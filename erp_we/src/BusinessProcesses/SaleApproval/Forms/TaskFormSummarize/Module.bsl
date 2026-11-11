
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
	SubjectType = Object.SubjectOf.Metadata().FullName();
	ParametersToBeSpecified.Insert("ObjectType", SubjectType);
	SetFormFunctionalOptionParameters(ParametersToBeSpecified);
	
	If BusinessProcesses.SaleApproval.VersioningOfItemIsUsed(SubjectType) Then
			
			ThereAreVersionDifferences = BusinessProcesses.SaleApproval.LatestVersionOfItemIsDifferentFromAgreedOnes(Object.BusinessProcess);
			
			If ThereAreVersionDifferences Then
				
				LastVersionNumber = BusinessProcesses.SaleApproval.LastVersionNumberOfItem(Object.BusinessProcess);
				TitleText = NStr("vi = 'Chú ý! Phiên bản hiện tại số %LastVersionNumber% khác với phiên bản đã điều chỉnh';
								|ru = 'Внимание! Текущая версия №%LastVersionNumber% отличается от согласованной';
								|en = 'Warning! The current version %LastVersionNumber% differs from the approved version'; fa = 'Warning! The current version %LastVersionNumber% differs from the approved version';
								|it = 'Attenzione! La versione corrente n. %LastVersionNumber% è diversa da quella concordata';
								|pl = 'Uwaga! Bieżąca wersja nr%LastVersionNumber% różni się od uzgodnionej';
								|tr = 'Dikkat! Mevcut sürüm №%LastVersionNumber% onaylanandan sürümden farklı '");
				TitleText = StrReplace(TitleText, "%LastVersionNumber%", LastVersionNumber);
				Items.DecorationDifferencesOfTheVersion.Title = TitleText;
				
			Else
				
				Items.DecorationDifferencesOfTheVersion.Visible = False;
				
			EndIf;
			
	Else
			
		Items.DecorationDifferencesOfTheVersion.Visible = False;
			
	EndIf;
		
	If Object.Executed Then
		ApprovalResult = BusinessProcesses.SaleApproval.ResultOfCoordinationByRoutePoint(Object.BusinessProcess, Object.RoutePoint);
		If ApprovalResult <> Undefined Then
			Items.ApprovalResult.Title = ApprovalResult;
		EndIf;
	EndIf;
	
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
Procedure Approved(Command)
	
	ClearMessages();
	If Write() Then
		
		FixResultOfAgreementServer(True);
		
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
Procedure NotApproved(Command)
	
	ClearMessages();
	If Not ValueIsFilled(Object.ExecutionResult) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Hãy chỉ ra nguyên nhân sai lệch của chứng từ';
				|ru = 'Укажите причину отклонения документа';
				|en = 'Specify reason for document rejection'; fa = 'Specify reason for document rejection';
				|it = 'Specificare il motivo per cui il documento viene rigettato';
				|pl = 'Wskaż powód odrzucenia dokumentu';
				|tr = 'Belgenin reddedilme nedenini belirt'"),
			Object.Ref,
			"Object.ExecutionResult");
		
		Return;
		
	EndIf;
	
	If Write() Then
		
		FixResultOfAgreementServer(False);
		
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
Procedure FixResultOfAgreementServer(Approved = True)
	
	Try
		LockDataForEdit(Object.BusinessProcess);
	Except
			
		ErrorText = NStr("vi = 'Khi thực hiện nhiệm vụ không thể phong tỏa %Ref%. %ErrorDescription%';
						|ru = 'При выполнении задачи не удалось заблокировать %Ref%. %ErrorDescription%';
						|en = 'Cannot lock %Ref% when executing the task. %ErrorDescription%'; fa = 'Cannot lock %Ref% when executing the task. %ErrorDescription%';
						|it = 'Nell''eseguire il task non è stato possibile sbloccare %Ref%. %ErrorDescription%';
						|pl = 'Podczas wykonywania zadania nie udało się zablokować %Ref%. %ErrorDescription%';
						|tr = 'Görevin gerçekleştirilmesi sırasında %Ref% engellenemedi. %ErrorDescription%'");
		ErrorText = StrReplace(ErrorText, "%Ref%",         Object.BusinessProcess);
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
		Raise ErrorText;
				
	EndTry;
	
	BeginTransaction();
	
	Try
		
		SetPrivilegedMode(True);
		
		ObjectApproval    = Object.BusinessProcess.GetObject();
		ApprovalResult = ?(Approved, Enums.ApprovalResults.Approved, Enums.ApprovalResults.NotApproved);
		ObjectApproval.AddApprovalResult(
			Object.RoutePoint,
			Users.CurrentUser(),
			ApprovalResult,
			Object.ExecutionResult,
			Object.CompletionDate);
		
		ObjectApproval.ApprovalResult = ApprovalResult;
		ObjectApproval.Write();
		SetPrivilegedMode(False);
		BusinessProcessesAndTasksServerCall.ExecuteTask(Object.Ref);
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	UnlockDataForEdit(Object.BusinessProcess);
	
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
