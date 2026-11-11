///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurrentUnspecifedUserID;
Var SourceUnspecifedUserID;
Var SavedRefsToUnspecifiedUser;

#EndRegion

#Region Internal

#Region DataExportHandlers

Procedure BeforeExportData(Container) Export
	
	CurrentUnspecifedUserID = UsersInternal.CreateUnspecifiedUser().UUID();
	
	FileName = Container.CreateCustomFile("xml", DataTypeForUnspecifiedUserIDExport());
	WriteObjectToFile(CurrentUnspecifedUserID, FileName);
	
EndProcedure

// Called before an object export.
// See "OnRegisterDataExportHandlers".
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager
//  ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager
//  Serializer - XDTOSerializer
//  Object - ConstantValueManager
//         - CatalogObject
//         - DocumentObject
//         - BusinessProcessObject
//         - TaskObject
//         - ChartOfAccountsObject
//         - ExchangePlanObject
//         - ChartOfCharacteristicTypesObject
//         - ChartOfCalculationTypesObject
//         - InformationRegisterRecordSet
//         - AccumulationRegisterRecordSet
//         - AccountingRegisterRecordSet
//         - CalculationRegisterRecordSet
//         - SequenceRecordSet
//         - RecalculationRecordSet
//  Artifacts - Array
//  Cancel - Boolean
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	If TypeOf(Object) <> Type("CatalogObject.Users") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàm sự kiện %2 không thể xử lý đối tượng metadata %1.';
				|ru = 'Объект метаданных %1 не может быть обработан обработчиком %2.';
				|en = 'Handler %2 cannot handle metadata object %1.'; fa = 'Handler %2 cannot handle metadata object %1.';
				|it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore %2.';
				|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania %2.';
				|tr = '%1 meta veri nesnesi %2 işleyicisi tarafından işlenemez.'"),
			Object.Metadata().FullName(),
			"ExportImportDataCollapsingUserReferencesInSeparatedData.BeforeExportObject");
	EndIf;
		
	If Object.Ref.UUID() = CurrentUnspecifedUserID Then
		
		NewArtifact = XDTOFactory.Create(UnspecifiedUserArtifactType());
		Artifacts.Add(NewArtifact);
		
	ElsIf UsersInternalSaaS.UserRegisteredAsShared(Object.IBUserID) Then
		
		NewArtifact = XDTOFactory.Create(SharedUserArtifactType());
		NewArtifact.UserName = InternalNameOfSharedUser(Object.IBUserID);
		Artifacts.Add(NewArtifact);
		
	EndIf;
	
EndProcedure

Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	If TypeOf(Object) <> Type("CatalogObject.Users") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàm sự kiện %2 không thể xử lý đối tượng metadata %1.';
				|ru = 'Объект метаданных %1 не может быть обработан обработчиком %2.';
				|en = 'Handler %2 cannot handle metadata object %1.'; fa = 'Handler %2 cannot handle metadata object %1.';
				|it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore %2.';
				|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania %2.';
				|tr = '%1 meta veri nesnesi %2 işleyicisi tarafından işlenemez.'"),
			Object.Metadata().FullName(),
			"ExportImportDataCollapsingUserReferencesInSeparatedData.AfterExportObject");
	EndIf;
		
	If Object.Ref.UUID() <> CurrentUnspecifedUserID Then
		
		IsSharedUserRef = UsersInternalSaaS.UserRegisteredAsShared(
			Object.IBUserID);
		
		NaturalKey = New Structure("Shared2", IsSharedUserRef);
		ObjectExportManager.YouNeedToMatchLinkWhenDownloading(Object.Ref, NaturalKey);
		
	EndIf;
		
EndProcedure

#EndRegion

#Region DataImportHandlers

// Called before data import.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//    For details, see comments to the API of ExportImportDataContainerManager.
//    
//
Procedure BeforeImportData(Container) Export
	
	CurrentUnspecifedUserID = UsersInternal.CreateUnspecifiedUser().UUID();
	
	FileName = Container.GetCustomFile(DataTypeForUnspecifiedUserIDExport());
	SourceUnspecifedUserID = ReadObjectFromFile(FileName);
	
EndProcedure

Procedure BeforeMapRefs(Container, MetadataObject, SourceRefsTable, StandardProcessing, Cancel) Export
	
	If MetadataObject = Metadata.Catalogs.Users Then
		
		StandardProcessing = False;
		
	Else
		
		Raise NStr("vi = 'Đã chỉ ra sai kiểu dữ liệu';
					|ru = 'Тип данных указан неверно';
					|en = 'Data type is specified incorrectly'; fa = 'Data type is specified incorrectly';
					|it = 'Il tipo di dati indicato è errato';
					|pl = 'Typ danych jest nieprawidłowy';
					|tr = 'Veri türü yanlış belirtilmiş'");
		
	EndIf;
	
EndProcedure

Function MapRefs(Container, RefsMapManager, SourceRefsTable) Export
	
	ColumnName = RefsMapManager.SourceLinkColumnName_();
	
	Result = New ValueTable();
	Result.Columns.Add(ColumnName, New TypeDescription("CatalogRef.Users"));
	Result.Columns.Add("Ref", New TypeDescription("CatalogRef.Users"));
	
	UnspecifiedUserMapping = Result.Add();
	UnspecifiedUserMapping[ColumnName] =
		Catalogs.Users.GetRef(SourceUnspecifedUserID);
	UnspecifiedUserMapping.Ref =
		Catalogs.Users.GetRef(CurrentUnspecifedUserID);
	
	MergeSharedUsers = False;
	MergeSeparatedUsers = False;
	
	If Common.DataSeparationEnabled() Then
		
		If Container.ImportParameters().Property("CollapseSeparatedUsers") Then
			MergeSeparatedUsers = Container.ImportParameters().CollapseSeparatedUsers;
		Else
			MergeSeparatedUsers = False;
		EndIf;
		
	Else
		MergeSharedUsers = True;
		MergeSeparatedUsers = False;
	EndIf;
	
	For Each SourceRefsTableRow In SourceRefsTable Do
		
		If SourceRefsTableRow.Shared2 Then
			
			If MergeSharedUsers Then
				
				UserMapping = Result.Add();
				UserMapping[ColumnName] = SourceRefsTableRow[ColumnName];
				UserMapping.Ref =
					Catalogs.Users.GetRef(CurrentUnspecifedUserID);
				
			EndIf;
			
		Else
			
			If MergeSeparatedUsers Then
				
				UserMapping = Result.Add();
				UserMapping[ColumnName] = SourceRefsTableRow[ColumnName];
				UserMapping.Ref =
					Catalogs.Users.GetRef(CurrentUnspecifedUserID);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Executes handlers before importing a particular data type.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - a container
//		manager used for data export. For more information, see the comment
//		to ExportImportDataContainerManager handler interface.
//  MetadataObject - MetadataObject - Metadata object.
//  Cancel - Boolean - indicates if the operation is completed.
//
Procedure BeforeImportType(Container, MetadataObject, Cancel) Export
	
	If UsersInternalSaaSCached.RecordSetsWithRefsToUsersList().Get(MetadataObject) <> Undefined Then
		
		SavedRefsToUnspecifiedUser = New ValueTable();
		
		For Each Dimension In MetadataObject.Dimensions Do
			
			SavedRefsToUnspecifiedUser.Columns.Add(Dimension.Name, Dimension.Type);
			
		EndDo;
		
	Else
		
		SavedRefsToUnspecifiedUser = Undefined;
		
	EndIf;
	
EndProcedure

Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	If TypeOf(Object) = Type("CatalogObject.Users") Then
		
		// "Users" catalog.
		IsSourceUnspecifiedUser = False;
		UtilityUsersIDS = UtilityUsersIDS();
		
		For Each Artifact In Artifacts Do
			
			If Artifact.Type() = SharedUserArtifactType() Then
				
				FoundRow = UtilityUsersIDS.Find(Artifact.UserName, "UserName");
				If FoundRow = Undefined Then
					Id = New UUID("00000000-0000-0000-0000-000000000000");
				Else
					Id = FoundRow.IBUserID;
				EndIf;
				
				If UsersInternalSaaS.UserRegisteredAsShared(Id) Then
					
					Object.IBUserID = Id;
					Object.Description = UsersInternalSaaS.InternalUserFullName(Id);
					
				EndIf;
				
			ElsIf Artifact.Type() = UnspecifiedUserArtifactType() Then
				
				IsSourceUnspecifiedUser = True;
				
			EndIf;
			
		EndDo;
		
		If Object.Ref.UUID() = CurrentUnspecifedUserID And Not IsSourceUnspecifiedUser Then
			Cancel = True;
		EndIf;
		
	ElsIf UsersInternalSaaSCached.RecordSetsWithRefsToUsersList().Get(Object.Metadata()) <> Undefined Then
		
		// Set of records containing a dimension with the CatalogRef.Users type
		CollapseRefsToUsersInSet(Object);
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàm sự kiện %2 không thể xử lý đối tượng metadata %1.';
				|ru = 'Объект метаданных %1 не может быть обработан обработчиком %2.';
				|en = 'Handler %2 cannot handle metadata object %1.'; fa = 'Handler %2 cannot handle metadata object %1.';
				|it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore %2.';
				|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania %2.';
				|tr = '%1 meta veri nesnesi %2 işleyicisi tarafından işlenemez.'"),
			Object.Metadata().FullName(),
			"ExportImportDataCollapsingUserReferencesInSeparatedData.BeforeImportObject");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function DataTypeForUnspecifiedUserIDExport()
	
	Return "1cfresh\ApplicationData\DefaultUserRef";
	
