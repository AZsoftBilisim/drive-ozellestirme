#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ID = Parameters.id;
	Type = Parameters.type;
	If Not ValueIsFilled(Type) Then
		Type = "DMDailyReport";
	EndIf;
	
	EnumerationValueDuration = "Duration";
	EnumerationValueStartTime  = "BeginTime";
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If ValueIsFilled(ID) And ValueIsFilled(Type) Then
		XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Parameters.type,
			Parameters.id);
	Else
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetNewObjectRequest");
		Query.type = Type;
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		XDTODataObject = Result;
		Modified = True;
	EndIf;
	
	FillInObjectForm(XDTODataObject);
	
	// Setting field visibility.
	SetVisibility1();
	
	If Properties.Count() > 0 Then
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	EndIf;
	
	// Timing.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		Items.WorksProjectTask.Visible = False;
		Items.WorksEnding.Visible = False;
	Else
		TimekeepingFunctionalityIsAvailable = True;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CalculateLengthOfDay();
	UpgradeBasement();
	
	TestConnection();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ClosingWithParameter Then
		Return;
	EndIf;
	
	If Modified Then
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,,WarningText);
		
	Else
		
		Cancel = True;
		AttachIdleHandler("CloseWithParameter", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" And Source <> ThisObject Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
	If EventName = "DocumentManagement_SelectAValueFromTheListInTheTableCompletion"
			And Source = ThisObject
			And Parameter.Attribute = "Project" Then
		Parameter.Data.TaskOfTheProject = "";
		Parameter.Data.TaskOfTheProjectID = "";
		Parameter.Data.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
			Parameter.Data.Project,
			Parameter.Data.TaskOfTheProject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	Notification = New CallbackDescription("AuthorizationSettingsDecorationClickCompletion", ThisObject);
	NameOfParameterForm = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement";
	
	OpenForm(NameOfParameterForm,, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsDecorationClickCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingDate();
	
EndProcedure

&AtClient
Procedure BegOfDayOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	BegOfDay = BegOfDay - Second(BegOfDay);
	
	If BegOfDay > EndDay And ValueIsFilled(EndDay) Then
		ShowMessageBox(, NStr("vi = 'Thời gian đầu ngày đã chỉ ra lớn hơn thời gian cuối ngày';
								|ru = 'Указанное время начала дня больше времени окончания';
								|en = 'The start time must be less than the end time'; fa = 'The start time must be less than the end time';
								|it = 'L''ora di avvio del giorno indicata è successiva all''ora di fine';
								|pl = 'Podany czas początku dnia jest większy niż czas zakończenia';
								|tr = 'Günün belirtilen başlangıç ​​saati, bitiş saatinden daha fazla'"));
	EndIf;
	
	CalculateLengthOfDay();
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure EndDayOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	EndDay = EndDay - Second(EndDay);
	
	If EndDay < BegOfDay And ValueIsFilled(EndDay) Then
		ShowMessageBox(, NStr("vi = 'Thời gian cuối ngày đã chỉ ra nhỏ hơn thời gian đầu ngày';
								|ru = 'Указанное время окончания дня меньше времени начала';
								|en = 'The end time you specified is less than the start time.'; fa = 'The end time you specified is less than the start time.';
								|it = 'L''ora di fine giorno indicata è precedente all''ora di avvio';
								|pl = 'Podany czas zakończenia dnia jest mniejszy niż czas początku';
								|tr = 'Günün belirtilen bitiş saati, başlangıç ​​saatinden daha az'"));
	EndIf;
	
	If (MethodOfIndicatingTimeID = EnumerationValueStartTime)
			And (Works.Count() > 0)
			And ValueIsFilled(EndDay)
			And (EndDay < Works[Works.Count() - 1].Begin) Then
		ShowMessageBox(, NStr("vi = 'Thời gian cuối ngày đã chỉ ra nhỏ hơn thời gian đầu ngày của một trong các công việc';
								|ru = 'Указанное время окончания дня меньше времени начала одной из работ';
								|en = 'The end time you specified is less than the start time of one of the works'; fa = 'The end time you specified is less than the start time of one of the works';
								|it = 'L''ora di fine giorno indicata è precedente all''ora di avvio di uno dei lavori';
								|pl = 'Wskazany czas zakończenia dnia jest mniejsze niż czas początku jednej z prac';
								|tr = 'Günün belirtilen bitiş saati, işlerden birinin başlangıç ​​saatinden daha az'"));
		EndDay = '00010101';
	EndIf;
	
	CalculateStringDuration();
	CalculateLengthOfDay();
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure UserStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("User", ThisObject);
	
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
Procedure UserChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"User",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure PropertiesValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.SelectValueOfAdditionalProps(
		ThisObject,
		Item,
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWorks

&AtClient
Procedure WorksOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Works.CurrentData;
	
	If Not NewRow Or CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not Copy Then
		CurrentData.WorkKind = MainTypeOfWork;
		CurrentData.WorkKindID = MainTypeOfWorkID;
		CurrentData.WorkKindType = MainTypeOfWorkType;
		CurrentData.Project = MainProject;
		CurrentData.ProjectID = MainProjectID;
		CurrentData.ProjectType = MainProjectType;
		CurrentData.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
			CurrentData.Project,
			CurrentData.TaskOfTheProject);
		FillInListOfSourceTypes(CurrentData.SourceListOfTypes);
	EndIf;
	
	If MethodOfIndicatingTimeID = EnumerationValueStartTime Then
		If TimekeepingFunctionalityIsAvailable Then
			String = Works.FindByID(CurrentData.GetID());
			IndexOf = Works.IndexOf(String);
			If IndexOf > 0 Then
				CurrentData.Begin = Works[IndexOf - 1].Ending;
			Else
				CurrentData.Begin = BegOfDay;
			EndIf;
		Else
			CurrentDate = CurrentDate(); // The use is justified: the date-time is fixed on the client.
			CurrentData.Begin = CurrentDate - Second(CurrentDate);
		EndIf;
		CalculateStringDuration();
		RecalculateStartOfDay();
	EndIf;
	
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure WorksOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateStringDuration();
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure WorksAfterDeleteRow(Item)
	
	CalculateStringDuration();
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure WorksBeginOnChange(Item)
	
	If Not TimekeepingFunctionalityIsAvailable Then
		CurrentData = Items.Works.CurrentData;
#If WebClient Then
		CurrentData.Begin = CurrentData.Begin - Second(CurrentData.Begin);
#EndIf
		
		CalculateStringDuration();
		RecalculateStartOfDay();
		UpgradeBasement();
	EndIf;
	
EndProcedure

&AtClient
Procedure WorksDurationOfRowOnChange(Item)
	
	CurrentData = Items.Works.CurrentData;
	
	If Not IntegrationWith1CDocumentManagementClientServer.CheckFormat(CurrentData.DurationOfRow) Then
		CurrentData.DurationOfRow = "";
	EndIf;
	CurrentData.Duration = IntegrationWith1CDocumentManagementClientServer.NumberFromString(CurrentData.DurationOfRow);
	
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure WorksWorkKindOnChange(Item)
	
	CurrentData = Items.Works.CurrentData;
	If IsBlankString(CurrentData.WorkKind) Then
		CurrentData.WorkKindID = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure WorksWorkKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Works.CurrentData;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
		"DMWorkType",
		"WorkKind",
		CurrentData,
		ThisObject);
	
EndProcedure

&AtClient
Procedure WorksWorkKindAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMWorkType",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure WorksWorkKindTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
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
				True,
				Item);
			StandardProcessing = True;
		EndIf;
		
		Items.Works.CurrentData.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
			Items.Works.CurrentData.Project,
			Items.Works.CurrentData.TaskOfTheProject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WorksWorkKindChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"WorkKind",
		ValueSelected,
		StandardProcessing,
		ThisObject,
		True,
		Item);
	
EndProcedure

&AtClient
Procedure WorksProjectTaskOnChange(Item)
	
	String = Items.Works.CurrentData;
	
	If String.ProjectTask = "" Then
		String.Project = "";
		String.ProjectID = "";
		String.TaskOfTheProject = "";
		String.TaskOfTheProjectID = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure WorksProjectTaskStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Works.CurrentData;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
		"DMProject",
		"Project",
		CurrentData,
		ThisObject);
	
	CurrentData.TaskOfTheProject = "";
	CurrentData.TaskOfTheProjectID = "";
	CurrentData.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
		CurrentData.Project,
		CurrentData.TaskOfTheProject);
	
EndProcedure

&AtClient
Procedure WorksProjectTaskAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)

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
				True, Item);
			
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WorksProjectTaskTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
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
				True,
				Item);
			
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WorksProjectTaskChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Project",
		ValueSelected,
		StandardProcessing,
		ThisObject,
		True,
		Item);
	
	If ValueSelected <> Undefined And ValueSelected.type = "DMProject" Then
		Item.Parent.CurrentData.TaskOfTheProject = "";
		Item.Parent.CurrentData.TaskOfTheProjectID = "";
	EndIf;
	
	String = Items.Works.CurrentData;
	String.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
		String.Project,
		String.TaskOfTheProject);
	
