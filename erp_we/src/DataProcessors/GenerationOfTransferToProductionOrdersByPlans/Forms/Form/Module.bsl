
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

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
	
	UseProductionManagement2_2 = GetFunctionalOption("UseProductionManagement2_2");
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	RestoreSettings();
	Object.Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	
	ScenarioData = ScriptDetailsValues(Object.Scenario);
	FillPropertyValues(ThisObject, ScenarioData);
	
	ModeForCalculatingNeedsOfPlanWhenChangingOnServer();
	BringDatesToPeriodicityOfScript(ThisObject, Object.PeriodBeginning, Object.PeriodEnd);
	
	SetFormItemsVisibility();
	VisibilitySettingsWhenChangingSubdividingSelectionOnServer(ThisForm);
	VisibilitySettingsWhenChangingScript(ThisForm);
	
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
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_OrderOfMaterialsForProduction"  And Items.PagesMainPanel.CurrentPage = Items.PageStep2 Then
		
		DocumentListForUpdate.Add(Source);
		UpdateDataWhenFormBecomesActive();
		
	ElsIf EventName = "SelectionAndFormationOfOrdersForTransferToProductionAccordingToPlanHasBeenEstablished" Then
		
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
Procedure GenerationOfOrdersNumberOfPackagesOnChange(Item)
	
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
	RowKey.Insert("BeginOfPeriod", 	CurRow.DemandPeriodStart);
	RowKey.Insert("PeriodEnding", EndOfDay(CurRow.DemandPeriodEnd));
	
	If UseProductionManagement2_2 Then
		RowKey.Insert("Warehouse", 					CurRow.ShopFloorStockroom);
	Else
		RowKey.Insert("Warehouse", 					CurRow.Warehouse);
	EndIf;
	
	RowKey.Insert("AssigneeBusinessUnit", CurRow.AssigneeBusinessUnit);
	RowKey.Insert("Scenario", 				Object.Scenario);
		
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
	RowKey.Insert("Purpose", 		CurRow.Purpose);
	RowKey.Insert("BeginOfPeriod", 	CurRow.DemandPeriodStart);
	RowKey.Insert("PeriodEnding", EndOfDay(CurRow.DemandPeriodEnd));
	
	RowKey.Insert("UseProductionManagement2_2", UseProductionManagement2_2);
	If UseProductionManagement2_2 Then
		RowKey.Insert("Warehouse", CurRow.ShopFloorStockroom);
	Else
		RowKey.Insert("Warehouse", CurRow.Warehouse);
	EndIf;
		
	RowKey.Insert("AssigneeBusinessUnit", CurRow.AssigneeBusinessUnit);
	
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
Procedure GenerationOfOrdersWarehouseOnChange(Item)
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersShopFloorStockroomOnChange(Item)
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
		
	If String <> Undefined And (Field.Name = "OrderBasketAssigneeBusinessUnit"
		Or Field.Name = "OrderBasketWarehouse") Then
		BucketRow = OrderBasket.FindByID(String);
		If Field.Name = "OrderBasketAssigneeBusinessUnit" Then
			FieldsNames = "AssigneeBusinessUnit";
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chỉ định bộ phận thực thi cho sản phẩm đã chọn: %1?';
					|ru = 'Назначить для выделенного товара подразделение-исполнитель: %1?';
					|en = 'Assign an assignee business unit: %1 to the selected goods?'; fa = 'Assign an assignee business unit: %1 to the selected goods?';
					|it = 'Assegnare per la merce selezionata il reparto-esecutore:%1?';
					|pl = 'Wyznaczyć dla wydzielonego towaru dział wykonawcy: %1?';
					|tr = 'Seçili ürün için atanan departman görevlendirilsin mi : %1?'"), BucketRow.AssigneeBusinessUnit);
		ElsIf Field.Name = "OrderBasketWarehouse" Then
			FieldsNames = "Warehouse";
			QueryText =StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ấn định kho bãi cho hàng hóa được chọn: %1?';
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
			If Not TSRow.EditWarehouse And FieldsNames = "Warehouse" Then
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

#Region CommandHandlers

&AtClient
Procedure PickProducts(Command)
	
	FormParameters = New Structure("SettingsComposer", SettingsComposer);
	OpenForm("DataProcessor.GenerationOfTransferToProductionOrdersByPlans.Form.FilterForm", FormParameters, ThisForm, UUID);
	
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
		"DataProcessor.GenerationOfTransferToProductionOrdersByPlans.Form.Command.Fill");
	
	Object.DataPopulationMode = True;
	If Not CheckFilling() Then
		Object.DataPopulationMode = False;
		Return
	EndIf;
	Object.DataPopulationMode = False;
	
	If Object.GenerationOfOrders.Count() > 0 Then
		Mode = QuestionDialogMode.YesNo;
		Response = Undefined;
		
		ShowQueryBox(New CallbackDescription("FillCompletion", ThisObject), NStr("vi = 'Trong bảng có các dòng. Khi điền các dòng sẽ bị xóa. Tiếp tục?';
																				|ru = 'В таблице имеются строки. При заполнении строки будут очищены. Продолжить?';
																				|en = 'There are rows in the table. The rows will be cleared when populating. Continue?'; fa = 'There are rows in the table. The rows will be cleared when populating. Continue?';
																				|it = 'La tabella contiene delle righe. Durante la compilazione le righe saranno cancellate. Continuare?';
																				|pl = 'W tabeli są wiersze. Przy wypełnieniu wiersze będą oczyszczone. Kontynuować?';
																				|tr = 'Tabloda satırlar var. Satırlar doldurulmak için temizlenecek. Devam edilsin mi?'"), Mode, 0);
		Return;
	EndIf;
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure OpenOrderList(Command)
	
	OpenForm("Document.OrderOfMaterialsForProduction.ListForm"); 
	
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
Procedure UncheckAll(Command)
	
	SwitchCheckboxes(False);
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	SwitchCheckboxes(True);
	
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
Procedure FillTheShopStoreroom(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	Filter = New Structure("ShopFloorStockroom", True);
	
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);
	Warehouse = Undefined;
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	ChoiceFormParameters.Insert("Key", TableRow.ShopFloorStockroom);
	ChoiceFormParameters.Insert("Filter", Filter);
	
	Notification = New CallbackDescription(
		"FillShopPantryEnd",
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
	FormParameters.Insert("DemandPeriodStart", Items.GenerationOfOrders.CurrentData.DemandPeriodStart);
	FormParameters.Insert("PlanningType", "PlanningTransferOfMaterialsToProduction");
	
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
		"DataProcessor.GenerationOfTransferToProductionOrdersByPlans.Form.Command.Next");
	
	If Items.PagesMainPanel.CurrentPage = Items.PageStep1 Then
		
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
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersWarehouse.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.SelectToOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseProductionManagement2_2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersWarehouse.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersShopFloorStockroom.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.GenerationOfOrders.ShopFloorStockroom");

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
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
	
	Items.OrderGenerationTransferDistribute.Visible = Periodicity <> Enums.Periodicity.Day;
	Items.OrderFormationTheContextMenuToTransferToDistribute.Visible = Periodicity <> Enums.Periodicity.Day;
	
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
	
	Form.Items.GenerationOfOrdersAssigneeBusinessUnit.Visible = Not Form.FilterDepartments;
	Form.Items.OrderBasketAssigneeBusinessUnit.Visible = Not Form.FilterDepartments;
	
	Form.Items.GenerationOfOrdersShopFloorStockroom.Visible = Form.UseProductionManagement2_2;
	Form.Items.FormFillOutShopStoreroom.Visible = Form.UseProductionManagement2_2;
	Form.Items.OrderBasketShopFloorStockroom.Visible = Form.UseProductionManagement2_2;
	
	Form.Items.Department.Enabled = Form.FilterDepartments;
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilitySettingsWhenChangingScript(Form)
	
	DestinationVisibility = Form.PlanningByAssignments And Form.UseOrderSupplyWithAssignment;
	Form.Items.GroupAdditionalSelections.Visible = DestinationVisibility;
	Form.Items.GenerationOfOrdersPurpose.Visible = DestinationVisibility;
	
EndProcedure

#EndRegion

#Region ProceduresForWorkingWithUserSettings

&AtServer
Procedure InitializeSettingsComposer()
	
		If Object.DemandCalculationModeByPlan = 0
			Or Object.DemandCalculationModeByPlan = 1 Then
			DataCompositionSchema = DataProcessors.GenerationOfTransferToProductionOrdersByPlans.GetTemplate("CompositionTemplate2_2");
		Else
			DataCompositionSchema = DataProcessors.GenerationOfTransferToProductionOrdersByPlans.GetTemplate("CompositionTemplate22Accumulated");
			DataLayoutSchemeQuantityInPlans = DataProcessors.GenerationOfTransferToProductionOrdersByPlans.GetTemplate("CompositionTemplate2_2QuantityInPlans");
			DataLayoutDiagramQuantityInOrders = DataProcessors.GenerationOfTransferToProductionOrdersByPlans.GetTemplate("CompositionTemplate2_2QuantityInOrders");
		EndIf;
	
	DataCompositionSchema.DataSets[0].Query = Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False)
		+ InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
			DataCompositionSchema.DataSets[0].Query,
			"MainSupplyMethodSubstitution",
			"TableOfPlans.Products,TableOfPlans.Characteristic,TableOfPlans.Warehouse");
	If Object.DemandCalculationModeByPlan = 2
			Or Object.DemandCalculationModeByPlan = 3 Then
		DataLayoutSchemeQuantityInPlans.DataSets[0].Query = Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False)
			+ InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
				DataLayoutSchemeQuantityInPlans.DataSets[0].Query,
				"MainSupplyMethodSubstitution",
				"TableOfPlans.Products,TableOfPlans.Characteristic,TableOfPlans.Warehouse");
		DataLayoutDiagramQuantityInOrders.DataSets[0].Query = Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False)
			+ InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
				DataLayoutDiagramQuantityInOrders.DataSets[0].Query,
				"MainSupplyMethodSubstitution",
				"TableOfPlans.Products,TableOfPlans.Characteristic,TableOfPlans.Warehouse");
	EndIf;
				
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	AddressOfDataCompositionSchemaPlannedQuantity = PutToTempStorage(DataLayoutSchemeQuantityInPlans, New UUID);
	AddressOfDataCompositionSchemaQuantityInOrders = PutToTempStorage(DataLayoutDiagramQuantityInOrders, New UUID);
	
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
	Settings.Insert("UserSettings",  SettingsComposer.UserSettings);
	Settings.Insert("Scenario",                   Object.Scenario);
	Settings.Insert("AssigneeBusinessUnit",   Object.AssigneeBusinessUnit);
	Settings.Insert("PeriodBeginning",               Object.PeriodBeginning);
	Settings.Insert("PeriodEnd",            Object.PeriodEnd);
	Settings.Insert("DemandCalculationModeByPlan", Object.DemandCalculationModeByPlan);
	Settings.Insert("FilterDepartments",         FilterDepartments);
	Settings.Insert("Organization",                Object.Organization);
	Settings.Insert("Purpose",                 Object.Purpose);
	
	SaveSettingsAtServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(Settings)
	
	ObjectKey = "DataProcessor.GenerationOfTransferToProductionOrdersByPlans";
	Common.CommonSettingsStorageSave(ObjectKey, "Settings", Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	ObjectKey = "DataProcessor.GenerationOfTransferToProductionOrdersByPlans";
	SettingsValue = Common.CommonSettingsStorageLoad(ObjectKey, "Settings");
	
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		FillPropertyValues(Object, SettingsValue);
		FillPropertyValues(ThisForm, SettingsValue);
		
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
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderStartDate",    Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderEndDate", Object.PeriodEnd);
	Else
		DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod",    Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodEnding", Object.PeriodEnd);
	EndIf;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , , False, );
	
	Query = New Query(DataCompositionTemplate.DataSets.DataSet.Query);
	
	For Each LayoutParameter In DataCompositionTemplate.ParameterValues Do
		
		Query.SetParameter(LayoutParameter.Name, LayoutParameter.Value);
		
	EndDo;
	
	Return Query;
	
EndFunction

#EndRegion

#Region ProceduresCommandHandlersCompletion

&AtClient
Procedure SetPeriodIntervalCompletion(Result, AdditionalParameters) Export 
	
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
		If FilterDepartments Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Theo kịch bản %1, bộ phận thực thi %2 trong kỳ được chỉ định không yêu cầu chứng từ.';
					|ru = 'По сценарию %1 у подразделения исполнителя %2 за установленный период потребность в материалах отсутствует.';
					|en = 'By scenario %1 assignee business unit %2 does not need materials for the specified period.'; fa = 'By scenario %1 assignee business unit %2 does not need materials for the specified period.';
					|it = 'Secondo lo scenario %1 il reparto esecutore %2 nel periodo impostato non necessità di materiali.';
					|pl = 'Według scenariuszu %1 dla działu wykonawcy %2 za ustawiony okres nie ma zapotrzebowania w materiałach.';
					|tr = '%1 senaryosuna göre %2 atanan departmanın belirlenen dönemi için herhangi bir malzeme gereksinimi bulunmamaktadır.'"),
				Object.Scenario,
				Object.AssigneeBusinessUnit);
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong kịch bản %1, không cần vật liệu trong kỳ được chỉ định.';
					|ru = 'По сценарию %1 за установленный период потребность в материалах отсутствует.';
					|en = 'No demand for materials by the %1 scenario for the specified period.'; fa = 'No demand for materials by the %1 scenario for the specified period.';
					|it = 'Secondo lo scenario %1 nel periodo impostato non c''è necessità di materiali.';
					|pl = 'Według scenariuszu %1 za ustawiony okres nie ma zapotrzebowania w materiałach.';
					|tr = '%1 senaryosuna göre, belirlenen dönem için herhangi bir malzeme gereksinimi bulunmamaktadır.'"),
				Object.Scenario);
		EndIf;
		ShowMessageBox(, ErrorText);
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
	
	If WarehouseChanged And DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillShopPantryEnd(Result, AdditionalParameters) Export
	
	TableRow = AdditionalParameters.TableRow;
	
	ShopFloorStockroom = Result;
	
	If Not ValueIsFilled(ShopFloorStockroom) Then
		Return;
	EndIf; 
	
	ShopPantryChanged = False;
	
	For Each SelectedRow In Items.GenerationOfOrders.SelectedRows Do
		
		TableRow = Object.GenerationOfOrders.FindByID(SelectedRow);
		
		If TableRow.ShopFloorStockroom <> ShopFloorStockroom Then
			ShopPantryChanged = True;
			TableRow.ShopFloorStockroom = ShopFloorStockroom;
		EndIf;
		
	EndDo;
	
	If ShopPantryChanged And DisplayOrdersForRegistration Then
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

#EndRegion

#Region ProceduresForObtainingPlansAndOrders

&AtServer
Function ListOfPlansByLine(RowKey)

	Query = New Query();
	Query.Text = 
	"SELECT ALLOWED
	|	SUM(MaterialConsumptionPlansTurnovers.ToOrderTurnover) AS Count,
	|	MaterialConsumptionPlansTurnovers.Recorder AS Document,
	|	DocProductionPlan.Date AS DocumentDate,
	|	DocProductionPlan.Number AS DocumentNumber
	|FROM
	|	AccumulationRegister.MaterialConsumptionPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&PeriodEnding,
	|			Recorder,
	|			Scenario = &Scenario
	|				AND Status = VALUE(Enum.PlanStatuses.Upholded)
	|				AND Warehouse = &Warehouse
	|				AND Products = &Products
	|				AND Characteristic = &Characteristic
	|				AND Purpose = &Purpose
	|				AND AssigneeBusinessUnit = &AssigneeBusinessUnit) AS MaterialConsumptionPlansTurnovers
	|		INNER JOIN Document.ProductionPlan AS DocProductionPlan
	|		ON MaterialConsumptionPlansTurnovers.Recorder = DocProductionPlan.Ref
	|
	|GROUP BY
	|	MaterialConsumptionPlansTurnovers.Recorder,
	|	DocProductionPlan.PointInTime,
	|	DocProductionPlan.Date,
	|	DocProductionPlan.Number
	|
	|ORDER BY
	|	DocProductionPlan.PointInTime";
	
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
	
	Query.SetParameter("Scenario", Object.Scenario);
	Query.SetParameter("AssigneeBusinessUnit", RowKey.AssigneeBusinessUnit);
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Purpose", RowKey.Purpose);
	Query.SetParameter("Products", RowKey.Products);
	Query.SetParameter("Characteristic", RowKey.Characteristic);
	Query.SetParameter("Warehouse", RowKey.Warehouse);
	
	ResultTable2 = Query.Execute().Unload();
	
	DocumentsList = New ValueList();
	For Each String In ResultTable2 Do
		
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (STT %2 ngày %3)';
				|ru = '%1 (№ %2 от %3)';
				|en = '%1 (No. %2 dated %3)'; fa = '%1 (No. %2 dated %3)';
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
	
	Query = New Query();
	Query.Text = 
	"SELECT ALLOWED
	|	SUM(Orders.Count) AS Count,
	|	OrderDetails.Ref AS Document,
	|	OrderDetails.Date AS DocumentDate,
	|	OrderDetails.Number AS DocumentNumber
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS Orders
	|	
	|		INNER JOIN Document.OrderOfMaterialsForProduction AS OrderDetails
	|		ON Orders.Ref = OrderDetails.Ref
	|WHERE
	|	OrderDetails.Posted
	|	AND NOT Orders.Canceled
	|	AND Orders.Products = &Products
	|	AND Orders.Characteristic = &Characteristic
	|	AND CASE
	|			WHEN &PlanningByAssignments AND &Purpose<>VALUE(Catalog.Assignments.EmptyRef)
	|				THEN Orders.Purpose = &Purpose
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &UseProductionManagement2_2
	|				THEN OrderDetails.ShopFloorStockroom = &Warehouse
	|			ELSE OrderDetails.Warehouse = &Warehouse
	|		END
	|	AND Orders.ShipmentStart BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND OrderDetails.Department = &AssigneeBusinessUnit
	|
	|GROUP BY
	|	OrderDetails.Ref,
	|	OrderDetails.Date,
	|	OrderDetails.Number
	|
	|ORDER BY
	|	OrderDetails.PointInTime";
	
	For Each Property In RowKey Do
		
		Query.SetParameter(Property.Key, Property.Value);
		
	EndDo;
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	
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
	
	Query.SetParameter("Scenario", Object.Scenario);
	Query.SetParameter("AssigneeBusinessUnit", RowKey.AssigneeBusinessUnit);
	Query.SetParameter("FilterDepartments", ValueIsFilled(RowKey.AssigneeBusinessUnit));
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Purpose", RowKey.Purpose);
	Query.SetParameter("Products", RowKey.Products);
	Query.SetParameter("Characteristic", RowKey.Characteristic);
	Query.SetParameter("Warehouse", RowKey.Warehouse);
	
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
		OpenForm("Document.OrderOfMaterialsForProduction.ObjectForm", FormParameters, ThisForm);
		
	EndIf;

EndProcedure 

#EndRegion

#Region CreateDeleteOrders

&AtServer
Procedure CreateOrdersOnServer()
	
	If Not CheckFilling() Then
		Return;
	EndIf; 
	
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
	
	TheOrdersTable = Object.GenerationOfOrders.Unload(New Structure("SelectToOrder", True));
	Columns = "Warehouse,AssigneeBusinessUnit,ShopFloorStockroom";
	
	DocumentsTable = TheOrdersTable.Copy(, Columns);
	DocumentsTable.GroupBy(Columns,);
	CurrentDate = CurrentSessionDate();
	
	SupplyMethods = New Map;
	
	For Each DocumentLine In DocumentsTable Do
		
		TheStructureOfTheSearch = New Structure(Columns);
		FillPropertyValues(TheStructureOfTheSearch, DocumentLine);
		PickedRows = TheOrdersTable.FindRows(TheStructureOfTheSearch);
		
		If PickedRows.Count() = 0 Then
			Continue;
		EndIf; 
		
		DocumentObject = Documents.OrderOfMaterialsForProduction.CreateDocument();
		DocumentObject.Date = CurrentDate;
		
		DocumentObject.Comment = NStr("vi = 'Được tạo tự động bằng cách xử lý ""lập đơn đặt hàng để chuyển sang sản xuất theo kế hoạch"".';
										|ru = 'Сформирован автоматически обработкой ""Формирование заказов на передачу в производство по планам"".';
										|en = 'Generated automatically using the ""Convert plans to orders for transfer to production"" data processor.'; fa = 'Generated automatically using the ""Convert plans to orders for transfer to production"" data processor.';
										|it = 'Formato automaticamente dall''elaborazione ""Formazione di ordini di trasferimento dei materiali in produzione secondo i piani"".';
										|pl = 'Utworzono przez automatyczną procedurę przetwarzania ""Формирование заказов на передачу в производство по планам"".';
										|tr = '""Planlara göre üretime transferi esnasında siparişlerin oluşturulması"" otomatik veri işlemcisi oluşturuldu.'");
		
		If ValueIsFilled(PickedRows[0].SupplyMethod) Then
		
			WayParameters = SupplyMethods.Get(PickedRows[0].SupplyMethod);
			If WayParameters = Undefined Then
			
				WayParameters = Common.ObjectAttributesValues(PickedRows[0].SupplyMethod, "Organization, Department");
				SupplyMethods.Insert(PickedRows[0].SupplyMethod, WayParameters);
				
			EndIf; 
			
			FillPropertyValues(DocumentObject, WayParameters, "Organization, Department");
		EndIf;
		
		DocumentObject.Fill(Undefined);
		
		If ValueIsFilled(Object.Organization) Then
			DocumentObject.Organization = Object.Organization;
		EndIf;
		
		DocumentObject.Department = DocumentLine.AssigneeBusinessUnit;
		
		If UseProductionManagement2_2 Then
			DocumentObject.ShopFloorStockroom = DocumentLine.ShopFloorStockroom;
		EndIf;
		
		If ValueIsFilled(DocumentLine.Warehouse) Then
			DocumentObject.Warehouse = DocumentLine.Warehouse;
		EndIf;
		
		DocumentObject.Status = Enums.StatusesOfOrdersForMaterialsForProduction.ForCompletion;
		
		For Each OrderDataLine In PickedRows Do
			If OrderDataLine.NumberOfPackages = 0 Then
				Continue;
			EndIf;
			
			NewRow = DocumentObject.Goods.Add();
			NewRow.Products = OrderDataLine.Products;
			NewRow.Characteristic = OrderDataLine.Characteristic;
			NewRow.Purpose = OrderDataLine.Purpose;
			NewRow.Package = OrderDataLine.Package;
			NewRow.Count = OrderDataLine.Count;
			NewRow.NumberOfPackages = OrderDataLine.NumberOfPackages;
			NewRow.ShipmentStart = Max(OrderDataLine.DemandPeriodStart, CurrentDate);
			NewRow.ReceiptEnd = Max(OrderDataLine.DemandPeriodStart, CurrentDate);
			
		EndDo;
		
		ProvisionInDocumentsServer.FillInDefaultSecurityOption(DocumentObject.Goods);
		
		For Each String In DocumentObject.Goods Do
			If ValueIsFilled(String.Purpose) Then
				String.SupplyOption = Enums.SupplyOptions.ToSupply;
				String.WithAssignment = True;
			EndIf;
		EndDo;
		
		If DocumentObject.Goods.Count() > 0 Then
			
			Try
				
				If DocumentObject.CheckFilling() Then
					DocumentObject.Write(DocumentWriteMode.Write);
					GeneratedOrders.Add(DocumentObject.Ref);
					DocumentObject.Write(DocumentWriteMode.Posting);
				Else
					Messages = GetUserMessages(True);
					DocumentObject.Write(DocumentWriteMode.Write);
					GeneratedOrders.Add(DocumentObject.Ref);
					CommonClientServer.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(FillingErrorText, String(DocumentObject.Ref)), 
					DocumentObject);
				EndIf;
				
			Except
				
				WriteLogEvent(NStr("vi = 'Lập đơn hàng nguyên vật liệu trong sản xuất theo kế hoạch';
									|ru = 'Формирование заказов материалов в производство по планам';
									|en = 'Generation of material orders for shop floor stockroom according to plans'; fa = 'Generation of material orders for shop floor stockroom according to plans';
									|it = 'Formazione degli ordini di materiali da trasferire in produzione secondo i piani';
									|pl = 'Utworzenie zamówień materiałów do produkcji według planów';
									|tr = 'Planlara göre üretim için malzeme siparişlerinin oluşturulması'", CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
				
				ErrorText = ErrorDescription();
				CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(TextOfRecordingError, String(DocumentObject.Ref), ErrorText),
				DocumentObject);
				
			EndTry; 
			
		
		EndIf;
		
	EndDo; 
	
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
		
		Result = Common.ObjectAttributesValues(Scenario, "Periodicity, PlanningByAssignments");
		
	Else
		
		Result = New Structure;
		Result.Insert("Periodicity", Undefined);
		Result.Insert("PlanningByAssignments", False);
		
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
	
	SetPrivilegedMode(True);
	
	Query = GetRequestWithDataLayoutSelections(AddressOfDataCompositionSchema, SettingsComposer);
	
	Query.SetParameter("Scenario", Object.Scenario);
	Query.SetParameter("AssigneeBusinessUnit", Object.AssigneeBusinessUnit);
	Query.SetParameter("FilterDepartments", FilterDepartments);
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Purpose", Object.Purpose);
	Query.SetParameter("FilterByAssignment", ValueIsFilled(Object.Purpose));

	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		Object.GenerationOfOrders.Load(Result.Unload());
		
		For Each OrderLine In Object.GenerationOfOrders Do
			OrderLine.Period.StartDate    = OrderLine.DemandPeriodStart;
			OrderLine.Period.EndDate = OrderLine.DemandPeriodEnd;
		EndDo;
		
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
				NStr("vi = 'Đơn đề nghị xuất nguyên vật liệu vào sản xuất đã được thay đổi. Bạn muốn cập nhật dữ liệu của bạn? Khi cập nhật, các dòng sẽ bị xóa.';
					|ru = 'Заказы материалов в производство были изменены. Хотите обновить данные? При обновлении строки будут очищены.';
					|en = 'Material orders for shop floor stockroom were changed. Do you want to update the data? Lines will be cleared during update.'; fa = 'Material orders for shop floor stockroom were changed. Do you want to update the data? Lines will be cleared during update.';
					|it = 'Ordini di materiali da trasferire in produzione sono stati modificati. Volete aggiornare i dati? Durante l''aggiornamento le righe saranno cancellate.';
					|pl = 'Zamówienia materiałów na produkcje zostały zmienione. Chcesz aktualizować dane? Podczas aktualizacji wiersze zostaną oczyszczone.';
					|tr = 'Üretimdeki malzemelerin siparişleri düzenlendi. Verileri güncellemek istiyor musunuz? Satırlar güncellemek için temizlenecek.'"), 
				QuestionDialogMode.YesNo,
				,
				,
				NStr("vi = 'Lập đơn đặt hàng để chuyển sang sản xuất theo kế hoạch';
					|ru = 'Формирование заказов на передачу в производство по плану';
					|en = 'Generation of orders for transfer to production according to plan'; fa = 'Generation of orders for transfer to production according to plan';
					|it = 'Formazione degli ordini di trasferimento dei materiali in produzione secondo il piano';
					|pl = 'Utworzenie zamówień na przekazanie do produkcji według planu';
					|tr = 'Plana göre üretimde sevkiyat için siparişlerin oluşturulması'"));
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
	|	TableOrderGeneration.AssigneeBusinessUnit AS AssigneeBusinessUnit,
	|	TableOrderGeneration.Products AS Products,
	|	TableOrderGeneration.Characteristic AS Characteristic,
	|	TableOrderGeneration.DemandPeriodStart AS DemandPeriodStart,
	|	TableOrderGeneration.DemandPeriodEnd AS DemandPeriodEnd
	|INTO TableOrderGeneration
	|FROM
	|	&TableOrderGeneration AS TableOrderGeneration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Orders.Ref AS Document
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS Orders
	|		INNER JOIN TableOrderGeneration AS TableOrderGeneration
	|		ON Orders.Products = TableOrderGeneration.Products
	|			AND Orders.Characteristic = TableOrderGeneration.Characteristic
	|WHERE
	|	Orders.Ref.Posted
	|	AND Orders.Ref.Department = TableOrderGeneration.AssigneeBusinessUnit
	|	AND Orders.ShipmentStart BETWEEN TableOrderGeneration.DemandPeriodStart AND TableOrderGeneration.DemandPeriodEnd
	|	AND (NOT Orders.Canceled)
	|	AND Orders.Ref IN(&DocumentListForUpdate)";
	
	Query.SetParameter("DocumentListForUpdate", DocumentListForUpdate);
	Query.SetParameter("TableOrderGeneration", Object.GenerationOfOrders.Unload());
	
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
	Columns = "Warehouse, AssigneeBusinessUnit";
	If UseProductionManagement2_2 Then
		Columns = Columns + ", ShopFloorStockroom";
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
