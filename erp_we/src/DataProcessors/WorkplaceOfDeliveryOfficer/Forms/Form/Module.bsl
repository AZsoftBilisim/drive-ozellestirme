// @strict-types

#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var NumberOfAllocatedOrderLines; // Number

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BoldFont = StyleFonts.BoldFont;
	ColorGreen = StyleColors.SuccessResultColor;
	ColorRed = StyleColors.ResultIssueColor;
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FillChoiceLists();
	
	// To fill in when changing the element of datareferences 
	CurrentSessionDate = CurrentSessionDate();
	RestoreSettings();
	WarehouseWas = Warehouse;
	
	AreaGroupOrEmpty = (Not ValueIsFilled(Zone) Or Common.ObjectAttributeValue(Zone,"IsFolder"));
	
	DataProcessor = FormAttributeToValue("Object");
	ProcessFullName = DataProcessor.Metadata().FullName();
	
	UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	SetColumnHeadersWeightVolumeServer();
	
	EditDeliveryAddressesOnlyInDialogBox = GetFunctionalOption("EditDeliveryAddressesOnlyInDialogBox");
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.TransportationTasksPlannedTimeFrom);
	ElementsToFillIn.Add(Items.TransportationTasksPlannedTimeBy);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	GoodsDelivery.SetAvailabilityOfDeliveryAddresses(ThisObject.Items);
	
	GoodsDelivery.FillInCarrierSelectionList(Items,,Warehouse);
	
	Items.DocumentsForCarriersCarrier.Visible = Not ValueIsFilled(Carrier);
	
	If ValueIsFilled(Parameters.DeliveryKind) Then
		DeliveryKind = Parameters.DeliveryKind;
		Items.DeliveryKind.Visible = False;
		Title = Parameters.DeliveryKind;
	EndIf;
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	WarehouseOnChangeServer(); // The lists are also updated here
	SetVisibilityOfWarehouses();
	
	// StandardSubsystems.AttachableCommands
	TypesList = TransportationJobsInProgress.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.CommandBarTransportationJobsInProgress;
	PlacementParameters.GroupsPrefix = "TransportationJobsInProgress";
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	TypesList = Metadata.DefinedTypes.DeliveryReferenceOrder.Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.CommandBarDocumentsForCarriers;
	PlacementParameters.GroupsPrefix = "DocumentsForCarriers";
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExpandOrders();
	TasksToDeploy();
	NumberOfAllocatedOrderLines = 0;
	If Items.MainPages.CurrentPage = Items.CreatingTransportationTasksPage Then
		AttachIdleHandler("CheckingIfYouNeedToRecalculateTotalsForDeliveryOrdersWaitingHandler",1.3,False);
	EndIf;
	
	TransportTasksScheduledWhenWaitHandlerLineIsActivated();
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If ChoiceSource.FormName = ProcessFullName + ".Form.ReferencesChoiceForm" Then
		SplitDeliveryPointServer(ValueSelected);
	ElsIf ChoiceSource.FormName = "Catalog.Vehicles.Form.ChoiceForm"
		Or ChoiceSource.FormName = "Catalog.VehicleTypes.Form.ChoiceForm" Then
		CurrentData = Items.ScheduledTransportationJobs.CurrentData;
		CurrentData.Transport = ValueSelected;
		FillPropertyValues(CurrentData, VehicleDetails(ValueSelected));
	EndIf;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		SaveSettingsAndTasksToAnotherServer();
		NotifyAboutCreatedTasks();
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_InstructionForShippingAgent" Then
		UpdateListOfDeliveryOrders(Source);
	ElsIf EventName = "Write_TransportationJob" Then
		UpdateListsForCurPage();
	ElsIf EventName = "CancelingDeliveryException" Then
		UpdateListOfDeliveryOrders(Parameter.ReferenceAddress);
	EndIf;
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeliveryKindOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.DeliveryKind.OnChange");
	
	DeliveryKindOnChangeServer();
	NotifyAboutCreatedTasks();
	
EndProcedure

&AtClient
Procedure DateOfOrders_OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfOrders_OnChangeServer();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.Warehouse.OnChange");
	
	If Warehouse <> WarehouseWas Then
		
		ErrorText = "";
		WarehouseOnChangeServer(ErrorText);
		If Not IsBlankString(ErrorText) Then
			ShowMessageBox(, ErrorText);
			Return;
		EndIf;
		
		NotifyAboutCreatedTasks();
		WarehouseWas = Warehouse;
	EndIf;
	
EndProcedure

&AtClient
Procedure ZoneOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.Zone.OnChange");
	
	ZoneOnChangeServer();
	
EndProcedure

&AtClient
Procedure MainPagesOnCurrentPageChange(Item, CurrentPage)
	
	AttachIdleHandler("UpdateListsForCurPage", 0.1, True);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOfOrders_Tuning(Item, Direction, StandardProcessing)
	
	If Not ValueIsFilled(DateOfOrders_) Then
		DateOfOrders_ = CurrentSessionDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOfOrders_StartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not ValueIsFilled(DateOfOrders_) Then
		DateOfOrders_ = CurrentSessionDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure CarrierOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.CarrierPartner.OnChange");
	
	CarrierOnChangeServer();
EndProcedure

&AtClient
Procedure PeriodOfDocumentsForCarriersOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.PeriodOfDocumentsForCarriers.OnChange");
	
	UpdateDocumentsForCarriers();
EndProcedure

&AtClient
Procedure FilterByAssigneeTypeOnChange(Item)
	
	SaveTasksUpdateLists();
	
EndProcedure

