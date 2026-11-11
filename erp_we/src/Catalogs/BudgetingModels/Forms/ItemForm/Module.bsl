
#Region FormEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("CopyingValue") Then
		CopyingModel = Parameters.CopyingValue;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	If Object.Ref.IsEmpty() Then
		Object.ValidOnDate = BegOfYear(CurrentSessionDate());
	EndIf;
	
	Items.BudgetsByCompanies.Visible = GetFunctionalOption("UseMultipleCompanies");
	Items.BudgetsByBusinessUnits.Visible = GetFunctionalOption("UseBusinessUnits");
	
	ThisIsEnterpriseManagement_ = GetFunctionalOption("EnterpriseManagement");
	UseBudgetProcess = False;
	UseBudgetProcess = GetFunctionalOption("UseBudgetProcess");
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	BudgetingServer.GetScheduleForRoutineTask(ThisObject);
	Items.BudgetProcessPage.Visible = ThisIsEnterpriseManagement_ And UseBudgetProcess;
	
	If Not ThisIsEnterpriseManagement_ Then
		Items.MainPanel.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	SetFormItemEnabled();

	AutomaticallyGenerateTasks = Object.AutomaticallyGenerateTasks;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	If Not Users.IsFullUser(, True)
	 Or Not ThisIsEnterpriseManagement_ Then
		Items.TheInscriptionSchedule.Visible = False;
	Else
		Items.TheInscriptionSchedule.SetAction("Click", "Attachable_ScheduleLabelClick");
	EndIf;
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	RefreshInterface();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
		
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.AutomaticallyGenerateTasks = AutomaticallyGenerateTasks;
	If Object.AutomaticallyGenerateTasks
	   And Object.Status = PredefinedValue("Enum.BudgetingModelStatuses.Valid") Then
		
		CurrentObject.AdditionalProperties.Insert("Schedule", Schedule);
		
	EndIf;
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	SetFormItemEnabled();
	// End StandardSubsystems.ObjectAttributesLock
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit = True And ValueIsFilled(CopyingModel) 
		And ValueIsFilled(Object.Ref) Then
		
		Cancel = True;
		QueryText = NStr("vi = 'Sao chép các loại ngân sách, các bước xử lý và định mức chi tiền?';
						|ru = 'Скопировать виды бюджетов, этапы процессов и лимиты расхода ДС?';
						|en = 'Copy budget profiles, process stages, and cash flow limits?'; fa = 'Copy budget profiles, process stages, and cash flow limits?';
						|it = 'Copiare i tipi di bilanci, le fasi dei processi e i limiti di spesa dei mezzi monetari?';
						|pl = 'Skopiować rodzaje budżetów, etapy procesów i limity wydatkowania środków pieniężnych?';
						|tr = 'Bütçe profilleri, süreç aşamaları ve nakit gider gelirleri kopyalansın mı?'");
		CallbackDescription = New CallbackDescription("QuestionCopyViewsStagesModelsCompletion", ThisObject, True);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit = True And ValueIsFilled(CopyingModel) 
		And ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Sao chép các loại ngân sách, các bước xử lý và định mức chi tiền?';
						|ru = 'Скопировать виды бюджетов, этапы процессов и лимиты расхода ДС?';
						|en = 'Copy budget profiles, process stages, and cash flow limits?'; fa = 'Copy budget profiles, process stages, and cash flow limits?';
						|it = 'Copiare i tipi di bilanci, le fasi dei processi e i limiti di spesa dei mezzi monetari?';
						|pl = 'Skopiować rodzaje budżetów, etapy procesów i limity wydatkowania środków pieniężnych?';
						|tr = 'Bütçe profilleri, süreç aşamaları ve nakit gider gelirleri kopyalansın mı?'");
		CallbackDescription = New CallbackDescription("QuestionCopyViewsStagesModelsCompletion", ThisObject, False);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GenerateIssuesAutomaticallyOnChange(Item)
	FormControl(ThisObject);
EndProcedure

&AtClient
Procedure LaunchADocumentOnChange(Item)
	FormControl(ThisObject);
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	FormControl(ThisObject);
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("NotificationAboutUnblocking", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "ValidOnDate", "ValidToDate"));
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure NotificationAboutUnblocking(Result, AdditionalParameters) Export
	
	SetFormItemEnabled();
	
