&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	DataProcessor = FormAttributeToValue("Object");
	
	CurrentSessionDate = CurrentSessionDate();
	DisplayOrdersForRegistration = True;
	DynamicStructure = GetFunctionalOption("DynamicStructureOfProductionOrders");
	UseProcessType = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	If Not UseSeveralWarehouses Then
		DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	EndIf;
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	RestoreSettings();
	
	If Not ValueIsFilled(Object.ProductionScheduling) Then
		Object.ProductionScheduling = PredefinedValue("Enum.WayOfLinkingProductionOperations.Backward");
	EndIf;
	
	If Not UseProcessType Then
		Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly;
	EndIf;
	Object.Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	ScenarioData = ScriptDetailsValues(Object.Scenario);
	FillPropertyValues(ThisObject, ScenarioData);
	
	If Not ScenarioData.UseForMaterialsPlanning Then
		Object.GenerateOrdersByUpToDateBillsOfMaterials = True;
		Items.GenerateOrdersByUpToDateBillsOfMaterials.Enabled = False;
	EndIf;
	
	ModeForCalculatingNeedsOfPlanWhenChangingOnServer();
	
	BringDatesToPeriodicityOfScript(ThisObject, Object.PeriodBeginning, Object.PeriodEnd);
	
	SetFormItemsVisibility();
	VisibilitySettingsWhenChangingSubdividingSelectionOnServer(ThisForm);
	VisibilitySettingsWhenChangingScript(ThisForm);
	VisibilitySettingsWhenChangingProcessType(ThisForm);
	VisibilitySettingsUseProductionManagement2_2();
	
	FillInCalculationModeSelectionList(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetFormHeader(Items.PagesMainPanel.CurrentPage);
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("Structure")
		And (ValueSelected.Property("SplitOrdersByAssignments")
		Or ValueSelected.Property("SplitOrdersByWarehouses")
		Or ValueSelected.Property("SplitOrdersByReleaseLaunchDates")) Then
		
		FillPropertyValues(ThisForm, ValueSelected);
		
		SetFormItemsVisibility();
		If DisplayOrdersForRegistration Then
			UpdateOrderCart();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionOrder"  And Items.PagesMainPanel.CurrentPage = Items.PageStep2 Then
		
		DocumentListForUpdate.Add(Parameter);
		UpdateDataWhenFormBecomesActive();
		
	ElsIf EventName = "EstablishedSelection_FormationOfOrdersForProductionAccordingToPlan" Then
		
		UpdateAtServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes  Then
		
		UpdateAtServer();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ScenarioOnChange(Item)
	
	ScenarioData = ScriptDetailsValues(Object.Scenario);
	FillPropertyValues(ThisObject, ScenarioData);
	
	If Not ScenarioData.UseForMaterialsPlanning Then
		Object.GenerateOrdersByUpToDateBillsOfMaterials = True;
		Items.GenerateOrdersByUpToDateBillsOfMaterials.Enabled = False;
	Else
		Object.GenerateOrdersByUpToDateBillsOfMaterials = False;
		Items.GenerateOrdersByUpToDateBillsOfMaterials.Enabled = True;
	EndIf;
	
	BringDatesToPeriodicityOfScript(ThisObject, Object.PeriodBeginning, Object.PeriodEnd);
	
	If Not PlanningByAssignments Then
		Purpose = Undefined
	EndIf;
	
	VisibilitySettingsWhenChangingScript(ThisForm);
	
EndProcedure

&AtClient
Procedure DemandCalculationModeByPlanOnChange(Item)
	
	ModeForCalculatingNeedsOfPlanWhenChangingOnServer();
	
EndProcedure

//To oldparent
&AtServer
Procedure ModeForCalculatingNeedsOfPlanWhenChangingOnServer()
	
	InitializeSettingsComposer();
	
	If Object.DemandCalculationModeByPlan < 2 Then
		Items.PeriodEnd.Enabled = True;
		Items.SetPeriodInterval.Enabled = True;
	Else
		Items.PeriodEnd.Enabled = False;
		Items.SetPeriodInterval.Enabled = False;
		
		Object.PeriodEnd = PlanningClientServerCached.CalculatePeriodEndDate(CurrentSessionDate, Periodicity);
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodBeginningOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	BringDatesToPeriodicityOfScript(ThisObject, Object.PeriodBeginning, Object.PeriodEnd);
	
EndProcedure

&AtClient
Procedure PeriodEndOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	BringDatesToPeriodicityOfScript(ThisObject, Object.PeriodBeginning, Object.PeriodEnd);
	
EndProcedure

&AtClient
Procedure FilterDepartmentsOnChange(Item)
	
	VisibilitySettingsWhenChangingSubdividingSelectionOnServer(ThisForm); 
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	VisibilitySettingsWhenChangingSubdividingSelectionOnServer(ThisForm); 
	
EndProcedure

&AtClient
Procedure ProductionProcessTypeOnChange(Item)
	
	ThisIsDisassembly = Object.ProductionProcessType = PredefinedValue(
		"Enum.ProductionProcessTypes.Disassembly");
	
	VisibilitySettingsWhenChangingProcessType(ThisForm);
	
	FillInCalculationModeSelectionList(ThisForm);
	
	InitializeSettingsComposer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGenerationOfOrders

&AtClient
Procedure GenerationOfOrdersBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure OrderGenerationQuantityWhenChanging(Item)
	
	CurrentRow = Items.GenerationOfOrders.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersPackageOnChange(Item)
	
	CurrentRow = Items.GenerationOfOrders.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersQuantityInOrdersStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersQuantityInOrdersClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersQuantityInPlansStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersQuantityInPlansClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersQuantityInPlansOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurRow = Items.GenerationOfOrders.CurrentData;
	
	RowKey = New Structure();
	RowKey.Insert("Products", 	CurRow.Products);
	RowKey.Insert("Characteristic", 	CurRow.Characteristic);
	RowKey.Insert("Purpose", 		CurRow.Purpose);
	RowKey.Insert("BillOfMaterials", 	CurRow.BillOfMaterials);
	RowKey.Insert("BeginOfPeriod", 	?(ThisIsDisassembly, CurRow.OrderDate, CurRow.ProductionIssuePeriodStart));
	RowKey.Insert("PeriodEnding", EndOfDay(?(ThisIsDisassembly, CurRow.OrderPeriodEnd, CurRow.DateOfProduction)));
	
	If CurRow.EditBusinessUnit Then
		RowKey.Insert("Department", 	PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	Else
		RowKey.Insert("Department", 	CurRow.ProductionDispatcherBusinessUnit);
	EndIf;
	
	RowKey.Insert("Scenario", 		Object.Scenario);
	
	If Object.DemandCalculationModeByPlan > 1 Then
		DocumentsList = ListOfPlansIsCumulativeByLine(RowKey);
	Else
		DocumentsList = ListOfPlansByLine(RowKey);
	EndIf;
	
	CallbackDescription = New CallbackDescription("SelectingPlanDocumentFromList", ThisObject);
	DocumentsList.ShowChooseItem(CallbackDescription, NStr("vi = 'Hãy chọn chứng từ';
															|ru = 'Выберите документ';
															|en = 'Select document'; fa = 'انتخاب سند';
															|it = 'Selezionare documento';
															|pl = 'Wybierz dokument';
															|tr = 'Belge seçin'"));
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersQuantityInOrdersOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurRow = Items.GenerationOfOrders.CurrentData;
	
	RowKey = New Structure();
	RowKey.Insert("Products", 	CurRow.Products);
	RowKey.Insert("Characteristic", 	CurRow.Characteristic);
	RowKey.Insert("BillOfMaterials", 	CurRow.BillOfMaterials);
	RowKey.Insert("Purpose", 		CurRow.Purpose);
	RowKey.Insert("BeginOfPeriod",    ?(ThisIsDisassembly, CurRow.OrderDate, CurRow.ProductionIssuePeriodStart));
	RowKey.Insert("PeriodEnding", EndOfDay(?(ThisIsDisassembly, CurRow.OrderPeriodEnd, CurRow.DateOfProduction)));
	RowKey.Insert("DateOfProduction",      CurRow.DateOfProduction);
	RowKey.Insert("OrderDate",       CurRow.OrderDate);
	RowKey.Insert("ProductionIssuePeriodStart",   CurRow.ProductionIssuePeriodStart);
	RowKey.Insert("OrderPeriodEnd", CurRow.OrderPeriodEnd);
	
	If CurRow.EditBusinessUnit Then
		RowKey.Insert("Department", PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	Else
		RowKey.Insert("Department", CurRow.ProductionDispatcherBusinessUnit);
	EndIf;
	
	If Object.DemandCalculationModeByPlan > 1 Then
		DocumentsList = ListOfOrdersByRow(RowKey);
	Else
		DocumentsList = ListOfOrdersByLine(RowKey);
	EndIf;
	
	CallbackDescription = New CallbackDescription("SelectingOrderDocumentFromList", ThisObject);
	DocumentsList.ShowChooseItem(CallbackDescription, NStr("vi = 'Hãy chọn chứng từ';
															|ru = 'Выберите документ';
															|en = 'Select document'; fa = 'انتخاب سند';
															|it = 'Selezionare documento';
															|pl = 'Wybierz dokument';
															|tr = 'Belge seçin'"));
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersSelectToOrderOnChange(Item)
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersDepartmentOnChange(Item)
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersProductionDispatcherBusinessUnitStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);

	RowKey = New Structure;
	RowKey.Insert("Products",					TableRow.Products);
	RowKey.Insert("Characteristic",				TableRow.Characteristic);
	RowKey.Insert("BillOfMaterials",					TableRow.BillOfMaterials);
	If ThisIsDisassembly Then
		RowKey.Insert("OrderDate",				TableRow.OrderDate);
		RowKey.Insert("OrderPeriodEnd",	TableRow.OrderPeriodEnd);
	Else
		RowKey.Insert("ProductionIssuePeriodStart", 	TableRow.ProductionIssuePeriodStart);
		RowKey.Insert("DateOfProduction",				TableRow.DateOfProduction);
	EndIf;
	RowKey.Insert("EditBusinessUnit",	False);
	
	LinkIsNotInList = New Array;
	Rows = TableOrderGeneration.FindRows(RowKey);
	For Each String In Rows Do
		LinkIsNotInList.Add(String.ProductionDispatcherBusinessUnit);
	EndDo;
	
	Filter = New Structure("ProductionDispatcherBusinessUnit", True);
	
	Notification = New CallbackDescription("FillInDispatcherDepartmentCompletion", 
		ThisObject, 
		New Structure("SelectedRows", Items.GenerationOfOrders.SelectedRows));
	OpenForm("Catalog.BusinessStructure.ChoiceForm", 
		New Structure("Key, Filter, LinkIsNotInList", TableRow.ProductionDispatcherBusinessUnit, Filter, LinkIsNotInList),
		,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure GenerationOfOrdersProductionDispatcherBusinessUnitChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);

	RowKey = New Structure;
	RowKey.Insert("Products",					TableRow.Products);
	RowKey.Insert("Characteristic",				TableRow.Characteristic);
	RowKey.Insert("BillOfMaterials",					TableRow.BillOfMaterials);
	If ThisIsDisassembly Then
		RowKey.Insert("OrderDate",				TableRow.OrderDate);
		RowKey.Insert("OrderPeriodEnd",	TableRow.OrderPeriodEnd);
	Else
		RowKey.Insert("ProductionIssuePeriodStart", 	TableRow.ProductionIssuePeriodStart);
		RowKey.Insert("DateOfProduction",				TableRow.DateOfProduction);
	EndIf;
	RowKey.Insert("EditBusinessUnit",	False);
	
	LinkIsNotInList = New Array;
	Rows = TableOrderGeneration.FindRows(RowKey);
	For Each String In Rows Do
		If ValueSelected = String.ProductionDispatcherBusinessUnit Then
			StandardProcessing = False;
			ShowMessageBox(, NStr("vi = 'Có kế hoạch cho các đơn vị được lựa chọn.';
									|ru = 'По выбранному подразделению есть планы.';
									|en = 'There are plans by the selected business unit.'; fa = 'There are plans by the selected business unit.';
									|it = 'Nel reparto selezionato sono presenti i piani.';
									|pl = 'Według wybranego działu są plany.';
									|tr = 'Seçili departmana göre planlar mevcut.'"));
			Return;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersWarehouseOnChange(Item)
	
	If SplitOrdersByWarehouses And DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersDateOfProductionOnChange(Item)
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersOrderDateOnChange(Item)
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrderBasket

// Parameters:
// 	String - Number -
// 	Field - FormField -
&AtClient
Procedure OrderBasketDrag(Item, DragParameters, StandardProcessing, String, Field)
		
	If String <> Undefined And (Field.Name = "OrderBasketProductionDispatcherBusinessUnit"
		Or Field.Name = "OrderBasketWarehouse") Then
		BucketRow = OrderBasket.FindByID(String);
		
		If Field.Name = "OrderBasketProductionDispatcherBusinessUnit" Then
			FieldsNames = "ProductionDispatcherBusinessUnit";
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chỉ định người quản lý cho sản phẩm đã chọn: %1?';
					|ru = 'Назначить для выделенного товара подразделение диспетчер: %1?';
					|en = 'Assign a dispatching unit: %1 to the selected goods?'; fa = 'Assign a dispatching unit: %1 to the selected goods?';
					|it = 'Assegnare per la merce selezionata il reparto distributore: %1?';
					|pl = 'Wyznaczyć dla wybranego towaru dział dyspozytor: %1?';
					|tr = 'Seçili ürün için üretim kontrolü departmanı görevlendirilsin mi: %1?'"), BucketRow.ProductionDispatcherBusinessUnit);
		ElsIf Field.Name = "OrderBasketWarehouse" Then
			FieldsNames = "Warehouse";
			QueryText =StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ấn định hàng hóa đã chọn kho bãi: %1?';
					|ru = 'Назначить для выделенного товара склад: %1?';
					|en = 'Assign a warehouse for the selected goods: %1?'; fa = 'Assign a warehouse for the selected goods: %1?';
					|it = 'Assegnare per la merce selezionata il magazzino: %1?';
					|pl = 'Wyznaczyć dla wydzielonego towaru magazyn: %1?';
					|tr = 'Seçili ürün için ambar görevlendirilsin mi: %1?'"),BucketRow.Warehouse);
		Else
			FieldsNames= "";
			QueryText = "";
		EndIf; 
		
		If Not IsBlankString(FieldsNames) Then 
			
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ấn định';
													|ru = 'Назначить';
													|en = 'Assign'; fa = 'تخصیص';
													|it = 'Assegnare';
													|pl = 'Assign';
													|tr = 'Ata'"));
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Chưa ấn định';
													|ru = 'Не назначать';
													|en = 'Do not assign'; fa = 'تخصیص نشود';
													|it = 'Non assegnare';
													|pl = 'Nie wyznaczaj';
													|tr = 'Görevlendirme'"));
			Buttons.Add(DialogReturnCode.Cancel);
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("DragParameters", DragParameters);
			AdditionalParameters.Insert("FieldsNames", FieldsNames);
			AdditionalParameters.Insert("BucketRow", BucketRow);
			ShowQueryBox(
				New CallbackDescription("OrderBasketDragCompletion", ThisObject, AdditionalParameters), 
				QueryText, Buttons,,DialogReturnCode.Yes);
			Return;
		EndIf;
		
	EndIf;
	
	For Each TSRow In DragParameters.Value Do
		TSRow.SelectToOrder = True;
	EndDo; 
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderBasketDragCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf; 
	
	DragParameters = AdditionalParameters.DragParameters;
	
	If QuestionResult = DialogReturnCode.Yes  Then
		
		FieldsNames = AdditionalParameters.FieldsNames;
		BucketRow = AdditionalParameters.BucketRow;
		
		For Each TSRow In DragParameters.Value Do
			If Not TSRow.EditBusinessUnit And FieldsNames = "Department" Then
				Continue;
			EndIf;
			FillPropertyValues(TSRow, BucketRow, FieldsNames);
		EndDo;
		
	EndIf;
	
	For Each TSRow In DragParameters.Value Do
		TSRow.SelectToOrder = True;
	EndDo; 
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderBasketDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If DragParameters.Value.Count() =0 Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	Try	
		SelectToOrder = DragParameters.Value[0].SelectToOrder;
	Except
		DragParameters.Action = DragAction.Cancel;
	EndTry;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PickProducts(Command)
	
	FormParameters = New Structure("SettingsComposer", SettingsComposer);
	OpenForm("DataProcessor.GenerationOfProductionOrdersByPlans.Form.FilterForm", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SetPeriodInterval(Command)
	
	Notification = New CallbackDescription(
		"SetPeriodIntervalCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		Object, 
		New Structure("StartDate, EndDate", "PeriodBeginning", "PeriodEnd"),
		Notification);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
	"DataProcessor.GenerationOfProductionOrdersByPlans.Form.Command.Fill");
	
	If Object.GenerationOfOrders.Count() > 0 Then
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Continue';
												|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Notification = New CallbackDescription("FillCompletion", ThisObject);
		ShowQueryBox(Notification,
			NStr("vi = 'Trong bảng có dòng. Khi cập nhật dữ liệu từ kế hoạch thì các dòng sẽ bị xóa. Tiếp tục?';
				|ru = 'В таблице имеются строки. При обновлении данных из планов строки будут очищены. Продолжить?';
				|en = 'There are rows in the table. When updating the plan data, the rows will be cleared. Continue?'; fa = 'There are rows in the table. When updating the plan data, the rows will be cleared. Continue?';
				|it = 'La tabella contiene delle righe. Durante l''aggiornamento dati dai piani le righe saranno cancellate. Continuare?';
				|pl = 'W tabeli są wiersze. Podczas aktualizacji danych z planów wiersze będą oczyszczone. Kontynuować?';
				|tr = 'Tabloda satırlar var. Verilerin güncellenmesi için satırlar için temizlenecek. Devam edilsin mi?'"), 
			Buttons, 0);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenOrderList(Command)
	
		OpenForm("Document.ProductionOrder2_2.ListForm");
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#Region CommandsOfFormTableFormFormationOfOrders

&AtClient
Procedure DisplayOrdersForRegistration(Command)
	
	DisplayOrdersForCheckoutOnServer();
	
EndProcedure

&AtClient
Procedure OrderCreationParameters(Command)
	
	OrderCreationParameters = New Structure();
	OrderCreationParameters.Insert("SplitOrdersByAssignments", SplitOrdersByAssignments);
	OrderCreationParameters.Insert("SplitOrdersByWarehouses", SplitOrdersByWarehouses);
	OrderCreationParameters.Insert("SplitOrdersByReleaseLaunchDates", SplitOrdersByReleaseLaunchDates);
	OrderCreationParameters.Insert("DestinationVisibility", PlanningByAssignments And UseOrderSupplyWithAssignment);
	OrderCreationParameters.Insert("AvailabilityOfDestinationSettings", Object.ProductionProcessType <> PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
	OrderCreationParameters.Insert("DynamicStructure", DynamicStructure);
	
	OpenForm("DataProcessor.GenerationOfProductionOrdersByPlans.Form.OrderCreationParameters", OrderCreationParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	SwitchCheckboxes(False);
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	SwitchCheckboxes(True);
	
EndProcedure

&AtClient
Procedure FillInDispatcherDepartment(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	Filter = New Structure("ProductionDispatcherBusinessUnit", True);
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);
	
	SelectedRows = New Array;
	For Each SelectedRow In Items.GenerationOfOrders.SelectedRows Do
		If Object.GenerationOfOrders.FindByID(SelectedRow).EditBusinessUnit Then
			SelectedRows.Add(SelectedRow);
		EndIf;
	EndDo;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn các dòng mà trong đó cho phép soạn bộ phận điều phối.';
								|ru = 'Выделите строки в которых разрешено редактирование подразделения-диспетчера.';
								|en = 'Select lines in which dispatching unit editing is allowed.'; fa = 'Select lines in which dispatching unit editing is allowed.';
								|it = 'Selezionate le righe in cui è consentita la modifica del reparto-distributore.';
								|pl = 'Wybierz wiersze w których jest dozwolona edycja działu dyspozytora.';
								|tr = 'Sevk eden departmanın düzenlemesine izin verilen satırları vurgulayınız.'"));
		Return;
	EndIf;
	
	LinkIsNotInList = GetDivisionsWithPlansOnSelectedLines(SelectedRows);
	
	Notification = New CallbackDescription("FillInDispatcherDepartmentCompletion", 
		ThisObject, 
		New Structure("SelectedRows", SelectedRows));
	OpenForm("Catalog.BusinessStructure.ChoiceForm", 
		New Structure("Key, Filter, LinkIsNotInList", TableRow.ProductionDispatcherBusinessUnit, Filter, LinkIsNotInList),
		,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure FillInTheWarehouse(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);
	Warehouse = Undefined;
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	ChoiceFormParameters.Insert("Key", TableRow.Warehouse);
	
	Notification = New CallbackDescription(
		"FillInTheWarehouseCompletion",
		ThisObject,
		New Structure("TableRow", TableRow));
	OpenForm(
		"Catalog.Warehouses.ChoiceForm",
		ChoiceFormParameters,
		,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.GenerationOfOrders;
	TableData = Object.GenerationOfOrders;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.GenerationOfOrders.CurrentData;
	
	If NewRow <> Undefined Then
		
		Actions = New Structure;
		Actions.Insert("RecalculateNumberOfUnits");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, Actions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDate(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	Notification = New CallbackDescription("SetDateCompletion", ThisObject);
	
	If ThisIsDisassembly Then
		
		ShowInputDate(Notification, 
			Items.GenerationOfOrders.CurrentData.OrderDate,
			NStr("vi = 'Nhập ngày vận hành';
				|ru = 'Введите дату запуска';
				|en = 'Enter start date'; fa = 'Enter start date';
				|it = 'Inserite la data di avvio';
				|pl = 'Wprowadź datę uruchomienia';
				|tr = 'Giriş tarihini giriniz'"),
			DateFractions.Date);
			
	Else
		
		ShowInputDate(Notification, 
			Items.GenerationOfOrders.CurrentData.DateOfProduction,
			NStr("vi = 'Nhập ngày xuất xưởng';
				|ru = 'Введите дату выпуска';
				|en = 'Enter a release date'; fa = 'Enter a release date';
				|it = 'Inserite la data di produzione';
				|pl = 'Wprowadź datę wyprodukowania';
				|tr = 'Çıkış tarihini giriniz'"),
			DateFractions.Date);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferOrAllocate(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Scenario", Object.Scenario);
	
	If ThisIsDisassembly Then
		FormParameters.Insert("ProductionDate", Items.GenerationOfOrders.CurrentData.OrderDate);
		FormParameters.Insert("PlanningType", "DisassemblyProductionPlanning");
	Else
		FormParameters.Insert("ProductionDate", Items.GenerationOfOrders.CurrentData.DateOfProduction);
		FormParameters.Insert("PlanningType", "AssemblyProductionPlanning");
	EndIf;
	
	Notification = New CallbackDescription("TransferOrAllocateCompletion", ThisObject);
	
	OpenForm(
		"CommonForm.GenerationOfOrdersByPlansAllocationAndTransfer",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
		
	
EndProcedure

#EndRegion

#Region StepByStepWizardCommands

&AtClient
Procedure Next(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.GenerationOfProductionOrdersByPlans.Form.Command.Next");
	
	If Items.PagesMainPanel.CurrentPage = Items.PageStep1 Then
		
		ClearMessages();
		
		If Not CheckFilling() Then
			Return;
		EndIf;
		
		If ValueIsFilled(Object.PeriodEnd)  
			And Object.PeriodBeginning > Object.PeriodEnd Then
			UserMessage = New UserMessage;
			UserMessage.Field = "Object.PeriodBeginning";
			UserMessage.Text = NStr("vi = '""Bắt đầu kỳ"" lớn hơn ""Kết thúc kỳ"". Không thể lựa chọn.';
									|ru = '""Начало периода"" больше ""Окончания периода"". Отбор невозможен.';
									|en = '""Beginning of period"" is greater than ""End of period"". Cannot filter.'; fa = '""Beginning of period"" is greater than ""End of period"". Cannot filter.';
									|it = '""Inizio del periodo"" è successivo alla ""Fine del periodo"". Selezione impossibile.';
									|pl = '""Początek okresu"" jest większy niż ""Zakończenie okresu"". Filtr jest niemożliwy możliwa.';
									|tr = '""Dönemin başlangıcı"", ""Dönemin sonu"" değerinden büyük. Filtre kullanılamaz.'");
			UserMessage.Message();
			Return;
		EndIf;
		
		If Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then 
			SplitOrdersByAssignments = True;
		EndIf;
		
		ShouldSaveSettings();
		FillInOnClient();
		
		If Object.GenerationOfOrders.Count() > 0 Then
			Items.PagesMainPanel.CurrentPage = Items.PageStep2;
		EndIf;
		
	ElsIf Items.PagesMainPanel.CurrentPage = Items.PageStep2 Then 
		
		UpdateOrderCart();
		
		If OrderBasket.Count() = 0 Then
			
			ErrorText = NStr("vi = 'Không có đơn hàng cần lập. Hãy đánh dấu bằng hộp kiểm số lượng trong cột 
				|""Cần đặt"" đối với mặt hàng cần đặt.';
				|ru = 'Нет заказов к оформлению. Отметьте флажком количество в колонке 
				|""К заказу"" для номенклатуры которую необходимо заказать.';
				|en = 'No orders for registration. Select quantity in
				|the ""To order"" column for products which should be ordered.'; fa = 'No orders for registration. Select quantity in
				|the ""To order"" column for products which should be ordered.';
				|it = 'Non ci sono ordini da formalizzare. Contrassegnate con un flag la quantità nella colonna 
				| ""Da ordinare"" per l''articolo che deve essere ordinato.';
				|pl = 'Brak zamówień do utworzenia. Zaznacz ilość w kolumnie 
				|""К заказу"" dla produktów które należy zamówić.';
				|tr = 'Düzenlenecek sipariş mevcut değil. Sipariş etmek istediğiniz öğeler için 
				| ""Sipariş edilecek"" sütununda ürün sayısını işaretleyiniz.'");
			
			ShowMessageBox(,ErrorText);
			
			Return;
			
		EndIf;
		
		ClearMessages();
		CreateOrdersOnServer();
		
			List = List2_2;
	
		TMCommonUseClientServer.GetDynamicListSelection(List).Items.Clear();
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Ref",
			GeneratedOrders,
			DataCompositionComparisonType.InList,
			NStr("vi = 'Đơn hàng đã lập';
				|ru = 'Сформированные заказы';
				|en = 'Generated orders'; fa = 'سفارش‌های ایجادشده';
				|it = 'Ordini generati';
				|pl = 'Utworzone zamówienia';
				|tr = 'Oluşturulmuş siparişler'"),
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
		Items.PagesMainPanel.CurrentPage = Items.PageStep3;
		
	EndIf;
	
	SetFormHeader(Items.PagesMainPanel.CurrentPage);
	SetVisibilityOfCommandPanelButtons(Items.PagesMainPanel.CurrentPage);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.PagesMainPanel.CurrentPage = Items.PageStep3 Then
		
		If GeneratedOrders.Count() > 0 Then
			
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Đặt dấu xóa chứng từ';
													|ru = 'Пометить документы на удаление';
													|en = 'Mark documents for deletion'; fa = 'علامت‌گذاری اسناد برای حذف';
													|it = 'Contrassegnare i documenti per l''eliminazione';
													|pl = 'Zaznacz dokumenty do usunięcia';
													|tr = 'Silinmek için belgeleri işaretle'"));
			Buttons.Add(DialogReturnCode.Cancel);
			
			ShowQueryBox
				(New CallbackDescription("BackCompletion", ThisObject), 
				NStr("vi = 'Danh sách các đơn đặt hàng đã tạo không trống. Các chứng từ được tạo sẽ được đánh dấu để xóa. Đánh dấu xóa đơn hàng và tiếp tục?';
					|ru = 'Список созданных заказов не пуст. Сформированные документы будут помечены на удаление. Пометить на удаление заказы и продолжить?';
					|en = 'The list of created orders is not empty. The generated documents will be marked for deletion. Mark orders for deletion and continue?'; fa = 'The list of created orders is not empty. The generated documents will be marked for deletion. Mark orders for deletion and continue?';
					|it = 'Elenco degli ordini generati non è vuoto. I documenti generati verranno contrassegnati per l''eliminazione. Contrassegnare per l''eliminazione gli ordini e continuare?';
					|pl = 'Lista utworzonych zamówień nie jest pusta. Utworzone dokumenty będą zaznaczone do usunięcia. Zaznaczyć do usunięcia zamówienia i kontynuować?';
					|tr = 'Oluşturulan siparişlerin listesi boş. Oluşturulan belgeler silinmeye etiketlenecek. Siparişler silinmek için etiketlensin ve devam edilsin mi?'"),
				Buttons);
			Return;
		EndIf;
		
		ClearMessages();
		Items.PagesMainPanel.CurrentPage = Items.PageStep2;
		
	ElsIf Items.PagesMainPanel.CurrentPage = Items.PageStep2 Then
		
		OrderBasket.Clear();
		Object.GenerationOfOrders.Clear();
		Items.PagesMainPanel.CurrentPage = Items.PageStep1;
		
	EndIf;
	
	SetFormHeader(Items.PagesMainPanel.CurrentPage);
	SetVisibilityOfCommandPanelButtons(Items.PagesMainPanel.CurrentPage);
	
EndProcedure

&AtClient
Procedure BackCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If MarkDocumentsForDeletion_(GeneratedOrders.UnloadValues()) Then
		GeneratedOrders.Clear();
		Items.PagesMainPanel.CurrentPage = Items.PageStep2;
		
		SetFormHeader(Items.PagesMainPanel.CurrentPage);
		SetVisibilityOfCommandPanelButtons(Items.PagesMainPanel.CurrentPage);
	EndIf;
	
EndProcedure

&AtClient
Procedure FinishGeneratingOrders(Command)
	
	OrderBasket.Clear();
	ClearMessages();
	Object.GenerationOfOrders.Clear();
	GeneratedOrders.Clear();
	
	Items.PagesMainPanel.CurrentPage = Items.PageStep1;
	SetFormHeader(Items.PagesMainPanel.CurrentPage);
	SetVisibilityOfCommandPanelButtons(Items.PagesMainPanel.CurrentPage);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FormDisplaySettings

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersProductionDispatcherBusinessUnit.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.EditBusinessUnit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtClient
Procedure SetFormHeader(Page)
	
	If Page = Items.PageStep1 Then
		
		Items.Subtitle.Title = NStr("vi = 'Bước 1 trên 3. Chọn kế hoạch';
									|ru = 'Шаг 1 из 3. Отбор планов';
									|en = 'Step 1 of 3. Filter plans'; fa = 'مرحله 1 از 3. فیلتر برنامه‌ها';
									|it = 'Passaggio 1 di 3. Selezione dei piani';
									|pl = 'Krok 1 z 3. Filtr planów';
									|tr = '3 adım arasından 1. adım. Plan filtresi'");
		
	ElsIf Page = Items.PageStep2 Then
		
		Items.Subtitle.Title = NStr("vi = 'Bước 2/3. Xác định thành phần và khối lượng đơn hàng';
									|ru = 'Шаг 2 из 3. Определение состава и объема заказа';
									|en = 'Step 2 of 3. Define what to order and how much to order'; fa = 'Step 2 of 3. Define what to order and how much to order';
									|it = 'Passaggio 2 di 3. Determinare la composizione e il volume dell''ordine';
									|pl = 'Krok 2 z 3. Określenie składu i objętości zamówienia';
									|tr = '3 adım arasından 2. adım. Siparişin içeriğinin ve hacminin belirlenmesi'");
		
	ElsIf Page = Items.PageStep3 Then
		
		Items.Subtitle.Title = NStr("vi = 'Bước 3/3. Làm rõ đơn hàng đã tạo';
									|ru = 'Шаг 3 из 3. Уточнение сформированных заказов';
									|en = 'Step 3 of 3. Specify generated orders'; fa = 'Step 3 of 3. Specify generated orders';
									|it = 'Passaggio 3 di 3. Perfezionamento degli ordini generati';
									|pl = 'Krok 3 z 3. Uściślenie utworzonych zamówień';
									|tr = 'Adım 3/3. Oluşturulan siparişlerin netleştirilmesi'");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	Items.FormToDisplayTheOrdersToTheDesign.Check = DisplayOrdersForRegistration;
	Items.GroupOrdersToBeProcessed.Visible        = DisplayOrdersForRegistration;
	
	Items.OrderBasketWarehouse.Visible            = SplitOrdersByWarehouses And UseSeveralWarehouses;
	Items.GenerationOfOrdersWarehouse.Visible       = SplitOrdersByWarehouses And UseSeveralWarehouses;
	Items.FillOutWarehouseForm.Visible            = SplitOrdersByWarehouses And UseSeveralWarehouses;
	
	DestinationVisibility = PlanningByAssignments And UseOrderSupplyWithAssignment;
	Items.OrderBasketPurpose.Visible                      = SplitOrdersByAssignments And DestinationVisibility;
	
	VisibilityOfReleaseLaunchDate = UseProductionManagement2_2 And (SplitOrdersByReleaseLaunchDates Or Not DynamicStructure);
	Items.OrderBasketDemandDate.Visible = VisibilityOfReleaseLaunchDate;
	Items.OrderBasketEarliestStartDate.Visible   = VisibilityOfReleaseLaunchDate;
	
	Items.OrderGenerationTransferDistribute.Visible = Periodicity <> Enums.Periodicity.Day;
	Items.OrderFormationTheContextMenuToTransferToDistribute.Visible = Periodicity <> Enums.Periodicity.Day;
	
	Items.ProductionProcessType.Visible = UseProcessType;
	If UseProcessType Then
		TypesToExclude = New Array;
		TypesToExclude.Add(Enums.ProductionProcessTypes.WithoutBillsOfMaterials);
		ProductionServer.FillInListOfProductionProcessTypes(Items.ProductionProcessType, TypesToExclude);
	EndIf;
	
	If DynamicStructure Then 
		Items.ProductionScheduling.Visible = False; // in orders with a dynamic structure, issue placement is not used
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfCommandPanelButtons(CurrentPage)
	
	If CurrentPage = Items.PageStep1 Then
				
		Items.CommandPagesBottom.CurrentPage  = Items.PageCommandsBottomStep1;
		Items.NextStep1.DefaultButton = True;
		
	ElsIf CurrentPage = Items.PageStep2 Then
		
		Items.CommandPagesBottom.CurrentPage  = Items.PageCommandsBottomStep2;
		Items.NextStep2.DefaultButton = True;
		
	ElsIf CurrentPage = Items.PageStep3 Then
		
		Items.CommandPagesBottom.CurrentPage  = Items.PageCommandsBottomStep3;
		Items.CompleteOrderGenerationStep3.DefaultButton = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilitySettingsWhenChangingSubdividingSelectionOnServer(Form)
	
	VisibilityOfDivisionColumns = Not (Form.FilterDepartments And ValueIsFilled(Form.Object.Department));
	Form.Items.GenerationOfOrdersProductionDispatcherBusinessUnit.Visible = VisibilityOfDivisionColumns;
	Form.Items.CreatingOrdersFillInTheDispatcherDivisionInTheSelectedLines.Visible = VisibilityOfDivisionColumns;
	Form.Items.Department.Enabled = Form.FilterDepartments;
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilitySettingsWhenChangingScript(Form)
	
	DestinationVisibility = Form.PlanningByAssignments And Form.UseOrderSupplyWithAssignment;
	Form.Items.GroupAdditionalSelections.Visible = DestinationVisibility;
	Form.Items.GenerationOfOrdersPurpose.Visible = DestinationVisibility;
	Form.Items.OrderBasketPurpose.Visible = DestinationVisibility And Form.SplitOrdersByAssignments;
	
EndProcedure

&AtServer
Procedure VisibilitySettingsUseProductionManagement2_2()
		Items.List2_1.Visible = False;
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilitySettingsWhenChangingProcessType(Form)
	
	Form.Items.GenerationOfOrdersDateOfProduction.Visible = Not Form.ThisIsDisassembly;
	Form.Items.OrderBasketDemandDate.Visible = Not Form.ThisIsDisassembly;
	
	Form.Items.GenerationOfOrdersOrderDate.ReadOnly = Not Form.ThisIsDisassembly;
	
	Form.Items.GenerationOfOrdersContextMenuSetDate.Title = ?(Form.ThisIsDisassembly,
		NStr("vi = 'Đặt ngày vận hành';
			|ru = 'Установить дату запуска';
			|en = 'Set start date'; fa = 'Set start date';
			|it = 'Impostare la data di avvio';
			|pl = 'Ustaw datę uruchomienia';
			|tr = 'Giriş tarihini ayarla'"), NStr("vi = 'Đặt ngày xuất xưởng';
											|ru = 'Установить дату выпуска';
											|en = 'Set the release date'; fa = 'Set the release date';
											|it = 'Impostare la data di produzione';
											|pl = 'Ustaw datę wyprodukowania';
											|tr = 'Çıkış tarihini ayarla'"));
	
	Form.Items.GenerationOfOrdersSetDate.Title = ?(Form.ThisIsDisassembly,
		NStr("vi = 'Đặt ngày vận hành';
			|ru = 'Установить дату запуска';
			|en = 'Set start date'; fa = 'Set start date';
			|it = 'Impostare la data di avvio';
			|pl = 'Ustaw datę uruchomienia';
			|tr = 'Giriş tarihini ayarla'"), NStr("vi = 'Đặt ngày xuất xưởng';
											|ru = 'Установить дату выпуска';
											|en = 'Set the release date'; fa = 'Set the release date';
											|it = 'Impostare la data di produzione';
											|pl = 'Ustaw datę wyprodukowania';
											|tr = 'Çıkış tarihini ayarla'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInCalculationModeSelectionList(Form)
	
	List = Form.Items.DemandCalculationModeByPlan.ChoiceList;
	
	List.Clear();
	
	List.Add(0, NStr("vi = 'Tách biệt theo kỳ vận hành';
					|ru = 'Раздельно по периодам запуска';
					|en = 'Separate by starting periods'; fa = 'Separate by starting periods';
					|it = 'Separatamente per periodi di avvio';
					|pl = 'Oddzielnie według okresów uruchomienia';
					|tr = 'Piyasaya sunma dönemine göre ayrı olarak'"));
	
	If Not Form.ThisIsDisassembly Then
		List.Add(1, NStr("vi = 'Tách biệt theo kỳ phát hành';
						|ru = 'Раздельно по периодам выпуска';
						|en = 'Separate by release periods'; fa = 'Separate by release periods';
						|it = 'Separatamente per periodi di produzione';
						|pl = 'Oddzielnie według okresów wyprodukowania';
						|tr = 'Satışa sunma dönemine göre ayrı olarak'"));
	EndIf;
	
	List.Add(2, NStr("vi = 'Tổng cộng tích lũy cho kỳ vận hành';
					|ru = 'Нарастающим итогом за период запуска';
					|en = 'Cumulative for start period'; fa = 'Cumulative for start period';
					|it = 'Totale parziale per il periodo di avvio';
					|pl = 'Rosnącym wynikiem za okres uruchomienia';
					|tr = 'Piyasaya sunma dönemi için birikimli toplam'"));
	
	If Not Form.ThisIsDisassembly Then
		List.Add(3, NStr("vi = 'Tổng cộng tích lũy cho kỳ xuất xưởng';
						|ru = 'Нарастающим итогом за период выпуска';
						|en = 'Cumulative for release period'; fa = 'Cumulative for release period';
						|it = 'Totale parziale per il periodo di produzione';
						|pl = 'Rosnącym wynikiem za okres wyprodukowania';
						|tr = 'Satışa sunma dönemine göre birikimli toplam'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresForWorkingWithUserSettings

&AtServer
Procedure InitializeSettingsComposer()
	
		If Object.DemandCalculationModeByPlan = 0
			Or Object.DemandCalculationModeByPlan = 1 Then
			
			If ThisIsDisassembly Then
				TemplateName = "CompositionTemplate22Disassembly";
			Else
				TemplateName = "CompositionTemplate22Assembly";
			EndIf;
				
			DataCompositionSchema = DataProcessors.GenerationOfProductionOrdersByPlans.GetTemplate(TemplateName);

		Else
			
			If ThisIsDisassembly Then
				TemplateName = "CompositionTemplate22AccumulatedDisassembly";
			Else
				TemplateName = "CompositionTemplate22AccumulatedAssembly";
			EndIf;
			DataCompositionSchema = DataProcessors.GenerationOfProductionOrdersByPlans.GetTemplate(TemplateName);
			
			If ThisIsDisassembly Then
				TemplateName = "CompositionTemplateQuantityInPlansDisassembly";
			Else
				TemplateName = "CompositionTemplateQuantityInPlansAssembly";
			EndIf;
			DataLayoutSchemeQuantityInPlans = DataProcessors.GenerationOfProductionOrdersByPlans.GetTemplate(TemplateName);
			
			If ThisIsDisassembly Then
				TemplateName = "CompositionTemplate2_2QuantityInOrdersDisassembly";
			Else
				TemplateName = "CompositionTemplate2_2QuantityInOrdersAssembly";
			EndIf;
			DataLayoutDiagramQuantityInOrders = DataProcessors.GenerationOfProductionOrdersByPlans.GetTemplate(TemplateName);
			
		EndIf;
	
	AddressOfDataCompositionSchemaPlannedQuantity = PutToTempStorage(DataLayoutSchemeQuantityInPlans, New UUID);
	AddressOfDataCompositionSchemaQuantityInOrders = PutToTempStorage(DataLayoutDiagramQuantityInOrders, New UUID);
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	
	If TypeOf(SettingsValue) = Type("Structure")
		And SettingsValue.Property("UserSettings") Then
		SettingsComposer.LoadUserSettings(SettingsValue.UserSettings);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShouldSaveSettings()
	
	Settings = New Structure;
	Settings.Insert("UserSettings", SettingsComposer.UserSettings);
	Settings.Insert("Scenario",                  Object.Scenario);
	Settings.Insert("PeriodBeginning",              Object.PeriodBeginning);
	Settings.Insert("PeriodEnd",           Object.PeriodEnd);
	Settings.Insert("FilterDepartments",        FilterDepartments);
	Settings.Insert("Department",             Object.Department);
	Settings.Insert("Organization",               Object.Organization);
	Settings.Insert("DemandCalculationModeByPlan", Object.DemandCalculationModeByPlan);
	Settings.Insert("SplitOrdersByWarehouses",  SplitOrdersByWarehouses);
	Settings.Insert("SplitOrdersByAssignments",  SplitOrdersByAssignments);
	Settings.Insert("SplitOrdersByReleaseLaunchDates",  SplitOrdersByReleaseLaunchDates);
	Settings.Insert("Purpose",                Object.Purpose);
	Settings.Insert("ProductionProcessType", Object.ProductionProcessType);
	Settings.Insert("GenerateOrdersByUpToDateBillsOfMaterials", Object.GenerateOrdersByUpToDateBillsOfMaterials);
	Settings.Insert("ProductionScheduling",         Object.ProductionScheduling);
	
	SaveSettingsAtServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(Settings)
	
	ObjectKey = "DataProcessor.GenerationOfProductionOrdersByPlans";
	Common.CommonSettingsStorageSave(ObjectKey, "Settings", Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.GenerationOfProductionOrdersByPlans", "Settings");
	
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		FillPropertyValues(Object, SettingsValue);
		FillPropertyValues(ThisForm, SettingsValue);
		
		If Not SettingsValue.Property("SplitOrdersByReleaseLaunchDates") Then
			SplitOrdersByReleaseLaunchDates = True;
		EndIf;
		
		ThisIsDisassembly = Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly;
		
	Else
		Object.ProductionScheduling = PredefinedValue("Enum.WayOfLinkingProductionOperations.ToFinish");
	EndIf;
	
EndProcedure

&AtServer
Function GetRequestWithDataLayoutSelections(AddressOfDataCompositionSchema, SettingsComposer, InitializeTeamBuilder = False)
	
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
	
	If InitializeTeamBuilder Then
		SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
		SettingsComposer.Initialize(SettingsSource);
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	If Object.DemandCalculationModeByPlan = 0
		Or Object.DemandCalculationModeByPlan = 2 Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderPeriodStart",    Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderPeriodEnd", Object.PeriodEnd);
	Else
		DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod",    Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodEnding", Object.PeriodEnd);
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "GenerateOrdersByUpToDateBillsOfMaterials", 
																			Object.GenerateOrdersByUpToDateBillsOfMaterials);
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , , False, );
	
	Query = New Query(DataCompositionTemplate.DataSets.DataSet.Query);
	
	For Each LayoutParameter In DataCompositionTemplate.ParameterValues Do
		
		Query.SetParameter(LayoutParameter.Name, LayoutParameter.Value);
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			?(ThisIsDisassembly, "BillsOfMaterials.MainProductPackage", "ResourceSpecificationsOutputProducts.Package"),
			"ProductionPlansTurnovers.Products"));
	
	Return Query;
	
EndFunction 

#EndRegion

#Region ProceduresCommandHandlersCompletion

&AtClient
Procedure SetPeriodIntervalCompletion(Period, AdditionalParameters) Export 
	
	BringDatesToPeriodicityOfScript(ThisObject, Object.PeriodBeginning, Object.PeriodEnd);
	
EndProcedure

&AtClient
Procedure FillCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	FillInOnClient();
	
EndProcedure

&AtClient
Procedure FillInOnClient()
	
	Object.GenerationOfOrders.Clear();
	OrderBasket.Clear();
	UpdateAtServer();
	If Object.GenerationOfOrders.Count() = 0 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không có kế hoạch đã phê duyệt đối với kịch bản %1 tương ứng với bộ lọc được thiết lập. Cần thay đổi bộ lọc.';
				|ru = 'Нет утвержденного плана для сценария %1, соответствующего установленным отборам. Необходимо изменить отборы.';
				|en = 'There is no confirmed plan for the %1 scenario corresponding to the set filters. Change the filters.'; fa = 'There is no confirmed plan for the %1 scenario corresponding to the set filters. Change the filters.';
				|it = 'Non esiste un piano approvato per lo scenario %1, che corrisponda ai filtri impostati. È necessario modificare i filtri.';
				|pl = 'Brak zatwierdzonego planu dla scenariusza %1, odpowiadającego ustawionym selekcjom. Należy zmienić selekcje.';
				|tr = '%1 senaryosu için belirlenen filtrelerle uyumlu onaylanmış plan yok. Filtrelerin değiştirilmesi gerekmektedir.'"),
			Object.Scenario);
		ShowMessageBox(, ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDispatcherDepartmentCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	ProductionDispatcherBusinessUnit = Result;
	
	If Not ValueIsFilled(ProductionDispatcherBusinessUnit) Then
		Return;
	EndIf; 
	
	DivisionManagerChanged = False;
	
	For Each SelectedRow In SelectedRows Do
		
		TableRow = Object.GenerationOfOrders.FindByID(SelectedRow);
		
		If TableRow.ProductionDispatcherBusinessUnit <> ProductionDispatcherBusinessUnit Then
			DivisionManagerChanged = True;
			TableRow.ProductionDispatcherBusinessUnit = ProductionDispatcherBusinessUnit;
		EndIf;
		
	EndDo;
	
	If DivisionManagerChanged And DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseCompletion(Result, AdditionalParameters) Export
	
	TableRow = AdditionalParameters.TableRow;
	
	Warehouse = Result;
	
	If Not ValueIsFilled(Warehouse) Then
		Return;
	EndIf; 
	
	WarehouseChanged = False;
	
	For Each SelectedRow In Items.GenerationOfOrders.SelectedRows Do
		
		TableRow = Object.GenerationOfOrders.FindByID(SelectedRow);
		
		If TableRow.Warehouse <> Warehouse Then
			WarehouseChanged = True;
			TableRow.Warehouse = Warehouse;
		EndIf;
		
	EndDo;
	
	If WarehouseChanged And SplitOrdersByWarehouses Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferOrAllocateCompletion(DistributionParameters, AdditionalParameters) Export 
	
	If DistributionParameters = Undefined Then
		Return;
	EndIf;
	
	MigrateOrDistributeCompletionOnServer(DistributionParameters,
		Items.GenerationOfOrders.SelectedRows);
	
EndProcedure

&AtServer
Procedure MigrateOrDistributeCompletionOnServer(DistributionParameters,Val SelectedRows) 
	
	Planning.MigrateOrDistributeOnServer(DistributionParameters,
		SelectedRows,
		Object.GenerationOfOrders);
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDateCompletion(Date, AdditionalParameters) Export 
	
	If Date = Undefined Then
		Return;
	EndIf;
	
	For Each CurrentRow In Items.GenerationOfOrders.SelectedRows Do
		
		TSRow = Object.GenerationOfOrders.FindByID(CurrentRow);
		
		If ThisIsDisassembly Then
			TSRow.OrderDate = Date;
		Else
			TSRow.DateOfProduction = Date;
		EndIf;
		
	EndDo;
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresForObtainingPlansAndOrders

&AtServer
Function ListOfPlansByLine(RowKey)

	Query = New Query();
	Query.Text = 
	"SELECT ALLOWED
	|	ProductionPlansTurnovers.ToOrderTurnover AS Count,
	|	ProductionPlansTurnovers.Recorder AS Document,
	|	ProductionPlansTurnovers.ProductionPlan.PointInTime AS PointInTime,
	|	ProductionPlansTurnovers.ProductionPlan.Date AS DocumentDate,
	|	ProductionPlansTurnovers.ProductionPlan.Number AS DocumentNumber
	|FROM
	|	AccumulationRegister.ProductionPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&PeriodEnding,
	|			Recorder,
	|			Scenario = &Scenario
	|				AND Department = &Department
	|				AND Products = &Products
	|				AND Characteristic = &Characteristic
	|				AND Purpose = &Purpose
	|				AND BillOfMaterials = &BillOfMaterials) AS ProductionPlansTurnovers
	|		INNER JOIN Document.ProductionPlan AS DocProductionPlan
	|		ON ProductionPlansTurnovers.Recorder = DocProductionPlan.Ref
	|
	|ORDER BY
	|	PointInTime";
	
	For Each Property In RowKey Do
		
		Query.SetParameter(Property.Key, Property.Value);
		
	EndDo;
	
	Selection = Query.Execute().Select();
	DocumentsList = New ValueList();
	While Selection.Next() Do
		
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (STT %2 ngày %3)';
				|ru = '%1 (№ %2 от %3)';
				|en = '%1 (No. %2 from %3)'; fa = '%1 (No. %2 from %3)';
				|it = '%1 (№%2 del %3)';
				|pl = '%1 (Nr %2 z %3)';
				|tr = '%1 (%3 itibarıyla %2 numaralı)'"), 
				Format(Selection.Count, "NFD=3"), Selection.DocumentNumber, 
				Format(Selection.DocumentDate, "DLF=D"));
		DocumentsList.Add(Selection.Document, DocumentPresentation);
		
	EndDo;
	
	Return DocumentsList;
	
EndFunction

&AtServer
Function ListOfPlansIsCumulativeByLine(RowKey)

	Query = GetRequestWithDataLayoutSelections(AddressOfDataCompositionSchemaPlannedQuantity, SettingsComposerQuantityInPlansInOrders, True);
	
	Query.SetParameter("Scenario",			Object.Scenario);
	Query.SetParameter("Department",		RowKey.Department);
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Products", RowKey.Products);
	Query.SetParameter("Characteristic", RowKey.Characteristic);
	Query.SetParameter("Purpose", RowKey.Purpose);
	Query.SetParameter("ProductionProcessType", Object.ProductionProcessType);
	
	ResultTable2 = Query.Execute().Unload();
	
	DocumentsList = New ValueList();
	For Each String In ResultTable2 Do
		
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (STT %2 ngày %3)';
				|ru = '%1 (№ %2 от %3)';
				|en = '%1 (No. %2 from %3)'; fa = '%1 (No. %2 from %3)';
				|it = '%1 (№%2 del %3)';
				|pl = '%1 (Nr %2 z %3)';
				|tr = '%1 (%3 itibarıyla %2 numaralı)'"), 
				Format(String.Count, "NFD=3"), String.DocumentNumber, 
				Format(String.DocumentDate, "DLF=D"));
		DocumentsList.Add(String.Document, DocumentPresentation);
	EndDo;
	
	Return DocumentsList;
	
EndFunction

&AtServer
Function ListOfOrdersByLine(RowKey)
	
	QueryText = 
	"SELECT ALLOWED
	|	ProductionOrder2_2ManufacturedProduct.Ref AS Document,
	|	ProductionOrder2_2.Date AS DocumentDate,
	|	ProductionOrder2_2.Number AS DocumentNumber,
	|	SUM(ProductionOrder2_2ManufacturedProduct.Count) AS Count
	|FROM
	|	Document.ProductionOrder2_2.ManufacturedProduct AS ProductionOrder2_2ManufacturedProduct
	|		LEFT JOIN Document.ProductionOrder2_2 AS ProductionOrder2_2
	|		ON ProductionOrder2_2ManufacturedProduct.Ref = ProductionOrder2_2.Ref
	|WHERE
	|	ProductionOrder2_2.Posted
	|	AND NOT ProductionOrder2_2ManufacturedProduct.Canceled
	|	AND CASE
	|			WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				THEN TRUE
	|			ELSE ProductionOrder2_2.Department = &Department
	|		END
	|	AND NOT ProductionOrder2_2.Department IN (&DivisionsForWhichThereArePlans)
	|	AND ProductionOrder2_2.Status <> VALUE(Enum.ProductionOrderStatuses2_2.BeingGenerated)
	|	AND ProductionOrder2_2ManufacturedProduct.Products = &Products
	|	AND ProductionOrder2_2ManufacturedProduct.Characteristic = &Characteristic
	|	AND CASE
	|			WHEN &PlanningByAssignments
	|				THEN 
	|					CASE WHEN &ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly) THEN
	|						ProductionOrder2_2ManufacturedProduct.Purpose = &Purpose
	|					ELSE
	|						ProductionOrder2_2.AssignmentProducts = &Purpose
	|					END
	|			ELSE TRUE
	|		END
	
	|	AND ProductionOrder2_2ManufacturedProduct.Count <> 0
	|	AND CASE
	|			WHEN &BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|				THEN TRUE
	|			ELSE ProductionOrder2_2ManufacturedProduct.BillOfMaterials = &BillOfMaterials
	|		END
	|	AND ProductionOrder2_2.DemandDate BETWEEN &BeginOfPeriod AND &PeriodEnding
	|
	|GROUP BY
	|	ProductionOrder2_2ManufacturedProduct.Ref,
	|	ProductionOrder2_2.Date,
	|	ProductionOrder2_2.Number
	|";
	
	If ThisIsDisassembly Then
		
		QueryText = StrReplace(QueryText, "DemandDate", "EarliestStartDate");
		
	EndIf;
	
	Query = New Query(QueryText);
	
	For Each Property In RowKey Do
		
		Query.SetParameter(Property.Key, Property.Value);
		
	EndDo;
	
	DivisionsForWhichThereArePlans = New Array;
	
	If Not ValueIsFilled(RowKey.Department) Then

		RowKey.Delete("Department");
		RowKey.Delete("BeginOfPeriod");
		RowKey.Delete("PeriodEnding");
		If ThisIsDisassembly Then
			RowKey.Delete("ProductionIssuePeriodStart");
			RowKey.Delete("DateOfProduction");
		Else
			RowKey.Delete("OrderDate");
			RowKey.Delete("OrderPeriodEnd");
		EndIf;
		
		RowKey.Insert("EditBusinessUnit", False);
		
		FoundRows = TableOrderGeneration.FindRows(RowKey);
		For Each String In FoundRows Do
			DivisionsForWhichThereArePlans.Add(String.ProductionDispatcherBusinessUnit);
		EndDo;
		
	EndIf;
	Query.SetParameter("DivisionsForWhichThereArePlans", DivisionsForWhichThereArePlans);
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("ProductionProcessType",  Object.ProductionProcessType);
	
	Selection = Query.Execute().Select();
	DocumentsList = New ValueList();
	While Selection.Next() Do
		
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (STT %2 ngày %3)';
				|ru = '%1 (№ %2 от %3)';
				|en = '%1 (No. %2 from %3)'; fa = '%1 (No. %2 from %3)';
				|it = '%1 (№%2 del %3)';
				|pl = '%1 (Nr %2 z %3)';
				|tr = '%1 (%3 itibarıyla %2 numaralı)'"), 
				Format(Selection.Count, "NFD=3"), Selection.DocumentNumber, 
				Format(Selection.DocumentDate, "DLF=D"));
		DocumentsList.Add(Selection.Document, DocumentPresentation);
		
	EndDo;
	
	Return DocumentsList;
	
EndFunction

&AtServer
Function ListOfOrdersByRow(RowKey)
	
	Query = GetRequestWithDataLayoutSelections(AddressOfDataCompositionSchemaQuantityInOrders, SettingsComposerQuantityInPlansInOrders, True);
	
	Query.SetParameter("Scenario",			Object.Scenario);
	Query.SetParameter("Department",		RowKey.Department);
	Query.SetParameter("FilterDepartments",	ValueIsFilled(RowKey.Department));
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Products", RowKey.Products);
	Query.SetParameter("Characteristic", RowKey.Characteristic);
	Query.SetParameter("Purpose", RowKey.Purpose);
	Query.SetParameter("FilterByAssignment", ValueIsFilled(Object.Purpose));
	Query.SetParameter("ProductionProcessType", Object.ProductionProcessType);

	ResultTable2 = Query.Execute().Unload();
	
	DocumentsList = New ValueList();
	For Each String In ResultTable2 Do
		
		If Not ValueIsFilled(RowKey.Department) 
			And ValueIsFilled(String.Department) Then
			Continue;
		EndIf;
		
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (STT %2 ngày %3)';
				|ru = '%1 (№ %2 от %3)';
				|en = '%1 (No. %2 from %3)'; fa = '%1 (No. %2 from %3)';
				|it = '%1 (№%2 del %3)';
				|pl = '%1 (Nr %2 z %3)';
				|tr = '%1 (%3 itibarıyla %2 numaralı)'"), 
				Format(String.Count, "NFD=3"), String.DocumentNumber, 
				Format(String.DocumentDate, "DLF=D"));
		DocumentsList.Add(String.Document, DocumentPresentation);
	EndDo;
	
	Return DocumentsList;
	
EndFunction

&AtClient
Procedure SelectingPlanDocumentFromList(SelectionResult, AdditionalParameters) Export 

	If Not SelectionResult = Undefined Then 
		
		Document = SelectionResult.Value;
		FormParameters = New Structure("Key", Document);
		OpenForm("Document.ProductionPlan.ObjectForm", FormParameters, ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure SelectingOrderDocumentFromList(SelectionResult, AdditionalParameters) Export 

	If Not SelectionResult = Undefined Then 
		
		Document = SelectionResult.Value;
		FormParameters = New Structure("Key", Document);
		
		If TypeOf(Document) = Type("DocumentRef.ProductionOrder2_2") Then
			OpenForm("Document.ProductionOrder2_2.ObjectForm", FormParameters, ThisForm);
		EndIf;
		
	EndIf;

EndProcedure 

#EndRegion

#Region CreateDeleteOrders

&AtServer
Procedure CreateOrdersOnServer()
	
	Filter = New Structure("SelectToOrder", True);
	TheOrdersTable = Object.GenerationOfOrders.Unload(Filter, "
		| ProductionDispatcherBusinessUnit,
		| Products,
		| Characteristic,
		| Purpose,
		| LineOfBusiness,
		| MaterialProvider,
		| Contract,
		| BillOfMaterials,
		| Warehouse,
		| OrderDate,
		| DateOfProduction,
		| Package,
		| NumberOfPackages,
		| Count");
	
	If Not UseSeveralWarehouses Then
		TheOrdersTable.FillValues(DefaultWarehouse, "Warehouse");
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TheOrdersTable.ProductionDispatcherBusinessUnit,
	|	TheOrdersTable.Products,
	|	TheOrdersTable.Characteristic,
	|	TheOrdersTable.Purpose,
	|	TheOrdersTable.LineOfBusiness,
	|	TheOrdersTable.MaterialProvider,
	|	TheOrdersTable.Contract,
	|	TheOrdersTable.BillOfMaterials,
	|	TheOrdersTable.Warehouse,
	|	TheOrdersTable.OrderDate,
	|	TheOrdersTable.DateOfProduction,
	|	TheOrdersTable.Package,
	|	TheOrdersTable.NumberOfPackages,
	|	TheOrdersTable.Count
	|INTO TheOrdersTable
	|FROM
	|	&TheOrdersTable AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.NumberOfPackages > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TheOrdersTable.ProductionDispatcherBusinessUnit,
	|	TheOrdersTable.Products,
	|	TheOrdersTable.Characteristic,
	|	TheOrdersTable.Purpose,
	|	TheOrdersTable.LineOfBusiness,
	|	TheOrdersTable.MaterialProvider,
	|	TheOrdersTable.Contract.ContractType AS ContractType,
	|	TheOrdersTable.Contract,
	|	TheOrdersTable.BillOfMaterials,
	|	TheOrdersTable.Warehouse,
	|	TheOrdersTable.OrderDate AS OrderDate,
	|	TheOrdersTable.DateOfProduction,
	|	TheOrdersTable.Package,
	|	TheOrdersTable.NumberOfPackages,
	|	TheOrdersTable.Count
	|FROM
	|	TheOrdersTable AS TheOrdersTable
	|
	|GROUP BY
	|	TheOrdersTable.ProductionDispatcherBusinessUnit,
	|	TheOrdersTable.Products,
	|	TheOrdersTable.Characteristic,
	|	TheOrdersTable.Purpose,
	|	TheOrdersTable.LineOfBusiness,
	|	TheOrdersTable.MaterialProvider,
	|	TheOrdersTable.Contract,
	|	TheOrdersTable.Count,
	|	TheOrdersTable.BillOfMaterials,
	|	TheOrdersTable.NumberOfPackages,
	|	TheOrdersTable.Package,
	|	TheOrdersTable.Warehouse,
	|	TheOrdersTable.OrderDate,
	|	TheOrdersTable.DateOfProduction
	|
	|ORDER BY
	|	OrderDate";
	
	Query.SetParameter("TheOrdersTable", TheOrdersTable);
	
	ErrorList = New ValueList;
	
	TheOrdersTable = Query.Execute().Unload();
	
	Columns = "ProductionDispatcherBusinessUnit";

		Columns = Columns + ",MaterialProvider,Contract,ContractType";
		If (SplitOrdersByReleaseLaunchDates Or Not DynamicStructure) Then
			Columns = Columns + ",OrderDate,DateOfProduction";
		EndIf;
	
	If SplitOrdersByWarehouses Then
		Columns = Columns + ",Warehouse";
	EndIf;
	
	If SplitOrdersByAssignments Then
		Columns = Columns + ",Purpose";
	EndIf;
	
	DocumentsTable = TheOrdersTable.Copy(, Columns);
	DocumentsTable.GroupBy(Columns,);
	CurrentDate = CurrentSessionDate();
	For Each DocumentLine In DocumentsTable Do; 
		
		FillingData = New Structure(Columns);
		FillPropertyValues(FillingData, DocumentLine);
		Goods = TheOrdersTable.Copy(FillingData);
		
		If Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
			FillingData.Insert("AssignmentProducts", DocumentLine.Purpose);
			
			Goods.FillValues(Catalogs.Assignments.EmptyRef(), "Purpose");
		EndIf;
		
		// Let's change the column names to the necessary names of the "Products" tabular part
		Goods.Columns.OrderDate.Name = "EarliestStartDate";
		Goods.Columns.DateOfProduction.Name = "DemandDate";
		
		FillingData.Insert("Goods", Goods);
		FillingData.Insert("Department", DocumentLine.ProductionDispatcherBusinessUnit);
		FillingData.Insert("Organization", Object.Organization); 
		
		If Not DynamicStructure Then
			FillingData.Insert("ProductionScheduling", Object.ProductionScheduling); // in orders with a dynamic structure, issue placement is not used
		EndIf;
		
		If SplitOrdersByAssignments Then
			FillingData.Insert("LineOfBusiness", Goods[0].LineOfBusiness);
		Else
			LinesOfBusiness = Goods.Copy(,"LineOfBusiness");
			LinesOfBusiness.GroupBy("LineOfBusiness");
			If LinesOfBusiness.Count() = 1 Then
				FillingData.Insert("LineOfBusiness", LinesOfBusiness[0].LineOfBusiness);
			EndIf
		EndIf;
		
		
		If
			ValueIsFilled(DocumentLine.MaterialProvider)
			And DocumentLine.ContractType = Enums.ContractTypes.ReceiptForTolling2_5 Then
			FillingData.Insert(
				"BusinessOperation", Enums.BusinessTransactions.TollManufacturing2_5);
			FillingData.Insert("Partner", DocumentLine.MaterialProvider);
			FillingData.Insert("Contract", DocumentLine.Contract);
		EndIf;
		
			FillingData.Insert("ProductionProcessType", Object.ProductionProcessType);
			FillingData.Insert("Source", "GenerationOfProductionOrdersByPlans");
		
			DocumentObject = Documents.ProductionOrder2_2.CreateDocument();
			DocumentObject.Status = Enums.ProductionOrderStatuses2_2.ToProduce;
		DocumentObject.Date = CurrentDate;
		DocumentObject.Fill(FillingData);
		
		RecordOrderOnServer(DocumentObject, ErrorList);
		
	EndDo; 
	
	For Each ListItem In ErrorList Do
		CommonClientServer.MessageToUser(ListItem.Presentation, ListItem.Value);
		ListItem.Value = Undefined;
	EndDo;
	ErrorList = Undefined;
	
EndProcedure

&AtServer
Procedure RecordOrderOnServer(DocumentObject, ErrorList)

	If DocumentObject = Undefined Then
		Return;
	EndIf; 
	
	DocumentObject.Comment = NStr("vi = 'Được tạo tự động bằng bộ xử lý ""Lập đơn đặt hàng để sản xuất theo kế hoạch"".';
									|ru = 'Сформирован автоматически обработкой ""Формирование заказов на производство по плану"".';
									|en = 'Generated automatically using data processor ""Convert plan to production orders"".'; fa = 'Generated automatically using data processor ""Convert plan to production orders"".';
									|it = 'Formato automaticamente dall''elaborazione ""Formazione di ordini di produzione secondo il piano"".';
									|pl = 'Utworzono automatycznie procedurą przetwarzania ""Формирование заказов на производство по плану"".';
									|tr = '""Plana göre üretim emirlerini oluşturma"" işlenerek otomatik olarak oluşturuldu'");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	CachedValues = Undefined;
	
	BatchProcessingOfTablePartServer.TreatTS(DocumentObject.ManufacturedProduct, StructureOfActions, CachedValues);
	
	TextOfRecordingError = NStr("vi = '%1 không thể ghi lại chứng từ do nguyên nhân:
								|%2';
								|ru = '%1 невозможно записать документ по причине:
								|%2';
								|en = 'Cannot save the document %1. Reason:
								|%2'; fa = 'Cannot save the document %1. Reason:
								|%2';
								|it = '%1 non è possibile salvare il documento a causa di:
								|%2';
								|pl = '%1 niemożliwe jest zapisać dokumentu z powodu:
								|%2';
								|tr = '
								|%2sebeplerinden dolayı %1 belgeyi kaydetmek mümkün değil'");
	FillingErrorText = NStr("vi = '%1 không thể kết chuyển theo nguyên nhân điền sai.';
							|ru = '%1 невозможно провести по причине некорректного заполнения.';
							|en = 'Cannot post %1. Reason: the document is filled incorrectly.'; fa = 'Cannot post %1. Reason: the document is filled incorrectly.';
							|it = '%1 non è possibile registrare a causa della compilazione non corretta.';
							|pl = '%1 niemożliwe jest zatwierdzenie z powodu niepoprawnego wypełnienia.';
							|tr = '%1 doğru olmayan doldurmadan dolayı kaydetmek mümkün değil.'");
	
	Try
		
		If DocumentObject.CheckFilling() Then
			DocumentObject.Write(DocumentWriteMode.Posting);
		Else
			Messages = GetUserMessages(True);
			DocumentObject.Write(DocumentWriteMode.Write);
			ErrorList.Add(DocumentObject,
				StringFunctionsClientServer.SubstituteParametersToString(FillingErrorText, String(DocumentObject.Ref)));
		EndIf;
		
		GeneratedOrders.Add(DocumentObject.Ref);
		
	Except
		WriteLogEvent(NStr("vi = 'Lập đơn đặt hàng sản xuất theo kế hoạch';
							|ru = 'Формирование заказов на производство по плану';
							|en = 'Convert plan to production orders'; fa = 'تبدیل برنامه به سفارش‌های تولید';
							|it = 'Creazione di ordini di produzione in base al piano';
							|pl = 'Tworzenie zamówień na produkcję wg planu';
							|tr = 'Plana göre üretim emirlerini oluşturma'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
			
		ErrorText = ErrorDescription();
		ErrorList.Add(DocumentObject,
			StringFunctionsClientServer.SubstituteParametersToString(TextOfRecordingError, String(DocumentObject.Ref), ErrorText));
		
	EndTry;

EndProcedure

&AtServerNoContext
Function MarkDocumentsForDeletion_(LinksToMarkDelete)
	
	ErrorList = TMCommonUse.SetMarkForDeletingDocuments(LinksToMarkDelete);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TRUE AS Field1
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.Ref IN(&Ref)
		|		AND NOT DocumentsRegistry.DeletionMark";
	
	Query.SetParameter("Ref", LinksToMarkDelete);
	
	If Query.Execute().IsEmpty() Then
		Return True;
	Else
		CommonClientServer.ReportErrorsToUser(ErrorList);
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions_

&AtServerNoContext
Function ScriptDetailsValues(Scenario)
	
	If ValueIsFilled(Scenario) Then
		
		Result = Common.ObjectAttributesValues(Scenario, "Periodicity, PlanningByAssignments, UseForMaterialsPlanning");
		
	Else
		
		Result = New Structure;
		Result.Insert("Periodicity", Undefined);
		Result.Insert("PlanningByAssignments", False);
		Result.Insert("UseForMaterialsPlanning", True);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure BringDatesToPeriodicityOfScript(Form, StartDate, EndDate)
	
	NewStartDate = PlanningClientServerCached.CalculateStartDateOfPeriod(
		StartDate, Form.Periodicity);
	
	StartDate = ?(ValueIsFilled(StartDate), NewStartDate, StartDate);
	
	NewEndDate = PlanningClientServerCached.CalculatePeriodEndDate(
		EndDate, Form.Periodicity);
		
	EndDate = ?(ValueIsFilled(EndDate), NewEndDate, EndDate);
	
EndProcedure

&AtServer
Procedure UpdateAtServer()
	
	Query = GetRequestWithDataLayoutSelections(AddressOfDataCompositionSchema, SettingsComposer);
	
	Query.SetParameter("Scenario",			Object.Scenario);
	Query.SetParameter("Department",		Object.Department);
	Query.SetParameter("FilterDepartments", FilterDepartments);
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Purpose", Object.Purpose);
	Query.SetParameter("FilterByAssignment", ValueIsFilled(Object.Purpose));
	Query.SetParameter("ProductionProcessType", Object.ProductionProcessType);
	Query.SetParameter("PlacementOfIssueByEnd",
		Object.ProductionScheduling = PredefinedValue("Enum.WayOfLinkingProductionOperations.ToFinish"));
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Table = Result.Unload();
		TableOrderGeneration.Load(Table);
		If FilterDepartments Then
			TableFormationOfOrdersWithSelection = Table.Copy(New Structure("ProductionDispatcherBusinessUnit", Object.Department));
		Else
			TableFormationOfOrdersWithSelection = Table;
		EndIf;
		
		Object.GenerationOfOrders.Load(TableFormationOfOrdersWithSelection);
		
		If Object.GenerateOrdersByUpToDateBillsOfMaterials Then
			
			BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
			BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
			
			BOMSelectionParameters.AvailableTypes.Add(Object.ProductionProcessType);
			
			ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
			
			ChoiceParameterLinks.Products            = "Object.GenerationOfOrders.Products";
			ChoiceParameterLinks.Characteristic          = "Object.GenerationOfOrders.Characteristic";
			ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.GenerationOfOrders.ProductionDispatcherBusinessUnit";
			ChoiceParameterLinks.LineOfBusiness = "Object.GenerationOfOrders.LineOfBusiness";
			ChoiceParameterLinks.ProductionStart      = StrTemplate("Object.GenerationOfOrders.%1", ?(ThisIsDisassembly, "OrderDate", "ProductionIssuePeriodStart"));
			BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.GenerationOfOrders.BillOfMaterials", ChoiceParameterLinks);
			
			RowsArray = New Array;
			DataArray = New Array;
			
		EndIf;
		
		For Each OrderLine In Object.GenerationOfOrders Do
			OrderLine.Period.StartDate    = ?(ThisIsDisassembly, OrderLine.OrderDate, OrderLine.ProductionIssuePeriodStart);
			OrderLine.Period.EndDate = ?(ThisIsDisassembly, OrderLine.OrderPeriodEnd, OrderLine.DateOfProduction);
			
			If Object.GenerateOrdersByUpToDateBillsOfMaterials Then
				RowsArray.Add(OrderLine);
				
				ProductData = ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
					Object, OrderLine, BOMSelectionParameters, ThisObject, New Structure("KeyOfDataPaths", "Object.GenerationOfOrders"));
				
				DataArray.Add(ProductData);
			EndIf;
			
		EndDo;
		
		If Object.GenerateOrdersByUpToDateBillsOfMaterials Then
			ProductDataManagement.FillInSpecificationInLines(RowsArray, DataArray, BOMSelectionParameters);
		EndIf;
	
	EndIf;
	
	SetFormItemsVisibility();
	
EndProcedure

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.1, True);

EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable() Then
		If CheckIfThereAreDocumentsToUpdate() Then
			ShowQueryBox(
				New CallbackDescription("NotificationProcessingCompletion", ThisObject), 
				NStr("vi = 'Đơn đặt hàng sản xuất đã được thay đổi. Bạn muốn cập nhật dữ liệu của bạn? Khi cập nhật, các dòng sẽ bị xóa.';
					|ru = 'Заказы на производство были изменены. Хотите обновить данные? При обновлении строки будут очищены.';
					|en = 'Production orders were changed. Do you want to update the data? Lines will be cleared during update.'; fa = 'Production orders were changed. Do you want to update the data? Lines will be cleared during update.';
					|it = 'Ordini di produzione sono stati modificati. Volete aggiornare i dati? Durante l''aggiornamento le righe saranno cancellate.';
					|pl = 'Zlecenia produkcyjne zostały zmienione. Chcesz aktualizować dane? Podczas aktualizacji wiersze zostaną oczyszczone.';
					|tr = 'Üretim emri değiştirildi. Verileri güncellemek ister misiniz? Satırlar güncellemek için silinecektir.'"), 
				QuestionDialogMode.YesNo,
				,
				,
				NStr("vi = 'Lập đơn đặt hàng sản xuất theo kế hoạch';
					|ru = 'Формирование заказов на производство по плану';
					|en = 'Convert plan to production orders'; fa = 'تبدیل برنامه به سفارش‌های تولید';
					|it = 'Creazione di ordini di produzione in base al piano';
					|pl = 'Tworzenie zamówień na produkcję wg planu';
					|tr = 'Plana göre üretim emirlerini oluşturma'"));
		EndIf;
	Else
		UpdateDataWhenFormBecomesActive();
	EndIf;

EndProcedure

&AtServer
Function CheckIfThereAreDocumentsToUpdate()
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	TableOrderGeneration.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
	|	TableOrderGeneration.Products AS Products,
	|	TableOrderGeneration.Characteristic AS Characteristic,
	|	TableOrderGeneration.BillOfMaterials AS BillOfMaterials,
	|	TableOrderGeneration.ProductionIssuePeriodStart AS ProductionIssuePeriodStart,
	|	TableOrderGeneration.DateOfProduction AS DateOfProduction,
	|	TableOrderGeneration.OrderDate AS OrderDate,
	|	TableOrderGeneration.OrderPeriodEnd AS OrderPeriodEnd,
	|	TableOrderGeneration.EditBusinessUnit AS EditBusinessUnit
	|INTO TableOrderGeneration
	|FROM
	|	&TableOrderGeneration AS TableOrderGeneration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductionOrder2_2ManufacturedProduct.Ref AS Document
	|FROM
	|	Document.ProductionOrder2_2.ManufacturedProduct AS ProductionOrder2_2ManufacturedProduct
	|		INNER JOIN TableOrderGeneration AS TableOrderGeneration
	|		ON ProductionOrder2_2ManufacturedProduct.Products = TableOrderGeneration.Products
	|			AND ProductionOrder2_2ManufacturedProduct.Characteristic = TableOrderGeneration.Characteristic
	|WHERE
	|	ProductionOrder2_2ManufacturedProduct.Ref.Posted
	|	AND CASE
	|			WHEN TableOrderGeneration.EditBusinessUnit
	|				THEN TRUE
	|			ELSE ProductionOrder2_2ManufacturedProduct.Ref.Department = TableOrderGeneration.ProductionDispatcherBusinessUnit
	|		END
	|	AND ProductionOrder2_2ManufacturedProduct.Ref.Status <> VALUE(Enum.ProductionOrderStatuses2_2.BeingGenerated)
	|	AND (&ThisIsDisassembly
	|			OR ProductionOrder2_2ManufacturedProduct.Ref.DemandDate BETWEEN TableOrderGeneration.ProductionIssuePeriodStart AND TableOrderGeneration.DateOfProduction)
	|	AND (NOT &ThisIsDisassembly
	|			OR ProductionOrder2_2ManufacturedProduct.Ref.EarliestStartDate BETWEEN TableOrderGeneration.OrderDate AND TableOrderGeneration.OrderPeriodEnd)
	|	AND ProductionOrder2_2ManufacturedProduct.Ref IN(&DocumentListForUpdate)
	|";
	
	Query.SetParameter("DocumentListForUpdate", DocumentListForUpdate);
	Query.SetParameter("Department", Object.Department);
	Query.SetParameter("TableOrderGeneration", TableOrderGeneration.Unload());
	Query.SetParameter("ThisIsDisassembly", ThisIsDisassembly);
	
	OrdersAreNotIncludedInPlans = Query.Execute().IsEmpty();
	DocumentListForUpdate.Clear();
	
	Return Not OrdersAreNotIncludedInPlans;
	
EndFunction

&AtServer
Procedure DisplayOrdersForCheckoutOnServer()
	
	DisplayOrdersForRegistration = Not DisplayOrdersForRegistration;
	SetFormItemsVisibility();
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderCart()
	
	Filter = New Structure("SelectToOrder", True);
	Columns = "ProductionDispatcherBusinessUnit";
	
		If (SplitOrdersByReleaseLaunchDates Or Not DynamicStructure) Then
			Columns = Columns + ", OrderDate, DateOfProduction";
		EndIf;
	If SplitOrdersByWarehouses Then
		Columns = Columns + ",Warehouse";
	EndIf;	
	If SplitOrdersByAssignments Then
		Columns = Columns + ",Purpose";
	EndIf;
	
	OrderBasketTable = Object.GenerationOfOrders.Unload(Filter, Columns + ", NumberOfPackages");
	For Each String In OrderBasketTable Do
		If String.NumberOfPackages>0 Then
			String.NumberOfPackages = 1;
		EndIf;
	EndDo;
	
	OrderBasketTable.GroupBy(Columns, "NumberOfPackages");
	OrderBasket.Clear();
	
	For Each String In OrderBasketTable Do
		If String.NumberOfPackages = 0 Then
			Continue;
		EndIf;
		NewRow = OrderBasket.Add();
		FillPropertyValues(NewRow, String);
		NewRow.TotalRows = String.NumberOfPackages;
			If (SplitOrdersByReleaseLaunchDates Or Not DynamicStructure) Then
				NewRow.EarliestStartDate = String.OrderDate;
				NewRow.DemandDate = String.DateOfProduction;
			EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SwitchCheckboxes(Install)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each SelectedRow In Items.GenerationOfOrders.SelectedRows Do
		
		TableRow = Object.GenerationOfOrders.FindByID(SelectedRow);
		
		If Install And Not TableRow.SelectToOrder And TableRow.NumberOfPackages > 0 Then
			
			TableRow.SelectToOrder = True;
			
		ElsIf Not Install And TableRow.SelectToOrder Then
			
			TableRow.SelectToOrder = False;
		
		EndIf;
		
	EndDo;
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtServer
Function GetDivisionsWithPlansOnSelectedLines(RowsIDs)
	
	Table = TableOrderGeneration.Unload();
	TableSelectedRows = Table.CopyColumns();
	
	For Each Id In RowsIDs Do
		NewRow = TableSelectedRows.Add();
		FillPropertyValues(NewRow, Object.GenerationOfOrders.FindByID(Id));
	EndDo;
	
	QueryText =
	"SELECT DISTINCT
	|	TableSelectedRows.Products AS Products,
	|	TableSelectedRows.Characteristic AS Characteristic,
	|	TableSelectedRows.BillOfMaterials AS BillOfMaterials,
	|	TableSelectedRows.ProductionIssuePeriodStart AS ProductionIssuePeriodStart
	|INTO TableSelectedRows
	|FROM
	|	&TableSelectedRows AS TableSelectedRows
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOrderGeneration.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
	|	TableOrderGeneration.Products AS Products,
	|	TableOrderGeneration.Characteristic AS Characteristic,
	|	TableOrderGeneration.BillOfMaterials AS BillOfMaterials,
	|	TableOrderGeneration.ProductionIssuePeriodStart AS ProductionIssuePeriodStart,
	|	TableOrderGeneration.EditBusinessUnit AS EditBusinessUnit
	|INTO TableOrderGeneration
	|FROM
	|	&TableOrderGeneration AS TableOrderGeneration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOrderGeneration.ProductionDispatcherBusinessUnit
	|FROM
	|	TableOrderGeneration AS TableOrderGeneration
	|		INNER JOIN TableSelectedRows AS TableSelectedRows
	|		ON TableOrderGeneration.Products = TableSelectedRows.Products
	|			AND TableOrderGeneration.Characteristic = TableSelectedRows.Characteristic
	|			AND TableOrderGeneration.BillOfMaterials = TableSelectedRows.BillOfMaterials
	|			AND TableOrderGeneration.ProductionIssuePeriodStart = TableSelectedRows.ProductionIssuePeriodStart
	|			AND (TableOrderGeneration.EditBusinessUnit = FALSE)";
	
	If ThisIsDisassembly Then
		QueryText = StrReplace(QueryText, "ProductionIssuePeriodStart", "OrderPeriodEnd");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("TableOrderGeneration",Table);
	Query.SetParameter("TableSelectedRows",TableSelectedRows);
	
	Return Query.Execute().Unload().UnloadColumn("ProductionDispatcherBusinessUnit");
	
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
	If Item.Name = "sh_ShamsiInput_PeriodBeginning" Then
		PeriodBeginningOnChange(Items.PeriodBeginning);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnd" Then
		PeriodEndOnChange(Items.PeriodEnd);
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
