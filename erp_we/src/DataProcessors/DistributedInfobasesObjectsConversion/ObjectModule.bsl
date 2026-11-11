///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Export service procedures and functions.

// Imports data from the exchange message file.
//
// Parameters:
//   Cancel - Boolean - a cancel flag appears on errors during exchange message processing.
//   ImportOnlyParameters - Boolean
//   ErrorMessage - String
// 
Procedure RunDataImport(Cancel, Val ImportOnlyParameters, ErrorMessage = "") Export
	
	DataExchangeServer.ClearErrorsListOnDataImport(InfobaseNode);
	
	If Not IsDistributedInfobaseNode() Then
		// The exchange must follow the conversion rules.
		ErrorMessage = DataExchangeKindError();
		WriteExchangeFinish(Cancel, , DataExchangeKindError());
		Return;
	EndIf;
	
	ImportMetadata = ImportOnlyParameters
		And DataExchangeServer.IsSubordinateDIBNode()
		And (DataExchangeInternal.RetryDataExchangeMessageImportBeforeStart()
			Or Not DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
					"MessageReceivedFromCache")
			Or DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
					"DownloadingExtensions"));
					
	DataAnalysisResultToExport = DataExchangeServer.DataAnalysisResultToExport(ExchangeMessageFileName(), False, True);
	ExchangeMessageFileSize = DataAnalysisResultToExport.ExchangeMessageFileSize;
	ObjectsToImportCount = DataAnalysisResultToExport.ObjectsToImportCount;
	
	// Set session parameters.
	DataSynchronizationSessionParameters = New Map;
	SetPrivilegedMode(True);
	Try
		CurrentSessionParameter = SessionParameters.DataSynchronizationSessionParameters.Get();
	Except
		CurrentSessionParameter = Undefined;
	EndTry;
	
	If TypeOf(CurrentSessionParameter) = Type("Map") Then
		For Each Item In CurrentSessionParameter Do
			DataSynchronizationSessionParameters.Insert(Item.Key, Item.Value);
		EndDo;
	EndIf;
	
	DataSynchronizationSessionParameters.Insert(InfobaseNode, 
						New Structure("ExchangeMessageFileSize, ObjectsToImportCount",
						ExchangeMessageFileSize, ObjectsToImportCount));
	SessionParameters.DataSynchronizationSessionParameters = New ValueStorage(DataSynchronizationSessionParameters);
	SetPrivilegedMode(False);
	
	XMLReader = New XMLReader;
	Try
		XMLReader.OpenFile(ExchangeMessageFileName());
	Except
		// Error opening the exchange message file.
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteExchangeFinish(Cancel, ErrorMessage, ErrorOpeningExchangeMessageFile());
		Return;
	EndTry;
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		ReadExchangeMessageFile(Cancel, XMLReader, ImportOnlyParameters, ImportMetadata, ErrorMessage);
		DataExchangeInternal.DisableAccessKeysUpdate(False);
	Except
		DataExchangeInternal.DisableAccessKeysUpdate(False);
		Raise;
	EndTry;
	
	XMLReader.Close();
EndProcedure

// Exports data to the exchange message file.
//
// Parameters:
//  Cancel - Boolean - a cancel flag appears on errors during exchange message processing.
//  ErrorMessage - String - textual description of the data export error.
// 
Procedure RunDataExport(Cancel, ErrorMessage = "") Export
	
	DataExchangeServer.ClearErrorsListOnExportData(InfobaseNode);
	
	If Not IsDistributedInfobaseNode() Then
		// The exchange must follow the conversion rules.
		ErrorMessage = DataExchangeKindError();
		WriteExchangeFinish(Cancel, , ErrorMessage);
		Return;
	EndIf;
	
	XMLWriter = New XMLWriter;
	
	Try
		XMLWriter.OpenFile(ExchangeMessageFileName());
	Except
		// Error opening the exchange message file.
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteExchangeFinish(Cancel, ErrorMessage, ErrorOpeningExchangeMessageFile());
		Return;
	EndTry;
	
	WriteChangesToExchangeMessageFile(Cancel, XMLWriter, ErrorMessage);
	
	XMLWriter.Close();
	
EndProcedure

// Passes the string with the full exchange message file name for data import or export to the ExchangeMessageFileNameField
// local variable.
// Usually, the exchange message file places 
// in the operating system user temporary directory.
//
// Parameters:
//  FileName - String - a full name of the exchange message file for data export or import.
// 
Procedure SetExchangeMessageFileName(Val FileName) Export
	
	ExchangeMessageFileNameField = FileName;
	
EndProcedure

//

Procedure ReadExchangeMessageFile(Cancel, XMLReader, Val ImportOnlyParameters, Val ImportMetadata, ErrorMessage = "")
	
	MessageReader = ExchangePlans.CreateMessageReader();
	
	Try
		MessageReader.BeginRead(XMLReader, AllowedMessageNo.Greater);
	Except
		// Unknown exchange plan specified.
		// Node outside of the exchange plan specified.
		// Unexpected message number.
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteExchangeFinish(Cancel, ErrorMessage, ErrorStartRedingTheExchangeMessageFile());
		Return;
	EndTry;
	
	CommonDataNode = Undefined;
	ReceivedNo = MessageReader.ReceivedNo;
	ExchangeNode = MessageReader.Sender;
	
	If ImportOnlyParameters Then
		
		If ImportMetadata Then
				
			Try
				
				SetPrivilegedMode(True);
				DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
					"ImportApplicationParameters", True);
				SetPrivilegedMode(False);
				
				// Receiving configuration changes and ignoring data changes
				ExchangePlans.ReadChanges(MessageReader, TransactionItemsCount);
				
				// Reading priority data (predefined items, metadata object IDs).
				ReadPriorityChangesFromExchangeMessage(MessageReader, CommonDataNode);
				
				// Pretending the message is still not received. Interrupting the data reading.
				MessageReader.CancelRead();
				
				SetPrivilegedMode(True);
				DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
					"ImportApplicationParameters", False);
				SetPrivilegedMode(False);
			Except
				SetPrivilegedMode(True);
				DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
					"ImportApplicationParameters", False);
				SetPrivilegedMode(False);
				
				MessageReader.CancelRead();
				ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteExchangeFinish(Cancel, ErrorMessage, ErrorReadingExchangeMessageFile());
				Return;
			EndTry;
			
		Else
			
			Try
				
				// Skipping configuration changes and data changes in the exchange message.
				MessageReader.XMLReader.Skip(); // <Changes>...</Changes>
				
				MessageReader.XMLReader.Read(); // </Changes>
				
				// Reading priority data (predefined items, metadata object IDs).
				ReadPriorityChangesFromExchangeMessage(MessageReader, CommonDataNode);
				
				// Pretending the message is still not received. Interrupting the data reading.
				MessageReader.CancelRead();
			Except
				MessageReader.CancelRead();
				ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteExchangeFinish(Cancel, ErrorMessage, ErrorReadingExchangeMessageFile());
				Return
			EndTry;
			
		EndIf;
		
	Else
		
		If ThereIsAnExtensionInTheExchangeMessage(MessageReader) Then
			DataExchangeInternal.EnableLoadingExtensionsThatChangeTheDataStructure();
		EndIf;
		
		Try
				
			// Receiving configuration changes and data changes from the exchange message.
			ExchangePlans.ReadChanges(MessageReader, TransactionItemsCount);
			
			// Reading priority data (predefined items, metadata object IDs).
			ReadPriorityChangesFromExchangeMessage(MessageReader, CommonDataNode);
			
			// Consider the message received.
			MessageReader.EndRead();
			
	        // If an exchange message was processed successfully, don't upload extensions.
			DataExchangeInternal.DisableLoadingExtensionsThatChangeTheDataStructure();
						
		Except
			
			// If the extensions were modified dynamically, reboot the session (not during the update process).
			If Catalogs.ExtensionsVersions.ExtensionsChangedDynamically() Then
				DataExchangeInternal.DisableLoadingExtensionsThatChangeTheDataStructure();
			EndIf;	
						
			MessageReader.CancelRead();
			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			WriteExchangeFinish(Cancel, ErrorMessage, ErrorReadingExchangeMessageFile());
			Return
		EndTry;
		
	EndIf;
			
	// Common data of nodes is written after the message is read.
	If CommonDataNode <> Undefined Then
		
		MasterNodeRef  = ExchangePlans.MasterNode();
		
		BeginTransaction();
		Try
		    Block = New DataLock;
			
		    LockItem = Block.Add(Common.TableNameByRef(MasterNodeRef));
		    LockItem.SetValue("Ref", MasterNodeRef);
			
			Block.Lock();
			
			CommonNodeData = DataExchangeCached.CommonNodeData(MasterNodeRef);
			CurrentNode = MasterNodeRef.GetObject();
			If DataExchangeEvents.DataDiffers1(CurrentNode, CommonDataNode, CommonNodeData) Then
				DataExchangeEvents.FillObjectPropertiesValues(CurrentNode, CommonDataNode, CommonNodeData);
				CurrentNode.Write();
			EndIf;

		    CommitTransaction();
		Except
		    RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
	InformationRegisters.CommonNodeDataChanges.DeleteChangeRecords(ExchangeNode, ReceivedNo);
	
EndProcedure

Procedure WriteChangesToExchangeMessageFile(Cancel, XMLWriter, ErrorMessage = "")
	
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	
	Try
		WriteMessage1.BeginWrite(XMLWriter, InfobaseNode);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteExchangeFinish(Cancel, ErrorMessage, ErrorStartWritingTheExchangeMessageFile());
		Return;
	EndTry;
	
	// Set session parameters.
	ObjectsToExportCount = DataExchangeServer.CalculateRegisteredObjectsCount(InfobaseNode);
	DataSynchronizationSessionParameters = New Map;
	SetPrivilegedMode(True);
	Try
		CurrentSessionParameter = SessionParameters.DataSynchronizationSessionParameters.Get();
	Except
		CurrentSessionParameter = Undefined;
	EndTry;
	
	If TypeOf(CurrentSessionParameter) = Type("Map") Then
		For Each Item In CurrentSessionParameter Do
			DataSynchronizationSessionParameters.Insert(Item.Key, Item.Value);
		EndDo;
	EndIf;
	
	DataSynchronizationSessionParameters.Insert(InfobaseNode, 
						New Structure("ObjectsToExportCount",
						ObjectsToExportCount));
	SessionParameters.DataSynchronizationSessionParameters = New ValueStorage(DataSynchronizationSessionParameters);
	SetPrivilegedMode(False);
	
	Try
		DataExchangeInternal.ClearPriorityExchangeData();
		
		// Writing configuration changes and data changes to the exchange message.
		ExchangePlans.WriteChanges(WriteMessage1, TransactionItemsCount);
		
		// Append top-priority data to the exchange message
		// (predefined items and metadata object IDs).
		WritePriorityChangesToExchangeMessage(WriteMessage1);
		
		WriteMessage1.EndWrite();
	Except
		WriteMessage1.CancelWrite();
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteExchangeFinish(Cancel, ErrorMessage, ErrorSavingExchangeMessageFile());
		Return;
	EndTry;
	
EndProcedure

// Writes priority data (such as metadata object IDs) to the exchange message.
// For example, predefined items and metadata object IDs.
//
Procedure WritePriorityChangesToExchangeMessage(Val WriteMessage1)
	
	// Write the <Parameters> element.
	WriteMessage1.XMLWriter.WriteStartElement("Parameters");
	
	If WriteMessage1.Recipient <> ExchangePlans.MasterNode() Then
		
		// Exporting priority exchange data (predefined items.
		PriorityExchangeData = DataExchangeInternal.PriorityExchangeData();
		
		If PriorityExchangeData.Count() > 0 Then
			
			ChangesSelection = DataExchangeServer.SelectChanges(
				WriteMessage1.Recipient,
				WriteMessage1.MessageNo,
				PriorityExchangeData);
			
			BeginTransaction();
			Try
				
				While ChangesSelection.Next() Do
					
					WriteXML(WriteMessage1.XMLWriter, ChangesSelection.Get());
					
				EndDo;
				
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			
		EndIf;
		
		If Not StandardSubsystemsCached.DisableMetadataObjectsIDs() Then
			
			// Exporting the metadata object IDs catalog.
			ChangesSelection = DataExchangeServer.SelectChanges(
				WriteMessage1.Recipient,
				WriteMessage1.MessageNo,
				Metadata.Catalogs["MetadataObjectIDs"]);
			
			BeginTransaction();
			Try
				
				While ChangesSelection.Next() Do
					
					WriteXML(WriteMessage1.XMLWriter, ChangesSelection.Get());
					
				EndDo;
				
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			
		EndIf;
		
		// Exporting common data of nodes.
		NodesChangesSelection = InformationRegisters.CommonNodeDataChanges.SelectChanges(WriteMessage1.Recipient, WriteMessage1.MessageNo);
		
		If NodesChangesSelection.Count() <> 0 Then
			
			CommonNodeData = DataExchangeCached.CommonNodeData(WriteMessage1.Recipient);
			
			If Not IsBlankString(CommonNodeData) Then
				
				ExchangePlanName = DataExchangeCached.GetExchangePlanName(WriteMessage1.Recipient);
				CommonNode = ExchangePlans[ExchangePlanName].CreateNode();
				DataExchangeEvents.FillObjectPropertiesValues(CommonNode, WriteMessage1.Recipient.GetObject(), CommonNodeData);
				WriteXML(WriteMessage1.XMLWriter, CommonNode);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	WriteMessage1.XMLWriter.WriteEndElement(); // Parameters
	
EndProcedure

