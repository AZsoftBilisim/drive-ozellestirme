
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Writes to the register.
//
// Parameters:
//  OrderRef  - DocumentRef - Link to the order to add.
//  Recorder - Undefined, DocumentRef - Recorder
Procedure AddOrderToQueue(OrderRef, Recorder = Undefined) Export
	
	If Not GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not Metadata.InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.Dimensions.OrderDocument.Type.ContainsType(TypeOf(OrderRef)) Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.OrderQueueToAdjustRowsOfMeasuringGoods");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("OrderDocument",OrderRef);
	Block.Lock();
	
	RecordManager = InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.CreateRecordManager();
	RecordManager.OrderDocument = OrderRef;
	RecordManager.Read();

	If RecordManager.Selected() Then
		Return;
	Else
		RecordManager.OrderDocument          = OrderRef;
		RecordManager.AddedOn = CurrentSessionDate();
		
		Try
			RecordManager.Write();
		Except
			
			If ValueIsFilled(Recorder) Then
				MessageText = NStr("vi = 'Không thể kết chuyển chứng từ: %Ref% vì lý do: %Cause%';
									|ru = 'Не удалось выполнить проведение документа: %Ref% по причине: %Cause%';
									|en = 'Cannot post document: %Ref%. Reason: %Cause%'; fa = 'Cannot post document: %Ref%. Reason: %Cause%';
									|it = 'Impossibile registrare il documento: %Ref% a causa: %Cause%';
									|pl = 'Nie można wykonać zaksięgowanie dokumentu: %Ref% z powodu: %Cause%';
									|tr = '%Cause% nedeniyle %Ref% belge kaydı gerçekleştirilemedi'");
				MessageText = StrReplace(MessageText, "%Ref%", Recorder);
				MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
				WriteLogEvent(InfobaseUpdate.EventLogEvent(),
					EventLogLevel.Error, Recorder.Metadata(), Recorder, MessageText);
			Else
				MessageText = NStr("vi = 'Không thể thêm đơn hàng %OrderDocument%vào trình tự điều chỉnh dòng hàng hóa đo lường';
									|ru = 'Не удалось добавить в очередь корректировки строк мерных товаров заказ %OrderDocument%';
									|en = 'Cannot add the %OrderDocument% order to the queue for adjustment of lines with measured goods'; fa = 'Cannot add the %OrderDocument% order to the queue for adjustment of lines with measured goods';
									|it = 'Non è stato possibile aggiungere alla coda di correzione delle righe delle merci misurabili l''ordine %OrderDocument%';
									|pl = 'Nie udało się dodać do kolejki korekty wierszy towarów wymiarowych towarów %OrderDocument%';
									|tr = 'Ölçülen ürün satırlarının düzeltme sırasına %OrderDocument% siparişi eklenemedi'");
				MessageText = StrReplace(MessageText, "%OrderDocument%", OrderRef);
				WriteLogEvent(InfobaseUpdate.EventLogEvent(),
					EventLogLevel.Error,,, MessageText);
			EndIf;
			
			Raise;
			
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf