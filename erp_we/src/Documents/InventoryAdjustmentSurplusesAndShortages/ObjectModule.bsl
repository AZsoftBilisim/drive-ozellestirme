#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryAdjustmentSurplusesAndShortages));
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckCompletenessOfProductLocations = True;
	CheckParameters.ConditionForSelectingCompletenessCheckLines = "Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)";
	ProductsServer.CheckCompletenessOfProductLocations(Goods, Cancel, CheckParameters);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckCompletenessOfProductLocations = True;
	CheckParameters.ConditionForSelectingCompletenessCheckLines = "Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)";
	ProductsServer.CheckCompletenessOfProductLocations(Goods, Cancel, CheckParameters);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryAdjustmentSurplusesAndShortages),
												Cancel,
												NotCheckedAttributeArray);
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel);
	
	If Not GetFunctionalOption("UseItemPackages") Then
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
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#EndIf