EndFunction

Function SharedUserArtifactType() 
	
	Return XDTOFactory.Type(Package(), "UnseparatedUser");
	
EndFunction

Function UnspecifiedUserArtifactType()
	
	Return XDTOFactory.Type(Package(), "UndefinedUser");
	
EndFunction

Function Package()
	
	Return "http://www.1c.ru/1cFresh/Data/Artefacts/ServiceUsers/1.0.0.1";
	
EndFunction

Function InternalNameOfSharedUser(Val Id)
	
	Manager = InformationRegisters.SharedUsers.CreateRecordManager();
	Manager.IBUserID = Id;
	Manager.Read();
	If Manager.Selected() Then
		Return Manager.UserName;
	Else
		Return "";
	EndIf;
	
EndFunction

Function UtilityUsersIDS()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SharedUsers.UserName AS UserName,
	|	SharedUsers.IBUserID AS IBUserID
	|FROM
	|	InformationRegister.SharedUsers AS SharedUsers";
	
	Result = Query.Execute().Unload();
	Result.Indexes.Add("UserName");
	
	Return Result;
	
EndFunction

Procedure CollapseRefsToUsersInSet(RecordSet)
	
	UnspecifiedUserRef = Catalogs.Users.GetRef(CurrentUnspecifedUserID);
	
	RecordsToDelete = New Array();
	
	RegisterMetadata = RecordSet.Metadata(); // MetadataObjectInformationRegister
	
	For Each Record In RecordSet Do
		
		StatusBarFilter = New Structure();
		
		For Each Dimension In RegisterMetadata.Dimensions Do
			
			ValueToCheck = Record[Dimension.Name];
			
			If ValueIsFilled(ValueToCheck) Then
				
				If TypeOf(ValueToCheck) = Type("CatalogRef.Users") Then
					
					If ValueToCheck = UnspecifiedUserRef Then
						
						StatusBarFilter.Insert(Dimension.Name, ValueToCheck);
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If StatusBarFilter.Count() > 0 Then
			
			If SavedRefsToUnspecifiedUser.FindRows(StatusBarFilter).Count() = 0 Then
				
				StatusBar = SavedRefsToUnspecifiedUser.Add();
				FillPropertyValues(StatusBar, Record);
				
			Else
				
				RecordsToDelete.Add(Record);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each RecordToDelete In RecordsToDelete Do
		
		RecordSet.Delete(RecordToDelete);
		
	EndDo;
	
EndProcedure

// Writes an object to file.
//
// Parameters:
//  Object - UUID - Object being written.
//  FileName - String - File path.
//  Serializer - XDTOSerializer - Serializer.
//
Procedure WriteObjectToFile(Val Object, Val FileName, Serializer = Undefined)
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	
	WriteObjectToStream(Object, WriteStream, Serializer);
	
	WriteStream.Close();
	
EndProcedure

// Writes an object to write stream.
//
// Parameters:
//  Object - UUID - Object being written.
//  WriteStream - XMLWriter - a write stream.
//  Serializer - XDTOSerializer - Serializer.
//
Procedure WriteObjectToStream(Val Object, WriteStream, Serializer = Undefined)
	
	If Serializer = Undefined Then
		Serializer = XDTOSerializer;
	EndIf;
	
	WriteStream.WriteStartElement("Data");
	
	NamespacesPrefixes = NamespacesPrefixes();
	For Each NamespacesPrefix In NamespacesPrefixes Do
		WriteStream.WriteNamespaceMapping(NamespacesPrefix.Value, NamespacesPrefix.Key);
	EndDo;
	
	Serializer.WriteXML(WriteStream, Object, XMLTypeAssignment.Explicit);
	
	WriteStream.WriteEndElement();
	
EndProcedure

// Returns an object from file.
//
// Parameters:
//  FileName - String - File path.
//
// Returns:
//  CatalogObject.Users
//  Undefined
//
Function ReadObjectFromFile(Val FileName)
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(FileName);
	ReaderStream.MoveToContent();
	
	Object = ReadObjectFromStream(ReaderStream);
	
	ReaderStream.Close();
	
	Return Object;
	
EndFunction

// Returns an object from file.
//
// Parameters:
//  ReaderStream - XMLReader - a reader stream.
//
// Returns:
//  CatalogObject.Users
//  Undefined
//
Function ReadObjectFromStream(ReaderStream)
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement Or ReaderStream.Name <> "Data" Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Đang chờ bắt đầu phần tử %1.';
				|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента %1.';
				|en = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.';
				|it = 'Errore di lettura XML. Formato errato di file. Atteso inizio dell''elemento %1.';
				|pl = 'Błąd odczytu XML. Nieprawidłowy format pliku. Jest oczekiwany początek elementu %1.';
				|tr = 'XML okuma hatası. Geçersiz dosya biçimi. %1 bileşenin başlangıcı bekleniyor.'"),
			"Data");
	EndIf;
	
	If Not ReaderStream.Read() Then
		Raise NStr("vi = 'Lỗi đọc XML. Tìm thấy sự kết thúc tệp.';
					|ru = 'Ошибка чтения XML. Обнаружено завершение файла.';
					|en = 'XML reading error. File end is detected.'; fa = 'XML reading error. File end is detected.';
					|it = 'Errore di lettura XML. Esecuzione file rilevata.';
					|pl = 'Błąd odczytu XML. Wykryto zakończenie pliku.';
					|tr = 'XML okuma hatası. Dosyanın sonlandırıldığı tespit edildi.'");
	EndIf;
	
	Object = XDTOSerializer.ReadXML(ReaderStream);
	Return Object;
	
EndFunction

// Returns prefixes to frequently used namespaces.
//
// Returns:
//  Map of KeyAndValue:
//  Key - String - a namespace.
//  Value - String - a prefix.
//
Function NamespacesPrefixes() Export
	
	Result = New Map();
	
	Result.Insert("http://www.w3.org/2001/XMLSchema", "xs");
	Result.Insert("http://www.w3.org/2001/XMLSchema-instance", "xsi");
	Result.Insert("http://v8.1c.ru/8.1/data/core", "v8");
	Result.Insert("http://v8.1c.ru/8.1/data/enterprise", "ns");
	Result.Insert("http://v8.1c.ru/8.1/data/enterprise/current-config", "cc");
	Result.Insert("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "dmp");
	
	Return New FixedMap(Result);
	
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