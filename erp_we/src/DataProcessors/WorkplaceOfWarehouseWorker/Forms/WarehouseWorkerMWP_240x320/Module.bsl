
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ScreenResolution = Enums.ScreenResolutions.Resolution240x320;
	
	WorkplaceOfWarehouseWorkerServer.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not InterfaceVersion82 Then
		
		Notification = New CallbackDescription("StartingWarehouseWorkerSWorkplaceIsNotInTaxi", ThisForm);
		
		OpenForm("DataProcessor.WorkplaceOfWarehouseWorker.Form.TransferToInterface82",
			,
			ThisForm
			,,,,
			Notification, 
			FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
	
	AttachIdleHandler("ExternalEquipmentMechanism", 5, True);
	
	AttachIdleHandler("Attachable_UpdateListOfTasksWaitingHandler", 60);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" Then
		
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			// Convert it to the expected format beforehand
			If Parameter[1] = Undefined Then
				Barcode = Parameter[0];
			Else
				Barcode = Parameter[1][1];
			EndIf;
			
			If ModeSettings.Mode = "RequestInformation" Then
				
				DisplayBarcodeInformationOnServer(Barcode);
				
			ElsIf ModeSettings.Mode = "Scanning" Then
				
				WhenScanningValueOnServer(Barcode);
				
				#If Not WebClient Then
				If ValueIsFilled(ErrorMessage) Then
					Beep();
				EndIf;
				#EndIf
				
			ElsIf ModeSettings.Mode = "SelectJob"
				Or ModeSettings.Mode = "OperationSelection" Then
				
				WhenScanningJobBarcodeOnServer(Barcode);
				
			Else
				
				// This mode is not intended for scanning.
				#If Not WebClient Then
				Beep();
				#EndIf
				
			EndIf;
			
			AttachIdleHandler("Attachable_DisplaysStateOfJobExecutionWaitingHandler", 5, True);
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		WorkplaceOfWarehouseWorkerClient.BeforeClose(ThisForm, Cancel, WarningText, StandardProcessing);
		Return;
	EndIf;
	
	BeforeCloseAtServer(Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	WorkplaceOfWarehouseWorkerClient.OnClose(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersJobs

&AtClient
Procedure JobsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ListOfSelectionTasksOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReceivingShippingAreas

&AtClient
Procedure AreasOfAcceptanceOfPlacementBeforeTheStartOfTheChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AreasOfAcceptanceOfPlacementBeforeRemoval(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ZoneOfAcceptanceOfThePlacementChoice(Item, RowSelected, Field, StandardProcessing)
	
	WhenSelectingHostingAcceptanceZoneOnServer();
	
EndProcedure

&AtClient
Procedure AreasOfAcceptanceOfPlacementBeforeTheStartOfTheAddition(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MainMenuUpdate(Command)
	
	MainMenuUpdateOnServer();
	
EndProcedure

&AtClient
Procedure EnteringTheQuantityOK(Command)
	
	WorkplaceOfWarehouseWorkerClient.EnteringTheQuantityOK(ThisForm);
	
EndProcedure

&AtClient
Procedure EnteringAQuantityCancel(Command)
	
	EnteringNumberOfUsersOnServer();
	
EndProcedure

&AtClient
Procedure MainMenuInformation(Command)
	
	MainMenuServerInformation();
	
EndProcedure

&AtClient
Procedure TasksGoToTheMainMenu(Command)
	
	TasksGoToMainMenuOnServer();
	
EndProcedure

&AtClient
Procedure TasksShowAll(Command)
	
	TasksShowAllOnServer();
	
EndProcedure

&AtClient
Procedure InformationClose(Command)
	
	CloseInformationOnServer();
	
EndProcedure

&AtClient
Procedure MainMenuSelection(Command)
	
	MainMenuSelectionOnServer();
	
EndProcedure

&AtClient
Procedure MainMenuAcceptance(Command)
	
	MainMenuAcceptanceOnServer();
	
EndProcedure

&AtClient
Procedure MainMenuSelectionCheck(Command)
	
	MainMenuCheckSelectionOnServer();
	
EndProcedure

&AtClient
Procedure MainMenuPlacement(Command)
	
	MainMenuServerPlacement();
	
EndProcedure

&AtClient
Procedure MainMenuMove(Command)
	
	MainMenuMoveOnServer();
	
EndProcedure

&AtClient
Procedure MainMenuRecalculate(Command)
	
	MainMenuRecalculationOnServer();
	
EndProcedure

&AtClient
Procedure MainMenuMarkCellToRecalculate(Command)
	
	MainMenuSelectCellToRecalculateOnServer();
	
EndProcedure

&AtClient
Procedure MainMenuClose(Command)
	
	MainMenuCloseOnServer();
	
EndProcedure

&AtClient
Procedure ScanningInformation(Command)
	
	ScanningInformationOnServer();
	
EndProcedure

&AtClient
Procedure ScanCell(Command)
	
	WorkplaceOfWarehouseWorkerClient.ScanCell(ThisForm);
	
EndProcedure

&AtClient
Procedure ScanSeries(Command)
	
	MessageToUserText = "";
	
EndProcedure

&AtClient
Procedure ScanTheProduct(Command)
	
	ScanningProductOnServer();
	
EndProcedure

&AtClient
Procedure CreateANewWarehouseTask(Command)
	
	CreateNewWarehouseJobOnServer();
	
EndProcedure

&AtClient
Procedure ScanningAnAction(Command)
	
	ScanningActionOnServer();
	
EndProcedure

&AtClient
Procedure ScanNext(Command)
	
	ScanNextOnServer();
	
EndProcedure

&AtClient
Procedure CloseTheFormOfMobileWorkplace(Command)
	
	WorkplaceOfWarehouseWorkerClient.CloseTheFormOfMobileWorkplace(ThisForm);
	
EndProcedure

&AtClient
Procedure DoNotCloseMobileWorkplaceForm(Command)
	
	DoNotCloseMobileWorkplaceFormOnServer();
	
EndProcedure

&AtClient
Procedure CancelJobExecution(Command)
	
	CancelTaskOnServer();
	
EndProcedure

&AtClient
Procedure FinishJobExecution(Command)
	
	FinishTaskOnServer();
	
EndProcedure

&AtClient
Procedure GoToTheGoodsPlacement(Command)
	
	GoToPlacingProductsOnServer();
	
EndProcedure

&AtClient
Procedure GoToTheNextScanningGoods(Command)
	
	GoToNextScanLineOnServer();
	
EndProcedure

&AtClient
Procedure GoToTheNextScanningBin(Command)
	
	GoToNextScanCellOnServer();
	
EndProcedure

&AtClient
Procedure SelectGoodsFromOtherBinsWhileTransferringToTheNextBin(Command)
	
	PickUpProductsFromOtherCellsWhenMovingToNextCellOnServer();
	AttachIdleHandler("Attachable_DisplaysStateOfJobExecutionWaitingHandler", 5, True);
	
EndProcedure

&AtClient
Procedure CancelGoodsPickingFromOtherBinsWhileTransferringToTheNextBin(Command)
	
	CancelSelectionOfProductsFromOtherCellsWhenMovingToNextCellOnServer();
	
EndProcedure

&AtClient
Procedure SelectGoodsFromOtherBins(Command)
	
	PickUpProductsFromOtherCellsOnServer();
	AttachIdleHandler("Attachable_DisplaysStateOfJobExecutionWaitingHandler", 5, True);
	
EndProcedure

&AtClient
Procedure CancelGoodsPickingFromOtherBins(Command)
	
	CancelSelectionOfProductsFromOtherCellsOnServer();
	
EndProcedure

&AtClient
Procedure AddGoods(Command)
	
	GetProductsOnServer();
	AttachIdleHandler("Attachable_DisplaysStateOfJobExecutionWaitingHandler", 5, True);
	
EndProcedure

&AtClient
Procedure ScanEnterAValue(Command)
	
	ScanEnterValueOnServer();
	
	Items.BarcodeOfTheScanParameter.Visible = False;
	Items.BarcodeOfTheScanParameter.Visible = True;
	ThisForm.CurrentItem = Items.BarcodeOfTheScanParameter;
	
	#If MobileClient Then
		ThisForm.BeginEditingItem();
	#EndIf
	
EndProcedure

&AtClient
Procedure ScanToEnterTheNumber(Command)
	
	ScanEnterQuantityOnServer();
	
EndProcedure

&AtClient
Procedure SelectingTheOKValue(Command)
	
	WorkplaceOfWarehouseWorkerClient.SelectingTheOKValue(ThisForm);
	
EndProcedure

&AtClient
Procedure SelectingTheCancelValue(Command)
	
	SelectingCancelValueOnServer();
	
EndProcedure

&AtClient
Procedure GoToScanning(Command)
	
	GoToScanningOnServer();
	
EndProcedure

&AtClient
Procedure GoToTheGoodsReceiving(Command)
	
	GoToAcceptanceOfGoodsOnServer()
	
EndProcedure

&AtClient
Procedure GoToThePreviousPage(Command)
	
	GoToPreviousPageOnServer();
	
EndProcedure

&AtClient
Procedure ReturnToTheJob(Command)
	
	BackToRunningTaskOnServer();
	
EndProcedure

&AtClient
Procedure GoToSelectionOfAPickingJob(Command)
	
	GoToSelectingSelectionTaskOnServer();
	
EndProcedure

&AtClient
Procedure GoToSelectionOfAPlacementJob(Command)
	
	GoToTaskSelectionForPlacementOnServer();
	
EndProcedure

&AtClient
Procedure GoToSelectionOfATransferJob(Command)
	
	GoToSelectingMoveJobOnServer();
	
EndProcedure

&AtClient
Procedure GoToSelectionOfARecountJob(Command)
	
	GoToTaskSelectionForRecalculationOnServer();
	
EndProcedure

&AtClient
Procedure GoToSelectionOfAReceivingArea(Command)
	
	GoToServerAcceptanceZoneSelection();
	
EndProcedure

&AtClient
Procedure TasksUpdate(Command)
	
	UpdateTasksOnServer();
	
EndProcedure

&AtClient
Procedure SelectThePlacementAcceptanceZone(Command)
	
	WhenSelectingHostingAcceptanceZoneOnServer();
	
EndProcedure

&AtClient
Procedure CancelTheSelectionOfThePlacementAcceptanceZone(Command)
	
	DeselectHostingAcceptanceZoneOnServer();
	
EndProcedure

&AtClient
Procedure ScanNotShip(Command)
	
	ScanningDoesNotShipToServer();
	
EndProcedure

&AtClient
Procedure ServiceTSTSeriesScanMode(Command)
	
	ServiceScanModeForTSTSeriesOnServer();
	
EndProcedure

&AtClient
Procedure ServiceTBTSeriesScanMode(Command)
	
	ServiceTVTSeriesScanningModeOnServer();
	
EndProcedure

&AtClient
Procedure ServiceProcessingProcedureBinGoods(Command)
	
	ServiceOrderOfProcessingCellItemOnServer();
	
EndProcedure

&AtClient
Procedure ServiceProcessingProcedureGoodsBin(Command)
	
	ServiceOrderOfProductProcessingCellOnServer();
	
EndProcedure

&AtClient
Procedure ScanningService(Command)
	
	ScanningServiceOnServer();
	
EndProcedure

&AtClient
Procedure ScanningToCheckTheBoxToRecalculate(Command)
	
	ScanningMarkCellForRecalculationOnServer();
	
EndProcedure

&AtClient
Procedure ContinueScanningService(Command)
	
	ContinueScanningOnServer();
	
EndProcedure

&AtClient
Procedure GoToWarehouseOperationSelection(Command)
	
	GoToSelectWarehouseOperationOnServer();
	
EndProcedure

&AtClient
Procedure SelectTasks(Command)
	
	TasksToSelectOnServer();
	
EndProcedure

&AtClient
Procedure AbortJobExecution(Command)
	
	CancelTaskOnServer();
	
EndProcedure

&AtClient
Procedure ScanPurpose(Command)
	
	ScanningDestinationOnServer();
	
EndProcedure

&AtClient
Procedure SelectDestinations(Command)
	SelectDestinationsOnServer();
EndProcedure

&AtClient
Procedure AssignmentsSelection(Item, RowSelected, Field, StandardProcessing)
	SelectDestinationsOnServer();
EndProcedure

&AtClient
Procedure DestinationsReturn(Command)
	DestinationsBackOnServer();
EndProcedure

#EndRegion

#Region Private

#Region PlugIns

&AtClient
Procedure Attachable_EnteringNumberOfOKWaitHandler()
	
	EnteringNumberOfOKWaitHandlerOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_SelectingOKValueWaitHandler()
	
	SelectingOKValueWaitHandlerOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_AddressSelectionOKWaitHandler()
	
	AddressSelectionOKWaitHandlerOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_UpdateListOfTasksWaitingHandler()
	
	If WorkplaceOfWarehouseWorkerClient.NeedToUpdateTaskList(ThisForm) Then
		UpdateListOfTasksWaitingHandlerOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_DisplaysStateOfJobExecutionWaitingHandler()
	
	If WorkplaceOfWarehouseWorkerClient.YouNeedToUpdateTaskState(ThisForm) Then
		DisplaysStateOfJobExecutionHandlerWaitingOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region OtherItems

&AtClient
Procedure EnterTheNumberOfTheNumberOnChange(Item)
	
	WorkplaceOfWarehouseWorkerClient.EnterTheNumberOfTheNumberOnChange(ThisForm);
	
EndProcedure

&AtClient
Procedure EnterQuantityWeightOnChange(Item)
	
	WorkplaceOfWarehouseWorkerClient.EnterQuantityWeightOnChange(ThisForm);
	
EndProcedure

&AtClient
Procedure EnterQuantityVolumeOnChange(Item)
	
	WorkplaceOfWarehouseWorkerClient.EnterQuantityVolumeOnChange(ThisForm);
	
EndProcedure

&AtClient
Procedure BarcodeOfTheScanParameterOnChange(Item)
	
	WorkplaceOfWarehouseWorkerClient.BarcodeOfTheScanParameterOnChange(ThisForm);
	
EndProcedure

&AtClient
Procedure StorageBinLocationOnChange(Item)
	
	WorkplaceOfWarehouseWorkerClient.StorageBinLocationOnChange(ThisForm);
	
EndProcedure

&AtClient
Procedure SeriesShelfLifeOnChange(Item)
	
	WorkplaceOfWarehouseWorkerClient.SeriesShelfLifeOnChange(ThisForm);
	
EndProcedure

&AtServer
Procedure MainMenuUpdateOnServer()
	
	WorkplaceOfWarehouseWorkerServer.UpdateMainMenu(ThisForm);
	
EndProcedure

&AtServer
Procedure CreateNewWarehouseJobOnServer()
	
	WorkplaceOfWarehouseWorkerServer.CreateANewWarehouseTask(ThisForm);
	
EndProcedure

&AtServer
Procedure CancelTaskOnServer()
	
	WorkplaceOfWarehouseWorkerServer.CancelJobExecution(ThisForm);
	
EndProcedure

&AtServer
Procedure FinishTaskOnServer()
	
	WorkplaceOfWarehouseWorkerServer.FinishJobExecution(ThisForm);
	
EndProcedure

&AtServer
Procedure GoToPlacingProductsOnServer()
	
	WorkplaceOfWarehouseWorkerServer.WhenCurJobScanIsComplete(ThisForm);
	
EndProcedure

&AtServer
Procedure GoToNextScanLineOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTheNextScanningGoods(ThisForm);
	
EndProcedure

&AtServer
Procedure GoToNextScanCellOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTheNextScanningBin(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanEnterValueOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ScanEnterAValue(ThisForm);
	
EndProcedure

&AtServer
Procedure GoToScanningOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToScanning(ThisForm);
	
EndProcedure

&AtServer
Procedure GoToAcceptanceOfGoodsOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTheGoodsReceiving(ThisForm);
	
EndProcedure

&AtServer
Procedure MainMenuSelectionOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Filter");
	
EndProcedure

&AtServer
Procedure UpdateTasksOnServer()
	
	JobType = ThisForm.ModeSettings.JobType;
	
	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, JobType);
	
EndProcedure

&AtServer
Procedure MainMenuCloseOnServer()
	
	WorkplaceOfWarehouseWorkerServer.MainMenuClose(ThisForm);
	
EndProcedure

&AtServer
Procedure TasksGoToMainMenuOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToWarehouseOperationSelection(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanNextOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ScanNext(ThisForm);
	
EndProcedure

&AtServer
Procedure MainMenuServerInformation()
	
	WorkplaceOfWarehouseWorkerServer.GoToGetInformation(ThisForm);
	
EndProcedure

&AtServer
Procedure MainMenuSelectCellToRecalculateOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToCellMarkToRecalculate(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanningInformationOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToGetInformation(ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateListOfTasksWaitingHandlerOnServer()
	
	WorkplaceOfWarehouseWorkerServer.UpdateListOfTasksWaitingHandler(ThisForm);
	
EndProcedure

&AtServer
Procedure DoNotCloseMobileWorkplaceFormOnServer()
	
	WorkplaceOfWarehouseWorkerServer.DoNotCloseMobileWorkplaceForm(ThisForm);
	
EndProcedure

&AtServer
Procedure CloseInformationOnServer()
	
	WorkplaceOfWarehouseWorkerServer.InformationClose(ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeCloseAtServer(Cancel, StandardProcessing)
	
	WorkplaceOfWarehouseWorkerServer.BeforeClose(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure TasksShowAllOnServer()
	
	WorkplaceOfWarehouseWorkerServer.DisplayAllYourWarehouseJobsOnly(ThisForm);
	
EndProcedure

&AtServer
Procedure TasksToSelectOnServer()
	
	WorkplaceOfWarehouseWorkerServer.WhenSelectingTask(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanningActionOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ScanningAnAction(ThisForm);
	
EndProcedure

&AtServer
Procedure SelectingCancelValueOnServer()
	
	WorkplaceOfWarehouseWorkerServer.SelectingTheCancelValue(ThisForm);
	
EndProcedure

&AtServer
Procedure BackToRunningTaskOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ReturnToTheJob(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanningProductOnServer()
	
	WorkplaceOfWarehouseWorkerServer.DisplayCurProductInformation(ThisForm);
	
EndProcedure

&AtServer
Procedure SelectingOKValueWaitHandlerOnServer()
	
	WorkplaceOfWarehouseWorkerServer.SelectingOKValueWaitHandler(ThisForm);
	
	BarcodeOfTheScanParameter = "";
	SeriesShelfLife = "";
	
EndProcedure

&AtServer
Procedure AddressSelectionOKWaitHandlerOnServer()
	
	WorkplaceOfWarehouseWorkerServer.AddressSelectionOKWaitHandler(ThisForm);
	
	BarcodeOfTheScanParameter = "";
	
EndProcedure

&AtServer
Procedure DisplaysStateOfJobExecutionHandlerWaitingOnServer()
	
	WorkplaceOfWarehouseWorkerServer.DisplayTaskState(ThisForm);
	
EndProcedure

&AtServer
Procedure MainMenuServerPlacement()
	
	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Location");
	
EndProcedure

&AtServer
Procedure MainMenuMoveOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Move");
	
EndProcedure

&AtServer
Procedure MainMenuCheckSelectionOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "PickingCheck");
	
EndProcedure

&AtServer
Procedure MainMenuRecalculationOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Recalculate");
	
EndProcedure

&AtServer
Procedure MainMenuAcceptanceOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Receiving");
	
EndProcedure

&AtServer
Procedure WhenSelectingHostingAcceptanceZoneOnServer()
	
	WorkplaceOfWarehouseWorkerServer.WhenSelectingShipmentAcceptanceZone(ThisForm);
	
EndProcedure

&AtServer
Procedure ListOfSelectionTasksOnServer()
	
	WorkplaceOfWarehouseWorkerServer.WhenSelectingTask(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanEnterQuantityOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ScanToEnterTheNumber(ThisForm);
	
EndProcedure

&AtServer
Procedure EnteringNumberOfOKWaitHandlerOnServer()
	
	WorkplaceOfWarehouseWorkerServer.EnteringNumberOfOKWaitHandler(ThisForm);
	
EndProcedure

&AtServer
Procedure EnteringNumberOfUsersOnServer()
	
	WorkplaceOfWarehouseWorkerServer.EnteringAQuantityCancel(ThisForm);
	
EndProcedure

&AtServer
Procedure GoToSelectWarehouseOperationOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToWarehouseOperationSelection(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanningDoesNotShipToServer()
	
	WorkplaceOfWarehouseWorkerServer.ScanNotShip(ThisForm);
	
EndProcedure

&AtServer
Procedure GoToPreviousPageOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToThePreviousPage(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanningServiceOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ScanningService(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanningMarkCellForRecalculationOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToCellMarkToRecalculate(ThisForm);
	
EndProcedure

&AtServer
Procedure ContinueScanningOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ContinueScanningService(ThisForm);
	
EndProcedure

&AtServer
Procedure DeselectHostingAcceptanceZoneOnServer()

	WorkplaceOfWarehouseWorkerServer.ReturnToTheJob(ThisForm);

EndProcedure

&AtServer
Procedure DisplayBarcodeInformationOnServer(Barcode)
	
	WorkplaceOfWarehouseWorkerServer.DisplayBarcodeInformation(ThisForm, Barcode);
	
EndProcedure

&AtServer
Procedure WhenScanningValueOnServer(Barcode)
	
	WorkplaceOfWarehouseWorkerServer.WhenScanningValue(ThisForm, Barcode, , True);
	
EndProcedure

&AtServer
Procedure WhenScanningJobBarcodeOnServer(Barcode)
	
	WorkplaceOfWarehouseWorkerServer.WhenScanningTaskBarcode(ThisForm, Barcode);
	
EndProcedure

&AtServer
Procedure GoToTaskSelectionForPlacementOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Location");
	
EndProcedure

&AtServer
Procedure GoToSelectingMoveJobOnServer()

	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Move");

EndProcedure

&AtServer
Procedure GoToTaskSelectionForRecalculationOnServer()

	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Recalculate");

EndProcedure

&AtServer
Procedure GoToSelectingSelectionTaskOnServer()

	WorkplaceOfWarehouseWorkerServer.GoToTaskSelection(ThisForm, "Filter");

EndProcedure

&AtServer
Procedure GoToServerAcceptanceZoneSelection()
	
	WorkplaceOfWarehouseWorkerServer.GoToSelectionOfShipmentAcceptanceZone(ThisForm, "ReceivingArea");
	
EndProcedure

&AtServer
Procedure IfHardwareConnectionOnServerFails(ErrorDescription)
	
	WorkplaceOfWarehouseWorkerServer.IfHardwareConnectionFails(ThisForm, ErrorDescription);
	
EndProcedure

&AtServer
Procedure ServiceScanModeForTSTSeriesOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ServiceTSTSeriesScanMode(ThisForm);
	
EndProcedure

&AtServer
Procedure ServiceTVTSeriesScanningModeOnServer()
	
	WorkplaceOfWarehouseWorkerServer.ServiceTBTSeriesScanMode(ThisForm);
	
EndProcedure

&AtServer
Procedure ServiceOrderOfProductProcessingCellOnServer();
	
	WorkplaceOfWarehouseWorkerServer.WhenSettingOrderOfProcessingItemCell(ThisForm);
	
EndProcedure

&AtServer
Procedure ServiceOrderOfProcessingCellItemOnServer()
	
	WorkplaceOfWarehouseWorkerServer.WhenSettingProcessingOrderItemCell(ThisForm);
	
EndProcedure

&AtServer
Procedure ScanningDestinationOnServer()
	
	WorkplaceOfWarehouseWorkerServer.GoToDestinationSelection(ThisForm);
	
EndProcedure

&AtServer
Procedure SelectDestinationsOnServer()
	WorkplaceOfWarehouseWorkerServer.WhenSelectingDestination(ThisForm);
EndProcedure

&AtServer
Procedure DestinationsBackOnServer()
	WorkplaceOfWarehouseWorkerServer.ReturnToTheJob(ThisForm)
EndProcedure

&AtServer
Procedure PickUpProductsFromOtherCellsWhenMovingToNextCellOnServer()
	
	WorkplaceOfWarehouseWorkerServer.SelectGoodsFromOtherBinsWhileTransferringToTheNextBin(ThisForm);
	
EndProcedure

&AtServer
Procedure CancelSelectionOfProductsFromOtherCellsWhenMovingToNextCellOnServer()
	
	WorkplaceOfWarehouseWorkerServer.CancelGoodsPickingFromOtherBinsWhileTransferringToTheNextBin(ThisForm);
	
EndProcedure

&AtServer
Procedure PickUpProductsFromOtherCellsOnServer()
	
	WorkplaceOfWarehouseWorkerServer.SelectGoodsFromOtherBins(ThisForm);
	
EndProcedure

&AtServer
Procedure CancelSelectionOfProductsFromOtherCellsOnServer()
	
	WorkplaceOfWarehouseWorkerServer.CancelGoodsPickingFromOtherBins(ThisForm);
	
EndProcedure

&AtServer
Procedure GetProductsOnServer()
	
	WorkplaceOfWarehouseWorkerServer.AddGoods(ThisForm);
	
EndProcedure

&AtClient
Procedure StartingWarehouseWorkerSWorkplaceIsNotInTaxi(Response, AdditionalParameters) Export 
	
	If Response = DialogReturnCode.OK Then
		
		StartingWarehouseWorkerWorkplaceNotInTaxiTerminatingOnServer();
		Exit(False, True);
		
	Else
		
		Exit(False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartingWarehouseWorkerWorkplaceNotInTaxiTerminatingOnServer()
	
	WorkplaceOfWarehouseWorkerServer.InstallVersion8_2OfClientApplicationInterface(
		InfoBaseUsers.CurrentUser().Name);
		
EndProcedure

&AtClient
Procedure StartConnectingDevicesWhenYouOpenFormCompletion(ExecutionResult, AdditionalParameters) Export

	If Not ExecutionResult.Result Then
		
		IfHardwareConnectionOnServerFails(ExecutionResult.ErrorDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalEquipmentMechanism()
	
	// ExternalEquipmentMechanism
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(
		New CallbackDescription("StartConnectingDevicesWhenYouOpenFormCompletion", ThisObject),
		ThisObject,
		"BarcodeScanner");
	// End ExternalEquipmentMechanism

EndProcedure

#EndRegion

#EndRegion
