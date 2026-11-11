
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Warehouse                 = Parameters.Warehouse;
	Premise             = Parameters.Premise;
	StorageBinType    = Enums.TypesOfStorageCells.Receiving;
	Performer           = Parameters.Performer;
	ReceivingArea           = Parameters.ReceivingArea;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	ScanningProcedure   = Parameters.ScanningProcedure;
	
	UnitOfMeasureForWeight   = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	SetConditionalAppearance();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(ReceivingArea) Then
		ReceivingArea = FillInDefaultAcceptanceZone(Warehouse, Premise);
	EndIf;
	
	UpdateFormData();
	
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.ChoiceForm") Then
		
		Warehouse = ValueSelected;
		Premise = Undefined;
		ReceivingArea = FillInDefaultAcceptanceZone(Warehouse, Premise);
		CreateRepresentationOfWarehouseSelection();
		ToFormRepresentationOfSelectionRoom();
		UpdateFormData();
		
	EndIf;
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warerooms.Form.ChoiceForm") Then
		
		Premise = ValueSelected;
		ToFormRepresentationOfSelectionRoom();
		ReceivingArea = FillInDefaultAcceptanceZone(Warehouse, Premise);
		UpdateFormData();
		
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

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectionsOpenWarehouse(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	FormOpenParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
		
	OpenForm(
		"Catalog.Warehouses.Form.ChoiceForm",
		FormOpenParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionsOpenRoom(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	
	Filter = New Structure();
	Filter.Insert("Owner", Warehouse);
	
	FormOpenParameters.Insert("Filter", Filter);
	
	OpenForm(
		"Catalog.Warerooms.Form.ChoiceForm",
		FormOpenParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SelectionsClearWarehouse(Command)
	
	Warehouse       = Undefined;
	Premise   = Undefined;
	ReceivingArea = Undefined;
	
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsCleanRoom(Command)

	Premise   = Undefined;
	ReceivingArea = Undefined;
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData(); 
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If ThisIsSelectionOfGoods Then
		Item.CurrentData.ProductSelected = Not Item.CurrentData.ProductSelected;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products",   Item.CurrentData.Products);
		TheStructureOfTheSearch.Insert("Characteristic", Item.CurrentData.Characteristic);
		TheStructureOfTheSearch.Insert("Series",          Item.CurrentData.Series);
		TheStructureOfTheSearch.Insert("Package",       Item.CurrentData.Package);
		
		SearchResult = ShoppingCart.FindRows(TheStructureOfTheSearch);
		
		If SearchResult.Count() > 0 Then 
			Return;
		Else
			NewRow = ShoppingCart.Add();
			FillPropertyValues(NewRow, Item.CurrentData);
			SetConditionalAppearance();
		EndIf;
		
		ChangeNameOfPlaceCommand();
		
		Return;
	EndIf;
		
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("Mode", "View");
	FormParameters.Insert("LineNumber", Goods.IndexOf(Items.Goods.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisObject,,,,,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	If Not ValueIsFilled(Warehouse) Then
		Status(NStr("vi = 'Hãy chỉ ra kho bãi trong bộ lọc';
					|ru = 'Укажите склад в отборе';
					|en = 'Specify a warehouse in the filter'; fa = 'Specify a warehouse in the filter';
					|it = 'Укажите склад в отборе';
					|pl = 'Specify a warehouse in the filter';
					|tr = 'Filtredeki ambarı belirtin'"));
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("ScanningResult", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "ProductItemsSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("DocumentRef", Ref);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
	ThisObject,,,, LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure ShoppingCartSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("Mode", "ShoppingCartSelection");
	FormParameters.Insert("LineNumber", ShoppingCart.IndexOf(Items.ShoppingCart.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisObject,,,, LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Place(Command)
	
	ClearMessages();
	
	If ShoppingCart.Count() = 0 And Goods.Count() = 0 Then
		Message = NStr("vi = 'Không có hàng hóa để xếp vào';
						|ru = 'Нет товаров для размещения';
						|en = 'No goods to put away'; fa = 'No goods to put away';
						|it = 'Non ci sono articoli da inserire';
						|pl = 'Brak towarów do umieszczenia';
						|tr = 'Yerleşim için ürünler mevcut değil'");
		Status(Message);
		Return;
	EndIf;
	
	If ShoppingCart.Count() > 0 Or Items.GroupPages.CurrentPage = Items["PlacementConditionsPage"] Then
				
		StructureOfNewPlacement = NewPlacementATServer();
		
		If ValueIsFilled(StructureOfNewPlacement.CheckErrorText) Then
			Status(StructureOfNewPlacement.CheckErrorText);
		EndIf;
		
		If Not ValueIsFilled(StructureOfNewPlacement.Ref) Then
			Return;
		EndIf;

		LongDesc = New CallbackDescription("UpdateForm", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", StructureOfNewPlacement.Ref);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PutAwayToStorageBins",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	Else
		LimitByWeight                      = False;
		LimitByVolume                    = False;
		Items.SelectProducts.Visible         = False;
		Items.Scan.Visible          = False;
		Items.GroupPages.CurrentPage = Items["PlacementConditionsPage"];
		Items.Place.Title = NStr("vi = 'Cần xếp vào';
								|ru = 'Разместить';
								|en = 'Put away'; fa = 'جای‌گذاری';
								|it = 'Posiziona';
								|pl = 'Put away';
								|tr = 'Yerleştir'");
		Items.GroupMainSelections.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitationByWeightOnChange(Item)
	
	If LimitationByWeight <> 0 Then
		LimitByWeight = True;
	Else
		LimitByWeight = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitationByVolumeOnChange(Item)
	
	If LimitationByVolume <> 0 Then
		LimitByVolume = True;
	Else
		LimitByVolume = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	UpdateFormData();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	If ShoppingCart.Count() > 0 Then
		Items.HeaderShoppingCart.Visible = True;
	Else
		Items.HeaderShoppingCart.Visible = False;
	EndIf;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.ErrorInPackaging");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.ItemError");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.ErrorInTheStorageArea");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
EndProcedure

&AtServer
Procedure UpdateFormData()
	
	FillInListOfProducts();
	
EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		ChangeNameOfPlaceCommand();
		Return;
	EndIf;
	
	UpdateFormOnServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateFormOnServer(Result)
	
	Items.Place.Title = NStr("vi = 'Xếp vào tất cả';
							|ru = 'Разместить все';
							|en = 'Put away all'; fa = 'جای‌گذاری همه';
							|it = 'Inserire tutti';
							|pl = 'Umieść wszystkie';
							|tr = 'Hepsini yerleştir'");
	Items.HeaderShoppingCart.Visible = False;
	
	If Result.Mode = "ShoppingCartSelection" Then 
		
		Literal = "LineNumber";
		LineNumber = Result[Literal];
	
		ShoppingCart[LineNumber].Package = Result.Package;
		ShoppingCart[LineNumber].NumberOfPackages = Result.NumberOfPackages;
	
	ElsIf Result.Mode = "Receiving" Then
		
		ProductStructure_2 = New Structure;
		ProductStructure_2.Insert("Products", "");
		ProductStructure_2.Insert("Characteristic", "");
		ProductStructure_2.Insert("Package", "");
		ProductStructure_2.Insert("Series", "");
		ProductStructure_2.Insert("Purpose", "");
		
		FillPropertyValues(ProductStructure_2, Result);
	
		ShoppingCartSearchResult = ShoppingCart.FindRows(ProductStructure_2);
		
		If ShoppingCartSearchResult.Count() > 0 Then 
			ShoppingCartSearchResult[0].NumberOfPackages = ShoppingCartSearchResult[0].NumberOfPackages + Result.NumberOfPackages;
		Else
			NewRow = ShoppingCart.Add();
			FillPropertyValues(NewRow, Result);
			SetConditionalAppearance();
		EndIf;
		
	Else
		
		UpdateFormData();
		CreateRepresentationOfWarehouseSelection();
		ToFormRepresentationOfSelectionRoom(); 
		
	EndIf;
	
	ChangeNameOfPlaceCommand();
	
EndProcedure

&AtServer
Procedure FillInListOfProducts()
	
	Goods.Clear();
	ShoppingCart.Clear();
	
	If Not ValueIsFilled(ReceivingArea) Then
		Return;
	EndIf;
	
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.PutAwayList();
	
	Query.SetParameter("ReceivingArea", ReceivingArea);
	GoodsForAcceptance = Query.Execute().Unload();
	
	Goods.Load(GoodsForAcceptance);
	ChangeNameOfPlaceCommand();
	
EndProcedure

&AtServer
Procedure CreateRepresentationOfWarehouseSelection()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Warehouse) Then
		PresentationsOfSelections = Warehouse;
		Items.TeamSelectionsToOpen.TextColor = WebColors.Black;
		Items.TeamSelectionsClear.Visible = True;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuBlack;
	Else
		PresentationsOfSelections = NStr("vi = 'Kho bãi';
										|ru = 'Склад';
										|en = 'Warehouse'; fa = 'Warehouse';
										|it = 'Magazzino';
										|pl = 'Magazyn';
										|tr = 'Ambar'");
		Items.TeamSelectionsToOpen.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClear.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	If Common.ObjectAttributeValue(Warehouse, "IsFolder") = True Then
		UseWarerooms = False;
	Else
		UseWarerooms = Warehouse["UseWarerooms"];
	EndIf;
	Items.GroupTeamSelectionsOpen2.Visible    = UseWarerooms;
	Items.TeamSelectionsClearRoom.Visible = UseWarerooms;
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
EndProcedure

&AtServer
Procedure ToFormRepresentationOfSelectionRoom()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Premise) Then
		PresentationsOfSelections = Premise;
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.Black;
		Items.TeamSelectionsClearRoom.Visible = True;
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuBlack;
	Else
		PresentationsOfSelections = NStr("vi = 'Nhà kho';
										|ru = 'Помещение';
										|en = 'Wareroom'; fa = 'بخش انبار';
										|it = 'Locale';
										|pl = 'Pomieszczenie';
										|tr = 'Alan'");
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClearRoom.Visible = False;
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsOpenRoom.Title = PresentationsOfSelections;
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
		
	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1); 
	
	If Not BarcodesAreValid Then
		Return;
	EndIf;
	
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
		
		QuantityFromWK = ProductData_8.Count;
	
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products","");
		TheStructureOfTheSearch.Insert("Characteristic","");
		TheStructureOfTheSearch.Insert("Series","");
		TheStructureOfTheSearch.Insert("Package","");
		
		FillPropertyValues(TheStructureOfTheSearch, ProductData_8);
		SearchResult = Goods.FindRows(TheStructureOfTheSearch);
			
		If SearchResult.Count() > 0 Then
					
			SearchResult[0].ProductSelected = True;
				
			ShoppingCartSearchResult = ShoppingCart.FindRows(TheStructureOfTheSearch);
					
			If ShoppingCartSearchResult.Count() > 0 Then 
				QuantityInCart = ShoppingCartSearchResult[0].NumberOfPackages;
				If QuantityInCart + QuantityFromWK > SearchResult[0].NumberOfPackages Then
					ErrorText = StrTemplate(NStr("vi = 'Không cần sắp xếp hàng hóa: %1';
												|ru = 'Размещение товара не требуется: %1';
												|en = 'Goods put-away is not required: %1'; fa = 'Goods put-away is not required: %1';
												|it = 'Размещение товара не требуется: %1';
												|pl = 'Goods put-away is not required: %1';
												|tr = 'Ürün yerleştirme gerekli değildir: %1'"), ProductData_8.Products);
					Status(ErrorText);
					Return;
				Else
					ShoppingCartSearchResult[0].NumberOfPackages = QuantityInCart + QuantityFromWK;
				EndIf;
			Else
				NewRow = ShoppingCart.Add();
				FillPropertyValues(NewRow, SearchResult[0]);
				NewRow.NumberOfPackages = QuantityFromWK;
				SetConditionalAppearance();
			EndIf;
					
			ChangeNameOfPlaceCommand();
					
			Return;
		Else
			ErrorText = StrTemplate(NStr("vi = 'Không cần sắp xếp hàng hóa: %1';
										|ru = 'Размещение товара не требуется: %1';
										|en = 'Goods put-away is not required: %1'; fa = 'Goods put-away is not required: %1';
										|it = 'Размещение товара не требуется: %1';
										|pl = 'Goods put-away is not required: %1';
										|tr = 'Ürün yerleştirme gerekli değildir: %1'"), ProductData_8.Products);
			Status(ErrorText);
			Return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScanningResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
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
		
		LongDesc = New CallbackDescription("UpdateForm", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("Products", ProductData_8.Products);
		FormParameters.Insert("Characteristic", ProductData_8.Characteristic);
		FormParameters.Insert("Series", ProductData_8.Series);
		FormParameters.Insert("Package", ProductData_8.Package);
		FormParameters.Insert("Count", ProductData_8.Count);
		FormParameters.Insert("Mode", "Receiving");
		FormParameters.Insert("LineNumber", 0);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
		
	EndIf;

EndProcedure

&AtServerNoContext
Function FillInDefaultAcceptanceZone(Warehouse, Premise)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StorageBins.Ref AS ReceivingArea
		|FROM
		|	Catalog.StorageBins AS StorageBins
		|WHERE
		|	StorageBins.Owner = &Warehouse
		|	AND StorageBins.Premise = &Premise
		|	AND StorageBins.StorageBinType = &TypeOfStorageCellAcceptance";
	
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("TypeOfStorageCellAcceptance", Enums.TypesOfStorageCells.Receiving);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Catalogs.StorageBins.EmptyRef();
	EndIf;
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Return SelectionDetailRecords.ReceivingArea;
	EndDo;
	
EndFunction

&AtClient
Procedure ReceivingAreaOnChange(Item)
	UpdateFormData();
EndProcedure

&AtClient
Procedure SelectProducts(Command)
	
	ThisIsSelectionOfGoods = Not ThisIsSelectionOfGoods;
	
	If ThisIsSelectionOfGoods Then
		Items.SelectProducts.BackColor = WebColors.LightGoldenRod;
	Else
		For Each String In Goods Do
			String.ProductSelected = False;
		EndDo;
		
		Items.SelectProducts.BackColor = WebColors.White;
	EndIf;
	
EndProcedure

&AtServer
Function NewPlacementATServer()
	
	ByAllProducts = 0;
	
	For Each String In ShoppingCart Do
		ByAllProducts = ByAllProducts + 1;
	EndDo;
	
	NumberQualifiers = New NumberQualifiers(15, 3, AllowedSign.Nonnegative);
	NumberDetails = New TypeDescription("Number", NumberQualifiers);
	
	TableOfSelectedProducts = New ValueTable;
	TableOfSelectedProducts.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
	TableOfSelectedProducts.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfSelectedProducts.Columns.Add("Purpose",New TypeDescription("CatalogRef.Assignments"));
	TableOfSelectedProducts.Columns.Add("Series",New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfSelectedProducts.Columns.Add("Package",New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfSelectedProducts.Columns.Add("NumberOfPackages", NumberDetails);
	
	ForEntireNomenclatureParameter = True;

	If ByAllProducts <> 0 Then
		For Each String In ShoppingCart Do
			NewRow = TableOfSelectedProducts.Add();
			FillPropertyValues(NewRow, String);
			If Common.ObjectAttributeValue(String.Package, "MeasuredValueType") <> Enums.TypesOfMeasuredValues.Package Then
				NewRow.Package = Undefined;
			EndIf;
		EndDo;
		ForEntireNomenclatureParameter = False;
	EndIf;
	
	PlacementParameters = DataProcessors.MobileWarehouseKeeperWorkspace.ParametersForCreatingItemPlacement();
	PlacementParameters.Warehouse = Warehouse;
	PlacementParameters.Premise = Premise; 
	PlacementParameters.Performer = Performer;
	PlacementParameters.ReceivingArea = ReceivingArea;
    PlacementParameters.ProductsTable = TableOfSelectedProducts;
	PlacementParameters.LimitByVolume = LimitByVolume;
	PlacementParameters.LimitByWeight = LimitByWeight;
	PlacementParameters.LimitationByVolume = LimitationByVolume;
    PlacementParameters.LimitationByWeight = LimitationByWeight;
    PlacementParameters.ByAllProducts = ForEntireNomenclatureParameter;
	
	StructureOfNewPlacement = DataProcessors.MobileWarehouseKeeperWorkspace.NewPlacementOfItems(PlacementParameters); 
		
	UpdateFormData();

	Return StructureOfNewPlacement;
		
EndFunction

&AtClient
Procedure CancelShoppingCartSelection(Command)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products",   Items.ShoppingCart.CurrentData.Products);
	TheStructureOfTheSearch.Insert("Characteristic", Items.ShoppingCart.CurrentData.Characteristic);
	TheStructureOfTheSearch.Insert("Series",          Items.ShoppingCart.CurrentData.Series);
	TheStructureOfTheSearch.Insert("Package",       Items.ShoppingCart.CurrentData.Package);
	
	SearchResult = ShoppingCart.FindRows(TheStructureOfTheSearch);
	For Each String In SearchResult Do
		
		String.ProductSelected = False;
		
	EndDo;
	
	RowIndex = ShoppingCart.IndexOf(Items.ShoppingCart.CurrentData);
	ShoppingCart.Delete(RowIndex);
	
	ChangeNameOfPlaceCommand();
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure ChangeNameOfPlaceCommand()
	
	NumberOfRowsInBucket = ShoppingCart.Count();
	If NumberOfRowsInBucket > 0 Then
		Items.Place.Title = StrTemplate(NStr("vi = 'Cần xếp vào (%1)';
											|ru = 'Разместить (%1)';
											|en = 'Put away (%1)'; fa = 'Put away (%1)';
											|it = 'Inserire (%1)';
											|pl = 'Umieść (%1)';
											|tr = 'Yerleştir (%1)'"), NumberOfRowsInBucket);
	Else
		Items.Place.Title = NStr("vi = 'Xếp vào tất cả';
								|ru = 'Разместить все';
								|en = 'Put away all'; fa = 'جای‌گذاری همه';
								|it = 'Inserire tutti';
								|pl = 'Umieść wszystkie';
								|tr = 'Hepsini yerleştir'");
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ItemDataBySchool(Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.ItemDataBySchool(Barcode);
	
EndFunction

&AtClient
Procedure SelectionsClearInboundArea(Command)
	
	ReceivingArea = Undefined;
	UpdateFormData();
	
EndProcedure

#EndRegion
