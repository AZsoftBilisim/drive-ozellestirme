#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	DataSeparationEnabled = Common.DataSeparationEnabled();

	If Not Allowed1Update() Then
		Items.ScheduledJobsTable.ReadOnly = True;
		Items.ScheduledJobsTableSetUpSchedule.Enabled = False;
	EndIf;
	
	Items.ScheduledJobsTableSetUpSchedule.Visible = Not DataSeparationEnabled;
	
	PriceManagementSystemServerCall.SetPropertiesOfSceneryInformingAboutRemovalOfPricingVersion20(Items);
	
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
	If Allowed1Update() Then
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
								|it = 'Selezionate un task di routine.';
								|pl = 'Wybierz jedno planowe zadanie.';
								|tr = 'Programlı bir iş seçin.'"));
		
	ElsIf Item.CurrentData.Predefined Then
		ShowMessageBox(, NStr("vi = 'Không thể xóa nhiệm vụ thường kỳ định trước.';
								|ru = 'Невозможно удалить предопределенное регламентное задание.';
								|en = 'Predefined scheduled job cannot be deleted.'; fa = 'Predefined scheduled job cannot be deleted.';
								|it = 'Non è possibile eliminare il task di routine predefinito.';
								|pl = 'Nie można usunąć zdefiniowanego planowego zadanie.';
								|tr = 'Önceden tanımlanmış programlı işi silmek mümkün değildir.'") );
	Else
		ShowQueryBox(
			New CallbackDescription("ScheduledJobsTableBeforeDeleteRowCompletion", ThisObject),
			NStr("vi = 'Xóa nhiệm vụ thường kỳ?';
				|ru = 'Удалить регламентное задание?';
				|en = 'Do you want to delete the scheduled job?'; fa = 'Do you want to delete the scheduled job?';
				|it = 'Eliminare il task di routine?';
				|pl = 'Usunąć planowe zadanie?';
				|tr = 'Programlı iş silinsin mi?'"), QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

&AtClient
Procedure AddCopyEditScheduledJob(Val Action)
	
	FormParameters = New Structure;
	FormParameters.Insert("Action",      Action);
	
	If Not Items.ScheduledJobsTable.CurrentData = Undefined Then
		FormParameters.Insert("Id", Items.ScheduledJobsTable.CurrentData.Id);
	EndIf;

	OpenForm("Catalog.TypesOfPrices.Form.ScheduledJobPriceUpdate", FormParameters, ThisObject);
	
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
								|it = 'Selezionate un task di routine.';
								|pl = 'Wybierz planowe zadanie.';
								|tr = 'Programlı iş seçin.'"));
	
	ElsIf Items.ScheduledJobsTable.SelectedRows.Count() > 1 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn một nhiệm vụ thường kỳ.';
								|ru = 'Выберите одно регламентное задание.';
								|en = 'Select one scheduled job.'; fa = 'Select one scheduled job.';
								|it = 'Selezionate un task di routine.';
								|pl = 'Wybierz jedno planowe zadanie.';
								|tr = 'Programlı bir iş seçin.'"));
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
		Filter = New Structure("Metadata", Metadata.ScheduledJobs.UpdatePrices);
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
				ToUpdate.Description = AutoDescription(Job.Parameters);
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
				Rows[0].Description = AutoDescription(CurrentJobs[0].Parameters);
			EndIf;
		EndIf;
	EndIf;
	
	ProcessResult(New Structure("Table", Table));
	
	Return True ;
	
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
	
	ImportScheduledJobs();
	
EndProcedure

&AtServerNoContext
Function Allowed1Update()
	Return AccessRight("Update", Metadata.Catalogs.TypesOfPrices);
EndFunction

&AtClientAtServerNoContext
Function AutoDescription(Parameters)
	
	NameString_ = "";
	
	PriceUpdateOption = 0;
	TypesOfPrices = New Array();
	
	TypesOfPrices.Clear();;
	
	If (Parameters.Count() > 0) Then
		
		For Each String In Parameters[0] Do
			TypesOfPrices.Add(String.PriceKind);
		EndDo;
		
		PriceUpdateOption = Parameters[1].PriceUpdateOption;
		
	EndIf;
	
	NameString_ = NStr("vi = 'Cập nhật giá (';
						|ru = 'Обновление цен (';
						|en = 'Update prices ('; fa = 'Update prices (';
						|it = 'Aggiornamento prezzi (';
						|pl = 'Aktualizacja cen (';
						|tr = 'Fiyat güncellemesi ('");
	
	If PriceUpdateOption = 0 Then
		NameString_ = NameString_ + NStr("vi = 'Tất cả)';
										|ru = 'Все)';
										|en = 'All)'; fa = 'All)';
										|it = 'Все)';
										|pl = 'Wszystkie)';
										|tr = 'Tümü)'");
	ElsIf PriceUpdateOption = 1 Then
		NameString_ = NameString_ + NStr("vi = 'Chỉ mục được chọn)';
										|ru = 'Только выбранные)';
										|en = 'Selected roles only)'; fa = 'Selected roles only)';
										|it = 'Solo selezionate)';
										|pl = 'Tylko wybrane)';
										|tr = 'Sadece seçilenler)'");
	ElsIf PriceUpdateOption = 2 Then
		NameString_ = NameString_ + NStr("vi = 'Các mục được chọn và phụ thuộc)';
										|ru = 'Выбранные и зависимые)';
										|en = 'Selected and dependent)'; fa = 'Selected and dependent)';
										|it = 'Selezionati e dipendenti)';
										|pl = 'Wybrane i zależne)';
										|tr = 'Seçilenler ve bağlı olanlar)'");
	ElsIf PriceUpdateOption = 3 Then
		NameString_ = NameString_ + NStr("vi = 'Tất cả ngoại trừ các mục được chọn)';
										|ru = 'Все кроме выбранных)';
										|en = 'All except selected)'; fa = 'All except selected)';
										|it = 'Tutti tranne i selezionati)';
										|pl = 'Wszystkie oprócz wybranych)';
										|tr = 'Seçilenler hariç tümü)'");
	EndIf;
	
	ThisIsFirstItemOfList = True;
	For Each PriceKind In TypesOfPrices Do
		NameString_ = NameString_ + ?(ThisIsFirstItemOfList," ",", ") + PriceKind;
		ThisIsFirstItemOfList = False;
	EndDo;
	
	Return NameString_;
	
EndFunction

#EndRegion
