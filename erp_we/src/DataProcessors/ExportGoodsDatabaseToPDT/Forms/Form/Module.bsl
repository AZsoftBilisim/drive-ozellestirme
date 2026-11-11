
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	LoadDefaultSelectionSettings();

	Items.Variant.ChoiceList.Add("ByRegisteredRecords",                       NStr("vi = 'Theo lưu chuyển trong kho cho giai đoạn';
																					|ru = 'По движениям на складах за период';
																					|en = 'By warehouse movements over the period'; fa = 'By warehouse movements over the period';
																					|it = 'Per i movimenti nei magazzini per il periodo';
																					|pl = 'Wg ruchów na magazynach za okres';
																					|tr = 'Dönem içindeki stok hareketlerine ilişkin'"));
	Items.Variant.ChoiceList.Add("ByRecountGoods",                NStr("vi = 'Theo hàng hóa kiểm đếm';
																		|ru = 'По товарам пересчета';
																		|en = 'By inventory count goods'; fa = 'بر اساس کالاهای شمارش موجودی';
																		|it = 'Per le merci di ricalcolo';
																		|pl = 'Wg towarów przeliczenia';
																		|tr = 'Stok sayımına ilişkin'"));
	If GetFunctionalOption("UseBinLocationWarehousing", New Structure) Then
		Items.Variant.ChoiceList.Add("ByReceivingAndShipmentReferences", NStr("vi = 'Theo lệnh nhập hàng và xuất hàng';
																				|ru = 'По распоряжениям на приемку и отгрузку';
																				|en = 'By receipt and shipment references'; fa = 'بر اساس مراجع دریافت و ارسال';
																				|it = 'Per le disposizioni di accettazione e spedizione';
																				|pl = 'Wg zamówień na odbiór i wysyłkę';
																				|tr = 'Siparişlerin alınması ve gönderilmesine ilişkin'"));
		Items.Variant.ChoiceList.Add("ByShipmentReferences",         NStr("vi = 'Theo lệnh xuất hàng';
																			|ru = 'По распоряжениям на отгрузку';
																			|en = 'By shipment references'; fa = 'بر اساس مراجع ارسال';
																			|it = 'Per le disposizioni di spedizione';
																			|pl = 'Wg zamówień na wysyłkę';
																			|tr = 'Siparişlerin gönderilmesine ilişkin'"));
		Items.Variant.ChoiceList.Add("ByReceivingReferences",          NStr("vi = 'Theo lệnh nhập hàng';
																			|ru = 'По распоряжениям на приемку';
																			|en = 'By receipt references'; fa = 'بر اساس مراجع دریافت';
																			|it = 'Per le disposizioni di accettazione';
																			|pl = 'Wg zamówień odbioru';
																			|tr = 'Siparişlerin alınmasına ilişkin'"));
	EndIf;
	Items.Variant.ChoiceList.Add("ByFilter", NStr("vi = 'Theo lọc';
													|ru = 'По отбору';
													|en = 'By picking'; fa = 'By picking';
													|it = 'In base alla selezione';
													|pl = 'Wg filtru';
													|tr = 'Seçime ilişkin'"));
	
	If ValueIsFilled(Parameters.FillingVariant) Then
		FillingVariant = Parameters.FillingVariant;
		
		DateOfShipment = Parameters.DateOfShipment;
		DateOfReceiving = Parameters.DateOfReceiving;
		
		OriginWarehouse = Parameters.OriginWarehouse;
		ReceivingWarehouse = Parameters.ReceivingWarehouse;
		
		Recalculate = Parameters.Recalculate;
		
		FullUpload = Parameters.FullUpload;
		
		FillAtServer();
		
	Else
		FillingVariant = "ByFilter";
	EndIf;
	
	Items.Pages.CurrentPage = Items[FillingVariant];
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillingVariant = Settings["FillingVariant"];
	
	Items.Pages.CurrentPage = Items[FillingVariant];
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UnloadExecute(Command)
	
	ClearMessages();
	
	CheckResult = ExecuteCheck();
	If Not CheckResult.ProductsSelected Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn mặt hàng nào';
										|ru = 'Не выбрано ни одного товара';
										|en = 'No goods selected'; fa = 'No goods selected';
										|it = 'Nessuna merce è stata selezionata';
										|pl = 'Nie wybrano ani jednego towaru';
										|tr = 'Hiç bir ürün seçilmedi'"));
		Return;
	EndIf;
	
	TSDTable = ProductDatabaseArray();
	
	EquipmentManagerClient.StartUploadingVTSDData(
		New CallbackDescription("UploadVTSDCompletion", ThisObject),
		UUID,
		TSDTable, FullUpload);

EndProcedure

&AtClient
Procedure UploadVTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		MessageText = NStr("vi = 'Đã kết xuất thành công dữ liệu vào thiết bị thu thập dữ liệu.';
							|ru = 'Данные успешно выгружены в ТСД.';
							|en = 'The data was successfully uploaded to PDT.'; fa = 'The data was successfully uploaded to PDT.';
							|it = 'I dati sono stati importati con successo nel TSD (Terminale Raccolta Dati).';
							|pl = 'Dane skutecznie odprowadzane w KD.';
							|tr = 'Veriler gönderim belgelerine başarıyla yüklendi.'");
		CommonClientServer.MessageToUser(MessageText);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	Cancel = False;
	
	ClearMessages();
	
	If FillingVariant = "ByRecountGoods"
		And Not ValueIsFilled(Recalculate) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kiểm đếm hàng hóa""';
				|ru = 'Не заполнено поле ""Пересчет товаров""';
				|en = '""Inventory count"" is required'; fa = '""Inventory count"" is required';
				|it = 'Non è compilato il campo ""Ricalcolo delle merci""';
				|pl = 'Nie jest wypełnione pole ""Liczenie towarów""';
				|tr = '""Stok sayımı"" alanı doldurulmamış'"),
			,
			"Recalculate",
			,
			Cancel);
			
		Return;
		
	ElsIf FillingVariant = "ByReceivingAndShipmentReferences"
		And Not ValueIsFilled(OriginWarehouse) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kho bãi""';
				|ru = 'Не заполнено поле ""Склад""';
				|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
				|it = 'Il campo ""Magazzino"" non è compilato';
				|pl = 'Nie jest wypełnione pole ""Magazyn""';
				|tr = '""Ambar"" alanı doldurulmadı'"),
			,
			"OriginWarehouse",
			,
			Cancel);
		
	ElsIf FillingVariant = "ByShipmentReferences"
		And Not ValueIsFilled(OriginWarehouse) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kho bãi""';
				|ru = 'Не заполнено поле ""Склад""';
				|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
				|it = 'Il campo ""Magazzino"" non è compilato';
				|pl = 'Nie jest wypełnione pole ""Magazyn""';
				|tr = '""Ambar"" alanı doldurulmadı'"),
			,
			"OriginWarehouse",
			,
			Cancel);
		
	ElsIf FillingVariant = "ByReceivingReferences"
		And Not ValueIsFilled(ReceivingWarehouse) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kho bãi""';
				|ru = 'Не заполнено поле ""Склад""';
				|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
				|it = 'Il campo ""Magazzino"" non è compilato';
				|pl = 'Nie jest wypełnione pole ""Magazyn""';
				|tr = '""Ambar"" alanı doldurulmadı'"),
			,
			"ReceivingWarehouse",
			,
			Cancel);
		
	EndIf;
	
	If Not Cancel Then
		FillAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectRows(Command)
	
	For Each TSRow In Object.Goods Do
		TSRow.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearRows(Command)

	For Each TSRow In Object.Goods Do
		TSRow.Selected = False
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectSelectedRows(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	
	If RowsArray.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Trong danh sách không có các dòng được chọn';
										|ru = 'В списке отсутствуют выделенные строки';
										|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
										|it = 'Nell''elenco mancano le righe selezionate';
										|pl = 'Na liście brakuje wybranych wierszy';
										|tr = 'Listede seçili satır yok'"));
		Return;
	EndIf;
	
	For Each LineNumber In RowsArray Do
		TSRow = Object.Goods.FindByID(LineNumber);
		TSRow.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearSelectedRows(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	
	If RowsArray.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Trong danh sách không có các dòng được chọn';
										|ru = 'В списке отсутствуют выделенные строки';
										|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
										|it = 'Nell''elenco mancano le righe selezionate';
										|pl = 'Na liście brakuje wybranych wierszy';
										|tr = 'Listede seçili satır yok'"));
		Return;
	EndIf;
	
	For Each LineNumber In RowsArray Do
		TSRow = Object.Goods.FindByID(LineNumber);
		TSRow.Selected = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure InstallANewBarcodeEAN13(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	
	If RowsArray.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Trong danh sách không có các dòng được chọn';
										|ru = 'В списке отсутствуют выделенные строки';
										|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
										|it = 'Nell''elenco mancano le righe selezionate';
										|pl = 'Na liście brakuje wybranych wierszy';
										|tr = 'Listede seçili satır yok'"));
		Return;
	EndIf;
	
	ErrorDescription = "";
	Result = InstallNewEAN13BarcodesOnServer(ErrorDescription);
	
	If Result = 0 And ValueIsFilled(ErrorDescription) Then
		ShowMessageBox(Undefined, ErrorDescription);
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure FillInOptionWhenChanging(Item)
	
	Items.Pages.CurrentPage = Items[FillingVariant];
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsBarcode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Barcode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure

#Region Other

&AtServer
Function ProductDatabaseArray()

	UploadArray = New Array;
	
	For Each TSRow In Object.Goods Do
		
		If TSRow.Selected Then
			StringStructure = New Structure;
			StringStructure.Insert("Barcode",                   TSRow.Barcode);
			StringStructure.Insert("Products",               TSRow.Products);
			StringStructure.Insert("UnitOfMeasure",           String(TSRow.Package));
			StringStructure.Insert("ProductCharacteristic", String(TSRow.Characteristic));
			StringStructure.Insert("Price",                       TSRow.Price);
			StringStructure.Insert("Count",                 0);
			
			UploadArray.Add(StringStructure);
		EndIf;
		
	EndDo;
	
	Return UploadArray;

EndFunction

&AtServer
Procedure ServerSelectionGuide()
	
	Object.Goods.Clear();
	
	// The fields required for output to the table of products on the form.
	SettingsStructure = DataProcessors.ExportGoodsDatabaseToPDT.SettingsStructure();
	
	SettingsStructure.RequiredFields.Add("Price");
	SettingsStructure.RequiredFields.Add("Barcode");
	SettingsStructure.RequiredFields.Add("Count");
	SettingsStructure.RequiredFields.Add("Products");
	If GetFunctionalOption("UseItemVariants") Then
		SettingsStructure.RequiredFields.Add("Characteristic");
	EndIf;
	If GetFunctionalOption("UseItemPackages") Then
		SettingsStructure.RequiredFields.Add("Package");
	EndIf;
	SettingsStructure.RequiredFields.Add("SoldByWeight");
	SettingsStructure.RequiredFields.Add("WarehouseStockBalance");
	
	DataParameters = New Structure;
	DataParameters.Insert("CurrentDate", CurrentSessionDate());
	DataParameters.Insert("PriceKind", PriceKind);
	SettingsStructure.Insert("DataParameters", DataParameters);
	
	// Templates of labels and price tags.
	SettingsStructure.SettingsComposer = SettingsComposer;
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "DBTemplateFieldsGoods";
	
	Object.Goods.Clear();
	
	// Loading the generated list of products.
	Table = DataProcessors.ExportGoodsDatabaseToPDT.PrepareDataStructure(SettingsStructure);
	For Each TSRow In Table Do
		
		NewRow = Object.Goods.Add();
		NewRow.Products         = TSRow.Products;
		
		If GetFunctionalOption("UseItemVariants") Then
			NewRow.Characteristic       = TSRow.Characteristic;
		EndIf;
		If GetFunctionalOption("UseItemPackages") Then
			NewRow.Package             = TSRow.Package;
		EndIf;
		
		NewRow.Barcode             = InformationRegisters.ItemsBarcodes.PrepareBarcode(TSRow.Barcode);
		NewRow.Price                 = TSRow.Price;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInByGoodsRecalculationOnServer()
	
	Object.Goods.Clear();
	
	Query = New Query(
	"SELECT DISTINCT
	|	RecalculationOfGoods.Products,
	|	RecalculationOfGoods.Package,
	|	RecalculationOfGoods.Characteristic,
	|	ItemsBarcodes.Barcode,
	|	ProductPriceRegister.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1) AS Price
	|FROM
	|	Document.InventoryRecount.Goods AS RecalculationOfGoods
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON RecalculationOfGoods.Products = ItemsBarcodes.Products
	|			AND RecalculationOfGoods.Characteristic = ItemsBarcodes.Characteristic
	|			AND RecalculationOfGoods.Package = ItemsBarcodes.Package
	|	
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&CurrentDate, PriceKind = &PriceKind) AS ProductPriceRegister
	|		ON RecalculationOfGoods.Products = ProductPriceRegister.Products
	|			AND RecalculationOfGoods.Characteristic = ProductPriceRegister.Characteristic
	|
	|WHERE
	|	RecalculationOfGoods.Ref = &InventoryRecount
	|	AND NOT CASE
	|		WHEN RecalculationOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CASE WHEN RecalculationOfGoods.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|		ELSE CASE WHEN RecalculationOfGoods.Package.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|	END");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPriceRegister.Package",
			"ProductPriceRegister.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"RecalculationOfGoods.Package",
			"RecalculationOfGoods.Products"));
	
	Query.SetParameter("InventoryRecount", Recalculate);
	Query.SetParameter("CurrentDate",     CurrentSessionDate());
	Query.SetParameter("PriceKind",         PriceKind);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		NewRow.Products         = Selection.Products;
		NewRow.Characteristic       = Selection.Characteristic;
		NewRow.Package             = Selection.Package;
		NewRow.Barcode             = InformationRegisters.ItemsBarcodes.PrepareBarcode(Selection.Barcode);
		NewRow.Price                 = Selection.Price;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillByRegisteredRecordsOnServer()
	
	Object.Goods.Clear();
	
	Query = New Query(
	"SELECT DISTINCT
	|	ItemsBarcodes.Products,
	|	ItemsBarcodes.Characteristic,
	|	ItemsBarcodes.Package,
	|	ItemsBarcodes.Barcode,
	|	ProductPriceRegister.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1) AS Price
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|	
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&CurrentDate, PriceKind = &PriceKind) AS ProductPriceRegister
	|		ON ItemsBarcodes.Products = ProductPriceRegister.Products
	|			AND ItemsBarcodes.Characteristic = ProductPriceRegister.Characteristic
	|
	|WHERE
	|	(ItemsBarcodes.Products, ItemsBarcodes.Characteristic) IN
	|			(SELECT
	|				MovementOfGoodsTurnover.Products,
	|				MovementOfGoodsTurnover.Characteristic
	|			FROM
	|				AccumulationRegister.ProductStock.Turnovers(&BeginOfPeriod, &EndOfPeriod, Auto, ) AS MovementOfGoodsTurnover)
	|	AND NOT CASE
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CASE WHEN ItemsBarcodes.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|		ELSE CASE WHEN ItemsBarcodes.Package.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|	END");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPriceRegister.Package",
			"ProductPriceRegister.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsBarcodes.Package",
			"ItemsBarcodes.Products"));
	
	Query.SetParameter("BeginOfPeriod", StandardPeriod.StartDate);
	Query.SetParameter("EndOfPeriod",  StandardPeriod.EndDate);
	Query.SetParameter("CurrentDate",   CurrentSessionDate());
	Query.SetParameter("PriceKind",       PriceKind);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		NewRow.Products         = Selection.Products;
		NewRow.Characteristic       = Selection.Characteristic;
		NewRow.Package             = Selection.Package;
		NewRow.Barcode             = InformationRegisters.ItemsBarcodes.PrepareBarcode(Selection.Barcode);
		NewRow.Price                 = Selection.Price;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInOrdersForAcceptanceAndShipmentOnServer()
	
	Object.Goods.Clear();
	
	Query = New Query(
	"SELECT DISTINCT
	|	ItemsBarcodes.Products,
	|	ItemsBarcodes.Characteristic,
	|	ItemsBarcodes.Package,
	|	ItemsBarcodes.Barcode,
	|	ProductPriceRegister.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1) AS Price
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|	
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&CurrentDate, PriceKind = &PriceKind) AS ProductPriceRegister
	|		ON ItemsBarcodes.Products = ProductPriceRegister.Products
	|			AND ItemsBarcodes.Characteristic = ProductPriceRegister.Characteristic
	|
	|WHERE
	|	(ItemsBarcodes.Products, ItemsBarcodes.Characteristic) IN
	|			(
	|			SELECT
	|				AccumulationRegisterGoodsForIssueBalance.Products,
	|				AccumulationRegisterGoodsForIssueBalance.Characteristic
	|			FROM
	|				AccumulationRegister.GoodsForIssue.Balance(&Date, Warehouse = &Warehouse) AS AccumulationRegisterGoodsForIssueBalance)
	|	OR (ItemsBarcodes.Products, ItemsBarcodes.Characteristic) IN
	|			(
	|			SELECT
	|				GoodsToBeReceivedBalancesAsOfDate.Products,
	|				GoodsToBeReceivedBalancesAsOfDate.Characteristic
	|			FROM
	|				AccumulationRegister.GoodsToReceive.Balance(&Date, Warehouse = &Warehouse) AS GoodsToBeReceivedBalancesAsOfDate
	|					INNER JOIN AccumulationRegister.GoodsToReceive.Balance(, Warehouse = &Warehouse) AS GoodsDueCurBalances
	|					ON GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsDueCurBalances.DocumentInflow
	|						AND GoodsToBeReceivedBalancesAsOfDate.Products = GoodsDueCurBalances.Products
	|						AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsDueCurBalances.Characteristic
	|						AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsDueCurBalances.Warehouse
	|)
	|	AND NOT CASE
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CASE WHEN ItemsBarcodes.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|		ELSE CASE WHEN ItemsBarcodes.Package.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|	END");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPriceRegister.Package",
			"ProductPriceRegister.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsBarcodes.Package",
			"ItemsBarcodes.Products"));
	
	Query.SetParameter("Warehouse",       OriginWarehouse);
	Query.SetParameter("Date",        ?(ValueIsFilled(DateOfShipment), EndOfDay(DateOfShipment), CurrentSessionDate()));
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("PriceKind",     PriceKind);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		NewRow.Products         = Selection.Products;
		NewRow.Characteristic       = Selection.Characteristic;
		NewRow.Package             = Selection.Package;
		NewRow.Barcode             = InformationRegisters.ItemsBarcodes.PrepareBarcode(Selection.Barcode);
		NewRow.Price                 = Selection.Price;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInShippingOrdersOnServer()
	
	Object.Goods.Clear();
	
	Query = New Query(
	"SELECT DISTINCT
	|	ItemsBarcodes.Products,
	|	ItemsBarcodes.Characteristic,
	|	ItemsBarcodes.Package,
	|	ItemsBarcodes.Barcode,
	|	ProductPriceRegister.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1) AS Price
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|	
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&CurrentDate, PriceKind = &PriceKind) AS ProductPriceRegister
	|		ON ItemsBarcodes.Products = ProductPriceRegister.Products
	|			AND ItemsBarcodes.Characteristic = ProductPriceRegister.Characteristic
	|
	|WHERE
	|	(ItemsBarcodes.Products, ItemsBarcodes.Characteristic) IN
	|			(
	|			SELECT
	|				AccumulationRegisterGoodsForIssueBalance.Products,
	|				AccumulationRegisterGoodsForIssueBalance.Characteristic
	|			FROM
	|				AccumulationRegister.GoodsForIssue.Balance(&DateOfShipment, Warehouse = &Warehouse) AS AccumulationRegisterGoodsForIssueBalance
	|)
	|	AND NOT CASE
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CASE WHEN ItemsBarcodes.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|		ELSE CASE WHEN ItemsBarcodes.Package.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|	END");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPriceRegister.Package",
			"ProductPriceRegister.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsBarcodes.Package",
			"ItemsBarcodes.Products"));
	
	Query.SetParameter("Warehouse",        OriginWarehouse);
	Query.SetParameter("DateOfShipment", ?(ValueIsFilled(DateOfShipment), EndOfDay(DateOfShipment), CurrentSessionDate()));
	Query.SetParameter("CurrentDate",  CurrentSessionDate());
	Query.SetParameter("PriceKind",      PriceKind);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		NewRow.Products         = Selection.Products;
		NewRow.Characteristic       = Selection.Characteristic;
		NewRow.Package             = Selection.Package;
		NewRow.Barcode             = InformationRegisters.ItemsBarcodes.PrepareBarcode(Selection.Barcode);
		NewRow.Price                 = Selection.Price;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInAcceptanceOrdersOnServer()
	
	Object.Goods.Clear();
	
	Query = New Query(
	"SELECT DISTINCT
	|	ItemsBarcodes.Products,
	|	ItemsBarcodes.Characteristic,
	|	ItemsBarcodes.Package,
	|	ItemsBarcodes.Barcode,
	|	ProductPriceRegister.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1) AS Price
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|	
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&CurrentDate, PriceKind = &PriceKind) AS ProductPriceRegister
	|		ON ItemsBarcodes.Products = ProductPriceRegister.Products
	|			AND ItemsBarcodes.Characteristic = ProductPriceRegister.Characteristic
	|
	|WHERE
	|	(ItemsBarcodes.Products, ItemsBarcodes.Characteristic) IN
	|			(
	|			SELECT
	|				GoodsToBeReceivedBalancesAsOfDate.Products,
	|				GoodsToBeReceivedBalancesAsOfDate.Characteristic
	|			FROM
	|				AccumulationRegister.GoodsToReceive.Balance(&DateOfReceipt, Warehouse = &Warehouse) AS GoodsToBeReceivedBalancesAsOfDate
	|					INNER JOIN AccumulationRegister.GoodsToReceive.Balance(, Warehouse = &Warehouse) AS GoodsDueCurBalances
	|					ON GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsDueCurBalances.DocumentInflow
	|						AND GoodsToBeReceivedBalancesAsOfDate.Products = GoodsDueCurBalances.Products
	|						AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsDueCurBalances.Characteristic
	|						AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsDueCurBalances.Warehouse
	|)
	|	AND NOT CASE
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CASE WHEN ItemsBarcodes.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|		ELSE CASE WHEN ItemsBarcodes.Package.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight) THEN TRUE ELSE FALSE END
	|	END");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPriceRegister.Package",
			"ProductPriceRegister.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsBarcodes.Package",
			"ItemsBarcodes.Products"));
	
	Query.SetParameter("Warehouse",           ReceivingWarehouse);
	Query.SetParameter("DateOfReceipt", ?(ValueIsFilled(DateOfReceiving), EndOfDay(DateOfReceiving), CurrentSessionDate()));
	Query.SetParameter("CurrentDate",     CurrentSessionDate());
	Query.SetParameter("PriceKind",         PriceKind);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		NewRow.Products         = Selection.Products;
		NewRow.Characteristic       = Selection.Characteristic;
		NewRow.Package             = Selection.Package;
		NewRow.Barcode             = InformationRegisters.ItemsBarcodes.PrepareBarcode(Selection.Barcode);
		NewRow.Price                 = Selection.Price;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillAtServer()
	
	SetPrivilegedMode(True);
	
	If FillingVariant = "ByFilter" Then
		ServerSelectionGuide();
	ElsIf FillingVariant = "ByRecountGoods" Then
		FillInByGoodsRecalculationOnServer();
	ElsIf FillingVariant = "ByRegisteredRecords" Then
		FillByRegisteredRecordsOnServer();
	ElsIf FillingVariant = "ByReceivingAndShipmentReferences" Then
		FillInOrdersForAcceptanceAndShipmentOnServer();
	ElsIf FillingVariant = "ByShipmentReferences" Then
		FillInShippingOrdersOnServer();
	ElsIf FillingVariant = "ByReceivingReferences" Then
		FillInAcceptanceOrdersOnServer();
	EndIf;
	
	For Each TSRow In Object.Goods Do
		TSRow.Selected = True;
	EndDo;
	
EndProcedure

&AtServer
Procedure LoadDefaultSelectionSettings()
	
	DataCompositionSchema = DataProcessors.ExportGoodsDatabaseToPDT.GetTemplate("DBTemplateFieldsGoods");
	
	SettingsComposer.Initialize(
		New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, ThisForm.UUID)));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

&AtServer
Function InstallNewEAN13BarcodesOnServer(ErrorDescription = "")
	
	Count = 0;
	
	RowsArray = Items.Goods.SelectedRows;
	
	Barcodes = New Map;
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		
		LockItem = Block.Add("InformationRegister.ItemsBarcodes");
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		
		MaximumValuesOfUnitBarcodes = InformationRegisters.ItemsBarcodes.GetMaximumValuesOfUnitBarcodes();
		MaximumUnitProductCode              = InformationRegisters.ItemsBarcodes.MaximumUnitProductCode();
		BarcodeNodePrefix                       = InformationRegisters.ItemsBarcodes.BarcodeNodePrefix();
		
		For Each LineNumber In RowsArray Do
			
			TSRow = Object.Goods.FindByID(LineNumber);
			
			If Not ValueIsFilled(TSRow.Barcode) Then
				Count = Count + 1;
			Else
				Continue;
			EndIf;
			
			Code = Undefined;
			Span = Undefined;
			
			For Each StringTSMaximumValues In MaximumValuesOfUnitBarcodes Do
				
				If Not StringTSMaximumValues.Code < MaximumUnitProductCode Then
					Continue;
				EndIf;
				
				StringTSMaximumValues.Code = StringTSMaximumValues.Code + 1;
				
				Code      = StringTSMaximumValues.Code; 
				Span = StringTSMaximumValues.Span;
				
				Break;
			EndDo;
			
			If Code = Undefined Then
				Raise InformationRegisters.ItemsBarcodes.MessageTextNoFreeCodesPieceBarcodes();
			EndIf;
			
			Barcode = InformationRegisters.ItemsBarcodes.GetBarcodeByCode(Code, Span, BarcodeNodePrefix);
			
			NewBarcode = InformationRegisters.ItemsBarcodes.CreateRecordManager();
			NewBarcode.Products = TSRow.Products; 
			If GetFunctionalOption("UseItemVariants") Then
				NewBarcode.Characteristic = TSRow.Characteristic;
			EndIf;
			If GetFunctionalOption("UseItemPackages") Then
				NewBarcode.Package       = TSRow.Package;
			EndIf;
			
			NewBarcode.Barcode = Barcode;
			NewBarcode.Write();
			
			Barcodes.Insert(TSRow, NewBarcode.Barcode);
			
		EndDo;
		
		For Each KeyAndValue In Barcodes Do
			KeyAndValue.Key.Barcode = KeyAndValue.Value;
		EndDo;
		
		CommitTransaction();
	
	Except
		RollbackTransaction();
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
		ErrorDescription = NStr("vi = 'Đã xảy ra lỗi khi ghi mã vạch.
		                      |Ghi mã vạch không thành công.
		                      |Mô tả bổ sung:
		                      |%AdditionalDetails%';
		                      |ru = 'При записи штрихкодов произошла ошибка.
		                      |Запись штрихкодов не выполнена.
		                      |Дополнительное описание:
		                      |%AdditionalDetails%';
		                      |en = 'An error occurred while saving barcodes.
		                      |Barcodes are not saved.
		                      |Additional description:
		                      |%AdditionalDetails%'; fa = 'An error occurred while saving barcodes.
		                      |Barcodes are not saved.
		                      |Additional description:
		                      |%AdditionalDetails%';
		                      |it = 'Nel corso della registrazione dei codici a barre si è verificato un errore.
		                      |La registrazione dei codici a barre non è stata effettuata.
		                      |Descrizione aggiuntiva:
		                      |%AdditionalDetails%';
		                      |pl = 'Podczas zapisu kodów kreskowych wystąpił błąd.
		                      |Zapis kodów kreskowych nie powiódł się.
		                      |Dodatkowy opis: 
		                      |%AdditionalDetails%';
		                      |tr = 'Barkodlar yazılırken bir hata oluştu.
		                      | Barkodlar yazılmadı.
		                      | Detaylı açıklama:
		                      |%AdditionalDetails%'");
		ErrorDescription = StrReplace(ErrorDescription, "%AdditionalDetails%", ErrorInfo().Description);
		
		Return 0;
	EndTry;
	
	Return Count;
	
EndFunction

&AtServer
Function ExecuteCheck()
	
	HasErrors = False;
	
	For Each TSRow In Object.Goods Do
		
		If Not TSRow.Selected Then
			Continue;
		EndIf;
		
		LineNumber = TSRow.LineNumber - 1;
		
		If Not ValueIsFilled(TSRow.Barcode) Then
			
			CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền trường ""Mã vạch"" tại dòng %1';
						|ru = 'Не заполнено поле ""Штрихкод"" в строке %1';
						|en = '""Barcode"" is required in line %1'; fa = '""Barcode"" is required in line %1';
						|it = 'Il campo ""Codice a barre"" nella riga %1 non è compilato';
						|pl = 'Nie jest wypełnione pole ""Kod kreskowy"" w wierszu %1';
						|tr = '%1Satırdaki ""Barkod"" alanı doldurulmamış'"),
					LineNumber+1
				),
				,
				"Object.Goods["+LineNumber+"].Barcode",
				,
				HasErrors);
			
		EndIf;
	
	EndDo;

	Filter = New Structure("Selected", True);
	ProductsSelected = Object.Goods.FindRows(Filter).Count() > 0;
	
	Return New Structure("ProductsSelected, CheckCompleted", ProductsSelected, Not HasErrors);
	
EndFunction

&AtClient
Procedure VariantClearing(Item, StandardProcessing)
	StandardProcessing = False;
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
