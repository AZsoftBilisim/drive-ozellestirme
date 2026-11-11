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
	UseWarehousesInTabularSectionsOfPurchaseDocuments = GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments");
	SplitOrdersByWarehouses = Not GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments");
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	Manager = Users.CurrentUser();
	
	ConfigurePurchaseDocumentType(Parameters.FullNameOfPurchaseDocument, Cancel);
	SetPropertiesByPurchaseDocumentType();
	
	RestoreSettings();
	
	ScenarioData = ScriptDetailsValues(Object.Scenario);
	FillPropertyValues(ThisObject, ScenarioData);
	
	ModeForCalculatingNeedsOfPlanWhenChangingOnServer();
	
	SetFormItemsVisibility();
	VisibilitySettingsWhenChangingScript(ThisForm);
	VisibilitySettingsWhenChangingSubdividingSelectionOnServer(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
	
		SplitOrdersByWarehouses = Settings.Get("SplitOrdersByWarehouses");
	
	Else
	
		SplitOrdersByWarehouses = False;
		Settings.Insert("SplitOrdersByWarehouses", False);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If GeneratePurchaseRequests Then
		Title = NStr("vi = 'Tạo yêu cầu mua hàng theo kế hoạch';
					|ru = 'Формирование заявок на закупку по плану';
					|en = 'Generate purchase requests by plan'; fa = 'ایجاد درخواست‌های خرید بر اساس برنامه';
					|it = 'Generate purchase requests by plan';
					|pl = 'Generate purchase requests by plan';
					|tr = 'Plana göre satın alma talebi oluşturma'");
	Else
		Title = NStr("vi = 'Tạo đơn hàng đặt nhà cung cấp theo kế hoạch';
					|ru = 'Формирование заказов поставщику по плану';
					|en = 'Convert plan to purchase orders'; fa = 'تبدیل برنامه به سفارش‌های خرید';
					|it = 'Generazione di ordini al fornitore in base al piano';
					|pl = 'Tworzenie zamówień do dostawcy wg planu';
					|tr = 'Plana göre satın alma siparişi oluşturma'");
	EndIf;
	
	SetFormHeader(Items.PagesMainPanel.CurrentPage);
	
	If ReflectLayoutSelectionInSimpleSelections() Then
		
		Items.PagesFilterOptions.CurrentPage = Items.PageSimpleFilters;
		
		FilterDepartments = ValueIsFilled(Object.Department);
		
	Else
		
		Items.PagesFilterOptions.CurrentPage = Items.PageRandomFilters;
	
	EndIf; 
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("ProviderParameters") Then
		
		CurrentRow = Items.GenerationOfOrders.CurrentData;
		TypeOfPriceWasSpecified = ValueIsFilled(CurrentRow.VendorPriceKind);
		FillPropertyValues(CurrentRow, ValueSelected.ProviderParameters);
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		If ValueSelected.ProviderParameters.Property("PriceInTheCurrencyOfAgreement") And ValueSelected.ProviderParameters.PriceInTheCurrencyOfAgreement > 0 Then
			CurrentRow.Price = ValueSelected.ProviderParameters.PriceInTheCurrencyOfAgreement;
		ElsIf TypeOfPriceWasSpecified Then
			StructureOfActions.Insert("FillInPurchasePrice", SettingsForFillingInPurchasePriceInTSLine(CurrentRow, CurrentSessionDate));
		EndIf; 
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		If CurrentRow.SelectToOrder Then
			
			If DisplayOrdersForRegistration Then
				UpdateOrderCart();
			EndIf;
			
		EndIf; 
		
	EndIf;
	
	If TypeOf(ValueSelected) = Type("Structure")
		And (ValueSelected.Property("SplitOrdersByOrderDates")
		Or ValueSelected.Property("SplitOrdersByDeliveryDates")
		Or ValueSelected.Property("SplitOrdersByAssignments")
		Or ValueSelected.Property("SplitOrdersByWarehouses")
		Or ValueSelected.Property("SplitOrdersByPlanLines")) Then
		
		FillPropertyValues(ThisForm, ValueSelected);
		
		SetFormItemsVisibility();
		If DisplayOrdersForRegistration Then
			UpdateOrderCart();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	NamesOfDocumentRecordingEvents = New Array;
	NamesOfDocumentRecordingEvents.Add("Write_PurchaseOrder");
	NamesOfDocumentRecordingEvents.Add("Write_PurchaseRequest");
	
	If NamesOfDocumentRecordingEvents.Find(EventName) <> Undefined
		And Items.PagesMainPanel.CurrentPage = Items.PageStep2 Then
		
		DocumentListForUpdate.Add(Source);
		UpdateDataWhenFormBecomesActive();
		
	ElsIf EventName = "SetSelection_FormationOfOrdersToSupplierAccordingToPlan" Then
		
		FillInOnClient();
		
	EndIf;
		
EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes  Then
		
		FillInOnClient();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	TheseAreSimpleSelections = Items.PagesFilterOptions.CurrentPage = Items.PageSimpleFilters;
	
	AttributesNotToCheck = New Array;
	If Not GeneratePurchaseRequests Then 
		AttributesNotToCheck.Add("Manager");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
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
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "Scenario", Object.Scenario);
	DataCompositionClientServer.SetParameter(SettingsComposer, "PlanningByAssignments", PlanningByAssignments);
	
	SetAvailability();
	
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
	
	If Object.DemandCalculationModeByPlan = 0
		Or Object.DemandCalculationModeByPlan = 2 Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderStartDate", Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderEndDate", Object.PeriodEnd);
		DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodEnding", Date("00010101"));
	Else
		
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderStartDate", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderEndDate", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod", Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodEnding", Object.PeriodEnd);
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodBeginning", Object.PeriodBeginning);
	DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodEnd", Object.PeriodEnd);
	
EndProcedure

&AtClient
Procedure PeriodBeginningOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PeriodStartPeriodEndWhenModified();
	
EndProcedure

&AtClient
Procedure PeriodEndOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PeriodStartPeriodEndWhenModified();
	
EndProcedure

&AtClient
Procedure PeriodStartPeriodEndWhenModified()
	
	BringDatesToPeriodicityOfScript(ThisObject, Object.PeriodBeginning, Object.PeriodEnd);
	
	If Object.DemandCalculationModeByPlan = 0
		Or Object.DemandCalculationModeByPlan = 2 Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderStartDate", Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderEndDate", Object.PeriodEnd);
		DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodEnding", Date("00010101"));
	Else
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderStartDate", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposer, "OrderEndDate", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod", Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodEnding", Object.PeriodEnd);
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodBeginning", Object.PeriodBeginning);
	DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodEnd", Object.PeriodEnd);
	
EndProcedure

&AtClient
Procedure FilterDepartmentsOnChange(Item)
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "FilterDepartments", FilterDepartments);
	VisibilitySettingsWhenChangingSubdividingSelectionOnServer(ThisForm);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "Department", Object.Department);
	VisibilitySettingsWhenChangingSubdividingSelectionOnServer(ThisForm);

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	ThisIsGroupSelection = ThisIsGroupSelection(Object.Warehouse, FilterByGroup);
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Warehouse", Object.Warehouse, ThisIsGroupSelection);
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	ThisIsGroupSelection = ThisIsGroupSelection(Object.Partner, FilterByGroup);
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Vendor", Object.Partner, ThisIsGroupSelection);
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Terms", Object.Terms, False);
	If ValueIsFilled(Object.Partner) Then
		Items.Terms.Enabled = True;
	Else
		Items.Terms.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Terms", Object.Terms, False);
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	ThisIsGroupSelection = ThisIsGroupSelection(Object.Products, FilterByGroup);
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Products", Object.Products, ThisIsGroupSelection);
	
EndProcedure

&AtClient
Procedure ProductSegmentOnChange(Item)
	
	ThisIsGroupSelection = ThisIsGroupSelection(Object.ProductSegment, FilterByGroup);
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "ProductSegment", Object.ProductSegment, ThisIsGroupSelection);
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "Purpose", Object.Purpose);
	DataCompositionClientServer.SetParameter(SettingsComposer, "FilterByAssignment", ValueIsFilled(Object.Purpose));
	
EndProcedure

&AtClient
Procedure SettingsComposerUserSettingsOnChange(Item)
	
	SettingStartPeriod = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "PeriodBeginning");
	SettingPeriodEnd = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "PeriodEnd");
	
	If SettingStartPeriod <> Undefined Then
		If TypeOf(SettingStartPeriod.Value) = Type("StandardBeginningDate") Then
			Object.PeriodBeginning = SettingStartPeriod.Value.Date;
		Else
			Object.PeriodBeginning = SettingStartPeriod.Value;
		EndIf;
	EndIf;
	
	If SettingPeriodEnd <> Undefined Then
		If TypeOf(SettingPeriodEnd.Value) = Type("StandardBeginningDate") Then
			Object.PeriodEnd = SettingPeriodEnd.Value.Date;
		Else
			Object.PeriodEnd = SettingPeriodEnd.Value;
		EndIf;
	EndIf;
	
	PeriodStartPeriodEndWhenModified();
	SettingStartPeriod.Value = Object.PeriodBeginning;
	SettingPeriodEnd.Value = Object.PeriodEnd;
	
EndProcedure

&AtClient
Procedure ToUseARandomSelectionClick(Item)
	
	Items.PagesFilterOptions.CurrentPage = Items.PageRandomFilters;
	
EndProcedure

&AtClient
Procedure TheUseOfSimpleSelectionsClick(Item)
	
	If ReflectLayoutSelectionInSimpleSelections() Then
		
		Items.PagesFilterOptions.CurrentPage = Items.PageSimpleFilters;
		If ValueIsFilled(Object.Partner) Then
			Items.Terms.Enabled = True;
		Else
			Items.Terms.Enabled = False;
		EndIf;
		
		FilterDepartments = ValueIsFilled(Object.Department);
		Items.Department.Enabled = FilterDepartments = 1;
		
	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Đã đặt lọc nâng cao, không sử dụng phương án lọc đơn giản.';
										|ru = 'Установлены сложные отборы, вариант использования простых отборов недоступен.';
										|en = 'Complex filters are set, simple filter usage option is not available.'; fa = 'Complex filters are set, simple filter usage option is not available.';
										|it = 'Sono stati impostati filtri complessi, opzione di utilizzo di filtri semplici non è disponibile.';
										|pl = 'Ustawiono złożone selekcje, wariant używania prostych selekcji jest niedostępny.';
										|tr = 'Karmaşık filtreler ayarlandı, kullanıcı basit filtre seçeneklerini kullanamaz.'"));
		
	EndIf;
	
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
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow <> Undefined Then
		CurrentRow.TotalWeight = CurrentRow.Count * CurrentRow.Weight;
	EndIf;
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersPackageOnChange(Item)
	
	CurrentRow = Items.GenerationOfOrders.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Delete("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		StructureOfActions.Insert("FillInPurchasePrice", SettingsForFillingInPurchasePriceInTSLine(CurrentRow, CurrentSessionDate));
	EndIf;
	
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
	RowKey.Insert("BeginOfPeriod", 	CurRow.DateOfReceipt);
	RowKey.Insert("PeriodEnding", EndOfDay(CurRow.ReceiptPeriodEnd));
	RowKey.Insert("Purpose", 		CurRow.Purpose);
	
	If CurRow.EditBusinessUnit Then
		RowKey.Insert("Department", 	PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	Else
		RowKey.Insert("Department", 	CurRow.Department);
	EndIf;
	If CurRow.EditPartner Then
		RowKey.Insert("Partner", 			PredefinedValue("Catalog.Partners.EmptyRef"));
	Else
		RowKey.Insert("Partner",			CurRow.Partner);
	EndIf;
	If CurRow.EditTermsOfPurchase Then
		RowKey.Insert("Terms", 		PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef"));
	Else
		RowKey.Insert("Terms",		CurRow.Terms);
	EndIf;
	If CurRow.EditWarehouse Then
		RowKey.Insert("Warehouse", 			PredefinedValue("Catalog.Warehouses.EmptyRef"));
	Else
		RowKey.Insert("Warehouse",			CurRow.Warehouse);
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
	RowKey.Insert("Products",                CurRow.Products);
	RowKey.Insert("Characteristic",              CurRow.Characteristic);
	RowKey.Insert("Purpose",                  CurRow.Purpose);
	RowKey.Insert("DateOfReceipt",             CurRow.DateOfReceipt);
	RowKey.Insert("ReceiptPeriodEnd", CurRow.ReceiptPeriodEnd);
	RowKey.Insert("EndOfDayEndOfReceiptPeriod", EndOfDay(CurRow.ReceiptPeriodEnd));
	RowKey.Insert("Purpose",                  CurRow.Purpose);
	
	If CurRow.EditBusinessUnit Then
		RowKey.Insert("Department", 	PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	Else
		RowKey.Insert("Department", 	CurRow.Department);
	EndIf;
	If CurRow.EditPartner Then
		RowKey.Insert("Partner", 			PredefinedValue("Catalog.Partners.EmptyRef"));
	Else
		RowKey.Insert("Partner",			CurRow.Partner);
	EndIf;
	If CurRow.EditTermsOfPurchase Then
		RowKey.Insert("Terms", 		PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef"));
	Else
		RowKey.Insert("Terms",		CurRow.Terms);
	EndIf;
	If CurRow.EditWarehouse Then
		RowKey.Insert("Warehouse", 			PredefinedValue("Catalog.Warehouses.EmptyRef"));
	Else
		RowKey.Insert("Warehouse",			CurRow.Warehouse);
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
Procedure GenerationOfOrdersDepartmentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);

	RowKey = New Structure;
	RowKey.Insert("Products",					TableRow.Products);
	RowKey.Insert("Characteristic",				TableRow.Characteristic);
	RowKey.Insert("DateOfReceipt",				TableRow.DateOfReceipt);
	RowKey.Insert("ReceiptPeriodEnd",	TableRow.ReceiptPeriodEnd);
	RowKey.Insert("EditBusinessUnit",	False);	
	
	LinkIsNotInList = New Array;
	Rows = TableOrderGeneration.FindRows(RowKey);
	For Each String In Rows Do
		LinkIsNotInList.Add(String.Department);
	EndDo;
	
	Filter = New Structure("Department", True);
	
	Notification = New CallbackDescription("FillInTheDepartmentCompletion", 
		ThisObject, 
		New Structure("SelectedRows", Items.GenerationOfOrders.SelectedRows));
	OpenForm("Catalog.BusinessStructure.ChoiceForm", 
		New Structure("Key, Filter, LinkIsNotInList", TableRow.Department, Filter, LinkIsNotInList),
		,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure GenerationOfOrdersDepartmentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);

	RowKey = New Structure;
	RowKey.Insert("Products",					TableRow.Products);
	RowKey.Insert("Characteristic",				TableRow.Characteristic);
	RowKey.Insert("DateOfReceipt",				TableRow.DateOfReceipt);
	RowKey.Insert("ReceiptPeriodEnd",	TableRow.ReceiptPeriodEnd);
	RowKey.Insert("EditBusinessUnit",	False);
	
	LinkIsNotInList = New Array;
	Rows = TableOrderGeneration.FindRows(RowKey);
	For Each String In Rows Do
		If ValueSelected = String.Department Then
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
Procedure GenerationOfOrdersPartnerOnChange(Item)
	
	CurrentRow = Items.GenerationOfOrders.CurrentData;
	
	If Not ValueIsFilled(CurrentRow.Terms) Then
		CurrentRow.PriceIncludesVAT = False;
	EndIf;
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersPartnerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.GenerationOfOrders.CurrentData;
	
	FormParameters = New Structure("Products, Characteristic, Warehouse", 
		CurrentData.Products, 
		CurrentData.Characteristic, 
		CurrentData.Warehouse);
	
	OpenForm("DataProcessor.GenerationOfPurchaseOrdersByPlans.Form.SelectionFormOfVendor", 
		FormParameters, 
		ThisObject, 
		UUID,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersTermsOnChange(Item)
	
	CurrentRow = Items.GenerationOfOrders.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	DetailsOfAgreement = GeneralPurposeTMServerCall.ObjectAttributesValues(CurrentRow.Terms, "Currency, VendorPriceKind, PriceIncludesVAT");
	CurrentRow.Currency = DetailsOfAgreement.Currency;
	CurrentRow.PriceIncludesVAT = DetailsOfAgreement.PriceIncludesVAT;
	If ValueIsFilled(DetailsOfAgreement.VendorPriceKind) Then
		CurrentRow.VendorPriceKind = DetailsOfAgreement.VendorPriceKind;
	EndIf;
	If ValueIsFilled(CurrentRow.VendorPriceKind) Then
		StructureOfActions.Insert("FillInPurchasePrice", SettingsForFillingInPurchasePriceInTSLine(CurrentRow, CurrentSessionDate));
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	EstablishLinksOfSelectionParametersToVendorPriceType(CurrentRow.Terms);
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersVendorPriceKindOnChange(Item)
	
	CurrentRow = Items.GenerationOfOrders.CurrentData;
	
	If Not ValueIsFilled(CurrentRow.VendorPriceKind) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInPurchasePrice", SettingsForFillingInPurchasePriceInTSLine(CurrentRow, CurrentSessionDate));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersWarehouseOnChange(Item)
	
	If SplitOrdersByWarehouses And DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersOrderDateOnChange(Item)
	
	If SplitOrdersByOrderDates And DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationOfOrdersDateOfReceiptOnChange(Item)
	
	If Items.GenerationOfOrders.CurrentData.SelectToOrder And DisplayOrdersForRegistration Then
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
		
	If String <> Undefined And (Field.Name = "OrderBasketPartner"
		Or Field.Name = "OrderBasketTerms"
		Or Field.Name = "OrderBasketDeliveryDate"
		Or Field.Name = "OrderBasketWarehouse"
		Or Field.Name = "OrderBasketDepartment") Then
		BucketRow = OrderBasket.FindByID(String);
		If Field.Name = "OrderBasketPartner" Then
			FieldsNames = "Partner";
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Ấn định hàng hóa đã chọn của nhà cung cấp: %1?';
																						|ru = 'Назначить для выделенного товара поставщика: %1?';
																						|en = 'Assign a vendor for the selected goods item: %1?'; fa = 'Assign a vendor for the selected goods item: %1?';
																						|it = 'Assegnare per la merce selezionata il fornitore: %1?';
																						|pl = 'Wyznacz dla wybranego towaru dostawcę: %1?';
																						|tr = 'Seçili ürün tedarikçisi için görevlendirilsin mi: %1?'"), BucketRow.Partner);
		ElsIf Field.Name = "OrderBasketDepartment" Then
			FieldsNames = "Department";
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chỉ định đơn vị cho sản phẩm đã chọn: %1?';
					|ru = 'Назначить для выделенного товара подразделение: %1?';
					|en = 'Assign a business unit: %1 to the selected goods?'; fa = 'Assign a business unit: %1 to the selected goods?';
					|it = 'Assegnare per la merce selezionata il reparto: %1?';
					|pl = 'Wyznacz dla wybranego towaru dział: %1?';
					|tr = 'Seçili ürün departmanı için görevlendirilsin mi: %1?'"), BucketRow.Department);
		ElsIf Field.Name = "OrderBasketTerms" Then
			FieldsNames = "Terms, Partner, Currency";
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Ấn định đối với hàng hóa đã chọn của nhà cung cấp: %1
				|và thỏa thuận: %2?';
				|ru = 'Назначить для выделенного товара поставщика: %1
				|и соглашение: %2?';
				|en = 'Assign vendor %1
				|and agreement %2 to the selected goods item?'; fa = 'Assign vendor %1
				|and agreement %2 to the selected goods item?';
				|it = 'Assegnare per la merce selezionata il fornitore: %1
				| e accordo: %2?';
				|pl = 'Wyznacz dla wybranego towaru dostawcę: %1
				|i umowę: %2?';
				|tr = 'Seçili ürün tedarikçisi için görevlendirilsin mi: %1
				|ve anlaşma: %2?'"),BucketRow.Partner, BucketRow.Terms);
		ElsIf Field.Name = "OrderBasketDeliveryDate" Or Field.Name = "OrderBasketWarehouse" Then
			FieldsNames = "Warehouse";
			QueryText =StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Ấn định kho bãi đối với hàng hóa đã chọn: %1?';
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
		
		PartnerChanged = False;
		AgreementChanged = False;
		AgreementsAreEmpty = False;
		
		For Each TSRow In DragParameters.Value Do
			OldAgreement = TSRow.Terms;
			OldOld = TSRow.Partner;
			
			If (Not TSRow.EditBusinessUnit And FieldsNames = "Department")
				Or (Not TSRow.EditPartner And FieldsNames = "Partner")
				Or (Not TSRow.EditTermsOfPurchase And FieldsNames = "Terms")
				Or (Not TSRow.EditWarehouse And FieldsNames = "Warehouse") Then
				Continue;
			EndIf;
			FillPropertyValues(TSRow, BucketRow, FieldsNames);
			
			If TSRow.Partner <> OldOld Then
				PartnerChanged = True;
			EndIf;
			If TSRow.Terms <> OldAgreement Then
				AgreementChanged = True;
			EndIf; 
			If Not ValueIsFilled(TSRow.Terms) Then
				AgreementsAreEmpty = True;
			EndIf;
		EndDo;
		If PartnerChanged Or AgreementChanged Or AgreementsAreEmpty Then
			OrderObject = New Structure("Partner, Terms, Currency, Warehouse, DateOfReceipt, OrderDate, VendorPriceKind");
			FillPropertyValues(OrderObject, Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]));
			OrderObject.Insert("Date", CurrentSessionDate);
			OrderObject.Insert("PriceIncludesVAT", True);
			
			PricesCalculated = WhenChangingAgreementOnServer(OrderObject, PartnerChanged Or AgreementsAreEmpty);
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
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

#Region BNDFormHandlers

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
	
	OpenForm("Document.PurchaseOrder.Form.DocumentsListForm"); 
	
EndProcedure

&AtClient
Procedure OpenListOfApplications(Command)
	
	OpenForm("Document.PurchaseRequest.Form.ListForm");
	
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
	OrderCreationParameters.Insert("SplitOrdersByOrderDates", SplitOrdersByOrderDates);
	OrderCreationParameters.Insert("SplitOrdersByDeliveryDates", SplitOrdersByDeliveryDates);
	OrderCreationParameters.Insert("SplitOrdersByAssignments", SplitOrdersByAssignments);
	OrderCreationParameters.Insert("SplitOrdersByWarehouses", SplitOrdersByWarehouses);
	OrderCreationParameters.Insert("SplitOrdersByPlanLines", SplitOrdersByPlanLines);
	OrderCreationParameters.Insert("DestinationVisibility", PlanningByAssignments And UseOrderSupplyWithAssignment);
	OrderCreationParameters.Insert("GeneratePurchaseRequests", GeneratePurchaseRequests);
	
	OpenForm("DataProcessor.GenerationOfPurchaseOrdersByPlans.Form.OrderCreationParameters", OrderCreationParameters, ThisForm);
	
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
Procedure FillInTheDepartment(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	Filter = New Structure("Department", True);
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);
	
	SelectedRows = New Array;
	For Each SelectedRow In Items.GenerationOfOrders.SelectedRows Do
		If Object.GenerationOfOrders.FindByID(SelectedRow).EditBusinessUnit Then
			SelectedRows.Add(SelectedRow);
		EndIf;
	EndDo;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn các dòng mà trong đó cho phép sửa bộ phận.';
								|ru = 'Выделите строки в которых разрешено редактирование подразделения.';
								|en = 'Select lines in which business unit editing is allowed.'; fa = 'Select lines in which business unit editing is allowed.';
								|it = 'Selezionate le righe in cui è consentita la modifica del reparto.';
								|pl = 'Wybierz wiersze w których jest dozwolona edycja działu.';
								|tr = 'Departmanın düzenlenmesine izin verilen satırları vurgulayınız.'"));
		Return;
	EndIf;
	
	LinkIsNotInList = GetDivisionsWithPlansOnSelectedLines(SelectedRows);
	
	Notification = New CallbackDescription("FillInTheDepartmentCompletion", 
		ThisObject, 
		New Structure("SelectedRows", SelectedRows));
	OpenForm("Catalog.BusinessStructure.ChoiceForm", 
		New Structure("Key, Filter, LinkIsNotInList", TableRow.Department, Filter, LinkIsNotInList),
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
	
	FilterStructure1 = New Structure("IsFolder", False);
	ParametersStructure = New Structure("Filter, ChoiceFoldersAndItems", FilterStructure1, FoldersAndItemsUse.Items);
	SelectedWarehouse = Undefined;

	OpenForm("Catalog.Warehouses.ChoiceForm", ParametersStructure, ThisForm,,,, New CallbackDescription("FillInTheWarehouseCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInTheSupplier(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	SelectedRows = New Array;
	For Each SelectedRow In Items.GenerationOfOrders.SelectedRows Do
		If Object.GenerationOfOrders.FindByID(SelectedRow).EditPartner Then
			SelectedRows.Add(SelectedRow);
		EndIf;
	EndDo;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn các dòng mà trong đó cho phép sửa nhà cung cấp.';
								|ru = 'Выделите строки в которых разрешено редактирование поставщика.';
								|en = 'Select lines in which you can edit the vendor.'; fa = 'Select lines in which you can edit the vendor.';
								|it = 'Selezionate le righe in cui è consentita la modifica del fornitore.';
								|pl = 'Wybierz wiersze w których jest dozwolona edycja dostawcy.';
								|tr = 'Tedarikçinin düzenlenmesine izin verilen satırları vurgulayınız.'"));
		Return;
	EndIf;
	
	Filter = New Structure("Vendor", True);
	TableRow = Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]);
	Partner = Undefined;
	
	Notification = New CallbackDescription("FillInTheSupplierCompletion", 
		ThisObject, 
		New Structure("TableRow, SelectedRows", TableRow, SelectedRows));
	OpenForm("Catalog.Partners.ChoiceForm", 
		New Structure("Key, Filter", TableRow.Partner, Filter),
		,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInPricesBySupplierPriceType(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	OrderObject = New Structure("Partner, Terms, Currency, Warehouse, DateOfReceipt, OrderDate, VendorPriceKind");
	FillPropertyValues(OrderObject, Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]));
	
	OrderObject.Insert("SelectedRows", Items.GenerationOfOrders.SelectedRows);
	OrderObject.Insert("Date", CurrentSessionDate);
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(OrderObject, "SelectedRows", NStr("vi = 'dòng đã tách';
																															|ru = 'выделенных строк';
																															|en = 'selected rows'; fa = 'selected rows';
																															|it = 'delle righe selezionate';
																															|pl = 'wybranych wierszy';
																															|tr = 'seçili satırları'")) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("OrderObject", OrderObject);
		PartnerPricesFillingClient.SelectVendorsPriceType(
			New CallbackDescription("FillInPricesBySupplierPriceTypeSelectionSupplierPriceTypeCompletion", ThisObject, AdditionalParameters),
			OrderObject.Partner);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillOutTheAgreement(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	SelectedRows = New Array;
	For Each SelectedRow In Items.GenerationOfOrders.SelectedRows Do
		If Object.GenerationOfOrders.FindByID(SelectedRow).EditTermsOfPurchase Then
			SelectedRows.Add(SelectedRow);
		EndIf;
	EndDo;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn các dòng mà trong đó cho phép soạn thỏa thuận.';
								|ru = 'Выделите строки в которых разрешено редактирование соглашения.';
								|en = 'Select lines in which agreement editing is allowed.'; fa = 'Select lines in which agreement editing is allowed.';
								|it = 'Selezionate le righe in cui è consentita la modifica dell''accordo.';
								|pl = 'Wybierz wiersze w których jest dozwolona edycja umowy.';
								|tr = 'Anlaşmanın düzenlenmesine izin verilen satırları belirle.'"));
		Return;
	EndIf;
	
	FirstRow = Object.GenerationOfOrders.FindByID(SelectedRows[0]);
	Partner = FirstRow.Partner;
	If Not ValueIsFilled(Partner) Then
		FilterStructure1 = New Structure("Vendor", True);
		ParametersStructure = New Structure("Filter", FilterStructure1);
		Notification = New CallbackDescription(
			"FillInAgreementAfterChoosingPartner", 
			ThisObject, 
			New Structure("SelectedRows, FirstRow, ParametersStructure", 
				SelectedRows, 
				FirstRow, 
				ParametersStructure));
		OpenForm("Catalog.Partners.ChoiceForm", 
			ParametersStructure, 
			ThisForm,
			,
			,
			,
			Notification, 
			FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf; 
	FillInThisSnippet_(SelectedRows, Partner, FirstRow);
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
Procedure SetDateOfReceipt(Command)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
		Return;
	EndIf;
	
	Notification = New CallbackDescription("SetDateOfReceiptCompletion", ThisObject);
	
	ShowInputDate(Notification, 
		Items.GenerationOfOrders.CurrentData.DateOfReceipt,
		NStr("vi = 'Hãy nhập ngày tiếp nhận';
			|ru = 'Введите дату поступления';
			|en = 'Enter date of receipt'; fa = 'Enter date of receipt';
			|it = 'Inserire la data di arrivo';
			|pl = 'Wprowadź datę wpłaty';
			|tr = 'Teslim alma tarihini girin'"),
		DateFractions.Date);
		
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
	FormParameters.Insert("DateOfReceipt", Items.GenerationOfOrders.CurrentData.DateOfReceipt);
	FormParameters.Insert("PlanningType", "PurchasePlanning");

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
	
	ClearMessages();
	
	If Items.PagesMainPanel.CurrentPage = Items.PageStep1 Then
		
		If Items.PagesFilterOptions.CurrentPage = Items.PageRandomFilters Then
			ReflectLayoutSelectionInSimpleSelections();
		EndIf;
		
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
		
	ElsIf Items.PagesMainPanel.CurrentPage = Items.PageStep2 Then 
		
		UpdateOrderCart();
		
		If OrderBasket.Count() = 0 Then
			
			If GeneratePurchaseRequests Then
				
				ErrorText = NStr("vi = 'Không có yêu cầu cần lập. Hãy đặt dấu số lượng tại cột 
					|""Trong yêu cầu"" đối với mặt hàng cần đặt.';
					|ru = 'Нет заявок к оформлению. Отметьте флажком количество в колонке 
					|""В заявку"" для номенклатуры которую необходимо заказать.';
					|en = 'No requests for registration. Select quantity in
					|the ""To request"" column for items which should be ordered.'; fa = 'No requests for registration. Select quantity in
					|the ""To request"" column for items which should be ordered.';
					|it = 'No requests for registration. Select quantity in
					|the ""To request"" column for items which should be ordered.';
					|pl = 'No requests for registration. Select quantity in
					|the ""To request"" column for items which should be ordered.';
					|tr = 'Düzenlenecek talep mevcut değil. Sipariş edilmesi gereken ürünler için 
					| ""Talebe ekle"" sütunundaki miktarı işaretleyiniz.'");
				
			Else
				
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
				
			EndIf;
			
			ShowMessageBox(,ErrorText);
			
			Return;
			
		EndIf;
		
		CreateOrdersOnServer();
		
		TMCommonUseClientServer.GetDynamicListSelection(List).Items.Clear();
		TMCommonUseClientServer.GetDynamicListSelection(ListOfPurchaseRequests).Items.Clear();
		
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
		
		CommonClientServer.SetDynamicListFilterItem(
			ListOfPurchaseRequests,
			"Ref",
			GeneratedOrders,
			DataCompositionComparisonType.InList,
			NStr("vi = 'Giấy đề nghị đã lập';
				|ru = 'Сформированные заявки';
				|en = 'Generated requests'; fa = 'Generated requests';
				|it = 'Generated requests';
				|pl = 'Generated requests';
				|tr = 'Oluşturulan talepler'"),
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
		Items.PagesMainPanel.CurrentPage = Items.PageStep3;
		
		SetFormHeader(Items.PagesMainPanel.CurrentPage);
		SetVisibilityOfCommandPanelButtons(Items.PagesMainPanel.CurrentPage);
	EndIf;
	
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
	ItemField.Field = New DataCompositionField(Items.Manager.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneratePurchaseRequests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Manager");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersDateOfReceipt.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("Object.GenerationOfOrders.Period.EndDate");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Object.GenerationOfOrders.Period.StartDate");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.EditBusinessUnit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.EditPartner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GenerationOfOrdersTerms.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GenerationOfOrders.EditTermsOfPurchase");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
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
	
	// Order Shopping Cart

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderBasketPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneratePurchaseRequests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderBasket.NumberOfPartners");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<một số giá trị>';
													|ru = '<несколько значений>';
													|en = '<multiple values>'; fa = '<multiple values>';
													|it = '<multiple values>';
													|pl = '<multiple values>';
													|tr = '<birden fazla değer>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderBasketTerms.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneratePurchaseRequests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderBasket.NumberOfAgreements");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<một số giá trị>';
													|ru = '<несколько значений>';
													|en = '<multiple values>'; fa = '<multiple values>';
													|it = '<multiple values>';
													|pl = '<multiple values>';
													|tr = '<birden fazla değer>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.GenerationOfOrdersWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "Object.GenerationOfOrders.ItemsType";
	ConditionalDesignParameters.ToCheckWhetherWarehouseIsFull = True;
	
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);
	
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
		
		If GeneratePurchaseRequests Then
			Items.Subtitle.Title = NStr("vi = 'Bước 2 trong số 3. Xác định thành phần giấy đề nghị';
										|ru = 'Шаг 2 из 3. Определение состава заявок';
										|en = 'Step 2 of 3. Determine requests'; fa = 'Step 2 of 3. Determine requests';
										|it = 'Step 2 of 3. Determine requests';
										|pl = 'Step 2 of 3. Determine requests';
										|tr = 'Adım 2/3. Talep içeriğinin belirlenmesi'");
		Else
			Items.Subtitle.Title = NStr("vi = 'Bước 2/3. Xác định thành phần và khối lượng đơn hàng';
										|ru = 'Шаг 2 из 3. Определение состава и объема заказа';
										|en = 'Step 2 of 3. Define what to order and how much to order'; fa = 'Step 2 of 3. Define what to order and how much to order';
										|it = 'Passaggio 2 di 3. Determinare la composizione e il volume dell''ordine';
										|pl = 'Krok 2 z 3. Określenie składu i objętości zamówienia';
										|tr = '3 adım arasından 2. adım. Siparişin içeriğinin ve hacminin belirlenmesi'");
		EndIf;
		
	ElsIf Page = Items.PageStep3 Then
		
		If GeneratePurchaseRequests Then
			Items.Subtitle.Title = NStr("vi = 'Bước 3/3. Làm rõ các giấy đề nghị đã lập';
										|ru = 'Шаг 3 из 3. Уточнение сформированных заявок';
										|en = 'Step 3 of 3. Specify generated requests'; fa = 'Step 3 of 3. Specify generated requests';
										|it = 'Step 3 of 3. Specify generated requests';
										|pl = 'Step 3 of 3. Specify generated requests';
										|tr = 'Adım 3/3. Oluşturulan taleplerin netleştirilmesi'");
		Else
			Items.Subtitle.Title = NStr("vi = 'Bước 3/3. Làm rõ đơn hàng đã tạo';
										|ru = 'Шаг 3 из 3. Уточнение сформированных заказов';
										|en = 'Step 3 of 3. Specify generated orders'; fa = 'Step 3 of 3. Specify generated orders';
										|it = 'Passaggio 3 di 3. Perfezionamento degli ordini generati';
										|pl = 'Krok 3 z 3. Uściślenie utworzonych zamówień';
										|tr = 'Adım 3/3. Oluşturulan siparişlerin netleştirilmesi'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	Items.FormToDisplayTheOrdersToTheDesign.Check = DisplayOrdersForRegistration;
	Items.GroupOrdersToBeProcessed.Visible        = DisplayOrdersForRegistration;
	
	DestinationVisibility = PlanningByAssignments And UseOrderSupplyWithAssignment;
	Items.OrderBasketPurpose.Visible                      = SplitOrdersByAssignments And DestinationVisibility;
	
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

&AtClient
Procedure SetAvailability()
	
	Items.Terms.Enabled = ValueIsFilled(Object.Partner);
	
EndProcedure 

&AtClientAtServerNoContext
Procedure VisibilitySettingsWhenChangingSubdividingSelectionOnServer(Form)
	
	VisibilityOfDivisionColumns = Not (Form.FilterDepartments
		And ValueIsFilled(Form.Object.Department));
	Form.Items.GenerationOfOrdersDepartment.Visible = VisibilityOfDivisionColumns;
	Form.Items.GenerationOfOrdersFillInTheDepartment.Visible = VisibilityOfDivisionColumns;
	Form.Items.OrderBasketDepartment.Visible = VisibilityOfDivisionColumns;
	Form.Items.Department.Enabled = Form.FilterDepartments;
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilitySettingsWhenChangingScript(Form)
	
	DestinationVisibility = Form.PlanningByAssignments And Form.UseOrderSupplyWithAssignment;
	Form.Items.Purpose.Visible = DestinationVisibility;
	Form.Items.GenerationOfOrdersPurpose.Visible = DestinationVisibility;
	Form.Items.OrderBasketPurpose.Visible = DestinationVisibility And Form.SplitOrdersByAssignments;
	
EndProcedure

#EndRegion

#Region ProceduresForWorkingWithUserSettings

&AtServer
Procedure InitializeSettingsComposer()
	
	If Object.DemandCalculationModeByPlan = 0
		Or Object.DemandCalculationModeByPlan = 1 Then
		DataCompositionSchema = DataProcessors.GenerationOfPurchaseOrdersByPlans.GetTemplate("CompositionTemplate");
	Else
		DataCompositionSchema = DataProcessors.GenerationOfPurchaseOrdersByPlans.GetTemplate("CompositionTemplateAccumulated");
		
		DataLayoutSchemeQuantityInPlans = DataProcessors.GenerationOfPurchaseOrdersByPlans.GetTemplate("CompositionTemplateQuantityInPlans");
		SetQueryTextOfPurchaseRequest(DataLayoutSchemeQuantityInPlans);
		AddressOfDataCompositionSchemaPlannedQuantity = PutToTempStorage(DataLayoutSchemeQuantityInPlans, New UUID);
		
		DataLayoutDiagramQuantityInOrders = DataProcessors.GenerationOfPurchaseOrdersByPlans.GetTemplate("CompositionTemplateQuantityInOrders");
		SetQueryTextOfPurchaseRequest(DataLayoutDiagramQuantityInOrders);
		AddressOfDataCompositionSchemaQuantityInOrders = PutToTempStorage(DataLayoutDiagramQuantityInOrders, New UUID);
		
	EndIf;
	
	SetQueryTextOfPurchaseRequest(DataCompositionSchema);
	
	QueryText = DataCompositionSchema.DataSets.Plans.Query;
	QueryText = Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False)
		+ InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
			QueryText,
			"MainSupplyMethodSubstitution",
			"PurchasePlansTurnovers.Products, PurchasePlansTurnovers.Characteristic, PurchasePlansTurnovers.Warehouse");
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
		"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
	QueryText = StrReplace(QueryText,
		"&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"CatProducts.UnitOfMeasure",
		"CatProducts"));
	QueryText = StrReplace(QueryText,
	"&QueryTextOrderPackingRatio",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"PurchaseConditions.Package",
		"PurchaseConditions.Products"));
		
	DataCompositionSchema.DataSets.Plans.Query = QueryText;
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	
	If TypeOf(SettingsValue) = Type("Structure")
		And SettingsValue.Property("UserSettings") Then
		SettingsComposer.LoadUserSettings(SettingsValue.UserSettings);
	EndIf;
	
	PlanningByAssignments = Common.ObjectAttributeValue(Object.Scenario, "PlanningByAssignments");
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "Department", Object.Department);
	DataCompositionClientServer.SetParameter(SettingsComposer, "Scenario", Object.Scenario);
	DataCompositionClientServer.SetParameter(SettingsComposer, "PlanningByAssignments", PlanningByAssignments);
	DataCompositionClientServer.SetParameter(SettingsComposer, "Purpose", Object.Purpose);
	DataCompositionClientServer.SetParameter(SettingsComposer, "FilterByAssignment", ValueIsFilled(Object.Purpose));
	
	ThisIsGroupSelection = ThisIsGroupSelection(Object.Warehouse, FilterByGroup);
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Warehouse", Object.Warehouse, ThisIsGroupSelection);
	ThisIsGroupSelection = ThisIsGroupSelection(Object.Partner, FilterByGroup);
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Vendor", Object.Partner, ThisIsGroupSelection);
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Terms", Object.Terms, False);
	
EndProcedure

&AtClient
Procedure ShouldSaveSettings()
	
	Settings = New Structure();
	Settings.Insert("UserSettings",  SettingsComposer.UserSettings);
	Settings.Insert("Scenario",                   Object.Scenario);
	Settings.Insert("PeriodBeginning",               Object.PeriodBeginning);
	Settings.Insert("PeriodEnd",            Object.PeriodEnd);
	Settings.Insert("Department",              Object.Department);
	Settings.Insert("FilterDepartments",         FilterDepartments);
	
	Settings.Insert("Partner",                    Object.Partner);
	Settings.Insert("ProductSegment",        Object.ProductSegment);
	
	Settings.Insert("Terms",                 Object.Terms);
	Settings.Insert("Warehouse",                      Object.Warehouse);
	Settings.Insert("Products",               Object.Products);
	
	Settings.Insert("DemandCalculationModeByPlan",    Object.DemandCalculationModeByPlan);
		
	Settings.Insert("SplitOrdersByAssignments", SplitOrdersByAssignments);
	Settings.Insert("Purpose",                   Object.Purpose);
	
	SaveSettingsAtServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(Settings)
	
	ObjectKey = "DataProcessor.GenerationOfPurchaseOrdersByPlans";
	Common.CommonSettingsStorageSave(ObjectKey, "Settings", Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.GenerationOfPurchaseOrdersByPlans", "Settings");
	
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		FillPropertyValues(Object, SettingsValue);
		FillPropertyValues(ThisForm, SettingsValue);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresCommandHandlersCompletion

&AtClient
Procedure SetPeriodIntervalCompletion(Result, AdditionalParameters) Export 
	
	PeriodStartPeriodEndWhenModified();
	
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
	
	StartWaiting = FillAtServer();
	
	If StartWaiting Then
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("UpdateInBackgroundCompletion", ThisObject),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
		
	Else
		
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
		
		If Object.GenerationOfOrders.Count() > 0 Then
			Items.PagesMainPanel.CurrentPage = Items.PageStep2;
		EndIf;
		
		SetFormHeader(Items.PagesMainPanel.CurrentPage);
		SetVisibilityOfCommandPanelButtons(Items.PagesMainPanel.CurrentPage);
	EndIf;
	
EndProcedure

&AtServer
Function FillAtServer()
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	Periodicity = Common.ObjectAttributeValue(Object.Scenario, "Periodicity");
	DataCompositionClientServer.SetParameter(SettingsComposer, "Periodicity", Periodicity);
	
	ProcedureParameters = New Structure("DataCompositionSettings,DataCompositionSchema",
											SettingsComposer.GetSettings(),
											GetFromTempStorage(AddressOfDataCompositionSchema));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Điền danh sách mua hàng đã lập kế hoạch';
			|ru = 'Заполнение списка запланированных закупок';
			|en = 'Fill the list of planned purchases'; fa = 'Fill the list of planned purchases';
			|it = 'Compilazione elenco degli acquisti pianificati';
			|pl = 'Wypełnienie listy zaplanowanych zakupów';
			|tr = 'Planlanan alımların listesini doldurma'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.GenerationOfPurchaseOrdersByPlans.UpdatePlannedPurchases",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartWaiting = True;
		
	Else
		
		ProcessResultFillInBackground(TimeConsumingOperation);
		
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtServer
Procedure ProcessResultFillInBackground(Result)
	
	If Result.Status = "Error" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(ResultStructure) = Type("Structure") And ResultStructure.Property("Messages") Then
			
			For Each Message In ResultStructure.Messages Do
			
				Message.TargetID = UUID;
				Message.Message();
				
			EndDo;
			
		EndIf;
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
	ResultTable2 = GetFromTempStorage(Result.ResultAddress);
	
	TableOrderGeneration.Load(ResultTable2);
	If FilterDepartments Then
		TableFormationOfOrdersWithSelection = ResultTable2.Copy(New Structure("Department", Object.Department));
	Else
		TableFormationOfOrdersWithSelection = ResultTable2;
	EndIf;
	
	Object.GenerationOfOrders.Load(TableFormationOfOrdersWithSelection);
	
	For Each OrderLine In Object.GenerationOfOrders Do
		
		OrderLine.Period.StartDate 		= OrderLine.DateOfReceipt;  
		OrderLine.Period.EndDate 	= OrderLine.ReceiptPeriodEnd;  
		
	EndDo;
	
	FillInDefaultCurrency();
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
	SetFormItemsVisibility();
	
EndProcedure

&AtClient
Procedure UpdateInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ProcessResultFillInBackground(Result);
		
		If Object.GenerationOfOrders.Count() = 0 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có kế hoạch đã phê duyệt cho kịch bản %1 tương ứng với bộ lọc thiết lập. Cần thay đổi bộ lọc.';
					|ru = 'Нет утвержденного плана для сценария %1, соответствующего установленным отборам. Необходимо изменить отборы.';
					|en = 'There is no confirmed plan for the %1scenario corresponding to the set filters. Change the filters.'; fa = 'There is no confirmed plan for the %1scenario corresponding to the set filters. Change the filters.';
					|it = 'Non esiste un piano approvato per lo scenario %1, che corrisponda ai filtri impostati. È necessario modificare i filtri.';
					|pl = 'Brak zatwierdzonego planu dla scenariusza %1, odpowiadającego ustawionym selekcjom. Należy zmienić selekcje.';
					|tr = '%1 senaryosu için belirlenen filtrelerle uyumlu onaylanmış plan yok. Filtrelerin değiştirilmesi gerekmektedir.'"),
				Object.Scenario);
			ShowMessageBox(, ErrorText);
		EndIf;
		
		If Object.GenerationOfOrders.Count() > 0 Then
			Items.PagesMainPanel.CurrentPage = Items.PageStep2;
		EndIf;
		
		SetFormHeader(Items.PagesMainPanel.CurrentPage);
		SetVisibilityOfCommandPanelButtons(Items.PagesMainPanel.CurrentPage);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheDepartmentCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	Department = Result;
	
	If Not ValueIsFilled(Department) Then
		Return;
	EndIf; 
	
	DivisionChanged = False;
	
	For Each SelectedRow In SelectedRows Do
		
		TableRow = Object.GenerationOfOrders.FindByID(SelectedRow);
		
		If TableRow.Department <> Department Then
			DivisionChanged = True;
			TableRow.Department = Department;
		EndIf;
		
	EndDo;
	
	If DivisionChanged And DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheSupplierCompletion(Result, AdditionalParameters) Export
	
	TableRow = AdditionalParameters.TableRow;
	
	
	Partner = Result;
	
	If Not ValueIsFilled(Partner) Then
		Return;
	EndIf; 
	
	If TableRow.Partner <> Partner Then
		Terms = Undefined;
	Else 
		Terms = TableRow.Terms;
	EndIf;
	PartnerChanged     = False;
	AgreementChanged = False;
	AgreementsAreEmpty   = False;
	
	For Each SelectedRow In AdditionalParameters.SelectedRows Do
		
		TableRow = Object.GenerationOfOrders.FindByID(SelectedRow);
		OldAgreement = TableRow.Terms;
		
		If TableRow.Partner <> Partner Then
			TableRow.Terms        = Undefined;
			TableRow.VendorPriceKind = Undefined;
			PartnerChanged = True;
		EndIf;
		TableRow.Partner = Partner;
		If ValueIsFilled(Terms) Then
			TableRow.Terms = Terms;
		EndIf;
		If TableRow.Terms <> OldAgreement Then
			AgreementChanged = True;
		EndIf; 
		If Not ValueIsFilled(TableRow.Terms) Then
			AgreementsAreEmpty = True;
		EndIf; 
		
	EndDo;
	
	If PartnerChanged Or AgreementChanged Or AgreementsAreEmpty Then
		OrderObject = New Structure("Partner, Terms, Currency, Warehouse, DateOfReceipt, OrderDate, VendorPriceKind");
		FillPropertyValues(OrderObject, Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]));
		OrderObject.Insert("Date", CurrentSessionDate);
		OrderObject.Insert("PriceIncludesVAT", True);
		
		PricesCalculated = WhenChangingAgreementOnServer(OrderObject, PartnerChanged Or AgreementsAreEmpty);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	Else
		If DisplayOrdersForRegistration Then
			UpdateOrderCart();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure FillInPricesBySupplierPriceTypeSelectionSupplierPriceTypeCompletion(VendorPriceKind, AdditionalParameters) Export
	
	If ValueIsFilled(VendorPriceKind) Then
		
		For Each String In Items.GenerationOfOrders.SelectedRows Do
			OrderLine = Object.GenerationOfOrders.FindByID(String);
			OrderLine.Partner = AdditionalParameters.OrderObject.Partner;
			OrderLine.Terms = AdditionalParameters.OrderObject.Terms;
		EndDo;
		
		PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(AdditionalParameters.OrderObject, VendorPriceKind);
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, VendorPriceKind);
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(OrderObject, VendorPriceKind)
	
	RowsArray = New Array;
	For Each String In Items.GenerationOfOrders.SelectedRows Do
		RowsArray.Add(Object.GenerationOfOrders.FindByID(String));
	EndDo;
	
	If TypeOf(OrderObject) = Type("Structure") Then
		OrderObject.Insert("PriceIncludesVAT", Common.ObjectAttributeValue(VendorPriceKind, "PriceIncludesVAT"));
	EndIf;
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, OrderObject);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price, VendorPriceKind");
	FillParameters.Insert("Date", OrderObject.Date);
	FillParameters.Insert("Currency", OrderObject.Currency);
	FillParameters.Insert("VendorPriceKind", VendorPriceKind);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.GenerationOfOrders,
		RowsArray,
		FillParameters,
		StructureOfActions);
		
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure FillInAgreementAfterChoosingPartner(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	FirstRow = AdditionalParameters.FirstRow;
	ParametersStructure = AdditionalParameters.ParametersStructure;
	
	Partner = Result;
	
	FillInThisSnippet_(SelectedRows, Partner, FirstRow);
	
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
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.GenerationOfOrders, ArrayOfSelectedRows, Warehouse);
	If DisplayOrdersForRegistration And SplitOrdersByWarehouses Then
		UpdateOrderCart();
	EndIf;
	
	Return FilledWithRows
EndFunction

&AtClient
Procedure FillInThisSnippet_(Val SelectedRows, Val Partner, Val FirstRow)
	
	If Not ValueIsFilled(Partner) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa chọn nhà cung cấp.';
				|ru = 'Не выбран поставщик.';
				|en = 'Vendor is not selected.'; fa = 'Vendor is not selected.';
				|it = 'Fornitore non selezionato.';
				|pl = 'Nie wybrano dostawcy.';
				|tr = 'Tedarikçi seçilmedi.'"),
			,
			CommonClientServer.PathToTabularSection("GenerationOfOrders",FirstRow.LineNumber, "Partner"),
			"Object");
		Return;
	EndIf; 
	
	FilterStructure1 = New Structure("Partner", Partner);
	ParametersStructure = New Structure("Filter, AvailableForPurchase", FilterStructure1, True);
	
	Notification = New CallbackDescription("FillOutTheAgreementCompletion", 
		ThisObject, 
		New Structure("SelectedRows, Partner", SelectedRows, Partner));
	OpenForm("Catalog.TermsOfPurchaseFromVendors.ChoiceForm", 
		ParametersStructure, 
		ThisForm,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure FillOutTheAgreementCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	Partner = AdditionalParameters.Partner;
	
	Terms = Result;
	If ValueIsFilled(Terms) Then
		
		ChangedAgreement = False;
		
		For Each CurRow In SelectedRows Do
			TableRow = Object.GenerationOfOrders.FindByID(CurRow);
			If TableRow.Terms <> Terms Then
				ChangedAgreement = True;
			EndIf; 
			TableRow.Partner = Partner;
			TableRow.Terms = Terms;
		EndDo; 
		
		If ChangedAgreement Then
			OrderObject = New Structure("Partner, Terms, Currency, Warehouse, DateOfReceipt, OrderDate, VendorPriceKind");
			FillPropertyValues(OrderObject, Object.GenerationOfOrders.FindByID(Items.GenerationOfOrders.SelectedRows[0]));
			OrderObject.Insert("Date", CurrentSessionDate);
			OrderObject.Insert("PriceIncludesVAT", True);
			
			PricesCalculated = WhenChangingAgreementOnServer(OrderObject, ChangedAgreement);
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
			
		Else
			If DisplayOrdersForRegistration Then
				UpdateOrderCart();
			EndIf;
		EndIf; 
		
	EndIf;
	
EndProcedure

// Calculates selected lines when the agreement is changed
&AtServer
Function WhenChangingAgreementOnServer(OrderObject, FillInAgreements = False)

	RowsArray = New Array;
	For Each String In Items.GenerationOfOrders.SelectedRows Do
		RowsArray.Add(Object.GenerationOfOrders.FindByID(String));
	EndDo;
	
	If FillInAgreements Then
		
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(OrderObject.Partner, New Structure("ConsiderWarehouseGroups, SelectedAgreement", True, OrderObject.Terms));
		
		If DefaultPurchasingConditions <> Undefined And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
			For Each TSRow In RowsArray Do
				TSRow.Terms = DefaultPurchasingConditions.Terms;
				TSRow.Currency = DefaultPurchasingConditions.Currency;
				If Not ValueIsFilled(TSRow.Warehouse) And ValueIsFilled(DefaultPurchasingConditions.Warehouse) Then
					TSRow.Warehouse = DefaultPurchasingConditions.Warehouse;
				EndIf;
			EndDo;
			OrderObject.Terms = DefaultPurchasingConditions.Terms;
			OrderObject.Currency = DefaultPurchasingConditions.Currency;
			If Not ValueIsFilled(OrderObject.Warehouse) And ValueIsFilled(DefaultPurchasingConditions.Warehouse) Then
				OrderObject.Warehouse = DefaultPurchasingConditions.Warehouse;
			EndIf;
			OrderObject.PriceIncludesVAT = DefaultPurchasingConditions.PriceIncludesVAT;
		EndIf; 
	
	EndIf; 
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, OrderObject);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price, VATRate, VendorPriceKind");
	FillParameters.Insert("Date", OrderObject.Date);
	FillParameters.Insert("Currency", OrderObject.Currency);
	FillParameters.Insert("Terms", OrderObject.Terms);
	FillParameters.Insert("VendorPriceKind", OrderObject.VendorPriceKind);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.GenerationOfOrders,
		RowsArray,
		FillParameters,
		StructureOfActions);
	
	If DisplayOrdersForRegistration Then
		UpdateOrderCart();
	EndIf;
	
	Return PricesCalculated;

EndFunction

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
Procedure SetDateOfReceiptCompletion(Date, AdditionalParameters) Export 
	
	If Date = Undefined Then
		Return;
	EndIf;
	
	For Each CurrentRow In Items.GenerationOfOrders.SelectedRows Do
		TSRow = Object.GenerationOfOrders.FindByID(CurrentRow);
		TSRow.DateOfReceipt = Date;
	EndDo;
	
EndProcedure

#EndRegion

#Region ProceduresForObtainingPlansAndOrders

&AtServerNoContext
Function ListOfPlansByLine(RowKey)

	Query = New Query();
	Query.Text = 
	"SELECT ALLOWED
	|	SUM(PurchasePlans.ToOrder) AS Count,
	|	PurchasePlans.PurchasePlan AS Document,
	|	DocPurchasePlan.PointInTime AS PointInTime,
	|	DocPurchasePlan.Date AS DocumentDate,
	|	DocPurchasePlan.Number AS DocumentNumber,
	|	PurchasePlans.Partner,
	|	PurchasePlans.Terms
	|FROM
	|	AccumulationRegister.PurchasePlans AS PurchasePlans
	|		INNER JOIN Document.PurchasePlan AS DocPurchasePlan
	|		ON PurchasePlans.PurchasePlan = DocPurchasePlan.Ref
	|		
	|		LEFT JOIN Catalog.PlanProfiles AS PlanProfiles
	|		ON DocPurchasePlan.PlanProfile = PlanProfiles.Ref
	|		AND (PlanProfiles.FillInPartner OR PlanProfiles.FillInPartnerInTabularForm)
	|		AND (PlanProfiles.FillInTermsOfSales OR PlanProfiles.FillInAgreementInTabularForm)
	|WHERE
	|	PurchasePlans.Period = &BeginOfPeriod
	|	AND PurchasePlans.Products = &Products
	|	AND PurchasePlans.Characteristic = &Characteristic
	|	AND PurchasePlans.Warehouse = &Warehouse
	|	AND PurchasePlans.Purpose = &Purpose
	|	AND PurchasePlans.Scenario = &Scenario
	|	AND PurchasePlans.Department = &Department
	|	AND (PlanProfiles.Ref IS NULL OR PurchasePlans.Partner = &Partner)
	|	AND (PlanProfiles.Ref IS NULL OR PurchasePlans.Terms = &Terms)
	|
	|GROUP BY
	|	PurchasePlans.PurchasePlan,
	|	PurchasePlans.OrderDate,
	|	DocPurchasePlan.PointInTime,
	|	DocPurchasePlan.Date,
	|	DocPurchasePlan.Number,
	|	PurchasePlans.Partner,
	|	PurchasePlans.Terms
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
			NStr("vi = '%1 (Số %2 ngày %3) Bạn hàng: %4 %5';
				|ru = '%1 (№ %2 от %3) Партнер: %4 %5';
				|en = '%1 (No. %2 from %3) Partner: %4 %5'; fa = '%1 (No. %2 from %3) Partner: %4 %5';
				|it = '%1 (№ %2 del %3) Partner: %4 %5';
				|pl = '%1 (nr %2 z dn. %3) Partner: %4 %5';
				|tr = '%1 ( %3itibarıyla %2numaralı) İş ortağı: %4 %5'"), 
				Format(Selection.Count, "NFD=3"), Selection.DocumentNumber, 
				Format(Selection.DocumentDate, "DLF=D"), ?(ValueIsFilled(Selection.Partner),Selection.Partner, "<IsEmpty>"), 
				Selection.Terms);
		DocumentsList.Add(Selection.Document, DocumentPresentation);
		
	EndDo;
	
	Return DocumentsList;
	
EndFunction

&AtServer
Function ListOfPlansIsCumulativeByLine(RowKey)

	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchemaPlannedQuantity);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchemaPlannedQuantity);
	SettingsComposerQuantityInPlansInOrders.Initialize(SettingsSource);
	SettingsComposerQuantityInPlansInOrders.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Scenario", Object.Scenario);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Periodicity", Periodicity);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Department", RowKey.Department);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Partner", RowKey.Partner);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Warehouse", RowKey.Warehouse);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Terms", RowKey.Terms);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Products", RowKey.Products);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Characteristic", RowKey.Characteristic);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Purpose", RowKey.Purpose);
	If Object.DemandCalculationModeByPlan = 0
		Or Object.DemandCalculationModeByPlan = 2 Then
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "OrderStartDate", Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "OrderEndDate", Object.PeriodEnd);
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "BeginOfPeriod", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "PeriodEnding", Date("00010101"));
	Else
		
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "OrderStartDate", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "OrderEndDate", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "BeginOfPeriod", Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "PeriodEnding", Object.PeriodEnd);
	EndIf;
	
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, SettingsComposerQuantityInPlansInOrders.GetSettings(), , ,Type("DataCompositionValueCollectionTemplateGenerator") , False, );
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate,,, True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor();
	ResultTable2 = OutputProcessor.Output(CompositionProcessor);
	
	DocumentsList = New ValueList();
	For Each String In ResultTable2 Do
		
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (Số %2 ngày %3) Bạn hàng: %4 %5';
				|ru = '%1 (№ %2 от %3) Партнер: %4 %5';
				|en = '%1 (No. %2 from %3) Partner: %4 %5'; fa = '%1 (No. %2 from %3) Partner: %4 %5';
				|it = '%1 (№ %2 del %3) Partner: %4 %5';
				|pl = '%1 (nr %2 z dn. %3) Partner: %4 %5';
				|tr = '%1 ( %3itibarıyla %2numaralı) İş ortağı: %4 %5'"), 
				Format(String.Count, "NFD=3"), String.DocumentNumber, 
				Format(String.DocumentDate, "DLF=D"), ?(ValueIsFilled(String.Partner),String.Partner, "<IsEmpty>"), 
				String.Terms);
		DocumentsList.Add(String.Document, DocumentPresentation);

	EndDo;
	
	Return DocumentsList;
	
