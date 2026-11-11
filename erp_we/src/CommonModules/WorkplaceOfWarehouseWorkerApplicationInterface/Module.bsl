////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions that are called when accessing the information base
// from the general module "Worker-Worker-Warehouse", as well as when accessing the functions of the web service.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the number - the number of task documents available for the warehouse employee to complete.
//
// Parameters:
//	Warehouse - CatalogRef.Warerooms - warehouse for which the number of tasks is returned,
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	JobType - String - the type of warehouse job,
//	Assignees - Array of CatalogRef.Users - list of task performers.
//
// Returns:
//	Number - the number of tasks available for the specified type.
//
Function NumberOfWarehouseTasksToComplete(Warehouse, Premise, JobType, Assignees) Export
	
	Query = New Query;
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Assignees", Assignees);
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		OperationKind = TypeOfPlacementSelectionOperation(JobType);
		WarehouseZones = ContractorSWorkAreas(Warehouse, Premise, Assignees);
		
		Query.SetParameter("OperationKind", OperationKind);
		Query.SetParameter("WarehouseZones", WarehouseZones);
		Query.SetParameter("SelectionByWorkingAreas", WarehouseZones.Count() > 1);
		
		Query.Text = 
		"SELECT
		|	COUNT(*) AS DocumentsCount
		|FROM
		|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
		|WHERE
		|	GoodsPickingPlacement.OperationKind = &OperationKind
		|	AND GoodsPickingPlacement.Posted
		|	AND GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2)
		|	AND GoodsPickingPlacement.Performer IN (&Assignees)
		|	AND GoodsPickingPlacement.Warehouse = &Warehouse
		|	AND GoodsPickingPlacement.Premise = &Premise
		|	AND (NOT &SelectionByWorkingAreas
		|		OR GoodsPickingPlacement.WarehouseZone IN(&WarehouseZones))";
		
	ElsIf JobType = "Recalculate" Then
		
		Query.Text = 
		"SELECT
		|	COUNT(*) AS DocumentsCount
		|FROM
		|	Document.InventoryRecount AS InventoryRecount
		|WHERE
		|	InventoryRecount.Posted
		|	AND InventoryRecount.Status = VALUE(Enum.InventoryRecountStatuses.Prepared2)
		|	AND InventoryRecount.Performer IN(&Assignees)
		|	AND InventoryRecount.Warehouse = &Warehouse
		|	AND InventoryRecount.Premise = &Premise";
		
	ElsIf JobType = "Receiving" Then
		
		Query.Text = 
		"SELECT
		|	COUNT(*) AS DocumentsCount
		|FROM
		|	Document.GoodsReceiptNote AS GoodsReceiptNote
		|WHERE
		|	GoodsReceiptNote.Posted
		|	AND GoodsReceiptNote.Status = VALUE(Enum.GoodsReceiptNoteStatuses.ToReceive)
		|	AND GoodsReceiptNote.Warehouse = &Warehouse
		|	AND GoodsReceiptNote.Premise = &Premise
		|	AND GoodsReceiptNote.Performer IN(&Assignees)";
		
	ElsIf JobType = "PickingCheck" Then
		
		Query.Text = 
		"SELECT
		|	COUNT(*) AS DocumentsCount
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.Posted
		|	AND GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForChecking)
		|	AND GoodsIssueNote.Warehouse = &Warehouse
		|	AND GoodsIssueNote.Premise = &Premise
		|	AND GoodsIssueNote.Inspector IN(&Assignees)";
		
	EndIf;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.DocumentsCount;
	
EndFunction

