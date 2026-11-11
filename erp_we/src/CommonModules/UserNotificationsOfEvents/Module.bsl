#Region Public

// Event handler for recording the source of user alerts.
// 
// Parameters:
//  Source - CatalogObject, DocumentObject - Source
//  Cancel - Boolean - Cancel
Procedure WhenWritingUserNotificationSource(Source, Cancel) Export
	
	FullSourceName = Source.Metadata().FullName();
	If Source.DataExchange.Load 
		Or Source.AdditionalProperties.Property("DisableUserAlerts") 
		Or Not SourceIsAvailable(FullSourceName) Then
		
		Return;
		
	EndIf;
	
	NotificationKindsBySourceAttributes = NotificationKindsBySourceAttributes(FullSourceName);
	For Each SourceProps In NotificationKindsBySourceAttributes Do
		
		AttributeName = SourceProps.Key;
		AvailableNotificationKinds = SourceProps.Value;
		
		Try
			AttributeValue = Source[AttributeName];
		Except
			WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Tạo thông báo';
								|ru = 'Оповещения пользователей.Формирование оповещений';
								|en = 'User notifications.Generate notifications'; fa = 'User notifications.Generate notifications';
								|it = 'User notifications.Generate notifications';
								|pl = 'User notifications.Generate notifications';
								|tr = 'Kullanıcı bildirimleri.Bildirim oluşturma'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		GenerateTasksForNotifyingUsers(AttributeValue, AvailableNotificationKinds);
		
	EndDo;
	
EndProcedure

// Event handler for recording the source of user alerts.
// 
// Parameters:
//  Source - AccumulationRegisterRecordSet, InformationRegisterRecordSet - source of the alert.
//  Cancel - Boolean - Refusal.
//  Replacing - Boolean - the substitution attribute.
Procedure WhenWritingRecordSetOfUserNotificationSource(Source, Cancel, Replacing) Export
	
	FullSourceName = Source.Metadata().FullName();
	If Source.DataExchange.Load 
		Or Source.AdditionalProperties.Property("DisableUserAlerts")
		Or Not SourceIsAvailable(FullSourceName) Then
		
		Return;
		
	EndIf;
	
	NotificationKindsBySourceAttributes = NotificationKindsBySourceAttributes(FullSourceName);
	For Each SourceProps In NotificationKindsBySourceAttributes Do
		
		AttributeName = SourceProps.Key;
		AvailableNotificationKinds = SourceProps.Value;
		
		Try
			ArrayOfSources = Source.UnloadColumn(AttributeName);
		Except
			WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Tạo thông báo';
								|ru = 'Оповещения пользователей.Формирование оповещений';
								|en = 'User notifications.Generate notifications'; fa = 'User notifications.Generate notifications';
								|it = 'User notifications.Generate notifications';
								|pl = 'User notifications.Generate notifications';
								|tr = 'Kullanıcı bildirimleri.Bildirim oluşturma'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		ArrayOfSources = CommonClientServer.CollapseArray(ArrayOfSources);
		GenerateTasksForNotifyingUsers(ArrayOfSources, AvailableNotificationKinds);
		
	EndDo;
EndProcedure

// Generates tasks in the information register "Tasks for notifying users".
// 
// Parameters:
//  NotificationSource - AnyRef, Array of AnyRef - link-the source of the task or an array of links to be reflected.
//  NotificationKinds - Array of CatalogRef.UserNotificationKinds - array of reflected types of alerts by source.
//  NotificationInitiator - CatalogRef.Users, Undefined - the user is the initiator of the notification.
//  Run - Boolean - indicates that tasks are running. The default is TRUE.
Procedure GenerateTasksForNotifyingUsers(NotificationSource, NotificationKinds, NotificationInitiator = Undefined, Run = True) Export
	
	If Not ValueIsFilled(NotificationSource) Or Not ValueIsFilled(NotificationKinds) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(NotificationInitiator) Then
		NotificationInitiator = Users.AuthorizedUser();
	EndIf;
	
	Queue = InformationRegisters.JobsToNotifyUsers.NameOfTaskQueue();
	
	TaskTable = ?(Run,
						DeferredJobs.InitializeTaskTable(Queue),
						Undefined);
	InformationRegisters.JobsToNotifyUsers.AddTasksToReflection(
		NotificationSource,
		NotificationKinds,
		NotificationInitiator,
		TaskTable);
	
	If Run Then
		DeferredJobs.Run(TaskTable);
	EndIf;
	
EndProcedure

// Routine task handler.
// Notifies users of non-operational alerts.
//
Procedure NotifyingUsersOfNonOperationalNotificationKinds() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.UserNotificationsOfEvents);
	If ExclusiveMode() Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Author = UserNotificationsOfEventsCached.UserNotificationAuthor();
	CheckPrepareConnectionToInteractionSystem(Author);
	
	Query = New Query;
	Query.Text = "SELECT
	|	NotificationKinds.Ref AS Ref,
	|	NotificationKinds.NotificationTextTemplate,
	|	NotificationKinds.GroupingThreshold,
	|	NotificationKinds.GroupedNotificationText,
	|	NotificationKinds.DCSTemplateName,
	|	NotificationKinds.DataCompositionSchema,
	|	NotificationKinds.StorageOfDataCompositionSettings,
	|	ISNULL(NotificationKinds.Parent.GroupItIntoSeparateDiscussion, FALSE) AS GroupItIntoSeparateDiscussion,
	|	ISNULL(NotificationKinds.Parent.Description, """") AS GroupHeader,
	|	PRESENTATION(UUID(NotificationKinds.Parent)) AS GroupingID
	|FROM
	|	Catalog.UserNotificationKinds AS NotificationKinds
	|WHERE
	|	NotificationKinds.Running
	|	AND NOT NotificationKinds.DeletionMark
	|	AND NOT NotificationKinds.IsFolder
	|	AND NotificationKinds.NotificationType = VALUE(Enum.UserNotificationTypes.NonOperational)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UserNotificationData.NotificationSource,
	|	UserNotificationData.NotificationKind,
	|	UserNotificationData.NotificationContext,
	|	UserNotificationData.RecordDate
	|FROM
	|	InformationRegister.UserNotificationData AS UserNotificationData
	|		INNER JOIN Catalog.UserNotificationKinds AS UserNotificationKinds
	|		ON UserNotificationData.NotificationKind = UserNotificationKinds.Ref
	|WHERE
	|	DATEADD(UserNotificationData.RecordDate, DAY, UserNotificationKinds.CacheRetentionPeriod) <= &CurrentDate
	|";
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	QueryBatch = Query.ExecuteBatch();
	Selection = QueryBatch[0].Select();
	While Selection.Next() Do
		//@skip-check query-in-loop
		DataOnTypeOfAlerts = DataOnNonOperationalTypeOfAlerts(Selection);
		ProcessNonOperationalNotificationOfUsers(DataOnTypeOfAlerts, Author);
	EndDo;
	
	DeleteNotificationData = QueryBatch[1].Unload();
	
	Try
		RecordSet = InformationRegisters.UserNotificationData.CreateRecordSet();
		RecordSet.Load(DeleteNotificationData);
		RecordSet.Write(ReplacementMode.Delete);
	Except
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Thực hiện nhiệm vụ';
							|ru = 'Оповещения пользователей.Выполнение заданий';
							|en = 'User notifications.Perform jobs'; fa = 'User notifications.Perform jobs';
							|it = 'User notifications.Perform jobs';
							|pl = 'User notifications.Perform jobs';
							|tr = 'Kullanıcı bildirimleri.Görevlerin gerçekleştirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Description of the types of user alerts.
// 
// Returns:
//	ValueTable - Description Of Types Of User Alerts:
//		* Id - String - unique identifier of the notification type.
//		* Description - String - name of the notification type.
//		* NotificationTypeGroup - See DescriptionOfGroupOfNotificationKinds.
//		* NotificationType - EnumRef.UserNotificationTypes - the type of user notification.
//		* Supplied - Boolean - indicates that the notification type is supplied.
//		* Changed - Boolean - indicates that the notification type has been changed relative to the one being delivered.
//		* NotificationTextTemplate - String - notification text template.
//		* CacheRetentionPeriod - Number - the storage period of the alert data cache.
//		* GroupingThreshold - Number - the threshold for grouping alerts.
//		* GroupedNotificationText - String - notification text generated for multiple entries.
//		* DCSTemplateName - String - the path to the DCS Template is in the metadata.
//		* DataCompositionSchema - ValueStorage - a value store with a data layout schema.
//		* StorageOfDataCompositionSettings - ValueStorage - value storage with data layout scheme settings.
//		* DataSources - Array of See NewDescriptionDataSource - data sources for notification.
Function DescriptionOfUserNotificationKinds() Export
	
	DescriptionOfNotificationKinds = New ValueTable();
	DescriptionOfNotificationKinds.Columns.Add("Id", New TypeDescription("String"));
	DescriptionOfNotificationKinds.Columns.Add("Description", New TypeDescription("String"));
	DescriptionOfNotificationKinds.Columns.Add("NotificationTypeGroup", New TypeDescription("Structure"));
	DescriptionOfNotificationKinds.Columns.Add("NotificationType", New TypeDescription("EnumRef.UserNotificationTypes"));
	DescriptionOfNotificationKinds.Columns.Add("Supplied", New TypeDescription("Boolean"));
	DescriptionOfNotificationKinds.Columns.Add("Changed", New TypeDescription("Boolean"));
	DescriptionOfNotificationKinds.Columns.Add("NotificationTextTemplate", New TypeDescription("String"));
	DescriptionOfNotificationKinds.Columns.Add("CacheRetentionPeriod", New TypeDescription("Number", 
		New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	DescriptionOfNotificationKinds.Columns.Add("GroupingThreshold", New TypeDescription("Number", 
		New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));	
	DescriptionOfNotificationKinds.Columns.Add("GroupedNotificationText", New TypeDescription("String"));
	DescriptionOfNotificationKinds.Columns.Add("DCSTemplateName", New TypeDescription("String"));
	DescriptionOfNotificationKinds.Columns.Add("DataCompositionSchema", New TypeDescription("ValueStorage"));
	DescriptionOfNotificationKinds.Columns.Add("StorageOfDataCompositionSettings", New TypeDescription("ValueStorage"));
	DescriptionOfNotificationKinds.Columns.Add("DataSources", New TypeDescription("Array"));
	
	DescriptionOfNotificationKinds.Indexes.Add("Id");
	Return DescriptionOfNotificationKinds;
EndFunction

// Adds a description of the type of user alerts with default values.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See DescriptionOfUserNotificationKinds
// 
// Returns:
//  ValueTableRow: See DescriptionOfUserNotificationKinds
//@skip-check function-return-types
Function AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds) Export
	
	NewTypeOfAlerts = DescriptionOfNotificationKinds.Add();
	NewTypeOfAlerts.NotificationType = Undefined;
	NewTypeOfAlerts.Supplied = True;
	NewTypeOfAlerts.Changed = False;
	NewTypeOfAlerts.CacheRetentionPeriod = 365;
	NewTypeOfAlerts.GroupingThreshold = 5;
	NewTypeOfAlerts.DCSTemplateName = NameOfPredefinedTemplate();
	NewTypeOfAlerts.DataSources = New Array;

	Return NewTypeOfAlerts;
	
EndFunction

// Adds a description of the data source of the type of user alerts.
//
// Parameters:
// 	TableRowDescriptionOfNotificationKinds - ValueTableRow: See DescriptionOfUserNotificationKinds - a row in the table with a description of the type of alert.
// 	FullSourceName - String - the data source for the notification in the form of objectmetadata.Fullname().
// 	AttributeName - String - the name of the main Attribute of the data source.
Procedure AddDescriptionOfDataSource(TableRowDescriptionOfNotificationKinds, FullSourceName, AttributeName = "") Export
	DataSource = NewDescriptionDataSource(FullSourceName, AttributeName);
	DataSources = TableRowDescriptionOfNotificationKinds.DataSources;
	DataSources.Add(DataSource);
EndProcedure

// Generates a description of the data source of the type of user alerts.
//
// Parameters:
// 	FullSourceName - String - the data source for the notification in the form of objectmetadata.Fullname().
// 	AttributeName - String - the name of the main Attribute of the data source.
// 
// Returns:
//  Structure - New description of the notification type data source:
// * SourceType - See Common.MetadataObjectID
// * SourceDetails_ - String - name of the notification type.
//
Function NewDescriptionDataSource(FullSourceName, AttributeName = "") Export
	
	NewDetails = New Structure;
	NewDetails.Insert("SourceType", Common.MetadataObjectID(FullSourceName));
	If AttributeName = "" Then
		AttributeName = "Ref";
		NameParts = StrSplit(FullSourceName, ".");
		HasRecorder = TypesThereIsRegistrar().Find(NameParts[0]);
		If HasRecorder <> Undefined Then
			AttributeName = "Recorder";
		EndIf;
	EndIf;
	NewDetails.Insert("SourceDetails_", AttributeName);
	
	//@skip-check constructor-function-return-section
	Return NewDetails;
	
EndFunction

// The handler of the routine task "Perform bot processing".
Procedure ProcessBots() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.BotsProcessing);
	
	CollaborationSystem.ProcessBots();
	
EndProcedure

#EndRegion

#Region Internal

// Performs tasks to notify users in turn of tasks.
//
// Parameters:
//	Jobs - ValueTable - the columns correspond to the dimensions, resources and Attributes of the Information Register:
//		* NotificationKind - CatalogRef.UserNotificationKinds - link to the type of notification
//		* RecordID - UUID - ID of the task queue entry
//		* RecordDate - Date - service column
//		* NotificationSource - AnyRef - link to the notification source
//		* NotificationInitiator - CatalogRef.Users - user initiator of the notification
//		* JobID - UUID - service column
//		* TaskDate_ - Date - official.
//	IdsOfUnprocessedRecords - Map of KeyAndValue:
//		* Key - UUID - ID of failed (giving an error) register entries.
//		* Value - String - Presentation of the error.
//	AdditionalProperties - Undefined, Structure - additional task completion properties.
//
Procedure CompleteTasksForNotifyingUsers(Jobs, IdsOfUnprocessedRecords, AdditionalProperties = Undefined) Export
	
	SetPrivilegedMode(True);
	Author = UserNotificationsOfEventsCached.UserNotificationAuthor();
	CheckPrepareConnectionToInteractionSystem(Author);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Jobs.NotificationKind AS NotificationKind,
	|	Jobs.RecordID AS RecordID,
	|	Jobs.RecordDate AS RecordDate,
	|	Jobs.NotificationSource AS NotificationSource,
	|	Jobs.NotificationInitiator AS NotificationInitiator,
	|	Jobs.JobID AS JobID,
	|	Jobs.TaskDate_ AS TaskDate_
	|INTO TTJobs
	|FROM
	|	&Jobs AS Jobs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Jobs.NotificationKind AS NotificationKind,
	|	Jobs.NotificationSource AS NotificationSource,
	|	MAX(Jobs.RecordID) AS RecordID,
	|	Jobs.NotificationInitiator AS NotificationInitiator,
	|	MIN(Jobs.TaskDate_) AS TaskDate_
	|FROM
	|	TTJobs AS Jobs
	|
	|GROUP BY
	|	Jobs.NotificationKind,
	|	Jobs.NotificationSource,
	|	Jobs.NotificationInitiator
	|
	|ORDER BY
	|	TaskDate_
	|TOTALS BY
	|	NotificationKind";

	Query.SetParameter("Jobs", Jobs);

	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	DataTableByType = InitializeSourceDataTable();
	
	SelectionTypeOfNotification = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectionTypeOfNotification.Next() Do
		Selection = SelectionTypeOfNotification.Select();
		While Selection.Next() Do
			NewRow = DataTableByType.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
		
		BeginTransaction();
		Try
			DataLock = New DataLock;
			
			LockItem = DataLock.Add("InformationRegister.UserNotificationData");
			LockItem.DataSource = DataTableByType;
			LockItem.UseFromDataSource("NotificationSource", "NotificationSource");
			LockItem.UseFromDataSource("NotificationKind", "NotificationKind");
			LockItem.Mode = DataLockMode.Exclusive;
			
			DataLock.Lock();
			
			//@skip-check query-in-loop
			DataOnTypeOfAlerts = DataOnOperationalTypeOfAlerts(SelectionTypeOfNotification.NotificationKind, DataTableByType);
			ProcessUserAlerts(DataOnTypeOfAlerts, Author, IdsOfUnprocessedRecords);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ErrorInfo = ErrorInfo();
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
			
			For Each ResultRow In DataTableByType Do
				If IdsOfUnprocessedRecords.Get(ResultRow.RecordID) = Undefined Then
					IdsOfUnprocessedRecords.Insert(ResultRow.RecordID, ErrorDescription);
				EndIf;
			EndDo;
			
			WriteLogEvent(NStr("ru = 'Оповещения пользователей.ВыполнитьЗаданияКОповещениюПользователей';
								|vi = 'User notifications.Complete user notification jobs';
								|en = 'User notifications.Complete user notification jobs'; fa = 'User notifications.Complete user notification jobs';
								|it = 'User notifications.Complete user notification jobs';
								|pl = 'User notifications.Complete user notification jobs';
								|tr = 'KullanıcıBildirimleri.KullanıcıBildirimGörevleriniYürüt'", 
				Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorDescription);
		EndTry;
		
		DataTableByType.Clear();
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Initializes the settings Composer.
// 
// Parameters:
//  SchemeAndSettingsForInitialization - DataCompositionSchema - Layout diagram for initializing settings.
//  Settings - Undefined, DataCompositionSettings - settings for initializing the Composer. 
//  	If not specified, the default settings are used.
// 
// Returns:
//  DataCompositionSettingsComposer - initialized settings Composer
Function InitializeSettingsComposer(SchemeAndSettingsForInitialization, Settings = Undefined) Export
	
	SettingsComposer = New DataCompositionSettingsComposer;
	If SchemeAndSettingsForInitialization = Undefined Then
		Return SettingsComposer
	EndIf;
	
	Try
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemeAndSettingsForInitialization));
	Except
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Kết nhập sơ đồ dàn dựng dữ liệu';
							|ru = 'Оповещения пользователей.Загрузка СКД';
							|en = 'User notifications.Import DCS'; fa = 'User notifications.Import DCS';
							|it = 'User notifications.Import DCS';
							|pl = 'User notifications.Import DCS';
							|tr = 'Kullanıcı bildirimleri.Veri oluşturma sisteminin yüklenmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If ValueIsFilled(Settings) Then
		SettingsComposer.LoadSettings(Settings);
	Else
		SettingsComposer.LoadSettings(SchemeAndSettingsForInitialization.DefaultSettings);
	EndIf;
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	Return SettingsComposer
	
EndFunction

// Allows you to check the correctness of the data acquisition scheme for generating operational alerts, correct errors if necessary,
// and also fill in a list of critical errors that the user will need to correct.
//
// Parameters:
//   DataCompositionSchema - DataCompositionSchema - The scheme of receiving these alerts.
//   SchemeContainsCriticalErrors - Boolean - a flag for critical errors that must
//   				be raised so that the user cannot apply the schema until the errors are fixed.
//   ListOfCriticalErrors - ValueList of String - A list containing the texts of critical error messages.
//   ListOfOtherMessages - ValueList of String - A list containing the texts of messages about fixed errors and other comments.
//   				This list of messages is displayed to the user once.
//
Procedure CheckingCorrectnessOfSchemeForReceivingDataOfOperationalTypeOfAlerts(DataCompositionSchema, SchemeContainsCriticalErrors,
					ListOfCriticalErrors, ListOfOtherMessages) Export
	
	RequiredFields = ReservedFieldNames(False);
	CheckingCorrectnessOfNotificationDataReceiptScheme(DataCompositionSchema, SchemeContainsCriticalErrors,
					ListOfCriticalErrors, ListOfOtherMessages, RequiredFields);
	
EndProcedure

// Allows you to check the correctness of the data acquisition scheme for generating non-operational alerts, correct errors if necessary,
// and also fill in the list of critical errors that the user will need to correct.
//
// Parameters:
//   DataCompositionSchema - DataCompositionSchema - The scheme of receiving these alerts.
//   SchemeContainsCriticalErrors - Boolean - a flag for critical errors that must
//   				be raised so that the user cannot apply the schema until the errors are fixed.
//   ListOfCriticalErrors - ValueList of String - A list containing the texts of critical error messages.
//   ListOfOtherMessages - ValueList of String - A list containing the texts of messages about fixed errors and other comments.
//   				This list of messages is displayed to the user once.
//
Procedure CheckingCorrectnessOfSchemeForReceivingDataOfNonOperationalTypeOfAlerts(DataCompositionSchema, SchemeContainsCriticalErrors,
					ListOfCriticalErrors, ListOfOtherMessages) Export
	
	RequiredFields = ReservedFieldNames(True);
	CheckingCorrectnessOfNotificationDataReceiptScheme(DataCompositionSchema, SchemeContainsCriticalErrors,
					ListOfCriticalErrors, ListOfOtherMessages, RequiredFields);
	
EndProcedure

// Checking the correctness of the data layout scheme before writing the Catalog.
// 
// Parameters:
//  TypeOfNotificationObject - CatalogObject.UserNotificationKinds - Type of notification object.
//  Cancel - Boolean - indicates that there is an error.
Procedure CheckingCorrectnessOfDataAcquisitionSchemeBeforeRecording(TypeOfNotificationObject, Cancel) Export
	
	DataCompositionSchema = TypeOfNotificationObject.DataCompositionSchema.Get();
	Settings = TypeOfNotificationObject.StorageOfDataCompositionSettings.Get();
	If DataCompositionSchema = Undefined Then
		DataCompositionSchema = TemplateByFullName(TypeOfNotificationObject.DCSTemplateName);
	EndIf;
	
	RequiredFields = ReservedFieldNames(TypeOfNotificationObject.NotificationType = Enums.UserNotificationTypes.NonOperational);
	ListOfCriticalErrors = New ValueList();
	ListOfOtherMessages = New ValueList();
	
	CheckingCorrectnessOfNotificationDataReceiptScheme(DataCompositionSchema, Cancel,
		ListOfCriticalErrors, ListOfOtherMessages, RequiredFields, Settings);
	If Cancel Then
		For Each CriticalError In ListOfCriticalErrors Do
			Common.MessageToUser(CriticalError.Value, 
				TypeOfNotificationObject, 
				"DataCompositionSchema");
		EndDo;
	EndIf;
	
EndProcedure

// Sets the message display mode for the transmitted discussion.
// 
// Parameters:
//  Conversation - CollaborationSystemConversationID - ID of the discussion.
//  DontDisturb - Boolean - indicates whether the "Do not disturb" notification display is set.
//  WatchMode - Undefined, Boolean -  If True, an alert is generated when new messages appear in the discussion. 
//  	If False, no alert is generated.
//  User - Undefined, CatalogRef.Users - user.
Procedure SetMessageDisplayMode(Conversation, DontDisturb, WatchMode = Undefined, User = Undefined) Export
	// Setting modes for a non-current user is only available in privileged mode.
	SetPrivilegedMode(True);
	
	NotificationRepresentation = CollaborationSystemNotificationRepresentation.Normal;
	If DontDisturb Then
		NotificationRepresentation = CollaborationSystemNotificationRepresentation.DontDisturb;
	EndIf;
	
	Try
		If User = Undefined Then
			User = CollaborationSystem.CurrentUserID();
		EndIf;
		CollaborationSystem.SetConversationNotificationRepresentation(Conversation, NotificationRepresentation, User);
		If ValueIsFilled(WatchMode) Then
			CollaborationSystem.SetWatchMode(Conversation, WatchMode, User);
		EndIf;
	Except
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Hệ thống tương tác';
							|ru = 'Оповещения пользователей.Система взаимодействия';
							|en = 'User notifications.Collaboration system'; fa = 'User notifications.Collaboration system';
							|it = 'User notifications.Collaboration system';
							|pl = 'User notifications.Collaboration system';
							|tr = 'Kullanıcı bildirimleri.Ortak çalışma sistemi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	SetPrivilegedMode(False);
EndProcedure

// Supported types of metadata for generating alerts.
// 
// Returns:
//  Array of See UserNotificationsOfEvents.DescriptionOfTypeOfMetadata - Supported Types Of Metadata
Function SupportedTypesOfMetadata() Export
	
	Array = New Array;
	
	Array.Add(DescriptionOfTypeOfMetadata("Catalogs", NStr("vi = 'Danh mục';
															|ru = 'Справочники';
															|en = 'Catalogs'; fa = 'فهرست‌ها';
															|it = 'Directory';
															|pl = 'Kartoteki';
															|tr = 'Kataloglar'")));
	Array.Add(DescriptionOfTypeOfMetadata("Documents", NStr("vi = 'Văn bản';
															|ru = 'Документы';
															|en = 'Documents'; fa = 'اسناد';
															|it = 'Documenti';
															|pl = 'Documents';
															|tr = 'Belgeler'")));
	Array.Add(DescriptionOfTypeOfMetadata("InformationRegisters", NStr("vi = 'Biểu ghi thông tin';
																		|ru = 'Регистры сведений';
																		|en = 'Information registers'; fa = 'ثبت‌های اطلاعاتی';
																		|it = 'Registri delle informazioni';
																		|pl = 'Rejestry informacji';
																		|tr = 'Bilgi kayıtları'")));
	Array.Add(DescriptionOfTypeOfMetadata("AccumulationRegisters", NStr("vi = 'Biểu ghi tích lũy';
																		|ru = 'Регистры накопления';
																		|en = 'Accumulation registers'; fa = 'ثبت‌های انباشتی';
																		|it = 'Registri di accumulo';
																		|pl = 'Rejestry kumulacji';
																		|tr = 'Birikim kayıtları'")));
	
	UserNotificationsOfEventsOverridable.AddSupportedTypesOfMetadata(Array);
	
	Return Array
	
EndFunction

// Description of the type of metadata.
// 
// Parameters:
//  Name - String - Name
//  Synonym - String - Synonym
// 
// Returns:
//  Structure - Description Of The Type Of Metadata:
// * Name - String - 
// * Synonym - String - 
Function DescriptionOfTypeOfMetadata(Name, Synonym) Export
	
	Structure = New Structure("Name, Synonym", Name, Synonym);
	Return Structure
	
EndFunction

// The name of the predefined template.
// 
// Returns:
//  String - Name of The Predefined Template
Function NameOfPredefinedTemplate() Export
	
	Return Metadata.Catalogs.UserNotificationKinds.Templates.Notifications_Predefined.FullName();
	
EndFunction

// There are changes.
// 
// Parameters:
//  Value1 - Arbitrary - Value1
//  Value2 - Arbitrary - Value2
// 
// Returns:
//  Boolean - There are changes
Function HasChanges(Value1, Value2) Export
	If Common.ValueToXMLString(Value1)
		<> Common.ValueToXMLString(Value2) Then
		
		Return True
		
	EndIf;
	
	Return False
	
EndFunction

// Defines the Index of the image.
// 
// Parameters:
//  FullName - String - full name of the metadata object.
// 
// Returns:
//  Number - The index of the image
Function PictureIndex(FullName) Export
	
	PictureIndex = 0;
	
	NameParts = StrSplit(FullName, ".");
	If NameParts.Count() > 0 Then
		IndexByType = IndexesOfImagesByType()[NameParts[0]];
		If IndexByType <> Undefined Then
			PictureIndex = IndexByType;
		EndIf;
	EndIf;
	
	Return PictureIndex
	
EndFunction

// Indexes of images by type.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String - type name
//   * Value - Number - index of the image.
Function IndexesOfImagesByType() Export
	Map = New Map;
	
	Map.Insert("Константа", 3); //@NON-NLS-1
	Map.Insert("Constant", 3); //@NON-NLS-1
	Map.Insert("Константы", 3); //@NON-NLS-1
	Map.Insert("Constants", 3); //@NON-NLS-1
	
	Map.Insert("Справочник", 4); //@NON-NLS-1
	Map.Insert("Catalog", 4); //@NON-NLS-1
	Map.Insert("Справочники", 4); //@NON-NLS-1
	Map.Insert("Catalogs", 4); //@NON-NLS-1
	
	Map.Insert("Документ", 5); //@NON-NLS-1
	Map.Insert("Document", 5); //@NON-NLS-1
	Map.Insert("Документы", 5); //@NON-NLS-1
	Map.Insert("Documents", 5); //@NON-NLS-1
	
	Map.Insert("ЖурналДокументов", 6); //@NON-NLS-1
	Map.Insert("DocumentJournal", 6); //@NON-NLS-1
	Map.Insert("ЖурналыДокументов", 6); //@NON-NLS-1
	Map.Insert("DocumentJournals", 6); //@NON-NLS-1
	
	Map.Insert("Перечисление", 7); //@NON-NLS-1
	Map.Insert("Enum", 7); //@NON-NLS-1
	Map.Insert("Перечисления", 7); //@NON-NLS-1
	Map.Insert("Enums", 7); //@NON-NLS-1
	
	Map.Insert("Отчет", 8); //@NON-NLS-1
	Map.Insert("Report", 8); //@NON-NLS-1
	Map.Insert("Отчеты", 8); //@NON-NLS-1
	Map.Insert("Reports", 8); //@NON-NLS-1
	
	Map.Insert("Обработка", 9); //@NON-NLS-1
	Map.Insert("DataProcessor", 10); //@NON-NLS-1
	Map.Insert("Обработки", 9); //@NON-NLS-1
	Map.Insert("DataProcessors", 10); //@NON-NLS-1
	
	Map.Insert("ПланВидовХарактеристик", 10); //@NON-NLS-1
	Map.Insert("ChartOfCharacteristicTypes", 10); //@NON-NLS-1
	Map.Insert("ПланыВидовХарактеристик", 10); //@NON-NLS-1
	Map.Insert("ChartsOfCharacteristicTypes", 10); //@NON-NLS-1
	
	Map.Insert("ПланСчетов", 11); //@NON-NLS-1
	Map.Insert("ChartOfAccounts", 11); //@NON-NLS-1
	Map.Insert("ПланыСчетов", 11); //@NON-NLS-1
	Map.Insert("ChartsOfAccounts", 11); //@NON-NLS-1
	
	Map.Insert("ПланВидовРасчета", 12); //@NON-NLS-1
	Map.Insert("ChartOfCalculationTypes", 12); //@NON-NLS-1
	Map.Insert("ПланыВидовРасчета", 12); //@NON-NLS-1
	Map.Insert("ChartsOfCalculationTypes", 12); //@NON-NLS-1
	
	Map.Insert("РегистрСведений", 13); //@NON-NLS-1
	Map.Insert("InformationRegister", 13); //@NON-NLS-1
	Map.Insert("РегистрыСведений", 13); //@NON-NLS-1
	Map.Insert("InformationRegisters", 13); //@NON-NLS-1
	
	Map.Insert("РегистрНакопления", 14); //@NON-NLS-1
	Map.Insert("AccumulationRegister", 14); //@NON-NLS-1
	Map.Insert("РегистрыНакопления", 14); //@NON-NLS-1
	Map.Insert("AccumulationRegisters", 14); //@NON-NLS-1
	
	Map.Insert("РегистрБухгалтерии", 15); //@NON-NLS-1
	Map.Insert("AccountingRegister", 15); //@NON-NLS-1
	Map.Insert("РегистрыБухгалтерии", 15); //@NON-NLS-1
	Map.Insert("AccountingRegisters", 15); //@NON-NLS-1
	
	Map.Insert("РегистрРасчета", 16); //@NON-NLS-1
	Map.Insert("CalculationRegister", 16); //@NON-NLS-1
	Map.Insert("РегистрыРасчета", 16); //@NON-NLS-1
	Map.Insert("CalculationRegisters", 16); //@NON-NLS-1
	
	Map.Insert("БизнесПроцесс", 17); //@NON-NLS-1
	Map.Insert("BusinessProcess", 17); //@NON-NLS-1
	Map.Insert("БизнесПроцессы", 17); //@NON-NLS-1
	Map.Insert("BusinessProcesses", 17); //@NON-NLS-1
	
	Map.Insert("Задача", 18); //@NON-NLS-1
	Map.Insert("Task", 18); //@NON-NLS-1
	Map.Insert("Задачи", 18); //@NON-NLS-1
	Map.Insert("Tasks", 18); //@NON-NLS-1
	
	Return Map
EndFunction

// Defines the standard Attribute of the data source.
// 
// Parameters:
//  MetadataObject - MetadataObject - the metadata object for which we get the Attribute name.
// 
// Returns:
//  String - The name of the props
Function StandardAttribute(MetadataObject) Export
	FullName = MetadataObject.FullName();
	AttributeName = "Ref";
	
	ArrayIsLogger = TypesThereIsRegistrar();
	
	ArrayInformationRegister = New Array;
	ArrayInformationRegister.Add("РегистрСведений"); //@NON-NLS-1
	ArrayInformationRegister.Add("InformationRegister"); //@NON-NLS-1
	
	NameParts = StrSplit(FullName, ".");
	If NameParts.Count() > 0 Then
		HasRecorder = ArrayIsLogger.Find(NameParts[0]);
		If HasRecorder <> Undefined Then
			AttributeName = "Recorder";
		EndIf;
		If ArrayInformationRegister.Find(NameParts[0]) <> Undefined Then
			If MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
				AttributeName = "";
				For Each Dimension In MetadataObject.Dimensions Do
					If Dimension.Master Then
						AttributeName = Dimension.Name;
						Break;
					EndIf;
				EndDo;
				If AttributeName = "" Then
					For Each Dimension In MetadataObject.Dimensions Do
						AttributeTypes = Dimension.Type.Types();
						IsReferenceType = False;
						For Each AttributeType In AttributeTypes Do
							IsReferenceType = Common.IsReference(AttributeType);
							If IsReferenceType Then
								AttributeName = Dimension.Name;
								Return AttributeName;
							EndIf;
						EndDo;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return AttributeName
	
EndFunction

// Sources of exception alerts.
// 
// Returns:
//  Array of String - Sources of Alerts Exceptions
Function SourcesOfNotificationExceptions() Export
	
	Exceptions = New Array();
	
	Exceptions.Add(Metadata.Catalogs.ExtensionsVersions.FullName());
	Exceptions.Add(Metadata.Catalogs.UserNotificationKinds.FullName());
	Exceptions.Add(Metadata.Catalogs.MetadataObjectIDs.FullName());
	Exceptions.Add(Metadata.Catalogs.ExtensionObjectIDs.FullName());
	Exceptions.Add(Metadata.Catalogs.AccessKeys.FullName());
	Exceptions.Add(Metadata.Catalogs.SetsOfAccessGroups.FullName());
	
	Exceptions.Add(Metadata.InformationRegisters.AccessValuesGroups.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessRightsDependencies.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessGroupsValues.FullName());
	Exceptions.Add(Metadata.InformationRegisters.DefaultAccessGroupsValues.FullName());
	Exceptions.Add(Metadata.InformationRegisters.ExtensionVersionObjectIDs.FullName());
	Exceptions.Add(Metadata.InformationRegisters.UserGroupsHierarchy.FullName());
	Exceptions.Add(Metadata.InformationRegisters.UsedAccessKinds.FullName());
	Exceptions.Add(Metadata.InformationRegisters.UsedAccessKindsByTables.FullName());
	Exceptions.Add(Metadata.InformationRegisters.ExternalUsersAccessKeys.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessGroupsAccessKeys.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessKeysForObjects.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessKeysForRegisters.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessGroupSetsAccessKeys.FullName());
	Exceptions.Add(Metadata.InformationRegisters.UsersAccessKeys.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessValuesSets.FullName());
	Exceptions.Add(Metadata.InformationRegisters.DataAccessKeysUpdate.FullName());
	Exceptions.Add(Metadata.InformationRegisters.UsersAccessKeysUpdate.FullName());
	Exceptions.Add(Metadata.InformationRegisters.UsersAccessKeysCurrentJobs.FullName());
	Exceptions.Add(Metadata.InformationRegisters.SentServerNotifications.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessRestrictionParameters.FullName());
	Exceptions.Add(Metadata.InformationRegisters.ExtensionVersionParameters.FullName());
	Exceptions.Add(Metadata.InformationRegisters.ApplicationRuntimeParameters.FullName());
	Exceptions.Add(Metadata.InformationRegisters.PeriodicServerNotifications.FullName());
	Exceptions.Add(Metadata.InformationRegisters.RolesRights.FullName());
	Exceptions.Add(Metadata.InformationRegisters.PredefinedExtensionsVersionsReportsOptions.FullName());
	Exceptions.Add(Metadata.InformationRegisters.UsersInfo.FullName());
	Exceptions.Add(Metadata.InformationRegisters.UserGroupCompositions.FullName());
	Exceptions.Add(Metadata.InformationRegisters.AccessGroupsTables.FullName());
	
	If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		Exceptions.Add("Catalog.JobsQueueHandlers");
		Exceptions.Add("Catalog.Catalogs.JobsQueue");
		Exceptions.Add("Catalog.Catalogs.QueueJobTemplates");
		
		Exceptions.Add("InformationRegister.ScheduledQueueJobs");
		Exceptions.Add("InformationRegister.RunningJobsQueueHandlers");
		Exceptions.Add("InformationRegister.HistoryOfStartsOfJobsInQueue");
	EndIf;

	UserNotificationsOfEventsOverridable.AddSourcesOfNotificationExceptions(Exceptions);
	
	Return Exceptions;
	
EndFunction

// Generates an array of objects with a description of the types of alerts.
// 
// Returns:
//  Array of String - Sources of Alerts Exceptions
Function ObjectsWithDescriptionsOfNotificationKinds() Export
	
	Array = New Array;
	
	UserNotificationsOfEventsOverridable.AddObjectsWithDescriptionOfTypesOfNotifications(Array);
	Return Array;
	
EndFunction

// Generates the correspondence of existing notification groups.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String - Sources of Alerts Exceptions
//   * Value - See DescriptionOfGroupOfNotificationKinds
Function GroupsOfNotificationKinds() Export
	
	GroupsOfNotificationKinds = New Map;
	
	UserNotificationsOfEventsOverridable.AddGroupsOfNotificationKinds(GroupsOfNotificationKinds);
	Return GroupsOfNotificationKinds;
	
EndFunction

// Description of a group of types of alerts.
// 
// Parameters:
//  Id - String - group ID
//  Description - String - Name of the group
//  GroupItIntoSeparateDiscussion - Boolean - indicates whether child types of notifications are grouped into a separate discussion
// 
// Returns:
//  Structure - Description Of A Group Of Types Of Alerts:
// * Id - String - group ID
// * Description - String - group ID
// * GroupItIntoSeparateDiscussion - Boolean - indicates whether child types of notifications are grouped into a separate discussion
Function DescriptionOfGroupOfNotificationKinds(Id, Description, GroupItIntoSeparateDiscussion = False) Export
	
	GroupDetails = New Structure();
	GroupDetails.Insert("Id", Id);
	GroupDetails.Insert("Description", Description);
	GroupDetails.Insert("GroupItIntoSeparateDiscussion", GroupItIntoSeparateDiscussion);

	Return GroupDetails
	
EndFunction

// Returns a description of the notification type group.
// 
// Parameters:
//  GroupKey - String - Group Key
// 
// Returns:
//  See DescriptionOfGroupOfNotificationKinds
Function NotificationTypeGroup(GroupKey) Export
	
	GroupsOfNotificationKinds = GroupsOfNotificationKinds();
	Group = GroupsOfNotificationKinds.Get(GroupKey);
	//@skip-check constructor-function-return-section
	Return Group;
	
EndFunction

// Description of the available types of user alerts.
// 
// Returns:
//  See DescriptionOfUserNotificationKinds
Function DescriptionOfAvailableUserNotificationKinds() Export
	
	DescriptionOfNotificationKinds = DescriptionOfUserNotificationKinds();
	
	ObjectsWithDescriptionsOfNotificationKinds = ObjectsWithDescriptionsOfNotificationKinds();
	For Each ObjectWithDescriptionOfTypesOfNotifications In ObjectsWithDescriptionsOfNotificationKinds Do
		If StrStartsWith(Upper(ObjectWithDescriptionOfTypesOfNotifications), "COMMONMODULE") Then
			RowsArray = StrSplit(ObjectWithDescriptionOfTypesOfNotifications, ".");
			MetadataObjectName1 = RowsArray[1];
			ObjectManager = Common.CommonModule(MetadataObjectName1);
		Else
			ObjectManager = Common.ObjectManagerByFullName(ObjectWithDescriptionOfTypesOfNotifications);
		EndIf;
		ObjectManager.OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds);
	EndDo;
	
	Return DescriptionOfNotificationKinds
EndFunction

// Returns a description of the type of user notifications by their ID.
// 
// Parameters:
//  NotificationID - String, UUID - Notification Id
// 
// Returns:
//  Undefined, ValueTableRow of See DescriptionOfUserNotificationKinds - Description of the type of user alerts
//@skip-check function-return-types
Function DescriptionOfTypeOfUserAlertsById(NotificationID) Export
	
	Result = Undefined;
	
	DescriptionOfNotificationKinds = DescriptionOfAvailableUserNotificationKinds();
	FoundRows = DescriptionOfNotificationKinds.FindRows(New Structure("Id", String(NotificationID)));
	If FoundRows.Count() > 0 Then
		Result = FoundRows[0];
	EndIf;
	
	Return Result;

EndFunction

// Fills in the Catalog elements of the types of user alerts.
// 
// Parameters:
//  Refill - Boolean - False if you only want to add new types of alerts,
//                            True if you want to re-fill all types of alerts.
Procedure FillInUserNotificationKinds(Refill=False) Export
	DescriptionOfNotificationKinds = DescriptionOfAvailableUserNotificationKinds();
	For Each DescriptionOfNotificationType In DescriptionOfNotificationKinds Do
		BeginTransaction();
		Try
			GroupTypeOfAlertsLink = Undefined;
			If ValueIsFilled(DescriptionOfNotificationType.NotificationTypeGroup) Then
				NewLinkGroup = Catalogs.UserNotificationKinds.GetRef(
					New UUID(DescriptionOfNotificationType.NotificationTypeGroup.Id));
				Block = New DataLock;
				LockItem = Block.Add("Catalog.UserNotificationKinds");
				LockItem.SetValue("Ref", NewLinkGroup);
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
				
				GroupTypeOfAlertsObject = NewLinkGroup.GetObject();
				If GroupTypeOfAlertsObject = Undefined Then
					GroupTypeOfAlertsObject = Catalogs.UserNotificationKinds.CreateFolder();
					GroupTypeOfAlertsObject.SetNewObjectRef(NewLinkGroup);
					GroupTypeOfAlertsObject.Description = DescriptionOfNotificationType.NotificationTypeGroup.Description;
					GroupTypeOfAlertsObject.GroupItIntoSeparateDiscussion = DescriptionOfNotificationType.NotificationTypeGroup.GroupItIntoSeparateDiscussion;
					InfobaseUpdate.WriteData(GroupTypeOfAlertsObject);
				ElsIf Refill Then
					GroupTypeOfAlertsObject.Description = DescriptionOfNotificationType.NotificationTypeGroup.Description;
					GroupTypeOfAlertsObject.GroupItIntoSeparateDiscussion = DescriptionOfNotificationType.NotificationTypeGroup.GroupItIntoSeparateDiscussion;
					InfobaseUpdate.WriteData(GroupTypeOfAlertsObject);
				EndIf;
				GroupTypeOfAlertsLink = GroupTypeOfAlertsObject.Ref;
			EndIf;
			
			RefToNew = Catalogs.UserNotificationKinds.GetRef(
				New UUID(DescriptionOfNotificationType.Id));
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.UserNotificationKinds");
			LockItem.SetValue("Ref", RefToNew);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			TypeOfAlertsObject = RefToNew.GetObject();
			If TypeOfAlertsObject = Undefined Then
				TypeOfAlertsObject = Catalogs.UserNotificationKinds.CreateItem();
				TypeOfAlertsObject.SetNewObjectRef(RefToNew);
			ElsIf Not Refill Then
				RollbackTransaction();
				Continue;
			EndIf;
			FillPropertyValues(TypeOfAlertsObject, DescriptionOfNotificationType,,"DataSources");
			TypeOfAlertsObject.Parent = GroupTypeOfAlertsLink;
			TypeOfAlertsObject.DataSources.Clear();
			For Each DataSource In DescriptionOfNotificationType.DataSources Do
				NewRow = TypeOfAlertsObject.DataSources.Add();
				If TypeOf(DataSource.SourceType) = Type("String") Then
					NewRow.SourceType = Common.MetadataObjectID(DataSource.SourceType);
				Else
					NewRow.SourceType = DataSource.SourceType;
				EndIf;
				NewRow.SourceDetails_ = DataSource.SourceDetails_;
			EndDo;
			InfobaseUpdate.WriteData(TypeOfAlertsObject);
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorInfo = ErrorInfo();
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
			WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Điền dạng thông báo';
								|ru = 'Оповещения пользователей.Заполнение видов оповещений';
								|en = 'User notifications.Fill notification kinds'; fa = 'User notifications.Fill notification kinds';
								|it = 'User notifications.Fill notification kinds';
								|pl = 'User notifications.Fill notification kinds';
								|tr = 'Kullanıcı bildirimleri.Bildirim türlerinin doldurulması'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorDescription);
		EndTry;
	EndDo;
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "UserNotificationsOfEvents.FillSeparatedDataHandlers";
	Handler.Version = "*";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	Handler.HandlerManagement = True;
	Handler.Comment = "";
	
	AddDataHandlerToUpgradeToNewVersion(Handlers);
	
EndProcedure

// Processes data to upgrade to the new version.
Procedure ProcessDataForMigrationToNewVersion() Export
	FillInUserNotificationKinds();
EndProcedure

// Fills in the split data handler that depends on changes to the undivided data.
//
// Parameters:
//   Parameters - Structure - structure of handler parameters:
//     * SeparatedHandlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	If Parameters <> Undefined Then
		Handlers = Parameters.SeparatedHandlers;
		AddDataHandlerToUpgradeToNewVersion(Handlers);
	EndIf;
	
EndProcedure

// Generates a service user to send alerts.
// 
// Returns:
//  Undefined, CatalogRef.Users - Service user
Function InternalUser() Export
	
	User = GetCreateServiceUser(InternalUsername(), 
		ServiceUserIdentifier());
	Return User;
	
EndFunction

// Creates a user of the interaction system to send alerts by the Bot.
// 
// Returns:
//  CollaborationSystemUser - Service user
Function CreateCollaborationSystemUserForBot() Export
	
	SetPrivilegedMode(True);
	
	BotUserName = BotUserName();
	
	FilterUsers = New CollaborationSystemUsersFilter;
	FilterUsers.Name = BotUserName;
	SVUsers = CollaborationSystem.GetUsers(FilterUsers);
	If SVUsers.Count() > 0 Then
		CollaborationSystemUser = SVUsers[0];
	Else
		CollaborationSystemUser = CollaborationSystem.CreateUser();
		CollaborationSystemUser.Name = BotUserName;
		CollaborationSystemUser.Write();
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return CollaborationSystemUser;
	
EndFunction

// The main Attributes of the type of alerts.
// 
// Returns:
//  Array of String - The main Attributes of the type of alerts.
Function MainAttributesOfTypeOfAlerts() Export
	Array = New Array;
	
	Array.Add("Description");
	Array.Add("NotificationType");
	Array.Add("NotificationTextTemplate");
	Array.Add("GroupedNotificationText");
	Array.Add("DCSTemplateName");
	
	Return Array;
EndFunction

// Gets the Template by the full Template name.
//
// Parameters:
//  FullName - String - the Template's full name, obtained using the platform's Fullname() method. 
// 
// Returns:
//  SpreadsheetDocument, TextDocument, DataCompositionSchema - Template by the full name of the Template.
//
Function TemplateByFullName(FullName) Export
	
	Template = Undefined;
	
	Metadata_Template = Metadata.FindByFullName(FullName);
	If Metadata_Template <> Undefined Then
		If Metadata.CommonTemplates.Contains(Metadata_Template) Then
			Template = GetCommonTemplate(Metadata_Template.Name);
		Else
			ObjectManager = Common.ObjectManagerByFullName(FullName);
			Template = ObjectManager.GetTemplate(Metadata_Template.Name);
		EndIf;
	EndIf;
	Return Template;
	
EndFunction

// Initializes the data table by the type of alert.
// 
// Returns:
//  ValueTable - Check The Correctness Of The Type Of User Alerts:
// * NotificationSource - AnyRef - 
// * NotificationContext - AnyRef - 
// * NotificationText1 - String, FormattedString -
// * NotificationRecipient - Array of CatalogRef.Users, CatalogRef.Users - 
// * RecipientOfNotificationAfterVerification - Array of CatalogRef.Users, CatalogRef.Users -
// * NotificationKind - CatalogRef.UserNotificationKinds - 
// * CacheOfKeyFields - ValueStorage - 
// * RecordDate - Date - 
// * TransitionCommand - See Conversations.DescriptionOfButton
// * IntegrationAddresses - Array of String -
// * AddressesOfMail - Array of String -
// * UserLanguageCode - String -
// * GroupItIntoSeparateDiscussion - Boolean - 
// * GroupHeader - String - 
// * GroupingID - String - 
Function InitializeTableDataByTypeOfNotification() Export
	
	TypesArrayString = New Array;
	TypesArrayString.Add(Type("String"));
	TypesArrayString.Add(Type("FormattedString"));
	
	ArrayOfRecipientTypes = New Array;
	ArrayOfRecipientTypes.Add(Type("Array"));
	ArrayOfRecipientTypes.Add(Type("CatalogRef.Users"));
	
	Table = New ValueTable;
	Table.Columns.Add("NotificationSource", Common.AllRefsTypeDetails());
	Table.Columns.Add("NotificationContext", Common.AllRefsTypeDetails());
	Table.Columns.Add("NotificationContextPresentation", New TypeDescription("String"));
	Table.Columns.Add("NotificationText1", New TypeDescription(TypesArrayString));
	Table.Columns.Add("NotificationRecipient", New TypeDescription(ArrayOfRecipientTypes));
	Table.Columns.Add("RecipientOfNotificationAfterVerification", New TypeDescription(ArrayOfRecipientTypes));
	Table.Columns.Add("NotificationKind", New TypeDescription("CatalogRef.UserNotificationKinds"));
	Table.Columns.Add("CacheOfKeyFields", New TypeDescription("ValueStorage"));
	Table.Columns.Add("RecordDate", New TypeDescription("Date",,,New DateQualifiers(DateFractions.DateTime)));
	Table.Columns.Add("TransitionCommand", New TypeDescription("Structure"));
	Table.Columns.Add("RecordID", New TypeDescription("UUID"));
	Table.Columns.Add("IntegrationAddresses", New TypeDescription("Array"));
	Table.Columns.Add("AddressesOfMail", New TypeDescription("Array"));
	Table.Columns.Add("UserLanguageCode", New TypeDescription("String"));
	Table.Columns.Add("GroupItIntoSeparateDiscussion", New TypeDescription("Boolean"));
	Table.Columns.Add("GroupHeader", New TypeDescription("String"));
	Table.Columns.Add("GroupingID", New TypeDescription("String"));
	
	Return Table
	
EndFunction

// Check the correctness of the type of user alerts.
// 
// Parameters:
//  NotificationKind - CatalogRef.UserNotificationKinds - a verifiable type of notification.
//  CheckMode - Boolean - if True, then the check is performed on the first 10 links, otherwise on all.
// 
// Returns:
//  See InitializeTableDataByTypeOfNotification
Function CheckCorrectnessOfTypeOfUserAlerts(NotificationKind, CheckMode = True) Export
	
	Cancel = False;
	ResultTable1 = InitializeTableDataByTypeOfNotification();
	
	TypeOfNotificationObject = NotificationKind.GetObject();
	If TypeOfNotificationObject = Undefined Then
		Return ResultTable1;
	EndIf;
	
	CheckingCorrectnessOfDataAcquisitionSchemeBeforeRecording(TypeOfNotificationObject, Cancel);
	If Cancel Then
		Return ResultTable1;
	EndIf;
	
	If TypeOfNotificationObject.DCSTemplateName = NameOfPredefinedTemplate() Then
		DCS = TypeOfNotificationObject.DataCompositionSchema.Get();
		If DCS = Undefined 
			Or Not HasChanges(DCS, TemplateByFullName(TypeOfNotificationObject.DCSTemplateName)) Then
			ErrorText = NStr("vi = 'Chưa tùy chỉnh truy vấn nhận dữ liệu thông báo.';
							|ru = 'Не настроен запрос получения данных оповещения.';
							|en = 'The request for notification data is not configured.'; fa = 'The request for notification data is not configured.';
							|it = 'The request for notification data is not configured.';
							|pl = 'The request for notification data is not configured.';
							|tr = 'Bildirim verilerini alma talebi yapılandırılmadı.'");
			Raise(ErrorText, ErrorCategory.DataCompositionSettingsError);
		EndIf;
	EndIf;
	If TypeOfNotificationObject.NotificationType = Enums.UserNotificationTypes.Nonexclusive Then
		SourceDataTable = InitializeSourceDataTable();
		ResultTable1 = DataOnOperationalTypeOfAlerts(NotificationKind, SourceDataTable, CheckMode);
	Else
		
		Query = New Query;
		Query.Text = "SELECT
		|	NotificationKinds.Ref AS Ref,
		|	NotificationKinds.NotificationTextTemplate,
		|	NotificationKinds.GroupingThreshold,
		|	NotificationKinds.GroupedNotificationText,
		|	NotificationKinds.DCSTemplateName,
		|	NotificationKinds.DataCompositionSchema,
		|	NotificationKinds.StorageOfDataCompositionSettings,
		|	ISNULL(NotificationKinds.Parent.GroupItIntoSeparateDiscussion, FALSE) AS GroupItIntoSeparateDiscussion,
		|	ISNULL(NotificationKinds.Parent.Description, """") AS GroupHeader,
		|	PRESENTATION(UUID(NotificationKinds.Parent)) AS GroupingID
		|FROM
		|	Catalog.UserNotificationKinds AS NotificationKinds
		|WHERE
		|	NotificationKinds.Ref = &Ref";
		
		Query.SetParameter("Ref", NotificationKind);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			ResultTable1 = DataOnNonOperationalTypeOfAlerts(Selection);
		EndIf;
	EndIf;
	
	Return ResultTable1
EndFunction

// See PropertyManagerOverridable.OnGetPredefinedPropertiesSets
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	
	Set = Sets.Rows.Add();
	Set.Name = "Catalog_UserNotificationKinds";
	Set.Id = New UUID("fc305419-3db3-4971-b4e5-c90826790356");
	Set.Used = GetFunctionalOption("UseUserNotificationsOfSystemEvents");
	
EndProcedure

// Checks and prepares the connection to the interaction system.
// 
// Parameters:
//  Author - Undefined, CatalogRef.Users - Author of alerts
Procedure CheckPrepareConnectionToInteractionSystem(Author = Undefined) Export
	
	BlockedForWorkingWithExternalResources = ScheduledJobsServer.OperationsWithExternalResourcesLocked();
	AccessToInternetServicesIsProhibited = Not Common.AccessToInternetServicesAllowed();
	
	If BlockedForWorkingWithExternalResources Then
		ErrorDescription = NStr("vi = 'Phong tỏa làm việc với nguồn ngoài';
								|ru = 'Заблокирована работа с внешними ресурсами.';
								|en = 'Operations with external resources are locked.'; fa = 'Operations with external resources are locked.';
								|it = 'Operations with external resources are locked.';
								|pl = 'Operations with external resources are locked.';
								|tr = 'Harici kaynaklarla çalışma kilitlendi.'");
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Thực hiện nhiệm vụ';
							|ru = 'Оповещения пользователей.Выполнение заданий';
							|en = 'User notifications.Perform jobs'; fa = 'User notifications.Perform jobs';
							|it = 'User notifications.Perform jobs';
							|pl = 'User notifications.Perform jobs';
							|tr = 'Kullanıcı bildirimleri.Görevlerin gerçekleştirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
		Raise ErrorDescription;
	ElsIf AccessToInternetServicesIsProhibited Then
		ErrorDescription = Common.AccessToInternetServicesDeniedMessageText();
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Thực hiện nhiệm vụ';
							|ru = 'Оповещения пользователей.Выполнение заданий';
							|en = 'User notifications.Perform jobs'; fa = 'User notifications.Perform jobs';
							|it = 'User notifications.Perform jobs';
							|pl = 'User notifications.Perform jobs';
							|tr = 'Kullanıcı bildirimleri.Görevlerin gerçekleştirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
		Raise ErrorDescription;
	EndIf;
	
	If Users.AuthorizedUser() = Users.UnspecifiedUserRef() Then
		UserIsNotificationAuthor = UserNotificationsOfEventsCached.UserIsNotificationAuthor(Author);
		CollaborationSystem.SetCurrentUser(UserIsNotificationAuthor);
	EndIf;
	
	If Not Conversations.CollaborationSystemConnected() Then
		ErrorDescription = NStr("vi = 'Thảo luận trong hệ thống tương tác hiện không khả dụng.';
								|ru = 'Обсуждения системы взаимодействия недоступны.';
								|en = 'Collaboration system conversations are unavailable.'; fa = 'Collaboration system conversations are unavailable.';
								|it = 'Collaboration system conversations are unavailable.';
								|pl = 'Collaboration system conversations are unavailable.';
								|tr = 'Ortak çalışma sistemi sohbeti mevcut değil.'");
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Thực hiện nhiệm vụ';
							|ru = 'Оповещения пользователей.Выполнение заданий';
							|en = 'User notifications.Perform jobs'; fa = 'User notifications.Perform jobs';
							|it = 'User notifications.Perform jobs';
							|pl = 'User notifications.Perform jobs';
							|tr = 'Kullanıcı bildirimleri.Görevlerin gerçekleştirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
		Raise ErrorDescription;
	EndIf;
	
	Try
		CollaborationSystem.GetExternalSystemTypes();
	Except
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Thực hiện nhiệm vụ';
							|ru = 'Оповещения пользователей.Выполнение заданий';
							|en = 'User notifications.Perform jobs'; fa = 'User notifications.Perform jobs';
							|it = 'User notifications.Perform jobs';
							|pl = 'User notifications.Perform jobs';
							|tr = 'Kullanıcı bildirimleri.Görevlerin gerçekleştirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
		Raise;
	EndTry;
EndProcedure

// Generates a new one, or returns an existing temporary code for connecting to telegram.
// 
// Parameters:
//  User - CatalogRef.Users - the user we are getting the code for.
// 
// Returns:
//  Structure - Temporary Code For Connecting To Telegram:
// * Code - String - code for connecting to telegram.
// * ValidityPeriod - Number - the universal date in milliseconds before which the code is valid.
// * ExpirationDateInSeconds - Number - The Balance of the code's validity time in seconds for output to the form.
Function TemporaryCodeForConnectingToTelegram(User) Export
	
	UserID_1 = "_" + StrReplace(XMLString(User),"-", "_"); // Must meet the requirements for identifiers.
	StorageData = Common.ReadDataFromSecureStorage(IdTelegramTemporaryCodes(),
		UserID_1);
	
	Result = New Structure("Code, ValidityPeriod, ExpirationDateInSeconds", "", 0, TelegramTemporaryCodeExpirationDate());
	If ValueIsFilled(StorageData) Then
		ExpirationDateInSeconds = (StorageData.ValidityPeriod - CurrentUniversalDateInMilliseconds())/1000;
		If ExpirationDateInSeconds > 0 Then
			Result.Code = StorageData.Code;
			Result.ValidityPeriod = StorageData.ValidityPeriod;
			Result.ExpirationDateInSeconds = ExpirationDateInSeconds;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Result.Code) Then
		PasswordGenerator = New RandomPasswordGenerator();
		Result.Code = PasswordGenerator.RandomPassword(TelegramTemporaryCodeLength(), True);
		Result.ValidityPeriod = CurrentUniversalDateInMilliseconds()+1000*Result.ExpirationDateInSeconds;
		StorageData = New Structure("Code, ValidityPeriod",
			Result.Code,
			Result.ValidityPeriod);
		Common.WriteDataToSecureStorage(IdTelegramTemporaryCodes(),
			StorageData,
			UserID_1);
	EndIf;
	
	Return Result;
	
EndFunction

//  The event handler for the message processing systeminteraction.
// 
// Parameters:
//  Message - CollaborationSystemMessage - message.
//  AdditionalParameters - Arbitrary - advanced setting.
Procedure CollaborationSystemMessageProcessing(Message, AdditionalParameters) Export
	SetPrivilegedMode(True);
	ConversationID = Message.Conversation;
	MessageText = String(Message.Text);
	
	NotificationMethod = NotificationMethodByDiscussion(ConversationID);
	If Not ValueIsFilled(NotificationMethod) Then
		Return;
	EndIf;
	
	Try
		BotID = CollaborationSystem.CurrentUserID();
		BotUser = CollaborationSystem.GetUser(BotID);
		NotificationAuthor = UserNotificationsOfEventsCached.UserNotificationAuthor();
		AuthorID = UserNotificationsOfEventsCached.CollaborationSystemUserIDNotificationsAuthor(NotificationAuthor);
	Except
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteLogEvent(NStr("ru = 'Оповещения пользователей.Обработка сообщения системы взаимодействия';
							|vi = 'User notifications.Processing Collaboration System message';
							|en = 'User notifications.Processing Collaboration System message'; fa = 'User notifications.Processing Collaboration System message';
							|it = 'User notifications.Processing Collaboration System message';
							|pl = 'User notifications.Processing Collaboration System message';
							|tr = 'Kullanıcı bildirimleri.Ortak çalışma sistemi mesajının işlenmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
		Return;
	EndTry;
	
	If Message.Author = AuthorID
		Or Message.Author = BotID Then
		Return;
	EndIf;
	SetPrivilegedMode(False);
	
	NumberOfRecentMessages = 10;
	FilterMessages_ = New CollaborationSystemMessagesFilter;
	FilterMessages_.Count = NumberOfRecentMessages;
	FilterMessages_.Conversation = ConversationID;
	FilterMessages_.After = Message.ID;
	FilterMessages_.SortDirection = SortDirection.Desc;
	
	RecentMessages = CollaborationSystem.GetMessages(FilterMessages_);
	If RecentMessages.Count() = NumberOfRecentMessages Then
		DateOfFirstMessage = '00010101';
		Iterator_SSLy = NumberOfRecentMessages;
		
		While Iterator_SSLy > 0 Do
			Iterator_SSLy = Iterator_SSLy-1;
			FirstMessage = RecentMessages[Iterator_SSLy];
			If FirstMessage.Author = Message.Author Then
				DateOfFirstMessage = FirstMessage.Date;
				Break;
			EndIf;
		EndDo;
		
		If (Message.Date - DateOfFirstMessage) < 60 Then
			Return; // If there were 10 messages in 1 minute, skip it.
		EndIf;
	EndIf;
	
	NotificationsRecipient = NotificationRecipientDataById(
		ConversationID,
		NotificationMethod);
	ThisIsNewDiscussion = Not ValueIsFilled(NotificationsRecipient);
	If ThisIsNewDiscussion Then
		
		If Not ThisIsTemporaryCode(MessageText) Then
			Try
				NameOfConfiguration = NameOfConfiguration();
				TextResponse = StrTemplate(NStr("ru = 'Для первоначальной настройки оповещений необходимо ввести временный код. 
					|Код можно получить в системе 1С:Предприятие ""%1"". ""НСИ и настройки"" - ""Персональные настройки"" - ""Оповещения пользователей""';
					|vi = 'To set up notifications for the first time, enter a temporary code. 
					|You can get the code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""';
					|en = 'To set up notifications for the first time, enter a temporary code. 
					|You can get the code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""'; fa = 'To set up notifications for the first time, enter a temporary code. 
					|You can get the code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""';
					|it = 'To set up notifications for the first time, enter a temporary code. 
					|You can get the code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""';
					|pl = 'To set up notifications for the first time, enter a temporary code. 
					|You can get the code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""';
					|tr = 'Bildirimleri ilk kez ayarlamak için geçici kod girmeniz gerekmektedir. 
					|Kod, ""%1"" 1C:Enterprise sisteminden edinilebilir. ""Master veri ve ayarlar""; ""Kişisel ayarlar""; ""Kullanıcı bildirimleri""'",
					Common.DefaultLanguageCode()), NameOfConfiguration);
				MessageDetails = Conversations.MessageDetails(TextResponse);
				Conversations.SendNotification(BotUser, MessageDetails, ConversationID);
			Except
				ErrorInfo = ErrorInfo();
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
				WriteLogEvent(NStr(
					"ru = 'Оповещения пользователей.Обработка сообщения системы взаимодействия';
					|vi = 'User notifications.Processing Collaboration System message';
					|en = 'User notifications.Processing Collaboration System message'; fa = 'User notifications.Processing Collaboration System message';
					|it = 'User notifications.Processing Collaboration System message';
					|pl = 'User notifications.Processing Collaboration System message';
					|tr = 'Kullanıcı bildirimleri.Ortak çalışma sistemi mesajının işlenmesi'",
					Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
			EndTry;
			
			Return
			
		EndIf;
		
		UserByTemporaryCode = UserByTelegramTemporaryCode(MessageText);
		If UserByTemporaryCode = Undefined Then
			Try
				If Not ValueIsFilled(NameOfConfiguration) Then
					NameOfConfiguration = NameOfConfiguration();
				EndIf;
				TextResponse = StrTemplate(NStr("ru = 'Указанный код не существует, либо у него истек срок действия.
					|Получите новый код в системе 1С:Предприятие ""%1"". ""НСИ и настройки"" - ""Персональные настройки"" - ""Оповещения пользователей""';
					|vi = 'The specified code does not exist or has expired.
					|Get a new code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""';
					|en = 'The specified code does not exist or has expired.
					|Get a new code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""'; fa = 'The specified code does not exist or has expired.
					|Get a new code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""';
					|it = 'The specified code does not exist or has expired.
					|Get a new code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""';
					|pl = 'The specified code does not exist or has expired.
					|Get a new code in the ""%1"" 1C:Enterprise system. ""Master data and settings"" - ""Personal settings"" - ""User notifications""';
					|tr = 'Belirtilen kod mevcut değil veya süresi dolmuş.
					|""%1"" 1C:Enterprise sisteminden yeni bir kod alın. ""Master veri ve ayarlar""; ""Kişisel ayarlar""; ""Kullanıcı bildirimleri""'",
					Common.DefaultLanguageCode()), NameOfConfiguration);
				MessageDetails = Conversations.MessageDetails(TextResponse);
				Conversations.SendNotification(BotUser, MessageDetails, ConversationID);
			Except
				ErrorInfo = ErrorInfo();
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
				WriteLogEvent(NStr(
					"ru = 'Оповещения пользователей.Обработка сообщения системы взаимодействия';
					|vi = 'User notifications.Processing Collaboration System message';
					|en = 'User notifications.Processing Collaboration System message'; fa = 'User notifications.Processing Collaboration System message';
					|it = 'User notifications.Processing Collaboration System message';
					|pl = 'User notifications.Processing Collaboration System message';
					|tr = 'Kullanıcı bildirimleri.Ortak çalışma sistemi mesajının işlenmesi'",
					Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
			EndTry;
		Else
			RecordMatchedMessengerUser(UserByTemporaryCode, ConversationID, NotificationMethod);
			Try
				TextNotificationsAreEnabled = NStr("ru = 'Оповещения в Telegram успешно подключены.';
													|vi = 'Telegram notifications are successfully enabled.';
													|en = 'Telegram notifications are successfully enabled.'; fa = 'Telegram notifications are successfully enabled.';
													|it = 'Telegram notifications are successfully enabled.';
													|pl = 'Telegram notifications are successfully enabled.';
													|tr = 'Telegram bildirimleri başarıyla etkinleştirildi.'", Common.DefaultLanguageCode());
				
				MessageDetails = Conversations.MessageDetails(TextNotificationsAreEnabled);
				
				ArrayOfRecipients_ = New Array;
				ArrayOfRecipients_.Add(UserByTemporaryCode);
				
				Conversations.SendMessage(NotificationAuthor, ArrayOfRecipients_, MessageDetails);
				Conversations.SendNotification(BotUser, MessageDetails, ConversationID);
				ClientNotifications.SendNotification("ConnectingTelegramUser", New Structure("User", UserByTemporaryCode));
			Except
				ErrorInfo = ErrorInfo();
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
				WriteLogEvent(NStr(
					"ru = 'Оповещения пользователей.Обработка сообщения системы взаимодействия';
					|vi = 'User notifications.Processing Collaboration System message';
					|en = 'User notifications.Processing Collaboration System message'; fa = 'User notifications.Processing Collaboration System message';
					|it = 'User notifications.Processing Collaboration System message';
					|pl = 'User notifications.Processing Collaboration System message';
					|tr = 'Kullanıcı bildirimleri.Ortak çalışma sistemi mesajının işlenmesi'",
					Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
			EndTry;
		EndIf;
	Else
		Try
			MessageDetails = Conversations.MessageDetails(NStr("ru = 'Оповещения в Telegram уже были подключены ранее.';
																|vi = 'Telegram notifications are already enabled.';
																|en = 'Telegram notifications are already enabled.'; fa = 'Telegram notifications are already enabled.';
																|it = 'Telegram notifications are already enabled.';
																|pl = 'Telegram notifications are already enabled.';
																|tr = 'Telegram bildirimleri daha önce zaten etkinleştirildi.'", 
				Common.DefaultLanguageCode()));
			Conversations.SendNotification(BotUser, MessageDetails, ConversationID);
		Except
			ErrorInfo = ErrorInfo();
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
			WriteLogEvent(NStr(
				"ru = 'Оповещения пользователей.Обработка сообщения системы взаимодействия';
				|vi = 'User notifications.Processing Collaboration System message';
				|en = 'User notifications.Processing Collaboration System message'; fa = 'User notifications.Processing Collaboration System message';
				|it = 'User notifications.Processing Collaboration System message';
				|pl = 'User notifications.Processing Collaboration System message';
				|tr = 'Kullanıcı bildirimleri.Ortak çalışma sistemi mesajının işlenmesi'",
				Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
		EndTry;
	EndIf;
	
EndProcedure

// Receives or creates a bot of the interaction system.
// 
// Returns:
//  CollaborationSystemBot, Undefined - interaction system bot
Function GetCreateCollaborationSystem() Export
	
	If Not (GetFunctionalOption("UseUserNotificationsOfSystemEvents")
		And GetFunctionalOption("UseUserNotificationsViaTelegram")
		And Conversations.CollaborationSystemConnected()) Then
		Raise NStr("ru = 'Бот системы взаимодействия не может быть создан.';
					|vi = 'Cannot create a Collaboration System bot.';
					|en = 'Cannot create a Collaboration System bot.'; fa = 'Cannot create a Collaboration System bot.';
					|it = 'Cannot create a Collaboration System bot.';
					|pl = 'Cannot create a Collaboration System bot.';
					|tr = 'Ortak çalışma sistemi botu oluşturulamaz.'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	FoundBots = FindBots();
	
	If FoundBots.Count() = 0 Then
		Bot = CollaborationSystem.CreateBot();
		Bot.User = CreateCollaborationSystemUserForBot().ID;
		Bot.Metadata = Metadata.Bots.UserNotificationsOfEvents;
		Try
			Bot.Write();
		Except
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
				NStr("ru = 'Не удалось создать бота системы взаимодействия по причине:';
					|vi = 'Cannot create a Collaboration System bot. Reason:';
					|en = 'Cannot create a Collaboration System bot. Reason:'; fa = 'Cannot create a Collaboration System bot. Reason:';
					|it = 'Cannot create a Collaboration System bot. Reason:';
					|pl = 'Cannot create a Collaboration System bot. Reason:';
					|tr = 'Ortak çalışma sistemi botu şu nedenle oluşturulamadı:'"), True);
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		EndTry;
	Else
		Bot = FoundBots[0];
	EndIf;
	
	If Not Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		Filter = New Structure();
		Filter.Insert("Metadata", Metadata.ScheduledJobs.BotsProcessing);
		Jobs = ScheduledJobsServer.FindJobs(Filter);
		If Jobs.Count() = 1 Then
			If Not Jobs[0].Use Then
				Parameters = New Structure();
				Parameters.Insert("Use", True);
				ScheduledJobsServer.ChangeJob(Jobs[0].UUID, Parameters);
			EndIf;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return Bot;
	
EndFunction

// Removes existing interaction system bots.
Procedure DeleteCollaborationSystemBots() Export
	
	SetPrivilegedMode(True);
	
	FoundBots = FindBots();
	For Each Bot In FoundBots Do
		Try
			If Bot <> Undefined Then
				Bot.Delete();
			EndIf;
		Except
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
				NStr("ru = 'Не удалось удалить бота системы взаимодействия по причине:';
					|vi = 'Cannot delete a Collaboration System bot. Reason:';
					|en = 'Cannot delete a Collaboration System bot. Reason:'; fa = 'Cannot delete a Collaboration System bot. Reason:';
					|it = 'Cannot delete a Collaboration System bot. Reason:';
					|pl = 'Cannot delete a Collaboration System bot. Reason:';
					|tr = 'Ortak çalışma sistemi botu şu nedenle silinemedi:'"), True);
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		EndTry;
	EndDo;
	
	If Not Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		Filter = New Structure();
		Filter.Insert("Metadata", Metadata.ScheduledJobs.BotsProcessing);
		Jobs = ScheduledJobsServer.FindJobs(Filter);
		If Jobs.Count() = 1 Then
			If Jobs[0].Use Then
				Parameters = New Structure();
				Parameters.Insert("Use", False);
				ScheduledJobsServer.ChangeJob(Jobs[0].UUID, Parameters);
			EndIf;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Find an existing integration.
// 
// Parameters:
//  Var_Key - CollaborationSystemIntegrationID - Integration ID
// 
// Returns:
//  CollaborationSystemIntegration, Undefined - Found integration
Function FindExistingIntegration(Var_Key) Export
	
	Try
		IntegrationDetails = CollaborationSystem.GetIntegration(Var_Key);
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("ru = 'Не удалось получить существующую интеграцию по причине:';
				|vi = 'Cannot receive an existing integration. Reason:';
				|en = 'Cannot receive an existing integration. Reason:'; fa = 'Cannot receive an existing integration. Reason:';
				|it = 'Cannot receive an existing integration. Reason:';
				|pl = 'Cannot receive an existing integration. Reason:';
				|tr = 'Mevcut entegrasyon şu nedenle alınamadı:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
	Return IntegrationDetails
	
EndFunction

// Integration settings by notification recipient.
// 
// Parameters:
//  User - Undefined, CatalogRef.Users - The user for whom the settings are obtained.
// 
// Returns:
//  Structure - Settings By Notification Recipient:
// * ShouldNotifyByEmail - Boolean - 
// * NotifyViaTelegram - Boolean - 
Function SettingsByNotificationRecipient(User = Undefined) Export
	
	If Not ValueIsFilled(User) Then
		User = Users.AuthorizedUser();
	EndIf;
	
	Result = New Structure;
	Result.Insert("ShouldNotifyByEmail", False);
	Result.Insert("NotifyViaTelegram", False);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	NotificationsRecipients.NotificationMethod AS NotificationMethod,
	|	MAX(NotificationsRecipients.Use) AS Use
	|FROM
	|	InformationRegister.UserNotificationsRecipients AS NotificationsRecipients
	|WHERE
	|	NotificationsRecipients.User = &User
	|GROUP BY
	|	NotificationsRecipients.NotificationMethod";
	Query.SetParameter("User", User);
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		If Selection.NotificationMethod = Enums.UserNotificationsMethods.Telegram Then
			Result.NotifyViaTelegram = Selection.Use;
		ElsIf Selection.NotificationMethod = Enums.UserNotificationsMethods.Email Then
			Result.ShouldNotifyByEmail = Selection.Use;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Save user notification integration settings.
// 
// Parameters:
//  Users - Array of CatalogRef.Users, CatalogRef.Users - users for whom the settings are being changed.
//  NotificationMethods - Array of EnumRef.UserNotificationsMethods, EnumRef.UserNotificationsMethods - Notification methods.
//  Use - Boolean - indicates whether the setting is on/off.
Procedure SaveUserNotificationSettings(Val Users, Val NotificationMethods, Use) Export
	
	If TypeOf(Users) <> Type("Array") Then
		Users = CommonClientServer.ValueInArray(Users);
	EndIf;
	
	If TypeOf(NotificationMethods) <> Type("Array") Then
		NotificationMethods = CommonClientServer.ValueInArray(NotificationMethods);
	EndIf;
	
	RecordsTable = New ValueTable();
	RecordsTable.Columns.Add("User", New TypeDescription("CatalogRef.Users"));
	RecordsTable.Columns.Add("NotificationMethod", New TypeDescription("EnumRef.UserNotificationsMethods"));
	For Each User In Users Do
		For Each NotificationMethod In NotificationMethods Do
			NewRow = RecordsTable.Add();
			NewRow.User = User;
			NewRow.NotificationMethod = NotificationMethod;
		EndDo;
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Table.User AS User,
	|	Table.NotificationMethod AS NotificationMethod
	|INTO
	|	TTTableOfRecords
	|FROM
	|	&RecordsTable AS Table;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RecordsTable.User AS User,
	|	ISNULL(NotificationsRecipients.NotificationAddress, """") AS NotificationAddress,
	|	RecordsTable.NotificationMethod AS NotificationMethod,
	|	&Use AS Use
	|FROM
	|	TTTableOfRecords AS RecordsTable
	|		LEFT JOIN InformationRegister.UserNotificationsRecipients AS NotificationsRecipients
	|		ON RecordsTable.User = NotificationsRecipients.User
	|			AND RecordsTable.NotificationMethod = NotificationsRecipients.NotificationMethod";
	
	Query.SetParameter("Use", Use);
	Query.SetParameter("RecordsTable", RecordsTable);
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UserNotificationsRecipients");
	LockItem.DataSource = RecordsTable;
	LockItem.UseFromDataSource("User", "User");
	LockItem.UseFromDataSource("NotificationMethod", "NotificationMethod");
	
	BeginTransaction();
	Try
		Block.Lock();
		Result = Query.Execute().Unload();
	
		RecordSet = InformationRegisters.UserNotificationsRecipients.CreateRecordSet();
		RecordSet.Load(Result);
		RecordSet.Write(ReplacementMode.Merge);
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("ru = 'Не удалось записать настройки оповещений по причине:';
				|vi = 'Cannot save the notification settings. Reason:';
				|en = 'Cannot save the notification settings. Reason:'; fa = 'Cannot save the notification settings. Reason:';
				|it = 'Cannot save the notification settings. Reason:';
				|pl = 'Cannot save the notification settings. Reason:';
				|tr = 'Bildirim ayarları şu nedenle kaydedilemedi:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	SetPrivilegedMode(False);
EndProcedure

// Records the comparison of the messenger user and the user of the information base.
// 
// Parameters:
//  User - CatalogRef.Users - User
//  ConversationID - CollaborationSystemConversationID - Discussion ID
//  NotificationMethod - Undefined, EnumRef.UserNotificationsMethods - Notification method
Procedure RecordMatchedMessengerUser(User, Val ConversationID, NotificationMethod = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(ConversationID) <> Type("String") Then
		ConversationID = String(ConversationID);
	EndIf;
	
	Try
		RecordSet = InformationRegisters.UserNotificationsRecipients.CreateRecordSet();
		RecordSet.Filter.User.Set(User);
		RecordSet.Filter.NotificationMethod.Set(NotificationMethod);
		RecordSet.DataExchange.Load = True;
		
		NewRecord = RecordSet.Add();
		NewRecord.User = User;
		NewRecord.NotificationMethod = NotificationMethod;
		NewRecord.NotificationAddress = ConversationID;
		NewRecord.Use = True;
		RecordSet.Write(ReplacementMode.Replace);
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteLogEvent(NStr("ru = 'Оповещения пользователей.Сопоставление пользователей';
							|vi = 'User notifications.Mapping users';
							|en = 'User notifications.Mapping users'; fa = 'User notifications.Mapping users';
							|it = 'User notifications.Mapping users';
							|pl = 'User notifications.Mapping users';
							|tr = 'Kullanıcı bildirimleri.Kullanıcıların eşleştirilmesi'", 
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Deletes user notification integration settings.
// 
// Parameters:
//  NotificationMethods - Array of EnumRef.UserNotificationsMethods, EnumRef.UserNotificationsMethods - Notification methods.
//  Users - Array of CatalogRef.Users, CatalogRef.Users - users for whom the settings are being changed.
Procedure ClearSettingsForNotificationRecipients(Val NotificationMethods, Val Users = Undefined) Export
	
	If ValueIsFilled(Users) And TypeOf(Users) <> Type("Array") Then
		Users = CommonClientServer.ValueInArray(Users);
	EndIf;
	
	If TypeOf(NotificationMethods) <> Type("Array") Then
		NotificationMethods = CommonClientServer.ValueInArray(NotificationMethods);
	EndIf;
	
	RecordsTable = New ValueTable();
	RecordsTable.Columns.Add("User", New TypeDescription("CatalogRef.Users"));
	RecordsTable.Columns.Add("NotificationMethod", New TypeDescription("EnumRef.UserNotificationsMethods"));
	For Each NotificationMethod In NotificationMethods Do
		If ValueIsFilled(Users) Then
			For Each User In Users Do
				NewRow = RecordsTable.Add();
				NewRow.User = User;
				NewRow.NotificationMethod = NotificationMethod;
			EndDo;
		Else
			NewRow = RecordsTable.Add();
			NewRow.NotificationMethod = NotificationMethod;
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	|	NotificationsRecipients.User AS User,
	|	NotificationsRecipients.NotificationAddress AS NotificationAddress,
	|	NotificationsRecipients.NotificationMethod AS NotificationMethod,
	|	NotificationsRecipients.Use AS Use
	|FROM
	|	InformationRegister.UserNotificationsRecipients AS NotificationsRecipients
	|WHERE
	|	NotificationsRecipients.NotificationMethod IN(&NotificationMethods)
	|	AND CASE
	|			WHEN &FilterByUser
	|				THEN NotificationsRecipients.User IN (&Users)
	|			ELSE TRUE
	|		END";
	
	Query.SetParameter("NotificationMethods", NotificationMethods);
	Query.SetParameter("FilterByUser", ValueIsFilled(Users));
	Query.SetParameter("Users", Users);
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UserNotificationsRecipients");
	LockItem.DataSource = RecordsTable;
	LockItem.UseFromDataSource("NotificationMethod", "NotificationMethod");
	If ValueIsFilled(Users) Then
		LockItem.UseFromDataSource("User", "User");
	EndIf;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		RecordsToDelete = Query.Execute().Unload();
		
		RecordSet = InformationRegisters.UserNotificationsRecipients.CreateRecordSet();
		RecordSet.Load(RecordsToDelete);
		RecordSet.Write(ReplacementMode.Delete);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("ru = 'Не удалось записать настройки оповещений по причине:';
				|vi = 'Cannot save the notification settings. Reason:';
				|en = 'Cannot save the notification settings. Reason:'; fa = 'Cannot save the notification settings. Reason:';
				|it = 'Cannot save the notification settings. Reason:';
				|pl = 'Cannot save the notification settings. Reason:';
				|tr = 'Bildirim ayarları şu nedenle kaydedilemedi:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// The address of the notification by user.
// 
// Parameters:
//  User - CatalogRef.Users - User
//  NotificationMethod - EnumRef.UserNotificationsMethods -Notification method
// 
// Returns:
//  String - The address of the user's notification.
Function NotificationAddressByUser(User, NotificationMethod) Export
	
	Query = New Query;
	Query.Text = "
		|SELECT TOP 1
		|	NotificationsRecipients.NotificationAddress AS NotificationAddress
		|FROM
		|	InformationRegister.UserNotificationsRecipients AS NotificationsRecipients
		|WHERE
		|	NotificationsRecipients.User = &User
		|	AND NotificationsRecipients.NotificationMethod = &NotificationMethod
		|	AND NotificationsRecipients.Use
		|	AND NOT NotificationsRecipients.NotificationAddress LIKE """"";
	Query.SetParameter("User", User);
	Query.SetParameter("NotificationMethod", NotificationMethod);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	Result = "";
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		Result = Selection.NotificationAddress;
	EndIf;
	
	Return Selection
	
EndFunction

// Creates or modifies integration in the interaction system based on the passed parameters.
//
// Parameters:
//   Parameters - Structure - contains parameters for creating or modifying integration:
//     * Id - UUID - integration ID, if not specified, a new integration is being created
//     * Type - String - Type of external system
//     * Key - String - integration key
//     * Attendees - Array of CollaborationSystemUserID - list of integration participants
//
// Returns:
//   CollaborationSystemIntegration - integration created or modified
Function CreateChangeIntegration(Parameters) Export

	Id = CommonClientServer.StructureProperty(Parameters, "Id");
	If Id <> Undefined Then
		NewIntegration = CollaborationSystem.GetIntegration(Id);
	Else
		NewIntegration = CollaborationSystem.CreateIntegration();
	EndIf;
	
	NewIntegration.ExternalSystemType = Parameters.Type;
	NewIntegration.Presentation = Parameters.Key;
	NewIntegration.Key = Parameters.Key;
	NewIntegration.Use = True;
	ExternalSystemDetails = CollaborationSystem.GetExternalSystemDescription(Parameters.Type);
	
	NotGivenParameters = New Array;
	For Each IntegrationParameter In ExternalSystemDetails.ParametersDescriptions Do
		If Not Parameters.Property(IntegrationParameter.Name) Then
			If IntegrationParameter.Required Then
				NotGivenParameters.Add(IntegrationParameter.Name);
			EndIf;
		Else
			NewIntegration.ExternalSystemParameters.Insert(IntegrationParameter.Name, Parameters[IntegrationParameter.Name]);
		EndIf;
	EndDo;
	
	If NotGivenParameters.Count() > 0 Then
		Raise NStr("vi = 'Chưa điền tham số tích hợp: 
			|%1';
			|ru = 'Не заполнены параметры интеграции: 
			|%1';
			|en = 'Integration parameters are not specified:
			|%1'; fa = 'Integration parameters are not specified:
			|%1';
			|it = 'Non sono stati compilati i parametri di integrazione: 
			|%1';
			|pl = 'Nie wypełniono parametrów integracji: 
			|%1';
			|tr = 'Entegrasyon parametreleri doldurulmadı:
			|%1'", StrConcat(NotGivenParameters, Chars.LF + "- "));
	EndIf;
	
	NewIntegration.Members.Clear();
	For Each Member In Parameters.Attendees Do
		NewIntegration.Members.Add(Member);
	EndDo;
	
	NewIntegration.Write();
	
	Return NewIntegration;
	
EndFunction

#EndRegion

#Region Private

//@skip-check bsl-nstr-string-literal-format
Function DataOnOperationalTypeOfAlerts(NotificationKind, SourceDataTable, CheckMode = False)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DataTable.NotificationSource AS NotificationSource,
	|	DataTable.NotificationInitiator AS NotificationInitiator,
	|	DataTable.RecordID AS RecordID,
	|	CAST(&NotificationKind AS Catalog.UserNotificationKinds) AS NotificationKind
	|INTO TTData
	|FROM
	|	&DataTable AS DataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TypesOfNotification.Ref AS NotificationKind,
	|	TypesOfNotification.NotificationTextTemplate AS NotificationTextTemplate,
	|	TypesOfNotification.DCSTemplateName AS DCSTemplateName,
	|	TypesOfNotification.DataCompositionSchema AS DataCompositionSchema,
	|	TypesOfNotification.StorageOfDataCompositionSettings AS StorageOfDataCompositionSettings,
	|	ISNULL(TypesOfNotification.Parent.GroupItIntoSeparateDiscussion, FALSE) AS GroupItIntoSeparateDiscussion,
	|	ISNULL(TypesOfNotification.Parent.Description, """") AS GroupHeader,
	|	PRESENTATION(UUID(TypesOfNotification.Parent)) AS GroupingID
	|FROM
	|	Catalog.UserNotificationKinds AS TypesOfNotification
	|WHERE
	|	TypesOfNotification.Ref = &NotificationKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataSource_.NotificationSource AS NotificationSource,
	|	DataSource_.NotificationKind AS NotificationKind,
	|	DataSource_.NotificationKind.NotificationTextTemplate AS NotificationText1,
	|	DataSource_.NotificationInitiator AS NotificationInitiator,
	|	DataSource_.RecordID AS RecordID,
	|	NotificationsData.NotificationContext AS NotificationContext,
	|	NotificationsData.CacheOfKeyFields AS CacheOfKeyFields
	|FROM
	|	TTData AS DataSource_
	|		LEFT JOIN InformationRegister.UserNotificationData AS NotificationsData
	|		ON NotificationsData.NotificationSource = DataSource_.NotificationSource
	|			AND NotificationsData.NotificationKind = DataSource_.NotificationKind
	|;
	|";
	Query.SetParameter("DataTable", SourceDataTable);
	Query.SetParameter("NotificationKind", NotificationKind);
	QueryBatch = Query.ExecuteBatch();
	
	SelectionTypeOfNotification = QueryBatch[1].Select();
	DCSResult = Undefined;
	NotificationTextTemplate = "";
	GroupingParameters = Undefined;
	DataTable = InitializeTableDataByTypeOfNotification();
	
	If SelectionTypeOfNotification.Next() Then
		DCSResult = InitializeDataLayoutScheme(SelectionTypeOfNotification, 
			SourceDataTable.UnloadColumn("NotificationSource"),
			CheckMode);
		NotificationTextTemplate = SelectionTypeOfNotification.NotificationTextTemplate;
		GroupingParameters = ConstructorGroupingParameters(SelectionTypeOfNotification.GroupItIntoSeparateDiscussion,
			SelectionTypeOfNotification.GroupHeader,
			SelectionTypeOfNotification.GroupingID);
	EndIf;
	
	TempTablesManager = ManagerOfTTCacheOfAttributes(DCSResult.DataCompositionSettingsComposer,
		QueryBatch[2].Select());
	LayoutResult = ResultOfDataLayout(DCSResult.DataCompositionSchema,
		DCSResult.DataCompositionSettingsComposer,
		TempTablesManager);
	If LayoutResult.Count() = 0 Then
		Return DataTable;
	EndIf;
	
	TableCache = InitializeAttributesCacheTable(LayoutResult.Columns);
	TableLayoutResults = ProcessLayoutResult(LayoutResult, TempTablesManager);
	ExternalRecipientsOfNotifications = NotificationRecipientsAtExternalSystem(
		TableLayoutResults.UnloadColumn("RecipientOfNotificationAfterVerification"));
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	For Each ResultRow In TableLayoutResults Do
		
		TableCache.Clear();
		UserLanguageCode = UserNotificationsOfEventsCached.UserLanguageCode(
			String(ResultRow.IBUserID));
	
		NotificationText1 = NStr(NotificationTextTemplate, UserLanguageCode);
		NotificationTextIsMainOne = NStr(NotificationTextTemplate, DefaultLanguageCode);
		
		If NotificationTextIsMainOne <> NotificationText1 Then // Let's repeat the notification in the main configuration language.
			
			TextOfNotificationWithSubstitution = SubstituteValuesByTemplate(NotificationTextIsMainOne,
				ResultRow,
				TableLayoutResults.Columns,
				DCSResult.FieldDesign,
				DefaultLanguageCode);
			
			NotificationKindData = DataForNotificationKindConstructor(
				NotificationTextConstructor(TextOfNotificationWithSubstitution, DefaultLanguageCode),
				GroupingParameters,
				ResultRow.NotificationContext);
			
			FillInNotificationTypeDataLine(DataTable,
				ResultRow,
				NotificationKindData,
				ExternalRecipientsOfNotifications);
			
		EndIf;
		
		TextOfNotificationWithSubstitution = SubstituteValuesByTemplate(NotificationText1,
			ResultRow,
			TableLayoutResults.Columns,
			DCSResult.FieldDesign,
			UserLanguageCode);
		
		NotificationKindData = DataForNotificationKindConstructor(
			NotificationTextConstructor(TextOfNotificationWithSubstitution, UserLanguageCode),
			GroupingParameters,
			ResultRow.NotificationContext,
			ResultRow.RecipientOfNotificationAfterVerification);
		
		FillInNotificationTypeDataLine(DataTable,
			ResultRow,
			NotificationKindData,
			ExternalRecipientsOfNotifications,
			TableCache);
		
	EndDo;
	
	Return DataTable
	
EndFunction

//@skip-check bsl-nstr-string-literal-format
Function DataOnNonOperationalTypeOfAlerts(NotificationKindAttributes)
	
	DataTable = InitializeTableDataByTypeOfNotification();
	NotificationKind = NotificationKindAttributes.Ref;
	DCSResult = InitializeDataLayoutScheme(NotificationKind);
	
	NotificationTextTemplate = NotificationKindAttributes.NotificationTextTemplate; // String
	GroupedNotificationText = NotificationKindAttributes.GroupedNotificationText; // String
	
	TempTablesManager = New TempTablesManager;
	LayoutResult = ResultOfDataLayout(DCSResult.DataCompositionSchema,
		DCSResult.DataCompositionSettingsComposer,
		TempTablesManager);
	TreeResult = ProcessLayoutResultWithTotals(LayoutResult, NotificationKind); // ValueTree
	ExternalRecipientsOfNotifications = NotificationRecipientsAtExternalSystem(
		TreeResult.Rows.UnloadColumn("RecipientOfNotificationAfterVerification"));
		
	DefaultLanguageCode = Common.DefaultLanguageCode();
	GroupingParameters = ConstructorGroupingParameters(NotificationKindAttributes.GroupItIntoSeparateDiscussion,
		NotificationKindAttributes.GroupHeader,
		NotificationKindAttributes.GroupingID);
	
	For Each LineTotal In TreeResult.Rows Do
		
		If ValueIsFilled(LineTotal.NotificationContext)
			And LineTotal.NotificationContext > NotificationKindAttributes.GroupingThreshold Then
			
			If Not ValueIsFilled(LineTotal.RecipientOfNotificationAfterVerification) Then
				// Non-contextual alerts cannot be without a recipient.
				Continue;
			EndIf;
			
			TransitionCommand = ConstructorOfTransitionCommand();
			RefsMap = New Map;
			RefsPresentations = New Map;
			RefsCount = 0;
			
			IBUserID = "";
			For Each ResultRow In LineTotal.Rows Do
				If Not ValueIsFilled(ResultRow.NotificationContext) Then
					Continue;
				EndIf;
				TableName = Common.TableNameByRef(ResultRow.NotificationContext);
				If RefsMap[TableName] = Undefined Then
					RefsMap.Insert(TableName, New Array);
				EndIf;
				RefsMap[TableName].Add(ResultRow.NotificationContext);
				IBUserID = ResultRow.IBUserID;
				
				If RefsPresentations[ResultRow.NotificationContext] = Undefined Then
					RefsPresentations.Insert(ResultRow.NotificationContext, ResultRow.NotificationContextPresentation);
				EndIf;
				RefsCount = RefsCount + 1;
			EndDo;
			
			If RefsCount > 0 Then
				TransitionCommand.Data.RefsMap = RefsMap;
				TransitionCommand.Data.RefsPresentations = RefsPresentations;
				
				If RefsMap.Count() = 1 Then
					TransitionCommand.Data.FormName = NameOfListFormByLink(ResultRow.NotificationContext, ResultRow.RecipientOfNotificationAfterVerification);
					TransitionCommand.ActionName = "GoToListFormWithFilter";
				Else
					TransitionCommand.Data.FormName = "Catalog.UserNotificationKinds.Form.FollowLinks";
					TransitionCommand.ActionName = "GoToFollowLinksForm";
				EndIf;
				
				UserLanguageCode = UserNotificationsOfEventsCached.UserLanguageCode(
					String(IBUserID));
				
				PresentationGoTo = "vi = 'Chuyển đến (%1)';
									|ru = 'Перейти (%1)';
									|en = 'Go to (%1)';
									|it = 'Go to (%1)';
									|pl = 'Go to (%1)';
									|tr = 'Git (%1)'"; // @Nstr-1
				TransitionCommand.Presentation = NStr(StrTemplate(PresentationGoTo, RefsCount),
					UserLanguageCode);
			EndIf;
			
			NotificationText1 = NStr(GroupedNotificationText,
				UserLanguageCode);
				
			NotificationKindData = DataForNotificationKindConstructor(
				NotificationTextConstructor(NotificationText1, UserLanguageCode),
				GroupingParameters,
				Undefined,
				ResultRow.RecipientOfNotificationAfterVerification,
				TransitionCommand);
				
			FillInNotificationTypeDataLine(DataTable,
				ResultRow,
				NotificationKindData,
				ExternalRecipientsOfNotifications);
		Else
			For Each ResultRow In LineTotal.Rows Do
				
				UserLanguageCode = UserNotificationsOfEventsCached.UserLanguageCode(
					String(ResultRow.IBUserID));
				
				NotificationText1 = NStr(NotificationTextTemplate, UserLanguageCode);
				NotificationTextIsMainOne = NStr(NotificationTextTemplate, DefaultLanguageCode);
				
				If NotificationTextIsMainOne <> NotificationText1 Then // Let's repeat the notification in the main configuration language.
					
					TextOfNotificationWithSubstitution = SubstituteValuesByTemplate(NotificationTextIsMainOne,
						ResultRow,
						TreeResult.Columns,
						DCSResult.FieldDesign,
						DefaultLanguageCode);
					
					NotificationKindData = DataForNotificationKindConstructor(
						NotificationTextConstructor(TextOfNotificationWithSubstitution, DefaultLanguageCode),
						GroupingParameters,
						ResultRow.NotificationContext);
					
					FillInNotificationTypeDataLine(DataTable,
						ResultRow,
						NotificationKindData,
						ExternalRecipientsOfNotifications);
					
				EndIf;
				
				TextOfNotificationWithSubstitution = SubstituteValuesByTemplate(
					NotificationText1,
					ResultRow,
					TreeResult.Columns,
					DCSResult.FieldDesign,
					UserLanguageCode);
				
				NotificationKindData = DataForNotificationKindConstructor(
					NotificationTextConstructor(TextOfNotificationWithSubstitution, UserLanguageCode),
					GroupingParameters,
					ResultRow.NotificationContext,
					ResultRow.RecipientOfNotificationAfterVerification);
				
				FillInNotificationTypeDataLine(DataTable,
					ResultRow,
					NotificationKindData,
					ExternalRecipientsOfNotifications);
					
			EndDo;
		EndIf;
	EndDo;
	
	Return DataTable;
	
EndFunction

Procedure ProcessUserAlerts(DataOnTypeOfAlerts, Author, IdsOfUnprocessedRecords)
	
	If DataOnTypeOfAlerts.Count() = 0 Then
		Return;
	EndIf;
	
	ParametersOfInfobasePublication = ParametersOfInfobasePublication();
	
	RecordSet = InformationRegisters.UserNotificationData.CreateRecordSet();
	TableRecordset = RecordSet.Unload();
	For Each ResultRow In DataOnTypeOfAlerts Do
		Try
			SendAlert(Author,
				ResultRow,
				True);
				
			// We will cache in the register only what was reported.
			AddAlertToRecordsetUserAlertData(ResultRow, TableRecordset);
		Except
			ErrorInfo = ErrorInfo();
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
			If IdsOfUnprocessedRecords.Get(ResultRow.RecordID) = Undefined Then
				IdsOfUnprocessedRecords.Insert(ResultRow.RecordID, ErrorDescription);
			EndIf;
		EndTry;
		
		SendNotificationToIntegrationAddress(Author, ResultRow);
		
		SendNotificationToEmailAddress(ParametersOfInfobasePublication, ResultRow);
		
	EndDo;
	
	Try
		RecordSet.Load(TableRecordset);
		RecordSet.Write(ReplacementMode.Merge);
	Except
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Thực hiện nhiệm vụ';
							|ru = 'Оповещения пользователей.Выполнение заданий';
							|en = 'User notifications.Perform jobs'; fa = 'User notifications.Perform jobs';
							|it = 'User notifications.Perform jobs';
							|pl = 'User notifications.Perform jobs';
							|tr = 'Kullanıcı bildirimleri.Görevlerin gerçekleştirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
		Raise;
	EndTry;
	
EndProcedure

Procedure AddAlertToRecordsetUserAlertData(LineToAdd, TableRecordset)
	
	TheStructureOfTheSearch = New Structure("NotificationSource, NotificationKind, NotificationContext");
	FillPropertyValues(TheStructureOfTheSearch, LineToAdd);
	FoundRows = TableRecordset.FindRows(TheStructureOfTheSearch); // convolution of lines for writing to the register
	If FoundRows.Count() > 0 Then
		FoundRow = FoundRows[0];
		TableCacheOfKeyFieldsReceiver = FoundRow.CacheOfKeyFields.Get(); // ValueTable
		TableCacheOfKeyFieldsSource = LineToAdd.CacheOfKeyFields.Get(); // ValueTable
		If TableCacheOfKeyFieldsSource <> Undefined Then
			If TableCacheOfKeyFieldsReceiver = Undefined Then
				FoundRow.CacheOfKeyFields = LineToAdd.CacheOfKeyFields;
			Else
				CacheSearchStructure = New Structure;
				For Each Column In TableCacheOfKeyFieldsSource.Columns Do
					CacheSearchStructure.Insert(Column.Name);
				EndDo;
				For Each LineCacheSource In TableCacheOfKeyFieldsSource Do
					FillPropertyValues(CacheSearchStructure, LineCacheSource);
					FoundLinesCache = TableCacheOfKeyFieldsReceiver.FindRows(CacheSearchStructure);
					If FoundLinesCache.Count() = 0 Then
						NewLineReceiver = TableCacheOfKeyFieldsReceiver.Add();
						FillPropertyValues(NewLineReceiver, LineCacheSource);
					EndIf;
				EndDo;
				CacheOfKeyFields = New ValueStorage(TableCacheOfKeyFieldsReceiver);
				FoundRow.CacheOfKeyFields = CacheOfKeyFields;
			EndIf;
		EndIf;
	Else
		FillPropertyValues(TableRecordset.Add(), LineToAdd);
	EndIf;
EndProcedure

Procedure ProcessNonOperationalNotificationOfUsers(DataOnTypeOfAlerts, Author)
	ParametersOfInfobasePublication = ParametersOfInfobasePublication();
	For Each ResultRow In DataOnTypeOfAlerts Do
		
		SendAlert(Author, ResultRow);
		
		SendNotificationToIntegrationAddress(Author, ResultRow);
		
		SendNotificationToEmailAddress(ParametersOfInfobasePublication, ResultRow);
		
	EndDo;
	
EndProcedure

Procedure SendAlert(Author, DataOnTypeOfAlerts, ThrowException = False)
	
	Try
		ArrayOfRecipients_ = New Array();
		Recipients = DataOnTypeOfAlerts.RecipientOfNotificationAfterVerification;
		If ValueIsFilled(Recipients) Then
			If TypeOf(Recipients) = Type("Array") Then
				For Each ArrayElement In Recipients Do
					If ValueIsFilled(ArrayElement) Then
						CollaborationSystemUser = Conversations.CollaborationSystemUser(ArrayElement);
						If Not CollaborationSystemUser.IsLocked Then
							ArrayOfRecipients_.Add(CollaborationSystemUser);
						EndIf;
					EndIf;
				EndDo;
			Else
				CollaborationSystemUser = Conversations.CollaborationSystemUser(Recipients);
				If Not CollaborationSystemUser.IsLocked Then
					ArrayOfRecipients_.Add(CollaborationSystemUser);
				EndIf;
			EndIf;
		EndIf;
		
		If ArrayOfRecipients_.Count() = 0 Then
			Return;
		EndIf;
		
		Data = New Structure("NotificationKind", DataOnTypeOfAlerts.NotificationKind);
		
		MessageDetails = Conversations.MessageDetails(DataOnTypeOfAlerts.NotificationText1);
		MessageDetails.Data = Data;
		
		MessageDetails.ButtonPanel.ButtonsType = CollaborationSystemMessageButtonPanelButtonType.Hyperlink;
		
		TransferCommands = DataOnTypeOfAlerts.TransitionCommand;
		If ValueIsFilled(TransferCommands) Then
			ArrayTransitionCommands = New Array;
			If TypeOf(TransferCommands) = Type("Structure") Then
				ArrayTransitionCommands.Add(TransferCommands);
			Else
				ArrayTransitionCommands = TransferCommands;
			EndIf;
			
			ArrayOfButtons = New Array;
			Counter = 0;
			For Each TransitionCommand In ArrayTransitionCommands Do
				DescriptionOfButton = Conversations.DescriptionOfButton(
					CollaborationSystemMessageButtonPanelButtonAction.ProcessOnClient,
					TransitionCommand.Presentation);
				DescriptionOfButton.Data = TransitionCommand.Data;
				DescriptionOfButton.ActionName = TransitionCommand.ActionName;
				ArrayOfButtons.Add(DescriptionOfButton);
				Counter = Counter + 1;
				If Counter%10 = 0 Then // there can be no more than 10 buttons in a row
					MessageDetails.ButtonPanel.ButtonRows.Add(ArrayOfButtons);
					ArrayOfButtons = New Array;
				EndIf;
			EndDo;
			If ArrayOfButtons.Count() > 0 Then
				MessageDetails.ButtonPanel.ButtonRows.Add(ArrayOfButtons);
			EndIf;
		EndIf;
		
		NotificationContext = DataOnTypeOfAlerts.NotificationContext;
		If Not ValueIsFilled(NotificationContext) Then
			
			// The message will be sent without context. We split the recipients so that a shared chat is not created.
			For Each Recipient In ArrayOfRecipients_ Do
				
				GroupingParameters = DiscussionGroupingParameters(DataOnTypeOfAlerts,
					Recipient,
					NotificationContext);
					
				Conversations.SendMessage(Author,
					CommonClientServer.ValueInArray(Recipient),
					MessageDetails,
					GroupingParameters.DiscussionKey,
					GroupingParameters.DiscussionTitle);
				
			EndDo;
			
		Else
			Conversations.SendMessage(Author,
				ArrayOfRecipients_,
				MessageDetails,
				NotificationContext);
		EndIf;
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteLogEvent(NStr("vi = 'Thông báo cho người sử dụng.Thực hiện nhiệm vụ';
							|ru = 'Оповещения пользователей.Выполнение заданий';
							|en = 'User notifications.Perform jobs'; fa = 'User notifications.Perform jobs';
							|it = 'User notifications.Perform jobs';
							|pl = 'User notifications.Perform jobs';
							|tr = 'Kullanıcı bildirimleri.Görevlerin gerçekleştirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorDescription);
		If ThrowException Then
			Raise;
		EndIf;
	EndTry;
	
EndProcedure

Procedure SendNotificationToIntegrationAddress(Author, ResultRow)
	
	For Each IntegrationAddress In ResultRow.IntegrationAddresses Do
		NotificationText1 = StrReplace(ResultRow.NotificationText1, Chars.NBSp, " ");
		
		If ValueIsFilled(ResultRow.NotificationContextPresentation) Then
			NotificationText1 = NotificationText1 + Chars.LF + ResultRow.NotificationContextPresentation;
		EndIf;
		
		If ValueIsFilled(ResultRow.TransitionCommand) Then
			NotificationText1 = NotificationText1 + Chars.LF + StrTemplate(NStr("ru = 'Количество (%1)';
																				|vi = 'Quantity (%1)';
																				|en = 'Quantity (%1)'; fa = 'Quantity (%1)';
																				|it = 'Quantità (%1)';
																				|pl = 'Ilość (%1)';
																				|tr = 'Miktar (%1)'",
				ResultRow.UserLanguageCode),
				ResultRow.TransitionCommand.Data.RefsPresentations.Count());
		EndIf;
		
		MessageDetails = Conversations.MessageDetails(NotificationText1);
		
		Try
			Conversations.SendNotification(Author, 
				MessageDetails, New CollaborationSystemConversationID(IntegrationAddress));
		Except
			ErrorInfo = ErrorInfo();
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
			WriteLogEvent(NStr("ru = 'Оповещения пользователей.Отправка во внешнюю систему';
								|vi = 'User notifications.Sending to external system';
								|en = 'User notifications.Sending to external system'; fa = 'User notifications.Sending to external system';
								|it = 'User notifications.Sending to external system';
								|pl = 'User notifications.Sending to external system';
								|tr = 'Kullanıcı bildirimleri.Harici sisteme gönderim'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorDescription);
		EndTry;
	EndDo;
	
EndProcedure

Procedure SendNotificationToEmailAddress(PublicationParameters, ResultRow)
	
	If Not ValueIsFilled(ResultRow.AddressesOfMail) Then
		Return;
	EndIf;
	
	EmailHeader = NStr("ru = 'Оповещение:';
						|vi = 'Notification:';
						|en = 'Notification:'; fa = 'Notification:';
						|it = 'Notification:';
						|pl = 'Notification:';
						|tr = 'Bildirim:'", ResultRow.UserLanguageCode) + " " + ResultRow.NotificationText1;
	SystemTitle = NStr("ru = 'Конфигурация:';
						|vi = 'Configuration:';
						|en = 'Configuration:'; fa = 'Configuration:';
						|it = 'Configuration:';
						|pl = 'Configuration:';
						|tr = 'Konfigürasyon:'", ResultRow.UserLanguageCode) + Chars.LF + PublicationParameters.SystemTitle;
	NotificationText1 = NStr("ru = 'Текст оповещения:';
							|vi = 'Notification text:';
							|en = 'Notification text:'; fa = 'Notification text:';
							|it = 'Notification text:';
							|pl = 'Notification text:';
							|tr = 'Bildirim metni:'", ResultRow.UserLanguageCode) + Chars.LF + ResultRow.NotificationText1;
	
	HyperlinkAnchorText = "";
	If ValueIsFilled(ResultRow.NotificationContext) Then
		HyperlinkAnchorText = NStr("ru = 'Ссылка:';
									|vi = 'Link:';
									|en = 'Link:'; fa = 'Link:';
									|it = 'Link:';
									|pl = 'Link:';
									|tr = 'Bağlantı:'", ResultRow.UserLanguageCode);
		AddLinkToEmailBody(HyperlinkAnchorText,
			ResultRow.NotificationContext,
			ResultRow.NotificationContextPresentation,
			PublicationParameters);
	ElsIf ValueIsFilled(ResultRow.TransitionCommand) Then
		HyperlinkAnchorText = NStr("ru = 'Ссылки (%1):';
									|vi = 'Link (%1):';
									|en = 'Link (%1):'; fa = 'Link (%1):';
									|it = 'Link (%1):';
									|pl = 'Link (%1):';
									|tr = 'Bağlantı (%1):'", ResultRow.UserLanguageCode);
		HyperlinkAnchorText = StrTemplate(HyperlinkAnchorText, ResultRow.TransitionCommand.Data.RefsPresentations.Count());
		For Each MapItem In ResultRow.TransitionCommand.Data.RefsPresentations Do
			AddLinkToEmailBody(HyperlinkAnchorText,
				MapItem.Key,
				MapItem.Value,
				PublicationParameters);
		EndDo;
	EndIf;
	
	EmailText = SystemTitle + Chars.LF + Chars.LF + NotificationText1 + Chars.LF + Chars.LF + HyperlinkAnchorText;
	
	NumberOfAttemptsToSendEmail = 3;
	ArrayOfSent = New Array;
	
	For AttemptNumber = 1 To NumberOfAttemptsToSendEmail Do
		
		For Each MailAddress In ResultRow.AddressesOfMail Do
			If ArrayOfSent.Find(MailAddress) = Undefined Then
				EmailSent = SendMail(EmailHeader, EmailText, MailAddress);
				If EmailSent Then
					ArrayOfSent.Add(MailAddress);
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure SetSelectionByNotificationSource(Settings, SourcesOfAlerts)
	FilterElement = Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));

	FilterElement.LeftValue = New DataCompositionField("NotificationSource");;
	FilterElement.Use = True;
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	FilterElement.RightValue = SourcesOfAlerts;
EndProcedure

// Fill in the notification type data line.
// 
// Parameters:
//  DataTable - See InitializeTableDataByTypeOfNotification
//  InitialString - ValueTableRow, ValueTreeRow - 
//  NotificationKindData - See DataForNotificationKindConstructor
//  ExternalRecipientsOfNotifications - See NotificationRecipientsAtExternalSystem
//  TableCache - Undefined, ValueTable - 
Procedure FillInNotificationTypeDataLine(DataTable, InitialString, NotificationKindData, ExternalRecipientsOfNotifications, Val TableCache = Undefined)
	
	KeySearchFields = New Structure("NotificationSource, NotificationKind");
	FillPropertyValues(KeySearchFields, InitialString);
	KeySearchFields.Insert("NotificationContext", NotificationKindData.NotificationContext);
	KeySearchFields.Insert("NotificationText1", NotificationKindData.NotificationText1);
	
	ExternalAddressesOfRecipient = ExternalRecipientsOfNotifications.Get(NotificationKindData.RecipientOfNotificationAfterVerification);
	IntegrationAddresses = New Array;
	If ExternalAddressesOfRecipient <> Undefined Then
		IntegrationAddresses = ExternalAddressesOfRecipient.IntegrationAddresses;
	EndIf;
	AddressesOfMail = New Array;
	If ExternalAddressesOfRecipient <> Undefined Then
		AddressesOfMail = ExternalAddressesOfRecipient.AddressesOfMail;
	EndIf;
	
	FoundRows = DataTable.FindRows(KeySearchFields);
	If FoundRows.Count() > 0 And NotificationKindData.NotificationContext <> Undefined Then
		ChangedRow = FoundRows[0]; // If a string with such key fields exists, add the recipient.
		ArrayOfRecipients_ = ChangedRow.NotificationRecipient;
		If ArrayOfRecipients_.Find(InitialString.NotificationRecipient) = Undefined Then
			ArrayOfRecipients_.Add(InitialString.NotificationRecipient);
		EndIf;
		ArrayOfRecipientsAfterVerification = ChangedRow.RecipientOfNotificationAfterVerification;
		If ArrayOfRecipientsAfterVerification.Find(NotificationKindData.RecipientOfNotificationAfterVerification) = Undefined Then
			ArrayOfRecipientsAfterVerification.Add(NotificationKindData.RecipientOfNotificationAfterVerification);
		EndIf;
		CacheOfKeyFields = ChangedRow.CacheOfKeyFields;
		If ValueIsFilled(CacheOfKeyFields) Then
			TableCacheAdd = CacheOfKeyFields.Get();
			FillInCacheOfKeyFieldsInLine(ChangedRow, InitialString, TableCacheAdd);
		EndIf;
		For Each IntegrationAddress In IntegrationAddresses Do
			If ChangedRow.IntegrationAddresses.Find(IntegrationAddress) = Undefined Then
				ChangedRow.IntegrationAddresses.Add(IntegrationAddress);
			EndIf;
		EndDo;
		For Each MailAddr In AddressesOfMail Do
			If ChangedRow.AddressesOfMail.Find(MailAddr) = Undefined Then
				ChangedRow.AddressesOfMail.Add(MailAddr);
			EndIf;
		EndDo;
	Else
		NewRow = DataTable.Add();
		FillPropertyValues(NewRow, InitialString, , "NotificationContext, NotificationContextPresentation, NotificationRecipient, RecipientOfNotificationAfterVerification");
		
		ArrayOfRecipients_ = New Array;
		ArrayOfRecipients_.Add(InitialString.NotificationRecipient);
		
		ArrayOfRecipientsAfterVerification = New Array;
		ArrayOfRecipientsAfterVerification.Add(NotificationKindData.RecipientOfNotificationAfterVerification);
		
		NewRow.NotificationText1 = NotificationKindData.NotificationText1;
		NewRow.NotificationContext = NotificationKindData.NotificationContext;
		NewRow.NotificationRecipient = ArrayOfRecipients_;
		NewRow.RecipientOfNotificationAfterVerification = ArrayOfRecipientsAfterVerification;
		NewRow.TransitionCommand = NotificationKindData.TransitionCommand;
		NewRow.RecordDate = CurrentSessionDate();
		NewRow.IntegrationAddresses = IntegrationAddresses;
		NewRow.AddressesOfMail = AddressesOfMail;
		NewRow.UserLanguageCode = NotificationKindData.UserLanguageCode;
		If ValueIsFilled(NewRow.NotificationContext) Then
			NewRow.NotificationContextPresentation = InitialString.NotificationContextPresentation;
		EndIf;
		NewRow.GroupItIntoSeparateDiscussion = NotificationKindData.GroupItIntoSeparateDiscussion;
		NewRow.GroupHeader = NotificationKindData.GroupHeader;
		NewRow.GroupingID = NotificationKindData.GroupingID;
		
		FillInCacheOfKeyFieldsInLine(NewRow, InitialString, TableCache);
	EndIf;
	
EndProcedure

Procedure FillInCacheOfKeyFieldsInLine(NewRow, InitialString, TableCache)
	
	If TableCache = Undefined Then
		Return;
	EndIf;
	
	NewLineCache = TableCache.Add();
	FillPropertyValues(NewLineCache, InitialString);
	CacheOfKeyFields = New ValueStorage(TableCache);
	
	NewRow.CacheOfKeyFields = CacheOfKeyFields;
EndProcedure

// Parameters:
//	StructureOfNotificationText - See NotificationTextConstructor
//	GroupingParameters - See ConstructorGroupingParameters
//	NotificationContext - Undefined, AnyRef - 
//	RecipientOfNotificationAfterVerification - Undefined, CatalogRef.Users - 
//	TransitionCommand - Undefined
//		- See ConstructorOfTransitionCommand
// Returns:
//	Structure:
//		* NotificationText1 - String, FormattedString - 
//		* UserLanguageCode - String - 
//		* NotificationContext - Undefined, AnyRef - 
//		* RecipientOfNotificationAfterVerification - Undefined, CatalogRef.Users - 
//		* GroupItIntoSeparateDiscussion - Boolean - 
//		* GroupHeader - String - 
//		* GroupingID - String - 
//		* TransitionCommand - Undefined
//			- See ConstructorOfTransitionCommand
Function DataForNotificationKindConstructor(StructureOfNotificationText, GroupingParameters, NotificationContext = Undefined, RecipientOfNotificationAfterVerification = Undefined, TransitionCommand = Undefined)
	
	NotificationKindData = New Structure;
	NotificationKindData.Insert("NotificationText1", StructureOfNotificationText.NotificationText1);
	NotificationKindData.Insert("UserLanguageCode", StructureOfNotificationText.UserLanguageCode);
	NotificationKindData.Insert("NotificationContext", NotificationContext);
	NotificationKindData.Insert("RecipientOfNotificationAfterVerification", RecipientOfNotificationAfterVerification);
	NotificationKindData.Insert("GroupItIntoSeparateDiscussion", GroupingParameters.GroupItIntoSeparateDiscussion);
	NotificationKindData.Insert("GroupHeader", GroupingParameters.GroupHeader);
	NotificationKindData.Insert("GroupingID", GroupingParameters.GroupingID);
	NotificationKindData.Insert("TransitionCommand", TransitionCommand);
	
	Return NotificationKindData
	
EndFunction

// Parameters:
//	NotificationText1 - String, FormattedString - 
//	UserLanguageCode - String - 
// Returns:
//	Structure:
//		* NotificationText1 - String, FormattedString - 
//		* UserLanguageCode - String - 
Function NotificationTextConstructor(NotificationText1, UserLanguageCode)
	
	Result = New Structure();
	Result.Insert("NotificationText1", NotificationText1);
	Result.Insert("UserLanguageCode", UserLanguageCode);
	
	Return Result
	
EndFunction

// Parameters:
//	GroupItIntoSeparateDiscussion - Boolean
//	GroupHeader - String - 
//	GroupingID - String - 
// Returns:
//	Structure:
//		* GroupItIntoSeparateDiscussion - Boolean -
//		* GroupHeader - String - 
//		* GroupingID - String - 
Function ConstructorGroupingParameters(GroupItIntoSeparateDiscussion, GroupHeader, GroupingID)
	
	Result = New Structure();
	Result.Insert("GroupItIntoSeparateDiscussion", GroupItIntoSeparateDiscussion);
	Result.Insert("GroupHeader", GroupHeader);
	Result.Insert("GroupingID", GroupingID);
	
	Return Result
	
EndFunction

// Parameters:
//	GroupingParameters - See ConstructorGroupingParameters
//	Recipient - CollaborationSystemUser - 
//	NotificationContext - Undefined, AnyRef - 
// Returns:
//	Structure:
//		* DiscussionKey - String -
//		* DiscussionTitle - String - 
Function DiscussionGroupingParameters(GroupingParameters, Recipient, NotificationContext)
	
	Result = New Structure("DiscussionKey, DiscussionTitle", "", "");
	If Not ValueIsFilled(NotificationContext)
		And GroupingParameters.GroupItIntoSeparateDiscussion Then
		
		ID_Recipient = String(Recipient.ID);
		Result.DiscussionKey = GroupingParameters.GroupingID + ID_Recipient;
		Result.DiscussionTitle = GroupingParameters.GroupHeader;
		
	EndIf;
	
	Return Result
	
EndFunction

Function InitializeDataLayoutScheme(NotificationTypeAttributes, SourcesOfNotification = Undefined, RestrictSelection = False)
	DataCompositionSchema = NotificationTypeAttributes.DataCompositionSchema.Get();
	CompositionSettings = NotificationTypeAttributes.StorageOfDataCompositionSettings.Get();
	
	If DataCompositionSchema = Undefined Then
		DataCompositionSchema = TemplateByFullName(NotificationTypeAttributes.DCSTemplateName);
	EndIf;
	
	FieldDesign = New Map;
	
	For Each DataSet In DataCompositionSchema.DataSets Do
		If RestrictSelection Then
			QueryText = StrReplaceByRegularExpression(DataSet.Query, 
				"^(?!\s*ВЫБРАТЬ\s+.*ПЕРВЫЕ\s*\d+)(\s*ВЫБРАТЬ)(\s+.*)$",
				"$1 ПЕРВЫЕ 10 $2", True, True); //@Non-NLS-1 @Non-NLS-2
			QueryText = StrReplaceByRegularExpression(QueryText, 
				"^(?!\s*SELECT\s+.*TOP\s*\d+)(\s*SELECT)(\s+.*)$",
				"$1 TOP 10 $2", True, True); //@Non-NLS-1 @Non-NLS-2
			DataSet.Query = QueryText;
		EndIf;
		For Each Field In DataSet.Fields Do
			FieldName = "[" + Field.DataPath + "]";
			DesignParameterValues = New Structure;
			For Each AppearanceItem In Field.Appearance.Items Do
				If AppearanceItem.Use Then
					DesignParameterValues.Insert(AppearanceItem.Parameter, AppearanceItem.Value);
				EndIf;
			EndDo;
			FieldDesign.Insert(FieldName, DesignParameterValues);
		EndDo;
	EndDo;
	
	DataCompositionSettingsComposer = InitializeSettingsComposer(DataCompositionSchema, CompositionSettings);
	
	If ValueIsFilled(SourcesOfNotification) Then
		SetSelectionByNotificationSource(DataCompositionSettingsComposer.FixedSettings, SourcesOfNotification);
	EndIf;
	
	Settings = DataCompositionSettingsComposer.Settings;
	If Settings.DataParameters.Items.Find("UpdateDate") <> Undefined Then
		Settings.DataParameters.SetParameterValue("UpdateDate", CurrentSessionDate());
	EndIf;
	
	Return New Structure("DataCompositionSchema, DataCompositionSettingsComposer, FieldDesign", DataCompositionSchema, DataCompositionSettingsComposer, FieldDesign);
EndFunction

Function ManagerOfTTCacheOfAttributes(DataCompositionSettingsComposer, SelectingBankingDetails_)
	
	Settings = DataCompositionSettingsComposer.GetSettings(); // DataCompositionSettings
	
	TableCache = New ValueTable;
	TableCache.Columns.Add("NotificationKind", New TypeDescription("CatalogRef.UserNotificationKinds"), NStr("vi = 'Dạng thông báo';
																											|ru = 'Вид оповещения';
																											|en = 'Notification kind'; fa = 'نوع اعلان';
																											|it = 'Tipo di notifica';
																											|pl = 'Rodzaj powiadomienia';
																											|tr = 'Bildirim türü'"));
	TableCache.Columns.Add("NotificationInitiator", New TypeDescription("CatalogRef.Users"), NStr("vi = 'Bộ khởi tạo thông báo';
																									|ru = 'Инициатор оповещения';
																									|en = 'Notification initiator'; fa = 'آغازگر اعلان';
																									|it = 'Notification initiator';
																									|pl = 'Notification initiator';
																									|tr = 'Bildirim başlatıcısı'"));
	TableCache.Columns.Add("RecordID", New TypeDescription("UUID"), NStr("vi = 'Tên bản ghi';
																		|ru = 'Идентификатор записи';
																		|en = 'Record ID'; fa = 'شناسه رکورد';
																		|it = 'Identificatore di record';
																		|pl = 'Identyfikator wpisu';
																		|tr = 'Kayıt kimliği'"));
	For Each AvailableField In Settings.Selection.SelectionAvailableFields.Items Do
		If AvailableField.Folder Then
			Continue;
		EndIf;
		If AvailableField.Field = New DataCompositionField("NotificationKind")
			Or AvailableField.Field = New DataCompositionField("NotificationInitiator") Then
			Continue;
		EndIf;
		TableCache.Columns.Add(AvailableField.Field, AvailableField.Type, AvailableField.Title);
	EndDo;
	
	While SelectingBankingDetails_.Next() Do
		NewRow = TableCache.Add();
		FillPropertyValues(NewRow, SelectingBankingDetails_);
		CacheOfKeyFields = SelectingBankingDetails_.CacheOfKeyFields;
		If ValueIsFilled(CacheOfKeyFields) Then
			CacheValue = CacheOfKeyFields.Get();
			If TypeOf(CacheValue) = Type("ValueTable") And CacheValue.Count() > 0 Then
				LastIndex = CacheValue.Count()-1;
				For IndexOf = 0 To LastIndex Do
					CacheRow = CacheValue[IndexOf];
					FillPropertyValues(NewRow, CacheRow);
					If IndexOf < LastIndex Then
						NewRow = TableCache.Add();
						FillPropertyValues(NewRow, SelectingBankingDetails_);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	TempTablesManager = New TempTablesManager;
	//@skip-check bsl-ql-hub
	Query = New Query("SELECT * INTO TTCacheOfAttributes FROM &TableCache AS T INDEX BY NotificationSource;");
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("TableCache", TableCache);
	Query.Execute();
	
	Return TempTablesManager
EndFunction

Function ResultOfDataLayout(DataCompositionSchema, DataCompositionSettingsComposer, TempTablesManager)
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, 
		DataCompositionSettingsComposer.GetSettings(),,,
		Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate,,,False,,TempTablesManager);
	
	// The table of values in which the result will be received
	Result = New ValueTable;
	
	// Getting the result
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(Result);
	OutputProcessor.Output(DataCompositionProcessor);
	
	Return Result
EndFunction

Function ProcessLayoutResult(LayoutResult, TempTablesManager)
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	//@skip-check bsl-ql-hub
	Query.Text = "
	|SELECT
	|	*
	|INTO
	|	TTIsResultOfLayout
	|FROM
	|	&LayoutResult AS T
	|INDEX BY
	|	T.NotificationSource,
	|	T.NotificationContext
	|;
	|
	|SELECT DISTINCT
	|	TTData.NotificationSource AS NotificationSource,
	|	TTData.NotificationContext AS NotificationContext,
	|	TTCacheOfAttributes.RecordID AS RecordID,
	|	TTCacheOfAttributes.NotificationKind AS NotificationKind,
	|	TTData.NotificationRecipient AS NotificationRecipient,
	|	CASE
	|		WHEN TTData.NotificationRecipient = TTCacheOfAttributes.NotificationInitiator
	|				OR NOT NotificationsSettings.User IS NULL
	|			THEN VALUE(Catalog.Users.EmptyRef)
	|		ELSE TTData.NotificationRecipient
	|	END AS RecipientOfNotificationAfterVerification
	|INTO
	|	TTRecipients
	|FROM
	|	TTIsResultOfLayout AS TTData
	|		LEFT JOIN TTCacheOfAttributes AS TTCacheOfAttributes
	|		ON TTData.NotificationSource = TTCacheOfAttributes.NotificationSource
	|		LEFT JOIN InformationRegister.DisabledUserNotificationSettings AS NotificationsSettings
	|		ON (NotificationsSettings.NotificationKind = TTCacheOfAttributes.NotificationKind)
	|			AND (NotificationsSettings.User = TTData.NotificationRecipient)
	|INDEX BY
	|	TTData.NotificationSource,
	|	TTData.NotificationContext
	|;
	|
	|SELECT DISTINCT
	|	TTData.*,
	|	PRESENTATION(TTData.NotificationContext) AS NotificationContextPresentation,
	|	TTRecipients.RecipientOfNotificationAfterVerification AS RecipientOfNotificationAfterVerification,
	|	TTRecipients.RecordID AS RecordID,
	|	TTRecipients.NotificationKind AS NotificationKind,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	TTIsResultOfLayout AS TTData
	|		INNER JOIN TTRecipients AS TTRecipients
	|		ON TTData.NotificationSource = TTRecipients.NotificationSource
	|		AND TTData.NotificationContext = TTRecipients.NotificationContext
	|		AND TTData.NotificationRecipient = TTRecipients.NotificationRecipient
	|		LEFT JOIN Catalog.Users AS Users
	|		ON TTRecipients.NotificationRecipient = Users.Ref
	|";
	
	Query.SetParameter("LayoutResult", LayoutResult);
	Return Query.Execute().Unload();
EndFunction

Function ProcessLayoutResultWithTotals(LayoutResult, NotificationKind)
	Query = New Query;
	//@skip-check bsl-ql-hub
	Query.Text = "
	|SELECT
	|	*
	|INTO
	|	TTIsResultOfLayout
	|FROM
	|	&LayoutResult AS T
	|;
	|
	|SELECT DISTINCT
	|	TTData.NotificationRecipient AS NotificationRecipient,
	|	CASE
	|		WHEN NOT NotificationsSettings.User IS NULL
	|			THEN VALUE(Catalog.Users.EmptyRef)
	|		ELSE TTData.NotificationRecipient
	|	END AS RecipientOfNotificationAfterVerification
	|INTO
	|	TTRecipients
	|FROM
	|	TTIsResultOfLayout AS TTData
	|		LEFT JOIN InformationRegister.DisabledUserNotificationSettings AS NotificationsSettings
	|		ON (NotificationsSettings.NotificationKind = &NotificationKind)
	|			AND (NotificationsSettings.User = TTData.NotificationRecipient)
	|;
	|
	|SELECT DISTINCT
	|	TTData.*,
	|	PRESENTATION(TTData.NotificationContext) AS NotificationContextPresentation,
	|	&NotificationKind AS NotificationKind,
	|	TTRecipients.RecipientOfNotificationAfterVerification AS RecipientOfNotificationAfterVerification,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	TTIsResultOfLayout AS TTData
	|		INNER JOIN TTRecipients AS TTRecipients
	|		ON TTData.NotificationRecipient = TTRecipients.NotificationRecipient
	|		LEFT JOIN Catalog.Users AS Users
	|		ON TTRecipients.RecipientOfNotificationAfterVerification = Users.Ref
	|TOTALS
	|	COUNT(DISTINCT TTData.NotificationContext)
	|BY
	|	RecipientOfNotificationAfterVerification
	|";
	
	Query.SetParameter("LayoutResult", LayoutResult);
	Query.SetParameter("NotificationKind", NotificationKind);
	
	Return Query.Execute().Unload(QueryResultIteration.ByGroups);
EndFunction

Function InitializeAttributesCacheTable(Columns)
	
	TableCache = New ValueTable;
	
	ArrayIsForbidden = New Array;
	ArrayIsForbidden.Add("NotificationSource");
	ArrayIsForbidden.Add("NotificationKind");
	ArrayIsForbidden.Add("NotificationContext");
	ArrayIsForbidden.Add("CacheOfKeyFields");
	ArrayIsForbidden.Add("RecordDate");
	
	For Each Column In Columns Do
		If ArrayIsForbidden.Find(Column.Name) <> Undefined Then
			Continue;
		EndIf;
		TableCache.Columns.Add(Column.Name,
			Column.ValueType,
			Column.Title,
			Column.Width);
	EndDo;
	Return TableCache
EndFunction

Function SubstituteValuesByTemplate(Val StringPattern_, ValuesRow, CollectionOfParameterNames, FieldDesign, LanguageCode)
	ReplacementParameters = New Map;
	For Each Value In CollectionOfParameterNames Do
		ParameterName = "[" + Value.Name + "]";
		ParameterValue = ValuesRow[CollectionOfParameterNames.IndexOf(Value)];
		ReplacementParameters.Insert(ParameterName, ParameterValue);
	EndDo;
	
	RegularExpression = "(\[[^\]]+\])|([^\[\]]+)"; //@Non-NLS-1
	RegularExpressionParameter = "\[[^\s]+\]"; //@Non-NLS-1
	
	RowsArray = New Array;
	SearchResults = StrFindAllByRegularExpression(StringPattern_, RegularExpression);
	For Each SearchResult In SearchResults Do
		If StrLikeByRegularExpression(SearchResult.Value, RegularExpressionParameter) Then
			CurrentParameter = ReplacementParameters.Get(SearchResult.Value);
			If CurrentParameter <> Undefined Then
				FieldAppearance = FieldDesign.Get(SearchResult.Value);
				DecoratedLine = IssueLine(SearchResult.Value, CurrentParameter, FieldAppearance, LanguageCode);
				RowsArray.Add(DecoratedLine);
			Else
				RowsArray.Add(SearchResult.Value);
			EndIf;
		Else
			RowsArray.Add(SearchResult.Value);
		EndIf;
	EndDo;
	
	Result = New FormattedString(RowsArray);
	Return Result
	
EndFunction

Function PresentationOfDocument(DocumentRef, LanguageCode)
	
	// The documentlink is ignored for now, since receiving document representations 
	// in different languages is not supported, we simply return the string
	
	Return NStr("vi = 'Chuyển đến chứng từ';
				|ru = 'Перейти к документу';
				|en = 'Go to document'; fa = 'Go to document';
				|it = 'Go to document';
				|pl = 'Go to document';
				|tr = 'Belgeye git'", LanguageCode);
	
EndFunction

Function ReservedFieldNames(OnlyRequired = False)
	
	ReservedNames = RequiredFields();
	If Not OnlyRequired Then
		For Each OptionalField In OptionalFields() Do
			ReservedNames.Add(OptionalField);
		EndDo;
	EndIf;
	Return ReservedNames;
	
EndFunction

Function RequiredFields()
	
	ReservedNames = New Array;
	ReservedNames.Add("NotificationRecipient");
	ReservedNames.Add("NotificationContext");
	
	Return ReservedNames;
	
EndFunction

Function OptionalFields()
	
	ReservedNames = New Array;
	ReservedNames.Add("NotificationSource");
	
	Return ReservedNames;
	
EndFunction

// Allows you to check the correctness of the data acquisition scheme for generating alerts, correct errors if necessary,
// and also fill in the list of critical errors that the user will need to correct.
//
// Parameters:
//   DataCompositionSchema - DataCompositionSchema - The scheme of receiving these alerts.
//   SchemeContainsCriticalErrors - Boolean - a flag for critical errors that must
//   				be raised so that the user cannot apply the schema until the errors are fixed.
//   ListOfCriticalErrors - ValueList of String - A list containing the texts of critical error messages.
//   ListOfOtherMessages - ValueList of String - A list containing the texts of messages about fixed errors and other comments.
//   				This list of messages is displayed to the user once.
//   RequiredFields - Array of String - Array of required field names for the data layout scheme.
//   SettingsComposer - DataCompositionSettingsComposer - The settings Composer for checking the schema.
//
Procedure CheckingCorrectnessOfNotificationDataReceiptScheme(DataCompositionSchema, SchemeContainsCriticalErrors,
					ListOfCriticalErrors, ListOfOtherMessages, RequiredFields, SettingsComposer = Undefined)
	If DataCompositionSchema = Undefined Then
		ErrorText = NStr("vi = 'Chưa điền sơ đồ dàn dựng dữ liệu.';
						|ru = 'Схема компоновки данных не заполнена.';
						|en = 'The data composition schema is not filled.'; fa = 'The data composition schema is not filled.';
						|it = 'The data composition schema is not filled.';
						|pl = 'The data composition schema is not filled.';
						|tr = 'Veri inşa edilme şeması doldurulmadı.'");
		ListOfCriticalErrors.Add(ErrorText);
	ElsIf DataCompositionSchema.DataSets.Count() = 0 Then
		ErrorText = NStr("vi = 'Trong sơ đồ dàn dựng không có tập hợp dữ liệu nào.';
						|ru = 'В схеме компоновки нет ни одного набора данных.';
						|en = 'There are no data sets in the data composition schema.'; fa = 'There are no data sets in the data composition schema.';
						|it = 'There are no data sets in the data composition schema.';
						|pl = 'There are no data sets in the data composition schema.';
						|tr = 'İnşa şemasında herhangi bir veri kümesi bulunmamaktadır.'");
		ListOfCriticalErrors.Add(ErrorText);
	Else
		UnlimitedLengthStringType = New TypeDescription("String",,,,New StringQualifiers(0,AllowedLength.Variable));
		DataCompositionSettingsComposer = InitializeSettingsComposer(DataCompositionSchema, SettingsComposer);
		Settings = DataCompositionSettingsComposer.GetSettings();
		For Each FieldName In RequiredFields Do
			RequiredField = New DataCompositionField(FieldName);
			FoundField = Settings.Selection.SelectionAvailableFields.FindField(RequiredField);
			If FoundField = Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không tìm thấy trường bắt buộc điền ""%1"" trong các trường chọn khả dụng của sơ đồ dàn dựng dữ liệu.';
						|ru = 'Обязательное поле ""%1"" не найдено в доступных полях выбора схемы компоновки данных.';
						|en = 'The ""%1"" required field is not found in the available fields of the data composition schema.'; fa = 'The ""%1"" required field is not found in the available fields of the data composition schema.';
						|it = 'The ""%1"" required field is not found in the available fields of the data composition schema.';
						|pl = 'The ""%1"" required field is not found in the available fields of the data composition schema.';
						|tr = 'Mevcut veri inşa edilme şemasının seçim alanlarında ""%1"" gerekli alanı bulunamadı.'"),
					FieldName);
				ListOfCriticalErrors.Add(ErrorText);
			EndIf;
			RequiredFieldSelected = False;
			For Each SelectedField In Settings.Selection.Items Do
				If TypeOf(SelectedField) = Type("DataCompositionAutoSelectedField") Then
					Continue;
				EndIf;
				If SelectedField.Field = RequiredField And SelectedField.Use Then
					RequiredFieldSelected = True;
					Break;
				EndIf;
			EndDo;
			If Not RequiredFieldSelected Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa chọn trường bắt buộc ""%1"" trong sơ đồ dàn dựng dữ liệu.';
						|ru = 'Обязательное поле ""%1"" не выбрано в схеме компоновки данных.';
						|en = 'The ""%1"" required field is not selected in the data composition schema.'; fa = 'The ""%1"" required field is not selected in the data composition schema.';
						|it = 'The ""%1"" required field is not selected in the data composition schema.';
						|pl = 'The ""%1"" required field is not selected in the data composition schema.';
						|tr = 'Veri inşa edilme şemasında ""%1"" zorunlu alanı seçilmedi.'"),
					FieldName);
				ListOfCriticalErrors.Add(ErrorText);
			EndIf;
		EndDo;
		FieldName = "UpdateDate";
		If Settings.DataParameters.Items.Find(FieldName) = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có tham số bắt buộc ""%1"" trong sơ đồ dàn dựng dữ liệu.';
					|ru = 'Отсутствует обязательный параметр ""%1"" в схеме компоновки данных.';
					|en = 'The ""%1"" required parameter is missing in the data composition schema.'; fa = 'The ""%1"" required parameter is missing in the data composition schema.';
					|it = 'The ""%1"" required parameter is missing in the data composition schema.';
					|pl = 'The ""%1"" required parameter is missing in the data composition schema.';
					|tr = 'Veri inşa edilme şemasında gerekli ""%1"" parametresi mevcut değil.'"),
				FieldName);
			ListOfCriticalErrors.Add(ErrorText);
		EndIf;
		For Each AvailableField In Settings.Selection.SelectionAvailableFields.Items Do
			
			If AvailableField.Field = New DataCompositionField("SystemFields")
				Or AvailableField.Field = New DataCompositionField("DataParameters") Then
				
				Continue;
				
			EndIf;
			
			If Not ValueIsFilled(AvailableField.ValueType) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa xác định kiểu giá trị trường ""%1"" trong sơ đồ dàn dựng dữ liệu. Kiểu giá trị không được để trống.';
						|ru = 'Не определен тип значения поля ""%1"" схемы компоновки данных. Тип значения не может быть пустым.';
						|en = 'The value type of the ""%1"" field of the data composition schema is undefined. The value type cannot be empty.'; fa = 'The value type of the ""%1"" field of the data composition schema is undefined. The value type cannot be empty.';
						|it = 'The value type of the ""%1"" field of the data composition schema is undefined. The value type cannot be empty.';
						|pl = 'The value type of the ""%1"" field of the data composition schema is undefined. The value type cannot be empty.';
						|tr = 'Veri inşa edilme şemasının ""%1"" alanının değer tipi tanımlanmadı. Değer tipi boş olamaz.'"),
					AvailableField.Field);
				ListOfCriticalErrors.Add(ErrorText);
			ElsIf AvailableField.ValueType = UnlimitedLengthStringType Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trường ""%1"" có kiểu giá trị ""Xâu ký tự có độ dài không hạn chế"". Cần hạn chế độ dài xâu ký tự.';
						|ru = 'Поле ""%1"" имеет тип значения ""Строка неограниченной длины"". Необходимо ограничить длину строки.';
						|en = 'The ""%1"" field has the ""String of unlimited length"" value type. Limit the string length.'; fa = 'The ""%1"" field has the ""String of unlimited length"" value type. Limit the string length.';
						|it = 'The ""%1"" field has the ""String of unlimited length"" value type. Limit the string length.';
						|pl = 'The ""%1"" field has the ""String of unlimited length"" value type. Limit the string length.';
						|tr = '""%1"" alanı, ""Sınırsız uzunlukta satır"" değer tipine sahiptir. Satırın uzunluğunu sınırlamak gereklidir.'"),
					AvailableField.Field);
				ListOfCriticalErrors.Add(ErrorText);
			EndIf;
			
		EndDo;
	EndIf;
	SchemeContainsCriticalErrors = ListOfCriticalErrors.Count() > 0;
EndProcedure

Function SourceIsAvailable(FullSourceName)
	
	If Not (GetFunctionalOption("UseUserNotificationsOfSystemEvents") 
		And Conversations.CollaborationSystemConnected()) Then
		Return False;
	EndIf;
	
	If UserNotificationsOfEventsCached.SourcesOfNotificationExceptions().Find(FullSourceName) <> Undefined Then
		Return False;
	EndIf;
	
	Return True
	
EndFunction

Function NotificationKindsBySourceAttributes(FullSourceName)
	NotificationKindsBySourceAttributes = New Map;
	
	SourceIdentificator = Common.MetadataObjectID(FullSourceName);
	AvailableNotificationKinds = UserNotificationsOfEventsCached.AvailableNotificationKinds()[SourceIdentificator];
	
	If AvailableNotificationKinds = Undefined Then
		Return NotificationKindsBySourceAttributes;
	EndIf;
	
	For Each NotificationTypeData In AvailableNotificationKinds Do
		ArrayOfViews = NotificationKindsBySourceAttributes.Get(NotificationTypeData.SourceDetails_); // Array
		If ArrayOfViews = Undefined Then
			ArrayOfViews = New Array;
			NotificationKindsBySourceAttributes.Insert(NotificationTypeData.SourceDetails_, ArrayOfViews);
		EndIf;
		ArrayOfViews.Add(NotificationTypeData.NotificationKind);
	EndDo;
	
	Return NotificationKindsBySourceAttributes
	
EndFunction

Function TextEmptyValue(LanguageCode)
	
	Text = NStr("vi = '<Giá trị trống>';
				|ru = '<Пустое значение>';
				|en = '<empty value>'; fa = '<empty value>';
				|it = '<Valore vuoto>';
				|pl = '<pusta wartość>';
				|tr = '<Boş değer>'", LanguageCode);
	
	Return Text
	
EndFunction

Function NameOfListFormByLink(Ref, User)
	FormName = "";
	If Common.RefTypeValue(Ref) Then
		TableName = Common.TableNameByRef(Ref);
		FormName = StrTemplate("%1.%2", TableName, "ListForm");
	EndIf;
	Return FormName
EndFunction

// Constructor of the transition command.
// 
// Returns:
//  Structure - Constructor of the Transition Command:
// * Presentation - String - 
// * ActionName - String - 
// * Data - Structure - :
// ** FormName - String - 
// ** RefsMap - Undefined - 
// ** RefsPresentations - Undefined - 
Function ConstructorOfTransitionCommand()
	
	TransitionCommand = New Structure();
	TransitionCommand.Insert("Presentation", "");
	TransitionCommand.Insert("ActionName", "");
	TransitionCommand.Insert("Data", New Structure("FormName, RefsMap, RefsPresentations",
		"",
		Undefined,
		Undefined));
	
	Return TransitionCommand
	
EndFunction

Function TypesThereIsRegistrar()
	
	Array = New Array;
	Array.Add("РегистрНакопления"); //@NON-NLS-1
	Array.Add("AccumulationRegister"); //@NON-NLS-1
	Array.Add("РегистрБухгалтерии"); //@NON-NLS-1
	Array.Add("AccountingRegister"); //@NON-NLS-1
	Array.Add("РегистрРасчета"); //@NON-NLS-1
	Array.Add("CalculationRegister"); //@NON-NLS-1 
	Array.Add("РегистрСведений"); //@NON-NLS-1
	Array.Add("InformationRegister"); //@NON-NLS-1
	
	Return Array
	
EndFunction

Function InternalUsername()
	Return NStr("vi = 'Thông báo hệ thống';
				|ru = 'Оповещения системы';
				|en = 'System notifications'; fa = 'System notifications';
				|it = 'System notifications';
				|pl = 'System notifications';
				|tr = 'Sistem bildirimleri'", Common.DefaultLanguageCode());
EndFunction

Function ServiceUserIdentifier()
	Return New UUID("10d6b342-4f1c-4a57-88bf-908f31a41f6e");
EndFunction

Function BotUserName()
	Return "UserNotificationsOfEventsBot";
EndFunction

Function GetCreateServiceUser(Name, Id)
	Properties = Users.NewIBUserDetails(, True);
	Properties.Name = Name;
		
	UserRef = Catalogs.Users.GetRef(
		Id);
		
	If Common.RefExists(UserRef) Then
		Return UserRef;
	EndIf;
	
	Try
		IBUser = Users.InfobaseDummyUser(Properties, UserRef);
	Except
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(
			NStr("vi = 'Thông báo cho người sử dụng.Tạo/nhận người sử dụng dịch vụ';
				|ru = 'Оповещения пользователей.Создание/получение служебного пользователя';
				|en = 'User notifications.Create/get utility user'; fa = 'User notifications.Create/get utility user';
				|it = 'User notifications.Create/get utility user';
				|pl = 'User notifications.Create/get utility user';
				|tr = 'Kullanıcı bildirimleri.Dahili kullanıcının oluşturulması/alınması'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Catalogs.Users,,
			ErrorInfo);
		Raise ErrorInfo;
	EndTry;
	
	If IBUser = Undefined 
		Or Not Common.RefExists(UserRef) Then 
		Raise StrTemplate(NStr("ru = 'Не удалось создать служебного пользователя %1';
								|vi = 'Cannot create utility user %1';
								|en = 'Cannot create utility user %1'; fa = 'Cannot create utility user %1';
								|it = 'Cannot create utility user %1';
								|pl = 'Cannot create utility user %1';
								|tr = '%1 hizmet kullanıcısı oluşturulamadı'"), Name);
	EndIf;
	
	Return UserRef;
EndFunction

Function InitializeSourceDataTable()
	Table = New ValueTable;
	Table.Columns.Add("NotificationSource", Common.AllRefsTypeDetails());
	Table.Columns.Add("NotificationInitiator", New TypeDescription("CatalogRef.Users"));
	Table.Columns.Add("RecordID", New TypeDescription("UUID"));
	Table.Columns.Add("NotificationKind", New TypeDescription("CatalogRef.UserNotificationKinds"));
	
	Return Table
EndFunction

Function IssueLine(ParameterName, ParameterValue, FieldAppearance, LanguageCode)
	
	ParameterValType = TypeOf(ParameterValue);
	IsReference = Common.IsReference(ParameterValType);
	ParameterPresentation = String(ParameterValue);
	
	Font = Undefined;
	TextColor = Undefined;
	BackColor = Undefined;
	
	If ValueIsFilled(FieldAppearance) Then
		If FieldAppearance.Property("Format") Then
			ParameterPresentation = Format(ParameterValue, FieldAppearance.Format);
		EndIf;
		If FieldAppearance.Property("Font") Then
			Font = FieldAppearance.Font;
		EndIf;
		If FieldAppearance.Property("TextColor") Then
			TextColor = FieldAppearance.TextColor;
		EndIf;
		If FieldAppearance.Property("BackColor") Then
			BackColor = FieldAppearance.BackColor;
		EndIf;
	EndIf;
	If IsBlankString(ParameterPresentation) Then
		ParameterPresentation = TextEmptyValue(LanguageCode);
	EndIf;
	
	If IsReference Then
		
		If Documents.AllRefsType().ContainsType(ParameterValType) Then
			ParameterPresentation = PresentationOfDocument(ParameterValue, LanguageCode);
		EndIf;
		
		Try
			URL = GetURL(ParameterValue);
			LinkString_ = New FormattedString(ParameterPresentation, Font, TextColor, BackColor, URL);
		Except
			// A type has arrived that you can't get a navigation link from. Output a line without a hyperlink.
			LinkString_ = New FormattedString(ParameterPresentation, Font, TextColor, BackColor);
		EndTry;
	Else
		LinkString_ = New FormattedString(ParameterPresentation, Font, TextColor, BackColor);
	EndIf;
	
	Return LinkString_
	
EndFunction

Procedure AddDataHandlerToUpgradeToNewVersion(Handlers)
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "UserNotificationsOfEvents.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("a7e59df8-6b10-4dec-9136-3fb4d15c11cc");
	Handler.Comment = NStr("vi = 'Điền phần tử danh mục ""Dạng thông báo cho người sử dụng"".';
							|ru = 'Заполняет элементы справочника ""Виды оповещений пользователей"".';
							|en = 'Fills the items of the ""User notification kinds"" catalog.'; fa = 'Fills the items of the ""User notification kinds"" catalog.';
							|it = 'Fills the items of the ""User notification kinds"" catalog.';
							|pl = 'Fills the items of the ""User notification kinds"" catalog.';
							|tr = '""Kullanıcı bildirimlerinin türleri"" kataloğunun öğelerini doldurur.'");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.UserNotificationKinds.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

Function IdTelegramTemporaryCodes()
	
	Return "UserNotificationsOfSystemEvents.TelegramTemporaryCodes"
	
EndFunction

Function TelegramTemporaryCodeExpirationDate()
	
	Return 600; // Seconds
	
EndFunction

Function TelegramTemporaryCodeLength()
	
	Return 6;
	
EndFunction

Function NotificationRecipientDataById(Val ConversationID, NotificationMethod)
	
	If TypeOf(ConversationID) <> Type("String") Then
		ConversationID = String(ConversationID);
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	|	NotificationsRecipients.User AS User,
	|	NotificationsRecipients.NotificationMethod AS NotificationMethod,
	|	NotificationsRecipients.Use AS Use
	|FROM
	|	InformationRegister.UserNotificationsRecipients AS NotificationsRecipients
	|WHERE
	|	NotificationsRecipients.NotificationAddress = &ConversationID
	|	AND NotificationsRecipients.NotificationMethod = &NotificationMethod";
	Query.SetParameter("ConversationID", ConversationID);
	Query.SetParameter("NotificationMethod", NotificationMethod);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Return Result.Unload();
	
EndFunction

Function UserByTelegramTemporaryCode(Val TemporaryCode)
	
	If Not ThisIsTemporaryCode(TemporaryCode) Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	StorageData = Common.ReadDataFromSecureStorage(IdTelegramTemporaryCodes(), Undefined);
	SetPrivilegedMode(False);
	
	If StorageData = Undefined Then
		Return Undefined;
	EndIf;
	
	KeysToDelete = "";
	User = Undefined;
	For Each StructureData In StorageData Do
		UserIdentifier = StrReplace(StructureData.Key, "_", "-");
		UserIdentifier = Right(UserIdentifier, StrLen(UserIdentifier) - 1);
		CurrentDateInMilliseconds = CurrentUniversalDateInMilliseconds();
		If User = Undefined
			And TemporaryCode = StructureData.Value.Code
			And CurrentDateInMilliseconds < StructureData.Value.ValidityPeriod Then
				
				User = Catalogs.Users.GetRef(New UUID(UserIdentifier));
				
		EndIf;
		
		If CurrentDateInMilliseconds >= StructureData.Value.ValidityPeriod Then
			KeysToDelete = KeysToDelete + ", " + StructureData.Key;
		EndIf;
		
	EndDo;
	
	If KeysToDelete <> "" Then
		SetPrivilegedMode(True);
		Common.DeleteDataFromSecureStorage(IdTelegramTemporaryCodes(), KeysToDelete);
		SetPrivilegedMode(False);
	EndIf;
	
	Return User
	
EndFunction

Function ThisIsTemporaryCode(TemporaryCode)
	
	RegularExpressionCode = StrTemplate("^[a-z]{%1}$", TelegramTemporaryCodeLength()); //@Non-NLS-1
	ThisIsTemporaryCode = StrLikeByRegularExpression(String(TemporaryCode), 
		RegularExpressionCode,
		False);
	
	Return ThisIsTemporaryCode;
	
EndFunction

Function NotificationRecipientsAtExternalSystem(Users)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	UserNotificationsRecipients.User AS User,
	|	UserNotificationsRecipients.NotificationAddress AS NotificationAddress
	|FROM
	|	InformationRegister.UserNotificationsRecipients AS UserNotificationsRecipients
	|WHERE
	|	&UseUserNotificationsViaTelegram
	|	AND UserNotificationsRecipients.User IN (&Users)
	|	AND UserNotificationsRecipients.NotificationMethod = VALUE(Enum.UserNotificationsMethods.Telegram)
	|	AND UserNotificationsRecipients.Use
	|	AND NOT UserNotificationsRecipients.NotificationAddress LIKE """"
	|TOTALS
	|BY
	|	User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	UserNotificationsRecipients.User AS User,
	|	UserNotificationsRecipients.NotificationAddress AS NotificationAddress
	|INTO RecipientsByMail
	|FROM
	|	InformationRegister.UserNotificationsRecipients AS UserNotificationsRecipients
	|WHERE
	|	&SendingToEmailIsAvailable
	|	AND UserNotificationsRecipients.User IN (&Users)
	|	AND UserNotificationsRecipients.NotificationMethod = VALUE(Enum.UserNotificationsMethods.Email)
	|	AND UserNotificationsRecipients.Use
	|
	|INDEX BY
	|	User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	UsersContacts.Ref AS User,
	|	UsersContacts.EMAddress AS Email
	|FROM
	|	RecipientsByMail AS Recipients
	|		INNER JOIN Catalog.Users.ContactInformation AS UsersContacts
	|		ON Recipients.User = UsersContacts.Ref
	|WHERE
	|	UsersContacts.Kind = VALUE(Catalog.ContactInformationKinds.UserEmail)
	|	AND UsersContacts.Type = VALUE(Enum.ContactInformationTypes.Email)
	|	AND NOT UsersContacts.EMAddress LIKE """"
	|
	|UNION
	|
	|SELECT
	|	Recipients.User AS User,
	|	Recipients.NotificationAddress AS Email
	|FROM
	|	RecipientsByMail AS Recipients
	|WHERE
	|	NOT Recipients.NotificationAddress LIKE """"
	|TOTALS
	|BY
	|	User";
	
	Query.SetParameter("Users", Users);
	Query.SetParameter("UseUserNotificationsViaTelegram",
		GetFunctionalOption("UseUserNotificationsViaTelegram"));
	Query.SetParameter("SendingToEmailIsAvailable",
		SendingToEmailIsAvailable());
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Recipients = New Map;
	
	NotificationsAddresses = New Structure();
	NotificationsAddresses.Insert("AddressesOfMail", New Array);
	NotificationsAddresses.Insert("IntegrationAddresses", New Array);
	
	SelectionMessengers = QueryBatch[0].Select(QueryResultIteration.ByGroups);
	While SelectionMessengers.Next() Do
		AddressesSelection = SelectionMessengers.Select();
		UserAddresses = Recipients.Get(SelectionMessengers.User);
		If UserAddresses = Undefined Then
			UserAddresses = UserNotificationAddressConstructor();
			Recipients.Insert(SelectionMessengers.User, UserAddresses);
		EndIf;
		While AddressesSelection.Next() Do
			NotificationAddress = AddressesSelection.NotificationAddress;
			If UserAddresses.IntegrationAddresses.Find(AddressesSelection.NotificationAddress) = Undefined Then
				UserAddresses.IntegrationAddresses.Add(NotificationAddress);
			EndIf;
		EndDo;
		
	EndDo;
	
	SelectionMail = QueryBatch[2].Select(QueryResultIteration.ByGroups);
	While SelectionMail.Next() Do
		AddressesSelection = SelectionMail.Select();
		UserAddresses = Recipients.Get(SelectionMail.User);
		If UserAddresses = Undefined Then
			UserAddresses = UserNotificationAddressConstructor();
			Recipients.Insert(SelectionMail.User, UserAddresses);
		EndIf;
		While AddressesSelection.Next() Do
			Email = AddressesSelection.Email;
			If UserAddresses.AddressesOfMail.Find(AddressesSelection.Email) = Undefined Then
				UserAddresses.AddressesOfMail.Add(Email);
			EndIf;
		EndDo;
	EndDo;
	
	Return Recipients;
	
EndFunction

Function NotificationMethodByDiscussion(ConversationID)
	
	NotificationMethod = Enums.UserNotificationsMethods.EmptyRef();
	
	Try
		SetPrivilegedMode(True);
		CSDiscussion = CollaborationSystem.GetConversation(ConversationID);
		IntegrationOfCS = CollaborationSystem.GetIntegration(CSDiscussion.Integration);
		ExternalSystemType = IntegrationOfCS.ExternalSystemType;
		NotificationMethod = NotificationMethodByTypeOfExternalSystem(ExternalSystemType);
		SetPrivilegedMode(False);
	Except
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteLogEvent(NStr(
			"ru = 'Оповещения пользователей.Получение типа внешней системы';
			|vi = 'User notifications.Getting external system type';
			|en = 'User notifications.Getting external system type'; fa = 'User notifications.Getting external system type';
			|it = 'User notifications.Getting external system type';
			|pl = 'User notifications.Getting external system type';
			|tr = 'Kullanıcı bildirimleri.Harici sistem türünün alınması'",
			Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
	EndTry;
	
	Return NotificationMethod;
	
EndFunction

Function NotificationMethodByTypeOfExternalSystem(Val ExternalSystemType)
	
	NotificationMethod = Enums.UserNotificationsMethods.EmptyRef();
	
	If Upper(ExternalSystemType) = "TELEGRAM" Then
		NotificationMethod = Enums.UserNotificationsMethods.Telegram;
	EndIf;
	
	Return NotificationMethod
	
EndFunction

Function UserNotificationAddressConstructor()
	
	NotificationsAddresses = New Structure();
	NotificationsAddresses.Insert("AddressesOfMail", New Array);
	NotificationsAddresses.Insert("IntegrationAddresses", New Array);
	
	Return NotificationsAddresses;
	
EndFunction

Function SendingToEmailIsAvailable()
	
	SendingAvailable = False;
	UseUserNotificationsByEmail = GetFunctionalOption("UseUserNotificationsByEmail");
	SetPrivilegedMode(True);
	If UseUserNotificationsByEmail And Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperations = Common.CommonModule("EmailOperations");
		SystemEmailAccountIsSetUp = ModuleEmailOperations.AccountSetUp(
			ModuleEmailOperations.SystemAccount(), True, False);
		SendingAvailable = SystemEmailAccountIsSetUp
			And UseUserNotificationsByEmail;
	EndIf;
	SetPrivilegedMode(False);
	
	Return SendingAvailable;

EndFunction

Function NameOfConfiguration()
	
	SetPrivilegedMode(True);
	
	Result = Constants.SystemTitle.Get();
	
	If IsBlankString(Result) Then
		
		Result = Metadata.Synonym;
		
	EndIf;
	
	Return TrimAll(Result);
	
EndFunction

Function ParametersOfInfobasePublication()
	
	PublicationParameters = New Structure;
	
	PublicationParameters.Insert("SystemTitle", NameOfConfiguration());
	PublicationParameters.Insert("InfobaseInternetAddress", Common.InfobasePublicationURL());
	PublicationParameters.Insert("InfobaseLocalAddress", Common.LocalInfobasePublishingURL());
	
	Return PublicationParameters
	
EndFunction

Function URLForNotificationContext(Ref, ReportDistributionParameters)
	
	IBPublicationURL = "";
	WebPublishing = False;
	URL = GetURL(Ref);
	If ValueIsFilled(ReportDistributionParameters.InfobaseLocalAddress) Then
		IBPublicationURL = ReportDistributionParameters.InfobaseLocalAddress;
	ElsIf ValueIsFilled(ReportDistributionParameters.InfobaseInternetAddress) Then
		IBPublicationURL = ReportDistributionParameters.InfobaseInternetAddress;
		WebPublishing = True;
	Else
		Return URL;
	EndIf;
	
	IBPublicationURL = TrimAll(IBPublicationURL);
	
	If WebPublishing And Right(IBPublicationURL,1)<> "/" Then
		IBPublicationURL = IBPublicationURL + "/";
	EndIf;
	
	Return IBPublicationURL + "#" + URL;
	
EndFunction

Procedure AddLinkToEmailBody(Text, Ref, RepresentationOfTheReference, PublicationParameters)
	
	HyperlinkAnchorText = RepresentationOfTheReference + Chars.LF;
	HyperlinkAnchorText = HyperlinkAnchorText + URLForNotificationContext(
		Ref,
		PublicationParameters) + Chars.LF;
	
	Text = Text + Chars.LF + HyperlinkAnchorText;
	
EndProcedure

Function SendMail(EmailSubject, EmailText, RecipientEmailAddress)
	
	EmailSent = False;
	
	EmailParameters = New Structure;
	EmailParameters.Insert("Subject", EmailSubject);
	EmailParameters.Insert("Body", EmailText);
	EmailParameters.Insert("Whom", RecipientEmailAddress);
	
	ModuleEmailOperations = Common.CommonModule("EmailOperations");
	
	Account = ModuleEmailOperations.SystemAccount();
	
	MailMessage = ModuleEmailOperations.PrepareEmail(Account, EmailParameters);
	Try
		ModuleEmailOperations.SendMail(Account, MailMessage);
		EmailSent = True;
	Except
		WriteLogEvent(NStr("ru = 'Оповещения пользователей.Отправка оповещений по электронной почте';
							|vi = 'User notifications.Sending notifications by email';
							|en = 'User notifications.Sending notifications by email'; fa = 'User notifications.Sending notifications by email';
							|it = 'User notifications.Sending notifications by email';
							|pl = 'User notifications.Sending notifications by email';
							|tr = 'Kullanıcı bildirimleri.E-posta yoluyla bildirim gönderimi'",
			Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Оповещения не отправлены по причине:
				|%1';
				|vi = 'Notifications are not sent due to:
				|%1';
				|en = 'Notifications are not sent due to:
				|%1'; fa = 'Notifications are not sent due to:
				|%1';
				|it = 'Notifications are not sent due to:
				|%1';
				|pl = 'Notifications are not sent due to:
				|%1';
				|tr = 'Bildirimler şu nedenlerle gönderilmedi:
				|%1'"), 
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
	EndTry;
	
	Return EmailSent
	
EndFunction

Function FindBots()
	
	SetPrivilegedMode(True);
	BotMetadata = Metadata.Bots.UserNotificationsOfEvents;
	Bots = CollaborationSystem.GetBots();
	FoundBots = New Array;
	
	For Each Bot In Bots Do
		If Bot.Metadata = BotMetadata Then
			FoundBots.Add(Bot);;
		EndIf;
	EndDo;
	
	Return FoundBots;
	
EndFunction

#EndRegion
