
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseGoodsTransfer") Then
		
		MessageText = NStr("vi = 'Trong hệ thống không sử dụng điều chuyển hàng hóa, không sử dụng chỗ làm việc.';
							|ru = 'В системе не используются перемещения товаров, рабочее место недоступно.';
							|en = 'Goods transfers are not used in the system. The workplace is unavailable.'; fa = 'Goods transfers are not used in the system. The workplace is unavailable.';
							|it = 'В системе не используются перемещения товаров, рабочее место недоступно.';
							|pl = 'Goods transfers are not used in the system. The workplace is unavailable.';
							|tr = 'Sistem mal hareketlerini kullanmıyor, çalışma alanı mevcut değil.'");
		Common.MessageToUser(MessageText,,,, Cancel);
		Return;
	
	EndIf;
	
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then

		MessageText = NStr("vi = 'Trong hệ thống không sử dụng cấu trúc động các đơn hàng sản xuất, không sử dụng chỗ làm việc.';
							|ru = 'В системе не используется динамическая структура заказов на производство, рабочее место недоступно.';
							|en = 'The system does not use a dynamic production order structure, the workplace is not available.'; fa = 'The system does not use a dynamic production order structure, the workplace is not available.';
							|it = 'В системе не используется динамическая структура заказов на производство, рабочее место недоступно.';
							|pl = 'The system does not use a dynamic production order structure, the workplace is not available.';
							|tr = 'Sistemde dinamik üretim emri yapısı kullanmamaktadır, çalışma alanı mevcut değil.'");
		Common.MessageToUser(MessageText,,,, Cancel);
		Return;

	EndIf;
	
	OptionOrdersToMoveIsAvailable = Constants.ControlBalanceOfGoodsToBeReservedUponReceipt.Get();
	
	InitializeSettingsComposer();
	
	RestoreSettings();
	
	FiltersStructure = Undefined;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		
		If FiltersStructure.Property("Products", FilterRemainingGoodsByShelfLives) Then
			ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Products", FilterRemainingGoodsByShelfLives);
		EndIf;
		
		If FiltersStructure.Property("ProductionOrder", FilterByOrder) Then
			ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "ProductionOrder", FilterByOrder);
		EndIf;
		
		If FiltersStructure.Property("BillOfMaterials", FilterByBillOfMaterials) Then
			ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "BillOfMaterials", FilterByBillOfMaterials);
		EndIf;
		
		SelectionStructureIsFilledInAccordingToPassedParameters = True;
		
	EndIf;
	
	InstallAssistantPages(ThisForm, "StepSelection");
	
	SelectedModeColor = StyleColors.GrayTextColor1;
	UnselectedModeColor = StyleColors.HyperlinkColor;
	
	AccessStructure = DataProcessors.GenerateProductionOrderRegisterRecords.AccessStructure();
	TransferOrdersAreUsed = AccessStructure.MoveOrderIsAvailable;
	
	CurrentDate = CurrentSessionDate();
	Object.DateOfShipment = CurrentDate;
	
	SetHeadersOfCartColumnsByWarehouse();
	CustomizeFormElements();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Object.RegistrationOption) Or Not OptionOrdersToMoveIsAvailable Then
		Object.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringTransferDocuments.InventoryTransfer");
	EndIf;
	
	If ReflectLayoutSelectionInSimpleSelections() Then
		
		// no additional actions are required in this configuration
		
	Else
		
		LoadDefaultSelectionSettings();
		
	EndIf;
	
	UpdateSettingsByDesignOption(ThisObject);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	If FormattedStringURL = "FillInNomenclaturePlan" Then
		
		StandardProcessing = False;
		SampleRestriction   = False;
		
		FillInNomenclaturePlanOnServer();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

#Region StepSelection

&AtClient
Procedure SelectionByWarehouseRecipientOnChange(Item)
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "DestinationWarehouse", SelectionByWarehouseRecipient);
	
EndProcedure

&AtClient
Procedure SelectionByWarehouseSenderOnChange(Item)
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "SourceWarehouse", SelectionByWarehouseSender);
	
EndProcedure

&AtClient
Procedure FilterByLineOfBusinessOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "LineOfBusiness", FilterByLineOfBusiness);

EndProcedure

&AtClient
Procedure FilterByAssignmentOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Purpose", FilterByAssignment);

EndProcedure

&AtClient
Procedure FilterRemainingGoodsByShelfLivesOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Products", FilterRemainingGoodsByShelfLives);

EndProcedure

&AtClient
Procedure FilterByOrderOnChange(Item)
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "ProductionOrder", FilterByOrder);

EndProcedure

&AtClient
Procedure FilterOnlyRunningLotsOnChange(Item)
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "OnlyRunningBatches", FilterOnlyRunningBatches,, Not FilterOnlyRunningBatches);
	
EndProcedure

&AtClient
Procedure DemandsBeforeDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(
		SettingsComposer, "EndDate", Object.DemandsBeforeDate, DataCompositionComparisonType.LessOrEqual);
	
EndProcedure

&AtClient
Procedure RegistrationOptionOnChange(Item)
	
	UpdateSettingsByDesignOption(ThisObject);
	
EndProcedure

#EndRegion

#Region StepPlan

&AtClient
Procedure PlanSelection(Item, RowSelected, Field, StandardProcessing)
	
	FieldName = StrReplace(Field.Name, "Plan", "");
	
	If StrFind("Products,Characteristic,Purpose,DestinationWarehouse,SourceWarehouse,ProductionOrder,BillOfMaterials,Product", FieldName) > 0 Then
		
		StandardProcessing = False;
		
		ShowValue(, Item.CurrentData[FieldName]);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanOnActivateRow(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.GenerateProductionOrderRegisterRecords.Form.Item.Plan.OnActivateRow");
	
EndProcedure

&AtClient
Procedure PlanMarkOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.GenerateProductionOrderRegisterRecords.Form.Item.Plan.WhenChangingQuantity");
	
	CurrentData = Items.Plan.CurrentData;
	
	ZoomRatio = ?(CurrentData.Mark, 1, -1);
	ChangesRow = ShoppingCartByWarehousesChanges.Add();
	FillPropertyValues(ChangesRow, CurrentData);
	ChangesRow.Weight = ZoomRatio * CurrentData.ForTransfer * CurrentData.UnitWeight;
	ChangesRow.VolumeM3 = ZoomRatio * CurrentData.ForTransfer * CurrentData.UnitVolume;
	ChangesRow.ThereAreRowsWithZeroWeight = CurrentData.UnitWeight = 0;
	ChangesRow.ThereAreLinesWithZeroVolume = CurrentData.UnitVolume = 0;
	ChangesRow.FrequencyOfLines = ZoomRatio;
	UpdateShoppingCartByWarehouse();
	
EndProcedure

&AtClient
Procedure PlanForTransferOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.GenerateProductionOrderRegisterRecords.Form.Item.Plan.WhenChangingQuantity");
	
	CurrentData = Items.Plan.CurrentData;
	MarkBeforeChange = CurrentData.Mark;
	CurrentData.Mark = CurrentData.ForTransfer > 0;
	UpdateCart = True;
	
	If Not MarkBeforeChange And CurrentData.Mark Then
		CurrentData.ToMoveBeforeChange = 0;
	ElsIf Not MarkBeforeChange And Not CurrentData.Mark Then
		UpdateCart = False;
	EndIf;
	
	If CurrentData.ForTransfer <> CurrentData.ToMoveBeforeChange
	   And UpdateCart Then
	
		Diff = CurrentData.ForTransfer - CurrentData.ToMoveBeforeChange;
		ChangesRow = ShoppingCartByWarehousesChanges.Add();
		FillPropertyValues(ChangesRow, CurrentData);
		ChangesRow.Weight = Diff * CurrentData.UnitWeight;
		ChangesRow.VolumeM3 = Diff * CurrentData.UnitVolume;
		ChangesRow.ThereAreRowsWithZeroWeight = CurrentData.UnitWeight = 0;
		ChangesRow.ThereAreLinesWithZeroVolume = CurrentData.UnitVolume = 0;
		
		If Not CurrentData.Mark Then
			ChangesRow.FrequencyOfLines = -1;
		ElsIf CurrentData.ForTransfer > 0
			    And Not MarkBeforeChange Then
			ChangesRow.FrequencyOfLines = 1;
		Else
			ChangesRow.FrequencyOfLines = 0;
		EndIf;
		
		CurrentData.ToMoveBeforeChange = CurrentData.ForTransfer;
		UpdateShoppingCartByWarehouse();
	
	EndIf;
	
EndProcedure

#EndRegion

#Region StepResultOfFormation

&AtClient
Procedure ListDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(Undefined, Items.ListDocuments.CurrentData.Ref);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

#Region Filters

&AtClient
Procedure RestoreDefaultSettings(Command)
	
	LoadDefaultSelectionSettings();
	
EndProcedure

#EndRegion

#Region ItemPlan

&AtClient
Procedure SelectItemPlanCheckBoxes(Command)
	
	ChangeCheckboxesInSelectedLines(True, Items.Plan.SelectedRows, "Plan");
	UpdateShoppingCartByWarehouse();
	
EndProcedure

&AtClient
Procedure UncheckItemPlanCheckboxes(Command)
	
	ChangeCheckboxesInSelectedLines(False, Items.Plan.SelectedRows, "Plan");
	UpdateShoppingCartByWarehouse();
	
EndProcedure

&AtClient
Procedure OnlyCheckedOnChange(Item)
	
	SetAdditionalSelectionOfLinesNomenclaturePlan(ThisForm);

EndProcedure

&AtClient
Procedure HyperlinkAllProductsClick(Item)
	
	FilterProvidesCurValue = SoftwareFilterIsDisabled();
	
	SetAdditionalSelectionOfLinesNomenclaturePlan(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "FilterSoftware");
	
EndProcedure

&AtClient
Procedure HyperlinkProvidedClick(Item)
	
	FilterProvidesCurValue = FilterSecurityIsProvided();
	
	SetAdditionalSelectionOfLinesNomenclaturePlan(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "FilterSoftware");
	
EndProcedure

&AtClient
Procedure ReReadNomenclaturePlan(Command)
	
	ReReadNomenclaturePlanOnServer();
	UpdateShoppingCartByWarehouse();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CreatedDocuments

&AtClient
Procedure UndoPosting(Command)
	
	WriteAtClient(Command);
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	WriteAtClient(Command);
	
EndProcedure

&AtClient
Procedure MarkToDelete(Command)
	
	WriteAtClient(Command);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfMaterialTransfersShipped(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfMaterialTransfersAccepted(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfProductMovementsShipped(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfProductMovementsAccepted(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

#EndRegion

#Region Steps

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	
	If Items.WizardPages.CurrentPage = Items.StepSelection Then
		
		Cancel = False;
		
		If Object.DateOfShipment < CurrentDate
		   And Object.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringTransferDocuments.TransferOrder") Then
		
			MessageText = NStr("vi = 'Ngày giao hàng không cần nhỏ hơn ngày hiện tại';
								|ru = 'Дата отгрузки не должна быть меньше текущей даты';
								|en = 'The shipment date cannot be earlier than the current date'; fa = 'The shipment date cannot be earlier than the current date';
								|it = 'Дата отгрузки не должна быть меньше текущей даты';
								|pl = 'The shipment date cannot be earlier than the current date';
								|tr = 'Sevkiyat tarihi güncel tarihten daha az olmamalıdır'");
			Field = "Object.DateOfShipment";
			CommonClient.MessageToUser(MessageText,, Field,, Cancel);
		
		EndIf;
		
		If Not Cancel Then
		
			GoToNomenclaturePlanStepOnClient();
		
		EndIf;
		
	ElsIf Items.WizardPages.CurrentPage = Items.StepNomenclaturePlan Then
	
		GoToGenerationResultStepOnClient();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)

	ClearMessages();

	If Items.WizardPages.CurrentPage = Items.StepResultOfFormation Then
		
		GoBackToNomenclaturePlanStepOnClient();
		
	ElsIf Items.WizardPages.CurrentPage = Items.StepNomenclaturePlan Then
		
		GoBackToSelectionsStepOnClient();

	ElsIf Items.WizardPages.CurrentPage = Items.StepSelection Then
	
		Return;
		
	EndIf;

EndProcedure

&AtClient
Procedure ContinueWithOtherFilters(Command)
	
	ClearMessages();
	ContinueWithOtherSelectionsOnServer();

EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Steps

#Region Filters

&AtClient
Procedure GoBackToSelectionsStepOnClient()
	
	Object.Plan.Clear();
	SetHyperlinkTextProvided();
	Totals.Clear();
	
	InstallAssistantPages(ThisForm, "StepSelection");
	
EndProcedure

#EndRegion

#Region ItemPlan

&AtClient
Procedure GoToNomenclaturePlanStepOnClient() 
	
	SampleRestriction = True;
	ShoppingCartByWarehouse.Clear();
	ShoppingCartByWarehousesChanges.Clear();
	
	FillInNomenclaturePlanOnServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	Else
		
		InstallAssistantPages(ThisForm, "StepNomenclaturePlan");
		
	EndIf;
	
	UpdateShoppingCartByWarehouse();
	
EndProcedure

&AtClient
Procedure GoBackToNomenclaturePlanStepOnClient()
	
	If CreatedObjects.Count() <> 0 Then
		
		Cancel = False;
		Delete_CreatedObjects(Cancel);
		
		If Not Cancel Then
			
			CreatedObjects.Clear();
			
			ShowUserNotification(
				NStr("vi = 'Xóa các đối tượng';
					|ru = 'Удаление объектов';
					|en = 'Delete objects'; fa = 'Delete objects';
					|it = 'Eliminazione oggetti';
					|pl = 'Usunięcie obiektów';
					|tr = 'Nesnelerin silinmesi'"),
				,
				NStr("vi = 'Đặt dấu xóa các đối tượng đã tạo.';
					|ru = 'Сформированные объекты помечены на удаление.';
					|en = 'Generated objects are marked for deletion.'; fa = 'Generated objects are marked for deletion.';
					|it = 'Oggetti creati contrassegnati per l''eliminazione.';
					|pl = 'Utworzone obiekty są zaznaczone do usunięcia.';
					|tr = 'Oluşturulan nesneler silinmek üzere işaretlendi.'"));
			
			InstallAssistantPages(ThisForm, "StepNomenclaturePlan");
			
		EndIf;
		
	Else
		InstallAssistantPages(ThisForm, "StepNomenclaturePlan");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInNomenclaturePlanOnServer()
	
	If ShouldSaveSettings And Not SelectionStructureIsFilledInAccordingToPassedParameters Then
		SaveSelectionComposerSettings();
	EndIf;
	
	CancelLongRunningOperation();
	
	If Object.RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder Then
		DateOfShipment = Object.DateOfShipment;
	Else
		DateOfShipment = Date(1, 1, 1);
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Settings", SettingsComposer.GetSettings());
	ProcedureParameters.Insert("DateOfShipment", DateOfShipment);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo chứng từ điều chuyển: điền kế hoạch theo mặt hàng';
														|ru = 'Формирование перемещений: заполнение номенклатурного плана';
														|en = 'Transfer generation: item plan filling'; fa = 'Transfer generation: item plan filling';
														|it = 'Creazione spostamenti: compilazione piano di nomenclatura';
														|pl = 'Rejestracja przeniesień: wypełnienie planu produktów';
														|tr = 'Transferin düzenlenmesi: Öğe planının doldurulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.GenerateProductionOrderRegisterRecords.GetItemPlanOnHold",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "FillOutNomenclaturePlanOnHoldCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		FillOutNomenclaturePlanOnHold(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillOutNomenclaturePlanOnHoldCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		FillOutNomenclaturePlanOnHold(Result);
		UpdateShoppingCartByWarehouse();
		InstallAssistantPages(ThisForm, "StepNomenclaturePlan");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOutNomenclaturePlanOnHold(Result)
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		Object.Plan.Load(FillingData);
		InitializeChangesToShoppingCartByWarehouse(FillingData);
		
		FilterProvidesCurValue = ?(FillingData.Find(True, "SupplyIsAvailable") <> Undefined,
			FilterSecurityIsProvided(), SoftwareFilterIsDisabled());
		
		SetHyperlinkTextProvided();
		SetAdditionalSelectionOfLinesNomenclaturePlan(ThisObject);
		ConfigureDependentFormElements(ThisObject, "FilterSoftware");
		
	Else
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReReadNomenclaturePlanOnServer()
	
	Object.Plan.Clear();
	SetHyperlinkTextProvided();
	Totals.Clear();
	ShoppingCartByWarehouse.Clear();
	ShoppingCartByWarehousesChanges.Clear();
	
	FillInNomenclaturePlanOnServer();
	
EndProcedure

&AtClientAtServerNoContext
Function SetAdditionalSelectionOfLinesNomenclaturePlan(Form)
	
	FilterStructure1 = New Structure();
	
	If Form.OnlyChecked Then
		FilterStructure1.Insert("Mark", True);
	EndIf;
	
	If Not Form.FilterProvidesCurValue = SoftwareFilterIsDisabled() Then
		FilterStructure1.Insert("SupplyIsAvailable", Form.FilterProvidesCurValue = FilterSecurityIsProvided());
	EndIf;
	
	If ValueIsFilled(FilterStructure1) Then
		Form.Items.Plan.RowFilter = New FixedStructure(FilterStructure1);
	Else
		Form.Items.Plan.RowFilter = Undefined;
	EndIf;
	
EndFunction

&AtServer
Function SetHyperlinkTextProvided()
	
	RowsCount = Object.Plan.Count();
	
	If RowsCount > 0 Then
		QuantityIsProvided   = Object.Plan.FindRows(New Structure("SupplyIsAvailable", True)).Count();
		QuantityIsNotSupplied = RowsCount - QuantityIsProvided;
	Else
		QuantityIsProvided   = 0;
		QuantityIsNotSupplied = 0;
	EndIf;
	
	Items.HyperlinkAllProducts.Title   = NStr("vi = 'Tất cả vị trí';
												|ru = 'Все позиции';
												|en = 'All items'; fa = 'همه اقلام';
												|it = 'Tutte le posizioni';
												|pl = 'Wszystkie pozycje';
												|tr = 'Tüm pozisyonlar'");
	Items.HyperlinkProvided.Title   = StrTemplate(NStr("vi = 'Đã đảm bảo (%1)';
														|ru = 'Обеспечено (%1)';
														|en = 'Supplied (%1)'; fa = 'Supplied (%1)';
														|it = 'Fornito (%1)';
														|pl = 'Zaopatrzono (%1)';
														|tr = 'Temin edildi (%1)'"), Format(QuantityIsProvided, "ND=3; NZ=; NG="));

EndFunction

&AtClientAtServerNoContext
Function SoftwareFilterIsDisabled()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function FilterSecurityIsProvided()
	
	Return 1;
	
EndFunction

#EndRegion

#Region ResultOfFormation

&AtClient
Procedure GoToGenerationResultStepOnClient()
	
	ClearMessages();
	CreateDocumentsOnServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateDocumentsOnServer()
	
	OptionIsActive = Constants.ControlBalanceOfGoodsToBeReservedUponReceipt.Get();
	
	If Object.RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder
	   And Not OptionIsActive Then
		
		MessageText = NStr("vi = 'Để lập chứng từ ""Đơn hàng điều chuyển nội bộ"" cần bật tùy chọn ""Kiểm soát vật tư hàng hóa phải được dự phòng theo mức độ tiếp nhận""';
							|ru = 'Для формирования документов ""Заказ на перемещение"" должна быть включена опция ""Контролировать запасы товаров, подлежащих резервированию по мере поступления""';
							|en = 'To generate the ""Transfer order"" documents, the ""Control balance of goods to be reserved upon receipt"" option must be enabled'; fa = 'To generate the ""Transfer order"" documents, the ""Control balance of goods to be reserved upon receipt"" option must be enabled';
							|it = 'To generate the ""Transfer order"" documents, the ""Control balance of goods to be reserved upon receipt"" option must be enabled';
							|pl = 'To generate the ""Transfer order"" documents, the ""Control balance of goods to be reserved upon receipt"" option must be enabled';
							|tr = '""Transfer emri"" belgelerinin oluşturulabilmesi için ""Geldikçe rezerve edilecek ürünlerin envanterini kontrol et"" seçeneğinin etkinleştirilmesi gerekmektedir'");
		Common.MessageToUser(MessageText);
		
		Return;
		
	EndIf;
	
	CancelLongRunningOperation();
	
	GroupFields = DataProcessors.GenerateProductionOrderRegisterRecords.CompositionOfColumnsForCreatingDocuments();
	
	FilterStructure1 = New Structure("Mark", True);
	
	UnloadedTable = Object.Plan.Unload(FilterStructure1, GroupFields + ",ForTransfer, Supplied");
	UnloadedTable.GroupBy(GroupFields, "ForTransfer, Supplied");
	
	OrderPlacementResultAddress = PutToTempStorage(Undefined, UUID);
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("OrderPlacementResultAddress", OrderPlacementResultAddress);
	ProcedureParameters.Insert("RegistrationOption", Object.RegistrationOption);
	ProcedureParameters.Insert("DateOfShipment", Object.DateOfShipment);
	ProcedureParameters.Insert("UnloadedTable", UnloadedTable);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập chứng từ điều chuyển: tạo chứng từ';
														|ru = 'Формирование перемещений: создание документов';
														|en = 'Transfer generation: document creation'; fa = 'Transfer generation: document creation';
														|it = 'Creazione spostamenti: creazione documenti';
														|pl = 'Rejestracja przeniesień: tworzenie dokumentów';
														|tr = 'Transferin düzenlenmesi: Belgelerin oluşturulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.GenerateProductionOrderRegisterRecords.CreateDocumentsDeferred",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "CreateDocumentsDeferredCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		CreateDocumentsDeferred(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDocumentsDeferredCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	CreateDocumentsDeferred(Result);
		
	If Result <> Undefined And Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateDocumentsDeferred(Result)
	
	ResultStructure1 = GetFromTempStorage(OrderPlacementResultAddress);
	
	If ValueIsFilled(ResultStructure1) Then // The task was interrupted before something was recorded
		
		InstallAssistantPages(ThisForm, "StepResultOfFormation");
		
		CreatedObjects.LoadValues(ResultStructure1.Documents);
		
		SetSettingsForListOfCreatedDocuments();
		
		CommonClientServer.SetDynamicListParameter(ListDocuments, "Documents", ResultStructure1.Documents);
		
		For Each Error In ResultStructure1.Messages Do
			CommonClientServer.MessageToUser(Error.Text, Error.DataKey, Error.Field, Error.DataPath);
		EndDo;
		
		If Result = Undefined Or Result.Status <> "Completed2" Then
			Message = New UserMessage();
			Message.Text = NStr("vi = 'Các đơn hàng chưa được lập đầy đủ';
								|ru = 'Заказы были сформированы не полностью';
								|en = 'Orders were not fully generated'; fa = 'Orders were not fully generated';
								|it = 'Gli ordini non sono stati completamente generati';
								|pl = 'Zamówienia nie zostały w pełni uformowane';
								|tr = 'Siparişler tamamen oluşturulmadı'");
			Message.Message();
		EndIf
		
	EndIf;
	
EndProcedure

&AtServer
Procedure Delete_CreatedObjects(Cancel)
	
	DocumentsArray = CreatedObjects.UnloadValues();
	ErrorList = TMCommonUse.SetMarkForDeletingDocuments(DocumentsArray);
	CommonClientServer.ReportErrorsToUser(ErrorList);

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ContinueWithOtherSelectionsOnServer()
	
	Object.Plan.Clear();
	SetHyperlinkTextProvided();
	Totals.Clear();
	
	CreatedObjects.Clear();
	
	InstallAssistantPages(ThisForm, "StepSelection");
	
EndProcedure

#EndRegion

#EndRegion

#Region Filters

&AtServer
Procedure InitializeSettingsComposer()
	
	DataCompositionSchema = DataProcessors.GenerateProductionOrderRegisterRecords.GetTemplate("ItemPlan");
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	
	SettingsComposer.Initialize(SettingsSource);
	
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);

EndProcedure

&AtClientAtServerNoContext
Procedure ReflectSimpleSelectionInLayoutSelections(
	SettingsComposer, FieldName, Value, Var_ComparisonType = Undefined, DisableUsage = False)
	
	If Var_ComparisonType = Undefined Then
		Var_ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;
	
	// The selection is predefined in the SKD settings.
	SearchValue = New DataCompositionField(FieldName);
	ElementFound_ = False;
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		
		If FilterElement.LeftValue = SearchValue Then
			
			UserSettingItem = SettingsComposer.UserSettings.Items.Find(
													FilterElement.UserSettingID);
					
			If Not UserSettingItem = Undefined Then
				
				UserSettingItem.Use = (Value <> Undefined) And ValueIsFilled(Value);
				If UserSettingItem.Use Then
					
					UserSettingItem.ComparisonType   = Var_ComparisonType;
					UserSettingItem.RightValue = Value;
					
				EndIf;
				
				If DisableUsage Then
					UserSettingItem.Use = False;
				EndIf;
				
				ElementFound_ = True;
				Break;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Selection by subordinate fields (search in user-added selection elements).
	If Not ElementFound_ Then
		
		SelectionID_ = SettingsComposer.Settings.Filter.UserSettingID;
		Filter = SettingsComposer.UserSettings.Items.Find(SelectionID_);
		FilterElement = Undefined;
		For Each ExistingSelectionElement In Filter.Items Do
			
			If String(ExistingSelectionElement.LeftValue) = FieldName Then
				FilterElement = ExistingSelectionElement;
				Break;
			EndIf;
		EndDo;
		If FilterElement = Undefined Then
			FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
		EndIf;
		
		FilterElement.Use  = ValueIsFilled(Value);
		FilterElement.LeftValue  = New DataCompositionField(FieldName);
		FilterElement.RightValue = Value;
		
		FilterElement.ComparisonType   = Var_ComparisonType;
		
	EndIf;
	
EndProcedure

&AtClient
Function ReflectLayoutSelectionInSimpleSelections()
	
	// Search in user-added selection elements.
	
	SelectionID_ = SettingsComposer.Settings.Filter.UserSettingID;
	Filter = SettingsComposer.UserSettings.Items.Find(SelectionID_);

	For Each FilterElement In Filter.Items Do
		
		If FilterElement.Use Then 
			Return False;
		EndIf;
	
	EndDo;
	
	SimpleSelections = "DestinationWarehouse, SourceWarehouse, LineOfBusiness, Purpose, Warehouse, Products, ProductionOrder, EndDate, OnlyRunningBatches, BillOfMaterials";
	
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		
		UserSettingItem = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
		
		If UserSettingItem <> Undefined
			 And UserSettingItem.Use
			 And TypeOf(FilterElement) = Type("DataCompositionFilterItem")
			 And Not StrFind(SimpleSelections, FilterElement.LeftValue) > 0 Then
			Return False;
		EndIf;
		
	EndDo;
	
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		
		UserSettingItem = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
		If Not UserSettingItem = Undefined Then
			
			If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
				
				FillOutSimpleSelection(SelectionByWarehouseRecipient,
					"DestinationWarehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"),
					FilterElement, UserSettingItem);
				
				FillOutSimpleSelection(SelectionByWarehouseSender,
					"SourceWarehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"),
					FilterElement, UserSettingItem);
				
				FillOutSimpleSelection(FilterByLineOfBusiness,
					"LineOfBusiness", PredefinedValue("Catalog.LinesOfBusiness.EmptyRef"),
					FilterElement, UserSettingItem);
				
				FillOutSimpleSelection(FilterByAssignment,
					"Purpose", PredefinedValue("Catalog.Assignments.EmptyRef"),
					FilterElement, UserSettingItem);
				
				FillOutSimpleSelection(FilterRemainingGoodsByShelfLives,
					"Products", PredefinedValue("Catalog.Products.EmptyRef"),
					FilterElement, UserSettingItem);
				
				FillOutSimpleSelection(FilterByOrder,
					"ProductionOrder", PredefinedValue("Document.ProductionOrder2_2.EmptyRef"),
					FilterElement, UserSettingItem);
					
				FillOutSimpleSelection(Object.DemandsBeforeDate,
					"EndDate", Date(1, 1, 1),
					FilterElement, UserSettingItem);
					
				FillOutSimpleSelection(FilterOnlyRunningBatches,
					"OnlyRunningBatches", False,
					FilterElement, UserSettingItem);
					
				FillOutSimpleSelection(FilterByBillOfMaterials,
					"BillOfMaterials", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"),
					FilterElement, UserSettingItem);
					
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Procedure FillOutSimpleSelection(FormAttribute, FieldName, DefaultValue, FilterElement, UserSettingItem)
	
	LayoutField = New DataCompositionField(FieldName);
	
	If LayoutField = FilterElement.LeftValue Then
		
		FormAttribute = ?(UserSettingItem.Use,
			UserSettingItem.RightValue, DefaultValue);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
EndProcedure

&AtServer
Procedure RestoreSettings()

	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.GenerateProductionOrderRegisterRecords", "SelectionComposer");

	If TypeOf(SettingsValue) = Type("Structure") Then
		
		SettingsComposer.LoadUserSettings(SettingsValue.UserSettings);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		
	EndIf;
	
	If Not ValueIsFilled(Object.RegistrationOption) Or Not OptionOrdersToMoveIsAvailable Then
		Object.RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DefaultUserSettings_()
	
	DataCompositionSchema = DataProcessors.GenerateProductionOrderRegisterRecords.GetTemplate("ItemPlan");
	
	SettingsSource = New DataCompositionAvailableSettingsSource(DataCompositionSchema);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	SettingsComposer.Initialize(SettingsSource);
	
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	Return SettingsComposer.UserSettings;

EndFunction

&AtServer
Procedure LoadDefaultSelectionSettings()
	
	SettingsComposer.LoadUserSettings(DefaultUserSettings_());
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);

EndProcedure

&AtClientAtServerNoContext
Procedure InstallAssistantPages(Form, StepName)
	
	Items = Form.Items;
	
	If StepName = "StepSelection" Then

		Items.TheWritingStep.Title = NStr("vi = 'Bước 1/3. Lọc';
											|ru = 'Шаг 1 из 3. Отбор';
											|en = 'Step 1 of 3. Filter'; fa = 'Step 1 of 3. Filter';
											|it = 'Passo 1 di 3. Filtro';
											|pl = 'Krok 1 z 3. Filtr';
											|tr = 'Adım 1/3. Filtre'");
		
		Items.Next.DefaultButton = True;
		
		Items.Next.Visible = True;
		Items.Back.Visible = False;
		
		Items.ContinueWithOtherFilters.Visible = False;
		
		Items.WizardPages.CurrentPage = Items.StepSelection;
	
	ElsIf StepName = "StepNomenclaturePlan" Then

		Items.TheWritingStep.Title = NStr("vi = 'Bước 2/3. Xác định thành phần và khối lượng điều chuyển';
											|ru = 'Шаг 2 из 3. Определение состава и объема перемещений';
											|en = 'Step 2 of 3. Decide what to transfer and how much'; fa = 'Step 2 of 3. Decide what to transfer and how much';
											|it = 'Passo 2 di 3. Definizione composizione e volume spostamento';
											|pl = 'Krok 2 z 3. Określenie składu i objętości przeniesień';
											|tr = 'Adım 2/3. Transfer içeriğinin ve hacminin belirlenmesi'");
		
		Items.Next.DefaultButton = True;
		
		Items.Next.Visible = True;
		Items.Back.Visible = True;
		
		Items.ContinueWithOtherFilters.Visible = False;
		
		Items.WizardPages.CurrentPage = Items.StepNomenclaturePlan;

	ElsIf StepName = "StepResultOfFormation" Then

		Items.TheWritingStep.Title = NStr("vi = 'Bước 3/3. Làm rõ các chứng từ đã lập';
											|ru = 'Шаг 3 из 3. Уточнение сформированных документов';
											|en = 'Step 3 of 3. Specify generated documents'; fa = 'Step 3 of 3. Specify generated documents';
											|it = 'Passo 3 di 3. Definizione dei documenti creati';
											|pl = 'Krok 3 z 3. Uściślenie utworzonych dokumentów';
											|tr = 'Adım 3/3. Oluşturulan belgelerin netleştirilmesi'");
		
		Items.Close.DefaultButton = True;
		
		Items.Next.Visible = False;
		Items.Back.Visible = True;
		
		Items.ContinueWithOtherFilters.Visible = True;
		
		Items.WizardPages.CurrentPage = Items.StepResultOfFormation;
	
	EndIf;

EndProcedure

&AtServer
Procedure CancelLongRunningOperation()
	
	If Not TimeConsumingOperation = Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction(OutputIdleWindow = True)
	
	CallbackOnCompletion = New CallbackDescription(TimeConsumingOperationIdleHandler, ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	IdleParameters.OutputIdleWindow = OutputIdleWindow;
	
	TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackOnCompletion,
			IdleParameters);
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtServer
Procedure SaveSelectionComposerSettings()
	
	Settings = New Structure();
	Settings.Insert("UserSettings", SettingsComposer.UserSettings);
	Common.CommonSettingsStorageSave("DataProcessor.GenerateProductionOrderRegisterRecords", "SelectionComposer", Settings);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	// Setting up the access rights form.
	AccessStructure = DataProcessors.GenerateProductionOrderRegisterRecords.AccessStructure();
	
	If Not AccessStructure.MoveOrderIsAvailable And Not AccessStructure.OrderingMaterialsIsAvailable Then
		DesiredElement = Items.RegistrationOption.ChoiceList.FindByValue(
			Enums.OptionsOfRegisteringTransferDocuments.TransferOrder);
		Items.RegistrationOption.ChoiceList.Delete(DesiredElement);
	EndIf;
	
	If Not AccessStructure.MovingIsAvailable And Not AccessStructure.TransferOfMaterialsIsAvailable Then
		DesiredElement = Items.RegistrationOption.ChoiceList.FindByValue(
			Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer);
		Items.RegistrationOption.ChoiceList.Delete(DesiredElement);
	EndIf;
	
	Items.RegistrationOption.Visible = AccessStructure.MoveOrderIsAvailable;
	Items.RegistrationOption.Enabled = OptionOrdersToMoveIsAvailable;
	
	If Not OptionOrdersToMoveIsAvailable Then
		
		Items.RegistrationOption.ToolTipRepresentation = ToolTipRepresentation.Button;
		ToolTipText = NStr("vi = 'Để chọn phương án lập ""Đơn hàng điều chuyển nội bộ"" cần bật tùy chọn ""Kiểm soát vật tư hàng hóa phải được dự phòng theo mức độ tiếp nhận""';
							|ru = 'Для выбора варианта оформления ""Заказ на перемещение"" должна быть включена опция ""Контролировать запасы товаров, подлежащих резервированию по мере поступления""';
							|en = 'To select the ""Transfer order"" option, the ""Control balance of goods to be reserved upon receipt"" option must be enabled'; fa = 'To select the ""Transfer order"" option, the ""Control balance of goods to be reserved upon receipt"" option must be enabled';
							|it = 'To select the ""Transfer order"" option, the ""Control balance of goods to be reserved upon receipt"" option must be enabled';
							|pl = 'To select the ""Transfer order"" option, the ""Control balance of goods to be reserved upon receipt"" option must be enabled';
							|tr = '""Hareket emri"" seçeneğinin seçilebilmesi için ""Geldikçe rezerve edilecek ürünlerin envanterini kontrol et"" seçeneğinin etkinleştirilmesi gerekmektedir'");
		Items.RegistrationOption.ToolTip = ToolTipText;
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);

	If AttributesStructure1.Property("FilterSoftware")
		Or Initialize Then
		
		Form.Items.HyperlinkAllProducts.TextColor = ?(Form.FilterProvidesCurValue <> SoftwareFilterIsDisabled(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Form.Items.HyperlinkProvided.TextColor = ?(Form.FilterProvidesCurValue <> FilterSecurityIsProvided(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeCheckboxesInSelectedLines(Val Value, Val RowsIDs, TableName = "")
	
	ChangesTable = New ValueTable;
	ChangesTable.Columns.Add("SourceWarehouse", New TypeDescription("CatalogRef.Warehouses"));
	ChangesTable.Columns.Add("DestinationWarehouse", New TypeDescription("CatalogRef.Warehouses"));
	ChangesTable.Columns.Add("Weight", Common.TypeDescriptionNumber(15, 3, AllowedSign.Any));
	ChangesTable.Columns.Add("VolumeM3", Common.TypeDescriptionNumber(15, 3, AllowedSign.Any));
	ChangesTable.Columns.Add("FrequencyOfLines", Common.TypeDescriptionNumber(10));
	
	TableOfZeroWeightRows = New ValueTable;
	TableOfZeroWeightRows.Columns.Add("SourceWarehouse", New TypeDescription("CatalogRef.Warehouses"));
	TableOfZeroWeightRows.Columns.Add("DestinationWarehouse", New TypeDescription("CatalogRef.Warehouses"));
	
	TableOfRowsWithZeroVolume = New ValueTable;
	TableOfRowsWithZeroVolume.Columns.Add("SourceWarehouse", New TypeDescription("CatalogRef.Warehouses"));
	TableOfRowsWithZeroVolume.Columns.Add("DestinationWarehouse", New TypeDescription("CatalogRef.Warehouses"));
	
	ZoomRatio = ?(Value, 1, -1);
	
	For Each RowID In RowsIDs Do
		
		TableRow = Object[TableName].FindByID(RowID);
		
		ValueBeforeChange = TableRow.Mark;
		TableRow.Mark = Value;
		
		If ValueBeforeChange <> Value Then
		
			ChangeBucketLine = ChangesTable.Add();
			FillPropertyValues(ChangeBucketLine, TableRow);
			ChangeBucketLine.Weight = ZoomRatio * TableRow.ForTransfer * TableRow.UnitWeight;
			ChangeBucketLine.VolumeM3 = ZoomRatio * TableRow.ForTransfer * TableRow.UnitVolume;
			ChangeBucketLine.FrequencyOfLines = ZoomRatio;
			
			If TableRow.UnitWeight = 0 Then
				TableRowWeight = TableOfZeroWeightRows.Add();
				FillPropertyValues(TableRowWeight, ChangeBucketLine);
			EndIf;
			
			If TableRow.UnitVolume = 0 Then
				TableRowVolume = TableOfRowsWithZeroVolume.Add();
				FillPropertyValues(TableRowVolume, ChangeBucketLine);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ChangesTable.GroupBy("SourceWarehouse, DestinationWarehouse", "Weight, VolumeM3, FrequencyOfLines");
	ShoppingCartByWarehousesChanges.Load(ChangesTable);
	
	WarehouseSearch = New Structure("SourceWarehouse, DestinationWarehouse");
	TableOfZeroWeightRows.GroupBy("SourceWarehouse, DestinationWarehouse");
	TableOfRowsWithZeroVolume.GroupBy("SourceWarehouse, DestinationWarehouse");
	
	For Each TableRow In TableOfZeroWeightRows Do
	
		FillPropertyValues(WarehouseSearch, TableRow);
		ArrayOfTSStrings = ShoppingCartByWarehousesChanges.FindRows(WarehouseSearch);
		For Each TSRow In ArrayOfTSStrings Do
			TSRow.ThereAreRowsWithZeroWeight = True;
		EndDo;
	
	EndDo;
	
	For Each TableRow In TableOfRowsWithZeroVolume Do
	
		FillPropertyValues(WarehouseSearch, TableRow);
		ArrayOfTSStrings = ShoppingCartByWarehousesChanges.FindRows(WarehouseSearch);
		For Each TSRow In ArrayOfTSStrings Do
			TSRow.ThereAreLinesWithZeroVolume = True;
		EndDo;
	
	EndDo;
	
EndProcedure

&AtClient
Procedure WriteAtClient(Command)
	
	ClearMessages();
	ReferencesArrray = New Array();
	
	For Each String In Items.ListDocuments.SelectedRows Do
		
		DocumentReference = Items.ListDocuments.RowData(String).Ref;
		ReferencesArrray.Add(DocumentReference);
		
	EndDo;
	WriteAtServer(ReferencesArrray, Command.Name);
	Items.ListDocuments.Refresh();
	
EndProcedure

&AtServer
Procedure WriteAtServer(ReferencesArrray, Action)
	
	BlockErrorTemplate     = NStr("vi = 'Không thể phong tỏa %Document%. %ErrorDescription%';
									|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
									|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
									|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
									|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
									|tr = '%Document% bloke edilemedi. %ErrorDescription%'");
	WriteErrorTemplate          = NStr("vi = 'Không thể ghi lại %Document%. %ErrorDescription%';
										|ru = 'Не удалось записать %Document%. %ErrorDescription%';
										|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
										|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
										|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
										|tr = '%Document% kaydedilemedi. %ErrorDescription%'");
	ErrorTemplateToHold          = NStr("vi = 'Chưa thực hiện kết chuyển %1 %2 ngày %3';
										|ru = 'Проведение не выполнено %1 %2 от %3';
										|en = 'Cannot post %1 %2 dated %3'; fa = 'Cannot post %1 %2 dated %3';
										|it = 'Проведение не выполнено %1 %2 от %3';
										|pl = 'Cannot post %1 %2 dated %3';
										|tr = 'Kaydetme gerçekleştirilmedi %1 %2/%3'");
	
	For Each Ref In ReferencesArrray Do
		
		// Capturing an object for editing
		Try
			LockDataForEdit(Ref);
		Except
			ErrorText = StrReplace(BlockErrorTemplate, "%Document%", Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Ref);
			Continue;
		EndTry;
		
		// Getting a Document object
		DocumentObject = Ref.GetObject();
		
		CorrectFilling = True;
		
		If Action = "Post" Then
			
			CorrectFilling = DocumentObject.CheckFilling();
			
			If Not CorrectFilling Then
				
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplateToHold,
					DocumentObject.Metadata().Synonym,
					DocumentObject.Number,
					DocumentObject.Date);
				
				CommonClientServer.MessageToUser(Text, DocumentObject.Ref);
			
			EndIf;
			
		EndIf;
		
		If CorrectFilling Then
		
			// Document recording
			Try
				
				If Action = "Post" Then
					DocumentObject.Write(DocumentWriteMode.Posting);
				ElsIf Action = "UndoPosting" Then
					DocumentObject.Write(DocumentWriteMode.UndoPosting);
				ElsIf Action = "MarkToDelete" Then
					DocumentObject.SetDeletionMark(Not DocumentObject.DeletionMark);
				EndIf;
				
			Except
				ErrorText = StrReplace(WriteErrorTemplate, "%Document%", Ref);
				ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
				CommonClientServer.MessageToUser(ErrorText, Ref);
			EndTry;
		
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetStatus(Command)
	
	DocumentType = Undefined;
	
	If Command = Commands.SetTheStatusOfProductMovementsShipped.Name Then
		
		DocumentType = Type("DocumentRef.InventoryTransfer");
		Status = PredefinedValue("Enum.GoodsTransferStatuses.Shipped");
		
	ElsIf Command = Commands.SetTheStatusOfProductMovementsAccepted.Name Then
		
		DocumentType = Type("DocumentRef.InventoryTransfer");
		Status = PredefinedValue("Enum.GoodsTransferStatuses.Accepted");
		
	ElsIf Command = Commands.SetTheStatusOfMaterialTransfersShipped.Name Then
		
		DocumentType = Type("DocumentRef.MovementOfProductsAndMaterials");
		Status = PredefinedValue("Enum.StatusesOfProductsAndMaterialMovement.Shipped");
		
	ElsIf Command = Commands.SetTheStatusOfMaterialTransfersAccepted.Name Then
		
		DocumentType = Type("DocumentRef.MovementOfProductsAndMaterials");
		Status = PredefinedValue("Enum.StatusesOfProductsAndMaterialMovement.Accepted");
		
	EndIf;
	
	ReferencesArrray = New Array();
	
	For Each String In Items.ListDocuments.SelectedRows Do
		
		DocumentReference = Items.ListDocuments.RowData(String).Ref;
		If TypeOf(DocumentReference) = DocumentType Then
			
			ReferencesArrray.Add(DocumentReference);
			
		EndIf;
		
	EndDo;
	SetStatusOnServer(ReferencesArrray, Status);
	Items.ListDocuments.Refresh();
	
EndProcedure

&AtServer
Procedure SetStatusOnServer(ReferencesArrray, Status)
	
	Status = Common.ObjectManagerByRef(Status).IndexOf(Status);
	TotalRefs = ReferencesArrray.Count();
	
	For Counter = 1 To TotalRefs Do
		
		CurArrayElement_ = ReferencesArrray[TotalRefs - Counter];
		If CreatedObjects.FindByValue(CurArrayElement_) = Undefined Then
		
			ReferencesArrray.Delete(CurArrayElement_);
			
		EndIf;
		
	EndDo;
	
	SetStatusByArrayOfLinks(ReferencesArrray, Status);
	
EndProcedure

&AtServer
Procedure SetStatusByArrayOfLinks(ReferencesArrray, Status)
	
	BlockErrorTemplate     = NStr("vi = 'Không thể phong tỏa %Document%. %ErrorDescription%';
									|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
									|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
									|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
									|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
									|tr = '%Document% bloke edilemedi. %ErrorDescription%'");
	WriteErrorTemplate          = NStr("vi = 'Không thể ghi lại %Document%. %ErrorDescription%';
										|ru = 'Не удалось записать %Document%. %ErrorDescription%';
										|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
										|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
										|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
										|tr = '%Document% kaydedilemedi. %ErrorDescription%'");

	For Each Ref In ReferencesArrray Do
		
		// Capturing an object for editing
		Try
			LockDataForEdit(Ref);
		Except
			ErrorText = StrReplace(BlockErrorTemplate, "%Document%", Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Ref);
			Continue;
		EndTry;
		
		// Getting a Document object
		DocumentObject = Ref.GetObject();
		
		// Setting the document status
		If Not DocumentObject.SetStatus(Status, Undefined) Then
			Continue;
		EndIf;
			
		// Document recording
		Try
			
			DocumentObject.Write(?(DocumentObject.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write));
			
		Except
			ErrorText = StrReplace(WriteErrorTemplate, "%Document%", Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Ref);
		EndTry;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSettingsForListOfCreatedDocuments()
	
	SetQueryTextForDynamicListOfCreatedDocuments();
	
	SetVisibilityOfCommandsOfCreatedDocuments();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandsOfCreatedDocuments()
	
	TypesArray = New Array();
	
	For Each Item In CreatedObjects Do
		
		DocumentType = TypeOf(Item.Value);
		
		If TypesArray.Find(DocumentType) = Undefined Then
			TypesArray.Add(DocumentType);
		EndIf;
		
	EndDo;
	
	For Each Item In Items.GroupSetStatus.ChildItems Do
		Item.Visible = False;
	EndDo;
	
	TotalTypes = 0;
	DocumentNames = New Array();
	
	DocumentNames.Add(NStr("vi = 'Điều chuyển hàng hóa:';
							|ru = 'Перемещение товаров:';
							|en = 'Goods transfer:'; fa = 'Goods transfer:';
							|it = 'Trasferimento prodotti:';
							|pl = 'Przemieszczanie towarów:';
							|tr = 'Mal transferi:'"));
	VisibilityOfStatuses = TypesArray.Find(Type("DocumentRef.InventoryTransfer")) <> Undefined
		And GetFunctionalOption("UseGoodsTransferStatuses");
	TotalTypes = TotalTypes + ?(VisibilityOfStatuses, 1, 0);
	
	Items.SetTheStatusOfProductMovementsShipped.Visible = VisibilityOfStatuses;
	Items.SetTheStatusOfProductMovementsAccepted.Visible   = VisibilityOfStatuses;
	
	DocumentNames.Add(NStr("vi = 'Chuyển giao nguyên vật liệu:';
							|ru = 'Передача материалов:';
							|en = 'Material transfer:'; fa = 'Material transfer:';
							|it = 'Consegna dei materiali:';
							|pl = 'Przekazanie materiałów:';
							|tr = 'Malzeme transferi:'"));
	VisibilityOfStatuses = TypesArray.Find(Type("DocumentRef.MovementOfProductsAndMaterials")) <> Undefined
		And GetFunctionalOption("UseStatusesOfProductsAndMaterialsMovements");
	TotalTypes = TotalTypes + ?(VisibilityOfStatuses, 1, 0);
	
	Items.SetTheStatusOfMaterialTransfersShipped.Visible = VisibilityOfStatuses;
	Items.SetTheStatusOfMaterialTransfersAccepted.Visible   = VisibilityOfStatuses;
	
	For Each FormItem In Items.GroupSetStatus.ChildItems Do
		
		FormCommand = Commands[FormItem.CommandName]; // FormCommand -
		CommandTitle = FormCommand.Title;
		
		If TotalTypes = 1 Then
			For Each DocumentName In DocumentNames Do
				CommandTitle = TrimAll(StrReplace(CommandTitle, DocumentName, ""));
			EndDo;
		EndIf;
		
		FormItem.Title = CommandTitle;
		
	EndDo;
	
	Items.ListDocumentsStatus.Visible = TotalTypes > 0;
	
EndProcedure

&AtServer
Procedure SetQueryTextForDynamicListOfCreatedDocuments()
	
	AccessStructure = DataProcessors.GenerateProductionOrderRegisterRecords.AccessStructure();
	QueryText = "";
	
	CurDesign_ = Object.RegistrationOption;
	
	If CurDesign_ = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer
			And AccessStructure.MovingIsAvailable Then
		
		AddJoinSection(QueryText);
		QueryText = QueryText +
			"SELECT
			|	CASE WHEN InventoryTransferOverridable.Posted THEN
			|				1
			|			WHEN InventoryTransferOverridable.DeletionMark THEN
			|				2
			|			ELSE
			|				0
			|		END                                                  AS RowPicture,
			|	InventoryTransferOverridable.Ref                  AS Ref,
			|	InventoryTransferOverridable.DeletionMark         AS DeletionMark,
			|	InventoryTransferOverridable.Number                   AS Number,
			|	InventoryTransferOverridable.Date                    AS Date,
			|	InventoryTransferOverridable.Posted                AS Posted,
			|	InventoryTransferOverridable.LineOfBusiness AS LineOfBusiness,
			|	InventoryTransferOverridable.Organization             AS Organization,
			|	InventoryTransferOverridable.CompanyRecipient   AS CompanyRecipient,
			|	InventoryTransferOverridable.EmployeeResponsible           AS EmployeeResponsible,
			|	InventoryTransferOverridable.Department           AS Department,
			|	InventoryTransferOverridable.SourceWarehouse        AS SourceWarehouse,
			|	InventoryTransferOverridable.DestinationWarehouse         AS DestinationWarehouse,
			|	InventoryTransferOverridable.Status                  AS Status
			|FROM
			|	Document.InventoryTransfer AS InventoryTransferOverridable
			|WHERE
			|	InventoryTransferOverridable.Ref IN(&Documents)";
			
	EndIf;
	
	If CurDesign_ = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer
			And AccessStructure.TransferOfMaterialsIsAvailable Then
		
		AddJoinSection(QueryText);
		QueryText = QueryText +
			"SELECT
			|	CASE WHEN MovementOfProductsAndMaterialsOverridable.Posted THEN
			|				1
			|			WHEN MovementOfProductsAndMaterialsOverridable.DeletionMark THEN
			|				2
			|			ELSE
			|				0
			|		END                                                            AS RowPicture,
			|	MovementOfProductsAndMaterialsOverridable.Ref                  AS Ref,
			|	MovementOfProductsAndMaterialsOverridable.DeletionMark         AS DeletionMark,
			|	MovementOfProductsAndMaterialsOverridable.Number                   AS Number,
			|	MovementOfProductsAndMaterialsOverridable.Date                    AS Date,
			|	MovementOfProductsAndMaterialsOverridable.Posted                AS Posted,
			|	MovementOfProductsAndMaterialsOverridable.LineOfBusiness AS LineOfBusiness,
			|	MovementOfProductsAndMaterialsOverridable.Organization             AS Organization,
			|	MovementOfProductsAndMaterialsOverridable.Organization             AS CompanyRecipient,
			|	MovementOfProductsAndMaterialsOverridable.EmployeeResponsible           AS EmployeeResponsible,
			|	CAST(MovementOfProductsAndMaterialsOverridable.Recipient
			|		AS Catalog.Warehouses).Department                             AS Department,
			|	MovementOfProductsAndMaterialsOverridable.Sender             AS SourceWarehouse,
			|	MovementOfProductsAndMaterialsOverridable.Recipient              AS DestinationWarehouse,
			|	MovementOfProductsAndMaterialsOverridable.Status                  AS Status
			|FROM
			|	Document.MovementOfProductsAndMaterials AS MovementOfProductsAndMaterialsOverridable
			|WHERE
			|	MovementOfProductsAndMaterialsOverridable.Ref IN(&Documents)";
		
	EndIf;
	
	If CurDesign_ = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder
			And AccessStructure.MoveOrderIsAvailable Then
		
		AddJoinSection(QueryText);
		QueryText = QueryText +
			"SELECT
			|	CASE WHEN TransferOrderOverridable.Posted THEN
			|				1
			|			WHEN TransferOrderOverridable.DeletionMark THEN
			|				2
			|			ELSE
			|				0
			|		END                                                  AS RowPicture,
			|	TransferOrderOverridable.Ref                  AS Ref,
			|	TransferOrderOverridable.DeletionMark         AS DeletionMark,
			|	TransferOrderOverridable.Number                   AS Number,
			|	TransferOrderOverridable.Date                    AS Date,
			|	TransferOrderOverridable.Posted                AS Posted,
			|	TransferOrderOverridable.LineOfBusiness AS LineOfBusiness,
			|	TransferOrderOverridable.Organization             AS Organization,
			|	TransferOrderOverridable.CompanyRecipient   AS CompanyRecipient,
			|	TransferOrderOverridable.EmployeeResponsible           AS EmployeeResponsible,
			|	TransferOrderOverridable.Department           AS Department,
			|	TransferOrderOverridable.SourceWarehouse        AS SourceWarehouse,
			|	TransferOrderOverridable.DestinationWarehouse         AS DestinationWarehouse,
			|	TransferOrderOverridable.Status                  AS Status
			|FROM
			|	Document.TransferOrder AS TransferOrderOverridable
			|WHERE
			|	TransferOrderOverridable.Ref IN(&Documents)";
		
	EndIf;
	
	If CurDesign_ = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder
			And AccessStructure.OrderingMaterialsIsAvailable Then
		
		AddJoinSection(QueryText);
		QueryText = QueryText +
			"SELECT
			|	CASE WHEN OrderOfMaterialsOverridable.Posted THEN
			|				1
			|			WHEN OrderOfMaterialsOverridable.DeletionMark THEN
			|				2
			|			ELSE
			|				0
			|		END                                               AS RowPicture,
			|	OrderOfMaterialsOverridable.Ref                  AS Ref,
			|	OrderOfMaterialsOverridable.DeletionMark         AS DeletionMark,
			|	OrderOfMaterialsOverridable.Number                   AS Number,
			|	OrderOfMaterialsOverridable.Date                    AS Date,
			|	OrderOfMaterialsOverridable.Posted                AS Posted,
			|	OrderOfMaterialsOverridable.LineOfBusiness AS LineOfBusiness,
			|	OrderOfMaterialsOverridable.Organization             AS Organization,
			|	OrderOfMaterialsOverridable.Organization             AS CompanyRecipient,
			|	OrderOfMaterialsOverridable.EmployeeResponsible           AS EmployeeResponsible,
			|	OrderOfMaterialsOverridable.Department           AS Department,
			|	OrderOfMaterialsOverridable.Warehouse                   AS SourceWarehouse,
			|	OrderOfMaterialsOverridable.ShopFloorStockroom         AS DestinationWarehouse,
			|	OrderOfMaterialsOverridable.Status                  AS Status
			|FROM
			|	Document.OrderOfMaterialsForProduction AS OrderOfMaterialsOverridable
			|WHERE
			|	OrderOfMaterialsOverridable.Ref IN(&Documents)";
		
	EndIf;
	
	If Not ValueIsFilled(QueryText) Then
		
		QueryText =
		"SELECT
		|	CASE WHEN InventoryTransferOverridable.Posted THEN
		|				1
		|			WHEN InventoryTransferOverridable.DeletionMark THEN
		|				2
		|			ELSE
		|				0
		|		END                                                  AS RowPicture,
		|	InventoryTransferOverridable.Ref                  AS Ref,
		|	InventoryTransferOverridable.DeletionMark         AS DeletionMark,
		|	InventoryTransferOverridable.Number                   AS Number,
		|	InventoryTransferOverridable.Date                    AS Date,
		|	InventoryTransferOverridable.Posted                AS Posted,
		|	InventoryTransferOverridable.Organization             AS Organization,
		|	InventoryTransferOverridable.CompanyRecipient   AS CompanyRecipient,
		|	InventoryTransferOverridable.LineOfBusiness AS LineOfBusiness,
		|	InventoryTransferOverridable.EmployeeResponsible           AS EmployeeResponsible,
		|	InventoryTransferOverridable.Department           AS Department,
		|	InventoryTransferOverridable.SourceWarehouse        AS SourceWarehouse,
		|	InventoryTransferOverridable.DestinationWarehouse         AS DestinationWarehouse,
		|	InventoryTransferOverridable.Status                  AS Status
		|FROM
		|	Document.InventoryTransfer AS InventoryTransferOverridable
		|WHERE
		|	InventoryTransferOverridable.Ref IN(&Documents)";
		
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ListDocuments);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.ListDocuments, ListProperties);
	
EndProcedure

&AtServer
Procedure AddJoinSection(QueryText)
	
	If QueryText <> "" Then
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|";
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateShoppingCartByWarehouse()
	
	TheStructureOfTheSearch = New Structure("SourceWarehouse, DestinationWarehouse");
	For Each ChangesRow In ShoppingCartByWarehousesChanges Do
		
		FillPropertyValues(TheStructureOfTheSearch, ChangesRow);
		ArrayOfTrashRows = ShoppingCartByWarehouse.FindRows(TheStructureOfTheSearch);
		If ArrayOfTrashRows.Count() = 0 Then
			ShoppingCartLine = ShoppingCartByWarehouse.Add();
			FillPropertyValues(ShoppingCartLine, TheStructureOfTheSearch);
		Else
			ShoppingCartLine = ArrayOfTrashRows[0];
		EndIf;
		
		ShoppingCartLine.Weight = ShoppingCartLine.Weight + ChangesRow.Weight;
		ShoppingCartLine.VolumeM3 = ShoppingCartLine.VolumeM3 + ChangesRow.VolumeM3;
		ShoppingCartLine.FrequencyOfLines = ShoppingCartLine.FrequencyOfLines + ChangesRow.FrequencyOfLines;
		
		If ChangesRow.ThereAreRowsWithZeroWeight Then
			ShoppingCartLine.ShowsThatThereAreLinesWithZeroWeight = 1;
		EndIf;
		
		If ChangesRow.ThereAreLinesWithZeroVolume Then
			ShoppingCartLine.ShowsThatThereAreLinesWithZeroVolume = 1;
		EndIf;
		
	EndDo;
	
	ForDeletion = ShoppingCartByWarehouse.FindRows(New Structure("FrequencyOfLines", 0));
	For Each ArrayRow In ForDeletion Do
		ShoppingCartByWarehouse.Delete(ArrayRow);
	EndDo;
	
	ShoppingCartByWarehousesChanges.Clear();
	
EndProcedure

&AtServer
Procedure InitializeChangesToShoppingCartByWarehouse(FillingData)

	FillingDataForWarehouses = FillingData.Copy(
		New Structure("Mark", True), "SourceWarehouse, DestinationWarehouse, Weight, VolumeM3");
	FillingDataForWarehouses.Columns.Add("FrequencyOfLines", Common.TypeDescriptionNumber(10));
	FillingDataForWarehouses.FillValues(1, "FrequencyOfLines");
	
	FillingDataForWarehouses.Indexes.Add("Weight");
	FillingDataForWarehouses.Indexes.Add("VolumeM3");
		
	TableOfZeroWeightRows = FillingDataForWarehouses.Copy(
		New Structure("Weight", 0), "SourceWarehouse, DestinationWarehouse");
	TableOfRowsWithZeroVolume = FillingDataForWarehouses.Copy(
		New Structure("VolumeM3", 0), "SourceWarehouse, DestinationWarehouse");
		
	TableOfZeroWeightRows.GroupBy("SourceWarehouse, DestinationWarehouse");
	TableOfRowsWithZeroVolume.GroupBy("SourceWarehouse, DestinationWarehouse");
		
	FillingDataForWarehouses.GroupBy("SourceWarehouse, DestinationWarehouse", "Weight, VolumeM3, FrequencyOfLines");
	ShoppingCartByWarehousesChanges.Load(FillingDataForWarehouses);
	
	WarehouseSearch = New Structure("SourceWarehouse, DestinationWarehouse");
	
	For Each TableRow In TableOfZeroWeightRows Do
	
		FillPropertyValues(WarehouseSearch, TableRow);
		ArrayOfTSStrings = ShoppingCartByWarehousesChanges.FindRows(WarehouseSearch);
		For Each TSRow In ArrayOfTSStrings Do
			TSRow.ThereAreRowsWithZeroWeight = True;
		EndDo;
	
	EndDo;
	
	For Each TableRow In TableOfRowsWithZeroVolume Do
	
		FillPropertyValues(WarehouseSearch, TableRow);
		ArrayOfTSStrings = ShoppingCartByWarehousesChanges.FindRows(WarehouseSearch);
		For Each TSRow In ArrayOfTSStrings Do
			TSRow.ThereAreLinesWithZeroVolume = True;
		EndDo;
	
	EndDo;

EndProcedure

&AtServer
Procedure SetHeadersOfCartColumnsByWarehouse()

	Query = New Query();
	Query.Text =
		"SELECT
		|	PRESENTATION(Constants.UnitOfMeasureForWeight)   AS UnitOfMeasureForWeight,
		|	PRESENTATION(Constants.UnitOfMeasureForVolume) AS UnitOfMeasureForVolume
		|FROM
		|	Constants AS Constants";
	Selection = Query.Execute().Select();
	Selection.Next();

	TitleWeight   = StrTemplate(NStr("vi = 'Trọng lượng (%1)';
									|ru = 'Вес (%1)';
									|en = 'Weight (%1)'; fa = 'Weight (%1)';
									|it = 'Вес (%1)';
									|pl = 'Waga (%1)';
									|tr = 'Ağırlık (%1)'"), Selection.UnitOfMeasureForWeight);
	VolumeHeader = StrTemplate(NStr("vi = 'khối lượng (%1)';
									|ru = 'Объем (%1)';
									|en = 'Volume (%1)'; fa = 'Volume (%1)';
									|it = 'Объем (%1)';
									|pl = 'Objętość (%1)';
									|tr = 'Hacim (%1)'"), Selection.UnitOfMeasureForVolume);
	
	Items.ShoppingCartByWarehouseWeight.Title = TitleWeight;
	Items.ShoppingCartByWarehouseVolumeM3.Title = VolumeHeader;

EndProcedure 

&AtClientAtServerNoContext
Procedure UpdateSettingsByDesignOption(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	
	If Form.TransferOrdersAreUsed Then
	
		If Object.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringTransferDocuments.InventoryTransfer") Then
		
			Object.DateOfShipment = Form.CurrentDate;
			Items.FilterByShipmentDate.Visible = False;
			
		ElsIf Object.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringTransferDocuments.TransferOrder") Then
			
			Items.FilterByShipmentDate.Visible = True;
					
		EndIf;
		
	Else
		
		Object.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringTransferDocuments.InventoryTransfer");
		Object.DateOfShipment = Form.CurrentDate;
		Items.FilterByShipmentDate.Visible = False;
	
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
	If Item.Name = "sh_ShamsiInput_DemandsBeforeDate" Then
		DemandsBeforeDateOnChange(Items.FilterDemandsBeforeDate);
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
