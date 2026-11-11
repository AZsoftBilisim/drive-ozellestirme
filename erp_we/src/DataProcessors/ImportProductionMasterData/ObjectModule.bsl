
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var DescriptionOfUploadedData;

Var Cache; // Structure
Var ErrorProtocolTable; // ValueTable

Var CurrentAction1; // String
Var CurrentPartitionKey; // String
Var CurFileName; // String
Var CurrentID; // String

Var DataSource;
Var DataSourceObject;
Var DataSourceSettings; // See Catalogs.SourcesToImportProductionMasterData.DataSourceSettingsConstructor
Var DataSourceAttributeSettings; // ValueTable
Var BankingDetailsSettings; // ValueTable

Var DataPortion; // ValueTree
Var DataChunkSize; // Number

Var IDsTable; // ValueTable
Var BatchSearchTable; // ValueTable
Var DataTableDescription; // Structure
Var DataTable; // ValueTable
Var TableOfAdditionalInformation; // ValueTable

Var Key_Item;
Var Key_Equipment;
Var Key_BillOfMaterials;
Var Key_Materials;
Var Key_LaborCosts;
Var _OperationKey;
Var Key_Stages;
Var Key_TypesOfWork;
Var _ReplacementKey;
Var Key_Replacements_Materials;

#EndRegion

#Region Public

// Perform an action.
// 
// Parameters:
//  ActionName - String - action name
//  Parameters - Structure:
//  * DataSource - CatalogRef.SourcesToImportProductionMasterData
// 
// Returns:
//  See CompleteAction
Function ExecuteAction(ActionName, Parameters) Export
	
	CurrentAction1 = ActionName;
	DataSource = Parameters.DataSource;
	
	WriteLogEvent(
		DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
		EventLogLevel.Information,,,
		StrTemplate(NStr("vi = 'Thao tác ""%1"" đối với nguồn ""%2"": Khởi động';
						|ru = 'Действие ""%1"" для источника ""%2"": Запуск';
						|en = 'The ""%1"" action for the ""%2"" source: Start'; fa = 'The ""%1"" action for the ""%2"" source: Start';
						|it = 'Действие ""%1"" для источника ""%2"": Запуск';
						|pl = 'The ""%1"" action for the ""%2"" source: Start';
						|tr = '""%2"" kaynağı için ""%1"" işlemi: Başlatma'"), ActionName, DataSource));
		
	InitializeVariablesBeforePerformingAction(ActionName);
		
	PerformActionInChunks();
	
	Result = CompleteAction();
	
	WriteResultOfExecutionToLog(Result);
		
	WriteLogEvent(
		DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
		EventLogLevel.Information,,,
		StrTemplate(NStr("vi = 'Thao tác ""%1"" đối với nguồn ""%2"": Hoàn thành';
						|ru = 'Действие ""%1"" для источника ""%2"": Завершение';
						|en = 'The ""%1"" action for the ""%2"" source: Complete'; fa = 'The ""%1"" action for the ""%2"" source: Complete';
						|it = 'Действие ""%1"" для источника ""%2"": Завершение';
						|pl = 'The ""%1"" action for the ""%2"" source: Complete';
						|tr = '""%2"" kaynağı için ""%1"" işlemi: Tamamlama'"), ActionName, DataSource));
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region Actions

Procedure InitializeVariablesBeforePerformingAction(ActionName)
	
	DataSourceObject = DataSource.GetObject();
	
	DataSourceSettings = Catalogs.SourcesToImportProductionMasterData.DataSourceSettings(DataSource);
	DescriptionOfUploadedData = ProductDataManagement.DescriptionOfUploadedData(DataSourceSettings);
	
	DataSourceAttributeSettings = Catalogs.SourcesToImportProductionMasterData.SourceAttributeSettings(DataSource, DescriptionOfUploadedData); // ValueTable
	DataSourceAttributeSettings.Indexes.Add("SectionKey");
	DataSourceAttributeSettings.Indexes.Add("SectionKey,ReferentialType");
	
	CurrentPartitionKey = "";
	CurFileName = "";
	
	ErrorProtocolTable.Clear();
	ErrorProtocolTable.Indexes.Clear();
	
	Key_Item     = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("Products");
	Key_Equipment     = XMLString(DataSourceSettings.HardwareLoadingOption);
	Key_BillOfMaterials     = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("BillsOfMaterials");
	Key_Materials        = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("BillsOfMaterials", "MaterialsAndServices");
	Key_LaborCosts     = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("BillsOfMaterials", "LaborCosts");
	Key_Stages            = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("ProductionStages");
	_OperationKey         = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("ManufacturingOperations");
	Key_TypesOfWork        = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("EmployeeWorkKinds");
	_ReplacementKey           = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("EngineeringChangeOrder");
	Key_Replacements_Materials = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement("EngineeringChangeOrder", "UsedMaterials");
	
	InitializeCache();
	
EndProcedure

Procedure PerformActionInChunks()
	
	If DataSourceObject.DeletionMark Then
		AddEntryToErrorLog(
			Enums.ImportMasterDataIssueTypes.DataSourceSettings,
			StrTemplate(NStr("vi = 'Đã đặt dấu xóa nguồn dữ liệu ""%1"".';
							|ru = 'Источник данных ""%1"" помечен на удаление.';
							|en = 'The %1 data source is marked for deletion.'; fa = 'The %1 data source is marked for deletion.';
							|it = 'Источник данных ""%1"" помечен на удаление.';
							|pl = 'The %1 data source is marked for deletion.';
							|tr = '""%1"" veri kaynağı silinmek üzere işaretlendi.'"), DataSource));
		Return;
	EndIf;
	
	If Not DataSourceObject.CheckFilling() Then
		AddEntryToErrorLog(
			Enums.ImportMasterDataIssueTypes.DataSourceSettings,
			NStr("vi = 'Chưa kiểm tra tùy chỉnh nguồn dữ liệu.';
				|ru = 'Не пройдена проверка настроек источника данных.';
				|en = 'Data source settings are not checked.'; fa = 'Data source settings are not checked.';
				|it = 'Не пройдена проверка настроек источника данных.';
				|pl = 'Data source settings are not checked.';
				|tr = 'Veri kaynağı ayarları kontrolü yapılmadı.'"));
		Return;
	EndIf;
	
	DataLocationDirectory = New File(DataSourceSettings.LocationOfData);
	If Not DataLocationDirectory.Exists() Then
		AddEntryToErrorLog(
			Enums.ImportMasterDataIssueTypes.DataSourceSettings,
			NStr("vi = 'Không tìm thấy thư mục có vị trí tệp dữ liệu.';
				|ru = 'Каталог с расположением файлов данных не найден.';
				|en = 'A directory with data file location is not found.'; fa = 'A directory with data file location is not found.';
				|it = 'Каталог с расположением файлов данных не найден.';
				|pl = 'A directory with data file location is not found.';
				|tr = 'Veri dosyalarının bulunduğu katalog bulunamadı.'"));
		Return;
	EndIf;
	
	ExchangeFormat = DataSourceObject.ExchangeFormat;
	If ExchangeFormat = Enums.ImportMasterDataFormats.XML Then
		DataReader = New XMLReader();
	ElsIf ExchangeFormat = Enums.ImportMasterDataFormats.JSON Then
		DataReader = New JSONReader();
	Else
		AddEntryToErrorLog(
			Enums.ImportMasterDataIssueTypes.DataSourceSettings,
			StrTemplate(NStr("vi = 'Không hỗ trợ định dạng trao đổi đã chỉ ra trong tùy chỉnh nguồn. %1';
							|ru = 'Формат обмена, указанный в настройках источника, не поддерживается. %1';
							|en = 'The exchange format specified in the source settings is not supported. %1'; fa = 'The exchange format specified in the source settings is not supported. %1';
							|it = 'Формат обмена, указанный в настройках источника, не поддерживается. %1';
							|pl = 'The exchange format specified in the source settings is not supported. %1';
							|tr = 'Kaynak ayarlarında belirtilen değişim formatı desteklenmiyor. %1'")), ExchangeFormat);
		Return;
	EndIf;
	
	Try
	
		For Each CurrentPartitionKey In ProductDataManagementClientServer.OrderOfProcessingSectionsOfSource(DataSourceSettings) Do
			
			DataPortion = New ValueTree;
			
			FilesFound = FindFiles(
				DataLocationDirectory.FullName,
				StrTemplate("%1*.%2", CurrentPartitionKey, Lower(ExchangeFormat)),
				False);
			
			For Each FoundFile In FilesFound Do
				
				ProcessDataFile(DataReader, FoundFile);
				
			EndDo;
			
		EndDo;
	
	Except
		
		If Not Cache.ErrorIsRecordedInProtocol Then
			AddEntryToErrorLogForException(
				Enums.ImportMasterDataIssueTypes.Other,
				NStr("vi = 'Lỗi không mong muốn. Đã ngắt thực hiện thao tác.';
					|ru = 'Непредвиденная ошибка. Выполнение действия прервано.';
					|en = 'Unexpected error. The action is terminated.'; fa = 'Unexpected error. The action is terminated.';
					|it = 'Непредвиденная ошибка. Выполнение действия прервано.';
					|pl = 'Unexpected error. The action is terminated.';
					|tr = 'Öngörülmeyen hata. İşlem iptal edildi.'"),
				ErrorInfo());
			Cache.ErrorIsRecordedInProtocol = True;
		EndIf;
		
	EndTry
	
EndProcedure

// Result of the processing action
// 
// Returns:
//  Structure:
// * ErrorsCount - Number
Function CompleteAction() Export
	
	ProcessTagValues();
	
	CompleteProcessingOfDataLoadingErrors();
	
	StructureOfCounters = Cache.StructureOfCounters.Fixed_;
	
	ErrorsCount = 0;
	For Each KeyAndValue In StructureOfCounters.IssuesTypes Do
		ErrorsCount = ErrorsCount + KeyAndValue.Value;
	EndDo;
	
	Result = New Structure;
	Result.Insert("StartDate",         Cache.ExecutionStarted);
	Result.Insert("EndDate",      CurrentSessionDate());
	Result.Insert("ErrorsCount",   ErrorsCount);
	
	If CurrentAction1 = DataProcessors.ImportProductionMasterData.UploadDataAction() Then
		
		If ErrorsCount = 0 Then
			If Cache.ProcessedFiles.Count() > 0 Then
				State = Enums.ImportMasterDataStates.SuccessfullyCompleted;
			Else
				State = Enums.ImportMasterDataStates.NoData1;
			EndIf;
		Else
			If StructureOfCounters.IssuesTypes.Get(Enums.ImportMasterDataIssueTypes.DataSourceSettings) <> Undefined
				Or StructureOfCounters.IssuesTypes.Get(Enums.ImportMasterDataIssueTypes.DataFileFormat) <> Undefined Then
				State = Enums.ImportMasterDataStates.NotExecuted;
			Else
				State = Enums.ImportMasterDataStates.WasCompletedWithErrors;
			EndIf;
		EndIf;
		
		Result.Insert("State", State);
		PerformActionsWithFilesAfterUploading(State);
		
		AdditionalParameters = New Structure(StoredCacheData());
		FillPropertyValues(AdditionalParameters, Cache);
		
		StructureOfData = Common.CopyRecursive(Result);
		StructureOfData.Insert("AdditionalParameters", New ValueStorage(AdditionalParameters));
		
		InformationRegisters.MasterDataImportSettings.RecordSourceSettings(DataSource, StructureOfData);
		
	EndIf;
	
	Result.Insert("StructureOfCounters", StructureOfCounters);
	
	Return Result;
	
EndFunction

Procedure FillIDs()
	
	InitializeTablesForFillingInIdentifiers();
	
	FillInTableOfIdentifiers(DataPortion.Rows);
	
	AddIdentifiersToMatchingRegister();
	
EndProcedure

Procedure ImportData()
	
	InitializeTablesForDataLoading();
	
	FillDataTable(DataPortion.Rows);
	
	PerformBatchSearchForLinks();
	
	CreateUpdateUploadedData();
	
EndProcedure

Procedure PerformActionsWithFilesAfterUploading(State)
	
	If State = Enums.ImportMasterDataStates.DoNotPerformed
			Or Cache.ProcessedFiles.Count() = 0 Then
		Return;
	EndIf;
	
	ActionDetails = Undefined;
	If Not DataSourceSettings.ActionsWithFiles.Property(XMLString(State), ActionDetails) Then
		Return;
	EndIf;
	
	If ActionDetails.Action = Enums.ImportMasterDataActionsWithFiles.MoveTo
		And Lower(CommonClientServer.AddLastPathSeparator(ActionDetails.Directory)) =
			Lower(CommonClientServer.AddLastPathSeparator(DataSourceSettings.LocationOfData)) Then
		Return;
	EndIf;
	
	EndDateAndTimeOfProcessing = Format(CurrentSessionDate(), "DF='yyy-MM-dd HHmmss';");
	
	For Each File In Cache.ProcessedFiles Do
		
		FullName = File.FullName;
		
		Try
		
			If ActionDetails.Action = Enums.ImportMasterDataActionsWithFiles.Delete Then
				
				DeleteFiles(FullName);
				
				WriteLogEvent(DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
					EventLogLevel.Information,,,
					StrTemplate(NStr("vi = 'Đã xóa tệp: %1';
									|ru = 'Удален файл: %1';
									|en = 'The file is deleted: %1'; fa = 'The file is deleted: %1';
									|it = 'Il file è stato eliminato: %1';
									|pl = 'Usunięto plik: %1';
									|tr = 'Dosya silindi: %1'"), FullName));
				
			ElsIf ActionDetails.Action = Enums.ImportMasterDataActionsWithFiles.MoveTo Then
				
				DirectoryName = CommonClientServer.AddLastPathSeparator(ActionDetails.Directory);
				CreateDirectory(DirectoryName);
				
				Found_1 = FindFiles(DirectoryName, File.Name);
				If Found_1.Count() = 0 Then
					FullNameNew = StrTemplate("%1%2", DirectoryName, File.Name);
				Else
					FullNameNew = StrTemplate("%1%2 %3", DirectoryName, EndDateAndTimeOfProcessing, File.Name);
				EndIf;
				
				MoveFile(FullName, FullNameNew);
				
				WriteLogEvent(DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
					EventLogLevel.Information,,,
					StrTemplate(NStr("vi = 'Đã di chuyển tệp: %1%2Vị trí mới: %3';
									|ru = 'Перемещен файл: %1%2Новое расположение: %3';
									|en = 'The file is moved: %1.%2New location: %3'; fa = 'The file is moved: %1.%2New location: %3';
									|it = 'Перемещен файл: %1%2Новое расположение: %3';
									|pl = 'The file is moved: %1.%2New location: %3';
									|tr = 'Taşınan dosya: %1%2Yeni konum: %3'"), FullName, Chars.LF, FullNameNew));
				
			EndIf;
		
		Except
			
			ErrorText = StrTemplate(NStr("vi = 'Lỗi thực hiện thao tác với tệp sau kết nhập.
										|Thao tác: %1
										|Tên tệp: %2';
										|ru = 'Ошибка выполнения действия с файлом после загрузки.
										|Действие: %1
										|Имя файла: %2';
										|en = 'An error occurred when performing an action with the file after import.
										|Action: %1
										|File name: %2'; fa = 'An error occurred when performing an action with the file after import.
										|Action: %1
										|File name: %2';
										|it = 'Ошибка выполнения действия с файлом после загрузки.
										|Действие: %1
										|Имя файла: %2';
										|pl = 'An error occurred when performing an action with the file after import.
										|Action: %1
										|File name: %2';
										|tr = 'Yüklemeden sonra dosya üzerinde işlem gerçekleştirilirken hata oluştu.
										|İşlem: %1
										|Dosya adı: %2'"),
								ActionDetails.Action, FullName);
			
			AddEntryToErrorLogForException(
				Enums.ImportMasterDataIssueTypes.Other,
				ErrorText,
				ErrorInfo());
			RecordErrorLog();
			
			Break;
			
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DataReader

Procedure ProcessDataFile(DataReader, CurrentFile)
	
	Try
		
		CurFileName = CurrentFile.FullName;
	
		DataReader.OpenFile(CurFileName);
		DataReader.Read();
		
		While ReadPortionOfData(DataReader) Do
			
			If CurrentAction1 = DataProcessors.ImportProductionMasterData.UploadDataAction() Then
				ImportData();
			ElsIf CurrentAction1 = DataProcessors.ImportProductionMasterData.ActionFillInIds() Then
				FillIDs();
			EndIf;
			
			DataPortion.Rows.Clear();
			
		EndDo;
		
		DataReader.Close();
		
		ProcessedFiles = Cache.ProcessedFiles; // Array
		ProcessedFiles.Add(CurrentFile);
	
	Except
		
		If Not Cache.ErrorIsRecordedInProtocol Then
			AddEntryToErrorLogForException(
				Enums.ImportMasterDataIssueTypes.DataFileFormat,
				NStr("vi = 'Lỗi không mong muốn. Đã ngắt xử lý tệp dữ liệu.';
					|ru = 'Непредвиденная ошибка. Обработка файла данных прервана.';
					|en = 'Unexpected error. Data file processing is terminated.'; fa = 'Unexpected error. Data file processing is terminated.';
					|it = 'Непредвиденная ошибка. Обработка файла данных прервана.';
					|pl = 'Unexpected error. Data file processing is terminated.';
					|tr = 'Öngörülmeyen hata. Veri dosyası işleme durduruldu.'"),
				ErrorInfo());
			Cache.ErrorIsRecordedInProtocol = True;
		EndIf;
		
		Raise;
		
	EndTry;
	
EndProcedure

Function ReadPortionOfData(DataReader)
	
	If DataSourceObject.ExchangeFormat = Enums.ImportMasterDataFormats.XML Then
		Return ReadPortionOfXMLData(DataReader, DataPortion, DataChunkSize);
	ElsIf DataSourceObject.ExchangeFormat = Enums.ImportMasterDataFormats.JSON Then
		Return ReadPortionOfJSONData(DataReader, DataPortion.Rows, DataChunkSize);
	EndIf;
		
EndFunction

Function ReadPortionOfXMLData(XMLReader, TreeRow, PortionSize = 0, Val CurrentItemName = "")
	
	TreeRows = TreeRow.Rows; // ValueTreeRowCollection
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			NewTreeRow = TreeRows.Add();
			
			If NewTreeRow.Parent <> Undefined Then
				FillPropertyValues(NewTreeRow, NewTreeRow.Parent);
			EndIf;
			
			CurrentItemName = XMLReader.Name;
			
			SetAttributeValueInLine(DataPortion, NewTreeRow, CurrentItemName, XMLReader.Value);
			
			While XMLReader.ReadAttribute() Do
				SetAttributeValueInLine(DataPortion, NewTreeRow, XMLReader.Name, XMLReader.Value);
			EndDo;
			
			ReadPortionOfXMLData(XMLReader, NewTreeRow, 0, CurrentItemName);
			
		ElsIf XMLReader.NodeType = XMLNodeType.Text Then
			
			SetAttributeValueInLine(DataPortion, TreeRow, CurrentItemName, XMLReader.Value);
			
		ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
			
			CurrentItemName = "";
			Break;
			
		EndIf;
		
		If PortionSize > 0 And TreeRows.Count() >= PortionSize Then
			Break;
		EndIf;
		
	EndDo;
	
	Return (TreeRows.Count() > 0);
	
EndFunction

Function ReadPortionOfJSONData(JSONReader, TreeRows, PortionSize = 0)
	
	TreeRow = Undefined;
	
	PropertyName = Undefined;
	PropertyValue = Undefined;
	
	While JSONReader.Read() Do
		
		NodeTypeJSON = JSONReader.CurrentValueType;
		
		If NodeTypeJSON = JSONValueType.ОbjectEnd Then
			
			If PortionSize > 0 And TreeRows.Count() >= PortionSize Then
				Break;
			Else
				Continue;
			EndIf;
			
		ElsIf NodeTypeJSON = JSONValueType.ArrayEnd Then
			
			Break;
			
		ElsIf NodeTypeJSON = JSONValueType.PropertyName Then
			
			PropertyName = JSONReader.CurrentValue;
			Continue;
			
		ElsIf NodeTypeJSON = JSONValueType.ObjectStart Then
			
			TreeRow = TreeRows.Add();
			If TreeRow.Parent <> Undefined Then
				FillPropertyValues(TreeRow, TreeRow.Parent);
			EndIf;
			Continue;
			
		ElsIf NodeTypeJSON = JSONValueType.ArrayStart Then
			
			If TreeRow <> Undefined Then
				ReadPortionOfJSONData(JSONReader, TreeRow.Rows);
			EndIf;
			Continue;
			
		Else
			
			PropertyValue = JSONReader.CurrentValue;
			
		EndIf;
		
		SetAttributeValueInLine(DataPortion, TreeRow, PropertyName, PropertyValue);
		
	EndDo;
	
	Return (TreeRows.Count() > 0);
	
EndFunction

Procedure SetAttributeValueInLine(Table, TableRow, AttributeName, AttributeValue)
	
	If Not ValueIsFilled(AttributeName) Then
		Return;
	EndIf;
	
	Try
	
		If Table.Columns.Find(AttributeName) = Undefined Then
			Table.Columns.Add(AttributeName);
		EndIf;
		
		TableRow[AttributeName] = AttributeValue;
	
	Except
		
		RowsArray = New Array;
		If DataSourceObject.ExchangeFormat = Enums.ImportMasterDataFormats.XML Then
			RowsArray.Add(NStr("vi = 'Sai giá trị phần tử hoặc thuộc tính trong tệp dữ liệu.';
								|ru = 'Неверное значение элемента или атрибута в файле данных.';
								|en = 'Incorrect item or attribute value in the data file.'; fa = 'Incorrect item or attribute value in the data file.';
								|it = 'Неверное значение элемента или атрибута в файле данных.';
								|pl = 'Incorrect item or attribute value in the data file.';
								|tr = 'Veri dosyasındaki bir öğenin veya özniteliğin değeri geçersiz.'"));
		ElsIf DataSourceObject.ExchangeFormat = Enums.ImportMasterDataFormats.JSON Then
			RowsArray.Add(NStr("vi = 'Sai giá trị khóa trong tệp dữ liệu.';
								|ru = 'Неверное значение ключа в файле данных.';
								|en = 'Incorrect key value in the data file.'; fa = 'Incorrect key value in the data file.';
								|it = 'Неверное значение ключа в файле данных.';
								|pl = 'Incorrect key value in the data file.';
								|tr = 'Veri dosyasındaki anahtar değeri geçersiz.'"));
		Else
			RowsArray.Add(NStr("vi = 'Lỗi đặt giá trị mục tin trong dòng tập hợp dữ liệu.';
								|ru = 'Ошибка установки значения реквизита в строке набора данных.';
								|en = 'An error occurred when setting an attribute value in the data set row.'; fa = 'An error occurred when setting an attribute value in the data set row.';
								|it = 'Ошибка установки значения реквизита в строке набора данных.';
								|pl = 'An error occurred when setting an attribute value in the data set row.';
								|tr = 'Veri setinin bir satırındaki bir gerekliliğin değerinin ayarlanmasında hata oluştu.'"));
		EndIf;
		RowsArray.Add(StrTemplate(NStr("vi = 'Tên: %1';
										|ru = 'Имя: %1';
										|en = 'Name: %1'; fa = 'Name: %1';
										|it = 'Имя: %1';
										|pl = 'Name: %1';
										|tr = 'Ad: %1'"), AttributeName));
		RowsArray.Add(StrTemplate(NStr("vi = 'Giá trị: %1';
										|ru = 'Значение: %1';
										|en = 'Value: %1'; fa = 'Value: %1';
										|it = 'Значение: %1';
										|pl = 'Wartość: %1';
										|tr = 'Değer: %1'"), AttributeValue));
		AddEntryToErrorLogForException(Enums.ImportMasterDataIssueTypes.DataFileFormat,
			StrConcat(RowsArray, Chars.LF), ErrorInfo());
		Cache.ErrorIsRecordedInProtocol = True;
		
		Raise;
		
	EndTry
	
EndProcedure

#EndRegion

#Region FillingInIds

Procedure InitializeTablesForFillingInIdentifiers()
	
	IDsTable.Clear();
	IDsTable.Indexes.Clear();
	
	BankingDetailsSettings = DataSourceAttributeSettings.Copy(
		New Structure("SectionKey,ReferentialType", CurrentPartitionKey, True));
		
	CheckSettingsOfDataSourceAttributes();
	
EndProcedure

Procedure FillInTableOfIdentifiers(DataPortionLines)
	
	DataPortionId = New UUID();
	
	For Each DataPortionString In DataPortionLines Do
		
		CurrentLevel = DataPortionString.Level();
		
		StorageObject = New Structure(AttributeInternal());
		InitializeServiceAttribute(StorageObject, DataPortionId, StructureOfFileFieldValues(DataPortionString));
		
		For Each SettingUpProps In BankingDetailsSettings Do
			
			AttributeLevel = DescriptionOfUploadedData[SettingUpProps.KeyOfUploadedData].LevelInFile;
			If TypeOfStorageObject(CurrentLevel) <> TypeOfStorageObject(AttributeLevel) Then
				Continue;
			EndIf;
			
			If SettingUpProps.MethodToSetValue <> Enums.ImportMasterDataMethodsToSetAttributeValue.GetFromFile Then
				Continue;
			EndIf;
			
			AttributeDetails = SettingUpProps.AttributeDetails;
				
			Value = AttributeValueByFileFields(StorageObject, SettingUpProps);
			If ValueIsFilled(Value) Then
				CompoundTypeConnections = New Array;
				For Each DescriptionOfReferenceType In AttributeDetails.RefTypesDetails Do
					NewRow = IDsTable.Add();
					NewRow.Id       = String(Value);
					NewRow.MetadataObject    = DescriptionOfReferenceType.MetadataObject;
					NewRow.CompoundTypeConnections = CompoundTypeConnections;
					NewRow.ValuesOwner    = AdditionalValuesOwner(AttributeDetails);
					CompoundTypeConnections.Add(NewRow);
				EndDo;
			EndIf;
			
		EndDo;
		
		FillInTableOfIdentifiers(DataPortionString.Rows);
		
	EndDo;
	
EndProcedure

Procedure AddIdentifiersToMatchingRegister()
	
	If IDsTable.Count() = 0 Then
		Return;
	EndIf;
	
	AttributesList1 = "MetadataObject,Id";
	AttributesList2 = "MetadataObject,Id,TableIndex";
	
	IDsTable.Indexes.Add(AttributesList1);
	TheStructureOfTheSearch = New Structure(AttributesList1);
	
	SearchData = IDsTable.Copy(, AttributesList2);
	SearchData.GroupBy(AttributesList2);
	SearchData.Columns.Add("RowIndex",  New TypeDescription("Number"));
	For RowIndex = 0 To SearchData.Count() -1 Do
		SearchData[RowIndex].RowIndex = RowIndex;
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("IDsTable", SearchData);
	Query.SetParameter("DataSource", DataSource);
	Query.Text = "
	|SELECT
	|	IDsTable.RowIndex     AS RowIndex,
	|	IDsTable.MetadataObject AS MetadataObject,
	|	IDsTable.Id    AS Id
	|INTO IDsTable
	|FROM
	|	&IDsTable AS IDsTable
	|INDEX BY
	|	Id,MetadataObject
	|";
	Query.Execute();
	
	QueriesTexts = New ValueList();
	
	QueryText = "
	|SELECT DISTINCT
	|	IDsTable.RowIndex AS RowIndex
	|FROM
	|	IDsTable AS IDsTable
	|
	|	LEFT JOIN InformationRegister.ItemMappingToImportMasterData AS Register
	|	ON Register.DataSource = &DataSource
	|		AND Register.Id = IDsTable.Id
	|WHERE
	|	Register.Id IS NULL
	|	AND IDsTable.MetadataObject = VALUE(Catalog.Products.EmptyRef)
	|";
	QueriesTexts.Add(QueryText, "ItemMappingToImportMasterData");
	
	QueryText = "
	|SELECT DISTINCT
	|	IDsTable.RowIndex AS RowIndex
	|FROM
	|	IDsTable AS IDsTable
	|
	|	LEFT JOIN InformationRegister.ObjectMappingToImportMasterData AS Register
	|	ON Register.DataSource = &DataSource
	|		AND Register.Id = IDsTable.Id
	|		AND Register.MetadataObject = IDsTable.MetadataObject
	|WHERE
	|	Register.Id IS NULL
	|	AND NOT IDsTable.MetadataObject = VALUE(Catalog.Products.EmptyRef)
	|";
	QueriesTexts.Add(QueryText, "ObjectMappingToImportMasterData");
	
	Query.Text = StrConcat(QueriesTexts.UnloadValues(), Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	For TableIndex = 1 To 2 Do
		Selection = QueryResults[TableIndex-1].Select();
		While Selection.Next() Do
			RowData = SearchData[Selection.RowIndex];
			FillPropertyValues(TheStructureOfTheSearch, RowData);
			For Each FoundRow In IDsTable.FindRows(TheStructureOfTheSearch) Do
				FoundRow.MapUser = True;
				FoundRow.TableIndex = TableIndex;
			EndDo;
		EndDo;
	EndDo;
	
	SearchData.Clear();
	For Each String In IDsTable Do
		If String.MapUser Then
			For Each RelatedString In String.CompoundTypeConnections Do
				String.MapUser = Min(String.MapUser, RelatedString.MapUser);
			EndDo;
			If String.MapUser Then
				FillPropertyValues(SearchData.Add(), String);
			EndIf;
		EndIf;
	EndDo;
	
	SearchData.GroupBy(AttributesList2);
	For Each String In SearchData Do
		RegisterName = QueriesTexts[String.TableIndex-1].Presentation;
		InformationRegisters[RegisterName].AddEntryByProperties(DataSource, String);
		IncreaseTagValue("IdsFilledIn");
	EndDo;
	
EndProcedure

#EndRegion

#Region DataImport

Procedure InitializeTablesForDataLoading()
	
	BatchSearchTable.Clear();
	BatchSearchTable.Indexes.Clear();
	
	BankingDetailsSettings = DataSourceAttributeSettings.CopyColumns();
	For Each SettingUpProps In DataSourceAttributeSettings Do
		If SettingUpProps.SectionKey = CurrentPartitionKey
			Or (SettingUpProps.AttributeName = "TechnologyID"
				And SettingUpProps.SectionKey = ProductDataManagementClientServer.KeyOfProductCompositionsSection()
				And CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection()) Then
			FillPropertyValues(BankingDetailsSettings.Add(), SettingUpProps);
		EndIf;
	EndDo;
	BankingDetailsSettings.Indexes.Add("KeyOfUploadedData,ThisIsMainIdentifier");
	BankingDetailsSettings.Indexes.Add("AttributeName");
	
	CheckSettingsOfDataSourceAttributes();
	
	DataTableDescription = New Structure;
	DataTable = New ValueTable;
	
	For Each SettingUpProps In BankingDetailsSettings Do
		
		KeyOfUploadedData = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement(
			SettingUpProps.MetadataObjectName, SettingUpProps.TSName);
			
		LevelInFile = DescriptionOfUploadedData[KeyOfUploadedData].LevelInFile;
		
		If Not DataTableDescription.Property(KeyOfUploadedData) Then
			ObjectToStore = New(TypeOfStorageObject(LevelInFile));
			DataTableDescription.Insert(KeyOfUploadedData, ObjectToStore);
		EndIf;
		
		If SettingUpProps.AttributeDetails.ThisIsID Then
			Type = Undefined;
			TypeValue = Undefined;
		Else
			Type = SettingUpProps.AttributeDetails.Type;
			TypeValue = Type.AdjustValue(Undefined);
		EndIf;
		
		If LevelInFile = 0 Then
			StorageObject = DataTableDescription[KeyOfUploadedData]; // Structure
			StorageObject.Insert(SettingUpProps.AttributeName, TypeValue);
		Else
			StorageObject = DataTableDescription[KeyOfUploadedData]; // ValueTable
			StorageObject.Columns.Add(SettingUpProps.AttributeName, Type);
		EndIf;
		
	EndDo;
	
	For Each KeyAndValue In DataTableDescription Do
		If TypeOf(KeyAndValue.Value) = Type("Structure") Then
			StorageObject = KeyAndValue.Value; // Structure
			StorageObject.Insert(AttributeInternal());
		Else
			StorageObject = KeyAndValue.Value; // ValueTable
			StorageObject.Columns.Add(AttributeInternal());
		EndIf;
		DataTable.Columns.Add(KeyAndValue.Key);
	EndDo;
	
	If CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection() Then
		If Cache.CommunicationTableMaterialOperation.Indexes.Count() = 0 Then
			Cache.CommunicationTableMaterialOperation.Indexes.Add("TechnologyID");
		EndIf;
		If Cache.TableOfAdditionalPropertiesOfComposition.Indexes.Count() = 0 Then
			Cache.TableOfAdditionalPropertiesOfComposition.Indexes.Add("TechnologyID");
		EndIf;
	EndIf;
	
	TableOfAdditionalInformation = InformationRegisters.AdditionalInfo.CreateRecordSet().UnloadColumns();
	
EndProcedure

Function GetRowInDataTable(Level, DataPortionString, DataPortionId)
	
	FileFieldValues = StructureOfFileFieldValues(DataPortionString);
	
	If Level = 0 Then
		TableRow = DataTable.Add();
		For Each Column In DataTable.Columns Do
			StorageObject = DataTableDescription[Column.Name];
			If TypeOf(StorageObject) = Type("ValueTable") Then
				TableRow[Column.Name] = StorageObject.Copy();
			Else
				TableRow[Column.Name] = Common.CopyRecursive(StorageObject);
				InitializeServiceAttribute(TableRow[Column.Name], DataPortionId, FileFieldValues);
			EndIf;
		EndDo;
	Else
		AdditionalProperties = Undefined;
		TableRow = DataTable[DataTable.Count()-1];
		For Each Column In DataTable.Columns Do
			If TypeOf(TableRow[Column.Name]) = Type("Structure") Then
				AdditionalProperties = ValuesOfAdditionalProperties(TableRow[Column.Name]);
				Break;
			EndIf;
		EndDo;
		For Each Column In DataTable.Columns Do
			If TypeOf(TableRow[Column.Name]) = Type("ValueTable") Then
				NestedTable = TableRow[Column.Name]; // ValueTable
				NewRow = NestedTable.Add();
				InitializeServiceAttribute(NewRow, DataPortionId, FileFieldValues, AdditionalProperties);
			EndIf;
		EndDo;
	EndIf;
	
	Return TableRow;
	
EndFunction

Procedure FillDataTable(DataPortionLines)
	
	DataPortionId = New UUID();
	
	FilterOfSettings = New Structure("KeyOfUploadedData,ThisIsMainIdentifier");
	
	For Each DataPortionString In DataPortionLines Do
		
		CurrentLevel = DataPortionString.Level();
		
		If CurrentLevel = 0 Or DataPortionString.Rows.Count() = 0 Then
		
			DataTableRow = GetRowInDataTable(CurrentLevel, DataPortionString, DataPortionId);
			
			For Each KeyAndValue In DataTableDescription Do
				
				KeyOfUploadedData = KeyAndValue.Key;
				
				FilterOfSettings.KeyOfUploadedData = KeyOfUploadedData;
				DescriptionOfUploadedDataElement = DescriptionOfUploadedData[KeyOfUploadedData];
				
				If TypeOfStorageObject(CurrentLevel) <> TypeOfStorageObject(DescriptionOfUploadedData[KeyOfUploadedData].LevelInFile) Then
					Continue;
				EndIf;
				
				StorageObject = DataTableRow[KeyOfUploadedData];
				If CurrentLevel = 0 Then
					CurrentID = "";
				Else
					StorageObject = StorageObject[StorageObject.Count()-1];
				EndIf;
				
				ExecuteAlgorithmBeforeLoadingObject = DescriptionOfUploadedDataElement.ObjectAlgorithmsAreAvailable;
				
				For It = 0 To 1 Do
					
					If It = 1 And ExecuteAlgorithmBeforeLoadingObject Then
						If DescriptionOfUploadedDataElement.SectionKey = CurrentPartitionKey Then
							ExecuteAlgorithmBeforeLoadingObject(StorageObject, KeyOfUploadedData);
						Else
							RestoreAdditionalPropertiesFromCache(StorageObject, KeyOfUploadedData);
						EndIf;
						ExecuteAlgorithmBeforeLoadingObject = False;
					EndIf;
					
					FilterOfSettings.ThisIsMainIdentifier = ?(It=0, True, False);
					For Each SettingUpProps In BankingDetailsSettings.FindRows(FilterOfSettings) Do
						
						If Not ValueIsFilled(SettingUpProps.Value)
								And Not ValueIsFilled(SettingUpProps.ValueCalculationAlgorithm)
							Or SettingUpProps.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.DontUse Then
							Continue;
						EndIf;
						
						If SettingUpProps.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.SetValueTo Then
							StorageObject[SettingUpProps.AttributeName] = SettingUpProps.Value;
							Continue;
						EndIf;
						
						If SettingUpProps.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm Then
							StorageObject[SettingUpProps.AttributeName] = ValueOfAttributeAccordingToAlgorithm(StorageObject, SettingUpProps);
							Continue;
						EndIf;
						
						AttributeDetails = SettingUpProps.AttributeDetails;
						
						Value = AttributeValueByFileFields(StorageObject, SettingUpProps);
						AttributeVALUESAreCalculated(StorageObject).Insert(SettingUpProps.AttributeName, Value);
						
						If SettingUpProps.ReferentialType Then
							If ValueIsFilled(Value) Then
								CompoundTypeConnections = New Array;
								For Each DescriptionOfReferenceType In AttributeDetails.RefTypesDetails Do
									NewRow = BatchSearchTable.Add();
									NewRow.Id            = Value;
									NewRow.MethodToSetValue  = SettingUpProps.MethodToSetValue;
									NewRow.MetadataObject         = DescriptionOfReferenceType.MetadataObject;
									NewRow.TableName               = DescriptionOfReferenceType.FullName;
									NewRow.AttributeName             = SettingUpProps.AttributeName;
									NewRow.StorageObject           = StorageObject;
									NewRow.ThisIsID         = AttributeDetails.ThisIsID;
									NewRow.ThisIsMainIdentifier = AttributeDetails.ThisIsMainIdentifier;
									NewRow.HasCode                  = DescriptionOfReferenceType.HasCode;
									NewRow.HasDescription         = DescriptionOfReferenceType.HasDescription;
									NewRow.HasNumber                = DescriptionOfReferenceType.HasNumber;
									NewRow.CompoundTypeConnections      = CompoundTypeConnections;
									NewRow.ValuesOwner         = AdditionalValuesOwner(AttributeDetails);
									CompoundTypeConnections.Add(NewRow);
								EndDo;
							EndIf;
						Else
							StorageObject[SettingUpProps.AttributeName] = Value;
						EndIf;
						
					EndDo;
					
					If It = 0 And CurrentLevel = 0 Then
						SetCurrentId(StorageObject);
					EndIf;
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
		FillDataTable(DataPortionString.Rows);
		
	EndDo;
	
EndProcedure

Procedure PerformBatchSearchForLinks()
	
	FindLinks = BatchSearchTable.Count();
	If FindLinks = 0 Then
		Return;
	EndIf;
	
	IncreaseTagValue("FindLinks", FindLinks);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	AttributesList = "MethodToSetValue,MetadataObject,Id,ValuesOwner,ThisIsID";
	BatchSearchTable.Indexes.Add(AttributesList);
	TheStructureOfTheSearch = New Structure(AttributesList);
	
	SearchData = BatchSearchTable.Copy(, AttributesList);
	SearchData.GroupBy(AttributesList);
	SearchData.Columns.Add("RowIndex", New TypeDescription("Number"));
	For RowIndex = 0 To SearchData.Count() -1 Do
		SearchData[RowIndex].RowIndex = RowIndex;
	EndDo;
	
	QueryText = "
	|SELECT
	|	T.RowIndex               AS RowIndex,
	|	T.MethodToSetValue    AS MethodToSetValue,
	|	T.MetadataObject           AS MetadataObject,
	|	T.Id              AS Id,
	|	T.ValuesOwner           AS ValuesOwner
	|INTO SearchData
	|FROM
	|	&SearchData AS T
	|INDEX BY
	|	MetadataObject,Id
	|";
	
	Query.SetParameter("DataSource", DataSource);
	Query.SetParameter("SearchData", SearchData);
	Query.Text = QueryText;
	Query.Execute();
	
	QueriesTexts = New Array;
	
	QueryText = "
	|SELECT
	|	T1.RowIndex                 AS RowIndex,
	|	T2.Products.ProductKind AS ProductKind,
	|	T2.Products                 AS Products,
	|	T2.Characteristic               AS Characteristic
	|FROM
	|	SearchData AS T1
	|	
	|	INNER JOIN InformationRegister.ItemMappingToImportMasterData AS T2
	|	ON T1.Id = T2.Id
	|		AND T1.MethodToSetValue = VALUE(Enum.ImportMasterDataMethodsToSetAttributeValue.GetFromFile)
	|		AND T1.MetadataObject = VALUE(Catalog.Products.EmptyRef)
	|		AND T2.Matched
	|		AND T2.DataSource = &DataSource
	|";
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	T1.RowIndex                AS RowIndex,
	|	T2.ObjectReference              AS ObjectReference
	|FROM
	|	SearchData AS T1
	|	
	|	INNER JOIN InformationRegister.ObjectMappingToImportMasterData AS T2
	|	ON T1.Id = T2.Id
	|		AND T1.MethodToSetValue = VALUE(Enum.ImportMasterDataMethodsToSetAttributeValue.GetFromFile)
	|		AND T1.MetadataObject = T2.MetadataObject
	|		AND NOT T1.MetadataObject = VALUE(Catalog.Products.EmptyRef)
	|		AND T2.Matched
	|		AND T2.DataSource = &DataSource
	|";
	QueriesTexts.Add(QueryText);
	
	AttributesList = "MethodToSetValue,MetadataObject,TableName,HasCode,HasDescription,HasNumber";
	DataForFormationOfRequest = BatchSearchTable.Copy(,AttributesList);
	DataForFormationOfRequest.GroupBy(AttributesList);
	
	For Each String In DataForFormationOfRequest Do
		
		If String.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.FindByCode And String.HasCode Then
			SearchDetails     = "T2.Code";
			SortingAttribute = "";
		ElsIf String.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.FindByDescription And String.HasDescription Then
			SearchDetails     = "T2.Description";
			SortingAttribute = "";
		ElsIf String.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.FindByNumber And String.HasNumber Then
			SearchDetails     = "T2.Number";
			SortingAttribute = "T2.Date DESC";
		Else
			Continue;
		EndIf;
			
		QueryText = "
		|SELECT
		|	T1.RowIndex   AS RowIndex,
		|	T2.Ref         AS ObjectReference
		|FROM
		|	SearchData AS T1
		|	
		|	INNER JOIN &Table AS T2
		|	ON T1.Id = &SearchDetails
		|		AND T1.MetadataObject = &MetadataObject
		|		AND T1.MethodToSetValue = &MethodToSetValue
		|		AND &FilterValuesOwner
		|";
		QueryText = StrReplace(QueryText, "&Table", String.TableName);
		QueryText = StrReplace(QueryText, "&SearchDetails", SearchDetails);
		QueryText = StrReplace(QueryText, "&MetadataObject", StrTemplate("VALUE(%1.EmptyRef)", String.TableName));
		QueryText = StrReplace(QueryText, "&MethodToSetValue",
			StrTemplate("VALUE(Enum.ImportMasterDataMethodsToSetAttributeValue.%1)",
			XMLString(String.MethodToSetValue)));
		QueryText = StrReplace(QueryText, "&FilterValuesOwner",
			?(String.MetadataObject = Catalogs.ObjectsPropertiesValues.EmptyRef(),
				"T1.ValuesOwner = T2.Owner",
				"TRUE"));
		If Not IsBlankString(SortingAttribute) Then
			QueryText = StrTemplate("%1 ORDER BY %2", QueryText, SortingAttribute);
		EndIf;
		QueriesTexts.Add(QueryText);
		
	EndDo;
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	For Each QueryResult In QueryResults Do
		Selection = QueryResult.Select();
		While Selection.Next() Do
			RowData = SearchData[Selection.RowIndex];
			If RowData.MetadataObject = Catalogs.Products.EmptyRef()
					And RowData.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.GetFromFile Then
				If RowData.ThisIsID Then
					AttributeValue = New Structure("ProductKind,Products,Characteristic",
											Selection.ProductKind, Selection.Products, Selection.Characteristic);
				Else
					AttributeValue = Selection.Products;
				EndIf;
			Else
				AttributeValue = Selection.ObjectReference;
			EndIf;
			FillPropertyValues(TheStructureOfTheSearch, RowData);
			For Each FoundRow In BatchSearchTable.FindRows(TheStructureOfTheSearch) Do
				If Not ValueIsFilled(FoundRow.StorageObject[FoundRow.AttributeName]) Then
					FoundRow.StorageObject[FoundRow.AttributeName] = AttributeValue;
				EndIf;
				For Each String In FoundRow.CompoundTypeConnections Do
					String.Found4 = True;
				EndDo;
				FoundRow.CompoundTypeConnections.Clear();
				IncreaseTagValue("LinksFound");
			EndDo;
		EndDo;
	EndDo;
	
	AttributesList = "Id,MetadataObject,ValuesOwner,MethodToSetValue";
	ErrorLoggingData = BatchSearchTable.Copy(New Structure("Found4,ThisIsMainIdentifier", False, False), AttributesList);
	ErrorLoggingData.GroupBy(AttributesList);
	
	For Each String In ErrorLoggingData Do
		If String.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.GetFromFile Then
			ErrorText = StrTemplate(NStr("vi = 'Không đặt tương ứng tên định danh ""%1"" với giá trị kiểu ""%2""';
										|ru = 'Отсутствует сопоставление идентификатора ""%1"" со значением типа ""%2""';
										|en = 'The ""%1"" ID mapping with a value of the ""%2"" type is missing'; fa = 'The ""%1"" ID mapping with a value of the ""%2"" type is missing';
										|it = 'Отсутствует сопоставление идентификатора ""%1"" со значением типа ""%2""';
										|pl = 'The ""%1"" ID mapping with a value of the ""%2"" type is missing';
										|tr = '''%1'' tanımlayıcısının ''%2'' türündeki değerle eşleşmesi mevcut değil'"),
				String.Id,
				TypeOf(String.MetadataObject));
			RecordingProtocol = AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.ObjectsMapping, ErrorText);
			RecordingProtocol.Id = String.Id;
		Else
			ErrorText = StrTemplate(NStr("vi = 'Lỗi tìm kiếm đối tượng kiểu ""%1"" theo giá trị ""%2"".
					|Phương án tìm kiếm: ""%3""';
					|ru = 'Ошибка поиска объекта типа ""%1"" по значению ""%2"".
					|Вариант поиска: ""%3""';
					|en = 'An error occurred when searching for an object of the ""%1"" type by the ""%2"" value.
					|Search option: ""%3""'; fa = 'An error occurred when searching for an object of the ""%1"" type by the ""%2"" value.
					|Search option: ""%3""';
					|it = 'Ошибка поиска объекта типа ""%1"" по значению ""%2"".
					|Вариант поиска: ""%3""';
					|pl = 'An error occurred when searching for an object of the ""%1"" type by the ""%2"" value.
					|Search option: ""%3""';
					|tr = '""%2"" değerine göre ""%1"" tipinde nesne aranırken hata oluştu.
					|Arama seçeneği: ""%3""'"),
				TypeOf(String.MetadataObject),
				String.Id,
				String.MethodToSetValue);
			RecordingProtocol = AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.SearchForObject, ErrorText);
		EndIf;
		RecordingProtocol.ObjectReference   = String.MetadataObject;
		RecordingProtocol.ValuesOwner = String.ValuesOwner;
	EndDo;
	
	ProcessTagValues();
	
EndProcedure

#Region DescriptionOfDataTable

Function TypeOfStorageObject(Level)
	
	Return ?(Level = 0, "Structure", "ValueTable");
	
EndFunction

Function AttributeInternal()
	
	Return "_Internal";
	
EndFunction

Procedure InitializeServiceAttribute(StorageObject, DataPortionId, FileFieldValues = Undefined, AdditionalProperties = Undefined)
	
	Result = New Structure;
	
	Result.Insert("DataPortionId", DataPortionId);
	Result.Insert("FileFieldValues", FileFieldValues);
	Result.Insert("AttributeVALUESAreCalculated", New Structure);
	Result.Insert("AdditionalProperties", ?(ValueIsFilled(AdditionalProperties), AdditionalProperties, New Structure));
	
	StorageObject[AttributeInternal()] = Result;
	
EndProcedure

Function AttributeVALUESAreCalculated(StorageObject)
	
	Result = StorageObject[AttributeInternal()]["AttributeVALUESAreCalculated"]; // Structure
	Return Result;
	
EndFunction

Function FileFieldValues(StorageObject)
	
	Result = StorageObject[AttributeInternal()]["FileFieldValues"]; // Structure
	Return Result;
	
EndFunction

Function ValuesOfAdditionalProperties(StorageObject)
	
	Result = StorageObject[AttributeInternal()]["AdditionalProperties"]; // Structure
	Return Result;
	
EndFunction

Function DataPortionId(StorageObject)
	
	Result = StorageObject[AttributeInternal()]["DataPortionId"]; // UUID
	Return Result;
	
EndFunction

#EndRegion

#Region CreatingUpdatingObjects

Procedure CreateUpdateUploadedData()
	
	If CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductsAndMaterialsSection() Then
		
		CreateUpdateItem();
		
	ElsIf CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductionEquipmentSection() Then
		
		CreateUpgradeHardware();
		
	ElsIf CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductCompositionsSection() Then
		
		CreateUpdateResourceBillsOfMATERIALS();
		
	ElsIf CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection() Then
		
		CreateUpdateProductionProcess();
		
	ElsIf CurrentPartitionKey = ProductDataManagementClientServer.KeyOfMaterialsReplacementSection() Then
		
		CreateUpdateMaterialReplacements();
		
	EndIf;
	
EndProcedure

Procedure CreateUpdateItem()
	
	For Each DataTableRow In DataTable Do
		
		FillingData = DataTableRow[Key_Item]; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
		
		If Not SetCurrentId(FillingData) Then
			Continue;
		EndIf;
		
		DownloadableDataItem   = DataToImport(FillingData, Key_Item);
		DownloadableDataCharacteristics = Undefined;
		
		If DownloadableDataItem.Cancel Then
			RecordErrorsByCurrentId(DownloadableDataItem);
			Continue;
		EndIf;
		
		CurViewOfProducts = FillingData.ProductKind;
		
		ProductKindAttributes = ProductKindAttributes(CurViewOfProducts);
		
		UseVariants = ValueIsFilled(ProductKindAttributes.UseVariants)
			And ProductKindAttributes.UseVariants <> Enums.ItemVariantsUsageOptions.DontUse
			And ValueIsFilled(ProductKindAttributes.CharacteristicsPropertySet);
		
		If UseVariants Then
				
			DownloadableDataCharacteristics = LoadingDataConstructor(FillingData, Key_Item);
				
			If ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
				ItemVariantsOwner = CurViewOfProducts;
			ElsIf ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
				ItemVariantsOwner = ProductKindAttributes.ItemVariantsOwner;
			ElsIf ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems Then
				ItemVariantsOwner = DownloadableDataItem.Ref;
			EndIf;
			
			If DownloadableDataItem.FoundByMatchingRegister
				And ValueIsFilled(FillingData.Id.Characteristic) Then
				DownloadableDataCharacteristics.Ref = FillingData.Id.Characteristic;
				DownloadableDataCharacteristics.Found = True;
				DownloadableDataCharacteristics.FoundByMatchingRegister = True;
			ElsIf Not FindCharacteristic(DownloadableDataCharacteristics, ItemVariantsOwner, ProductKindAttributes) Then
				DownloadableDataCharacteristics.Ref = Catalogs.ItemsCharacteristics.GetRef();
			EndIf;
			
		EndIf;
		
		If Not SkipObjectProcessing(DownloadableDataItem) Then
			
			FillInUploadedDataObject(DownloadableDataItem);
			
			If SetValueOfItemSProps(DownloadableDataItem, "ProductKind", CurViewOfProducts) Then
				DownloadableDataItem.Object.AdditionalProperties.Insert("DisableAttributeClearing", True);
				Catalogs.Products.FillInDetailsForTypeOfProduct(DownloadableDataItem.Object);
			EndIf;
			
			FillObjectAttributes(DownloadableDataItem);
			
			FillInAdditionalDetailsOfObject(DownloadableDataItem,
				ProductKindAttributes.AttributesList_PropertiesSet);
			
			ExecuteAlgorithmBeforeRecordingObject(DownloadableDataItem);
			
		EndIf;
		
		If UseVariants
			And Not SkipObjectProcessing(DownloadableDataCharacteristics) Then
			
			DownloadableDataCharacteristics.Object = DownloadableDataCharacteristics.Ref.GetObject();
			If DownloadableDataCharacteristics.Object = Undefined Then
				DownloadableDataCharacteristics.Object = Catalogs.ItemsCharacteristics.CreateItem();
				DownloadableDataCharacteristics.Object.SetNewObjectRef(DownloadableDataCharacteristics.Ref);
				DownloadableDataCharacteristics.Object.Owner = ItemVariantsOwner;
				DownloadableDataCharacteristics.Object.ProductKind = CurViewOfProducts;
				DownloadableDataCharacteristics.ObjectModified = True;
			EndIf;
			
			NameIsSetByProperties =
				NameByProperties(DownloadableDataCharacteristics) = DownloadableDataCharacteristics.Object.Description;
			
			FillInAdditionalDetailsOfObject(DownloadableDataCharacteristics,
				ProductKindAttributes.AttributesList_CharacteristicsPropertySet);
			
			FillInNameOfCharacteristic(DownloadableDataCharacteristics,
				ProductKindAttributes, NameIsSetByProperties);
			
		EndIf;
		
		BeginTransaction();
		Try
			
			CurrentObject = DownloadableDataItem.Object;
			WriteObject(DownloadableDataItem);
			
			If UseVariants
					And DownloadableDataCharacteristics.Object <> Undefined Then
				CurrentObject = DownloadableDataCharacteristics.Object;
				WriteObject(DownloadableDataCharacteristics);
			EndIf;
			
			AddMatchingItems(DownloadableDataItem, DownloadableDataCharacteristics);
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			DownloadableDataItem.Cancel = True;
			HandleObjectRecordingError(CurrentObject, ErrorInfo(), Key_Item, FillingData);
		EndTry;
		
		RecordErrorsByCurrentId(DownloadableDataItem);
		
		ProcessTagValues(Not DownloadableDataItem.Cancel);
		
	EndDo;
	
EndProcedure

Procedure CreateUpgradeHardware()
	
	For Each DataTableRow In DataTable Do
		
		FillingData = DataTableRow[Key_Equipment];
		
		If Not SetCurrentId(FillingData) Then
			Continue;
		EndIf;
		
		DataToImport = DataToImport(FillingData, Key_Equipment);
		
		If SkipObjectProcessing(DataToImport) Then
			AddObjectMatch(DataToImport);
			RecordErrorsByCurrentId(DataToImport);
			Continue;
		EndIf;
		
		FillInUploadedDataObject(DataToImport);
		
		CurrentObject = DataToImport.Object;
		
		FillObjectAttributes(DataToImport);
		
		FillInAdditionalDetailsOfObject(DataToImport);
		
		ExecuteAlgorithmBeforeRecordingObject(DataToImport);
		
		BeginTransaction();
		Try
			
			WriteObject(DataToImport);
			
			AddObjectMatch(DataToImport);
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			DataToImport.Cancel = True;
			HandleObjectRecordingError(CurrentObject, ErrorInfo(), Key_Equipment, FillingData);
		EndTry;
		
		RecordErrorsByCurrentId(DataToImport);
		
		ProcessTagValues(Not DataToImport.Cancel);
		
	EndDo;
	
EndProcedure

Procedure CreateUpdateResourceBillsOfMATERIALS()
	
	TableOfAdditionalPropertiesOfComposition = Cache.TableOfAdditionalPropertiesOfComposition; // ValueTable
	
	For Each DataTableRow In DataTable Do
		
		FillingData = DataTableRow[Key_BillOfMaterials];
		
		If Not SetCurrentId(FillingData) Then
			Continue;
		EndIf;
		
		DataToImport = DataToImport(FillingData, Key_BillOfMaterials);
		
		If SkipObjectProcessing(DataToImport) Then
			RecordErrorsByCurrentId(DataToImport);
			Continue;
		EndIf;
		
		FillInUploadedDataObject(DataToImport);
		
		CurrentObject = DataToImport.Object;
		
		FillObjectAttributes(DataToImport);
		
		FillInAdditionalDetailsOfObject(DataToImport);
		
		TableCached = DeleteCompositionEntriesFromCache(DataToImport);
		
		ManufacturedProducts = CurrentObject.ManufacturedProducts.UnloadColumns();
		
		ProductData_ = FillingData.IdOfProduct;
		If ValueIsFilled(ProductData_) Then
			NewRow = ManufacturedProducts.Add();
			ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(NewRow);
			FillPropertyValues(NewRow, ProductData_);
			NewRow.NumberOfPackages = 1;
		EndIf;
		
		FillInAttributesOfTablePart(DataToImport, ManufacturedProducts, "ManufacturedProducts", "Stage,Operation");
		
		MaterialsAndServices = CurrentObject.MaterialsAndServices.UnloadColumns();
		
		For Each StringMaterial In DataTableRow[Key_Materials] Do
			
			SettlementAttributes = AttributeVALUESAreCalculated(StringMaterial); // Structure
			
			NewRow = MaterialsAndServices.Add();
			NewRow.ConnectionKey = New UUID;
			ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(NewRow);
			
			MaterialData = StringMaterial.MaterialId;
			If ValueIsFilled(MaterialData) Then
				FillPropertyValues(NewRow, MaterialData);
			EndIf;
			FillPropertyValues(NewRow, StringMaterial);
			
			IdOfEmbeddedTechnology = Undefined;
			SettlementAttributes.Property("IdOfEmbeddedTechnology", IdOfEmbeddedTechnology);
			
			If ValueIsFilled(IdOfEmbeddedTechnology)
					Or (Cache.ThereIsCalculationOfFieldPerformedInProcess And StringMaterial.ProducedInProcess = True) Then
				NewRow.ProducedInProcess = True;
				NewRow.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials;
				NewRow.ProductCostElement = Catalogs.ProductCostElements.SemiFinishedProductsProducedInProcess;
				NewRow.WithAssignment = False;
				If ValueIsFilled(IdOfEmbeddedTechnology) Then
					NestedSpecification = StringMaterial.IdOfEmbeddedTechnology;
					If Not ValueIsFilled(NestedSpecification) Then
						NestedSpecification = GetCreateNewLink(
							IdOfEmbeddedTechnology, Key_BillOfMaterials);
						InformationRegisters.ObjectMappingToImportMasterData.AddRecord(
							DataSource, IdOfEmbeddedTechnology, NestedSpecification);
					EndIf;
					NewRow.SourceOfSemiFinishedProduct = NestedSpecification;
				EndIf;
			Else
				ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(NewRow);
			EndIf;
			
			If Cache.ThereIsMaterialRoutePoint Then
				AddCacheLineLinkingMaterialsToOperations(DataToImport,
					SettlementAttributes.CommunicationKeyMaterialOperation,
					NewRow,
					TableCached);
			EndIf;
			
		EndDo;
		
		FillInAttributesOfTablePart(DataToImport, MaterialsAndServices, "MaterialsAndServices", "Stage,Operation");
		
		CheckFillInStatusOfBillOfMaterials(DataToImport);
		
		AdditionalPropertiesOfComposition = ValuesOfAdditionalProperties(FillingData);
		If AdditionalPropertiesOfComposition.Count() > 0 Then
			AdditionalPropertiesLine = TableOfAdditionalPropertiesOfComposition.Add();
			AdditionalPropertiesLine.RecordDate              = CurrentSessionDate();
			AdditionalPropertiesLine.TechnologyID = DataToImport.BillingID;
			AdditionalPropertiesLine.AdditionalProperties  = AdditionalPropertiesOfComposition;
		EndIf;
		
		BeginTransaction();
		Try
			
			WriteObject(DataToImport);
			
			AddObjectMatch(DataToImport);
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			DataToImport.Cancel = True;
			HandleObjectRecordingError(CurrentObject, ErrorInfo(), Key_BillOfMaterials, FillingData);
		EndTry;
		
		RecordErrorsByCurrentId(DataToImport);
		
		ProcessTagValues(Not DataToImport.Cancel);
		
	EndDo;
	
EndProcedure

Procedure CreateUpdateProductionProcess()
	
	Specifications = New Array;
	For Each DataTableRow In DataTable Do
		BillOfMaterials = DataTableRow[Key_BillOfMaterials].TechnologyID;
		If ValueIsFilled(BillOfMaterials) Then
			Specifications.Add(BillOfMaterials);
		EndIf;
	EndDo;
	
	QueryText = "
	|SELECT
	|	Stages.Owner            AS BillOfMaterials,
	|	Stages.Ref              AS ItemRef,
	|	Stages.Description        AS Description,
	|	Stages.StageNumber          AS StageNumber,
	|	Stages.Department       AS Department,
	|	FALSE                      AS Found
	|FROM
	|	Catalog.ProductionStages AS Stages
	|WHERE
	|	Stages.Owner IN(&Specifications)
	|	AND NOT Stages.DeletionMark
	|
	|ORDER BY
	|	BillOfMaterials,
	|	StageNumber,
	|	Description
	|;
	|
	|SELECT
	|	Operations.BillOfMaterials     AS BillOfMaterials,
	|	Operations.Owner         AS Stage,
	|	Operations.Ref           AS ItemRef,
	|	Operations.Description     AS Description,
	|	Operations.OperationNumber    AS OperationNumber,
	|	FALSE                      AS Found
	|FROM
	|	Catalog.ManufacturingOperations AS Operations
	|WHERE
	|	Operations.BillOfMaterials IN(&Specifications)
	|	AND NOT Operations.DeletionMark
	|
	|ORDER BY
	|	BillOfMaterials,
	|	Stage,
	|	OperationNumber,
	|	Description
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Specifications", Specifications);
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	StepsTable   = QueryResults[0].Unload();
	StepsTable.Indexes.Add("BillOfMaterials");
	TransactionTable = QueryResults[1].Unload();
	TransactionTable.Indexes.Add("BillOfMaterials");
	
	StagesOfOperationToProcess = New ValueTable;
	StagesOfOperationToProcess.Columns.Add("Stage");
	StagesOfOperationToProcess.Columns.Add("Operations");
	TypesOfWorkToProcess = New Map;
	CommunicationKeysMaterialOperation = New Array;
	
	For Each DataTableRow In DataTable Do
		
		FillingData = DataTableRow[Key_BillOfMaterials]; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
		
		If Not SetCurrentId(FillingData) Then
			Continue;
		EndIf;
		
		DownloadableDataSpecification = DataToImport(FillingData, Key_BillOfMaterials);
		
		If DownloadableDataSpecification.Found Then
			DownloadableDataSpecification.Found =
				StepsTable.Find(DownloadableDataSpecification.Ref, "BillOfMaterials") <> Undefined;
		Else
			AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.Other,
				NStr("vi = 'Không tìm thấy bảng kê chi tiết để kết nhập quy trình sản xuất.';
					|ru = 'Не найдена спецификация для загрузки производственного процесса.';
					|en = 'A bill of materials to import a production process is not found.'; fa = 'A bill of materials to import a production process is not found.';
					|it = 'Не найдена спецификация для загрузки производственного процесса.';
					|pl = 'A bill of materials to import a production process is not found.';
					|tr = 'Üretim sürecini indirmek için ürün reçetesi bulunamadı.'"),
				Key_BillOfMaterials,
				FillingData);
			DownloadableDataSpecification.Cancel = True;
		EndIf;
		
		If SkipObjectProcessing(DownloadableDataSpecification) Then
			RecordErrorsByCurrentId(DownloadableDataSpecification);
			Continue;
		EndIf;
		
		FillInUploadedDataObject(DownloadableDataSpecification, False);
		
		Cache.FilterBillOfMaterials.BillOfMaterials = DownloadableDataSpecification.Ref;
		
		BillOfMaterialsStageTable    = StepsTable.Copy(Cache.FilterBillOfMaterials);
		TableOfOperationsBillOfMaterials  = TransactionTable.Copy(Cache.FilterBillOfMaterials);
		
		StagesOfOperationToProcess.Clear();
		TypesOfWorkToProcess.Clear();
		
		LoadingDataStage     = Undefined;
		UploadedDataOperation = Undefined;
		
		StageNumber = 0;
		OperationNumber = 0;
		CommunicationKeysMaterialOperation.Clear();
		
		LaborCosts = DownloadableDataSpecification.Object.LaborCosts.UnloadColumns();
		
		For IndexOf = 0 To DataTableRow[_OperationKey].Count() - 1 Do
			
			// Stages
			Data_Stage = DataTableRow[Key_Stages][IndexOf];
			
			If LoadingDataStage = Undefined
				Or (ValueIsFilled(Data_Stage.Department)
						And Data_Stage.Department <> LoadingDataStage.Object.Department)
				Or (DataPortionId(Data_Stage)
						<> DataPortionId(LoadingDataStage.StorageObject)) Then
				
				StageNumber = ?(Cache.ThereIsCalculationOfStageNumberField, Data_Stage.StageNumber, StageNumber + 1);
				OperationNumber = 0;
				
				LoadingDataStage = LoadingDataConstructor(Data_Stage, Key_Stages);
				
				If Not FindStage(LoadingDataStage, DownloadableDataSpecification.Ref, BillOfMaterialsStageTable, StageNumber) Then
					LoadingDataStage.Ref = Catalogs.ProductionStages.GetRef();
				EndIf;
				FillInUploadedDataObject(LoadingDataStage);
				
				SetValueOfItemSProps(LoadingDataStage, "Owner", DownloadableDataSpecification.Ref);
				
				FillObjectAttributes(LoadingDataStage);
				FillInAdditionalDetailsOfObject(LoadingDataStage);
				
				SetValueOfItemSProps(LoadingDataStage, "StageNumber", StageNumber);
				
				NewRow = StagesOfOperationToProcess.Add();
				NewRow.Stage     = LoadingDataStage;
				NewRow.Operations = New Array;
				
			EndIf;
			
			// Operations
			OperationData = DataTableRow[_OperationKey][IndexOf];
			
			UploadedDataOperation = LoadingDataConstructor(OperationData, _OperationKey);
			
			If Not LoadingDataStage.Object.ProductionByThirdParty Then
				
				OperationNumber = ?(Cache.ThereIsCalculationOfOperationNumberField, OperationData.OperationNumber, OperationNumber + 1);
				
				If Not FindOperation(UploadedDataOperation, LoadingDataStage.Ref, TableOfOperationsBillOfMaterials, OperationNumber) Then
					UploadedDataOperation.Ref = Catalogs.ManufacturingOperations.GetRef();
				EndIf;
				FillInUploadedDataObject(UploadedDataOperation);
				
				SetValueOfItemSProps(UploadedDataOperation, "Owner", LoadingDataStage.Ref);
				SetValueOfItemSProps(UploadedDataOperation, "BillOfMaterials", DownloadableDataSpecification.Ref);
				
				FillObjectAttributes(UploadedDataOperation);
				FillInAdditionalDetailsOfObject(UploadedDataOperation);
				
				SetValueOfItemSProps(UploadedDataOperation, "OperationNumber", OperationNumber);
				
				Operations = StagesOfOperationToProcess[StagesOfOperationToProcess.Count()-1].Operations; // Array
				Operations.Add(UploadedDataOperation);
				
				// Types of work
				DataOfActivityKind = DataTableRow[Key_TypesOfWork][IndexOf];
				
				DownloadableDataActivityKind = DataToImport(DataOfActivityKind, Key_TypesOfWork, "Id");
				If Not SkipObjectProcessing(DownloadableDataActivityKind)
					And TypesOfWorkToProcess.Get(DownloadableDataActivityKind.Ref) = Undefined Then
					
					FillInUploadedDataObject(DownloadableDataActivityKind);
					
					FillObjectAttributes(DownloadableDataActivityKind);
					FillInAdditionalDetailsOfObject(DownloadableDataActivityKind);
					
					ExecuteAlgorithmBeforeRecordingObject(DownloadableDataActivityKind);
					
					TypesOfWorkToProcess.Insert(DownloadableDataActivityKind.Ref, DownloadableDataActivityKind);
					
				EndIf;
				
				// LaborCosts
				TheseLaborCosts = DataTableRow[Key_LaborCosts][IndexOf];
				
				NewRow = LaborCosts.Add();
				NewRow.ConnectionKey = New UUID;
				NewRow.StageEditing     = LoadingDataStage.Ref;
				NewRow.OperationEdit = UploadedDataOperation.Ref;
				
				FillPropertyValues(NewRow, TheseLaborCosts);
				If Not ValueIsFilled(NewRow.WorkKind) Then
					NewRow.WorkKind = DownloadableDataActivityKind.Ref;
				EndIf;
			
			EndIf;
			
			// Linking operations to specification materials
			If Cache.ThereIsPointOnRouteOfOperation And ValueIsFilled(OperationData.CommunicationKeyMaterialOperation) Then
				If CommunicationKeysMaterialOperation.Find(OperationData.CommunicationKeyMaterialOperation) = Undefined Then
					FillInLinksOfMaterialsWithOperationsInCache(DownloadableDataSpecification,
						OperationData.CommunicationKeyMaterialOperation,
						LoadingDataStage.Ref,
						UploadedDataOperation.Ref);
					CommunicationKeysMaterialOperation.Add(OperationData.CommunicationKeyMaterialOperation);
				Else
					ErrorText = StrTemplate(NStr("vi = 'Đã tìm thấy sự trùng lặp của khóa liên kết với nguyên vật liệu ""%1"".
					|Khóa phải là duy nhất cho mỗi hoạt động trong công nghệ.';
					|ru = 'Обнаружено дублирование ключа связи с материалом ""%1"".
					|Ключ должен быть уникальным для каждой операции в технологии.';
					|en = 'Duplication of the connection key with the ""%1"" material is detected.
					|The key must be unique for each operation in the technology.'; fa = 'Duplication of the connection key with the ""%1"" material is detected.
					|The key must be unique for each operation in the technology.';
					|it = 'Обнаружено дублирование ключа связи с материалом ""%1"".
					|Ключ должен быть уникальным для каждой операции в технологии.';
					|pl = 'Duplication of the connection key with the ""%1"" material is detected.
					|The key must be unique for each operation in the technology.';
					|tr = 'Yinelenen malzeme bağlantı anahtarı ""%1"" tespit edildi.
					|Anahtar, teknolojideki her operasyon için benzersiz olmalıdır.'"), OperationData.CommunicationKeyMaterialOperation);
					RecordingProtocol = AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.FillFieldsInDataFile,
						ErrorText, _OperationKey);
					RecordingProtocol.ObjectReference = UploadedDataOperation.Ref;
				EndIf;
			EndIf;
			
		EndDo;
		
		FillInAttributesOfTablePart(DownloadableDataSpecification, LaborCosts, "LaborCosts", "Stage,Operation");
		
		// Post-processing of production process elements
		For IndexStage = 0 To StagesOfOperationToProcess.Count() - 1 Do
			
			CurrentDataStage = StagesOfOperationToProcess[IndexStage].Stage; // See LoadingDataConstructor
			CurrentStageObject = CurrentDataStage.Object; // CatalogObject.ProductionStages
			Operations          = StagesOfOperationToProcess[IndexStage].Operations; // Array
			
			If Not Cache.ThereIsCalculationOfFieldNumberOfNextStage Then
				If IndexStage = StagesOfOperationToProcess.Count() - 1 Then
					NextStageNo = 0;
				Else
					NextStageNo = CurrentStageObject.StageNumber + 1;
				EndIf;
				SetValueOfItemSProps(CurrentDataStage, "NextStageNo", NextStageNo);
			EndIf;
			
			If Not Cache.ThereIsCalculationOfStageNameField Then
				SetValueOfItemSProps(CurrentDataStage, "Description", String(CurrentStageObject.Department));
			EndIf;
			
			OperationDataForFillingInVRC = ProductionProcessEditor.FillInTypesOfWorkCentersForOperationsConstructor();
			
			For IndexOperation = 0 To Operations.UBound() Do
				CurrentDataOperation = Operations[IndexOperation]; // See LoadingDataConstructor
				CurrentOperationObject = CurrentDataOperation.Object; // CatalogObject.ManufacturingOperations
				If CurrentStageObject.PlanOperationsOfWorkCenterTypes Then
					NewRow = OperationDataForFillingInVRC.Add();
					FillPropertyValues(NewRow, CurrentOperationObject);
					NewRow.FilledIn= True;
				EndIf;
				If Not Cache.ThereIsCalculationOfFieldNumberOfNextOperation Then
					If IndexOperation = Operations.UBound() Then
						NextOperation = 0;
					Else
						NextOperation = CurrentOperationObject.OperationNumber + 1;
					EndIf;
					SetValueOfItemSProps(CurrentDataOperation, "NextOperation", NextOperation);
				EndIf;
				ExecuteAlgorithmBeforeRecordingObject(CurrentDataOperation);
			EndDo;
			
			FillInTypesOfWorkCentersForOperations(CurrentDataStage, OperationDataForFillingInVRC);
			
			ExecuteAlgorithmBeforeRecordingObject(CurrentDataStage);
				
		EndDo;
		
		// Restoring links with materials
		If Cache.ThereIsPointOnRouteOfOperation Then
			FillInLinksOfMaterialsWithOperationsFromCache(DownloadableDataSpecification);
		EndIf;
		
		CheckFillInStatusOfBillOfMaterials(DownloadableDataSpecification);
		
		For Each KeyAndValue In TypesOfWorkToProcess Do
			CurrentDataActivityKind = KeyAndValue.Value; // See LoadingDataConstructor
			CurrentObject = CurrentDataActivityKind.Object;
			If TryToRecordObject(CurrentDataActivityKind) Then
				AddObjectMatch(CurrentDataActivityKind);
			EndIf;
		EndDo;
		
		ExecuteAlgorithmBeforeRecordingObject(DownloadableDataSpecification);
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.BillsOfMaterials");
			LockItem.SetValue("Ref", DownloadableDataSpecification.Ref);
			LockItem = Block.Add("Catalog.ProductionStages");
			LockItem.SetValue("Owner", DownloadableDataSpecification.Ref);
			LockItem = Block.Add("Catalog.ManufacturingOperations");
			LockItem.SetValue("BillOfMaterials", DownloadableDataSpecification.Ref);
			Block.Lock();
			
			For Each CurrentRow In StagesOfOperationToProcess Do
				CurrentDataStage = CurrentRow.Stage; // See LoadingDataConstructor
				CurrentObject     = CurrentDataStage.Object;
				CurrentObject.AdditionalProperties.Insert("DoNotCheckStatusOfOwner");
				CurrentObject.AdditionalProperties.Insert("ProhibitCalculationOfDaysBeforeEnd");
				If WriteObject(CurrentDataStage, False) Then
					DownloadableDataSpecification.ObjectModified = True;
				EndIf;
				For Each CurrentDataOperation In CurrentRow.Operations Do // See LoadingDataConstructor
					CurrentObject = CurrentDataOperation.Object;
					CurrentObject.AdditionalProperties.Insert("DoNotCheckStatusOfOwner");
					If WriteObject(CurrentDataOperation, False) Then
						DownloadableDataSpecification.ObjectModified = True;
					EndIf;
				EndDo;
			EndDo;
			
			ArrayOfTables = New Array;
			ArrayOfTables.Add(BillOfMaterialsStageTable);
			ArrayOfTables.Add(TableOfOperationsBillOfMaterials);
			For Each Table In ArrayOfTables Do
				For Each TableRow In Table Do
					If Not TableRow.Found Then
						ItemRef = TableRow.ItemRef;
						CurrentObject = ItemRef.GetObject();
						CurrentObject.AdditionalProperties.Insert("AllowRecording");
						CurrentObject.SetDeletionMark(True);
						DownloadableDataSpecification.ObjectModified = True;
						IncreaseTagValueByFollowingLink("Deleted", ItemRef);
					EndIf;
				EndDo;
			EndDo;
			
			CurrentObject = DownloadableDataSpecification.Object;
			CurrentObject.AdditionalProperties.Insert("ProhibitCalculationOfProductionDuration");
			If WriteObject(DownloadableDataSpecification) Then
				InformationRegisters.JobsOfStandardProductionDurationCalculation.AddJob(CurrentObject.Ref, True, False);
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			DownloadableDataSpecification.Cancel = True;
			HandleObjectRecordingError(CurrentObject, ErrorInfo(), Key_BillOfMaterials, FillingData);
		EndTry;
		
		RecordErrorsByCurrentId(DownloadableDataSpecification);
		
		ProcessTagValues(Not DownloadableDataSpecification.Cancel);
		
	EndDo;
	
	InformationRegisters.JobsOfStandardProductionDurationCalculation.RunJob();
	
EndProcedure

Procedure CreateUpdateMaterialReplacements()
	
	DescriptionOfTS = New ValueTable;
	DescriptionOfTS.Columns.Add("TSName");
	DescriptionOfTS.Columns.Add("ReplacementGroup");
	DescriptionOfTS.Columns.Add("TSData");
	
	ReplacementGroups = StrSplit("UsedMaterials,Substitutes", ",");
	For IndexOf = 0 To ReplacementGroups.UBound() Do
		NewRow = DescriptionOfTS.Add();
		NewRow.ReplacementGroup = String(IndexOf);
		NewRow.TSName        = ReplacementGroups[IndexOf];
	EndDo;
	
	For Each DataTableRow In DataTable Do
		
		FillingData = DataTableRow[_ReplacementKey];
		
		If Not SetCurrentId(FillingData) Then
			Continue;
		EndIf;
		
		DataToImport = DataToImport(FillingData, _ReplacementKey);
		
		If SkipObjectProcessing(DataToImport) Then
			RecordErrorsByCurrentId(DataToImport);
			Continue;
		EndIf;
		
		FillInUploadedDataObject(DataToImport);
		
		CurrentObject = DataToImport.Object; // DocumentObject.EngineeringChangeOrder
		
		FillObjectAttributes(DataToImport);
		
		If Not ValueIsFilled(CurrentObject.Date) Then
			SetValueOfItemSProps(DataToImport, "Date", CurrentSessionDate());
		EndIf;
		
		SetValueOfItemSProps(DataToImport, "ReplacementOption", Enums.SubstituteReplacementOption.SetToSet);
		
		FillInAdditionalDetailsOfObject(DataToImport);
		
		AreasOfAction = CurrentObject.AreasOfAction.UnloadColumns();
		NewRow = AreasOfAction.Add();
		FillPropertyValues(NewRow, FillingData);
		
		IdOfProduct = Undefined;
		If FillingData.Property("IdOfProduct", IdOfProduct)
				And ValueIsFilled(IdOfProduct) Then
			NewRow.Product = IdOfProduct.Products;
			NewRow.ItemVariantOfProduct = IdOfProduct.Characteristic;
		Else
			NewRow.Product = Undefined;
			NewRow.ItemVariantOfProduct = Undefined;
		EndIf;
		
		TechnologyID = Undefined;
		If FillingData.Property("TechnologyID", TechnologyID)
				And Not ValueIsFilled(NewRow.Product) Then
			NewRow.BillOfMaterials = TechnologyID;
		Else
			NewRow.BillOfMaterials = Undefined;
		EndIf;
		
		FillInAttributesOfTablePart(DataToImport, AreasOfAction, "AreasOfAction");
		
		If Not FillingData.Property("Status") Then
			SetValueOfItemSProps(DataToImport, "Status", Enums.StatusesOfEngineeringChangeOrders.Confirmed);
		EndIf;
		
		For Each String In DescriptionOfTS Do
			If String.TSData = Undefined Then
				String.TSData = CurrentObject[String.TSName].UnloadColumns();
			EndIf;
			String.TSData.Clear();
		EndDo;
		
		For Each StringMaterial In DataTableRow[Key_Replacements_Materials] Do
			
			SettlementAttributes = AttributeVALUESAreCalculated(StringMaterial); // Structure
			
			CurCurrentReplacementGroup = String(SettlementAttributes.ReplacementGroup);
			If Not ValueIsFilled(CurCurrentReplacementGroup) Then
				DataToImport.Cancel = True;
				Break;
			EndIf;
			
			CurrentTSData = Undefined;
			For IndexOf = 0 To DescriptionOfTS.Count() - 1 Do
				If DescriptionOfTS[IndexOf].ReplacementGroup = CurCurrentReplacementGroup Then
					CurrentTSData = DescriptionOfTS[IndexOf].TSData;
					Break;
				EndIf;
			EndDo;
			
			If CurrentTSData = Undefined Then
				ServiceDetails = DescriptionOfUploadedData[Key_Replacements_Materials].ServiceDetails;
				ErrorText = StrTemplate(NStr("vi = 'Lỗi phân bổ nguyên vật liệu theo các phần bảng của chứng từ.
						|Sai giá trị ""%1"" mục tin ""%2"".';
						|ru = 'Ошибка распределения материалов по табличным частям документа.
						|Неверное значение ""%1"" реквизита ""%2"".';
						|en = 'An error occurred when allocating materials among document tables.
						|Incorrect ""%1"" value of the ""%2"" attribute.'; fa = 'An error occurred when allocating materials among document tables.
						|Incorrect ""%1"" value of the ""%2"" attribute.';
						|it = 'Ошибка распределения материалов по табличным частям документа.
						|Неверное значение ""%1"" реквизита ""%2"".';
						|pl = 'An error occurred when allocating materials among document tables.
						|Incorrect ""%1"" value of the ""%2"" attribute.';
						|tr = 'Malzemelerin belge tablosuna dağıtılmasında hata oluştu.
						|""%2"" özniteliğinin geçersiz ""%1"" değeri.'"),
					CurCurrentReplacementGroup,
					ServiceDetails.ReplacementGroup.Presentation);
				AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.FillFieldsInDataFile,
					ErrorText, _ReplacementKey, FillingData);
				DataToImport.Cancel = True;
				Break;
			EndIf;
			
			NewRow = CurrentTSData.Add();
			
			MaterialData = StringMaterial.MaterialId;
			If ValueIsFilled(MaterialData) Then
				FillPropertyValues(NewRow, MaterialData);
			EndIf;
			FillPropertyValues(NewRow, StringMaterial);
			FillPropertyValues(NewRow, New Structure("RowID", New UUID()));
			
		EndDo;
		
		If Not DataToImport.Cancel Then
			For Each String In DescriptionOfTS Do
				FillInAttributesOfTablePart(DataToImport, String.TSData, String.TSName);
			EndDo;
		EndIf;
		
		ExecuteAlgorithmBeforeRecordingObject(DataToImport);
		
		BeginTransaction();
		Try
			
			WriteObject(DataToImport);
			
			AddObjectMatch(DataToImport);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			DataToImport.Cancel = True;
			HandleObjectRecordingError(CurrentObject, ErrorInfo(), _ReplacementKey, FillingData);
			
		EndTry;
		
		RecordErrorsByCurrentId(DataToImport);
		
		ProcessTagValues(Not DataToImport.Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region CalculationOfValues

Procedure ExecuteAlgorithmBeforeLoadingObject(StorageObject, KeyOfUploadedData)
	
	EventName = ProductDataManagementClientServer.NameOfEventBeforeLoadingObject();
	
	AlgorithmKey = ProductDataManagementClientServer.KeyOfObjectProcessingAlgorithmWhenLoading(
		EventName, KeyOfUploadedData);
	
	AlgorithmBeforeLoadingObject = "";
	If Not DataSourceSettings.ObjectProcessingAlgorithms.Property(AlgorithmKey, AlgorithmBeforeLoadingObject)
		Or Not ValueIsFilled(AlgorithmBeforeLoadingObject) Then
		Return;
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("AdditionalProperties", ValuesOfAdditionalProperties(StorageObject));
	ParametersStructure.Insert("FileFields", FileFieldValues(StorageObject));
	ParametersStructure.Insert("AlgorithmParameters", ParametersOfObjectProcessingAlgorithm(AlgorithmKey, EventName, KeyOfUploadedData));
	
	AlgorithmText = StrTemplate("
	|ParametersStructure = Parameters;
	|
	|AdditionalProperties = ParametersStructure.AdditionalProperties;
	|FileFields = ParametersStructure.FileFields;
	|Parameters = ParametersStructure.AlgorithmParameters;
	|
	|%1
	|
	|", AlgorithmBeforeLoadingObject);
	
	Try
		Common.ExecuteInSafeMode(AlgorithmText, ParametersStructure);
	Except
		ErrorText = StrTemplate(NStr("vi = 'Lỗi thuật toán ""%1"".';
									|ru = 'Ошибка алгоритма ""%1"".';
									|en = '""%1"" algorithm error.'; fa = '""%1"" algorithm error.';
									|it = 'Ошибка алгоритма ""%1"".';
									|pl = '""%1"" algorithm error.';
									|tr = '""%1"" algoritma hatası.'"),
			ProductDataManagementClientServer.PresentationOfTypeOfObjectProcessingAlgorithm(EventName));
		AddEntryToErrorLogForException(Enums.ImportMasterDataIssueTypes.AlgorithmExecution,
			ErrorText,
			ErrorInfo(),
			KeyOfUploadedData,
			StorageObject);
	EndTry;
	
EndProcedure

Function ValueOfAttributeAccordingToAlgorithm(StorageObject, SettingUpProps)
	
	AttributeDetails  = SettingUpProps.AttributeDetails; // See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("AdditionalProperties", ValuesOfAdditionalProperties(StorageObject));
	ParametersStructure.Insert("FileFields", FileFieldValues(StorageObject));
	ParametersStructure.Insert("AlgorithmParameters", AlgorithmParametersForFillingInAttributes(SettingUpProps));
	ParametersStructure.Insert("Result", Undefined);
	
	AlgorithmText = StrTemplate("
	|ParametersStructure = Parameters;
	|Result = Undefined;
	|
	|AdditionalProperties = ParametersStructure.AdditionalProperties;
	|FileFields = ParametersStructure.FileFields;
	|Parameters = ParametersStructure.AlgorithmParameters;
	|
	|%1
	|
	|ParametersStructure.Result = Result;
	|", SettingUpProps.ValueCalculationAlgorithm);
	
	Try
		Common.ExecuteInSafeMode(AlgorithmText, ParametersStructure);
	Except
		ErrorText = StrTemplate(NStr("vi = 'Lỗi khi tính giá trị mục tin ""%1"" theo thuật toán.';
									|ru = 'Ошибка вычисления значения реквизита ""%1"" по алгоритму.';
									|en = 'An error occurred when calculating a value of the ""%1"" attribute by the algorithm.'; fa = 'An error occurred when calculating a value of the ""%1"" attribute by the algorithm.';
									|it = 'Ошибка вычисления значения реквизита ""%1"" по алгоритму.';
									|pl = 'An error occurred when calculating a value of the ""%1"" attribute by the algorithm.';
									|tr = 'Algoritmaya göre ""%1"" özniteliğinin değeri hesaplanırken hata.'"),
			AttributeDetails.Presentation);
		RecordingProtocol = AddEntryToErrorLogForException(Enums.ImportMasterDataIssueTypes.AlgorithmExecution,
			ErrorText, ErrorInfo(), SettingUpProps.KeyOfUploadedData, StorageObject);
		RecordingProtocol.AttributeDetails = AttributeDetails;
	EndTry;
	
	Return ParametersStructure.Result;
	
EndFunction

Function AttributeValueByFileFields(StorageObject, SettingUpProps)
	
	Result = Undefined;
	
	SettingText = SettingUpProps.Value;
	If Not ValueIsFilled(SettingText) Then
		Return Result;
	EndIf;
	
	AttributeDetails  = SettingUpProps.AttributeDetails; // See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
	FileFieldValues = FileFieldValues(StorageObject);
	
	FieldsNotFilled = New Array;
	FieldsAreMissing = New Array;	
	
	If ProductDataManagement.IsExpression(SettingText) Then
		
		ExpressionText = SettingText;
		ParametersStructure = New Structure;
		
		StartPosition = StrFind(SettingText, "[");
		While StartPosition > 0 Do
			PositionEnd1 = StrFind(SettingText, "]", SearchDirection.FromBegin, StartPosition + 1);
			If PositionEnd1 > 0 Then
				Operand = Mid(SettingText, StartPosition + 1, PositionEnd1 - StartPosition - 1);
				If Not FileFieldValues.Property(Operand) Then
					FieldsAreMissing.Add(Operand);
				Else
					Value = FileFieldValues[Operand];
					If Not ValueIsFilled(Value) Then
						FieldsNotFilled.Add(Operand);
					EndIf;
					ParametersStructure.Insert(Operand, Value);
				EndIf;
				ExpressionText = StrReplace(ExpressionText, StrTemplate("[%1]", Operand), StrTemplate("Parameters.%1", Operand));
			EndIf;
			StartPosition = StrFind(SettingText, "[", SearchDirection.FromBegin, PositionEnd1);
		EndDo;
		
		Try
			Result = Common.CalculateInSafeMode(ExpressionText, ParametersStructure);
		Except
			ErrorText = TextOfErrorInCalculatingAttributeValue(AttributeDetails, FieldsNotFilled, FieldsAreMissing);
			RecordingProtocol = AddEntryToErrorLogForException(Enums.ImportMasterDataIssueTypes.FillFieldsInDataFile,
				ErrorText, ErrorInfo(), SettingUpProps.KeyOfUploadedData, StorageObject);
			RecordingProtocol.AttributeDetails = AttributeDetails;
			Return Result;
		EndTry;
		
	Else
		
		Value = Undefined;
		If Not FileFieldValues.Property(SettingText, Value) Then
			FieldsAreMissing.Add(SettingText);
		ElsIf Not ValueIsFilled(Value) Then
			FieldsNotFilled.Add(SettingText);
		Else
			Result = Value;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Result)
			And AttributeDetails.IsRequired Then
		
		ErrorText = TextOfErrorInCalculatingAttributeValue(AttributeDetails, FieldsNotFilled, FieldsAreMissing);
		RecordingProtocol = AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.FillFieldsInDataFile,
			ErrorText, SettingUpProps.KeyOfUploadedData, StorageObject);
		RecordingProtocol.AttributeDetails = AttributeDetails; 
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ExecuteAlgorithmBeforeRecordingObject(DataToImport)
	
	KeyOfUploadedData = DataToImport.KeyOfUploadedData;
	CurrentObject = DataToImport.Object;
	StorageObject = DataToImport.StorageObject;
	
	EventName = ProductDataManagementClientServer.NameOfEventBeforeRecordingObject();
	
	AlgorithmKey = ProductDataManagementClientServer.KeyOfObjectProcessingAlgorithmWhenLoading(
		EventName, KeyOfUploadedData);
	
	AlgorithmBeforeLoadingObject = "";
	If Not DataSourceSettings.ObjectProcessingAlgorithms.Property(AlgorithmKey, AlgorithmBeforeLoadingObject)
		Or Not ValueIsFilled(AlgorithmBeforeLoadingObject) Then
		Return;
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("CurrentObject", CurrentObject);
	ParametersStructure.Insert("AdditionalProperties", ValuesOfAdditionalProperties(StorageObject));
	ParametersStructure.Insert("FileFields", FileFieldValues(StorageObject));
	ParametersStructure.Insert("AlgorithmParameters", ParametersOfObjectProcessingAlgorithm(AlgorithmKey, EventName, KeyOfUploadedData));
	
	AlgorithmText = StrTemplate("
	|ParametersStructure = Parameters;
	|CurrentObject = ParametersStructure.CurrentObject;
	|
	|AdditionalProperties = ParametersStructure.AdditionalProperties;
	|FileFields = ParametersStructure.FileFields;
	|Parameters = ParametersStructure.AlgorithmParameters;
	|
	|%1
	|
	|", AlgorithmBeforeLoadingObject);
	
	Try
		Common.ExecuteInSafeMode(AlgorithmText, ParametersStructure);
		DataToImport.ObjectModified = DataToImport.Object.Modified();
	Except
		ErrorText = StrTemplate(NStr("vi = 'Lỗi thuật toán ""%1"".';
									|ru = 'Ошибка алгоритма ""%1"".';
									|en = '""%1"" algorithm error.'; fa = '""%1"" algorithm error.';
									|it = 'Ошибка алгоритма ""%1"".';
									|pl = '""%1"" algorithm error.';
									|tr = '""%1"" algoritma hatası.'"),
			ProductDataManagementClientServer.PresentationOfTypeOfObjectProcessingAlgorithm(EventName));
		AddEntryToErrorLogForException(Enums.ImportMasterDataIssueTypes.AlgorithmExecution,
			ErrorText,
			ErrorInfo(),
			KeyOfUploadedData,
			StorageObject);
	EndTry;
	
EndProcedure

Function ParametersOfObjectProcessingAlgorithm(AlgorithmKey, EventName, KeyOfUploadedData)
	
	FilterParameters = New Structure;
	FilterParameters.Insert("MetadataObject", DescriptionOfUploadedData[KeyOfUploadedData].MetadataObject);
	FilterParameters.Insert("ConnectionKey", ProductDataManagementClientServer.CommunicationKeyOfTypeOfObjectProcessingAlgorithm(EventName));
	
	Return AlgorithmParameters(AlgorithmKey, FilterParameters, KeyOfUploadedData);
	
EndFunction

Function AlgorithmParametersForFillingInAttributes(SettingUpProps)
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ConnectionKey", SettingUpProps.ConnectionKey);
	
	Return AlgorithmParameters(SettingUpProps.ConnectionKey, FilterParameters);
	
EndFunction

Function AlgorithmParameters(Var_Key, FilterParameters, KeyOfUploadedData = "")
	
	AlgorithmsParameters = GetCreateCacheProperty("AlgorithmsParameters", "Map");
	
	ParametersStructure = AlgorithmsParameters.Get(Var_Key);
	
	If ParametersStructure = Undefined Then
		
		ParametersStructure = New Structure;
		
		FoundRows = DataSourceObject.AlgorithmsParameters.FindRows(FilterParameters);
		For Each FoundRow In FoundRows Do
			Try
				ParametersStructure.Insert(FoundRow.ParameterName, FoundRow.Value);
			Except
				AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.AlgorithmExecution,
					StrTemplate(NStr("vi = 'Sai tên tham số thuật toán: %1';
									|ru = 'Неверное имя параметра алгоритма: %1';
									|en = 'Incorrect algorithm parameter name: %1'; fa = 'Incorrect algorithm parameter name: %1';
									|it = 'Неверное имя параметра алгоритма: %1';
									|pl = 'Incorrect algorithm parameter name: %1';
									|tr = 'Yanlış algoritma parametresi adı: %1'"), FoundRow.ParameterName),
					KeyOfUploadedData);
			EndTry;
		EndDo;
		
		AlgorithmsParameters.Insert(Var_Key, ParametersStructure);
		
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

Function TextOfErrorInCalculatingAttributeValue(AttributeDetails, FieldsNotFilled, FieldsAreMissing)
	
	TemplateCalculationError = NStr("vi = 'Lỗi khi tính giá trị mục tin ""%1"".';
									|ru = 'Ошибка вычисления значения реквизита ""%1""';
									|en = 'An error occurred when calculating a value of the ""%1"" attribute'; fa = 'An error occurred when calculating a value of the ""%1"" attribute';
									|it = 'Ошибка вычисления значения реквизита ""%1""';
									|pl = 'An error occurred when calculating a value of the ""%1"" attribute';
									|tr = '""%1"" öznitelik değeri hesaplanırken hata'");
	TemplateFieldsAreNotFilledIn  = NStr("vi = 'Chưa điền trường của tệp: %1';
										|ru = 'Не заполнены поля файла: %1';
										|en = 'The file fields are not filled: %1'; fa = 'The file fields are not filled: %1';
										|it = 'Не заполнены поля файла: %1';
										|pl = 'The file fields are not filled: %1';
										|tr = 'Dosya alanları doldurulmadı: %1'");
	TemplateMissingFields  = NStr("vi = 'Không có trường tệp: %1';
									|ru = 'Отсутствуют поля файла: %1';
									|en = 'The file fields are missing: %1'; fa = 'The file fields are missing: %1';
									|it = 'Отсутствуют поля файла: %1';
									|pl = 'The file fields are missing: %1';
									|tr = 'Dosya alanları bulunmamaktadır: %1'");
	
	ErrorText = StrTemplate(TemplateCalculationError, AttributeDetails.Presentation);
	If FieldsNotFilled.UBound() <> -1 Then
		Fields = TMCommonUse.DeleteDuplicateElementsFromArray(FieldsNotFilled);
		ErrorText = ErrorText + Chars.LF + StrTemplate(TemplateFieldsAreNotFilledIn, StrConcat(Fields,", "));
	EndIf;
	If FieldsAreMissing.UBound() <> -1 Then
		Fields = TMCommonUse.DeleteDuplicateElementsFromArray(FieldsAreMissing);
		ErrorText = ErrorText + Chars.LF + StrTemplate(TemplateMissingFields, StrConcat(Fields,", "));
	EndIf;
	
	Return ErrorText;
	
EndFunction

#EndRegion

#Region DownloadService

// Loading data constructor.
// Parameters:
// 	StorageObject - Structure
// 	KeyOfUploadedData - String
// 
// Returns:
//  Structure - Loading Data Constructor:
// * Object - Reference object, Document object
// * Ref - Referenceslink, Referenceslink
// * StorageObject - Structure
// * ObjectModified - Boolean
//
Function LoadingDataConstructor(StorageObject, KeyOfUploadedData)
	
	Result = New Structure;
	
	Result.Insert("KeyOfUploadedData", KeyOfUploadedData);
	Result.Insert("LongDesc", DescriptionOfUploadedData[KeyOfUploadedData]);
	Result.Insert("StorageObject", StorageObject);
	
	Result.Insert("Ref");
	Result.Insert("Object");
	Result.Insert("ObjectModified",  False);
	
	Result.Insert("IdField");
	Result.Insert("BillingID");
	
	Result.Insert("Found", False);
	Result.Insert("FoundByMatchingRegister", False);
	Result.Insert("FoundByKeyFields", False);
	
	Result.Insert("AdditionalInfo", TableOfAdditionalInformation.CopyColumns());
	
	Result.Insert("Cancel", False);
	
	Return Result;
	
EndFunction

// Forms the structure of the uploaded data.
// 
// Parameters:
//  StorageObject - Structure
//  KeyOfUploadedData - String
//  IdField - String
//  Create a Boolean object
// 
// Returns:
//  Structure - See LoadingDataConstructor
Function DataToImport(StorageObject, KeyOfUploadedData, IdField = Undefined)
	
	DataToImport = LoadingDataConstructor(StorageObject, KeyOfUploadedData);
	
	DataToImport.IdField = ?(IdField = Undefined, PrimaryIdField(), IdField);
	DataToImport.BillingID = AttributeVALUESAreCalculated(StorageObject)[DataToImport.IdField];
	
	Value = StorageObject[DataToImport.IdField];
	If ValueIsFilled(Value) Then
		DataToImport.Ref = ?(TypeOf(Value) = Type("Structure"), Value[KeyOfUploadedData], Value);
	EndIf;
	
	If ValueIsFilled(DataToImport.Ref) Then
		DataToImport.FoundByMatchingRegister = True;
	Else
		If DataToImport.LongDesc.SearchIsAvailable Then
			FindByKeyFields(DataToImport);
			If DataToImport.Cancel Then
				Return DataToImport;
			EndIf;
		EndIf;
		If Not ValueIsFilled(DataToImport.Ref) Then
			DataToImport.Ref = GetCreateNewLink(DataToImport.BillingID, KeyOfUploadedData);
		EndIf;
	EndIf;
	
	DataToImport.Found = (DataToImport.FoundByMatchingRegister Or DataToImport.FoundByKeyFields);
	
	Return DataToImport;
	
EndFunction

Function FillInUploadedDataObject(DataToImport, ShouldCreateObject = True)
	
	ObjectRead = DataToImport.Object <> Undefined;
	
	If Not ObjectRead
		And ValueIsFilled(DataToImport.Ref) Then
		
		DataToImport.Object = DataToImport.Ref.GetObject();
		If DataToImport.Object = Undefined Then
			If ShouldCreateObject Then
				DataToImport.Object = ?(DataToImport.LongDesc.IsDocument,
					Documents[DataToImport.KeyOfUploadedData].CreateDocument(),
					Catalogs[DataToImport.KeyOfUploadedData].CreateItem());
				DataToImport.Object.SetNewObjectRef(DataToImport.Ref);
				DataToImport.Object.Fill(Undefined);
				ObjectRead = True;
			EndIf;
		Else
			ObjectRead = True;
		EndIf;
		
	EndIf;
	
	Return ObjectRead;
	
EndFunction

Procedure FillObjectAttributes(DataToImport, AttributesList = Undefined)
	
	StorageObject = DataToImport.StorageObject;
	
	If UpgradeOptionIsAlways() Then
		FillPropertyValues(DataToImport.Object, StorageObject, AttributesList);
		DataToImport.ObjectModified = True;
	Else
		If AttributesList = Undefined Then
			AttributesList = ListOfBasicAttributes(DataToImport);
		EndIf;
		If ValueIsFilled(AttributesList) Then
			For Each AttributeName In StrSplit(AttributesList,",") Do
				SetValueOfItemSProps(DataToImport, AttributeName, StorageObject[AttributeName]);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInAttributesOfTablePart(DataToImport, Table, TSName, ExcludedAttributes = "")
	
	Object = DataToImport.Object;
	TabularSection = Object[TSName];
	
	If UpgradeOptionIsAlways()
		Or DataToImport.ObjectModified
		Or TabularSection.Count() <> Table.Count() Then
		TabularSection.Load(Table);
		DataToImport.ObjectModified = True;
	Else
		ExcludeColumns_ = StrSplit("LineNumber,ConnectionKey,RowID", ",");
		If Not IsBlankString(ExcludedAttributes) Then
			CommonClientServer.SupplementArray(ExcludeColumns_, StrSplit(ExcludedAttributes,","));
		EndIf;
		For IndexOf = 0 To Table.Count()-1 Do
			For Each Column In Table.Columns Do
				ColumnName = Column.Name;
				If ExcludeColumns_.Find(ColumnName) <> Undefined Then
					Continue;
				ElsIf TabularSection[IndexOf][ColumnName] <> Table[IndexOf][ColumnName] Then
					DataToImport.ObjectModified = True;
					TabularSection.Load(Table);
					Return;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInAdditionalDetailsOfObject(DataToImport, AttributesList = Undefined)
	
	Object = DataToImport.Object;
	
	If AttributesList = Undefined Then
		AttributesList = ListOfAdditionalAttributes(DataToImport);
	EndIf;
	
	If Not ValueIsFilled(AttributesList) Then
		Return;
	EndIf;
	
	StructureOfValues = New Structure(AttributesList);
	FillPropertyValues(StructureOfValues, DataToImport.StorageObject);
	
	For Each KeyAndValue In StructureOfValues Do
		
		AttributeDetails = DataToImport.LongDesc.AdditionalDetails_[KeyAndValue.Key]; // See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
		PropertyDetails  = AttributeDetails.PropertyDetails;
		
		If KeyAndValue.Value = Undefined 
			And (Not AttributeDetails.CompositeType
				Or BankingDetailsSettings.Find(AttributeDetails.Name, "AttributeName") = Undefined) Then
			Continue;
		EndIf;
		
		NewValue = PropertyDetails.PropertyValueType.AdjustValue(KeyAndValue.Value);
		
		If PropertyDetails.PropertyIsAdditionalInformation Then
			NewRecord = DataToImport.AdditionalInfo.Add();
			NewRecord.Property = PropertyDetails.Property;
			NewRecord.Value = NewValue;
			Continue;
		EndIf;
		
		Cache.FilterProperty.Property = PropertyDetails.Property;
		FoundRows = Object.AdditionalAttributes.FindRows(Cache.FilterProperty);
		
		If PropertyValueIsFilledIn(NewValue) Then
			If FoundRows.Count() > 0 Then
				PropertyRow = FoundRows[0];
			Else
				PropertyRow = Object.AdditionalAttributes.Add();
				PropertyRow.Property = Cache.FilterProperty.Property;
			EndIf;
			If NewValue <> PropertyRow.Value Then
				PropertyRow.Value = NewValue;
				DataToImport.ObjectModified = True;
			EndIf;
		ElsIf FoundRows.Count() > 0 Then
			Object.AdditionalAttributes.Delete(FoundRows[0]);
			DataToImport.ObjectModified = True;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInNameOfCharacteristic(DataToImport, ProductKindAttributes, NameByProperties = False)
	
	If SkipObjectProcessing(DataToImport) Then
		Return;
	EndIf;
	
	ItemVariantName = "";
	StorageObject = DataToImport.StorageObject;
	
	If (Not StorageObject.Property("ItemVariantName", ItemVariantName)
				Or Not ValueIsFilled(ItemVariantName))
		And (Not DataToImport.Found
				Or NameByProperties) Then
		
		ItemVariantName = NameByProperties(DataToImport);
		
	EndIf;
	
	If ValueIsFilled(ItemVariantName) Then
		MatchingBankDetails = New Structure;
		MatchingBankDetails.Insert("Description",       "WorkingNameTemplateCharacteristics");
		MatchingBankDetails.Insert("DescriptionFull", "NameTemplateForPrintingCharacteristics");
		For Each KeyAndValue In MatchingBankDetails Do
			If IsBlankString(ProductKindAttributes[KeyAndValue.Value]) Then
				SetValueOfItemSProps(DataToImport, KeyAndValue.Key, ItemVariantName);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function NameByProperties(DataToImport)
	
	TheTitlesOfTheProperties = GetCreateCacheProperty("TheTitlesOfTheProperties", "Structure");
	PropertyHeadersByKey = Undefined;
	
	If Not TheTitlesOfTheProperties.Property(DataToImport.KeyOfUploadedData, PropertyHeadersByKey) Then
		PropertyHeadersByKey = New Map;
		For Each KeyAndValue In DataToImport.LongDesc.AdditionalDetails_ Do
			PropertyDetails = KeyAndValue.Value.PropertyDetails;
			PropertyHeadersByKey.Insert(PropertyDetails.Property, PropertyDetails.HeaderProperty);
		EndDo;
		TheTitlesOfTheProperties.Insert(DataToImport.KeyOfUploadedData, PropertyHeadersByKey);
	EndIf;
	
	PartsOfName = New ValueList();
	For Each String In DataToImport.Object.AdditionalAttributes Do
		PropertyHeader = PropertyHeadersByKey.Get(String.Property);
		If Not ValueIsFilled(PropertyHeader) Then
			PropertyHeader = String(String.Property);
		EndIf;
		PartsOfName.Add(StrTemplate("%1: %2", PropertyHeader, String.Value));
	EndDo;
	PartsOfName.SortByValue();
	
	Return StrConcat(PartsOfName.UnloadValues(), "; ");
	
EndFunction

Procedure FillInTypesOfWorkCentersForOperations(DataToImport, OperationData_)
	
	If OperationData_.Count() = 0 Then
		Return;
	EndIf;
		
	CurrentObject = DataToImport.Object; // CatalogObject.ProductionStages
	
	Data_Stage = New Structure;
	Data_Stage.Insert("Department",                    CurrentObject.Department);
	Data_Stage.Insert("OperatingProcedureOfWorkCenterTypes", CurrentObject.OperatingProcedureOfWorkCenterTypes);
	Data_Stage.Insert("WorkCenterTypes",               CurrentObject.WorkCenterTypes.UnloadColumns());
	Data_Stage.Insert("AlternateWorkCenterTypes", CurrentObject.AlternateWorkCenterTypes.UnloadColumns());
	
	ProductionProcessEditor.FillInTypesOfWorkCentersForOperations(Data_Stage, OperationData_);
	
	SetValueOfItemSProps(DataToImport, "OperatingProcedureOfWorkCenterTypes", Data_Stage.OperatingProcedureOfWorkCenterTypes);
	FillInAttributesOfTablePart(DataToImport, Data_Stage.WorkCenterTypes, "WorkCenterTypes");
	FillInAttributesOfTablePart(DataToImport, Data_Stage.AlternateWorkCenterTypes, "AlternateWorkCenterTypes");
	
EndProcedure

Function SetValueOfItemSProps(DataToImport, AttributeName, Value)
	
	PreviousValue2 = DataToImport.Object[AttributeName];
	
	If DataToImport.ObjectModified Then
		DataToImport.Object[AttributeName] = Value;
		Return DataToImport.Object[AttributeName] <> PreviousValue2;
	EndIf;
	
	AttributeDetails = Undefined; // See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
	For Each GroupName In ProductDataManagementCached.GroupsOfAttributesForItemHeader(True) Do
		If DataToImport.LongDesc[GroupName].Property(AttributeName, AttributeDetails) Then
			Break;
		EndIf;
	EndDo;
	
	NewValue = AttributeDetails.Type.AdjustValue(Value);
	
	If NewValue <> PreviousValue2 Then
		DataToImport.Object[AttributeName] = NewValue;
		DataToImport.ObjectModified        = True;
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function FindByKeyFields(DataToImport)
	
	Result = Undefined;
	
	KeyOfUploadedData = DataToImport.KeyOfUploadedData;
	LongDesc = DataToImport.LongDesc; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
	StorageObject = DataToImport.StorageObject;
	
	SearchDataByKeyFields = GetCreateCacheProperty("SearchDataByKeyFields", "Structure");
	SearchData_ = Undefined;
	
	If Not SearchDataByKeyFields.Property(KeyOfUploadedData, SearchData_) Then
		SearchData_ = New Structure;
		SearchData_.Insert("KeyFields", New Array);
		SearchData_.Insert("SearchHistory", New Map);
		SearchDataByKeyFields.Insert(KeyOfUploadedData, SearchData_);
		For Each SettingUpProps In BankingDetailsSettings Do
			If SettingUpProps.FieldForSearch Then
				SearchData_.KeyFields.Add(SettingUpProps.AttributeDetails);
			EndIf;
		EndDo;
	EndIf;
	
	If SearchData_.KeyFields.Count() > 0 Then
		
		ErrorLoggingRule = ProductDataManagementClientServer.RuleForResolvingConflictWhenSearchingLogError();
		SortRule          = ProductDataManagementClientServer.RuleForResolvingConflictsWhenSearchingSort();
		SearchConflict           = "3249bd7f-54f5-4261-9918-815769906036";
		
		Query = New Query;
		
		PresentationsArray = New Array;
		ArrayOfConditions       = New Array;
		For Each AttributeDetails In SearchData_.KeyFields Do // See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
			Simple = StorageObject[AttributeDetails.Name];
			PresentationsArray.Add(StrTemplate("%1 (%2)", AttributeDetails.Presentation, Simple));
			ArrayOfConditions.Add(StrTemplate("T.%1 = &%1", AttributeDetails.Name));
			Query.SetParameter(AttributeDetails.Name, Simple);
		EndDo;
		
		HashSumOfKeyFieldValues = HashByStructureValues(Query.Parameters).HashSum;
		
		Result = SearchData_.SearchHistory.Get(HashSumOfKeyFieldValues);
		
		If Result = Undefined Then
		
			Setting = Undefined; // See ProductDataManagementClientServer.DescriptionOfConflictResolutionSettingsForSearchConstructor
			If Not DataSourceSettings.Property("ResolvingSearchConflicts")
				Or Not DataSourceSettings.ResolvingSearchConflicts.Property(KeyOfUploadedData, Setting)
				Or (Setting.Rule = SortRule
							And Setting.SortingSettings.Count() = 0) Then
				Setting = ProductDataManagementClientServer.DescriptionOfConflictResolutionSettingsForSearchConstructor();
			EndIf;
		
			QueryText = "
			|SELECT TOP 2
			|	T.Ref AS Ref
			|FROM
			|	&TableName AS T
			|
			|WHERE
			|	NOT T.DeletionMark
			|	AND NOT T.IsFolder
			|	AND &SelectionByKeyFields
			|";
			
			QueryText = StrReplace(QueryText, "&TableName", LongDesc.FullName);
			QueryText = StrReplace(QueryText, "&SelectionByKeyFields", StrConcat(ArrayOfConditions, " And "));
			
			If Setting.Rule = SortRule Then
				SortingElements = New Array;
				For Each SortingElement In Setting.SortingSettings Do // See ProductDataManagementClientServer.DescriptionOfSortingElementConstructor
					SortingElements.Add(StrTemplate("T.%1 %2", SortingElement.AttributeName, SortingElement.Direction));
				EndDo;
				QueryText = QueryText + StrTemplate("
				|
				|ORDER BY
				|	%1
				|", StrConcat(SortingElements, ", "));
			EndIf;
			
			Query.Text = QueryText;
			
			SetPrivilegedMode(True);
			Selection = Query.Execute().Select();
			SetPrivilegedMode(False);
			
			If Selection.Next() Then
				If Setting.Rule = SortRule Then
					Result = Selection.Ref;
				ElsIf Setting.Rule = ErrorLoggingRule
						And Selection.Count() = 1 Then
					Result = Selection.Ref;
				ElsIf Setting.Rule = ErrorLoggingRule
						And Selection.Count() > 1 Then
					Result = SearchConflict;
				EndIf;
				SearchData_.SearchHistory.Insert(HashSumOfKeyFieldValues, Result);
			EndIf;
		
		EndIf;
		
		If Result = SearchConflict Then
			MessageText = StrTemplate(NStr("vi = 'Khi tìm kiếm theo các trường chính trong danh mục ""%1"" đã tìm thấy hơn một phần tử.
					|Các trường tìm kiếm: %2';
					|ru = 'При поиске по ключевым полям в справочнике ""%1"" обнаружено более одного элемента.
					|Поля поиска: %2';
					|en = 'More than one item is detected during the search by the key fields in the %1 catalog.
					|Search fields: %2'; fa = 'More than one item is detected during the search by the key fields in the %1 catalog.
					|Search fields: %2';
					|it = 'При поиске по ключевым полям в справочнике ""%1"" обнаружено более одного элемента.
					|Поля поиска: %2';
					|pl = 'More than one item is detected during the search by the key fields in the %1 catalog.
					|Search fields: %2';
					|tr = 'Anahtar alanlara göre arama yaparken, ""%1"" kataloğunda birden fazla öğe bulundu.
					|Arama alanı: %2'"),
				LongDesc.Presentation, StrConcat(PresentationsArray, "; "));
			RecordingProtocol = AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.SearchForObject,
				MessageText,
				KeyOfUploadedData,
				StorageObject);
			RecordingProtocol.ObjectReference = LongDesc.MetadataObjectEmptyLink;
			DataToImport.Cancel = True;
			Result = Undefined;
		EndIf;
		
	EndIf;
	
	If Result <> Undefined Then
		DataToImport.Ref = Result;
		DataToImport.FoundByKeyFields = True;
	EndIf;
	
	Return DataToImport.FoundByKeyFields;
	
EndFunction

Function FindCharacteristic(DataToImport, ItemVariantsOwner, ProductKindAttributes)
	
	StorageObject = DataToImport.StorageObject;
	
	CharacteristicsAttributes = New Structure(ProductKindAttributes.AttributesList_CharacteristicsPropertySet);
	FillPropertyValues(CharacteristicsAttributes, StorageObject);
	
	Query = New Query;
	Query.SetParameter("ItemVariantsOwner", ItemVariantsOwner);
	
	TemplateSelectionByProperty = "Properties.Ref = &%1 AND ISNULL(PropertiesValues.Value, UNDEFINED) = &%2";
	
	ListOfPropertiesOfAll        = New Array;
	ListOfPropertiesFilledIn = New Array;
	FiltersList            = New Array;
	For Each KeyAndValue In CharacteristicsAttributes Do
		
		PropertyDetails = DataToImport.LongDesc.AdditionalDetails_[KeyAndValue.Key].PropertyDetails;
		
		ListOfPropertiesOfAll.Add(PropertyDetails.Property);
		
		NameOfPropertyParameter = StrTemplate("Property_%1",  KeyAndValue.Key);
		NameOfValueParameter = StrTemplate("Value_%1" , KeyAndValue.Key);
		
		Query.SetParameter(NameOfPropertyParameter, PropertyDetails.Property);
		
		PropertyValue = PropertyDetails.PropertyValueType.AdjustValue(KeyAndValue.Value);
		If PropertyValueIsFilledIn(PropertyValue) Then
			Query.SetParameter(NameOfValueParameter, PropertyValue);
			ListOfPropertiesFilledIn.Add(PropertyDetails.Property);
		Else
			Query.SetParameter(NameOfValueParameter, Undefined);
		EndIf;
		
		FiltersList.Add(StrTemplate(TemplateSelectionByProperty, NameOfPropertyParameter, NameOfValueParameter));
		
	EndDo;
	
	If ListOfPropertiesOfAll.UBound() = -1 Then
		
		ItemVariantName = Undefined;
		If Not StorageObject.Property("ItemVariantName", ItemVariantName)
			Or Not ValueIsFilled(ItemVariantName) Then
			Return False;
		EndIf;
			
		QueryText = "
		|SELECT TOP 1
		|	Characteristics.Ref AS Characteristic
		|FROM
		|	Catalog.ItemsCharacteristics AS Characteristics
		|
		|WHERE
		|	Characteristics.Owner = &ItemVariantsOwner
		|	AND Characteristics.Description = &ItemVariantName
		|	AND NOT Characteristics.DeletionMark
		|	AND NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Catalog.ItemsCharacteristics.AdditionalAttributes AS PropertiesValues
		|		WHERE
		|			Characteristics.Ref = PropertiesValues.Ref)
		|";
		
		Query.SetParameter("ItemVariantName", ItemVariantName);
		
	Else
		
		If ListOfPropertiesFilledIn.UBound() = -1 Then
			Return False;
		EndIf;
		
		QueryText = "
		|SELECT TOP 1
		|	Characteristics.Ref AS Characteristic
		|FROM
		|	Catalog.ItemsCharacteristics AS Characteristics
		|
		|	LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
		|	ON Properties.Ref IN (&ListOfProperties)
		|
		|	LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS PropertiesValues
		|	ON Characteristics.Ref = PropertiesValues.Ref
		|		AND Properties.Ref = PropertiesValues.Property
		|
		|WHERE
		|	Characteristics.Owner = &ItemVariantsOwner
		|	AND NOT Characteristics.DeletionMark
		|
		|GROUP BY
		|	Characteristics.Ref
		|	
		|HAVING
		|	SUM(CASE WHEN
		|				&TextOfSelectionsByProperties
		|			THEN 1
		|		ELSE 0
		|	END) = &PropertiesCount
		|
		|";
		
		Query.SetParameter("PropertiesCount", ListOfPropertiesOfAll.Count());
		Query.SetParameter("ListOfProperties",     ListOfPropertiesOfAll);
		
		QueryText = StrReplace(QueryText, "&TextOfSelectionsByProperties", StrConcat(FiltersList, Chars.LF + "OR "));
		
	EndIf;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		DataToImport.Ref =  Selection.Characteristic;
		DataToImport.Found = True;
	EndIf;
	
	Return DataToImport.Found;
	
EndFunction

Function FindStage(DataToImport, BillOfMaterials, StepsTable, StageNumber)
	
	FillPropertyValues(Cache.Stage1Selection, DataToImport.StorageObject);
	Cache.Stage1Selection.BillOfMaterials  = BillOfMaterials;
	Cache.Stage1Selection.StageNumber    = StageNumber;
	Cache.Stage1Selection.Found        = False;
	
	FillPropertyValues(Cache.Stage2Selection, Cache.Stage1Selection);
	
	SearchStructures = New Array;
	SearchStructures.Add(Cache.Stage1Selection);
	SearchStructures.Add(Cache.Stage2Selection);
	
	For Each TheStructureOfTheSearch In SearchStructures Do
		FoundRows = StepsTable.FindRows(TheStructureOfTheSearch);
		If ValueIsFilled(FoundRows) And FoundRows.Count() = 1 Then
			FoundRows[0].Found = True;
			DataToImport.Found  = True;
			DataToImport.Ref  = FoundRows[0].ItemRef;
			Break;
		EndIf;
	EndDo;
	
	Return DataToImport.Found;
	
EndFunction

Function FindOperation(DataToImport, Stage, TransactionTable, OperationNumber)
	
	FillPropertyValues(Cache.FilterOperations1, DataToImport.StorageObject);
	Cache.FilterOperations1.Stage          = Stage;
	Cache.FilterOperations1.OperationNumber = OperationNumber;
	Cache.FilterOperations1.Found        = False;
	
	FillPropertyValues(Cache.FilterOperations2, Cache.FilterOperations1);
	
	SearchStructures = New Array;
	SearchStructures.Add(Cache.FilterOperations1);
	SearchStructures.Add(Cache.FilterOperations2);
	
	For Each TheStructureOfTheSearch In SearchStructures Do
		FoundRows = TransactionTable.FindRows(TheStructureOfTheSearch);
		If ValueIsFilled(FoundRows) And FoundRows.Count() = 1 Then
			FoundRows[0].Found = True;
			DataToImport.Found  = True;
			DataToImport.Ref  = FoundRows[0].ItemRef;
			Break;
		EndIf;
	EndDo;
	
	Return DataToImport.Found;
	
EndFunction

Function WriteObject(DataToImport, CheckFilling = True)
	
	ObjectRecorded = False;
	
	If MustWriteObject(DataToImport) Then
		
		Object = DataToImport.Object; // CatalogObject,DocumentObject
		
		KeyOfUploadedData = DataToImport.KeyOfUploadedData;
		LongDesc = DataToImport.LongDesc; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
		ValueType = TypeOf(Object.Ref);
		IsNew = Object.IsNew();
	
		If CheckFilling
				And Not Object.CheckFilling() Then
			
			ErrorText = NStr("vi = 'Chưa kiểm tra việc điền đối tượng.';
							|ru = 'Не пройдена проверка заполнения объекта.';
							|en = 'Object filling is not checked.'; fa = 'Object filling is not checked.';
							|it = 'Не пройдена проверка заполнения объекта.';
							|pl = 'Object filling is not checked.';
							|tr = 'Nesne doldurma kontrolü başarısız oldu.'");
			
			For Each AttributeName In LongDesc.RequiredAttributes Do
				If LongDesc.AttributesIds.Property(AttributeName) Then
					Continue;
				EndIf;
				If CommonClientServer.HasAttributeOrObjectProperty(Object, AttributeName)
						And Not ValueIsFilled(Object[AttributeName]) Then
					Raise ErrorText;
				EndIf;
			EndDo;
			
			RecordingProtocol = AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.CheckingObjectFilling,
				ErrorText, KeyOfUploadedData, DataToImport.StorageObject);
			RecordingProtocol.ObjectReference = ?(IsNew, New (ValueType), Object.Ref);
			
			LowerStatusOfObject(Object);
			
			If LongDesc.IsDocument
				And Not IsNew
				And Object.Posted Then
				Object.Write(DocumentWriteMode.UndoPosting);
			Else
				Object.Write();
			EndIf;
			
			RecordingProtocol.ObjectReference = Object.Ref;
			
		ElsIf LongDesc.IsDocument Then
			
			Object.Write(DocumentWriteMode.Posting);
			
		Else
			
			Object.Write();
			
		EndIf;
		
		IncreaseTagValueByFollowingLink(?(DataToImport.Found, "Updated3", "CreatedOn"), Object.Ref);
		
		ObjectRecorded = True;
		
	EndIf;
	
	RecordAdditionalInformation(DataToImport);
	
	Return ObjectRecorded;
	
EndFunction

Function TryToRecordObject(DataToImport, CheckFilling = True)
	
	Try
	
		Return WriteObject(DataToImport, CheckFilling);
	
	Except
		
		HandleObjectRecordingError(DataToImport.Object,
			ErrorInfo(),
			DataToImport.KeyOfUploadedData,
			DataToImport.StorageObject);
		Return False;
	
	EndTry;
	
EndFunction

Procedure RecordAdditionalInformation(DataToImport)
	
	If SkipObjectProcessing(DataToImport) Then
		Return;
	EndIf;
	
	AdditionalInfo = DataToImport.AdditionalInfo;
	
	If AdditionalInfo.Count() > 0 Then
		
		RecordSet = InformationRegisters.AdditionalInfo.CreateRecordSet();
		RecordSet.Filter.Object.Set(DataToImport.Ref);
		RecordSet.Read();
		
		For Each StringInfo In AdditionalInfo Do
			Found4 = False;
			For Each Record In RecordSet Do
				If StringInfo.Property = Record.Property Then
					If ValueIsFilled(StringInfo.Value) Then
						Record.Value = StringInfo.Value;
					Else
						RecordSet.Delete(Record);
					EndIf;
					Found4 = True;
					Break;
				EndIf;
			EndDo;
			If Not Found4 And ValueIsFilled(StringInfo.Value) Then
				NewRecord = RecordSet.Add();
				NewRecord.Object   = DataToImport.Ref;
				NewRecord.Property = StringInfo.Property;
				NewRecord.Value = StringInfo.Value;
			EndIf;
		EndDo;
		
		RecordSet.Write();
		
	EndIf;
	
EndProcedure

Function StructureOfFileFieldValues(DataPortionString)
	
	FileFieldValues = New Structure;
	
	For Each Column In DataPortion.Columns Do
		If Not DataPortionString[Column.Name] = Undefined Then
			FileFieldValues.Insert(Column.Name, DataPortionString[Column.Name]);
		EndIf;
	EndDo;
	
	Return New FixedStructure(FileFieldValues);
	
EndFunction

Function AdditionalValuesOwner(AttributeDetails)
	
	Result = Undefined;
	
	PropertyDetails = AttributeDetails.PropertyDetails;
	If PropertyDetails <> Undefined Then
		Result = PropertyDetails.PropertyOwnerOfAdditionalValues;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CheckFillInStatusOfBillOfMaterials(DataToImport)
	
	Object = DataToImport.Object;
	AdditionalProperties = ValuesOfAdditionalProperties(DataToImport.StorageObject);
	
	If Cache.ThereIsCalculationOfStatusField Then
		StatusOfBillOfMaterials = GetCreateCacheProperty("StatusOfBillOfMaterials", "Structure");
		If StatusOfBillOfMaterials.Count() = 0 Then
			Filter = New Structure("AttributeName,KeyOfUploadedData,MethodToSetValue",
				"Status", Key_BillOfMaterials, Enums.ImportMasterDataMethodsToSetAttributeValue.SetValueTo);
			FoundRows = DataSourceAttributeSettings.FindRows(Filter);
			If FoundRows.Count() > 0 Then
				StatusValue = FoundRows[0].Value;
			Else
				StatusValue = Undefined;
			EndIf;
			StatusOfBillOfMaterials.Insert("StatusConstant", StatusValue <> Undefined);
			StatusOfBillOfMaterials.Insert("Status_Value",  StatusValue);
		EndIf;
	EndIf;
	
	NewStatus = Undefined;
	
	If CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductCompositionsSection() Then
		
		If Cache.ThereIsCalculationOfStatusField
				And Not StatusOfBillOfMaterials.StatusConstant
				And ValueIsFilled(Object.Status) Then
			AdditionalProperties.Insert("Status_Value", Object.Status);
		EndIf;
		
	ElsIf CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection() Then
		
		If Not Cache.ThereIsCalculationOfStatusField And Not Object.DeletionMark Then
			NewStatus = Enums.BOMStatuses.Valid;
		ElsIf Cache.ThereIsCalculationOfStatusField And StatusOfBillOfMaterials.StatusConstant Then
			NewStatus = StatusOfBillOfMaterials.Status_Value;
		ElsIf Cache.ThereIsCalculationOfStatusField And Not StatusOfBillOfMaterials.StatusConstant Then
			If AdditionalProperties.Property("Status_Value") Then
				NewStatus = AdditionalProperties.Status_Value;
			EndIf;
		EndIf;
		
	EndIf;
		
	If NewStatus <> Undefined Then
		SetValueOfItemSProps(DataToImport, "Status", NewStatus);
	EndIf;
	
	If Not ValueIsFilled(Object.Status) Then
		SetValueOfItemSProps(DataToImport, "Status", Enums.BOMStatuses.UnderDevelopment);
	EndIf;
	
EndProcedure

Procedure LowerStatusOfObject(Object)
	
	If TypeOf(Object) = Type("CatalogObject.BillsOfMaterials")
			And Object.Status = Enums.BOMStatuses.Valid Then
		Object.Status = Enums.BOMStatuses.UnderDevelopment;
	ElsIf TypeOf(Object) = Type("DocumentObject.EngineeringChangeOrder")
			And Object.Status = Enums.StatusesOfEngineeringChangeOrders.Confirmed Then
		Object.Status = Enums.StatusesOfEngineeringChangeOrders.CreatedOn;
	EndIf;
	
EndProcedure

Function PrimaryIdField()
	
	Result = "";
	
	If CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductsAndMaterialsSection()
			Or CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductionEquipmentSection()
			Or CurrentPartitionKey = ProductDataManagementClientServer.KeyOfMaterialsReplacementSection() Then
		Result = "Id";
	ElsIf CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductCompositionsSection()
			Or CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection() Then
		Result = "TechnologyID";
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddObjectMatch(DataToImport)
	
	If Not DataToImport.Cancel
			And Not DataToImport.FoundByMatchingRegister Then
		If ValueIsFilled(DataToImport.BillingID) Then
			InformationRegisters.ObjectMappingToImportMasterData.AddRecord(DataSource,
				DataToImport.BillingID, DataToImport.Ref);
		Else
			RecordingProtocol = AddEntryToErrorLog(Enums.ImportMasterDataIssueTypes.FillFieldsInDataFile,
				NStr("vi = 'Lỗi thêm bản ghi trong biểu ghi tương ứng. Chưa đặt ID đối tượng.';
					|ru = 'Ошибка добавления записи в регистр соответствия. Не задан идентификатор объекта.';
					|en = 'Error adding an entry to the mapping register. The object ID is not set.'; fa = 'Error adding an entry to the mapping register. The object ID is not set.';
					|it = 'Ошибка добавления записи в регистр соответствия. Не задан идентификатор объекта.';
					|pl = 'Error adding an entry to the mapping register. The object ID is not set.';
					|tr = 'Uyumluluk kaydına giriş eklenirken hata oluştu. Nesne tanımlayıcısı ayarlanmamış.'"),
				DataToImport.KeyOfUploadedData,
				DataToImport.StorageObject);
			RecordingProtocol.ObjectReference = DataToImport.Ref;
		EndIf;
	EndIf
	
EndProcedure

Procedure AddMatchingItems(DownloadableDataItem, DownloadableDataCharacteristics = Undefined)
	
	Products   = Undefined;
	Characteristic = Undefined;
	
	If Not DownloadableDataItem.Cancel
		And Not DownloadableDataItem.FoundByMatchingRegister Then
		Products = DownloadableDataItem.Ref;
	EndIf;
	
	If Not DownloadableDataCharacteristics = Undefined
		And Not DownloadableDataCharacteristics.Cancel
		And Not DownloadableDataCharacteristics.FoundByMatchingRegister Then
		Characteristic = DownloadableDataCharacteristics.Ref;
	EndIf;
	
	If Products <> Undefined Or Characteristic <> Undefined Then
		InformationRegisters.ItemMappingToImportMasterData.AddRecord(DataSource,
			DownloadableDataItem.BillingID, Products, Characteristic);
	EndIf;
	
EndProcedure

Function PropertyValueIsFilledIn(PropertyValue)
	
	Return ValueIsFilled(PropertyValue) And Not PropertyValue = False;
	
EndFunction

Function UpgradeOptionIsAlways()
	
	Return DataSourceSettings.UpdatingObjects.UpdateOption =
		Enums.ImportMasterDataObjectUpdateOptions.Always;
	
EndFunction

Function UpdateOptionIfThereAreChanges()
	
	Return DataSourceSettings.UpdatingObjects.UpdateOption =
		Enums.ImportMasterDataObjectUpdateOptions.UpdateIfThereAreChanges;
	
EndFunction

Function UpgradeOptionIsNever()
	
	Return DataSourceSettings.UpdatingObjects.UpdateOption =
		Enums.ImportMasterDataObjectUpdateOptions.Never;
	
EndFunction

Function MustWriteObject(DataToImport)
	
	Return DataToImport.Object <> Undefined
		And (UpgradeOptionIsAlways()
			Or (UpdateOptionIfThereAreChanges() And DataToImport.ObjectModified)
			Or (UpgradeOptionIsNever() And Not DataToImport.Found));
	
EndFunction

Function SkipObjectProcessing(DataToImport)
	
	Return DataToImport = Undefined
		Or DataToImport.Cancel
		Or (UpgradeOptionIsNever() And DataToImport.Found);
	
EndFunction

#EndRegion

#EndRegion

#Region Cache

Procedure InitializeCache()
	
	Cache = New Structure;
	
	Cache.Insert("ErrorIsRecordedInProtocol", False);
	Cache.Insert("ProcessedFiles", New Array);
	Cache.Insert("ExecutionStarted", CurrentSessionDate());
	
	StructureOfCounters = New Structure;
	StructureOfCounters.Insert("IsInProcessing",      StructureOfTagsSectionConstructor());
	StructureOfCounters.Insert("Fixed_", StructureOfTagsSectionConstructor());
	Cache.Insert("StructureOfCounters", StructureOfCounters);
	
	CommunicationTableMaterialOperation = New ValueTable;
	CommunicationTableMaterialOperation.Columns.Add("RecordDate",                New TypeDescription("Date"));
	CommunicationTableMaterialOperation.Columns.Add("TechnologyID",   New TypeDescription("String"));
	CommunicationTableMaterialOperation.Columns.Add("RowIndex",              New TypeDescription());
	CommunicationTableMaterialOperation.Columns.Add("CommunicationKeyMaterialOperation", New TypeDescription("String"));
	CommunicationTableMaterialOperation.Columns.Add("Stage",                      New TypeDescription("CatalogRef.ProductionStages"));
	CommunicationTableMaterialOperation.Columns.Add("Operation",                  New TypeDescription("CatalogRef.ManufacturingOperations"));
	Cache.Insert("CommunicationTableMaterialOperation", CommunicationTableMaterialOperation);
	
	TableOfAdditionalPropertiesOfComposition = New ValueTable;
	TableOfAdditionalPropertiesOfComposition.Columns.Add("RecordDate",              New TypeDescription("Date"));
	TableOfAdditionalPropertiesOfComposition.Columns.Add("TechnologyID", New TypeDescription("String"));
	TableOfAdditionalPropertiesOfComposition.Columns.Add("AdditionalProperties",  New TypeDescription());
	Cache.Insert("TableOfAdditionalPropertiesOfComposition", TableOfAdditionalPropertiesOfComposition);
	
	LimitOfRelevanceOfCacheEntries = CurrentSessionDate() - 2 * 86400;
	
	Record = InformationRegisters.MasterDataImportSettings.CreateRecordManager();
	Record.DataSource = DataSource;
	Record.Read();
	If Record.Selected() Then
		SavedCache = Record.AdditionalParameters.Get();
		If SavedCache <> Undefined Then
			Try
				If SavedCache.Property("CommunicationTableMaterialOperation") Then
					For Each String In SavedCache.CommunicationTableMaterialOperation Do
						If String.RecordDate > LimitOfRelevanceOfCacheEntries Then
							FillPropertyValues(Cache.CommunicationTableMaterialOperation.Add(), String);
						EndIf;
					EndDo;
				EndIf;
				If SavedCache.Property("TableOfAdditionalPropertiesOfComposition") Then
					For Each String In SavedCache.TableOfAdditionalPropertiesOfComposition Do
						If String.RecordDate > LimitOfRelevanceOfCacheEntries Then
							FillPropertyValues(Cache.TableOfAdditionalPropertiesOfComposition.Add(), String);
						EndIf;
					EndDo;
				EndIf;
			Except
				WriteLogEvent(DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
					EventLogLevel.Error,,
					DataSource,
					NStr("vi = 'Lỗi phục hồi dữ liệu bộ đệm trung gian.';
						|ru = 'Ошибка восстановления данных кэша.';
						|en = 'An error occurred when restoring cache data.'; fa = 'An error occurred when restoring cache data.';
						|it = 'Ошибка восстановления данных кэша.';
						|pl = 'An error occurred when restoring cache data.';
						|tr = 'Önbellek verileri geri yüklenirken hata.'"));
			EndTry;
		EndIf;
	EndIf;
	
	CacheSelectionStructures();
	
	CacheSignsOfSettingUpAttributes();
	
EndProcedure

Function StoredCacheData()
	
	Return "CommunicationTableMaterialOperation,TableOfAdditionalPropertiesOfComposition";
	
EndFunction

Function GetCreateCacheProperty(PropertyName, TypeName = "")
	
	Property = Undefined;
	If Not Cache.Property(PropertyName, Property) Then
		Property = ?(IsBlankString(TypeName), Undefined, New (TypeName));
		Cache.Insert(PropertyName, Property);
	EndIf;
	
	Return Property;
	
EndFunction

Function ListOfBasicAttributes(DataToImport)
	
	Return AttributesList("ListsOfBasicAttributes",
		DataToImport.StorageObject, DataToImport.KeyOfUploadedData, "AttributesStandard,AttributesApplication");
	
EndFunction

Function ListOfAdditionalAttributes(DataToImport)
	
	Return AttributesList("ListsOfAdditionalAttributes",
		DataToImport.StorageObject, DataToImport.KeyOfUploadedData, "AdditionalDetails_");
	
EndFunction

Function AttributesList(CacheProperty, StorageObject, KeyOfUploadedData, AttributesGroups)
	
	AttributesList = "";
	
	ListsOfAttributes = GetCreateCacheProperty(CacheProperty, "Structure");
	If Not ListsOfAttributes.Property(KeyOfUploadedData) Then
		LongDesc = DescriptionOfUploadedData[KeyOfUploadedData]; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
		For Each AttributeGroup In StrSplit(AttributesGroups,",") Do
			For Each KeyAndValue In LongDesc[AttributeGroup] Do
				AttributeName = KeyAndValue.Key;
				If CommonClientServer.HasAttributeOrObjectProperty(StorageObject, AttributeName) Then
					AttributesList = StrTemplate("%1%2%3", AttributesList, ?(IsBlankString(AttributesList),"",","), AttributeName);
				EndIf;
			EndDo;
		EndDo;
		ListsOfAttributes.Insert(KeyOfUploadedData, AttributesList);
	Else
		AttributesList = ListsOfAttributes[KeyOfUploadedData];
	EndIf;
	
	Return AttributesList;
	
EndFunction

Function ProductKindAttributes(ProductKind)
	
	DetailsOfProductTypes = GetCreateCacheProperty("DetailsOfProductTypes", "Map");
	ProductKindAttributes  = DetailsOfProductTypes.Get(ProductKind);
	
	If ProductKindAttributes = Undefined Then
		
		Attributes = New Array;
		Attributes.Add("PropertiesSet");
		Attributes.Add("CharacteristicsPropertySet");
		Attributes.Add("UseVariants");
		Attributes.Add("ItemVariantsOwner");
		Attributes.Add("WorkingNameTemplateOfProductItem");
		Attributes.Add("WorkingNameTemplateCharacteristics");
		Attributes.Add("NameTemplateForPrintingOfProductItem");
		Attributes.Add("NameTemplateForPrintingCharacteristics");
		
		ProductKindAttributes = Common.ObjectAttributesValues(
				?(ProductKind = Undefined, Catalogs.ItemKinds.EmptyRef(), ProductKind),
				Attributes);
		
		PropertiesSets = New Structure;
		PropertiesSets.Insert("PropertiesSet",
			New Structure("Overall,List", PropertyManager.PropertiesSetByName("Catalog_Products_Overall"), New Array));
		PropertiesSets.Insert("CharacteristicsPropertySet",
			New Structure("Overall,List", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"), New Array));
		
		For Each KeyAndValueDescription In DescriptionOfUploadedData["Products"].AdditionalDetails_ Do
			PropertyDetails = KeyAndValueDescription.Value.PropertyDetails;
			For Each KeyAndValueSets In PropertiesSets Do
				If PropertyDetails.PropertiesSets.Find(ProductKindAttributes[KeyAndValueSets.Key]) <> Undefined
					Or PropertyDetails.PropertiesSets.Find(KeyAndValueSets.Value.Overall) <> Undefined Then
						List = KeyAndValueSets.Value.List; // Array
						List.Add(PropertyDetails.NameProperty);
				EndIf;
			EndDo;
		EndDo;
		
		For Each KeyAndValue In PropertiesSets Do
			ProductKindAttributes.Insert(StrTemplate("AttributesList_%1", KeyAndValue.Key), StrConcat(KeyAndValue.Value.List, ","));
		EndDo;
		ProductKindAttributes.Insert("ProductKind", ProductKind);
		
		DetailsOfProductTypes.Insert(ProductKind, ProductKindAttributes);
		
	EndIf;
	
	Return ProductKindAttributes;
	
EndFunction

Function GetCreateNewLink(Id, KeyOfUploadedData)
	
	RefsOfNew = GetCreateCacheProperty("RefsOfNew", "Structure");
	
	NewRefsByKey = Undefined;
	If Not RefsOfNew.Property(KeyOfUploadedData, NewRefsByKey) Then
		NewRefsByKey = New Map;
		RefsOfNew.Insert(KeyOfUploadedData, NewRefsByKey);
	EndIf;
	
	RefToNew = NewRefsByKey.Get(Id);
	If RefToNew = Undefined Then
		Manager = Common.ObjectManagerByRef(DescriptionOfUploadedData[KeyOfUploadedData].MetadataObjectEmptyLink);
		RefToNew = Manager.GetRef();
		NewRefsByKey.Insert(Id, RefToNew);
	EndIf;
	
	Return RefToNew;
	
EndFunction

Procedure CacheSelectionStructures()
	
	Cache.Insert("FilterBillOfMaterials",             New Structure("BillOfMaterials"));
	Cache.Insert("SelectionTechnology",               New Structure("TechnologyID"));
	Cache.Insert("SelectionTechnologyKeyCommunication",      New Structure("TechnologyID,CommunicationKeyMaterialOperation"));
	Cache.Insert("FilterProperty",                 New Structure("Property"));
	Cache.Insert("SelectionIdPartitionKey", New Structure("Id,SectionKey"));
	AttributesList = "BillOfMaterials,Department,Found";
	Cache.Insert("Stage1Selection",                   New Structure(AttributesList+",StageNumber"));
	Cache.Insert("Stage2Selection",                   New Structure(AttributesList));
	AttributesList = "Stage,Description,Found";
	Cache.Insert("FilterOperations1",                New Structure(AttributesList+",OperationNumber"));
	Cache.Insert("FilterOperations2",                New Structure(AttributesList));
	
EndProcedure

Procedure CacheSignsOfSettingUpAttributes()
	
	AddFeature("ThereIsCalculationOfStatusField",                 "Status",                    Key_BillOfMaterials);
	AddFeature("ThereIsCalculationOfFieldPerformedInProcess",  "ProducedInProcess",     Key_Materials);
	AddFeature("ThereIsCalculationOfStageNumberField",             "StageNumber",                Key_Stages);
	AddFeature("ThereIsCalculationOfFieldNumberOfNextStage",   "NextStageNo",      Key_Stages);
	AddFeature("ThereIsCalculationOfStageNameField",      "Description",              Key_Stages);
	AddFeature("ThereIsCalculationOfOperationNumberField",          "OperationNumber",             _OperationKey);
	AddFeature("ThereIsCalculationOfFieldNumberOfNextOperation", "NextOperation",    _OperationKey);
	AddFeature("ThereIsMaterialRoutePoint",           "CommunicationKeyMaterialOperation", Key_Materials);
	AddFeature("ThereIsPointOnRouteOfOperation",            "CommunicationKeyMaterialOperation", _OperationKey);
	
EndProcedure

Procedure AddFeature(NameOfFlag, AttributeName, KeyOfUploadedData)
	
	Filter = New Structure("AttributeName,KeyOfUploadedData", AttributeName, KeyOfUploadedData);

	Cache.Insert(NameOfFlag, DataSourceAttributeSettings.FindRows(Filter).Count() > 0);
	
EndProcedure

#Region ConnectionsCompositionTechnology

Procedure AddCacheLineLinkingMaterialsToOperations(DataToImport, CommunicationKeyMaterialOperation, RowData, TableCached = Undefined)
	
	If Not ValueIsFilled(CommunicationKeyMaterialOperation) Then
		Return;
	EndIf;
	
	LinkTable     = Cache.CommunicationTableMaterialOperation; // ValueTable
	TableOfMaterials = RowData.Owner(); // ValueTable
	
	NewRow                           = LinkTable.Add();
	NewRow.RecordDate                = CurrentSessionDate();
	NewRow.TechnologyID   = DataToImport.BillingID;
	NewRow.RowIndex              = TableOfMaterials.IndexOf(RowData);
	NewRow.CommunicationKeyMaterialOperation = CommunicationKeyMaterialOperation;
	
	If TableCached <> Undefined
		And TableCached.Count() > 0 Then
		
		Filter = New Structure("CommunicationKeyMaterialOperation", CommunicationKeyMaterialOperation);
		
		For Each FoundRow In TableCached.FindRows(Filter) Do
			RowData.StageEditing     = FoundRow.Stage;
			RowData.OperationEdit = FoundRow.Operation;
			NewRow.Stage     = FoundRow.Stage;
			NewRow.Operation = FoundRow.Operation;
			Break;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInLinksOfMaterialsWithOperationsInCache(DataToImport, CommunicationKeyMaterialOperation, Stage, Operation)
	
	If Not ValueIsFilled(CommunicationKeyMaterialOperation) Then
		Return;
	EndIf;
	
	Cache.SelectionTechnologyKeyCommunication.TechnologyID   = DataToImport.BillingID;
	Cache.SelectionTechnologyKeyCommunication.CommunicationKeyMaterialOperation = CommunicationKeyMaterialOperation;
	
	For Each FoundRow In Cache.CommunicationTableMaterialOperation.FindRows(Cache.SelectionTechnologyKeyCommunication) Do
		FoundRow.Stage     = Stage;
		FoundRow.Operation = Operation;
	EndDo;
	
EndProcedure

Procedure FillInLinksOfMaterialsWithOperationsFromCache(DataToImport)
	
	Cache.SelectionTechnology.TechnologyID = DataToImport.BillingID;
	
	FoundRows = Cache.CommunicationTableMaterialOperation.FindRows(Cache.SelectionTechnology);
	If FoundRows.Count() = 0 Then
		Return;
	EndIf;
	
	If DataToImport.ObjectModified Then
		MaterialsAndServices = DataToImport.Object.MaterialsAndServices;
	Else
		MaterialsAndServices = DataToImport.Object.MaterialsAndServices.Unload();
	EndIf;
	
	For Each FoundRow In FoundRows Do
		If FoundRow.RowIndex < MaterialsAndServices.Count() Then
			TSRow = MaterialsAndServices[FoundRow.RowIndex];
			TSRow.StageEditing     = FoundRow.Stage;
			TSRow.OperationEdit = FoundRow.Operation;
		EndIf;
	EndDo;
	
	If DataToImport.ObjectModified Then
		Return;
	Else
		FillInAttributesOfTablePart(DataToImport, MaterialsAndServices, "MaterialsAndServices", "Stage,Operation");
	EndIf;
	
EndProcedure

Procedure RestoreAdditionalPropertiesFromCache(StorageObject, KeyOfUploadedData)
	
	If KeyOfUploadedData <> "BillsOfMaterials" Then
		Return;
	EndIf;
	
	TechnologyID = Undefined;
	If Not AttributeVALUESAreCalculated(StorageObject).Property("TechnologyID", TechnologyID) Then
		Return;
	EndIf;
	
	Cache.SelectionTechnology.TechnologyID = TechnologyID;
	
	FoundRows = Cache.TableOfAdditionalPropertiesOfComposition.FindRows(Cache.SelectionTechnology);
	If ValueIsFilled(FoundRows) Then
		AdditionalProperties = ValuesOfAdditionalProperties(StorageObject);
		For Each KeyAndValue In FoundRows[0].AdditionalProperties Do
			AdditionalProperties.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndIf;
	
EndProcedure

Function DeleteCompositionEntriesFromCache(DataToImport)
	
	Cache.SelectionTechnology.TechnologyID = DataToImport.BillingID;
	
	For Each FoundRow In Cache.TableOfAdditionalPropertiesOfComposition.FindRows(Cache.SelectionTechnology) Do
		Cache.TableOfAdditionalPropertiesOfComposition.Delete(FoundRow);
	EndDo;
	
	AttributesCached = "CommunicationKeyMaterialOperation,Stage,Operation";
	TableCached   = Cache.CommunicationTableMaterialOperation.CopyColumns(AttributesCached);
	
	For Each FoundRow In Cache.CommunicationTableMaterialOperation.FindRows(Cache.SelectionTechnology) Do
		FillPropertyValues(TableCached.Add(), FoundRow);
		Cache.CommunicationTableMaterialOperation.Delete(FoundRow);
	EndDo;
	
	TableCached.GroupBy(AttributesCached);
	Return TableCached;
	
EndFunction

#EndRegion

#Region Counters

Function StructureOfTagsSectionConstructor()
	
	Result = New Structure;
	
	Result = New Structure;
	Result.Insert("IdsFilledIn", 0);
	Result.Insert("FindLinks",              0);
	Result.Insert("LinksFound",            0);
	Result.Insert("IssuesTypes",              New Map);
	
	For Each KeyAndValue In NestedTagsFact() Do
		Result.Insert(KeyAndValue.Key, New Map);
		Result.Insert(CounterArray(KeyAndValue.Key), New Array);
	EndDo;
	
	Return Result;
	
EndFunction

Function NestedTagsFact()
	
	Counters = New Structure;
	
	Counters.Insert("CreatedOn",    NStr("vi = 'Đã tạo';
										|ru = 'Создано';
										|en = 'Created'; fa = 'ایجادشده';
										|it = 'Создано';
										|pl = 'Created';
										|tr = 'Oluşturuldu'"));
	Counters.Insert("Updated3",  NStr("vi = 'Đã cập nhật';
										|ru = 'Обновлено';
										|en = 'Updated'; fa = 'به‌روزرسانی شد';
										|it = 'Обновлено';
										|pl = 'Updated';
										|tr = 'Güncellendi'"));
	Counters.Insert("Deleted",    NStr("vi = 'Đã xóa';
										|ru = 'Удалено';
										|en = 'Deleted'; fa = 'حذف‌شده';
										|it = 'Удалено';
										|pl = 'Deleted';
										|tr = 'Silindi'"));
	Counters.Insert("NotWritten1", NStr("vi = 'Chưa ghi lại';
										|ru = 'Не записано';
										|en = 'Not saved'; fa = 'Not saved';
										|it = 'Non scritto';
										|pl = 'Nie zapisano';
										|tr = 'Kaydedilmedi'"));
	
	Return Counters;
	
EndFunction

Function CounterArray(CounterName)
	
	Return StrTemplate("%1_", CounterName);
	
EndFunction

Procedure IncreaseTagValue(CounterName, Var_Key = "", Value = 1, Section = "IsInProcessing")
	
	StructureOfSectionCounters = Cache.StructureOfCounters[Section];
	
	If TypeOf(StructureOfSectionCounters[CounterName]) = Type("Number") Then
		StructureOfSectionCounters[CounterName] = StructureOfSectionCounters[CounterName] + Value;
	Else
		Counter = StructureOfSectionCounters[CounterName];
		If TypeOf(Counter) = Type("Map")
				And Counter.Get(Var_Key) = Undefined
			Or TypeOf(Counter) = Type("Structure")
				And Not Counter.Property(Var_Key) Then
			Counter.Insert(Var_Key, 0);
		EndIf;
		Counter[Var_Key] = Counter[Var_Key] + Value;
	EndIf;
	
EndProcedure

Procedure IncreaseTagValueByFollowingLink(CounterName, Ref, Value = 1, Section = "IsInProcessing")
	
	StructureOfSectionCounters = Cache.StructureOfCounters[Section];
	If StructureOfSectionCounters.Property(CounterArray(CounterName)) Then
		StructureOfSectionCounters[CounterArray(CounterName)].Add(Ref);
	EndIf;
	
	IncreaseTagValue(CounterName, TypeOf(Ref), Value, Section);
	
EndProcedure

Procedure ResetTagValues(Section = "IsInProcessing")
	
	Cache.StructureOfCounters[Section] = StructureOfTagsSectionConstructor();
	
EndProcedure

Procedure ProcessTagValues(Commit = True)
	
	If Commit Then
	
		CountersInProcessing      = Cache.StructureOfCounters.IsInProcessing;
		CountersAreFixed = Cache.StructureOfCounters.Fixed_;
		
		For Each KeyAndValue1 In CountersInProcessing Do
			CounterType = TypeOf(KeyAndValue1.Value);
			If CounterType = Type("Number") Then
				If KeyAndValue1.Value > 0 Then
					CountersAreFixed[KeyAndValue1.Key] = CountersAreFixed[KeyAndValue1.Key] + KeyAndValue1.Value;
				EndIf;
			ElsIf CounterType = Type("Array") Then
				CommonClientServer.SupplementArray(CountersAreFixed[KeyAndValue1.Key], KeyAndValue1.Value);
			Else
				For Each KeyAndValue2 In KeyAndValue1.Value Do
					If KeyAndValue2.Value > 0 Then
						TagAdded =
							TypeOf(CountersAreFixed[KeyAndValue1.Key]) = Type("Map")
								And CountersAreFixed[KeyAndValue1.Key].Get(KeyAndValue2.Key) <> Undefined
							Or TypeOf(CountersAreFixed[KeyAndValue1.Key]) = Type("Structure")
								And CountersAreFixed[KeyAndValue1.Key].Property(KeyAndValue2.Key);
						If TagAdded Then
							CountersAreFixed[KeyAndValue1.Key][KeyAndValue2.Key] =
								CountersAreFixed[KeyAndValue1.Key][KeyAndValue2.Key] + KeyAndValue2.Value;
						Else
							CountersAreFixed[KeyAndValue1.Key].Insert(KeyAndValue2.Key, KeyAndValue2.Value);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	
	EndIf;
	
	ResetTagValues();
	
EndProcedure

#EndRegion

#EndRegion

#Region ErrorProcessing

Procedure CompleteProcessingOfDataLoadingErrors()
	
	RecordSet = InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.CreateRecordSet();
	RecordSet.Filter.DataSource.Set(DataSource);
	RecordSet.Filter.IssueType.Set(Enums.ImportMasterDataIssueTypes.DataSourceSettings);
	RecordSet.Write();
	
	RecordErrorLog();
	
	CheckClearObjectMappingErrors();
	
EndProcedure

Function AddEntryToErrorLog(IssueType, ErrorText, KeyOfUploadedData = "", StorageObject = Undefined)
	
	RecordingProtocol = ErrorProtocolTable.Add();
	
	RecordingProtocol.IssueType           = IssueType;
	RecordingProtocol.ErrorText           = ErrorText;
	
	RecordingProtocol.KeyOfUploadedData = KeyOfUploadedData;
	RecordingProtocol.Id         = CurrentID;
	
	RecordingProtocol.SectionKey           = CurrentPartitionKey;
	RecordingProtocol.FileName              = CurFileName;
	RecordingProtocol.Date                  = CurrentSessionDate();
	
	If StorageObject <> Undefined Then
		RecordingProtocol.FileFields = FileFieldValues(StorageObject);
	EndIf;
	
	ArrayOfTexts = New Array;
	For Each Message In GetUserMessages(True) Do
		ArrayOfTexts.Add(Message.Text);
	EndDo;
	RecordingProtocol.TextMessagesToUser = StrConcat(ArrayOfTexts, Chars.LF);
	
	Return RecordingProtocol;
	
EndFunction

Function AddEntryToErrorLogForException(IssueType, ErrorText, ErrorInfo, KeyOfUploadedData = "", StorageObject = Undefined)
	
	RecordingProtocol = AddEntryToErrorLog(IssueType, ErrorText, KeyOfUploadedData, StorageObject);
	
	RecordingProtocol.ExceptionText          = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	RecordingProtocol.ExceptionTextIsDetailed = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	Return RecordingProtocol;
	
EndFunction

Function SetCurrentId(StructureOfData)
	
	CurrentID = "";
	
	If TypeOf(StructureOfData) = Type("Structure") Then
		StorageObject = StructureOfData;
	Else
		For Each KeyAndValue In DataTableDescription Do
			If TypeOf(KeyAndValue.Value) = Type("Structure") Then
				StorageObject = StructureOfData[KeyAndValue.Key];
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If StorageObject <> Undefined Then
		CurrentID = AttributeVALUESAreCalculated(StorageObject)[PrimaryIdField()];
	EndIf;
	
	Return Not IsBlankString(CurrentID);
	
EndFunction

Procedure RecordErrorsByCurrentId(DataToImport)
	
	If IsBlankString(CurrentID) Then
		Return;
	EndIf;
	
	ObjectsRefs = New Array;
	ThisIsBillOfMaterials = DataToImport.KeyOfUploadedData = "BillsOfMaterials";
	
	CountersInProcessing = Cache.StructureOfCounters.IsInProcessing;
	For Each KeyAndValue In NestedTagsFact() Do
		For Each ObjectReference In CountersInProcessing[CounterArray(KeyAndValue.Key)] Do
			ObjectsRefs.Add(ObjectReference);
		EndDo;
	EndDo;
	
	RecordSet = InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.CreateRecordSet();
	RecordSet.Filter.DataSource.Set(DataSource);
	RecordSet.Filter.Id.Set(CurrentID);
	If Not ThisIsBillOfMaterials Then
		RecordSet.Filter.SectionKey.Set(CurrentPartitionKey);
	EndIf;
	
	If ThisIsBillOfMaterials
		Or Not (ThisIsBillOfMaterials And DataToImport.Found) Then
		RecordSet.Read();
	EndIf;
	
	ErrorsTable = RecordSet.UnloadColumns();
	
	For Each Error In RecordSet Do
		Ignore = False;
		If ValueIsFilled(Error.ObjectReference)
			And ObjectsRefs.Find(Error.ObjectReference) <> Undefined
			And (Error.SectionKey = CurrentPartitionKey
				Or ThisIsBillOfMaterials
					And Error.IssueType = Enums.ImportMasterDataIssueTypes.CheckingObjectFilling) Then
			Ignore = True;
		ElsIf Not ValueIsFilled(Error.ObjectReference)
			And Error.SectionKey = CurrentPartitionKey
			And Error.IssueType = Enums.ImportMasterDataIssueTypes.ObjectRecord Then
			Ignore = True;
		ElsIf Error.SectionKey = CurrentPartitionKey
				And (Error.IssueType = Enums.ImportMasterDataIssueTypes.AlgorithmExecution
					Or Error.IssueType = Enums.ImportMasterDataIssueTypes.FillFieldsInDataFile) Then
			Ignore = True;
		EndIf;
		If Ignore Then
			If Error.OccurrenceDate >= Cache.ExecutionStarted Then
				IncreaseTagValue("IssuesTypes", Error.IssueType, -1, "Fixed_");
			EndIf;
			Continue;
		EndIf;
		FillPropertyValues(ErrorsTable.Add(), Error);
	EndDo;
	
	Cache.SelectionIdPartitionKey["Id"] = CurrentID;
	Cache.SelectionIdPartitionKey["SectionKey"]   = CurrentPartitionKey;
	
	For Each FoundRow In ErrorProtocolTable.FindRows(Cache.SelectionIdPartitionKey) Do
		If ErrorCorrespondsToPropertiesOfObject(FoundRow, DataToImport) Then
			Error = ErrorsTable.Add();
			WritingErrorLogToRegisterEntry(Error, FoundRow);
		EndIf;
		ErrorProtocolTable.Delete(FoundRow);
	EndDo;
	
	RecordSet.Load(ErrorsTable);
	RecordSet.Write();
	
	CurrentID = "";
	
	GetUserMessages(True);
	
EndProcedure

Procedure WritingErrorLogToRegisterEntry(RegisterRecord, RecordingProtocol)
	
	RegisterRecord.DataSource     = DataSource;
	RegisterRecord.IssueType        = RecordingProtocol.IssueType;
	RegisterRecord.Id      = RecordingProtocol.Id;
	RegisterRecord.SectionKey        = RecordingProtocol.SectionKey;
	
	If RecordingProtocol.IssueType  = Enums.ImportMasterDataIssueTypes.ObjectsMapping Then
		If ValueIsFilled(RecordingProtocol.ValuesOwner) Then
			RegisterRecord.UniqueKey = RecordingProtocol.ValuesOwner.UUID();
			RegisterRecord.ValuesOwner = RecordingProtocol.ValuesOwner;
		EndIf;
	Else
		RegisterRecord.UniqueKey = New UUID();
	EndIf;
	
	ObjectReferenceValueType         = TypeOf(RecordingProtocol.ObjectReference);
	
	If RecordingProtocol.ObjectReference <> Undefined Then
		RegisterRecord.MetadataObject = New(ObjectReferenceValueType);
	ElsIf Not IsBlankString(RecordingProtocol.KeyOfUploadedData) Then
		LongDesc = DescriptionOfUploadedData[RecordingProtocol.KeyOfUploadedData];
		RegisterRecord.MetadataObject = LongDesc.MetadataObjectEmptyLink;
	EndIf;
	
	RegisterRecord.Information         = RecordingProtocol.ErrorText;
	RegisterRecord.ObjectReference     = RecordingProtocol.ObjectReference;
	RegisterRecord.OccurrenceDate  = RecordingProtocol.Date;
	RegisterRecord.FileName           = RecordingProtocol.FileName;
	
	If RecordingProtocol.FileFields <> Undefined Then
		RegisterRecord.FileFields = New ValueStorage(RecordingProtocol.FileFields);
	EndIf;
	
	RowsArray = New Array;
	
	If Not IsBlankString(RecordingProtocol.TextMessagesToUser) Then
		RowsArray.Add(RecordingProtocol.TextMessagesToUser);
	EndIf;
	If Not IsBlankString(RecordingProtocol.ExceptionText) Then
		RowsArray.Add(RecordingProtocol.ExceptionText);
	EndIf;
	RegisterRecord.InformationDetailed = StrConcat(RowsArray, Chars.LF);
	
	RowsArray.Clear();
	RowsArray.Add(RegisterRecord.Information);
	If Not IsBlankString(RegisterRecord.InformationDetailed) Then
		RowsArray.Add(RegisterRecord.InformationDetailed);
	EndIf;
	RowsArray.Add("");
	If Not IsBlankString(RegisterRecord.Id) Then
		RowsArray.Add(StrTemplate(NStr("vi = 'Tên định danh: %1';
										|ru = 'Идентификатор: %1';
										|en = 'ID: %1'; fa = 'ID: %1';
										|it = 'Идентификатор: %1';
										|pl = 'ID: %1';
										|tr = 'Tanımlayıcı: %1'"), RegisterRecord.Id));
	EndIf;
	If Not IsBlankString(RegisterRecord.FileName) Then
		RowsArray.Add(StrTemplate(NStr("vi = 'Tệp: %1';
										|ru = 'Файл: %1';
										|en = 'File: %1'; fa = 'File: %1';
										|it = 'File: %1';
										|pl = 'Plik: %1';
										|tr = 'Dosya: %1'"), RegisterRecord.FileName));
	EndIf;
	If Not IsBlankString(RecordingProtocol.ExceptionTextIsDetailed) Then
		RowsArray.Add("");
		RowsArray.Add(RecordingProtocol.ExceptionTextIsDetailed);
	EndIf;
	
	WriteLogEvent(DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
		EventLogLevel.Error,
		Metadata.FindByType(ObjectReferenceValueType),
		RegisterRecord.ObjectReference,
		StrConcat(RowsArray, Chars.LF));
	
	IncreaseTagValue("IssuesTypes", RegisterRecord.IssueType, 1, "Fixed_");
	
EndProcedure

Procedure RecordErrorLog()
	
	If ErrorProtocolTable.Count() = 0 Then
		Return;
	EndIf;
	
	For Each RecordingProtocol In ErrorProtocolTable Do
		
		RegisterRecord = InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.CreateRecordManager();
		WritingErrorLogToRegisterEntry(RegisterRecord, RecordingProtocol);
		RegisterRecord.Write();
		
	EndDo;
	
	ErrorProtocolTable.Clear();
	
EndProcedure

Function ErrorCorrespondsToPropertiesOfObject(DataOfError, DataToImport)
	
	Result         = True;
	ProductKind   = Undefined;
	AttributeDetails = DataOfError.AttributeDetails;
	ObjectReference    = DataToImport.Ref;
	
	If CurrentPartitionKey = ProductDataManagementClientServer.KeyOfProductsAndMaterialsSection()
		And ValueIsFilled(AttributeDetails)
		And ValueIsFilled(AttributeDetails.PropertyDetails)
		And DataToImport.StorageObject.Property("ProductKind", ProductKind)
		And ValueIsFilled(ProductKind) Then
			
		ProductKindAttributes = ProductKindAttributes(ProductKind);
		PropertyDetails          = AttributeDetails.PropertyDetails;
		
		If PropertyDetails.PropertiesSets.Find(ProductKindAttributes.PropertiesSet) <> Undefined Then
			ObjectReference = Catalogs.Products.EmptyRef();
		ElsIf PropertyDetails.PropertiesSets.Find(ProductKindAttributes.CharacteristicsPropertySet) <> Undefined Then
			ObjectReference = Catalogs.ItemsCharacteristics.EmptyRef();
		Else
			Result = False;
		EndIf;
		
	EndIf;
	
	If DataOfError.ObjectReference = Undefined Then
		DataOfError.ObjectReference = ObjectReference;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure HandleObjectRecordingError(CurrentObject, ErrorInfo, KeyOfUploadedData, StorageObject)
	
	PartsOfMessage = New Array;
	LongDesc       = DescriptionOfUploadedData[KeyOfUploadedData]; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
	IssueType    = Enums.ImportMasterDataIssueTypes.ObjectRecord;
	CurrentRef  = Undefined;
	
	If CurrentObject <> Undefined Then
		CurrentRef = CurrentObject.Ref;
		PartsOfMessage.Add(NStr("vi = 'Không thể ghi lại đối tượng (Kiểu: %1).';
								|ru = 'Не удалось записать объект (Тип: %1).';
								|en = 'Cannot save the object (Type: %1).'; fa = 'Cannot save the object (Type: %1).';
								|it = 'Не удалось записать объект (Тип: %1).';
								|pl = 'Cannot save the object (Type: %1).';
								|tr = 'Nesne kaydedilemedi (Tip: %1).'"));
		If LongDesc.IsDocument Then
			If CurrentObject.Posted Then
				IssueType = Enums.ImportMasterDataIssueTypes.CarryingOutDocument;
				PartsOfMessage[0] = NStr("vi = 'Không thể kết chuyển chứng từ(Kiểu: %1).';
										|ru = 'Не удалось провести документ(Тип: %1).';
										|en = 'Cannot post the document (Type: %1).'; fa = 'Cannot post the document (Type: %1).';
										|it = 'Не удалось провести документ(Тип: %1).';
										|pl = 'Cannot post the document (Type: %1).';
										|tr = 'Belge kaydedilemedi(Tip: %1).'");
			EndIf;
		Else
			If ValueIsFilled(CurrentObject.Description) Then
				PartsOfMessage.Add(StrTemplate(NStr("vi = 'Tên gọi: %1';
													|ru = 'Наименование: %1';
													|en = 'Name: %1 '; fa = 'Name: %1 ';
													|it = 'Наименование: %1';
													|pl = 'Name: %1 ';
													|tr = 'Tanım: %1'"), CurrentObject.Description));
			EndIf;
		EndIf;
		PartsOfMessage[0] = StrTemplate(PartsOfMessage[0], TypeOf(CurrentObject));
		IncreaseTagValueByFollowingLink("NotWritten1", CurrentRef);
	Else
		PartsOfMessage.Add(NStr("vi = 'Không thể ghi lại đối tượng.';
								|ru = 'Не удалось записать объект.';
								|en = 'Cannot save the object.'; fa = 'Cannot save the object.';
								|it = 'Не удалось записать объект.';
								|pl = 'Cannot save the object.';
								|tr = 'Nesne kaydedilemedi.'"));
	EndIf;
	
	RecordingProtocol = AddEntryToErrorLogForException(
		IssueType,
		StrConcat(PartsOfMessage, Chars.LF),
		ErrorInfo,
		KeyOfUploadedData,
		StorageObject);
	RecordingProtocol.ObjectReference = CurrentRef;
	
EndProcedure

Procedure CheckClearObjectMappingErrors()
	
	If CurrentAction1 <> DataProcessors.ImportProductionMasterData.UploadDataAction() Then
		Return;
	EndIf;
	
	IssueType = Enums.ImportMasterDataIssueTypes.ObjectsMapping;
	
	QueryText = "
	|SELECT
	|	Errors.Id      AS Id,
	|	Errors.MetadataObject   AS MetadataObject,
	|	Errors.OccurrenceDate  AS OccurrenceDate
	|FROM
	|	InformationRegister.ObjectMappingToImportMasterData AS Maps1
	|		INNER JOIN InformationRegister.ErrorsThatOccurredWhenImportingProductionMasterData AS Errors
	|		ON Maps1.DataSource = Errors.DataSource
	|		AND Maps1.Id = Errors.Id
	|		AND Maps1.MetadataObject = Errors.MetadataObject
	|		AND Maps1.Matched
	|		AND Errors.IssueType = &IssueType
	|WHERE
	|	Maps1.DataSource = &DataSource
	|
	|UNION ALL
	|
	|SELECT
	|	Errors.Id      AS Id,
	|	Errors.MetadataObject   AS MetadataObject,
	|	Errors.OccurrenceDate  AS OccurrenceDate
	|FROM
	|	InformationRegister.ItemMappingToImportMasterData AS Maps1
	|		INNER JOIN InformationRegister.ErrorsThatOccurredWhenImportingProductionMasterData AS Errors
	|		ON Maps1.DataSource = Errors.DataSource
	|		AND Maps1.Id = Errors.Id
	|		AND Maps1.Matched
	|		AND Errors.MetadataObject = VALUE(Catalog.Products.EmptyRef)
	|		AND Errors.IssueType = &IssueType
	|WHERE
	|	Maps1.DataSource = &DataSource
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataSource", DataSource);
	Query.SetParameter("IssueType", IssueType);
	
	Set = InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.CreateRecordSet();
	Set.Filter.DataSource.Set(DataSource);
	Set.Filter.IssueType.Set(IssueType);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Set.Filter.Id.Set(Selection.Id);
		Set.Filter.MetadataObject.Set(Selection.MetadataObject);
		Set.Write();
		If Selection.OccurrenceDate >= Cache.ExecutionStarted Then
			IncreaseTagValue("IssuesTypes", IssueType, -1, "Fixed_");
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckSettingsOfDataSourceAttributes()
	
	Cancel = False;
	
	For Each SettingUpProps In BankingDetailsSettings Do
		
		AttributeDetails = SettingUpProps.AttributeDetails; // See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
		If Not AttributeDetails.IsRequired Then
			Continue;
		EndIf;
		
		If SettingUpProps.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm
			And ValueIsFilled(SettingUpProps.ValueCalculationAlgorithm) Then
			Continue;
		EndIf;
		
		If SettingUpProps.MethodToSetValue <> Enums.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm
			And ValueIsFilled(SettingUpProps.Value) Then
			Continue;
		EndIf;
		
		MessageText = StrTemplate(NStr("vi = 'Chưa xác định phương thức điền mục tin bắt buộc.
										|Kiểu dữ liệu được kết nhập: %1
										|Tên mục tin: %2';
										|ru = 'Не задан способ заполнения обязательного реквизита.
										|Тип загружаемых данных: %1
										|Имя реквизита: %2';
										|en = 'A method to fill the required attribute is not specified.
										|Type of data to import: %1
										|Attribute name: %2'; fa = 'A method to fill the required attribute is not specified.
										|Type of data to import: %1
										|Attribute name: %2';
										|it = 'Не задан способ заполнения обязательного реквизита.
										|Тип загружаемых данных: %1
										|Имя реквизита: %2';
										|pl = 'A method to fill the required attribute is not specified.
										|Type of data to import: %1
										|Attribute name: %2';
										|tr = 'Zorunlu özniteliğin doldurulma yöntemi belirtilmedi.
										|Yüklenen veri tipi: %1
										|Öznitelik adı: %2'"),
								DescriptionOfUploadedData[SettingUpProps.KeyOfUploadedData].Presentation,
								AttributeDetails.Presentation);
		AddEntryToErrorLog(
			Enums.ImportMasterDataIssueTypes.DataSourceSettings,
			MessageText,
			SettingUpProps.KeyOfUploadedData);
		
		Cancel = True;
		
	EndDo;
	
	If Cancel Then
		Cache.ErrorIsRecordedInProtocol = True;
		Raise NStr("vi = 'Chưa tiến hành kiểm tra tùy chỉnh điền mục tin.';
					|ru = 'Проверка настроек заполнения реквизитов не пройдена.';
					|en = 'The check of the attribute filling settings failed.'; fa = 'The check of the attribute filling settings failed.';
					|it = 'Проверка настроек заполнения реквизитов не пройдена.';
					|pl = 'The check of the attribute filling settings failed.';
					|tr = 'Öznitelikleri doldurma ayarlarının kontrolü geçilmedi.'");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Function HashByStructureValues(Structure)
	
	Result = New DataHashing(HashFunction.MD5);
	
	For Each KeyAndValue In Structure Do
		Value = KeyAndValue.Value;
		If Common.RefTypeValue(Value) Then
			Result.Append(String(Value.UUID()));
		Else
			Result.Append(String(Value));
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure WriteResultOfExecutionToLog(Result)
	
	StructureOfCounters = Result.StructureOfCounters;
	
	MessageText = StrTemplate(NStr("vi = 'Thời gian thực hiện: %1 giây
			|Số lượng lỗi: %2
			|Đã tìm thấy tham chiếu: %3';
			|ru = 'Время выполнения: %1 сек.
			|Количество ошибок: %2
			|Ссылок найдено: %3';
			|en = 'Execution time: %1 sec.
			|Number of errors: %2
			|References found: %3'; fa = 'Execution time: %1 sec.
			|Number of errors: %2
			|References found: %3';
			|it = 'Время выполнения: %1 сек.
			|Количество ошибок: %2
			|Ссылок найдено: %3';
			|pl = 'Execution time: %1 sec.
			|Number of errors: %2
			|References found: %3';
			|tr = 'Yürütme süresi: %1 sn.
			|Hata miktarı: %2
			|Bulunan bağlantılar: %3'"),
		Result.EndDate - Result.StartDate,
		Result.ErrorsCount,
		StructureOfCounters.LinksFound);
	
	For Each KeyAndValue In NestedTagsFact() Do
		AttachedMessages = New Array;
		For Each KeyAndValueAreNested In StructureOfCounters[KeyAndValue.Key] Do
			AttachedMessages.Add(StrTemplate("%1: %2", KeyAndValueAreNested.Key, KeyAndValueAreNested.Value));
		EndDo;
		If ValueIsFilled(AttachedMessages) Then
			MessageText = StrTemplate("%1
				|
				|-------------------
				|%2
				|%3", MessageText, Upper(KeyAndValue.Value), StrConcat(AttachedMessages, Chars.LF));
		EndIf;
	EndDo;
	
	WriteLogEvent(
		DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
		EventLogLevel.Information,,,
		MessageText);
	
EndProcedure

Procedure InitializeVariablesWhenCreating()
	
	DataChunkSize = 1000;
	
	ReferenceTypes = ProductDataManagementCached.AllConfigurationReferenceTypes();
	
	IDsTable = New ValueTable;
	IDsTable.Columns.Add("Id",               New TypeDescription("String",,,,New StringQualifiers(150)));
	IDsTable.Columns.Add("MetadataObject",            New TypeDescription(ReferenceTypes));
	IDsTable.Columns.Add("CompoundTypeConnections" ,        New TypeDescription("Array"));
	IDsTable.Columns.Add("MapUser",                 New TypeDescription("Boolean"));
	IDsTable.Columns.Add("TableIndex",               New TypeDescription("Number"));
	IDsTable.Columns.Add("ExternalSystemPresentation", New TypeDescription("String",,,,New StringQualifiers(150)));
	IDsTable.Columns.Add("ValuesOwner",            New TypeDescription(ReferenceTypes));
	
	BatchSearchTable = New ValueTable;
	BatchSearchTable.Columns.Add("Id",               New TypeDescription("String",,,,New StringQualifiers(150)));
	BatchSearchTable.Columns.Add("MetadataObject",            New TypeDescription(ReferenceTypes));
	BatchSearchTable.Columns.Add("AttributeName",                New TypeDescription("String"));
	BatchSearchTable.Columns.Add("MethodToSetValue",     New TypeDescription("EnumRef.ImportMasterDataMethodsToSetAttributeValue"));
	BatchSearchTable.Columns.Add("TableName",                  New TypeDescription("String"));
	BatchSearchTable.Columns.Add("StorageObject",              New TypeDescription());
	BatchSearchTable.Columns.Add("ThisIsID",            New TypeDescription("Boolean"));
	BatchSearchTable.Columns.Add("ThisIsMainIdentifier",    New TypeDescription("Boolean"));
	BatchSearchTable.Columns.Add("CompoundTypeConnections" ,        New TypeDescription("Array"));
	BatchSearchTable.Columns.Add("Found4",                     New TypeDescription("Boolean"));
	BatchSearchTable.Columns.Add("ValuesOwner",            New TypeDescription(ReferenceTypes));
	BatchSearchTable.Columns.Add("HasCode",                     New TypeDescription("Boolean"));
	BatchSearchTable.Columns.Add("HasDescription",            New TypeDescription("Boolean"));
	BatchSearchTable.Columns.Add("HasNumber",                   New TypeDescription("Boolean"));
	
	ErrorProtocolTable = New ValueTable;
	ErrorProtocolTable.Columns.Add("IssueType",                  New TypeDescription("EnumRef.ImportMasterDataIssueTypes"));
	ErrorProtocolTable.Columns.Add("ErrorText",                  New TypeDescription("String"));
	ErrorProtocolTable.Columns.Add("ExceptionText",              New TypeDescription("String"));
	ErrorProtocolTable.Columns.Add("ExceptionTextIsDetailed",     New TypeDescription("String"));
	ErrorProtocolTable.Columns.Add("TextMessagesToUser",   New TypeDescription("String"));
	ErrorProtocolTable.Columns.Add("Id",                New TypeDescription("String",,,,New StringQualifiers(150)));
	ErrorProtocolTable.Columns.Add("KeyOfUploadedData",        New TypeDescription("String"));
	ErrorProtocolTable.Columns.Add("FileFields",                    New TypeDescription());
	ErrorProtocolTable.Columns.Add("ObjectReference",               New TypeDescription(ReferenceTypes));
	ErrorProtocolTable.Columns.Add("Date",                         New TypeDescription("Date"));
	ErrorProtocolTable.Columns.Add("SectionKey",                  New TypeDescription("String"));
	ErrorProtocolTable.Columns.Add("FileName",                     New TypeDescription("String"));
	ErrorProtocolTable.Columns.Add("AttributeDetails",            New TypeDescription());
	ErrorProtocolTable.Columns.Add("ValuesOwner",             New TypeDescription(ReferenceTypes));
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

InitializeVariablesWhenCreating();

#EndRegion

#EndIf