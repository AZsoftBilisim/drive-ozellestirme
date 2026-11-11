#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not UserRightsCached.PutGoodsIssueNoteIntoOperation() Then
		
		If  Status <> Enums.GoodsIssueNoteStatuses.Prepared
			And WriteMode = DocumentWriteMode.Posting Then
			
			MessageText = StrTemplate(NStr("vi = 'Không có đủ quyền để đưa một lệnh chi phí vào công việc. Không thể thực hiện thay đổi trạng thái. (%1)';
											|ru = 'Недостаточно прав на взятие расходного ордера в работу. Изменения статуса не выполнено. (%1)';
											|en = 'Insufficient rights to put a goods issue into operation. The status is not changed. (%1)'; fa = 'Insufficient rights to put a goods issue into operation. The status is not changed. (%1)';
											|it = 'Недостаточно прав на взятие расходного ордера в работу. Изменения статуса не выполнено. (%1)';
											|pl = 'Insufficient rights to put a goods issue into operation. The status is not changed. (%1)';
											|tr = 'Ambar çıkış fişini işleme almak için yetersiz yetki. Durum değişikliği gerçekleşmedi. (%1)'"), Ref);
			Raise MessageText;
			
		EndIf;
		
		OldStatus = Common.ObjectAttributeValue(Ref, "Status");
		
		If OldStatus <> Enums.GoodsIssueNoteStatuses.Prepared
			And OldStatus <> Undefined Then
			
			MessageText = StrTemplate(NStr("vi = 'Không có đủ quyền để thay đổi trạng thái của lệnh chi phí được thực hiện. (%1)';
											|ru = 'Недостаточно прав на изменение статуса расходного ордера, взятого в работу. (%1)';
											|en = 'Insufficient rights to change a status of the goods issue note that was accepted for processing. (%1)'; fa = 'Insufficient rights to change a status of the goods issue note that was accepted for processing. (%1)';
											|it = 'Недостаточно прав на изменение статуса расходного ордера, взятого в работу. (%1)';
											|pl = 'Insufficient rights to change a status of the goods issue note that was accepted for processing. (%1)';
											|tr = 'İşleme alınan ambar çıkış fişinin durumunu değiştirmek için yetersiz yetki. (%1)'"), Ref);
			Raise MessageText;
			
		EndIf;
		
	EndIf;
	
	StructureWarehouseForFO = New Structure;
	StructureWarehouseForFO.Insert("Warehouse", Warehouse);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsIssueNote);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.GoodsByReferences);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.ShippedGoods);
	
	If Not GetFunctionalOption("UseGoodsIssueNoteStatuses", StructureWarehouseForFO) Then
		Status = Enums.GoodsIssueNoteStatuses.Shipped_;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		CheckOrderWarehouse(Cancel);
	EndIf;
	
	ShipmentAfterTaskIsUsed = GetFunctionalOption(
		"StartShipmentOnceDeliveryOrderIsCreated",
		StructureWarehouseForFO);
	If Not ShipmentAfterTaskIsUsed
		And GoodsDeliveryClientServer.UsedDelivery25() Then
		
		ShipmentUnderTransportationJob = False;
		TransportationJob = Undefined;
		
	EndIf;
	
	TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(ShippedGoods);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	Var Cancel;
	
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;
	
	If Not (ValueIsFilled(Warehouse)
		And ValueIsFilled(WarehouseOperation)
		And (ValueIsFilled(Recipient) Or WarehouseOperation = Enums.WarehouseTransactions.ShipmentForInternalNeeds)
		And ValueIsFilled(DateOfShipment)) Then
		
		Cancel = True;
		
	Else
		
		UsePremises = WarehousesServer.UseWarerooms(Warehouse, DateOfShipment, True);

		If UsePremises
			And Not ValueIsFilled(Premise) Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
	If Cancel = True Then
		MessageText = NStr("vi = 'Chỉ có thể lập phiếu xuất kho chỉ trên cơ sở lệnh giao hàng.';
							|ru = 'Расходный ордер на товары можно вводить только на основании распоряжения на отгрузку товаров.';
							|en = 'Goods issue can be entered only on the basis of a shipment reference.'; fa = 'Goods issue can be entered only on the basis of a shipment reference.';
							|it = 'Mandato di pagamento per le merci si può inserire soltanto in base alla disposizione di spedizione delle merci.';
							|pl = 'Zlecenie wydania towarów można wprowadzić tylko na podstawie zamówienia na wysyłkę towarów.';
							|tr = 'Ambar çıkış fişi yalnızca bir ürün sevkiyat emri temelinde girilebilir.'");
		Raise MessageText;
	EndIf;
		
	InitializeDocument(FillingData);
	
	SeriesSpecificationParameters = Documents.GoodsIssueNote.SeriesSpecificationParameters(ThisObject);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.GoodsByReferences); 
	
	Documents.GoodsIssueNote.FillInShippedGoodsByGoodsByOrders(ThisObject);
	
	Documents.GoodsIssueNote.FillInActionInLines(ThisObject);
	
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters.ShippedGoods, False); 
	
	If Not WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, DateOfShipment)
		And GetFunctionalOption("UseItemPackages") Then
		Documents.GoodsIssueNote.SplitByPackagesForReference(ThisObject);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.ShippedGoods); 
	
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
	
	If Not AdditionalProperties.Property("DeferredPosting") Then
		
		FOParameters = New Structure;
		FOParameters.Insert("Warehouse", Warehouse);
		
		If Not Posted
			And Status <> Enums.GoodsIssueNoteStatuses.ForPicking
			And Status <> Enums.GoodsIssueNoteStatuses.Prepared
			And (GetFunctionalOption("UseItemsBatchWarehouse",FOParameters)
			Or WarehousesServer.UseWarerooms(Warehouse, DateOfShipment)
			Or WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, DateOfShipment)) Then
			
			MessageText = NStr("vi = 'Chứng từ phải được kết chuyển ban đầu ở trạng thái ""Để lựa chọn"" hoặc ""Chuẩn bị""';
								|ru = 'Документ должен быть проведен сначала в статусе ""К отбору"" или ""Подготовлен""';
								|en = 'The document must be posted with the ""Pick list"" or ""Prepared"" status first'; fa = 'The document must be posted with the ""Pick list"" or ""Prepared"" status first';
								|it = 'Документ должен быть проведен сначала в статусе ""К отбору"" или ""Подготовлен""';
								|pl = 'The document must be posted with the ""Pick list"" or ""Prepared"" status first';
								|tr = 'Belge öncelikle ""Toplamaya hazır"" veya ""Hazırlandı"" durumunda tutulmalıdır'");
			
			CommonClientServer.MessageToUser(MessageText,ThisObject,"Status","Object",Cancel);
		EndIf;
	EndIf;

	NotCheckedAttributeArray = New Array;

	NotCheckedAttributeArray.Add("TransportationJob");
	
	ShipmentAfterTaskIsUsed = GetFunctionalOption(
		"StartShipmentOnceDeliveryOrderIsCreated",
		New Structure("Warehouse", Warehouse));
	
	ThisIs25DeliveryShipment = 
		(GoodsDeliveryClientServer.UsedDelivery25()
			And ShipmentAfterTaskIsUsed
			And ShipmentUnderTransportationJob);
	ThisIsDeliveryShipmentOf20 =
		(Not GoodsDeliveryClientServer.UsedDelivery25()
			And ShipmentUnderTransportationJob);
	
	If ThisIs25DeliveryShipment
		Or ThisIsDeliveryShipmentOf20 Then
		
		If Not GoodsDelivery.ThereIsDeliveryOnWarehouseOperation(WarehouseOperation) Then
			
			MessageTemplate = NStr("vi = 'Đối với hoạt động kho %1 giao hàng không được cung cấp';
									|ru = 'Для складской операции %1 доставка не предусмотрена';
									|en = 'The %1 warehouse operation cannot include delivery'; fa = 'The %1 warehouse operation cannot include delivery';
									|it = 'The %1 warehouse operation cannot include delivery';
									|pl = 'The %1 warehouse operation cannot include delivery';
									|tr = '%1 ambar işlemi için teslimat öngörülmemiş'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				String(WarehouseOperation));
			
			CommonClientServer.MessageToUser(MessageText, ThisObject,,, Cancel);
			
		ElsIf Not ValueIsFilled(TransportationJob)
			And (ShipmentAfterTaskIsUsed
				Or Status = Enums.GoodsIssueNoteStatuses.ToShip
				Or Status = Enums.GoodsIssueNoteStatuses.Shipped_) Then
			
			If GoodsDeliveryClientServer.UsedDelivery25() Then
				FieldName = NStr("vi = 'Chuyến đi';
								|ru = 'Рейс';
								|en = 'Trip'; fa = 'سفر';
								|it = 'Trip';
								|pl = 'Trip';
								|tr = 'Sefer'");
			Else
				FieldName = NStr("vi = 'Nhiệm vụ vận chuyển';
								|ru = 'Задание на перевозку';
								|en = 'Itinerary'; fa = 'مسیر سفر';
								|it = 'Task di trasporto';
								|pl = 'Zadanie przewozu';
								|tr = 'Taşıma planı'");
			EndIf;
			MessageText = CommonClientServer.FillingErrorText(,, FieldName);
			CommonClientServer.MessageToUser(
				MessageText, ThisObject, "TransportationJob", "Object", Cancel);
			
		ElsIf Status <> Enums.GoodsIssueNoteStatuses.Shipped_
			And ValueIsFilled(TransportationJob) Then
			
			If GoodsDeliveryClientServer.UsedDelivery25() Then
				
				FlightStatus = Common.ObjectAttributeValue(TransportationJob, "Status");
				
				If FlightStatus = Enums.TripStatuses.Shipped_5
					Or FlightStatus = Enums.TripStatuses.Completed
					Or FlightStatus = Enums.TripStatuses.RolledBack_ Then
					
					MessageTemplate = NStr("vi = 'Chuyến đi đã chọn đang ở trạng thái ""%1"", do đó không thể chỉ định trong phiếu đang ở trạng thái ""%2"". Vui lòng thay đổi trạng thái của phiếu sang ""%3"".';
											|ru = 'Выбранный рейс находится в статусе ""%1"", поэтому его нельзя указать в ордере, который находится в статусе ""%2"". Измените статус ордера на ""%3"".';
											|en = 'The selected trip has the ""%1"" status, so you cannot specify it in the note that has the ""%2"" status. Change the note status to ""%3"".'; fa = 'The selected trip has the ""%1"" status, so you cannot specify it in the note that has the ""%2"" status. Change the note status to ""%3"".';
											|it = 'The selected trip has the ""%1"" status, so you cannot specify it in the note that has the ""%2"" status. Change the note status to ""%3"".';
											|pl = 'The selected trip has the ""%1"" status, so you cannot specify it in the note that has the ""%2"" status. Change the note status to ""%3"".';
											|tr = 'Seçilen sefer ""%1"" durumundadır, bu yüzden ""%2"" durumundaki siparişte belirtilemez. Sipariş durumunu ""%3"" olarak değiştirin.'");
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						MessageTemplate,
						String(FlightStatus),
						String(Status),
						String(Enums.GoodsIssueNoteStatuses.Shipped_));
					
					CommonClientServer.MessageToUser(
						MessageText, ThisObject, "Status", "Object", Cancel);
					
				EndIf;
				
			Else
				
				TransportationJobStatus = Common.ObjectAttributeValue(TransportationJob, "Status");
				
				If TransportationJobStatus = Enums.StatusesOfTransportationJobs.Sent
					Or TransportationJobStatus = Enums.StatusesOfTransportationJobs.Closed Then
					
					MessageTemplate = NStr("vi = 'Nhiệm vụ vận chuyển đã chọn ở trạng thái ""%1"", vì vậy không thể chỉ ra nhiệm vụ đó trong lệnh có trạng thái ""%2"". Hãy thay đổi trạng thái của lệnh sang ""%3"".';
											|ru = 'Выбранное задание на перевозку находится в статусе ""%1"", поэтому его нельзя указать в ордере, который находится в статусе ""%2"". Измените статус ордера на ""%3"".';
											|en = 'The selected itinerary has the ""%1"" status, so you cannot specify it in the note that has the ""%2"" status. Change the note status to ""%3"".'; fa = 'The selected itinerary has the ""%1"" status, so you cannot specify it in the note that has the ""%2"" status. Change the note status to ""%3"".';
											|it = 'The selected itinerary has the ""%1"" status, so you cannot specify it in the note that has the ""%2"" status. Change the note status to ""%3"".';
											|pl = 'The selected itinerary has the ""%1"" status, so you cannot specify it in the note that has the ""%2"" status. Change the note status to ""%3"".';
											|tr = 'Seçilen taşıma görevi ""%1"" durumundadır, bu yüzden ""%2"" durumundaki siparişte belirtilemez. Sipariş durumunu ""%3"" olarak değiştirin.'");
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						MessageTemplate,
						String(TransportationJobStatus),
						String(Status),
						String(Enums.GoodsIssueNoteStatuses.Shipped_));
					
					CommonClientServer.MessageToUser(
						MessageText, ThisObject, "Status", "Object", Cancel);
					
				EndIf;
			
			EndIf;
			
		EndIf;
		
		If GoodsDeliveryClientServer.UsedDelivery25() Then
			
			TemplateTypeIsNotSupported = NStr("vi = 'Loại lệnh ""%1"" không được hỗ trợ để lập vận đơn.';
												|ru = 'Тип распоряжения ""%1"" не поддерживается для оформления доставки.';
												|en = 'The ""%1"" reference type is not supported for shipment registration.'; fa = 'The ""%1"" reference type is not supported for shipment registration.';
												|it = 'The ""%1"" reference type is not supported for shipment registration.';
												|pl = 'The ""%1"" reference type is not supported for shipment registration.';
												|tr = '""%1"" talimat türü teslimat oluşturma için desteklenmiyor.'");
			ColumnName = Metadata.Documents.GoodsIssueNote.TabularSections.GoodsByReferences.Attributes.ReferenceOrder.Synonym;
			ListName = Metadata.Documents.GoodsIssueNote.TabularSections.GoodsByReferences.Synonym;
			
			TypesOfDeliveryOrder = Metadata.DefinedTypes.DeliveryReferenceOrder25.Type.Types();
			For Each LineWithOrder In GoodsByReferences Do
				
				If LineWithOrder.ReferenceOrder.IsEmpty() Then
					Continue;
				EndIf;
				
				TypeOfOrder_ = TypeOf(LineWithOrder.ReferenceOrder);
				If TypesOfDeliveryOrder.Find(TypeOfOrder_) = Undefined Then
					
					TextTypeIsNotSupported = StringFunctionsClientServer.SubstituteParametersToString(
						TemplateTypeIsNotSupported,
						String(TypeOfOrder_));
						
					ErrorTextOrderType = CommonClientServer.FillingErrorText(
						"Column",
						"Correctness",
						ColumnName,
						LineWithOrder.LineNumber,
						ListName,
						TextTypeIsNotSupported);
						
					Field = CommonClientServer.PathToTabularSection(
						"GoodsByReferences", LineWithOrder.LineNumber, "ReferenceOrder");
					
					Common.MessageToUser(ErrorTextOrderType, ThisObject, Field,, Cancel);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	If Not WarehousesServer.UseWarerooms(Warehouse,DateOfShipment) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	If WarehouseOperation = Enums.WarehouseTransactions.ShipmentForInternalNeeds Then
		NotCheckedAttributeArray.Add("Recipient");
	EndIf;
	
	UsePackingLists = GetFunctionalOption("UsePackingLists");
	
	If Not WarehousesServer.UseBinLocationWarehousing(Warehouse,Premise,DateOfShipment) Then
		NotCheckedAttributeArray.Add("ShippedGoods.Package");
		NotCheckedAttributeArray.Add("ShippingZone");
	Else
		If Status = Enums.GoodsIssueNoteStatuses.ForPicking
			Or Status = Enums.GoodsIssueNoteStatuses.Prepared Then
			NotCheckedAttributeArray.Add("ShippedGoods.Package");
		Else
			
			CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
			CheckParameters.OutputLineNumbers = Not UsePackingLists;
			CheckParameters.TSName = "ShippedGoods";
			CheckParameters.SelectingRowsToCheck.Insert("ThisIsAPackingList", False);
			CheckParameters.OtherPresentationPackagingUnits = NStr("vi = 'Đơn vị tính';
																	|ru = 'Ед. изм.';
																	|en = 'Unit'; fa = 'واحد';
																	|it = 'Unità di misura';
																	|pl = 'J. m.';
																	|tr = 'Ölçü birimi.'");
			
			CheckParameters.SelectingRowsToCheck.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.Ship);
			ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
			
			CheckParameters.SelectingRowsToCheck.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.DoNotShip);
			ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
			
		EndIf;
		
		If Not GetFunctionalOption("UseItemPackages") Then
			NotCheckedAttributeArray.Add("Goods.Package");
			MessageText = NStr("vi = 'Trong tùy chỉnh chương trình chưa bật sử dụng đóng gói mặt hàng, 
			|do đó không thể lập chứng từ theo kho có lưu số dư theo địa chỉ. Hãy liên hệ với người quản trị';
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
	EndIf;	
	
	If Status = Enums.GoodsIssueNoteStatuses.Shipped_ Then
		
		If DateOfShipment > CurrentSessionDate() Then
			
			MessageText = NStr("vi = 'Khi kết chuyển phiếu xuất kho với trạng thái ""%Shipped_%"", ngày giao hàng cần phải lớn hơn ngày hiện tại.';
								|ru = 'При проведении расходного ордера в статусе ""%Shipped_%"" дата отгрузки должна быть не больше текущей даты.';
								|en = 'Shipment date should not be later than the current date while posting the goods issue note in status ""%Shipped_%"".'; fa = 'Shipment date should not be later than the current date while posting the goods issue note in status ""%Shipped_%"".';
								|it = 'Durante la registrazione del mandato di pagamento con lo stato ""%Shipped_%"" la data di spedizione non deve essere successiva alla data corrente.';
								|pl = 'Podczas zaksięgowania zlecenia wydania ze statusem ""%Shipped_%"" data wysłania nie może być większa niz bieżąca data.';
								|tr = '""%Shipped_%"" durumundaki bir ambar çıkış fişini gönderirken, sevkiyat tarihi mevcut tarihten sonra olmamalıdır.'");
			
			MessageText = StrReplace(MessageText,"%Shipped_%",Enums.GoodsIssueNoteStatuses.Shipped_);
			
			CommonClientServer.MessageToUser(MessageText,ThisObject,"DateOfShipment","Object",Cancel);
			
		EndIf;
	EndIf;

	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.OutputLineNumbers = Not UsePackingLists;
	CheckParameters.TSName = "GoodsByReferences"; 
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.OutputLineNumbers = Not UsePackingLists;
	CheckParameters.TSName = "ShippedGoods"; 
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	SeriesSpecificationParameters =
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsIssueNote);
	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.GoodsByReferences);
	ParametersArray.Add(SeriesSpecificationParameters.ShippedGoods);
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ParametersArray,
		Cancel,
		NotCheckedAttributeArray);

	If UsePackingLists Then											
		PackingListsServer.CheckFillingOfPMWithPackingLists(ThisObject, CheckedAttributes, NotCheckedAttributeArray, Cancel, "ShippedGoods");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "ShippedGoods";
	CheckParameters.CheckPossibilityOfRounding = False;
	CheckParameters.CheckCompletenessOfProductLocations = True;
	CheckParameters.ConditionForSelectingCompletenessCheckLines = "ShippedGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	WarehousesServer.CheckWarehouseOrder(Warehouse, DateOfShipment, "OnShipment", Cancel);
	
	If Status = Enums.GoodsIssueNoteStatuses.Verified
		Or Status = Enums.GoodsIssueNoteStatuses.ToShip
		Or Status = Enums.GoodsIssueNoteStatuses.Shipped_ Then
		
		FoundRows = ShippedGoods.FindRows(New Structure("Action", Enums.ActionsWithGoodsIssueNoteRows.Pick)); // Array of LineOfATabularSection
		
		PresentationOfTS = Metadata().TabularSections.ShippedGoods.Presentation();
		
		For Each RowOfTables In FoundRows Do
			Cancel = True;
			
			DataPath = CommonClientServer.PathToTabularSection("ShippedGoods", RowOfTables.LineNumber, "Action");
						
			MessageText = NStr("vi = 'Trong dòng %LineNumber% của danh sách %TSName% đã chọn thao tác ""%Pick%"". Không thể kết chuyển chứng từ ở trạng thái %DocumentStatus%. Cần chọn thao tác: ""%DoNotShip%"" hoặc ""%Ship%"".';
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
			
	If TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		CheckCorrespondenceOfRowsOfTableParts(Cancel);
	EndIf;
	
	GoodsIssueNoteLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure CheckCorrespondenceOfRowsOfTableParts(Cancel)
	
	Selection = Documents.GoodsIssueNote.SelectionFromRequestForExceedingOrders(ThisObject);
	
	MessageTemplate = NStr("vi = 'Số lượng hàng hóa %OwnGoods% mà cần giao theo lệnh giao hàng không bằng số lượng được giao bởi lệnh.';
							|ru = 'Количество товара %OwnGoods%, которое нужно отгрузить по распоряжениям на отгрузку не равно количеству, которое отгружается ордером.';
							|en = 'Quantity of goods %OwnGoods% that needs to be shipped under shipment references is not equal to the quantity shipped under the note.'; fa = 'Quantity of goods %OwnGoods% that needs to be shipped under shipment references is not equal to the quantity shipped under the note.';
							|it = 'Quantità di merce %OwnGoods%, che deve essere spedita in base alle disposizioni di spedizione non è uguale alla quantità spedita con il mandato.';
							|pl = 'Ilość wierszy pozycji %OwnGoods%, którą należy wysłać zgodnie z zamówieniami wysyłki, nie jest równa ilości wysyłanej na podstawie zlecenia.';
							|tr = 'Sevkiyat emirlerine göre sevk edilmesi gereken ürün miktarı %OwnGoods%, siparişle sevk edilen miktara eşit değildir.'");
	
	While Selection.Next() Do
		Cancel = True;
		OwnGoodsPresentation = ProductsClientServer.ProductPresentation(Selection.Products,
																	Selection.Characteristic,
																	,
																	Selection.Series,
																	Selection.Purpose);
		MessageText = StrReplace(MessageTemplate,"%OwnGoods%", OwnGoodsPresentation);
		
		CommonClientServer.MessageToUser(MessageText,ThisObject.Ref);
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	
	If WarehousesServer.UseBinLocationWarehousing(Warehouse,Premise,DateOfShipment) Then
		ShippingZone = Catalogs.StorageBins.DefaultShippingZone(Warehouse,Premise,ShippingZone);
	EndIf;
	
	If GetFunctionalOption("UseGoodsIssueNoteStatuses", New Structure("Warehouse", Warehouse)) Then
		MetadataObjectStatus = Metadata().Attributes.Status; // MetadataObjectAttribute
		Status = MetadataObjectStatus.FillValue;
	Else
		Status = Enums.GoodsIssueNoteStatuses.Shipped_;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckOrderWarehouse(Cancel)
	
	If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Warehouse, Date) Then
		
		Cancel = True;
		MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" vào ngày %Date% không sử dụng sơ đồ hóa đơn kiêm phiếu xuất nhập khi giao hàng.';
							|ru = 'На складе ""%Warehouse%"" на %Date% не используется ордерная схема при отгрузке.';
							|en = 'Warehouse management is not used in warehouse ""%Warehouse%"" for shipping as of %Date%.'; fa = 'Warehouse management is not used in warehouse ""%Warehouse%"" for shipping as of %Date%.';
							|it = 'Nel magazzino ""%Warehouse%"" al %Date% non si usa lo schema dei mandati durante la spedizione.';
							|pl = 'W magazynie ""%Warehouse%"" na dzień %Date% nie jest używany schemat zleceniowy podczas wysyłki.';
							|tr = 'Sevkiyat sırasında ""%Warehouse%"" ambarda %Date%''da ambar yönetimi kullanılmıyor.'");
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
#EndIf