////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns dependencies of undivided metadata objects.
// If a metadata object contains a field whose value type is a reference to another metadata object
// , it is assumed that it depends on it.
//
// Returns:
//  FixedMap of KeyAndValue:
//    * Key - String - the full name of the dependent object metadata,
//    * Value - Array of String - full names of the metadata objects that this metadata object depends on.
//
Function DependenciesOfUnsharedMetadataObjects() Export
	
	Cache = New Map();
	
	TypesOfCommonClassifiers = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	
	For Each TypeOfGeneralClassifier In TypesOfCommonClassifiers Do
		
		Manager = Common.ObjectManagerByFullName(TypeOfGeneralClassifier.FullName());

		Try
			NaturalKeyFields = Manager.NaturalKeyFields();
		Except
			Raise StrTemplate(NStr("vi = 'Không thể nhận mô tả trường của khóa tự nhiên của đối tượng %1:
				|%2';
				|ru = 'Не удалось получить описание полей естественного ключа объекта %1:
				|%2';
				|en = 'Cannot get the field details of the natural key of the %1object:
				|%2'; fa = 'Cannot get the field details of the natural key of the %1object:
				|%2';
				|it = 'Cannot get the field details of the natural key of the %1object:
				|%2';
				|pl = 'Cannot get the field details of the natural key of the %1object:
				|%2';
				|tr = 'X nesnesinin doğal anahtar alanlarının açıklaması alınamadı %1:
				|%2'", Metadata.DefaultLanguage.LanguageCode),
				TypeOfGeneralClassifier.FullName(),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;

		For Each NaturalKeyField In NaturalKeyFields Do
			
			FieldTypes = Undefined;
			
			For Iterator_SSLy = 0 To TypeOfGeneralClassifier.StandardAttributes.Count() - 1 Do
				
				// Search in standard details
				StandardAttribute = TypeOfGeneralClassifier.StandardAttributes[Iterator_SSLy];
				If StandardAttribute.Name = NaturalKeyField Then
					FieldTypes = StandardAttribute.Type;
				EndIf;
				
			EndDo;
			
			// Search in the details
			Attribute = TypeOfGeneralClassifier.Attributes.Find(NaturalKeyField);
			If Attribute <> Undefined Then
				FieldTypes = Attribute.Type;
			EndIf;
			
			// Search in general details
			CommonAttribute = Metadata.CommonAttributes.Find(NaturalKeyField);
			If CommonAttribute <> Undefined Then
				For Each CommonAttribute In Metadata.CommonAttributes Do
					If CommonAttribute.Content.Find(TypeOfGeneralClassifier) <> Undefined Then
						FieldTypes = CommonAttribute.Type;
					EndIf;
				EndDo;
			EndIf;
			
			If FieldTypes = Undefined Then
				
				Raise StrTemplate(NStr("vi = 'Trường %1 không được sử dụng để làm trường khóa tự nhiên của đối tượng %2:
                          |không tìm thấy trường của đối tượng';
                          |ru = 'Поле %1 не может использоваться в качестве поля естественного ключа объекта %2:
                          |поле объекта не обнаружено';
                          |en = 'Cannot use the %1 field as a natural key field of %2 object:
                          |the object field is not found'; fa = 'Cannot use the %1 field as a natural key field of %2 object:
                          |the object field is not found';
                          |it = 'Il campo %1 non può essere usato come campo della chiave naturale dell''oggetto %2:
                          | campo dell''oggetto non trovato';
                          |pl = 'Pole %1 nie może być używane jako pole naturalnego klucza obiektu %2:
                          | nie odnaleziono pola obiektu';
                          |tr = '%1 alanı, %2 nesnesinin doğal anahtar alanı olarak kullanılamaz:
                          |nesne alanı bulunamadı'", Metadata.DefaultLanguage.LanguageCode),
					NaturalKeyField,
					TypeOfGeneralClassifier.FullName());
				
			EndIf;
			
			For Each FieldType In FieldTypes.Types() Do
				
				If Not CommonCTL.IsPrimitiveType(FieldType) And Not CommonCTL.IsEnum(ExportImportDataInternal.MetadataObjectByRefType(FieldType)) Then
					
					If FieldType = Type("ValueStorage") Then
						
						Raise StrTemplate(
							NStr("vi = 'Trường %1 không thể sử dụng để làm trường khóa tự nhiên của đối tượng %2: không hỗ trợ sử dụng
                                  |giá trị kiểu %3 để làm trường khóa tự nhiên';
                                  |ru = 'Поле %1 не может использоваться в качестве поля естественного ключа объекта %2: использование
                                  |значений типа %3 в качестве полей естественного ключа не поддерживается';
                                  |en = 'Cannot use the %1 field as a natural key field of the %2 object:
                                  |using the %3 type values as natural keys is not supported'; fa = 'Cannot use the %1 field as a natural key field of the %2 object:
                                  |using the %3 type values as natural keys is not supported';
                                  |it = 'Il campo %1 non può essere usato come campo della chiave naturale dell''oggetto %2: uso di 
                                  | valori del tipo %3 come campo della chiave naturale non è supportato';
                                  |pl = 'Pole %1 nie może być używane jako pole naturalnego klucza obiektu %2: używanie
                                  |wartości typu %3 jako pola klucza naturalnego nie jest obsługiwane';
                                  |tr = '%1 alanı, %2 nesnesinin doğal anahtar alanı olarak kullanılamaz: %3 türündeki
                                  |değerlerin doğal anahtar alanları olarak kullanılması desteklenmiyor'", Metadata.DefaultLanguage.LanguageCode),
							NaturalKeyField,
							TypeOfGeneralClassifier.FullName(),
							"ValueStorage");
						
					EndIf;
					
					Ref = New(FieldType);
					ObjectMetadata = Ref.Metadata(); // MetadataObject
					If TypesOfCommonClassifiers.Find(ObjectMetadata) <> Undefined Then
						GeneralClassifier = Cache.Get(TypeOfGeneralClassifier.FullName()); // Array
						If GeneralClassifier <> Undefined Then
							GeneralClassifier.Add(ObjectMetadata.FullName());
						Else
							NewArray = New Array();
							NewArray.Add(ObjectMetadata.FullName());
							Cache.Insert(TypeOfGeneralClassifier.FullName(), NewArray);
						EndIf;
						
					Else
						
						Raise StrTemplate(
							NStr("vi = 'Trường %1 không thể sử dụng để làm trường khóa tự nhiên của đối tượng %2:
                                  |để làm kiểu trường, có thể sử dụng đối tượng %3 không được đưa vào bộ sản phẩm
                                  |của dữ liệu chung thông qua thủ tục định trước
                                  |%4';
                                  |ru = 'Поле %1 не может использоваться в качестве поля естественного ключа объекта %2:
                                  |в качестве типа поля может использоваться объект %3, который не включен в набор
                                  |общих данных через переопределяемую процедуру
                                  |%4';
                                  |en = 'Cannot use the %1 field as a natural key field of the %2 object:
                                  |the field type might be based on the %3 object, which is not included
                                  |in the common data set through overridable procedure
                                  |%4'; fa = 'Cannot use the %1 field as a natural key field of the %2 object:
                                  |the field type might be based on the %3 object, which is not included
                                  |in the common data set through overridable procedure
                                  |%4';
                                  |it = 'Il campo %1 non può essere utilizzato come campo della chiave naturale dell''oggetto%2:
                                  | come tipo di campo è possibile utilizzare l''oggetto %3, non incluso nel kit 
                                  | di dati comuni attraverso procedure ridefinibili
                                  | %4';
                                  |pl = 'Pole %1 nie może być używane jako pole naturalne klucza obiektu %2:
                                  |jako typ pola może być używany obiekt %3, który nie jest włączony do zestawu 
                                  |podstawowych danych przez predefiniowaną procedurę
                                  |%4';
                                  |tr = '%1 alanı, %2 nesnesinin doğal anahtar alanı olarak kullanılamaz:
                                  | %3 nesnesi, %4 Overridable prosedürü aracılığıyla paylaşılan veri kümesine
                                  |dahil edilmeyen alan türü olarak kullanılabilir
                                  |'", Metadata.DefaultLanguage.LanguageCode),
							NaturalKeyField,
							TypeOfGeneralClassifier.FullName(),
							ObjectMetadata.FullName(),
							"ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport");
						
					EndIf;
					
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return New FixedMap(Cache);
	
EndFunction

// Returns rules for controlling links to undivided data in split data when uploading.
//
// Returns:
//  FixedMap of KeyAndValue:
//    * Key - String - the full name of the metadata object to check
//       for references to undivided data in split data when uploading.
//    * Value - Array of String - array of names of object fields that should be
//       checked for references to undivided data in separated data when uploading.
//
Function ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading() Export
	
	Cache = New Map();
	
	TypesOfSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	ObjectsExcludedFromUnloadingLoading = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
	ObjectsThatDoNotRequireReferenceMapping = ExportImportDataInternalEvents.GetSharedDataTypesThatDoNotRequireLinkMappingWhenLoading();
	
	LocalCacheOfDelimiterCompositions = New Map();
	
	For Each MetadataObject In ExportImportDataInternal.AllConstants() Do
		FillReferenceControlCacheForUnsharedDataWhenUnloadingForConstants(
			Cache, MetadataObject, TypesOfSharedData, ObjectsExcludedFromUnloadingLoading, ObjectsThatDoNotRequireReferenceMapping,
				LocalCacheOfDelimiterCompositions);
	EndDo;
	
	For Each MetadataObject In ExportImportDataInternal.AllReferenceData() Do
		FillReferenceControlCacheForUnsharedDataWhenUnloadingForObjects(
			Cache, MetadataObject, TypesOfSharedData, ObjectsExcludedFromUnloadingLoading, ObjectsThatDoNotRequireReferenceMapping,
				LocalCacheOfDelimiterCompositions);
	EndDo;
	
	For Each MetadataObject In ExportImportDataInternal.AllRecordSets() Do
		FillReferenceControlCacheForUnsharedDataWhenUnloadingForRecordsets(
			Cache, MetadataObject, TypesOfSharedData, ObjectsExcludedFromUnloadingLoading, ObjectsThatDoNotRequireReferenceMapping,
				LocalCacheOfDelimiterCompositions);
	EndDo;
	
	Return New FixedMap(Cache);
	
EndFunction

#EndRegion

#Region Private

Procedure FillReferenceControlCacheForUnsharedDataWhenUnloadingForConstants(Cache, Val MetadataObject, Val TypesOfSharedData, Val ObjectsExcludedFromUnloadingLoading, Val ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition)
	
	If ObjectsExcludedFromUnloadingLoading.Find(MetadataObject) = Undefined 
	   And ExportImportSharedData.MetadataObjectIsSeparatedByAtLeastOneSeparator(MetadataObject, LocalCacheOfDelimiterComposition) Then
		
		FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
			Cache, MetadataObject, MetadataObject, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
		
	EndIf;
	
EndProcedure

Procedure FillReferenceControlCacheForUnsharedDataWhenUnloadingForObjects(Cache, Val MetadataObject, Val TypesOfSharedData, Val ObjectsExcludedFromUnloadingLoading, Val ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition)
	
	If ObjectsExcludedFromUnloadingLoading.Find(MetadataObject) = Undefined 
	   And ExportImportSharedData.MetadataObjectIsSeparatedByAtLeastOneSeparator(MetadataObject, LocalCacheOfDelimiterComposition) Then
		
		For Each Attribute In MetadataObject.Attributes Do
			
			FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
				Cache, MetadataObject, Attribute, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
			
		EndDo;
		
		For Each TabularSection In MetadataObject.TabularSections Do
			
			For Each Attribute In TabularSection.Attributes Do
				
				FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
					Cache, MetadataObject, Attribute, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillReferenceControlCacheForUnsharedDataWhenUnloadingForRecordsets(Cache, Val MetadataObject, Val TypesOfSharedData, Val ObjectsExcludedFromUnloadingLoading, Val ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition)
	
	If ObjectsExcludedFromUnloadingLoading.Find(MetadataObject) = Undefined 
	   And ExportImportSharedData.MetadataObjectIsSeparatedByAtLeastOneSeparator(MetadataObject, LocalCacheOfDelimiterComposition) Then
		
		For Each Dimension In MetadataObject.Dimensions Do
			
			FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
				Cache, MetadataObject, Dimension, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
			
		EndDo;
		
		For Each Resource In MetadataObject.Resources Do
			
			FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
				Cache, MetadataObject, Resource, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
			
		EndDo;
		
		For Each Attribute In MetadataObject.Attributes Do
			
			FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
				Cache, MetadataObject, Attribute, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
			
		EndDo;
		
	EndIf;
	
EndProcedure


// Parameters:
// 	Cache - Map - key and value:
//	 * Key - String - full name of the metadata.
//	 * Value - Array of String - metadata names.
Procedure FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(Cache, Val MetadataObject, Val Field, Val TypesOfSharedData, Val ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterCompositions)
	
	FieldTypes = Field.Type;
	ObjectName = MetadataObject.FullName();
	
	If CommonCTL.IsRefsTypesSet(FieldTypes) Then
		
		// For the props, the type of any link or the composite type of the Reference Link type is set.*,
		// Document link.* etc. - at this stage, the check will not be performed, because the developer could
		// mean any reference of the separated metadata reference object.
		//
		// The information about the object and the details will be stored in the cache and later used
		// to perform verification during the unloading of the data that will actually be unloaded.
		//
		
		TypesNames = Cache.Get(ObjectName);
		If TypesNames = Undefined Then
			TypesNames = New Array;
			Cache.Insert(ObjectName, TypesNames);
		EndIf;
		
		TypesNames.Add(Field.FullName());
		
	Else
		
		For Each FieldType In FieldTypes.Types() Do
			
			If Not CommonCTL.IsPrimitiveType(FieldType) And Not (FieldType = Type("ValueStorage")) Then
				
				RefMetadata = ExportImportDataInternal.MetadataObjectByRefType(FieldType);
				
				If TypesOfSharedData.Find(RefMetadata) = Undefined
						And Not CommonCTL.IsEnum(RefMetadata)
						And Not ExportImportSharedData.MetadataObjectIsSeparatedByAtLeastOneSeparator(RefMetadata, LocalCacheOfDelimiterCompositions) 
						And RefMetadata.ConfigurationExtension() = Undefined Then
					
					If ObjectsThatDoNotRequireReferenceMapping.Find(RefMetadata) = Undefined Then
						
						RaiseExceptionIfSplitDataContainsReferencesToUnsharedDataWithoutReferenceMatchingSupport(
							MetadataObject,
							Field.FullName(),
							RefMetadata,
							False);
						
					Else
						
						TypesNames = Cache.Get(ObjectName);
						If TypesNames = Undefined Then
							TypesNames = New Array;
							Cache.Insert(ObjectName, TypesNames);
						EndIf;
						
						TypesNames.Add(Field.FullName());
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure RaiseExceptionIfSplitDataContainsReferencesToUnsharedDataWithoutReferenceMatchingSupport(Val MetadataObject, Val FieldName, Val RefMetadata, Val OnExport)
	
	If CommonCTL.IsConstant(MetadataObject) Then
		
		ErrorText = StrTemplate(
			NStr("vi = 'Để làm giá trị hằng chia tách %1 đang sử dụng tham chiếu đến
                  |đối tượng không chia tách %2';
                  |ru = 'В качестве значения разделенной константы %1 используются ссылки на
                  |неразделенный объект %2';
                  |en = 'References to undivided object %2
                  |are used as a value of divided constant %1'; fa = 'References to undivided object %2
                  |are used as a value of divided constant %1';
                  |it = 'Come valore di una costante divisa%1 si utilizzano i collegamenti 
                  | all''oggetto non condiviso%2';
                  |pl = 'Jako wartości podzielonej konstanty %1 są używane odnośniki do 
                  |niepodzielonego obiektu %2';
                  |tr = '%1 Ayrılmış sabit, değer olarak 
                  |ayrılmamış %2 nesnesine yapılan bağlantıları kullanır'", Metadata.DefaultLanguage.LanguageCode),
			MetadataObject.FullName(),
			RefMetadata.FullName());
		
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		ErrorText = StrTemplate(
			NStr("vi = 'Để làm giá trị mục tin %1 của đối tượng chia tách %2 đang sử dụng tham chiếu đến
                  |đối tượng không chia tách %3';
                  |ru = 'В качестве значения реквизита %1 разделенного объекта %2 используются ссылки на
                  |неразделенный объект %3';
                  |en = 'References to undivided object %3
                  |are used as a value of attribute %1 of divided object %2'; fa = 'References to undivided object %3
                  |are used as a value of attribute %1 of divided object %2';
                  |it = 'Come valore del requisito %1 dell''oggetto condiviso %2 si utilizzano i collegamenti all
                  |''oggetto non condiviso %3';
                  |pl = 'Jako wartość atrybutu %1 podzielonego obiektu %2 są używane odnośniki do 
                  |niepodzielonego obiektu %3';
                  |tr = '%3 ayrılmış nesnesine yapılan bağlantılar, 
                  |ayrılmamış %2 nesnesinin %1 özniteliğinin değeri olarak kullanılıyor'", Metadata.DefaultLanguage.LanguageCode),
			FieldName,
			MetadataObject.FullName(),
			RefMetadata.FullName());
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		
		ErrorText = StrTemplate(
			NStr("vi = 'Để làm giá trị chiều đo, nguồn hoặc mục tin %1 của tập hợp bản ghi chia tách %2 có sử dụng tham chiếu đến
                  |đối tượng không chia tách %3';
                  |ru = 'В качестве значения измерения, ресурса или реквизита %1 разделенного набора записей %2 используются ссылки на
                  |неразделенный объект %3';
                  |en = 'References to
                  |undivided object %3are used as a value of dimension, resource or attribute %1 of divided record set %2'; fa = 'References to
                  |undivided object %3are used as a value of dimension, resource or attribute %1 of divided record set %2';
                  |it = 'Come valore di misura, risorsa o requisito %1 di un kit di registrazioni condiviso%2, viene utilizzato il collegamento 
                  | a un oggetto non condiviso%3';
                  |pl = 'Jako wartość atrybutu miary, zasobu lub atrybutu %1 podzielonego zestawu wpisów %2 są używane odnośniki do 
                  |niepodzielonego obiektu %3';
                  |tr = 'Ayrılmış %2 kayıt kümesinin %1 boyut değeri, kaynağı veya özniteliği, 
                  |ayrılmamış %3 nesnesine referanslar kullanıyor'", Metadata.DefaultLanguage.LanguageCode),
			FieldName,
			MetadataObject.FullName(),
			RefMetadata.FullName());
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Đối tượng metadata bất thường: %1';
								|ru = 'Неожиданный объект метаданных: %1';
								|en = 'Unexpected metadata object: %1'; fa = 'Unexpected metadata object: %1';
								|it = 'Oggetto di metadati imprevisto: %1';
								|pl = 'Nieoczekiwany obiekt metadanych: %1';
								|tr = 'Beklenmedik meta veri nesnesi: %1'", Metadata.DefaultLanguage.LanguageCode),
			MetadataObject.FullName());
		
	EndIf;
	
	If OnExport Then
		
		ErrorText = ErrorText + " "
			+ NStr("vi = '(để làm kiểu giá trị đối với đối tượng, thiết lập kiểu dữ liệu phức hợp,
                  |trong đó có thể chứa tham chiếu đến dữ liệu chia tách cũng như dữ liệu không chia tách,
                  |nhưng khi kết xuất đã chẩn đoán thử kết xuất tham chiếu đến đối tượng không chia tách).';
                  |ru = '(в качестве типа значения для объекта установлен составной тип данных,
                  |который может содержать ссылки как на разделенные данные, так и на неразделенные,
                  |но при выгрузке была диагностирована попытка выгрузки ссылки на неразделенный объект).';
                  |en = '(composite data type is set as a value type for the object
                  |which can contain references to both separated and shared data,
                  |but an attempt of export of the reference to undivided object was detected when exporting).'; fa = '(composite data type is set as a value type for the object
                  |which can contain references to both separated and shared data,
                  |but an attempt of export of the reference to undivided object was detected when exporting).';
                  |it = '(come tipo di valore per un oggetto, viene impostato un tipo di dati composito,
                  | che può contenere collegamenti a dati sia condivisi che non condivisi
                  |, ma durante l''upload è stato effettuato un tentativo di caricare un collegamento ad un oggetto non condiviso).';
                  |pl = '(jako typ wartości dla obiektu jest ustawiony złożony typ danych, 
                  |który może zawierać odnośniki tak do podzielonych danych, jak i do nie podzielonych,
                  | ale przy wyeksportowaniu została wykryta próba eksportowania odnośnika na obiekt niepodzielony).';
                  |tr = '(nesnenin değer türü, hem ayrılmış hem de ayrılmamış verilere bağlantılar içerebilen
                  |bileşik bir veri türüne ayarlanmıştır, ancak
                  |dışa aktarma sırasında paylaşımlı nesneye yapılan bağlantı dışa aktarma girişimi teşhis edildi).'", Metadata.DefaultLanguage.LanguageCode);
		
	Else
		
		ErrorText = ErrorText + ".";
		
	EndIf;
	
	ErrorAddition = StrTemplate(
		NStr("vi = 'Khi đó, đối tượng không chia tách %1 không thuộc thành phần các kiểu dữ liệu chung,
              |mà có thể thực hiện so sánh tham chiếu khi kết xuất và kết nhập.
              |Tình huống này là không thể chấp nhận, bởi vì khi kết nhập dữ liệu đã kết xuất sang CSTT khác
              |sẽ kết nhập tham chiếu ""hỏng"" đến đối tượng %1.
              |
              |Để khắc phục tình trạng này, đối với đối tượng %1 cần thực thi cơ chế xác định 
              |các trường để xác định duy nhất khóa tự nhiên của đối tượng và đưa đối tượng %1 vào thành phần
              |kiểu dữ liệu chung, để có thể thực hiện so sánh tham chiếu khi
              |kết xuất và kết nhập, sau khi chỉ ra đối tượng metadata %1trong thủ tục
              |%2.';
              |ru = 'При этом неразделенный объект %1 не включен в состав типов общих данных,
              |для которых возможно выполнение сопоставления ссылок при выгрузке и загрузке.
              |Данная ситуация является недопустимой, т.к. при загрузке выгруженных данных в другую ИБ
              |будут загружены ""битые"" ссылки на объект %1.
              |
              |Для исправления ситуации требуется реализовать для объекта %1 механизм определения
              |полей, однозначно определяющих естественный ключ объекта и включить объект %1 в состав
              |типов общих данных, для которых возможно выполнение сопоставления ссылок при
              |выгрузке и загрузке, указав объект метаданных %1 в процедуре
              |%2.';
              |en = 'The shared %1 object does not belong to shared data types,
              |for which references can be mapped upon export and import.
              |This situation is not allowed as ""damaged"" references to the %1 object will be imported
              |when you import exported data to another infobase.
              |
              |To fix this situation, implement a tool determining
              |fields that uniquely identify the object natural key for the %1 object. Include the %1 object in
              |shared data types, for which references can be mapped upon export and import.
              |To do it, specify the %1 metadata object in the procedure
              |%2.'; fa = 'The shared %1 object does not belong to shared data types,
              |for which references can be mapped upon export and import.
              |This situation is not allowed as ""damaged"" references to the %1 object will be imported
              |when you import exported data to another infobase.
              |
              |To fix this situation, implement a tool determining
              |fields that uniquely identify the object natural key for the %1 object. Include the %1 object in
              |shared data types, for which references can be mapped upon export and import.
              |To do it, specify the %1 metadata object in the procedure
              |%2.';
              |it = 'Un oggetto non condiviso%1 non è incluso nei tipi di dati generali
              | per i quali è possibile eseguire la mappatura di riferimento durante download e upload.
              | Tale situazione non è disponibile, poiché quando si scaricano i dati caricati su un altro database informatico
              |, verranno caricati riferimenti a oggetti ""spezzati""%1.
              |
              | Per correggere la situazione, è necessario implementare per l''oggetto%1 un meccanismo di definizione
              | dei campi che definiscono in modo univoco la chiave naturale dell''oggetto e includere %1l''oggetto come parte
              | dei dati comuni per i quali è possibile eseguire la mappatura dei collegamenti
              | durante download e upload, specificando l''oggetto di metadati%1 nella procedura
              | %2.';
              |pl = 'Przy tym obiekt niepodzielony %1 nie jest włączony do składu typów ogólnych danych, 
              |dla których jest możliwe wykonanie porównania odnośników przy wyeksportowaniu i pobieraniu. 
              |Ta sytuacja jest niedopuszczalną, ponieważ przy pobieraniu wyeksportowanych danych do innej bazy informacyjnej 
              |będą pobrane niedziałające odnośniki na obiekt %1.
              |
              |W celu poprawienia sytuacji należy dla obiektu realizować %1 mechanizm określenia 
              |pól, jednoznacznie określających klucz naturalny obiektu i włączyć obiekt %1 do składu
              |typów ogólnych danych, dla których jest możliwe porównanie odnośników przy 
              |eksportowaniu i pobieraniu, wskazując obiekt metadanych %1 w procedurze
              |%2.';
              |tr = 'Ancak, paylaşımlı %1 nesnesi, dışa ve içe aktarma sırasında bağlantı eşleştirmenin gerçekleştirilebileceği
              |paylaşılan veri türlerine dahil değildir. 
              |Bu durum geçersiz çünkü içe aktarılan veriler başka bir
              |infobase''e yüklendiğinde, %1 nesnesine yapılan ""bozuk"" bağlantılar yüklenecek.
              |
              |Durumu düzeltmek için, %1 nesnesi için, nesnenin doğal anahtarını benzersiz bir şekilde tanımlayan
              |alanları tanımlayan ve gerçekleştirmenin mümkün olduğu 
              |genel veri türlerine %1 nesnesini dahil eden bir mekanizma uygulamak gerekir. 
              |yükleme ve indirme sırasında bağlantı eşleştirme, prosedürde
              |%2 meta veri nesnesi %1 belirtilerek.'", Metadata.DefaultLanguage.LanguageCode),
		RefMetadata.FullName(),
		"ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport");
	
	If Not OnExport Then
		
		ErrorAddition = ErrorAddition + Chars.LF + StrTemplate(
			NStr("vi = 'Nếu so sánh chính xác tham chiếu đến dữ liệu không chia tách trong CSTT mà từ đó đã kết xuất
                  |dữ liệu và CSTT mà dữ liệu được kết nhập vào đó, được đảm bảo thông qua các cơ chế khác, cần
                  |chỉ ra đối tượng metadata %1 trong thủ tục
                  |%2.';
                  |ru = 'Если корректное сопоставление ссылок на неразделенные данные в ИБ, из которой выгружены
                  |данные и ИБ, в которую они загружаются, гарантируется с помощью других механизмов, необходимо
                  |указать объект метаданных %1 в процедуре
                  |%2.';
                  |en = 'If other tools ensure the correct mapping of references to shared data in the infobase, from which data and the infobase, to which they are imported, are exported,
                  |specify the %1 metadata object in the procedure
                  |%2.'; fa = 'If other tools ensure the correct mapping of references to shared data in the infobase, from which data and the infobase, to which they are imported, are exported,
                  |specify the %1 metadata object in the procedure
                  |%2.';
                  |it = 'Se il corretto confronto dei collegamenti a dati non condivisi nel database informatico, da cui i dati vengono 
                  |caricati e il database informatico in cui sono scaricati, è garantito tramite l''utilizzo di altri meccanismi, è necessario
                  | specificare l''oggetto di metadati %1nella procedura 
                  |%2.';
                  |pl = 'Jeżeli poprawne porównanie odnośników na niepodzielone dane w bazie informacyjnej, z której są wyeksportowane 
                  |dane i baza informacyjna, do której oni są ładowane, jest gwarantowane za pomocą innych mechanizmów, należy 
                  |wskazać obiekt metadanych %1 w procedurze 
                  |%2.';
                  |tr = 'Verilerin dışa aktarıldığı
                  |Infobase''teki ve verilerin içe aktarıldığı infobase''teki paylaşılan verilere yapılan bağlantıların doğru eşleşmesi
                  |başka mekanizmalar tarafından garanti ediliyorsa, %2 prosedüründe %1 metaveri nesnesini belirtmeniz gerekir.
                  |'", Metadata.DefaultLanguage.LanguageCode),
			RefMetadata.FullName(),
			"ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport");
		
	EndIf;
	
	Raise ErrorText + Chars.LF + Chars.CR + ErrorAddition;
	
EndProcedure

#EndRegion