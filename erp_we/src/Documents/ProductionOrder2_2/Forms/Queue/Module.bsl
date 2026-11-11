#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DynamicStructureIsUsed = GetFunctionalOption("DynamicStructureOfProductionOrders");
	TheProductionScheduleIsPlanned = ProductionManagementCached.TheProductionScheduleIsUsed();
	
	SetDynamicListProperties();
	  	
	FiltersStructure = Undefined;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) 
		And ValueIsFilled(FiltersStructure) Then
		
		QuickFilterStructure = New Structure;
		
		If FiltersStructure.Property("Priority", Priority) Then
			QuickFilterStructure.Insert("Priority", Priority);
		EndIf;
		
		If FiltersStructure.Property("Department", Department) Then
			QuickFilterStructure.Insert("Department", Department);
		EndIf;
		
		If FiltersStructure.Property("EmployeeResponsible", EmployeeResponsible) Then
			QuickFilterStructure.Insert("EmployeeResponsible", EmployeeResponsible);
		EndIf;
		
		If FiltersStructure.Property("ProductionProcessType", ProductionProcessType) Then
			QuickFilterStructure.Insert("ProductionProcessType", ProductionProcessType);
		EndIf;
		
		SelectionByStateWhenCreatedOnServer(FiltersStructure);
		
	ElsIf Parameters.Property("QuickFilterStructure", QuickFilterStructure) Then
		
		SelectionByStateWhenCreatedOnServer(QuickFilterStructure);
		
	EndIf;
	
	If Parameters.Property("CurrentRow") Then
		Items.List.CurrentRow = Parameters.CurrentRow;
	EndIf;
	
	If Parameters.Property("CheckingClosingOfMonth") And Parameters.Property("CompanyArray") Then
		CommonClientServer.SetDynamicListFilterItem(List, "Organization", Parameters.CompanyArray);
	EndIf;
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Priority", Priority, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", Department, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "ProductionProcessType", ProductionProcessType, QuickFilterStructure);
	
	#Region UniversalMechanisms
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.CommandBarGlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	UpdateHyperlinksWhenOpeningForm = True;
	
	CustomizeFormElements();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
	AttachIdleHandler("CheckOrderStructureCalculationErrors", 0.5, True);
	
	If UpdateHyperlinksWhenOpeningForm Then
		AttachIdleHandler("Attachable_UpdateHyperlinks", 0.1, True);
	EndIf;
	
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
	
	If EventName = "Write_ProductionSchedule"
		Or EventName = "Write_ProductionOrder" Or EventName = "Write_ProductionOrder2_2" Then
		
		Items.List.Refresh();
		
	EndIf; 
	
	If EventName = "Write_ProductionOrder" Then
		
		AttachIdleHandler("Attachable_UpdateHyperlinks", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		Settings.Delete("Department");
		Settings.Delete("EmployeeResponsible");
	EndIf;

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Settings.Get("AdditPanelCollapsed") = True Then
		ConfigureDependentFormElements(ThisForm, "AdditionalPanel");
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Department", Department, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	
	UpdateHyperlinksWhenOpeningForm = False;
	UpdateHyperlinks(ThisObject);
	
	ConfigureDependentFormElements(ThisForm, "FilterDepartment, FilterEmployeeResponsible");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)

	Return; // no additional actions are provided in this configuration
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region CommandPanelOrders

&AtClient
Procedure UpdateList(Command)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ProductionOrder2_2.Queue.Command.UpdateList");
	
	UpdateTheListOnServer();
	
	AttachIdleHandler("CheckOrderStructureCalculationErrors", 0.5, True);
		
EndProcedure

&AtServer
Procedure UpdateTheListOnServer()
	
	SetConditionalDesignOfPriorityField();
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	SelectedOrders = SelectedOrders();
	If SelectedOrders.UBound() <> 0 Then
		Return;
	EndIf;
	
	MoveOrderToQueue(SelectedOrders[0], -1);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	SelectedOrders = SelectedOrders();
	If SelectedOrders.UBound() <> 0 Then
		Return;
	EndIf;
	
	MoveOrderToQueue(SelectedOrders[0], 1);
	
EndProcedure

