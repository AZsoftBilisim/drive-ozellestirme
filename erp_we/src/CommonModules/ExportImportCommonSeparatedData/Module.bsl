////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Fills in an array of types that need to be annotated
// with links in the upload files when uploading.
//
// Parameters:
//  Types - Array of MetadataObject - metadata object. 
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	ListOfSharedMetadataObjects = ExportImportCommonSeparatedDataCached.SharedMetadataObjects_();
	
	For Each KeyAndValue In ListOfSharedMetadataObjects Do
		
		For Each TypeName In KeyAndValue.Value.Objects Do
			
			Types.Add(Metadata.FindByFullName(TypeName));
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Called when registering custom data upload handlers.
//
// Parameters:
//   HandlersTable - ValueTable -  In this procedure, it is required
//  to supplement this table of values with information about registered arbitrary
//  data upload handlers. Columns:
//    Data objectmetadata - Data objectmetadata - when uploading data
//      , the registered handler should be called,
//    Handler - General module - a general module in which an arbitrary
//      data upload handler is implemented. A set of export procedures that should
//      can be implemented in the handler, depends on setting the values of the following
//      columns of the table of values,
//    Version - String is the version number of the data upload/download handler interface
//      supported by the handler,
//    Before loading the type, a Boolean flag indicates whether the handler needs to be called before
//      unloading all information database objects related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exported procedure can be implemented before loading the type(),
//      which supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of unloading data. For more information, see the comment
//          on the program interface for processing the offload and offload data of the Container manager,
//        Serializer - XDTO serializer - initialized with support for
//          link annotation. If you need
//          to upload additional data in an arbitrary upload handler, use
//          SerializatorXDTO, passed to the procedure before loading the type() as
//          the value of the Serializer parameter, and not obtained using the global
//          context property of the SerializatorXDTO,
//        Data objectmetadata - The data objectmetadata whose
//          handler was called before the data was uploaded,
//        Failure - Boolean - If the value
//          of this parameter is set to True in the procedure before loading the type(), the objects corresponding
//          to the Cur metadata object will not be unloaded.
//    Before loading an object - Boolean flag of the need to call a handler before
//      unloading a specific object of the information base. If the value is assigned
//      True - the exported procedure must be implemented in the general handler module
//      Before loading an object() that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of unloading data. For more information, see the comment
//          on the program interface for processing the offload and offload data of the Container manager,
//        The
//          manager of the loading of the object is the processing of the object - the unloading of the data. The manager of the loading of the data of the information database is the manager of the unloading of the Cur object. For more information, see the comment on the processing software interface
//          Unloaded and unloaded data from the management and unloaded data from the information database. The parameter is passed only when calling
//          handler procedures for which a version at least 1.0.0.1 is specified during registration,
//        Serializer - XDTO serializer - initialized with support for
//          link annotation. If you need
//          to upload additional data in an arbitrary upload handler, use
//          SerializatorXDTO, passed to the procedure before loading the object() as
//          the value of the Serializer parameter, and not obtained using the global
//          context property of the SerializatorXDTO,
//        The object is a constant value manager.* - A reference object.*, Document object.*,
//          Business ProcessObject.*, Taskobject.*, Account planobject.*, PlanObmenaObject.*,
//          The plan of the type of characteristicobject.*, A kind of calculation planobject.*, Register of Recordset entries.*,
//          The register of a set of records.*, Register of bookgalteriinabor records.*,
//          The register is calculated by the records.*, A sequence of a set of recordings.*, Recalculating a set of records.* -
//          the data object of the information database, before unloading which the handler was called.
//          The value passed to the procedure before loading the object() as a parameter value
//          The object can be modified inside the handler before loading the object(). In
//          this case, the changes made will be reflected in the serialization of the object in the upload files, but
//          will not be recorded in the information database
//        Artifacts - An array Of ObjectXDTO - a set of additional information that is logically inextricably
//          linked to the object, but is not part of it (object artifacts). Artifacts must
//          be generated inside the handler before loading the object() and added to the array passed
//          as the value of the Artifacts parameter. Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem. In the future
//          , the artifacts generated in the procedure before loading the object() will be available in the procedures
//          of the data loading processors (see the comment on the procedure for registering the Data loading processors().
//        Failure - Boolean - If the value
//           of this parameter is set to True in the procedure before loading the object(), the object for which the handler was called
//           will not be unloaded.
//    After loading the type() - Boolean, flag for calling the handler after unloading all
//      information base objects related to this metadata object. If the value is assigned
//      True - the exported procedure must be implemented in the general handler module
//      Post-loading type() that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of unloading data. For more information, see the comment
//          on the program interface for processing the offload and offload data of the Container manager,
//        Serializer - XDTO serializer - initialized with support for
//          link annotation. If you need
//          to upload additional data in an arbitrary upload handler, use
//          SerializatorXDTO, passed to the procedure after loading the type() as
//          the value of the Serializer parameter, and not obtained using the global
//          context property of the SerializatorXDTO,
//        Data objectmetadata - Data objectmetadata - after the data was uploaded
//          , the handler was called.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	ListOfSharedMetadataObjects = ExportImportCommonSeparatedDataCached.SharedMetadataObjects_();
	
	For Each KeyAndValue In ListOfSharedMetadataObjects Do
		
		For Each MetadataObjectName In KeyAndValue.Value.Objects Do
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportCommonSeparatedData;
			NewHandler.AfterExportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	ListOfSharedMetadataObjects = ExportImportCommonSeparatedDataCached.SharedMetadataObjects_();
	
	ObjectFoundInCache = False;
	MetadataObject = Object.Metadata(); // MetadataObject
	
	For Each KeyAndValue In ListOfSharedMetadataObjects Do
		For Each MetadataObjectName In KeyAndValue.Value.Objects Do
			If MetadataObjectName = MetadataObject.FullName() Then
				ObjectFoundInCache = True;
			EndIf;
		EndDo;
	EndDo;
	
	If Not ObjectFoundInCache Then
		
		Raise StrTemplate(
			NStr("vi = 'Đối tượng metadata %1 không thể là hàm sự kiện %2,
                  |vì không có trong bộ nhớ đệm các đối tượng được chia tách chung.
                  |Nếu sau khi điều chỉnh cấu trúc metadata cấu hình, mà chưa cập nhật bộ nhớ đệm thì cần
                  |cập nhật bộ nhớ đệm của các đối tượng được chia tách chung bằng cách gọi ra phương thức
                  |%3';
                  |ru = 'Объект метаданных %1 не может быть обработчиком %2,
                  |т.к. отсутствует в кэше совместно-разделенных объектов.
                  |Если после редактирования структуры метаданных конфигурации кэш не обновлялся - необходимо выполнять
                  |обновление кэша совместно-разделенных объектов с помощью вызова метода
                  |%3';
                  |en = 'The %1 metadata object cannot be the %2 handler
                  |as it is missing from the cache of objects separated together.
                  |If the cache is not updated after the metadata structure is edited,
                  |update the cache of objects separated together by calling the method
                  |%3'; fa = 'The %1 metadata object cannot be the %2 handler
                  |as it is missing from the cache of objects separated together.
                  |If the cache is not updated after the metadata structure is edited,
                  |update the cache of objects separated together by calling the method
                  |%3';
                  |it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore %2,
                  | poiché risulta mancante nella cache degli oggetti condivisi.
                  |Se, dopo aver modificato la struttura dei metadati della configurazione, la cache non viene aggiornata,
                  | è necessario aggiornare la cache degli oggetti condivisi definendo il metodo
                  |%3';
                  |pl = 'Obiekt metadanych %1 nie może być procedurą przetwarzania %2,
                  |w pamięci podręcznej jest brak obiektów wspólnie-podzielonych obiektów. 
                  |Jeżeli po edycji struktury metadanych konfiguracji pamięć podręczna nie jest aktualizowana - należy wykonać 
                  |aktualizację pamięci podręcznej obiektów wspólnie-podzielonych za pomocą wyłowania metody 
                  |%3';
                  |tr = '%1 meta veri nesnesi, %2 işleyicisi olamaz,
                  |çünkü paylaşılan-ayrılmış nesnelerin önbelleğinde bukunmuyor.
                  |Yapılandırma meta veri yapısı düzenlendikten sonra önbellek güncellenmediyse,
                  |paylaşılan-ayrılmış nesnelerin önbelleğini yöntemi çağırarak
                  |%3 güncellemelisiniz'", Metadata.DefaultLanguage.LanguageCode),
			MetadataObject.FullName(),
			"UploadingSharedData.BeforeExportObject",
			"ExportImportCommonSeparatedData.FillCacheOfSharedObjects");
		
	EndIf;
	
	ObjectExportManager.YouNeedToRecreateLinkWhenUploading(Object.Ref);
	
EndProcedure

// Called when the registration of arbitrary handlers load the data.
//
// Parameters:
//   HandlersTable - ValueTable -  In this procedure, it is required
//  to supplement this table of values with information about registered arbitrary
//  data loading handlers. Columns:
//    Data objectmetadata - Data objectmetadata - when loading data
//      , the registered handler should be called,
//    Handler - General module - a general module in which an arbitrary
//      data loading handler is implemented. A set of export procedures that should
//      to be implemented in the handler, depends on setting the values of the following
//      columns of the table of values,
//    Version - String - version number of the data upload/download handler interface
//      supported by the handler,
//    Before the links are set, a Boolean flag indicates whether the handler needs to be called before
//      matching the links (in the original IS and in the Cur) related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable procedure must be implemented before the links are supplied(),
//      which supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata -
//          the handler was called before matching the references of which,
//        Standard Processing - Boolean - If the procedure is
//          set to False before providing links(), instead of the standard
//          link matching (searching for objects in the Cur IS with the same
//          natural key values that were unloaded from the IS source)
//          , the function Match Links() of the general module will be called in the procedure
//          Before the delivery of the links() whose value is the parameter Standardprocessing
//          it was set to equal False.
//          Parameters of the Match Links() function:
//            Container - processingobject - Offload-Offload data of the Container manager
//              is the container manager used in the process of loading data. For more information, see the comment
//              to the program interface for processing the uploadingmediagercontainer,
//            the table of outgoing links - the table of assignments - containing information about links
//              unloaded from the source information system. Columns:
//                Source link - Any link is a link of the object of the original information security, which you want
//                  to match with the link in the Cur information security,
//                The remaining columns are equal to the fields of the object's natural key, which
//                  were passed to the function during the data upload process
//                  Processing.Unloaded and unloaded data from the management and unloaded data from the information database.It is required to provide a link to the Download()
//          The return value of the function Match Links() - Value tables, columns:
//            Source link - Any link is a link of an object unloaded from the source information system,
//            Link - Any link - a mapped source link in the Cur IS.
//        Failure - Boolean - If the value
//          of this parameter is set to True in the procedure before the provision of links(), the mapping of links corresponding
//          to the Cur metadata object will not be performed.
//    Before loading the type, a Boolean flag indicates whether a handler needs to be called before
//      loading all data objects related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable Preload Type procedure() can be implemented
//      that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - The data objectmetadata whose
//          handler was called before loading all the data,
//        Failure - Boolean - If the value of this
//          parameter is set to True in the Preload Type() procedure, all data objects corresponding to the Cur
//          metadata object will not be loaded.
//    Before loading the object - Boolean - flag of the need to call the handler before
//      loading the data object related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exported procedure for preloading an object() can be implemented
//      that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        The object is a constant value manager.* - A reference object.*, Document object.*,
//          Business ProcessObject.*, Taskobject.*, Account planobject.*, PlanObmenaObject.*,
//          The plan of the type of characteristicobject.*, A kind of calculation planobject.*, Register of Recordset entries.*,
//          The register of a set of records.*, Register of bookgalteryinabor records.*,
//          The register is calculated by the records.*, A sequence of a set of recordings.*, Recalculating a set of records.* -
//          the data object of the information database, before loading which the handler was called.
//          The value passed to the procedure before loading the object() as a parameter value
//          The object can be modified inside the handler procedure before loading the object().
//        Artifacts - An array Of ObjectXDTO - additional data, logically inextricably linked
//          with a data object, but not part of it. Generated in exported procedures
//          Before loading the object() of the data upload handlers (see the procedure comment
//          When registering the processed data(). Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//        Failure - Boolean - If the value of this
//          parameter is set to True in the procedure for preloading the object(), the data object will not be loaded.
//    After loading the object - Boolean - flag of the need to call the handler after
//      loading the data object related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exported procedure for post-loading an object() can be implemented
//      that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload of the data of the Container manager.
//        The object is a constant value manager.* - A reference object.*, Document object.*,
//          Business ProcessObject.*, Taskobject.*, Account planobject.*, PlanObmenaObject.*,
//          The Type plancharacteristicobject.*, A kind of calculation planobject.*, Register of Recordset entries.*,
//          The register of the recording set.*, Register of bookgalteriinabor records.*,
//          The register is calculated by the records.*, A sequence of a set of recordings.*, Recalculating a set of records.* -
//          the data object of the information database, after loading which the handler was called.
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          to the data object, but is not part of it. Generated in exported procedures
//          Before loading the object() of the data upload handlers (see the procedure comment
//          When registering the processed data(). Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//    After loading Type - Boolean - flag of the need to call the handler after
//      loading all data objects related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exportable post-loading Type() procedure can be implemented
//      that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata - after loading all the objects of which
//          the handler was called.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	ListOfSharedMetadataObjects = ExportImportCommonSeparatedDataCached.SharedMetadataObjects_();
	
	For Each KeyAndValue In ListOfSharedMetadataObjects Do
		
		For Each MetadataObjectName In KeyAndValue.Value.Constants Do
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportCommonSeparatedData;
			NewHandler.BeforeImportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndDo;
		
		For Each MetadataObjectName In KeyAndValue.Value.Objects Do
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportCommonSeparatedData;
			NewHandler.BeforeImportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndDo;
		
		For Each MetadataObjectName In KeyAndValue.Value.RecordSets Do
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportCommonSeparatedData;
			NewHandler.BeforeImportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	If CommonCTL.IsRecordSet(Object.Metadata()) Then
		If CommonCTL.IsIndependentRecordSet(Object.Metadata()) Then
			Object.Filter.DataAreaAuxiliaryData.Use = False;
		EndIf;
		For Each Record In Object Do
			Record.DataAreaAuxiliaryData = 0;
		EndDo;
	Else
		
		Object.DataAreaAuxiliaryData = 0;
		
	EndIf;
	
EndProcedure

#EndRegion
