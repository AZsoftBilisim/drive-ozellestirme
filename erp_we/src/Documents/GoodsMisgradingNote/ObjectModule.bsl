#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.GoodsIssueNote") Then
		FillInOnTheBasis(FillingData);
	Else
		InitializeDocument(FillingData);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date) Then
		
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
		
		Common.MessageToUser(MessageText, Undefined, "", "", Cancel);
		
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
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel,
		CheckParameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.GoodsMisgradingNote);
	
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	ErrorText = NStr("vi = 'Hàng hóa ghi giảm trùng với hàng hóa tiếp nhận';
					|ru = 'Списываемый товар совпадает с приходуемым';
					|en = 'Goods to adjust match the goods recorded as received'; fa = 'Goods to adjust match the goods recorded as received';
					|it = 'La merce in fase di storno coincide a quella in fase della registrazione in contabilità';
					|pl = 'Spisany na straty towar pokrywa się z przyjmowanym';
					|tr = 'Zarara yazılan ürün envanter girişi yapılan ile eşleşiyor'");
	
	For Each RowOfTables In Goods Do
		
		ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'в строке %LineNumber% списка ""Товары""';
							|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
							|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
							|pl = 'w wierszu %LineNumber% listy ""Towary""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", RowOfTables.LineNumber);
		
		If ValueIsFilled(RowOfTables.Products)
			And RowOfTables.Products = RowOfTables.ProductsRecordingAsReceived
			And RowOfTables.Characteristic = RowOfTables.CharacteristicRecordingAsReceived
			And RowOfTables.Purpose = RowOfTables.AssignmentGoodsReceipt
			And RowOfTables.Series = RowOfTables.BatchReceipt Then
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "ProductsRecordingAsReceived");
			
			CommonClientServer.MessageToUser(ErrorText + Chars.NBSp + ErrorAddress, ThisObject, Field, "", Cancel);
			
		EndIf;
		
	EndDo;
	
	CheckCompletionOfAppointments(Cancel);
	
	If GetFunctionalOption("UseReusablePackage") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	TableOfGoods.LineNumber AS LineNumber,
		|	TableOfGoods.Products AS Products,
		|	TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived
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
		
		ErrorText = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""Hàng hóa"" các kiểu mặt hàng không trùng nhau. 
			|Mặt hàng ghi giảm có kiểu %ProductsTypeOfProducts%, mặt hàng ghi tăng có kiểu - %ProductsDescriptionProductsType%.';
			|ru = 'В строке %LineNumber% списка ""Товары"" не совпадают типы номенклатуры. 
			|У списываемой номенклатуры тип %ProductsTypeOfProducts%, приходуемой - %ProductsDescriptionProductsType%.';
			|en = 'Item types do not match in line %LineNumber% of the Item list.
			|Type of written off items is %ProductsTypeOfProducts%, recorded as received one is %ProductsDescriptionProductsType%.'; fa = 'Item types do not match in line %LineNumber% of the Item list.
			|Type of written off items is %ProductsTypeOfProducts%, recorded as received one is %ProductsDescriptionProductsType%.';
			|it = 'Nella riga %LineNumber% dell''elenco ""Merci"" i tipi di nomenclatura non coincidono. 
			|Il tipo di nomenclatura in fase di storno è %ProductsTypeOfProducts%, di quella in fase della registrazione in contabilità - %ProductsDescriptionProductsType%.';
			|pl = 'W wierszu %LineNumber% listy ""Towary"" nie odpowiadają typy produktów. 
			|Dla rozchodowanych produktów typ%ProductsTypeOfProducts%, przyjmowanych na stan - %ProductsDescriptionProductsType%.';
			|tr = 'Ürün gamı türleri, ""Ürünler"" listesinin %LineNumber%satırında eşleşmiyor. 
			| Zarara yazılan ürün gamı türü %ProductsTypeOfProducts%, envanter girişi - %ProductsDescriptionProductsType%.'");
		
		While Selection.Next() Do
			ErrorMessage = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber);
			ErrorMessage = StrReplace(ErrorMessage, "%ProductsTypeOfProducts%",
				Selection.ProductsTypeOfProducts);
			ErrorMessage = StrReplace(ErrorMessage, "%ProductsDescriptionProductsType%",
				Selection.ProductsDescriptionProductsType); 
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "ProductsRecordingAsReceived");
			
			CommonClientServer.MessageToUser(ErrorMessage, ThisObject, Field, "", Cancel);
		EndDo;
		
	EndIf;
	
	VerifyQuantityInBaseUnits(Cancel);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckPossibilityOfRounding = False;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	WarehousesServer.CheckWarehouseOrder(Warehouse, Date, "WhenReflectingSurplusShortages", Cancel);
	
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
			|tr = 'Ürünler'"));
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date) Then
		CheckCellLock(Cancel);
		
		If Cancel Then
			Return;
		EndIf;
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.GoodsMisgradingNote);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
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

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInOnTheBasis(Basis)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	NotShippedGoods.Ref.ShippingZone       AS Cell,
	|	NotShippedGoods.Products              AS Products,
	|	NotShippedGoods.Characteristic            AS Characteristic,
	|	NotShippedGoods.Purpose                AS Purpose,
	|	NotShippedGoods.Package                  AS Package,
	|	NotShippedGoods.Series                     AS Series,
	|	NotShippedGoods.BatchesIndicationStatus       AS BatchesIndicationStatus,
	|	NotShippedGoods.Products              AS ProductsRecordingAsReceived,
	|	NotShippedGoods.Characteristic            AS CharacteristicRecordingAsReceived,
	|	NotShippedGoods.Purpose                AS AssignmentGoodsReceipt,
	|	NotShippedGoods.Ref.ControlledLotReference AS ControlledLotReference,
	|	NotShippedGoods.Package                  AS PackagingReceipt,
	|	NotShippedGoods.Series                     AS BatchReceipt,
	|	NotShippedGoods.BatchesIndicationStatus       AS BatchesIndicationStatusReceipt,
	|	SUM(NotShippedGoods.Count)         AS Count,
	|	SUM(NotShippedGoods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(NotShippedGoods.Count)         AS CountRecordingAsReceived
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS NotShippedGoods
	|WHERE
	|	NotShippedGoods.Ref = &DocumentBasis
	|	AND NotShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|	AND (NotShippedGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		OR NotShippedGoods.Package.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|
	|GROUP BY
	|	NotShippedGoods.Ref.ShippingZone,
	|	NotShippedGoods.Products,
	|	NotShippedGoods.Characteristic,
	|	NotShippedGoods.Purpose,
	|	NotShippedGoods.Ref.ControlledLotReference,
	|	NotShippedGoods.Package,
	|	NotShippedGoods.Series,
	|	NotShippedGoods.BatchesIndicationStatus
	|
	|ORDER BY
	|	NotShippedGoods.Products.Description,
	|	NotShippedGoods.Characteristic.Description,
	|	NotShippedGoods.Purpose.Description,
	|	NotShippedGoods.Series.Description
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	DocumentHeader.Warehouse         AS Warehouse,
	|	DocumentHeader.Premise     AS Premise,
	|	DocumentHeader.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document.GoodsIssueNote AS DocumentHeader
	|WHERE
	|	DocumentHeader.Ref = &DocumentBasis";
	
	Query.SetParameter("DocumentBasis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	DocumentAttributes = QueryResult[1].Select();
	DocumentAttributes.Next();
	
	FillPropertyValues(ThisObject, DocumentAttributes);
	
	Goods.Load(QueryResult[0].Unload());
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

#EndRegion

#Region Other

Procedure VerifyQuantityInBaseUnits(Cancel)
	
	CheckTable = Goods.Unload();
	MessageTextTemplate = NStr("vi = 'Ghi giảm số lượng mặt hàng ""%WriteOffProducts_%"" trong dòng ""%LineNumber%"" của danh sách ""Hàng hóa"" khác với số lượng của hàng hóa được ghi tăng ""%RegistrationProducts%"" bởi ""%Count%"" đơn vị lưu trữ';
								|ru = 'Списываемое количество номенклатуры ""%WriteOffProducts_%"" в строке ""%LineNumber%"" списка ""Товары"" отличается от количества приходуемой номенклатуры ""%RegistrationProducts%"" на ""%Count%"" единиц хранения';
								|en = 'Quantity of written off items ""%WriteOffProducts_%"" in line ""%LineNumber%"" of the ""Goods"" list is different from the quantity of recorded as received items ""%RegistrationProducts%"" by ""%Count%"" stock UOM'; fa = 'Quantity of written off items ""%WriteOffProducts_%"" in line ""%LineNumber%"" of the ""Goods"" list is different from the quantity of recorded as received items ""%RegistrationProducts%"" by ""%Count%"" stock UOM';
								|it = 'La quantità di nomenclatura in fase di storno ""%WriteOffProducts_%"" nella riga ""%LineNumber%"" dell''elenco ""Merci"" è diversa dalla quantità di nomenclatura in fase della registrazione in contabilità ""%RegistrationProducts%"" per ""%Count%"" unità di stoccaggio';
								|pl = 'Rozchodowana ilość produktów ""%WriteOffProducts_%"" w wierszu ""%LineNumber%"" listy ""Towary"" różni się od ilości przyjmowanych na stan produktów ""%RegistrationProducts%"" na ""%Count%"" jednostek przechowywania';
								|tr = '""Ürünler"" listesinin ""%LineNumber%"" satırındaki ""%WriteOffProducts_%"" ürün gamının silinen miktarı, alınan ""%RegistrationProducts%"" ürün gamı miktarından ""%Count%"" stok ölçü birimi kadar farklıdır'");
	
	For Each RowOfProduct In CheckTable Do
		
		If RowOfProduct.Count <> RowOfProduct.CountRecordingAsReceived Then
			NumberOfDivergence = RowOfProduct.Count - RowOfProduct.CountRecordingAsReceived;
			NumberOfDivergence = Max(NumberOfDivergence, -NumberOfDivergence);
			
			PresentationOfWriteOffProducts     = ProductsClientServer.ProductPresentation(RowOfProduct.Products,
													RowOfProduct.Characteristic, RowOfProduct.Package, RowOfProduct.Series, RowOfProduct.Purpose);
			PresentationOfParishProducts = ProductsClientServer.ProductPresentation(
													RowOfProduct.ProductsRecordingAsReceived, RowOfProduct.CharacteristicRecordingAsReceived,
													RowOfProduct.PackagingReceipt, RowOfProduct.BatchReceipt, RowOfProduct.AssignmentGoodsReceipt);
			
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
	|	StorageBinsLocks.Cell        AS Cell,
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
		
		CommonClientServer.MessageToUser(MessageText, Undefined, "", "", Cancel);
	EndDo;
	
EndProcedure

Procedure CheckOrderWarehouse(Cancel)
	
	If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse, Date) Then
		
		Cancel = True;
		
		MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" vào ngày %Date%, sơ đồ đơn hàng không được sử dụng khi phản ánh thừa, thiếu, phân loại lại và hỏng.';
							|ru = 'На складе ""%Warehouse%"" на %Date% не используется ордерная схема при отражении излишков, недостач, пересортицы и порчи.';
							|en = 'Warehouse management is not used in warehouse ""%Warehouse%"" to record surplus, shortage, stock reclass, and damage as of %Date%.'; fa = 'Warehouse management is not used in warehouse ""%Warehouse%"" to record surplus, shortage, stock reclass, and damage as of %Date%.';
							|it = 'Nel magazzino ""%Warehouse%"" al %Date% non viene utilizzato lo schema dei mandati per la visualizzazione di eccedenze, ammanchi, riclassificazione e danni.';
							|pl = 'W magazynie ""%Warehouse%"" na %Date% nie jest używany schemat zleceniowy podczas odzwierciedlenia nadwyżek, niedoborów i przeklasyfikacji.';
							|tr = 'Ambarda ""%Warehouse%"", %Date%''da fazlalıkları, eksiklikleri, yeniden sınıflandırmayı ve stok kalite değişikliğini yansıtırken ambar yönetimi kullanılmıyor.'");
		MessageText = StrReplace(MessageText, "%Warehouse%", Warehouse);
		MessageText = StrReplace(MessageText, "%Date%", Format(Date, "DLF=D"));
		
		CommonClientServer.MessageToUser(MessageText, Ref);
		
	EndIf;
	
EndProcedure

Procedure CheckCompletionOfAppointments(Cancel)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.LineNumber             AS LineNumber,
	|	Goods.Purpose              AS Purpose,
	|	Goods.AssignmentGoodsReceipt AS AssignmentGoodsReceipt
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	AssignmentGoodsReceipt
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber               AS LineNumber,
	|	""AssignmentGoodsReceipt""      AS FieldName,
	|	&ErrorTextNotFilledInCorrectly AS ErrorText
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.AssignmentGoodsReceipt <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND CAST(Goods.AssignmentGoodsReceipt AS Catalog.Assignments).AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|	AND Goods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND CAST(Goods.Purpose AS Catalog.Assignments).AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|	AND (NOT CAST(Goods.Purpose AS Catalog.Assignments).Partner =
	|				CAST(ISNULL(Goods.AssignmentGoodsReceipt, VALUE(Catalog.Assignments.EmptyRef)) AS Catalog.Assignments).Partner
	|		OR NOT CAST(Goods.Purpose AS Catalog.Assignments).Contract =
	|				CAST(ISNULL(Goods.AssignmentGoodsReceipt, VALUE(Catalog.Assignments.EmptyRef)) AS Catalog.Assignments).Contract)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.LineNumber                   AS LineNumber,
	|	""AssignmentGoodsReceipt""          AS FieldName,
	|	&ErrorTextAssignmentIsNotGiveaway AS ErrorText
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.AssignmentGoodsReceipt <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND CAST(Goods.AssignmentGoodsReceipt AS Catalog.Assignments).AssignmentType <> VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|	AND Goods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND CAST(Goods.Purpose AS Catalog.Assignments).AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.LineNumber               AS LineNumber,
	|	""AssignmentGoodsReceipt""      AS FieldName,
	|	&ErrorTextNotFilledIn          AS ErrorText
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.AssignmentGoodsReceipt = VALUE(Catalog.Assignments.EmptyRef)
	|	AND Goods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND CAST(Goods.Purpose AS Catalog.Assignments).AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|
	|ORDER BY
	|	LineNumber
	|";
	
	Query.SetParameter("Goods", Goods.Unload(, "LineNumber, Purpose, AssignmentGoodsReceipt"));
	
	Query.SetParameter(
		"ErrorTextNotFilledInCorrectly",
		NStr("vi = 'Trong dòng %1 của danh sách ""Hàng hóa"", đặt riêng hàng hóa được ghi tăng theo mục đích của người đặt gia công mà trong đó bạn hàng/hợp đồng khác với bạn hàng/hợp đồng ban đầu.';
			|ru = 'В строке %1 списка ""Товары"" приходуемый товар обосабливается под назначение давальца, в котором партнер/договор отличается от исходного.';
			|en = 'In line %1 of the ""Goods"" list, the stock surplus is assigned for the provider assignment, in which the partner/contract is different from the initial one.'; fa = 'In line %1 of the ""Goods"" list, the stock surplus is assigned for the provider assignment, in which the partner/contract is different from the initial one.';
			|it = 'Nella riga %1 dell''elenco ""Merci"" la merce in arrivo viene divisa per assegnazione del fornitore, in cui il partner/contratto differisce da quello originario.';
			|pl = 'W wierszu %1 listy ""Towary"" rejestrowany towar jest oddzielany pod przeznaczenie właściciela surowców, w którym partner/umowa różni się od źródłowego.';
			|tr = '""Ürünler"" listesi %1 satırında, stok fazlası, müşterinin atamasına ayrılıyor, iş ortağı/sözleşmenin orijinalinden farklı olduğu şekilde ayrılır.'"));
		
	Query.SetParameter(
		"ErrorTextAssignmentIsNotGiveaway",
		NStr("vi = 'Trong dòng %1 của danh sách ""Hàng hóa"", cần đặt riêng hàng hóa được ghi tăng theo mục đích của người đặt gia công.';
			|ru = 'В строке %1 списка ""Товары"" приходуемый товар должен быть обособлен под назначение давальца.';
			|en = 'In line %1 of the ""Goods"" list, the stock surplus must be assigned for the provider assignment.'; fa = 'In line %1 of the ""Goods"" list, the stock surplus must be assigned for the provider assignment.';
			|it = 'Nella stringa %1 dell''elenco ""Merci"" la merce in arrivo deve essere divisa per assegnazione del fornitore.';
			|pl = 'W wierszu %1 listy ""Towary"" rejestrowany towar powinien być oddzielony pod przeznaczenie właściciela surowców.';
			|tr = '""Ürünler"" listesi %1 satırında, stok fazlasını müşterinin atamasına göre ayırmak gerekir.'"));
		
	Query.SetParameter(
		"ErrorTextNotFilledIn",
		NStr("vi = 'Trong dòng %1 của danh sách ""Hàng hóa"", chưa điền mục đích của hàng hóa được ghi tăng. ';
			|ru = 'В строке %1 списка ""Товары"" назначение приходуемого товара не заполнено.';
			|en = 'In line %1 of the ""Goods"" list, the stock surplus assignment is not filled.'; fa = 'In line %1 of the ""Goods"" list, the stock surplus assignment is not filled.';
			|it = 'Nella stringa %1 dell''elenco ""Merci"" l''assegnazione della merce in arrivo non è compilata.';
			|pl = 'W wierszu %1 listy ""Towary"" przeznaczenie rejestrowanego twoaru nie jest wypełnione.';
			|tr = '""Ürünler"" listesi %1 satırında, stok fazlasının ataması doldurulmadı.'"));
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		Common.MessageToUser(
			StrTemplate(Selection.ErrorText, Selection.LineNumber),
			ThisObject,
			CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, Selection.FieldName),,
			Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf