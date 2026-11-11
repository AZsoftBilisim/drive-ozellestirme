////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

// The procedures and functions of this module provide the ability to match and
// recreate references stored in value stores.
// In this case, reference matching is not possible without additional processing,
// because the values written to the value stores are written
// to XML in the form of base64 during serialization.

#Region Internal

#Region RegisteringDataUploadAndDownloadHandlers

// Called when registering custom data upload handlers.
// In this procedure, you need to Supplement this table of values with information 
// about registered custom data upload handlers.
// 
// Parameters:
//   HandlersTable - ValueTable - Columns:
//    * MetadataObject - MetadataObject - when uploading data, the registered handler should be called,
//    * Handler - CommonModule - a general module that implements an arbitrary data upload handler. The set
//       of export procedures to be implemented in the handler depends on setting the values of the following
//       columns of the value table.
//    * Version - String - version number of the data upload / download handler interface supported by the handler,
//    * BeforeUnloadingType - Boolean - flag of the need to call the handler before unloading all objects of the information
//       base related to this metadata object. If the value is set to True 
//       , the exported Type Transfer procedure() must be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//         in the process of unloading data is the container data manager. For more information, see the comment on the processing software interface,
//        Serializer - XDTO serializer - initialized with support for link annotation. If
//         you need to upload additional data in an arbitrary upload handler, use
//         SerializatorXDTO, passed to the procedure before loading the type() as the value of the Serializer parameter, 
//         and not obtained using the global context property of the SerializatorXDTO,
//        Data objectmetadata - The data objectmetadata whose handler was called before the data was uploaded,
//        Failure - Boolean - if the value of this parameter is set to equal in the procedure before loading the type() 
//         True - objects corresponding to the Cur metadata object will not be uploaded.
//    * BeforeExportObject - Boolean - flag for whether a handler should be called before uploading a specific 
//       database object. If the value is set to True 
//       , the exported procedure before loading the object() must be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//        in the process of unloading data is the container manager. For more information, see the comment on the processing software interface,
//        The manager of the loading object is the processing object.Unloading and unloading of data from the Information database -
//          manager for unloading the Cur object. For more information, see the comment on the processing software interface
//          Unloaded and unloaded data from the management and unloaded data from the information database. The parameter is passed only when calling
//          handler procedures for which a version at least 1.0.0.1 is specified during registration,
//        Serializer - XDTO serializer - initialized with support for link annotation. If
//         you need to upload additional data in an arbitrary upload handler, use
//          SerializatorXDTO, passed to the procedure before loading the object() as the value of the Serializer parameter,
//          and not obtained using the global context property of the SerializatorXDTO,
//        Object - Value constantmanagement, Directory object, Document object,
//          Business ProcessObject, taskobject, planaccountsobject, Planobmanobject, PlanFormcHaracteristicObject, 
//          Type of Calculation planobject, Recordset Creation register, Recordset Registration register, 
//          The register of the bookgalteryinabor records, the register of the calculation of records, the sequence of a set of records, 
//          Recalculation of a recordset is an information database data object that the handler was called before uploading.
//          The value passed to the Object Transfer procedure() as the value of the Object parameter can be 
//          modified inside the Object Transfer handler(), and the changes made will be reflected 
//          in the object serialization in the upload files, but will not be recorded in the information database
//        Artifacts - An array Of ObjectXDTO - a set of additional information that is logically inextricably linked to the object,
//          but is not part of it (object artifacts). Artifacts must be generated inside the handler 
//          Before loading the object() and added to the array passed as the value of the Artifacts parameter. 
//          Each artifact must be an XDTO object, for the type of which an 
//          abstract XDTO type is used as the base type {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1 }Artefact. It is allowed to use 
//          XDTO-packages, in addition to those originally supplied as part of the Unloading and Unloading data subsystem. In the future
//          , the artifacts generated in the procedure before loading the object() will be available in the procedures 
//          of the data loading handlers (See OnRegisterDataImportHandlers)
//        . 
//          Failure - Boolean - if the value of this parameter is set to equal in the procedure before loading the object()
//                                       True - the object for which the handler was called will not be unloaded.
//    * AfterUnloadingType - Boolean - flag of the need to call the handler after unloading all objects of the information 
//       base related to this metadata object. If the value is set to True 
//       , the exported post-type() procedure should be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//         in the process of unloading data is the container data manager. For more information, see the comment on the processing software interface,
//        Serializer - XDTO serializer - initialized with support for link annotation. If 
//         you need to upload additional data in an arbitrary upload handler, use
//          SerializatorXDTO, passed to the procedure after loading the type() as the value of the Serializer parameter, 
//          and not obtained using the global context property of the SerializatorXDTO,
//        Data objectmetadata - Data objectmetadata - after the data was uploaded, the handler was called.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	MetadataList = ExportImportValueStoragesDataCached.ListOfMetadataObjectsThatHaveValueStore();
	
	For Each ListItem In MetadataList Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Metadata.FindByFullName(ListItem.Key);
		NewHandler.Handler = ExportImportValueStoragesData;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportValueStoragesData;
	NewHandler.BeforeUploadingSettings = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

// Called when the registration of arbitrary handlers load the data.
// In this procedure, you need to Supplement this table of values with information
// about registered custom data loading handlers.
// 
// Parameters:
//   HandlersTable - ValueTable - Columns:
//   * MetadataObject - MetadataObject - when loading data the registered handler should be called,
//   * Handler - CommonModule - a general module that implements an arbitrary data loading handler. The set 
//      of export procedures to be implemented in the handler depends on setting the values of the following
//      columns of the value table.
//   * Version - String - version number of the data upload / download handler interface supported by the handler,
//   * BeforeMapRefs - Boolean - flag of the need to call the handler before matching the links 
//      (in the original IS and in the Cur) related to this metadata object. If the value is set to True
//      , the exported procedure must be implemented in the general handler module before the links are supplied(), which supports 
//      the following parameters:
//        Container - Processing object.The container manager used 
//          in the data upload process is the container manager. For more information, see the comments on the processing software interface.
//          Data objectmetadata - Data objectmetadata - before matching the references of which the handler was called,
//        Standard processing - Boolean - If the procedure before the provision of links() sets the value of this 
//          parameter to False, instead of the standard link matching (searching for objects in the Cur IS with the same
//          natural key values that were unloaded from the IS source), the function will be called 
//          Match the links() of the shared module, in the procedure before the provision of links() of which the value of the parameter 
//          Standard processing has been set to False.
//          Parameters of the Match Links() function:
//            Container - Processing object.The container manager used
//              in the data upload process is the container manager. For more information, see the comments to the processing software interface
//            , the table of Outbound links - the table of assignments - containing information about links unloaded from the source information system. 
//              Columns:
//                Source link - Any link is a link of the object of the original information security, which you want to match with the link 
//                  in the Cur information security, 
//                The remaining columns are equal to the fields of the natural key of the object, which in the process of unloading data were 
//                  transferred to the function of unloading the data of the information database.It is required to provide a link to the Download()
//          The return value of the function Match Links() - tables of values, columns:
//            Source link - Any link is a link of an object unloaded from the source information system,
//            Link - Any link - a mapped source link in the Cur IS.
//        Failure - Boolean - If the value of this parameter is set to equal in the procedure before the provision of links() 
//          True - the mapping of links corresponding to the Cur metadata object will not be performed.
//   * BeforeImportType - Boolean - flag for calling the handler before loading all data objects 
//      related to this metadata object. If the value is set to True, the common handler module must
//      an exportable Preload Type procedure() can be implemented that supports the following parameters:
//        Container - Processing object.The container manager used 
//          in the data upload process is the container manager. For more information, see the comments on the processing software interface.
//        Data objectmetadata - Data objectmetadata - before loading all the data of which the handler was called,
//        Failure - Boolean - If you set the value of this parameter to equal in the procedure for preloading Type() 
//          True - loading of all data objects corresponding to the Cur metadata object will not be performed.
//   * BeforeImportObject - Boolean - flag for calling a handler before loading a data object 
//       related to this metadata object. If the value is set to True, the common handler module should
//       an exported procedure for preloading an object() can be implemented that supports the following parameters:
//        Container - Processing object.The container manager used 
//          in the data upload process is the container manager. For more information, see the comments to the processing software interface.
//        Object - Value constantmanagement, Reference object, Document object, Business Process object, Task object, 
//          PlanChetovObject, PlanObmenaObject, PlanChetcHaracteristicObject, planchetavigationobject, 
//          Register of Record Collection, Register of Record collection, Register of bookgalteryinabor records,
//          The register of the record setcountainment, the sequence of the record set, the recalculation of the record set - the data object 
//          of the information database, before loading which the handler was called.
//          The value passed to the Object Preloading procedure() as the value of the Object parameter can be 
//          modified inside the object Preloading handler procedure().
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked to the data object, 
//          but is not part of it. Generated in the exported procedures before loading the object() 
//          of data upload handlers (see the comment on the procedure for registering data upload handlers(). Each artifact 
//          must be an XDTO object, for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages, in addition 
//          to those originally supplied as part of the Unloading and Unloading data subsystem.
//        Failure - Boolean - If the value of this parameter is set to equal in the procedure for preloading the object() 
//          True - the data object will not be loaded.
//   * AfterImportObject - Boolean - flag for whether a handler should be called after loading a data object related
//      to this metadata object. If the value is set to True 
//      , the exported procedure for afterloading the object() must be implemented in the general handler module, which supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager is the container manager used
//          in the process of loading data. For more information, see the comments on the processing software interface.
//        Object - constantmanagement values - Reference object, Document object, Business Process object, Task object, 
//          PlanChetovObject, PlanObmenaObject, PlanChetcHaracteristicObject, planchetavigationobject, 
//          Register of Record Collection, Register of Record collection, Register of bookgalteryinabor records,
//          The register of the record setcounts, the sequence of the record set, the recalculation of the record set is the data object 
//          of the information database, after loading which the handler was called.
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked to the data object, 
//          but is not part of it. Generated in the exported procedures before loading the object() 
//          of data upload handlers (see the comment on the procedure for registering data upload handlers(). 
//          Each artifact must be an XDTO object, for the type of which an 
//          abstract XDTO type is used as the base type {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1 }Artefact. It is allowed to use 
//          XDTO-packages, in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//   * AfterLoadingType - Boolean - flag for calling the handler after loading all data objects 
//     related to this metadata object. If the value is set to True, the common handler module should
//     an exportable post-loading Type() procedure can be implemented that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager is the container manager used 
//        in the process of loading data. For more information, see the comments on the processing software interface.
//        Data objectmetadata - Data objectmetadata - after loading all the objects of which the handler was called.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	MetadataList = ExportImportValueStoragesDataCached.ListOfMetadataObjectsThatHaveValueStore();
	
	For Each ListItem In MetadataList Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Metadata.FindByFullName(ListItem.Key);
		NewHandler.Handler = ExportImportValueStoragesData;
		NewHandler.BeforeImportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportValueStoragesData;
	NewHandler.BeforeDownloadingSettings = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

#EndRegion

#EndRegion


#Region Private

#Region DataUploadAndDownloadHandlers

// Called before the object is unloaded.
// See OnRegisterDataExportHandlers
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	MetadataObject = Object.Metadata();
	PropsWithValueStorage = DetailsOfObjectWithValueStore(Container, MetadataObject);
	
	If PropsWithValueStorage = Undefined Then
		
		Raise StrTemplate(NStr("vi = 'Hàm sự kiện %2 không thể xử lý đối tượng metadata %1.';
								|ru = 'Объект метаданных %1 не может быть обработан обработчиком %2.';
								|en = 'The %2 handler cannot process the %1 metadata object.'; fa = 'The %2 handler cannot process the %1 metadata object.';
								|it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore %2.';
								|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania %2.';
								|tr = '%1 meta veri nesnesi %2 işleyicisi tarafından işlenemez.'"),
			MetadataObject.FullName(),
			"ExportImportValueStoragesData.BeforeExportObject");
		
	EndIf;
	
	If CommonCTL.IsConstant(MetadataObject) Then
		
		BeforeUnloadingConstant(Container, Object, Artifacts, PropsWithValueStorage);
		
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		BeforeUnloadingReferenceObject(Container, Object, Artifacts, PropsWithValueStorage);
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		
		BeforeExportRecordSet(Container, Object, Artifacts, PropsWithValueStorage);
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Đối tượng metadata bất thường: %1.';
								|ru = 'Неожиданный объект метаданных: %1.';
								|en = 'Unexpected metadata object: %1.'; fa = 'Unexpected metadata object: %1.';
								|it = 'Oggetto di metadati imprevisto: %1.';
								|pl = 'Nieoczekiwany obiekt metadanych: %1.';
								|tr = 'Beklenmedik meta veri nesnesi: %1.'"),
			MetadataObject.FullName);
		
	EndIf;
	
EndProcedure



// Performed before uploading settings.
// 
// Parameters:
// 	Container - DataProcessorObject.ExportImportDataUserSettingsImportManager - 
// 	Serializer - XDTOSerializer - 
// 	NameOfSettingsStore - String - 
// 	SettingsKey - String - see syntax -platform assistant.
// 	ObjectKey - String - see syntax -platform assistant.
// 	Settings - ValueStorage - 
// 	User - InfoBaseUser - 
// 	Presentation - String - 
// 	Artifacts - Array of XDTODataObject - additional data.
// 	Cancel - Boolean - indicates that processing was refused.
Procedure BeforeUploadingSettings(Container, Serializer, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	If TypeOf(Settings) = Type("ValueStorage") Then
		
		NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
		NewArtifact.Owner = XDTOFactory.Create(TypeOwnerBody());
		
		If UnloadValueStorage(Container, Settings, NewArtifact.Data) Then
			Settings = Undefined;
			Artifacts.Add(NewArtifact);
		EndIf;
		
	EndIf;
	
EndProcedure

// See OnRegisterDataExportHandlers
// Called before the object is unloaded.
//
Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	MetadataObject = Object.Metadata();
	
	For Each Artifact In Artifacts Do
		
		If Artifact.Type() <> ValueStoreArtifactType() Then
			Continue;
		EndIf;
		
		If CommonCTL.IsConstant(MetadataObject) Then
			
			BeforeLoadingConstant(Container, Object, Artifact);
			
		ElsIf CommonCTL.IsRefData(MetadataObject) Then
			
			BeforeLoadingReferenceObject(Container, Object, Artifact);
			
		ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
			
			BeforeLoadingRecordset(Container, Object, Artifact);
			
		Else
			
			Raise StrTemplate(NStr("vi = 'Đối tượng metadata bất thường: %1.';
									|ru = 'Неожиданный объект метаданных: %1.';
									|en = 'Unexpected metadata object: %1.'; fa = 'Unexpected metadata object: %1.';
									|it = 'Oggetto di metadati imprevisto: %1.';
									|pl = 'Nieoczekiwany obiekt metadanych: %1.';
									|tr = 'Beklenmedik meta veri nesnesi: %1.'"),
				MetadataObject.FullName);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure BeforeDownloadingSettings(Container, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	For Each Artifact In Artifacts Do
		
		If Artifact.Type() = ValueStoreArtifactType() And Artifact.Owner.Type() = TypeOwnerBody() Then
			
			LoadValueStore_(Container, Settings, Artifact);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Unloading data from value stores

// Called before unloading a constant with the value store.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	Object - Arbitrary - object of uploaded data.
//	Artifacts - Array - array of artifacts (XDTO objects).
//	PropsWithValueStorage - Array of Structure - see the structurequisitesreservation of values
//
Procedure BeforeUnloadingConstant(Container, Object, Artifacts, PropsWithValueStorage)
	
	NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
	NewArtifact.Owner = XDTOFactory.Create(TypeOwnerConstant());
	
	If UnloadValueStorage(Container, Object.Value, NewArtifact.Data) Then
		Object.Value = New ValueStorage(Undefined);
		Artifacts.Add(NewArtifact);
	EndIf;
	
EndProcedure

// Called before unloading the reference object with the value store.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	Object - Arbitrary - object of uploaded data.
//	Artifacts - Array - array of artifacts (XDTO objects).
//	PropsWithValueStorage - Array of Structure - see the structure of the Requirements for the storage of values.
//
Procedure BeforeUnloadingReferenceObject(Container, Object, Artifacts, PropsWithValueStorage)
	
	For Each CurrentAttribute In PropsWithValueStorage Do
		
		If CurrentAttribute.TabularSectionName = Undefined Then
			
			AttributeName = CurrentAttribute.AttributeName;
			
			NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
			NewArtifact.Owner = XDTOFactory.Create(OwnerObjectType());
			NewArtifact.Owner.Property = AttributeName;
			
			If UnloadValueStorage(Container, Object[AttributeName], NewArtifact.Data) Then
				Object[AttributeName] = New ValueStorage(Undefined);
				Artifacts.Add(NewArtifact);
			EndIf;
			
		Else
			
			AttributeName      = CurrentAttribute.AttributeName;
			TabularSectionName = CurrentAttribute.TabularSectionName;
			
			For Each LineOfATabularSection In Object[TabularSectionName] Do 
				
				NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
				NewArtifact.Owner = XDTOFactory.Create(TypeOwnerTabularPart());
				NewArtifact.Owner.TabularSection = TabularSectionName;
				NewArtifact.Owner.Property = AttributeName;
				NewArtifact.Owner.LineNumber = LineOfATabularSection.LineNumber;
				
				If UnloadValueStorage(Container, LineOfATabularSection[AttributeName], NewArtifact.Data) Then
					LineOfATabularSection[AttributeName] = New ValueStorage(Undefined);
					Artifacts.Add(NewArtifact);
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Called before unloading the record set of the object with the value store.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	RecordSet - InformationRegisterRecordSet, CalculationRegisterRecordSet, AccountingRegisterRecordSet - 
//               - CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - a set of uploaded data.
//	Artifacts - Array - array of artifacts (XDTO objects).
//	PropsWithValueStorage - Array of Structure - see the structure of the Requirements for the storage of values.
//
Procedure BeforeExportRecordSet(Container, RecordSet, Artifacts, PropsWithValueStorage)
	
	For Each CurrentAttribute In PropsWithValueStorage Do
		
		PropertyName = CurrentAttribute.AttributeName;
		
		For Each Record In RecordSet Do
			
			NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
			NewArtifact.Owner = XDTOFactory.Create(TypeOwnerRecordset());
			NewArtifact.Owner.Property = PropertyName;
			NewArtifact.Owner.LineNumber = RecordSet.IndexOf(Record);
			
			If UnloadValueStorage(Container, Record[PropertyName], NewArtifact.Data) Then
				Record[PropertyName] = New ValueStorage(Undefined);
				Artifacts.Add(NewArtifact);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Unloads the value store.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in 
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	ValueStorage - ValueStorage - storage.
//	Artifact - XDTODataObject - artifact.
//
// Returns:
//	Boolean - True if unloaded.
//
Function UnloadValueStorage(Container, ValueStorage, Artifact)
	
	If ValueStorage = Null Then
		
		// For example, the values of the details used only for the elements of the directory,
		// read from the directory group.
		Return False;
		
	EndIf;
	
	Try
		
		Value = ValueStorage.Get();
		
	Except
		
		// If it was not possible to get the value stored in it from the storage,
		// do not try to serialize it and leave it in the object.
		Return False;
		
	EndTry;
	
	If Value = Undefined
		Or (CommonCTL.IsPrimitiveType(TypeOf(Value)) And Not ValueIsFilled(Value)) Then
		
		Return False;
		
	Else
		
		Try
			
			Artifact = WriteValueStoreToArtifact(Container, Value);
			Return True;
			
		Except
			
			Return False; // If the storage could not be serialized, we will leave it in the object
			
		EndTry;
		
	EndIf;
	
EndFunction

// Writes the value store to the artifact.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in 
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	StorageValue - Arbitrary - the value of storage.
//
// Returns:
//	XDTODataObject - artifact.
//
Function WriteValueStoreToArtifact(Container, Val StorageValue)
	
	// Binary data of more than 64 KB should be uploaded as separate bin files, the rest together with the data.
	UploadAsBinary = TypeOf(StorageValue) = Type("BinaryData") And StorageValue.Size() > 64 * 1024;
	
	If UploadAsBinary Then
		
		Return WriteBinaryValueStorageToArtifact(Container, StorageValue);
		
	Else
		
		Return WriteSerializableValueStorageToArtifact(Container, StorageValue);
		
	EndIf;
	
EndFunction

// Writes the serializable value to the artifact.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in 
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	StorageValue - Arbitrary - the value of storage.
//
// Returns:
//	XDTODataObject - artifact.
//
Function WriteSerializableValueStorageToArtifact(Container, Val StorageValue)
	
	ValueDescription = XDTOFactory.Create(TypeSerializableValue());
	ValueDescription.Data = XDTOSerializer.WriteXDTO(StorageValue);
	
	Return ValueDescription;
	
EndFunction

// Writes a binary value to the artifact.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - The container manager	 used in the process
//	 of uploading data. For more information, see the comment on the program interface for processing the offload data of the Container manager.	
//	StorageValue - BinaryData - the value of storage.
//
// Returns:
//	XDTODataObject - artifact.
//
Function WriteBinaryValueStorageToArtifact(Container, Val StorageValue)
	
	FileName = Container.CreateCustomFile("bin");
	StorageValue.Write(FileName);
	
	ValueDescription = XDTOFactory.Create(TypeBinaryValue());
	ValueDescription.RelativeFilePath = Container.GetRelativeFileName(FileName);
	
	Container.FileRecorded(FileName);
	
	Return ValueDescription;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Loading data from value stores

// Called before loading the constant.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in 
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	Object - ConstantValueManager - constant value Manager.
//	Artifact - XDTODataObject - Artifact:
//	 * Owner - XDTODataObject - the owner of the artifact...
//
Procedure BeforeLoadingConstant(Container, Object, Artifact)
	
	If Artifact.Owner.Type() = TypeOwnerConstant() Then
		LoadValueStore_(Container, Object.Value, Artifact);
	Else
		
		Raise StrTemplate(NStr("vi = 'Không nên sử dụng kiểu đối tượng chủ {%1}%2 cho đối tượng metadata %3.';
								|ru = 'Тип владельца {%1}%2 не должен использоваться для объекта метаданных %3.';
								|en = 'Type of owner {%1}%2 cannot be used for metadata object %3.'; fa = 'Type of owner {%1}%2 cannot be used for metadata object %3.';
								|it = 'Tipo di titolare {%1}%2 non deve essere usato per l''oggetto metadati %3.';
								|pl = 'Typ właściciela {%1}%2 nie należy używać dla obiektu metadanych %3.';
								|tr = '{%1}%2 sahip türü, %3 meta veri nesnesi için kullanılmamalıdır.'"),
			Artifact.Owner.Type().NamespaceURI,
			Artifact.Owner.Type().Name,
			Object.Metadata().FullName());
		
	EndIf;
	
EndProcedure

// Called before loading the reference object.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	Object - Arbitrary - an object of the reference type.
//	Artifact - XDTODataObject - Artifact:
//	 * Owner - XDTODataObject - the owner of the artifact...
//
Procedure BeforeLoadingReferenceObject(Container, Object, Artifact)
	
	If Artifact.Owner.Type() = OwnerObjectType() Then
		LoadValueStore_(Container, Object[Artifact.Owner.Property], Artifact);
	ElsIf Artifact.Owner.Type() = TypeOwnerTabularPart() Then
		LoadValueStore_(Container,
			Object[Artifact.Owner.TabularSection].Get(Artifact.Owner.LineNumber - 1)[Artifact.Owner.Property],
			Artifact);
	Else
		
		Raise StrTemplate(NStr("vi = 'Không nên sử dụng kiểu đối tượng chủ {%1}%2 cho đối tượng metadata %3.';
								|ru = 'Тип владельца {%1}%2 не должен использоваться для объекта метаданных %3.';
								|en = 'Type of owner {%1}%2 cannot be used for metadata object %3.'; fa = 'Type of owner {%1}%2 cannot be used for metadata object %3.';
								|it = 'Tipo di titolare {%1}%2 non deve essere usato per l''oggetto metadati %3.';
								|pl = 'Typ właściciela {%1}%2 nie należy używać dla obiektu metadanych %3.';
								|tr = '{%1}%2 sahip türü, %3 meta veri nesnesi için kullanılmamalıdır.'"),
			Artifact.Owner.Type().NamespaceURI,
			Artifact.Owner.Type().Name,
			Object.Metadata().FullName());
		
	EndIf;
	
EndProcedure

// Called before loading the recordset.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//  RecordSet - InformationRegisterRecordSet, CalculationRegisterRecordSet, AccountingRegisterRecordSet -
//               - CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - a set of records.
//	Artifact - XDTODataObject - Artifact:
//	 * Owner - XDTODataObject - the owner of the artifact....
Procedure BeforeLoadingRecordset(Container, RecordSet, Artifact)
	
	If Artifact.Owner.Type() = TypeOwnerRecordset() Then
		LoadValueStore_(Container,
			RecordSet.Get(Artifact.Owner.LineNumber)[Artifact.Owner.Property],
			Artifact);
	Else
		
		Raise StrTemplate(NStr("vi = 'Không nên sử dụng kiểu đối tượng chủ {%1}%2 cho đối tượng metadata %3.';
								|ru = 'Тип владельца {%1}%2 не должен использоваться для объекта метаданных %3.';
								|en = 'Type of owner {%1}%2 cannot be used for metadata object %3.'; fa = 'Type of owner {%1}%2 cannot be used for metadata object %3.';
								|it = 'Tipo di titolare {%1}%2 non deve essere usato per l''oggetto metadati %3.';
								|pl = 'Typ właściciela {%1}%2 nie należy używać dla obiektu metadanych %3.';
								|tr = '{%1}%2 sahip türü, %3 meta veri nesnesi için kullanılmamalıdır.'"),
			Artifact.Owner.Type().NamespaceURI,
			Artifact.Owner.Type().Name,
			RecordSet.Metadata().FullName());
		
	EndIf;
	
EndProcedure

// Loads the value storage value from the artifact.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	A recordset is a set of records.
//	Artifact - XDTODataObject - Artifact:
//	 * Data - XDTODataObject - the data artifact....
//
Procedure LoadValueStore_(Container, ValueStorage, Artifact)
	
	If Artifact.Data.Type() = TypeBinaryValue() Then
		FileName = Container.GetFullFileName(Artifact.Data.RelativeFilePath);
		Value = New BinaryData(FileName);
	ElsIf Artifact.Data.Type() = TypeSerializableValue() Then
		Value = LoadSerializableValueData(Artifact.Data.Data);
	Else
		
		Raise StrTemplate(NStr("vi = 'Kiểu vị trí không mong muốn của dữ liệu kho chứa giá trị trong dữ liệu kết xuất: {%1}%2.';
								|ru = 'Неожиданный тип размещения данных хранилища значений в контейнере выгрузки: {%1}%2.';
								|en = 'Unexpected placement type of value storage data in export container: {%1}%2.'; fa = 'Unexpected placement type of value storage data in export container: {%1}%2.';
								|it = 'Tipo imprevisto di allocazione dei dati per l''archiviazione dei valori nel contenitore di upload: {%1}%2.';
								|pl = 'Nieoczekiwany typ rozmieszczenia danych pamięci wartości w kontenerze wyciągu: {%1}%2.';
								|tr = 'Dışa aktarma kapsayıcısında veri depolayan beklenmeyen konum türü: {%1}%2.'"),
			Artifact.Data.Type().NamespaceURI,
			Artifact.Data.Type().Name);
		
	EndIf;
	
	ValueStorage = New ValueStorage(Value);
	
EndProcedure

Function LoadSerializableValueData(ArtifactValue)
	
	If TypeOf(ArtifactValue) = Type("XDTODataObject") Then
		Try
			Value = XDTOSerializer.ReadXDTO(ArtifactValue);
		Except
			If ArtifactValue.Type() = XDTODataCompositionSettingsType() Then
				Value = Undefined;
			Else
				Raise;
			EndIf;
		EndTry;
	Else
		Value = ArtifactValue;
	EndIf;	
	
	Return Value;
	
EndFunction

Function XDTODataCompositionSettingsType()
	
	Return XDTOFactory.Type("http://v8.1c.ru/8.1/data-composition-system/settings", "Settings");
	
EndFunction

// Returns an array of structures that store the names of details and table parts
// that contain value stores.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in
//	 the data upload process. For more information, see the comment on the software interface for processing the unloading of the data of the Manager container.
//	ObjectMetadata - MetadataObject - the metadata object.
//
// Returns:
//	Array - Array of Structure - see The structure of the Requirements is a storage of values.
//
Function DetailsOfObjectWithValueStore(Container, Val ObjectMetadata)
	
	FullMetadataName = ObjectMetadata.FullName();
	
	MetadataList = ExportImportValueStoragesDataCached.ListOfMetadataObjectsThatHaveValueStore();
	
	PropsWithValueStorage = MetadataList.Get(FullMetadataName);
	If PropsWithValueStorage = Undefined Then 
		Return Undefined;
	EndIf;
	
	Return PropsWithValueStorage;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions defining the types of XDTO objects

// Type of value storage artifact.
//
// Returns:
//	XDTOObjectType - the type of the returned object.
//
Function ValueStoreArtifactType()
	
	Return XDTOFactory.Type(Package(), "ValueStorageArtefact");
	
EndFunction

// Type of binary value.
//
// Returns:
//	XDTOObjectType - the type of the returned object.
//
Function TypeBinaryValue()
	
	Return XDTOFactory.Type(Package(), "BinaryValueStorageData");
	
EndFunction

// Type of the serialized value.
//
// Returns:
//	XDTOObjectType - the type of the returned object.
//
Function TypeSerializableValue()
	
	Return XDTOFactory.Type(Package(), "SerializableValueStorageData");
	
EndFunction

// Type of the constant owner.
//
// Returns:
//	XDTOObjectType - the type of the returned object.
//
Function TypeOwnerConstant()
	
	Return XDTOFactory.Type(Package(), "OwnerConstant");
	
EndFunction

// Type of the owner of the reference object.
//
// Returns:
//	XDTOObjectType - the type of the returned object.
//
Function OwnerObjectType()
	
	Return XDTOFactory.Type(Package(), "OwnerObject");
	
EndFunction

// Type of owner of the table part.
//
// Returns:
//	XDTOObjectType - the type of the returned object.
//
Function TypeOwnerTabularPart()
	
	Return XDTOFactory.Type(Package(), "OwnerObjectTabularSection");
	
EndFunction

// The owner type of the recordset.
//
// Returns:
//	XDTOObjectType - the type of the returned object.
//
Function TypeOwnerRecordset()
	
	Return XDTOFactory.Type(Package(), "OwnerRecordset");
	
EndFunction

Function TypeOwnerBody()
	
	Return XDTOFactory.Type(Package(), "OwnerBody");
	
EndFunction

// Returns the namespace of the XDTO-package for storage of values.
//
// Returns:
//	String - the namespace of the XDTO package for value stores.
//
Function Package()
	
	Return "http://www.1c.ru/1cFresh/Data/Artefacts/ValueStorage/1.0.0.1";
	
EndFunction

#EndRegion
