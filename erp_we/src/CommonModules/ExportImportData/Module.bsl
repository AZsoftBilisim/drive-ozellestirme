////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

// This module contains interface procedures for
// calling the processes of unloading and loading data.


#Region Public

// Uploads data to a zip archive, from which it can later be uploaded
//  to another information database or data area using the function
//  Offloading data upload.Download the data from the current archived area().
//
// Parameters:
//  ExportingParameters - Structure - containing data upload parameters:
//		* TypesToExport - Array of MetadataObject - the data that you want to upload to the archive
//      * UnloadUsers - Boolean - to upload information about users of the information base,
//      * ExportUserSettings - Boolean - ignored if Unloaded users = False.
//    Also, the structure may contain additional keys that can be processed inside
//      arbitrary data upload handlers.
//
// Returns:		
//  Structure - With Fields:
//  * FileName - String - the archive file name
//  * Warnings - Array of String - warnings to the user based on the results of the upload.
//
Function UploadCurAreaDataToArchive(Val ExportingParameters) Export
	
	If Not CheckForRights() Then
		Raise NStr("vi = 'Không đủ quyền truy cập để kết xuất dữ liệu';
					|ru = 'Недостаточно прав доступа для выгрузки данных';
					|en = 'Insufficient access rights to export data'; fa = 'Insufficient access rights to export data';
					|it = 'Diritti di accesso insufficienti per l''upload dei dati';
					|pl = 'Niewystarczające uprawnienia dostępu do wyciągu danych';
					|tr = 'Verileri dışa aktarmak için erişim yetkileri yetersiz'");
	EndIf;
	
	If Not ExportingParameters.Property("TypesToExport") Then
		ExportingParameters.Insert("TypesToExport", New Array());
	EndIf;
	
	If Not ExportingParameters.Property("UnloadedTypesOfSharedData") Then
		ExportingParameters.Insert("UnloadedTypesOfSharedData", New Array());
	EndIf;
	
	If Not ExportingParameters.Property("UnloadUsers") Then
		ExportingParameters.Insert("UnloadUsers", False);
	EndIf;
	
	If Not ExportingParameters.Property("ExportUserSettings") Then
		ExportingParameters.Insert("ExportUserSettings", False);
	EndIf;
	
	If Not ExportingParameters.Property("UploadRegisteredChangesForExchangePlanNodes") Then
		ExportingParameters.Insert("UploadRegisteredChangesForExchangePlanNodes", False);
	EndIf;
	
	ExportImportDataInternal.CheckParametersOfParallelExportImportData(ExportingParameters, False);
	
	If Not ExportingParameters.Property("SkipCheckingExportedData") Then
		
		DataUploadErrors = DataUploadErrors(
 			ExportingParameters.TypesToExport,
 			ExportingParameters.UnloadedTypesOfSharedData);

		If ValueIsFilled(DataUploadErrors) Then

			PartsOfErrorText = New Array;
			PartsOfErrorText.Add(NStr("vi = 'Đã tìm thấy các lỗi:';
										|ru = 'Обнаруженные ошибки:';
										|en = 'Detected errors:'; fa = 'Detected errors:';
										|it = 'Errori rilevati:';
										|pl = 'Wykryto błędy:';
										|tr = 'Tespit edilen hatalar:'"));
			PartsOfErrorText.Add(Chars.LF);

			For Each DataUploadError In DataUploadErrors Do
				PartsOfErrorText.Add("● ");
				PartsOfErrorText.Add(DataUploadError);
				PartsOfErrorText.Add(Chars.LF);
			EndDo;

			ErrorText = StrConcat(PartsOfErrorText);

			WriteLogEvent(NStr("vi = 'Kết xuất dữ liệu. Đã tìm thấy lỗi trong dữ liệu được kết xuất';
								|ru = 'Выгрузка данных. Обнаружены ошибки в выгружаемых данных';
								|en = 'Data export. Errors are found in data to export'; fa = 'Data export. Errors are found in data to export';
								|it = 'Upload dati. Nei dati di upload sono stati trovati errori';
								|pl = 'Eksport danych. Wykryto błędy w eksportowanych danych';
								|tr = 'Veri dışa aktarımı. Dışa aktarılan verilerde hatalar tespit edildi'",
				Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorText);

			If Not SaaSOperations.DataSeparationEnabled() Then
				ErrorText = StrTemplate(
				NStr("vi = 'Trước khi chỉnh sửa, nên sao lưu dự phòng cơ sở thông tin bằng các công cụ của Hệ quản trị CSDL.
					 |
					 |%1';
					 |ru = 'Перед исправлением рекомендуется создать резервную копию информационной базы средствами СУБД.
					 |
					 |%1';
					 |en = 'Before fixing, create an infobase backup using the database management system.
					 |
					 |%1'; fa = 'Before fixing, create an infobase backup using the database management system.
					 |
					 |%1';
					 |it = 'Перед исправлением рекомендуется создать резервную копию информационной базы средствами СУБД.
					 |
					 |%1';
					 |pl = 'Before fixing, create an infobase backup using the database management system.
					 |
					 |%1';
					 |tr = 'Düzeltmeden önce, VYÖS kullanılarak infobase''in yedek kopyasının oluşturulmak önerilir.
					 |
					 |%1'"), ErrorText);
			EndIf;
			
			Raise ErrorText;

		EndIf;
		
	EndIf;
		
	Return ExportImportDataInternal.UploadCurAreaDataToArchive(ExportingParameters);
	
EndFunction

// Loads data from a zip archive with XML files.
//
// Parameters:
//  ArchiveName - String, UUID, Structure - file name, file ID, or file data obtained using ziparchives.Read the archive().
//  ImportParameters - Structure - containing data loading parameters:
//		* LoadableTypes - Array of MetadataObject - an array of metadata objects, data
//        	which you want to load from the archive. If the parameter value is set, all other
//        	data contained in the upload file will not be loaded. If the parameter value
//        	is not set, all data contained in the upload file will be loaded.
//      * UploadUsers - Boolean - upload information about users of the information database,
//      * UploadUserSettings_ - Boolean - ignored if Upload users = False.
//      * UserMatching - ValueTable - table with columns:
//        ** User - CatalogRef.Users - user ID from the archive.
//        ** ServiceUserID - UUID - ID of the service user.
//        ** OldIBUserName - String - old name of the database user.
//        ** NewIBUserName - String - new name of the database user.
//    The structure can also contain additional keys that can be processed inside
//      arbitrary data loading handlers.
//
// Returns:		
//  Structure - With Fields:
//  * Warnings - Array of String - warnings to the user based on the download results.
//
Function DownloadCurAreaDataFromArchive(Val ArchiveName, Val ImportParameters) Export
	
	If Not CheckForRights() Then
		Raise NStr("vi = 'Không đủ quyền truy cập đế kết nhập dữ liệu';
					|ru = 'Недостаточно прав доступа для загрузки данных';
					|en = 'Insufficient rights for data import'; fa = 'Insufficient rights for data import';
					|it = 'Diritti di accesso insufficienti per il download dei dati';
					|pl = 'Niewystarczające uprawnienia dostępu do pobierania danych';
					|tr = 'Verileri içe aktarmak için erişim yetkileri yetersiz'");
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ExternalMonopolyMode = SaaSOperations.MonopolyModeIsSet();
	UseMultithreading = ExportImportDataInternal.UseMultithreading(ImportParameters);
	
	Try
		
		If Not ExternalMonopolyMode Then
			SaaSOperations.SetExclusiveLock();
		EndIf;
		
		ImportResult1 = ExportImportDataInternal.DownloadCurAreaDataFromArchive(
			ArchiveName, ImportParameters);
		
		If Not ExternalMonopolyMode Then
			SaaSOperations.RemoveExclusiveLock(UseMultithreading);
		EndIf;
		
		Return ImportResult1;
		
	Except
		
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo());
		
		WriteLogEvent(NStr("vi = 'Kết nhập dữ liệu từ tệp nén';
							|ru = 'Загрузка данных из архива';
							|en = 'Data import from archive'; fa = 'Data import from archive';
							|it = 'Download dei dati dal file';
							|pl = 'Pobieranie danych z archiwum';
							|tr = 'Verileri arşivden içe aktar'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , ExceptionText);
		
		If Not ExternalMonopolyMode Then
			
			SaaSOperations.RemoveExclusiveLock(UseMultithreading);
			
			If UseMultithreading Then
				SaaSOperations.RemoveExclusiveLock();
			EndIf;
			
		EndIf;
		
		Raise ExceptionText;
		
	EndTry;
	
EndFunction

// Checks whether the file upload is compatible with the current database configuration.
//
// Parameters:
//  ArchiveName - String - path to the upload file.
//
// Returns: 
//	Boolean - True if the data from the archive can be loaded into the current configuration.
//
Function UploadingToArchiveIsCompatibleWithCurConfiguration(Val ArchiveName) Export
	
	Directory = GetTempFileName();
	CreateDirectory(Directory);
	Directory = Directory + GetPathSeparator();
	
	Archiver = New ZipFileReader(ArchiveName);
	
	Try
		
		UploadDescriptionElement = Archiver.Items.Find("DumpInfo.xml");
		
		If UploadDescriptionElement = Undefined Then
			Raise StrTemplate(NStr("vi = 'Trong tệp kết xuất không có tệp %1';
									|ru = 'В файле выгрузки отсутствует файл %1';
									|en = 'The %1 file is missing from the export file'; fa = 'The %1 file is missing from the export file';
									|it = 'Nel file di upload manca il file %1';
									|pl = 'Brak pliku %1 w pliku wyciągu';
									|tr = 'Dışa aktarma dosyasında %1 dosyası eksik'"), "DumpInfo.xml");
		EndIf;
		
		Archiver.Extract(UploadDescriptionElement, Directory, ZIPRestoreFilePathsMode.Restore);
		
		UploadDescriptionFile = Directory + "DumpInfo.xml";
		
		UploadInformation = ExportImportDataInternal.ReadXDTOObjectFromFile(
			UploadDescriptionFile, XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo"));
		
		Result = ExportImportDataInternal.UploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation)
			And ExportImportDataInternal.UploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(UploadInformation);
		
		DeleteFiles(Directory);
		Archiver.Close();
		
		Return Result;
		
	Except
		
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo());
		
		DeleteFiles(Directory);
		Archiver.Close();
		
		Raise ExceptionText;
		
	EndTry;
	
EndFunction

// Writes an object to a file.
//
// Parameters:
//	Object - Arbitrary - the object being recorded.
//	FileName - String - file path.
//	Serializer - XDTOSerializer - serializer.
//
Procedure WriteObjectToFile(Val Object, Val FileName, Serializer = Undefined) Export
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	
	ExportImportDataInternal.WriteObjectToStream(Object, WriteStream, Serializer);
	
	WriteStream.Close();
	
EndProcedure

// Returns an object from a file.
//
// Parameters:
//	FileName - String - file path.
//
// Returns:
//	Arbitrary - an object containing the read data
//
Function ReadObjectFromFile(Val FileName) Export
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(FileName);
	ReaderStream.MoveToContent();
	
	Object = ExportImportDataInternal.ReadObjectFromStream(ReaderStream);
	
	ReaderStream.Close();
	
	Return Object;
	
EndFunction

#Region HandlingReferencesToTypesExcludedFromUnloading

// Complements the array of types excluded from the upload-upload
// It is intended for use in handlers when filling in the types of excluded uploads.
//
// Parameters:
// 	Types - Array of FixedStructure
//	Type - MetadataObject - metadata object excluded from upload-upload
//	ActionWithLinks - String -  action option when a link to an object that is excluded from uploading is found
//		The following actions are supported:
//			Offloading and offloading of data.actionsselinkmineimend() - no action will be performed  
//			Offloading and offloading of data.Clean up actionsreferences() - the link to the non-paged object will be cleared  
//			Offloading and offloading of data.actionsexlink to reload object() - the object containing the link will not be unloaded
//		  
// Example of use:
//  Procedure for filling in the types of excluded unloads(Types) Export
//		Offloading and offloading of data.To complement the type of the excluded from the load of the load(
//			Types,
//			Metadata.Catalogs.Historyproke and correct the linked files,
//			Offloading and offloading of data.Actionsexlink to reload object());
//	End of the procedure 
//
Procedure AddTypeExcludedFromUploadingUploads(Types, Type, ActionWithLinks) Export

	If Not (ActionWithLinks = ActionWithLinksDoNotChange() 
		Or ActionWithLinks = ActionWithClearLinks() 
		Or ActionWithLinks = ActionWithLinksDoNotUnloadObject()) Then	
		
		Raise StrTemplate(
			NStr("vi = 'Đã tìm thấy thao tác không hỗ trợ ''%1'' khi tìm thấy tham chiếu đến kiểu ''%2'' được loại trừ khỏi kết xuất';
				|ru = 'Обнаружено неподдерживаемое действие ''%1'' при обнаружении ссылки на тип ''%2'' исключаемый из выгрузки';
				|en = 'Unsupported action ''%1'' was detected when a reference to the ''%2 '' type to be excluded from the export was detected'; fa = 'Unsupported action ''%1'' was detected when a reference to the ''%2 '' type to be excluded from the export was detected';
				|it = 'È stata rilevata una azione non supportata ''%1'' al rilevamento del collegamento al tipo ''%2'' escluso dall''upload';
				|pl = 'Wykryto nieobsługiwaną czynność ''%1'' przy wykryciu odnośnika do typu ''%2'' wykluczanego z eksportu';
				|tr = 'Dışa aktarmadan çıkarılan ''%2'' türünün bağlantısı tespit edildiğinde desteklenmeyen ''%1'' eylemi tespit edildi'"),
			ActionWithLinks,
			Type);	
					
	EndIf;
	
	TypeDetails = New Structure("Type, Action", Type, ActionWithLinks);
	Types.Add(
		New FixedStructure(TypeDetails))
	
EndProcedure
	
// Returns:
//  String -
Function ActionWithLinksDoNotChange() Export
	Return "DontChange";	
EndFunction

// Returns:
//  String -
Function ActionWithClearLinks() Export
	Return "Clear";	
EndFunction

// Returns:
//  String -
Function ActionWithLinksDoNotUnloadObject() Export
	Return "NotExportObject";	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. You should use Data offloading.Unload the data from the current Plastic Archive
// Uploads data to a zip archive, from which they can later be uploaded
//  to another information database or data area using the function
//  Unloading of the data.Upload the data of the current Archive region().
//
// Parameters:
//  ExportingParameters - Structure - containing data upload parameters:
//		* TypesToExport - Array of MetadataObject - array of metadata objects whose data needs to be archived
//      * UnloadUsers - Boolean - to upload information about users of the information base,
//      * ExportUserSettings - Boolean - ignored if Unloaded users = False.
//    Also, the structure may contain additional keys that can be processed inside
//      arbitrary data upload handlers.
//
// Returns:
//	String - path to the upload file.
//
Function UploadDataToArchive(Val ExportingParameters) Export
	
	Return UploadCurAreaDataToArchive(ExportingParameters).FileName;
	
EndFunction

// Deprecated. You should use Data offloading.Upload the data of the current Archive region
// Downloads data from a zip archive with XML files.
//
// Parameters:
//  ArchiveName - String - full name of the data archive file,
//  ImportParameters - Structure - containing data loading parameters:
//		* LoadableTypes - Array of MetadataObject - an array of metadata objects, data
//        	which you want to load from the archive. If the parameter value is set, all other
//        	data contained in the upload file will not be loaded. If the parameter value
//        	is not set, all data contained in the upload file will be loaded.
//      * UploadUsers - Boolean - upload information about users of the information database,
//      * UploadUserSettings_ - Boolean - ignored if Upload users = False.
//      * UserMatching - ValueTable - table with columns:
//        ** User - CatalogRef.Users - user ID from the archive.
//        ** ServiceUserID - UUID - ID of the service user.
//        ** OldIBUserName - String - old name of the database user.
//        ** NewIBUserName - String - new name of the database user.
//    The structure can also contain additional keys that can be processed inside
//      arbitrary data loading handlers.
//
Procedure DownloadDataFromArchive(Val ArchiveName, Val ImportParameters) Export
	
	DownloadCurAreaDataFromArchive(ArchiveName, ImportParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Procedure PlaceErrorsOfExportedDataToTemporaryStorage(StorageAddress) Export 
	DataModelTypes = ExportImportDataAreas.GetAreaDataModelTypes();
	TypesOfSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	DataUploadErrors = DataUploadErrors(DataModelTypes, TypesOfSharedData);
	PutToTempStorage(DataUploadErrors, StorageAddress);
EndProcedure

// Parameters:
// 	DataModelTypes - Array of MetadataObject:
// 	TypesOfSharedData - FixedArray of MetadataObject:
// 	
// Returns:
// 	Array of String
Function DataUploadErrors(DataModelTypes, TypesOfSharedData) Export
	
	DataUploadErrors = New Array;
	
	Query = New Query;
	FileInfobase = Common.FileInfobase();

	RequestTextTemplateCheckLogger =
	"SELECT
	|	MIN(Table.Recorder) AS Recorder
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Recorder.Ref IS NULL
	|
	|HAVING
	|	NOT MIN(Table.Recorder) IS NULL";

	For Each UnloadedType In DataModelTypes Do

		If Not CommonCTL.IsRecordSet(UnloadedType) 
			Or CommonCTL.IsIndependentRecordSet(UnloadedType)
			Or CommonCTL.IsRecalculationRecordSet(UnloadedType) Then
			Continue;
		EndIf;

		FullName = UnloadedType.FullName();

		Query.Text = StrReplace(RequestTextTemplateCheckLogger, "&Table", FullName);

		Selection = Query.Execute().Select();

		If Selection.Next() And Not ValueIsFilled(Selection.Recorder) Then

			ErrorText = StrTemplate(
				NStr("vi = 'Đã tìm thấy các nguồn ghi không tồn tại trong bảng %1.
					 |Nên xóa các bản ghi có nguồn ghi không tồn tại.';
					 |ru = 'Обнаружены отсутствующие регистраторы в таблице %1.
					 |Рекомендуется выполнить удаление записей с отсутствующими регистраторами.';
					 |en = 'Missing recorders are found in the %1 table.
					 |We recommend that you delete records with missing recorders.'; fa = 'Missing recorders are found in the %1 table.
					 |We recommend that you delete records with missing recorders.';
					 |it = 'Sono stati rilevati registratori mancanti nella tabella %1.
					 |Si consiglia di eseguire l''eliminazione delle registrazioni con registratori mancanti.';
					 |pl = 'Wykryto brakujące rejestratory w tabeli %1.
					 |Zaleca się wykonanie usunięcia wpisów z brakującymi rejestratorami.';
					 |tr = '%1 tablosunda eksik kaydediciler tespit edildi.
					 |Kaydedicileri eksik olan kayıtların silinmesi tavsiye edilir.'"), FullName) + " ";
			DataUploadErrors.Add(ErrorText);

		EndIf;

	EndDo;

	QueryTextTemplateCheckingForDuplicateDimensions = 
	"SELECT
	|	TRUE
	|FROM
	|	(SELECT TOP 1
	|		&TableFields
	|	FROM
	|		&RegisterTable AS RegisterTable
	|	
	|	GROUP BY
	|	&TableFields
	|	
	|	HAVING
	|		COUNT(*) > 1) AS NestedQuery";
	
	For Each DataModelType In DataModelTypes Do
		
		FullName = DataModelType.FullName();

		If CommonCTL.IsInformationRegister(DataModelType) Then
			
			CheckForDuplicateRecords = FileInfobase;
			If Not FileInfobase Then
				CheckForDuplicateRecords = DataModelType.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate
				And DataModelType.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition;  
			EndIf;
			
			If Not CheckForDuplicateRecords Then
				Continue;
			EndIf;
						
			Dimensions = New Array;
			
			If DataModelType.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
				
				Dimensions.Add("RegisterTable.Period");
				
				If DataModelType.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
					Dimensions.Add("RegisterTable.Recorder");				
				EndIf;
				
			EndIf;
			
			For Each MetadataDimensions In DataModelType.Dimensions Do
				Dimensions.Add("RegisterTable" + "." + MetadataDimensions.Name);
			EndDo;
			
			If Not ValueIsFilled(Dimensions) Then
				Continue;
			EndIf;
			
			Query.Text = StrReplace(QueryTextTemplateCheckingForDuplicateDimensions, "&RegisterTable", FullName);
			Query.Text = StrReplace(Query.Text, "&TableFields", StrConcat(Dimensions, ", "));
			
			If Not Query.Execute().IsEmpty() Then
				ErrorText = StrTemplate(
					NStr("vi = 'Đã tìm thấy dữ liệu trùng lặp trong bảng %1.
					|Nên xóa các bản ghi bị trùng.';
					|ru = 'Обнаружено дублирование данных в таблице %1.
					|Рекомендуется выполнить удаление дублирующихся записей.';
					|en = 'Duplicate data is found in the %1 table.
					|We recommend that you delete duplicate records.'; fa = 'Duplicate data is found in the %1 table.
					|We recommend that you delete duplicate records.';
					|it = 'Rilevati dati duplicati nella tabella %1.
					|Si consiglia di eliminare le registrazioni duplicate.';
					|pl = 'Wykryto duplikowanie danych w tabeli %1.
					|Zalecane jest wykonanie usunięcia duplikowanych wpisów.';
					|tr = '%1 tablosunda yinelenen veriler tespit edildi.
					|Yinelenen girişlerin silinmesi tavsiye edilir.'"),
					FullName) + " ";
				DataUploadErrors.Add(ErrorText);
			EndIf;
			
		EndIf;
		
	EndDo; 

	For Each TypeOfSharedData In TypesOfSharedData Do

		Try
			ExportImportSharedData.BeforeUnloadingType(
				Undefined, 
				Undefined, 
				TypeOfSharedData, 
				False);
		Except
			DataUploadErrors.Add(CloudTechnology.ShortErrorText(ErrorInfo()));
		EndTry;

	EndDo;
	
	For Each MetadataNotIncludedInExchangePlanError In MetadataErrorsNotIncludedInExchangePlan(DataModelTypes, False) Do
		DataUploadErrors.Add(MetadataNotIncludedInExchangePlanError);
	EndDo;
			
	Return DataUploadErrors;

EndFunction

// Checks that the transferred metadata is included in the Application Migration exchange plan
// 
// Parameters:
//  DataModelTypes - Array of MetadataObject - Data Model Types:
// * Name - String -
// * Dimensions - Array of MetadataObject -
// ConsiderAddedInExtension - Boolean - Enables/disables validation for extension metadata objects
// 
// Returns:
//  Array of String - Textual Presentations Of errors
Function MetadataErrorsNotIncludedInExchangePlan(DataModelTypes, ConsiderAddedInExtension = True) Export
	
	Errors = New Array;
	TypesToExclude = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
		
	For Each TypeOfSharedData In DataModelTypes Do
	
		If Metadata.ExchangePlans.ApplicationsMigration.Content.Contains(TypeOfSharedData)
			Or Metadata.ScheduledJobs.Contains(TypeOfSharedData)
			Or Metadata.ExternalDataSources.Contains(TypeOfSharedData)
			Or Metadata.IntegrationServices.Contains(TypeOfSharedData)
			Or Metadata.ExchangePlans.Contains(TypeOfSharedData) 
			Or (Not ConsiderAddedInExtension And TypeOfSharedData.ConfigurationExtension() <> Undefined)
			Or TypesToExclude.Find(TypeOfSharedData) <> Undefined Then
			Continue;
		EndIf;
			
		ModuleName = "ExportImportDataOverridable.OnFillTypesExcludedFromExportImport";
		ErrorTextTemplate = NStr("vi = 'Đối tượng siêu dữ liệu (metadata) %1 không được bao gồm trong kế hoạch trao đổi Di chuyển ứng dụng. 
			|Cần đưa nó vào kế hoạch trao đổi Di chuyển các ứng dụng có cấm tự động ghi nhận. 
			|Trong trường hợp, nếu không cần kết xuất đối tượng thì cần thêm bổ sung nó vào các đối tượng bị loại trừ khỏi kết xuất. Xem thêm %2';
			|ru = 'Объект метаданных %1 не включен в план обмена Миграция приложений. 
			|Его необходимо включить в состав плана обмена Миграция приложений с запрещенной авторегистрацией. 
			|В случае, если объект не должен выгружаться, необходимо дополнительно добавить его в исключаемые из выгрузки. См. %2';
			|en = 'The %1 metadata object is not included in the ""Application migration"" exchange plan. 
			|Include it in the ""Application migration"" exchange plan with the disabled autoregistration. 
			|If the object must not be exported, exclude it from the export. For more information, see %2'; fa = 'The %1 metadata object is not included in the ""Application migration"" exchange plan. 
			|Include it in the ""Application migration"" exchange plan with the disabled autoregistration. 
			|If the object must not be exported, exclude it from the export. For more information, see %2';
			|it = 'Объект метаданных %1 не включен в план обмена Миграция приложений. 
			|Его необходимо включить в состав плана обмена Миграция приложений с запрещенной авторегистрацией. 
			|В случае, если объект не должен выгружаться, необходимо дополнительно добавить его в исключаемые из выгрузки. См. %2';
			|pl = 'The %1 metadata object is not included in the ""Application migration"" exchange plan. 
			|Include it in the ""Application migration"" exchange plan with the disabled autoregistration. 
			|If the object must not be exported, exclude it from the export. For more information, see %2';
			|tr = '%1 meta veri nesnesi, Uygulama Geçişi değişim planına dahil değil. 
			|Otomatik kaydı devre dışı bırakılmış uygulamalar için değişim planına dahil edilmelidir. 
			|Bir nesnenin boşaltılmaması gerekiyorsa, onu boşaltma dışında bırakılanlara ek olarak eklemelisiniz. Bkz. %2'");
		Errors.Add(StrTemplate(ErrorTextTemplate, TypeOfSharedData.FullName(), ModuleName));
		
	EndDo;
	
	Return Errors;
	
EndFunction

Function NeedToCountObjectsNumber(ExportImportParameters) Export
	
	Return ItIsNecessaryToRecordExportImportDataAreaState(ExportImportParameters)
		Or ExportImportDataInternal.UseMultithreading(ExportImportParameters);
	
EndFunction

Function ItIsNecessaryToRecordExportImportDataAreaState(ExportImportParameters) Export
	
	If Not ValueIsFilled(ExportImportParameters) Then
		Return False;
	EndIf;
	
	StateID = Undefined;
	ExportImportParameters.Property("StateID", StateID);
	
	Return ValueIsFilled(StateID);
	
EndFunction

Function DataAreaExportImportState(StateID) Export
	
	Query = New Query("SELECT
	|	ExportImportDataAreasStates.DataAreaAuxiliaryData AS DataArea,
	|	ExportImportDataAreasStates.importDataArea AS importDataArea,
	|	ExportImportDataAreasStates.EndPercentage,
	|	ExportImportDataAreasStates.EstimatedEndDate,
	|	ExportImportDataAreasStates.NameOfMetadataObjectBeingProcessed,
	|	ExportImportDataAreasStates.ProcessedObjectsCount1,
	|	ExportImportDataAreasStates.ProcessedObjectsUpToCurrentMetadataObject,
	|	ExportImportDataAreasStates.StartDate,
	|	ExportImportDataAreasStates.ObjectProcessingStartedDate <> DATETIME(1, 1, 1) AS
	|		ObjectProcessingStarted,
	|	ExportImportDataAreasStates.ObjectProcessingEndDate <> DATETIME(1, 1, 1) AS
	|		ObjectProcessingCompleted,
	|	ExportImportDataAreasStates.ActualEndDate AS ActualEndDate
	|FROM
	|	InformationRegister.ExportImportDataAreasStates AS ExportImportDataAreasStates
	|WHERE
	|	ExportImportDataAreasStates.Id = &Id");
	
	Query.SetParameter("Id", StateID);

	ResultTable2 = Query.Execute().Unload();
	
	If Not ValueIsFilled(ResultTable2) Then
		Return Undefined;		
	EndIf;
	
	Return Common.ValueTableToArray(ResultTable2)[0];
	
EndFunction

Function DataAreaExportImportStateView(DataAreaExportImportState, TimeZone = Undefined) Export
		
	If Not DataAreaExportImportState.ObjectProcessingStarted Then
		
		Return ExportImportDataClientServer.ExportImportDataAreaPreparationStateView(
			DataAreaExportImportState.importDataArea);
				
	ElsIf DataAreaExportImportState.ObjectProcessingCompleted Then
		
		If DataAreaExportImportState.importDataArea Then
			StatusPresentation = NStr("vi = 'Đanng thực hiện hoàn tất kết nhập dữ liệu.';
										|ru = 'Выполняется завершение загрузки данных.';
										|en = 'Completing the data import.'; fa = 'Completing the data import.';
										|it = 'Выполняется завершение загрузки данных.';
										|pl = 'Completing the data import.';
										|tr = 'Veri içe aktarma tamamlanması yapılıyor.'");
		Else
			StatusPresentation = NStr("vi = 'Đanng thực hiện hoàn tất kết xuất dữ liệu.';
										|ru = 'Выполняется завершение выгрузки данных.';
										|en = 'Completing the data export.'; fa = 'Completing the data export.';
										|it = 'Выполняется завершение выгрузки данных.';
										|pl = 'Completing the data export.';
										|tr = 'Veri dışa aktarma tamamlanması yapılıyor.'");
		EndIf;	
		
	Else
		
		StateViewParts = New Array();
		
		If DataAreaExportImportState.importDataArea Then
			FirstPartOfStateRepresentation = NStr("vi = 'Đang thực hiện kết nhập dữ liệu.';
													|ru = 'Выполняется загрузка данных.';
													|en = 'Importing data.'; fa = 'در حال ورود اطلاعات.';
													|it = 'Выполняется загрузка данных.';
													|pl = 'Importing data.';
													|tr = 'Veri içe aktarma yapılıyor.'");
		Else
			FirstPartOfStateRepresentation = NStr("vi = 'Đang thực hiện kết xuất dữ liệu.';
													|ru = 'Выполняется выгрузка данных.';
													|en = 'Exporting data.'; fa = 'در حال خروج اطلاعات.';
													|it = 'Выполняется выгрузка данных.';
													|pl = 'Exporting data.';
													|tr = 'Veri dışa aktarma yapılıyor.'");
		EndIf;
		
		StateViewParts.Add(FirstPartOfStateRepresentation);		
		
		EstimatedEndDate = DataAreaExportImportState.EstimatedEndDate;
		If ValueIsFilled(EstimatedEndDate) Then
			
			If TimeZone = Undefined Then 
				TimeZone = SessionTimeZone();
			EndIf;
			
			EstimatedEndDateInLocalTime = ToLocalTime(EstimatedEndDate, TimeZone);
			CurrentDateInLocalTime = ToLocalTime(CurrentUniversalDate(), TimeZone);
			
			If BegOfDay(CurrentDateInLocalTime) = BegOfDay(EstimatedEndDateInLocalTime) Then
				EndDatePresentationTemplate = NStr("vi = 'Thời gian hoàn thành dự kiến %1.';
													|ru = 'Расчетное время завершения %1.';
													|en = 'Estimated completion time: %1.'; fa = 'Estimated completion time: %1.';
													|it = 'Расчетное время завершения %1.';
													|pl = 'Estimated completion time: %1.';
													|tr = 'Tahmini tamamlama süresi %1.'");
				FormatString = "DF='HH:mm';";
			Else
				EndDatePresentationTemplate = NStr("vi = 'Ngày hoàn thành dự kiến %1.';
													|ru = 'Расчетная дата завершения %1.';
													|en = 'Estimated completion date: %1.'; fa = 'Estimated completion date: %1.';
													|it = 'Расчетная дата завершения %1.';
													|pl = 'Estimated completion date: %1.';
													|tr = 'Tahmini tamamlama tarihi %1.'");
				FormatString = "DF='dd MMMM HH:mm';";
			EndIf;

			StateRepresentationSecondPart = StrTemplate(
				EndDatePresentationTemplate,
				Format(EstimatedEndDateInLocalTime, FormatString));
			
			StateViewParts.Add(StateRepresentationSecondPart);			
		
		EndIf;

		StatusPresentation = StrConcat(StateViewParts, " ");
		
	EndIf;
		
	Return StatusPresentation;
	
EndFunction

Function ExportImportDataAreaEndPercentage(DataAreaExportImportState) Export
		
	If DataAreaExportImportState = Undefined 
		Or Not DataAreaExportImportState.ObjectProcessingStarted
		Or DataAreaExportImportState.ObjectProcessingCompleted Then	
		Return Undefined;
	EndIf;
	
	Return DataAreaExportImportState.EndPercentage;
			
EndFunction

#EndRegion

#Region Private

// Checks whether the "data Administration" permission is available"
//
// Returns:
//	Boolean - The truth, if there is, a Lie - otherwise.
//
Function CheckForRights()
	
	Return AccessRight("DataAdministration", Metadata);
	
EndFunction

#EndRegion