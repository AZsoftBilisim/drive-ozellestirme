#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsTransferNote));
	
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

	For Each LineProducts_ In ShippedGoods Do
		
		LineProducts_.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;
		
	EndDo;
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not AdditionalProperties.Property("DeferredPosting") Then
		If Not Posted
			And Status <> Enums.TransferNoteStatuses.ForPicking Then
			
			MessageText = NStr("vi = 'Chứng từ phải được kết chuyển ban đầu ở trạng thái ""Để lựa chọn""';
								|ru = 'Документ должен быть проведен сначала в статусе ""К отбору""';
								|en = 'Document should be posted in status ""For picking"" first'; fa = 'Document should be posted in status ""For picking"" first';
								|it = 'Il documento deve essere per prima registrato nello stato ""Per la selezione""';
								|pl = 'Dokument należy zatwierdzić od początku w statusie ""К отбору""';
								|tr = 'Belge önce ""Toplamaya hazır"" durumunda kaydedilmelidir'");
			
			CommonClientServer.MessageToUser(MessageText,ThisObject,"Status","Object",Cancel);
		EndIf;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "ShippedGoods";
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsTransferNote),
												Cancel,
												NotCheckedAttributeArray);	
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "ShippedGoods";
	CheckParameters.CheckPossibilityOfRounding = False;
	CheckParameters.CheckCompletenessOfProductLocations = True;
	CheckParameters.ConditionForSelectingCompletenessCheckLines = "ShippedGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);

	SenderUseAddressStorage = WarehousesServer.UseBinLocationWarehousing(Warehouse,SenderWareroom,DateOfShipment);
	
	ReceiverUseAddressableStorage = WarehousesServer.UseBinLocationWarehousing(Warehouse,ReceivingWareroom,DateOfShipment);
	
	If Not SenderUseAddressStorage
		Or Status = Enums.TransferNoteStatuses.ForPicking Then
		NotCheckedAttributeArray.Add("ShippingZone");
	EndIf;
	
	If Not ReceiverUseAddressableStorage
		Or (ReceiverUseAddressableStorage
		And Status <> Enums.TransferNoteStatuses.Accepted) Then
		NotCheckedAttributeArray.Add("ReceivingArea");
	EndIf;
	
	If (SenderUseAddressStorage
		Or ReceiverUseAddressableStorage)
		And Not GetFunctionalOption("UseItemPackages") Then
		
		NotCheckedAttributeArray.Add("ShippedGoods.Package");
		
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
		
	ElsIf Not((SenderUseAddressStorage
		And Status <> Enums.TransferNoteStatuses.ForPicking)
		Or (ReceiverUseAddressableStorage
		And Status = Enums.TransferNoteStatuses.Accepted))Then
		NotCheckedAttributeArray.Add("ShippedGoods.Package");
	Else
		CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
		CheckParameters.TSName = "ShippedGoods";
		CheckParameters.OtherPresentationPackagingUnits = NStr("vi = 'Đơn vị tính';
																|ru = 'Ед. изм.';
																|en = 'Unit'; fa = 'واحد';
																|it = 'Unità di misura';
																|pl = 'J. m.';
																|tr = 'Ölçü birimi.'");
		
		CheckParameters.SelectingRowsToCheck.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.Ship);
		ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
		
		CheckParameters.SelectingRowsToCheck.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.DoNotShip);
		ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
		
		ParametersForCheckingIndicationOfMultiTurnContainer = ReusablePackageServer.ParametersForCheckingIndicationOfMultiTurnContainer();
		ParametersForCheckingIndicationOfMultiTurnContainer.ThereAreCells = False;
		ParametersForCheckingIndicationOfMultiTurnContainer.TSName = "ShippedGoods";
		ParametersForCheckingIndicationOfMultiTurnContainer.RowFilter = New Structure("Action", Enums.ActionsWithGoodsIssueNoteRows.Ship);
		ReusablePackageServer.CheckIndicationOfMultiTurnContainer(ThisObject, ParametersForCheckingIndicationOfMultiTurnContainer, Cancel);
	EndIf;
	
	If Status = Enums.TransferNoteStatuses.Accepted
		Or Status = Enums.TransferNoteStatuses.ToShip Then
		FoundRows = ShippedGoods.FindRows(New Structure("Action", Enums.ActionsWithGoodsIssueNoteRows.Pick));
		
		PresentationOfTS = Metadata().TabularSections.ShippedGoods.Presentation();
		
		For Each RowOfTables In FoundRows Do
			Cancel = True;
			
			DataPath = CommonClientServer.PathToTabularSection("ShippedGoods", RowOfTables.LineNumber, "Action");
						
			MessageText = NStr("vi = 'Trong dòng %LineNumber% danh sách %TSName% , hành động ""%Pick%"". Không thể kết chuyển chứng từ trong trạng thái %DocumentStatus%. Phải chọn hành động: ""%DoNotShip%"" hoặc ""%Ship%"".';
								|ru = 'В строке %LineNumber% списка %TSName% выбрано действие ""%Pick%"". Невозможно проведение документа в статусе %DocumentStatus%. Необходимо выбрать действие: ""%DoNotShip%"" или ""%Ship%"".';
								|en = 'You have selected action ""%Pick%"" in line %LineNumber% of the %TSName% list. Cannot post the document in status %DocumentStatus%. Select action ""%DoNotShip%"" or ""%Ship%"".'; fa = 'You have selected action ""%Pick%"" in line %LineNumber% of the %TSName% list. Cannot post the document in status %DocumentStatus%. Select action ""%DoNotShip%"" or ""%Ship%"".';
								|it = 'Nella riga %LineNumber% dell''elenco %TSName% è selezionata l''azione ""%Pick%"". Impossibile registrare il documento nello stato %DocumentStatus%. È necessario selezionare l''azione: ""%DoNotShip%"" o ""%Ship%"".';
								|pl = 'W wierszu %LineNumber% listy %TSName% wybrano czynność ""%Pick%"". Nie jest mozliwe zaksięgowanie dokumentu ze statusem%DocumentStatus%. Nalezy wybrać czynność: ""%DoNotShip%"" lub ""%Ship%"".';
								|tr = '%TSName% listenin %LineNumber% satırında ""%Pick%"" eylemi seçilir. %DocumentStatus% durumda belge kaydetmek mümkün değil. Bir eylem seçmelisiniz: ""%DoNotShip%"" veya ""%Ship%"".'");
			
			MessageText = StrReplace(MessageText, "%LineNumber%", RowOfTables.LineNumber);
			MessageText = StrReplace(MessageText, "%TSName%", PresentationOfTS);
			MessageText = StrReplace(MessageText, "%Pick%", String(Enums.ActionsWithGoodsIssueNoteRows.Pick));
			MessageText = StrReplace(MessageText, "%DocumentStatus%", String(Status));
			MessageText = StrReplace(MessageText, "%DoNotShip%", String(Enums.ActionsWithGoodsIssueNoteRows.DoNotShip));
			MessageText = StrReplace(MessageText, "%Ship%", String(Enums.ActionsWithGoodsIssueNoteRows.Ship));
			
			CommonClientServer.MessageToUser(MessageText, Ref, DataPath);
		EndDo;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If ValueIsFilled(SenderWareroom)
		And ValueIsFilled(ReceivingWareroom)
		And SenderWareroom = ReceivingWareroom Then

		CommonClientServer.MessageToUser(NStr("vi = 'Một nhà kho không thể đồng thời vừa là nơi gửi vừa là nơi nhận';
												|ru = 'Одно и то же складское помещение не может являться отправителем и получателем одновременно.';
												|en = 'The same wareroom cannot be both shipping and receiving.'; fa = 'The same wareroom cannot be both shipping and receiving.';
												|it = 'Lo stesso magazzino non può essere mittente e destinatario contemporaneamente.';
												|pl = 'Jedno i to samo pomieszczenie magazynowe nie może być nadawcą i odbiorcą jednocześnie.';
												|tr = 'Aynı depo aynı anda hem gönderen hem de alıcı olamaz.'"),
				ThisObject,
				"SenderWareroom",,Cancel);

	EndIf;
	
	WarehousesServer.CheckWarehouseOrder(Warehouse, DateOfShipment, "WhenReflectingSurplusShortages", Cancel);
	WarehousesServer.CheckWarehouseOrder(Warehouse, DateOfShipment, "OnShipment", Cancel);
	WarehousesServer.CheckWarehouseOrder(Warehouse, DateOfShipment, "OnReceipt", Cancel);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument(FillingData);
	
	If ValueIsFilled(Warehouse)
		And Not WarehousesServer.UseWarerooms(Warehouse,DateOfShipment) Then
		
		MessageText = NStr("vi = 'Không thể tạo ""Phiếu điều chuyển hàng hóa"" vì trong kho ""%Warehouse%"" ngày %DateOfShipment% không sử dụng nhà kho.';
							|ru = 'Не удалось создать ""Ордер на перемещение товаров"", поскольку на складе ""%Warehouse%"" на %DateOfShipment% не используются складские помещения.';
							|en = 'Cannot create ""Internal stock transfer"" as warerooms are not used in warehouse ""%Warehouse%"" on %DateOfShipment%.'; fa = 'Cannot create ""Internal stock transfer"" as warerooms are not used in warehouse ""%Warehouse%"" on %DateOfShipment%.';
							|it = 'Impossibile creare ""Mandato per il movimento di merci"", perché nel magazzino %Warehouse% al %DateOfShipment% non vengono utilizzati i settori del magazzino.';
							|pl = 'Nie udało się utworzyć ""Ордер на перемещение товаров"", ponieważ w magazynie ""%Warehouse%"" na %DateOfShipment% nie są używane pomieszczenia magazynowe.';
							|tr = '""Dahili stok transferi"" oluşturulamadı çünkü ''''%Warehouse%"" ambarında %DateOfShipment%''da kullanımda olan depolar mevcut değil.'");
		MessageText = StrReplace(MessageText,"%Warehouse%",Warehouse);
		MessageText = StrReplace(MessageText,"%DateOfShipment%",Format(DateOfShipment,"DLF=D"));
		Raise MessageText;
		
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();
	Status        = Metadata().Attributes.Status.FillValue;
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Priority     = SettingsValueCached.GetDefaultPriority(Priority);
	
	If Not ValueIsFilled(DateOfShipment) Then
		DateOfShipment = CurrentSessionDate();
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndIf