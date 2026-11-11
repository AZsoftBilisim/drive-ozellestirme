#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurHandlers;
Var HandlersAvailability; // Matching from objectmetadata: Structure
Var ManagerIsInitialized;

#EndRegion

#Region Internal

Procedure Initialize() Export
	
	If ManagerIsInitialized Then
		Raise NStr("vi = 'Bộ quản lý hàm sự kiện kết nhập dữ liệu đã được khởi xướng từ trước.';
					|ru = 'Менеджер обработчиков загрузки данных уже был инициализирован ранее.';
					|en = 'The data import handler manager has been previously initialized.'; fa = 'The data import handler manager has been previously initialized.';
					|it = 'Manager elaboratori upload dati già precedentemente inizializzato.';
					|pl = 'Kreator procesorów danych importu danych był już inicjowany wcześniej.';
					|tr = 'Veri içe aktarma işleyici yöneticisi zaten daha önce başlatıldı.'");
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
	ExportImportValueStoragesData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportSequencesBoundaryData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportPredefinedData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportSharedPredefinedData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportCommonSeparatedData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportDataTotalsManagement.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportUserFavorites.OnRegisterDataImportHandlers(CurHandlers);

	// Library Event Handlers
	CTLSubsystemsIntegration.OnRegisterDataImportHandlers(CurHandlers);

	// Redefined procedure
	ExportImportDataOverridable.OnRegisterDataImportHandlers(CurHandlers);
	
	CurHandlers.Columns.Add("LineNumber");
	CurrentRowNumber1 = 1;
	
	For Each String In CurHandlers Do
		
		String.LineNumber = CurrentRowNumber1;
		CurrentRowNumber1 = CurrentRowNumber1 + 1;
		
		If IsBlankString(String.Version) Then
			String.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_0();
		EndIf;
		
	EndDo;
	
	CurHandlers.Indexes.Add("BeforeImportObject, MetadataObject");
	CurHandlers.Indexes.Add("AfterImportObject, MetadataObject");
	
	HandlersAvailability = ExportImportDataInternal.MetadataObjectsHandlersAvailability(
		CurHandlers, HandlerColumnsNames);
	ManagerIsInitialized = True;
		
EndProcedure

// See ExportImportDataInternalEvents.
//
Procedure BeforeImportData(Container) Export
		
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeImportData", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeImportData(Container);
	EndDo;
	
	// Library Event Handlers
	CTLSubsystemsIntegration.BeforeImportData(Container);
	
	// Redefined procedure
	ExportImportDataOverridable.BeforeImportData(Container);
	
EndProcedure

// Performs a number of actions when loading the user information database.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//
Procedure AfterImportData(Container) Export
		
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterImportData", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterImportData(Container);
	EndDo;
	
	// Library Event Handlers
	CTLSubsystemsIntegration.AfterImportData(Container);
	
	// Redefined procedure
	ExportImportDataOverridable.AfterImportData(Container);
	
EndProcedure

Procedure BeforeMapRefs(Container, MetadataObject, SourceRefsTable, StandardProcessing, NonStandardHandler, Cancel) Export
		
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeMapRefs", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		
		HandlerDetails.Handler.BeforeMapRefs(Container, MetadataObject, SourceRefsTable, StandardProcessing, Cancel);
		
		If Not StandardProcessing Or Cancel Then
			NonStandardHandler = HandlerDetails.Handler;
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// The action to be performed when replacing the links.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - the container manager used in 
//	 the data upload process. For more information, see the comment on the processing software interface.
//	RefsMap - Map - see the description of the processing object.Offloading and offloading of the given filesreferences
//
Procedure WhenReplacingLinks(Container, RefsMap) Export
		
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("WhenReplacingLinks", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.WhenReplacingLinks(Container, RefsMap);
	EndDo;
	
EndProcedure

// Executes handlers before loading a specific type of data.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//	MetadataObject - MetadataObject - metadata object.
//	Cancel - Boolean - indicates whether this operation was performed.
//
Procedure BeforeImportType(Container, MetadataObject, Cancel) Export
		
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeImportType", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeImportType(Container, MetadataObject, Cancel);
	EndDo;
	
EndProcedure

// Called before unloading the object.
// see "When registering the processed data".
//
Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
		
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeImportObject", True);
	FilterHandlers_.Insert("MetadataObject", Object.Metadata());

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeImportObject(Container, Object, Artifacts, Cancel);
	EndDo;
	
EndProcedure

// Executes handlers after the object is loaded.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//	Object - Arbitrary - the object of the uploaded data.
//	Artifacts - Array of XDTODataObject - array of artifacts (XDTO objects).
//
Procedure AfterImportObject(Container, Object, Artifacts) Export
	
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterImportObject", True);
	FilterHandlers_.Insert("MetadataObject", Object.Metadata());

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterImportObject(Container, Object, Artifacts);
	EndDo;
	
EndProcedure

// See the description of the procedure for adding service events() to the general module of unloading and unloading service events.
//
Procedure AfterLoadingType(Container, MetadataObject) Export
		
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterLoadingType", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterLoadingType(Container, MetadataObject);
	EndDo;
	
EndProcedure

Procedure BeforeLoadingSettingsStore(Container, NameOfSettingsStore, SettingsStorage, Cancel) Export

	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeLoadingSettingsStore", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeLoadingSettingsStore(Container, NameOfSettingsStore, SettingsStorage, Cancel);
	EndDo;
	
EndProcedure

Procedure BeforeDownloadingSettings(Container, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeDownloadingSettings", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeDownloadingSettings(
			Container,
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

Procedure AfterLoadingSettings(Container, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts) Export
	
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterLoadingSettings", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterLoadingSettings(
			Container,
			NameOfSettingsStore,
			SettingsKey,
			ObjectKey,
			Settings,
			User,
			Presentation,
			Artifacts);
	EndDo;
	
EndProcedure

Procedure AfterLoadingSettingsStore(Container, NameOfSettingsStore, SettingsStorage) Export
	
	// Registered Handlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterLoadingSettingsStore", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterLoadingSettingsStore(Container, NameOfSettingsStore, SettingsStorage);
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
	ColumnsNames.Add("BeforeImportData");
	ColumnsNames.Add("AfterImportData");
	ColumnsNames.Add("BeforeMapRefs");
	ColumnsNames.Add("WhenReplacingLinks");
	ColumnsNames.Add("BeforeImportType");
	ColumnsNames.Add("BeforeImportObject");
	ColumnsNames.Add("AfterImportObject");
	ColumnsNames.Add("AfterLoadingType");
	ColumnsNames.Add("BeforeLoadingSettingsStore");
	ColumnsNames.Add("BeforeDownloadingSettings");
	ColumnsNames.Add("AfterLoadingSettings");
	ColumnsNames.Add("AfterLoadingSettingsStore");
	
	Return ColumnsNames;
	
EndFunction

#EndRegion

#Region Initialize
	ManagerIsInitialized = False;
#EndRegion

#EndIf