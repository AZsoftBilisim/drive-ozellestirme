///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("User", User) Then
		Common.MessageToUser(NStr(
			"vi = 'Danh sách chỉ khả dụng từ biểu mẫu báo cáo hoặc thanh lệnh báo cáo';
			|ru = 'Список доступен только из формы отчета или панели отчетов';
			|en = 'The report snapshot list is available only from a report form or report panel.'; fa = 'The report snapshot list is available only from a report form or report panel.';
			|it = 'Список доступен только из формы отчета или панели отчетов';
			|pl = 'The report snapshot list is available only from a report form or report panel.';
			|tr = 'Listeye yalnızca rapor formundan veya rapor panelinden erişilebilir'"), , , , Cancel);
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	Parameters.Property("CatalogNameReportOptions", CatalogNameReportOptions);
	
	FillReportsSnapshots();
	
#If Not MobileStandaloneServer Then
	If Users.IsFullUser() Then
		Items.ShowAllReportsSnapshots.Visible = True;
	EndIf;
#EndIf
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

#If MobileClient Then
	CommandBarLocation = FormCommandBarLabelLocation.None;
	Items.MobileClientButtonGroup.Visible = True;
	Items.ReportsSnapshots.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	
	If MainServerAvailable() = False Then
		Items.GroupSaveReportsSnapshots.Enabled = False;
		Items.ReportsSnapshotsSaveReportSnapshot.Enabled = False;
	EndIf;
#EndIf
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
 
&AtClient
Procedure ShowAllReportsSnapshotsOnChange(Item)
	
	FillReportsSnapshots();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAllCommand(Command)
	
	For Each RowReport In ListOfReportSnapshots Do
		RowReport.Check = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	For Each RowReport In ListOfReportSnapshots Do
		RowReport.Check = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateReportsSnapshots(Command)
	
	RowsIDs = New Array;
	For Each RowReport In ListOfReportSnapshots Do
		If RowReport.Check Then
			RowsIDs.Add(RowReport.GetID());
		EndIf;
	EndDo;
	
	If RowsIDs.Count() = 0 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("AfterReportsSnapshotsUpdated", ThisObject);
	TimeConsumingOperation = Undefined;
	IdleParameters = Undefined;
	
#If MobileClient Then
	Execute("TimeConsumingOperation = UpdateReportsSnapshotsAtServer(RowsIDs)");
	Execute("IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject)");
	Execute("TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters)");
#Else
	TimeConsumingOperation = UpdateReportsSnapshotsAtServer(RowsIDs);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
#EndIf
	
EndProcedure


#If Not MobileStandaloneServer Then

&AtServer
Function UpdateReportsSnapshotsAtServer(RowsIDs)
	
	FillParameters = New Structure;
	FillParameters.Insert("User", User);
	FillParameters.Insert("CatalogNameReportOptions", CatalogNameReportOptions);
	
	UserReportsSnapshots = ListOfReportSnapshots.Unload(, "User, Report, Variant, UserSettingsHash");
	UserReportsSnapshots.Clear();
	For Each RowID In RowsIDs Do
		RowReport = ListOfReportSnapshots.FindByID(RowID);
		NewRow = UserReportsSnapshots.Add();
		FillPropertyValues(NewRow, RowReport);
	EndDo;
	FillParameters.Insert("ReportsSnapshots", UserReportsSnapshots);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật ảnh chụp báo cáo của người sử dụng';
														|ru = 'Обновление снимков отчетов пользователя';
														|en = 'Update user report snapshots'; fa = 'Update user report snapshots';
														|it = 'Обновление снимков отчетов пользователя';
														|pl = 'Update user report snapshots';
														|tr = 'Kullanıcı raporlarının anlık görüntülerinin güncellenmesi'");
	ExecutionParameters.RefinementErrors = NStr("vi = 'Không thể cập nhật ảnh chụp báo cáo do:';
												|ru = 'Не удалось обновить снимки отчетов по причине:';
												|en = 'Cannot update the report snapshots due to:'; fa = 'Cannot update the report snapshots due to:';
												|it = 'Не удалось обновить снимки отчетов по причине:';
												|pl = 'Cannot update the report snapshots due to:';
												|tr = 'Raporların anlık görüntülerinin güncellenememe nedeni:'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.ReportsSnapshots.UpdateUserReportsSnapshots",
		FillParameters, ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction

#EndIf

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterReportsSnapshotsUpdated(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
#If MobileClient Then
		Execute("StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo)");
#Else
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
#EndIf
		Return;
	EndIf;

	NotificationText1 = NStr("vi = 'Đã cập nhật ảnh chụp báo cáo.';
							|ru = 'Снимки отчетов обновлены.';
							|en = 'Report snapshots are updated.'; fa = 'Report snapshots are updated.';
							|it = 'Снимки отчетов обновлены.';
							|pl = 'Report snapshots are updated.';
							|tr = 'Raporların anlık görüntüleri güncellendi.'");
	ShowUserNotification(NStr("vi = 'Đã cập nhật xong ảnh chụp';
								|ru = 'Обновление снимков завершено';
								|en = 'Snapshots updated'; fa = 'Snapshots updated';
								|it = 'Обновление снимков завершено';
								|pl = 'Snapshots updated';
								|tr = 'Anlık görüntü güncellemesi tamamlandı'"), , NotificationText1);
	
	FillReportsSnapshots();
	
EndProcedure

&AtClient
Procedure DeleteReportsSnapshots(Command)
	
	RowsIDs = New Array;
	For Each RowReport In ListOfReportSnapshots Do
		If RowReport.Check Then
			RowsIDs.Add(RowReport.GetID());
		EndIf;
	EndDo;

	If RowsIDs.Count() > 0 Then
		DeleteReportsSnapshotsAtServer(RowsIDs);
	EndIf;

EndProcedure

&AtServer
Procedure DeleteReportsSnapshotsAtServer(RowsIDs)
	
	DeletionMode = Common.RecordSetDeletionMode();
	BatchMode = DeletionMode <> Undefined;

	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.ReportsSnapshots");
	LockItem.SetValue("User", User);
	
	BeginTransaction();
	Try
		Block.Lock();

		If BatchMode Then
			RecordsToDelete = InformationRegisters.ReportsSnapshots.CreateRecordSet();
			For Each RowID In RowsIDs Do
				RowReport = ListOfReportSnapshots.FindByID(RowID);
				RecordToDelete = RecordsToDelete.Add();
				FillPropertyValues(RecordToDelete, RowReport);
			EndDo;
			RecordsToDelete.Write(DeletionMode);
		Else
			For Each RowID In RowsIDs Do
				RowReport = ListOfReportSnapshots.FindByID(RowID);

				RecordsToDelete = InformationRegisters.ReportsSnapshots.CreateRecordSet();
				RecordsToDelete.Filter.User.Set(RowReport.User);
				RecordsToDelete.Filter.Report.Set(RowReport.Report);
				RecordsToDelete.Filter.Variant.Set(RowReport.Variant);
				RecordsToDelete.Filter.UserSettingsHash.Set(RowReport.UserSettingsHash);
				RecordsToDelete.Write();
			EndDo;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtClient
Procedure OpenReportSnapshot(Command)
	
	RecordStructure = New Structure("User,Report,Variant,UserSettingsHash,UpdateDate");
	
	RowReport = Items.ReportsSnapshots.CurrentData;
	
	If RowReport = Undefined Then
		ClearMessages();
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Chưa chọn ảnh chụp báo cáo.';
							|ru = 'Не выбран снимок отчета.';
							|en = 'A report snapshot is required.'; fa = 'A report snapshot is required.';
							|it = 'A report snapshot is required.';
							|pl = 'A report snapshot is required.';
							|tr = 'Raporun anlık görüntüsü seçilmedi.'");
		Message.Message();
		Return;
	EndIf;
	
	FillPropertyValues(RecordStructure, RowReport);
	
	OpenForm("InformationRegister.ReportsSnapshots.RecordForm",
		New Structure("RecordStructure", RecordStructure), ThisObject, UUID);

EndProcedure

&AtClient
Procedure UpdateReportSnapshot(Command)
	
	If Items.ReportsSnapshots.CurrentRow = Undefined Then
		ClearMessages(); 
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Chưa chọn ảnh chụp báo cáo.';
							|ru = 'Не выбран снимок отчета.';
							|en = 'A report snapshot is required.'; fa = 'A report snapshot is required.';
							|it = 'A report snapshot is required.';
							|pl = 'A report snapshot is required.';
							|tr = 'Raporun anlık görüntüsü seçilmedi.'");
		Message.Message();
		Return;
	EndIf;
	
	RowsIDs = New Array;
	RowsIDs.Add(Items.ReportsSnapshots.CurrentRow);
	
	CallbackDescription = New CallbackDescription("AfterReportsSnapshotsUpdated", ThisObject);
	TimeConsumingOperation = Undefined;
	IdleParameters = Undefined;
	
#If MobileClient Then
	Execute("TimeConsumingOperation = UpdateReportsSnapshotsAtServer(RowsIDs)");
	Execute("IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject)");
	Execute("TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters)");
#Else
	TimeConsumingOperation = UpdateReportsSnapshotsAtServer(RowsIDs);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
#EndIf
	
EndProcedure

#EndRegion

#Region ReportsSnapshotsFormTableEventHandlers

&AtClient
Procedure ReportsSnapshotsListChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	RowReport = ListOfReportSnapshots.FindByID(RowSelected);
	RowReport.Check = Not RowReport.Check;
	
EndProcedure

&AtClient
Procedure ReportsSnapshotsBeforeDeleteRow(Item, Cancel)
	
	RowsIDs = New Array;
	RowsIDs.Add(Items.ReportsSnapshots.CurrentRow);
	
	DeleteReportsSnapshotsAtServer(RowsIDs);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportsSnapshotsUser.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShowAllReportsSnapshots");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

&AtServer
Procedure FillReportsSnapshots()

	ListOfReportSnapshots.Load(InformationRegisters.ReportsSnapshots.UserReportsSnapshots(
		?(ShowAllReportsSnapshots, Undefined, User), CatalogNameReportOptions));

EndProcedure

#EndRegion