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
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShortageNote));
	
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

	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckPossibilityOfRounding = False;
	CheckParameters.CheckCompletenessOfProductLocations = True;
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	If Not WarehousesServer.UseBinLocationWarehousing(Warehouse,Premise,Date) Then
		NotCheckedAttributeArray.Add("Goods.Cell");
		NotCheckedAttributeArray.Add("Goods.Package");
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
	
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShortageNote),
												Cancel,
												NotCheckedAttributeArray);
	WarehousesServer.CheckWarehouseOrder(Warehouse, Date, "WhenReflectingSurplusShortages", Cancel);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument(FillingData);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);

EndProcedure

#EndRegion

#Region Other

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
		MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" vào ngày %Date% không sử dụng sơ đồ hóa đơn kiêm phiếu xuất nhập khi phản ánh hàng thừa, hàng thiếu và hàng hỏng.';
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