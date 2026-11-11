////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Adds to the list of Handlers of the procedure-the update handlers required by this subsystem.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   Handlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure RegisterUpdateHandlers(Handlers) Export
	
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export

	Parameters.Insert("UnloadingLoadingDataLoadingAborted", CommonServerCallCTL.DownloadAborted());
	
EndProcedure

Function StartLoadingCurAreaDataFromArchive(Val FileData, Val ImportParameters, Val ResultAddress = Undefined) Export 
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ImportParameters.Insert(
		"LoadableTypes",
		LoadableTypes(BackupType(ImportParameters)));
		
	Handlers = DataProcessors.ExportImportDataDataImportHandlersManager.Create();
	Handlers.Initialize();
	
	Container = DataProcessors.ExportImportDataContainerManager.Create();
	Container.InitializeDownload(FileData, ImportParameters);	
	
	If ImportParameters.ItIsPossibleToContinueLoadingProcedure Then
		RefsMap = ContinueLoadingProcedure(ImportParameters, Container, Handlers);
	Else
		RefsMap = StartImportProcedure(ImportParameters, Container, Handlers);
	EndIf;
	
	ImportResult1 = New Structure(
		"Warnings, RefsMap",
		Container.Warnings(),
		RefsMap);
	
	If ResultAddress <> Undefined Then
		PutToTempStorage(ImportResult1, ResultAddress);
	EndIf;
	
	Return ImportResult1;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Uploading/uploading data

// Remove temporary file, error deleting ignored.
//
// Parameters:
//  Path - String - path to the file to delete.
//
Procedure DeleteTempFile(Val Path) Export
	
	Info = New File(Path);
	If Not Info.Exists() Then
		Return;
	EndIf;
	
	Try
		DeleteFiles(Path);
	Except
		WriteLogEvent(NStr("vi = 'Xóa tệp';
							|ru = 'Удаление файла';
							|en = 'Delete file'; fa = 'حذف فایل';
							|it = 'Cancellazione file';
							|pl = 'Usuń plik';
							|tr = 'Dosya silme'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			ErrorInfo().Description);
	EndTry;
	
EndProcedure

// Returns an array of all metadata objects contained in the configuration.
//  It is used to start uploading and loading data in configurations that do not contain BSP.
//
// Returns:
//   Array of MetadataObject - types.
//
// Example:
//  Loading Parameter = New Structure();
//  The loading parameter.Insert("Unloaded types", Unloaded Service data.Get Configuration types());
//  The loading parameter.Insert("Unload users", True);
//  The loading parameter.Insert("Unload User settings", True);
//  File Name = Offloading and offloading of data.Unload the data of the current Plastic Archive(Upload parameter);
//
//  Loading Parameters = New Structure();
//  Loading parameters.Insert("Loadable types", unloaded and unloaded Service data.Get Configuration types());
//  Loading parameters.Insert("Upload Users", True);
//  Loading parameters.Insert("Upload User settings", True);
//  Unloaded the unloaded data.Upload the data of the current Archive region(File name, upload parameters);
//
Function GetAllConfigurationTypes() Export
	
	ArrayOfMetadataCollections = New Array();
	
	FillCollectionsOfConstants(ArrayOfMetadataCollections);
	PopulateCollectionsOfReferenceObjects(ArrayOfMetadataCollections);
	PopulateRecordsetCollections(ArrayOfMetadataCollections);
	
	Return ArrayOfMetadataCollections;
	
EndFunction

// Uploads data to the folder.
//
// Parameters:
//	ExportingParameters - Structure - containing data upload parameters.
//		Keys:
//			Unloaded Types - An array of object metadata - an array of metadata objects
//				whose data you want to upload to the archive,
//			Upload users - Boolean - upload information about users of the information base,
//			Unloaded User settings - Boolean - ignored if Unloaded users = False.
//			Also, the structure may contain additional keys that can be processed inside
//				arbitrary data upload handlers.
//
// Returns:		
//  Structure - With Fields:
//  * FileName - String - the archive file name
//  * Warnings - Array of String - warnings to the user based on the results of the upload.
//
Function UploadCurAreaDataToArchive(Val ExportingParameters) Export
	
	Container = DataProcessors.ExportImportDataContainerManager.Create();
	Container.InitializeUpload(ExportingParameters);
	
	Serializer = XdtoSerializerWithTypeAnnotation();
	
	Handlers = DataProcessors.ExportImportDataDataExportHandlersManager.Create();
	Handlers.Initialize(Container);
	
	Handlers.BeforeExportData(Container);
	
	SaveUploadDescription(Container);
	
	DataProcessors.ExportImportDataInfobaseDataExportManager.UploadDatabaseData(
		Container, Handlers, Serializer);
	
	If ExportingParameters.UnloadUsers Then
		
		ExportImportInfobaseUsers.UnloadUsersOfInformationBase(Container);
		
		If ExportingParameters.ExportUserSettings Then
			
			DataProcessors.ExportImportDataUserSettingsExportManager.UploadInformationDatabaseUserSettings(
				Container, Handlers, Serializer);
			
		EndIf;
		
	EndIf;
	
	UnloadConfigurationDiagram(Container, ExportingParameters);
	
	Handlers.AfterExportData(Container);
	
	Return New Structure("FileName, Warnings",
		Container.FinalizeUpload(),
		Container.Warnings());
	
EndFunction

// Loads data from the folder.
//
// Parameters:
//	FileData - String, UUID, Structure - file name, file ID, or file data obtained using ziparchives.Read the archive().
//	ImportParameters - See ExportImportData.DownloadCurAreaDataFromArchive.ImportParameters.
//
// Returns:
//  Structure:
//  * Warnings - Array of String - warnings to the user based on the download results.
//
Function DownloadCurAreaDataFromArchive(Val FileData, Val ImportParameters) Export
	
	DataSeparationEnabled = Common.DataSeparationEnabled();

	SkipExtensionsRestoring = ImportParameters.Property("SkipExtensionsRestoring") 
		And ImportParameters.SkipExtensionsRestoring;

	HashSumOfSource = HashSumOfSource(ReadArchive(FileData));
	ImportParameters.Insert("HashSumOfSource", HashSumOfSource);
	
	HashSumOfParameters = HashSumOfParameters(ImportParameters);
	ImportParameters.Insert("HashSumOfParameters", HashSumOfParameters);
	
	ItIsPossibleToContinueLoadingProcedure = ItIsPossibleToContinueLoadingProcedure(
		HashSumOfSource,
		HashSumOfParameters);	
	ImportParameters.Insert("ItIsPossibleToContinueLoadingProcedure", ItIsPossibleToContinueLoadingProcedure);
		
	If Not (ItIsPossibleToContinueLoadingProcedure Or IsDifferentialBackup(ImportParameters)) Then
		
		SaaSOperations.ClearAreaData(Not SkipExtensionsRestoring, False);
			
		If Not SkipExtensionsRestoring Then
			
			ExtensionData_ = Undefined;
			ImportParameters.Property("ExtensionData_", ExtensionData_);
			
			If ValueIsFilled(ExtensionData_) Then
				
				If DataSeparationEnabled Then
					RestoreAreaExtensions(ExtensionData_);
					RestorePlusExtensionsFromSM(ExtensionData_);
				Else
					RestoreInformationBaseExtensions(ExtensionData_);
				EndIf;
				
			EndIf;
			
		EndIf;
			
	EndIf;
	
	If UseMultithreading(ImportParameters) Then
		SaaSOperations.SetExclusiveLock(True);
	EndIf;
		
	If Not SkipExtensionsRestoring 
		And ExtensionsSaaS.ThereAreInstalledExtensionsModifyingDataStructure() Then
		ImportResult1 = LoadCurAreaDataFromArchiveInBackground(FileData, ImportParameters);	
	Else
		ImportResult1 = StartLoadingCurAreaDataFromArchive(FileData, ImportParameters);
	EndIf;
	
	Return ImportResult1;

EndFunction

Procedure RestoreInformationBaseExtensions(ExtensionData_) Export
			
	RecoveryExtensions = Undefined;	
	
	If ExtensionData_.Property("RecoveryExtensions", RecoveryExtensions) Then
		
		RestoreExtensions(RecoveryExtensions);
			
	EndIf;
	
	ExtensionsFrameForRecovery = Undefined;
	
	If ExtensionData_.Property("ExtensionsFrameForRecovery", ExtensionsFrameForRecovery)  Then
		
		RestoreExtensionFrames(ExtensionsFrameForRecovery);
		
	EndIf;
		
EndProcedure

Procedure RestorePlusExtensions(PlusExtensions) Export
	ModulePlusService = GetPlusModule();
	
	If Not ModulePlusService = Undefined Then
		ModulePlusService.RestoreExtensions(PlusExtensions);
	EndIf;
EndProcedure

// Compares whether the upload is compatible with the current configuration.
//
// Parameters:
//	UploadInformation - XDTODataObject - see the procedure "Save the Upload description".
//
// Returns:
//	Boolean - True if it matches.
//
Function UploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation) Export
	
	ConfigurationName = UploadInformation.Configuration.Name;
	Return AppTypesServer.AppTypePropertiesByName(ConfigurationName, False) <> Undefined;
	
EndFunction

// Compares whether the configuration version is compatible with the uploaded version.
//
// Parameters:
//	UploadInformation - XDTODataObject - see the procedure "Save the Upload description".
//
// Returns:
//	Boolean - True if it matches.
//
Function UploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(UploadInformation) Export
	
	Return UploadInformation.Configuration.Version = Metadata.Version;
	
EndFunction

// Compares whether the upload is compatible with the current configuration.
//
// Parameters:
//	UploadInformation - XDTODataObject - see the procedure "Save the Upload description".
//
Procedure CheckIfUploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation) Export
	
	If Not UploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation) Then
		Raise ErrorTextExportNotCompatibleWithCurrentConfiguration(UploadInformation);
	EndIf;
	
EndProcedure

// Compares whether the configuration version is compatible with the uploaded version.
//
// Parameters:
//	UploadInformation - XDTODataObject - see the procedure "Save the Upload description".
//  StrictVerification - Boolean - if True, then checks for equality, if False, then the version in the upload must be less than or equal to the Cur
//
Procedure CheckIfUploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(Val UploadInformation, Val StrictVerification = False) Export
	
	UnloadingIsCompatible = False;
	If StrictVerification Then
		UnloadingIsCompatible = UploadInformation.Configuration.Version = Metadata.Version
	Else
		UnloadingIsCompatible = CommonClientServer.CompareVersions(UploadInformation.Configuration.Version, Metadata.Version) <= 0;
	EndIf;
	
	If Not UnloadingIsCompatible Then
		Raise ErrorTextExportNotCompatibleWithCurrentConfigurationVersion(UploadInformation);
	EndIf;
	
EndProcedure

// Error text The upload is not compatible with the Cur configuration.
// 
// Parameters:
//  UploadInformation - XDTODataObject - see the procedure "Save the Upload description".
// 
// Returns:
//  String - error text
Function ErrorTextExportNotCompatibleWithCurrentConfiguration(UploadInformation) Export
	
	Return StrTemplate(NStr("vi = 'Không thể kết nhập dữ liệu từ tệp, bởi vì tệp đã được kết xuất từ cấu hình khác (tệp được kết xuất từ cấu hình %1 và không thể kết nhập vào cấu hình %2).';
							|ru = 'Невозможно загрузить данные из файла, т.к. файл был выгружен из другой конфигурации (файл выгружен из конфигурации %1 и не может быть загружен в конфигурацию %2).';
							|en = 'Cannot import data from a file as the file was exported from another configuration (the file is exported from configuration %1 and cannot be imported to configuration%2).'; fa = 'Cannot import data from a file as the file was exported from another configuration (the file is exported from configuration %1 and cannot be imported to configuration%2).';
							|it = 'Невозможно загрузить данные из файла, т.к. файл был выгружен из другой конфигурации (файл выгружен из конфигурации %1 и не может быть загружен в конфигурацию %2).';
							|pl = 'Cannot import data from a file as the file was exported from another configuration (the file is exported from configuration %1 and cannot be imported to configuration%2).';
							|tr = 'Dosya başka bir yapılandırmadan yüklendiği için dosyadan veri içe aktarılamıyor (dosya %1 yapılandırmasından dışa aktarıldı ve %2 yapılandırmasına içe aktarılamıyor).'"),
		UploadInformation.Configuration.Name,
		Metadata.Name);
	
EndFunction

// Error text The upload is not compatible with the Cur version of the configuration.
// 
// Parameters:
//  UploadInformation - XDTODataObject - see the procedure "Save the Upload description".
// 
// Returns:
//  String - error text
Function ErrorTextExportNotCompatibleWithCurrentConfigurationVersion(UploadInformation) Export
	
	Return StrTemplate(NStr("vi = 'Không thể kết nhập dữ liệu từ tệp, vì tệp đã được kết xuất từ phiên bản khác của cấu hình (tệp được kết xuất từ cấu hình có phiên bản %1 và không thể được kết nhập vào cấu hình phiên bản %2).';
							|ru = 'Невозможно загрузить данные из файла, т.к. файл был выгружен из другой версии конфигурации (файл выгружен из конфигурации версии %1 и не может быть загружен в конфигурацию версии %2).';
							|en = 'Cannot import data from a file as the file was exported from another configuration version (the file is exported from configuration version %1 and cannot be imported to configuration version %2).'; fa = 'Cannot import data from a file as the file was exported from another configuration version (the file is exported from configuration version %1 and cannot be imported to configuration version %2).';
							|it = 'Невозможно загрузить данные из файла, т.к. файл был выгружен из другой версии конфигурации (файл выгружен из конфигурации версии %1 и не может быть загружен в конфигурацию версии %2).';
							|pl = 'Cannot import data from a file as the file was exported from another configuration version (the file is exported from configuration version %1 and cannot be imported to configuration version %2).';
							|tr = 'Dosya başka bir yapılandırma sürümünden yüklendiği için dosyadan veri içe aktarılamıyor (dosya %1 yapılandırma sürümünden dışa aktarıldı ve %2 yapılandırma sürümüne içe aktarılamıyor).'"),
		UploadInformation.Configuration.Version,
		Metadata.Version);
	
EndFunction

// The data type of the file that stores the name of the column with the source link.
//
// Returns:
//	String - type name.
//
Function DataTypeForColumnNameOfValueTable() Export
	
	Return "1cfresh\ReferenceMapping\ValueTableColumnName";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// File types and upload/upload directory structure

// Returns the name of the file type with information about the upload.
// Returns:
//  String - name of the type.
Function DumpInfo() Export
	Return "DumpInfo";
EndFunction

// Returns the name of the file type with information about the composition of the upload.
// Returns:
//  String - name of the type.
Function PackageContents() Export
	Return "PackageContents";
EndFunction

// Returns the name of the file type with information about link mapping.
// Returns:
//  String - name of the type.
Function ReferenceMapping() Export
	Return "ReferenceMapping";
EndFunction

// Returns the name of the file type with information about link re-creation.
// Returns:
//  String - name of the type.
Function ReferenceRebuilding() Export
	Return "ReferenceRebuilding";
EndFunction

// Returns the name of the file type that stores serialized database data.
// Returns:
//  String - name of the type.
Function InfobaseData() Export
	Return "InfobaseData";
EndFunction

// Returns the name of the file type that stores serialized changes to the information database data.
// Returns:
//  String - name of the type.
Function InfobaseDataChanges() Export
	Return "InfobaseDataChanges";
EndFunction

// Returns the name of the file type that stores serialized data in the sequence.
// Returns:
//	String - name of the type.
Function SequenceBoundary() Export
	Return "SequenceBoundary";
EndFunction

// Returns the name of the file type that stores serialized user settings data.
// Returns:
//	String - name of the type.
Function UserSettings() Export
	Return "UserSettings";
EndFunction

// Returns the name of the file type that stores serialized user data.
// Returns:
//	String - name of the type.
Function Users() Export
	Return "Users";
EndFunction

// Returns the name of the file type that stores arbitrary data.
// Returns:
//	String - name of the type.
Function CustomData() Export
	Return "CustomData";
EndFunction

// This function generates rules for the directory structure in the upload.
//
// Returns:
//	FixedStructure - directory structure:
//	 * DumpInfo - String
//	 * Digest - String
//	 * Extensions - String
//	 * CustomExtensions - String
//	 * DumpWarnings - String
//	 * PackageContents - String
//	 * ReferenceMapping - String
//	 * ReferenceRebuilding - String
//	 * InfobaseData - String
//	 * SequenceBoundary - String
//	 * Users - String
//	 * UserSettings - String
//	 * CustomData - String
Function RulesForCreatingDirectoryStructure() Export
	
	RootDirectory1 = "";
	DataDirectory = "Data";
	
	Result = New Structure();
	Result.Insert(DumpInfo(), RootDirectory1);
	Result.Insert(Digest(), RootDirectory1);
	Result.Insert(Extensions(), RootDirectory1);
	Result.Insert(CustomExtensions(), RootDirectory1);
	Result.Insert(DumpWarnings(), RootDirectory1);
	Result.Insert(ApplicationTypes(), RootDirectory1);
	Result.Insert(PackageContents(), RootDirectory1);
	Result.Insert(ReferenceMapping(), ReferenceMapping());
	Result.Insert(ReferenceRebuilding(), ReferenceRebuilding());
	Result.Insert(InfobaseData(), DataDirectory);
	Result.Insert(SequenceBoundary(), DataDirectory);
	Result.Insert(Users(), RootDirectory1);
	Result.Insert(UserSettings(), UserSettings());
	Result.Insert(CustomData(), CustomData());
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns the types of files that support replacement links.
//
// Returns:
//	Array of String - array of file types.
//
Function FileTypesThatSupportLinkReplacement() Export
	
	Result = New Array();
	
	Result.Add(InfobaseData());
	Result.Add(SequenceBoundary());
	Result.Add(UserSettings());
	
	Return Result;
	
EndFunction

// Returns the name of the type that will be used in the xml file for the specified metadata object
// Used when searching for and replacing links when loading, when modifying the current-config schema when writing.
// 
// Parameters:
//  Value - CatalogRef, DocumentRef, MetadataObject - a metadata object or link.
//
// Returns:
//  String - A string of the form AccountingRegisterRecordSet.Self-supporting, describing the metadata object.
//
Function XMLRefType(Val Value) Export
	
	If TypeOf(Value) = Type("MetadataObject") Then
		MetadataObject = Value;
		ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		Ref = ObjectManager.GetRef();
	Else
		MetadataObject = Value.Metadata();
		Ref = Value;
	EndIf;
	
	If CommonCTL.IsRefData(MetadataObject) Then
		
		Return XDTOSerializer.XMLTypeOf(Ref).TypeName;
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Lỗi khi xác định XML kiểu tham chiếu dành cho đối tượng %1: đối tượng không phải là kiểu tham chiếu';
								|ru = 'Ошибка при определении XML типа ссылки для объекта %1: объект не является ссылочным';
								|en = 'An error occurred when determining an XML reference type for the %1 object: this is not a reference object'; fa = 'An error occurred when determining an XML reference type for the %1 object: this is not a reference object';
								|it = 'Errore durante la definizione del tipo XML per un oggetto%1: l''oggetto non è un riferimento';
								|pl = 'Błąd przy określeniu XML typu odnośnika dla obiektu%1: obiekt nie jest linkowym';
								|tr = '%1 nesnesi için XML bağlantı türü belirlenirken hata oluştu: nesne bağlantı değil'"),
			MetadataObject.FullName());
		
	EndIf;
	
EndFunction

// Returns the metadata object for the field type.
//
// Parameters:
//	FieldType - Type - field type
//
// Returns:
//	MetadataObject - metadata object.
//
Function MetadataObjectByRefType(Val FieldType) Export
	
	BusinessProcessesRoutePointsRefs = BusinessProcessesRoutePointsRefs();
	
	BusinessProcess = BusinessProcessesRoutePointsRefs.Get(FieldType);
	If BusinessProcess = Undefined Then
		Ref = New(FieldType);
		RefMetadata = Ref.Metadata();
	Else
		RefMetadata = BusinessProcess;
	EndIf;
	
	Return RefMetadata;
	
EndFunction

// Returns the full list of configuration constants
//
// Returns:
//  Array of MetadataObject - metadata object.
//
Function AllConstants() Export
	
	ObjectsMetadata = New Array;
	FillCollectionsOfConstants(ObjectsMetadata);
	Return AllCollectionMetadata(ObjectsMetadata);
	
EndFunction

// Returns a complete list of reference configuration types
//
// Returns:
//  Array of MetadataObject
//
Function AllReferenceData() Export
	
	ObjectsMetadata = New Array;
	PopulateCollectionsOfReferenceObjects(ObjectsMetadata);
	Return AllCollectionMetadata(ObjectsMetadata);
	
EndFunction

// Returns a complete list of configuration record sets
//
// Returns:
//  Array of MetadataObject
//
Function AllRecordSets() Export
	
	ObjectsMetadata = New Array;
	PopulateRecordsetCollections(ObjectsMetadata);
	Return AllCollectionMetadata(ObjectsMetadata);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Reading/writing data

// Writes an object to the write stream.
//
// Parameters:
//	Object - Arbitrary - the object being recorded.
//	WriteStream - XMLWriter - writer thread.
//	Serializer - XDTOSerializer - serializer.
//
Procedure WriteObjectToStream(Val Object, WriteStream, Serializer = Undefined) Export
	
	If Serializer = Undefined Then
		Serializer = XDTOSerializer;
	EndIf;
	
	WriteStream.WriteStartElement(NameOfElementContainingObject());
	
	NamespacesPrefixes = NamespacesPrefixes();
	For Each NamespacesPrefix In NamespacesPrefixes Do
		WriteStream.WriteNamespaceMapping(NamespacesPrefix.Value, NamespacesPrefix.Key);
	EndDo;
	
	Serializer.WriteXML(WriteStream, Object, XMLTypeAssignment.Explicit);
	
	WriteStream.WriteEndElement();
	
EndProcedure

// Returns an object from a file.
//
// Parameters:
//	ReaderStream - XMLReader - the flow of reading.
//
// Returns:
//	Arbitrary - read object.
//
Function ReadObjectFromStream(ReaderStream) Export
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> NameOfElementContainingObject() Then
		
		Raise StrTemplate(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Đang chờ bắt đầu phần tử %1.';
								|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента %1.';
								|en = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.';
								|it = 'Errore di lettura XML. Formato errato di file. Atteso inizio dell''elemento %1.';
								|pl = 'Błąd odczytu XML. Nieprawidłowy format pliku. Jest oczekiwany początek elementu %1.';
								|tr = 'XML okuma hatası. Geçersiz dosya biçimi. %1 bileşenin başlangıcı bekleniyor.'"),
			NameOfElementContainingObject());
		
	EndIf;
	
	If Not ReaderStream.Read() Then
		Raise NStr("vi = 'Lỗi đọc XML. Đã tìm thấy kết thúc tệp.';
					|ru = 'Ошибка чтения XML. Обнаружено завершение файла.';
					|en = 'XML reading error. File end is detected.'; fa = 'XML reading error. File end is detected.';
					|it = 'Errore di lettura XML. Esecuzione file rilevata.';
					|pl = 'Błąd odczytu XML. Wykryto zakończenie pliku.';
					|tr = 'XML okuma hatası. Dosyanın sonlandırıldığı tespit edildi.'");
	EndIf;
	
	Object = XDTOSerializer.ReadXML(ReaderStream);
	
	Return Object;
	
EndFunction

// Reads the xdto Object from a file.
//
// Parameters:
//	FileName - String - full path to the file.
//	XDTOType - XDTOObjectType - type of the XDTO object.
//
// Returns:
//	XDTODataObject - the read object.
//
Function ReadXDTOObjectFromFile(Val FileName, Val XDTOType) Export
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(FileName);
	ReaderStream.MoveToContent();
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> NameOfElementContainingXDTOObject() Then
		
		Raise StrTemplate(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Đang chờ bắt đầu phần tử %1.';
								|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента %1.';
								|en = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.';
								|it = 'Errore di lettura XML. Formato errato di file. Atteso inizio dell''elemento %1.';
								|pl = 'Błąd odczytu XML. Nieprawidłowy format pliku. Jest oczekiwany początek elementu %1.';
								|tr = 'XML okuma hatası. Geçersiz dosya biçimi. %1 bileşenin başlangıcı bekleniyor.'"),
			NameOfElementContainingXDTOObject());
		
	EndIf;
	
	If Not ReaderStream.Read() Then
		Raise NStr("vi = 'Lỗi đọc XML. Đã tìm thấy kết thúc tệp.';
					|ru = 'Ошибка чтения XML. Обнаружено завершение файла.';
					|en = 'XML reading error. File end is detected.'; fa = 'XML reading error. File end is detected.';
					|it = 'Errore di lettura XML. Esecuzione file rilevata.';
					|pl = 'Błąd odczytu XML. Wykryto zakończenie pliku.';
					|tr = 'XML okuma hatası. Dosyanın sonlandırıldığı tespit edildi.'");
	EndIf;
	
	XDTODataObject = XDTOFactory.ReadXML(ReaderStream, XDTOType);
	
	ReaderStream.Close();
	
	Return XDTODataObject;
	
EndFunction

// Returns prefixes for commonly used namespaces.
//
// Returns:
//	Map of KeyAndValue:
//	* Key - String - the name space.
//	* Value - String - prefix.
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

////////////////////////////////////////////////////////////////////////////////
// Other

// Returns a template for recording settings.
// 
// Returns:
// 	Structure:
// * Settings - ValueStorage
// * SerializationViaValueStorage - Boolean
// * Presentation - String
// * User - String
// * ObjectKey - String
// * SettingsKey - String
Function NewSettingsEntry() Export

	RecordingSettings = New Structure();
	RecordingSettings.Insert("SettingsKey", "");
	RecordingSettings.Insert("ObjectKey", "");
	RecordingSettings.Insert("User", "");
	RecordingSettings.Insert("Presentation", "");
	RecordingSettings.Insert("SerializationViaValueStorage", False);
	RecordingSettings.Insert("Settings", New ValueStorage(Undefined));

	Return RecordingSettings;
	
EndFunction

// Types of standard settings storage
// 
// Returns: 
//  FixedArray of String
Function TypesOfStandardSettingsRepositories() Export
	
	Result = New Array();
	
	Result.Add("CommonSettingsStorage");
	Result.Add("SystemSettingsStorage");
	Result.Add("ReportsUserSettingsStorage");
	Result.Add("ReportsVariantsStorage");
	Result.Add("FormDataSettingsStorage");
	Result.Add("DynamicListsUserSettingsStorage");
	
	Return New FixedArray(Result);
	
EndFunction

// The download is interrupted
// 
// Returns:
//  Boolean
Function DownloadAborted() Export
	Return InformationAboutImportProcedure() <> Undefined;
EndFunction

Procedure FixLinkMatching(RefsMap) Export
	InformationAboutImportProcedure =  InformationAboutImportProcedure();
	InformationAboutImportProcedure.RefsMap = RefsMap; 
	RecordInformationAboutBootProcedure(InformationAboutImportProcedure);
EndProcedure

// Parameters:
//	MetadataObjects - Array of MetadataObject
//	
// Returns: 
//	See ExportImportDataInternal.ReferencesToTypes
//
Function ReferencesToMetadataObjects(MetadataObjects) Export
		
	AllReferenceData = AllReferenceData();
	
	Types = New Array;
	
	For Each MetadataObject In MetadataObjects Do
		If AllReferenceData.Find(MetadataObject) = Undefined Then
			Continue;
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(
			MetadataObject.FullName());
		Type = TypeOf(ObjectManager.EmptyRef());
		
		Types.Add(Type);
			
	EndDo;
	
	Return ReferencesToTypes(Types);
	
EndFunction

// Parameters:
//	Types - Array of Type
//	
// Returns: 
//	FixedMap of KeyAndValue:
//	 * Key - String - name of the metadata object
//	 * Value - Array 
//
Function ReferencesToTypes(Types) Export
				
	MetadataList = New Map;
	For Each ObjectMetadata In AllConstants() Do
		AddConstantToMetadataList(ObjectMetadata, MetadataList, Types);
	EndDo;
	
	For Each ObjectMetadata In AllReferenceData() Do
		AddReferenceTypeToMetadataList(ObjectMetadata, MetadataList, Types);
	EndDo;
	
	For Each ObjectMetadata In AllRecordSets() Do
		AddRegisterToMetadataTable(ObjectMetadata, MetadataList, Types);
	EndDo;
	
	Return New FixedMap(MetadataList);
	
EndFunction

Function ReadArchive(ArchiveData) Export
	
	ArchiveDataType = TypeOf(ArchiveData);
	
	If ArchiveDataType = Type("Structure") Then
		
		If ArchiveData.Property("IDOfSourceFile") Then
			FullArchiveFileName_ = ExportImportDataAreas.FullArchiveFileName_();
			CopyArchive = ZIPArchives.ReadArchive(ArchiveData.IDOfSourceFile);
			Archive = ZIPArchives.ReadAttachedUncompressedArchive(CopyArchive, FullArchiveFileName_);
		Else
			Archive = ArchiveData;
		EndIf;
		
	ElsIf ArchiveDataType = Type("UUID") Then
		Archive = ZIPArchives.ReadArchive(ArchiveData);
	Else
		Archive = ZIPArchives.ReadArchive(FileStreams.OpenForRead(ArchiveData));
	EndIf;
	
	Return Archive;
	
EndFunction

Procedure UnzipArchiveFile(Val Archive, Val TargetDirectory, Val Name, Val Path = "") Export
	
	If Not IsBlankString(Path) Then
		Path = Path + "/";
	EndIf;
	
	FileNameInArchive = ?(IsBlankString(Path), Name, Path + Name);
		
	If Not ZIPArchives.ExtractFile(Archive, FileNameInArchive, TargetDirectory) Then
		Raise StrTemplate(NStr("vi = 'Không tìm thấy tệp %1';
								|ru = 'Файл %1 не найден';
								|en = 'File %1 is not found'; fa = 'File %1 is not found';
								|it = 'File %1 non trovato';
								|pl = 'Plik %1 nie został znaleziony';
								|tr = '%1 dosyası bulunamadı'"), FileNameInArchive);
	EndIf;
	
EndProcedure

Function GetFileName(Val FileKind, Val Extension = "xml") Export
	
	If FileKind = DumpInfo() Then
		FileName = DumpInfo();
	ElsIf FileKind = Digest() Then
		FileName = Digest();
	ElsIf FileKind = Extensions() Then
		FileName = Extensions();	
	ElsIf FileKind = CustomExtensions() Then
		FileName = CustomExtensions();
	ElsIf FileKind = DumpWarnings() Then
		FileName = DumpWarnings();
	ElsIf FileKind = ApplicationTypes() Then
		FileName = ApplicationTypes();
	ElsIf FileKind = PackageContents() Then
		FileName = PackageContents();
	ElsIf FileKind = Users() Then
		FileName = Users();
	ElsIf FileKind = PredefinedDataDuplicates() Then
		FileName = PredefinedDataDuplicates();
	Else
		FileName = String(New UUID);
	EndIf;
	
	For CharacterNumber = 1 To StrLen(Extension) Do
		Char = CharCode(Extension, CharacterNumber);
		// Only numbers and Latin letters, see standard 542, clause 3.1
		If Not (Char >= 48 And Char <= 57)
			And Not (Char >= 65 And Char <= 90)
			And Not (Char >= 97 And Char <= 122) Then
			Extension = "bin";
			Break;
		EndIf;
	EndDo;
	
	If Extension <> "" Then
		
		FileName = FileName + "." + Extension;
		
	EndIf;
	
	Return FileName;
	
EndFunction

Function NumberOfImportObjectsByMetadataObjects(Content, LoadableTypes, ForTechnicalSupport) Export
	
	ImportingObjectsCountTable = NewTableOfNumberOfProcessedObjects();
	
	ImportingTypesFullNames = FullTypeNames(LoadableTypes);
	
	FullNamesOfExcludedTypes = FullTypeNames(
		TypesToExclude(ForTechnicalSupport));
	
	IBDataFileType = InfobaseData();		
	For Each CompositionRow In Content Do 
		
		DataType = CompositionRow.DataType;
		
		If CompositionRow.FileKind <> IBDataFileType
			Or ImportingTypesFullNames.Get(DataType) = Undefined
			Or FullNamesOfExcludedTypes.Get(DataType) <> Undefined Then
			Continue;
		EndIf;
		
		ImportingObjectString = ImportingObjectsCountTable.Add();
		ImportingObjectString.FullName = DataType;
		ImportingObjectString.NumberOfObjects = CompositionRow.NumberOfObjects;
	
	EndDo;
		
	ImportingObjectsCountTable.GroupBy("FullName", "NumberOfObjects");
	
	Return ImportingObjectsCountTable;
	
EndFunction

Function NumberOfBackupObjectsToImport(Archive, BackupType, ForTechnicalSupport) Export
	
	TempDirectory = GetTempFileName();
	
	NameOfContentFile = GetFileName(PackageContents()); 
	
	UnzipArchiveFile(
		ReadArchive(Archive),
		TempDirectory,
		NameOfContentFile);
	
	ArchiveContent = ArchiveContent(
		TempDirectory + GetPathSeparator() + NameOfContentFile);
	
	DeleteFiles(TempDirectory);
	
	LoadableTypes = LoadableTypes(BackupType);
	
	NumberOfImportObjectsByMetadataObjects = NumberOfImportObjectsByMetadataObjects(
		ArchiveContent,
		LoadableTypes,
		ForTechnicalSupport);
		
	Return NumberOfImportObjectsByMetadataObjects.Total("NumberOfObjects"); 
	
EndFunction

Function ImportObjectsdByMetadataObjectsCount(TypesToExport, UnloadedTypesOfSharedData, ForTechnicalSupport) Export
	
	ExportingObjectsCountTable = NewTableOfNumberOfProcessedObjects();
				
	SubqueryTemplate = "SELECT
		|	 ""%1"" AS FullName,
		|	 %2 AS NumberOfObjects
		|FROM
		|	%3";
				
	Subqueries = New Array; 
	
	UniqueExportingTypes = New Array;
	CommonClientServer.SupplementArray(UniqueExportingTypes, TypesToExport);
	CommonClientServer.SupplementArray(UniqueExportingTypes, UnloadedTypesOfSharedData);
	UniqueExportingTypes = CommonClientServer.CollapseArray(UniqueExportingTypes);
		
	FullNamesOfExcludedTypes = FullTypeNames(
		TypesToExclude(ForTechnicalSupport));

	For Each UnloadedType In UniqueExportingTypes Do   
			
		FullNameOfExportingType = UnloadedType.FullName();
				
		If FullNamesOfExcludedTypes.Get(FullNameOfExportingType) <> Undefined Then
			Continue;
		EndIf;
		
		If CommonCTL.IsConstant(UnloadedType) Then
			StringConsts = ExportingObjectsCountTable.Add();
			StringConsts.FullName = FullNameOfExportingType;
			StringConsts.NumberOfObjects = 1;
			Continue; 
		EndIf;
		
		If CommonCTL.IsRefData(UnloadedType) 
			Or CommonCTL.IsIndependentRecordSet(UnloadedType) Then		
			
			QuantityCalculationExpression = "Count(*)";
			TableName = UnloadedType.FullName();
		
		ElsIf CommonCTL.IsRecordSet(UnloadedType) Then 
			
			If CommonCTL.IsRecalculationRecordSet(UnloadedType) Then
				
				QuantityCalculationExpression = "Count(Distinct RecalculationObject)";
				
				Substrings = StrSplit(UnloadedType.FullName(), ".");
				TableName = Substrings[0] + "." + Substrings[1] + "." + Substrings[3];
				
			Else
				
				QuantityCalculationExpression = "Count(Distinct Recorder)";
				TableName = UnloadedType.FullName();
				
			EndIf;
						
		Else
			Raise StrTemplate(NStr("vi = 'Không hỗ trợ đối tượng metadata: %1';
									|ru = 'Объект метаданных не поддерживается: %1';
									|en = 'The metadata object is not supported: %1'; fa = 'The metadata object is not supported: %1';
									|it = 'Объект метаданных не поддерживается: %1';
									|pl = 'The metadata object is not supported: %1';
									|tr = 'Metaveri nesneleri desteklenmiyor: %1'"),
				UnloadedType.FullName());		
		EndIf;     
		
		Subqueries.Add(
				StrTemplate(SubqueryTemplate, FullNameOfExportingType, QuantityCalculationExpression, TableName));
	
		If Subqueries.Count() >= 100 Then
			AddTableOfProcessedObjectsNumber(
				ExportingObjectsCountTable,
				TableOfNumberOfExportedObjectsBySubqueries(Subqueries));
			Subqueries.Clear();			
		EndIf;
		
	EndDo; 
	
	If ValueIsFilled(Subqueries) Then
		AddTableOfProcessedObjectsNumber(
			ExportingObjectsCountTable,
			TableOfNumberOfExportedObjectsBySubqueries(Subqueries));			
	EndIf;
		
	Return ExportingObjectsCountTable;
		
EndFunction

Function IsDifferentialBackup(ImportParameters) Export
	
	Return BackupType(ImportParameters) = BackupTypeDifferential();
	
EndFunction

Function IsFullBackup(ImportParameters) Export
	
	Return BackupType(ImportParameters) = BackupTypeFull();
	
EndFunction

Function BackupTypeDifferential() Export
	
	Return "Differential";
	
EndFunction

Function BackupTypeFull() Export
	
	Return "Full";
	
EndFunction

Function BackupTypeNormal() Export
	
	Return "Ordinary";
	
EndFunction

// Get file data from the archive.
// 
// Parameters:
//  Content - See ArchiveContent
//  SearchParameters - See NewFileFromArchiveSearchParameters
// 
// Returns:
//  ValueTableRow - file parameters:
// * Name - String
// * Directory - String
// * Size - Number
// * FileKind - String
// * NumberOfObjects - Number
// * DataType - String
Function GetFileParametersFromArchive(Content, SearchParameters) Export
	
	FilterParameters = New Structure();
	
	For Each SearchParameter In SearchParameters Do
		
		If ValueIsFilled(SearchParameter.Value) Then
			FilterParameters.Insert(SearchParameter.Key, SearchParameter.Value);
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(FilterParameters) Then
		Raise NStr("vi = 'Sai tham số tìm kiếm tệp thành phần tệp nén';
					|ru = 'Неверные параметры поиска файла состава архива';
					|en = 'Incorrect archive file search parameters'; fa = 'Incorrect archive file search parameters';
					|it = 'Неверные параметры поиска файла состава архива';
					|pl = 'Incorrect archive file search parameters';
					|tr = 'Hatalı arşiv içerik dosyası arama parametreleri'");
	EndIf;
	
	FoundRows = Content.FindRows(FilterParameters);
	FilesCount = FoundRows.Count();
	
	If FilesCount = 0 Then
		Raise NStr("vi = 'Trong thành phần tệp nén không tìm thấy tệp cần tìm';
					|ru = 'В составе архива не найден искомый файл';
					|en = 'The required file is not found in the archive'; fa = 'The required file is not found in the archive';
					|it = 'В составе архива не найден искомый файл';
					|pl = 'The required file is not found in the archive';
					|tr = 'Aranan dosya arşiv içeriğinde bulunamadı'");
	ElsIf FilesCount > 1 Then
		 Raise NStr("vi = 'Trong thành phần tệp nén đã tìm thấy nhiều tệp cần tìm';
					|ru = 'В составе архива найдено несколько искомых файлов';
					|en = 'Multiple required files are found in the archive'; fa = 'Multiple required files are found in the archive';
					|it = 'В составе архива найдено несколько искомых файлов';
					|pl = 'Multiple required files are found in the archive';
					|tr = 'Aranan dosyaların birkaçı arşiv içeriğinde bulundu'");
	EndIf;
	
	FileParameters = FoundRows[0]; // ValueTableRow
	
	Return FileParameters;
	
EndFunction

// The composition of the archive.
// 
// Parameters:
//  CompositionFilePath - String - The Path To The Composition File
// 
// Returns:
//  See NewContent
Function ArchiveContent(CompositionFilePath) Export
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(CompositionFilePath);
	ReaderStream.MoveToContent();
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> "Data" Then
		
		Raise StrTemplate(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Đang chờ bắt đầu phần tử %1.';
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
	
	ArchiveContent = NewContent();
	
	While ReaderStream.NodeType = XMLNodeType.StartElement Do
		
		ContainerElement = XDTOFactory.ReadXML(
			ReaderStream,
			XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "File"));
			
		File = ArchiveContent.Add();
		File.Name = ContainerElement.Name;
		File.Directory = ContainerElement.Directory;
		File.Size = ContainerElement.Size;
		File.FileKind = ContainerElement.Type;
		File.NumberOfObjects = ContainerElement.Count;
		File.DataType = ContainerElement.DataType;
		
	EndDo;
	
	ReaderStream.Close();	
			
	Return ArchiveContent;
	
EndFunction

// New line-up.
// 
// Returns:
//  ValueTable - New line-up:
// * Name - String
// * Directory - String
// * Size - Number
// * FileKind - String
// * NumberOfObjects - Number
// * DataType - String
Function NewContent() Export
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsNumber = New TypeDescription("Number");
	
	NewContent = New ValueTable;
	NewContent.Columns.Add("Name", TypesDetailsString);
	NewContent.Columns.Add("Directory", TypesDetailsString);
	NewContent.Columns.Add("Size", TypesDetailsNumber);
	NewContent.Columns.Add("FileKind", TypesDetailsString);
	NewContent.Columns.Add("NumberOfObjects", TypesDetailsNumber);
	NewContent.Columns.Add("DataType", TypesDetailsString);
	
	Return NewContent;
	
EndFunction

// New file search parameters from the archive.
// 
// Returns:
//  Structure - New Search Parameters For A File From The Archive:
// * Name - String
// * Directory - String
// * FileKind - String
// * DataType - String
Function NewFileFromArchiveSearchParameters() Export
	
	SearchParameters = New Structure();
	SearchParameters.Insert("Name", "");
	SearchParameters.Insert("Directory", "");
	SearchParameters.Insert("FileKind", "");
	SearchParameters.Insert("DataType", "");
	
	Return SearchParameters;
	
EndFunction

Function LoadableTypes(BackupType) Export
	
	LoadableTypes = New Array();
	CommonClientServer.SupplementArray(
		LoadableTypes,
		ExportImportDataAreas.GetAreaDataModelTypes());
	
	If Not SaaSOperationsCached.DataSeparationEnabled() Then
		CommonClientServer.SupplementArray(
			LoadableTypes, 
			ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading(),
			True);
	EndIf;
		
	If BackupType = BackupTypeFull() Then
		For ReverseIndex = 1 - LoadableTypes.Count() To 0 Do
			MetadataObject = LoadableTypes[-ReverseIndex];
			If Metadata.ExchangePlans.Contains(MetadataObject)
				Or MetadataObject.ConfigurationExtension() <> Undefined
				And Not Metadata.ExchangePlans.ApplicationsMigration.Content.Contains(MetadataObject) Then
				LoadableTypes.Delete(-ReverseIndex);
			EndIf;
		EndDo;
	EndIf;
	
	Return LoadableTypes;
	
EndFunction

Function TypesToExclude(ForTechnicalSupport) Export
	TypesToExclude = New Array;
	CommonClientServer.SupplementArray(
 		TypesToExclude,
 		ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload());
 	If ForTechnicalSupport Then
 		CommonClientServer.SupplementArray(
 			TypesToExclude,
 			DataAreasExportForTechnicalSupportCached.MetadataExcludedFromUploadingInTechnicalSupportMode(),
 			True);
 	EndIf;
 	Return TypesToExclude;
EndFunction

Function FullTypeNames(Types) Export
	FullTypeNames = New Map();
	For Each Type In Types Do
		FullTypeNames.Insert(Type.FullName(), True);
	EndDo;
	Return FullTypeNames;
EndFunction

Function ExportForTechnicalSupportMode(PathToDigestFile) Export
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToDigestFile);
	
	DOMBuilder = New DOMBuilder;
	UploadDigest = DOMBuilder.Read(XMLReader);
	
	XMLReader.Close();
	
	If UploadDigest <> Undefined Then
		ItemsList = UploadDigest.GetElementByTagName("DataDumpType");
		UploadingForTechnicalSupport = ValueIsFilled(ItemsList) And ItemsList[0].TextContent = "TechnicalSupport";	
	Else
		UploadingForTechnicalSupport = False;
	EndIf;
	
	Return UploadingForTechnicalSupport;

EndFunction  

// Returns the xdto Serializer with type annotation.
//
// Returns:
//	XDTOSerializer - serializer.
//
Function XdtoSerializerWithTypeAnnotation() Export
	
	SchemaBinaryData = ConfigurationSchema.SchemaBinaryData(True, True);
	XMLSchema = XMLSchema(SchemaBinaryData);	
	Factory = FactoryByScheme(XMLSchema);	
	Return New XDTOSerializer(Factory);
	
EndFunction

// Availability of handlers for metadata objects.
// 
// Parameters:
//  CurHandlers - ValueTable - Cur Handlers
//  HandlerColumnsNames - Array of String -  Names Of Handler Columns
// 
// Returns:
//  Map of MetadataObject: 
Function MetadataObjectsHandlersAvailability(CurHandlers, HandlerColumnsNames) Export
	
	HandlersAvailability = New Map();
	
	For Each TableRow In CurHandlers Do
		
		ObjectHandlersAvailability = HandlersAvailability.Get(TableRow.MetadataObject);
		
		If ObjectHandlersAvailability = Undefined Then
			ObjectHandlersAvailability = NewMetadataObjectHandlersAvailabilityData(HandlerColumnsNames);
			HandlersAvailability.Insert(TableRow.MetadataObject, ObjectHandlersAvailability);
		EndIf;
		
		For Each HandlerName In HandlerColumnsNames Do
			ObjectHandlersAvailability[HandlerName] = Max(
				ObjectHandlersAvailability[HandlerName], TableRow[HandlerName]);
		EndDo;
		
	EndDo;
	
	Return HandlersAvailability;
	
EndFunction

// New data on the availability of handlers for the metadata object.
// 
// Parameters:
//  HandlerColumnsNames - Array of String - Names Of Handler Columns
// 
// Returns:
//  Structure - New Data On The Availability Of Handlers For The Metadata Object
Function NewMetadataObjectHandlersAvailabilityData(HandlerColumnsNames) Export
	
	HandlersAvailability = New Structure();
	
	For Each ColumnName In HandlerColumnsNames Do
		HandlersAvailability.Insert(ColumnName, False);
	EndDo;
	
	Return HandlersAvailability;
	
EndFunction

Procedure FillInInstalledPlusExtensions(PlusExtensions) Export
	SubsystemName = "PlusService";
	
	If Common.SubsystemExists(SubsystemName) Then 
		ModulePlusService = Common.CommonModule(SubsystemName);
		If CommonClientServer.CompareVersions(ModulePlusService.LibraryVersion(), "1.0.0.4") >= 0 Then
			ModulePlusService.FillInInstalledExtensions(PlusExtensions);
		EndIf;
	EndIf;
EndProcedure

Procedure RestorePlusExtensionsFromSM(Val ExtensionData_) Export
	PlusModule = GetPlusModule();
	If Not ExtensionData_.Property("PlusExtensions") Or PlusModule = Undefined Then
		Return;
	EndIf;
	
	For Each Extension In ExtensionData_.PlusExtensions Do
		Try
			ExtensionFileName = SaaSOperations.GetFileFromServiceManagerStorage(
									New UUID(Extension.PathToData));
		Except
			ErrorText = StrTemplate(NStr("vi = 'Không thể nhận tệp mở rộng
				|%1
				|%2';
				|ru = 'Не удалось получить файл расширения
				|%1
				|%2';
				|en = 'Cannot get the extension file
				|%1
				|%2'; fa = 'Cannot get the extension file
				|%1
				|%2';
				|it = 'Не удалось получить файл расширения
				|%1
				|%2';
				|pl = 'Cannot get the extension file
				|%1
				|%2';
				|tr = 'Eklenti dosyası alınamıyor
				|%1
				|%2'"),
				,
				CloudTechnology.DetailedErrorText(ErrorInfo()));
			EventNameLR = NStr("vi = 'Phần mở rộng 1C:Plus.Lỗi nơi chứa MS';
								|ru = 'Расширения 1С:Плюс.Ошибка хранилища МС';
								|en = '1C:Plus extensions.Service Manager storage error'; fa = '1C:Plus extensions.Service Manager storage error';
								|it = 'Расширения 1С:Плюс.Ошибка хранилища МС';
								|pl = '1C:Plus extensions.Service Manager storage error';
								|tr = 'Servis Yöneticisi saklamasında 1C:Plus.Error eklentisi'", Common.DefaultLanguageCode());
			WriteLogEvent(EventNameLR, EventLogLevel.Error, , , ErrorText);
			Raise ErrorText;
		EndTry;
		
		Extension.PathToData = ExtensionFileName;
	EndDo;
	
	PlusModule.RestoreExtensionsFromMS(ExtensionData_.PlusExtensions);
EndProcedure

Function CheckPlusExtensions() Export
	PlusModule = GetPlusModule();
	If PlusModule <> Undefined Then
		Return PlusModule.ListOfModifiedExtensions();
	EndIf;
EndFunction

// Parameters:
//  ExportImportParameters - Structure
// 
// Returns:
//  Number
Function ClientSessionNumberFromParameters(ExportImportParameters) Export
	
	ClientSessionNumber = 0;
	
	If ExportImportParameters.Property("ClientSessionNumber")
		And TypeOf(ExportImportParameters.ClientSessionNumber) = Type("Number")
		And ValueIsFilled(ExportImportParameters.ClientSessionNumber) Then
		
		ClientSessionNumber = ExportImportParameters.ClientSessionNumber;
		
	EndIf;
	
	Return ClientSessionNumber;
	
EndFunction

#Region ParallelExportImport

// Parameters for parallel data loading.
// 
// Returns:
//  Structure - Parameters for parallel data loading:
// * AvailableUsage - Boolean -
// * ThreadsCount - Number -
Function ParallelDataExportImportParameters() Export
	
	AvailableUsage = Not Common.DataSeparationEnabled()
		And Not Common.FileInfobase();
	
	Parameters = New Structure();
	Parameters.Insert("AvailableUsage", AvailableUsage);
	Parameters.Insert("ThreadsCount", 4);
	
	Return Parameters;
	
EndFunction

// Use multithreading.
// 
// Parameters:
//  ExportImportParameters - Structure
// 
// Returns:
//  Boolean - Use Multithreading
Function UseMultithreading(ExportImportParameters) Export
	
	If SaaSOperations.DataSeparationEnabled() Then
		
		Return GetFunctionalOption("UseParallelExportImportData");
		
	Else
	
		ThreadsCount = 0;
		
		If ExportImportParameters.Property("ThreadsCount") Then
			ThreadsCount = ExportImportParameters.ThreadsCount;
		EndIf;
		
		Return ValueIsFilled(ThreadsCount) And ThreadsCount > 1;
		
	EndIf;
	
EndFunction

// Starts data upload and download streams.
// 
// Parameters:
//  ThreadsParameters - See NewExportImportDataThreadsParameters
//  Container - DataProcessorObject.ExportImportDataContainerManager
// 
// Returns:
//  Array of BackgroundJob - Running background jobs
Function StartDataExportImportThreads(ThreadsParameters, Container) Export
	
	If Not ValueIsFilled(ThreadsParameters.ThreadsCount) Then
		Raise NStr("vi = 'Sai tham số luồng, chưa chỉ định số luồng.';
					|ru = 'Некорректные параметры потоков, не указано количество потоков.';
					|en = 'Incorrect stream parameters. The number of streams is not specified.'; fa = 'Incorrect stream parameters. The number of streams is not specified.';
					|it = 'Некорректные параметры потоков, не указано количество потоков.';
					|pl = 'Incorrect stream parameters. The number of streams is not specified.';
					|tr = 'Hatalı iş parçacığı parametreleri, iş parçacığı sayısı belirtilmedi.'");
	EndIf;
	
	If ThreadsParameters.IsExport Then
		JobDescription = NStr("vi = 'Kết xuất dữ liệu cơ sở thông tin';
								|ru = 'Выгрузка данных информационной базы';
								|en = 'Export infobase data'; fa = 'Export infobase data';
								|it = 'Выгрузка данных информационной базы';
								|pl = 'Export infobase data';
								|tr = 'Infobase verilerinin aktarımı'");
	ElsIf ThreadsParameters.ThisIsDownload Then
		JobDescription = NStr("vi = 'Kết nhập dữ liệu cơ sở thông tin';
								|ru = 'Загрузка данных информационной базы';
								|en = 'Import infobase data'; fa = 'Import infobase data';
								|it = 'Загрузка данных информационной базы';
								|pl = 'Import infobase data';
								|tr = 'Infobase verilerinin indirilmesi'");
	Else
		Raise NStr("vi = 'Sai tham số luồng, chưa chỉ định dấu hiệu kết xuất hoặc kết nhập.';
					|ru = 'Некорректные параметры потоков, не указан признак выгрузки или загрузки.';
					|en = 'Incorrect thread parameters. An export or import flag is not selected.'; fa = 'Incorrect thread parameters. An export or import flag is not selected.';
					|it = 'Некорректные параметры потоков, не указан признак выгрузки или загрузки.';
					|pl = 'Incorrect thread parameters. An export or import flag is not selected.';
					|tr = 'Hatalı iş parçacığı parametreleri, yükleme veya dışa aktarma işareti belirtilmedi.'");
	EndIf;
	
	JobParameters = New Array();
	JobParameters.Add(ThreadsParameters);
	
	Jobs = New Array();
	
	For ThreadNumber = 1 To ThreadsParameters.ThreadsCount Do
		
		Job = BackgroundJobs.Execute(
			ExportImportDataInThreadMethodName(),
			JobParameters,
			ExportImportDataJobKey(Container),
			JobDescription);
		
		Jobs.Add(Job);
		
		InformationRegisters.ExportImportDataThreads.AddRecord(Job, Container, ThreadsParameters.ThreadTypes);
		
		If ThreadNumber < ThreadsParameters.ThreadsCount Then
			// We distribute the start of tasks by time
			CommonCTL.Pause(1);
		EndIf;
		
	EndDo;
	
	Return Jobs;
	
EndFunction

Function ExportImportDataInThreadMethodName() Export
	
	Return "ExportImportDataInternal.ExportImportInfoBaseDataInThread";
	
EndFunction

// The name of the method for the End of the upload stream message.
// 
// Returns:
//  String - Method name of the stream message End of unloading
Function StreamMessageMethodName_ExportEnd() Export
	
	Return "ExportEnd";
	
EndFunction

// Waits for data to be uploaded and loaded in streams.
// 
// Parameters:
//  Jobs - Array of BackgroundJob - Running Jobs
//  ProcessParameters - Structure - To download data, see processing the offload and offload of data from the manager and offload of data from the information database.newparameters of the processagruzedannyhinformation database
//									To upload data, see processing the uploadinggroupdannyhmanageredgroupdannyhinformation database.newparameters of the process of loading the specified information database
Procedure WaitExportImportDataInThreads(Jobs, ProcessParameters) Export
	
	ManagingTask = GetJobOfParallelExportImportData();
	JobID = ?(ManagingTask = Undefined,
		CommonClientServer.BlankUUID(),
		ManagingTask.UUID);
	
	Timeout = 5; // sec.
	Container = ProcessParameters.Container; // DataProcessorObject.ExportImportDataContainerManager
	ProcessID = Container.ProcessID();
	
	While True Do
		
		StartAdditionalExportImportDataThreads(Jobs, ProcessParameters);
		
		Jobs = BackgroundJobs.WaitForExecutionCompletion(Jobs, Timeout);
		JobNumber = Jobs.Count();
		
		Errors = New Array();
		CompletedTasks = New Array();
		MessageTable = NewThreadMessagesTable();
		
		While JobNumber > 0 Do
			
			JobNumber = JobNumber - 1;
			Job = Jobs[JobNumber];
			
			If Job.State <> BackgroundJobState.Active Then
				Jobs.Delete(JobNumber);
			EndIf;
			
			ReceiveThreadMessages(MessageTable, Job, ProcessID);
			
			ErrorText = Undefined;
			
			If Job.State = BackgroundJobState.Failed Then
				
				ErrorInfo = ?(Job.ErrorInfo = Undefined,
					NStr("vi = 'Không có thông tin về lỗi.';
						|ru = 'Отсутствует информация об ошибке.';
						|en = 'No error information available.'; fa = 'No error information available.';
						|it = 'Отсутствует информация об ошибке.';
						|pl = 'No error information available.';
						|tr = 'Hata bilgisi mevcut değil.'"),
					ErrorProcessing.DetailErrorDescription(Job.ErrorInfo));
				ErrorText = StrTemplate(
					NStr("vi = 'Luồng %1, nhiệm vụ nền đã kết thúc bất thường.
						 |%2';
						 |ru = 'Поток %1, фоновое задание завершилось аварийно.
						 |%2';
						 |en = 'Thread %1, background job crashed.
						 |%2'; fa = 'Thread %1, background job crashed.
						 |%2';
						 |it = 'Поток %1, фоновое задание завершилось аварийно.
						 |%2';
						 |pl = 'Thread %1, background job crashed.
						 |%2';
						 |tr = '%1 iş parçacığı, arka plan işi arızalı şekilde sona erdi.
						 |%2'"),
					ThreadNumberFromJobKey(Job.Key),
					ErrorInfo);
				
			ElsIf Job.State = BackgroundJobState.Canceled Then
				
				ErrorText = StrTemplate(
					NStr("vi = 'Luồng %1, nhiệm vụ nền đã bị hủy.';
						|ru = 'Поток %1, фоновое задание отменено.';
						|en = 'Thread %1, background job is canceled.'; fa = 'Thread %1, background job is canceled.';
						|it = 'Поток %1, фоновое задание отменено.';
						|pl = 'Thread %1, background job is canceled.';
						|tr = '%1 iş parçacığı, arka plan işi iptal edildi.'"),
					ThreadNumberFromJobKey(Job.Key));
				
			EndIf;
			
			If ValueIsFilled(ErrorText) Then
				
				Errors.Add(ErrorText);
				
				InformationRegisters.ExportImportDataThreads.DeleteRecord(Job.UUID);
				
			ElsIf StreamJobCompleted(Job, MessageTable) Then
				
				 CompletedTasks.Add(JobNumber);
				 
			EndIf;
			
		EndDo;
		
		If ValueIsFilled(Errors) Then
			
			CompletedTasks.Clear();
			
			For Each Job In Jobs Do
				
				ErrorText = StrTemplate(
					NStr("vi = 'Luồng %1, nhiệm vụ nền đã bị ngắt do lỗi trong luồng khác.';
						|ru = 'Поток %1, фоновое задание прервано из-за ошибки в другом потоке.';
						|en = 'Thread %1, background job was interrupted due to an error in another thread.'; fa = 'Thread %1, background job was interrupted due to an error in another thread.';
						|it = 'Поток %1, фоновое задание прервано из-за ошибки в другом потоке.';
						|pl = 'Thread %1, background job was interrupted due to an error in another thread.';
						|tr = '%1 iş parçacığı, arka plan işi başka bir iş parçacığındaki hata nedeniyle sonlandırıldı.'"),
					ThreadNumberFromJobKey(Job.Key));
				
				Job.Cancel();
				Errors.Add(ErrorText);
				
				ReceiveThreadMessages(MessageTable, Job, ProcessID);
				
				InformationRegisters.ExportImportDataThreads.DeleteRecord(Job);
				
			EndDo;
			
			ProcessThreadMessages(MessageTable, Container);
			
			InformationRegisters.ExportImportDataThreads.DeleteRecord(JobID);
			
			ErrorSeparator = Chars.LF + Chars.LF;
			ErrorText = StrConcat(Errors, ErrorSeparator);
			
			Raise ErrorText;
			
		EndIf;
		
		ProcessThreadMessages(MessageTable, Container);
		
		For Each JobNumber In CompletedTasks Do
			Job = Jobs[JobNumber];
			Jobs.Delete(JobNumber);
			Job.Cancel();
		EndDo;
		
		If Not ValueIsFilled(Jobs) Then
			Break;
		EndIf;
		
	EndDo;
	
	InformationRegisters.ExportImportDataThreads.DeleteRecord(JobID);
	
EndProcedure

// New parameters of data upload and download streams.
// 
// Returns:
//  Structure - New Parameters Of Data Upload And Download Streams:
// * IsExport - Boolean -
// * ThisIsDownload - Boolean -
// * ThreadsCount - Number -
// * ThreadTypes - EnumRef.ExportImportDataThreadTypes -
// * Parameters - Structure -
Function NewExportImportDataThreadsParameters() Export
	
	StreamParameters = New Structure();
	StreamParameters.Insert("IsExport", False);
	StreamParameters.Insert("ThisIsDownload", False);
	StreamParameters.Insert("ThreadsCount", 0);
	StreamParameters.Insert("ThreadTypes", Enums.ExportImportDataThreadTypes.Additional);
	StreamParameters.Insert("Parameters", New Structure());
	
	Return StreamParameters;
	
EndFunction

// Uploading loading information database data in a stream.
// 
// Parameters:
//  StreamParameters - See ExportImportDataInternal.ExportImportInfoBaseDataInThread
Procedure ExportImportInfoBaseDataInThread(StreamParameters) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If StreamParameters.IsExport Then
		
		DataProcessors.ExportImportDataInfobaseDataExportManager.ExportInfoBaseDataInThread(
			StreamParameters.Parameters);
		
	ElsIf StreamParameters.ThisIsDownload Then
		
		ModuleAccessManagement = Undefined;
		
		If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagement = Common.CommonModule("AccessManagement");
			ModuleAccessManagement.DisableAccessKeysUpdate(True, False);
		EndIf;
		
		Try
			
			DataProcessors.ExportImportDataInfobaseDataImportManager.ImportInfoBaseDataInThread(
				StreamParameters.Parameters);
			
			If ModuleAccessManagement <> Undefined Then
				ModuleAccessManagement.DisableAccessKeysUpdate(False);
			EndIf;
			
		Except
			
			If ModuleAccessManagement <> Undefined Then
				ModuleAccessManagement.DisableAccessKeysUpdate(False);
			EndIf;
			
			Raise;
			
		EndTry;
		
	Else
		
		Raise NStr("vi = 'Sai tham số luồng.';
					|ru = 'Некорректные параметры потока.';
					|en = 'Incorrect thread parameters.'; fa = 'Incorrect thread parameters.';
					|it = 'Некорректные параметры потока.';
					|pl = 'Incorrect thread parameters.';
					|tr = 'Hatalı iş parçacığı parametreleri.'");
		
	EndIf;
	
EndProcedure

// Send a message to the parent thread.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Cur Container
//  MethodName - String - Method name
//  MessageData - Structure - Message data
Procedure SendMessageToParentThread(Container, MethodName, MessageData) Export
	
	If Not Container.ClientSessionExists() Then
		Container.AbortProcessOnAbsentClientSession();
	EndIf;
	
	ThreadMessage = New Structure();
	ThreadMessage.Insert("DateSent", CurrentUniversalDateInMilliseconds());
	ThreadMessage.Insert("MessageNo", Container.NextMessageNumberInStream());
	ThreadMessage.Insert("MethodName", MethodName);
	ThreadMessage.Insert("MessageData", MessageData);
	
	MessageDataWriter = New JSONWriter();
	MessageDataWriter.SetString();
	WriteJSON(MessageDataWriter, ThreadMessage);
	
	Message = New UserMessage();
	Message.TargetID = Container.ProcessID();
	Message.Text = MessageDataWriter.Close();
	Message.Message();
	
EndProcedure

// Get a task for parallel uploading of data downloads.
// 
// Returns:
//  BackgroundJob, Undefined -
Function GetJobOfParallelExportImportData() Export
	
	Job = GetCurrentInfoBaseSession().GetBackgroundJob();
	
	If Job = Undefined And SaaSOperations.DataSeparationEnabled() Then
		Raise NStr(
			"vi = 'Việc kết xuất\kết nhập song song có thể được thực hiện chỉ trong nhiệm vụ nền.';
			|ru = 'Параллельная выгрузка\загрузка данных может выполняться только в фоновом задании.';
			|en = 'You can perform parallel data export\import only in the background job.'; fa = 'You can perform parallel data export\import only in the background job.';
			|it = 'Параллельная выгрузка\загрузка данных может выполняться только в фоновом задании.';
			|pl = 'You can perform parallel data export\import only in the background job.';
			|tr = 'Bilgi veri tabanı verilerinin paralel olarak dışa aktarılması sadece bir arka plan işinde gerçekleştirilebilir.'");
	EndIf;
	
	Return Job;
	
EndFunction

// View of the thread of parallel unloading of data loading.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager
// 
// Returns:
//  EnumRef.ExportImportDataThreadTypes
Function ParallelExportImportDataThreadType(Container) Export
	
	If SaaSOperations.DataSeparationEnabled() And Container.ThreadsCount() = 1 Then
		Return Enums.ExportImportDataThreadTypes.Main;
	Else
		Return Enums.ExportImportDataThreadTypes.Additional;
	EndIf;
	
EndFunction

// Check the parameters of parallel data upload and download.
// 
// Parameters:
//  ExportImportParameters - Structure
//  ThisIsDownload - Boolean
Procedure CheckParametersOfParallelExportImportData(ExportImportParameters, ThisIsDownload) Export
	
	If Not ExportImportParameters.Property("ThreadsCount") Then
		ExportImportParameters.Insert("ThreadsCount", 0);
	EndIf;
	
	If ExportImportParameters.ThreadsCount < 1 Then
		ExportImportParameters.ThreadsCount = 1;
	EndIf;
	
	If Not (ExportImportParameters.Property("JobKind")
		And ValueIsFilled(ExportImportParameters.JobKind)) Then
		
		JobKind = ?(ThisIsDownload,
			Enums.ExportImportDataJobTypes.OtherDataImport,
			Enums.ExportImportDataJobTypes.OtherDataExport);
			
		ExportImportParameters.Insert("JobKind", JobKind);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function GetPlusModule()
	SubsystemName = "PlusService";
	
	If Common.SubsystemExists(SubsystemName) Then 
		ModulePlusService = Common.CommonModule(SubsystemName);
		If CommonClientServer.CompareVersions(ModulePlusService.LibraryVersion(), "1.0.0.4") >= 0 Then
			Return ModulePlusService;
		EndIf;
	EndIf;
EndFunction

Function LoadCurAreaDataFromArchiveInBackground(Val FileData, Val ImportParameters)
		
	If Common.FileInfobase() 
		And GetCurrentInfoBaseSession().ApplicationName = "BackgroundJob" Then
		Raise NStr("vi = 'Không thể tải ở chế độ nền: Cơ sở thông tin tệp (file-server) chỉ hỗ trợ một công việc nền chạy tại một thời điểm.';
					|ru = 'Невозможно выполнить загрузку в фоновом режиме: файловая информационная база поддерживает одновременное выполнение только одного фонового задания.';
					|en = 'Cannot import data in the background. The file infobase can run only one background job at a time.'; fa = 'Cannot import data in the background. The file infobase can run only one background job at a time.';
					|it = 'Невозможно выполнить загрузку в фоновом режиме: файловая информационная база поддерживает одновременное выполнение только одного фонового задания.';
					|pl = 'Cannot import data in the background. The file infobase can run only one background job at a time.';
					|tr = 'Arka plan işi içe aktarılamıyor: dosya infobase aynı anda yalnızca bir arka plan işini destekler.'");
	EndIf;			
			
	ResultAddress = PutToTempStorage(Undefined);
	
	JobParameters = New Array();
	JobParameters.Add(FileData);
	JobParameters.Add(ImportParameters);
	JobParameters.Add(ResultAddress);
	
	MethodName = "ExportImportDataInternal.StartLoadingCurAreaDataFromArchive";
	
	Job = CloudTechnology.CompleteTaskWithExtensions(
		MethodName,
		JobParameters,
		New UUID,
		NStr("vi = 'Phục hồi vùng dữ liệu từ tệp nén';
			|ru = 'Восстановление области данных из архива';
			|en = 'Restore data area from archive'; fa = 'Restore data area from archive';
			|it = 'Ripristino area dati dall''archivio';
			|pl = 'Przywrócenie obszaru danych z archiwum';
			|tr = 'Arşivden veri alanı geri yükleme'"))
		.WaitForExecutionCompletion();
	
	If Job.State = BackgroundJobState.Canceled Then
		Raise NStr("vi = 'Nhiệm vụ đã bị hủy';
					|ru = 'Задание отменено';
					|en = 'Job is canceled'; fa = 'Job is canceled';
					|it = 'Task annullato';
					|pl = 'Zadanie anulowano';
					|tr = 'Görev iptal edildi'");
	ElsIf Job.State = BackgroundJobState.Failed Then
		Raise ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
	EndIf;
	
	Return GetFromTempStorage(ResultAddress);	
	
EndFunction

Function ItIsPossibleToContinueLoadingProcedure(HashSumOfSource, HashSumOfParameters)
	
	InformationAboutImportProcedure =  InformationAboutImportProcedure();
	CheckResult = AbilityToContinueAreaDataImportingCheckingResult(
		InformationAboutImportProcedure,
		HashSumOfSource,
		HashSumOfParameters);
	
	EventLogEvent = NStr(
		"vi = 'Kết xuất kết nhập dữ liệu. Không thể tiếp tục thủ tục kết nhập';
		|ru = 'Выгрузка загрузка данных. Продолжение процедуры загрузки невозможно';
		|en = 'Data export and import. Cannot continue import procedure'; fa = 'Data export and import. Cannot continue import procedure';
		|it = 'Download upload dati. Impossibile continuare il download';
		|pl = 'Eksportowanie pobieranie danych. Kontynuacja procedury pobierania jest niemożliwa';
		|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı. İçe aktarma işlemini devam etmek mümkün değil'",
		Common.DefaultLanguageCode());
	
	If Not CheckResult.ThisIsContinuationOfDownload Then 
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			NStr("vi = 'Thiếu thông tin về thủ tục kết nhập lần trước';
				|ru = 'Отсутствует информация о прошлой процедуре загрузки';
				|en = 'No information about the previous import procedure'; fa = 'No information about the previous import procedure';
				|it = 'Manca l''informazione sul download precedente';
				|pl = 'Brak informacji o poprzednie procedurze pobierania';
				|tr = 'Bir önceki içe aktarma prosedürü hakkında bilgi bulunmuyor'"));
		Return False;
	EndIf;
	
	If CheckResult.ConfigurationVersionDiffers Then
		
		WarningText = StrTemplate(
			NStr("vi = 'Đã thay đổi tên hoặc phiên bản cấu hình 
			|Giá trị cũ: %1 %2
			|Giá trị hiện tại: %3 %4';
			|ru = 'Изменилось имя или версия конфигурации 
			|Прошлые значения: %1 %2
			|Текущие значения: %3 %4';
			|en = 'Configuration name or version changed 
			|Previous values: %1 %2
			|Current values: %3 %4'; fa = 'Configuration name or version changed 
			|Previous values: %1 %2
			|Current values: %3 %4';
			|it = 'Nome o versione dell''applicazione sono stati modificati 
			|Valori precedenti: %1 %2
			|Valori correnti: %3 %4';
			|pl = 'Zmieniła się nazwa lub wersja konfiguracji 
			|Poprzednie wartości: %1 %2
			|Bieżące wartości: %3 %4';
			|tr = 'Yapılandırma adı veya sürümü değiştirildi 
			|Önceki değerler: %1 %2
			|Mevcut değerler: %3 %4'"),
			InformationAboutImportProcedure.Configuration,
			InformationAboutImportProcedure.ConfigurationVersion,
			Metadata.Name,
			Metadata.Version);
			
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			WarningText);
		Return False;
	EndIf;
	
	If CheckResult.HashSumOfSourceDiffers Then
		
		WarningText = StrTemplate(
			NStr("vi = 'Đã thay đổi nguồn kết nhập 
				 |Giá trị cũ của Hash số tiền: %1 
				 |Giá trị hiện tại của Hash số tiền: %2';
				 |ru = 'Изменился источник загрузки 
				 |Прошлое значение хеш суммы: %1 
				 |Текущее значение хеш суммы: %2';
				 |en = 'Import source changed 
				 |Previous hash value: %1 
				 |Current hash value: %2'; fa = 'Import source changed 
				 |Previous hash value: %1 
				 |Current hash value: %2';
				 |it = 'Fonte di caricamento modificata 
				 |Valore precedente dell''importo hash: %1 
				 |Valore corrente dell''importo hash: %2';
				 |pl = 'Zmieniło się źródło pobierania 
				 |Poprzednia wartość suma hash: %1 
				 |Bieżąca wartość sumy hash: %2';
				 |tr = 'İçe aktarma kaynağı değişti 
				 |Geçmiş hash değeri: %1 
				 |Mevcut hash değeri: %2'"),
			InformationAboutImportProcedure.HashSumOfSource,
			HashSumOfSource);
			
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			WarningText);
			
		Return False;
	EndIf;

	If CheckResult.HashSumOfParametersDiffers Then
		
		WarningText = StrTemplate(
			NStr("vi = 'Đã thay đổi tham số kết nhập
				 |Giá trị cũ của Hash số tiền: %1 
				 |Giá trị hiện tại của Hash số tiền: %2';
				 |ru = 'Изменились параметры загрузки
				 |Прошлое значение хеш суммы: %1 
				 |Текущее значение хеш суммы: %2';
				 |en = 'Import parameters changed
				 |Previous hash value: %1 
				 |Current hash value: %2'; fa = 'Import parameters changed
				 |Previous hash value: %1 
				 |Current hash value: %2';
				 |it = 'Parametri di caricamento modificati
				 |Valore precedente dell''importo hash: %1 
				 |Valore corrente dell''importo hash: %2';
				 |pl = 'Zmieniły się parametry pobierania
				 |Poprzednia wartość sumy hash: %1 
				 |Bieżąca wartość sumy hash: %2';
				 |tr = 'İçe aktarma parametreleri değişti 
				 |Geçmiş hash değeri: %1 
				 |Mevcut hash değeri: %2'"),
			InformationAboutImportProcedure.HashSumOfParameters,
			HashSumOfParameters);
			
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			WarningText);
			
		Return False;
	EndIf;
	
	If Not CheckResult.LastImportedMetadataObjectDetermined Then
	
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			NStr("vi = 'Quá trình kết nhập đã bị ngắt không phải khi kết nhập metadata';
				|ru = 'Процесс загрузки был прерван не на загрузке метаданных';
				|en = 'Import process was interrupted not on metadata import'; fa = 'Import process was interrupted not on metadata import';
				|it = 'Il processo è stato interrotto durante il download di metadati';
				|pl = 'Proces pobierania został przerwany nie podczas pobierania metadanych';
				|tr = 'Meta veriler içe aktarılmadan indirme işlemi kesintiye uğradı'"));
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function AbilityToContinueAreaDataImportingCheckingResult(
	InformationAboutImportProcedure, HashSumOfSource, HashSumOfParameters)
	
	Result = New Structure();
	Result.Insert("ThisIsContinuationOfDownload", False);
	Result.Insert("LastImportedMetadataObjectDetermined", False);
	Result.Insert("ConfigurationVersionDiffers", False);
	Result.Insert("HashSumOfSourceDiffers", False);
	Result.Insert("HashSumOfParametersDiffers", False);
	
	Result.ThisIsContinuationOfDownload = InformationAboutImportProcedure <> Undefined;
	
	If Result.ThisIsContinuationOfDownload Then
		
		Result.LastImportedMetadataObjectDetermined
			= InformationRegisters.ExportImportMetadataObjects.HasProcessedMetadataObjects();
		Result.ConfigurationVersionDiffers = InformationAboutImportProcedure.Configuration <> Metadata.Name 
			Or InformationAboutImportProcedure.ConfigurationVersion <> Metadata.Version;
		Result.HashSumOfSourceDiffers
			= InformationAboutImportProcedure.HashSumOfSource <> HashSumOfSource;
		Result.HashSumOfParametersDiffers
			= InformationAboutImportProcedure.HashSumOfParameters <> HashSumOfParameters;
	
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FixStartOfBootProcedure(HashSumOfSource, HashSumOfParameters, StateID)
		
	InformationAboutImportProcedure = New Structure();
	InformationAboutImportProcedure.Insert("StartDate", CurrentSessionDate());
	InformationAboutImportProcedure.Insert("Configuration", Metadata.Name);
	InformationAboutImportProcedure.Insert("ConfigurationVersion", Metadata.Version);
	InformationAboutImportProcedure.Insert("HashSumOfSource", HashSumOfSource);
	InformationAboutImportProcedure.Insert("HashSumOfParameters", HashSumOfParameters);
	InformationAboutImportProcedure.Insert("RefsMap", Undefined);
	InformationAboutImportProcedure.Insert("StateID", StateID);
		
	RecordInformationAboutBootProcedure(InformationAboutImportProcedure);
	
EndProcedure

Function InformationAboutImportProcedure() 
	Return Constants.InformationAboutImportProcedure.Get().Get();
EndFunction

Procedure RecordInformationAboutBootProcedure(Value)
	Constants.InformationAboutImportProcedure.Set(
		New ValueStorage(Value));
EndProcedure

Procedure FixCompletionOfBootProcedure()
	RecordInformationAboutBootProcedure(Undefined);
EndProcedure

Function StartImportProcedure(ImportParameters, Container, Handlers)
	
	If Container.FixState() And IsDifferentialBackup(ImportParameters) Then
		
		StateID = StateID(ImportParameters);
		
		ImportState = ExportImportData.DataAreaExportImportState(StateID);
	
		If ValueIsFilled(ImportState) Then
			Container.SetStartDate(
				ImportState.StartDate);	
			Container.SetNumberOfProcessedObjects(
				ImportState.ProcessedObjectsCount1);	
		Else
			RecordEventOfPreviousRecordStateAbsence(
				StateID);
		EndIf;
		
	EndIf;
			
	UploadInformation = ReadUploadInformation(Container);
	
	CheckIfUploadingToArchiveIsCompatibleWithCurConfiguration(
		UploadInformation);
	CheckIfUploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(
		UploadInformation,
		BackupType(ImportParameters) <> BackupTypeFull());
	
	FixStartOfBootProcedure(
		ImportParameters.HashSumOfSource,
		ImportParameters.HashSumOfParameters,
		StateID(ImportParameters));
					
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(True, False);
	EndIf;
	
	Handlers.BeforeImportData(Container);
				
	RefsMap = Undefined;
	ImportParameters.Property("RefsMap", RefsMap);
				
	Return DownloadDatabaseData(
		ImportParameters,
		Container,
		Handlers,
		RefsMap);

EndFunction
	
Function ContinueLoadingProcedure(ImportParameters, Container, Handlers)
	
	InformationAboutImportProcedure = InformationAboutImportProcedure();
	ObjectSelection = InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection(True);
	DownloadableMetadataObjects = New Array();
	
	While ObjectSelection.Next() Do
		DownloadableMetadataObjects.Add(ObjectSelection.MetadataObject);
	EndDo;
	
	EventLogEvent = NStr(
		"vi = 'Kết xuất kết nhập dữ liệu. Tiếp tục thủ tục kết nhập';
		|ru = 'Выгрузка загрузка данных. Продолжение процедуры загрузки';
		|en = 'Data export and import. Continue import procedure'; fa = 'Data export and import. Continue import procedure';
		|it = 'Upload download dati. Download continua';
		|pl = 'Eksportowanie pobieranie danych. Kontynuacja procedury pobierania';
		|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı. İçe aktarma işleminin devamı'",
		Common.DefaultLanguageCode());
	WarningText = StrTemplate(
			NStr("vi = 'Thủ tục kết nhập đã được tiếp tục từ các đối tượng metadata: %1';
				|ru = 'Процедура загрузки продолжена с объектов метаданных: %1';
				|en = 'Import procedure continued from metadata objects: %1'; fa = 'Import procedure continued from metadata objects: %1';
				|it = 'Процедура загрузки продолжена с объектов метаданных: %1';
				|pl = 'Import procedure continued from metadata objects: %1';
				|tr = 'Yükleme prosedürü meta veri nesnelerinden devam etti: %1'"),
			StrConcat(DownloadableMetadataObjects, ", "));
	WriteLogEvent(
		EventLogEvent,
		EventLogLevel.Warning,,, 
		WarningText);
	
	ObjectSelection.Reset();

	While ObjectSelection.Next() Do
		
		SaaSOperations.ClearMetadataObjectData(
			ObjectSelection.MetadataObject,
			Metadata.FindByFullName(ObjectSelection.MetadataObject));
		
		InformationRegisters.ExportImportMetadataObjects.RecordObjectProcessingEnd(
			ObjectSelection);
		
	EndDo;
		
	If Container.FixState() Then
		
		DownloadProcedureStateId = InformationAboutImportProcedure.StateID;
		
		If ValueIsFilled(DownloadProcedureStateId) Then
			
			ImportState = ExportImportData.DataAreaExportImportState(
				DownloadProcedureStateId);
			
			If ValueIsFilled(ImportState) Then
				Container.SetStartDate(
					ImportState.StartDate);	
				Container.SetNumberOfProcessedObjects(
					ImportState.ProcessedObjectsUpToCurrentMetadataObject);	
			Else
				RecordEventOfPreviousRecordStateAbsence(
					DownloadProcedureStateId);
			EndIf;
			
			DownloadParametersStateId = StateID(ImportParameters);
			If DownloadProcedureStateId <> DownloadParametersStateId Then
				InformationAboutImportProcedure.StateID = DownloadParametersStateId;
				RecordInformationAboutBootProcedure(InformationAboutImportProcedure);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return DownloadDatabaseData(
		ImportParameters,
		Container,
		Handlers,
		InformationAboutImportProcedure.RefsMap);
	
EndFunction

Function DownloadDatabaseData(
	ImportParameters,
	Container,
	Handlers,
	RefsMap = Undefined)
		
	LinkReplacementFlow = DataProcessors.ExportImportDataInfobaseDataImportManager.DownloadDatabaseData(
		Container,
		Handlers,
		RefsMap);
	
	If Not SaaSOperations.DataSeparationEnabled() Then
		SaaSOperations.DeleteAreaUsers(True);
	EndIf;
		
	AfterLoadingDatabaseData(
		ImportParameters,
		Container,
		Handlers,
		LinkReplacementFlow);
	
	Return LinkReplacementFlow.RefsMap();
	
EndFunction

Procedure AfterLoadingDatabaseData(ImportParameters, Container, Handlers, LinkReplacementFlow)
	
	UserMatching = Undefined;
	If ImportParameters.UploadUsers Then
		
		ExportImportInfobaseUsers.UploadInformationBaseUsers(Container);
		
		If ImportParameters.UploadUserSettings_ Then
			
			DataProcessors.ExportImportDataUserSettingsImportManager.DownloadInformationDatabaseUserSettings(
				Container, Handlers, LinkReplacementFlow);
			
		EndIf;
		
	ElsIf ImportParameters.Property("UserMatching", UserMatching)
		And ImportParameters.UserMappingIsRequired	 Then
		
		// Clear IDs if they are used.
		Query = New Query;
		Query.SetParameter("Users", UserMatching.UnloadColumn("User"));
		Query.SetParameter("IDs", UserMatching.UnloadColumn("ServiceUserID"));
		Query.Text =
		"SELECT
		|	Users.Ref AS User
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.Ref IN (&Users)
		|	AND Users.ServiceUserID IN(&IDs)";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			UserObject = Selection.User.GetObject(); // CatalogObject.Users
			UserObject.ServiceUserID = Undefined;
			UserObject.DataExchange.Load = True;
			UserObject.Write();
		EndDo;
		
		// Update IDs for used users.
		For Each UserMapping In UserMatching Do
			If Not ValueIsFilled(UserMapping.User) Then
				Continue;
			EndIf;
			UserObject = UserMapping.User.GetObject(); // CatalogObject.Users
			If UserObject.ServiceUserID <> UserMapping.ServiceUserID Then
				UserObject.ServiceUserID = UserMapping.ServiceUserID;
				UserObject.DataExchange.Load = True;
				UserObject.Write();
			EndIf;
		EndDo;
		
		// Upload settings with the replacement of the IB username.
		ReplaceUserInSettings = New Map;
		For Each UserMapping In UserMatching Do
			If ValueIsFilled(UserMapping.OldIBUserName) 
				And ValueIsFilled(UserMapping.NewIBUserName) Then
				ReplaceUserInSettings.Insert(UserMapping.OldIBUserName, UserMapping.NewIBUserName);
			EndIf;
		EndDo;
		DataProcessors.ExportImportDataUserSettingsImportManager.DownloadInformationDatabaseUserSettings(
			Container, Handlers, LinkReplacementFlow, ReplaceUserInSettings);
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(True);
	EndIf;
	
	If ImportParameters.ApplicationKind <> Undefined Then
		AppTypesInternal.SetAppTypeByMessage(ImportParameters.ApplicationKind);
	EndIf;
	
	DataSeparationEnabled = SaaSOperations.DataSeparationEnabled();
	If DataSeparationEnabled Then
		ExtensionsDirectory.ChangeUsageValueInApp(ExtensionsDirectory.AvailableInInfobase());
		PersonalAreaOfService.UpdatePersonalAreaUsage();
	EndIf;
	 
	If DataSeparationEnabled Then
		LockParameters = IBConnections.GetDataAreaSessionLock();
		If Not LockParameters.Use Then
			LockParameters.Use = True;
			IBConnections.SetDataAreaSessionLock(LockParameters);		
		EndIf;
	EndIf;
	
	JobsQueueInternalDataSeparation.AfterImportData(Container);
	
	Handlers.AfterImportData(Container);
	
	If DataSeparationEnabled Then
		LockParameters.Use = False;
		IBConnections.SetDataAreaSessionLock(LockParameters);	
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(False);
	EndIf;
	
	Container.FinalizeDownload();	
	
	FixCompletionOfBootProcedure();
	
EndProcedure

// Writes a description of the configuration
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//
Procedure SaveUploadDescription(Val Container)
	
	DumpInfoType = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo");
	ConfigurationInfoType = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "ConfigurationInfo");
	
	UploadInformation = XDTOFactory.Create(DumpInfoType);
	UploadInformation.Created = CurrentUniversalDate();
	
	ConfigurationInformation = XDTOFactory.Create(ConfigurationInfoType);
	ConfigurationInformation.Name = AppTypesServer.CurrentAppTypeName();
	ConfigurationInformation.Version = Metadata.Version;
	ConfigurationInformation.Vendor = Metadata.Vendor;
	ConfigurationInformation.Presentation = AppTypesServer.CurrentAppTypePresentation();
	
	UploadInformation.Configuration = ConfigurationInformation;
	
	FileName = Container.CreateFile(DumpInfo(), CustomData());
	WriteXDTOObjectToFile(UploadInformation, FileName);
	Container.FileRecorded(FileName);
	
EndProcedure

// Reads the description of the configuration
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//
Function ReadUploadInformation(Container)
	
	File = Container.GetFileFromFolder(DumpInfo());
	If File = Undefined Then
		Raise NStr("vi = 'Trong thông tin về thành phần tệp kết xuất, không có mô tả tệp với thông tin về kết xuất';
					|ru = 'В информации о составе файлов выгрузки отсутствует описание файла с информацией о выгрузке';
					|en = 'The information about export files does not contain details of the file with export information.'; fa = 'The information about export files does not contain details of the file with export information.';
					|it = 'The information about export files does not contain details of the file with export information.';
					|pl = 'The information about export files does not contain details of the file with export information.';
					|tr = 'Karşıya aktarma dosyasının oluşturulma bilgilerinde karşıya aktarma bilgi dosyasının ayrıntıları eksik'");
	EndIf;
	
	Container.UnzipFile(File);
	
	Result =  ReadXDTOObjectFromFile(File.FullName, XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo"));
	
	DeleteFiles(File.FullName);
	
	Return Result;
	
EndFunction

// Returns the name of the element in the write/read stream that stores the xdto Object.
//
// Returns:
//	String - element name.
//
Function NameOfElementContainingXDTOObject()
	
	Return "XDTODataObject";
	
EndFunction

// Returns the name of the element in the write/read stream where the object is stored.
//
// Returns:
//	String - element name.
//
Function NameOfElementContainingObject()
	
	Return "Data";
	
EndFunction

// Returns an array of the namespace for writing packages.
//
// Parameters:
//	NamespaceURI - String - namespace.
//
// Returns:
//	Array of String - an array of namespaces.
//
Function GetNamespacesForPackageEntries(Val NamespaceURI)
	
	Result = New Array();
	Result.Add(NamespaceURI);
	
	Dependencies = XDTOFactory.Packages.Get(NamespaceURI).Dependencies;
	For Each Dependence In Dependencies Do
		DependentNamespaces = GetNamespacesForPackageEntries(Dependence.NamespaceURI);
		CommonClientServer.SupplementArray(Result, DependentNamespaces, True);
	EndDo;
	
	Return Result;
	
EndFunction

// Fills the array with a collection of reference object metadata.
//
// Parameters:
//	ArrayOfMetadataCollections - Array of MetadataObject - metadata object.
//
Procedure PopulateCollectionsOfReferenceObjects(ArrayOfMetadataCollections)

	ArrayOfMetadataCollections.Add(Metadata.Catalogs);
	ArrayOfMetadataCollections.Add(Metadata.Documents);
	ArrayOfMetadataCollections.Add(Metadata.BusinessProcesses);
	ArrayOfMetadataCollections.Add(Metadata.Tasks);
	ArrayOfMetadataCollections.Add(Metadata.ChartsOfAccounts);
	ArrayOfMetadataCollections.Add(Metadata.ExchangePlans);
	ArrayOfMetadataCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	ArrayOfMetadataCollections.Add(Metadata.ChartsOfCalculationTypes);
	
EndProcedure

// Fills the array with a collection of recordset metadata.
//
// Parameters:
//	ArrayOfMetadataCollections - Array of MetadataObjectCollection - Array.
//
Procedure PopulateRecordsetCollections(ArrayOfMetadataCollections)
	
	ArrayOfMetadataCollections.Add(Metadata.InformationRegisters);
	ArrayOfMetadataCollections.Add(Metadata.AccumulationRegisters);
	ArrayOfMetadataCollections.Add(Metadata.AccountingRegisters);
	ArrayOfMetadataCollections.Add(Metadata.Sequences);
	ArrayOfMetadataCollections.Add(Metadata.CalculationRegisters);
	For Each CalculationRegister In Metadata.CalculationRegisters Do
		ArrayOfMetadataCollections.Add(CalculationRegister.Recalculations);
	EndDo;
	
EndProcedure

// Fills the array with a collection of constant metadata.
//
// Parameters:
//	ArrayOfMetadataCollections - Array of MetadataObjectCollection - Array.
//
Procedure FillCollectionsOfConstants(ArrayOfMetadataCollections)
	
	ArrayOfMetadataCollections.Add(Metadata.Constants);
	
EndProcedure

// Returns a complete list of objects from the specified collections
//
// Parameters:
//  Collections - Array of MetadataObjectCollection - Collections.
//
// Returns:
//  Array of MetadataObject - metadata object.
//
Function AllCollectionMetadata(Val Collections)
	
	Result = New Array;
	For Each Collection In Collections Do
		
		For Each Object In Collection Do
			Result.Add(Object);
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the reference point of the business process
//
// Returns:
//	Map of KeyAndValue:
//	  *Key - Type - the type of business process point reference.
//	  *Value - MetadataObject - business process.
//
Function BusinessProcessesRoutePointsRefs()
	
	Result = New Map();
	
	For Each BusinessProcess In Metadata.BusinessProcesses Do
		
		Result.Insert(Type("BusinessProcessRoutePointRef." + BusinessProcess.Name), BusinessProcess);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the name of the file with the upload digest.
//
// Returns:
//	String - Description
Function Digest() Export
	Return "Digest";
EndFunction

// Returns the name of the file with upload warnings.
//
// Returns:
//	String - Description
Function DumpWarnings() Export
	Return "DumpWarnings";
EndFunction

// Extensions
// 
// Returns:
//  String
Function Extensions() Export
	Return "Extensions";
EndFunction

// Custom extensions
// 
// Returns:
//  String
Function CustomExtensions() Export 
	Return "CustomExtensions";	
EndFunction

// Returns the name of the file with the application views.
// 
// Returns:
//  String
Function ApplicationTypes() Export 
	Return "ApplicationTypes";
EndFunction

// Returns the name of a file with predefined duplicates.
//
// Returns:
//	String - Description
Function PredefinedDataDuplicates() Export
	Return "PredefinedDataDuplicates";
EndFunction

// Writes the xdto Object to a file.
//
// Parameters:
//	XDTODataObject - XDTODataObject - writable xdto Object.
//	FileName - String - full path to the file.
//	DefaultNamespacePrefix - String - prefix.
//
Procedure WriteXDTOObjectToFile(Val XDTODataObject, Val FileName, Val DefaultNamespacePrefix = "")
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	
	NamespacesPrefixes = NamespacesPrefixes();
	ObjectNamespace = XDTODataObject.Type().NamespaceURI;
	If IsBlankString(DefaultNamespacePrefix) Then
		DefaultNamespacePrefix = NamespacesPrefixes.Get(ObjectNamespace);
	EndIf;
	NamespacesUsed = GetNamespacesForPackageEntries(ObjectNamespace);
	
	WriteStream.WriteStartElement(NameOfElementContainingXDTOObject());
	
	For Each NamespaceUsed In NamespacesUsed Do
		NamespacesPrefix = NamespacesPrefixes.Get(NamespaceUsed);
		If NamespacesPrefix = DefaultNamespacePrefix Then
			WriteStream.WriteNamespaceMapping("", NamespaceUsed);
		Else
			WriteStream.WriteNamespaceMapping(NamespacesPrefix, NamespaceUsed);
		EndIf;
	EndDo;
	
	XDTOFactory.WriteXML(WriteStream, XDTODataObject);
	
	WriteStream.WriteEndElement();
	
	WriteStream.Close();
	
EndProcedure

Function XMLSchema(SchemaBinaryData)
	
	ReadStream = SchemaBinaryData.OpenStreamForRead();
	
	Read = New XMLReader;
	Read.OpenStream(ReadStream);
	
	Builder = New DOMBuilder;
	Document = Builder.Read(Read); // DOMElement
	
	ReadStream.Close();
	
	CircuitBuilder = New XMLSchemaBuilder;	
	
	Return CircuitBuilder.CreateXMLSchema(Document);

EndFunction

Function FactoryByScheme(Schema)
	
	SetOfSchemes = New XMLSchemaSet;
	SetOfSchemes.Add(Schema);
	
	Return New XDTOFactory(SetOfSchemes);

EndFunction

Procedure UnloadConfigurationDiagram(Container, ExportingParameters)
	
	ConfigurationSchemaData = Undefined;
	If Not ExportingParameters.Property("ConfigurationSchemaData", ConfigurationSchemaData) Then
		ConfigurationSchemaData = ConfigurationSchema.SchemaBinaryData(False, False);	
	EndIf;
	
	FullFileName = Container.CreateCustomFile("xsd", "ConfigScheme");
	ConfigurationSchemaData.Write(FullFileName);
	
	Container.SetNumberOfObjects(FullFileName, 1);
	
EndProcedure

Procedure RestoreExtensions(RecoveryExtensions)

	FilterStructure1 = New Structure("Name");

	For Each ExtensionForRecovery In RecoveryExtensions Do

		FilterStructure1.Name = ExtensionForRecovery.Name;

		DataOfRestoredExtension = ExtensionForRecovery.Data;

		InstalledExtensions = ConfigurationExtensions.Get(FilterStructure1,
			ConfigurationExtensionsSource.Database);

		If ValueIsFilled(InstalledExtensions) Then

			InstalledExtension = InstalledExtensions[0];

			If InstalledExtension.Active = ExtensionForRecovery.Active
				And InstalledExtension.SafeMode = ExtensionForRecovery.SafeMode
				And InstalledExtension.UseDefaultRolesForAllUsers = ExtensionForRecovery.UseDefaultRolesForAllUsers
				And InstalledExtension.UsedInDistributedInfoBase = ExtensionForRecovery.UsedInDistributedInfoBase
				And InstalledExtension.UnsafeActionProtection.UnsafeOperationWarnings = ExtensionForRecovery.UnsafeActionProtection.UnsafeOperationWarnings Then			
					
				If InstalledExtension.UUID = ExtensionForRecovery.UUID Then
					Continue;
				EndIf;
												
				MetadataOfInstalledExtension = New ConfigurationMetadataObject(InstalledExtension.GetData());
				MetadataOfExtensionBeingRestored = New ConfigurationMetadataObject(DataOfRestoredExtension);

				If MetadataOfInstalledExtension.Version = MetadataOfExtensionBeingRestored.Version Then									
					Continue;
				EndIf;

			EndIf;
			
			InstalledExtension.Delete();

		EndIf;

		RecoverableExtension = ConfigurationExtensions.Create();
		FillPropertyValues(RecoverableExtension, ExtensionForRecovery);
		RecoverableExtension.Write(DataOfRestoredExtension);
			
	EndDo;

EndProcedure

Procedure RestoreExtensionFrames(RecoveryExtensions)

	FilterStructure1 = New Structure("Name");

	For Each ExtensionForRecovery In RecoveryExtensions Do

		DataOfRestoredExtension = ExtensionForRecovery.Data;
		MetadataOfExtensionBeingRestored = New ConfigurationMetadataObject(DataOfRestoredExtension);
		
		FilterStructure1.Name = MetadataOfExtensionBeingRestored.Name;	

		InstalledExtensions = ConfigurationExtensions.Get(FilterStructure1,
			ConfigurationExtensionsSource.Database);	
		
		If ValueIsFilled(InstalledExtensions) Then

			InstalledExtension = InstalledExtensions[0];

			MetadataOfInstalledExtension = New ConfigurationMetadataObject(InstalledExtension.GetData());

			If MetadataOfInstalledExtension.Version = MetadataOfExtensionBeingRestored.Version Then
				Continue;
			EndIf;
			
			InstalledExtension.Delete();

		EndIf;

		RecoverableExtension = ConfigurationExtensions.Create();
		RecoverableExtension.SafeMode = False;
		
		UnsafeActionProtection = New UnsafeOperationProtectionDescription;
		UnsafeActionProtection.UnsafeOperationWarnings = False;
		RecoverableExtension.UnsafeActionProtection = UnsafeActionProtection;
		
		RecoverableExtension.Write(DataOfRestoredExtension);
				
	EndDo;
	
EndProcedure

Procedure AddConstantToMetadataList(ObjectMetadata, MetadataList, Types)
	
	For Each Type In Types Do
		
		If ObjectMetadata.Type.ContainsType(Type) Then 
			MetadataList.Insert(ObjectMetadata.FullName(), New Array);		
			Return;
		EndIf;

	EndDo;
		
EndProcedure

Procedure AddReferenceTypeToMetadataList(ObjectMetadata, MetadataList, Types)
	
	StructuresArray = New Array;
	
	For Each Attribute In ObjectMetadata.Attributes Do 
		
		AddPropsToArray(StructuresArray, Attribute,, Types);
		
	EndDo;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do 
		
		For Each Attribute In TabularSection.Attributes Do
			
			AddPropsToArray(StructuresArray, Attribute, TabularSection, Types);
			
		EndDo;
		
	EndDo;
	
	InsertMetadataObjectIntoMatch(ObjectMetadata.FullName(), MetadataList, StructuresArray);
	
EndProcedure

Procedure AddRegisterToMetadataTable(ObjectMetadata, Val MetadataList, Types)
	
	StructuresArray = New Array;
	This_Is_Recalculation = Metadata.CalculationRegisters.Contains(ObjectMetadata.Parent());
	
	For Each Dimension In ObjectMetadata.Dimensions Do 
		
		If This_Is_Recalculation Then
			Dimension = Dimension.RegisterDimension;
		EndIf;
		
		AddPropsToArray(StructuresArray, Dimension,, Types);
		
	EndDo;
		
	If Metadata.Sequences.Contains(ObjectMetadata) Then 
		
		For Each DocumentMetadata In ObjectMetadata.Documents Do
			
			ManagerOfDocument = Common.ObjectManagerByFullName(
				DocumentMetadata.FullName());
			DocumentType = TypeOf(ManagerOfDocument.EmptyRef());
			
			If Types.Find(DocumentType) <> Undefined Then 
				
				Structure = AttributesStructure1();
				Structure.AttributeName = "Recorder";
				
				StructuresArray.Add(Structure);
				
				Break;
			EndIf;
			
		EndDo;
		
	ElsIf Not This_Is_Recalculation Then
		
		For Each Attribute In ObjectMetadata.Attributes Do 
			
			AddPropsToArray(
				StructuresArray,
				Attribute,,
				Types);
			
		EndDo;
		
		For Each Resource In ObjectMetadata.Resources Do 
			
			AddPropsToArray(
				StructuresArray,
				Resource,,
				Types);
			
		EndDo;
		
		If Not CommonCTL.IsIndependentRecordSet(ObjectMetadata) Then
			AddPropsToArray(
				StructuresArray,
				ObjectMetadata.StandardAttributes.Recorder,,
				Types);	
		EndIf;
		
		If CommonCTL.IsAccountingRegister(ObjectMetadata)
			And ObjectMetadata.ChartOfAccounts <> Undefined Then
			
			ChartOfAccountsManager = Common.ObjectManagerByFullName(
				ObjectMetadata.ChartOfAccounts.FullName());
			ChartOfAccountsType = TypeOf(ChartOfAccountsManager.EmptyRef());
			
			If Types.Find(ChartOfAccountsType) <> Undefined Then 
				
				If ObjectMetadata.Correspondence Then 
					Structure = AttributesStructure1();
					Structure.AttributeName = "AccountDr";		
					StructuresArray.Add(Structure);
					
					Structure = AttributesStructure1();
					Structure.AttributeName = "AccountCr";		
					StructuresArray.Add(Structure);
				Else		
					Structure = AttributesStructure1();
					Structure.AttributeName = "Account";		
					StructuresArray.Add(Structure);
				EndIf;
				
			EndIf;
	
		EndIf;
				
	EndIf;
	
	InsertMetadataObjectIntoMatch(ObjectMetadata.FullName(), MetadataList, StructuresArray);
	
EndProcedure

Procedure AddPropsToArray(StructuresArray, Attribute, TabularSection = Undefined, Types)
	
	For Each Type In Types Do
		
		If Attribute.Type.ContainsType(Type) Then 
			AttributeName      = Attribute.Name;
			TabularSectionName = ?(TabularSection = Undefined, Undefined, TabularSection.Name);
			
			Structure = AttributesStructure1();
			Structure.TabularSectionName = TabularSectionName;
			Structure.AttributeName      = AttributeName;
			
			StructuresArray.Add(Structure);
			
			Return;
		EndIf;
		
	EndDo;
			
EndProcedure

Procedure InsertMetadataObjectIntoMatch(FullMetadataName, MetadataList, StructuresArray)
	
	If StructuresArray.Count() = 0 Then 
		Return;
	EndIf;
	
	MetadataList.Insert(FullMetadataName, StructuresArray);
	
EndProcedure

// Returns:
// 	Structure:
// * AttributeName - String
// * TabularSectionName - String
// 
Function AttributesStructure1()
	
	Result = New Structure;
	Result.Insert("TabularSectionName");
	Result.Insert("AttributeName");
	
	Return Result;
	
EndFunction

// Returns the backup type depending on the upload parameters.
// Parameters:
//  ImportParameters - Structure - Parameters
//
// Returns:
//  String - one of the values: Normal, Full, Differential
Function BackupType(ImportParameters) 

	If ImportParameters.Property("BackupType") Then
		Return ImportParameters.BackupType;
	EndIf;
		
	Return BackupTypeNormal();
  
EndFunction

Function StateID(ImportParameters)
	
	If Not ValueIsFilled(ImportParameters) Then
		Return Undefined;
	EndIf;
	
	StateID = Undefined;
	ImportParameters.Property("StateID", StateID);
	
	Return StateID;
	
EndFunction

Procedure RestoreAreaExtensions(ExtensionData_)
		
	ExtensionsDirectory.ReadDataOfRecoverableAreaExtensions(ExtensionData_);

	DataAreaKey = Undefined;
	If ExtensionData_.Property("DataAreaKey", DataAreaKey) Then
		Constants.DataAreaKey.Set(DataAreaKey);
	EndIf;

	RecoveryExtensions = Undefined;
	If ExtensionData_.Property("RecoveryExtensions", RecoveryExtensions) Then

		ExtensionsDirectory.RestoreExtensionsToNewArea(RecoveryExtensions);

	EndIf;

	ExtensionsDirectory.RecordDataOfRecoverableAreaExtensions(RecoveryExtensions);
	
EndProcedure

Procedure RecordEventOfPreviousRecordStateAbsence(StateID)
	
	WriteLogEvent(
		NStr("vi = 'Kết xuất kết nhập dữ liệu. Chưa tìm thấy bản ghi trạng thái trước đó';
			|ru = 'Выгрузка загрузка данных. Не найдена запись предыдущего состояния';
			|en = 'Data export and import. Cannot find previous state record'; fa = 'Data export and import. Cannot find previous state record';
			|it = 'Выгрузка загрузка данных. Не найдена запись предыдущего состояния';
			|pl = 'Data export and import. Cannot find previous state record';
			|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı. Bir önceki durumun kaydı bulunamadı.'", Common.DefaultLanguageCode()),
		EventLogLevel.Warning,,
		StateID,
		NStr("vi = 'Đã bỏ qua khôi phục trạng thái';
			|ru = 'Восстановление состояния пропущено';
			|en = 'State recovery is skipped'; fa = 'State recovery is skipped';
			|it = 'Восстановление состояния пропущено';
			|pl = 'State recovery is skipped';
			|tr = 'Durum geri yüklemesi atlandı'"));
		
EndProcedure

Function HashSumOfSource(Archive)
	
	NameOfContentFile = GetFileName(PackageContents());
	
	TempDirectory = GetTempFileName();
	CreateDirectory(TempDirectory);
	
	UnzipArchiveFile(Archive, TempDirectory, NameOfContentFile);

	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.AppendFile(
		TempDirectory + GetPathSeparator() + NameOfContentFile);
	
	DeleteFiles(TempDirectory);
	
	Return DataHashing.HashSum;

EndFunction

Function HashSumOfParameters(ImportParameters)
	
	ControlledLoadingParameters = New Structure(
		"UploadUserSettings_, UploadUsers, CollapseSeparatedUsers");
	FillPropertyValues(ControlledLoadingParameters, ImportParameters);
	
	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.Append(
		Common.ValueToXMLString(ControlledLoadingParameters));
	
	Return DataHashing.HashSum;
	
EndFunction

Function NewTableOfNumberOfProcessedObjects()
	NumberOfProcessedObjectsTable = New ValueTable;
	NumberOfProcessedObjectsTable.Columns.Add("FullName", New TypeDescription("String"));
	NumberOfProcessedObjectsTable.Columns.Add("NumberOfObjects", New TypeDescription("Number"));
	Return NumberOfProcessedObjectsTable;
EndFunction

Function TableOfNumberOfExportedObjectsBySubqueries(Subqueries)
	SubquerySeparator_ = Chars.LF + " UNION ALL " + Chars.LF;		
	Query = New Query(StrConcat(Subqueries, SubquerySeparator_));
	Return Query.Execute().Unload();
EndFunction

Procedure AddTableOfProcessedObjectsNumber(NumberOfProcessedObjectsTable, Supplement_Table)
	For Each SupplementTableRow In Supplement_Table Do
		FillPropertyValues(NumberOfProcessedObjectsTable.Add(), SupplementTableRow);
	EndDo;
EndProcedure

#Region ParallelExportImport

// Process thread messages.
// 
// Parameters:
//  MessageTable - See NewThreadMessagesTable
//  Container - DataProcessorObject.ExportImportDataContainerManager - Cur Container
Procedure ProcessThreadMessages(MessageTable, Container)
	
	If Not ValueIsFilled(MessageTable) Then
		Return;
	EndIf;
	
	MessageTable.Sort("DateSent, MessageNo");
	
	For Each TableRow In MessageTable Do
		Container.ProcessThreadMessage(TableRow.MethodName, TableRow.MessageData);
	EndDo;
	
EndProcedure

// Receive stream messages.
// 
// Parameters:
//  MessageTable - See NewThreadMessagesTable
//  Job - BackgroundJob - The task that performs the upload/ download
//  ProcessID - UUID - ID of the upload/upload process
Procedure ReceiveThreadMessages(MessageTable, Job, ProcessID)
	
	ThreadMessages = Job.GetUserMessages(True);
	
	If Not ValueIsFilled(ThreadMessages) Then
		Return;
	EndIf;
	
	ThreadMessageReading = New JSONReader();
	
	For Each Message In ThreadMessages Do
		
		If Message.TargetID <> ProcessID Then
			Continue;
		EndIf;
		
		ThreadMessageReading.SetString(Message.Text);
		ThreadMessage = ReadJSON(ThreadMessageReading);
		
		TableRow = MessageTable.Add();
		FillPropertyValues(TableRow, ThreadMessage);
		
		TableRow.JobKey = Job.Key;
		
	EndDo;
	
	ThreadMessageReading.Close();
	
EndProcedure

// The flow assignment is complete.
// 
// Parameters:
//  Job - BackgroundJob - The task that performs the upload/ download
//  MessageTable - See NewThreadMessagesTable
// 
// Returns:
//  Boolean
Function StreamJobCompleted(Job, MessageTable)
	
	FilterParameters = New Structure();
	FilterParameters.Insert("MethodName", StreamMessageMethodName_ExportEnd());
	FilterParameters.Insert("JobKey", Job.Key);
	
	FoundRows = MessageTable.FindRows(FilterParameters);
	
	Return ValueIsFilled(FoundRows);
	
EndFunction

// A new table of thread messages.
// 
// Returns:
//  ValueTable - New Table Of Thread Messages:
// * DateSent - Number - universal date in milliseconds
// * MethodName - String - Method name
// * MessageData - Structure - Message data
// * JobKey - String - Sender's background task key
Function NewThreadMessagesTable()
	
	NumberType = New TypeDescription("Number", New NumberQualifiers(32, 0, AllowedSign.Nonnegative));
	StringType = New TypeDescription("String", , New StringQualifiers(256, AllowedLength.Variable));
	
	MessageTable = New ValueTable();
	MessageTable.Columns.Add("DateSent", NumberType);
	MessageTable.Columns.Add("MessageNo", NumberType);
	MessageTable.Columns.Add("MethodName", StringType);
	MessageTable.Columns.Add("MessageData");
	MessageTable.Columns.Add("JobKey", StringType);
	
	Return MessageTable;
	
EndFunction

// The key for the task of uploading uploading data.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager
// 
// Returns:
//  String - Task Key For Uploading Uploading Data
Function ExportImportDataJobKey(Container)
	
	Return StrTemplate(
		"%1_Stream_%2",
		Container.ProcessID(),
		Container.NextStreamNumber());
	
EndFunction

// The stream number from the job key.
// 
// Parameters:
//  JobKey - String - task key
// 
// Returns:
//  String - The Stream Number From The Job Key
Function ThreadNumberFromJobKey(JobKey)
	
	ThreadNumber = "";
	KeyParts = StrSplit(JobKey, "_", False);
	
	If KeyParts.Count() = 3 Then
		ThreadNumber = KeyParts[2];
	EndIf;
	
	Return ThreadNumber;
	
EndFunction

// Start additional threads for uploading data downloads.
// 
// Parameters:
//  Jobs - Array of BackgroundJob - Running Jobs
//  ProcessParameters - Structure - To download data, see processing the offload and offload of data from the manager and offload of data from the information database.newparameters of the processagruzedannyhinformation database
//									To upload data, see processing the uploadinggroupdannyhmanageredgroupdannyhinformation database.newparameters of the process of loading the specified information database
Procedure StartAdditionalExportImportDataThreads(Jobs, ProcessParameters)
	
	Return;
	
EndProcedure

#EndRegion

#EndRegion
