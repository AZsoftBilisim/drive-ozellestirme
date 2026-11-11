
#Region Private

// Operation for getting the number of warehouse tasks of the specified type.
//
// Parameters:
//	IdWarehouse - String- the ID of the warehouse,
//	IdStorage - String- the ID of the room,
//	JobType - XDTODataObject - Task type - type of warehouse task,
//	IdExecutor - String- ID of the warehouse task performer,
//	JobsByWithoutIncluded - Boolean - True - getting the number of all available warehouse tasks.
//
// Returns:
//	Number - the number of tasks available for the specified type.
//
Function GetJobsCount(IdWarehouse, IdStorage, JobType, IdExecutor, JobsByWithoutIncluded)
	
	JobsCount = WorkplaceOfWarehouseWorkerXDTO.NumberOfWarehouseJobsWS(IdWarehouse, IdStorage, JobType,
		IdExecutor, JobsByWithoutIncluded);
	
	Return JobsCount;
	
EndFunction

// Operation to get the task table of the selected operation type.
//
// Parameters:
//	IdWarehouse - String- the ID of the warehouse,
//	IdStorage - String- the ID of the room,
//	JobType - XDTODataObject - Task type - type of warehouse task,
//	IdExecutor - String- ID of the warehouse task performer,
//	JobsByWithoutIncluded - Boolean - True - getting the number of all available warehouse tasks.
//
// Returns:
//	XDTODataObject - a table of tasks of a given type.
//
Function GetJobsTable(IdWarehouse, IdStorage, JobType, IdExecutor, JobsByWithoutIncluded)
	
	WSJobTable = WorkplaceOfWarehouseWorkerXDTO.WSJobTable(IdWarehouse, IdStorage, JobType, IdExecutor,
		JobsByWithoutIncluded, ServiceVersion());
	
	Return WSJobTable;
	
EndFunction

// Operation for getting information with the warehouse task service information based on the barcode of the warehouse task document.
//
// Parameters:
//	Barcode - String- barcode of the warehouse task,
//	IdWarehouse - String- the ID of the warehouse,
//	IdStorage - String- the ID of the room,
//	IdExecutor - String- ID of the warehouse task performer,
//	JobType - XDTODataObject - Task type - the type of warehouse task.
//	AddMarkInfo - Number - depth of detail of information on marked packages:
//				0 - do not request
//				999 data - no nesting restrictions
//
// Returns:
//	XDTODataObject - warehouse task parameters:
//		Successful - Boolean, True - warehouse task data received,
//		Message text - String - Informational message,
//		Processing order - ObjectXDTO - warehouse task processing order,
//		Source Executor - Users - ObjectXDTO - source executor of the warehouse task,
//		Selecting the placement of goods - Selecting the placement of goods - ObjectXDTO - data of the document 'Selection (placement) of goods',
//		Recalculation of goods - Recalculation of goods - ObjectXDTO - data of the document 'Recalculation of goods',
//		Incoming Order of goods - Incoming Order of goods - ObjectXDTO - data of the document 'Incoming order for goods',
//		Consumables - Consumables - ObjectXDTO - data of the document 'Expenditure order for goods'.
//
Function GetJobIDAndTypeByBarcode(Barcode, IdWarehouse, IdStorage, IdExecutor, JobType, AddMarkInfo)
	
	JobParameters = WorkplaceOfWarehouseWorkerXDTO.TaskParametersForWSBarcode(
		Barcode, IdWarehouse, IdStorage, IdExecutor, JobType, AddMarkInfo, ServiceVersion());
	
	Return JobParameters;
	
EndFunction

// Operation for getting information with the service information of a warehouse task by clicking the link in the warehouse task document.
//
// Parameters:
//	IdJob - String- ID of the warehouse task document,
//	IdExecutor - String- ID of the warehouse task performer,
//	JobType - XDTODataObject - Task type - the type of warehouse task.
//	AddMarkInfo - Number - depth of detail of information on marked packages:
//				0 - do not request
//				999 data - no nesting restrictions
//
// Returns:
//	XDTODataObject - warehouse task parameters:
//		Successful - Boolean, True - warehouse task data received,
//		Message text - String - Informational message,
//		Processing order - ObjectXDTO - warehouse task processing order,
//		Source Executor - Users - ObjectXDTO - source executor of the warehouse task,
//		Selecting the placement of goods - Selecting the placement of goods - ObjectXDTO - data of the document 'Selection (placement) of goods',
//		Recalculation of goods - Recalculation of goods - ObjectXDTO - data of the document 'Recalculation of goods',
//		Incoming Order of goods - Incoming Order of goods - ObjectXDTO - data of the document 'Incoming order for goods',
//		Consumables - Consumables - ObjectXDTO - data of the document 'Expenditure order for goods'.
//
Function GetAndTakeAllotmentPickJob(IdJob, IdExecutor, JobType, AddMarkInfo)
	
	JobParameters = WorkplaceOfWarehouseWorkerXDTO.JobParametersWhenWSIsAcceptedForWork(
		IdJob, IdExecutor, JobType, AddMarkInfo, ServiceVersion());
	
	Return JobParameters;
	
EndFunction

// Operation for getting data about warehouses intended for receiving and shipping goods.
//
// Parameters:
//	IdWarehouse - String- the ID of the warehouse,
//	IdStorage - String- the ID of the room.
//
// Returns:
//	XDTODataObject - parameters of storage cells:
//		Successful - Boolean, True - warehouse task data received,
//		Message text - String - Informational message,
//		Loading zones - ObjectXDTO - table of storage cells.
//
Function GetAcceptanceAreas(IdWarehouse, IdStorage)
	
	CellListParameters = WorkplaceOfWarehouseWorkerXDTO.WSShipmentAcceptanceZones(
		IdWarehouse, IdStorage, ServiceVersion());
	
	Return CellListParameters;
	
EndFunction

// Operation for getting data about products stored in a warehouse cell by using the cell link.
//
// Parameters:
//	IdCell - String- ID of the storage cell.
//
// Returns:
//	XDTODataObject - parameters of the goods stored in the cell:
//		Successful - Boolean, True - warehouse task data received,
//		Message text - String - Informational message,
//		Cell - Storage cells - ObjectXDTO, Undefined - storage cell,
//		Product Cells - ObjectXDTO - table of products stored in the cell.
//
Function GetGoodsOfCellStored(IdCell)
	
	CellProductParameters = WorkplaceOfWarehouseWorkerXDTO.WSCellProducts(IdCell, ServiceVersion());
	
	Return CellProductParameters;
	
EndFunction

// Operation for getting data about goods stored in a warehouse cell using the cell's barcode.
//
// Parameters:
//	Barcode - String- the barcode warehouse of the cell,
//	IdWarehouse - String- the ID of the warehouse,
//	IdStorage - String- the ID of the room.
//
// Returns:
//	XDTODataObject - parameters of the goods stored in the cell:
//		Successful - Boolean, True - warehouse task data received,
//		Message text - String - Informational message,
//		Cell - Storage cells - ObjectXDTO, Undefined - storage cell,
//		Product Cells - ObjectXDTO - table of products stored in the cell.
//
Function GetGoodsOfCellStoredByBarcode(Barcode, IdWarehouse, IdStorage)
	
	CellProductParameters = WorkplaceOfWarehouseWorkerXDTO.CellProductsByBarcodeWS(
		Barcode, IdWarehouse, IdStorage, ServiceVersion());
	
	Return CellProductParameters;
	
EndFunction

// Operation for getting data about goods stored in a warehouse cell using the cell's barcode.
//
// Parameters:
//	IdJob - String- ID of the warehouse task document,
//	ScannedGoods - XDTODataValue - Scanned goods table - scanned goods of the warehouse task.
//
// Returns:
//	XDTODataObject - parameters processing of selected goods of the warehouse operation "Moving":
//		Successfully - Boolean, True - the data of the warehouse task has been received,
//		Message text - String - Informational message,
//		Product Selection - Selection placement of goods Product Selection - ObjectXDTO - table of selected document goods 
//			'Selection (placement) of goods', after performing the selection of goods according to the task of the warehouse operation "Moving".
//
Function SetPickedGoodsInAllotmentPickJob(IdJob, ScannedGoods)
	
	JobParameters = WorkplaceOfWarehouseWorkerXDTO.ProcessScannedGoodsToMoveWS(
		IdJob, ScannedGoods, ServiceVersion());
	
	Return JobParameters;
	
