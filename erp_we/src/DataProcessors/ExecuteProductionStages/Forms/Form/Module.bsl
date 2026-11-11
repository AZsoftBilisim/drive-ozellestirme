
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UploadFormSettings();
	
	AccessRightStateOfSoftware = AccessRight("Use", Metadata.DataProcessors.OrderSupplyForecast);
	
	#Region MobileClient
	
	IsMobileClient = Common.IsMobileClient();
	
	If IsMobileClient Then
		States1 = New ValueList();
		States1.Add(PredefinedValue("Enum.ShopfloorLevelStagesStates.Initiated"));
		States1.Add(PredefinedValue("Enum.ShopfloorLevelStagesStates.ExecutionIsAllowed"));
		FilterState = States1;
		
		AttributesToBeAdded = New Array;
		AttributesToBeAdded.Add(New FormAttribute("FiltersLine", New TypeDescription("String")));
		AttributesToBeAdded.Add(New FormAttribute("FilterOrderDocument", New TypeDescription("DocumentRef.ProductionOrder2_2")));
		AttributesToBeAdded.Add(New FormAttribute("FilterProduct", New TypeDescription("CatalogRef.Products")));
		AttributesToBeAdded.Add(New FormAttribute("FilterLot", New TypeDescription("CatalogRef.ProductionLots")));
		AttributesToBeAdded.Add(New FormAttribute("FilterStage", New TypeDescription("DocumentRef.ProductionStage2_2")));
		
		ChangeAttributes(AttributesToBeAdded);
		
		ClearFilters        = Commands.Add("ClearFilters");
		Ship           = Commands.Add("Ship");
		ScanBarcode = Commands.Add("ScanBarcode");
		
		ClearFilters.Action = "ClearFilters";
		ClearFilters.Picture = PictureLib.Clear;
		
		Ship.Action = "Ship";
		
		ScanBarcode.Action = "ScanBarcode";
		ScanBarcode.Picture = PictureLib["Barcode"];
		
	EndIf;
	
	#EndRegion
	
	CustomizeList();
	
	#Region UniversalMechanisms
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	CustomizeFormElements();
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
	ConfigureAutomaticUpdatingOfListParameters();
	
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
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetSelectionByDivision(ThisObject);
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure FilterPeriodOnChange(Item)
	
	SetSelectionByPeriod(ThisObject);
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure FilterStateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("FilterStateStartChoiceCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedValues", FilterState);
	
	OpenForm("DataProcessor.ExecuteProductionStages.Form.FilterStates1",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetSelectionByState(ThisObject);
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure FilterSupplyOnChange(Item)
	
	EstablishSecuritySelection(ThisObject);
	SaveFormSettingsClient();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	
	If Field.Name = "PendingSupply" Then
		
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
		
	ElsIf Field.Name = "OperationStatusCode" Then
		
		If Not CurrentData.OperationStatus.IsEmpty()
			And Not CurrentData.ItIsRequiredToPopulateByOperationsManually Then
			
			StandardProcessing = False;
			
			ProductionManagementClient.DecodeStateOfStageOperations(
				CurrentData.Ref,
				CurrentData.OperationStatus,
				ThisForm);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	DetachIdleHandler("Attachable_UpdateSoftwareCommands");
	AttachIdleHandler("Attachable_UpdateSoftwareCommands", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MarkAsStarted(Command)
	
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
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã bắt đầu';
																												|ru = 'Начат';
																												|en = 'Started'; fa = 'شروع‌شده';
																												|it = 'Начат';
																												|pl = 'Started';
																												|tr = 'Başlatıldı'"));
	
EndProcedure

&AtClient
Procedure MarkCompleted(Command)
	
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
Procedure RegisterEmployeeOutput(Command)
	
	SelectedRows = SelectedStages();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ReferencesArrray = StagesForDesignOfDevelopment(SelectedRows);
	If ReferencesArrray.Count() > 0 Then
		ProductionAccountingClient.IssueDevelopmentOfEmployeesOnOrders(ReferencesArrray);
	Else
		WarningText = NStr("vi = 'Không cần tạo sản lượng của nhân viên cho các công đoạn được chọn.';
							|ru = 'Не требуется оформлять выработку сотрудников для выбранных этапов.';
							|en = 'It is not required to register timesheets charge for the selected stages.'; fa = 'It is not required to register timesheets charge for the selected stages.';
							|it = 'Non è richiesta la formalizzazione della produttività dei dipendenti per le fasi selezionate.';
							|pl = 'Nie należy zatwierdzać generację produkcji pracowników do wybranych etapów.';
							|tr = 'Seçili aşamalar için zaman çizelgesi bazlı ücretlendirmenin düzenlenmesi gerekli değildir.'");
		ShowMessageBox(,WarningText);
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
Procedure StateOfSoftwareDynamicStructure(Command)
	
	DocumentsArray = Items.List.SelectedRows;
	
	If DocumentsArray.Count() > 0 Then
		
		OpenSupplyForecastStatusForDynamicStructureStages(DocumentsArray);
		
	EndIf;
	
EndProcedure

#If MobileClient Then

&AtClient
Procedure Ship(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_LOAD",
		Items.List,
		PredefinedValue("Document.ProductionStage2_2.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_FiltersLineClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	
	FormParameters.Insert("FilterState",FilterState);
	FormParameters.Insert("FilterSupply",FilterSupply);
	FormParameters.Insert("Department",FilterDepartment);
	FormParameters.Insert("OrderDocument", ThisForm["FilterOrderDocument"]);
	FormParameters.Insert("Product", ThisForm["FilterProduct"]);
	FormParameters.Insert("Lot", ThisForm["FilterLot"]);
	FormParameters.Insert("Stage", ThisForm["FilterStage"]);
	FormParameters.Insert("Period",FilterPeriod);
	
	OpenForm("DataProcessor.ExecuteProductionStages.Form.MobileApplicationFiltersSetting",
		FormParameters,
		ThisForm,
		,
		,
		,
		New CallbackDescription("FiltersLineClickCompletion",ThisObject));
	
EndProcedure

&AtClient
Procedure FiltersLineClickCompletion(FilterParameters, AdditionalParameters) Export
	
	If TypeOf(FilterParameters) <> Type("Structure") Then
		Return;
	EndIf;
	
	ArrayOfSelectionStrings = New Array();
	
	If FilterParameters.Property("ExecutionIsAllowed") And FilterParameters.Property("Initiated") Then
		
		States1 = New ValueList();
		
		If FilterParameters.ExecutionIsAllowed Then
			States1.Add(PredefinedValue("Enum.ShopfloorLevelStagesStates.Initiated"));
			States1.Add(PredefinedValue("Enum.ShopfloorLevelStagesStates.ExecutionIsAllowed"));
		EndIf;
		
		If FilterParameters.Initiated Then
			States1.Add(PredefinedValue("Enum.ShopfloorLevelStagesStates.Initiated"));
		EndIf;
		
		FilterState = States1;
		
	EndIf;
	
	SetSelectionByState(ThisForm);
	
	If FilterParameters.Property("OnlyTheWellOff") And FilterParameters.OnlyTheWellOff Then
		FilterSupply= "MaterialsAreProvided";
		ArrayOfSelectionStrings.Add("Only secured");
	Else
		FilterSupply = "";
	EndIf;
	
	EstablishSecuritySelection(ThisForm);
	
	For Each KeyAndValue In FilterParameters Do
		
		If StrFind(KeyAndValue.Key, "Filter") > 0 Then
			ThisForm[KeyAndValue.Key] = KeyAndValue.Value;
			
			If ValueIsFilled(KeyAndValue.Value) Then
				ArrayOfSelectionStrings.Add(KeyAndValue.Value);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	SetSelectionByDivision(ThisForm);
	
	SetSelectionByOrder();
	
	SetSelectionByProduct();
	
	SetSelectionByBatch();
	
	SetSelectionByStage();
	
	SetSelectionByPeriod(ThisForm);
	
	If ArrayOfSelectionStrings.Count() > 0 Then
		ThisForm["FiltersLine"] = StrConcat(ArrayOfSelectionStrings, ", ");
	Else
		ThisForm["FiltersLine"] = NStr("vi = 'Đặt bộ lọc';
										|ru = 'Установить отборы';
										|en = 'Set filters'; fa = 'تعیین فیلترها';
										|it = 'Impostare le selezioni';
										|pl = 'Ustaw filtr';
										|tr = 'Filtreleri yapılandır'") + ?(FilterState.Count() > 0, "*", "");
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearFilters(Command)
	
	FilterSupply   = Undefined;
	FilterPeriod        = Undefined;
	FilterDepartment = Undefined;
	
	FilterState = New ValueList();
	
	ThisForm["FilterOrderDocument"]   = Undefined;
	ThisForm["FilterProduct"] = Undefined;
	ThisForm["FilterLot"]  = Undefined;
	ThisForm["FilterStage"]    = Undefined;

	ThisForm["FiltersLine"] = NStr("vi = 'Đặt bộ lọc';
									|ru = 'Установить отборы';
									|en = 'Set filters'; fa = 'تعیین فیلترها';
									|it = 'Impostare le selezioni';
									|pl = 'Ustaw filtr';
									|tr = 'Filtreleri yapılandır'");
	
	SetSelectionByDivision(ThisForm);
	SetSelectionByPeriod(ThisForm);
	SetSelectionByState(ThisForm);
	EstablishSecuritySelection(ThisForm);
	
	SetSelectionByOrder();
	SetSelectionByProduct();
	SetSelectionByBatch();
	SetSelectionByStage();
	
EndProcedure

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

#Region Universal_

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

#Region Private

#Region ListSettings

&AtClientAtServerNoContext
Procedure SetCurDateListParameter(Form)
	
	#If Client Then
		
		ParameterValue = CommonClient.SessionDate();
		
	#Else
		
		ParameterValue = CurrentSessionDate();
		
	#EndIf
	
	Form.List.Parameters.SetParameterValue(
		"CurrentDate",
		ParameterValue);
	
EndProcedure

&AtClient
Procedure ConfigureAutomaticUpdatingOfListParameters()
	
	If Items.List.AutoRefresh Then
		UpdateInterval = Items.List.AutoRefreshPeriod;
	Else
		UpdateInterval = 3600;
	EndIf;
	AttachIdleHandler("UpdateListParameters", UpdateInterval);
	
EndProcedure

&AtClient
Procedure UpdateListParameters()
	
	SetCurDateListParameter(ThisObject);
	
EndProcedure

&AtServer
Procedure CustomizeList()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = StrReplace(
		List.QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("StagesOverridable"));
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	List.Parameters.SetParameterValue(
		"ScheduleStatus",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	SetCurDateListParameter(ThisObject);
	
	// Filters
	If ValueIsFilled(FilterDepartment) Then
		SetSelectionByDivision(ThisObject);
	EndIf;
	
	If ValueIsFilled(FilterPeriod)
		And ProductionManagementCached.TheProductionScheduleIsUsed() Then
		SetSelectionByPeriod(ThisObject);
	EndIf;
	
	If ValueIsFilled(FilterState) Then
		SetSelectionByState(ThisObject);
	EndIf;
	
	If ValueIsFilled(FilterSupply) Then
		EstablishSecuritySelection(ThisObject);
	EndIf;
	
	// Order
	List.Order.Items.Clear();
	
	If ProductionManagementCached.TheProductionScheduleIsUsed() Then
		
		ListOrder = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("StatusCode");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
		ListOrder = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("Begin");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("NextStageStart");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
	Else
		
		ListOrder = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("StatusCode");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
		ListOrder = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("OrderPriority_3");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("DivisionPriority");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("OrderQueue");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("DurationBeforeProductionIssue");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormSettings

&AtServer
Procedure UploadFormSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		FormKey(),
		FormSettingsKey());
	
	If TypeOf(Settings) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, Settings);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveFormSettingsClient()
	
	Settings = New Structure;
	Settings.Insert("FilterDepartment", FilterDepartment);
	Settings.Insert("FilterState", FilterState);
	Settings.Insert("FilterSupply", FilterSupply);
	Settings.Insert("FilterPeriod", FilterPeriod);
	
	SaveFormSettingsServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveFormSettingsServer(Settings)
	
	Common.CommonSettingsStorageSave(
		FormKey(),
		FormSettingsKey(),
		Settings);
	
EndProcedure

&AtClientAtServerNoContext
Function FormKey()
	
	Return "DataProcessor.ExecuteProductionStages.Form";
	
EndFunction

&AtClientAtServerNoContext
Function FormSettingsKey()
	
	Return "Main_";
	
EndFunction

#EndRegion

#Region Supply

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

&AtClient
Procedure Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders()
	ProvisionInDocumentsClient.CheckWhetherInventoryAllocationTaskIsCompletedForOrders(ThisObject, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateSoftwareCommands()
	
	CurrentData = Items.List.CurrentData;
	ListLineIsHighlighted = CurrentData <> Undefined
		And TypeOf(Items.List.CurrentRow) <> Type("DynamicListGroupRow");
	
	Items.SupplyForecastOfOrderList.Visible = ListLineIsHighlighted
		And Not CurrentData.DynamicStructure
		And AccessRightStateOfSoftware;
		
	Items.ListStateOfSoftwareDynamicStructure.Visible = ListLineIsHighlighted
		And CurrentData.DynamicStructure
		And AccessRightStateOfSoftware;
	
EndProcedure

&AtClient
Procedure OpenSoftwareState(RowSelected)
	
	FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("ORDERLIST");
	FormParameters.Orders = CommonClientServer.ValueInArray(RowSelected);
	
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	#Region ScheduleDates
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Begin.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Ending.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NextStageStart.Name);
	
	Item.Appearance.SetParameterValue(
		"Format",
		ProductionManagement.FormatStringForProductionScheduleDate());
	
	#EndRegion
	
	#Region NotPredecessorsAreCompleted
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ShopfloorLevelStagesStates.PendingPredecessorCompletion);
	ValueList.Add(Enums.ShopfloorLevelStagesStates.PreviousOnesStarted);
	
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	#EndRegion
	
	#Region StageOverdue
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Ending.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Overdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue(
		"TextColor",
		StyleColors.TextColorIssue);
	
	#EndRegion
	
	#Region MobileClient
	
	If Common.IsMobileClient() Then
		
		Item = List.ConditionalAppearance.Items.Add();
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("State");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ShopfloorLevelStagesStates.Completed;
		
		Item.Appearance.SetParameterValue(
			"TextColor",
			StyleColors.GrayTextColor1);
		
		Item = List.ConditionalAppearance.Items.Add();
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("State");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		
		ValueList = New ValueList;
		ValueList.Add(Enums.ShopfloorLevelStagesStates.PendingPredecessorCompletion);
		ValueList.Add(Enums.ShopfloorLevelStagesStates.PreviousOnesStarted);
		
		ItemFilter.RightValue = ValueList;
		
		Item.Appearance.SetParameterValue(
			"TextColor",
			StyleColors.GrayTextColor2);
		
		Item = List.ConditionalAppearance.Items.Add();
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("State");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ShopfloorLevelStagesStates.ExecutionIsAllowed;
		
		Item.Appearance.SetParameterValue(
			"TextColor",
			StyleColors.TextColorSuccess);
		
		Item = List.ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.State.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("State");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.ShopfloorLevelStagesStates.Completed;
		
		Item.Appearance.SetParameterValue(
			"Text",
			"");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByDivision(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Department", 
		Form.FilterDepartment, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterDepartment));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByPeriod(Form)
	
	If ValueIsFilled(Form.FilterPeriod.StartDate) Then
		
		Items_Group = CommonClientServer.CreateFilterItemGroup(
			Form.List.Filter.Items,
			"GroupBegin",
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"Begin", 
			DataCompositionComparisonType.GreaterOrEqual, 
			Form.FilterPeriod.StartDate);
			
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"Begin", 
			DataCompositionComparisonType.NotFilled);
			
	Else
		
		CommonClientServer.DeleteFilterItems(
			Form.List.Filter,
			"Begin");
		
	EndIf;
	
	If ValueIsFilled(Form.FilterPeriod.EndDate) Then
		
		Items_Group = CommonClientServer.CreateFilterItemGroup(
			Form.List.Filter.Items,
			"EndGroup",
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"Ending", 
			DataCompositionComparisonType.LessOrEqual, 
			Form.FilterPeriod.EndDate);
			
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"Ending", 
			DataCompositionComparisonType.NotFilled);
			
	Else
		
		CommonClientServer.DeleteFilterItems(
			Form.List.Filter,
			"Ending");
			
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterStateStartChoiceCompletion(ClosingResult, AdditionalParameters) Export
	
	If Not ClosingResult = Undefined Then
		
		FilterState = ClosingResult;
		SetSelectionByState(ThisObject);
		SaveFormSettingsClient();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByState(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"State", 
		Form.FilterState, 
		DataCompositionComparisonType.InList,
		, 
		ValueIsFilled(Form.FilterState));
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishSecuritySelection(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"SupplyState", 
		Form.FilterSupply,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterSupply));
	
EndProcedure

&AtClient
Procedure SetSelectionByOrder()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref.ReferenceOrder", 
		ThisForm["FilterOrderDocument"], 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(ThisForm["FilterOrderDocument"]));
	
EndProcedure

&AtClient
Procedure SetSelectionByProduct()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref.ProductionLot.MainProductProducts", 
		ThisForm["FilterProduct"], 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(ThisForm["FilterProduct"]));
	
EndProcedure

&AtClient
Procedure SetSelectionByBatch()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref.ProductionLot", 
		ThisForm["FilterLot"], 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(ThisForm["FilterLot"]));
	
EndProcedure

&AtClient
Procedure SetSelectionByStage()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref", 
		ThisForm["FilterStage"], 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(ThisForm["FilterStage"]));
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	GraphIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	
	Items.FilterPeriod.Visible = GraphIsUsed;
	Items.Begin.Visible = GraphIsUsed;
	Items.Ending.Visible = GraphIsUsed;
	Items.NextStageStart.Visible = GraphIsUsed;
	Items.CalculationIsRequired.Visible = GraphIsUsed;
	
	OperationsAreUsed = GetFunctionalOption("UseOperationManagement") Or GetFunctionalOption("UseManufacturingExecutionSystem");
	
	Items.OperationStatus.Visible = OperationsAreUsed;
	Items.OperationStatusCode.Visible = OperationsAreUsed;
	Items.FormPerformingOperations.Visible = OperationsAreUsed;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	AttributesList - String
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	
	If Initialize And Form.IsMobileClient Then
		
		//List commands
		Items.MarkAsStarted.Title = NStr("vi = 'Bắt đầu';
										|ru = 'Начать';
										|en = 'Start'; fa = 'شروع';
										|it = 'Avvia';
										|pl = 'Rozpocznij';
										|tr = 'Başlat'");
		Items.MarkCompleted.Title = NStr("vi = 'Kết thúc';
										|ru = 'Завершить';
										|en = 'Finish'; fa = 'پایان';
										|it = 'Completare';
										|pl = 'Zakończ';
										|tr = 'Tamamla'");
		
		StartElement_ = Items.Add("ToBegin",Type("FormButton"), Items.List.ContextMenu);
		StartElement_.Title = NStr("vi = 'Bắt đầu';
									|ru = 'Начать';
									|en = 'Start'; fa = 'شروع';
									|it = 'Avvia';
									|pl = 'Rozpocznij';
									|tr = 'Başlat'");
		StartElement_.CommandName = "MarkAsStarted";
		
		CompleteElement = Items.Add("ExitApp",Type("FormButton"), Items.List.ContextMenu);
		CompleteElement.Title = NStr("vi = 'Kết thúc';
									|ru = 'Завершить';
									|en = 'Finish'; fa = 'پایان';
									|it = 'Completare';
									|pl = 'Zakończ';
									|tr = 'Tamamla'");
		CompleteElement.CommandName = "MarkCompleted";
		
		ShipElement = Items.Add("Ship",Type("FormButton"));
		ShipElement.CommandName = "Ship";
		
		ShipElementCommandBar = Items.Add("ShipCommandBar",Type("FormButton"), Items.MainActions);
		ShipElementCommandBar.Title = NStr("vi = 'Giao hàng';
											|ru = 'Отгрузить';
											|en = 'Ship'; fa = 'ارسال';
											|it = 'Da spedire';
											|pl = 'Ship';
											|tr = 'Sevk et'");
		ShipElementCommandBar.Type = FormButtonType.CommandBarButton;
		ShipElementCommandBar.CommandName = "Ship";
		
		ItemArray = New Array();
		ItemArray.Add(ShipElement);
		ItemArray.Add(StartElement_);
		ItemArray.Add(CompleteElement);
		ItemArray.Add(Items.ActionsOther);
		ItemArray.Add(Items.CreateBasedOnSubmenu);
		ItemArray.Add(Items.PrintSubmenu);
		ItemArray.Add(Items.ReportsSubmenu);
		ItemArray.Add(Items.FormPerformingOperations);
		
		For Each Item In ItemArray Do
			Items.Move(Item,Items.List.ContextMenu, Items.ListContextMenuChange);
		EndDo;
		
		//List box
		Items.RegisterOutput.Visible     = False;
		Items.CalculationIsRequired.Visible       = False;
		Items.OperationStatusCode.Visible  = False;
		Items.PendingSupply.Visible  = False;
		Items.Ending.Visible             = False;
		Items.NextStageStart.Visible = False;
		
		Items.State.ShowInHeader               = False;
		Items.ProductUnitOfMeasurement.ShowInHeader = False;
		
		Items.Move(Items.Begin, Items.List);
		Items.Move(Items.State, Items.List, Items.Begin);
		
		Items.Products_.Title = NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'");
		
		Products = Items.Add("Products", Type("FormField"), Items.List);
		Products.DataPath = "List.Ref.ProductionLot.MainProductProducts";
		Products.Title = NStr("vi = 'Mặt hàng';
								|ru = 'Номенклатура';
								|en = 'Item'; fa = 'قلم';
								|it = 'Articolo';
								|pl = 'Pozycja';
								|tr = 'Öğe'");
		Items.Move(Products, Items.List, Items.Products_);
		
		Characteristic = Items.Add("Characteristic", Type("FormField"), Items.List);
		Characteristic.DataPath = "List.Ref.ProductionLot.MainProductCharacteristic";
		Characteristic.Title = NStr("vi = 'Đặc tính';
									|ru = 'Характеристика';
									|en = 'Variant'; fa = 'گونه';
									|it = 'Caratteristica';
									|pl = 'Charakterystyka';
									|tr = 'Varyant'");
		Items.Move(Characteristic, Items.List, Items.Products_);
		
		//Filters
		For Each Filter In Items.GroupFilters.ChildItems Do
			Filter.Visible = False;
		EndDo; 
		
		Items.GroupFilters.Group = ChildFormItemsGroup.AlwaysHorizontal;
		
		Form["FiltersLine"] = NStr("vi = 'Đặt bộ lọc';
									|ru = 'Установить отборы';
									|en = 'Set filters'; fa = 'تعیین فیلترها';
									|it = 'Impostare le selezioni';
									|pl = 'Ustaw filtr';
									|tr = 'Filtreleri yapılandır'") + ?(Form.FilterState.Count() > 0, "*", "");
		FiltersLine = Items.Add("FiltersLine",Type("FormField"),Items.GroupFilters);
		FiltersLine.Type = FormFieldType.LabelField;
		FiltersLine.DataPath = "FiltersLine";
		FiltersLine.TitleLocation = FormItemTitleLocation.None;
		FiltersLine.Hyperlink = True;
		FiltersLine.TextColor = WebColors.Green;
		FiltersLine.SetAction("Click", "Attachable_FiltersLineClick");
		
		ItemResetSelections = Items.Add("ClearFilters",Type("FormButton"),Items.GroupFilters);
		ItemResetSelections.CommandName = "ClearFilters";
		ItemResetSelections.Representation = ButtonRepresentation.Picture;
		
		ItemScanBarcode = Items.Add("ScanBarcode",Type("FormButton"),Items.GroupFilters);
		ItemScanBarcode.CommandName = "ScanBarcode";
		ItemScanBarcode.Representation = ButtonRepresentation.Picture;
		
	EndIf;
	
EndProcedure

&AtClient
Function StagesForDesignOfDevelopment(SelectedRows)
	
	Result = New Array;
	
	For Each String In SelectedRows Do
		
		RowData = Items.List.RowData(String);
		
		If RowData.RegisterOutput Then
			
			Result.Add(RowData.Ref);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

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

&AtClient
Procedure ProcessBarcodes(Data)
	
	Ref = LinkToListItemByBarcode(Data.Barcode);
	If Ref <> Undefined Then
		Items.List.CurrentRow = Ref;
		If Items.List.CurrentRow = Undefined Then
			ShowValue(Undefined, Ref);
		EndIf;
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Return ProductionManagementClient.LinkToProductionStageByBarcode(Barcode);
	
EndFunction

&AtClient
Procedure FillInSelectionForm(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionStage2_2.EmptyRef"));
	Managers.Add(PredefinedValue("Document.ProductionOrder2_2.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.ProductionLots.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.Products.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	
	References = BarcodingOfPrintFormsServerCall.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
	Ref = Undefined;
	If References.Count() > 0 Then
		Ref = References[0];
	EndIf;
	
	If TypeOf(Ref) = Type("CatalogRef.BusinessStructure") Then
		
		FilterDepartment = Ref;
		SetSelectionByDivision(ThisForm);
		
	ElsIf TypeOf(Ref) = Type("DocumentRef.ProductionOrder2_2") Then
		
		ThisForm["FilterOrderDocument"] = Ref;
		SetSelectionByOrder();
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.Products") Then
		
		ThisForm["FilterProduct"] = Ref;
		SetSelectionByProduct();
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.ProductionLots") Then
		
		ThisForm["FilterLot"] = Ref;
		SetSelectionByBatch();
		
	ElsIf TypeOf(Ref) = Type("DocumentRef.ProductionStage2_2") Then
		
		ThisForm["FilterStage"] = Ref;
		SetSelectionByStage();
		
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
	
	Filters = "FilterDepartment,FilterOrderDocument,FilterProduct,FilterLot,FilterStage";
	Filters = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Filters, ",");
	
	ArrayOfSelectionStrings = New Array();
	
	For Each Filter In Filters Do
		If ValueIsFilled(ThisForm[Filter]) Then
			ArrayOfSelectionStrings.Add(ThisForm[Filter]);
		EndIf;
	EndDo;
	
	If ArrayOfSelectionStrings.Count() > 0 Then
		ThisForm["FiltersLine"] = StrConcat(ArrayOfSelectionStrings, ", ");
	Else
		ThisForm["FiltersLine"] = NStr("vi = 'Đặt bộ lọc';
										|ru = 'Установить отборы';
										|en = 'Set filters'; fa = 'تعیین فیلترها';
										|it = 'Impostare le selezioni';
										|pl = 'Ustaw filtr';
										|tr = 'Filtreleri yapılandır'") + ?(FilterState.Count() > 0, "*", "");
	EndIf;
	
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

#EndRegion
