
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InitialExecutionFlag = Object.Executed;
	ReadOnly = Object.Executed;
	
	If Not Object.Executed Then
		Object.CompletionDate = CurrentSessionDate();
	EndIf;
	
	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	Items.DueDateTime.Visible = UseDateAndTimeInTaskDeadlines;
	Items.ExecutionStartDateScheduledTime.Visible = UseDateAndTimeInTaskDeadlines;
	Items.CompletionDate.Format = ?(UseDateAndTimeInTaskDeadlines, "DLF=DT", "DLF=D");
	
	ChangeJobsBackdated = GetFunctionalOption("ChangeJobsBackdated");
	TMCommonUseClientServer.SetFormItemProperty(Items, "CompletionDate", "ReadOnly", Not ChangeJobsBackdated);
	
	ApprovalProgress.Parameters.SetParameterValue("BusinessProcess", Object.BusinessProcess);
	
	ParametersToBeSpecified = New Structure();
	ParametersToBeSpecified.Insert("ObjectType", Object.SubjectOf.Metadata().FullName());
	SetFormFunctionalOptionParameters(ParametersToBeSpecified);
	
	If Not ValueIsFilled(Object.Ref) Then
		BusinessProcessesAndTasksServer.TaskFormOnCreateAtServer(ThisForm, Object,
			Items.StateGroup, Items.CompletionDate);
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	BusinessProcessesAndTasksClient.TaskFormNotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	BusinessProcessesAndTasksServer.TaskFormOnCreateAtServer(ThisForm, Object, 
		Items.StateGroup, Items.CompletionDate);
	Items.ResultDetails.ReadOnly = Object.Executed;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndCloseExecute()
	
	ClearMessages();
	If Write() Then
		
		NotifyChanged(Object.Ref);
		ShowUserNotification(
			NStr("vi = 'Thay đổi:';
				|ru = 'Изменение:';
				|en = 'Editing:'; fa = 'Editing:';
				|it = 'Modifica:';
				|pl = 'Editing:';
				|tr = 'Değişim:'"),
			GetURL(Object.Ref),
			String(Object.Ref),
			PictureLib.Information32);
			
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteExecute(Command)
	
	If Write() Then
		
		NotifyChanged(Object.Ref);
		ShowUserNotification(
			NStr("vi = 'Thay đổi:';
				|ru = 'Изменение:';
				|en = 'Editing:'; fa = 'Editing:';
				|it = 'Modifica:';
				|pl = 'Editing:';
				|tr = 'Değişim:'"),
			GetURL(Object.Ref),
			String(Object.Ref),
			PictureLib.Information32);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure IHaveReadAndUnderstood(Command)
	
	If Write() Then 
		IHaveReadAndUnderstoodServer();
		
		ShowUserNotification(
			NStr("vi = 'Thực hiện:';
				|ru = 'Выполнение:';
				|en = 'Executing:'; fa = 'Executing:';
				|it = 'Esecuzione:';
				|pl = 'Executing:';
				|tr = 'Gerçekleştirme:'"),
			GetURL(Object.Ref),
			String(Object.Ref),
			PictureLib.Information32);
		
		NotifyChanged(Object.Ref);
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VariancesFromSalesTermsAndConditions(Command)
	FormParameters = New Structure("DocumentSales", Object.SubjectOf);
	OpenForm("Report.VariancesFromSalesTermsAndConditions.Form", FormParameters);
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure IHaveReadAndUnderstoodServer()
	
	BusinessProcessesAndTasksServerCall.ExecuteTask(Object.Ref);
	
EndProcedure

#EndRegion

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
