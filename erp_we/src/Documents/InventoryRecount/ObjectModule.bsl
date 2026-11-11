#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject,FillingData);
	EndIf;
	
	InitializeDocument();
	
	InventoryRecountLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SetPrivilegedMode(True);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryRecount));
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If PostingMode = DocumentPostingMode.RealTime Then
			Date = GetRealTimeTimestamp();
		EndIf;
		
		PastStatus = Common.ObjectAttributeValue(Ref, "Status");
		
		If (Not ValueIsFilled(PastStatus) 
				Or PastStatus = Enums.InventoryRecountStatuses.Prepared2)
			And (Status = Enums.InventoryRecountStatuses.EnteringResults
				Or Status = Enums.InventoryRecountStatuses.Completed2
					And WarehousesServer.UseInventoryRecountStatuses(Warehouse)) Then
				
			If ValueIsFilled(Ref) Then 
				MessageText = NStr("vi = 'Không thể kết chuyển chứng từ ""%Document%"" với trạng thái ""%NewStatus%"". Đầu tiên cần kết chuyển chứng từ với trạng thái ""%StatusInProgress%"".';
									|ru = 'Невозможно провести документ ""%Document%"" в статусе ""%NewStatus%"". Необходимо сначала провести документ в статусе ""%StatusInProgress%"".';
									|en = 'Cannot post %Document% in status %NewStatus%. To post it, change status to %StatusInProgress%.'; fa = 'Cannot post %Document% in status %NewStatus%. To post it, change status to %StatusInProgress%.';
									|it = 'Impossibile registrare il documento ""%Document%"" nello stato ""%NewStatus%"". È necessario innanzitutto registrare il documento nello stato ""%StatusInProgress%"".';
									|pl = 'Nie można zatwierdzić dokumentu ""%Document%"" w statusie ""%NewStatus%"". Musisz najpierw zatwierdzić dokument w statusie ""%StatusInProgress%"".';
									|tr = '""%Document%"" belgesi ""%NewStatus%"" durumunda kaydedilmiyor. Önce belge ""%StatusInProgress%"" durumunda kaydedilmeli.'");
				MessageText = StrReplace(MessageText, "%Document%", Ref);
			Else
				MessageText = NStr("vi = 'Cần kết chuyển chứng từ với trạng thái ""%NewStatus%"". Đầu tiên cần kết chuyển chứng từ với trạng thái ""%StatusInProgress%"".';
									|ru = 'Невозможно провести документ в статусе ""%NewStatus%"". Необходимо сначала провести документ в статусе ""%StatusInProgress%"".';
									|en = 'Cannot post the document in status %NewStatus%. To post it, change status to %StatusInProgress%.'; fa = 'Cannot post the document in status %NewStatus%. To post it, change status to %StatusInProgress%.';
									|it = 'Impossibile registrare il documento nello stato ""%NewStatus%"". È necessario innanzitutto registrare il documento nello stato ""%StatusInProgress%"".';
									|pl = 'Nie można zatwierdzić dokumentu ""w statusie ""%NewStatus%"". Musisz najpierw zatwierdzić dokument w statusie ""%StatusInProgress%"".';
									|tr = '""%NewStatus%"" durumundaki belge kaydedilmiyor. Önce belge ""%StatusInProgress%"" durumunda kaydedilmeli.'");
			EndIf;
			
			MessageText = StrReplace(MessageText, "%NewStatus%", Status);
			MessageText = StrReplace(MessageText, "%StatusInProgress%", Enums.InventoryRecountStatuses.InProgress);
			
			Common.MessageToUser(MessageText, , , , Cancel);
			
			If Cancel Then 
				Return;
			EndIf;
			
		EndIf;
		
		If Status = Enums.InventoryRecountStatuses.Prepared2
				And WriteMode = DocumentWriteMode.Posting
			Or Status = Enums.InventoryRecountStatuses.InProgress
			Or Status = Enums.InventoryRecountStatuses.EnteringResults Then
			
			If WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date) Then
				CheckCellsBeforeLocking(Cancel);
			Else
				CheckOtherRecalculations(Cancel);
			EndIf;
			
		EndIf;
		
		If Not AccountingDataIsFilledIn
			And Not Cancel Then
			
			FillInInvoiceQuantity();
			
		EndIf;
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		AccountingDataIsFilledIn = False;
	EndIf;
	
	InventoryRecountLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	WarehousesServer.ReflectStatesOfCellRecalculations(ThisObject.Ref, ThisObject.Status, Cancel);
	
	InventoryRecountLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	InventoryRecountLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	AccountingDataIsFilledIn = False;
	
	InitializeDocument();

	InventoryRecountLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not Posted
			And (Status = Enums.InventoryRecountStatuses.EnteringResults
	 	Or Status = Enums.InventoryRecountStatuses.Completed2)
	 		And WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date) Then
		
		MessageText = NStr("vi = 'Không thể kết chuyển chứng từ ngay với trạng thái ""%CurrentStatus%"". Ban đầu cần kết chuyển chứng từ với trạng thái trước đó.';
							|ru = 'Нельзя проводить документ сразу в статусе ""%CurrentStatus%"". Необходимо сначала провести документ в предыдущем статусе.';
							|en = 'Cannot post the document in status %CurrentStatus%. To post it, return to the preceding status.'; fa = 'Cannot post the document in status %CurrentStatus%. To post it, return to the preceding status.';
							|it = 'Impossibile registrare il documento subito nello stato ""%CurrentStatus%"". È necessario innanzitutto registrare il documento nello stato precedente.';
							|pl = 'Nie można natychmiast zatwierdzić dokumentu ""w statusie ""%CurrentStatus%"". Musisz najpierw zatwierdzić dokument w poprzednim statusie.';
							|tr = 'Belge hemen ""%CurrentStatus%"" durumunda kaydedilmemeli. Önce belgenin önceki durumda kaydedilmesi gerekir.'");
		MessageText = StrReplace(MessageText, "%CurrentStatus%",Status);
		
		CommonClientServer.MessageToUser(MessageText,ThisObject, "Status", "Object", Cancel);
		
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.FieldNamesWithSuffix.Insert("Count", "CountReal");
	CheckParameters.FieldNamesWithSuffix.Insert("NumberOfPackages", "NumberOfPackagesReal");
	CheckParameters.CheckPossibilityOfRounding = False;
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	If Not MoveGoodsSurplusesIntoBin Then
		NotCheckedAttributeArray.Add("StorageBinForSurplusesConsolidation");
	EndIf;
	If Not MoveSpoiledGoodsIntoBin Then
		NotCheckedAttributeArray.Add("StorageBinForSpoiledGoodsConsolidation");
	EndIf;
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date);
	
	If Not UseBinLocationWarehousing Then
		
		NotCheckedAttributeArray.Add("Goods.Package");
		NotCheckedAttributeArray.Add("Goods.Cell");
		
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
	Else
		ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel)
	EndIf;
	
	If UseBinLocationWarehousing Then
		
		NotCheckedAttributeArray.Add("Goods.Products");
		
	EndIf;
	
	If Not AccountingDataIsFilledIn Then
		
		KeyAttributes = New Array;
		KeyAttributes.Add("Products");
		KeyAttributes.Add("Characteristic");
		KeyAttributes.Add("Purpose");
		KeyAttributes.Add("ControlledLotReference");
		KeyAttributes.Add("Series");
		KeyAttributes.Add("Cell");
		KeyAttributes.Add("Package");
		
		TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "Goods", KeyAttributes, Cancel)
		
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryRecount),
												Cancel,
												NotCheckedAttributeArray);
	
	QualityControl.ProcessingVerificationOfFillingInSurplusDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Items';
			|pl = 'Items';
			|tr = 'Ürünler'"),
		Status <> Enums.InventoryRecountStatuses.InProgress And Status <> Enums.InventoryRecountStatuses.Prepared2);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

	InventoryRecountLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument()

	Date          = CurrentSessionDate();
	EmployeeResponsible = Users.CurrentUser();
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	BinLocationWarehousingIsUsed = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise);
	UseInventoryRecountStatuses = WarehousesServer.UseInventoryRecountStatuses(Warehouse);
	If Not UseInventoryRecountStatuses Then
		Status = Enums.InventoryRecountStatuses.Completed2;
	ElsIf BinLocationWarehousingIsUsed Then
		Status = Enums.InventoryRecountStatuses.Prepared2;
	Else
		Status = Enums.InventoryRecountStatuses.InProgress;
	EndIf;
	
	CellStructure = Documents.InventoryRecount.GetDefaultSurplusAndRejectCells(Ref, Warehouse, Premise);
	FillPropertyValues(ThisObject, CellStructure);

	PrintQuantityByRecords = Documents.InventoryRecount.GetValueForPrintQuantityByAccountingDefaultAttribute(Ref, EmployeeResponsible);
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillInInvoiceQuantity()
	
	Query = New Query;
	
	If WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date) Then
		Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Package AS Package,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.Series AS Series,
		|	Table.Cell AS Cell,
		|	Table.CountReal AS CountReal,
		|	Table.NumberOfPackagesReal AS NumberOfPackagesReal,
		|	Table.LineNumber
		|INTO ProductsTable
		|FROM
		|	&ProductsTable AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfProductsWithBalances.Cell,
		|	TableOfProductsWithBalances.Products,
		|	TableOfProductsWithBalances.Characteristic,
		|	TableOfProductsWithBalances.Purpose,
		|	TableOfProductsWithBalances.Package,
		|	TableOfProductsWithBalances.Series AS Series,
		|	SUM(TableOfProductsWithBalances.NumberOfPackages) AS NumberOfPackages,
		|	SUM(TableOfProductsWithBalances.Count) AS Count,
		|	SUM(TableOfProductsWithBalances.CountReal) AS CountReal,
		|	SUM(TableOfProductsWithBalances.NumberOfPackagesReal) AS NumberOfPackagesReal
		|INTO TableOfProductsWithBalances
		|FROM
		|	(SELECT
		|		ProductsTable.Cell AS Cell,
		|		ProductsTable.Products AS Products,
		|		ProductsTable.Characteristic AS Characteristic,
		|		ProductsTable.Purpose AS Purpose,
		|		ProductsTable.Package AS Package,
		|		ProductsTable.Series AS Series,
		|		0 AS NumberOfPackages,
		|		0 AS Count,
		|		ProductsTable.CountReal AS CountReal,
		|		ProductsTable.NumberOfPackagesReal AS NumberOfPackagesReal
		|	FROM
		|		ProductsTable AS ProductsTable
		|	WHERE
		|		ProductsTable.Products <> VALUE(Catalog.Products.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT DISTINCT
		|		ProductsTable.Cell,
		|		ISNULL(GoodsInStorageBinsBalance.Products, VALUE(Catalog.Products.EmptyRef)),
		|		ISNULL(GoodsInStorageBinsBalance.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
		|		ISNULL(GoodsInStorageBinsBalance.Purpose, VALUE(Catalog.Assignments.EmptyRef)),
		|		ISNULL(GoodsInStorageBinsBalance.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
		|		ISNULL(GoodsInStorageBinsBalance.Series, VALUE(Catalog.ItemsBatches.EmptyRef)),
		|		ISNULL(GoodsInStorageBinsBalance.InStockBalance, 0),
		|		CASE
		|			WHEN ISNULL(&QueryTextPackagingFactor, 0) = 0
		|				THEN ISNULL(GoodsInStorageBinsBalance.InStockBalance, 0)
		|			ELSE ISNULL(GoodsInStorageBinsBalance.InStockBalance, 0) * &QueryTextPackagingFactor
		|		END,
		|		0,
		|		0
		|	FROM
		|		ProductsTable AS ProductsTable
		|			LEFT JOIN AccumulationRegister.GoodsInStorageBins.Balance(&DateOfRemainingGoods, ) AS GoodsInStorageBinsBalance
		|			ON (GoodsInStorageBinsBalance.Cell = ProductsTable.Cell)
		|				AND (CASE
		|					WHEN ProductsTable.Products = VALUE(Catalog.Products.EmptyRef)
		|						THEN TRUE
		|					ELSE GoodsInStorageBinsBalance.Products = ProductsTable.Products
		|				END)
		|				AND (CASE
		|					WHEN ProductsTable.Products = VALUE(Catalog.Products.EmptyRef)
		|						THEN TRUE
		|					ELSE GoodsInStorageBinsBalance.Characteristic = ProductsTable.Characteristic
		|				END)
		|				AND (CASE
		|					WHEN ProductsTable.Products = VALUE(Catalog.Products.EmptyRef)
		|						THEN TRUE
		|					ELSE GoodsInStorageBinsBalance.Purpose = ProductsTable.Purpose
		|				END)
		|				AND (CASE
		|					WHEN ProductsTable.Products = VALUE(Catalog.Products.EmptyRef)
		|						THEN TRUE
		|					ELSE GoodsInStorageBinsBalance.Series = ProductsTable.Series
		|				END)
		|				AND (CASE
		|					WHEN ProductsTable.Products = VALUE(Catalog.Products.EmptyRef)
		|						THEN TRUE
		|					ELSE GoodsInStorageBinsBalance.Package = ProductsTable.Package
		|				END)
		|	WHERE
		|		(ProductsTable.Products = VALUE(Catalog.Products.EmptyRef)
		|				OR ProductsTable.Products <> VALUE(Catalog.Products.EmptyRef)
		|					AND NOT (GoodsInStorageBinsBalance.Products IS NULL
		|							AND GoodsInStorageBinsBalance.Characteristic IS NULL
		|							AND GoodsInStorageBinsBalance.Purpose IS NULL
		|							AND GoodsInStorageBinsBalance.Package IS NULL
		|							AND GoodsInStorageBinsBalance.Series IS NULL))) AS TableOfProductsWithBalances
		|
		|GROUP BY
		|	TableOfProductsWithBalances.Cell,
		|	TableOfProductsWithBalances.Package,
		|	TableOfProductsWithBalances.Characteristic,
		|	TableOfProductsWithBalances.Purpose,
		|	TableOfProductsWithBalances.Products,
		|	TableOfProductsWithBalances.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfProductsWithBalances.Products AS Products,
		|	TableOfProductsWithBalances.Characteristic AS Characteristic,
		|	TableOfProductsWithBalances.Purpose AS Purpose,
		|	TableOfProductsWithBalances.Package AS Package,
		|	TableOfProductsWithBalances.Cell AS Cell,
		|	TableOfProductsWithBalances.Series AS Series,
		|	TableOfProductsWithBalances.NumberOfPackages,
		|	TableOfProductsWithBalances.Count,
		|	TableOfProductsWithBalances.CountReal,
		|	TableOfProductsWithBalances.NumberOfPackagesReal,
		|	ISNULL(ProductsTable.LineNumber, &MaximumPossibleNumberOfWHLines) AS LineNumber,
		|	FALSE AS SurplusDamage
		|FROM
		|	TableOfProductsWithBalances AS TableOfProductsWithBalances
		|		LEFT JOIN ProductsTable AS ProductsTable
		|		ON TableOfProductsWithBalances.Products = ProductsTable.Products
		|			AND TableOfProductsWithBalances.Characteristic = ProductsTable.Characteristic
		|			AND TableOfProductsWithBalances.Purpose = ProductsTable.Purpose
		|			AND TableOfProductsWithBalances.Package = ProductsTable.Package
		|			AND TableOfProductsWithBalances.Cell = ProductsTable.Cell
		|			AND TableOfProductsWithBalances.Series = ProductsTable.Series
		|
		|ORDER BY
		|	LineNumber,
		|	CAST(TableOfProductsWithBalances.Cell AS Catalog.StorageBins).WarehouseZone,
		|	CAST(TableOfProductsWithBalances.Cell AS Catalog.StorageBins).TabIndex,
		|	CAST(TableOfProductsWithBalances.Cell AS Catalog.StorageBins).Code,
		|	TableOfProductsWithBalances.Series.Number,
		|	TableOfProductsWithBalances.Series.ValidUntil_";
		
		Query.Text = StrReplace(Query.Text,
									"&QueryTextPackagingFactor",
									Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
										"GoodsInStorageBinsBalance.Package",
										"GoodsInStorageBinsBalance.Products"));
		
		Query.SetParameter("MaximumPossibleNumberOfWHLines", 100000);
		
	Else
		Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.Series AS Series,
		|	Table.CountReal AS CountReal,
		|	Table.NumberOfPackagesReal AS NumberOfPackagesReal,
		|	Table.LineNumber
		|INTO ProductsTable
		|FROM
		|	&ProductsTable AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfProductsWithBalances.Products AS Products,
		|	TableOfProductsWithBalances.Characteristic AS Characteristic,
		|	TableOfProductsWithBalances.Purpose AS Purpose,
		|	TableOfProductsWithBalances.ControlledLotReference AS ControlledLotReference,
		|	TableOfProductsWithBalances.Series AS Series,
		|	SUM(TableOfProductsWithBalances.NumberOfPackages) AS NumberOfPackages,
		|	SUM(TableOfProductsWithBalances.Count) AS Count,
		|	SUM(TableOfProductsWithBalances.CountReal) AS CountReal,
		|	SUM(TableOfProductsWithBalances.NumberOfPackagesReal) AS NumberOfPackagesReal
		|INTO TableOfProductsWithBalances
		|FROM
		|	(SELECT
		|		ProductsTable.Products AS Products,
		|		ProductsTable.Characteristic AS Characteristic,
		|		ProductsTable.Purpose AS Purpose,
		|		ProductsTable.ControlledLotReference AS ControlledLotReference,
		|		ProductsTable.Series AS Series,
		|		0 AS NumberOfPackages,
		|		0 AS Count,
		|		ProductsTable.CountReal AS CountReal,
		|		ProductsTable.NumberOfPackagesReal AS NumberOfPackagesReal
		|	FROM
		|		ProductsTable AS ProductsTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductStockBalance.Products,
		|		ProductStockBalance.Characteristic,
		|		ProductStockBalance.Purpose,
		|		ProductStockBalance.ControlledLotReference,
		|		ProductStockBalance.Series,
		|		ProductStockBalance.InStockBalance,
		|		ProductStockBalance.InStockBalance,
		|		0,
		|		0
		|	FROM
		|		AccumulationRegister.ProductStock.Balance(
		|				&DateOfRemainingGoods,
		|				(Products, Characteristic, Purpose, ControlledLotReference, Warehouse, Premise) IN
		|					(SELECT
		|						Table.Products,
		|						Table.Characteristic,
		|						Table.Purpose,
		|						Table.ControlledLotReference,
		|						&Warehouse,
		|						&Premise
		|					FROM
		|						ProductsTable AS Table)) AS ProductStockBalance) AS TableOfProductsWithBalances
		|
		|GROUP BY
		|	TableOfProductsWithBalances.Products,
		|	TableOfProductsWithBalances.Characteristic,
		|	TableOfProductsWithBalances.Purpose,
		|	TableOfProductsWithBalances.ControlledLotReference,
		|	TableOfProductsWithBalances.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfProductsWithBalances.Products,
		|	TableOfProductsWithBalances.Characteristic,
		|	TableOfProductsWithBalances.Purpose,
		|	TableOfProductsWithBalances.ControlledLotReference,
		|	TableOfProductsWithBalances.Series AS Series,
		|	TableOfProductsWithBalances.NumberOfPackages AS NumberOfPackages,
		|	TableOfProductsWithBalances.Count AS Count,
		|	TableOfProductsWithBalances.CountReal AS CountReal,
		|	TableOfProductsWithBalances.NumberOfPackagesReal AS NumberOfPackagesReal,
		|	ProductsTable.LineNumber AS LineNumber,
		|	FALSE AS SurplusDamage
		|FROM
		|	ProductsTable AS ProductsTable
		|		INNER JOIN TableOfProductsWithBalances AS TableOfProductsWithBalances
		|		ON ProductsTable.Products = TableOfProductsWithBalances.Products
		|			AND ProductsTable.Characteristic = TableOfProductsWithBalances.Characteristic
		|			AND ProductsTable.Series = TableOfProductsWithBalances.Series
		|			AND ProductsTable.Purpose = TableOfProductsWithBalances.Purpose
		|			AND ProductsTable.ControlledLotReference = TableOfProductsWithBalances.ControlledLotReference
		|
		|ORDER BY
		|	LineNumber,
		|	TableOfProductsWithBalances.Series.Number,
		|	TableOfProductsWithBalances.Series.ValidUntil_";
		
		Query.SetParameter("Ref",		Ref);
		Query.SetParameter("Warehouse",		Warehouse);
		Query.SetParameter("Premise",	Premise);
		
	EndIf;
	
	DateOfRemainingGoods = New Boundary(Date, BoundaryType.Including);
	
	Query.SetParameter("DateOfRemainingGoods",			DateOfRemainingGoods);
	Query.SetParameter("ProductsTable",	Goods.Unload());
	
	Goods.Load(Query.Execute().Unload());
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryRecount));
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	AccountingDataIsFilledIn = True;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckCellsBeforeLocking(Cancel)
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.StorageBinsLocks");
	LockItem.Mode          = DataLockMode.Exclusive;
	LockItem.DataSource = Goods;
	LockItem.UseFromDataSource("Cell", "Cell");
	
	LockItem = Block.Add("AccumulationRegister.GoodsInStorageBins");
	LockItem.Mode          = DataLockMode.Exclusive;   
	LockItem.DataSource = Goods;
	LockItem.UseFromDataSource("Cell", "Cell");
	
	Block.Lock();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsTable.Cell AS Cell,
	|	ProductsTable.LineNumber AS LineNumber
	|INTO TableOfCellsForQuery
	|FROM
	|	&ProductsTable AS ProductsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(TableOfCellsForQuery.Cell AS Catalog.StorageBins) AS Cell,
	|	MIN(TableOfCellsForQuery.LineNumber) AS LineNumber
	|INTO CellTable
	|FROM
	|	TableOfCellsForQuery AS TableOfCellsForQuery
	|
	|GROUP BY
	|	TableOfCellsForQuery.Cell
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellTable.Cell AS Cell,
	|	CellTable.Cell.StorageBinType AS StorageBinType,
	|	CellTable.LineNumber,
	|	CASE
	|		WHEN ISNULL(GoodsInStorageBinsBalance.ForPickingBalance, 0) <> 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreTasksForSelection,
	|	CASE
	|		WHEN ISNULL(GoodsInStorageBinsBalance.ForPlacementBalance, 0) <> 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreTasksForPlacement,
	|	CASE
	|		WHEN StorageBinsLocks.LockType IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreLocksOnCell
	|FROM
	|	CellTable AS CellTable
	|		LEFT JOIN AccumulationRegister.GoodsInStorageBins.Balance(
	|				,
	|				Cell IN
	|					(SELECT
	|						CellTable.Cell AS Cell
	|					FROM
	|						CellTable AS CellTable)) AS GoodsInStorageBinsBalance
	|		ON CellTable.Cell = GoodsInStorageBinsBalance.Cell
	|		LEFT JOIN InformationRegister.StorageBinsLocks AS StorageBinsLocks
	|		ON (CellTable.Cell = StorageBinsLocks.Cell
	|				AND StorageBinsLocks.Recorder <> &Ref)
	|WHERE
	|	(ISNULL(GoodsInStorageBinsBalance.ForPickingBalance, 0) <> 0
	|			OR ISNULL(GoodsInStorageBinsBalance.ForPlacementBalance, 0) <> 0
	|			OR (NOT StorageBinsLocks.LockType IS NULL ))
	|
	|ORDER BY
	|	Cell";
	Query.SetParameter("ProductsTable", Goods.Unload());
	Query.SetParameter("Ref", Ref);
	
	CellTypesShipment = WarehousesClientServer.CellTypesShipment();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		MessageText = NStr("vi = 'Không thể phong tỏa %CellType% %Cell%:
		|%Cause%';
		|ru = 'Невозможно заблокировать %CellType% %Cell%:
		|%Cause%';
		|en = 'Cannot lock: %CellType%, code %Cell%. Reason:
		|%Cause%'; fa = 'Cannot lock: %CellType%, code %Cell%. Reason:
		|%Cause%';
		|it = 'Impossibile bloccare %CellType% %Cell%:
		|%Cause%';
		|pl = 'Nie można zablokować %CellType% %Cell%:
		| %Cause%';
		|tr = 'Kilitlemek imkansız %CellType% %Cell%:
		|%Cause%'");
		If Selection.ThereAreLocksOnCell Then
			ReasonText = NStr("vi = 'ô hàng bị khóa bằng chứng từ khác';
								|ru = 'ячейка заблокирована другим документом';
								|en = 'Storage bin is locked by a document.'; fa = 'Storage bin is locked by a document.';
								|it = 'la cella è bloccata da un altro documento';
								|pl = 'komórka jest zablokowana przez inny dokument';
								|tr = 'hücre başka bir belge tarafından kilitlendi'");
		Else
			ReasonText = "";
			If Selection.ThereAreTasksForSelection <> 0 Then
				ReasonText = NStr("vi = 'nếu chưa thực hiện nhiệm vụ lấy ra hàng hóa trong ô hàng ';
									|ru = 'есть невыполненные задания на отбор товара из ячейки';
									|en = 'Storage bin is locked by a picking job.'; fa = 'Storage bin is locked by a picking job.';
									|it = 'ci sono task in sospeso per la selezione della merce dalla cella';
									|pl = 'istnieją wybitne zadania dla doboru towarów z komórki';
									|tr = 'hücreden ürün filtresi için yerine getirilmemiş görevler mevcut'");
			EndIf;
			If Selection.ThereAreTasksForPlacement <> 0 Then
				If ValueIsFilled(ReasonText) Then
					ReasonText = ReasonText + ";
						|"
				EndIf;
				ReasonText = ReasonText + NStr("vi = 'nếu chưa thực hiện nhiệm vụ sắp xếp hàng hóa vào ô hàng ';
												|ru = 'есть невыполненные задания на размещение в ячейку';
												|en = 'Storage bin is locked by a put-away task.'; fa = 'Storage bin is locked by a put-away task.';
												|it = 'ci sono task in sospeso per il posizionamento nella cella';
												|pl = 'są wyjątkowe zadania do umieszczenia w komórce';
												|tr = 'hücreye yerleştirmek için yerine getirilmemiş görevler mevcut'");
				
				If CellTypesShipment.Find(Selection.StorageBinType) <> Undefined Then
					ReasonText = ReasonText + " " + NStr("vi = 'hoặc có phiếu xuất kho (phiếu điều chuyển) có trạng thái chưa hoàn thành với hàng hóa chưa giao được sắp xếp vào khu vực giao hàng này';
														|ru = 'или есть расходные ордера (ордера на перемещение) в неокончательном статусе с неотгружаемыми товарами, размещаемыми в эту зону отгрузки';
														|en = 'Or it is locked by an order in progress that is assigned to this storage bin.'; fa = 'Or it is locked by an order in progress that is assigned to this storage bin.';
														|it = 'oppure ci sono mandati di pagamento (mandati di trasferimento) in stato non definitivo con delle merci non soggette alla spedizione, che vengono collocate in questa area di spedizione';
														|pl = 'lub istnieją zlecenia wydatków (zlecenia przeniesienia) w statusie nieostatecznym z towarami nieprzeznaczonymi do wysyłki w tej strefie wysyłkowej';
														|tr = 'veya bu yükleme alanına sevkıyatı yapılmayan ürünlerin yerleştirildiği nihai olmayan durumdaki ambar çıkış fişleri (dahili stok transferleri) mevcut'");
				EndIf;
			EndIf;
			
		EndIf;
		MessageText = StrReplace(MessageText, "%CellType%",
			?(CellTypesShipment.Find(Selection.StorageBinType) <> Undefined, NStr("vi = 'khu vực giao hàng';
																					|ru = 'зону отгрузки';
																					|en = 'Outbound area'; fa = 'ناحیه خروجی';
																					|it = 'area di spedizione';
																					|pl = 'strefa wysyłki';
																					|tr = 'yükleme alanına'"),
				?(Selection.StorageBinType = Enums.TypesOfStorageCells.Receiving, NStr("vi = 'khu vực tiếp nhận';
																						|ru = 'зону приемки';
																						|en = 'Inbound area'; fa = 'ناحیه ورودی';
																						|it = 'area di accettazione';
																						|pl = 'strefa odbioru';
																						|tr = 'boşaltma alanına'"),
					NStr("vi = 'ô hàng';
						|ru = 'ячейку';
						|en = 'Storage bin'; fa = 'محل نگهداری';
						|it = 'cella';
						|pl = 'komórkę';
						|tr = 'hücrenin'"))));
		MessageText = StrReplace(MessageText, "%Cause%", ReasonText);
		MessageText = StrReplace(MessageText, "%Cell%", Selection.Cell);
		
		Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "Cell");
		
		CommonClientServer.MessageToUser(MessageText,ThisObject,Field,"Object",Cancel);
	EndDo;
EndProcedure

Procedure CheckOtherRecalculations(Cancel)
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages");
	
	LockItem.Mode = DataLockMode.Shared;
	LockItem.SetValue("Warehouse", Warehouse);
	LockItem.DataSource = Goods;
	LockItem.UseFromDataSource("Products", "Products");
	LockItem.UseFromDataSource("Characteristic", "Characteristic");
	LockItem.UseFromDataSource("Series", "Series");
	
	StatusWas = Common.ObjectAttributeValue(Ref, "Status");
	
	If Status = Enums.InventoryRecountStatuses.Completed2
		Or StatusWas = Enums.InventoryRecountStatuses.Completed2 Then
		LockItem.Mode = DataLockMode.Exclusive;
	Else
		LockItem.Mode = DataLockMode.Shared;
	EndIf;
	
	Block.Lock();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.LineNumber
	|INTO TTTableProducts
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTableProducts.LineNumber
	|FROM
	|	Document.InventoryRecount.Goods AS RecalculationOfGoods
	|		INNER JOIN TTTableProducts AS TTTableProducts
	|		ON (TTTableProducts.Products = RecalculationOfGoods.Products)
	|			AND (TTTableProducts.Characteristic = RecalculationOfGoods.Characteristic)
	|			AND (TTTableProducts.Series = RecalculationOfGoods.Series)
	|WHERE
	|	RecalculationOfGoods.Ref.Warehouse = &Warehouse
	|	AND RecalculationOfGoods.Ref.Premise = &Premise
	|	AND RecalculationOfGoods.Ref.Posted
	|	AND NOT RecalculationOfGoods.Ref = &Ref
	|	AND RecalculationOfGoods.Ref.Status IN (VALUE(Enum.InventoryRecountStatuses.InProgress), VALUE(Enum.InventoryRecountStatuses.EnteringResults))
	|
	|GROUP BY
	|	TTTableProducts.LineNumber";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("GoodsTable", Goods.Unload());
	
	QueryResultsArray = Query.ExecuteBatch();
	Result = QueryResultsArray[1]; // QueryResult
	SampleRecalculations = Result.Select();
	While SampleRecalculations.Next() Do
		MessageText = NStr("vi = 'Hàng hóa trong dòng %LineNumber% đã bao gồm trong kiểm kê hàng hóa ở trạng thái ""Đang làm việc"" hoặc ""Đưa ra kết quả"" ở kho bãi (nhà kho) này.';
							|ru = 'Товар в строке %LineNumber% уже включен в пересчеты товаров в статусе ""В работе"" или ""Внесение результатов"" на этом же складе (помещении).';
							|en = 'Item #%LineNumber% is already included in an Inventory count sheet that has the status ""In progress"" or ""Submitted"".'; fa = 'Item #%LineNumber% is already included in an Inventory count sheet that has the status ""In progress"" or ""Submitted"".';
							|it = 'La merce nella riga %LineNumber% è già inclusa nel ricalcolo delle merci nello stato ""In lavorazione"" o ""Immissione dei risultati"" nello stesso magazzino (locale).';
							|pl = 'Towary w wierszu %LineNumber% jest już uwzględniony w ponownym obliczaniu towarów w statusie ""W pracy"" lub ""Wprowadzanie wyników"" w tym samym magazynie (pomieszczeniu).';
							|tr = '%LineNumber% satırdaki ürün, aynı ambarda (alan) ""İşleniyor"" veya ""Sonuçların girilmesi"" durumundaki ürünlerin yeniden hesaplanmasına artık dahil edilmiştir.'");
		MessageText = StrReplace(MessageText, "%LineNumber%", SampleRecalculations.LineNumber);
		Field = CommonClientServer.PathToTabularSection("Goods", SampleRecalculations.LineNumber, "LineNumber");
		CommonClientServer.MessageToUser(MessageText,ThisObject,Field,"Object",Cancel);
	EndDo;
		
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf