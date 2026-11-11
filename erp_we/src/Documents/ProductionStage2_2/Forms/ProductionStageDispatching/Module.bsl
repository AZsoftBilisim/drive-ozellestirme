#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var UpdateSelectionsWhenReopening;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TheProductionScheduleIsPlanned = ProductionManagementCached.TheProductionScheduleIsUsed();
	PlanningCommandIsAvailable = DataProcessors.ProductionSchedulePlanning2_2.PlanningIsAvailable();
	
	BackgroundJob = New Structure("
		|JobName,
		|JobID,
		|StorageAddress,
		|ExecutionResult");
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterStartDate2.ChoiceList);
	
	SetDynamicListProperties();
	
	If Parameters.Property("FiltersStructure") Then
		FillInSelectionsBySelectionStructure(Parameters.FiltersStructure);
	ElsIf Parameters.Property("QuickFilterStructure") Then
		FillInSelectionsBySelectionStructure(Parameters.QuickFilterStructure);
	EndIf;
	
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterStartDate2.ChoiceList, EventDate, QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", Department, QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "ReferenceOrder", ReferenceOrder, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Status", Status, QuickFilterStructure);
	
	SelectionBasedOnStateOfStagesCreatedOnServer();
	
	AccessRightStateOfSoftware = AccessRight("Use", Metadata.DataProcessors.OrderSupplyForecast);
	
	RestrictionFields = New Array;
	RestrictionFields.Add("ListOfStagesBalanceOfLaborInput");
	RestrictionFields.Add("ListOfStagesPercentageOfCompletion");
	List.SetRestrictionsForUseInGroup(RestrictionFields);
	List.SetRestrictionsForUseInOrder(RestrictionFields);
	List.SetRestrictionsForUseInFilter(RestrictionFields);
	
	#Region UniversalMechanisms
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.GroupCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.CommandBarGlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	#EndRegion
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
	EnableHandlerWaitingToUpdateData();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	UpdateSelectionsWhenReopening = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	// End Peripherals
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	If NeedToUpdateInstalledSelections(EventName, Source) Then
		
		SetSelectionsBySelectionStructure(Parameter);
		
	EndIf;
	
	If EventName = "ClosingOrders"
			Or EventName = "ChangingProcessTechnology" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		Settings.Delete("ProductionDispatcherBusinessUnit");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Settings.Get("AdditPanelCollapsed") = True Then
		ConfigureDependentFormElements(ThisForm, "PositionOfFrontPanel");
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.ListOnChange(ThisObject, "Document.ProductionStage2_2");
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	DetachIdleHandler("Attachable_UpdateListCommands");
	AttachIdleHandler("Attachable_UpdateListCommands", 0.2, True);
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)

	KeysList = Rows.GetKeys();
	
	If KeysList.UBound() = -1 Then
		Return;
	EndIf;
	
	ThereIsColumnBalanceOfLaborInput = Rows[KeysList[0]].Data.Property("BalanceOfLaborInput");
	ThereIsColumnPercentageOfCompletion = Rows[KeysList[0]].Data.Property("ProgressPercent");
	
	If ThereIsColumnBalanceOfLaborInput Or ThereIsColumnPercentageOfCompletion Then

		Query = New Query;
		Query.SetParameter("StageList", KeysList);
		Query.Text = 
		"SELECT
		|	LaborCosts.Stage AS Stage,
		|	SUM(LaborCosts.Plan) AS Plan,
		|	SUM(LaborCosts.Balance) AS Balance
		|FROM
		|	(SELECT
		|		LaborCosts.Stage AS Stage,
		|		LaborCosts.WorkKind AS WorkKind,
		|		SUM(LaborCosts.Plan) AS Plan,
		|		CASE
		|			WHEN SUM(LaborCosts.Real) > SUM(LaborCosts.Plan)
		|				THEN 0
		|			ELSE SUM(LaborCosts.Plan) - SUM(LaborCosts.Real)
		|		END AS Balance
		|	FROM
		|		(SELECT
		|			LaborCosts.Ref AS Stage,
		|			LaborCosts.WorkKind AS WorkKind,
		|			CASE
		|				WHEN LaborCosts.WorkKind.LaborInputMultiplier = 0
		|					THEN 0
		|				ELSE LaborCosts.Count * LaborCosts.WorkKind.LaborInput / LaborCosts.WorkKind.LaborInputMultiplier
		|			END AS Plan,
		|			CASE
		|				WHEN NOT LaborCosts.Completed2
		|				OR LaborCosts.WorkKind.LaborInputMultiplier = 0
		|					THEN 0
		|				ELSE LaborCosts.Count * LaborCosts.WorkKind.LaborInput / LaborCosts.WorkKind.LaborInputMultiplier
		|			END AS Real
		|		FROM
		|			Document.ProductionStage2_2.LaborCosts AS LaborCosts
		|		WHERE
		|			LaborCosts.Ref IN (&StageList)
		|			AND NOT LaborCosts.Canceled
		|			AND LaborCosts.Ref.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|
		|		UNION ALL
		|
		|		SELECT
		|			Stages.Ref AS Stage,
		|			LaborCostsOfOperations.WorkKind,
		|			0 AS Plan,
		|			CASE
		|				WHEN LaborCostsOfOperations.WorkKind.LaborInputMultiplier = 0
		|					THEN 0
		|				ELSE LaborCostsOfOperations.Count * LaborCostsOfOperations.WorkKind.LaborInput /
		|					LaborCostsOfOperations.WorkKind.LaborInputMultiplier
		|			END AS Real
		|		FROM
		|			Document.ProductionStage2_2 AS Stages
		|				INNER JOIN Document.ProductionOperation2_2.LaborCosts AS LaborCostsOfOperations
		|				ON Stages.Ref = LaborCostsOfOperations.Ref.Stage
		|				AND LaborCostsOfOperations.Ref.Posted
		|				AND LaborCostsOfOperations.Ref.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|		WHERE
		|			Stages.Ref IN (&StageList)
		|			AND Stages.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
		|			AND Stages.OperationAsOutputReference) AS LaborCosts
		|	GROUP BY
		|		LaborCosts.Stage,
		|		LaborCosts.WorkKind) AS LaborCosts
		|GROUP BY
		|	LaborCosts.Stage
		|HAVING
		|	SUM(LaborCosts.Balance) > 0";
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			RowData = Rows[Selection.Stage].Data;
			If ThereIsColumnBalanceOfLaborInput Then
				RowData["BalanceOfLaborInput"] = Selection.Balance;
			EndIf;
			If ThereIsColumnPercentageOfCompletion Then
				RowData["ProgressPercent"] = RoundUpPercentages(100-Selection.Balance*100/Selection.Plan);
			EndIf;
		EndDo;
	
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region CommandPanelStages

