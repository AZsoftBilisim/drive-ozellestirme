
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Data Source Settings Constructor
// 
// Parameters:
// Content - Number - The composition of the settings (0 - complete, 1 - only grouped, 2 - only external)
// 
// Returns:
//  Structure - Data Source Settings Constructor:
// * SectionsToBeProcessed - Structure
// * LocationOfData - String
// * HardwareLoadingOption - EnumRef.ImportMasterDataEquipment
// * ObjectProcessingAlgorithms - Structure
// * ResolvingSearchConflicts - Structure
// * ActionsWithFiles - Structure
// * UpdatingObjects - See ProductDataManagementClientServer.DescriptionOfObjectUpdateSettingsConstructor
// * Used - Boolean
// * AutoimportIsUsed - Boolean
// * AutoimportSchedule - Undefined
// * AutoimportJobID - UUID
Function DataSourceSettingsConstructor(Content = 0) Export
	
	Result = New Structure;
	
	If Content = 0 Or Content = 1 Then
		Result.Insert("SettingsVersion",                   SettingsVersion());
		Result.Insert("LocationOfData",               "");
		Result.Insert("SectionsToBeProcessed",                New Structure);
		Result.Insert("HardwareLoadingOption",      Enums.ImportMasterDataEquipment.WorkCenterTypes);
		Result.Insert("ObjectProcessingAlgorithms",       New Structure);
		Result.Insert("ResolvingSearchConflicts",    New Structure);
		Result.Insert("ActionsWithFiles",                 New Structure);
		Result.Insert("UpdatingObjects",               ProductDataManagementClientServer.DescriptionOfObjectUpdateSettingsConstructor());
	EndIf;
	
	If Content = 0 Or Content = 2 Then
		Result.Insert("Used",                     False);
		Result.Insert("AutoimportIsUsed",         False);
		Result.Insert("AutoimportSchedule",           Undefined);
		Result.Insert("AutoimportJobID", Undefined);
	EndIf;
	
	Return Result;
	
EndFunction

// Data source settings.
// 
// Parameters:
//  DataSource - CatalogObject.SourcesToImportProductionMasterData
// 
// Returns:
//  Structure - See DataSourceSettingsConstructor
//
Function DataSourceSettings(DataSource) Export
	
	Result = DataSourceSettingsConstructor();
	
	If DataSource <> Undefined
		And DataSource <> Catalogs.SourcesToImportProductionMasterData.EmptyRef() Then
		
		SettingsStorage = Undefined;
		
		If TypeOf(DataSource) = Type("CatalogRef.SourcesToImportProductionMasterData") Then
			IsObject = False;
			DataSourceLink = DataSource;
		Else
			IsObject = True;
			DataSourceLink = DataSource.Ref;
		EndIf;
		
		If ValueIsFilled(DataSourceLink) Then
			
			QueryText = "
			|SELECT
			|	DataSources.ExchangeFormat                                                   AS ExchangeFormat,
			|	DataSources.SettingsStorage                                              AS SettingsStorage,
			|	ISNULL(AdditionalSettings.Used, FALSE)                             AS Used,
			|	ISNULL(AdditionalSettings.AutoimportJobID, UNDEFINED) AS AutoimportJobID
			|FROM
			|	Catalog.SourcesToImportProductionMasterData AS DataSources
			|
			|		LEFT JOIN InformationRegister.MasterDataImportSettings AS AdditionalSettings
			|		ON DataSources.Ref = AdditionalSettings.DataSource
			|WHERE
			|	DataSources.Ref = &DataSource
			|";
			
			Query = New Query;
			Query.Text = QueryText;
			Query.SetParameter("DataSource", DataSourceLink);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				FillPropertyValues(Result, Selection);
				FillInStartupSettings(Result);
				SettingsStorage = Selection.SettingsStorage;
			EndIf
			
		EndIf;
		
		If IsObject Then
			FillPropertyValues(Result, DataSource);
			SettingsStorage = DataSource.SettingsStorage;
		EndIf;
		
		Try
		
			If SettingsStorage <> Undefined Then
				SettingsStructure = GetStructureOfSettingsFromRepository(SettingsStorage);
				For Each KeyAndValue In DataSourceSettingsConstructor(1) Do
					SettingName = KeyAndValue.Key;
					If SettingsStructure.Property(SettingName) Then
						Result[SettingName] = SettingsStructure[SettingName];
					EndIf;
				EndDo;
			EndIf;
		
		Except
			ErrorText = StrTemplate(NStr("vi = 'Không thể nhận tùy chỉnh nguồn dữ liệu ""%1"".
				|%2 ';
				|ru = 'Не удалось получить настройки источника данных ""%1"".
				|%2';
				|en = 'Cannot get settings of the %1 data source.
				|%2'; fa = 'Cannot get settings of the %1 data source.
				|%2';
				|it = 'Не удалось получить настройки источника данных ""%1"".
				|%2';
				|pl = 'Cannot get settings of the %1 data source.
				|%2';
				|tr = '""%1"" verilerinin kaynak ayarları alınamadı.
				|%2'"), DataSource, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
					EventLogLevel.Error,,
					DataSource,
					ErrorText);
		EndTry;
		
	EndIf;
	
	If Not ValueIsFilled(Result.SectionsToBeProcessed) Then
		Result.SectionsToBeProcessed = ProductDataManagementClientServer.SectionsToBeProcessedByConstructor();
	EndIf;
	
	Return Result;
	
EndFunction

// Returns reference data types that are loaded or matched for the source
// 
// Parameters:
//  DataSource  - CatalogRef.SourcesToImportProductionMasterData
//  DescriptionOfUploadedData - See ProductDataManagement.DescriptionOfUploadedData
//  Filter - Undefined,Structure
//  ExceptionOnError - Boolean - determines whether to stop if the description and setting data do not match
//  
// 
// Returns:
//  ValueTable - Source reference data types:
// * MetadataObject - CatalogRef.MetadataObjectIDs
Function SourceAttributeSettings(DataSource, DescriptionOfUploadedData, Filter = Undefined, ExceptionOnError = False) Export
	
	Result = New ValueTable;
	
	Result.Columns.Add("MetadataObject",              New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.Columns.Add("MetadataObjectName",          New TypeDescription("String"));
	Result.Columns.Add("TSName",                         New TypeDescription("String"));
	Result.Columns.Add("AttributeName",                  New TypeDescription("String"));
	Result.Columns.Add("MethodToSetValue",       New TypeDescription("EnumRef.ImportMasterDataMethodsToSetAttributeValue"));
	Result.Columns.Add("Value",                      New TypeDescription());
	Result.Columns.Add("ValueCalculationAlgorithm",       New TypeDescription("String"));
	Result.Columns.Add("FieldForSearch",                    New TypeDescription("Boolean"));
	Result.Columns.Add("ConnectionKey",                     New TypeDescription("UUID"));
	
	Result.Columns.Add("SectionKey",                   New TypeDescription("String"));
	Result.Columns.Add("KeyOfUploadedData",         New TypeDescription("String"));
	Result.Columns.Add("ReferentialType",                  New TypeDescription("Boolean"));
	Result.Columns.Add("ThisIsMainIdentifier",      New TypeDescription("Boolean"));
	Result.Columns.Add("AttributeDetails");
	
	QueryText = "
	|SELECT
	|	T.MetadataObject           AS MetadataObject,
	|	T.MetadataObject.Name       AS MetadataObjectName,
	|	T.TSName                      AS TSName,
	|	T.AttributeName               AS AttributeName,
	|	T.MethodToSetValue    AS MethodToSetValue,
	|	T.Value                   AS Value,
	|	T.ValueCalculationAlgorithm    AS ValueCalculationAlgorithm,
	|	T.FieldForSearch                 AS FieldForSearch,
	|	T.ConnectionKey                  AS ConnectionKey
	|FROM
	|	Catalog.SourcesToImportProductionMasterData.AttributesDetails1 AS T
	|WHERE
	|	T.Ref = &DataSource
	|	AND NOT T.MethodToSetValue IN (&ExcludeWaysToSetValue)
	|
	|ORDER BY
	|	MetadataObject,
	|	TSName,
	|	AttributeName";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataSource", DataSource);
	
	If Filter <> Undefined
		And Filter.Property("ExcludeWaysToSetValue") Then
		Query.SetParameter("ExcludeWaysToSetValue", Filter.ExcludeWaysToSetValue);
	Else
		Query.SetParameter("ExcludeWaysToSetValue", New Array);
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		KeyOfUploadedData = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement(
			Selection.MetadataObjectName, Selection.TSName);
			
		If Not DescriptionOfUploadedData.Property(KeyOfUploadedData) Then
			ErrorText = StrTemplate(NStr("vi = 'Mô tả không xác định dữ liệu được kết nhập: %1.';
										|ru = 'Неизвестное описание загружаемых данных: %1.';
										|en = 'Unknown description of data to import: %1.'; fa = 'Unknown description of data to import: %1.';
										|it = 'Неизвестное описание загружаемых данных: %1.';
										|pl = 'Unknown description of data to import: %1.';
										|tr = 'Yüklenen verilerin bilinmeyen ayrıntıları: %1.'"), KeyOfUploadedData);
			WriteLogEvent(DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
				EventLogLevel.Error,,
				DataSource,
				ErrorText);
			If ExceptionOnError Then
				Raise ErrorText;
			EndIf;
			Continue;
		EndIf;
		
		AttributeDetails = ProductDataManagement.DescriptionOfAttributesOfUploadedDataByName(
			Selection.AttributeName, DescriptionOfUploadedData[KeyOfUploadedData]);
			
		If AttributeDetails = Undefined Then
			ErrorText = StrTemplate(NStr("vi = 'Mục tin mô tả dữ liệu được kết nhập không xác định: %1.';
										|ru = 'Неизвестный реквизит описания загружаемых данных: %1.';
										|en = 'Unknown attribute of the description of data to import: %1.'; fa = 'Unknown attribute of the description of data to import: %1.';
										|it = 'Неизвестный реквизит описания загружаемых данных: %1.';
										|pl = 'Unknown attribute of the description of data to import: %1.';
										|tr = 'Yüklenen veri ayrıntılarının bilinmeyen özniteliği: %1.'"), Selection.AttributeName);
			WriteLogEvent(DataProcessors.ImportProductionMasterData.LogEventKey(DataSource),
				EventLogLevel.Error,,
				DataSource,
				ErrorText);
			If ExceptionOnError Then
				Raise ErrorText;
			EndIf;
			Continue;
		EndIf;
		
		NewRow = Result.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.SectionKey = DescriptionOfUploadedData[KeyOfUploadedData].SectionKey;
		NewRow.KeyOfUploadedData = KeyOfUploadedData;
		NewRow.ReferentialType = AttributeDetails.ReferentialType Or AttributeDetails.ThisIsID;
		NewRow.ThisIsMainIdentifier = AttributeDetails.ThisIsMainIdentifier;
		NewRow.AttributeDetails = AttributeDetails;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region Settings

// The Cur version of the data source settings.
// 
// Returns:
//  Number
Function SettingsVersion() Export
	
	Return 1;
	
EndFunction

// Restores the structure of settings from the repository.
// In particular, it provides conversion to the current version of settings.
// 
// Parameters:
//  SettingsStorage - ValueStorage
// 
// Returns:
//  See DataSourceSettingsConstructor
Function GetStructureOfSettingsFromRepository(SettingsStorage) Export
	
	If Not ValueIsFilled(SettingsStorage) Then
		Return Undefined;
	EndIf;
	
	SettingsStructure = SettingsStorage.Get(); // See DataSourceSettingsConstructor
	
	If Not ValueIsFilled(SettingsStructure) Then
		Return Undefined;
	EndIf;
	
	If SettingsStructure.Property("SettingsVersion") Then
		VersionOfSavedSettings = SettingsStructure.SettingsVersion;
	Else
		VersionOfSavedSettings = 0;
	EndIf;
	
	If VersionOfSavedSettings >= SettingsVersion() Then
		Return SettingsStructure;
	EndIf;
	
	If VersionOfSavedSettings = 0 Then
		ConvertConflictResolutionSettings(SettingsStructure);
		ConvertKeysOfObjectProcessingAlgorithms(SettingsStructure);
	EndIf;
	
	SettingsStructure.Insert("SettingsVersion", SettingsVersion());
	
	Return SettingsStructure;
	
EndFunction

// Put the settings structure in the repository.
// 
// Parameters:
//  Object - CatalogObject.SourcesToImportProductionMasterData
//  SettingsStructure - See DataSourceSettingsConstructor
Procedure PutSettingsStructureInRepository(Object, SettingsStructure) Export
	
	If Not ValueIsFilled(SettingsStructure) Then
		SettingsStructure = DataSourceSettingsConstructor(1);
	EndIf;
		
	Object.SettingsVersion    = SettingsStructure.SettingsVersion;
	Object.SettingsStorage = New ValueStorage(SettingsStructure);
	
EndProcedure

Procedure FillInStartupSettings(SourceSettings) Export
	
	If Not ValueIsFilled(SourceSettings.AutoimportJobID) Then
		Return;
	EndIf;
	
	Job = ScheduledJobsServer.Job(SourceSettings.AutoimportJobID);
	If Job <> Undefined Then
		SourceSettings.AutoimportIsUsed = Job.Use;
		SourceSettings.AutoimportSchedule   = Job.Schedule;
	EndIf;
	
EndProcedure

Procedure ConvertConflictResolutionSettings(SettingsStructure)
	
	SortingSettings = Undefined;
	If Not SettingsStructure.Property("SortingSettings", SortingSettings)
		Or Not ValueIsFilled(SortingSettings) Then
		Return;
	EndIf;
	
	ResolvingSearchConflicts = Undefined;
	If Not SettingsStructure.Property("ResolvingSearchConflicts", ResolvingSearchConflicts) Then
		ResolvingSearchConflicts = New Structure;
		SettingsStructure.Insert("ResolvingSearchConflicts", ResolvingSearchConflicts);
	EndIf;
	
	For Each KeyAndValue In SortingSettings Do
		If Not ResolvingSearchConflicts.Property(KeyAndValue.Key)
				And ValueIsFilled(KeyAndValue.Value) Then
			SettingUpRule = ProductDataManagementClientServer.DescriptionOfConflictResolutionSettingsForSearchConstructor();
			ResolvingSearchConflicts.Insert(KeyAndValue.Key, SettingUpRule);
		EndIf;
	EndDo;
	
EndProcedure

Procedure ConvertKeysOfObjectProcessingAlgorithms(SettingsStructure)
	
	ObjectProcessingAlgorithms = Undefined;
	If Not SettingsStructure.Property("ObjectProcessingAlgorithms", ObjectProcessingAlgorithms)
		Or Not ValueIsFilled(ObjectProcessingAlgorithms) Then
		Return;
	EndIf;
	
	For Each KeyAndValue In ProductDataManagement.DescriptionOfUploadedData(SettingsStructure) Do
		
		LongDesc = KeyAndValue.Value; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
		
		KeyIsOld = ProductDataManagementClientServer.KeyOfObjectProcessingAlgorithmWhenLoading(
			"AfterImport", LongDesc.MetadataObjectName, LongDesc.TSName);
		Key_New  = ProductDataManagementClientServer.KeyOfObjectProcessingAlgorithmWhenLoading(
			ProductDataManagementClientServer.NameOfEventBeforeRecordingObject(), LongDesc.MetadataObjectName, LongDesc.TSName);
		
		If ObjectProcessingAlgorithms.Property(KeyIsOld)
				And Not ObjectProcessingAlgorithms.Property(Key_New) Then
			ObjectProcessingAlgorithms.Insert(Key_New, ObjectProcessingAlgorithms[KeyIsOld]);
			ObjectProcessingAlgorithms.Delete(KeyIsOld);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Procedure InitializeNewRowInAttributesTable(RowData, IsRequired = False) Export
	
	RowData.ConnectionKey = New UUID();
	
	If IsRequired Then
		RowData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.GetFromFile");
	Else
		RowData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.DontUse");
	EndIf;
	
EndProcedure

// Information about the mode of working with sources.
// 
// Returns:
//  Structure:
// * MultipleDataSources - Boolean - indicates that multiple sources are used
// * DataSource - CatalogRef.SourcesToImportProductionMasterData - priority source for form substitution
Function InformationAboutModeOfWorkingWithSources() Export
	
	Result = New Structure;
	Result.Insert("MultipleDataSources", False);
	Result.Insert("DataSource", Catalogs.SourcesToImportProductionMasterData.EmptyRef());
	
	QueryText = "
	|SELECT
	|	COUNT(DISTINCT T.Ref) AS NumberOfSources
	|INTO TTNumberOfSources
	|
	|FROM
	|	Catalog.SourcesToImportProductionMasterData AS T
	|
	|;
	|SELECT TOP 1
	|	T1.NumberOfSources                                                                   AS NumberOfSources,
	|	ISNULL(T2.Ref, VALUE(Catalog.SourcesToImportProductionMasterData.EmptyRef)) AS DataSource
	|FROM
	|	TTNumberOfSources AS T1
	|		
	|		LEFT JOIN Catalog.SourcesToImportProductionMasterData AS T2
	|		ON NOT T2.DeletionMark
	|
	|ORDER BY
	|	ISNULL(T2.Code, """")
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Result.MultipleDataSources = Selection.NumberOfSources > 1;
	If Not Result.MultipleDataSources Then
		Result.DataSource = Selection.DataSource;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
