
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Products          = Parameters.Products;
	Characteristic        = Parameters.Characteristic;
	Package              = Parameters.Package;
	ProductKind       = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Products, "ProductKind");
	ShowProductPhotos = Parameters.ShowProductPhotos;
	ExpirationDate_          = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Products, "ExpirationDate_");
	DocumentBarcode     = Parameters.DocumentBarcode;
	ScanningProcedure   = Parameters.ScanningProcedure;
	
	If Parameters.Property("Warehouse") Then
		Warehouse = Parameters.Warehouse;
	EndIf;
	
	If Parameters.Property("DocumentSource") Then
		DocumentSource = Parameters.DocumentSource;
	EndIf;
	
	If Parameters.Property("ReceiptReferenceOrder") Then
		ReceiptReferenceOrder = Parameters.ReceiptReferenceOrder;
	EndIf;
	
	If Parameters.Property("SelectionOrder_") Then
		SelectionOrder_ = Parameters.SelectionOrder_;
	EndIf;
	
	If Parameters.Property("WarehouseOperation") Then
		WarehouseOperation = Parameters.WarehouseOperation;
	EndIf;
	
	If Parameters.Property("Premise") Then
		Premise = Parameters.Premise;
	EndIf;
	
	If Not ValueIsFilled(Package) Then
		Package = UnitOfProductMeasurement_();
	EndIf;
	
	If Parameters.Property("Series") Then
		Series = Parameters.Series;
	EndIf;
	
	If Not GetFunctionalOption("UseItemsBatch") Then
		Items.GroupSeries.Visible = False;
	EndIf;
	
	If Parameters.Property("SKU") Then
		SKU = Parameters.SKU;
	EndIf;
	
	If Parameters.Property("PackageBarcode") And ValueIsFilled(Parameters.PackageBarcode) Then
		BarcodeString = PackageBarcodes.Add();
		BarcodeString.PackageBarcode = Parameters.PackageBarcode;
		BarcodeString.Products     = Parameters.Products;
		BarcodeString.Characteristic   = Parameters.Characteristic;
	EndIf;
	
	UseCharacteristics = MobileWarehouseKeeperWorkspace.ItemVariantsAreUsed(Products);
	
	If Parameters.Property("Count") Then
		NumberOfPackages             = Parameters.Count;		
		MaximumNumberOfPackages = Parameters.Count;
	EndIf;

	If Parameters.Property("Purpose") Then
		Purpose = Parameters.Purpose;
	EndIf; 
	
	If Parameters.Property("Cell") Then
		Cell = Parameters.Cell;
	EndIf;
	
	Mode = Parameters.Mode;
	Literal = "LineNumber";
	LineNumber = Parameters[Literal];
	
	WarehouseProperties = DataProcessors.MobileWarehouseKeeperWorkspace.WarehouseProperties(Warehouse);
	If ValueIsFilled(WarehouseProperties) Then
		UseBinLocationWarehousing            = WarehouseProperties.UseBinLocationWarehousing;
		UseWarehouseManagemantSystemForGoodsReceipt = WarehouseProperties.UseWarehouseManagemantSystemForGoodsReceipt;
		UseWarerooms          = WarehouseProperties.UseWarerooms;
	EndIf;
	
	If WarehouseProperties.UseWarerooms Then
		StructureOfRoom = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(Premise, "UseBinLocationWarehousing");
		UseBinLocationWarehousing = StructureOfRoom.UseBinLocationWarehousing;
	EndIf;
	
#If Not MobileStandaloneServer Then
	If ShowProductPhotos Then 
		Items.GroupPhotoAdd.Enabled = AccessRight("Insert", Metadata.Catalogs.ProductsAttachedFiles);
		UploadProductPhoto(); 
	Else
		Items.PhotosOfProducts.Visible = False;
	EndIf;
#Else
	Items.PhotosOfProducts.Visible = False;
