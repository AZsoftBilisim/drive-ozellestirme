#Region Variables

&AtClient
Var ThisIsWaitingForReservationsFromOtherOrders;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	Text = NStr("vi = 'Đơn hàng / Mặt hàng,Đặc tính,Đvt,Kho bãi /Bộ phận';
				|ru = 'Заказ / Номенклатура, Характеристика, Ед. изм., Склад / Подразделение';
				|en = 'Order / Item, Variant, Unit, Warehouse / Business unit'; fa = 'سفارش / قلم، گونه، واحد، انبار / واحد تجاری';
				|it = 'Заказ / Номенклатура, Характеристика, Ед. изм., Склад / Подразделение';
				|pl = 'Order / Item, Variant, Unit, Warehouse / Business unit';
				|tr = 'Sipariş / Öğe, Özellik, Ölçü birimi, Ambar / Departman'");
	If UseItemVariants Then
		If Not UseSeveralWarehouses And Not UseBusinessUnits Then
			Text = NStr("vi = 'Đơn hàng / Mặt hàng,Đặc tính,Đvt';
						|ru = 'Заказ / Номенклатура, Характеристика, Ед. изм.';
						|en = 'Order / Item, Variant, Unit'; fa = 'Order / Item, Variant, Unit';
						|it = 'Заказ / Номенклатура, Характеристика, Ед. изм.';
						|pl = 'Order / Item, Variant, Unit';
						|tr = 'Sipariş / Öğe, Özellik, Ölçü birimi'");
		ElsIf Not UseSeveralWarehouses Then
			Text = NStr("vi = 'Đơn hàng / Mặt hàng, Đặc tính, Đvt, Bộ phận';
						|ru = 'Заказ / Номенклатура, Характеристика, Ед. изм., Подразделение';
						|en = 'Order / Item, Variant, Unit, Business unit'; fa = 'Order / Item, Variant, Unit, Business unit';
						|it = 'Заказ / Номенклатура, Характеристика, Ед. изм., Подразделение';
						|pl = 'Order / Item, Variant, Unit, Business unit';
						|tr = 'Sipariş / Öğe, Özellik, Ölçü birimi, Departman'");
		ElsIf Not UseBusinessUnits Then
			Text = NStr("vi = 'Đơn hàng / Mặt hàng, Đặc tính, Đvt, Kho bãi';
						|ru = 'Заказ / Номенклатура, Характеристика, Ед. изм., Склад';
						|en = 'Order / Item, Variant, Unit, Warehouse'; fa = 'Order / Item, Variant, Unit, Warehouse';
						|it = 'Заказ / Номенклатура, Характеристика, Ед. изм., Склад';
						|pl = 'Order / Item, Variant, Unit, Warehouse';
						|tr = 'Sipariş / Öğe, Özellik, Ölçü birimi, Ambar'");
		EndIf;
	Else
		If Not UseSeveralWarehouses And Not UseBusinessUnits Then
			Text = NStr("vi = 'Đơn hàng / Mặt hàng, Đvt';
						|ru = 'Заказ / Номенклатура, Ед. изм.';
						|en = 'Order / Item, Unit'; fa = 'Order / Item, Unit';
						|it = 'Заказ / Номенклатура, Ед. изм.';
						|pl = 'Order / Item, Unit';
						|tr = 'Sipariş /Ürün, Ölçü birimi'");
		ElsIf Not UseSeveralWarehouses Then
			Text = NStr("vi = 'Đơn hàng / Mặt hàng, Đvt, Bộ phận';
						|ru = 'Заказ / Номенклатура, Ед. изм., Подразделение';
						|en = 'Order / Item, Unit, Business unit'; fa = 'Order / Item, Unit, Business unit';
						|it = 'Заказ / Номенклатура, Ед. изм., Подразделение';
						|pl = 'Order / Item, Unit, Business unit';
						|tr = 'Sipariş / Ürün, Ölçü birimi, Departman'");
		ElsIf Not UseBusinessUnits Then
			Text = NStr("vi = 'Đơn hàng / Mặt hàng, Đvt, Kho bãi';
						|ru = 'Заказ / Номенклатура, Ед. изм., Склад';
						|en = 'Order / Item, Unit, Warehouse'; fa = 'Order / Item, Unit, Warehouse';
						|it = 'Заказ / Номенклатура, Ед. изм., Склад';
						|pl = 'Order / Item, Unit, Warehouse';
						|tr = 'Sipariş / Ürün, Ölçü birimi, Ambar'");
		EndIf;
	EndIf;
	
	Items.ListOfOrdersShipmentOrder.Title = Text;
	
	Text = NStr("vi = 'Kho bãi/ Bộ phận';
				|ru = 'Склад / Подразделение';
				|en = 'Warehouse / Business unit'; fa = 'انبار / واحد تجاری';
				|it = 'Склад / Подразделение';
				|pl = 'Magazyn / Dział';
				|tr = 'Ambar / Departman'");
	If Not UseSeveralWarehouses Then
		Text = NStr("vi = 'Bộ phận';
					|ru = 'Подразделение';
					|en = 'Business unit'; fa = 'Business unit';
					|it = 'Подразделение';
					|pl = 'Dział';
					|tr = 'Departman'");
	ElsIf Not UseBusinessUnits Then
		Text = NStr("vi = 'Kho bãi';
					|ru = 'Склад';
					|en = 'Warehouse'; fa = 'Warehouse';
					|it = 'Склад';
					|pl = 'Magazyn';
					|tr = 'Ambar'");
	EndIf;
	
	Items.SetWarehouse.Title = Text;
	Items.ListWarehouse.Title = Text;
	
	UseSeparateSoftware = GetFunctionalOption("UseOrderSupplyWithAssignment");
	Items.ListWithAssignment.Visible = UseSeparateSoftware;
	Items.ListOfOrdersWithAssignment.Visible = UseSeparateSoftware;
	Items.SetWithAssignment.Visible = UseSeparateSoftware;
	UseGoodsQualityControl = GetFunctionalOption("UseGoodsQualityControl");
	Items.ListQualityControl.Visible = UseGoodsQualityControl;
	Items.ListOfOrdersQualityControl.Visible = UseGoodsQualityControl;
	Items.SetQualityControl.Visible = UseGoodsQualityControl;
	Items.BasementHeaderInStockQualityConfirmed.Visible = UseGoodsQualityControl;
	Items.ResultIsInStockWithConfirmedQuality.Visible = UseGoodsQualityControl;
	Items.ListOfUnitOfTotalInStockWithConfirmedQuality.Visible = UseGoodsQualityControl;
	Items.TotalAvailableInStockWithConfirmedQuality.Visible = UseGoodsQualityControl;
	Items.ResultIsInReserveInWarehouseWithProvenQuality.Visible = UseGoodsQualityControl;
	Items.BasementHeaderInWarehouseOfEverythingIncludingQualityControl.Title = ?(UseGoodsQualityControl,
		NStr("vi = 'Trong kho, bao gồm cả kiểm soát chất lượng:';
			|ru = 'На складе, в том числе на контроле качества:';
			|en = 'In stock, including under quality control:'; fa = 'In stock, including under quality control:';
			|it = 'In stock, including under quality control:';
			|pl = 'In stock, including under quality control:';
			|tr = 'Ambarda, kalite kontrol dahil:'"),
		NStr("vi = 'Tại kho:';
			|ru = 'На складе:';
			|en = 'At warehouse:'; fa = 'در انبار:';
			|it = 'Nel magazzino:';
			|pl = 'W magazynie:';
			|tr = 'Ambarda:'"));
	
	CountRegisterWithRoutineTask = InventoryAllocation.CountRegisterWithRoutineTask();
	ReadOnly = Parameters.ReadOnly;
	CloseOnChoice = False;
	
	FillInOrdersToCheckTasksWhenCreatingThemOnServer();
	
	If Parameters.OrdersMotionRecorders <> Undefined Then
		OrdersMotionRecorders.LoadValues(Parameters.OrdersMotionRecorders);
	EndIf;
	OrdersMotionRecorders.Add(Parameters.OrderDocument);
	
	SelectedStates.Add(Enums.InventoryAllocationStates.InReserve,
		Enums.InventoryAllocationStates.InReserve, True);
	SelectedStates.Add(Enums.InventoryAllocationStates.SuppliedOnWarehouse,
		Enums.InventoryAllocationStates.SuppliedOnWarehouse, True);
	SelectedStates.Add(Enums.InventoryAllocationStates.SuppliedByDate,
		NStr("vi = 'Đang chờ';
			|ru = 'Ожидается';
			|en = 'Expected'; fa = 'مورد انتظار';
			|it = 'Previsto';
			|pl = 'Oczekiwane';
			|tr = 'Beklenen'"), True);
	SelectedStates.Add(Enums.InventoryAllocationStates.SuppliedByDate,
		NStr("vi = 'Dự kiến không đúng hạn';
			|ru = 'Ожидается не в срок';
			|en = 'Expected out-of-time'; fa = 'Expected out-of-time';
			|it = 'Previsto fuori termini';
			|pl = 'Oczekuje się nie w terminie';
			|tr = 'Zaman aşımı bekleniyor'"), True);
	SelectedStates.Add(Enums.InventoryAllocationStates.ToSupply_,
		Enums.InventoryAllocationStates.ToSupply_, True);
	SelectedStates.Add(Enums.InventoryAllocationStates.NotProvide,
		Enums.InventoryAllocationStates.NotProvide, True);
	
	ContextOfUse = Parameters.ContextOfUse;
	IsDocument = ContextOfUse = "ORDERLIST"
		Or ContextOfUse = "SECTION"
		Or ValueIsFilled(Parameters.OrderDocument);
		
	RestoreSettings();
	States1 = StatusBar(SelectedStates);
	
	VisibilityManagement(Undefined, ThisObject, ContextOfUse);
	ManagingListParameters(Undefined);
	AddressAnalyst = PutToTempStorage(Undefined, UUID);
	
	TheShipmentDateOfAllLinesIsASingleDate = ProvisionInDocumentsServer.TheShipmentDateOfAllLinesIsASingleDate(
		Parameters.AvailableRemainingDocumentParameters);
	DateWhenTheNewLinesWereShipped = BegOfDay(CurrentSessionDate());
	RemoveTheShipOnOneDateFlag_3 = Parameters.AvailableRemainingDocumentParameters <> Undefined
		And Parameters.AvailableRemainingDocumentParameters.EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList <> "UNDEFINED";
	
	If GetFunctionalOption("BaseVersion") Then
		Items.SetTheWayToEnsureProductName.Visible = False;
		Items.ListTheWayToEnsureProductName.Visible = False;
		Items.ListOfOrdersTheWayToEnsureProductName.Visible = False;
	EndIf;
	
	If AnExternalUserIsAuthorized Then
		
		Items.ReserveAtWarehouse.Visible = False;
		Items.ListOfOrdersAction.Visible = False;
		Items.ListOfOrdersWithAssignment.Visible = False;
		Items.ListOfOrdersReceiptOrderSecurityMethod.Visible = False;
		Items.ListOfOrdersReceiptOrder.Visible = False;
		Items.ListOfOrdersTheWayToEnsureProductName.Visible = False;
		Items.ListOfOrdersPurpose.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If OrdersForCheckingTasks.Count() > 0 Then
		
		IntervalSwitchPages = 1;
		AttachIdleHandler("Attachable_SwitchPages", IntervalSwitchPages, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.MarkValuesInList" Then
		
		SelectedStates.Clear();
		For Each Item In ValueSelected Do
			SelectedStates.Add(Item.Value, Item.Presentation, Item.Check, Item.Picture);
		EndDo;
		MarkingValuesInListOnServer();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure States1Click(Item, StandardProcessing)
	
	FormParameters = New Structure("List,Title", SelectedStates, NStr("vi = 'Trạng thái đảm bảo';
																		|ru = 'Состояния обеспечения';
																		|en = 'Supply forecast'; fa = 'پیش‌بینی تأمین';
																		|it = 'Stati di approvvigionamento';
																		|pl = 'Statusy zaopatrzenia';
																		|tr = 'Arz tahmini'"));
	StandardProcessing = False;
	OpenForm(
		"CommonForm.MarkValuesInList",
		FormParameters,
		ThisObject,
		UUID,
		,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	ManagingListParameters(Items.Warehouse.Name);
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	ManagingListParameters(Items.Manager.Name);
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure ClientOnChange(Item)
	
	ManagingListParameters(Items.Client.Name);
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure LabelMoreClick(Item)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	AdditionalParameters = New Structure("Products,Characteristic,Warehouse");
	If Not CurrentData.Property("Products")
				Or Not CurrentData.Property("Characteristic")
				Or Not CurrentData.Property("Warehouse") Then
		Return;
	EndIf;
	If CurrentData <> Undefined Then
		FillPropertyValues(AdditionalParameters, CurrentData);
	EndIf;
	ManagingListParameters(Items.LabelMore.Name, AdditionalParameters);
	VisibilityManagement(Items.LabelMore.Name, ThisObject, ContextOfUse);
	
EndProcedure

&AtClient
Procedure LabelForTheCurrentOrderClick(Item, StandardProcessing)
	
	ManagingListParameters(Items.LabelForTheCurrentOrder.Name);
	VisibilityManagement(Items.LabelForTheCurrentOrder.Name, ThisObject, ContextOfUse);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ListSelectionOnClient(Item, RowSelected, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("Attachable_ListOnActivateRow", 0.1, True);
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	OnGetDataAtServer(TagName, Settings, Rows);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrders

&AtClient
Procedure ListOfOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	ListSelectionOnClient(Item, RowSelected, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ListOfOrdersOnActivateRow(Item)
	
	If Items.ListOfOrders.CurrentRow = Undefined Then
		Return;
	EndIf;
	Items.ListOfOrders.Expand(Items.ListOfOrders.CurrentRow);
	
EndProcedure

&AtServerNoContext
Procedure ListOfOrdersOnGetDataAtServer(TagName, Settings, Rows)
	OnGetDataAtServer(TagName, Settings, Rows);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSet

&AtClient
Procedure SetSelection(Item, RowSelected, Field, StandardProcessing)
	
	ListSelectionOnClient(Item, RowSelected, Field, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NotProvide(Command)
	
	ClearMessages();
	ExecuteAction("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure Ship(Command)
	
	ClearMessages();
	ExecuteAction("ACTION_SHIP_SUPPLIED");
	
EndProcedure

&AtClient
Procedure ShipAvailable(Command)
	
	ClearMessages();
	ExecuteAction("ACTION_SHIP_AVAILABLE");
	
EndProcedure

&AtClient
Procedure ReserveAtWarehouse(Command)
	
	If ContextOfUse = "TABLE" Then
		
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Kết chuyển';
												|ru = 'Провести';
												|en = 'Post'; fa = 'ثبت';
												|it = 'Провести';
												|pl = 'Post';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Để thực hiện lệnh, cần kết chuyển chứng từ.';
						|ru = 'Для выполнения команды необходимо провести документ.';
						|en = 'Post the document to run the command.'; fa = 'Post the document to run the command.';
						|it = 'Для выполнения команды необходимо провести документ.';
						|pl = 'Post the document to run the command.';
						|tr = 'Komutu çalıştırmak için belgeyi kaydetmek gerekmektedir.'");
		
		ShowQueryBox(New CallbackDescription("QuestionIsToPostEndDocument", ThisObject), QueryText, Buttons);
		
		Return;
		
	EndIf;
	ReserveAtWarehouseClient();
	
EndProcedure

&AtClient
Procedure ReserveSecured(Command)
	
	ClearMessages();
	If Parameters.Orders <> Undefined Then
		CheckAndReserveGoodsInProductionPhase();
	Else
		ExecuteAction("ACTION_RESERVATION_RESERVED");
	EndIf;
	Return; // in UT and KA the handler is empty
	
EndProcedure

#EndRegion

#Region Private

#Region SavingSettings_

&AtServer
Procedure ShouldSaveSettings()
	
	Settings = New Structure();
	Settings.Insert("Manager", Manager);
	Settings.Insert("Client",   Client);
	Settings.Insert("Warehouse",    Warehouse);
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.OrderSupplyForecast.Form", "Main");
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		If SettingsValue.Property("StateSection") Then
			Settings.Insert("StateSection", SettingsValue.StateSection);
		EndIf;
		
		If SettingsValue.Property("StateListOfOrders") Then
			Settings.Insert("StateListOfOrders", SettingsValue.StateListOfOrders);
		EndIf;
		
	EndIf;
	
	If ContextOfUse = "SECTION" Then
		
		StateStructure_1 = New Structure();
		StateStructure_1.Insert("State0", SelectedStates[0].Check);
		StateStructure_1.Insert("State1", SelectedStates[1].Check);
		StateStructure_1.Insert("State2", SelectedStates[2].Check);
		StateStructure_1.Insert("State3", SelectedStates[3].Check);
		StateStructure_1.Insert("State4", SelectedStates[4].Check);
		StateStructure_1.Insert("State5", SelectedStates[5].Check);
		Settings.Insert("StateSection", StateStructure_1);
		
	EndIf;
	
	If ContextOfUse = "ORDERLIST" Then
		
		StateStructure_1 = New Structure();
		StateStructure_1.Insert("State0", SelectedStates[0].Check);
		StateStructure_1.Insert("State1", SelectedStates[1].Check);
		StateStructure_1.Insert("State2", SelectedStates[2].Check);
		StateStructure_1.Insert("State3", SelectedStates[3].Check);
		StateStructure_1.Insert("State4", SelectedStates[4].Check);
		StateStructure_1.Insert("State5", SelectedStates[5].Check);
		Settings.Insert("StateListOfOrders", StateStructure_1);
		
	EndIf;
	
	Common.CommonSettingsStorageSave("DataProcessor.OrderSupplyForecast.Form", "Main", Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.OrderSupplyForecast.Form", "Main");
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		Manager = SettingsValue.Manager;
		Warehouse    = SettingsValue.Warehouse;
		If SettingsValue.Property("Client") Then
			Client = SettingsValue.Client;
		EndIf;
		If SettingsValue.Property("StateSection") And ContextOfUse = "SECTION" Then
			
			SelectedStates[0].Check = SettingsValue.StateSection.State0;
			SelectedStates[1].Check = SettingsValue.StateSection.State1;
			SelectedStates[2].Check = SettingsValue.StateSection.State2;
			SelectedStates[3].Check = SettingsValue.StateSection.State3;
			SelectedStates[4].Check = SettingsValue.StateSection.State4;
			SelectedStates[5].Check = SettingsValue.StateSection.State5;
			
		EndIf;
		
		If SettingsValue.Property("StateListOfOrders") And ContextOfUse = "ORDERLIST" Then
			
			SelectedStates[0].Check = SettingsValue.StateListOfOrders.State0;
			SelectedStates[1].Check = SettingsValue.StateListOfOrders.State1;
			SelectedStates[2].Check = SettingsValue.StateListOfOrders.State2;
			SelectedStates[3].Check = SettingsValue.StateListOfOrders.State3;
			SelectedStates[4].Check = SettingsValue.StateListOfOrders.State4;
			SelectedStates[5].Check = SettingsValue.StateListOfOrders.State5;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	EstablishGeneralConditionalAppearanceOfLists();
	SetIndividualConditionalAppearanceOfSet();
	SetIndividualConditionalAppearanceOfOrdersList();
	
EndProcedure

&AtServer
Procedure SetConditionalListAppearance(ListOfConditionalAppearance, DataPaths, FieldsNames)
	
	ValuesOnApprovalOrNotProvided = New ValueList();
	ValuesOnApprovalOrNotProvided.Add(Enums.InventoryStates.PendingSupplyApproval);
	ValuesOnApprovalOrNotProvided.Add(Enums.InventoryStates.NotProvided);
	
	ValuesAvailable = New ValueList();
	ValuesAvailable.Add(Enums.InventoryStates.InStock);
	ValuesAvailable.Add(Enums.InventoryStates.AvailablePendingUnlocking);
	ValuesAvailable.Add(Enums.InventoryStates.AvailableNotSubjectToUnlocking);
	
	ValuesAreNotInControl = New ValueList();
	ValuesAreNotInControl.Add(Enums.InventoryStates.InStock);
	ValuesAreNotInControl.Add(Enums.InventoryStates.ExpectedForReceiptWithoutLock);
	ValuesAreNotInControl.Add(Enums.InventoryStates.PendingSupplyApproval);
	ValuesAreNotInControl.Add(Enums.InventoryStates.NotProvided);
	
	ListOfConditionalAppearance.Items.Clear();
	
	// The inscription "Not required" in the "Quality Control" field.
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Nhãn ""<không cần>"" trong trường ""Kiểm soát chất lượng""';
							|ru = 'Надпись ""<не требуется>"" в поле ""Контроль качества""';
							|en = 'The ""<not defined>"" label in the ""Quality control"" field'; fa = 'The ""<not defined>"" label in the ""Quality control"" field';
							|it = 'The ""<not defined>"" label in the ""Quality control"" field';
							|pl = 'The ""<not defined>"" label in the ""Quality control"" field';
							|tr = '""Kalite kontrol"" alanında ""<gerekmez>"" yazısı'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.QualityControl);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.ControlQualityOfReceivedGoods);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValuesAreNotInControl;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	
	#EndRegion
	
	// The inscription "Passed" in the "Quality Control" field.
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Nhãn ""<Đã đạt>"" trong trường ""Kiểm soát chất lượng""';
							|ru = 'Надпись ""Пройден"" в поле ""Контроль качества""';
							|en = 'The ""Passed"" label in the ""Quality control"" field'; fa = 'The ""Passed"" label in the ""Quality control"" field';
							|it = 'The ""Passed"" label in the ""Quality control"" field';
							|pl = 'The ""Passed"" label in the ""Quality control"" field';
							|tr = '""Kalite kontrol"" alanında ""Geçti"" yazısı'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.QualityControl);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.ControlQualityOfReceivedGoods);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.InventoryStates.InStock;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã đạt';
													|ru = 'Пройден';
													|en = 'Passed'; fa = 'تأییدشده';
													|it = 'Passed';
													|pl = 'Passed';
													|tr = 'Geçti'"));
	#EndRegion
	
	// The inscription "<undefined>" in the "Receipt date" field, if the main method of provision is not set, the calendar is not filled in, or the date of the next delivery according to the schedule is not set
	#Region AppearanceItem
	
	If Not AnExternalUserIsAuthorized Then
		
		Item = ListOfConditionalAppearance.Items.Add();
		Item.Presentation = NStr("vi = 'Nhãn ""<không xác định>"" trong trường ""Ngày tiếp nhận"", nếu chưa đặt phương pháp đảm bảo chính, chưa điền lịch hoặc chưa đặt ngày giao hàng tiếp theo theo lịch biểu';
								|ru = 'Надпись ""<не определена>"" в поле ""Дата поступления"", если не установлен основной способ обеспечения, не заполнен календарь или не установлена дата следующей поставки по графику';
								|en = 'The ""<not defined>"" label in the ""Date of receipt"" field, if the main procurement strategy is not set, the calendar is not filled in or the date of the next scheduled delivery is not set'; fa = 'The ""<not defined>"" label in the ""Date of receipt"" field, if the main procurement strategy is not set, the calendar is not filled in or the date of the next scheduled delivery is not set';
								|it = 'Scritta ""<non definita>"" nel campo ""Data di arrivo"", se il metodo principale di approvvigionamento non è impostato, il calendario non è compilato o la data della prossima consegna non è impostata nel grafico';
								|pl = 'Napis ""<nie określona>"" w polu ""Daty wpływu"", jeśli nie ustawiono podstawowego sposobu zaopatrzenia, nie wypełniono kalendarza lub nie ustawiono daty następnej dostawy zgodnie z harmonogramem';
								|tr = 'Ana tedarik stratejisi belirlenmemişse, takvim tamamlanmamışsa veya bir sonraki planlanan teslimat tarihi belirlenmemişse ""Teslim tarihi"" alanında ""<belirlenmedi>"" ifadesi ekleyin'");
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldsNames.DateOfReceipt);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = ValuesOnApprovalOrNotProvided;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(DataPaths.DemandCharacteristic);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.DemandCharacteristics.NotProvide;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(DataPaths.DateOfReceipt);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		TextIsUndefined = NStr("vi = '<không xác định>';
								|ru = '<не определена>';
								|en = '<not defined>'; fa = '<not defined>';
								|it = '<non definita>';
								|pl = '<nie określona>';
								|tr = '<belirlenmedi>'");
		Item.Appearance.SetParameterValue("Text", TextIsUndefined);
		
	EndIf;
	
	#EndRegion
	
	// The inscription "<not determined>" in the "Quality Control" field, if the main method of provision is not established, the calendar is not filled in, or the date of the next scheduled delivery is not set.
	#Region AppearanceItem
	
	If Not AnExternalUserIsAuthorized Then
		
		Item = ListOfConditionalAppearance.Items.Add();
		Item.Presentation = NStr("vi = 'Nhãn ""<không xác định>"" trong trường ""Kiểm soát chất lượng"", nếu chưa đặt phương pháp đảm bảo chính, chưa điền lịch hoặc chưa đặt ngày giao hàng tiếp theo theo lịch biểu';
								|ru = 'Надпись ""<не определено>"" в поле ""Контроль качества"", если не установлен основной способ обеспечения, не заполнен календарь или не установлена дата следующей поставки по графику';
								|en = 'The ""<not defined>"" label in the ""Quality control"" field if the main procurement strategy is not set, the calendar is not filled in or the date of the next scheduled delivery is not set'; fa = 'The ""<not defined>"" label in the ""Quality control"" field if the main procurement strategy is not set, the calendar is not filled in or the date of the next scheduled delivery is not set';
								|it = 'The ""<not defined>"" label in the ""Quality control"" field if the main procurement strategy is not set, the calendar is not filled in or the date of the next scheduled delivery is not set';
								|pl = 'The ""<not defined>"" label in the ""Quality control"" field if the main procurement strategy is not set, the calendar is not filled in or the date of the next scheduled delivery is not set';
								|tr = 'Ana karşılama yöntemi belirlenmemişse, takvim doldurulmamışsa veya takvime göre bir sonraki teslimat tarihi ayarlanmamışsa ""Kalite kontrol"" alanında ""<belirtilmemiş>"" yazısı'");
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldsNames.QualityControl);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = ValuesOnApprovalOrNotProvided;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(DataPaths.DemandCharacteristic);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.DemandCharacteristics.NotProvide;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(DataPaths.QualityControl);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(DataPaths.ControlQualityOfReceivedGoods);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		TextUndefined = NStr("vi = '<không xác định>';
							|ru = '<не определено>';
							|en = '<not defined>'; fa = '<not defined>';
							|it = '<non definito>';
							|pl = '<nie określono>';
							|tr = '<belirlenmedi>'");
		Item.Appearance.SetParameterValue("Text", TextUndefined);
		
	EndIf;
	
	#EndRegion
	
	// The date of receipt is highlighted if the calendar is not filled in or the date of the next scheduled delivery is not set
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đánh dấu ngày tiếp nhận, ngày kiểm soát chất lượng, nếu chưa chỉ ra phương thức đảm bảo chính thì chưa điền lịch hoặc chưa đặt ngày giao hàng tiếp theo theo lịch biểu';
							|ru = 'Подсветка даты поступления, даты контроля качества, если не установлен основной способ обеспечения, не заполнен календарь или не установлена дата следующей поставки по графику';
							|en = 'Highlighting the date of receipt and quality control date if the main procurement strategy is not set, the calendar is not filled in, or the date of the next scheduled delivery is not set'; fa = 'Highlighting the date of receipt and quality control date if the main procurement strategy is not set, the calendar is not filled in, or the date of the next scheduled delivery is not set';
							|it = 'Highlighting the date of receipt and quality control date if the main procurement strategy is not set, the calendar is not filled in, or the date of the next scheduled delivery is not set';
							|pl = 'Highlighting the date of receipt and quality control date if the main procurement strategy is not set, the calendar is not filled in, or the date of the next scheduled delivery is not set';
							|tr = 'Ana karşılama yöntemi belirlenmemişse, takvim doldurulmamışsa veya takvime göre bir sonraki teslimat tarihi ayarlanmamışsa giriş tarihi, kalite kontrol tarihi vurgulanır'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.DateOfReceipt);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValuesOnApprovalOrNotProvided;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.SupplyMethod);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.DateOfReceipt);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	#EndRegion
	
	// Highlighting the date of quality control if the calendar is not filled in or the date of the next scheduled delivery is not set
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đánh dấu ngày kiểm soát chất lượng, nếu chưa chỉ ra phương thức đảm bảo chính thì chưa điền lịch hoặc chưa đặt ngày giao hàng tiếp theo theo lịch biểu';
							|ru = 'Подсветка даты контроля качества, если не установлен основной способ обеспечения, не заполнен календарь или не установлена дата следующей поставки по графику';
							|en = 'Highlighting the quality control date if the main procurement strategy is not set, the calendar is not filled in, or the date of the next scheduled delivery is not set'; fa = 'Highlighting the quality control date if the main procurement strategy is not set, the calendar is not filled in, or the date of the next scheduled delivery is not set';
							|it = 'Highlighting the quality control date if the main procurement strategy is not set, the calendar is not filled in, or the date of the next scheduled delivery is not set';
							|pl = 'Highlighting the quality control date if the main procurement strategy is not set, the calendar is not filled in, or the date of the next scheduled delivery is not set';
							|tr = 'Ana karşılama yöntemi belirlenmemişse, takvim doldurulmamışsa veya takvime göre bir sonraki teslimat tarihi ayarlanmamışsa kalite kontrol tarihi vurgulanır'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.QualityControl);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValuesOnApprovalOrNotProvided;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.SupplyMethod);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.QualityControl);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.ControlQualityOfReceivedGoods);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	#EndRegion
	
	// The inscription "<as early as possible>" in the "Desired shipment date" field, if it is not set.
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Nhãn ""<càng sớm càng tốt>"" trong trường ""Ngày giao hàng dự kiến, nếu chưa đặt';
							|ru = 'Надпись ""<как можно раньше>"" в поле ""Желаемая дата отгрузки"", если она не установлена';
							|en = 'Label ""<as soon as possible>"" in the ""Desired date of shipment"" field, if it is not set'; fa = 'Label ""<as soon as possible>"" in the ""Desired date of shipment"" field, if it is not set';
							|it = 'Scritta ""<prima possibile>"" nel campo ""Data di spedizione desiderata"" se non è impostata';
							|pl = 'Napis ""<jak najwcześniej>"" w polu ""Planowana data wysyłki"", jeśli nie jest ona ustawiona';
							|tr = 'Ayarlanmamışsa, ""İstenen sevkiyat tarihi"" alanına ""<mümkün olan en kısa sürede>"" ifadesini ekleyin'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.RequestShipmentOn);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.RequestShipmentOn);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<sớm nhất có thể>';
													|ru = '<как можно раньше>';
													|en = '<as soon as possible>'; fa = '<as soon as possible>';
													|it = '<prima possibile>';
													|pl = '<jak najwcześniej>';
													|tr = '<mümkün olan en kısa sürede>.'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
	
	// The date of receipt is highlighted if the date of shipment is not met (the date of receipt is later than the desired date of shipment).
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đánh dấu ngày tiếp nhận, nếu ngày giao hàng không thực thi (ngày tiếp nhận muộn hơn ngày giao hàng mong muốn)';
							|ru = 'Подсветка даты поступления, если неисполнима дата отгрузки (дата поступления позже желаемой даты отгрузки)';
							|en = 'Highlighting of the date of receipt, if the date of shipment cannot be met (the date of receipt is later than the desired date of shipment)'; fa = 'Highlighting of the date of receipt, if the date of shipment cannot be met (the date of receipt is later than the desired date of shipment)';
							|it = 'Highlighting of the date of receipt, if the date of shipment cannot be met (the date of receipt is later than the desired date of shipment)';
							|pl = 'Highlighting of the date of receipt, if the date of shipment cannot be met (the date of receipt is later than the desired date of shipment)';
							|tr = 'Sevkiyat tarihi mevcut değilse varış tarihinin vurgulanması (varış tarihi istenen sevkiyat tarihinden daha geç)'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.DateOfReceipt);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.TheShipmentDateIsExecutable);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	#EndRegion
	
	// The text ""Received"" if the line is provided with the availability of goods in stock.
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Nội dung ""Đã nhập"", nếu dòng có đủ hàng tồn kho';
							|ru = 'Текст ""Поступило"" если строка обеспечена наличием товара на складе';
							|en = 'The ""Received"" text if the line is supplied by stock availability'; fa = 'The ""Received"" text if the line is supplied by stock availability';
							|it = 'The ""Received"" text if the line is supplied by stock availability';
							|pl = 'The ""Received"" text if the line is supplied by stock availability';
							|tr = 'Satır ambardaki ürün mevcudiyeti ile karşılanmışsa ""Teslim Alındı"" metni'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.DateOfReceipt);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValuesAvailable;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thu tiền';
													|ru = 'Поступило';
													|en = 'Received'; fa = 'دریافت‌شده';
													|it = 'Ricevuti';
													|pl = 'Received';
													|tr = 'Alındı'"));
	#EndRegion
	
	// Hiding the way to provide needs if it is a secured string.
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Ẩn phương thức đảm bảo nhu cầu, nếu đây là chuỗi đảm bảo';
							|ru = 'Скрытие способа обеспечения потребностей, если это обеспеченная строка';
							|en = 'Hiding the procurement strategy if it is a supplied line'; fa = 'Hiding the procurement strategy if it is a supplied line';
							|it = 'Nascondere metodo di approvvigionamento dei fabbisogni se è una riga approvvigionata';
							|pl = 'Ukrycie sposobu zaopatrzenia zapotrzebowań, jeśli to jest zaopatrzony wiersz';
							|tr = 'Bu bir ""Tedarik edilmiş"" satırı ise, tedarik stratejisini gizle'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.TheWayToEnsureProductName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.InventoryStates.PendingSupplyApproval;
	
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
	// The inscription "<security method not specified>".
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Nhãn ""<chưa đặt phương thức đảm bảo>""';
							|ru = 'Надпись ""<способ обеспечения не задан>""';
							|en = 'Label ""<procurement strategy is not set>""'; fa = 'Label ""<procurement strategy is not set>""';
							|it = 'Scritta ""<metodo di approvvigionamento non impostato>""';
							|pl = 'Napis ""<nie zadano sposobu zaopatrzenia>""';
							|tr = '""<tedarik stratejisi belirtilmemiş>"" etiketi'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.TheWayToEnsureProductName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.SupplyMethod);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.InventoryState);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.InventoryStates.NotProvided;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.DemandCharacteristic);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.DemandCharacteristics.NotProvide;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa đặt phương thức đảm bảo>';
													|ru = '<способ обеспечения не задан>';
													|en = '<procurement strategy is not set>'; fa = '<procurement strategy is not set>';
													|it = '<metodo di approvvigionamento non impostato>';
													|pl = '<nie zadano sposobu zaopatrzenia>';
													|tr = '<tedarik stratejisi belirtilmemiş>'"));
	#EndRegion
	
	// The inscription "Secured in the division" for work.
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Nhãn ""Đảm bảo trong bộ phận"" đối với công việc';
							|ru = 'Надпись ""Обеспечен в подразделении"" для работ';
							|en = 'Label ""Supplied in business unit"" for works'; fa = 'Label ""Supplied in business unit"" for works';
							|it = 'Scritta ""Disponibile nel reparto"" per lavori';
							|pl = 'Napis ""Zaopatrzony w dziale"" dla prac';
							|tr = 'İş için ""Departmanda emniyete alınmıştır"" etiketi'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldsNames.State);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.State);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.InventoryAllocationStates.SuppliedOnWarehouse;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPaths.ItemsType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã đảm bảo trong bộ phận';
													|ru = 'Обеспечен в подразделении';
													|en = 'Supplied in business unit'; fa = 'Supplied in business unit';
													|it = 'Disponibile nel reparto';
													|pl = 'Zaopatrzony w dziale';
													|tr = 'Departmanda emniyete alınmıştır'"));
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetIndividualConditionalAppearanceOfSet()
	
	// The State is highlighted if it is possible to ship from availability, taking into account the reserves of other orders.
	#Region AppearanceItem
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đánh dấu trạng thái, nếu có thể giao hàng từ sẵn có, có ghi nhận dự phòng các đơn hàng khác.';
							|ru = 'Подсветка состояния, если можно отгрузить из наличия, с учетом резервов других заказов.';
							|en = 'State highlighting if it is possible to ship goods from stock, taking into account the reserves under other orders.'; fa = 'State highlighting if it is possible to ship goods from stock, taking into account the reserves under other orders.';
							|it = 'Подсветка состояния, если можно отгрузить из наличия, с учетом резервов других заказов.';
							|pl = 'State highlighting if it is possible to ship goods from stock, taking into account the reserves under other orders.';
							|tr = 'Diğer siparişlerin rezervleri dikkate alınarak, stoktan gönderim mümkünse durum vurgusu.'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("SetState");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Set.CanBeShippedFromAvailability");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
	// The State is highlighted if it is possible to ship from the available Balance.
	#Region AppearanceItem
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đánh dấu trạng thái, nếu có thể giao hàng từ số dư được phép.';
							|ru = 'Подсветка состояния, если можно отгрузить из доступного остатка.';
							|en = 'State highlighting if it is possible to ship goods from the available balance.'; fa = 'State highlighting if it is possible to ship goods from the available balance.';
							|it = 'Подсветка состояния, если можно отгрузить из доступного остатка.';
							|pl = 'State highlighting if it is possible to ship goods from the available balance.';
							|tr = 'Mevcut bakiyeden sevk edilebiliyorsa durum vurgusu.'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("SetState");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Set.YouCanShipFromAvailableBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveValueTextColor);
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetIndividualConditionalAppearanceOfOrdersList()
	
	ListOfConditionalAppearance = ListOfOrders.SettingsComposer.Settings.ConditionalAppearance;
	
	// Hiding the shipment order field for detailed records.
	#Region AppearanceItem
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Ẩn trường ""Đơn hàng cần giao"" cho bản ghi chi tiết';
							|ru = 'Скрытие поля ""Заказ на отгрузку"" для детальных записей';
							|en = 'Hiding the ""Shipping order"" field for detailed records'; fa = 'Hiding the ""Shipping order"" field for detailed records';
							|it = 'Nascondere campo ""Ordine di spedizione"" per scritture dettagliate';
							|pl = 'Ukrycie pola ""Zamówienie do wysyłki"" dla szczegółowych wpisów';
							|tr = 'Ayrıntılı kayıtlar için ""Sevkiyat siparişi"" alanını gizleme'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("ShipmentOrder");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SystemFields.Level");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
EndProcedure

&AtServer
Procedure EstablishGeneralConditionalAppearanceOfLists()
	
	DataPaths = New Structure(
		"ControlQualityOfReceivedGoods,
		|QualityControl,
		|DateOfReceipt,
		|State,
		|InventoryState,
		|DemandCharacteristic,
		|RequestShipmentOn,
		|TheShipmentDateIsExecutable,
		|SupplyMethod,
		|ItemsType");
	DataPaths.ControlQualityOfReceivedGoods = "Set.ControlQualityOfReceivedGoods";
	DataPaths.QualityControl = "Set.QualityControl";
	DataPaths.DateOfReceipt = "Set.DateOfReceipt";
	DataPaths.State = "Set.State";
	DataPaths.InventoryState = "Set.InventoryState";
	DataPaths.DemandCharacteristic = "Set.DemandCharacteristic";
	DataPaths.RequestShipmentOn = "Set.RequestShipmentOn";
	DataPaths.TheShipmentDateIsExecutable = "Set.TheShipmentDateIsExecutable";
	DataPaths.SupplyMethod = "Set.SupplyMethod";
	DataPaths.ItemsType = "Set.ItemsType";
	
	FieldsNames = New Structure(
		"DateOfReceipt,
		|RequestShipmentOn,
		|ReceiptOrder,
		|TheWayToEnsureProductName,
		|State,
		|QualityControl");
	FieldsNames.QualityControl = Items.SetQualityControl.Name;
	FieldsNames.DateOfReceipt = Items.SetDateOfReceipt.Name;
	FieldsNames.RequestShipmentOn = Items.SetRequestShipmentOn.Name;
	FieldsNames.ReceiptOrder = Items.SetReceiptOrder.Name;
	FieldsNames.TheWayToEnsureProductName = Items.SetTheWayToEnsureProductName.Name;
	FieldsNames.State = Items.SetState.Name;
	
	SetConditionalListAppearance(ConditionalAppearance, DataPaths, FieldsNames);
	
	DataPaths.ControlQualityOfReceivedGoods = "ControlQualityOfReceivedGoods";
	DataPaths.QualityControl = "QualityControl";
	DataPaths.DateOfReceipt = "DateOfReceipt";
	DataPaths.State = "State";
	DataPaths.InventoryState = "InventoryState";
	DataPaths.DemandCharacteristic = "DemandCharacteristic";
	DataPaths.RequestShipmentOn = "RequestShipmentOn";
	DataPaths.TheShipmentDateIsExecutable = "TheShipmentDateIsExecutable";
	DataPaths.SupplyMethod = "SupplyMethod";
	DataPaths.ItemsType = "ItemsType";
	
	FieldsNames.QualityControl = "QualityControl";
	FieldsNames.DateOfReceipt = "DateOfReceipt";
	FieldsNames.RequestShipmentOn = "RequestShipmentOn";
	FieldsNames.ReceiptOrder = "ReceiptOrder";
	FieldsNames.TheWayToEnsureProductName = "TheWayToEnsureProductName";
	FieldsNames.State = "State";
	
	SetConditionalListAppearance(List.SettingsComposer.Settings.ConditionalAppearance, DataPaths, FieldsNames);
	SetConditionalListAppearance(ListOfOrders.SettingsComposer.Settings.ConditionalAppearance, DataPaths, FieldsNames);
	
EndProcedure

#EndRegion

#Region Visible

&AtClientAtServerNoContext
Procedure VisibilityManagement(TagName, Form, ContextOfUse)
	
	Items = Form.Items;
	ThisIsStageOfDynamicStructure = Form.Parameters.StageOfDynamicOrderStructure;
	If TagName = Undefined Then
		
		If ContextOfUse = "ORDERDOCUMENT" Or ContextOfUse = "TABLE" Then
			
			If ValueIsFilled(Form.Parameters.OrderDocument) Then
				Form.Title = StrReplace(NStr("vi = 'Trạng thái đảm bảo: %OrderDocument%';
											|ru = 'Состояние обеспечения: %OrderDocument%';
											|en = 'Supply forecast: %OrderDocument%'; fa = 'Supply forecast: %OrderDocument%';
											|it = 'Stato di approvvigionamento: %OrderDocument%';
											|pl = 'Status zaopatrzenia: %OrderDocument%';
											|tr = 'Tedarik durumu: %OrderDocument%'"), "%OrderDocument%", Form.Parameters.OrderDocument);
				If ContextOfUse = "TABLE" Then
					Form.Title = Form.Title + " (*)";
				EndIf;
			Else
				
				If ThisIsStageOfDynamicStructure And ValueIsFilled(Form.Parameters.Orders) Then
					Title = NStr("vi = 'Trạng thái đảm bảo đơn hàng (%1)';
								|ru = 'Состояние обеспечения заказов (%1)';
								|en = 'Order supply forecast (%1)'; fa = 'Order supply forecast (%1)';
								|it = 'Stato di approvvigionamento degli ordini (%1)';
								|pl = 'Status zaopatrzenia zamówień (%1)';
								|tr = 'Sipariş karşılama durumu (%1)'");
					Form.Title = StrTemplate(Title, Form.Parameters.Orders.Count());
				Else
					Form.Title = StrReplace(NStr("vi = 'Trạng thái đảm bảo: %OrderType_5% (mới)';
												|ru = 'Состояние обеспечения: %OrderType_5% (новый)';
												|en = 'Supply forecast: %OrderType_5% (new)'; fa = 'Supply forecast: %OrderType_5% (new)';
												|it = 'Stato di approvvigionamento: %OrderType_5% (nuovo)';
												|pl = 'Status zaopatrzenia: %OrderType_5% (nowy)';
												|tr = 'Tedarik durumu: %OrderType_5% (yeni)'"), "%OrderType_5%", TypeOf(Form.Parameters.OrderDocument));
				EndIf;
				
			EndIf;
			
		ElsIf ContextOfUse = "ORDERLIST" Then
			
			Title = NStr("vi = 'Trạng thái đảm bảo đơn hàng (%1)';
						|ru = 'Состояние обеспечения заказов (%1)';
						|en = 'Order supply forecast (%1)'; fa = 'Order supply forecast (%1)';
						|it = 'Stato di approvvigionamento degli ordini (%1)';
						|pl = 'Status zaopatrzenia zamówień (%1)';
						|tr = 'Sipariş karşılama durumu (%1)'");
			Form.Title = StrTemplate(Title, Form.Parameters.Orders.Count());
			
		ElsIf ContextOfUse = "SECTION" Then
			
			Form.Title = NStr("vi = 'Trạng thái đảm bảo';
								|ru = 'Состояние обеспечения заказов';
								|en = 'Order supply forecast'; fa = 'پیش‌بینی تأمین سفارش';
								|it = 'Stato di approvvigionamento degli ordini';
								|pl = 'Analiza stanu realizacji zamówień';
								|tr = 'Sipariş karşılama durumu'");
			
		EndIf;
		
		ArrayOfAllProps = New Array();
		
		ArrayOfAllProps.Add(Items.ListFooter.Name);
		ArrayOfAllProps.Add(Items.GroupSettingsList.Name);
		ArrayOfAllProps.Add(Items.List.Name);
		ArrayOfAllProps.Add(Items.StandardListCommands.Name);
		ArrayOfAllProps.Add(Items.States1.Name);
		ArrayOfAllProps.Add(Items.Ship.Name);
		ArrayOfAllProps.Add(Items.ShipAvailable.Name);
		ArrayOfAllProps.Add(Items.NotProvide.Name);
		ArrayOfAllProps.Add(Items.ReserveAtWarehouse.Name);
		ArrayOfAllProps.Add(Items.ReserveSecured.Name);
		ArrayOfAllProps.Add(Items.UserSettingsGroup_2.Name);
		ArrayOfAllProps.Add(Items.ListOfOrders.Name);
		ArrayOfAllProps.Add(Items.StandardCommandsInTheOrdersList.Name);
		ArrayOfAllProps.Add(Items.GroupFilters.Name);
		ArrayOfAllProps.Add(Items.Set.Name);
		ArrayOfAllProps.Add(Items.StandardDialCommands.Name);
		ArrayOfAllProps.Add(Items.SetShipmentOrder.Name);
		ArrayOfContextDetails = New Array();
		
		If ContextOfUse = "TABLE" And ValueIsFilled(Form.Parameters.Orders) Then
			ArrayOfContextDetails.Add(Items.SetShipmentOrder.Name);
		EndIf;
		
		If ContextOfUse = "ORDERLIST" Or ContextOfUse = "SECTION" Then
			
			If Form.Parameters.AcceptableSecurityOptions = Undefined
					Or Form.Parameters.AcceptableSecurityOptions.Get(
						PredefinedValue("Enum.SupplyOptions.FromWarehouse")) = True Then
				If ThereIsRightToAccessChangeOrdersWithCollateralManagement() Then
					ArrayOfContextDetails.Add(Items.ReserveAtWarehouse.Name);
				EndIf;
			EndIf;
			
		ElsIf ContextOfUse = "ORDERDOCUMENT" Or ContextOfUse = "TABLE" Then
			
			If ThisIsStageOfDynamicStructure Then
				ArrayOfContextDetails.Add(Items.ReserveSecured.Name);
			EndIf;
			
			If Form.Parameters.AcceptableSecurityOptions = Undefined
					Or Form.Parameters.AcceptableSecurityOptions.Get(
						PredefinedValue("Enum.SupplyOptions.Ship")) = True Then
				ArrayOfContextDetails.Add(Items.Ship.Name);
				ArrayOfContextDetails.Add(Items.ShipAvailable.Name);
			EndIf;
			
			If Form.Parameters.AcceptableSecurityOptions = Undefined
					Or Form.Parameters.AcceptableSecurityOptions.Get(
						PredefinedValue("Enum.SupplyOptions.FromWarehouse")) = True Then
				ArrayOfContextDetails.Add(Items.ReserveAtWarehouse.Name);
			EndIf;
			
			If Form.Parameters.AcceptableSecurityOptions = Undefined
					Or Form.Parameters.AcceptableSecurityOptions.Get(
						PredefinedValue("Enum.SupplyOptions.NotRequired")) = True Then
				ArrayOfContextDetails.Add(Items.NotProvide.Name);
			EndIf;
			
		EndIf;
		
		If ContextOfUse = "ORDERDOCUMENT" Then
			
			ArrayOfContextDetails.Add(Items.ListFooter.Name);
			ArrayOfContextDetails.Add(Items.GroupSettingsList.Name);
			ArrayOfContextDetails.Add(Items.List.Name);
			ArrayOfContextDetails.Add(Items.StandardListCommands.Name);
			ArrayOfContextDetails.Add(Items.States1.Name);
			
		ElsIf ContextOfUse = "SECTION" Then
			
			ArrayOfContextDetails.Add(Items.UserSettingsGroup_2.Name);
			ArrayOfContextDetails.Add(Items.ListOfOrders.Name);
			ArrayOfContextDetails.Add(Items.StandardCommandsInTheOrdersList.Name);
			ArrayOfContextDetails.Add(Items.GroupFilters.Name);
			
		ElsIf ContextOfUse = "ORDERLIST" Then
			
			ArrayOfContextDetails.Add(Items.UserSettingsGroup_2.Name);
			ArrayOfContextDetails.Add(Items.ListOfOrders.Name);
			ArrayOfContextDetails.Add(Items.StandardCommandsInTheOrdersList.Name);
			ArrayOfContextDetails.Add(Items.States1.Name);
			
		ElsIf ContextOfUse = "TABLE" Then
			
			ArrayOfContextDetails.Add(Items.States1.Name);
			ArrayOfContextDetails.Add(Items.Set.Name);
			ArrayOfContextDetails.Add(Items.StandardDialCommands.Name);
			
		EndIf;
		
		TMCommonUseClientServer.SetVisibilityOfElementsByArray(Items, ArrayOfAllProps, ArrayOfContextDetails);
		
	EndIf;
	
	If ThisIsStageOfDynamicStructure Then
		
		Items.SetShipmentOrder.Title = NStr("vi = 'Đơn hàng';
											|ru = 'Заказ';
											|en = 'Order'; fa = 'سفارش';
											|it = 'Order';
											|pl = 'Order';
											|tr = 'Sipariş'");
		TMCommonUseClientServer.SetFormItemProperty(Items, "Set", "ReadOnly", True);
		
	EndIf;
	
	If TagName = Undefined Or TagName = Items.LabelForTheCurrentOrder.Name Then
		
		Items.OrderOrAllOrdersPages.CurrentPage = Items.OrderOrAllOrdersPages.ChildItems.PageOrder;
		Items.ListShipmentOrder.Visible = False;
		Items.Ship.Enabled = Not Form.ReadOnly;
		Items.ShipAvailable.Enabled = Not Form.ReadOnly;
		Items.NotProvide.Enabled = Not Form.ReadOnly;
		Items.ReserveAtWarehouse.Enabled = Not Form.ReadOnly;
		
	EndIf;
	
	If TagName = Items.LabelMore.Name Then
		
		Items.OrderOrAllOrdersPages.CurrentPage = Items.OrderOrAllOrdersPages.ChildItems.OrdersPage;
		Items.ListShipmentOrder.Visible = True;
		Items.Ship.Enabled = False;
		Items.ShipAvailable.Enabled = False;
		Items.NotProvide.Enabled = False;
		Items.ReserveAtWarehouse.Enabled = False;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ThereIsRightToAccessChangeOrdersWithCollateralManagement()
	
	HasRight = False;
	For Each TypeValue In Metadata.DefinedTypes.OrdersWithSupplyManagement.Type.Types() Do
		
		NewTypeDescription = TMCommonUse.DescriptionOfTypesByType(TypeValue);
		MetadataObject = NewTypeDescription.AdjustValue().Metadata();
		If AccessRight("Update", MetadataObject) Then
			HasRight = True;
			Break;
		EndIf;
		
	EndDo;
	
	Return HasRight;
	
EndFunction

&AtClientAtServerNoContext
Function StatusBar(States1)
	
	All = True;
	Presentations = New Array();
	For Each Item In States1 Do
		All = All And Item.Check;
		If Item.Check Then
			Presentations.Add(Item.Presentation);
		EndIf;
	EndDo;
	Return ?(All, NStr("vi = 'Tất cả';
						|ru = 'Все';
						|en = 'All'; fa = 'همه';
						|it = 'Tutti';
						|pl = 'All';
						|tr = 'Tümü'"), StrConcat(Presentations, ", "));
	
EndFunction

#EndRegion

#Region SwitchingPages

&AtServer
Procedure FillInOrdersToCheckTasksWhenCreatingThemOnServer()
	
	OrdersForCheckingTasks.Clear();
	If CountRegisterWithRoutineTask Then
		If Parameters.ContextOfUse = "ORDERDOCUMENT" Then
			OrdersForCheckingTasks.Add(Parameters.OrderDocument);
		ElsIf Parameters.ContextOfUse = "TABLE" Then
			OrdersForCheckingTasks.Add(Parameters.OrderDocument);
		ElsIf Parameters.ContextOfUse = "ORDERLIST" Then
			OrdersForCheckingTasks.LoadValues(Parameters.Orders);
		EndIf;
	EndIf;
	If OrdersForCheckingTasks.Count() > 0 And Not ThereAreTasksForOrders(OrdersForCheckingTasks) Then
		OrdersForCheckingTasks.Clear();
	EndIf;
	HasJobs = OrdersForCheckingTasks.Count() > 0;
	Items.Pages.CurrentPage = ?(HasJobs, Items.PageWait, Items.WorkplacePage);
	
EndProcedure

&AtClient
Procedure FillInOrdersToCheckTasksAfterReservingFromOtherOrders(Processed_Orders)
	
	OrdersForCheckingTasks.Clear();
	If CountRegisterWithRoutineTask Then
		OrdersForCheckingTasks.LoadValues(Processed_Orders);
	EndIf;
	If OrdersForCheckingTasks.Count() > 0 And Not ThereAreTasksForOrders(OrdersForCheckingTasks) Then
		OrdersForCheckingTasks.Clear();
	EndIf;
	HasJobs = OrdersForCheckingTasks.Count() > 0;
	Items.Pages.CurrentPage = ?(HasJobs, Items.PageWait, Items.WorkplacePage);
	
	ThisIsWaitingForReservationsFromOtherOrders = True;
	If OrdersForCheckingTasks.Count() > 0 Then
		
		IntervalSwitchPages = 1;
		AttachIdleHandler("Attachable_SwitchPages", IntervalSwitchPages, True);
		
	Else
		
		UpdateList();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_SwitchPages()
	
	SetPageVisibility();
	If OrdersForCheckingTasks.Count() > 0 Then
		IntervalSwitchPages = IntervalSwitchPages + 1;
		AttachIdleHandler("Attachable_SwitchPages", IntervalSwitchPages, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetPageVisibility()
	
	If Not ThereAreTasksForOrders(OrdersForCheckingTasks) Then
		OrdersForCheckingTasks.Clear();
	EndIf;
	HasJobs = OrdersForCheckingTasks.Count() > 0;
	Items.Pages.CurrentPage = ?(HasJobs, Items.PageWait, Items.WorkplacePage);
	If Not HasJobs Then
		UpdateList();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ThereAreTasksForOrders(OrdersForCheckingTasks)
	
	Return ProvisionInDocumentsServer.ThereAreTasksForOrders(OrdersForCheckingTasks);
	
EndFunction

#EndRegion

#Region SettingUpLists

&AtServer
Procedure ManagingListParameters(TagName, AdditionalParameters = Undefined)
	
	SubstituteCurOrder = AdditionalParameters <> Undefined;
	
	QueryOptions = QueryOptions();
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure("Products,Characteristic,Warehouse");
	EndIf;
	
	AvailableOrderTypes = AvailableOrderTypes();

	// Setting mandatory fixed list parameters.
	If TagName = Undefined Then
		
		If ContextOfUse = "SECTION" Then
			
			ListProperties = Common.DynamicListPropertiesStructure();
			FillPropertyValues(ListProperties, ListOfOrders);
			ListProperties.QueryText = QueryText(Items.ListOfOrders.Name, SubstituteCurOrder);
			Common.SetDynamicListProperties(Items.ListOfOrders, ListProperties);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "ExcludedOrders", New Array());
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "LabelOrder", QueryOptions.LabelOrder);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "BeginningOfThisDay", QueryOptions.BeginningOfThisDay);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "AvailableOrderTypes", AvailableOrderTypes);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "CurrentDayStart", BegOfDay(CurrentSessionDate()));
		EndIf;
		
		If ContextOfUse = "ORDERLIST" Then
			ListProperties = Common.DynamicListPropertiesStructure();
			FillPropertyValues(ListProperties, ListOfOrders);
			ListProperties.QueryText = QueryText(Items.ListOfOrders.Name, SubstituteCurOrder);
			Common.SetDynamicListProperties(Items.ListOfOrders, ListProperties);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "ExcludedOrders", New Array());
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "LabelOrder", QueryOptions.LabelOrder);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "BeginningOfThisDay", QueryOptions.BeginningOfThisDay);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "ShippingOrders", QueryOptions.ShippingOrders);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "AvailableOrderTypes", AvailableOrderTypes);
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "CurrentDayStart", BegOfDay(CurrentSessionDate()));
		EndIf;
		
	EndIf;
	
	If TagName = Undefined
			Or TagName = Items.LabelForTheCurrentOrder.Name
			Or TagName = Items.LabelMore.Name Then
		
		If ContextOfUse = "ORDERDOCUMENT" Then
			
			ListProperties = Common.DynamicListPropertiesStructure();
			FillPropertyValues(ListProperties, List);
			ListProperties.QueryText = QueryText(Items.List.Name, SubstituteCurOrder);
			Common.SetDynamicListProperties(Items.List, ListProperties);
			CommonClientServer.SetDynamicListParameter(List, "ExcludedOrders", New Array());
			CommonClientServer.SetDynamicListParameter(List, "CurOrderLabel", QueryOptions.CurOrderLabel);
			CommonClientServer.SetDynamicListParameter(List, "LabelOrder",        QueryOptions.LabelOrder);
			CommonClientServer.SetDynamicListParameter(List, "BeginningOfThisDay",      QueryOptions.BeginningOfThisDay);
			CommonClientServer.SetDynamicListParameter(List, "CurrentOrder",        QueryOptions.CurrentOrder);
			CommonClientServer.SetDynamicListParameter(List, "CurOrderLabel", QueryOptions.CurOrderLabel);
			CommonClientServer.SetDynamicListParameter(List, "AvailableOrderTypes", AvailableOrderTypes);
			CommonClientServer.SetDynamicListParameter(List, "CurrentDayStart", BegOfDay(CurrentSessionDate()));
			
			List.SettingsComposer.FixedSettings.Order.Items.Clear();
			OrderFields_ = "RequestShipmentOn,ShipmentOrder,Products,Characteristic,Warehouse,DateOfReceipt,ReceiptOrder";
			OrderFields_ = StrSplit(OrderFields_, ",");
			For Each OrderField_ In OrderFields_ Do
				OrderItem = List.SettingsComposer.FixedSettings.Order.Items.Add(Type("DataCompositionOrderItem"));
				OrderItem.Field = New DataCompositionField(OrderField_);
				OrderItem.Use = True;
				OrderItem.OrderType = DataCompositionSortDirection.Asc;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	// Selections in the form header.
	If TagName = Undefined Or TagName = Items.Warehouse.Name Then
		
		If ContextOfUse = "SECTION" Then
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "Warehouse", Warehouse, ValueIsFilled(Warehouse));
		EndIf;
		
	EndIf;
	
	If TagName = Undefined Or TagName = Items.Manager.Name Then
		
		If ContextOfUse = "SECTION" Then
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "Manager", Manager, ValueIsFilled(Manager));
		EndIf;
		
	EndIf;
	If TagName = Undefined Or TagName = Items.Client.Name Then
		
		If ContextOfUse = "SECTION" Then
			CommonClientServer.SetDynamicListParameter(ListOfOrders, "Client", Client, ValueIsFilled(Client));
		EndIf;
		
	EndIf;
	
	If TagName = Undefined Or TagName = Items.States1.Name Then
		
		If ContextOfUse = "ORDERDOCUMENT" Then
				
			CommonClientServer.SetDynamicListParameter(
				List,
				"SelectionOfStates",
				QueryOptions.SelectionOfStates);
				
			CommonClientServer.SetDynamicListParameter(
				List,
				"Expected_",
				QueryOptions.Expected_);
				
			CommonClientServer.SetDynamicListParameter(
				List,
				"NotExpectedOnTime",
				QueryOptions.NotExpectedOnTime);
			
		EndIf;
		
		If ContextOfUse = "SECTION" Or ContextOfUse = "ORDERLIST" Then
			
			CommonClientServer.SetDynamicListParameter(
				ListOfOrders,
				"SelectionOfStates",
				QueryOptions.SelectionOfStates);
				
			CommonClientServer.SetDynamicListParameter(
				ListOfOrders,
				"Expected_",
				QueryOptions.Expected_);
				
			CommonClientServer.SetDynamicListParameter(
				ListOfOrders,
				"NotExpectedOnTime",
				QueryOptions.NotExpectedOnTime);
				
		EndIf;
		
	EndIf;
	
	// Clicking on the hyperlink in the basement of the form.
	If TagName = Undefined
			Or TagName = Items.LabelForTheCurrentOrder.Name
			Or TagName = Items.LabelMore.Name Then
		
		If ContextOfUse = "ORDERDOCUMENT" Then
			Use = TagName = Undefined Or TagName = Items.LabelForTheCurrentOrder.Name;
			CommonClientServer.SetDynamicListParameter(
				List,
				"ShipmentOrder",
				QueryOptions.ShipmentOrder,
				Use);
			
			Use = TagName = Items.LabelMore.Name;
			CommonClientServer.SetDynamicListParameter(
				List,
				"Products",
				AdditionalParameters.Products,
				Use);
			CommonClientServer.SetDynamicListParameter(
				List,
				"Characteristic",
				AdditionalParameters.Characteristic,
				Use);
			CommonClientServer.SetDynamicListParameter(
				List,
				"Warehouse",
				AdditionalParameters.Warehouse,
				Use);
		EndIf;
		
	EndIf;
	
	If ContextOfUse = "TABLE" Then
		SetUpdate(QueryOptions, Parameters.AddressOfTheMovementTable);
	ElsIf TagName = Undefined And ContextOfUse = "ORDERDOCUMENT" Then
		SetPrivilegedMode(True);
		Query = New Query();
		Query.SetParameter("CurrentOrder", QueryOptions.CurrentOrder);
		Query.Text =
			"SELECT
			|COUNT(*) AS TotalRecords
			|FROM
			|	InformationRegister.InventoryAllocation AS Table
			|WHERE
			|	Table.ShipmentOrder = &CurrentOrder
			|	AND Table.DemandCharacteristic IN(
			|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
			|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
			|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
			|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked),
			|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
			|		VALUE(Enum.DemandCharacteristics.ToSupply),
			|		VALUE(Enum.DemandCharacteristics.NotProvide))
			|;
			|///////////////////////////////////////////////////////////////////
			|SELECT TOP 1
			|	TRUE AS ThereIsShip
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS Table
			|WHERE
			|	Table.Recorder = &CurrentOrder
			|		AND Table.OrderToShip = &CurrentOrder
			|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND Table.InStock > 0";
		TotalRowsInListWithoutFilters = 0;
		QueryResult = Query.ExecuteBatch();
		
		Selection = QueryResult[0].Select();
		If Selection.Next() Then
			TotalRowsInListWithoutFilters = Selection.TotalRecords;
		EndIf;
		
		Selection = QueryResult[1].Select();
		If Selection.Next() Then
			// it is enough to understand that all lines cannot be selected in the list.
			TotalRowsInListWithoutFilters = TotalRowsInListWithoutFilters + 1;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function AvailableOrderTypes()
	
	AvailableTypes = New Array();
	AllTypesOfOrders = Metadata.DefinedTypes.ExpectedShipment.Type.Types();
	For Each Item In AllTypesOfOrders Do
		If AccessRight("Read", Metadata.FindByType(Item)) Then
			AvailableTypes.Add(Item);
		EndIf;
	EndDo;
		
	Return AvailableTypes;
	
EndFunction

&AtServer
Function QueryText(TagName, SubstituteCurOrder = False)
	
	Texts = New Array();
	QueryText = TextOfTemporaryTableSelectionOfStates();
	Texts.Add(QueryText);
	QueryText =
		"SELECT ALLOWED
		|	SelectionOfStates.State AS State,
		|	OrderState.Products AS Products,
		|	OrderState.Characteristic AS Characteristic,
		|	OrderState.Warehouse AS Warehouse,
		|	OrderState.Purpose AS Purpose,
		|	OrderState.DemandCharacteristic AS DemandCharacteristic,
		|	OrderState.InventoryState AS InventoryState,
		|	OrderState.RequestShipmentOn AS RequestShipmentOn,
		|	OrderState.ReceiptOrder AS ReceiptOrder,
		|	OrderState.Count AS Count,
		|	&ShipmentOrderOverridable AS ShipmentOrder,
		|	DocumentsRegistry.Partner AS Client,
		|	DocumentsRegistry.EmployeeResponsible AS Manager,
		|	
		// Derived fields.
		|	OrderState.Products.ControlQualityOfReceivedGoods
		|		AND CAST(OrderState.Warehouse AS Catalog.Warehouses).ControlQualityOfReceivedGoods AS ControlQualityOfReceivedGoods,
		|	OrderState.Products.ItemsType AS ItemsType,
		|	OrderState.Products.UnitOfMeasure AS UnitOfMeasure,
		|	OrderState.Purpose.OrderDocument AS DestinationOrder,
		|	OrderState.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
		|	
		// The Action field.
		|	CASE
		|		WHEN OrderState.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|				VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked))
		|			THEN VALUE(Enum.SupplyOptions.FromWarehouse)
		|		WHEN OrderState.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|				VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|				VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))
		|			THEN VALUE(Enum.SupplyOptions.ReserveAsReceived)
		|		WHEN OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ToSupply)
		|			THEN VALUE(Enum.SupplyOptions.ToSupply)
		|		WHEN OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|			THEN VALUE(Enum.SupplyOptions.NotRequired)
		|	END AS Action,
		|	
		// The data access field.
		|	CASE
		|		WHEN OrderState.InventoryState IN(
		|				VALUE(Enum.InventoryStates.NotProvided),
		|				VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|				AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|			THEN
		|				CASE
		|					WHEN CalculationOfSecurityMethodOverridable.Ref = VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|						THEN DATETIME(1,1,1)
		|					ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|				END
		|		ELSE OrderState.DateOfReceipt
		|	END AS DateOfReceipt,
		|	
		// Quality control field.
		|	CASE
		|		WHEN OrderState.InventoryState IN(
		|				VALUE(Enum.InventoryStates.NotProvided),
		|				VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|				AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|			THEN
		|				CASE
		|					WHEN CalculationOfSecurityMethodOverridable.Ref = VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|						THEN DATETIME(1,1,1)
		|					ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|				END
		|		ELSE OrderState.AvailabilityDate
		|	END AS QualityControl,
		|	
		// Fields of the Security Method.
		|	ISNULL(CAST(&LabelOrder AS STRING(5))
		|			+ "" / ""
		|			+ CAST(CalculationOfSecurityMethodOverridable.Ref AS Catalog.ProcurementStrategies).Description,
		|		 """") AS TheWayToEnsureProductName,
		|	ISNULL(CAST(CalculationOfSecurityMethodOverridable.Ref AS Catalog.ProcurementStrategies),
		|		VALUE(Catalog.ProcurementStrategies.EmptyRef)) AS SupplyMethod,
		|	
		// The upload datafield is executable.
		|	OrderState.RequestShipmentOn = DATETIME(1,1,1)
		|		OR CASE
		|				WHEN OrderState.RequestShipmentOn < &CurrentDayStart
		|					THEN &CurrentDayStart
		|				ELSE OrderState.RequestShipmentOn
		|			END
		|				>= CASE
		|						WHEN OrderState.InventoryState IN(
		|								VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|								VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking),
		|								VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|								VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|								VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|							THEN
		|								CASE
		|									WHEN VALUETYPE(OrderState.ShipmentOrder) = TYPE(Catalog.ControlledLots)
		|										THEN
		|											CASE
		|												WHEN OrderState.DateOfReceipt < &CurrentDayStart
		|													THEN &CurrentDayStart
		|												ELSE OrderState.DateOfReceipt
		|											END
		|									ELSE
		|										CASE
		|											WHEN OrderState.AvailabilityDate < &CurrentDayStart
		|												THEN &CurrentDayStart
		|											ELSE OrderState.AvailabilityDate
		|										END
		|								END
		|						WHEN OrderState.InventoryState IN(
		|								VALUE(Enum.InventoryStates.NotProvided),
		|								VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|								AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|							THEN
		|								CASE
		|									WHEN CalculationOfSecurityMethodOverridable.Ref = VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|										THEN DATETIME(1,1,1)
		|									ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|								END
		|						ELSE
		|							DATETIME(1,1,1)
		|					END AS TheShipmentDateIsExecutable,
		|	
		|	FALSE AS YouCanShipFromAvailableBalance,
		|	FALSE AS CanBeShippedFromAvailability,
		|
		// Further fields are not used in dynamic lists, but are used only in the value table. 
		|	OrderState.DateOfReceipt AS DateOfReceiptForOrdering
		|FROM
		|	InformationRegister.InventoryAllocation AS OrderState
		|		
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON DocumentsRegistry.Ref = OrderState.ShipmentOrder
		|		 AND NOT DocumentsRegistry.AdditionalRecord
		|		
		|		LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|		
		|		INNER JOIN SelectionOfStates AS SelectionOfStates
		|		ON SelectionOfStates.InventoryState = OrderState.InventoryState
		|		 AND SelectionOfStates.DemandCharacteristic = OrderState.DemandCharacteristic
		|		
		|	AND VALUETYPE(OrderState.ShipmentOrder) IN (&AvailableOrderTypes)
		|	AND NOT OrderState.ShipmentOrder IN(&ExcludedOrders)
		|	AND (NOT OrderState.InventoryState IN(
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|		OR &Expected_
		|		OR &NotExpectedOnTime
		|			AND OrderState.RequestShipmentOn <> DATETIME(1, 1, 1)
		|			AND OrderState.DateOfReceipt <> DATETIME(1, 1, 1)
		|			AND CASE
		|					WHEN OrderState.RequestShipmentOn < &CurrentDayStart
		|						THEN &CurrentDayStart
		|					ELSE OrderState.RequestShipmentOn
		|				END < OrderState.DateOfReceipt)
		|{SELECT
		|	State AS State,
		|	Products.* AS Products,
		|	Characteristic.* AS Characteristic,
		|	Warehouse.* AS Warehouse,
		|	Purpose.* AS Purpose,
		|	DemandCharacteristic AS DemandCharacteristic,
		|	InventoryState AS InventoryState,
		|	RequestShipmentOn AS RequestShipmentOn,
		|	ReceiptOrder.* AS ReceiptOrder,
		|	Count AS Count,
		|	ShipmentOrder.* AS ShipmentOrder,
		|	Client.* AS Client,
		|	Manager.* AS Manager,
		|	ControlQualityOfReceivedGoods AS ControlQualityOfReceivedGoods,
		|	ItemsType AS ItemsType,
		|	UnitOfMeasure.* AS UnitOfMeasure,
		|	WithAssignment AS WithAssignment,
		|	Action AS Action,
		|	DateOfReceipt AS DateOfReceipt,
		|	QualityControl AS QualityControl,
		|	TheWayToEnsureProductName AS TheWayToEnsureProductName,
		|	SupplyMethod.* AS SupplyMethod,
		|	TheShipmentDateIsExecutable AS TheShipmentDateIsExecutable,
		|	YouCanShipFromAvailableBalance AS YouCanShipFromAvailableBalance,
		|	CanBeShippedFromAvailability AS CanBeShippedFromAvailability
		|}
		|{WHERE
		|	SelectionOfStates.State AS State,
		|	OrderState.Products.* AS Products,
		|	OrderState.Characteristic.* AS Characteristic,
		|	OrderState.Warehouse.* AS Warehouse,
		|	OrderState.Purpose.* AS Purpose,
		|	OrderState.DemandCharacteristic AS DemandCharacteristic,
		|	OrderState.InventoryState AS InventoryState,
		|	OrderState.RequestShipmentOn AS RequestShipmentOn,
		|	OrderState.ReceiptOrder.* AS ReceiptOrder,
		|	OrderState.Count AS Count,
		|	OrderState.ShipmentOrder.* AS ShipmentOrder,
		|	DocumentsRegistry.Partner.* AS Client,
		|	DocumentsRegistry.EmployeeResponsible.* AS Manager,
		|	OrderState.Products.ItemsType AS ItemsType,
		|	OrderState.Products.UnitOfMeasure.* AS UnitOfMeasure,
		|	OrderState.Purpose.OrderDocument AS DestinationOrder,
		|	OrderState.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
		|	CASE
		|		WHEN OrderState.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|				VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked))
		|			THEN VALUE(Enum.SupplyOptions.FromWarehouse)
		|		WHEN OrderState.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|				VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|				VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))
		|			THEN VALUE(Enum.SupplyOptions.ReserveAsReceived)
		|		WHEN OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ToSupply)
		|			THEN VALUE(Enum.SupplyOptions.ToSupply)
		|		WHEN OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|			THEN VALUE(Enum.SupplyOptions.NotRequired)
		|	END AS Action,
		|	CASE
		|		WHEN OrderState.InventoryState IN(
		|				VALUE(Enum.InventoryStates.NotProvided),
		|				VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|				AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|			THEN
		|				CASE
		|					WHEN CalculationOfSecurityMethodOverridable.Ref = VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|						THEN DATETIME(1,1,1)
		|					ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|				END
		|		ELSE OrderState.DateOfReceipt
		|	END AS DateOfReceipt,
		|	CASE
		|		WHEN OrderState.InventoryState IN(
		|				VALUE(Enum.InventoryStates.NotProvided),
		|				VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|				AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|			THEN
		|				CASE
		|					WHEN CalculationOfSecurityMethodOverridable.Ref = VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|						THEN DATETIME(1,1,1)
		|					ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|				END
		|		ELSE OrderState.AvailabilityDate
		|	END AS QualityControl}";
	
	SubstitutingShipmentOrder = "OrderState.ShipmentOrder";
	If SubstituteCurOrder Then
		
		SubstitutingShipmentOrder =
			"CASE WHEN OrderState.ShipmentOrder = &CurrentOrder THEN
			|					CAST(&CurOrderLabel AS STRING(20))
			|			ELSE
			|				OrderState.ShipmentOrder
			|		END";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&ShipmentOrderOverridable", SubstitutingShipmentOrder);
	
	If TagName = Items.List.Name Then
		
		QueryText = QueryText + "
			|{WHERE
			|	OrderState.ShipmentOrder = &ShipmentOrder}
			|{WHERE
			|	OrderState.Products     = &Products
			|	AND OrderState.Characteristic = &Characteristic
			|	AND OrderState.Warehouse          = &Warehouse}";
		
	ElsIf TagName = Items.ListOfOrders.Name Then
		
		QueryText = QueryText + "
			|{WHERE
			|	&Warehouse = OrderState.Warehouse}
			|{WHERE
			|	&Manager = ISNULL(DocumentsRegistry.EmployeeResponsible, VALUE(Catalog.Users.EmptyRef))}
			|{WHERE
			|	&Client = ISNULL(DocumentsRegistry.Partner, VALUE(Catalog.Partners.EmptyRef))}
			|{WHERE
			|	OrderState.ShipmentOrder IN(&ShippingOrders)}";
			
	ElsIf TagName = Items.Set.Name Then
		
		QueryText = StrReplace(QueryText, "InformationRegister.InventoryAllocation", "SimulationOfReflection");
		QueryText = QueryText + "
			|WHERE
			|	OrderState.ShipmentOrder IN(
			|		SELECT DISTINCT
			|			RegisterRecords.OrderDocument AS ShipmentOrder
			|		FROM
			|			SetOfRecordsStocksAndNeeds AS RegisterRecords)
			|ORDER BY
			|	State,
			|	Products,
			|	Characteristic,
			|	Warehouse,
			|	Purpose,
			|	ShipmentOrder,
			|	RequestShipmentOn,
			|	ReceiptOrder,
			|	DateOfReceiptForOrdering";
		
	EndIf;
	
	If AnExternalUserIsAuthorized Then
		
		QueryText = StrReplace(QueryText, "CalculationOfSecurityMethodOverridable.Ref", "NULL");
		QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE", "");
		
		QueryText = StrReplace(QueryText, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", "DATETIME(1, 1, 1)");
		QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", "");
		
		Texts.Add(QueryText);
		
	Else
		
		TemporaryTableText = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
		Texts.Add(TemporaryTableText);
		
		Substitutions = ProvisionInDocumentsServer.SubstitutionsOfMainMethodOfProviding(
			"OrderState.Products",
			"OrderState.Characteristic",
			"OrderState.Warehouse",
			"(OrderState.InventoryState IN(
			|	VALUE(Enum.InventoryStates.NotProvided),
			|	VALUE(Enum.InventoryStates.PendingSupplyApproval))
			|	AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide))");
		
		QueryText = StrReplace(QueryText, "CalculationOfSecurityMethodOverridable.Ref", Substitutions.Field);
		QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE",
			Substitutions.Joins);
		
		Substitutions = ProvisionInDocumentsServer.SubstitutionsOfPlannedDeliveryDate(
			Substitutions.Field,
			"&BeginningOfThisDay",
			"OrderState.Products",
			"OrderState.Warehouse");
		
		QueryText = StrReplace(QueryText, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
		QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE",
			Substitutions.Joins);
		
		Texts.Add(QueryText);
	
	EndIf;
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

&AtServer
Function TextOfTemporaryTableSelectionOfStates()
	
	QueryText =
		"SELECT
		|	Set.State AS State,
		|	Set.InventoryState AS InventoryState,
		|	Set.DemandCharacteristic AS DemandCharacteristic
		|INTO SelectionOfStates
		|FROM(
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.InReserve) AS State,
		|		VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedOnWarehouse) AS State,
		|		VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedOnWarehouse) AS State,
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedOnWarehouse) AS State,
		|		VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedOnWarehouse) AS State,
		|		VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedOnWarehouse) AS State,
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedOnWarehouse) AS State,
		|		VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.SuppliedByDate) AS State,
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.ExpectedBasedOnUnconfirmedOrder) AS State,
		|		VALUE(Enum.InventoryStates.PendingSupplyApproval) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.ExpectedBasedOnUnconfirmedOrder) AS State,
		|		VALUE(Enum.InventoryStates.PendingSupplyApproval) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.ExpectedBasedOnUnconfirmedOrder) AS State,
		|		VALUE(Enum.InventoryStates.PendingSupplyApproval) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.ExpectedBasedOnUnconfirmedOrder) AS State,
		|		VALUE(Enum.InventoryStates.PendingSupplyApproval) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.ToSupply_) AS State,
		|		VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.ToSupply_) AS State,
		|		VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.ToSupply_) AS State,
		|		VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.ToSupply_) AS State,
		|		VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.InventoryAllocationStates.NotProvide) AS State,
		|		VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|		VALUE(Enum.DemandCharacteristics.NotProvide) AS DemandCharacteristic) AS Set
		|WHERE
		|	Set.State IN(&SelectionOfStates)
		|INDEX BY
		|	InventoryState, DemandCharacteristic";
	
	Return QueryText;
	
EndFunction

&AtServer
Function QueryOptions()
	
	SelectionOfStates = New Array();
	
	Expected_ = False;
	NotExpectedOnTime = False;
	SecuredByDateAdded = False;
	For Each Item In SelectedStates Do
		
		If Not Item.Check Then
			Continue;
		EndIf;
		
		If Item.Value = Enums.InventoryAllocationStates.SuppliedByDate Then
			
			Expected_ = Expected_ Or Item.Presentation = NStr("vi = 'Đang chờ';
																|ru = 'Ожидается';
																|en = 'Expected'; fa = 'مورد انتظار';
																|it = 'Previsto';
																|pl = 'Oczekiwane';
																|tr = 'Beklenen'");
			NotExpectedOnTime = NotExpectedOnTime Or Item.Presentation = NStr("vi = 'Dự kiến không đúng hạn';
																				|ru = 'Ожидается не в срок';
																				|en = 'Expected out-of-time'; fa = 'Expected out-of-time';
																				|it = 'Previsto fuori termini';
																				|pl = 'Oczekuje się nie w terminie';
																				|tr = 'Zaman aşımı bekleniyor'");
			
			If SecuredByDateAdded Then
				Continue;
			EndIf;
			SecuredByDateAdded = True;
			SelectionOfStates.Add(Enums.InventoryAllocationStates.ExpectedBasedOnUnconfirmedOrder);
			
		EndIf;
		SelectionOfStates.Add(Item.Value);
		
	EndDo;
	
	QueryOptions = New Structure();
	QueryOptions.Insert("SelectionOfStates", SelectionOfStates);
	QueryOptions.Insert("Expected_", Expected_);
	QueryOptions.Insert("NotExpectedOnTime", NotExpectedOnTime);
	QueryOptions.Insert("CurrentOrder", Parameters.OrderDocument);
	QueryOptions.Insert("LabelOrder", NStr("vi = 'Đơn hàng';
											|ru = 'Заказ';
											|en = 'Order'; fa = 'سفارش';
											|it = 'Ordine';
											|pl = 'Order';
											|tr = 'Sipariş'"));
	QueryOptions.Insert("BeginningOfThisDay", BegOfDay(CurrentSessionDate()));
	QueryOptions.Insert("CurOrderLabel", NStr("vi = 'Đơn hàng hiện tại';
												|ru = 'Текущий заказ';
												|en = 'Current order'; fa = 'Current order';
												|it = 'Ordine corrente';
												|pl = 'Bieżące zamówienie';
												|tr = 'Mevcut sipariş'"));
	QueryOptions.Insert("ShipmentOrder", Parameters.OrderDocument);
	QueryOptions.Insert("ShippingOrders", Parameters.Orders);
	
	Return QueryOptions;
	
EndFunction

&AtClient
Procedure Attachable_ListOnActivateRow()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then
		
		Result = ListWhenActivatingLineOnServer(
			?(CurrentData.Property("Products"), CurrentData.Products, Undefined),
			?(CurrentData.Property("Characteristic"), CurrentData.Characteristic, Undefined),
			?(CurrentData.Property("Warehouse"), CurrentData.Warehouse, Undefined),
			?(CurrentData.Property("Purpose"), CurrentData.Purpose, Undefined),
			?(CurrentData.Property("UnitOfMeasure"), CurrentData.UnitOfMeasure, Undefined));
			
		FillPropertyValues(ThisObject, Result);
		Items.ProductLabel.Title = Result.ProductLabel;
		ThisIsWork = CurrentData.Property("ItemsType")
			And CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5");
		Items.PagesBasementTitleInStock.CurrentPage = ?(ThisIsWork,
			Items.PageBasementTitleInDivision,
			Items.BasementPageIsTitleOfWarehouseIncludingQualityControl);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ListWhenActivatingLineOnServer(Products, Characteristic, Warehouse, Purpose, UnitOfMeasure)
	
	QueriesTexts = New Array();
	QueriesTexts.Add(
		"SELECT
		|	Table.Description AS Description
		|FROM
		|	Catalog.Products AS Table
		|WHERE
		|	Table.Ref = &Products");
	QueriesTexts.Add(
		"SELECT
		|	Table.Description AS Description
		|FROM
		|	Catalog.ItemsCharacteristics AS Table
		|WHERE
		|	Table.Ref = &Characteristic");
	QueriesTexts.Add(
		"SELECT
		|	Table.Description AS Description
		|FROM
		|	Catalog.Warehouses AS Table
		|WHERE
		|	Table.Ref = &Warehouse");
	QueriesTexts.Add(
		"SELECT
		|	Table.Description AS Description
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS Table
		|WHERE
		|	Table.Ref = &UnitOfMeasure");
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Products = &Products
		|		AND Characteristic = &Characteristic
		|		AND Warehouse = &Warehouse) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Products = &Products
		|		AND Characteristic = &Characteristic
		|		AND Warehouse = &Warehouse) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	Calculation.Warehouse AS Warehouse,
		|	SUM(Calculation.QuantityWithoutControlOfReservesForShipAction) AS ResultIsInStockWithConfirmedQuality,
		|	SUM(Calculation.QuantityInStock) AS ResultIsInStock,
		|	SUM(Calculation.QuantityAvailableAndExpected) AS SummaryOfSchedule,
		|	SUM(CASE
		|		WHEN Calculation.Purpose IN (VALUE(Catalog.Assignments.EmptyRef), &Purpose)
		|			THEN Calculation.QuantityForShipAction
		|		ELSE 0
		|	END) AS TotalAvailableInStockWithConfirmedQuality,
		|	SUM(CASE
		|		WHEN Calculation.Purpose IN (VALUE(Catalog.Assignments.EmptyRef), &Purpose)
		|			THEN Calculation.QuantityInStockForActionToReserveAsReceived
		|		ELSE 0
		|	END) AS TotalAvailableInStock,
		|	SUM(CASE
		|		WHEN Calculation.Purpose IN (VALUE(Catalog.Assignments.EmptyRef), &Purpose)
		|			THEN Calculation.QuantityForActionIsReservedAsItBecomesAvailable
		|		ELSE 0
		|	END) AS TotalAvailableOnSchedule
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|GROUP BY
		|	Calculation.Products,
		|	Calculation.Characteristic,
		|	Calculation.Warehouse";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames, True, False);
	
	QueriesTexts.Add(QueryText);
	
	Query = New Query();
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Query.SetParameter("Products",     Products);
	Query.SetParameter("Characteristic",   Characteristic);
	Query.SetParameter("Warehouse",            Warehouse);
	Query.SetParameter("Purpose",       Purpose);
	Query.SetParameter("UnitOfMeasure", UnitOfMeasure);
	Query.TempTablesManager = New TempTablesManager();
	ExecutionResult = Query.ExecuteBatch();
	
	LabelElements = New Array();
	Selection = ExecutionResult[0].Select();
	If Selection.Next() Then
		LabelElements.Add(Selection.Description);
	EndIf;
	Selection = ExecutionResult[1].Select();
	If Selection.Next() Then
		LabelElements.Add(Selection.Description);
	EndIf;
	Selection = ExecutionResult[2].Select();
	If Selection.Next() Then
		LabelElements.Add(Selection.Description);
	EndIf;
	
	Result = New Structure();
	Result.Insert("ProductLabel", NStr("vi = 'Vị trí đơn hàng:';
										|ru = 'Позиция заказа:';
										|en = 'Order item:'; fa = 'Order item:';
										|it = 'Позиция заказа:';
										|pl = 'Order item:';
										|tr = 'Sipariş kalemi:'") + Chars.NBSp + StrConcat(LabelElements, ", "));
	Result.Insert("ResultIsInStockWithConfirmedQuality", 0);
	Result.Insert("ResultIsInStock", 0);
	Result.Insert("SummaryOfSchedule", 0);
	Result.Insert("TotalAvailableInStockWithConfirmedQuality", 0);
	Result.Insert("TotalAvailableInStock", 0);
	Result.Insert("TotalAvailableOnSchedule", 0);
	Result.Insert("ResultIsInReserveInWarehouseWithProvenQuality", 0);
	Result.Insert("TotalInReserveInTheWarehouse", 0);
	Result.Insert("ResultIsInReserveAccordingToSchedule", 0);
	Result.Insert("UnitOfMeasure", "");
	
	Selection = ExecutionResult[3].Select();
	If Selection.Next() Then
		Result.Insert("UnitOfMeasure", Selection.Description);
	EndIf;
	
	Selection = ExecutionResult[ExecutionResult.UBound()].Select();
	If Selection.Next() Then
		
		FillPropertyValues(Result, Selection);
		
		Result.TotalAvailableInStockWithConfirmedQuality = Max(Result.TotalAvailableInStockWithConfirmedQuality, 0);
		Result.TotalAvailableInStock = Max(Result.TotalAvailableInStock, 0);
		Result.TotalAvailableOnSchedule = Max(Result.TotalAvailableOnSchedule, 0);
		
		Result.ResultIsInStockWithConfirmedQuality = Max(Result.ResultIsInStockWithConfirmedQuality, 0);
		Result.ResultIsInStock = Max(Result.ResultIsInStock, 0);
		Result.SummaryOfSchedule = Max(Result.SummaryOfSchedule, 0);
		
		Result.ResultIsInReserveInWarehouseWithProvenQuality = Result.ResultIsInStockWithConfirmedQuality
			- Result.TotalAvailableInStockWithConfirmedQuality;
		Result.TotalInReserveInTheWarehouse = Result.ResultIsInStock
			- Result.TotalAvailableInStock;
		Result.ResultIsInReserveAccordingToSchedule = Result.SummaryOfSchedule
			- Result.TotalAvailableOnSchedule;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure ListSelectionOnClient(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	Data = Undefined;
	
	If StrFind(Field.Name, "ShipmentOrder") > 0
			And Item.CurrentData.Property("ShipmentOrder") Then
		
		Data = Item.CurrentData.ShipmentOrder;
		
	ElsIf StrFind(Field.Name, "ReceiptOrder") > 0
				And Item.CurrentData.Property("ReceiptOrder") Then
		
		Data = Item.CurrentData.ReceiptOrder;
		If Not ValueIsFilled(Data) And Item.CurrentData.Property("SupplyMethod") Then
			Data = Item.CurrentData.SupplyMethod;
		ElsIf ValueIsFilled(Data) And TypeOf(Data) = Type("CatalogRef.ControlledLots") Then
			Data = AttributesOfLotReference(Data);
		EndIf;
		
	ElsIf StrFind(Field.Name, "TheWayToEnsureProductName") > 0
				And Item.CurrentData.Property("SupplyMethod") Then
		
		Data = Item.CurrentData.SupplyMethod;
		If Not ValueIsFilled(Data) And Item.CurrentData.Property("ReceiptOrder") Then
			Data = Item.CurrentData.ReceiptOrder;
		EndIf;
		
	ElsIf StrFind(Field.Name, "Products") > 0
				And Item.CurrentData.Property("Products") Then
		
		Data = Item.CurrentData.Products;
		
	ElsIf StrFind(Field.Name, "Characteristic") > 0
				And Item.CurrentData.Property("Characteristic") Then
		
		Data = Item.CurrentData.Characteristic;
		
	ElsIf StrFind(Field.Name, "Warehouse") > 0
				And Item.CurrentData.Property("Warehouse") Then
		
		Data = Item.CurrentData.Warehouse;
		
	ElsIf StrFind(Field.Name, "Purpose") > 0
				And Item.CurrentData.Property("DestinationOrder") Then
		
		Data = Item.CurrentData.DestinationOrder;
		If Not ValueIsFilled(Data) And Item.CurrentData.Property("Purpose") Then
			Data = Item.CurrentData.Purpose;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Data) Then
		ShowValue(, Data);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AttributesOfLotReference(Data)
	
	SetPrivilegedMode(True);
	Lot = Common.ObjectAttributeValue(Data, "Lot");
	SetPrivilegedMode(False);
	Return Lot;
	
EndFunction

&AtServerNoContext
Procedure OnGetDataAtServer(TagName, Settings, Rows)
	
	Table = New ValueTable();
	Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	Table.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Table.Columns.Add("ShipmentOrder", Metadata.DefinedTypes.ExpectedShipment.Type);
	Table.Columns.Add("InventoryState", New TypeDescription("EnumRef.InventoryStates"));
	Table.Columns.Add("DemandCharacteristic", New TypeDescription("EnumRef.DemandCharacteristics"));
	Table.Columns.Add("IndexOf", New TypeDescription("Number"));
	Table.Columns.Add("Action", New TypeDescription("EnumRef.SupplyOptions"));
	Table.Columns.Add("ControlQualityOfReceivedGoods", New TypeDescription("Boolean"));
	Table.Columns.Add("QualityControl", New TypeDescription("Date"));
	
	IndexOf = 0;
	Keys = New Array();
	For Each String In Rows Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, String.Value.Data);
		NewRow.IndexOf = IndexOf;
		Keys.Add(String.Key);
		IndexOf = IndexOf + 1;
	EndDo;
	
	Query = New Query();
	Query.SetParameter("Table", Table);
	Query.Text = QueryTextOnGetDataAtServer("LIST");
	QueryResult = Query.ExecuteBatch();
	Selection = QueryResult[QueryResult.UBound() - 1].Select();
	
	TextColorParameter = New DataCompositionParameter("TextColor");
	PositiveValueTextColor = StyleColors.PositiveValueTextColor;
	HyperlinkColor = StyleColors.HyperlinkColor;
	While Selection.Next() Do
		
		String = Rows[Keys[Selection.IndexOf]].Data;
		FillPropertyValues(String, Selection, "YouCanShipFromAvailableBalance,CanBeShippedFromAvailability");
		RegistrationOfState = Rows[Keys[Selection.IndexOf]].Appearance.Get("State");
		If TypeOf(RegistrationOfState) = Type("DynamicListCellAppearance") Then
			
			If String.YouCanShipFromAvailableBalance Then
				RegistrationOfState.SetParameterValue(TextColorParameter, PositiveValueTextColor);
			ElsIf String.CanBeShippedFromAvailability Then
				RegistrationOfState.SetParameterValue(TextColorParameter, HyperlinkColor);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Selection = QueryResult[QueryResult.UBound()].Select();
	While Selection.Next() Do
		
		String = Rows[Keys[Selection.IndexOf]].Data;
		FillPropertyValues(String, Selection, "DateOfReceipt");
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetUpdate(QueryOptions, AddressOfTheMovementTable)
	
	Data = GetFromTempStorage(AddressOfTheMovementTable);
	TempTablesManager = New TempTablesManager;
	
	StockAllocationRecords.AddRegisterColumns(Data.RegisterRecordTable);
	InventoryAllocation.StateWithReflectionOfChanges(
		OrdersMotionRecorders.UnloadValues(),
		Data.RegisterRecordTable,
		TempTablesManager,
		Data.TableSimulationRegistry);
		
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText(Items.Set.Name);
	Query.SetParameter("ExcludedOrders", New Array());
	Query.SetParameter("SelectionOfStates", QueryOptions.SelectionOfStates);
	Query.SetParameter("Expected_", QueryOptions.Expected_);
	Query.SetParameter("NotExpectedOnTime", QueryOptions.NotExpectedOnTime);
	Query.SetParameter("CurrentOrder", QueryOptions.CurrentOrder);
	Query.SetParameter("LabelOrder", QueryOptions.LabelOrder);
	Query.SetParameter("BeginningOfThisDay", QueryOptions.BeginningOfThisDay);
	Query.SetParameter("AvailableOrderTypes", AvailableOrderTypes());
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));

	SetPrivilegedMode(True);
	Table = Query.Execute().Unload();
	
	Table.Columns.Add("IndexOf", New TypeDescription("Number"));
	For IndexOf = 0 To Table.Count() - 1 Do
		Table[IndexOf].IndexOf = IndexOf;
	EndDo;
	
	Query.SetParameter("Table", Table);
	Query.Text = QueryTextOnGetDataAtServer("TABLE");
	QueryResult = Query.ExecuteBatch();
	Selection = QueryResult[QueryResult.UBound() - 1].Select();
	
	While Selection.Next() Do
		FillPropertyValues(Table[Selection.IndexOf], Selection, "YouCanShipFromAvailableBalance,CanBeShippedFromAvailability");
	EndDo;
	Selection = QueryResult[QueryResult.UBound()].Select();
	While Selection.Next() Do
		FillPropertyValues(Table[Selection.IndexOf], Selection, "DateOfReceipt");
	EndDo;
	
	Set.Load(Table);
	
	Query.Text =
		"SELECT
		|COUNT(*) AS TotalRecords
		|FROM
		|	SimulationOfReflection AS Table
		|WHERE
		|	Table.DemandCharacteristic IN(
		|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|		VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked),
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|		VALUE(Enum.DemandCharacteristics.ToSupply),
		|		VALUE(Enum.DemandCharacteristics.NotProvide))
		|
		|;
		|///////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE AS ThereIsShip
		|FROM
		|	SetOfRecordsStocksAndNeeds AS Table
		|WHERE
		|	Table.OrderToShip = &CurrentOrder
		|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND Table.InStock > 0";
	TotalRowsInListWithoutFilters = 0;
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	If Selection.Next() Then
		TotalRowsInListWithoutFilters = Selection.TotalRecords;
	EndIf;
	
	Selection = QueryResult[1].Select();
	If Selection.Next() Then
		// it is enough to understand that all lines cannot be selected in the list.
		TotalRowsInListWithoutFilters = TotalRowsInListWithoutFilters + 1;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function QueryTextOnGetDataAtServer(Source)
	
	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
	Texts = New Array();
	If Source = "TABLE" Then
		
		RegisterName = "SimulationOfReflection"; // @query-part-1
		NameInventoryAndNeedsChange = "InventoryAndDemandsUpdate"; // @query-part-1
		
	ElsIf Source = "LIST" Then
		
		RegisterName = "InformationRegister.InventoryAllocation"; // @query-part-1
		NameInventoryAndNeedsChange = "";
		Texts.Add(ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule());
		
	EndIf;
	
	QueryText =
		"SELECT
		|	CAST(Table.Products AS Catalog.Products) AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.InventoryState AS InventoryState,
		|	Table.DemandCharacteristic AS DemandCharacteristic,
		|	CASE
		|		WHEN Table.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|				VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))
		|			THEN Table.ShipmentOrder
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	Table.ControlQualityOfReceivedGoods AS ControlQualityOfReceivedGoods,
		|	Table.QualityControl AS QualityControl,
		|	Table.IndexOf AS IndexOf
		|INTO Table
		|FROM
		|	&Table AS Table
		|WHERE
		|	Table.Action <> VALUE(Enum.SupplyOptions.NotRequired)
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ShipmentOrder
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(Table.Products.TermOfQualityControl, 0) AS TermOfQualityControl,
		|	Table.QualityControl AS QualityControl,
		|	Table.IndexOf AS IndexOf
		|INTO TableForCalculatingDateOfReceipt
		|FROM
		|	Table AS Table
		|WHERE
		|	Table.ControlQualityOfReceivedGoods
		|	AND Table.QualityControl <> DATETIME(1, 1, 1)
		|	AND ISNULL(Table.Products.TermOfQualityControl, 0) > 0
		|	AND Table.InventoryState IN(
		|		VALUE(Enum.InventoryStates.NotProvided),
		|		VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|	AND Table.DemandCharacteristic <> VALUE(Enum.DemandCharacteristics.NotProvide)
		|INDEX BY
		|	TermOfQualityControl, QualityControl
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Table.TermOfQualityControl AS TermOfQualityControl,
		|	Table.QualityControl AS QualityControl
		|INTO SearchParameters
		|FROM
		|	TableForCalculatingDateOfReceipt AS Table
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Table.TermOfQualityControl AS TermOfQualityControl,
		|	Table.QualityControl AS QualityControl,
		|	CalculationOfDeliveryDateOverridable.DateFound AS DateOfReceipt
		|INTO TTScheduleDates
		|FROM
		|	SearchParameters AS Table
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|INDEX BY
		|	TermOfQualityControl, QualityControl";
		
	Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
		"Table.QualityControl",
		"(-Table.TermOfQualityControl)");
	
	If AnExternalUserIsAuthorized Then
		
		QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", "");
		QueryText = StrReplace(QueryText, "CalculationOfDeliveryDateOverridable.DateFound", "DATETIME(1, 1, 1)");
		
	Else
		
		QueryText = StrReplace(QueryText, "CalculationOfDeliveryDateOverridable.DateFound", Substitutions.Field);
		QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", Substitutions.Joins);
		
	EndIf;
	
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose, OrderDocument) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose,
		|				Filter.ShipmentOrder AS OrderDocument
		|			FROM
		|				Table AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				Table AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////
		|SELECT ALLOWED
		|	InventoryAllocation.Products AS Products,
		|	InventoryAllocation.Characteristic AS Characteristic,
		|	InventoryAllocation.Warehouse AS Warehouse,
		|	InventoryAllocation.Purpose AS Purpose,
		|	InventoryAllocation.InventoryState AS InventoryState,
		|	InventoryAllocation.DemandCharacteristic AS DemandCharacteristic,
		|	InventoryAllocation.ReceiptOrder AS ReceiptOrder,
		|	InventoryAllocation.DateOfReceipt AS DateOfReceipt,
		|	InventoryAllocation.AvailabilityDate AS AvailabilityDate,
		|	InventoryAllocation.ShipmentOrder AS ShipmentOrder,
		|	InventoryAllocation.RequestShipmentOn AS RequestShipmentOn,
		|	InventoryAllocation.Count AS Count
		|INTO InventoryAllocation
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|WHERE
		|	TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			Table AS Filter
		|		WHERE
		|			Filter.Products = InventoryAllocation.Products
		|			AND Filter.Characteristic = InventoryAllocation.Characteristic
		|			AND Filter.Warehouse = InventoryAllocation.Warehouse
		|			AND Filter.Purpose = InventoryAllocation.Purpose
		|			AND Filter.ShipmentOrder = InventoryAllocation.ShipmentOrder)
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Table.IndexOf AS IndexOf,
		|	
		|	ISNULL(Balance.QuantityForShipAction, 0)
		|		>= ISNULL(Demands.ReserveAsReceived
		|				+ Demands.SnoozeReservation
		|				+ Demands.ToSupply, 0) AS YouCanShipFromAvailableBalance,
		|	
		|	ISNULL(Balance.QuantityWithoutControlOfReservesForShipAction, 0)
		|		>= ISNULL(Demands.ReserveAtWarehouse
		|				+ Demands.ReserveAsReceived
		|				+ Demands.SnoozeReservation
		|				+ Demands.ToSupply, 0) AS CanBeShippedFromAvailability
		|FROM
		|	Table AS Table
		|		
		|		LEFT JOIN CalculationOfBalancesForSettingActions AS Balance
		|		ON Balance.ShipmentOrder = Table.ShipmentOrder
		|		AND Balance.Products = Table.Products
		|		AND Balance.Characteristic = Table.Characteristic
		|		AND Balance.Warehouse = Table.Warehouse
		|		AND Balance.Purpose = Table.Purpose
		|		AND Balance.ControlledLotReference = Table.ControlledLotReference
		|
		|		LEFT JOIN Demands AS Demands
		|		ON Demands.ShipmentOrder = Table.ShipmentOrder
		|		AND Demands.Products = Table.Products
		|		AND Demands.Characteristic = Table.Characteristic
		|		AND Demands.Warehouse = Table.Warehouse
		|		AND Demands.Purpose = Table.Purpose
		|		AND Demands.ControlledLotReference = Table.ControlledLotReference
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Table.IndexOf AS IndexOf,
		|	ISNULL(TTScheduleDates.DateOfReceipt, DATETIME(1, 1, 1)) AS DateOfReceipt
		|FROM
		|	TableForCalculatingDateOfReceipt AS Table
		|		LEFT JOIN TTScheduleDates
		|		ON TTScheduleDates.QualityControl = Table.QualityControl
		|			AND TTScheduleDates.TermOfQualityControl = Table.TermOfQualityControl";
	
	QueryText = StrReplace(QueryText, "InformationRegister.InventoryAllocation", RegisterName); // @query-part-1
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Analysts = "Table"; // @query-part-1
	TablesNames.InventoryAndDemandsUpdate = NameInventoryAndNeedsChange;
	TablesNames.InventoryAllocation = "InventoryAllocation"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	TablesNames.Demands = "Demands"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames, True, False);
	Texts.Add(QueryText);
	
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	Return QueryText;
	
EndFunction

#EndRegion

#Region ExecutingCommands

&AtClient
Procedure UpdateList()
	
	If ContextOfUse = "SECTION" Or ContextOfUse = "ORDERLIST" Then
		Items.ListOfOrders.Refresh();
	ElsIf ContextOfUse = "ORDERDOCUMENT" Then
		Items.List.Refresh();
		If ThisIsWaitingForReservationsFromOtherOrders = True Then
			FormOwner.Read();
		EndIf;
	EndIf;
	ThisIsWaitingForReservationsFromOtherOrders = False;
	
EndProcedure

&AtClient
Function CurrentDataClient()
	
	If ContextOfUse = "TABLE" Then
		
		CurrentData = Items.Set.CurrentData;
		
	Else
		
		If ContextOfUse = "ORDERDOCUMENT" Then
			
			CurrentData = Items.List.CurrentData;
			
		ElsIf ContextOfUse = "ORDERLIST" Or ContextOfUse = "SECTION" Then
			
			CurrentData = Items.ListOfOrders.CurrentData;
			
		EndIf;
		
		If CurrentData <> Undefined Then
			
			If CurrentData.Property("RowGroup") Then
				CurrentData = Undefined;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return CurrentData;
	
EndFunction

&AtServer
Procedure MarkingValuesInListOnServer()
	
	ShouldSaveSettings();
	States1 = StatusBar(SelectedStates);
	ManagingListParameters(Items.States1.Name);
	
EndProcedure

&AtClient
Procedure ExecuteAction(ActionCode)
	
	UnloadedColumns =
		"ShipmentOrder,
		|RequestShipmentOn,
		|Products,
		|Characteristic,
		|State,
		|InventoryState,
		|DemandCharacteristic,
		|Warehouse,
		|Purpose,
		|Action,
		|WithAssignment,
		|Count";
	
	RowsArray = New Array();
	
	If ContextOfUse = "TABLE" Then
		
		For Each Id In Items.Set.SelectedRows Do
			
			RowData = Set.FindByID(Id);
			NewRow = New Structure(UnloadedColumns);
			FillPropertyValues(NewRow, RowData);
			RowsArray.Add(NewRow);
			
		EndDo;
		
	ElsIf ContextOfUse = "ORDERDOCUMENT" Then
		
		TotalCount1 = 0;
		For Each Id In Items.List.SelectedRows Do
			
			RowData = Items.List.RowData(Id);
			NewRow = New Structure(UnloadedColumns);
			FillPropertyValues(NewRow, RowData);
			RowsArray.Add(NewRow);
			TotalCount1 = TotalCount1 + NewRow.Count;
			
		EndDo;
		
	EndIf;
	
	If ActionCode = "ACTION_SHIP_SUPPLIED" Or ActionCode = "ACTION_RESERVATION_RESERVED" Then
		
		ToReserve_ = PredefinedValue("Enum.DemandCharacteristics.ReserveAtWarehouse");
		ToReserveAsNeeded = PredefinedValue("Enum.DemandCharacteristics.ReserveAsReceived");
		Snooze = PredefinedValue("Enum.DemandCharacteristics.SnoozeReservation");
		ToSupply = PredefinedValue("Enum.DemandCharacteristics.ToSupply");
		ReserveFromBlocked = PredefinedValue("Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked");
		ReserveAsManyOfBlocked = PredefinedValue("Enum.DemandCharacteristics.ReserveUponReceiptFromLocked");
		InStock = PredefinedValue("Enum.InventoryStates.InStock");
		AvailableUnlock = PredefinedValue("Enum.InventoryStates.AvailablePendingUnlocking");
		AvailableWithoutUnlocking = PredefinedValue("Enum.InventoryStates.AvailableNotSubjectToUnlocking");
		
		TotalRows = RowsArray.Count();
		For Counter = 1 To TotalRows Do
			ArrayRow = RowsArray[TotalRows - Counter];
			InventoryState = ArrayRow.InventoryState;
			DemandCharacteristic = ArrayRow.DemandCharacteristic;
			CanBeShipped = InventoryState = InStock And DemandCharacteristic = ToReserve_
				Or InventoryState = InStock And DemandCharacteristic = ToReserveAsNeeded
				Or InventoryState = InStock And DemandCharacteristic = Snooze
				Or InventoryState = InStock And DemandCharacteristic = ToSupply
				Or InventoryState = AvailableUnlock And DemandCharacteristic = ReserveFromBlocked
				Or InventoryState = AvailableUnlock And DemandCharacteristic = ReserveAsManyOfBlocked
				Or InventoryState = AvailableWithoutUnlocking And DemandCharacteristic = ReserveFromBlocked
				Or InventoryState = AvailableWithoutUnlocking And DemandCharacteristic = ReserveAsManyOfBlocked;
			
			If Not CanBeShipped Then
				RowsArray.Delete(TotalRows - Counter);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If RowsArray.Count() = 0 Then
		If UseGoodsQualityControl Then
			WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với các dòng đã chọn.
				|Để thực hiện lệnh, cần chọn các dòng của đơn hàng với trạng thái ""Dự phòng"" với chất lượng được xác nhận.';
				|ru = 'Команда не может быть выполнена для выбранных строк.
				|Для выполнения команды необходимо выбрать строки заказа в состоянии ""В резерве"" с подтвержденным качеством.';
				|en = 'Cannot run the command for the selected lines.
				|To run the command, select the order lines in the ""In reserve"" state with confirmed quality.'; fa = 'Cannot run the command for the selected lines.
				|To run the command, select the order lines in the ""In reserve"" state with confirmed quality.';
				|it = 'Cannot run the command for the selected lines.
				|To run the command, select the order lines in the ""In reserve"" state with confirmed quality.';
				|pl = 'Cannot run the command for the selected lines.
				|To run the command, select the order lines in the ""In reserve"" state with confirmed quality.';
				|tr = 'Seçilen satırlar için komut gerçekleştirilemez. 
				| Komutu gerçekleştirmek için ""Rezerve"" durumunda ve kalitesi onaylanmış sipariş satırlarını seçmek gerekir.""'");
		Else
			WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với các dòng đã chọn.
				|Để thực hiện lệnh, cần chọn các dòng của đơn hàng với trạng thái ""Dự phòng"".';
				|ru = 'Команда не может быть выполнена для выбранных строк.
				|Для выполнения команды необходимо выбрать строки заказа в состоянии ""В резерве"".';
				|en = 'Cannot run the command for the selected lines.
				|To run the command, select the order lines in the ""In reserve"" state.'; fa = 'Cannot run the command for the selected lines.
				|To run the command, select the order lines in the ""In reserve"" state.';
				|it = 'Cannot run the command for the selected lines.
				|To run the command, select the order lines in the ""In reserve"" state.';
				|pl = 'Cannot run the command for the selected lines.
				|To run the command, select the order lines in the ""In reserve"" state.';
				|tr = 'Seçilen satırlar için komut gerçekleştirilemez. 
				|Komutu gerçekleştirmek için ""Rezerve"" durumunda sipariş satırlarını seçmek gerekir.""'");
		EndIf;
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	PutStringsInStorage(UnloadedColumns, RowsArray);
	
	If ActionCode = "ACTION_SHIP_SUPPLIED" Or ActionCode = "ACTION_SHIP_AVAILABLE" Then
		
		If Not RemoveTheShipOnOneDateFlag_3 Then
			
			PerformActionAfterQuestion("DialogReturnCode_No", ActionCode);
			
		ElsIf TheShipmentDateOfAllLinesIsASingleDate <> Undefined
				And TheShipmentDateOfAllLinesIsASingleDate < BegOfDay(CommonClient.SessionDate()) Then
			
			If RowsArray.Count() = TotalRowsInListWithoutFilters Then
				PerformActionAfterQuestion("DialogReturnCode_No", ActionCode);
			Else
				DateSettingParameters = New Structure("TheShipmentDateOfAllLinesIsASingleDate,DateWhenTheNewLinesWereShipped",
					TheShipmentDateOfAllLinesIsASingleDate, DateWhenTheNewLinesWereShipped);
				ProvisionInDocumentsClient.ShowIssueUncheckShipByOneDateInStateOfProvision(
					ThisObject, DateSettingParameters, ActionCode, "PerformActionAfterQuestion");
			EndIf;
				
		Else
			PerformActionAfterQuestion(Undefined, ActionCode);
		EndIf;
		
	Else
		
		PerformActionAfterQuestion(Undefined, ActionCode);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingOrdersToSetActions(FillParameters, AdditionalParameters) Export
	
	If FillParameters = Undefined Or FillParameters = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	OrdersBeingProcessed = New Array();
	TimeConsumingOperation = ReserveLaunchOfBackgroundJobOnServer(FillParameters, OrdersBeingProcessed);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	CallbackDescription = New CallbackDescription(
		"ReserveOnServerAfterEndOfBackgroundJob",
		ThisObject,
		OrdersBeingProcessed);
		
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure PerformActionAfterQuestion(Response, ActionCode) Export
	
	Callback = New CallbackDescription(
		"UpdateSetAfterGettingAddressOfMovementTableOnClient",
		ThisObject,
		New Structure);
		
	AlertStructure = New Structure();
	AlertStructure.Insert("ActionCode", ActionCode);
	AlertStructure.Insert("AddressAnalyst", AddressAnalyst);
	AlertStructure.Insert("Callback", Callback);
	
	FillParameters = New Structure();
	FillParameters.Insert("UncheckShipByOneDateFlag", False);
	FillParameters.Insert("FillShippingDateWithSingleDate", False);
	
	If RemoveTheShipOnOneDateFlag_3 Then
		
		FillParameters.Insert("UncheckShipByOneDateFlag", Response = "DialogReturnCode_Yes");
		FillParameters.Insert("FillShippingDateWithSingleDate", Response = "DialogReturnCode_No"
		And TheShipmentDateOfAllLinesIsASingleDate < DateWhenTheNewLinesWereShipped);
		
		If Response = "DialogReturnCode_No" Then
			TheShipmentDateOfAllLinesIsASingleDate = Max(TheShipmentDateOfAllLinesIsASingleDate, DateWhenTheNewLinesWereShipped);
		ElsIf Response = "DialogReturnCode_Yes" Then
			TheShipmentDateOfAllLinesIsASingleDate = Undefined;
		EndIf;
		
	EndIf;
	
	AlertStructure.Insert("FillParameters", FillParameters);
	
	NotifyChoice(AlertStructure);
	
EndProcedure

&AtServer
Procedure PutStringsInStorage(UnloadedColumns, RowsArray)
	
	Analysts = Set.Unload(New Array, UnloadedColumns);
	For Each String In RowsArray Do
		FillPropertyValues(Analysts.Add(), String);
	EndDo;
	PutToTempStorage(Analysts, AddressAnalyst);
	
EndProcedure

&AtServer
Procedure UpdateSetAfterGettingAddressOfTable(AddressOfTheMovementTable)
	
	SetUpdate(QueryOptions(), AddressOfTheMovementTable);
	DeleteFromTempStorage(AddressOfTheMovementTable);
	
EndProcedure

&AtClient
Procedure UpdateSetAfterGettingAddressOfMovementTableOnClient(Result, AdditionalParameters) Export
	
	ContextOfUse = "TABLE";
	VisibilityManagement(Undefined, ThisObject, ContextOfUse);
	UpdateSetAfterGettingAddressOfTable(Result);
	
EndProcedure

&AtServer
Function ReserveLaunchOfBackgroundJobOnServer(FillParameters, OrdersBeingProcessed)
	
	ProcedureParameters = New Structure();
	
	TheOrdersTable = GetFromTempStorage(FillParameters.AddressInStorage);
	
	OrdersBeingProcessed.Add(FillParameters.ShipmentOrder);
	CommonClientServer.SupplementArray(OrdersBeingProcessed, TheOrdersTable.UnloadColumn("OrderDocument"));
	
	DimensionOfProduct = New Structure();
	DimensionOfProduct.Insert("Products", FillParameters.Products);
	DimensionOfProduct.Insert("Characteristic", FillParameters.Characteristic);
	DimensionOfProduct.Insert("Warehouse", FillParameters.Warehouse);
	DimensionOfProduct.Insert("Purpose", FillParameters.Purpose);
	
	ProcedureParameters.Insert("ShipmentOrder", FillParameters.ShipmentOrder);
	ProcedureParameters.Insert("ToReserveEverything", FillParameters.ToReserveEverything);
	ProcedureParameters.Insert("DimensionOfProduct", DimensionOfProduct);
	ProcedureParameters.Insert("TheOrdersTable", TheOrdersTable);
	DeleteFromTempStorage(FillParameters.AddressInStorage);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Trạng thái đảm bảo: Dự phòng trong kho';
														|ru = 'Состояние обеспечения: Резервировать на складе';
														|en = 'Supply forecast: Reserve at warehouse'; fa = 'Supply forecast: Reserve at warehouse';
														|it = 'Состояние обеспечения: Резервировать на складе';
														|pl = 'Supply forecast: Reserve at warehouse';
														|tr = 'Tedarik durumu: Ambarda rezerve et'");
	
	Return TimeConsumingOperations.ExecuteInBackground("ProvisionInDocumentsServer.ReserveFromOtherOrders",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure ReserveOnServerAfterEndOfBackgroundJob(Result, Processed_Orders) Export

	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	Else
		ResultStructure1 = GetFromTempStorage(Result.ResultAddress);
		DeleteFromTempStorage(Result.ResultAddress);
		If ResultStructure1.ErrorText <> Undefined Then
			CommonClient.MessageToUser(NStr("vi = 'Chưa thực hiện dự phòng.';
											|ru = 'Резервирование не выполнено.';
											|en = 'Not reserved.'; fa = 'Not reserved.';
											|it = 'Резервирование не выполнено.';
											|pl = 'Not reserved.';
											|tr = 'Rezervasyon yapılmadı.'"));
			CommonClient.MessageToUser(ResultStructure1.ErrorText);
		Else
			FillInOrdersToCheckTasksAfterReservingFromOtherOrders(Processed_Orders);
			ShowUserNotification(NStr("vi = 'Dự phòng trong kho.';
										|ru = 'Резервирование на складе.';
										|en = 'Reservation in the warehouse.'; fa = 'Reservation in the warehouse.';
										|it = 'Резервирование на складе.';
										|pl = 'Reservation in the warehouse.';
										|tr = 'Ambar rezervasyonu.'"), ,
					NStr("vi = 'Dã thực hiện thành công lệnh.';
						|ru = 'Команда выполнена успешно.';
						|en = 'Command completed successfully.'; fa = 'Command completed successfully.';
						|it = 'Команда выполнена успешно.';
						|pl = 'Command completed successfully.';
						|tr = 'Komut başarıyla tamamlandı.'"), , , );
		EndIf;
		For Each Error In ResultStructure1.UserMessages Do
			Error.Message();
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReserveAtWarehouseClient()
	
	ClearMessages();
	WarningText = Undefined;
	CurrentData = CurrentDataClient();
	If CurrentData = Undefined Then
		
		ShowMessageBox(,
			NStr("vi = 'Không thể thực hiện lệnh. Để dự phòng, cần chọn dòng (vị trí) của đơn hàng.';
				|ru = 'Команда не может быть выполнена. Для резервирования необходимо выбрать строку (позицию) заказа.';
				|en = 'Cannot run the command. To reserve, select the order line (item).'; fa = 'Cannot run the command. To reserve, select the order line (item).';
				|it = 'Команда не может быть выполнена. Для резервирования необходимо выбрать строку (позицию) заказа.';
				|pl = 'Cannot run the command. To reserve, select the order line (item).';
				|tr = 'Komut gerçekleştirilemez. Rezervasyon yapmak için sipariş satırını (pozisyonunu) seçmeniz gerekmektedir.'"));
		
	ElsIf TypeOf(CurrentData.Warehouse) <> Type("CatalogRef.Warehouses") Then
	
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh cho công việc.';
								|ru = 'Команда не может быть выполнена для работ.';
								|en = 'Cannot run the command for works.'; fa = 'Cannot run the command for works.';
								|it = 'Команда не может быть выполнена для работ.';
								|pl = 'Cannot run the command for works.';
								|tr = 'İşler için komut gerçekleştirilemez.'"));
		
	ElsIf Not ValueIsFilled(CurrentData.Warehouse) Then
	
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh, nếu chưa điền kho bãi trong dòng.';
								|ru = 'Команда не может быть выполнена, если склад в строке не заполнен.';
								|en = 'Cannot run the command if the warehouse in the line is not filled.'; fa = 'Cannot run the command if the warehouse in the line is not filled.';
								|it = 'Команда не может быть выполнена, если склад в строке не заполнен.';
								|pl = 'Cannot run the command if the warehouse in the line is not filled.';
								|tr = 'Satırdaki ambar doldurulmamış ise komut gerçekleştirilemez.'"));
		
	ElsIf TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.CustomerInvoice")
				Or TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.DiscrepancyReportFollowingTransfer")
				
				
				Or TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
	
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh cho chứng từ này.';
								|ru = 'Команда не может быть выполнена для данного документа.';
								|en = 'Cannot run the command for this document.'; fa = 'Cannot run the command for this document.';
								|it = 'Команда не может быть выполнена для данного документа.';
								|pl = 'Cannot run the command for this document.';
								|tr = 'Mevcut belge için komut gerçekleştirilemez.'"));
		
	ElsIf (TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.SalesOrder")
				Or TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
				
				
				Or TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.SubcontractOrder2_5")
				
				
				Or TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.RMOrder")
				Or TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.MaterialProviderOrder2_5")
				Or TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.ProductionStage2_2")
				
				Or TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.InventoryConsumptionOrder"))
					And ReserveInStockOrderVerification(CurrentData.ShipmentOrder, WarningText) Then
				
		ShowMessageBox(, WarningText);
		
	ElsIf TypeOf(CurrentData.ShipmentOrder) = Type("DocumentRef.ByAssemblyDisassemblyOrder")
					And ThisIsDisassembly(CurrentData.ShipmentOrder) Then
		
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh cho đơn hàng tách bộ.';
								|ru = 'Команда не может быть выполнена для заказов на разборку.';
								|en = 'Cannot run the command for reverse kitting orders.'; fa = 'Cannot run the command for reverse kitting orders.';
								|it = 'Команда не может быть выполнена для заказов на разборку.';
								|pl = 'Cannot run the command for reverse kitting orders.';
								|tr = 'Demontaj emirleri için komut gerçekleştirilemez.'"));
		
	Else
		
		FormParameters = ProvisionInDocumentsClient.ParametersOfQuantityInputFormReserveFromOtherOrders();
		FillPropertyValues(FormParameters, CurrentData);
		
		ResultStructure1 = ReserveInStockWithoutUsingReservesOfOtherOrders(
			FormParameters,
			Parameters.OrderDocument,
			?(ContextOfUse = "ORDERDOCUMENT", FormOwner.UUID, Undefined));
		If ResultStructure1 = Undefined Then
			
			Notification = New CallbackDescription("AfterSelectingOrdersToSetActions", ThisObject);
			
			PerformanceMonitorClient.TimeMeasurement(
				"DataProcessor.OrderSupplyForecast.Form.SetReserveAtWarehouseAction.Event.OpenForm");
			OpenForm("DataProcessor.OrderSupplyForecast.Form.SetReserveAtWarehouseAction",
				FormParameters, ThisObject, , , , Notification);
				
		Else
			If ResultStructure1.ErrorText <> Undefined Then
				CommonClient.MessageToUser(NStr("vi = 'Chưa thực hiện dự phòng.';
												|ru = 'Резервирование не выполнено.';
												|en = 'Not reserved.'; fa = 'Not reserved.';
												|it = 'Резервирование не выполнено.';
												|pl = 'Not reserved.';
												|tr = 'Rezervasyon yapılmadı.'"));
				CommonClient.MessageToUser(ResultStructure1.ErrorText);
			Else
				Processed_Orders = CommonClientServer.ValueInArray(Parameters.OrderDocument);
				FillInOrdersToCheckTasksAfterReservingFromOtherOrders(Processed_Orders);
				ShowUserNotification(NStr("vi = 'Dự phòng trong kho.';
											|ru = 'Резервирование на складе.';
											|en = 'Reservation in the warehouse.'; fa = 'Reservation in the warehouse.';
											|it = 'Резервирование на складе.';
											|pl = 'Reservation in the warehouse.';
											|tr = 'Ambar rezervasyonu.'"), ,
					NStr("vi = 'Đã thực hiện thành công lệnh.';
						|ru = 'Команда выполнена успешно.';
						|en = 'Command completed successfully.'; fa = 'Command completed successfully.';
						|it = 'Команда выполнена успешно.';
						|pl = 'Command completed successfully.';
						|tr = 'Komut başarıyla tamamlandı.'"), , , );
			EndIf;
			For Each Error In ResultStructure1.UserMessages Do
				Error.Message();
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ReserveInStockWithoutUsingReservesOfOtherOrders(FormParameters, OrderDocument, UUID)
	
	If UUID <> Undefined Then
		UnlockDataForEdit(OrderDocument, UUID);
	EndIf;
	ProcedureParameters = New Structure();
	
	DimensionOfProduct = New Structure("Products,Characteristic,Warehouse,Purpose");
	FillPropertyValues(DimensionOfProduct, FormParameters);
	
	ProcedureParameters.Insert("ShipmentOrder", FormParameters.ShipmentOrder);
	ProcedureParameters.Insert("ToReserveEverything", 0);
	ProcedureParameters.Insert("DimensionOfProduct", DimensionOfProduct);
	ProcedureParameters.Insert("TheOrdersTable", Undefined);
	
	ResultAddress = PutToTempStorage(Undefined, New UUID());
	ProvisionInDocumentsServer.ReserveFromOtherOrders(ProcedureParameters, ResultAddress);
	
	ResultStructure1 = GetFromTempStorage(ResultAddress);
	Return ResultStructure1;
	
EndFunction

&AtClient
Procedure QuestionIsToPostEndDocument(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CallbackDescription = New CallbackDescription("DocumentRecordingCompletion", ThisObject);
		TMCommonUseClient.Post(FormOwner, True, CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentRecordingCompletion(QuestionResult, AdditionalParameters) Export
	
	ContextOfUse = "ORDERDOCUMENT";
	VisibilityManagement(Undefined, ThisObject, ContextOfUse);
	ManagingListParameters(Undefined);
	ReserveAtWarehouseClient();
	
EndProcedure

&AtServerNoContext
Function ReserveInStockOrderVerification(OrderDocument, WarningText)
	
	WarningText = Undefined;
	If TypeOf(OrderDocument) = Type("DocumentRef.SalesOrder")
			Or TypeOf(OrderDocument) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				
				OrderDetails = Common.ObjectAttributesValues(OrderDocument, "Status,ThisIsOrderAsInvoice");
				If OrderDetails.ThisIsOrderAsInvoice
						Or Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
							
							WarningText = NStr("vi = 'Không thể thực hiện lệnh cho đơn hàng như hóa đơn.';
												|ru = 'Команда не может быть выполнена для заказов как счет.';
												|en = 'Cannot run the command for orders as a commercial invoice.'; fa = 'Cannot run the command for orders as a commercial invoice.';
												|it = 'Команда не может быть выполнена для заказов как счет.';
												|pl = 'Cannot run the command for orders as a commercial invoice.';
												|tr = 'Komut, fatura olarak siparişler için gerçekleştirilemez.'");
							Return True;
							
				ElsIf Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
					
					WarningText = NStr("vi = 'Không thể thực hiện lệnh cho các đơn hàng từ kho.';
										|ru = 'Команда не может быть выполнена для заказов со склада.';
										|en = 'Cannot run the command for orders from the warehouse.'; fa = 'Cannot run the command for orders from the warehouse.';
										|it = 'Команда не может быть выполнена для заказов со склада.';
										|pl = 'Cannot run the command for orders from the warehouse.';
										|tr = 'Ambardaki siparişler için komut gerçekleştirilemez.'");
					Return True;
					
				EndIf;
				
	Else
		OrderDetails = Common.ObjectAttributesValues(OrderDocument, "Status");
	EndIf;
	
	If ThisIsStatusOnApproval(OrderDetails.Status) Then
		
		WarningText = StrTemplate(NStr("vi = 'Không thể thực hiện lệnh cho đơn hàng trong trạng thái ""%1"".';
										|ru = 'Команда не может быть выполнена для заказа в статусе ""%1"".';
										|en = 'Cannot run the command for orders in the %1 status.'; fa = 'Cannot run the command for orders in the %1 status.';
										|it = 'Команда не может быть выполнена для заказа в статусе ""%1"".';
										|pl = 'Cannot run the command for orders in the %1 status.';
										|tr = 'Komut, ""%1"" durumundaki sipariş için gerçekleştirilemez.'"),
			OrderDetails.Status);
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function ThisIsStatusOnApproval(Status)
	
	Result =
		Status = Enums.SalesOrderStatuses.NotApproved
				Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon
				Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn
		
			Or Status = Enums.TollingOrderStatuses.NotApproved
			Or Status = Enums.RMOrderStatuses.Created
		
			Or Status = Enums.StatusesOfMaterialProviderOrders.NotApproved
			Or Status = Enums.StatusesOfProductionStages2_2.BeingGenerated
		
			Or Status = Enums.InternalOrderStatuses.AwaitingApproval;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ThisIsDisassembly(OrderDocument)
	EconomicOperationOfOrder = Common.ObjectAttributeValue(OrderDocument, "BusinessOperation");
	Return EconomicOperationOfOrder = Enums.BusinessTransactions.DisassemblyIntoComponents;
EndFunction
&AtClient
Procedure CheckAndReserveGoodsInProductionPhase()
	
	CurrentData = Items.Set.CurrentData;
	WarningText = Undefined;
	
	If CurrentData = Undefined Then
		
		ShowMessageBox(,
			NStr("vi = 'Không thể thực hiện lệnh. Để dự phòng, cần chọn dòng (vị trí) của đơn hàng.';
				|ru = 'Команда не может быть выполнена. Для резервирования необходимо выбрать строку (позицию) заказа.';
				|en = 'Cannot run the command. To reserve, select the order line (item).'; fa = 'Cannot run the command. To reserve, select the order line (item).';
				|it = 'Команда не может быть выполнена. Для резервирования необходимо выбрать строку (позицию) заказа.';
				|pl = 'Cannot run the command. To reserve, select the order line (item).';
				|tr = 'Komut gerçekleştirilemez. Rezervasyon yapmak için sipariş satırını (pozisyonunu) seçmeniz gerekmektedir.'"));
		
	ElsIf TypeOf(CurrentData.Warehouse) <> Type("CatalogRef.Warehouses") Then
	
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh cho công việc.';
								|ru = 'Команда не может быть выполнена для работ.';
								|en = 'Cannot run the command for works.'; fa = 'Cannot run the command for works.';
								|it = 'Команда не может быть выполнена для работ.';
								|pl = 'Cannot run the command for works.';
								|tr = 'İşler için komut gerçekleştirilemez.'"));
		
	ElsIf ReserveInStockOrderVerification(CurrentData.ShipmentOrder, WarningText) Then
				
		ShowMessageBox(, WarningText);
		
	Else
		
		DimensionOfProduct = New Structure("Products, Characteristic, Warehouse, Purpose, WithAssignment");
		FillPropertyValues(DimensionOfProduct, CurrentData);
		Result = ReserveGoodsInProductionPhase(CurrentData.ShipmentOrder, DimensionOfProduct);
		
		If Result Then
			ShowUserNotification(NStr("vi = 'Lập dự phòng.';
										|ru = 'Резервирование.';
										|en = 'Reservation.'; fa = 'Reservation.';
										|it = 'Reservation.';
										|pl = 'Reservation.';
										|tr = 'Rezervasyon.'"), ,
						NStr("vi = 'Dã thực hiện thành công lệnh.';
							|ru = 'Команда выполнена успешно.';
							|en = 'Command completed successfully.'; fa = 'Command completed successfully.';
							|it = 'Команда выполнена успешно.';
							|pl = 'Command completed successfully.';
							|tr = 'Komut başarıyla tamamlandı.'"), , , );
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function ReserveGoodsInProductionPhase(Stage, DimensionOfProduct)

	ReservationIsCompleted = Documents.ProductionStage2_2.MakeReservationsForGoodsOfDynamicStructureStage(Stage, DimensionOfProduct);
	If ReservationIsCompleted Then
		
		Address = Documents.ProductionStage2_2.AddressOfRegisteredRecordsTableForCallingSupplyForecastStatus(Parameters.Orders, UUID);
		
		If IsTempStorageURL(Parameters.AddressOfTheMovementTable) Then
			DeleteFromTempStorage(Parameters.AddressOfTheMovementTable);
		EndIf;
		
		Parameters.AddressOfTheMovementTable = Address;
		SetUpdate(QueryOptions(), Address);
		
	EndIf;
	Return ReservationIsCompleted;

EndFunction
#EndRegion

#EndRegion
