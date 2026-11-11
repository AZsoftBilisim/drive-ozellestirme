#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("DisplaySource", DisplaySource);
	
	If Parameters.Property("SourceID") Then
		Source = Parameters["Source"];
		SourceID = Parameters["SourceID"];
		SourceType = Parameters["SourceType"];
	EndIf;
	
	Items.Source.Visible = DisplaySource;
	
	EnumerationValueDuration = "Duration";
	EnumerationValueStartTime = "BeginTime";
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If ValueIsFilled(SourceID) Then
		
		// We will get the timekeeping data
		If Find(SourceType, "Document") Or Find(SourceType, "Task") Then
			
			PackageQueries = New Array;
			
			PackageQueries.Add(
				IntegrationWith1CDocumentManagementCore.GetNewObjectRequest(Proxy, "DMActualWork"));
			
			Query = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMGetChronometrationSettingsRequest");
			ListOfObjects = Query.objects; // XDTOList
			ObjectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, SourceID, SourceType);
			ListOfObjects.Add(ObjectID);
			PackageQueries.Add(Query);
			
			ObjectToGetFromTO = New Structure("ID, Type", SourceID, SourceType);
			FieldsReceived = New Array;
			FieldsReceived.Add("project");
			If Find(SourceType, "Task") Then
				FieldsReceived.Add("projectTask");
			EndIf;
			PackageQueries.Add(
				IntegrationWith1CDocumentManagementCore.GetRequestObjects(
					Proxy,
					CommonClientServer.ValueInArray(ObjectToGetFromTO),
					FieldsReceived));
			
			ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
				Proxy,
				PackageQueries,
				True);
			
			FillInObjectForm(ResponseToPackageRequests.responses[0]);
			
			TimingParameters = ResponseToPackageRequests.responses[1].settings[0];
			If TimingParameters.IsSet("beginDate") And ValueIsFilled(TimingParameters.beginDate) Then
				Begin = TimingParameters.beginDate;
			EndIf;
			If TimingParameters.IsSet("timeInputMethod") Then
				IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
					ThisObject, TimingParameters.timeInputMethod, "MethodOfIndicatingTime", False);
			EndIf;
			If TimingParameters.IsSet("workType") Then
				IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
					ThisObject, TimingParameters.workType, "WorkKind", False);
			EndIf;
			If ValueIsFilled(Begin) And ValueIsFilled(Ending) Then
				Duration = Ending - Begin;
			EndIf;
			
			BasisObject = ResponseToPackageRequests.responses[2].objects[0];
			If BasisObject.IsSet("project") Then
				Project = BasisObject.project.name;
				ProjectID = BasisObject.project.objectID.ID;
				If BasisObject.Properties().Get("projectTask") <> Undefined
						And BasisObject.IsSet("projectTask") Then
					TaskOfTheProject = BasisObject.projectTask.name;
					TaskOfTheProjectID = BasisObject.projectTask.objectID.ID;
					TaskOfTheProjectType = BasisObject.projectTask.objectID.type;
				EndIf;
			EndIf;
			
		EndIf;
		
	Else
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetNewObjectRequest");
		Query.type = "DMActualWork";
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		XDTODataObject = Result;
		
		FillInObjectForm(XDTODataObject);
		
	EndIf;
	
	If Not ValueIsFilled(WorkDescription) Then
		
		If ValueIsFilled(ExternalObject) Then
			
			MetadataObject = Parameters.ExternalObject.Metadata();
			
			If Metadata.Catalogs.Contains(MetadataObject)
					Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
				SubstitutionString = StrTemplate("%1 (%2)",
					String(Parameters.ExternalObject),
					String(MetadataObject.ObjectPresentation));
			Else
				SubstitutionString = String(Parameters.ExternalObject);
			EndIf;
			
			WorkDescription = StrTemplate(NStr("vi = 'Công việc ""%1""';
												|ru = 'Работа над ""%1""';
												|en = 'Work on ""%1""'; fa = 'Work on ""%1""';
												|it = 'Lavoro su ""%1""';
												|pl = 'Praca nad ""%1""';
												|tr = '""%1"" üzerinde çalışma'"), SubstitutionString);
			
		Else
			
			WorkDescription = StrTemplate(NStr("vi = 'Công việc ""%1""';
												|ru = 'Работа над ""%1""';
												|en = 'Work on ""%1""'; fa = 'Work on ""%1""';
												|it = 'Lavoro su ""%1""';
												|pl = 'Praca nad ""%1""';
												|tr = '""%1"" üzerinde çalışma'"), Source);
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(AddedOn) Then
		AddedOn = CurrentSessionDate();
	EndIf;
	
	WorkDuration = IntegrationWith1CDocumentManagementClientServer.NumberPerLine(Duration);
	ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(Project, TaskOfTheProject);
	
	If Not ValueIsFilled(MethodOfIndicatingTimeID) Then
		MethodOfIndicatingTimeID = EnumerationValueDuration;
	EndIf;
	
	If MethodOfIndicatingTime = EnumerationValueDuration Then
		Items.WorkDuration.Visible = True;
		Items.Begin.Visible = False;
		Items.Ending.Visible = False;
	Else
		Items.WorkDuration.Visible = False;
		Items.Begin.Visible = True;
		Items.Ending.Visible = True;
	EndIf;
	
	// Timekeeping and projects.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		Items.ProjectTask.Visible = False;
		Items.Ending.Visible = False;
		Items.AddedOn.ReadOnly = True;
		Items.AddedOn.Title = NStr("vi = 'Thêm vào báo cáo trong';
									|ru = 'Добавить в отчет за';
									|en = 'Add to report for'; fa = 'Add to report for';
									|it = 'Aggiungere al report per';
									|pl = 'Dodaj do raportu za';
									|tr = 'İçin rapora ekle'");
		Items.Begin.Title = NStr("vi = 'Thời gian bắt đầu công việc';
								|ru = 'Время начала работы';
								|en = 'Time of start of work'; fa = 'Time of start of work';
								|it = 'Ora di inizio lavoro';
								|pl = 'Czas początku pracy';
								|tr = 'Çalışma başlama tarihi'");
	Else
		TimekeepingFunctionalityIsAvailable = True;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "DocumentManagement_SelectAValueFromTheListCompletion" And Source = ThisObject Then
		If Parameter = "Project" Then
			ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(Project, TaskOfTheProject);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Begin = Begin - Second(Begin);
	
EndProcedure

&AtClient
Procedure EndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Ending = Ending - Second(Ending);
	
EndProcedure

&AtClient
Procedure UserStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("User", ThisObject);
	
EndProcedure

&AtClient
Procedure UserAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure UserTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"User",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UserChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"User",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure WorkKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		"DMWorkType",
		"WorkKind",
		ThisObject);
	
EndProcedure

&AtClient
Procedure WorkKindAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMWorkType",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkKindTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMWorkType",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"WorkKind",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject,
				False,
				Item);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkKindChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"WorkKind",
		ValueSelected,
		StandardProcessing,
		ThisObject,
		False,
		Item);
	
EndProcedure

&AtClient
Procedure ProjectTaskAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMProject",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProjectTaskTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMProject",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Project",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject,
				False,
				Item);
			
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProjectTaskStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList("DMProject", "Project", ThisObject);
	
	TaskOfTheProject = "";
	TaskOfTheProjectID = "";
	ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(Project, TaskOfTheProject);
	
EndProcedure

&AtClient
Procedure ProjectTaskChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Project",
		ValueSelected,
		StandardProcessing,
		ThisObject,
		False,
		Item);
	
	If ValueSelected <> Undefined And ValueSelected.type = "DMProject" Then
		TaskOfTheProject = "";
		TaskOfTheProjectID = "";
	EndIf;
	
	ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(Project, TaskOfTheProject);
	
EndProcedure

&AtClient
Procedure ProjectTaskOnChange(Item)
	
	If Not ValueIsFilled(ProjectTask) Then
		Project = "";
		ProjectID = "";
		TaskOfTheProject = "";
		TaskOfTheProjectID = "";
	EndIf;
	
	ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(Project, TaskOfTheProject);
	
EndProcedure

&AtClient
Procedure ProjectTaskClearing(Item, StandardProcessing)
	
	Project = "";
	ProjectID = "";
	TaskOfTheProject = "";
	TaskOfTheProjectID = "";
	
	ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(Project, TaskOfTheProject);
	
EndProcedure

&AtClient
Procedure WorkDurationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceList = TimingList();
	
	Notification = New CallbackDescription("WorkDurationStartChoiceCompletion", ThisObject);
	ShowChooseFromList(Notification, ChoiceList, Item);
	
EndProcedure

&AtClient
Procedure SourceClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Source) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(SourceType, SourceID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkKindClearing(Item, StandardProcessing)
	
	WorkKind = "";
	WorkKindID = "";
	WorkKindType = "";
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Add(Command)
	
	ClearMessages();
	
	Cancel = False;
	If Not ValueIsFilled(MethodOfIndicatingTimeID) Then
		MethodOfIndicatingTimeID =EnumerationValueDuration;
	EndIf;
	
	If Not ValueIsFilled(WorkKind) Or Not ValueIsFilled(WorkKindID) Then
		CommonClient.MessageToUser(
			CommonClientServer.FillingErrorText(,, NStr("vi = 'Dạng công việc';
														|ru = 'Вид работ';
														|en = 'Activity kind'; fa = 'نوع فعالیت';
														|it = 'Вид работ';
														|pl = 'Rodzaj prac';
														|tr = 'İş türü'")),,
			"WorkKind",,
			Cancel);
	EndIf;
	
	If MethodOfIndicatingTimeID = EnumerationValueDuration Then
		If Not ValueIsFilled(WorkDuration) Or WorkDuration = "00:00" Then
			CommonClient.MessageToUser(
				CommonClientServer.FillingErrorText(,, NStr("vi = 'Thời lượng';
															|ru = 'Длительность';
															|en = 'Duration'; fa = 'مدت';
															|it = 'Durata';
															|pl = 'Duration';
															|tr = 'Süre'")),,
				"WorkDuration",,
				Cancel);
		EndIf;
	Else
		If Not ValueIsFilled(Begin) Then
			CommonClient.MessageToUser(
				CommonClientServer.FillingErrorText(,, NStr("vi = 'Bắt đầu';
															|ru = 'Начало';
															|en = 'Start'; fa = 'شروع';
															|it = 'Inizio';
															|pl = 'Początek';
															|tr = 'Başlangıç'")),,
				"Begin",,
				Cancel);
		EndIf;
		
		If TimekeepingFunctionalityIsAvailable Then
			If Not ValueIsFilled(Ending) Then
				CommonClient.MessageToUser(
					CommonClientServer.FillingErrorText(,, NStr("vi = 'Kết thúc';
																|ru = 'Окончание';
																|en = 'End'; fa = 'پایان';
																|it = 'Fine';
																|pl = 'Zakończenie';
																|tr = 'Bitiş'")),,
					"Ending",,
					Cancel);
			EndIf;
				
			If ValueIsFilled(Begin) And ValueIsFilled(Ending) And Begin > Ending Then
				CommonClient.MessageToUser(
					NStr("vi = 'Thời gian kết thúc nhỏ hơn thời gian bắt đầu';
						|ru = 'Время окончания меньше, чем время начала';
						|en = 'End time is less than the start time '; fa = 'End time is less than the start time ';
						|it = 'L''ora di fine è precedente all''ora di avvio';
						|pl = 'Czas zakończenia jest mniejszy niż czas rozpoczęcia';
						|tr = 'Bitiş zamanı, başlangıç ​​zamanından daha az'"),,
					"Ending",,
					Cancel);
			EndIf;
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If MethodOfIndicatingTimeID = EnumerationValueDuration Then
		Duration = IntegrationWith1CDocumentManagementClientServer.NumberFromString(WorkDuration);
	ElsIf ValueIsFilled(Begin) And ValueIsFilled(Ending) Then
		Duration = Ending - Begin;
	EndIf;
	
	WriteData();
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("name", Source);
	NotificationParameters.Insert("ID", SourceID);
	NotificationParameters.Insert("type", SourceType);
	
	Notify("Recording_1CDocumentManagementTimeSpent", NotificationParameters, SourceID);
	
	Close(True);
	
EndProcedure

&AtClient
Procedure DontAdd(Command)
	
	Close(False);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WorkDurationStartChoiceCompletion(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	WorkDuration = Result.Value;
	
EndProcedure

&AtServer
Procedure WriteData()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMActualWork");
	
	MatchingBankDetails = New Map;
	MatchingBankDetails.Insert("AddedOn",  "addDate");
	MatchingBankDetails.Insert("Begin",          "begin");
	MatchingBankDetails.Insert("Ending",       "end");
	MatchingBankDetails.Insert("WorkDescription",  "description");
	MatchingBankDetails.Insert("Duration",    "duration");
	MatchingBankDetails.Insert("WorkKind",        "workType");
	MatchingBankDetails.Insert("Project",          "project");
	MatchingBankDetails.Insert("TaskOfTheProject", "projectTask");
	MatchingBankDetails.Insert("Source",        "source");
	
	For Each MapRow In MatchingBankDetails Do
		
		IntegrationWith1CDocumentManagement.FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			XDTODataObject,
			MapRow.Value,
			ThisObject,
			MapRow.Key);
		
	EndDo;
	
	If ValueIsFilled(ExternalObject) Then
		XDTODataObject.externalSource = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,
			ExternalObject);
	EndIf;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateRequest");
	Query.object = XDTODataObject;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
EndProcedure

&AtServer
Procedure FillInObjectForm(XDTODataObject)
	
	AddedOn = XDTODataObject.addDate;
	Begin = XDTODataObject.begin;
	Ending = XDTODataObject.end;
	WorkDescription = XDTODataObject.description;
	Duration = XDTODataObject.duration;
	KeepRecordsOnProjects = XDTODataObject.projectsEnabled;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.workType,
		"WorkKind",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.project,
		"Project",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.projectTask,
		"TaskOfTheProject",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.source,
		"Source",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.timeInputMethod,
		"MethodOfIndicatingTime",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.user,
		"User",
		False);
	
EndProcedure

&AtClientAtServerNoContext
Function TimingList()
	
	ChoiceList = New ValueList;
	
	ChoiceList.Add("00:15");
	ChoiceList.Add("00:30");
	ChoiceList.Add("00:45");
	ChoiceList.Add("01:00");
	ChoiceList.Add("01:30");
	ChoiceList.Add("02:00");
	ChoiceList.Add("03:00");
	ChoiceList.Add("04:00");
	ChoiceList.Add("05:00");
	
	Return ChoiceList;
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_Begin" Then
		BeginOnChange(Items.Begin);
	ElsIf Item.Name = "sh_ShamsiInput_F_Ending" Then
		EndingOnChange(Items.Ending);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