// Returns a table of tasks, the selected operation type, and the specified users.
//
// Parameters:
//	Warehouse - CatalogRef.Warehouses - warehouse,
//	Premise - CatalogRef.Warerooms - warehouse premises,
//	JobType - String - type of warehouse tasks,
//	Performer - Array of CatalogRef.Users - list of task performers.
//
// Returns:
//	ValueTable:
//	*Ref - DocumentRef - warehouse document
//	*Number - String - document number
//	*Performer - CatalogRef.Users
//	*AssigneeName - String
//	*ArtistNumber - Number 
//	*UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//	*UnitOfMeasureDescription - String
//
Function TaskTable(Warehouse, Premise, JobType, Performer) Export
	
	QueryText = "";
	UnitOfMeasure = Constants.UnitOfMeasureForWeight.Get();
	
	If JobType = "Filter" Then
		
		QueryText = 
		"SELECT
		|	GoodsPickingPlacement.Ref AS Ref,
		|	CASE
		|		WHEN GoodsPickingPlacement.Performer <> VALUE(Catalog.Users.EmptyRef)
		|			THEN 0
		|		ELSE 1
		|	END AS ArtistNumber,
		|	GoodsPickingPlacement.Number AS Number,
		|	GoodsPickingPlacement.Performer AS Performer,
		|	ISNULL(GoodsPickingPlacement.Performer.Presentation, """") AS AssigneeName,
		|	GoodsPickingPlacement.WeightFilter AS Weight,
		|	&UnitOfMeasure AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(&UnitOfMeasure), """") AS UnitOfMeasureDescription
		|FROM
		|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
		|WHERE
		|	GoodsPickingPlacement.Posted
		|	AND GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2)
		|	AND GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter)
		|	AND GoodsPickingPlacement.Warehouse = &Warehouse
		|	AND GoodsPickingPlacement.Premise = &Premise
		|	AND GoodsPickingPlacement.Performer IN(&Performer)
		|	AND (NOT &SelectionByWorkingAreas
		|		OR GoodsPickingPlacement.WarehouseZone IN(&WarehouseZones))
		|
		|ORDER BY
		|	ArtistNumber";
		
	ElsIf JobType = "Move" Then
		
		QueryText =
		"SELECT
		|	GoodsPickingPlacement.Ref AS Ref,
		|	CASE
		|		WHEN GoodsPickingPlacement.Performer <> VALUE(Catalog.Users.EmptyRef)
		|			THEN 0
		|		ELSE 1
		|	END AS ArtistNumber,
		|	GoodsPickingPlacement.Number AS Number,
		|	GoodsPickingPlacement.Performer AS Performer,
		|	ISNULL(GoodsPickingPlacement.Performer.Presentation, """") AS AssigneeName,
		|	GoodsPickingPlacement.WeightFilter AS Weight,
		|	&UnitOfMeasure AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(&UnitOfMeasure), """") AS UnitOfMeasureDescription
		|FROM
		|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
		|WHERE
		|	GoodsPickingPlacement.Posted
		|	AND GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2)
		|	AND GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Move)
		|	AND GoodsPickingPlacement.Warehouse = &Warehouse
		|	AND GoodsPickingPlacement.Premise = &Premise
		|	AND GoodsPickingPlacement.Performer IN(&Performer)
		|	AND (NOT &SelectionByWorkingAreas
		|		OR GoodsPickingPlacement.WarehouseZone IN(&WarehouseZones))
		|
		|ORDER BY
		|	ArtistNumber";
		
	ElsIf JobType = "Location" Then
		
		QueryText =
		"SELECT
		|	GoodsPickingPlacement.Ref AS Ref,
		|	GoodsPickingPlacement.Number AS Number,
		|	CASE
		|		WHEN GoodsPickingPlacement.Performer <> VALUE(Catalog.Users.EmptyRef)
		|			THEN 0
		|		ELSE 1
		|	END AS ArtistNumber,
		|	GoodsPickingPlacement.Performer AS Performer,
		|	ISNULL(GoodsPickingPlacement.Performer.Presentation, """") AS AssigneeName,
		|	GoodsPickingPlacement.WeightPlacement AS Weight,
		|	&UnitOfMeasure AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(&UnitOfMeasure), """") AS UnitOfMeasureDescription
		|FROM
		|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
		|WHERE
		|	GoodsPickingPlacement.Posted
		|	AND GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2)
		|	AND GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)
		|	AND GoodsPickingPlacement.Warehouse = &Warehouse
		|	AND GoodsPickingPlacement.Premise = &Premise
		|	AND GoodsPickingPlacement.Performer IN(&Performer)
		|	AND (NOT &SelectionByWorkingAreas
		|		OR GoodsPickingPlacement.WarehouseZone IN(&WarehouseZones))
		|
		|ORDER BY
		|	ArtistNumber";
		
	ElsIf JobType = "Recalculate" Then
		
		QueryText =
		"SELECT
		|	InventoryRecount.Ref AS Ref,
		|	InventoryRecount.Number AS Number,
		|	CASE
		|		WHEN InventoryRecount.Performer <> VALUE(Catalog.Users.EmptyRef)
		|			THEN 0
		|		ELSE 1
		|	END AS ArtistNumber,
		|	InventoryRecount.Performer AS Performer,
		|	ISNULL(InventoryRecount.Performer.Presentation, """") AS AssigneeName
		|FROM
		|	Document.InventoryRecount AS InventoryRecount
		|WHERE
		|	InventoryRecount.Posted
		|	AND InventoryRecount.Status = VALUE(Enum.InventoryRecountStatuses.Prepared2)
		|	AND InventoryRecount.Warehouse = &Warehouse
		|	AND InventoryRecount.Premise = &Premise
		|	AND InventoryRecount.Performer IN(&Performer)
		|
		|ORDER BY
		|	ArtistNumber";
		
	ElsIf JobType = "PickingCheck" Then
		
		QueryText =
		"SELECT
		|	GoodsIssueNote.Ref AS Ref,
		|	GoodsIssueNote.Number AS Number,
		|	CASE
		|		WHEN GoodsIssueNote.Inspector <> VALUE(Catalog.Users.EmptyRef)
		|			THEN 0
		|		ELSE 1
		|	END AS ArtistNumber,
		|	GoodsIssueNote.Inspector AS Performer,
		|	ISNULL(GoodsIssueNote.Inspector.Presentation, """") AS AssigneeName,
		|	GoodsIssueNote.DeliveryProcedure AS DeliveryProcedure
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.Posted
		|	AND GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForChecking)
		|	AND GoodsIssueNote.Warehouse = &Warehouse
		|	AND GoodsIssueNote.Premise = &Premise
		|	AND GoodsIssueNote.Inspector IN(&Performer)
		|
		|ORDER BY
		|	ArtistNumber";
		
	ElsIf JobType = "Receiving" Then
		
		QueryText =
		"SELECT
		|	GoodsReceiptNote.Ref AS Ref,
		|	GoodsReceiptNote.Number AS Number,
		|	CASE
		|		WHEN GoodsReceiptNote.Performer <> VALUE(Catalog.Users.EmptyRef)
		|			THEN 0
		|		ELSE 1
		|	END AS ArtistNumber,
		|	GoodsReceiptNote.Performer AS Performer,
		|	ISNULL(GoodsReceiptNote.Performer.Presentation, """") AS AssigneeName
		|FROM
		|	Document.GoodsReceiptNote AS GoodsReceiptNote
		|WHERE
		|	GoodsReceiptNote.Posted
		|	AND GoodsReceiptNote.Status = VALUE(Enum.GoodsReceiptNoteStatuses.ToReceive)
		|	AND GoodsReceiptNote.Warehouse = &Warehouse
		|	AND GoodsReceiptNote.Premise = &Premise
		|	AND GoodsReceiptNote.Performer IN(&Performer)
		|
		|ORDER BY
		|	ArtistNumber";
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Performer", Performer);
	Query.SetParameter("UnitOfMeasure", UnitOfMeasure);
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		WarehouseZones = ContractorSWorkAreas(Warehouse, Premise, Performer);
		
		Query.SetParameter("WarehouseZones", WarehouseZones);
		Query.SetParameter("SelectionByWorkingAreas", WarehouseZones.Count() > 1);
		
	EndIf;
	
	QueryResult = Query.Execute();
	TaskTable = QueryResult.Unload();
	
	Return TaskTable;
	
EndFunction

// Returns a structure with service information about the task.
// This function is called when scanning the barcode of a warehouse task.
//
// Parameters:
//	Barcode - String - task barcode.
//	Warehouse - CatalogRef.Warehouses - warehouse.
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	User - CatalogRef.Users - the contractor warehouse jobs,
//	JobType - String - type of warehouse task.
//	OperationSelectionMode - Boolean - True if the job was scanned from the select operation menu.
//									False if the job was scanned from the Main menu of the workplace form.
//	DepthOfDetailOfMarking - Number - depth of detail of information on marked packages:
//				0 - without detail
//				999 - without limitation of nesting
//
// Returns:
//	See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function BarcodeTaskParameters(Barcode, Warehouse, Premise, User, JobType = "",
		OperationSelectionMode = False, DepthOfDetailOfMarking = 0) Export
	
	Managers = New Array;
	
	If Not ValueIsFilled(JobType) Then
		OperationSelectionMode = True;
	EndIf;
	
	JobParameters = JobParameters();
	
	If OperationSelectionMode
		Or JobType = "PickingCheck" Then
		
		Managers.Add(Documents.GoodsIssueNote.EmptyRef());
		
	EndIf;
	
	If OperationSelectionMode
		Or JobType = "Receiving" Then
		
		Managers.Add(Documents.GoodsReceiptNote.EmptyRef());
		
	EndIf;
	
	If OperationSelectionMode
		Or JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		Managers.Add(Documents.GoodsPickingPlacement.EmptyRef());
		
	EndIf;
	
	If OperationSelectionMode
		Or JobType = "Recalculate" Then
		
		Managers.Add(Documents.InventoryRecount.EmptyRef());
		
	EndIf;
	
	ReferencesArrray = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		Query = New Query;
		Query.SetParameter("ReferencesArrray", ReferencesArrray);
		
		Query.Text =
		"SELECT
		|	GoodsPickingPlacement.Ref AS Ref
		|FROM
		|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
		|WHERE
		|	GoodsPickingPlacement.Ref IN(&ReferencesArrray)
		|	AND &SelectionByTypeOfOperation";
		
		Query.Text = StrReplace(Query.Text, 
			"AND &SelectionByTypeOfOperation", 
			"AND GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking." + JobType +")");
		
		ReferencesArrray = Query.Execute().Unload().UnloadColumn("Ref");
		
	EndIf;
	
	If ReferencesArrray.Count() = 0 Then
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Không thể tìm thấy nhiệm vụ kho theo mã vạch.';
										|ru = 'Не удалось найти складское задание по штрихкоду.';
										|en = 'Cannot find a warehouse task using the barcode.'; fa = 'Cannot find a warehouse task using the barcode.';
										|it = 'Non è stato possibile individuare il task di magazzino tramite codice a barre.';
										|pl = 'Nie udało się znaleźć zadanie magazynowe po kodu kreskowym.';
										|tr = 'Barkod ile ambar görevi bulunamadı.'");
		
		Return JobParameters;
	EndIf;
	
	JobParameters.Insert("Job", ReferencesArrray[0]);
	Job = JobParameters.Job;
	
	If OperationSelectionMode Then
		If TypeOf(Job) = Type("DocumentRef.GoodsReceiptNote") Then
			JobType = "Receiving";
		ElsIf TypeOf(Job) = Type("DocumentRef.InventoryRecount") Then
			JobType = "Recalculate";
		ElsIf TypeOf(Job) = Type("DocumentRef.GoodsIssueNote") Then
			JobType = "PickingCheck";
		ElsIf TypeOf(Job) = Type("DocumentRef.GoodsPickingPlacement") Then
			JobType = JobType(Job);
		EndIf;
	EndIf;
	
	JobParameters.JobType = JobType;
	SetJobParameters(Job, JobParameters);
	
	If AcceptanceOfWarehouseTaskIsAvailable(Warehouse, Premise, User, JobParameters) Then
		Return JobParametersWhenAcceptedForWork(Job, User, JobParameters);
	Else
		Return JobParameters;
	EndIf;
	
EndFunction

// Returns a structure with service information about the task.
// This function is called when you select a task from the "Tasks" tabular part of the "Workworkworkersclad" processing form.
//
// Parameters:
//	Job - DocumentRef - warehouse task link,
//	User - CatalogRef.Users - warehouse task executor
//	JobParameters - See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
// Returns:
//	See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function JobParametersWhenAcceptedForWork(Job, User, JobParameters = Undefined) Export
	
	If JobParameters = Undefined Then
		JobType = JobType(Job);
		
		JobParameters = JobParameters();
		JobParameters.JobType = JobType;
	EndIf;
	
	JobParameters.SourceExecutor = OriginalWarehouseTaskExecutor(Job, JobParameters.JobType);
	JobParameters.ProcessingProcedure_ = ProcedureForProcessingGoodsOfWarehouseTask(Job, JobParameters.JobType,
		User);
	
	Try
		LockDataForEdit(Job);
	Except
		
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
			|Đã xảy ra lỗi khi thử phong tỏa nhiệm vụ.';
			|ru = 'Не удалось взять складское задание в работу. 
			|Произошла ошибка при попытке блокировки задания.';
			|en = 'Cannot start working on the warehouse task.
			|An error occurred while locking the job.'; fa = 'Cannot start working on the warehouse task.
			|An error occurred while locking the job.';
			|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
			| Si è verificato un errore durante il tentativo di bloccare il task.';
			|pl = 'Nie udało się wziąć zadania magazynowego. 
			|Wystąpił błąd podczas próby blokady zadania.';
			|tr = 'Ambar görevi işe alınamadı. 
			|İşi kilitlemeye çalışırken hata oluştu.'");
		
		Return JobParameters;
		
	EndTry;
	
	SetTaskItems(Job, JobParameters);
	
	If JobParameters.ReturnCode = 0 Then
		Return JobParameters;
	EndIf;
	
	SetStatusOfTaskInProgress(Job, JobParameters, User);
	
	If JobParameters.ReturnCode = 0 Then
		
		If JobType = "Recalculate" Then
			MessageText = NStr("vi = 'Đã xảy ra lỗi khi thực hiện nhiệm vụ kho. 
				|Rất có thể là trong nhiệm vụ có ô hàng đã bị phong tỏa hoặc ô hàng đang tiến hành lấy ra/xếp vào.
				|Hãy thử thực hiện nhiệm vụ sau hoặc liên hệ với người quản trị.';
				|ru = 'При взятии складского задания в работу произошла ошибка. 
				|Скорее всего, в задании присутствуют уже заблокированные ячейки или ячейки, по которым ведется отбор/размещение.
				|Попробуйте взять задание в работу позже или обратитесь к администратору.';
				|en = 'An error occurred while putting the warehouse task into operation. 
				|Blocked storage bins or bins for which goods are picked or put away are likely to be in the job. Try to put the job into operation later or contact the administrator. 
				|.'; fa = 'An error occurred while putting the warehouse task into operation. 
				|Blocked storage bins or bins for which goods are picked or put away are likely to be in the job. Try to put the job into operation later or contact the administrator. 
				|.';
				|it = 'Si è verificato un errore durante la presa in lavorazione del task di magazzino. 
				| Nel task potrebbero essere presenti celle bloccate o celle di cui selezione/collocamento sono in corso. 
				| Ripetete il tentativo più tardi o rivolgetevi all''amministratore.';
				|pl = 'Przy wzięciu zadania magazynowego wyniknął błąd. 
				|Najprawdopodobniej w zadaniu są już zablokowane komórki lub komórki, w których prowadzone jest dopasowanie/rozmieszczenie. 
				|Spróbuj wziąć zadanie później lub skontaktuj się z administratorem.';
				|tr = 'Ambar görevi işe alınırken hata oluştu. 
				|Görev büyük olasılıkla zaten bloke edilmiş hücreleri veya filtre/yerleştirmenin gerçekleştirildiği hücreleri içeriyor.
				|Görevi daha sonra kabul etmeyi dene veya yöneticiyle iletişime geç.'");
		Else
			MessageText = NStr("vi = 'Đã xảy ra lỗi khi thực hiện nhiệm vụ kho. 
				|Hãy liên hệ với người quản trị.';
				|ru = 'При взятии складского задания в работу произошла ошибка. 
				|Обратитесь к администратору.';
				|en = 'An error occurred while putting the warehouse task into operation. 
				|Please contact the administrator.'; fa = 'An error occurred while putting the warehouse task into operation. 
				|Please contact the administrator.';
				|it = 'Si è verificato un errore durante la presa in lavorazione del task di magazzino. 
				| Rivolgetevi all''amministratore.';
				|pl = 'Przy wzięciu zadania magazynowego wyniknął błąd. 
				|Skontaktuj się z administratorem.';
				|tr = 'Bir ambar işi kabul edilirken hata oluştu. 
				|Yöneticiyle iletişime geç.'");
		EndIf;
		
		JobParameters.MessageText = MessageText;
		
		Return JobParameters;
		
	EndIf;
	
	If Not ValueIsFilled(JobParameters.Warehouse) Then
		SetJobParameters(Job, JobParameters);
	EndIf;
	
	FillInStatusesForSpecifyingSeries(Job, JobParameters);
	
	Return JobParameters;
	
EndFunction

// Returns a table of cells for the acceptance and shipment zones for the specified warehouse.
//
// Parameters:
//	Warehouse - CatalogRef.Warehouses - warehouse,
//	Premise - CatalogRef.Warerooms - warehouse.
//
// Returns:
//	ValueTable - table of acceptance and shipment zones:
//		* Cell - CatalogRef.StorageBins - address of the storage cell.
//		* CellCode - String - string representation of the storage cell.
//		* CellType - EnumRef.TypesOfStorageCells - type of storage cell.
//		* Warehouse - CatalogRef.Warehouses - the warehouse where the acceptance (shipment) cell is located.
//		* NameOfTheWarehouse - String - name of the warehouse.
//
Function ReceivingShippingAreas(Warehouse, Premise) Export
	
	Query = New Query;
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	
	Query.Text =
	"SELECT
	|	StorageBins.Ref AS Cell,
	|	StorageBins.Code AS CellCode,
	|	StorageBins.StorageBinType AS CellType,
	|	StorageBins.Owner AS Warehouse,
	|	ISNULL(StorageBins.Owner.Presentation, """") AS NameOfTheWarehouse
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	NOT StorageBins.IsFolder
	|	AND NOT StorageBins.DeletionMark
	|	AND StorageBins.Owner = &Warehouse
	|	AND StorageBins.Premise = &Premise";
	
	Result = Query.Execute();
	ReceivingShippingAreas = Result.Unload();
	
	Return ReceivingShippingAreas;
	
EndFunction

// Searches for a cell in the barcode.
//
// Parameters:
//	Warehouse           - CatalogRef.Warehouses - warehouse.
//	Premise       - CatalogRef.Warerooms - warehouse premises.
//	CellBarcode  - String - barcode of the cell.
//	ThisIsScan - Boolean - True if the cell address barcode value is received via the TSD.
//
// Returns:
//	Structure - parameters of the cell that contains the fields:
//		* ReturnCode - Number - 1, if the cell is found. 0 If the cell is not found.
//		* Cell - CatalogRef.StorageBins - found cell.
//		* CellType - EnumRef.TypesOfStorageCells - type of storage cell.
//		* CellCode - String- cell code.
//		* CellBarcode - String - barcode of the cell.
//
Function FindCellByBarcode(Warehouse, Premise, CellBarcode, ThisIsScan = False) Export
	
	ObjectsManagers = New Array();
	ObjectsManagers.Add(Catalogs.StorageBins.EmptyRef());
	
	If ThisIsScan Then
		ReferencesArrray = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(CellBarcode,
			ObjectsManagers);
	Else
		ReferencesArrray = New Array;
	EndIf;
	
	If ReferencesArrray.Count() = 0 Then
		Return FindCellByCode(Warehouse, Premise, CellBarcode);
	Else
		
		CellParameters_ = New Structure;
		CellDetails = Common.ObjectAttributesValues(ReferencesArrray[0], "Code, StorageBinType, IsFolder");
		
		If CellDetails.IsFolder Then
			CellParameters_.Insert("ReturnCode", 0);
			Return CellParameters_;
		Else
			CellParameters_.Insert("ReturnCode", 1);
			CellParameters_.Insert("Cell", ReferencesArrray[0]);
			CellParameters_.Insert("CellType", CellDetails.StorageBinType);
			CellParameters_.Insert("CellCode", CellDetails.Code);
			CellParameters_.Insert("CellBarcode", CellBarcode);
			
			Return CellParameters_;
		EndIf;
		
	EndIf;
	
EndFunction

// Searches for a cell by code.
//
// Parameters:
//	Warehouse - CatalogRef.Warehouses - warehouse.
//	Premise - CatalogRef - warehouse premises.
//	CellCode - String - cell code.
//
// Returns:
//	Structure - parameters of the cell that contains the fields:
//		* ReturnCode - Number - 1, if the cell is found. 0 If the cell is not found.
//		* Cell - CatalogRef.StorageBins - found cell.
//		* CellType - EnumRef.TypesOfStorageCells - type of storage cell.
//		* CellCode - String- cell code.
//		* CellBarcode - String - barcode of the cell.
//
Function FindCellByCode(Warehouse, Premise, CellCode) Export
	
	CellParameters_ = New Structure("ReturnCode", 1);
	CellParameters_.Insert("Cell", Catalogs.StorageBins.EmptyRef());
	CellParameters_.Insert("CellType", Enums.TypesOfStorageCells.EmptyRef());
	CellParameters_.Insert("CellCode", CellCode);
	CellParameters_.Insert("CellBarcode", "");
	
	Query = New Query;
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Code", CellCode);
	
	Query.Text =
	"SELECT TOP 1
	|	StorageBins.Ref AS Cell,
	|	StorageBins.StorageBinType,
	|	StorageBins.Code AS CellCode,
	|	StorageBins.IsFolder AS IsFolder
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	StorageBins.Owner = &Warehouse
	|	AND StorageBins.Code = &Code
	|	AND StorageBins.Premise = &Premise";
	
	QueryResult = Query.Execute();
	CellTable = QueryResult.Unload();
	
	If CellTable.Count() = 0 Then
		CellParameters_.ReturnCode = 0;
		Return CellParameters_;
	Else
		
		If CellTable[0].IsFolder Then
			CellParameters_.ReturnCode = 0;
			Return CellParameters_;
		Else
			CellParameters_.Cell = CellTable[0].Cell;
			CellParameters_.CellType = CellTable[0].StorageBinType;
			CellParameters_.CellBarcode = BarcodingOfPrintForms.NumericCodeFromLink(CellTable[0].Cell);
			Return CellParameters_;
		EndIf;
		
	EndIf;
	
EndFunction

// Returns a table of products stored in the cell.
//
// Parameters:
//	Warehouse - CatalogRef.Warerooms - warehouse.
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	Cell - CatalogRef.StorageBins - cell.
//
// Returns:
//	ValueTable - the table of goods stored in the cell contains columns:
//		* Products - CatalogRef.Products - product.
//		* ItemName - String - name of goods.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//		* ItemVariantName - String - product name and characteristics.
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure - packing;.
//		* PackageName - String - name of the product packaging.
//		* Series - CatalogRef.ItemsBatches - product series.
//		* BatchName - String - presentation of the product series.
//		* Count - Number - amount of goods.
//
Function CellGoods(Warehouse, Premise, Cell) Export
	
	Query = New Query;
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Cell", Cell);
	
	Query.Text =
	"SELECT
	|	GoodsInStorageBinsBalance.Products AS Products,
	|	ISNULL(GoodsInStorageBinsBalance.Products.Presentation, """") AS ItemName,
	|	GoodsInStorageBinsBalance.Characteristic AS Characteristic,
	|	ISNULL(GoodsInStorageBinsBalance.Characteristic.Presentation, """") AS ItemVariantName,
	|	GoodsInStorageBinsBalance.Package,
	|	ISNULL(GoodsInStorageBinsBalance.Package.Presentation, """") AS PackageName,
	|	GoodsInStorageBinsBalance.Series AS Series,
	|	ISNULL(GoodsInStorageBinsBalance.Series.Presentation, """") AS BatchName,
	|	GoodsInStorageBinsBalance.Products.UnitOfMeasure AS UnitOfMeasure,
	|	ISNULL(GoodsInStorageBinsBalance.Products.UnitOfMeasure.Presentation, """") AS UnitOfMeasureDescription,
	|	ISNULL(GoodsInStorageBinsBalance.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)) AS MeasuredValueType,
	|	GoodsInStorageBinsBalance.InStockBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(
	|			,
	|			Cell.Owner = &Warehouse
	|				AND Cell.Premise = &Premise
	|				AND Cell = &Cell) AS GoodsInStorageBinsBalance
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	GoodsInStorageBinsBalance.Package";
	
	Result = Query.Execute();
	CellGoods = Result.Unload();
	
	Return CellGoods;
	
EndFunction

// Marks the cell to be recalculated in the data register as"state_counter".
//
// Parameters:
//	Cell - CatalogRef.StorageBins - cell.
//
Procedure MarkABinForRecount(Cell) Export
	
	Query = New Query;
	Query.SetParameter("Cell", Cell);
	
	Query.Text =
	"SELECT
	|	BinRecountStates.Cell,
	|	BinRecountStates.State,
	|	BinRecountStates.LastRecalculationDate
	|FROM
	|	InformationRegister.BinRecountStates AS BinRecountStates
	|WHERE
	|	BinRecountStates.Cell = &Cell
	|	AND BinRecountStates.State = VALUE(Enum.BinRecountStates.RecalculationIsCompleted)";
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	CellStateForRecalculation = InformationRegisters.BinRecountStates.CreateRecordSet();
	CellStateForRecalculation.Filter.Cell.Set(Cell);
	CellStateForRecalculation.Read();
	
	SetPrivilegedMode(True);
	
	If Selection.Count() = 0 Then
		If CellStateForRecalculation.Count() = 0 Then
			NewState = CellStateForRecalculation.Add();
			
			NewState.Cell = Cell;
			NewState.State = Enums.BinRecountStates.RecountIsRequired;
			
			CellStateForRecalculation.Write();
		EndIf;
	Else
		For Each SetRecord In CellStateForRecalculation Do
			SetRecord.Cell = Cell;
			SetRecord.State = Enums.BinRecountStates.RecountIsRequired;
		EndDo;
		
		CellStateForRecalculation.Write();
	EndIf;
	
EndProcedure

// Searches for entries in the register of information "of Strikodynarad" at the specified barcode.
//
// Parameters:
//	Barcode - String - the barcode of the product.
//	SearchForPackingLists - Boolean - True - the barcode is searched among the packing lists, False - no.
//
// Returns:
//	See ProductParameters_1
//
Function FindProductOrPackingList(Barcode, SearchForPackingLists) Export
	
	ProductParameters_1 = ProductParameters_1();
	Barcode = Upper(TrimAll(Barcode));
	ProductParameters_1.Barcode = Barcode;
	
	// Get barcode data 
	ArrayOfBarcodes = New Array();
	ArrayOfBarcodes.Add(Barcode);
	
	Cached_Values = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	InformationRegisters.ItemsBarcodes.GetBarcodeData(Cached_Values, ArrayOfBarcodes);
	
	If ProductNotFound_(Barcode, Cached_Values.Barcodes)
		And SearchForPackingLists Then
		
		Documents.PackingList.AddDataOnBarcodes(Cached_Values, ArrayOfBarcodes);
		
	EndIf;
		
	If ProductNotFound_(Barcode, Cached_Values.Barcodes) Then
		ProductParameters_1.ReturnCode = 0;
		ProductParameters_1.ErrorType = "ProductNotFound";
		ProductParameters_1.MessageText = NStr("vi = 'Mã vạch không xác định';
												|ru = 'Неизвестный штрихкод.';
												|en = 'Unknown barcode.'; fa = 'Unknown barcode.';
												|it = 'Codice a barre sconosciuto.';
												|pl = 'Nieznany kod kreskowy.';
												|tr = 'Bilinmeyen barkod.'");
		
		Return ProductParameters_1;
	EndIf;
	
	ProductBarcodeData = Cached_Values.Barcodes.Get(Barcode);
	FillPropertyValues(ProductParameters_1, ProductBarcodeData);
	
	If ValueIsFilled(ProductBarcodeData.PackingList) Then
		ProductParameters_1.ThisIsAPackingList = True;
		Return ProductParameters_1;
	EndIf;
	
	// Get additional information about the product range.
	ProductAttributes = Common.ObjectAttributesValues(ProductBarcodeData.Products,
		"Description, ProductKind, LongDesc, SKU, WeightUnitOfMeasure, VolumeUnitOfMeasure");
	FillPropertyValues(ProductParameters_1, ProductAttributes);
	
	ProductParameters_1.ProductIDOfItems = ProductAttributes.SKU;
	ProductParameters_1.ItemsDescription = ProductAttributes.LongDesc;
	ProductParameters_1.ItemName = ProductAttributes.Description;
	
	ProductParameters_1.UnitOfMeasureForWeight = ProductAttributes.WeightUnitOfMeasure;
	ProductParameters_1.UnitOfMeasureForVolume = ProductAttributes.VolumeUnitOfMeasure;
	
	SeriesParameters_ = Catalogs.ItemKinds.SeriesUseSettings(ProductParameters_1.ProductKind);
	FillPropertyValues(ProductParameters_1, SeriesParameters_);
	
	DetailsOfUnitOfMeasurement = Common.ObjectAttributesValues(ProductParameters_1.UnitOfMeasure,
		"MeasuredValueType");
	FillPropertyValues(ProductParameters_1, DetailsOfUnitOfMeasurement);
	
	If ProductParameters_1.ItemsType = Enums.ItemsTypes.ReusablePackage Then
		Return ProductParameters_1; // the container has no packages
	EndIf;
	
	// Get more information about the product packaging.
	If Not ValueIsFilled(ProductBarcodeData.Package) Then
		
		// Options:
		// - several single packages are a mistake, it is unclear what to do;
		// - one single package.
		If ProductBarcodeData.MultipleUnitPackages Then
			ProductParameters_1.ReturnCode = 0;
			ProductParameters_1.ErrorType = "PackagingIsNotLinkedToBarcode";
			ProductParameters_1.MessageText = NStr("vi = 'Sản phẩm không được chỉ định bao bì.';
													|ru = 'У товара не указана упаковка.';
													|en = 'Goods packaging unit is not specified.'; fa = 'Goods packaging unit is not specified.';
													|it = 'Non è indicato l''imballaggio della merce.';
													|pl = 'Dla towaru nie podano opakowanie.';
													|tr = 'Ürünün paketleme ünitesi belirtilmedi.'");
			
			Return ProductParameters_1;
		Else
			// If there is one single package, then you need to check that it is there at all.
			If Not ValueIsFilled(ProductBarcodeData.SinglePackaging)
				And Not (ProductParameters_1.MeasuredValueType = Enums.TypesOfMeasuredValues.Weight
					Or ProductParameters_1.MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3
					Or ProductParameters_1.MeasuredValueType = Enums.TypesOfMeasuredValues.Length
					Or ProductParameters_1.MeasuredValueType = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement) Then
				
				ProductParameters_1.ReturnCode = 0;
				ProductParameters_1.ErrorType = "PackagingIsNotLinkedToBarcode";
				ProductParameters_1.MessageText = NStr("vi = 'Sản phẩm không được chỉ định bao bì.';
														|ru = 'У товара не указана упаковка.';
														|en = 'Goods packaging unit is not specified.'; fa = 'Goods packaging unit is not specified.';
														|it = 'Non è indicato l''imballaggio della merce.';
														|pl = 'Dla towaru nie podano opakowanie.';
														|tr = 'Ürünün paketleme ünitesi belirtilmedi.'");
				
				Return ProductParameters_1;
				
			ElsIf (ProductParameters_1.MeasuredValueType = Enums.TypesOfMeasuredValues.Weight)
				Or (ProductParameters_1.MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3)
				Or (ProductParameters_1.MeasuredValueType = Enums.TypesOfMeasuredValues.Length)
				Or (ProductParameters_1.MeasuredValueType = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement) Then
				
				GoodsPackaging = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				
			Else
				GoodsPackaging = ProductBarcodeData.SinglePackaging;
			EndIf;
		EndIf;
		
	Else
		GoodsPackaging = ProductBarcodeData.Package;
	EndIf;
	
	// Get the values of the packaging details.
	PackingDetails = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(GoodsPackaging,
		ProductBarcodeData.Products,, False);
	
	ProductParameters_1.Package = GoodsPackaging;
	ProductParameters_1.PackageWeight = PackingDetails.Weight;
	ProductParameters_1.PackageVolume = PackingDetails.VolumeM3;
	ProductParameters_1.ZoomRatio = PackingDetails.ZoomRatio;
	
	// Get the values of the coefficients of the units of measurement of the weight and volume of the item.
	ProductParameters_1.FactorOfWeightUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(ProductParameters_1.UnitOfMeasureForWeight,
		ProductParameters_1.Products);
	ProductParameters_1.FactorOfVolumeUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
		ProductParameters_1.UnitOfMeasureForVolume, ProductParameters_1.Products);
	
	Return ProductParameters_1;
	
EndFunction

// Returns a structure with service information about the product.
//
// Parameters:
//	Warehouse - CatalogRef.Warerooms - warehouse.
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	ProductParameters_1 - Structure - product data.
//
// Returns:
//	Structure:
//		* ProductPicture_ - BinaryData,Undefined - the picture of the product.
//		* ProductResidues - ValueTable - data on the Balance of Goods in the cells in the warehouse:
//		**Products - CatalogRef.Products
//		**ItemName - String
//		**Characteristic - CatalogRef.ItemsCharacteristics
//		**ItemVariantName - String
//		**Package - CatalogRef.PackagesAndUnitsOfMeasure
//		**PackageName - String
//		**Series - CatalogRef.ItemsBatches
//		**BatchName - String
//		**Count - Number
//		**Cell - CatalogRef.StorageBins
//		**CellCode - String
//
Function GoodsInformation(Warehouse, Premise, ProductParameters_1) Export
	
	GoodsInformation = New Structure("ProductPicture_, ProductResidues");
	
	// If there is a picture of the product, then display it.
	PicturesFile = Common.ObjectAttributeValue(ProductParameters_1.Products, "PicturesFile");
	
	If ValueIsFilled(PicturesFile) Then
		PictureParameters = FilesOperations.FileData(PicturesFile);
		Picture = GetFromTempStorage(PictureParameters.RefToBinaryFileData);
		
		GoodsInformation.ProductPicture_ = Picture;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsInStorageBinsBalance.Products AS Products,
	|	GoodsInStorageBinsBalance.Products.Presentation AS ItemName,
	|	GoodsInStorageBinsBalance.Characteristic AS Characteristic,
	|	ISNULL(GoodsInStorageBinsBalance.Characteristic.Presentation, """") AS ItemVariantName,
	|	CASE
	|		WHEN GoodsInStorageBinsBalance.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN ISNULL(GoodsInStorageBinsBalance.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|		ELSE GoodsInStorageBinsBalance.Package
	|	END AS Package,
	|	CASE
	|		WHEN GoodsInStorageBinsBalance.Package.Presentation IS NULL 
	|			THEN ISNULL(GoodsInStorageBinsBalance.Products.UnitOfMeasure.Presentation, """")
	|		ELSE GoodsInStorageBinsBalance.Package.Presentation
	|	END AS PackageName,
	|	GoodsInStorageBinsBalance.Cell AS Cell,
	|	ISNULL(GoodsInStorageBinsBalance.Cell.Code, """") AS CellCode,
	|	GoodsInStorageBinsBalance.Series AS Series,
	|	ISNULL(GoodsInStorageBinsBalance.Series.Presentation, """") AS BatchName,
	|	GoodsInStorageBinsBalance.InStockBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(
	|			,
	|			Cell.Owner = &Warehouse
	|				AND Cell.Premise = &Premise
	|				AND Products = &Products
	|				AND Characteristic = &Characteristic
	|				AND Package = &Package) AS GoodsInStorageBinsBalance
	|
	|ORDER BY
	|	Cell,
	|	GoodsInStorageBinsBalance.InStockBalance";
		
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Products", ProductParameters_1.Products);
	Query.SetParameter("Package", ProductParameters_1.Package);
	Query.SetParameter("Characteristic", ProductParameters_1.Characteristic);
	
	Result = Query.Execute();
	ProductResidues = Result.Unload();	// ValueTable
	
	GoodsInformation.ProductResidues = ProductResidues;
	
	Return GoodsInformation;
	
EndFunction

// Searches for the specified packing list among the scanned documents.
//
// Parameters:
//	PackingList - DocumentRef.PackingList - link to the packing list
//	ScannedPackingSheets - Array of DocumentRef.PackingList - 
//			an array of links to previously scanned packing lists.
//
// Returns:
//	Boolean - True if the packing list is found among the previously scanned ones.
//
Function PackingListScanned(PackingList, ScannedPackingSheets) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	1 AS Field1
	|FROM
	|	Document.PackingList.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.ThisIsAPackingList
	|	AND Goods.PackingList IN (&ScannedPackingSheets)";
	
	Query.SetParameter("Ref", PackingList);
	Query.SetParameter("ScannedPackingSheets", ScannedPackingSheets);
	
	If Not Query.Execute().IsEmpty() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Searches for an item series by the specified number and expiration date.
//
// Parameters:
//	BatchNumber - String - serial number.
//	SeriesShelfLife - Date - shelf life of the series.
//	ProductKind - CatalogRef.ItemKinds - type of item.
//	SeriesIndicationParameters - Structure - parameters for specifying a series.
//	ThisIsScan - Boolean - True if the barcode of the series of items is entered manually.
//
// Returns:
//	See SeriesParameters
//
Function FindSeries_(BatchNumber, SeriesShelfLife, ProductKind, SeriesIndicationParameters,
		ThisIsScan = Undefined) Export
	
	Var ExpirationDate_;
	
	BatchNumber = TrimAll(BatchNumber);
	SeriesParameters = SeriesParameters();
	
	If ThisIsScan <> Undefined Then
		
		If ThisIsScan Then
			
			If ValueIsFilled(SeriesShelfLife) Then
				
				If Not ShelfLifeOfSeriesIsCorrect(SeriesIndicationParameters, SeriesShelfLife, ExpirationDate_) Then
					SeriesParameters.ReturnCode = 0;
					SeriesParameters.MessageText = NStr("vi = 'Lỗi: đã quét không phải sê-ri.';
														|ru = 'Ошибка: отсканирована не та серия.';
														|en = 'Error: the wrong batch is scanned.'; fa = 'Error: the wrong batch is scanned.';
														|it = 'Errore: scannerizzata la serie sbagliata.';
														|pl = 'Błąd: została zeskanowana nie ta seria.';
														|tr = 'Hata: yanlış parti tarandı.'");
					Return SeriesParameters;
				EndIf;
				
				SeriesParameters.BatchNumber = BatchNumber;
				SeriesParameters.ValidUntil_ = ExpirationDate_;
				
			Else
				SeriesParameters.BatchNumber = BatchNumber;
				SeriesParameters.ValidUntil_ = Date("00010101");
			EndIf;
			
		Else
			
			SeriesInformation = SeriesInformationFromBarcode(BatchNumber, SeriesIndicationParameters.SpecifyNumberWhenRegisteringBatch,
				SeriesIndicationParameters.UseShelfLifeOnBatchRegistration);
			
			If SeriesInformation.HasError Then
				SeriesParameters.ReturnCode = 0;
				SeriesParameters.MessageText = NStr("vi = 'Lỗi: đã quét không phải sê-ri.';
													|ru = 'Ошибка: отсканирована не та серия.';
													|en = 'Error: the wrong batch is scanned.'; fa = 'Error: the wrong batch is scanned.';
													|it = 'Errore: scannerizzata la serie sbagliata.';
													|pl = 'Błąd: została zeskanowana nie ta seria.';
													|tr = 'Hata: yanlış parti tarandı.'");
				Return SeriesParameters;
			Else
				SeriesParameters.BatchNumber = SeriesInformation.Number;
				SeriesParameters.ValidUntil_ = SeriesInformation.ValidUntil_
			EndIf;
			
		EndIf;
		
	Else
		
		SeriesParameters.BatchNumber = BatchNumber;
		SeriesParameters.ValidUntil_ = SeriesShelfLife;
		
	EndIf;
	
	Query = New Query;
	QueryText = 
	"SELECT TOP 1
	|	ItemsBatches.Ref AS Series
	|FROM
	|	Catalog.ItemsBatches AS ItemsBatches
	|WHERE
	|	ItemsBatches.ProductKind = &ProductKind";
	
	// Depending on the composition of the series key, the text of the request condition will vary.
	If SeriesIndicationParameters.SpecifyNumberWhenRegisteringBatch
		And Not SeriesIndicationParameters.UseShelfLifeOnBatchRegistration Then
		
		ConditionText = "
		|AND ItemsBatches.Number = &BatchNumber";
		
		Query.SetParameter("BatchNumber", SeriesParameters.BatchNumber);
		
	ElsIf SeriesIndicationParameters.SpecifyNumberWhenRegisteringBatch 
		And SeriesIndicationParameters.UseShelfLifeOnBatchRegistration Then
		
		ConditionText = "
		|AND ItemsBatches.Number = &BatchNumber
		|AND ItemsBatches.ValidUntil_ = &ValidUntil_";
		
		Query.SetParameter("BatchNumber", SeriesParameters.BatchNumber);
		Query.SetParameter("ValidUntil_", SeriesParameters.ValidUntil_);
		
	ElsIf Not SeriesIndicationParameters.SpecifyNumberWhenRegisteringBatch 
		And SeriesIndicationParameters.UseShelfLifeOnBatchRegistration Then
		
		ConditionText = "
		|AND ItemsBatches.ValidUntil_ = &ValidUntil_";
		
		Query.SetParameter("ValidUntil_", SeriesParameters.ValidUntil_);
		
	EndIf;
	
	Query.Text = QueryText + ConditionText;
	Query.SetParameter("ProductKind", ProductKind);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		SeriesParameters.ReturnCode = 0;
		SeriesParameters.MessageText = NStr("vi = 'Lỗi: đã quét không phải sê-ri.';
											|ru = 'Ошибка: отсканирована не та серия.';
											|en = 'Error: the wrong batch is scanned.'; fa = 'Error: the wrong batch is scanned.';
											|it = 'Errore: scannerizzata la serie sbagliata.';
											|pl = 'Błąd: została zeskanowana nie ta seria.';
											|tr = 'Hata: yanlış parti tarandı.'");
		Return SeriesParameters;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	SeriesParameters.Series = Selection.Series;
	
	Return SeriesParameters;
	
EndFunction

// Retrieves information about the number and expiration date from the barcode.
// Only works for barcodes generated by the barcode printing process and
// serial numbers generated by the serial registration form.
//
// Parameters:
//	BarcodeSeries - String - barcode to extract information from,
//	SpecifyNumberWhenRegisteringBatch - Boolean - indicates that a number is used for the series whose barcode was transmitted,
//	UseShelfLifeOnBatchRegistration - Boolean - indicates that a number is used for the series whose barcode is transmitted.
//
// Returns:
//	See BarcodingOfItemsServer.SeriesInformationFromBarcode.
//
Function SeriesInformationFromBarcode(BarcodeSeries, SpecifyNumberWhenRegisteringBatch, UseShelfLifeOnBatchRegistration) Export
	
	InformationFromBarcodeSeries = BarcodingOfItemsServer.SeriesInformationFromBarcode(
									BarcodeSeries,
									SpecifyNumberWhenRegisteringBatch,
									UseShelfLifeOnBatchRegistration);
	
	GetUserMessages(True);
	
	Return InformationFromBarcodeSeries;
	
EndFunction

// Selects the destination for the product.
//
// Parameters:
//	Warehouse - CatalogRef.Warerooms - the warehouse where you search for destinations for the specified product.
//	ReferenceOrder - DocumentRef - link to the order document.
//	Cell - CatalogRef.StorageBins - a cell that searches for destinations for the specified product.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//	DocumentGoods - ValueTable - table of products in the warehouse task document.
//	ModeSettings - Structure - parameters of the working mode of the warehouse employee's workplace.
//
// Returns:
//	CatalogRef.Assignments - the selected destination for the specified product.
//
Function SelectAppointment(Warehouse, ReferenceOrder, Cell, OwnGoods, DocumentGoods, ModeSettings) Export
	
	Assignments = Assignments(Warehouse, ReferenceOrder, Cell, OwnGoods, DocumentGoods, ModeSettings, True);
	
	If Assignments.Columns.Find("Products") = Undefined Then
		TypeProducts = New TypeDescription("CatalogRef.Products");
		TypeOfProductCharacteristics = New TypeDescription("CatalogRef.ItemsCharacteristics");
		
		Assignments.Columns.Add("Products", TypeProducts);
		Assignments.Columns.Add("Characteristic", TypeOfProductCharacteristics);
		
		Assignments.FillValues(OwnGoods.Products, "Products");
		Assignments.FillValues(OwnGoods.Characteristic, "Characteristic");
	EndIf;
	
	Filter = New Structure("Products, Characteristic, Package");
	FillPropertyValues(Filter, OwnGoods);
	
	RowsArray = DocumentGoods.FindRows(Filter);
	
	DataIsWH = (RowsArray.Count() > 0);
	
	If ValueIsFilled(OwnGoods.Package) Then
		QuantityToAdd = OwnGoods.ZoomRatio;
	Else
		QuantityToAdd = 1;
	EndIf;
	
	Purpose = BarcodingOfItemsServer.SelectAppointment(OwnGoods, Assignments, "Count", RowsArray,
		QuantityToAdd, DataIsWH);
	
	Return Purpose;
	
EndFunction

// Returns the assignment table, according to the specified parameters.
//
// Parameters:
//	Warehouse - CatalogRef.Warerooms - the warehouse where you search for destinations for the specified product.
//	ReferenceOrder - DocumentRef - link to the order document.
//	Cell - CatalogRef.StorageBins - a cell that searches for destinations for the specified product.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//	DocumentGoods - ValueTable - table of products in the warehouse task document.
//	ModeSettings - Structure - parameters of the working mode of the warehouse employee's workplace.
//	ForAutoSelection - Boolean - True if the destination is selected automatically.
//
// Returns:
//	ValueTable - assignment table.
//
Function Assignments(Warehouse, ReferenceOrder, Cell, OwnGoods, DocumentGoods, ModeSettings, ForAutoSelection = False) Export
	
	Job = ModeSettings.Job;
	JobType = ModeSettings.JobType;
	ReceivingArea = ModeSettings.ReceivingArea;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	SelectionScanned = ModeSettings.SelectionScanned;
	
	Query = New Query();
	
	RequestTextParameters = Catalogs.Assignments.ParametersForCreatingRequestForAvailableAssignments();
	
	RequestTextParameters.TakeIntoAccountAlreadySelected = True;
	RequestTextParameters.SortByDateOfAppointmentOrder = True;
	
	If JobType = "PickingCheck"
		And Not ForAutoSelection Then
		Query.Text = DataProcessors.GoodsQuantityCheckInDocument.RequestTextForAvailableAssignments(RequestTextParameters);
	Else
		
		If JobType = "Recalculate" Then
			If ForAutoSelection Then
				RequestTextParameters.ChoiceMode = "ByBalancesInCell";
				Query.SetParameter("Cell", Cell);
			Else
				// We will unload all unsecured assignments
				Query.SetParameter("IncludeGiverOrders", True);
			EndIf;
		ElsIf JobType = "Location" Then
			RequestTextParameters.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location;
			Query.SetParameter("Cell", ReceivingArea);
			
			If Not ValueIsFilled(Job) Then
				Job = Documents.GoodsPickingPlacement.EmptyRef();
			EndIf;
		ElsIf JobType = "Filter" Then
			RequestTextParameters.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter;
			Query.SetParameter("Cell", Cell);
		ElsIf JobType = "Move" Then
			If Not SelectionScanned Then
				RequestTextParameters.ChoiceMode = "ResiduesInCell";
				Query.SetParameter("Cell", Cell);
			EndIf;
			
			RequestTextParameters.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move;
		Else
			Query.SetParameter("ByAllReferences", True);
		EndIf;
		
		Query.Text =
			Common.ObjectManagerByRef(Job).RequestTextForAvailableAssignments(RequestTextParameters);
			
	EndIf;
	
	Query.SetParameter("Products", OwnGoods.Products);
	Query.SetParameter("Characteristic", OwnGoods.Characteristic);
	
	Query.SetParameter("ThisIsWork", False);
	Query.SetParameter("Purpose", OwnGoods.Purpose);
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Department", Catalogs.BusinessStructure.EmptyRef());
	
	Query.SetParameter("DocumentGoods", DocumentGoods);
	
	Query.SetParameter("Recorder", Job);
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	If (JobType = "Recalculate"
			Or JobType = "PickingCheck")
		And ForAutoSelection Then
		
		For Each ResultString1 In Result Do
			ResultString1.Balance = ResultString1.Demand;
		EndDo;
		
	EndIf;
	
	If (JobType = "Recalculate"
			Or JobType = "PickingCheck")
		And Not ForAutoSelection Then
		// The details of the "Destination" are not displayed
	Else
		DeleteEmptyRows = ThisIsSetOfGoods
								And (JobType = "Location");
		
		RecalculateBalancesByDestination(Result, OwnGoods, DeleteEmptyRows);
	EndIf;
	
	Return Result;
	
EndFunction

// Called when the selection of items is completed when the move task is completed.
// When you move can be selected only part of the goods when placing the goods
// should be issued for processing only a selected portion of the goods.
//
// Parameters:
//	Job - DocumentRef - warehouse task link,
//	GoodsForScanning - ValueTable - a product table that corresponds to the table part of the task being performed
//											and contains information about scanned products.
//											Recalculation operations store the original information about the goods in the document "recalculation of Goods".
//	VTScannedProducts - ValueTable - a table of products that contains information about scanned products
//												whose series indication status is set to'after-selection'.
//
// Returns:
//	See JobParameters
//
Function ProcessScannedGoodsForMoving(Job, GoodsForScanning, VTScannedProducts) Export
	
	JobType = JobType(Job);
	
	JobParameters = JobParameters();
	JobParameters.JobType = JobType;
	
	SetTaskItems(Job, JobParameters);
	FillInStatusesForSpecifyingSeries(Job, JobParameters);
	
	GoodsFilter = JobParameters.GoodsFilter;
	
	ArrayOfProducts_2 = New Array;
	ArrayOfTaskProducts = GoodsFilter.UnloadColumn("Products");
	
	CommonClientServer.SupplementArray(ArrayOfProducts_2, ArrayOfTaskProducts, True);
	
	// We set the values of the props "Status Designationseries"
	For Each TaskItem_ In ArrayOfProducts_2 Do
		
		Filter = New Structure("Products", TaskItem_);
		
		RowsArray = GoodsForScanning.FindRows(Filter);
		BatchesIndicationStatus = RowsArray[0].BatchesIndicationStatus;
		
		ArrayOfSelectionStrings = GoodsFilter.FindRows(Filter);
		For Each FIlterRow In ArrayOfSelectionStrings Do
			FIlterRow.BatchesIndicationStatus = BatchesIndicationStatus;
		EndDo;
		
	EndDo;
	
	If VTScannedProducts <> Undefined Then
		VTScannedProducts.GroupBy("Cell, Products, Characteristic, Purpose, Package, ZoomRatio, Series,
			|BatchNumber, ValidUntil_", "NumberOfPackagingsScanned");
	EndIf;
	
	Filter = New Structure("Cell, Products, Characteristic, Purpose, BatchNumber, ValidUntil_, Package");
	SelectionWithoutSeries = New Structure("Cell, Products, Characteristic, Purpose, Package");
	
	For Each LineProductsToScan In GoodsForScanning Do
		
		NumberOfPackagingsScanned = LineProductsToScan.NumberOfPackagingsScanned;
		
		If LineProductsToScan.ZoomRatio <> 0 Then
			QuantityScanned = NumberOfPackagingsScanned * LineProductsToScan.ZoomRatio;
		Else
			QuantityScanned = NumberOfPackagingsScanned;
		EndIf;
		
		If NumberOfPackagingsScanned = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(Filter, LineProductsToScan);
		FillPropertyValues(SelectionWithoutSeries, LineProductsToScan);
		
		ArrayOfProductLines = GoodsFilter.FindRows(Filter);
		If ArrayOfProductLines.Count() = 0 Then
			
			NewLineProductsSelection = GoodsFilter.Add();
			FillPropertyValues(NewLineProductsSelection, LineProductsToScan);
			
			NewLineProductsSelection.NumberOfPackages = NumberOfPackagingsScanned;
			NewLineProductsSelection.NumberOfPackagesPicked = NumberOfPackagingsScanned;
			NewLineProductsSelection.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
			
			NewLineProductsSelection.Count = QuantityScanned;
			NewLineProductsSelection.CountPicked = QuantityScanned;
			
			Continue;
			
		Else
			LineProductsSelection = ArrayOfProductLines[0];
		EndIf;
		
		If SeriesAreIndicatedUponSelection(LineProductsToScan.BatchesIndicationStatus)
			And (VTScannedProducts <> Undefined)Then
			
			ArrayOfRowsScannedProducts = VTScannedProducts.FindRows(SelectionWithoutSeries);
			
			If ArrayOfRowsScannedProducts.Count() > 0 Then
				FirstRow = ArrayOfRowsScannedProducts[0];
			EndIf;
			
			For Each ScannedProductsLine In ArrayOfRowsScannedProducts Do
				
				If ScannedProductsLine = FirstRow Then
					
					NumberOfScans = FirstRow.NumberOfPackagingsScanned;
					If ArrayOfRowsScannedProducts.Count() > 0 Then
						
						NumberOfScans = 0;
						For Each ProductLineBySeries In ArrayOfRowsScannedProducts Do
							NumberOfScans = NumberOfScans + ProductLineBySeries.NumberOfPackagingsScanned;
						EndDo;
						
					EndIf;
					
					NumberOfScans = NumberOfScans - FirstRow.NumberOfPackagingsScanned;
					NumberOfPackagingsScanned = LineProductsToScan.NumberOfPackagingsScanned
						- NumberOfScans;
					
					If LineProductsToScan.ZoomRatio <> 0 Then
						QuantityScanned = NumberOfPackagingsScanned * LineProductsToScan.ZoomRatio;
					Else
						QuantityScanned = NumberOfPackagingsScanned;
					EndIf;
					
				Else
					NumberOfPackagingsScanned = ScannedProductsLine.NumberOfPackagingsScanned;
					
					If LineProductsToScan.ZoomRatio <> 0 Then
						QuantityScanned = NumberOfPackagingsScanned * LineProductsToScan.ZoomRatio;
					Else
						QuantityScanned = NumberOfPackagingsScanned;
					EndIf;
				EndIf;
				
				NewLineProductsSelection = GoodsFilter.Add();
				FillPropertyValues(NewLineProductsSelection, LineProductsSelection);
				
				NewLineProductsSelection.Series = ScannedProductsLine.Series;
				NewLineProductsSelection.BatchNumber = ScannedProductsLine.BatchNumber;
				NewLineProductsSelection.ValidUntil_ = ScannedProductsLine.ValidUntil_;
				
				NewLineProductsSelection.NumberOfPackages = NumberOfPackagingsScanned;
				NewLineProductsSelection.NumberOfPackagesPicked = NumberOfPackagingsScanned;
				NewLineProductsSelection.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
				
				NewLineProductsSelection.Count = QuantityScanned;
				NewLineProductsSelection.CountPicked = QuantityScanned;
				NewLineProductsSelection.BatchesIndicationStatus = LineProductsToScan.BatchesIndicationStatus;
				
			EndDo;
			
			RemainingPackagesToScan = LineProductsToScan.NumberOfPackages
				- LineProductsToScan.NumberOfPackagingsScanned;
			
			If LineProductsToScan.ZoomRatio <> 0 Then
				ItRemainsToScan = RemainingPackagesToScan * LineProductsToScan.ZoomRatio;
			Else
				ItRemainsToScan = RemainingPackagesToScan;
			EndIf;
			
			If RemainingPackagesToScan <= 0 Then
				GoodsFilter.Delete(LineProductsSelection);
			Else
				LineProductsSelection.NumberOfPackages = RemainingPackagesToScan;
				LineProductsSelection.Count = ItRemainsToScan;
			EndIf;
			
		Else
			
			If SeriesAreIndicatedUponSelection(LineProductsToScan.BatchesIndicationStatus) Then
				
				If ValueIsFilled(LineProductsToScan.BatchNumber)
					Or ValueIsFilled(LineProductsToScan.ValidUntil_) Then
					
					// Add a line of selected products.
					NewLineProductsSelection = GoodsFilter.Add();
					FillPropertyValues(NewLineProductsSelection, LineProductsSelection);
					
					NewLineProductsSelection.BatchNumber = LineProductsToScan.BatchNumber;
					NewLineProductsSelection.ValidUntil_ = LineProductsToScan.ValidUntil_;
					
					NewLineProductsSelection.NumberOfPackages = NumberOfPackagingsScanned;
					NewLineProductsSelection.NumberOfPackagesPicked = NumberOfPackagingsScanned;
					NewLineProductsSelection.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
					
					NewLineProductsSelection.Count = QuantityScanned;
					NewLineProductsSelection.CountPicked = QuantityScanned;
					NewLineProductsSelection.BatchesIndicationStatus = LineProductsToScan.BatchesIndicationStatus;
					
				Else
					LineProductsSelection.Count = LineProductsToScan.NumberOfPackages *
						LineProductsToScan.ZoomRatio;
					LineProductsSelection.NumberOfPackages = LineProductsToScan.NumberOfPackages;
					LineProductsSelection.NumberOfPackagesInDocument = LineProductsToScan.NumberOfPackages;
				EndIf;
			Else
				LineProductsSelection.NumberOfPackagesPicked = NumberOfPackagingsScanned;
				LineProductsSelection.CountPicked = QuantityScanned;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Filter = New Structure("Count", 0);
	ArrayOfEmptyStrings = GoodsFilter.FindRows(Filter);
	
	For Each IsBlankString In ArrayOfEmptyStrings Do
		GoodsFilter.Delete(IsBlankString);
	EndDo;
	
	For Each RowOfGoods In GoodsFilter Do
		
		If SeriesAreIndicatedUponSelection(RowOfGoods.BatchesIndicationStatus) Then
			
			If Not ValueIsFilled(RowOfGoods.Series)
				And (ValueIsFilled(RowOfGoods.BatchNumber)
					Or ValueIsFilled(RowOfGoods.ValidUntil_)) Then
				
				SeriesIndicationParameters = New Structure("SpecifyNumberWhenRegisteringBatch, UseShelfLifeOnBatchRegistration,
					|PrecisionOfBatchShelfLifeIndication");
				FillPropertyValues(SeriesIndicationParameters, RowOfGoods);
				
				SeriesParameters = FindSeries_(RowOfGoods.BatchNumber, RowOfGoods.ValidUntil_, RowOfGoods.ProductKind,
					SeriesIndicationParameters);
				
				RowOfGoods.Series = SeriesParameters.Series;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	DocumentObject = Job.GetObject();
	DocumentObject.GoodsFilter.Clear();
	
	CommonClientServer.SupplementTable(GoodsFilter, DocumentObject.GoodsFilter);
	
	DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
	SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Filter);
	
	DocumentObject.Write(DocumentWriteMode.Posting);
	
	Job = DocumentObject.Ref;
	JobParameters.GoodsFilter = GoodsFilter;
	
	Return JobParameters;
	
EndFunction

// Cancels the current warehouse task and returns it to its original status.
//
// Parameters:
//	Job - DocumentRef - warehouse task link,
//	SourceExecutor - CatalogRef.Users - performer of the warehouse task.
//	JobType - String - type of warehouse tasks.
//	JobParameters - See JobParameters
//
// Returns:
//	See JobParameters
//
Function CancelJobExecution(Job, SourceExecutor, JobType, JobParameters = Undefined) Export
	
	If JobParameters = Undefined Then
		JobParameters = JobParameters();
	EndIf;
	
	SetInitialStatusOfWarehouseTask(Job, JobType, JobParameters);
	
	If Not (JobType = "Receiving") Then
		InstallOriginalWarehouseTaskExecutor(Job, SourceExecutor, JobParameters);
	EndIf;
	
	If JobType = "Recalculate" Then
		SetCellLockValueInRecalculationTask(Job, JobParameters);
	EndIf;
	
	UnlockDataForEdit(Job);
	
	Return JobParameters;
	
EndFunction

// Called when completing a set of products to create a new placement task.
//
// Parameters:
//	Warehouse - CatalogRef.Warehouses - warehouse.
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	ReceivingArea - CatalogRef.StorageBins - the zone from which products are selected for placement.
//	User - CatalogRef.Users - performer of the warehouse task.
//	ScannedGoods - ValueTable - table of selected products for the placement operation.
//	DZScannedContainer - ValueTree - data on the packaging of selected products that are delivered in multi-turn containers.
//
// Returns:
//	See JobParameters
//
Function CompleteTaskNewPlacement(Warehouse, Premise, ReceivingArea, User, ScannedGoods,
	DZScannedContainer) Export
	
	JobParameters = JobParameters();
	
	DocumentObject = Documents.GoodsPickingPlacement.CreateDocument();
	
	DocumentObject.Date = CurrentSessionDate();
	DocumentObject.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location;
	DocumentObject.ExecutionStartDate = CurrentSessionDate();
	DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2;
	DocumentObject.ReceivingArea = ReceivingArea;
	DocumentObject.Performer = User;
	DocumentObject.EmployeeResponsible = User;
	DocumentObject.Warehouse = Warehouse;
	DocumentObject.Premise = Premise;
	
	For Each TBLString In ScannedGoods Do
		
		If TBLString.NumberOfPackagingsScanned = 0 Then
			Continue;
		EndIf;
		
		NumberOfPackagingsScanned = TBLString.NumberOfPackagingsScanned;
		
		If TBLString.ZoomRatio <> 0 Then
			QuantityScanned = NumberOfPackagingsScanned * TBLString.ZoomRatio;
		Else
			QuantityScanned = NumberOfPackagingsScanned;
		EndIf;
		
		NewRow = DocumentObject.GoodsPlacement.Add();
		FillPropertyValues(NewRow, TBLString);
		
		NewRow.NumberOfPackages = NumberOfPackagingsScanned;
		NewRow.Count = QuantityScanned;
		
	EndDo;
	
	If DZScannedContainer <> Undefined Then
		
		// If there is a scanned container, then add it to the table of scanned goods.
		For Each RowOfProduct In DZScannedContainer.Rows Do
			
			For Each TareString In RowOfProduct.Rows Do
				
				If TareString.NumberOfPackagingsScanned = 0 Then
					Continue;
				EndIf;
				
				NewRow = DocumentObject.GoodsPlacement.Add();
				FillPropertyValues(NewRow, TareString);
				
				NewRow.NumberOfPackages = TareString.NumberOfPackagingsScanned;
				NewRow.Count = TareString.NumberOfPackagingsScanned;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	Try
		DocumentObject.Write(DocumentWriteMode.Write);
		DocumentObject.PlaceProducts("GoodsPlacement");
	Except
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Khi kết thúc chọn hàng, đã xảy ra lỗi. Không thể 
			|thực hiện xếp vào hàng hóa. Hãy liên hệ với người quản trị.';
			|ru = 'При завершении выполнения подбора товаров произошла ошибка. Не удалось 
			|выполнить размещение товаров. Обратитесь к администратору.';
			|en = 'Item picking failed. Cannot complete put-away.
			|Please contact the administrator.'; fa = 'Item picking failed. Cannot complete put-away.
			|Please contact the administrator.';
			|it = 'Si è verificato un errore durante la selezione delle merci. Non è stato possibile 
			| eseguire il collocamento delle merci. Rivolgetevi all''amministratore.';
			|pl = 'Po zakończeniu wyboru towarów wystąpił błąd. Nie udało się 
			|wykonać rozmieszczenie towarów. Skontaktuj się z administratorem.';
			|tr = 'Ürün montaj işlemi tamamlanırken hata oluştu. 
			|Ürünler yerleştirilemedi. Yöneticiyle iletişime geç.'");
		
		// Add an error entry to the log.
		JournalComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi tạo mới nhiệm vụ sắp xếp đã xảy ra lỗi. Mô tả lỗi: ""%1""';
				|ru = 'При создании нового задания на размещение произошла ошибка. Описание ошибки: ""%1""';
				|en = 'Error creating Put-away task. Details: %1'; fa = 'Error creating Put-away task. Details: %1';
				|it = 'Si è verificato un errore durante la creazione del nuovo task di collocamento. Descrizione dell''errore: ""%1""';
				|pl = 'Podczas tworzenia nowego zadania na rozmieszczenie wystąpił błąd. Opis błędu: ""%1""';
				|tr = 'Yeni bir görev oluşturulurken hata oluştu. Hata Açıklaması: ""%1""'"), 
			ErrorInfo().Description);
		
		WriteLogEvent(
			NStr("vi = 'Lỗi khi tạo nhiệm vụ sắp xếp mới';
				|ru = 'Ошибка при создании нового задания на размещение.';
				|en = 'Error creating put-away task.'; fa = 'Error creating put-away task.';
				|it = 'Errore durante la creazione del nuovo task di collocamento.';
				|pl = 'Błąd podczas tworzenia nowego zadania na rozmieszczenie.';
				|tr = 'Yeni bir görev oluşturulurken hata oluştu.'",
				Common.DefaultLanguageCode()), 
			EventLogLevel.Error,
			DocumentObject.Ref.Metadata(),
			DocumentObject.Ref,
			JournalComment,
			EventLogEntryTransactionMode.Transactional);
	EndTry;
	
	If JobParameters.ReturnCode = 1 Then
		
		// Check that cells are specified in all lines of the document.
		PlacementCompleted = True;
		
		For Each TSRow In DocumentObject.GoodsPlacement Do
			
			If Not ValueIsFilled(TSRow.Cell) Then
				PlacementCompleted = False;
				Break;
			EndIf;
			
		EndDo;
		
		If PlacementCompleted Then
			
			SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
			
			SeriesSpecificationParameters.Filter.NameTSGoods = "GoodsPlacement";
			SeriesSpecificationParameters.Filter.TSSeriesName = "GoodsPlacement";
			
			ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Filter);
			DocumentObject.AdditionalProperties.Insert("CarryingOutOfMRMWarehouseWorker", True);
			
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
			Except
				JobParameters.ReturnCode = 0;
				JobParameters.MessageText = NStr("vi = 'Khi kết thúc chọn hàng, đã xảy ra lỗi. Không thể 
					|thực hiện xếp vào hàng hóa. Hãy liên hệ với người quản trị.';
					|ru = 'При завершении выполнения подбора товаров произошла ошибка. Не удалось 
					|выполнить размещение товаров. Обратитесь к администратору.';
					|en = 'Item picking failed. Cannot complete put-away.
					|Please contact the administrator.'; fa = 'Item picking failed. Cannot complete put-away.
					|Please contact the administrator.';
					|it = 'Si è verificato un errore durante la selezione delle merci. Non è stato possibile 
					| eseguire il collocamento delle merci. Rivolgetevi all''amministratore.';
					|pl = 'Po zakończeniu wyboru towarów wystąpił błąd. Nie udało się 
					|wykonać rozmieszczenie towarów. Skontaktuj się z administratorem.';
					|tr = 'Ürün montaj işlemi tamamlanırken hata oluştu. 
					|Ürünler yerleştirilemedi. Yöneticiyle iletişime geç.'");
			EndTry;
			
		Else
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Không thể sắp xếp hàng hóa theo ô hàng.';
											|ru = 'Не удалось разместить товары по ячейкам.';
											|en = 'Cannot place goods to bins.'; fa = 'Cannot place goods to bins.';
											|it = 'Non è stato possibile collocare le merci nelle celle.';
											|pl = 'Nie udało się rozmieścić wiersze pozycji w komórkach.';
											|tr = 'Ürünler hücreler yerleştirilemedi.'");
		EndIf;
		
	EndIf;
	
	If JobParameters.ReturnCode = 1 Then
		JobParameters.Insert("Job", DocumentObject.Ref);
	EndIf;
	
	Return JobParameters;
	
EndFunction

// The constructor of the method parameters completes the Task assignment().
// Returns:
//	Structure:
//	*Job - DocumentRef,Undefined - link to the warehouse task.
//	*VTScannedProducts - FormDataCollectionItem,ValueTable,Undefined - a table of products containing information
//		about scanned products whose series status is set to 'after-selection' in the selection,
//		placement, and movement operations. In the operations of recalculation and selection verification, data about scanned products is stored.
//	*GoodsForScanning - ValueTable,Undefined - a product table that corresponds to the tabular part of the task being performed
//		and contains information about scanned products in the selection, placement, movement, and selection verification operations.
//		Recalculation operations store the original information about the goods in the document "recalculation of Goods".
//	*ScannedStampValues - ValueTable,Undefined
//	*ReceivingArea - CatalogRef.StorageBins,Undefined - the zone where the selected items should be moved
//		if the transfer task is canceled.
//	*SelectionScanned - Boolean - True - the selection operation was performed in the move tasks.
Function NewCompleteWarehouseTaskParameters() Export
	
	Result = New Structure;
	
	Result.Insert("Job", Undefined);
	Result.Insert("VTScannedProducts", Undefined);
	Result.Insert("GoodsForScanning", Undefined);
	Result.Insert("ScannedStampValues", Undefined);
	Result.Insert("ReceivingArea", Undefined);
	Result.Insert("ShippingZone", Undefined);
	Result.Insert("SelectionScanned", False);
	
	Return Result;
	 
EndFunction
	
// Terminates the execution of the inventory job. When scanning products, the scanned products
// are transferred to the tabular parts of the documents. when typing, new warehouse tasks are created.
// The necessary statuses are set for documents, and documents are processed.
//
// Parameters:
//	Parameters - See NewCompleteWarehouseTaskParameters
//	
// Returns:
//	See WorkplaceOfWarehouseWorkerApplicationInterface.JobParameters
//
Function CompleteWarehouseTask(Parameters) Export
	
	Job = Parameters.Job;
	VTScannedProducts = Parameters.VTScannedProducts;
	GoodsForScanning = Parameters.GoodsForScanning;
	ScannedStampValues = Parameters.ScannedStampValues;
	ReceivingArea = Parameters.ReceivingArea;
	ShippingZone = Parameters.ShippingZone;
	SelectionScanned = Parameters.SelectionScanned;
	
	
	JobType = JobType(Job);
	JobParameters = JobParameters();
	JobParameters.JobType = JobType;
	
	DocumentObject = Job.GetObject();
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	PermissibleDeviationOfSelectedGoods = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If VTScannedProducts <> Undefined Then
		VTScannedProducts.GroupBy("Cell, Products, Characteristic, Purpose, Package, Series, BatchNumber,
			|ValidUntil_, ZoomRatio, BatchesIndicationStatus", "NumberOfPackagingsScanned");
	EndIf;
	
	SetTaskItems(Job, JobParameters);
	FillInStatusesForSpecifyingSeries(Job, JobParameters);
	
	If JobType = "Filter" Then
		
		JobParameters.GoodsFilter.Clear();
		
		SelectingDeletedRows = New Structure("NumberOfPackages", 0);
		Filter = New Structure("Cell, Products, Characteristic, Purpose, Package");
		
		ArrayOfRowsToDelete_1 = GoodsForScanning.FindRows(SelectingDeletedRows);
		
		For Each RowToDelete In ArrayOfRowsToDelete_1 Do
			GoodsForScanning.Delete(RowToDelete);
		EndDo;
		
		For Each ScanLine In GoodsForScanning Do
			NewRow = JobParameters.GoodsFilter.Add();
			FillPropertyValues(NewRow, ScanLine);
			
			If NewRow.ZoomRatio <> 0 Then
				NewRow.Count = ScanLine.NumberOfPackages * NewRow.ZoomRatio;
			Else
				NewRow.Count = ScanLine.NumberOfPackages;
			EndIf;
		EndDo;
		
		For Each ScanLine In GoodsForScanning Do
			
			NumberOfPackagingsScanned = ScanLine.NumberOfPackagingsScanned;
			
			If ScanLine.ZoomRatio <> 0 Then
				QuantityScanned = NumberOfPackagingsScanned * ScanLine.ZoomRatio;
			Else
				QuantityScanned = NumberOfPackagingsScanned;
			EndIf;
			
			If NumberOfPackagingsScanned = 0 Then
				Continue;
			EndIf;
			
			FillPropertyValues(Filter, ScanLine);
			
			FoundRows = JobParameters.GoodsFilter.FindRows(Filter);
			String = FoundRows[0];
			
			If SeriesAreIndicatedUponSelection(ScanLine.BatchesIndicationStatus)
				And (VTScannedProducts <> Undefined) Then
				
				FoundRowsBySeries = VTScannedProducts.FindRows(Filter);
				If FoundRowsBySeries.Count() > 0 Then
					FirstRow = FoundRowsBySeries[0];
				EndIf;
				
				TotalScannedPackages = 0;
				
				For Each ScanLineBySeries In FoundRowsBySeries Do
					
					If ScanLineBySeries = FirstRow Then
						
						QuantityScanned = FirstRow.NumberOfPackagingsScanned;
						If FoundRowsBySeries.Count() > 0 Then
							
							QuantityScanned = 0;
							For Each ProductLineBySeries In FoundRowsBySeries Do
								QuantityScanned = QuantityScanned + ProductLineBySeries.NumberOfPackagingsScanned;
							EndDo;
							
						EndIf;
						
						QuantityScanned = QuantityScanned - FirstRow.NumberOfPackagingsScanned;
						
						NumberOfPackagingsScanned = ScanLine.NumberOfPackagingsScanned
							- QuantityScanned;
						
						If ScanLine.ZoomRatio <> 0 Then
							QuantityScanned = NumberOfPackagingsScanned * ScanLine.ZoomRatio;
						Else
							QuantityScanned = NumberOfPackagingsScanned;
						EndIf;
						
					Else
						NumberOfPackagingsScanned = ScanLineBySeries.NumberOfPackagingsScanned;
						
						If ScanLineBySeries.ZoomRatio <> 0 Then
							QuantityScanned = NumberOfPackagingsScanned * ScanLineBySeries.ZoomRatio;
						Else
							QuantityScanned = NumberOfPackagingsScanned;
						EndIf;
					EndIf;
					
					NewRow = JobParameters.GoodsFilter.Add();
					FillPropertyValues(NewRow, String);
					
					NewRow.BatchNumber = ScanLineBySeries.BatchNumber;
					NewRow.ValidUntil_ = ScanLineBySeries.ValidUntil_;
					
					NewRow.NumberOfPackages = NumberOfPackagingsScanned;
					NewRow.NumberOfPackagesPicked = NumberOfPackagingsScanned;
					NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
					
					NewRow.Count = QuantityScanned;
					NewRow.CountPicked = QuantityScanned;
					
					TotalScannedPackages = TotalScannedPackages + NumberOfPackagingsScanned;
					
				EndDo;
				
				ItRemainsToScanPackages = ScanLine.NumberOfPackages - TotalScannedPackages;
				
				If ScanLine.ZoomRatio <> 0 Then
					ItRemainsToScan = ItRemainsToScanPackages * ScanLine.ZoomRatio;
				Else
					ItRemainsToScan = ItRemainsToScanPackages;
				EndIf;
				
				If ItRemainsToScanPackages <= 0 Then
					JobParameters.GoodsFilter.Delete(String);
				Else
					String.NumberOfPackagesInDocument = ItRemainsToScanPackages;
					String.NumberOfPackages = ItRemainsToScanPackages;
					String.Count = ItRemainsToScan;
				EndIf;
				
			Else
				
				If SeriesAreIndicatedUponSelection(ScanLine.BatchesIndicationStatus) Then
					
					If ValueIsFilled(ScanLine.BatchNumber)
						Or ValueIsFilled(ScanLine.ValidUntil_) Then
						
						FilterByBatch = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber, 
							|ValidUntil_");
						FillPropertyValues(FilterByBatch, ScanLine);
						
						String = JobParameters.GoodsFilter.FindRows(FilterByBatch)[0];
						String.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
						String.NumberOfPackagesPicked = NumberOfPackagingsScanned;
						String.CountPicked = QuantityScanned;
						
					EndIf;
					
				Else
					FilterByBatch = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
					FillPropertyValues(FilterByBatch, ScanLine);
					
					String = JobParameters.GoodsFilter.FindRows(FilterByBatch)[0];
					String.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
					String.NumberOfPackagesPicked = NumberOfPackagingsScanned;
					String.CountPicked = QuantityScanned;
					
					If DimensionalUnitsOfMeasurement.Find(String.MeasuredValueType) <> Undefined
						And String.NumberOfPackages < NumberOfPackagingsScanned Then
						
						String.Count = QuantityScanned;
						String.NumberOfPackages = NumberOfPackagingsScanned;
						
					EndIf;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ArrayOfEmptyStrings = New Array;
		
		For Each IsBlankString In JobParameters.GoodsFilter Do
			If IsBlankString.Count <= 0 Then
				ArrayOfEmptyStrings.Add(IsBlankString);
			EndIf;
		EndDo;
		
		For Each IsBlankString In ArrayOfEmptyStrings Do
			JobParameters.GoodsFilter.Delete(IsBlankString);
		EndDo;
		
		DocumentObject.GoodsFilter.Clear();
		FillInProductTableSeriesOfTask(JobParameters.GoodsFilter);
		CommonClientServer.SupplementTable(JobParameters.GoodsFilter, DocumentObject.GoodsFilter);
		
		GoodsFilter = JobParameters.GoodsFilter;
		MaximumQuantityOfSelectedGoods = 0;
		
		For Each RowOfProduct In GoodsFilter Do
			If DimensionalUnitsOfMeasurement.Find(RowOfProduct.MeasuredValueType) = Undefined Then
				MaximumQuantityOfSelectedGoods = MaximumQuantityOfSelectedGoods +
					RowOfProduct.NumberOfPackages;
			Else
				MaximumQuantityOfSelectedGoods = MaximumQuantityOfSelectedGoods +
					RowOfProduct.NumberOfPackages + RowOfProduct.NumberOfPackages * PermissibleDeviationOfSelectedGoods / 100;
			EndIf;
		EndDo;
		
		MaximumQuantityOfSelectedGoods = GoodsFilter.Total("NumberOfPackages") + 
			GoodsFilter.Total("NumberOfPackages") * PermissibleDeviationOfSelectedGoods / 100;
		
		If Not (GoodsFilter.Total("NumberOfPackages") <= GoodsFilter.Total("NumberOfPackagesPicked")
				And MaximumQuantityOfSelectedGoods >= GoodsFilter.Total("NumberOfPackagesPicked")) Then
			DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
		Else
			DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors;
		EndIf;
		
		SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Filter);
		
		ResultOfMarkingCheck = WorkplaceOfWarehouseWorkerLocalization.ResultOfMarkingCheck(
																					GoodsForScanning, 
																					ScannedStampValues);
		JobParameters.ResultOfMarkingCheck = ResultOfMarkingCheck;
		If TypeOf(ScannedStampValues) = Type("ValueTable") Then
			For Each MarkSAle In ResultOfMarkingCheck Do
				If MarkSAle.ValueAccepted
					And DocumentObject.PackageBarcodes.Find(MarkSAle.PackageBarcode) = Undefined Then
					NewString = DocumentObject.PackageBarcodes.Add();
					NewString.PackageBarcode = MarkSAle.PackageBarcode;
				EndIf; 
			EndDo; 
		EndIf; 
		
	EndIf;
	
	If JobType = "Location" Then
		
		JobParameters.GoodsPlacement.Clear();
		
		SelectingDeletedRows = New Structure("NumberOfPackages", 0);
		ArrayOfRowsToDelete_1 = GoodsForScanning.FindRows(SelectingDeletedRows);
		
		For Each RowToDelete In ArrayOfRowsToDelete_1 Do
			GoodsForScanning.Delete(RowToDelete);
		EndDo;
		
		For Each ScanLine In GoodsForScanning Do
			NewRow = JobParameters.GoodsPlacement.Add();
			FillPropertyValues(NewRow, ScanLine);
			
			If NewRow.ZoomRatio <> 0 Then
				NewRow.Count = ScanLine.NumberOfPackages * NewRow.ZoomRatio;
			Else
				NewRow.Count = ScanLine.NumberOfPackages;
			EndIf;
		EndDo;
		
		For Each ScanLine In GoodsForScanning Do
			IndexOf = GoodsForScanning.IndexOf(ScanLine);
			LineProductsPlacement = JobParameters.GoodsPlacement.Get(IndexOf);
			
			LineProductsPlacement.NumberOfPackagesPlaced = ScanLine.NumberOfPackagingsScanned;
			
			If LineProductsPlacement.ZoomRatio <> 0 Then
				LineProductsPlacement.CountPlaced = ScanLine.NumberOfPackagingsScanned
					* LineProductsPlacement.ZoomRatio;
			Else
				LineProductsPlacement.CountPlaced = ScanLine.NumberOfPackagingsScanned;
			EndIf;
		EndDo;
		
		DocumentObject.GoodsPlacement.Clear();
		
		CommonClientServer.SupplementTable(JobParameters.GoodsPlacement, DocumentObject.GoodsPlacement);
		
		ThereAreProductsNotScanned = Not (DocumentObject.GoodsPlacement.Total("NumberOfPackages") =
			DocumentObject.GoodsPlacement.Total("NumberOfPackagesPlaced"));
		
		If ThereAreProductsNotScanned Then
			DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
		Else
			DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors;
		EndIf;
		
		ResultOfMarkingCheck = WorkplaceOfWarehouseWorkerLocalization.ResultOfMarkingCheck(
																						GoodsForScanning, 
																						ScannedStampValues);
		JobParameters.ResultOfMarkingCheck = ResultOfMarkingCheck;
		If TypeOf(ScannedStampValues) = Type("ValueTable") Then
			For Each MarkSAle In ResultOfMarkingCheck Do
				If MarkSAle.ValueAccepted
					And DocumentObject.PackageBarcodes.Find(MarkSAle.PackageBarcode) = Undefined Then
					NewString = DocumentObject.PackageBarcodes.Add();
					NewString.PackageBarcode = MarkSAle.PackageBarcode;
				EndIf; 
			EndDo; 
		EndIf; 
		
	EndIf;
	
	If JobType = "Move" Then
		
		DoneWithErrors = False;
		
		If Not SelectionScanned Then
			
			// The selection has not been scanned and an early completion of the transfer is being performed,
			// (i.e. something was selected or nothing was selected at all, but they did not place it).
			
			ArrayOfProducts_2 = New Array;
			ArrayOfTaskProducts = JobParameters.GoodsFilter.UnloadColumn("Products");
			
			CommonClientServer.SupplementArray(ArrayOfProducts_2, ArrayOfTaskProducts, True);
			
			// We set the values of the props "Status Designationseries"
			For Each TaskItem_ In ArrayOfProducts_2 Do
				
				Filter = New Structure("Products", TaskItem_);
				RowsArray = GoodsForScanning.FindRows(Filter);
				
				BatchesIndicationStatus = RowsArray[0].BatchesIndicationStatus;
				
				ArrayOfSelectionStrings = JobParameters.GoodsFilter.FindRows(Filter);
				For Each FIlterRow In ArrayOfSelectionStrings Do
					FIlterRow.BatchesIndicationStatus = BatchesIndicationStatus;
				EndDo;
				
				ArrayOfStringsLocation = JobParameters.GoodsPlacement.FindRows(Filter);
				For Each LinePlacement In ArrayOfStringsLocation Do
					LinePlacement.BatchesIndicationStatus = BatchesIndicationStatus;
				EndDo;
				
			EndDo;
			
			GoodsFilter = JobParameters.GoodsFilter.Copy();
			
			For Each ScanLine In GoodsForScanning Do
				
				If ScanLine.NumberOfPackagingsScanned <= 0 Then
					Continue;
				EndIf;
				
				Filter = New Structure("Cell, Products, Characteristic, Purpose, Package");
				FillPropertyValues(Filter, ScanLine);
				
				FoundRows = GoodsFilter.FindRows(Filter);
				
				If FoundRows.Count() = 0 Then
					Continue;
				EndIf;
				
				LineVtProductsSelection = FoundRows[0];
				ArrayOfProductLines = JobParameters.GoodsFilter.FindRows(Filter);
				LineProductsSelection = ArrayOfProductLines[0];
				IndexOfNewRow = JobParameters.GoodsFilter.IndexOf(LineProductsSelection);
				
				If SeriesAreIndicatedUponSelection(ScanLine.BatchesIndicationStatus)
					And (VTScannedProducts <> Undefined) Then
					
					GoodsFilter.Delete(LineVtProductsSelection);
					RowsArray = VTScannedProducts.FindRows(Filter);
					
					If RowsArray.Count() = 0 Then
						Continue;
					EndIf;
					
					If RowsArray.Count() > 0 Then
						FirstRow = RowsArray[0];
					EndIf;
					
					For Each RowOfScannedProducts In RowsArray Do
						
						IndexOfNewRow = IndexOfNewRow + 1;
						If RowOfScannedProducts = FirstRow Then
							
							NumberOfScans = FirstRow.NumberOfPackagingsScanned;
							If RowsArray.Count() > 0 Then
								
								NumberOfScans = 0;
								For Each ProductLineBySeries In RowsArray Do
									NumberOfScans = NumberOfScans + ProductLineBySeries.NumberOfPackagingsScanned;
								EndDo;
								
							EndIf;
							
							NumberOfScans = NumberOfScans - FirstRow.NumberOfPackagingsScanned;
							
							NumberOfPackagingsScanned = ScanLine.NumberOfPackagingsScanned
								- NumberOfScans;
							
							If ScanLine.ZoomRatio <> 0 Then
								QuantityScanned = NumberOfPackagingsScanned * ScanLine.ZoomRatio;
							Else
								QuantityScanned = NumberOfPackagingsScanned;
							EndIf;
							
						Else
							NumberOfPackagingsScanned = RowOfScannedProducts.NumberOfPackagingsScanned;
							
							If RowOfScannedProducts.ZoomRatio <> 0 Then
								QuantityScanned = NumberOfPackagingsScanned * RowOfScannedProducts.ZoomRatio;
							Else
								QuantityScanned = NumberOfPackagingsScanned;
							EndIf;
						EndIf;
						
						// Add a line of selected products.
						NewRow = JobParameters.GoodsFilter.Insert(IndexOfNewRow);
						FillPropertyValues(NewRow, LineProductsSelection);
						
						NewRow.BatchNumber = RowOfScannedProducts.BatchNumber;
						NewRow.ValidUntil_ = RowOfScannedProducts.ValidUntil_;
						
						NewRow.NumberOfPackages = NumberOfPackagingsScanned;
						NewRow.NumberOfPackagesPicked = NumberOfPackagingsScanned;
						NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
						
						NewRow.Count = QuantityScanned;
						NewRow.CountPicked = QuantityScanned;
						
						// Add a line of posted products.
						NewRow = JobParameters.GoodsPlacement.Add();
						FillPropertyValues(NewRow, LineProductsSelection);
						
						NewRow.Cell = ReceivingArea;
						
						NewRow.BatchNumber = RowOfScannedProducts.BatchNumber;
						NewRow.ValidUntil_ = RowOfScannedProducts.ValidUntil_;
						
						NewRow.NumberOfPackages = NumberOfPackagingsScanned;
						NewRow.NumberOfPackagesPlaced = NumberOfPackagingsScanned;
						NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
						
						NewRow.Count = QuantityScanned;
						NewRow.CountPlaced = QuantityScanned;
						
					EndDo;
					
					NumberOfPackagingsScanned = ScanLine.NumberOfPackagingsScanned;
					
					If ScanLine.ZoomRatio <> 0 Then
						QuantityScanned = NumberOfPackagingsScanned * ScanLine.ZoomRatio;
					Else
						QuantityScanned = NumberOfPackagingsScanned;
					EndIf;
					
					LineProductsSelection.NumberOfPackages = LineProductsSelection.NumberOfPackages - NumberOfPackagingsScanned;
					LineProductsSelection.NumberOfPackagesInDocument = LineProductsSelection.NumberOfPackages;
					
					LineProductsSelection.Count = LineProductsSelection.Count - QuantityScanned;
					
				Else
					
					NumberOfPackagingsScanned = ScanLine.NumberOfPackagingsScanned;
					
					If ScanLine.ZoomRatio <> 0 Then
						QuantityScanned = NumberOfPackagingsScanned * ScanLine.ZoomRatio;
					Else
						QuantityScanned = NumberOfPackagingsScanned;
					EndIf;
					
					If SeriesAreIndicatedUponSelection(ScanLine.BatchesIndicationStatus) Then
						
						If ValueIsFilled(ScanLine.BatchNumber)
							Or ValueIsFilled(ScanLine.ValidUntil_) Then
							
							FilterByBatch = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber, 
								|ValidUntil_");
							FillPropertyValues(FilterByBatch, ScanLine);
							
							LineProductsSelection = JobParameters.GoodsFilter.FindRows(FilterByBatch)[0];
							
							// Add a line of selected products.
							NewRow = JobParameters.GoodsFilter.Insert(IndexOfNewRow + 1);
							FillPropertyValues(NewRow, LineProductsSelection);
							
							NewRow.BatchNumber = ScanLine.BatchNumber;
							NewRow.ValidUntil_ = ScanLine.ValidUntil_;
							
							NewRow.NumberOfPackages = NumberOfPackagingsScanned;
							NewRow.NumberOfPackagesPicked = NumberOfPackagingsScanned;
							NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
							
							NewRow.Count = QuantityScanned;
							NewRow.CountPicked = QuantityScanned;
							
							// Add a line of posted products.
							NewRow = JobParameters.GoodsPlacement.Add();
							FillPropertyValues(NewRow, LineProductsSelection);
							
							NewRow.Cell = ReceivingArea;
							
							NewRow.BatchNumber = ScanLine.BatchNumber;
							NewRow.ValidUntil_ = ScanLine.ValidUntil_;
							
							NewRow.NumberOfPackages = NumberOfPackagingsScanned;
							NewRow.NumberOfPackagesPlaced = NumberOfPackagingsScanned;
							NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
							
							NewRow.Count = QuantityScanned;
							NewRow.CountPlaced = QuantityScanned;
							
						Else
							LineProductsSelection.Count = ScanLine.NumberOfPackages * ScanLine.ZoomRatio;
							LineProductsSelection.NumberOfPackages = ScanLine.NumberOfPackages;
							LineProductsSelection.NumberOfPackagesInDocument = ScanLine.NumberOfPackages;
						EndIf;
						
					Else
						
						FilterByBatch = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
						FillPropertyValues(FilterByBatch, ScanLine);
						
						LineProductsSelection = JobParameters.GoodsFilter.FindRows(FilterByBatch)[0];
						LineProductsSelection.NumberOfPackagesPicked = NumberOfPackagingsScanned;
						LineProductsSelection.CountPicked = QuantityScanned;
						
						// Add a line of posted products.
						NewRow = JobParameters.GoodsPlacement.Add();
						FillPropertyValues(NewRow, LineProductsSelection);
						
						NewRow.Cell = ReceivingArea;
						
						NewRow.NumberOfPackages = NumberOfPackagingsScanned;
						NewRow.NumberOfPackagesPlaced = NumberOfPackagingsScanned;
						NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
						
						NewRow.Count = QuantityScanned;
						NewRow.CountPlaced = QuantityScanned;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
			ArrayOfEmptyStrings = New Array;
			
			For Each IsBlankString In JobParameters.GoodsFilter Do
				If IsBlankString.Count <= 0 Then
					ArrayOfEmptyStrings.Add(IsBlankString);
				EndIf;
			EndDo;
			
			For Each IsBlankString In ArrayOfEmptyStrings Do
				JobParameters.GoodsFilter.Delete(IsBlankString);
			EndDo;
			
			// Transfer information about selected products.
			DocumentObject.GoodsFilter.Clear();
			FillInProductTableSeriesOfTask(JobParameters.GoodsFilter);
			CommonClientServer.SupplementTable(JobParameters.GoodsFilter, DocumentObject.GoodsFilter);
			
			ArrayOfEmptyStrings = New Array;
			
			For Each IsBlankString In JobParameters.GoodsPlacement Do
				If IsBlankString.Count <= 0 Then
					ArrayOfEmptyStrings.Add(IsBlankString);
				EndIf;
			EndDo;
			
			For Each IsBlankString In ArrayOfEmptyStrings Do
				JobParameters.GoodsPlacement.Delete(IsBlankString);
			EndDo;
			
			// Transfer information about the placed products.
			DocumentObject.GoodsPlacement.Clear();
			FillInProductTableSeriesOfTask(JobParameters.GoodsPlacement);
			CommonClientServer.SupplementTable(JobParameters.GoodsPlacement, DocumentObject.GoodsPlacement);
			
			// Set the task status - completed with errors.
			DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
			SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
			
			ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Filter);
			ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Location);
			
		Else
			
			// This is the completion of the transfer task, by this point:
			// in the PM Goods collection there is information about the selected goods,
			// in the PM goods placement you need to enter information about the scanned goods.
			
			// The option when the selected products could not be placed.
			If GoodsForScanning.Total("NumberOfPackagingsScanned") = 0 Then
				
				For Each RowOfGoods In JobParameters.GoodsFilter Do
					
					If RowOfGoods.NumberOfPackagesPicked > 0 Then
						NewRow = JobParameters.GoodsPlacement.Add();
						FillPropertyValues(NewRow, RowOfGoods);
						
						NewRow.Cell = ReceivingArea;
						
						NewRow.BatchNumber = RowOfGoods.BatchNumber;
						NewRow.ValidUntil_ = RowOfGoods.ValidUntil_;
						NewRow.BatchesIndicationStatus = RowOfGoods.BatchesIndicationStatus;
						
						NewRow.NumberOfPackages = RowOfGoods.NumberOfPackagesPicked;
						NewRow.NumberOfPackagesPlaced = RowOfGoods.NumberOfPackagesPicked;
						NewRow.NumberOfPackagesInDocument = RowOfGoods.NumberOfPackagesPicked;
						
						NewRow.Count = RowOfGoods.NumberOfPackagesPicked * RowOfGoods.ZoomRatio;
						NewRow.CountPlaced = NewRow.Count;
					EndIf;
					
				EndDo;
				
				DoneWithErrors = True;
				
			Else
				
				ArrayOfProducts_2 = New Array;
				ArrayOfTaskProducts = JobParameters.GoodsFilter.UnloadColumn("Products");
				
				CommonClientServer.SupplementArray(ArrayOfProducts_2, ArrayOfTaskProducts, True);
				
				// We set the values of the props "Status Designationseries"
				For Each TaskItem_ In ArrayOfProducts_2 Do
					
					Filter = New Structure("Products", TaskItem_);
					RowsArray = DocumentObject.GoodsFilter.FindRows(Filter);
					
					BatchesIndicationStatus = RowsArray[0].BatchesIndicationStatus;
					
					ArrayOfSelectionStrings = JobParameters.GoodsFilter.FindRows(Filter);
					For Each FIlterRow In ArrayOfSelectionStrings Do
						FIlterRow.BatchesIndicationStatus = BatchesIndicationStatus;
					EndDo;
					
					ArrayOfStringsLocation = JobParameters.GoodsPlacement.FindRows(Filter);
					For Each LinePlacement In ArrayOfStringsLocation Do
						LinePlacement.BatchesIndicationStatus = BatchesIndicationStatus;
					EndDo;
					
				EndDo;
				
				Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber, ValidUntil_");
				SelectionWithoutSeries = New Structure("Cell, Products, Characteristic, Purpose, Package");
				
				For Each ScanLine In GoodsForScanning Do
					
					NumberOfPackagingsScanned = ScanLine.NumberOfPackagingsScanned;
					
					If ScanLine.ZoomRatio <> 0 Then
						QuantityScanned = NumberOfPackagingsScanned * ScanLine.ZoomRatio;
					Else
						QuantityScanned = NumberOfPackagingsScanned;
					EndIf;
					
					FillPropertyValues(Filter, ScanLine);
					FillPropertyValues(SelectionWithoutSeries, ScanLine);
					
					FoundRows = JobParameters.GoodsPlacement.FindRows(SelectionWithoutSeries);
					LineProductsPlacement = FoundRows[0];
					IndexOfNewRow = JobParameters.GoodsPlacement.IndexOf(LineProductsPlacement);
					
					If SeriesAreIndicatedUponSelection(ScanLine.BatchesIndicationStatus)
						And (VTScannedProducts <> Undefined) Then
						
						FoundRowsBySeries = VTScannedProducts.FindRows(Filter);
						
						If FoundRowsBySeries.Count() > 0 Then
							
							FirstRow = FoundRowsBySeries[0];
							For Each RowOfScannedProducts In FoundRowsBySeries Do
								
								IndexOfNewRow = IndexOfNewRow + 1;
								If RowOfScannedProducts = FirstRow Then
									
									NumberOfScans = FirstRow.NumberOfPackagingsScanned;
									If FoundRowsBySeries.Count() > 0 Then
										
										NumberOfScans = 0;
										For Each ProductLineBySeries In FoundRowsBySeries Do
											NumberOfScans = NumberOfScans + ProductLineBySeries.NumberOfPackagingsScanned;
										EndDo;
										
									EndIf;
									
									NumberOfScans = NumberOfScans - FirstRow.NumberOfPackagingsScanned;
									
									NumberOfPackagingsScanned = ScanLine.NumberOfPackagingsScanned
										- NumberOfScans;
									
									If RowOfScannedProducts.ZoomRatio <> 0 Then
										QuantityScanned = NumberOfPackagingsScanned * RowOfScannedProducts.ZoomRatio;
									Else
										QuantityScanned = NumberOfPackagingsScanned;
									EndIf;
									
								Else
									NumberOfPackagingsScanned = RowOfScannedProducts.NumberOfPackagingsScanned;
									
									If RowOfScannedProducts.ZoomRatio <> 0 Then
										QuantityScanned = NumberOfPackagingsScanned * RowOfScannedProducts.ZoomRatio;
									Else
										QuantityScanned = NumberOfPackagingsScanned;
									EndIf;
								EndIf;
								
								NewRow = JobParameters.GoodsPlacement.Insert(IndexOfNewRow);
								FillPropertyValues(NewRow, LineProductsPlacement);
								
								NewRow.BatchNumber = RowOfScannedProducts.BatchNumber;
								NewRow.ValidUntil_ = RowOfScannedProducts.ValidUntil_;
								NewRow.BatchesIndicationStatus = RowOfScannedProducts.BatchesIndicationStatus;
								
								NewRow.NumberOfPackages = NumberOfPackagingsScanned;
								NewRow.NumberOfPackagesPlaced = NumberOfPackagingsScanned;
								NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
								
								NewRow.Count = QuantityScanned;
								NewRow.CountPlaced = QuantityScanned;
								
								LineProductsPlacement.NumberOfPackages = LineProductsPlacement.NumberOfPackages - NumberOfPackagingsScanned;
								LineProductsPlacement.NumberOfPackagesInDocument = LineProductsPlacement.NumberOfPackages;
								LineProductsPlacement.Count = LineProductsPlacement.Count - QuantityScanned;
								
							EndDo;
							
						EndIf;
						
						RemainingPackagesToScan = ScanLine.NumberOfPackages -
							ScanLine.NumberOfPackagingsScanned;
						
						If ScanLine.ZoomRatio <> 0 Then
							ItRemainsToScan = RemainingPackagesToScan * ScanLine.ZoomRatio;
						Else
							ItRemainsToScan = RemainingPackagesToScan;
						EndIf;
						
						If RemainingPackagesToScan > 0 Then
							NewRow = JobParameters.GoodsPlacement.Add();
							FillPropertyValues(NewRow, LineProductsPlacement);
							
							NewRow.Cell = ReceivingArea;
							
							NewRow.BatchNumber = ScanLine.BatchNumber;
							NewRow.ValidUntil_ = ScanLine.ValidUntil_;
							NewRow.BatchesIndicationStatus = ScanLine.BatchesIndicationStatus;
							
							NewRow.NumberOfPackages = RemainingPackagesToScan;
							NewRow.NumberOfPackagesPlaced = RemainingPackagesToScan;
							NewRow.NumberOfPackagesInDocument = RemainingPackagesToScan;
							
							NewRow.Count = ItRemainsToScan;
							NewRow.CountPlaced = ItRemainsToScan;
							
							DoneWithErrors = True;
						EndIf;
						
					Else
						
						If SeriesAreIndicatedUponSelection(ScanLine.BatchesIndicationStatus) Then
							
							If NumberOfPackagingsScanned > 0 Then
								
								NewRow = JobParameters.GoodsPlacement.Insert(IndexOfNewRow + 1);
								FillPropertyValues(NewRow, ScanLine);
								
								NewRow.NumberOfPackages = NumberOfPackagingsScanned;
								NewRow.NumberOfPackagesPlaced = NumberOfPackagingsScanned;
								NewRow.NumberOfPackagesInDocument = NumberOfPackagingsScanned;
								
								NewRow.Count = QuantityScanned;
								NewRow.CountPlaced = QuantityScanned;
								
								LineProductsPlacement.NumberOfPackages = LineProductsPlacement.NumberOfPackages - NumberOfPackagingsScanned;
								LineProductsPlacement.NumberOfPackagesInDocument = LineProductsPlacement.NumberOfPackages;
								LineProductsPlacement.Count = LineProductsPlacement.Count - QuantityScanned;
								
							EndIf;
							
							LeftPackages = ScanLine.NumberOfPackages - NumberOfPackagingsScanned;
							ItRemainsToPlace = LeftPackages * ScanLine.ZoomRatio;
							
							If ItRemainsToPlace > 0 Then
								
								NewRow = JobParameters.GoodsPlacement.Add();
								FillPropertyValues(NewRow, ScanLine);
								
								NewRow.Cell = ReceivingArea;
								
								NewRow.NumberOfPackagesPlaced = LeftPackages;
								NewRow.NumberOfPackagesInDocument = LeftPackages;
								NewRow.NumberOfPackages = LeftPackages;
								
								NewRow.Count = ItRemainsToPlace;
								NewRow.CountPlaced = ItRemainsToPlace;
								
								DoneWithErrors = True;
							EndIf;
							
						Else
							
							FoundRows = JobParameters.GoodsPlacement.FindRows(Filter);
							LineProductsPlacement = FoundRows[0];
							
							LeftPackages = ScanLine.NumberOfPackages - NumberOfPackagingsScanned;
							
							If LineProductsPlacement.ZoomRatio <> 0 Then
								ItRemainsToPlace = LeftPackages * LineProductsPlacement.ZoomRatio;
							Else
								ItRemainsToPlace = LeftPackages;
							EndIf;
							
							If ScanLine.NumberOfPackages = ScanLine.NumberOfPackagingsScanned Then
								LineProductsPlacement.CountPlaced = QuantityScanned;
								LineProductsPlacement.NumberOfPackagesPlaced = NumberOfPackagingsScanned;
							Else
								
								// If there are selected but not placed goods, they should be taken to the shipping area.
								// To do this, the incompletely placed line needs to be divided into two:
								// the scanned quantity will be set in the first line, the remaining one in the second line indicating
								// the cell of the shipping zone, otherwise, the transfer document will not be able to be carried out.
								
								LineProductsPlacement.CountPlaced = QuantityScanned;
								LineProductsPlacement.NumberOfPackagesPlaced = NumberOfPackagingsScanned;
								
								// Add a new line indicating the remaining quantity and the shipping zone cell.
								If LeftPackages > 0 Then
									NewRow = JobParameters.GoodsPlacement.Add();
									FillPropertyValues(NewRow, LineProductsPlacement);
									
									NewRow.Cell = ReceivingArea;
									
									NewRow.BatchNumber = ScanLine.BatchNumber;
									NewRow.ValidUntil_ = ScanLine.ValidUntil_;
									NewRow.BatchesIndicationStatus = ScanLine.BatchesIndicationStatus;
									
									NewRow.NumberOfPackagesPlaced = LeftPackages;
									NewRow.NumberOfPackagesInDocument = LeftPackages;
									NewRow.NumberOfPackages = LeftPackages;
									
									NewRow.Count = ItRemainsToPlace;
									NewRow.CountPlaced = ItRemainsToPlace;
								EndIf;
								
								DoneWithErrors = True;
								
							EndIf;
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
			ArrayOfEmptyStrings = New Array;
			
			For Each IsBlankString In JobParameters.GoodsPlacement Do
				If IsBlankString.Count <= 0 Then
					ArrayOfEmptyStrings.Add(IsBlankString);
				EndIf;
			EndDo;
			
			For Each IsBlankString In ArrayOfEmptyStrings Do
				JobParameters.GoodsPlacement.Delete(IsBlankString);
			EndDo;
			
			// This is the completion of the transfer task, by this point:
			// in the PM Goods collection there is information about the selected goods, 
			// in the PM goods placement you need to enter information about the scanned goods.
			
			DocumentObject.GoodsPlacement.Clear();
			FillInProductTableSeriesOfTask(JobParameters.GoodsPlacement);
			CommonClientServer.SupplementTable(JobParameters.GoodsPlacement, DocumentObject.GoodsPlacement);
			
			GoodsFilter = JobParameters.GoodsFilter;
			GoodsPlacement = JobParameters.GoodsPlacement;
			
			ThereAreProductsNotScanned = 
				(GoodsFilter.Total("NumberOfPackages") <> GoodsFilter.Total("NumberOfPackagesPicked"))
					Or GoodsPlacement.Total("NumberOfPackages") <> GoodsPlacement.Total("NumberOfPackagesPlaced");
			
			If ThereAreProductsNotScanned
				Or DoneWithErrors Then
				
				DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
				
			Else
				DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors;
			EndIf;
			
			SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
			ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Location);
			
		EndIf;
		
	EndIf;
	
	If JobType = "Recalculate" Then
		
		DocumentObject = Job.GetObject();
		
		If VTScannedProducts.Count() > 0 Then
			
			DocumentObject.Goods.Clear();
			JobParameters.Goods.Clear();
			
			For Each ScanLine In VTScannedProducts Do
				
				NumberOfPackagingsScanned = ScanLine.NumberOfPackagingsScanned;
				
				If ScanLine.ZoomRatio <> 0 Then
					QuantityScanned = NumberOfPackagingsScanned * ScanLine.ZoomRatio;
				Else
					QuantityScanned = NumberOfPackagingsScanned;
				EndIf;
				
				NewRow = JobParameters.Goods.Add();
				FillPropertyValues(NewRow, ScanLine);
				
				NewRow.NumberOfPackages = 0;
				NewRow.NumberOfPackagesReal = NumberOfPackagingsScanned;
				NewRow.Count = 0;
				NewRow.CountReal = QuantityScanned;
				
			EndDo;
			
			CommonClientServer.SupplementTable(JobParameters.Goods, DocumentObject.Goods);
			FillInQuantityForAccountingWhenRecalculatingGoods(DocumentObject);
			
			Filter = New Structure("NumberOfPackages, NumberOfPackagesReal", 0, 0);
			RowsArray = DocumentObject.Goods.FindRows(Filter);
			
			For Each RowToDelete In RowsArray Do
				If ValueIsFilled(RowToDelete.Products) Then
					DocumentObject.Goods.Delete(RowToDelete);
				EndIf;
			EndDo;
			
			DocumentObject.Status = Enums.InventoryRecountStatuses.Completed2;
			
		Else
			DocumentObject.Status = Enums.InventoryRecountStatuses.Prepared2;
		EndIf;
		
		DocumentObject.LockStorageBins = False;
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.InventoryRecount);
		ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
		
	EndIf;
	
	If JobType = "PickingCheck" Then
		DocumentObject.Status = Enums.GoodsIssueNoteStatuses.ToShip;
	EndIf;
	
	If TMCommonUseClientServer.HasObjectAttribute(DocumentObject, "ExecutionEndDate") Then
		DocumentObject.ExecutionEndDate = CurrentSessionDate();
	EndIf;
	
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
	Except
		JobParameters.ReturnCode = 0;
		
		JournalComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi ghi lại và kết chuyển nhiệm vụ theo kho đã xảy ra lỗi. Mô tả lỗi: ""%1""';
				|ru = 'При записи и проведении складского задания произошла ошибка. Описание ошибки: ""%1""';
				|en = 'An error occurred while saving and posting the warehouse task. Error description: ""%1""'; fa = 'An error occurred while saving and posting the warehouse task. Error description: ""%1""';
				|it = 'Si è verificato un errore durante la registrazione e salvataggio del task di magazzino. Descrizione dell''errore: ""%1""';
				|pl = 'Podczas zapisu i prowadzeniu zadania magazynowego wystąpił błąd. Opis błędu: ""%1""';
				|tr = 'Ambar görevinin kaydı ve kaydetme sırasında hata oluştu. Hata ayrıntıları: ""%1""'"),
			ErrorInfo().Description);
		
		JobParameters.MessageText = JournalComment;
		
		WriteLogEvent(
			NStr("vi = 'Đã xảy ra lỗi trong khi ghi và thực hiện một nhiệm vụ kho từ nơi làm việc của nhân viên kho';
				|ru = 'Ошибка при записи и проведении складского задания из рабочего места работника склада';
				|en = 'An error occurred while saving and posting a warehouse task from the warehouse employee workplace'; fa = 'An error occurred while saving and posting a warehouse task from the warehouse employee workplace';
				|it = 'Si è verificato un errore durante la registrazione e il salvataggio del task di magazzino dalla postazione di lavoro del dipendente del magazzino';
				|pl = 'Błąd podczas zapisu i prowadzeniu zadania magazynowego z miejsca pracy pracownika magazynu';
				|tr = 'Bir ambar çalışanının çalışma alanından ambar görevinin kaydı ve kaydetme sırasında hata oluştu'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Job.Metadata(),
			Job,
			JournalComment,
			EventLogEntryTransactionMode.Transactional);
	EndTry;
	
	UnlockDataForEdit(Job);
	
	Return JobParameters;
	
EndFunction

// Called when the job is finished checking the selection.
//
// Parameters:
//	Warehouse - CatalogRef.Warehouses - warehouse.
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	Job - DocumentRef - link to the warehouse task.
//	ScannedGoods - ValueTable - a product table containing information about scanned products.
//	GoodsForScanning - TabularSection - a product table that corresponds to the table part of the task being performed and contains information about scanned products.
//	BinLocationWarehousingIsUsed - Boolean - True if the warehouse uses address storage.
//	ScannedStampValues - ValueList:
//	*Value - CatalogRef - the mapped link.
//	*Presentation - String -  the value of the barcode of the brand.
//
// Returns:
//	See JobParameters
//
Function CompleteTaskCheckSelection(Warehouse, Premise, Job, ScannedGoods, GoodsForScanning,
		BinLocationWarehousingIsUsed, ScannedStampValues = Undefined) Export
	
	JobParameters = JobParameters();
	
	// Create a processing for checking the quantity in the document.
	ProcessingVerification = DataProcessors.GoodsQuantityCheckInDocument.Create();
	ProcessingVerification.WarehouseDocument = Job;
	ProcessingVerification.Warehouse = Warehouse;
	ProcessingVerification.Premise = Premise;
	ProcessingVerification.ShortageAccountingOption = "Get_";
	
	For Each RowOfScannedProducts In ScannedGoods Do
		
		NewRow = ProcessingVerification.Goods.Add();
		FillPropertyValues(NewRow, RowOfScannedProducts);
		
		NewRow.NumberOfPackages = (RowOfScannedProducts.NumberOfPackagingsScanned
			- RowOfScannedProducts.NumberOfPackagesDoNotShip);
		
		If RowOfScannedProducts.ZoomRatio <> 0 Then
			NewRow.Count = (RowOfScannedProducts.NumberOfPackagingsScanned
				- RowOfScannedProducts.NumberOfPackagesDoNotShip) * RowOfScannedProducts.ZoomRatio;
		Else
			NewRow.Count = (RowOfScannedProducts.NumberOfPackagingsScanned
				- RowOfScannedProducts.NumberOfPackagesDoNotShip);
		EndIf;
		
		If RowOfScannedProducts.NumberOfPackagesDoNotShip > 0 Then
			
			If RowOfScannedProducts.NumberOfPackagesDoNotShip =
				RowOfScannedProducts.NumberOfPackagingsScanned Then
				
				NewRow.DoNotShip = 1;
				NewRow.NumberOfPackages = RowOfScannedProducts.NumberOfPackagesDoNotShip;
				
				If RowOfScannedProducts.ZoomRatio <> 0 Then
					NewRow.Count = RowOfScannedProducts.NumberOfPackagesDoNotShip
						* RowOfScannedProducts.ZoomRatio;
				Else
					NewRow.Count = RowOfScannedProducts.NumberOfPackagesDoNotShip;
				EndIf;
				
			Else
				StringOfUnloaded = ProcessingVerification.Goods.Add();
				FillPropertyValues(StringOfUnloaded, RowOfScannedProducts);
				
				StringOfUnloaded.DoNotShip = 1;
				
				StringOfUnloaded.NumberOfPackages = RowOfScannedProducts.NumberOfPackagesDoNotShip;
				
				If RowOfScannedProducts.ZoomRatio <> 0 Then
					StringOfUnloaded.Count = RowOfScannedProducts.NumberOfPackagesDoNotShip
					* RowOfScannedProducts.ZoomRatio;
				Else
					StringOfUnloaded.Count = RowOfScannedProducts.NumberOfPackagesDoNotShip;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If GoodsForScanning <> Undefined Then
		AddScannedContainerToSelectionVerificationTask(GoodsForScanning, ProcessingVerification.Goods);
	EndIf;
	
	If ScannedStampValues <> Undefined Then
		JobParameters.ResultOfMarkingCheck = WorkplaceOfWarehouseWorkerLocalization.ResultOfMarkingCheck(ScannedGoods, ScannedStampValues);
		For Each Itm In JobParameters.ResultOfMarkingCheck Do
			If Itm.ValueAccepted Then
				NewString = ProcessingVerification.PackageBarcodes.Add();
				NewString.PackageBarcode = Itm.PackageBarcode;
			EndIf;
		EndDo; 
	EndIf;
	
	// Unlock the document.
	UnlockDataForEdit(Job);
	
	FieldsToConsider = FieldsTakenIntoAccountWhenCheckingSpendingOrder(BinLocationWarehousingIsUsed, Undefined);
	
	CheckPassed = ProcessingVerification.FinishCheck(FieldsToConsider, True, True);
	ThereAreGoodsUnshipped = ProcessingVerification.Unshipped.Count() > 0;
	
	If ThereAreGoodsUnshipped Then
		JobParameters.Insert("NotShippedGoods", ProcessingVerification.Unshipped);
	EndIf;
	
	If CheckPassed
		And (ThereAreGoodsUnshipped
			Or ProcessingVerification.Shortage.Count() > 0) Then
		
		CheckPassed = ProcessingVerification.ReflectDiscrepanciesInAccounting(FieldsToConsider, True);
		
	EndIf;
	
	If Not CheckPassed Then
		
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Khi kết thúc nhiệm vụ, đã xảy ra lỗi. Không thể kết chuyển phiếu. 
			|Hãy liên hệ với người quản trị.';
			|ru = 'При завершении задания произошла ошибка. Не удалось провести ордер. 
			|Обратитесь к администратору.';
			|en = 'An error occurred while completing the job. Cannot post the note.
			|Please contact the administrator.'; fa = 'An error occurred while completing the job. Cannot post the note.
			|Please contact the administrator.';
			|it = 'Si è verificato un errore durante il completamento del task. Non è stato possibile registrare il mandato. 
			| Rivolgetevi all''ammistratore.';
			|pl = 'Po zakończeniu zadania wystąpił błąd. Nie udało się zatwierdzić zlecenie.
			|Skontaktuj się z administratorem.';
			|tr = 'İş tamamlanırken hata oluştu. Emir kaydedilmedi. 
			|Yöneticiyle iletişime geç.'");
		
		EventName = NStr("vi = 'Lỗi khi ghi và kết chuyển một phiếu kho từ nơi làm việc của nhân viên kho bãi';
						|ru = 'Ошибка при записи и проведении складского ордера из рабочего места работника склада';
						|en = 'An error occurred while saving and posting a warehouse note from the warehouse employee workplace'; fa = 'An error occurred while saving and posting a warehouse note from the warehouse employee workplace';
						|it = 'Si è verificato un errore durante la registrazione e il salvataggio del mandato di magazzino dalla postazione di lavoro del dipendente del magazzino';
						|pl = 'Błąd podczas zapisu i zatwierdzenia zlecenia magazynowego z miejsca pracy pracownika magazynu';
						|tr = 'Bir ambar çalışanının çalışma alanından ambar siparişi görevinin kaydı ve kaydetme sırasında hata oluştu'",
				Common.DefaultLanguageCode());
		
		For Each Message In GetUserMessages(True) Do
			
			JournalComment = NStr("vi = 'Khi ghi và kết chuyển nhiệm vụ kho đã xảy ra lỗi. Mô tả lỗi: ""%1"".';
									|ru = 'При записи и проведении складского задания произошла ошибка. Описание ошибки: ""%1"".';
									|en = 'An error occurred while saving and posting the warehouse task. Error description: ""%1"".'; fa = 'An error occurred while saving and posting the warehouse task. Error description: ""%1"".';
									|it = 'Si è verificato un errore durante la registrazione e il salvataggio del mandato di magazzino. Descrizione dell''errore: ""%1"".';
									|pl = 'Błąd podczas zapisu i zatwierdzenia zlecenia magazynowego. Opis błędu: ""%1"".';
									|tr = 'Ambar görevinin kaydı ve kaydetme sırasında hata oluştu. Hata ayrıntıları: ""%1"".'");
			JournalComment = StrReplace(JournalComment, "%1", Message.Text);
			
			WriteLogEvent(
				EventName,
				EventLogLevel.Error,
				Job.Metadata(),
				Job,
				JournalComment);
			
		EndDo;
		
	Else
		
		If ThereAreGoodsUnshipped Then
			JobParameters.ReturnCode = 0;
			JobParameters.Insert("NotShippedGoods", ProcessingVerification.Unshipped);
		Else
			JobParameters.MessageText = NStr("vi = 'Đã hoàn tất kiểm tra lọc.';
											|ru = 'Выполнение проверки отбора завершено.';
											|en = 'Picking check is finished.'; fa = 'Picking check is finished.';
											|it = 'Verifica della selezione completata.';
											|pl = 'Weryfikacja wyboru zakończona.';
											|tr = 'Filtre kontrolü tamamlandı.'");
		EndIf;
		
		
	EndIf;
	
	ProcessingVerification = Undefined;
	
	Return JobParameters;
	
EndFunction

// Returns a structure for storing task information.
//
// Returns:
//	Structure - warehouse task parameters contain the following fields:
//		* ReturnCode - Number - 0 indicates that there are errors detected while working with the warehouse task.
//		* MessageText - String - text of a message to the user describing problems that occurred during the execution
//									of the warehouse task.
//		* Warehouse - CatalogRef.Warehouses - warehouse of the warehouse task document.
//		* Premise - CatalogRef.Warerooms - the premise of the document warehouse jobs.
//		* Goods - ValueTable - goods of the tabular part of warehouse documents:
//			** LineNumber - Number
//			** Cell - CatalogRef.StorageBins
//			** CellCode - String
//			** Products - CatalogRef.Products
//			** ItemName - String
//			** ProductIDOfItems - String
//			** ItemsDescription - String
//			** ItemsType - EnumRef.ItemsTypes
//			** ProductKind - CatalogRef.ItemKinds
//			** NameOfTypeOfProduct - String
//			** Characteristic - CatalogRef.ItemsCharacteristics
//			** ItemVariantName - String
//			** Series - CatalogRef.ItemsBatches
//			** BatchName - String
//			** Purpose - CatalogRef.Assignments
//			** PurposeDescription - String
//			** Package - CatalogRef.PackagesAndUnitsOfMeasure
//			** PackageName - String
//			** ZoomRatio - Number
//			** FactorOfWeightUnitOfMeasure - Number
//			** FactorOfVolumeUnitOfMeasure - Number
//			** PackageWeight - Number
//			** PackageVolume - Number
//			** UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//			** UnitOfMeasureDescription - String
//			** UnitOfMeasureForWeight - CatalogRef.PackagesAndUnitsOfMeasure
//			** NameOfWeightUnitOfMeasure - String
//			** UnitOfMeasureForVolume - CatalogRef.PackagesAndUnitsOfMeasure
//			** NameOfVolumeUnitOfMeasure - String
//			** MeasuredValueType - EnumRef.TypesOfMeasuredValues
//			** SurplusDamage - Number 
//			** Count - Number 
//			** CountReal - Number 
//			** NumberOfPackages - Number 
//			** NumberOfPackagesReal - Number 
//			** NumberOfPackagesInDocument - Number 
//			** BatchesIndicationStatus - Number
//			** SpecifyNumberWhenRegisteringBatch - Boolean
//			** UseShelfLifeOnBatchRegistration - Boolean
//			** PrecisionOfBatchShelfLifeIndication - EnumRef.AccuracyOfShelfLifeIndication
//		* GoodsFilter - ValueTable - Goods of the tabular part 'Goods selection' of the document "Selection of the placement of goods":
//			** LineNumber - Number
//			** Cell - CatalogRef.StorageBins
//			** Products - CatalogRef.Products
//			** Characteristic - CatalogRef.ItemsCharacteristics
//			** Series - CatalogRef.ItemsBatches
//			** Purpose - CatalogRef.Assignments
//			** Package - CatalogRef.PackagesAndUnitsOfMeasure
//			** BatchesIndicationStatus - Number
//		* GoodsPlacement - ValueTable - Goods of the tabular part 'Product placement' of the document "Selection of product placements":
//			** LineNumber - Number
//			** Cell - CatalogRef.StorageBins
//			** Products - CatalogRef.Products
//			** Characteristic - CatalogRef.ItemsCharacteristics
//			** Series - CatalogRef.ItemsBatches
//			** Purpose - CatalogRef.Assignments
//			** BatchesIndicationStatus - Number
//		* ShippedGoods - ValueTable - goods of the tabular part 'Shippable goods' of the document 'Consumables':
//			** LineNumber - Number
//			** Action - EnumRef.ActionsWithGoodsIssueNoteRows
//			** Products - CatalogRef.Products
//			** ItemName - String
//			** ProductIDOfItems - String
//			** ItemsDescription - String
//			** ItemsType - EnumRef.ItemsTypes
//			** ProductKind - CatalogRef.ItemKinds
//			** NameOfTypeOfProduct - String
//			** Characteristic - CatalogRef.ItemsCharacteristics
//			** ItemVariantName - String
//			** Series - CatalogRef.ItemsBatches
//			** BatchName - String
//			** Purpose - CatalogRef.Assignments
//			** PurposeDescription - String
//			** Package - CatalogRef.PackagesAndUnitsOfMeasure
//			** PackageName - String
//			** ZoomRatio - Number
//			** FactorOfWeightUnitOfMeasure - Number
//			** FactorOfVolumeUnitOfMeasure - Number
//			** PackageWeight - Number
//			** PackageVolume - Number
//			** UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//			** UnitOfMeasureDescription - String
//			** UnitOfMeasureForWeight - CatalogRef.PackagesAndUnitsOfMeasure
//			** NameOfWeightUnitOfMeasure - String
//			** UnitOfMeasureForVolume - CatalogRef.PackagesAndUnitsOfMeasure
//			** NameOfVolumeUnitOfMeasure - String
//			** MeasuredValueType - EnumRef.TypesOfMeasuredValues
//			** DoNotShip - Number 
//			** Count - Number 
//			** QuantityNotToShip - Number 
//			** NumberOfPackages - Number 
//			** NumberOfPackagesDoNotShip - Number 
//			** NumberOfPackagesInDocument - Number 
//			** NumberOfPackagesInDocumentUnshipped - Number
//			** BatchesIndicationStatus - Number
//			** SpecifyNumberWhenRegisteringBatch - Boolean
//			** UseShelfLifeOnBatchRegistration - Boolean
//			** PrecisionOfBatchShelfLifeIndication - EnumRef.AccuracyOfShelfLifeIndication
//			** ThisIsAPackingList - Boolean
//		* JobType - String - ID of the warehouse task type.
//		* Status - EnumRef.StatusesOfGoodsPickingPlacement - status of the warehouse task document.
//		* Posted - Boolean - True if the warehouse task document is held.
//		* SourceExecutor - CatalogRef.Users - the initial performer of the warehouse task.
//		* ProcessingProcedure_ - EnumRef.WarehouseJobProcessingProcedure - how to work with storage cells 
//																					during the warehouse task execution.
//		* SelectionScanned - Boolean - True if the selection of goods for the 'Move' warehouse task was completed successfully.
//
Function JobParameters() Export
	
	JobParameters = New Structure();
	
	JobParameters.Insert("ReturnCode", 1);
	JobParameters.Insert("MessageText", "");
	
	JobParameters.Insert("Warehouse", Catalogs.Warehouses.EmptyRef());
	JobParameters.Insert("Premise", Catalogs.Warerooms.EmptyRef());
	
	JobParameters.Insert("Goods", Undefined);
	JobParameters.Insert("GoodsFilter", Undefined);
	JobParameters.Insert("GoodsPlacement", Undefined);
	JobParameters.Insert("ShippedGoods", Undefined);
	
	JobParameters.Insert("TopLevelMarking", Undefined);
	JobParameters.Insert("DetailedMarking", Undefined);
	JobParameters.Insert("ResultOfMarkingCheck", Undefined);
	
	JobParameters.Insert("JobType", "");
	JobParameters.Insert("Status", Undefined);
	JobParameters.Insert("Posted", False);
	JobParameters.Insert("SourceExecutor", Catalogs.Users.EmptyRef());
	JobParameters.Insert("ProcessingProcedure_", Enums.WarehouseJobProcessingProcedure.EmptyRef());
	
	JobParameters.Insert("SelectionScanned", False);
	
	Return JobParameters;
	
EndFunction

#EndRegion

#Region Private

// The function returns a reference to the warehouse operation type depending on the string description
// of the operation type (document type).
//
// Parameters:
//	OperationKind - String - type of operation.
//
// Returns:
//	EnumRef.OperationKindsOfGoodsPlacementPicking - type of warehouse operation.
//
Function TypeOfPlacementSelectionOperation(OperationKind)
	
	If OperationKind = "Filter" Then
		Return Enums.OperationKindsOfGoodsPlacementPicking.Filter;
	ElsIf OperationKind = "Location" Then
		Return Enums.OperationKindsOfGoodsPlacementPicking.Location;
	ElsIf OperationKind = "Move" Then
		Return Enums.OperationKindsOfGoodsPlacementPicking.Move;
	Else
		Return Enums.OperationKindsOfGoodsPlacementPicking.EmptyRef();
	EndIf;
	
EndFunction

// Returns a string - the type of warehouse job.
//
// Parameters:
//	Job - DocumentRef - a warehouse task that has been accepted for work.
//
// Returns:
//	Undefined, String - type of warehouse task.
//
Function JobType(Job) Export
	
	If Not ValueIsFilled(Job) Then
		Return Undefined;
	EndIf;
	
	JobType = TypeOf(Job);
	
	If JobType = Type("DocumentRef.GoodsPickingPlacement") Then
		
		TypeOfTaskOperation = Common.ObjectAttributeValue(Job, "OperationKind");
		
		If Not ValueIsFilled(TypeOfTaskOperation) Then
			Return Undefined;
		EndIf;
		
		If TypeOfTaskOperation = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
			Return "Filter";
		EndIf;
		
		If TypeOfTaskOperation = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
			Return "Location";
		EndIf;
		
		If TypeOfTaskOperation = Enums.OperationKindsOfGoodsPlacementPicking.Move Then
			Return "Move";
		EndIf;
		
	ElsIf JobType = Type("DocumentRef.InventoryRecount") Then
		
		Return "Recalculate";
		
	ElsIf JobType = Type("DocumentRef.GoodsReceiptNote") Then
		
		Return "Receiving";
		
	ElsIf JobType = Type("DocumentRef.GoodsIssueNote") Then
		
		Return "PickingCheck";
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

// Checks whether the task is available for acceptance or not.
//
// Parameters:
//	Warehouse - CatalogRef.Warerooms - warehouse for which the number of tasks is returned,
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	User - CatalogRef.Users - the contractor warehouse jobs,
//	JobParameters - See JobParameters
//
// Returns:
//	Boolean - True - the task is available for acceptance, False - the task is unavailable.
//
Function AcceptanceOfWarehouseTaskIsAvailable(Warehouse, Premise, User, JobParameters)
	
	Job = JobParameters.Job;
	JobType = JobParameters.JobType;
	
	If Not JobParameters.Posted Then
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Chưa kết chuyển chứng từ.';
										|ru = 'Документ не проведен.';
										|en = 'Document is not posted.'; fa = 'Document is not posted.';
										|it = 'Il documento non è stato registrato nella contabilità.';
										|pl = 'Nie zatwierdzono dokumentu.';
										|tr = 'Belge kaydedilmedi.'");
		
		Return False;
	EndIf;
	
	If JobParameters.Status <> InitialStatusOfWarehouseTask(JobParameters.JobType) Then
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Sai trạng thái chứng từ.';
										|ru = 'Неверный статус документа.';
										|en = 'Incorrect document status.'; fa = 'Incorrect document status.';
										|it = 'Stato del documento non corretto.';
										|pl = 'Nieprawidłowy status dokumentu.';
										|tr = 'Geçersiz belge durumu.'");
		
		Return False;
	EndIf;
	
	If Not (JobParameters.Warehouse = Warehouse)
		Or Not (JobParameters.Premise = Premise) Then
		
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Kho bãi và nhà kho trong chứng từ không tương ứng với tùy chỉnh 
			|của người sử dụng.';
			|ru = 'Склад и помещение в документе не соответствуют настройкам 
			|пользователя.';
			|en = 'Warehouse and wareroom in the document do not correspond to the
			|user settings.'; fa = 'Warehouse and wareroom in the document do not correspond to the
			|user settings.';
			|it = 'Il magazzino e il locale nel documento non corrispondono alle impostazioni 
			| dell''utente.';
			|pl = 'Magazyn i pomieszczenie w dokumencie nie są zgodne z ustawieniami 
			| użytkownika.';
			|tr = 'Belgedeki ambar ve depolama alanı kullanıcı ayarlarıyla eşleşmiyor.'");
		
		Return False;
		
	EndIf;
	
	If JobParameters.Property("Inspector") Then
		Performer = JobParameters.Inspector;
	ElsIf JobParameters.Property("Performer") Then
		Performer = JobParameters.Performer;
	ElsIf JobParameters.Property("EmployeeResponsible") Then
		Performer = JobParameters.EmployeeResponsible;
	EndIf;
	
	If ValueIsFilled(Performer) Then
		If Not (Performer = User) Then
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Nhiệm vụ kho cần được thực hiện bởi nhân viên kho khác.';
											|ru = 'Складское задание должен выполнять другой работник склада.';
											|en = 'Other warehouse worker must perform the warehouse task.'; fa = 'Other warehouse worker must perform the warehouse task.';
											|it = 'Il task di magazzino deve essere eseguito da un altro dipendente del magazzino.';
											|pl = 'Zlecenie magazynowe musi wykonywać inny pracownik magazynu.';
											|tr = 'Ambar görevi, başka bir ambar çalışanı tarafından gerçekleştirilmelidir.'");
			
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// The function returns the value of the enumeration-the initial status of the warehouse task.
//
// Parameters:
//	JobType - String - type of warehouse task.
//
Function InitialStatusOfWarehouseTask(JobType)
	
	Status = Undefined;
	
	If JobType = "Filter" 
		Or JobType = "Location" 
		Or JobType = "Move" Then
		
		Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2;
		
	ElsIf JobType = "Recalculate" Then
		
		Status = Enums.InventoryRecountStatuses.Prepared2;
		
	ElsIf JobType = "Receiving" Then
		
		Status = Enums.GoodsReceiptNoteStatuses.ToReceive;
		
	ElsIf JobType = "PickingCheck" Then
		
		Status = Enums.GoodsIssueNoteStatuses.ForChecking;
		
	EndIf;
	
	Return Status;
	
EndFunction

// The function returns the original performer of the warehouse task.
//
// Parameters:
//	Job - DocumentRef - warehouse task,
//	JobType - String - type of warehouse task.
//
// Returns:
//	CatalogRef.Users - the original executor of the warehouse task.
//
Function OriginalWarehouseTaskExecutor(Job, JobType)
	
	If JobType = "Filter" Then
		Return Job.Performer;
	ElsIf JobType = "Location" Then
		Return Job.Performer;
	ElsIf JobType = "Move" Then
		Return Job.Performer;
	ElsIf JobType = "Recalculate" Then
		Return Job.Performer;
	ElsIf JobType = "PickingCheck" Then
		Return Job.Inspector;
	ElsIf JobType = "Receiving" Then
		Return Job.EmployeeResponsible;
	Else
		Return Catalogs.Users.EmptyRef();
	EndIf;
	
EndFunction

// Returns the value of the scan option that is specified in the work area of the task.
//
// Parameters:
//	Job - DocumentRef.GoodsReceiptNote, DocumentRef.GoodsIssueNote, DocumentRef.GoodsPickingPlacement, DocumentRef.InventoryRecount - a warehouse task that is being accepted
//		for work.
//	JobType - String - type of warehouse task.
//	User - CatalogRef.Users - performer of the warehouse task.
//
// Returns:
//	EnumRef.WarehouseJobProcessingProcedure - scan option.
//
Function ProcedureForProcessingGoodsOfWarehouseTask(Job, JobType, User) Export
	
	ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.StorageBinGoods;
	
	If JobType = "Location"
		Or JobType = "Move" Then
		
		WarehouseZone = Common.ObjectAttributeValue(Job, "WarehouseZone");
		
		If ValueIsFilled(WarehouseZone) Then
			ProcessingProcedure_ = Common.ObjectAttributeValue(WarehouseZone, "WarehouseJobProcessingProcedure");
		Else
			Filter = New Structure("User, OpenedForm",
				User, Enums.FormsOpenedOnApplicationStart.WorkplaceOfWarehouseWorker);
			
			FormOpeningSettings	= InformationRegisters.ConfigureFormOpeningOnStartingApplication.Get(Filter);
			FormSettingsParameters	= FormOpeningSettings.Parameters; // ValueStorage -
			ProcessingProcedure_		= FormSettingsParameters.Get().WarehouseJobProcessingProcedure;
		EndIf;
		
	EndIf;
	
	Return ProcessingProcedure_;
	
EndFunction

// Fills in the value tables with the items required for scanning the task.
//
// Parameters:
//	Job - DocumentRef - warehouse task,
//	JobParameters - See JobParameters
//
Procedure SetTaskItems(Job, JobParameters)
	
	JobType = JobParameters.JobType;
	
	If Not ValueIsFilled(JobType) Then
		
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
			|Đã xảy ra lỗi khi nhận hàng hóa vào nhiệm vụ. Không thể nhận kiểu nhiệm vụ.';
			|ru = 'Не удалось взять складское задание в работу. 
			|Произошла ошибка при получении товаров задания. Не удалось получить тип задания.';
			|en = 'Cannot start working on the warehouse task.
			|An error occurred while receiving the job goods. Cannot receive the job type.'; fa = 'Cannot start working on the warehouse task.
			|An error occurred while receiving the job goods. Cannot receive the job type.';
			|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
			| Si è verificato un errore durante la ricezione delle merci del task. Non è stato possibile ottenere il tipo del task.';
			|pl = 'Nie udało się wziąć zadanie magazynowe. 
			|Wystąpił błąd podczas pobierania towarów zadania. Nie udało się uzyskać typ zadania.';
			|tr = 'Ambar işi kabul edilemedi. 
			|Görev ürünleri alınırken hata oluştu. İş tipi alınamadı.'");
		
		UnlockDataForEdit(Job);
		
		Return;
		
	EndIf;
	
	DocumentObject = Job.GetObject();
	

	// When goods are accepted according to the receipt order, the existing data
	// in the document is overwritten with the actually scanned values.
	If JobType = "Receiving" Then
		Return;
	EndIf;
	
	If DocumentObject = Undefined Then
		
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
			|Đã xảy ra lỗi khi nhận hàng hóa vào nhiệm vụ. Không thể nhận đối tượng nhiệm vụ.';
			|ru = 'Не удалось взять складское задание в работу. 
			|Произошла ошибка при получении товаров задания. Не удалось получить объект задания.';
			|en = 'Cannot start working on the warehouse task.
			|An error occurred while receiving the job goods. Cannot receive the job object.'; fa = 'Cannot start working on the warehouse task.
			|An error occurred while receiving the job goods. Cannot receive the job object.';
			|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
			| Si è verificato un errore durante la ricezione delle merci del task. Non è stato possibile ottenere l''oggetto del task.';
			|pl = 'Nie udało się wziąć zadanie magazynowe. 
			|Wystąpił błąd podczas pobierania towarów zadania. Nie udało się uzyskać obiekt zadania.';
			|tr = 'Ambar görevi işe alınamadı. 
			|Görev ürünleri alınırken hata oluştu. Görev nesnesi alınamadı.'");
		
		UnlockDataForEdit(Job);
		
		Return;
		
	EndIf;
	
	If JobType = "Filter" Then
		
		If DocumentObject.GoodsFilter.Count() = 0 Then
			
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
				|Đã xảy ra lỗi khi nhận hàng hóa của nhiệm vụ. Chưa điền phần bảng ""Hàng hóa 
				|(lấy ra)"" của nhiệm vụ kho.';
				|ru = 'Не удалось взять складское задание в работу. 
				|Произошла ошибка при получении товаров задания. Не заполнена табличная часть ""Товары 
				|(отбор)"" складского задания.';
				|en = 'Cannot start executing the warehouse task.
				|An error occurred while receiving the job goods. Table ""Goods
				|(picking)"" of the warehouse task is not filled in.'; fa = 'Cannot start executing the warehouse task.
				|An error occurred while receiving the job goods. Table ""Goods
				|(picking)"" of the warehouse task is not filled in.';
				|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
				| Si è verificato un errore durante la ricezione delle merci del task. Non è stata compilata la parte tabellare ""Merci 
				| (selezione)"" del task di magazzino.';
				|pl = 'Nie udało się wziąć zadanie magazynowe. 
				|Wystąpił błąd podczas pobierania towarów zadania. Nie wypełniono części tabelarycznej ""Wiersze pozycji 
				|(dopasowanie)"" zadania magazynowego.';
				|tr = 'Ambar görevi işe alınamadı. 
				|Görev ürünleri alınırken hata oluştu. Ambar görevinin ""Ürünler 
				|(filtre)"" tablo bölümü doldurulmadı.'");
			
			Return;
			
		EndIf;
		
		TaskItems_ = TaskItems_(Job, JobType);
		FillPropertyValues(JobParameters, TaskItems_);
		
	ElsIf JobType = "Location" Then
		
		If DocumentObject.GoodsPlacement.Count() = 0 Then
			
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
				|Đã xảy ra lỗi khi nhận hàng hóa của nhiệm vụ. Chưa điền phần bảng ""Hàng hóa 
				|(xếp vào)"" của nhiệm vụ kho.';
				|ru = 'Не удалось взять складское задание в работу. 
				|Произошла ошибка при получении товаров задания. Не заполнена табличная часть ""Товары 
				|(размещение)"" складского задания.';
				|en = 'Cannot assign the intra-warehouse transfer task.
				|No items in the Put-away list table.
				|Please add items to proceed.'; fa = 'Cannot assign the intra-warehouse transfer task.
				|No items in the Put-away list table.
				|Please add items to proceed.';
				|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
				| Si è verificato un errore durante la ricezione delle merci del task. Non è stata compilata la parte tabellare ""Merci 
				| (collocamento)"" del task di magazzino.';
				|pl = 'Nie udało się wziąć zadanie magazynowe. 
				|Wystąpił błąd podczas pobierania towarów zadania. Nie wypełniono części tabelarycznej ""Wiersze pozycji
				|(rozmieszczenie)"" zadania magazynowego.';
				|tr = 'Ambar görevi işe alınamadı. 
				|Görev ürünleri alınırken hata oluştu. Ambar işinin ""Ürünler 
				|(yerleştirme)"" tablo bölümü doldurulmadı.'");
			
			UnlockDataForEdit(Job);
			
			Return;
			
		EndIf;
		
		TaskItems_ = TaskItems_(Job, JobType);
		FillPropertyValues(JobParameters, TaskItems_);
		
	ElsIf JobType = "Move" Then
			
		If DocumentObject.GoodsFilter.Count() = 0 Then
			
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
				|Đã xảy ra lỗi khi nhận hàng hóa của nhiệm vụ. Chưa điền phần bảng ""Hàng hóa 
				|(xếp vào)"" của nhiệm vụ kho.';
				|ru = 'Не удалось взять складское задание в работу. 
				|Произошла ошибка при получении товаров задания. Не заполнена табличная часть ""Товары 
				|(размещение)"" складского задания.';
				|en = 'Cannot assign the intra-warehouse transfer task.
				|No items in the Put-away list table.
				|Please add items to proceed.'; fa = 'Cannot assign the intra-warehouse transfer task.
				|No items in the Put-away list table.
				|Please add items to proceed.';
				|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
				| Si è verificato un errore durante la ricezione delle merci del task. Non è stata compilata la parte tabellare ""Merci 
				| (collocamento)"" del task di magazzino.';
				|pl = 'Nie udało się wziąć zadanie magazynowe. 
				|Wystąpił błąd podczas pobierania towarów zadania. Nie wypełniono części tabelarycznej ""Wiersze pozycji
				|(rozmieszczenie)"" zadania magazynowego.';
				|tr = 'Ambar görevi işe alınamadı. 
				|Görev ürünleri alınırken hata oluştu. Ambar işinin ""Ürünler 
				|(yerleştirme)"" tablo bölümü doldurulmadı.'");
			
			Return;
			
		EndIf;
		
		If DocumentObject.GoodsPlacement.Count() = 0 Then
			
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
				|Đã xảy ra lỗi khi nhận hàng hóa của nhiệm vụ. Chưa điền phần bảng ""Hàng hóa 
				|(xếp vào)"" của nhiệm vụ kho.';
				|ru = 'Не удалось взять складское задание в работу. 
				|Произошла ошибка при получении товаров задания. Не заполнена табличная часть ""Товары 
				|(размещение)"" складского задания.';
				|en = 'Cannot assign the intra-warehouse transfer task.
				|No items in the Put-away list table.
				|Please add items to proceed.'; fa = 'Cannot assign the intra-warehouse transfer task.
				|No items in the Put-away list table.
				|Please add items to proceed.';
				|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
				| Si è verificato un errore durante la ricezione delle merci del task. Non è stata compilata la parte tabellare ""Merci 
				| (collocamento)"" del task di magazzino.';
				|pl = 'Nie udało się wziąć zadanie magazynowe. 
				|Wystąpił błąd podczas pobierania towarów zadania. Nie wypełniono części tabelarycznej ""Wiersze pozycji
				|(rozmieszczenie)"" zadania magazynowego.';
				|tr = 'Ambar görevi işe alınamadı. 
				|Görev ürünleri alınırken hata oluştu. Ambar işinin ""Ürünler 
				|(yerleştirme)"" tablo bölümü doldurulmadı.'");
			
			Return;
			
		EndIf;
		
		TaskItems_ = TaskItems_(Job, JobType);
		FillPropertyValues(JobParameters, TaskItems_);
		
	ElsIf JobType = "Recalculate" Then
		
		If DocumentObject.Goods.Count() = 0 Then
			
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
				|Đã xảy ra lỗi khi nhận hàng hóa của nhiệm vụ. Chưa điền phần bảng của nhiệm vụ kho.';
				|ru = 'Не удалось взять складское задание в работу. 
				|Произошла ошибка при получении товаров задания. Не заполнена табличная часть складского задания.';
				|en = 'Cannot start executing the warehouse task.
				|An error occurred while receiving the job goods. Table of the warehouse task is not filled in.'; fa = 'Cannot start executing the warehouse task.
				|An error occurred while receiving the job goods. Table of the warehouse task is not filled in.';
				|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
				| Si è verificato un errore durante la ricezione delle merci del task. Non è stata compilata la parte tabellare del task di magazzino.';
				|pl = 'Nie udało się wziąć zadanie magazynowe. 
				|Wystąpił błąd podczas pobierania towarów zadania. Nie wypełniono części tabelarycznej zadania magazynowego.';
				|tr = 'Ambar görevi işe alınamadı. 
				|Görev ürünleri alınırken hata oluştu. Ambar görevinin tablolu bölümü doldurulmadı.'");
			
			UnlockDataForEdit(Job);
			
			Return;
			
		EndIf;
		
		TaskItems_ = TaskItems_(Job, JobType);
		FillPropertyValues(JobParameters, TaskItems_);
		
	ElsIf JobType = "PickingCheck" Then
		
		Filter = New Structure("Action", Enums.ActionsWithGoodsIssueNoteRows.Pick);
		
		RowsArray = DocumentObject.ShippedGoods.FindRows(Filter);
		
		If RowsArray.Count() = 0 Then
			
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
				|Đã xảy ra lỗi khi nhận hàng hóa của nhiệm vụ. Chưa điền phần bảng của nhiệm vụ kho.';
				|ru = 'Не удалось взять складское задание в работу. 
				|Произошла ошибка при получении товаров задания. Не заполнена табличная часть складского задания.';
				|en = 'Cannot start executing the warehouse task.
				|An error occurred while receiving the job goods. Table of the warehouse task is not filled in.'; fa = 'Cannot start executing the warehouse task.
				|An error occurred while receiving the job goods. Table of the warehouse task is not filled in.';
				|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
				| Si è verificato un errore durante la ricezione delle merci del task. Non è stata compilata la parte tabellare del task di magazzino.';
				|pl = 'Nie udało się wziąć zadanie magazynowe. 
				|Wystąpił błąd podczas pobierania towarów zadania. Nie wypełniono części tabelarycznej zadania magazynowego.';
				|tr = 'Ambar görevi işe alınamadı. 
				|Görev ürünleri alınırken hata oluştu. Ambar görevinin tablolu bölümü doldurulmadı.'");
			
			UnlockDataForEdit(Job);
			
			Return;
			
		EndIf;
		
		If Not NumberOfTaskContainersCorrespondsToNumberOfMultiTurnContainersOfGoods(Job) Then
			
			JobParameters.ReturnCode = 0;
			JobParameters.MessageText = NStr("vi = 'Không thể lấy ra nhiệm vụ khho để làm việc. Đã lập sai nhiệm vụ kiểm tra lọc. Hãy liên hệ với người quản trị.';
											|ru = 'Не удалось взять складское задание в работу. Задание на проверку отбора составлено некорректно. Обратитесь к администратору.';
											|en = 'Cannot start working on the warehouse task. Picking check job is created incorrectly. Please contact the administrator.'; fa = 'Cannot start working on the warehouse task. Picking check job is created incorrectly. Please contact the administrator.';
											|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. Il task per la verifica della selezione non è corretto. Rivolgetevi all''amministratore.';
											|pl = 'Nie udało się wziąć zadanie magazynowe. Zadanie na sprawdzenie wyboru zostało sporządzone niepoprawnie. Skontaktuj się z administratorem.';
											|tr = 'Ambar görevi işe alınamadı. Filtre kontrolü görevi yanlış hazırlandı. Yöneticiyle iletişime geç.'");
			
			UnlockDataForEdit(Job);
			
			EventName = NStr("vi = 'Tiếp nhận nhiệm vụ kho ""Kiểm tra lọc"" để làm việc.';
							|ru = 'Принятие складского задания ""Проверка отбора"" в работу.';
							|en = 'Accept the follow-up check.'; fa = 'Accept the follow-up check.';
							|it = 'Presa in lavorazione del task di magazzino ""Verifica della selezione"".';
							|pl = 'Przyjęcie zadania magazynowego ""Weryfikacja wyboru"".';
							|tr = 'İş için ""Filtre kontrolü"" ambar görevi kabulü.'",
				CommonClientServer.DefaultLanguageCode());
			
			JournalComment = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. 
				|Không hỗ trợ kịch bản xử lý nhiệm vụ ""Kiểm tra lấy ra"" 
				|trong danh sách hàng hóa mà đã chỉ ra hàng hóa được giao với bao bì luân chuyển và 
				|bao bì đã giao riêng.';
				|ru = 'Не удалось взять складское задание в работу. 
				|Не поддерживается сценарий обработки заданий ""Проверка отбора"" 
				|в списке товаров, которых указаны товары, отгружаемые с многооборотной тарой и 
				|отдельно отгружаемой тарой.';
				|en = 'Cannot start working on the warehouse task.
				|The ""Check filter"" 
				|job processing scenario is not available in the Item list in which goods shipped with reusable packaging and 
				|package shipped separately are specified.'; fa = 'Cannot start working on the warehouse task.
				|The ""Check filter"" 
				|job processing scenario is not available in the Item list in which goods shipped with reusable packaging and 
				|package shipped separately are specified.';
				|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. 
				| Lo scenario di elaborazione dei task ""Verifica della selezione"" 
				|non è supportato nell''elenco di merci dove sono indicate le merci spedite con imballo riutilizzabile e 
				| con imballo spedito separatamente.';
				|pl = 'Nie udało się wziąć zadanie magazynowe. 
				|Scenariusz przetwarzania zadań ""Weryfikacja wyboru"" nie jest obsługiwany 
				|na liście towarów, których są wymienione wiersze pozycji, wysyłane z opakowaniem wielokrotnego użytku i 
				| oddzielnie dostarczanym opakowaniem.';
				|tr = 'Ambar görevi işe alınamadı. 
				|""Filtre kontrolü"" iş işleme komut dosyası, 
				|yeniden kullanılabilir ambalaj ve 
				|ayrı olarak sevk edilen ambalajla sevk edilen ürünleri içeren ürün listesinde desteklenmez.'");
			
			WriteLogEvent(EventName,
				EventLogLevel.Warning,
				DocumentObject.Ref.Metadata(),
				DocumentObject.Ref,
				JournalComment);
			
		EndIf;
		
		TaskItems_ = TaskItems_(Job, JobType);
		FillPropertyValues(JobParameters, TaskItems_);
		
	EndIf;
	
EndProcedure

// Checks whether the quantity of multi-turn packaging delivered with the product matches the quantity
// of packaging specified in the document.
//
// Parameters:
//	Job - DocumentRef - link to the warehouse task.
//
// Returns:
//	Boolean - True - the number of multi-turn containers supplied with the goods corresponds to the number of containers
//		specified in the document.
//
Function NumberOfTaskContainersCorrespondsToNumberOfMultiTurnContainersOfGoods(Job)
	
	UseReusablePackage = GetFunctionalOption("UseReusablePackage");
	
	If Not UseReusablePackage Then
		Return True;
	EndIf;
	
	NumberType          = TMCommonUse.MoneyFieldTypeDescription();
	TypeProducts   = New TypeDescription("CatalogRef.Products");
	TypeCharacteristic = New TypeDescription("CatalogRef.ItemsCharacteristics");
	TypePackaging       = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	
	// Create a container tree structure.
	Tara = New ValueTree();
	Tara.Columns.Add("Products",                                    TypeProducts);
	Tara.Columns.Add("Characteristic",                                  TypeCharacteristic);
	Tara.Columns.Add("Package",                                        TypePackaging);
	Tara.Columns.Add("UnitOfMeasure",                                TypePackaging);
	Tara.Columns.Add("QuantityOfProducts",                          NumberType);
	Tara.Columns.Add("ReusablePackageItems",                  TypeProducts);
	Tara.Columns.Add("ReusablePackageVariant",                TypeCharacteristic);
	Tara.Columns.Add("TheRecommendedNumberOfContainers",                     NumberType);
	Tara.Columns.Add("SelectedAmountOfPackaging",                       NumberType);
	Tara.Columns.Add("AvailableContainerQuantity",                         NumberType);
	Tara.Columns.Add("NumberOfContainersInTheDocument",                        NumberType);
	Tara.Columns.Add("MinimumNumberOfReusablePackages", NumberType);
	Tara.Columns.Add("Selected_5",                                         NumberType);
	
	// Fill the multi-turn container tree.
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentGoods.Products   AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Count     AS Count
	|
	|INTO
	|	TTDocumentProducts_
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref = &Job
	|	AND DocumentGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
	|	AND NOT DocumentGoods.ThisIsAPackingList
	|	AND DocumentGoods.Count > 0
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDocumentProducts_.Products                                  AS Products,
	|	TTDocumentProducts_.Characteristic                                AS Characteristic,
	|	0                                                               AS QuantityOfProducts,
	|	TTDocumentProducts_.Products.ReusablePackageItems   AS ReusablePackageItems,
	|	TTDocumentProducts_.Products.ReusablePackageVariant AS ReusablePackageVariant,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)      AS Package,
	|	0                                                               AS MinimumNumberOfReusablePackages
	|
	|INTO
	|	TTTare
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND TTDocumentProducts_.Products.SuppliedInReusablePackage
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocumentProducts_.Products                               AS Products,
	|	TTDocumentProducts_.Characteristic                             AS Characteristic,
	|	TTDocumentProducts_.Count                                 AS QuantityOfProducts,
	|	VALUE(Catalog.Products.EmptyRef)               AS ReusablePackageItems,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ReusablePackageVariant,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)   AS Package,
	|	0                                                            AS MinimumNumberOfReusablePackages
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocumentProducts_.Products                                       AS Products,
	|	TTDocumentProducts_.Characteristic                                     AS Characteristic,
	|	CAST(TTDocumentProducts_.Count /
	|		&QueryTextPackagingFactor1 AS NUMBER(15,0))               AS QuantityOfProducts,
	|	ProductPackages.ReusablePackageItems                  AS ReusablePackageItems,
	|	ProductPackages.ReusablePackageVariant                AS ReusablePackageVariant,
	|	ISNULL(ProductPackages.Ref,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))      AS Package,
	|	ProductPackages.MinimumNumberOfReusablePackages AS MinimumNumberOfReusablePackages
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON TTDocumentProducts_.Products.PackagingGroup = ProductPackages.Owner
	|				OR (TTDocumentProducts_.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|			AND TTDocumentProducts_.Products = ProductPackages.Owner)
	|			AND ProductPackages.SuppliedInReusablePackage
	|			AND NOT ProductPackages.DeletionMark
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTare.Products                                              AS Products,
	|	TTTare.Characteristic                                            AS Characteristic,
	|	TTTare.Package                                                  AS Package,
	|	CASE
	|		WHEN TTTare.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.Complex)
	|			THEN TTTare.Package.NumberOfPackages
	|		ELSE
	|			&QueryTextPackagingFactor2
	|	END AS NumberOfPackages,
	|	TTTare.Package.Parent                                         AS Parent,
	|	TTTare.Products.UnitOfMeasure                             AS UnitOfMeasure,
	|	MAX(TTTare.MinimumNumberOfReusablePackages) AS MinimumNumberOfReusablePackages,
	|	MAX(TTTare.ReusablePackageItems)                  AS ReusablePackageItems,
	|	MAX(TTTare.ReusablePackageVariant)                AS ReusablePackageVariant,
	|	MAX(TTTare.QuantityOfProducts)                          AS QuantityOfProducts
	|FROM
	|	TTTare AS TTTare
	|
	|GROUP BY
	|	TTTare.Products,
	|	TTTare.Characteristic,
	|	TTTare.Package
	|
	|ORDER BY
	|	TTTare.Products,
	|	TTTare.Characteristic,
	|	TTTare.Package
	|
	|TOTALS
	|	MAX(ReusablePackageItems),
	|	MAX(ReusablePackageVariant)
	|
	|BY
	|	TTTare.Products,
	|	TTTare.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDocumentProducts_.Products      AS Products,
	|	TTDocumentProducts_.Characteristic    AS Characteristic,
	|	SUM(TTDocumentProducts_.Count) AS InitialTareQuantity,
	|	SUM(TTDocumentProducts_.Count) AS NumberOfContainers,
	|	UNDEFINED                        AS TreeRow
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|
	|GROUP BY
	|	TTDocumentProducts_.Products,
	|	TTDocumentProducts_.Characteristic
	|
	|ORDER BY
	|	TTDocumentProducts_.Products.Description,
	|	TTDocumentProducts_.Characteristic.Description";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ProductPackages", Undefined));
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("TTTare.Package", "TTTare.Products"));
	
	Query.SetParameter("Job", Job);
	QueryResult = Query.ExecuteBatch();
	
	If QueryResult[2].IsEmpty() Then
		Return True;
	EndIf;
	
	PackingTable_ = New ValueTable();
	PackingTable_.Columns.Add("Products",                                    TypeProducts);
	PackingTable_.Columns.Add("Characteristic",                                  TypeCharacteristic);
	PackingTable_.Columns.Add("Package",                                        TypePackaging);
	PackingTable_.Columns.Add("Parent");
	PackingTable_.Columns.Add("QuantityOfProducts",                          NumberType);
	PackingTable_.Columns.Add("NumberOfPackages",                              NumberType);
	PackingTable_.Columns.Add("ReusablePackageItems",                  TypeProducts);
	PackingTable_.Columns.Add("ReusablePackageVariant",                TypeCharacteristic);
	PackingTable_.Columns.Add("MinimumNumberOfReusablePackages", NumberType);
	
	AllContainersArePickedUp = True;
	
	SelectionOfProducts = QueryResult[2].Select(QueryResultIteration.ByGroups);
	DocumentPackaging       = QueryResult[3].Unload();
	
	While SelectionOfProducts.Next() Do
		
		FeatureSelection_ = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		
		While FeatureSelection_.Next() Do
			
			PackingTable_.Clear();
			
			PackageSelection = FeatureSelection_.Select();
			
			While PackageSelection.Next() Do
				
				If ValueIsFilled(PackageSelection.Package) Then
					
					NewLinePackaging = PackingTable_.Add();
					FillPropertyValues(NewLinePackaging, PackageSelection);
					
				Else
					
					NewRow = Tara.Rows.Add();
					FillPropertyValues(NewRow, PackageSelection);
					
					If ValueIsFilled(NewRow.ReusablePackageItems) Then
						NewRow.TheRecommendedNumberOfContainers = Int(NewRow.QuantityOfProducts);
						NewRow.SelectedAmountOfPackaging   = NewRow.TheRecommendedNumberOfContainers;
						
						FillInNumberOfContainersFromDocument(DocumentPackaging, NewRow, AllContainersArePickedUp);
					EndIf;
					
				EndIf;
				
			EndDo;
			
			OutputSubordinatePackages(NewRow.Rows, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), PackingTable_,
				DocumentPackaging, AllContainersArePickedUp);
			
		EndDo;
		
	EndDo;
	
	For Each CurRow In DocumentPackaging Do
		
		If CurRow.InitialTareQuantity = CurRow.NumberOfContainers Then
			
			AllContainersArePickedUp = False;
			
			NewRow = Tara.Rows.Add();
			NewRow.ReusablePackageItems   = CurRow.Products;
			NewRow.ReusablePackageVariant = CurRow.Characteristic;
			NewRow.NumberOfContainersInTheDocument         = CurRow.NumberOfContainers;
			NewRow.Selected_5                          = True;
			
		ElsIf CurRow.NumberOfContainers > 0 And CurRow.TreeRow <> Undefined Then
			
			CurRow.TreeRow.NumberOfContainersInTheDocument = CurRow.TreeRow.NumberOfContainersInTheDocument
				+ CurRow.NumberOfContainers;
			
			If CurRow.TreeRow.NumberOfContainersInTheDocument <> CurRow.TreeRow.SelectedAmountOfPackaging Then
				AllContainersArePickedUp = False;
				
				CurRow.TreeRow.Selected_5 = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Place the container in the storage.
	PackageTable = New ValueTable();
	PackageTable.Columns.Add("Products",   TypeProducts);
	PackageTable.Columns.Add("Characteristic", TypeCharacteristic);
	PackageTable.Columns.Add("Count",     NumberType);
	
	AddSelectedContainersToTable(Tara.Rows, PackageTable);
	
	PackageTable.GroupBy("Products,Characteristic", "Count");
	
	SelectedContainerCorrespondsToTask = True;
	
	For Each TareString In PackageTable Do
		
		Filter = New Structure("Products, Characteristic", TareString.Products, TareString.Characteristic);
		PackagingAccordingToDocument = DocumentPackaging.FindRows(Filter);
		
		If PackagingAccordingToDocument.Count() = 0 Then
			Continue;
		EndIf;
		
		CountByDocument = 0;
		
		For Each DocumentContainerString In PackagingAccordingToDocument Do
			CountByDocument = CountByDocument + DocumentContainerString.InitialTareQuantity;
		EndDo;
		
		If CountByDocument > TareString.Count Then
			SelectedContainerCorrespondsToTask = False;
			Break;
		EndIf;
		
	EndDo;
	
	Return SelectedContainerCorrespondsToTask;
	
EndFunction

// Fills the columns of the container quantity in the document's table With values based on the container data in the document.
//
// Parameters:
//	DocumentPackaging    - ValueTable      - summary table of containers,
//	TreeRow     - ValueTreeRow - line wood containers,
//	AllContainersArePickedUp - Boolean               - indicates that the entire container is filled.
//
Procedure FillInNumberOfContainersFromDocument(DocumentPackaging, TreeRow, AllContainersArePickedUp)
	
	UseVariants = Common.ObjectAttributeValue(TreeRow.ReusablePackageItems,
		"UseVariants");
	
	If UseVariants <> Enums.ItemVariantsUsageOptions.DontUse
		And Not ValueIsFilled(TreeRow.ReusablePackageVariant) Then
		
		Filter = New Structure("Products", TreeRow.ReusablePackageItems);
		TareDocumentStrings = DocumentPackaging.FindRows(Filter);
		
	Else
		
		Filter = New Structure;
		Filter.Insert("Products", TreeRow.ReusablePackageItems);
		Filter.Insert("Characteristic", TreeRow.ReusablePackageVariant);
		
		TareDocumentStrings = DocumentPackaging.FindRows(Filter);
		
	EndIf;
	
	If TareDocumentStrings.Count() > 0
		And TareDocumentStrings[0].NumberOfContainers > 0 Then
		
		TreeRow.NumberOfContainersInTheDocument = Min(TreeRow.TheRecommendedNumberOfContainers,
			TareDocumentStrings[0].NumberOfContainers);
		
		TareDocumentStrings[0].NumberOfContainers = TareDocumentStrings[0].NumberOfContainers - TreeRow.NumberOfContainersInTheDocument;
		TareDocumentStrings[0].TreeRow   = TreeRow;
		
	EndIf;
	
	If TreeRow.NumberOfContainersInTheDocument <> TreeRow.SelectedAmountOfPackaging Then
		AllContainersArePickedUp = False;
		
		TreeRow.Selected_5 = True;
	EndIf;
	
EndProcedure

// Complements the container tree with subordinate packages, if the product packages are nested.
//
// Parameters:
//	StringPacking_   - ValueTreeRowCollection              - node lines,
//	PackingKnot     - CatalogRef.PackagesAndUnitsOfMeasure - the package for which subordinate packages are output,
//	PackingTable_  - ValueTable                           - packing table,
//	DocumentPackaging    - ValueTable                           - document multi-turn packaging table,
//	AllContainersArePickedUp - Boolean                                    - indicates whether the entire container is selected, including nested packages.
//
Procedure OutputSubordinatePackages(StringPacking_, PackingKnot, PackingTable_, DocumentPackaging, AllContainersArePickedUp)
	
	Filter               = New Structure("Parent", PackingKnot);
	SubordinatePackages = PackingTable_.FindRows(Filter);
	
	QuantityOfProducts               = StringPacking_.Parent.QuantityOfProducts;
	NumberOfProductsToDistribute = QuantityOfProducts;
	
	For Each CurRow In SubordinatePackages Do
		
		NewLinePackaging = StringPacking_.Add();
		FillPropertyValues(NewLinePackaging, CurRow);
		
		RemainingPackages = Int(QuantityOfProducts % CurRow.NumberOfPackages);
		
		NewLinePackaging.QuantityOfProducts = NewLinePackaging.QuantityOfProducts +
			?(RemainingPackages > 0 And RemainingPackages >= CurRow.MinimumNumberOfReusablePackages, 1, 0);
		
		NumberOfContainers = Int(NumberOfProductsToDistribute / CurRow.NumberOfPackages);
		ContainerResidue    = Int(QuantityOfProducts % CurRow.NumberOfPackages);
		
		If NumberOfContainers > 0 Then
			
			NewLinePackaging.TheRecommendedNumberOfContainers = NumberOfContainers;
			NewLinePackaging.SelectedAmountOfPackaging = NewLinePackaging.TheRecommendedNumberOfContainers;
			NumberOfProductsToDistribute = ContainerResidue;
			
		EndIf;
		
		If CurRow = SubordinatePackages[SubordinatePackages.Count()-1]
			And NumberOfProductsToDistribute > 0 Then
			
			NewLinePackaging.TheRecommendedNumberOfContainers =
				?(ValueIsFilled(NewLinePackaging.TheRecommendedNumberOfContainers),
					NewLinePackaging.TheRecommendedNumberOfContainers, 0)
				+ ?(NumberOfProductsToDistribute >= CurRow.MinimumNumberOfReusablePackages, 1, 0);
			NewLinePackaging.SelectedAmountOfPackaging  = NewLinePackaging.TheRecommendedNumberOfContainers;
			
		EndIf;
		
		FillInNumberOfContainersFromDocument(DocumentPackaging, NewLinePackaging, AllContainersArePickedUp);
		OutputSubordinatePackages(NewLinePackaging.Rows, CurRow.Package, PackingTable_, DocumentPackaging,
			AllContainersArePickedUp);
		
	EndDo;
	
EndProcedure

// Adds the selected container to the final container table.
//
// Parameters:
//	TreeRows - ValueTreeRowCollection - tare tree strings,
//	PackageTable  - ValueTable              - the final table of the container.
//
Procedure AddSelectedContainersToTable(TreeRows, PackageTable)
	
	For Each CurRow In TreeRows Do
		
		If CurRow.Selected_5 Then
			If ValueIsFilled(CurRow.ReusablePackageItems) Then
				NewRow = PackageTable.Add();
				NewRow.Products   = CurRow.ReusablePackageItems;
				NewRow.Characteristic = CurRow.ReusablePackageVariant;
				NewRow.Count     = CurRow.SelectedAmountOfPackaging;
			EndIf;
		EndIf;
		
		AddSelectedContainersToTable(CurRow.Rows, PackageTable);
		
	EndDo;
	
EndProcedure

// The function returns a structure with data from the table parts of the document-the warehouse task.
// If the warehouse task type is "Moving", then the structure contains 2 elements - data
// from the table part "product Selection"and" product Placement".
//
// Parameters:
//	Job - DocumentRef - warehouse task
//	JobType - String - type of warehouse task
//
// Returns:
//	Structure:
//	*LineNumber - Number
//	*Cell - CatalogRef.StorageBins
//	*Products - CatalogRef.Products
//	*Characteristic - CatalogRef.ItemsCharacteristics
//	*Series - CatalogRef.ItemsBatches
//	*Purpose - CatalogRef.Assignments
//	*Package - CatalogRef.PackagesAndUnitsOfMeasure
//	*BatchesIndicationStatus - Number
//
Function TaskItems_(Job, JobType) Export
	
	If JobType = "Filter" Then
		
		QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Cell AS Cell,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Series AS Series,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
		|FROM
		|	Document.GoodsPickingPlacement.GoodsFilter AS Goods
		|WHERE
		|	Goods.Ref = &Job";
		
	ElsIf JobType = "Location" Then
		
		QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Cell AS Cell,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Series AS Series,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
		|FROM
		|	Document.GoodsPickingPlacement.GoodsPlacement AS Goods
		|WHERE
		|	Goods.Ref = &Job";
		
	ElsIf JobType = "Move" Then
		
		QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Cell AS Cell,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Series AS Series,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
		|FROM
		|	Document.GoodsPickingPlacement.GoodsFilter AS Goods
		|WHERE
		|	Goods.Ref = &Job
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Cell AS Cell,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Series AS Series,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
		|FROM
		|	Document.GoodsPickingPlacement.GoodsPlacement AS Goods
		|WHERE
		|	Goods.Ref = &Job";
		
	ElsIf JobType = "Recalculate" Then
		
		QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Cell AS Cell,
		|	Goods.Cell.Code AS CellCode,
		|	Goods.Products AS Products,
		|	ISNULL(Goods.Products.Presentation, """") AS ItemName,
		|	ISNULL(Goods.Products.SKU, """") AS ProductIDOfItems,
		|	ISNULL(Goods.Products.LongDesc, """") AS ItemsDescription,
		|	ISNULL(Goods.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|	ISNULL(Goods.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
		|	ISNULL(Goods.Products.ProductKind.Presentation, """") AS NameOfTypeOfProduct,
		|	Goods.Characteristic AS Characteristic,
		|	ISNULL(Goods.Characteristic.Presentation, """") AS ItemVariantName,
		|	Goods.Series AS Series,
		|	ISNULL(Goods.Series.Presentation, """") AS BatchName,
		|	Goods.Purpose AS Purpose,
		|	ISNULL(Goods.Purpose.Presentation, """") AS PurposeDescription,
		|	Goods.Package AS Package,
		|	ISNULL(Goods.Package.Presentation, """") AS PackageName,
		|	ISNULL(&ZoomRatio1, 1) AS ZoomRatio,
		|	ISNULL(&ZoomRatio2, 1) AS FactorOfWeightUnitOfMeasure,
		|	ISNULL(&ZoomRatio3, 1) AS FactorOfVolumeUnitOfMeasure,
		|	&PackageWeight AS PackageWeight,
		|	&PackageVolume AS PackageVolume,
		|	ISNULL(Goods.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(Goods.Products.UnitOfMeasure), """") AS UnitOfMeasureDescription,
		|	ISNULL(Goods.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForWeight,
		|	ISNULL(PRESENTATION(Goods.Products.WeightUnitOfMeasure), """") AS NameOfWeightUnitOfMeasure,
		|	ISNULL(Goods.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForVolume,
		|	ISNULL(PRESENTATION(Goods.Products.VolumeUnitOfMeasure), """") AS NameOfVolumeUnitOfMeasure,
		|	ISNULL(Goods.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)) AS MeasuredValueType,
		|	Goods.SurplusDamage AS SurplusDamage,
		|	Goods.Count AS Count,
		|	Goods.CountReal AS CountReal,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.NumberOfPackagesReal AS NumberOfPackagesReal,
		|	Goods.NumberOfPackages AS NumberOfPackagesInDocument,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	ISNULL(Goods.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE) AS SpecifyNumberWhenRegisteringBatch,
		|	ISNULL(Goods.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE) AS UseShelfLifeOnBatchRegistration,
		|	ISNULL(Goods.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)) AS PrecisionOfBatchShelfLifeIndication
		|FROM
		|	Document.InventoryRecount.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Job";
		
	ElsIf JobType = "PickingCheck" Then
		
		QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Action AS Action,
		|	Goods.Products AS Products,
		|	ISNULL(Goods.Products.Presentation, """") AS ItemName,
		|	ISNULL(Goods.Products.SKU, """") AS ProductIDOfItems,
		|	ISNULL(Goods.Products.LongDesc, """") AS ItemsDescription,
		|	ISNULL(Goods.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|	ISNULL(Goods.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
		|	ISNULL(Goods.Products.ProductKind.Presentation, """") AS NameOfTypeOfProduct,
		|	Goods.Characteristic AS Characteristic,
		|	ISNULL(Goods.Characteristic.Presentation, """") AS ItemVariantName,
		|	Goods.Series AS Series,
		|	ISNULL(Goods.Series.Presentation, """") AS BatchName,
		|	Goods.Purpose AS Purpose,
		|	ISNULL(Goods.Purpose.Presentation, """") AS PurposeDescription,
		|	Goods.Package AS Package,
		|	ISNULL(Goods.Package.Presentation, """") AS PackageName,
		|	ISNULL(&ZoomRatio1, 1) AS ZoomRatio,
		|	ISNULL(&ZoomRatio2, 1) AS FactorOfWeightUnitOfMeasure,
		|	ISNULL(&ZoomRatio3, 1) AS FactorOfVolumeUnitOfMeasure,
		|	&PackageWeight AS PackageWeight,
		|	&PackageVolume AS PackageVolume,
		|	ISNULL(Goods.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(Goods.Products.UnitOfMeasure), """") AS UnitOfMeasureDescription,
		|	ISNULL(Goods.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForWeight,
		|	ISNULL(PRESENTATION(Goods.Products.WeightUnitOfMeasure), """") AS NameOfWeightUnitOfMeasure,
		|	ISNULL(Goods.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForVolume,
		|	ISNULL(PRESENTATION(Goods.Products.VolumeUnitOfMeasure), """") AS NameOfVolumeUnitOfMeasure,
		|	ISNULL(Goods.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)) AS MeasuredValueType,
		|	0 AS DoNotShip,
		|	Goods.Count AS Count,
		|	0 AS QuantityNotToShip,
		|	Goods.Count AS QuantityOfGoodsInDocument,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	0 AS NumberOfPackagesDoNotShip,
		|	Goods.NumberOfPackages AS NumberOfPackagesInDocument,
		|	0 AS NumberOfPackagesInDocumentUnshipped,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	ISNULL(Goods.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE) AS SpecifyNumberWhenRegisteringBatch,
		|	ISNULL(Goods.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE) AS UseShelfLifeOnBatchRegistration,
		|	ISNULL(Goods.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)) AS PrecisionOfBatchShelfLifeIndication,
		|	Goods.ThisIsAPackingList AS ThisIsAPackingList
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS Goods
		|WHERE
		|	Goods.Ref = &Job";
		
	EndIf;
	
	If JobType = "Recalculate"
		Or JobType = "PickingCheck" Then
		
		SourceOfPackaging = "Goods.Package";
		SourceOfProducts = "Goods.Products";
		SourceOfWeightUnit = "Goods.Products.WeightUnitOfMeasure";
		SourceVolumeUnits = "Goods.Products.VolumeUnitOfMeasure";
		
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
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Job", Job);
	
	TaskItems_ = New Structure; // See JobParameters
	QueryResult = Query.ExecuteBatch();
	
	If JobType = "Filter" Then
		TaskItems_.Insert("GoodsFilter", QueryResult[0].Unload());
	ElsIf JobType = "Recalculate" Then
		TaskItems_.Insert("Goods", QueryResult[0].Unload());
	ElsIf JobType = "Location" Then
		TaskItems_.Insert("GoodsPlacement", QueryResult[0].Unload());
	ElsIf JobType = "Move" Then
		TaskItems_.Insert("GoodsFilter", QueryResult[0].Unload());
		TaskItems_.Insert("GoodsPlacement", QueryResult[1].Unload());
	ElsIf JobType = "PickingCheck" Then
		TaskItems_.Insert("ShippedGoods", QueryResult[0].Unload());
	EndIf;
	
	If JobType = "Recalculate" Then
		
		TypeRowWKCells = New TypeDescription("String", , New StringQualifiers(50));
		TaskItems_.Goods.Columns.Add("CellBarcode", TypeRowWKCells);
		
		For Each RowOfGoods In TaskItems_.Goods Do
			RowOfGoods.CellBarcode = BarcodingOfPrintForms.NumericCodeFromLink(RowOfGoods.Cell);
		EndDo;
		
	EndIf;
	
	Return TaskItems_;
	
EndFunction

// The procedure sets the status <in Progress> for the warehouse task.
// 
// Parameters:
//	Job - DocumentRef.GoodsReceiptNote, DocumentRef.GoodsIssueNote, DocumentRef.GoodsPickingPlacement, DocumentRef.InventoryRecount - 
//			a warehouse task that is being accepted for work.
//	JobParameters - See JobParameters
//	User - CatalogRef.Users - performer of the warehouse task.
//
Procedure SetStatusOfTaskInProgress(Job, JobParameters, User) Export
	
	JobType = JobParameters.JobType;
	DocumentObject = Job.GetObject();
	
	If DocumentObject = Undefined Then
		
		UnlockDataForEdit(Job);
		
		JobParameters.ReturnCode = 0;
		
		// Add an error entry to the log.
		JournalComment = NStr("vi = 'Không thể thực hiện nhiệm vụ kho. Đã xảy ra lỗi khi đặt trạng thái 
			|nhiệm vụ. Mô tả lỗi: Không thể nhận đối tượng nhiệm vụ.';
			|ru = 'Не удалось взять складское задание в работу. Произошла ошибка при установке статуса 
			|задания. Описание ошибки: Не удалось получить объект задания.';
			|en = 'Cannot start working on the warehouse task.
			|An error occurred while setting the job status. Error description: Cannot receive the job object.'; fa = 'Cannot start working on the warehouse task.
			|An error occurred while setting the job status. Error description: Cannot receive the job object.';
			|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. Si è verificato un errore durante l''impostazione dello stato 
			|del task. Descrizione dell''errore: Non è stato possibile ottenere l''oggetto del task.';
			|pl = 'Nie udało się wziąć zadanie magazynowe. Wystąpił błąd podczas ustawieniu statusu 
			|zadania. Opis błędu: Nie udało się uzyskać obiekt zadania.';
			|tr = 'Ambar görevi işe alınamadı. 
			|İş durumu ayarlanırken hata oluştu. Hata ayrıntıları: Görev nesnesi alınamadı.'");
		
		WriteLogEvent(NStr("vi = 'Đã xảy ra lỗi trong khi đặt nhiệm vụ kho làm việc.';
							|ru = 'Ошибка при постановке складского задания в работу.';
							|en = 'An error occurred while putting the warehouse task into operation.'; fa = 'An error occurred while putting the warehouse task into operation.';
							|it = 'Errore durante la messa in lavorazione del task di magazzino.';
							|pl = 'Błąd podczas ustawiania zadania magazynowego do wykonania.';
							|tr = 'Ambar görevi işe ayarlanırken hata oluştu.'",
			CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Job.Metadata(),
			Job,
			JournalComment,
			EventLogEntryTransactionMode.Transactional);
		
		Return;
		
	EndIf;
	
	If JobType = "Receiving" Then
		
		DocumentObject.Status = Enums.GoodsReceiptNoteStatuses.InProgress;
		
	ElsIf JobType = "Recalculate" Then
		
		DocumentObject.Date = CurrentSessionDate();
		DocumentObject.Performer = User;
		DocumentObject.LockStorageBins = True;
		DocumentObject.AccountingDataIsFilledIn = False;
		DocumentObject.Status = Enums.InventoryRecountStatuses.InProgress;
		
	ElsIf JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		DocumentObject.Performer = User;
		DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.InProgress;
		
	ElsIf JobType = "PickingCheck" Then
		
		DocumentObject.Inspector = User;
		DocumentObject.Status = Enums.GoodsIssueNoteStatuses.DuringChecking;
		
	EndIf;
	
	Try
		
		If JobType = "Filter"
			Or JobType = "Recalculate"
			Or JobType = "Location"
			Or JobType = "Move" Then
			
			If TMCommonUseClientServer.HasObjectAttribute(DocumentObject, "ExecutionStartDate") Then
				DocumentObject.ExecutionStartDate = CurrentSessionDate();
			EndIf;
			
			WriteMode = DocumentWriteMode.Posting;
			
		ElsIf JobType = "Receiving"
			Or JobType = "PickingCheck" Then
			
			WriteMode = DocumentWriteMode.Write;
			
		EndIf;
		
		DocumentObject.Write(WriteMode);
		
	Except
		
		UnlockDataForEdit(Job);
		
		JobParameters.ReturnCode = 0;
		ErrorDescription = ErrorInfo().Description;
		
		// Add an error entry to the log.
		JournalComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thực hiện nhiệm vụ kho. Đã xảy ra lỗi khi đặt trạng thái nhiệm vụ. 
			|Mô tả lỗi: ""%1"".';
			|ru = 'Не удалось взять складское задание в работу. Произошла ошибка при установке статуса задания. 
			|Описание ошибки: ""%1"".';
			|en = 'Cannot start working on the warehouse task.
			|An error occurred while setting the job status. Error description: ""%1"".'; fa = 'Cannot start working on the warehouse task.
			|An error occurred while setting the job status. Error description: ""%1"".';
			|it = 'Non è stato possibile prendere in lavorazione il task di magazzino. Si è verificato un errore durante l''impostazione dello stato del task. 
			|Descrizione dell''errore: ""%1"".';
			|pl = 'Nie udało się wziąć zadanie magazynowe. Wystąpił błąd podczas ustawienia statusu zadania. 
			| Opis błędu: ""%1"".';
			|tr = 'Ambar görevi işe alınamadı. İş durumu ayarlanırken hata oluştu. 
			|Hata ayrıntıları: ""%1"".'"),
			ErrorDescription);
		
		WriteLogEvent(NStr("vi = 'Đã xảy ra lỗi trong khi đặt nhiệm vụ kho làm việc.';
							|ru = 'Ошибка при постановке складского задания в работу.';
							|en = 'An error occurred while putting the warehouse task into operation.'; fa = 'An error occurred while putting the warehouse task into operation.';
							|it = 'Errore durante la messa in lavorazione del task di magazzino.';
							|pl = 'Błąd podczas ustawiania zadania magazynowego do wykonania.';
							|tr = 'Ambar görevi işe ayarlanırken hata oluştu.'",
			CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Job.Metadata(),
			Job,
			JournalComment,
			EventLogEntryTransactionMode.Transactional);
		
		Return;
		
	EndTry;
	
EndProcedure

// The procedure fills in the parameters of the 'Parameterization' structure.
//
// Parameters:
//	Job - DocumentRef - warehouse task
//	JobParameters - See JobParameters
//
Procedure SetJobParameters(Job, JobParameters) Export
	
	JobType = JobParameters.JobType;
	
	NamesOfTaskDetails = New Array;
	NamesOfTaskDetails.Add("Warehouse");
	NamesOfTaskDetails.Add("Status");
	NamesOfTaskDetails.Add("Posted");
	NamesOfTaskDetails.Add("Premise");
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move"
		Or JobType = "Recalculate" Then
		
		JobParameters.Insert("Performer");
		
		NamesOfTaskDetails.Add("Performer");
		
	EndIf;
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		JobParameters.Insert("ReceivingArea");
		JobParameters.Insert("ShippingZone");
		
		NamesOfTaskDetails.Add("ReceivingArea");
		NamesOfTaskDetails.Add("ShippingZone");
		
	EndIf;
	
	If JobType = "Receiving" Then
		JobParameters.Insert("Status");
		JobParameters.Insert("EmployeeResponsible");
		
		NamesOfTaskDetails.Add("Status");
		NamesOfTaskDetails.Add("EmployeeResponsible");
	EndIf;
	
	If JobType = "Filter"
		Or JobType = "Receiving" Then
		
		JobParameters.Insert("ReferenceOrder");
		
		NamesOfTaskDetails.Add("ReferenceOrder");
		
	EndIf;
	
	If JobType = "PickingCheck" Then
		JobParameters.Insert("Inspector");
		JobParameters.Insert("DateOfShipment");
		
		NamesOfTaskDetails.Add("Inspector");
		NamesOfTaskDetails.Add("DateOfShipment");
	EndIf;
	
	If JobType = "Receiving"
		Or JobType = "PickingCheck" Then
		
		NamesOfTaskDetails.Add("WarehouseOperation");
		
		JobParameters.Insert("WarehouseOperation");
		
	EndIf;
	
	TaskAttributes = Common.ObjectAttributesValues(Job, NamesOfTaskDetails);
	FillPropertyValues(JobParameters, TaskAttributes);
	
EndProcedure

// The procedure fills in the statuses of specifying series in the table parts of the 'Parameterization' structure
// of the 'Acceptance' and 'check-Selection' operations.
//
// Parameters:
//	Job - DocumentRef - warehouse task
//	JobParameters - See JobParameters
//
Procedure FillInStatusesForSpecifyingSeries(Job, JobParameters) Export
	
	Var SeriesSpecificationParameters;
	
	JobType = JobParameters.JobType;
	SelectionScanned = JobParameters.SelectionScanned;
	DocumentObject = Job.GetObject();
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors;
		SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
		
	ElsIf JobType = "Recalculate" Then
		
		SeriesSpecificationParameters = Documents.InventoryRecount.SeriesSpecificationParameters(DocumentObject);
		
	ElsIf JobType = "PickingCheck" Then
		
		DocumentObject.Status = Enums.GoodsIssueNoteStatuses.ToShip;
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, DataProcessors.GoodsQuantityCheckInDocument);
		
		SeriesSpecificationParameters.NameTSGoods = "ShippedGoods";
		SeriesSpecificationParameters.TSSeriesName = "ShippedGoods";
		
	EndIf;
	
	If JobType = "Filter" Then
		ProductsServer.FillInStatusesForSpecifyingSeries(JobParameters, SeriesSpecificationParameters.Filter);
	ElsIf JobType = "Location" Then
		ProductsServer.FillInStatusesForSpecifyingSeries(JobParameters, SeriesSpecificationParameters.Location);
	ElsIf JobType = "Move" Then
		ProductsServer.FillInStatusesForSpecifyingSeries(JobParameters, SeriesSpecificationParameters.Filter);
		ProductsServer.FillInStatusesForSpecifyingSeries(JobParameters, SeriesSpecificationParameters.Location);
	ElsIf JobType = "Recalculate" Then
		ProductsServer.FillInStatusesForSpecifyingSeries(JobParameters, SeriesSpecificationParameters);
	ElsIf JobType = "PickingCheck" Then
		
		ProductsServer.FillInStatusesForSpecifyingSeries(JobParameters, SeriesSpecificationParameters);
		
		LinesToDelete = New Array;
		ShippedGoods = JobParameters.ShippedGoods;
		
		For Each RowOfProduct In ShippedGoods Do
			
			If RowOfProduct.ThisIsAPackingList
				Or Not (RowOfProduct.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick) Then
				
				LinesToDelete.Add(RowOfProduct);
				
			EndIf;
			
		EndDo;
		
		For Each RowOfProduct In LinesToDelete Do
			JobParameters.ShippedGoods.Delete(RowOfProduct);
		EndDo;
		
		ShippedGoods.Columns.Delete("ThisIsAPackingList");
		
	EndIf;
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		FillInStatusesForSpecifyingSeriesProductsSelectionPlacement(Job, JobParameters);
		
	EndIf;
	
EndProcedure

// The procedure fills in the series indication statuses in the table parts of the 'Parameterization' structure
// of the 'Selection', 'Placement', and 'Move' operations.
//
// Parameters:
//	Job - DocumentRef - warehouse task,
//	JobParameters - See JobParameters
//
Procedure FillInStatusesForSpecifyingSeriesProductsSelectionPlacement(Job, JobParameters)
	
	Query = New Query;
	TaskItems_ = New Structure; // See JobParameters
	Manager = New TempTablesManager;
	
	JobType = JobParameters.JobType;
	
	If JobType = "Filter" Then
		
		Query.SetParameter("GoodsFilter", JobParameters.GoodsFilter);
		
		QueryText =
		"SELECT
		|	Table.LineNumber AS LineNumber,
		|	Table.BatchesIndicationStatus AS BatchesIndicationStatus
		|INTO ProductsSelectionForRequest
		|FROM
		|	&GoodsFilter AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(ProductsSelectionForRequest.LineNumber) AS LineNumber,
		|	GoodsFilter.Cell AS Cell,
		|	GoodsFilter.Cell.Code AS CellCode,
		|	GoodsFilter.Products AS Products,
		|	ISNULL(GoodsFilter.Products.Presentation, """") AS ItemName,
		|	ISNULL(GoodsFilter.Products.SKU, """") AS ProductIDOfItems,
		|	ISNULL(CAST(GoodsFilter.Products.LongDesc AS STRING(1000)), """") AS ItemsDescription,
		|	ISNULL(GoodsFilter.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|	ISNULL(GoodsFilter.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
		|	ISNULL(GoodsFilter.Products.ProductKind.Presentation, """") AS NameOfTypeOfProduct,
		|	GoodsFilter.Characteristic AS Characteristic,
		|	ISNULL(GoodsFilter.Characteristic.Presentation, """") AS ItemVariantName,
		|	GoodsFilter.Series AS Series,
		|	ISNULL(GoodsFilter.Series.Presentation, """") AS BatchName,
		|	ISNULL(GoodsFilter.Series.Number, """") AS BatchNumber,
		|	ISNULL(GoodsFilter.Series.ValidUntil_, DATETIME(1, 1, 1)) AS ValidUntil_,
		|	GoodsFilter.Purpose AS Purpose,
		|	ISNULL(GoodsFilter.Purpose.Presentation, """") AS PurposeDescription,
		|	GoodsFilter.Package AS Package,
		|	ISNULL(GoodsFilter.Package.Presentation, """") AS PackageName,
		|	MIN(ISNULL(&ZoomRatio1, 1)) AS ZoomRatio,
		|	MIN(ISNULL(&ZoomRatio2, 1)) AS FactorOfWeightUnitOfMeasure,
		|	MIN(ISNULL(&ZoomRatio3, 1)) AS FactorOfVolumeUnitOfMeasure,
		|	MIN(&PackageWeight) AS PackageWeight,
		|	MIN(&PackageVolume) AS PackageVolume,
		|	ISNULL(GoodsFilter.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(GoodsFilter.Products.UnitOfMeasure), """") AS UnitOfMeasureDescription,
		|	ISNULL(GoodsFilter.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForWeight,
		|	ISNULL(PRESENTATION(GoodsFilter.Products.WeightUnitOfMeasure), """") AS NameOfWeightUnitOfMeasure,
		|	ISNULL(GoodsFilter.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForVolume,
		|	ISNULL(PRESENTATION(GoodsFilter.Products.VolumeUnitOfMeasure), """") AS NameOfVolumeUnitOfMeasure,
		|	ISNULL(GoodsFilter.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)) AS MeasuredValueType,
		|	SUM(GoodsFilter.Count) AS Count,
		|	SUM(GoodsFilter.CountPicked) AS CountPicked,
		|	SUM(GoodsFilter.NumberOfPackages) AS NumberOfPackages,
		|	SUM(GoodsFilter.NumberOfPackagesPicked) AS NumberOfPackagesPicked,
		|	SUM(GoodsFilter.NumberOfPackages) AS NumberOfPackagesInDocument,
		|	ProductsSelectionForRequest.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	ISNULL(GoodsFilter.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE) AS SpecifyNumberWhenRegisteringBatch,
		|	ISNULL(GoodsFilter.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE) AS UseShelfLifeOnBatchRegistration,
		|	ISNULL(GoodsFilter.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)) AS PrecisionOfBatchShelfLifeIndication
		|FROM
		|	ProductsSelectionForRequest AS ProductsSelectionForRequest
		|		INNER JOIN Document.GoodsPickingPlacement.GoodsFilter AS GoodsFilter
		|		ON ProductsSelectionForRequest.LineNumber = GoodsFilter.LineNumber
		|WHERE
		|	GoodsFilter.Ref = &Job
		|
		|GROUP BY
		|	GoodsFilter.Products,
		|	GoodsFilter.Package,
		|	GoodsFilter.Characteristic,
		|	GoodsFilter.Cell,
		|	GoodsFilter.Series,
		|	ProductsSelectionForRequest.BatchesIndicationStatus,
		|	GoodsFilter.Cell.Code,
		|	ISNULL(GoodsFilter.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE),
		|	ISNULL(GoodsFilter.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE),
		|	ISNULL(GoodsFilter.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.SKU, """"),
		|	ISNULL(CAST(GoodsFilter.Products.LongDesc AS STRING(1000)), """"),
		|	ISNULL(GoodsFilter.Series.ValidUntil_, DATETIME(1, 1, 1)),
		|	GoodsFilter.Purpose,
		|	ISNULL(GoodsFilter.Series.Number, """"),
		|	ISNULL(GoodsFilter.Products.Presentation, """"),
		|	ISNULL(GoodsFilter.Characteristic.Presentation, """"),
		|	ISNULL(GoodsFilter.Purpose.Presentation, """"),
		|	ISNULL(GoodsFilter.Package.Presentation, """"),
		|	ISNULL(GoodsFilter.Series.Presentation, """"),
		|	ISNULL(GoodsFilter.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.ProductKind.Presentation, """"),
		|	ISNULL(PRESENTATION(GoodsFilter.Products.UnitOfMeasure), """"),
		|	ISNULL(PRESENTATION(GoodsFilter.Products.WeightUnitOfMeasure), """"),
		|	ISNULL(PRESENTATION(GoodsFilter.Products.VolumeUnitOfMeasure), """")
		|
		|ORDER BY
		|	GoodsFilter.Cell.TabIndex,
		|	GoodsFilter.Cell.Code,
		|	GoodsFilter.Products.Description,
		|	GoodsFilter.Characteristic,
		|	GoodsFilter.Purpose,
		|	GoodsFilter.Package,
		|	GoodsFilter.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductsSelectionForRequest";
		
		RequestTextForPackagingUnits(QueryText, "GoodsFilter");
		
		SourceOfPackaging = "GoodsFilter.Package";
		SourceOfProducts = "GoodsFilter.Products";
		SourceOfWeightUnit = "GoodsFilter.Products.WeightUnitOfMeasure";
		SourceVolumeUnits = "GoodsFilter.Products.VolumeUnitOfMeasure";
		
		// Substitution "Coefficient 1" - packing coefficient
		QueryText = StrReplace(QueryText, "&ZoomRatio1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfPackaging, SourceOfProducts));
		
		// Substitution "Coefficient 2" - coefficient of the unit of measurement of the weight of the item
		QueryText = StrReplace(QueryText, "&ZoomRatio2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfWeightUnit, Undefined));
		
		// Substitution "Coefficient 3" - coefficient of the unit of measurement of the volume of the nomenclature
		QueryText = StrReplace(QueryText, "&ZoomRatio3",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceVolumeUnits, Undefined));
		
	ElsIf JobType = "Location" Then
		
		Query.SetParameter("GoodsPlacement", JobParameters.GoodsPlacement);
		
		QueryText =
		"SELECT
		|	Table.LineNumber AS LineNumber,
		|	Table.BatchesIndicationStatus AS BatchesIndicationStatus
		|INTO ProductsPlacementForRequest
		|FROM
		|	&GoodsPlacement AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(ProductsPlacementForRequest.LineNumber) AS LineNumber,
		|	GoodsPlacement.Cell AS Cell,
		|	GoodsPlacement.Cell.Code AS CellCode,
		|	GoodsPlacement.Products AS Products,
		|	ISNULL(GoodsPlacement.Products.Presentation, """") AS ItemName,
		|	ISNULL(GoodsPlacement.Products.SKU, """") AS ProductIDOfItems,
		|	ISNULL(CAST(GoodsPlacement.Products.LongDesc AS STRING(1000)), """") AS ItemsDescription,
		|	ISNULL(GoodsPlacement.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|	ISNULL(GoodsPlacement.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
		|	ISNULL(GoodsPlacement.Products.ProductKind.Presentation, """") AS NameOfTypeOfProduct,
		|	GoodsPlacement.Characteristic AS Characteristic,
		|	ISNULL(GoodsPlacement.Characteristic.Presentation, """") AS ItemVariantName,
		|	GoodsPlacement.Series AS Series,
		|	ISNULL(GoodsPlacement.Series.Presentation, """") AS BatchName,
		|	ISNULL(GoodsPlacement.Series.Number, """") AS BatchNumber,
		|	ISNULL(GoodsPlacement.Series.ValidUntil_, DATETIME(1, 1, 1)) AS ValidUntil_,
		|	GoodsPlacement.Purpose AS Purpose,
		|	ISNULL(GoodsPlacement.Purpose.Presentation, """") AS PurposeDescription,
		|	GoodsPlacement.Package AS Package,
		|	ISNULL(GoodsPlacement.Package.Presentation, """") AS PackageName,
		|	MIN(ISNULL(&ZoomRatio1, 1)) AS ZoomRatio,
		|	MIN(ISNULL(&ZoomRatio2, 1)) AS FactorOfWeightUnitOfMeasure,
		|	MIN(ISNULL(&ZoomRatio3, 1)) AS FactorOfVolumeUnitOfMeasure,
		|	MIN(&PackageWeight) AS PackageWeight,
		|	MIN(&PackageVolume) AS PackageVolume,
		|	ISNULL(GoodsPlacement.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.UnitOfMeasure), """") AS UnitOfMeasureDescription,
		|	ISNULL(GoodsPlacement.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForWeight,
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.WeightUnitOfMeasure), """") AS NameOfWeightUnitOfMeasure,
		|	ISNULL(GoodsPlacement.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForVolume,
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.VolumeUnitOfMeasure), """") AS NameOfVolumeUnitOfMeasure,
		|	ISNULL(GoodsPlacement.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)) AS MeasuredValueType,
		|	SUM(GoodsPlacement.Count) AS Count,
		|	SUM(GoodsPlacement.CountPlaced) AS CountPlaced,
		|	SUM(GoodsPlacement.NumberOfPackages) AS NumberOfPackages,
		|	SUM(GoodsPlacement.NumberOfPackagesPlaced) AS NumberOfPackagesPlaced,
		|	SUM(GoodsPlacement.NumberOfPackages) AS NumberOfPackagesInDocument,
		|	ProductsPlacementForRequest.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	ISNULL(GoodsPlacement.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE) AS SpecifyNumberWhenRegisteringBatch,
		|	ISNULL(GoodsPlacement.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE) AS UseShelfLifeOnBatchRegistration,
		|	ISNULL(GoodsPlacement.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)) AS PrecisionOfBatchShelfLifeIndication
		|FROM
		|	ProductsPlacementForRequest AS ProductsPlacementForRequest
		|		INNER JOIN Document.GoodsPickingPlacement.GoodsPlacement AS GoodsPlacement
		|		ON ProductsPlacementForRequest.LineNumber = GoodsPlacement.LineNumber
		|WHERE
		|	GoodsPlacement.Ref = &Job
		|
		|GROUP BY
		|	GoodsPlacement.Products,
		|	GoodsPlacement.Package,
		|	GoodsPlacement.Characteristic,
		|	GoodsPlacement.Cell,
		|	GoodsPlacement.Series,
		|	ProductsPlacementForRequest.BatchesIndicationStatus,
		|	GoodsPlacement.Cell.Code,
		|	ISNULL(GoodsPlacement.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE),
		|	ISNULL(GoodsPlacement.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE),
		|	ISNULL(GoodsPlacement.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.SKU, """"),
		|	ISNULL(CAST(GoodsPlacement.Products.LongDesc AS STRING(1000)), """"),
		|	ISNULL(GoodsPlacement.Series.ValidUntil_, DATETIME(1, 1, 1)),
		|	GoodsPlacement.Purpose,
		|	ISNULL(GoodsPlacement.Series.Number, """"),
		|	ISNULL(GoodsPlacement.Products.Presentation, """"),
		|	ISNULL(GoodsPlacement.Characteristic.Presentation, """"),
		|	ISNULL(GoodsPlacement.Purpose.Presentation, """"),
		|	ISNULL(GoodsPlacement.Package.Presentation, """"),
		|	ISNULL(GoodsPlacement.Series.Presentation, """"),
		|	ISNULL(GoodsPlacement.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.ProductKind.Presentation, """"),
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.UnitOfMeasure), """"),
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.WeightUnitOfMeasure), """"),
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.VolumeUnitOfMeasure), """")
		|
		|ORDER BY
		|	GoodsPlacement.Cell.TabIndex,
		|	GoodsPlacement.Cell.Code,
		|	GoodsPlacement.Products.Description,
		|	GoodsPlacement.Characteristic,
		|	GoodsPlacement.Purpose,
		|	GoodsPlacement.Package,
		|	GoodsPlacement.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductsPlacementForRequest";
		
		RequestTextForPackagingUnits(QueryText, "GoodsPlacement");
		
		SourceOfPackaging = "GoodsPlacement.Package";
		SourceOfProducts = "GoodsPlacement.Products";
		SourceOfWeightUnit = "GoodsPlacement.Products.WeightUnitOfMeasure";
		SourceVolumeUnits = "GoodsPlacement.Products.VolumeUnitOfMeasure";
		
		// Substitution "Coefficient 1" - packing coefficient
		QueryText = StrReplace(QueryText, "&ZoomRatio1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfPackaging, SourceOfProducts));
		
		// Substitution "Coefficient 2" - coefficient of the unit of measurement of the weight of the item
		QueryText = StrReplace(QueryText, "&ZoomRatio2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfWeightUnit, Undefined));
		
		// Substitution "Coefficient 3" - coefficient of the unit of measurement of the volume of the nomenclature
		QueryText = StrReplace(QueryText, "&ZoomRatio3",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceVolumeUnits, Undefined));
		
	ElsIf JobType = "Move" Then
		
		Query.SetParameter("GoodsFilter", JobParameters.GoodsFilter);
		Query.SetParameter("GoodsPlacement", JobParameters.GoodsPlacement);
		
		QueryText =
		"SELECT
		|	Table.LineNumber AS LineNumber,
		|	Table.BatchesIndicationStatus AS BatchesIndicationStatus
		|INTO ProductsSelectionForRequest
		|FROM
		|	&GoodsFilter AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(ProductsSelectionForRequest.LineNumber) AS LineNumber,
		|	GoodsFilter.Cell AS Cell,
		|	GoodsFilter.Cell.Code AS CellCode,
		|	GoodsFilter.Products AS Products,
		|	ISNULL(GoodsFilter.Products.Presentation, """") AS ItemName,
		|	ISNULL(GoodsFilter.Products.SKU, """") AS ProductIDOfItems,
		|	ISNULL(CAST(GoodsFilter.Products.LongDesc AS STRING(1000)), """") AS ItemsDescription,
		|	ISNULL(GoodsFilter.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|	ISNULL(GoodsFilter.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
		|	ISNULL(GoodsFilter.Products.ProductKind.Presentation, """") AS NameOfTypeOfProduct,
		|	GoodsFilter.Characteristic AS Characteristic,
		|	ISNULL(GoodsFilter.Characteristic.Presentation, """") AS ItemVariantName,
		|	GoodsFilter.Series AS Series,
		|	ISNULL(GoodsFilter.Series.Presentation, """") AS BatchName,
		|	ISNULL(GoodsFilter.Series.Number, """") AS BatchNumber,
		|	ISNULL(GoodsFilter.Series.ValidUntil_, DATETIME(1, 1, 1)) AS ValidUntil_,
		|	GoodsFilter.Purpose AS Purpose,
		|	ISNULL(GoodsFilter.Purpose.Presentation, """") AS PurposeDescription,
		|	GoodsFilter.Package AS Package,
		|	ISNULL(GoodsFilter.Package.Presentation, """") AS PackageName,
		|	MIN(ISNULL(&ZoomRatio1, 1)) AS ZoomRatio,
		|	MIN(ISNULL(&ZoomRatio2, 1)) AS FactorOfWeightUnitOfMeasure,
		|	MIN(ISNULL(&ZoomRatio3, 1)) AS FactorOfVolumeUnitOfMeasure,
		|	MIN(&PackageWeight1) AS PackageWeight,
		|	MIN(&PackageVolume1) AS PackageVolume,
		|	ISNULL(GoodsFilter.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(GoodsFilter.Products.UnitOfMeasure), """") AS UnitOfMeasureDescription,
		|	ISNULL(GoodsFilter.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForWeight,
		|	ISNULL(PRESENTATION(GoodsFilter.Products.WeightUnitOfMeasure), """") AS NameOfWeightUnitOfMeasure,
		|	ISNULL(GoodsFilter.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForVolume,
		|	ISNULL(PRESENTATION(GoodsFilter.Products.VolumeUnitOfMeasure), """") AS NameOfVolumeUnitOfMeasure,
		|	ISNULL(GoodsFilter.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)) AS MeasuredValueType,
		|	SUM(GoodsFilter.Count) AS Count,
		|	SUM(GoodsFilter.CountPicked) AS CountPicked,
		|	SUM(GoodsFilter.NumberOfPackages) AS NumberOfPackages,
		|	SUM(GoodsFilter.NumberOfPackagesPicked) AS NumberOfPackagesPicked,
		|	SUM(GoodsFilter.NumberOfPackages) AS NumberOfPackagesInDocument,
		|	ProductsSelectionForRequest.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	ISNULL(GoodsFilter.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE) AS SpecifyNumberWhenRegisteringBatch,
		|	ISNULL(GoodsFilter.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE) AS UseShelfLifeOnBatchRegistration,
		|	ISNULL(GoodsFilter.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)) AS PrecisionOfBatchShelfLifeIndication
		|FROM
		|	ProductsSelectionForRequest AS ProductsSelectionForRequest
		|		INNER JOIN Document.GoodsPickingPlacement.GoodsFilter AS GoodsFilter
		|		ON ProductsSelectionForRequest.LineNumber = GoodsFilter.LineNumber
		|WHERE
		|	GoodsFilter.Ref = &Job
		|
		|GROUP BY
		|	GoodsFilter.Products,
		|	GoodsFilter.Package,
		|	GoodsFilter.Characteristic,
		|	GoodsFilter.Cell,
		|	GoodsFilter.Series,
		|	ProductsSelectionForRequest.BatchesIndicationStatus,
		|	GoodsFilter.Cell.Code,
		|	ISNULL(GoodsFilter.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE),
		|	ISNULL(GoodsFilter.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE),
		|	ISNULL(GoodsFilter.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.SKU, """"),
		|	ISNULL(CAST(GoodsFilter.Products.LongDesc AS STRING(1000)), """"),
		|	ISNULL(GoodsFilter.Series.ValidUntil_, DATETIME(1, 1, 1)),
		|	GoodsFilter.Purpose,
		|	ISNULL(GoodsFilter.Series.Number, """"),
		|	ISNULL(GoodsFilter.Products.Presentation, """"),
		|	ISNULL(GoodsFilter.Characteristic.Presentation, """"),
		|	ISNULL(GoodsFilter.Purpose.Presentation, """"),
		|	ISNULL(GoodsFilter.Package.Presentation, """"),
		|	ISNULL(GoodsFilter.Series.Presentation, """"),
		|	ISNULL(GoodsFilter.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)),
		|	ISNULL(GoodsFilter.Products.ProductKind.Presentation, """"),
		|	ISNULL(PRESENTATION(GoodsFilter.Products.UnitOfMeasure), """"),
		|	ISNULL(PRESENTATION(GoodsFilter.Products.WeightUnitOfMeasure), """"),
		|	ISNULL(PRESENTATION(GoodsFilter.Products.VolumeUnitOfMeasure), """")
		|
		|ORDER BY
		|	GoodsFilter.Cell.TabIndex,
		|	GoodsFilter.Cell.Code,
		|	GoodsFilter.Products.Description,
		|	GoodsFilter.Characteristic,
		|	GoodsFilter.Purpose,
		|	GoodsFilter.Package,
		|	GoodsFilter.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductsSelectionForRequest
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.LineNumber AS LineNumber,
		|	Table.BatchesIndicationStatus AS BatchesIndicationStatus
		|INTO ProductsPlacementForRequest
		|FROM
		|	&GoodsPlacement AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(ProductsPlacementForRequest.LineNumber) AS LineNumber,
		|	GoodsPlacement.Cell AS Cell,
		|	GoodsPlacement.Cell.Code AS CellCode,
		|	GoodsPlacement.Products AS Products,
		|	ISNULL(GoodsPlacement.Products.Presentation, """") AS ItemName,
		|	ISNULL(GoodsPlacement.Products.SKU, """") AS ProductIDOfItems,
		|	ISNULL(CAST(GoodsPlacement.Products.LongDesc AS STRING(1000)), """") AS ItemsDescription,
		|	ISNULL(GoodsPlacement.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|	ISNULL(GoodsPlacement.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
		|	ISNULL(GoodsPlacement.Products.ProductKind.Presentation, """") AS NameOfTypeOfProduct,
		|	GoodsPlacement.Characteristic AS Characteristic,
		|	ISNULL(GoodsPlacement.Characteristic.Presentation, """") AS ItemVariantName,
		|	GoodsPlacement.Series AS Series,
		|	ISNULL(GoodsPlacement.Series.Presentation, """") AS BatchName,
		|	ISNULL(GoodsPlacement.Series.Number, """") AS BatchNumber,
		|	ISNULL(GoodsPlacement.Series.ValidUntil_, DATETIME(1, 1, 1)) AS ValidUntil_,
		|	GoodsPlacement.Purpose AS Purpose,
		|	ISNULL(GoodsPlacement.Purpose.Presentation, """") AS PurposeDescription,
		|	GoodsPlacement.Package AS Package,
		|	ISNULL(GoodsPlacement.Package.Presentation, """") AS PackageName,
		|	MIN(ISNULL(&ZoomRatio4, 1)) AS ZoomRatio,
		|	MIN(ISNULL(&ZoomRatio5, 1)) AS FactorOfWeightUnitOfMeasure,
		|	MIN(ISNULL(&ZoomRatio6, 1)) AS FactorOfVolumeUnitOfMeasure,
		|	MIN(&PackageWeight2) AS PackageWeight,
		|	MIN(&PackageVolume2) AS PackageVolume,
		|	ISNULL(GoodsPlacement.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.UnitOfMeasure), """") AS UnitOfMeasureDescription,
		|	ISNULL(GoodsPlacement.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForWeight,
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.WeightUnitOfMeasure), """") AS NameOfWeightUnitOfMeasure,
		|	ISNULL(GoodsPlacement.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasureForVolume,
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.VolumeUnitOfMeasure), """") AS NameOfVolumeUnitOfMeasure,
		|	ISNULL(GoodsPlacement.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)) AS MeasuredValueType,
		|	SUM(GoodsPlacement.Count) AS Count,
		|	SUM(GoodsPlacement.CountPlaced) AS CountPlaced,
		|	SUM(GoodsPlacement.NumberOfPackages) AS NumberOfPackages,
		|	SUM(GoodsPlacement.NumberOfPackagesPlaced) AS NumberOfPackagesPlaced,
		|	SUM(GoodsPlacement.NumberOfPackages) AS NumberOfPackagesInDocument,
		|	ProductsPlacementForRequest.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	ISNULL(GoodsPlacement.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE) AS SpecifyNumberWhenRegisteringBatch,
		|	ISNULL(GoodsPlacement.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE) AS UseShelfLifeOnBatchRegistration,
		|	ISNULL(GoodsPlacement.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)) AS PrecisionOfBatchShelfLifeIndication
		|FROM
		|	ProductsPlacementForRequest AS ProductsPlacementForRequest
		|		INNER JOIN Document.GoodsPickingPlacement.GoodsPlacement AS GoodsPlacement
		|		ON ProductsPlacementForRequest.LineNumber = GoodsPlacement.LineNumber
		|WHERE
		|	GoodsPlacement.Ref = &Job
		|
		|GROUP BY
		|	GoodsPlacement.Products,
		|	GoodsPlacement.Package,
		|	GoodsPlacement.Characteristic,
		|	GoodsPlacement.Cell,
		|	GoodsPlacement.Series,
		|	ProductsPlacementForRequest.BatchesIndicationStatus,
		|	GoodsPlacement.Cell.Code,
		|	ISNULL(GoodsPlacement.Products.ProductKind.SpecifyNumberWhenRegisteringBatch, FALSE),
		|	ISNULL(GoodsPlacement.Products.ProductKind.PrecisionOfBatchShelfLifeIndication, VALUE(Enum.AccuracyOfShelfLifeIndication.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.ProductKind.UseShelfLifeOnBatchRegistration, FALSE),
		|	ISNULL(GoodsPlacement.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.SKU, """"),
		|	ISNULL(CAST(GoodsPlacement.Products.LongDesc AS STRING(1000)), """"),
		|	ISNULL(GoodsPlacement.Series.ValidUntil_, DATETIME(1, 1, 1)),
		|	GoodsPlacement.Purpose,
		|	ISNULL(GoodsPlacement.Series.Number, """"),
		|	ISNULL(GoodsPlacement.Products.Presentation, """"),
		|	ISNULL(GoodsPlacement.Characteristic.Presentation, """"),
		|	ISNULL(GoodsPlacement.Purpose.Presentation, """"),
		|	ISNULL(GoodsPlacement.Package.Presentation, """"),
		|	ISNULL(GoodsPlacement.Series.Presentation, """"),
		|	ISNULL(GoodsPlacement.Products.UnitOfMeasure.MeasuredValueType, VALUE(Enum.TypesOfMeasuredValues.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.VolumeUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.ProductKind.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)),
		|	ISNULL(GoodsPlacement.Products.ProductKind.Presentation, """"),
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.UnitOfMeasure), """"),
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.WeightUnitOfMeasure), """"),
		|	ISNULL(PRESENTATION(GoodsPlacement.Products.VolumeUnitOfMeasure), """")
		|
		|ORDER BY
		|	GoodsPlacement.Cell.TabIndex,
		|	GoodsPlacement.Cell.Code,
		|	GoodsPlacement.Products.Description,
		|	GoodsPlacement.Characteristic,
		|	GoodsPlacement.Purpose,
		|	GoodsPlacement.Package,
		|	GoodsPlacement.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductsPlacementForRequest";
		
		RequestTextForPackagingUnits(QueryText, "GoodsFilter", 1);
		RequestTextForPackagingUnits(QueryText, "GoodsPlacement", 2);
		
		SourceOfPackaging = "GoodsFilter.Package";
		SourceOfProducts = "GoodsFilter.Products";
		SourceOfWeightUnit = "GoodsFilter.Products.WeightUnitOfMeasure";
		SourceVolumeUnits = "GoodsFilter.Products.VolumeUnitOfMeasure";
		
		// Substitution "Coefficient 1" - packing coefficient
		QueryText = StrReplace(QueryText, "&ZoomRatio1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfPackaging, SourceOfProducts));
		
		// Substitution "Coefficient 2" - coefficient of the unit of measurement of the weight of the item
		QueryText = StrReplace(QueryText, "&ZoomRatio2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfWeightUnit, Undefined));
		
		// Substitution "Coefficient 3" - coefficient of the unit of measurement of the volume of the nomenclature
		QueryText = StrReplace(QueryText, "&ZoomRatio3",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceVolumeUnits, Undefined));
		
		SourceOfPackaging = "GoodsPlacement.Package";
		SourceOfProducts = "GoodsPlacement.Products";
		SourceOfWeightUnit = "GoodsPlacement.Products.WeightUnitOfMeasure";
		SourceVolumeUnits = "GoodsPlacement.Products.VolumeUnitOfMeasure";
		
		// Substitution "Coefficient 4" - packing coefficient
		QueryText = StrReplace(QueryText, "&ZoomRatio4",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfPackaging, SourceOfProducts));
		
		// Substitution "Coefficient 5" - coefficient of the unit of measurement of the weight of the item
		QueryText = StrReplace(QueryText, "&ZoomRatio5",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfWeightUnit, Undefined));
		
		// Substitution "Coefficient 6" - coefficient of the unit of measurement of the volume of the nomenclature
		QueryText = StrReplace(QueryText, "&ZoomRatio6",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceVolumeUnits, Undefined));
		
	EndIf;
	
	Query.Text = QueryText;
	Query.TempTablesManager = Manager;
	Query.SetParameter("Job", Job);
	
	QueryResult = Query.ExecuteBatch();
	Manager.Close();
	
	If JobType = "Filter" Then
		TaskItems_.Insert("GoodsFilter", QueryResult[1].Unload());
	ElsIf JobType = "Location" Then
		TaskItems_.Insert("GoodsPlacement", QueryResult[1].Unload());
	ElsIf JobType = "Move" Then
		TaskItems_.Insert("GoodsFilter", QueryResult[1].Unload());
		TaskItems_.Insert("GoodsPlacement", QueryResult[4].Unload());
	EndIf;
	
	TypeRowWKCells = New TypeDescription("String", , New StringQualifiers(50));
	TypeStringOfProductList = New TypeDescription("String", , New StringQualifiers(360));
	
	BarcodeSelectionParameters = InformationRegisters.ItemsBarcodes.DefaultParametersForSelectingItemBarcodes();
	
	For Each TableOfGoods In TaskItems_ Do
		Table = TableOfGoods.Value; // ValueTable
		
		Table.Columns.Add("CellBarcode", TypeRowWKCells);
		Table.Columns.Add("ItemsBarcode", TypeStringOfProductList);
		
		For Each RowOfGoods In Table Do
			RowOfGoods.CellBarcode = BarcodingOfPrintForms.NumericCodeFromLink(RowOfGoods.Cell);
			
			FillPropertyValues(BarcodeSelectionParameters, RowOfGoods);
			
			ItemsBarcodes = InformationRegisters.ItemsBarcodes.ItemsBarcodes(
										BarcodeSelectionParameters);
			
			If ValueIsFilled(RowOfGoods.Package)
				And ItemsBarcodes.Count() = 0
				And Not (RowOfGoods.MeasuredValueType = Enums.TypesOfMeasuredValues.Weight
					Or RowOfGoods.MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3
					Or RowOfGoods.MeasuredValueType = Enums.TypesOfMeasuredValues.Length
					Or RowOfGoods.MeasuredValueType = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement) Then
				
				BarcodeSelectionParameters.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				
				ItemsBarcodes = InformationRegisters.ItemsBarcodes.ItemsBarcodes(
											BarcodeSelectionParameters);
				
			EndIf;
			
			If ItemsBarcodes.Count() > 0 Then
				RowOfGoods.ItemsBarcode = StrConcat(ItemsBarcodes, ", ");
			EndIf;
		EndDo;
	EndDo;
	
	FillPropertyValues(JobParameters, TaskItems_);
	
EndProcedure

// The procedure fills in the query text the query text details measuring units
// directory "Opakowaniowej".
//
// Parameters:
//	QueryText - String,
//	TableName - String - PM name in the request text,
//	ParameterNumber - String - number of the parameter to replace in the request text.
//
Procedure RequestTextForPackagingUnits(QueryText, TableName, ParameterNumber = "")
	
	SourceOfPackaging = TableName + ".Package";
	SourceOfProducts = TableName + ".Products";
	
	// Substitution of "Weight"
	QueryText = StrReplace(QueryText, "&PackageWeight" + ParameterNumber,
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(SourceOfPackaging, SourceOfProducts, False));
	
	// Substitution of "Volume"
	QueryText = StrReplace(QueryText, "&PackageVolume" + ParameterNumber,
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(SourceOfPackaging, SourceOfProducts, False));
	
EndProcedure

// Returns a structure for storing product information.
//
// Returns:
// 	Structure - description of the value of the scanned product, which contains the following fields:
//	* PackingList - DocumentRef.PackingList - packing list that includes the product.
//	* ThisIsAPackingList - Boolean - True if the product is used as a packing list.
//	* MeasuredValueType - EnumRef.TypesOfMeasuredValues - type measured veocine product.
//	* NameOfVolumeUnitOfMeasure - String - representation of the unit of measurement for the product volume.
//	* UnitOfMeasureForVolume - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement for the product volume.
//	* NameOfWeightUnitOfMeasure - String - representation of the unit of measurement for the product weight.
//	* UnitOfMeasureForWeight - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement for the product weight.
//	* UnitOfMeasureDescription - String - representation of the product's unit of measurement.
//	* UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement of the product.
//	* PackageVolume - Number - value of the product packaging volume.
//	* PackageWeight - Number - value of the product package weight.
//	* FactorOfVolumeUnitOfMeasure - Number - the ratio of the volume of product packaging.
//	* FactorOfWeightUnitOfMeasure - Number - the weight ratio of the product packaging.
//	* ZoomRatio - Number - product packaging coefficient.
//	* PackageName - String - the idea of packaging the product.
//	* Package - CatalogRef.PackagesAndUnitsOfMeasure - packing.
//	* PurposeDescription - String - presentation of information about product separation.
//	* Purpose - CatalogRef.Assignments - information about the product separation.
//	* PrecisionOfBatchShelfLifeIndication - EnumRef.AccuracyOfShelfLifeIndication - accuracy of the period of use of the product series.
//	* UseShelfLifeOnBatchRegistration - Boolean - True if information about the expiration date of the product series is used.
//	* SpecifyNumberWhenRegisteringBatch - Boolean - True if series accounting is used in the context of numbers.
//	* ValidUntil_ - Date - expiration date of the product series.
//	* BatchNumber - String - serial number.
//	* BatchName - String - presentation of the product series.
//	* Series - CatalogRef.ItemsBatches - product series.
//	* ItemVariantName - String - the performance characteristics of the goods.
//	* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//	* ItemsType - EnumRef.ItemsTypes - type of goods.
//	* ProductKind - CatalogRef.ItemKinds - type of goods.
//	* QuantityByBarcode - Number - the quantity of the product that is contained in its barcode information.
//	* Barcode - String - the barcode of the product.
//	* ItemsDescription - String - information about the product.
//	* ProductIDOfItems - String - item number.
//	* ItemName - String - presentation of the product.
//	* Products - CatalogRef.Products - product.
//	* MessageText - String - message to the user about errors detected when scanning the product barcode.
//	* ErrorType - String - error type scan the barcode of the product.
//	* ReturnCode - Number - code of the product information search result. 1-the product is specified correctly.
//
Function ProductParameters_1()
	
	ProductParameters_1 = New Structure;
	
	ProductParameters_1.Insert("ReturnCode", 1);
	ProductParameters_1.Insert("ErrorType", "");
	ProductParameters_1.Insert("MessageText", "");
	
	ProductParameters_1.Insert("Products", Catalogs.Products.EmptyRef());
	ProductParameters_1.Insert("ItemName", "");
	ProductParameters_1.Insert("ProductIDOfItems", "");
	ProductParameters_1.Insert("ItemsDescription", "");
	
	ProductParameters_1.Insert("Barcode", ""); // To save barcodes during acceptance
	ProductParameters_1.Insert("QuantityByBarcode", 0);
	
	ProductParameters_1.Insert("ProductKind", Catalogs.ItemKinds.EmptyRef());
	ProductParameters_1.Insert("ItemsType", Enums.ItemsTypes.EmptyRef());
	
	ProductParameters_1.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	ProductParameters_1.Insert("ItemVariantName", "");
	
	ProductParameters_1.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	ProductParameters_1.Insert("BatchName", "");
	ProductParameters_1.Insert("BatchNumber", "");
	ProductParameters_1.Insert("ValidUntil_", Date("00010101"));
	
	ProductParameters_1.Insert("SpecifyNumberWhenRegisteringBatch", False);
	ProductParameters_1.Insert("UseShelfLifeOnBatchRegistration", False);
	ProductParameters_1.Insert("PrecisionOfBatchShelfLifeIndication",
		Enums.AccuracyOfShelfLifeIndication.EmptyRef());
	
	ProductParameters_1.Insert("Purpose", Catalogs.Assignments.EmptyRef());
	ProductParameters_1.Insert("PurposeDescription", "");
	
	ProductParameters_1.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	ProductParameters_1.Insert("PackageName", "");
	
	ProductParameters_1.Insert("ZoomRatio", 0);
	ProductParameters_1.Insert("FactorOfWeightUnitOfMeasure", 0);
	ProductParameters_1.Insert("FactorOfVolumeUnitOfMeasure", 0);
	
	ProductParameters_1.Insert("PackageWeight", 0);
	ProductParameters_1.Insert("PackageVolume", 0);
	
	ProductParameters_1.Insert("UnitOfMeasure", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	ProductParameters_1.Insert("UnitOfMeasureDescription", "");
	ProductParameters_1.Insert("UnitOfMeasureForWeight", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	ProductParameters_1.Insert("NameOfWeightUnitOfMeasure", "");
	ProductParameters_1.Insert("UnitOfMeasureForVolume", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	ProductParameters_1.Insert("NameOfVolumeUnitOfMeasure", "");
	ProductParameters_1.Insert("MeasuredValueType", Enums.TypesOfMeasuredValues.EmptyRef());
	
	ProductParameters_1.Insert("ThisIsAPackingList", False);
	ProductParameters_1.Insert("PackingList", Documents.PackingList.EmptyRef());
	
	Return ProductParameters_1;
	
EndFunction

// Checks the result returned by the 'result Registers' function.Barcodes of the nomenclature.Get the data for the barcode()'.
// If there is no barcode match or the product parameter structure does not contain fields, then it is assumed
// that the barcode search did not find anything.
//
// Parameters:
//	Barcode - String - product barcode
//	BarcodeData_ - See InformationRegisters.ItemsBarcodes.GetBarcodeData
//
// Returns:
//	Boolean - True - the product was not found by barcode, False - found.
//
Function ProductNotFound_(Barcode, BarcodeData_)
	
	ProductBarcodeData = BarcodeData_.Get(Barcode);
	
	If ProductBarcodeData = Undefined Then
		Return True;
	EndIf;
	
	If TypeOf(ProductBarcodeData) = Type("Structure") Then
		If ProductBarcodeData.UnknownBarcode Then
			Return True;
		EndIf;
	Else
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Returns a structure for storing information about the series.
// 
// Returns:
// 	Structure - description of the value of the scanned product series, which contains the following fields:
//	* ValidUntil_ - Date - expiration date of the product series.
//	* BatchNumber - String - the batch number of the product.
//	* Series - CatalogRef.ItemsBatches - link to the product series in the information base.
//	* MessageText - String - message to the user about the results of specifying the product series.
//	* ErrorType - String - ID of the type of error in specifying the product series.
//	* ReturnCode - Number - code of the search result for information about the product series. 1 - the product series is specified correctly.
//
Function SeriesParameters()
	
	SeriesParameters = New Structure();
	
	SeriesParameters.Insert("ReturnCode", 1);
	SeriesParameters.Insert("ErrorType", "");
	SeriesParameters.Insert("MessageText", "");
	
	SeriesParameters.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	SeriesParameters.Insert("BatchNumber", "");
	SeriesParameters.Insert("ValidUntil_", Date("00010101"));
	
	Return SeriesParameters;
	
EndFunction

// Checks whether the manually entered batch expiration date is correct.
//
// Parameters:
//	SeriesIndicationParameters - Structure
//	ExpirationDateByString - String - expiration date of the series by line
//	ExpirationDate_ - Undefined - the variable in which the expiration date received is written, from the string
//
// Returns:
//	Boolean - True - the expiration date is correct, False - not.
//
Function ShelfLifeOfSeriesIsCorrect(SeriesIndicationParameters, Val ExpirationDateByString, ExpirationDate_ = Undefined)
	
	DateAsString = "";
	ExpirationDateByString = TrimAll(ExpirationDateByString);
	
	If SeriesIndicationParameters.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
		// MM.yy
		DateAsString = "20" + Right(ExpirationDateByString, 2) + Left(ExpirationDateByString, 2) + "00000000";
	ElsIf SeriesIndicationParameters.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToDays Then
		// dd.MM.yy
		DateAsString = "20" + Right(ExpirationDateByString, 2) + Mid(ExpirationDateByString, 4, 2)
			+ Left(ExpirationDateByString, 2) + "000000";
	ElsIf SeriesIndicationParameters.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
		// dd.MM.yy-HH
		DateAsString = "20" + Mid(ExpirationDateByString, 7, 2) + Mid(ExpirationDateByString, 4, 2) + Left(ExpirationDateByString, 2)
			+ Right(ExpirationDateByString, 2) + "0000";
	EndIf;
	
	Try
		ExpirationDate_ = Date(DateAsString);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Recalculates the number of product balances by destination, in accordance with the dimension of the container
// in which the product is taken into account.
//
// Parameters:
//	Assignments - ValueTable - stores data on the remaining balance of the specified product by destination.
//	OwnGoods - CatalogRef.Products - the item for which balances are recalculated.
//	DeleteEmptyRows - Boolean
//
Procedure RecalculateBalancesByDestination(Assignments, OwnGoods, DeleteEmptyRows = False)
	
	If OwnGoods.ItemsType = Enums.ItemsTypes.ReusablePackage Then
		Return
	EndIf;
	
	If OwnGoods.ZoomRatio <> 0 Then
		ZoomRatio = OwnGoods.ZoomRatio;
	Else
		ZoomRatio = 1;
	EndIf;
	
	LinesToDelete = New Array;
	
	For Each String In Assignments Do
		String.Balance = Round(String.Balance / ZoomRatio, 0, 0);
		
		If String.Balance = 0 Then
			LinesToDelete.Add(String);
		EndIf;
	EndDo;
	
	If DeleteEmptyRows Then
		For Each RowToDelete In LinesToDelete Do
			Assignments.Delete(RowToDelete);
		EndDo;
	EndIf;
	
EndProcedure

// Sets the initial status of the warehouse task.
//
// Parameters:
//	Job - DocumentRef - warehouse task link,
//	JobType - String - type of warehouse tasks,
//	JobParameters - See JobParameters
//
Procedure SetInitialStatusOfWarehouseTask(Job, JobType, JobParameters)
	
	InitialStatus = InitialStatusOfWarehouseTask(JobType);
	
	Try
		DocumentObject = Job.GetObject();
		DocumentObject.Status = InitialStatus;
		
		WriteMode = ?(DocumentObject.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write);
		DocumentObject.Write(WriteMode);
	Except
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi thiết lập trạng thái nguồn của nhiệm vụ kho đã xảy ra lỗi. Mô tả lỗi: ""%1""';
				|ru = 'При установке исходного статуса складского задания произошла ошибка. Описание ошибки: ""%1""';
				|en = 'An error occurred when setting an original status of the warehouse task. Error description: ""%1""'; fa = 'An error occurred when setting an original status of the warehouse task. Error description: ""%1""';
				|it = 'Si è verificato un errore durante l''impostazione dello stato originale del task di magazzino. Descrizione dell''errore: ""%1""';
				|pl = 'Przy ustawieniu pierwotnego stanu zadania magazynowego wystąpił błąd. Opis błędu: ""%1""';
				|tr = 'Ambar görevinin başlangıç ​​durumu ayarlanırken hata oluştu. Hata Açıklaması: ""%1""'"),
			ErrorInfo().Description);
		
		// Add an error entry to the log.
		WriteLogEvent(
			NStr("vi = 'Đã xảy ra lỗi trong khi đặt trạng thái nguồn của nhiệm vụ kho.';
				|ru = 'Ошибка при установке исходного статуса складского задания.';
				|en = 'An error occurred while setting an original status of the warehouse task.'; fa = 'An error occurred while setting an original status of the warehouse task.';
				|it = 'Errore durante l''impostazione dello stato originale del task di magazzino.';
				|pl = 'Wystąpił błąd przy ustawieniu pierwotnego statusu zadania magazynowego.';
				|tr = 'Ambar görevinin başlangıç ​​durumu ayarlanırken hata.'",
				CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Job.Metadata(),
			Job,
			JobParameters.MessageText,
			EventLogEntryTransactionMode.Transactional);
	EndTry;
	
EndProcedure

// Sets the original contractor for the warehouse task when it is canceled.
//
// Parameters:
//	Job - DocumentRef - warehouse task link,
//	SourceExecutor - CatalogRef.Users - source performer of the warehouse task,
//	JobParameters - See JobParameters
//
Procedure InstallOriginalWarehouseTaskExecutor(Job, SourceExecutor, JobParameters)
	
	Try
		DocumentObject = Job.GetObject();
		
		If TMCommonUseClientServer.HasObjectAttribute(DocumentObject, "Performer") Then
			DocumentObject.Performer = SourceExecutor;
		EndIf;
		
		If TMCommonUseClientServer.HasObjectAttribute(DocumentObject, "Inspector") Then
			DocumentObject.Inspector = SourceExecutor;
		EndIf;
		
		WriteMode = ?(DocumentObject.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write);
		DocumentObject.Write(WriteMode);
	Except
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi đặt người thực hiện vào nhiệm vụ kho, đã xảy ra lỗi. Mô tả lỗi: ""%1""';
				|ru = 'При установке исходного исполнителя складского задания произошла ошибка. Описание ошибки: ""%1""';
				|en = 'An error occurred when setting an original assignee of the warehouse task. Error description: ""%1""'; fa = 'An error occurred when setting an original assignee of the warehouse task. Error description: ""%1""';
				|it = 'Si è verificato un errore durante l''impostazione del esecutore iniziale del task di magazzino. Descrizione dell''errore: ""%1""';
				|pl = 'Przy ustawieniu pierwotnego wykonawcy zadania magazynowego wystąpił błąd. Opis błędu: ""%1""';
				|tr = 'Ambar görevinin başlangıç ​​durumu ayarlanırken hata oluştu. Hata ayrıntıları: ""%1""'"),
			ErrorInfo().Description);
		
		// Add an error entry to the log.
		WriteLogEvent(
			NStr("vi = 'Đã xảy ra lỗi trong khi đặt thực hiện nguồn của nhiệm vụ kho.';
				|ru = 'Ошибка при установке исходного исполнителя складского задания.';
				|en = 'An error occurred while setting an original assignee of the warehouse task.'; fa = 'An error occurred while setting an original assignee of the warehouse task.';
				|it = 'Errore durante l''impostazione dell''esecutore iniziale del task di magazzino.';
				|pl = 'Wystąpił błąd przy ustawieniu pierwotnego wykonawcy zadania magazynowego.';
				|tr = 'Ambar görevinin başlangıç ​​durumu ayarlanırken hata.'",
				CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Job.Metadata(),
			Job,
			JobParameters.MessageText,
			EventLogEntryTransactionMode.Transactional);
	EndTry;
	
EndProcedure

// Removes the lock on cells in the item recalculation task.
//
// Parameters:
//	Job - DocumentRef - warehouse task link,
//	JobParameters - See JobParameters
//
Procedure SetCellLockValueInRecalculationTask(Job, JobParameters)
	
	Try
		DocumentObject = Job.GetObject();
		DocumentObject.LockStorageBins = False;
		
		WriteMode = ?(DocumentObject.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write);
		DocumentObject.Write(WriteMode);
	Except
		JobParameters.ReturnCode = 0;
		JobParameters.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi bỏ phong tỏa ô hàng, đã xảy ra lỗi. Mô tả lỗi: ""%1""';
				|ru = 'При снятии блокировок ячеек произошла ошибка. Описание ошибки: ""%1""';
				|en = 'An error occurred while unlocking the bins. The error details: ""%1""'; fa = 'An error occurred while unlocking the bins. The error details: ""%1""';
				|it = 'Si è verificato un errore durante la rimozione del blocco delle celle. Descrizione dell''errore:""%1""';
				|pl = 'Podczas zdjęcia blokowań komórek wystąpił błąd. Opis błędu: ""%1""';
				|tr = 'Hücre kilitleri kaldırılırken hata oluştu. Hata ayrıntılar: ""%1""'"),
			ErrorInfo().Description);
		
		// Add an error entry to the log.
		WriteLogEvent(
			NStr("vi = 'Lỗi khi dỡ phong tỏa ô hàng.';
				|ru = 'Ошибка при снятии блокировок ячеек.';
				|en = 'An error occurred while unlocking bins.'; fa = 'An error occurred while unlocking bins.';
				|it = 'Errore durante la rimozione del blocco delle celle.';
				|pl = 'Błąd podczas zdejmowania blokowań komórek.';
				|tr = 'Hücrelerin kilidi kaldırılırken hata oluştu.'",
				CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Job.Metadata(),
			Job,
			JobParameters.MessageText,
			EventLogEntryTransactionMode.Transactional);
	EndTry;
	
EndProcedure

// Returns an indication that the series are specified after selection (managing balances).
//
// Parameters:
//	BatchesIndicationStatus - Number - the status of specifying the series.
//
// Returns:
//	Boolean - flag indicating the series upon selection.
//
Function SeriesAreIndicatedUponSelection(BatchesIndicationStatus)
	
	ArrayOfStatuses = New Array;
	ArrayOfStatuses.Add(3);
	ArrayOfStatuses.Add(4);
	
	Return Not (ArrayOfStatuses.Find(BatchesIndicationStatus) = Undefined);
	
EndFunction

// Fills in the table part "Goods" of the document of recalculation of goods with the number of goods for accounting.
//
// Parameters:
//	RecalculationOfGoodsObject - DocumentObject.InventoryRecount - the document conversion.
//
Procedure FillInQuantityForAccountingWhenRecalculatingGoods(RecalculationOfGoodsObject)
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	Goods.Cell AS Cell,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.Package AS Package
	|INTO TT_Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsInStorageBins.Cell AS Cell,
	|	GoodsInStorageBins.Products AS Products,
	|	GoodsInStorageBins.Characteristic AS Characteristic,
	|	GoodsInStorageBins.Purpose AS Purpose,
	|	GoodsInStorageBins.Package AS Package,
	|	GoodsInStorageBins.Series,
	|	GoodsInStorageBins.InStockBalance AS NumberOfPackages,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 0) = 0
	|			THEN GoodsInStorageBins.InStockBalance
	|		ELSE GoodsInStorageBins.InStockBalance * &QueryTextPackagingFactor
	|	END AS Count
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(
	|			&DateOfRemainingGoods,
	|			Cell.Owner = &Warehouse
	|				AND Cell.Premise = &Premise
	|				AND (Cell, Products, Characteristic, Purpose, Series, Package) IN
	|					(SELECT
	|						Goods.Cell,
	|						Goods.Products,
	|						Goods.Characteristic,
	|						Goods.Purpose,
	|						Goods.Series,
	|						Goods.Package
	|					FROM
	|						TT_Goods AS Goods)) AS GoodsInStorageBins";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsInStorageBins.Package", Undefined));
		
	Query.SetParameter("Warehouse", RecalculationOfGoodsObject.Warehouse);
	Query.SetParameter("Premise", RecalculationOfGoodsObject.Premise);
	Query.SetParameter("Goods", RecalculationOfGoodsObject.Goods.Unload());
	Query.SetParameter("DateOfRemainingGoods", RecalculationOfGoodsObject.Date);
	
	FilterParameters = New Structure("Cell, Products, Characteristic, Purpose, Series, Package");
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		FillPropertyValues(FilterParameters, Selection);
		
		RowsArray = RecalculationOfGoodsObject.Goods.FindRows(FilterParameters);
		If RowsArray.Count() = 0 Then
			Continue;
		ElsIf RowsArray.Count() = 1 Then
			TablRow = RowsArray[0];
			TablRow.NumberOfPackages = Selection.NumberOfPackages;
			TablRow.Count = Selection.Count;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in a table of values containing product information with series references.
//
// Parameters:
//	TaskItems_ - ValueTable
//
Procedure FillInProductTableSeriesOfTask(TaskItems_)
	
	For Each RowOfGoods In TaskItems_ Do
		
		If SeriesAreIndicatedUponSelection(RowOfGoods.BatchesIndicationStatus) Then
		
			If Not ValueIsFilled(RowOfGoods.Series)
				And (ValueIsFilled(RowOfGoods.BatchNumber)
					Or ValueIsFilled(RowOfGoods.ValidUntil_)) Then
				
				SeriesIndicationParameters = New Structure("SpecifyNumberWhenRegisteringBatch, UseShelfLifeOnBatchRegistration,
					|PrecisionOfBatchShelfLifeIndication");
				FillPropertyValues(SeriesIndicationParameters, RowOfGoods);
				
				SeriesParameters = FindSeries_(RowOfGoods.BatchNumber, RowOfGoods.ValidUntil_, RowOfGoods.ProductKind,
					SeriesIndicationParameters);
				
				RowOfGoods.Series = SeriesParameters.Series;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Complements the selection verification task with a scanned container.
//
// Parameters:
//	GoodsForScanning - FormDataCollectionItem, ValueTable - a product table that corresponds to the table
//		part of the task being performed and contains information about scanned products.
//	Goods - ValueTable
//
Procedure AddScannedContainerToSelectionVerificationTask(GoodsForScanning, Goods)
	
	UBound = Goods.Count() - 1;
	
	For OBRIndex = 0 To UBound Do
		
		StringTSGoods = Goods[UBound - OBRIndex];
		
		If ThisIsTara(StringTSGoods) Then
			Goods.Delete(StringTSGoods);
		EndIf;
		
	EndDo;
	
	For Each TablRow In GoodsForScanning Do
		
		If ThisIsTara(TablRow) Then
			If TablRow.NumberOfPackagingsScanned > 0 Then
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, TablRow);
				NewRow.Count = NewRow.NumberOfPackages;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fields where the selected products may not match the order and this is not considered a shortage.
//
// Parameters:
//	BinLocationWarehousingIsUsed - Boolean - True if used in the warehouse address storage of goods is used.
//	CurrentData - FormDataCollectionItem, Undefined - if data is transmitted, it is calculated for them if
//																Is undefined in General, for PM.
//
//	Returns:
//		Structure - parameters used when checking a spending order for goods:
//			* PackingList_ - Boolean - The truth is, if you want to take into account the differences in the packages when checking the debit orders.
//			* SeriesStatusesThatAreNotTakenIntoAccount - Array of Number - the series indication statuses that are not taken into account when checking the expenditure order.
//			* ConsiderSeries - Boolean - True if it is necessary to take into account discrepancies by series when checking the expense order.
//
Function FieldsTakenIntoAccountWhenCheckingSpendingOrder(BinLocationWarehousingIsUsed, CurrentData) Export
	
	Result = New Structure("PackingList_, ConsiderSeries, SeriesStatusesThatAreNotTakenIntoAccount");
	
	Result.PackingList_ = BinLocationWarehousingIsUsed;
	
	SeriesStatusesThatAreNotTakenIntoAccount = New Array();
	SeriesStatusesThatAreNotTakenIntoAccount.Add(0);
	SeriesStatusesThatAreNotTakenIntoAccount.Add(1);
	SeriesStatusesThatAreNotTakenIntoAccount.Add(2);
	SeriesStatusesThatAreNotTakenIntoAccount.Add(3);
	SeriesStatusesThatAreNotTakenIntoAccount.Add(4);
	
	Result.SeriesStatusesThatAreNotTakenIntoAccount = SeriesStatusesThatAreNotTakenIntoAccount;
	
	If CurrentData = Undefined Then
		Result.ConsiderSeries = True;
	Else
		Result.ConsiderSeries = (SeriesStatusesThatAreNotTakenIntoAccount.Find(CurrentData.BatchesIndicationStatus) = Undefined);
	EndIf;

	Return Result;
	
EndFunction

// Checks whether the item is a container.
//
// Parameters:
//	StructureOfData - FormDataCollectionItem, Structure - any data structure to check.
//
// Returns:
//	Boolean - The truth is that the nomenclature is a container.
//
Function ThisIsTara(StructureOfData)
	
	Return (StructureOfData.ItemsType = Enums.ItemsTypes.ReusablePackage);
	
EndFunction

// Returns a table of products stored in the cell.
//
// Parameters:
//	ArrayOfCells - Array of CatalogRef.StorageBins - storage cells for which you want to get the remaining items.
//
// Returns:
//	ValueTable - table of goods stored in the cell:
//		* Cell - CatalogRef.StorageBins - storage cell.
//		* Products - CatalogRef.Products - the product stored in the cell.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure - packing.
//		* Series - CatalogRef.ItemsBatches - product series.
//		* BatchNumber - String - the batch number of the product.
//		* ValidUntil_ - Date - expiration date of the product series.
//		* BatchPresentation - String - name of the series.
//		* Count - Number - the remainder of the goods in Lidskoe cell.
//		* QuantityScanned - Number - the number of scanned items.
//
Function StockOfGoodsInBin(ArrayOfCells) Export
	
	Query = New Query;
	Query.SetParameter("Cells", ArrayOfCells);
	
	Query.Text =
	"SELECT
	|	GoodsInStorageBinsBalance.Cell AS Cell,
	|	GoodsInStorageBinsBalance.Products AS Products,
	|	GoodsInStorageBinsBalance.Characteristic AS Characteristic,
	|	CASE
	|		WHEN GoodsInStorageBinsBalance.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|			THEN GoodsInStorageBinsBalance.Package
	|		ELSE GoodsInStorageBinsBalance.Products.UnitOfMeasure
	|	END AS Package,
	|	GoodsInStorageBinsBalance.Purpose AS Purpose,
	|	GoodsInStorageBinsBalance.Series AS Series,
	|	GoodsInStorageBinsBalance.Series.Number AS BatchNumber,
	|	GoodsInStorageBinsBalance.Series.ValidUntil_ AS ValidUntil_,
	|	GoodsInStorageBinsBalance.Series.Presentation AS BatchPresentation,
	|	GoodsInStorageBinsBalance.InStockBalance AS Count,
	|	GoodsInStorageBinsBalance.InStockBalance AS QuantityScanned
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(, Cell IN (&Cells)) AS GoodsInStorageBinsBalance
	|
	|ORDER BY
	|	GoodsInStorageBinsBalance.Cell.TabIndex,
	|	GoodsInStorageBinsBalance.Cell.Code,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series";
	
	QueryResult = Query.Execute();
	StockBalance = QueryResult.Unload();
	
	Return StockBalance;
	
EndFunction

// Returns a table of products stored in the cell marked for recalculation.
//
// Parameters:
//	ArrayOfCells - Array of CatalogRef.StorageBins - storage cells for which you want to get the remaining items.
//
// Returns:
//	ValueTable - table of goods stored in the cell:
//		* Cell - CatalogRef.StorageBins - storage cell.
//		* Products - CatalogRef.Products - the product stored in the cell.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure - packing.
//		* Series - CatalogRef.ItemsBatches - product series.
//		* BatchNumber - String - the batch number of the product.
//		* ValidUntil_ - Date - expiration date of the product series.
//		* BatchPresentation - String - name of the series.
//		* Count - Number - the remainder of the goods in Lidskoe cell.
//
Function InventoryToRecount(ArrayOfCells) Export
	
	Query = New Query;
	Query.SetParameter("Cells", ArrayOfCells);
	
	Query.Text =
	"SELECT
	|	GoodsInStorageBinsBalance.Cell AS Cell,
	|	GoodsInStorageBinsBalance.Products AS Products,
	|	GoodsInStorageBinsBalance.Characteristic AS Characteristic,
	|	CASE
	|		WHEN GoodsInStorageBinsBalance.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|			THEN GoodsInStorageBinsBalance.Package
	|		ELSE GoodsInStorageBinsBalance.Products.UnitOfMeasure
	|	END AS Package,
	|	GoodsInStorageBinsBalance.Purpose AS Purpose,
	|	GoodsInStorageBinsBalance.Series AS Series,
	|	GoodsInStorageBinsBalance.InStockBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(, Cell IN (&Cells)) AS GoodsInStorageBinsBalance
	|
	|ORDER BY
	|	Cell,
	|	Products,
	|	Characteristic,
	|	Package,
	|	Purpose,
	|	Series";
	
	QueryResult = Query.Execute();
	InventoryToRecount = QueryResult.Unload();
	
	Return InventoryToRecount;
	
EndFunction

// Returns a table of product values that can be selected/placed for further execution of the warehouse task
// in accordance with the algorithm for selecting products in other cells, according to the set parameters.
//
// Parameters:
//	Warehouse - CatalogRef.Warerooms - warehouse.
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	GoodsForPicking - ValueTable - table of unselected / unplaced items according to the task being performed.
//	ReferenceOrder - DocumentRef - the disposal of the warehouse activities.
//	Job - DocumentRef.GoodsPickingPlacement - the warehouse job.
//	
// Returns:
// 	See WarehousesServer.SelectProductFromCells
//
Function TableOfUnselectedProducts(Warehouse, Premise, GoodsForPicking, ReferenceOrder, Job) Export
	
	Manager = New TempTablesManager;
	
	JobType = JobType(Job);
	
	// A request is formed, depending on the type of operation being performed, to obtain data for selection/placement
	// from other cells.
	If JobType = "Filter" Then
		
		Query = New Query;
		Query.TempTablesManager = Manager;
		Query.SetParameter("Goods", GoodsForPicking);
		Query.SetParameter("ReferenceOrder", ?(ValueIsFilled(ReferenceOrder), ReferenceOrder, ""));
		
		Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.Series AS Series,
		|	Table.Count AS Count
		|INTO RequestProductTable
		|FROM
		|	&Goods AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RequestProductTable.Products AS Products,
		|	RequestProductTable.Characteristic AS Characteristic,
		|	RequestProductTable.Purpose AS Purpose,
		|	RequestProductTable.Series AS Series,
		|	SUM(RequestProductTable.Count) AS Count,
		|	DATETIME(1, 1, 1) AS DateOfShipment,
		|	0 AS Priority,
		|	&ReferenceOrder AS ReferenceOrder,
		|	CAST(RequestProductTable.Products AS Catalog.Products).WarehouseGroup AS WarehouseGroupOfProducts
		|INTO ProductsTable
		|FROM
		|	RequestProductTable AS RequestProductTable
		|
		|GROUP BY
		|	RequestProductTable.Products,
		|	RequestProductTable.Characteristic,
		|	RequestProductTable.Purpose,
		|	RequestProductTable.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RequestProductTable";
		
		Query.Execute();
		
		ReturnStructure = WarehousesServer.SelectProductFromCells(Manager, Warehouse, Premise);
		Manager.Close();
		
	Else
		
		CheckError = False;
		WarehouseZone = Common.ObjectAttributeValue(Job, "WarehouseZone");
		
		Query = New Query;
		Query.TempTablesManager = Manager;
		Query.SetParameter("Goods", GoodsForPicking);
		Query.SetParameter("Warehouse", Warehouse);
		
		Query.Text =
		"SELECT
		|	RequestProductTable.Products AS Products,
		|	RequestProductTable.Package AS Package,
		|	RequestProductTable.Characteristic AS Characteristic,
		|	RequestProductTable.Purpose AS Purpose,
		|	CAST(RequestProductTable.Series AS Catalog.ItemsBatches) AS Series,
		|	RequestProductTable.NumberOfPackages AS NumberOfPackages
		|INTO RequestProductTable
		|FROM
		|	&Goods AS RequestProductTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RequestProductTable.Products AS Products,
		|	RequestProductTable.Package AS Package,
		|	RequestProductTable.Series,
		|	RequestProductTable.Characteristic AS Characteristic,
		|	RequestProductTable.Purpose AS Purpose,
		|	SUM(RequestProductTable.NumberOfPackages) AS NumberOfPackages
		|INTO ProductsTable
		|FROM
		|	RequestProductTable AS RequestProductTable
		|
		|GROUP BY
		|	RequestProductTable.Products,
		|	RequestProductTable.Package,
		|	RequestProductTable.Characteristic,
		|	RequestProductTable.Purpose,
		|	RequestProductTable.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RequestProductTable";
		
		Query.Execute();
		
		ReturnStructure = WarehousesServer.PlaceGoodsInCells(Manager ,Warehouse ,Premise ,WarehouseZone, 
			Catalogs.StorageBins.EmptyRef(), CheckError);
		
		Manager.Close();
		
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Returns an array with the data of the barcode cells.
//
// Parameters:
//	ArrayOfCells - Array of CatalogRef.StorageBins - links of storage cells for which you want to get barcodes.
//
// Returns:
//	Array of Structure:
//		*Cell - CatalogRef.StorageBins
//		*CellCode - String
//		*CellBarcode - String
//
Function CellBarcodes(ArrayOfCells) Export
	
	Query = New Query;
	Query.SetParameter("Cells", ArrayOfCells);
	
	Query.Text =
	"SELECT
	|	StorageBins.Ref AS Cell,
	|	StorageBins.Code AS CellCode
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	StorageBins.Ref IN (&Cells)";
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	CellsWithBarcodes = New Array;
	
	While Selection.Next() Do
		ElementStructure = New Structure("Cell, CellCode, CellBarcode");
		FillPropertyValues(ElementStructure, Selection);
		
		ElementStructure.CellBarcode = BarcodingOfPrintForms.NumericCodeFromLink(Selection.Cell);
		CellsWithBarcodes.Add(ElementStructure);
	EndDo;
	
	Return CellsWithBarcodes;
	
EndFunction

// Returns a table of values after selecting products from other cells
// that stores information about the products that need to be scanned for the task being performed.
//
// Parameters:
//	Warehouse - CatalogRef.Warerooms - warehouse,
//	Premise - CatalogRef.Warerooms - warehouse premises.
//	VTProductsForScanning - ValueTable - table of products with initial information about scanned products,
//	CurCell - CatalogRef.StorageBins - the cell with which warehouse operations are performed.
//
// Returns:
//	ValueTable
//
Function ProductQueueForScanning(Warehouse, Premise, VTProductsForScanning, CurCell) Export
	
	Manager = New TempTablesManager;
	
	// We form a request to receive the TK for the effective TK <Goods for scanning>.
	// As a result, we get a TK in which the cells are sorted in the order of traversal, and the cells whose code is less
	// than the current cell are placed at the end of the queue, also in sorted order.
	Query = New Query;
	Query.TempTablesManager = Manager;
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Goods", VTProductsForScanning);
	
	CellDetails = Common.ObjectAttributesValues(CurCell, "TabIndex, Code");
	
	Query.SetParameter("Code", CellDetails.Code);
	Query.SetParameter("TabIndex", CellDetails.TabIndex);
	
	Query.Text =
	"SELECT
	|	Table.Cell AS Cell,
	|	Table.Products AS Products,
	|	Table.Package AS Package,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.NumberOfPackagingsScanned AS NumberOfPackagingsScanned,
	|	Table.ActiveString AS ActiveString,
	|	Table.NumberOfBins AS NumberOfBins,
	|	Table.CellNumber AS CellNumber,
	|	Table.QuantityOfGoodsInABin AS QuantityOfGoodsInABin,
	|	Table.GoodsNumberInTheBin AS GoodsNumberInTheBin,
	|	Table.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Table.LineNumber AS LineNumber,
	|	Table.ZoomRatio AS ZoomRatio,
	|	Table.QuantityNotToShip AS QuantityNotToShip,
	|	Table.NumberOfPackagesDoNotShip AS NumberOfPackagesDoNotShip,
	|	Table.QuantityOfGoodsInDocument AS QuantityOfGoodsInDocument,
	|	Table.NumberOfPackagesInDocument AS NumberOfPackagesInDocument,
	|	Table.ThereIsShortage AS ThereIsShortage,
	|	Table.ThereAreGoodsUnshipped AS ThereAreGoodsUnshipped,
	|	Table.ItemsType AS ItemsType,
	|	Table.DoNotShip AS DoNotShip,
	|	Table.NumberOfPackagesInDocumentUnshipped AS NumberOfPackagesInDocumentUnshipped,
	|	Table.Purpose AS Purpose,
	|	Table.OriginalLineNumber AS OriginalLineNumber,
	|	Table.CellBarcode AS CellBarcode,
	|	Table.ItemsBarcode AS ItemsBarcode,
	|	Table.CellCode AS CellCode,
	|	Table.ValidUntil_ AS ValidUntil_,
	|	Table.BatchNumber AS BatchNumber,
	|	Table.SpecifyNumberWhenRegisteringBatch AS SpecifyNumberWhenRegisteringBatch,
	|	Table.UseShelfLifeOnBatchRegistration AS UseShelfLifeOnBatchRegistration,
	|	Table.PrecisionOfBatchShelfLifeIndication AS PrecisionOfBatchShelfLifeIndication,
	|	Table.ProductKind AS ProductKind,
	|	Table.UnitOfMeasure AS UnitOfMeasure,
	|	Table.PackageWeight AS PackageWeight,
	|	Table.PackageVolume AS PackageVolume,
	|	Table.UnitOfMeasureForWeight AS UnitOfMeasureForWeight,
	|	Table.UnitOfMeasureForVolume AS UnitOfMeasureForVolume,
	|	Table.MeasuredValueType AS MeasuredValueType,
	|	Table.FactorOfWeightUnitOfMeasure AS FactorOfWeightUnitOfMeasure,
	|	Table.FactorOfVolumeUnitOfMeasure AS FactorOfVolumeUnitOfMeasure
	|INTO RequestProductTable
	|FROM
	|	&Goods AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StorageBins.Ref AS Cell,
	|	RequestProductTable.Products AS Products,
	|	RequestProductTable.Package AS Package,
	|	RequestProductTable.Characteristic AS Characteristic,
	|	RequestProductTable.Series AS Series,
	|	SUM(RequestProductTable.NumberOfPackages) AS NumberOfPackages,
	|	SUM(RequestProductTable.NumberOfPackagingsScanned) AS NumberOfPackagingsScanned,
	|	MIN(RequestProductTable.ActiveString) AS ActiveString,
	|	MAX(RequestProductTable.NumberOfBins) AS NumberOfBins,
	|	MAX(RequestProductTable.CellNumber) AS CellNumber,
	|	MAX(RequestProductTable.QuantityOfGoodsInABin) AS QuantityOfGoodsInABin,
	|	MAX(RequestProductTable.GoodsNumberInTheBin) AS GoodsNumberInTheBin,
	|	MAX(RequestProductTable.BatchesIndicationStatus) AS BatchesIndicationStatus,
	|	MIN(RequestProductTable.LineNumber) AS LineNumber,
	|	MIN(RequestProductTable.ZoomRatio) AS ZoomRatio,
	|	SUM(RequestProductTable.QuantityNotToShip) AS QuantityNotToShip,
	|	SUM(RequestProductTable.NumberOfPackagesDoNotShip) AS NumberOfPackagesDoNotShip,
	|	SUM(RequestProductTable.QuantityOfGoodsInDocument) AS QuantityOfGoodsInDocument,
	|	SUM(RequestProductTable.NumberOfPackagesInDocument) AS NumberOfPackagesInDocument,
	|	RequestProductTable.ThereIsShortage AS ThereIsShortage,
	|	RequestProductTable.ThereAreGoodsUnshipped AS ThereAreGoodsUnshipped,
	|	RequestProductTable.ItemsType AS ItemsType,
	|	RequestProductTable.DoNotShip AS DoNotShip,
	|	SUM(RequestProductTable.NumberOfPackagesInDocumentUnshipped) AS NumberOfPackagesInDocumentUnshipped,
	|	RequestProductTable.Purpose AS Purpose,
	|	MIN(RequestProductTable.OriginalLineNumber) AS OriginalLineNumber,
	|	CASE
	|		WHEN RequestProductTable.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN 1
	|		ELSE 0
	|	END AS ProductPriority,
	|	MAX(CASE
	|			WHEN &TabIndex < StorageBins.TabIndex
	|				THEN 2
	|			ELSE CASE
	|					WHEN &TabIndex = StorageBins.TabIndex
	|							AND &Code > StorageBins.Code
	|						THEN 1
	|					ELSE 0
	|				END
	|		END) AS CellPriority,
	|	RequestProductTable.CellBarcode AS CellBarcode,
	|	RequestProductTable.ItemsBarcode AS ItemsBarcode,
	|	RequestProductTable.CellCode AS CellCode,
	|	RequestProductTable.ValidUntil_ AS ValidUntil_,
	|	RequestProductTable.BatchNumber AS BatchNumber,
	|	RequestProductTable.SpecifyNumberWhenRegisteringBatch AS SpecifyNumberWhenRegisteringBatch,
	|	RequestProductTable.UseShelfLifeOnBatchRegistration AS UseShelfLifeOnBatchRegistration,
	|	RequestProductTable.PrecisionOfBatchShelfLifeIndication AS PrecisionOfBatchShelfLifeIndication,
	|	RequestProductTable.ProductKind AS ProductKind,
	|	RequestProductTable.UnitOfMeasure AS UnitOfMeasure,
	|	RequestProductTable.PackageWeight AS PackageWeight,
	|	RequestProductTable.PackageVolume AS PackageVolume,
	|	RequestProductTable.UnitOfMeasureForWeight AS UnitOfMeasureForWeight,
	|	RequestProductTable.UnitOfMeasureForVolume AS UnitOfMeasureForVolume,
	|	RequestProductTable.MeasuredValueType AS MeasuredValueType,
	|	MIN(RequestProductTable.FactorOfWeightUnitOfMeasure) AS FactorOfWeightUnitOfMeasure,
	|	MIN(RequestProductTable.FactorOfVolumeUnitOfMeasure) AS FactorOfVolumeUnitOfMeasure
	|FROM
	|	RequestProductTable AS RequestProductTable
	|		LEFT JOIN Catalog.StorageBins AS StorageBins
	|		ON RequestProductTable.Cell = StorageBins.Ref
	|WHERE
	|	StorageBins.Owner = &Warehouse
	|	AND StorageBins.Premise = &Premise
	|
	|GROUP BY
	|	StorageBins.Ref,
	|	RequestProductTable.Products,
	|	RequestProductTable.Package,
	|	RequestProductTable.Characteristic,
	|	RequestProductTable.Series,
	|	RequestProductTable.ThereIsShortage,
	|	RequestProductTable.ThereAreGoodsUnshipped,
	|	RequestProductTable.ItemsType,
	|	RequestProductTable.DoNotShip,
	|	RequestProductTable.CellBarcode,
	|	RequestProductTable.ItemsBarcode,
	|	RequestProductTable.CellCode,
	|	RequestProductTable.ValidUntil_,
	|	RequestProductTable.BatchNumber,
	|	RequestProductTable.SpecifyNumberWhenRegisteringBatch,
	|	RequestProductTable.UseShelfLifeOnBatchRegistration,
	|	RequestProductTable.PrecisionOfBatchShelfLifeIndication,
	|	RequestProductTable.ProductKind,
	|	RequestProductTable.UnitOfMeasure,
	|	RequestProductTable.PackageWeight,
	|	RequestProductTable.PackageVolume,
	|	RequestProductTable.Purpose,
	|	RequestProductTable.UnitOfMeasureForWeight,
	|	RequestProductTable.UnitOfMeasureForVolume,
	|	RequestProductTable.MeasuredValueType
	|
	|ORDER BY
	|	StorageBins.TabIndex,
	|	CellPriority,
	|	StorageBins.Code,
	|	ProductPriority,
	|	Products,
	|	Characteristic,
	|	Series,
	|	NumberOfPackages DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RequestProductTable";
	
	QueryResult = Query.Execute();
	VTProductsForScanning = QueryResult.Unload();
	
	Manager.Close();
	
	TypeSeriesName = New TypeDescription("String", , New StringQualifiers(150));
	TypeNameLong = New TypeDescription("String", , New StringQualifiers(100));
	TypeNameShort = New TypeDescription("String", , New StringQualifiers(50));
	
	VTProductsForScanning.Columns.Add("ItemName", TypeNameLong);
	VTProductsForScanning.Columns.Add("ProductIDOfItems", TypeNameLong);
	VTProductsForScanning.Columns.Add("ItemsDescription", TypeNameLong);
	VTProductsForScanning.Columns.Add("PackageName", TypeNameShort);
	VTProductsForScanning.Columns.Add("ItemVariantName", TypeNameLong);
	VTProductsForScanning.Columns.Add("BatchName", TypeNameLong);
	VTProductsForScanning.Columns.Add("PurposeDescription", TypeNameLong);
	VTProductsForScanning.Columns.Add("UnitOfMeasureDescription", TypeNameShort);
	VTProductsForScanning.Columns.Add("NameOfWeightUnitOfMeasure", TypeNameShort);
	VTProductsForScanning.Columns.Add("NameOfVolumeUnitOfMeasure", TypeNameShort);
	
	Goods = New Array;
	Filter = New Structure("Products");
	VTProducts = VTProductsForScanning.UnloadColumn("Products");
	
	CommonClientServer.SupplementArray(Goods, VTProducts, True);
	
	For Each Products In Goods Do
		
		Filter.Products = Products;
		
		RowsArray = VTProductsForScanning.FindRows(Filter);
		ProductAttributes = Common.ObjectAttributesValues(Products, "Presentation,
			|SKU, LongDesc");
		
		For Each RowOfGoods In RowsArray Do
			
			RowOfGoods.ProductIDOfItems = ProductAttributes.SKU;
			RowOfGoods.ItemsDescription = ProductAttributes.LongDesc;
			RowOfGoods.ItemName = ProductAttributes.Presentation;
			
			If ValueIsFilled(RowOfGoods.Characteristic) Then
				Description = Common.ObjectAttributeValue(RowOfGoods.Characteristic, "Presentation");
				RowOfGoods.ItemVariantName = Description;
			EndIf;
			
			If ValueIsFilled(RowOfGoods.Package) Then
				Description = Common.ObjectAttributeValue(RowOfGoods.Package, "Presentation");
				RowOfGoods.PackageName = Description;
			EndIf;
			
			If ValueIsFilled(RowOfGoods.Purpose) Then
				Description = Common.ObjectAttributeValue(RowOfGoods.Purpose, "Presentation");
				RowOfGoods.PurposeDescription = Description;
			EndIf;
			
			If ValueIsFilled(RowOfGoods.Series) Then
				Description = Common.ObjectAttributeValue(RowOfGoods.Series, "Presentation");
				RowOfGoods.BatchName = Description;
			EndIf;
			
			If ValueIsFilled(RowOfGoods.UnitOfMeasureForWeight) Then
				Description = Common.ObjectAttributeValue(RowOfGoods.UnitOfMeasureForWeight, "Presentation");
				RowOfGoods.NameOfWeightUnitOfMeasure = Description;
			EndIf;
			
			If ValueIsFilled(RowOfGoods.UnitOfMeasureForVolume) Then
				Description = Common.ObjectAttributeValue(RowOfGoods.UnitOfMeasureForVolume, "Presentation");
				RowOfGoods.NameOfVolumeUnitOfMeasure = Description;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return VTProductsForScanning;
	
EndFunction

// Returns an array whose elements are values of dimensional types of measured values.
//
// Returns:
//	Array of EnumRef.TypesOfMeasuredValues - the elements are the values of the dimensional types of the measured quantities.
//
Function DimensionalUnitsOfMeasurement()
	
	DimensionalUnitsOfMeasurement = New Array;
	DimensionalUnitsOfMeasurement.Add(Enums.TypesOfMeasuredValues.Weight);
	DimensionalUnitsOfMeasurement.Add(Enums.TypesOfMeasuredValues.VolumeM3);
	DimensionalUnitsOfMeasurement.Add(Enums.TypesOfMeasuredValues.Length);
	DimensionalUnitsOfMeasurement.Add(Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
	
	Return DimensionalUnitsOfMeasurement;
	
EndFunction

Function ContractorSWorkAreas(Warehouse, Premise, Performer)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	WarehouseZonesAreaWorkers.Ref AS WarehouseZone
	|FROM
	|	Catalog.WarehouseZones.AreaWorkers AS WarehouseZonesAreaWorkers
	|WHERE
	|	WarehouseZonesAreaWorkers.AreaWorker IN(&Assignees)
	|	AND WarehouseZonesAreaWorkers.Ref.Owner = &Warehouse
	|	AND WarehouseZonesAreaWorkers.Ref.Premise = &Premise";
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Assignees", Performer);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	WarehouseZones = Result.Unload().UnloadColumn("WarehouseZone");
	WarehouseZones.Add(Catalogs.WarehouseZones.EmptyRef());
	
	Return WarehouseZones;
	
EndFunction

#EndRegion