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

// Set report form settings.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnDefineSelectionParameters = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
EndProcedure


// Called before importing new settings. Used for modifying DCS reports.
//
// Parameters:
//   Context - Arbitrary
//   SchemaKey - String
//   VariantKey - String
//                - Undefined
//   NewDCSettings - DataCompositionSettings
//                    - Undefined
//   NewDCUserSettings - DataCompositionUserSettings
//                                    - Undefined
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey <> "1" Then
		SchemaKey = "1";
	EndIf;
	
	If EventLog.ServerTimeOffset() = 0 Then
		DataCompositionSchema.Parameters.DatesInServerTimeZone.UseRestriction = True;
	EndIf;
	
	ReportVariant = NewDCSettings.DataParameters.Items.Find("ReportVariant").Value;
	
	If ReportVariant <> "UsersActivityAnalysis" Then
		DataCompositionSchema.Parameters.UsersAndGroups.UseRestriction = True;
		DataCompositionSchema.Parameters.ShouldOutputUtilityUsers.UseRestriction = True;
	EndIf;
	
	If ReportVariant <> "DepartmentActivityAnalysis" Then
		DataCompositionSchema.Parameters.Department.UseRestriction = True;
	EndIf;
	
	If ReportVariant <> "UserActivity" Then
		DataCompositionSchema.Parameters.User.UseRestriction = True;
		DataCompositionSchema.Parameters.OutputBusinessProcesses.UseRestriction = True;
		DataCompositionSchema.Parameters.OutputTasks.UseRestriction = True;
		DataCompositionSchema.Parameters.OutputCatalogs.UseRestriction = True;
		DataCompositionSchema.Parameters.OutputDocuments.UseRestriction = True;
	EndIf;
	
	If ReportVariant <> "ScheduledJobsDuration" Then
		DataCompositionSchema.Parameters.DayPeriod.UseRestriction = True;
		DataCompositionSchema.Parameters.SelectionStart.UseRestriction = True;
		DataCompositionSchema.Parameters.SelectionEnd.UseRestriction = True;
		DataCompositionSchema.Parameters.DisplayBackgroundJobs.UseRestriction = True;
		DataCompositionSchema.Parameters.MinScheduledJobSessionDuration.UseRestriction = True;
		DataCompositionSchema.Parameters.ConcurrentSessionsSize.UseRestriction = True;
		DataCompositionSchema.Parameters.HideScheduledJobs.UseRestriction = True;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsServer = Common.CommonModule("ReportsServer");
		ModuleReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.SettingProperties
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	FieldName = String(SettingProperties.DCField);
	If FieldName = "DataParameters.HideScheduledJobs" Then
		ScheduledJobsArray = AllScheduledJobsList();
		SettingProperties.ValuesForSelection.Clear();
		For Each Item In ScheduledJobsArray Do
			SettingProperties.ValuesForSelection.Add(Item.UID, Item.Description);
		EndDo;
		SettingProperties.ValuesForSelection.SortByPresentation();
	EndIf;
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, ObjectDetailsData, StandardProcessing, StorageAddress)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Raise NStr("vi = 'Hỗ trợ báo cáo chỉ trong vùng dữ liệu và chế độ cục bộ.';
					|ru = 'Отчет поддерживается только в области данных и локальном режиме.';
					|en = 'The report is supported for data areas and the local mode.'; fa = 'The report is supported for data areas and the local mode.';
					|it = 'Отчет поддерживается только в области данных и локальном режиме.';
					|pl = 'The report is supported for data areas and the local mode.';
					|tr = 'Rapor yalnızca veri bölgesi ve yerel modda desteklenir.'");
	EndIf;
	
	StandardProcessing = False;
	ReportSettings = SettingsComposer.GetSettings();
	ReportVariant = ReportSettings.DataParameters.Items.Find("ReportVariant").Value;
	
	If Common.DataSeparationEnabled()
	   And ReportVariant = "ScheduledJobsDuration" Then
		Raise NStr("vi = 'Tùy chọn báo cáo không có sẵn trong ứng dụng trực tuyến.';
					|ru = 'Вариант отчета не доступен в приложении в интернете.';
					|en = 'The report option is unavailable in web apps.'; fa = 'The report option is unavailable in web apps.';
					|it = 'Вариант отчета не доступен в приложении в интернете.';
					|pl = 'The report option is unavailable in web apps.';
					|tr = 'Online uygulamada rapor seçeneği mevcut değildir.'");
	EndIf;
	
	Period = ReportSettings.DataParameters.Items.Find("Period").Value; // StandardPeriod
	DatesInServerTimeZone = ReportSettings.DataParameters.Items.Find("DatesInServerTimeZone").Value;
	If DatesInServerTimeZone Then
		ServerTimeOffset = 0;
	Else
		ServerTimeOffset = EventLog.ServerTimeOffset();
	EndIf;
	
	If ReportVariant <> "ScheduledJobsDuration" Then
		DataCompositionSchema.Parameters.DayPeriod.Use = DataCompositionParameterUse.Auto;
	EndIf;
	
	If ReportVariant = "EventLogMonitor" Then
		ReportGenerationResult = Reports.EventLogAnalysis.
			GenerateEventLogMonitorReport(Period.StartDate, Period.EndDate, ServerTimeOffset);
		// ReportIsBlank - Flag indicating whether the report has no data. Required for report distribution.
		ReportIsBlank = ReportGenerationResult.ReportIsBlank;
		SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
		ResultDocument.Put(ReportGenerationResult.Report);
	ElsIf ReportVariant = "ScheduledJobsDuration" Then
		ScheduledJobsDuration(ReportSettings, ResultDocument, SettingsComposer, ServerTimeOffset);
	Else
		ReportParameters = UserActivityReportParameters(ReportSettings);
		ReportParameters.Insert("StartDate", Period.StartDate);
		ReportParameters.Insert("EndDate", Period.EndDate);
		ReportParameters.Insert("ReportVariant", ReportVariant);
		ReportParameters.Insert("DatesInServerTimeZone", DatesInServerTimeZone);
		If ReportVariant = "UsersActivityAnalysis"
		 Or ReportVariant = "DepartmentActivityAnalysis" Then
			DataCompositionSchema.Parameters.User.Use = DataCompositionParameterUse.Auto;
		EndIf;
		
		TemplateComposer = New DataCompositionTemplateComposer;
		CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, ObjectDetailsData);
		CompositionProcessor = New DataCompositionProcessor;
		ReportData = Reports.EventLogAnalysis.EventLogData1(ReportParameters);
		SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportData.ReportIsBlank);
		ReportData.Delete("ReportIsBlank");
		CompositionProcessor.Initialize(CompositionTemplate, ReportData, ObjectDetailsData, True);
		OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
		OutputProcessor.SetDocument(ResultDocument);
		OutputProcessor.BeginOutput();
		ResultItem = CompositionProcessor.Next();
		While ResultItem <> Undefined Do
			OutputProcessor.OutputItem(ResultItem);
			ResultItem = CompositionProcessor.Next();
		EndDo;
		ResultDocument.ShowRowGroupLevel(1);
		OutputProcessor.EndOutput();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ReportSettings = SettingsComposer.GetSettings();
	ReportVariant = ReportSettings.DataParameters.Items.Find("ReportVariant").Value;
	If ReportVariant = "ScheduledJobsDuration" Then
		DayPeriod = ReportSettings.DataParameters.Items.Find("DayPeriod").Value;
		SelectionStart = ReportSettings.DataParameters.Items.Find("SelectionStart");
		SelectionEnd = ReportSettings.DataParameters.Items.Find("SelectionEnd");
		
		If Not ValueIsFilled(DayPeriod.Date) Then
			Common.MessageToUser(
				NStr("vi = 'Chưa điền giá trị trường Ngày.';
					|ru = 'Не заполнено значение поля День.';
					|en = 'The ""Day"" field is blank.'; fa = 'The ""Day"" field is blank.';
					|it = 'Il valore del campo Giorno non è compilato';
					|pl = 'Wartość pola Dzień nie jest wypełniona.';
					|tr = 'Alan değeri Gün girilmemiş.'"), , );
			Cancel = True;
			Return;
		EndIf;
		
		If ValueIsFilled(SelectionStart.Value)
		And ValueIsFilled(SelectionEnd.Value)
		And SelectionStart.Value > SelectionEnd.Value
		And SelectionStart.Use 
		And SelectionEnd.Use Then
			Common.MessageToUser(
				NStr("vi = 'Giá trị bắt đầu kỳ không thể lớn hơn giá trị cuối.';
					|ru = 'Значение начала периода не может быть больше значения конца.';
					|en = 'The beginning of the period must be earlier than the end of the period.'; fa = 'The beginning of the period must be earlier than the end of the period.';
					|it = 'Il valore di inizio periodo non può essere superiore al valore del termine.';
					|pl = 'Wartość początku okresu nie może być większa, niż wartość końca.';
					|tr = 'Dönem başlangıç değeri, dönem sonu değerinden daha geç olamaz.'"), , );
			Cancel = True;
			Return;
		EndIf;
		
	ElsIf ReportVariant = "UserActivity" Then
		
		User = ReportSettings.DataParameters.Items.Find("User").Value;
		
		If Not ValueIsFilled(User) Then
			Common.MessageToUser(
				NStr("vi = 'Chưa điền giá trị trường Người sử dụng.';
					|ru = 'Не заполнено значение поля Пользователь.';
					|en = 'The ""User"" field is blank.'; fa = 'The ""User"" field is blank.';
					|it = 'Il valore del campo Utente non è compilato.';
					|pl = 'Wartość pola Użytkownik nie jest wypełniona.';
					|tr = 'Alan değeri Kullanıcı girilmedi.'"), , );
			Cancel = True;
			Return;
		EndIf;
		
		If Reports.EventLogAnalysis.UserForSelection(User) = Undefined Then
			Common.MessageToUser(
				NStr("vi = 'Chỉ có thể lập báo cáo đối với người sử dụng mà đã chỉ ra tên đăng nhập vào ứng dụng.';
					|ru = 'Формирование отчета возможно только для пользователя, которому указано имя для входа в приложение.';
					|en = 'Cannot create a report because the username is not specified.'; fa = 'Cannot create a report because the username is not specified.';
					|it = 'Формирование отчета возможно только для пользователя, которому указано имя для входа в приложение.';
					|pl = 'Cannot create a report because the username is not specified.';
					|tr = 'Rapor, yalnızca uygulama için oturum açma adı belirtilmiş olan kullanıcı için oluşturulabilir.'"), , );
			Cancel = True;
			Return;
		EndIf;
		
	ElsIf ReportVariant = "UsersActivityAnalysis" Then
		
		UsersAndGroups = ReportSettings.DataParameters.Items.Find("UsersAndGroups").Value;
		
		If TypeOf(UsersAndGroups) = Type("CatalogRef.Users") Then
			
			If Reports.EventLogAnalysis.UserForSelection(UsersAndGroups) = Undefined Then
				Common.MessageToUser(
					NStr("vi = 'Chỉ có thể lập báo cáo đối với người sử dụng mà đã chỉ ra tên đăng nhập vào ứng dụng.';
						|ru = 'Формирование отчета возможно только для пользователя, которому указано имя для входа в приложение.';
						|en = 'Cannot create a report because the username is not specified.'; fa = 'Cannot create a report because the username is not specified.';
						|it = 'Формирование отчета возможно только для пользователя, которому указано имя для входа в приложение.';
						|pl = 'Cannot create a report because the username is not specified.';
						|tr = 'Rapor, yalnızca uygulama için oturum açma adı belirtilmiş olan kullanıcı için oluşturulabilir.'"), , );
				Cancel = True;
				Return;
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(UsersAndGroups) Then
			Common.MessageToUser(
				NStr("vi = 'Chưa điền giá trị trường Người sử dụng.';
					|ru = 'Не заполнено значение поля Пользователи.';
					|en = 'The ""Users"" field is blank.'; fa = 'The ""Users"" field is blank.';
					|it = 'Il valore del campo Utenti non è compilato.';
					|pl = 'Wartość pola Użytkownicy nie jest wypełniona.';
					|tr = 'Alan değeri Kullanıcılar girilmemiş.'"), , );
			Cancel = True;
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function UserActivityReportParameters(ReportSettings)
	
	UsersAndGroups = ReportSettings.DataParameters.Items.Find("UsersAndGroups").Value;
	ShouldOutputUtilityUsers = ReportSettings.DataParameters.Items.Find("ShouldOutputUtilityUsers").Value;
	Department = ?(ReportSettings.DataParameters.Items.Find("Department").Use,
		ReportSettings.DataParameters.Items.Find("Department").Value, Undefined);
	User = ReportSettings.DataParameters.Items.Find("User").Value;
	OutputBusinessProcesses = ReportSettings.DataParameters.Items.Find("OutputBusinessProcesses");
	OutputTasks = ReportSettings.DataParameters.Items.Find("OutputTasks");
	OutputCatalogs = ReportSettings.DataParameters.Items.Find("OutputCatalogs");
	OutputDocuments = ReportSettings.DataParameters.Items.Find("OutputDocuments");
	
	If Not OutputBusinessProcesses.Use Then
		ReportSettings.DataParameters.SetParameterValue("OutputBusinessProcesses", False);
	EndIf;
	If Not OutputTasks.Use Then
		ReportSettings.DataParameters.SetParameterValue("OutputTasks", False);
	EndIf;
	If Not OutputCatalogs.Use Then
		ReportSettings.DataParameters.SetParameterValue("OutputCatalogs", False);
	EndIf;
	If Not OutputDocuments.Use Then
		ReportSettings.DataParameters.SetParameterValue("OutputDocuments", False);
	EndIf;		
	
	ReportParameters = New Structure;
	ReportParameters.Insert("UsersAndGroups", UsersAndGroups);
	ReportParameters.Insert("ShouldOutputUtilityUsers", ShouldOutputUtilityUsers);
	ReportParameters.Insert("Department", Department);
	ReportParameters.Insert("User", User);
	ReportParameters.Insert("OutputBusinessProcesses", OutputBusinessProcesses.Value);
	ReportParameters.Insert("OutputTasks", OutputTasks.Value);
	ReportParameters.Insert("OutputCatalogs", OutputCatalogs.Value);
	ReportParameters.Insert("OutputDocuments", OutputDocuments.Value);
	
	Return ReportParameters;
EndFunction

Procedure ScheduledJobsDuration(ReportSettings, ResultDocument, Var_SettingsComposer, ServerTimeOffset)
	TitleOutput = ReportSettings.OutputParameters.Items.Find("TitleOutput");
	FilterOutput = ReportSettings.OutputParameters.Items.Find("FilterOutput");
	ReportHeader = ReportSettings.OutputParameters.Items.Find("Title");
	DayPeriod = ReportSettings.DataParameters.Items.Find("DayPeriod").Value;
	SelectionStart = ReportSettings.DataParameters.Items.Find("SelectionStart");
	SelectionEnd = ReportSettings.DataParameters.Items.Find("SelectionEnd");
	MinScheduledJobSessionDuration = ReportSettings.DataParameters.Items.Find(
																"MinScheduledJobSessionDuration");
	DisplayBackgroundJobs = ReportSettings.DataParameters.Items.Find("DisplayBackgroundJobs");
	HideScheduledJobs = ReportSettings.DataParameters.Items.Find("HideScheduledJobs");
	ConcurrentSessionsSize = ReportSettings.DataParameters.Items.Find("ConcurrentSessionsSize");
	
	// Checking for parameter usage flag.
	If Not MinScheduledJobSessionDuration.Use Then
		ReportSettings.DataParameters.SetParameterValue("MinScheduledJobSessionDuration", 0);
	EndIf;
	If Not DisplayBackgroundJobs.Use Then
		ReportSettings.DataParameters.SetParameterValue("DisplayBackgroundJobs", False);
	EndIf;
	If Not HideScheduledJobs.Use Then
		ReportSettings.DataParameters.SetParameterValue("HideScheduledJobs", "");
	EndIf;
	If Not ConcurrentSessionsSize.Use Then
		ReportSettings.DataParameters.SetParameterValue("ConcurrentSessionsSize", 0);
	EndIf;
		
	If Not ValueIsFilled(SelectionStart.Value) Then
		DayPeriodStartDate = BegOfDay(DayPeriod);
	ElsIf Not SelectionStart.Use Then
		DayPeriodStartDate = BegOfDay(DayPeriod);
	Else
		DayPeriodStartDate = Date(Format(DayPeriod.Date, "DLF=D") + " " + Format(SelectionStart.Value, "DLF=T"));
	EndIf;
	
	If Not ValueIsFilled(SelectionEnd.Value) Then
		DayPeriodEndDate = EndOfDay(DayPeriod);
	ElsIf Not SelectionEnd.Use Then
		DayPeriodEndDate = EndOfDay(DayPeriod);
	Else
		DayPeriodEndDate = Date(Format(DayPeriod.Date, "DLF=D") + " " + Format(SelectionEnd.Value, "DLF=T"));
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("StartDate", DayPeriodStartDate);
	FillParameters.Insert("EndDate", DayPeriodEndDate);
	FillParameters.Insert("ConcurrentSessionsSize", ConcurrentSessionsSize.Value);
	FillParameters.Insert("MinScheduledJobSessionDuration", 
								  MinScheduledJobSessionDuration.Value);
	FillParameters.Insert("DisplayBackgroundJobs", DisplayBackgroundJobs.Value);
	FillParameters.Insert("TitleOutput", TitleOutput);
	FillParameters.Insert("FilterOutput", FilterOutput);
	FillParameters.Insert("ReportHeader", ReportHeader);
	FillParameters.Insert("HideScheduledJobs", HideScheduledJobs.Value);
	FillParameters.Insert("ServerTimeOffset", ServerTimeOffset);
	
	ReportGenerationResult =
		Reports.EventLogAnalysis.GenerateScheduledJobsDurationReport(FillParameters);
	Var_SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportGenerationResult.ReportIsBlank);
	ResultDocument.Put(ReportGenerationResult.Report);
EndProcedure

// Returns:
//  Array of Structure:
//    * UID - UUID
//    * Description - String
//
Function AllScheduledJobsList()
	
	ScheduledJobsArray = New Array;
	If Common.DataSeparationEnabled() Then
		Return ScheduledJobsArray;
	EndIf;
	
	SetPrivilegedMode(True);
	ScheduledJobsList = ScheduledJobsServer.FindJobs(New Structure);
	For Each Item In ScheduledJobsList Do
		If Item.Description <> "" Then
			ScheduledJobsArray.Add(New Structure("UID, Description",
				Item.UUID, Item.Description));
		ElsIf Item.Metadata.Synonym <> "" Then
			ScheduledJobsArray.Add(New Structure("UID, Description",
				Item.UUID, Item.Metadata.Synonym));
		EndIf;
	EndDo;
	
	Return ScheduledJobsArray;
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf