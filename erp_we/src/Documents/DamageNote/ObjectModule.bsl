#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If WarehousesServer.UseBinLocationWarehousing(Warehouse,Premise,Date) Then
		CheckCellLock(Cancel);
		If Cancel Then
			Return;
		EndIf;
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DamageNote));
	
	If WriteMode = DocumentWriteMode.Posting Then
		CheckOrderWarehouse(Cancel);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	InitializeDocument();

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseBinLocationWarehousing(Warehouse,Premise,Date) Then
		NotCheckedAttributeArray.Add("Goods.Cell");
		NotCheckedAttributeArray.Add("Goods.Package");
		NotCheckedAttributeArray.Add("Goods.PackagingReceipt");
	ElsIf Not GetFunctionalOption("UseItemPackages") Then
		NotCheckedAttributeArray.Add("Goods.Package");
		NotCheckedAttributeArray.Add("Goods.PackagingReceipt");
		
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
		
		Common.MessageToUser(MessageText, , , , Cancel);
	Else
		FieldNamesWithSuffix = New Structure;
		FieldNamesWithSuffix.Insert("Products",	"ProductsRecordingAsReceived");
		FieldNamesWithSuffix.Insert("Package",		"PackagingReceipt");
		
		CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
		CheckParameters.FieldNamesWithSuffix = FieldNamesWithSuffix;
		
		ProductsServer.CheckFillingOfPackages(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	EndIf;
	
	If Not WarehousesServer.UseWarerooms(Warehouse, Date) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DamageNote),
												Cancel,
												NotCheckedAttributeArray);
	
	AssignmentTypes = Common.ObjectsAttributeValue(Goods.UnloadColumn("Purpose"), "AssignmentType");
	ErrorTextForAssignment = NStr("vi = 'Trong trường hợp, hàng hỏng đã đặt riêng theo mục đích của người đặt gia công, cần nhập hàng ""Theo mục đích""';
									|ru = 'При порче товара, обособленного под назначение давальца, приход товара должен быть ""Под назначение""';
									|en = 'If an item assigned for the provider assignment has a stock quality change, the stock surplus must be ""For assignment""'; fa = 'If an item assigned for the provider assignment has a stock quality change, the stock surplus must be ""For assignment""';
									|it = 'In caso di usura della merce separata per assegnazione del fornitore, l''arrivo della merce deve essere ""Per assegnazione""';
									|pl = 'W przypadku uszkodzenia towaru, oddzielonego pod przeznaczenie właściciela surowców, przyjęcie towaru musi być ""Na przeznaczenie""';
									|tr = 'Ürün stok kalite değişikliği durumunda, müşterinin amacına uygun olarak ayrılması durumunda, ürünün girişi ""Atamaya uygun"" olmalıdır.'");
	
	ErrorText = NStr("vi = 'Hàng hóa có chất lượng ban đầu trùng với hàng hóa có chất lượng khác';
					|ru = 'Товар исходного качества совпадает с товаром другого качества';
					|en = 'Goods of original quality matches with goods of different quality'; fa = 'Goods of original quality matches with goods of different quality';
					|it = 'Il prodotto della qualità originale coincide con il prodotto di una qualità diversa';
					|pl = 'Towar oryginalnej jakości zbiega się z towarem innej jakości';
					|tr = 'Orijinal kalitedeki ürün uygun kalitede olmayan ürünle eşleşmektedir'");
	
	For Each RowOfTables In Goods Do
		ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'в строке %LineNumber% списка ""Товары""';
							|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
							|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
							|pl = 'w wierszu %LineNumber% listy ""Towary""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress =  StrReplace(ErrorAddress, "%LineNumber%", RowOfTables.LineNumber);
		If ValueIsFilled(RowOfTables.Products)
			And RowOfTables.Products = RowOfTables.ProductsRecordingAsReceived Then
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "ProductsRecordingAsReceived");
			CommonClientServer.MessageToUser(ErrorText + Chars.NBSp + ErrorAddress,ThisObject,Field,,Cancel);
		EndIf;
		
		If Not RowOfTables.ForAssignment
		   And AssignmentTypes.Get(RowOfTables.Purpose) = Enums.AssignmentTypes.Giveaway2_5 Then
			
			Common.MessageToUser(
				StrTemplate("%1 %2", ErrorTextForAssignment, ErrorAddress),
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "ForAssignment"),,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	If GetFunctionalOption("UseReusablePackage") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	TableOfGoods.Products,
		|	TableOfGoods.ProductsRecordingAsReceived,
		|	TableOfGoods.LineNumber
		|INTO TableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.LineNumber AS LineNumber,
		|	CAST(TableOfGoods.Products AS Catalog.Products).ItemsType AS ProductsTypeOfProducts,
		|	CAST(TableOfGoods.ProductsRecordingAsReceived AS Catalog.Products).ItemsType AS ProductsDescriptionProductsType
		|FROM
		|	TableOfGoods AS TableOfGoods
		|WHERE
		|	CAST(TableOfGoods.Products AS Catalog.Products).ItemsType <> CAST(TableOfGoods.ProductsRecordingAsReceived AS Catalog.Products).ItemsType
		|
		|ORDER BY
		|	LineNumber";	
		
		Query.SetParameter("TableOfGoods", Goods.Unload(,"LineNumber,Products,ProductsRecordingAsReceived"));
		
		Selection = Query.Execute().Select();
		
		ErrorText = NStr("vi = 'Tại dòng %LineNumber% trong danh sách ""Hàng hóa"" không trùng kiểu mặt hàng. Mặt hàng chất lượng ban đầu có kiểu %ProductsTypeOfProducts%, mặt hàng chất lượng khác có kiểu %ProductsDescriptionProductsType%.';
						|ru = 'В строке %LineNumber% списка ""Товары"" не совпадают типы номенклатуры. У номенклатуры исходхого качества тип %ProductsTypeOfProducts%, другого качества - %ProductsDescriptionProductsType%.';
						|en = 'Item types do not match in line %LineNumber% of the Item list. Items of the original quality are of the %ProductsTypeOfProducts% type; items of other quality are of the %ProductsDescriptionProductsType% type.'; fa = 'Item types do not match in line %LineNumber% of the Item list. Items of the original quality are of the %ProductsTypeOfProducts% type; items of other quality are of the %ProductsDescriptionProductsType% type.';
						|it = 'Nella riga %LineNumber% dell''elenco ""Merci"" i tipi di nomenclatura non coincidono. Il tipo di nomenclatura della qualità originale è %ProductsTypeOfProducts%, di quella della qualità diversa - %ProductsDescriptionProductsType%.';
						|pl = 'W wierszu %LineNumber% listy ""Towary"" nie odpowiadają typy produktów. Dla produktów oryginalnej jakości typ%ProductsTypeOfProducts%, innej jakości - %ProductsDescriptionProductsType%.';
						|tr = 'Ürün gamı türleri, ""Ürünler"" listesinin %LineNumber% satırında eşleşmiyor. Orijinal ürün gamı kalite türü %ProductsTypeOfProducts%, diğer kalitede - %ProductsDescriptionProductsType%.'");
		
		While Selection.Next() Do
			ErrorMessage = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber); 
			ErrorMessage = StrReplace(ErrorMessage, "%ProductsTypeOfProducts%", Selection.ProductsTypeOfProducts); 
			ErrorMessage = StrReplace(ErrorMessage, "%ProductsDescriptionProductsType%", Selection.ProductsDescriptionProductsType); 
			
			Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "ProductsRecordingAsReceived");
			CommonClientServer.MessageToUser(ErrorMessage,ThisObject,Field,,Cancel);
		EndDo;
		
	EndIf;
	
	ProductsServer.CheckTypeOfProductDescription(ThisObject,Cancel);
	
	VerifyQuantityInBaseUnits(Cancel);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckPossibilityOfRounding = False;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	WarehousesServer.CheckWarehouseOrder(Warehouse, Date, "WhenReflectingSurplusShortages", Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.GoodsIssueNote") Then
		FillInOnTheBasis(FillingData);
	Else
		InitializeDocument(FillingData);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInOnTheBasis(Basis)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ShippedGoods.Products AS OtherQualityGoods,
	|	ISNULL(AnotherQualityGoods.Products, VALUE(Catalog.Products.EmptyRef)) AS Products
	|INTO DefectiveGoods_
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		ON ShippedGoods.Products = AnotherQualityGoods.OtherQualityGoods
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality <> VALUE(Enum.QualityLevels.New)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT DISTINCT
	|	DefectiveGoods_.OtherQualityGoods AS OtherQualityGoods,
	|	DefectiveGoods_.Products     AS Products
	|INTO MatchedGoodsOrders
	|FROM
	|	DefectiveGoods_ AS DefectiveGoods_
	|		INNER JOIN Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		ON DefectiveGoods_.Products = ShippedGoods.Products
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality = VALUE(Enum.QualityLevels.New)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	QualityProducts.Products                 AS Products,
	|	COUNT(QualityProducts.OtherQualityGoods) AS LinkCount
	|INTO TableOfLinksOfQualityGoods
	|FROM
	|	MatchedGoodsOrders AS QualityProducts
	|
	|GROUP BY
	|	QualityProducts.Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	DefectiveGoods_.OtherQualityGoods         AS OtherQualityGoods,
	|	COUNT(DefectiveGoods_.Products) AS LinkCount
	|INTO TableOfLinksOfDefectiveGoodsOrders
	|FROM
	|	MatchedGoodsOrders AS DefectiveGoods_
	|
	|GROUP BY
	|	DefectiveGoods_.OtherQualityGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	DefectiveGoods_.OtherQualityGoods         AS OtherQualityGoods,
	|	COUNT(DefectiveGoods_.Products) AS LinkCount
	|INTO TableOfLinksOfDefectiveGoods
	|FROM
	|	DefectiveGoods_ AS DefectiveGoods_
	|WHERE
	|	NOT DefectiveGoods_.OtherQualityGoods IN
	|		(SELECT
	|			MatchedGoodsOrders.OtherQualityGoods
	|		FROM
	|			MatchedGoodsOrders AS MatchedGoodsOrders)
	|	AND NOT DefectiveGoods_.Products IS NULL
	|
	|GROUP BY
	|	DefectiveGoods_.OtherQualityGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT DISTINCT
	|	GoodsOfOrder.OtherQualityGoods AS OtherQualityGoods,
	|	CASE
	|		WHEN TableOfLinksOfDefectiveGoodsOrders.LinkCount = 1
	|				AND TableOfLinksOfQualityGoods.LinkCount = 1
	|			THEN GoodsOfOrder.Products
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END                         AS Products
	|INTO MatchedDefectiveGoods
	|FROM
	|	MatchedGoodsOrders AS GoodsOfOrder
	|		LEFT JOIN TableOfLinksOfDefectiveGoodsOrders AS TableOfLinksOfDefectiveGoodsOrders
	|		ON GoodsOfOrder.OtherQualityGoods = TableOfLinksOfDefectiveGoodsOrders.OtherQualityGoods
	|
	|		LEFT JOIN TableOfLinksOfQualityGoods AS TableOfLinksOfQualityGoods
	|		ON GoodsOfOrder.Products = TableOfLinksOfQualityGoods.Products
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DefectiveGoods_.OtherQualityGoods,
	|	VALUE(Catalog.Products.EmptyRef)
	|FROM
	|	DefectiveGoods_ AS DefectiveGoods_
	|WHERE
	|	DefectiveGoods_.Products IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TableOfLinksOfDefectiveGoods.OtherQualityGoods,
	|	CASE
	|		WHEN TableOfLinksOfDefectiveGoods.LinkCount = 1
	|			THEN ISNULL(DefectiveGoods_.Products, VALUE(Catalog.Products.EmptyRef))
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END
	|FROM
	|	TableOfLinksOfDefectiveGoods AS TableOfLinksOfDefectiveGoods
	|	LEFT JOIN DefectiveGoods_ AS DefectiveGoods_
	|		ON TableOfLinksOfDefectiveGoods.OtherQualityGoods = DefectiveGoods_.OtherQualityGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT DISTINCT
	|	ISNULL(DefectiveGoods_.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS OtherQualityGoods,
	|	ShippedGoods.Characteristic AS CharacteristicsDefectiveGoods,
	|	ISNULL(DefectiveGoods_.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	CASE
	|		WHEN (ShippedGoods.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					AND ShippedGoods.Products.ProductKind = DefectiveGoods_.OtherQualityGoods.ProductKind)
	|				OR (ShippedGoods.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					AND ShippedGoods.Products.ItemVariantsOwner = DefectiveGoods_.OtherQualityGoods.ItemVariantsOwner)
	|			THEN ShippedGoods.Characteristic
	|		ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	END                            AS Characteristic
	|INTO MatchedDefectiveGoodsByCharacteristics
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedDefectiveGoods AS DefectiveGoods_
	|		ON ShippedGoods.Products = DefectiveGoods_.OtherQualityGoods
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality <> VALUE(Enum.QualityLevels.New)
	|	AND ShippedGoods.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ISNULL(DefectiveGoods_.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ShippedGoods.Characteristic,
	|	ISNULL(DefectiveGoods_.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(ItemsCharacteristics.Ref, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedDefectiveGoods AS DefectiveGoods_
	|		ON ShippedGoods.Products = DefectiveGoods_.OtherQualityGoods
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON DefectiveGoods_.Products = ItemsCharacteristics.Owner
	|			AND CAST(ShippedGoods.Characteristic.Description AS STRING(500)) = CAST(ItemsCharacteristics.Description AS STRING(500))
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality <> VALUE(Enum.QualityLevels.New)
	|	AND ShippedGoods.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|	AND NOT ISNULL(ItemsCharacteristics.DeletionMark, FALSE)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT DISTINCT
	|	ISNULL(DefectiveGoods_.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS OtherQualityGoods,
	|	ShippedGoods.Package AS PackagingDefectiveGoods,
	|	ISNULL(DefectiveGoods_.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	CASE
	|		WHEN ShippedGoods.Products.UsePackages
	|				AND ShippedGoods.Package.Owner = DefectiveGoods_.OtherQualityGoods.PackagingGroup
	|			THEN ShippedGoods.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END                      AS Package
	|INTO MatchedDefectiveGoodsByPackaging
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedDefectiveGoods AS DefectiveGoods_
	|		ON ShippedGoods.Products = DefectiveGoods_.OtherQualityGoods
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality <> VALUE(Enum.QualityLevels.New)
	|	AND ShippedGoods.Products.PackagingGroup <> VALUE(Catalog.PackagingGroups.SpecialForItem)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ISNULL(DefectiveGoods_.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ShippedGoods.Package,
	|	ISNULL(DefectiveGoods_.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(ProductPackages.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedDefectiveGoods AS DefectiveGoods_
	|		ON ShippedGoods.Products = DefectiveGoods_.OtherQualityGoods
	|
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON DefectiveGoods_.Products = ProductPackages.Owner
	|			AND CAST(ShippedGoods.Package.Description AS STRING(500)) = CAST(ProductPackages.Description AS STRING(500))
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality <> VALUE(Enum.QualityLevels.New)
	|	AND ShippedGoods.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND NOT ISNULL(ProductPackages.DeletionMark, FALSE)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT DISTINCT
	|	ISNULL(AnotherQualityGoods.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS OtherQualityGoods,
	|	ShippedGoods.Products AS Products
	|INTO UnloadedQualityGoods
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		ON ShippedGoods.Products = AnotherQualityGoods.Products
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality = VALUE(Enum.QualityLevels.New)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 9
	|SELECT
	|	QualityProducts.Products                 AS Products,
	|	COUNT(QualityProducts.OtherQualityGoods) AS LinkCount
	|INTO TableOfLinksOfUnloadedQualityGoods
	|FROM
	|	UnloadedQualityGoods AS QualityProducts
	|
	|GROUP BY
	|	QualityProducts.Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 10
	|SELECT DISTINCT
	|	CASE
	|		WHEN LinkTable.LinkCount = 1
	|			THEN CAST(GoodsOfOrder.OtherQualityGoods AS Catalog.Products)
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END                     AS OtherQualityGoods,
	|	GoodsOfOrder.Products AS Products
	|INTO MatchedQualityGoods
	|FROM
	|	UnloadedQualityGoods AS GoodsOfOrder
	|		LEFT JOIN TableOfLinksOfUnloadedQualityGoods AS LinkTable
	|		ON GoodsOfOrder.Products = LinkTable.Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 11
	|SELECT DISTINCT
	|	ISNULL(QualityProducts.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS OtherQualityGoods,
	|	CASE
	|		WHEN (ShippedGoods.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					AND ShippedGoods.Products.ProductKind = QualityProducts.OtherQualityGoods.ProductKind)
	|				OR (ShippedGoods.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					AND ShippedGoods.Products.ItemVariantsOwner = QualityProducts.OtherQualityGoods.ItemVariantsOwner)
	|			THEN ShippedGoods.Characteristic
	|		ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	END                               AS CharacteristicsDefectiveGoods,
	|	ShippedGoods.Products      AS Products,
	|	ShippedGoods.Characteristic    AS Characteristic
	|INTO ComparedQualityGoodsByCharacteristics
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedQualityGoods AS QualityProducts
	|		ON ShippedGoods.Products = QualityProducts.Products
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality = VALUE(Enum.QualityLevels.New)
	|	AND ShippedGoods.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ISNULL(QualityProducts.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(ItemsCharacteristics.Ref, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedQualityGoods AS QualityProducts
	|		ON ShippedGoods.Products = QualityProducts.Products
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON QualityProducts.OtherQualityGoods = ItemsCharacteristics.Owner
	|			AND CAST(ShippedGoods.Characteristic.Description AS STRING(500)) = CAST(ItemsCharacteristics.Description AS STRING(500))
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality = VALUE(Enum.QualityLevels.New)
	|	AND ShippedGoods.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|	AND NOT ISNULL(ItemsCharacteristics.DeletionMark, FALSE)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 12
	|SELECT DISTINCT
	|	ISNULL(QualityProducts.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS OtherQualityGoods,
	|	CASE
	|		WHEN ShippedGoods.Products.UsePackages
	|				AND ShippedGoods.Package.Owner = QualityProducts.OtherQualityGoods.PackagingGroup
	|			THEN ShippedGoods.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END                               AS PackagingDefectiveGoods,
	|	ShippedGoods.Products      AS Products,
	|	ShippedGoods.Package          AS Package
	|INTO ComparableQualityGoodsByPackaging
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedQualityGoods AS QualityProducts
	|		ON ShippedGoods.Products = QualityProducts.Products
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality = VALUE(Enum.QualityLevels.New)
	|	AND ShippedGoods.Products.PackagingGroup <> VALUE(Catalog.PackagingGroups.SpecialForItem)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ISNULL(QualityProducts.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(ProductPackages.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ShippedGoods.Products,
	|	ShippedGoods.Package
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedQualityGoods AS QualityProducts
	|		ON ShippedGoods.Products = QualityProducts.Products
	|
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON QualityProducts.OtherQualityGoods = ProductPackages.Owner
	|			AND CAST(ShippedGoods.Package.Description AS STRING(500)) = CAST(ProductPackages.Description AS STRING(500))
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality = VALUE(Enum.QualityLevels.New)
	|	AND ShippedGoods.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND NOT ISNULL(ProductPackages.DeletionMark, FALSE)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 13
	|SELECT
	|	ShippedGoods.Ref.ShippingZone       AS Cell,
	|	ISNULL(GoodsCharacteristics.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS ProductsRecordingAsReceived,
	|	ISNULL(GoodsCharacteristics.CharacteristicsDefectiveGoods, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CharacteristicRecordingAsReceived,
	|	CASE
	|		WHEN ShippedGoods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                       AS ForAssignment,
	|	ISNULL(PackagingOfGoods.PackagingDefectiveGoods, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS PackagingReceipt,
	|	ShippedGoods.Series                     AS Series,
	|	ISNULL(GoodsCharacteristics.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(GoodsCharacteristics.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	ShippedGoods.Purpose                AS Purpose,
	|	ISNULL(PackagingOfGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	ShippedGoods.BatchesIndicationStatus       AS BatchesIndicationStatus,
	|	SUM(ShippedGoods.Count)         AS Count,
	|	SUM(ShippedGoods.NumberOfPackages) AS NumberOfPackages
	|INTO GoodsOfOrder
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN MatchedDefectiveGoodsByCharacteristics AS GoodsCharacteristics
	|		ON ShippedGoods.Products = GoodsCharacteristics.OtherQualityGoods
	|			AND ShippedGoods.Characteristic = GoodsCharacteristics.CharacteristicsDefectiveGoods
	|
	|		LEFT JOIN MatchedDefectiveGoodsByPackaging AS PackagingOfGoods
	|		ON ShippedGoods.Products = PackagingOfGoods.OtherQualityGoods
	|			AND ShippedGoods.Package = PackagingOfGoods.PackagingDefectiveGoods
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality <> VALUE(Enum.QualityLevels.New)
	|	AND (ShippedGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		OR ShippedGoods.Package.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|
	|GROUP BY
	|	ShippedGoods.Ref.ShippingZone,
	|	ISNULL(GoodsCharacteristics.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(GoodsCharacteristics.CharacteristicsDefectiveGoods, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	CASE
	|		WHEN ShippedGoods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END,
	|	ShippedGoods.Series,
	|	ISNULL(PackagingOfGoods.PackagingDefectiveGoods, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ISNULL(GoodsCharacteristics.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(GoodsCharacteristics.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	ShippedGoods.Purpose,
	|	ISNULL(PackagingOfGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ShippedGoods.BatchesIndicationStatus
	|
	|HAVING
	|	SUM(ShippedGoods.Count) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	ShippedGoods.Ref.ShippingZone,
	|	ISNULL(GoodsCharacteristics.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(GoodsCharacteristics.CharacteristicsDefectiveGoods, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	CASE
	|		WHEN ShippedGoods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END,
	|	ISNULL(PackagingOfGoods.PackagingDefectiveGoods, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ShippedGoods.Series,
	|	ISNULL(GoodsCharacteristics.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(GoodsCharacteristics.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	ShippedGoods.Purpose,
	|	ISNULL(PackagingOfGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ShippedGoods.BatchesIndicationStatus,
	|	SUM(ShippedGoods.Count),
	|	SUM(ShippedGoods.NumberOfPackages)
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		LEFT JOIN ComparedQualityGoodsByCharacteristics AS GoodsCharacteristics
	|		ON ShippedGoods.Products = GoodsCharacteristics.Products
	|			AND ShippedGoods.Characteristic = GoodsCharacteristics.Characteristic
	|
	|		LEFT JOIN ComparableQualityGoodsByPackaging AS PackagingOfGoods
	|		ON ShippedGoods.Products = PackagingOfGoods.Products
	|			AND ShippedGoods.Package = PackagingOfGoods.Package
	|WHERE
	|	ShippedGoods.Ref = &DocumentBasis
	|	AND ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND ShippedGoods.Products.Quality = VALUE(Enum.QualityLevels.New)
	|	AND (ShippedGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		OR ShippedGoods.Package.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|
	|GROUP BY
	|	ShippedGoods.Ref.ShippingZone,
	|	ISNULL(GoodsCharacteristics.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(GoodsCharacteristics.CharacteristicsDefectiveGoods, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	CASE
	|		WHEN ShippedGoods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END,
	|	ShippedGoods.Series,
	|	ISNULL(PackagingOfGoods.PackagingDefectiveGoods, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ISNULL(GoodsCharacteristics.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(GoodsCharacteristics.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	ShippedGoods.Purpose,
	|	ISNULL(PackagingOfGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ShippedGoods.BatchesIndicationStatus
	|
	|HAVING
	|	SUM(ShippedGoods.Count) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 14
	|SELECT
	|	GoodsOfOrder.Cell                      AS Cell,
	|	GoodsOfOrder.ProductsRecordingAsReceived   AS ProductsRecordingAsReceived,
	|	GoodsOfOrder.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	GoodsOfOrder.ForAssignment               AS ForAssignment,
	|	GoodsOfOrder.PackagingReceipt       AS PackagingReceipt,
	|	GoodsOfOrder.Series                       AS Series,
	|	GoodsOfOrder.Products                AS Products,
	|	GoodsOfOrder.Characteristic              AS Characteristic,
	|	GoodsOfOrder.Purpose                  AS Purpose,
	|	GoodsOfOrder.Package                    AS Package,
	|	GoodsOfOrder.BatchesIndicationStatus         AS BatchesIndicationStatus,
	|	GoodsOfOrder.Count                  AS Count,
	|	GoodsOfOrder.NumberOfPackages          AS NumberOfPackages,
	|	GoodsOfOrder.Count                  AS CountRecordingAsReceived
	|FROM
	|	GoodsOfOrder AS GoodsOfOrder
	|
	|ORDER BY
	|	GoodsOfOrder.Products.Description,
	|	GoodsOfOrder.Characteristic.Description,
	|	GoodsOfOrder.Purpose.Description,
	|	GoodsOfOrder.Series.Description
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 15
	|SELECT
	|	DocumentHeader.Warehouse         AS Warehouse,
	|	DocumentHeader.Premise     AS Premise,
	|	DocumentHeader.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document.GoodsIssueNote AS DocumentHeader
	|WHERE
	|	DocumentHeader.Ref = &DocumentBasis
	|";
	
	Query.SetParameter("DocumentBasis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	DocumentAttributes = QueryResult[15].Select();
	DocumentAttributes.Next();
	
	FillPropertyValues(ThisObject, DocumentAttributes);
	
	Goods.Load(QueryResult[14].Unload());
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);

EndProcedure

#EndRegion

#Region Other

Procedure VerifyQuantityInBaseUnits(Cancel)
	
	CheckTable = Goods.Unload();
	MessageTextTemplate = NStr("vi = 'Số lượng mặt hàng chất lượng ban đầu ""%WriteOffProducts_%"" trong dòng ""%LineNumber%"" của danh sách ""Hàng hóa"" khác với số lượng Mặt hàng bị hỏng ""%RegistrationProducts%"" bởi ""%Count%""  của đơn vị lưu trữ';
								|ru = 'Количество номенклатуры исходного качества ""%WriteOffProducts_%"" в строке ""%LineNumber%"" списка ""Товары"" отличается от количества испорченной номенклатуры ""%RegistrationProducts%"" на ""%Count%"" единиц хранения';
								|en = 'Quantity of the  ""%WriteOffProducts_%"" items of original quality in line ""%LineNumber%"" of the ""Goods"" list is different from the quantity of damaged ""%RegistrationProducts%"" items by ""%Count%"" stock UOM'; fa = 'Quantity of the  ""%WriteOffProducts_%"" items of original quality in line ""%LineNumber%"" of the ""Goods"" list is different from the quantity of damaged ""%RegistrationProducts%"" items by ""%Count%"" stock UOM';
								|it = 'La quantità di nomenclatura della qualità originale ""%WriteOffProducts_%"" nella riga ""%LineNumber%"" dell''elenco ""Merci"" è diversa dalla quantità di nomenclatura difettosa ""%RegistrationProducts%"" per ""%Count%"" unità di stoccaggio';
								|pl = 'Ilość produktów oryginalnej jakości ""%WriteOffProducts_%"" w wierszu ""%LineNumber%"" listy ""Towary"" różni się od ilości zepsutych produktów ""%RegistrationProducts%"" na ""%Count%"" jednostek przechowywania';
								|tr = '""Ürünler"" listesinin ""%LineNumber%"" satırındaki orijinal kalite ürün gamı ""%WriteOffProducts_%"" miktarı, stok ölçü birimlerine ""%Count%"" göre hasarlı ""%RegistrationProducts%"" ürün gamının miktarından farklıdır'");
	
	For Each RowOfProduct In CheckTable Do
		
		If RowOfProduct.Count <> RowOfProduct.CountRecordingAsReceived Then
			NumberOfDivergence = RowOfProduct.Count - RowOfProduct.CountRecordingAsReceived;
			NumberOfDivergence = Max(NumberOfDivergence, -NumberOfDivergence);
			
			PresentationOfWriteOffProducts     = ProductsClientServer.ProductPresentation(RowOfProduct.Products,
													RowOfProduct.Characteristic, RowOfProduct.Package, RowOfProduct.Series, RowOfProduct.Purpose);
			PresentationOfParishProducts = ProductsClientServer.ProductPresentation(
													RowOfProduct.ProductsRecordingAsReceived, RowOfProduct.CharacteristicRecordingAsReceived,
													RowOfProduct.PackagingReceipt);
			
			MessageText = StrReplace(MessageTextTemplate, "%LineNumber%", RowOfProduct.LineNumber);
			MessageText = StrReplace(MessageText, "%WriteOffProducts_%", PresentationOfWriteOffProducts);
			MessageText = StrReplace(MessageText, "%RegistrationProducts%", PresentationOfParishProducts);
			MessageText = StrReplace(MessageText, "%Count%", NumberOfDivergence);
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfProduct.LineNumber, "NumberOfPackages");
			
			CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "Object", Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckCellLock(Cancel)
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.StorageBinsLocks");
	LockItem.Mode          = DataLockMode.Shared;
	LockItem.DataSource = Goods;
	LockItem.UseFromDataSource("Cell", "Cell");
	
	Block.Lock();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	StorageBinsLocks.Cell AS Cell,
	|	StorageBinsLocks.LockType AS LockType
	|FROM
	|	InformationRegister.StorageBinsLocks AS StorageBinsLocks
	|WHERE
	|	StorageBinsLocks.Cell IN (&ArrayOfCells)
	|
	|GROUP BY
	|	StorageBinsLocks.Cell,
	|	StorageBinsLocks.LockType
	|
	|ORDER BY
	|	Cell";
	
	Query.SetParameter("ArrayOfCells", Goods.UnloadColumn("Cell"));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		MessageText = NStr("vi = 'Ô hàng %Cell% đã bị phong tỏa: kiểu phong tỏa ""%LockType%""';
							|ru = 'Ячейка %Cell% заблокирована: тип блокировки ""%LockType%""';
							|en = 'Storage bin %Cell% is blocked: block type ""%LockType%""'; fa = 'Storage bin %Cell% is blocked: block type ""%LockType%""';
							|it = 'Cella %Cell% è bloccata: tipo di blocco ""%LockType%""';
							|pl = 'Komórka %Cell% jest zablokowana: typ blokowania ""%LockType%""';
							|tr = '%Cell% hücresi kilitli: kilit türü ""%LockType%""'");
		MessageText = StrReplace(MessageText, "%Cell%", Selection.Cell);
		MessageText = StrReplace(MessageText, "%LockType%", Selection.LockType);
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndDo;
	
EndProcedure

Procedure CheckOrderWarehouse(Cancel)
	
	If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse, Date) Then
		
		Cancel = True;
		MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" vào %Date% không sử dụng sơ đồ hóa đơn kiêm phiếu xuất nhập khi phản ánh hàng thừa, hàng thiếu và hàng hỏng.';
							|ru = 'На складе ""%Warehouse%"" на %Date% не используется ордерная схема при отражении излишков, недостач и порчи.';
							|en = 'Warehouse management is not used in warehouse ""%Warehouse%"" to record surpluses, shortages and damage as of %Date%.'; fa = 'Warehouse management is not used in warehouse ""%Warehouse%"" to record surpluses, shortages and damage as of %Date%.';
							|it = 'Nel magazzino ""%Warehouse%"" al %Date% non viene utilizzato lo schema dei mandati per la visualizzazione di eccedenze, ammanchi e danni.';
							|pl = 'W magazynie ""%Warehouse%"" na %Date% nie jest używany schemat zleceniowy podczas odzwierciedlenia nadwyżek, niedoborów i uszkodzenia.';
							|tr = '""%Warehouse%"" ambarında %Date%''da fazlalıklar, eksiklikler ve stok kalite değişikliği yansıtması yapılırken ambar yönetimi kullanılmıyor.'");
		MessageText = StrReplace(MessageText,"%Warehouse%",Warehouse);
		MessageText = StrReplace(MessageText,"%Date%",Format(Date, "DLF=D"));
		CommonClientServer.MessageToUser(
			MessageText,
			Ref);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf