
#Region Internal

// Called when the registration of arbitrary handlers load the data.
//
// Parameters:
//   HandlersTable - ValueTable - In this procedure, it is required
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
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata -
//          the handler was called before matching the references of which,
//        Standard Processing - Boolean - If the procedure is
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
//                  were passed to the function during the data upload process
//                  Unloaded and unloaded data from the information database.It is required to provide a link to the Download()
//          The return value of the function Match Links() - Value tables, columns:
//            Source link - Any link is an object link unloaded from the source information system,
//            Link - Any link - a mapped source link in the Cur IS.
//        Failure - Boolean - if the value
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
//      metadata object. If the value is set to True, the common handler module should
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
//    After loading the object - Boolean - flag of the need to call the handler after
//      loading the data object related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exported procedure for post-loading an object() can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Object - Value constantmanagement, Directory object, Document object,
//          Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          Type Characterization planobject, Type calculation planobject, Record setreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          The register of the set of records, the sequence of the set of records, the recalculation of the set of records -
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
//      metadata object. If the value is set to True, the common handler module should
//      an exportable post-loading Type() procedure can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata - after loading all the objects of which
//          the handler was called.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportSharedPredefinedData;
	NewHandler.BeforeImportData = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

// Parameters:
// 	Container - DataProcessorObject.ExportImportDataContainerManager - the Manager of the container.
Procedure BeforeImportData(Container) Export
	
	If Not Common.DataSeparationEnabled() Then
		
		FileName = Container.GetCustomFile(DataTypeForTableOfAdditionallyUnloadedData());
		NamesOfAdditionallyLoadedFiles = ExportImportData.ReadObjectFromFile(FileName);
		DeleteFiles(FileName);
		
		ImportParameters = New Structure(Container.ImportParameters()); // See ExportImportData.DownloadCurAreaDataFromArchive.ImportParameters
		
		For Each NameOfObjectToLoadAdditionally In NamesOfAdditionallyLoadedFiles Do
			ImportParameters.LoadableTypes.Add(Metadata.FindByFullName(NameOfObjectToLoadAdditionally));
		EndDo;
		
		Container.SetDownloadParameters(ImportParameters);
		
	EndIf;
	
EndProcedure

#Region InternalEventsHandlers

// Called when registering custom data upload handlers.
//
// Parameters:
//   HandlersTable - ValueTable - In this procedure, it is required
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
//      metadata object. If the value is set to True, the common handler module must
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
//        Failure - Boolean - if the value
//          of this parameter is set to True in the procedure before loading the type(), the objects corresponding
//          to the Cur metadata object will not be unloaded.
//    Before loading an object - Boolean flag of the need to call a handler before
//      unloading a specific object of the information base. If the value is assigned
//      True - the exported procedure must be implemented in the general handler module
//      Before loading an object() that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the process of unloading data is the container data manager. For more information, see the comment
//          on the program interface for processing the offload and offload data of the Container manager,
//        The manager of the loading object is the processing object.Unloading and unloading of data from the Information database -
//          manager for unloading the Cur object. For more information, see the comment on the processing software interface
//          Unloaded and unloaded data from the management and unloaded data from the information database. The parameter is passed only when calling
//          handler procedures for which a version at least 1.0.0.1 is specified during registration,
//        Serializer - XDTO serializer - initialized with support for
//          link annotation. If you need
//          to upload additional data in an arbitrary upload handler, use
//          SerializatorXDTO, passed to the procedure before loading the object() as
//          the value of the Serializer parameter, and not obtained using the global
//          context property of the SerializatorXDTO,
//        Object - Value constantmanagement, Directory object, Document object,
//          Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          The register of
//          the record setcounts, the sequence of the record set, the recalculation of the record set is the data object of the information database, before unloading which the handler was called.
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
//        Failure - Boolean - if the value
//           of this parameter is set to True in the procedure before loading the object(), the object for which the handler was called
//           will not be unloaded.
//    After unloading the type - Boolean - flag of the need to call the handler after unloading all
//      information base objects related to this metadata object. If the value is assigned
//      True - the exported procedure must be implemented in the general handler module
//      Post-loading type() that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the process of unloading data is the container data manager. For more information, see the comment
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
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportSharedPredefinedData;
	NewHandler.BeforeExportData = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

Procedure BeforeExportData(Container) Export
	
	ExportingParameters = New Structure(Container.ExportingParameters());
	
	AdditionallyUnloaded = New Array();
	
	ControlRules = ExportImportSharedDataCached.ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading();
	
	For Each ControlRule In ControlRules Do
		
		MetadataObject = Metadata.FindByFullName(ControlRule.Key);
		
		If ExportingParameters.TypesToExport.Find(MetadataObject) <> Undefined Then
			
			For Each FieldName In ControlRule.Value Do
				
				FieldNameStructure = StrSplit(FieldName, ".");
				
				If CommonCTL.IsConstant(MetadataObject) Then
					
					FieldSubstring = "Value";
					TableSubstring = MetadataObject.FullName();
					
				ElsIf CommonCTL.IsRefData(MetadataObject) Then
					
					If FieldNameStructure[2] = "Attribute" Or FieldNameStructure[2] = "Attribute" Then // Not localized
						
						FieldSubstring = FieldNameStructure[3];
						TableSubstring = MetadataObject.FullName();
						
					ElsIf FieldNameStructure[2] = "TabularSection" Or FieldNameStructure[2] = "TabularSection" Then // Not localized
						
						TabularSectionName = FieldNameStructure[3];
						
						If FieldNameStructure[4] = "Attribute" Or FieldNameStructure[4] = "Attribute" Then // Not localized
							
							FieldSubstring = FieldNameStructure[5];
							TableSubstring = MetadataObject.FullName() + "." + TabularSectionName;
							
						Else
							
							RaiseExceptionFailedToDefineField(FieldName, MetadataObject.FullName());
							
						EndIf;
						
					Else
						
						RaiseExceptionFailedToDefineField(FieldName, MetadataObject.FullName());
						
					EndIf;
					
				ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
					
					If FieldNameStructure[2] = "Dimension" Or FieldNameStructure[2] = "Dimension"
							Or FieldNameStructure[2] = "Resource" Or FieldNameStructure[2] = "Resource"
							Or FieldNameStructure[2] = "Attribute" Or FieldNameStructure[2] = "Attribute" Then // Not localized
						
						FieldSubstring = FieldNameStructure[3];
						TableSubstring = MetadataObject.FullName();
						
					Else
						
						RaiseExceptionFailedToDefineField(FieldName, MetadataObject.FullName());
						
					EndIf;
					
				Else
					
					Raise StrTemplate(NStr("vi = 'Đối tượng metadata %1 không được hỗ trợ';
											|ru = 'Объект метаданных %1 не поддерживается';
											|en = 'Metadata object %1 is not supported'; fa = 'Metadata object %1 is not supported';
											|it = 'Oggetto metadati %1 non supportato';
											|pl = 'Obiekt metadanych %1 nie jest obsługiwany';
											|tr = '%1 metaveri nesnesi desteklenmiyor'"), 
						MetadataObject.FullName());
					
				EndIf;
				
				PossibleFieldTypes = Metadata.FindByFullName(FieldName).Type.Types();
				CheckedFieldTypes = New Array();
				For Each PossibleFieldType In PossibleFieldTypes Do
					
					ObjectOfPossibleType = Metadata.FindByType(PossibleFieldType);
					
					If ObjectOfPossibleType = Undefined Then
						// primitive type
						Continue;
					EndIf;
					
					If ExportingParameters.TypesToExport.Find(ObjectOfPossibleType) <> Undefined Then
						// The object is initially included in the composition of the unloaded types
						Continue;
					EndIf;
					
					If AdditionallyUnloaded.Find(ObjectOfPossibleType) <> Undefined Then
						// The object has already been added to the list of additionally unloaded
						Continue;
					EndIf;
					
					If Not CommonCTL.IsRefDataSupportingPredefinedItems(
						ObjectOfPossibleType) Then
						// An object cannot contain predefined elements
						Continue;
					EndIf;
					
					CheckedFieldTypes.Add(PossibleFieldType);
					
				EndDo;
				
				If CheckedFieldTypes.Count() = 0 Then
					Continue;
				EndIf;
				
				QueryText = "";
				QueryTextTemplate2 =
				"SELECT TOP 1
				|	VALUETYPE(&FieldName) AS Type
				|FROM
				|	&Table AS T
				|		INNER JOIN &TabPredefined AS TPredefined
				|		ON &FieldName = TPredefined.Ref
				|			AND (TPredefined.Predefined)";
				
				For Each FieldTypeToCheck In CheckedFieldTypes Do
					
					If Not IsBlankString(QueryText) Then
						
						QueryText = QueryText + Chars.LF + "UNION ALL" + Chars.LF;
						
					EndIf;
					
					QueryText = QueryText + QueryTextTemplate2;
					QueryText = StrReplace(QueryText, "&Table", TableSubstring);
					QueryText = StrReplace(QueryText, "&TabPredefined", 
						Metadata.FindByType(FieldTypeToCheck).FullName());
					QueryText = StrReplace(QueryText, "&FieldName", "T." + FieldSubstring);
					
				EndDo;
				
				Query = New Query(QueryText);
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					
					AdditionalMetadataObject = Metadata.FindByType(Selection.Type);
					If AdditionalMetadataObject <> Undefined Then
						AdditionallyUnloaded.Add(AdditionalMetadataObject);
					EndIf;
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	UnloadedTypesOfSharedData = New Array(ExportingParameters.UnloadedTypesOfSharedData);
	CommonClientServer.SupplementArray(UnloadedTypesOfSharedData, AdditionallyUnloaded, True);
	ExportingParameters.UnloadedTypesOfSharedData = New FixedArray(UnloadedTypesOfSharedData);
	
	Container.SetUploadParameters(ExportingParameters);
	
	NamesOfAdditionalUnloads = New Array();
	For Each AdditionallyUnloadedObject In AdditionallyUnloaded Do
		NamesOfAdditionalUnloads.Add(AdditionallyUnloadedObject.FullName());
	EndDo;
	
	FileName = Container.CreateCustomFile("xml", DataTypeForTableOfAdditionallyUnloadedData());
	ExportImportData.WriteObjectToFile(NamesOfAdditionalUnloads, FileName);
	Container.FileRecorded(FileName);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function DataTypeForTableOfAdditionallyUnloadedData()
	
	Return "1cfresh\UnseparatedPredefined\AdditionalObjects";
	
EndFunction

Procedure RaiseExceptionFailedToDefineField(Val FieldName, Val ObjectName)
	
	Raise StrTemplate(NStr("vi = 'Không thể tạo truy vấn nhận giá trị trường %1 của đối tượng metadata %2';
							|ru = 'Не удалось построить запрос получения значения поля %1 объекта метаданных %2';
							|en = 'Cannot build request to get the %1 field value of the %2 metadata object'; fa = 'Cannot build request to get the %1 field value of the %2 metadata object';
							|it = 'Non è stato possibile creare la richiesta per ottenere il valore del campo %1 dell''oggetto metadati %2';
							|pl = 'Nie udało się utworzyć zapytania otrzymania pola %1 obiektu metadanych %2';
							|tr = '%2 meta veri nesnesinin %1 alan değerini almak için sorgu oluşturulamadı'"),
		FieldName, ObjectName);
	
EndProcedure

#EndRegion