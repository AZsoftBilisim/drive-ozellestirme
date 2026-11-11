#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurHandlers;
Var HandlersAvailability; // Matching from objectmetadata: Structure
Var ManagerIsInitialized;

#EndRegion
	
#Region Internal

Procedure Initialize(Val Container) Export
	
	If ManagerIsInitialized Then
		Raise NStr("vi = 'Bộ quản lý hàm sự kiện kết xuất dữ liệu đã khởi xướng từ trước.';
					|ru = 'Менеджер обработчиков выгрузки данных уже был инициализирован ранее.';
					|en = 'The data export handler manager has been previously initialized.'; fa = 'The data export handler manager has been previously initialized.';
					|it = 'Manager degli elaboratori upload dati già precedentemente inizializzati.';
					|pl = 'Kreator procesorów danych eksportu danych został już zainicjowany wcześniej.';
					|tr = 'Veri dışa aktarma işleyici yöneticisi zaten daha önce başlatıldı.'");
	EndIf;
	
	BooleanType = New TypeDescription("Boolean");
	HandlerColumnsNames = HandlerColumnsNames();
	
	CurHandlers = New ValueTable;
	CurHandlers.Columns.Add("MetadataObject");
	CurHandlers.Columns.Add("Handler");
	CurHandlers.Columns.Add("Version", New TypeDescription("String"));

	For Each ColumnName In HandlerColumnsNames Do
		CurHandlers.Columns.Add(ColumnName, BooleanType);
	EndDo;

	// Integrated handlers
	DataAreasExportForTechnicalSupport.BeforeExportData(Container, CurHandlers);
	ProcessingTypesExcludedFromUpload.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportSharedData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportPredefinedData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportSharedPredefinedData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportCommonSeparatedData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportUserFavorites.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportValueStoragesData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportExchangePlansNodes.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportDataOfAdditionalReportsAndDataProcessors.OnRegisterDataExportHandlers(CurHandlers);

	// Library Event Handlers
	CTLSubsystemsIntegration.OnRegisterDataExportHandlers(CurHandlers);

	// Redefined procedure
	ExportImportDataOverridable.OnRegisterDataExportHandlers(CurHandlers);

	CurHandlers.Columns.Add("LineNumber");
	CurrentRowNumber1 = 1;
	
	For Each String In CurHandlers Do
		
		String.LineNumber = CurrentRowNumber1;
		CurrentRowNumber1 = CurrentRowNumber1 + 1;
		
		If IsBlankString(String.Version) Then
			String.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_0();
		EndIf;

	EndDo;
	
	CurHandlers.Indexes.Add("BeforeExportObject, MetadataObject");
	CurHandlers.Indexes.Add("AfterExportObject, MetadataObject");

	HandlersAvailability = ExportImportDataInternal.MetadataObjectsHandlersAvailability(
		CurHandlers, HandlerColumnsNames);
	ManagerIsInitialized = True;
	
EndProcedure

Procedure BeforeExportData(Container) Export
	
	If Not ManagerIsInitialized Then
		Raise NStr("vi = 'Bộ quản lý hàm sự kiện kết xuất dữ liệu chưa được khởi xướng.';
					|ru = 'Менеджер обработчиков выгрузки данных не инициализирован.';
					|en = 'The data export handler manager is not initialized.'; fa = 'The data export handler manager is not initialized.';
					|it = 'Manager elaboratori upload dati non inizializzati.';
					|pl = 'Kreator procesorów danych eksportu danych nie jest zainicjowany.';
					|tr = 'Veri dışa aktarma işleyici yöneticisi başlatılmadı.'");
	EndIf;
	
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeExportData", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeExportData(Container);
	EndDo;
	
	// Library Event Handlers
	CTLSubsystemsIntegration.BeforeExportData(Container);
	
	// Redefined procedure
	ExportImportDataOverridable.BeforeExportData(Container);
		
EndProcedure

// Called after data is uploaded.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - 
//    the container manager used in the data upload process. For more information, see the comment
//    on the software interface for processing the unloading of the data of the Manager container.
//
Procedure AfterExportData(Container) Export
	
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterExportData", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterExportData(Container);
	EndDo;
	
	// Library Event Handlers
	CTLSubsystemsIntegration.AfterExportData(Container);
	
	// Redefined procedure
	ExportImportDataOverridable.AfterExportData(Container);
	
EndProcedure

// See ExportImportDataInternalEvents.
//
Procedure BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeUnloadingType", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel);
	EndDo;
	
EndProcedure

// Called before unloading the object.
// see "When registering the processed data".
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeExportObject", True);
	FilterHandlers_.Insert("MetadataObject", Object.Metadata());
	
	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		
		If HandlerDetails.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_0() Then
			
			HandlerDetails.Handler.BeforeExportObject(Container, Serializer, Object, Artifacts, Cancel);
			
		Else
			
			HandlerDetails.Handler.BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Called before uploading the data object.
// see "When registering the data processing processers".
//
Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterExportObject", True);
	FilterHandlers_.Insert("MetadataObject", Object.Metadata());
	
	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		
		If HandlerDetails.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_0() Then
			
			HandlerDetails.Handler.AfterExportObject(Container, Serializer, Object, Artifacts);
			
		Else
			
			HandlerDetails.Handler.AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Executes the handlers after the upload of a specific data type.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//	Serializer - XDTOSerializer - serializer.
//	MetadataObject - MetadataObject - metadata object.
//
Procedure AfterUnloadingType(Container, Serializer, MetadataObject) Export
		
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterUnloadingType", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterUnloadingType(Container, Serializer, MetadataObject);
	EndDo;
	
EndProcedure

Procedure BeforeUnloadingSettingsStore(Container, Serializer, NameOfSettingsStore, Val SettingsStorage, Cancel) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeUnloadingSettingsStore", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeUnloadingSettingsStore(Container, Serializer, NameOfSettingsStore, SettingsStorage, Cancel);
	EndDo;
	
EndProcedure

// Performed before uploading settings.
// 
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//	Serializer - XDTOSerializer - serializer.
//	NameOfSettingsStore - String -
//	SettingsKey - String - see syntax -platform assistant.
//	ObjectKey - String - see syntax -platform assistant.
//	Settings - ValueStorage - 
//	User - InfoBaseUser - 
//	Presentation - String - 
// 	Artifacts - Array of XDTODataObject - additional data.
// 	Cancel - Boolean - indicates that processing was refused.
//
Procedure BeforeUploadingSettings(Container, Serializer, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeUploadingSettings", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeUploadingSettings(
			Container,
			Serializer,
			NameOfSettingsStore,
			SettingsKey,
			ObjectKey,
			Settings,
			User,
			Presentation,
			Artifacts,
			Cancel);
	EndDo;
	
EndProcedure

Procedure AfterUnloadingSettings(Container, Serializer, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterUnloadingSettings", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterUnloadingSettings(
			Container,
			Serializer,
			NameOfSettingsStore,
			SettingsKey,
			ObjectKey,
			Settings,
			User,
			Presentation);
	EndDo;
	
EndProcedure

Procedure AfterUnloadingSettingsStore(Container, Serializer, NameOfSettingsStore, Val SettingsStorage) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterUnloadingSettingsStore", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterUnloadingSettingsStore(Container, Serializer, NameOfSettingsStore, SettingsStorage);
	EndDo;
	
EndProcedure

// Availability of handlers for the metadata object.
// 
// Parameters:
//  MetadataObject - MetadataObject - metadata object
// 
// Returns:
//  Structure - Availability Of Handlers For The Metadata Object
Function MetadataObjectHandlersAvailability(MetadataObject) Export
	
	ObjectHandlersAvailability = HandlersAvailability.Get(MetadataObject);
	
	If ObjectHandlersAvailability = Undefined Then
		ObjectHandlersAvailability = ExportImportDataInternal.NewMetadataObjectHandlersAvailabilityData(
			HandlerColumnsNames());
	EndIf;
	
	Return ObjectHandlersAvailability;
	
EndFunction

#EndRegion

#Region Private

Function HandlerDescriptions(FilterHandlers_)
	FoundHandlers = CurHandlers.Copy(FilterHandlers_);
	FoundHandlers.Sort("LineNumber");
	Return FoundHandlers;
EndFunction

// The names of the handler columns.
// 
// Returns:
//  Array of String - column name
Function HandlerColumnsNames()
	
	ColumnsNames = New Array();
	ColumnsNames.Add("BeforeExportData");
	ColumnsNames.Add("AfterExportData");
	ColumnsNames.Add("BeforeUnloadingType");
	ColumnsNames.Add("BeforeExportObject");
	ColumnsNames.Add("AfterExportObject");
	ColumnsNames.Add("AfterUnloadingType");
	ColumnsNames.Add("BeforeUnloadingSettingsStore");
	ColumnsNames.Add("BeforeUploadingSettings");
	ColumnsNames.Add("AfterUnloadingSettings");
	ColumnsNames.Add("AfterUnloadingSettingsStore");
	
	Return ColumnsNames;
	
EndFunction

#EndRegion

#Region Initialize
	ManagerIsInitialized = False;
#EndRegion

#EndIf