// Reading first-priority data from the exchange message
// (predefined items, metadata object IDs).
//
Procedure ReadPriorityChangesFromExchangeMessage(Val MessageReader, CommonDataNode)
	
	If MessageReader.Sender = ExchangePlans.MasterNode() Then
		
		MessageReader.XMLReader.Read(); // <Parameters>
		
		BeginTransaction();
		Try
			
			DuplicatesOfPredefinedItems = "";
			Cancel = False;
			CancelDetails = "";
			IDObjects = New Array;
			ExchangePlanName = DataExchangeCached.GetExchangePlanName(MessageReader.Sender);
			TypeExchangePlanObject = Type("ExchangePlanObject." + ExchangePlanName);
			
			If NotUniqueRecordsFound("Catalog.MetadataObjectIDs") Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NotUniqueRecordErrorTemplate(),
					NStr("vi = 'Trước khi kết nhập tên định danh đối tượng metadata
					           |trong danh mục đã tìm thấy các bản ghi không đơn trị.';
					           |ru = 'Перед загрузкой идентификаторов объектов метаданных
					           |в справочнике найдены не уникальные записи.';
					           |en = 'Duplicate catalog items were found
					           |before importing IDs of metadata objects.'; fa = 'Duplicate catalog items were found
					           |before importing IDs of metadata objects.';
					           |it = 'Prima di download degli identificatori degli oggetti di metadati
					           |nella directory sono state trovate le voci non univoche.';
					           |pl = 'Przed załadowaniem identyfikatorów obiektów metadanych
					           |znaleziono nieunikalne wpisy w katalogu.';
					           |tr = 'Meta veri nesne tanımlayıcılarını yüklemeden önce, dizinde 
					           |benzersiz olmayan kayıtlar bulundu.'"));
			EndIf;
			
			While CanReadXML(MessageReader.XMLReader) Do
				
				Data = ReadXML(MessageReader.XMLReader);
				
				Data.DataExchange.Load = True;
				
				If TypeOf(Data) = TypeExchangePlanObject Then // Node common data.
					
					CommonDataNode = Data;
					Continue;
					
				EndIf;
				
				Data.DataExchange.Sender = MessageReader.Sender;
				Data.DataExchange.Recipients.AutoFill = False;
				
				If TypeOf(Data) = Type("CatalogObject.MetadataObjectIDs") Then
					IDObjects.Add(Data);
					Continue;
					
				ElsIf TypeOf(Data) <> Type("ObjectDeletion") Then // This is a predefined item.
					
					If Not Data.Predefined Then
						Continue; // Process only predefined items.
					EndIf;
					
				Else // Type("ObjectDeletion")
					
					// 1. ID references are deleted independently in each node using Marked object deletion.
					//    2. Deleted predefined objects are not exported.
					// 
					Continue;
				EndIf;
				
				WritePredefinedDataRef(Data);
				AddPredefinedItemDuplicateDetails(Data, DuplicatesOfPredefinedItems, Cancel, CancelDetails);
			EndDo;
			
			If Cancel Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa thực hiện kết nhập dữ liệu ưu tiên.
					           |Khi kết nhập phần tử định trước đã tìm thấy các bản ghi không đơn trị.
					           |Không thể tiếp tục do các nguyên nhân sau.
					           |%1';
					           |ru = 'Загрузка приоритетных данных не выполнена.
					           |При загрузке предопределенных элементов найдены не уникальные записи.
					           |По следующим причинам продолжение невозможно.
					           |%1';
					           |en = 'Cannot import priority data.
					           |Duplicate predefined items are found.
					           |Cannot continue the import due to the following reasons:
					           |%1'; fa = 'Cannot import priority data.
					           |Duplicate predefined items are found.
					           |Cannot continue the import due to the following reasons:
					           |%1';
					           |it = 'Il download di dati prioritari non è stato effettuato.
					           |Durante il download di elementi predefiniti sono state trovate le voci non univoche.
					           |Per i seguenti motivi la continuazione è impossibile.
					           |%1';
					           |pl = 'Ładowanie danych o priorytecie nie powiodło się.
					           |Podczas ładowania wstępnie zdefiniowanych pozycji znaleziono nieunikalne zapisy.
					           |Z następujących powodów kontynuacja nie jest możliwa.
					           |%1';
					           |tr = 'Öncelikli veriler yüklenemedi. 
					           |Önceden tanımlanmış öğeleri yüklerken benzersiz olmayan kayıtlar bulundu.
					           |Aşağıdaki nedenlerden dolayı devam edilemez.
					           |%1'"),
					CancelDetails);
			EndIf;
			
			If ValueIsFilled(DuplicatesOfPredefinedItems) Then
				WriteLogEvent(
					NStr("vi = 'Phần tử định trước.Đã tìm thấy các bản ghi không đơn trị.';
						|ru = 'Предопределенные элементы.Найдены не уникальные записи.';
						|en = 'Predefined items.Duplicates'; fa = 'Predefined items.Duplicates';
						|it = 'Elementi predefiniti.Sono state trovate le voci non univoche.';
						|pl = 'Elementy predefiniowane. Nie znaleziono unikalnych rekordów.';
						|tr = 'Önceden tanımlanmış öğeler. Benzersiz olmayan kayıtlar bulundu.'",
						Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Khi kết nhập phần tử định trước đã tìm thấy các bản ghi không đơn trị.
						           |%1';
						           |ru = 'При загрузке предопределенных элементов найдены не уникальные записи.
						           |%1';
						           |en = 'When importing predefined items, duplicate records were found.
						           |%1'; fa = 'When importing predefined items, duplicate records were found.
						           |%1';
						           |it = 'Durante il download di elementi predefiniti sono state trovate le voci non univoche.
						           |%1';
						           |pl = 'Podczas ładowania wstępnie zdefiniowanych elementów nie znaleziono unikalnych rekordów.
						           |%1';
						           |tr = 'Öntanımlı öğeler içe aktarılırken benzersiz olmayan kayıtlar bulundu. 
						           |%1'"),
						DuplicatesOfPredefinedItems));
			EndIf;
			
			UpdatePredefinedItemsDeletion();
			
			If Not StandardSubsystemsCached.DisableMetadataObjectsIDs() Then
				Catalogs.MetadataObjectIDs.ImportDataToSubordinateNode(IDObjects);
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ErrorMessage = NStr("vi = 'Lỗi khi kết nhập dữ liệu ưu tiên: ""%1"" (kiểu %2)';
								|ru = 'Ошибка при загрузке приоритетных данных: ""%1"" (тип %2)';
								|en = 'An error occurred when importing priority data: ""%1"" (type %2)'; fa = 'An error occurred when importing priority data: ""%1"" (type %2)';
								|it = 'Errore durante il caricamento di dati prioritari: ""%1"" (tipo %2)';
								|pl = 'Błąd podczas pobierania danych priorytetowych: ""%1"" (typ %2)';
								|tr = 'Öncelikli veriler yüklenirken bir hata oluştu: ""%1"" (%2 türü)'", Common.DefaultLanguageCode());
			ErrorMessage = StrTemplate(ErrorMessage, Data, TypeOf(Data));
			ErrorMessage = ErrorMessage + Chars.LF + ErrorInfo().Description; 
	
			WriteExchangeFinish(Cancel, ErrorMessage, ErrorReadingExchangeMessageFile());
			
			Raise;
		EndTry;
		
		MessageReader.XMLReader.Read(); // </Parameters>
		
	Else
		
		// Skipping the application execution parameters.
		MessageReader.XMLReader.Skip(); // <Parameters>...</Parameters>
		
		MessageReader.XMLReader.Read(); // </Parameters>
		
	EndIf;
	
EndProcedure

Procedure WriteExchangeFinish(Cancel, ErrorDescription = "", ContextErrorDescription = "")
	
	Cancel = True;
	
	Comment = "[ContextErrorDescription]: [ErrorDescription]"; // Do not localize.
	
	Comment = StrReplace(Comment, "[ContextErrorDescription]", ContextErrorDescription);
	Comment = StrReplace(Comment, "[ErrorDescription]", ErrorDescription);
	
	WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
		InfobaseNode.Metadata(), InfobaseNode, Comment);
	
EndProcedure

Function IsDistributedInfobaseNode()
	
	Return DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode);
	
EndFunction

Procedure WritePredefinedDataRef(Data)
	
	ObjectMetadata = Metadata.FindByType(TypeOf(Data.Ref));
	If ObjectMetadata = Undefined Then
		Return;
	EndIf;
	
	ObjectManager = Common.ObjectManagerByRef(Data.Ref);
	
	If Data.IsNew() Then
		If Common.IsCatalog(ObjectMetadata) Then
			If ObjectMetadata.Hierarchical
				And ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems
				And Data.IsFolder Then
				Object = ObjectManager.CreateFolder();
			Else
				Object = ObjectManager.CreateItem();
			EndIf;
		ElsIf Common.IsChartOfCharacteristicTypes(ObjectMetadata) Then
			If ObjectMetadata.Hierarchical
				And Data.IsFolder Then
				Object = ObjectManager.CreateFolder();
			Else
				Object = ObjectManager.CreateItem();
			EndIf;
		ElsIf Common.IsChartOfAccounts(ObjectMetadata) Then
			Object = ObjectManager.CreateAccount();
		ElsIf Common.IsChartOfCalculationTypes(ObjectMetadata) Then
			Object = ObjectManager.CreateCalculationType();
		EndIf;
	Else
		Object = Data.Ref.GetObject();
	EndIf;
	
	If Data.IsNew() Then
		Object.SetNewObjectRef(Data.GetNewObjectRef());
		Object.PredefinedDataName = Data.PredefinedDataName;
		Object.AdditionalProperties.Insert("SkipObjectVersionRecord");
		Object.AdditionalProperties.Insert("PriorityDataImport");
		
		InfobaseUpdate.WriteData(Object, False); 
		
	ElsIf Object.PredefinedDataName <> Data.PredefinedDataName Then

		BeginTransaction();
		
		Try
			Block = New DataLock;
			LockItem = Block.Add(Common.TableNameByRef(Object.Ref));
			LockItem.SetValue("Ref", Object.Ref);
			Block.Lock();
			
			Object.PredefinedDataName = Data.PredefinedDataName;
			Object.AdditionalProperties.Insert("SkipObjectVersionRecord");
			Object.AdditionalProperties.Insert("PriorityDataImport");
		
			LockDataForEdit(Object.Ref);
			
			InfobaseUpdate.WriteData(Object, False);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			Event = NStr("vi = 'Предопределенные элементы.Запись';
						|ru = 'Предопределенные элементы.Запись';
						|en = 'Predefined items.Record'; fa = 'Predefined items.Record';
						|it = 'Предопределенные элементы.Запись';
						|pl = 'Predefined items.Record';
						|tr = 'Предопределенные элементы.Запись'", Common.DefaultLanguageCode());
			
			WriteLogEvent(Event, EventLogLevel.Error, , , ErrorMessage);
		EndTry;
		
	Else
		// If the predefined item exists, preliminary import is not required
	EndIf;
	
	Data = Object;
	
EndProcedure

Procedure AddPredefinedItemDuplicateDetails(WrittenObject, DuplicatesOfPredefinedItems, Cancel, CancelDetails)
	
	ObjectMetadata = Metadata.FindByType(TypeOf(WrittenObject.Ref));
	If ObjectMetadata = Undefined Then
		Return;
	EndIf;
	
	Table = ObjectMetadata.FullName();
	PredefinedDataName = WrittenObject.PredefinedDataName;
	Ref = WrittenObject.Ref;
	
	Query = New Query;
	Query.SetParameter("PredefinedDataName", PredefinedDataName);
	Query.Text =
	"SELECT
	|	CurrentTable.Ref AS Ref,
	|	CurrentTable.PredefinedDataName AS PredefinedDataName
	|FROM
	|	&CurrentTable AS CurrentTable
	|WHERE
	|	CurrentTable.PredefinedDataName = &PredefinedDataName";
	
	Query.Text = StrReplace(Query.Text, "&CurrentTable", Table);
	Selection = Query.Execute().Select();
	
	DuplicateRefIDs = "";
	DuplicateCount = 0;
	FoundRefs = New Map;
	RefToImportFound = False;
	
	While Selection.Next() Do
		// Searching for duplicate records that are relevant to predefined items
		If FoundRefs.Get(Selection.Ref) = Undefined Then
			FoundRefs.Insert(Selection.Ref, 1);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NotUniqueRecordErrorTemplate(),
				NStr("vi = 'Khi kết nhập phần tử định trước đã tìm thấy các bản ghi không đơn trị.';
					|ru = 'При загрузке предопределенных элементов найдены не уникальные записи.';
					|en = 'When importing predefined items, duplicate records were found.'; fa = 'When importing predefined items, duplicate records were found.';
					|it = 'Durante il download di elementi predefiniti sono state trovate le voci non univoche.';
					|pl = 'Podczas ładowania wstępnie zdefiniowanych elementów nie znaleziono unikalnych rekordów.';
					|tr = 'Önceden tanımlanmış öğeler yüklenirken benzersiz olmayan kayıtlar bulundu.'"));
		EndIf;
		// Searching for duplicate predefined items
		If Ref = Selection.Ref And Not RefToImportFound Then
			RefToImportFound = True;
			Continue;
		EndIf;
		DuplicateCount = DuplicateCount + 1;
		If ValueIsFilled(DuplicateRefIDs) Then
			DuplicateRefIDs = DuplicateRefIDs + ",";
		EndIf;
		DuplicateRefIDs = DuplicateRefIDs
			+ String(Selection.Ref.UUID());
	EndDo;
	
	If DuplicateCount = 0 Then
		Return;
	EndIf;
	
	WriteToLog = True;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		
		LongDesc = "";
		ModuleAccessManagementInternal.OnFindNotUniquePredefinedItem(
			WrittenObject, WriteToLog, Cancel, LongDesc);
		
		If ValueIsFilled(LongDesc) Then
			CancelDetails = CancelDetails + Chars.LF + TrimAll(LongDesc) + Chars.LF;
		EndIf;
	EndIf;
	
	If WriteToLog Then
		If DuplicateCount = 1 Then
			Template = NStr("vi = '(tham chiếu được kết nhập: %1, tham chiếu trùng lặp: %2)';
							|ru = '(загружаемая ссылка: %1, ссылка дубля: %2)';
							|en = '(reference to import: %1, duplicate reference: %2)'; fa = '(reference to import: %1, duplicate reference: %2)';
							|it = '(link in download: %1, link al duplicato: %2)';
							|pl = '(odnośnik do pobrania: %1, odnośnik duplikatu: %2)';
							|tr = '(yüklenen referans: %1, kopya referansı: %2)'");
		Else
			Template = NStr("vi = '(tham chiếu được kết nhập: %1, tham chiếu trùng lặp: %2)';
							|ru = '(загружаемая ссылка: %1, ссылки дублей: %2)';
							|en = '(reference to import: %1, duplicate references: %2)'; fa = '(reference to import: %1, duplicate references: %2)';
							|it = '(link in download: %1, i link ai duplicati: %2)';
							|pl = '(odnośnik do pobrania: %1, odnośniki duplikatów: %2)';
							|tr = '(yüklenen referans: %1, kopyaların referansı: %2)'");
		EndIf;
		DuplicatesOfPredefinedItems = DuplicatesOfPredefinedItems + Chars.LF
			+ Table + "." + PredefinedDataName + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				String(Ref.UUID()),
				DuplicateRefIDs)
			+ Chars.LF;
	EndIf;
	
EndProcedure

Function NotUniqueRecordsFound(Table)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|
	|GROUP BY
	|	MetadataObjectIDs.Ref
	|
	|HAVING
	|	COUNT(MetadataObjectIDs.Ref) > 1";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function NotUniqueRecordErrorTemplate()
	Return
		NStr("vi = 'Chưa thực hiện kết nhập dữ liệu ưu tiên.
		           |%1
		           |Cần sửa lỗi cơ sở thông tin.
		           |1. Hãy mở bộ thiết kế, chuyển đến menu Quản trị,
		           |   chọn mục ""Thử nghiệm và sửa chữa ..."".
		           |2. Trong biểu mẫu mở ra
		           |   - chỉ chọn mục ""Kiểm tra tính toàn vẹn của cơ sở thông tin"";
		           |   - chọn phương án ""Thử nghiệm và sửa chữa"", không chọn ""Chỉ thử nghiệm"";
		           |   - nhấn nút Thực hiện.
		           |3. Sau đó, khởi động 1C:Enterprise và đồng bộ lại dữ liệu.';
		           |ru = 'Загрузка приоритетных данных не выполнена.
		           |%1
		           |Требуется исправление информационной базы.
		           |1. Откройте конфигуратор, перейдите в меню Администрирование,
		           |   выберите пункт ""Тестирование и исправление ..."".
		           |2. В открывшейся форме
		           |   - включите только пункт ""Проверка логической целостности информационной базы"";
		           |   - выберите вариант ""Тестирование и исправление"", а не ""Только тестирование"";
		           |   - нажмите Выполнить.
		           |3. После этого запустите 1С:Предприятие и выполните повторную синхронизацию данных.';
		           |en = 'Cannot import priority data.
		           |%1
		           |An infobase repair is required.
		           |1. Open Designer. On the ""Administration"" menu,
		           | click ""Verify and repair"".
		           |2. In the ""Verify and repair infobase"" window:
		           |   - Select only the ""Check logical infobase integrity"" check box.
		           |   - Click ""Verify and repair"".
		           |   - Click ""Execute"".
		           |3. Then run 1C:Enterprise and synchronize the data again.'; fa = 'Cannot import priority data.
		           |%1
		           |An infobase repair is required.
		           |1. Open Designer. On the ""Administration"" menu,
		           | click ""Verify and repair"".
		           |2. In the ""Verify and repair infobase"" window:
		           |   - Select only the ""Check logical infobase integrity"" check box.
		           |   - Click ""Verify and repair"".
		           |   - Click ""Execute"".
		           |3. Then run 1C:Enterprise and synchronize the data again.';
		           |it = 'Il download di dati prioritari non è completato. 
		           |%1
		           |È necessario effettuare la rettifica del database informatico.
		           |1.Aprire il configuratore, andare al menu Amministrazione,
		           |   selezionare la voce ""Test e correzione ..."".
		           |2. Nel modulo aperto
		           |   - includere solo la voce ""Verifica dell''integrità logica del database informatico"";
		           | - selezionare l''opzione ""Test e correzione"", e non ""Solo test""; 
		           |   - fare clic su Eseguire.
		           |3. Successivamente eseguire avviamento di 1C:Enterprise ed effettuare una seconda sincronizzazione dei dati.';
		           |pl = 'Ładowanie danych priorytetowych nie jest zakończone.
		           |%1
		           |Wymagana jest korekta bazy danych.
		           |1. Otwórz konfigurator, przejdź do menu Administracja,
		           | wybierz element ""Testowanie i naprawa..."".
		           |2. W formularzu, który się otwiorzy
		           | - uwzględnij tylko pozycję ""Sprawdzanie logicznej integralności bazy danych"";
		           | - wybierz opcję ""Testowanie i utrwalanie"", a nie ""Tylko testowanie"";
		           | - kliknij Wykonaj.
		           |3. Następnie uruchom 1C:Enterprise i ponownie zsynchronizuj dane. ';
		           |tr = 'Öncelikli veriler yüklenemedi. 
		           |%1
		           |Bir bilgi tabanı düzeltmesi gereklidir.
		           |1. Designer''ı açın, Yönetim menüsüne gidin, 
		           |""Test Et ve düzelt"" maddesini seçin ...""
		           |2. Açılan formda
		           |-sadece ""Infobase''in mantıksal bütünlüğünü kontrol et"" seçeneğini etkinleştirin; 
		           |- ""Yalnızca test"" yerine ""Test ve düzeltme"" seçeneğini seçin; 
		           |- Çalıştır''ı tıklayın.
		           |3. Bundan sonra 1C:Enterprise''ı çalıştırın ve verileri yeniden senkronize edin.'");
EndFunction

Procedure UpdatePredefinedItemsDeletion()
	
	SetPrivilegedMode(True);
	
	MetadataCollections = New Array;
	MetadataCollections.Add(Metadata.Catalogs);
	MetadataCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataCollections.Add(Metadata.ChartsOfAccounts);
	MetadataCollections.Add(Metadata.ChartsOfCalculationTypes);
	
	For Each Collection In MetadataCollections Do
		For Each MetadataObject In Collection Do
			If MetadataObject = Metadata.Catalogs.MetadataObjectIDs Then
				Continue; // Metadata objects of this type are updated in the procedure that updates metadata object IDs
			EndIf;
			UpdatePredefinedItemDeletion(MetadataObject.FullName());
		EndDo;
	EndDo;
	
EndProcedure

Procedure UpdatePredefinedItemDeletion(Table)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CurrentTable.Ref AS Ref,
	|	CurrentTable.PredefinedDataName AS PredefinedDataName
	|FROM
	|	&CurrentTable AS CurrentTable
	|WHERE
	|	CurrentTable.Predefined = TRUE";
	
	Query.Text = StrReplace(Query.Text, "&CurrentTable", Table);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If StrStartsWith(Selection.PredefinedDataName, "#") Then
			
			Object = Selection.Ref.GetObject();
			Object.PredefinedDataName = "";
			Object.DeletionMark = True;
			
			Object.AdditionalProperties.Insert("SkipObjectVersionRecord");
			InfobaseUpdate.WriteData(Object);
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Local utility functions are properties.

Function ExchangeMessageFileName()
	
	If Not ValueIsFilled(ExchangeMessageFileNameField) Then
		
		ExchangeMessageFileNameField = "";
		
	EndIf;
	
	Return ExchangeMessageFileNameField;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Descriptions of execution context errors.

Function ErrorOpeningExchangeMessageFile()
	
	Return NStr("vi = 'Lỗi mở tệp thông điệp trao đổi';
				|ru = 'Ошибка открытия файла сообщения обмена';
				|en = 'Cannot open the exchange message file.'; fa = 'Cannot open the exchange message file.';
				|it = 'Errore di apertura file del messaggio di scambio';
				|pl = 'Błąd podczas otwierania wymiany plików';
				|tr = 'Değişim mesaj dosyası açılırken bir hata oluştu'", Common.DefaultLanguageCode());
	
EndFunction

Function ErrorStartRedingTheExchangeMessageFile()
	
	Return NStr("vi = 'Lỗi khi bắt đầu đọc tệp thông điệp trao đổi';
				|ru = 'Ошибка при начале чтения файла сообщения обмена';
				|en = 'Cannot start reading the exchange message file.'; fa = 'Cannot start reading the exchange message file.';
				|it = 'Errore durante l''avvio della lettura del file di messaggio di scambio';
				|pl = 'Błąd podczas odczytu pliku wymiany komunikatów';
				|tr = 'Veri alışverişi mesajı dosyasını okumaya başlarken bir hata oluştu'", Common.DefaultLanguageCode());
	
EndFunction

Function ErrorStartWritingTheExchangeMessageFile()
	
	Return NStr("vi = 'Lỗi khi bắt đầu ghi lại tệp thông điệp trao đổi';
				|ru = 'Ошибка при начале записи файла сообщения обмена';
				|en = 'Cannot start saving the exchange message file'; fa = 'Cannot start saving the exchange message file';
				|it = 'Errore durante l''avvio della scrittura del file di messaggio di scambio';
				|pl = 'Błąd podczas rozpoczynania zapisywania wymiany plików wiadomości';
				|tr = 'Veri alışverişi mesajı dosyasını kaydetmeye başlarken bir hata oluştu'", Common.DefaultLanguageCode());
	
EndFunction

Function ErrorReadingExchangeMessageFile()
	
	Return NStr("vi = 'Lỗi đọc tệp thông điệp trao đổi';
				|ru = 'Ошибка чтения файла сообщения обмена';
				|en = 'Cannot read the exchange message file.'; fa = 'Cannot read the exchange message file.';
				|it = 'Errore di lettura del file di messaggio di scambio';
				|pl = 'Błąd podczas odczytu pliku wymiany komunikatów';
				|tr = 'Veri alışverişi mesajı dosyası okunurken bir hata oluştu'", Common.DefaultLanguageCode());
	
EndFunction

Function ErrorSavingExchangeMessageFile()
	
	Return NStr("vi = 'Lỗi ghi lại dữ liệu vào tệp thông điệp trao đổi';
				|ru = 'Ошибка записи данных в файл сообщения обмена';
				|en = 'Failed to save data to the exchange message file.'; fa = 'Failed to save data to the exchange message file.';
				|it = 'Errore della scrittura dati nel file di messaggio di scambio';
				|pl = 'Błąd podczas zapisywania danych w pliku wymiany komunikatów';
				|tr = 'Veriler alışveriş mesajı dosyasına kaydedilirken bir hata oluştu'");
	
EndFunction

Function DataExchangeKindError()
	
	Return NStr("vi = 'Không hỗ trơj trao đổi không theo quy tắc chuyển đổi';
				|ru = 'Обмен не по правилам конвертации не поддерживается';
				|en = 'The exchange must follow the conversion rules.'; fa = 'The exchange must follow the conversion rules.';
				|it = 'Lo scambio fuori regole di conversione non è supportato';
				|pl = 'Wymiana nie zgodna z zasadami konwersji nie jest obsługiwana';
				|tr = 'Dönüşüm kurallarına uygun olmayan değişim desteklenmiyor'", Common.DefaultLanguageCode());
	
EndFunction

Function ThereIsAnExtensionInTheExchangeMessage(MessageReader)
	
	If Not DataExchangeServer.IsSubordinateDIBNode() 
		Or Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	HasExtensions = False;
	ThereAreExtensionsThatChangeDataStructure = False;
		
	ExchangeFile = New XMLReader;
	
	ExchangeFile.OpenFile(MessageReader.XMLReader.BaseURI);
	
	While ExchangeFile.Read() Do
		
		If ExchangeFile.Name = "v8de:Data"
			Or ExchangeFile.LocalName = "v8de:ConfigurationExtensions" 
			And ExchangeFile.NodeType = XMLNodeType.EndElement Then
			
			Break;
			
		EndIf;
		
		If ExchangeFile.Name = "v8de:ConfigurationExtensions" Then
			
			HasExtensions = True;
			Continue;
			
		EndIf;
		
		If HasExtensions And ExchangeFile.Name = "v8md:Metadata"
			Or ExchangeFile.Name = "v8de:ConfigurationExtensionDeletion" Then
			
			ThereAreExtensionsThatChangeDataStructure = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return ThereAreExtensionsThatChangeDataStructure
		Or HasExtensions And Not InfobaseNode.Metadata().IncludeConfigurationExtensions;
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf