#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("FillingStructure") Then
		
		FillingStructure = Parameters.FillingStructure;
		
		ReceiptReferenceOrder = FillingStructure.ReferenceOrder;
		ControlledLotReference = FillingStructure.ControlledLotReference;
		If Not CreateIncomingOrder(FillingStructure) Then
			Cancel = True;
			Return;
		EndIf;
		
	Else
		Ref = Parameters.Ref;
#If Not MobileStandaloneServer Then
		FilledInAttributes = Common.ObjectAttributesValues(Ref,
			"ReferenceOrder,ControlledLotReference");
		ReceiptReferenceOrder = FilledInAttributes.ReferenceOrder;
		ControlledLotReference = FilledInAttributes.ControlledLotReference;
#Else
		ReceiptReferenceOrder = Parameters.Ref.ReferenceOrder;
#EndIf

	EndIf;
	
	ShowProductPhotos = Parameters.ShowProductPhotos;
	Barcode = Parameters.Barcode;
	ScanningProcedure = Parameters.ScanningProcedure;

	FillForm();
	

	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CreateMenu_("ToReceive");
	
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
Procedure GoToAcceptanceSection(Command)
	CreateMenu_("ToReceive");
EndProcedure

&AtClient
Procedure GoToAcceptedSection(Command)
	CreateMenu_("Accepted");
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
	FormParameters.Insert("Mode", "Receiving");
	FormParameters.Insert("LineNumber", Item.CurrentRow);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("ReceiptReferenceOrder", ReceiptReferenceOrder);
	FormParameters.Insert("WarehouseOperation", WarehouseOperation);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure ProductsAcceptedSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("Mode", "EditingAcceptance");
	FormParameters.Insert("LineNumber", ProductsAccepted.IndexOf(Items.ProductsAccepted.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("ReceiptReferenceOrder", ReceiptReferenceOrder);
	FormParameters.Insert("WarehouseOperation", WarehouseOperation);

	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);

EndProcedure

&AtClient
Procedure FinishAcceptance(Command)
	
	If Not UseGoodsReceiptNoteStatuses And ProductsAccepted.Count() = 0 Then   		
		Status(NStr("vi = 'Không thể hoàn thành việc nhập hàng khi chưa có hàng hóa nào được nhập.';
					|ru = 'Не возможно закончить приемку, пока не принято ни одного товара.';
					|en = 'Cannot finish the receipt until at least one item is received.'; fa = 'Cannot finish the receipt until at least one item is received.';
					|it = 'Cannot finish the receipt until at least one item is received.';
					|pl = 'Cannot finish the receipt until at least one item is received.';
					|tr = 'Hiçbir ürün kabul edilmeden kabul işlemi tamamlanamaz.'"));	
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
	ShowQueryBox(Notification, NStr("vi = 'Kết thúc nhập hàng?';
									|ru = 'Завершить приемку?';
									|en = 'Finish goods receipt?'; fa = 'Finish goods receipt?';
									|it = 'Terminare l''accettazione?';
									|pl = 'Zakończyć przyjęcie?';
									|tr = 'Kabulü tamamla?'"), ValueList, 0);
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)

	UpdateAcceptanceZoneBinLocationSystem();

EndProcedure

&AtClient
Procedure CollectEverything(Command)
	Notification = New CallbackDescription("AfterClosingQuestionCollectAll", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Thẻ Đã tiếp nhận sẽ bị xóa, tiếp tục?';
									|ru = 'Вкладка Принято будет очищена, продолжить?';
									|en = 'The Received tab will be cleared. Continue?'; fa = 'The Received tab will be cleared. Continue?';
									|it = 'Вкладка Принято будет очищена, продолжить?';
									|pl = 'The Received tab will be cleared. Continue?';
									|tr = 'Kabul edildi sekmesi temizlenecek, devam edilsin mi?'"),QuestionDialogMode.YesNo,0);
EndProcedure

&AtClient
Procedure Scan(Command)

	LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "ProductItemsSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("DocumentRef", Ref);
	FormParameters.Insert("PackageBarcodes", PackageBarcodes);
	FormParameters.Insert("Organization", Organization);
	
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
Procedure CancelAcceptance(Command)
	
	RowIndex = ProductsAccepted.IndexOf(Items.ProductsAccepted.CurrentData);
	If RowIndex >= 0 Then
		ProductsAccepted.Delete(RowIndex);
	EndIf;
	
	GenerateMenuCommandHeaders();
	
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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Items.Premise.Visible      = UseWarerooms;
	Items.ReceivingArea.Visible    = UseBinLocationWarehousing;
	Items.MarkingCodes.Visible = UseAccountingOfLabeledProducts And ThereAreLabeledProducts;
	Items.InformationAboutSender.Visible   = (TypeOf(Sender) = Type("CatalogRef.Partners") Or TypeOf(Sender) = Type("CatalogRef.Persons"));
	
#If MobileStandaloneServer Then
	Items.CollectEverything.Visible = False;
	Items.FormCancelOrderAcceptance.Visible = False;
#Else
	Status = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Ref, "Status");
	If Status = Enums.GoodsReceiptNoteStatuses.ToReceive And AccessRight("InteractiveSetDeletionMark", Metadata.Documents.GoodsReceiptNote) Then
		Items.FormCancelOrderAcceptance.Visible = True;
	Else
		Items.FormCancelOrderAcceptance.Visible = False;
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
		If Status = PredefinedValue("Enum.GoodsReceiptNoteStatuses.Accepted")
			And UseBinLocationWarehousing Then

			PlacementTasks = OrderTaskData();
			DocumentScanResult(PlacementTasks);

		ElsIf UseBinLocationWarehousing Then
			FinishAcceptanceOnClient(False);
		Else
			FinishAcceptanceOnClient(True);
		EndIf;
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

&AtServer
Function OrderTaskData()

	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Warehouse", Warehouse);
	TheStructureOfTheSearch.Insert("Premise", Premise);
	TheStructureOfTheSearch.Insert("ReceivingArea", ReceivingArea);
	TheStructureOfTheSearch.Insert("DateFromOrder", Date);
	TheStructureOfTheSearch.Insert("Direction", "Receiving");

	Return DataProcessors.MobileWarehouseKeeperWorkspace.OrderTaskData(TheStructureOfTheSearch);

EndFunction

&AtClient
Procedure DocumentScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	LongDesc = New CallbackDescription("CloseForm", ThisObject);

	If ValueIsFilled(Result.References) And ValueIsFilled(Result.Mode) Then

		LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);

		FormParameters = New Structure;
		FormParameters.Insert("ScanningResult", Result);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ScanSelectionForm", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.LockWholeInterface);

	ElsIf ValueIsFilled(Result.References) And Not ValueIsFilled(Result.Mode) Then

		FormParameters = New Structure;
		FormParameters.Insert("Ref", Result.References[0]);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PutAwayToStorageBins", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);

	Else

		StructureOfNewPlacement = NewPlacementOfItems();

		If ValueIsFilled(StructureOfNewPlacement.CheckErrorText) Then
			Status(StructureOfNewPlacement.CheckErrorText);
		EndIf;

		If Not ValueIsFilled(StructureOfNewPlacement.Ref) Then
			Return;
		EndIf;

		FormParameters = New Structure;
		FormParameters.Insert("Ref", StructureOfNewPlacement.Ref);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Strikehod", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PutAwayToStorageBins", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);

	EndIf;

EndProcedure

&AtServer
Function NewPlacementOfItems()

	PlacementParameters = DataProcessors.MobileWarehouseKeeperWorkspace.ParametersForCreatingItemPlacement();
	PlacementParameters.Warehouse = Warehouse;
	PlacementParameters.Premise = Premise;
	PlacementParameters.Performer = Performer;
	PlacementParameters.ReceivingArea = ReceivingArea;
	PlacementParameters.ProductsTable =  ProductsAccepted.Unload();

	StructureOfNewPlacement = DataProcessors.MobileWarehouseKeeperWorkspace.NewPlacementOfItems(PlacementParameters);

	Return StructureOfNewPlacement;

EndFunction

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
		FormParameters.Insert("PackageBarcode", ProductData_8.PackageBarcode);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("DocumentBarcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		FormParameters.Insert("Source", Ref);
		FormParameters.Insert("ReceiptReferenceOrder", ReceiptReferenceOrder);
		FormParameters.Insert("WarehouseOperation", WarehouseOperation);

		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);

	EndIf;

EndProcedure

&AtServer
Function CreateIncomingOrder(FillingStructure)
	
#If Not MobileStandaloneServer Then

	NewWarrant = Documents.GoodsReceiptNote.CreateDocument();
	
	NewWarrant.Fill(FillingStructure);
	NewWarrant.Date = CurrentSessionDate();
	NewWarrant.Performer = MobileWarehouseKeeperWorkspace.CurrentUser();
	
	SeriesSpecificationParameters = Documents.GoodsReceiptNote.SeriesSpecificationParameters(NewWarrant);
	MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(NewWarrant, SeriesSpecificationParameters);
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(NewWarrant);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(NewWarrant.Goods, StructureOfActions);
	
	If NewWarrant.Goods.Count() = 0 Then
		Return False;
	EndIf;
		
	NewWarrant.Write(DocumentWriteMode.Write);
	
	Warehouse       = NewWarrant.Warehouse;
	Premise   = NewWarrant.Premise;
	Performer = NewWarrant.Performer;
	
	Ref = NewWarrant.Ref;
	
	Return True;

#Else

	Return False;

#EndIf
	
EndFunction

&AtClient
Procedure CreateMenu_(TabName)
	
	ShowMenu();
	
	Items.FrameForAdmission.Picture = PictureLib.BorderMenuWhite;
	Items.AdmissionCommand.TextColor = WebColors.DarkGray;
	
	Items.FrameAccepted.Picture = PictureLib.BorderMenuWhite;
	Items.CommandAccepted.TextColor = WebColors.DarkGray;
	
	If TabName = "ToReceive" Then
		Items.FrameForAdmission.Picture = PictureLib.BorderMenuBlack;
		Items.AdmissionCommand.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PageToReceive;
	ElsIf TabName = "Accepted" Then
		Items.FrameAccepted.Picture = PictureLib.BorderMenuBlack;
		Items.CommandAccepted.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.AcceptedPage;
	EndIf;
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtServer
Procedure GenerateMenuCommandHeaders()
	Items.AdmissionCommand.Title = StrTemplate(NStr("vi = 'Cần nhập hàng (%1)';
													|ru = 'К приемке (%1)';
													|en = 'To receive (%1)'; fa = 'To receive (%1)';
													|it = 'In accettazione (%1)';
													|pl = 'Do przyjęcia (%1)';
													|tr = 'Kabul edilecek (%1)'"), GoodsToReceive.Count());
	Items.CommandAccepted.Title = StrTemplate(NStr("vi = 'Đã tiếp nhận (%1)';
													|ru = 'Принято (%1)';
													|en = 'Received (%1)'; fa = 'Received (%1)';
													|it = 'Ricevuto (%1)';
													|pl = 'Przyjęto (%1)';
													|tr = 'Kabul edildi (%1)'"), ProductsAccepted.Count());
EndProcedure

&AtServer
Procedure FillForm()
	
#If Not MobileStandaloneServer Then

	Query = New Query;
	Query.Text = 
		"SELECT
		|	GoodsReceiptNote.Number AS Number,
		|	GoodsReceiptNote.Date AS Date,
		|	GoodsReceiptNote.Status AS Status,
		|	GoodsReceiptNote.Warehouse AS Warehouse,
		|	GoodsReceiptNote.Performer AS Performer,
		|	GoodsReceiptNote.Comment AS Comment,
		|	GoodsReceiptNote.Premise AS Premise,
		|	GoodsReceiptNote.ReceivingArea AS ReceivingArea,
		|	GoodsReceiptNote.IncomingDocumentDate AS IncomingDocumentDate,
		|	GoodsReceiptNote.IncomingDocumentNumber AS IncomingDocumentNumber,
		|	GoodsReceiptNote.Sender AS Sender,
		|	GoodsReceiptNote.WarehouseOperation AS WarehouseOperation,
		|	GoodsReceiptNote.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt AS UseWarehouseManagemantSystemForGoodsReceipt,
		|	GoodsReceiptNote.Warehouse.UseGoodsReceiptNoteStatuses AS UseGoodsReceiptNoteStatuses,
		|	GoodsReceiptNote.Warehouse.UseWarerooms AS UseWarerooms,
		|	CASE
		|		WHEN GoodsReceiptNote.Warehouse.UseWarerooms
		|			THEN GoodsReceiptNote.Premise.UseBinLocationWarehousing
		|		ELSE GoodsReceiptNote.Warehouse.UseBinLocationWarehousing
		|	END AS UseBinLocationWarehousing
		|FROM
		|	Document.GoodsReceiptNote AS GoodsReceiptNote
		|WHERE
		|	GoodsReceiptNote.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReceiptOrderForGoodsGoods.Products AS Products,
		|	ReceiptOrderForGoodsGoods.Products.SKU AS SKU,
		|	ReceiptOrderForGoodsGoods.Characteristic AS Characteristic,
		|	ReceiptOrderForGoodsGoods.Purpose AS Purpose,
		|	ReceiptOrderForGoodsGoods.Package AS Package,
		|	ReceiptOrderForGoodsGoods.NumberOfPackages AS NumberOfPackages,
		|	ReceiptOrderForGoodsGoods.Count AS Count,
		|	ReceiptOrderForGoodsGoods.Series AS Series
		|INTO TTProducts_1
		|FROM
		|	Document.GoodsReceiptNote.Goods AS ReceiptOrderForGoodsGoods
		|WHERE
		|	ReceiptOrderForGoodsGoods.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTProducts_1.Products AS Products,
		|	TTProducts_1.SKU AS SKU,
		|	TTProducts_1.Characteristic AS Characteristic,
		|	TTProducts_1.Purpose AS Purpose,
		|	TTProducts_1.Package AS Package,
		|	TTProducts_1.NumberOfPackages AS NumberOfPackages,
		|	TTProducts_1.Count AS Count,
		|	TTProducts_1.Series AS Series
		|FROM
		|	TTProducts_1 AS TTProducts_1
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTProducts_1.Products AS Products,
		|	TTProducts_1.SKU AS SKU,
		|	TTProducts_1.Characteristic AS Characteristic,
		|	TTProducts_1.Purpose AS Purpose,
		|	TTProducts_1.Package AS Package,
		|	TTProducts_1.NumberOfPackages AS NumberOfPackages,
		|	TTProducts_1.Count AS Count,
		|	TTProducts_1.Series AS Series
		|FROM
		|	TTProducts_1 AS TTProducts_1
		|WHERE
		|	TTProducts_1.Count > 0";
	
	Columns = PackageBarcodes.Unload().Columns;
	If Columns.PackageBarcode.ValueType.ContainsType(Type("String")) Then
		
		Query.Text = Query.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsReceiptNotePackageBarcodes.PackageBarcode AS PackageBarcode
		|FROM
		|	Document.GoodsReceiptNote.PackageBarcodes AS GoodsReceiptNotePackageBarcodes
		|WHERE
		|	GoodsReceiptNotePackageBarcodes.Ref = &Ref";
		
	Else
		
		Query.Text = Query.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsReceiptNotePackageBarcodes.PackageBarcode AS PackageBarcode,
		|	GoodsReceiptNotePackageBarcodes.PackageBarcode.Products AS Products,
		|	GoodsReceiptNotePackageBarcodes.PackageBarcode.Characteristic AS Characteristic
		|FROM
		|	Document.GoodsReceiptNote.PackageBarcodes AS GoodsReceiptNotePackageBarcodes
		|WHERE
		|	GoodsReceiptNotePackageBarcodes.Ref = &Ref";
		
	EndIf;
	
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	Selection.Next();
	FillPropertyValues(ThisObject, Selection);
	GoodsToReceive.Load(QueryResult[2].Unload());
	ProductsAccepted.Load(QueryResult[3].Unload());
	PackageBarcodes.Load(QueryResult[4].Unload());

#Else

	Query = New Query;
	Query.Text =
		"SELECT
		|	GoodsReceiptNote.Number AS Number,
		|	GoodsReceiptNote.Date AS Date,
		|	GoodsReceiptNote.Warehouse AS Warehouse,
		|	GoodsReceiptNote.Performer AS Performer,
		|	GoodsReceiptNote.Comment AS Comment,
		|	GoodsReceiptNote.Premise AS Premise,
		|	GoodsReceiptNote.ReceivingArea AS ReceivingArea,
		|	GoodsReceiptNote.IncomingDocumentDate AS IncomingDocumentDate,
		|	GoodsReceiptNote.IncomingDocumentNumber AS IncomingDocumentNumber,
		|	GoodsReceiptNote.Sender AS Sender,
		|	GoodsReceiptNote.WarehouseOperation AS WarehouseOperation,
		|	GoodsReceiptNote.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt AS UseWarehouseManagemantSystemForGoodsReceipt,
		|	CASE
		|		WHEN GoodsReceiptNote.Warehouse.UseWarerooms
		|			THEN GoodsReceiptNote.Premise.UseBinLocationWarehousing
		|		ELSE GoodsReceiptNote.Warehouse.UseBinLocationWarehousing
		|	END AS UseBinLocationWarehousing
		|FROM
		|	Document.GoodsReceiptNote AS GoodsReceiptNote
		|WHERE
		|	GoodsReceiptNote.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReceiptOrderForGoodsGoods.Products AS Products,
		|	ReceiptOrderForGoodsGoods.Products.SKU AS SKU,
		|	ReceiptOrderForGoodsGoods.Characteristic AS Characteristic,
		|	ReceiptOrderForGoodsGoods.Purpose AS Purpose,
		|	ReceiptOrderForGoodsGoods.Package AS Package,
		|	ReceiptOrderForGoodsGoods.NumberOfPackages AS NumberOfPackages,
		|	ReceiptOrderForGoodsGoods.Count AS Count,
		|	ReceiptOrderForGoodsGoods.Series AS Series
		|INTO TTProducts_1
		|FROM
		|	Document.GoodsReceiptNote.Goods AS ReceiptOrderForGoodsGoods
		|WHERE
		|	ReceiptOrderForGoodsGoods.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTProducts_1.Products AS Products,
		|	TTProducts_1.SKU AS SKU,
		|	TTProducts_1.Characteristic AS Characteristic,
		|	TTProducts_1.Purpose AS Purpose,
		|	TTProducts_1.Package AS Package,
		|	TTProducts_1.NumberOfPackages AS NumberOfPackages,
		|	TTProducts_1.Count AS Count,
		|	TTProducts_1.Series AS Series
		|FROM
		|	TTProducts_1 AS TTProducts_1
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTProducts_1.Products AS Products,
		|	TTProducts_1.SKU AS SKU,
		|	TTProducts_1.Characteristic AS Characteristic,
		|	TTProducts_1.Purpose AS Purpose,
		|	TTProducts_1.Package AS Package,
		|	TTProducts_1.NumberOfPackages AS NumberOfPackages,
		|	TTProducts_1.Count AS Count,
		|	TTProducts_1.Series AS Series
		|FROM
		|	TTProducts_1 AS TTProducts_1
		|WHERE
		|	TTProducts_1.Count > 0";

	Query.SetParameter("Ref", Ref);

	QueryResult = Query.ExecuteBatch();

	Selection = QueryResult[0].Select();
	Selection.Next();
	FillPropertyValues(ThisObject, Selection);
	GoodsToReceive.Load(QueryResult[2].Unload());
	ProductsAccepted.Load(QueryResult[3].Unload());

#EndIf

	If ValueIsFilled(IncomingDocumentNumber) And ValueIsFilled(IncomingDocumentDate) Then
		DocumentInformation = StrTemplate(NStr("vi = 'Số %1 ngày %2, %3';
												|ru = '№ %1 от %2, %3';
												|en = '%1 dated %2, %3'; fa = '%1 dated %2, %3';
												|it = '%1 dated %2, %3';
												|pl = '%1 dated %2, %3';
												|tr = '%2 tarihli %1 numaralı, %3'"),
			IncomingDocumentNumber, Format(IncomingDocumentDate, NStr("vi = 'DF=''dd.ММ.yyy HH:mm''';
																		|ru = 'ДФ=''дд.ММ.гг ЧЧ:мм''';
																		|en = 'DF=''MM/dd/yy hh:mm tt'''; fa = 'DF=''MM/dd/yy hh:mm tt''';
																		|it = 'D F ''=gg.ММ.aa 00:mm''';
																		|pl = 'DF=''dd.MM.yy HH:mm''';
																		|tr = 'DF=''dd.MM.yy HH:mm'''")), Status);
	Else
		DocumentInformation = StrTemplate(NStr("vi = 'Số %1 ngày %2, %3';
												|ru = '№ %1 от %2, %3';
												|en = '%1 dated %2, %3'; fa = '%1 dated %2, %3';
												|it = '%1 dated %2, %3';
												|pl = '%1 dated %2, %3';
												|tr = '%2 tarihli %1 numaralı, %3'"),
			ObjectsPrefixesClientServer.NumberForPrinting(Number), Format(Date, NStr("vi = 'DF=''dd.ММ.yyy HH:mm''';
																					|ru = 'ДФ=''дд.ММ.гг ЧЧ:мм''';
																					|en = 'DF=''MM/dd/yy hh:mm tt'''; fa = 'DF=''MM/dd/yy hh:mm tt''';
																					|it = 'D F ''=gg.ММ.aa 00:mm''';
																					|pl = 'DF=''dd.MM.yy HH:mm''';
																					|tr = 'DF=''dd.MM.yy HH:mm'''")), Status);
	EndIf;

EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateFormOnServer(Result);
	If ValueIsFilled(Result.DataOfFollowingItem) Then
		ResultOfScanningItem(Result.DataOfFollowingItem);
	EndIf;

EndProcedure

&AtServer
Procedure UpdateFormOnServer(Result)

	PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(Result.Package, Result.Products);
	
	If Result.Mode = "EditingAcceptance" Then
		
		Literal = "LineNumber";
		LineNumber = Result[Literal];
		
		ProductsAccepted[LineNumber].Package           = Result.Package;
		ProductsAccepted[LineNumber].NumberOfPackages = Result.NumberOfPackages;
		ProductsAccepted[LineNumber].Count         = ProductsAccepted[LineNumber].NumberOfPackages * PackagingFactor;
		ProductsAccepted[LineNumber].Series              = Result.Series;
		ProductsAccepted[LineNumber].Purpose         = Result.Purpose;
		
	Else
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products", Result.Products);
		TheStructureOfTheSearch.Insert("Characteristic", Result.Characteristic);
		TheStructureOfTheSearch.Insert("Series", Result.Series);
		TheStructureOfTheSearch.Insert("Package", Result.Package);
		TheStructureOfTheSearch.Insert("Purpose", Result.Purpose);
		
		SearchResult = ProductsAccepted.FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() > 0 Then
			SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages + Result.NumberOfPackages;
			SearchResult[0].Count = SearchResult[0].NumberOfPackages * PackagingFactor;
		Else
			NewRow = ProductsAccepted.Add();
			FillPropertyValues(NewRow, Result);
			NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
		EndIf;
		
	EndIf;
	
	For Each LineMarkingCode In Result.PackageBarcodes Do
		
		NewRow = PackageBarcodes.Add();
		FillPropertyValues(NewRow, LineMarkingCode);
		
	EndDo;
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure FinishAcceptanceOnClient(Close)

	AcceptanceIsComplete = FinishAcceptanceOnServer();

	If AcceptanceIsComplete And Close Then
		Close();
	ElsIf Not AcceptanceIsComplete Then
		Status(ErrorText);
	Else
		FillForm();
		GenerateMenuCommandHeaders();
	EndIf;

EndProcedure

&AtServer
Function FinishAcceptanceOnServer()
	
	OrderObject_ = Ref.GetObject();
	
	OrderObject_.Premise               = Premise;
	OrderObject_.Comment             = Comment;
	OrderObject_.ReceivingArea             = ReceivingArea;
	OrderObject_.Performer             = Performer;
	OrderObject_.IncomingDocumentNumber = IncomingDocumentNumber;
	OrderObject_.IncomingDocumentDate  = IncomingDocumentDate;
	
	If UseWarerooms And Not ValueIsFilled(Premise) Then

		ErrorText = NStr("vi = 'Chưa chọn nhà kho';
						|ru = 'Не выбрано помещение';
						|en = 'Wareroom is not selected'; fa = 'Wareroom is not selected';
						|it = 'Locale non selezionato';
						|pl = 'Nie wybrano pomieszczenia';
						|tr = 'Alan seçilmedi'");
		Items.GroupPages.CurrentPage = Items["InformationPage"];
		Return False;
		
	EndIf;
	
	If UseBinLocationWarehousing And Not ValueIsFilled(ReceivingArea) Then

		ErrorText = NStr("vi = 'Chưa chọn khu vực nhập hàng';
						|ru = 'Не выбрана зона приемки';
						|en = 'Inbound area is not selected'; fa = 'Inbound area is not selected';
						|it = 'Zona di accettazione non selezionata';
						|pl = 'Nie wybrano strefy przyjęcia';
						|tr = 'Boşaltma alanı seçilmedi'");
		Items.GroupPages.CurrentPage = Items["InformationPage"];
		Return False;
		
	EndIf;
	
	// We do not carry out the document if the packages are not specified
	ArrayOfMessages = New Array;
	If UseBinLocationWarehousing Then
		For Each String In ProductsAccepted Do
			
			If Not ValueIsFilled(String.Package)
				Or (MobileWarehouseKeeperWorkspace.ObjectAttributeValue(String.Package, "Owner") = Catalogs.PackagingGroups.BasicUnitsOfMeasure
				And MobileWarehouseKeeperWorkspace.ObjectAttributeValue(String.Package, "MeasuredValueType") = Enums.TypesOfMeasuredValues.NumberOfPieces) Then
				
				MessageText = String(String.Products);
				
				If ValueIsFilled(String.Characteristic) Then
					MessageText = MessageText + Chars.LF + String(String.Characteristic);
				EndIf;
				
				If ValueIsFilled(String.Series) Then
					MessageText = MessageText + Chars.LF + String(String.Series);
				EndIf;
				
				ArrayOfMessages.Add(MessageText);
				
			EndIf;
			
		EndDo;
	EndIf;
	
	If ArrayOfMessages.Count() > 0 Then

		MessageText = NStr("vi = 'Hãy chỉ ra đóng gói cho mục:';
							|ru = 'Укажите упаковки для позиций:';
							|en = 'Specify packaging units for the items:'; fa = 'Specify packaging units for the items:';
							|it = 'Укажите упаковки для позиций:';
							|pl = 'Specify packaging units for the items:';
							|tr = 'Pozisyonlar için paketleme ünitelerini belirtin:'");
		For Each EmailMessages In ArrayOfMessages Do
			MessageText = MessageText + Chars.LF + EmailMessages;
		EndDo;
		ErrorText = MessageText;
		Return False;

	EndIf;
	
	For Each String In ProductsAccepted Do
		
		ProductKind    = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(String.Products, "ProductKind");
		BatchAccountingPolicy = DataProcessors.MobileWarehouseKeeperWorkspace.BatchAccountingPolicy(ProductKind, Warehouse);
		If ValueIsFilled(BatchAccountingPolicy) Then
			KeepAccountingByBatch = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(BatchAccountingPolicy, "SpecifyOnReceiving");
		Else
			KeepAccountingByBatch = False;
		EndIf;
			
		If Not ValueIsFilled(String.Series) And (ValueIsFilled(KeepAccountingByBatch) And KeepAccountingByBatch) Then
			
			MessageText = String(String.Products);
			
			If ValueIsFilled(String.Characteristic) Then
				MessageText = MessageText + Chars.LF + String(String.Characteristic);
			EndIf;
			
			ArrayOfMessages.Add(MessageText);
			
		EndIf;
		
	EndDo;
	
	If ArrayOfMessages.Count() > 0 Then

		MessageText = NStr("vi = 'Hãy chỉ ra sê-ri cho mục:';
							|ru = 'Укажите серии для позиций:';
							|en = 'Specify batches for the items:'; fa = 'Specify batches for the items:';
							|it = 'Укажите серии для позиций:';
							|pl = 'Specify batches for the items:';
							|tr = 'Pozisyonlar için partileri belirtin:'");
		For Each EmailMessages In ArrayOfMessages Do
			MessageText = MessageText + Chars.LF + EmailMessages;
		EndDo;
		ErrorText = MessageText;
		Return False;

	EndIf;
	
	If ProductsAccepted.Count() <> 0 Then
		OrderObject_.Goods.Clear();
		OrderObject_.Status = Enums.GoodsReceiptNoteStatuses.Accepted;
	Else
		OrderObject_.Status = Enums.GoodsReceiptNoteStatuses.ToReceive;
	EndIf;
	
	For Each String In ProductsAccepted Do
		
		NewRow = OrderObject_.Goods.Add();
		FillPropertyValues(NewRow, String);
		
	EndDo;
	
#If Not MobileStandaloneServer Then
	OrderObject_.PackageBarcodes.Clear();
	For Each StringBC In PackageBarcodes Do
		
		NewRow = OrderObject_.PackageBarcodes.Add();
		NewRow.PackageBarcode = StringBC.PackageBarcode;
		
	EndDo;
	
	SeriesSpecificationParameters = Documents.GoodsReceiptNote.SeriesSpecificationParameters(OrderObject_);
	ProductsServer.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters);

	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(OrderObject_);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(OrderObject_.Goods, StructureOfActions);
#Else

	SeriesSpecificationParameters = Documents.GoodsReceiptNote.SeriesSpecificationParameters(OrderObject_);
	MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters);
#EndIf

	Try
		OrderObject_.Write(DocumentWriteMode.Posting);
	Except
		OrderObject_.Write(DocumentWriteMode.Write);
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
		CreateMenu_("Accepted");
	EndIf;
	
EndProcedure 

&AtServer
Procedure FillInAcceptanceArea()
	
	ReceivingArea = MobileWarehouseKeeperWorkspace.DefaultAcceptanceZone(Warehouse, Premise);
	
EndProcedure

&AtServer
Procedure UpdateAcceptanceZoneBinLocationSystem()

	FillInAcceptanceArea();

	UseBinLocationWarehousing = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Premise,
		"UseBinLocationWarehousing");

EndProcedure

&AtClient
Procedure ShowMenu()

	Items.MenuGroup_2.Visible = True;
	Items.CommandGroup.Visible = True;
	Items.DocumentInformation.Visible = True;
	Items.InformationAboutSender.Visible = True;
	
EndProcedure

&AtClient
Procedure HideMenu()

	Items.MenuGroup_2.Visible = False;
	Items.CommandGroup.Visible = False;
	Items.DocumentInformation.Visible = False;
	Items.InformationAboutSender.Visible = False;
	
EndProcedure

&AtServer
Procedure CollectEverythingOnServer()

#If Not MobileStandaloneServer Then
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Goods.Products AS Products
		|INTO TTProducts_1
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow AS DocumentInflow,
		|	GoodsToReceiveBalance.Products AS Products,
		|	GoodsToReceiveBalance.Characteristic AS Characteristic,
		|	GoodsToReceiveBalance.Purpose AS Purpose,
		|	MAX(GoodsToReceiveBalance.Series) AS Series
		|INTO SetOfSeries
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,
		|		DocumentInflow = &DocumentInflow
		// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
		// then you need to accept it, if not, then all goods orders.
		|			AND (ControlledLotReference = &ControlledLotReference
		|				OR ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))) AS GoodsToReceiveBalance
		|
		|GROUP BY
		|	GoodsToReceiveBalance.DocumentInflow,
		|	GoodsToReceiveBalance.Purpose,
		|	GoodsToReceiveBalance.Products,
		|	GoodsToReceiveBalance.Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow AS DocumentInflow,
		|	GoodsToReceiveBalance.Products AS Products,
		|	GoodsToReceiveBalance.Characteristic AS Characteristic,
		|	GoodsToReceiveBalance.Purpose AS Purpose,
		|	GoodsToReceiveBalance.Warehouse AS Warehouse,
		|	GoodsToReceiveBalance.Sender AS Sender,
		|	GoodsToReceiveBalance.BusinessOperation AS BusinessOperation,
		|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS Count,
		|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS NumberOfPackages,
		|	GoodsToReceiveBalance.Products.UnitOfMeasure AS Package,
		|	SetOfSeries.Series AS Series
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(
		|			,
		|			DocumentInflow = &DocumentInflow
		// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
		// then you need to accept it, if not, then all goods orders.
		|				AND (ControlledLotReference = &ControlledLotReference
		|					OR ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))
		|				AND Products IN
		|					(SELECT
		|						TTProducts_1.Products AS Products
		|					FROM
		|						TTProducts_1)) AS GoodsToReceiveBalance
		|		LEFT JOIN SetOfSeries AS SetOfSeries
		|		ON GoodsToReceiveBalance.DocumentInflow = SetOfSeries.DocumentInflow
		|			AND GoodsToReceiveBalance.Products = SetOfSeries.Products
		|			AND GoodsToReceiveBalance.Characteristic = SetOfSeries.Characteristic
		|			AND GoodsToReceiveBalance.Purpose = SetOfSeries.Purpose
		|WHERE
		|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance > 0";
	
	Query.SetParameter("DocumentInflow", ReceiptReferenceOrder);
	Query.SetParameter("ControlledLotReference", ControlledLotReference);
	Query.SetParameter("Goods", GoodsToReceive.Unload());
	
	Balance = Query.Execute().Unload();
	
	If UseBinLocationWarehousing Then
		SplitByPackagesForReference(Balance);
		ProductsAccepted.Load(Balance);
	Else
		ProductsAccepted.Load(Balance);
		MobileWarehouseKeeperWorkspace.SplitProductsByProductLocations(ProductsAccepted);
	EndIf;
#EndIf

EndProcedure

&AtServerNoContext
Function ItemDataBySchool(Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.ItemDataBySchool(Barcode);
	
EndFunction

&AtClient
Procedure AfterClosingQuestion_(Result, Var_Parameters = Undefined) Export
	
	If Result = "ExitApp" Then
		
		AcceptanceIsComplete = FinishAcceptanceOnServer();
		
		If AcceptanceIsComplete Then
			Close();
		Else
			Status(ErrorText);
		EndIf;
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionCollectAll(Result, Var_Parameters = Undefined) Export
	
	If Result = DialogReturnCode.Yes Then
		
		CollectEverythingOnServer();
		CreateMenu_("Accepted");
		
	EndIf;

EndProcedure

&AtClient
Procedure CloseForm(Result = Undefined, AdditionalParameters = Undefined) Export

	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

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

&AtServer
Procedure SplitByPackagesForReference(Goods)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.LineNumber AS LineNumber,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series
	|INTO RequestProductTable
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Products AS Products,
	|	MIN(Table.LineNumber) AS LineNumber,
	|	CAST(Table.Products AS Catalog.Products).PackagingGroup AS PackagingGroup,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series,
	|	SUM(Table.Count) AS Count
	|INTO ProductsTable
	|FROM
	|	RequestProductTable AS Table
	|WHERE
	|	ISNULL(Table.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	Table.Products,
	|	CAST(Table.Products AS Catalog.Products).PackagingGroup,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternalQuery.Products,
	|	InternalQuery.Count,
	|	InternalQuery.ItIsACargoItem,
	|	InternalQuery.LineNumber,
	|	InternalQuery.Characteristic,
	|	InternalQuery.Purpose,
	|	InternalQuery.QuantityPerPackage,
	|	InternalQuery.Package,
	|	InternalQuery.Series,
	|	InternalQuery.PackingUnitPresentation
	|FROM
	|	(SELECT
	|		ProductsTable.Products AS Products,
	|		ProductsTable.Count AS Count,
	|		FALSE AS ItIsACargoItem,
	|		ProductsTable.LineNumber AS LineNumber,
	|		ProductsTable.Characteristic AS Characteristic,
	|		ProductsTable.Purpose AS Purpose,
	|		ProductsTable.Series AS Series,
	|		ISNULL(&QueryTextPackagingFactor, 1) AS QuantityPerPackage,
	|		ISNULL(ProductPackages.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|		ISNULL(ProductPackages.UnitOfMeasure.Presentation, """") AS PackingUnitPresentation
	|	FROM
	|		ProductsTable AS ProductsTable
	|			LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (ProductsTable.Products = ProductPackages.Owner
	|					OR ProductsTable.PackagingGroup = ProductPackages.Owner)
	|				AND (NOT ProductPackages.DeletionMark)
	|				AND (ProductsTable.Count >= &QueryTextPackagingFactor)
	|				AND (&QueryTextPackagingFactor <> 0)
	|				AND (ISNULL(ProductPackages.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductsTable.Products,
	|		ProductsTable.Count,
	|		TRUE,
	|		ProductsTable.LineNumber,
	|		ProductsTable.Characteristic,
	|		ProductsTable.Purpose,
	|		ProductsTable.Package.NumberOfPackages,
	|		ProductsTable.Package,
	|		ProductsTable.Series,
	|		""""
	|	FROM
	|		RequestProductTable AS ProductsTable
	|	WHERE
	|		ISNULL(ProductsTable.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)) AS InternalQuery
	|
	|ORDER BY
	|	InternalQuery.LineNumber,
	|	InternalQuery.QuantityPerPackage,
	|	InternalQuery.PackingUnitPresentation";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		MobileWarehouseKeeperWorkspace.RequestTextForPackingCoefficient(
			"ProductPackages",
			"ProductsTable.Products"));
	
	ProductsTable = Goods.Copy();
	ProductsTable.Columns.Add("LineNumber",    New TypeDescription("Number", New NumberQualifiers(10,0)));
	
	LineNumber = 1;
	For Each String In ProductsTable Do
		String.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
	Query.SetParameter("Table",ProductsTable);
	
	Goods.Clear();
	
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	CurRowNumber = Undefined;
	CurProducts = Undefined;
	CurCharacteristic = Undefined;
	CurPurpose = Undefined;
	CurSeries = Undefined;
	Count = Undefined;
	
	While Selection.Next() Do
		
		If Selection.LineNumber <> CurRowNumber Then
			
			If Count <> Undefined Then
				NewRow = Goods.Add();
				NewRow.Count = Count;
				NewRow.NumberOfPackages = Count;
				
				NewRow.Products = CurProducts;
				NewRow.Characteristic = CurCharacteristic;
				NewRow.Purpose = CurPurpose;
				NewRow.Series = CurSeries;
			EndIf;
			
			CurRowNumber              = Selection.LineNumber;
			CurProducts             = Selection.Products; 
			CurCharacteristic           = Selection.Characteristic;
			CurPurpose               = Selection.Purpose;
			CurSeries                    = Selection.Series;
			
			If Selection.ItIsACargoItem Then
				
				NewRow = Goods.Add();
				NewRow.Count = Selection.Count;
				NewRow.NumberOfPackages =  Selection.Count * Selection.QuantityPerPackage;
				NewRow.Package = Selection.Package;
				
				NewRow.Products = CurProducts;
				NewRow.Characteristic = CurCharacteristic;
				NewRow.Purpose = CurPurpose;
				NewRow.Series = CurSeries;
				
				Continue;
				
			EndIf;
			
			Count = Selection.Count;//(Not A Sample.This is a commodity place, a sample.Quantity, Selection.Number of packages);
			
		EndIf;
		
		If Count <> Undefined Then
			If ValueIsFilled(Selection.Package) Then
				QuantityPerDocument = Int(Count / Selection.QuantityPerPackage);
			Else
				QuantityPerDocument = Count;
			EndIf;
			
			If QuantityPerDocument > 0 Then
				
				NewRow = Goods.Add();
				NewRow.Count = QuantityPerDocument * Selection.QuantityPerPackage;
				NewRow.NumberOfPackages = QuantityPerDocument;
				NewRow.Package = Selection.Package;
				
				NewRow.Products = CurProducts;
				NewRow.Characteristic = CurCharacteristic;
				NewRow.Purpose = CurPurpose;
				NewRow.Series = CurSeries;
				
				If Count = QuantityPerDocument * Selection.QuantityPerPackage Then
					Count = Undefined;
				Else
					Count = Count - QuantityPerDocument * Selection.QuantityPerPackage;
				EndIf;
				
			EndIf;
		EndIf;
	EndDo;
	
	If Count <> Undefined Then
		NewRow = Goods.Add();
		NewRow.Count = Count;
		NewRow.NumberOfPackages = Count;
		NewRow.Products = CurProducts;
		NewRow.Characteristic = CurCharacteristic;
		NewRow.Purpose = CurPurpose;
		NewRow.Series = CurSeries;
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelOrderAcceptance(Command)
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Đặt dấu xóa phiếu';
									|ru = 'Пометить ордер на удаление';
									|en = 'Mark the note for deletion'; fa = 'Mark the note for deletion';
									|it = 'Mark the note for deletion';
									|pl = 'Mark the note for deletion';
									|tr = 'Silme emrini işaretle'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục nhập hàng';
									|ru = 'Продолжить приемку';
									|en = 'Continue receipt'; fa = 'Continue receipt';
									|it = 'Continue receipt';
									|pl = 'Continue receipt';
									|tr = 'Kabule devam et'"));
	
	Notification = New CallbackDescription("AfterClosingIssueCancelAcceptance", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Để hủy nhập hàng, cần đặt dấu xóa phiếu nhập kho. Sau đó sẽ không thể quay lại chỉnh sửa. Bạn có muốn đặt dấu xóa không?';
									|ru = 'Для отмены приемки необходимо пометить на удаление приходный ордер. Вернуться к редактированию будет невозможно. Пометить на удаление?';
									|en = 'To cancel goods receipt, mark the goods receipt document for deletion. It will be impossible to get back to editing. Mark the document for deletion?'; fa = 'To cancel goods receipt, mark the goods receipt document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|it = 'To cancel goods receipt, mark the goods receipt document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|pl = 'To cancel goods receipt, mark the goods receipt document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|tr = 'Kabulü geri almak için, ambar girişini silinmek üzere işaretlemeniz gerekir. Düzenleme yapılamaz. Silinmek üzere işaretlensin mi?'"), ValueList, 0);
	
EndProcedure

&AtClient
Procedure AfterClosingIssueCancelAcceptance(Result, Var_Parameters) Export
	
	If Result = "ExitApp" Then
		
		AcceptanceCanceled = CancelOrderAcceptanceATServer();
		
		If AcceptanceCanceled Then
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
Function CancelOrderAcceptanceATServer()
	
#If MobileStandaloneServer Then
	Return False;
#Else
	Try
		DocumentObject = Ref.GetObject();
		DocumentObject.SetDeletionMark(True);
		
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	Except
		Common.MessageToUser(NStr("vi = 'Không thể hủy nhập hàng.';
									|ru = 'Не удалось отменить приемку.';
									|en = 'Cannot cancel goods receipt.'; fa = 'Cannot cancel goods receipt.';
									|it = 'Cannot cancel goods receipt.';
									|pl = 'Cannot cancel goods receipt.';
									|tr = 'Kabul iptal edilemedi.'"));
		
		Return False;
	EndTry;
	
	Return True;
#EndIf

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
