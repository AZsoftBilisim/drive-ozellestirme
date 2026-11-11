
#Region Public

// The function generates an exchange packet that will be sent to the node of the "Exchange node" 
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - node of the exchange plan "mobile", with which the exchange is carried out
//
// Returns:
//  ValueStorage - the generated package placed in the value store
Function GenerateExchangeBatch(ExchangeNode) Export
	
	XMLFileName = GenerateXML(ExchangeNode);
	Package = New BinaryData(XMLFileName);
	HZz = New ValueStorage(Package);
	Return HZz;
	
EndFunction

// The procedure enters into the information database the data that are sent from the node of the "Node Exchange" 
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - node of the exchange plan "mobile", with which the exchange is carried out
//  ExchangeData - ValueStorage - the exchange packet received from the node of the node exchange is placed in the value storehouse
//
Procedure ReceiveExchangeBatch(ExchangeNode, ExchangeData) Export
	
	FileName = GetTempFileName("xml");
	BinaryData = ExchangeData.Get(); // BinaryData
	BinaryData.Write(FileName);
	
	SetPrivilegedMode(True);
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileName,,,"UTF-8");
	MessageReader = ExchangePlans.CreateMessageReader();
	MessageReader.BeginRead(XMLReader);
	ExchangePlans.DeleteChangeRecords(MessageReader.Sender, MessageReader.ReceivedNo);
	
	ArrayOfIncomingOrders = New Array;
	ArrayOfPlacementSelections = New Array;
	ArrayOfSpendingOrders = New Array;
	ArrayOfRecalculations = New Array;
	
	CentralExchangeHub = ExchangePlans.Mobile.FindByCode("001");
	
	While CanReadXML(XMLReader) Do
		ObjectName = XMLReader.Name;
		Data = ExchangeMobileOverridable.ReadData(XMLReader);
		If Not Data = Undefined Then
			If ExchangeNode <> CentralExchangeHub And ExchangePlans.IsChangeRecorded(MessageReader.Sender, Data) Then
