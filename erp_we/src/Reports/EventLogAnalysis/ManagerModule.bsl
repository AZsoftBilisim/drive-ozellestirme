///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ReportsOptions

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	If Not AccessRight("View", Metadata.Reports.EventLogAnalysis)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	AddCommand = False;
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm" Then
		
		Command = ReportsCommands.Add();
		Command.Presentation = NStr("vi = 'Phân tích hoạt động của người dùng';
									|ru = 'Анализ активности пользователей';
									|en = 'Summary user activity'; fa = 'خلاصه فعالیت کاربر';
									|it = 'Analisi dell''attività utenti';
									|pl = 'Analiza aktywności użytkownika';
									|tr = 'Kullanıcıların etkinlik analizi'");
		Command.VariantKey = "UsersActivityAnalysis";
		Command.MultipleChoice = True;
		Command.Manager = "Report.EventLogAnalysis";
		Command.OnlyInAllActions = True;
		Command.Importance = "SeeAlso";
		
		If Users.IsDepartmentUsed() Then
			Command = ReportsCommands.Add();
			Command.Presentation = NStr("vi = 'Phân tích hoạt động của bộ phận';
										|ru = 'Анализ активности подразделений';
										|en = 'Department activity'; fa = 'فعالیت دپارتمان';
										|it = 'Анализ активности подразделений';
										|pl = 'Department activity';
										|tr = 'Departman faaliyetinin analizi'");
			Command.VariantKey = "DepartmentActivityAnalysis";
			Command.MultipleChoice = True;
			Command.Manager = "Report.EventLogAnalysis";
			Command.OnlyInAllActions = True;
			Command.Importance = "SeeAlso";
		EndIf;
		
		AddCommand = True;
		
	ElsIf Parameters.FormName = "Catalog.Users.Form.ItemForm" Then
		AddCommand = True;
	EndIf;
	
	If Not AddCommand Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = NStr("vi = 'Phân tích hoạt động của người dùng';
								|ru = 'Анализ активности пользователя';
								|en = 'User activity'; fa = 'فعالیت کاربر';
								|it = 'Анализ активности пользователя';
								|pl = 'User activity';
								|tr = 'Kullanıcıların etkinlik analizi'");
	Command.VariantKey = "UserActivity";
	Command.MultipleChoice = False;
	Command.Manager = "Report.EventLogAnalysis";
	Command.OnlyInAllActions = True;
	Command.Importance = "SeeAlso";
	
EndProcedure

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings.DefineFormSettings = True;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	SubsystemForAdministration = Metadata.Subsystems.Find("Administration");
	SubsystemForMonitoring = ?(SubsystemForAdministration = Undefined, Undefined,
		SubsystemForAdministration.Subsystems.Find("UserMonitoring"));
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersActivityAnalysis");
	If SubsystemForMonitoring <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForMonitoring, "");
	EndIf;
	OptionSettings.LongDesc =
		NStr("vi = 'Cho phép bạn theo dõi hoạt động của người dùng trong ứng dụng (mức độ chuyên sâu và với những đối tượng mà người dùng hoạt động).';
			|ru = 'Позволяет выполнять мониторинг активности пользователей в приложении (насколько интенсивно и с какими объектами работают пользователи).';
			|en = 'User activity (total load and affected objects).'; fa = 'User activity (total load and affected objects).';
			|it = 'Позволяет выполнять мониторинг активности пользователей в приложении (насколько интенсивно и с какими объектами работают пользователи).';
			|pl = 'User activity (total load and affected objects).';
			|tr = 'Uygulamadaki kullanıcı aktivitesinin izlenmesini 
			|sağlar (kullanıcıların ne kadar yoğun ve hangi nesnelerle çalıştığı).'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DepartmentActivityAnalysis");
	OptionSettings.Enabled = Users.IsDepartmentUsed();
	If SubsystemForMonitoring <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForMonitoring, "");
	EndIf;
	OptionSettings.LongDesc =
		NStr("vi = 'Cho phép bạn theo dõi hoạt động của người dùng trong ứng dụng (mức độ chuyên sâu và với những đối tượng mà người dùng hoạt động).';
			|ru = 'Позволяет выполнять мониторинг активности подразделений в приложении (насколько интенсивно и с какими объектами работают пользователи подразделений).';
			|en = 'Department activity (total load and affected objects).'; fa = 'Department activity (total load and affected objects).';
			|it = 'Позволяет выполнять мониторинг активности подразделений в приложении (насколько интенсивно и с какими объектами работают пользователи подразделений).';
			|pl = 'Department activity (total load and affected objects).';
			|tr = 'Uygulamadaki departmanların faaliyetlerini (departman kullanıcılarının ne kadar yoğun ve hangi nesnelerle çalıştığını) izlemenizi sağlar.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UserActivity");
	If SubsystemForMonitoring <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForMonitoring, "");
	EndIf;
	OptionSettings.LongDesc =
		NStr("vi = 'Thông tin chi tiết về đối tượng mà người dùng đã làm việc với trong ứng dụng.';
			|ru = 'Подробная информация о том, с какими объектами работал пользователь в приложении.';
			|en = 'Objects affected by user activities (detailed).'; fa = 'Objects affected by user activities (detailed).';
			|it = 'Подробная информация о том, с какими объектами работал пользователь в приложении.';
			|pl = 'Objects affected by user activities (detailed).';
			|tr = 'Kullanıcının uygulamada çalıştığı nesneler hakkında ayrıntılı bilgi.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "EventLogMonitor");
	OptionSettings.SearchSettings.TemplatesNames = "EvengLogErrorReportTemplate";
	If SubsystemForAdministration <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForAdministration, "");
	EndIf;
	OptionSettings.LongDesc = NStr("vi = 'Danh sách các bản ghi quan trọng trong nhật ký sự kiện.';
									|ru = 'Список критичных записей журнала регистрации.';
									|en = 'Critical events in the system event log.'; fa = 'Critical events in the system event log.';
									|it = 'Elenco delle voci di registro critiche.';
									|pl = 'Lista krytycznych wpisów dziennika rejestracji.';
									|tr = 'Olay günlüğündeki kritik girişlerin listesi.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ScheduledJobsDuration");
	OptionSettings.SearchSettings.TemplatesNames = "ScheduledJobsDuration, ScheduledJobsDetails";
	OptionSettings.Enabled = Not Common.DataSeparationEnabled();
	If SubsystemForAdministration <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForAdministration, "");
	EndIf;
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị lịch biểu thực hiện nhiệm vụ thường kỳ trong ứng dụng.';
									|ru = 'Выводит график выполнения регламентных заданий в приложении.';
									|en = 'Job schedules.'; fa = 'Job schedules.';
									|it = 'Выводит график выполнения регламентных заданий в приложении.';
									|pl = 'Job schedules.';
									|tr = 'Uygulamada zamanlanmış görev programını görüntüler.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// Gets logged user activities for the given period.
// 
//
// Parameters:
//    ReportParameters - Structure:
//    * StartDate          - Date   - Beginning of the reporting period.
//    * EndDate       - Date   - End of the reporting period.
//    * User        - String - The name of the user whose activity is being analyzed.
//                                     Intended for the "User activity" report option.
//    * UsersAndGroups - ValueList - A value is user groups or users
//                                     whose activity is being analyzed.
//                                     Intended for the "Summary user activity" report option.
//    * ReportVariant       - String - "UserActivity" or "UsersActivityAnalysis".
//    * OutputTasks      - Boolean - Flag indicating whether to get data on tasks from the event log.
//    * OutputCatalogs - Boolean - Flag indicating whether to get data on catalogs from the event log.
//    * OutputDocuments   - Boolean - Flag indicating whether to get data on documents from the event log.
//    * OutputBusinessProcesses - Boolean - Flag indicating whether to get data on business processes from the event log.
//
// Returns:
//  ValueTable - An ungrouped table with logged user activities.
//     
//
Function EventLogData1(ReportParameters) Export
	
	// Prepare report parameters.
	StartDate = ReportParameters.StartDate;
	EndDate = ReportParameters.EndDate;
	User = ReportParameters.User;
	UsersAndGroups = ReportParameters.UsersAndGroups;
	Department = ReportParameters.Department;
	ReportVariant = ReportParameters.ReportVariant;
	
	If ReportVariant = "UserActivity" Then
		ShouldOutputUtilityUsers = True;
		OutputBusinessProcesses = ReportParameters.OutputBusinessProcesses;
		OutputTasks = ReportParameters.OutputTasks;
		OutputCatalogs = ReportParameters.OutputCatalogs;
		OutputDocuments = ReportParameters.OutputDocuments;
	Else
		ShouldOutputUtilityUsers = ReportParameters.ShouldOutputUtilityUsers;
		OutputCatalogs = True;
		OutputDocuments = True;
		OutputBusinessProcesses = False;
		OutputTasks = False;
	EndIf;
	
	// Generate a source data table.
	RawData = New ValueTable();
	RawData.Columns.Add("Date", New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	RawData.Columns.Add("Week", New TypeDescription("String", , New StringQualifiers(10)));
	RawData.Columns.Add("User");
	RawData.Columns.Add("Department");
	RawData.Columns.Add("DepartmentPresentation");
	RawData.Columns.Add("WorkHours", New TypeDescription("Number", New NumberQualifiers(15,4)));
	RawData.Columns.Add("StartsCount", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("DocumentsCreated", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("CatalogsCreated", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("DocumentsChanged", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("BusinessProcessesCreated",	New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("TasksCreated", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("BusinessProcessesChanged", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("TasksChanged", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("CatalogsChanged",	New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("Errors1", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("Warnings", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("ObjectKind", New TypeDescription("String", , New StringQualifiers(50)));
	RawData.Columns.Add("CatalogDocumentObject");
	
	// Calculate the concurrent session limit.
	ConcurrentSessionsData = New ValueTable();
	ConcurrentSessionsData.Columns.Add("ConcurrentUsersDate",
		New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	ConcurrentSessionsData.Columns.Add("ConcurrentUsers",
		New TypeDescription("Number", New NumberQualifiers(10)));
	ConcurrentSessionsData.Columns.Add("ConcurrentUsersList");
	
	EventLogData = New ValueTable;
	
	Levels = New Array;
	Levels.Add(EventLogLevel.Information);
	
	Events = New Array;
	Events.Add("_$Session$_.Start"); //  Start session.
	Events.Add("_$Session$_.Finish"); //  End session.  
	Events.Add("_$Data$_.New"); // Add data
	Events.Add("_$Data$_.Update"); // Modify data.
	
	ApplicationName = New Array;
	ApplicationName.Add("1CV8C");
	ApplicationName.Add("WebClient");
	ApplicationName.Add("1CV8");
	ApplicationName.Add("BackgroundJob");
	ApplicationName.Add("MobileClient");
	ApplicationName.Add("HTTPServiceConnection");
	ApplicationName.Add("WSConnection");
	ApplicationName.Add("ODataConnection");
	ApplicationName.Add("COMConnection");
	
	DatesInServerTimeZone = CommonClientServer.StructureProperty(ReportParameters,
		"DatesInServerTimeZone", False);
	If DatesInServerTimeZone Then
		ServerTimeOffset = 0;
	Else
		ServerTimeOffset = EventLog.ServerTimeOffset();
	EndIf;
	
	UserFilter = New Array;
	SelectedDivisions = Undefined;
	UserDepartments = Undefined;
	
	// Get a user list.
	If ReportVariant = "UserActivity" Then
		UserFilter.Add(UserForSelection(User));
	ElsIf ReportVariant = "DepartmentActivityAnalysis" Then
		SelectedDivisions = SelectedDivisions(Department);
		UserDepartments = UserDepartments(StartDate,
			ServerTimeOffset, SelectedDivisions);
		FillUsersForAnalysisFromDepartment(UserFilter,
			SelectedDivisions, UserDepartments);
	Else
		FillUsersForAnalysis(UserFilter, UsersAndGroups);
	EndIf;
	
	If UserFilter.Count() = 0 Then
		Return New Structure("UsersActivityAnalysis, ConcurrentSessionsData, ReportIsBlank",
			RawData, ConcurrentSessionsData, True);
	EndIf;
	
	EventLogFilter = New Structure;
	EventLogFilter.Insert("StartDate", StartDate + ServerTimeOffset);
	EventLogFilter.Insert("EndDate", EndDate + ServerTimeOffset);
	EventLogFilter.Insert("ApplicationName", ApplicationName);
	EventLogFilter.Insert("Level", Levels);
	EventLogFilter.Insert("Event", Events);
	
	If UserFilter.Find("AllUsers") = Undefined Then
		EventLogFilter.Insert("User", UserFilter);
	Else
		UserFilter = Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	UnloadEventLog(EventLogData, EventLogFilter);
	SetPrivilegedMode(False);
	
	ReportIsBlank = (EventLogData.Count() = 0);
	
	// Add a UUID—UserRef map for future use.
	UsersIDsMap = UsersUUIDs(EventLogData,
		ShouldOutputUtilityUsers);
	
	Sessions = New ValueTable;
	Sessions.Columns.Add("SessionNumber");
	Sessions.Columns.Add("StartingEvent");
	Sessions.Columns.Add("FinishingEvent");
	Sessions.Columns.Add("User");
	Sessions.Columns.Add("Department");
	Sessions.Columns.Add("DepartmentPresentation");
	Sessions.Columns.Add("SessionFirstEventDate");
	Sessions.Columns.Add("SessionLastEventDate");
	Sessions.Indexes.Add("SessionNumber");
	
	// Count data required for the report.
	For Each EventLogDataRow In EventLogData Do
		EventLogDataRow.Date = EventLogDataRow.Date - ServerTimeOffset;
		
		If Not ValueIsFilled(EventLogDataRow.Session)
			Or Not ValueIsFilled(EventLogDataRow.Date) Then
			Continue;
		EndIf;
		
		UsernameRef = UsersIDsMap[EventLogDataRow.User];
		If UsernameRef = Undefined Then
			Continue;
		EndIf;
		IBUserDepartment = New Structure("Department, DepartmentPresentation");
		If UserDepartments <> Undefined Then
			PopulateIBUserDepartment(IBUserDepartment, EventLogDataRow.Date,
				EventLogDataRow.User, UserDepartments);
			If SelectedDivisions <> Undefined
			   And SelectedDivisions.Find(IBUserDepartment.Department) = Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		// Prepare for estimating user session time and the number of app startups.
		Session = Sessions.Find(EventLogDataRow.Session, "SessionNumber");
		IsSessionAdded = False;
		If EventLogDataRow.Event = "_$Session$_.Start" Then
			If Session <> Undefined Then
				Session.SessionNumber = Undefined;
			EndIf;
			Session = Sessions.Add();
			Session.SessionNumber   = EventLogDataRow.Session;
			Session.StartingEvent = EventLogDataRow;
			IsSessionAdded = True;
			
		ElsIf EventLogDataRow.Event = "_$Session$_.Finish" Then
			If Session = Undefined Then
				Session = Sessions.Add();
				IsSessionAdded = True;
			EndIf;
			Session.SessionNumber = Undefined;
			Session.FinishingEvent = EventLogDataRow;
		Else
			If Session = Undefined Then
				Session = Sessions.Add();
				Session.SessionFirstEventDate = EventLogDataRow.Date;
				IsSessionAdded = True;
			EndIf;
			Session.SessionLastEventDate = EventLogDataRow.Date;
		EndIf;
		If IsSessionAdded Then
			Session.User = UsernameRef;
			FillPropertyValues(Session, IBUserDepartment);
		EndIf;

		EventMetadata = EventLogDataRow.Metadata;
		SourceDataString = Undefined;
		
		// Count created documents and catalogs.
		If EventLogDataRow.Event = "_$Data$_.New" Then
			If StrFind(EventMetadata, "Document.") > 0 And OutputDocuments Then
				SourceDataString = RawData.Add();
				SourceDataString.DocumentsCreated = 1;
			EndIf;
			If StrFind(EventMetadata, "Catalog.") > 0 And OutputCatalogs Then
				SourceDataString = RawData.Add();
				SourceDataString.CatalogsCreated = 1;
			EndIf;
		EndIf;
		
		// Count modified documents and catalogs.
		If EventLogDataRow.Event = "_$Data$_.Update" Then
			If StrFind(EventMetadata, "Document.") > 0 And OutputDocuments Then
				SourceDataString = RawData.Add();
				SourceDataString.DocumentsChanged = 1;
			EndIf;
			If StrFind(EventMetadata, "Catalog.") > 0 And OutputCatalogs Then
				SourceDataString = RawData.Add();
				SourceDataString.CatalogsChanged = 1;
			EndIf;
		EndIf;
		
		// Count created business processes and tasks.
		If EventLogDataRow.Event = "_$Data$_.New" Then
			If StrFind(EventMetadata, "BusinessProcess.") > 0  And OutputBusinessProcesses Then
				SourceDataString = RawData.Add();
				SourceDataString.BusinessProcessesCreated = 1;
			EndIf;
			If StrFind(EventMetadata, "Task.") > 0 And OutputTasks Then
				SourceDataString = RawData.Add();
				SourceDataString.TasksCreated = 1;
			EndIf;
		EndIf;
		
		// Count modified business processes and tasks.
		If EventLogDataRow.Event = "_$Data$_.Update" Then
			If StrFind(EventMetadata, "BusinessProcess.") > 0 And OutputBusinessProcesses Then
				SourceDataString = RawData.Add();
				SourceDataString.BusinessProcessesChanged = 1;
			EndIf;
			If StrFind(EventMetadata, "Task.") > 0 And OutputTasks Then
				SourceDataString = RawData.Add();
				SourceDataString.TasksChanged = 1;
			EndIf;
		EndIf;
		
		If SourceDataString <> Undefined Then
			SourceDataString.Date = EventLogDataRow.Date;
			SourceDataString.Week = WeekOfYearString(EventLogDataRow.Date); 
			SourceDataString.ObjectKind = EventLogDataRow.MetadataPresentation;
			SourceDataString.CatalogDocumentObject = EventLogDataRow.Data;
			SourceDataString.User = UsernameRef;
			FillPropertyValues(SourceDataString, IBUserDepartment);
		EndIf;
		
	EndDo;
	
	// Calculate the startup number and user session durations.
	For Each Session In Sessions Do
		If Session.StartingEvent <> Undefined Then
			Begin = Session.StartingEvent.Date;
		ElsIf ValueIsFilled(Session.SessionFirstEventDate) Then
			Begin = Session.SessionFirstEventDate;
		Else
			Begin = Session.FinishingEvent.Date;
		EndIf;
		If Session.FinishingEvent <> Undefined Then
			End = Session.FinishingEvent.Date;
		ElsIf ValueIsFilled(Session.SessionLastEventDate) Then
			End = Session.SessionLastEventDate;
		Else
			End = Begin;
		EndIf;
		StartsCount = 1;
		Continue_ = True;
		While Continue_ Do
			Date = Begin;
			If BegOfDay(Begin) < BegOfDay(End) Then
				Begin = BegOfDay(Begin) + 86400;
				WorkHours = (Begin - Date) / 3600;
			Else
				Continue_ = False;
				WorkHours = (End - Begin) / 3600;
			EndIf;
			SourceDataString = RawData.Add();
			SourceDataString.Date = Date;
			SourceDataString.Week = WeekOfYearString(Date);
			SourceDataString.User = Session.User;
			SourceDataString.Department = Session.Department;
			SourceDataString.DepartmentPresentation = Session.DepartmentPresentation;
			SourceDataString.StartsCount = StartsCount;
			SourceDataString.WorkHours = ?(WorkHours = 0, 0.0001, WorkHours);
			StartsCount = 0;
		EndDo;
	EndDo;
	
	If ReportVariant = "UsersActivityAnalysis" Then
	
		UsersArray 	= New Array;
		MaxUsersArray = New Array;
		ConcurrentUsers  = 0;
		Counter                 = 0;
		CurrentDate             = Undefined;
		
		For Each EventLogDataRow In EventLogData Do
			
			If Not ValueIsFilled(EventLogDataRow.Date) Then
				Continue;
			EndIf;
			
			UsernameRef = UsersIDsMap[EventLogDataRow.User];
			If UsernameRef = Undefined Then
				Continue;
			EndIf;
			
			ConcurrentUsersDate = BegOfDay(EventLogDataRow.Date);
			
			// For a new date, clear all data on concurrent sessions data fill in data on the previous date.
			If CurrentDate <> ConcurrentUsersDate Then
				If ConcurrentUsers <> 0 Then
					GenerateConcurrentSessionsRow(ConcurrentSessionsData, MaxUsersArray, 
						ConcurrentUsers, CurrentDate);
				EndIf;
				ConcurrentUsers = 0;
				Counter    = 0;
				UsersArray.Clear();
				CurrentDate = ConcurrentUsersDate;
			EndIf;
			
			If EventLogDataRow.Event = "_$Session$_.Start" Then
				Counter = Counter + 1;
				UsersArray.Add(UsernameRef);
			ElsIf EventLogDataRow.Event = "_$Session$_.Finish" Then
				UserIndex = UsersArray.Find(UsernameRef);
				If Not UserIndex = Undefined Then 
					UsersArray.Delete(UserIndex);
					Counter = Counter - 1;
				EndIf;
			EndIf;
			
			// Read the counter value and compare it against the cap.
			Counter = Max(Counter, 0);
			If Counter > ConcurrentUsers Then
				MaxUsersArray = New Array;
				For Each Item In UsersArray Do
					MaxUsersArray.Add(Item);
				EndDo;
			EndIf;
			ConcurrentUsers = Max(ConcurrentUsers, Counter);
			
		EndDo;
		
		If ConcurrentUsers <> 0 Then
			GenerateConcurrentSessionsRow(ConcurrentSessionsData, MaxUsersArray, 
				ConcurrentUsers, CurrentDate);
		EndIf;
		
		// Count errors and warnings.
		EventLogData = EventLogErrorsInformation(StartDate,
			EndDate, ServerTimeOffset, UserFilter);
		
		ReportIsBlank =  ReportIsBlank Or (EventLogData.Count() = 0);
		
		For Each EventLogDataRow In EventLogData Do
			
			UsernameRef = UsersIDsMap[EventLogDataRow.User];
			If UsernameRef = Undefined Then
				Continue;
			EndIf;
			
			If EventLogDataRow.Level = EventLogLevel.Error Then
				SourceDataString = RawData.Add();
				SourceDataString.Errors1 = 1;
			EndIf;
			
			If EventLogDataRow.Level = EventLogLevel.Warning Then
				SourceDataString = RawData.Add();
				SourceDataString.Warnings = 1;
			EndIf;
			
			If SourceDataString <> Undefined Then
				SourceDataString.Date = EventLogDataRow.Date;
				SourceDataString.Week = WeekOfYearString(EventLogDataRow.Date); 
				SourceDataString.User = UsernameRef;
				If UserDepartments <> Undefined Then
					PopulateIBUserDepartment(SourceDataString, EventLogDataRow.Date,
						EventLogDataRow.User, UserDepartments);
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return New Structure("UsersActivityAnalysis, ConcurrentSessionsData, ReportIsBlank",
		RawData, ConcurrentSessionsData, ReportIsBlank);
	
EndFunction

#Region UsersActivityAnalysis

Procedure FillUsersForAnalysis(UserFilter, FilterValue)
	
	If TypeOf(FilterValue) = Type("ValueList") Then
		UsersAndGroups = FilterValue.UnloadValues();
	Else
		UsersAndGroups = CommonClientServer.ValueInArray(FilterValue);
	EndIf;
	
	GroupToRetrieveUsers = New Array;
	AllUsersGroup = Users.AllUsersGroup();
	For Each UserOrGroup In UsersAndGroups Do
		If TypeOf(UserOrGroup) = Type("CatalogRef.Users") Then
			UserForSelection = UserForSelection(UserOrGroup);
			
			If UserForSelection <> Undefined Then
				UserFilter.Add(UserForSelection);
			EndIf;
		ElsIf UserOrGroup = AllUsersGroup Then
			UserFilter = New Array;
			UserFilter.Add("AllUsers");
			Return;
		ElsIf TypeOf(UserOrGroup) = Type("CatalogRef.UserGroups") Then
			GroupToRetrieveUsers.Add(UserOrGroup);
		EndIf;
	EndDo;
	
	If GroupToRetrieveUsers.Count() > 0 Then
		
		Query = New Query;
		Query.SetParameter("Group", GroupToRetrieveUsers);
		Query.Text = 
			"SELECT DISTINCT
			|	UserGroupCompositions.User AS User
			|FROM
			|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
			|WHERE
			|	UserGroupCompositions.UsersGroup IN
			|			(SELECT
			|				UserGroups.Ref AS Ref
			|			FROM
			|				Catalog.UserGroups AS UserGroups
			|			WHERE
			|				UserGroups.Ref IN HIERARCHY (&Group))";
		Result = Query.Execute().Unload();
		
		For Each String In Result Do
			UserForSelection = UserForSelection(String.User);
			
			If UserForSelection <> Undefined Then
				UserFilter.Add(UserForSelection);
			EndIf;
		
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns:
//  Structure:
//   * CurrentItems - Map of KeyAndValue:
//      ** Key - UUID - Infobase user ID
//      ** Value - See DepartmentDetails
//   * Changes - Map of KeyAndValue:
//      ** Key - UUID - Infobase user ID
//      ** Value - Array of See DepartmentChangeDetails
//   * UsersOfSelectedDepartments - Map of KeyAndValue:
//      ** Key - UUID
//      ** Value - Undefined
//
Function UserDepartments(StartDate, ServerTimeOffset, Val SelectedDivisions)
	
	LogFilter = New Structure;
	LogFilter.Insert("StartDate", StartDate + ServerTimeOffset);
	LogFilter.Insert("Event", UsersInternal.EventNameChangeAdditionalForLogging());
	
	LogData = New ValueTable;
	UnloadEventLog(LogData, LogFilter, "Date, Data");
	
	ChangesInDepartments = New Map;
	UsersOfSelectedDepartments = New Map;
	If SelectedDivisions = Undefined Then
		SelectedDivisions = New Array;
	EndIf;
	
	For Each TableRow In LogData Do
		EventData = TableRow.Data;
		If Not ValueIsFilled(EventData) Then
			Continue;
		EndIf;
		TableRow.Date = TableRow.Date - ServerTimeOffset;
		Try
			Data = Common.ValueFromXMLString(EventData);
		Except
			Continue;
		EndTry;
		If TypeOf(Data) <> Type("Structure") Then
			Continue;
		EndIf;
		VersionStorage = New Structure;
		VersionStorage.Insert("DataStructureVersion");
		FillPropertyValues(VersionStorage, Data);
		If VersionStorage.DataStructureVersion <> 2 Then
			Continue;
		EndIf;
		OldDepartmentDetails = Undefined;
		IBUserOldID = Undefined;
		Try
			IBUserID = New UUID(
				Data.IBUserID);
			DepartmentDetails = DepartmentDetails(Data);
			If Data.OldPropertyValues.Property("Department") Then
				OldDepartmentDetails = DepartmentDetails(Data.OldPropertyValues);
				If Data.OldPropertyValues.Property("IBUserID") Then
					IBUserOldID = New UUID(
						Data.OldPropertyValues.IBUserID);
				EndIf;
				If Not ValueIsFilled(IBUserOldID) Then
					IBUserOldID = IBUserID;
				EndIf;
			EndIf;
		Except
			Continue;
		EndTry;
		If Not ValueIsFilled(IBUserID) Then
			Continue;
		EndIf;
		CurrentChanges = ChangesInDepartments.Get(IBUserID);
		If CurrentChanges = Undefined Then
			CurrentChanges = New Array;
			ChangesInDepartments.Insert(IBUserID, CurrentChanges);
		EndIf;
		ChangeDescription = DepartmentChangeDetails(TableRow.Date, DepartmentDetails);
		CurrentChanges.Add(ChangeDescription);
		If SelectedDivisions.Find(DepartmentDetails.Department) <> Undefined
		   And (DepartmentDetails.Department <> Undefined
		      Or Not ValueIsFilled(DepartmentDetails.DepartmentString)) Then
			UsersOfSelectedDepartments.Insert(IBUserID);
		EndIf;
		If OldDepartmentDetails = Undefined Then
			Continue;
		EndIf;
		If SelectedDivisions.Find(OldDepartmentDetails.Department) <> Undefined
		   And (OldDepartmentDetails.Department <> Undefined
		      Or Not ValueIsFilled(OldDepartmentDetails.DepartmentString)) Then
			UsersOfSelectedDepartments.Insert(IBUserOldID);
		EndIf;
		If IBUserID = IBUserOldID Then
			ChangeDescription.Old = OldDepartmentDetails;
			Continue;
		EndIf;
		CurrentChanges = ChangesInDepartments.Get(IBUserOldID);
		If CurrentChanges = Undefined Then
			CurrentChanges = New Array;
			ChangesInDepartments.Insert(IBUserOldID, CurrentChanges);
		EndIf;
		ChangeDescription = DepartmentChangeDetails(TableRow.Date,, OldDepartmentDetails);
		CurrentChanges.Add(ChangeDescription);
	EndDo;
	
	Result = New Structure;
	Result.Insert("CurrentItems", New Map);
	Result.Insert("Changes", ChangesInDepartments);
	Result.Insert("UsersOfSelectedDepartments", UsersOfSelectedDepartments);
	
	Return Result;
	
EndFunction

// Parameters:
//  Data - Structure:
//   * Department - String - Serialized reference.
//   * DepartmentPresentation - String
//
// Returns:
//  Structure:
//   * Department - AnyRef, Undefined
//   * DepartmentString - String - Serialized reference.
//   * DepartmentPresentation - String
//
Function DepartmentDetails(Data)
	
	Department = ?(TypeOf(Data.Department) = Type("String"),
		Data.Department, Undefined);
	
	Result = New Structure;
	Result.Insert("Department", ?(ValueIsFilled(Department),
		ValueFromStringInternal(Department), Undefined));
	Result.Insert("DepartmentString", Department);
	Result.Insert("DepartmentPresentation", Data.DepartmentPresentation);
	
	Return Result;
	
EndFunction

// Parameters:
//  Date   - Date
//  Var_New  - See DepartmentDetails
//         - Undefined
//  Old - See DepartmentDetails
//         - Undefined
//
// Returns:
//  Structure:
//   * Date   - Date
//   * New  - See DepartmentDetails
//            - Undefined
//   * Old - See DepartmentDetails
//            - Undefined
//
Function DepartmentChangeDetails(Date, Var_New = Undefined, Old = Undefined)
	
	Return New Structure("Date, New, Old", Date, Var_New, Old);
	
EndFunction

Procedure FillUsersForAnalysisFromDepartment(UserFilter,
			SelectedDivisions, UserDepartments)
	
	If SelectedDivisions = Undefined Then
		UserFilter.Add("AllUsers");
		AddCurrentUserDepartments(UserDepartments);
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Department", SelectedDivisions);
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	Query.Text =
	"SELECT DISTINCT
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Department IN(&Department)
	|	AND Users.IBUserID <> &BlankUUID";
	
	Upload0 = Query.Execute().Unload();
	Upload0.Indexes.Add("IBUserID");
	
	For Each KeyAndValue In UserDepartments.UsersOfSelectedDepartments Do
		If Upload0.Find(KeyAndValue.Key, "IBUserID") = Undefined Then
			Upload0.Add().IBUserID = KeyAndValue.Key;
		EndIf;
	EndDo;
	
	SetPrivilegedMode(True);
	
	For Each TableRow In Upload0 Do
		UserFilter.Add(UserForSelection(,
			TableRow.IBUserID));
	EndDo;
	
EndProcedure

Function SelectedDivisions(FilterValue)
	
	If FilterValue = Undefined Then
		Return Undefined;
	ElsIf TypeOf(FilterValue) = Type("ValueList") Then
		Result = FilterValue.UnloadValues();
	Else
		Result = CommonClientServer.ValueInArray(FilterValue);
	EndIf;
	
	BlankValues = New Array;
	BlankValues.Add(Undefined);
	For Each Type In Metadata.Catalogs.Users.Attributes.Department.Type.Types() Do
		TypeDetails = New TypeDescription(CommonClientServer.ValueInArray(Type));
		BlankValues.Add(TypeDetails.AdjustValue(Undefined));
	EndDo;
	
	ThereIsEmptyValue = False;
	For Each EmptyValue In BlankValues Do
		If Result.Find(EmptyValue) <> Undefined Then
			ThereIsEmptyValue = True;
			Break;
		EndIf;
	EndDo;
	
	If Not ThereIsEmptyValue Then
		Return Result;
	EndIf;
	
	For Each EmptyValue In BlankValues Do
		If Result.Find(EmptyValue) = Undefined Then
			Result.Add(EmptyValue);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure AddCurrentUserDepartments(UserDepartments, IBUsersIDs = Undefined)
	
	Query = New Query;
	Query.SetParameter("IBUsersIDs", IBUsersIDs);
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	Query.Text =
	"SELECT DISTINCT
	|	Users.IBUserID AS IBUserID,
	|	Users.Department AS Department
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID IN(&IBUsersIDs)";
	If IBUsersIDs = Undefined Then
		Query.Text = StrReplace(Query.Text,
			"Users.IBUserID IN(&IBUsersIDs)",
			"Users.IBUserID <> &BlankUUID");
	EndIf;
	
	Selection = Query.Execute().Select();
	
	ChangesInDepartments = UserDepartments.Changes;
	While Selection.Next() Do
		DepartmentDetails = New Structure;
		DepartmentDetails.Insert("Department", Selection.Department);
		DepartmentDetails.Insert("DepartmentString", "");
		DepartmentDetails.Insert("DepartmentPresentation", String(Selection.Department));
		CurrentChanges = ChangesInDepartments.Get(Selection.IBUserID);
		If CurrentChanges = Undefined Then
			CurrentChanges = New Array;
			ChangesInDepartments.Insert(Selection.IBUserID, CurrentChanges);
		EndIf;
		ChangeDescription = DepartmentChangeDetails('39991231',, DepartmentDetails);
		CurrentChanges.Add(ChangeDescription);
	EndDo;
	
EndProcedure

// Parameters:
//  SourceDataString - ValueTable:
//   * Department - AnyRef, String
//   * DepartmentPresentation - String
//  Date - Date - Event date and time
//  IBUserID - UUID
//  UserDepartments - See UserDepartments
//
Procedure PopulateIBUserDepartment(SourceDataString, Date, IBUserID,
			UserDepartments)
	
	DepartmentDetails = UserDepartments.CurrentItems.Get(IBUserID);
	
	CurrentChanges = UserDepartments.Changes.Get(IBUserID);
	Refresh = False;
	If CurrentChanges.Count() > 0 Then
		While ValueIsFilled(CurrentChanges) And Date >= CurrentChanges[0].Date Do
			PreviousChangeDetails = CurrentChanges[0];
			CurrentChanges.Delete(0);
			Refresh = True;
		EndDo;
		If Refresh Then
			If PreviousChangeDetails.New <> Undefined
			 Or Not ValueIsFilled(CurrentChanges) Then
				DepartmentDetails = PreviousChangeDetails.New;
			Else
				DepartmentDetails = CurrentChanges[0].Old;
			EndIf;
		ElsIf DepartmentDetails = Undefined Then
			DepartmentDetails = CurrentChanges[0].Old;
			Refresh = True;
		EndIf;
	EndIf;
	
	If Refresh Then
		UserDepartments.CurrentItems.Insert(IBUserID, DepartmentDetails);
	EndIf;
	
	If DepartmentDetails = Undefined
	 Or Not ValueIsFilled(DepartmentDetails.Department)
	   And Not ValueIsFilled(DepartmentDetails.DepartmentPresentation) Then
		
		SourceDataString.DepartmentPresentation = "<" + NStr("vi = 'Chưa chỉ ra';
															|ru = 'Не указано';
															|en = 'Not specified'; fa = 'مشخص نشده';
															|it = 'Non indicato';
															|pl = 'Nie określono';
															|tr = 'Belirtilmedi'") + ">";
		Return;
	EndIf;
	
	If DepartmentDetails.Department <> Undefined Then
		SourceDataString.Department = DepartmentDetails.Department;
		SourceDataString.DepartmentPresentation = DepartmentDetails.DepartmentPresentation;
	Else
		SourceDataString.Department = DepartmentDetails.DepartmentString;
		SourceDataString.DepartmentPresentation = DepartmentDetails.DepartmentPresentation;
	EndIf;
	
EndProcedure

Function UsersUUIDs(EventLogData, ShouldOutputUtilityUsers)
	
	UsersTable = EventLogData.Copy(, "User, UserName");
	UsersTable.Indexes.Add("User, UserName");
	UsersTable.GroupBy("User, UserName");
	
	UUIDMap = New Map;
	
	Filter = New Structure("User", CommonClientServer.BlankUUID());
	FoundRows = UsersTable.FindRows(Filter);
	For Each FoundRow In FoundRows Do
		If Not ValueIsFilled(FoundRow.UserName) And ShouldOutputUtilityUsers Then
			UUIDMap.Insert(FoundRows[0].User,
				Users.UnspecifiedUserRef());
		EndIf;
		UsersTable.Delete(FoundRows[0]);
	EndDo;
	
	IBUsersIDs = UsersTable.UnloadColumn("User");
	
	Query = New Query;
	Query.SetParameter("IBUsersIDs", IBUsersIDs);
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.IsInternal AS IsInternal,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID IN(&IBUsersIDs)
	|
	|UNION ALL
	|
	|SELECT
	|	Users.Ref,
	|	FALSE,
	|	Users.IBUserID
	|FROM
	|	Catalog.ExternalUsers AS Users
	|WHERE
	|	Users.IBUserID IN(&IBUsersIDs)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Not Selection.IsInternal Or ShouldOutputUtilityUsers Then
			UUIDMap.Insert(Selection.IBUserID, Selection.Ref);
		EndIf;
		String = UsersTable.Find(Selection.IBUserID, "User");
		UsersTable.Delete(String);
	EndDo;
	
	If Not ShouldOutputUtilityUsers Then
		Return UUIDMap;
	EndIf;
	
	For Each String In UsersTable Do
		If ValueIsFilled(String.UserName) Then
			UUIDMap.Insert(String.User, String.UserName);
		Else
			UUIDMap.Insert(String.User, String(String.User));
		EndIf;
	EndDo;
	
	Return UUIDMap;
	
EndFunction

Function UserForSelection(UserRef = "", IBUserID = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If UserRef <> "" Then
		IBUserID = Common.ObjectAttributeValue(UserRef,
			"IBUserID");
	EndIf;
	
	If ValueIsFilled(IBUserID) Then
		Return EventLog.InfobaseUserForFilter(IBUserID);
	EndIf;
	
	If UserRef = Users.UnspecifiedUserRef() Then
		Return InfoBaseUsers.FindByName("");
	EndIf;
	
	Return Undefined;
	
EndFunction

Function WeekOfYearString(DateInYear)
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tuần %1';
																		|ru = 'Неделя %1';
																		|en = 'Week %1'; fa = 'Week %1';
																		|it = 'Settimana %1';
																		|pl = 'Tydzień %1';
																		|tr = 'Hafta %1'"), WeekOfYear(DateInYear));
EndFunction

Procedure GenerateConcurrentSessionsRow(ConcurrentSessionsData, MaxUsersArray,
			ConcurrentUsers, CurrentDate)
	
	TemporaryArray = New Array;
	IndexOf = 0;
	For Each Item In MaxUsersArray Do
		TemporaryArray.Insert(IndexOf, Item);
		UserSessionsCounter = 0;
		
		For Each CurrentUser In TemporaryArray Do
			If CurrentUser = Item Then
				UserSessionsCounter = UserSessionsCounter + 1;
				UserAndNumber = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																								|ru = '%1 (%2)';
																								|en = '%1 (%2)'; fa = '%1 (%2)';
																								|it = '%1 (%2)';
																								|pl = '%1 (%2)';
																								|tr = '%1 (%2)'"),
					Item,
					UserSessionsCounter);
			EndIf;
		EndDo;
		
		TableRow = ConcurrentSessionsData.Add();
		TableRow.ConcurrentUsersDate = CurrentDate;
		TableRow.ConcurrentUsers = ConcurrentUsers;
		TableRow.ConcurrentUsersList = UserAndNumber;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

#EndRegion

#Region ScheduledJobsDuration

// Generates a report on scheduled jobs.
//
// Parameters:
//   FillParameters - Structure - A set of parameters required to generate the report:
//     * StartDate    - Date - Beginning of the reporting period.
//     * EndDate - Date - End of the reporting period.
//   ConcurrentSessionsSize - Number - Minimum number of concurrent scheduled jobs.
//                                      MinScheduledJobSessionDuration - Number - Minimum duration of a job session in seconds.
//   DisplayBackgroundJobs - Boolean - If set to "True", display a session interval line on the Gantt chart.
//                                                                    OutputTitle - DataCompositionTextOutputType - A title display option.
//   OutputFilter - DataCompositionTextOutputType - A filter display option.
//                                       HideScheduledJobs - ValueList - A list of scheduled jobs to exclude from the report.
//   
//   
//   
//
Function GenerateScheduledJobsDurationReport(FillParameters) Export
	
	// Report parameters.
	StartDate = FillParameters.StartDate;
	EndDate = FillParameters.EndDate;
	MinScheduledJobSessionDuration = 
		FillParameters.MinScheduledJobSessionDuration;
	TitleOutput = FillParameters.TitleOutput;
	FilterOutput = FillParameters.FilterOutput;
	
	Result = New Structure;
	Report = New SpreadsheetDocument;
	
	// Get data required to generate the report.
	GetData = DataForScheduledJobsDurationsReport(FillParameters);
	ScheduledJobsSessionsTable = GetData.ScheduledJobsSessionsTable;
	ConcurrentSessionsData = GetData.TotalConcurrentScheduledJobs;
	StartsCount = GetData.StartsCount;
	ReportIsBlank        = GetData.ReportIsBlank;
	Template = GetTemplate("ScheduledJobsDuration");
	
	// A set of colors for the chart and table backgrounds.
	BackColors = New Array;
	BackColors.Add(WebColors.White);
	BackColors.Add(WebColors.LightYellow);
	BackColors.Add(WebColors.LemonChiffon);
	BackColors.Add(WebColors.NavajoWhite);
	
	// Generate a report header.
	If TitleOutput.Value = DataCompositionTextOutputType.Output
		And TitleOutput.Use
		Or Not TitleOutput.Use Then
		Report.Put(TemplateAreaDetails(Template, "ReportHeader1"));
	EndIf;
	
	If FilterOutput.Value = DataCompositionTextOutputType.Output
		And FilterOutput.Use
		Or Not FilterOutput.Use Then
		Area = TemplateAreaDetails(Template, "Filter");
		If MinScheduledJobSessionDuration > 0 Then
			IntervalsViewMode = NStr("vi = 'Hiển thị khoảng thời gian không bị vô hiệu hóa';
									|ru = 'Отключено отображение интервалов с нулевой продолжительностью';
									|en = 'Hide intervals with zero duration'; fa = 'Hide intervals with zero duration';
									|it = 'Disattivata la visualizzazione degli intervalli con la durata zero';
									|pl = 'Wyświetlanie interwałów o zerowej długości zostało wyłączone';
									|tr = 'Sıfır süreli aralıkların devre dışı görüntülenmesi'");
		Else
			IntervalsViewMode = NStr("vi = 'Hiển thị khoảng thời gian bằng không';
									|ru = 'Включено отображение интервалов с нулевой продолжительностью';
									|en = 'Show intervals with zero duration'; fa = 'Show intervals with zero duration';
									|it = 'Attivata la visualizzazione degli intervalli con la durata zero';
									|pl = 'Wyświetlanie interwałów o zerowej długości zostało włączone';
									|tr = 'Sıfır süreli aralıkların gösterimi etkin'");
		EndIf;
		Area.Parameters.StartDate = StartDate;
		Area.Parameters.EndDate = EndDate;
		Area.Parameters.IntervalsViewMode = IntervalsViewMode;
		Report.Put(Area);
	EndIf;
	
	If ValueIsFilled(ConcurrentSessionsData) Then
	
		Report.Put(TemplateAreaDetails(Template, "TableHeader"));
		
		// Generate a table of the maximum number of concurrent scheduled jobs.
		CurrentSessionsCount = 0; 
		ColorIndex = 3;
		For Each ConcurrentSessionsRow In ConcurrentSessionsData Do
			Area = TemplateAreaDetails(Template, "Table");
			If CurrentSessionsCount <> 0 
				And CurrentSessionsCount <> ConcurrentSessionsRow.ConcurrentScheduledJobs
				And ColorIndex <> 0 Then
				ColorIndex = ColorIndex - 1;
			EndIf;
			If ConcurrentSessionsRow.ConcurrentScheduledJobs = 1 Then
				ColorIndex = 0;
			EndIf;
			Area.Parameters.Fill(ConcurrentSessionsRow);
			TableBackColor = BackColors.Get(ColorIndex);
			TableArea = Area.Areas.Table; // SpreadsheetDocumentRange
			TableArea.BackColor = TableBackColor;
			Report.Put(Area);
			CurrentSessionsCount = ConcurrentSessionsRow.ConcurrentScheduledJobs;
			ScheduledJobsArray = ConcurrentSessionsRow.ScheduledJobsList;
			ScheduledJobIndex = 0;
			Report.StartRowGroup(, False);
			For Each Item In ScheduledJobsArray Do
				If Not TypeOf(Item) = Type("Number")
					And Not TypeOf(Item) = Type("Date") Then
					Area = TemplateAreaDetails(Template, "ScheduledJobsList");
					Area.Parameters.ScheduledJobsList = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (phiên làm việc %2)';
																														|ru = '%1 (сеанс %2)';
																														|en = '%1 (session %2)'; fa = '%1 (session %2)';
																														|it = '%1 (sessione %2)';
																														|pl = '%1 (sesja %2)';
																														|tr = '%1 (oturum %2)'"),
						Item,
						ScheduledJobsArray[ScheduledJobIndex+1]);
				ElsIf Not TypeOf(Item) = Type("Date")
					And Not TypeOf(Item) = Type("String") Then	
					Area.Parameters.JobDetails1 = New Array;
					Area.Parameters.JobDetails1.Add("ScheduledJobDetails1");
					Area.Parameters.JobDetails1.Add(Item);
					ScheduledJobName = ScheduledJobsArray.Get(ScheduledJobIndex-1);
					Area.Parameters.JobDetails1.Add(ScheduledJobName);
					Area.Parameters.JobDetails1.Add(StartDate);
					Area.Parameters.JobDetails1.Add(EndDate);
					Report.Put(Area);
				EndIf;
				ScheduledJobIndex = ScheduledJobIndex + 1;
			EndDo;
			Report.EndRowGroup();
		EndDo;
	EndIf;
	
	Report.Put(TemplateAreaDetails(Template, "IsBlankString"));
	
	// Get the Gantt chart and specify the parameters required to fill the chart.
	Area = TemplateAreaDetails(Template, "Chart");
	GanttChart = Area.Drawings.GanttChart.Object; // GanttChart
	GanttChart.RefreshEnabled = False;  
	
	Series = GanttChart.Series.Add();

	CurrentEvent			 = Undefined;
	OverallScheduledJobsDuration = 0;
	Point					 = Undefined;
	StartsCountRow = Undefined;
	ScheduledJobStarts = 0;
	PointChangedFlag        = False;
	
	// Populate the Gantt chart.	
	For Each ScheduledJobsRow In ScheduledJobsSessionsTable Do
		ScheduledJobIntervalDuration =
			ScheduledJobsRow.JobEndDate - ScheduledJobsRow.JobStartDate;
		If ScheduledJobIntervalDuration >= MinScheduledJobSessionDuration Then
			If CurrentEvent <> ScheduledJobsRow.NameOfEvent Then
				If CurrentEvent <> Undefined
					And PointChangedFlag Then
					DetailsPoint = Point.Details; // Array
					DetailsPoint.Add(ScheduledJobStarts);
					DetailsPoint.Add(OverallScheduledJobsDuration);
					DetailsPoint.Add(StartDate);
					DetailsPoint.Add(EndDate);
					PointName = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2 trong số %3)';
																								|ru = '%1 (%2 из %3)';
																								|en = '%1 (%2 out of %3)'; fa = '%1 (%2 out of %3)';
																								|it = '%1(%2 di %3)';
																								|pl = '%1 (%2 z %3)';
																								|tr = '%1 (%2''den %3)'"),
						Point.Value,
						ScheduledJobStarts,
						String(StartsCountRow.Starts));
					Point.Value = PointName;
				EndIf;
				StartsCountRow = StartsCount.Find(
					ScheduledJobsRow.NameOfEvent, "NameOfEvent");
				// Leaving the details of background jobs blank.
				If ScheduledJobsRow.EventMetadata <> "" Then 
					PointName = ScheduledJobsRow.NameOfEvent;
					Point = GanttChart.SetPoint(PointName);
					DetailsPoint  = New Array;
					IntervalStart	  = New Array;
					IntervalEnd	  = New Array;
					ScheduledJobSession = New Array;
					DetailsPoint.Add("DetailsPoint");
					DetailsPoint.Add(ScheduledJobsRow.EventMetadata);
					DetailsPoint.Add(ScheduledJobsRow.NameOfEvent);
					DetailsPoint.Add(StartsCountRow.Canceled);
					DetailsPoint.Add(StartsCountRow.ExecutionError);                                                             
					DetailsPoint.Add(IntervalStart);
					DetailsPoint.Add(IntervalEnd);
					DetailsPoint.Add(ScheduledJobSession);
					DetailsPoint.Add(MinScheduledJobSessionDuration);
					Point.Details = DetailsPoint;
					CurrentEvent = ScheduledJobsRow.NameOfEvent;
					OverallScheduledJobsDuration = 0;				
					ScheduledJobStarts = 0;
					Point.Picture = PictureLib.ScheduledJob;
				ElsIf Not ValueIsFilled(ScheduledJobsRow.EventMetadata) Then
					PointName = NStr("vi = 'Nhiệm vụ nền';
									|ru = 'Фоновые задания';
									|en = 'Background jobs'; fa = 'کارهای پس‌زمینه';
									|it = 'Background task';
									|pl = 'Zadania w tle';
									|tr = 'Arka plan işleri'");
					Point = GanttChart.SetPoint(PointName);
					OverallScheduledJobsDuration = 0;
				EndIf;
			EndIf;
			Value = GanttChart.GetValue(Point, Series);
			Interval = Value.Add();
			Interval.Begin = ScheduledJobsRow.JobStartDate;
			Interval.End = ScheduledJobsRow.JobEndDate;
			Interval.Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 - %2';
																							|ru = '%1 - %2';
																							|en = '%1 - %2'; fa = '%1 - %2';
																							|it = '%1 - %2';
																							|pl = '%1 - %2';
																							|tr = '%1 - %2'"),
				Format(Interval.Begin, "DLF=T"),
				Format(Interval.End, "DLF=T"));
			PointChangedFlag = False;
			// Leaving the details of background jobs blank.
			If ScheduledJobsRow.EventMetadata <> "" Then
				IntervalStart.Add(ScheduledJobsRow.JobStartDate);
				IntervalEnd.Add(ScheduledJobsRow.JobEndDate);
				ScheduledJobSession.Add(ScheduledJobsRow.Session);
				OverallScheduledJobsDuration = ScheduledJobIntervalDuration + OverallScheduledJobsDuration;
				ScheduledJobStarts = ScheduledJobStarts + 1;
				PointChangedFlag = True;
			EndIf;
		EndIf;
	EndDo; 
	
	If ScheduledJobStarts <> 0
		And ValueIsFilled(Point.Details) Then
		// Add the details feature to the last point.
		DetailsPoint = Point.Details; // Array
		DetailsPoint.Add(ScheduledJobStarts);
		DetailsPoint.Add(OverallScheduledJobsDuration);
		DetailsPoint.Add(StartDate);
		DetailsPoint.Add(EndDate);	
		PointName = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2 trong số %3)';
																					|ru = '%1 (%2 из %3)';
																					|en = '%1 (%2 out of %3)'; fa = '%1 (%2 out of %3)';
																					|it = '%1(%2 di %3)';
																					|pl = '%1 (%2 z %3)';
																					|tr = '%1 (%2''den %3)'"),
			Point.Value,
			ScheduledJobStarts,
			String(StartsCountRow.Starts));
		Point.Value = PointName;
	EndIf;
		
	// Configure the chart view.
	GanttChartColors(StartDate, GanttChart, ConcurrentSessionsData, BackColors);
	AnalysisPeriod = EndDate - StartDate;
	GanttChartTimescale(GanttChart, AnalysisPeriod);
	
	ColumnsCount = GanttChart.Points.Count();
	Area.Drawings.GanttChart.Height				 = 15 + 10 * ColumnsCount;
	Area.Drawings.GanttChart.Width 				 = 450;
	GanttChart.AutoDetectWholeInterval	 = False; 
	GanttChart.IntervalRepresentation   			 = GanttChartIntervalRepresentation.Flat;
	GanttChart.LegendArea.Placement       = ChartLegendPlacement.None;
	GanttChart.VerticalStretch 			 = GanttChartVerticalStretch.StretchRowsAndData;
	GanttChart.SetWholeInterval(StartDate, EndDate);
	GanttChart.RefreshEnabled = True;

	Report.Put(Area);
	
	Result.Insert("Report", Report);
	Result.Insert("ReportIsBlank", ReportIsBlank);
	Return Result;
EndFunction

// Gets scheduled jobs data from the Event log.
//
// Parameters:
//   FillParameters - Structure - Set of parameters required for report generation.:
//   * StartDate    - Date - Beginning of the reporting period.
//   * EndDate - Date - End of the reporting period.
//   * ConcurrentSessionsSize	- Number - Minimum number of concurrent scheduled jobs
// 		to display in the table.
//   * MinScheduledJobSessionDuration - Number - Minimal job session duration in seconds.
// 		
//   * DisplayBackgroundJobs - Boolean - If set to "True", display a line with intervals of background job sessions 
// 		on the Gantt chart.
//   * HideScheduledJobs - ValueList - List of scheduled jobs to exclude from the report.
//
// Returns
//   ValueTable - Table of log entries on the scheduled jobs.
//     
//
Function DataForScheduledJobsDurationsReport(FillParameters)
	
	StartDate = FillParameters.StartDate;
	EndDate = FillParameters.EndDate;
	ConcurrentSessionsSize = FillParameters.ConcurrentSessionsSize;
	DisplayBackgroundJobs = FillParameters.DisplayBackgroundJobs;
	MinScheduledJobSessionDuration =
		FillParameters.MinScheduledJobSessionDuration;
	HideScheduledJobs = FillParameters.HideScheduledJobs;
	ServerTimeOffset = FillParameters.ServerTimeOffset;
	
	Levels = New Array;
	Levels.Add(EventLogLevel.Information);
	Levels.Add(EventLogLevel.Warning);
	Levels.Add(EventLogLevel.Error);
	
	ScheduledJobEvents = New Array;
	ScheduledJobEvents.Add("_$Job$_.Start");
	ScheduledJobEvents.Add("_$Job$_.Cancel");
	ScheduledJobEvents.Add("_$Job$_.Fail");
	ScheduledJobEvents.Add("_$Job$_.Succeed");
	ScheduledJobEvents.Add("_$Job$_.Finish");
	ScheduledJobEvents.Add("_$Job$_.Error");
	
	SetPrivilegedMode(True);
	LogFilter = New Structure;
	LogFilter.Insert("Level", Levels);
	LogFilter.Insert("StartDate", StartDate + ServerTimeOffset);
	LogFilter.Insert("EndDate", EndDate + ServerTimeOffset);
	LogFilter.Insert("Event", ScheduledJobEvents);
	
	EventLogData = New ValueTable;
	UnloadEventLog(EventLogData, LogFilter);
	ReportIsBlank = (EventLogData.Count() = 0);
	
	If ServerTimeOffset <> 0 Then
		For Each TableRow In EventLogData Do
			TableRow.Date = TableRow.Date - ServerTimeOffset;
		EndDo;
	EndIf;
	
	// Generate data for the filter by scheduled jobs.
	AllScheduledJobsList = ScheduledJobsServer.FindJobs(New Structure);
	MetadataIDMap = New Map;
	MetadataNameMap = New Map;
	DescriptionIDMap = New Map;
	SetPrivilegedMode(False);
	
	For Each SchedJob In AllScheduledJobsList Do
		MetadataIDMap.Insert(SchedJob.Metadata, String(SchedJob.UUID));
		DescriptionIDMap.Insert(SchedJob.Description, String(SchedJob.UUID));
		If SchedJob.Description <> "" Then
			MetadataNameMap.Insert(SchedJob.Metadata, SchedJob.Description);
		Else
			MetadataNameMap.Insert(SchedJob.Metadata, SchedJob.Metadata.Synonym);
		EndIf;
	EndDo;
	
	// Populate parameters required for defining concurrent scheduled jobs.
	ConcurrentSessionsParameters = New Structure;
	ConcurrentSessionsParameters.Insert("EventLogData", EventLogData);
	ConcurrentSessionsParameters.Insert("DescriptionIDMap", DescriptionIDMap);
	ConcurrentSessionsParameters.Insert("MetadataIDMap", MetadataIDMap);
	ConcurrentSessionsParameters.Insert("MetadataNameMap", MetadataNameMap);
	ConcurrentSessionsParameters.Insert("HideScheduledJobs", HideScheduledJobs);
	ConcurrentSessionsParameters.Insert("MinScheduledJobSessionDuration",
		MinScheduledJobSessionDuration);
	
	// The maximum number of concurrent scheduled job sessions.
	ConcurrentSessionsData = ConcurrentScheduledJobs(ConcurrentSessionsParameters);
	
	// Select values from the "ConcurrentSessions" table.
	ConcurrentSessionsData.Sort("ConcurrentScheduledJobs Desc");
	
	TotalConcurrentScheduledJobsRow = Undefined;
	TotalConcurrentScheduledJobs = New ValueTable();
	TotalConcurrentScheduledJobs.Columns.Add("ConcurrentScheduledJobsDate", 
		New TypeDescription("String", , New StringQualifiers(50)));
	TotalConcurrentScheduledJobs.Columns.Add("ConcurrentScheduledJobs", 
		New TypeDescription("Number", New NumberQualifiers(10))); 
	TotalConcurrentScheduledJobs.Columns.Add("ScheduledJobsList");
	
	For Each ConcurrentSessionsRow In ConcurrentSessionsData Do
		If ConcurrentSessionsRow.ConcurrentScheduledJobs >= ConcurrentSessionsSize
			And ConcurrentSessionsRow.ConcurrentScheduledJobs >= 2 Then
			TotalConcurrentScheduledJobsRow = TotalConcurrentScheduledJobs.Add();
			TotalConcurrentScheduledJobsRow.ConcurrentScheduledJobsDate = 
				ConcurrentSessionsRow.ConcurrentScheduledJobsDate;
			TotalConcurrentScheduledJobsRow.ConcurrentScheduledJobs = 
				ConcurrentSessionsRow.ConcurrentScheduledJobs;
			TotalConcurrentScheduledJobsRow.ScheduledJobsList = 
				ConcurrentSessionsRow.ScheduledJobsList;
		EndIf;
	EndDo;
	
	EventLogData.Sort("Metadata, Data, Date, Session");
	
	// Populate parameters required for getting data by scheduled jobs session.
	ScheduledJobsSessionsParameters = New Structure;
	ScheduledJobsSessionsParameters.Insert("EventLogData", EventLogData);
	ScheduledJobsSessionsParameters.Insert("DescriptionIDMap", DescriptionIDMap);
	ScheduledJobsSessionsParameters.Insert("MetadataIDMap", MetadataIDMap);
	ScheduledJobsSessionsParameters.Insert("MetadataNameMap", MetadataNameMap);
	ScheduledJobsSessionsParameters.Insert("DisplayBackgroundJobs", DisplayBackgroundJobs);
	ScheduledJobsSessionsParameters.Insert("HideScheduledJobs", HideScheduledJobs);
	
	// Scheduled jobs
	ScheduledJobsSessionsTable = 
		ScheduledJobsSessions(ScheduledJobsSessionsParameters).ScheduledJobsSessionsTable;
	StartsCount = ScheduledJobsSessions(ScheduledJobsSessionsParameters).StartsCount;
	
	Result = New Structure;
	Result.Insert("ScheduledJobsSessionsTable", ScheduledJobsSessionsTable);
	Result.Insert("TotalConcurrentScheduledJobs", TotalConcurrentScheduledJobs);
	Result.Insert("StartsCount", StartsCount);
	Result.Insert("ReportIsBlank", ReportIsBlank);
	
	Return Result;
EndFunction

Function ConcurrentScheduledJobs(ConcurrentSessionsParameters)
	
	EventLogData 			  = ConcurrentSessionsParameters.EventLogData;
	DescriptionIDMap = ConcurrentSessionsParameters.DescriptionIDMap;
	MetadataIDMap   = ConcurrentSessionsParameters.MetadataIDMap;
	MetadataNameMap 		  = ConcurrentSessionsParameters.MetadataNameMap;
	HideScheduledJobs 			  = ConcurrentSessionsParameters.HideScheduledJobs;
	MinScheduledJobSessionDuration = ConcurrentSessionsParameters.	
		MinScheduledJobSessionDuration;
										
	ConcurrentSessionsData = New ValueTable();
	
	ConcurrentSessionsData.Columns.Add("ConcurrentScheduledJobsDate",
										New TypeDescription("String", , New StringQualifiers(50)));
	ConcurrentSessionsData.Columns.Add("ConcurrentScheduledJobs",
										New TypeDescription("Number", New NumberQualifiers(10)));
	ConcurrentSessionsData.Columns.Add("ScheduledJobsList");
	
	ScheduledJobsArray = New Array;
	
	ConcurrentScheduledJobs	  = 0;
	Counter     				  = 0;
	CurrentDate 					  = Undefined;
	TableRow 				  = Undefined;
	MaxScheduledJobsArray = Undefined;
	
	For Each EventLogDataRow In EventLogData Do 
		If Not ValueIsFilled(EventLogDataRow.Date)
			Or Not ValueIsFilled(EventLogDataRow.Metadata) Then
			Continue;
		EndIf;
		
		NameAndUUID = ScheduledJobSessionNameAndUUID(
			EventLogDataRow, DescriptionIDMap,
			MetadataIDMap, MetadataNameMap);
			
		ScheduledJobName1 = NameAndUUID.SessionName;
		ScheduledJobUUID = 
			NameAndUUID.ScheduledJobUUID;
		
		If Not HideScheduledJobs = Undefined
			And Not TypeOf(HideScheduledJobs) = Type("String") Then
			ScheduledJobsFilter = HideScheduledJobs.FindByValue(
				ScheduledJobUUID);
			If Not ScheduledJobsFilter = Undefined Then
				Continue;
			EndIf;
		ElsIf Not HideScheduledJobs = Undefined
			And TypeOf(HideScheduledJobs) = Type("String") Then	
			If ScheduledJobUUID = HideScheduledJobs Then
				Continue;
			EndIf;
		EndIf;	
		
		ConcurrentScheduledJobsDate = BegOfHour(EventLogDataRow.Date);
		
		If CurrentDate <> ConcurrentScheduledJobsDate Then
			If TableRow <> Undefined Then
				TableRow.ConcurrentScheduledJobs = ConcurrentScheduledJobs;
				TableRow.ConcurrentScheduledJobsDate = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 - %2';
																													|ru = '%1 - %2';
																													|en = '%1 - %2'; fa = '%1 - %2';
																													|it = '%1 - %2';
																													|pl = '%1 - %2';
																													|tr = '%1 - %2'"),
					Format(CurrentDate, "DLF=T"),
					Format(EndOfHour(CurrentDate), "DLF=T"));
				TableRow.ScheduledJobsList = MaxScheduledJobsArray;
			EndIf;
			TableRow = ConcurrentSessionsData.Add();
			ConcurrentScheduledJobs = 0;
			Counter    = 0;
			ScheduledJobsArray.Clear();
			CurrentDate = ConcurrentScheduledJobsDate;
		EndIf;
		
		If EventLogDataRow.Event = "_$Job$_.Start" Then
			Counter = Counter + 1;
			ScheduledJobsArray.Add(ScheduledJobName1);
			ScheduledJobsArray.Add(EventLogDataRow.Session);
			ScheduledJobsArray.Add(EventLogDataRow.Date);
		Else
			ScheduledJobIndex = ScheduledJobsArray.Find(ScheduledJobName1);
			If ScheduledJobIndex = Undefined Then 
				Continue;
			EndIf;
			
			If ValueIsFilled(MaxScheduledJobsArray) Then
				ArrayStringIndex = MaxScheduledJobsArray.Find(ScheduledJobName1);
				If ArrayStringIndex <> Undefined 
					And MaxScheduledJobsArray[ArrayStringIndex+1] = ScheduledJobsArray[ScheduledJobIndex+1]
					And EventLogDataRow.Date - MaxScheduledJobsArray[ArrayStringIndex+2] <
						MinScheduledJobSessionDuration Then
					MaxScheduledJobsArray.Delete(ArrayStringIndex);
					MaxScheduledJobsArray.Delete(ArrayStringIndex);
					MaxScheduledJobsArray.Delete(ArrayStringIndex);
					ConcurrentScheduledJobs = ConcurrentScheduledJobs - 1;
				EndIf;
			EndIf;    						
			ScheduledJobsArray.Delete(ScheduledJobIndex);
			ScheduledJobsArray.Delete(ScheduledJobIndex); // Delete the session value.
			ScheduledJobsArray.Delete(ScheduledJobIndex); // Delete the date value.
			Counter = Counter - 1;
		EndIf;
		
		Counter = Max(Counter, 0);
		If Counter > ConcurrentScheduledJobs Then
			MaxScheduledJobsArray = New Array;
			For Each Item In ScheduledJobsArray Do
				MaxScheduledJobsArray.Add(Item);
			EndDo;
		EndIf;
		ConcurrentScheduledJobs = Max(ConcurrentScheduledJobs, Counter);
	EndDo;
		
	If ConcurrentScheduledJobs <> 0 Then
		TableRow.ConcurrentScheduledJobs  = ConcurrentScheduledJobs;
		TableRow.ConcurrentScheduledJobsDate = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 - %2';
																											|ru = '%1 - %2';
																											|en = '%1 - %2'; fa = '%1 - %2';
																											|it = '%1 - %2';
																											|pl = '%1 - %2';
																											|tr = '%1 - %2'"),
			Format(CurrentDate, "DLF=T"),
			Format(EndOfHour(CurrentDate), "DLF=T"));
		TableRow.ScheduledJobsList = MaxScheduledJobsArray;
	EndIf;
	
	Return ConcurrentSessionsData;
EndFunction

Function ScheduledJobsSessions(ScheduledJobsSessionsParameters)

	EventLogData = ScheduledJobsSessionsParameters.EventLogData;
	DescriptionIDMap = ScheduledJobsSessionsParameters.DescriptionIDMap;
	MetadataIDMap = ScheduledJobsSessionsParameters.MetadataIDMap;
	MetadataNameMap = ScheduledJobsSessionsParameters.MetadataNameMap;
	HideScheduledJobs = ScheduledJobsSessionsParameters.HideScheduledJobs;
	DisplayBackgroundJobs = ScheduledJobsSessionsParameters.DisplayBackgroundJobs;  
	
	ScheduledJobsSessionsTable = New ValueTable();
	ScheduledJobsSessionsTable.Columns.Add("JobStartDate",New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime)));
	ScheduledJobsSessionsTable.Columns.Add("JobEndDate",New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime)));
    ScheduledJobsSessionsTable.Columns.Add("NameOfEvent",New TypeDescription("String", , New StringQualifiers(100)));
	ScheduledJobsSessionsTable.Columns.Add("EventMetadata",New TypeDescription("String", , New StringQualifiers(100)));
	ScheduledJobsSessionsTable.Columns.Add("Session",New TypeDescription("Number", 	New NumberQualifiers(10)));
	
	StartsCount = New ValueTable();
	StartsCount.Columns.Add("NameOfEvent",New TypeDescription("String", , New StringQualifiers(100)));
	StartsCount.Columns.Add("Starts",New TypeDescription("Number", 	New NumberQualifiers(10)));
	StartsCount.Columns.Add("Canceled",New TypeDescription("Number", 	New NumberQualifiers(10)));
	StartsCount.Columns.Add("ExecutionError",New TypeDescription("Number", 	New NumberQualifiers(10))); 	
	
	ScheduledJobsRow = Undefined;
	NameOfEvent			  = Undefined;
	JobEndDate	  = Undefined;
	JobStartDate		  = Undefined;
	EventMetadata		  = Undefined;
	Starts				  = 0;
	CurrentEvent			  = Undefined;
	StartsCountRow  = Undefined;
	CurrentSession			  = 0;
	Canceled				  = 0;
	ExecutionError		  = 0;
	
	For Each EventLogDataRow In EventLogData Do
		If Not ValueIsFilled(EventLogDataRow.Metadata)
			And DisplayBackgroundJobs = False Then
			Continue;
		EndIf;
		
		NameAndUUID = ScheduledJobSessionNameAndUUID(
			EventLogDataRow, DescriptionIDMap,
			MetadataIDMap, MetadataNameMap);
			
		NameOfEvent = NameAndUUID.SessionName;
		ScheduledJobUUID = NameAndUUID.
														ScheduledJobUUID;

		If Not HideScheduledJobs = Undefined
			And Not TypeOf(HideScheduledJobs) = Type("String") Then
			ScheduledJobsFilter = HideScheduledJobs.FindByValue(
				ScheduledJobUUID);
			If Not ScheduledJobsFilter = Undefined Then
				Continue;
			EndIf;
		ElsIf Not HideScheduledJobs = Undefined
			And TypeOf(HideScheduledJobs) = Type("String") Then	
			If ScheduledJobUUID = HideScheduledJobs Then
				Continue;
			EndIf;
		EndIf;
	
		Session = EventLogDataRow.Session;
		If CurrentEvent = Undefined Then                             
			CurrentEvent = NameOfEvent;
			Starts = 0;
		ElsIf CurrentEvent <> NameOfEvent Then
			StartsCountRow = StartsCount.Add();
			StartsCountRow.NameOfEvent = CurrentEvent;
			StartsCountRow.Starts = Starts;
			StartsCountRow.Canceled = Canceled;
			StartsCountRow.ExecutionError = ExecutionError;
			Starts = 0; 
			Canceled = 0;
			ExecutionError = 0;
			CurrentEvent = NameOfEvent;
		EndIf;  
		
		If CurrentSession <> Session Then
			ScheduledJobsRow = ScheduledJobsSessionsTable.Add();
			JobStartDate = EventLogDataRow.Date;
			ScheduledJobsRow.JobStartDate = JobStartDate;    
		EndIf;
		
		If CurrentSession = Session Then
			JobEndDate = EventLogDataRow.Date;
			EventMetadata = EventLogDataRow.Metadata;
			ScheduledJobsRow.NameOfEvent = NameOfEvent;
			ScheduledJobsRow.EventMetadata = EventMetadata;
			ScheduledJobsRow.JobEndDate = JobEndDate;
			ScheduledJobsRow.Session = CurrentSession;
		EndIf;
		CurrentSession = Session;
		
		If EventLogDataRow.Event = "_$Job$_.Cancel" Then
			Canceled = Canceled + 1;
		ElsIf EventLogDataRow.Event = "_$Job$_.Fail" Then
			ExecutionError = ExecutionError + 1;
		ElsIf EventLogDataRow.Event = "_$Job$_.Start" Then
			Starts = Starts + 1
		EndIf;		
	EndDo;
	
	StartsCountRow = StartsCount.Add();
	StartsCountRow.NameOfEvent = CurrentEvent;
	StartsCountRow.Starts = Starts;
	StartsCountRow.Canceled = Canceled;
	StartsCountRow.ExecutionError = ExecutionError;
	
	ScheduledJobsSessionsTable.Sort("EventMetadata, NameOfEvent, JobStartDate");
	
	Return New Structure("ScheduledJobsSessionsTable, StartsCount",
					ScheduledJobsSessionsTable, StartsCount);
EndFunction

// Parameters:
//   Details - Array - The scheduled job drill-down.
//
Function ScheduledJobDetails1(Details) Export
	Result = New Structure;
	Report = New SpreadsheetDocument;
	JobsCanceled = 0;
	ExecutionError = 0;
	
	JobStartDate = Details.Get(5);
	JobEndDate = Details.Get(6);
	SessionsList = Details.Get(7);
	Template = GetTemplate("ScheduledJobsDetails");
	
	Area = TemplateAreaDetails(Template, "Title");
	StartDate = Details.Get(11);
	EndDate = Details.Get(12);
	Area.Parameters.StartDate = StartDate;
	Area.Parameters.EndDate = EndDate;
	If Details.Get(8) = 0 Then
		IntervalsViewMode = NStr("vi = 'Hiển thị khoảng thời gian bằng không';
								|ru = 'Включено отображение интервалов с нулевой продолжительностью';
								|en = 'Show intervals with zero duration'; fa = 'Show intervals with zero duration';
								|it = 'Attivata la visualizzazione degli intervalli con la durata zero';
								|pl = 'Wyświetlanie interwałów o zerowej długości zostało włączone';
								|tr = 'Sıfır süreli aralıkların gösterimi etkin'");
	Else
		IntervalsViewMode = NStr("vi = 'Hiển thị khoảng thời gian không bị vô hiệu hóa';
								|ru = 'Отключено отображение интервалов с нулевой продолжительностью';
								|en = 'Hide intervals with zero duration'; fa = 'Hide intervals with zero duration';
								|it = 'Disattivata la visualizzazione degli intervalli con la durata zero';
								|pl = 'Wyświetlanie interwałów o zerowej długości zostało wyłączone';
								|tr = 'Sıfır süreli aralıkların devre dışı görüntülenmesi'");
	EndIf;
	Area.Parameters.SessionViewMode = IntervalsViewMode;
	Report.Put(Area);
	
	Report.Put(Template.GetArea("IsBlankString"));
	
	Area = TemplateAreaDetails(Template, "Table");
	Area.Parameters.JobType = NStr("vi = 'Thường kỳ';
									|ru = 'Регламентное';
									|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
									|it = 'Routine';
									|pl = 'Scheduled';
									|tr = 'Programlı'");
	Area.Parameters.NameOfEvent = Details.Get(2);
	Area.Parameters.Starts = Details.Get(9);
	JobsCanceled = Details.Get(3);
	ExecutionError = Details.Get(4);
	If JobsCanceled = 0 Then
		Area.Parameters.Canceled = "0";
	Else
		Area.Parameters.Canceled = JobsCanceled;
	EndIf;
	If ExecutionError = 0 Then 
		Area.Parameters.ExecutionError = "0";
	Else
		Area.Parameters.ExecutionError = ExecutionError;
	EndIf;
	OverallScheduledJobsDuration = Details.Get(10);
	OverallScheduledJobsDurationTotal = ScheduledJobDuration(OverallScheduledJobsDuration);
	Area.Parameters.OverallScheduledJobsDuration = OverallScheduledJobsDurationTotal;
	Report.Put(Area);
	
	Report.Put(Template.GetArea("IsBlankString")); 
	
	Report.Put(Template.GetArea("IntervalsTitle"));
		
	Report.Put(Template.GetArea("IsBlankString"));
	
	Report.Put(Template.GetArea("TableHeader"));
	
	// Populate the intervals table.
	ArraySize = JobStartDate.Count();
	IntervalNumber = 1; 	
    Report.StartRowGroup(, False);
	For IndexOf = 0 To ArraySize-1 Do
		Area = TemplateAreaDetails(Template, "IntervalsTable");
		StartOfRange = JobStartDate.Get(IndexOf);
		EndOfRange = JobEndDate.Get(IndexOf);
		SJDuration = ScheduledJobDuration(EndOfRange - StartOfRange);
		Area.Parameters.IntervalNumber = IntervalNumber;
		Area.Parameters.StartOfRange = Format(StartOfRange, "DLF=T");
		Area.Parameters.EndOfRange = Format(EndOfRange, "DLF=T");
		Area.Parameters.SJDuration = SJDuration;
		Area.Parameters.Session = SessionsList.Get(IndexOf);
		Area.Parameters.IntervalDetails1 = New Array;
		Area.Parameters.IntervalDetails1.Add(StartOfRange);
		Area.Parameters.IntervalDetails1.Add(EndOfRange);
		Area.Parameters.IntervalDetails1.Add(SessionsList.Get(IndexOf));
		Report.Put(Area);
		IntervalNumber = IntervalNumber + 1;
	EndDo;
	Report.EndRowGroup();
	
	Result.Insert("Report", Report);
	Return Result;
EndFunction

// Sets interval and background colors for a Gantt chart.
//
// Parameters:
//   StartDate - Day to be analyzed.
//   GanttChart - GanttChart, Type - SpreadsheetDocumentDrawing.
//   ConcurrentSessionsData - ValueTable - Contains the number of concurrent scheduled jobs that ran on the given date.
// 		
//   BackColors - Array of colors for background intervals.
//
Procedure GanttChartColors(StartDate, GanttChart, ConcurrentSessionsData, BackColors)
	// Add colors of background intervals.
	CurrentSessionsCount = 0;
	ColorIndex = 3;
	For Each ConcurrentSessionsRow In ConcurrentSessionsData Do
		If ConcurrentSessionsRow.ConcurrentScheduledJobs = 1 Then
			Continue
		EndIf;
		DateString = Left(ConcurrentSessionsRow.ConcurrentScheduledJobsDate, 8);
		BackIntervalStartDate =  Date(Format(StartDate,"DLF=D") + " " + DateString);
		BackIntervalEndDate = EndOfHour(BackIntervalStartDate);
		GanttChartInterval = GanttChart.BackgroundIntervals.Add(BackIntervalStartDate, BackIntervalEndDate);
		If CurrentSessionsCount <> 0 
			And CurrentSessionsCount <> ConcurrentSessionsRow.ConcurrentScheduledJobs 
			And ColorIndex <> 0 Then
			ColorIndex = ColorIndex - 1;
		EndIf;
		BackColor = BackColors.Get(ColorIndex);
		GanttChartInterval.Color = BackColor;
		
		CurrentSessionsCount = ConcurrentSessionsRow.ConcurrentScheduledJobs;
	EndDo;
EndProcedure

// Generates a timescale of a Gantt chart.
//
// Parameters:
//   GanttChart - GanttChart, Type - SpreadsheetDocumentDrawing.
//
Procedure GanttChartTimescale(GanttChart, AnalysisPeriod)
	TimeScaleItems = GanttChart.PlotArea.TimeScale.Items;
	
	TheFirstControl = TimeScaleItems[0];
	For IndexOf = 1 To TimeScaleItems.Count()-1 Do
		TimeScaleItems.Delete(TimeScaleItems[1]);
	EndDo; 
		
	TheFirstControl.Unit = TimeScaleUnitType.Day;
	TheFirstControl.PointLines = New Line(ChartLineType.Solid, 1);
	TheFirstControl.DayFormat =  TimeScaleDayFormat.MonthDay;
	
	Item = TimeScaleItems.Add();
	Item.Unit = TimeScaleUnitType.Hour;
	Item.PointLines = New Line(ChartLineType.Dotted, 1);
	
	If AnalysisPeriod <= 3600 Then
		Item = TimeScaleItems.Add();
		Item.Unit = TimeScaleUnitType.Minute;
		Item.PointLines = New Line(ChartLineType.Dotted, 1);
	EndIf;
EndProcedure

Function ScheduledJobDuration(SJDuration)
	If SJDuration = 0 Then
		OverallScheduledJobsDuration = "0";
	ElsIf SJDuration <= 60 Then
		OverallScheduledJobsDuration = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 giây';
																									|ru = '%1 сек';
																									|en = '%1 sec'; fa = '%1 sec';
																									|it = '%1 sec-';
																									|pl = '%1 sek';
																									|tr = 'saniye %1'"), SJDuration);
	ElsIf 60 < SJDuration <= 3600 Then
		DurationMinutes  = Format(SJDuration/60, "NFD=0");
		DurationSeconds = Format((Format(SJDuration/60, "NFD=2")
			- Int(SJDuration/60)) * 60, "NFD=0");
		OverallScheduledJobsDuration = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 phút %2 giây';
																									|ru = '%1 мин %2 сек';
																									|en = '%1 min %2 sec'; fa = '%1 min %2 sec';
																									|it = '%1 min %2 sec';
																									|pl = '%1 min %2 sek';
																									|tr = '%1 dak %2 san'"), DurationMinutes, DurationSeconds);
	ElsIf SJDuration > 3600 Then
		DurationHours    = Format(SJDuration/60/60, "NFD=0");
		DurationMinutes  = (Format(SJDuration/60/60, "NFD=2") - Int(SJDuration/60/60))*60;
		DurationMinutes  = Format(DurationMinutes, "NFD=0");
		OverallScheduledJobsDuration = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 giờ %2 phút';
																									|ru = '%1 ч %2 мин';
																									|en = '%1 h %2 min'; fa = '%1 h %2 min';
																									|it = '%1 h %2 min';
																									|pl = '%1 godz %2 min';
																									|tr = '%1 sa %2 dk'"), DurationHours, DurationMinutes);
	EndIf;
	
	Return OverallScheduledJobsDuration;
EndFunction

Function ScheduledJobMetadata(ScheduledJobData)
	If ScheduledJobData <> "" Then
		Return Metadata.ScheduledJobs.Find(
			StrReplace(ScheduledJobData, "ScheduledJob." , ""));
	EndIf;
EndFunction

Function ScheduledJobSessionNameAndUUID(EventLogDataRow,
			DescriptionIDMap, MetadataIDMap, MetadataNameMap)
	If Not EventLogDataRow.Data = "" Then
		ScheduledJobUUID = DescriptionIDMap[
														EventLogDataRow.Data];
		SessionName = EventLogDataRow.Data;
	Else 
		ScheduledJobUUID = MetadataIDMap[
			ScheduledJobMetadata(EventLogDataRow.Metadata)];
		SessionName = MetadataNameMap[ScheduledJobMetadata(
														EventLogDataRow.Metadata)];
	EndIf;
													
	Return New Structure("SessionName, ScheduledJobUUID",
								SessionName, ScheduledJobUUID)
EndFunction

// Parameters:
//  Template - SpreadsheetDocument
//  AreaName - String
//
// Returns:
//  SpreadsheetDocument:
//    * Parameters - SpreadsheetDocumentTemplateParameters:
//        ** StartDate - Date
//        ** EndDate - Date
//        ** IntervalsViewMode - String
//        ** ScheduledJobsList - String
//        ** JobDetails1 - Array of String
//                              - Date
//        ** IntervalDetails1 - Array of String
//
Function TemplateAreaDetails(Template, AreaName)
	
	Return Template.GetArea(AreaName);
	
EndFunction

#EndRegion

#Region EventLogMonitor

// Generates a report on errors registered in the event log.
//
// Parameters:
//   EventLogData - ValueTable - Table exported from the event log.
//
// Mandatory columns: "Date", "Username", "ApplicationPresentation",
//                                          "EventPresentation", "Comment", and "Level".
//
Function GenerateEventLogMonitorReport(StartDate, EndDate, ServerTimeOffset) Export
	
	Result = New Structure; 	
	Report = New SpreadsheetDocument; 	
	Template = GetTemplate("EvengLogErrorReportTemplate");
	EventLogData = EventLogErrorsInformation(StartDate, EndDate, ServerTimeOffset);
	EventLogRecordsCount = EventLogData.Count();
	
	ReportIsBlank = (EventLogRecordsCount = 0); // Validate report input.
		
	///////////////////////////////////////////////////////////////////////////////
	// A data preparation sequence.
	//
	
	CollapseByComments = EventLogData.Copy();
	CollapseByComments.Columns.Add("TotalByComment");
	CollapseByComments.FillValues(1, "TotalByComment");
	CollapseByComments.GroupBy("Level, Comment, Event, EventPresentation", "TotalByComment");
	
	RowsArrayErrorLevel = CollapseByComments.FindRows(
									New Structure("Level", EventLogLevel.Error));
	
	RowsArrayWarningLevel = CollapseByComments.FindRows(
									New Structure("Level", EventLogLevel.Warning));
	
	CollapseErrors         = CollapseByComments.Copy(RowsArrayErrorLevel);
	CollapseErrors.Sort("TotalByComment Desc");
	CollapseWarnings = CollapseByComments.Copy(RowsArrayWarningLevel);
	CollapseWarnings.Sort("TotalByComment Desc");
	
	///////////////////////////////////////////////////////////////////////////////
	// A report generation sequence.
	//
	
	Area = Template.GetArea("ReportHeader1");
	Area.Parameters.SelectionPeriodStart    = StartDate;
	Area.Parameters.SelectionPeriodEnd = EndDate;
	Area.Parameters.InfobasePresentation = InfobasePresentation();
	Report.Put(Area);
	
	TSCompositionResult = GenerateTabularSection(Template, EventLogData, CollapseErrors);
	
	Report.Put(Template.GetArea("IsBlankString"));
	Area = Template.GetArea("ErrorBlockTitle");
	Area.Parameters.ErrorsCount1 = String(TSCompositionResult.Total);
	Report.Put(Area);
	
	If TSCompositionResult.Total > 0 Then
		Report.Put(TSCompositionResult.TabularSection);
	EndIf;
	
	Result.Insert("TotalByErrors", TSCompositionResult.Total); 	
	TSCompositionResult = GenerateTabularSection(Template, EventLogData, CollapseWarnings);
	
	Report.Put(Template.GetArea("IsBlankString"));
	Area = Template.GetArea("WarningBlockTitle");
	Area.Parameters.WarningsCount = TSCompositionResult.Total;
	Report.Put(Area);
	
	If TSCompositionResult.Total > 0 Then
		Report.Put(TSCompositionResult.TabularSection);
	EndIf;
	
	Result.Insert("TotalByWarnings", TSCompositionResult.Total);	
	Report.ShowGrid = False; 	
	Result.Insert("Report", Report); 
	Result.Insert("ReportIsBlank", ReportIsBlank);
	Return Result;
	
EndFunction

// Gets a presentation of the physical infobase location to display it to an administrator.
//
// Returns:
//   String - Infobase presentation.
//
// Example:
// - For a file infobase: \\FileServer\1c_ib\
// - For a server infobase: ServerName:1111 / information_base_name.
//
Function InfobasePresentation()
	
	DatabaseConnectionString = InfoBaseConnectionString();
	
	If Common.FileInfobase(DatabaseConnectionString) Then
		Return Mid(DatabaseConnectionString, 6, StrLen(DatabaseConnectionString) - 6);
	EndIf;
		
	// Append the infobase name to the server name.
	SearchPosition = StrFind(Upper(DatabaseConnectionString), "SRVR=");
	If SearchPosition <> 1 Then
		Return Undefined;
	EndIf;
	
	SemicolonPosition = StrFind(DatabaseConnectionString, ";");
	StartPositionForCopying = 6 + 1;
	EndPositionForCopying = SemicolonPosition - 2; 
	
	ServerName = Mid(DatabaseConnectionString, StartPositionForCopying, EndPositionForCopying - StartPositionForCopying + 1);
	
	DatabaseConnectionString = Mid(DatabaseConnectionString, SemicolonPosition + 1);
	
	// Server name position.
	SearchPosition = StrFind(Upper(DatabaseConnectionString), "REF=");
	If SearchPosition <> 1 Then
		Return Undefined;
	EndIf;
	
	StartPositionForCopying = 6;
	SemicolonPosition = StrFind(DatabaseConnectionString, ";");
	EndPositionForCopying = SemicolonPosition - 2; 
	
	IBNameAtServer = Mid(DatabaseConnectionString, StartPositionForCopying, EndPositionForCopying - StartPositionForCopying + 1);
	PathToDatabase = ServerName + "/ " + IBNameAtServer;
	Return PathToDatabase;
	
EndFunction

// Gets error details from the event log for the given period.
//
// Parameters:
//   StartDate    - Date - Beginning of the reporting period.
//   EndDate - Date - The end of the reporting period.
//
// Returns
//   ValueTable - Table of event log filtered records.:
//                    EventLogLevel - EventLogLevel.Error
//                    The beginning and end of the reporting period are passed in the parameters.
//
Function EventLogErrorsInformation(StartDate, EndDate,
			ServerTimeOffset, UserFilter = Undefined)
	
	EventLogData = New ValueTable;
	
	LogLevels = New Array;
	LogLevels.Add(EventLogLevel.Error);
	LogLevels.Add(EventLogLevel.Warning);
	
	Filter = New Structure;
	Filter.Insert("Level", LogLevels);
	Filter.Insert("StartDate", StartDate + ServerTimeOffset);
	Filter.Insert("EndDate", EndDate + ServerTimeOffset);
	
	If UserFilter <> Undefined Then
		Filter.Insert("User", UserFilter);
	EndIf;
	
	SetPrivilegedMode(True);
	UnloadEventLog(EventLogData, Filter);
	SetPrivilegedMode(False);
	
	If ServerTimeOffset <> 0 Then
		For Each TableRow In EventLogData Do
			TableRow.Date = TableRow.Date - ServerTimeOffset;
		EndDo;
	EndIf;
	
	Return EventLogData;
	
EndFunction

// Adds to the report a table of errors grouped by comment.
// 
//
// Parameters:
//   Template  - SpreadsheetDocument - The source of formatted areas that will be used to generate the report.
//                              
//   EventLogData   - ValueTable - "As is" errors and warnings from the event log.
//                              
//   CollapsedData - ValueTable - Error count (collapsed by comment).
//
Function GenerateTabularSection(Template, EventLogData, CollapsedData)
	
	Report = New SpreadsheetDocument;	
	Total = 0;
	
	If CollapsedData.Count() > 0 Then
		Report.Put(Template.GetArea("IsBlankString"));
		
		For Each Record In CollapsedData Do
			Total = Total + Record.TotalByComment;
			RowsArray = EventLogData.FindRows(
				New Structure("Level, Comment",
					EventLogLevel.Error,
					Record.Comment));
			
			Area = Template.GetArea("TabularSectionBodyHeader");
			Area.Parameters.Fill(Record);
			Report.Put(Area);
			
			Report.StartRowGroup(, False);
			For Each String In RowsArray Do
				Area = Template.GetArea("TabularSectionBodyDetails");
				Area.Parameters.Fill(String);
				Report.Put(Area);
			EndDo;
			Report.EndRowGroup();
			Report.Put(Template.GetArea("IsBlankString"));
		EndDo;
	EndIf;
	
	Result = New Structure("TabularSection, Total", Report, Total);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf