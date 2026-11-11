#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Var FieldName;
	Var DocumentBasis;
	Var DateOfReceipt;
	TextOfMessageAboutIncorrectCreation = NStr("vi = 'Cần nhập phiếu nhập kho từ biểu mẫu ""Nhập hàng"".';
												|ru = 'Приходный ордер на товары нужно вводить из формы ""Приемка"".';
												|en = 'To register a goods receipt, use the ""Receipt"" form.'; fa = 'To register a goods receipt, use the ""Receipt"" form.';
												|it = 'Il reversale d’incasso deve essere immesso dal modello ""Accettazione"".';
												|pl = 'Asygnatę przychodowa na wiersze pozycji należy wprowadzać z formularza ""Odbiór"".';
												|tr = '""Mal kabulü"" formundan ambar giriş fişi girilmelidir.'");
	
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;	
		
	If TypeOf(FillingData) = Type("Structure") Then
		
		FillingData.Property("Warehouse",                      Warehouse);
		FillingData.Property("Premise",                  Premise);
		FillingData.Property("ReferenceOrder",               ReferenceOrder);
		FillingData.Property("ControlledLotReference",       ControlledLotReference);
		FillingData.Property("DateOfReceipt",            DateOfReceipt);
		FillingData.Property("ReceivingArea",                ReceivingArea);
		FillingData.Property("WarehouseOperation",          WarehouseOperation);
		FillingData.Property("Sender",                Sender);
		FillingData.Property("IncomingDocumentDate",     IncomingDocumentDate);
		FillingData.Property("IncomingDocumentNumber",    IncomingDocumentNumber);
		FillingData.Property("BusinessOperation",      BusinessOperation);
		
		If WarehouseOperation <> Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient
			And ValueIsFilled(ReferenceOrder) Then
			WarehouseOperation = WarehousesClientServer.WarehouseAcceptanceOperationForBusinessOperation(BusinessOperation);
			SetPrivilegedMode(True);
			
			If WarehouseOperation = Enums.WarehouseTransactions.ReceivingByTransfer
				Or WarehouseOperation = Enums.WarehouseTransactions.ProductReceivingFromManufacturing Then
				FillInItemsByItemsDue("ProductsQuantity_", DateOfReceipt);
			Else
				FillInItemsByItemsDue("Products", DateOfReceipt);
			EndIf;
			
			GoodsReceiptNoteLocalization.Filling(ThisObject, FillingData, StandardProcessing);
			
			Documents.GoodsReceiptNote.FillInSeriesByReference(ThisObject, False);
			SetPrivilegedMode(False);
		ElsIf WarehouseOperation <> Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient Then
			Raise TextOfMessageAboutIncorrectCreation;
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject, 
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsReceiptNote));
	
	If WriteMode = DocumentWriteMode.Posting Then
		CheckOrderWarehouse(Cancel);
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.FillInControlledLotReferenceInReceiptOrder(ThisObject);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateControlledLotReferenceInReceiptOrder(ThisObject);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	InitializeDocument();

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse, Date)
		And WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient Then		
		MessageText = NStr("vi = 'Giao dịch kho bãi ""%RefundOfRejectedItems%"" trong kho mà không sử dụng sơ đồ hai pha khi phản ánh hàng thừa, hàng thiếu và hàng hỏng sẽ là giao dịch lưu trữ. Để ghi tăng hàng hóa, nên sử dụng chứng từ ""%RecordingAsReceived%"".';
							|ru = 'Складская операция ""%RefundOfRejectedItems%"" на складе, неордерном при отражении излишков, недостач и порчи, является архивной. Для оприходования товаров рекомендуется использовать документ ""%RecordingAsReceived%"".';
							|en = 'Warehouse operation ""%RefundOfRejectedItems%"" is an archived one in a non-advanced warehouse when recording surpluses, shortages and damage. To record as received goods, use document ""%RecordingAsReceived%"".'; fa = 'Warehouse operation ""%RefundOfRejectedItems%"" is an archived one in a non-advanced warehouse when recording surpluses, shortages and damage. To record as received goods, use document ""%RecordingAsReceived%"".';
							|it = 'Per riportare le eccedenze, ammanchi e danni l''operazione di magazzino ""%RefundOfRejectedItems%"" nel magazzino è inattiva. Per registrare le merci in contabilità si consiglia di utilizzare il documento ""%RecordingAsReceived%"".';
							|pl = 'Operacja magazynowa ""%RefundOfRejectedItems%"" w magazynie, bez asygnat w razie odzwierciedlenia nadwyżek, braków i szkód, jest archiwalna. Do rejestrowania towarów zaleca się używanie dokumentu ""%RecordingAsReceived%"".';
							|tr = 'Ambar operasyonu ""%RefundOfRejectedItems%"" ambarda, düzensiz fazlalıklar, eksiklikler ve stok kalite düşüklüğü yansıtıldığında, arşivlenir. Ürün göndermek için ""%RecordingAsReceived%"" belgesinin kullanılması önerilmektedir.'");
		MessageText = StrReplace(MessageText, "%RefundOfRejectedItems%", Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient);
		MessageText = StrReplace(MessageText, "%RecordingAsReceived%", Metadata.Documents.InventorySurplusRecognition.Synonym);
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	BinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date);
	UsePackingLists = GetFunctionalOption("UsePackingLists");
	
	If Not BinLocationWarehousing Then
		NotCheckedAttributeArray.Add("ReceivingArea");
	ElsIf Not GetFunctionalOption("UseItemPackages") Then
		NotCheckedAttributeArray.Add("Goods.Package");
		MessageText = NStr("vi = 'Trong tùy chỉnh chương trình chưa bật sử dụng đóng gói mặt hàng, 
		|do đó không thể lập chứng từ theo kho có cất giữ số dư theo địa chỉ. Hãy liên hệ với người quản trị';
		|ru = 'В настройках программы не включено использование упаковок номенклатуры, 
		|поэтому нельзя оформить документ по складу с адресным хранением остатков. Обратитесь к администратору';
		|en = 'Packaging options are disabled in the application settings. To create a document that uses bin locations, you need to enable packaging options.
		|Please contact the administrator'; fa = 'Packaging options are disabled in the application settings. To create a document that uses bin locations, you need to enable packaging options.
		|Please contact the administrator';
		|it = 'Le impostazioni del programma non includono l''uso di imballaggio degli articoli, 
		|pertanto è impossibile formalizzare il documento per magazzino con il sistema di stoccaggio giacenze codificato. Contattare amministratore';
		|pl = 'W ustawieniach programu nie jest włączone użycie paczek wykazu towaru,
		|dlatego niemożliwe jest sporządzenie dokumentu dla magazynu z przechowywaniem pozostałości. Skontaktuj się z administratorem';
		|tr = 'Uygulama ayarlarında ürün paketleme kullanımı etkin değildir,
		|bu nedenle depo konum takibi olan bir ambar için belge düzenleyemezsiniz. Yönetici ile iletişime geçin'");
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndIf;	
	
	If (Not BinLocationWarehousing
		Or Status = Enums.GoodsReceiptNoteStatuses.ToReceive
		Or Status = Enums.GoodsReceiptNoteStatuses.InProgress
		Or Status = Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired)Then
		NotCheckedAttributeArray.Add("Goods.Package");
	Else
		CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
		CheckParameters.OutputLineNumbers = Not UsePackingLists;
		CheckParameters.SelectingRowsToCheck.Insert("ThisIsAPackingList", False);
		CheckParameters.OtherPresentationPackagingUnits = NStr("vi = 'Đơn vị tính';
																|ru = 'Ед. изм.';
																|en = 'Unit'; fa = 'واحد';
																|it = 'Unità di misura';
																|pl = 'J. m.';
																|tr = 'Ölçü birimi.'");
		ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
		
		ParametersForCheckingIndicationOfMultiTurnContainer = ReusablePackageServer.ParametersForCheckingIndicationOfMultiTurnContainer();
		ParametersForCheckingIndicationOfMultiTurnContainer.ThereAreCells = False;
		ReusablePackageServer.CheckIndicationOfMultiTurnContainer(ThisObject, ParametersForCheckingIndicationOfMultiTurnContainer, Cancel);
	EndIf;
	
	If Status = Enums.GoodsReceiptNoteStatuses.ToReceive 
		Or Status = Enums.GoodsReceiptNoteStatuses.InProgress
		Or Status = Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired Then
	
		NotCheckedAttributeArray.Add("Goods");
		NotCheckedAttributeArray.Add("Goods.Products");
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		NotCheckedAttributeArray.Add("Goods.Count");
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	Goods.LineNumber
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.Barcode = """"
		|	AND Goods.PackingListParent = VALUE(Document.PackingList.EmptyRef)
		|	AND Goods.Products = VALUE(Catalog.Products.EmptyRef)
		|	AND Goods.PackingList = VALUE(Document.PackingList.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	LineNumber
		|FROM
		|	Goods";
		
		Query.SetParameter("Goods",
			ThisObject.Goods.Unload(,"LineNumber, Barcode, Products, PackingList, PackingListParent"));
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ErrorText = NStr("vi = 'Chưa điền cột ""Mặt hàng"" trong danh sách ""Hàng hóa"".';
							|ru = 'Не заполнена колонка ""Номенклатура"" в списке ""Товары"".';
							|en = 'Column ""Items"" in the ""Goods"" list is not filled in.'; fa = 'Column ""Items"" in the ""Goods"" list is not filled in.';
							|it = 'La colonna ""Nomenclatura"" nell''elenco ""Merci"" non è compilata.';
							|pl = 'Nie jest wypełniona kolumna ""Wykaz towarów"" na liście ""Wiersze pozycji"".';
							|tr = '""Ürünler"" listesinde ""Öğe"" sütunu doldurulmadı.'");
			Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "Products");
			CommonClientServer.MessageToUser(ErrorText, , Field, "Object", Cancel);
		EndDo;
		
	EndIf;
	
	If WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient
		Or WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipientNotUsed Then
		NotCheckedAttributeArray.Add("ReferenceOrder");
		NotCheckedAttributeArray.Add("BusinessOperation");
	ElsIf WarehouseOperation = Enums.WarehouseTransactions.GoodsReceiptByOtherTransactions Then
		NotCheckedAttributeArray.Add("Sender");
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.OutputLineNumbers = Not UsePackingLists;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsReceiptNote),
												Cancel,
												NotCheckedAttributeArray);
	If RecordOfAPreviouslyReceivedLot Then
		
		QualityControl.ProcessingVerificationOfFillingInSurplusDocument(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			"Goods",
			NStr("vi = 'Hàng hóa';
				|ru = 'Товары';
				|en = 'Items'; fa = 'اقلام';
				|it = 'Merci';
				|pl = 'Wiersze pozycji';
				|tr = 'Ürünler'"),
			SubjectToUnlocking,
			False);
		
	Else
		
		QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			"Goods",
			NStr("vi = 'Hàng hóa';
				|ru = 'Товары';
				|en = 'Items'; fa = 'اقلام';
				|it = 'Merci';
				|pl = 'Wiersze pozycji';
				|tr = 'Ürünler'"),
			Undefined);
		
	EndIf;
	
	If Not Status = Enums.GoodsReceiptNoteStatuses.ToReceive
		And Not Status = Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired Then
		PackingListsServer.CheckFillingOfPMWithPackingLists(ThisObject, CheckedAttributes, NotCheckedAttributeArray, Cancel);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckPossibilityOfRounding = False;
	CheckParameters.CheckCompletenessOfProductLocations = True;
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
		
	WarehousesServer.CheckWarehouseOrder(Warehouse, Date, "OnReceipt", Cancel);
	
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInItemsByItemsDue(TypeOfFilling, DateOfReceipt) Export
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date);
	
	If WarehouseOperation = Enums.WarehouseTransactions.ReceivingByTransfer Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	GoodsToReceive.Products		AS Products,
		|	GoodsToReceive.Characteristic	AS Characteristic,
		|	COUNT(DISTINCT GoodsToReceive.Purpose)	AS Purpose
		|INTO DestinationsOfGoods
		|FROM
		|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.Warehouse = &Warehouse
		|	AND GoodsToReceive.Sender = &Sender
		|	AND GoodsToReceive.DocumentInflow = &ReferenceOrder
		// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
		// then you need to accept it, if not, then all goods orders.
		|	AND (GoodsToReceive.ControlledLotReference = &ControlledLotReference
		|			OR GoodsToReceive.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))
		|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|GROUP BY
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Products
		|HAVING
		|	SUM(GoodsToReceive.GoodsReceiptNotesToRegister) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DestinationsOfGoods.Products		AS Products,
		|	DestinationsOfGoods.Characteristic	AS Characteristic,
		|	DestinationsOfGoods.Purpose		AS Purpose
		|FROM
		|	DestinationsOfGoods AS DestinationsOfGoods
		|WHERE
		|	DestinationsOfGoods.Purpose > 1";
		
		Query.SetParameter("ReferenceOrder",	ReferenceOrder);
		Query.SetParameter("ControlledLotReference", ControlledLotReference);
		Query.SetParameter("Sender",	Sender);
		Query.SetParameter("Warehouse",			Warehouse);
		
		OneProductAssignment = Query.Execute().IsEmpty();
		
		If OneProductAssignment
			And WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Sender, DateOfReceipt)
			And Not Constants.GoodsReceiptOption.Get() = Enums.GoodsReceiptOptions.SplitByInvoicesOnly Then
			
			Query = New Query;
			
			QueryText =
			"SELECT
			|	GoodsToReceive.Products			AS Products,
			|	GoodsToReceive.Characteristic		AS Characteristic,
			|	GoodsToReceive.Purpose			AS Purpose,
			|	SUM(GoodsToReceive.Count)	AS Count
			|INTO ProcessedGoods
			|FROM
			|	(SELECT
			|		GoodsToReceive.Products		AS Products,
			|		GoodsToReceive.Characteristic	AS Characteristic,
			|		GoodsToReceive.Purpose		AS Purpose,
			|		GoodsToReceive.GoodsReceiptNotesToRegisterBalance - GoodsToReceive.AcceptsBalance AS Count
			|	FROM
			|		AccumulationRegister.GoodsToReceive.Balance(
			|				&DateOfRemainingGoods,
			|				DocumentInflow = &ReferenceOrder
			// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
			// then you need to accept it, if not, then all goods orders.
			|				AND (ControlledLotReference = &ControlledLotReference
			|					OR ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))
			|				AND Warehouse = &Warehouse
			|				AND Sender = &Sender) AS GoodsToReceive
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsToReceive.Products		AS Products,
			|		GoodsToReceive.Characteristic	AS Characteristic,
			|		GoodsToReceive.Purpose		AS Purpose,
			|		CASE
			|			WHEN GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
			|				-GoodsToReceive.GoodsReceiptNotesToRegister
			|			ELSE GoodsToReceive.GoodsReceiptNotesToRegister
			|		END - CASE
			|			WHEN GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
			|				- GoodsToReceive.Accepts
			|			ELSE GoodsToReceive.Accepts
			|		END								AS Count
			|	FROM
			|		AccumulationRegister.GoodsToReceive AS GoodsToReceive
			|	WHERE
			|		GoodsToReceive.Active
			|		AND GoodsToReceive.Warehouse = &Warehouse
			|		AND GoodsToReceive.Recorder = &Ref
			|		AND GoodsToReceive.DocumentInflow = &ReferenceOrder
			// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
			// then you need to accept it, if not, then all goods orders.
			|		AND (GoodsToReceive.ControlledLotReference = &ControlledLotReference
			|			OR GoodsToReceive.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))
			|) AS GoodsToReceive
			|
			|GROUP BY
			|	GoodsToReceive.Products,
			|	GoodsToReceive.Characteristic,
			|	GoodsToReceive.Purpose
			|
			|HAVING
			|	SUM(GoodsToReceive.Count) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 1
			|SELECT
			|	Products_From_Orders.Ref				AS Ref,
			|	Products_From_Orders.Products			AS Products,
			|	Products_From_Orders.Characteristic		AS Characteristic,
			|	SUM(Products_From_Orders.Count)	AS Count
			|INTO ShippedGoodsByOrder
			|FROM
			|	Document.GoodsIssueNote.GoodsByReferences AS Products_From_Orders
			|		INNER JOIN Document.GoodsIssueNote AS ExpenseOrder
			|		ON Products_From_Orders.Ref = ExpenseOrder.Ref
			|
			|WHERE
			|	ExpenseOrder.Posted
			|	AND ExpenseOrder.Warehouse = &Sender
			|	AND ExpenseOrder.ControlledLotReference = &ControlledLotReference
			|	AND Products_From_Orders.ReferenceOrder = &ReferenceOrder
			|	AND ExpenseOrder.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_)
			|
			|GROUP BY
			|	Products_From_Orders.Ref,
			|	Products_From_Orders.Products,
			|	Products_From_Orders.Characteristic
			|
			|INDEX BY
			|	Ref,
			|	Products,
			|	Characteristic
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 2
			|SELECT
			|	ShippedGoods.Products				AS Products,
			|	ShippedGoods.Characteristic			AS Characteristic,
			|	ShippedGoods.Package					AS Package,
			|	SUM(ShippedGoods.Count)			AS Count
			|INTO ShippedGoods
			|FROM
			|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
			|		INNER JOIN ShippedGoodsByOrder AS GoodsByReferences
			|		ON ShippedGoods.Ref = GoodsByReferences.Ref
			|			AND ShippedGoods.Products = GoodsByReferences.Products
			|			AND ShippedGoods.Characteristic = GoodsByReferences.Characteristic
			|
			|WHERE
			|	NOT ShippedGoods.ThisIsAPackingList
			|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
			|
			|GROUP BY
			|	ShippedGoods.Products,
			|	ShippedGoods.Characteristic,
			|	ShippedGoods.Package
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 3
			|SELECT
			|	BalanceOfGoods.Products					AS Products,
			|	BalanceOfGoods.Characteristic				AS Characteristic,
			|	BalanceOfGoods.Package						AS Package,
			|	SUM(BalanceOfGoods.Count)			AS Count
			|INTO BalanceOfShippedGoods
			|FROM
			|	(SELECT
			|		ShippedGoods.Products		AS Products,
			|		ShippedGoods.Characteristic	AS Characteristic,
			|		ShippedGoods.Package			AS Package,
			|		GoodsByReferences.Count	AS Count
			|	FROM
			|		ShippedGoods AS ShippedGoods
			|			INNER JOIN ShippedGoodsByOrder AS GoodsByReferences
			|			ON ShippedGoods.Products = GoodsByReferences.Products
			|				AND ShippedGoods.Characteristic = GoodsByReferences.Characteristic
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsToReceive.Products			AS Products,
			|		GoodsToReceive.Characteristic		AS Characteristic,
			|		GoodsToReceive.Package				AS Package,
			|		-GoodsToReceive.Count			AS Count
			|	FROM
			|		Document.GoodsReceiptNote.Goods AS GoodsToReceive
			|			INNER JOIN Document.GoodsReceiptNote AS ReceiptGoodsOrder
			|			ON GoodsToReceive.Ref = ReceiptGoodsOrder.Ref
			|	
			|	WHERE
			|		ReceiptGoodsOrder.Posted
			|		AND ReceiptGoodsOrder.Ref <> &Ref
			|		AND ReceiptGoodsOrder.Warehouse = &Sender
			|		AND ReceiptGoodsOrder.ControlledLotReference = &ControlledLotReference
			|		AND NOT GoodsToReceive.ThisIsAPackingList
			|		AND ReceiptGoodsOrder.ReferenceOrder = &ReferenceOrder) AS BalanceOfGoods
			|
			|GROUP BY
			|	BalanceOfGoods.Products,
			|	BalanceOfGoods.Characteristic,
			|	BalanceOfGoods.Package
			|
			|HAVING
			|	SUM(BalanceOfGoods.Count) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Package
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 4
			|SELECT
			|	BalanceOfGoods.Products			AS Products,
			|	BalanceOfGoods.Characteristic		AS Characteristic,
			|	MIN(BalanceOfGoods.Count)	AS Count
			|INTO BalanceOfShippedGoodsByCommodityPlaces
			|FROM
			|	BalanceOfShippedGoods AS BalanceOfGoods
			|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
			|		ON BalanceOfGoods.Package = Packages.Ref
			|
			|WHERE
			|	NOT Packages.DeletionMark
			|	AND Packages.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
			|
			|GROUP BY
			|	BalanceOfGoods.Products,
			|	BalanceOfGoods.Characteristic
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 5
			|SELECT
			|	BalanceOfGoods.Products		AS Products,
			|	BalanceOfGoods.Characteristic	AS Characteristic,
			|	SUM(CASE
			|		WHEN BalanceOfGoods.Count >= GoodsToReceive.Count
			|			THEN GoodsToReceive.Count
			|		ELSE BalanceOfGoods.Count
			|	END)							AS Count
			|INTO DemandOfGoodsByCommodityPlaces
			|FROM
			|	BalanceOfShippedGoodsByCommodityPlaces AS BalanceOfGoods
			|		INNER JOIN ProcessedGoods AS GoodsToReceive
			|		ON BalanceOfGoods.Products = GoodsToReceive.Products
			|			AND BalanceOfGoods.Characteristic = GoodsToReceive.Characteristic
			|
			|GROUP BY
			|	BalanceOfGoods.Products,
			|	BalanceOfGoods.Characteristic
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 6
			|SELECT
			|	BalanceOfGoods.Products		AS Products,
			|	BalanceOfGoods.Characteristic	AS Characteristic,
			|	BalanceOfGoods.Package			AS Package,
			|	SUM(CASE
			|		WHEN BalanceOfGoods.Count >= GoodsToReceive.Count
			|			THEN GoodsToReceive.Count
			|		ELSE BalanceOfGoods.Count
			|	END)							AS Count
			|INTO NeedForGoodsWithoutCommodityPlaces
			|FROM
			|	BalanceOfShippedGoods AS BalanceOfGoods
			|		INNER JOIN ProcessedGoods AS GoodsToReceive
			|		ON BalanceOfGoods.Products = GoodsToReceive.Products
			|			AND BalanceOfGoods.Characteristic = GoodsToReceive.Characteristic
			|
			|WHERE
			|	ISNULL(BalanceOfGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
			|
			|GROUP BY
			|	BalanceOfGoods.Products,
			|	BalanceOfGoods.Characteristic,
			|	BalanceOfGoods.Package
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Package
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 7
			|SELECT
			|	NeedOfGoods.Products		AS Products,
			|	NeedOfGoods.Characteristic	AS Characteristic,
			|	BalanceOfGoods.Package				AS Package,
			|	NeedOfGoods.Count		AS Count,
			|	0									AS PackingPriority
			|INTO NeedOfGoods
			|FROM
			|	DemandOfGoodsByCommodityPlaces AS NeedOfGoods
			|		INNER JOIN BalanceOfShippedGoods AS BalanceOfGoods
			|		ON NeedOfGoods.Products = BalanceOfGoods.Products
			|			AND NeedOfGoods.Characteristic = BalanceOfGoods.Characteristic
			|
			|WHERE
			|	ISNULL(BalanceOfGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
			|
			|UNION ALL
			|
			|SELECT
			|	NeedOfGoods.Products			AS Products,
			|	NeedOfGoods.Characteristic		AS Characteristic,
			|	NeedOfGoods.Package				AS Package,
			|	NeedOfGoods.Count			AS Count,
			|	1										AS PackingPriority
			|FROM
			|	NeedForGoodsWithoutCommodityPlaces AS NeedOfGoods
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Package";
			
			If TypeOfFilling = "Products"
				Or TypeOfFilling = "ProductsQuantity_" Then
				
				QueryText = QueryText + Common.QueryBatchSeparator() + "
				|SELECT
				|	0										AS LineNumber,
				|	NeedOfGoods.Products			AS Products,
				|	NeedOfGoods.Characteristic		AS Characteristic,
				|	NeedOfGoods.Package				AS Package,
				|	NeedOfGoods.PackingPriority	AS PackingPriority,
				|	CASE
				|		WHEN &FillQuantity
				|			THEN NeedOfGoods.Count
				|		ELSE 0
				|	END									AS Count
				|INTO GoodsTable
				|FROM
				|	NeedOfGoods AS NeedOfGoods
				|
				|INDEX BY
				|	Products,
				|	Characteristic,
				|	Package";
				
			ElsIf TypeOfFilling = "Count" Then
				
				QueryText = QueryText + Common.QueryBatchSeparator() + "
				|SELECT
				|	TableOfGoods.LineNumber		AS LineNumber,
				|	TableOfGoods.Products		AS Products,
				|	TableOfGoods.Characteristic	AS Characteristic
				|INTO TableOfNomeclatureForRequest
				|FROM
				|	&TableOfGoods AS TableOfGoods
				|
				|WHERE
				|	TableOfGoods.Products <> VALUE(Catalog.Products.EmptyRef)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	MIN(TableOfGoods.LineNumber)	AS LineNumber,
				|	TableOfGoods.Products			AS Products,
				|	TableOfGoods.Characteristic		AS Characteristic
				|INTO TableOfGoods
				|FROM
				|	TableOfNomeclatureForRequest AS TableOfGoods
				|
				|GROUP BY
				|	TableOfGoods.Products,
				|	TableOfGoods.Characteristic
				|
				|INDEX BY
				|	Products,
				|	Characteristic
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TableOfGoods.LineNumber		AS LineNumber,
				|	TableOfGoods.Products		AS Products,
				|	TableOfGoods.Characteristic	AS Characteristic,
				|	ISNULL(NeedOfGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
				|	ISNULL(NeedOfGoods.Count, 0) AS Count,
				|	ISNULL(NeedOfGoods.PackingPriority, 1) AS PackingPriority
				|INTO GoodsTable
				|FROM
				|	TableOfGoods AS TableOfGoods
				|		LEFT JOIN NeedOfGoods AS NeedOfGoods
				|		ON TableOfGoods.Products = NeedOfGoods.Products
				|			AND TableOfGoods.Characteristic = NeedOfGoods.Characteristic
				|
				|INDEX BY
				|	Products,
				|	Characteristic";
				
				UnloadedColumns = "LineNumber, Products, Characteristic, Purpose";
				
				Query.SetParameter("TableOfGoods", Goods.Unload(, UnloadedColumns));
				
			EndIf;
			
			QueryText = QueryText + Common.QueryBatchSeparator() + "
			|SELECT DISTINCT
			|	GoodsToReceive.Products		AS Products,
			|	GoodsToReceive.Characteristic	AS Characteristic,
			|	GoodsToReceive.Purpose		AS Purpose
			|INTO DestinationsOfGoods
			|FROM
			|	ProcessedGoods AS GoodsToReceive
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GoodsTable.LineNumber			AS LineNumber,
			|	GoodsTable.Products			AS Products,
			|	GoodsTable.Characteristic		AS Characteristic,
			|	ISNULL(DestinationsOfGoods.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
			|	GoodsTable.Package				AS Package,
			|	GoodsTable.Count			AS Count,
			|	0									AS NumberOfPackages,
			|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
			|	GoodsTable.PackingPriority		AS PackingPriority
			|FROM
			|	GoodsTable AS GoodsTable
			|		LEFT JOIN DestinationsOfGoods AS DestinationsOfGoods
			|		ON GoodsTable.Products = DestinationsOfGoods.Products
			|			AND GoodsTable.Characteristic = DestinationsOfGoods.Characteristic
			|
			|WHERE
			|	GoodsTable.Count > 0
			|
			|ORDER BY
			|	GoodsTable.LineNumber,
			|	GoodsTable.Products.Description,
			|	GoodsTable.Characteristic.Description,
			|	Purpose,
			|	GoodsTable.PackingPriority,
			|	GoodsTable.Package.Description
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GoodsToReceive.Products		AS Products,
			|	GoodsToReceive.Characteristic	AS Characteristic,
			|	GoodsToReceive.Purpose		AS Purpose,
			|	GoodsToReceive.Count		AS Count
			|FROM
			|	ProcessedGoods AS GoodsToReceive
			|
			|ORDER BY
			|	GoodsToReceive.Products.Description,
			|	GoodsToReceive.Characteristic.Description,
			|	GoodsToReceive.Purpose";
			
			QueryText = StrReplace(QueryText,
										"&QueryTextPackagingFactor",
										Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
											"GoodsTable.Package",
											"GoodsTable.Products"));
			
			Query.Text = QueryText;
			Query.SetParameter("Ref",					Ref);
			Query.SetParameter("ReferenceOrder",			ReferenceOrder);
			Query.SetParameter("ControlledLotReference",	ControlledLotReference);
			Query.SetParameter("Sender",			Sender);
			Query.SetParameter("Warehouse",					Warehouse);
			Query.SetParameter("FillQuantity",	TypeOfFilling <> "Products");
			
			If ValueIsFilled(DateOfReceipt) Then
				Query.SetParameter("DateOfRemainingGoods", EndOfDay(DateOfReceipt));
			Else
				Query.SetParameter("DateOfRemainingGoods", DateOfReceipt);
			EndIf;
			
			SetPrivilegedMode(True);
			Result = Query.ExecuteBatch();
			SetPrivilegedMode(False);
			
			GoodsForDistribution = Result[Result.UBound() - 1].Unload(); // ValueTable
			
			If GoodsForDistribution.Count() > 0 Then
				
				TableOfGoods = GoodsForDistribution.CopyColumns();
				
				GoodsForDistribution.Indexes.Add("Products, Characteristic, Purpose");
				
				StockBalance = Result[Result.UBound()].Unload(); // ValueTable
				StockBalance.Indexes.Add("Products, Characteristic, Purpose");
				
				For Each RemainderLine_ In StockBalance Do
					
					CurPriority	= Undefined;
					CountBalance	= RemainderLine_.Count;
					
					Filter = New Structure("Products, Characteristic, Purpose");
					FillPropertyValues(Filter, RemainderLine_);
					
					DistributionLines = GoodsForDistribution.FindRows(Filter);
					
					For Each DistributableString In DistributionLines Do
						
						If CountBalance <= 0 Then
							Break;
						EndIf;
						
						If CurPriority = Undefined Then
							CurPriority = DistributableString.PackingPriority;
						ElsIf DistributableString.PackingPriority
							And CurPriority <> DistributableString.PackingPriority Then
							
							Count = Min(CountBalance, DistributableString.Count);
							
							NewRow = TableOfGoods.Add();
							FillPropertyValues(NewRow, DistributableString);
							
							NewRow.Count			= Count;
							NewRow.NumberOfPackages	= Count / DistributableString.PackagingFactor;
							
							CountBalance = CountBalance - Count;
							
						EndIf;
						
						Count = Min(CountBalance, DistributableString.Count);
						
						NewRow = TableOfGoods.Add();
						FillPropertyValues(NewRow, DistributableString);
						
						NewRow.Count			= Count;
						NewRow.NumberOfPackages	= Count / DistributableString.PackagingFactor;
						
						If CurPriority Then
							CountBalance = CountBalance - Count;
						EndIf;
						
					EndDo;
					
				EndDo;
				
				TableOfGoods.Sort("LineNumber");
				Goods.Load(TableOfGoods);
				
			Else
				
				If WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Sender) Then
					MessageText = NStr("vi = 'Không có hàng hóa để điền theo lệnh ""%ReferenceOrder%"".
											|Có thể là vẫn chưa tạo phiếu xuất kho từ kho ""%Sender%"".';
											|ru = 'Нет товаров для заполнения по распоряжению ""%ReferenceOrder%"".
											|Возможно еще не создан расходный ордер со склада ""%Sender%"".';
											|en = 'No goods to fill in under the ""%ReferenceOrder%"" reference.
											|The goods issue note from the ""%Sender%"" warehouse might not have been created yet.'; fa = 'No goods to fill in under the ""%ReferenceOrder%"" reference.
											|The goods issue note from the ""%Sender%"" warehouse might not have been created yet.';
											|it = 'Non ci sono prodotti da compilare per disposizione ""%ReferenceOrder%"".
											| Il mandato di pagamento dal magazzino ""%Sender%"" potrebbe non essere stato ancora creato.';
											|pl = 'Brak towarów do wypełnienia według zamówienia ""%ReferenceOrder%"".
											|Możliwe że jeszcze nie zostało utworzone zlecenie wydania z magazynu%Sender%ь%"".';
											|tr = '""%ReferenceOrder%"" emiri için doldurulacak ürün mevcut değil.
											|Belki ""%Sender%"" ambarından ambar çıkış fişi henüz oluşturulmamıştır.'");
					MessageText = StrReplace(MessageText, "%ReferenceOrder%",	ReferenceOrder);
					MessageText = StrReplace(MessageText, "%Sender%",	Sender);
					
					CommonClientServer.MessageToUser(MessageText, ThisObject, "ReferenceOrder");
				EndIf;
				
			EndIf;
			
			If TypeOfFilling = "Count"
				Or TypeOfFilling = "ProductsQuantity_" Then
				
				If UseBinLocationWarehousing Then
					SplitByPackagesForReference();
				EndIf;
				
			EndIf;
			
			TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(Goods);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref",			Ref);
	Query.SetParameter("ReferenceOrder",	ReferenceOrder);
	Query.SetParameter("ControlledLotReference", ControlledLotReference);
	Query.SetParameter("Sender",	Sender);
	Query.SetParameter("Warehouse",			Warehouse);
	
	If ValueIsFilled(DateOfReceipt) Then
		Query.SetParameter("DateOfRemainingGoods", EndOfDay(DateOfReceipt));
	Else
		Query.SetParameter("DateOfRemainingGoods", DateOfReceipt);
	EndIf;
	
	If TypeOfFilling = "Products"
		Or TypeOfFilling = "ProductsQuantity_" Then
		
		Goods.Clear();
		
		QueryText =
		"SELECT
		|	GoodsToReceive.Products		AS Products,
		|	GoodsToReceive.Characteristic	AS Characteristic,
		|	CASE
		|		WHEN ISNULL(GoodsToReceive.Purpose.RecordsInWarehouseRegisters, FALSE)
		|			THEN GoodsToReceive.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END								AS Purpose,
		|	CASE
		|		WHEN &FillQuantity
		|			THEN SUM(GoodsToReceive.Count)
		|		ELSE 0
		|	END								AS Count,
		|	CASE
		|		WHEN &FillQuantity
		|			THEN SUM(GoodsToReceive.Count)
		|		ELSE 0
		|	END								AS NumberOfPackages
		|FROM
		|	(SELECT
		|		GoodsToReceive.Products		AS Products,
		|		GoodsToReceive.Characteristic	AS Characteristic,
		|		GoodsToReceive.Purpose		AS Purpose,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterBalance - GoodsToReceive.AcceptsBalance AS Count
		|	FROM
		|		AccumulationRegister.GoodsToReceive.Balance(
		|				&DateOfRemainingGoods,
		|				DocumentInflow = &ReferenceOrder
		// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
		// then you need to accept it, if not, then all goods orders.
		|				AND (ControlledLotReference = &ControlledLotReference
		|					OR ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))
		|				AND Warehouse = &Warehouse
		|				AND Sender = &Sender) AS GoodsToReceive
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsToReceive.Products		AS Products,
		|		GoodsToReceive.Characteristic	AS Characteristic,
		|		GoodsToReceive.Purpose		AS Purpose,
		|		CASE
		|			WHEN GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -GoodsToReceive.GoodsReceiptNotesToRegister
		|			ELSE GoodsToReceive.GoodsReceiptNotesToRegister
		|		END - CASE
		|			WHEN GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN - GoodsToReceive.Accepts
		|			ELSE GoodsToReceive.Accepts
		|		END								AS Count
		|	FROM
		|		AccumulationRegister.GoodsToReceive AS GoodsToReceive
		|	
		|	WHERE
		|		GoodsToReceive.Active
		|		AND GoodsToReceive.Warehouse = &Warehouse
		|		AND GoodsToReceive.Recorder = &Ref
		// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
		// then you need to accept it, if not, then all goods orders.
		|		AND (GoodsToReceive.ControlledLotReference = &ControlledLotReference
		|			OR GoodsToReceive.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))
		|		AND GoodsToReceive.DocumentInflow = &ReferenceOrder) AS GoodsToReceive
		|
		|GROUP BY
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	CASE
		|		WHEN ISNULL(GoodsToReceive.Purpose.RecordsInWarehouseRegisters, FALSE)
		|			THEN GoodsToReceive.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END
		|
		|HAVING
		|	SUM(GoodsToReceive.Count) > 0
		|
		|ORDER BY
		|	Products.Description,
		|	Characteristic.Description,
		|	Purpose";
		
		Query.Text = QueryText;
		Query.SetParameter("FillQuantity", TypeOfFilling <> "Products");
		
		Result = Query.Execute();
		
		If Not Result.IsEmpty() Then
			Goods.Load(Result.Unload());
			ProductsServer.SplitProductsByProductLocations(Goods);
		Else
			MessageText = NStr("vi = 'Không có hàng hóa để điền theo lệnh ""%ReferenceOrder%"" từ người gửi %Sender%.';
								|ru = 'Нет товаров для заполнения по распоряжению ""%ReferenceOrder%"" от отправителя %Sender%.';
								|en = 'No goods to fill in according to the %ReferenceOrder% reference from the %Sender% sender.'; fa = 'No goods to fill in according to the %ReferenceOrder% reference from the %Sender% sender.';
								|it = 'Non ci sono prodotti da compilare per disposizione ""%ReferenceOrder%"" dal mittente %Sender%.';
								|pl = 'Brak towarów do wypełnienia według zamówienia ""%ReferenceOrder%"" od nadawcy %Sender%.';
								|tr = 'Gönderen ""%ReferenceOrder%"" emrine göre doldurulacak ürün mevcut değil %Sender%.'");
			MessageText = StrReplace(MessageText, "%ReferenceOrder%",	ReferenceOrder);
			MessageText = StrReplace(MessageText, "%Sender%",	Sender);
			
			CommonClientServer.MessageToUser(MessageText, ThisObject, "ReferenceOrder");
		EndIf;
		
	Else
		
		QueryText =
		"SELECT
		|	Table.LineNumber		AS LineNumber,
		|	Table.Products	AS Products,
		|	Table.Characteristic	AS Characteristic,
		|	Table.Purpose		AS Purpose
		|INTO RequestProductTable
		|FROM
		|	&Table AS Table
		|
		|WHERE
		|	Table.Products <> VALUE(Catalog.Products.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(Table.LineNumber)	AS LineNumber,
		|	Table.Products			AS Products,
		|	Table.Characteristic			AS Characteristic,
		|	Table.Purpose				AS Purpose
		|INTO ProductsTable
		|FROM
		|	RequestProductTable AS Table
		|
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsToReceive.Products		AS Products,
		|	GoodsToReceive.Characteristic	AS Characteristic,
		|	GoodsToReceive.Purpose		AS Purpose,
		|	GoodsToReceive.GoodsReceiptNotesToRegisterBalance - GoodsToReceive.AcceptsBalance AS Count
		|INTO GoodsToReceive
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(
		|			&DateOfRemainingGoods,
		|			DocumentInflow = &ReferenceOrder
		// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
		// then you need to accept it, if not, then all goods orders.
		|			AND (ControlledLotReference = &ControlledLotReference
		|				OR ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))
		|			AND Warehouse = &Warehouse
		|			AND Sender = &Sender) AS GoodsToReceive
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsToReceive.Products		AS Products,
		|	GoodsToReceive.Characteristic	AS Characteristic,
		|	GoodsToReceive.Purpose		AS Purpose,
		|	CASE
		|		WHEN GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -GoodsToReceive.GoodsReceiptNotesToRegister
		|		ELSE GoodsToReceive.GoodsReceiptNotesToRegister
		|	END - CASE
		|		WHEN GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -GoodsToReceive.Accepts
		|		ELSE GoodsToReceive.Accepts
		|	END								AS Count
		|FROM
		|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
		|
		|WHERE
		|	GoodsToReceive.Active
		|	AND GoodsToReceive.Warehouse = &Warehouse
		|	AND GoodsToReceive.Recorder = &Ref
		// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
		// then you need to accept it, if not, then all goods orders.
		|	AND (GoodsToReceive.ControlledLotReference = &ControlledLotReference
		|		OR GoodsToReceive.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))
		|	AND GoodsToReceive.DocumentInflow = &ReferenceOrder
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(ProductsTable.LineNumber)	AS LineNumberOld,
		|	ProductsTable.Products			AS Products,
		|	ProductsTable.Characteristic			AS Characteristic,
		|	ProductsTable.Purpose				AS Purpose,
		|	SUM(ISNULL(GoodsToReceive.Count, 0))	AS Count,
		|	SUM(ISNULL(GoodsToReceive.Count, 0))	AS NumberOfPackages
		|FROM
		|	ProductsTable AS ProductsTable
		|		LEFT JOIN GoodsToReceive AS GoodsToReceive
		|		ON ProductsTable.Products = GoodsToReceive.Products
		|			AND ProductsTable.Characteristic = GoodsToReceive.Characteristic
		|			AND ProductsTable.Purpose = GoodsToReceive.Purpose
		|
		|GROUP BY
		|	ProductsTable.Products,
		|	ProductsTable.Characteristic,
		|	ProductsTable.Purpose
		|
		|ORDER BY
		|	LineNumberOld";
		
		Query.Text = QueryText;
		Query.SetParameter("Table", Goods.Unload());
		
		Goods.Load(Query.Execute().Unload());
		ProductsServer.SplitProductsByProductLocations(Goods);
		
	EndIf;
	
	If TypeOfFilling = "Count"
		Or TypeOfFilling = "ProductsQuantity_" Then
		
		If UseBinLocationWarehousing Then
			SplitByPackagesForReference();
		EndIf;
		
	EndIf;
	
	TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(Goods);
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure SplitByPackagesForReference()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.LineNumber AS LineNumber,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	Table.Purpose AS Purpose
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
	|	InternalQuery.PackingUnitPresentation
	|FROM
	|	(SELECT
	|		ProductsTable.Products AS Products,
	|		ProductsTable.Count AS Count,
	|		FALSE AS ItIsACargoItem,
	|		ProductsTable.LineNumber AS LineNumber,
	|		ProductsTable.Characteristic AS Characteristic,
	|		ProductsTable.Purpose AS Purpose,
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
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages",
			"ProductsTable.Products"));
	
	ProductsTable = Goods.Unload();
	Query.SetParameter("Table",ProductsTable);
	
	Goods.Clear();
	
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	CurRowNumber = Undefined;
	CurProducts = Undefined;
	CurCharacteristic = Undefined;
	CurPurpose = Undefined;
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
			EndIf;
			
			CurRowNumber              = Selection.LineNumber;
			CurProducts             = Selection.Products; 
			CurCharacteristic           = Selection.Characteristic;
			CurPurpose               = Selection.Purpose;
			
			If Selection.ItIsACargoItem Then
				
				NewRow = Goods.Add();
				NewRow.Count = Selection.Count;
				NewRow.NumberOfPackages =  Selection.Count * Selection.QuantityPerPackage;
				NewRow.Package = Selection.Package;
				
				NewRow.Products = CurProducts;
				NewRow.Characteristic = CurCharacteristic;
				NewRow.Purpose = CurPurpose;
				
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
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible          = Users.CurrentUser();
	MetadataObjectStatus = Metadata().Attributes.Status; // MetadataObjectAttribute
	Status                 = MetadataObjectStatus.FillValue;
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	If ValueIsFilled(Warehouse) Then
		If WarehousesServer.UseBinLocationWarehousing(Warehouse,Premise,Date) Then
			ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Warehouse,Premise,ReceivingArea);
		EndIf;
	EndIf;
	
	RecordOfAPreviouslyReceivedLot = False;
	SubjectToUnlocking = True;
	
	If ValueIsFilled(ControlledLotReference) Then
		SetPrivilegedMode(True);
		PartyDetails = Common.ObjectAttributesValues(
			ControlledLotReference,
			"Lot,ScheduleGoodsUnlock");
		SetPrivilegedMode(False);
		If PartyDetails.ScheduleGoodsUnlock <> Undefined Then // not a broken link
			RecordOfAPreviouslyReceivedLot = PartyDetails.Lot <> ReferenceOrder; // the order is mixing, and the Lot reference is not moving the blocked goods
			SubjectToUnlocking = PartyDetails.ScheduleGoodsUnlock;
		EndIf;
	EndIf;
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckOrderWarehouse(Cancel)
	
	If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Warehouse, Date) Then
		
		Cancel = True;
		
		MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" vào ngày %Date% không sử dụng sơ đồ hai pha khi tiếp nhận.';
							|ru = 'На складе ""%Warehouse%"" на %Date% не используется ордерная схема при поступлении.';
							|en = 'Warehouse management is not used in warehouse ""%Warehouse%"" on receipt as of %Date%.'; fa = 'Warehouse management is not used in warehouse ""%Warehouse%"" on receipt as of %Date%.';
							|it = 'Nel magazzino ""%Warehouse%"" al %Date% non viene utilizzato lo schema dei mandati durante l''arrivo.';
							|pl = 'W magazynie ""%Warehouse%"" na dzień %Date% nie jest używany schemat zleceniowy podczas wpływu.';
							|tr = 'Ambarda ""%Warehouse%"", %Date%''da giriş sırasında ambar yönetimi kullanılmıyor.'");
		MessageText = StrReplace(MessageText,"%Warehouse%",Warehouse);
		MessageText = StrReplace(MessageText,"%Date%",Format(Date, "DLF=D"));
		
		CommonClientServer.MessageToUser(MessageText, Ref);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf