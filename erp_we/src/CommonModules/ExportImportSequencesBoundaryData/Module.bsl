////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
// 
// The procedures and functions of this module allow you to unload and load
// sequence boundaries.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called when registering custom data upload handlers.
// in this procedure, you need to add information about registered custom
// data upload handlers to the handler table.
//
// Parameters:
//	HandlersTable - ValueTable - LongDesc:
//	 * MetadataObject - MetadataObject - when uploading data, the registered handler should be called,
//   * Handler - CommonModule - a General module that implements an arbitrary data upload handler. 
//      The set of export procedures to be implemented in the handler depends on setting the values
//      of the following columns in the value table.
//   * Version - String - version number of the data upload / download handler interface supported by the handler.
//   * BeforeUnloadingType - Boolean - flag of the need to call the handler before unloading all information
//      database objects related to this metadata object. If the value is set to True
//      , the exported procedure before loading Type() must be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//          in the process of unloading data is the container data manager. For more information, see the comments on the processing software interface.
//        Serializer - XDTO serializer - initialized with support for link annotation.
//          If additional data needs to be unloaded in an arbitrary upload handler 
//          , you should use the XDTO serializer passed to the Type() procedure before loading as
//          the value of the Serializer parameter, and not obtained using the global context property of the XDTO serializer.
//        Data objectmetadata - The data objectmetadata whose handler was called before the data was uploaded
//        Failure - Boolean - If the value of this parameter is set to equal in the procedure before loading the type() 
//          True - objects corresponding to the Cur metadata object will not be uploaded.
//   * BeforeExportObject - Boolean - flag for whether a handler should be called before uploading a specific 
//      database object. If the value is set to True 
//      , the exported procedure before loading the object() must be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//          in the process of unloading data is the container manager. For more information, see the comments on the processing software interface.
//        The manager of the loading object is the processing object.Unloading and unloading of data from the Information database -
//          manager for unloading the Cur object. For more information, see the comment on the processing software interface
//          Unloaded and unloaded data from the management and unloaded data from the information database. The parameter is passed only when calling
//          handler procedures for which a version at least 1.0.0.1 is specified during registration,
//        Serializer - XDTO serializer - initialized with support for link annotation. If 
//          additional data needs to be unloaded in an arbitrary upload handler, you should 
//          use the XDTO serializer passed to the procedure before loading the object() as the parameter value. 
//          Serializer, not obtained using the global context property of the SerializatorXDTO,
//        Object - Value constantmanagement, Reference object, Document object, Business Process object, Task object, 
//                 PlanChetovObject, PlanObmenaObject, PlanChetcHaracteristicObject, planchetavigationobject, 
//                 Register of Record Collection, Register of Record collection, Register of bookgalteryinabor records,
//                 The register of the record setcountainment, the sequence of the record set, the recalculation of the record set - the data object
//                 of the information database, before unloading which the handler was called.
//          The value passed to the Object Transfer procedure() as the value of the Object parameter can be
//          modified inside the Object Transfer handler(), and the changes made will be reflected
//          in the object serialization in the upload files, but will not be recorded in the information database.
//        Artifacts - An array Of ObjectXDTO - a set of additional information that is logically inextricably linked to the object,
//          but is not part of it (object artifacts). Artifacts must be generated inside the handler 
//          Before loading the object() and added to the array passed as the value of the Artifacts parameter. 
//          Each artifact must be an XDTO object, for the type of which an 
//          abstract XDTO type is used as the base type {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1 }Artefact. It is allowed to use 
//          XDTO-packages, in addition to those originally supplied as part of the Unloading and Unloading data subsystem. In the future
//          , the artifacts generated in the procedure before loading the object() will be available in the procedures
//          of the data loading processors (see the comment on the procedure for registering the Data loading processors().
//        Failure - Boolean - if the value of this parameter is set to equal in the procedure before loading the object() 
//           True - the object for which the handler was called will not be unloaded.
//   * AfterUnloadingType - Boolean - flag of the need to call the handler after unloading all objects of the information
//      base related to this metadata object. If the value is set to True 
//      , the exported post-type() procedure should be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//          in the process of unloading data is the container manager. For more information, see the comments to the processing software interface.
//        Serializer - XDTO serializer - initialized with support for link annotation. If 
//          additional data needs to be unloaded in an arbitrary upload handler, you should 
//          use the XDTO serializer passed to the post-upload Type() procedure as the parameter value.
//          Serializer, not obtained using the global context property of the SerializatorXDTO,
//        Data objectmetadata - Data objectmetadata - after the data was uploaded, the handler was called.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	For Each Sequence In Metadata.Sequences Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Sequence;
		NewHandler.Handler = ExportImportSequencesBoundaryData;
		NewHandler.BeforeUnloadingType = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
EndProcedure

// Handler for the event before unloading the type.
// 
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager
//	Serializer - XDTOSerializer
//	MetadataObject - MetadataObject
//	Cancel - Boolean
//
Procedure BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel) Export
	
	If CommonCTL.IsSequenceRecordSet(MetadataObject) Then
		
		Filter     = New Array;
		State = Undefined;
		
		While True Do
			
			ArrayOfTables = CloudTechnologyInternalQueries.GetChunkOfDataFromIndependentRecordset(
				MetadataObject, Filter, 10000, False, State, ".Boundaries"); // @query-part-1
			If ArrayOfTables.Count() <> 0 Then
				
				FirstTable = ArrayOfTables.Get(0); // ValueTable
				
				RecordsCount = FirstTable.Count();
				
				FileName = Container.CreateFile(ExportImportDataInternal.SequenceBoundary(), MetadataObject.FullName());
				ExportImportData.WriteObjectToFile(FirstTable, FileName);
				Container.SetNumberOfObjects(FileName, RecordsCount);
				Container.FileRecorded(FileName);
				
				Continue;
				
			EndIf;
			
			Break;
		
		EndDo;
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Hàm sự kiện %2 không thể xử lý đối tượng metadata %1';
								|ru = 'Объект метаданных %1 не может быть обработан обработчиком %2';
								|en = 'The %2 handler cannot process the %1 metadata object'; fa = 'The %2 handler cannot process the %1 metadata object';
								|it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore %2';
								|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania %2';
								|tr = '%1 meta veri nesnesi %2 işleyicisi tarafından işlenemez'"),
			MetadataObject.FullName(),
			"ExportImportSequencesBoundaryData.BeforeExportObject");
		
	EndIf;
	
EndProcedure

// Called when registering arbitrary data loading handlers.
// In this procedure, you need to supplement the table of values with information about the registered 
// arbitrary data loading handlers. 
//
// Parameters:
//  HandlersTable - ValueTable - Columns:
//		* MetadataObject - MetadataObject - when loading the data of which the registered handler should be called
//    	* Handler - CommonModule - a general module that implements an arbitrary
//       	data loading handler. A set of export procedures that should
//       	to be implemented in the handler, depends on setting the values of the following
//       	columns of the value table.
//    	* Version - String - the version number of the data upload / download handler interface
//       	supported by the handler.
//    	* BeforeMapRefs - Boolean - flag of the need to call a handler before
//       	matching links (in the original IS and in the Cur) related to this
//       	metadata object. If the value is set to True, the common handler module should
//       	an exportable procedure must be implemented before the links are supplied(),
//       	which supports the following parameters:
//        		Container - Processing object.The
//          		container manager used in the data upload process is the container manager. For more information, see the comment
//          		on the program interface for processing the offload data of the Container manager.
//        		Data objectmetadata - Data objectmetadata -
//          		the handler was called before matching the references of which,
//        		Standard Processing - Boolean - If the procedure is
//          		set to False before providing links(), instead of the standard
//          		link matching (searching for objects in the Cur IS with the same
//          		natural key values that were unloaded from the IS source)
//          		, the function Match Links() of the general module will be called in the procedure
//          		Before the delivery of the links() whose value is the parameter Standardprocessing
//          		it was set equal to False.
//          		Parameters of the Match Links() function:
//            			Container - Processing object.The
//              			container manager used in the data upload process is the container manager. For more information, see the comment
//              			to the program interface for processing the uploadingmediagercontainer,
//            			the table of outgoing links - the table of assignments - containing information about links
//              			unloaded from the source information system. Columns:
//                		Source link - Any link is a link of the object of the original information security, which you want
//                  		to match with the link in the Cur information security,
//                	The remaining columns are equal to the fields of the object's natural key, which
//                  were passed to the function during the data upload process
//                  Processing.Unloaded and unloaded data from the management and unloaded data from the information database.It is required to provide a link to the Download()
//          The return value of the function Match Links() - Value tables, columns:
//            Source link - Any link is a link of an object unloaded from the source information system,
//            Link - Any link - a mapped source link in the Cur IS.
//        	Failure - Boolean - if the value
//          	of this parameter is set to True in the procedure before the provision of links(), the mapping of links corresponding
//          	to the Cur metadata object will not be performed.
//		* BeforeImportType - Boolean - flag for calling the handler before
//       	loading all data objects related to this
//       	metadata object. If the value is set to True, the common handler module must
//       	an exportable Preload Type procedure() can be implemented
//       	that supports the following parameters:
//        		Container - Processing object.The
//          		container manager used in the data upload process is the container manager. For more information, see the comment
//          		on the program interface for processing the offload data of the Container manager.
//        		Data objectmetadata - The data objectmetadata whose
//          		handler was called before loading all the data,
//        		Failure - Boolean - if the value of this
//          		parameter is set to True in the Preload Type() procedure, all data objects corresponding to the Cur
//          		metadata object will not be loaded.
//		* BeforeImportObject - Boolean - flag for calling a handler before
//       	loading a data object related to this
//       	metadata object. If the value is set to True, the common handler module must
//       	an exported procedure for preloading an object() can be implemented
//       	that supports the following parameters:
//        		Container - Processing object.The
//          		container manager used in the data upload process is the container manager. For more information, see the comment
//          		on the program interface for processing the offload data of the Container manager.
//        		Object - Value constantmanagement, Directory object, Document object,
//          		Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          		Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          		Register of Records Collection, Register of bookgalteryinabor records,
//          		The register of the record setcountainment, the sequence of the record set, the recalculation of the record set -
//          		the data object of the information database, before loading which the handler was called.
//          		The value passed to the procedure before loading the object() as a parameter value
//          		The object can be modified inside the handler procedure before loading the object().
//        		Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          		to the data object, but is not part of it. Generated in exported procedures
//          		Before loading the object() of the data upload handlers (see the procedure comment
//          		When registering the processed data(). Each artifact must be an XDTO object,
//          		for the type of which an abstract XDTO type is used as the base type
//          		{http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          		in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//        		Failure - Boolean - if the value of this
//          		parameter is set to True in the procedure for preloading the object(), the data object will not be loaded.
//		* AfterImportObject - Boolean - flag for whether a handler should be called after
//       	loading a data object related to this
//       	metadata object. If the value is set to True, the common handler module must
//       	an exported procedure for post-loading an object() can be implemented
//       	that supports the following parameters:
//        		Container - Processing object.The
//          		container manager used in the data upload process is the container manager. For more information, see the comment
//          		on the program interface for processing the offload data of the Container manager.
//        		Object - Value constantmanagement, Directory object, Document object,
//          		Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          		Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          		Register of Records Collection, Register of bookgalteryinabor records,
//          		Register of recordscountainment, sequence of recordscountainment, Recalculation of recordscountainment -
//          		the data object of the information database, after loading which the handler was called.
//        		Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          		to the data object, but is not part of it. Generated in exported procedures
//          		Before loading the object() of the data upload handlers (see the procedure comment
//          		When registering the processed data(). Each artifact must be an XDTO object,
//          		for the type of which an abstract XDTO type is used as the base type
//          		{http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          		in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//		* AfterLoadingType - Boolean - flag for calling the handler after
//       	loading all data objects related to this
//       	metadata object. If the value is set to True, the common handler module must
//       	an exportable post-loading Type() procedure can be implemented
//       	that supports the following parameters:
//        		Container - Processing object.The
//          		container manager used in the data upload process is the container manager. For more information, see the comment
//          		on the program interface for processing the offload data of the Container manager.
//        		Data objectmetadata - Data objectmetadata - after loading all the objects of which
//          		the handler was called.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	For Each Sequence In Metadata.Sequences Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Sequence;
		NewHandler.Handler = ExportImportSequencesBoundaryData;
		NewHandler.AfterLoadingType = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
EndProcedure

// See ExportImportDataInternalEvents.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager
//	MetadataObject - MetadataObject
// 
Procedure AfterLoadingType(Container, MetadataObject) Export
	
	If CommonCTL.IsSequenceRecordSet(MetadataObject) Then
		
		SequenceManager = Common.ObjectManagerByFullName(
			MetadataObject.FullName()); // SequenceManagerSequenceName 
		
		BoundaryFiles = Container.GetFilesFromDirectory(
			ExportImportDataInternal.SequenceBoundary(), MetadataObject.FullName());
		
		For Each FileBoundaries In BoundaryFiles Do
			
			BorderTable = Container.ReadObjectFromFile(FileBoundaries);
			
			For Each TableRow In BorderTable Do 
				
				SequenceKey = GetSequenceKey(MetadataObject, TableRow);
				
				PointInTime = New PointInTime(TableRow.Period, TableRow.Recorder);
				SequenceManager.SetBound(PointInTime, SequenceKey);
				
			EndDo;
			
		EndDo;
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Hàm sự kiện %2 không thể xử lý đối tượng metadata %1';
								|ru = 'Объект метаданных %1 не может быть обработан обработчиком %2';
								|en = 'The %2 handler cannot process the %1 metadata object'; fa = 'The %2 handler cannot process the %1 metadata object';
								|it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore %2';
								|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania %2';
								|tr = '%1 meta veri nesnesi %2 işleyicisi tarafından işlenemez'"),
			MetadataObject.FullName(),
			"ExportImportSequencesBoundaryData.BeforeExportObject");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Generates a key for a sequence that consists of the composition of its dimensions.
//
// Parameters:
//	MetadataObject - MetadataObjectSequence - sequence metadata object.
//	TableRow - ValueTableRow - a string that stores records of sequence boundaries.
//
// Returns:
//	Structure - sequence key: Key is the name of the dimension, Value is the value of the dimension.
//
Function GetSequenceKey(Val MetadataObject, Val TableRow)
	
	SequenceKey = New Structure;
	
	For Each Field In MetadataObject.Dimensions Do
		SequenceKey.Insert(Field.Name, TableRow[Field.Name]);
	EndDo;
	
	Return SequenceKey;
	
EndFunction

#EndRegion