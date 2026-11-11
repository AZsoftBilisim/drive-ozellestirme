#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
	
	BinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date);
	UsePackingLists = GetFunctionalOption("UsePackingLists");
	
	If BinLocationWarehousing And Not GetFunctionalOption("UseItemPackages") Then
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
		|tr = 'Uygulama ayarlarında ürün paketleme ünitelerinin kullanımı etkin değildir,
		|bu nedenle depo konum takibi olan bir ambar için belge düzenleyemezsiniz. Yönetici ile iletişime geçin'");
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndIf;
	
	If (Not BinLocationWarehousing
		Or Status = Enums.GoodsReceiptNoteStatuses.ToReceive)Then
		NotCheckedAttributeArray.Add("Goods.Package");
	Else
		CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
		CheckParameters.OutputLineNumbers = Not UsePackingLists;
		CheckParameters.SelectingRowsToCheck.Insert("ThisIsAPackingList", False);
		ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	EndIf;
	
	If Status = Enums.GoodsReceiptNoteStatuses.ToReceive 
		Or Status = Enums.GoodsReceiptNoteStatuses.InProgress Then
	
		NotCheckedAttributeArray.Add("Goods");
		
	EndIf;
	
	If Status = Enums.GoodsReceiptNoteStatuses.ToReceive Then
		
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		NotCheckedAttributeArray.Add("Goods.Count");
		
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.OutputLineNumbers = Not UsePackingLists;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, DataProcessors.GoodsQuantityCheckInGoodsReceiptNote),
												Cancel);
	
	PackingListsServer.CheckFillingOfPMWithPackingLists(ThisObject, CheckedAttributes, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
EndProcedure

#EndRegion

#EndIf