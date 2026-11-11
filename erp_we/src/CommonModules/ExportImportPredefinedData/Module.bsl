#Region Internal

// Fills in an array of types that need to be annotated
// with links in the upload files when uploading.
//
// Parameters:
//  Types - Array of MetadataObject - metadata object. 
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	ObjectsWithPredefinedItems = ExportImportPredefinedDataCached.MetadataObjectsWithPredefinedElements();
	For Each TypeName In ObjectsWithPredefinedItems Do
		
		If ReferenceMappingToPredefinedElementsIsRequired(TypeName) Then
			Types.Add(Metadata.FindByFullName(TypeName));
		EndIf;
		
	EndDo;
	
EndProcedure

// Called when registering custom data upload handlers.
// In this procedure, you need to Supplement this table of values with information 
// about registered custom data upload handlers.
// 
// Parameters:
//	HandlersTable - ValueTable - Columns:
//	 * MetadataObject - MetadataObject - when uploading data, the registered handler should be called,
//	 * Handler - CommonModule - a General module that implements an arbitrary data upload handler. 
//	    The set of export procedures to be implemented in the handler depends on setting the values 
//	    of the following columns in the value table.
//	 * Version - String - version number of the data upload / download handler interface supported by the handler.
//	 * BeforeUnloadingType - Boolean - flag of the need to call the handler before unloading all information
//	    database objects related to this metadata object. If the value is set to True 
//	    , the exported Type Transfer procedure() must be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//          in the process of unloading data is the container manager. For more information, see the comments on the processing software interface. 
//        Serializer - XDTO serializer - initialized with support for link annotation. If 
//          additional data needs to be unloaded in an arbitrary upload handler, you should 
//          use the XDTO serializer passed to the Type() procedure before uploading as the parameter value. 
//          The serializer, not obtained using the global context property of the serializer XDTO.
//        Data objectmetadata - The data objectmetadata whose handler was called before the data was uploaded.
//        Failure - Boolean - if the value of this parameter is set to equal in the procedure before loading the type() 
//          True - objects corresponding to the Cur metadata object will not be uploaded.
//	 * BeforeExportObject - Boolean - flag for whether a handler should be called before uploading a specific 
//	    database object. If the value is set to True 
//	    , the exported procedure before loading the object() must be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//          in the process of unloading data is the container manager. For more information, see the comments on the processing software interface.
//        The manager of the loading object is the processing object.Unloading and unloading of data from the Information database -
//          manager for unloading the Cur object. For more information, see the comment on the processing software interface
//          Unloaded and unloaded data from the management and unloaded data from the information database. The parameter is passed only when calling
//          handler procedures for which a version at least 1.0.0.1 is specified during registration.
//        Serializer - SerializatorXDTO - initialized with support for link annotation. If 
//          you want to unload additional data in an arbitrary upload handler, you should 
//          use the XDTO serializer passed to the procedure before loading the object() as the value 
//          of the Serializer parameter, and not obtained using the global context property of the XDTO serializer.
//        Object - Value constantmanagement, Reference object, Document object, Business Process object, Task object, 
//          PlanChetovObject, PlanObmenaObject, PlanChetcHaracteristicObject, planchetavigationobject, 
//          Register of Record Collection, Register of Record collection, Register of bookgalteryinabor records,
//          The register of recordscountainment, recordset sequenceset, recordset recalculation is the data object 
//          of the information database that the handler was called before unloading. The value passed to the procedure 
//          Before loading the object() as a parameter value, the object can be modified inside the handler 
//          Before loading the object(), the changes made will be reflected in the object serialization in 
//          the upload files, but will not be recorded in the information database
//        Artifacts - An array Of ObjectXDTO - a set of additional information that is logically inextricably linked to the object,
//          but is not part of it (object artifacts). Artifacts must be generated inside the handler 
//          Before loading the object() and added to the array passed as the value of the Artifacts parameter. 
//          Each artifact must be an XDTO object, for the type of which an 
//          abstract XDTO type is used as the base type {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1 }Artefact. It is allowed to use 
//          XDTO packages, in addition to those originally supplied as part of the Unloading and Unloading data subsystem. In the future
//          , the artifacts generated in the procedure before loading the object() will be available in the procedures
//          of the data loading processors (see the comment on the procedure for registering the Data loading processors().
//        Failure - Boolean - if the value of this parameter is set to True in the procedure before loading the object() 
//        , the object for which the handler was called will not be unloaded.
//	 * AfterUnloadingType - Boolean - flag of the need to call the handler after unloading all objects of the information 
//	    base related to this metadata object. If the value is set to True 
//	    , the exported post-type() procedure should be implemented in the general handler module that supports the following parameters:
//        Container - Processing object.The container manager used 
//          in the process of unloading data is the container manager. For more information, see the comments to the processing software interface.
//        Serializer - XDTO serializer - initialized with support for link annotation. If 
//          additional data needs to be unloaded in an arbitrary upload handler, you should 
//          use the XDTO serializer passed to the post-upload Type() procedure as the parameter value. 
//          Serializer, not obtained using the global context property of the SerializatorXDTO,
//        Data objectmetadata - Data objectmetadata - after the data was uploaded, the handler was called.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	ObjectsWithPredefinedItems = ExportImportPredefinedDataCached.MetadataObjectsWithPredefinedElements();
	For Each MetadataObjectName In ObjectsWithPredefinedItems Do
		
		If ReferenceMappingToPredefinedElementsIsRequired(MetadataObjectName) Then
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportPredefinedData;
			NewHandler.AfterExportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	ObjectMetadata = Object.Metadata();
	If CommonCTL.IsRefDataSupportingPredefinedItems(Object.Metadata()) Then
		
		If ReferenceMappingToPredefinedElementsIsRequired(ObjectMetadata.FullName()) Then
			
			If Object.Predefined Then
				
				NaturalKey = New Structure("PredefinedDataName", Object.PredefinedDataName);
				ObjectExportManager.YouNeedToMatchLinkWhenDownloading(Object.Ref, NaturalKey);
				
			EndIf;
			
		Else
			
			Raise StrTemplate(
			NStr("vi = 'Hàm sự kiện
                  |%2không thể xử lý đối tượng metadata %1,
                  |bởi vì không cần đảm bảo so sánh tham chiếu đến các phần tử định trước của nó.';
                  |ru = 'Объект метаданных %1 не может быть обработан обработчиком
                  |%2,
                  |т.к. не требуется обеспечивать сопоставление ссылок на его предопределенные элементы.';
                  |en = 'The %1 metadata object cannot be processed by the handler
                  |%2
                  |as the mapping of references to its predefined items is not required.'; fa = 'The %1 metadata object cannot be processed by the handler
                  |%2
                  |as the mapping of references to its predefined items is not required.';
                  |it = 'Oggetto metadati %1 non può essere elaborato dal processore 
                  |%2,
                  | perché non è richiesto di fornire il confronto dei riferimenti ai suoi elementi predefiniti.';
                  |pl = 'Obiekt metadanych %1 nie może być przetworzony procedurą przetwarzania 
                  |%2,
                  |ponieważ nie jest wymagane zapewnienie linków na jego predefiniowane elementy.';
                  |tr = '%1 meta veri nesnesi
                  |%2 işleyicisi tarafından işlenemiyor
                  |çünkü önceden tanımlanmış öğelerine bağlantı eşleştirme sağlamak gerekli değildir.'", Metadata.DefaultLanguage.LanguageCode),
			ObjectMetadata.FullName(),
			"ExportImportPredefinedData.BeforeExportObject");
			
		EndIf;
		
	Else
		Raise StrTemplate(
			NStr("vi = 'Hàm sự kiện
                  |%2không thể xử lý đối tượng metadata %1,
                  |bởi vì không thể chứa phần tử định trước.';
                  |ru = 'Объект метаданных %1 не может быть обработан обработчиком
                  |%2,
                  |т.к. не может содержать предопределенных элементов.';
                  |en = 'The %1 metadata object cannot be processed by the handler
                  |%2
                  |as it cannot contain predefined items.'; fa = 'The %1 metadata object cannot be processed by the handler
                  |%2
                  |as it cannot contain predefined items.';
                  |it = 'Oggetto metadati %1 non può essere elaborato dal processore 
                  |%2,
                  | perché non può contenere elementi predefiniti.';
                  |pl = 'Obiekt metadanych %1 nie może być przetworzony procedurą przetwarzania 
                  |%2,
                  |ponieważ nie może zawierać predefiniowanych elementów.';
                  |tr = '%1 meta veri nesnesi
                  |%2 işleyicisi tarafından işlenemiyor
                  |çünkü önceden tanımlanmış öğeleri içeremez.'", Metadata.DefaultLanguage.LanguageCode),
			ObjectMetadata.FullName(),
			"ExportImportPredefinedData.BeforeExportObject");
		
	EndIf;
	
EndProcedure

// Parameters:
// 	HandlersTable - See ExportImportDataOverridable.OnRegisterDataImportHandlers.HandlersTable
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
		
	ObjectsWithPredefinedItems = ExportImportPredefinedDataCached.MetadataObjectsWithPredefinedElements();
	For Each MetadataObjectName In ObjectsWithPredefinedItems Do
		
		If ReferenceMappingToPredefinedElementsIsRequired(MetadataObjectName) Then
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportPredefinedData;
			NewHandler.BeforeMapRefs = True;
			NewHandler.BeforeImportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	Container - DataProcessorObject.ExportImportDataContainerManager - the Manager of the container.
// 	MetadataObject - MetadataObject - metadata object.
// 	SourceRefsTable - ValueTable - reference table.
// 	StandardProcessing - Boolean - indicates standard processing.
// 	Cancel - Boolean - indicates that processing was refused.
Procedure BeforeMapRefs(Container, MetadataObject, SourceRefsTable, StandardProcessing, Cancel) Export
	
	If CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject)
			And SourceRefsTable.Columns.Find("PredefinedDataName") <> Undefined Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in 
//	 the data loading process. For more information, see the comment on the processing software interface.
//	RefsMapManager - DataProcessorObject.ExportImportDataReferenceMappingManager - 
//	SourceRefsTable - ValueTable - containing information about links downloaded from the original IS. Columns:
//	* SourceRef1 - AnyRef - reference of the source IB object that you want to map to the reference in the current IB,
//		The remaining columns are equal to the fields of the object's natural key.
// Returns:
//	ValueTable - Columns:
//	 * SourceRef1 - AnyRef -  object reference unloaded from the source information system,
//	 * Ref - AnyRef - the associated source link in the current is.
Function MapRefs(Container, RefsMapManager, SourceRefsTable) Export
	
	SourceLinksForStandardProcessing = New ValueTable();
	For Each Column In SourceRefsTable.Columns Do
		If Column.Name <> "PredefinedDataName" Then
			SourceLinksForStandardProcessing.Columns.Add(Column.Name, Column.ValueType);
		EndIf;
	EndDo;
	
	ColumnName = RefsMapManager.SourceLinkColumnName_();
	
	Result = New ValueTable();
	Result.Columns.Add(ColumnName, SourceRefsTable.Columns.Find(ColumnName).ValueType);
	Result.Columns.Add("Ref", SourceRefsTable.Columns.Find(ColumnName).ValueType);
	
	MetadataObject = Undefined;
	
	For Each SourceRefsTableRow In SourceRefsTable Do
		
		If ValueIsFilled(SourceRefsTableRow.PredefinedDataName) Then
			
			Query = New Query;
			Query.Text = 
				"SELECT
				|	Table.Ref AS Ref
				|FROM
				|	&RefsTable AS Table
				|WHERE
				|	Table.PredefinedDataName = &PredefinedDataName";
			Query.SetParameter("PredefinedDataName", SourceRefsTableRow.PredefinedDataName);
			MetadataObject = SourceRefsTableRow[ColumnName].Metadata(); // MetadataObject
			Query.Text = StrReplace(Query.Text, "&RefsTable", MetadataObject.FullName());
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				
				Selection = QueryResult.Select();
				
				If Selection.Count() = 1 Then
					
					Selection.Next();
					
					ResultString1 = Result.Add();
					ResultString1.Ref = Selection.Ref;
					ResultString1[ColumnName] = SourceRefsTableRow[ColumnName];
					
				Else
					
					Raise StrTemplate(
						NStr("vi = 'Đã tìm thấy các phần tử định trước trùng lặp %1 trong bảng %2.';
							|ru = 'Обнаружено дублирование предопределенных элементов %1 в таблице %2.';
							|en = 'Duplicate predefined items %1 are found in table %2.'; fa = 'Duplicate predefined items %1 are found in table %2.';
							|it = 'Rilevata duplicazione degli elementi predefiniti %1 nella tabella%2.';
							|pl = 'Wykryto dublowanie predefiniowanych elementów %1 w tabeli %2.';
							|tr = 'Önceden tanımlanmış %1 öğelerinin %2 tablosunda tekrarlananları bulundu.'", Metadata.DefaultLanguage.LanguageCode),
						SourceRefsTableRow.PredefinedDataName,
						MetadataObject.FullName());
					
				EndIf;
				
			EndIf;
			
		Else
			
			If MetadataObject = Undefined Then
				MetadataObject = SourceRefsTableRow[ColumnName].Metadata();
			EndIf;
			
			ReferenceForStandardProcessing = SourceLinksForStandardProcessing.Add();
			FillPropertyValues(ReferenceForStandardProcessing, SourceRefsTableRow);
			
		EndIf;
		
	EndDo;
	
	If SourceLinksForStandardProcessing.Count() > 0 Then
		
		Selection = DataProcessors.ExportImportDataReferenceMappingManager.FetchingLinkMatching(
			MetadataObject, SourceLinksForStandardProcessing, ColumnName);
		
		While Selection.Next() Do
			
			ResultString1 = Result.Add();
			ResultString1.Ref = Selection.Ref;
			ResultString1[ColumnName] = Selection[ColumnName];
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	MetadataObject = Object.Metadata(); // MetadataObject
	
	If Not CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject) Then
		
		Raise StrTemplate(
			NStr("vi = 'Hàm sự kiện
                  |%2không thể xử lý đối tượng metadata %1,
                  |bởi vì không thể chứa phần tử định trước.';
                  |ru = 'Объект метаданных %1 не может быть обработан обработчиком
                  |%2,
                  |т.к. не может содержать предопределенных элементов.';
                  |en = 'The %1 metadata object cannot be processed by the handler
                  |%2
                  |as it cannot contain predefined items.'; fa = 'The %1 metadata object cannot be processed by the handler
                  |%2
                  |as it cannot contain predefined items.';
                  |it = 'Oggetto metadati %1 non può essere elaborato dal processore 
                  |%2,
                  | perché non può contenere elementi predefiniti.';
                  |pl = 'Obiekt metadanych %1 nie może być przetworzony procedurą przetwarzania 
                  |%2,
                  |ponieważ nie może zawierać predefiniowanych elementów.';
                  |tr = '%1 meta veri nesnesi
                  |%2 işleyicisi tarafından işlenemiyor
                  |çünkü önceden tanımlanmış öğeleri içeremez.'", Metadata.DefaultLanguage.LanguageCode),
			MetadataObject.FullName(),
			"ExportImportPredefinedData.BeforeImportObject");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ReferenceMappingToPredefinedElementsIsRequired(TypeName)
	
	If SaaSOperations.IsSeparatedMetadataObject(TypeName, SaaSOperations.MainDataSeparator())
		Or SaaSOperations.IsSeparatedMetadataObject(TypeName, SaaSOperations.AuxiliaryDataSeparator()) Then
		
		Return False;
			
	Else
		
		// For undivided objects, reference mapping to predefined elements is always required.
		Return True;
		
	EndIf;
	
EndFunction

#EndRegion