&AtClient
Procedure UpdateList(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionStage2_2.ProductionStageDispatching.Command.UpdateList");
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure ChangeAStage(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	ShowValue(, SelectedStages[0]);

EndProcedure

&AtClient
Procedure ChangeStageChain(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		ProductionManagementClient.OpenStageChainEditingForm(
			RowData.ReferenceOrder,
			RowData.ProductionLot,,
			ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure ChangeBatch(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		If RowData.ProductionProcessType 
				= PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Đối với các công đoạn đơn hàng với quy trình sản xuất loại ""Không có bảng kê chi tiết các nguồn lực sản xuất"", không thể thay đổi lô';
					|ru = 'Для этапов заказа с типом производственного процесса ""Без спецификаций"" изменение партии недоступно';
					|en = 'For order stages with ""No BOM"" production process type, lot change is not available'; fa = 'For order stages with ""No BOM"" production process type, lot change is not available';
					|it = 'Per le fasi dell''ordine con il tipo di processo di produzione ""Senza specifiche"" non è possibile modificare i lotti';
					|pl = 'Dla etapów zamówienia o typie procesu produkcyjnego ""Bez specyfikacji"" zmiana partii jest niedostępna';
					|tr = '""Ürün Reçetesiz"" üretim süreci türü olan sipariş aşaması için lot değişikliği mevcut değil'"));
			Return;
		EndIf;
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.Workplace",
			New Structure("ProductionLot, Stage", RowData.ProductionLot, RowData.Ref),
			ThisForm,
			RowData.ProductionLot);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReFillBatch(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.FillingInByBOM",
			New Structure("ProductionLot, Stage", RowData.ProductionLot, RowData.Ref),
			ThisObject,
			RowData.ProductionLot);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanTheOrder(Command)
	
	SelectedStages = SelectedStages();
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	OpenOrderPlanningForm(RowData.ReferenceOrder);

EndProcedure

&AtClient
Procedure PlanTheSelectedOnes(Command)
	
	SelectedStages = SelectedStages();
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	DefineParametersAndSchedule(SelectedStages);
	
EndProcedure

&AtClient
Procedure DefineParametersAndSchedule(Stages)
	
	FormParameters = New Structure;
	FormParameters.Insert("StageSchedulePlanning", True);
	FormParameters.Insert("Stages", Stages);
	
	CallbackDescription = New CallbackDescription(
			"DefineParametersAndScheduleCompletion", 
			ThisObject, Stages);
	
	OpenForm("DataProcessor.ProductionSchedulePlanning2_2.Form.PlanningSettingsOfListOfReferencesAndStages", 
			FormParameters, ThisForm, 
			UUID,,, 
			CallbackDescription);
	
EndProcedure

&AtClient
Procedure DefineParametersAndScheduleCompletion(Result, Stages) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	JobParameters = New Structure;
	JobParameters.Insert("Stages", Stages);
	
	For Each KeyAndValue In Result Do
		JobParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	RunBackgroundJob1("PlanProductionSchedule", JobParameters);
	
EndProcedure

&AtClient
Procedure SendToExecuteCommand(Command)
	
	SelectedRows = SelectedStages();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure("SelectedRows", SelectedRows);
	
	CallbackDescription = New CallbackDescription(
		"PassForExecutionCompletion", 
		ThisObject, AdditionalParameters);
	
	FormParameters = New Structure();
	FormParameters.Insert("FormCaption", NStr("vi = 'Đánh dấu chuyển công đoạn cần thực hiện';
												|ru = 'Отметить передачу этапов к выполнению';
												|en = 'Mark stage release'; fa = 'Mark stage release';
												|it = 'Mark stage release';
												|pl = 'Mark stage release';
												|tr = 'Aşamaların gerçekleştirilmek üzere aktarılmasını işaretle'"));
	FormParameters.Insert("TransferToExecution", True);
	
	OpenForm(
		"Document.ProductionStage2_2.Form.CancelStageFulfillmentStart",
		FormParameters,
		ThisObject,,,,
		CallbackDescription, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PassForExecutionCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "ForCompletion", Result);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Cần thực hiện';
																												|ru = 'К выполнению';
																												|en = 'Released'; fa = 'آزادشده';
																												|it = 'Da eseguire';
																												|pl = 'Do wykonania';
																												|tr = 'Gerçekleştirmeye hazır'"))
	
EndProcedure

&AtClient
Procedure MarkStartOfExecutionCommand(Command)
	
	SelectedRows = SelectedStages(); 
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ValuesFromSelectedRows = New Structure("Department,Organization");
	
	ReferencesArrray = StepsToChangeStatus("Initiated", SelectedRows, ValuesFromSelectedRows);
	
	If ReferencesArrray.Count() > 0 Then
		
		AdditionalParameters = New Structure("SelectedRows", ReferencesArrray);
		CallbackDescription = New CallbackDescription("MarkAsStartedCompletion", ThisObject, AdditionalParameters);
		
		FormParameters = New Structure();
		FormParameters.Insert("Department", ValuesFromSelectedRows.Department);
		FormParameters.Insert("Organization", ValuesFromSelectedRows.Organization);
		OpenForm(
			"Document.ProductionStage2_2.Form.CancelStageFulfillmentStart",
			FormParameters,
			ThisObject,,,,
			CallbackDescription, 
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		WarningText = NStr("vi = 'Không cần thay đổi trạng thái của các công đoạn được chọn.';
							|ru = 'Не требуется изменять статус выбранных этапов.';
							|en = 'Do not change status of the selected stages.'; fa = 'Do not change status of the selected stages.';
							|it = 'Non è richiesta la modifica di stato delle fasi selezionate.';
							|pl = 'Nie trzeba zmieniać status wybranych etapów.';
							|tr = 'Seçili aşamaların durumunu değiştirmeniz gerekli değildir.'");
		ShowMessageBox(,WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkAsStartedCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = AdditionalParameters.SelectedRows;
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Initiated", QuestionResult);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Bắt đầu';
																												|ru = 'Начат';
																												|en = 'Started'; fa = 'شروع‌شده';
																												|it = 'Iniziato';
																												|pl = 'Started';
																												|tr = 'Başlatıldı'"));
	
EndProcedure

&AtClient
Procedure MarkAsCompletedCommand(Command)
	
	SelectedRows = SelectedStages();
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ReferencesArrray = StepsToChangeStatus("Completed", SelectedRows);
	
	If ReferencesArrray.Count() > 0 Then
		
		OrderList = New ValueList;
		OrderList.LoadValues(SelectedRows);
		
		ClosureStructure = New Structure;
		ClosureStructure.Insert("Orders",                       OrderList);
		ClosureStructure.Insert("CancelUnprocessedLines", True);
		ClosureStructure.Insert("CloseOrders",              True);
		
		OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure,
						ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		WarningText = NStr("vi = 'Không cần thay đổi trạng thái của các công đoạn được chọn.';
							|ru = 'Не требуется изменять статус выбранных этапов.';
							|en = 'Do not change status of the selected stages.'; fa = 'Do not change status of the selected stages.';
							|it = 'Non è richiesta la modifica di stato delle fasi selezionate.';
							|pl = 'Nie trzeba zmieniać status wybranych etapów.';
							|tr = 'Seçili aşamaların durumunu değiştirmeniz gerekli değildir.'");
		ShowMessageBox(,WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionByTheChainOfStagesWhenChanging(Command)
	
	FilterTypeByTheStageChain = Command.Name;
	
	EstablishSelectionAlongChainOfStages();
	
EndProcedure

&AtClient
Procedure WhenChangingTheSelectionBasedOnStageData(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Department", Department);
	FormParameters.Insert("FilterStructureByStageData", FilterStructureByStageData);
	
	CallbackDescription = New CallbackDescription("WhenChangingTheSelectionBasedOnStageDataCompletion", ThisObject);
	
	OpenForm("Document.ProductionStage2_2.Form.PickingByContent",
					FormParameters,
					ThisObject,,,,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WhenChangingTheSelectionBasedOnStageDataCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If Result.ProductSelectionIsUsed
			Or Result.MaterialSelectionIsUsed
			Or Result.VRCSelectionIsUsed
			Or Result.SelectionByPerformerIsUsed Then
			
			FilterStructureByStageData = Result;
			
		Else
			
			FilterStructureByStageData = Undefined;
			
		EndIf;
		
		SetSelectionsBasedOnStageData();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenRemovingTheSelectionAccordingToTheStageData(Command)
	
	If FilterStructureByStageData <> Undefined Then
		
		FilterStructureByStageData = Undefined;
		
		SetSelectionsBasedOnStageData();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecutionOfOperations(Command)
	
	RowsSelected = SelectedStages();
	If RowsSelected.Count() > 0 Then
		ProductionManagementClient.OpenPerformingOperations(RowsSelected, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List.SelectedRows);
	
EndProcedure

&AtClient
Procedure SplitParty(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		If RowData.ProductionProcessType 
				= PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Đối với các công đoạn đơn hàng với quy trình sản xuất loại ""Không có bảng kê chi tiết các nguồn lực sản xuất"", không thể thay đổi lô';
					|ru = 'Для этапов заказа с типом производственного процесса ""Без спецификаций"" изменение партии недоступно';
					|en = 'For order stages with ""No BOM"" production process type, lot change is not available'; fa = 'For order stages with ""No BOM"" production process type, lot change is not available';
					|it = 'Per le fasi dell''ordine con il tipo di processo di produzione ""Senza specifiche"" non è possibile modificare i lotti';
					|pl = 'Dla etapów zamówienia o typie procesu produkcyjnego ""Bez specyfikacji"" zmiana partii jest niedostępna';
					|tr = '""Ürün Reçetesiz"" üretim süreci türü olan sipariş aşaması için lot değişikliği mevcut değil'"));
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("ProductionLot", RowData.ProductionLot);
		FormParameters.Insert("Stage", RowData.Ref);
		FormParameters.Insert("Split", True);
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.Workplace",
			FormParameters,
			ThisObject,
			"" + RowData.ProductionLot.UUID() + "_Split");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordDefectiveGoods(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		If RowData.ProductionProcessType 
				= PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Đối với các công đoạn đơn hàng với quy trình sản xuất loại ""Không có bảng kê chi tiết các nguồn lực sản xuất"", không thể thay đổi lô';
					|ru = 'Для этапов заказа с типом производственного процесса ""Без спецификаций"" изменение партии недоступно';
					|en = 'For order stages with ""No BOM"" production process type, lot change is not available'; fa = 'For order stages with ""No BOM"" production process type, lot change is not available';
					|it = 'Per le fasi dell''ordine con il tipo di processo di produzione ""Senza specifiche"" non è possibile modificare i lotti';
					|pl = 'Dla etapów zamówienia o typie procesu produkcyjnego ""Bez specyfikacji"" zmiana partii jest niedostępna';
					|tr = '""Ürün Reçetesiz"" üretim süreci türü olan sipariş aşaması için lot değişikliği mevcut değil'"));
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("ProductionLot", RowData.ProductionLot);
		FormParameters.Insert("Stage", RowData.Ref);
		FormParameters.Insert("RecordDefectiveGoods", True);
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.Workplace",
			FormParameters,
			ThisObject,
			"" + RowData.ProductionLot.UUID() + "_DefectiveGoods");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShortenLotReference(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		If RowData.ProductionProcessType 
				= PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Đối với các công đoạn đơn hàng với quy trình sản xuất loại ""Không có bảng kê chi tiết các nguồn lực sản xuất"", không thể thay đổi lô';
					|ru = 'Для этапов заказа с типом производственного процесса ""Без спецификаций"" изменение партии недоступно';
					|en = 'For order stages with ""No BOM"" production process type, lot change is not available'; fa = 'For order stages with ""No BOM"" production process type, lot change is not available';
					|it = 'Per le fasi dell''ordine con il tipo di processo di produzione ""Senza specifiche"" non è possibile modificare i lotti';
					|pl = 'Dla etapów zamówienia o typie procesu produkcyjnego ""Bez specyfikacji"" zmiana partii jest niedostępna';
					|tr = '""Ürün Reçetesiz"" üretim süreci türü olan sipariş aşaması için lot değişikliği mevcut değil'"));
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("ProductionLot", RowData.ProductionLot);
		FormParameters.Insert("Stage", RowData.Ref);
		FormParameters.Insert("ReduceIncrease", True);
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.Workplace",
			FormParameters,
			ThisObject,
			"" + RowData.ProductionLot.UUID() + "_Reduce");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DivideStage(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		OpenDivisionForm = True;
		WarningText = "";
		
		SplitStageCommandOnServer(RowData.Ref, OpenDivisionForm, WarningText);
		
		If Not IsBlankString(WarningText) Then
			ShowMessageBox(, WarningText);
			Return;
		EndIf;
		
		If OpenDivisionForm Then
			
			OpenForm(
				"Document.ProductionStage2_2.Form.DocumentDivision",
				New Structure("Ref", RowData.Ref),,
				RowData.Ref,,,,
				FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SplitStageCommandOnServer(Ref, OpenDivisionForm, WarningText)
	
	If Not Documents.ProductionStage2_2.YouCanSplitDocument(Ref, WarningText) Then
		Return;
	EndIf;
	
	ProductionProcessType = Common.ObjectAttributeValue(
		Ref,
		"ProductionProcessType");
	
	If ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		
		Documents.ProductionStage2_2.DivideDocument(
			Ref, 0, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), False);
		OpenDivisionForm = False;
		
	Else
		OpenDivisionForm = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure EditTechnicalProcess(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	ElsIf SelectedStages.UBound() > 1 Then
		WarningText = NStr("vi = 'Lệnh không thể được thực thi cho nhiều dòng.';
							|ru = 'Команда не может быть выполнена для нескольких строк.';
							|en = 'Command cannot be executed for multiple lines.'; fa = 'Command cannot be executed for multiple lines.';
							|it = 'Il comando non può essere eseguito per alcune righe.';
							|pl = 'Polecenie nie może być wykonane dla kilku wierszy.';
							|tr = 'Birden fazla satır için komut gerçekleştirilemez.'");
	Else
		RowData = Items.List.RowData(SelectedStages[0]);
		If Not ProductionProcessEditorClientServer.ProcessTechnologyEditorIsAvailable(RowData) Then
			WarningText = NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn.';
								|ru = 'Команда не может быть выполнена для выбранной строки.';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata.';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza';
								|tr = 'Seçili satır için komut gerçekleştirilemez.'");
		EndIf;
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(,WarningText);
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Stage", Items.List.CurrentRow);
		OpenForm("DataProcessor.ProductionProcessEditor.Form", FormParameters, ThisObject, Items.List.CurrentRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReplaceTechnologicalProcess(Command)
	
	FormParameters = New Structure;
	
	SelectedStages = SelectedStages();
	If SelectedStages.UBound() <> -1 Then
		RowData = Items.List.RowData(SelectedStages[0]);
		If Not ProductionProcessEditorClientServer.ProcessTechnologyEditorIsAvailable(RowData) Then
			WarningText = NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn.';
								|ru = 'Команда не может быть выполнена для выбранной строки.';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata.';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza';
								|tr = 'Seçili satır için komut gerçekleştirilemez.'");
		EndIf;
		FormParameters.Insert("Stage", SelectedStages[0]);
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(,WarningText);
	Else
		OpenForm("DataProcessor.ProductionProcessEditor.Form.BulkReplacement", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Universal_

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Supply
       
&AtClient
Procedure ShipByOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"Action_Ship_PRIORITY_WithAssignment",
		Items.List,
		PredefinedValue("Document.ProductionStage2_2.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure ReserveAnOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"Action_ToReserve__PRIORITY_WithAssignment",
		Items.List,
		PredefinedValue("Document.ProductionStage2_2.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure ToSupplyOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_COOPERATION",
		Items.List,
		PredefinedValue("Document.ProductionStage2_2.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure DoNotSupplyOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_NOTABLE",
		Items.List,
		PredefinedValue("Document.ProductionStage2_2.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure ReserveAsReceivedOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_RESERVATION_REFERENCES",
		Items.List,
		PredefinedValue("Document.ProductionStage2_2.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure StateOfSoftwareDynamicStructure(Command)
	
	DocumentsArray = Items.List.SelectedRows;
	
	If DocumentsArray.Count() > 0 Then
		
		OpenSupplyForecastStatusForDynamicStructureStages(DocumentsArray);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region FormElementHandlers

#Region Header

&AtClient
Procedure FilterProductionDispatcherBusinessUnitOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit, DataCompositionComparisonType.Equal,, ValueIsFilled(ProductionDispatcherBusinessUnit));
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus();
	
EndProcedure

&AtClient
Procedure FilterStatusStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("FilterStatusStartChoiceCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedValues", Status);
	
	OpenForm("Document.ProductionStage2_2.Form.PickingByStatuses",
					FormParameters,
					ThisObject,,,,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FilterStatusClearing(Item, StandardProcessing)
	
	If Status.Count() = 0 Then
		Return;
	EndIf;
	
	Status.Clear();
	
	SetSelectionByStatus();
	
EndProcedure

&AtClient
Procedure FilterStatusStartChoiceCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		
		Status = ValueSelected;
		SetSelectionByStatus();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterStartDate2OnChange(Item)
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterStartDate2.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterStartDate2Clearing(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FilterStartDate2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterStartDate2",
		"EventDate");
		
EndProcedure

&AtClient
Procedure FilterReferenceOrderOnChange(Item)
	
	EstablishSelectionByOrder();
	
EndProcedure

&AtClient
Procedure FilterReferenceOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = StructureOfSelectionByOrder_();
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	
	If Not ReferenceOrder.IsEmpty() Then
		FormParameters.Insert("CurrentRow", ReferenceOrder);
	EndIf;
	
	CallbackDescription = New CallbackDescription("FilterReferenceOrderChoiceProcessingCompletion", ThisObject);
	
	OpenForm("Document.ProductionOrder2_2.ChoiceForm", 
					FormParameters,,,,, 
					CallbackDescription, 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FilterReferenceOrderChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterReferenceOrderChoiceProcessingCompletion(ValueSelected);
	
EndProcedure

&AtClient
Procedure FilterReferenceOrderChoiceProcessingCompletion(ValueSelected, AdditionalParameters = Undefined) Export

	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	ReferenceOrder = ValueSelected;
	
	EstablishSelectionByOrder();
	
EndProcedure

&AtClient
Procedure FilterReferenceOrderAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Text <> "" Then
		StandardProcessing = False;
		AutoSelectionOfProductionOrders(Text, StructureOfSelectionByOrder_(), ChoiceData);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterReferenceOrderTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If Text <> "" Then
		StandardProcessing = False;
		AutoSelectionOfProductionOrders(Text, StructureOfSelectionByOrder_(), ChoiceData);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterReferenceOrderClearing(Item, StandardProcessing)
	
	If ReferenceOrder.IsEmpty() Then
		Return;
	EndIf;
	
	ReferenceOrder = Undefined;
	
	EstablishSelectionByOrder();
	
EndProcedure

&AtClient
Procedure FilterReferenceOrderOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ReferenceOrder.IsEmpty() Then
		
		ShowValue(,ReferenceOrder);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = ValueOfHyperlinkJumpToCurStageOfChain() Then
		
		Items.List.CurrentRow = CurrentStageOfTheChain;
		
	ElsIf FormattedStringURL = ValueOfHyperlinkDisableSelectionByChainOfStages() Then
		
		FilterTypeByTheStageChain = ValueShowAllStages();
		
		EstablishSelectionAlongChainOfStages();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterSupplyOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"SupplyState",
		Supply,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Supply));
	
EndProcedure

#EndRegion

#Region List

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TypeOf(RowSelected) <> Type("DocumentRef.ProductionStage2_2") Then
		Return;
	EndIf;
	
	CurrentData = Items.List.CurrentData;
	
	If Field.Name = "ListOfStagesExpectedToBeProvided" Then
		
		StandardProcessing = False;
		
		If CurrentData.SupplyState = PredefinedValue("Enum.SupplyStateOfProductionStage.PendingSupply") Then
			
			If CurrentData.DynamicStructure
				And AccessRightStateOfSoftware Then
				DocumentsArray = New Array;
				DocumentsArray.Add(RowSelected);
				OpenSupplyForecastStatusForDynamicStructureStages(DocumentsArray);
			ElsIf Not CurrentData.DynamicStructure
				And AccessRightStateOfSoftware Then
				OpenSoftwareState(RowSelected);
			EndIf;
			
		EndIf;
		
	ElsIf Field.Name = "ListOfStagesRequiredToPlanASchedule" Then
		
		StandardProcessing = False;
		
		If PlanningCommandIsAvailable Then
		
			OpenOrderPlanningForm(CurrentData.ReferenceOrder);
			
		EndIf;
		
	ElsIf Field.Name = "ListOfStagesStateOfConstraintsInTheGraph" Then
		
		StandardProcessing = False;
		
	ElsIf Field.Name = "ListOfStagesOperationStatusCode" Then
		
		If CurrentData.OperationStatusCode = 0
			Or CurrentData.OperationStatusCode = 1
			Or CurrentData.OperationStatusCode = 2 Then
			
			StandardProcessing = False;
			
			ProductionManagementClient.DecodeStateOfStageOperations(
				RowSelected,
				CurrentData.OperationStatus,
				ThisForm);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region PanelOfAdditionalSelectionsStages

&AtClient
Procedure CollapseAnAdditionalPanel(Command)
	
	AdditPanelCollapsed = True;
	
	ConfigureDependentFormElements(ThisForm, "PositionOfFrontPanel");
	
EndProcedure

&AtClient
Procedure ExpandTheAddOnPanel(Command)
	
	AdditPanelCollapsed = False;
	
	ConfigureDependentFormElements(ThisForm, "PositionOfFrontPanel");
	
EndProcedure

&AtClient
Procedure FilterByStateOnChange(Item)
	
	SetSelectionByStateOfStages();
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Constants

&AtServerNoContext
Function ValueShowAllStages()
	
	Return "ShowAllStages";
	
EndFunction

&AtServerNoContext
Function ValueShowStageAndAdjacentStages()
	
	Return "ShowAStageAndAdjacentStages";
	
EndFunction

&AtServerNoContext
Function MeaningShowFollowers()
	
	Return "ShowFollowers";
	
EndFunction

&AtServerNoContext
Function ValueOfTheirPredecessors()
	
	Return "ShowPredecessors";
	
EndFunction

&AtServerNoContext
Function ValueOfHyperlinkJumpToCurStageOfChain()
	
	Return "#GoToCurStageOfChain";
	
EndFunction

&AtServerNoContext
Function ValueOfHyperlinkDisableSelectionByChainOfStages()
	
	Return "#DisableSelectionByStageChain";
	
EndFunction

#EndRegion

#Region FormMaintenance

&AtServer
Procedure SetConditionalAppearance()

	// The text of the "Start date" and "End date" fields if the schedule is not calculated
	#Region ScheduleIsNotCalculated
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListOfStagesStartDate.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListOfStagesCompletionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("List.TheScheduleIsCalculated");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được tính>';
													|ru = '<не рассчитана>';
													|en = '<not calculated>'; fa = '<not calculated>';
													|it = '<non calcolato>';
													|pl = '<nie obliczona>';
													|tr = '<hesaplanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	#EndRegion
	
	// Color design of the period according to the production schedule
	#Region ThereIsABacklogFromTheSchedule
	
	// Start date
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListOfStagesStartDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("List.TheScheduleIsCalculated");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ValueList = New ValueList;
	ValueList.Add(Enums.StatusesOfProductionStages2_2.BeingGenerated);
	ValueList.Add(Enums.StatusesOfProductionStages2_2.Generated1);
	ValueList.Add(Enums.StatusesOfProductionStages2_2.ForCompletion);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("UpdateDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("List.StartDate");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// completion date
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListOfStagesCompletionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("List.TheScheduleIsCalculated");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.StatusesOfProductionStages2_2.Completed;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("UpdateDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("List.CompletedOn");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	#EndRegion
	
	// Expected release date
	#Region ProductionDate
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListProductionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("List.ProductionDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = '00010101';

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указана>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	#EndRegion
	
	// We do not display the status in the status "Completed"
	#Region StateCompleted
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListStageState.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfProductionStages2_2.Completed;

	Item.Appearance.SetParameterValue("Show", False);
	
	#EndRegion
	
	// Start date
	ProductionManagement.SetConditionalAppearanceOfProductionDateField(ThisObject, "List", "ListOfStagesStartDate");
	
	// completion date
	ProductionManagement.SetConditionalAppearanceOfProductionDateField(ThisObject, "List", "ListOfStagesCompletionDate");
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.ProductionStage2_2);
	DynamicStructure = GetFunctionalOption("DynamicStructureOfProductionOrders");
	
	// The software Commands are visible if there is access to change the stages.
	Items.ShipByOrder.Visible = ThereIsChangeAccess;
	Items.ReserveAnOrder.Visible = ThereIsChangeAccess;
	Items.ReserveAsReceivedOrder.Visible = ThereIsChangeAccess;
	Items.ToSupplyOrder.Visible = ThereIsChangeAccess;
	Items.DoNotSupplyOrder.Visible = ThereIsChangeAccess;
	
	// We will adjust the visibility of the elements depending on the use of the production schedule
	Items.ListOfStagesRequiredToPlanASchedule.Visible   = TheProductionScheduleIsPlanned;
	Items.GroupAdditionalSelectionYouNeedToPlanASchedule.Visible = TheProductionScheduleIsPlanned;
	
	Items.ListOfStagesStateOfConstraintsInTheGraph.Visible = TheProductionScheduleIsPlanned
		And Not DynamicStructure;
	Items.GroupDopingOnACriticalPath.Visible          = TheProductionScheduleIsPlanned
		And Not DynamicStructure;
	Items.GroupAdditionalSelectionAdditionalSelectionDelayTheOrder.Visible   = TheProductionScheduleIsPlanned
		And Not DynamicStructure;
	
	Items.PlanTheOrder.Visible                    = PlanningCommandIsAvailable;
	Items.ContextMenuToScheduleTheOrder.Visible     = PlanningCommandIsAvailable;
	
	Items.ListProductionDate.Visible = Not TheProductionScheduleIsPlanned 
		And DynamicStructure;
	Items.ListProductionDate.AutoMarkIncomplete = False;
	Items.ListProductionDate.MarkIncomplete     = False;
	
	// We will set the default selection by the chain of stages
	FilterTypeByTheStageChain = ValueShowAllStages();
	Items.ShowAllStages.Check = True;
	
	// Visibility of selection by dispatcher units
	MultipleControllersAreUsed = Catalogs.BusinessStructure.MultipleDispatcherUnitsAreUsed();
	Items.FilterProductionDispatcherBusinessUnit.Visible = MultipleControllersAreUsed;
	
	// We will adjust the visibility of the elements depending on the use of operational control.
	OperationsAreUsed = GetFunctionalOption("UseOperationManagement")
		Or GetFunctionalOption("UseManufacturingExecutionSystem");
	
	Items.ListOfStagesOperationStatusCode.Visible = OperationsAreUsed;
	Items.AdditionalSelectionRequiredToAssignOperations.Visible = OperationsAreUsed;
	Items.DecorationIconAdditionalSelectionRequiredToAssignOperations.Visible = OperationsAreUsed;
	Items.TheAdditionalSelectionGroupMustBeFilledInForOperations.Visible = OperationsAreUsed;
	Items.OpenPerformingOperationsList.Visible = OperationsAreUsed;
	Items.EditTechnicalProcess.Visible = OperationsAreUsed;
	Items.ContextMenuEditProcessTechnology.Visible = OperationsAreUsed;
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.ProductionStage2_2);
	Items.ChangeSelectedItems.Visible                 = ChangeSelectedAvailable;
	Items.ChangeSelectedOnesInCommandPanel.Visible = ChangeSelectedAvailable;
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize Or AttributesStructure1.Property("Status") Then
		
		If ValueIsFilled(Form.Status) Then
			Form.StatusLines = GetStatusPresentation(Form.Status);
		Else
			Form.StatusLines = "";
		EndIf;
		
	EndIf;
	
	If Initialize Or AttributesStructure1.Property("ReferenceOrder") Then
		
		If ValueIsFilled(Form.ReferenceOrder) Then
			Form.TheOrderLine = GetPresentationOfOrder(Form.ReferenceOrder);
		Else
			Form.TheOrderLine = "";
		EndIf;
		
	EndIf;
	
	If Initialize Or AttributesStructure1.Property("PositionOfFrontPanel") Then
		
		Items.ExpandTheAddOnPanel.Visible = Form.AdditPanelCollapsed;
		Items.CollapseAnAdditionalPanel.Visible = Not Form.AdditPanelCollapsed;
		
		Items.DecorationSelectStages.Title = 
				?(Form.AdditPanelCollapsed, NStr("vi = 'Hiển thị';
												|ru = 'Отобрать';
												|en = 'Pick'; fa = 'انتخاب';
												|it = 'Selezionare';
												|pl = 'Pick';
												|tr = 'Seç'"), NStr("vi = 'Chọn các công đoạn';
																		|ru = 'Отобрать этапы, которые';
																		|en = 'Pick stages with status'; fa = 'Pick stages with status';
																		|it = 'Selezionare le fasi che:';
																		|pl = 'Wybierz etapy, które';
																		|tr = 'Aşamaları filtreleme kriteri'"));
		
		Items.DecorationSelectStagesContinued.Title = 
				?(Not Form.AdditPanelCollapsed, NStr("vi = 'Khác';
													|ru = 'Прочее';
													|en = 'Other'; fa = 'سایر';
													|it = 'Altro';
													|pl = 'Other';
													|tr = 'Diğer'"), "");
		
		CurPromptDisplay = ?(Form.AdditPanelCollapsed, 
											ToolTipRepresentation.Balloon,
											ToolTipRepresentation.ShowRight);
		
		ItemArray = New Array;
		
		ItemArray.Add(Items.DecorationIconRequiresClarification);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionIsReadyForExecution);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionAwaitsThePredecessors);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionIsWaitingToStart);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionIsWaitingToBeCompleted);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionCompleted);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionRequiredSchedulePlanning);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionRequiredToAssignOperations);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionRequiredForOperations);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionExpired);
		ItemArray.Add(Items.DecorationIconDopSelectionOnTheCriticalPath);
		ItemArray.Add(Items.DecorationIconAdditionalSelectionDelayTheOrder);
		
		For Each CurrentItem In ItemArray Do
			
			CurrentItem.ToolTipRepresentation = CurPromptDisplay;
			
		EndDo;
		
	EndIf;
	
	If AttributesStructure1.Property("EstablishSelectionAlongChainOfStages") Then
		
		ShowAllStages          = Form.FilterTypeByTheStageChain = ValueShowAllStages();
		ShowAStageAndAdjacentStages = Form.FilterTypeByTheStageChain = ValueShowStageAndAdjacentStages();
		ShowFollowers    = Form.FilterTypeByTheStageChain = MeaningShowFollowers();
		ShowPredecessors  = Form.FilterTypeByTheStageChain = ValueOfTheirPredecessors();
		
		If Not ShowAllStages Then
			
			RowsArray = New Array;
			RowsArray.Add(NStr("vi = 'Đặt lọc theo';
								|ru = 'Установлен отбор по';
								|en = 'Filter is set by'; fa = 'فیلتر تنظیم شده است بر اساس';
								|it = 'Impostata la selezione per';
								|pl = 'Ustawiono selekcję wg';
								|tr = 'Fitrenin yapılandırıldığı'"));
			RowsArray.Add(" ");
			
			RowsArray.Add(New FormattedString(NStr("vi = 'công đoạn';
													|ru = 'этапу';
													|en = 'stage'; fa = 'stage';
													|it = 'fase';
													|pl = 'stage';
													|tr = 'aşama'"),,,, 
					ValueOfHyperlinkJumpToCurStageOfChain()));
					
			RowsArray.Add(" ");
			RowsArray.Add(NStr("vi = 'và tất cả';
								|ru = 'и всем его';
								|en = 'and all its'; fa = 'and all its';
								|it = 'e a tutte le sue';
								|pl = 'i wszystkim jego';
								|tr = 've onun tüm'"));
			RowsArray.Add(" ");
			
			If ShowAStageAndAdjacentStages Then
				RowsArray.Add(NStr("vi = 'các công đoạn sản xuất liền kề';
									|ru = 'смежным этапам';
									|en = 'adjacent stages'; fa = 'adjacent stages';
									|it = 'fasi collegate';
									|pl = 'powiązanym etapom';
									|tr = 'ilgili aşama'"));
			ElsIf ShowFollowers Then
				RowsArray.Add(NStr("vi = 'người theo dõi';
									|ru = 'последователям';
									|en = 'successors'; fa = 'successors';
									|it = 'consecutive';
									|pl = 'successors';
									|tr = 'ardıl'"));
			ElsIf ShowPredecessors Then
				RowsArray.Add(NStr("vi = 'người tiền nhiệm';
									|ru = 'предшественникам';
									|en = 'predecessors'; fa = 'predecessors';
									|it = 'predecessori';
									|pl = 'predecessors';
									|tr = 'öncül'"));
			EndIf;
			
			RowsArray.Add(" (");
			
			RowsArray.Add(New FormattedString(NStr("vi = 'ngắt kết nối';
													|ru = 'отключить';
													|en = 'disable'; fa = 'disable';
													|it = 'disattivare';
													|pl = 'disable';
													|tr = 'devre dışı bırak'"),,,, 
					ValueOfHyperlinkDisableSelectionByChainOfStages()));
			
			RowsArray.Add(") ");
			
			Form.InformationText = New FormattedString(RowsArray);
			Items.InformationText.Visible = True;
			
		Else
			
			Form.InformationText = New FormattedString("");
			Items.InformationText.Visible = False;
			
		EndIf;
		
		Items.ShowAllStages.Check          = ShowAllStages;
		Items.ShowAStageAndAdjacentStages.Check = ShowAStageAndAdjacentStages;
		Items.ShowFollowers.Check    = ShowFollowers;
		Items.ShowPredecessors.Check  = ShowPredecessors;
		
	EndIf;
	
	If AttributesStructure1.Property("SetSelectionsBasedOnStageData") Then
		
		Items.RemoveSelectionsBasedOnStageData.Enabled = Form.FilterStructureByStageData <> Undefined;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region List

&AtClientAtServerNoContext
Function RoundUpPercentages(RoundedNumber)
	
	If RoundedNumber > 99
		And RoundedNumber < 100 Then
		
		RoundedNumber = 99;
		
	EndIf;
	
	If RoundedNumber > 0
		And RoundedNumber < 1 Then
		
		RoundedNumber = 1;
		
	EndIf;
	
	Return Round(RoundedNumber);
	
EndFunction

&AtServer
Procedure SetDynamicListProperties()
	
	QueryText = 
		"SELECT
		|	Stages.Status AS Status,
		|	&PresentationStage AS PresentationStage,
		|	Stages.ReferenceOrder AS ReferenceOrder,
		|	Stages.ReferenceOrder.Department AS ProductionDispatcherBusinessUnit,
		|	Stages.StageName AS StageName,
		|	Stages.ProductionByThirdParty AS ProductionByThirdParty,
		|	Stages.WorkPlanning AS WorkPlanning,
		|	Stages.Department AS Department,
		|	Stages.BillOfMaterials AS BillOfMaterials,
		|	Stages.ProductionLot AS ProductionLot,
		|	Stages.ProductionProcessType AS ProductionProcessType,
		|	Stages.NextStageNo AS NextStageNo,
		|	CASE
		|		WHEN &TheProductionScheduleIsPlanned
		|				AND TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						InformationRegister.JobsToProductionScheduleCalculation AS T
		|					WHERE
		|						NOT Stages.DynamicStructure
		|						AND T.ReferenceOrder = Stages.ReferenceOrder
		|						AND T.ProductionStage = Stages.Ref
		|					
		|					UNION ALL
		|					
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						InformationRegister.OrderStructureCalculationJobsProductionSchedule AS T
		|					WHERE
		|						Stages.DynamicStructure
		|						AND T.ProductionStage = Stages.Ref
		|					)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS YouNeedToPlanASchedule,
		|
		|	ISNULL(ProductionStageStates.SupplyState, &EmptyLinkToStateOfSoftware) AS SupplyState,
		|	ISNULL(ProductionStageStates.SupplyState, &EmptyLinkToStateOfSoftware)
		|		= VALUE(Enum.SupplyStateOfProductionStage.PendingSupply) AS PendingSupply,
		|
		|	CASE
		|		WHEN &TheProductionScheduleIsPlanned
		|			THEN CASE
		|					WHEN ISNULL(ProductionSchedule.ItLimitsProductionDate, FALSE) = TRUE
		|						THEN 3
		|					WHEN ISNULL(ProductionSchedule.OnCriticalPath, FALSE) = TRUE
		|						THEN 2
		|					ELSE -1
		|				END
		|		ELSE -1
		|	END AS StatusOfConstraintsInTheGraph,
		|	CASE
		|		WHEN Stages.Status = &StatusCompleted_1
		|			THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.Completed)
		|		ELSE ISNULL(ProductionStageStates.StateAtIntershopLevel, &EmptyLinkStatus)
		|	END AS StageState,
		|	
		|	ISNULL(ProductionStageStates.OperationStatus, &EmptyLinkOperationStatus) AS OperationStatus,
		|	CASE
		|		WHEN Stages.ItIsRequiredToPopulateByOperationsManually
		|			THEN 3
		|		WHEN ProductionStageStates.OperationStatus = VALUE(Enum.StatesOfProductionStageOperations.PendingOperationAssignment)
		|			THEN 0
		|		WHEN ProductionStageStates.OperationStatus = VALUE(Enum.StatesOfProductionStageOperations.PendingCompletion)
		|			THEN 1
		|		WHEN ProductionStageStates.OperationStatus = VALUE(Enum.StatesOfProductionStageOperations.Completed2)
		|			THEN 2
		|		ELSE -1
		|	END AS OperationStatusCode,
		|	Stages.ItIsRequiredToPopulateByOperationsManually AS ItIsRequiredToPopulateByOperationsManually,
		|	NOT Stages.ItIsRequiredToPopulateByOperationsManually
		|		AND ProductionStageStates.OperationStatus = VALUE(Enum.StatesOfProductionStageOperations.PendingOperationAssignment) AS YouNeedToAssignOperations,
		|	
		|	CASE
		|		WHEN Stages.DynamicStructure OR &TheProductionScheduleIsPlanned
		|			THEN NOT ProductionSchedule.Stage IS NULL
		|		ELSE &ThereIsRegulatorySchedule
		|	END AS TheScheduleIsCalculated,
		|	CASE
		|		WHEN Stages.DynamicStructure OR &TheProductionScheduleIsPlanned
		|			THEN ISNULL(BEGINOFPERIOD(ProductionSchedule.Begin, DAY), DATETIME(1,1,1))
		|		WHEN &ThereIsRegulatorySchedule
		|			THEN BEGINOFPERIOD(&NormativeScheduleIsBeginning, DAY)
		|		ELSE DATETIME(1,1,1)
		|	END AS EventDate,
		|	CASE
		|		WHEN ProductionSchedule.Begin IS NOT NULL
		|			THEN CASE
		|					WHEN &UpdateDate > ProductionSchedule.Begin
		|							AND Stages.Status IN (&StatusIsGenerated, &GeneratedStatus, &StatusPending)
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		WHEN &ThereIsRegulatorySchedule
		|			THEN CASE
		|					WHEN &UpdateDate > &NormativeScheduleIsBeginning
		|							AND Stages.Status IN (&StatusIsGenerated, &GeneratedStatus, &StatusPending)
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		ELSE FALSE
		|	END AS Overdue,
		|
		|	CASE
		|		WHEN Stages.DynamicStructure OR &TheProductionScheduleIsPlanned
		|			THEN ISNULL(ProductionSchedule.Begin, DATETIME(1,1,1))
		|		WHEN &ThereIsRegulatorySchedule
		|			THEN &NormativeScheduleIsBeginning
		|		ELSE DATETIME(1,1,1)
		|	END AS StartDate,
		|	CASE
		|		WHEN Stages.DynamicStructure OR &TheProductionScheduleIsPlanned
		|			THEN ISNULL(ProductionSchedule.Ending, DATETIME(1,1,1))
		|		WHEN &ThereIsRegulatorySchedule
		|			THEN &RegulatoryScheduleEnd
		|		ELSE DATETIME(1,1,1)
		|	END AS CompletedOn,
		|	CASE 
		|		WHEN ProductionSchedule.Begin IS NOT NULL THEN
		|			CASE 
		|				WHEN Stages.Status IN (&StatusIsGenerated, &GeneratedStatus, &StatusPending)
		|						AND DATEDIFF(ProductionSchedule.Begin, &UpdateDate, DAY) > 0 THEN
		|					DATEDIFF(ProductionSchedule.Begin, &UpdateDate, DAY)
		|				WHEN Stages.Status = &StatusStarted
		|						AND DATEDIFF(ProductionSchedule.Ending, &UpdateDate, DAY) > 0 THEN
		|					DATEDIFF(ProductionSchedule.Ending, &UpdateDate, DAY)
		|				WHEN Stages.Status = &StatusCompleted_1
		|						AND DATEDIFF(ProductionSchedule.Ending, Stages.ActualStageEnd, DAY) > 0 THEN
		|					DATEDIFF(ProductionSchedule.Ending, Stages.ActualStageEnd, DAY)
		|				ELSE 0
		|			END
		|		ELSE 0 
		|	END AS Delay,
		|	CASE
		|		WHEN ProductionSchedule.Begin IS NOT NULL
		|			THEN CASE
		|					WHEN &UpdateDate > ProductionSchedule.Begin
		|							AND Stages.Status IN (&StatusIsGenerated, &GeneratedStatus, &StatusPending)
		|						OR &UpdateDate > ProductionSchedule.Ending
		|							AND Stages.Status <> &StatusCompleted_1
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		WHEN &ThereIsRegulatorySchedule
		|			THEN CASE
		|					WHEN &UpdateDate > &NormativeScheduleIsBeginning
		|							AND Stages.Status IN (&StatusIsGenerated, &GeneratedStatus, &StatusPending)
		|						OR &UpdateDate > &RegulatoryScheduleEnd
		|							AND Stages.Status <> &StatusCompleted_1
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		ELSE FALSE
		|	END AS ThereIsABacklogFromTheSchedule,
		|	
		|	CASE
		|		WHEN Stages.StagePlacementInProductionSchedule AND &TheProductionScheduleIsPlanned
		|			THEN 1
		|		ELSE -1
		|	END AS StartDateImageIndex,
		|	
		|	CASE
		|		WHEN Stages.StagePlacementInProductionSchedule AND &TheProductionScheduleIsPlanned
		|			THEN 1
		|		ELSE -1
		|	END AS EndDateImageIndex,
		|	
		|	Stages.ProductionDate AS ProductionDate,
		|	Stages.DynamicStructure AS DynamicStructure,
		|
		|	Stages.Department.UseOperationManagement AS UseOperationManagement,
		|	Stages.Department.UseManufacturingExecutionSystem AS UseManufacturingExecutionSystem,
		|	Stages.Department.UseShiftTasks AS UseShiftTasks,
		|	&TechProcessParameters,
		|
		|	ISNULL(Stages.ProductionLot.MainProductProducts, VALUE(Catalog.Products.EmptyRef)) AS MainProduct,
		|
		|	Stages.NumberOfPackagesPlan     AS CountPlan,
		|	Stages.NumberOfPackagesReal     AS CountReal,
		|	Stages.NumberOfPackagesCanceled AS CountCanceled,
		|	CASE
		|		WHEN Stages.PackagePlan = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN Stages.ProductionLot.MainProductProducts.UnitOfMeasure
		|		ELSE Stages.PackagePlan
		|	END AS QuantityUnit,
		|
		|	0 AS BalanceOfLaborInput,
		|	0 AS ProgressPercent,
		|	
		|	Stages.Ref AS Ref
		|FROM
		|	Document.ProductionStage2_2 AS Stages
		|	
		|		LEFT JOIN InformationRegister.ProductionStageStates AS ProductionStageStates
		|		ON Stages.ReferenceOrder = ProductionStageStates.ReferenceOrder
		|			AND Stages.Ref = ProductionStageStates.Stage
		|	
		|		{LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardProductionSchedule
		|		ON Stages.Ref = StandardProductionSchedule.ProductionStage
		|			AND Stages.ReferenceOrder = StandardProductionSchedule.ReferenceOrder}
		|	
		|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ProductionSchedule
		|		ON Stages.ReferenceOrder = ProductionSchedule.ProductionOrder
		|			AND Stages.Ref = ProductionSchedule.Stage
		|			AND (ProductionSchedule.ScheduleStatus = &StatusWorkingSchedule)
		|
		|		{LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
		|		ON Stages.Ref = TechnicalProcess.Stage}
		|	
		|WHERE
		|	NOT Stages.DeletionMark
		|";

	Documents.ProductionStage2_2.ReplacePresentationField(QueryText, "&PresentationStage", "Stages");
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	If StrFind(QueryText, "TargetOrderStructureSchedule") Then
		QueryText = StrReplace(QueryText, "ProductionSchedule.ItLimitsProductionDate", "FALSE");
		QueryText = StrReplace(QueryText, "ProductionSchedule.OnCriticalPath", "FALSE");
	EndIf;
	
	If TheProductionScheduleIsPlanned
		And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		QueryText = StrReplace(QueryText,
			"&ThereIsRegulatorySchedule",
			"FALSE");
		QueryText = StrReplace(QueryText,
			"&NormativeScheduleIsBeginning",
			"DATETIME(1,1,1)");
		QueryText = StrReplace(QueryText,
			"&RegulatoryScheduleEnd",
			"DATETIME(1,1,1)");
	Else
		QueryText = StrReplace(QueryText,
			"&ThereIsRegulatorySchedule",
			"StandardProductionSchedule.ProductionStage IS NOT NULL");
		QueryText = StrReplace(QueryText,
			"&NormativeScheduleIsBeginning",
			"DATEADD(Stages.ReferenceOrder.EarliestStartDate, SECOND, StandardProductionSchedule.DurationBeforeStart)");
		QueryText = StrReplace(QueryText,
			"&RegulatoryScheduleEnd",
			"DATEADD(Stages.ReferenceOrder.EarliestStartDate, SECOND, StandardProductionSchedule.DurationBeforeStart + StandardProductionSchedule.ResourceIntensity)");
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage("Stages",,"TechnologicalProcess,TechnologicalProcessPresentation"));
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	ListProperties.QueryText = QueryText;
	ListProperties.MainTable = List.MainTable;
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	
	List.Parameters.SetParameterValue("TheProductionScheduleIsPlanned", TheProductionScheduleIsPlanned);
	List.Parameters.SetParameterValue("StatusWorkingSchedule", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	List.Parameters.SetParameterValue("StatusIsGenerated", Enums.StatusesOfProductionStages2_2.BeingGenerated);
	List.Parameters.SetParameterValue("GeneratedStatus", Enums.StatusesOfProductionStages2_2.Generated1);
	List.Parameters.SetParameterValue("StatusPending", Enums.StatusesOfProductionStages2_2.ForCompletion);
	List.Parameters.SetParameterValue("StatusStarted",       Enums.StatusesOfProductionStages2_2.Initiated);
	List.Parameters.SetParameterValue("StatusCompleted_1",    Enums.StatusesOfProductionStages2_2.Completed);
	
	List.Parameters.SetParameterValue("EmptyLinkStatus", Enums.StateOfProductionStagesAtIntershopLevel.EmptyRef());
	List.Parameters.SetParameterValue("EmptyLinkOperationStatus", Enums.StatesOfProductionStageOperations.EmptyRef());
	List.Parameters.SetParameterValue("EmptyLinkToStateOfSoftware", Enums.SupplyStateOfProductionStage.EmptyRef());
	
EndProcedure

#EndRegion

#Region Filters

&AtServer
Procedure FillInSelectionsBySelectionStructure(FiltersStructure)
	
	QuickFilterStructure = New Structure;
	
	If FiltersStructure.Property("ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit) Then
		QuickFilterStructure.Insert("ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit);
	EndIf;
	
	If FiltersStructure.Property("Department", Department) Then
		QuickFilterStructure.Insert("Department", Department);
	EndIf;
	
	If FiltersStructure.Property("Status", Status) Then
		QuickFilterStructure.Insert("Status", Status);
	EndIf;
	
	If FiltersStructure.Property("ReferenceOrder", ReferenceOrder) Then
		QuickFilterStructure.Insert("ReferenceOrder", ReferenceOrder);
	EndIf;
	
	FiltersStructure.Property("ClarificationIsRequired",            AdditionalSelectionRequiresClarification);
	FiltersStructure.Property("ReadyForFulfillment",              AdditionalSelectionIsReadyForExecution);
	FiltersStructure.Property("PendingPredecessors",       AdditionalSelectionAwaitsThePredecessors);
	FiltersStructure.Property("PendingStart",                 AdditionalSelectionIsWaitingToStart);
	FiltersStructure.Property("PendingCompletion",             AdditionalSelectionIsAwaitingCompletion);
	FiltersStructure.Property("FilterCompleted",                 AdditionalSelectionCompleted);
	FiltersStructure.Property("ScheduleRecalculationIsRequired",    AddFilterRequiredToPlanSchedule);
	FiltersStructure.Property("YouNeedToAssignOperations",    AdditionalSelectionRequiredToAssignOperations);
	FiltersStructure.Property("ItIsRequiredToPopulateByOperationsManually", AddFilterRequiredToFillInByOperations);
	FiltersStructure.Property("Overdue",                     AddFilterOverdue);
	FiltersStructure.Property("OnCriticalPath",             AddFilterOnCriticalPath);
	FiltersStructure.Property("DelayOrder",              AdditionalSelectionDelaysTheOrder);
	
EndProcedure

&AtServer
Procedure SetSelectionsBySelectionStructure(FiltersStructure)
	
	FillInSelectionsBySelectionStructure(FiltersStructure);
	
	SetSelectionByDivisionDispatcher();
	SetSelectionByDivision();
	
	EstablishSelectionByOrder();
	SetSelectionByStatus();
	
	SetSelectionByStateOfStages();
	
EndProcedure

&AtServer
Procedure SetSelectionByDivisionDispatcher()
	
	CommonClientServer.SetDynamicListFilterItem(List, "ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit, DataCompositionComparisonType.Equal,, ValueIsFilled(ProductionDispatcherBusinessUnit));

EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
EndProcedure

&AtServer
Procedure SetSelectionByStatus()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.InList,, ValueIsFilled(Status));
	
	ConfigureDependentFormElements(ThisForm, "Status");

EndProcedure

&AtServer
Procedure EstablishSelectionByOrder()
	
	CommonClientServer.SetDynamicListFilterItem(List, "ReferenceOrder", ReferenceOrder, DataCompositionComparisonType.Equal,, ValueIsFilled(ReferenceOrder));
	
	ConfigureDependentFormElements(ThisForm, "ReferenceOrder");

EndProcedure

&AtServer
Procedure SetSelectionByStateOfStages()
	
	ArrayOfSelections = New Array;
	
	// Selection based on the current state of the stage
	
	ArrayOfValues = New Array;
	
	If AdditionalSelectionRequiresClarification Then
		
		ArrayOfValues.Add(Enums.StateOfProductionStagesAtIntershopLevel.RequiresClarification);
		
	EndIf;
	
	If AdditionalSelectionIsReadyForExecution Then
		
		ArrayOfValues.Add(Enums.StateOfProductionStagesAtIntershopLevel.ReadyForFulfillment);
		
	EndIf;
	
	If AdditionalSelectionAwaitsThePredecessors Then
		
		ArrayOfValues.Add(Enums.StateOfProductionStagesAtIntershopLevel.PendingPredecessors);
		
	EndIf;
	
	If AdditionalSelectionIsWaitingToStart Then
		
		ArrayOfValues.Add(Enums.StateOfProductionStagesAtIntershopLevel.PendingStart);
		
	EndIf;
	
	If AdditionalSelectionIsAwaitingCompletion Then
		
		ArrayOfValues.Add(Enums.StateOfProductionStagesAtIntershopLevel.PendingCompletion);
		
	EndIf;
	
	If AdditionalSelectionCompleted Then
		
		ArrayOfValues.Add(Enums.StateOfProductionStagesAtIntershopLevel.Completed);
		
	EndIf;
	
	Filter = FilterStructure1("StageState");
	Filter.Use = ArrayOfValues.UBound() <> -1;
	Filter.ComparisonType  = DataCompositionComparisonType.InList;
	Filter.Value      = ArrayOfValues;
	
	ArrayOfSelections.Add(Filter);
	
	// Selection according to the state of the production schedule
	
	Filter = FilterStructure1("YouNeedToPlanASchedule");
	Filter.Use = AddFilterRequiredToPlanSchedule;
	Filter.ComparisonType  = DataCompositionComparisonType.Equal;
	Filter.Value      = True;
	
	ArrayOfSelections.Add(Filter);
	
	// Selection based on the state of the assignment of operations
	
	Filter = FilterStructure1("YouNeedToAssignOperations");
	Filter.Use = AdditionalSelectionRequiredToAssignOperations;
	Filter.ComparisonType  = DataCompositionComparisonType.Equal;
	Filter.Value      = True;
	
	ArrayOfSelections.Add(Filter);
	
	// Selection based on the state of operations
	
	Filter = FilterStructure1("ItIsRequiredToPopulateByOperationsManually");
	Filter.Use = AddFilterRequiredToFillInByOperations;
	Filter.ComparisonType  = DataCompositionComparisonType.Equal;
	Filter.Value      = True;
	
	ArrayOfSelections.Add(Filter);
	
	// Selection by lagging behind schedule
	
	Filter = FilterStructure1("ThereIsABacklogFromTheSchedule");
	Filter.Use = AddFilterOverdue;
	Filter.ComparisonType  = DataCompositionComparisonType.Equal;
	Filter.Value      = True;
	
	ArrayOfSelections.Add(Filter);
	
	// Selection based on the state of constraints in the schedule
	
	ArrayOfValues = New Array;
	
	If AddFilterOnCriticalPath Then
		ArrayOfValues.Add(2);
		ArrayOfValues.Add(3);
	EndIf;
	
	If AdditionalSelectionDelaysTheOrder Then
		ArrayOfValues.Add(3);
	EndIf;
	
	Filter = FilterStructure1("StatusOfConstraintsInTheGraph");
	Filter.Use = ArrayOfValues.UBound() <> -1;
	Filter.ComparisonType  = DataCompositionComparisonType.InList;
	Filter.Value      = ArrayOfValues;
	
	ArrayOfSelections.Add(Filter);
	
	// Setting selections
	
	For Each FilterElement In ArrayOfSelections Do
		
		CommonClientServer.SetDynamicListFilterItem(
															List,
															FilterElement.Field,
															FilterElement.Value,
															FilterElement.ComparisonType,,
															FilterElement.Use);
		
	EndDo;

EndProcedure

&AtServer
Procedure EstablishSelectionAlongChainOfStages()
	
	ReferencesArrray = New Array();
	
	If FilterTypeByTheStageChain <> ValueShowAllStages() Then
		
		CurrentStageOfTheChain = Items.List.CurrentRow;
		
		If FilterTypeByTheStageChain = ValueShowStageAndAdjacentStages() Then
			
			ReferencesArrray = Documents.ProductionStage2_2.AdjacentStages(CurrentStageOfTheChain);
			
		ElsIf FilterTypeByTheStageChain = MeaningShowFollowers() Then
			
			ReferencesArrray = Documents.ProductionStage2_2.AllFollowers(CurrentStageOfTheChain);

		ElsIf FilterTypeByTheStageChain = ValueOfTheirPredecessors() Then
			
			ReferencesArrray = Documents.ProductionStage2_2.AllPredecessors(CurrentStageOfTheChain);
			
		EndIf;
		
		ReferencesArrray.Add(CurrentStageOfTheChain);
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "Ref", ReferencesArrray, DataCompositionComparisonType.InList,, ValueIsFilled(ReferencesArrray));
	
	ConfigureDependentFormElements(ThisForm, "EstablishSelectionAlongChainOfStages");
	
EndProcedure

&AtServer
Procedure SetSelectionsBasedOnStageData()
	
	#Region SelectionByOutputProducts
	
	If FilterStructureByStageData <> Undefined And FilterStructureByStageData.ProductSelectionIsUsed Then
		ProductRange_2 = FilterStructureByStageData.ProductRange_2;
		ItemVariantOfProduct = FilterStructureByStageData.ItemVariantOfProduct;
	Else
		ProductRange_2 = Catalogs.Products.EmptyRef();
		ItemVariantOfProduct = Catalogs.ItemsCharacteristics.EmptyRef();
	EndIf;
	
	SelectionByOutputProducts = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo sản phẩm xuất xưởng';
			|ru = 'Отбор по выходным изделиям';
			|en = 'Filter by finished products'; fa = 'Filter by finished products';
			|it = 'Selezione per prodotti in uscita';
			|pl = 'Filtr według produktów wyjściowych';
			|tr = 'Üretilen nihai ürüne göre filtre'"),
		DataCompositionFilterItemsGroupType.OrGroup);
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		SelectionByOutputProducts.Items,
		NStr("vi = 'Lọc theo sản phẩm xuất xưởng (chi phí ước tính)';
			|ru = 'Отбор по выходным изделиям (рассчитываемая стоимость)';
			|en = 'Filter by finished products (calculated cost)'; fa = 'Filter by finished products (calculated cost)';
			|it = 'Selezione per prodotti in uscita (costo stimato)';
			|pl = 'Filtr według produktów wyjściowych (obliczany koszt)';
			|tr = 'Üretilen nihai ürüne göre filtre (hesaplanan maliyet)'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.ManufacturedProducts.Products",
		DataCompositionComparisonType.Equal,
		ProductRange_2,
		,
		ValueIsFilled(ProductRange_2));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.ManufacturedProducts.Characteristic",
		DataCompositionComparisonType.Equal,
		ItemVariantOfProduct,
		,
		ValueIsFilled(ProductRange_2) And ValueIsFilled(ItemVariantOfProduct));
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		SelectionByOutputProducts.Items,
		NStr("vi = 'Lọc theo sản phẩm xuất xưởng (chi phí cố định)';
			|ru = 'Отбор по выходным изделиям (фиксированная стоимость)';
			|en = 'Filter by finished products (fixed cost)'; fa = 'Filter by finished products (fixed cost)';
			|it = 'Selezione per progetti in uscita (costo fisso)';
			|pl = 'Filtr według produktów wyjściowych (ustalony koszt)';
			|tr = 'Üretilen nihai ürüne göre filtre (sabit maliyet)'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.SideAndIntermediateRelease.Products",
		DataCompositionComparisonType.Equal,
		ProductRange_2,
		,
		ValueIsFilled(ProductRange_2));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.SideAndIntermediateRelease.Characteristic",
		DataCompositionComparisonType.Equal,
		ItemVariantOfProduct,
		,
		ValueIsFilled(ProductRange_2) And ValueIsFilled(ItemVariantOfProduct));
	
	#EndRegion
	
	#Region FilterByMaterials
	
	If FilterStructureByStageData <> Undefined And FilterStructureByStageData.MaterialSelectionIsUsed Then
		MaterialNomenclature = FilterStructureByStageData.MaterialNomenclature;
		ItemVariantOfMaterial = FilterStructureByStageData.ItemVariantOfMaterial;
	Else
		MaterialNomenclature = Catalogs.Products.EmptyRef();
		ItemVariantOfMaterial = Catalogs.ItemsCharacteristics.EmptyRef();
	EndIf;
	
	FilterByMaterials = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo nguyên vật liệu';
			|ru = 'Отбор по материалам';
			|en = 'Filter by materials'; fa = 'فیلتر بر اساس مواد';
			|it = 'Selezione per materiali';
			|pl = 'Filtr wg materiałów';
			|tr = 'Malzemeye göre filtre'"),
		DataCompositionFilterItemsGroupType.OrGroup);
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		FilterByMaterials.Items,
		NStr("vi = 'Lọc theo nguyên vật liệu (cung cấp)';
			|ru = 'Отбор по материалам (обеспечение)';
			|en = 'Filter by materials (supply)'; fa = 'Filter by materials (supply)';
			|it = 'Selezione per materiali (forniti)';
			|pl = 'Filtr według materiałów (zaopatrzenie)';
			|tr = 'Malzemeye göre filtre (Sipariş karşılama)'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.SupplyWithMaterialsAndWorks.Products",
		DataCompositionComparisonType.Equal,
		MaterialNomenclature,
		,
		ValueIsFilled(MaterialNomenclature));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.SupplyWithMaterialsAndWorks.Characteristic",
		DataCompositionComparisonType.Equal,
		ItemVariantOfMaterial,
		,
		ValueIsFilled(MaterialNomenclature) And ValueIsFilled(ItemVariantOfMaterial));
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		FilterByMaterials.Items,
		NStr("vi = 'Lọc theo nguyên vật liệu (tiêu thụ)';
			|ru = 'Отбор по материалам (расход)';
			|en = 'Filter by materials (expense)'; fa = 'Filter by materials (expense)';
			|it = 'Selezione per materiali (spesa)';
			|pl = 'Filtr według materiałów (wydatek)';
			|tr = 'Malzemeye göre filtre (gider)'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.MaterialsAndWorksConsumption.Products",
		DataCompositionComparisonType.Equal,
		MaterialNomenclature,
		,
		ValueIsFilled(MaterialNomenclature));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.MaterialsAndWorksConsumption.Characteristic",
		DataCompositionComparisonType.Equal,
		ItemVariantOfMaterial,
		,
		ValueIsFilled(MaterialNomenclature) And ValueIsFilled(ItemVariantOfMaterial));
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		FilterByMaterials.Items,
		NStr("vi = 'Lọc theo nguyên vật liệu (tiết kiệm)';
			|ru = 'Отбор по материалам (экономия)';
			|en = 'Filter by materials (savings)'; fa = 'Filter by materials (savings)';
			|it = 'Selezione per materiali (risparmio)';
			|pl = 'Filtr według materiałów (ekonomia)';
			|tr = 'Malzemeye göre filtre (tasarruf)'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.UnusedMaterials.Products",
		DataCompositionComparisonType.Equal,
		MaterialNomenclature,
		,
		ValueIsFilled(MaterialNomenclature));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.UnusedMaterials.Characteristic",
		DataCompositionComparisonType.Equal,
		ItemVariantOfMaterial,
		,
		ValueIsFilled(MaterialNomenclature) And ValueIsFilled(ItemVariantOfMaterial));
	
	#EndRegion
	
	#Region SelectionByVRC
	
	If FilterStructureByStageData <> Undefined And FilterStructureByStageData.VRCSelectionIsUsed Then
		WorkCenterType = FilterStructureByStageData.WorkCenterType;
	Else
		WorkCenterType = Catalogs.WorkCenterTypes.EmptyRef();
	EndIf;
	
	FilterByKinds = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo trung tâm làm việc';
			|ru = 'Отбор по рабочим центрам';
			|en = 'Filter by work centers'; fa = 'Filter by work centers';
			|it = 'Selezione per centri di lavoro';
			|pl = 'Filtr według centrów wykonania pracy';
			|tr = 'İş merkezlerine göre filtre'"),
		DataCompositionFilterItemsGroupType.OrGroup);
	
	SelectionByVRC = CommonClientServer.CreateFilterItemGroup(
		FilterByKinds.Items,
		NStr("vi = 'Lọc NLSX (chính)';
			|ru = 'Отбор по ВРЦ (основные)';
			|en = 'Filter by work center type (main)'; fa = 'Filter by work center type (main)';
			|it = 'Selezione per un tipo di centro di lavoro (principali)';
			|pl = 'Filtr według rodzajów centrów wykonania pracy (podstawowe)';
			|tr = 'İMT doğrultusunda filtre (temeller)'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		SelectionByVRC,
		"Ref.WorkCenterTypes.WorkCenterType",
		DataCompositionComparisonType.Equal,
		WorkCenterType,
		,
		ValueIsFilled(WorkCenterType));
		
	CommonClientServer.AddCompositionItem(
		SelectionByVRC,
		"Ref.WorkCenterTypes.Use",
		DataCompositionComparisonType.Equal,
		True,
		,
		ValueIsFilled(WorkCenterType));
	
	SelectionByVRC = CommonClientServer.CreateFilterItemGroup(
		FilterByKinds.Items,
		NStr("vi = 'Lọc NLSX (thay thế)';
			|ru = 'Отбор по ВРЦ (альтернативные)';
			|en = 'Filter by work center type (alternate)'; fa = 'Filter by work center type (alternate)';
			|it = 'Selezione per un tipo di centro di lavoro (alternativi)';
			|pl = 'Filtr według rodzajów centrów wykonania pracy (alternatywne)';
			|tr = 'İMT doğrultusunda filtre (alternatifler)'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		SelectionByVRC,
		"Ref.AlternateWorkCenterTypes.WorkCenterType",
		DataCompositionComparisonType.Equal,
		WorkCenterType,
		,
		ValueIsFilled(WorkCenterType));
		
	CommonClientServer.AddCompositionItem(
		SelectionByVRC,
		"Ref.AlternateWorkCenterTypes.Use",
		DataCompositionComparisonType.Equal,
		True,
		,
		ValueIsFilled(WorkCenterType));
	
	#EndRegion
	
	#Region FilterByAssignees
	
	If FilterStructureByStageData <> Undefined And FilterStructureByStageData.SelectionByPerformerIsUsed Then
		Performer = FilterStructureByStageData.Performer;
	Else
		Performer = Catalogs.Persons.EmptyRef();
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref.LaborCosts.Performer",
		Performer,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Performer));
	
	#EndRegion
	
	ConfigureDependentFormElements(ThisForm, "SetSelectionsBasedOnStageData");
	
EndProcedure

&AtServer
Procedure SelectionBasedOnStateOfStagesCreatedOnServer()
	
	If AdditionalSelectionRequiresClarification
		Or AdditionalSelectionIsReadyForExecution
		Or AdditionalSelectionAwaitsThePredecessors
		Or AdditionalSelectionIsWaitingToStart
		Or AdditionalSelectionIsAwaitingCompletion
		Or AdditionalSelectionCompleted
		Or AddFilterRequiredToPlanSchedule
		Or AdditionalSelectionRequiredToAssignOperations
		Or AddFilterRequiredToFillInByOperations
		Or AddFilterOverdue
		Or AddFilterOnCriticalPath
		Or AdditionalSelectionDelaysTheOrder Then
		
		SetSelectionByStateOfStages();
		
	EndIf;
	
EndProcedure

&AtClient
Function NeedToUpdateInstalledSelections(EventName, Source)
	
	Return UpdateSelectionsWhenReopening
			And EventName = ProductionManagementClientServer.EventNameUpdateStageDispatching()
			And Source   = FormOwner;
	
EndFunction

&AtClient
Function StructureOfSelectionByOrder_()
	
	ArrayOfAvailableStatuses = New Array;
	
	ArrayOfAvailableStatuses.Add(
			PredefinedValue("Enum.ProductionOrderStatuses2_2.ToProduce"));
	ArrayOfAvailableStatuses.Add(
			PredefinedValue("Enum.ProductionOrderStatuses2_2.Closed"));
			
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Status", ArrayOfAvailableStatuses);
	
	If Not ProductionDispatcherBusinessUnit.IsEmpty() Then
		FilterStructure1.Insert("Department", ProductionDispatcherBusinessUnit);
	EndIf;
	
	Return FilterStructure1;
	
EndFunction

#EndRegion

#Region UpdatingData

&AtClient
Procedure Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders()
	ProvisionInDocumentsClient.CheckWhetherInventoryAllocationTaskIsCompletedForOrders(ThisObject, Items.List);
EndProcedure

&AtClient
Procedure EnableHandlerWaitingToUpdateData()
	
	AttachIdleHandler("Attachable_UpdateData1", 60, True);

EndProcedure

&AtClient
Procedure DisableWaitHandlerToUpdateData()
	
	DetachIdleHandler("Attachable_UpdateData1");

EndProcedure

&AtClient
Procedure EnableHandlerWaitingToUpdateDataOnActivation()
	
	AttachIdleHandler("Attachable_UpdateData1", 0.1, True);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateData1()
	
	UpdateData1(True);
	
EndProcedure

&AtClient
Procedure UpdateData1(ScheduledUpdates = False)
	
	If Not ScheduledUpdates Then
		DisableWaitHandlerToUpdateData();
	EndIf;
	
	If IsInputAvailable() Then
		
		Items.List.Refresh();
		
		EnableHandlerWaitingToUpdateData();
		
	Else
		
		EnableHandlerWaitingToUpdateDataOnActivation();
		
	EndIf;

EndProcedure

#EndRegion

#Region BackgroundJobs

&AtClient
Procedure RunBackgroundJob1(JobName, JobParameters)
	
	TaskStartResult = RunBackgroundJobOnServer(JobName, JobParameters);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription("PlanProductionScheduleNotification", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(TaskStartResult, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtClient
Procedure PlanProductionScheduleNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessJobCompletionOnClient(True);
	EndIf;
	
EndProcedure

&AtServer
Function RunBackgroundJobOnServer(Val JobName, Val JobParameters)
	
	If JobName = "PlanProductionSchedule" Then
		
		TaskStartResult = RunJobPlanProductionSchedule(JobParameters);
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Công việc không xác định ""%1""';
								|ru = 'Неизвестное задание ""%1""';
								|en = 'Unknown job ""%1""'; fa = 'Unknown job ""%1""';
								|it = 'Task sconosciuto ""%1""';
								|pl = 'Nieznane zadanie ""%1""';
								|tr = '""%1"" bilinmeyen görevi'"),
							JobName);
	EndIf;
	
	BackgroundJob.JobName           = JobName;
	BackgroundJob.JobID = TaskStartResult.JobID;
	BackgroundJob.StorageAddress       = TaskStartResult.ResultAddress;
	BackgroundJob.ExecutionResult  = TaskStartResult;
	
	Return TaskStartResult;

EndFunction

&AtClient
Procedure ProcessJobCompletionOnClient(UpdateData1 = True)

	If BackgroundJob.JobName = "PlanProductionSchedule" Then
		TaskCompletionPlanProductionSchedule(BackgroundJob.StorageAddress, UpdateData1);
	EndIf;

EndProcedure

#Region CompletingTasks

&AtServer
Function RunJobPlanProductionSchedule(JobParameters)
	
	JobDescription = NStr("vi = 'Lập kế hoạch cho các công đoạn sản xuất';
							|ru = 'Планирование графика этапов производства';
							|en = 'Production stage schedule planning'; fa = 'Production stage schedule planning';
							|it = 'Pianificazione del grafico delle fasi di produzione';
							|pl = 'Planowanie harmonogramu etapów produkcji';
							|tr = 'Üretim aşamaları programının planlanması'");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
		
	TaskStartResult = TimeConsumingOperations.ExecuteInBackground(
		"ProductionManagement.PlanScheduleOfStages",
		JobParameters,
		ExecutionParameters);
			
	Return TaskStartResult;
		
EndFunction

&AtClient
Procedure TaskCompletionPlanProductionSchedule(StorageAddress, UpdateData1)
	
	If UpdateData1 Then
		
		Result = CompletingJobOnServer(StorageAddress);
		
	Else
		
		Result = CompletingJobOnServerWithoutContext(StorageAddress);
		
	EndIf;
	
	ProductionManagementClient.NotifyUserOfProductionSchedulePlanning(Result);
	
EndProcedure

&AtServer
Function CompletingJobOnServer(StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	
	Items.List.Refresh();
	
	Return Result;
	
EndFunction

&AtServer
Function CompletingJobOnServerWithoutContext(StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region SettingActions

&AtClient
Procedure PerformActionInListOfOrdersOfDifferentTypesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		
		Return;
		
	ElsIf Result.Status = "Error" Then
		
		ShowMessageBox(, Result.BriefErrorDescription);
		
	Else
		
		OrdersToCheckTheInventoryAllocationTask.LoadValues(AdditionalParameters.Orders);
		AttachIdleHandler("Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders", 1, True);
		ResultOfActions = GetFromTempStorage(Result.ResultAddress);
		ProvisionInDocumentsClient.ReportResultsOfActionsInOrderList(ResultOfActions);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Function SelectedStages()

	Return TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);

EndFunction

&AtClient
Function StepsToChangeStatus(NewStatus, SelectedRows, ValuesFromSelectedRows = Undefined)
	
	ValuesKeys = New Array();
	KeysAreInitialized = False;
	
	Result = New Array;
	MeaningOfNewStatus = PredefinedValue("Enum.StatusesOfProductionStages2_2." + NewStatus);
	
	For Each String In SelectedRows Do
		
		RowData = Items.List.RowData(String);
		
		If Not ProductionManagementClientServer.ComparisonOfStageStatuses(MeaningOfNewStatus, RowData.Status) > 0 Then
			Continue;
		EndIf;
		
		Result.Add(RowData.Ref); 
		
		If Not ValuesFromSelectedRows = Undefined Then
			If Not KeysAreInitialized Then
				For Each KeyAndValue In ValuesFromSelectedRows Do
					If CommonClientServer.HasAttributeOrObjectProperty(RowData, KeyAndValue.Key) Then
						ValuesFromSelectedRows[KeyAndValue.Key] = RowData[KeyAndValue.Key];
						ValuesKeys.Add(KeyAndValue.Key);
					EndIf; 
				EndDo;
				KeysAreInitialized = True;
			Else
				For Cnt = -ValuesKeys.UBound() To 0 Do
					Var_Key = ValuesKeys[-Cnt];
					If RowData[Var_Key] = ValuesFromSelectedRows[Var_Key] Then
						Continue;
					EndIf;
					ValuesFromSelectedRows[Var_Key] = Undefined;
					ValuesKeys.Delete(-Cnt);
				EndDo;
			EndIf; 
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetStatusPresentation(StatusesList)
	
	Result = "";
	StatusCompleted_1     = PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed");
	NumberOfStatuses = Enums.StatusesOfProductionStages2_2.Count();
	
	If StatusesList.Count() = NumberOfStatuses - 1
		And StatusesList.FindByValue(StatusCompleted_1) = Undefined Then
		
		Result = NStr("vi = 'Chưa hoàn thành';
						|ru = 'Незавершенные';
						|en = 'Unfinished'; fa = 'ناتمام';
						|it = 'Non completate';
						|pl = 'Niedokończone';
						|tr = 'Tamamlanmayanlar'");
		
	Else
		
		For Each Item In StatusesList Do
			
			Result = Result + ?(IsBlankString(Result), "", "; ") + Item.Value;
			
		EndDo;
		
	EndIf;
	
	Return Result; 
	
EndFunction

&AtServerNoContext
Function GetPresentationOfOrder(ReferenceOrder)
	
	DetailsOfOrder = Common.ObjectAttributesValues(ReferenceOrder, "Number, Date");
	
	DocumentNumber = ?(ValueIsFilled(DetailsOfOrder.Number), " " + DetailsOfOrder.Number, "");
	DocumentDate = Format(DetailsOfOrder.Date, "DLF=D");
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = 'Số%1 ngày %2';
												|ru = '№%1 от %2';
												|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
												|it = '№%1 da %2';
												|pl = 'Nr%1 z dnia %2';
												|tr = '%2 tarihli %1 numaralı'"),
											DocumentNumber,
											DocumentDate);
	
EndFunction

&AtServerNoContext
Function FilterStructure1(Field = "")
	
	Return New Structure("Field, Value, ComparisonType, Use", Field);
	
EndFunction

&AtServerNoContext
Procedure AutoSelectionOfProductionOrders(Text, FilterStructure1, ChoiceData)
	
	ReferencesArrray = Documents.ProductionOrder2_2.AutoSelectionOfProductionOrders(Text, FilterStructure1);
	
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(ReferencesArrray);

EndProcedure

&AtClient
Procedure OpenSoftwareState(RowSelected)
	
	FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("ORDERLIST");
	FormParameters.Orders = CommonClientServer.ValueInArray(RowSelected);
	
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenOrderPlanningForm(ReferenceOrder)
	
	FormParameters = New Structure("ReferenceOrder", ReferenceOrder);
	
	OpenForm("DataProcessor.ProductionSchedulePlanning2_2.Form.CreatingProductionOrderSchedule", FormParameters,, ReferenceOrder);

EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
	Ref = LinkToListItemByBarcode(Data.Barcode);
	If Ref <> Undefined Then
		Items.List.CurrentRow = Ref;
		ShowValue(Undefined, Ref);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Return ProductionManagementClient.LinkToProductionStageByBarcode(Barcode);
	
EndFunction

&AtClient
Procedure Attachable_UpdateListCommands()
	
	CurrentData = Items.List.CurrentData;
	ListLineIsHighlighted = CurrentData <> Undefined
		And TypeOf(Items.List.CurrentRow) <> Type("DynamicListGroupRow");
	
	Items.ListSupplyForecastOfOrderList.Visible = ListLineIsHighlighted
		And Not CurrentData.DynamicStructure
		And AccessRightStateOfSoftware;
		
	Items.ListStateOfSoftwareDynamicStructure.Visible = ListLineIsHighlighted
		And CurrentData.DynamicStructure
		And AccessRightStateOfSoftware;
	
	Items.DivideStage.Visible = ListLineIsHighlighted
		And Not(
			(CurrentData.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
				Or CurrentData.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair")
				Or CurrentData.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM"))
			And CurrentData.NextStageNo = 0)
		And CurrentData.OperationStatusCode = -1;
	
	Items.ReFillBatch.Visible = ListLineIsHighlighted
		And Not CurrentData.BillOfMaterials.IsEmpty();
	
	StagesAreSeleted2_2 = False;
	If Items.List.SelectedRows.Count() < 2 Then
		StagesAreSeleted2_2 = ListLineIsHighlighted
			And Not CurrentData.DynamicStructure;
	Else
		For Each String In Items.List.SelectedRows Do
			If TypeOf(String) <> Type("DynamicListGroupRow")
				And Not Items.List.RowData(String).DynamicStructure Then
				StagesAreSeleted2_2 = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Items.PlanTheSelectedOnes.Visible = PlanningCommandIsAvailable
		And StagesAreSeleted2_2;
	Items.TheShortcutMenuPlanSelected.Visible = PlanningCommandIsAvailable
		And StagesAreSeleted2_2;
	
EndProcedure

&AtServerNoContext
Function AddressOfTheMovementTable(DocumentsArray, UUID)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MAX(ProductionStage2_2.DynamicStructure) AS DynamicStructureMax,
		|	MIN(ProductionStage2_2.DynamicStructure) AS DynamicStructureOfMines
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage2_2
		|WHERE
		|	ProductionStage2_2.Ref IN(&DocumentsArray)";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	Selection.Next();
	If Selection.DynamicStructureMax <> Selection.DynamicStructureOfMines Then
		Return Undefined;
	EndIf;
	
	Return Documents.ProductionStage2_2.AddressOfRegisteredRecordsTableForCallingSupplyForecastStatus(DocumentsArray, UUID);

EndFunction

&AtClient
Procedure OpenSupplyForecastStatusForDynamicStructureStages(DocumentsArray)
	
	ClearMessages();
	AddressOfTheMovementTable = AddressOfTheMovementTable(DocumentsArray, UUID);
	
	If AddressOfTheMovementTable = Undefined Then
		MessageText = NStr("vi = 'Trong số các dòng được chọn có các công đoạn sản xuất theo cấu trúc đơn hàng tĩnh và động.
		|Đối với các công đoạn này, không hỗ trợ đồng thời làm việc với biểu mẫu ""Trạng thái cung ứng"".';
		|ru = 'Среди выделенных строк присутствуют этапы производства по статической и динамической структуре заказа.
		|Для данных этапов одновременно не поддерживается работа формы ""Состояние обеспечения"".';
		|en = 'The selected lines contain production stages with static and dynamic order structure.
		|These stages do not simultaneously support the ""Supply forecast"" form.'; fa = 'The selected lines contain production stages with static and dynamic order structure.
		|These stages do not simultaneously support the ""Supply forecast"" form.';
		|it = 'The selected lines contain production stages with static and dynamic order structure.
		|These stages do not simultaneously support the ""Supply forecast"" form.';
		|pl = 'The selected lines contain production stages with static and dynamic order structure.
		|These stages do not simultaneously support the ""Supply forecast"" form.';
		|tr = 'Seçilen satırlar arasında statik ve dinamik sipariş yapısına göre üretim adımları bulunmaktadır. 
		| Bu aşamalar için ""Tedarik durumu"" formunun çalışması aynı anda desteklenmemektedir.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("TABLE");
	FormParameters.AddressOfTheMovementTable = AddressOfTheMovementTable;
	FormParameters.OrdersMotionRecorders = DocumentsArray;
	FormParameters.StageOfDynamicOrderStructure = True;
	FormParameters.AcceptableSecurityOptions = New Map;
		
	FormParameters.Orders = DocumentsArray;
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

#EndRegion

#Region Initialize

UpdateSelectionsWhenReopening = False;

#EndRegion

#EndRegion
