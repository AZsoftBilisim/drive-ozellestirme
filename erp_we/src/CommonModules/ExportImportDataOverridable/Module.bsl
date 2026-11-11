///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Unloading of data is undefined: processing of data unloading and loading events in the area.
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Fills in an array of types that need to be annotated
// with links in the upload files when uploading.
//
// Parameters:
//  Types - Array of MetadataObject - array of object Metadata types.
//
//@skip-warning IsEmpty Method
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
EndProcedure

// Fills in an array of undivided data types that support link matching
// when uploading data to another information database.
//
// Parameters:
//  Types - Array of MetadataObject - array of object Metadata types.
//
//@skip-warning IsEmpty Method
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	ExportImportDataLocalization.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	
	//++ WE
	Types.Add(Metadata.Catalogs.IntegrateWithBankFeeds);
	//-- WE
	
	BackdateJobQueue.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	MonthEndTransactionsServer.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	
EndProcedure

// Fills in an array of undivided data types that do not require link matching
// when loading data into another information database, because correct link matching
// is guaranteed using other mechanisms.
//
// Parameters:
//  Types - Array of MetadataObject - array of object Metadata types.
//
//@skip-warning IsEmpty Method
Procedure OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types) Export
	ExportImportDataLocalization.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
EndProcedure

// Fills in an array of types that are excluded from uploading and loading data.
//
// Parameters:
//  Types - Array of MetadataObject - array of object Metadata types.
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export	
	ExportImportDataLocalization.OnFillTypesExcludedFromExportImport(Types);
	
	Types.Add(Metadata.InformationRegisters.LotAccountingDataCache);
EndProcedure

// Called before uploading data.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used during
//   the data upload process. See the comment on the program interface for processing the offload data of the Container manager.
//
//@skip-warning IsEmpty Method
Procedure BeforeExportData(Container) Export
	
	ExportImportDataLocalization.BeforeExportData(Container);	
	
EndProcedure

// Called when registering custom data upload handlers. 
// In this procedure, you need to Supplement the handler table with information 
// about registered custom data upload handlers.
//
// Parameters:
//	HandlersTable - ValueTable - LongDesc:
//	 * MetadataObject - MetadataObject - when uploading data, the registered handler should be called
//	 * Handler - CommonModule - a General module that implements an arbitrary data upload handler. 
//		The set of export procedures to be implemented in the handler depends on setting the values 
//		of the following columns in the value table.
//	 * Version - String - version number of the data upload / download handler interface supported by the handler
//	 * BeforeUnloadingType - Boolean - flag of the need to call the handler before
//      	unloading all information database objects related to this
//      	metadata object. If the value is set to True, the common handler module should
//      	an exported procedure can be implemented before loading the type(),
//      	which supports the following parameters:
//        		Container - Processing object.The
//          		container manager used in the process of unloading data is the container manager. For more information, see the comment
//          		on the program interface for processing the offload and offload data of the Container manager,
//        		Serializer - XDTO serializer - initialized with support for
//          		link annotation. If you need
//          		to upload additional data in an arbitrary upload handler, use
//          	    SerializatorXDTO, passed to the procedure before loading the type() as
//          		the value of the Serializer parameter, and not obtained using the global
//          		context property of the SerializatorXDTO,
//        		Data objectmetadata - The data objectmetadata whose
//          		handler was called before the data was uploaded,
//        		Failure - Boolean - if the value
//          		of this parameter is set to True in the procedure before loading the type(), the objects corresponding
//          		to the Cur metadata object will not be unloaded.
//	 * BeforeExportObject - Boolean - flag for whether a handler should be called before
//      	uploading a specific database object. If the value is assigned
//      	True - the exported procedure must be implemented in the general handler module
//      	Before loading an object() that supports the following parameters:
//        		Container - Processing object.The
//          		container manager used in the process of unloading data is the container data manager. For more information, see the comment
//          		on the program interface for processing the offload and offload data of the Container manager,
//        		The manager of the loading object is the processing object.Unloading and unloading of data from the Information database -
//          		manager for unloading the Cur object. For more information, see the comment on the processing software interface
//          		Unloaded and unloaded data from the management and unloaded data from the information database. The parameter is passed only when calling
//          		handler procedures for which a version at least 1.0.0.1 is specified during registration,
//        		Serializer - XDTO serializer - initialized with support for
//          		link annotation. If you need
//          		to upload additional data in an arbitrary upload handler, use
//          	    SerializatorXDTO, passed to the procedure before loading the object() as
//          		the value of the Serializer parameter, and not obtained using the global
//          		context property of the SerializatorXDTO,
//        		Object - Value constantmanagement, Directory object, Document object,
//          		Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          		Type Characterization planobject, Type calculation planobject, Record setreferences,
//          		Register of Records Collection, Register of bookgalteryinabor records,
//          		The register of the record setcountainment, the sequence of the record set, the recalculation of the record set -
//          		the data object of the information database, before unloading which the handler was called.
//          		The value passed to the procedure before loading the object() as a parameter value
//          		The object can be modified inside the handler before loading the object(). In
//          		this case, the changes made will be reflected in the serialization of the object in the upload files, but
//          		will not be recorded in the information database
//        		Artifacts - An array Of ObjectXDTO - a set of additional information that is logically inextricably
//          		linked to the object, but is not part of it (object artifacts). Artifacts must
//          		be generated inside the handler before loading the object() and added to the array passed
//          		as the value of the Artifacts parameter. Each artifact must be an XDTO object,
//          		for the type of which an abstract XDTO type is used as the base type
//          		{http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          		in addition to those originally supplied as part of the Unloading and Unloading data subsystem. In the future
//          		, artifacts generated in the procedure before loading the object() will be available in the procedures
//          		of data loading handlers (see the comment on the procedure for registering data loading handlers.
//        		Failure - Boolean - if the value
//           		of this parameter is set to True in the procedure before loading the object(), the object for which the handler was called
//           		will not be unloaded.
//	 * AfterUnloadingType - Boolean - flag of the need to call the handler after unloading all
//      	information database objects related to this metadata object. If the value is assigned
//      	True - the exported procedure must be implemented in the general handler module
//      	Post-loading type() that supports the following parameters:
//        		Container - Processing object.The
//          		container manager used in the process of unloading data is the container data manager. For more information, see the comment
//          		on the program interface for processing the offload and offload data of the Container manager,
//        		Serializer - XDTO serializer - initialized with support for
//          		link annotation. If you need
//          		to upload additional data in an arbitrary upload handler, use
//          	    SerializatorXDTO, passed to the procedure after loading the type() as
//          		the value of the Serializer parameter, and not obtained using the global
//          		context property of the SerializatorXDTO,
//        		Data objectmetadata - Data objectmetadata - after the data was uploaded
//          		, the handler was called.
//
//@skip-warning IsEmpty Method
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
EndProcedure

// Called after data is uploaded.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used during
//   the data upload process. See the comment on the program interface for processing the offload data of the Container manager.
//
//@skip-warning IsEmpty Method
Procedure AfterExportData(Container) Export
	
	ExportImportDataLocalization.AfterExportData(Container);
	
EndProcedure

// Called before loading data.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used during 
//  data loading. See the comment to the program interface for processing the offload data of the Container manager.
//
//@skip-warning IsEmpty Method
Procedure BeforeImportData(Container) Export
	
	ExportImportDataLocalization.BeforeImportData(Container);
	
EndProcedure

// Called when the registration of arbitrary handlers load the data. 
// In this procedure, you need to Supplement this table of values with information 
// about registered custom data loading handlers.
//
// Parameters:
//  HandlersTable - ValueTable - LongDesc:
//	 * MetadataObject - MetadataObject - when loading data the registered handler should be called,
//	 * Handler - CommonModule - a General module that implements an arbitrary
//      data loading handler. The set of export procedures to
//      be implemented in the handler depends on setting the values of the following
//      columns in the value table,
//	 * Version - String - version number of the data upload / download handler interface supported by the handler.
//	 * BeforeMapRefs - Boolean - flag of the need to call a handler before
//      matching links (in the original IS and in the Cur) related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable procedure must be implemented before the links are supplied(),
//      which supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - The data objectmetadata whose handler was called before matching the references.
//        Standard processing - Boolean - if the procedure is
//          set to False before providing links(), instead of the standard
//          link matching (searching for objects in the Cur IS with the same
//          natural key values that were unloaded from the IS source)
//          , the function Match Links() of the general module will be called in the procedure
//          Before the delivery of the links() whose value is the parameter Standardprocessing
//          it was set equal to False.
//          Parameters of the Match Links() function:
//            Container - Processing object.The
//              container manager used in the data upload process is the container manager. For more information, see the comment
//              to the program interface for processing the uploadingmediagercontainer,
//            the table of outgoing links - the table of assignments - containing information about links
//              unloaded from the source information system. Columns:
//                Source link - Any link is a link of the object of the original information security, which you want
//                  to match with the link in the Cur information security,
//                The remaining columns are equal to the fields of the object's natural key, which
//                  were passed to the function during the data upload process.
//                  Processing.Unloaded and unloaded data from the management and unloaded data from the information database.It is required to provide a link to the Download()
//          The return value of the function Match Links() - tables of values, columns:
//            Source link - Any link is an object link unloaded from the source information system,
//            Link - Any link - a mapped source link in the Cur IS.
//        Failure - Boolean - if the value
//          of this parameter is set to True in the procedure before the provision of links(), the matching of links corresponding
//          to the Cur metadata object will not be performed.
//	 * BeforeImportType - Boolean - flag for calling the handler before
//      loading all data objects related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable Preload Type procedure() can be implemented
//      that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - The data objectmetadata whose
//          handler was called before loading all the data,
//        Failure - Boolean - if the value of this
//          parameter is set to True in the Preload Type() procedure, all data objects corresponding to the Cur
//          metadata object will not be loaded.
//	 * BeforeImportObject - Boolean - flag for calling a handler before
//      loading a data object related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exported procedure for preloading an object() can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Object - Value constantmanagement, Directory object, Document object,
//          Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          The register of the record setcountainment, the sequence of the record set, the recalculation of the record set -
//          the data object of the information database, before loading which the handler was called.
//          The value passed to the procedure before loading the object() as a parameter value
//          The object can be modified inside the handler procedure before loading the object().
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          to the data object, but is not part of it. Generated in exported procedures
//          Before loading the object() of the data upload handlers (see the procedure comment
//          When registering the processed data(). Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//        Failure - Boolean - if the value of this
//          parameter is set to True in the procedure for preloading the object(), the data object will not be loaded.
//	 * AfterImportObject - Boolean - flag for whether a handler should be called after
//      loading a data object related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exported procedure for post-loading an object() can be implemented
//      that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Object - Value constantmanagement, Directory object, Document object,
//          Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          The register of the set of records*, the sequence of the set of records, the recalculation of the set of records -
//          the data object of the information database, after loading which the handler was called.
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          to the data object, but is not part of it. Generated in exported procedures
//          Before loading the object() of the data upload handlers (see the procedure comment
//          When registering the processed data(). Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//	 * AfterLoadingType - Boolean - flag for calling the handler after
//      loading all data objects related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exportable post-loading Type() procedure can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata - after loading all the objects of which
//          the handler was called.
//
//@skip-warning IsEmpty Method
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	DataExchangeEvents.OnRegisterDataImportHandlers(HandlersTable);
	For Each SourceType In Metadata.EventSubscriptions.RegisterSourceDocumentData.Source.Types() Do
		HandlerRow = HandlersTable.Add();
		HandlerRow.MetadataObject      = Metadata.FindByType(SourceType);
		HandlerRow.Handler            = Common.CommonModule("TMDataExchange");
		HandlerRow.BeforeImportObject = True;
	EndDo;
	
	DataExchangeEvents.OnRegisterDataImportHandlers(HandlersTable);
EndProcedure

// Called after loading data.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used during
//   data loading. See the comment to the program interface for processing the offload data of the Container manager.
//
//@skip-warning IsEmpty Method
Procedure AfterImportData(Container) Export
	
	ExportImportDataLocalization.AfterImportData(Container);
	
EndProcedure

// Called before loading the database user.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - 
//    the container manager used in the data loading process. For more information, see the comment
//    on the software interface for handling the unloading of the Manager container,
//  Serialization - XDTODataObject - {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1} InfoBaseUser,
//    serialization of the database user,
//  IBUser - InfoBaseUser - deserialized from the discharge,
//  Cancel - Boolean - if you set the value of this parameter inside this procedure to
//    False, the user's download of the information database will be skipped.
//
//@skip-warning IsEmpty Method
Procedure OnImportInfobaseUser(Container, Serialization, IBUser, Cancel) Export
	
EndProcedure

// Called after the user loads the database.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - 
//    the container manager used in the data loading process. For more information, see the comment
//    on the software interface for handling the unloading of the Manager container,
//  Serialization - XDTODataObject - {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1} InfoBaseUser,
//    serialization of the database user,
//  IBUser - InfoBaseUser - deserialized from an upload.
//
//@skip-warning IsEmpty Method
Procedure AfterImportInfobaseUser(Container, Serialization, IBUser) Export
	
EndProcedure

// Called after loading all users of the information database.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - 
//    the container manager used in the data loading process. For more information, see the comment
//    on the software interface for processing the unloading of the data of the Manager container.
//
//@skip-warning IsEmpty Method
Procedure AfterImportInfobaseUsers(Container) Export
	
EndProcedure

// Fills in an array of metadata that is excluded from uploading in technical support mode.
// Links to excluded reference data will also be cleared
//
// Parameters:
//  Var_Metadata - Array - array of object Metadata types.
//
//@skip-warning IsEmpty Method
Procedure WhenFillingInMetadataExcludedFromUploadingInTechnicalSupportMode(Var_Metadata) Export
	
EndProcedure

#EndRegion