EndProcedure

&AtServer
Procedure SetFormItemEnabled()
	
	// The blocking mechanism has blocked the banking details
	Items.SetDateInterval.Enabled = Not Items.ValidOnDate.ReadOnly;
	Items.GenerateIssuesAutomatically.ReadOnly = Items.ValidOnDate.ReadOnly;
	Items.LaunchADocument.ReadOnly = Items.ValidOnDate.ReadOnly;
	
	FormControl(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	Object = Form.Object;
	Items = Form.Items;
	
	ValidStatus = PredefinedValue("Enum.BudgetingModelStatuses.Valid");
	// You can edit the schedule, or when the routine task has already been created
	// or the settings are set for which the routine task will be created and the model will be recorded.
	ScheduleEditingIsAvailable = ValueIsFilled(Object.ScheduledJob)
	                               Or (Form.AutomaticallyGenerateTasks
	                                 And Object.Status = ValidStatus
	                                 And Not Object.DeletionMark);
	Items.TheInscriptionSchedule.Enabled = ScheduleEditingIsAvailable;
EndProcedure

&AtClient
Procedure Attachable_ScheduleLabelClick(Item)
	
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	AdditionalParameters = New Structure("ScheduleDialog1", ScheduleDialog1);
	CallbackDescription = New CallbackDescription("SetUpScheduleCompletion", ThisObject, AdditionalParameters);
	ScheduleDialog1.Show(CallbackDescription);
	
EndProcedure

&AtServerNoContext
Function CheckingSettingScheduleForRoutineTask(ScheduledJobID, Schedule)
	JobExists = False;
	
	Job = ScheduledJobsServer.Job(ScheduledJobID);
	
	If Not Job = Undefined Then
		JobExists = True;
		
		If String(Schedule) <> String(Job.Schedule) Then
			JobParameters = New Structure;
			JobParameters.Insert("Schedule", Schedule);
			ScheduledJobsServer.ChangeJob(ScheduledJobID, JobParameters);
		EndIf;
	EndIf;
	
	Return JobExists;
	
EndFunction
&AtClient
Procedure SetUpScheduleCompletion(Schedule1, AdditionalParameters) Export
	
	ScheduleDialog1 = AdditionalParameters.ScheduleDialog1;
	
	If Schedule1 <> Undefined Then
		
		Schedule         = ScheduleDialog1.Schedule;
		If DataSeparationEnabled 
		   And Schedule.RepeatPeriodInDay > 0
		   And Schedule.RepeatPeriodInDay < 3600 Then
			
			Schedule.RepeatPeriodInDay = 3600;
			
		EndIf;
		
		If Not ValueIsFilled(Object.ScheduledJob)
		 Or Not CheckingSettingScheduleForRoutineTask(Object.ScheduledJob, Schedule) Then
			Modified = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionCopyViewsStagesModelsCompletion(QuestionResult, CloseForm_ = False) Export
		
	If Not QuestionResult = DialogReturnCode.Yes Then
		CopyingModel = Undefined;
		If CloseForm_ Then
			Close();
		EndIf;
		Return;
	EndIf;
	
	ParametersList = New Structure;
	ParametersList.Insert("CopyingModel", CopyingModel);
	ParametersList.Insert("BudgetingModel", Object.Ref);
		
	CopyingModel = Undefined;
		
	Notification = New CallbackDescription("WhenClosingCopyForm", ThisObject, CloseForm_);
	OpenForm("Catalog.BudgetingModels.Form.CopyForm", ParametersList, ThisObject, , , , Notification);

EndProcedure

&AtClient
Procedure WhenClosingCopyForm(Result, CloseForm_) Export
	
	If CloseForm_ Then
		Close();
	EndIf;
	
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
