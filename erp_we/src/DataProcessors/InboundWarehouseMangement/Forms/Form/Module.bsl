
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	TMCommonUse.CustomizePeripherals(ThisForm, "Inflow");
	
	FillDefaultWarehouse();
	
	FilterJobs = "Incomplete";
	FilterNotes = "ForReceiving";
			
	ProductPoolPlacement.Parameters.SetParameterValue("ReceivingArea", Undefined);
	
	SetColumnHeadersWeightVolume();
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		
		QuickFilterStructure.Property("Warehouse", Warehouse);
		QuickFilterStructure.Property("FilterReferences", FilterReferences);
		
		If QuickFilterStructure.Property("ReceivingArea", ReceivingArea) Then
			ProductPoolPlacement.Parameters.SetParameterValue("ReceivingArea", ReceivingArea);
		EndIf;
		
	EndIf;
	
	WarehouseSpaceWhenServerChanges();
	
	
	// StandardSubsystems.AttachableCommands
	TypesList = NotesInProgress.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.NotesInProgressGroupCommandBar;
	PlacementParameters.GroupsPrefix = "NotesInProgress";
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	TypesList = JobsInProgress.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.TransfersInProgressGroupCommandBar;
	PlacementParameters.GroupsPrefix = "TransfersInProgress";
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
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
	
	
	If EventName = "ChangingList_OrdersInProgress" Then
		ChangingOrderListInProgress(ReceiptReferenceOrder());
	ElsIf Items.GroupPages.CurrentPage = Items.PlacementPage
		And (EventName = "ChangingListOf_TasksInProgress"
			Or EventName = "Write_Products"
			Or EventName = "Write_ProductPackages"
			Or EventName = "Write_GoodsPlacementRules") Then
		Items.ProductPoolPlacement.Refresh();
	ElsIf EventName = "Write_TermsOfPurchaseFromVendors"
		Or EventName = "Write_PurchaseOrder"
		Or EventName = "Write_RequestForReturnOfGoodsFromCustomer"
		Or EventName = "Write_InventoryTransfer"
		Or EventName = "Write_VendorInvoice"
		Or EventName = "Write_GoodsReceiptForStorage"
		Or EventName = "Write_AssemblyFromComponents" Then
		FillInReceiptOrders();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TMCommonUse.ClearFormSettingsOrDetailsFromNonexistentLinks(Settings);
	
	GettingInventoryFromSettings =
		Warehouse = Settings.Get("Warehouse")
		Or GetFunctionalOption("UseSeveralWarehouses");
	
	If GettingInventoryFromSettings Then
		If QuickFilterStructure = Undefined Then
			Warehouse 		= Settings.Get("Warehouse");
			Premise 	= Settings.Get("Premise");
			ReceivingArea = Settings.Get("ReceivingArea");
		Else
			
			If Not QuickFilterStructure.Property("Warehouse") Then
				Warehouse = Settings.Get("Warehouse");
			EndIf;
			
			If Not QuickFilterStructure.Property("Premise") Then
				Premise = Settings.Get("Premise");
			EndIf;
			
			If Not QuickFilterStructure.Property("ReceivingArea") Then
				ReceivingArea = Settings.Get("ReceivingArea");
			EndIf;
			
		EndIf;
	EndIf;
	
	// We have already downloaded these settings
	Settings.Delete("Warehouse");
	Settings.Delete("Premise");
	Settings.Delete("ReceivingArea");
		
	WarehouseSpaceWhenServerChanges();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReceivingAreaOnChange(Item)
	
	SetSelectionsInAllLists(ReceiptReferenceOrder());
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.InboundWarehouseMangement.Form.Item.Warehouse.OnChange");
	
	WarehouseOnChangeServer(ReceiptReferenceOrder());		
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	WarehouseSpaceWhenServerChanges();
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	SetSelectionsInMainLists();
EndProcedure

&AtClient
Procedure FilterNotesOnChange(Item)
	SetSelectionsInDependentLists(ReceiptReferenceOrder());
EndProcedure

&AtClient
Procedure FilterJobsOnChange(Item)
	SetSelectionsInMainLists();
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	GroupPagesOnCurrentPageChangeServer(CurrentPage.Name);
EndProcedure

&AtClient
Procedure ReceiptStatusFilterOnChange(Item)
	
	SetSelectionsInAllLists(ReceiptReferenceOrder());
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReceiptOrders

&AtClient
Procedure ReceiptOrdersOnActivateRow(Item)
	
	SetSelectionsInDependentLists(ReceiptReferenceOrder());
	
EndProcedure

&AtClient
Procedure ReceiptOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Field = Items.ReceiptOrdersReceiptState
		And ValueIsFilled(Item.CurrentData.ReceiptState) Then
		
		Filter = New Structure("Warehouse, ReferenceOrder", Warehouse, Item.CurrentData.ReferenceOrder);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", Filter);
		FormParameters.Insert("PurposeUseKey", "StateOfAcceptanceContext");
		FormParameters.Insert("VariantKey", "StateOfAcceptanceContext");
		FormParameters.Insert("GenerateOnOpen", True);
		
		OpenForm("Report.GoodsToReceive.Form", FormParameters, ThisForm);
		
	Else
		ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReceiptOrdersBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ReceiptOrdersBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormTableElementPoolNomecnlaturePlacement

&AtClient
Procedure ProductPoolPlacementSelection(Item, RowSelected, Field, StandardProcessing)
	CurrentData = Items.ProductPoolPlacement.CurrentData;
	
	If CurrentData <> Undefined Then
		If Field = Items.ProductPoolPlacement.ChildItems.TheGroupOfColumnsPoolOfItemPlacementItem.ChildItems.ProductPoolPlacementProducts Then
			ShowValue(Undefined, CurrentData.Products);
		ElsIf Field = Items.ProductPoolPlacement.ChildItems.ProductPoolPlacementPackage Then
			ShowValue(Undefined, CurrentData.Package);
		ElsIf Field = Items.ProductPoolPlacement.ChildItems.ProductPoolPlacementWarehouseGroupOfProducts Then
			ShowValue(Undefined, CurrentData.WarehouseGroupOfProducts);
		ElsIf Field = Items.ProductPoolPlacement.ChildItems.ProductPoolPlacementWarehouseGroupOfPackages Then
			ShowValue(Undefined, CurrentData.WarehouseGroupOfPackages);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersJobsInProgress

&AtClient
Procedure JobsInProgressOnChange(Item)
	Notify("ChangingListOf_TasksInProgress", New Structure);
EndProcedure

&AtClient
Procedure JobsInProgressOnActivateRow(Item)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNotesInProgress

&AtClient
Procedure NotesInProgressOnChange(Item)
	Notify("ChangingList_OrdersInProgress", New Structure);
EndProcedure

&AtClient
Procedure NotesInProgressOnActivateRow(Item)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateJobs(Command)
	ClearMessages();
	Cancel = False;
	
	If Not ValueIsFilled(Warehouse) Then
		MessageText = NStr("vi = 'Trước khi thực hiện giao dịch, cần chọn kho.';
							|ru = 'Перед выполнением операции необходимо выбрать склад.';
							|en = 'Before executing the operation it is required to select the warehouse.'; fa = 'Before executing the operation it is required to select the warehouse.';
							|it = 'Prima di eseguire l''operazione è necessario selezionare un magazzino.';
							|pl = 'Przed wykonaniem operacji należy wybrać magazyn.';
							|tr = 'İşlemi gerçekleştirmeden önce bir ambar seçilmeli.'");
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndIf;
	
	If Not Cancel Then
		
		Structure = New Structure;
		Structure.Insert("Premise",Premise);
		Structure.Insert("Warehouse",Warehouse);
		
		ParametersForm = New Structure("Title, Operation, ParameterObject", "InboundWarehouseMangement", "JobGeneration",Structure);
		Response = Undefined;

		OpenForm("Document.GoodsPickingPlacement.Form.SettingsForm",ParametersForm,ThisForm,,,, New CallbackDescription("CreateJobsCompletion", ThisObject, New Structure("Structure", Structure)), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure CreateJobsCompletion(Result, AdditionalParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.InboundWarehouseMangement.Form.Notification.CreateJobsCompletion");
	
	Structure = AdditionalParameters.Structure;
	
	Response = Result;
	
	SelectedRows = New Array;
	
	If ByAllProducts <> 0 Then
		
		For Each ArrRow In Items.ProductPoolPlacement.SelectedRows Do
			RowData = Items.ProductPoolPlacement.RowData(ArrRow);
			
			RowOfTables = New Structure;
			RowOfTables.Insert("Products",RowData.Products);
			RowOfTables.Insert("Characteristic",RowData.Characteristic);
			RowOfTables.Insert("Series",RowData.Series);
			RowOfTables.Insert("Purpose",RowData.Purpose);
			
			SelectedRows.Add(RowOfTables);
			
		EndDo;
	EndIf;
	
	If Response = DialogReturnCode.OK Then
		CreateJobsServer(SelectedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure TakeUpTheJobs(Command)
	
	Notification = New CallbackDescription("TakeUpTheJobsCompletion", ThisObject);
	
	WarehousesClient.TakeUpTheJobs(ThisForm, Items.JobsInProgress , "InboundWarehouseMangement", Notification);
	
EndProcedure

&AtClient
Procedure TakeUpTheJobsCompletion(Result, AdditionalParameters) Export
	
	SetSelectionsInMainLists();

EndProcedure

&AtClient
Procedure CompleteJobs(Command)
	
	Notification = New CallbackDescription("CompleteJobsCompletion", ThisObject);
	
	WarehousesClient.MarkCompletionOfTasksWithoutErrors(ThisForm, Items.JobsInProgress, "FilterLocation", Notification);
	
EndProcedure

&AtClient
Procedure CompleteJobsCompletion(Result, AdditionalParameters) Export
	
	SetSelectionsInMainLists();

EndProcedure

&AtClient
Procedure CreateNote(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.InboundWarehouseMangement.Form.Command.CreateNote");

	ClearMessages();
	CurrentData = Items.ReceiptOrders.CurrentData;
	
	If CurrentData <> Undefined Then

		Basis = New Structure;
		Basis.Insert("ReferenceOrder",               CurrentData.ReferenceOrder);
		Basis.Insert("ControlledLotReference",       CurrentData.ControlledLotReference);
		Basis.Insert("Sender",                CurrentData.Sender);
		Basis.Insert("Warehouse",                      Warehouse);
		Basis.Insert("Premise",                  Premise);
		Basis.Insert("ReceivingArea",                ReceivingArea);
		Basis.Insert("IncomingDocumentDate",     CurrentData.IncomingDocumentDate);
		Basis.Insert("IncomingDocumentNumber",    CurrentData.IncomingDocumentNumber);
		Basis.Insert("DateOfReceipt",            DateOfReceipt);
		Basis.Insert("BusinessOperation",      CurrentData.BusinessOperation);
		OpenForm("Document.GoodsReceiptNote.Form.DocumentForm",
					New Structure("Basis",Basis));
		
	Else
			
		WarningText = NStr("vi = 'Hãy chọn chênh lệch cho tiếp nhận hàng hóa.';
							|ru = 'Выберите распоряжение на поступление товаров.';
							|en = 'Select a goods receipt reference.'; fa = 'Select a goods receipt reference.';
							|it = 'Selezionare una disposizione per l''arrivo delle merci.';
							|pl = 'Wybierz zamówienie na wpływ towarów.';
							|tr = 'İrsaliye için siparişi seç.'");
		CommonClientServer.MessageToUser(WarningText);
		
	EndIf;

EndProcedure

&AtClient
Procedure UpdateReceiptLists(Command)
	UpdatedList_4("Inpayment", ReceiptReferenceOrder());
EndProcedure

&AtClient
Procedure UpdateListsPlacement(Command)
	UpdatedList_4("Location");
EndProcedure

&AtClient
Procedure UploadVTSDData(Command)
	
	FormParameters = New Structure("FillingVariant, ReceivingWarehouse, DateOfReceiving", "ByReceivingReferences", Warehouse, DateOfReceipt);
	OpenForm("DataProcessor.ExportGoodsDatabaseToPDT.Form", FormParameters);
	
EndProcedure

&AtClient
Procedure PrintLabelsBySelectedProductsLines(Command)
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
			
	ArrayProducts = New Array;
	
	For Each PoolRowId In Items.ProductPoolPlacement.SelectedRows Do
		
		PoolLine = Items.ProductPoolPlacement.RowData(PoolRowId);
		
		RowGoods = New Structure;
		RowGoods.Insert("Products", PoolLine.Products);
		RowGoods.Insert("Characteristic", PoolLine.Characteristic);
		RowGoods.Insert("Count", PoolLine.Place);
		RowGoods.Insert("Package", PoolLine.Package);
		
		ArrayProducts.Add(RowGoods);
	
	EndDo; 
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", New FixedArray(ArrayProducts));
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	
	StorageAddress = PutToTempStorage(ResultingStructure);
		
	OpenForm(
		"DataProcessor.PrintPriceTagsAndLabels.Form.FormGoods",
			New Structure("AddressInStorage, TemplateAssignment", StorageAddress, Undefined));
	
EndProcedure

&AtClient
Procedure PrintLabelsByReference(Command)
	
	If Items.ReceiptOrders.CurrentData = Undefined Then 
		Raise NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
					|ru = 'Команда не может быть выполнена для указанного объекта!';
					|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
					|it = 'Il comando non può essere eseguito per oggetto indicato!';
					|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
					|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
	EndIf; 
	
	StorageAddress = DataForPrintingLabelsByOrder(Items.ReceiptOrders.CurrentData.ReferenceOrder);
	
	OpenForm(
		"DataProcessor.PrintPriceTagsAndLabels.Form.FormGoods",
		New Structure("AddressInStorage, TemplateAssignment", StorageAddress, Undefined));
	
EndProcedure

// StandardSubsystems.AttachableCommands
// Parameters:
// 	Command - FormCommand
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If Find(Command.Name, "NotesInProgress") Then
		List = Items.NotesInProgress;
	Else
		List = Items.JobsInProgress;
	EndIf;
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	If Find(Context.CommandNameInForm, "NotesInProgress") Then
		List = Items.NotesInProgress;
	Else
		List = Items.JobsInProgress;
	EndIf;
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	If Items.GroupPages.CurrentPage = Items.PageReceipt Then
		List = Items.NotesInProgress;
	ElsIf Items.GroupPages.CurrentPage = Items.PlacementPage Then
		List = Items.JobsInProgress;
	EndIf; 

	AttachableCommandsClientServer.UpdateCommands(ThisObject, List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductPoolPlacementWarehouseGroupOfProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductPoolPlacementWarehouseGroupOfPackages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductPoolPlacement.ErrorInTheStorageArea");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductPoolPlacementPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductPoolPlacement.ErrorInPackaging");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductPoolPlacementProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductPoolPlacement.ItemError");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceiptOrdersControlledLotReference.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReceiptOrders.ControlledLotReference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'lệnh hiện tại';
													|ru = 'текущее распоряжение';
													|en = 'current reference'; fa = 'current reference';
													|it = 'current reference';
													|pl = 'current reference';
													|tr = 'geçerli talimat'"));

	//

EndProcedure

#Region FillingAndInitialization

&AtServer
Procedure FillDefaultWarehouse()
	
	FillingStructure = New Structure("Warehouse");
	TMCommonUse.Filling(FillingStructure, Undefined, Undefined);
	Warehouse = FillingStructure.Warehouse;
	
	If Not ValueIsFilled(Warehouse) Then
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	EndIf;
	
EndProcedure

&AtServer
Procedure GroupPagesOnCurrentPageChangeServer(CurrentPageName)
	
	CurrentPage = Items[CurrentPageName];
	
	If CurrentPage = Items.PageReceipt Then
		ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Warehouse, Premise, ReceivingArea);
		Items.Warehouse.Enabled = True;
		Items.Premise.Enabled = True;
		Items.ReceivingArea.AutoMarkIncomplete = False;
		Items.ReceivingArea.MarkIncomplete = False;
	ElsIf CurrentPage = Items.PlacementPage Then
		Items.Warehouse.Enabled = False;
		Items.Premise.Enabled = False;
		Items.ReceivingArea.AutoMarkIncomplete = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.GoodsPickingPlacement.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Ref = ReferencesArrray[0];
		Items.JobsInProgress.CurrentRow = Ref;
		Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.PlacementPage;
		ShowValue(Undefined, Ref);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure CreateJobsServer(SelectedRows)
	
	TableOfSelectedProducts = New ValueTable;
	TableOfSelectedProducts.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
	TableOfSelectedProducts.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfSelectedProducts.Columns.Add("Purpose",New TypeDescription("CatalogRef.Assignments"));
	TableOfSelectedProducts.Columns.Add("Series",New TypeDescription("CatalogRef.ItemsBatches"));
	
	If ByAllProducts <> 0 Then
		For Each ArrRow In SelectedRows Do
			
			FillPropertyValues(TableOfSelectedProducts.Add(), ArrRow);
			
		EndDo;
	EndIf;
	Manager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = Manager;
	
	Query.Text =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series
	|INTO RequestProductTable
	|FROM
	|	&TableOfSelectedProducts AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsInStorageBinsBalance.Products AS Products,
	|	GoodsInStorageBinsBalance.Characteristic AS Characteristic,
	|	GoodsInStorageBinsBalance.Purpose AS Purpose,
	|	GoodsInStorageBinsBalance.Series,
	|	GoodsInStorageBinsBalance.Package AS Package,
	|	CASE
	|		WHEN GoodsInStorageBinsBalance.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
	|			THEN CAST(GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance - 0.5 AS NUMBER(15, 0))
	|		ELSE GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance
	|	END AS NumberOfPackages
	|INTO ProductsTable
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(
	|			,
	|			(&ByAllProducts
	|				OR (Products, Characteristic, Series, Purpose) IN
	|					(SELECT
	|						Table.Products AS Products,
	|						Table.Characteristic AS Characteristic,
	|						Table.Series AS Series,
	|				        Table.Purpose AS Purpose
	|					FROM
	|						RequestProductTable AS Table))
	|				AND Cell = &AcceptanceZones) AS GoodsInStorageBinsBalance
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS PoliciesSeriesAccounting
	|		ON GoodsInStorageBinsBalance.Products.ProductKind = PoliciesSeriesAccounting.Ref
	|			AND (PoliciesSeriesAccounting.Warehouse = &Warehouse)
	|WHERE
	|	GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RequestProductTable";

	Query.SetParameter("AcceptanceZones", ReceivingArea);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("TableOfSelectedProducts", TableOfSelectedProducts);
	Query.SetParameter("ByAllProducts", ByAllProducts = 0);
	
	Results = Query.ExecuteBatch(); 
	
	Selection = Results[1].Select();
	Selection.Next();
	
	If Selection.Count = 0 Then
		MessageText = NStr("vi = 'Không tạo nhiệm vụ sắp xếp: tất cả hàng hóa hoặc là đã được sắp xếp hoặc là đã có nhiệm vụ sắp xếp đối với các hàng hóa đó.';
							|ru = 'Задания на размещение не сформированы: все товары или уже размещены, или по ним уже есть задания на размещение.';
							|en = 'Cannot generate a Put-away task: all items are already in storage bins or in Put-away lists.'; fa = 'Cannot generate a Put-away task: all items are already in storage bins or in Put-away lists.';
							|it = 'I task per collocamento non sono stati generati: tutti i prodotti sono stati già collocati o sono già presenti i task per collocamento.';
							|pl = 'Nie utworzono zadań na rozmieszczenie: wszystkie wiersze pozycji lub już są rozmieszczone, lub według nich już są zadania na rozmieszczenie.';
							|tr = 'Yerleştirme görevleri oluşturulmadı: tüm ürünler ya zaten yerleştirildi ya da bunlar için zaten yerleştirme görevleri mevcut.'");
		Common.MessageToUser(MessageText);
		Return;
	EndIf;
	
	CheckError = False;
	
	If CustomizeGenerationByWorkAreas = "ByASingleWarehouseZone" Then
 		ReturnStructure = WarehousesServer.PlaceGoodsInCells(Manager, Warehouse, Premise, WarehouseZone, ReceivingArea, CheckError, False);
	Else
		ReturnStructure = WarehousesServer.PlaceGoodsInCells(Manager, Warehouse, Premise, Catalogs.WarehouseZones.EmptyRef(), ReceivingArea, CheckError, False);
	EndIf;
	
	If CheckError Then
		Return;
	EndIf;
	
	If ReturnStructure.ResultsTable.Count() = 0 Then
		MessageText = NStr("vi = 'Không tạo nhiệm vụ sắp xếp: không thể sắp xếp mặt hàng theo quy tắc sắp xếp.';
							|ru = 'Задания на размещение не сформированы: не удалось разместить номенклатуру согласно правилам размещения.';
							|en = 'Cannot generate a Put-away task due to the specified rules.'; fa = 'Cannot generate a Put-away task due to the specified rules.';
							|it = 'I task per collocamento non sono stati generati: impossibile collocare l''articolo in base alle regole di collocamento.';
							|pl = 'Nie utworzono zadań na rozmieszczenie: nie udało się rozmieścić produkty zgodnie z regułami rozmieszczenia.';
							|tr = 'Yerleştirme görevleri oluşturulmadı: ürün gamı, yerleştirme kurallarına göre yerleştirilemedi.'");
		Common.MessageToUser(MessageText);
		Return;
	EndIf;
	
	If CustomizeGenerationByWorkAreas = "GroupByWarehouseZones" Then
		
		RequestPlots = New Query;
		RequestPlots.Text = "SELECT
		|	WarehouseZones.Ref AS WarehouseZone,
		|	WarehouseZones.LimitByWeight,
		|	WarehouseZones.LimitationByWeight,
		|	WarehouseZones.LimitByVolume,
		|	WarehouseZones.LimitationByVolume
		|FROM
		|	Catalog.WarehouseZones AS WarehouseZones
		|WHERE
		|	WarehouseZones.Owner = &Warehouse
		|	AND WarehouseZones.Premise = &Premise";
		
		RequestPlots.SetParameter("Warehouse",Warehouse);
		RequestPlots.SetParameter("Premise",Premise);
		
		TableOfWorkPlots = RequestPlots.Execute().Unload();
		
		NewRow = TableOfWorkPlots.Add();
		NewRow.WarehouseZone = Catalogs.WarehouseZones.EmptyRef();
		NewRow.LimitByVolume = False;
		NewRow.LimitByWeight = False;
		
	Else	
		TableOfWorkPlots = New ValueTable;
		TableOfWorkPlots.Columns.Add("WarehouseZone", New TypeDescription("CatalogRef.WarehouseZones"));
		NewRow = TableOfWorkPlots.Add();
		If CustomizeGenerationByWorkAreas = "WithoutBreakdownByWarehouseZones" Then
			NewRow.WarehouseZone = Catalogs.WarehouseZones.EmptyRef();
		Else
			NewRow.WarehouseZone = WarehouseZone;
		EndIf;
		
	EndIf;
	
	ImpossibleSet = 9999999999;
	
	For Each WorkingSectionLine In TableOfWorkPlots Do
		
		If CustomizeGenerationByWorkAreas = "GroupByWarehouseZones" Then
			MaximumVolume_ = ?(WorkingSectionLine.LimitByVolume, WorkingSectionLine.LimitationByVolume, ImpossibleSet);
			MaximumWeight = ?(WorkingSectionLine.LimitByWeight, WorkingSectionLine.LimitationByWeight, ImpossibleSet);
		Else
			MaximumVolume_ = ?(LimitByVolume, LimitationByVolume, ImpossibleSet);
			MaximumWeight = ?(LimitByWeight, LimitationByWeight, ImpossibleSet);
		EndIf;
			
		If CustomizeGenerationByWorkAreas <> "WithoutBreakdownByWarehouseZones" Then
			FoundRows = ReturnStructure.ResultsTable.FindRows(New Structure("WarehouseZone",WorkingSectionLine.WarehouseZone));
			ResultTable2 = ReturnStructure.ResultsTable.Copy(FoundRows);
			
			If ResultTable2.Count() = 0
				And TableOfWorkPlots.Count() = 1 Then
				MessageText = NStr("vi = 'Không có hàng hóa để sắp xếp theo vùng làm việc %WarehouseZone%';
									|ru = 'Нет товаров для размещения по рабочему участку %WarehouseZone%';
									|en = 'No goods to put away by warehouse area %WarehouseZone%'; fa = 'No goods to put away by warehouse area %WarehouseZone%';
									|it = 'Non ci sono prodotti da collocare nell''area di lavoro %WarehouseZone%';
									|pl = 'Brak towarów do rozmieszczenia według obszaru roboczego %WarehouseZone%';
									|tr = 'Çalışma alanına yerleştirilecek ürün mevcut değil %WarehouseZone%'");
				MessageText = StrReplace(MessageText," %WarehouseZone%", WorkingSectionLine.WarehouseZone);
				
				Common.MessageToUser(MessageText);
			EndIf;
			
		Else
			ResultTable2 = ReturnStructure.ResultsTable;
		EndIf;
		
		ResultTable2 = SplitLinesByConstraints(ResultTable2, MaximumVolume_, MaximumWeight);
		
		// Splitting by weight and volume. Agreements:
		//	- one person goes to one cell (i.e. the line of the placement result is not split)
		//  - if the weight (volume) of one line is greater than the limits - a separate document is created,
		//		the weight (volume) of which will be greater than the maximum
		//	- splitting by weight (volume) is not optimal, because it is more important to preserve the order of traversal
		//			(it is better to have more tasks, but each one can be bypassed faster).
		
		DocumentScope    = 0;
		DocumentWeight	  = 0;
		CurrentDocument = NewPlacementTask(WorkingSectionLine.WarehouseZone);
		
		PopulationTable = ResultTable2.CopyColumns();
		
		QuantityProcessed = 0;
		
		For Each RowOfTables In ResultTable2 Do

			If (DocumentScope + RowOfTables.PackageVolume * RowOfTables.NumberOfPackages) > MaximumVolume_
				Or (DocumentWeight + RowOfTables.PackageWeight * RowOfTables.NumberOfPackages) > MaximumWeight Then

				WarehousesServer.AddMultiTurnContainerToPlacementTable(PopulationTable);
				CommonClientServer.SupplementTable(PopulationTable, CurrentDocument.GoodsPlacement);

				WriteDocument(CurrentDocument, DocumentScope, DocumentWeight);

				DocumentScope    = 0;
				DocumentWeight	  = 0;
				CurrentDocument = NewPlacementTask(WorkingSectionLine.WarehouseZone);
				PopulationTable.Clear();

			EndIf;

			NewRow = PopulationTable.Add();
			FillPropertyValues(NewRow, RowOfTables);

			DocumentScope    = DocumentScope + RowOfTables.PackageVolume * RowOfTables.NumberOfPackages;
			DocumentWeight	  = DocumentWeight + RowOfTables.PackageWeight * RowOfTables.NumberOfPackages;
			QuantityProcessed = QuantityProcessed + 1;

		EndDo;
		
		If PopulationTable.Count() > 0 Then
			
			WarehousesServer.AddMultiTurnContainerToPlacementTable(PopulationTable);
			CommonClientServer.SupplementTable(PopulationTable, CurrentDocument.GoodsPlacement);
			
			WriteDocument(CurrentDocument,DocumentScope,DocumentWeight);
			
		EndIf;
		
	EndDo;
	
	Manager.Close();
	SetSelectionsInMainLists();
EndProcedure

&AtServer
Function SplitLinesByConstraints(PlacementOfGoodsInCells, MaximumVolume_, MaximumWeight)

	ResultTable2 = PlacementOfGoodsInCells.CopyColumns();
	RowsWithRecalculatedQuantity = New Array;

	For Each DescriptionOfPlacement In PlacementOfGoodsInCells Do

		ItRemainsToPlace = DescriptionOfPlacement.NumberOfPackages;

		MaximumQuantityByVolume = MaximumQuantityByRestriction(
			DescriptionOfPlacement.PackageVolume,
			MaximumVolume_,
			ItRemainsToPlace);

		MaximumQuantityByWeight = MaximumQuantityByRestriction(
			DescriptionOfPlacement.PackageWeight,
			MaximumWeight,
			ItRemainsToPlace);

		MaximumNumberOfPlacements = Min(MaximumQuantityByVolume, MaximumQuantityByWeight);
		ToRecalculateQuantity = MaximumNumberOfPlacements < ItRemainsToPlace;
		
		While ItRemainsToPlace <> 0 Do

			AssignmentRow2 = ResultTable2.Add();
			FillPropertyValues(AssignmentRow2, DescriptionOfPlacement);

			If ItRemainsToPlace > MaximumNumberOfPlacements Then
				PlacedNumberOfPackages = MaximumNumberOfPlacements;
			Else
				PlacedNumberOfPackages = ItRemainsToPlace;
			EndIf;

			AssignmentRow2.NumberOfPackages = PlacedNumberOfPackages;

			ItRemainsToPlace = ItRemainsToPlace - PlacedNumberOfPackages;
			
			If ToRecalculateQuantity Then
				RowsWithRecalculatedQuantity.Add(AssignmentRow2);
			EndIf;
			
		EndDo;

	EndDo;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsWithRecalculatedQuantity, StructureOfActions,
		ResultTable2);

	Return ResultTable2;

EndFunction

&AtServerNoContext
Function MaximumQuantityByRestriction(Value, Restriction, DefaultValue)
	
	If Value = 0 Then
		Return DefaultValue;
	EndIf;
	
	Return Int(Restriction / Value);
	
EndFunction

&AtServer
Function NewPlacementTask(WarehouseZone)
	
	DocumentObject = Documents.GoodsPickingPlacement.CreateDocument();
	DocumentObject.Date 				= CurrentSessionDate();
	DocumentObject.Status 				= Enums.StatusesOfGoodsPickingPlacement.Prepared2;
	DocumentObject.OperationKind 			= Enums.OperationKindsOfGoodsPlacementPicking.Location;
	DocumentObject.Warehouse 				= Warehouse;
	DocumentObject.Premise 			= Premise;
	DocumentObject.ReceivingArea		 	= ReceivingArea;
	DocumentObject.EmployeeResponsible 		= Users.CurrentUser();
	
	DocumentObject.WarehouseZone 		= WarehouseZone;
	
	DocumentObject.Performer          = ?(AssignAssignee, Performer, Catalogs.Users.EmptyRef());
	
	Return DocumentObject;
	
EndFunction

&AtServer
Procedure WriteDocument(DocumentObject, VolumeM3, Weight)
	Try
		ParametersForSpecifyingSeries = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.GoodsPickingPlacement);
		ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject,ParametersForSpecifyingSeries.Location);
		DocumentObject.Write(DocumentWriteMode.Posting);
	Except
		CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure

&AtServer
Procedure WarehouseSpaceWhenServerChanges()
	
	StructureOfSetParameters = New Structure;
	If ValueIsFilled(Warehouse) Then
		StructureOfSetParameters.Insert("Warehouse",Warehouse);
		StructureOfSetParameters.Insert("Premise",Premise);
		
		UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise);
		
		If UseBinLocationWarehousing Then
			ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Warehouse, Premise, ReceivingArea);
			Items.GroupPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
			Items.ReceivingArea.Visible = True;
		Else
			Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
			Items.ReceivingArea.Visible = False;
		EndIf;
		
	Else
		StructureOfSetParameters.Insert("Warehouse",Undefined);
		StructureOfSetParameters.Insert("Premise",Undefined);
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
		Items.ReceivingArea.Visible = False;
	EndIf;
	
	WarehouseZone = Catalogs.WarehouseZones.EmptyRef();
	
	SetFormFunctionalOptionParameters(StructureOfSetParameters);
	UseGoodsReceiptNoteStatuses = GetFunctionalOption("UseGoodsReceiptNoteStatuses", New Structure("Warehouse", Warehouse));
	
	Items.ReceiptStatusFilter.ChoiceList.Clear();
	
	If UseGoodsReceiptNoteStatuses Then
		Items.ReceiptStatusFilter.ChoiceList.Add("", NStr("vi = 'Tất cả';
															|ru = 'Все';
															|en = 'All'; fa = 'همه';
															|it = 'Tutti';
															|pl = 'Wszystkie';
															|tr = 'Tümü'"));
		Items.ReceiptStatusFilter.ChoiceList.Add("AllToReceiving", NStr("vi = 'Tất cả để chấp nhận';
																		|ru = 'Все к приемке';
																		|en = 'All to receiving'; fa = 'همه برای دریافت';
																		|it = 'Totale per l''accettazione';
																		|pl = 'Wszystkie do odbioru';
																		|tr = 'Kabul edilecek tümü'"));
		Items.ReceiptStatusFilter.ChoiceList.Add("PendingReceiving", NStr("vi = 'Đang chờ chấp nhận';
																			|ru = 'Ожидается приемка';
																			|en = 'Receipt is expected'; fa = 'رسید مورد انتظار است';
																			|it = 'Accettazione prevista';
																			|pl = 'Oczekiwanie odbioru';
																			|tr = 'Kabul bekleniyor'"));
		Items.ReceiptStatusFilter.ChoiceList.Add("DuringReceiving", NStr("vi = 'Trong quá trình chấp nhận';
																		|ru = 'В процессе приемки';
																		|en = 'Receipt in progress'; fa = 'رسید در حال انجام';
																		|it = 'Nel corso di accettazione';
																		|pl = 'W trakcie odbioru';
																		|tr = 'Kabul sürecinde'"));
		Items.ReceiptStatusFilter.ChoiceList.Add("Overdelivery", NStr("vi = 'Giao lại';
																		|ru = 'Перепоставка';
																		|en = 'Overdelivery'; fa = 'تحویل مازاد';
																		|it = 'Fornitura in eccesso';
																		|pl = 'Ponowna dostawa';
																		|tr = 'Yeniden tedarik'"));
		Items.ReceiptStatusFilter.ChoiceList.Add("PendingInvoiceRegistration", NStr("vi = 'Trong Kỳ chờ giao hóa đơn';
																					|ru = 'Ожидается оформление накладных';
																					|en = 'Pending invoice registration'; fa = 'در انتظار ثبت فاکتور';
																					|it = 'È prevista l''emissione dei documenti di trasporto';
																					|pl = 'Oczekiwanie sporządzenia faktur';
																					|tr = 'İrsaliye düzenleme bekleniyor'"));
		ReceiptStatusFilter = "AllToReceiving";
	Else
		Items.ReceiptStatusFilter.ChoiceList.Add("", NStr("vi = 'Tất cả';
															|ru = 'Все';
															|en = 'All'; fa = 'همه';
															|it = 'Tutti';
															|pl = 'Wszystkie';
															|tr = 'Tümü'"));
		Items.ReceiptStatusFilter.ChoiceList.Add("PendingReceiving", NStr("vi = 'Đang chờ chấp nhận';
																			|ru = 'Ожидается приемка';
																			|en = 'Receipt is expected'; fa = 'رسید مورد انتظار است';
																			|it = 'Accettazione prevista';
																			|pl = 'Oczekiwanie odbioru';
																			|tr = 'Kabul bekleniyor'"));
		Items.ReceiptStatusFilter.ChoiceList.Add("Overdelivery", NStr("vi = 'Giao lại';
																		|ru = 'Перепоставка';
																		|en = 'Overdelivery'; fa = 'تحویل مازاد';
																		|it = 'Fornitura in eccesso';
																		|pl = 'Ponowna dostawa';
																		|tr = 'Yeniden tedarik'"));
		Items.ReceiptStatusFilter.ChoiceList.Add("PendingInvoiceRegistration", NStr("vi = 'Trong Kỳ chờ giao hóa đơn';
																					|ru = 'Ожидается оформление накладных';
																					|en = 'Pending invoice registration'; fa = 'در انتظار ثبت فاکتور';
																					|it = 'È prevista l''emissione dei documenti di trasporto';
																					|pl = 'Oczekiwanie sporządzenia faktur';
																					|tr = 'İrsaliye düzenleme bekleniyor'"));
		ReceiptStatusFilter = "PendingReceiving";
	EndIf;
	
	Items.NotesInProgressStatus.Visible = UseGoodsReceiptNoteStatuses;
	
	Items.CreateReturnOfUnreceivedGoods.Visible = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsSurplusesShortages", New Structure("Warehouse", Warehouse));
	
	SetSelectionsInMainLists();
	
	FillOrderFilterSelectionList();
	
	SetVisibilityOfPremises();
	
EndProcedure

&AtServer
Procedure SetColumnHeadersWeightVolume()
	UnitOfMeasureForVolume 	= String(Constants.UnitOfMeasureForVolume.Get());
	UnitOfMeasureForWeight 	= String(Constants.UnitOfMeasureForWeight.Get());
	
	ItemTitle = NStr("vi = 'Thể tích, %UnitOfMeasure%';
					|ru = 'Объем, %UnitOfMeasure%';
					|en = 'Volume, %UnitOfMeasure%'; fa = 'Volume, %UnitOfMeasure%';
					|it = 'Volume, %UnitOfMeasure%';
					|pl = 'Objętość, %UnitOfMeasure%';
					|tr = 'Hacim, %UnitOfMeasure%'");
	ItemTitle = StrReplace(ItemTitle, "%UnitOfMeasure%", UnitOfMeasureForVolume); 
	Items.JobsInProgress.ChildItems.MovementInWorkVolumePlacement.Title = ItemTitle;
	
	ItemTitle = NStr("vi = 'Trọng lượng (cả bì), %UnitOfMeasure%';
					|ru = 'Вес (брутто), %UnitOfMeasure%';
					|en = 'Weight (gross), %UnitOfMeasure%'; fa = 'Weight (gross), %UnitOfMeasure%';
					|it = 'Peso (lordo), %UnitOfMeasure%';
					|pl = 'Waga (brutto), %UnitOfMeasure%';
					|tr = 'Ağırlık (brüt), %UnitOfMeasure%'");
	ItemTitle = StrReplace(ItemTitle, "%UnitOfMeasure%", UnitOfMeasureForWeight); 
	Items.JobsInProgress.ChildItems.MovementInWorkWeightPlacement.Title   = ItemTitle;
EndProcedure

&AtServer
Procedure SetSelectionsInMainLists()
	
	FillInReceiptOrders();
	
	ProductPoolPlacement.Parameters.SetParameterValue("ReceivingArea", ReceivingArea);
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.StatusesOfGoodsPickingPlacement.Prepared2);
	StatusesList.Add(Enums.StatusesOfGoodsPickingPlacement.InProgress);
	
	CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Status", StatusesList, DataCompositionComparisonType.InList,,FilterJobs <> "");
	CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Posted", True,,,FilterJobs <> "");
	
	CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Warehouse", Warehouse, DataCompositionComparisonType.InList,,True);
	CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Premise", Premise, DataCompositionComparisonType.InList,,True);
			
	Items.ProductPoolPlacement.Refresh();
	
EndProcedure

&AtServer
Procedure SetSelectionsInDependentLists(ReceiptReferenceOrder)
	
	CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "ReceivingArea", ReceivingArea,
														DataCompositionComparisonType.InList,,ValueIsFilled(ReceivingArea));
	CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref.ReceivingArea",ReceivingArea,
														DataCompositionComparisonType.InList,,ValueIsFilled(ReceivingArea));
	TypesList = New ValueList;
	TypesList.Add(Type("DocumentRef.GoodsReceiptNote"));
	TypesList.Add(Type("DocumentRef.GoodsTransferNote"));
	CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Type", TypesList, DataCompositionComparisonType.InList,,True);
	
	CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Warehouse", Warehouse, DataCompositionComparisonType.Equal,,True);
	CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "ReceivingWareroom", Premise, DataCompositionComparisonType.Equal,,ValueIsFilled(Premise));
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.GoodsReceiptNoteStatuses.ToReceive);
	StatusesList.Add(Enums.GoodsReceiptNoteStatuses.InProgress);
	StatusesList.Add(Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired);
	StatusesList.Add(Enums.TransferNoteStatuses.ToShip);
	
	If FilterNotes = "" Then
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Status", StatusesList, DataCompositionComparisonType.InList,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Posted", True, DataCompositionComparisonType.Equal,,False);
	ElsIf FilterNotes = "ForReceiving" Then	
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Status", StatusesList, DataCompositionComparisonType.InList,,True);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Posted", True, DataCompositionComparisonType.Equal,,True);
	ElsIf FilterNotes = "ByCurrentReference" Then	
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Status", StatusesList, DataCompositionComparisonType.InList,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Posted", True, DataCompositionComparisonType.Equal,,False);
		GoodsReceiptNotes = ReceiptOrdersByOrderOf(ReceiptReferenceOrder);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", GoodsReceiptNotes, DataCompositionComparisonType.InList,,True);									
	EndIf;
		
	If Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.PlacementPage Then
		Items.ProductPoolPlacement.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatedList_4(SetOfLists, ReceiptReferenceOrder = Undefined)
	If SetOfLists = "Inpayment" Then
		FillInReceiptOrders();
		Items.NotesInProgress.Refresh();
		SetSelectionsInDependentLists(ReceiptReferenceOrder);
	Else
		Items.ProductPoolPlacement.Refresh();
		Items.JobsInProgress.Refresh();
	EndIf;
EndProcedure

&AtClient
Function ReceiptReferenceOrder()
	
	If Items.ReceiptOrders.CurrentData <> Undefined Then
		Return Items.ReceiptOrders.CurrentData.ReferenceOrder;
	EndIf;
	
	Return PredefinedValue("Document.VendorInvoice.EmptyRef");
	
EndFunction

&AtServer
Procedure FillOrderFilterSelectionList()
	
	// We will add or remove the "KPriemke" element from the Filter Order field selection list
	// , depending on the use of order statuses in the selected warehouse.
	
	ChoiceList  = Items.FilterNotes.ChoiceList;
	ListItem = ChoiceList.FindByValue("ForReceiving");
	
	If WarehousesServer.UseOrderStatuses(Warehouse, True, False) Then
		If ListItem = Undefined Then
			ListItem = ChoiceList.Insert(1, "ForReceiving");
		EndIf;
		ListItem.Presentation = NStr("vi = 'Cần tiếp nhận';
									|ru = 'К приемке';
									|en = 'For receiving'; fa = 'برای دریافت';
									|it = 'Per l''accettazione';
									|pl = 'Do odbioru';
									|tr = 'Kabul edilecek'");
	Else
		If ListItem <> Undefined Then
			If FilterNotes = "ForReceiving" Then
				FilterNotes = ChoiceList[0].Value; // the new selection will be set later, when calling installselection of dependent lists
			EndIf;
			ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfPremises()
	
	UseWarerooms = WarehousesServer.UseWarerooms(Warehouse,CurrentSessionDate());
	Items.Premise.Visible                = UseWarerooms;
	Items.OrdersAreInOperation.Visible   = UseWarerooms;
	
EndProcedure

&AtServer
Procedure FillInReceiptOrders()
	
	If Not ValueIsFilled(Warehouse) Then
		ReceiptOrders.Clear();
		Return;
	EndIf;
	
	If Not Users.IsFullUser(Undefined) Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref = &Warehouse";
		
		Query.SetParameter("Warehouse", Warehouse);
		
		If Query.Execute().IsEmpty() Then
			ReceiptOrders.Clear();
			Return;
		EndIf;
		
		SetPrivilegedMode(True);
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsDueCurBalances.DocumentInflow AS DocumentInflow,
	|	GoodsDueCurBalances.Sender AS Sender,
	|	GoodsDueCurBalances.Products AS Products,
	|	GoodsDueCurBalances.Characteristic AS Characteristic,
	|	GoodsDueCurBalances.Purpose AS Purpose,
	|	GoodsDueCurBalances.ControlledLotReference AS ControlledLotReference,
	|	GoodsDueCurBalances.Warehouse AS Warehouse,
	|	GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance AS GoodsReceiptNotesToRegisterBalance,
	|	GoodsDueCurBalances.ToRegisterGoodsReceiptsBalance AS ToRegisterGoodsReceiptsBalance,
	|	GoodsDueCurBalances.AcceptsBalance AS AcceptsBalance,
	|	GoodsDueCurBalances.BusinessOperation AS EconomicOperationForFilter
	|INTO GoodsDueCurBalances
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(, Warehouse = &Warehouse) AS GoodsDueCurBalances
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Warehouse,
	|	DocumentInflow,
	|	Sender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForExecutionOfOrdersTurnover.Products AS Products,
	|	GoodsForExecutionOfOrdersTurnover.Characteristic AS Characteristic,
	|	GoodsForExecutionOfOrdersTurnover.Purpose AS Purpose,
	|	GoodsForExecutionOfOrdersTurnover.ControlledLotReference AS ControlledLotReference,
	|	GoodsForExecutionOfOrdersTurnover.Warehouse AS Warehouse,
	|	GoodsForExecutionOfOrdersTurnover.DocumentInflow AS DocumentInflow,
	|	GoodsForExecutionOfOrdersTurnover.Sender AS Sender,
	|	GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterTurnover AS GoodsReceiptNotesToRegisterTurnover,
	|	GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt AS GoodsReceiptNotesToRegisterReceipt,
	|	GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterExpense AS GoodsReceiptNotesToRegisterExpense,
	|	GoodsForExecutionOfOrdersTurnover.AcceptsTurnover AS AcceptsTurnover,
	|	GoodsForExecutionOfOrdersTurnover.AcceptsReceipt AS AcceptsReceipt,
	|	GoodsForExecutionOfOrdersTurnover.AcceptsExpense AS AcceptsExpense
	|INTO GoodsForExecutionOfOrdersTurnover
	|FROM
	|	AccumulationRegister.GoodsToReceive.Turnovers(, , , &SpeedFilter) AS GoodsForExecutionOfOrdersTurnover
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Warehouse,
	|	DocumentInflow,
	|	Sender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS DocumentInflow,
	|	GoodsToBeReceivedBalancesAsOfDate.Sender AS Sender,
	|	GoodsToBeReceivedBalancesAsOfDate.Products AS Products,
	|	GoodsToBeReceivedBalancesAsOfDate.Characteristic AS Characteristic,
	|	GoodsToBeReceivedBalancesAsOfDate.Purpose AS Purpose,
	|	GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference AS ControlledLotReference,
	|	MIN(GoodsToBeReceivedBalancesAsOfDate.Series) AS Series,
	|	GoodsToBeReceivedBalancesAsOfDate.Warehouse AS Warehouse,
	|	GoodsToBeReceivedBalancesAsOfDate.BusinessOperation AS BusinessOperation,
	|	SUM(GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance) AS GoodsReceiptNotesToRegisterBalance,
	|	MAX(GoodsToBeReceivedBalancesAsOfDate.ToRegisterGoodsReceiptsBalance) AS ToRegisterGoodsReceiptsBalance,
	|	SUM(GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance) AS AcceptsBalance
	|INTO GoodsToBeReceivedBalancesAsOfDate
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			&DateOfReceipt,
	|			(Products, Characteristic, Purpose, ControlledLotReference, Warehouse, DocumentInflow, Sender, BusinessOperation) IN
	|				(SELECT
	|					FilterProductsForReceipt.Products,
	|					FilterProductsForReceipt.Characteristic,
	|					FilterProductsForReceipt.Purpose,
	|					FilterProductsForReceipt.ControlledLotReference,
	|					FilterProductsForReceipt.Warehouse,
	|					FilterProductsForReceipt.DocumentInflow,
	|					FilterProductsForReceipt.Sender,
	|					FilterProductsForReceipt.EconomicOperationForFilter AS BusinessOperation
	|				FROM
	|					GoodsDueCurBalances AS FilterProductsForReceipt)) AS GoodsToBeReceivedBalancesAsOfDate
	|
	|GROUP BY
	|	GoodsToBeReceivedBalancesAsOfDate.Characteristic,
	|	GoodsToBeReceivedBalancesAsOfDate.DocumentInflow,
	|	GoodsToBeReceivedBalancesAsOfDate.Products,
	|	GoodsToBeReceivedBalancesAsOfDate.Sender,
	|	GoodsToBeReceivedBalancesAsOfDate.Warehouse,
	|	GoodsToBeReceivedBalancesAsOfDate.BusinessOperation,
	|	GoodsToBeReceivedBalancesAsOfDate.Purpose,
	|	GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Warehouse,
	|	DocumentInflow,
	|	Sender,
	|	BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.ReferenceOrder AS ReferenceOrder,
	|	NestedQuery.Sender AS Sender,
	|	NestedQuery.ControlledLotReference AS ControlledLotReference,
	|	NestedQuery.BusinessOperation AS BusinessOperation,
	|	MAX(NestedQuery.Number) AS Number,
	|	MAX(NestedQuery.Date) AS Date,
	|	MAX(NestedQuery.IncomingDocumentNumber) AS IncomingDocumentNumber,
	|	MAX(NestedQuery.IncomingDocumentDate) AS IncomingDocumentDate,
	|	MIN(NestedQuery.Overdelivery) AS Overdelivery,
	|	MIN(NestedQuery.State) AS State,
	|	CASE
	|		WHEN MIN(NestedQuery.State) = 1
	|			THEN VALUE(Enum.GoodsReceiptStates.DuringReceiving)
	|		WHEN MIN(NestedQuery.State) = 2
	|			THEN VALUE(Enum.GoodsReceiptStates.PendingReceiving)
	|		WHEN MIN(NestedQuery.State) = 3
	|			THEN VALUE(Enum.GoodsReceiptStates.Overdelivery)
	|		WHEN MIN(NestedQuery.State) = 4
	|			THEN VALUE(Enum.GoodsReceiptStates.PendingInvoiceRegistration)
	|		ELSE VALUE(Enum.GoodsReceiptStates.EmptyRef)
	|	END AS ReceiptState,
	|	NestedQuery.DocumentType AS DocumentType
	|FROM
	|	(SELECT
	|		GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS ReferenceOrder,
	|		GoodsToBeReceivedBalancesAsOfDate.Sender AS Sender,
	|		GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference AS ControlledLotReference,
	|		GoodsToBeReceivedBalancesAsOfDate.BusinessOperation AS BusinessOperation,
	|		CASE
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Number AS STRING(11))
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
	|				THEN CAST(CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Number AS STRING(11))
	|			ELSE ISNULL(DocumentsRegistry.IBDocumentNumber, """")
	|		END AS Number,
	|		CASE
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Date
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
	|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Date
	|			ELSE ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1))
	|		END AS Date,
	|		CASE
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|					OR GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
	|				THEN """"
	|			ELSE ISNULL(DocumentsRegistry.SourceDocumentNumber, """")
	|		END AS IncomingDocumentNumber,
	|		CASE
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|					OR GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
	|				THEN DATETIME(1, 1, 1)
	|			ELSE ISNULL(DocumentsRegistry.SourceDocumentDate, DATETIME(1, 1, 1))
	|		END AS IncomingDocumentDate,
	|		CASE
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Description
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
	|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Description
	|			WHEN &ConditionsForUsingRegistryBusinessOperation
	|				THEN PRESENTATION(DocumentsRegistry.BusinessOperation)
	|			ELSE PRESENTATION(VALUETYPE(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow))
	|		END AS DocumentType,
	|		CASE
	|			WHEN GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance - GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance < 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS Overdelivery,
	|		CASE
	|			WHEN &ConditionStateDuringAcceptance
	|				THEN 1
	|			WHEN &ConditionStatePendingAcceptance
	|				THEN 2
	|			WHEN &ConditionStateReDelivery
	|				THEN 3
	|			WHEN ISNULL(GoodsToBeReceivedBalancesAsOfDate.ToRegisterGoodsReceiptsBalance, 0) <> 0
	|				THEN 4
	|			WHEN &ConditionStateTolerance
	|				THEN 6
	|			ELSE 404
	|		END AS State
	|	FROM
	|		GoodsToBeReceivedBalancesAsOfDate AS GoodsToBeReceivedBalancesAsOfDate
	|			LEFT JOIN GoodsDueCurBalances AS GoodsDueCurBalances
	|			ON GoodsToBeReceivedBalancesAsOfDate.Products = GoodsDueCurBalances.Products
	|				AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsDueCurBalances.Characteristic
	|				AND GoodsToBeReceivedBalancesAsOfDate.Purpose = GoodsDueCurBalances.Purpose
	|				AND GoodsToBeReceivedBalancesAsOfDate.Sender = GoodsDueCurBalances.Sender
	|				AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsDueCurBalances.Warehouse
	|				AND GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsDueCurBalances.DocumentInflow
	|				AND GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference = GoodsDueCurBalances.ControlledLotReference
	|			LEFT JOIN GoodsForExecutionOfOrdersTurnover AS GoodsForExecutionOfOrdersTurnover
	|			ON GoodsToBeReceivedBalancesAsOfDate.Products = GoodsForExecutionOfOrdersTurnover.Products
	|				AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsForExecutionOfOrdersTurnover.Characteristic
	|				AND GoodsToBeReceivedBalancesAsOfDate.Purpose = GoodsForExecutionOfOrdersTurnover.Purpose
	|				AND GoodsToBeReceivedBalancesAsOfDate.Sender = GoodsForExecutionOfOrdersTurnover.Sender
	|				AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsForExecutionOfOrdersTurnover.Warehouse
	|				AND GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsForExecutionOfOrdersTurnover.DocumentInflow
	|				AND GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference = GoodsForExecutionOfOrdersTurnover.ControlledLotReference
	|			LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			ON GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = DocumentsRegistry.Ref
	|				AND (NOT DocumentsRegistry.AdditionalRecord)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CounterpartyContracts.Ref,
	|		CounterpartyContracts.Partner,
	|		VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|		CounterpartyContracts.BusinessOperation,
	|		CAST(CounterpartyContracts.Number AS STRING(11)),
	|		CounterpartyContracts.Date,
	|		"""",
	|		DATETIME(1, 1, 1),
	|		CounterpartyContracts.Description,
	|		FALSE,
	|		5
	|	FROM
	|		Catalog.CounterpartyContracts AS CounterpartyContracts
	|	WHERE
	|		CounterpartyContracts.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices)
	|		AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|		AND NOT CounterpartyContracts.DeletionMark) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ReferenceOrder,
	|	NestedQuery.Sender,
	|	NestedQuery.ControlledLotReference,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.DocumentType
	|
	|HAVING
	|	MIN(NestedQuery.State) IN (&ConditionByState)
	|
	|ORDER BY
	|	Date";
	
	ConditionsForUsingRegistryBusinessOperation = "VALUETYPE(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow) = TYPE(Document.OtherGoodsRecordingAsReceived)";
	ConditionsForUsingRegistryBusinessOperation = ConditionsForUsingRegistryBusinessOperation + "
			|				OR VALUETYPE(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow) = TYPE(Document.MovementOfProductsAndMaterials)";
	Query.Text = StrReplace(Query.Text,"&ConditionsForUsingRegistryBusinessOperation", ConditionsForUsingRegistryBusinessOperation);
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving <> 0 Then
		
		ConditionStatePendingAcceptance = "GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance > CASE
			|			WHEN GoodsToBeReceivedBalancesAsOfDate.Products.UnitOfMeasure.MeasuredValueType
			|					IN (&DimensionalTypesOfUnits)
			|				THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|					* ISNULL(GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt,0)
			|			ELSE 0
			|		END
			|	AND GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance = 0";
		
		ConditionStateReDelivery = "GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance < CASE
			|			WHEN GoodsToBeReceivedBalancesAsOfDate.Products.UnitOfMeasure.MeasuredValueType
			|					IN (&DimensionalTypesOfUnits)
			|				THEN - &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|					* ISNULL(GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt,0)
			|			ELSE 0
			|		END
			|	AND GoodsDueCurBalances.AcceptsBalance = 0";
		
		ConditionStateDuringAcceptance = "GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance > 0";
		
		ConditionStateTolerance = "GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance <= CASE
			|			WHEN GoodsToBeReceivedBalancesAsOfDate.Products.UnitOfMeasure.MeasuredValueType IN(&DimensionalTypesOfUnits)
			|				THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|					* ISNULL(GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt, 0)
			|			ELSE 0
			|		END
			|		AND GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance >= CASE
			|			WHEN GoodsToBeReceivedBalancesAsOfDate.Products.UnitOfMeasure.MeasuredValueType IN(&DimensionalTypesOfUnits)
			|				THEN -&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|					* ISNULL(GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt, 0)
			|			ELSE 0
			|		END
			|		AND GoodsDueCurBalances.AcceptsBalance = 0";
		
		Query.Text = StrReplace(Query.Text,"&ConditionStatePendingAcceptance", 	ConditionStatePendingAcceptance);
		Query.Text = StrReplace(Query.Text,"&ConditionStateReDelivery", 		ConditionStateReDelivery);
		Query.Text = StrReplace(Query.Text,"&ConditionStateDuringAcceptance", 	ConditionStateDuringAcceptance);
		Query.Text = StrReplace(Query.Text,"&ConditionStateTolerance",ConditionStateTolerance);
		
		SpeedFilter =
		"				(Products, Characteristic, Purpose, ControlledLotReference, Warehouse, DocumentInflow, Sender) IN
		|					(SELECT
		|						GoodsDueCurBalances.Products,
		|						GoodsDueCurBalances.Characteristic,
		|						GoodsDueCurBalances.Purpose,
		|						GoodsDueCurBalances.ControlledLotReference,
		|						GoodsDueCurBalances.Warehouse,
		|						GoodsDueCurBalances.DocumentInflow,
		|						GoodsDueCurBalances.Sender
		|					FROM
		|						GoodsDueCurBalances AS GoodsDueCurBalances)";
		
		Query.Text = StrReplace(Query.Text,"&SpeedFilter", SpeedFilter);
		
	Else
		
		ConditionStatePendingAcceptance = "GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance > 0
											|	AND GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance = 0";
		
		ConditionStateReDelivery = "GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance < 0
											|	AND GoodsDueCurBalances.AcceptsBalance = 0";
		
		ConditionStateDuringAcceptance = "GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance > 0";
		
		Query.Text = StrReplace(Query.Text,"&ConditionStateReDelivery", ConditionStateReDelivery);
		Query.Text = StrReplace(Query.Text,"&ConditionStatePendingAcceptance", ConditionStatePendingAcceptance);
		Query.Text = StrReplace(Query.Text,"&ConditionStateDuringAcceptance", ConditionStateDuringAcceptance);
		Query.Text = StrReplace(Query.Text,"&ConditionStateTolerance","FALSE");
		
		Query.Text = StrReplace(Query.Text,"&SpeedFilter", "FALSE");
		
	EndIf;
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	
	Query.SetParameter("Warehouse", Warehouse);
	If ValueIsFilled(DateOfReceipt) Then
		Query.SetParameter("DateOfReceipt", New Boundary(EndOfDay(DateOfReceipt), BoundaryType.Including));
	Else
		Query.SetParameter("DateOfReceipt", DateOfReceipt); 
	EndIf;
	
	ReceiptStatuses = New Array;
	
	ComplianceOfIndexStates = New Map;
	
	ComplianceOfIndexStates.Insert(Enums.GoodsReceiptStates.DuringReceiving, 1);
	ComplianceOfIndexStates.Insert(Enums.GoodsReceiptStates.PendingReceiving, 2);
	ComplianceOfIndexStates.Insert(Enums.GoodsReceiptStates.Overdelivery, 3);
	ComplianceOfIndexStates.Insert(Enums.GoodsReceiptStates.PendingInvoiceRegistration, 4);
	ComplianceOfIndexStates.Insert(Enums.GoodsReceiptStates.EmptyRef(),5);

	If ReceiptStatusFilter = "" Then
		For Each EnumerationValue In Enums.GoodsReceiptStates Do 
			ReceiptStatuses.Add(ComplianceOfIndexStates.Get(EnumerationValue));	
		EndDo;
		ReceiptStatuses.Add(ComplianceOfIndexStates.Get(Enums.GoodsReceiptStates.EmptyRef()));
	ElsIf ReceiptStatusFilter = "AllToReceiving" Then
		ReceiptStatuses.Add(ComplianceOfIndexStates.Get(Enums.GoodsReceiptStates.PendingReceiving));
		ReceiptStatuses.Add(ComplianceOfIndexStates.Get(Enums.GoodsReceiptStates.DuringReceiving));
		ReceiptStatuses.Add(ComplianceOfIndexStates.Get(Enums.GoodsReceiptStates.EmptyRef()));
	Else
		ReceiptStatuses.Add(ComplianceOfIndexStates.Get(Enums.GoodsReceiptStates[ReceiptStatusFilter]));
	EndIf;
	
	ReceiptStatuses.Add(404);
	
	Query.SetParameter("ConditionByState", ReceiptStatuses);
	
	// Let's remember the current row of the orders table
	If ValueIsFilled(Items.ReceiptOrders.CurrentRow) Then
		CurLineOfShipmentOrder = 
			ReceiptOrders.FindByID(Items.ReceiptOrders.CurrentRow);
		If CurLineOfShipmentOrder <> Undefined Then
			CurrentOrder = CurLineOfShipmentOrder.ReferenceOrder;
		EndIf;
	Else
		CurrentOrder = Undefined;
	EndIf;
	
	ReceiptOrders.Load(Query.Execute().Unload());
	
	// Restore the current line
	If ValueIsFilled(CurrentOrder) Then
		Rows = ReceiptOrders.FindRows(New Structure("ReferenceOrder", CurrentOrder));
		If Rows.Count() > 0 Then
			Items.ReceiptOrders.CurrentRow = Rows[0].GetID();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateReturnOfUnreceivedGoods(Command)
	
	Basis = New Structure;
	Basis.Insert("Warehouse", Warehouse);
	Basis.Insert("Premise", Premise);
	Basis.Insert("ReceivingArea", ReceivingArea);
	Basis.Insert("WarehouseOperation", PredefinedValue("Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient"));
	OpenForm("Document.GoodsReceiptNote.Form.DocumentForm",
				New Structure("Basis",Basis));
	
EndProcedure

&AtServer
Function DataForPrintingLabelsByOrder(ReferenceOrder)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsToBeReceivedBalancesAsOfDate.Products AS Products,
	|	GoodsToBeReceivedBalancesAsOfDate.Characteristic AS Characteristic,
	|	GoodsToBeReceivedBalancesAsOfDate.Series AS Series,
	|	GoodsToBeReceivedBalancesAsOfDate.Purpose,
	|	CASE
	|		WHEN GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance - GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance > 0
	|			THEN GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance - GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance
	|		ELSE 0
	|	END AS Count,
	|	CASE
	|		WHEN GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance - GoodsDueCurBalances.AcceptsBalance < 0
	|			THEN -(GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance - GoodsDueCurBalances.AcceptsBalance)
	|		ELSE 0
	|	END AS Overdelivery,
	|	GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance AS Accepts
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			&DateOfReceipt,
	|			DocumentInflow = &ReferenceOrder
	|				AND Warehouse = &Warehouse) AS GoodsToBeReceivedBalancesAsOfDate
	|		INNER JOIN AccumulationRegister.GoodsToReceive.Balance(
	|				,
	|				DocumentInflow = &ReferenceOrder
	|					AND Warehouse = &Warehouse) AS GoodsDueCurBalances
	|		ON GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsDueCurBalances.DocumentInflow
	|			AND GoodsToBeReceivedBalancesAsOfDate.Products = GoodsDueCurBalances.Products
	|			AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsDueCurBalances.Characteristic
	|			AND GoodsToBeReceivedBalancesAsOfDate.Series = GoodsDueCurBalances.Series
	|			AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsDueCurBalances.Warehouse
	|			AND GoodsToBeReceivedBalancesAsOfDate.Purpose = GoodsDueCurBalances.Purpose";
		
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("DateOfReceipt", DateOfReceipt);
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
		
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", Query.Execute().Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);

	Return PutToTempStorage(ResultingStructure);
	
EndFunction 

&AtServerNoContext
Function ReceiptOrdersByOrderOf(ReferenceOrder)

	Query = New Query;
	Query.Text = 		
	"SELECT DISTINCT
	|	GoodsReceiptNote.Ref
	|FROM
	|	Document.GoodsReceiptNote AS GoodsReceiptNote
	|WHERE
	|	GoodsReceiptNote.ReferenceOrder = &ReferenceOrder";
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);	
	GoodsReceiptNotes = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return GoodsReceiptNotes;
	
EndFunction

&AtServer
Procedure ChangingOrderListInProgress(ReceiptReferenceOrder) 
	FillInReceiptOrders();
	SetSelectionsInDependentLists(ReceiptReferenceOrder);
	Items.ProductPoolPlacement.Refresh();
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(ReceiptReferenceOrder)
	WarehouseSpaceWhenServerChanges();
	SetSelectionsInDependentLists(ReceiptReferenceOrder);
EndProcedure

&AtServer
Procedure SetSelectionsInAllLists(ReceiptReferenceOrder)
	
	SetSelectionsInMainLists();
	SetSelectionsInDependentLists(ReceiptReferenceOrder);
	
EndProcedure

#EndRegion

#EndRegion

#Region Performance

&AtClient
Procedure NotesInProgressSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.InboundWarehouseMangement.Form.Item.NotesInProgress.Selection");
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_DateOfReceipt" Then
		DateOfReceiptOnChange(Items.DateOfReceipt);
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