#EndIf
	
	FillInLinksOfDestinationSelectionParameters();
	SetConditionalAppearance();
	
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
	
	If EventName = "Write_ItemsBatches" And ValueIsFilled(Source) Then
		Series = Source;
	EndIf;
	
	EventName = Undefined;

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.PackagesAndUnitsOfMeasure.Form.FormOfSelectionFromDocuments")
		Or Upper(ChoiceSource.FormName) = Upper("Catalog.PackagesAndUnitsOfMeasure.Form.FormOfSelectionFromDocumentsOfflineMode") Then
		
		If ValueIsFilled(ValueSelected) Then
			Package = ValueSelected;
		Else
			Package = UnitOfProductMeasurement_();
		EndIf;
		
		Items.Package.Title = Package;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Confirm(Command)
	
	If Items.SelectCell.Visible 
		And Cell.IsEmpty() And ScanningProcedure = "FirstScanProduct" Then
		Status(NStr("vi = 'Hãy chỉ ra ô hàng';
					|ru = 'Укажите ячейку';
					|en = 'Specify a storage bin'; fa = 'Specify a storage bin';
					|it = 'Specificare la cella';
					|pl = 'Wskaż komórkę';
					|tr = 'Hücre belirt'"));
		Return;
	EndIf;
	
	CloseProductProfile();
	
EndProcedure

&AtClient
Procedure Package(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	FormOpenParameters.Insert("Products", Products);
	FormOpenParameters.Insert("Warehouse", Warehouse);
	FormOpenParameters.Insert("Premise", Premise);
	
	If UsedFormServer = UsedServer.Main Then
		OpenForm(
			"Catalog.PackagesAndUnitsOfMeasure.Form.FormOfSelectionFromDocuments",
			FormOpenParameters,
			ThisObject,,,,,
			FormWindowOpeningMode.LockOwnerWindow);
	Else
		OpenForm(
			"Catalog.PackagesAndUnitsOfMeasure.Form.FormOfSelectionFromDocumentsOfflineMode",
			FormOpenParameters,
			ThisObject,,,,,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure IncreasedAmount(Command)
	NumberOfPackages = NumberOfPackages + 1;
EndProcedure

&AtClient
Procedure ReducedAmount(Command)
	
	NumberOfPackages = NumberOfPackages - 1;
	
	If NumberOfPackages < 0 Then
		NumberOfPackages = 0 ;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectCell(Command)
	
	LongDesc = New CallbackDescription("ResultOfCellReplacement", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Products", Products);
	FormParameters.Insert("Characteristic", Characteristic);
	FormParameters.Insert("Series", Series);
	FormParameters.Insert("Mode", Mode);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Cells",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Barcodes(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Products);
	FormParameters.Insert("Package", Package);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Barcodes",FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Products);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.EditGoods",FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure MaxCount(Command)
	NumberOfPackages = MaximumNumberOfPackages;
EndProcedure

&AtClient
Procedure AddPhoto(Command)
	
	ValueList = New ValueList;
	ValueList.Add("ChoosePhoto", NStr("vi = 'Chọn ảnh';
										|ru = 'Выбрать фото';
										|en = 'Select a photo'; fa = 'انتخاب عکس';
										|it = 'Selezionare foto';
										|pl = 'Wybierz zdjęcie';
										|tr = 'Fotoğraf seç'"));
	ValueList.Add("TakePhoto", NStr("vi = 'Tạo ảnh';
									|ru = 'Сделать фото';
									|en = 'Take a photo'; fa = 'Take a photo';
									|it = 'Fare foto';
									|pl = 'Zrób zdjęcie';
									|tr = 'Fotoğraf çek'"));
	ValueList.Add("Cancel", NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Annulla';
								|pl = 'Cancel';
								|tr = 'İptal'"));
	
	Notification = New CallbackDescription("AfterClosingQuestionPhoto", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Thêm ảnh vào hàng hóa';
									|ru = 'Добавить фотографию к товару';
									|en = 'Add a photo to goods'; fa = 'Add a photo to goods';
									|it = 'Aggiungere foto all''articolo';
									|pl = 'Dodaj zdjęcie do towaru';
									|tr = 'Ürüne fotoğraf ekle'"), ValueList, 0);
	
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
Procedure SeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Filter = New Structure();
	Filter.Insert("ProductKind", ProductKind);
	Filter.Insert("ExpirationDate_", ExpirationDate_);
	
	SeriesSelection_3 = New CallbackDescription("SeriesSelection_3", ThisObject);
	
	If UsedFormServer = UsedServer.Main Then
		OpenForm("Catalog.ItemsBatches.Form.ChoiceForm", Filter, ThisObject,,,, SeriesSelection_3);
	Else
		OpenForm("Catalog.ItemsBatches.Form.FormOfSelectionOfflineMode", Filter, ThisObject,,,, SeriesSelection_3);
	EndIf;
	
EndProcedure

#If MobileClient Then
&AtClient
Procedure BarcodeScanning(Command)
			
	If MultimediaTools.BarcodeScanningSupported() Then		
		ScanningHandler = New CallbackDescription("ScanProcessing", ThisObject);
		MultimediaTools.ShowBarcodeScanning(NStr("vi = 'Hướng máy ảnh vào mã vạch';
												|ru = 'Наведите камеру на штрихкод';
												|en = 'Point the camera at the barcode'; fa = 'Point the camera at the barcode';
												|it = 'Puntare la camera sul codice a barre';
												|pl = 'Skieruj aparat na kod kreskowy';
												|tr = 'Kamerayı barkoda doğrult'"), ScanningHandler,,
			BarcodeType.Linear);
	EndIf;
			
EndProcedure
#EndIf

#EndRegion

#Region Private

#If MobileClient Then 
&AtClient
Procedure ScanProcessing(BarcodeCamera, Result, Message, AdditionalParameters) Export

	If Result Then
		MultimediaTools.PlaySoundAlert(SoundAlert.Default, True);
		MultimediaTools.CloseBarcodeScanning();
		
		Barcode = BarcodeCamera;
		ProcessBarcode(New Structure("Barcode", Barcode));
	Else
		Message = NStr("vi = 'Lỗi xử lý mã vạch';
						|ru = 'Ошибка обработки штрихкода';
						|en = 'Barcode processing error'; fa = 'Barcode processing error';
						|it = 'Barcode processing error';
						|pl = 'Barcode processing error';
						|tr = 'Barkod İşleme hatası'");
	EndIf;
	
EndProcedure
#EndIf

&AtServer
Procedure SetConditionalAppearance()
	
	BatchAccountingPolicy = DataProcessors.MobileWarehouseKeeperWorkspace.BatchAccountingPolicy(ProductKind, Warehouse);
	EmptyBatch_ = Catalogs.ItemsBatches.EmptyRef();
	
	Items.Characteristic.Visible = UseCharacteristics;
	Items.Package.Title = Package;
	
	Items.GroupPhotoAdd.Visible = Not ValueIsFilled(ProductPhoto1) 
	And Not ValueIsFilled(ProductPhoto2)
	And Not ValueIsFilled(ProductPhoto3);
	Items.GroupPhoto1.Visible = ValueIsFilled(ProductPhoto1);
	Items.GroupPhoto2.Visible = ValueIsFilled(ProductPhoto2);
	Items.GroupPhoto3.Visible = ValueIsFilled(ProductPhoto3);
	
	Items.SelectCell.Visible      = False;
	
	Items.Purpose.Visible = Constants.UseOrderSupplyWithAssignment.Get();
	
	If Mode = "View" Then
		
		Items.Count.Type                   = FormFieldType.LabelField;
		Items.Package.Enabled             = False;
		Items.Characteristic.Enabled       = False;
		Items.Series.Enabled                = False;
		Items.CreateSeries.Visible           = False;
		Items.Purpose.Enabled           = False;
		Items.Confirm.Visible            = False;
		Items.Count.ReadOnly        = True;
		Items.MaxCount.Visible = False;
		Items.Minus.Visible                  = False;
		Items.Plus.Visible                   = False;
		If ValueIsFilled(Cell) Then
			Items.SelectCell.Visible = True;
			Items.SelectCell.Title = Cell; 
			Items.SelectCell.Enabled = False;
		EndIf;
				
	ElsIf Mode = "Receiving" Or Mode = "EditingAcceptance" Then
		Items.Count.Type             = FormFieldType.InputField;
		Items.Confirm.Visible      = True;
		Items.Confirm.Title      = NStr("vi = 'Tiếp nhận';
										|ru = 'Принять';
										|en = 'Accept'; fa = 'پذیرش';
										|it = 'Принять';
										|pl = 'Accept';
										|tr = 'Kabul et'");
		Items.MaxCount.Title = StrTemplate(NStr("vi = 'Điền %1';
												|ru = 'Заполнить %1';
												|en = 'Fill %1'; fa = 'Fill %1';
												|it = 'Заполнить %1';
												|pl = 'Fill %1';
												|tr = 'Doldur %1'"), MaximumNumberOfPackages);
		
		If ValueIsFilled(Package) Then
			Items.Package.Title = Package;
		EndIf;
		
		Items.GroupSeries.Visible = False;
		
		If ValueIsFilled(BatchAccountingPolicy) Then
			KeepAccountingByBatch = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(BatchAccountingPolicy, "SpecifyOnReceiving");
		Else
			KeepAccountingByBatch = False;
		EndIf;
		
		If KeepAccountingByBatch Then
			Items.GroupSeries.Visible = True;
		Else
			Series = EmptyBatch_;
		EndIf;

	ElsIf Mode = "ShoppingCartSelection" Then
		Items.Count.Type             = FormFieldType.InputField;
		Items.Confirm.Visible      = True;
		Items.Package.Enabled       = False;
		Items.Purpose.Enabled     = False;
		Items.Confirm.Title      = NStr("vi = 'Xác nhận';
										|ru = 'Подтвердить';
										|en = 'Confirm'; fa = 'تأیید';
										|it = 'Подтвердить';
										|pl = 'Confirm';
										|tr = 'Doğrula'");
		
		If ValueIsFilled(Package) Then
			Items.Package.Title = Package;
		EndIf;
		
	ElsIf Mode = "Shipment" Or Mode = "EditShipment" Then
		Items.Count.Type             = FormFieldType.InputField;
		Items.Confirm.Visible      = True; 
		Items.Confirm.Title  = NStr("vi = 'Giao hàng';
									|ru = 'Отгрузить';
									|en = 'Ship'; fa = 'ارسال';
									|it = 'Отгрузить';
									|pl = 'Ship';
									|tr = 'Sevk et'");
		Items.MaxCount.Title = StrTemplate(NStr("vi = 'Điền %1';
												|ru = 'Заполнить %1';
												|en = 'Fill %1'; fa = 'Fill %1';
												|it = 'Заполнить %1';
												|pl = 'Fill %1';
												|tr = 'Doldur %1'"), MaximumNumberOfPackages);
		
		If ValueIsFilled(Package) Then
			Items.Package.Title = Package;
		EndIf;
		
		Items.GroupSeries.Visible = False;
		
		If ValueIsFilled(BatchAccountingPolicy) Then   
			
			SeriesOnShipment =  MobileWarehouseKeeperWorkspace.ObjectAttributesValues(BatchAccountingPolicy,
				"SpecifyWhenPlanningPicking, SpecifyByPickingResult, SpecifyWhenPlanningShipment");
						
			KeepAccountingByBatch = SeriesOnShipment.SpecifyWhenPlanningPicking 
				Or SeriesOnShipment.SpecifyByPickingResult;
			
			If KeepAccountingByBatch Then
				Items.GroupSeries.Visible = True;
			ElsIf SeriesOnShipment.SpecifyWhenPlanningShipment Then
				Items.GroupSeries.Visible = True;
				Items.Series.Enabled = False;
				Items.CreateSeries.Visible = False;
			Else
				Series = EmptyBatch_;
			EndIf;
		Else
			KeepAccountingByBatch = False;
			Series = EmptyBatch_;
		EndIf;
	
	ElsIf Mode = "RecalculationShipment" Or Mode = "EditingRecalculationShipment" 
		Or Mode = "EditingRecalculationShipmentWithoutBatch" Then
		
		Items.Count.Type                   = FormFieldType.InputField;
		Items.Confirm.Visible            = True;
		Items.MaxCount.Visible = False;
		
		Items.GroupSeries.Visible = False;
		
		If ValueIsFilled(Package) Then
			Items.Package.Title = Package;
		EndIf;
		
		Items.GroupSeries.Visible = False;

		If ValueIsFilled(BatchAccountingPolicy) Then
			SeriesOnShipment =  MobileWarehouseKeeperWorkspace.ObjectAttributesValues(BatchAccountingPolicy, 
				"SpecifyByPickingResult, SpecifyWhenPlanningPicking, SpecifyWhenPlanningShipment");   
				
			KeepAccountingByBatch = SeriesOnShipment.SpecifyByPickingResult Or SeriesOnShipment.SpecifyWhenPlanningShipment
				Or SeriesOnShipment.SpecifyWhenPlanningPicking; 
				
			If KeepAccountingByBatch Then
				Items.GroupSeries.Visible = True;
			Else
				Series = EmptyBatch_;
			EndIf;
		Else
			KeepAccountingByBatch = False;
			Series = EmptyBatch_;
		EndIf;
	
	ElsIf Mode = "Recalculate" Or Mode = "EditingRecalculation" Then
		
		Items.Count.Type                   = FormFieldType.InputField;
		Items.Package.Visible               = False;
		Items.Confirm.Visible            = True;
		Items.Package.Enabled             = False;
		Items.MaxCount.Visible = False;
		
		Items.GroupSeries.Visible = False;
		
		If ValueIsFilled(BatchAccountingPolicy) Then
			KeepAccountingByBatch = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(BatchAccountingPolicy, "SpecifyWhenRecountingInventory");
		Else
			KeepAccountingByBatch = False;
		EndIf;
		
		If KeepAccountingByBatch Then
			Items.GroupSeries.Visible = True; 
		Else
			Series = EmptyBatch_;
		EndIf;
		
		Items.SelectCell.Visible = UseBinLocationWarehousing;
		If ValueIsFilled(Cell) Then
			Items.SelectCell.Title = Cell;
		EndIf;
		
	ElsIf Mode = "Move" Then
		
		Items.Count.Type                   = FormFieldType.InputField;
		Items.Confirm.Visible            = True;
		Items.MaxCount.Visible = False; 
		
		Items.GroupSeries.Visible = False;

		If ValueIsFilled(BatchAccountingPolicy) Then
			KeepAccountingByBatch = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(BatchAccountingPolicy, "SpecifyUponTransferBetweenWarerooms");
		Else
			KeepAccountingByBatch = False;
		EndIf;
		
		If KeepAccountingByBatch Then
			Items.GroupSeries.Visible = True;
		Else
			Series = EmptyBatch_;
		EndIf;
		
		Items.SelectCell.Visible = UseBinLocationWarehousing;
		If ValueIsFilled(Cell) Then
			Items.SelectCell.Title = Cell;
		EndIf;

	ElsIf Mode = "PlacementInCell" Or Mode = "EditingPlacementByCells" Then
		
		Items.Count.Type             = FormFieldType.InputField;
		Items.Confirm.Visible      = True;
		Items.SelectCell.Visible    = True;
		Items.Confirm.Title      = NStr("vi = 'Cần xếp vào';
										|ru = 'Разместить';
										|en = 'Put away'; fa = 'جای‌گذاری';
										|it = 'Разместить';
										|pl = 'Put away';
										|tr = 'Yerleştir'");
		Items.MaxCount.Title = StrTemplate(NStr("vi = 'Điền %1';
												|ru = 'Заполнить %1';
												|en = 'Fill %1'; fa = 'Fill %1';
												|it = 'Заполнить %1';
												|pl = 'Fill %1';
												|tr = 'Doldur %1'"), MaximumNumberOfPackages);
		
		If ValueIsFilled(Package) Then
			Items.Package.Title = Package;
		EndIf;
		
		Items.SelectCell.Visible = UseBinLocationWarehousing;
		If ValueIsFilled(Cell) Then
			Items.SelectCell.Title = Cell;
		EndIf;
		
	ElsIf Mode = "SelectionFromShipmentCell" Or Mode = "EditingSelectionFromShipmentCell" Then
		
		Items.Count.Type             = FormFieldType.InputField;
		Items.Confirm.Visible      = True;
		Items.Confirm.Title      = NStr("vi = 'Hiển thị';
										|ru = 'Отобрать';
										|en = 'Pick'; fa = 'انتخاب';
										|it = 'Отобрать';
										|pl = 'Pick';
										|tr = 'Seç'");
		Items.MaxCount.Title = StrTemplate(NStr("vi = 'Điền %1';
												|ru = 'Заполнить %1';
												|en = 'Fill %1'; fa = 'Fill %1';
												|it = 'Заполнить %1';
												|pl = 'Fill %1';
												|tr = 'Doldur %1'"), MaximumNumberOfPackages);
		
		Items.SelectCell.Visible = UseBinLocationWarehousing;
		If ValueIsFilled(Cell) Then
			Items.SelectCell.Title = Cell;
		EndIf;
		
		If ValueIsFilled(Package) Then
			Items.Package.Title = Package;
		EndIf;

		Items.GroupSeries.Visible = False;

		If ValueIsFilled(BatchAccountingPolicy) Then
			
			SeriesOnShipment =  MobileWarehouseKeeperWorkspace.ObjectAttributesValues(BatchAccountingPolicy, 
				"SpecifyByPickingResult, SpecifyWhenPlanningPicking, SpecifyWhenPlanningShipment, AccountForRemainingSeries"); 
			
			If UseBinLocationWarehousing Then
				KeepAccountingByBatch = SeriesOnShipment.SpecifyByPickingResult And SeriesOnShipment.AccountForRemainingSeries; 
			Else
				KeepAccountingByBatch = SeriesOnShipment.SpecifyWhenPlanningPicking;
			EndIf;
				
			If KeepAccountingByBatch Then
				Items.GroupSeries.Visible = True;
			ElsIf SeriesOnShipment.SpecifyWhenPlanningShipment 
				Or SeriesOnShipment.SpecifyWhenPlanningPicking Then
				Items.GroupSeries.Visible = True;
				Items.Series.Enabled = False;
				Items.CreateSeries.Visible = False;
			Else
				Series = EmptyBatch_;
			EndIf;
		Else
			KeepAccountingByBatch = False;
			Series = EmptyBatch_;
		EndIf;
		
	ElsIf Mode = "SpecifyingSeries" Or Mode = "EditingBatches" Then
		
		Items.Count.Type             = FormFieldType.InputField;
		Items.Confirm.Visible      = True;
		Items.Confirm.Title      = NStr("vi = 'Xác nhận';
										|ru = 'Подтвердить';
										|en = 'Confirm'; fa = 'تأیید';
										|it = 'Подтвердить';
										|pl = 'Confirm';
										|tr = 'Doğrula'");
		Items.MaxCount.Title = StrTemplate(NStr("vi = 'Điền %1';
												|ru = 'Заполнить %1';
												|en = 'Fill %1'; fa = 'Fill %1';
												|it = 'Заполнить %1';
												|pl = 'Fill %1';
												|tr = 'Doldur %1'"), MaximumNumberOfPackages);
		
		Items.SelectCell.Visible = UseBinLocationWarehousing;
		If ValueIsFilled(Cell) Then
			Items.SelectCell.Title = Cell;
		EndIf;
		
		Items.GroupSeries.Visible = True;
		KeepAccountingByBatch = True;
		
	EndIf;
	
	Items.Count.Font = New Font(, 16, True, , , );
	
	If Not KeepAccountingByBatch Then
		Items.Series.Enabled = False;
		Items.CreateSeries.Visible = False;
	Else
#If MobileStandaloneServer Then
		Items.Series.CreateButton = False;
		Items.CreateSeries.Visible = False;
#EndIf
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
		
	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1); 
	
	If Not BarcodesAreValid Then
		Return;
	EndIf;
	
	Barcode = BarcodeData_1.Barcode;
	
	If DocumentBarcode = Barcode Then
		If Items.SelectCell.Visible Then
			If ScanningProcedure = "FirstScanCell" Then
				CloseProductProfile(,,True);
			ElsIf Cell.IsEmpty() Then
				Status(NStr("vi = 'Hãy chỉ ra ô hàng';
							|ru = 'Укажите ячейку';
							|en = 'Specify a storage bin'; fa = 'Specify a storage bin';
							|it = 'Specificare la cella';
							|pl = 'Wskaż komórkę';
							|tr = 'Hücre belirt'"));
			Else
				CloseProductProfile();
			EndIf;
		Else
			CloseProductProfile();
		EndIf;
		Return;	
	EndIf;
	
	If KeepAccountingByBatch Then
		
		SeriesParameters = GetSeriesParametersOnServer(Barcode);
				
		If ValueIsFilled(SeriesParameters.Series) Then
			Series = SeriesParameters.Series;
			NumberOfPackages = NumberOfPackages + 1;
			Return;
		EndIf;
	EndIf;
	
	ProductData_9 = ItemDataBySchool(Barcode);
	
	If ValueIsFilled(ProductData_9) Then
		If ProductData_9.Count() > 1 Then
			CloseProductProfile(ProductData_9);
		ElsIf ProductData_9[0].Products = Products
			And ProductData_9[0].Characteristic = Characteristic
			And ProductData_9[0].Package = Package
			And (ProductData_9[0].Series = Series Or Not KeepAccountingByBatch) Then
			
			NumberOfPackages = NumberOfPackages + ProductData_9[0].Count;
		Else
			CloseProductProfile(ProductData_9);
		EndIf;
		Return;
	EndIf;
	
	If Items.SelectCell.Visible Then 
		
		CellData = CellDataByWK(Barcode); 
		If ValueIsFilled(CellData.Cell) Then
			If CellData.Cell = Cell Then
				CloseProductProfile(); 
			ElsIf Mode = "Move" Then 
				CloseProductProfile(,CellData, True);
			Else
				CloseProductProfile(,CellData);
			EndIf;
		
			Return;
		EndIf;
		
		Status(NStr("vi = 'Không tìm thấy mặt hàng hoặc ô hàng theo mã vạch';
					|ru = 'Номенклатура или ячейка по штрихкоду не найдена';
					|en = 'Item or storage bin is not found by barcode'; fa = 'Item or storage bin is not found by barcode';
					|it = 'Item or storage bin is not found by barcode';
					|pl = 'Item or storage bin is not found by barcode';
					|tr = 'Barkod ile ürün veya depo yeri bulunamadı'"));
		Return;
		
	EndIf;
	
	Status(NStr("vi = 'Không tìm thấy mặt hàng theo mã vạch';
				|ru = 'Номенклатура по штрихкоду не найдена';
				|en = 'Item is not found by barcode'; fa = 'Item is not found by barcode';
				|it = 'Item is not found by barcode';
				|pl = 'Item is not found by barcode';
				|tr = 'Barkod ile ürün bulunamadı'"));

EndProcedure

&AtServer
Procedure UploadProductPhoto()

#If Not MobileStandaloneServer Then
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProductsAttachedFiles.Ref AS Ref
		|FROM
		|	Catalog.ProductsAttachedFiles AS ProductsAttachedFiles
		|WHERE
		|	ProductsAttachedFiles.FileOwner = &FileOwner
		|	AND NOT ProductsAttachedFiles.DeletionMark";
	
	Query.SetParameter("FileOwner", Products);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	Cnt = 1;
	While SelectionDetailRecords.Next() Do
		
		If Cnt > 3 Then
			Continue;
		EndIf;
		
		LinkToDDF = FilesOperations.FileData(SelectionDetailRecords.Ref, UUID).RefToBinaryFileData;
		ThisObject["ProductPhoto" + Cnt] = LinkToDDF;
		
		Cnt = Cnt + 1;
		
	EndDo;	
#EndIf
EndProcedure

&AtServer
Function UnitOfProductMeasurement_()
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.GetCatalogAttributes(Products, "UnitOfMeasure");
	
EndFunction

&AtClient
Procedure ResultOfCellReplacement(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Cell = Result;
	Items.SelectCell.Title = Cell;
	
	If Mode = "PlacementInCell" Or Mode = "EditingPlacementByCells" 
		Or Mode = "Move" Or Mode = "SelectionFromCell" Or Mode = "EditingSelectionFromCell" 
		Or Mode = "SelectionFromShipmentCell" Or Mode = "EditingSelectionFromShipmentCell" Then
		
		Purpose = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionPhoto(Result, Var_Parameters) Export
	
	If Result = "ChoosePhoto" Then
		
#If MobileClient Then
		Execute("FilesOperationsClient.AddFiles(Products, UUID, , Undefined)");
#Else
		FilesOperationsClient.AddFiles(Products, UUID, , Undefined);
#EndIf
		UploadProductPhoto();
		SetConditionalAppearance();
		
	ElsIf Result = "TakePhoto" Then
		
#If MobileClient Then
		BinaryData = GetSnapshotPhotoData();
		Attach_File(BinaryData);
		UploadProductPhoto();
		SetConditionalAppearance();
#Else
		Status(NStr("vi = 'Thiết bị này không hỗ trợ chụp ảnh màn hình';
					|ru = 'Данное устройство не поддерживает фотоснимок';
					|en = 'This device does not support photo capturing'; fa = 'This device does not support photo capturing';
					|it = 'This device does not support photo capturing';
					|pl = 'This device does not support photo capturing';
					|tr = 'Bu cihaz fotoğraf çekmeyi desteklemiyor'"));
#EndIf
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangePackageBarcodes(Result, Var_Parameters) Export
	
	ChangeBarcodesOfPackagesOnServer(Result);
	
EndProcedure

&AtServer
Procedure ChangeBarcodesOfPackagesOnServer(Result)
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	PackageBarcodes.Clear();
	PackageBarcodes.Load(Result.Unload());
	
EndProcedure

&AtClient
Function GetSnapshotPhotoData()
	
	Data = Undefined;
	
#If MobileClient Then 
		
	If MultimediaTools.PhotoSupported() Then
			
		Data = MultimediaTools.MakePhoto();
			
		Return Data.GetBinaryData();
			
	Else
		Status(NStr("vi = 'Thiết bị này không hỗ trợ chụp ảnh màn hình';
					|ru = 'Данное устройство не поддерживает фотоснимок';
					|en = 'This device does not support photo capturing'; fa = 'This device does not support photo capturing';
					|it = 'This device does not support photo capturing';
					|pl = 'This device does not support photo capturing';
					|tr = 'Bu cihaz fotoğraf çekmeyi desteklemiyor'"));
	EndIf;
		
#EndIf
	
	Return Data;
	
EndFunction

&AtServer
Procedure Attach_File(BinaryData)

#If Not MobileStandaloneServer Then
	
	TemporaryStorage                = PutToTempStorage(BinaryData);
	FileParameters                    = FilesOperations.FileAddingOptions();
	FileParameters.Author              = Users.CurrentUser();
	FileParameters.BaseName   = String(Products);
	FileParameters.ExtensionWithoutPoint = "jpg";
	FileParameters.FilesOwner = Products;
	FilesOperations.AppendFile(FileParameters, TemporaryStorage);
	
#EndIf

EndProcedure

&AtServerNoContext
Function ItemDataBySchool(Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.ItemDataBySchool(Barcode);
	
EndFunction

&AtServer
Function CellDataByWK(Val Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.CellDataByWK(Warehouse, Premise, Barcode);
	
EndFunction

&AtClient
Procedure CloseProductProfile(DataOfFollowingItem = Undefined, 
		NextCellData = Undefined, ScannedWKOfDocument = False)
	
	ErrorText = "";
	CloseProductProfileAtServer(ErrorText);
	
	If ValueIsFilled(ErrorText) Then
		Status(ErrorText);
		Return;
	EndIf;
	
	Structure = New Structure;
	Structure.Insert("Products", Products);
	Structure.Insert("Characteristic", Characteristic);
	Structure.Insert("Series", Series);
	Structure.Insert("Package", Package);
	Structure.Insert("NumberOfPackages", NumberOfPackages);
	Structure.Insert("Purpose", Purpose);
	Structure.Insert("LineNumber", LineNumber);
	Structure.Insert("Cell", Cell);
	Structure.Insert("Mode", Mode);
	Structure.Insert("PackageBarcodes", PackageBarcodes);
	Structure.Insert("SKU", SKU);
	Structure.Insert("DataOfFollowingItem", DataOfFollowingItem);
	Structure.Insert("NextCellData", NextCellData);
	Structure.Insert("CloseCard", ScannedWKOfDocument);

	Close(Structure);
	
EndProcedure  

&AtServer
Procedure CloseProductProfileAtServer(ErrorText)
	
	PackageIsFilledIn = Not (DataProcessors.MobileWarehouseKeeperWorkspace.GetCatalogAttributes(Package,
		"Owner") = Catalogs.PackagingGroups.BasicUnitsOfMeasure 
		And DataProcessors.MobileWarehouseKeeperWorkspace.GetCatalogAttributes(Package, 
		"MeasuredValueType") = Enums.TypesOfMeasuredValues.NumberOfPieces);
	
	If Not PackageIsFilledIn And Mode = "Receiving" And UseBinLocationWarehousing Then
		ErrorText = ErrorText + NStr("vi = 'Chỉ ra đóng gói';
									|ru = 'Укажите упаковку';
									|en = 'Specify packaging unit'; fa = 'تعیین واحد بسته‌بندی';
									|it = 'Indica imballaggio';
									|pl = 'Wskaż opakowanie';
									|tr = 'Paketleme ünitesini belirtin'");
	EndIf;
	
	If Mode = "Receiving" Or Mode = "EditingAcceptance" 
		Or Mode = "Shipment" Or Mode = "EditShipment" Or Mode = "Recalculate" Or Mode = "Move" 
		Or Mode = "EditingRecalculationShipment" Or Mode = "RecalculationShipment"
		Or Mode = "EditingRecalculationShipmentWithoutBatch"
		Or Mode = "SelectionFromShipmentCell" Or Mode = "EditingSelectionFromShipmentCell"
		Or Mode =  "SpecifyingSeries" Or Mode =  "EditingBatches" Then
	
		If UseCharacteristics And Not ValueIsFilled(Characteristic) Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = 'Hãy chỉ ra đặc tính';
													|ru = 'Укажите характеристику';
													|en = 'Specify variant'; fa = 'Specify variant';
													|it = 'Indicare caratteristica';
													|pl = 'Wskaż charaktyrystykę';
													|tr = 'Özelliği belirt'");
		EndIf;
		
		If KeepAccountingByBatch And Not ValueIsFilled(Series) Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = 'Hãy chỉ ra sê-ri';
													|ru = 'Укажите серию';
													|en = 'Specify batch'; fa = 'تعیین بچ';
													|it = 'Indicare serie';
													|pl = 'Wskaż serię';
													|tr = 'Partiyi belirt'");
		EndIf;
		
		If NumberOfPackages = 0 Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = 'Hãy chỉ ra số lượng';
													|ru = 'Укажите количество';
													|en = 'Specify quantity'; fa = 'Specify quantity';
													|it = 'Indicare quantità';
													|pl = 'Podaj ilość';
													|tr = 'Miktarı belirt'");
		EndIf;
		
		If KeepAccountingByBatch And ValueIsFilled(Series) Then
			BatchUsageSettings = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(ProductKind, "BatchUsageSettings");
			If BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then  
				PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(Package, Products);
				If NumberOfPackages > 1 Then
					MessageTemplate = NStr("vi = 'Số lượng được chỉ định của hàng hóa  với sê-ri ""%1"" bằng %2. Chính sách ghi nhận sê-ri của hàng hóa này quy định rằng, số lượng theo sê-ri bất kỳ của hàng hóa này sẽ luôn bằng 1.';
											|ru = 'Указанное количество товара с серией ""%1"" равно %2. Политика учета серий данного товара предусматривает, что количество по любой серии этого товара всегда будет равно 1.';
											|en = 'The specified quantity of the item with batch ""%1"" is equal to %2. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.'; fa = 'The specified quantity of the item with batch ""%1"" is equal to %2. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
											|it = 'The specified quantity of the item with batch ""%1"" is equal to %2. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
											|pl = 'The specified quantity of the item with batch ""%1"" is equal to %2. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
											|tr = '""%1"" partisine sahip ürünün belirtilen miktarı %2 değerindedir. Bu ürün için toplu muhasebe politikası, bu ürünün herhangi bir partisi için miktarın her zaman 1 olacağını öngörür.'");
					MessageText = StrTemplate(MessageTemplate, Series, Format(NumberOfPackages, "NZ=0; NG="));		
					ErrorText = ErrorText + Chars.LF + MessageText; 
				ElsIf PackagingFactor <> 1 Then
					MessageText = NStr("vi = 'Chính sách kế toán sê-ri của hàng hóa quy định rằng, sê-ri được chỉ định đối với mỗi mặt hàng. Hãy chỉ định bộ đóng gói riêng.';
										|ru = 'Политика учета серий товара предусматривает, что серии указываются для каждого экземпляра. Укажите единичную упаковку.';
										|en = 'According to the batch accounting policy of the item, batches are specified for each item. Specify a single packaging unit.'; fa = 'According to the batch accounting policy of the item, batches are specified for each item. Specify a single packaging unit.';
										|it = 'According to the batch accounting policy of the item, batches are specified for each item. Specify a single packaging unit.';
										|pl = 'According to the batch accounting policy of the item, batches are specified for each item. Specify a single packaging unit.';
										|tr = 'Toplu muhasebe politikası, her ürün için partilerin belirtilmesini şart koşmaktadır. Birim paketleme ünitesini belirtin.'");
					ErrorText = ErrorText + Chars.LF + MessageText; 
				EndIf;
			EndIf;
		EndIf;
		
		If (Mode = "SelectionFromShipmentCell" Or Mode = "Recalculate") And Not ValueIsFilled(Cell) 
			And UseBinLocationWarehousing And ScanningProcedure = "FirstScanCell" Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = 'Hãy chỉ ra ô hàng';
													|ru = 'Укажите ячейку';
													|en = 'Specify a storage bin'; fa = 'Specify a storage bin';
													|it = 'Specificare la cella';
													|pl = 'Wskaż komórkę';
													|tr = 'Hücre belirt'");
		EndIf;
		
	EndIf;
	
	If Mode = "PlacementInCell" And Not ValueIsFilled(Cell) 
		And ScanningProcedure = "FirstScanCell" Then
		ErrorText = ErrorText + Chars.LF + NStr("vi = 'Hãy chỉ ra ô hàng';
												|ru = 'Укажите ячейку';
												|en = 'Specify a storage bin'; fa = 'Specify a storage bin';
												|it = 'Specificare la cella';
												|pl = 'Wskaż komórkę';
												|tr = 'Hücre belirt'");
	EndIf;
	
	If Not StampsWereScannedServer() Then
		
		ErrorText = ErrorText + Chars.LF + NStr("vi = 'Hãy chỉ ra mã dán nhãn';
												|ru = 'Укажите коды маркировки';
												|en = 'Specify marking codes'; fa = 'Specify marking codes';
												|it = 'Indicare i codici di marcatura';
												|pl = 'Podaj koda oznakowania';
												|tr = 'İşaretleme kodu belirt'");
		
	EndIf;
	
EndProcedure

&AtServer
Function GetSeriesParametersOnServer(Val Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.GetParametersOfSeriesByWK(Barcode, ProductKind);
	
EndFunction

&AtClient
Procedure CountOnChange(Item)
	
	If NumberOfPackages < 0 Then
		NumberOfPackages = 0;
		Status(NStr("vi = 'Không thể chỉ ra giá trị âm';
					|ru = 'Нельзя указать отрицательное значение';
					|en = 'Negative values are not allowed'; fa = 'Negative values are not allowed';
					|it = 'Negative values are not allowed';
					|pl = 'Negative values are not allowed';
					|tr = 'Negatif değer belirtilemez'"));
	EndIf;
	
EndProcedure

&AtServer
Function StampsWereScannedServer()
	
	StampsWereScanned = DataProcessors.MobileWarehouseKeeperWorkspace.StampsWereScanned(Products, NumberOfPackages, Package, PackageBarcodes);
	Return StampsWereScanned;
	
EndFunction

&AtClient
Procedure SeriesSelection_3(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Series = Result;
	
EndProcedure

&AtClient
Procedure SeriesCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CreatingSeries();
	
EndProcedure

&AtClient
Procedure CreateSeries(Command)
	
	CreatingSeries();
	
EndProcedure

&AtClient
Procedure CreatingSeries()
	
	Filter = New Structure();
	Filter.Insert("ProductKind", ProductKind);
	
	FormParameters = New Structure();
	FormParameters.Insert("FillingValues",Filter);
	FormParameters.Insert("ExpirationDate_", ExpirationDate_);
	
	OpenForm("Catalog.ItemsBatches.Form.ItemForm", FormParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure FillInLinksOfDestinationSelectionParameters()
	
	ChoiceParameterLinks = New Array();
	ChoiceParameters = New Array();
	
	If Mode = "Shipment" Or Mode = "EditShipment" 
		Or Mode = "RecalculationShipment" Or Mode = "EditingRecalculationShipment" 
		Or Mode = "Recalculate" Or Mode = "EditingRecalculation" Then
		
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Products", "Products", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Characteristic", "Characteristic", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Warehouse", "Warehouse", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Source", "DocumentSource", LinkedValueChangeMode.Clear));
		
		ChoiceParameters.Add(New ChoiceParameter("Filter.RecordsInWarehouseRegisters", True));
		
	ElsIf Mode = "Receiving" Or Mode = "EditingAcceptance" Then
		
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Products", "Products", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Characteristic", "Characteristic", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Warehouse", "Warehouse", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Source", "DocumentSource", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("ReferenceOrder", "ReceiptReferenceOrder", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("OperationKind", "WarehouseOperation", LinkedValueChangeMode.DontChange));
		
		ChoiceParameters.Add(New ChoiceParameter("WarehouseAssignmentsOnly", True));
		SelectionOptions = New Array;
		SelectionOptions.Add(0);
		SelectionOptions.Add(5);
		ChoiceParameters.Add(New ChoiceParameter("SelectionOptions", New FixedArray(SelectionOptions)));
		
	ElsIf Mode = "PlacementInCell" Or Mode = "EditingPlacementByCells" Then
		
		OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location;
		
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Products", "Products", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Characteristic", "Characteristic", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Warehouse", "Warehouse", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Source", "DocumentSource", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Cell", "Cell", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("OperationKind", "OperationKind", LinkedValueChangeMode.DontChange));
		
		ChoiceParameters.Add(New ChoiceParameter("Filter.RecordsInWarehouseRegisters", True));
		
	ElsIf Mode = "Move" Then
		
		OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move;
		
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Products", "Products", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Characteristic", "Characteristic", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Warehouse", "Warehouse", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Source", "DocumentSource", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Cell", "Cell", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("OperationKind", "OperationKind", LinkedValueChangeMode.DontChange));
		
		ChoiceParameters.Add(New ChoiceParameter("Filter.RecordsInWarehouseRegisters", True));
		
	ElsIf Mode = "SelectionFromCell" Or Mode = "EditingSelectionFromCell" 
		Or Mode = "SelectionFromShipmentCell" Or Mode = "EditingSelectionFromShipmentCell" Then
		
		OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter;
		
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Products", "Products", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Characteristic", "Characteristic", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Warehouse", "Warehouse", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Source", "DocumentSource", LinkedValueChangeMode.Clear));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Cell", "Cell", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("OperationKind", "OperationKind", LinkedValueChangeMode.DontChange));
		ChoiceParameterLinks.Add(New ChoiceParameterLink("ReferenceOrder", "SelectionOrder_", LinkedValueChangeMode.DontChange));
		
		ChoiceParameters.Add(New ChoiceParameter("Filter.RecordsInWarehouseRegisters", True));
		ChoiceParameters.Add(New ChoiceParameter("DestinationSelectionMode", "ResiduesInCell"));
		
	EndIf;
	
	Items.Purpose.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	Items.Purpose.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

&AtClient
Procedure CharacteristicStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("Products", Products);
	
	SelectItemVariant = New CallbackDescription("SelectItemVariant", ThisObject);
	If UsedFormServer = UsedServer.Main Then
		OpenForm("Catalog.ItemsCharacteristics.Form.ChoiceForm", FormParameters, ThisObject,,,, SelectItemVariant);
	Else
		OpenForm("Catalog.ItemsCharacteristics.Form.FormOfSelectionOfflineMode", FormParameters, ThisObject,,,, SelectItemVariant);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectItemVariant(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Characteristic = Result;
	
EndProcedure

#EndRegion