EndFunction

&AtServer
Function ListOfOrdersByLine(RowKey)
	
	QueriesTexts = New Array;
	
	QueryText = 
	"SELECT
	|	&DateOfReceipt AS DateOfReceipt,
	|	&EndOfDayEndOfReceiptPeriod AS ReceiptPeriodEnd,
	|	&Products AS Products,
	|	&Characteristic AS Characteristic,
	|	&Warehouse AS Warehouse,
	|	&Purpose AS Purpose,
	|	&Department AS Department,
	|	&Partner AS PartnerPlan,
	|	&Terms AS Terms,
	|	&Terms AS AgreementPlan
	|INTO TableOfPlans";
	QueriesTexts.Add(QueryText);
	
	QueryText = Documents.PurchaseRequest.QueryTextBalancesOfPurchaseRequestsAccordingToPlans(
		"TableOfPlans",
		"PurchaseRequestsBalance");
	QueriesTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	SUM(TablePlansOrders.Count) AS Count,
	|	TablePlansOrders.Document AS Document,
	|	VALUETYPE(TablePlansOrders.Document) AS DocumentType,
	|	TablePlansOrders.DocumentDate AS DocumentDate,
	|	TablePlansOrders.DocumentNumber AS DocumentNumber,
	|	TablePlansOrders.Partner AS Partner,
	|	TablePlansOrders.Terms AS Terms
	|FROM
	|	(SELECT
	|		PurchaseOrderGoods.Count AS Count,
	|		PurchaseOrder.Ref AS Document,
	|		PurchaseOrder.Date AS DocumentDate,
	|		PurchaseOrder.Number AS DocumentNumber,
	|		PurchaseOrder.Partner AS Partner,
	|		PurchaseOrder.Terms AS Terms
	|	FROM
	|		Document.PurchaseOrder.Goods AS PurchaseOrderGoods
	|			INNER JOIN Document.PurchaseOrder AS PurchaseOrder
	|			ON PurchaseOrderGoods.Ref = PurchaseOrder.Ref
	|				AND (PurchaseOrder.Posted)
	|				AND (NOT PurchaseOrder.Department IN (&DivisionsForWhichThereArePlans))
	|			INNER JOIN TableOfPlans AS TableOfPlans
	|			ON (TableOfPlans.Products = PurchaseOrderGoods.Products)
	|				AND (NOT PurchaseOrderGoods.Canceled)
	|				AND (TableOfPlans.Characteristic = PurchaseOrderGoods.Characteristic)
	|				AND (CASE
	|					WHEN TableOfPlans.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|						THEN TRUE
	|					ELSE TableOfPlans.Warehouse = PurchaseOrderGoods.Warehouse
	|				END)
	|				AND (CASE
	|					WHEN NOT &PlanningByAssignments
	|						THEN TRUE
	|					ELSE TableOfPlans.Purpose = PurchaseOrderGoods.Purpose
	|				END)
	|				AND (CASE
	|					WHEN TableOfPlans.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|						THEN TRUE
	|					ELSE TableOfPlans.Department = PurchaseOrder.Department
	|				END)
	|				AND (CASE
	|					WHEN TableOfPlans.PartnerPlan = VALUE(Catalog.Partners.EmptyRef)
	|						THEN TRUE
	|					ELSE TableOfPlans.PartnerPlan = PurchaseOrder.Partner
	|				END)
	|				AND (CASE
	|					WHEN TableOfPlans.AgreementPlan = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|						THEN TRUE
	|					ELSE TableOfPlans.Terms = PurchaseOrder.Terms
	|				END)
	|				AND (PurchaseOrderGoods.DateOfReceipt BETWEEN &DateOfReceipt AND &EndOfDayEndOfReceiptPeriod)
	|				AND (PurchaseOrderGoods.Count <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PurchaseRequestsBalance.Count,
	|		PurchaseRequestsBalance.PurchaseRequest,
	|		CAST(PurchaseRequestsBalance.PurchaseRequest AS Document.PurchaseRequest).Date,
	|		CAST(PurchaseRequestsBalance.PurchaseRequest AS Document.PurchaseRequest).Number,
	|		PurchaseRequestsBalance.Partner,
	|		PurchaseRequestsBalance.Terms
	|	FROM
	|		PurchaseRequestsBalance AS PurchaseRequestsBalance
	|			INNER JOIN TableOfPlans AS TableOfPlans
	|			ON (NOT PurchaseRequestsBalance.CapDivision IN (&DivisionsForWhichThereArePlans))
	|				AND (TableOfPlans.Products = PurchaseRequestsBalance.Products)
	|				AND (TableOfPlans.Characteristic = PurchaseRequestsBalance.Characteristic)
	|				AND (CASE
	|					WHEN TableOfPlans.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|						THEN TRUE
	|					ELSE TableOfPlans.Warehouse = PurchaseRequestsBalance.Warehouse
	|				END)
	|				AND (CASE
	|					WHEN NOT &PlanningByAssignments
	|						THEN TRUE
	|					ELSE TableOfPlans.Purpose = PurchaseRequestsBalance.Purpose
	|				END)
	|				AND (CASE
	|					WHEN TableOfPlans.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|						THEN TRUE
	|					ELSE TableOfPlans.Department = PurchaseRequestsBalance.Department
	|				END)
	|				AND (CASE
	|					WHEN TableOfPlans.PartnerPlan = VALUE(Catalog.Partners.EmptyRef)
	|						THEN TRUE
	|					ELSE TableOfPlans.PartnerPlan = PurchaseRequestsBalance.Partner
	|				END)
	|				AND (CASE
	|					WHEN TableOfPlans.AgreementPlan = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|						THEN TRUE
	|					ELSE TableOfPlans.Terms = PurchaseRequestsBalance.Terms
	|				END)
	|				AND (PurchaseRequestsBalance.DateOfReceipt BETWEEN &DateOfReceipt AND &EndOfDayEndOfReceiptPeriod)) AS TablePlansOrders
	|
	|GROUP BY
	|	TablePlansOrders.Document,
	|	TablePlansOrders.DocumentDate,
	|	TablePlansOrders.DocumentNumber,
	|	TablePlansOrders.Partner,
	|	TablePlansOrders.Terms";
	
	QueriesTexts.Add(QueryText);
	Query = New Query;
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	For Each Property In RowKey Do
		
		Query.SetParameter(Property.Key, Property.Value);
		
	EndDo;
	
	DivisionsForWhichThereArePlans = New Array;
	If Not ValueIsFilled(RowKey.Department) Then

		RowKey.Delete("Department");
		RowKey.Delete("EndOfDayEndOfReceiptPeriod");
		RowKey.Insert("EditBusinessUnit", False);
		
		FoundRows = TableOrderGeneration.FindRows(RowKey);
		
		For Each String In FoundRows Do
			DivisionsForWhichThereArePlans.Add(String.Department);
		EndDo;
		
	EndIf;
	Query.SetParameter("DivisionsForWhichThereArePlans", DivisionsForWhichThereArePlans);
	Query.SetParameter("PlanningByAssignments", PlanningByAssignments
		And ValueIsFilled(RowKey.Purpose));
	
	Selection = Query.Execute().Select();
	DocumentsList = New ValueList();
	While Selection.Next() Do
		
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (%2 Số %3 ngày %4) Bạn hàng: %5 %6';
				|ru = '%1 (%2 № %3 от %4) Партнер: %5 %6';
				|en = '%1 (%2 No. %3 dated %4) Partner: %5 %6'; fa = '%1 (%2 No. %3 dated %4) Partner: %5 %6';
				|it = '%1 (%2 No. %3 dated %4) Partner: %5 %6';
				|pl = '%1 (%2 No. %3 dated %4) Partner: %5 %6';
				|tr = '%1 (%4 tarihli %3 numaralı %2) İş ortağı: %5 %6'"), 
				Format(Selection.Count, "NFD=3"),
				Selection.DocumentType,
				Selection.DocumentNumber,
				Format(Selection.DocumentDate, "DLF=D"),
				?(ValueIsFilled(Selection.Partner),Selection.Partner, "<IsEmpty>"),
				Selection.Terms);
		DocumentsList.Add(Selection.Document, DocumentPresentation);
		
	EndDo;
	
	Return DocumentsList;
	
EndFunction

&AtServer
Function ListOfOrdersByRow(RowKey)

	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchemaQuantityInOrders);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchemaQuantityInOrders);
	SettingsComposerQuantityInPlansInOrders.Initialize(SettingsSource);
	SettingsComposerQuantityInPlansInOrders.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Scenario", Object.Scenario);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Periodicity", Periodicity);
	If ValueIsFilled(RowKey.Department) Then
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Department", RowKey.Department);
	EndIf;
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Partner", RowKey.Partner);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Warehouse", RowKey.Warehouse);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Terms", RowKey.Terms);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Products", RowKey.Products);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Characteristic", RowKey.Characteristic);
	DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "Purpose", RowKey.Purpose);
	If Object.DemandCalculationModeByPlan = 0
		Or Object.DemandCalculationModeByPlan = 2 Then
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "OrderStartDate", Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "OrderEndDate", Object.PeriodEnd);
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "BeginOfPeriod", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "PeriodEnding", Date("00010101"));
	Else
		
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "OrderStartDate", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "OrderEndDate", Date("00010101"));
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "BeginOfPeriod", Object.PeriodBeginning);
		DataCompositionClientServer.SetParameter(SettingsComposerQuantityInPlansInOrders, "PeriodEnding", Object.PeriodEnd);
	EndIf;
	
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, SettingsComposerQuantityInPlansInOrders.GetSettings(), , ,Type("DataCompositionValueCollectionTemplateGenerator") , False, );
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate,,, True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor();
	ResultTable2 = OutputProcessor.Output(CompositionProcessor);
	
	DocumentsList = New ValueList();
	For Each String In ResultTable2 Do
		
		If Not ValueIsFilled(RowKey.Department) 
			And ValueIsFilled(String.Department) Then
			Continue;
		EndIf;
		
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (%2 Số %3 ngày %4) Bạn hàng: %5 %6';
				|ru = '%1 (%2 № %3 от %4) Партнер: %5 %6';
				|en = '%1 (%2 No. %3 dated %4) Partner: %5 %6'; fa = '%1 (%2 No. %3 dated %4) Partner: %5 %6';
				|it = '%1 (%2 No. %3 dated %4) Partner: %5 %6';
				|pl = '%1 (%2 No. %3 dated %4) Partner: %5 %6';
				|tr = '%1 (%4 tarihli %3 numaralı %2) İş ortağı: %5 %6'"),
				Format(String.Count, "NFD=3"),
				String.DocumentType,
				String.DocumentNumber,
				Format(String.DocumentDate, "DLF=D"),
				?(ValueIsFilled(String.Partner),String.Partner, "<IsEmpty>"),
				String.Terms);
		DocumentsList.Add(String.Document, DocumentPresentation);

	EndDo;
	
	Return DocumentsList;
	
EndFunction

&AtClient
Procedure SelectingPlanDocumentFromList(SelectionResult, AdditionalParameters) Export 

	If Not SelectionResult = Undefined Then 
		
		Document = SelectionResult.Value;
		FormParameters = New Structure("Key", Document);
		OpenForm("Document.PurchasePlan.ObjectForm", FormParameters, ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure SelectingOrderDocumentFromList(SelectionResult, AdditionalParameters) Export 

	If Not SelectionResult = Undefined Then 
		
		Document = SelectionResult.Value;
		FormParameters = New Structure("Key", Document);
		ShowValue(, Document);
		
	EndIf;

EndProcedure 

#EndRegion

#Region CreateDeleteOrders

&AtServer
Procedure CreateOrdersOnServer()
	
	TheOrdersTable = TheOrdersTable();
	
	FieldNameDateOfReceipt = "DateOfReceipt";
	If GeneratePurchaseRequests Then
		FieldNameDateOfReceipt = "RequestedDeliveryDate";
	EndIf;
	
	TheOrdersTable.Columns.DateOfReceipt.Name = FieldNameDateOfReceipt;
	
	Columns = "WarehouseParent, Manager, Performer, Department, Organization";
	
	ErrorList = New ValueList;
	
	If GeneratePurchaseRequests Then
		Columns = Columns + ",PriceIncludesVAT";
	Else
		Columns = Columns + ",Partner,Terms";
	EndIf;
	
	If SplitOrdersByAssignments Then
		Columns = Columns + ",Purpose";
	EndIf;
	
	ThereAreWarehousesWithoutGroup = False;
	If  GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
		ThereAreWarehousesWithoutGroup = TheOrdersTable.FindRows(New Structure("WarehouseParent", Catalogs.Warehouses.EmptyRef())).Count() > 0;
	EndIf; 
	
	If SplitOrdersByWarehouses 
		Or Not GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments")
		Or ThereAreWarehousesWithoutGroup Then
		Columns = Columns + ",Warehouse";
	EndIf; 
	
	If SplitOrdersByDeliveryDates Then
		Columns = Columns + "," + FieldNameDateOfReceipt;
	EndIf;
	
	If SplitOrdersByOrderDates Then
		Columns = Columns + ",OrderDate";
	EndIf;
	
	If SplitOrdersByPlanLines Then
		Columns = Columns + ",LineNumber";
	EndIf;
	
	DocumentsTable = TheOrdersTable.Copy(, Columns);
	DocumentsTable.GroupBy(Columns,);
	
	For Each DocumentLine In DocumentsTable Do
		
		FillingData = New Structure(Columns);
		If Not SplitOrdersByWarehouses 
			And GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments")
			And ValueIsFilled(DocumentLine.WarehouseParent) Then
			
			FillingData.Delete("Warehouse");
			FillPropertyValues(FillingData, DocumentLine);
			FoundRows = DocumentsTable.FindRows(FillingData);
			For Each FoundRow In FoundRows Do
				If FoundRow = DocumentLine Then
					Continue;
				EndIf;
				DocumentsTable.Delete(FoundRow);
			EndDo; 
		Else
			FillPropertyValues(FillingData, DocumentLine);
		EndIf; 
		
		Goods = TheOrdersTable.Copy(FillingData);
		
		FillingData.Insert("Goods", Goods);
		
		If SplitOrdersByAssignments Then
			FillingData.Insert("LineOfBusiness", Goods[0].LineOfBusiness);
		Else
			LinesOfBusiness = Goods.Copy(,"LineOfBusiness");
			LinesOfBusiness.GroupBy("LineOfBusiness");
			If LinesOfBusiness.Count() = 1 Then
				FillingData.Insert("LineOfBusiness", LinesOfBusiness[0].LineOfBusiness);
			EndIf
		EndIf;
		
		FillingData.Insert(FieldNameDateOfReceipt, Date("00010101"));
		For Each TSRow In Goods Do
			FillingData[FieldNameDateOfReceipt] = Max(FillingData[FieldNameDateOfReceipt], TSRow[FieldNameDateOfReceipt]);
			FillingData.Insert("Warehouse", TSRow.Warehouse);
		EndDo; 
		
		If Not SplitOrdersByWarehouses 
			And GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments")
			And ValueIsFilled(DocumentLine.WarehouseParent)
			And Goods.FindRows(New Structure("Warehouse", FillingData.Warehouse)).Count() < Goods.Count() Then
			
			FillingData.Insert("Warehouse", DocumentLine.WarehouseParent);
		EndIf;
		
		// We install the division forcibly if it is filled in, because plans are compared according to them, 
		// if not filled in, they are obtained from the user settings.
		If ValueIsFilled(DocumentLine.Department) Then
			FillingData.Insert("Department", DocumentLine.Department);
		EndIf; 
		
		FillingData.Insert("PurchaseObjective", PurchaseObjective);
		
		FullDocumentName = Common.MetadataObjectByID(TypeOfPurchaseDocument).FullName();
		ManagerOfDocument = Common.ObjectManagerByFullName(FullDocumentName);
		
		DocumentObject = ManagerOfDocument.CreateDocument();
		DocumentObject.Date = ?(SplitOrdersByOrderDates, FillingData.OrderDate, CurrentSessionDate());
		DocumentObject.Fill(FillingData);
		
		RecordOrderOnServer(DocumentObject, DocumentLine.WarehouseParent, ErrorList);
		
	EndDo; 
	
	If GeneratePurchaseRequests
		And Documents.PurchaseRequest.PurchaseTargetsWithBDRLimitControl().Find(PurchaseObjective) <> Undefined Then
		Common.MessageToUser(Documents.PurchaseRequest.ErrorTextOfBDRLimits());
	EndIf;
	
	For Each ListItem In ErrorList Do
		CommonClientServer.MessageToUser(ListItem.Presentation, ListItem.Value);
		ListItem.Value = Undefined;
	EndDo;
	ErrorList = Undefined;
	
EndProcedure

&AtServer
Procedure RecordOrderOnServer(DocumentObject, WarehouseParent, ErrorList)

	If DocumentObject = Undefined Then
		Return;
	EndIf; 
	
	If GeneratePurchaseRequests Then
		
		CommentFromDocument = NStr("vi = 'Được tạo tự động bằng bộ xử lý ""Lập đơn đặt hàng để sản xuất theo kế hoạch"".';
									|ru = 'Сформирован автоматически обработкой ""Формирование заявок на закупку по плану"".';
									|en = 'Generated automatically using the ""Generate purchase requests by plan"" data processor.'; fa = 'Generated automatically using the ""Generate purchase requests by plan"" data processor.';
									|it = 'Generated automatically using the ""Generate purchase requests by plan"" data processor.';
									|pl = 'Generated automatically using the ""Generate purchase requests by plan"" data processor.';
									|tr = '""Plana göre satın alma talebi oluşturma"" işlemiyle otomatik olarak oluşturuldu.'");

		// The document cannot be held if it is necessary to fill out the limit analysis.
		RecordWithoutConducting = Documents.PurchaseRequest.MonitorBDRLimits(DocumentObject);
	
	Else
		
		CommentFromDocument = NStr("vi = 'Được tạo tự động bằng bộ xử lý ""Lập đơn đặt hàng cho nhà cung cấp theo kế hoạch"".';
									|ru = 'Сформирован автоматически обработкой ""Формирование заказов поставщику по плану"".';
									|en = 'Generated automatically using the ""Convert plan to purchase orders"" data processor.'; fa = 'Generated automatically using the ""Convert plan to purchase orders"" data processor.';
									|it = 'Formato automaticamente dall''elaborazione ""Formazione di ordini al fornitore secondo il piano"".';
									|pl = 'Utworzony automatycznie przez procedurę przetwarzania ""Формирование заказов поставщику по плану"".';
									|tr = '""Plana göre satın alma siparişi oluşturma"" işlenerek otomatik olarak oluşturuldu.'");
		RecordWithoutConducting = False;
	
	EndIf;
	DocumentObject.Comment = CommentFromDocument;
	
	If Not GeneratePurchaseRequests Then
		
		If ValueIsFilled(DocumentObject.Terms)
			And (Not ValueIsFilled(DocumentObject.Organization)
				Or Not ValueIsFilled(DocumentObject.Partner)
				Or Not ValueIsFilled(DocumentObject.Counterparty)) Then
			
			Attributes = Common.ObjectAttributesValues(DocumentObject.Terms, "Organization, Partner, Counterparty");
			FillPropertyValues(DocumentObject, Attributes);
			
		EndIf;
		
		If Not GetFunctionalOption("UsePurchaseOrderStatuses") Then
			DocumentObject.Status = Enums.PurchaseOrderStatuses.Closed;
		Else
			DocumentObject.Status = Enums.PurchaseOrderStatuses.Confirmed_;
		EndIf;
		
	Else
		
		If UserRightsCached.ApprovePurchaseRequests() Then
			DocumentObject.Status = Enums.PurchaseRequestStatuses.OnExecution;
		Else
			DocumentObject.Status = Enums.PurchaseRequestStatuses.AwaitingApproval;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(DocumentObject.Warehouse) Then
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(DocumentObject.Warehouse);
		WarehousesServer.FillInWarehousesInTablePart(DocumentObject.Warehouse, WarehouseGroup_, DocumentObject.Goods, False);
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(DocumentObject);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(DocumentObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	If Not GeneratePurchaseRequests Then
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	EndIf;
	
	CachedValues = Undefined;
	
	BatchProcessingOfTablePartServer.TreatTS(DocumentObject.Goods, StructureOfActions, CachedValues);
	
	Warehouse = DocumentObject.Warehouse;
	If ValueIsFilled(Warehouse) Then
		DocumentObject.Warehouse = Warehouse;
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
								|%2sebeplerinden dolayı %1 belgeyi kaydetmek mümkün değil '");
	FillingErrorText = NStr("vi = '%1 không thể kết chuyển theo nguyên nhân điền sai.';
							|ru = '%1 невозможно провести по причине некорректного заполнения.';
							|en = 'Cannot post %1. Reason: the document is filled incorrectly.'; fa = 'Cannot post %1. Reason: the document is filled incorrectly.';
							|it = '%1 non è possibile registrare a causa della compilazione non corretta.';
							|pl = '%1 niemożliwe jest zatwierdzenie z powodu niepoprawnego wypełnienia.';
							|tr = '%1 doğru olmayan doldurmadan dolayı kaydetmek mümkün değil.'");
	
	Try
		
		If RecordWithoutConducting Then
			DocumentObject.Write(DocumentWriteMode.Write);
			GeneratedOrders.Add(DocumentObject.Ref);
		ElsIf DocumentObject.CheckFilling() Then
			DocumentObject.Write(DocumentWriteMode.Write);
			GeneratedOrders.Add(DocumentObject.Ref);
			DocumentObject.Write(DocumentWriteMode.Posting);
		Else
			Messages = GetUserMessages(True);
			DocumentObject.Write(DocumentWriteMode.Write);
			GeneratedOrders.Add(DocumentObject.Ref);
			ErrorList.Add(DocumentObject,
				StringFunctionsClientServer.SubstituteParametersToString(FillingErrorText, String(DocumentObject.Ref)));
		EndIf;
		
	Except
		WriteLogEvent(NStr("vi = 'Lập đơn hàng đặt nhà cung cấp theo kế hoạch';
							|ru = 'Формирование заказов поставщику по плану';
							|en = 'Convert plan to purchase orders'; fa = 'تبدیل برنامه به سفارش‌های خرید';
							|it = 'Generazione di ordini al fornitore in base al piano';
							|pl = 'Tworzenie zamówień do dostawcy wg planu';
							|tr = 'Plana göre satın alma siparişi oluşturma'", CommonClientServer.DefaultLanguageCode()),
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

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.1, True);

EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable() Then
		If CheckIfThereAreDocumentsToUpdate() Then
			
			If GeneratePurchaseRequests Then
				QuestionTitle = NStr("vi = 'Tạo giấy đề nghị mua hàng theo kế hoạch';
									|ru = 'Формирование заявок на закупку по плану';
									|en = 'Generate purchase requests by plan'; fa = 'ایجاد درخواست‌های خرید بر اساس برنامه';
									|it = 'Generate purchase requests by plan';
									|pl = 'Generate purchase requests by plan';
									|tr = 'Plana göre satın alma başvurusu oluşturma'");
				QueryText = NStr("vi = 'Đã thay đổi giấy đề nghị mua hàng. Bạn có muốn cập nhật dữ liệu? Sẽ xóa dòng khi cập nhật.';
								|ru = 'Заявки на закупку были изменены. Хотите обновить данные? При обновлении строки будут очищены.';
								|en = 'Purchase requests were changed. Do you want to update the data? Lines will be cleared during update.'; fa = 'Purchase requests were changed. Do you want to update the data? Lines will be cleared during update.';
								|it = 'Purchase requests were changed. Do you want to update the data? Lines will be cleared during update.';
								|pl = 'Purchase requests were changed. Do you want to update the data? Lines will be cleared during update.';
								|tr = 'Satın alma talepleri değiştirildi. Verileri güncellemek ister misiniz? Güncelleme sırasında satırlar temizlenecektir.'");
			Else
				QueryText = NStr("vi = 'Lập đơn hàng đặt nhà cung cấp theo kế hoạch';
								|ru = 'Формирование заказов поставщику по плану';
								|en = 'Convert plan to purchase orders'; fa = 'تبدیل برنامه به سفارش‌های خرید';
								|it = 'Generazione di ordini al fornitore in base al piano';
								|pl = 'Tworzenie zamówień do dostawcy wg planu';
								|tr = 'Plana göre satın alma siparişi oluşturma'");
				QuestionTitle = NStr("vi = 'Đã thay đổi đơn hàng đặt nhà cung cấp. Bạn có muốn cập nhật dữ liệu? Sẽ xóa dòng khi cập nhật.';
									|ru = 'Заказы поставщику были изменены. Хотите обновить данные? При обновлении строки будут очищены.';
									|en = 'Purchase orders were changed. Do you want to update the data? Lines will be cleared during update.'; fa = 'Purchase orders were changed. Do you want to update the data? Lines will be cleared during update.';
									|it = 'Ordini al fornitore sono stati modificati. Volete aggiornare i dati? Durante l''aggiornamento le righe saranno cancellate.';
									|pl = 'Zamówienia zakupu zostały zmienione. Chcesz aktualizować dane? Podczas aktualizacji wiersze zostaną oczyszczone.';
									|tr = 'Satın alma siparişi değiştirildi. Verileri güncellemek ister misiniz? Satırlar güncellemek için silinecektir.'");
			EndIf;
			
			ShowQueryBox(
				New CallbackDescription("NotificationProcessingCompletion", ThisObject), 
				QueryText,
				QuestionDialogMode.YesNo,
				,
				,
				QuestionTitle);
				
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
	|	TableOrderGeneration.Department AS Department,
	|	TableOrderGeneration.Products AS Products,
	|	TableOrderGeneration.Characteristic AS Characteristic,
	|	TableOrderGeneration.DateOfReceipt AS DateOfReceipt,
	|	TableOrderGeneration.ReceiptPeriodEnd AS ReceiptPeriodEnd,
	|	TableOrderGeneration.EditBusinessUnit AS EditBusinessUnit
	|INTO TableOrderGeneration
	|FROM
	|	&TableOrderGeneration AS TableOrderGeneration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PurchaseOrder.Ref AS Document
	|FROM
	|	Document.PurchaseOrder.Goods AS GoodsTable
	|		INNER JOIN Document.PurchaseOrder AS PurchaseOrder
	|		ON GoodsTable.Ref = PurchaseOrder.Ref
	|		INNER JOIN TableOrderGeneration AS TableOrderGeneration
	|		ON GoodsTable.Products = TableOrderGeneration.Products
	|			AND GoodsTable.Characteristic = TableOrderGeneration.Characteristic
	|WHERE
	|	CASE
	|		WHEN TableOrderGeneration.EditBusinessUnit
	|			THEN TRUE
	|		ELSE TableOrderGeneration.Department = PurchaseOrder.Department
	|	END
	|	AND GoodsTable.DateOfReceipt BETWEEN TableOrderGeneration.DateOfReceipt AND TableOrderGeneration.ReceiptPeriodEnd
	|	AND NOT GoodsTable.Canceled
	|	AND PurchaseOrder.Ref.Posted
	|	AND PurchaseOrder.Ref IN(&DocumentListForUpdate)
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseRequest.Ref AS Document
	|FROM
	|	Document.PurchaseRequest.Goods AS GoodsTable
	|		INNER JOIN Document.PurchaseRequest AS PurchaseRequest
	|		ON GoodsTable.Ref = PurchaseRequest.Ref
	|		INNER JOIN TableOrderGeneration AS TableOrderGeneration
	|		ON GoodsTable.Products = TableOrderGeneration.Products
	|			AND GoodsTable.Characteristic = TableOrderGeneration.Characteristic
	|WHERE
	|	CASE
	|		WHEN TableOrderGeneration.EditBusinessUnit
	|			THEN TRUE
	|		ELSE TableOrderGeneration.Department = PurchaseRequest.Department
	|	END
	|	AND CASE
	|		WHEN GoodsTable.RequestedDeliveryDate <> DATETIME(1, 1, 1)
	|			THEN GoodsTable.RequestedDeliveryDate BETWEEN TableOrderGeneration.DateOfReceipt AND TableOrderGeneration.ReceiptPeriodEnd
	|		ELSE
	|			PurchaseRequest.Date BETWEEN TableOrderGeneration.DateOfReceipt AND TableOrderGeneration.ReceiptPeriodEnd
	|	END
	|	AND NOT GoodsTable.Canceled
	|	AND PurchaseRequest.Ref.Posted
	|	AND PurchaseRequest.Ref IN(&DocumentListForUpdate)
	|";
	
	Query.SetParameter("DocumentListForUpdate", DocumentListForUpdate);
	Query.SetParameter("TableOrderGeneration", TableOrderGeneration.Unload());
	
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
	
	TheOrdersTable = TheOrdersTable();
	
	ThereAreWarehousesWithoutGroup = False;
	If GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
		ThereAreWarehousesWithoutGroup = TheOrdersTable.FindRows(New Structure("WarehouseParent", Catalogs.Warehouses.EmptyRef())).Count() > 0;
	EndIf;
	
	Columns = "Department";
	
	If GeneratePurchaseRequests Then
		Columns = Columns + ",PriceIncludesVAT";
	EndIf;
	If SplitOrdersByWarehouses 
		Or Not GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments")
		Or ThereAreWarehousesWithoutGroup Then
		Columns = Columns + ", Warehouse";
	EndIf;
	If SplitOrdersByOrderDates Then
		Columns = Columns + ",OrderDate";
	EndIf;
	If SplitOrdersByDeliveryDates Then
		Columns = Columns + ",DateOfReceipt";
	EndIf;
	If SplitOrdersByAssignments Then
		Columns = Columns + ",Purpose";
	EndIf;
	If SplitOrdersByPlanLines Then
		Columns = Columns + ",LineNumber";
	EndIf;
	
	For Each String In TheOrdersTable Do
		If String.NumberOfPackages>0 Then
			String.Count = 1;
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	TheOrdersTable.Partner            AS Partner,
	|	TheOrdersTable.Terms         AS Terms,
	|	TheOrdersTable.NumberOfPackages AS NumberOfPackages,
	|	TheOrdersTable.Sum              AS Sum,
	|	TheOrdersTable.AmountIncludingVAT          AS AmountIncludingVAT,
	|	TheOrdersTable.TotalWeight           AS TotalWeight,
	|	&Columns
	|INTO OrderDataTT
	|FROM
	|	&TheOrdersTable AS TheOrdersTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DISTINCT OrderDataTT.Partner) AS NumberOfPartners,
	|	COUNT(DISTINCT OrderDataTT.Terms) AS NumberOfAgreements,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderDataTT.Partner) = 1
	|			THEN MAX(OrderDataTT.Partner)
	|		ELSE
	|			UNDEFINED
	|	END                                     AS Partner,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderDataTT.Terms) = 1
	|			THEN MAX(OrderDataTT.Terms)
	|		ELSE
	|			UNDEFINED
	|	END                                     AS Terms,
	|	COUNT(1)                             AS TotalRows,
	|	SUM(OrderDataTT.NumberOfPackages) AS Count,
	|	SUM(OrderDataTT.Sum)              AS Sum,
	|	SUM(OrderDataTT.AmountIncludingVAT)          AS AmountManAccounting,
	|	SUM(OrderDataTT.TotalWeight)           AS TotalWeight,
	|	&Columns
	|FROM
	|	OrderDataTT AS OrderDataTT
	|WHERE
	|	&GeneratePurchaseRequests
	|
	|GROUP BY
	|	&Columns
	|
	|HAVING
	|	SUM(NumberOfPackages) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	1                                AS NumberOfPartners,
	|	1                                AS NumberOfAgreements,
	|	OrderDataTT.Partner          AS Partner,
	|	OrderDataTT.Terms       AS Terms,
	|	COUNT(1)                    AS TotalRows,
	|	SUM(OrderDataTT.NumberOfPackages) AS Count,
	|	SUM(OrderDataTT.Sum)     AS Sum,
	|	SUM(OrderDataTT.AmountIncludingVAT) AS AmountManAccounting,
	|	SUM(OrderDataTT.TotalWeight)  AS TotalWeight,
	|	&Columns
	|FROM
	|	OrderDataTT AS OrderDataTT
	|WHERE
	|	NOT &GeneratePurchaseRequests
	|
	|GROUP BY
	|	OrderDataTT.Partner,
	|	OrderDataTT.Terms,
	|	&Columns
	|
	|HAVING
	|	SUM(NumberOfPackages) <> 0
	|";
	
	Query.Text = StrReplace(Query.Text, "&Columns", Columns);
	
	Query.SetParameter("TheOrdersTable", TheOrdersTable);
	Query.SetParameter("GeneratePurchaseRequests", GeneratePurchaseRequests);
	
	OrderBasket.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Function TheOrdersTable()
	
	Filter = New Structure("SelectToOrder", True);
	TheOrdersTable = Object.GenerationOfOrders.Unload(Filter, "
		| Products, 
		| Characteristic, 
		| Purpose,
		| LineOfBusiness,
		| Warehouse, 
		| Partner,
		| Terms, 
		| VendorPriceKind, 
		| DateOfReceipt, 
		| Package,
		| Count,
		| NumberOfPackages,
		| Price,
		| Sum,
		| AmountIncludingVAT,
		| TotalWeight,
		| OrderDate,
		| Department,
		| Organization,
		| LineNumber,
		|PriceIncludesVAT");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TheOrdersTable.Terms,
	|	TheOrdersTable.Department,
	|	TheOrdersTable.Organization,
	|	TheOrdersTable.Partner,
	|	TheOrdersTable.Products,
	|	TheOrdersTable.Characteristic,
	|	TheOrdersTable.Purpose,
	|	TheOrdersTable.LineOfBusiness,
	|	TheOrdersTable.Warehouse,
	|	TheOrdersTable.Package,
	|	TheOrdersTable.Count,
	|	TheOrdersTable.NumberOfPackages,
	|	TheOrdersTable.Price,
	|	TheOrdersTable.Sum,
	|	TheOrdersTable.AmountIncludingVAT,
	|	TheOrdersTable.TotalWeight,
	|	TheOrdersTable.LineNumber,
	|	TheOrdersTable.DateOfReceipt AS DateOfReceipt,
	|	CASE WHEN TheOrdersTable.OrderDate>&CurrentSessionDate THEN TheOrdersTable.OrderDate ELSE &CurrentSessionDate END AS OrderDate,
	|	TheOrdersTable.VendorPriceKind,
	|	TheOrdersTable.PriceIncludesVAT,
	|	&Manager AS Manager,
	|	&Manager AS Performer
	|INTO TheOrdersTable
	|FROM
	|	&TheOrdersTable AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.NumberOfPackages > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TheOrdersTable.Terms AS Terms,
	|	TheOrdersTable.Department AS Department,
	|	TheOrdersTable.Organization AS Organization,
	|	TheOrdersTable.Partner AS Partner,
	|	TheOrdersTable.Products,
	|	TheOrdersTable.Characteristic,
	|	TheOrdersTable.Purpose,
	|	TheOrdersTable.LineOfBusiness,
	|	TheOrdersTable.Warehouse AS Warehouse,
	|	ISNULL(Warehouses.Ref, VALUE(Catalog.Warehouses.EmptyRef)) AS WarehouseParent,
	|	TheOrdersTable.Package,
	|	SUM(TheOrdersTable.Count),
	|	SUM(TheOrdersTable.NumberOfPackages) AS NumberOfPackages,
	|	TheOrdersTable.Price,
	|	TheOrdersTable.Sum,
	|	TheOrdersTable.AmountIncludingVAT,
	|	TheOrdersTable.TotalWeight,
	|	TheOrdersTable.LineNumber,
	|	CASE 
	|		WHEN TheOrdersTable.DateOfReceipt>DATEADD(&CurrentSessionDate, DAY, ISNULL(TheOrdersTable.Terms.ShipmentDueDate + TheOrdersTable.Terms.DeliveryTime, 0))
	|			THEN TheOrdersTable.DateOfReceipt
	|		ELSE DATEADD(&CurrentSessionDate, DAY, ISNULL(TheOrdersTable.Terms.ShipmentDueDate + TheOrdersTable.Terms.DeliveryTime, 0))
	|	END AS DateOfReceipt,
	|	TheOrdersTable.OrderDate AS OrderDate,
	|	TheOrdersTable.VendorPriceKind,
	|	TheOrdersTable.PriceIncludesVAT,
	|	TheOrdersTable.Manager,
	|	TheOrdersTable.Performer
	|FROM
	|	TheOrdersTable AS TheOrdersTable
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON (CAST(TheOrdersTable.Warehouse AS Catalog.Warehouses).Parent = Warehouses.Ref)
	|			AND (Warehouses.IsFolder)
	|			AND (Warehouses.SelectGroup IN (VALUE(Enum.SelectWarehouseGroup.AllowInOrders), VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)))
	|
	|GROUP BY
	|	TheOrdersTable.Terms,
	|	TheOrdersTable.Department,
	|	TheOrdersTable.Organization,
	|	TheOrdersTable.OrderDate,
	|	TheOrdersTable.Products,
	|	TheOrdersTable.DateOfReceipt,
	|	TheOrdersTable.Warehouse,
	|	TheOrdersTable.Partner,
	|	TheOrdersTable.VendorPriceKind,
	|	TheOrdersTable.Characteristic,
	|	TheOrdersTable.Purpose,
	|	TheOrdersTable.LineOfBusiness,
	|	TheOrdersTable.Package,
	|	TheOrdersTable.Price,
	|	TheOrdersTable.Sum,
	|	TheOrdersTable.AmountIncludingVAT,
	|	TheOrdersTable.TotalWeight,
	|	TheOrdersTable.LineNumber,
	|	ISNULL(Warehouses.Ref, VALUE(Catalog.Warehouses.EmptyRef)),
	|	TheOrdersTable.PriceIncludesVAT,
	|	TheOrdersTable.Manager,
	|	TheOrdersTable.Performer
	|
	|ORDER BY
	|	Department,
	|	Partner,
	|	Terms,
	|	WarehouseParent,
	|	Warehouse,
	|	DateOfReceipt,
	|	OrderDate";
	
	Query.SetParameter("TheOrdersTable", TheOrdersTable);
	Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
	Query.SetParameter("Manager", Manager);
	
	Return Query.Execute().Unload();
	
EndFunction

&AtClient
Procedure SwitchCheckboxes(Install)
	
	If Items.GenerationOfOrders.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chọn các dòng trong danh sách.';
								|ru = 'Выделите строки в списке.';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'Evidenziate le righe nell''elenco.';
								|pl = 'Wydziel wiersze w liście.';
								|tr = 'Listedeki satırı vurgulayınız.'"));
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
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	TableSelectedRows.Products AS Products,
	|	TableSelectedRows.Characteristic AS Characteristic,
	|	TableSelectedRows.DateOfReceipt AS DateOfReceipt,
	|	TableSelectedRows.ReceiptPeriodEnd AS ReceiptPeriodEnd
	|INTO TableSelectedRows
	|FROM
	|	&TableSelectedRows AS TableSelectedRows
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOrderGeneration.Department AS Department,
	|	TableOrderGeneration.Products AS Products,
	|	TableOrderGeneration.Characteristic AS Characteristic,
	|	TableOrderGeneration.DateOfReceipt AS DateOfReceipt,
	|	TableOrderGeneration.ReceiptPeriodEnd AS ReceiptPeriodEnd,
	|	TableOrderGeneration.EditBusinessUnit AS EditBusinessUnit
	|INTO TableOrderGeneration
	|FROM
	|	&TableOrderGeneration AS TableOrderGeneration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOrderGeneration.Department
	|FROM
	|	TableOrderGeneration AS TableOrderGeneration
	|		INNER JOIN TableSelectedRows AS TableSelectedRows
	|		ON TableOrderGeneration.Products = TableSelectedRows.Products
	|			AND TableOrderGeneration.Characteristic = TableSelectedRows.Characteristic
	|			AND TableOrderGeneration.DateOfReceipt = TableSelectedRows.DateOfReceipt
	|			AND (TableOrderGeneration.EditBusinessUnit = FALSE)";
	
	Query.SetParameter("TableOrderGeneration",Table);
	Query.SetParameter("TableSelectedRows",TableSelectedRows);
	Return Query.Execute().Unload().UnloadColumn("Department");
	
EndFunction

&AtClient
Function ReflectLayoutSelectionInSimpleSelections()
	
	ReflectionIsUnacceptable = False;
	For Each FilterElement In SettingsComposer.UserSettings.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") And FilterElement.Use Then
			
			GroupSelectionIsAvailable = 
				TypeOf(FilterElement.RightValue) = Type("CatalogRef.Warehouses") Or
				TypeOf(FilterElement.RightValue) = Type("CatalogRef.Partners") Or
				TypeOf(FilterElement.RightValue) = Type("CatalogRef.Products") Or
				TypeOf(FilterElement.RightValue) = Type("CatalogRef.ProductSegments") Or
				TypeOf(FilterElement.RightValue) = Type("CatalogRef.BusinessStructure");
				
			ReflectionIsUnacceptable = 
				Not FilterElement.ComparisonType = DataCompositionComparisonType.Equal 
				And Not (FilterElement.ComparisonType = DataCompositionComparisonType.InHierarchy And GroupSelectionIsAvailable) 
				Or FilterElement.RightValue = Undefined 
				Or FilterElement.RightValue.IsEmpty();
				
			If ReflectionIsUnacceptable Then
				
				Break;
				
			EndIf;
			
		EndIf;
		
	EndDo;

	If Not ReflectionIsUnacceptable Then
		For Each FilterElement In SettingsComposer.Settings.DataParameters.Items Do
			
			UserSettingItem = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
			If Not UserSettingItem = Undefined Then
				
				FillInParameter(Object.Department,
					"FilterDepartments",
					False,
					FilterElement,
					UserSettingItem);
				FillInParameter(Object.Department,
					"Department",
					PredefinedValue("Catalog.BusinessStructure.EmptyRef"),
					FilterElement,
					UserSettingItem);
				FillInParameter(Object.Scenario,
					"Scenario",
					PredefinedValue("Catalog.SalesOperationsPlanningScenarios.EmptyRef"),
					FilterElement,
					UserSettingItem);
				FillInParameter(Object.PeriodBeginning,
					Object.PeriodBeginning,
					Date("00010101"),
					FilterElement,
					UserSettingItem);
				FillInParameter(Object.PeriodEnd,
					Object.PeriodEnd,
					Date("00010101"),
					FilterElement,
					UserSettingItem)	
					
			EndIf;
		EndDo;
		For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
			
			UserSettingItem = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
			If Not UserSettingItem = Undefined Then
				
				FillOutSimpleSelection(
					Object.Warehouse,
					"Warehouse",
					PredefinedValue("Catalog.Warehouses.EmptyRef"), 
					FilterElement,
					UserSettingItem);
				FillOutSimpleSelection(
					Object.Partner,
					"Vendor",
					PredefinedValue("Catalog.Partners.EmptyRef"),
					FilterElement,
					UserSettingItem);
				FillOutSimpleSelection(
					Object.Terms,
					"Terms",
					PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef"),
					FilterElement,
					UserSettingItem);
				FillOutSimpleSelection(
					Object.Products,
					"Products",
					PredefinedValue("Catalog.Products.EmptyRef"),
					FilterElement,
					UserSettingItem);
				FillOutSimpleSelection(Object.ProductSegment,
					"ProductSegment",
					PredefinedValue("Catalog.ProductSegments.EmptyRef"),
					FilterElement,
					UserSettingItem);
				FillOutSimpleSelection(Object.PeriodBeginning,
					"PeriodBeginning",
					Object.PeriodBeginning,
					FilterElement,
					UserSettingItem);
				FillOutSimpleSelection(Object.PeriodEnd,
					"PeriodEnd",
					Object.PeriodEnd,
					FilterElement,
					UserSettingItem);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Not ReflectionIsUnacceptable;
	
EndFunction

&AtClient
Procedure FillOutSimpleSelection(FormAttribute, FieldName, DefaultValue, FilterElement, UserSettingItem)
	
	LayoutField = New DataCompositionField(FieldName);
	If LayoutField = FilterElement.LeftValue Then
		
		If UserSettingItem.Use Then
			
			FormAttribute = UserSettingItem.RightValue;
			
		Else 
			
			FormAttribute = DefaultValue;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInParameter(FormAttribute, ParameterName, DefaultValue, ParameterElement, UserSettingItem)
	
	LayoutParameter = New DataCompositionParameter(ParameterName);
	If LayoutParameter = ParameterElement.Parameter Then
		
		If UserSettingItem.Use Then
			
			FormAttribute = UserSettingItem.Value;
			
		Else 
			
			FormAttribute = DefaultValue;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ReflectSimpleSelectionInLayoutSelections(SettingsComposer, FieldName, Value, ThisIsGroupSelection)

	SearchValue = New DataCompositionField(FieldName);
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		
		If FilterElement.LeftValue = SearchValue Then
			
			UserSettingItem 
				= SettingsComposer.UserSettings.Items.Find(
					FilterElement.UserSettingID);
			If Not UserSettingItem = Undefined Then
				
				UserSettingItem.Use = (Value <> Undefined) And Not Value.IsEmpty();
				If UserSettingItem.Use Then
					
					VariantOfComparisonType = DataCompositionComparisonType.Equal;
					
					If ThisIsGroupSelection Then
						
						VariantOfComparisonType = DataCompositionComparisonType.InHierarchy;
						
					EndIf;
					
					UserSettingItem.ComparisonType  = VariantOfComparisonType;
					UserSettingItem.RightValue = Value;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ThisIsGroupSelection(Var_Key, FilterByGroup)
	
	FilterValue = FilterByGroup.FindByValue(Var_Key);
	If FilterValue = Undefined Then	
		GroupSelectionFlag = ThisIsGroupSelectionOnServer(Var_Key);
		FilterByGroup.Add(Var_Key,,GroupSelectionFlag);
	Else
		GroupSelectionFlag = FilterValue.Check;
	EndIf;
	
	Return GroupSelectionFlag;
	
EndFunction

&AtServerNoContext
Function ThisIsGroupSelectionOnServer(FilterValue)
	
	If TypeOf(FilterValue) = Type("CatalogRef.Warehouses") Then
		CatalogName = "Warehouses";
	ElsIf TypeOf(FilterValue) = Type("CatalogRef.Products") Then
		CatalogName = "Products";
	ElsIf TypeOf(FilterValue) = Type("CatalogRef.Partners") Then
		Return True;
	ElsIf TypeOf(FilterValue) = Type("CatalogRef.ProductSegments") Then
		CatalogName = "ProductSegments";
	Else 
		Return False;
	EndIf;
	
	Query = New Query();
	Query.Text = 
		"SELECT ALLOWED
		|	CatalogTable.IsFolder AS IsFolder
		|FROM
		|	&QueryTextCatalogName AS CatalogTable
		|WHERE
		|	CatalogTable.Ref = &Ref";
	
	Query.SetParameter("Ref", FilterValue);
	
	Query.Text = StrReplace(
		Query.Text, 
		"&QueryTextCatalogName", 
		"Catalog." + CatalogName + "");
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Return Selection.IsFolder;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtClientAtServerNoContext
Function SettingsForFillingInPurchasePriceInTSLine(String, CurrentSessionDate)
	
	PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(String);
	PriceFillingParameters_.Date = CurrentSessionDate;
	
	Return PriceFillingParameters_;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object = Undefined)
	
	If Object = Undefined Then
		StructureOfRecalculationOfAmount = New Structure;
		StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	Else
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	EndIf; 
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
		
EndProcedure

&AtServer
Procedure FillInDefaultCurrency()
	
	If GetFunctionalOption("UseTermsOfPurchases") Then 
		Return;
	EndIf;
	
	FillInDefaultCurrency = False;
	
	If GetFunctionalOption("UseMultipleCurrencies") Then
		
		Attributes = Common.ObjectAttributesValues(Object.Scenario, 
		            "CreatePurchasePlanByAmount, CreateSalesPlanByAmount");
		
		If Not Attributes.CreatePurchasePlanByAmount And Not Attributes.CreateSalesPlanByAmount Then
			FillInDefaultCurrency = True;
		EndIf; 
		
	Else 
		FillInDefaultCurrency = True;
	EndIf; 
	
	If FillInDefaultCurrency Then
		
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting();
		
		For Each OrderGenerationLine In Object.GenerationOfOrders Do
			If Not ValueIsFilled(OrderGenerationLine.Currency) Then
				OrderGenerationLine.Currency = Currency;
			EndIf; 
		EndDo; 
	
	EndIf; 
	
EndProcedure

&AtServer
Procedure ConfigurePurchaseDocumentType(Val FullNameOfPurchaseDocument, Cancel)
	
	If Not ValueIsFilled(FullNameOfPurchaseDocument) Then
		FullNameOfPurchaseDocument = "Document.PurchaseOrder";
	EndIf;
	
	TypeOfPurchaseDocument = Common.MetadataObjectID(FullNameOfPurchaseDocument);
	
	If TypeOfPurchaseDocument <> Common.MetadataObjectID(Metadata.Documents.PurchaseRequest)
		And TypeOfPurchaseDocument <> Common.MetadataObjectID(Metadata.Documents.PurchaseOrder) Then
		
		ErrorText = NStr("vi = 'Sai giá trị kiểu của chứng từ mua hàng. Hãy liên hệ với người quản trị.';
						|ru = 'Неверное значение типа документа закупки. Обратитесь к администратору.';
						|en = 'Invalid purchase document type value. Contact the administrator.'; fa = 'Invalid purchase document type value. Contact the administrator.';
						|it = 'Invalid purchase document type value. Contact the administrator.';
						|pl = 'Invalid purchase document type value. Contact the administrator.';
						|tr = 'Geçersiz satın alma belge türü. Yöneticiye başvurun.'");
		Common.MessageToUser(ErrorText,,,, Cancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPropertiesByPurchaseDocumentType()
	
	GeneratePurchaseRequests = TypeOfPurchaseDocument = Common.MetadataObjectID(Metadata.Documents.PurchaseRequest);
	
	If Not GeneratePurchaseRequests
		Or Not Documents.PurchaseRequest.UseBDRLimits() Then
			// Purchase goals are not used.
			PurchaseObjective = PurchaseRequestClientServer.DefaultPurchaseTarget();
			Items.PurchaseObjective.Visible = False;
	EndIf;
	
	If GeneratePurchaseRequests Then
		Items.DocumentTypePages.CurrentPage = Items.GeneratedApplicationsPage;
		Items.GroupOrderWeight.Visible = False;
		
		#Region Headers
		Items.GroupSimpleFilters.Title = NStr("vi = 'Tạo giấy đề nghị theo:';
												|ru = 'Создавать заявки по:';
												|en = 'Create requests by:'; fa = 'Create requests by:';
												|it = 'Create requests by:';
												|pl = 'Create requests by:';
												|tr = 'Talepleri şuna göre oluştur:'");
		Items.GenerationOfOrders.Title = NStr("vi = 'Lập giấy đề nghị';
												|ru = 'Формирование заявок';
												|en = 'Generate requests'; fa = 'Generate requests';
												|it = 'Generate requests';
												|pl = 'Generate requests';
												|tr = 'Talep oluşturma'");
		Items.GenerationOfOrdersOrderCreationParameters.Title = NStr("vi = 'Tham số tạo mới giấy đề nghị';
																	|ru = 'Параметры создания заявки';
																	|en = 'Request creation parameters'; fa = 'Request creation parameters';
																	|it = 'Request creation parameters';
																	|pl = 'Request creation parameters';
																	|tr = 'Başvuru oluşturma parametreleri'");
		Items.OrderGenerationProductCharacteristic.Title = NStr("vi = 'Lập giấy đề nghị mặt hàng đặc tính';
																|ru = 'Формирование заявок номенклатура характеристика';
																|en = 'Generate requests item variant'; fa = 'Generate requests item variant';
																|it = 'Generate requests item variant';
																|pl = 'Generate requests item variant';
																|tr = 'Talep oluşturma ürün özellikler'");
		Items.ForOrderGroup.Title = NStr("vi = 'Chuyển vào giấy đề nghị';
										|ru = 'В заявку';
										|en = 'To request'; fa = 'To request';
										|it = 'To request';
										|pl = 'To request';
										|tr = 'Talebe ekleme'");
		Items.GenerationOfOrdersQuantityInOrders.Title = NStr("vi = 'Đang xử lý';
																|ru = 'В работе';
																|en = 'In progress'; fa = 'در حال انجام';
																|it = 'In esecuzione';
																|pl = 'Wykonuje się';
																|tr = 'İşleniyor'");
		Items.GenerationOfOrdersQuantityInOrders.ToolTip= NStr("vi = 'Số lượng trong giấy đề nghị và đơn hàng đặt nhà cung cấp';
																|ru = 'Количество в заявках и заказах поставщикам';
																|en = 'Quantity in requests and purchase orders'; fa = 'Quantity in requests and purchase orders';
																|it = 'Quantity in requests and purchase orders';
																|pl = 'Quantity in requests and purchase orders';
																|tr = 'Talepler ve tedarikçi siparişlerindeki miktar'");
		Items.GroupOrderGenerationQuantityInOrders.Title = NStr("vi = 'Đang làm việc';
																|ru = 'В работе';
																|en = 'In progress'; fa = 'در حال انجام';
																|it = 'In esecuzione';
																|pl = 'Wykonuje się';
																|tr = 'İşleniyor'");
		Items.GenerateOrdersPriceCurrency.Title = NStr("vi = 'Lập giấy đề nghị đơn giá tiền tệ';
														|ru = 'Формирование заявок цена валюта';
														|en = 'Generate requests price currency'; fa = 'Generate requests price currency';
														|it = 'Generate requests price currency';
														|pl = 'Generate requests price currency';
														|tr = 'Talep oluşturma fiyat para birimi'");
		Items.GroupOrdersToBeProcessed.Title = NStr("vi = 'Giấy đề nghị cần lập';
													|ru = 'Заявки к оформлению';
													|en = 'Requests to register'; fa = 'Requests to register';
													|it = 'Requests to register';
													|pl = 'Requests to register';
													|tr = 'Oluşturulacak talepler'");
		Items.OrderBasket.Title = NStr("vi = 'Giấy đề nghị cần lập';
										|ru = 'Заявки к оформлению';
										|en = 'Requests to register'; fa = 'Requests to register';
										|it = 'Requests to register';
										|pl = 'Requests to register';
										|tr = 'Oluşturulacak talepler'");
		Items.ShoppingCartGroupDeliveryDateWarehouse.Title = NStr("vi = 'Giỏ yêu cầu nhóm ngày giao hàng kho bãi';
																	|ru = 'Корзина заявок группа дата поставки склад';
																	|en = 'Request cart group delivery date warehouse'; fa = 'Request cart group delivery date warehouse';
																	|it = 'Request cart group delivery date warehouse';
																	|pl = 'Request cart group delivery date warehouse';
																	|tr = 'Talep sepeti grup tedarik tarihi depo'");
		Items.GroupOrderAmount.Title = NStr("vi = 'Số tiền của giấy đề nghị';
											|ru = 'Сумма заявки';
											|en = 'Request amount'; fa = 'مبلغ درخواست';
											|it = 'Request amount';
											|pl = 'Request amount';
											|tr = 'Talep tutarı'");
		Items.OrderBasketTotalRows.Title = NStr("vi = 'Dòng trong giấy đề nghị';
												|ru = 'Строк в заявке';
												|en = 'Lines in request'; fa = 'Lines in request';
												|it = 'Lines in request';
												|pl = 'Lines in request';
												|tr = 'Talepteki satırlar sayısı'");
		Items.GeneratedOrdersPage.Title = NStr("vi = 'Trang giấy đề nghị đã lập';
												|ru = 'Страница сформированные заявки';
												|en = 'Page generated requests'; fa = 'صفحه درخواست‌های ایجادشده';
												|it = 'Page generated requests';
												|pl = 'Page generated requests';
												|tr = 'Sayfa oluşturulan talepler'");
		Items.NextStep2.Title = NStr("vi = 'Tạo giấy đề nghị >';
									|ru = 'Создать заявки >';
									|en = 'Create requests >'; fa = 'Create requests >';
									|it = 'Create requests >';
									|pl = 'Create requests >';
									|tr = 'Talepleri oluştur >'");
		Items.CheckAll.Title = NStr("vi = 'Đánh dấu trong giấy đề nghị';
									|ru = 'Отметить в заявку';
									|en = 'Select in request'; fa = 'Select in request';
									|it = 'Select in request';
									|pl = 'Select in request';
									|tr = 'Talep için işaretle'");
		Items.UncheckAll.Title = NStr("vi = 'Bỏ đánh dấu trong giấy đề nghị';
										|ru = 'Снять отметку в заявку';
										|en = 'Clear in request'; fa = 'Clear in request';
										|it = 'Clear in request';
										|pl = 'Clear in request';
										|tr = '""Talep için"" işaretini kaldır'");
		Items.GenerationOfOrdersSelectToOrder.Title = NStr("vi = 'Đánh dấu trong giấy đề nghị';
															|ru = 'Отметить в заявку';
															|en = 'Select in request'; fa = 'Select in request';
															|it = 'Select in request';
															|pl = 'Select in request';
															|tr = 'Talep için işaretle'");
		Items.GenerationOfOrdersOrderDate.Title = NStr("vi = 'Ngày giấy đề nghị';
														|ru = 'Дата заявки';
														|en = 'Request date'; fa = 'تاریخ درخواست';
														|it = 'Data della richiesta';
														|pl = 'Data zgłoszenia';
														|tr = 'Talep tarihi'");
		Items.GenerationOfOrdersDaysBeforeOrdering.Title = NStr("vi = 'Thời hạn thực hiện giấy đề nghị';
																|ru = 'Срок исполнения заявки';
																|en = 'Request due date'; fa = 'Request due date';
																|it = 'Request due date';
																|pl = 'Request due date';
																|tr = 'Son talep tarihi'");
		#EndRegion
		
	Else
		
		Items.Manager.AutoMarkIncomplete = False;
		Items.Manager.MarkIncomplete = False;
		
		Items.DocumentTypePages.CurrentPage = Items.GeneratedOrdersPage;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetQueryTextOfPurchaseRequest(DataCompositionSchema)
	
	NameOfTempTableOfPurchaseRequestBalances = "PurchaseRequestsBalance";
	
	QueryText = DataCompositionSchema.DataSets.Plans.Query;
	QueryText = StrReplace(QueryText,
		"ReplacementTextForUsingIntermediateGroupingFields",
		Documents.PurchaseRequest.TextOfUseOfIntermediateFieldsOfFormationOfBalance(NameOfTempTableOfPurchaseRequestBalances));
		
	QueryTexts = StrSplit(QueryText, ";");
	For IndexOfRequestInPackage = 0 To QueryTexts.UBound() Do
		
		QueryTextInPackage = QueryTexts[IndexOfRequestInPackage];
		If StrFind(QueryTextInPackage, "INTO " + NameOfTempTableOfPurchaseRequestBalances) <> 0 Then
			QueryTexts[IndexOfRequestInPackage] = Documents.PurchaseRequest.QueryTextBalancesOfPurchaseRequestsAccordingToPlans(
				"TableOfPlans",
				NameOfTempTableOfPurchaseRequestBalances);
				
			Break;
		EndIf;
		
	EndDo;
	
	QueryText = StrConcat(QueryTexts, ";");
	DataCompositionSchema.DataSets.Plans.Query = QueryText;
	
EndProcedure

&AtServer
Procedure EstablishLinksOfSelectionParametersToVendorPriceType(Terms)
	
	Links = New Array(Items.GenerationOfOrdersVendorPriceKind.ChoiceParameterLinks);
	NewLink = New ChoiceParameterLink("Filter.PriceIncludesVAT", "Items.GenerationOfOrders.CurrentData.PriceIncludesVAT");
	
	ElementIndex = Links.Find(NewLink);
	
	If ValueIsFilled(Terms) And ElementIndex = Undefined Then
		Links.Add(NewLink);
	ElsIf Not ValueIsFilled(Terms) And ElementIndex <> Undefined Then
		Links.Delete(ElementIndex);
	EndIf;
	
	Items.GenerationOfOrdersVendorPriceKind.ChoiceParameterLinks = New FixedArray(Links);
	
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
