////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Based on types, when replacing the links.
// 
// Returns: 
//  FixedMap of KeyAndValue - Type Dependencies When Replacing References:
// * Key - String
// * Value - Array of String
Function TypeDependenciesWhenReplacingReferences() Export
	
	Return ExportImportSharedDataCached.DependenciesOfUnsharedMetadataObjects();
	
EndFunction

// The metadata object is separated by at least one separator.
// 
// Parameters: 
//	MetadataObject - MetadataObjectExchangePlan, MetadataObjectEnum - metadata object.
//	Cache - Map of KeyAndValue:
//	 * Key - String
//	 * Value - CommonAttributeContent
// 
// Returns: 
//	Boolean - The metadata object is separated by at least one separator.
Function MetadataObjectIsSeparatedByAtLeastOneSeparator(Val MetadataObject, Cache) Export
	
	Result = Cache.Get(MetadataObject);
	
	If Result <> Undefined Then
		Return Result;
	EndIf;
	
	If MetadataObject.ConfigurationExtension() <> Undefined And Not SaaSOperations.DataSeparationEnabled() Then
		// A custom metadata object when installing an extension in the service will always be considered split,
		// because the extension is installed with the scope - data separation
		Cache.Insert(MetadataObject, True);
		Return True;
	EndIf;
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			
			AutoUse = (CommonAttribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
			
			Content = Cache.Get(CommonAttribute.FullName());
			If Content = Undefined Then
				Content = CommonAttribute.Content;
				Cache.Insert(CommonAttribute.FullName(), Content);
			EndIf;
			
			CompositionItem = Content.Find(MetadataObject);
			If CompositionItem <> Undefined Then
				
				If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use
						Or (AutoUse And CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto) Then
					
					Cache.Insert(MetadataObject, True);
					Return True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Cache.Insert(MetadataObject, False);
	Return False;
	
EndFunction

#Region InternalEventsHandlers

// Fills in an array of types that need to be annotated
// with links in the upload files when uploading.
//
// Parameters:
//  Types - Array of MetadataObject - metadata object.
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	TypesOfSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	For Each TypeOfSharedData In TypesOfSharedData Do
		Types.Add(TypeOfSharedData);
	EndDo;
	
EndProcedure

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
//      to be implemented in the handler, depends on setting the values of the following
//      columns of the table of values,
//    Version - String - version number of the data upload/download handler interface
//      supported by the handler,
//    Before loading the type, a Boolean flag indicates whether the handler needs to be called before
//      unloading all information database objects related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exported procedure can be implemented before loading the type(),
//      which supports the following parameters:
//        Container - Processing object.The
//          container manager used in the process of unloading data is the container manager. For more information, see the comment
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
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of unloading data. For more information, see the comment
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
//          Type Characterization planobject, Type calculation planobject, Record setreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          The register of the record setcountainment, the sequence of the record set, the recalculation of the record set -
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
//        Failure - Boolean - if the value
//           of this parameter is set to True in the procedure before loading the object(), the object for which the handler was called
//           will not be unloaded.
//    After loading the type() - Boolean, flag for calling the handler after unloading all
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
	
	TypesOfSharedData
		= ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	
	For Each TypeOfSharedData In TypesOfSharedData Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = TypeOfSharedData;
		NewHandler.Handler = ExportImportSharedData;
		NewHandler.BeforeUnloadingType = True;
		NewHandler.AfterExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
	ObjectsForMonitoringUnsharedDataWhenUnloading
		= ExportImportSharedDataCached.ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading();
	
	For Each ObjectForMonitoringUnsharedDataDuringUpload In ObjectsForMonitoringUnsharedDataWhenUnloading Do
		
		MetadataObject = Metadata.FindByFullName(ObjectForMonitoringUnsharedDataDuringUpload.Key);
		
		If TypesOfSharedData.Find(MetadataObject) = Undefined Then // Otherwise, a handler is already registered for the object
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = MetadataObject;
			NewHandler.Handler = ExportImportSharedData;
			NewHandler.AfterExportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Called before unloading the data type.
// See OnRegisterDataExportHandlers.
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   Serializer - XDTOSerializer
//   MetadataObject - MetadataObject
//   Cancel - Boolean
//
Procedure BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel) Export
	
	If Not CommonCTL.IsRefData(MetadataObject) Then 
		Raise NStr("vi = 'Chỉ có thể thay thế tham chiếu trong dữ liệu tham chiếu';
					|ru = 'Замена ссылок доступна только в ссылочных данных';
					|en = 'References can be replaced only in the reference data'; fa = 'References can be replaced only in the reference data';
					|it = 'La sostituzione dei collegamenti è disponibile solo nei dati di riferimento.';
					|pl = 'Wymiana odnośników jest dostępna tylko w odnośnikowych danych';
					|tr = 'Bağlantı değiştirme sadece başvurulan verilerde mevcuttur'");
	EndIf;
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	NaturalKeyFields = ObjectManager.NaturalKeyFields();
	
	CheckNaturalKeyFields(MetadataObject, NaturalKeyFields);
	CheckForDuplicatesOfNaturalKeys(MetadataObject, NaturalKeyFields);
	
EndProcedure

// Called after unloading the data object. See the description of the registration of the processing of the uploaded data.
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - Manager of the data upload container.
//	ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager -
//	 Manager for uploading the current object.
//	Serializer - XDTOSerializer - initialized to support the implementation of the annotation links.
//	Object - ConstantValueManager, CatalogObject, DocumentObject, BusinessProcessObject, TaskObject - 
//		   - ChartOfAccountsObject, ExchangePlanObject, ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject -  
//		   - CalculationRegisterRecordSet, AccountingRegisterRecordSet, AccumulationRegisterRecordSet - 
//		   - InformationRegisterRecordSet - data object.
//	Artifacts - Array of XDTODataObject - set of additional information 
Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	MetadataObject = Object.Metadata();
	FullMetadataObjectName = MetadataObject.FullName();
	
	FieldsToControlReferencesToUnsharedData =
		ExportImportSharedDataCached.ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading().Get(
			FullMetadataObjectName);
	
	If FieldsToControlReferencesToUnsharedData <> Undefined Then
		ControlOfReferencesToUnsharedDataDuringUnloading(Container, Object, FieldsToControlReferencesToUnsharedData);
	EndIf;
	
	If Container.AdditionalProperties.GeneralDataRequiringLinkMatching.Find(MetadataObject) <> Undefined Then
		
		If Not CommonCTL.IsRefData(MetadataObject) Then 
			Raise NStr("vi = 'Chỉ có thể thay thế tham chiếu trong dữ liệu tham chiếu';
						|ru = 'Подмена ссылок доступна только в ссылочных данных';
						|en = 'Reference substitution is only available for reference data'; fa = 'Reference substitution is only available for reference data';
						|it = 'La sostituzione dei collegamenti è disponibile solo nei dati di riferimento.';
						|pl = 'Podstawienie odnośników dostępu w odnośnikowych danych';
						|tr = 'Bağlantı ikamesi sadece başvurulan verilerde mevcuttur'");
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(FullMetadataObjectName);
		
		NaturalKeyFields = ObjectManager.NaturalKeyFields();
		
		NaturalKey = New Structure();
		For Each NaturalKeyField In NaturalKeyFields Do
			NaturalKey.Insert(NaturalKeyField, Object[NaturalKeyField]);
		EndDo;
		
		ObjectExportManager.YouNeedToMatchLinkWhenDownloading(Object.Ref, NaturalKey);
		
	EndIf;
	
EndProcedure

Procedure ControlUseOfReferencesToUnsharedDataInPartitioned() Export
	
	Try
		
		ExportImportSharedDataCached.ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading();
		
	Except
		
		ErrorText = CloudTechnology.ShortErrorText(ErrorInfo());
		Raise StrTemplate(NStr("vi = 'Đã phát hiện lỗi trong cấu trúc metadata cấu hình: %1';
								|ru = 'Обнаружены ошибки в структуре метаданных конфигурации: %1';
								|en = 'Errors found in the structure of metadata configuration: %1'; fa = 'Errors found in the structure of metadata configuration: %1';
								|it = 'Sono stati rilevati degli errori nella struttura della configurazione dei metadati: %1';
								|pl = 'Są wykryte błędy w strukturze metadanych konfiguracji: %1';
								|tr = 'Meta veri yapılandırmasının yapısında bulunan hatalar: %1'", Metadata.DefaultLanguage.LanguageCode),
			ErrorText);
		
	EndTry;
	
EndProcedure

Procedure ControlFillingOfNaturalKeyFieldsForUnsharedObjects() Export
	
	Try
		
		ExportImportSharedDataCached.DependenciesOfUnsharedMetadataObjects();
		
	Except
		
		ErrorText = CloudTechnology.ShortErrorText(ErrorInfo());
		Raise StrTemplate(NStr("vi = 'Đã tìm thấy lỗi trong cấu trúc metadata cấu hình: %1';
								|ru = 'Обнаружены ошибки в структуре метаданных конфигурации: %1';
								|en = 'Errors found in the structure of metadata configuration: %1'; fa = 'Errors found in the structure of metadata configuration: %1';
								|it = 'Sono stati rilevati degli errori nella struttura della configurazione dei metadati: %1';
								|pl = 'Są wykryte błędy w strukturze metadanych konfiguracji: %1';
								|tr = 'Meta veri yapılandırmasının yapısında bulunan hatalar: %1'", Metadata.DefaultLanguage.LanguageCode),
			ErrorText);
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Checks for duplicates of natural keys of the objects.
//
// Parameters:
//	MetadataObject - MetadataObject - the metadata object to upload.
//	NaturalKeyFields - Array of String - array of strings that store the names of natural keys.
//
Procedure CheckForDuplicatesOfNaturalKeys(Val MetadataObject, Val NaturalKeyFields)
	
	TableName = MetadataObject.FullName();
	
	QueryText = StrReplace(
	"SELECT
	|	&SelectionFields1,
	|	MAX(_Table_OfCatalog_First.Ref) AS Ref,
	|	COUNT(*) AS Cnt
	|INTO TTDoubles
	|FROM
	|	&Table AS _Table_OfCatalog_First
	|
	|GROUP BY
	|	&GroupFields
	|
	|HAVING
	|	COUNT(*) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 5
	|	PRESENTATION(_Table_OfCatalog_First.Ref) AS ItemPresentation
	|FROM
	|	TTDoubles AS TTDoubles
	|		INNER JOIN &Table AS _Table_OfCatalog_First
	|		ON TTDoubles.Ref <> _Table_OfCatalog_First.Ref
	|		AND &AdditionalRequestText", "&Table", TableName);
	
	AdditionalRequestText = "";
	FieldSelectionText_ = "";
	
	For Each NaturalKeyField In NaturalKeyFields Do 
		
		FieldSelectionText_ = FieldSelectionText_ + StrTemplate("_Table_OfCatalog_First.%1, 
			|", NaturalKeyField);
		
		AdditionalRequestText = AdditionalRequestText
			+ StrTemplate("AND (_Table_OfCatalog_First.%1 = TTDoubles.%1) ", NaturalKeyField);
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "&SelectionFields1,", FieldSelectionText_);
	QueryText = StrReplace(
		QueryText, "&GroupFields", Mid(FieldSelectionText_, 1, StrLen(FieldSelectionText_) - 3));
	QueryText = StrReplace(
		QueryText, "AND &AdditionalRequestText", AdditionalRequestText);
	
	Query = New Query;
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	ItemsList = StrConcat(
		QueryResult.Unload().UnloadColumn("ItemPresentation"), Chars.LF);
	KeysNames = RepresentationOfNaturalKeyFields(MetadataObject, NaturalKeyFields);
	
	// Filling in the warning text
	MessageText = StrTemplate(NStr("vi = 'Trong một số đối tượng %1: 
		|%2
		|
		|có các trường trùng lặp:
		|%3.
		|
		|Nên xóa các phần tử trùng lặp.';
		|ru = 'У некоторых объектов %1: 
		|%2
		|
		|дублируются поля:
		|%3.
		|
		|Рекомендуется выполнить удаление дублирующихся элементов.';
		|en = 'Several objects %1:
		|%2
		|
		|have duplicate fields:
		|%3.
		|
		|We recommend that you delete duplicate items.'; fa = 'Several objects %1:
		|%2
		|
		|have duplicate fields:
		|%3.
		|
		|We recommend that you delete duplicate items.';
		|it = 'Per alcuni oggetti %1: 
		|%2
		|
		| vi sono duplicati dei campi:
		|%3.
		|
		| Si consiglia di eliminare gli elementi duplicati.';
		|pl = 'Niektóre pola %1: 
		|%2
		|
		|powtarzające się pola:
		|%3.
		|
		|Zalecane jest usunięcie powtarzających się elementów.';
		|tr = 'Bazı nesnelerde %1: 
		|%2
		|
		| alanlar tekrar ediyor:
		|%3.
		|
		|Tekrar eden öğelerin silinmesi tavsiye ediliyor.'"),
		TableName, ItemsList, KeysNames);
	
	Raise MessageText;
	
EndProcedure

// Checks for the presence of natural keys in the metadata object.
//
// Parameters:
//	MetadataObject - MetadataObject - the metadata object to upload.
//	NaturalKeyFields - Array of String - array of strings that store the names of natural keys.
//
Procedure CheckNaturalKeyFields(Val MetadataObject, Val NaturalKeyFields)
	
	If NaturalKeyFields = Undefined Or NaturalKeyFields.Count() = 0 Then
		
		Raise StrTemplate(NStr("vi = 'Đối với kiểu dữ liệu %1 chưa chỉ ra khóa tự nhiên để thay thế tham chiếu.
                  |Hãy kiểm tra hàm sự kiện %2.';
                  |ru = 'Для типа данных %1 не указаны естественные ключи для замены ссылок.
                  |Проверьте обработчик %2.';
                  |en = 'Natural keys for reference replacement are not specified for the %1 data type.
                  |Check the %2 handler.'; fa = 'Natural keys for reference replacement are not specified for the %1 data type.
                  |Check the %2 handler.';
                  |it = 'Per il tipo di dati %1 non sono indicate le chiavi naturali di sostituzione dei collegamenti. 
                  | Verificare gestore %2.';
                  |pl = 'Dla typu danych %1 są nie wskazane klucze naturalne dla wymiany odnośników. 
                  |Sprawdź procedurę przetwarzania %2.';
                  |tr = 'Bağlantıları değiştirmek için %1 veri türü için hiçbir doğal anahtar belirtilmedi.
                  |%2 işleyicisini kontrol edin.'"),
			MetadataObject.FullName(),
			"WhenDeterminingTypesThatRequireUploadingToLocalVersion");
		
	EndIf;
	
EndProcedure

Function RepresentationOfNaturalKeyFields(MetadataObject, NaturalKeyFields)
	
	FieldsPresentation = New Array();
	
	NamesOfPropertiesOfDetails = New Array();
	NamesOfPropertiesOfDetails.Add("StandardAttributes");
	
	If Not CommonCTL.IsEnum(MetadataObject) Then
		NamesOfPropertiesOfDetails.Add("Attributes");
	EndIf;
	
	If CommonCTL.IsTask(MetadataObject) Then
		NamesOfPropertiesOfDetails.Add("AddressingAttributes");
	EndIf;
	
	For Each NaturalKeyField In NaturalKeyFields Do
		
		AttributeSynonym = "";
		PropsFound = False;
		
		For Each PropertyName In NamesOfPropertiesOfDetails Do
			
			For Each AttributeObject In MetadataObject[PropertyName] Do
				
				If AttributeObject.Name = NaturalKeyField Then
					
					AttributeSynonym = AttributeObject.Synonym;
					PropsFound = True;
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If PropsFound Then
				Break;
			EndIf;
			
		EndDo;
		
		FieldPresentation = ?(IsBlankString(AttributeSynonym),
			NaturalKeyField,
			StrTemplate("%1 (%2)", AttributeSynonym, NaturalKeyField));
		FieldsPresentation.Add(FieldPresentation);
		
	EndDo;
	
	Return StrConcat(FieldsPresentation, Chars.LF);
	
EndFunction

Procedure ControlOfReferencesToUnsharedDataDuringUnloading(Container, Val Object, FieldsToControlReferencesToUnsharedData)
	
	MetadataObject = Object.Metadata();
	FullMetadataObjectName = MetadataObject.FullName();
	ObjectNameStructure = StrSplit(FullMetadataObjectName, ".");
	
	For Each FieldForControllingReferencesToUnsharedData In FieldsToControlReferencesToUnsharedData Do
		
		FieldNameStructure = StrSplit(FieldForControllingReferencesToUnsharedData, ".");
		
		If ObjectNameStructure[0] <> FieldNameStructure[0] Or ObjectNameStructure[1] <> FieldNameStructure[1] Then
			
			Raise NStr("vi = 'Bộ nhớ cache không hợp lệ để theo dõi dữ liệu không chia tách trong quá trình tải lên.';
						|ru = 'Некорректный кэш контроля неразделенных данных при выгрузке.';
						|en = 'Invalid shared data control cache on export.'; fa = 'Invalid shared data control cache on export.';
						|it = 'Cache di controllo dati non condivisi durante l''upload non valido.';
						|pl = 'Nieprawidłowy cache kontroli niepodzielonych danych przy eksportowaniu.';
						|tr = 'Dışa aktarma sırasında yanlış paylaşımlı veri kontrol önbelleği.'");
			
		EndIf;
		
		If CommonCTL.IsConstant(MetadataObject) Then
			
			ControllingReferenceToUnsharedDataWhenUnloading(
				Container,
				Object.Value,
				Object,
				MetadataObject,
				FieldForControllingReferencesToUnsharedData);
			
		ElsIf CommonCTL.IsRefData(MetadataObject) Then
			
			If FieldNameStructure[2] = "Attribute" Or FieldNameStructure[2] = "Attribute" Then // Not localized
				
				ControllingReferenceToUnsharedDataWhenUnloading(
					Container,
					Object[FieldNameStructure[3]],
					Object,
					MetadataObject,
					FieldForControllingReferencesToUnsharedData);
				
			ElsIf FieldNameStructure[2] = "TabularSection" Or FieldNameStructure[2] = "TabularSection" Then // Not localized
				
				TabularSectionName = FieldNameStructure[3];
				
				If FieldNameStructure[4] = "Attribute" Or FieldNameStructure[4] = "Attribute" Then // Not localized
					
					AttributeName = FieldNameStructure[5];
					
					For Each LineOfATabularSection In Object[TabularSectionName] Do
						
						ControllingReferenceToUnsharedDataWhenUnloading(
							Container,
							LineOfATabularSection[AttributeName],
							Object,
							MetadataObject,
							FieldForControllingReferencesToUnsharedData);
						
					EndDo;
					
				Else
					
					Raise NStr("vi = 'Bộ nhớ cache không hợp lệ để theo dõi dữ liệu không chia tách trong quá trình tải lên.';
								|ru = 'Некорректный кэш контроля неразделенных данных при выгрузке.';
								|en = 'Invalid shared data control cache on export.'; fa = 'Invalid shared data control cache on export.';
								|it = 'Cache di controllo dati non condivisi durante l''upload non valido.';
								|pl = 'Nieprawidłowy cache kontroli niepodzielonych danych przy eksportowaniu.';
								|tr = 'Dışa aktarma sırasında yanlış paylaşımlı veri kontrol önbelleği.'");
					
				EndIf;
				
			Else
				
				Raise NStr("vi = 'Bộ nhớ cache không hợp lệ để theo dõi dữ liệu không chia tách trong quá trình tải lên.';
							|ru = 'Некорректный кэш контроля неразделенных данных при выгрузке.';
							|en = 'Invalid shared data control cache on export.'; fa = 'Invalid shared data control cache on export.';
							|it = 'Cache di controllo dati non condivisi durante l''upload non valido.';
							|pl = 'Nieprawidłowy cache kontroli niepodzielonych danych przy eksportowaniu.';
							|tr = 'Dışa aktarma sırasında yanlış paylaşımlı veri kontrol önbelleği.'");
				
			EndIf;
			
		ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
			
			If FieldNameStructure[2] = "Dimension" Or FieldNameStructure[2] = "Dimension"
					Or FieldNameStructure[2] = "Resource" Or FieldNameStructure[2] = "Resource"
					Or FieldNameStructure[2] = "Attribute" Or FieldNameStructure[2] = "Attribute" Then // Not localized
				
				For Each Record In Object Do
					
					ControllingReferenceToUnsharedDataWhenUnloading(
						Container,
						Record[FieldNameStructure[3]],
						Object,
						MetadataObject,
						FieldForControllingReferencesToUnsharedData);
					
				EndDo;
				
			Else
				
				Raise NStr("vi = 'Bộ nhớ cache không hợp lệ để theo dõi dữ liệu không chia tách trong quá trình tải lên.';
							|ru = 'Некорректный кэш контроля неразделенных данных при выгрузке.';
							|en = 'Invalid shared data control cache on export.'; fa = 'Invalid shared data control cache on export.';
							|it = 'Cache di controllo dati non condivisi durante l''upload non valido.';
							|pl = 'Nieprawidłowy cache kontroli niepodzielonych danych przy eksportowaniu.';
							|tr = 'Dışa aktarma sırasında yanlış paylaşımlı veri kontrol önbelleği.'");
				
			EndIf;
			
		Else
			Raise StrTemplate(NStr("vi = 'Không hỗ trợ đối tượng metadata %1.';
									|ru = 'Объект метаданных %1 не поддерживается.';
									|en = 'Metadata object %1 is not supported.'; fa = 'Metadata object %1 is not supported.';
									|it = 'Oggetto metadati %1 non supportato.';
									|pl = 'Obiekt metadanych %1 nie jest obsługiwany.';
									|tr = '""%1"" metaveri nesnesi desteklenmiyor.'", Metadata.DefaultLanguage.LanguageCode),
				FullMetadataObjectName);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ControllingReferenceToUnsharedDataWhenUnloading(Container, Val RefToCheck, Val InitialObject, Val SourceMetadataObject, Val FieldName)
	
	If Not ValueIsFilled(RefToCheck) Then
		// If the value of the props is not filled in, control is not required.
		Return;
	EndIf;
	
	ValueType = TypeOf(RefToCheck);
	
	If Not Common.IsReference(ValueType) Then
		// Control is required only for reference type values
		Return;
	EndIf;
	
	MetadataObject = RefToCheck.Metadata();
	
	If CommonCTL.IsEnum(MetadataObject) Then
		// For references to enumeration elements, the same unique identifier is used
		// in all information databases of the same configuration - therefore, they do not need to perform
		// link matching when loading.
		Return;
	EndIf;
	
	If CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject) Then
		If RefToCheck.Predefined Then
			// The mapping of links to predefined elements is performed by a separate mechanism
			// (see the general module unloading and loading of predefined data).
			Return;
		EndIf;
	EndIf;
	
	If MetadataObjectIsSeparatedByAtLeastOneSeparator(MetadataObject, Container.AdditionalProperties.LocalCacheOfDelimiterCompositions) Then
		// The separated data will be loaded while preserving the original unique identifiers (for objects
		// separated by separators with the separation type "Independently and jointly", all links will be generated anew).
		Return;
	EndIf;
	
	If Container.AdditionalProperties.GeneralDataRequiringLinkMatching.Find(MetadataObject) <> Undefined Then
		// If the developer has specified the composition of the natural key fields for the metadata object
		// , the links will be compared by the values of the natural key fields during loading.
		Return;
	EndIf;
	
	If Not Common.RefExists(RefToCheck) Then
		// The presence of "broken" links does not diagnose the developer's error in ensuring link matching
		// during loading.
		Return;
	EndIf;
	
	ErrorTemplate =
		NStr("vi = 'Đối tượng metadata %1 được đưa vào danh sách đối tượng mà không cần so sánh tham chiếu khi kết xuất / kết nhập
              |dữ liệu (trong thủ tục định trước 
              |%2,
              |nhưng khi đó không đảm bảo yêu cầu không có tham chiếu chưa đặt tương ứng khi kết xuất.
              |
              |Đã tìm thấy tham chiếu chưa đặt tương ứng khi kết xuất đối tượng %3, mà để làm giá trị mục tin %4
              |có đặt tham chiếu đến đối tượng %1 mà không thể đặt tương ứng đúng khi kết nhập dữ liệu.
              |Cần xem lại lô-gic sử dụng đối tượng %1 và đảm bảo trong đó không có các tham chiếu chưa đặt tương ứng
              |trong dữ liệu được kết xuất.
              |
              |Thông tin chẩn đoán:
              |1. Tuần tự hóa đối tượng được kết xuất:
              |---------------------------------------------------------------------------------------------------------------------------
              |%5
              |---------------------------------------------------------------------------------------------------------------------------
              |2. Tuần tự hóa đối tượng tham chiếu chưa đặt tương ứng
              |---------------------------------------------------------------------------------------------------------------------------
              |%6
              |---------------------------------------------------------------------------------------------------------------------------';
              |ru = 'Объект метаданных %1 включен в перечень объектов, для которых не требуется сопоставление ссылок при выгрузке / загрузке
              |данных (в переопределяемой процедуре 
              |%2,
              |но при этом для него не обеспечивается требования отсутствия несопоставимых ссылок при выгрузке.
              |
              |Несопоставимая ссылка обнаружена при выгрузке объекта %3, у которого в качестве значения реквизита %4
              |установлена ссылка на объект %1, которая не сможет быть корректно сопоставлена при загрузке данных.
              |Требуется пересмотреть логику использования объекта %1 и обеспечить для него отсутствие несопоставимых ссылок
              |в выгружаемых данных.
              |
              |Диагностическая информация:
              |1. Сериализация выгружаемого объекта:
              |---------------------------------------------------------------------------------------------------------------------------
              |%5
              |---------------------------------------------------------------------------------------------------------------------------
              |2. Сериализация объекта несопоставимой ссылки
              |---------------------------------------------------------------------------------------------------------------------------
              |%6
              |---------------------------------------------------------------------------------------------------------------------------';
              |en = 'The %1 metadata object is included in the list of objects, for which reference mapping is not required when importing/exporting
              |data in the 
              |%2
              |overridable procedure. The requirement for no unmapped references is not satisfied for it on export.
              |
              |Unmapped reference is detected when exporting the %3 object, which has a reference to the %1 object set as the %4
              |attribute value, which cannot be correctly mapped when importing data.
              |Revise the logic of the %1 object usage and make sure it has no unmapped references
              |in exported data.
              |
              |Diagnostic data:
              |1. Exported object serialization:
              |---------------------------------------------------------------------------------------------------------------------------
              |%5
              |---------------------------------------------------------------------------------------------------------------------------
              |2. Serialization of unmapped reference object
              |---------------------------------------------------------------------------------------------------------------------------
              |%6
              |---------------------------------------------------------------------------------------------------------------------------'; fa = 'The %1 metadata object is included in the list of objects, for which reference mapping is not required when importing/exporting
              |data in the 
              |%2
              |overridable procedure. The requirement for no unmapped references is not satisfied for it on export.
              |
              |Unmapped reference is detected when exporting the %3 object, which has a reference to the %1 object set as the %4
              |attribute value, which cannot be correctly mapped when importing data.
              |Revise the logic of the %1 object usage and make sure it has no unmapped references
              |in exported data.
              |
              |Diagnostic data:
              |1. Exported object serialization:
              |---------------------------------------------------------------------------------------------------------------------------
              |%5
              |---------------------------------------------------------------------------------------------------------------------------
              |2. Serialization of unmapped reference object
              |---------------------------------------------------------------------------------------------------------------------------
              |%6
              |---------------------------------------------------------------------------------------------------------------------------';
              |it = 'Объект метаданных %1 включен в перечень объектов, для которых не требуется сопоставление ссылок при выгрузке / загрузке
              |данных (в переопределяемой процедуре 
              |%2,
              |но при этом для него не обеспечивается требования отсутствия несопоставимых ссылок при выгрузке.
              |
              |Несопоставимая ссылка обнаружена при выгрузке объекта %3, у которого в качестве значения реквизита %4
              |установлена ссылка на объект %1, которая не сможет быть корректно сопоставлена при загрузке данных.
              |Требуется пересмотреть логику использования объекта %1 и обеспечить для него отсутствие несопоставимых ссылок
              |в выгружаемых данных.
              |
              |Диагностическая информация:
              |1. Сериализация выгружаемого объекта:
              |---------------------------------------------------------------------------------------------------------------------------
              |%5
              |---------------------------------------------------------------------------------------------------------------------------
              |2. Сериализация объекта несопоставимой ссылки
              |---------------------------------------------------------------------------------------------------------------------------
              |%6
              |---------------------------------------------------------------------------------------------------------------------------';
              |pl = 'The %1 metadata object is included in the list of objects, for which reference mapping is not required when importing/exporting
              |data in the 
              |%2
              |overridable procedure. The requirement for no unmapped references is not satisfied for it on export.
              |
              |Unmapped reference is detected when exporting the %3 object, which has a reference to the %1 object set as the %4
              |attribute value, which cannot be correctly mapped when importing data.
              |Revise the logic of the %1 object usage and make sure it has no unmapped references
              |in exported data.
              |
              |Diagnostic data:
              |1. Exported object serialization:
              |---------------------------------------------------------------------------------------------------------------------------
              |%5
              |---------------------------------------------------------------------------------------------------------------------------
              |2. Serialization of unmapped reference object
              |---------------------------------------------------------------------------------------------------------------------------
              |%6
              |---------------------------------------------------------------------------------------------------------------------------';
              |tr = '%1 meta veri nesnesi, veri dışa / içe aktarma sırasında bağlantı eşleştirmesi gerektirmeyen nesneler listesine dahil edilmiştir
              | (
              | %2 Overridable prosedürde, ancak içe aktarma sırasında eşleşmeyen bağlantı olmaması gerekliliğini karşılamıyor. 
              |
              |Özniteliği %4 olarak ayarlanmış %1 nesnesine referansı olan %3 nesnesi kaldırılırken eşleşmeyen bağlantı algılandı
              |, veri içe aktarılırken doğru şekilde eşleştirilemiyor. 
              |%1 nesnesini kullanma mantığını yeniden gözden geçirmeli ve dışa aktarılan verilerde eşleştirme olmayan bağlantı içermediğinden emin olmalıyız. 
              |
              |Tanı bilgileri:
              |1. Dışa aktarılacak nesnenin seri hale getirilmesi: 
              |
              |------------------------------------------------ -------------------------------------------------- ------------------------
              |%5
              |------------- ------- ------------------------------------------------------ ------- ------------------------------------------------------ ----
              |2. Eişleştirme olmayan bağlantı nesnesini seri hale getirme
              |------------------------------------------------------ --------- --------------------------------------------------------------------------------
              |%6
              |--------------------------------------------------------------------------------------------------------------------------'");
	
	ErrorText = StrTemplate(
		ErrorTemplate,
		MetadataObject,
		"ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport",
		SourceMetadataObject,
		FieldName,
		Common.ValueToXMLString(InitialObject),
		Common.ValueToXMLString(RefToCheck.GetObject()));
	
	Raise ErrorText;
	
EndProcedure

#EndRegion