&AtClient
Procedure GenerateProductionStages(Command)
	
	OrderList = New Array();
	
	NumberOfOrdersByJobOptions = New Array(2);
	NumberOfOrdersByJobOptions[0] = 0;
	NumberOfOrdersByJobOptions[1] = 0;
	
	For Iterator_SSLy = 0 To Items.List.SelectedRows.Count() - 1 Do
		
		Id = Items.List.SelectedRows[Iterator_SSLy];
		
		If TypeOf(Id) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		RowData = Items.List.RowData(Id);
		
		WorkOption = Number(RowData.DynamicStructure);
		NumberOfOrdersByJobOptions[WorkOption] = NumberOfOrdersByJobOptions[WorkOption] + 1;
		
		OrderList.Add(RowData.Ref);
		
	EndDo;
	
	If NumberOfOrdersByJobOptions[0] > 0 And NumberOfOrdersByJobOptions[1] > 0 Then
		
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với các đơn hàng sản xuất khác kiểu.';
							|ru = 'Выполнение команды не возможно для заказов на производство разных типов.';
							|en = 'The command cannot be executed for production orders of different types.'; fa = 'The command cannot be executed for production orders of different types.';
							|it = 'Non è possibile eseguire i comandi per gli ordini di produzione di tipi diversi.';
							|pl = 'Wykonanie polecenia jest niemożliwe dla zleceń produkcyjnych różnych typów.';
							|tr = 'Farklı türdeki üretim emirleri için komut gerçekleştirme mümkün değildir.'");
		ShowMessageBox(, WarningText);
		
		Return;
		
	EndIf;
	
	If NumberOfOrdersByJobOptions[0] > 0 Then
		
		DefineParametersAndGenerateStages(OrderList);
		
	ElsIf NumberOfOrdersByJobOptions[1] > 0 Then
		
		FiltersStructure = New Structure();
		
		If NumberOfOrdersByJobOptions[1] = 1 Then
			FiltersStructure.Insert("ProductionOrder", OrderList[0]);
		EndIf;
		
		OpenForm("DataProcessor.GeneratingProductionStages.Form.Form", New Structure("FiltersStructure", FiltersStructure), ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DefineParametersAndGenerateStages(References)
	
	CallbackDescription = New CallbackDescription(
		"DefineParametersAndGenerateStagesCompletion", 
		ThisObject);
	
	OpenForm("Document.ProductionStage2_2.Form.StageGenerationSettings", 
		New Structure("References", References),
		ThisForm,
		UUID,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DefineParametersAndGenerateStagesCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	RunBackgroundJob1("GenerateProductionStages", Result);
	
EndProcedure

&AtClient
Procedure PassStagesForExecution(Command)
	
	SelectedOrders = SelectedOrders();
	If SelectedOrders.UBound() = -1 Then
		Return;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("References", SelectedOrders);
	
	RunBackgroundJob1("PassStagesForExecution", ProcedureParameters);
	
EndProcedure

&AtClient
Procedure MarkProductionStagesForDeletion(Command)
	
	SelectedOrders = SelectedOrders();
	If SelectedOrders.UBound() = -1 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("MarkProductionStagesForDeletionCompletion", ThisForm, SelectedOrders);
	
	If SelectedOrders.Count() > 1 Then
		QueryText = NStr("vi = 'Đánh dấu xóa tất cả công đoạn của đơn hàng đã chọn?';
						|ru = 'Пометить на удаление все этапы выбранных заказов?';
						|en = 'Mark all stages of the selected order for deletion?'; fa = 'Mark all stages of the selected order for deletion?';
						|it = 'Contrassegnare per eliminazione tutte le fasi degli ordini selezionati?';
						|pl = 'Zaznaczyć do usunięcia wszystkie etapy wybranych zamówień?';
						|tr = 'Seçili emirlerinin tüm aşamaları silinmek üzere işaretlensin mi?'");
	Else
		Presentation = ProductionManagementServerCall.OrderPresentation(SelectedOrders[0],"");
		QueryText = StrTemplate(NStr("vi = 'Đánh dấu xóa tất cả công đoạn của đơn hàng %1?';
									|ru = 'Пометить на удаление все этапы заказа %1?';
									|en = 'Mark all stages of order %1 for deletion?'; fa = 'Mark all stages of order %1 for deletion?';
									|it = 'Contrassegnare per eliminazione tutte le fasi dell''ordine%1?';
									|pl = 'Chcesz zaznaczyć do skasowania wszystkie etapy zamówienia %1?';
									|tr = '%1 emrinin tüm aşamaları silinmek üzere işaretlensin mi?'"), Presentation);
	EndIf;
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure MarkProductionStagesForDeletionCompletion(QuestionResult, ProcedureParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	RunBackgroundJob1("MarkProductionStagesForDeletion", ProcedureParameters);
	
EndProcedure

&AtClient
Procedure StageDispatching(Command)
	
	Var ReferenceOrder;
	
	For Iterator_SSLy = 0 To Items.List.SelectedRows.Count() - 1 Do
		If TypeOf(Items.List.SelectedRows[Iterator_SSLy]) <> Type("DynamicListGroupRow") Then
			ReferenceOrder = Items.List.SelectedRows[Iterator_SSLy];
			Break;
		EndIf;
	EndDo;
	
	OpenStageManagement(ReferenceOrder);
	
EndProcedure

&AtClient
Procedure PlanTheCurrentOne(Command)
	
	SelectedOrders = SelectedOrders();
	
	If SelectedOrders.UBound() = -1 Then
		Return;
	EndIf;
	
	OpenOrderPlanningForm(SelectedOrders[0]);
	
EndProcedure

&AtClient
Procedure PlanTheSelectedOnes(Command)
	
	SelectedOrders = SelectedOrders();
	
	If SelectedOrders.UBound() = -1 Then
		Return;
	EndIf;
	
	DefineParametersAndSchedule(SelectedOrders);
	
EndProcedure

&AtClient
Procedure PlanTheQueueByTheCurrentOne(Command)
	
	SelectedOrders = SelectedOrders();
	
	If SelectedOrders.UBound() = -1 Then
		Return;
	EndIf;
	
	PlanningQueue = PlanningQueue(SelectedOrders[0], Department);
	DefineParametersAndSchedule(PlanningQueue);
	
EndProcedure

&AtClient
Procedure DefineParametersAndSchedule(References)
	
	FormParameters = New Structure;
	FormParameters.Insert("References", References);
	
	CallbackDescription = New CallbackDescription(
			"DefineParametersAndScheduleCompletion", 
			ThisObject, References);
	
	OpenForm("DataProcessor.ProductionSchedulePlanning2_2.Form.PlanningSettingsOfListOfReferencesAndStages", 
		FormParameters, ThisForm, UUID,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure DefineParametersAndScheduleCompletion(Result, References) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("References", References);
	
	For Each KeyAndValue In Result Do
		ProcedureParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	RunBackgroundJob1("PlanProductionSchedule", ProcedureParameters);
	
EndProcedure

&AtClient
Procedure GenerationOfOrders(Command)
	
	OpenPlanningOfSemiFinishedProducts();
	
EndProcedure

&AtClient
Procedure ShopStoreroomSupply(Command)
	
	OpenProvisionOfShopStorerooms();
	
EndProcedure

&AtClient
Procedure GenerateMovementsByProductionOrder(Command)
	
	SelectedOrders = SelectedOrders();
	
	If SelectedOrders.UBound() <> 0 Then
		Return;
	EndIf;
	
	FiltersStructure = New Structure();
	FiltersStructure.Insert("ProductionOrder", SelectedOrders[0]);
	
	OpenForm("DataProcessor.GenerateProductionOrderRegisterRecords.Form", New Structure("FiltersStructure", FiltersStructure), ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure RescheduleRequestedSupplyDates(Command)
	
	SelectedOrders = SelectedOrders();
	
	If SelectedOrders.UBound() = -1 Then
		Return;
	EndIf;
	
	FormParameters = New Structure("ReferenceOrder", SelectedOrders[0]);
	
	OpenForm("DataProcessor.RescheduleRequestedSupplyDateOfProductionStages.Form",
		FormParameters, ThisForm, SelectedOrders[0]);
	
EndProcedure

&AtClient
Procedure SetTheClosedStatus(Command)
	
	SelectedRows = SelectedOrders();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Đặt trạng thái ""Đã đóng"" cho các đơn hàng được chọn trong danh sách. Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""Закрыт"". Продолжить?';
					|en = 'Status of the orders selected in the list will be set to Closed. Continue?'; fa = 'Status of the orders selected in the list will be set to Closed. Continue?';
					|it = 'Per gli ordini selezionati nella lista sarà impostato lo stato ""Chiuso"". Continuare?';
					|pl = 'W wydzielonych w liście zamówieniach będzie ustawiony status ""Закрыт"". Kontynuować?';
					|tr = 'Listede belirtilen siparişler için ""Kapalı"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AdditionalParameters = New Structure("SelectedRows", SelectedRows);
	
	CallbackDescription = New CallbackDescription(
		"SetTheClosedStatusCompletion", 
		ThisObject, AdditionalParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheClosedStatusCompletion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Closed", New Structure("OrderFulfillmentControl"));
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã đóng';
																												|ru = 'Закрыт';
																												|en = 'Closed'; fa = 'بسته‌شده';
																												|it = 'Chiuso';
																												|pl = 'Closed';
																												|tr = 'Kapalı'"));
	
EndProcedure

&AtClient
Procedure RecalculateOrderStructure(Command)
	
	SelectedOrders = SelectedOrders();
	
	If SelectedOrders.UBound() = -1 Then
		Return;
	EndIf;
	
	OrderStructureClient.StartRecalculatingOrderStructure(SelectedOrders);
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List.SelectedRows);
	
EndProcedure

#EndRegion

#Region AdditionalSelectionPanelOrders

&AtClient
Procedure EmergingOrders(Command)
	
	OpenOrdersThatAreForming();
	
EndProcedure

&AtClient
Procedure ClosedOrders(Command)
	
	ToOpenTheClosedOrders();
	
EndProcedure

&AtClient
Procedure ExpandTheAddOnPanel(Command)
	
	AdditPanelCollapsed = False;
	
	ConfigureDependentFormElements(ThisForm, "AdditionalPanel");
	
EndProcedure

&AtClient
Procedure CollapseAnAdditionalPanel(Command)
	
	AdditPanelCollapsed = True;
	
	ConfigureDependentFormElements(ThisForm, "AdditionalPanel");
	
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

#EndRegion

#Region EventHandlersForFormElements

#Region Header

&AtClient
Procedure FilterDueDate_2OnChange(Item)
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate);
	
	ConfigureDependentFormElements(ThisForm, "FilterDueDate_2");
	
EndProcedure

&AtClient
Procedure FilterCompletionDateCleaningUp(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
	ConfigureDependentFormElements(ThisForm, "FilterDueDate_2");
	
EndProcedure

&AtClient
Procedure FilterDueDate_2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterDueDate_2",
		"EventDate");
	
EndProcedure

&AtClient
Procedure PrioritySelectionOnChange(Item)
	
	SetSelectionPriority();
	
EndProcedure

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	SetSelectionUnit();
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleFilterOnChange(Item)
	
	SetSelectionResponsible();
	
EndProcedure

&AtClient
Procedure StructureOfAdditionalSelectionsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "Disable_ProductionProcessType" Then
		
		ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.EmptyRef");
		CommonClientServer.SetDynamicListFilterItem(List, "ProductionProcessType", ProductionProcessType,,, False);
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "StructureOfAdditionalSelections");
	
EndProcedure

&AtClient
Procedure WarningCalculationStateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "MoreDetails" Then
		
		TypesList = New Array();
		TypesList.Add(PredefinedValue("Enum.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError"));
		TypesList.Add(PredefinedValue("Enum.ErrorsTypesOfProductionOrderStructureCalculation.InventoryAllocationError"));
		
		OpenForm("InformationRegister.OrderStructureCalculationProtocol.ListForm", New Structure("Filter", New Structure("ErrorType", TypesList)));
		
	ElsIf FormattedStringURL = "ShouldRecalculate" Then
		
		RecalculateOrderStructureCalculationErrors();
		
		Items.GroupWarningCalculationState.Visible = False;
		
		ShowUserNotification(NStr("vi = 'Đã phát hành bản sửa lỗi được ghi nhận';
									|ru = 'Запущено исправление зарегистрированных ошибок';
									|en = 'Correction of registered errors has been started'; fa = 'Correction of registered errors has been started';
									|it = 'Correzione degli errori registrati avviata';
									|pl = 'Uruchomiono korygowanie zarejestrowanych błędów';
									|tr = 'Bildirilen hata düzeltmeleri başlatıldı'"),,, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region AdditionalSelectionPanelOrders

&AtClient
Procedure FilterByStateOnChange(Item)
	
	SetSelectionByState();
	ConfigureDependentFormElements(ThisForm, "FilterByState");
	
EndProcedure

#EndRegion

#Region ListOfOrders

&AtClient
Procedure OrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TypeOf(RowSelected) <> Type("DocumentRef.ProductionOrder2_2") Then
		Return;
	EndIf;
	
	If Field.Name = "StatusOfProductionStagesAndSchedule" Then
	
		StandardProcessing = False;
		
		StatusCode = Item.CurrentData.StatusOfProductionStagesAndSchedule;
		
		ProcessingSelectionStateOfStagesAndProductionSchedule(StatusCode, RowSelected);
		
	ElsIf Field.Name = "SupplyState" Then
		
		StandardProcessing = False;
		
		StatusCode = Item.CurrentData.SupplyState;
		
		SoftwareStateSelectionProcessing(StatusCode, RowSelected);
		
	ElsIf Field.Name = "ProductReleaseStatus" Then
		
		StandardProcessing = False;
		
		StatusCode = Item.CurrentData.ProductReleaseStatus;
		
		SelectionProcessingOutputState(StatusCode, RowSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingSelectionStateOfStagesAndProductionSchedule(StatusCode, RowSelected)

	If StatusCode = 1 Then
		
		References = ReferencesArrray(RowSelected);
		DefineParametersAndGenerateStages(References);
		
	ElsIf StatusCode = 2 Then
		
		FiltersStructure = New Structure("ClarificationIsRequired", True);
		OpenStageManagement(RowSelected, FiltersStructure);
		
	ElsIf StatusCode = 3 Then
		
		OpenOrderPlanningForm(RowSelected);
		
	ElsIf StatusCode = 4 Then
		
		ProcedureParameters = ParametersForStartingTasksByOrder(RowSelected);
		
		RunBackgroundJob1("PassStagesForExecution", ProcedureParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SoftwareStateSelectionProcessing(StatusCode, RowSelected)
	
	If StatusCode = 1 Then
		
		FiltersStructure = New Structure("SupplyIsRequired", True);
		OpenStageManagement(RowSelected, FiltersStructure);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionProcessingOutputState(StatusCode, RowSelected)
	
EndProcedure

&AtClient
Procedure OrdersStartDragging(Item, DragParameters, Perform)
	
	Perform = EnableDrag;
	
EndProcedure

&AtClient
Procedure OrdersDragAndDropCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If DraggingIsAllowed(DragParameters.Value, String) Then
		DragParameters.Action = DragAction.Move;
	Else
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure OrdersEndOfDragAndDrop(Item, DragParameters, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(NewPositionInTheQueue) And DragParameters.Value.UBound() = 0 Then
		
		InsertDocumentIntoQueue(DragParameters.Value[0], NewPositionInTheQueue);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region List 
                
&AtServer
Procedure SetDynamicListProperties()
	
	QueryText =
		"SELECT
		|	
		|	Table.Ref AS Ref,
		|	Table.Number AS Number,
		|	Table.Date AS Date,
		|	Table.Status AS Status,
		|	Table.Priority AS Priority,
		|	Table.Department AS Department,
		|	Table.EarliestStartDate AS ProductionStart,
		|	Table.DemandDate AS DemandDate,
		|	Table.DynamicStructure AS DynamicStructure,
		|	
		|	&TextOfEventDateField AS EventDate,
		|	&FieldTextIsOverdue AS Overdue,
		|	
		|	CASE
		|		
		|		WHEN Table.DynamicStructure
		|			AND (TRUE IN 
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
		|					T.ProductionOrder = Table.Ref))
		|				OR TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					InformationRegister.OrderStructureCleanupTasks AS T
		|				WHERE
		|					T.ProductionOrder = Table.Ref)
		|			THEN 5
		|		
		|		WHEN Table.DynamicStructure
		|			AND (TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					InformationRegister.OrderStructureCalculationProtocol AS T
		|				WHERE
		|					T.ProductionOrder = Table.Ref))
		|			AND Table.Posted
		|			THEN 6
		|		
		|		WHEN NOT Table.DynamicStructure
		|			AND StatesOfProductionOrders.StageStatus = &TheStatusNeedsToBeChecked
		|			THEN 2
		|		
		|		WHEN NOT Table.DynamicStructure
		|			AND StatesOfProductionOrders.StageStatus = &TheStateIsRequiredToEstablishTheStages
		|			THEN 1
		|		
		|		WHEN &TheProductionScheduleIsPlanned
		|			AND (
		|				TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						InformationRegister.JobsToProductionScheduleCalculation AS T
		|					WHERE
		|						T.ReferenceOrder = Table.Ref)
		|				OR TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						InformationRegister.OrderStructureCalculationJobsProductionSchedule AS T
		|					WHERE
		|						T.ProductionOrder = Table.Ref)
		|				)
		|			THEN 3
		|		
		|		WHEN StatesOfProductionOrders.StageStatus = &StateRequiredToPassStagesToBeExecuted
		|			THEN 4
		|		
		|		ELSE -1
		|		
		|	END AS StatusOfProductionStagesAndSchedule,
		|
		|	CASE
		|		WHEN StatesOfProductionOrders.SupplyState = &TheStateIsRequiredToObtain
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS SupplyState,
		|
		|	CASE
		|		WHEN StatesOfProductionOrders.StatusOfProductionIssue = &TheStatusOfCompleted
		|			THEN 2
		|		WHEN StatesOfProductionOrders.StatusOfProductionIssue = &TheStateViolatedTheRequirementsDate
		|			THEN 1
		|		ELSE -1
		|	END AS ProductReleaseStatus,
		|	
		|	-Table.Priority.AddlOrderingAttribute AS PriorityQueue,
		|	Table.Department.AddlOrderingAttribute AS DivisionQueue,
		|	Table.Queue AS Queue,
		|
		|	Table.EmployeeResponsible AS EmployeeResponsible,
		|	Table.Comment   AS Comment
		|
		|FROM
		|	Document.ProductionOrder2_2 AS Table
		|
		|		LEFT JOIN InformationRegister.StatesOfProductionOrders AS StatesOfProductionOrders
		|		ON Table.Ref = StatesOfProductionOrders.OrderDocument
		|		 
		|WHERE 
		|	Table.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
		|	AND Table.Posted";
	
	If Not DynamicStructureIsUsed Then
		QueryText = StrReplace(QueryText, "&TextOfEventDateField", "Table.DemandDate");
	Else
		QueryText = StrReplace(QueryText, 
			"&TextOfEventDateField", 
			"CASE
			|	WHEN StatesOfProductionOrders.StatusOfProductionIssue = &TheStatusOfCompleted THEN
			|		DATETIME(1, 1, 1)
			|	ELSE
			// a stub for the period of updating data in information security
			|		CASE
			|			WHEN ISNULL(StatesOfProductionOrders.EventDate, DATETIME(1,1,1)) = DATETIME(1,1,1) THEN 
			|				Table.DemandDate
			|			ELSE
			|				StatesOfProductionOrders.EventDate
			|		END
			|END");
	EndIf; 
		
	If Not DynamicStructureIsUsed Then
		QueryText = StrReplace(QueryText, 
			"&FieldTextIsOverdue", 
			"CASE 
			|	WHEN Table.DemandDate <> DATETIME(1, 1, 1)
			|		AND &UpdateDate > Table.DemandDate
			|	THEN TRUE
			|	ELSE FALSE
			|END");
	Else
		QueryText = StrReplace(QueryText, 
			"&FieldTextIsOverdue", 
			"CASE
			|	WHEN NOT ISNULL(StatesOfProductionOrders.EventDate, DATETIME(1,1,1)) = DATETIME(1,1,1) 
			|		AND &UpdateDate > StatesOfProductionOrders.EventDate
			|	THEN TRUE
			|	ELSE FALSE
			|END");
	EndIf;
		
	ListProperties = Common.DynamicListPropertiesStructure();

	ListProperties.QueryText = QueryText;
	ListProperties.MainTable = List.MainTable;
	ListProperties.DynamicDataRead = True;

	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	List.Parameters.SetParameterValue("TheProductionScheduleIsPlanned", TheProductionScheduleIsPlanned);
	List.Parameters.SetParameterValue("TheStatusNeedsToBeChecked", Enums.StatesOfQueuedProductionOrders.ItIsRequiredToCheckStages);
	List.Parameters.SetParameterValue("TheStateIsRequiredToEstablishTheStages", Enums.StatesOfQueuedProductionOrders.StageGenerationIsRequired);
	List.Parameters.SetParameterValue("StateRequiredToPassStagesToBeExecuted", Enums.StatesOfQueuedProductionOrders.ItIsRequiredToReleaseStages);
	List.Parameters.SetParameterValue("TheStateIsRequiredToObtain", Enums.StatesOfQueuedProductionOrders.SupplyIsRequired);
	List.Parameters.SetParameterValue("TheStateViolatedTheRequirementsDate", Enums.StatesOfQueuedProductionOrders.DemandDateIsViolated);
	List.Parameters.SetParameterValue("TheStatusOfCompleted", Enums.StatesOfQueuedProductionOrders.Completed);

EndProcedure

#EndRegion

#Region Filters

&AtClientAtServerNoContext
Function ValuesOfBasicSelections(Form, OnlyFilledValues = True)
	
	FiltersStructure = New Structure;
	
	If Not OnlyFilledValues Or ValueIsFilled(Form.Priority) Then
		FiltersStructure.Insert("Priority", Form.Priority);
	EndIf;
	
	If Not OnlyFilledValues Or ValueIsFilled(Form.Department) Then
		FiltersStructure.Insert("Department", Form.Department);
	EndIf;
	
	If Not OnlyFilledValues Or ValueIsFilled(Form.EmployeeResponsible) Then
		FiltersStructure.Insert("EmployeeResponsible", Form.EmployeeResponsible);
	EndIf;

	Return FiltersStructure;

EndFunction

&AtServer
Procedure SetSelectionPriority()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Priority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));
	
	ConfigureDependentFormElements(ThisForm, "FilterPriority");
	
	UpdateHyperlinks(ThisObject);
	
EndProcedure

&AtServer
Procedure SetSelectionUnit()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
	ConfigureDependentFormElements(ThisForm, "FilterDepartment");
	
	UpdateHyperlinks(ThisObject);
	
EndProcedure

&AtServer
Procedure SetSelectionResponsible()
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
	ConfigureDependentFormElements(ThisForm, "FilterEmployeeResponsible");
	
	UpdateHyperlinks(ThisObject);
	
EndProcedure

&AtServer
Procedure SelectionByStateWhenCreatedOnServer(FiltersStructure)
	
	FiltersStructure.Property("ItIsRequiredToCheckStages",           FilterItIsRequiredToCheckStages);
	FiltersStructure.Property("StageGenerationIsRequired",        FilterStageGenerationIsRequired);
	FiltersStructure.Property("ScheduleCreationIsRequired",      FilterScheduleCreationIsRequired);
	FiltersStructure.Property("ItIsRequiredToReleaseStages", FilterItIsRequiredToReleaseStages);
	FiltersStructure.Property("SupplyIsRequired",              FilterSupplyIsRequired);
	FiltersStructure.Property("DemandDateIsViolated",           FilterDemandDateIsViolated);
	FiltersStructure.Property("Completed",                          FilterCompleted);
	
	SetSelectionByState();
	
EndProcedure

&AtServer
Procedure SetSelectionByState()
	
	CommonClientServer.DeleteFilterItems(List.Filter,, "SelectionGroupByState");
	
	SelectionByStateOfStagesAndSchedule = ListOfAvailableStageStatesAndSchedule();
	SelectionByStateOfRelease        = ListOfAvailableReleaseStates();
	
	If SelectionByStateOfStagesAndSchedule.Count() > 0
		Or FilterSupplyIsRequired
		Or SelectionByStateOfRelease.Count() > 0 Then
		
		SelectionGroupByState = CommonClientServer.CreateFilterItemGroup(
			List.Filter.Items, "SelectionGroupByState", DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.SetFilterItem(
			SelectionGroupByState, "StatusOfProductionStagesAndSchedule", SelectionByStateOfStagesAndSchedule, DataCompositionComparisonType.InList,, ValueIsFilled(SelectionByStateOfStagesAndSchedule));
			
		CommonClientServer.SetFilterItem(
			SelectionGroupByState, "SupplyState", FilterSupplyIsRequired, DataCompositionComparisonType.Equal,, FilterSupplyIsRequired);
		
		CommonClientServer.SetFilterItem(
			SelectionGroupByState, "ProductReleaseStatus", SelectionByStateOfRelease, DataCompositionComparisonType.InList,, ValueIsFilled(SelectionByStateOfRelease));
		
		SelectionGroupByState.Use = True;
		
	EndIf;
	
EndProcedure

&AtServer
Function ListOfAvailableStageStatesAndSchedule()

	Result = New Array;
	
	If FilterStageGenerationIsRequired Then
		Result.Add(1);
	EndIf;
	
	If FilterItIsRequiredToCheckStages Then
		Result.Add(2);
	EndIf;
	
	If FilterScheduleCreationIsRequired Then
		Result.Add(3);
	EndIf;
	
	If FilterItIsRequiredToReleaseStages Then
		Result.Add(4);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ListOfAvailableReleaseStates()

	Result = New Array;
	
	If FilterDemandDateIsViolated Then
		Result.Add(1);
	EndIf;
	
	If FilterCompleted Then
		Result.Add(2);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region UpdatingHyperlinks

&AtClient
Procedure Attachable_UpdateHyperlinks()
	
	UpdateHyperlinks(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateHyperlinks(Form)
	
	Items = Form.Items;
	
	FiltersStructure = ValuesOfBasicSelections(Form);
	FiltersStructure.Insert(
		"Status",
		PredefinedValue("Enum.ProductionOrderStatuses2_2.BeingGenerated"));
	
	OrdersCount = OrdersCount(FiltersStructure);
	NumberOfOrdersPerLine = Format(OrdersCount, "NZ=0; NG=0");
	
	Items.EmergingOrders.Title = StrTemplate(
												NStr("vi = 'Đang lập đơn hàng (%1)';
													|ru = 'Формирующиеся заказы (%1)';
													|en = 'Orders being generated (%1)'; fa = 'Orders being generated (%1)';
													|it = 'Ordini in fase di generazione (%1)';
													|pl = 'Utworzone zamówienia (%1)';
													|tr = 'Oluşturulmakta olan emirler (%1)'"),
												NumberOfOrdersPerLine);
	
EndProcedure

#EndRegion

#Region Queue

&AtClientAtServerNoContext
Function QueueAvailable(Form)
	
	Return Not (ValueIsFilled(Form.EventDate)
			Or ValueIsFilled(Form.Priority)
			Or ValueIsFilled(Form.EmployeeResponsible)
			Or ValueIsFilled(Form.Relevance)
			Or Form.FilterStageGenerationIsRequired
			Or Form.FilterItIsRequiredToCheckStages
			Or Form.FilterScheduleCreationIsRequired
			Or Form.FilterItIsRequiredToReleaseStages
			Or Form.FilterSupplyIsRequired
			Or Form.FilterDemandDateIsViolated
			Or Form.FilterCompleted
	);
	
EndFunction

&AtClient
Function DraggingIsAllowed(AnArrayOfOrders, CheckedPosition)
	
	If CheckedPosition <> Undefined 
		And TypeOf(AnArrayOfOrders) = Type("Array") And AnArrayOfOrders.UBound() = 0 
		And TypeOf(AnArrayOfOrders[0]) = Type("DocumentRef.ProductionOrder2_2")
		And YouCanInsertDocumentIntoQueue(AnArrayOfOrders[0], CheckedPosition) Then
		
		NewPositionInTheQueue = CheckedPosition;
		
	Else
		
		NewPositionInTheQueue = Undefined;
		
	EndIf;
	
	Return (NewPositionInTheQueue <> Undefined);
	
EndFunction

&AtServerNoContext
Function YouCanInsertDocumentIntoQueue(CurrentOrder, NewPositionInTheQueue)
	
	Return ObjectManager().YouCanInsertDocumentIntoQueue(CurrentOrder, NewPositionInTheQueue);
	
EndFunction

&AtServer
Procedure InsertDocumentIntoQueue(CurrentOrder, NewPositionInTheQueue)
	
	LockDataForEdit(CurrentOrder);
	LockDataForEdit(NewPositionInTheQueue);
	
	ObjectManager().InsertDocumentIntoQueue(CurrentOrder, NewPositionInTheQueue);
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure MoveOrderToQueue(CurrentOrder, Direction)
	
	If Not ObjectManager().YouCanMoveDocumentToQueue(CurrentOrder, Direction) Then
		Return;
	EndIf;
	
	LockDataForEdit(CurrentOrder);

	ObjectManager().MoveDocumentToQueue(CurrentOrder, Direction);
	
	Items.List.Refresh();
	
EndProcedure

&AtServerNoContext
Function PlanningQueue(CurrentOrder, ProductionDispatcherBusinessUnit)
	
	Return ObjectManager().PlanningQueue(CurrentOrder, ProductionDispatcherBusinessUnit);
	
EndFunction

#EndRegion

#Region OrderStructure

&AtClient
Procedure CheckOrderStructureCalculationErrors() Export

	If Not ThereAreErrorsInCalculatingOrderStructure() Then
		
		Items.GroupWarningCalculationState.Visible = False;
		
	Else
		
		RowsArray = New Array();
		RowsArray.Add(NStr("vi = 'Đã tính toán bị lỗi cấu trúc đơn hàng';
							|ru = 'Расчет структуры заказов завершился с ошибками';
							|en = 'The order structure calculation completed with errors'; fa = 'The order structure calculation completed with errors';
							|it = 'Calcolo della struttura degli ordini eseguita con errori';
							|pl = 'Obliczenie struktury zamówień zostało zakończono z błędami';
							|tr = 'Sipariş yapısının hesaplanması hatayla sonuçlandı'"));
		RowsArray.Add(" ");
		RowsArray.Add(New FormattedString(NStr("vi = 'tính lại';
												|ru = 'пересчитать';
												|en = 'recalculate'; fa = 'recalculate';
												|it = 'ricalcolare';
												|pl = 'recalculate';
												|tr = 'yeniden hesapla'"),,,, "ShouldRecalculate"));
		RowsArray.Add(" / ");
		RowsArray.Add(New FormattedString(NStr("vi = 'chi tiết';
												|ru = 'подробнее';
												|en = 'details'; fa = 'details';
												|it = 'dettagli';
												|pl = 'details';
												|tr = 'daha fazla bilgi'"),,,, "MoreDetails"));
		WarningCalculationState = New FormattedString(RowsArray);
		Items.GroupWarningCalculationState.Visible = True;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ThereAreErrorsInCalculatingOrderStructure()

	ProtocolIsAvailable = AccessRight("View", Metadata.InformationRegisters.OrderStructureCalculationProtocol);

	If Not ProtocolIsAvailable Then
		Return False;
	EndIf;
	
	ThereAreErrorsInProtocol = InformationRegisters.OrderStructureCalculationProtocol.CheckOrderQueueErrors();
	
	Return ThereAreErrorsInProtocol;
	
EndFunction

&AtServerNoContext
Procedure RecalculateOrderStructureCalculationErrors()

	InformationRegisters.OrderStructureCalculationProtocol.RecalculateErrorsFromOrderQueue();
	
EndProcedure

#EndRegion

#Region BackgroundJobs

&AtClient
Procedure RunBackgroundJob1(JobName, ProcedureParameters)
	
	ClearMessages();
	
	RunResult = RunBackgroundJobOnServer(JobName, ProcedureParameters);
	
	If RunResult.StartWaiting Then
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("ExecuteInBackgroundCompletion", ThisObject, New Structure("JobName", JobName)),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
		
	Else
		
		NotifyAboutTaskCompletion(JobName, RunResult.JobResult);
		
	EndIf;
	
EndProcedure

&AtServer
Function RunBackgroundJobOnServer(JobName, ProcedureParameters)
	
	If JobName = "GenerateProductionStages" Then
		ProcedureName = "Documents.ProductionStage2_2.GenerateStages";
		JobDescription = NStr("vi = 'Tạo các công đoạn sản xuất';
								|ru = 'Формирование этапов производства';
								|en = 'Generate production stages'; fa = 'ایجاد مراحل تولید';
								|it = 'Generazione fasi di produzione';
								|pl = 'Tworzenie etapów produkcji';
								|tr = 'Üretim aşamalarının oluşturulması'");
	ElsIf JobName = "PassStagesForExecution" Then
		ProcedureName = "Documents.ProductionStage2_2.PassStagesToExecutionDeferred";
		JobDescription = NStr("vi = 'Chuyển giao các công đoạn cần thực hiện';
								|ru = 'Передача этапов к выполнению';
								|en = 'Release stages'; fa = 'ترخیص مراحل';
								|it = 'Trasferimento delle fasi in esecuzione';
								|pl = 'Przekazanie etapów do wykonania';
								|tr = 'Aşamaların gerçekleştirmeye transferi'");
	ElsIf JobName = "MarkProductionStagesForDeletion" Then
		ProcedureName = "Documents.ProductionStage2_2.MarkStagesDeferredForDeletion";
		JobDescription = NStr("vi = 'Đánh dấu xóa các công đoạn sản xuất';
								|ru = 'Пометка на удаление этапов производства';
								|en = 'Production stage deletion mark'; fa = 'Production stage deletion mark';
								|it = 'Contrassegno di eliminazione delle fasi di produzione';
								|pl = 'Zaznaczenie do usuwania etapów produkcji';
								|tr = 'Üretim aşamalarının silinmesine yönelik işaret'");
	ElsIf JobName = "PlanProductionSchedule" Then
		ProcedureName = "ProductionManagement.ScheduleOrders";
		JobDescription = NStr("vi = 'Lập kế hoạch sản xuất';
								|ru = 'Планирование графика производства';
								|en = 'Production schedule creating'; fa = 'Production schedule creating';
								|it = 'Programmazione del piano di produzione';
								|pl = 'Planowanie harmonogramu produkcji';
								|tr = 'Üretim programını planlama'");
	Else
		Return New Structure("StartWaiting, JobResult", False, Undefined);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.RunInBackground = True;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, ExecutionParameters);
	
	StartWaiting = True;
	JobResult = Undefined;
	
	If TimeConsumingOperation.Status <> "Running" Then
		
		StartWaiting = False;
		JobResult = ProcessResultOfBackgroundTask(TimeConsumingOperation);
		
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return New Structure("StartWaiting, JobResult", StartWaiting, JobResult);
	
EndFunction

&AtClient
Procedure ExecuteInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		JobResult = ProcessResultOfBackgroundTask(Result);
		
		NotifyAboutTaskCompletion(AddlParameters.JobName, JobResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutTaskCompletion(JobName, JobResult)

	If JobName = "GenerateProductionStages" Then
		
		ProductionManagementClient.NotifyUserAboutFormationOfProductionStages(
			JobResult, UUID);
		
	ElsIf JobName = "PassStagesForExecution" Then
		
		ProductionManagementClient.NotifyUserWhenStepsAreReadyForExecution(
			JobResult, UUID);
		
	ElsIf JobName = "MarkProductionStagesForDeletion" Then
		
		ProductionManagementClient.NotifyUserAboutMarkToDeleteProductionStages(
			JobResult);
		
	ElsIf JobName = "PlanProductionSchedule" Then
		
		ProductionManagementClient.NotifyUserOfProductionSchedulePlanning(
			JobResult, UUID);
			
	EndIf;

EndProcedure

&AtServer
Function ProcessResultOfBackgroundTask(Result)
	
	JobResult = GetFromTempStorage(Result.ResultAddress);
	
	If Result.Status = "Error" Then
		
		If TypeOf(JobResult) = Type("Structure") And JobResult.Property("Messages") Then
			
			For Each Message In JobResult.Messages Do
			
				Message.TargetID = UUID;
				Message.Message();
				
			EndDo;
			
		EndIf;
		
		Raise Result.BriefErrorDescription;
		
	Else
		
		Items.List.Refresh();
		
	EndIf;
	
	Return JobResult;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure CustomizeFormElements()
	
	// Visibility/Accessibility Settings
	
	AccessRightInsert = Documents.ProductionOrder2_2.AccessRightInsert();
	
	UseCreateSubmenu = GetFunctionalOption("UseAdvancedDemandFulfillment")
							  Or GetFunctionalOption("UseProductionPlanning");
	
	CommonClientServer.SetFormItemProperty(Items, "SubmenuListGroupCreate", "Visible", AccessRightInsert And UseCreateSubmenu);
	CommonClientServer.SetFormItemProperty(Items, "CreateNewList",         "Visible", AccessRightInsert And Not UseCreateSubmenu);
	CommonClientServer.SetFormItemProperty(Items, "ListCopy",          "Visible", AccessRightInsert);
	
	MultipleDivisionsAreUsed = Catalogs.BusinessStructure.MultipleDispatcherUnitsAreUsed();
	Items.FilterDepartment.Visible = MultipleDivisionsAreUsed;
	
	Items.PlanTheCurrentOne.Visible   = TheProductionScheduleIsPlanned;
	Items.PlanTheSelectedOnes.Visible = TheProductionScheduleIsPlanned;
	
	Items.ContextMenuToScheduleTheCurrent.Visible   = TheProductionScheduleIsPlanned;
	Items.TheShortcutMenuPlanSelected.Visible = TheProductionScheduleIsPlanned;
	
	Items.PlanTheQueueByTheCurrentOne.Visible                = TheProductionScheduleIsPlanned;
	Items.ContextMenuScheduleQueueByCurrent.Visible = TheProductionScheduleIsPlanned;
	
	Items.TheTeamSelectionProcessPlanningSchedule.Visible       = TheProductionScheduleIsPlanned;
	Items.TheTeamSelectionProcessViolatedTheRequirementsDate.Visible = TheProductionScheduleIsPlanned;
	
	Items.FormRescheduleRequestedSupplyDates.Visible = TheProductionScheduleIsPlanned;
	Items.ContextMenuToMoveTheDesiredDateEnsure.Visible = TheProductionScheduleIsPlanned;
	
	Items.SupplyState.Visible          = Not DynamicStructureIsUsed;
	Items.GroupSelectionRequiresSecurity.Visible = Not DynamicStructureIsUsed;
	
	Items.GroupSelectionRequiresFormationOfStages.Visible = Not DynamicStructureIsUsed;
	
	Items.GenerateProductionStages.Title = ?(DynamicStructureIsUsed,
		NStr("vi = 'Tạo lô hàng...';
			|ru = 'Cформировать партии...';
			|en = 'Generate lots...'; fa = 'تولید لات‌ها...';
			|it = 'Creazione lotti...';
			|pl = 'Utwórz partie...';
			|tr = 'Lotları oluştur...'"),
		NStr("vi = 'Tạo công đoạn...';
			|ru = 'Cформировать этапы...';
			|en = 'Generate stages...'; fa = 'ایجاد مراحل...';
			|it = 'Creazione fasi...';
			|pl = 'Utwórz etapy...';
			|tr = 'Aşamaları oluştur...'"));
	Items.TheContextMenuToCreateTheProductionStages.Title = Items.GenerateProductionStages.Title;
	
	Items.StageDispatching.Visible = Documents.ProductionStage2_2.StageDispatchingIsAvailable();
	
	ConfigureFormElementsByRights();
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsByRights()

	DemandFulfillmentIsAvailable = AccessRight("View", Metadata.DataProcessors.DemandFulfillment);
	
	YouCanCreateOrdersForMaterials = 
			DemandFulfillmentIsAvailable 
			And AccessRight("InteractiveInsert", Metadata.Documents.OrderOfMaterialsForProduction);
			
	FormationOfPurchaseOrdersIsAvailable = GetFunctionalOption("UsePurchaseOrders") 
			And AccessRight("InteractiveInsert", Metadata.Documents.PurchaseOrder);
			
	BuildOrdersCanBeGenerated = GetFunctionalOption("UseAssemblyDisassemblyOrders")
			And AccessRight("InteractiveInsert", Metadata.Documents.ByAssemblyDisassemblyOrder);
					
	CreationOfOrdersForMovingIsAvailable = GetFunctionalOption("UseTransferOrders")
			And AccessRight("InteractiveInsert", Metadata.Documents.TransferOrder);
					
	
	OrdersCanBeGeneratedForProcessor2_5 = GetFunctionalOption("UseProductionByThirdParty2_5")
			And AccessRight("InteractiveInsert", Metadata.Documents.SubcontractOrder2_5);
	
	ExpandedProvisionOfNeeds = GetFunctionalOption("UseAdvancedDemandFulfillment");
	
	FormationOfMovementsAccordingToProductionScheduleIsAvailable = DynamicStructureIsUsed
			And (CreationOfOrdersForMovingIsAvailable Or YouCanCreateOrdersForMaterials)
			And AccessRight("View", Metadata.DataProcessors.GenerateProductionOrderRegisterRecords);
	
	StoreroomSupplyIsAvailable = 
			DemandFulfillmentIsAvailable
			And ExpandedProvisionOfNeeds
			And (YouCanCreateOrdersForMaterials
				Or FormationOfPurchaseOrdersIsAvailable
				Or BuildOrdersCanBeGenerated
				Or CreationOfOrdersForMovingIsAvailable
				Or OrdersCanBeGeneratedForProcessor2_5);
	
	Items.HowToScheduleSemiFinishedProducts.Visible = DemandFulfillmentIsAvailable;
	Items.PlanSemiFinishedProducts_3.Visible = DemandFulfillmentIsAvailable;
	
	Items.SoftwareForShopStorerooms.Visible = StoreroomSupplyIsAvailable;
	Items.ShopStoreroomSupply.Visible = StoreroomSupplyIsAvailable;
	
	Items.ContextMenuToGenerateMovementsOnProductionOrders.Visible = FormationOfMovementsAccordingToProductionScheduleIsAvailable;
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.ProductionOrder2_2);
	Items.ChangeSelectedItems.Visible                      = ChangeSelectedAvailable;
	Items.ListContextMenuChangeSelectedItems.Visible = ChangeSelectedAvailable;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// Priority selection
	If AttributesStructure1.Property("FilterPriority") Or Initialize Then
		
		Items.Priority.Visible = Not ValueIsFilled(Form.Priority);
		
	EndIf;
	
	// Selection by dispatcher division
	If AttributesStructure1.Property("FilterDepartment") Or Initialize Then
		
		Items.Department.Visible = Items.FilterDepartment.Visible
											And Not ValueIsFilled(Form.Department);
		
	EndIf;
	
	// Selection by responsible person
	If AttributesStructure1.Property("FilterEmployeeResponsible") Or Initialize Then
		
		Items.EmployeeResponsible.Visible = Not ValueIsFilled(Form.EmployeeResponsible);
		
	EndIf;
	
	// Availability of queue controls
	If AttributesStructure1.Property("FilterPriority")
		Or AttributesStructure1.Property("FilterEmployeeResponsible")
		Or AttributesStructure1.Property("FilterDueDate_2")
		Or AttributesStructure1.Property("FilterByState")
		Or Initialize Then
		
		QueueAvailable = QueueAvailable(Form);
		
		Form.EnableDrag = QueueAvailable;
		
		Items.MoveDown.Enabled  = QueueAvailable;
		Items.MoveUp.Enabled = QueueAvailable;
		
		Items.PlanTheQueueByTheCurrentOne.Enabled                = QueueAvailable;
		Items.ContextMenuScheduleQueueByCurrent.Enabled = QueueAvailable;
		
	EndIf;
	
	// Information label
	If AttributesStructure1.Property("StructureOfAdditionalSelections")
		Or Initialize Then
		
		RowsArray = New Array;
		
		If ValueIsFilled(Form.ProductionProcessType) Then
			
			StringText = StrTemplate(NStr("vi = 'Kiểu quy trình sản xuất: ""%1""';
											|ru = 'Тип производственного процесса: ""%1""';
											|en = 'Production process: %1'; fa = 'Production process: %1';
											|it = 'Tipo di processo di produzione: ""%1""';
											|pl = 'Typ operacji: ""%1""';
											|tr = 'Üretim süreci türü: ""%1""'"), Form.ProductionProcessType);;
			RowsArray.Add(New FormattedString(StringText));
			RowsArray.Add(" (");
			RowsArray.Add(New FormattedString(NStr("vi = 'ngắt kết nối';
													|ru = 'отключить';
													|en = 'disable'; fa = 'disable';
													|it = 'disattivare';
													|pl = 'disable';
													|tr = 'devre dışı bırak'"),,,, "Disable_ProductionProcessType"));
			RowsArray.Add(")");
			
		EndIf;
		
		Form.StructureOfAdditionalSelections = New FormattedString(RowsArray);
		Items.StructureOfAdditionalSelections.Visible = ValueIsFilled(RowsArray);
		
	EndIf;
	
	// Setting up the elements located on the additional selection panel
	If AttributesStructure1.Property("AdditionalPanel")
		Or Initialize Then
		
		Items.PlanSemiFinishedProducts_3.Visible    = Not Form.AdditPanelCollapsed And Form.DemandFulfillmentIsAvailable;
		Items.EmergingOrders.Visible           = Not Form.AdditPanelCollapsed;
		Items.ShopStoreroomSupply.Visible    = Not Form.AdditPanelCollapsed And Form.StoreroomSupplyIsAvailable;
		
		Items.ExpandTheAddOnPanel.Visible   = Form.AdditPanelCollapsed;
		Items.CollapseAnAdditionalPanel.Visible     = Not Form.AdditPanelCollapsed;
		Items.ToOpenTheClosedOrders.Visible = Not Form.AdditPanelCollapsed;
		
		Items.SceneryToTakeOrders.Title = 
				?(Form.AdditPanelCollapsed, NStr("vi = 'Hiển thị';
												|ru = 'Отобрать';
												|en = 'Pick'; fa = 'انتخاب';
												|it = 'Selezionare';
												|pl = 'Pick';
												|tr = 'Seç'"), 
					NStr("vi = 'Chọn đơn hàng yêu cầu';
						|ru = 'Отобрать заказы, для которых требуется';
						|en = 'Filter orders'; fa = 'Filter orders';
						|it = 'Selezionare gli ordini per cui è richiesto';
						|pl = 'Wybierz zamówienia dla których wymaga się';
						|tr = 'Emirleri filtrele'"));
		
		Items.SceneryToTakeOrdersContinued.Title = 
				?(Not Form.AdditPanelCollapsed, NStr("vi = 'Hoặc';
													|ru = 'Или по которым';
													|en = 'Or orders where/which are:'; fa = 'یا سفارش‌هایی که:';
													|it = 'Oppure per i quali';
													|pl = 'Lub według których';
													|tr = 'Diğer'"), "");
		
		CurPromptDisplay = ?(Form.AdditPanelCollapsed, 
											ToolTipRepresentation.Balloon,
											ToolTipRepresentation.ShowRight);
		
		ItemArray = New Array;
		
		ItemArray.Add(Items.DecorationAdditionalSelectionYouNeedToCreateStages);
		ItemArray.Add(Items.DecorationAdditionalSelectionYouNeedToCheckTheStages);
		ItemArray.Add(Items.DecorationAdditionalSelectionSchedulePlanningRequired);
		ItemArray.Add(Items.DecorationAdditionalSelectionMustBeSubmittedForExecution);
		ItemArray.Add(Items.DecorationAdditionalSelectionIsRequiredToObtain);
		ItemArray.Add(Items.DecorationAdditionalSelectionViolatedDateOfNeed);
		ItemArray.Add(Items.DecorationAdditionalSelectionCompleted);
		
		For Each CurrentItem In ItemArray Do
			
			CurrentItem.ToolTipRepresentation = CurPromptDisplay;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// Date
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);

	// Priority
	SetConditionalDesignOfPriorityField();
	
	// start of production
	ProductionManagement.SetConditionalAppearanceOfProductionDateField(ThisObject, "List", "ProductionStart");
	
	// due date
	#Region DueDate_2
	ProductionManagement.SetConditionalAppearanceOfProductionDateField(ThisObject, "List", "EventDate");

	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField("EventDate");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Overdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);

	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField("EventDate");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DemandDate"); // if there is no need date, then there is no deadline
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetConditionalDesignOfPriorityField()
	
	ProductionManagement.SetConditionalAppearanceOfPriorityField(ThisObject, "List", "PriorityQueue", "Priority", True, "Priority", "PrioritySelection");
	
EndProcedure

&AtClient
Procedure OpenStageManagement(ReferenceOrder, AdditionalFilters = Undefined)
	
	Filters = New Structure;
	
	Filters.Insert("ProductionDispatcherBusinessUnit", Department);
	Filters.Insert("ReferenceOrder",           ReferenceOrder);
	
	If AdditionalFilters <> Undefined Then
		
		CommonClientServer.SupplementStructure(Filters, AdditionalFilters);
		
	EndIf;
	
	OpenForm("Document.ProductionStage2_2.Form.ProductionStageDispatching",
		New Structure("FiltersStructure", Filters), ThisForm);
	
	Notify(ProductionManagementClientServer.EventNameUpdateStageDispatching(),
		Filters, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenOrderPlanningForm(ReferenceOrder)
	
	FormParameters = New Structure("ReferenceOrder", ReferenceOrder);
	
	OpenForm("DataProcessor.ProductionSchedulePlanning2_2.Form.CreatingProductionOrderSchedule", 
		FormParameters,, ReferenceOrder);

EndProcedure

&AtClient
Procedure OpenPlanningOfSemiFinishedProducts()
	
	FormParameters = SupplyClient.ParametersForOpeningProcessingFormProvidingNeeds();
	
	FormParameters.FilterBySupplyType      = PredefinedValue("Enum.SupplyTypes.Production");
	FormParameters.FilterBySupplySource = Department;
	
	FormParameters.ThereIsInventoryStep = False;
	
	OpenForm("DataProcessor.DemandFulfillment.Form",
		FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure OpenProvisionOfShopStorerooms()
	
	FormParameters = SupplyClient.ParametersForOpeningProcessingFormProvidingNeeds();
	
	FormParameters.SelectionByWorkshopStorerooms = True;
	
	OpenForm("DataProcessor.DemandFulfillment.Form",
		FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure OpenOrdersThatAreForming()
	
	FiltersStructure = ValuesOfBasicSelections(ThisForm, False);
	FiltersStructure.Insert("Status", PredefinedValue("Enum.ProductionOrderStatuses2_2.BeingGenerated"));
	
	OpenForm("Document.ProductionOrder2_2.ListForm", 
		New Structure("FiltersStructure", FiltersStructure));

EndProcedure

&AtClient
Procedure ToOpenTheClosedOrders()
	
	FiltersStructure = ValuesOfBasicSelections(ThisForm, False);
	FiltersStructure.Insert("Status", PredefinedValue("Enum.ProductionOrderStatuses2_2.Closed"));
	
	OpenForm("Document.ProductionOrder2_2.ListForm",
		New Structure("FiltersStructure", FiltersStructure));

EndProcedure

&AtServerNoContext
Function OrdersCount(Val FilterParameters)
	
	Return Documents.ProductionOrder2_2.OrdersCount(FilterParameters);
	
EndFunction

&AtClient
Function SelectedOrders()

	Return TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);

EndFunction

&AtClientAtServerNoContext
Function ReferencesArrray(Ref = Undefined)
	
	ReferencesArrray = New Array;
	
	If Ref <> Undefined Then
		ReferencesArrray.Add(Ref);
	EndIf;
	
	Return ReferencesArrray;
	
EndFunction

&AtClient
Function ParametersForStartingTasksByOrder(RowSelected)
	
	ReferencesArrray = ReferencesArrray(RowSelected);
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("References", ReferencesArrray);
	
	Return ProcessingParameters;

EndFunction

&AtServerNoContext
Function ObjectManager()
	
	Return Documents.ProductionOrder2_2;
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionOrder2_2.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#EndRegion

#EndRegion
