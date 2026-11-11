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
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	RestoreSettings();
	Object.Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	
	If Not UseSeveralWarehouses Then
		Object.Warehouse = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse);
		Items.GroupSelectionWarehouse.Visible = False;
	EndIf;
	
	ScenarioData = ScriptDetailsValues(Object.Scenario);
	FillPropertyValues(ThisObject, ScenarioData);
	
	ModeForCalculatingNeedsOfPlanWhenChangingOnServer();
	BringDatesToPeriodicityOfScript(ThisObject, Object.PeriodBeginning, Object.PeriodEnd);
	
	SetFormItemsVisibility();
	VisibilitySettingsWhenChangingScript(ThisForm);
	VisibilitySettingsWhenChangingWarehouseSelectionOnServer(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetFormHeader(Items.PagesMainPanel.CurrentPage);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Settings.Insert("Object.Warehouse", SettingsValueCached.GetDefaultWarehouse(Object.Warehouse));
	EndIf; 
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ByAssemblyDisassemblyOrder" And Items.PagesMainPanel.CurrentPage = Items.PageStep2 Then
		
		DocumentListForUpdate.Add(Source);
		UpdateDataWhenFormBecomesActive();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes  Then
		
		UpdateAtServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not Object.DataPopulationMode Then
		
		VerificationDetails_1 = New Structure;
		VerificationDetails_1.Insert("Products", NStr("vi = 'Mặt hàng';
														|ru = 'Номенклатура';
														|en = 'Items'; fa = 'اقلام';
														|it = 'Articolo';
														|pl = 'Pozycja';
														|tr = 'Ürün'"));
		VerificationDetails_1.Insert("Warehouse", NStr("vi = 'Kho bãi';
														|ru = 'Склад';
														|en = 'Warehouse'; fa = 'Warehouse';
														|it = 'Magazzino';
														|pl = 'Magazyn';
														|tr = 'Ambar'"));
		VerificationDetails_1.Insert("ProductKit", NStr("vi = 'Đóng bộ';
														|ru = 'Комплектация';
														|en = 'Product kit'; fa = 'کیت کالا';
														|it = 'Componenti';
														|pl = 'Product kit';
														|tr = 'Ürün seti'"));
		
		
		MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2.';
								|ru = 'Не заполнена колонка ""%1"" в строке %2.';
								|en = 'Column ""%1"" in line %2 is not filled in.'; fa = 'Column ""%1"" in line %2 is not filled in.';
								|it = 'Non è stata compilata la colonna ""%1"" nella riga %2.';
								|pl = 'Nie wypełniono kolumny ""%1"" w wierszu%2.';
								|tr = '%2 satırındaki ""%1"" sütunu doldurulmamış.'");
		For Each OrderDataLine In Object.GenerationOfOrders Do
			If Not OrderDataLine.SelectToOrder Or OrderDataLine.NumberOfPackages = 0 Then
				Continue;
			EndIf;
			
			For Each TSProps In VerificationDetails_1 Do
				If Not ValueIsFilled(OrderDataLine[TSProps.Key]) Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplate, 
												TSProps.Value,
												OrderDataLine.LineNumber);
												
					Field = CommonClientServer.PathToTabularSection("GenerationOfOrders", OrderDataLine.LineNumber, TSProps.Key);
					CommonClientServer.MessageToUser(MessageText,, Field, "Object", Cancel);
				EndIf;
				
			EndDo;
		EndDo;
		
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
Procedure FilterWarehouseOnChange(Item)
	
	VisibilitySettingsWhenChangingWarehouseSelectionOnServer(ThisForm);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	VisibilitySettingsWhenChangingWarehouseSelectionOnServer(ThisForm);
	
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
	RowKey.Insert("BeginOfPeriod", 	CurRow.AssemblyPeriodStart);
	RowKey.Insert("PeriodEnding", EndOfDay(CurRow.AssemblyEndDate));
	
	RowKey.Insert("ProductKit",   CurRow.ProductKit);
	RowKey.Insert("BusinessOperation", CurRow.BusinessOperation);
	
	If CurRow.EditWarehouse Then
		RowKey.Insert("Warehouse", 	PredefinedValue("Catalog.Warehouses.EmptyRef"));
	Else
		RowKey.Insert("Warehouse", 	CurRow.Warehouse);
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
	RowKey.Insert("Purpose", 		CurRow.Purpose);
	RowKey.Insert("AssemblyPeriodStart", CurRow.AssemblyPeriodStart);
	RowKey.Insert("AssemblyEndDate", CurRow.AssemblyEndDate);
	RowKey.Insert("EndOfDayBuildEndDate", EndOfDay(CurRow.AssemblyEndDate));
	
	If CurRow.EditWarehouse Then
		RowKey.Insert("Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"));
	Else
		RowKey.Insert("Warehouse", CurRow.Warehouse);
	EndIf;
	
	RowKey.Insert("ProductKit",   CurRow.ProductKit);
	RowKey.Insert("BusinessOperation", CurRow.BusinessOperation);
	
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
Procedure GenerationOfOrdersWarehouseOnChange(Item)
	
	CurrentRow = Items.GenerationOfOrders.CurrentRow;
	UpdateBuildDateWhenWarehouseChanges(CurrentRow);
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersWarehouseStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);

	RowKey = New Structure;
	RowKey.Insert("Products",					TableRow.Products);
	RowKey.Insert("Characteristic",				TableRow.Characteristic);
	RowKey.Insert("BusinessOperation",		TableRow.BusinessOperation);
	RowKey.Insert("ProductKit", 			TableRow.ProductKit);
	RowKey.Insert("EditWarehouse",	False);
	RowKey.Insert("AssemblyPeriodStart",			TableRow.AssemblyPeriodStart);
	RowKey.Insert("AssemblyEndDate",			TableRow.AssemblyEndDate);
	
	LinkIsNotInList = New Array;
	Rows = TableOrderGeneration.FindRows(RowKey);
	For Each String In Rows Do
		LinkIsNotInList.Add(String.Warehouse);
	EndDo;
	
	Filter = New Structure("Warehouse", True);
	
	Notification = New CallbackDescription("FillInTheWarehouseCompletion", 
		ThisObject, 
		New Structure("SelectedRows", Items.GenerationOfOrders.SelectedRows));
	OpenForm("Catalog.Warehouses.ChoiceForm", 
		New Structure("Key, Filter, LinkIsNotInList", TableRow.Warehouse, Filter, LinkIsNotInList),
		,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure GenerationOfOrdersWarehouseChoiceProcessing(Item, ValueSelected, StandardProcessing)
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);

	RowKey = New Structure;
	RowKey.Insert("Products",					TableRow.Products);
	RowKey.Insert("Characteristic",				TableRow.Characteristic);
	RowKey.Insert("BusinessOperation",		TableRow.BusinessOperation);
	RowKey.Insert("ProductKit", 			TableRow.ProductKit);
	RowKey.Insert("EditWarehouse",	False);
	RowKey.Insert("AssemblyPeriodStart",			TableRow.AssemblyPeriodStart);
	RowKey.Insert("AssemblyEndDate",			TableRow.AssemblyEndDate);
		
	Rows = TableOrderGeneration.FindRows(RowKey);
	For Each String In Rows Do
		If ValueSelected = String.Warehouse Then
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

#EndRegion

#Region CommandHandlers

&AtClient
Procedure PickProducts(Command)
	
	FormParameters = New Structure("SettingsComposer", SettingsComposer);
	OpenForm("DataProcessor.GenerationOfAssemblyDisassemblyOrdersByPlans.Form.FilterForm", FormParameters, ThisForm, UUID);
	
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
		"DataProcessor.GenerationOfAssemblyDisassemblyOrdersByPlans.Form.Command.Fill");
	
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
	
EndProcedure

&AtClient
Procedure OpenOrderList(Command)
	
	OpenForm("Document.ByAssemblyDisassemblyOrder.ListForm"); 
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#Region CommandsOfFormTableFormFormationOfOrders

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

	Filter = New Structure("IsFolder", False);
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);
	
	SelectedRows = New Array;
	For Each SelectedRow In Items.GenerationOfOrders.SelectedRows Do
		If Object.GenerationOfOrders.FindByID(SelectedRow).EditWarehouse Then
			SelectedRows.Add(SelectedRow);
		EndIf;
	EndDo;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn các dòng mà trong đó cho phép sửa kho bãi.';
								|ru = 'Выделите строки в которых разрешено редактирование склада.';
								|en = 'Select lines in which warehouse editing is allowed.'; fa = 'Select lines in which warehouse editing is allowed.';
								|it = 'Selezionate le righe in cui è consentita la modifica del magazzino.';
								|pl = 'Wybierz wiersze w których jest dozwolona edycja magazynu.';
								|tr = 'Ambarın düzenlenmesine izin verilen satırları vurgulayınız.'"));
		Return;
	EndIf;
	
	LinkIsNotInList = GetWarehousesByPlansBySelectedLines(SelectedRows);
	
	Notification = New CallbackDescription("FillInTheWarehouseCompletion", 
		ThisObject, 
		New Structure("SelectedRows", SelectedRows));
		
	ChoiceFormParameters = New Structure();
	ChoiceFormParameters.Insert("Key", TableRow.Warehouse);
	ChoiceFormParameters.Insert("Filter", Filter);
	ChoiceFormParameters.Insert("LinkIsNotInList", LinkIsNotInList);
	ChoiceFormParameters.Insert("ChoiceFoldersAndItems", False);
	
	OpenForm("Catalog.Warehouses.ChoiceForm", 
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
	FormParameters.Insert("AssemblyPeriodStart", Items.GenerationOfOrders.CurrentData.AssemblyPeriodStart);
	FormParameters.Insert("PlanningType", "PlanningAssemblyDisassembly");
	
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
		"DataProcessor.GenerationOfAssemblyDisassemblyOrdersByPlans.Form.Command.Next");
	
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
		
		ClearMessages();
		
		TheStructureOfTheSearch = New Structure("SelectToOrder", True);
		OrderBasket = Object.GenerationOfOrders.FindRows(TheStructureOfTheSearch);
		
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
		
		FillInCheckPassed = CreateOrdersOnServer();
		
		If Not FillInCheckPassed Then
			Return;
		EndIf;
		
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

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.EditWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersProductKit.Name);
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

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
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
Procedure VisibilitySettingsWhenChangingWarehouseSelectionOnServer(Form)
	
	VisibilityOfWarehouseColumns = Not (Form.FilterWarehouse And ValueIsFilled(Form.Object.Warehouse));
	Form.Items.GenerationOfOrdersFillInTheWarehouse.Visible = VisibilityOfWarehouseColumns;
	Form.Items.GenerationOfOrdersWarehouse.Visible = VisibilityOfWarehouseColumns;
	Form.Items.Warehouse.Enabled = Form.FilterWarehouse;
	
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
		DataCompositionSchema = DataProcessors.GenerationOfAssemblyDisassemblyOrdersByPlans.GetTemplate("CompositionTemplate");
	Else
		DataCompositionSchema = DataProcessors.GenerationOfAssemblyDisassemblyOrdersByPlans.GetTemplate("CompositionTemplateAccumulated");
		DataLayoutSchemeQuantityInPlans = DataProcessors.GenerationOfAssemblyDisassemblyOrdersByPlans.GetTemplate("CompositionTemplateQuantityInPlans");
		DataLayoutDiagramQuantityInOrders = DataProcessors.GenerationOfAssemblyDisassemblyOrdersByPlans.GetTemplate("CompositionTemplateQuantityInOrders");
		AddressOfDataCompositionSchemaPlannedQuantity = PutToTempStorage(DataLayoutSchemeQuantityInPlans, New UUID);
		AddressOfDataCompositionSchemaQuantityInOrders = PutToTempStorage(DataLayoutDiagramQuantityInOrders, New UUID);
	EndIf;
	
	DataCompositionSchema.DataSets[0].Query = Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False)
		+ InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
			DataCompositionSchema.DataSets[0].Query,
			"MainSupplyMethodSubstitution",
			"AssemblyPlansDisassemblyRevolutions.Products, AssemblyPlansDisassemblyRevolutions.Characteristic, AssemblyPlansDisassemblyRevolutions.Warehouse");
	
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

&AtServer
Procedure ShouldSaveSettings()
	
	Settings = New Structure;
	Settings.Insert("UserSettings",  SettingsComposer.UserSettings);
	Settings.Insert("Scenario",                   Object.Scenario);
	Settings.Insert("Warehouse",                      Object.Warehouse);
	Settings.Insert("PeriodBeginning",               Object.PeriodBeginning);
	Settings.Insert("PeriodEnd",            Object.PeriodEnd);
	Settings.Insert("DemandCalculationModeByPlan", Object.DemandCalculationModeByPlan);
	Settings.Insert("FilterWarehouse",                 FilterWarehouse);
	Settings.Insert("Periodicity",              Periodicity);
	Settings.Insert("Organization",                Object.Organization);
	Settings.Insert("Purpose",                 Object.Purpose);
	
	SaveSettingsAtServer(Settings)
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(Settings)
	
	ObjectKey = "DataProcessor.GenerationOfAssemblyDisassemblyOrdersByPlans";
	Common.CommonSettingsStorageSave(ObjectKey, "Settings", Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.GenerationOfAssemblyDisassemblyOrdersByPlans", "Settings");
	
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		FillPropertyValues(Object, SettingsValue);
		FillPropertyValues(ThisForm, SettingsValue);
		
		If SettingsValue.Property("ReceiptPeriodStart")
			Or SettingsValue.Property("ReceiptPeriodEnds") Then
			Object.DemandCalculationModeByPlan = 1;
			Object.PeriodBeginning = SettingsValue.ReceiptPeriodStart;
			Object.PeriodEnd = SettingsValue.ReceiptPeriodEnds;
		EndIf;
		
		If SettingsValue.Property("OrderPeriodStart_")
			Or SettingsValue.Property("OrderPeriodEnds") Then
			Object.DemandCalculationModeByPlan = 0;
			Object.PeriodBeginning = SettingsValue.OrderPeriodStart_;
			Object.PeriodEnd = SettingsValue.OrderPeriodEnds;
		EndIf;
		
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
	UpdateAtServer();
	If Object.GenerationOfOrders.Count() = 0 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không có kế hoạch đã phê duyệt cho kịch bản %1 tương ứng với bộ lọc thiết lập. Cần thay đổi bộ lọc.';
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
Procedure FillInTheWarehouseCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	SelectedWarehouse = Result;
	If ValueIsFilled(SelectedWarehouse) Then
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.GenerationOfOrders, ArrayOfSelectedRows, Warehouse);
	
	UpdateBuildDateWhenWarehouseChanges(ArrayOfSelectedRows);
	
	Return FilledRows;
	
EndFunction

&AtServer
Procedure UpdateBuildDateWhenWarehouseChanges(StringsList)
	
	If TypeOf(StringsList) = Type("Array") Then
		ModifiedRows = StringsList;
	Else
		ModifiedRows = New Array;
		ModifiedRows.Add(StringsList);
	EndIf; 
	
	StringsToProcess = New Array;
	RowsMap = New Map;
	For Each RowID In ModifiedRows Do
		RowData = Object.GenerationOfOrders.FindByID(RowID);
		StringsToProcess.Add(RowData);
		RowsMap.Insert(RowData.LineNumber, RowData);
	EndDo; 
	
	OrdersTable = Object.GenerationOfOrders.Unload(StringsToProcess);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OrdersTable.LineNumber AS LineNumber,
	|	OrdersTable.Warehouse AS Warehouse,
	|	OrdersTable.Calendar AS Calendar,
	|	OrdersTable.AssemblyPeriodStart AS AssemblyPeriodStart,
	|	OrdersTable.Products AS Products,
	|	OrdersTable.Characteristic AS Characteristic
	|INTO OrdersTable
	|FROM
	|	&OrdersTable AS OrdersTable
	|
	|INDEX BY
	|	Warehouse,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Warehouse          AS Warehouse,
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic
	|INTO TTProducts_1
	|FROM
	|	OrdersTable AS Table
	|;
	|
	|//////////////////////////////////////////////
	|" + InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE") + "
	|;
	|
	|////////////////////////////////////
	|SELECT
	|	OrdersTable.Calendar,
	|	CalendarSchedules.Year,
	|	MAX(CalendarSchedules.DaysCountInScheduleSinceBegOfYear) AS DaysCountInScheduleSinceBegOfYear
	|INTO ChartsNumberOfDaysInPastYear
	|FROM
	|	OrdersTable AS OrdersTable
	|		LEFT JOIN InformationRegister.CalendarSchedules AS CalendarSchedules
	|		ON OrdersTable.Calendar = CalendarSchedules.Calendar
	|			AND (YEAR(OrdersTable.AssemblyPeriodStart) - 1 = CalendarSchedules.Year)
	|
	|GROUP BY
	|	OrdersTable.Calendar,
	|	CalendarSchedules.Year
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.LineNumber AS LineNumber,
	|	ISNULL(Approaches.OrderFulfillmentPeriod, 0) AS DaysBeforeOrdering,
	|	ISNULL(Approaches.ProductionDurationDays, 0) AS AssemblyDisassemblyDurationDays,
	|	OrdersTable.Calendar AS Calendar,
	|	OrdersTable.AssemblyPeriodStart AS AssemblyPeriodStart,
	|	ISNULL(Approaches.Ref, VALUE(Catalog.ProcurementStrategies.EmptyRef)) AS SupplyMethod
	|INTO TableOrdersAndDueDate
	|FROM
	|	OrdersTable AS OrdersTable
	|		LEFT JOIN TTWaysToEnsure AS TableWaysToEnsure
	|		ON TableWaysToEnsure.Products   = OrdersTable.Products
	|		 AND TableWaysToEnsure.Characteristic = OrdersTable.Characteristic
	|		 AND TableWaysToEnsure.Warehouse          = OrdersTable.Warehouse
	|		
	|		LEFT JOIN Catalog.ProcurementStrategies AS Approaches
	|		ON Approaches.Ref = TableWaysToEnsure.ProcurementStrategy
	|		 AND Approaches.SupplyType = VALUE(Enum.SupplyTypes.AssemblyDisassembly)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.LineNumber AS LineNumber,
	|	OrdersTable.DaysBeforeOrdering AS DaysBeforeOrdering,
	|	OrdersTable.AssemblyDisassemblyDurationDays AS AssemblyDisassemblyDurationDays,
	|	CASE
	|		WHEN ScheduleBuildDate.ScheduleDate IS NULL 
	|			THEN DATEADD(OrdersTable.AssemblyPeriodStart, DAY, -OrdersTable.DaysBeforeOrdering)
	|		ELSE ScheduleOrderDate.ScheduleDate
	|	END AS OrderDate,
	|	OrdersTable.SupplyMethod
	|FROM
	|	TableOrdersAndDueDate AS OrdersTable
	|		LEFT JOIN InformationRegister.CalendarSchedules AS ScheduleBuildDate
	|		ON OrdersTable.Calendar = ScheduleBuildDate.Calendar
	|			AND OrdersTable.AssemblyPeriodStart = ScheduleBuildDate.ScheduleDate
	|			AND (YEAR(OrdersTable.AssemblyPeriodStart) = ScheduleBuildDate.Year)
	|		LEFT JOIN ChartsNumberOfDaysInPastYear AS ChartsLastYear
	|		ON (YEAR(OrdersTable.AssemblyPeriodStart) - 1 = ChartsLastYear.Year)
	|			AND (CASE
	|				WHEN NOT ScheduleBuildDate.ScheduleDate IS NULL 
	|						AND ISNULL(ScheduleBuildDate.DaysCountInScheduleSinceBegOfYear, 0) < OrdersTable.DaysBeforeOrdering
	|					THEN TRUE
	|				ELSE FALSE
	|			END)
	|		LEFT JOIN InformationRegister.CalendarSchedules AS ScheduleOrderDate
	|		ON OrdersTable.Calendar = ScheduleOrderDate.Calendar
	|			AND (ScheduleOrderDate.DayAddedToSchedule)
	|			AND (CASE
	|				WHEN NOT ScheduleBuildDate.ScheduleDate IS NULL 
	|						AND ISNULL(ScheduleBuildDate.DaysCountInScheduleSinceBegOfYear, 0) < OrdersTable.DaysBeforeOrdering
	|					THEN YEAR(OrdersTable.AssemblyPeriodStart) - 1 = ScheduleOrderDate.Year
	|				ELSE YEAR(OrdersTable.AssemblyPeriodStart) = ScheduleOrderDate.Year
	|			END)
	|			AND (CASE
	|				WHEN NOT ScheduleBuildDate.ScheduleDate IS NULL 
	|						AND ISNULL(ScheduleBuildDate.DaysCountInScheduleSinceBegOfYear, 0) < OrdersTable.DaysBeforeOrdering
	|					THEN CASE
	|							WHEN ISNULL(ChartsLastYear.DaysCountInScheduleSinceBegOfYear, 0) - (OrdersTable.DaysBeforeOrdering - ISNULL(ScheduleBuildDate.DaysCountInScheduleSinceBegOfYear, 0)) <= 0
	|								THEN ScheduleOrderDate.DaysCountInScheduleSinceBegOfYear = 1
	|							ELSE ISNULL(ChartsLastYear.DaysCountInScheduleSinceBegOfYear, 0) - (OrdersTable.DaysBeforeOrdering - ISNULL(ScheduleBuildDate.DaysCountInScheduleSinceBegOfYear, 0)) = ScheduleOrderDate.DaysCountInScheduleSinceBegOfYear
	|						END
	|				ELSE ISNULL(ScheduleBuildDate.DaysCountInScheduleSinceBegOfYear, 0) - OrdersTable.DaysBeforeOrdering = ScheduleOrderDate.DaysCountInScheduleSinceBegOfYear
	|			END)";
	
	Query.SetParameter("OrdersTable", OrdersTable);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		OrderLine = RowsMap.Get(Selection.LineNumber);
		FillPropertyValues(OrderLine, Selection, "OrderDate, DaysBeforeOrdering, AssemblyDisassemblyDurationDays, SupplyMethod");
	EndDo;
	
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
	
EndProcedure

#EndRegion

#Region ProceduresForObtainingPlansAndOrders

&AtServer
Function ListOfPlansByLine(RowKey)

	Query = New Query();
	Query.Text = 
	"SELECT ALLOWED
	|	SUM(AssemblyPlansDisassemblyRevolutions.ToOrderTurnover) AS Count,
	|	AssemblyPlansDisassemblyRevolutions.Recorder AS Document,
	|	DocAssemblyDisassemblyPlan.PointInTime AS PointInTime,
	|	DocAssemblyDisassemblyPlan.Date AS DocumentDate,
	|	DocAssemblyDisassemblyPlan.Number AS DocumentNumber
	|FROM
	|	AccumulationRegister.AssemblyDisassemblyPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&PeriodEnding,
	|			Recorder,
	|			Scenario = &Scenario
	|				AND BusinessOperation = &BusinessOperation
	|				AND Warehouse = &Warehouse
	|				AND Products = &Products
	|				AND Characteristic = &Characteristic
	|				AND Purpose = &Purpose
	|				AND ProductKit = &ProductKit) AS AssemblyPlansDisassemblyRevolutions
	|		INNER JOIN Document.AssemblyDisassemblyPlan AS DocAssemblyDisassemblyPlan
	|		ON AssemblyPlansDisassemblyRevolutions.Recorder = DocAssemblyDisassemblyPlan.Ref
	|
	|GROUP BY
	|	AssemblyPlansDisassemblyRevolutions.Recorder,
	|	DocAssemblyDisassemblyPlan.PointInTime,
	|	DocAssemblyDisassemblyPlan.Date,
	|	DocAssemblyDisassemblyPlan.Number
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
	
	Query.SetParameter("Scenario", Object.Scenario);
	Query.SetParameter("Warehouse",		RowKey.Warehouse);
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Purpose", RowKey.Purpose);
	Query.SetParameter("Products", RowKey.Products);
	Query.SetParameter("Characteristic", RowKey.Characteristic);
	Query.SetParameter("ProductKit", RowKey.ProductKit);
	Query.SetParameter("BusinessOperation", RowKey.BusinessOperation);
	
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

	Query = New Query();
	Query.Text = 
	"SELECT ALLOWED
	|	SUM(ByAssemblyDisassemblyOrder.Count) AS Count,
	|	ByAssemblyDisassemblyOrder.Ref AS Document,
	|	ByAssemblyDisassemblyOrder.Date AS DocumentDate,
	|	ByAssemblyDisassemblyOrder.Number AS DocumentNumber
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
	|WHERE
	|	CASE
	|			WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN NOT ByAssemblyDisassemblyOrder.Warehouse IN (&WarehousesForWhichThereArePlans)
	|			ELSE ByAssemblyDisassemblyOrder.Warehouse = &Warehouse
	|		END
	|	AND ByAssemblyDisassemblyOrder.ProductKit = &ProductKit
	|	AND ByAssemblyDisassemblyOrder.Products = &Products
	|	AND ByAssemblyDisassemblyOrder.Characteristic = &Characteristic
	|	AND CASE
	|		WHEN &PlanningByAssignments AND &Purpose<>VALUE(Catalog.Assignments.EmptyRef)
	|			THEN ByAssemblyDisassemblyOrder.Purpose = &Purpose
	|		ELSE TRUE
	|	END
	|	AND ByAssemblyDisassemblyOrder.BusinessOperation = &BusinessOperation
	|	AND ByAssemblyDisassemblyOrder.Count <> 0
	|	AND ByAssemblyDisassemblyOrder.Posted
	|	AND ByAssemblyDisassemblyOrder.AssemblyDisassemblyEnd BETWEEN &AssemblyPeriodStart AND &EndOfDayBuildEndDate
	|
	|GROUP BY
	|	ByAssemblyDisassemblyOrder.Ref,
	|	ByAssemblyDisassemblyOrder.Date,
	|	ByAssemblyDisassemblyOrder.Number
	|
	|ORDER BY
	|	ByAssemblyDisassemblyOrder.PointInTime";
	
	For Each Property In RowKey Do
		
		Query.SetParameter(Property.Key, Property.Value);
		
	EndDo;
	
	WarehousesForWhichThereArePlans = New Array;
	If Not ValueIsFilled(RowKey.Warehouse) Then

		RowKey.Delete("Warehouse");
		RowKey.Delete("EndOfDayBuildEndDate");
		RowKey.Delete("AssemblyPeriodStart");
		RowKey.Insert("EditWarehouse", False);
		
		FoundRows = TableOrderGeneration.FindRows(RowKey);
		For Each String In FoundRows Do
			WarehousesForWhichThereArePlans.Add(String.Warehouse);
		EndDo;
		
	EndIf;
	
	Query.SetParameter("WarehousesForWhichThereArePlans", WarehousesForWhichThereArePlans);
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
	Query.SetParameter("Warehouse",		RowKey.Warehouse);
	Query.SetParameter("FilterWarehouse", ValueIsFilled(RowKey.Warehouse));
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Purpose", RowKey.Purpose);
	Query.SetParameter("Products", RowKey.Products);
	Query.SetParameter("Characteristic", RowKey.Characteristic);
	Query.SetParameter("ProductKit", RowKey.ProductKit);
	Query.SetParameter("BusinessOperation", RowKey.BusinessOperation);
	
	ResultTable2 = Query.Execute().Unload();
	
	DocumentsList = New ValueList();
	For Each String In ResultTable2 Do
		
		If Not ValueIsFilled(RowKey.Warehouse) 
			And ValueIsFilled(String.Warehouse) Then
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
		OpenForm("Document.AssemblyDisassemblyPlan.ObjectForm", FormParameters, ThisForm);
		
	EndIf;

EndProcedure 

&AtClient
Procedure SelectingOrderDocumentFromList(SelectionResult, AdditionalParameters) Export 

	If Not SelectionResult = Undefined Then 
		
		Document = SelectionResult.Value;
		FormParameters = New Structure("Key", Document);
		OpenForm("Document.ByAssemblyDisassemblyOrder.ObjectForm", FormParameters, ThisForm);
		
	EndIf;

EndProcedure 

#EndRegion

#Region CreateDeleteOrders

&AtServer
Function CreateOrdersOnServer()
	
	If Not CheckFilling() Then
		Return False;
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
								|%2 sebeplerinden dolayı %1 belgeyi kaydetmek mümkün değil'");
	FillingErrorText = NStr("vi = '%1 không thể kết chuyển theo nguyên nhân điền sai.';
							|ru = '%1 невозможно провести по причине некорректного заполнения.';
							|en = 'Cannot post %1. Reason: the document is filled incorrectly.'; fa = 'Cannot post %1. Reason: the document is filled incorrectly.';
							|it = '%1 non è possibile registrare a causa della compilazione non corretta.';
							|pl = '%1 niemożliwe jest zatwierdzenie z powodu niepoprawnego wypełnienia.';
							|tr = '%1 doğru olmayan doldurmadan dolayı kaydetmek mümkün değil.'");
	
	SupplyMethods = New Map;
	
	For Each OrderDataLine In Object.GenerationOfOrders Do
		If Not OrderDataLine.SelectToOrder Or OrderDataLine.NumberOfPackages = 0 Then
			Continue;
		EndIf;
		
		FillingData = New Structure("BusinessOperation,Warehouse,Products,Characteristic,Purpose,ProductKit, Count,
			|NumberOfPackages, Package, AssemblyDisassemblyStart, AssemblyDisassemblyEnd, AssemblyDisassemblyDurationDays");
		
		FillingData.Insert("AssemblyDisassemblyDurationDays", OrderDataLine.AssemblyDisassemblyDurationDays);
		
		DocumentObject = Documents.ByAssemblyDisassemblyOrder.CreateDocument();
		DocumentObject.Date = CurrentSessionDate();
		
		DocumentObject.Comment = NStr("vi = 'Được lập tự động bằng bộ xử lý ""Lập đơn đặt hàng đóng bộ (tách bộ) theo kế hoạch"".';
										|ru = 'Сформирован автоматически обработкой ""Формирование заказов на сборку (разборку) по плану"".';
										|en = 'Generated automatically using the ""Convert plan to kitting orders"" data processor.'; fa = 'Generated automatically using the ""Convert plan to kitting orders"" data processor.';
										|it = 'Formato automaticamente dall''elaborazione ""Formazione di ordini di assemblaggio (disassemblaggio) secondo il piano"".';
										|pl = 'Utworzono automatycznie procedurą przetwarzania ""Формирование заказов на сборку (разборку) по плану"".';
										|tr = '""Plana göre montaj(demontaj) siparişlerinin oluşturulması"" işlenerek otomatik olarak oluşturuldu.'");
		
		If ValueIsFilled(OrderDataLine.SupplyMethod) Then
		
			WayParameters = SupplyMethods.Get(OrderDataLine.SupplyMethod);
			If WayParameters = Undefined Then
			
				WayParameters = Common.ObjectAttributesValues(OrderDataLine.SupplyMethod, "Organization, Department, ProductionDurationDays");
				SupplyMethods.Insert(OrderDataLine.SupplyMethod, WayParameters);
				
			EndIf; 
			
			If ValueIsFilled(WayParameters.ProductionDurationDays) Then
				FillingData.AssemblyDisassemblyDurationDays = WayParameters.ProductionDurationDays;
			EndIf; 
			
			FillingData.Insert("Organization", WayParameters.Organization);
			FillingData.Insert("Department", WayParameters.Department);
			
		EndIf; 
		
		If Not GetFunctionalOption("UseStatusesOfAssemblyOrders") Then
			DocumentObject.Status = Enums.InternalOrderStatuses.Closed;
		Else
			DocumentObject.Status = Enums.InternalOrderStatuses.ForCompletion;
		EndIf;
		
		FillPropertyValues(FillingData, OrderDataLine);
		
		FillingData.AssemblyDisassemblyStart = Max(OrderDataLine.AssemblyStartDate,CurrentSessionDate);
		FillingData.AssemblyDisassemblyEnd = FillingData.AssemblyDisassemblyStart + FillingData.AssemblyDisassemblyDurationDays*86400;
		
		DocumentObject.Fill(FillingData);
		
		If OrderDataLine.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
			For Each String In DocumentObject.Goods Do
				If ValueIsFilled(OrderDataLine.Purpose) Then
					String.SupplyOption = Enums.SupplyOptions.ToSupply;
					String.WithAssignment = True;
				EndIf;
			EndDo;
		Else
			If ValueIsFilled(OrderDataLine.Purpose) Then
				DocumentObject.SupplyOption = Enums.SupplyOptions.ToSupply;
				DocumentObject.WithAssignment = True;
				DocumentObject.LineOfBusiness = OrderDataLine.LineOfBusiness;
				For Each String In DocumentObject.Goods Do
					String.Purpose = OrderDataLine.Purpose;
				EndDo;
			EndIf;
		EndIf;
			
		If ValueIsFilled(Object.Organization) Then
			DocumentObject.Organization = Object.Organization;
		EndIf;
		
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
			
			WriteLogEvent(NStr("vi = 'Lập đơn hàng đóng bộ (tách bộ) theo kế hoạch';
								|ru = 'Формирование заказов на сборку (разборку) по плану';
								|en = 'Convert plan to kitting orders'; fa = 'تبدیل برنامه به سفارش‌های کیت‌سازی';
								|it = 'La formazione di ordini di assemblaggio (smontaggio) al piano';
								|pl = 'Tworzenie zamówień na montaż (demontaż) wg planu';
								|tr = 'Plana göre montaj (demontaj) siparişlerinin oluşturulması'", CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
				
			ErrorText = ErrorDescription();
			CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(TextOfRecordingError, String(DocumentObject.Ref), ErrorText),
				DocumentObject);
			
		EndTry; 
		
	EndDo; 
	
	Return True;
EndFunction

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
	
	Query = GetRequestWithDataLayoutSelections(AddressOfDataCompositionSchema, SettingsComposer);
		
	Query.SetParameter("Scenario",	Object.Scenario);
	Query.SetParameter("Warehouse",		Object.Warehouse);
	Query.SetParameter("FilterWarehouse",	FilterWarehouse);
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments);
	Query.SetParameter("Purpose", Object.Purpose);
	Query.SetParameter("FilterByAssignment", ValueIsFilled(Object.Purpose));
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Table = Result.Unload();
		TableOrderGeneration.Load(Table);
		If FilterWarehouse Then
			TableFormationOfOrdersWithSelection = Table.Copy(New Structure("Warehouse", Object.Warehouse));
		Else
			TableFormationOfOrdersWithSelection = Table;
		EndIf;
		
		Object.GenerationOfOrders.Load(TableFormationOfOrdersWithSelection);
		
		For Each OrderLine In Object.GenerationOfOrders Do
			OrderLine.Period.StartDate    = OrderLine.AssemblyPeriodStart;
			OrderLine.Period.EndDate = OrderLine.AssemblyEndDate;
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
				NStr("vi = 'Đơn hàng đóng bộ (tách bộ) đã thay đổi. Bạn muốn cập nhật dữ liệu? Khi cập nhật, các dòng sẽ bị xóa.';
					|ru = 'Заказы на сборку(разборку) были изменены. Хотите обновить данные? При обновлении строки будут очищены.';
					|en = 'Kitting orders were changed. Do you want to update the data? Lines will be cleared during update.'; fa = 'Kitting orders were changed. Do you want to update the data? Lines will be cleared during update.';
					|it = 'Ordini di assemblaggio (disassemblaggio) sono stati modificati. Volete aggiornare i dati? Durante l''aggiornamento le righe saranno cancellate.';
					|pl = 'Zamówienia na montaż (demontaż) zostały zmienione. Chcesz aktualizować dane? Podczas aktualizacji wiersze zostaną oczyszczone.';
					|tr = 'Montaj (demontaj) siparişleri değiştirildi. Verileri güncellemek ister misiniz?Satırlar güncellemek için silinecektir.'"), 
				QuestionDialogMode.YesNo,
				,
				,
				NStr("vi = 'Lập đơn hàng đóng bộ (tách bộ) theo kế hoạch';
					|ru = 'Формирование заказов на сборку разборку по плану';
					|en = 'Generation of kitting reverse kitting orders according to plan'; fa = 'Generation of kitting reverse kitting orders according to plan';
					|it = 'La formazione di ordini di assemblaggio disassemblaggio secondo il piano';
					|pl = 'Tworzenie zamówień na montaż demontaż według planu';
					|tr = 'Plana göre montaj (demontaj) siparişlerinin oluşturulması'"));
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
	|	TableOrderGeneration.Warehouse AS Warehouse,
	|	TableOrderGeneration.Products AS Products,
	|	TableOrderGeneration.Characteristic AS Characteristic,
	|	TableOrderGeneration.BusinessOperation AS BusinessOperation,
	|	TableOrderGeneration.ProductKit AS ProductKit,
	|	TableOrderGeneration.AssemblyEndDate AS AssemblyEndDate,
	|	TableOrderGeneration.AssemblyStartDate AS AssemblyStartDate,
	|	TableOrderGeneration.EditWarehouse AS EditWarehouse
	|INTO TableOrderGeneration
	|FROM
	|	&TableOrderGeneration AS TableOrderGeneration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ByAssemblyDisassemblyOrder.Ref AS Document
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
	|	INNER JOIN TableOrderGeneration AS TableOrderGeneration
	|	ON ByAssemblyDisassemblyOrder.Products = TableOrderGeneration.Products
	|		AND ByAssemblyDisassemblyOrder.Characteristic = TableOrderGeneration.Characteristic
	|		AND ByAssemblyDisassemblyOrder.ProductKit = TableOrderGeneration.ProductKit
	|		AND ByAssemblyDisassemblyOrder.BusinessOperation = TableOrderGeneration.BusinessOperation
	|WHERE
	|	CASE
	|		WHEN TableOrderGeneration.EditWarehouse
	|			THEN TRUE
	|		ELSE TableOrderGeneration.Warehouse = ByAssemblyDisassemblyOrder.Warehouse
	|	END
	|	AND ByAssemblyDisassemblyOrder.AssemblyDisassemblyEnd BETWEEN TableOrderGeneration.AssemblyStartDate AND TableOrderGeneration.AssemblyEndDate
	|	AND ByAssemblyDisassemblyOrder.Posted
	|	AND ByAssemblyDisassemblyOrder.Ref IN(&DocumentListForUpdate)";
	
	Query.SetParameter("DocumentListForUpdate", DocumentListForUpdate);
	Query.SetParameter("TableOrderGeneration", TableOrderGeneration.Unload());
	
	OrdersAreNotIncludedInPlans = Query.Execute().IsEmpty();
	DocumentListForUpdate.Clear();
	
	Return Not OrdersAreNotIncludedInPlans;
	
EndFunction

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
	
EndProcedure

&AtServer
Function GetWarehousesByPlansBySelectedLines(RowsIDs)
	Table = TableOrderGeneration.Unload();
	TableSelectedRows = Table.CopyColumns();
	
	For Each Id In RowsIDs Do
		NewRow = TableSelectedRows.Add();
		FillPropertyValues(NewRow, Object.GenerationOfOrders.FindByID(Id));
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	TableSelectedRows.Products AS Products,
	|	TableSelectedRows.Characteristic AS Characteristic,
	|	TableSelectedRows.ProductKit AS ProductKit,
	|	TableSelectedRows.BusinessOperation AS BusinessOperation
	|INTO TableSelectedRows
	|FROM
	|	&TableSelectedRows AS TableSelectedRows
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOrderGeneration.Warehouse AS Warehouse,
	|	TableOrderGeneration.Products AS Products,
	|	TableOrderGeneration.Characteristic AS Characteristic,
	|	TableOrderGeneration.ProductKit AS ProductKit,
	|	TableOrderGeneration.BusinessOperation AS BusinessOperation,
	|	TableOrderGeneration.EditWarehouse AS EditWarehouse
	|INTO TableOrderGeneration
	|FROM
	|	&TableOrderGeneration AS TableOrderGeneration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOrderGeneration.Warehouse
	|FROM
	|	TableOrderGeneration AS TableOrderGeneration
	|		INNER JOIN TableSelectedRows AS TableSelectedRows
	|		ON TableOrderGeneration.Products = TableSelectedRows.Products
	|			AND TableOrderGeneration.Characteristic = TableSelectedRows.Characteristic
	|			AND TableOrderGeneration.ProductKit = TableSelectedRows.ProductKit
	|			AND TableOrderGeneration.BusinessOperation = TableSelectedRows.BusinessOperation
	|			AND (TableOrderGeneration.EditWarehouse = FALSE)";
	
	Query.SetParameter("TableOrderGeneration",Table);
	Query.SetParameter("TableSelectedRows",TableSelectedRows);
	Return Query.Execute().Unload().UnloadColumn("Warehouse");
	
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
