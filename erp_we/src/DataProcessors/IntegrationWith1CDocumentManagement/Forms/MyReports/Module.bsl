#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	WeekDays.Add(NStr("vi = 'Thứ 2';
						|ru = 'Понедельник';
						|en = 'Monday'; fa = 'دوشنبه';
						|it = 'Lunedì';
						|pl = 'Poniedziałek';
						|tr = 'Pazartesi'"));
	WeekDays.Add(NStr("vi = 'Thứ 3';
						|ru = 'Вторник';
						|en = 'Tuesday'; fa = 'سه‌شنبه';
						|it = 'Martedì';
						|pl = 'Wtorek';
						|tr = 'Salı'"));
	WeekDays.Add(NStr("vi = 'Thứ 4';
						|ru = 'Среда';
						|en = 'Wednesday'; fa = 'چهارشنبه';
						|it = 'Mercoledì';
						|pl = 'Wednesday';
						|tr = 'Çarşamba'"));
	WeekDays.Add(NStr("vi = 'Thứ 5';
						|ru = 'Четверг';
						|en = 'Thursday'; fa = 'پنجشنبه';
						|it = 'Giovedì';
						|pl = 'Thursday';
						|tr = 'Perşembe'"));
	WeekDays.Add(NStr("vi = 'Thứ 6';
						|ru = 'Пятница';
						|en = 'Friday'; fa = 'جمعه';
						|it = 'Venerdì';
						|pl = 'Friday';
						|tr = 'Cuma'"));
	WeekDays.Add(NStr("vi = 'Thứ 7';
						|ru = 'Суббота';
						|en = 'Saturday'; fa = 'شنبه';
						|it = 'Sabato';
						|pl = 'Saturday';
						|tr = 'Cumartesi'"));
	WeekDays.Add(NStr("vi = 'Chủ nhật';
						|ru = 'Воскресенье';
						|en = 'Sunday'; fa = 'یکشنبه';
						|it = 'Domenica';
						|pl = 'Sunday';
						|tr = 'Pazar'"));
	
	PeriodSettings = Common.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement",
		"DailyReports_SettingUpPeriod");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit Then
		PeriodStructure = New Structure("Variant, StartDate, EndDate",
			PeriodSettings.Variant,
			PeriodSettings.StartDate,
			PeriodSettings.EndDate);
		BeforeCloseAtServer(PeriodStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" And Source <> ThisObject Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
	If EventName = "Recording_1CDocumentManagementObject" And Source = ThisObject Then
		UpdateListOfDocumentsPartially(Parameter.ID);
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

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Document = Items.List.CurrentData;
	If Document <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(Document.RefType, Document.RefID, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.DailyReport",,ThisObject);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	SetDeleteMarkOnClient();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Create(Command)
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.DailyReport",,ThisObject);
	Modified = False;
	
EndProcedure

&AtClient
Procedure Change(Command)
	
	Document = Items.List.CurrentData;
	
	If Document <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(Document.RefType, Document.RefID, ThisObject);
	EndIf;
	Modified = False;
	
EndProcedure

&AtClient
Procedure SetDeletionMark(Command)
	
	SetDeleteMarkOnClient();
	Modified = False;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateListOfDocuments();
	Modified = False;
	
EndProcedure

&AtClient
Procedure PeriodSettings(Command)
	
	Notification = New CallbackDescription("PeriodSettingsCompletion", ThisObject);
	
	PeriodDialog = New StandardPeriodEditDialog;
	PeriodDialog.Period = PeriodSettings;
	PeriodDialog.Show(Notification);
	Modified = False;
	
EndProcedure

&AtClient
Procedure PeriodSettingsCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		PeriodSettings = Result;
		UpdateListOfDocuments();
	EndIf;
	Modified = False;
	
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

&AtServerNoContext
Function GetDocuments(Proxy, PeriodSettings)
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "byUser";
	Condition.value = True;
	FilterConditions.Add(Condition);
	
	If ValueIsFilled(PeriodSettings.StartDate) Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "beginDate";
		Condition.value = PeriodSettings.StartDate;
		FilterConditions.Add(Condition);
	EndIf;
	
	If ValueIsFilled(PeriodSettings.EndDate) Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "endDate";
		Condition.value = PeriodSettings.EndDate;
		FilterConditions.Add(Condition);
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMDailyReport",
		ListOfConditions);
	
	Return Response.items;
	
EndFunction

&AtServer
Procedure SetListLayout(Var_ConditionalAppearance)

	// setting up registration for overdue tasks
	ConditionalAppearanceItem = Var_ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.InvalidDurationList");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  WebColors.Red;
	AppearanceColorItem.Use = True;
	
	AppearanceAreaItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceAreaItem.Field = New DataCompositionField("List");
	
EndProcedure

&AtServer
Procedure UpdateListOfDocuments()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODocuments = GetDocuments(Proxy, PeriodSettings);
	FillInListOfDocuments(XDTODocuments);
	
EndProcedure

&AtServer
Procedure UpdateListOfDocumentsPartially(CurrentDocument = Undefined)
	
	If List.Count() = 0 Then
		UpdateListOfDocuments();
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODocuments = GetDocuments(Proxy, PeriodSettings);
	RowReferencesToDelete = List.Unload().UnloadColumn("RefID");
	
	For Each XDTORow In XDTODocuments Do
		Rows = List.FindRows(New Structure("RefID",XDTORow.object.objectID.ID));
		If Rows.Count() > 0 Then
			String = Rows[0];
			RowReferencesToDelete.Delete(RowReferencesToDelete.Find(XDTORow.object.objectID.ID));
		Else
			String = List.Add();
		EndIf;
		FillInLineInList(String, XDTORow.object);
	EndDo;
	
	For Each Ref In RowReferencesToDelete Do
		Rows = List.FindRows(New Structure("RefID",Ref));
		If Rows.Count() > 0 Then
			List.Delete(Rows[0]);
		EndIf;
	EndDo;
	
	List.Sort("Date");
	
	SetCurrentRow(CurrentDocument);
	
EndProcedure

&AtServer
Procedure FillInListOfDocuments(XDTODocuments)
	
	CurrentDocument = Items.List.CurrentRow;
	If CurrentDocument <> Undefined Then
		CurrentDocument = List.FindByID(CurrentDocument).RefID;
	EndIf;
	
	List.Clear();
	
	For Each XDTODocument In XDTODocuments Do
		ListLine = List.Add();
		FillInLineInList(ListLine, XDTODocument.object)
	EndDo;
	
	List.Sort("Date");
	
	SetCurrentRow(CurrentDocument);
	
EndProcedure

&AtServer
Procedure FillInLineInList(ListLine, XDTODocument)
	
	ListLine.Date = XDTODocument.date;
	ListLine.WeekDay = WeekDays.Get(WeekDay(XDTODocument.date) - 1).Value;
	ListLine.BegOfDay = XDTODocument.dayBegin;
	ListLine.EndDay = XDTODocument.dayEnd;
	ListLine.DurationOfWork = XDTODocument.duration;
	ListLine.IncorrectDuration =  XDTODocument.durationIncorrect;
	ListLine.Picture = 1;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ListLine, XDTODocument.author, "Author", False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ListLine, XDTODocument.user, "User", False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ListLine, XDTODocument, "Ref", False);
	
EndProcedure

&AtServer
Procedure SetCurrentRow(RefID)
	
	If ValueIsFilled(RefID) Then
		For Each String In List Do
			If String.RefID = RefID Then
				Items.List.CurrentRow = String.GetID();
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDeleteMarkOnClient()
	
	If Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	
	QueryText = "";
	
	If Items.List.SelectedRows.Count() = 1 Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đặt dấu xóa ""%1""?';
				|ru = 'Пометить ""%1"" на удаление?';
				|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
				|it = 'Contrassegnare ""%1"" per cancellazione?';
				|pl = 'Zaznaczyć ""%1"" do usunięcia?';
				|tr = '""%1"" silinmek üzere işaretlensin mi?'"), Items.List.CurrentData.Ref);
	Else
		QueryText = NStr("vi = 'Đánh dấu xóa phần tử đã chọn?';
						|ru = 'Пометить выделенные элементы на удаление?';
						|en = 'Mark the selected items for deletion?'; fa = 'Mark the selected items for deletion?';
						|it = 'Contrassegnare gli elementi selezionati per la cancellazione?';
						|pl = 'Zaznaczyć wybrane elementy do usunięcia?';
						|tr = 'Seçilen öğeler silinmek üzere işaretlensin mi?'");
	EndIf;
	
	Notification = New CallbackDescription("SetDeleteMarkOnClientCompletion", ThisObject);
	
	IntegrationWith1CDocumentManagementClient.ShowQuestionYesNo(Notification, QueryText);
	
EndProcedure

&AtClient
Procedure SetDeleteMarkOnClientCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SetDeleteMarkToOnServer();
	
EndProcedure

&AtServer
Procedure SetDeleteMarkToOnServer()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ListOfObjects = New Array;
	
	For Each LineNumber In Items.List.SelectedRows Do
		Data = List.FindByID(LineNumber);
		ListOfObjects.Add(New Structure("ID, Type", Data.RefID, Data.RefType));
	EndDo;
	
	IntegrationWith1CDocumentManagementCore.MarkForDeletionUncheckItems(
		Proxy,
		ListOfObjects);
	
	UpdateListOfDocumentsPartially();
	
EndProcedure

&AtServerNoContext
Procedure BeforeCloseAtServer(PeriodStructure)
	
	PeriodSettings = New StandardPeriod(PeriodStructure.Variant);
	PeriodSettings.StartDate = PeriodStructure.StartDate;
	PeriodSettings.EndDate = PeriodStructure.EndDate;
	Common.CommonSettingsStorageSave(
		"IntegrationWith1CDocumentManagement", "DailyReports_SettingUpPeriod", PeriodSettings);
	
EndProcedure

&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	Title = NStr("vi = 'Báo cáo của tôi';
				|ru = 'Мои отчеты';
				|en = 'My reports'; fa = 'گزارش‌های من';
				|it = 'I miei report';
				|pl = 'Moje raporty';
				|tr = 'Raporlarım'");
	
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
		Items.List.Visible = False;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		Items.AuthorizationVerificationGroup.Visible = False;
		
		If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3")
				Or IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
			DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
			Items.List.Visible = False;
		Else
			Items.FunctionalityGroupIsNotSupported.Visible = False;
			Items.List.Visible = True;
			
			SetListLayout(ConditionalAppearance);
			UpdateListOfDocuments();
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

#EndRegion