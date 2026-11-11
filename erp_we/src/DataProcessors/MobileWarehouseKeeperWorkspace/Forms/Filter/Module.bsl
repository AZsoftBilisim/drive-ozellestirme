
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Literal = "Ref";
	Ref = Parameters[Literal];
	ShowProductPhotos = Parameters.ShowProductPhotos; 
	Seamless = Parameters.Seamless;
	Barcode = Parameters.Barcode;
	ScanningProcedure = Parameters.ScanningProcedure;
	
	LockDataForEdit(Ref,,UUID);
	
	FillForm();
		
	
	ThereIsRightToCheckWarrant = DataProcessors.MobileWarehouseKeeperWorkspace.HaveRightToCheckYourOrders();
	
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CreateMenu_("Pick");
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.GroupPages.CurrentPage = Items["InformationPage"] Then
		StandardProcessing = False;
		Cancel = True;
		CreateMenu_("Pick");
	EndIf;
	
EndProcedure 

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If UsedFormServer = UsedServer.Main Then
		// Peripherals
		If Source = "Peripherals" And IsInputAvailable() Then
			
			ThereIsRawEvent = MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent();
			
			If EventName = "ScanData" And ThereIsRawEvent Then
				
				Data = MobileWarehouseKeeperWorkspaceClient.ConvertDataFromScannerToStructure(Parameter);
				
				ProcessBarcode(Data);

			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PremiseOnChange(Item)
	
	FillInAcceptanceArea();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsPick

&AtClient
Procedure ProductsPickSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("Mode", "SelectionFromShipmentCell");
	FormParameters.Insert("LineNumber", ProductsPick.IndexOf(Items.ProductsPick.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Cell", Item.CurrentData.Cell);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("SelectionOrder_", ReferenceOrder);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsSelected_

&AtClient
Procedure ProductsSelected_Selection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("Mode", "EditingSelectionFromShipmentCell");
	FormParameters.Insert("LineNumber", ProductsSelected_.IndexOf(Items.ProductsSelected_.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Cell", Item.CurrentData.Cell);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("SelectionOrder_", ReferenceOrder);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Information(Command)
	
	Items.GroupPages.CurrentPage = Items["InformationPage"];
	HideMenu();
	
EndProcedure

&AtClient
Procedure GoToSelectSection(Command)
	
	CreateMenu_("Pick");
	
EndProcedure

&AtClient
Procedure GoToSelectedSection(Command)
	
	CreateMenu_("Picked");
	
EndProcedure

&AtClient
Procedure FinishSelection(Command)
	
	If ProductsSelected_.Count() = 0 Then
		Status(NStr("vi = 'Không thể hoàn tất việc lấy hàng, khi chưa chọn được mặt hàng nào.';
					|ru = 'Не возможно закончить отбор, пока не отобрано ни одного товара.';
					|en = 'Cannot finish picking until at least one item is selected.'; fa = 'Cannot finish picking until at least one item is selected.';
					|it = 'Cannot finish picking until at least one item is selected.';
					|pl = 'Cannot finish picking until at least one item is selected.';
					|tr = 'Toplama, hiçbir ürün toplanmış olmadığı için kapatılamaz.'"));
		Return;
	EndIf; 
		
	ValueList = New ValueList;	

	If ProductsPick.Count() And Seamless Then
		ValueList.Add("DoNotShip", NStr("vi = 'Hủy giao hàng';
										|ru = 'Отменить отгрузку товаров';
										|en = 'Cancel goods shipment'; fa = 'لغو ارسال کالا';
										|it = 'Cancel goods shipment';
										|pl = 'Cancel goods shipment';
										|tr = 'Ürün sevkiyatını iptal et'"));
		ValueList.Add("ForPicking", NStr("vi = 'Giữ nguyên lệnh để tiếp tục lấy hàng';
										|ru = 'Оставить ордер к отбору';
										|en = 'Leave the note for picking'; fa = 'باقی گذاشتن حواله برای برداشت';
										|it = 'Leave the note for picking';
										|pl = 'Leave the note for picking';
										|tr = 'Filtre için sipariş bırak'"));
		ValueList.Add("Continue", NStr("vi = 'Tiếp tục lấy hàng';
										|ru = 'Продолжить отбор';
										|en = 'Continue picking'; fa = 'ادامه برداشت';
										|it = 'Continue picking';
										|pl = 'Continue picking';
										|tr = 'Filtrelemeye devam et'"));
		MessageText = NStr("vi = 'Chưa chọn tất cả các mặt hàng được giao theo phiếu. Bạn muốn hủy giao các mặt hàng chưa được lấy trong lệnh và chuyển sang bước kiểm tra hoặc giữ nguyên phiếu để tiếp tục lấy hàng?';
							|ru = 'Отобраны не все товары, отгружаемые ордером. Отменить отгрузку не отобранных товаров в ордере и перевести ордер к проверке или оставить ордер к отбору?';
							|en = 'Not all the goods to ship under the goods issue are picked. Do you want to cancel shipment of unpicked goods in the goods issue and move the goods issue to check, or leave the goods issue for picking?'; fa = 'همه کالاهای قابل ارسال تحت صدور کالا برداشت نشده‌اند. آیا می‌خواهید ارسال کالاهای برداشت‌نشده در صدور کالا را لغو کرده و صدور کالا را به بررسی منتقل کنید، یا صدور کالا را برای برداشت باقی بگذارید؟';
							|it = 'Not all the goods to ship under the goods issue are picked. Do you want to cancel shipment of unpicked goods in the goods issue and move the goods issue to check, or leave the goods issue for picking?';
							|pl = 'Not all the goods to ship under the goods issue are picked. Do you want to cancel shipment of unpicked goods in the goods issue and move the goods issue to check, or leave the goods issue for picking?';
							|tr = 'Siparişle sevk edilen tüm ürünler seçilmedi. Siparişteki seçilmeyen ürünlerin sevkiyatını iptal edip siparişi incelemeye mi taşıyalım, yoksa siparişi seçili olarak mı tutalım?'");
		
		Notification = New CallbackDescription("AfterClosingQuestion_Continued", ThisObject);
		ShowQueryBox(Notification, MessageText, ValueList, 0);
	Else
		AfterClosingQuestion_Continued("ExitApp");
	EndIf;
	
EndProcedure

&AtClient
Procedure CollectEverything(Command)
	
	CollectEverythingOnServer();
	CreateMenu_("Accepted");
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("DocumentRef", Ref);
	FormParameters.Insert("PackageBarcodes", PackageBarcodes);
		
	If ScanningProcedure = "FirstScanCell" Then
		
		LongDesc = New CallbackDescription("CellScanResult", ThisObject);
		FormParameters.Insert("FindType", "CellSearch");
		
	Else
		
		LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
		FormParameters.Insert("FindType", "ProductItemsSearch");
		FormParameters.Insert("Organization", Organization);
		
	EndIf;
	
	If UsedFormServer = UsedServer.Main Then
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning", FormParameters,
			ThisObject,,,, LongDesc,
			FormWindowOpeningMode.Independent);
	Else
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanningOfflineMode", FormParameters,
			ThisObject,,,, LongDesc,
			FormWindowOpeningMode.Independent);
	EndIf;

EndProcedure

&AtClient
Procedure MarkingCodes(Command)
	LongDesc = New CallbackDescription("ChangePackageBarcodes", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("PackageBarcodes", PackageBarcodes);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.MarkingCodeList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
		
EndProcedure

&AtClient
Procedure CancelFilter(Command)
	
	RowIndex = ProductsSelected_.IndexOf(Items.ProductsSelected_.CurrentData);
	CancelFilterServer(RowIndex);
	
EndProcedure

&AtClient
Procedure CancelSelectionTask(Command)
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Đặt dấu xóa chứng từ';
									|ru = 'Пометить документ на удаление';
									|en = 'Mark the document for deletion'; fa = 'Mark the document for deletion';
									|it = 'Mark the document for deletion';
									|pl = 'Mark the document for deletion';
									|tr = 'Silinmek üzere belge işaretle'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục lấy hàng';
									|ru = 'Продолжить отбор';
									|en = 'Continue picking'; fa = 'ادامه برداشت';
									|it = 'Continue picking';
									|pl = 'Continue picking';
									|tr = 'Filtrelemeye devam et'"));
	
	Notification = New CallbackDescription("AfterClosingQuestionCancelSelectionTask", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Để hủy lấy hàng, cần đặt dấu xóa chứng từ lấy ra. Sau đó sẽ không thể quay lại chỉnh sửa. Bạn có muốn đặt dấu xóa không?';
									|ru = 'Для отмены отбора необходимо пометить на удаление документ отбора. Вернуться к редактированию будет невозможно. Пометить на удаление?';
									|en = 'To cancel picking, mark the picking document for deletion. It will be impossible to get back to editing. Mark the document for deletion?'; fa = 'To cancel picking, mark the picking document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|it = 'To cancel picking, mark the picking document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|pl = 'To cancel picking, mark the picking document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|tr = 'Filtreyi geri almak için, filtre belgesini silinmek üzere işaretlemeniz gerekir. Düzenleme yapılamaz. Silinmek üzere işaretlensin mi?'"), ValueList, 0);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Items.MarkingCodes.Visible = UseAccountingOfLabeledProducts And ThereAreLabeledProducts;
	
#If MobileStandaloneServer Then
	Items.FormCancelSelectionTask.Visible = False;
#Else
	Status = Common.ObjectAttributeValue(Ref, "Status");
	If Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2
		And AccessRight("InteractiveSetDeletionMark", Metadata.Documents.GoodsPickingPlacement) Then
		Items.FormCancelSelectionTask.Visible = True;
	Else
		Items.FormCancelSelectionTask.Visible = False;
	EndIf;
#EndIf
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
		
	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1);
	
	If Not BarcodesAreValid Then
		Return;
	EndIf;
		
	If Barcode = BarcodeData_1.Barcode Then  
		
		If ProductsSelected_.Count() = 0 Then
			ErrorText = NStr("vi = 'Không thể hoàn tất việc lấy hàng, khi chưa chọn được mặt hàng nào.';
							|ru = 'Не возможно закончить отбор, пока не отобрано ни одного товара.';
							|en = 'Cannot finish picking until at least one item is selected.'; fa = 'Cannot finish picking until at least one item is selected.';
							|it = 'Cannot finish picking until at least one item is selected.';
							|pl = 'Cannot finish picking until at least one item is selected.';
							|tr = 'Toplama, hiçbir ürün toplanmış olmadığı için kapatılamaz.'");
			Status(ErrorText);
			Return;
		EndIf;
				
		If ProductsPick.Count() And Seamless Then
			
			LongDesc = New CallbackDescription("AfterClosingQuestionForm", ThisObject);
			FormParameters = New Structure("Mode", "Filter");
			
			OpenForm(
				"DataProcessor.MobileWarehouseKeeperWorkspace.Form.QuestionFormScanning", FormParameters,
				ThisObject,,,, LongDesc, FormWindowOpeningMode.LockWholeInterface);
				
		Else
			FilterCompleted = FinishSelectionOnServer("ExitApp", "ExitApp");
		
			If FilterCompleted Then
				OpenSpendingOrderForm();
			Else
				Status(ErrorText);
			EndIf;
		EndIf;
		
		Return;
	EndIf;
	
	CellSearchFirst = (ScanningProcedure = "FirstScanCell");

	If CellSearchFirst Then
		
		CellData = CellDataByWK(BarcodeData_1.Barcode); 
		
		If ValueIsFilled(CellData.Cell) Then
			CellScanResult(CellData);
			Return;
		EndIf;
				
		Status(NStr("vi = 'Không tìm thấy ô theo mã vạch';
					|ru = 'Ячейка по штрихкоду не найдена';
					|en = 'Storage bin is not found by barcode'; fa = 'Storage bin is not found by barcode';
					|it = 'Storage bin is not found by barcode';
					|pl = 'Storage bin is not found by barcode';
					|tr = 'Barkod ile depo yeri bulunamadı'"));
	Else
		
		ProductData_9 = ItemDataBySchool(BarcodeData_1.Barcode); 
		
		If ValueIsFilled(ProductData_9) Then
			ResultOfScanningItem(ProductData_9);
			Return;
		EndIf;
		
		Status(NStr("vi = 'Không tìm thấy mặt hàng theo mã vạch';
					|ru = 'Номенклатура по штрихкоду не найдена';
					|en = 'Item is not found by barcode'; fa = 'Item is not found by barcode';
					|it = 'Item is not found by barcode';
					|pl = 'Item is not found by barcode';
					|tr = 'Barkod ile ürün bulunamadı'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CellScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("CompleteSelectionFromCell", ThisObject);
	
	ProductsInCell = New Array;
	
	For Each String In ProductsPick Do
		
		If String.Cell = Result.Cell Then
			
			Structure = StructureOfGoods();
			FillPropertyValues(Structure, String);
			
			ProductsInCell.Add(Structure);
			
		EndIf;
		
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("Cell",      Result.Cell);
	FormParameters.Insert("Goods",      ProductsInCell);
	FormParameters.Insert("Warehouse",       Warehouse);
	FormParameters.Insert("Premise",   Premise);
	FormParameters.Insert("Organization",   Organization);
	FormParameters.Insert("OperationType", 2);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Ref",      Ref);
	FormParameters.Insert("SelectionOrder_", ReferenceOrder);
	FormParameters.Insert("DocumentBarcode", Barcode);
    FormParameters.Insert("CellBarcode", Result.Barcode);
    FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PlacementIntoBins",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure ResultOfScanningItem(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Count() > 1 Then 
		
		LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
		
		FillingValues = New Structure;
		FillingValues.Insert("Goods", Result);
		FillingValues.Insert("Mode", "SelectItems");
		FillingValues.Insert("Barcode", "");
		
		FormParameters = New Structure;
		FormParameters.Insert("ScanningResult", FillingValues);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ScanSelectionForm", FormParameters,
			ThisObject,,,,LongDesc, FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ProductData_8 = Result[0]; 
		
		LongDesc = New CallbackDescription("AddProduct", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("Products", ProductData_8.Products);
		FormParameters.Insert("Characteristic", ProductData_8.Characteristic);
		FormParameters.Insert("Series", ProductData_8.Series);
		FormParameters.Insert("Package", ProductData_8.Package);
		FormParameters.Insert("Count", ProductData_8.Count);
		FormParameters.Insert("Mode", "SelectionFromShipmentCell");
		FormParameters.Insert("LineNumber", 0);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);
		FormParameters.Insert("PackageBarcode", ProductData_8.PackageBarcode);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Source", Ref);
		FormParameters.Insert("SelectionOrder_", ReferenceOrder);
		FormParameters.Insert("DocumentBarcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteSelectionFromCell(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CompleteSelectionFromCellAtServer(Result);
	If ValueIsFilled(Result.NextCellData) Then
		CellScanResult(Result.NextCellData);
	EndIf;

EndProcedure

&AtServer
Procedure CompleteSelectionFromCellAtServer(Result)
	
	OperationText = NStr("vi = 'Không cần lọc mặt hàng %1 trong bao bì %2 từ ô %3.';
						|ru = 'Не требуется отбор номенклатуры %1 в упаковке %2 из ячейки %3.';
						|en = 'Picking the %1 items in the %2 packaging unit from the %3 storage bin is not required.'; fa = 'Picking the %1 items in the %2 packaging unit from the %3 storage bin is not required.';
						|it = 'Picking the %1 items in the %2 packaging unit from the %3 storage bin is not required.';
						|pl = 'Picking the %1 items in the %2 packaging unit from the %3 storage bin is not required.';
						|tr = '%3 depo yerinden %2 paketleme ünitesi içindeki %1 ürün için filtre gerekli değil.'");
	
	GoodsTable = ProductsPick.Unload();
	
	FilterArray = Result.ArrayOfPlacements;
	Cell = Result.Cell;
	
	// Array of structures
	For Each String In FilterArray Do
		
		If String.NumberOfPackages <= 0 Then
			Continue;
		EndIf;
		
		PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(String.Package, String.Products);
		
		SearchSelection = New Structure;
		SearchSelection.Insert("Products",   String.Products);
		SearchSelection.Insert("Characteristic", String.Characteristic);
		SearchSelection.Insert("Series",          String.Series);
		SearchSelection.Insert("Package",       String.Package);
		SearchSelection.Insert("Cell",         Cell);
		
		ArrayToBeSelected = GoodsTable.FindRows(SearchSelection);
		
		If Not ArrayToBeSelected.Count() Then
			SearchSelection.Insert("Series", Catalogs.ItemsBatches.EmptyRef()); 
			ArrayToBeSelected = GoodsTable.FindRows(SearchSelection);
		EndIf;
		
		If Not ArrayToBeSelected.Count() And ScanningProcedure = "FirstScanProduct" Then
			ErrorText = ErrorText + ?(ValueIsFilled(ErrorText), Chars.LF, "") + StrTemplate(OperationText, 
				String.Products, String.Package, Cell);
			Continue;
		EndIf;
		
		NewRow = ProductsSelected_.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;

		If ValueIsFilled(String.ReplacementCell) Then
			NewRow.Cell = String.ReplacementCell;
		EndIf;
		
		For Each SearchString_ In ArrayToBeSelected Do
			SearchString_.NumberOfPackages = SearchString_.NumberOfPackages - NewRow.NumberOfPackages;
			SearchString_.Count = SearchString_.NumberOfPackages;
		EndDo;
		
	EndDo;
	
	ArrayOfRowsToDelete_1 = New Array;
	For Each String In GoodsTable Do
		If String.NumberOfPackages <= 0 Then
			ArrayOfRowsToDelete_1.Add(String);
		EndIf;
	EndDo;
	
	For Each DeleteLine In ArrayOfRowsToDelete_1 Do
		GoodsTable.Delete(DeleteLine);
	EndDo;
		
	For Each LineMarkingCode In Result.PackageBarcodes Do
			
		NewRow = PackageBarcodes.Add();
		FillPropertyValues(NewRow, LineMarkingCode);
			
	EndDo;
	
	ProductsPick.Load(GoodsTable);
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure AddProduct(Result = Undefined, AdditionalParameters = Undefined) Export
	
	ErrorText = "";
	AddItemATServer(Result);
	
	If Result = Undefined Then		
		Return;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then 
		Status(ErrorText); 
	EndIf;

	If ValueIsFilled(Result.DataOfFollowingItem) Then
		ResultOfScanningItem(Result.DataOfFollowingItem);
	EndIf;  
	
EndProcedure 

&AtServer
Procedure AddItemATServer(Val Result)
	
	TheStructureOfTheSearch = New Structure;
	
	If Result = Undefined Then
		
		TheStructureOfTheSearch.Insert("Cell", Catalogs.StorageBins.EmptyRef());		
		SearchResult = ProductsSelected_.FindRows(TheStructureOfTheSearch);
		For Each String In SearchResult Do
			ProductsSelected_.Delete(String);
		EndDo;
		
		Return;
	EndIf; 
		
	If Not ValueIsFilled(Result.Cell) And Not ValueIsFilled(Result.NextCellData) Then
		NewRow = ProductsSelected_.Add();
		FillPropertyValues(NewRow, Result);
		Return;
	EndIf;
	
	FilterArray = New Array; 
	
	If ValueIsFilled(Result.Cell) Then
		Cell = Result.Cell;		
	ElsIf ValueIsFilled(Result.NextCellData) Then
		Cell = Result.NextCellData.Cell;
	EndIf; 

	Structure = StructureOfSelectionItems();
	FillPropertyValues(Structure, Result);
	Structure.Cell = Cell;
	FilterArray.Add(Structure); 	
	
	If Not ValueIsFilled(Result.DataOfFollowingItem) Then
		TheStructureOfTheSearch.Insert("Cell", Catalogs.StorageBins.EmptyRef());
		SearchResult = ProductsSelected_.FindRows(TheStructureOfTheSearch); 
			
		For Each String In SearchResult Do
			Structure = StructureOfSelectionItems();
			String.Cell = Cell;
			FillPropertyValues(Structure, String); 
			FilterArray.Add(Structure);
		EndDo;
			
		For Each String In SearchResult Do
			ProductsSelected_.Delete(String);
		EndDo;
	EndIf;
		 
	Result.Insert("ArrayOfPlacements", FilterArray);
	Result.Insert("Cell", Cell); 
	CompleteSelectionFromCellAtServer(Result);
		
EndProcedure

&AtServer
Function StructureOfGoods()
	
	Structure = New Structure;
	Structure.Insert("Products","");
	Structure.Insert("Characteristic","");
	Structure.Insert("Series","");
	Structure.Insert("Package","");
	Structure.Insert("NumberOfPackages","");
	Structure.Insert("Purpose","");
	
	Return Structure;
	
EndFunction

&AtClient
Procedure CreateMenu_(TabName)
	
	ShowMenu();
	
	Items.SelectFrame.Picture = PictureLib.BorderMenuWhite;
	Items.PickCommand.TextColor = WebColors.DarkGray;
	
	Items.FrameSelected.Picture = PictureLib.BorderMenuWhite;
	Items.TeamSelected.TextColor = WebColors.DarkGray;
	
	If TabName = "Pick" Then
		Items.PickCommand.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PagePick;
		Items.SelectFrame.Picture = PictureLib.BorderMenuBlack;
	ElsIf TabName = "Picked" Then
		Items.TeamSelected.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PageSelected;
		Items.FrameSelected.Picture = PictureLib.BorderMenuBlack;
	EndIf;
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtServer
Procedure GenerateMenuCommandHeaders()
	
	Items.PickCommand.Title = StrTemplate(NStr("vi = 'Cần lấy ra (%1)';
												|ru = 'Отобрать (%1)';
												|en = 'Pick (%1)'; fa = 'Pick (%1)';
												|it = 'Ritirare (%1)';
												|pl = 'Wybierz (%1)';
												|tr = 'Filtrele (%1)'"), ProductsPick.Count());
	Items.TeamSelected.Title = StrTemplate(NStr("vi = 'Đã lấy ra (%1)';
												|ru = 'Отобрано (%1)';
												|en = 'Selected (%1)'; fa = 'Selected (%1)';
												|it = 'Ritirato (%1)';
												|pl = 'Wybrano (%1)';
												|tr = 'Toplanan (%1)'"), ProductsSelected_.Count());
	
EndProcedure

&AtServer
Procedure FillForm()
	
	Query = New Query;
	Query.Text = 
	
		"SELECT
		|	GoodsPickingPlacement.Number AS Number,
		|	GoodsPickingPlacement.Date AS Date,
		|	GoodsPickingPlacement.ShippingZone AS ShippingZone,
		|	GoodsPickingPlacement.Performer AS Performer,
		|	GoodsPickingPlacement.Comment AS Comment,
		|	GoodsPickingPlacement.Warehouse AS Warehouse,
		|	GoodsPickingPlacement.Premise AS Premise,
		|	GoodsPickingPlacement.Status AS Status,
		|	GoodsPickingPlacement.ReferenceOrder AS ReferenceOrder
		|FROM
		|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
		|WHERE
		|	GoodsPickingPlacement.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductsSelected_.Products AS Products,
		|	ProductsSelected_.Products.SKU AS SKU,
		|	ProductsSelected_.Characteristic AS Characteristic,
		|	ProductsSelected_.Package AS Package,
		|	ProductsSelected_.Series AS Series,
		|	ProductsSelected_.Purpose AS Purpose,
		|	ProductsSelected_.Cell AS Cell,
		|	ProductsSelected_.CountPicked AS Count,
		|	ProductsSelected_.NumberOfPackagesPicked AS NumberOfPackages
		|FROM
		|	Document.GoodsPickingPlacement.GoodsFilter AS ProductsSelected_
		|WHERE
		|	ProductsSelected_.Ref = &Ref
		|	AND ProductsSelected_.CountPicked > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductsPick.Products AS Products,
		|	ProductsPick.Products.SKU AS SKU,
		|	ProductsPick.Characteristic AS Characteristic,
		|	ProductsPick.Package AS Package,
		|	ProductsPick.Series AS Series,
		|	ProductsPick.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	ProductsPick.Purpose AS Purpose,
		|	ProductsPick.Cell AS Cell,
		|	ProductsPick.CountPicked AS CountPicked,
		|	ProductsPick.Count AS Count,
		|	ProductsPick.NumberOfPackages AS NumberOfPackages
		|FROM
		|	Document.GoodsPickingPlacement.GoodsFilter AS ProductsPick
		|WHERE
		|	ProductsPick.Ref = &Ref
		|   AND ProductsPick.CountPicked <= 0";
	
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.ExecuteBatch();
	SelectionDetailRecords = QueryResult[0].Select();
	SelectionDetailRecords.Next();
	
	FillPropertyValues(ThisObject, SelectionDetailRecords);

	ProductsSelected_.Load(QueryResult[1].Unload());
	ProductsPick.Load(QueryResult[2].Unload());
	
	UseWarerooms = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Warehouse, "UseWarerooms");
	
EndProcedure

&AtServer
Function FinishSelectionOnServer(Result, ProcessName)
	
	If Common.ObjectAttributeValue(Warehouse, "UseWarerooms")
		And Premise.IsEmpty() Then
		
		ErrorText = NStr("vi = 'Chưa chọn nhà kho';
						|ru = 'Не выбрано помещение';
						|en = 'Wareroom is not selected'; fa = 'Wareroom is not selected';
						|it = 'Locale non selezionato';
						|pl = 'Nie wybrano pomieszczenia';
						|tr = 'Alan seçilmedi'");	
		Items.GroupPages.CurrentPage = Items["InformationPage"];	
		Return False;
		
	EndIf;
	
	If ShippingZone.IsEmpty() Then
				
		ErrorText = NStr("vi = 'Chưa chọn khu vực nhập hàng';
						|ru = 'Не выбрана зона приемки';
						|en = 'Inbound area is not selected'; fa = 'Inbound area is not selected';
						|it = 'Zona di accettazione non selezionata';
						|pl = 'Nie wybrano strefy przyjęcia';
						|tr = 'Boşaltma alanı seçilmedi'");	
		Items.GroupPages.CurrentPage = Items["InformationPage"];
		
		Return False;
		
	EndIf;

	WriteErrorTemplate = NStr("vi = 'Không thể ghi lại %1. %2';
								|ru = 'Не удалось записать %1. %2';
								|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
								|it = 'Не удалось записать %1. %2';
								|pl = 'Nie udało się zapisać %1. %2';
								|tr = 'Kaydedilemedi%1. %2'");

	BeginTransaction();
	Try

		DocumentObject = Ref.GetObject();
		DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors;

		DocumentObject.Premise   = Premise;
		DocumentObject.Comment = Comment;
		DocumentObject.ShippingZone = ShippingZone;
		DocumentObject.Performer = Performer;
		
		DocumentObject.GoodsFilter.Clear();
			
		For Each String In ProductsSelected_ Do
			
			NewRow = DocumentObject.GoodsFilter.Add();
			FillPropertyValues(NewRow, String); 
			
			PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(String.Package, String.Products);
			
			NewRow.CountPicked = String.NumberOfPackages * PackagingFactor;
			NewRow.NumberOfPackagesPicked = String.NumberOfPackages;
			
			NewRow.Count = NewRow.CountPicked;
			NewRow.NumberOfPackages = NewRow.NumberOfPackagesPicked;
			
		EndDo;
		
		SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
		MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Filter);

#If MobileStandaloneServer Then
		DocumentObject.Write(DocumentWriteMode.Write);
#Else
		DocumentObject.Write(DocumentWriteMode.Posting);
#EndIf

		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorText = StrTemplate(WriteErrorTemplate, Ref,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Return False;
	EndTry;

	If ProcessName = "DoNotShip" Then
		
		// Capturing an object for editing
		Try
			LockDataForEdit(ReferenceOrder);
		Except
			ErrorText = StrTemplate(NStr("vi = 'Không thể phong tỏa %1. %2';
										|ru = 'Не удалось заблокировать %1. %2';
										|en = 'Cannot block %1. %2'; fa = 'Cannot block %1. %2';
										|it = 'Impossibile bloccare %1. %2';
										|pl = 'Nie udało się zablokować %1. %2';
										|tr = '%1 engellenemedi. %2'"), ReferenceOrder,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));  
			
			DocumentObject.Write(DocumentWriteMode.UndoPosting);
			
			Return False;
		EndTry;
		
		BeginTransaction();
		Try
				
			OrderObject_ = ReferenceOrder.GetObject();

			If Result = "ExitApp" Then
				OrderObject_.Status = Enums.GoodsIssueNoteStatuses.ForChecking;
			Else
				OrderObject_.Status = Enums.GoodsIssueNoteStatuses.DuringChecking;
				OrderObject_.Inspector = MobileWarehouseKeeperWorkspace.CurrentUser();
			EndIf;
			
			TheStructureOfTheSearch = StructureOfGoods();
			TheStructureOfTheSearch.Delete("NumberOfPackages");
			TheStructureOfTheSearch.Delete("Package");
			TheStructureOfTheSearch.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.Pick);
			
			For Each String In ProductsPick Do
				
				FillPropertyValues(TheStructureOfTheSearch, String);
				
				If String.BatchesIndicationStatus = 13 Or String.BatchesIndicationStatus = 14 
					Or String.BatchesIndicationStatus = 9 Or String.BatchesIndicationStatus = 10 Then
					TheStructureOfTheSearch.Insert("Series", String.Series);
				Else
					TheStructureOfTheSearch.Delete("Series");
				EndIf;
				
				SearchResult = OrderObject_.ShippedGoods.FindRows(TheStructureOfTheSearch);
				
				If SearchResult.Count() > 0 Then
					PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(
					SearchResult[0].Package, SearchResult[0].Products);
					
					SearchResult[0].Count         = SearchResult[0].Count - String.Count;
					SearchResult[0].NumberOfPackages = SearchResult[0].Count / PackagingFactor;
				EndIf; 
				
				QuantityToDistribution = String.Count; 
				
				TheStructureOfTheSearch.Delete("Action");
					
				FoundOrders_ = OrderObject_.GoodsByReferences.FindRows(TheStructureOfTheSearch);
				For Each OrderLine_2 In FoundOrders_ Do
					If QuantityToDistribution >= OrderLine_2.Count Then
						QuantityToDistribution = QuantityToDistribution - OrderLine_2.Count;
						OrderObject_.GoodsByReferences.Delete(OrderLine_2);
					Else
						OrderLine_2.Count = OrderLine_2.Count - QuantityToDistribution;
						QuantityToDistribution = 0;
					EndIf;
						
					If QuantityToDistribution = 0 Then
						Break;
					EndIf;
				EndDo;
			EndDo;
			
			ArrayOfRowsToDelete_1 = New Array;
			For Each String In OrderObject_.ShippedGoods Do	
				If String.Count <= 0 Then
					ArrayOfRowsToDelete_1.Add(String);
				EndIf;
			EndDo;	
			
			For Each DeleteLine In ArrayOfRowsToDelete_1 Do	
				OrderObject_.ShippedGoods.Delete(DeleteLine);	
			EndDo;

#If MobileStandaloneServer Then
			OrderObject_.Write(DocumentWriteMode.Write);
#Else
			OrderObject_.Write(DocumentWriteMode.Posting);
#EndIf

			CommitTransaction();
		Except 
			RollbackTransaction();
			
			ErrorText = StrTemplate(WriteErrorTemplate, ReferenceOrder,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
						
			DocumentObject.Write(DocumentWriteMode.UndoPosting);
			
			Return False;
		EndTry;
		
	ElsIf Not ProcessName = "ForPicking" Then
		If Result = "ExitApp" Then
			Return DataProcessors.MobileWarehouseKeeperWorkspace.SetStatusOfOrder(ReferenceOrder,
				Enums.GoodsIssueNoteStatuses.ForChecking); 
		ElsIf Result = "Validate" Then
			Return DataProcessors.MobileWarehouseKeeperWorkspace.SetStatusOfOrder(ReferenceOrder,
				Enums.GoodsIssueNoteStatuses.DuringChecking);
		EndIf;
	EndIf;

	Return True;
	
EndFunction

&AtServer
Procedure FillInAcceptanceArea()
	
	ShippingZone = MobileWarehouseKeeperWorkspace.DefaultAcceptanceZone(Warehouse, Premise);
	
EndProcedure

&AtClient
Procedure ShowMenu()

	Items.MenuGroup_2.Visible = True;
	Items.CommandGroup.Visible = True;
	
EndProcedure

&AtClient
Procedure HideMenu()

	Items.MenuGroup_2.Visible = False;
	Items.CommandGroup.Visible = False;
	
EndProcedure

&AtServer
Procedure CollectEverythingOnServer()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	GoodsToReceiveBalance.DocumentInflow AS DocumentInflow,
		|	GoodsToReceiveBalance.Products AS Products,
		|	GoodsToReceiveBalance.Characteristic AS Characteristic,
		|	GoodsToReceiveBalance.Purpose AS Purpose,
		|	GoodsToReceiveBalance.Warehouse AS Warehouse,
		|	GoodsToReceiveBalance.Sender AS Sender,
		|	GoodsToReceiveBalance.BusinessOperation AS BusinessOperation,
		|	GoodsToReceiveBalance.Series AS Series,
		|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS Count,
		|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS NumberOfPackages,
		|	GoodsToReceiveBalance.Products.UnitOfMeasure AS Package
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &DocumentInflow) AS GoodsToReceiveBalance
		|WHERE
		|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance > 0";
	
	Query.SetParameter("DocumentInflow", ShipmentReferenceOrder);
	
	Balance = Query.Execute().Unload();
	ProductsSelected_.Load(Balance);
	
EndProcedure

&AtServer
Procedure CancelFilterServer(RowIndex)
	
	CurrentRow = ProductsSelected_[RowIndex];
	
	PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(CurrentRow.Package, CurrentRow.Products);
	
	TheStructureOfTheSearch = StructureOfGoods(); 
	TheStructureOfTheSearch.Delete("NumberOfPackages");
	TheStructureOfTheSearch.Insert("Cell");
	
	FillPropertyValues(TheStructureOfTheSearch, CurrentRow);
	
	SearchResult = ProductsPick.FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() > 0 Then
		SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages + CurrentRow.NumberOfPackages;
		SearchResult[0].Count = SearchResult[0].NumberOfPackages * PackagingFactor;
	Else
		NewRow = ProductsPick.Add();
		FillPropertyValues(NewRow, CurrentRow);
		NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
	EndIf;
	
	ProductsSelected_.Delete(RowIndex);
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateFormOnServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateFormOnServer(Result)
	
	Literal = "LineNumber";
	LineNumber = Result[Literal];
	
	PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(Result.Package, Result.Products);
	
	TheStructureOfTheSearch = StructureOfGoods(); 
	TheStructureOfTheSearch.Delete("NumberOfPackages");
	TheStructureOfTheSearch.Insert("Cell");
	
	FillPropertyValues(TheStructureOfTheSearch, Result);
	
	If Result.Mode = "EditingSelectionFromShipmentCell" Then
		
		InitialQuantity_ = ProductsSelected_[Result.LineNumber].NumberOfPackages;
		
		ProductsSelected_[Result.LineNumber].Package           = Result.Package;
		ProductsSelected_[Result.LineNumber].NumberOfPackages = Result.NumberOfPackages;
		ProductsSelected_[Result.LineNumber].Count         = ProductsSelected_[Result.LineNumber].NumberOfPackages * PackagingFactor;
		ProductsSelected_[Result.LineNumber].Series              = Result.Series;
		ProductsSelected_[Result.LineNumber].Purpose         = Result.Purpose;
		
		SearchResult = ProductsPick.FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() > 0 Then
			SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages + InitialQuantity_ - Result.NumberOfPackages;
			SearchResult[0].Count = SearchResult[0].NumberOfPackages * PackagingFactor;
		ElsIf InitialQuantity_ - Result.NumberOfPackages > 0 Then
			NewRow = ProductsPick.Add();
			FillPropertyValues(NewRow, Result);
			NewRow.NumberOfPackages = InitialQuantity_ - Result.NumberOfPackages;
			NewRow.Count         = NewRow.NumberOfPackages * PackagingFactor;
		EndIf;
		
	Else
		
		ProductsPick[LineNumber].Package = Result.Package;
		ProductsPick[LineNumber].NumberOfPackages = ProductsPick[LineNumber].NumberOfPackages - Result.NumberOfPackages;
		ProductsPick[LineNumber].Count = ProductsPick[LineNumber].NumberOfPackages * PackagingFactor;
		
		SearchResult = ProductsSelected_.FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() > 0 Then
			SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages + Result.NumberOfPackages;
			SearchResult[0].Count = SearchResult[0].NumberOfPackages * PackagingFactor;
		ElsIf Result.NumberOfPackages > 0 Then
			NewRow = ProductsSelected_.Add();
			FillPropertyValues(NewRow, Result);
			NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
		EndIf;
		
	EndIf;
	
	ArrayOfRowsToDelete_1 = New Array;
	For Each String In ProductsPick Do
		If String.Count <= 0 Then
			ArrayOfRowsToDelete_1.Add(String);
		EndIf;
	EndDo;
			
	For Each DeleteLine In ArrayOfRowsToDelete_1 Do
		ProductsPick.Delete(DeleteLine);
	EndDo;
	
	ArrayOfRowsToDelete_1 = New Array;
	For Each String In ProductsSelected_ Do	
		If String.Count <= 0 Then
			ArrayOfRowsToDelete_1.Add(String);
		EndIf;
	EndDo;
			
	For Each DeleteLine In ArrayOfRowsToDelete_1 Do
		ProductsSelected_.Delete(DeleteLine);
	EndDo;
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure AfterClosingQuestion_Continued(Result, Var_Parameters = Undefined) Export
	
	If Result = "Continue" Then
		Return;
	EndIf;
	
	ValueList = New ValueList();
	
	If Result = "DoNotShip" Or Result = "ExitApp" Then	
		
		If ThereIsRightToCheckWarrant And Seamless Then
			ValueList.Add("Validate", NStr("vi = 'Chuyển đến kiểm tra phiếu';
											|ru = 'Перейти к проверке ордера';
											|en = 'Proceed to checking the note'; fa = 'Proceed to checking the note';
											|it = 'Proceed to checking the note';
											|pl = 'Proceed to checking the note';
											|tr = 'Sipariş kontrolüne git'"));
			ValueList.Add("ExitApp", NStr("vi = 'Kết thúc làm việc với phiếu';
											|ru = 'Завершить работу с ордером';
											|en = 'Close the note'; fa = 'Close the note';
											|it = 'Close the note';
											|pl = 'Close the note';
											|tr = 'Siparişle çalışmayı tamamla'"));
			ValueList.Add("Continue", NStr("vi = 'Tiếp tục lấy hàng';
											|ru = 'Продолжить отбор';
											|en = 'Continue picking'; fa = 'ادامه برداشت';
											|it = 'Continue picking';
											|pl = 'Continue picking';
											|tr = 'Filtrelemeye devam et'"));
			MessageText = NStr("vi = 'Sau khi kết thúc lấy hàng, cần chuyển đến kiểm tra phiếu hay kết thúc công việc với phiếu hiện tại?';
								|ru = 'После завершения отбора перейти к проверке ордера или завершить работу с текущим ордером?';
								|en = 'After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?'; fa = 'After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
								|it = 'After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
								|pl = 'After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
								|tr = 'Filtreyi tamamladıktan sonra sipariş doğrulamaya devam etmek veya mevcut siparişle çalışmayı bitirmek istiyor musunuz?'");
		Else
			ValueList.Add("ExitApp", NStr("vi = 'Kết thúc';
											|ru = 'Завершить';
											|en = 'Exit'; fa = 'خروج';
											|it = 'Completare';
											|pl = 'Zakończ';
											|tr = 'Tamamla'"));
			ValueList.Add("Continue", NStr("vi = 'Tiếp tục';
											|ru = 'Продолжить';
											|en = 'Continue'; fa = 'ادامه';
											|it = 'Continuare';
											|pl = 'Kontynuuj';
											|tr = 'Devam et'"));
			MessageText = NStr("vi = 'Kết thúc lấy ra?';
								|ru = 'Завершить отбор?';
								|en = 'Finish picking job?'; fa = 'Finish picking job?';
								|it = 'Terminare la selezione?';
								|pl = 'Zakończyć wybór?';
								|tr = 'Filtre tamamlansın mı?'");
		EndIf; 
		
		AddlParameters = New Structure("ProcessName", Result);
		Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject, AddlParameters);
		ShowQueryBox(Notification, MessageText, ValueList, 0);
		
	Else 
		AddlParameters = New Structure("ProcessName", Result);
		AfterClosingQuestion_("ExitApp", AddlParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestion_(Result, AdditionalParameters = Undefined) Export
	
	If Result = "Continue" Then
		Return;
	EndIf;
			
	FilterCompleted = FinishSelectionOnServer(Result, AdditionalParameters.ProcessName);

	If Result = "ExitApp" And FilterCompleted Then
		Close();
	ElsIf Result = "Validate" And FilterCompleted Then  
		OpenSpendingOrderForm(); 
	Else
		Status(ErrorText);
	EndIf;
	
EndProcedure 

&AtClient
Procedure AfterClosingQuestionForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result = "Continue" Then
		Return;
	EndIf;
	
	If Result = "ForPicking" Then
		FilterCompleted = FinishSelectionOnServer("ExitApp", "ForPicking");
	Else
		FilterCompleted = FinishSelectionOnServer("ExitApp", "DoNotShip");
	EndIf;
	
	If FilterCompleted Then
		OpenSpendingOrderForm();
	Else
		Status(ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSpendingOrderForm()
	
	Close(); 
				
	FormParameters = New Structure;
	FormParameters.Insert("Ref", ReferenceOrder);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Barcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
			
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder", FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.Independent);
		
EndProcedure 

&AtServer
Function CellDataByWK(Val Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.CellDataByWK(Warehouse, Premise, Barcode);
	
EndFunction

&AtServerNoContext
Function ItemDataBySchool(Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.ItemDataBySchool(Barcode); 
	
EndFunction

&AtClient
Procedure ChangePackageBarcodes(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ChangeBarcodesOfPackagesOnServer(Result);
	
EndProcedure

&AtServer
Procedure ChangeBarcodesOfPackagesOnServer(Result)
	
	PackageBarcodes.Clear();
	PackageBarcodes.Load(Result.Unload());
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionCancelSelectionTask(Result, Var_Parameters) Export
	
	If Result = "ExitApp" Then
		
		FilterRolledBack_ = CancelSelectionTaskAtServer();
		
		If FilterRolledBack_ Then
			If Items.GroupPages.CurrentPage = Items["InformationPage"] Then
				Close();
			EndIf;
			Close();
		EndIf;
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtServer
Function CancelSelectionTaskAtServer()
	
#If MobileStandaloneServer Then
	Return False;
#Else
	Try
		DocumentObject = Ref.GetObject();
		DocumentObject.SetDeletionMark(True);
		
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	Except
		Common.MessageToUser(NStr("vi = 'Không thể hủy nhiệm vụ lấy hàng.';
									|ru = 'Не удалось отменить задание на отбор.';
									|en = 'Cannot cancel the picking job.'; fa = 'Cannot cancel the picking job.';
									|it = 'Cannot cancel the picking job.';
									|pl = 'Cannot cancel the picking job.';
									|tr = 'Filtreleme görevi iptal edilemedi.'"));
		
		Return False;
	EndTry;
	
	Return True;
#EndIf

EndFunction

&AtServer
Function StructureOfSelectionItems()
	
	Structure = New Structure;
	Structure.Insert("Products","");
	Structure.Insert("Characteristic","");
	Structure.Insert("Series","");
	Structure.Insert("Purpose","");
	Structure.Insert("Package","");
	Structure.Insert("PackagePlaced","");
	Structure.Insert("NumberOfPackages","");
	Structure.Insert("NumberOfPackagesPlaced","");
	Structure.Insert("Cell","");
	Structure.Insert("ReplacementCell","");
	Structure.Insert("LineNumber","");
	
	Return Structure;
	
EndFunction 

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