&AtClient
Procedure LabelReferencesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	LineItem = ScheduledTransportationJobs.FindByID(Items.ScheduledTransportationJobs.CurrentRow);
	RowJob = LineTaskByLineItem(LineItem);
	
	FormParameters = New Structure;
	FormParameters.Insert("TransportationJob", RowJob.Ref);
	FormParameters.Insert("Vehicle_", RowJob.Transport);
	FormParameters.Insert("TaskWeight", RowJob.Weight);
	FormParameters.Insert("TaskScope", RowJob.VolumeM3);
	FormParameters.Insert("PlanTripStartTime", RowJob.TimeFrom);
	FormParameters.Insert("DeliveryKind", DeliveryKind);
	FormParameters.Insert("AddressOfGoodsForDelivery", PlaceGoodsInStorageForDelivery(RowJob.Ref));
	If LineItem = RowJob Then
		FormParameters.Insert("ReferenceAddress", PutItInStorage(RowJob.Ref));
	Else
		FormParameters.Insert("ReferenceAddress", PutItInStorage(LineItem.ConnectionKey));
		FormParameters.Insert("Address", LineItem.Address);
		FormParameters.Insert("TimeFrom", LineItem.TimeFrom);
		FormParameters.Insert("TimeTo", LineItem.TimeTo);
	EndIf;
	
	CallbackDescription = New CallbackDescription("AfterEditingOrders",ThisObject);
	
	OpenForm("DataProcessor.WorkplaceOfDeliveryOfficer.Form.RoutePointReferences",
		FormParameters, ThisObject,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDeliveryReferences

&AtClient
Procedure DeliveryReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectedRowTreeElement = DeliveryReferences.FindByID(RowSelected);
	If SelectedRowTreeElement.GetItems().Count() = 0 Then
		ShowValue(Undefined, SelectedRowTreeElement.ReferenceOrder);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryReferencesDragStart(Item, DragParameters, Perform)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.DeliveryReferences.DragStart");
	
	StartedMoving = True;
	
EndProcedure

&AtClient
Procedure DeliveryReferencesDragEnd(Item, DragParameters, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.DeliveryReferences.DragEnd");
	
	StartedMoving = False;
	
EndProcedure

&AtClient
Procedure DeliveryReferencesDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.DeliveryReferences.DragCheck");
	
	StandardProcessing = False;
	CheckSetDragAndDropValidity(Item, DragParameters);
	
EndProcedure

&AtClient
Procedure DeliveryReferencesDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.DeliveryReferences.Drag");
	
	StandardProcessing = False;
	If TypeOf(DragParameters.Value[0]) = Type("FormDataTreeItem")
		And DragParameters.Value[0].Property("DateSwitch") Then
		// Dragging from transportation tasks
		RemoveLinesFromJobsClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryReferencesOnActivateRow(Item)
	
	AttachIdleHandler("DeliveryOrdersWhenWaitHandlerLineIsActivated", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScheduledTransportationJobs

&AtClient
Procedure ScheduledTransportationJobsOnActivateRow(Item)
	
	AttachIdleHandler("TransportTasksScheduledWhenWaitHandlerLineIsActivated", 0.1, True);
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.ScheduledTransportationJobs.Drag");
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value[0]) = Type("Number") Then
		If String <> Undefined Then
			// Dragging and dropping within the list of Transportation tasks generated
			MoveLinesInsideListOfTasksGeneratedByServer(DragParameters.Value,String);
			NotifyAboutCreatedTasks();
		EndIf;
	ElsIf DragParameters.Value[0].Property("ReferenceKind") Then
		// Dragging from Orders
		MoveLines(String);
	ElsIf DragParameters.Value[0].Property("ConnectionKey") Then
		// Dragging from the list of orders
	EndIf;
	TransportTasksScheduledWhenWaitHandlerLineIsActivated();
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsSelection(Item, RowSelected, Field, StandardProcessing)
	
	String = ScheduledTransportationJobs.FindByID(RowSelected);
	ThisIsAGrouping = (String.GetParent() = Undefined);
	If ThisIsAGrouping Then
		If Field.ReadOnly Or Field.Name = "ScheduledTransportationJobsZone" Then
			StandardProcessing = False;
			OpenTaskForm(String);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	NumberOfRecordedTasks = 0;
	For Each ID In Items.ScheduledTransportationJobs.SelectedRows Do
		Page1 = ScheduledTransportationJobs.FindByID(ID);
		If Page1.GetParent() = Undefined And ValueIsFilled(Page1.Ref) Then
			NumberOfRecordedTasks = NumberOfRecordedTasks + 1;
		EndIf;
	EndDo;
	If NumberOfRecordedTasks > 0 Then
		
		Mode = New ValueList; // ValueList of DialogReturnCode
		Mode.Add(DialogReturnCode.Yes, NStr("vi = 'Đánh dấu';
											|ru = 'Пометить';
											|en = 'Mark'; fa = 'علامت';
											|it = 'Contrassegnare';
											|pl = 'Mark';
											|tr = 'İşaretle'"));
		Mode.Add(DialogReturnCode.No, NStr("vi = 'Không đánh dấu, chỉ xóa lộ trình';
											|ru = 'Не помечать, только очистить маршруты';
											|en = 'Do not mark, only clear routes'; fa = 'Do not mark, only clear routes';
											|it = 'Non contrassegnare, cancellare solo percorsi';
											|pl = 'Nie zaznaczać, tylko wyczyścić trasy';
											|tr = 'İşaretlemeyin, sadece güzergahları temizleyin'"));
		Mode.Add(DialogReturnCode.Cancel);
		Text = NStr("vi = 'Đánh dấu xóa các nhiệm vụ vận chuyển đã chọn?';
					|ru = 'Пометить на удаление выделенные задания на перевозку?';
					|en = 'Mark the selected itineraries for deletion?'; fa = 'Mark the selected itineraries for deletion?';
					|it = 'Contrassegnare per l''eliminazione i compiti di trasporto selezionati?';
					|pl = 'Oznaczyć na usunięcie zaznaczone zadania na przewóz?';
					|tr = 'Tahsis edilen taşıma planları silinmek üzere işaretlensin mi?'");
		
		ShowQueryBox(New CallbackDescription("ScheduledTransportationJobsBeforeDeleteRowCompletion", ThisObject), Text, Mode);
		Return;
		
	Else
		
		RemoveLinesFromJobsClient();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsBeforeDeleteRowCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	MarkTasksForDeletion_ = False;
	If QuestionResult = DialogReturnCode.Yes Then
		MarkTasksForDeletion_ = True;
	EndIf;
	
	RemoveLinesFromJobsClient(False, MarkTasksForDeletion_);
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	If Not ValueIsFilled(CachedValues) Then
		CachedValues = New Structure("Address,FieldValueAddress,Zone,TimeFrom,TimeTo,AdditionalInformation");
	EndIf;
	FillPropertyValues(CachedValues, CurrentData);
	
	If EditDeliveryAddressesOnlyInDialogBox
		Or CurrentData.GetParent() = Undefined Then
		Items.ScheduledTransportationJobsAddress.TextEdit = False;
	Else
		Items.ScheduledTransportationJobsAddress.TextEdit = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsOnEditEnd(Item, NewRow, CancelEdit)
	CurrentData = Item.CurrentData;
	If Not (CurrentData = Undefined)
		And Not TMCommonUseClientServer.StructuresAreEqual(CachedValues, Item.CurrentData,
		"Address,FieldValueAddress,Zone,TimeFrom,TimeTo,AdditionalInformation") Then
		DetermineIfModified(CurrentData,JobsModified);
	EndIf;
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsDragStart(Item, DragParameters, Perform)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.ScheduledTransportationJobs.DragStart");
	
	StartedMoving = True;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsDragEnd(Item, DragParameters, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.ScheduledTransportationJobs.DragEnd");
	
	StartedMoving = False;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Item.ScheduledTransportationJobs.DragCheck");
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TransportationTasksScheduledTimeWhenChanging(Item)
	
	If Item = Items.TransportationTasksPlannedTimeFrom
		Or Item = Items.TransportationTasksPlannedDateFrom Then
		TimeFromTimeTo        = "TimeFrom";
		TimeFromTimeToNoDate = "TimeFromWithoutDate"
	Else
		TimeFromTimeTo        = "TimeTo";
		TimeFromTimeToNoDate = "TimeToWithoutDate";
	EndIf;
	CurRow = Items.ScheduledTransportationJobs.CurrentData;
	CurRow[TimeFromTimeTo] = BegOfDay(CurRow[TimeFromTimeTo])
		+ Hour(CurRow[TimeFromTimeToNoDate])*60*60 + Minute(CurRow[TimeFromTimeToNoDate])*60;
	
	CheckTimeCompliance(TimeFromTimeTo);
	Parent = CurRow.GetParent();
	If Parent = Undefined Then
		TasksCheckSortFillTransitionAttributes();
	Else
		CurBranch = Parent.GetItems();
		CurIndex__ = CurBranch.IndexOf(CurRow);
		If (CurIndex__ > 0 And CurRow.TimeFrom <= CurBranch[CurIndex__-1].TimeFrom)
			Or (CurIndex__ < CurBranch.Count()-1 And CurRow.TimeFrom >= CurBranch[CurIndex__+1].TimeFrom) Then
			TasksSortRenumberFillInDateTransitionAttributes();
		Else
			DestinationLineID = CurRow.GetID();
			FillInDateTransitionSigns(DestinationLineID);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("Address");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Items.ScheduledTransportationJobs.CurrentData,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("ValueListItem") Then
		StandardProcessing = False;
		Items.ScheduledTransportationJobs.CurrentData.Address = ValueSelected.Presentation;
		Items.ScheduledTransportationJobs.CurrentData.FieldValueAddress = ValueSelected.FieldValues;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsTransportStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	List = New ValueList; // ValueList of String
	List.Add(NStr("vi = 'Phương tiện vận chuyển';
					|ru = 'Транспортное средство';
					|en = 'Vehicle'; fa = 'وسیله نقلیه';
					|it = 'Mezzo di trasporto';
					|pl = 'Środek transportu';
					|tr = 'Araç'"));
	List.Add(NStr("vi = 'Kiểu phương tiện vận tải';
					|ru = 'Тип транспортного средства';
					|en = 'Vehicle type'; fa = 'نوع وسیله نقلیه';
					|it = 'Tipo di mezzo di trasporto';
					|pl = 'Typ pojazdu';
					|tr = 'Araç türü'"));
	
	ShowChooseFromList(New CallbackDescription("ScheduledTransportationJobsTransportStartChoiceCompletion", ThisObject), List, Item);
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsTransportStartChoiceCompletion(SelectedElement, AdditionalParameters) Export
	
	Selected_2Type = SelectedElement;
	
	If Selected_2Type = Undefined Then
		Return;
	ElsIf Selected_2Type.Value = NStr("vi = 'Phương tiện vận chuyển';
										|ru = 'Транспортное средство';
										|en = 'Vehicle'; fa = 'وسیله نقلیه';
										|it = 'Mezzo di trasporto';
										|pl = 'Środek transportu';
										|tr = 'Araç'") Then
		OpenForm("Catalog.Vehicles.Form.ChoiceForm",, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	Else
		OpenForm("Catalog.VehicleTypes.Form.ChoiceForm",, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsTransportOnChange(Item)
	
	CurrentData = Items.ScheduledTransportationJobs.CurrentData;
	
	If CurrentData.Transport <> Undefined Then
		FillPropertyValues(CurrentData, VehicleDetails(CurrentData.Transport));
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsTransportClearing(Item, StandardProcessing)
	
	If Items.ScheduledTransportationJobs.CurrentData.GetParent() = Undefined Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsAdditionalInformationStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	Notification = New CallbackDescription("ScheduledTransportationJobsAdditionalInformationStartChoiceCompletion", ThisObject);
	CommonClient.ShowMultilineTextEditingForm(
		Notification,
		Items.ScheduledTransportationJobsAdditionalInformation.EditText,
		Items.ScheduledTransportationJobs.CurrentData.AdditionalInformation);

EndProcedure

&AtClient
Procedure ScheduledTransportationJobsAdditionalInformationStartChoiceCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		CurrentData = Items.ScheduledTransportationJobs.CurrentData;
		CurrentData.AdditionalInformation = ClosingResult;
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheStatusOfTransportationTasks(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.TransportationJobsInProgress);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	StatusName = CorrespondenceOfCommandsToStatuses().Get(Command.Name);
	
	If Command.Name = "SetTheClosedStatusForFullyDeliveredTasks" Then
		AdditionalParameters.Insert("DeliveryControl", True);
	EndIf;
	StatusHeader = PredefinedValue("Enum.StatusesOfTransportationJobs." + StatusName);
	
	ClearMessages();
	HighlightedLinks = Items.TransportationJobsInProgress.SelectedRows;
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks, StatusName, AdditionalParameters);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.TransportationJobsInProgress,
		ProcessedItemsCount, HighlightedLinks.Count(), StatusHeader);
	
EndProcedure

&AtClient
Procedure UpdateDeliveryLists(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Command.UpdateDeliveryLists");
	
	UpdateListsForCurPage();
	
EndProcedure

&AtClient
Procedure MoveLinesToJob(Command)
	
	MoveLines();
	
EndProcedure

&AtClient
Procedure OpenJob(Command)
	
	CurrentData = Items.ScheduledTransportationJobs.CurrentData;
	If CurrentData = Undefined Then
		Return
	EndIf;
	OpenTaskForm(LineTaskByLineItem(Items.ScheduledTransportationJobs.CurrentData));
	
EndProcedure

&AtClient
Procedure RemoveLinesFromJobs(Command)
	
	ClearMessages();
	
	If Items.ScheduledTransportationJobs.SelectedRows.Count() > 0 Then
		RemoveLinesFromJobsClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure TasksUp(Command)
	
	CurrentData = Items.ScheduledTransportationJobs.CurrentData;
	If CurrentData = Undefined Then
		Return
	EndIf;
	Parent = CurrentData.GetParent();
	If Parent = Undefined Then
		Return
	EndIf;
	IndexOf = Parent.GetItems().IndexOf(CurrentData);
	Branch1 = Parent.GetItems();
	If IndexOf <> 0 Then
		Branch1.Move(IndexOf, -1);
		Branch1[IndexOf-1].SequenceInRoute = IndexOf;
		Branch1[IndexOf].SequenceInRoute	 = IndexOf+1;
		Branch1[IndexOf-1].TimeFrom			 = Branch1[IndexOf].TimeFrom;
		Branch1[IndexOf-1].TimeFromWithoutDate	 = GoodsDeliveryClientServer.TimeWithoutDate(Branch1[IndexOf].TimeFrom);
		Branch1[IndexOf-1].TimeTo			 = Branch1[IndexOf].TimeFrom;
		Branch1[IndexOf-1].TimeToWithoutDate	 = GoodsDeliveryClientServer.TimeWithoutDate(Branch1[IndexOf].TimeFrom);
		
		If Branch1[IndexOf].DateSwitch = 1 Then
			Branch1[IndexOf-1].DateSwitch = 1;
		Else
			Branch1[IndexOf-1].DateSwitch = 0;
		EndIf;
		
		If Branch1[IndexOf].DateSwitch > 1 Then
			Branch1[IndexOf].DateSwitch = 2;
		Else
			Branch1[IndexOf].DateSwitch = 0;
		EndIf;
		
		If Branch1.Count() > IndexOf + 1 Then
			Branch1[IndexOf+1].DateSwitch = 0;
			If BegOfDay(Branch1[IndexOf+1].TimeFrom) <> BegOfDay(Branch1[IndexOf].TimeFrom) Then
				Branch1[IndexOf+1].DateSwitch = 1;
			EndIf;
			If BegOfDay(Branch1[IndexOf+1].TimeFrom) <> BegOfDay(Branch1[IndexOf+1].TimeTo) Then
				Branch1[IndexOf+1].DateSwitch = Branch1[IndexOf+1].DateSwitch + 2;
			EndIf;
		EndIf;
	EndIf;
	DetermineIfModified(Parent, JobsModified);
	
EndProcedure

&AtClient
Procedure TasksDown(Command)
	
	CurrentData = Items.ScheduledTransportationJobs.CurrentData;
	If CurrentData = Undefined Then
		Return
	EndIf;
	Parent = CurrentData.GetParent();
	If Parent = Undefined Then
		Return
	EndIf;
	IndexOf = Parent.GetItems().IndexOf(CurrentData);
	Branch1 = Parent.GetItems();
	If IndexOf <> Branch1.Count()-1 Then
		Branch1.Move(IndexOf, 1);
		Branch1[IndexOf+1].SequenceInRoute = IndexOf+2;
		Branch1[IndexOf].SequenceInRoute	 = IndexOf+1;
		Branch1[IndexOf+1].TimeFrom			 = Branch1[IndexOf].TimeTo;
		Branch1[IndexOf+1].TimeFromWithoutDate	 = GoodsDeliveryClientServer.TimeWithoutDate(Branch1[IndexOf+1].TimeFrom);
		Branch1[IndexOf+1].TimeTo			 = Branch1[IndexOf].TimeTo;
		Branch1[IndexOf+1].TimeToWithoutDate	 = GoodsDeliveryClientServer.TimeWithoutDate(Branch1[IndexOf+1].TimeTo);
		
		If Branch1[IndexOf+1].DateSwitch = 1 Then
			Branch1[IndexOf].DateSwitch = 1;
		EndIf;
		Branch1[IndexOf+1].DateSwitch = 0;
		
		If BegOfDay(Branch1[IndexOf].TimeFrom) <> BegOfDay(Branch1[IndexOf].TimeTo) Then
			Branch1[IndexOf].DateSwitch	 = 2;
		EndIf;
	EndIf;
	DetermineIfModified(Parent, JobsModified);
	
EndProcedure

&AtClient
Procedure FillInWithYesterdayTrips(Command)
	
	ClearMessages();
	
	FillServerWithPastFlights();
	
EndProcedure

&AtClient
Procedure FillInWithTripsOnDate(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Title",NStr("vi = 'Hãy chọn ngày tạo nhiệm vụ cho vận chuyển';
										|ru = 'Выберите дату формирования эаданий на перевозку';
										|en = 'Select a delivery order generation date'; fa = 'Select a delivery order generation date';
										|it = 'Selezionate la data di generazione dei task di spedizione';
										|pl = 'Wybierz datę sporządzenia zadań na transport';
										|tr = 'Taşıma emirlerinin oluşturulma tarihini seçin'"));
	FormParameters.Insert("NoteText",NStr("vi = 'Các nhiệm vụ vào ngày đã chọn sẽ được sử dụng như là khuôn mẫu để điền danh sách.';
											|ru = 'Задания на выбранную дату будут использованы в качестве шаблона для заполнения списка.';
											|en = 'Jobs for the selected date will be used as a template for populating the list.'; fa = 'Jobs for the selected date will be used as a template for populating the list.';
											|it = 'I task per la data selezionata verranno utilizzati come modello per compilare l''elenco.';
											|pl = 'Zadania na wybraną datę zostaną wykorzystane jako szablon do wypełnienia listy.';
											|tr = 'Seçilen tarihe ait görevler, listeyi tamamlamak için bir şablon olarak kullanılacaktır.'"));
	
	ClearMessages();
	
	OpenForm("CommonForm.SelectDate",FormParameters,,,,, New CallbackDescription("FillInWithTripsOnDateCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInWithTripsOnDateCompletion(Result, AdditionalParameters) Export
	
	SelectedDate = Result;
	
	If ValueIsFilled(SelectedDate) Then
		FillServerWithPastFlights(SelectedDate);
	EndIf;

EndProcedure

&AtClient
Procedure CreateTransportationJobs(Command)
	
	OpenTransportSelection();
	
EndProcedure

&AtClient
Procedure DistributeReferencesByTime(Command)
	
	ClearMessages();
	
	CurrentData = Items.ScheduledTransportationJobs.CurrentData;
	If CurrentData = Undefined Then
		Return
	EndIf;
	If CurrentData.GetParent() = Undefined Then
		Text = NStr("vi = 'Chỉ có thể phân chia dòng đối với các dòng địa chỉ';
					|ru = 'Разбиение строки возможно только для строк-адресов';
					|en = 'Line split is available only for address lines'; fa = 'Line split is available only for address lines';
					|it = 'La divisione della riga è possibile solo per gli indirizzi di riga';
					|pl = 'Podział wiersza jest możliwe tylko dla wierszy-adresów';
					|tr = 'Dize bölme yalnızca adres dizeleri için mümkündür'");
		CommonClient.MessageToUser(Text);
		Return;
	EndIf;
	If Not CheckSplitDeliveryPointServer() Then
		ReferenceAddress = PutItInStorage(CurrentData.ConnectionKey);
		FormParameters = New Structure("ReferenceAddress", ReferenceAddress);
		OpenForm(ProcessFullName + ".Form.ReferencesChoiceForm", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure UniteByTime(Command)
	
	ClearMessages();
	
	If Items.ScheduledTransportationJobs.SelectedRows.Count() < 2 Then
		CommonClient.MessageToUser(NStr("vi = 'Để hợp nhất, cần chọn ít nhất 2 dòng.';
										|ru = 'Для объединения необходимо выделить хотя бы 2 строки.';
										|en = 'Select at least 2 lines to merge.'; fa = 'Select at least 2 lines to merge.';
										|it = 'Per l''unione è necessario selezionare almeno 2 righe.';
										|pl = 'Dla połączenia należy wybrać przynajmniej 2 wierszy.';
										|tr = 'Birleştirmek için en az 2 satır seçilmelidir.'"));
	ElsIf Not UniteByTimeServer() Then
		CommonClient.MessageToUser(NStr("vi = 'Không thể hợp nhất các dòng được chọn: chọn các dòng có địa chỉ giống hệt nhau.';
										|ru = 'Не удалось объединить выделенные строки: выберите строки с одинаковыми адресами.';
										|en = 'Unable to merge the selected lines: select lines with the same addresses.'; fa = 'Unable to merge the selected lines: select lines with the same addresses.';
										|it = 'Non è stato possibile unificare le righe selezionate: scegliete le righe con gli stessi indirizzi.';
										|pl = 'Nie udało się połączyć wybrane wiersze: wybierz wiersze z jednakowymi adresami.';
										|tr = 'Seçilen satırlar birleştirilemedi: aynı adrese sahip satırları seçin.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateTransportationJob(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Command.CreateTransportationJob");
	
	StructureOfFillValue = New Structure;
	StructureOfFillValue.Insert("Warehouse", Warehouse);
	StructureOfFillValue.Insert("Operation", DeliveryKind);
	
	OpenForm("Document.TransportationJob.ObjectForm", New Structure("FillingValues", StructureOfFillValue));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	If Items.MainPages.CurrentPage = Items.TheJobsPageOnTransportationToWork Then
		List = Items.TransportationJobsInProgress;
	ElsIf Items.MainPages.CurrentPage = Items.DocumentsForCarriersPage Then
		List = Items.DocumentsForCarriers;
	EndIf;
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, List);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	
	If Items.MainPages.CurrentPage = Items.TheJobsPageOnTransportationToWork Then
		List = Items.TransportationJobsInProgress;
	ElsIf Items.MainPages.CurrentPage = Items.DocumentsForCarriersPage Then
		List = Items.DocumentsForCarriers;
	EndIf; 
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, List, Result);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	List = Undefined;
	If Items.MainPages.CurrentPage = Items.TheJobsPageOnTransportationToWork Then
		List = Items.TransportationJobsInProgress;
	ElsIf Items.MainPages.CurrentPage = Items.DocumentsForCarriersPage Then
		List = Items.DocumentsForCarriers;
	EndIf;
	
	If List <> Undefined Then
		AttachableCommandsClientServer.UpdateCommands(ThisObject, List);
	EndIf;
	
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure CreateInstructionForShippingAgent(Command)
	
	FormParameters = New Structure("Warehouse", Warehouse);
	OpenForm("Document.InstructionForShippingAgent.Form.DocumentForm", FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ExcludeFromDelivery(Command)
	
	ExcludeFromDeliveryOnServer();
	UpdateListsForCurPage();
	
EndProcedure

&AtClient
Procedure ReturnExcludedOnesToDelivery(Command)
	
	FormParameters = New Structure("Warehouse", Warehouse);
	OpenForm(ProcessFullName + ".Form.CancellationFormOfExclusionFromDelivery", FormParameters, ThisObject);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
#Region DeliveryReferences
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveryReferencesAddress.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.Zone");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.DeliveryZones.EmptyRef();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.RowAppearance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 5;
	
	Item.Appearance.SetParameterValue("Font", New Font(, , , True));
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<vùng không được chỉ định>';
													|ru = '<зона не указана>';
													|en = '<area is not specified>'; fa = '<area is not specified>';
													|it = '<area is not specified>';
													|pl = '<strefa nie została określona>';
													|tr = '<alan belirtilmedi>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveryReferencesPicture.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.ArtistTypeImage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.RowAppearance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 5;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveryReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.RowAppearance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 5;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportHeaderBackColor);
	Item.Appearance.SetParameterValue("Font", New Font(, , True));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveryReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.RowAppearance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);
	
#EndRegion

#Region ScheduledTransportationJobs
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobs.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);
	Item.Appearance.SetParameterValue("Font", New Font(, , True));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationTasksPlannedDateFrom.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.DateSwitch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 1;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.DateSwitch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 3;
	
	Item.Appearance.SetParameterValue("Text", "");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationTasksPlannedDateBy.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.DateSwitch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 2;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.DateSwitch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 3;
	
	Item.Appearance.SetParameterValue("Text", "");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsCarrier.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationTasksPlannedByTheCarrierSTransport.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ThisIsOurDelivery");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsTransport.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationTasksPlannedCapacity.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ThisIsOurDelivery");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsTransport.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationTasksPlannedCapacity.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsCarrier.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationTasksPlannedByTheCarrierSTransport.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsAddress.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsZone.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsWeight.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.Weight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("ScheduledTransportationJobs.CarryingCapacityInUserUnit");
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScheduledTransportationJobsVolumeM3.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.VolumeM3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("ScheduledTransportationJobs.CapacityInUserUnits");
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledTransportationJobs.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
#EndRegion

#Region TransportationJobsInProgress
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "TransportationJobsInProgress.Date", Items.TransportationJobsInProgressDate.Name);
	
	// Presentation of the planned flight end date today: "09:46"
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationJobsInProgressPlanTripEndTime.Name);
	
	ItemPresentation = NStr("vi = 'Trình bày ngày hôm nay: ""09:46""';
							|ru = 'Представление даты сегодня: ""09:46""';
							|en = 'Date presentation today: ""09:46""'; fa = 'Date presentation today: ""09:46""';
							|it = 'Visualizzazione della data di oggi: ""09:46""';
							|pl = 'Wyświetlanie daty dzisiaj: ""09:46""';
							|tr = 'Bugünün tarihi: ""09:46""'");
	ConditionalAppearanceItem.Presentation = ItemPresentation;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.PlanTripEndTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.PlanTripEndTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.PlanTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DF=HH:mm");
	
	// Representation of the actual flight end date today: "09:46"
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationJobsInProgressActualTripEndTime.Name);
	
	ItemPresentation = NStr("vi = 'Trình bày ngày hôm nay: ""09:46""';
							|ru = 'Представление даты сегодня: ""09:46""';
							|en = 'Date presentation today: ""09:46""'; fa = 'Date presentation today: ""09:46""';
							|it = 'Visualizzazione della data di oggi: ""09:46""';
							|pl = 'Wyświetlanie daty dzisiaj: ""09:46""';
							|tr = 'Bugünün tarihi: ""09:46""'");
	ConditionalAppearanceItem.Presentation = ItemPresentation;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.ActualTripEndTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.ActualTripEndTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.ActualTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DF=HH:mm");
	
	// Presentation of the planned start date of the flight today: "09:46"
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationJobsInProgressPlanTripStartTime.Name);
	
	ItemPresentation = NStr("vi = 'Trình bày về ngày kết thúc dự kiến ​​ngày hôm nay: ""09:46""';
							|ru = 'Представление плановой даты окончания сегодня: ""09:46""';
							|en = 'Planned end date presentation today: ""09:46""'; fa = 'Planned end date presentation today: ""09:46""';
							|it = 'Visualizzazione della data del termine programmata per oggi: ""09:46""';
							|pl = 'Przedstawienie planowanej daty zakończenia dzisiaj: ""09:46""';
							|tr = 'Bugünkü planlanan bitiş tarihi: ""09:46""'");
	ConditionalAppearanceItem.Presentation = ItemPresentation;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.PlanTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.PlanTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DF=HH:mm");
	
	// Presentation of the planned start date of the flight today: "09:46"
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationJobsInProgressActualTripStartTime.Name);
	
	ItemPresentation = NStr("vi = 'Trình bày về ngày kết thúc dự kiến ​​ngày hôm nay: ""09:46""';
							|ru = 'Представление плановой даты окончания сегодня: ""09:46""';
							|en = 'Planned end date presentation today: ""09:46""'; fa = 'Planned end date presentation today: ""09:46""';
							|it = 'Visualizzazione della data del termine programmata per oggi: ""09:46""';
							|pl = 'Przedstawienie planowanej daty zakończenia dzisiaj: ""09:46""';
							|tr = 'Bugünkü planlanan bitiş tarihi: ""09:46""'");
	ConditionalAppearanceItem.Presentation = ItemPresentation;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.ActualTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TransportationJobsInProgress.ActualTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DF=HH:mm");
	
#EndRegion
		
EndProcedure

#Region BarcodesAndTradeEquipment

&AtServer
Function LinkToListItemByBarcode(Barcode)
	
	Return BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		If TypeOf(ReferencesArrray[0]) = Type("DocumentRef.TransportationJob") Then
			If Items.MainPages.CurrentPage <> Items.TheJobsPageOnTransportationToWork Then
				Items.MainPages.CurrentPage = Items.TheJobsPageOnTransportationToWork;
				UpdateListsForCurPage();
			EndIf;
			Items.TransportationJobsInProgress.CurrentRow = ReferencesArrray[0];
		ElsIf ValueIsFilled(Warehouse)
			And Items.DocumentsForCarriersPage.Visible = True Then
			If Items.MainPages.CurrentPage <> Items.DocumentsForCarriersPage Then
				Items.MainPages.CurrentPage = Items.DocumentsForCarriersPage;
				UpdateListsForCurPage();
			EndIf;
			FoundRows = DocumentsForCarriers.FindRows(New Structure("Ref",ReferencesArrray[0]));
			If FoundRows.Count() > 0 Then
				Items.DocumentsForCarriers.CurrentRow = FoundRows[0].GetID();
			EndIf;
		EndIf;
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillChoiceLists()
	
	EnumValues = Metadata.Enums.StatusesOfTransportationJobs.EnumValues;
	
	ChoiceList = Items.Status.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("AllInProgress", NStr("vi = 'Tất cả đang làm việc';
										|ru = 'Все в работе';
										|en = 'All in progress'; fa = 'All in progress';
										|it = 'Tutto in esecuzione';
										|pl = 'Wszystkie w toku';
										|tr = 'Tümü faaliyette'"));
	ChoiceList.Add(EnumValues.BeingGenerated.Name, EnumValues.BeingGenerated.Synonym);
	ChoiceList.Add(EnumValues.ToLoad.Name, EnumValues.ToLoad.Synonym);
	ChoiceList.Add(EnumValues.Sent.Name, EnumValues.Sent.Synonym);
	ChoiceList.Add(EnumValues.Closed.Name, EnumValues.Closed.Synonym);
	ChoiceList.Add("", NStr("vi = 'Tất cả';
							|ru = 'Все';
							|en = 'All'; fa = 'همه';
							|it = 'Все';
							|pl = 'All';
							|tr = 'Tümü'"));
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure WarehouseOnChangeServer(ErrorText = "")
	
	WarehouseIsFull = ValueIsFilled(Warehouse);
	Items.MainPages.Enabled        = WarehouseIsFull;
	Items.UpdateDeliveryLists.Enabled = WarehouseIsFull;
	
	If WarehouseIsFull Then
		If DeliveryKind = Enums.DeliveryKinds.FromWarehouse Then
			ThereIsOrderWarehouse = WarehousesServer.ThereIsOrderWarehouseForShipment(Warehouse);
			ThereIsNonOrderWarehouse = WarehousesServer.ThereIsWarehouseThatIsNotOrderForShipment(Warehouse);
		Else
			ThereIsOrderWarehouse = WarehousesServer.ThereIsOrderForReceiptWarehouse(Warehouse);
			ThereIsNonOrderWarehouse = WarehousesServer.ThereIsWarehouseThatIsNotOrderForReceipt(Warehouse);
		EndIf;
		
		GroupSelected = Common.ObjectAttributeValue(Warehouse, "IsFolder");
		GroupSelected = ?(GroupSelected = Undefined, False, GroupSelected);
		
		If GroupSelected
			And Not ThereIsOrderWarehouse
			And Not ThereIsNonOrderWarehouse Then
			Warehouse = WarehouseWas;
			ErrorText = NStr("vi = 'Nhóm được chọn không chứa kho.';
							|ru = 'Выбранная группа не содержит складов.';
							|en = 'Selected group does not contain warehouses.'; fa = 'Selected group does not contain warehouses.';
							|it = 'Il gruppo selezionato non contiene magazzini.';
							|pl = 'Wybrana grupa nie zawiera magazynów.';
							|tr = 'Seçilen grup herhangi bir depo içermiyor.'");
			Return;
		EndIf;
	EndIf;
	
	SetVisibilityOfWarehouses();
	
	GoodsDelivery.FillInCarrierSelectionList(Items,,Warehouse);
	
	SaveTasksUpdateLists();
	
	SetItemsAvailability();
	
EndProcedure

&AtClientAtServerNoContext
Procedure DetermineIfModified(TreeRow, JobsModified, ValueToSet = True)
	
	TreeRow.ItemModified = ValueToSet;
	Parent = TreeRow.GetParent();
	If Parent <> Undefined Then
		Parent.ItemModified = ValueToSet;
	EndIf;
	
	// At least one task has been modified.
	JobsModified = True;
	
EndProcedure

&AtServer
Procedure SaveSettingsAndTasksToAnotherServer()
	
	Settings = New Map;
	Settings.Insert("Warehouse",                           Warehouse);
	Settings.Insert("SaveDate",                  CurrentSessionDate());
	Settings.Insert("DateOfOrders_",                DateOfOrders_);
	Settings.Insert("Zone",                            Zone);
	Settings.Insert("Status",                          Status);
	Settings.Insert("Carrier",                      Carrier);
	Settings.Insert("PeriodOfDocumentsForCarriers", PeriodOfDocumentsForCarriers);
	Settings.Insert("CurrentPageName",              Items.MainPages.CurrentPage.Name);
	Settings.Insert("DeliveryKind",                     DeliveryKind);
	Settings.Insert("FilterByAssigneeType",         FilterByAssigneeType);
	
	Common.CommonSettingsStorageSave("DataProcessor.WorkplaceOfDeliveryOfficer", "Settings", Settings);
	
	SaveTasksToAnotherServer();

EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.WorkplaceOfDeliveryOfficer", "Settings");
	
	If TypeOf(SettingsValue) = Type("Map") Then

		Warehouse                           = SettingsValue.Get("Warehouse");
		SaveDate                  = SettingsValue.Get("SaveDate");
		DateOfOrders_                = SettingsValue.Get("DateOfOrders_");
		Zone                            = SettingsValue.Get("Zone");
		Status                          = SettingsValue.Get("Status");
		Carrier                      = SettingsValue.Get("Carrier");
		PeriodOfDocumentsForCarriers = SettingsValue.Get("PeriodOfDocumentsForCarriers");
		CurrentPageName              = SettingsValue.Get("CurrentPageName");
		DeliveryKind                     = SettingsValue.Get("DeliveryKind");
		FilterByAssigneeType         = SettingsValue.Get("FilterByAssigneeType");
		
		If Not ValueIsFilled(PeriodOfDocumentsForCarriers.StartDate) Then
			PeriodOfDocumentsForCarriers.Variant = StandardPeriodVariant.Last7Days;
		ElsIf PeriodOfDocumentsForCarriers.Variant = StandardPeriodVariant.Custom Then
			PeriodOfDocumentsForCarriers.EndDate = Date(1,1,1);
		EndIf;
		
		// If in the past days we planned for the future, then we substitute the future day
		If (BegOfDay(SaveDate) < BegOfDay(DateOfOrders_)) Then
			DateOfOrders_ = Max(CurrentSessionDate + 60*60*24, DateOfOrders_)
		ElsIf ValueIsFilled(DateOfOrders_) Then
			DateOfOrders_ = CurrentSessionDate
		EndIf;
		
		If ValueIsFilled(CurrentPageName)
			And Items.Find(CurrentPageName) <> Undefined Then
			Items.MainPages.CurrentPage = Items[CurrentPageName];
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(DeliveryKind) Then
		DeliveryKind = Enums.DeliveryKinds.FromWarehouse;
	EndIf;
	
	CustomizeFormByDeliveryType();
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse, True, True);
	
EndProcedure

&AtClient
Procedure ExpandOrders()
	If Not AreaGroupOrEmpty Then
		Return;
	EndIf;
	
	For Each TreeRow In DeliveryReferences.GetItems() Do
		Items.DeliveryReferences.Expand(TreeRow.GetID());
	EndDo;
	
EndProcedure

&AtClient
Procedure TasksToDeploy()
	
	For Each TreeRow In ScheduledTransportationJobs.GetItems() Do
		Items.ScheduledTransportationJobs.Expand(TreeRow.GetID());
	EndDo;
	
EndProcedure

&AtClient
Procedure MoveLines(DestinationLineID = Undefined)
	
	ClearMessages();
	
	If DestinationLineID = Undefined Then
		DestinationLineID = Items.ScheduledTransportationJobs.CurrentRow;
	EndIf;
	
	If Items.DeliveryReferences.SelectedRows.Count() = 0 Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chọn lệnh để chuyển tiếp.';
												|ru = 'Не выбраны распоряжения для переноса.';
												|en = 'References for transfer are not selected.'; fa = 'References for transfer are not selected.';
												|it = 'Nessuna disposizione è stato selezionata per il trasferimento.';
												|pl = 'Nie wybrano zamówienia do przenoszenia.';
												|tr = 'Emirler erteleme için seçilmemiş.'"));
		Return
	EndIf;
	
	If ScheduledTransportationJobs.GetItems().Count() > 0 Then
		
		MoveLinesCompletion(DestinationLineID);
		
	Else
		
		Mode = New ValueList; // ValueList of DialogReturnCode
		Mode.Add(DialogReturnCode.Yes, NStr("vi = 'Tạo mới';
											|ru = 'Создать';
											|en = 'Create'; fa = 'ایجاد';
											|it = 'Creare';
											|pl = 'Create';
											|tr = 'Oluştur'"));
		Mode.Add(DialogReturnCode.Cancel);
		Text = NStr("vi = 'Chưa điền danh sách nhiệm vụ đã tạo. Tạo mới nhiệm vụ vận chuyển?';
					|ru = 'Список формируемых заданий не заполнен. Создать задания на перевозку?';
					|en = 'List of generated jobs is not filled in. Generate itineraries?'; fa = 'List of generated jobs is not filled in. Generate itineraries?';
					|it = 'L''elenco dei task in generazione non è compilato. Creare i task di trasporto?';
					|pl = 'Lista formowanych zadań nie jest wypełniona. Utworzyć zadania na przewóz?';
					|tr = 'Oluşturulan işlerin listesi tamamlanmadı. Taşıma planları oluşturulsun mu?'");
		ShowQueryBox(New CallbackDescription("AfterQuestionAboutCreatingJobs", ThisObject), Text, Mode);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionAboutCreatingJobs(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		OpenTransportSelection(True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTransportSelection(MoveOrdersToNewTask = False)
	
	ClearMessages();
	
	AddressOfGeneratedTasks = PutTasksInStorage();
	
	FormParameters = New Structure;
	FormParameters.Insert("DateFilter", DateOfOrders_);
	FormParameters.Insert("AddressOfGeneratedTasks", AddressOfGeneratedTasks);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("TotalWeight_", TotalWeight_);
	FormParameters.Insert("TotalVolume", TotalVolume);
	FormParameters.Insert("JobWillBePerformedBy", FilterByAssigneeType);
	
	CallbackDescription = New CallbackDescription("AfterSelectingTransport",
		ThisObject, New Structure("MoveOrdersToNewTask",MoveOrdersToNewTask));
	OpenForm(ProcessFullName + ".Form.VehicleChoiceForm", FormParameters, ThisObject,,,,
		CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterSelectingTransport(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	AddNewTasksServer(Result);
	
	If AdditionalParameters.MoveOrdersToNewTask
		And ScheduledTransportationJobs.GetItems().Count() > 0 Then
		MoveLinesCompletion(ScheduledTransportationJobs.GetItems()[0].GetID());
	EndIf;
	
EndProcedure

&AtServer
Procedure AddNewTasksServer(AddressOfNewTasksInStorage);
	
	TableOfNewTasks = GetFromTempStorage(AddressOfNewTasksInStorage); // See NewTableOfScheduledTasks
	TableOfNewTasks.Sort("TimeFrom, TimeTo");
	TaskCollection = ScheduledTransportationJobs.GetItems();
	IndexOf = 0;
	FirstAddedLine = True;
	For Each Page1 In TableOfNewTasks Do
		While IndexOf < TaskCollection.Count()
			 And (TaskCollection[IndexOf].TimeFrom < Page1.TimeFrom
				Or (TaskCollection[IndexOf].TimeFrom = Page1.TimeFrom
					 And TaskCollection[IndexOf].TimeTo < Page1.TimeTo)) Do
			IndexOf = IndexOf + 1;
		EndDo;
		newRow_ = TaskCollection.Insert(IndexOf);
		FillPropertyValues(newRow_, Page1);
		newRow_.DeliveryKind   = DeliveryKind;
		newRow_.Warehouse         = Warehouse;
		newRow_.Transport     = Page1.Ref;
		newRow_.ItemModified = True;
		If newRow_.JobIsPerformedBy = Enums.TypesOfTransportationJobAssignees.OurTransportationService Then
			newRow_.ThisIsOurDelivery = 1;
		Else
			newRow_.ThisIsOurDelivery = 0;
		EndIf;
		FillPropertyValues(newRow_, VehicleDetails(Page1.Ref));
		If FirstAddedLine Then
			FirstAddedLine = False;
			Items.ScheduledTransportationJobs.CurrentRow = newRow_.GetID();
		EndIf;
		If Not ValueIsFilled(newRow_.SequenceInRoute) Then
			newRow_.SequenceInRoute = "*";
		EndIf;
	EndDo;
	JobsModified = True;
	FillInDateTransitionSigns();
	Items.ScheduledTransportationJobs.Refresh();
	SetItemsAvailability();
	
EndProcedure

&AtClient
Procedure MoveLinesCompletion(DestinationLineID)
	
	If ScheduledTransportationJobs.GetItems().Count() = 1 Then
		DestinationLineID = ScheduledTransportationJobs.GetItems()[0].GetID();
	EndIf;
	If DestinationLineID = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn dòng đích trong danh sách nhiệm vụ vận chuyển';
										|ru = 'Не выбрана строка назначения в списке заданий на перевозку.';
										|en = 'Assignment line is not selected in the itineraries list.'; fa = 'Assignment line is not selected in the itineraries list.';
										|it = 'Nessuna riga di assegnazione è stata selezionata nell''elenco dei task di spedizione.';
										|pl = 'Nie wybrano wiersz przeznaczenia na liście zadań na transport.';
										|tr = 'Taşıma planları listesindeki hedef satır seçilmedi.'"));
		Return
	EndIf;
	
	OrdersWithSpecialConditions = MoveLinesServer(DestinationLineID);
	NotifyAboutCreatedTasks();
	Items.ScheduledTransportationJobs.Expand(DestinationLineID);
	
	If OrdersWithSpecialConditions.Count() > 0 Then
		FormParameters = New Structure("References", OrdersWithSpecialConditions);
		OpenForm(ProcessFullName + ".Form.WarningForm",	FormParameters, ThisObject);
	EndIf;
	
	TransportTasksScheduledWhenWaitHandlerLineIsActivated();
	
EndProcedure

&AtServer
Procedure UpdateDocumentsForCarriers()
	
	DocumentsForCarriers.Clear();
	If Not ValueIsFilled(Warehouse) Then
		Return;
	EndIf;
	
	Query = New Query(QueryTextDocumentsForCarriers());
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Carrier", Carrier);
	Query.SetParameter("CarrierIsNotFull", Not ValueIsFilled(Carrier));
	Query.SetParameter("StartDate", PeriodOfDocumentsForCarriers.StartDate);
	Query.SetParameter("EndDate", PeriodOfDocumentsForCarriers.EndDate);
	Query.SetParameter("NoStartDate", Not ValueIsFilled(PeriodOfDocumentsForCarriers.StartDate));
	Query.SetParameter("NoEndDate", Not ValueIsFilled(PeriodOfDocumentsForCarriers.EndDate));
	Query.SetParameter("ByCarrierFromWarehouse", Enums.TransportMethods.ByCarrier);
	
	Result = Query.Execute().Unload();
	DocumentsForCarriers.Load(Result);
	
EndProcedure

&AtServer
Function QueryTextDocumentsForCarriers()
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	VALUETYPE(DeliveryReferences.ReferenceOrder) AS DocumentKind,
	|	DeliveryReferences.ReferenceOrder AS Ref,
	|	DeliveryReferences.Date AS Date,
	|	DeliveryReferences.RecipientSender,
	|	DeliveryReferences.Address AS DeliveryAddress,
	|	DeliveryReferences.Carrier AS Carrier,
	|	DeliveryReferences.Number AS Number,
	|	DeliveryReferences.Warehouse AS Warehouse,
	|	CAST(DeliveryReferences.AdditionalInformation AS STRING(1000)) AS AdditionalInformation
	|FROM
	|	InformationRegister.StatesAndDetailsOfDelivery AS DeliveryReferences
	|WHERE
	|	(DeliveryReferences.Carrier = &Carrier
	|			OR &CarrierIsNotFull)
	|	AND DeliveryReferences.DeliveryMethod = &ByCarrierFromWarehouse
	|	AND DeliveryReferences.Warehouse IN HIERARCHY(&Warehouse)
	|	AND (DeliveryReferences.Date <= &EndDate OR &NoEndDate)
	|	AND (DeliveryReferences.Date >= &StartDate OR &NoStartDate)
	| ORDER BY DeliveryReferences.Date";
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure SetColumnHeadersWeightVolumeServer()
	
	TextWeight = NStr("vi = 'Trọng lượng';
						|ru = 'Вес,';
						|en = 'Weight,'; fa = 'Weight,';
						|it = 'Peso,';
						|pl = 'Waga,';
						|tr = 'Ağırlık,'") + " " + UnitOfMeasureForWeight;
	TextVolume = NStr("vi = 'Khối lượng,';
						|ru = 'Объем,';
						|en = 'Volume,'; fa = 'Volume,';
						|it = 'Volume,';
						|pl = 'Objętość,';
						|tr = 'Hacim,'") + " " + UnitOfMeasureForVolume;
	Items.DeliveryReferencesWeight.Title = TextWeight;
	Items.DeliveryReferencesVolumeM3.Title = TextVolume;
	
	Items.ScheduledTransportationJobsWeight.Title = TextWeight;
	Items.ScheduledTransportationJobsVolumeM3.Title = TextVolume;
	
EndProcedure

&AtServer
Function MoveLinesServer(DestinationLineID)
	
	ArrayOfIDOfSelectedRows = Items.DeliveryReferences.SelectedRows;
	AssignmentRow1 = ScheduledTransportationJobs.FindByID(DestinationLineID);
	RowJob = LineTaskByLineItem(AssignmentRow1);
	CurOfMomentTransportationItems = RowJob.GetItems();
	
	If Not TryToBlockGettingLinkByTaskLine(RowJob) Then
		Return New Array;
	EndIf;
	
	If CheckReportTaskChanged(RowJob) Then
		Return New Array;
	EndIf;
	
	RemoveRootLines = DeliveryReferences.GetItems();
	
	ModifiedAddedOrderLines = New Array;
	OrdersWithSpecialConditions = New Array;
	For Each LineID In ArrayOfIDOfSelectedRows Do
		
		CurLineOfOrders = DeliveryReferences.FindByID(LineID);
		
		// If the current row has already been deleted along with the parent
		If CurLineOfOrders = Undefined Then
			Continue;
		EndIf;
		
		TopOfCurBranchOfOrders = CurLineOfOrders.GetParent();
		
		// If there is a parent of this row in the selected rows, we do nothing, the row will be processed together with the parent.
		If TopOfCurBranchOfOrders <> Undefined
				And ArrayOfIDOfSelectedRows.Find(TopOfCurBranchOfOrders.GetID())<>Undefined Then
			Continue;
		EndIf;
		
		If TopOfCurBranchOfOrders = Undefined Then
			CurBranchOrders = CurLineOfOrders.GetItems();
			TopOfCurBranchOfOrders = CurLineOfOrders;
		Else
			CurBranchOrders = TopOfCurBranchOfOrders.GetItems();
		EndIf;
			
		CollectionOfSubordinateStrings = CurLineOfOrders.GetItems();
		
		If CollectionOfSubordinateStrings.Count() = 0 Then
			CollectionOfSubordinateStrings = New Array(1);
			CollectionOfSubordinateStrings[0] = CurLineOfOrders;
			If AreaGroupOrEmpty Then
				CurLineOfOrders.GetParent().Weight = CurLineOfOrders.GetParent().Weight - CurLineOfOrders.Weight;
				CurLineOfOrders.GetParent().VolumeM3 = CurLineOfOrders.GetParent().VolumeM3 - CurLineOfOrders.VolumeM3;
			EndIf;
		EndIf;
		
		TotalWeight_ = TotalWeight_ - CurLineOfOrders.Weight;
		TotalVolume = TotalVolume - CurLineOfOrders.VolumeM3;
		RowJob.Weight = RowJob.Weight + CurLineOfOrders.Weight;
		RowJob.VolumeM3 = RowJob.VolumeM3 + CurLineOfOrders.VolumeM3;
		
		For Each Orders_Row In CollectionOfSubordinateStrings Do
			
			RouteString = Undefined;
			
			// Perhaps the order is already in the task, then a new line is not added
			TheStructureOfTheSearch = New Structure("Ref, Warehouse, ReferenceOrder",
				RowJob.Ref, Orders_Row.Warehouse, Orders_Row.ReferenceOrder);
			FoundRows = Object.ReferencesInDeliveryOrders.FindRows(TheStructureOfTheSearch);
			OrderIsAlreadyInTask = FoundRows.Count() > 0;
			
			If OrderIsAlreadyInTask Then
				
				OrderLineInTasks = FoundRows[0];
				RouteString = RoutePointByKeyLine(RowJob, OrderLineInTasks.ConnectionKey);
				OrderLineInTasks.Weight = OrderLineInTasks.Weight + Orders_Row.Weight;
				OrderLineInTasks.VolumeM3 = OrderLineInTasks.VolumeM3 + Orders_Row.VolumeM3;
				RouteString.Weight = RouteString.Weight + Orders_Row.Weight;
				RouteString.VolumeM3 = RouteString.VolumeM3 + Orders_Row.VolumeM3;
				
			Else
				
				RouteString = GoodsDelivery.AddEditItemByDeliveryDetails(CurOfMomentTransportationItems,
					Orders_Row, RowJob.TimeFrom);
				RouteString.Ref = RowJob.Ref;
				RouteString.DateSwitch = 0;
				
				RowJob.NumberOfReferences = RowJob.NumberOfReferences + 1;
				RouteString.NumberOfReferences = RouteString.NumberOfReferences + 1;
				
			EndIf;
			
			RouteString.ThisIsOurDelivery = 1;
			RouteString.FieldValueAddress = Orders_Row.DeliveryAddressFieldValues;
			
			DetermineIfModified(RouteString, JobsModified);
			ConnectionKey = RouteString.ConnectionKey;
			DestinationLineID = RouteString.GetID();
			
			If Not OrderIsAlreadyInTask Then
				
				OrderLineInTasks = Object.ReferencesInDeliveryOrders.Add();
				FillPropertyValues(OrderLineInTasks, Orders_Row);
				OrderLineInTasks.Ref = RowJob.Ref;
				OrderLineInTasks.ConnectionKey = ConnectionKey;
				OrderLineInTasks.ThisIsInstructionForShippingAgent = (Orders_Row.ReferenceOrder.Metadata() = Metadata.Documents.InstructionForShippingAgent);
				
			EndIf;
			
			ModifiedAddedOrderLines.Add(OrderLineInTasks);
			
			TheStructureOfTheSearch = New Structure("IDInReferenceTree", Orders_Row.GetID());
			LinesOfOrdersWithGoods = ReferenceGoodsToDeliver.FindRows(TheStructureOfTheSearch);
			For Each Page1 In LinesOfOrdersWithGoods Do
				ReadyGoodsForDelivery = GoodsToDeliver.Add();
				FillPropertyValues(ReadyGoodsForDelivery, Page1);
				ReadyGoodsForDelivery.TransportationJob = RowJob.Ref;
				ReferenceGoodsToDeliver.Delete(Page1);
			EndDo;
			
			If Orders_Row.SpecialTransportationConditions Then
				OrdersWithSpecialConditions.Add(Orders_Row.ReferenceOrder);
			EndIf;
		
		EndDo;
		
		If TopOfCurBranchOfOrders = CurLineOfOrders Then
			RemoveRootLines.Delete(CurLineOfOrders);
		Else
			CurBranchOrders.Delete(CurLineOfOrders);
			// If we deleted the last element in the branch, we will delete the parent
			If CurBranchOrders.Count() = 0 Then
				RemoveRootLines.Delete(TopOfCurBranchOfOrders);
			EndIf;
		EndIf;
		
	EndDo;
	
	RenumberAndFillInDateTransitionSignsInTaskList(DestinationLineID);
	FillInWarehousesForItemsAndTasks(True);
	GoodsDelivery.FillInSignsOfExecutionOfOrders(DeliveryReferences, AreaGroupOrEmpty);
	Items.ScheduledTransportationJobs.CurrentRow = DestinationLineID;
	SetItemsAvailability();
	
	GoodsDelivery.ThisAttributeIsDeliveredInFull(GoodsToDeliver.Unload((New Structure("TransportationJob",RowJob.Ref))),
		Object.ReferencesInDeliveryOrders, ModifiedAddedOrderLines);
	SaveTaskInLine(RowJob);
	
	Return OrdersWithSpecialConditions;
	
EndFunction

&AtServer
Function CheckReportTaskChanged(RowJob)
	
	NewJob = Not ValueIsFilled(RowJob.Ref)
		Or Not Common.RefExists(RowJob.Ref);
	If Not NewJob Then
		DocumentDataVersion = Common.ObjectAttributeValue(RowJob.Ref, "DataVersion");
		If DocumentDataVersion <> RowJob.DataVersion Then
			Text = NStr("vi = 'Không thể thay đổi %Job%, bởi vì phiên bản của chứng từ khác với dự kiến. Nên cập nhật danh sách.';
						|ru = 'Не удалось внести изменения в %Job%, т.к. версия документа отличается от ожидаемой. Рекомендуется обновить список.';
						|en = 'Cannot edit %Job% as the document does not have the expected version. Refresh the list.'; fa = 'Cannot edit %Job% as the document does not have the expected version. Refresh the list.';
						|it = 'Non è stato possibile apportare modifiche a %Job%, poiché la versione del documento è diversa da quella prevista. Si consiglia di aggiornare l''elenco.';
						|pl = 'Nie udało się wprowadzić zmiany do %Job%, ponieważ wersja dokumentu różni się od oczekiwanej. Zaleca się odświeżyć listę.';
						|tr = '%Job% üzerinde değişiklik yapılamadı çünkü belgenin sürümü istenen sürümden farklıdır. Listenin güncellenmesi tavsiye edilir.'");
			Text = StrReplace(Text,"%Job%", RowJob.Ref);
			Common.MessageToUser(Text, RowJob.Ref);
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function RoutePointByKeyLine(CurrentRow, ConnectionKey)
	RowJob = LineTaskByLineItem(CurrentRow);
	For Each Page1 In RowJob.GetItems() Do
		If Page1.ConnectionKey = ConnectionKey Then
			Return Page1;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure FillInWarehousesForItemsAndTasks(ConsiderModifiability = False);
	
	QueryText =
	"SELECT DISTINCT
	|	ReferencesInDeliveryOrders.Warehouse,
	|	ReferencesInDeliveryOrders.ReferenceOrder,
	|	ReferencesInDeliveryOrders.ConnectionKey,
	|	ReferencesInDeliveryOrders.Ref
	|INTO ReferencesInDeliveryOrders
	|FROM
	|	&ReferencesInDeliveryOrders AS ReferencesInDeliveryOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	COUNT(DISTINCT WarehousesByItem.Warehouse) AS NumberOfWarehouses,
	|	MAX(WarehousesByItem.Warehouse) AS Warehouse,
	|	WarehousesByItem.ConnectionKey,
	|	WarehousesByItem.Ref
	|FROM
	|	ReferencesInDeliveryOrders AS WarehousesByItem
	|
	|GROUP BY
	|	WarehousesByItem.ConnectionKey,
	|	WarehousesByItem.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	COUNT(DISTINCT WarehousesByTask.Warehouse) AS NumberOfWarehouses,
	|	MAX(WarehousesByTask.Warehouse) AS Warehouse,
	|	WarehousesByTask.Ref
	|FROM
	|	ReferencesInDeliveryOrders AS WarehousesByTask
	|
	|GROUP BY
	|	WarehousesByTask.Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("ReferencesInDeliveryOrders",
		Object.ReferencesInDeliveryOrders.Unload(,"Warehouse, ReferenceOrder, ConnectionKey, Ref"));
	Result = Query.ExecuteBatch();
	WarehousesByItem = Result[1].Unload();
	WarehousesByTask = Result[2].Unload();
	For Each RowJob In ScheduledTransportationJobs.GetItems() Do
		If ConsiderModifiability
			And Not RowJob.ItemModified Then
			Continue
		EndIf;
		TaskWarehouses = WarehousesByTask.Find(RowJob.Ref, "Ref");
		If TaskWarehouses = Undefined Then
			Continue;
		EndIf;
		NumberOfWarehouses = TaskWarehouses.NumberOfWarehouses;
		If NumberOfWarehouses = 1
			And ValueIsFilled(TaskWarehouses.Warehouse)
			And RowJob.Warehouse <> TaskWarehouses.Warehouse Then
			RowJob.Warehouse = TaskWarehouses.Warehouse;
			DetermineIfModified(RowJob, JobsModified);
		ElsIf RowJob.Warehouse <> Warehouse Then
			// We take the warehouse from the header
			RowJob.Warehouse = Warehouse;
			DetermineIfModified(RowJob, JobsModified);
		EndIf;
		
		For Each LineItem In RowJob.GetItems() Do
			If ConsiderModifiability
				And Not LineItem.ItemModified Then
				Continue
			EndIf;
			PointWarehouses = WarehousesByItem.Find(LineItem.ConnectionKey, "ConnectionKey");
			NumberOfWarehouses = PointWarehouses.NumberOfWarehouses;
			If NumberOfWarehouses = 1 Then
				LineItem.Warehouse = PointWarehouses.Warehouse;
			Else
				Text = NStr("vi = '%NumberOfWarehouses% bốc hàng';
							|ru = '%NumberOfWarehouses% погрузки';
							|en = '%NumberOfWarehouses% of lading'; fa = '%NumberOfWarehouses% of lading';
							|it = '%NumberOfWarehouses% del carico';
							|pl = '%NumberOfWarehouses% załadunku';
							|tr = '%NumberOfWarehouses% yükleniyor'");
				Text = StrReplace(Text, "%NumberOfWarehouses%",
					StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(NumberOfWarehouses,
						NStr("vi = 'một kho bãi, hai kho bãi, nhiều kho';
							|ru = 'склад, склада, складов';
							|en = 'warehouse, warehouse, warehouses'; fa = 'warehouse, warehouse, warehouses';
							|it = 'magazzino, del magazzino, dei magazzini';
							|pl = 'magazyn, magazynu, magazynów';
							|tr = 'depo, depo, depolar'")));
				LineItem.Warehouse = Text;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

&AtServer
Procedure FillInDateTransitionSigns(DestinationLineID = Undefined)
	
	CurBranch		= Undefined;
	CurrentJob	= Undefined;
	
	If ValueIsFilled(DestinationLineID) Then
		CurRow = ScheduledTransportationJobs.FindByID(DestinationLineID);
		CurrentJob = ?(CurRow.GetParent() = Undefined, CurRow, CurRow.GetParent());
	EndIf;
	
	TransportTaskLines = ScheduledTransportationJobs.GetItems();	
	
	If TransportTaskLines.Count() = 0 Then
		Return
	EndIf;
	
	PreDateWith = TransportTaskLines[0].TimeFrom + 60 * 60 * 24;
	
	For Each Page1 In TransportTaskLines Do
		
		If CurrentJob <> Undefined And CurrentJob <> Page1 Then	
			Continue;		
		EndIf;
		
		If BegOfDay(Page1.TimeFrom) <> BegOfDay(PreDateWith) Then
			
			If BegOfDay(Page1.TimeFrom) <> BegOfDay(Page1.TimeTo) Then
				Page1.DateSwitch = 3;
			Else
				Page1.DateSwitch = 1;
			EndIf;
				
		Else
			
			If BegOfDay(Page1.TimeFrom) <> BegOfDay(Page1.TimeTo) Then
				Page1.DateSwitch = 2;
			Else
				Page1.DateSwitch = 0;
			EndIf;
			
		EndIf;
		
		PreDateWith = Page1.TimeFrom;
		
		For Each NestedRow In Page1.GetItems() Do
			
			If BegOfDay(NestedRow.TimeFrom) <> BegOfDay(PreDateWith) Then
				
				If BegOfDay(NestedRow.TimeFrom) <> BegOfDay(NestedRow.TimeTo) Then
					NestedRow.DateSwitch = 3;
				Else
					NestedRow.DateSwitch = 1;
				EndIf;
				
			Else
				
				If BegOfDay(NestedRow.TimeFrom) <> BegOfDay(NestedRow.TimeTo) Then
					NestedRow.DateSwitch = 2;
				Else
					NestedRow.DateSwitch = 0;
				EndIf;
				
			EndIf;
			
			PreDateWith = NestedRow.TimeFrom;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RefreshTaskGenerationPage()
	
	ScheduledTransportationJobs.GetItems().Clear();
	Object.ReferencesInDeliveryOrders.Clear();
	DeliveryReferences.GetItems().Clear();
	TotalWeight_ = 0;
	TotalVolume = 0;
	
	If Not ValueIsFilled(Warehouse) Then
		Return;
	EndIf;
	
	Query = New Query;
	
	Query.Text = 
	"SELECT ALLOWED
	|	TransportationJob.Number AS JobNumber,
	|	TransportationJob.Warehouse AS Warehouse,
	|	TransportationJob.Ref AS Ref,
	|	TransportationJob.DataVersion AS DataVersion,
	|	TransportationJob.Carrier AS Carrier,
	|	TransportationJob.Counterparty AS Counterparty,
	|	TransportationJob.CarrierBankAccount AS CarrierBankAccount,
	|	TransportationJob.JobIsPerformedBy AS JobIsPerformedBy,
	|	CASE
	|		WHEN TransportationJob.JobIsPerformedBy = VALUE(Enum.TypesOfTransportationJobAssignees.OurTransportationService)
	|			THEN 1
	|		ELSE 0
	|	END AS ThisIsOurDelivery,
	|	TransportationJob.PlanTripStartTime AS PlanTripStartTime,
	|	TransportationJob.PlanTripEndTime AS PlanTripEndTime,
	|	TransportationJob.Vehicle_ AS Transport,
	|	TransportationJob.Vehicle_.CapacityPresentation AS CapacityPresentation,
	|	TransportationJob.AdditionalInformation AS AdditionalInformationTask,
	|	TransportationJob.Vehicle_.CarryingCapacityInTons / &TonConversionFactor AS CarryingCapacityInUserUnit,
	|	TransportationJob.Vehicle_.CapacityInCubicMeters / &CubicMeterConversionFactor AS CapacityInUserUnits,
	|
	|	TaskForTransportationRoute.Address AS Address,
	|	TaskForTransportationRoute.FieldValueAddress AS FieldValueAddress,
	|	TaskForTransportationRoute.Zone AS Zone,
	|	TaskForTransportationRoute.Weight AS Weight,
	|	TaskForTransportationRoute.VolumeM3 AS VolumeM3,
	|	TaskForTransportationRoute.TimeFrom AS TimeFrom,
	|	TaskForTransportationRoute.TimeTo AS TimeTo,
	|	TaskForTransportationRoute.AdditionalInformation AS AdditionalInformation,
	|	TaskForTransportationRoute.LineNumber AS SequenceInRoute,
	|	TaskForTransportationRoute.ConnectionKey AS ConnectionKey,
	|
	|	TransportationTask.Warehouse AS ReferenceWarehouse,
	|	TransportationTask.ReferenceOrder AS ReferenceOrder,
	|	TransportationTask.ReferenceOrder REFS Document.InstructionForShippingAgent AS ThisIsInstructionForShippingAgent,
	|	TransportationTask.Weight AS WeightOrder,
	|	TransportationTask.VolumeM3 AS OrderVolume,
	|	TransportationTask.RecipientSender AS RecipientSender,
	|	TransportationTask.Carrier AS OrderCarrier,
	|	TransportationTask.TimeFrom AS AllTimesWith,
	|	TransportationTask.TimeTo AS CurrentSoftwareTime,
	|	TransportationTask.AdditionalInformation AS OrderAdditionalInformation,
	|	TransportationTask.DeliveredInFull AS DeliveredInFull
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|		LEFT JOIN Document.TransportationJob.Route AS TaskForTransportationRoute
	|			INNER JOIN Document.TransportationJob.References AS TransportationTask
	|			ON TaskForTransportationRoute.Ref = TransportationTask.Ref
	|			AND TaskForTransportationRoute.ConnectionKey = TransportationTask.ConnectionKey
	|		ON (TaskForTransportationRoute.Ref = TransportationJob.Ref)
	|		
	|WHERE
	|	TransportationJob.Posted
	|	AND TransportationJob.Status = VALUE(Enum.StatusesOfTransportationJobs.BeingGenerated)
	|	AND TransportationJob.Warehouse IN HIERARCHY(&Warehouse)
	|	AND TransportationJob.Operation = &DeliveryKind
	|	AND CASE
	|			WHEN &FilterByAssigneeType = VALUE(Enum.TypesOfTransportationJobAssignees.EmptyRef)
	|				THEN TRUE
	|			ELSE TransportationJob.JobIsPerformedBy = &FilterByAssigneeType
	|		END
	|
	|ORDER BY
	|	PlanTripStartTime,
	|	PlanTripEndTime,
	|	Ref,
	|	SequenceInRoute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsToDeliver.TransportationJob,
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Warehouse,
	|	GoodsToDeliver.Products,
	|	GoodsToDeliver.Characteristic,
	|	GoodsToDeliver.Purpose,
	|	GoodsToDeliver.Series,
	|	GoodsToDeliver.Count,
	|	GoodsToDeliver.AllGoods,
	|	GoodsToDeliver.RecipientSender
	|FROM
	|	InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|		INNER JOIN Document.TransportationJob AS Job
	|		ON (Job.Ref = GoodsToDeliver.TransportationJob)
	|			AND (Job.Posted)
	|			AND (Job.Status = VALUE(Enum.StatusesOfTransportationJobs.BeingGenerated))
	|			AND (Job.Warehouse IN HIERARCHY (&Warehouse))
	|			AND (GoodsToDeliver.TransportationJob.Operation = &DeliveryKind)
	|			AND (CASE
	|				WHEN &FilterByAssigneeType = VALUE(Enum.TypesOfTransportationJobAssignees.EmptyRef)
	|					THEN TRUE
	|				ELSE GoodsToDeliver.TransportationJob.JobIsPerformedBy = &FilterByAssigneeType
	|			END)";
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("TonConversionFactor", GoodsDelivery.TonConversionFactor());
	Query.SetParameter("CubicMeterConversionFactor", GoodsDelivery.CubicMeterConversionFactor());
	Query.SetParameter("DeliveryKind", DeliveryKind);
	Query.SetParameter("FilterByAssigneeType", FilterByAssigneeType);
	Result = Query.ExecuteBatch();
	
	Selection = Result[0].Select();
	While Selection.NextByFieldValue("Ref") Do
		
		RowJob = ScheduledTransportationJobs.GetItems().Add();
		FillPropertyValues(RowJob, Selection);
		
		RowJob.SequenceInRoute 	= ObjectsPrefixesClientServer.NumberForPrinting(Selection.JobNumber, True, True);
		RowJob.TimeFrom 			= Selection.PlanTripStartTime;
		RowJob.TimeTo 			= Selection.PlanTripEndTime;
		RowJob.TimeFromWithoutDate 	= GoodsDeliveryClientServer.TimeWithoutDate(RowJob.TimeFrom);
		RowJob.TimeToWithoutDate 	= GoodsDeliveryClientServer.TimeWithoutDate(RowJob.TimeTo);
		RowJob.AdditionalInformation = Selection.AdditionalInformationTask;
		RowJob.Weight 				= 0;
		RowJob.VolumeM3 			= 0;
		RowJob.ConnectionKey 		= "";
		RowJob.DeliveryKind 		= DeliveryKind;
		
		PreviousZone = Selection.Zone;
		ZoneHasChanged = False;
		
		While Selection.NextByFieldValue("SequenceInRoute")
			And ValueIsFilled(Selection.ConnectionKey) Do
			
			LineItem = RowJob.GetItems().Add();
			FillPropertyValues(LineItem, Selection);
			LineItem.TimeFromWithoutDate   = GoodsDeliveryClientServer.TimeWithoutDate(LineItem.TimeFrom);
			LineItem.TimeToWithoutDate  = GoodsDeliveryClientServer.TimeWithoutDate(LineItem.TimeTo);
			RowJob.Weight = RowJob.Weight + LineItem.Weight;
			RowJob.VolumeM3 = RowJob.VolumeM3 + LineItem.VolumeM3;
			ZoneHasChanged = Max(ZoneHasChanged, PreviousZone <> Selection.Zone);
			LineItem.ThisIsOurDelivery = 1;
			
			While Selection.Next() Do
				
				CommandLine_ = Object.ReferencesInDeliveryOrders.Add();
				FillPropertyValues(CommandLine_, Selection);
				CommandLine_.Warehouse      = Selection.ReferenceWarehouse;
				CommandLine_.Weight        = Selection.WeightOrder;
				CommandLine_.VolumeM3      = Selection.OrderVolume;
				CommandLine_.Carrier = Selection.OrderCarrier;
				CommandLine_.TimeFrom     = Selection.AllTimesWith;
				CommandLine_.TimeTo    = Selection.CurrentSoftwareTime;
				CommandLine_.AdditionalInformation = Selection.OrderAdditionalInformation;
	
				LineItem.NumberOfReferences = LineItem.NumberOfReferences + 1;
				
			EndDo;
			
			RowJob.NumberOfReferences = RowJob.NumberOfReferences + LineItem.NumberOfReferences;
			
		EndDo;
		
		If ZoneHasChanged Then
			RowJob.Zone = Catalogs.DeliveryZones.EmptyRef();
		EndIf;
		
	EndDo;
	
	FillInDateTransitionSigns();
	
	GoodsToDeliver.Load(Result[1].Unload());
	
	FillInWarehousesForItemsAndTasks(True);
	
	GoodsDelivery.UpdateListOfDeliveryOrders(ThisObject);
	
	JobsModified = False;
	SetItemsAvailability();
	
EndProcedure

&AtServer
Procedure SaveTasksToAnotherServer(TaskLinesThatAreMarkedForDeletion = Undefined)
	
	If JobsModified Then
		For Each Page1 In ScheduledTransportationJobs.GetItems() Do
			MarkToDelete = False;
			If Page1.ItemModified Then
				NewJob = Not ValueIsFilled(Page1.Ref);
				If TaskLinesThatAreMarkedForDeletion <> Undefined
					And TaskLinesThatAreMarkedForDeletion.Find(Page1) <> Undefined Then
					MarkToDelete = True;
				EndIf;
				SaveTaskInLine(Page1, MarkToDelete);
				If NewJob And ValueIsFilled(Page1.Ref) Then
					NewJobs.Add(Page1.Ref);
				EndIf;
			EndIf;
		EndDo;
		JobsModified = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveTaskInLine(RowJob, MarkToDelete = False)
	
	If RowJob = Undefined Then
		RowJob = LineTaskByLineItem(ScheduledTransportationJobs.FindByID(Items.ScheduledTransportationJobs.CurrentRow));
	EndIf;
	
	If Not RowJob.ItemModified Then
		Return;
	EndIf;
	TaskID = RowJob.GetID();
	NewJob = Not ValueIsFilled(RowJob.Ref)
		Or Not Common.RefExists(RowJob.Ref);
	
	If NewJob Then
		DocObject = Documents.TransportationJob.CreateDocument();
		If ValueIsFilled(RowJob.Ref) Then
			DocObject.SetNewObjectRef(RowJob.Ref);
		EndIf;
		DocObject.Fill(Undefined);
		DocObject.Date		= CurrentSessionDate();
		DocObject.Priority = SettingsValueCached.GetDefaultPriority(DocObject.Priority);
		DocObject.Status	= Enums.StatusesOfTransportationJobs.BeingGenerated;
		DocObject.Operation  = RowJob.DeliveryKind;
	Else
		Try
			DocObject = RowJob.Ref.GetObject();
			If CheckReportTaskChanged(RowJob) Then
				// It is expected that the user will receive an error message and click the "Update list" button.
				// When the list is updated, tasks are recorded with a sign of modification. For this reason
				// , the sign of modification is removed from the task that cannot be recorded.
				DetermineIfModified(RowJob, JobsModified, False);
				Return;
			EndIf;
			DocObject.Lock();
		Except
			Text = NStr("vi = 'Không thể chặn %Job% cho các thay đổi.';
						|ru = 'Не удалось заблокировать %Job% для изменений.';
						|en = 'Cannot lock %Job% for editing.'; fa = 'Cannot lock %Job% for editing.';
						|it = 'Impossibile bloccare %Job% per le modifiche.';
						|pl = 'Nie udało się zablokować %Job% do zmian.';
						|tr = '%Job% değişimi engellenemedi.'");
			Text = StrReplace(Text,"%Job%", DocObject.Ref);
			Common.MessageToUser(Text, DocObject.Ref);
			Return;
		EndTry;
	EndIf;
	
	DocObject.Vehicle_      = RowJob.Transport;
	DocObject.PlanTripStartTime       = RowJob.TimeFrom;
	DocObject.PlanTripEndTime      = RowJob.TimeTo;
	DocObject.AdditionalInformation  = RowJob.AdditionalInformation;
	DocObject.Carrier                = RowJob.Carrier;
	DocObject.Counterparty                = RowJob.Counterparty;
	DocObject.CarrierBankAccount = RowJob.CarrierBankAccount;
	DocObject.JobIsPerformedBy          = RowJob.JobIsPerformedBy;
	DocObject.Status                    = Enums.StatusesOfTransportationJobs.BeingGenerated;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Vehicles.Code AS VehicleRegPlate,
	|	Vehicles.Brand AS VehicleModel,
	|	Vehicles.TransportationType AS TransportationType,
	|	Vehicles.Type AS VehicleType,
	|	Vehicles.CapacityInCubicMeters AS VehicleCubicMetresCapacity,
	|	Vehicles.CarryingCapacityInTons AS VehicleCarryingCapacityInTons,
	|	Vehicles.LicenseCardKind AS LicenseCardKind,
	|	Vehicles.LicenseCardNumber AS LicenseCardNumber,
	|	Vehicles.RegistrationNumberOfLicenseCard AS RegistrationNumberOfLicenseCard,
	|	Vehicles.LicenseCardSeries AS LicenseCardSeries,
	|	Vehicles.Trailer AS Trailer,
	|	Vehicles.TrailerRegPlate AS TrailerRegPlate
	|FROM
	|	Catalog.Vehicles AS Vehicles
	|WHERE
	|	Vehicles.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VehicleTypes.Description,
	|	VehicleTypes.CapacityInCubicMeters,
	|	VehicleTypes.CarryingCapacityInTons,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	Catalog.VehicleTypes AS VehicleTypes
	|WHERE
	|	VehicleTypes.Ref = &Ref";
	Query.SetParameter("Ref", RowJob.Transport);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FillPropertyValues(DocObject, Selection);
	EndIf;
	
	If TypeOf(RowJob.Warehouse) = Type("String")
		Or Common.ObjectAttributeValue(RowJob.Warehouse,"IsFolder") = True Then
		DocObject.Warehouse = Warehouse;
	Else
		DocObject.Warehouse = RowJob.Warehouse;
	EndIf;
	DocObject.Route.Clear();
	For Each TaskItem In RowJob.GetItems() Do
		TSRow = DocObject.Route.Add();
		FillPropertyValues(TSRow, TaskItem);
	EndDo;
	
	DocObject.References.Load(Object.ReferencesInDeliveryOrders.Unload(New Structure("Ref",RowJob.Ref)));
	
	DocObject.AdditionalProperties.Insert("GoodsToDeliver", GoodsToDeliver.Unload((New Structure("TransportationJob",RowJob.Ref))));
	
	If MarkToDelete Then
		DocObject.DeletionMark = True;
		DocObject.Write(DocumentWriteMode.UndoPosting);
	Else
		DocObject.Write(DocumentWriteMode.Posting);
	EndIf;
	
	If NewJob Then
		UserWorkHistory.Add(DocObject.Ref);
	EndIf;
	DocObject.Unlock();
	
	RowJob.SequenceInRoute	= ObjectsPrefixesClientServer.NumberForPrinting(Common.ObjectAttributeValue(DocObject.Ref, "Number"), True, True);
	RowJob.Ref            = DocObject.Ref;
	RowJob.DataVersion      = DocObject.DataVersion;
	RowJob.ItemModified		= False;
	
EndProcedure

&AtClient
Procedure TransportTasksScheduledWhenWaitHandlerLineIsActivated()
	
	ItemLine = Items.ScheduledTransportationJobs.CurrentData;
	
	If ItemLine = Undefined Then
		GoodsDeliveryClientServer.DisplayUnderloadOverload(ThisObject, Undefined);
	Else
		GoodsDeliveryClientServer.DisplayUnderloadOverload(ThisObject, LineTaskByLineItem(ItemLine));
	EndIf;
	
	If ItemLine = Undefined
		Or ItemLine.NumberOfReferences = 0 Then
		Items.PageReferences.CurrentPage = Items.PageNoReferences;
	Else
		Items.PageReferences.CurrentPage = Items.PageThereAreReferences;
		Text = NStr("vi = 'Lệnh (%Count%)';
					|ru = 'Распоряжения (%Count%)';
					|en = 'References (%Count%)'; fa = 'References (%Count%)';
					|it = 'Disposizioni (%Count%)';
					|pl = 'Zamówienia (%Count%)';
					|tr = 'Emirler (%Count%)'");
		LabelReferences = StrReplace(Text, "%count%", ItemLine.NumberOfReferences);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfWarehouses()
	
	VisibilityFlag = Warehouse.IsEmpty() Or Common.ObjectAttributeValue(Warehouse,"IsFolder");
	Items.DeliveryReferencesWarehouse.Visible			 = VisibilityFlag;
	Items.TransportationJobsInProgressWarehouse.Visible		 = VisibilityFlag;
	Items.DocumentsForCarriersWarehouse.Visible		 = VisibilityFlag;
	
EndProcedure	

&AtServer
Procedure SetSelectionOfTaskForTransportationInWork()
	
	If Status = "AllInProgress" Then
		CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
			"Status", Enums.StatusesOfTransportationJobs.Closed, DataCompositionComparisonType.NotEqual,,True);
	ElsIf ValueIsFilled(Status) Then
		CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
			"Status", Enums.StatusesOfTransportationJobs[Status], DataCompositionComparisonType.Equal,,True);
	ElsIf Not ValueIsFilled(Status) Then
		CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
			"Status",,,,False);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
		"Posted", True, DataCompositionComparisonType.Equal,,ValueIsFilled(Status));
	
	If ValueIsFilled(Warehouse) Then
		CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
			"Warehouse", Warehouse, DataCompositionComparisonType.InHierarchy,,True);
	Else
		CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
			"Warehouse", Warehouse, DataCompositionComparisonType.Equal,,True);
	EndIf;
	
	If AreaGroupOrEmpty Then
		CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
			"Zone", Zone, DataCompositionComparisonType.InHierarchy,,ValueIsFilled(Zone));
	Else
		CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
			"Zone", Zone, DataCompositionComparisonType.Equal,,True);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
			"JobIsPerformedBy", FilterByAssigneeType, DataCompositionComparisonType.Equal,,ValueIsFilled(FilterByAssigneeType));
	
	CommonClientServer.SetDynamicListFilterItem(TransportationJobsInProgress,
		"Operation", DeliveryKind, DataCompositionComparisonType.Equal,,True);
	
EndProcedure

&AtClient
Procedure RemoveLinesFromJobsClient(SourceInvoices = False, MarkTasksForDeletion_ = False)
	RemoveLinesFromJobsServer(SourceInvoices, MarkTasksForDeletion_);
	TransportTasksScheduledWhenWaitHandlerLineIsActivated();
	DeliveryOrdersWhenWaitHandlerLineIsActivated();
EndProcedure

&AtServer
Procedure RemoveLinesFromJobsServer(SourceInvoices, MarkTasksForDeletion_)
	
	OrdersThatAreDeletedFromTasks = TableUpdatedOrders();
	
	TaskLinesThatAreMarkedForDeletion = New Array;
	
	For Each ID In Items.ScheduledTransportationJobs.SelectedRows Do
		
		CurrentRow = ScheduledTransportationJobs.FindByID(ID);
		
		If CurrentRow = Undefined Then
			Continue; //This line has already been deleted when transferring the parent line
		EndIf;
		
		TotalWeight_ = TotalWeight_ + CurrentRow.Weight;
		TotalVolume = TotalVolume + CurrentRow.VolumeM3;
		
		If CurrentRow.GetParent() = Undefined Then
			RowJob = CurrentRow;
			If Not TryToBlockGettingLinkByTaskLine(RowJob) Then
				Return;
			EndIf;
			DetermineIfModified(CurrentRow, JobsModified);
			Branch1 = RowJob.GetItems();
			For Each LineItem In Branch1 Do
				
				For Each CommandLine_ In Object.ReferencesInDeliveryOrders.FindRows(New Structure("ConnectionKey",LineItem.ConnectionKey)) Do
					LineToUpdate = OrdersThatAreDeletedFromTasks.Add();
					FillPropertyValues(LineToUpdate, CommandLine_);
					Object.ReferencesInDeliveryOrders.Delete(CommandLine_);
				EndDo;
				
			EndDo;
			Branch1.Clear();
			RowJob.Weight = 0;
			RowJob.VolumeM3 = 0;
			
			JobModified = CheckReportTaskChanged(RowJob);
			
			If MarkTasksForDeletion_
				And ValueIsFilled(RowJob.Ref)
				And Not JobModified Then
				TaskLinesThatAreMarkedForDeletion.Add(RowJob);
			EndIf;
			
			If Not ValueIsFilled(CurrentRow.Ref) Then
				ScheduledTransportationJobs.GetItems().Delete(CurrentRow);
			EndIf;
			
			ProductsByTask = GoodsToDeliver.FindRows(New Structure("TransportationJob",RowJob.Ref));
			For Each LineProducts_ In ProductsByTask Do
				GoodsToDeliver.Delete(LineProducts_);
			EndDo;
			RowJob.NumberOfReferences = 0;
			
		Else
			
			LineItem = CurrentRow;
			RowJob = LineItem.GetParent();
			JobModified = CheckReportTaskChanged(RowJob);
			If Not TryToBlockGettingLinkByTaskLine(RowJob)
				Or JobModified Then
				Return;
			EndIf;
			DetermineIfModified(CurrentRow, JobsModified);
			
			Branch1 = RowJob.GetItems();
			For Each CommandLine_ In Object.ReferencesInDeliveryOrders.FindRows(New Structure("ConnectionKey",LineItem.ConnectionKey)) Do
				LineToUpdate = OrdersThatAreDeletedFromTasks.Add();
				FillPropertyValues(LineToUpdate, CommandLine_);
				GoodsByOrder = GoodsToDeliver.FindRows(New Structure("TransportationJob,ReferenceOrder,Warehouse",CommandLine_.Ref, CommandLine_.ReferenceOrder, CommandLine_.Warehouse));
				For Each LineProducts_ In GoodsByOrder Do
					GoodsToDeliver.Delete(LineProducts_);
				EndDo;
				Object.ReferencesInDeliveryOrders.Delete(CommandLine_);
			EndDo;
			
			RowJob.Weight = RowJob.Weight - LineItem.Weight;
			RowJob.VolumeM3 = RowJob.VolumeM3 - LineItem.VolumeM3;
			
			RowJob.NumberOfReferences = RowJob.NumberOfReferences - LineItem.NumberOfReferences;
			
			Branch1.Delete(LineItem);
			
		EndIf;
		
	EndDo;
	
	SaveTasksToAnotherServer(TaskLinesThatAreMarkedForDeletion);
	
	For Each Page1 In TaskLinesThatAreMarkedForDeletion Do
		ScheduledTransportationJobs.GetItems().Delete(Page1);
	EndDo;
	
	GoodsDelivery.UpdateListOfDeliveryOrders(ThisObject, OrdersThatAreDeletedFromTasks);
	
	RenumberAndFillInDateTransitionSignsInTaskList();
	FillInWarehousesForItemsAndTasks(True);
	SetItemsAvailability();
	
EndProcedure

&AtServerNoContext
Function TableUpdatedOrders(CommandLine_ = Undefined)
	
	UpdatedOrders = New ValueTable;
	UpdatedOrders.Columns.Add("ReferenceOrder", Metadata.DefinedTypes.DeliveryReferenceOrder.Type);
	UpdatedOrders.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	If CommandLine_ <> Undefined Then
		NewRow = UpdatedOrders.Add();
		FillPropertyValues(NewRow, CommandLine_);
	EndIf;
	
	Return UpdatedOrders;
	
EndFunction

// Returns:
// 	ValueTable - Where:
// 		* Ref - DocumentRef.TransportationJob
// 		* Transport - CatalogRef.Vehicles
// 		* Status - EnumRef.StatusesOfTransportationJobs
// 		* TimeFrom - Date
// 		* TimeTo - Date
&AtServer
Function NewTableOfScheduledTasks()
	
	Result = New ValueTable();
	Result.Columns.Add("Ref", New TypeDescription("DocumentRef.TransportationJob"));
	Result.Columns.Add("Transport", New TypeDescription("CatalogRef.Vehicles"));
	Result.Columns.Add("Status", New TypeDescription("EnumRef.StatusesOfTransportationJobs"));
	Result.Columns.Add("TimeFrom", New TypeDescription("Date"));
	Result.Columns.Add("TimeTo", New TypeDescription("Date"));
	
	Return Result;
	
EndFunction

&AtServer
Function PutTasksInStorage()
	
	TableOfScheduledTasks = NewTableOfScheduledTasks();
	
	For Each Job In ScheduledTransportationJobs.GetItems() Do
		If TypeOf(Job.Transport) = Type("CatalogRef.Vehicles") Then
			Page1 = TableOfScheduledTasks.Add();
			FillPropertyValues(Page1, Job);
		EndIf;
	EndDo;
	TableOfScheduledTasks.FillValues(Enums.StatusesOfTransportationJobs.BeingGenerated,"Status");
	TableOfScheduledTasks.Columns.Transport.Name = "Vehicle_";
	Return PutToTempStorage(TableOfScheduledTasks, UUID);

EndFunction

&AtServer
Function PutItInStorage(SelectionKey)
	If TypeOf(SelectionKey) = Type("DocumentRef.TransportationJob") Then
		StructureSearch = New Structure("Ref", SelectionKey);
	Else
		StructureSearch = New Structure("ConnectionKey", SelectionKey);
	EndIf;
	InstructionsForSelection = Object.ReferencesInDeliveryOrders.Unload(StructureSearch);
	Return PutToTempStorage(InstructionsForSelection, UUID);

EndFunction

&AtClient
Procedure CheckSetDragAndDropValidity(Item, DragParameters)
	
	DragParameters.Action = DragAction.Cancel;
	If StartedMoving
			And TypeOf(DragParameters.Value) = Type("Array")
			And DragParameters.Value.Count() > 0 Then
		If Item = Items.ScheduledTransportationJobs 
			And TypeOf(DragParameters.Value[0]) = Type("Number") Then
			DragParameters.Action = DragAction.Move;
		ElsIf ((TypeOf(DragParameters.Value[0]) = Type("FormDataCollectionItem")
					Or TypeOf(DragParameters.Value[0]) = Type("FormDataTreeItem"))) Then
			TaskSource = DragParameters.Value[0].Property("DateSwitch");
			SourceInvoicesInTasks = DragParameters.Value[0].Property("ConnectionKey");
			SourceOfOrder = ((Not DragParameters.Value[0].Property("DateSwitch"))
								And (Not DragParameters.Value[0].Property("ConnectionKey")));
			If (Item = Items.DeliveryReferences And (TaskSource Or SourceInvoicesInTasks))
				Or (Item = Items.ScheduledTransportationJobs And SourceOfOrder)
				Or (Item = Items.ScheduledTransportationJobs And TaskSource)
				Then
				DragParameters.Action = DragAction.Move;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateListsForCurPage()
	
	DetachIdleHandler("CheckingIfYouNeedToRecalculateTotalsForDeliveryOrdersWaitingHandler");
	
	SaveTasksUpdateLists();
	If Items.MainPages.CurrentPage = Items.CreatingTransportationTasksPage Then
		ExpandOrders();
		TasksToDeploy();
		AttachIdleHandler("CheckingIfYouNeedToRecalculateTotalsForDeliveryOrdersWaitingHandler",1.3,False);
	EndIf;
	NotifyAboutCreatedTasks();
	
EndProcedure

&AtServer
Procedure SaveTasksUpdateLists()
	
	SaveTasksToAnotherServer();
	
	If Items.MainPages.CurrentPage = Items.CreatingTransportationTasksPage Then
		RefreshTaskGenerationPage();
	ElsIf Items.MainPages.CurrentPage = Items.DocumentsForCarriersPage Then
		UpdateDocumentsForCarriers();
	Else
		UpdateTasksInProgressServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetItemsAvailability()
	
	TasksFilledIn = ScheduledTransportationJobs.GetItems().Count() > 0;
	Items.TransportationTasksPlannedTasksUp.Enabled     = TasksFilledIn;
	Items.TransportationTasksScheduledTasksDown.Enabled      = TasksFilledIn;
	Items.TheTreeFormationOfTheDeliverySplit.Enabled             = TasksFilledIn;
	Items.TheTreeFormationOfTheShippingCombine.Enabled          = TasksFilledIn;
	Items.JobTransportationPlanToOpenAJob.Enabled   = TasksFilledIn;
	Items.RemoveLinesFromAFlight.Enabled                           = TasksFilledIn;
	
	OrdersFilledIn = DeliveryReferences.GetItems().Count() > 0;
	Items.TransferLinesToAFlight.Enabled = OrdersFilledIn;
	
EndProcedure

&AtServer
Procedure UpdateTasksInProgressServer()
	
	SetVisibilityOfWarehouses();
	SetSelectionOfTaskForTransportationInWork();
	
EndProcedure

&AtServer
Function CheckSplitDeliveryPointServer()
	
	ConnectionKey = ScheduledTransportationJobs.FindByID(Items.ScheduledTransportationJobs.CurrentRow).ConnectionKey;
	NumberOfReferences = Object.ReferencesInDeliveryOrders.FindRows(New Structure("ConnectionKey",ConnectionKey)).Count();
	If NumberOfReferences < 2 Then
		Text = NStr("vi = 'Có thể phân chia dòng đối với địa chỉ, mà có liên quan đến hơn một lệnh';
					|ru = 'Разбиение строки возможно для адресов, к которым относится более одного распоряжения';
					|en = 'Line split is available for addresses with more than one reference'; fa = 'Line split is available for addresses with more than one reference';
					|it = 'La divisione della riga è possibile per gli indirizzi ai quali si riferisce più di un riferimento.';
					|pl = 'Podział wiersza jest możliwy dla adresów, do których odnosi się więcej niż jedno zamówienie';
					|tr = 'Birden fazla emrin geçerli olduğu adresler için satır bölme mümkündür'");
		Common.MessageToUser(Text);
		Return True;
	EndIf;
	If NumberOfReferences > 2 Then
		Return False; //Return to the client and open the order selection form
	EndIf;
	SplitDeliveryPointServer(); // The case with two orders - just split without a choice
	Return True;
	
EndFunction

&AtServer
Procedure SplitDeliveryPointServer(ValueSelected = Undefined)
	IDOfCurLine = Items.ScheduledTransportationJobs.CurrentRow;
	If ValueSelected <> Undefined Then
		// If there are more than two orders to split
		ReferenceArray = GetFromTempStorage(ValueSelected.ReferenceAddress);
	Else
		// If it is necessary to separate two orders
		ReferenceArray = New Array();
		Filter = New Structure("ConnectionKey", ScheduledTransportationJobs.FindByID(IDOfCurLine).ConnectionKey);
		ReferenceArray.Add(Object.ReferencesInDeliveryOrders.FindRows(Filter)[1]);
	EndIf;
	CurrentRow = ScheduledTransportationJobs.FindByID(IDOfCurLine);
	ParentBranch = CurrentRow.GetParent().GetItems();
	NewLineItem = ParentBranch.Insert(ParentBranch.IndexOf(CurrentRow)+1);
	FillPropertyValues(NewLineItem, CurrentRow);
	NewLineItem.ConnectionKey = New UUID;
	Weight = 0;
	VolumeM3 = 0;
	For Each Page1 In ReferenceArray Do
		CommandLine_ = Object.ReferencesInDeliveryOrders.FindRows(New Structure("ReferenceOrder, Warehouse", Page1.ReferenceOrder, Page1.Warehouse))[0];
		CommandLine_.ConnectionKey = NewLineItem.ConnectionKey;
		Weight = Weight + CommandLine_.Weight;
		VolumeM3 = VolumeM3 + CommandLine_.VolumeM3;
	EndDo;
	NewLineItem.Weight = Weight;
	NewLineItem.VolumeM3 = VolumeM3;
	NewLineItem.NumberOfReferences = ReferenceArray.Count();
	
	CurrentRow.Weight = CurrentRow.Weight - Weight;
	CurrentRow.VolumeM3 = CurrentRow.VolumeM3 - VolumeM3;
	CurrentRow.NumberOfReferences = CurrentRow.NumberOfReferences - ReferenceArray.Count();
	
	DetermineIfModified(CurrentRow,JobsModified);
	DetermineIfModified(NewLineItem, JobsModified);
	Items.ScheduledTransportationJobs.CurrentRow = NewLineItem.GetID();
	FillInWarehousesForItemsAndTasks(False);
	RenumberAndFillInDateTransitionSignsInTaskList(IDOfCurLine);
	
EndProcedure

&AtServer
Function UniteByTimeServer()
	
	FlagFirstRow = True;
	United = False;
	Weight = 0;
	VolumeM3 = 0;
	NumberOfReferences = 0;
	PreviousAddress = "";
	IDArray = Items.ScheduledTransportationJobs.SelectedRows;
	For Each ID In IDArray Do
		String = ScheduledTransportationJobs.FindByID(ID);
		Parent = String.GetParent();
		If Parent = Undefined Then
			Return False;
		EndIf;
		If Not FlagFirstRow And Upper(TrimAll(String.Address)) <> PreviousAddress Then
			Return False;
		EndIf;
		ParentIndex = ScheduledTransportationJobs.GetItems().IndexOf(Parent);
		RowIndex = Parent.GetItems().IndexOf(String);
		If FlagFirstRow Then
			FlagFirstRow = False;
			// You need to find the topmost delivery point in the list in order to merge lines with the same delivery addresses into it.
			MinIndexOfParent = ParentIndex;
			MinRowIndex = RowIndex;
		Else
			If MinIndexOfParent > ParentIndex Then
				MinIndexOfParent = ParentIndex;
				MinRowIndex = RowIndex;
			ElsIf (MinIndexOfParent = ParentIndex) And (MinRowIndex > RowIndex) Then
				MinRowIndex = RowIndex;
			EndIf;
		EndIf;
		Weight = Weight + String.Weight;
		VolumeM3 = VolumeM3 + String.VolumeM3;
		PreviousAddress = Upper(TrimAll(String.Address));
		United = True;
	EndDo;
	If United Then
		ResultRow = ScheduledTransportationJobs.GetItems()[MinIndexOfParent].GetItems()[MinRowIndex];
		ResultRow.Weight = Weight;
		ResultRow.VolumeM3 = VolumeM3;
		IDArray.Delete(IDArray.Find(ResultRow.GetID()));
		ConnectionKey = ResultRow.ConnectionKey;
		TransportationJob = ResultRow.Ref;
		For Each ID In IDArray Do
			String = ScheduledTransportationJobs.FindByID(ID);
			Branch1 = String.GetParent().GetItems();
			SearchFields = New Structure("ConnectionKey", String.ConnectionKey);
			ReferenceArray = Object.ReferencesInDeliveryOrders.FindRows(SearchFields);
			For Each CommandLine_ In ReferenceArray Do 
				CommandLine_.ConnectionKey = ConnectionKey;				
				CommandLine_.Ref = TransportationJob;
			EndDo;
			Branch1.Delete(String);
		EndDo;
		
		ReferencesInDeliveryOrders = Object.ReferencesInDeliveryOrders.Unload();
		ReferencesInDeliveryOrders.GroupBy(
			"ReferenceOrder,ConnectionKey,TimeFrom,TimeTo,Ref,AdditionalInformation,Address,Warehouse,RecipientSender,Carrier,DeliveredInFull",
			"Weight,VolumeM3");
		Object.ReferencesInDeliveryOrders.Load(ReferencesInDeliveryOrders);
		
		RowJob = LineTaskByLineItem(ResultRow);
		SearchFields = New Structure("Ref", TransportationJob);
		ReferenceArray = Object.ReferencesInDeliveryOrders.FindRows(SearchFields);
		RowJob.NumberOfReferences = ReferenceArray.Count();
		
		SearchFields = New Structure("ConnectionKey", ConnectionKey);
		ReferenceArray = Object.ReferencesInDeliveryOrders.FindRows(SearchFields);
		ResultRow.NumberOfReferences = ReferenceArray.Count();
		
		DetermineIfModified(ResultRow, JobsModified);
		FillInWarehousesForItemsAndTasks(False);
		RenumberAndFillInDateTransitionSignsInTaskList();
	EndIf;
	Return United;
	
EndFunction

&AtServer
Procedure FillServerWithPastFlights(TasksDate = Undefined)
	
	CurrentSessionDate = CurrentSessionDate();
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	BEGINOFPERIOD(TransportationJob.Date, DAY) AS MaxDay
	|INTO TTMaxDay
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|WHERE
	|	TransportationJob.Posted
	|	AND TransportationJob.Date < BEGINOFPERIOD(&CurrentDate, DAY)
	|
	|ORDER BY
	|	TransportationJob.Date DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TransportationJob.Vehicle_ AS Transport,
	|	TransportationJob.Vehicle_.CapacityPresentation AS CapacityPresentation,
	|	TransportationJob.PlanTripStartTime AS PlanTripStartTime,
	|	TransportationJob.Date AS Date,
	|	TransportationJob.JobIsPerformedBy AS JobIsPerformedBy,
	|	TransportationJob.Carrier AS Carrier,
	|	TransportationJob.Counterparty AS Counterparty,
	|	TransportationJob.CarrierBankAccount AS CarrierBankAccount
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|		LEFT JOIN TTMaxDay AS TTMaxDay
	|		ON (TTMaxDay.MaxDay = BEGINOFPERIOD(TransportationJob.Date, DAY))
	|WHERE
	|	TransportationJob.Warehouse IN HIERARCHY(&Warehouse)
	|	AND (TransportationJob.JobIsPerformedBy = &TypeOfPerformers
	|			OR &TypeOfPerformers = VALUE(Enum.TypesOfTransportationJobAssignees.EmptyRef))
	|	AND TransportationJob.Operation = &DeliveryKind
	|	AND TransportationJob.Posted
	|	AND BEGINOFPERIOD(TransportationJob.Date, DAY) = &TasksDate";
	
	If TasksDate = Undefined Then
		QueryText = StrReplace(QueryText, "LEFT JOIN", "INNER JOIN");
		QueryText = StrReplace(QueryText, "BEGINOFPERIOD(TransportationJob.Date, DAY)", "&TasksDate");
	EndIf;
	Query = New Query(QueryText);
	Query.SetParameter("TasksDate", TasksDate);
	Query.SetParameter("CurrentDate", CurrentSessionDate);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("DeliveryKind", DeliveryKind);
	Query.SetParameter("TypeOfPerformers", FilterByAssigneeType);
	Result = Query.Execute();
	Selection = Result.Select();
	If Result.IsEmpty() Then
		Text = NStr("vi = 'Tại ngày đã chỉ ra không có nhiệm vụ vận chuyển đã tiến hành';
					|ru = 'На указанную дату нет проведенных заданий на перевозку';
					|en = 'No posted itineraries for the specified date'; fa = 'No posted itineraries for the specified date';
					|it = 'Nella data indicata non ci sono task di trasporto pubblicati';
					|pl = 'W określonym terminie nie ma zatwierdzonych zadań na przewóz';
					|tr = 'Belirtilen tarih itibariyle herhangi bir taşıma planı gerçekleştirilmemiştir'");
		Common.MessageToUser(Text);
		Return;
	EndIf;
	While Selection.Next() Do
		NewRow = ScheduledTransportationJobs.GetItems().Add();
		NewRow.Transport = Selection.Transport;
		If BegOfDay(Selection.PlanTripStartTime) > BegOfDay(Selection.Date) Then
			// If we planned for future days, then in future plans we will use the time of departure of flights from history.
			NewRow.TimeFrom = BegOfDay(CurrentSessionDate) + (Selection.PlanTripStartTime - BegOfDay(Selection.Date));
		ElsIf Selection.PlanTripStartTime - BegOfDay(Selection.Date) > CurrentSessionDate - BegOfDay(CurrentSessionDate) + 60*60 Then
			// If we plan to send today and the time has not passed yet, we use the time of sending from history.
			NewRow.TimeFrom = BegOfDay(CurrentSessionDate) + (Selection.PlanTripStartTime - BegOfDay(Selection.PlanTripStartTime));
		Else
			// If we plan to ship today and the time has already passed, we believe that the flight can be sent an hour after formation.
			NewRow.TimeFrom = CurrentSessionDate + 60*60;
		EndIf;
		NewRow.TimeTo = NewRow.TimeFrom;
		NewRow.TimeFromWithoutDate  = GoodsDeliveryClientServer.TimeWithoutDate(NewRow.TimeFrom);
		NewRow.TimeToWithoutDate = GoodsDeliveryClientServer.TimeWithoutDate(NewRow.TimeTo);
		NewRow.Warehouse = Warehouse;
		NewRow.DeliveryKind = DeliveryKind;
		FillPropertyValues(NewRow, VehicleDetails(Selection.Transport));
		NewRow.JobIsPerformedBy = Selection.JobIsPerformedBy;
		NewRow.Carrier       = Selection.Carrier;
		NewRow.Counterparty                = Selection.Counterparty;
		NewRow.CarrierBankAccount = Selection.CarrierBankAccount;
		NewRow.ThisIsOurDelivery           =
			(Selection.JobIsPerformedBy = Enums.TypesOfTransportationJobAssignees.OurTransportationService);
		
		DetermineIfModified(NewRow, JobsModified);
	EndDo;
	SetItemsAvailability();
	
EndProcedure

&AtServer
Procedure RenumberAndFillInDateTransitionSignsInTaskList(DestinationLineID = Undefined)
	
	RenumberTaskItems(DestinationLineID);
	FillInDateTransitionSigns(DestinationLineID);
	
EndProcedure

&AtServer
Procedure RenumberTaskItems(DestinationLineID = Undefined)
	
	CurBranch		= Undefined; 
	CurrentJob	= Undefined;
	
	If ValueIsFilled(DestinationLineID) Then
		CurRow = ScheduledTransportationJobs.FindByID(DestinationLineID);
		CurrentJob = ?(CurRow.GetParent() = Undefined, CurRow, CurRow.GetParent());
	EndIf;
		
	CurBranch = ScheduledTransportationJobs.GetItems();
	
	For Each TaskRow In CurBranch Do
		
		If CurrentJob <> Undefined And CurrentJob <> TaskRow Then
			Continue;
		EndIf;
		
		If TaskRow.ItemModified Then
			For Each RowPoint In TaskRow.GetItems() Do
				RowPoint.SequenceInRoute = TaskRow.GetItems().IndexOf(RowPoint)+1;
			EndDo;
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure TasksSortRenumberFillInDateTransitionAttributes();
	
	CurRow = ScheduledTransportationJobs.FindByID(Items.ScheduledTransportationJobs.CurrentRow);
	Parent = CurRow.GetParent();
	If Parent = Undefined Then
		CurBranch = ScheduledTransportationJobs.GetItems();
	Else
		CurBranch = Parent.GetItems();
	EndIf;
	CurIndex__ = CurBranch.IndexOf(CurRow);
	
	Position = 0;
	While Position < CurBranch.Count()
		And (Position = CurIndex__
			Or (CurRow.TimeFrom > CurBranch[Position].TimeFrom
			Or (CurRow.TimeFrom = CurBranch[Position].TimeFrom
				And CurRow.TimeTo > CurBranch[Position].TimeTo))) Do
		Position = Position + 1;
	EndDo;
	
	If Position > CurIndex__ Then
		CurBranch.Move(CurIndex__,Position-CurIndex__-1);
	Else
		CurBranch.Move(CurIndex__,Position-CurIndex__);
	EndIf;
	
	If Parent <> Undefined Then
		RenumberTaskItems();
	EndIf;
	FillInDateTransitionSigns();
	
EndProcedure

&AtClient
Procedure CheckTimeCompliance(Source);
	
	CurRow = Items.ScheduledTransportationJobs.CurrentData;
	Parent = CurRow.GetParent();
	If (CurRow.TimeFrom > CurRow.TimeTo) Then
		If Source = "TimeFrom" Then
			CurRow.TimeTo = CurRow.TimeFrom;
			CurRow.TimeToWithoutDate  = GoodsDeliveryClientServer.TimeWithoutDate(CurRow.TimeTo);
		Else
			CurRow.TimeFrom = CurRow.TimeTo;
			CurRow.TimeFromWithoutDate = GoodsDeliveryClientServer.TimeWithoutDate(CurRow.TimeFrom);
		EndIf;
	EndIf;
	
	If Parent <> Undefined
		And (CurRow.TimeFrom < Parent.TimeFrom
			Or CurRow.TimeTo > Parent.TimeTo) Then
		Parent.TimeFrom = Min(CurRow.TimeFrom,Parent.TimeFrom);
		Parent.TimeTo = Max(CurRow.TimeTo,Parent.TimeTo);
		Parent.TimeFromWithoutDate  = GoodsDeliveryClientServer.TimeWithoutDate(Parent.TimeFrom);
		Parent.TimeToWithoutDate = GoodsDeliveryClientServer.TimeWithoutDate(Parent.TimeTo);
	EndIf;
	
EndProcedure

&AtServer
Procedure TasksCheckSortFillTransitionAttributes();
	
	CurRow = ScheduledTransportationJobs.FindByID(Items.ScheduledTransportationJobs.CurrentRow);
	CurIndex__ = ScheduledTransportationJobs.GetItems().IndexOf(CurRow);
	For Each Page1 In CurRow.GetItems() Do
		If Page1.TimeFrom < CurRow.TimeFrom Then
			Page1.TimeFrom = CurRow.TimeFrom;
		EndIf;
		If Page1.TimeTo < CurRow.TimeFrom Then
			Page1.TimeTo = CurRow.TimeFrom;
		EndIf;
		If Page1.TimeFrom > CurRow.TimeTo Then
			Page1.TimeFrom = CurRow.TimeTo;
		EndIf;
		Page1.TimeFromWithoutDate  = GoodsDeliveryClientServer.TimeWithoutDate(Page1.TimeFrom);
		Page1.TimeToWithoutDate = GoodsDeliveryClientServer.TimeWithoutDate(Page1.TimeTo);
	EndDo;
	
	TasksSortRenumberFillInDateTransitionAttributes();
	
EndProcedure

&AtServer
Procedure MoveLinesInsideListOfTasksGeneratedByServer(ArrayOfRowIDs,DestinationLineID)
	
	DestinationRow = ScheduledTransportationJobs.FindByID(DestinationLineID);
	ParentRow = DestinationRow.GetParent();
	If ParentRow = Undefined Then
		ParentRow = DestinationRow;
		IndexToInsert = ParentRow.GetItems().Count();
	Else
		IndexToInsert = ParentRow.GetItems().IndexOf(DestinationRow);
	EndIf;
	
	If Not TryToBlockGettingLinkByTaskLine(ParentRow) Then
		Return;
	EndIf;
	
	ModifiedAddedOrderLines = New Array;
	
	For Each LineID In ArrayOfRowIDs Do
		DraggableLine = ScheduledTransportationJobs.FindByID(LineID);
		FormerParent = DraggableLine.GetParent();
		If FormerParent = Undefined
			Or Not TryToBlockGettingLinkByTaskLine(FormerParent)
			Or CheckReportTaskChanged(FormerParent) Then
			Continue;
		EndIf;
		NewRow = ParentRow.GetItems().Insert(IndexToInsert);
		FillPropertyValues(NewRow,DraggableLine);
		FormerParent.Weight = FormerParent.Weight - NewRow.Weight;
		FormerParent.VolumeM3 = FormerParent.VolumeM3 - NewRow.VolumeM3;
		FormerParent.NumberOfReferences = FormerParent.NumberOfReferences - NewRow.NumberOfReferences;
		ParentRow.Weight = ParentRow.Weight + NewRow.Weight;
		ParentRow.VolumeM3 = ParentRow.VolumeM3 + NewRow.VolumeM3;
		ParentRow.NumberOfReferences = ParentRow.NumberOfReferences + ParentRow.NumberOfReferences;
		NewRow.Ref = ParentRow.Ref;
		If IndexToInsert > 0 Then
			If IndexToInsert + 1 < ParentRow.GetItems().Count() Then
				NewRow.TimeFrom = Min(ParentRow.GetItems()[IndexToInsert - 1].TimeTo,
										ParentRow.GetItems()[IndexToInsert + 1].TimeFrom);
				NewRow.TimeTo = ParentRow.GetItems()[IndexToInsert + 1].TimeFrom;
			Else
				NewRow.TimeFrom = ParentRow.GetItems()[IndexToInsert - 1].TimeTo;
				NewRow.TimeTo = NewRow.TimeFrom;
			EndIf;
		Else
			NewRow.TimeFrom = ParentRow.TimeFrom;
			If ParentRow.GetItems().Count() > 1 Then
				NewRow.TimeTo = ParentRow.GetItems()[IndexToInsert + 1].TimeFrom;
			Else
				NewRow.TimeTo = NewRow.TimeFrom;
			EndIf;
			NewRow.TimeTo = NewRow.TimeFrom;
		EndIf;
		NewRow.TimeFromWithoutDate  = GoodsDeliveryClientServer.TimeWithoutDate(NewRow.TimeFrom);
		NewRow.TimeToWithoutDate = GoodsDeliveryClientServer.TimeWithoutDate(NewRow.TimeTo);
		FormerParent.GetItems().Delete(DraggableLine);
		DetermineIfModified(NewRow, JobsModified);
		DetermineIfModified(FormerParent, JobsModified);
		IndexToInsert = IndexToInsert + 1;
		InvoicesForItem = Object.ReferencesInDeliveryOrders.FindRows(New Structure("ConnectionKey",NewRow.ConnectionKey));
		
		For Each Page1 In InvoicesForItem Do
			Page1.Ref = NewRow.Ref;
			ModifiedAddedOrderLines.Add(Page1);
			GoodsByOrder = GoodsToDeliver.FindRows(New Structure("TransportationJob,ReferenceOrder,Warehouse",FormerParent.Ref, Page1.ReferenceOrder, Page1.Warehouse));
			For Each LineProducts_ In GoodsByOrder Do
				LineProducts_.TransportationJob = Page1.Ref;
			EndDo;
		EndDo;
		
	EndDo;
	FillInWarehousesForItemsAndTasks(True);
	SaveTasksToAnotherServer();
	GoodsDelivery.ThisAttributeIsDeliveredInFull(GoodsToDeliver.Unload((New Structure("TransportationJob",ParentRow.Ref))),
		Object.ReferencesInDeliveryOrders, ModifiedAddedOrderLines);
	RenumberAndFillInDateTransitionSignsInTaskList(DestinationLineID);
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	SetSelectionOfTaskForTransportationInWork();
	
	If Status = "AllInProgress" Or Not ValueIsFilled(Status) Then
		Items.TransportationJobsInProgressStatus.Visible = True;
	Else
		Items.TransportationJobsInProgressStatus.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentsForCarriersOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure DocumentsForCarriersSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.DocumentsForCarriers.CurrentData;
	
	If CurrentData <> Undefined And TypeOf(CurrentData) <> Type("DynamicListGroupRow") Then
		ShowValue(Undefined, CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTaskForm(RowJob)
	
	If JobsModified Then
		SaveTasksToAnotherServer();
		NotifyAboutCreatedTasks();
	EndIf;
	ShowValue(Undefined, RowJob.Ref);
	
EndProcedure

&AtClient
Procedure NotifyAboutCreatedTasks()
	
	If NewJobs.Count() > 0 Then
		If NewJobs.Count() > 1 Then
			MessageText = NStr("vi = 'Đã tạo %JobsCount% vận chuyển';
								|ru = 'Создано %JobsCount% на перевозку';
								|en = '%JobsCount% for transportation are created'; fa = '%JobsCount% for transportation are created';
								|it = 'Generati %JobsCount% per il trasporto';
								|pl = 'Utworzono %JobsCount% na transport';
								|tr = '%JobsCount% transferi oluşturuldu'");
			MessageText = StrReplace(MessageText,"%JobsCount%",
				StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(NewJobs.Count(),
					"job,jobs,oftasks"));
			ShowUserNotification(,, MessageText, PictureLib.Information32);
		Else
			TitleText = NStr("vi = 'Tạo:';
							|ru = 'Создание:';
							|en = 'Created:'; fa = 'ایجادشده:';
							|it = 'Creazione:';
							|pl = 'Utworzenie:';
							|tr = 'Oluştur:'");
			URL = GetURL(NewJobs[0].Value);
			ShowUserNotification(
				TitleText,
				URL,
				String(NewJobs[0].Value),
				PictureLib.Information32);
			EndIf;
			NewJobs.Clear();
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledTransportationJobsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtServer
Procedure DateOfOrders_OnChangeServer()
	
	GoodsDelivery.UpdateListOfDeliveryOrders(ThisObject);
	SetItemsAvailability();
	
EndProcedure

&AtServer
Procedure ZoneOnChangeServer()
	
	AreaGroupOrEmpty = (Not ValueIsFilled(Zone)
		Or Common.ObjectAttributeValue(Zone,"IsFolder"));
	
	SaveTasksUpdateLists();
	
	If AreaGroupOrEmpty Then
		Items.DeliveryReferencesAddress.Title = NStr("vi = 'Khu vực/Địa chỉ';
													|ru = 'Зона/Адрес';
													|en = 'Delivery zone/Address'; fa = 'منطقه تحویل/آدرس';
													|it = 'Area/Indirizzo';
													|pl = 'Delivery zone/Address';
													|tr = 'Alan/Adres'");
	Else
		Items.DeliveryReferencesAddress.Title = NStr("vi = 'Địa chỉ';
													|ru = 'Адрес';
													|en = 'Address'; fa = 'آدرس';
													|it = 'Indirizzo';
													|pl = 'Address';
													|tr = 'Adres'");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function LineTaskByLineItem(RouteString)
	
	ParentOfRouteLine = RouteString.GetParent();
	If ParentOfRouteLine <> Undefined Then
		Return ParentOfRouteLine;
	Else
		Return RouteString;
	EndIf;
	
EndFunction

&AtServer
Function PlaceGoodsInStorageForDelivery(TransportationJob)
	
	Return PutToTempStorage(GoodsToDeliver.Unload(New Structure("TransportationJob",TransportationJob)),UUID);
	
EndFunction

&AtServer
Function TryToBlockGettingLinkByTaskLine(RowJob)
	
	If Not ValueIsFilled(RowJob.Ref) Then
		RowJob.Ref = Documents.TransportationJob.GetRef();
		NewJobs.Add(RowJob.Ref);
		Return True;
	EndIf;
	
	Try
		DocObject = RowJob.Ref.GetObject();
		DocObject.Lock();
		DocObject.Unlock();
		Return True;
	Except
		Text = NStr("vi = 'Không thể chặn %Job% cho các thay đổi.';
					|ru = 'Не удалось заблокировать %Job% для изменений.';
					|en = 'Cannot lock %Job% for editing.'; fa = 'Cannot lock %Job% for editing.';
					|it = 'Impossibile bloccare %Job% per le modifiche.';
					|pl = 'Nie udało się zablokować %Job% do zmian.';
					|tr = '%Job% değişimi engellenemedi.'");
		Text = StrReplace(Text,"%Job%", RowJob.Ref);
		Common.MessageToUser(Text, RowJob.Ref);
		Return False;
	EndTry;
	
EndFunction

&AtServer
Procedure DeliveryKindOnChangeServer()
	
	CustomizeFormByDeliveryType();
	SaveTasksUpdateLists();
	SetItemsAvailability();
	
EndProcedure

&AtServer
Procedure CustomizeFormByDeliveryType()
	
	If DeliveryKind = Enums.DeliveryKinds.FromWarehouse Then
		
		Items.DeliveryReferencesDate.Title                              = NStr("vi = 'Ngày giao hàng';
																				|ru = 'Дата отгрузки';
																				|en = 'Shipment date'; fa = 'تاریخ ارسال';
																				|it = 'Data di spedizione';
																				|pl = 'Data wysyłki';
																				|tr = 'Sevkiyat tarihi'");
		Items.DeliveryReferencesTime.Title                             = NStr("vi = 'Thời gian giao hàng (mong muốn)';
																				|ru = 'Время доставки (желаемое)';
																				|en = 'Delivery time (required)'; fa = 'Delivery time (required)';
																				|it = 'Orario di consegna (desiderato)';
																				|pl = 'Czas dostawy (żądany)';
																				|tr = 'Teslimat süresi (istenen)'");
		Items.DeliveryOrdersRecipientSender.Title             = NStr("vi = 'Người nhận';
																	|ru = 'Получатель';
																	|en = 'Recipient'; fa = 'گیرنده';
																	|it = 'Destinatario';
																	|pl = 'Recipient';
																	|tr = 'Alıcı'");
		Items.DocumentsForCarriersPage.Visible = Not GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers");
		Items.TransportationTasksInProgressSetTheStatusForLoading.Visible = True;
		If Items.Status.ChoiceList.FindByValue("ToLoad") = Undefined Then
			EnumValues = Metadata.Enums.StatusesOfTransportationJobs.EnumValues;
			Items.Status.ChoiceList.Insert(2, EnumValues.ToLoad.Name, EnumValues.ToLoad.Synonym);
		EndIf;
	Else
		
		Items.DeliveryReferencesDate.Title                              = NStr("vi = 'Ngày tiếp nhận';
																				|ru = 'Дата поступления';
																				|en = 'Date of receipt'; fa = 'تاریخ دریافت';
																				|it = 'Data di ricezione';
																				|pl = 'Data wpływu';
																				|tr = 'Giriş tarihi'");
		Items.DeliveryReferencesTime.Title                             = NStr("vi = 'Thời gian chuyển hàng';
																				|ru = 'Время передачи товара';
																				|en = 'Goods delivery time'; fa = 'Goods delivery time';
																				|it = 'Tempo di consegna merce';
																				|pl = 'Czas przekazania towaru';
																				|tr = 'Devir teslim süresi'");
		Items.DeliveryOrdersRecipientSender.Title             = NStr("vi = 'Người gửi';
																	|ru = 'Отправитель';
																	|en = 'Sender'; fa = 'فرستنده';
																	|it = 'Mittente';
																	|pl = 'Sender';
																	|tr = 'Gönderen'");
		If Items.MainPages.CurrentPage = Items.DocumentsForCarriersPage Then
			Items.MainPages.CurrentPage = Items.CreatingTransportationTasksPage;
		EndIf;
		Items.DocumentsForCarriersPage.Visible = False;
		Items.TransportationTasksInProgressSetTheStatusForLoading.Visible = False;
		ListItem = Items.Status.ChoiceList.FindByValue("ToLoad");
		If ListItem <> Undefined Then
			Items.Status.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
	CustomizeFormByDeliveryTypeLocalization()
	
EndProcedure

&AtServer
Procedure CarrierOnChangeServer()
	
	UpdateDocumentsForCarriers();
	Items.DocumentsForCarriersCarrier.Visible = Not ValueIsFilled(Carrier);
	
EndProcedure

&AtServer
Procedure ExcludeFromDeliveryOnServer()
	
	ModesOfFormationOfSpendingOrdersAutomatically = Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.Automatically;
	ShipmentReferenceOrderType = Metadata.DefinedTypes.ShipmentReferenceOrder.Type;
	
	ArrayOfIDOfSelectedRows = Items.DeliveryReferences.SelectedRows;
	
	RemoveRootLines = DeliveryReferences.GetItems();
	
	ModifiedAddedOrderLines = New Array;
	
	For Each LineID In ArrayOfIDOfSelectedRows Do
		
		CurLineOfOrders = DeliveryReferences.FindByID(LineID);
		
		// If the current row has already been deleted along with the parent
		If CurLineOfOrders = Undefined Then
			Continue;
		EndIf;
		
		TopOfCurBranchOfOrders = CurLineOfOrders.GetParent();
		
		// If there is a parent of this row in the selected rows, we do nothing, the row will be processed together with the parent.
		If TopOfCurBranchOfOrders <> Undefined
				And ArrayOfIDOfSelectedRows.Find(TopOfCurBranchOfOrders.GetID())<>Undefined Then
			Continue;
		EndIf;
		
		If TopOfCurBranchOfOrders = Undefined Then
			CurBranchOrders = CurLineOfOrders.GetItems();
			TopOfCurBranchOfOrders = CurLineOfOrders;
		Else
			CurBranchOrders = TopOfCurBranchOfOrders.GetItems();
		EndIf;
			
		CollectionOfSubordinateStrings = CurLineOfOrders.GetItems();
		
		If CollectionOfSubordinateStrings.Count() = 0 Then
			CollectionOfSubordinateStrings = New Array(1);
			CollectionOfSubordinateStrings[0] = CurLineOfOrders;
			If AreaGroupOrEmpty Then
				CurLineOfOrders.GetParent().Weight = CurLineOfOrders.GetParent().Weight - CurLineOfOrders.Weight;
				CurLineOfOrders.GetParent().VolumeM3 = CurLineOfOrders.GetParent().VolumeM3 - CurLineOfOrders.VolumeM3;
			EndIf;
		EndIf;
		
		TotalWeight_ = TotalWeight_ - CurLineOfOrders.Weight;
		TotalVolume = TotalVolume - CurLineOfOrders.VolumeM3;
		
		For Each Orders_Row In CollectionOfSubordinateStrings Do
			
			TheStructureOfTheSearch = New Structure("IDInReferenceTree", Orders_Row.GetID());
			LinesOfOrdersWithGoods = ReferenceGoodsToDeliver.FindRows(TheStructureOfTheSearch);
			
			RegisterFields = "ReferenceOrder, Warehouse, Products, Characteristic, Purpose, Series, RecipientSender";
			NumericRegisterFields = "Count, Weight, VolumeM3";
			RolledGoodsDeliveryOrders = ReferenceGoodsToDeliver.Unload(
				LinesOfOrdersWithGoods,
				RegisterFields + ", " + NumericRegisterFields);
			RolledGoodsDeliveryOrders.GroupBy(RegisterFields, NumericRegisterFields);
			
			BeginTransaction();
			
			Try
				
				For Each LineException In RolledGoodsDeliveryOrders Do
				
					NewRecord = InformationRegisters.GoodsToDeliver.CreateRecordManager();
					FillPropertyValues(NewRecord, LineException);
					NewRecord.Write();
				
				EndDo;
				
				If ModesOfFormationOfSpendingOrdersAutomatically
					And ShipmentReferenceOrderType.ContainsType(TypeOf(Orders_Row.ReferenceOrder)) Then
					If WarehousesServer.YouNeedToReissueSpendingOrders(Orders_Row.Warehouse, Orders_Row.RecipientSender) Then
						WarehousesServer.AddToQueueForFormingSpendingOrders(Orders_Row.Warehouse, Orders_Row.RecipientSender);
					EndIf;
				EndIf;
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				MessageText = NStr("vi = 'Không thể loại trừ %ReferenceOrder% khỏi giao hàng.';
									|ru = 'Не удалось исключить %ReferenceOrder% из доставки.';
									|en = 'Cannot exclude %ReferenceOrder% from delivery.'; fa = 'Cannot exclude %ReferenceOrder% from delivery.';
									|it = 'Impossibile escludere %ReferenceOrder% dalla consegna.';
									|pl = 'Nie udało się wykluczyć %ReferenceOrder% z dostawy.';
									|tr = '%ReferenceOrder% teslimattan çıkarılamadı.'");
				MessageText = StrReplace(MessageText, "%ReferenceOrder%", String(Orders_Row.ReferenceOrder));
				CommonClientServer.MessageToUser(MessageText);
				
				DefaultLanguageCode = CommonClientServer.DefaultLanguageCode(); // To record an event in the registration Log.
				WriteLogEvent(NStr("vi = 'Không thể loại trừ đơn hàng khỏi giao hàng.';
									|ru = 'Не удалось исключить распоряжение из доставки.';
									|en = 'Cannot exclude the reference from delivery.'; fa = 'Cannot exclude the reference from delivery.';
									|it = 'Impossibile escludere la disposizione dalla consegna.';
									|pl = 'Nie udało się wykluczyć zamówienie z dostawy.';
									|tr = 'Sipariş teslimattan çıkarılamadı.'", DefaultLanguageCode),
					EventLogLevel.Error, , ,
					DetailErrorDescription(ErrorInfo()));
				
			EndTry;
			
		EndDo;
		
		If TopOfCurBranchOfOrders = CurLineOfOrders Then
			RemoveRootLines.Delete(CurLineOfOrders);
		Else
			CurBranchOrders.Delete(CurLineOfOrders);
			// If we deleted the last element in the branch, we will delete the parent
			If CurBranchOrders.Count() = 0 Then
				RemoveRootLines.Delete(TopOfCurBranchOfOrders);
			EndIf;
		EndIf;
		
	EndDo;
	
	RenumberAndFillInDateTransitionSignsInTaskList();
	GoodsDelivery.FillInSignsOfExecutionOfOrders(DeliveryReferences, AreaGroupOrEmpty);
	SetItemsAvailability();
	
EndProcedure

&AtServer
Procedure UpdateListOfDeliveryOrders(EmailAddressOrLink = Undefined)
	
	UpdatedOrders = Undefined;
	If EmailAddressOrLink <> Undefined Then
		
		If TypeOf(EmailAddressOrLink) = Type("String") Then
			UpdatedOrders = GetFromTempStorage(EmailAddressOrLink);
		Else
			UpdatedOrders = TableUpdatedOrders();
			NewRow = UpdatedOrders.Add();
			NewRow.ReferenceOrder = EmailAddressOrLink;
			NewRow.Warehouse = Common.ObjectAttributeValue(EmailAddressOrLink,"Warehouse");
		EndIf;
		
	EndIf;
	
	GoodsDelivery.UpdateListOfDeliveryOrders(ThisObject, UpdatedOrders);
	
EndProcedure

&AtClient
Procedure AfterEditingOrders(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	AfterEditingOrdersServer(Result);
	TransportTasksScheduledWhenWaitHandlerLineIsActivated();
	
EndProcedure

&AtServer
Procedure AfterEditingOrdersServer(Result)
	
	LineItem = ScheduledTransportationJobs.FindByID(Items.ScheduledTransportationJobs.CurrentRow);
	RowJob = LineTaskByLineItem(LineItem);
		
	DetermineIfModified(LineItem, JobsModified);
	
	// We will clear editable orders and related products
	If LineItem = RowJob Then
		StructureOfOrderSearch = New Structure("Ref",RowJob.Ref);
	Else
		StructureOfOrderSearch = New Structure("Ref,ConnectionKey", LineItem.Ref,LineItem.ConnectionKey);
	EndIf;
	
	TableUpdatedOrders = TableUpdatedOrders();
	
	FoundOrderLines = Object.ReferencesInDeliveryOrders.FindRows(StructureOfOrderSearch);
	For Each CommandLine_ In FoundOrderLines Do
		
		If LineItem <> RowJob Then
			ProductSearchStructure_1 = New Structure("TransportationJob,ReferenceOrder,Warehouse",
				CommandLine_.Ref, CommandLine_.ReferenceOrder, CommandLine_.Warehouse);
			FoundProductLines = GoodsToDeliver.FindRows(ProductSearchStructure_1);
			For Each LineProducts_ In FoundProductLines Do
				GoodsToDeliver.Delete(LineProducts_);
			EndDo;
		EndIf;
		
		FillPropertyValues(TableUpdatedOrders.Add(), CommandLine_);
		Object.ReferencesInDeliveryOrders.Delete(CommandLine_);
	EndDo;
	
	If LineItem = RowJob Then
		ProductSearchStructure_1 = New Structure("TransportationJob",RowJob.Ref);
		FoundProductLines = GoodsToDeliver.FindRows(ProductSearchStructure_1);
		For Each LineProducts_ In FoundProductLines Do
			GoodsToDeliver.Delete(LineProducts_);
		EndDo;
		
		RowJob.Weight = Result.Weight;
		RowJob.VolumeM3 = Result.VolumeM3;
	Else
		LineItem.Weight = Result.Weight;
		LineItem.VolumeM3 = Result.VolumeM3;
	EndIf;
	
	// We will add orders and products after editing
	EditedProducts = GetFromTempStorage(Result.AddressOfGoodsForDelivery);
	CommonClientServer.SupplementTable(EditedProducts, GoodsToDeliver);
	EditedOrders = GetFromTempStorage(Result.ReferenceAddress);
	MatchingItems = New Map;
	For Each Page1 In EditedOrders Do
		FillPropertyValues(Object.ReferencesInDeliveryOrders.Add(),Page1);
		If MatchingItems[Page1.ConnectionKey] = Undefined Then
			MatchingItems.Insert(Page1.ConnectionKey, 1);
		Else
			MatchingItems[Page1.ConnectionKey] = MatchingItems[Page1.ConnectionKey] + 1;
		EndIf;
	EndDo;
	
	TaskItems = RowJob.GetItems();
	If LineItem = RowJob Then
		PointsToBypass = TaskItems;
		RowJob.NumberOfReferences = 0;
	Else
		PointsToBypass = New Array;
		PointsToBypass.Add(LineItem);
		RowJob.NumberOfReferences = RowJob.NumberOfReferences - LineItem.NumberOfReferences;
	EndIf;
	
	RowsCount = PointsToBypass.Count();
	For Account = 1 To RowsCount Do
		Page1 = PointsToBypass[RowsCount - Account];
		If MatchingItems[Page1.ConnectionKey] <> Undefined Then
			Page1.NumberOfReferences = MatchingItems[Page1.ConnectionKey];
			RowJob.NumberOfReferences = RowJob.NumberOfReferences + Page1.NumberOfReferences;
		Else
			TaskItems.Delete(Page1);
		EndIf;
	EndDo;
	
	GoodsDelivery.ThisAttributeIsDeliveredInFull(GoodsToDeliver.Unload(), Object.ReferencesInDeliveryOrders);
	
	SaveTasksToAnotherServer();
	
	GoodsDelivery.UpdateListOfDeliveryOrders(ThisForm,TableUpdatedOrders);
	
	SetItemsAvailability();
	
EndProcedure

&AtClient
Procedure CheckingIfYouNeedToRecalculateTotalsForDeliveryOrdersWaitingHandler()
	// A waiting handler to intercept the allocation of all rows of the order tree is being delivered,
	// because the platform does not have a handler for the allocation of all rows event.
	NumberOfAllocated = Items.DeliveryReferences.SelectedRows.Count();
	If NumberOfAllocatedOrderLines <> NumberOfAllocated Then
		RecalculateTotalsForDeliveryOrders();
		NumberOfAllocatedOrderLines = NumberOfAllocated;
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryOrdersWhenWaitHandlerLineIsActivated()
	
	RecalculateTotalsForDeliveryOrders();
	NumberOfAllocatedOrderLines = Items.DeliveryReferences.SelectedRows.Count();
	
EndProcedure

&AtClient
Procedure RecalculateTotalsForDeliveryOrders()
	
	Weight = 0;
	VolumeM3 = 0;
	
	IDOfCurLine = Items.DeliveryReferences.CurrentRow;
	CurrentRow = Undefined;
	If IDOfCurLine <> Undefined Then
		CurrentRow = DeliveryReferences.FindByID(IDOfCurLine);
	EndIf;
	
	If CurrentRow <> Undefined Then
		
		If Not AreaGroupOrEmpty Then
			For Each ID In Items.DeliveryReferences.SelectedRows Do
				Page1 = DeliveryReferences.FindByID(ID);
				Weight = Weight + Page1.Weight;
				VolumeM3 = VolumeM3 + Page1.VolumeM3;
			EndDo;
		Else
			CalculatedWeightByZone   = New Structure;
			RecordedVolumeByZone = New Structure;
			RegisteredParents     = New Structure;
			For Each ID In Items.DeliveryReferences.SelectedRows Do
				Page1 = DeliveryReferences.FindByID(ID);
				IdString = "ID" + StrReplace(String(ID),Chars.NBSp,"");
				RowParent_ = Page1.GetParent();
				If RowParent_ = Undefined Then
					RegisteredParents.Insert(IdString,True);
					If CalculatedWeightByZone.Property(IdString) Then
						Weight = Weight + Page1.Weight - CalculatedWeightByZone[IdString];
						VolumeM3 = VolumeM3 + Page1.VolumeM3 - RecordedVolumeByZone[IdString];
					Else
						Weight = Weight + Page1.Weight;
						VolumeM3 = VolumeM3 + Page1.VolumeM3;
					EndIf;
				Else
					IdString = "ID" + StrReplace(String(RowParent_.GetID()),Chars.NBSp,"");
					If Not RegisteredParents.Property(IdString) Then
						If CalculatedWeightByZone.Property(IdString) Then
							CalculatedWeightByZone[IdString] = CalculatedWeightByZone[IdString] + Page1.Weight;
							RecordedVolumeByZone[IdString] = RecordedVolumeByZone[IdString] + Page1.VolumeM3;
						Else
							CalculatedWeightByZone.Insert(IdString, Page1.Weight);
							RecordedVolumeByZone.Insert(IdString, Page1.VolumeM3);
						EndIf;
						Weight = Weight + Page1.Weight;
						VolumeM3 = VolumeM3 + Page1.VolumeM3;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	Template = NStr("vi = '%Count% %UnitOfMeasure%';
					|ru = '%Count% %UnitOfMeasure%';
					|en = '%Count% %UnitOfMeasure%'; fa = '%Count% %UnitOfMeasure%';
					|it = '%Count% %UnitOfMeasure%';
					|pl = '%Count% %UnitOfMeasure%';
					|tr = '%Count% %UnitOfMeasure%'");
	Text = StrReplace(Template, "%Count%", Round(Weight));
	Text = StrReplace(Text, "%UnitOfMeasure%", UnitOfMeasureForWeight);
	LabelWeightOfTheAllocatedOnes = New FormattedString(Text, New Font(, , True));
	Text = StrReplace(Template, "%Count%", Round(VolumeM3));
	Text = StrReplace(Text, "%UnitOfMeasure%", UnitOfMeasureForVolume);
	LabelVolumeOfTheAllocatedOnes = New FormattedString(Text, New Font(, , True));
	
	Picture = New Picture;
	Text = "";
	
	If CurrentRow <> Undefined
		And CurrentRow.RowAppearance <> 5 Then
		
		If CurrentRow.Picture = 4 Then
			
			Picture = PictureLib.Warning;
			Text = NStr("vi = 'Điều kiện đặc biệt của vận chuyển.';
						|ru = 'Особые условия перевозки.';
						|en = 'Requires special handling.'; fa = 'Requires special handling.';
						|it = 'Condizioni speciali di trasporto.';
						|pl = 'Szczególne warunki przewozu.';
						|tr = 'Özel sevkiyat koşulları.'");
			
		ElsIf CurrentRow.Picture = 2 Then
			
			Picture = PictureLib.DoQueryBox;
			Text = NStr("vi = 'Phương thức giao hàng không được chỉ định.';
						|ru = 'Не указан способ доставки.';
						|en = 'Delivery method is not specified.'; fa = 'Delivery method is not specified.';
						|it = 'Modalità di consegna non specificata.';
						|pl = 'Nie określono sposobu dostawy.';
						|tr = 'Teslimat yöntemi belirtilmedi.'");
			
		ElsIf CurrentRow.Picture = 5 Then
			
			Picture = PictureLib.QuestionWithWarning;
			Text = NStr("vi = 'Phương thức giao hàng không được chỉ định. Điều kiện đặc biệt của vận chuyển.';
						|ru = 'Не указан способ доставки. Особые условия перевозки.';
						|en = 'Delivery method is not specified. Requires special handling.'; fa = 'Delivery method is not specified. Requires special handling.';
						|it = 'Modalità di consegna non specificata. Condizioni speciali di trasporto.';
						|pl = 'Nie określono sposobu dostawy. Szczególne warunki przewozu.';
						|tr = 'Teslimat yöntemi belirtilmedi. Özel sevkiyat koşulları.'");
			
		ElsIf CurrentRow.Picture = 0 Then
			
			Picture = PictureLib.JobIsExecutedByCarrier;
			Text = NStr("vi = 'Người vận chuyển.';
						|ru = 'Везет перевозчик.';
						|en = 'Carried by the carrier.'; fa = 'Carried by the carrier.';
						|it = 'Portato dal trasportatore.';
						|pl = 'Wiezie przewoźnik.';
						|tr = 'Taşıyıcı araç kullanıyor.'");
			
		ElsIf CurrentRow.Picture = 3 Then
			
			Picture = PictureLib.JobIsCompletedByCarrierSpecialConditions;
			Text = NStr("vi = 'Người vận chuyển. Điều kiện đặc biệt của vận chuyển.';
						|ru = 'Везет перевозчик. Особые условия перевозки.';
						|en = 'Carried by the carrier. Requires special handling.'; fa = 'Carried by the carrier. Requires special handling.';
						|it = 'Portato dal trasportatore. Condizioni speciali di trasporto.';
						|pl = 'Wiezie przewoźnik. Szczególne warunki przewozu.';
						|tr = 'Taşıyıcı araç kullanıyor. Özel sevkiyat koşulları.'");
			
		EndIf;
		
	EndIf;
	
	LabelFooterLegend = Text;
	Items.DecorationBasementLegend.Picture = Picture;
	
EndProcedure

&AtServerNoContext
Function VehicleDetails(Vehicle_)
	
	Return GoodsDelivery.VehicleDetails(Vehicle_);
	
EndFunction

&AtClient
Procedure TransportationJobsInProgressOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Function CorrespondenceOfCommandsToStatuses()
	
	CorrespondenceOfCommandsToStatuses = New Map();
	CorrespondenceOfCommandsToStatuses.Insert("SetClosedStatus", "Closed");
	CorrespondenceOfCommandsToStatuses.Insert("SetTheClosedStatusForFullyDeliveredTasks", "Closed");
	CorrespondenceOfCommandsToStatuses.Insert("SetTheStatusForLoading", "ToLoad");
	CorrespondenceOfCommandsToStatuses.Insert("SetTheSentStatus", "Sent");
	CorrespondenceOfCommandsToStatuses.Insert("SetTheGeneratingStatus", "BeingGenerated");
	
	Return CorrespondenceOfCommandsToStatuses;
	
EndFunction

#EndRegion

#Region Localization

&AtServer
Procedure CustomizeFormByDeliveryTypeLocalization()
	
	
	Return;
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_DateOfOrders_" Then
		DateOfOrders_OnChange(Items.DateOfOrders_);
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
