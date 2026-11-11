
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("ReferenceOrder", ReferenceOrder) Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'This data processor is not intended for manual use.'; fa = 'This data processor is not intended for manual use.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Veri işlemcisi, doğrudan kullanıma yönelik değildir.'");
	EndIf;
	
	UseHourInterval = Constants.UsePlanningIntervalHour.Get();
	
	UploadFormSettings();
	SetSelectionToShowCompletedStages(StagesAreDynamic, ShowCompletedDynamicStages);
	
	ReadTheseOrders();
	
	CustomizeFormWhenCreatingIt();
	
	UpdateChartData();
	
	AvailabilityControl(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartWaitingForLongOperations();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If ScheduleIsPlanned And Not DynamicStructure Then
		
		Cancel = True;
		ShowQuestionAboutSavingChartBeforeClosing();
		
	ElsIf ToDeleteResultsBeforeClosing Then
		
		Cancel = True;
		DeleteSchedulingResultsOnClient(True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	CancelLongRunningOperationsWhenClosing();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowOnlyCheckTheOrderingIfYouChange(Item)
	
	SetSelectionToOnlyDelayOrderSteps(Stages, OnlyStagesThatDelayTheOrder);
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure DecorationThereAreNoDelaysInProvidingClick(Item)
	
	DecipherProvisionOfMaterialsByModel();
	
EndProcedure

&AtClient
Procedure ShowCompletedDynamicStagesOnChange(Item)
	
	SetSelectionToShowCompletedStages(StagesAreDynamic, ShowCompletedDynamicStages);
	SaveFormSettingsClient();
	
EndProcedure

#EndRegion

#Region EventHandlersForChartElementsOfFormDueDates

&AtClient
Procedure ExecutionDatesDetailProcessing(Item, Decryptions, StandardProcessing, Date)
	
	If TypeOf(Decryptions) = Type("Array")
		And Decryptions.Count() > 1 Then
		
		DetailsValue  = Decryptions[1];
		
		If TypeOf(DetailsValue) = Type("Number") Then
			
			StandardProcessing = False;
			
			FormParameters = New Structure;
			FormParameters.Insert("ProductionOrder", ReferenceOrder);
			FormParameters.Insert("ScheduleStatus", DetailsValue);
			
			OpenForm(
				"Report.MonitorOrder.ObjectForm",
				FormParameters,, True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormDiagramElementsHardwareLoading

&AtClient
Procedure LoadingEquipmentSelection(Item, ChartValue, StandardProcessing)
	
	DecryptionProcessingHardwareLoading(StandardProcessing);
	
EndProcedure

&AtClient
Procedure LoadingEquipmentDetailProcessing(Item, Details, StandardProcessing)
	
	DecryptionProcessingHardwareLoading(StandardProcessing);
	
EndProcedure

#EndRegion

#Region EventHandlersForChartElementsFormContentManagement

&AtClient
Procedure MaterialSupplySelection(Item, ChartValue, StandardProcessing)
	
	StandardProcessing = False;
	DecipherProvisionOfMaterialsByModel();
	
EndProcedure

&AtClient
Procedure MaterialSupplyDetailProcessing(Item, Details, StandardProcessing)
	
	StandardProcessing = False;
	DecipherProvisionOfMaterialsByModel();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersErrors

&AtClient
Procedure ErrorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	RowData = Errors.FindByID(RowSelected);
	
	ErrorCodes = SchedulingErrorCodes();
	
	If RowData.Details.ErrorCode = ErrorCodes.ErrorCodeVRCAvailability Then
		
		FormParameters = New Structure;
		FormParameters.Insert("WorkMode", PredefinedValue(
			"Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule"));
		
		If ValueIsFilled(RowData.Details.WorkCenterType) Then
			FormParameters.Insert("WorkCenterType", RowData.Details.WorkCenterType);
			FormParameters.Insert("BeginOfPeriod", RowData.Details.Period);
		Else
			FormParameters.Insert("Department", RowData.Details.Department);
		EndIf;
		
		OpenForm("DataProcessor.AvailabilityOfWorkCenterTypes.Form", FormParameters);
		
	ElsIf RowData.Details.ErrorCode = ErrorCodes.ErrorCodeDivisionSchedule Then
		
		ShowValue(, RowData.Details.Department);
		
	ElsIf RowData.Details.ErrorCode = ErrorCodes.ErrorCodeBusinessHours Then
		
		OpenForm("DataProcessor.TMAdministrationPanel.Form.Enterprise");
		
	ElsIf RowData.Details.ErrorCode = ErrorCodes.ErrorCodeMissingPredecessorGraph Then
		
		FormParameters = New Structure("ReferenceOrder", RowData.Details.ReferenceOrder);
		OpenForm(
			"DataProcessor.ProductionSchedulePlanning2_2.Form.CreatingProductionOrderSchedule",
			FormParameters,
			,
			RowData.Details.ReferenceOrder);
			
	ElsIf RowData.Details.ErrorCode = ErrorCodes.ErrorCodeThereAreCyclesInChainOfStages Then
		
		ShowValue(, RowData.Details.ProductionStage);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStagesAreDynamic

&AtClient
Procedure StagesAreDynamicBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure StagesAreDynamicSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.StagesAreDynamic.CurrentData;
	
	If Field.Name = "StagesAreDynamicDepartment" Then
		ShowValue(, CurrentData.Department);
	ElsIf Field.Name = "StagesAreDynamicBillOfMaterials" Then
		ShowValue(, CurrentData.BillOfMaterials);
	ElsIf Field.Name = "StagesAreDynamicProducts" Then
		ShowValue(, CurrentData.Products);
	ElsIf Field.Name = "StagesAreDynamicProductionOrder" Then
		ShowValue(, CurrentData.ProductionOrder);
	Else
		ShowValue(, CurrentData.Stage);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToPlan_2(Command)
	
	CallbackDescription = New CallbackDescription("SelectSchedulingSettingsEnd", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ProductionOrder", ReferenceOrder);
	FormParameters.Insert("DynamicStructure", DynamicStructure);
	
	OpenForm("DataProcessor.ProductionSchedulePlanning2_2.Form.PlanningSettingsReferences",
		FormParameters,
		,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	If ScheduleIsPlanned Then
		
		SaveOnClient(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Reread(Command)
	
	If (ScheduleIsPlanned Or ModelIsPlanned) And Not DynamicStructure Then
		
		CallbackDescription = New CallbackDescription("QuestionRereadDataCompletion", ThisObject);
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Đọc lại dữ liệu?';
						|ru = 'Данные изменены. Перечитать данные?';
						|en = 'Data is changed. Reread?'; fa = 'Data is changed. Reread?';
						|it = 'I dati sono stati modificati. Rileggere i dati?';
						|pl = 'Dane zostały zmienione. Przeliczyć dane?';
						|tr = 'Veri değişti. Tekrar okunsun mu?'");
		Buttons = QuestionDialogMode.YesNo;
		DefaultButton = DialogReturnCode.Yes;
		
		ShowQueryBox(CallbackDescription, QueryText, Buttons,, DefaultButton);
		
	Else
		
		ReReadDataOnServer();
		StartWaitingForLongOperations();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiagramOfAdjacentStages(Command)
	
	If Not CheckSelectedLineInList(Items.Stages) Then
		Return;
	EndIf;
	
	ProductionStage = Items.Stages.CurrentRow;
	ScheduleStatus = ScheduleStatusListOfStages(ThisObject);
		
	FormParameters = New Structure;
	FormParameters.Insert("CommandParameter", ProductionStage);
	FormParameters.Insert("ScheduleStatus", ScheduleStatus);
	
	OpenForm(
		"Report.ConnectedProductionStagesChart.ObjectForm",
		FormParameters,
		ThisObject,
		ProductionStage);
	
EndProcedure

&AtClient
Procedure StageResourceChart(Command)
	
	If Not CheckSelectedLineInList(Items.Stages) Then
		Return;
	EndIf;
	
	ProductionStage = Items.Stages.CurrentRow;
	ScheduleStatus = ScheduleStatusListOfStages(ThisObject);
		
	FormParameters = New Structure;
	FormParameters.Insert("CommandParameter", ProductionStage);
	FormParameters.Insert("ScheduleStatus", ScheduleStatus);
	
	OpenForm(
		"Report.ProductionStageResourceChart.Form",
		FormParameters,
		ThisObject,
		ProductionStage);
	
EndProcedure

&AtClient
Procedure DiagnosticsOfDynamicStage(Command)
	
	If Not CheckSelectedLineInList(Items.StagesAreDynamic) Then
		Return;
	EndIf;
	
	CurrentData = Items.StagesAreDynamic.CurrentData;
	
	FormParameters = New Structure;
	If TypeOf(CurrentData.Stage) = Type("DocumentRef.ProductionStage2_2") Then
		FormParameters.Insert("CommandParameter", CurrentData.Stage);
	Else
		FormParameters.Insert("Stage", CurrentData.Stage);
		FormParameters.Insert("KeyLot", CurrentData.KeyLot);
		FormParameters.Insert("ProductionOrder", ReferenceOrder);
	EndIf;
	
	FormParameters.Insert("ScheduleStatus", ScheduleStatusListOfStages(ThisObject));
	
	UniqueKey = String(CurrentData.KeyLot)
		+ String(CurrentData.Stage.UUID());
	
	OpenForm(
		"Report.ProductionStageResourceChart.Form",
		FormParameters,
		ThisObject,
		UniqueKey);
	
EndProcedure

&AtClient
Procedure DiagramOfAdjacentDynamicStages(Command)
	
	If Not CheckSelectedLineInList(Items.StagesAreDynamic) Then
		Return;
	EndIf;
	
	CurrentData = Items.StagesAreDynamic.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("ScheduleStatus", ScheduleStatusListOfStages(ThisObject));
	If TypeOf(CurrentData.Stage) = Type("DocumentRef.ProductionStage2_2") Then
		FormParameters.Insert("CommandParameter", CurrentData.Stage);
	Else
		FormParameters.Insert("Stage", CurrentData.Stage);
		FormParameters.Insert("KeyLot", CurrentData.KeyLot);
		FormParameters.Insert("ProductionOrder", ReferenceOrder);
	EndIf;
	
	UniqueKey = String(CurrentData.KeyLot)
		+ String(CurrentData.Stage.UUID());
		
	OpenForm(
		"Report.ConnectedProductionStagesChart.ObjectForm",
		FormParameters,
		ThisObject,
		UniqueKey);
	
EndProcedure

#EndRegion

#Region Private

#Region Planning

&AtClient
Procedure SelectSchedulingSettingsEnd(CalculationSettings, AdditionalParameters) Export
	
	If CalculationSettings = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	StartWaiting = PlanScheduleInBackground(CalculationSettings);
	
	If StartWaiting Then
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("PlanScheduleInBackgroundCompletion", ThisObject),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
	Else
		AfterSchedulingScheduleOnClient();
	EndIf;
	
EndProcedure

&AtServer
Function PlanScheduleInBackground(CalculationSettings)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = DataProcessors.ProductionSchedulePlanning2_2.NameOfScheduleCalculationTask();
	
	If DynamicStructure Then
		ProcedureName = "OrderStructureProductionSchedule.CalculateWorkScheduleAndModel";
		
		If Common.FileInfobase() Then
			CalculationProtocol = Documents.ProductionOrder2_2.OrderStructureCalculationProtocol(ReferenceOrder);
			
			If CalculationProtocol.State = CalculationProtocol.StateCodes.NotCalculated
				Or CalculationProtocol.State = CalculationProtocol.StateCodes.CalculatedHasErrors
				Or CalculationProtocol.State = CalculationProtocol.StateCodes.NotCalculatedHasErrors
				Or CalculationProtocol.State = CalculationProtocol.StateCodes.IsCancelled Then
				Common.MessageToUser(
					NStr("vi = 'Структура заказа на производство не рассчитана. Рекомендуется пересчитать график после расчета структуры.';
						|ru = 'Структура заказа на производство не рассчитана. Рекомендуется пересчитать график после расчета структуры.';
						|en = 'The production order structure is not calculated. It is recommended that you recalculate the schedule after calculating the structure.'; fa = 'The production order structure is not calculated. It is recommended that you recalculate the schedule after calculating the structure.';
						|it = 'Структура заказа на производство не рассчитана. Рекомендуется пересчитать график после расчета структуры.';
						|pl = 'The production order structure is not calculated. It is recommended that you recalculate the schedule after calculating the structure.';
						|tr = 'Структура заказа на производство не рассчитана. Рекомендуется пересчитать график после расчета структуры.'"),
					ReferenceOrder);
			ElsIf CalculationProtocol.State = CalculationProtocol.StateCodes.Calculating
				Or CalculationProtocol.State = CalculationProtocol.StateCodes.AwaitingCalculation Then
				ExecutionParameters.RunInBackground = True;
			EndIf;
		EndIf;
	Else
		ProcedureName = "ProductionManagementOverridable.PlanPreliminarySchedule";
	EndIf;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, CalculationSettings, ExecutionParameters);
	If TimeConsumingOperation.Status = "Running" Then
		StartWaiting = True;
	Else
		ProcessResultOfSchedulePlanning(TimeConsumingOperation);
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtClient
Procedure PlanScheduleInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		ProcessResultOfSchedulePlanning(Result);
		AfterSchedulingScheduleOnClient();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfSchedulePlanning(Result)
	
	If Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	ElsIf Result.Status = "Completed2" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		If TypeOf(ResultStructure) = Type("Structure") Then
			FillPropertyValues(
				ThisObject,
				ResultStructure,
				"ScheduleIsPlanned, ModelIsPlanned, NumberOfJobForCalculatingProductionSchedule, CancelManualChangesOfSchedule");
			PlacedStages.LoadValues(ResultStructure.PlacedStages);
			
			ValueToFormAttribute(ResultStructure.Errors, "Errors");
			ReportSchedulingErrors();
			
			ShowAlerts(ResultStructure.Notifications);
			
			AvailabilityControl(ThisObject);
			
			UpdateChartData();
			
			If ModelIsPlanned
				Or ScheduleIsPlanned And Not DynamicStructure Then
				ToDeleteResultsBeforeClosing = True;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSchedulingScheduleOnClient()
	
	StartWaitingForLongOperations();
	If DynamicStructure And ScheduleIsPlanned Then
		Notify("Write_ProductionSchedule", ReferenceOrder);
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithSeveralFederalLaws

&AtServer
Procedure FillInLengthyFormOperations()
	
	NewRow = FormLongActions.Add();
	NewRow.Name = LongRunningOperationNameReleaseDates();
	NewRow.StartWaiting = False;
	NewRow.TimeConsumingOperation = Undefined;
	
	NewRow = FormLongActions.Add();
	NewRow.Name = NameOfLongRunningOperationLoadingHardware();
	NewRow.StartWaiting = False;
	NewRow.TimeConsumingOperation = Undefined;
	
	NewRow = FormLongActions.Add();
	NewRow.Name = NameOfLongRunningOperationProvidingMaterials();
	NewRow.StartWaiting = False;
	NewRow.TimeConsumingOperation = Undefined;
	
EndProcedure

&AtClientAtServerNoContext
Function TimeConsumingOperationDetails(Form, Name)
	
	TheStructureOfTheSearch = New Structure("Name", Name);
	FoundRows = Form.FormLongActions.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() = 0 Then
		Result = Undefined;
	Else
		Result = FoundRows[0];
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure CancelLongRunningOperationsWhenClosing()
	
	For Each String In FormLongActions Do
		If Not String.TimeConsumingOperation = Undefined Then
			
			CancelLongRunningOperation(String.Name);

		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CancelLongRunningOperation(Name)
	
	OperationDescription = TimeConsumingOperationDetails(ThisObject, Name);
	
	If Not OperationDescription.TimeConsumingOperation = Undefined Then
		
		TimeConsumingOperations.CancelJobExecution(OperationDescription.TimeConsumingOperation.JobID);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function LongRunningOperationNameReleaseDates()
	
	Return "ReadProductReleaseTime";
	
EndFunction

&AtClientAtServerNoContext
Function NameOfLongRunningOperationLoadingHardware()
	
	Return "ReadingHardwareLoad";
	
EndFunction

&AtClientAtServerNoContext
Function NameOfLongRunningOperationProvidingMaterials()
	
	Return "MaterialSupportSystem";
	
EndFunction

&AtClientAtServerNoContext
Function LongRunningOperationStatusInProgress()
	
	Return "Running";
	
EndFunction

&AtClientAtServerNoContext
Function LongRunningOperationStatusCompleted()
	
	Return "Completed2";
	
EndFunction

&AtClientAtServerNoContext
Function LongRunningOperationStatusError()
	
	Return "Error";
	
EndFunction

&AtClient
Procedure StartWaitingForLongOperations()
	
	For Each String In FormLongActions Do
		
		If String.StartWaiting Then
			
			CallbackOnCompletion = NotificationOfCompletionOfLongOperation(String.Name);
			
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = False;
			
			TimeConsumingOperationsClient.WaitCompletion(
				String.TimeConsumingOperation,
				CallbackOnCompletion,
				IdleParameters);
			
			DisplayStartOfWaitingForLongOperation(String.Name);
			
			String.StartWaiting = False;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Function NotificationOfCompletionOfLongOperation(Name)
	
	If Name = LongRunningOperationNameReleaseDates() Then
		
		Result = New CallbackDescription("ReadProductReleaseDatesInBackgroundCompletion", ThisObject);
		
	ElsIf Name = NameOfLongRunningOperationLoadingHardware() Then
		
		Result = New CallbackDescription("FillInDiagramLoadingEquipmentInBackgroundCompletion", ThisObject);
		
	ElsIf Name = NameOfLongRunningOperationProvidingMaterials() Then
		
		Result = New CallbackDescription("FillInDiagramWithAllMaterialsInBackgroundCompletion", ThisObject);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure DisplayStartOfWaitingForLongOperation(Name)
	
	If Name = LongRunningOperationNameReleaseDates() Then
		
		Items.TheGroupProductsAreLongLastingOperation.CurrentPage = Items.PageProductsLongOperation;
		
	ElsIf Name = NameOfLongRunningOperationLoadingHardware() Then
		
		Items.TheGroupLoadEquipmentLongTermOperation.CurrentPage =
			Items.PageLoadingHardwareLongOperation;
	
	ElsIf Name = NameOfLongRunningOperationProvidingMaterials() Then
		
		Items.GroupProvisionOfMaterialsALongRunningOperation.CurrentPage =
			Items.PageContentEnsuringALongRunningOperation;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ReadingUpdatingData

&AtServer
Procedure ReReadDataOnServer()
	
	Errors.Clear();
	
	ReadTheseOrders();
	UpdateChartData();
	
	ReadingTheDataAgain = False;
	
EndProcedure

&AtServer
Procedure ReadTheseOrders()
	
	If ReferenceOrder.IsEmpty() Then
		Return;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	OrderDocument.Date AS Date,
		|	OrderDocument.Number AS Number,
		|	OrderDocument.ProductionProcessType AS ProductionProcessType,
		|	OrderDocument.DynamicStructure AS DynamicStructure,
		|	OrderDocument.EarliestStartDate AS EarliestStartDate
		|FROM
		|	Document.ProductionOrder2_2 AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(ManufacturedProduct.DemandDate) AS DemandDate
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS ManufacturedProduct
		|WHERE
		|	ManufacturedProduct.Ref = &Ref
		|HAVING
		|	COUNT(ManufacturedProduct.Ref) > 0");
	Query.SetParameter("Ref", ReferenceOrder);
	
	QueryResults = Query.ExecuteBatch();
	
	TheseOrders_ = QueryResults[0].Select();
	TheseOrders_.Next();
	FillPropertyValues(ThisObject, TheseOrders_, "EarliestStartDate, DynamicStructure");
	
	TabularSectionData = QueryResults[1].Select();
	If TabularSectionData.Next() Then
		DemandDate = TabularSectionData.DemandDate;
	Else
		DemandDate = '00010101';
	EndIf;
	
	ThisIsDisassembly = (TheseOrders_.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly);
	
	TheNumberOfTheOrder = ObjectsPrefixesClientServer.NumberForPrinting(
		TheseOrders_.Number, False, True);
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lập kế hoạch lịch biểu sản xuất đơn hàng số %1 ngày %2';
			|ru = 'Планирование графика производства заказа № %1 от %2';
			|en = 'Production schedule creating for order No.%1 dated %2'; fa = 'Production schedule creating for order No.%1 dated %2';
			|it = 'Programmazione del piano di produzione dell''ordine № %1 del %2';
			|pl = 'Planowanie harmonogramu produkcji zlecenia № %1 od %2';
			|tr = '%2 tarihli %1 numaralı siparişin üretim programının planlanması'"),
		TheNumberOfTheOrder,
		Format(TheseOrders_.Date, "DLF=D"));
	Items.FormSave.Visible = Not DynamicStructure;
	Items.PageGroupListOfStages.CurrentPage = ?(DynamicStructure,
		Items.PageListOfDynamicStages,
		Items.PageListOfStages);
	
EndProcedure

&AtServer
Procedure UpdateChartData()
	
	ReadTimeline();
	
	FillInTimelineDiagram();
	FillInDiagramLoadingEquipmentInBackground();
	FillInDiagramWithAllMaterialsInBackground();
	
	ReadProductReleaseDatesInBackground();
	
	FillInformationLabels();
	
	SetParametersOfStagesList();
	
	ShowHideErrors();
	
EndProcedure

&AtServer
Procedure ReadTimeline()
	
	StatusWorkingSchedule = StatusWorkingSchedule();
	StatusPreliminarySchedule = StatusPreliminarySchedule();
	ModelStatus = StatusChartModel();
	
	ChartStatuses = New Array;
	If ScheduleIsPlanned And Not DynamicStructure Then
		ChartStatuses.Add(StatusPreliminarySchedule);
	Else
		ChartStatuses.Add(StatusWorkingSchedule);
	EndIf;
	If ModelIsPlanned Then
		ChartStatuses.Add(ModelStatus);
	EndIf;
	
	Query = New Query(
	"SELECT DISTINCT
	|	ScheduleOfProductionStages2_2.Stage AS Stage
	|INTO TTHostedStages
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|WHERE
	|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|	AND ScheduleOfProductionStages2_2.ScheduleStatus <> &StatusWorkingSchedule
	|
	|INDEX BY
	|	Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(ScheduleOfProductionStages2_2.Begin) AS StartDate2
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|		LEFT JOIN TTHostedStages AS TTHostedStages
	|		ON ScheduleOfProductionStages2_2.Stage = TTHostedStages.Stage
	|WHERE
	|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusWorkingSchedule
	|	AND TTHostedStages.Stage IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfProductionStages2_2.ScheduleStatus,
	|	MIN(ScheduleOfProductionStages2_2.Begin) AS StartDate2,
	|	MAX(ScheduleOfProductionStages2_2.Ending) AS DateOfProduction
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|WHERE
	|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|	AND ScheduleOfProductionStages2_2.ScheduleStatus IN(&ChartStatuses)
	|
	|GROUP BY
	|	ScheduleOfProductionStages2_2.ScheduleStatus");
	
	Query.SetParameter("ProductionOrder", ReferenceOrder);
	Query.SetParameter("ChartStatuses", ChartStatuses);
	Query.SetParameter("StatusWorkingSchedule", StatusWorkingSchedule);
	
	ResultsArray = Query.ExecuteBatch();
	
	Selection = ResultsArray[1].Select();
	If Selection.Next() And ValueIsFilled(Selection.StartDate2) Then
		LaunchDateWorkSchedule = Selection.StartDate2;
	Else
		LaunchDateWorkSchedule = Undefined;
	EndIf;
	
	Selection = ResultsArray[2].Select();
	
	ScheduleDeadlinesAreFilled = False;
	ModelTermsAreFilled = False;
	
	While Selection.Next() Do
		
		If Selection.ScheduleStatus = StatusPreliminarySchedule
			Or Selection.ScheduleStatus = StatusWorkingSchedule Then
			
			LaunchDateSchedule = Selection.StartDate2;
			ReleaseDateSchedule = Selection.DateOfProduction;
			ScheduleDeadlinesAreFilled = True;
			
		ElsIf Selection.ScheduleStatus = ModelStatus Then
			
			LaunchDateModel = Selection.StartDate2;
			ReleaseDateModel = Selection.DateOfProduction;
			ModelTermsAreFilled = True;
			
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(LaunchDateWorkSchedule) Then
		
		If ValueIsFilled(LaunchDateSchedule) Then
			LaunchDateSchedule = Min(LaunchDateSchedule, LaunchDateWorkSchedule);
		EndIf;
		If ValueIsFilled(LaunchDateModel) Then
			LaunchDateModel = Min(LaunchDateModel, LaunchDateWorkSchedule);
		EndIf;
		
	EndIf;
	
	If ScheduleDeadlinesAreFilled Then
		LateSchedule = LineDelay(DemandDate, ReleaseDateSchedule, UseHourInterval);
		DurationChart = DateDifferenceByString(LaunchDateSchedule, ReleaseDateSchedule, UseHourInterval);
	Else
		LaunchDateSchedule = '00010101';
		ReleaseDateSchedule = '00010101';
		LateSchedule = "";
		DurationChart = "";
	EndIf;
	
	If ModelTermsAreFilled Then
		LateArrivalModel = LineDelay(DemandDate, ReleaseDateModel, UseHourInterval);
		TheDurationModel = DateDifferenceByString(LaunchDateModel, ReleaseDateModel, UseHourInterval);
	Else
		LaunchDateModel = '00010101';
		ReleaseDateModel = '00010101';
		LateArrivalModel = "";
		TheDurationModel = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadProductReleaseDatesInBackground()
	
	OperationName = LongRunningOperationNameReleaseDates();
	CancelLongRunningOperation(OperationName);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ReferenceOrder", ReferenceOrder);
	ProcedureParameters.Insert("ScheduleIsPlanned", ScheduleIsPlanned);
	ProcedureParameters.Insert("ModelIsPlanned", ModelIsPlanned);
	ProcedureParameters.Insert("DynamicStructure", DynamicStructure);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Đọc ngày xuất xưởng sản phẩm';
														|ru = 'Чтение сроков выпуска продукции';
														|en = 'Read product release time'; fa = 'Read product release time';
														|it = 'La lettura dei tempi di emissione prodotti';
														|pl = 'Czytanie terminów wyprodukowania produkcji';
														|tr = 'İmal edilen ürün çıkışı süresinin okunması'");
	ExecutionParameters.RunInBackground = True;
	
	LongTermFormOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ProductionSchedulePlanning2_2.ReadProductReleaseDates",
		ProcedureParameters,
		ExecutionParameters);
	
	OperationDescription = TimeConsumingOperationDetails(ThisObject, OperationName);
	If LongTermFormOperation.Status = LongRunningOperationStatusInProgress() Then
		
		OperationDescription.TimeConsumingOperation = LongTermFormOperation;
		OperationDescription.StartWaiting = True;
		
	Else
		
		OperationDescription.TimeConsumingOperation = Undefined;
		OperationDescription.StartWaiting = False;
		
		ProcessResultOfReadingReleaseDatesInBackground(LongTermFormOperation);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DownloadProductReleaseDates(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	If TypeOf(Result) = Type("ValueTable") Then
		
		ManufacturedProduct.Load(Result);
		For Each String In ManufacturedProduct Do
			
			If ValueIsFilled(String.LaunchDateSchedule) Then
				String.LateSchedule = LineDelay(
						String.DemandDate, String.ReleaseDateSchedule, UseHourInterval);
				String.DurationChart = DateDifferenceByString(
					String.LaunchDateSchedule, String.ReleaseDateSchedule, UseHourInterval);
			EndIf;
			
			If ValueIsFilled(String.LaunchDateModel) Then
				String.LateArrivalModel = LineDelay(
						String.DemandDate, String.ReleaseDateModel, UseHourInterval);
				String.TheDurationModel = DateDifferenceByString(
					String.LaunchDateModel, String.ReleaseDateModel, UseHourInterval);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Items.TheGroupProductsAreLongLastingOperation.CurrentPage = Items.ProductsDataPage;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearAndShowProductionDates(Form)
	
	Form.ManufacturedProduct.Clear();
	Form.Items.TheGroupProductsAreLongLastingOperation.CurrentPage = Form.Items.ProductsDataPage;
	
EndProcedure

&AtClient
Procedure ReadProductReleaseDatesInBackgroundCompletion(Result, AdditionalParameters) Export
	
	OperationName = LongRunningOperationNameReleaseDates();
	OperationDescription = TimeConsumingOperationDetails(ThisObject, OperationName);
	OperationDescription.TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		
		ClearAndShowProductionDates(ThisObject);
		
	Else
		
		ProcessResultOfReadingReleaseDatesInBackground(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfReadingReleaseDatesInBackground(Result)
	
	If Result.Status = LongRunningOperationStatusCompleted() Then
		
		DownloadProductReleaseDates(Result.ResultAddress);
		
	Else
		
		ClearAndShowProductionDates(ThisObject);
		
		If Result.Status = LongRunningOperationStatusError() Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInformationLabels()
	
	PlacedManually_ = 0;
	CalculateTheSchedule = 0;
	ThereArePriorities = False;
	ThereAreEntriesInSchedule = False;
	
	ReadInformationLabelData(PlacedManually_, CalculateTheSchedule, ThereArePriorities, ThereAreEntriesInSchedule);
	
	If PlacedManually_ > 0 Then
		
		Items.TheLabelIsPlacedManually.Title = StrTemplate(
			NStr("vi = 'Có các công đoạn được lên lịch thủ công (tổng cộng: %1).';
				|ru = 'Имеются этапы, запланированные вручную (всего: %1).';
				|en = 'There are stages scheduled manually (total: %1).'; fa = 'There are stages scheduled manually (total: %1).';
				|it = 'Ci sono le fasi programmate manualmente (totale: %1).';
				|pl = 'Są etapy, zaplanowane ręcznie (ogółem: %1).';
				|tr = 'Manuel olarak planlanan aşamalar mevcut (toplam: %1).'"),
			PlacedManually_);
		Items.ManuallyPlacedGroup.Visible = True;
		
	Else
		
		Items.ManuallyPlacedGroup.Visible = False;
		
	EndIf;
	
	If CalculateTheSchedule > 0 Then
		
		If DynamicStructure Then
			Items.TheLabelTheRelevanceOfTheGraph.Title = 
				NStr("vi = 'Chưa cập nhật lịch biểu đơn hàng. Có các công đoạn cần lập lại kế hoạch.';
					|ru = 'График заказа не актуален. Имеются этапы, требующие перепланирования.';
					|en = 'Order schedule is not relevant. There are stages which require rescheduling.'; fa = 'Order schedule is not relevant. There are stages which require rescheduling.';
					|it = 'График заказа не актуален. Имеются этапы, требующие перепланирования.';
					|pl = 'Order schedule is not relevant. There are stages which require rescheduling.';
					|tr = 'Sipariş programı güncel değil. Yeniden planlanması gereken aşamalar var.'");
		Else
			Items.TheLabelTheRelevanceOfTheGraph.Title = StrTemplate(
				NStr("vi = 'Lịch trình đặt hàng không liên quan. Có những công đoạn yêu cầu lập kế hoạch lại (tổng: %1).';
					|ru = 'График заказа не актуален. Имеются этапы, требующие перепланирования (всего: %1).';
					|en = 'Order schedule is not relevant. There are stages which require replanning (total: %1).'; fa = 'Order schedule is not relevant. There are stages which require replanning (total: %1).';
					|it = 'Il piano dell''ordine non è rilevante. Ci sono fasi che richiedono la ripianificazione (totale: %1).';
					|pl = 'Harmonogram zlecenia jest nieaktualny. Są etapy, które wymagają ponownego planowania (ogółem: %1).';
					|tr = 'Sipariş programı güncel değil. Yeniden planlanması gereken aşamalar var (toplam: %1).'"),
				CalculateTheSchedule);
		EndIf;
		
	Else
		
		Items.TheLabelTheRelevanceOfTheGraph.Title = NStr("vi = 'Lịch trình đặt hàng được cập nhật.';
															|ru = 'График заказа актуален.';
															|en = 'Order schedule is relevant.'; fa = 'Order schedule is relevant.';
															|it = 'Il piano dell''ordine è pertinente.';
															|pl = 'Harmonogram zlecenia jest aktualny.';
															|tr = 'Sipariş programı güncel.'");
		
	EndIf;
	
	Items.GroupAvailabilityOfHigherPriorityOrders.Visible = ThereArePriorities;
	Items.GroupIsRequiredToCalculateSchedule.Visible = Not ThereAreEntriesInSchedule;
	
EndProcedure

&AtServer
Procedure ReadInformationLabelData(PlacedManually_, CalculateTheSchedule, ThereArePriorities, ThereAreEntriesInSchedule)
	
	TempTablesManager = New TempTablesManager;
	Documents.ProductionOrder2_2.CreateTTOrdersWithHighPriority(
		TempTablesManager,
		"TTPriorityOrders",
		ReferenceOrder);
	
	DataProcessors.ProductionSchedulePlanning2_2.ReadNumberOfObjectsToSchedule(
		PlacedManually_,
		CalculateTheSchedule,
		ThereArePriorities,
		ThereAreEntriesInSchedule,
		ReferenceOrder,
		TempTablesManager,
		"TTPriorityOrders");
	
EndProcedure

&AtServer
Procedure SetParametersOfStagesList()
	
	ScheduleStatus = ScheduleStatusListOfStages(ThisObject);
	
	Stages.Parameters.SetParameterValue("ReferenceOrder", ReferenceOrder);
	Stages.Parameters.SetParameterValue("ScheduleStatus", ScheduleStatus);
	
	StagesAreDynamic.Parameters.SetParameterValue("ReferenceOrder", ReferenceOrder);
	StagesAreDynamic.Parameters.SetParameterValue("ScheduleStatus", ScheduleStatus);
	
	StageStatuses_2 = New Array;
	StageStatuses_2.Add(Enums.StatusesOfProductionStages2_2.BeingGenerated);
	StageStatuses_2.Add(Enums.StatusesOfProductionStages2_2.Generated1);
	StageStatuses_2.Add(Enums.StatusesOfProductionStages2_2.ForCompletion);
	Stages.Parameters.SetParameterValue("StageStatuses_2", StageStatuses_2);
	
EndProcedure

&AtClientAtServerNoContext
Function ScheduleStatusListOfStages(Form)
	
	If Form.ScheduleIsPlanned And Not Form.DynamicStructure Then
		Result = StatusPreliminarySchedule();
	Else
		Result = StatusWorkingSchedule();
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ReportSchedulingErrors()
	
	If Errors.Count() > 0 Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Xảy ra lỗi trong khi lập kế hoạch lịch trình.';
				|ru = 'При планировании графика возникли ошибки.';
				|en = 'Errors occurred when planning the schedule.'; fa = 'Errors occurred when planning the schedule.';
				|it = 'Si sono verificati degli errori durante la programmazione del piano.';
				|pl = 'Przy planowaniu harmonogramu wystąpiły błędy.';
				|tr = 'Program planlanırken bir hata oluştu.'"),
			,
			"Errors");
			
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowAlerts(Notifications)
	
	If TypeOf(Notifications) = Type("Array") Then
		For Each Notification In Notifications Do
			CommonClientServer.MessageToUser(Notification);
		EndDo;
	ElsIf TypeOf(Notifications) = Type("Map") Then
		For Each KeyAndValue In Notifications Do
			Common.MessageToUser(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowHideErrors()
	
	Items.PageErrors.Visible = Not (Errors.Count() = 0);
	
EndProcedure

#EndRegion

#Region Save

&AtClient
Procedure SaveOnClient(BeforeClose)
	
	SaveBeforeClosing = BeforeClose;
	
	StartWaiting = SaveAtServer();
	
	If StartWaiting Then
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("SaveGraphInBackgroundEnd", ThisObject),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
	Else
		AfterSavingScheduleOnClient();
	EndIf;
	
EndProcedure

&AtServer
Function SaveAtServer()
	
	ProcedureName = "DataProcessors.ProductionSchedulePlanning2_2.WritePreliminaryScheduleToWorkingOne";
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ReferenceOrder", ReferenceOrder);
	ProcedureParameters.Insert("NumberOfJobForCalculatingProductionSchedule", NumberOfJobForCalculatingProductionSchedule);
	ProcedureParameters.Insert("CancelManualChangesOfSchedule", CancelManualChangesOfSchedule);
	ProcedureParameters.Insert("PlacedStages", PlacedStages.UnloadValues());
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Сохранение графика производства заказа';
														|ru = 'Сохранение графика производства заказа';
														|en = 'Save order production schedule'; fa = 'Save order production schedule';
														|it = 'Сохранение графика производства заказа';
														|pl = 'Zapisywanie harmonogramu produkcji zlecenia';
														|tr = 'Сохранение графика производства заказа'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, ExecutionParameters);
	If TimeConsumingOperation.Status = "Running" Then
		StartWaiting = True;
	Else
		ProcessResultOfSavingGraph(TimeConsumingOperation);
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtClient
Procedure SaveGraphInBackgroundEnd(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		ProcessResultOfSavingGraph(Result);
		AfterSavingScheduleOnClient();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ProcessResultOfSavingGraph(Result)
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSavingScheduleOnClient()
	
	ClearPlanningResults();
	Notify("Write_ProductionSchedule", ReferenceOrder);
	
	If SaveBeforeClosing Then
		
		Close();
		
	Else
		
		AvailabilityControl(ThisObject);
		UpdateChartData();
		StartWaitingForLongOperations();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQuestionAboutSavingChartBeforeClosing()
	
	CallbackDescription = New CallbackDescription("QuestionOfSavingBeforeClosingEnds", ThisObject);
	QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
					|ru = 'Данные были изменены. Сохранить изменения?';
					|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
					|it = 'I dati sono stati modificati. Salvare le modifiche?';
					|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
					|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
	Buttons = QuestionDialogMode.YesNoCancel;
	DefaultButton = DialogReturnCode.Cancel;
	
	ShowQueryBox(CallbackDescription, QueryText, Buttons,, DefaultButton);
	
EndProcedure

&AtClient
Procedure QuestionOfSavingBeforeClosingEnds(ClosingResult, AdditionalParameters) Export
	
	TheUserResponse = ClosingResult;
	
	If TheUserResponse = DialogReturnCode.Yes Then
		
		SaveOnClient(True);
		
	ElsIf TheUserResponse = DialogReturnCode.No Then
		
		DeleteSchedulingResultsOnClient(True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DeletingPlanningResults

&AtClient
Procedure DeleteSchedulingResultsOnClient(BeforeClose)
	
	DeleteResultsBeforeClosing = BeforeClose;
	
	StartWaiting = DeleteSchedulingResultsOnServer();
	
	If StartWaiting Then
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("DeletePlanningResultsInBackgroundEnd", ThisObject),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
	Else
		AfterDeletingPlanningResults();
	EndIf;
	
EndProcedure

&AtServer
Function DeleteSchedulingResultsOnServer()
	
	ProcedureName = "DataProcessors.ProductionSchedulePlanning2_2.ClearPreliminarySchedule";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Очистка предварительного графика производства';
														|ru = 'Очистка предварительного графика производства';
														|en = 'Clear preliminary production schedule'; fa = 'Clear preliminary production schedule';
														|it = 'Очистка предварительного графика производства';
														|pl = 'Czyszczenie wstępnego harmonogramu produkcji';
														|tr = 'Очистка предварительного графика производства'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, ReferenceOrder, ExecutionParameters);
	If TimeConsumingOperation.Status = "Running" Then
		StartWaiting = True;
	Else
		ProcessDeletionOfPlanningResult(TimeConsumingOperation);
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtClient
Procedure DeletePlanningResultsInBackgroundEnd(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		ProcessDeletionOfPlanningResult(Result);
		AfterDeletingPlanningResults();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ProcessDeletionOfPlanningResult(Result)
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDeletingPlanningResults()
	
	ClearPlanningResults();
	
	If DeleteResultsBeforeClosing Then
		
		Close();
		
	Else
		
		AvailabilityControl(ThisObject);
		
		If ReadingTheDataAgain Then
			ReReadDataOnServer();
		Else
			UpdateChartData();
		EndIf;
		
		StartWaitingForLongOperations();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearPlanningResults()
	
	ScheduleIsPlanned = False;
	ModelIsPlanned = False;
	ToDeleteResultsBeforeClosing = False;
	NumberOfJobForCalculatingProductionSchedule = 0;
	CancelManualChangesOfSchedule = False;
	Errors.Clear();
	PlacedStages.Clear();
	
EndProcedure

#EndRegion

#Region ChartLeadTimes

&AtServer
Procedure ConfigureTimelineChart()
	
	ExecutionDates.AutoDetectWholeInterval = False;
	ExecutionDates.AutoPointText = False;
	ExecutionDates.Animation = ChartAnimation.DontUse;
	ExecutionDates.VerticalScroll = False;
	ExecutionDates.Outline = False;
	ExecutionDates.ShowLegend = False;
	ExecutionDates.ShowEmptyValues = False;
	ExecutionDates.ShowTitle = False;
	ExecutionDates.ValueTextRepresentation = GanttChartValueTextRepresentation.None;
	ExecutionDates.ScaleKeeping = GanttChartScaleKeeping.AllData;
	ExecutionDates.Border = New Border(ControlBorderType.WithoutBorder);
	
	Items.ColorOrder.BackColor = IntervalColor(TypeOfIntervalOrder());
	Items.ColorChart.BackColor = IntervalColor(TypeOfIntervalGraph());
	Items.ColorModel.BackColor = IntervalColor(ViewIntervalModel());
	
EndProcedure

&AtServer
Procedure FillInTimelineDiagram()
	
	ExecutionDates.RefreshEnabled = False;
	ExecutionDates.Clear();
	
	Point = ExecutionDates.Points.Add();
	
	Boundaries = New Structure("Begin, Ending", '39991231', '00010101');
	
	If ValueIsFilled(EarliestStartDate) And ValueIsFilled(DemandDate) And Not ThisIsDisassembly Then
		AddIntervalToLeadTimes(Point, EarliestStartDate, DemandDate, TypeOfIntervalOrder(), Boundaries);
	EndIf;
	
	If ValueIsFilled(LaunchDateSchedule) And ValueIsFilled(ReleaseDateSchedule) Then
		AddIntervalToLeadTimes(Point, LaunchDateSchedule, ReleaseDateSchedule, TypeOfIntervalGraph(), Boundaries);
	EndIf;
	
	If ValueIsFilled(LaunchDateModel) And ValueIsFilled(ReleaseDateModel) Then
		AddIntervalToLeadTimes(Point, LaunchDateModel, ReleaseDateModel, ViewIntervalModel(), Boundaries);
	EndIf;
	
	ExecutionDates.RefreshEnabled = True;
	
	If ValueIsFilled(Boundaries.Ending) Then
		ConfigureTimeline(Boundaries.Begin, Boundaries.Ending);
	EndIf;
	
EndProcedure

&AtServer
Procedure AddIntervalToLeadTimes(Point, Begin, Ending, TypeOfInterval, Boundaries)
	
	Series = ExecutionDates.Series.Add();
	Series.Text = TypeOfInterval;
	Series.Color = IntervalColor(TypeOfInterval);
	
	Value = ExecutionDates.GetValue(Point, Series);
	
	Interval = Value.Add();
	Interval.Begin = Begin;
	Interval.End = Ending;
	
	If TypeOfInterval = TypeOfIntervalOrder() Then
		Interval.Details = ReferenceOrder;
	ElsIf TypeOfInterval = TypeOfIntervalGraph() Then
		If ScheduleIsPlanned And Not DynamicStructure Then
			Interval.Details = StatusPreliminarySchedule();
		Else
			Interval.Details = StatusWorkingSchedule();
		EndIf;
	ElsIf TypeOfInterval = ViewIntervalModel() Then
		Interval.Details = StatusChartModel();
	EndIf;
	
	Boundaries.Begin = Min(Boundaries.Begin, Begin);
	Boundaries.Ending = Max(Boundaries.Ending, Ending);
	
EndProcedure

&AtServer
Procedure ConfigureTimeline(Begin, Ending)
	
	ScaleSettings = ProductionManagementClientServer.GanttChartScaleSettingsInAllDataMode(
		Begin, Ending, 3);
	
	TimelineElements = ExecutionDates.PlotArea.TimeScale.Items;
	
	For IndexOf = 1 To TimelineElements.Count()-1 Do
		TimelineElements.Delete(TimelineElements[IndexOf]);
	EndDo;
	
	ScaleElement = TimelineElements.Add();
	ScaleElement.Unit = ScaleSettings.Unit;
	ScaleElement.Format = ScaleSettings.Format;
	
	If TimelineElements.Count() = 2 Then
		TimelineElements.Delete(TimelineElements[0]);
	EndIf;
	
	ExecutionDates.SetWholeInterval(
		ScaleSettings.BeginOfWholeInterval,
		ScaleSettings.EndOfFullInterval);
	
EndProcedure

&AtServer
Function TypeOfIntervalOrder()
	
	Return "ReferenceOrder";
	
EndFunction

&AtServer
Function TypeOfIntervalGraph()
	
	Return "Schedule";
	
EndFunction

&AtServer
Function ViewIntervalModel()
	
	Return "Model";
	
EndFunction

&AtServer
Function IntervalColor(TypeOfInterval)
	
	If TypeOfInterval = TypeOfIntervalOrder() Then
		
		Result = WebColors.LightGreen;
		
	ElsIf TypeOfInterval = TypeOfIntervalGraph() Then
		
		Result = WebColors.LightBlue;
		
	ElsIf TypeOfInterval = ViewIntervalModel() Then
		
		Result = WebColors.Khaki;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region EquipmentLoadingDiagram

&AtServer
Procedure ConfigureHardwareLoadingDiagram()
	
	If Not PlanningByProductionResourcesIsUsed() Then
		Return;
	EndIf;
	
	AdjustHistogram(LoadingEquipment);
	
EndProcedure

&AtServer
Procedure FillInDiagramLoadingEquipmentInBackground()
	
	If Not PlanningByProductionResourcesIsUsed() Then
		Return;
	EndIf;
	
	If ModelIsPlanned Then
		
		OperationName = NameOfLongRunningOperationLoadingHardware();
		CancelLongRunningOperation(OperationName);
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("ReferenceOrder", ReferenceOrder);
		ProcedureParameters.Insert("QuantityOfUnits", 5);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Đọc tải thiết bị theo mô hình';
															|ru = 'Чтение загрузки оборудования по модели';
															|en = 'Reading the equipment load according to model'; fa = 'Reading the equipment load according to model';
															|it = 'Lettura di download delle attrezzature per il modello';
															|pl = 'Czytanie obciążenia urządzenia według modelu';
															|tr = 'Modele göre ekipman yüklemenin okunması'");
		ExecutionParameters.RunInBackground = True;
		
		LongTermFormOperation = TimeConsumingOperations.ExecuteInBackground(
			"Reports.EquipmentLoadAccordingToProductionScheduleModel.GetMostLoadedHardware",
			ProcedureParameters,
			ExecutionParameters);
		
		OperationDescription = TimeConsumingOperationDetails(ThisObject, OperationName);
		If LongTermFormOperation.Status = LongRunningOperationStatusInProgress() Then
			
			OperationDescription.TimeConsumingOperation = LongTermFormOperation;
			OperationDescription.StartWaiting = True;
			
		Else
			
			OperationDescription.TimeConsumingOperation = Undefined;
			OperationDescription.StartWaiting = False;
			
			ProcessResultOfReadingHardwareLoadInBackground(LongTermFormOperation);
			
		EndIf;
		
	Else
		
		ClearAndShowHardwareLoading(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDiagramLoadingEquipmentInBackgroundCompletion(Result, AdditionalParameters) Export
	
	OperationName = NameOfLongRunningOperationLoadingHardware();
	OperationDescription = TimeConsumingOperationDetails(ThisObject, OperationName);
	OperationDescription.TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		
		ClearAndShowHardwareLoading(ThisObject);
		
	Else
		
		ProcessResultOfReadingHardwareLoadInBackground(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfReadingHardwareLoadInBackground(Result)
	
	If Result.Status = LongRunningOperationStatusCompleted() Then
		
		FillInHardwareLoad(Result.ResultAddress);
		
	Else
		
		ClearAndShowHardwareLoading(ThisObject);
		
		If Result.Status = LongRunningOperationStatusError() Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInHardwareLoad(ResultAddress)
	
	LoadingEquipment.RefreshEnabled = False;
	LoadingEquipment.Clear();
		
	Data = GetFromTempStorage(ResultAddress);
	If ValueIsFilled(Data) Then
		
		DetailsOfVRC = Common.ObjectsAttributesValues(
			Data.UnloadColumn("WorkCenterType"),
			"Presentation");
		
		Data.Sort("LoadingPercentages Asc");
		
		Series = LoadingEquipment.Series.Add("Load");
		Series.Color = WebColors.Salmon;
		
		For IndexOf = 0 To Data.Count()-1 Do
			
			Details = Data[IndexOf].WorkCenterType;
			PointText = DetailsOfVRC.Get(Details).Presentation;
			Value = Data[IndexOf].LoadingPercentages;
			ToolTip = PointText + ", " + Value + "%";
			
			Point = LoadingEquipment.Points.Add();
			Point.Text = PointText;
			
			LoadingEquipment.SetValue(Point, Series, Value, Details, ToolTip);
			
		EndDo;
		
	EndIf;
	
	LoadingEquipment.RefreshEnabled = True;
	
	Items.TheGroupLoadEquipmentLongTermOperation.CurrentPage = Items.HardwareLoadingPageDiagram;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearAndShowHardwareLoading(Form)
	
	Form.LoadingEquipment.Clear();
	Form.Items.TheGroupLoadEquipmentLongTermOperation.CurrentPage = Form.Items.HardwareLoadingPageDiagram;
	
EndProcedure

&AtClient
Procedure DecryptionProcessingHardwareLoading(StandardProcessing)
	
	StandardProcessing = False;
	
	If ModelIsPlanned Then
		
		Filter = New Structure("ReferenceOrder", ReferenceOrder);
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Filter", Filter);
		ReportParameters.Insert("GenerateOnOpen", True);
		ReportParameters.Insert("CloseOnOwnerClose", True);
		
		OpenForm(
			"Report.EquipmentLoadAccordingToProductionScheduleModel.ObjectForm",
			ReportParameters,
			ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DiagramMaterialsSupply

&AtServer
Procedure SetUpChartWithMaterials()
	
	If Not PlanningByMaterialResourcesIsUsed() Then
		Return;
	EndIf;
	
	AdjustHistogram(MaterialSupply);
	
EndProcedure

&AtServer
Procedure FillInDiagramWithAllMaterialsInBackground()
	
	If Not PlanningByMaterialResourcesIsUsed() Then
		Return;
	EndIf;
	
	If ModelIsPlanned Then
		
		OperationName = NameOfLongRunningOperationProvidingMaterials();
		CancelLongRunningOperation(OperationName);
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("ReferenceOrder", ReferenceOrder);
		ProcedureParameters.Insert("QuantityOfUnits", 5);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Đọc yêu cầu vật liệu theo mô hình';
															|ru = 'Чтение потребности в материалах по модели';
															|en = 'Reading the demand for materials according to model'; fa = 'Reading the demand for materials according to model';
															|it = 'Lettura di fabbisogno dei materiali per il modello';
															|pl = 'Czytanie potrzeb materiałowych według modelu';
															|tr = 'Modele göre malzeme gereksiniminin okunması'");
		ExecutionParameters.RunInBackground = True;
		
		LongTermFormOperation = TimeConsumingOperations.ExecuteInBackground(
			"Reports.DemandForMaterialsAccordingToProductionScheduleModel.GetMaterialsWithGreatestDelayInSecuring",
			ProcedureParameters,
			ExecutionParameters);
		
		OperationDescription = TimeConsumingOperationDetails(ThisObject, OperationName);
		If LongTermFormOperation.Status = LongRunningOperationStatusInProgress() Then
			
			OperationDescription.TimeConsumingOperation = LongTermFormOperation;
			OperationDescription.StartWaiting = True;
			
		Else
			
			OperationDescription.TimeConsumingOperation = Undefined;
			OperationDescription.StartWaiting = False;
			
			ProcessResultOfReadingWithMaterialsInBackground(LongTermFormOperation);
			
		EndIf;
		
	Else
		
		CleanAndShowProvidingMaterials(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDiagramWithAllMaterialsInBackgroundCompletion(Result, AdditionalParameters) Export
	
	OperationName = NameOfLongRunningOperationProvidingMaterials();
	OperationDescription = TimeConsumingOperationDetails(ThisObject, OperationName);
	OperationDescription.TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		
		CleanAndShowProvidingMaterials(ThisObject);
		
	Else
		
		ProcessResultOfReadingWithMaterialsInBackground(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfReadingWithMaterialsInBackground(Result)
	
	If Result.Status = LongRunningOperationStatusCompleted() Then
		
		MaterialSupport(Result.ResultAddress);
		
	Else
		
		CleanAndShowProvidingMaterials(ThisObject);
		
		If Result.Status = LongRunningOperationStatusError() Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure MaterialSupport(ResultAddress)
	
	MaterialSupply.Clear();
		
	Data = GetFromTempStorage(ResultAddress);
	If ValueIsFilled(Data) Then
		
		MaterialSupply.RefreshEnabled = False;
		
		ProductAttributes = Common.ObjectsAttributesValues(
			Data.UnloadColumn("Products"),
			"Presentation");
		
		Data.Sort("LateArrival Asc");
		
		Series = MaterialSupply.Series.Add("LateArrival");
		Series.Color = WebColors.Salmon;
		
		For IndexOf = 0 To Data.Count()-1 Do
			
			Details = Data[IndexOf].Products;
			PointText = ProductAttributes.Get(Details).Presentation;
			Value = Data[IndexOf].LateArrival;
			ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1, %2 ngày';
					|ru = '%1, %2 дн.';
					|en = '%1, %2 days'; fa = '%1, %2 days';
					|it = '%1, %2 giorni.';
					|pl = '%1, %2 dn.';
					|tr = '%1, %2 gün'"), PointText, Value);
			
			Point = MaterialSupply.Points.Add();
			Point.Text = PointText;
			
			MaterialSupply.SetValue(Point, Series, Value, Details, ToolTip);
			
		EndDo;
		
		MaterialSupply.RefreshEnabled = True;
		Items.GroupProvisionOfMaterialsALongRunningOperation.CurrentPage =
			Items.PageProvidingMaterialsDiagram;
		
	Else
		
		Items.GroupProvisionOfMaterialsALongRunningOperation.CurrentPage =
			Items.PageProvidingMaterialsThereAreNoDelays;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CleanAndShowProvidingMaterials(Form)
	
	Form.MaterialSupply.Clear();
	Form.Items.GroupProvisionOfMaterialsALongRunningOperation.CurrentPage = Form.Items.PageProvidingMaterialsDiagram;
	
EndProcedure

&AtClient
Procedure DecipherProvisionOfMaterialsByModel()
	
	If ModelIsPlanned Then
		
		Filter = New Structure("ReferenceOrder", ReferenceOrder);
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Filter", Filter);
		ReportParameters.Insert("VariantKey", "NeedForMaterialsContext");
		ReportParameters.Insert("GenerateOnOpen", True);
		ReportParameters.Insert("CloseOnOwnerClose", True);
		
		OpenForm(
			"Report.DemandForMaterialsAccordingToProductionScheduleModel.ObjectForm",
			ReportParameters,
			ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region UnitsOfMeasurement
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "ManufacturedProduct.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	#EndRegion

	#Region ScheduleLatenessHeader
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReleaseDateSchedule.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LateSchedule.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DemandDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LateSchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsDisassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	#EndRegion
	
	#Region LateOnSchedule
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductReleaseDateSchedule.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductLateSchedule.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DemandDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManufacturedProduct.LateSchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsDisassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	#EndRegion
	
	#Region LatenessForHeaderModel
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReleaseDateModel.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LateArrivalModel.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DemandDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LateArrivalModel");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsDisassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	#EndRegion
		
	#Region DelayByProductModel
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductReleaseDateModel.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductLateArrivalModel.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DemandDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManufacturedProduct.LateArrivalModel");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsDisassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	#EndRegion
	
	#Region ScheduleDates
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductLaunchDateSchedule.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductReleaseDateSchedule.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductLaunchDateModel.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductReleaseDateModel.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductDemandDate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesBegin.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesEnding.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesAreDynamicBegin.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesAreDynamicEnding.Name);
	
	Item.Appearance.SetParameterValue(
		"Format",
		FormatStringForProductionScheduleDate());
	
	#EndRegion
	
	#Region DynamicFontStages
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesAreDynamic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StagesAreDynamic.CanBeScheduled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	#EndRegion
	
	#Region EverythingIsProduced
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductReleaseDateSchedule.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductLateSchedule.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManufacturedProduct.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("ManufacturedProduct.NumberOfPackagesIsReady");
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	#EndRegion
	
	#Region ModelDates
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductLaunchDateModel.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductReleaseDateModel.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductLateArrivalModel.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductTheDurationModel.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ModelIsPlanned");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure CustomizeFormWhenCreatingIt()
	
	SetUpFormItemsVisibility();
	ConfigureFormatOfElementsWithDateType();
	ConfigureTimelineChart();
	ConfigureHardwareLoadingDiagram();
	SetUpChartWithMaterials();
	FillInLengthyFormOperations();
	FillInProductDesignations();
	CustomizeListRequestText();
	
	Items.FormToPlan_2.Enabled = Not ReferenceOrder.IsEmpty();
	
	If DynamicStructure And Not ThisIsDisassembly Then
		Items.ManufacturedProductNumberOfPackages.Title = NStr("vi = 'Được yêu cầu';
																|ru = 'Требуется';
																|en = 'Required'; fa = 'موردنیاز';
																|it = 'Required';
																|pl = 'Required';
																|tr = 'Gerekli'");
	Else
		Items.ManufacturedProductNumberOfPackagesIsReady.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInProductDesignations()
	
	Template = DataProcessors.ProductionSchedulePlanning2_2.GetTemplate("ProductsTableDetails");
	Area = Template.GetArea("Details");
	ProductDesignations.Put(Area);
	
EndProcedure

&AtServer
Procedure CustomizeListRequestText()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = StrReplace(
		Stages.QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("StagesOverridable"));
	Common.SetDynamicListProperties(Items.Stages, ListProperties);
	
	QueryText = StagesAreDynamic.QueryText;
	QueryText = StrReplace(
		QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage(
			"CAST(ScheduleOverridable.Stage AS Document.ProductionStage2_2)"));
	QueryText = StrReplace(
		QueryText,
		"&StatusIsWaitingToBeGenerated",
		NStr("vi = '""Chờ lập chứng từ""';
			|ru = '""Ожидает формирования""';
			|en = '""Pending generation""'; fa = '""Pending generation""';
			|it = '""Pending generation""';
			|pl = '""Pending generation""';
			|tr = '""Oluşturulmayı bekliyor""'"));
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.StagesAreDynamic, ListProperties);
	
EndProcedure

&AtServer
Procedure SetUpFormItemsVisibility()
	
	Items.TheGroupOfTheSoftware.Visible = PlanningByProductionResourcesIsUsed();
	Items.GroupProvisionOfMaterials.Visible = PlanningByMaterialResourcesIsUsed();
	
	// Header
	Items.DemandDate.Visible = Not ThisIsDisassembly;
	Items.TitleDecoration4.Visible = Not ThisIsDisassembly;
	Items.LateSchedule.Visible = Not ThisIsDisassembly;
	Items.LateArrivalModel.Visible = Not ThisIsDisassembly;
	
	// The Lateness column in the table
	Items.ManufacturedProductLateSchedule.Visible = Not ThisIsDisassembly;
	Items.ManufacturedProductLateArrivalModel.Visible = Not ThisIsDisassembly;
	Items.ManufacturedProductDemandDate.Visible = DynamicStructure;
	Items.ManufacturedProductStartDate2.Visible = Not DynamicStructure;
	Items.ProductionDuration.Visible = Not DynamicStructure;
	
	// Chart Legend
	Items.ColorOrder.Visible = Not ThisIsDisassembly;
	Items.LegendOrder.Visible = Not ThisIsDisassembly;
	
EndProcedure

&AtServer
Procedure ConfigureFormatOfElementsWithDateType()
	
	FormatString = FormatStringForProductionScheduleDate();
	
	Items.EarliestStartDate.EditFormat = FormatString;
	Items.DemandDate.EditFormat = FormatString;
	Items.LaunchDateSchedule.EditFormat = FormatString;
	Items.ReleaseDateSchedule.EditFormat = FormatString;
	Items.LaunchDateModel.EditFormat = FormatString;
	Items.ReleaseDateModel.EditFormat = FormatString;
	
EndProcedure

&AtServer
Function FormatStringForProductionScheduleDate()
	
	Return ProductionManagement.FormatStringForProductionScheduleDate();	
	
EndFunction

&AtClientAtServerNoContext
Function LineDelay(Val Date1, Val Date2, UseHourInterval)
	
	If Not ValueIsFilled(Date1)
		Or Not ValueIsFilled(Date2) Then
		Return "";
	EndIf;
	
	Result = "";
	
	If UseHourInterval Then
		DifferenceHours_ = Int((Date2 - Date1)/3600);
		If DifferenceHours_ >= 1 Then
			If DifferenceHours_ <= 48 Then
				Result = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 h';
						|ru = '%1 ч.';
						|en = '%1 h.'; fa = '%1 h.';
						|it = '%1 ore.';
						|pl = '%1 g.';
						|tr = '%1 sa.'"),
					DifferenceHours_);
			Else
				DifferenceDays_ = Int((BegOfDay(Date2) - BegOfDay(Date1))/86400);
				Result = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 ngày';
						|ru = '%1 дн.';
						|en = '%1 days'; fa = '%1 days';
						|it = '%1 giorni.';
						|pl = '%1 dn.';
						|tr = '%1 gün'"),
					Format(DifferenceDays_, "NG=0"));
			EndIf;
		EndIf;
	Else
		DifferenceDays_ = Int((BegOfDay(Date2) - BegOfDay(Date1))/86400);
		If DifferenceDays_ >= 1 Then
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 ngày';
					|ru = '%1 дн.';
					|en = '%1 days'; fa = '%1 days';
					|it = '%1 giorni.';
					|pl = '%1 dn.';
					|tr = '%1 gün'"),
				Format(DifferenceDays_, "NG=0"));
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function DateDifferenceByString(Val Date1, Val Date2, UseHourInterval)
	
	If Not ValueIsFilled(Date1)
		Or Not ValueIsFilled(Date2) Then
		Return "";
	EndIf;
	
	Result = "";
	
	If UseHourInterval Then
		DifferenceHours_ = Int((Date2 - Date1)/3600);
		If DifferenceHours_ >= 1 Then
			If DifferenceHours_ <= 48 Then
				Result = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 h';
						|ru = '%1 ч.';
						|en = '%1 h.'; fa = '%1 h.';
						|it = '%1 ore.';
						|pl = '%1 g.';
						|tr = '%1 sa.'"),
					DifferenceHours_);
			Else
				DifferenceDays_ = Round(DifferenceHours_ / 24, 0);
				Result = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 ngày';
						|ru = '%1 дн.';
						|en = '%1 days'; fa = '%1 days';
						|it = '%1 giorni.';
						|pl = '%1 dn.';
						|tr = '%1 gün'"),
					Format(DifferenceDays_, "NG=0"));
			EndIf;
		EndIf;
	Else
		DifferenceDays_ = Int((EndOfDay(Date2) + 1 - BegOfDay(Date1))/86400);
		If DifferenceDays_ >= 1 Then
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 ngày';
					|ru = '%1 дн.';
					|en = '%1 days'; fa = '%1 days';
					|it = '%1 giorni.';
					|pl = '%1 dn.';
					|tr = '%1 gün'"),
				Format(DifferenceDays_, "NG=0"));
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	Form.Items.FormSave.Enabled = Form.ScheduleIsPlanned;
	Form.Modified = Form.ScheduleIsPlanned And Not Form.DynamicStructure;
	
	Form.Items.LaunchDateModel.Enabled = Form.ModelIsPlanned;
	Form.Items.ReleaseDateModel.Enabled = Form.ModelIsPlanned;
	Form.Items.LateArrivalModel.Enabled = Form.ModelIsPlanned;
	Form.Items.TheDurationModel.Enabled = Form.ModelIsPlanned;
	Form.Items.LoadingEquipment.Enabled = Form.ModelIsPlanned;
	Form.Items.MaterialSupply.Enabled = Form.ModelIsPlanned;
	
EndProcedure

&AtClient
Procedure QuestionRereadDataCompletion(TheUserResponse, AdditionalParameters) Export
	
	If TheUserResponse = DialogReturnCode.Yes Then
		
		ReadingTheDataAgain = True;
		DeleteSchedulingResultsOnClient(False);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndFunction

&AtServerNoContext
Function StatusPreliminarySchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusPreliminarySchedule();
	
EndFunction
	
&AtServerNoContext
Function StatusChartModel()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel();
	
EndFunction

&AtClientAtServerNoContext
Procedure SetSelectionToOnlyDelayOrderSteps(List, FilterValue)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"DelaysTheOrder", 
		FilterValue, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		FilterValue);
		
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionToShowCompletedStages(StagesAreDynamic, ShowCompletedDynamicStages)
	
	CommonClientServer.SetDynamicListFilterItem(
		StagesAreDynamic,
		"Status",
		PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed"),
		DataCompositionComparisonType.NotEqual,
		, // Presentation - automatically
		Not ShowCompletedDynamicStages);
	
EndProcedure

&AtClient
Procedure SaveFormSettingsClient()
	
	Settings = New Structure;
	Settings.Insert("OnlyStagesThatDelayTheOrder", OnlyStagesThatDelayTheOrder);
	Settings.Insert("ShowCompletedDynamicStages", ShowCompletedDynamicStages);
	
	SaveFormSettingsServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveFormSettingsServer(Settings)
	
	Common.CommonSettingsStorageSave(
		FormKey(),
		FormSettingsKey(),
		Settings);
	
EndProcedure

&AtServer
Procedure UploadFormSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		FormKey(),
		FormSettingsKey());
	
	If TypeOf(Settings) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, Settings);
		SetSelectionToOnlyDelayOrderSteps(Stages, OnlyStagesThatDelayTheOrder);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function FormKey()
	
	Return "DataProcessor.ProductionSchedulePlanning2_2.CreatingProductionOrderSchedule";
	
EndFunction

&AtClientAtServerNoContext
Function FormSettingsKey()
	
	Return "Main_";
	
EndFunction

&AtServer
Procedure AdjustHistogram(Chart)
	
	Chart.Animation = ChartAnimation.DontUse;
	Chart.AutoPointText = False;
	Chart.ChartType = ChartType.Bar;
	Chart.ShowLegend = False;
	Chart.ShowTitle = False;
	Chart.PlotArea.Top = 0;
	Chart.PlotArea.Left = 0;
	Chart.PlotArea.ValuesScale.GridLinesShowMode = ChartGridLinesShowMode.DontShow;
	Chart.PlotArea.BackColor = StyleColors.FormBackColor;
	
EndProcedure

&AtServerNoContext
Function SchedulingErrorCodes()
	
	Manager = DataProcessors.ProductionSchedulePlanning2_2;
	
	Result = New Structure;
	Result.Insert("ErrorCodeVRCAvailability", Manager.ErrorCodeVRCAvailability());
	Result.Insert("ErrorCodeDivisionSchedule", Manager.ErrorCodeDivisionSchedule());
	Result.Insert("ErrorCodeBusinessHours", Manager.ErrorCodeBusinessHours());
	Result.Insert("ErrorCodeMissingPredecessorGraph", Manager.ErrorCodeMissingPredecessorGraph());
	Result.Insert("ErrorCodeThereAreCyclesInChainOfStages", Manager.ErrorCodeThereAreCyclesInChainOfStages());
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function PlanningByProductionResourcesIsUsed()
	
	Return ProductionManagementCached.PlanningByProductionResourcesIsUsed();
	
EndFunction

&AtServerNoContext
Function PlanningByMaterialResourcesIsUsed()
	
	Return ProductionManagementCached.PlanningByMaterialResourcesIsUsed();
	
EndFunction

// Check the selected line in the list.
// 
// Parameters:
//  List - FormTable
// 
// Returns:
//  Boolean - True if the check is passed successfully
//
&AtClient
Function CheckSelectedLineInList(List)
	
	If List.CurrentRow = Undefined Then
		ShowMessageBox(,NStr("vi = 'Chưa chọn dòng danh sách';
							|ru = 'Не выбрана строка списка';
							|en = 'The list row is not selected'; fa = 'The list row is not selected';
							|it = 'Не выбрана строка списка';
							|pl = 'The list row is not selected';
							|tr = 'Liste satırı seçilmemiş'"));
		Return False;
	ElsIf TypeOf(List.CurrentRow) = Type("DynamicListGroupRow") Then
		ShowMessageBox(,NStr("vi = 'Thao tác không thể được thực hiện trên một dòng nhóm danh sách.';
							|ru = 'Действие не может быть выполнено для строки группировки списка';
							|en = 'Action cannot be executed for the list grouping row'; fa = 'Action cannot be executed for the list grouping row';
							|it = 'Действие не может быть выполнено для строки группировки списка';
							|pl = 'Czynność nie może być wykonana dla wiersza grupowania listy';
							|tr = 'Liste gruplandırma satırı için eylem gerçekleştirilemez'"));
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