#If Not MobileStandaloneServer Then
				EventNameLog = NStr("vi = 'Đối tượng được nhận từ cấu hình độc lập chưa được ghi lại, vì đã bị thay đổi trong cơ sở dữ liệu trung tâm';
									|ru = 'Объект, принятый из автономной конфигурации, не был записан, так как был изменен в центральной базе';
									|en = 'The object borrowed from the standalone configuration was not saved, as it was changed in the central infobase'; fa = 'The object borrowed from the standalone configuration was not saved, as it was changed in the central infobase';
									|it = 'The object borrowed from the standalone configuration was not saved, as it was changed in the central infobase';
									|pl = 'The object borrowed from the standalone configuration was not saved, as it was changed in the central infobase';
									|tr = 'Tek başına konfigürasyondan alınan nesne merkezi veritabanında değiştirildiği için kaydedilmedi'", Common.DefaultLanguageCode());
				WriteLogEvent(EventNameLog, EventLogLevel.Error,,Data.Ref);
#EndIf
				Continue;
			EndIf;
			
			Data.DataExchange.Sender = MessageReader.Sender;
			Data.DataExchange.Load = True;
			
			Try
				LockDataForEdit(Data.Ref);
			Except
#If Not MobileStandaloneServer Then
				DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EventNameLog = NStr("vi = 'Không thể ghi lại dữ liệu nhận được từ cấu hình độc lập, vì tại thời điểm ghi lại, đối tượng đã bị khóa';
									|ru = 'Не удалось записать данные, принятые из автономной конфигурации, так как в момент записи объект был заблокирован';
									|en = 'Cannot write the data borrowed from the standalone configuration as the object was locked when writing'; fa = 'Cannot write the data borrowed from the standalone configuration as the object was locked when writing';
									|it = 'Cannot write the data borrowed from the standalone configuration as the object was locked when writing';
									|pl = 'Cannot write the data borrowed from the standalone configuration as the object was locked when writing';
									|tr = 'Tek başına konfigürasyondan alınan veriler kaydedilemedi, çünkü kaydetme sırasında nesne kilitliydi'", Common.DefaultLanguageCode());
				WriteLogEvent(EventNameLog, EventLogLevel.Error,,Data.Ref,DetailErrorDescription);
#EndIf
				Continue;
			EndTry;
			
			YouCanSpend = MobileWarehouseKeeperWorkspace.HasAttributeOrObjectProperty(Data, "Posted");
			
			Try
				Data.Write();
				
				If YouCanSpend Then
					If TypeOf(Data) = Type("DocumentObject.GoodsReceiptNote") Then
						ArrayOfIncomingOrders.Add(Data.Ref);
					ElsIf TypeOf(Data) = Type("DocumentObject.GoodsPickingPlacement") Then
						ArrayOfPlacementSelections.Add(Data.Ref);
					ElsIf TypeOf(Data) = Type("DocumentObject.GoodsIssueNote") Then
						ArrayOfSpendingOrders.Add(Data.Ref);
					ElsIf TypeOf(Data) = Type("DocumentObject.InventoryRecount") Then
						ArrayOfRecalculations.Add(Data.Ref);
					EndIf; 
				EndIf;
			Except
#If Not MobileStandaloneServer Then
				DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EventNameLog = NStr("vi = 'Không thể ghi lại dữ liệu nhận được từ cấu hình độc lập';
									|ru = 'Не удалось записать данные, принятые из автономной конфигурации';
									|en = 'Cannot write the data borrowed from the standalone configuration'; fa = 'Cannot write the data borrowed from the standalone configuration';
									|it = 'Cannot write the data borrowed from the standalone configuration';
									|pl = 'Cannot write the data borrowed from the standalone configuration';
									|tr = 'Tek başına konfigürasyondan alınan veriler kaydedilemedi'", Common.DefaultLanguageCode());
				WriteLogEvent(EventNameLog, EventLogLevel.Error,,Data.Ref,DetailErrorDescription);
#EndIf
			EndTry;
			UnlockDataForEdit(Data.Ref);
		EndIf;
		
	EndDo;
	
	ArraysOfDocuments = New Structure;
	ArraysOfDocuments.Insert("GoodsReceiptNotes", ArrayOfIncomingOrders);
	ArraysOfDocuments.Insert("PlacementSelections", ArrayOfPlacementSelections);
	ArraysOfDocuments.Insert("GoodsIssueNotes", ArrayOfSpendingOrders);
	ArraysOfDocuments.Insert("Recalculations", ArrayOfRecalculations);
	
	MessageReader.EndRead();
	XMLReader.Close();
	
	If ExchangeNode <> CentralExchangeHub Then
		ToCarryOutCarryingOutOfDocuments(ArraysOfDocuments);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// The procedure based on the analysis of the data type replaces them with data that removes
// information from the node in which they should not be
//
// Parameters:
//  Data - An object, a set of records,... that needs to be converted
//
Procedure DataDeletion(Data) 
	
	// We get the metadata description object corresponding to the data
	MetadataObject = ?(TypeOf(Data) = Type("ObjectDeletion"), Data.Ref.Metadata(), Data.Metadata());
	// We check the type, we are interested only in those types that are implemented on the mobile platform
	If Metadata.Catalogs.Contains(MetadataObject)
		Or Metadata.Documents.Contains(MetadataObject) Then
		
		// Transferring object deletion for object
		Data = New ObjectDeletion(Data.Ref);
		
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject)
		Or Metadata.AccumulationRegisters.Contains(MetadataObject)
		Or Metadata.Sequences.Contains(MetadataObject) Then
		
		// Clearing the data
		Data.Clear();
		
	EndIf;	
	
EndProcedure

Function GenerateXML(ExchangeNode)
	
	SetPrivilegedMode(True);
	XMLWriter = New XMLWriter;
	
	FileName = GetTempFileName("xml");
	XMLWriter.OpenFile(FileName, "UTF-8");
	
	XMLWriter.WriteXMLDeclaration();
	
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	WriteMessage1.BeginWrite(XMLWriter, ExchangeNode);
	
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("v8",  "http://v8.1c.ru/data");
	
	DataToDeleteType = Type("ObjectDeletion");
	
	CentralNode = True;
	If ExchangeNode <> ExchangePlans.Mobile.FindByCode("001") Then
		CentralNode = False;
		DocumentsExportStartDate = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(ExchangeNode, "DocumentsExportStartDate");
	EndIf;
	ChangesSelection = ExchangePlans.SelectChanges(ExchangeNode, WriteMessage1.MessageNo);
	While ChangesSelection.Next() Do
		
		Data = ChangesSelection.Get();
		
		// If data transfer is not necessary, then it may be necessary to record data deletion
		If Not ExchangeMobileOverridable.DataTransferRequired(Data, ExchangeNode) Then
			
			// We get the value with the possible deletion of data
			DataDeletion(Data); 
			
		EndIf;
		
		If Not CentralNode And MobileWarehouseKeeperWorkspace.HasAttributeOrObjectProperty(Data, "Posted") Then
			If Data.Date < DocumentsExportStartDate Then
				Continue;
			EndIf;
		EndIf;
		
		// We write the data in the message
		ExchangeMobileOverridable.WriteData(XMLWriter, Data);
		
	EndDo;
	
	WriteMessage1.EndWrite();
	
	XMLWriter.Close();
	
	Return FileName;
	
EndFunction

// The procedure performs the execution of documents received from the autonomous configuration in the main database
//
// Parameters:
//  ArraysOfDocuments - Structure - a structure containing arrays of documents by type
//
Procedure ToCarryOutCarryingOutOfDocuments(ArraysOfDocuments)
	
#If Not MobileStandaloneServer Then
	For Each DocumentsArray In ArraysOfDocuments Do
		For Each DocumentRef In DocumentsArray.Value Do
			
			Try
				LockDataForEdit(DocumentRef);
			Except
				DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EventNameLog = NStr("vi = 'Không thể kết chuyển chứng từ nhận được từ cấu hình độc lập, vì tại thời điểm kết chuyển, đối tượng đã bị khóa';
									|ru = 'Не удалось провести документ, принятый из автономной конфигурации, так как в момент проведения объект был заблокирован';
									|en = 'Cannot post the document borrowed from the standalone configuration as the object was locked when posting'; fa = 'Cannot post the document borrowed from the standalone configuration as the object was locked when posting';
									|it = 'Cannot post the document borrowed from the standalone configuration as the object was locked when posting';
									|pl = 'Cannot post the document borrowed from the standalone configuration as the object was locked when posting';
									|tr = 'Tek başına konfigürasyondan alınan belge gerçekleştirilemedi, çünkü kaydetme sırasında nesne kilitliydi'", Common.DefaultLanguageCode());
				WriteLogEvent(EventNameLog, EventLogLevel.Error,,DocumentRef,DetailErrorDescription);
				Continue;
			EndTry;
			
			Data = DocumentRef.GetObject();
			
			Try
				Data.Write(DocumentWriteMode.Posting);
			Except
				DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EventNameLog = NStr("vi = 'Không thể kết chuyển chứng từ nhận được từ cấu hình độc lập';
									|ru = 'Невозможно провести документ, принятый из автономной конфигурации';
									|en = 'Cannot post the document borrowed from the standalone configuration'; fa = 'Cannot post the document borrowed from the standalone configuration';
									|it = 'Cannot post the document borrowed from the standalone configuration';
									|pl = 'Cannot post the document borrowed from the standalone configuration';
									|tr = 'Tek başına konfigürasyondan alınan belge kaydedilemez'", Common.DefaultLanguageCode());
				WriteLogEvent(EventNameLog, EventLogLevel.Error,,DocumentRef,DetailErrorDescription);
			EndTry;
			
			UnlockDataForEdit(DocumentRef);
			
		EndDo;
	EndDo;
#EndIf
	
EndProcedure

#EndRegion