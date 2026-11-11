#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MultiSubjectivityIsAvailable = False;
	ProcessTypeXDTO = "DMBusinessProcessOutgoingDocumentProcessing";
	XDTODataObject = IntegrationWith1CDocumentManagement.GetProcessXDTOObject(ProcessTypeXDTO, Parameters);
	FillOutFormFromXDTOObject(XDTODataObject);
	
	IntegrationWith1CDocumentManagementCoreOverridable.AdditionalProcessingOfBusinessProcessForm(
		ThisObject,
		Cancel,
		StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,,WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_1CDocumentManagementDocument" And Source = Items.SubjectOfPresentation Then
		SubjectOf = Parameter.name;
	ElsIf EventName = "Recording_1CDocumentManagementBusinessProcess" Then
		If Parameter.ID = ID Then
			RereadProcess();
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MainTaskPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(MainTask) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(MainTaskType, MainTaskID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubjectOfClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(SubjectOf) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(SubjectOfType, SubjectOfID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApprovalTemplatePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		"DMBusinessProcessApprovalTemplate", "ApprovalTemplate", ThisObject);
	
EndProcedure

&AtClient
Procedure ConfirmationTemplatePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		"DMBusinessProcessConfirmationTemplate", "ConfirmationTemplate", ThisObject);
	
EndProcedure

&AtClient
Procedure RegistrationTemplatePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		"DMBusinessProcessRegistrationTemplate", "RegistrationTemplate", ThisObject);
	
EndProcedure

&AtClient
Procedure AuthorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("Author", ThisObject);
	
EndProcedure

&AtClient
Procedure AuthorAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching("DMUser", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Author",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Author",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RecordBusinessProcess(Command)
	
	RecordingResult = WriteObjectExecute();
	
	If RecordingResult Then
		IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, False);
		Title = Presentation;
		Status(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã lưu lại quy trình nghiệp vụ ""%1"".';
				|ru = 'Бизнес-процесс ""%1"" сохранен.';
				|en = 'Business process ""%1"" is saved.'; fa = 'Business process ""%1"" is saved.';
				|it = 'Processo aziendale ""%1"" salvato.';
				|pl = 'Proces biznesowy ""%1"" jest zapisany.';
				|tr = '""%1"" iş süreci kaydedildi.'"), Presentation));
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAndClose(Command)
	
	RunResult = PrepareForTransferAndStartBusinessProcess();
	
	If RunResult Then
		IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, True);
		StateText = NStr("vi = 'Đã khởi chạy thành công quy trình nghiệp vụ ""%Description%"".';
						|ru = 'Бизнес-процесс ""%Description%"" успешно запущен.';
						|en = 'The ""%Description%"" business process is started successfully.'; fa = 'The ""%Description%"" business process is started successfully.';
						|it = 'Processo aziendale ""%Description%"" avviato con successo.';
						|pl = 'Proces biznesowy ""%Description%"" jest pomyślnie uruchomiony.';
						|tr = '""%Description%"" iş süreci başarıyla başlatıldı.'");
		StateText = StrReplace(StateText,"%Description%", Presentation);
		Status(StateText);
		Modified = False;
		If IsOpen() Then
			Close();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillFromTemplate(Command)
	
	Notification = New CallbackDescription("FillFromTemplateCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.StartSelectingBusinessProcessTemplate(Notification, ThisObject);
	
EndProcedure

&AtClient
Procedure StopProcess(Command)
	
	IntegrationWith1CDocumentManagementClient.StopProcess(ThisObject);
	
EndProcedure

&AtClient
Procedure InterruptProcess(Command)
	
	IntegrationWith1CDocumentManagementClient.InterruptProcess(ThisObject);
	
EndProcedure

&AtClient
Procedure ContinueProcess(Command)
	
	IntegrationWith1CDocumentManagementClient.ContinueProcess(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillFromTemplateCompletion(TemplateSelectionResult, NotificationParameters) Export
	
	If TypeOf(TemplateSelectionResult) = Type("Structure") Then
		FillInCardUsingTemplate(TemplateSelectionResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCardUsingTemplate(TemplateData)
	
	FillingResult = IntegrationWith1CDocumentManagement.FillInBusinessProcessUsingTemplate(ThisObject, TemplateData);
	FillOutFormFromXDTOObject(FillingResult.object);

EndProcedure

&AtServer
Procedure FillOutFormFromXDTOObject(XDTODataObject)
	
	If XDTODataObject.IsSet("objectID") Then
		ID = XDTODataObject.objectID.ID;
		Type = XDTODataObject.objectID.type;
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(
		ThisObject,
		XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.FillInStandardHeaderOfBusinessProcess(ThisObject, XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.SetVisibilityOfProcessStateChangeCommands(ThisObject, XDTODataObject);
	
	// The specifics of processing an outgoing document
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.approvalTemplate,"ApprovalTemplate");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.confirmationTemplate, "ConfirmationTemplate");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.registrationTemplate, "RegistrationTemplate");
		
	// It is possible that changing the process is prohibited by its template.
	ProhibitedUpdate = False;
	If XDTODataObject.Properties().Get("blockedByTemplate") <> Undefined Then
		ProhibitedUpdate = XDTODataObject.blockedByTemplate;
	EndIf;
	For Each Item In Items.GroupActions.ChildItems Do
		Item.Enabled = Item.Enabled And Not ProhibitedUpdate;
	EndDo;
	
EndProcedure

&AtServer
Function PrepareForTransferAndRecordBusinessProcess()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = PrepareBusinessProcess(Proxy);
	
	If ValueIsFilled(ID) Then
		RecordingResult = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, XDTODataObject);
	Else
		CreationResult = IntegrationWith1CDocumentManagementCore.CreateNewObject(Proxy, XDTODataObject);
	EndIf;
	
	Result = ?(CreationResult = Undefined, RecordingResult, CreationResult);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	If RecordingResult <> Undefined Then
		SetBusinessProcessLink(Result.objects[0]);
	Else
		SetBusinessProcessLink(Result.object);
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function PrepareForTransferAndStartBusinessProcess()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = PrepareBusinessProcess(Proxy);
	
	RunResult = IntegrationWith1CDocumentManagement.StartBusinessProcess(Proxy, XDTODataObject);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, RunResult);
	
	SetBusinessProcessLink(RunResult.businessProcess);
	
	Return True;
	
EndFunction

&AtServer
Function PrepareBusinessProcess(Proxy)
	
	XDTODataObject = DataProcessors.IntegrationWith1CDocumentManagement.PrepareBusinessProcessHeader(
		Proxy,
		"DMBusinessProcessOutgoingDocumentProcessing",
		ThisObject,
		"Importance,Started,Completed,LongDesc,DueDate,Template");
	
	// The specifics of processing an outgoing document
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(Proxy, ThisObject,
		"ApprovalTemplate", XDTODataObject.approvalTemplate, "DMBusinessProcessApprovalTemplate");
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(Proxy, ThisObject,
		"ConfirmationTemplate", XDTODataObject.confirmationTemplate, "DMBusinessProcessConfirmationTemplate");
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(Proxy, ThisObject,
		"RegistrationTemplate", XDTODataObject.registrationTemplate, "DMBusinessProcessRegistrationTemplate");
	
	Return XDTODataObject;
	
EndFunction

&AtClient
Function WriteObjectExecute()
	
	PrepareForTransferAndRecordBusinessProcess();
	IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, False);
	Modified = False;
	
	Return True;
	
EndFunction

&AtServer
Procedure SetBusinessProcessLink(XDTODataObject)
	
	ID = XDTODataObject.objectID.ID;
	If XDTODataObject.objectID.Properties().Get("presentation") <> Undefined Then
		Presentation = XDTODataObject.objectID.presentation;
	Else
		Presentation = XDTODataObject.name;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteObjectExecute();
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteProgrammaticallyAddedCommand(Command)
	
	// Let's call the handler of the command that was added programmatically when creating the form on the server.
	IntegrationWith1CDocumentManagementCoreClientOverridable.ExecuteProgrammaticallyAddedCommand(Command, ThisObject);
	
EndProcedure

&AtServer
Procedure RereadProcess()
	
	ReceivingParameters = New Structure("ID, type", ID, Type);
	XDTODataObject = IntegrationWith1CDocumentManagement.GetProcessXDTOObject(Type, ReceivingParameters);
	FillOutFormFromXDTOObject(XDTODataObject);
	
EndProcedure

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
