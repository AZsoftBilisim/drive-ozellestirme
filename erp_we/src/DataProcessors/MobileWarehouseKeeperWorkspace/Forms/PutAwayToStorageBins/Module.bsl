
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Ref = Parameters.Ref;

	ShowProductPhotos = Parameters.ShowProductPhotos;
	Barcode = Parameters.Barcode;
	ScanningProcedure = Parameters.ScanningProcedure;
	
#If MobileStandaloneServer Then
	Items.FormCancelPlacementTask.Visible = False;
#Else
	Status = Common.ObjectAttributeValue(Ref, "Status");
	If Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2 And AccessRight("InteractiveSetDeletionMark", Metadata.Documents.GoodsPickingPlacement) Then
		Items.FormCancelPlacementTask.Visible = True;
	Else
		Items.FormCancelPlacementTask.Visible = False;
	EndIf;
#EndIf
	
	FillForm();

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	CreateMenu_("Place")
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

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToPostSection(Command)
	CreateMenu_("Place");
EndProcedure

&AtClient
Procedure GoToPostedSection(Command)
	CreateMenu_("Placed");
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("Mode", "PlacementInCell");
	FormParameters.Insert("LineNumber", ProductsToPlace.IndexOf(Items.ProductsToPlace.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Cell", Item.CurrentData.Cell);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("DocumentSource", Ref);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure ProductItemsPlacedSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("Mode", "EditingPlacementByCells");
	FormParameters.Insert("LineNumber", ProductItemsPlaced.IndexOf(Items.ProductItemsPlaced.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Cell", Item.CurrentData.Cell);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure FinishPlacement(Command)
	
	If ProductsToPlace.Count() = 0 And ProductItemsPlaced.Count() = 0 Then
		Status(NStr("vi = 'Không có hàng hóa để xếp vào';
					|ru = 'Нет товаров для размещения';
					|en = 'No goods to put away'; fa = 'No goods to put away';
					|it = 'Non ci sono articoli da inserire';
					|pl = 'Brak towarów do umieszczenia';
					|tr = 'Yerleşim için ürünler mevcut değil'"));
		Return;
	EndIf;
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Kết thúc';
									|ru = 'Завершить';
									|en = 'Finish'; fa = 'پایان';
									|it = 'Completare';
									|pl = 'Zakończ';
									|tr = 'Tamamla'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Kontynuuj';
									|tr = 'Devam et'"));
	
	Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Tiếp tục xếp vào?';
									|ru = 'Завершить размещение?';
									|en = 'Finish put-away?'; fa = 'Finish put-away?';
									|it = 'Terminare il collocamento?';
									|pl = 'Zakończyć umieszczenie?';
									|tr = 'Yerleşimi tamamla?'"), ValueList, 0);
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	FillInAcceptanceArea();
EndProcedure

&AtClient
Procedure CollectEverything(Command)
	CollectEverythingOnServer();
	CreateMenu_("Placed");
EndProcedure

&AtClient
Procedure Scan(Command)

	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("DocumentRef", Ref);
	
	If ScanningProcedure = "FirstScanCell" Then
		
		LongDesc = New CallbackDescription("CellScanResult", ThisObject);
		FormParameters.Insert("FindType", "CellSearch");
		
	Else
		
		LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
		FormParameters.Insert("FindType", "ProductItemsSearch");
		
	EndIf;
	
	If UsedFormServer = UsedServer.Main Then
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	Else
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanningOfflineMode",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	EndIf
		
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateMenu_(TabName)
	
	ShowMenu();
	
	Items.FrameToPlace.Picture = PictureLib.BorderMenuWhite;
	Items.PlaceCommand.TextColor = WebColors.DarkGray;
	
	Items.FramePlaced.Picture = PictureLib.BorderMenuWhite;
	Items.TeamPosted.TextColor = WebColors.DarkGray;
	
	If TabName = "Place" Then
		Items.FrameToPlace.Picture = PictureLib.BorderMenuBlack;
		Items.PlaceCommand.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PlacePage;
	ElsIf TabName = "Placed" Then
		Items.FramePlaced.Picture = PictureLib.BorderMenuBlack; 
		Items.TeamPosted.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PagePosted;
	EndIf;
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtServer
Procedure GenerateMenuCommandHeaders()
	Items.PlaceCommand.Title = StrTemplate(NStr("vi = 'Cần xếp vào (%1)';
												|ru = 'Разместить (%1)';
												|en = 'To put away (%1)'; fa = 'To put away (%1)';
												|it = 'Inserire (%1)';
												|pl = 'Umieść (%1)';
												|tr = 'Yerleştir (%1)'"), ProductsToPlace.Count());
	Items.TeamPosted.Title = StrTemplate(NStr("vi = 'Đã xếp vào (%1)';
												|ru = 'Размещено (%1)';
												|en = 'Put away (%1)'; fa = 'Put away (%1)';
												|it = 'Inserito (%1)';
												|pl = 'Umieszczono (%1)';
												|tr = 'Yerleştirildi (%1)'"), ProductItemsPlaced.Count());
EndProcedure

&AtServer
Procedure FillForm()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	GoodsPickingPlacement.Warehouse AS Warehouse,
		|	GoodsPickingPlacement.Comment AS Comment,
		|	GoodsPickingPlacement.Performer AS Performer,
		|	GoodsPickingPlacement.Premise AS Premise,
		|	GoodsPickingPlacement.ReceivingArea AS ReceivingArea,
		|	GoodsPickingPlacement.Number AS Number,
		|	GoodsPickingPlacement.Date AS Date,
		|	GoodsPickingPlacement.GoodsPlacement.(
		|		Products AS Products,
		|		Products.SKU AS SKU,
		|		Products.UnitOfMeasure AS ProductsUnitOfMeasure,
		|		Characteristic AS Characteristic,
		|		Series AS Series,
		|		Package AS Package,
		|		Count AS Count,
		|		NumberOfPackages AS NumberOfPackages,
		|		CountPlaced AS CountPlaced,
		|		NumberOfPackagesPlaced AS NumberOfPackagesPlaced,
		|		Purpose AS Purpose,
		|		Cell AS Cell
		|	) AS GoodsPlacement
		|FROM
		|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
		|WHERE
		|	GoodsPickingPlacement.Ref = &Ref";
	
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	SelectionDetailRecords.Next();
	FillPropertyValues(ThisObject, SelectionDetailRecords);
	
	For Each String In SelectionDetailRecords.GoodsPlacement.Unload() Do
		
		Place         = String.Count - String.CountPlaced;
		PlacePackages = String.NumberOfPackages - String.NumberOfPackagesPlaced;
		
		If String.CountPlaced > 0 Then
			NewRow = ProductItemsPlaced.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Count = String.CountPlaced;
			NewRow.NumberOfPackages = String.NumberOfPackagesPlaced;
		ElsIf Place > 0 Then
			NewRow = ProductsToPlace.Add();
			FillPropertyValues(NewRow, String);
			If Not ValueIsFilled(NewRow.Package) Then
				NewRow.Package = String.ProductsUnitOfMeasure;
			EndIf;
			NewRow.Count = Place;
			NewRow.NumberOfPackages = PlacePackages;
		EndIf;
		
	EndDo;
	
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
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", Result.Products);
	TheStructureOfTheSearch.Insert("Characteristic", Result.Characteristic);
	TheStructureOfTheSearch.Insert("Series", Result.Series);
	TheStructureOfTheSearch.Insert("Package", Result.Package);
	TheStructureOfTheSearch.Insert("Purpose", Result.Purpose); 
	TheStructureOfTheSearch.Insert("Cell", Result.Cell);
	
	If Result.Mode = "EditingPlacementByCells" Then
		
		InitialQuantity_ = ProductItemsPlaced[Result.LineNumber].NumberOfPackages;
		
		ProductItemsPlaced[Result.LineNumber].Package           = Result.Package;
		ProductItemsPlaced[Result.LineNumber].NumberOfPackages = Result.NumberOfPackages;
		ProductItemsPlaced[Result.LineNumber].Count         = ProductItemsPlaced[Result.LineNumber].NumberOfPackages * PackagingFactor;
		ProductItemsPlaced[Result.LineNumber].Series              = Result.Series;
		ProductItemsPlaced[Result.LineNumber].Purpose         = Result.Purpose;
		
		SearchResult = ProductsToPlace.FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() > 0 Then
			SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages +  InitialQuantity_ - Result.NumberOfPackages;
			SearchResult[0].Count = SearchResult[0].NumberOfPackages * PackagingFactor;
		ElsIf InitialQuantity_ - Result.NumberOfPackages > 0 Then
			NewRow = ProductsToPlace.Add();
			FillPropertyValues(NewRow, Result);
			NewRow.NumberOfPackages = InitialQuantity_ - Result.NumberOfPackages;
			NewRow.Count         = NewRow.NumberOfPackages * PackagingFactor;
		EndIf;
		
	Else
		
		ProductsToPlace[LineNumber].Count = ProductsToPlace[LineNumber].Count - Result.NumberOfPackages * PackagingFactor;
		PackingFactorToPlace = MobileWarehouseKeeperWorkspace.PackagingFactor(ProductsToPlace[LineNumber].Package, ProductsToPlace[LineNumber].Products);
		ProductsToPlace[LineNumber].NumberOfPackages = ProductsToPlace[LineNumber].Count / PackingFactorToPlace;
		
		If ProductsToPlace[LineNumber].NumberOfPackages <= 0 Then
			ProductsToPlace.Delete(LineNumber);
		EndIf; 
		
		SearchResult = ProductItemsPlaced.FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() > 0 Then
			SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages + Result.NumberOfPackages;
			SearchResult[0].Count = SearchResult[0].NumberOfPackages * PackagingFactor;
		ElsIf Result.NumberOfPackages > 0 Then
			NewRow = ProductItemsPlaced.Add();
			FillPropertyValues(NewRow, Result);
			NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
		EndIf;
		
	EndIf;
	
	Cnt = 0;
	While Cnt < ProductsToPlace.Count() Do
		If ProductsToPlace[Cnt].Count <= 0 Then
			ProductsToPlace.Delete(Cnt);
		Else
			Cnt = Cnt + 1;
		EndIf;
	EndDo;
	
	Cnt = 0;
	While Cnt < ProductItemsPlaced.Count() Do
		If ProductItemsPlaced[Cnt].Count <= 0 Then
			ProductItemsPlaced.Delete(Cnt);
		Else
			Cnt = Cnt + 1;
		EndIf;
	EndDo;
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
		
	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1); 
	
	If Not BarcodesAreValid Then
		Return;
	EndIf;
		
	If Barcode = BarcodeData_1.Barcode Then  
		
		If  ProductsToPlace.Count() = 0 And ProductItemsPlaced.Count() = 0 Then
			ErrorText = NStr("vi = 'Không có hàng hóa để xếp vào';
							|ru = 'Нет товаров для размещения';
							|en = 'No goods to put away'; fa = 'No goods to put away';
							|it = 'Non ci sono articoli da inserire';
							|pl = 'Brak towarów do umieszczenia';
							|tr = 'Yerleşim için ürünler mevcut değil'");
			Status(ErrorText);
			Return;
		EndIf;
				
		PlacementWasCompleted = FinishPostingOnServer();
		
		If PlacementWasCompleted Then
			Close();
		Else
			Status(ErrorText);
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
					|tr = 'Barkod ile öğe bulunamadı'"));
	EndIf;
			
EndProcedure

&AtClient
Procedure CellScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("CompletePlacementInCell", ThisObject);
	
	ProductsInCell = New Array;
	
	For Each String In ProductsToPlace Do
		
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
	FormParameters.Insert("OperationType", 1);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("CellBarcode", Result.Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	FormParameters.Insert("Ref", Ref);
	
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
		FormParameters.Insert("Mode", "PlacementInCell");
		FormParameters.Insert("LineNumber", 0);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);
		FormParameters.Insert("PackageBarcode", ProductData_8.PackageBarcode);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Source", Ref);
		FormParameters.Insert("DocumentBarcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompletePlacementInCell(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CompletePlacementInCellOnServer(Result);
	If ValueIsFilled(Result.NextCellData) Then
		CellScanResult(Result.NextCellData);
	EndIf;
	
EndProcedure

&AtServer
Procedure CompletePlacementInCellOnServer(Result)
	
	OperationText = NStr("vi = 'Không cần đặt mặt hàng %1 trong bao bì %2 vào ô %3.';
						|ru = 'Не требуется размещение номенклатуры %1 в упаковке %2 в ячейку %3.';
						|en = 'Putting away the %1 item in the %2 packaging unit to the %3 storage bin is not required.'; fa = 'Putting away the %1 item in the %2 packaging unit to the %3 storage bin is not required.';
						|it = 'Putting away the %1 item in the %2 packaging unit to the %3 storage bin is not required.';
						|pl = 'Putting away the %1 item in the %2 packaging unit to the %3 storage bin is not required.';
						|tr = '%2 paketleme ünitesindeki %1 ürünü %3 depo yerine yerleştirme gerekli değil.'");
	
	GoodsTable = ProductsToPlace.Unload();
	
	ArrayOfPlacements = Result.ArrayOfPlacements;
	Cell = Result.Cell;
	
	// Array of structures
	For Each String In ArrayOfPlacements Do
		
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
		
		PlaceArray = GoodsTable.FindRows(SearchSelection);
		If Not PlaceArray.Count() And ScanningProcedure = "FirstScanProduct" Then
			ErrorText = ErrorText + ?(ValueIsFilled(ErrorText), Chars.LF, "") + StrTemplate(OperationText, 
				String.Products, String.Package, Cell);
			Continue;
		EndIf;
		
		NewRow = ProductItemsPlaced.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
		
		If ValueIsFilled(String.ReplacementCell) Then
			NewRow.Cell = String.ReplacementCell;
		EndIf;
			
		For Each SearchString_ In PlaceArray Do
			SearchString_.NumberOfPackages = SearchString_.NumberOfPackages - NewRow.NumberOfPackages;
			SearchString_.Count = SearchString_.NumberOfPackages;
		EndDo;
		
	EndDo;
	
	Cnt = 0;
	While Cnt < GoodsTable.Count() Do
		
		If GoodsTable[Cnt].NumberOfPackages <= 0 Then
			GoodsTable.Delete(GoodsTable[Cnt]);
		Else
			Cnt = Cnt + 1;
		EndIf;
		
	EndDo;
	
	ProductsToPlace.Load(GoodsTable);
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
		SearchResult = ProductItemsPlaced.FindRows(TheStructureOfTheSearch);
		For Each String In SearchResult Do
			ProductItemsPlaced.Delete(String);
		EndDo;
		
		Return;
	EndIf; 
		
	If Not ValueIsFilled(Result.Cell) And Not ValueIsFilled(Result.NextCellData) Then
		NewRow = ProductItemsPlaced.Add();
		FillPropertyValues(NewRow, Result); 
		Return;
	EndIf;
	
	ArrayOfPlacements = New Array; 
	
	If ValueIsFilled(Result.Cell) Then
		Cell = Result.Cell;
	ElsIf ValueIsFilled(Result.NextCellData) Then
		Cell = Result.NextCellData.Cell;
	EndIf; 

	Structure = StructureOfItemsOfPlacement();
	FillPropertyValues(Structure, Result);
	Structure.Cell = Cell;
	ArrayOfPlacements.Add(Structure);
	
	If Not ValueIsFilled(Result.DataOfFollowingItem) Then
		TheStructureOfTheSearch.Insert("Cell", Catalogs.StorageBins.EmptyRef());
		SearchResult = ProductItemsPlaced.FindRows(TheStructureOfTheSearch);
			
		For Each String In SearchResult Do
			Structure = StructureOfItemsOfPlacement();
			String.Cell = Cell;
			FillPropertyValues(Structure, String); 
			ArrayOfPlacements.Add(Structure);
		EndDo;
			
		For Each String In SearchResult Do
			ProductItemsPlaced.Delete(String);
		EndDo;
	EndIf;
		 
	Result.Insert("ArrayOfPlacements", ArrayOfPlacements);
	Result.Insert("Cell", Cell); 
	CompletePlacementInCellOnServer(Result);
		
EndProcedure

&AtServer
Function FinishPostingOnServer()
	
	DocumentObject = Ref.GetObject();
	
	DocumentObject.Premise   = Premise;
	DocumentObject.Comment = Comment;
	DocumentObject.ReceivingArea = ReceivingArea;
	DocumentObject.Performer = Performer;
	
	DocumentObject.GoodsPlacement.Clear();
	
	If MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Warehouse, "UseWarerooms")
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
	
	If ReceivingArea.IsEmpty() Then
				
		ErrorText = NStr("vi = 'Chưa chọn khu vực nhập hàng';
						|ru = 'Не выбрана зона приемки';
						|en = 'Inbound area is not selected'; fa = 'Inbound area is not selected';
						|it = 'Zona di accettazione non selezionata';
						|pl = 'Nie wybrano strefy przyjęcia';
						|tr = 'Boşaltma alanı seçilmedi'");
		Items.GroupPages.CurrentPage = Items["InformationPage"];
		Return False;
		
	EndIf;
	
	For Each String In ProductItemsPlaced Do
		
		NewRow = DocumentObject.GoodsPlacement.Add();
		FillPropertyValues(NewRow, String);
		NewRow.CountPlaced = String.Count;
		NewRow.NumberOfPackagesPlaced = String.NumberOfPackages;
		NewRow.Count = String.Count;
		NewRow.NumberOfPackages = String.NumberOfPackages;
		
	EndDo;
	
	For Each String In ProductsToPlace Do
		
		NewRow = DocumentObject.GoodsPlacement.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Count = String.Count;
		NewRow.NumberOfPackages = String.NumberOfPackages;
		
	EndDo;
	
	SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
	MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Location);
	
	If ProductsToPlace.Count() = 0 Then
		DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors;
	ElsIf ProductItemsPlaced.Count() = 0 Then
		DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2;
	Else
		DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
	EndIf;
		
	Try
#If Not MobileStandaloneServer Then
		DocumentObject.Write(DocumentWriteMode.Posting);
#Else
		DocumentObject.Write(DocumentWriteMode.Write);
#EndIf
	Except
		DocumentObject.Write(DocumentWriteMode.Write);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

&AtClient
Procedure Information(Command)
	
	Items.GroupPages.CurrentPage = Items["InformationPage"];
	HideMenu();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.GroupPages.CurrentPage = Items["InformationPage"] Then
		StandardProcessing = False;
		Cancel = True;
		CreateMenu_("Placed");
	EndIf;
	
EndProcedure 

&AtServer
Procedure FillInAcceptanceArea()
	
	ReceivingArea = MobileWarehouseKeeperWorkspace.DefaultAcceptanceZone(Warehouse, Premise);
	
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
	
	Query.SetParameter("DocumentInflow", ReceiptReferenceOrder);
	
	Balance = Query.Execute().Unload();
	ProductItemsPlaced.Load(Balance);
	
EndProcedure

&AtClient
Procedure CancelPlacement(Command)
	
	RowIndex = ProductItemsPlaced.IndexOf(Items.ProductItemsPlaced.CurrentData);
	
	If RowIndex < 0 Then
		Return;
	EndIf;
	
	PackagingFactor = GetPackingRatioServer(ProductItemsPlaced[RowIndex].Products, ProductItemsPlaced[RowIndex].Package);
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products",   ProductItemsPlaced[RowIndex].Products);
	TheStructureOfTheSearch.Insert("Characteristic", ProductItemsPlaced[RowIndex].Characteristic);
	TheStructureOfTheSearch.Insert("Series",          ProductItemsPlaced[RowIndex].Series);
	TheStructureOfTheSearch.Insert("Package",       ProductItemsPlaced[RowIndex].Package);
	TheStructureOfTheSearch.Insert("Cell",         ProductItemsPlaced[RowIndex].Cell);
	TheStructureOfTheSearch.Insert("Purpose",     ProductItemsPlaced[RowIndex].Purpose);
	
	SearchResult = ProductsToPlace.FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() > 0 Then
		SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages + ProductItemsPlaced[RowIndex].NumberOfPackages;
		SearchResult[0].Count = SearchResult[0].NumberOfPackages * PackagingFactor;
	Else
		NewRow = ProductsToPlace.Add();
		FillPropertyValues(NewRow, ProductItemsPlaced[RowIndex]);
		NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
	EndIf;
	
	ProductItemsPlaced.Delete(RowIndex);
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtServer
Function GetPackingRatioServer(Products, Package)
	
	Return MobileWarehouseKeeperWorkspace.PackagingFactor(Package, Products);
	
EndFunction

&AtClient
Procedure AfterClosingQuestion_(Result, Var_Parameters) Export
	
	If Result = "ExitApp" Then
		
		PlacementWasCompleted = FinishPostingOnServer();
		
		If PlacementWasCompleted Then
			Close();
		Else
			Status(ErrorText);
		EndIf;
		
	Else
		Return;
	EndIf;
	
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
Procedure CancelPlacementTask(Command)
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Đặt dấu xóa chứng từ';
									|ru = 'Пометить документ на удаление';
									|en = 'Mark the document for deletion'; fa = 'Mark the document for deletion';
									|it = 'Mark the document for deletion';
									|pl = 'Mark the document for deletion';
									|tr = 'Silinmek üzere belge işaretle'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục xếp vào hàng hóa';
									|ru = 'Продолжить размещение';
									|en = 'Resume put-away'; fa = 'Resume put-away';
									|it = 'Resume put-away';
									|pl = 'Resume put-away';
									|tr = 'Yerleştirmeye devam et'"));
	
	Notification = New CallbackDescription("AfterClosingQuestionCancelPlacementTask", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Để hủy xếp vào hàng hóa, cần đặt dấu xóa chứng từ xếp vào. Sau đó sẽ không thể quay lại chỉnh sửa. Bạn có muốn đặt dấu xóa không?';
									|ru = 'Для отмены размещения необходимо пометить на удаление документ размещения. Вернуться к редактированию будет невозможно. Пометить на удаление?';
									|en = 'To cancel put-away, mark the put-away document for deletion. It will be impossible to get back to editing. Mark the document for deletion?'; fa = 'To cancel put-away, mark the put-away document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|it = 'To cancel put-away, mark the put-away document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|pl = 'To cancel put-away, mark the put-away document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|tr = 'Yerleştirmeyi geri almak için, yerleştirme belgesini silinmek üzere işaretlemeniz gerekir. Düzenleme yapılamaz. Silinmek üzere işaretlensin mi?'"), ValueList, 0);
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionCancelPlacementTask(Result, Var_Parameters) Export
	
	If Result = "ExitApp" Then
		
		LocationCanceled = CancelPlacementTaskATServer();
		
		If LocationCanceled Then
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
Function CancelPlacementTaskATServer()
	
#If MobileStandaloneServer Then
	Return False;
#Else
	Try
		DocumentObject = Ref.GetObject();
		DocumentObject.SetDeletionMark(True);
		
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	Except
		Common.MessageToUser(NStr("vi = 'Không thể hủy nhiệm vụ xếp vào.';
									|ru = 'Не удалось отменить задание на размещение.';
									|en = 'Cannot cancel the put-away task.'; fa = 'Cannot cancel the put-away task.';
									|it = 'Cannot cancel the put-away task.';
									|pl = 'Cannot cancel the put-away task.';
									|tr = 'Yerleştirme görevi iptal edilemedi.'"));
		
		Return False;
	EndTry;
	
	Return True;
#EndIf
		
EndFunction

&AtServer
Function StructureOfItemsOfPlacement()
	
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

&AtClient
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