EndProcedure

&AtClient
Procedure WorksSourceStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectValueOfCompositeTypePropsInTable(
		ThisObject,
		Items.Works.CurrentData,
		"Source",
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	Cancel = False;
	FillCheckProcessing(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	WriteObject();
	Modified = False;
	IntegrationWith1CDocumentManagementClient.Notify_ObjectRecord(ThisObject);
	
	Close();
	
EndProcedure

&AtClient
Procedure WriteReport(Command)
	
	Cancel = False;
	FillCheckProcessing(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	WriteObject();
	Modified = False;
	IntegrationWith1CDocumentManagementClient.Notify_ObjectRecord(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

// Checks the connection to the DO by displaying the authorization window, if necessary, and changing the form according to the result.
//
&AtClient
Procedure TestConnection()
	
	CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject);
	
EndProcedure

// It is called after checking the connection to BEFORE and changes the form according to the result.
//
&AtClient
Procedure TestConnectionCompletion(Result, Var_Parameters) Export
	
	ProcessFormAccordingToServiceVersion();
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteObject();
	IntegrationWith1CDocumentManagementClient.Notify_ObjectRecord(ThisObject);
	CloseWithParameter();
	
EndProcedure

&AtServer
Procedure WhenChangingDate()
	
	If Not ValueIsFilled(ID) And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
		FilterConditions = ListOfConditions.conditions; // XDTOList
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "beginDate";
		Condition.value = BegOfDay(Date);
		FilterConditions.Add(Condition);
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "endDate";
		Condition.value = EndOfDay(Date);
		FilterConditions.Add(Condition);
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "byUser";
		Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			UserID,
			UserType);
		FilterConditions.Add(Condition);
		
		Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
			Proxy,
			"DMActualWork",
			ListOfConditions);
		
		Works.Clear();
		
		For Each ResponseString In Response.items Do
			
			String = ResponseString.object;
			
			NewRow = Works.Add();
			NewRow.AddedOn = String.addDate;
			NewRow.Begin = String.begin;
			NewRow.Ending = String.end;
			NewRow.Work_5 = String.description;
			NewRow.Duration = String.duration;
			NewRow.DurationOfRow = IntegrationWith1CDocumentManagementClientServer.NumberPerLine(
				NewRow.Duration);
			
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow,
				String.workType,
				"WorkKind",
				False);
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow,
				String.project,
				"Project",
				False);
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow,
				String.projectTask,
				"TaskOfTheProject",
				False);
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow,
				String.source,
				"Source",
				False);
			
			NewRow.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
				NewRow.Project,
				NewRow.TaskOfTheProject);
			
			For Each TypeDetails In String.sourceValueTypes Do
				DataAboutType = New Structure("xdtoClassName, presentation");
				DataAboutType.xdtoClassName = TypeDetails.xdtoClassName;
				DataAboutType.presentation = TypeDetails.presentation;
				NewRow.SourceListOfTypes.Add(DataAboutType, TypeDetails.presentation);
			EndDo;
			
			NewRow.SourceListOfTypes.SortByPresentation();
			
		EndDo;
		
	EndIf;
	
	GenerateFormTitle();
	
EndProcedure

&AtClient
Procedure FillInListOfSourceTypes(TypesList)
	
	TypesList.Clear();
	
	SourceTypes = New Structure;
	SourceTypes.Insert("DMInternalDocument");
	SourceTypes.Insert("DMIncomingEMail");
	SourceTypes.Insert("DMIncomingDocument");
	SourceTypes.Insert("DMDailyReport");
	SourceTypes.Insert("DMBusinessProcessTask");
	SourceTypes.Insert("DMOutgoingEMail");
	SourceTypes.Insert("DMOutgoingDocument");
	SourceTypes.Insert("DMActivity");
	SourceTypes.Insert("DMProject");
	SourceTypes.Insert("DMProjectTask");
	SourceTypes.Insert("DMFile");
	
	For Each Item In SourceTypes Do
		Item.Value = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(Item.Key);
	EndDo;
	
	For Each SourceType In SourceTypes Do
		TypesList.Add(
			New Structure("xdtoClassName, presentation", SourceType.Key, SourceType.Value),
			SourceType.Value);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInObjectForm(XDTODataObject)
	
	ID = XDTODataObject.objectID.ID;
	Type =  XDTODataObject.objectID.type;
	
	Presentation = XDTODataObject.objectID.presentation;
	Title = XDTODataObject.objectID.presentation;
	Date = XDTODataObject.date;
	BegOfDay = XDTODataObject.dayBegin;
	EndDay = XDTODataObject.dayEnd;
	IncorrectDuration = XDTODataObject.durationIncorrect;
	KeepRecordsOnProjects = XDTODataObject.projectsEnabled;
	
	GenerateFormTitle();
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.user,
		"User",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.author,
		"Author",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.timeInputMethod,
		"MethodOfIndicatingTime",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.mainProject,
		"MainProject",
		False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.mainWorkType,
		"MainTypeOfWork",
		False);
	
	Works.Clear();
	
	For Each String In XDTODataObject.works Do
		NewRow = Works.Add();
		NewRow.AddedOn = String.addDate;
		NewRow.Begin = String.begin;
		NewRow.Ending = String.end;
		NewRow.Work_5 = String.description;
		NewRow.Duration = String.duration;
		NewRow.DurationOfRow = IntegrationWith1CDocumentManagementClientServer.NumberPerLine(NewRow.Duration);
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow,
			String.workType,
			"WorkKind",
			False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow,
			String.project,
			"Project",
			False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow,
			String.projectTask,
			"TaskOfTheProject",
			False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow,
			String.source,
			"Source",
			False);
		
		NewRow.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
			NewRow.Project,
			NewRow.TaskOfTheProject);
		
		For Each TypeDetails In String.sourceValueTypes Do
			DataAboutType = New Structure("xdtoClassName, presentation");
			DataAboutType.xdtoClassName = TypeDetails.xdtoClassName;
			DataAboutType.presentation = TypeDetails.presentation;
			NewRow.SourceListOfTypes.Add(DataAboutType, TypeDetails.presentation);
		EndDo;
		
		NewRow.SourceListOfTypes.SortByPresentation();
		
	EndDo;
	
	If MethodOfIndicatingTimeID = EnumerationValueStartTime Then
		Works.Sort("Begin");
	Else
		Works.Sort("AddedOn");
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.PlaceAdditionalDetailsOnForm(
		ThisObject,
		XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(
		ThisObject,
		XDTODataObject);
	
EndProcedure

&AtClient
Procedure CalculateStringDuration()
	
	// Filling in the duration field.
	If (MethodOfIndicatingTimeID = EnumerationValueStartTime) And (Works.Count() > 0) Then
		Works.Sort("Begin Asc");

		If TimekeepingFunctionalityIsAvailable Then
			For Each String In Works Do
				If String.Ending > String.Begin Then
					String.Duration = String.Ending - String.Begin;
				Else
					String.Duration = 0;
				EndIf;
			EndDo;
		Else
			For Indus = 0 To Works.Count() - 2 Do
				Works[Indus].Duration = Works[Indus+1].Begin - Works[Indus].Begin;
			EndDo;
			
			Indus = Works.Count() - 1;
			If ValueIsFilled(EndDay) Then // The last line.
				If Works[Indus].Begin <= EndDay Then
					Works[Indus].Duration = EndDay - Works[Indus].Begin;
				EndIf;
			Else
				Works[Indus].Duration = 0;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateLengthOfDay()
	
	If Not ValueIsFilled(BegOfDay) Or Not ValueIsFilled(EndDay) Then
		LengthOfDay = "";
		
	ElsIf BegOfDay > EndDay Then
		LengthOfDay = "";
		
	Else
		LengthOfDay = IntegrationWith1CDocumentManagementClientServer.NumberPerLine(EndDay - BegOfDay);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateFormTitle()
	
	If Not ValueIsFilled(ID) Then
		Title = NStr("vi = 'Báo cáo công việc hàng ngày (tạo mới)';
					|ru = 'Ежедневный отчет (создание)';
					|en = 'Daily report (creation)'; fa = 'Daily report (creation)';
					|it = 'Report giornaliero (creazione)';
					|pl = 'Raport codzienny (tworzenie)';
					|tr = 'Günlün rapor (oluşturma)'");
	Else
		Title = StrTemplate(NStr("vi = 'Báo cáo công việc hàng ngày trong %1';
								|ru = 'Ежедневный отчет за %1';
								|en = 'Daily report for %1'; fa = 'Daily report for %1';
								|it = 'Report giornaliero per %1';
								|pl = 'Codzienny raport za %1';
								|tr = '%1 için günlük rapor'"), Format(Date, "DLF=D"));
	EndIf;
	
	Items.BegOfDay.Title = Title(Format(Date, "DF=dddd"));
	
EndProcedure

&AtClient
Procedure UpgradeBasement()
	
	// The output of the line "In just a day".
	DurationOfWorksSEC = 0;
	For Each String In Works Do
		DurationOfWorksSEC = DurationOfWorksSEC + String.Duration;
	EndDo;
	DurationOfWork = StrTemplate(NStr("vi = 'Tổng số trong ngày: %1';
										|ru = 'Всего за день: %1';
										|en = 'Total for the day: %1'; fa = 'Total for the day: %1';
										|it = 'Totale per giorno: %1';
										|pl = 'Łącznie za dzień: %1';
										|tr = 'Günlük toplam: %1'"),
		IntegrationWith1CDocumentManagementClientServer.NumberPerLine(DurationOfWorksSEC, "0"));
	
	// Output of the line "Exceeded  It remains."
	LengthOfDaySec = EndDay - BegOfDay;
	
	If Not ValueIsFilled(BegOfDay) Or Not ValueIsFilled(EndDay) Then
		ErrorsMessage = "";
		
	ElsIf DurationOfWorksSEC > LengthOfDaySec Then
		ErrorsMessage = StrTemplate(NStr("vi = '(đã vượt quá %1)';
										|ru = '(превышено на %1)';
										|en = '(exceeded at %1)'; fa = '(exceeded at %1)';
										|it = '(eccesso di %1)';
										|pl = '(przekroczono o %1)';
										|tr = '(%1kadar aşıldı)'"),
			IntegrationWith1CDocumentManagementClientServer.NumberPerLine(DurationOfWorksSEC - LengthOfDaySec));
		
	ElsIf DurationOfWorksSEC < LengthOfDaySec Then
		ErrorsMessage = StrTemplate(NStr("vi = '(còn lại %1)';
										|ru = '(осталось %1)';
										|en = '(%1 left)'; fa = '(%1 left)';
										|it = '(resta %1)';
										|pl = '(pozostało %1)';
										|tr = '(%1kaldı)'"),
			IntegrationWith1CDocumentManagementClientServer.NumberPerLine(LengthOfDaySec - DurationOfWorksSEC));
		
	Else
		ErrorsMessage = "";
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	If MethodOfIndicatingTimeID = EnumerationValueDuration Then
		
		Items.WorksBegin.Visible = False;
		Items.WorksEnding.Visible = False;
		Items.WorksDurationOfRow.Visible = True;
		
	ElsIf MethodOfIndicatingTimeID = EnumerationValueStartTime Then
		
		Items.WorksBegin.Visible = True;
		Items.WorksEnding.Visible = True;
		Items.WorksDurationOfRow.Visible = False;
		
	EndIf;
	
	If KeepRecordsOnProjects Then
		
		Items.WorksProjectTask.Visible = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillCheckProcessing(Cancel)
	
	For Each String In Works Do
		
		String.Begin = BegOfMinute(String.Begin);
		String.Ending = BegOfMinute(String.Ending);
		
		RowIndex = Works.IndexOf(String);
		
		If Not ValueIsFilled(String.Work_5) Then
			MessageText = StrTemplate(
				NStr("vi = 'Chưa điền cột ""Nội dung công việc"" tại dòng %1 của danh sách ""Công việc"".';
					|ru = 'Не заполнена колонка ""Содержание работ"" в строке %1 списка ""Работы"".';
					|en = 'The ""Work content"" column is not populated in line %1 of the ""Works"" list.'; fa = 'The ""Work content"" column is not populated in line %1 of the ""Works"" list.';
					|it = 'Colonna ""Contenuto lavori"" non compilata nella riga %1 dell''elenco ""Lavori"".';
					|pl = 'Nie wypełniono kolumny ""Zawartość prac"" w wierszu %1 listy ""Prace"".';
					|tr = '%1 satırındaki ""İşler"" listesinden ""İşin içeriği"" sütunu doldurulmadı.'"),
				RowIndex + 1);
			CommonClient.MessageToUser(
				MessageText,,
				"Works[" + Format(RowIndex, "NZ=0; NG=0") + "].Work_5",,
				Cancel);
		EndIf;
		
		If Not ValueIsFilled(String.WorkKind) Then
			MessageText = StrTemplate(
				NStr("vi = 'Chưa điền cột ""Dạng công việc"" tại dòng %1 của danh sách ""Công việc"".';
					|ru = 'Не заполнена колонка ""Вид работ"" в строке %1 списка ""Работы"".';
					|en = 'The ""Activity kinds"" column is not populated in line %1 of the ""Works"" list.'; fa = 'The ""Activity kinds"" column is not populated in line %1 of the ""Works"" list.';
					|it = 'Colonna ""Tipo di lavori"" non completata nella riga %1 dell''elenco ""Lavori"".';
					|pl = 'Nie wypełniono kolumny ""Rodzaj prac"" w wierszu %1 listy ""Prace"".';
					|tr = '%1 satırındaki ""İşler"" listesinden ""İş türü"" sütunu doldurulmadı.'"),
				RowIndex + 1);
			CommonClient.MessageToUser(
				MessageText,,
				"Works[" + Format(RowIndex, "NZ=0; NG=0") + "].WorkKind",,
				Cancel);
		EndIf;
		
		If MethodOfIndicatingTimeID = EnumerationValueDuration Then
			
			Duration = IntegrationWith1CDocumentManagementClientServer.NumberFromString(String.DurationOfRow);
			If Not ValueIsFilled(Duration) Then
				MessageText = StrTemplate(
					NStr("vi = 'Chưa điền cột ""Thời gian"" tại dòng %1 của danh sách ""Công việc"".';
						|ru = 'Не заполнена колонка ""Время"" в строке %1 списка ""Работы"".';
						|en = 'The ""Time"" column is not populated in line %1 of the ""Works"" list.'; fa = 'The ""Time"" column is not populated in line %1 of the ""Works"" list.';
						|it = 'Colonna ""Ora"" non compilata nella riga %1 dell''elenco ""Lavori"".';
						|pl = 'Nie wypełniono kolumny ""Czas"" w wierszu %1 listy ""Prace"".';
						|tr = '%1 satırındaki ""İşler"" listesinden ""Zaman"" sütunu doldurulmadı.'"),
					RowIndex + 1);
				CommonClient.MessageToUser(
					MessageText,,
					"Works[" + Format(RowIndex, "NZ=0; NG=0") + "].DurationOfRow",,
					Cancel);
			EndIf;
			
		Else
			
			If Not ValueIsFilled(String.Begin) Then
				MessageText = StrTemplate(
					NStr("vi = 'Chưa điền cột ""Bắt đầu công việc"" tại dòng %1 của danh sách ""Công việc"".';
						|ru = 'Не заполнена колонка ""Начало работ"" в строке %1 списка ""Работы"".';
						|en = 'The ""Work start"" column is not populated in line %1 of the ""Works"" list.'; fa = 'The ""Work start"" column is not populated in line %1 of the ""Works"" list.';
						|it = 'Colonna ""Avvio lavori"" non compilata nella riga %1 dell''elenco ""Lavori"".';
						|pl = 'Nie wypełniono kolumny ""Początek prac"" w wierszu %1 listy ""Prace"".';
						|tr = '%1 satırındaki ""İşler"" listesinden ""İşin başlangıcı"" sütunu doldurulmadı.'"),
					RowIndex + 1);
				CommonClient.MessageToUser(
					MessageText,,
					"Works[" + Format(RowIndex, "NZ=0; NG=0") + "].Begin",,
					Cancel);
			EndIf;
			
			If TimekeepingFunctionalityIsAvailable Then
				If Not ValueIsFilled(String.Ending) Then
					MessageText = StrTemplate(
						NStr("vi = 'Chưa điền cột ""Kết thúc công việc"" tại dòng %1 của danh sách ""Công việc"".';
							|ru = 'Не заполнена колонка ""Окончание работ"" в строке %1 списка ""Работы"".';
							|en = 'The ""Work end"" column is not populated in line %1 of the ""Works"" list.'; fa = 'The ""Work end"" column is not populated in line %1 of the ""Works"" list.';
							|it = 'Colonna ""Fine lavori"" non compilata nella riga %1 dell''elenco ""Lavori"".';
							|pl = 'Nie wypełniono kolumny ""Zakończenie prac"" w wierszu %1 listy ""Prace"".';
							|tr = '%1satırındaki ""İşler"" listesinden ""İşin bitişi"" sütunu doldurulmadı.'"),
						RowIndex + 1);
					CommonClient.MessageToUser(
						MessageText,,
						"Works[" + Format(RowIndex, "NZ=0; NG=0") + "].Ending",,
						Cancel);
				EndIf;
				If String.Begin > String.Ending Then
					MessageText = StrTemplate(
						NStr("vi = 'Thời gian bắt đầu công việc lớn hơn thời gian kết thúc công việc tại dòng %1 của danh sách ""Công việc"".';
							|ru = 'Время начала работ больше, чем время окончания работ в строке %1 списка ""Работы"".';
							|en = 'Work start time is later than work end time in line %1 of the ""Works"" list.'; fa = 'Work start time is later than work end time in line %1 of the ""Works"" list.';
							|it = 'L''ora di avvio dei lavori è successiva all''ora di fine dei lavori nella riga %1 dell''elenco ""Lavori"".';
							|pl = 'Czas rozpoczęcia prac jest większy, niż czas zakończenia prac w wierszu %1 listy ""Prace"".';
							|tr = '%1 satırındaki ""İşler"" listesinde başlangıç ​​zamanı bitiş zamanından daha uzun.'"),
						RowIndex + 1);
					
					CommonClient.MessageToUser(
						MessageText,,
						"Works[" + Format(RowIndex, "NZ=0; NG=0") + "].Begin",,
						Cancel);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If TimekeepingFunctionalityIsAvailable And MethodOfIndicatingTimeID = EnumerationValueStartTime Then
		// Checking intersecting intervals.
		For Indus1 = 0 To Works.Count() - 2 Do
			String1 = Works[Indus1];
			For Indus2 = Indus1 + 1 To Works.Count() - 1 Do
				String2 = Works[Indus2];
				If (String2.Begin >= String1.Begin And String2.Begin < String1.Ending)
						Or (String2.Ending > String1.Begin And String2.Ending <= String1.Ending) Then
					MessageText = StrTemplate(
						NStr("vi = 'Đã tìm thấy các khoảng thời gian trùng nhau tại các dòng %1 và %2 của danh sách ""Công việc"".';
							|ru = 'Найдены пересекающиеся интервалы времени в строках %1 и %2 списка ""Работы"".';
							|en = 'Overlapping time intervals are found in lines %1 and %2 of the ""Works"" list.'; fa = 'Overlapping time intervals are found in lines %1 and %2 of the ""Works"" list.';
							|it = 'Sono stati trovati intervalli di tempo sovrapposti nelle righe %1 e %2 nell''elenco ""Lavori"".';
							|pl = 'Znaleziono przecinające się interwały czasu w wierszach %1 i %2 listy ""Prace"".';
							|tr = '%1 satırında ve %2 ""İşler"" listesinde kesişen zaman aralıkları bulundu.'"),
						Indus1 + 1,
						Indus2 + 1);
					CommonClient.MessageToUser(
						MessageText,,
						"Works",,
						Cancel);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteObject()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Type);
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.GenerateAdditionalProperties(
		Proxy,
		XDTODataObject,
		ThisObject);
	
	MatchingBankDetails = NewMatchingOfXdtPropertiesAndObjectDetails();
	
	For Each MapRow In MatchingBankDetails Do
		If TypeOf(MapRow.Value) = Type("String") Then
			IntegrationWith1CDocumentManagement.FillInXDTPropertyOfOizPropsStructure(
				Proxy,
				XDTODataObject,
				MapRow.Value,
				ThisObject,
				MapRow.Key);
		Else
			XDTOList = XDTODataObject[MapRow.Value.Name]; // XDTOList
			For Each String In ThisObject[MapRow.Key] Do
				XDTORow = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					MapRow.Value.Type);
				For Each TSMatchString In MapRow.Value.Attributes Do
					IntegrationWith1CDocumentManagement.FillInXDTPropertyOfOizPropsStructure(
						Proxy,
						XDTORow,
						TSMatchString.Value,
						String,
						TSMatchString.Key);
				EndDo;
				XDTOList.Add(XDTORow);
			EndDo;
		EndIf;
	EndDo;
	
	If ValueIsFilled(ID) And ValueIsFilled(Type) Then // Update.
		
		XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
		XDTODataObject.name = Presentation;
		
		Result = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, XDTODataObject);
		
		XDTODataObject = Result.objects[0];
	
	Else // Creation.
		
		XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
		XDTODataObject.name = Presentation;
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateRequest");
		Query.object = XDTODataObject;
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		
		XDTODataObject = Result.object;
		ID  = XDTODataObject.objectID.ID;
		Type = XDTODataObject.objectID.type;
		
	EndIf;
	
	// Re-read the object into the Form.
	FillInObjectForm(XDTODataObject);
	
EndProcedure

&AtClient
Procedure CloseWithParameter()
	
	Result = New Structure;
	Result.Insert("ID", ID);
	Result.Insert("type", Type);
	Result.Insert("name", Presentation);
	
	ClosingWithParameter = True;
	Close(Result);
	
EndProcedure

&AtClient
Procedure RecalculateStartOfDay()
	
	If Not TimekeepingFunctionalityIsAvailable And (MethodOfIndicatingTimeID = EnumerationValueStartTime) Then
		
		CurEarlyAfternoon = '99990101';
		For Each String In Works Do
			If CurEarlyAfternoon > String.Begin And ValueIsFilled(String.Begin) Then
				CurEarlyAfternoon = String.Begin;
			EndIf;
		EndDo;
		
		If CurEarlyAfternoon = '99990101' Then
			BegOfDay = '00010101';
		Else
			BegOfDay = CurEarlyAfternoon;
		EndIf;
		CalculateLengthOfDay();
		
	EndIf;
	
EndProcedure

&AtServer
Function NewMatchingOfXdtPropertiesAndObjectDetails()
	
	MatchingBankDetails = New Map;
	MatchingBankDetails.Insert("Date", "date");
	MatchingBankDetails.Insert("BegOfDay", "dayBegin");
	MatchingBankDetails.Insert("EndDay", "dayEnd");
	MatchingBankDetails.Insert("LengthOfDay", "duration");
	MatchingBankDetails.Insert("IncorrectDuration", "durationIncorrect");
	MatchingBankDetails.Insert("Author", "author");
	MatchingBankDetails.Insert("User", "user");
	MatchingBankDetails.Insert("MethodOfIndicatingTime", "timeInputMethod");
	
	ComplianceWithTSDetails = New Map;
	ComplianceWithTSDetails.Insert("AddedOn", "addDate");
	ComplianceWithTSDetails.Insert("Begin", "begin");
	ComplianceWithTSDetails.Insert("Ending", "end");
	ComplianceWithTSDetails.Insert("Work_5", "description");
	ComplianceWithTSDetails.Insert("Duration", "duration");
	ComplianceWithTSDetails.Insert("WorkKind", "workType");
	ComplianceWithTSDetails.Insert("Project", "project");
	ComplianceWithTSDetails.Insert("TaskOfTheProject", "projectTask");
	ComplianceWithTSDetails.Insert("Source", "source");
	
	StructureOfTS = New Structure;
	StructureOfTS.Insert("Name", "works");
	StructureOfTS.Insert("Type", "DMActualWork");
	StructureOfTS.Insert("Attributes", ComplianceWithTSDetails);
	
	MatchingBankDetails.Insert("Works", StructureOfTS);
	
	Return MatchingBankDetails;
	
EndFunction

&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	Title = NStr("vi = 'Báo cáo công việc hàng ngày';
				|ru = 'Ежедневный отчет';
				|en = 'Daily report'; fa = 'گزارش روزانه';
				|it = 'Report giornaliero';
				|pl = 'Codzienny raport';
				|tr = 'Günlük rapor'");
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.FunctionalityGroupIsNotSupported.Visible = True;
		Items.AuthorizationVerificationGroup.Visible = True;
		Items.DecorationFunctionalityIsNotSupported.Title = NStr("vi = 'Không đủ quyền truy cập đến 1C:Document Management.';
																|ru = 'Нет доступа к 1С:Документообороту.';
																|en = 'No access to 1C:Document Management.'; fa = 'دسترسی به 1C:Document Management وجود ندارد.';
																|it = 'Non vi è accesso a 1C:Document Management.';
																|pl = 'Brak dostępu do 1C:Document Management.';
																|tr = '1C:Document Management''e erişilmiyor.'");
		Items.MainGroup2.Visible = False;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		Items.AuthorizationVerificationGroup.Visible = False;
		
		If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3")
				Or IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
			DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
			Items.MainGroup2.Visible = False;
			Items.FormCommandBar.Visible = False;
		Else
			Items.AuthorizationVerificationGroup.Visible = False;
			Items.FunctionalityGroupIsNotSupported.Visible = False;
			Items.MainGroup2.Visible = True;
			Items.FormCommandBar.Visible = True;
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
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
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_F_BegOfDay" Then
		BegOfDayOnChange(Items.BegOfDay);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndDay" Then
		EndDayOnChange(Items.EndDay);
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
