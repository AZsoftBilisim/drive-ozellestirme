#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Add a package with an error to the queue
//
// Parameters:
//  OfflineEquipment_ - CatalogRef
//  TransferID - Undefined, Arbitrary - 
//  ErrorText - String
//
Procedure AddDataPacketToQueue_(OfflineEquipment_, TransferID, ErrorText) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.OfflineEquipmentExchangeMessageQueue");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("OfflineEquipment_",OfflineEquipment_);
		LockItem.SetValue("TransferID",TransferID);
		Block.Lock();
	
		RecordSet = InformationRegisters.OfflineEquipmentExchangeMessageQueue.CreateRecordSet();
		RecordSet.Filter.OfflineEquipment_.Set(OfflineEquipment_);
		RecordSet.Filter.TransferID.Set(TransferID);
		RecordSet.Read();
		
		NewRecord 						= RecordSet.Add();
		NewRecord.OfflineEquipment_ 		= OfflineEquipment_;
		NewRecord.TransferID 	= TransferID;
		NewRecord.Error 					= True;
		NewRecord.ErrorDescription 			= ErrorText;
		
		RecordSet.Write(True);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Thêm gói lỗi dữ liệu vào trình tự';
				|ru = 'Добавление пакета ошибки данных в очередь';
				|en = 'Add a data error package to the queue'; fa = 'Add a data error package to the queue';
				|it = 'Aggiunta pacchetto errore dati in coda';
				|pl = 'Dodawanie pakietu błędu danych do kolejki';
				|tr = 'Sıraya veri hata paketi eklenmesi'", CommonCEL.DefaultLanguageCode()), 
			BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

// Add a data packet to the queue
//
// Parameters:
//  OfflineEquipment_ - CatalogRef
//  TransferID - Undefined, Arbitrary - 
//  MessageText - String
//  SequenceNumber - Number
//  TotalAmountOfPackages - Number
//
Procedure AddDataPacketToQueue(OfflineEquipment_, TransferID, MessageText, SequenceNumber = 1, TotalAmountOfPackages = 1) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.OfflineEquipmentExchangeMessageQueue");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("OfflineEquipment_", OfflineEquipment_);
		LockItem.SetValue("TransferID", TransferID);
		LockItem.SetValue("SequenceNumber", SequenceNumber);
		Block.Lock();
	
		RecordSet = InformationRegisters.OfflineEquipmentExchangeMessageQueue.CreateRecordSet();
		RecordSet.Filter.OfflineEquipment_.Set(OfflineEquipment_);
		RecordSet.Filter.TransferID.Set(TransferID);
		RecordSet.Filter.SequenceNumber.Set(SequenceNumber);
		RecordSet.Read();
		
		// If a message with this number is already in the queue, we generate an exception.
		If RecordSet.Count() = 0 Then
			
			NewRecord 						= RecordSet.Add();
			NewRecord.OfflineEquipment_ 		= OfflineEquipment_;
			NewRecord.TransferID 	= TransferID;
			NewRecord.SequenceNumber 		= SequenceNumber;
			NewRecord.PackageData 			= New ValueStorage(MessageText, New Deflation(9));
			NewRecord.TotalAmountOfPackages 			= TotalAmountOfPackages;
			
			RecordSet.Write(True);
			
			WritingError = False;
		Else
			
			WritingError = True;
			
		EndIf;
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Thêm gói dữ liệu vào trình tự.';
				|ru = 'Добавление пакета данных в очередь.';
				|en = 'Add a data package to the queue.'; fa = 'Add a data package to the queue.';
				|it = 'Aggiunta pacchetto dati in coda.';
				|pl = 'Dodawanie pakietu danych do kolejki';
				|tr = 'Sıraya veri paketi eklenmesi.'", CommonCEL.DefaultLanguageCode()), 
			BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
	If WritingError Then
		Raise(
			StrTemplate(
				NStr("vi = 'Không thể thực hiện gửi dữ liệu. Hàng đợi thông báo trao đổi đã có thông báo với số %1.';
					|ru = 'Не удалось выполнить отправку данных. Очередь сообщений обмена уже содержит сообщение с номером %1.';
					|en = 'Cannot send data. The exchange message queue already contains a message with number %1.'; fa = 'Cannot send data. The exchange message queue already contains a message with number %1.';
					|it = 'Не удалось выполнить отправку данных. Очередь сообщений обмена уже содержит сообщение с номером %1.';
					|pl = 'Cannot send data. The exchange message queue already contains a message with number %1.';
					|tr = 'Veri gönderilemedi. Değişim mesajı sırası zaten %1 numaralı mesajı içermektedir.'"),
				String(SequenceNumber)));
	EndIf;
	
EndProcedure

// Clears the message queue
//
// Parameters:
//  OfflineEquipment_ - CatalogRef
//
Procedure ClearMessageQueue(OfflineEquipment_) Export
	
	BeginTransaction();
	Try
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.OfflineEquipmentExchangeMessageQueue");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("OfflineEquipment_", OfflineEquipment_);
		Block.Lock();
	
		RecordSet = InformationRegisters.OfflineEquipmentExchangeMessageQueue.CreateRecordSet();
		RecordSet.Filter.OfflineEquipment_.Set(OfflineEquipment_);
		RecordSet.Read();
		RecordSet.Clear();
		
		RecordSet.Write(True);

		CommitTransaction();
	Except
		
		RollbackTransaction();
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Xóa trình tự thông báo.';
				|ru = 'Очистка очереди сообщений.';
				|en = 'Clear the message queue.'; fa = 'Clear the message queue.';
				|it = 'Eliminazione coda di messaggi.';
				|pl = 'Wyczyszczenie kolejki wiadomości.';
				|tr = 'Mesaj sırasının temizlenmesi.'", CommonCEL.DefaultLanguageCode()), 
			BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

// Get an unsent ID.
// 
// Parameters:
//  OfflineEquipment_ - CatalogRef - Offline equipment
// 
// Returns:
//  Undefined, Arbitrary - Get an unsent ID
//
Function GetUnsentID(OfflineEquipment_) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	OfflineEquipmentExchangeMessageQueue.TransferID AS TransferID
		|FROM
		|	InformationRegister.OfflineEquipmentExchangeMessageQueue AS OfflineEquipmentExchangeMessageQueue
		|WHERE
		|	OfflineEquipmentExchangeMessageQueue.OfflineEquipment_ = &OfflineEquipment_
		|	AND NOT OfflineEquipmentExchangeMessageQueue.Shipped_5
		|	AND NOT OfflineEquipmentExchangeMessageQueue.Error";
	
	Query.SetParameter("OfflineEquipment_", OfflineEquipment_);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Return Selection.TransferID;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Get a message from the queue.
// 
// Parameters:
//  OfflineEquipment_ - CatalogRef - Offline equipment
//  TransferID - UUID - Transfer ID
//  Restart_ - Boolean - Restart_
// 
// Returns:
//  Structure:
//   * OfflineEquipment_ - Arbitrary -
//   * TransferID - Arbitrary -
//   * SequenceNumber - Arbitrary -
//   * PackageData - ValueStorage -
//   * TotalAmountOfPackages - Arbitrary -
//   * Error - Arbitrary -
//   * ErrorDescription - Arbitrary -
//
Function GetMessageFromQueue(OfflineEquipment_, TransferID, Restart_) Export
	
	If Restart_ Then
		ResetSendFlagInExchangeQueue(OfflineEquipment_, TransferID);
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	OfflineEquipmentExchangeMessageQueue.OfflineEquipment_ AS OfflineEquipment_,
	|	OfflineEquipmentExchangeMessageQueue.TransferID AS TransferID,
	|	OfflineEquipmentExchangeMessageQueue.SequenceNumber AS SequenceNumber,
	|	OfflineEquipmentExchangeMessageQueue.PackageData AS PackageData,
	|	OfflineEquipmentExchangeMessageQueue.TotalAmountOfPackages AS TotalAmountOfPackages,
	|	OfflineEquipmentExchangeMessageQueue.Error AS Error,
	|	OfflineEquipmentExchangeMessageQueue.ErrorDescription AS ErrorDescription
	|FROM
	|	InformationRegister.OfflineEquipmentExchangeMessageQueue AS OfflineEquipmentExchangeMessageQueue
	|WHERE
	|	OfflineEquipmentExchangeMessageQueue.OfflineEquipment_ = &OfflineEquipment_
	|	AND NOT OfflineEquipmentExchangeMessageQueue.Shipped_5
	|	AND OfflineEquipmentExchangeMessageQueue.TransferID = &TransferID
	|
	|ORDER BY
	|	OfflineEquipmentExchangeMessageQueue.SequenceNumber";
	
	Query.SetParameter("OfflineEquipment_",    OfflineEquipment_);
	Query.SetParameter("TransferID", TransferID);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		
		PackageStructure = New Structure;
		PackageStructure.Insert("OfflineEquipment_", 		Selection.OfflineEquipment_);
		PackageStructure.Insert("TransferID", 	Selection.TransferID);
		PackageStructure.Insert("SequenceNumber", 		Selection.SequenceNumber);
		PackageStructure.Insert("PackageData", 			Selection.PackageData);
		PackageStructure.Insert("TotalAmountOfPackages", 			Selection.TotalAmountOfPackages);
		PackageStructure.Insert("Error", 					Selection.Error);
		PackageStructure.Insert("ErrorDescription", 			Selection.ErrorDescription);
		
		Return PackageStructure;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Internal

// StandardSubsystems.AccessManagement
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Manager = "InformationRegister.OfflineEquipmentExchangeMessageQueue";
	EquipmentManagerServerCallOverridable.OnFillAccessRestriction(Manager, Restriction);
	
EndProcedure
// End StandardSubsystems.AccessManagement

#EndRegion

#Region Private

Procedure ResetSendFlagInExchangeQueue(OfflineEquipment_, TransferID)
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.OfflineEquipmentExchangeMessageQueue");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("OfflineEquipment_",OfflineEquipment_);
		LockItem.SetValue("TransferID",TransferID);
		Block.Lock();
	
		RecordSet = InformationRegisters.OfflineEquipmentExchangeMessageQueue.CreateRecordSet();
		RecordSet.Filter.OfflineEquipment_.Set(OfflineEquipment_);
		RecordSet.Filter.TransferID.Set(TransferID);
		RecordSet.Read();
		
		For Each Record In RecordSet Do
			Record.Shipped_5 = False;
		EndDo;
		
		RecordSet.Write(True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Bỏ hộp kiểm gửi vào trình tự trao đổi.';
				|ru = 'Сброс флага отправки в очереди обмена';
				|en = 'Reset the sending check box in the exchange queue'; fa = 'Reset the sending check box in the exchange queue';
				|it = 'Rimozione contrassegno di invio nella coda di scambio';
				|pl = 'Odznaczenie pola wyboru wysyłki w kolejce wymiany';
				|tr = 'Değişim sırasında gönderi işaretini sıfırlamak'", CommonCEL.DefaultLanguageCode()), 
			BriefErrorDescription(ErrorInfo()));
		
	EndTry;
		
EndProcedure

#EndRegion


#EndIf
