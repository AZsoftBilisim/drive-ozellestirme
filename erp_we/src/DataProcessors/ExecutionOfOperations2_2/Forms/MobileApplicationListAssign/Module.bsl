#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	ExecutionIsAllowed = Parameters.ExecutionIsAllowed;
	Department  = Parameters.DepartmentFilter;
	ProductionArea        = Parameters.LotFilter;
	RCView          = Parameters.ViewRatbor;
	WorkCenter   = Parameters.WorkCenterFilter;
	Operation       = Parameters.OperationFilter;
	Product        = Parameters.ProductSelection_4_;
	Performer    = Parameters.PerformerFilter;
	Stage           = Parameters.StepFilter;
	Lot         = Parameters.ButchFilter;
	
	FillInServiceDetails();
	
	SetPropertiesOfDynamicListPerformOperations();
	
	SetFilters();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	FilterParameters = New Structure();
	
	FilterParameters.Insert("ExecutionIsAllowed", ExecutionIsAllowed);
	FilterParameters.Insert("RCView", RCView);
	FilterParameters.Insert("WorkCenter", WorkCenter);
	FilterParameters.Insert("Performer", Performer);
	FilterParameters.Insert("Operation", Operation);
	FilterParameters.Insert("Product", Product);
	FilterParameters.Insert("Lot", Lot);
	FilterParameters.Insert("Stage", Stage);
	FilterParameters.Insert("ProductionArea", ProductionArea);
	
	Close(FilterParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionOperation2_2"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("Department")
		And Parameter.Department = Department Then
		
		Items.ExecutionOfOperations.Refresh();
		
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure ExecutionOfOperationsOnActivateRow(Item)
	
	SeveralOperationsAreHighlighted = Items.ExecutionOfOperations.SelectedRows.Count()>1;
	
	If IsMobileClient Then
		Items.AssignOperations.Visible = SeveralOperationsAreHighlighted;
		Items.Select.Visible           = Not SeveralOperationsAreHighlighted;
	EndIf;
	
	RunTime = 0;
	If SeveralOperationsAreHighlighted Then
	
		For Each String In Items.ExecutionOfOperations.SelectedRows Do
		
			CurrentData = Items.ExecutionOfOperations.RowData(String);
			
			If CurrentData.TimeUnitsOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Second") Then
				RunTime = RunTime + CurrentData.ExecutionTimeWaitingForCreation/3600;
			ElsIf CurrentData.TimeUnitsOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute") Then
				RunTime = RunTime + CurrentData.ExecutionTimeWaitingForCreation/60;
			ElsIf CurrentData.TimeUnitsOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Day") Then
				RunTime = RunTime + CurrentData.ExecutionTimeWaitingForCreation*24;
			ElsIf CurrentData.TimeUnitsOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Days1") Then
				RunTime = RunTime + CurrentData.ExecutionTimeWaitingForCreation*24;
			Else
				RunTime = RunTime + CurrentData.ExecutionTimeWaitingForCreation;
			EndIf;
		
		EndDo;
		
	EndIf;
	AdditionalDownload(RunTime);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FiltersLineClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	
	FormParameters.Insert("Product",Product);
	FormParameters.Insert("Performer",Performer);
	FormParameters.Insert("Operation",Operation);
	FormParameters.Insert("RCView",RCView);
	FormParameters.Insert("WorkCenter",WorkCenter);
	FormParameters.Insert("ExecutionIsAllowed",ExecutionIsAllowed);
	FormParameters.Insert("Stage",Stage);
	FormParameters.Insert("Lot",Lot);
	FormParameters.Insert("Department",Department);
	FormParameters.Insert("ProductionArea",ProductionArea);
	
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationFiltersSetting",
		FormParameters,
		ThisForm,
		,
		,
		,
		New CallbackDescription("SetFiltersClient",ThisObject));
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AssignOperation(Command)
	
	SelectedRows = Items.ExecutionOfOperations.SelectedRows;
	
	OperationKeys = CheckGetOperationsHighlightedInList(SelectedRows);
	
	If OperationKeys = Undefined Then
		Return;
	EndIf;
	
	If OperationKeys.Count() = 1
		And Items.ExecutionOfOperations.CurrentData <> Undefined Then
		
		If TypeOf(Items.ExecutionOfOperations.CurrentRow) = Type("DynamicListGroupRow")
			Or (Not ShiftJobsAreUsed And Items.ExecutionOfOperations.CurrentData.WaitingForCreation = 0) Then
			
			ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn';
									|ru = 'Команда не может быть выполнена для выбранной строки';
									|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
									|it = 'Il comando non può essere eseguito per la riga selezionata!';
									|pl = 'Polecenie nie może być wykonane dla wybranego wiersza';
									|tr = 'Seçili satır için komut gerçekleştirilemez'"));
			Return;
		EndIf;
		
	EndIf;
		
	OpenOperationAssignmentForm(OperationKeys, "Assign");
	
EndProcedure

&AtClient
Procedure SkipOperation(Command)
	
	SelectedRows = Items.ExecutionOfOperations.SelectedRows;
	
	OperationKeys = CheckGetOperationsHighlightedInList(SelectedRows);
	
	If OperationKeys = Undefined Then
		Return;
	EndIf;
	
	If OperationKeys.Count() = 1
		And Items.ExecutionOfOperations.CurrentData <> Undefined Then
		
		If TypeOf(Items.ExecutionOfOperations.CurrentRow) = Type("DynamicListGroupRow") Then
			
			ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn';
									|ru = 'Команда не может быть выполнена для выбранной строки';
									|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
									|it = 'Il comando non può essere eseguito per la riga selezionata!';
									|pl = 'Polecenie nie może być wykonane dla wybranego wiersza';
									|tr = 'Seçili satır için komut gerçekleştirilemez'"));
			Return;
		EndIf;
		
		If Not Items.ExecutionOfOperations.CurrentData.Skippable Then
		
			ShowMessageBox(, NStr("vi = 'Hoạt động không thể được bỏ qua';
									|ru = 'Операция не может быть пропущена';
									|en = 'Operation cannot be skipped'; fa = 'Operation cannot be skipped';
									|it = 'L''operazione non può essere ignorata';
									|pl = 'Operacja nie może być pominięta';
									|tr = 'İşlem atlanamaz'"));
			Return;
		EndIf;
	EndIf;
	
	ProductionAccountingClient.GenerateProductionOperations(
			Department,
			OperationKeys,
			New Structure,
			PredefinedValue("Enum.ProductionOperationStatuses.IsSkipped"));
	
EndProcedure

&AtClient
Procedure PutIntoOperation(Command)
	
	SelectedRows = Items.ExecutionOfOperations.SelectedRows;
	
	OperationKeys = CheckGetOperationsHighlightedInList(SelectedRows);
	
	If OperationKeys = Undefined Then
		Return;
	EndIf;
	
	If OperationKeys.Count() = 1
		And (Items.ExecutionOfOperations.CurrentData <> Undefined) Then 
		
		If TypeOf(Items.ExecutionOfOperations.CurrentRow) = Type("DynamicListGroupRow")
			Or (Not ShiftJobsAreUsed And Items.ExecutionOfOperations.CurrentData.ExecutionIsAllowed = 0)
			Or (ShiftJobsAreUsed And Not Items.ExecutionOfOperations.CurrentData.YouCanStartNow) Then
			
			ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn';
									|ru = 'Команда не может быть выполнена для выбранной строки';
									|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
									|it = 'Il comando non può essere eseguito per la riga selezionata!';
									|pl = 'Polecenie nie może być wykonane dla wybranego wiersza';
									|tr = 'Seçili satır için komut gerçekleştirilemez'"));
			Return;
		EndIf;
		
	EndIf;
	
	OpenOperationAssignmentForm(OperationKeys, "PutIntoOperation");
	
EndProcedure

&AtClient
Procedure MarkCompletion(Command)
	
	SelectedRows = Items.ExecutionOfOperations.SelectedRows;
	
	OperationKeys = CheckGetOperationsHighlightedInList(SelectedRows);
	
	If OperationKeys = Undefined Then
		Return;
	EndIf;
	
	If OperationKeys.Count() = 1
		And (Items.ExecutionOfOperations.CurrentData <> Undefined) Then
		
		CurrentData = Items.ExecutionOfOperations.CurrentData;
		
		If TypeOf(Items.ExecutionOfOperations.CurrentRow) = Type("DynamicListGroupRow")
			Or (Not ShiftJobsAreUsed And (CurrentData.ExecutionIsAllowed + CurrentData.Running) = 0)
			Or (ShiftJobsAreUsed And Not Items.ExecutionOfOperations.CurrentData.YouCanStartNow) Then
			
			ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn';
									|ru = 'Команда не может быть выполнена для выбранной строки';
									|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
									|it = 'Il comando non può essere eseguito per la riga selezionata!';
									|pl = 'Polecenie nie może być wykonane dla wybranego wiersza';
									|tr = 'Seçili satır için komut gerçekleştirilemez'"));
			Return;
		EndIf;
		
	EndIf;
	
	OpenOperationAssignmentForm(OperationKeys, "MarkCompletion");
	
EndProcedure

&AtClient
Procedure ClearFilters(Command)
	
	If Not Rcvconfigurations Then
		RCView        = Undefined;
		WorkCenter = Undefined;
	EndIf;
	
	If Not ArtistInSettings Then
		Performer = Undefined;
	EndIf;
	
	If Not PlotInSettings Then
		ProductionArea = Undefined;
	EndIf;
	
	Operation = Undefined;
	Product  = Undefined;
	Stage     = Undefined;
	Lot   = Undefined;
	
	SetFilters();
EndProcedure

#If MobileClient Then

&AtClient
Procedure ScanBarcode(Command)
	
	If MultimediaTools.BarcodeScanningSupported() Then
		
		ScanningHandler = New CallbackDescription("ScanProcessing", ThisForm);
		
		MultimediaTools.ShowBarcodeScanning(NStr("vi = 'Hướng máy ảnh vào mã vạch';
												|ru = 'Наведите камеру на штрихкод';
												|en = 'Point the camera at the barcode'; fa = 'Point the camera at the barcode';
												|it = 'Puntare la camera sul codice a barre';
												|pl = 'Skieruj aparat na kod kreskowy';
												|tr = 'Kamerayı barkodun üzerine getirin'"),
			ScanningHandler,
			,
			BarcodeType.Linear);
	EndIf;
	
EndProcedure

&AtClient
Procedure ScanProcessing(Barcode, Result, Message, AdditionalParameters) Export

	If Result Then
		
		MultimediaTools.PlaySoundAlert(SoundAlert.Default,True);
		MultimediaTools.CloseBarcodeScanning();
		
		FillInSelectionForm(Barcode);
	Else
		
		Message = NStr("vi = 'Lỗi xử lý mã vạch';
						|ru = 'Ошибка обработки штрих кода';
						|en = 'Barcode processing error'; fa = 'Barcode processing error';
						|it = 'Errore di elaborazione del codice a barre';
						|pl = 'Wystąpił błąd podczas przetwarzania kodu kreskowego';
						|tr = 'Barkod işleme hatası'");
		
	EndIf;
EndProcedure

#EndIf

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Color-coding of operations that cannot be started
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ExecutionOfOperations.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ExecutionOfOperations.YouCanStartNow");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// Registration of the "Operation" field
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Operation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("OperationAssignment1.Operation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("OperationAssignment1.Description"));
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	ShiftJobsAreUsed = 
		ProductionServer.ProductionBusinessUnitDescription(Department).UseShiftTasks;
	
	IsMobileClient = Common.IsMobileClient();
	
	Settings = DataProcessors.ExecutionOfOperations2_2.GetUserSettings();
	
	If Settings <> Undefined Then
		
		PlotInSettings     = ValueIsFilled(Settings.ProductionArea);
		Rcvconfigurations          = ValueIsFilled(Settings.WorkCenter);
		ArtistInSettings = ValueIsFilled(Settings.Performer);
		
	EndIf;
	
EndProcedure

&AtClient
Function OpenOperationAssignmentForm(OperationKeys, WorkMode)
	
	FormParameters = New Structure;
	FormParameters.Insert("Department", Department);
	FormParameters.Insert("WorkMode", WorkMode);
	FormParameters.Insert("OperationKeys", OperationKeys);
	
	For Each ParameterName In StrSplit("WorkCenter,Performer,ProductionArea", ",") Do
		If ValueIsFilled(ThisObject[ParameterName]) Then
			FormParameters.Insert(ParameterName, ThisObject[ParameterName]);
		ElsIf OperationKeys.Count() = 1 Then
			CurrentData = Items.ExecutionOfOperations.CurrentData;
			If CurrentData <> Undefined Then
				FormParameters.Insert(ParameterName, CurrentData[ParameterName]);
			EndIf;
		EndIf;
	EndDo;
	
	OperationStatus = Undefined;
	If WorkMode = "Assign" Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.CreatedOn_");
	ElsIf WorkMode = "PutIntoOperation" Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.Running");
	ElsIf WorkMode = "MarkCompletion" Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.Executed");
	EndIf;
	
	AddlParameters = New Structure;
	AddlParameters.Insert("OperationKeys", OperationKeys);
	AddlParameters.Insert("OperationStatus", OperationStatus);
	
	CallbackDescription = New CallbackDescription(
		"OpenAssignOperationsFormCompletion",
		ThisObject,
		AddlParameters);
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.OperationAssignment1",
		FormParameters,
		ThisForm,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndFunction

&AtClient
Procedure OpenAssignOperationsFormCompletion(AssignmentParameters, AdditionalParameters) Export
	
	If AssignmentParameters <> Undefined Then
		
		ProductionAccountingClient.GenerateProductionOperations(
			Department, AdditionalParameters.OperationKeys, AssignmentParameters, AdditionalParameters.OperationStatus);
		
		CalculateDownload_();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfDynamicListPerformOperations()
	
	QueryOptions = New Structure;
	QueryOptions.Insert("FilterByArea", ValueIsFilled(ProductionArea));
	QueryOptions.Insert("ShiftJobsAreUsed", ShiftJobsAreUsed);
	
	ListProperties              = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = RequestTextForOperationsList();
	ListProperties.MainTable = ?(ShiftJobsAreUsed,
		"InformationRegister.OperationsToCreateShiftTasks",
		"InformationRegister.QueueOfProductionOperations");
	Common.SetDynamicListProperties(Items.ExecutionOfOperations, ListProperties);
	
	If ValueIsFilled(ProductionArea) Then
		OperationAssignment1.Parameters.SetParameterValue("ProductionArea",ProductionArea);
	EndIf;
	
	OperationAssignment1.Parameters.SetParameterValue(
		"TheProductionScheduleIsUsed",
		ProductionManagementCached.TheProductionScheduleIsUsed());
	
	OperationAssignment1.Parameters.SetParameterValue(
		"StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	OperationAssignment1.Order.Items.Clear();
	
	If ProductionManagementCached.TheProductionScheduleIsUsed() Then
	
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("Order");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("StageStart");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("NextStageStart");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("OperationNumber");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
	Else
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("Order");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("ReferenceOrder.Priority");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("ReferenceOrder.Department.AddlOrderingAttribute");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("ReferenceOrder.Queue");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("DurationBeforeProductionIssue");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OperationAssignment1.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("OperationNumber");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
	
	EndIf;
	
EndProcedure

&AtServer
Function RequestTextForOperationsList()
	
	QueryText =
		"SELECT
		|	OperationQueue.ReferenceOrder AS ReferenceOrder,
		|	OperationQueue.Stage AS Stage,
		|	&PresentationStage AS PresentationStage,
		|	OperationQueue.Department AS Department,
		|	OperationQueue.Operation AS Operation,
		|	OperationQueue.OperationID AS OperationID,
		|	OperationQueue.Scheduled AS WaitingForCreation,
		|	CASE
		|		WHEN
		|			CASE
		|				WHEN OperationQueue.Operation.WorkCenter REFS Catalog.WorkCenterTypes
		|					THEN ISNULL(OperationQueue.Operation.WorkCenter.ParallelLoad, FALSE)
		|						ELSE ISNULL(OperationQueue.Operation.WorkCenter.WorkCenterType.ParallelLoad, FALSE)
		|			END THEN OperationQueue.TimePerPiece
		|		ELSE OperationQueue.TimePerPiece * OperationQueue.Scheduled / OperationQueue.Operation.Count
		|	END + OperationQueue.SetupTime AS ExecutionTimeWaitingForCreation,
		|	OperationQueue.ExecutionIsAllowed AS ExecutionIsAllowed,
		|	OperationQueue.Running AS Running,
		|	ISNULL(Operations.Skippable, OperationQueue.ProductionOperation.Skippable) AS Skippable,
		|	ISNULL(Operations.UnitOfMeasure, OperationQueue.ProductionOperation.UnitOfMeasure) AS UnitOfMeasure,
		|	CASE
		|		WHEN OperationQueue.WorkCenter REFS Catalog.WorkCenterTypes
		|			THEN OperationQueue.WorkCenter
		|		ELSE (CAST(OperationQueue.WorkCenter AS Catalog.WorkCenters)).WorkCenterType
		|	END AS WorkCenterType,
		|	CASE
		|		WHEN OperationQueue.WorkCenter REFS Catalog.WorkCenters
		|			THEN OperationQueue.WorkCenter
		|		ELSE VALUE(Catalog.WorkCenters.EmptyRef)
		|	END AS WorkCenter,
		|	ISNULL(Operations.SetupSettings, OperationQueue.ProductionOperation.SetupSettings) AS SetupSettings,
		|	OperationQueue.TimeTotal AS RunTime,
		|	OperationQueue.TimeUnitsOfMeasure AS TimeUnitsOfMeasure,
		|	OperationQueue.Order AS Order,
		|	CASE
		|		WHEN &TheProductionScheduleIsUsed
		|				AND NOT Schedule.Stage IS NULL
		|			THEN Schedule.Begin
		|		ELSE DATEADD(OperationQueue.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(RegulatorySchedule.DurationBeforeStart, 0))
		|	END AS StartDate,
		|	OperationQueue.OperationNumber AS OperationNumber,
		|	OperationQueue.NextOperation AS NextOperation,
		|	ISNULL(Operations.LongDesc, OperationQueue.ProductionOperation.Comment) AS LongDesc,
		|	CASE
		|		WHEN OperationQueue.ExecutionIsAllowed > 0
		|				AND OperationQueue.ExecutionIsAllowed > OperationQueue.CreatedOn - (OperationQueue.Running + OperationQueue.Completed2 + OperationQueue.Skipped3)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS YouCanStartNow,
		|	Schedule.Begin AS StageStart,
		|	Schedule.NextStageStart AS NextStageStart,
		|	RegulatorySchedule.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
		|	ISNULL(OperationQueue.Operation.Description, OperationQueue.ProductionOperation.Description) AS Description,
		|	OperationQueue.State AS State,
		|	OperationQueue.ProductionOperation AS ProductionOperation,
		|	OperationQueue.ProductionOperation.ProductionArea AS ProductionArea,
		|	OperationQueue.ProductionOperation.Performer AS Performer
		|FROM
		|	InformationRegister.QueueOfProductionOperations AS OperationQueue
		|		LEFT JOIN Catalog.ManufacturingOperations AS Operations
		|		ON OperationQueue.Operation = Operations.Ref
		|		{LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		ON OperationQueue.ReferenceOrder = Schedule.ProductionOrder
		|			AND OperationQueue.Stage = Schedule.Stage
		|			AND (Schedule.ScheduleStatus = &StatusWorkingSchedule)}
		|		{LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS RegulatorySchedule
		|		ON OperationQueue.Stage = RegulatorySchedule.ProductionStage}
		|WHERE
		|	NOT OperationQueue.InArchive
		|	AND (OperationQueue.ProductionOperation = VALUE(Document.ProductionOperation2_2.EmptyRef)
		|		OR ISNULL(OperationQueue.ProductionOperation.Status,
		|				VALUE(Enum.ProductionOperationStatuses.EmptyRef)) = VALUE(Enum.ProductionOperationStatuses.BeingGenerated))
		|	AND OperationQueue.Scheduled > 0
		|	AND &TextSelectionBySite
		|
		|UNION ALL
		|
		|SELECT
		|	Queue.ReferenceOrder AS ReferenceOrder,
		|	Queue.Stage AS Stage,
		|	&PresentationStage AS PresentationStage,
		|	Queue.Department AS Department,
		|	Queue.Operation AS Operation,
		|	Queue.OperationID AS OperationID,
		|	Queue.Count AS WaitingForCreation,
		|	&ExecutionTimeWaitingForCreation AS ExecutionTimeWaitingForCreation,
		|	NULL AS ExecutionIsAllowed,
		|	NULL AS Running,
		|	ISNULL(Operations.Skippable, OperationQueue.ProductionOperation.Skippable) AS Skippable,
		|	ISNULL(Operations.UnitOfMeasure, OperationQueue.ProductionOperation.UnitOfMeasure) AS UnitOfMeasure,
		|	CASE
		|		WHEN OperationQueue.WorkCenter REFS Catalog.WorkCenterTypes
		|			THEN OperationQueue.WorkCenter
		|		ELSE (CAST(OperationQueue.WorkCenter AS Catalog.WorkCenters)).WorkCenterType
		|	END AS WorkCenterType,
		|	CASE
		|		WHEN OperationQueue.WorkCenter REFS Catalog.WorkCenters
		|			THEN OperationQueue.WorkCenter
		|		ELSE VALUE(Catalog.WorkCenters.EmptyRef)
		|	END AS WorkCenter,
		|	ISNULL(Operations.SetupSettings, OperationQueue.ProductionOperation.SetupSettings) AS SetupSettings,
		|	&RunTime AS RunTime,
		|	Queue.TimeUnitsOfMeasure AS TimeUnitsOfMeasure,
		|	Queue.Order AS Order,
		|	CASE
		|		WHEN &TheProductionScheduleIsUsed
		|				AND NOT Schedule.Stage IS NULL
		|			THEN Schedule.Begin
		|		ELSE DATEADD(Queue.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(RegulatorySchedule.DurationBeforeStart, 0))
		|	END AS StartDate,
		|	Queue.OperationNumber AS OperationNumber,
		|	Queue.NextOperation AS NextOperation,
		|	ISNULL(Operations.LongDesc, OperationQueue.ProductionOperation.Comment) AS LongDesc,
		|	Queue.AssignmentIsAllowed AS YouCanStartNow,
		|	Schedule.Begin AS StageStart,
		|	Schedule.NextStageStart AS NextStageStart,
		|	RegulatorySchedule.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
		|	ISNULL(Queue.Operation.Description, OperationQueue.ProductionOperation.Description) AS Description,
		|	OperationQueue.State AS State,
		|	OperationQueue.ProductionOperation AS ProductionOperation,
		|	OperationQueue.ProductionOperation.ProductionArea AS ProductionArea,
		|	OperationQueue.ProductionOperation.Performer AS Performer
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Queue
		|		LEFT JOIN Catalog.ManufacturingOperations AS Operations
		|		ON Queue.Operation = Operations.Ref
		|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS OperationQueue
		|		ON Queue.Stage = OperationQueue.Stage
		|		AND Queue.Operation = OperationQueue.Operation
		|		AND Queue.OperationID = OperationQueue.OperationID
		|		AND OperationQueue.MainEntry_
		|		{LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		ON Queue.ReferenceOrder = Schedule.ProductionOrder
		|			AND Queue.Stage = Schedule.Stage
		|			AND (Schedule.ScheduleStatus = &StatusWorkingSchedule)}
		|		{LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS RegulatorySchedule
		|		ON Queue.Stage = RegulatorySchedule.ProductionStage}
		|WHERE
		|	Queue.ShiftTask = VALUE(Document.ShiftTask.EmptyRef)
		|	AND &TextSelectionBySite";
	
	QueryText = StrReplace(QueryText, "UNION ALL", "~");
	
	If ShiftJobsAreUsed Then
		
		QueryText = StrSplit(QueryText,"~")[1];
		
		QueryText = StrReplace(
			QueryText,
			"&ExecutionTimeWaitingForCreation",
			InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("Queue"));
		
		QueryText = StrReplace(
			QueryText,
			"&RunTime",
			InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("Queue"));
		
	Else
		
		QueryText = StrSplit(QueryText,"~")[0];
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &TextSelectionBySite",
		?(Not ValueIsFilled(ProductionArea), "",
			"	AND (OperationQueue.WorkCenter IN (
			|								UNDEFINED,
			|								VALUE(Catalog.WorkCenters.EmptyRef),
			|								VALUE(Catalog.WorkCenterTypes.EmptyRef))
			|		OR OperationQueue.WorkCenter REFS Catalog.WorkCenters
			|			AND (CAST(OperationQueue.WorkCenter AS Catalog.WorkCenters)).ProductionArea = &ProductionArea
			|		OR OperationQueue.WorkCenter REFS Catalog.WorkCenterTypes
			|			AND TRUE IN
			|				(SELECT TOP 1
			|					TRUE
			|				FROM
			|					Catalog.WorkCenters AS T
			|				WHERE
			|					T.WorkCenterType = OperationQueue.WorkCenter
			|					AND T.ProductionArea = &ProductionArea)
			|		OR ISNULL(OperationQueue.ProductionOperation.ProductionArea, UNDEFINED) = &ProductionArea
			|)"));
	
	Documents.ProductionStage2_2.ReplacePresentationField(
			QueryText, "&PresentationStage", "OperationQueue.Stage");
	
	Return QueryText;
	
EndFunction

#Region Filters

&AtClient
Procedure SetFiltersClient(Result = Undefined, AdditionalParameters = Undefined) Export
	SetFilters(Result, AdditionalParameters);
EndProcedure

&AtServer
Procedure SetFilters(Result = Undefined, AdditionalParameters = Undefined)
	
	If Result <> Undefined Then
		
		ExecutionIsAllowed = Result.ExecutionIsAllowed;
		RCView          = Result.RCView;
		WorkCenter   = Result.WorkCenter;
		Performer    = Result.Performer;
		Operation       = Result.Operation;
		Product        = Result.Product;
		Lot         = Result.Lot;
		Stage           = Result.Stage;
		ProductionArea        = Result.ProductionArea;
	
	EndIf;
	
	FiltersLine = "";
	
	SetSelectionCanBePerformed();
	SetSelectionByStage();
	SetSelectionByBatch();
	SetSelectionByProduct();
	SetSelectionByOperation();
	AddToSelectionLine(Performer);
	SetSelectionByWorkCenter();
	SetSelectionBySite();
	SetSelectionByDivision();
	
	ConfigureSelectionElements();
	
	CalculateDownload_()
	
EndProcedure

&AtServer
Procedure SetSelectionCanBePerformed()
	
	CommonClientServer.SetDynamicListFilterItem(OperationAssignment1,
		"YouCanStartNow",
		ExecutionIsAllowed,
		DataCompositionComparisonType.Equal,
		,
		ExecutionIsAllowed);
	
EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	CommonClientServer.SetDynamicListFilterItem(OperationAssignment1,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Department));
EndProcedure

&AtServer
Procedure SetSelectionByWorkCenter()
	
	If ValueIsFilled(WorkCenter) Then
		
		RCDivision = Common.ObjectAttributeValue(WorkCenter,"WorkCenterType.Department");
		RCSection = Common.ObjectAttributeValue(WorkCenter,"ProductionArea");
		
		If RCDivision <> Department
			Or (ValueIsFilled(ProductionArea) And RCSection <> ProductionArea) Then
			
			MessageText = NStr("vi = 'Nguồn lực sản xuất được chọn không thuộc bộ phận hoặc khu vực hiện tại';
								|ru = 'Выбранный рабочий центр не находится в текущем подразделении или участке';
								|en = 'The selected work center is not in the current business unit or site'; fa = 'The selected work center is not in the current business unit or site';
								|it = 'Il centro operativo selezionato non si trova nel reparto corrente o area';
								|pl = 'Wybrane centrum pracy nie znajduje się w bieżącym dziale lub działce';
								|tr = 'Seçili iş merkezi, mevcut departmanda veya sahada bulunmamaktadır'");
			Common.MessageToUser(MessageText);
			
			WorkCenter = Undefined;
			
			Return;
			
		EndIf;
		
	EndIf;
	
	RCValues = New ValueList;
	RCValues.Add(WorkCenter);
	RCValues.Add(PredefinedValue("Catalog.WorkCenters.EmptyRef"));
	RCValues.Add(Undefined);
	
	CommonClientServer.SetDynamicListFilterItem(
	OperationAssignment1, 
	"WorkCenter", 
	RCValues, 
	DataCompositionComparisonType.InList,
	, 
	ValueIsFilled(WorkCenter));
	
	VRCValues = New ValueList;
	VRCValues.Add(Common.ObjectAttributeValue(WorkCenter,"WorkCenterType"));
	VRCValues.Add(PredefinedValue("Catalog.WorkCenterTypes.EmptyRef"));
	VRCValues.Add(Undefined);
	
	CommonClientServer.SetDynamicListFilterItem(
	OperationAssignment1, 
	"WorkCenterType", 
	VRCValues, 
	DataCompositionComparisonType.InList,
	,
	ValueIsFilled(WorkCenter));
	
	If Not ValueIsFilled(WorkCenter) And ValueIsFilled(RCView) Then
		CommonClientServer.SetDynamicListFilterItem(
		OperationAssignment1, 
		"WorkCenterType", 
		VRCValues, 
		DataCompositionComparisonType.InList,
		,
		True);
		
		AddToSelectionLine(RCView);
	EndIf;
	
	AddToSelectionLine(WorkCenter);
	
EndProcedure

&AtServer
Procedure SetSelectionByOperation()
	CommonClientServer.SetDynamicListFilterItem(OperationAssignment1,
		"Operation",
		Operation,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Operation));
		
	AddToSelectionLine(Operation);
	
EndProcedure

&AtServer
Procedure SetSelectionByProduct()
	CommonClientServer.SetDynamicListFilterItem(OperationAssignment1,
		"Stage.ProductionLot.MainProductProducts",
		Product,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Product));
		
	AddToSelectionLine(Product);
	
EndProcedure

&AtServer
Procedure SetSelectionByBatch()
	CommonClientServer.SetDynamicListFilterItem(OperationAssignment1,
		"Stage.ProductionLot",
		Lot,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Lot));
		
	AddToSelectionLine(Lot);
	
EndProcedure

&AtServer
Procedure SetSelectionByStage()
	CommonClientServer.SetDynamicListFilterItem(OperationAssignment1,
		"Stage",
		Stage,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Stage));
		
	AddToSelectionLine(Stage);
	
EndProcedure

&AtServer
Procedure SetSelectionBySite()
	If Not PlotInSettings Then
	
		SetPropertiesOfDynamicListPerformOperations();
		
		Items.ExecutionOfOperations.Refresh();
		
	EndIf;
	If ValueIsFilled(ProductionArea) Then
		AddToSelectionLine(ProductionArea);
	EndIf;
EndProcedure

&AtClient
Procedure FillInSelectionForm(Barcode)
	
	Ref = GetRef(Barcode);
	
	If TypeOf(Ref) = Type("CatalogRef.WorkCenters") And Not Rcvconfigurations Then
		
		WorkCenter = Ref;
		
	ElsIf (TypeOf(Ref) = Type("CatalogRef.Persons")
		) And Not ArtistInSettings Then
		
		Performer = Ref;
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.ManufacturingOperations") Then
		
		Operation = Ref;
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.Products") Then
		
		Product = Ref;
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.ProductionLots") Then
		
		Lot = Ref;
		
	ElsIf TypeOf(Ref) = Type("DocumentRef.ProductionStage2_2") Then
		
		Stage = Ref;
		
	Else
		
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Không tìm thấy mã vạch';
							|ru = 'Штрих-код не найден';
							|en = 'Barcode is not found'; fa = 'Barcode is not found';
							|it = 'Codice a barre non trovato';
							|pl = 'Kod kreskowy nie został znaleziony';
							|tr = 'Barkod bulunamadı'");
		Message.Message();
		
	EndIf;
	
	SetFilters();
EndProcedure

&AtServer
Procedure ConfigureSelectionElements()
	
	If FiltersLine = "" Then
		FiltersLine = ?(ExecutionIsAllowed,NStr("vi = 'Đặt bộ lọc *';
												|ru = 'Установить отбор*';
												|en = 'Set filter*'; fa = 'Set filter*';
												|it = 'Impostare selezione*';
												|pl = 'Ustaw dobór*';
												|tr = 'Filtre yapılandır*'"),NStr("vi = 'Đặt bộ lọc';
																			|ru = 'Установить отбор';
																			|en = 'Set filter'; fa = 'تعیین فیلتر';
																			|it = 'Impostare selezione';
																			|pl = 'Ustaw wybór';
																			|tr = 'Filtre yapılandır'"));
		Items.ClearFilters.Visible = False;
	Else
		FiltersLine = Left(FiltersLine, StrLen(FiltersLine)-2);
		Items.ClearFilters.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddToSelectionLine(Ref)
	If ValueIsFilled(Ref) Then
		DocumentsTypesDetails = Documents.AllRefsType();

		LinkDocument_ = DocumentsTypesDetails.ContainsType(TypeOf(Ref));
		
		FiltersLine = FiltersLine
			+ ?(LinkDocument_,
				Common.ObjectAttributeValue(Ref, "Number"),
				Common.ObjectAttributeValue(Ref, "Description"))
			+ ", ";
	EndIf;
EndProcedure


#EndRegion

&AtServerNoContext
Function GetRef(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionStage2_2.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.ProductionLots.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.Products.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.WorkCenters.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.ManufacturingOperations.EmptyRef"));
	Managers.Add(PredefinedValue("Document.ProductionOperation2_2.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.Persons.EmptyRef"));

	References = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode,Managers);
	
	If References.Count() > 0 Then
		
		If TypeOf(References[0]) = Type("DocumentRef.ProductionOperation2_2") Then
			Return References[0].Operation;
		Else
			Return References[0];
		EndIf;
	
	EndIf;
	Return Undefined;

EndFunction

&AtServer
Procedure CalculateDownload_()
	
	Items.Load.Visible = ValueIsFilled(WorkCenter) Or ValueIsFilled(Performer);
	
	CalculatedLoad = ProductionAccounting.CalculateDownload(WorkCenter, Performer, Department);
	
	If ValueIsFilled(WorkCenter) > 0 Then
		
		Load = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tải xuống NLSX % %1 h';
				|ru = 'Загрузка РЦ %1 ч';
				|en = 'Work center load %1 h'; fa = 'Work center load %1 h';
				|it = 'Download del centro operativo%1 ore';
				|pl = 'Pobieranie CP %1 g';
				|tr = 'İM yükü %1 sa.'"), CalculatedLoad.WorkCenter);
		
	EndIf;
	
	If ValueIsFilled(Performer) > 0 Then
		
		If ValueIsFilled(WorkCenter) Then
		
			Load = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1, người thực hiện %2 giờ';
				|ru = '%1, исполнителя %2 ч';
				|en = '%1, assignee %2 h'; fa = '%1, assignee %2 h';
				|it = '%1, dell''assegnatario %2 ore';
				|pl = '%1, wykonawcy %2 g';
				|tr = '%1, atanan %2 sa.'"),Load, CalculatedLoad.Performer);
			
		Else
		
			Load = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tải xuống người thực hiện %1 h';
					|ru = 'Загрузка исполнителя %1 ч';
					|en = 'Assignee import %1 h'; fa = 'Assignee import %1 h';
					|it = 'Download dell''assegnatario %1 ore';
					|pl = 'Pobieranie wykonawcy %1 g';
					|tr = 'Atanan yükü %1 sa.'"), CalculatedLoad.Performer);
		
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AdditionalDownload(RunTime)
	
	DoNotUseRPI = Not (ValueIsFilled(Performer) And ValueIsFilled(WorkCenter));
	
	SubstringSignPosition = StrFind(Load,"(");
	
	If SubstringSignPosition > 0 Then
		
		If DoNotUseRPI Then
			Load = Left(Load,SubstringSignPosition - 2) + Chars.NBSp + NStr("vi = 'giờ';
																			|ru = 'ч';
																			|en = 'h'; fa = 'ساعت';
																			|it = 'ore';
																			|pl = 'godz.';
																			|tr = 'sa.'");
		Else
			Load = Left(Load,SubstringSignPosition - 2);
		EndIf;
		
	EndIf;
	
	If RunTime > 0 Then
		
		If DoNotUseRPI Then
			
			SubstringSignPosition = StrFind(Load,NStr("vi = 'giờ';
														|ru = 'ч';
														|en = 'h'; fa = 'ساعت';
														|it = 'ore';
														|pl = 'godz.';
														|tr = 'sa.'"));
			
			Load = Left(Load,SubstringSignPosition - 2) + " (+" + Round(RunTime,2) + NStr("vi = ') h';
																							|ru = ') ч';
																							|en = ') h'; fa = ') h';
																							|it = ') ore';
																							|pl = ') g';
																							|tr = ') sa.'");
			
		Else
			
			Load = Load + " (+" + Round(RunTime,2) + ")";
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function CheckGetOperationsHighlightedInList(SelectedRows)
	
	If SelectedRows.Count() = 0 Then
		
		Result = Undefined;
		
		ShowMessageBox(, NStr("vi = 'Không có thao tác nào được chọn để hoàn thành giao dịch';
								|ru = 'Не выбраны операции для выполнения действия';
								|en = 'Operations to execute the action are not selected'; fa = 'Operations to execute the action are not selected';
								|it = 'Nessuna operazione selezionata per eseguire l''azione';
								|pl = 'Nie wybrano operacji dla wykonania czynności';
								|tr = 'Eylemin gerçekleştirilmesi için herhangi bir işlem seçilmedi'"));
		
	Else
		
		Result = New Array;
		
		For Each String In SelectedRows Do
			
			If TypeOf(String) = Type("DynamicListGroupRow") Then
				
				ShowMessageBox(, NStr("vi = 'Thao tác không thể được thực hiện trên một dòng nhóm danh sách.';
										|ru = 'Действие не может быть выполнено для строки группировки списка';
										|en = 'Action cannot be executed for the list grouping row'; fa = 'Action cannot be executed for the list grouping row';
										|it = 'L''operazione non può essere eseguita per la riga di raggruppamento dell''elenco';
										|pl = 'Czynność nie może być wykonana dla wiersza grupowania listy';
										|tr = 'Liste gruplandırma satırı için eylem gerçekleştirilemez'"));
				
				Result = Undefined;
				Break;
				
			Else
				
				Var_Key = ProductionManagementClientServer.ProductionOperationKey(True);
				FillPropertyValues(Var_Key, Items.ExecutionOfOperations.RowData(String));
				Result.Add(Var_Key);
				
			EndIf;
		
		EndDo;
		
	EndIf;
	
	If Result <> Undefined Then
		Result = OperationKeys(Result);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function OperationKeys(StructuresArray)
	
	Result = New Array;
	
	For Each KeyData In StructuresArray Do
		Result.Add(InformationRegisters.QueueOfProductionOperations.CreateRecordKey(KeyData));
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion
