////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions that are called when accessing the information base
// from the general module "Worker-Worker-Warehouse", as well as when accessing the functions of the web service.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the number - the number of documents-tasks available for execution by the warehouse employee 
// when accessing the GetJobsCount function of the "WMSMobileClientExchange" web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	Proxy - WSProxy - proxy for calling a web service,
//	JobType - String - type of warehouse task.
//
// Returns:
//	Number - the number of tasks available for the specified type.
//
Function NumberOfWarehouseTasks(Form, Proxy, JobType) Export
	
	WarehouseID = TrimAll(Form.Warehouse.UUID());
	RoomID = TrimAll(Form.Premise.UUID());
	ArtistID = TrimAll(Form.User.UUID());
	
	ServiceVersion = ServiceVersionFromForm(Form);
	JobTypeWS = JobTypeWS(JobType, Proxy.XDTOFactory, ServiceVersion);
	
	JobsCount = Proxy.GetJobsCount(WarehouseID, RoomID, JobTypeWS, ArtistID, True);
	
	Return JobsCount;
	
EndFunction

// Returns-the number of task documents available for the warehouse employee to complete.
//
// Parameters:
//	WarehouseID - String - the ID of the warehouse;
//	RoomID - String - the ID of the room;
//	JobType - XDTODataValue - Task type of the WMSMobileClientExchange XDTO package - type of the warehouse task;
//	ArtistID - String - user ID;
//	AllAssignees - Boolean - True, getting the number of all available warehouse tasks.
//
// Returns:
//	Number - the number of tasks available for the specified type.
//
Function NumberOfWarehouseJobsWS(WarehouseID, RoomID, JobType, ArtistID, AllAssignees) Export
	
	Warehouse = CatalogLink(WarehouseID, "Warehouses");
	Premise = CatalogLink(RoomID, "Warerooms");
	Performer = CatalogLink(ArtistID, "Users");
	
	TaskPerformers_ = New Array;
	TaskPerformers_.Add(Performer);
	
	If AllAssignees Then
		TaskPerformers_.Add(Catalogs.Users.EmptyRef());
	EndIf;
	
	Assignees = New FixedArray(TaskPerformers_);
	
	JobsCount = WorkplaceOfWarehouseWorkerApplicationInterface.NumberOfWarehouseTasksToComplete(Warehouse,
		Premise, JobType, Assignees);
	
	Return JobsCount;
	
EndFunction

// Returns the task table of the selected operation type when accessing the function
// GetJobsTable of the "WMSMobileClientExchange" web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	JobType - String - type of warehouse task.
//
// Returns:
//	ValueTable - the task table.
//
Function TaskTable(Form, JobType) Export
	
	DocumentName = DocumentName(JobType);
	ServiceVersion = ServiceVersionFromForm(Form);
	Proxy = ProxyWebService(Form.UserName, Form.Password,Form.WSDLLocation, ServiceVersion);
	
	WarehouseID = TrimAll(Form.Warehouse.UUID());
	RoomID = TrimAll(Form.Premise.UUID());
	ArtistID = TrimAll(Form.User.UUID());
	
	JobTypeWS = JobTypeWS(JobType, Proxy.XDTOFactory, ServiceVersion);
	TaskTable = Form.Jobs.Unload();
	WSJobTable = Proxy.GetJobsTable(WarehouseID, RoomID, JobTypeWS, ArtistID, True);
	
	TaskTable.Clear();
	FillInTaskTable(TaskTable, WSJobTable, DocumentName);
	
	Return TaskTable;
	
EndFunction

// Returns a table of tasks of the type 'Task Tables' of the XDTO package WMSMobileClientExchange*, 
// the selected type of operation.
//
// Parameters:
//	WarehouseID - String - the ID of the warehouse;
//	RoomID - String - the ID of the room;
//	JobType - XDTODataValue - The type of tasks of the XDTO package WMSMobileClientExchange* is the type of warehouse task;
//	ArtistID - String - user ID;
//	AllAssignees - Boolean - getting all available warehouse tasks.
//	ServiceVersion - String - the version of the service in the format "A.B.C"? actually points to ws and the package WMSMobileClientExchange_A_B_C
//
// Returns:
//	XDTODataValue - The XDTO task tables of the WMSMobileClientExchange package, the task table.
//
Function WSJobTable(WarehouseID, RoomID, JobType, ArtistID, AllAssignees, ServiceVersion = "") Export
	
	Warehouse = CatalogLink(WarehouseID, "Warehouses");
	Premise = CatalogLink(RoomID, "Warerooms");
	Performer = CatalogLink(ArtistID, "Users");
	
	TaskPerformers_ = New Array;
	TaskPerformers_.Add(Performer);
	
	If AllAssignees Then
		TaskPerformers_.Add(Catalogs.Users.EmptyRef());
	EndIf;
	
	Assignees = New FixedArray(TaskPerformers_);
	
	TaskTable = WorkplaceOfWarehouseWorkerApplicationInterface.TaskTable(Warehouse, Premise, JobType,
		Assignees);
	
	WSJobTable = XDTOJobTable(TaskTable, ServiceVersion);
	
	Return WSJobTable;
	
EndFunction

// Returns a structure with service information about the task when scanning the barcode of a warehouse
// task, as well as when accessing the GetJobIDAndTypeByBarcode function of the "WMSMobileClientExchange"web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	Barcode - String - barcode of the warehouse task,
//	JobType - String - type of warehouse task.
//	DepthOfDetailOfMarking - Number - depth of detail 
//
// Returns:
//	See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function BarcodeTaskParameters(Form, Barcode, JobType, DepthOfDetailOfMarking = 0) Export
	
	ServiceVersion = ServiceVersionFromForm(Form);
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersion);
	
	WarehouseID = TrimAll(Form.Warehouse.UUID());
	RoomID = TrimAll(Form.Premise.UUID());
	ArtistID = TrimAll(Form.User.UUID());
	
	JobTypeWS = JobTypeWS(JobType, Proxy.XDTOFactory, ServiceVersion);
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters();
	If IsBlankString(ServiceVersion) Then
		WSJobParameters = Proxy.GetJobIDAndTypeByBarcode(
			Barcode, WarehouseID, RoomID, ArtistID, JobTypeWS);
	Else
		WSJobParameters = Proxy.GetJobIDAndTypeByBarcode(
			Barcode, WarehouseID, RoomID, ArtistID, JobTypeWS, DepthOfDetailOfMarking);
	EndIf; 
	
	JobType = JobTypeWS;
	JobParameters.JobType = JobType;
	
	FillPropertyValues(JobParameters, Form, "Warehouse, Premise");
	FillInTaskParameters(Form.Object, JobParameters, WSJobParameters);
	
	Return JobParameters;
	
EndFunction

// Returns information with service information for a warehouse task of the 'parameterization' Type 
// of the WMSMobileClientExchange XDTO package. This function is called when scanning the barcode
// of a warehouse task document.
//
// Parameters:
//	Barcode - String - barcode of the warehouse task;
//	WarehouseID - String - the ID of the warehouse;
//	RoomID - String - the ID of the room;
//	ArtistID - String - ID of the warehouse task performer;
//	JobType - XDTODataValue - Task type of the WMSMobileClientExchange XDTO package - type of the warehouse task;
//	DepthOfDetailOfMarking - Number - depth of detail of information on marked packages:
//				0 - without detail
//				999 - without limitation of nesting.
//	ServiceVersion - String - postfix of the service version.
//
// Returns:
//	XDTODataValue - ParameterIzation of the XDTO package WMSMobileClientExchange.
//
Function TaskParametersForWSBarcode(Barcode, WarehouseID, RoomID, ArtistID, JobType,
	DepthOfDetailOfMarking = 0, ServiceVersion = "") Export
	
	Warehouse = CatalogLink(WarehouseID, "Warehouses");
	Premise = CatalogLink(RoomID, "Warerooms");
	Performer = CatalogLink(ArtistID, "Users");
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.BarcodeTaskParameters(
		Barcode, Warehouse, Premise, Performer, JobType,, DepthOfDetailOfMarking);
	WSJobParameters = WSJobParameters(JobParameters, ServiceVersion);
	
	Return WSJobParameters;
	
EndFunction

// Returns a structure with service information about the task. This function is called when you select a task 
// from the table part of the 'Task' form for processing 'workworkersclad', as well as when 
// you access the GetAndTakeAllotmentPickJob function of the "WMSMobileClientExchange"web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	Job - DocumentRef - link to the warehouse task document.
//
// Returns:
// See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function JobParametersWhenAcceptedForWork(Form, Job) Export
	
	ServiceVersion = ServiceVersionFromForm(Form);
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersion);
	
	JobType = Form.ModeSettings.JobType;
	JobTypeWS = JobTypeWS(JobType, Proxy.XDTOFactory, ServiceVersion);
	
	TaskID_ = TrimAll(Job.UUID());
	ArtistID = TrimAll(Form.User.UUID());
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters();
	If IsBlankString(ServiceVersion) Then
		WSJobParameters = Proxy.GetAndTakeAllotmentPickJob(TaskID_, ArtistID, JobTypeWS);
	Else
		WSJobParameters = Proxy.GetAndTakeAllotmentPickJob(TaskID_, ArtistID, JobTypeWS,1);
	EndIf; 
	
	JobParameters.JobType = JobType;
	TaskAttributes = Common.ObjectAttributesValues(Job, "Warehouse, Premise");
	
	FillPropertyValues(JobParameters, TaskAttributes);
	FillInTaskParameters(Form.Object, JobParameters, WSJobParameters);
	
	Return JobParameters;
	
EndFunction

// Returns information with the service information of a warehouse task of the' task parameters ' type 
// of the WMSMobileClientExchange XDTO package, when selecting a task from the 'Task' table part of the processing form 
// 'Rabocheostrovsk'.
//
// Parameters:
//	TaskID_ - String - the document ID of the task;
//	ArtistID - String - ID of the warehouse task performer;
//	JobType - XDTODataValue - Task type of the WMSMobileClientExchange XDTO package - the type of warehouse task.
//	DepthOfDetailOfMarking - Number - 
//	ServiceVersion - String - 
//
// Returns:
//	XDTODataValue - ParameterIzation of the XDTO package WMSMobileClientExchange.
//
Function JobParametersWhenWSIsAcceptedForWork(TaskID_, ArtistID, JobType,
	DepthOfDetailOfMarking = 0, ServiceVersion = "") Export
	
	User = CatalogLink(ArtistID, "Users");
	Job = TaskLink(TaskID_, JobType);
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.JobParametersWhenAcceptedForWork(
		Job, User);
	JobParameters.Insert("Job", Job);
	
	WSJobParameters = WSJobParameters(JobParameters, ServiceVersion);
	
	Return WSJobParameters;
	
EndFunction

// Returns a table of cells for receiving and shipping zones at the specified warehouse when accessing 
// the GetAcceptanceAreas function of the "WMSMobileClientExchange" web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//
// Returns:
//	ValueTable - table with description of warehouse areas of acceptance and shipment:
//		* Cell - CatalogRef.StorageBins - address of the storage cell;
//		* CellType - EnumRef.TypesOfStorageCells - storage cell type;
//		* Warehouse - CatalogRef.Warehouses - warehouse where the acceptance (shipment) cell is located);
//		* NameOfTheWarehouse - String - the name of the warehouse;
//		* CellCode - String - string representation of the storage cell.
//
Function ReceivingShippingAreas(Form) Export
	
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersionFromForm(Form));
	
	WarehouseID = TrimAll(Form.Warehouse.UUID());
	RoomID = TrimAll(Form.Premise.UUID());;
	
	WSCellListParameters= Proxy.GetAcceptanceAreas(WarehouseID, RoomID);
	
	ReceivingShippingAreas = Form.ReceivingShippingAreas.Unload();
	ReceivingShippingAreas.Clear();
	
	FillInShipmentAcceptanceZones(ReceivingShippingAreas, WSCellListParameters.ReceivingShippingAreas);
	
	Return ReceivingShippingAreas;
	
EndFunction

// Returns a table of cells for the acceptance and shipment zones for the specified warehouse.
//
// Parameters:
//	WarehouseID - String - the ID of the warehouse,
//	RoomID - String - the ID of the room.
//	ServiceVersion - String - 
//
// Returns:
//	XDTODataValue - Parameters of the XDTO package's WMSMobileClientExchange* listbox.
//
Function WSShipmentAcceptanceZones(WarehouseID, RoomID, ServiceVersion = "") Export
	
	Warehouse = CatalogLink(WarehouseID, "Warehouses");
	Premise = CatalogLink(RoomID, "Warerooms");
	
	ReceivingShippingAreas = WorkplaceOfWarehouseWorkerApplicationInterface.ReceivingShippingAreas(Warehouse, Premise);
	WSCellListParameters = WSCellListParameters(ReceivingShippingAreas, ServiceVersion);
	
	Return WSCellListParameters;
	
EndFunction

// Returns a table of products stored in a cell by the cell reference when accessing the function 
// GetGoodsOfCellStored of the "WMSMobileClientExchange" web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	Cell - CatalogRef.StorageBins - storage cell.
//
// Returns:
//	See CellProductsTable
//
Function CellGoods(Form, Cell) Export
	
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersionFromForm(Form));
	
	CellID = TrimAll(Cell.UUID());
	WSCellProductParameters = Proxy.GetGoodsOfCellStored(CellID);
	
	CellGoods = CellProductsTable();
	FillInAllCells(CellGoods, WSCellProductParameters.CellGoods);
	
	Return CellGoods;
	
EndFunction

// Returns a table of products stored in the cell.
//
// Parameters:
//	CellID - String - ID of the storage cell.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Parameters of the XDTO-package WMSMobileClientExchange cell.
//
Function WSCellProducts(CellID, ServiceVersion = "") Export
	
	Cell = CatalogLink(CellID, "StorageBins");
	CellDetails = Common.ObjectAttributesValues(Cell, "Owner, Premise");
	
	CellGoods = WorkplaceOfWarehouseWorkerApplicationInterface.CellGoods(CellDetails.Owner,
		CellDetails.Premise, Cell);
	
	AddDataToCellItems(CellGoods);
	WSCellProductParameters = WSCellProductParameters(Undefined, CellGoods, ServiceVersion);
	
	Return WSCellProductParameters;
	
EndFunction

// Returns a table of products stored in a cell by the cell's barcode when accessing the function 
// GetGoodsOfCellStoredByBarcode of the "WMSMobileClientExchange" web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	Barcode - String - barcode of the cell.
//
// Returns:
//	Structure:
//	*ReturnCode - Number
//	*Cell - See CatalogLink
//
Function CellProductsByBarcode(Form, Barcode) Export
	
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersionFromForm(Form));

	WarehouseID = TrimAll(Form.Warehouse.UUID());
	RoomID = TrimAll(Form.Premise.UUID());
	
	WSCellProductParameters = Proxy.GetGoodsOfCellStoredByBarcode(Barcode, WarehouseID, RoomID); // XDTODataObject
	
	CellParameters_ = New Structure;
	
	If Not WSCellProductParameters.Успешно Then
		CellParameters_.Insert("ReturnCode", 0);
		Return CellParameters_;
	Else
		CellParameters_.Insert("ReturnCode", 1);
		CellParameters_.Insert("Cell", CatalogLink(WSCellProductParameters.Ячейка["Ref"], "StorageBins"));
	EndIf;
	
	Return CellParameters_;
	
EndFunction

// Returns a table of products stored in the cell.
//
// Parameters:
//	Barcode - String - the barcode warehouse of the cell,
//	WarehouseID - String - the ID of the warehouse,
//	RoomID - String - the ID of the room.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Parameters of the XDTO-package WMSMobileClientExchange cell.
//
Function CellProductsByBarcodeWS(Barcode, WarehouseID, RoomID, ServiceVersion = "") Export
	
	Warehouse = CatalogLink(WarehouseID, "Warehouses");
	Premise = CatalogLink(RoomID, "Warerooms");
	
	CellParameters_ = WorkplaceOfWarehouseWorkerApplicationInterface.FindCellByBarcode(Warehouse, Premise, Barcode,
		True);
	
	If CellParameters_.ReturnCode = 0 Then
		WSCellProductParameters = WSCellProductParameters(Undefined, Undefined, ServiceVersion);
		Return WSCellProductParameters;
	Else
		CellGoods = WorkplaceOfWarehouseWorkerApplicationInterface.CellGoods(Warehouse, Premise, 
			CellParameters_.Cell);
	EndIf;
	
	AddDataToCellItems(CellGoods);
	WSCellProductParameters = WSCellProductParameters(CellParameters_, CellGoods, ServiceVersion);
	
	Return WSCellProductParameters;
	
EndFunction

// Called when the goods selection of the warehouse operation "Move" is completed, as well as when 
// the SetPickedGoodsInAllotmentPickJob function of the "WMSMobileClientExchange"web service is accessed.
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//
// Returns:
//	See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function ProcessScannedGoodsForMoving(Form) Export
	
	ServiceVersion = ServiceVersionFromForm(Form);
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersion);
	
	ScannedWSProducts = ScannedWSProducts(Form, Proxy.XDTOFactory);
	TaskID_ = TrimAll(Form.ModeSettings.Job.UUID());
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters();
	WSJobParameters = Proxy.SetPickedGoodsInAllotmentPickJob(TaskID_, ScannedWSProducts);
	
	FillInParametersForProcessingScannedProducts(JobParameters, WSJobParameters, Form.Object);
	
	Return JobParameters;
	
EndFunction

// Called when the selection of items is completed when the move task is completed.
//
// Parameters:
//	TaskID_ - String - ID of the warehouse task document;
//	ScannedWSProducts - XDTODataValue - table OF the xdto package WMSMobileClientExchange - table of scanned
//		products.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Processing parametres of scanned products of the XDTO package WMSMobileClientExchange.
//
Function ProcessScannedGoodsToMoveWS(TaskID_, ScannedWSProducts, ServiceVersion = "") Export
	
	Job = TaskLink(TaskID_, "Move");
	
	TableScannedProducts = TableScannedProducts();
	ScannedGoods = WarehouseTaskItems(TableScannedProducts, ScannedWSProducts);
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.ProcessScannedGoodsForMoving(
		Job, ScannedGoods, Undefined);
	WSJobParameters = ParametersForProcessingScannedGoodsInWS(JobParameters, ServiceVersion);
	
	Return WSJobParameters;
	
EndFunction

// Cancels the current warehouse task and returns it to its original status 
// when accessing the CancelJob function of the "WMSMobileClientExchange" web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	Job - DocumentRef - link to the warehouse task document.
//
// Returns:
//	See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function CancelJobExecution(Form, Job) Export
	
	ServiceVersion = ServiceVersionFromForm(Form);
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersion);
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	SourceExecutor = ModeSettings.SourceExecutor;
	
	TaskID_ = TrimAll(Job.UUID());
	ArtistID = TrimAll(SourceExecutor.UUID());
	
	JobTypeWS = JobTypeWS(JobType, Proxy.XDTOFactory, ServiceVersion);
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters();
	WSJobParameters = Proxy.CancelJob(TaskID_, ArtistID, JobTypeWS);
	
	FillInTaskCancellationParameters(JobParameters, WSJobParameters);
	
	Return JobParameters;
	
EndFunction

// Cancels the current warehouse task and returns it to its original status.
//
// Parameters:
//	TaskID_ - String - ID of the warehouse task;
//	ArtistID - String - user ID;
//	JobType - XDTODataValue - Task type of the WMSMobileClientExchange XDTO package - the type of warehouse task.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Parameters of the cancellation of the task -XDTO package WMSMobileClientExchange.
//
Function CancelWSJob(TaskID_, ArtistID, JobType, ServiceVersion = "") Export
	
	Job = TaskLink(TaskID_, JobType);
	SourceExecutor = CatalogLink(ArtistID, "Users");
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CancelJobExecution(Job,
		SourceExecutor, JobType);
	WSJobParameters = ParametersForCancelingWarehouseTaskWS(JobParameters, ServiceVersion);
	
	Return WSJobParameters;
	
EndFunction

// Terminates the execution of the inventory job. When scanning products, the scanned products
//  are transferred to the table parts of the documents. when typing, new warehouse tasks are created.
//  The necessary statuses are set for documents, and documents are processed.
//  Called when accessing the CompleteJob function of the "WMSMobileClientExchange" web service.
//
// Parameters:
//  Form	 - ClientApplicationForm	 - form of a warehouse employee's mobile workplace,
//  Job	 - DocumentRef	 - link to the warehouse task document.
// 
// Returns:
//  See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function CompleteWarehouseTask(Form, Job) Export
	
	ServiceVersion = ServiceVersionFromForm(Form);
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersion);
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	SourceExecutor = ModeSettings.SourceExecutor;
	
	TaskID_ = TrimAll(Job.UUID());
	ArtistID = TrimAll(SourceExecutor.UUID());
	
	JobTypeWS = JobTypeWS(JobType, Proxy.XDTOFactory, ServiceVersion);
	AdditionalWSParameters = AdditionalWSParameters(Form, JobType, Proxy.XDTOFactory);
	ScannedWSProducts = ScannedWSProducts(Form, Proxy.XDTOFactory);
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters();
	If ServiceVersion = "" Then
		WSJobParameters = Proxy.CompleteJob(
			TaskID_, ArtistID, ScannedWSProducts, JobTypeWS, AdditionalWSParameters);
	Else
		StampData = Undefined;
		WSJobParameters = Proxy.CompleteJob(
			TaskID_, ArtistID, ScannedWSProducts, JobTypeWS, AdditionalWSParameters, StampData);
	EndIf; 
	
	FillInWarehouseTaskCompletionParameters(JobParameters, WSJobParameters);
	
	Return JobParameters;
	
