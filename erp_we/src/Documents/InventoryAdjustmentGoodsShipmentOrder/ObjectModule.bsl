#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryAdjustmentGoodsShipmentOrder));
	
EndProcedure

Procedure OnWrite(Cancel)
		
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)

	InitializeDocument(FillingData);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	WarehousesServer.ReflectStatesOfCellRecalculations(ThisObject.Ref, Undefined, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	InitializeDocument();

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryAdjustmentGoodsShipmentOrder),
												Cancel,
												NotCheckedAttributeArray);
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
	CheckParameters.OtherPresentationPackagingUnits = NStr("vi = 'Đơn vị tính';
															|ru = 'Ед. изм.';
															|en = 'Unit'; fa = 'واحد';
															|it = 'Unità di misura';
															|pl = 'J. m.';
															|tr = 'Ölçü birimi.'");
	ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
	
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
		|tr = 'Uygulama ayarlarında ürün paketleme kullanımı etkin değildir,
		|bu nedenle depo konum takibi olan bir ambar için belge düzenleyemezsiniz. Yönetici ile iletişime geçin'");
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndIf;
	
	ThereIsTransfer_ 				   = False;
	ThereIsRegistrationInShipmentZone = False;
	
	For Each RowOfTables In Goods Do
		
		If RowOfTables.OperationKind = Enums.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote Then
			ThereIsTransfer_ = True;
		ElsIf RowOfTables.OperationKind = Enums.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea
			Or RowOfTables.OperationKind = Enums.OperationKindsOfStockBalanceAdjustingEntries.LeaveInShippingArea Then
			ThereIsRegistrationInShipmentZone = True;
		EndIf;	
		
	EndDo;
	
	If Not ThereIsTransfer_ Then
		NotCheckedAttributeArray.Add("RecipientNote");
	EndIf;	
	
	If Not ThereIsRegistrationInShipmentZone Then
		NotCheckedAttributeArray.Add("ShippingZone");
	EndIf;	
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf