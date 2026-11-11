
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillInDescriptionOfCustomRoutineTasks();
	ManagingElementVisibility();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DeleteUnusedConstraintsOnInventoryBelongingToRetailOutlets(Command)
	DeleteUnusedDataToClarifyInventoryOwnershipOfRetailOutlets();
	Items.List.Refresh();
EndProcedure

&AtClient
Procedure SetUpScheduleForDeletingUnusedConstraintsOnInventoryBelongingToRetailOutlets(Command)
	
	RetailSalesClientLocalization.OpenScheduleSetupFormForRoutineTask(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure ClearAllData(Command)
	CallbackDescription  = New CallbackDescription("ClearEntireRegister", ThisObject);
	QueryText = NStr("vi = 'Bạn chuẩn bị xóa tất cả dữ liệu của biểu ghi. Tiếp tục?';
					|ru = 'Вы собираетесь удалить все данные регистра. Продолжить?';
					|en = 'You are going to delete all the register data. Continue?'; fa = 'You are going to delete all the register data. Continue?';
					|it = 'You are going to delete all the register data. Continue?';
					|pl = 'You are going to delete all the register data. Continue?';
					|tr = 'Tüm kayıt verilerini silmek üzeresiniz. Devam edilsin mi?'");
	StrTitle = NStr("vi = 'Xóa tất cả bản ghi';
					|ru = 'Удаление всех записей';
					|en = 'Delete all records'; fa = 'حذف همه رکوردها';
					|it = 'Delete all records';
					|pl = 'Delete all records';
					|tr = 'Tüm kayıtların silinmesi'");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel,20,, StrTitle);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElementVisibility();
	
	UseRetailSales = GetFunctionalOption("UseRetailSales");
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	Items.FormDeleteUnusedConstraintsOnInventoryBelongingToRetailOutlets.Visible = UseRetailSales;
	Items.FormToSetUpScheduleForDeletingUnusedClarificationsOfInventoryBelongingToRetailOutlets.Visible = DataSeparationEnabled And UseRetailSales;
	Items.List.ReadOnly = True;
	Items.List.ChangeRowSet = False;
	Items.List.ChangeRowOrder = False;
	Items.FormClearAllData.Visible = AccessRight("Update", Metadata.InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation);
	
EndProcedure

&AtServer
Procedure FillInDescriptionOfCustomRoutineTasks()
	
	SetPrivilegedMode(True);
	
	DescriptionOfCustomScheduledTasks = New Structure;
	DescriptionOfCustomScheduledTasks.Insert("DeleteUnusedInventoryAffiliationDataOfRetailOutlets", 
					New Structure("NameOfRoutineTaskMetadata, MetadataForCheckingAccessRightsForChanges",
									Metadata.ScheduledJobs.DeleteUnusedInventoryAffiliationDataOfRetailOutlets.Name, New ValueList));
	
EndProcedure

&AtClient
Procedure DeleteUnusedDataToClarifyInventoryOwnershipOfRetailOutlets()
	
	ProcessingResult = DeleteUnusedClarificationsAtServerForInventoryBelongingToRetailOutlets();

	If Not ProcessingResult.Status = "Completed2" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("CompleteRoutineTaskNotification", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(
			ProcessingResult, CallbackOnCompletion, IdleParameters);
		
	Else
		NotifyUserOfTaskResults(ProcessingResult);
	EndIf;
	
EndProcedure

&AtServer
Function DeleteUnusedClarificationsAtServerForInventoryBelongingToRetailOutlets()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.BackgroundJobDescription = Commands.DeleteUnusedConstraintsOnInventoryBelongingToRetailOutlets.ToolTip;
	ExecutionParameters.WaitCompletion = 0;
	
	Method = "InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation.DeleteUnusedDataOnInventoryOwnershipOfRetailOutlets";
	Result = TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, Method);
		
	Return Result;
	
EndFunction

&AtClient
Procedure CompleteRoutineTaskNotification(Result, AdditionalParameters) Export
	
	NotifyUserOfTaskResults(Result);
	
EndProcedure

&AtClient
Procedure NotifyUserOfTaskResults(ProcessingResult)
	
	If ProcessingResult = Undefined Then
		Return;
	EndIf;

	If ProcessingResult.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(ProcessingResult.ErrorInfo);
		If StandardSubsystemsClient.ClientRunParameters().FileInfobase Then
			ErrorMessage = NStr("vi = 'Đã hoàn tất xóa dữ liệu không sử dụng khỏi biểu ghi và bị lỗi.';
								|ru = 'Удаление из регистра неиспользуемых данных завершено с ошибками.';
								|en = 'Deletion of unused data from the register completed with errors.'; fa = 'Deletion of unused data from the register completed with errors.';
								|it = 'Deletion of unused data from the register completed with errors.';
								|pl = 'Deletion of unused data from the register completed with errors.';
								|tr = 'Kullanılmayan verilerin kayıttan silinmesi hatalarla tamamlandı.'");
		Else
			ErrorMessage = NStr("vi = 'Đã hoàn tất xóa dữ liệu không sử dụng khỏi biểu ghi và bị lỗi. Xem nhật ký sự kiện.';
								|ru = 'Удаление из регистра неиспользуемых данных завершено с ошибками. См. журнал регистрации.';
								|en = 'Deletion of unused data from the register completed with errors. See the event log.'; fa = 'Deletion of unused data from the register completed with errors. See the event log.';
								|it = 'Deletion of unused data from the register completed with errors. See the event log.';
								|pl = 'Deletion of unused data from the register completed with errors. See the event log.';
								|tr = 'Kullanılmayan verilerin kayıttan silinmesi hatalarla tamamlandı. Olay günlüğüne bakın.'");
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Đã hoàn tất xóa dữ liệu không sử dụng khỏi biểu ghi.';
									|ru = 'Удаление из регистра неиспользуемых данных завершено.';
									|en = 'Unused data is deleted from the register.'; fa = 'Unused data is deleted from the register.';
									|it = 'Unused data is deleted from the register.';
									|pl = 'Unused data is deleted from the register.';
									|tr = 'Kullanılmayan verilerin kayıttan silinmesi tamamlandı.'"),
				,
				ErrorMessage,
				PictureLib.Information32);
		
		Return;
	ElsIf ProcessingResult.Status = "Completed2" Then
		ShowUserNotification(NStr("vi = 'Đã hoàn tất xóa dữ liệu không sử dụng khỏi biểu ghi.';
									|ru = 'Удаление из регистра неиспользуемых данных завершено.';
									|en = 'Unused data is deleted from the register.'; fa = 'Unused data is deleted from the register.';
									|it = 'Unused data is deleted from the register.';
									|pl = 'Unused data is deleted from the register.';
									|tr = 'Kullanılmayan verilerin kayıttan silinmesi tamamlandı.'"),
			,
			NStr("vi = 'Đã xóa thành công dữ liệu không sử dụng khỏi biểu ghi.';
				|ru = 'Удаление из регистра неиспользуемых данных успешно завершено.';
				|en = 'Unused data is successfully deleted from the register.'; fa = 'Unused data is successfully deleted from the register.';
				|it = 'Unused data is successfully deleted from the register.';
				|pl = 'Unused data is successfully deleted from the register.';
				|tr = 'Kullanılmayan verilerin kayıttan silinmesi başarıyla tamamlandı.'"),
			PictureLib.Information32);
	EndIf;
		
EndProcedure

&AtClient
Procedure ClearEntireRegister(Val QuestionResult, Val AddlParameters = Undefined) Export 
	
	If QuestionResult = DialogReturnCode.OK Then
		ClearEntireRegisterServer();
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ClearEntireRegisterServer() 
	
	If AccessRight("Update", Metadata.InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation) Then
		SetPrivilegedMode(True);
		Set = InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation.CreateRecordSet();
		Set.Write();
	EndIf;
	
EndProcedure

#EndRegion