EndFunction

// Terminates the execution of the inventory job. When scanning products, the scanned products
// are transferred to the tabular parts of the documents. when typing, new warehouse tasks are created.
// The necessary statuses are set for documents, and documents are processed.
//
// Parameters:
//	TaskID_ - String - task ID;
//	ArtistID - String - ID of the warehouse task performer;
//	ScannedWSProducts - XDTODataValue - table OF the xdto package WMSMobileClientExchange-data of scanned products;
//	JobType - XDTODataValue - Task type of the WMSMobileClientExchange XDTO package - type of the warehouse task;
//	AdditionalParameters - XDTODataValue - Parameters for moving the WMSMobileClientExchange XDTO package- 
//		additional parameters for the "Move" warehouse operation.
//	TopLevelMarking - XDTOList,Undefined - package labeling list
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Parametersperformance of the XDTO task of the WMSMobileClientExchange package.
//
Function CompleteWsWarehouseTask(
	TaskID_, ArtistID, ScannedWSProducts, JobType, AdditionalParameters,
	TopLevelMarking = Undefined, ServiceVersion = "") Export
	
	Job = TaskLink(TaskID_, JobType);
	SourceExecutor = CatalogLink(ArtistID, "Users");
	
	TableScannedProducts = TableScannedProducts();
	ScannedGoods = WarehouseTaskItems(TableScannedProducts, ScannedWSProducts);
	
	TableScannedStamps = WorkplaceOfWarehouseWorkerLocalization.TableScannedStamps();
	ScannedStampValues = WorkplaceOfWarehouseWorkerLocalization.ScannedStamps(
																			TableScannedStamps, 
																			TopLevelMarking, 
																			ServiceVersion);
	
	JobParameters = TaskCompletionParameters_(Job, SourceExecutor, ScannedGoods, JobType,
		AdditionalParameters, ScannedStampValues);
	WSJobParameters = WarehouseTaskCompletionParametersWS(JobParameters, ServiceVersion);
	
	Return WSJobParameters;
	
EndFunction

// Called when completing a set of products to create a new placement task, 
// as well as when accessing the CompleteJobNewLocation function of the "WMSMobileClientExchange"web service.
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//
// Returns:
//	See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function CompleteTaskNewPlacement(Form) Export
	
	Proxy = ProxyWebService(Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersionFromForm(Form));
	
	Object = Form.Object;
	ModeSettings = Form.ModeSettings;
	
	WarehouseID = TrimAll(Object.Warehouse.UUID());
	RoomID = TrimAll(Object.Premise.UUID());
	IDOfAcceptanceZone = TrimAll(ModeSettings.ReceivingArea.UUID());
	ArtistID = TrimAll(Object.Performer.UUID());
	
	ScannedWSProducts = ScannedWSProducts(Form, Proxy.XDTOFactory);
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters();
	WSJobParameters = Proxy.CompleteJobNewLocation(WarehouseID, RoomID, IDOfAcceptanceZone, ArtistID,
		ScannedWSProducts);
	
	FillInWarehouseTaskCompletionParameters(JobParameters, WSJobParameters);
	
	Return JobParameters;
	
EndFunction

// Called when completing a set of products to create a new placement task.
//
//	Parameters:
//	WarehouseID - String - the ID of the warehouse;
//	RoomID - String - the ID of the room;
//	IDOfAcceptanceZone - String - the ID of the cell;
//	ArtistID - String - ID of the warehouse task performer;
//	ScannedWSProducts - XDTODataValue - table OF the xdto package WMSMobileClientExchange - data of scanned 
//		products.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Parametersperformance of the XDTO task of the WMSMobileClientExchange package.
//
Function FinishTaskNewWSPlacement(
		WarehouseID, RoomID, IDOfAcceptanceZone, ArtistID, ScannedWSProducts, ServiceVersion = "") Export
	
	Warehouse = CatalogLink(WarehouseID, "Warehouses");
	Performer = CatalogLink(ArtistID, "Users");
	Premise = CatalogLink(RoomID, "Warerooms");
	ReceivingArea = CatalogLink(IDOfAcceptanceZone, "StorageBins");
	
	TableScannedProducts = TableScannedProducts();
	ScannedGoods = WarehouseTaskItems(TableScannedProducts, ScannedWSProducts);
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteTaskNewPlacement(Warehouse,
		Premise, ReceivingArea, Performer, ScannedGoods, Undefined);
	WSJobParameters = WarehouseTaskCompletionParametersWS(JobParameters, ServiceVersion);
	
	Return WSJobParameters;
	
EndFunction

// Returns the service version for the regular processing of the warehouse worker's workplace
// Returns:
//	String -
//
Function MainVersionOfService() Export
	Return "2.5.9";
EndFunction

// The service version from the form.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
// 
// Returns:
//  String - service version
Function ServiceVersionFromForm(Form) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		
		AllAttributes = Form.GetAttributes();	//Array of FormAttribute
		VersionAttributeName = "ServiceVersion";
		
		For Each Itm In AllAttributes Do
			If Itm.Name = VersionAttributeName Then
				
				Return Form[VersionAttributeName];
				
			EndIf; 
		EndDo; 
		
	EndIf; 
	
	Return MainVersionOfService();
	
EndFunction

#EndRegion

#Region Private

#Region SerializationOfWarehouseTaskParameters

// Returns the' assignment Parameter ' of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	JobParameters - Structure - parameters of the warehouse task.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - ParameterIzation of the XDTO package WMSMobileClientExchange.
//
Function WSJobParameters(JobParameters, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	JobParameterStructure = JobParameterStructure();
	FillInTaskParameterStructure(JobParameterStructure, JobParameters, ServiceVersion);
	
	JobParametersType = XDTOFactory.Type(NameUris, "ПараметрыЗадания");
	WSJobParameters = XDTOFactory.Create(JobParametersType);
	
	FillPropertyValues(WSJobParameters, JobParameterStructure);
	
	Return WSJobParameters;
	
EndFunction

// Returns a structure for storing data for the' parameterization ' of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	Structure
//
Function JobParameterStructure()
	
	JobParameterStructure = New Structure;
	
	JobParameterStructure.Insert("Success", False);
	JobParameterStructure.Insert("MessageText", "");
	JobParameterStructure.Insert("ProcessingProcedure_");
	JobParameterStructure.Insert("SourceExecutor");
	JobParameterStructure.Insert("GoodsPickingPlacement");
	JobParameterStructure.Insert("InventoryRecount");
	JobParameterStructure.Insert("GoodsReceiptNote");
	JobParameterStructure.Insert("GoodsIssueNote");
	
	Return JobParameterStructure;
	
EndFunction

// Fills in the 'parameter Structure' with data from the warehouse task document.
//
// Parameters:
//	ParametersStructure - Structure,
//	JobParameters - Structure - parameters of the warehouse task.
//	ServiceVersion - String
//
Procedure FillInTaskParameterStructure(ParametersStructure, JobParameters, Val ServiceVersion)
	
	ParametersStructure.Success = (JobParameters.ReturnCode = 1);
	ParametersStructure.MessageText = JobParameters.MessageText;
	
	If Not ParametersStructure.Success Then
		Return;
	EndIf;
	
	NameUris = NamespaceURI(ServiceVersion);
	JobType = JobParameters.JobType;
	
	ParametersStructure.SourceExecutor = UserWS(JobParameters.SourceExecutor, XDTOFactory, NameUris);
	ParametersStructure.ProcessingProcedure_ = OrderInWhichWSJobIsProcessed(JobParameters.ProcessingProcedure_, NameUris);
	
	DocumentStructure = WarehouseTaskStructure(JobType);
	FillInWarehouseTaskStructure(DocumentStructure, JobParameters, ServiceVersion);
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		GoodsPickingPlacementType = XDTOFactory.Type(NameUris, "ОтборРазмещениеТоваров");
		SelectionPlacementOfWSProducts = XDTOFactory.Create(GoodsPickingPlacementType);
		
		FillPropertyValues(SelectionPlacementOfWSProducts, DocumentStructure);
		
		ParametersStructure.GoodsPickingPlacement = SelectionPlacementOfWSProducts;
		
	ElsIf JobType = "Receiving" Then
		
		GoodsReceiptNoteType = XDTOFactory.Type(NameUris, "ПриходныйОрдерНаТовары");
		ReceiptOrderForWSGoods = XDTOFactory.Create(GoodsReceiptNoteType);
		
		FillPropertyValues(ReceiptOrderForWSGoods, DocumentStructure);
		
		ParametersStructure.GoodsReceiptNote = ReceiptOrderForWSGoods;
		
	ElsIf JobType = "Recalculate" Then
		
		InventoryRecountType = XDTOFactory.Type(NameUris, "ПересчетТоваров");
		RecalculationOfWSProducts = XDTOFactory.Create(InventoryRecountType);
		
		FillPropertyValues(RecalculationOfWSProducts, DocumentStructure);
		
		ParametersStructure.InventoryRecount = RecalculationOfWSProducts;
		
	ElsIf JobType = "PickingCheck" Then
		
		GoodsIssueNoteType = XDTOFactory.Type(NameUris, "РасходныйОрдерНаТовары");
		SpendingOrderForWSGoods = XDTOFactory.Create(GoodsIssueNoteType);
		
		FillPropertyValues(SpendingOrderForWSGoods, DocumentStructure);
		
		ParametersStructure.GoodsIssueNote = SpendingOrderForWSGoods;
		
	EndIf;
	
EndProcedure

// Fills in the 'document Structure' with data from the warehouse task document.
//
// Parameters:
//	DocumentStructure - See WarehouseTaskStructure
//	JobParameters - Structure - parameters of the warehouse task.
//	ServiceVersion - String
//
Procedure FillInWarehouseTaskStructure(DocumentStructure, JobParameters, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	JobType = JobParameters.JobType;
	
	DocumentStructure.Ref = TrimAll(JobParameters.Job.UUID());
	DocumentStructure.Warehouse = WSWarehouse(JobParameters.Warehouse, XDTOFactory, NameUris);
	DocumentStructure.Premise = WSRoom(JobParameters.Premise, XDTOFactory, NameUris);
	
	StringOfDocumentDetails = "Date, Number, Posted";
	DocumentAttributes = Common.ObjectAttributesValues(JobParameters.Job, StringOfDocumentDetails);
	
	FillPropertyValues(DocumentStructure, DocumentAttributes);
	
		
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		FillInSelectionPlacementOfWSProducts(DocumentStructure, JobParameters, ServiceVersion);
		
	ElsIf JobType = "Receiving" Then
		FillReceiptOrderForWSGoods(DocumentStructure, JobParameters, ServiceVersion);
	ElsIf JobType = "Recalculate" Then
		FillInRecalculationOfWSProducts(DocumentStructure, JobParameters, ServiceVersion);
	ElsIf JobType = "PickingCheck" Then
		FillOutSpendingOrderForWSGoods(DocumentStructure, JobParameters, ServiceVersion);
	EndIf;
	
EndProcedure

// Fills in the 'document Structure' with data from the 'product Selection (placement)'document.
//
// Parameters:
//	DocumentStructure - See WarehouseTaskStructure
//	JobParameters - Structure
//	ServiceVersion - String
//
Procedure FillInSelectionPlacementOfWSProducts(DocumentStructure, JobParameters, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	JobType = JobParameters.JobType;
	
	DocumentStructure.Status = ProductPlacementSelectionStatusWS(JobParameters.Status, NameUris);
	DocumentStructure.Performer = UserWS(JobParameters.Performer, XDTOFactory, NameUris);
	
	If JobType = "Filter" Then
		
		TableName = "SelectionProductPlacementProductsSelection";
		
		DocumentStructure.ShippingZone = WSStorageArea(JobParameters.ShippingZone, XDTOFactory, NameUris);
		DocumentStructure.GoodsFilter = WsWarehouseTaskProducts(
			JobParameters.GoodsFilter, JobType, TableName, ServiceVersion);
		
	ElsIf JobType = "Location" Then
		
		TableName = "SelectionProductPlacementProductsPlacement";
		
		DocumentStructure.ReceivingArea = WSStorageArea(JobParameters.ReceivingArea,XDTOFactory, NameUris);
		DocumentStructure.GoodsPlacement = WsWarehouseTaskProducts(
			JobParameters.GoodsPlacement, JobType, TableName, ServiceVersion);
		
	ElsIf JobType = "Move" Then
		
		DocumentStructure.ShippingZone = WSStorageArea(JobParameters.ShippingZone, XDTOFactory, NameUris);
		DocumentStructure.ReceivingArea = WSStorageArea(JobParameters.ReceivingArea, XDTOFactory, NameUris);
		
		TableName = "SelectionProductPlacementProductsSelection";
		DocumentStructure.GoodsFilter = WsWarehouseTaskProducts(
			JobParameters.GoodsFilter, JobType, TableName, ServiceVersion);
		
		TableName = "SelectionProductPlacementProductsPlacement";
		DocumentStructure.GoodsPlacement = WsWarehouseTaskProducts(
		JobParameters.GoodsPlacement, JobType, TableName, ServiceVersion);
		
	EndIf;
	
EndProcedure

// Fills in the 'document Structure' with data from the 'product Recalculation' document.
//
// Parameters:
//	DocumentStructure - Structure - the document 'Conversion of goods',
//	JobParameters - Structure
//	ServiceVersion - String
//
Procedure FillInRecalculationOfWSProducts(DocumentStructure, JobParameters, ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	TableName = "RecalculationOfGoods";
	JobType = JobParameters.JobType;
	
	DocumentStructure.Status = StatusOfGoodsRecalculationWS(JobParameters.Status, NameUris);
	DocumentStructure.Performer = UserWS(JobParameters.Performer, XDTOFactory, NameUris);
	DocumentStructure.Goods = WsWarehouseTaskProducts(JobParameters.Goods, JobType, TableName, ServiceVersion);
	
EndProcedure

// Fills in the 'document Structure' with the data of the 'Receipt order for goods' document.
//
// Parameters:
//	DocumentStructure - Structure - document 'Receipt order for goods',
//	JobParameters - Structure
//	ServiceVersion - String
//
Procedure FillReceiptOrderForWSGoods(DocumentStructure, JobParameters, ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	DocumentStructure.Status = StatusOfWsReceiptOrder(JobParameters.Status, NameUris);
	DocumentStructure.EmployeeResponsible = UserWS(JobParameters.EmployeeResponsible, XDTOFactory, NameUris);
	
EndProcedure

// Fills in the 'Structuradocument' with the data of the 'Expenditure order for goods' document.
//
// Parameters:
//	DocumentStructure - Structure - document ' Expenditure order for goods,
//	JobParameters - Structure
//	ServiceVersion - String
//
Procedure FillOutSpendingOrderForWSGoods(DocumentStructure, JobParameters, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	JobType = JobParameters.JobType;
	TableName = "SpendingOrderForGoodsShippedGoods";
	
	DocumentStructure.Status = StatusOfWsSpendingOrder(JobParameters.Status, NameUris);
	DocumentStructure.Inspector = UserWS(JobParameters.Inspector, XDTOFactory, NameUris);
	DocumentStructure.DateOfShipment = JobParameters.DateOfShipment;
	DocumentStructure.ShippedGoods = WsWarehouseTaskProducts(
		JobParameters.ShippedGoods, JobType, TableName, ServiceVersion);
	
EndProcedure

#EndRegion

#Region DeserializationOfWarehouseTaskParameters

// Fills in the 'task Parameters' with data from the warehouse task document received via the web service.
//
// Parameters:
//	Object - DataProcessorObject.WorkplaceOfWarehouseWorker,
//	JobParameters - See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//	WSJobParameters - XDTODataObject
//	
Procedure FillInTaskParameters(Object, JobParameters, WSJobParameters)
	
	If Not WSJobParameters.Успешно Then
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = WSJobParameters.ТекстСообщения;
		
		Return;
	EndIf;
	
	JobType = JobParameters.JobType;
	
	JobParameters.ProcessingProcedure_ = JobProcessingProcedure(WSJobParameters.ПорядокОбработки);
	JobParameters.SourceExecutor = CatalogLink(WSJobParameters.ИсходныйИсполнитель["Ref"],
		"Users");
	
	NameOfDocumentInCollection = "";
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		FillInSelectionOfProductPlacement(Object, JobParameters, WSJobParameters.ОтборРазмещениеТоваров);
		NameOfDocumentInCollection = "GoodsPickingPlacement";
		
	ElsIf JobType = "Receiving" Then
		FillInReceiptOrderForGoods(JobParameters, WSJobParameters.ПриходныйОрдерНаТовары);
		NameOfDocumentInCollection = "GoodsReceiptNote";
	ElsIf JobType = "Recalculate" Then
		FillInRecalculationOfGoods(Object, JobParameters, WSJobParameters.ПересчетТоваров);
		NameOfDocumentInCollection = "InventoryRecount";
	ElsIf JobType = "PickingCheck" Then
		FillOutSpendingOrderForGoods(Object, JobParameters, WSJobParameters.РасходныйОрдерНаТовары);
		NameOfDocumentInCollection = "GoodsIssueNote";
	EndIf;
	
	If IsBlankString(NameOfDocumentInCollection) Then
		Return;
	EndIf;
	
	
EndProcedure


// Fills in the 'parameterization' with data from the 'selection (placement) of products' document received 
// via the web service.
//
// Parameters:
//	Object - DataProcessorObject.WorkplaceOfWarehouseWorker,
//	JobParameters - See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//	SelectionOfWSProductPlacement - XDTODataObject - 
//			Selection of product placements of the WMSMobileClientExchange XDTO package - data from the document 'selection (placement) of products'.
//
Procedure FillInSelectionOfProductPlacement(Object, JobParameters, SelectionOfWSProductPlacement)
	
	JobType = JobParameters.JobType;
	
	Job = DocumentLink_(SelectionOfWSProductPlacement.Ссылка, "GoodsPickingPlacement");
	Performer = CatalogLink(SelectionOfWSProductPlacement.Исполнитель["Ref"], "Users");
	
	JobParameters.Posted = SelectionOfWSProductPlacement.Проведен;
	JobParameters.Status = ProductPlacementSelectionStatus(SelectionOfWSProductPlacement.Статус);
	
	JobParameters.Insert("Job", Job);
	JobParameters.Insert("Performer", Performer);
	
	If JobType = "Filter" Then
		
		ShippingZone = CatalogLink(SelectionOfWSProductPlacement.ЗонаОтгрузки.Ссылка, "StorageBins");
		ReferenceOrder = Common.ObjectAttributeValue(JobParameters.Job, "ReferenceOrder");
		
		Object.GoodsFilter.Clear();
		GoodsFilter = Object.GoodsFilter.Unload();
		
		JobParameters.GoodsFilter = WarehouseTaskItems(GoodsFilter, SelectionOfWSProductPlacement.ТоварыОтбор);
		
		JobParameters.Insert("ReferenceOrder", ReferenceOrder);
		JobParameters.Insert("ShippingZone", ShippingZone);
		JobParameters.Insert("NameOfShippingArea", SelectionOfWSProductPlacement.ЗонаОтгрузки.Код);
		
		JobParameters.Insert("ReceivingArea");
		JobParameters.Insert("NameOfAcceptanceZone");
		
	ElsIf JobType = "Location" Then
		
		Object.GoodsPlacement.Clear();
		GoodsPlacement = Object.GoodsPlacement.Unload();
		
		ReceivingArea = CatalogLink(SelectionOfWSProductPlacement.ЗонаПриемки.Ссылка, "StorageBins");
		
		JobParameters.GoodsPlacement = WarehouseTaskItems(GoodsPlacement,
			SelectionOfWSProductPlacement.ТоварыРазмещение);
		
		JobParameters.Insert("ReceivingArea", ReceivingArea);
		JobParameters.Insert("NameOfAcceptanceZone", SelectionOfWSProductPlacement.ЗонаПриемки.Код);
		
	ElsIf JobType = "Move" Then
		
		ReceivingArea = CatalogLink(SelectionOfWSProductPlacement.ЗонаПриемки.Ссылка, "StorageBins");
		ShippingZone = CatalogLink(SelectionOfWSProductPlacement.ЗонаОтгрузки.Ссылка, "StorageBins");
		
		Object.GoodsFilter.Clear();
		GoodsFilter = Object.GoodsFilter.Unload();
		
		Object.GoodsPlacement.Clear();
		GoodsPlacement = Object.GoodsPlacement.Unload();
		
		JobParameters.GoodsFilter = WarehouseTaskItems(GoodsFilter, SelectionOfWSProductPlacement.ТоварыОтбор);
		JobParameters.GoodsPlacement = WarehouseTaskItems(GoodsPlacement,
			SelectionOfWSProductPlacement.ТоварыРазмещение);
		
		JobParameters.Insert("ReceivingArea", ReceivingArea);
		JobParameters.Insert("ShippingZone", ShippingZone);
		JobParameters.Insert("NameOfAcceptanceZone", SelectionOfWSProductPlacement.ЗонаПриемки.Код);
		JobParameters.Insert("NameOfShippingArea", SelectionOfWSProductPlacement.ЗонаОтгрузки.Код);
		
	EndIf;
	
EndProcedure

// Fills in the 'parameterization' with data from the 'product Recalculation' document received via the web service.
//
// Parameters:
//	Object - DataProcessorObject.WorkplaceOfWarehouseWorker,
//	JobParameters - Structure,
//	RecalculationOfWSProducts - XDTODataObject - 
//			Recalculation of goods OF the xdto package WMSMobileClientExchange-data of the Document 'recalculation of goods'.
//
Procedure FillInRecalculationOfGoods(Object, JobParameters, RecalculationOfWSProducts)
	
	Job = DocumentLink_(RecalculationOfWSProducts.Ссылка, "InventoryRecount");
	Performer = CatalogLink(RecalculationOfWSProducts.Исполнитель["Ref"], "Users");
	
	Object.Goods.Clear();
	Goods = Object.Goods.Unload();
	
	JobParameters.Posted = RecalculationOfWSProducts.Проведен;
	JobParameters.Status = StatusOfRecalculationOfGoods(RecalculationOfWSProducts.Статус);
	JobParameters.Goods = WarehouseTaskItems(Goods, RecalculationOfWSProducts.Товары);
	
	JobParameters.Insert("Job", Job);
	JobParameters.Insert("Performer", Performer);
	
EndProcedure

// Fills in the 'parameters' With data from the 'Receipt order for goods' document received via the web service.
//
// Parameters:
//	Processing Object.Rabocheostrovsk,
//	JobParameters - Structure,
//	ReceiptOrderForWSGoods - XDTODataObject - 
//			Incoming orders OF the xdto package WMSMobileClientExchange - data of the document 'Incoming order for goods'.
//
Procedure FillInReceiptOrderForGoods(JobParameters, ReceiptOrderForWSGoods)
	
	Job = DocumentLink_(ReceiptOrderForWSGoods.Ссылка, "GoodsReceiptNote");
	EmployeeResponsible = CatalogLink(ReceiptOrderForWSGoods.Ответственный["Ref"], "Users");
	TaskAttributes = Common.ObjectAttributesValues(Job, "ReferenceOrder, WarehouseOperation");
	
	ReferenceOrder = TaskAttributes.ReferenceOrder;
	WarehouseOperation = TaskAttributes.WarehouseOperation;
	
	JobParameters.Posted = ReceiptOrderForWSGoods.Проведен;
	JobParameters.Status = StatusOfReceiptOrderForGoods(ReceiptOrderForWSGoods.Статус);
	
	JobParameters.Insert("Job", Job);
	JobParameters.Insert("ReferenceOrder",ReferenceOrder);
	JobParameters.Insert("EmployeeResponsible", EmployeeResponsible);
	JobParameters.Insert("WarehouseOperation", WarehouseOperation);
	
EndProcedure

// Fills in the 'parameterization' with data from the 'Expenditure order for goods' document received via the web service.
//
// Parameters:
//	Object - DataProcessorObject.WorkplaceOfWarehouseWorker,
//	JobParameters - Structure,
//	SpendingOrderForWSGoods - XDTODataObject - 
//			Consumable items OF the xdto package WMSMobileClientExchange - data of the document 'Consumable order for goods'.
//
Procedure FillOutSpendingOrderForGoods(Object, JobParameters, SpendingOrderForWSGoods)
	
	Job = DocumentLink_(SpendingOrderForWSGoods.Ссылка, "GoodsIssueNote");	// DocumentRef.GoodsIssueNote
	Inspector = CatalogLink(SpendingOrderForWSGoods.Контролер["Ref"], "Users");
	WarehouseOperation = Common.ObjectAttributeValue(Job, "WarehouseOperation");
	
	Object.ShippedGoods.Clear();
	ShippedGoods = Object.ShippedGoods.Unload();
	
	JobParameters.Posted = SpendingOrderForWSGoods.Проведен;
	JobParameters.Status = SpendingOrderStatus(SpendingOrderForWSGoods.Статус);
	JobParameters.ShippedGoods = WarehouseTaskItems(ShippedGoods,
		SpendingOrderForWSGoods.ОтгружаемыеТовары);
	
	JobParameters.Insert("Job", Job);
	JobParameters.Insert("DateOfShipment", SpendingOrderForWSGoods.ДатаОтгрузки);
	JobParameters.Insert("Inspector", Inspector);
	JobParameters.Insert("WarehouseOperation", WarehouseOperation);
	
EndProcedure

#EndRegion

#Region SerializingAdditionalParameters

// Returns 'additional Parameters' of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	JobType - String - the type of warehouse job,
//	Factory - XDTOFactory, Undefined -
//
// Returns:
//	XDTODataValue - ParameterIzation of the XDTO package WMSMobileClientExchange.
//
Function AdditionalWSParameters(Form, JobType, Factory)
	
	If Not (JobType = "Move") Then
		Return Undefined;
	EndIf;
	
	ServiceVersion = ServiceVersionFromForm(Form);
	NameUris = NamespaceURI(ServiceVersion);
	
	AdditionalParameters = StructureAdditionalParameters();
	FillInAdditionalParameters(Form, AdditionalParameters, Factory);
	
	ParametersForEndingMoveType = Factory.Type(NameUris, "ПараметрыЗавершенияПеремещения");
	AdditionalWSParameters = Factory.Create(ParametersForEndingMoveType);
	
	FillPropertyValues(AdditionalWSParameters, AdditionalParameters);
	
	Return AdditionalWSParameters;
	
EndFunction

// Returns a structure for storing data for additional parameters of the warehouse operation "Moving goods".
//
// Returns:
//	Structure
//
Function StructureAdditionalParameters()
	
	StructureAdditionalParameters = New Structure();
	
	StructureAdditionalParameters.Insert("ReceivingArea");
	StructureAdditionalParameters.Insert("ShippingZone");
	StructureAdditionalParameters.Insert("SelectionScanned");
	
	Return StructureAdditionalParameters;
	
EndFunction

// Fills in the 'additional Parameters' with data from the Move operation fold.
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//	AdditionalParameters - Structure
//	Factory - XDTOFactory
//
Procedure FillInAdditionalParameters(Form, AdditionalParameters, Factory)
	
	ServiceVersion = ServiceVersionFromForm(Form);
	NameUris = NamespaceURI(ServiceVersion);
	ModeSettings = Form.ModeSettings;
	
	AdditionalParameters.ReceivingArea = WSStorageArea(ModeSettings.ReceivingArea, Factory, NameUris);
	AdditionalParameters.ShippingZone = WSStorageArea(ModeSettings.ShippingZone, Factory, NameUris);
	AdditionalParameters.SelectionScanned = ModeSettings.SelectionScanned;
	
EndProcedure

#EndRegion

#Region DeserializationOfWarehouseTaskCompletionParameters

// Returns the 'parameter of the Assignment' after the warehouse operation is completed.
//
// Parameters:
//	Job - DocumentRef - link to the warehouse task document,
//	SourceExecutor - CatalogRef.Users - source performer of the warehouse task,
//	ScannedGoods - ValueTable - table of scanned items in the warehouse task document,
//	JobType - String - the type of warehouse job,
//	AdditionalParameters - Structure, Undefined - parameters of the "Move" warehouse operation.
//	ScannedStampValues - ValueList:
//		*Value - CatalogRef - mapped link
//		*Presentation - String - the value of the barcode of the brand
//
// Returns:
//	Structure
//
Function TaskCompletionParameters_(
	Job, SourceExecutor, ScannedGoods, JobType, AdditionalParameters, ScannedStampValues)
	
	If JobType = "Recalculate" Then
		
		EndParameters = 
			WorkplaceOfWarehouseWorkerApplicationInterface.NewCompleteWarehouseTaskParameters();
		EndParameters.Job = Job;
		EndParameters.VTScannedProducts = ScannedGoods;
		JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteWarehouseTask(
			EndParameters);
		
	ElsIf JobType = "Filter" Then
		
		EndParameters = 
			WorkplaceOfWarehouseWorkerApplicationInterface.NewCompleteWarehouseTaskParameters();
		EndParameters.Job = Job;
		EndParameters.GoodsForScanning = ScannedGoods;
		EndParameters.ScannedStampValues = ScannedStampValues;
		JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteWarehouseTask(
			EndParameters);
		
	ElsIf JobType = "Location" Then
		
		EndParameters = 
			WorkplaceOfWarehouseWorkerApplicationInterface.NewCompleteWarehouseTaskParameters();
		EndParameters.Job = Job;
		EndParameters.GoodsForScanning = ScannedGoods;
		EndParameters.ScannedStampValues = ScannedStampValues;
		JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteWarehouseTask(
			EndParameters);
		
	ElsIf JobType = "Move" Then
		
		JobParameters = TaskCompletionParametersMovingGoods(Job, SourceExecutor, ScannedGoods,
			AdditionalParameters);
		
	ElsIf JobType = "PickingCheck" Then
		
		JobParameters = TaskCompletionParametersCheckSelection(Job, SourceExecutor, ScannedGoods,
		ScannedStampValues);
		
	EndIf;
	
	Return JobParameters;
	
EndFunction

// Parameters:
// 		Job - DocumentRef, UUID - 
// 		SourceExecutor - CatalogRef.Users, UUID -
// 		GoodsForScanning - ValueTable
// 		AdditionalParameters - Structure, XDTODataValue, XDTODataObject, Undefined - Contains:
// 			* ReceivingArea - CatalogRef.StorageBins
// 			* ShippingZone - CatalogRef.StorageBins
// 	
// Returns:
// 		See WorkplaceOfWarehouseWorkerApplicationInterface.CompleteWarehouseTask
//
Function TaskCompletionParametersMovingGoods(Job, SourceExecutor, GoodsForScanning,
		AdditionalParameters)
	
	SelectionScanned = AdditionalParameters.ОтборОтсканирован;
	ReceivingArea = CatalogLink(AdditionalParameters.ЗонаПриемки["Ref"], "StorageBins");
	ShippingZone = CatalogLink(AdditionalParameters.ЗонаОтгрузки["Ref"], "StorageBins");
	
	EndParameters = 
		WorkplaceOfWarehouseWorkerApplicationInterface.NewCompleteWarehouseTaskParameters();
	EndParameters.Job = Job;
	EndParameters.GoodsForScanning = GoodsForScanning;
	EndParameters.ReceivingArea = ReceivingArea;
	EndParameters.ShippingZone = ShippingZone;
	EndParameters.SelectionScanned = SelectionScanned;
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteWarehouseTask(
		EndParameters);
	
	Return JobParameters;
	
EndFunction

// Returns 'Parameterization' after the warehouse operation "selection Check" is completed.
//
// Parameters:
//	Job - DocumentRef - link to the warehouse task document.
//	SourceExecutor - CatalogRef.Users - source performer of the warehouse task,
//	ScannedGoods - ValueTable - table of scanned items in the warehouse task document.
//	ScannedStampValues - ValueTable
//
// Returns:
//	Structure
//
Function TaskCompletionParametersCheckSelection(Job, 
													SourceExecutor, 
													ScannedGoods,
													ScannedStampValues)
	
	AttributesRow = "Warehouse, Premise";
	TaskAttributes = Common.ObjectAttributesValues(Job, AttributesRow);
	
	AddressStorageIsUsed = WarehousesServer.UseBinLocationWarehousing(TaskAttributes.Warehouse,
		TaskAttributes.Premise, , False);
	
	JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteTaskCheckSelection(
		TaskAttributes.Warehouse, TaskAttributes.Premise, Job, ScannedGoods, Undefined,
		AddressStorageIsUsed,ScannedStampValues);
	
	Return JobParameters;
	
EndFunction

// Fills in the 'task Parameters' with data from the warehouse task document after the warehouse operation is completed.
//
// Parameters:
//	JobParameters - Structure,
//	WSJobParameters - XDTODataValue- Parameters of the WMSMobileClientExchange XDTO package-parameters of the warehouse task.
//
Procedure FillInWarehouseTaskCompletionParameters(JobParameters, WSJobParameters)
	
	If Not WSJobParameters.Success Then
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = WSJobParameters.MessageText;
	EndIf;
	
	If WSJobParameters.Job <> Undefined Then
		Job = TaskLink(WSJobParameters.Job, "Location");
		
		JobParameters.Insert("Job", Job);
	EndIf;
	
	If WSJobParameters.NotShippedGoods <> Undefined Then
		TableUnloadedGoods = TableUnloadedGoods();
		NotShippedGoods = NotShippedGoods(TableUnloadedGoods, WSJobParameters.NotShippedGoods);
		
		JobParameters.Insert("NotShippedGoods", NotShippedGoods);
	EndIf;
	
EndProcedure

#EndRegion

#Region SerializationOfOtherXDTOPackageObjects

// Returns The 'Task Completion Parameterssetter'.
//
// Parameters:
//	JobParameters - Structure - parameters of the warehouse task.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Parametersperformance of the XDTO task of the WMSMobileClientExchange package.
//
Function WarehouseTaskCompletionParametersWS(JobParameters, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	JobParametersType = XDTOFactory.Type(NameUris, "ПараметрыЗавершенияСкладскогоЗадания");
	WSJobParameters = XDTOFactory.Create(JobParametersType);
	
	WSJobParameters.Успешно = JobParameters.ReturnCode = 1;
	WSJobParameters.ТекстСообщения = JobParameters.MessageText;
	
	If JobParameters.Property("Job") Then
		TaskID_ = TrimAll(JobParameters.Job.UUID());
		WSJobParameters.Задание = TaskID_;
	EndIf;
	
	If JobParameters.Property("NotShippedGoods") Then
		AddDataToUnloadedProducts(JobParameters.NotShippedGoods);
		WSJobParameters.НеотгружаемыеТовары = UnloadedWSGoods(JobParameters.NotShippedGoods, ServiceVersion);
	EndIf;


	Return WSJobParameters;
	
EndFunction

// Returns 'Parameters For Processing Scanned Goods'.
//
// Parameters:
//	JobParameters - Structure - parameters of the warehouse task.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Processing parametres of scanned products of the XDTO package WMSMobileClientExchange.
//
Function ParametersForProcessingScannedGoodsInWS(JobParameters, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	JobParametersType = XDTOFactory.Type(NameUris, "ПараметрыОбработкиОтсканированныхТоваров");
	WSJobParameters = XDTOFactory.Create(JobParametersType);
	
	WSJobParameters.Успешно = JobParameters.ReturnCode = 1;
	WSJobParameters.ТекстСообщения = JobParameters.MessageText;
	
	If WSJobParameters.Успешно Then
		WSJobParameters.ТоварыОтбор = WsWarehouseTaskProducts(
			JobParameters.GoodsFilter, "Filter","SelectionProductPlacementProductsSelection", ServiceVersion);
	EndIf;
	
	Return WSJobParameters;
	
EndFunction

// Returns 'Task Cancelation Parameters'.
//
// Parameters:
//	JobParameters - Structure - parameters of the warehouse task.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Parameters of the cancellation of the task of the XDTO package WMSMobileClientExchange.
//
Function ParametersForCancelingWarehouseTaskWS(JobParameters, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	JobParametersType = XDTOFactory.Type(NameUris, "ПараметрыОтменыВыполненияЗадания");
	WSJobParameters = XDTOFactory.Create(JobParametersType);
	
	WSJobParameters.Успешно = JobParameters.ReturnCode = 1;
	WSJobParameters.ТекстСообщения = JobParameters.MessageText;
	
	Return WSJobParameters;
	
EndFunction

// Returns The 'Parametrisation'.
//
// Parameters:
//	ReceivingShippingAreas - ValueTable - table of storage cells.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Parameters of the XDTO package WMSMobileClientExchange listbox.
//
Function WSCellListParameters(ReceivingShippingAreas, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	CellListParametersType = XDTOFactory.Type(NameUris, "ПараметрыСпискаЯчеек");
	WSCellListParameters = XDTOFactory.Create(CellListParametersType);
	
	WSCellListParameters.Успешно = True;
	WSCellListParameters.ТекстСообщения = "";
	WSCellListParameters.ЗоныПриемкиОтгрузки = XDTOShipmentAcceptanceZones(ReceivingShippingAreas, ServiceVersion);
	
	Return WSCellListParameters;
	
EndFunction

// Returns 'Parameters Of The Fire Cell'.
//
// Parameters:
//	CellParameters_ -See WorkplaceOfWarehouseWorkerApplicationInterface.CellGoods
//	CellGoods - ValueTable - table of products stored in the cell.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Product parameterscells of the XDTO package WMSMobileClientExchange:
//		* Success - Boolean
//		* MessageText - String
//		* Cell - See WSStorageCell
//		* CellGoods - See XDTOCellProducts
//
Function WSCellProductParameters(CellParameters_, CellGoods, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	CellProductParametersType = XDTOFactory.Type(NameUris, "ПараметрыТоваровЯчейки");
	WSCellProductParameters = XDTOFactory.Create(CellProductParametersType);
	
	If (CellParameters_ = Undefined)
		And (CellGoods = Undefined) Then
		
		WSCellProductParameters.Успешно = False;
		WSCellProductParameters.ТекстСообщения = NStr("vi = 'Không thể lấy thông tin mã vạch.';
														|ru = 'Не удалось получить информацию по штрихкоду';
														|en = 'Cannot receive barcode information'; fa = 'Cannot receive barcode information';
														|it = 'Non è stato possibile ricevere l''informazione sul codice a barre';
														|pl = 'Nie udało się uzyskać informacji za kodem kreskowym';
														|tr = 'Barkod bilgisi alınamadı'");
		
	Else
		WSCellProductParameters.Успешно = True;
		WSCellProductParameters.ТекстСообщения = "";
		
		If Not (CellParameters_ = Undefined) Then
			WSCellProductParameters.Ячейка = WSStorageCell(CellParameters_, XDTOFactory, NameUris);
		Else
			WSCellProductParameters.Ячейка = Undefined;
		EndIf;
		
		WSCellProductParameters.ТоварыЯчейки = XDTOCellProducts(CellGoods, ServiceVersion);
	EndIf;
	
	Return WSCellProductParameters;
	
EndFunction

#EndRegion

#Region DeserializationOfOtherXDTOPackageObjects

// Fills in the 'parameterization' with data from the document 'Selection (placement) of goods' 
// after the process of selecting goods from the cells of the warehouse operation "Movement"is completed.
//
// Parameters:
//	JobParameters - Structure,
//	WSJobParameters - XDTODataValue- Parameters of the WMSMobileClientExchange XDTO package-parameters of the warehouse task,
//	Object - DataProcessorObject.WorkplaceOfWarehouseWorker
//
Procedure FillInParametersForProcessingScannedProducts(JobParameters, WSJobParameters, Object)
	
	If Not WSJobParameters.Success Then
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = WSJobParameters.MessageText;
	EndIf;
	
	If WSJobParameters.GoodsFilter <> Undefined Then
		GoodsFilter = Object.GoodsFilter.Unload();
		GoodsFilter.Clear();
		
		JobParameters.GoodsFilter = WarehouseTaskItems(GoodsFilter, WSJobParameters.GoodsFilter);
	EndIf;
	
EndProcedure

// Fills in the 'task Parameters' with the initial data of the warehouse task document before accepting the task for execution.
//
// Parameters:
//	JobParameters - Structure,
//	WSJobParameters - XDTODataValue- Parameters of the WMSMobileClientExchange XDTO package-parameters of the warehouse task.
//
Procedure FillInTaskCancellationParameters(JobParameters, WSJobParameters)
	
	If Not WSJobParameters.Success Then
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = WSJobParameters.MessageText;
	EndIf;
	
EndProcedure

#EndRegion

#Region SerializingEnumerations

// Returns the value of the "order of Workingcommitment" enumeration.
//
// Parameters:
//	OrderInWhichWSJobIsProcessed - XDTODataValue - Order of processing of the xdto package's master task 
//		WMSMobileClientExchange - the order in which the warehouse task is processed.
//
// Returns:
//	 EnumRef.WarehouseJobProcessingProcedure - enumeration value.
//
Function JobProcessingProcedure(OrderInWhichWSJobIsProcessed)
	
	OrderOfObjectProcessing = Metadata.Enums.WarehouseJobProcessingProcedure.EnumValues.Find(
		OrderInWhichWSJobIsProcessed);
	
	If OrderOfObjectProcessing <> Undefined Then
		ValueIndex = Metadata.Enums.WarehouseJobProcessingProcedure.EnumValues.IndexOf(
			OrderOfObjectProcessing);
		ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.Get(ValueIndex);
	Else
		ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.EmptyRef();
	EndIf;
	
	Return ProcessingProcedure_;
	
EndFunction

// Returns the value of the "product selection Statusdistribution" enumeration.
//
// Parameters:
//	JobStatusWS - XDTODataValue - Statusselectionsallocation of XDTO-package items 
//		WMSMobileClientExchange - status of the document "selection (placement) of products".
//
// Returns:
//	 EnumRef.StatusesOfGoodsPickingPlacement - enumeration value.
//
Function ProductPlacementSelectionStatus(JobStatusWS)
	
	TaskStatusObject = Metadata.Enums.StatusesOfGoodsPickingPlacement.EnumValues.Find(
		JobStatusWS);
	
	If TaskStatusObject <> Undefined Then
		ValueIndex = Metadata.Enums.StatusesOfGoodsPickingPlacement.EnumValues.IndexOf(
			TaskStatusObject);
		JobStatus = Enums.StatusesOfGoodsPickingPlacement.Get(ValueIndex);
	Else
		JobStatus = Enums.StatusesOfGoodsPickingPlacement.EmptyRef();
	EndIf;
	
	Return JobStatus;
	
EndFunction

// Returns the enumeration value "Statuspresetcaption".
//
// Parameters:
//	JobStatusWS - XDTODataValue - Statusaccounts of XDTO package products 
//		WMSMobileClientExchange - status of the document "product Recalculations".
//
// Returns:
//	 EnumRef.InventoryRecountStatuses - enumeration value.
//
Function StatusOfRecalculationOfGoods(JobStatusWS)
	
	TaskStatusObject = Metadata.Enums.InventoryRecountStatuses.EnumValues.Find(
		JobStatusWS);
	
	If TaskStatusObject <> Undefined Then
		ValueIndex = Metadata.Enums.InventoryRecountStatuses.EnumValues.IndexOf(
			TaskStatusObject);
		JobStatus = Enums.InventoryRecountStatuses.Get(ValueIndex);
	Else
		JobStatus = Enums.InventoryRecountStatuses.EmptyRef();
	EndIf;
	
	Return JobStatus;
	
EndFunction

// Returns the value of the "status of incoming Orders" enumeration.
//
// Parameters:
//	JobStatusWS - XDTODataValue - Status of incoming xdto package headers 
//		WMSMobileClientExchange - status of the document "Receipt order for goods".
//
// Returns:
//	 EnumRef.GoodsReceiptNoteStatuses - enumeration value.
//
Function StatusOfReceiptOrderForGoods(JobStatusWS)
	
	TaskStatusObject = Metadata.Enums.GoodsReceiptNoteStatuses.EnumValues.Find(
		JobStatusWS);
	
	If TaskStatusObject <> Undefined Then
		ValueIndex = Metadata.Enums.GoodsReceiptNoteStatuses.EnumValues.IndexOf(
			TaskStatusObject);
		JobStatus = Enums.GoodsReceiptNoteStatuses.Get(ValueIndex);
	Else
		JobStatus = Enums.GoodsReceiptNoteStatuses.EmptyRef();
	EndIf;
	
	Return JobStatus;
	
EndFunction

// Returns the enumeration value of "Statusindicator".
//
// Parameters:
//	JobStatusWS - XDTODataValue - Statusindicator XDTO package 
//		WMSMobileClientExchange - status of the document "Expenditure order for goods".
//
// Returns:
//	 EnumRef.GoodsIssueNoteStatuses - enumeration value.
//
Function SpendingOrderStatus(JobStatusWS)
	
	TaskStatusObject = Metadata.Enums.GoodsIssueNoteStatuses.EnumValues.Find(
		JobStatusWS);
	
	If TaskStatusObject <> Undefined Then
		ValueIndex = Metadata.Enums.GoodsIssueNoteStatuses.EnumValues.IndexOf(
			TaskStatusObject);
		JobStatus = Enums.GoodsIssueNoteStatuses.Get(ValueIndex);
	Else
		JobStatus = Enums.GoodsIssueNoteStatuses.EmptyRef();
	EndIf;
	
	Return JobStatus;
	
EndFunction

// Returns the value of the enumeration "types of measured Values".
//
// Parameters:
//	TypeOfMeasuredValueWS - XDTODataValue - Types of measured values of the XDTO package 
//		WMSMobileClientExchange - type of unit of measurement to be measured.
//
// Returns:
//	 EnumRef.TypesOfMeasuredValues - enumeration value.
//
Function MeasuredValueType(TypeOfMeasuredValueWS)
	
	TypeOfMeasuredValueObject = Metadata.Enums.TypesOfMeasuredValues.EnumValues.Find(
		TypeOfMeasuredValueWS);
	
	If TypeOfMeasuredValueObject <> Undefined Then
		ValueIndex = Metadata.Enums.TypesOfMeasuredValues.EnumValues.IndexOf(
			TypeOfMeasuredValueObject);
		MeasuredValueType = Enums.TypesOfMeasuredValues.Get(ValueIndex);
	Else
		MeasuredValueType = Enums.TypesOfMeasuredValues.EmptyRef();
	EndIf;
	
	Return MeasuredValueType;
	
EndFunction

// Returns the value of the "nomenclature Types" enumeration.
//
// Parameters:
//	ItemTypeWS - XDTODataValue - Nomenclature typesof the xdto package WMSMobileClientExchange - the type of nomenclature.
//
// Returns:
//	 EnumRef.ItemsTypes - enumeration value.
//
Function ItemsType(ItemTypeWS)
	
	ItemProductType_ = Metadata.Enums.ItemsTypes.EnumValues.Find(
		ItemTypeWS);
	
	If ItemProductType_ <> Undefined Then
		ValueIndex = Metadata.Enums.ItemsTypes.EnumValues.IndexOf(ItemProductType_);
		ItemsType = Enums.ItemsTypes.Get(ValueIndex);
	Else
		ItemsType = Enums.ItemsTypes.EmptyRef();
	EndIf;
	
	Return ItemsType;
	
EndFunction

// Returns the value of the "type of child Cells" enumeration.
//
// Parameters:
//	CellTypeWS - XDTODataValue - Cell type of the WMSMobileClientExchange XDTO package-the cell type.
//
// Returns:
//	 EnumRef.TypesOfStorageCells - enumeration value.
//
Function StorageBinType(CellTypeWS) Export
	
	StorageCellTypeObject = Metadata.Enums.TypesOfStorageCells.EnumValues.Find(CellTypeWS);
	
	If StorageCellTypeObject <> Undefined Then
		ValueIndex = Metadata.Enums.TypesOfStorageCells.EnumValues.IndexOf(StorageCellTypeObject);
		StorageBinType = Enums.TypesOfStorageCells.Get(ValueIndex);
	Else
		StorageBinType = Enums.TypesOfStorageCells.EmptyRef();
	EndIf;
	
	Return StorageBinType;
	
EndFunction

// Returns the value of the enumeration "precision of specificationsworthinessws".
//
// Parameters:
//	AccuracyOfIndicationOfExpirationDateWS - XDTODataObject 
//
// Returns:
//	 EnumRef.AccuracyOfShelfLifeIndication - The accuracy of the indication of the suitability of the WS is the value of the enumeration.
//
Function AccuracyOfIndicationOfExpirationDate(AccuracyOfIndicationOfExpirationDateWS)
	
	AccuracyOfSpecifyingExpirationDateOfObject =
		Metadata.Enums.AccuracyOfShelfLifeIndication.EnumValues.Find(AccuracyOfIndicationOfExpirationDateWS);
	
	If AccuracyOfSpecifyingExpirationDateOfObject <> Undefined Then
		ValueIndex = Metadata.Enums.AccuracyOfShelfLifeIndication.EnumValues.IndexOf(
			AccuracyOfSpecifyingExpirationDateOfObject);
		AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.Get(ValueIndex);
	Else
		AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.EmptyRef();
	EndIf;
	
	Return AccuracyOfIndicationOfExpirationDate;
	
EndFunction

#EndRegion

#Region DeserializationOfEnumerations

// Returns the value of the 'xdto' action of the 'loading order' XDTO package WMSMobileClientExchange.
//
// Parameters:
//	ActionWithShipmentOrderString - EnumRef.ActionsWithGoodsIssueNoteRows - action with the lines of the Spending order for goods.
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function ActionWithWSShipmentOrderString(ActionWithShipmentOrderString, NameUris)
	
	ActionWithShipmentOrderStringType = XDTOFactory.Type(NameUris, "ДействияСоСтрокамиОрдеровНаОтгрузку");
	
	If ValueIsFilled(ActionWithShipmentOrderString) Then
		ValueIndex = Enums.ActionsWithGoodsIssueNoteRows.IndexOf(ActionWithShipmentOrderString);
		MetadataObject = 
			Metadata.Enums.ActionsWithGoodsIssueNoteRows.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		ActionWithShippingOrderString = MetadataObject.Name;
	Else
		ActionWithShippingOrderString = "";
	EndIf;
	
	ActionWithWSShipmentOrderString = XDTOFactory.Create(ActionWithShipmentOrderStringType,
		ActionWithShippingOrderString);
	
	Return ActionWithWSShipmentOrderString;
	
EndFunction

// Returns The Xdto Value 'The order of processing the' xdto ' task of the WMSMobileClientExchange package.
//
// Parameters:
//	JobProcessingProcedure - EnumRef.WarehouseJobProcessingProcedure -the procedure for processing a warehouse task,
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function OrderInWhichWSJobIsProcessed(JobProcessingProcedure, NameUris)
	
	JobProcessingProcedureType = XDTOFactory.Type(NameUris, "ПорядокОбработкиСкладскогоЗадания");
	
	If ValueIsFilled(JobProcessingProcedure) Then
		ValueIndex = Enums.WarehouseJobProcessingProcedure.IndexOf(JobProcessingProcedure);
		MetadataObject = 
			Metadata.Enums.WarehouseJobProcessingProcedure.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		OrderInWhichTaskIsProcessedAsString = MetadataObject.Name;
	Else
		OrderInWhichTaskIsProcessedAsString = "";
	EndIf;
	
	OrderInWhichWSJobIsProcessed = XDTOFactory.Create(JobProcessingProcedureType, OrderInWhichTaskIsProcessedAsString);
	
	Return OrderInWhichWSJobIsProcessed;
	
EndFunction

// Returns the value of the Xdto 'statuses of product placements' of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	Status - EnumRef.StatusesOfGoodsPickingPlacement - status of the document 'selection (placement) of products',
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function ProductPlacementSelectionStatusWS(Status, NameUris)
	
	StatusType = XDTOFactory.Type(NameUris, "СтатусыОтборовРазмещенийТоваров");
	
	If ValueIsFilled(Status) Then
		ValueIndex = Enums.StatusesOfGoodsPickingPlacement.IndexOf(Status);
		MetadataObject = 
			Metadata.Enums.StatusesOfGoodsPickingPlacement.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		StatusString = MetadataObject.Name;
	Else
		StatusString = "";
	EndIf;
	
	WSStatus = XDTOFactory.Create(StatusType, StatusString);
	
	Return WSStatus;
	
EndFunction

// Returns The Xdto Value'Status of the' XDTO ' package WMSMobileClientExchange account.
//
// Parameters:
//	Status - EnumRef.InventoryRecountStatuses - the status of the document 'supplementary goods',
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function StatusOfGoodsRecalculationWS(Status, NameUris)
	
	StatusType = XDTOFactory.Type(NameUris, "СтатусыПересчетовТоваров");
	
	If ValueIsFilled(Status) Then
		ValueIndex = Enums.InventoryRecountStatuses.IndexOf(Status);
		MetadataObject = 
			Metadata.Enums.InventoryRecountStatuses.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		StatusString = MetadataObject.Name;
	Else
		StatusString = "";
	EndIf;
	
	WSStatus = XDTOFactory.Create(StatusType, StatusString);
	
	Return WSStatus;
	
EndFunction

// Returns the value of the Xdto 'status of incoming Orders' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	Status - EnumRef.GoodsReceiptNoteStatuses - status of the document 'Receipt order for goods',
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function StatusOfWsReceiptOrder(Status, NameUris)
	
	StatusType = XDTOFactory.Type(NameUris, "СтатусыПриходныхОрдеров");
	
	If ValueIsFilled(Status) Then
		ValueIndex = Enums.GoodsReceiptNoteStatuses.IndexOf(Status);
		MetadataObject = 
			Metadata.Enums.GoodsReceiptNoteStatuses.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		StatusString = MetadataObject.Name;
	Else
		StatusString = "";
	EndIf;
	
	WSStatus = XDTOFactory.Create(StatusType, StatusString);
	
	Return WSStatus;
	
EndFunction

// Returns the value of the Xdto 'status of outgoing Orders' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	Status - EnumRef.GoodsIssueNoteStatuses - status of the document 'Expenditure order for goods',
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function StatusOfWsSpendingOrder(Status, NameUris)
	
	StatusType = XDTOFactory.Type(NameUris, "СтатусыРасходныхОрдеров");
	
	If ValueIsFilled(Status) Then
		ValueIndex = Enums.GoodsIssueNoteStatuses.IndexOf(Status);
		MetadataObject = 
			Metadata.Enums.GoodsIssueNoteStatuses.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		StatusString = MetadataObject.Name;
	Else
		StatusString = "";
	EndIf;
	
	WSStatus = XDTOFactory.Create(StatusType, StatusString);
	
	Return WSStatus;
	
EndFunction

// Returns the xdto 'task Type' Value of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	JobType - String - the type of warehouse job,
//	Factory - XDTOFactory, Undefined - Factory of the xdto proxy connection.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - type of warehouse task.
//
Function JobTypeWS(JobType, Factory, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	TypesOfTasksType = Factory.Type(NameUris, "ТипыЗаданий");
	JobTypeWS = Factory.Create(TypesOfTasksType, JobType);
	
	Return JobTypeWS;
	
EndFunction

// Returns the value of Xdto 'types of measured Values' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	MeasuredValueType - EnumRef.TypesOfMeasuredValues - type of measured value unit of measurement,
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function TypeOfMeasuredValueWS(MeasuredValueType, NameUris)
	
	MeasuredValueTypeType = XDTOFactory.Type(NameUris, "ТипыИзмеряемыхВеличин");
	
	If ValueIsFilled(MeasuredValueType) Then
		ValueIndex = Enums.TypesOfMeasuredValues.IndexOf(MeasuredValueType);
		MetadataObject = 
			Metadata.Enums.TypesOfMeasuredValues.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		TypeOfMeasuredValueByString = MetadataObject.Name;
	Else
		TypeOfMeasuredValueByString = "";
	EndIf;
	
	TypeOfMeasuredValueWS = XDTOFactory.Create(MeasuredValueTypeType, TypeOfMeasuredValueByString);
	
	Return TypeOfMeasuredValueWS;
	
EndFunction

// Returns the value of Xdto 'nomenclature Types' of the xdto package WMSMobileClientExchange.
//
// Parameters:
//	ItemsType - EnumRef.ItemsTypes - the type of item,
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function ItemTypeWS(ItemsType, NameUris)
	
	ItemsTypeType = XDTOFactory.Type(NameUris, "ТипыНоменклатуры");
	
	If ValueIsFilled(ItemsType) Then
		ValueIndex = Enums.ItemsTypes.IndexOf(ItemsType);
		MetadataObject = 
			Metadata.Enums.ItemsTypes.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		ItemTypeByLine = MetadataObject.Name;
	Else
		ItemTypeByLine = "";
	EndIf;
	
	ItemTypeWS = XDTOFactory.Create(ItemsTypeType, ItemTypeByLine);
	
	Return ItemTypeWS;
	
EndFunction

// Returns the value of Xdto 'cell type' of the xdto package WMSMobileClientExchange.
//
// Parameters:
//	CellType - EnumRef.TypesOfStorageCells - cell type,
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function StorageCellTypeWS(CellType, NameUris) Export
	
	StorageBinTypeType = XDTOFactory.Type(NameUris, "ТипыСкладскихЯчеек");
	
	If ValueIsFilled(CellType) Then
		ValueIndex = Enums.TypesOfStorageCells.IndexOf(CellType);
		MetadataObject = 
			Metadata.Enums.TypesOfStorageCells.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		StorageCellTypeByRow = MetadataObject.Name;
	Else
		StorageCellTypeByRow = "";
	EndIf;
	
	TypeOfStorageCellByStringWS = XDTOFactory.Create(StorageBinTypeType, StorageCellTypeByRow);
	
	Return TypeOfStorageCellByStringWS;
	
EndFunction

// Returns the value of Xdto 'accuracy of serviceability' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	AccuracyOfIndicationOfExpirationDate - XDTODataObject,Undefined
//	NameUris - String - The URI of the space is the name of the XDTO package WMSMobileClientExchange*.
//
// Returns:
//	XDTODataValue
//
Function AccuracyOfIndicationOfExpirationDateWS(AccuracyOfIndicationOfExpirationDate, NameUris)
	
	AccuracyOfIndicationOfExpirationDateType = XDTOFactory.Type(NameUris, "ТочностиУказанияСрокаГодности");
	
	If ValueIsFilled(AccuracyOfIndicationOfExpirationDate) Then
		ValueIndex = Enums.AccuracyOfShelfLifeIndication.IndexOf(AccuracyOfIndicationOfExpirationDate);
		MetadataObject = 
			Metadata.Enums.AccuracyOfShelfLifeIndication.EnumValues.Get(ValueIndex); // MetadataObjectEnum
		AccuracyOfExpirationDateLine = MetadataObject.Name;
	Else
		AccuracyOfExpirationDateLine = "";
	EndIf;
	
	AccuracyOfIndicationOfExpirationDateWS = XDTOFactory.Create(AccuracyOfIndicationOfExpirationDateType,
		AccuracyOfExpirationDateLine);
	
	Return AccuracyOfIndicationOfExpirationDateWS;
	
EndFunction

#EndRegion

#Region SerializingSimpleObjects

// Returns the value of the Xdto 'nomenclature View' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	RowOfGoods - ValueTableRow
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function ItemKindWS(RowOfGoods, Factory, NameUris)
	
	StructureOfProductType = StructureOfProductType();
	
	StructureOfProductType.Ref = TrimAll(RowOfGoods.ProductKind.UUID());
	StructureOfProductType.Description = "";
	
	StructureOfProductType.ItemsType = ItemTypeWS(RowOfGoods.ItemsType, NameUris);
	StructureOfProductType.PrecisionOfBatchShelfLifeIndication = 
		AccuracyOfIndicationOfExpirationDateWS(RowOfGoods.PrecisionOfBatchShelfLifeIndication, NameUris);
	
	PropertiesToExclude = "ItemsType, PrecisionOfBatchShelfLifeIndication";
	FillPropertyValues(StructureOfProductType, RowOfGoods, , PropertiesToExclude);
	
	ProductKindType = Factory.Type(NameUris, "ВидыНоменклатуры");
	ItemKindWS = Factory.Create(ProductKindType);
	
	FillPropertyValues(ItemKindWS, StructureOfProductType);
	
	Return ItemKindWS;
	
EndFunction

// Returns The Xdto Value 'Measurement units' of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	AttributeDescription - String - name of the type of unit of measurement,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function UnitOfMeasurementWS(RowOfGoods, AttributeDescription, Factory, NameUris)
	
	MeasuredValueType = Undefined;
	UnitStructure = UnitStructure();
	
	If AttributeDescription = "UnitOfMeasure" Then
		UnitOfMeasure = RowOfGoods.UnitOfMeasure;
		Description = RowOfGoods.UnitOfMeasureDescription;
		
		If RowOfGoods.Owner().Columns.Find("MeasuredValueType") <> Undefined Then
			MeasuredValueType = RowOfGoods.MeasuredValueType;
		EndIf;
	Else
		
		If AttributeDescription = "UnitOfMeasureForWeight" Then
			UnitOfMeasure = RowOfGoods.UnitOfMeasureForWeight;
			Description = RowOfGoods.NameOfWeightUnitOfMeasure;
		Else
			UnitOfMeasure = RowOfGoods.UnitOfMeasureForVolume;
			Description = RowOfGoods.NameOfVolumeUnitOfMeasure;
		EndIf;
		
	EndIf;
	
	UnitStructure.Ref = TrimAll(UnitOfMeasure.UUID());
	UnitStructure.Description = TrimAll(Description);
	
	If MeasuredValueType <> Undefined Then
		UnitStructure.MeasuredValueType = TypeOfMeasuredValueWS(MeasuredValueType, NameUris);
	EndIf;
	
	UnitOfMeasureType = Factory.Type(NameUris, "ЕдиницыИзмерения");
	UnitOfMeasurementWS = Factory.Create(UnitOfMeasureType);
	
	FillPropertyValues(UnitOfMeasurementWS, UnitStructure);
	
	Return UnitOfMeasurementWS;
	
EndFunction

// Returns the xdto Value Of the 'storage Cells' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	StorageArea - CatalogRef.StorageBins - area of acceptance (shipment) of goods,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function WSStorageArea(StorageArea, Factory, NameUris) Export
	
	StorageAreaType = Factory.Type(NameUris, "СкладскиеЯчейки");
	WSStorageArea = Factory.Create(StorageAreaType);
	
	WSStorageArea.Ref = TrimAll(StorageArea.UUID());
	WSStorageArea.Code = TrimAll(AttributeValue(StorageArea, "Code"));
	
	WSStorageArea.StorageBinType = StorageCellTypeWS(AttributeValue(StorageArea,
		"StorageBinType"), NameUris);
	WSStorageArea.Barcode = BarcodingOfPrintForms.NumericCodeFromLink(StorageArea);
	
	Return WSStorageArea;
	
EndFunction

// Returns the xdto 'Destination' Value of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function WSAssignment(RowOfGoods, Factory, NameUris)
	
	AssignmentStructure = StructureOfCatalog();
	
	AssignmentStructure.Ref = TrimAll(RowOfGoods.Purpose.UUID());
	AssignmentStructure.Description = TrimAll(RowOfGoods.PurposeDescription);
	
	PurposeType = Factory.Type(NameUris, "Назначения");
	Purpose = Factory.Create(PurposeType);
	
	FillPropertyValues(Purpose, AssignmentStructure);
	
	Return Purpose;
	
EndFunction

// Returns the xdto 'Nomenclature' Value of the xdto package WMSMobileClientExchange.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function WSProduct(RowOfGoods, Factory, NameUris)
	
	ProductStructure_ = ProductStructure_();
	
	ProductStructure_.Ref = TrimAll(RowOfGoods.Products.UUID());
	ProductStructure_.Description = TrimAll(RowOfGoods.ItemName);
	
	If RowOfGoods.Owner().Columns.Find("ProductIDOfItems") <> Undefined Then
		ProductStructure_.SKU = TrimAll(RowOfGoods.ProductIDOfItems);
		ProductStructure_.LongDesc = TrimAll(RowOfGoods.ItemsDescription);
	EndIf;
	
	If RowOfGoods.Owner().Columns.Find("ProductKind") <> Undefined Then
		If ValueIsFilled(RowOfGoods.ProductKind) Then
			ProductStructure_.ProductKind = ItemKindWS(RowOfGoods, Factory, NameUris);
		EndIf;
	EndIf;
	
	ProductStructure_.UnitOfMeasure = UnitOfMeasurementWS(RowOfGoods, "UnitOfMeasure",
		Factory, NameUris);
	
	If RowOfGoods.Owner().Columns.Find("UnitOfMeasureForWeight") <> Undefined Then
		ProductStructure_.UnitOfMeasureForWeight = UnitOfMeasurementWS(RowOfGoods, "UnitOfMeasureForWeight",
			Factory, NameUris);
		
		ProductStructure_.UnitOfMeasureForVolume = UnitOfMeasurementWS(RowOfGoods, "UnitOfMeasureForVolume",
			Factory, NameUris);
	EndIf;
	
	If RowOfGoods.Owner().Columns.Find("ItemsBarcode") <> Undefined Then
		ProductStructure_.Barcode = RowOfGoods.ItemsBarcode;
	EndIf;
	
	ProductsType = Factory.Type(NameUris, "Номенклатура");
	WSProduct = Factory.Create(ProductsType);
	
	FillPropertyValues(WSProduct, ProductStructure_);
	
	Return WSProduct;
	
EndFunction

// Returns the xdto 'Users' Value of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	User - CatalogRef.Users - the contractor warehouse jobs,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	 XDTODataValue
//
Function UserWS(User, Factory, NameUris)
	
	UserType = Factory.Type(NameUris, "Пользователи");
	UserWS = Factory.Create(UserType);
	
	UserWS.Ref = TrimAll(User.UUID());
	UserWS.Description = TrimAll(AttributeValue(User, "Presentation"));
	
	Return UserWS;
	
EndFunction

// Returns the value of The xdto' Room ' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	Premise - CatalogRef.Warerooms - warehouse,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function WSRoom(Premise, Factory, NameUris)
	
	PremiseType = Factory.Type(NameUris, "Помещения");
	WSRoom = Factory.Create(PremiseType);
	
	WSRoom.Ref = TrimAll(Premise.UUID());
	WSRoom.Description = TrimAll(AttributeValue(Premise, "Presentation"));
	
	Return WSRoom;
	
EndFunction

// Returns the xdto Value Of the 'serialdistribution' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function WSSeriesOfProducts(RowOfGoods, Factory, NameUris)
	
	SeriesStructure = ItemsBatchStructure();
	
	SeriesStructure.Ref = TrimAll(RowOfGoods.Series.UUID());
	SeriesStructure.Description = TrimAll(RowOfGoods.BatchName);
	
	If RowOfGoods.Owner().Columns.Find("BatchNumber") <> Undefined Then
		SeriesStructure.Number = TrimAll(RowOfGoods.BatchNumber);
		SeriesStructure.ValidUntil_ = RowOfGoods.ValidUntil_;
	EndIf;
	
	SeriesType = Factory.Type(NameUris, "СерииНоменклатуры");
	WSSeries = Factory.Create(SeriesType);
	
	FillPropertyValues(WSSeries, SeriesStructure);
	
	Return WSSeries;
	
EndFunction

// Returns the xdto 'Warehouses' Value of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	Warehouse - CatalogRef.Warehouses - warehouse,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function WSWarehouse(Warehouse, Factory, NameUris)
	
	WarehouseType = Factory.Type(NameUris, "Склады");
	WSWarehouse = Factory.Create(WarehouseType);
	
	WSWarehouse.Ref = TrimAll(Warehouse.UUID());
	WSWarehouse.Description = TrimAll(AttributeValue(Warehouse, "Presentation"));
	
	Return WSWarehouse;
	
EndFunction

// Returns the xdto Value Of the 'storage Cells' OF the xdto package WMSMobileClientExchange.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	CatalogRef.StorageBins - The value of XDTO.
//
Function WSStorageCell(RowOfGoods, Factory, NameUris)
	
	CellStructure_ = WarehouseCellStructure();
	
	CellStructure_.Ref = TrimAll(RowOfGoods.Cell.UUID());
	CellStructure_.Code = TrimAll(RowOfGoods.CellCode);
	CellStructure_.Barcode = RowOfGoods.CellBarcode;
	
	CellType = Factory.Type(NameUris, "СкладскиеЯчейки");
	CellWS = Factory.Create(CellType);
	
	FillPropertyValues(CellWS, CellStructure_, , "StorageBinType");
	
	Return CellWS;
	
EndFunction

// Returns the Xdto value of the 'nomenclature Characteristic' of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function CharacteristicsOfWSProducts(RowOfGoods, Factory, NameUris)
	
	StructureCharacteristics = StructureOfCatalog();
	
	StructureCharacteristics.Ref = TrimAll(RowOfGoods.Characteristic.UUID());
	StructureCharacteristics.Description = TrimAll(RowOfGoods.ItemVariantName);
	
	CharacteristicType = Factory.Type(NameUris, "ХарактеристикиНоменклатуры");
	CharacteristicWS = Factory.Create(CharacteristicType);
	
	FillPropertyValues(CharacteristicWS, StructureCharacteristics);
	
	Return CharacteristicWS;
	
EndFunction

// Returns The Xdto Value 'Packaging nomenclature' of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	Factory - XDTOFactory
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	XDTODataValue
//
Function PackagingOfWSProducts(RowOfGoods, Factory, NameUris)
	
	PackingStructure = ProductPackagingStructure();
	
	PackingStructure.Ref = TrimAll(RowOfGoods.Package.UUID());
	PackingStructure.Description = TrimAll(RowOfGoods.PackageName);
	
	If RowOfGoods.Owner().Columns.Find("PackageWeight") <> Undefined Then
		PackingStructure.Weight = RowOfGoods.PackageWeight;
		PackingStructure.VolumeM3 = RowOfGoods.PackageVolume;
	EndIf;
	
	FillPropertyValues(PackingStructure, RowOfGoods);
	
	PackageType = Factory.Type(NameUris, "УпаковкиНоменклатуры");
	WSPackaging = Factory.Create(PackageType);
	
	FillPropertyValues(WSPackaging, PackingStructure);
	
	Return WSPackaging;
	
EndFunction

#EndRegion

#Region DeserializationOfSimpleObjects

// Fills in "unloaded Goods" with item data.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	WSProduct - XDTODataValue - Nomenclature of the xdto package WMSMobileClientExchange-nomenclature data.
//
Procedure FillInProductListForUnloadedGoods(RowOfGoods, WSProduct)
	
	If WSProduct <> Undefined Then
		RowOfGoods.Products = CatalogLink(WSProduct.Ref, "Products");
		RowOfGoods.ItemName = WSProduct.Description;
	EndIf;
	
EndProcedure

// Fills a row in the value table with data of the item type.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	ItemKindWS - XDTODataObject - 
//				Nomenclature viewsdto - package WMSMobileClientExchange - data of the nomenclature type.
//
Procedure FillInWarehouseTaskProductType(RowOfGoods, ItemKindWS)
	
	If ItemKindWS <> Undefined Then
		
		RowOfGoods.ProductKind = CatalogLink(ItemKindWS.Ссылка, "ItemKinds");
		RowOfGoods.ItemsType = ItemsType(ItemKindWS.ТипНоменклатуры);
		RowOfGoods.PrecisionOfBatchShelfLifeIndication = AccuracyOfIndicationOfExpirationDate(
			ItemKindWS.ТочностьУказанияСрокаГодностиСерии);
		
		PropertiesToExclude = "ItemsType, PrecisionOfBatchShelfLifeIndication";
		
		FillPropertyValues(RowOfGoods, ItemKindWS, , PropertiesToExclude);
		
	EndIf;
	
EndProcedure

// Fills a row in the value table with unit data.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	UnitOfMeasurementWS - XDTODataObject - 
//					Units of measurement of the WMSMobileClientExchange XDTO package-unit data,
//	UnitType - String - type of unit of measurement.
//
Procedure FillInUnitOfMeasurementForWarehouseTask(RowOfGoods, UnitOfMeasurementWS, UnitType)
	
	If UnitOfMeasurementWS <> Undefined Then
		
		If UnitType = "UnitOfMeasure" Then
			RowOfGoods.UnitOfMeasure = CatalogLink(UnitOfMeasurementWS.Ссылка, "PackagesAndUnitsOfMeasure");
			RowOfGoods.UnitOfMeasureDescription = UnitOfMeasurementWS.Наименование;
			
			If RowOfGoods.Owner().Columns.Find("MeasuredValueType") <> Undefined Then
				RowOfGoods.MeasuredValueType = MeasuredValueType(UnitOfMeasurementWS.ТипИзмеряемойВеличины);
			EndIf;
		ElsIf UnitType = "UnitOfMeasureForWeight" Then
			RowOfGoods.UnitOfMeasureForWeight = CatalogLink(UnitOfMeasurementWS.Ссылка, "PackagesAndUnitsOfMeasure");
			RowOfGoods.NameOfWeightUnitOfMeasure = UnitOfMeasurementWS.Наименование;
		ElsIf UnitType = "UnitOfMeasureForVolume" Then
			RowOfGoods.UnitOfMeasureForVolume = CatalogLink(UnitOfMeasurementWS.Ссылка, "PackagesAndUnitsOfMeasure");
			RowOfGoods.NameOfVolumeUnitOfMeasure = UnitOfMeasurementWS.Наименование;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills a row in the value table with item assignment data.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	WSAssignment - XDTODataValue - Wmsmobileclientexchange XDTO package assignments - item assignment data.
//
Procedure FillInWarehouseTaskAssignment(RowOfGoods, WSAssignment)
	
	If WSAssignment <> Undefined Then
		RowOfGoods.Purpose = CatalogLink(WSAssignment.Ref, "Assignments");
		RowOfGoods.PurposeDescription = WSAssignment.Description;
	EndIf;
	
EndProcedure

// Fills a row in the value table with item data.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	WSProduct - XDTODataObject - 
//				Nomenclature of the xdto package WMSMobileClientExchange-nomenclature data.
//
Procedure FillInInventoryTaskProductList(RowOfGoods, WSProduct)
	
	If WSProduct <> Undefined Then
		RowOfGoods.Products = CatalogLink(WSProduct.Ссылка, "Products");
		RowOfGoods.ItemName = WSProduct.Наименование;
		RowOfGoods.ProductIDOfItems = WSProduct.Артикул;
		RowOfGoods.ItemsDescription = WSProduct.Описание;
		
		If RowOfGoods.Owner().Columns.Find("ItemsBarcode") <> Undefined Then
			RowOfGoods.ItemsBarcode = WSProduct.Штрихкод;
		EndIf;
		
		FillInWarehouseTaskProductType(RowOfGoods, WSProduct.ВидНоменклатуры);
		FillInUnitOfMeasurementForWarehouseTask(RowOfGoods, WSProduct.ЕдиницаИзмерения, "UnitOfMeasure");
		FillInUnitOfMeasurementForWarehouseTask(RowOfGoods, WSProduct.ЕдиницаИзмеренияВеса,
			"UnitOfMeasureForWeight");
		FillInUnitOfMeasurementForWarehouseTask(RowOfGoods, WSProduct.ЕдиницаИзмеренияОбъема,
			"UnitOfMeasureForVolume");
	EndIf;
	
EndProcedure

// Populates the table's 'Shipremote' data warehouse cells.
//
// Parameters:
//	TableRow - ValueTable,
//	CellWS - XDTODataObject - 
//					Storage cells of the WMSMobileClientExchange XDTO package-cell data.
//
Procedure FillInStorageAreaParameters(TableRow, CellWS)
	
	TableRow.Cell = CatalogLink(CellWS.Ссылка, "StorageBins");
	TableRow.CellCode = CellWS.Код;
	TableRow.CellType = StorageBinType(CellWS.ТипСкладскойЯчейки);
	
EndProcedure

// Fills in the 'pickup and loading Zones' table with warehouse data.
//
// Parameters:
//	TableRow - ValueTable,
//	WSWarehouse - XDTODataValue - Warehouses of the WMSMobileClientExchange XDTO package-warehouse data.
//
Procedure FillInWarehouseParameters(TableRow, WSWarehouse)
	
	TableRow.Warehouse = CatalogLink(WSWarehouse.Ref, "Warehouses");
	TableRow.NameOfTheWarehouse = WSWarehouse.Description;
	
EndProcedure

// Fills a row in the table of values with item characteristics.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	CellWS - XDTODataValue - Storage cells of the WMSMobileClientExchange XDTO package-cell data.
//
Procedure FillInCellParameters(RowOfGoods, CellWS)
	
	If CellWS <> Undefined Then
		RowOfGoods.Cell = CatalogLink(CellWS.Ref, "StorageBins");
		RowOfGoods.CellCode = CellWS.Code;
		RowOfGoods.CellBarcode = CellWS.Barcode;
	EndIf;
	
EndProcedure

// Fills in "unloaded Goods" with the item series data.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	WSSeries - XDTODataValue - Serial nomenclature OF the xdto package WMSMobileClientExchange - data of the nomenclature series.
//
Procedure FillInSeriesOfUnloadedGoods(RowOfGoods, WSSeries)
	
	If WSSeries <> Undefined Then
		RowOfGoods.Series = CatalogLink(WSSeries.Ref, "ItemsBatches");
		RowOfGoods.BatchName = WSSeries.Description;
	EndIf;
	
EndProcedure

// Fills a row in the value table with the item series data.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	WSSeries - XDTODataValue - Serial nomenclature OF the xdto package WMSMobileClientExchange - data of the nomenclature series,
//	UseSeriesParameters - Boolean - The truth is, there are more options series.
//
Procedure FillInSeriesOfWarehouseTasks(RowOfGoods, WSSeries, UseSeriesParameters = False)
	
	If WSSeries = Undefined Then
		Return;
	EndIf;
	
	If WSSeries.Ref <> Undefined Then
		RowOfGoods.Series = CatalogLink(WSSeries.Ref, "ItemsBatches");
		RowOfGoods.BatchName = WSSeries.Description;
	EndIf;
	
	If UseSeriesParameters Then
		RowOfGoods.BatchNumber = WSSeries.Number;
		RowOfGoods.ValidUntil_ = WSSeries.ValidUntil_;
	EndIf;
	
EndProcedure

// Fills in "unloaded Goods" with the item's packaging data.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	WSPackaging - XDTODataValue - Packaging nomenclature OF the xdto package WMSMobileClientExchange-data for packaging the nomenclature.
//
Procedure FillPackagingOfUnloadedGoods(RowOfGoods, WSPackaging)
	
	If WSPackaging <> Undefined Then
		RowOfGoods.Package = CatalogLink(WSPackaging.Ref, "PackagesAndUnitsOfMeasure");
		RowOfGoods.PackageName = WSPackaging.Description;
	EndIf;
	
EndProcedure

// Fills a row in the value table with item packaging data.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	WSPackaging - XDTODataValue - Packaging nomenclature OF the xdto package WMSMobileClientExchange-data for packaging the nomenclature.
//
Procedure FillInWarehouseTaskPackage(RowOfGoods, WSPackaging)
	
	If WSPackaging = Undefined Then
		Return;
	EndIf;
	
	If WSPackaging.Ref <> Undefined Then
		RowOfGoods.Package = CatalogLink(WSPackaging.Ref, "PackagesAndUnitsOfMeasure");
		RowOfGoods.PackageName = WSPackaging.Description;
	EndIf;
	
	RowOfGoods.PackageWeight = WSPackaging.Weight;
	RowOfGoods.PackageVolume = WSPackaging.VolumeM3;
	
	FillPropertyValues(RowOfGoods, WSPackaging);
	
EndProcedure

// Fills a row in the table of values with item characteristics.
//
// Parameters:
//	RowOfGoods - ValueTableRow,
//	CharacteristicWS - XDTODataValue - Characteristics of the nomenclature OF the xdto package WMSMobileClientExchange-these characteristics of the nomenclature.
//
Procedure FillInInventoryTaskDescription(RowOfGoods, CharacteristicWS)
	
	If CharacteristicWS <> Undefined Then
		RowOfGoods.Characteristic = CatalogLink(CharacteristicWS.Ref, "ItemsCharacteristics");
		RowOfGoods.ItemVariantName = CharacteristicWS.Description;
	EndIf;
	
EndProcedure

#EndRegion

#Region SerializationOfTables

// Returns the 'list of Cells' table filled with data from storage cells.
//
// Parameters:
//	ReceivingShippingAreas - ValueTable - table of storage cells.
//
// Returns:
//	XDTODataValue - List of cells of the XDTO package WMSMobileClientExchange.
//
Function XDTOShipmentAcceptanceZones(ReceivingShippingAreas, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	ListOfCellsType = XDTOFactory.Type(NameUris, "СписокЯчеек");
	CellListRowType = XDTOFactory.Type(NameUris, "СписокЯчеекСтрока");
	
	WSShipmentAcceptanceZones = XDTOFactory.Create(ListOfCellsType);
	
	For Each CellListRow In ReceivingShippingAreas Do
		
		CellListRowStructure = RowStructureCellList();
		WSCellListLine = XDTOFactory.Create(CellListRowType);
		
		FillInCellListLine(CellListRowStructure, CellListRow, NameUris);
		FillPropertyValues(WSCellListLine, CellListRowStructure);
		
		ShipmentAcceptanceZonesWSLine = WSShipmentAcceptanceZones["String"]; // XDTOList
		ShipmentAcceptanceZonesWSLine.Add(WSCellListLine);
		
	EndDo;
	
	Return WSShipmentAcceptanceZones;
	
EndFunction

// Returns the' table of unloaded Goods ' with product data.
//
// Parameters:
//	Goods - ValueTable - table of unloaded goods.
//
// Returns:
//	XDTODataValue - Table of downloadable products of the XDTO package WMSMobileClientExchange.
//
Function UnloadedWSGoods(Goods, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	GoodsType = XDTOFactory.Type(NameUris, "ТаблицаНеотгружаемыхТоваров");
	LineProducts_Type = XDTOFactory.Type(NameUris, "ТаблицаНеотгружаемыхТоваровСтрока");
	
	UnloadedGoodsWS = XDTOFactory.Create(GoodsType);
	
	For Each RowOfGoods In Goods Do
		
		WSProductLine = XDTOFactory.Create(LineProducts_Type);
		ProductLineStructure = StructureOfLineUnloadedGoods();
		
		FillInLineOfUnloadedProducts(ProductLineStructure, RowOfGoods, ServiceVersion);
		FillPropertyValues(WSProductLine, ProductLineStructure);
		
		UnloadedGoodsWSString = UnloadedGoodsWS["String"]; // XDTOList
		UnloadedGoodsWSString.Add(WSProductLine);
		
	EndDo;
	
	Return UnloadedGoodsWS;
	
EndFunction

// Returns The 'Scanned Goods Table'.
//
// Parameters:
//	Form - ClientApplicationForm - form of a warehouse employee's mobile workplace,
//	Factory - XDTOFactory, Undefined -
//
// Returns:
//	XDTODataValue - The table of scanned products of the XDTO package WMSMobileClientExchange.
//
Function ScannedWSProducts(Form, Factory)
	
	ServiceVersion = ServiceVersionFromForm(Form);
	NameUris = NamespaceURI(ServiceVersion);
	ScannedGoods = ScannedWarehouseTaskItems(Form);
	
	GoodsType = Factory.Type(NameUris, "ТаблицаОтсканированныхТоваров");
	LineProducts_Type = Factory.Type(NameUris, "ТаблицаОтсканированныхТоваровСтрока");
	
	ScannedWSProducts = Factory.Create(GoodsType);
	
	For Each RowOfGoods In ScannedGoods Do
		
		WSProductLine = Factory.Create(LineProducts_Type);
		ProductLineStructure = RowStructureScannedProducts();
		
		FillInProductLineOfWarehouseTask(ProductLineStructure, RowOfGoods, Factory, ServiceVersion);
		FillPropertyValues(WSProductLine, ProductLineStructure);
		
		ScannedGoodsWSString = ScannedWSProducts["String"]; // XDTOList
		ScannedGoodsWSString.Add(WSProductLine);
		
	EndDo;
	
	Return ScannedWSProducts;
	
EndFunction

// Returns the' task Table ' of the WMSMobileClientExchange XDTO package filled with warehouse task data.
//
// Parameters:
//	TaskTable - ValueTable
//
// Returns:
//	XDTODataValue - The task tables of the XDTO package WMSMobileClientExchange.
//
Function XDTOJobTable(TaskTable, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	TaskTableType = XDTOFactory.Type(NameUris, "ТаблицаЗаданий");
	TaskTableRowType = XDTOFactory.Type(NameUris, "СтрокаТаблицыЗаданий");
	
	ThereIsWeight = (TaskTable.Columns.Find("Weight") <> Undefined);
	ThereIsDeliveryOrder = (TaskTable.Columns.Find("DeliveryProcedure") <> Undefined);
	
	WSJobTable = XDTOFactory.Create(TaskTableType);
	
	For Each TaskTableRow In TaskTable Do
		
		RowStructureOfJobTable = RowStructureOfJobTable(ThereIsWeight, ThereIsDeliveryOrder);
		FillInRowInTaskTable(RowStructureOfJobTable, TaskTableRow, NameUris);
		
		WSJobTableRow = XDTOFactory.Create(TaskTableRowType);
		FillPropertyValues(WSJobTableRow, RowStructureOfJobTable);
		
		WsRowJobTable = WSJobTable["String"]; // XDTOList
		WsRowJobTable.Add(WSJobTableRow);
		
	EndDo;
	
	Return WSJobTable;
	
EndFunction

// Returns the product table of the warehouse task of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	Goods - ValueTable - the products table,
//	JobType - String- the type of warehouse job,
//	TableTypeName - String
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - The table of the XDTO package WMSMobileClientExchange.
//
Function WsWarehouseTaskProducts(Goods, JobType, TableTypeName, Val ServiceVersion)
	
	NameUris =NamespaceURI(ServiceVersion);
	
	GoodsType = XDTOFactory.Type(NameUris, TableTypeName);
	LineProducts_Type = XDTOFactory.Type(NameUris, TableTypeName + "String");
	
	WsWarehouseTaskProducts = XDTOFactory.Create(GoodsType);
	
	For Each RowOfGoods In Goods Do
		
		WSProductLine = XDTOFactory.Create(LineProducts_Type);
		
		If TableTypeName = "SelectionProductPlacementProductsSelection" Then
			ProductLineStructure = RowStructureProductsSelection();
		ElsIf TableTypeName = "SelectionProductPlacementProductsPlacement" Then
			ProductLineStructure = RowStructureAndPlacement();
		ElsIf TableTypeName = "RecalculationOfGoods" Then
			ProductLineStructure = StructureOfGoodsLine();
		ElsIf TableTypeName = "SpendingOrderForGoodsShippedGoods" Then
			ProductLineStructure = StructureOfShippedGoodsLine();
		EndIf;
		
		FillInProductLineOfWarehouseTask(ProductLineStructure, RowOfGoods, XDTOFactory, ServiceVersion);
		FillPropertyValues(WSProductLine, ProductLineStructure);
		
		ProductsOfWarehouseTaskWSString = WsWarehouseTaskProducts["String"];	// XDTOList
		ProductsOfWarehouseTaskWSString.Add(WSProductLine);
		
	EndDo;
	
	Return WsWarehouseTaskProducts;
	
EndFunction


// Returns the 'product Cells' table of the WMSMobileClientExchange XDTO package, filled with product data
// stored in the cell.
//
// Parameters:
//	CellGoods - ValueTable - table of products stored in the cell.
//	ServiceVersion - String
//
// Returns:
//	XDTODataValue - Product Cells of the XDTO package WMSMobileClientExchange.
//
Function XDTOCellProducts(CellGoods, Val ServiceVersion)
	
	NameUris = NamespaceURI(ServiceVersion);
	
	CellGoodsType = XDTOFactory.Type(NameUris, "ТоварыЯчейки");
	RowProductsCellType = XDTOFactory.Type(NameUris, "ТоварыЯчейкиСтрока");
	
	WSCellProducts = XDTOFactory.Create(CellGoodsType);
	
	For Each CellProductLine In CellGoods Do
		
		RowAndCellStructure = RowAndCellStructure();
		FillInRowInCell(RowAndCellStructure, CellProductLine, ServiceVersion);
		
		Row1OfCellWS = XDTOFactory.Create(RowProductsCellType);
		FillPropertyValues(Row1OfCellWS, RowAndCellStructure);
		
		ProductsCellWSRow = WSCellProducts["String"]; // XDTOList
		ProductsCellWSRow.Add(Row1OfCellWS);
		
	EndDo;
	
	Return WSCellProducts;
	
EndFunction

#EndRegion

#Region SerializingTableRows

// Fills in the 'table of unloaded Goods' row with product data.
//
// Parameters:
//	StringStructure - Structure,
//	RowOfGoods - ValueTableRow - product data.
//	ServiceVersion - String
//
Procedure FillInLineOfUnloadedProducts(StringStructure, RowOfGoods, ServiceVersion)
	
	NameUris =NamespaceURI(ServiceVersion);
	
	If ValueIsFilled(RowOfGoods.Characteristic) Then
		StringStructure.Characteristic = CharacteristicsOfWSProducts(RowOfGoods, XDTOFactory, NameUris);
	EndIf;
	
	If ValueIsFilled(RowOfGoods.Purpose) Then
		StringStructure.Purpose = WSAssignment(RowOfGoods, XDTOFactory, NameUris);
	EndIf;
	
	StringStructure.Products = WSProduct(RowOfGoods, XDTOFactory, NameUris);
	StringStructure.Package = PackagingOfWSProducts(RowOfGoods, XDTOFactory, NameUris);
	StringStructure.Series = WSSeriesOfProducts(RowOfGoods,XDTOFactory, NameUris);
	
	PropertiesToExclude = "Products, Characteristic, Purpose, Package, Series";
	
	FillPropertyValues(StringStructure, RowOfGoods, , PropertiesToExclude);
	
EndProcedure

// Fills the 'cell List' line with cell data.
//
// Parameters:
//	CellRowStructure - Structure,
//	CellRow - ValueTableRow - cell data,
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
Procedure FillInCellListLine(CellRowStructure, CellRow, NameUris) Export
	
	CellRowStructure.Cell = WSStorageArea(CellRow.Cell, XDTOFactory, NameUris);
	CellRowStructure.Warehouse = WSWarehouse(CellRow.Warehouse, XDTOFactory, NameUris);
	
EndProcedure

// Fills in the 'task Table' row.
//
// Parameters:
//	StringStructure - Structure,
//	TableRow - ValueTableRow - goods data, contains, among other things:
//		* Ref - CatalogRef
//	NameUris - String - URI of the space name of the WMSMobileClientExchange XDTO package.
//
Procedure FillInRowInTaskTable(StringStructure, TableRow, NameUris)
	
	StringStructure.Ref = TrimAll(TableRow.Ref.UUID());
	StringStructure.Performer = UserWS(TableRow.Performer, XDTOFactory, NameUris);
	
	PropertiesToExclude = "Ref, Performer";
	
	If StringStructure.Property("Weight") Then
		PropertiesToExclude = PropertiesToExclude + ", " + "UnitOfMeasure";
		StringStructure.UnitOfMeasure = UnitOfMeasurementWS(TableRow, "UnitOfMeasure",
			XDTOFactory, NameUris);
	EndIf;
	
	FillPropertyValues(StringStructure, TableRow, , PropertiesToExclude);
	
EndProcedure

// Fills in a row in the product table of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	StringStructure - Structure,
//	RowOfGoods - ValueTableRow - product data.
//	Factory - XDTOFactory
//
Procedure FillInProductLineOfWarehouseTask(StringStructure, RowOfGoods, Factory, Val ServiceVersion) Export
	
	PropertiesToExclude = "";
	NameUris = NamespaceURI(ServiceVersion);
	
	If StringStructure.Property("Action") Then
		StringStructure.Action = ActionWithWSShipmentOrderString(RowOfGoods.Action, NameUris);
		PropertiesToExclude = "Action";
	EndIf;
	
	If StringStructure.Property("Cell") Then
		StringStructure.Cell = WSStorageCell(RowOfGoods, Factory, NameUris);
		PropertiesToExclude = "Cell";
	EndIf;
	
	If Not ValueIsFilled(RowOfGoods.LineNumber) Then
		RowOfGoods.LineNumber = 0;
	EndIf;
	
	StringStructure.Products = WSProduct(RowOfGoods, Factory, NameUris);
	StringStructure.Characteristic = CharacteristicsOfWSProducts(RowOfGoods, Factory, NameUris);
	StringStructure.Purpose = WSAssignment(RowOfGoods, Factory, NameUris);
	StringStructure.Package = PackagingOfWSProducts(RowOfGoods, Factory, NameUris);
	StringStructure.Series = WSSeriesOfProducts(RowOfGoods, Factory, NameUris);
	
	PropertiesToExclude = PropertiesToExclude + ", " + "Products, Characteristic, Purpose, Package, Series";
	
	FillPropertyValues(StringStructure, RowOfGoods, , PropertiesToExclude);
	
EndProcedure

// Fills in the 'product Cells' line of the WMSMobileClientExchange XDTO package with product data.
//
// Parameters:
//	StringStructure - Structure,
//	RowOfGoods - ValueTableRow - product data.
//
Procedure FillInRowInCell(StringStructure, RowOfGoods, Val ServiceVersion) Export
	
	NameUris = NamespaceURI(ServiceVersion);
	
	If ValueIsFilled(RowOfGoods.Characteristic) Then
		StringStructure.Characteristic = CharacteristicsOfWSProducts(RowOfGoods, XDTOFactory, NameUris);
	EndIf;
	
	If ValueIsFilled(RowOfGoods.Package) Then
		StringStructure.Package = PackagingOfWSProducts(RowOfGoods, XDTOFactory, NameUris);
	EndIf;
	
	If ValueIsFilled(RowOfGoods.Series) Then
		StringStructure.Series = WSSeriesOfProducts(RowOfGoods, XDTOFactory, NameUris);
	EndIf;
	
	StringStructure.Products = WSProduct(RowOfGoods, XDTOFactory, NameUris);
	PropertiesToExclude = "Products, Characteristic, Package, Series";
	
	FillPropertyValues(StringStructure, RowOfGoods, , PropertiesToExclude);
	
EndProcedure

#EndRegion

#Region DeserializationOfTables

// Populates the table's 'Shipremote' data warehouse cells.
//
// Parameters:
//	ReceivingShippingAreas - ValueTable,
//	WSShipmentAcceptanceZones - XDTODataValue - List of cells of the XDTO package WMSMobileClientExchange.
//
Procedure FillInShipmentAcceptanceZones(ReceivingShippingAreas, WSShipmentAcceptanceZones)
	
	For Each WSCellLine In WSShipmentAcceptanceZones["String"] Do
		
		NewRow = ReceivingShippingAreas.Add();
		
		FillInStorageAreaParameters(NewRow, WSCellLine.Cell);
		FillInWarehouseParameters(NewRow, WSCellLine.Warehouse);
		
	EndDo;
	
EndProcedure

// Fills In The 'Task Table'.
//
// Parameters:
//	TaskTable - ValueTable,
//	WSJobTable - XDTODataValue - Task table of the WMSMobileClientExchange XDTO package-table of warehouse tasks,
//	DocumentName - String - the name of the object of the warehouse task document.
//
Procedure FillInTaskTable(TaskTable, WSJobTable, DocumentName)
	
	For Each WSJobString In WSJobTable["String"] Do
		
		NewRow = TaskTable.Add();
		
		NewRow.Ref = DocumentLink_(WSJobString.Ref, DocumentName);
		NewRow.Number = WSJobString.Number;
		
		NewRow.Performer = CatalogLink(WSJobString.Performer.Ref, "Users");
		NewRow.AssigneeName = WSJobString.Performer.Description;
		
		If WSJobString.UnitOfMeasure <> Undefined Then
			NewRow.Weight = WSJobString.Weight;
			
			NewRow.UnitOfMeasure = CatalogLink(WSJobString.UnitOfMeasure.Ref,
				"PackagesAndUnitsOfMeasure");
			NewRow.UnitOfMeasureDescription = WSJobString.UnitOfMeasure.Description;
		EndIf;
		
		If WSJobString.DeliveryProcedure <> Undefined Then
			NewRow.DeliveryProcedure = WSJobString.DeliveryProcedure;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the 'product Cells' with the product data stored in the cell.
//
// Parameters:
//	CellGoods - ValueTable,
//	WSCellProducts - XDTODataValue - Product cells OF the xdto package WMSMobileClientExchange - product table of the cell.
//
Procedure FillInAllCells(CellGoods, WSCellProducts)
	
	For Each WSProductLine In WSCellProducts["String"] Do
		
		NewRow = CellGoods.Add();
		
		FillInProductListForUnloadedGoods(NewRow, WSProductLine.Products);
		FillInInventoryTaskDescription(NewRow, WSProductLine.Characteristic);
		FillPackagingOfUnloadedGoods(NewRow, WSProductLine.Package);
		FillInUnitOfMeasurementForWarehouseTask(NewRow, WSProductLine.Products.UnitOfMeasure,
			"UnitOfMeasure");
		FillInSeriesOfUnloadedGoods(NewRow, WSProductLine.Series);
		
		PropertiesToExclude = "Products, Characteristic, Package, Series";
		
		FillPropertyValues(NewRow, WSProductLine, , PropertiesToExclude);
		
	EndDo;
	
EndProcedure

// Returns the 'unloaded Goods' table filled with data for unloaded goods.
//
// Parameters:
//	Goods - ValueTable,
//	WSProducts - XDTODataValue - Table OF the xdto package WMSMobileClientExchange - table of unloaded products.
//
// Returns:
//	ValueTable
//
Function NotShippedGoods(Goods, WSProducts) Export
	
	For Each WSProductLine In WSProducts["String"] Do
		
		NewRow = Goods.Add();
		
		FillInProductListForUnloadedGoods(NewRow, WSProductLine.Products);
		FillInInventoryTaskDescription(NewRow, WSProductLine.Characteristic);
		FillInWarehouseTaskAssignment(NewRow, WSProductLine.Purpose);
		FillPackagingOfUnloadedGoods(NewRow, WSProductLine.Package);
		FillInSeriesOfUnloadedGoods(NewRow, WSProductLine.Series);
		
		PropertiesToExclude = "Products, Characteristic, Purpose, Package, Series";
		
		FillPropertyValues(NewRow, WSProductLine, , PropertiesToExclude);
		
	EndDo;
	
	Return Goods;
	
EndFunction

// Returns the table of items in the warehouse task.
//
// Parameters:
//	Goods - ValueTable,
//	WSProducts - XDTODataValue - Table of the WMSMobileClientExchange XDTO package - a table with data for products in the warehouse task.
//
// Returns:
//	ValueTable
//
Function WarehouseTaskItems(Goods, WSProducts) Export
	
	UseSeriesParameters = (Goods.Columns.Find("BatchNumber") <> Undefined);
	
	For Each WSProductLine In WSProducts["String"] Do
		
		NewRow = Goods.Add();
		
		If Goods.Columns.Find("Action") <> Undefined Then
			PropertiesToExclude = "";
		Else
			PropertiesToExclude = "Cell, ";
			FillInCellParameters(NewRow, WSProductLine.Cell);
		EndIf;
		
		FillInInventoryTaskProductList(NewRow, WSProductLine.Products);
		FillInInventoryTaskDescription(NewRow, WSProductLine.Characteristic);
		FillInWarehouseTaskAssignment(NewRow, WSProductLine.Purpose);
		FillInWarehouseTaskPackage(NewRow, WSProductLine.Package);
		FillInSeriesOfWarehouseTasks(NewRow, WSProductLine.Series, UseSeriesParameters);
		
		PropertiesToExclude = PropertiesToExclude + "Products, Characteristic, Purpose, Package, Series";
		
		FillPropertyValues(NewRow, WSProductLine, , PropertiesToExclude);
		
	EndDo;
	
	Return Goods;
	
EndFunction

#EndRegion

#Region DocumentStructures

// Returns a structure for storing General document details for warehouse tasks.
//
// Returns:
//	Structure:
//	*Ref - String - string representation of the UID
//	*Date - Date
//	*Number - String
//	*Posted - Boolean
//
Function DocumentStructure()
	
	DocumentStructure = New Structure;
	
	DocumentStructure.Insert("Ref", "");
	DocumentStructure.Insert("Date", Date("00010101"));
	DocumentStructure.Insert("Number", "");
	DocumentStructure.Insert("Posted", False);
	
	Return DocumentStructure;
	
EndFunction

// Returns the structure for storing data for the warehouse task document.
//
// Returns:
//	See DocumentStructure
//
Function WarehouseTaskStructure(JobType)
	
	WarehouseTaskStructure = DocumentStructure();
	
	WarehouseTaskStructure.Insert("Warehouse");
	WarehouseTaskStructure.Insert("Premise");
	WarehouseTaskStructure.Insert("Status");
	
	If JobType = "Filter"
		Or JobType = "Recalculate"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		WarehouseTaskStructure.Insert("Performer");
		
	ElsIf JobType = "Receiving" Then
		
		WarehouseTaskStructure.Insert("EmployeeResponsible");
		WarehouseTaskStructure.Insert("ReceivingArea");
		WarehouseTaskStructure.Insert("Goods");
		
	ElsIf JobType = "PickingCheck" Then
		
		WarehouseTaskStructure.Insert("Inspector");
		WarehouseTaskStructure.Insert("DateOfShipment");
		WarehouseTaskStructure.Insert("ShippedGoods");
		
	EndIf;
	
	If JobType = "Filter"
		Or JobType = "Receiving"
		Or JobType = "PickingCheck" Then
	
		WarehouseTaskStructure.Insert("TopLevelMarking");
		WarehouseTaskStructure.Insert("DetailedMarking");
	
	EndIf; 
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		WarehouseTaskStructure.Insert("ShippingZone");
		WarehouseTaskStructure.Insert("ReceivingArea");
		WarehouseTaskStructure.Insert("GoodsFilter");
		WarehouseTaskStructure.Insert("GoodsPlacement");
		
	ElsIf JobType = "Recalculate" Then
		
		WarehouseTaskStructure.Insert("Goods");
		
	EndIf;
	
	Return WarehouseTaskStructure;
	
EndFunction

#EndRegion

#Region TableStructures

// Returns a structure for storing data for a row in the 'table of unloaded goods' table.
//
// Returns:
//	Structure
//
Function StructureOfLineUnloadedGoods()
	
	ProductLineStructure = New Structure;
	
	ProductLineStructure.Insert("Products");
	ProductLineStructure.Insert("Characteristic");
	ProductLineStructure.Insert("Purpose");
	ProductLineStructure.Insert("Package");
	ProductLineStructure.Insert("Series");
	ProductLineStructure.Insert("Count", 0);
	ProductLineStructure.Insert("NumberOfPackages", 0);
	
	Return ProductLineStructure;
	
EndFunction

// Returns the structure for storing data in the row of the table 'Consumableordernatovaryotrugableovars'.
//
// Returns:
//	Structure
//
Function StructureOfShippedGoodsLine()
	
	ProductLineStructure = StructureOfGoodsLineOfSpendingOrder();
	
	ProductLineStructure.Insert("DoNotShip", 0);
	ProductLineStructure.Insert("Count", 0);
	ProductLineStructure.Insert("QuantityNotToShip", 0);
	ProductLineStructure.Insert("QuantityOfGoodsInDocument", 0);
	ProductLineStructure.Insert("NumberOfPackages", 0);
	ProductLineStructure.Insert("NumberOfPackagesDoNotShip", 0);
	ProductLineStructure.Insert("NumberOfPackagesInDocument", 0);
	ProductLineStructure.Insert("NumberOfPackagesInDocumentUnshipped", 0);
	
	Return ProductLineStructure;
	
EndFunction

// Returns a structure for storing data in the 'scanned goods Table' row.
//
// Returns:
//	Structure
//
Function RowStructureScannedProducts()
	
	ProductLineStructure = StructureOfGoodsRowForProductPlacement();
	
	ProductLineStructure.Insert("Count", 0);
	ProductLineStructure.Insert("QuantityOfGoodsInDocument", 0);
	ProductLineStructure.Insert("QuantityScanned", 0);
	ProductLineStructure.Insert("NumberOfPackages", 0);
	ProductLineStructure.Insert("NumberOfPackagesInDocument", 0);
	ProductLineStructure.Insert("NumberOfPackagingsScanned", 0);
	ProductLineStructure.Insert("NumberOfPackagesDoNotShip", 0);
	
	Return ProductLineStructure;
	
EndFunction

// Returns the structure for storing data in the 'list of Cells' string.
//
// Returns:
//	Structure
//
Function RowStructureCellList()
	
	RowStructureCellList = New Structure;
	
	RowStructureCellList.Insert("Cell");
	RowStructureCellList.Insert("Warehouse");
	
	Return RowStructureCellList;
	
EndFunction

// Returns a structure for storing data in the 'task Table' row of the WMSMobileClientExchange XDTO package.
//
// Parameters:
//	ThereIsWeight - Boolean - True, the product weight data is used.,
//	ThereIsDeliveryOrder - Boolean - True, data about delivery methods is used.
//
// Returns:
//	Structure
//
Function RowStructureOfJobTable(ThereIsWeight, ThereIsDeliveryOrder)
	
	RowStructureOfJobTable = New Structure;
	
	RowStructureOfJobTable.Insert("Ref");
	RowStructureOfJobTable.Insert("Number");
	RowStructureOfJobTable.Insert("Performer");
	
	If ThereIsDeliveryOrder Then
		RowStructureOfJobTable.Insert("DeliveryProcedure");
	EndIf;
	
	If ThereIsWeight Then
		RowStructureOfJobTable.Insert("Weight");
		RowStructureOfJobTable.Insert("UnitOfMeasure");
	EndIf;
	
	Return RowStructureOfJobTable;
	
EndFunction

// Returns the structure for storing data in the 'Products' table row of the WMSMobileClientExchange XDTO package.
//
// Returns:
//	Structure
//
Function StructureOfGoodsLine()
	
	ProductLineStructure = StructureOfGoodsRowForProductPlacement();
	
	ProductLineStructure.Insert("SurplusDamage", False);
	ProductLineStructure.Insert("Count", 0);
	ProductLineStructure.Insert("CountReal", 0);
	ProductLineStructure.Insert("NumberOfPackages", 0);
	ProductLineStructure.Insert("QuantityOfGoodsInDocument", 0);
	ProductLineStructure.Insert("NumberOfPackagesReal", 0);
	ProductLineStructure.Insert("NumberOfPackagesInDocument", 0);
	
	Return ProductLineStructure;
	
EndFunction

// Returns a structure for storing data for a row of tables in the document 'selection of product Placements'.
//
// Returns:
//	Structure
//
Function StructureOfGoodsRowForProductPlacement()
	
	ProductLineStructure = New Structure;
	
	ProductLineStructure.Insert("LineNumber", 0);
	ProductLineStructure.Insert("Cell");
	ProductLineStructure.Insert("Products");
	ProductLineStructure.Insert("Characteristic");
	ProductLineStructure.Insert("Purpose");
	ProductLineStructure.Insert("Package");
	ProductLineStructure.Insert("Series");
	ProductLineStructure.Insert("BatchesIndicationStatus");
	
	Return ProductLineStructure;
	
EndFunction

// Returns a structure for storing data for a row in the table 'Selectdistributiontovarovtovaryselection'.
//
// Returns:
//	Structure
//
Function RowStructureProductsSelection()
	
	ProductLineStructure = StructureOfGoodsRowForProductPlacement();
	
	ProductLineStructure.Insert("Count", 0);
	ProductLineStructure.Insert("CountPicked", 0);
	ProductLineStructure.Insert("NumberOfPackages", 0);
	ProductLineStructure.Insert("NumberOfPackagesPicked", 0);
	ProductLineStructure.Insert("NumberOfPackagesInDocument", 0);
	
	Return ProductLineStructure;
	
EndFunction

// Returns a structure for storing data for a row in the table 'Selectdistributiontovarovdistribution'.
//
// Returns:
//	Structure
//
Function RowStructureAndPlacement()
	
	ProductLineStructure = StructureOfGoodsRowForProductPlacement();
	
	ProductLineStructure.Insert("Count", 0);
	ProductLineStructure.Insert("CountPlaced", 0);
	ProductLineStructure.Insert("NumberOfPackages", 0);
	ProductLineStructure.Insert("NumberOfPackagesPlaced", 0);
	ProductLineStructure.Insert("NumberOfPackagesInDocument", 0);
	
	Return ProductLineStructure;
	
EndFunction

// Returns the structure for storing data in the table row of the document 'consumable items'.
//
// Returns:
//	Structure
//
Function StructureOfGoodsLineOfSpendingOrder()
	
	ProductLineStructure = New Structure;
	
	ProductLineStructure.Insert("LineNumber", 0);
	ProductLineStructure.Insert("Products");
	ProductLineStructure.Insert("Characteristic");
	ProductLineStructure.Insert("Purpose");
	ProductLineStructure.Insert("Package");
	ProductLineStructure.Insert("Series");
	ProductLineStructure.Insert("BatchesIndicationStatus");
	
	Return ProductLineStructure;
	
EndFunction

// Returns the structure for storing data in the 'product Cells' string.
//
// Returns:
//	Structure
//
Function RowAndCellStructure()
	
	RowAndCellStructure = New Structure;
	
	RowAndCellStructure.Insert("Products");
	RowAndCellStructure.Insert("Characteristic");
	RowAndCellStructure.Insert("Package");
	RowAndCellStructure.Insert("Series");
	RowAndCellStructure.Insert("Count", 0);
	
	Return RowAndCellStructure;
	
EndFunction

#EndRegion

#Region StructuresOfSimpleTypes

// Returns the structure for storing data in the object's reference list.
//
// Returns:
//	Structure
//
Function StructureOfCatalog()
	
	StructureOfCatalog = New Structure;
	
	StructureOfCatalog.Insert("Ref");
	StructureOfCatalog.Insert("Description", "");
	
	Return StructureOfCatalog;
	
EndFunction

// Returns a structure for storing data of the item type.
//
// Returns:
//	Structure
//
Function StructureOfProductType()
	
	StructureOfProductType = StructureOfCatalog();
	
	StructureOfProductType.Insert("SpecifyNumberWhenRegisteringBatch", False);
	StructureOfProductType.Insert("UseShelfLifeOnBatchRegistration", False);
	StructureOfProductType.Insert("ItemsType");
	StructureOfProductType.Insert("PrecisionOfBatchShelfLifeIndication",
		Enums.AccuracyOfShelfLifeIndication.EmptyRef());
	
	Return StructureOfProductType;
	
EndFunction

// Returns a structure for storing unit data.
//
// Returns:
//	Structure
//
Function UnitStructure()
	
	UnitStructure = StructureOfCatalog();
	UnitStructure.Insert("MeasuredValueType");
	
	Return UnitStructure;
	
EndFunction

// Returns the structure for storing item data.
//
// Returns:
//	Structure:
//	*SKU - String
//	*ProductKind - CatalogRef.ItemKinds
//	*UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//	*UnitOfMeasureForWeight - CatalogRef.PackagesAndUnitsOfMeasure
//	*UnitOfMeasureForVolume - CatalogRef.PackagesAndUnitsOfMeasure
//	*LongDesc - String
//	*Barcode - String
//
Function ProductStructure_()
	
	ProductStructure_ = StructureOfCatalog();
	
	ProductStructure_.Insert("SKU", "");
	ProductStructure_.Insert("ProductKind");
	ProductStructure_.Insert("UnitOfMeasure");
	ProductStructure_.Insert("UnitOfMeasureForWeight");
	ProductStructure_.Insert("UnitOfMeasureForVolume");
	ProductStructure_.Insert("LongDesc", "");
	ProductStructure_.Insert("Barcode", "");
	
	Return ProductStructure_;
	
EndFunction

// Returns the structure for storing the item series data.
//
// Returns:
//	Structure
//
Function ItemsBatchStructure()
	
	ItemsBatchStructure = StructureOfCatalog();
	
	ItemsBatchStructure.Insert("Number", "");
	ItemsBatchStructure.Insert("ValidUntil_", Date("00010101"));
	
	Return ItemsBatchStructure;
	
EndFunction

// Returns the structure for storing data in the xdto package cell.
//
// Returns:
//	Structure
//
Function WarehouseCellStructure()
	
	WarehouseCellStructure = New Structure;
	
	WarehouseCellStructure.Insert("Ref");
	WarehouseCellStructure.Insert("Code", "");
	WarehouseCellStructure.Insert("StorageBinType");
	WarehouseCellStructure.Insert("Barcode", "");
	
	Return WarehouseCellStructure;
	
EndFunction

// Returns a structure for storing data of the package item.
//
// Returns:
//	Structure
//
Function ProductPackagingStructure()
	
	ProductPackagingStructure = StructureOfCatalog();
	
	ProductPackagingStructure.Insert("Weight", 0);
	ProductPackagingStructure.Insert("ZoomRatio", 1);
	ProductPackagingStructure.Insert("FactorOfWeightUnitOfMeasure", 0);
	ProductPackagingStructure.Insert("FactorOfVolumeUnitOfMeasure", 0);
	ProductPackagingStructure.Insert("VolumeM3", 0);
	
	Return ProductPackagingStructure;
	
EndFunction

#EndRegion

#Region ConstructorsOfValueTables

// Returns the 'unloaded Goods' table.
//
// Returns:
//	ValueTable
//
Function TableUnloadedGoods()
	
	TypeProducts = New TypeDescription("CatalogRef.Products");
	TypeCharacteristic = New TypeDescription("CatalogRef.ItemsCharacteristics");
	TypePackaging = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	TypePurpose = New TypeDescription("CatalogRef.Assignments");
	TypeSeries = New TypeDescription("CatalogRef.ItemsBatches");
	
	TypeStringName = New TypeDescription("String", , New StringQualifiers(100));
	TypeQuantity = New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	NotShippedGoods = New ValueTable;
	
	NotShippedGoods.Columns.Add("Products", TypeProducts);
	NotShippedGoods.Columns.Add("ItemName", TypeStringName);
	NotShippedGoods.Columns.Add("Characteristic", TypeCharacteristic);
	NotShippedGoods.Columns.Add("ItemVariantName", TypeStringName);
	NotShippedGoods.Columns.Add("Purpose", TypePurpose);
	NotShippedGoods.Columns.Add("PurposeDescription", TypeStringName);
	NotShippedGoods.Columns.Add("Series", TypeSeries);
	NotShippedGoods.Columns.Add("BatchName", TypeStringName);
	NotShippedGoods.Columns.Add("Package", TypePackaging);
	NotShippedGoods.Columns.Add("PackageName", TypeStringName);
	NotShippedGoods.Columns.Add("Count", TypeQuantity);
	NotShippedGoods.Columns.Add("NumberOfPackages", TypeQuantity);
	
	Return NotShippedGoods;
	
EndFunction

// Returns the "scanned Goods" table.
//
// Returns:
//	ValueTable
//
Function TableScannedProducts()
	
	CellType_1 = New TypeDescription("CatalogRef.StorageBins");
	TypeProducts = New TypeDescription("CatalogRef.Products");
	TypeTypeOfProduct = New TypeDescription("CatalogRef.ItemKinds");
	TypeTypeOfProduct_ = New TypeDescription("EnumRef.ItemsTypes");
	TypeOfAccuracyOfIndicationOfExpirationDate = New TypeDescription("EnumRef.AccuracyOfShelfLifeIndication");
	TypeTypeOfMeasuredValue = New TypeDescription("EnumRef.TypesOfMeasuredValues");
	TypeUnitOfMeasurement = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	TypeCharacteristic = New TypeDescription("CatalogRef.ItemsCharacteristics");
	TypePackaging = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	TypePurpose = New TypeDescription("CatalogRef.Assignments");
	TypeSeries = New TypeDescription("CatalogRef.ItemsBatches");
	
	BooleanType = New TypeDescription("Boolean");
	TypeArticleString = New TypeDescription("String", , New StringQualifiers(50));
	TypeDescriptionString = New TypeDescription("String", , New StringQualifiers(1024));
	TypeStringSeriesNumber = New TypeDescription("String", , New StringQualifiers(200));
	TypeStringName = New TypeDescription("String", , New StringQualifiers(100));
	DateType = New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime));
	TypeQuantity = New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	TypeStatusOfSeriesIndication = New TypeDescription("Number", New NumberQualifiers(2, 0, AllowedSign.Nonnegative));
	
	ScannedGoods = New ValueTable;
	
	ScannedGoods.Columns.Add("LineNumber", CellType_1);
	ScannedGoods.Columns.Add("Cell", CellType_1);
	ScannedGoods.Columns.Add("CellCode", CellType_1);
	ScannedGoods.Columns.Add("CellBarcode", TypeArticleString);
	ScannedGoods.Columns.Add("Products", TypeProducts);
	ScannedGoods.Columns.Add("ItemName", TypeStringName);
	ScannedGoods.Columns.Add("ProductIDOfItems", TypeArticleString);
	ScannedGoods.Columns.Add("ItemsDescription", TypeDescriptionString);
	ScannedGoods.Columns.Add("ProductKind", TypeTypeOfProduct);
	ScannedGoods.Columns.Add("ItemsType", TypeTypeOfProduct_);
	ScannedGoods.Columns.Add("SpecifyNumberWhenRegisteringBatch", BooleanType);
	ScannedGoods.Columns.Add("UseShelfLifeOnBatchRegistration", BooleanType);
	ScannedGoods.Columns.Add("PrecisionOfBatchShelfLifeIndication", TypeOfAccuracyOfIndicationOfExpirationDate);
	ScannedGoods.Columns.Add("Characteristic", TypeCharacteristic);
	ScannedGoods.Columns.Add("ItemVariantName", TypeStringName);
	ScannedGoods.Columns.Add("Purpose", TypePurpose);
	ScannedGoods.Columns.Add("PurposeDescription", TypeStringName);
	ScannedGoods.Columns.Add("Series", TypeSeries);
	ScannedGoods.Columns.Add("BatchName", TypeStringName);
	ScannedGoods.Columns.Add("BatchNumber", TypeStringSeriesNumber);
	ScannedGoods.Columns.Add("ValidUntil_", DateType);
	ScannedGoods.Columns.Add("BatchesIndicationStatus", TypeStatusOfSeriesIndication);
	ScannedGoods.Columns.Add("UnitOfMeasure", TypeUnitOfMeasurement);
	ScannedGoods.Columns.Add("UnitOfMeasureDescription", TypeStringName);
	ScannedGoods.Columns.Add("UnitOfMeasureForWeight", TypeUnitOfMeasurement);
	ScannedGoods.Columns.Add("NameOfWeightUnitOfMeasure", TypeStringName);
	ScannedGoods.Columns.Add("UnitOfMeasureForVolume", TypeUnitOfMeasurement);
	ScannedGoods.Columns.Add("NameOfVolumeUnitOfMeasure", TypeStringName);
	ScannedGoods.Columns.Add("MeasuredValueType", TypeTypeOfMeasuredValue);
	ScannedGoods.Columns.Add("Package", TypePackaging);
	ScannedGoods.Columns.Add("PackageName", TypeStringName);
	ScannedGoods.Columns.Add("ZoomRatio", TypeQuantity);
	ScannedGoods.Columns.Add("FactorOfWeightUnitOfMeasure", TypeQuantity);
	ScannedGoods.Columns.Add("FactorOfVolumeUnitOfMeasure", TypeQuantity);
	ScannedGoods.Columns.Add("PackageWeight", TypeQuantity);
	ScannedGoods.Columns.Add("PackageVolume", TypeQuantity);
	
	ScannedGoods.Columns.Add("Count", TypeQuantity);
	ScannedGoods.Columns.Add("QuantityOfGoodsInDocument", TypeQuantity);
	ScannedGoods.Columns.Add("QuantityScanned", TypeQuantity);
	ScannedGoods.Columns.Add("NumberOfPackages", TypeQuantity);
	ScannedGoods.Columns.Add("NumberOfPackagesInDocument", TypeQuantity);
	ScannedGoods.Columns.Add("NumberOfPackagingsScanned", TypeQuantity);
	ScannedGoods.Columns.Add("NumberOfPackagesDoNotShip", TypeQuantity);
	
	Return ScannedGoods;
	
EndFunction

// Returns the "product Cells" table.
//
// Returns:
//	ValueTable
//
Function CellProductsTable()
	
	TypeProducts = New TypeDescription("CatalogRef.Products");
	TypeUnitOfMeasurement = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	TypeCharacteristic = New TypeDescription("CatalogRef.ItemsCharacteristics");
	TypePackaging = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	TypeSeries = New TypeDescription("CatalogRef.ItemsBatches");
	
	TypeStringName = New TypeDescription("String", , New StringQualifiers(100));
	TypeQuantity = New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	CellGoods = New ValueTable;
	
	CellGoods.Columns.Add("Products", TypeProducts);
	CellGoods.Columns.Add("ItemName", TypeStringName);
	CellGoods.Columns.Add("Characteristic", TypeCharacteristic);
	CellGoods.Columns.Add("ItemVariantName", TypeStringName);
	CellGoods.Columns.Add("Series", TypeSeries);
	CellGoods.Columns.Add("BatchName", TypeStringName);
	CellGoods.Columns.Add("Package", TypePackaging);
	CellGoods.Columns.Add("PackageName", TypeStringName);
	CellGoods.Columns.Add("UnitOfMeasure", TypeUnitOfMeasurement);
	CellGoods.Columns.Add("UnitOfMeasureDescription", TypeStringName);
	CellGoods.Columns.Add("Count", TypeQuantity);
	
	Return CellGoods;
	
EndFunction

#EndRegion

#Region ProcessingScannedGoodsWarehouseTasks

// Returns a table of scanned items in the "Select" and "Move" warehouse operations, 
// after selecting items from the cells.
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//
// Returns:
//	ValueTable - scanned goods of the warehouse task.
//
Function ScannedProducts(Form)
	
	GoodsForScanning = Form.GoodsForScanning;
	ScannedGoods = GoodsForScanning.Unload();
	Filter = New Structure("Cell, Products, Characteristic, Purpose, Package");
	
	VTScannedProducts = Form.ScannedGoods.Unload();
	VTScannedProducts.GroupBy("Cell, Products, Characteristic, Purpose, Package, Series, BatchNumber,
			|ValidUntil_, ZoomRatio, BatchesIndicationStatus", "NumberOfPackagingsScanned");
	
	For Each RowOfGoods In GoodsForScanning Do
		
		If SeriesAreIndicatedUponSelection(RowOfGoods.BatchesIndicationStatus) Then
			
			FillPropertyValues(Filter, RowOfGoods);
			
			TotalScannedPackages = 0;
			FoundRows = ScannedGoods.FindRows(Filter);
			FoundRowsBySeries = VTScannedProducts.FindRows(Filter);
			
			String = FoundRows[0];
			IndexOfNewRow = ScannedGoods.IndexOf(String);
			
			If FoundRowsBySeries.Count() > 0 Then
				FirstRow = FoundRowsBySeries[0];
			EndIf;
			
			For Each ProductLineWithSeries In FoundRowsBySeries Do
				
				IndexOfNewRow = IndexOfNewRow + 1;
				
				If ProductLineWithSeries = FirstRow Then
					
					QuantityScanned = FirstRow.NumberOfPackagingsScanned;
					
					If FoundRowsBySeries.Count() > 0 Then
						QuantityScanned = 0;
						
						For Each ProductLineBySeries In FoundRowsBySeries Do
							QuantityScanned = QuantityScanned + ProductLineBySeries.NumberOfPackagingsScanned;
						EndDo;
					EndIf;
					
					QuantityScanned = QuantityScanned - FirstRow.NumberOfPackagingsScanned;
					NumberOfPackagingsScanned = RowOfGoods.NumberOfPackagingsScanned - QuantityScanned;
					QuantityScanned = NumberOfPackagingsScanned * RowOfGoods.ZoomRatio;
					
				Else
					NumberOfPackagingsScanned = ProductLineWithSeries.NumberOfPackagingsScanned;
					QuantityScanned = NumberOfPackagingsScanned * ProductLineWithSeries.ZoomRatio;
				EndIf;
				
				NewRow = ScannedGoods.Insert(IndexOfNewRow);
				FillPropertyValues(NewRow, String);
				
				NewRow.BatchNumber = ProductLineWithSeries.BatchNumber;
				NewRow.ValidUntil_ = ProductLineWithSeries.ValidUntil_;
				
				NewRow.NumberOfPackages = NumberOfPackagingsScanned;
				NewRow.NumberOfPackagingsScanned = NumberOfPackagingsScanned;
				NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
				
				TotalScannedPackages = TotalScannedPackages + NumberOfPackagingsScanned;
				
			EndDo;
			
			ItRemainsToScanPackages = RowOfGoods.NumberOfPackages - TotalScannedPackages;
			
			If ItRemainsToScanPackages <= 0 Then
				ScannedGoods.Delete(String);
			Else
				String.NumberOfPackagesInDocument = ItRemainsToScanPackages;
				String.NumberOfPackages = ItRemainsToScanPackages;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	DeleteBlankRowsScannedProducts(ScannedGoods);
	
	Return ScannedGoods;
	
EndFunction

// Returns a table of scanned items in the "Recalculation" warehouse operation.
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//
// Returns:
//	ValueTable - scanned goods of the warehouse task.
//
Function ScannedGoodsRecalculation(Form)
	
	VTScannedProducts = Form.ScannedGoods.Unload();
	ScannedGoods = Form.GoodsForScanning.Unload();
	ScannedGoods.Clear();
	
	For Each RowOfGoods In VTScannedProducts Do
		NewRow = ScannedGoods.Add();
		FillPropertyValues(NewRow, RowOfGoods);
	EndDo;
	
	Return ScannedGoods;
	
EndFunction

// Returns a table of scanned items in the warehouse operation "selection Check".
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//
// Returns:
//	ValueTable - scanned goods of the warehouse task.
//
Function ScannedGoodsSelectionChecks(Form)
	
	VTScannedProducts = Form.ScannedGoods.Unload();
	ScannedGoods = Form.GoodsForScanning.Unload();
	ScannedGoods.Clear();
	
	For Each RowOfGoods In VTScannedProducts Do
		NewRow = ScannedGoods.Add();
		FillPropertyValues(NewRow, RowOfGoods);
	EndDo;
	
	For Each RowOfGoods In Form.GoodsForScanning Do
		
		If ThisIsTara(RowOfGoods)
			And RowOfGoods.NumberOfPackagingsScanned > 0 Then
			
			NewRow = ScannedGoods.Add();
			FillPropertyValues(NewRow, RowOfGoods);
			
		EndIf;
		
	EndDo;
	
	Return ScannedGoods;
	
EndFunction

// Returns a table of scanned items in the new placement warehouse operation.
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//
// Returns:
//	ValueTable - scanned goods of the warehouse task.
//
Function ScannedProductsOfNewPlacement(Form)
	
	VTScannedProducts = Form.ScannedGoods.Unload();
	ScannedPackage = Form.FormAttributeToValue("ScannedPackage");
	
	ScannedGoods = Form.GoodsForScanning.Unload();
	ScannedGoods.Clear();
	
	For Each RowOfGoods In VTScannedProducts Do
		NewRow = ScannedGoods.Add();
		FillPropertyValues(NewRow, RowOfGoods);
	EndDo;
	
	For Each RowOfProduct In ScannedPackage.Rows Do
		
		For Each TareString In RowOfProduct.Rows Do
			
			If TareString.NumberOfPackagingsScanned = 0 Then
				Continue;
			EndIf;
			
			NewRow = ScannedGoods.Add();
			FillPropertyValues(NewRow, TareString);
			
			NewRow.NumberOfPackages = TareString.NumberOfPackagingsScanned;
			
		EndDo;
		
	EndDo;
	
	Return ScannedGoods;
	
EndFunction

// Returns a table of scanned items in the warehouse task document.
//
// Parameters:
//	Form - ClientApplicationForm - form of a mobile workplace for a warehouse employee.
//
// Returns:
//	ValueTable - scanned goods of the warehouse task.
//
Function ScannedWarehouseTaskItems(Form)
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	
	If JobType = "Filter" Then
		ScannedGoods = ScannedProducts(Form);
	ElsIf JobType = "Location" Then
		
		If ThisIsSetOfGoods Then
			ScannedGoods = ScannedProductsOfNewPlacement(Form);
		Else
			ScannedGoods = Form.GoodsForScanning.Unload();
		EndIf;
		
	ElsIf JobType = "Recalculate" Then
		ScannedGoods = ScannedGoodsRecalculation(Form);
	ElsIf JobType = "Move" Then
		
		If Not ModeSettings.SelectionScanned Then
			ScannedGoods = ScannedProducts(Form);
		Else
			ScannedGoods = Form.GoodsForScanning.Unload();
		EndIf;
		
	ElsIf JobType = "PickingCheck" Then
		ScannedGoods = ScannedGoodsSelectionChecks(Form);
	EndIf;
	
	Return ScannedGoods;
	
EndFunction

#EndRegion

#Region Other

// The function returns the URI of the name of the corresponding XDTO package WMSMobileClientExchange*.
//
Function NamespaceURI(ServiceVersion)
	
	ServiceName = "WMSMobileClientExchange";
	
	ServiceName = FullNameOfService(ServiceName,ServiceVersion);
	
	Service = Metadata.WebServices.Find(ServiceName);
	
	If Service = Undefined Then
		ExceptionPattern = NStr("vi = 'Không tìm thấy Web-service ""%1""';
								|ru = 'Не найден Web-сервис ""%1""';
								|en = '""%1"" web service is not found'; fa = '""%1"" web service is not found';
								|it = 'Servizio web ""%1"" non trovato';
								|pl = 'Nie znaleziono serwisu webowego ""%1""';
								|tr = 'Web servisi ""%1"" bulunamadı'");
		Raise StrTemplate(ExceptionPattern,ServiceName);
	Else
		Return Service.Namespace;
	EndIf; 
	
EndFunction

// Creates a web service proxy. If an error occurs, an exception is thrown.
//
// Parameters:
//	UserName - String - the user name specified in the authorization,
//	Password - String - the password specified during login,
//	WSDLLocation - String - location of the WSDL file from which the web service definition will be obtained.
//	ServiceVersion - String,Undefined - used to get the suffix of the service name, schema, and namespace
//		. The Undefined value is converted to the default suffix.
//
// Returns:
//	WSProxy - Proxy of the web service.
//
Function ProxyWebService(UserName, Password, Val WSDLLocation, Val ServiceVersion = "") Export
	
	If ServiceVersion = Undefined Then
		ServiceVersion = MainVersionOfService();
	EndIf; 
	
	If IsBlankString(WSDLLocation) Then
		Raise NStr("vi = 'Lỗi kết nối đến Web-service.
			|
			|Trong tham số kết nối chưa chỉ ra URL cơ sở thông tin';
			|ru = 'Ошибка подключения к веб-сервису.
			|
			|В параметрах соединения не указан URL информационной базы';
			|en = 'An error occurred while connecting to the web service.
			|
			|Infobase URL is not specified in the connection parameters'; fa = 'An error occurred while connecting to the web service.
			|
			|Infobase URL is not specified in the connection parameters';
			|it = 'Errore di connessione al servizio web. 
			|
			| Nei parametri di connessione non è stato indicato l''URL del database';
			|pl = 'Błąd połączenia z usługą internetową.
			|
			|W ustawieniach połączenia nie został podany adres URL bazy informacyjnej';
			|tr = 'Web servisine bağlanırken hata.
			|
			|Infobase URL''si bağlantı parametrelerinde belirtilmedi'");
	EndIf;
	
	If ValueIsFilled(WSDLLocation)
		And (Right(WSDLLocation, 1) <> "/")
		And (Right(WSDLLocation, 1) <> "\") Then
		
		WSDLLocation = WSDLLocation + "/";
		
	EndIf;
	
	ServiceName = "WMSMobileClientExchange";
	ServiceName = FullNameOfService(ServiceName,ServiceVersion);
	WSDLLocation = StrTemplate("%1ws/%2.1cws?wsdl", WSDLLocation, ServiceName);
	
	If IsBlankString(UserName) Then
		Raise NStr("vi = 'Lỗi kết nối đến Web-service.
			|
			|Trong tham số kết nối chưa chỉ ra người sử dụng';
			|ru = 'Ошибка подключения к веб-сервису.
			|
			|В параметрах соединения не указан пользователь';
			|en = 'An error occurred while connecting to the web service.
			|
			|User is not specified in the connection parameters'; fa = 'An error occurred while connecting to the web service.
			|
			|User is not specified in the connection parameters';
			|it = 'Errore di connessione al servizio web. 
			|
			| Nei parametri di connessione non è stato indicato l''utente';
			|pl = 'Błąd połączenia z usługą internetową.
			|
			|W ustawieniach połączenia nie został podany użytkownik';
			|tr = 'Web servisine bağlanırken hata.
			|
			|Bağlantı parametrelerinde kullanıcı belirtilmedi'");
	EndIf;
	
	Try
		NameUris = NamespaceURI(ServiceVersion);
		URIStructure = CommonClientServer.URIStructure(WSDLLocation);
		
		SecureConnectionIsUsed = URIStructure.Schema = "https";
		If SecureConnectionIsUsed Then
			
			SecureConnection = CommonClientServer.NewSecureConnection();
			InternetProxy = GetFilesFromInternet.GetProxy("https");
			
		Else
			
			SecureConnection = Undefined;
			InternetProxy = GetFilesFromInternet.GetProxy("http");
			
		EndIf;
		
		Definitions = New WSDefinitions(WSDLLocation,
			UserName,
			Password,
			InternetProxy,
			60,
			SecureConnection);
		
		Proxy = New WSProxy(
			Definitions,
			NameUris,
			ServiceName,
			StrTemplate("%1Soap", ServiceName),
			InternetProxy,
			60,
			SecureConnection);
		
	Except
		TextMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		DefaultLanguageCode = Common.DefaultLanguageCode();
		
		WriteLogEvent(NStr("vi = 'Kết nối đến cơ sở thông tin';
							|ru = 'Подключение к информационной базе';
							|en = 'Connect to infobase'; fa = 'Connect to infobase';
							|it = 'Connessione al database';
							|pl = 'Podłączenie do bazy informacyjnej';
							|tr = 'Infobase''e bağlanma'", DefaultLanguageCode),
			EventLogLevel.Error, , ,
			TextMessage);
		
		Raise NStr("vi = 'Lỗi kết nối đến Web-service.
			|
			|Có thể là chưa đăng nhập, đã chỉ ra sai địa chỉ Web-service
			|hoặc cơ sở thông tin chưa được đăng tải trên Web-server.
			|
			|Chi tiết xem trong nhật ký sự kiện.';
			|ru = 'Ошибка подключения к веб-сервису.
			|
			|Возможно не прошла авторизация, указан неверный адрес веб-сервиса 
			|или информационная база не опубликована на веб-сервере.
			|
			|Подробности в журнале регистрации.';
			|en = 'An error occurred when connecting to web service.
			|
			|Authorization might fail, the web service address is incorrect,
			|or infobase is not published on web server.
			|
			|See the event log for details.'; fa = 'An error occurred when connecting to web service.
			|
			|Authorization might fail, the web service address is incorrect,
			|or infobase is not published on web server.
			|
			|See the event log for details.';
			|it = 'Errore di connessione al servizio web. 
			|
			| L''autorizzazione potrebbe non essere riuscita, l''indirizzo del servizio web
			|non è corretto o il database non è stato pubblicato sul server web.
			|
			|Dettagli nel registro di registrazione.';
			|pl = 'Błąd połączenia z usługą internetową.
			|
			|Być może nie przeszła autoryzacja, podano nieprawidłowy adres usługi internetowej
			|lub baza informacyjna nie została opublikowana na serwerze internetowym.
			|
			|Szczegóły w dzienniku rejestracji.';
			|tr = 'Web servisine bağlanırken hata .
			|
			|Kimlik doğrulama başarısız olabilir, geçersiz bir web servisi adresi belirtilmiş 
			|veya infobase web sunucusunda yayınlanmamış olabilir.
			|
			|Ayrıntılar için kayıt defterine bak.'");
	EndTry;
	
	Proxy.User = UserName;
	Proxy.Password = Password;
	
	Return Proxy;
	
EndFunction

// Adds data to the 'unloaded Goods' table.
//
// Parameters:
//	NotShippedGoods - ValueTable - table of unloaded goods.
//
Procedure AddDataToUnloadedProducts(NotShippedGoods)
	
	Query = New Query;
	Manager = New TempTablesManager;
	
	Query.TempTablesManager = Manager;
	Query.SetParameter("Goods", NotShippedGoods);
	
	QueryText =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Package AS Package,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages
	|INTO NotShippedGoods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NotShippedGoods.LineNumber AS LineNumber,
	|	NotShippedGoods.Products,
	|	ISNULL(TSProducts.Ref.Presentation, """") AS ItemName,
	|	ISNULL(TSProducts.SKU, """") AS ProductIDOfItems,
	|	ISNULL(TSProducts.LongDesc, """") AS ItemsDescription,
	|	ISNULL(TSProducts.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
	|	ISNULL(TSProducts.ProductKind.Presentation, """") AS NameOfTypeOfProduct,
	|	ISNULL(TSProducts.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
	|	NotShippedGoods.Characteristic AS Characteristic,
	|	ISNULL(TSCharacteristics.Ref.Presentation, """") AS ItemVariantName,
	|	NotShippedGoods.Purpose AS Purpose,
	|	ISNULL(DestinationTS_.Ref.Presentation, """") AS PurposeDescription,
	|	NotShippedGoods.Package AS Package,
	|	ISNULL(TSPackaging.Ref.Presentation, """") AS PackageName,
	|	NotShippedGoods.Series AS Series,
	|	ISNULL(TSSetOfSeries.Ref.Presentation, """") AS BatchName,
	|	ISNULL(&ZoomRatio1, 1) AS ZoomRatio,
	|	ISNULL(&ZoomRatio2, 1) AS FactorOfWeightUnitOfMeasure,
	|	ISNULL(&ZoomRatio3, 1) AS FactorOfVolumeUnitOfMeasure,
	|	&PackageWeight AS PackageWeight,
	|	&PackageVolume AS PackageVolume,
	|	ISNULL(TSProducts.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
	|	ISNULL(TSProducts.UnitOfMeasure, """") AS UnitOfMeasureDescription,
	|	ISNULL(TSProducts.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForWeight,
	|	ISNULL(TSProducts.WeightUnitOfMeasure.Presentation, """") AS NameOfWeightUnitOfMeasure,
	|	ISNULL(TSProducts.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForVolume,
	|	ISNULL(TSProducts.VolumeUnitOfMeasure.Presentation, """") AS NameOfVolumeUnitOfMeasure,
	|	ISNULL(TSProducts.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)) AS MeasuredValueType,
	|	ISNULL(TSProducts.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE) AS SpecifyNumberWhenRegisteringBatch,
	|	ISNULL(TSProducts.ProductKind.UseShelfLifeOnBatchRegistration, FALSE) AS UseShelfLifeOnBatchRegistration,
	|	ISNULL(TSProducts.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)) AS PrecisionOfBatchShelfLifeIndication,
	|	NotShippedGoods.Count AS Count,
	|	NotShippedGoods.NumberOfPackages AS NumberOfPackages
	|FROM
	|	NotShippedGoods AS NotShippedGoods
	|		LEFT JOIN Catalog.Products AS TSProducts
	|		ON NotShippedGoods.Products = TSProducts.Ref
	|		LEFT JOIN Catalog.ItemsCharacteristics AS TSCharacteristics
	|		ON NotShippedGoods.Characteristic = TSCharacteristics.Ref
	|		LEFT JOIN Catalog.Assignments AS DestinationTS_
	|		ON NotShippedGoods.Purpose = DestinationTS_.Ref
	|		LEFT JOIN Catalog.ItemsBatches AS TSSetOfSeries
	|		ON NotShippedGoods.Series = TSSetOfSeries.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS TSPackaging
	|		ON NotShippedGoods.Package = TSPackaging.Ref";
	
	SourceOfPackaging = "TSPackaging";
	SourceOfProducts = "TSProducts";
	SourceOfWeightUnit = "TSProducts.WeightUnitOfMeasure";
	SourceVolumeUnits = "TSProducts.VolumeUnitOfMeasure";
	
	// Substitution "Coefficient 1" - packing coefficient
	QueryText = StrReplace(QueryText, "&ZoomRatio1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfPackaging, SourceOfProducts));
	
	// Substitution "Coefficient 2" - coefficient of the unit of measurement of the weight of the item
	QueryText = StrReplace(QueryText, "&ZoomRatio2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfWeightUnit, Undefined));
	
	// Substitution "Coefficient 3" - coefficient of the unit of measurement of the volume of the nomenclature
	QueryText = StrReplace(QueryText, "&ZoomRatio3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceVolumeUnits, Undefined));
	
	// Substitution of the "weight of the package"
	QueryText = StrReplace(QueryText, "&PackageWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(SourceOfPackaging, SourceOfProducts, False));
	
	// Substitution of the "Packaging volume"
	QueryText = StrReplace(QueryText, "&PackageVolume",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(SourceOfPackaging, SourceOfProducts, False));
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	NotShippedGoods = QueryResult.Unload();
	
EndProcedure

// Adds data to the 'product Cells' table.
//
// Parameters:
//	CellGoods - ValueTable - table of products stored in the cell.
//
Procedure AddDataToCellItems(CellGoods)
	
	Query = New Query;
	Manager = New TempTablesManager;
	
	Query.TempTablesManager = Manager;
	Query.SetParameter("CellGoods", CellGoods);
	
	QueryText =
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.ItemName AS ItemName,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.ItemVariantName AS ItemVariantName,
	|	Goods.Package AS Package,
	|	Goods.PackageName AS PackageName,
	|	Goods.Series AS Series,
	|	Goods.BatchName AS BatchName,
	|	Goods.UnitOfMeasure AS UnitOfMeasure,
	|	Goods.UnitOfMeasureDescription AS UnitOfMeasureDescription,
	|	Goods.MeasuredValueType AS MeasuredValueType,
	|	Goods.Count AS Count
	|INTO ProductsToRequest
	|FROM
	|	&CellGoods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsToRequest.Products AS Products,
	|	ProductsToRequest.ItemName AS ItemName,
	|	ISNULL(TSProducts.SKU, """") AS ProductIDOfItems,
	|	ISNULL(TSProducts.LongDesc, """") AS ItemsDescription,
	|	TSProducts.ProductKind AS ProductKind,
	|	ISNULL(TSProducts.ProductKind.Presentation, """") AS NameOfTypeOfProduct,
	|	ISNULL(TSProducts.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
	|	ProductsToRequest.Characteristic AS Characteristic,
	|	ProductsToRequest.ItemVariantName AS ItemVariantName,
	|	ProductsToRequest.Package AS Package,
	|	ProductsToRequest.PackageName AS PackageName,
	|	ProductsToRequest.Series AS Series,
	|	ProductsToRequest.BatchName AS BatchName,
	|	ProductsToRequest.UnitOfMeasure AS UnitOfMeasure,
	|	ProductsToRequest.UnitOfMeasureDescription AS UnitOfMeasureDescription,
	|	ISNULL(&ZoomRatio1, 1) AS ZoomRatio,
	|	ISNULL(&ZoomRatio2, 1) AS FactorOfWeightUnitOfMeasure,
	|	ISNULL(&ZoomRatio3, 1) AS FactorOfVolumeUnitOfMeasure,
	|	&PackageWeight AS PackageWeight,
	|	&PackageVolume AS PackageVolume,
	|	ISNULL(TSProducts.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForWeight,
	|	ISNULL(TSProducts.WeightUnitOfMeasure.Presentation, """") AS NameOfWeightUnitOfMeasure,
	|	ISNULL(TSProducts.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForVolume,
	|	ISNULL(TSProducts.VolumeUnitOfMeasure.Presentation, """") AS NameOfVolumeUnitOfMeasure,
	|	ProductsToRequest.MeasuredValueType AS MeasuredValueType,
	|	ISNULL(TSProducts.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE) AS SpecifyNumberWhenRegisteringBatch,
	|	ISNULL(TSProducts.ProductKind.UseShelfLifeOnBatchRegistration, FALSE) AS UseShelfLifeOnBatchRegistration,
	|	ISNULL(TSProducts.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)) AS PrecisionOfBatchShelfLifeIndication,
	|	ProductsToRequest.Count AS Count
	|FROM
	|	ProductsToRequest AS ProductsToRequest
	|		LEFT JOIN Catalog.Products AS TSProducts
	|		ON ProductsToRequest.Products = TSProducts.Ref";
	
	SourceOfPackaging = "ProductsToRequest.Package";
	SourceOfProducts = "ProductsToRequest.Products";
	SourceOfWeightUnit = "TSProducts.WeightUnitOfMeasure";
	SourceVolumeUnits = "TSProducts.VolumeUnitOfMeasure";
	
	// Substitution "Coefficient 1" - packing coefficient
	QueryText = StrReplace(QueryText, "&ZoomRatio1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfPackaging, SourceOfProducts));
	
	// Substitution "Coefficient 2" - coefficient of the unit of measurement of the weight of the item
	QueryText = StrReplace(QueryText, "&ZoomRatio2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfWeightUnit, Undefined));
	
	// Substitution "Coefficient 3" - coefficient of the unit of measurement of the volume of the nomenclature
	QueryText = StrReplace(QueryText, "&ZoomRatio3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceVolumeUnits, Undefined));
	
	// Substitution of the "weight of the package"
	QueryText = StrReplace(QueryText, "&PackageWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(SourceOfPackaging, SourceOfProducts, False));
	
	// Substitution of the "Packaging volume"
	QueryText = StrReplace(QueryText, "&PackageVolume",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(SourceOfPackaging, SourceOfProducts, False));
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	CellGoods = QueryResult.Unload();
	
EndProcedure

// Returns the value of the object reference property.
//
// Parameters:
//	Ref - CatalogRef, DocumentRef - link to an object, reference list item, or document,
//	AttributeName - String
//
// Returns:
//	Arbitrary
//
Function AttributeValue(Ref, AttributeName)
	
	Description = Common.ObjectAttributeValue(Ref, AttributeName);
	
	Return Description;
	
EndFunction

// Returns the name of the warehouse task document object.
//
// Parameters:
//	JobType - String - type of warehouse task.
//
// Returns:
//	String - the name of the object of the warehouse task document.
//
Function DocumentName(JobType)
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		DocumentName = "GoodsPickingPlacement";
		
	ElsIf JobType = "Receiving" Then
		DocumentName = "GoodsReceiptNote";
	ElsIf JobType = "Recalculate" Then
		DocumentName = "InventoryRecount";
	ElsIf JobType = "PickingCheck" Then
		DocumentName = "GoodsIssueNote";
	EndIf;
	
	Return DocumentName;
	
EndFunction

// Returns a flag for specifying series based on selection.
//
// Parameters:
//	BatchesIndicationStatus - Number - the status of specifying the series.
//
// Returns:
//	Boolean - True, the series are indicated upon selection.
//
Function SeriesAreIndicatedUponSelection(BatchesIndicationStatus)
	
	ArrayOfStatuses = New Array;
	ArrayOfStatuses.Add(3);
	ArrayOfStatuses.Add(4);
	
	Return Not (ArrayOfStatuses.Find(BatchesIndicationStatus) = Undefined);
	
EndFunction

// Returns the ID of the document link by object name.
//
// Parameters:
//	IdString - String - ID of the warehouse task document,
//	DocumentName - String- name of the warehouse task document object.
//
// Returns:
//	DocumentRef
//
Function DocumentLink_(IdString, DocumentName)
	
	DocumentID_2 = New UUID(IdString);
	DocumentLink_ = Documents[DocumentName].GetRef(DocumentID_2);
	
	Return DocumentLink_;
	
EndFunction

// Returns the reference ID of the warehouse task document by type of warehouse operation.
//
// Parameters:
//	TaskID_ - String - ID of the warehouse task document,
//	JobType - String- type of warehouse task.
//
// Returns:
//	UUID - the reference ID of the warehouse task document.
//
Function TaskLink(TaskID_, JobType)
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		Job = DocumentLink_(TaskID_, "GoodsPickingPlacement");
	ElsIf JobType = "Receiving" Then
		Job = DocumentLink_(TaskID_, "GoodsReceiptNote");
	ElsIf JobType = "Recalculate" Then
		Job = DocumentLink_(TaskID_, "InventoryRecount");
	ElsIf JobType = "PickingCheck" Then
		Job = DocumentLink_(TaskID_, "GoodsIssueNote");
	EndIf;
	
	Return Job;
	
EndFunction

// Returns the reference reference ID for the object name.
//
// Parameters:
//	IdString - String - ID of the reference list,
//	CatalogName - String- name of the directory object.
//
// Returns:
//	CatalogRef - ID of the reference directory.
//
Function CatalogLink(IdString, CatalogName) Export
	
	CatalogID = New UUID(IdString);
	CatalogLink = Catalogs[CatalogName].GetRef(CatalogID);
	
	Return CatalogLink;
	
EndFunction

// Deletes rows in 'scanned Goods' whose values in the 'Quantity' column are 0.
//
// Parameters:
//	ScannedGoods - ValueTable
//
Procedure DeleteBlankRowsScannedProducts(ScannedGoods)
	
	Filter = New Structure("NumberOfPackages", 0);
	ArrayOfEmptyStrings = ScannedGoods.FindRows(Filter);
	
	For Each IsBlankString In ArrayOfEmptyStrings Do
		ScannedGoods.Delete(IsBlankString);
	EndDo;
	
EndProcedure

// Checks whether the item is a container.
//
// Parameters:
//	StructureOfData - FormDataStructure, Structure -
//
// Returns:
//	Boolean - True, the nomenclature is a container.
//
Function ThisIsTara(StructureOfData)
	
	Return (StructureOfData.ItemsType = Enums.ItemsTypes.ReusablePackage);
	
EndFunction

Function FullNameOfService(Val ServiceName, Val ServiceVersion = "")

	If ValueIsFilled(ServiceVersion) Then
		VersionParts = StrSplit(ServiceVersion,".",False);
		VersionParts.Insert(0,ServiceName);
		ServiceName = StrConcat(VersionParts,"_");
	EndIf; 
	
	Return ServiceName;

EndFunction // Full Service name()

#EndRegion

#Region Constructors


#EndRegion

#EndRegion