EndFunction

// Operation to cancel a warehouse operation. Sets the initial data of the warehouse task document 
// before it is accepted by the storekeeper for execution.
//
// Parameters:
//	IdJob - String- ID of the warehouse task document,
//	IdExecutor - String- ID of the warehouse task performer,
//	JobType - XDTODataObject - Task type - the type of warehouse task.
//
// Returns:
//	XDTODataObject - the parameters of the warehouse task of the "Move" operation:
//		are Successful - Boolean, True - the warehouse task data has been received,
//		Message text - String - informational message.
//
Function CancelJob(IdJob, IdExecutor, JobType)
	
	JobParameters = WorkplaceOfWarehouseWorkerXDTO.CancelWSJob(
		IdJob, IdExecutor, JobType, ServiceVersion());
	
	Return JobParameters;
	
EndFunction

// Operation to complete the warehouse operation. When scanning products, the scanned products
// are transferred to the tabular parts of the documents. The necessary statuses are 
// set for documents, and documents are processed.
//
// Parameters:
//	IdJob - String- ID of the warehouse task document,
//	IdExecutor - String- ID of the warehouse task performer,
//	ScannedGoods - XDTODataValue - Table of scanned goods - scanned goods of the warehouse task,
//	JobType - XDTODataObject - Task type - type of warehouse task,
//	ScannedMarks - XDTODataObject - list of scanned marking barcodes
//	AdditionalOptions - ObjectXDTO - parametersthe completion of the relocation - parameters of the completion of the warehouse operation 
//		"Moving".
//
// Returns:
//	XDTODataObject - the parameters of the warehouse task of the "Move" operation:
//		are successful - Boolean, True - the warehouse task data has been received,
//		Message text - String - Informational message,
//		Task - String, Undefined - ID of the document 'Selection (placement) of goods' of the warehouse operation "Placement",
//		Unloaded goods - Table of unloaded goods - ObjectXDTO - table of unloaded goods of the warehouse 
//			operation "Selection check".
//
Function CompleteJob(IdJob, IdExecutor, ScannedGoods, JobType, AdditionalOptions, ScannedMarks)
	
	JobParameters = WorkplaceOfWarehouseWorkerXDTO.CompleteWsWarehouseTask(IdJob,
		IdExecutor, ScannedGoods, JobType, AdditionalOptions, ScannedMarks, ServiceVersion());
	
	Return JobParameters;
	
EndFunction

// Operation to complete the warehouse operation. When scanning products, the scanned products
// are transferred to the tabular parts of the documents. The necessary statuses are 
// set for documents, and documents are processed.
//
// Parameters:
//	IdWarehouse - String- the ID of the warehouse,
//	IdStorage - String- the ID of the room,
//	IdAcceptanceDock - String - ID of the warehouse cell in the acceptance zone,
//	IdExecutor - String- ID of the warehouse task performer,
//	ScannedGoods - XDTODataValue - Scanned goods table - scanned goods of the warehouse task.
//	
//
// Returns:
//	XDTODataObject - the parameters of the warehouse task of the "Move" operation:
//		are successful - Boolean, True - the warehouse task data has been received,
//		Message text - String - Informational message,
//		Task - String - ID of the document 'Selection (placement) of goods' of the warehouse operation "Placement",
//		Unloaded goods - Table of unloaded goods - ObjectXDTO, Indefinite - table of unloaded goods
//			of the warehouse operation "Selection check".
//
Function CompleteJobNewLocation(IdWarehouse, IdStorage, IdAcceptanceDock, IdExecutor, ScannedGoods)
	
	JobParameters = WorkplaceOfWarehouseWorkerXDTO.FinishTaskNewWSPlacement(IdWarehouse, IdStorage,
		IdAcceptanceDock, IdExecutor, ScannedGoods, ServiceVersion());
	
	Return JobParameters;
	
EndFunction

Function ServiceVersion()

	Return "2.5.9";

EndFunction
 
#EndRegion
