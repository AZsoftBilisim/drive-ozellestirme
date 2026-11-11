
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	NameOfRoutineTaskMetadata = Parameters.NameOfRoutineTaskMetadata;
	If IsBlankString(NameOfRoutineTaskMetadata) Then
		Raise NStr("vi = 'Chưa chỉ ra tên nhiệm vụ thường kỳ để tùy chỉnh.';
					|ru = 'Не указано имя регламентного задания для настройки.';
					|en = 'The name of the scheduled job to set up is not specified.'; fa = 'The name of the scheduled job to set up is not specified.';
					|it = 'Не указано имя регламентного задания для настройки.';
					|pl = 'The name of the scheduled job to set up is not specified.';
					|tr = 'Ayarlanacak zamanlanmış görevin adı belirtilmemiş.'");
	EndIf;
	MetadataForCheckingAccessRightsForChanges = Parameters.MetadataForCheckingAccessRightsForChanges;
	
	If Not Allowed1Update(MetadataForCheckingAccessRightsForChanges) Then
		Items.ScheduledJobsTable.ReadOnly = True;
		Items.ScheduledJobsTableSetUpSchedule.Enabled = False;
	EndIf;
	
	Items.ScheduledJobsTableSetUpSchedule.Visible = Not DataSeparationEnabled;
	Title = StrTemplate(NStr("vi = 'Tùy chỉnh nhiệm vụ: %1';
							|ru = 'Настройка задания: %1';
							|en = 'Job setup: %1'; fa = 'Job setup: %1';
							|it = 'Настройка задания: %1';
							|pl = 'Job setup: %1';
							|tr = 'Görev ayarları: %1'"), Metadata.ScheduledJobs[NameOfRoutineTaskMetadata].Presentation());
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ImportScheduledJobs();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ScheduledJobs" Then
		
		ImportScheduledJobs(Parameter);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScheduledJobsTable
&AtClient
Procedure ScheduledJobsTableBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	Cancel = True;
	
	AddCopyEditScheduledJob(?(Copy, "Copy", "Add"));
EndProcedure

&AtClient
Procedure ScheduledJobsTableBeforeRowChange(Item, Cancel)
	Cancel = True;
	If Allowed1Update(MetadataForCheckingAccessRightsForChanges) Then
		AddCopyEditScheduledJob("Change");
	EndIf;
EndProcedure

&AtClient
Procedure ScheduledJobsTableBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	
	If Items.ScheduledJobsTable.SelectedRows.Count() > 1 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn một nhiệm vụ thường kỳ.';
								|ru = 'Выберите одно регламентное задание.';
								|en = 'Select one scheduled job.'; fa = 'Select one scheduled job.';
								|it = 'Выберите одно регламентное задание.';
								|pl = 'Wybierz jedno planowe zadanie.';
								|tr = 'Zamanlanmış bir görev seçin.'"));
		
	ElsIf Item.CurrentData.Predefined Then
		ShowMessageBox(, NStr("vi = 'Không thể xóa bỏ nhiệm vụ thường kỳ định trước.';
								|ru = 'Невозможно удалить предопределенное регламентное задание.';
								|en = 'Predefined scheduled job cannot be deleted.'; fa = 'Predefined scheduled job cannot be deleted.';
								|it = 'Невозможно удалить предопределенное регламентное задание.';
								|pl = 'Nie można usunąć zdefiniowanego planowego zadanie.';
								|tr = 'Ön tanımlı zamanlanmış görev silinemiyor.'") );
	Else
		ShowQueryBox(
			New CallbackDescription("ScheduledJobsTableBeforeDeleteRowCompletion", ThisObject),
			NStr("vi = 'Xóa nhiệm vụ thường kỳ?';
				|ru = 'Удалить регламентное задание?';
				|en = 'Do you want to delete the scheduled job?'; fa = 'Do you want to delete the scheduled job?';
				|it = 'Удалить регламентное задание?';
				|pl = 'Usunąć planowe zadanie?';
				|tr = 'Zamanlanmış görev silinsin mi?'"), QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

&AtClient
Procedure AddCopyEditScheduledJob(Val Action)
	
	FormParameters = New Structure;
	FormParameters.Insert("Action",      Action);
	
	If Not Items.ScheduledJobsTable.CurrentData = Undefined Then
		FormParameters.Insert("Id", Items.ScheduledJobsTable.CurrentData.Id);
	EndIf;
	
	FormParameters.Insert("NameOfRoutineTaskMetadata", NameOfRoutineTaskMetadata);
   	FormParameters.Insert("MetadataForCheckingAccessRightsForChanges", MetadataForCheckingAccessRightsForChanges);
	
	OpenForm("DataProcessor.TMAdministrationPanel.Form.ScheduledJobSetting", FormParameters, ThisObject);
	
EndProcedure
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetUpSchedule(Command)
	CurrentData = Items.ScheduledJobsTable.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ thường kỳ.';
								|ru = 'Выберите регламентное задание.';
								|en = 'Select a scheduled job.'; fa = 'Select a scheduled job.';
								|it = 'Выберите регламентное задание.';
								|pl = 'Wybierz planowe zadanie.';
								|tr = 'Zamanlanmış görev seçin.'"));
	
	ElsIf Items.ScheduledJobsTable.SelectedRows.Count() > 1 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn một nhiệm vụ thường kỳ.';
								|ru = 'Выберите одно регламентное задание.';
								|en = 'Select one scheduled job.'; fa = 'Select one scheduled job.';
								|it = 'Выберите одно регламентное задание.';
								|pl = 'Wybierz jedno planowe zadanie.';
								|tr = 'Zamanlanmış bir görev seçin.'"));
	Else
		Dialog = New ScheduledJobDialog(
			GetSchedule(CurrentData.Id));
		
		Dialog.Show(New CallbackDescription(
			"OpenScheduleEnd", ThisObject, CurrentData));
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateScheduledJobs(Command)
	
	ImportScheduledJobs();

EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SetSchedule(Val ScheduledJobID, Val Schedule)
	
	SetPrivilegedMode(True);
	
	ScheduledJobsServer.SetJobSchedule(
		ScheduledJobID,
		Schedule);

	SetPrivilegedMode(False);
	
EndProcedure

// Setting a new schedule
// 
// Parameters:
// 	NewSchedule - JobSchedule
// 	CurrentData - FormDataCollectionItem
&AtClient
Procedure OpenScheduleEnd(NewSchedule, CurrentData) Export

	If NewSchedule <> Undefined Then

		If DataSeparationEnabled 
			And NewSchedule.RepeatPeriodInDay > 0
			And NewSchedule.RepeatPeriodInDay < 3600 Then
			
			NewSchedule.RepeatPeriodInDay = 3600;
			
		EndIf;
		
		SetSchedule(CurrentData.Id, NewSchedule);
		ImportScheduledJobs(CurrentData.Id);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetSchedule(Val ScheduledJobID)
	
	SetPrivilegedMode(True);
	
	Return ScheduledJobsServer.JobSchedule(
		ScheduledJobID);
	
EndFunction

&AtServer
Function ImportScheduledJobs(JobID = Undefined)

	Table =  FormAttributeToValue("ScheduledJobsTable");

	// Updating the Schedule task table and the list of lists of the selection of the schedule task for selection.
	If JobID = Undefined Then
		ScheduledJob = Metadata.ScheduledJobs[NameOfRoutineTaskMetadata];
		ScheduledJobPresentation = ScheduledJob.Presentation();
		Filter = New Structure("Metadata", Metadata.ScheduledJobs[NameOfRoutineTaskMetadata]);
	Else	
		Filter = New Structure("UUID",New UUID(JobID));
	EndIf;
	
	SetPrivilegedMode(True);
	CurrentJobs = ScheduledJobsServer.FindJobs(Filter);
	SetPrivilegedMode(False);
	
	If JobID = Undefined Then
		IndexOf = 0;
		For Each Job In CurrentJobs Do
			
			Id = String(ScheduledJobsServer.UUID(Job));
			
			If IndexOf >= Table.Count()
			 Or Table[IndexOf].Id <> Id Then
				
				// Inserting a new task.
				ToUpdate = Table.Insert(IndexOf);
			Else
				ToUpdate = Table[IndexOf];
			EndIf;
			
			FillPropertyValues(ToUpdate, Job);

			ToUpdate.Id = Id;
			
			If IsBlankString(ToUpdate.Description) Then
				ToUpdate.Description = AutoDescription(ScheduledJobPresentation, Job.Parameters);
			EndIf;
			
			IndexOf = IndexOf + 1;
		EndDo;
	
		// Deleting extra lines.
		While IndexOf < Table.Count() Do
			Table.Delete(IndexOf);
		EndDo;
	Else
		
		Rows = Table.FindRows(
			New Structure("Id", JobID));
		
		If Rows.Count() > 0 
			And CurrentJobs.Count() > 0 Then
			
			FillPropertyValues(Rows[0], CurrentJobs[0]);
			Rows[0].Id = JobID;
			If IsBlankString(Rows[0].Description) Then
				Rows[0].Description = AutoDescription(ScheduledJobPresentation, CurrentJobs[0].Parameters);
			EndIf;
		EndIf;
	EndIf;
	
	ProcessResult(New Structure("Table", Table));
	
	Return True;
	
EndFunction

&AtServer
Procedure ProcessResult(Result)
	
	ValueToFormAttribute(Result.Table, "ScheduledJobsTable");
	
	Items.ScheduledJobsTable.Refresh();
	
EndProcedure

&AtClient
Procedure ScheduledJobsTableBeforeDeleteRowCompletion(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		DeleteScheduledJobExecuteAtServer(
			Items.ScheduledJobsTable.CurrentData.Id);
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteScheduledJobExecuteAtServer(Val Id)
	
	SetPrivilegedMode(True);
	ScheduledJobsServer.DeleteJob(Id);
	SetPrivilegedMode(False);
	
	ImportScheduledJobs();
	
EndProcedure

&AtServerNoContext
Function Allowed1Update(MetadataForCheckingAccessRightsForChanges)
	Result = True;

	For Each RightsVerificationElement In MetadataForCheckingAccessRightsForChanges Do
        MetadataForRightsVerification = Metadata.FindByFullName(RightsVerificationElement.Value);
		If ValueIsFilled(MetadataForRightsVerification) And Not AccessRight("Update", MetadataForRightsVerification) Then
			Result = False;
			Break;
		EndIf;	
	EndDo;
	Return Result;
EndFunction

&AtClientAtServerNoContext
Function AutoDescription(Presentation, Parameters)
	
	NameString_ = Presentation;
	
	Return NameString_;
	
EndFunction

#EndRegion