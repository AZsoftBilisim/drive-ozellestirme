///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var CurrentOperation1; // See TimeConsumingOperations.ExecuteFunction

&AtClient
Var PresentationOperation; // String

&AtClient
Var DeletionResultsInfo; // See NewDeletionResultsInfo

&AtClient
Var FormJobsQueue; // Array of String

&AtClient
Var PreviousStepResult;

&AtClient
Var ReportToSend; // ErrorReport 

&AtClient
Var NotDeletedItemRelationsAction;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Users.IsFullUser() Then
		ErrorText = NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
						|ru = 'Недостаточно прав для выполнения операции.';
						|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
						|it = 'Diritti insufficienti per eseguire l''operazione.';
						|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
						|tr = 'İşlem için gerekli yetkiler yok.'");
		Return; // Cancel is set in OnOpen.
	EndIf;
	
	If Common.DataSeparationEnabled() And Not Common.SeparatedDataUsageAvailable() Then
		ErrorText = NStr("vi = 'Để xóa các đối tượng có đánh dấu, hãy nhập vào vùng dữ liệu.';
						|ru = 'Для удаления помеченных войдите в область данных.';
						|en = 'To delete marked objects, log in to the data area.'; fa = 'To delete marked objects, log in to the data area.';
						|it = 'Per eliminazione gli elementi contrassegnati, entrare nell''area dati.';
						|pl = 'Aby usunąć zaznaczone wejdź do obszaru danych.';
						|tr = 'İşaretli olanları silmek için veri alanına girin.'");
		Return; // Cancel is set in OnOpen.
	EndIf;
	
	If Parameters.ObjectsToDelete.Count() > 0 Then
		ConfigureFormToWorkAsService();
	Else
		ToStartSearchingForTheMarkedSettingOfTheForm(ThisObject);
	EndIf;
	
	If Parameters.MetadataFilter.Count() > 0 Then
		SetPassedMetadataFilter();
	EndIf;
	
	IsMobileClient = Common.IsMobileClient();
	If IsMobileClient Then
		Items.MarkedForDeletionItemsTreeConfigure.Visible = False;
		Items.MarkedForDeletionItemsTreeChange.Visible = False;
		Items.NotDeletedItemsChange.Visible = False;
		Items.Actions.Visible = False;
		Items.Back.Visible = False;
	EndIf;
	
	SetObjectsMarkedForDeletionSelectionState();
	SetConditionalAppearance();	
	SetUsageInstancesActionsList(ThisObject);
	
	ReadOnly = True;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	AdditionalAttributesSettings = Settings["AdditionalAttributesOfItemsMarkedForDeletion"];
	If AdditionalAttributesSettings <> Undefined Then
		AdditionalAttributesNumber = MarkedObjectsDeletionInternal.AdditionalAttributesNumber(
			AdditionalAttributesSettings);
		AddAdditionalAttributes(1, AdditionalAttributesNumber);
		SetConditionalAppearance();
	EndIf;
	
	If Parameters.MetadataFilter.Count() > 0 Then 
		MetadataFilter = Parameters.MetadataFilter;
	Else
		Filter_Settings = Settings["MetadataFilter"];
		If ValueIsFilled(Filter_Settings) Then
			MetadataFilter = SelectionOfMetadataOnlyExisting(Filter_Settings);
			Items.ConfigureFilter.Title = MetadataFilterPresentation(Filter_Settings);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	DeletionResultsInfo = NewDeletionResultsInfo(); 
	PresentationOperation = "";
	FormJobsQueue = New Array;

	If ValueIsFilled(ErrorText) Then
		ShowMessageBox(, ErrorText);
		Cancel = True;
	EndIf;
	
	If DeleteOnOpen Then
		AddJob(FormJobs().DeleteMarkedObjects);
	Else	
		AddJob(FormJobs().MarkedObjectsSearch);
	EndIf;
	AttachIdleHandler("RunJobWithPending", 0.1, True);
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	If Parameters.MetadataFilter.Count() > 0 Then
		Settings["MetadataFilter"] = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Exit Then
		Return;
	EndIf;
	
	If ShowDialogBeforeClose Then
		Cancel = True;
		Handler = New CallbackDescription("AfterConfirmCancelJob", ThisObject);
		QueryText = NStr("vi = 'Đang thực hiện %1.
							|Ngắt?';
							|ru = 'Выполняется %1.
							|Прервать?';
							|en = 'In progress %1.
							|Do you want to stop it?'; fa = 'In progress %1.
							|Do you want to stop it?';
							|it = 'In esecuzione %1.
							|Interrompere?';
							|pl = 'Trwa wykonywanie%1.
							|Przerwać?';
							|tr = '%1 gerçekleştiriliyor. 
							| iptal etmek?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Abort);
		Buttons.Add(DialogReturnCode.Ignore, NStr("vi = 'Không ngắt';
													|ru = 'Не прерывать';
													|en = 'Do not stop'; fa = 'Do not stop';
													|it = 'Non interrompere';
													|pl = 'Nie przerywać';
													|tr = 'İptal etmemek'"));
		
		ShowQueryBox(Handler, 
			StringFunctionsClientServer.SubstituteParametersToString(QueryText, Lower(PresentationOperation)),
		 	Buttons, 60, DialogReturnCode.Ignore);
	ElsIf DeleteOnOpen Then 
		CallbackDescriptionOnClose.AdditionalParameters.Insert("ClosingResult", DeletionResultsInfo);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DetailsRefClick(Item)

	If IsExclusiveModeSettingError(BackgroundJobErrorInfo) Then
		ToOpenTheFormCompleteTheUserExperience();
		Return;
	EndIf;

	If Item.Name = Items.DetailsBackgroundJobError.Name Then
		If ReportToSend = Undefined Then
			ReportToSend = New ErrorReport(BackgroundJobErrorInfo);
		EndIf;
		StandardSubsystemsClient.ShowErrorReport(ReportToSend);	
	Else
		ErrorText = DetailedErrorText;
		StandardSubsystemsClient.ShowDetailedInfo(Undefined, ErrorText);
	EndIf;
EndProcedure

&AtClient
Procedure CancelOperation(Command)
	CancelOperationServer(CurrentOperation1);
	ClearFormJobsQueue();
	
	If CurrentJob().Name = "AdditionalDataProcessorExecution" Then
		SetStateUnsuccessfulDeletion();
	Else
		SetObjectsMarkedForDeletionSelectionState();
	EndIf;
	
	ShowDialogBeforeClose = False;
	CurrentOperation1 = Undefined;
	If DeleteOnOpen Then
		Close();
	EndIf;
EndProcedure

&AtServer
Procedure CancelOperationServer(CurrentOperation1)
	If CurrentOperation1 = Undefined Then
		Return;
	EndIf;
	
	TimeConsumingOperations.CancelJobExecution(CurrentOperation1.JobID);
	MarkedObjectsDeletionInternal.UnlockUsageOfObjectsToDelete(UUID);
	SetExclusiveModeAtServer(False);
EndProcedure

&AtClient
Procedure TotalObjectsToSelect(Command)
	Notification = New CallbackDescription("TotalObjectsToSelectCompletion", ThisObject);
	If ActionsTable.Count() > 0 Then
		ShowQueryBox(Notification, 
			NStr("vi = 'Việc xóa các đối tượng chưa được hoàn tất
			|Quay lại danh sách các đối tượng được đánh dấu để xóa?';
			|ru = 'Не завершено удаление объектов.
			|Вернуться к списку помеченных на удаление?';
			|en = 'Object deletion is not completed.
			|Go back to the list of objects marked for deletion?'; fa = 'Object deletion is not completed.
			|Go back to the list of objects marked for deletion?';
			|it = 'Cancellazione degli oggetti non completata. 
			|Tornare all''elenco dei contrassegnati per la cancellazione?';
			|pl = 'Nie zakończono usunięcie obiektów.
			|Powrócić do listy zaznaczonych do usunięcia?';
			|tr = 'Nesne silme işlemi tamamlanmadı. 
			|Silinmek üzere işaretlenmiş listeye geri dönülsün mü?'"),
			QuestionDialogMode.YesNo);
	Else
		UpdateTheTreeMarkedForDeletion();
		SetObjectsMarkedForDeletionSelectionState();
	EndIf;
EndProcedure

&AtClient
Procedure TotalObjectsToSelectCompletion(Result, AdditionalParameters) Export
	UpdateTheTreeMarkedForDeletion();
	If Result = DialogReturnCode.Yes Then
		ActionsTable.Clear();
		SetObjectsMarkedForDeletionSelectionState();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMarkedForDeletionItemsTree

&AtClient
Procedure MarkedForDeletionItemsTreeCheckOnChange(Item)
	CurrentData = Items.MarkedForDeletionItemsTree.CurrentData;
	If CurrentData.Check = 2 Then
		CurrentData.Check = 0;
	EndIf;
	
	MarkedForDeletionItemsTreeSetMarkInList(CurrentData, CurrentData.Check, True);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNotTrash

&AtClient
Procedure NotTrashOnActivateRow(Item)
	AttachIdleHandler("ShowNotDeletedItemsLinksAtClient", 0.1, True);
EndProcedure

&AtClient
Procedure NotTrashBeforeRowChange(Item, Cancel)
	Cancel = True;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotTrashSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotTrashPresentationOpening(Item, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsLinksChoice(Item, RowSelected, Field, StandardProcessing)
	If Field.Name <> Items.NotDeletedItemRelationsAction.Name Then
		StandardProcessing = False;
		ShowTableObject(Item);
	EndIf;
EndProcedure

&AtClient
Procedure NotDeletedItemsUsageInstancesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	CurrentTreeRow = CurrentRowOfNotDeletedItemsUsageInstances();
	CurrentData = Items.NotDeletedItemsUsageInstances.CurrentData;
	MessageText = SetReplaceOnServer(CurrentData.ItemToDeleteRef, ValueSelected);
	If Not IsBlankString(MessageText) Then
		ShowMessageBox(, MessageText);
	EndIf;
	StandardSubsystemsClient.ExpandTreeNodes(ThisObject, "NotDeletedItemsUsageInstances", "*", True);
	SetCurrentRowOfNotDeletedItemsUsageInstances(CurrentTreeRow);
	
EndProcedure

&AtClient
Procedure NotDeletedItemRelationsActionOnChange(Item)
	CurrentData = Items.NotDeletedItemsUsageInstances.CurrentData;
	ValueSelected = CurrentData.ActionPresentation;
	
	If Not ValueIsFilled(ValueSelected) Then
		
		If CurrentData.Action = "ReplaceRef" Then
			For Each Item In NotDeletedItemsUsageInstances.GetItems() Do
				Item.Action = Undefined;
			EndDo;	
			
			Filter = New Structure("Source", CurrentData.ItemToDeleteRef);
			Actions = ActionsTable.FindRows(Filter);
			For Each Action In Actions Do
				ActionsTable.Delete(Action);
			EndDo;
		Else			
			CurrentData.Action = Undefined;
			
			Filter = New Structure("FoundItemReference", CurrentData.FoundItemReference);
			Actions = ActionsTable.FindRows(Filter);
			For Each Action In Actions Do
				ActionsTable.Delete(Action);
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure NotDeletedItemRelationsActionChoiceProcessing(Item, ValueSelected, StandardProcessing)

	StandardProcessing = False;
	
	NotDeletedItemRelationsAction = New Structure;
	NotDeletedItemRelationsAction.Insert("CurrentTreeRow", CurrentRowOfNotDeletedItemsUsageInstances());
	NotDeletedItemRelationsAction.Insert("RowID", Items.NotDeletedItemsUsageInstances.CurrentRow);
	NotDeletedItemRelationsAction.Insert("ValueSelected", ValueSelected);
	
	RowID = Items.NotDeletedItemsUsageInstances.CurrentRow;
	SelectedRow = NotDeletedItemsUsageInstances.FindByID(RowID);
	SelectedRow.ActionPresentation = "";

	If ValueSelected = "ReplaceRef" Then
		SetReplaceWith(Undefined);
	ElsIf ValueSelected = "Delete" And Not SelectedRow.ReferenceType Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xóa giá trị được chọn: %1';
				|ru = 'Нельзя удалить выбранное значение: %1';
				|en = 'Cannot delete selected value: %1'; fa = 'Cannot delete selected value: %1';
				|it = 'Нельзя удалить выбранное значение: %1';
				|pl = 'Cannot delete selected value: %1';
				|tr = 'Seçilen değer %1 silinemez'"),
			SelectedRow.Presentation));
	Else	
		AttachIdleHandler("NotDeletedItemRelationsActionChoiceProcessingCompletion", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotDeletedItemRelationsActionChoiceProcessingCompletion()

	If NotDeletedItemRelationsAction = Undefined Then
		Return;
	EndIf;
	
	MessageText = SetActionForUsageInstance(NotDeletedItemRelationsAction.RowID, 
		NotDeletedItemRelationsAction.ValueSelected);
	SetCurrentRowOfNotDeletedItemsUsageInstances(NotDeletedItemRelationsAction.CurrentTreeRow);
	If Not IsBlankString(MessageText) Then
		ShowMessageBox(, MessageText);
	EndIf;
	NotDeletedItemRelationsAction = Undefined;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	If CurrentOperation1 = Undefined Then
		RunJob(FormJobs().MarkedObjectsSearch);
	EndIf;
EndProcedure

&AtClient
Procedure ExecuteActionsAndDelete(Command)
	UpdateTheTreeMarkedForDeletion();
	InformationAboutTheSelectedObjects = SelectedObjectsCount();
	SelectedCountTotal = InformationAboutTheSelectedObjects.SelectedCount;
	If SelectedCountTotal = 0 Then
		WarningText = NStr("vi = 'Cần chọn ít nhất một phần tử để xóa.';
							|ru = 'Необходимо выбрать хотя бы один элемент для удаления.';
							|en = 'Select at least one item to be deleted.'; fa = 'Select at least one item to be deleted.';
							|it = 'È necessario selezionare almeno un elemento per l''eliminazione.';
							|pl = 'Należy wybrać co najmniej jeden element do usunięcia.';
							|tr = 'Silmek için en az bir öğe seçmelisiniz.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	AddJob(FormJobs().AdditionalDataProcessorExecution);
	AddJob(FormJobs().DeleteMarkedObjects);
	RunJob();
EndProcedure

&AtClient
Procedure NotDeletedItemsChange(Command)
	If Not CommonClientServer.HasAttributeOrObjectProperty(CurrentItem, "CurrentData") Then
		Return;
	EndIf;

	ShowTableObject(CurrentItem);	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeSelectAll(Command)
	
	MarkedForDeletionItemsTreeSetAllClearAll(True);
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeClearAll(Command)
	
	MarkedForDeletionItemsTreeSetAllClearAll(False);
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeChange(Command)
	ShowTableObject(Items.MarkedForDeletionItemsTree);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeUpdate(Command)
	RunJob(FormJobs().MarkedObjectsSearch);
EndProcedure

&AtClient
Procedure InstallDelete(Command)
	
	CurrentTreeRow = CurrentRowOfNotDeletedItemsUsageInstances();
	SelectedTableRows = New Array;
	NonReferenceValues = New Array;
	AllSelectedTableRows = Items.NotDeletedItemsUsageInstances.SelectedRows;
	TableRowsCount = AllSelectedTableRows.Count();
	For Each TableRowID_ In AllSelectedTableRows Do
		CurrentData = NotDeletedItemsUsageInstances.FindByID(TableRowID_);
		If CurrentData.ReferenceType Then
			SelectedTableRows.Add(TableRowID_);
		Else	
			NonReferenceValues.Add(CurrentData.Presentation);
		EndIf;
	EndDo;

	If SelectedTableRows.Count() > 0 Then
		SetActionForUsageInstances(SelectedTableRows, "Delete");
	EndIf;
	If NonReferenceValues.Count() = 1 Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xóa giá trị được chọn: %1';
				|ru = 'Нельзя удалить выбранное значение: %1.';
				|en = 'Cannot delete selected value: %1.'; fa = 'Cannot delete selected value: %1.';
				|it = 'Нельзя удалить выбранное значение: %1.';
				|pl = 'Cannot delete selected value: %1.';
				|tr = 'Seçilen değer %1 silinemez'"),
			NonReferenceValues[0]));
	ElsIf NonReferenceValues.Count() > 1 And SelectedTableRows.Count() > 0 Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xóa tất cả giá trị được chọn (%1 trong %2).';
				|ru = 'Нельзя удалить все выбранные значения (%1 из %2).';
				|en = 'Cannot delete some of the selected values (%1 out of %2).'; fa = 'Cannot delete some of the selected values (%1 out of %2).';
				|it = 'Нельзя удалить все выбранные значения (%1 из %2).';
				|pl = 'Cannot delete some of the selected values (%1 out of %2).';
				|tr = 'Seçilen tüm değerler (%1/%2) silinemez.'"),
			NonReferenceValues.Count(), TableRowsCount));
 	ElsIf NonReferenceValues.Count() > 1 Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xóa giá trị được chọn (%1 c.).';
				|ru = 'Нельзя удалить выбранные значения (%1 шт.).';
				|en = 'Cannot delete the selected values (%1).'; fa = 'Cannot delete the selected values (%1).';
				|it = 'Нельзя удалить выбранные значения (%1 шт.).';
				|pl = 'Cannot delete the selected values (%1).';
				|tr = 'Seçilen değerler (%1 ad) silinemez.'"),
			NonReferenceValues.Count()));
	EndIf;
		
	StandardSubsystemsClient.ExpandTreeNodes(ThisObject, "NotDeletedItemsUsageInstances", "*", True);
	SetCurrentRowOfNotDeletedItemsUsageInstances(CurrentTreeRow);

EndProcedure

&AtClient
Procedure SetReplaceWith(Command)

	CurrentData = Items.NotDeletedItemsUsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Status(NStr("vi = 'Không có hành động nào có thể được chỉ định cho hàng đã chọn.';
					|ru = 'Для выбранной строки нельзя указать действие.';
					|en = 'Cannot specify an action for the selected row.'; fa = 'Cannot specify an action for the selected row.';
					|it = 'Per la riga selezionata non deve essere indicata alcuna azione.';
					|pl = 'Dla wybranego wiersza nie można wskazać działania.';
					|tr = 'Seçili satır için eylem belirtememek gerekiyor.'"),,, PictureLib.DialogExclamation);
		Return;
	EndIf;
	
	If CurrentData.MainReason Then
		FormPath = NameOfMetadataObjects(CurrentData.ItemToDeleteRef) + ".ChoiceForm";
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		OpenForm(FormPath, FormParameters, Items.NotDeletedItemsUsageInstances,,,,, FormWindowOpeningMode.LockOwnerWindow);
	Else
		Status(NStr("vi = 'Không có hành động nào có thể được chỉ định cho hàng đã chọn.';
					|ru = 'Для выбранной строки нельзя указать действие.';
					|en = 'Cannot specify an action for the selected row.'; fa = 'Cannot specify an action for the selected row.';
					|it = 'Per la riga selezionata non deve essere indicata alcuna azione.';
					|pl = 'Dla wybranego wiersza nie można wskazać działania.';
					|tr = 'Seçili satır için eylem belirtememek gerekiyor.'"),,, PictureLib.DialogExclamation);
	EndIf;
	
EndProcedure

&AtClient
Procedure Customize(Command)
	ClosingNotification1 = New CallbackDescription("CustomizeContinued", ThisObject);
	
	FormParameters = New Structure("SettingsAddress", MarkedObjectsDeletionSettings());
	OpenForm("DataProcessor.MarkedObjectsDeletion.Form.ObjectsDeletionSettings", FormParameters, ThisObject, , , ,
		ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtServer
Function MarkedObjectsDeletionSettings()
	Settings = New Structure;
	Settings.Insert("DeletionMode", DeletionMode);
	Settings.Insert("SelectedAttributes", AdditionalAttributesOfItemsMarkedForDeletion.Unload());
	Return PutToTempStorage(Settings, UUID);
EndFunction

&AtClient
Procedure CustomizeContinued(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	ObjectsMarkedForDeletionUpdateRequired = CustomizeContinuedServer(Result);
	If ObjectsMarkedForDeletionUpdateRequired Then
		RunJob(FormJobs().MarkedObjectsSearch);
	EndIf;
EndProcedure

&AtServer
Function CustomizeContinuedServer(SettingsAddress)
	Settings = GetFromTempStorage(SettingsAddress);
	DeleteFromTempStorage(SettingsAddress);
	DeletionMode = Settings.DeletionMode;

	SettingsChanged = SettingsChanged(Settings.SelectedAttributes);

	CurrentAdditionalAttributesCount = MarkedObjectsDeletionInternal.AdditionalAttributesNumber(
		AdditionalAttributesOfItemsMarkedForDeletion.Unload());
	NewAdditionalAttributesNumber = MarkedObjectsDeletionInternal.AdditionalAttributesNumber(Settings.SelectedAttributes);
	CurrentGeneratedAttributesCount = CurrentGeneratedAttributesCount(CurrentAdditionalAttributesCount, NewAdditionalAttributesNumber);

	If CurrentGeneratedAttributesCount < NewAdditionalAttributesNumber Then
		AttributesToAddNumber = NewAdditionalAttributesNumber - CurrentGeneratedAttributesCount;
		AddAdditionalAttributes(CurrentGeneratedAttributesCount + 1, AttributesToAddNumber);
	EndIf;
	
	If CurrentAdditionalAttributesCount < CurrentGeneratedAttributesCount 
		And CurrentAdditionalAttributesCount < NewAdditionalAttributesNumber Then
		
		SetAdditionalAttributesVisibility(CurrentAdditionalAttributesCount+1, CurrentGeneratedAttributesCount, True);
	EndIf;

	If CurrentAdditionalAttributesCount > NewAdditionalAttributesNumber Then
		SetAdditionalAttributesVisibility(NewAdditionalAttributesNumber+1,
			CurrentAdditionalAttributesCount, False);
	EndIf;
	
	AdditionalAttributesOfItemsMarkedForDeletion.Load(Settings.SelectedAttributes);
	
	SetConditionalAppearance();
	
	Return NewAdditionalAttributesNumber > CurrentAdditionalAttributesCount Or SettingsChanged;
EndFunction

&AtClient
Procedure DeleteSelectedItems(Command)
	
	InformationAboutTheSelectedObjects = SelectedObjectsCount();
	SelectedCountTotal = InformationAboutTheSelectedObjects.SelectedCount;
	If SelectedCountTotal = 0 Then
		QueryText = NStr("vi = 'Cần chọn ít nhất một phần tử để xóa.';
						|ru = 'Необходимо выбрать хотя бы один элемент для удаления.';
						|en = 'Select at least one item to be deleted.'; fa = 'Select at least one item to be deleted.';
						|it = 'È necessario selezionare almeno un elemento per l''eliminazione.';
						|pl = 'Należy wybrać co najmniej jeden element do usunięcia.';
						|tr = 'Silmek için en az bir öğe seçmelisiniz.'");
		ShowMessageBox(, QueryText);
		Return;
	ElsIf SelectedCountTotal = 1 Then
		QueryText = NStr("vi = 'Xóa phần tử đã đặt dấu xóa?';
						|ru = 'Удалить элемент, помеченный на удаление?';
						|en = 'Delete the item marked for deletion?'; fa = 'Delete the item marked for deletion?';
						|it = 'Eliminare l''elemento contrassegnato per l''eliminazione?';
						|pl = 'Usunąć element, zaznaczony do usunięcia?';
						|tr = 'Silinmek üzere işaretlenen öğe silinsin mi?'");
	ElsIf SelectedCountTotal = InformationAboutTheSelectedObjects.TotalCount1 Then
		QueryText = NStr("vi = 'Xóa tất cả phần tử đã đặt dấu xóa?';
						|ru = 'Удалить все элементы, помеченные на удаление?';
						|en = 'Delete all items marked for deletion?'; fa = 'Delete all items marked for deletion?';
						|it = 'Eliminare tutti gli elementi contrassegnati per l''eliminazione?';
						|pl = 'Usunąć wszystkie elementy, zaznaczone do usunięcia?';
						|tr = 'Silinmek üzere işaretlenen tüm öğeler silinsin mi?'");
	Else
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Xóa các phần tử đã đặt dấu xóa (%1)?';
				|ru = 'Удалить элементы, помеченные на удаление (%1)?';
				|en = 'Delete the items marked for deletion (%1)?'; fa = 'Delete the items marked for deletion (%1)?';
				|it = 'Eliminare gli elementi contrassegnati per l''eliminazione (%1)?';
				|pl = 'Usunąć elementy, zaznaczone do usunięcia (%1)?';
				|tr = 'Silinmek üzere işaretlenen öğeler silinsin mi (%1)?'"),
			SelectedCountTotal);
	EndIf;
	
	NotificationConfirmationDeleteAll = New CallbackDescription("OnConfirmationDelete",
		ThisObject, InformationAboutTheSelectedObjects);
	ShowQueryBox(NotificationConfirmationDeleteAll, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ConfigureFilter(Command)
	ObjectsToSelectCollection = New ValueList();
	
	ObjectsToSelectCollection.Add("Catalogs");
	ObjectsToSelectCollection.Add("Documents");
	ObjectsToSelectCollection.Add("ChartsOfCharacteristicTypes");
	ObjectsToSelectCollection.Add("ChartsOfAccounts");
	ObjectsToSelectCollection.Add("ChartsOfAccounts");
	ObjectsToSelectCollection.Add("ChartsOfCalculationTypes");
	ObjectsToSelectCollection.Add("BusinessProcesses");
	ObjectsToSelectCollection.Add("Tasks");
	
	FormParameters = New Structure;
	FormParameters.Insert("MetadataObjectsToSelectCollection", ObjectsToSelectCollection);
	FormParameters.Insert("SearchAreas", MetadataFilter);
	FormParameters.Insert("SubsystemsWithCIOnly", True);
	
	ClosingNotification1 = New CallbackDescription("ConfigureFilterCompletion", ThisObject);
	OpenForm("DataProcessor.MarkedObjectsDeletion.Form.SelectMetadataObjectsBySubsystems", FormParameters, ThisObject, , , , ClosingNotification1,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ExpandRowsOfMarkedObjectsTree(Command)
	StandardSubsystemsClient.ExpandTreeNodes(ThisObject, "MarkedForDeletionItemsTree");
EndProcedure

&AtClient
Procedure CollapseMarkedObjectTreeRows(Command)
	AllRows = Items.MarkedForDeletionItemsTree;
	For Each RowData In MarkedForDeletionItemsTree.GetItems() Do 
		AllRows.Collapse(RowData.GetID());
	EndDo;
EndProcedure

&AtClient
Procedure SetClearDeletionMark(Command)
	
	ReferencesToProcess = New Array;
	ViewOfTheLastSelectedOne = "";
	TheNumberOfItemsWithTheUncheckedLabel = 0;
	For Each SelectedRow In Items.NotTrash.SelectedRows Do
		Data = Items.NotTrash.RowData(SelectedRow);
		If TypeOf(Data.ItemToDeleteRef) <> Type("String") Then
			ReferencesToProcess.Add(Data.ItemToDeleteRef);
			ViewOfTheLastSelectedOne = Data.Presentation;
		EndIf;
		
		If ItemsWithoutDeletionMark.FindByValue(Data.ItemToDeleteRef) <> Undefined Then
			TheNumberOfItemsWithTheUncheckedLabel = TheNumberOfItemsWithTheUncheckedLabel + 1;
		EndIf;
	EndDo;
	
	SetATag = ReferencesToProcess.Count() = TheNumberOfItemsWithTheUncheckedLabel
							And TheNumberOfItemsWithTheUncheckedLabel <> 0;
	
	Handler = New CallbackDescription("SetClearDeletionMarkContinued", ThisObject, ReferencesToProcess);
	If ReferencesToProcess.Count() = 1 Then
		If SetATag Then
			QueryText = NStr("vi = 'Đặt dấu xóa ""%1""?';
							|ru = 'Пометить ""%1"" на удаление?';
							|en = 'Mark ""%1"" for deletion?'; fa = 'Mark ""%1"" for deletion?';
							|it = 'Contrassegnare ""%1"" per cancellazione?';
							|pl = 'Zaznaczyć ""%1"" do usunięcia?';
							|tr = '""%1"" silinmek üzere işaretlensin mi?'");
		Else
			QueryText = NStr("vi = 'Bỏ dấu xóa ""%1""?';
							|ru = 'Снять с ""%1"" пометку на удаление?';
							|en = 'Clear the deletion mark from ""%1""?'; fa = 'Clear the deletion mark from ""%1""?';
							|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
							|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
							|tr = '""%1"" için silme işareti kaldırılsın mı?'");
		EndIf;
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, ViewOfTheLastSelectedOne);
	Else
		If SetATag Then
			QueryText = NStr("vi = 'Đánh dấu xóa phần tử (%1) đã chọn?';
							|ru = 'Пометить выделенные объекты (%1) на удаление?';
							|en = 'Mark the selected objects (%1) for deletion?'; fa = 'Mark the selected objects (%1) for deletion?';
							|it = 'Contrassegnare gli oggetti selezionati (%1) per la cancellazione?';
							|pl = 'Zaznaczyć wybrane obiekty (%1) do usunięcia?';
							|tr = 'Işaretlenmiş nesneler (%1) silinecek olarak işaretlensin mi?'");
		Else
			QueryText = NStr("vi = 'Bỏ dấu xóa các đối tượng(%1) đã chọn?';
							|ru = 'Снять с выделенных объектов (%1) пометку на удаление?';
							|en = 'Clear the deletion mark from the selected objects (%1)?'; fa = 'Clear the deletion mark from the selected objects (%1)?';
							|it = 'Togliere il contrassegno per l''eliminazione dagli oggetti (%1) selezionati?';
							|pl = 'Usunąć z wybranych obiektów (%1) zaznaczenie do usunięcia?';
							|tr = 'Seçilmiş nesneler (%1) için silme işareti kaldırılsın mı?'");
		EndIf;
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, Format(ReferencesToProcess.Count(), "NZ=0; NG="));
	EndIf;
	
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo, 60, DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure SetClearDeletionMarkContinued(Result, ReferencesToProcess) Export

	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Changes = Undefined;
	Try
		Changes = SetUncheckDeleteOnTheServer(ReferencesToProcess);
	Except
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorText = NStr("vi = 'Không thể thay đổi dấu xóa do nguyên nhân:';
						|ru = 'Не удалось изменить пометку удаления по причине:';
						|en = 'Cannot change the deletion mark due to:'; fa = 'Cannot change the deletion mark due to:';
						|it = 'Не удалось изменить пометку удаления по причине:';
						|pl = 'Cannot change the deletion mark due to:';
						|tr = 'Silme işareti şu sebeple değiştirilemedi:'")
			+ Chars.LF + ErrorText;
		ShowMessageBox(, ErrorText);
	EndTry;
	
	If Changes <> Undefined Then
		StandardSubsystemsClient.NotifyFormsAboutChange(Changes);
	EndIf;	
	StandardSubsystemsClient.ExpandTreeNodes(ThisObject, "NotTrash", "*", True);	

EndProcedure

&AtServer
Function SetUncheckDeleteOnTheServer(References)
	
	Try
		Changes = MarkedObjectsDeletionInternal.RemovePutATickRemoval(References);
	Except
		WriteLogEvent(
			NStr("vi = 'Đã đánh dấu xóa. Đang đánh dấu / bỏ đánh dấu xóa';
				|ru = 'Удаление помеченных.Установка / снятие пометки удаления';
				|en = 'Delete marked objects.Toggle deletion mark'; fa = 'Delete marked objects.Toggle deletion mark';
				|it = 'Eliminazione dei contrassegnati. Imposta/rimuovi contrassegno di eliminazione';
				|pl = 'Usunięcie zaznaczonych.Ustawienie / usunięcie zaznaczenia do usunięcia';
				|tr = 'İşaretlilerin silinmesi. Silmeyi ayarlama/işareti kaldırma'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	Result = New Array;
	NotDeletedItemsTree = FormAttributeToValue("NotTrash");
	TypesInformation = MarkedObjectsDeletionInternal.TypesInformation(Changes.UnloadColumn("Ref"));

	For Each Update In Changes Do
		
		TypeInformation = TypesInformation[TypeOf(Update.Ref)]; // See MarkedObjectsDeletionInternal.TypeInformation
		MetadataStrings = NotDeletedItemsTree.Rows.FindRows(
			New Structure("ItemToDeleteRef", TypeInformation.FullName))[0].Rows;
		Data = MetadataStrings.FindRows(New Structure("ItemToDeleteRef", Update.Ref))[0];
		
		Data.PictureNumber = MarkedObjectsDeletionInternal.PictureNumber(Update.Ref,
			TypeInformation.Referential, TypeInformation.Kind,
			?(Update.DeletionMarkNewValue = True, "Removed", Undefined));
		Result.Add(Update.Ref);

		If Not Update.DeletionMarkNewValue Then
			ItemsWithoutDeletionMark.Add(Update.Ref);
		Else
			ListItem = ItemsWithoutDeletionMark.FindByValue(Update.Ref);
			If ListItem <> Undefined Then
				ItemsWithoutDeletionMark.Delete(ListItem);
			EndIf;
		EndIf;

	EndDo;

	ValueToFormAttribute(NotDeletedItemsTree, "NotTrash");	
	Return StandardSubsystemsServer.PrepareFormChangeNotification(Result);
	
EndFunction

&AtClient
Procedure ShowTechnologicalData(Command)
	Items.ShowTechnologicalData.Check = Not Items.ShowTechnologicalData.Check;
	AddJob(FormJobs().MarkedObjectsSearch);
	RunJob();
EndProcedure

#EndRegion

#Region Private

#Region FormStates

&AtServer
Procedure SetObjectsMarkedForDeletionSelectionState()
	Items.CommandBarForm.Enabled = True;
	Items.RunningState.Visible = False;
	Items.InformationPages.Enabled = True;
	
	Items.InformationPages.CurrentPage = Items.ObjectsToProcessChoicePage;
	Items.StatePresentationPages.Visible = False;
	Items.InformationPages.ReadOnly = False;
	Items.ActiveAfterSearchMarkedObjectsGroup.Enabled = MarkedForDeletionItemsTree.GetItems().Count() > 0;
	
	Items.CommandBarMarkedObjectsSearch.Visible = True;
	Items.CommandBarErrorsProcessing.Visible = False;
	
	Items.SearchFilterSettingsGroup.Enabled = True;
	Items.ProgressPresentation.Visible = False;
	Items.MarkedForDeletionItemsTreeDeleteSelectedItems.DefaultButton = True;
	Items.SearchStringForDeletion.Visible = True;
EndProcedure

&AtServer
Procedure SetObjectsMarkedForDeletionSelectionStateWithStatePanel()
	Items.CommandBarForm.Enabled = True;
	Items.RunningState.Visible = True;
	Items.InformationPages.Enabled = True;
	
	Items.InformationPages.CurrentPage = Items.ObjectsToProcessChoicePage;
	Items.StatePresentationPages.Visible = True;
	Items.InformationPages.ReadOnly = False;
	
	Items.CommandBarMarkedObjectsSearch.Visible = True;
	Items.CommandBarErrorsProcessing.Visible = False;
	
	Items.SearchFilterSettingsGroup.Enabled = True;
	Items.ProgressPresentation.Visible = False;
	Items.MarkedForDeletionItemsTreeDeleteSelectedItems.DefaultButton = True;
	Items.ActiveAfterSearchMarkedObjectsGroup.Enabled = MarkedForDeletionItemsTree.GetItems().Count() > 0;
	Items.SearchStringForDeletion.Visible = False;
EndProcedure

&AtServer
Procedure SetStateUnsuccessfulDeletion()
	Items.CommandBarForm.Enabled = True;
	Items.RunningState.Visible = False;
	Items.InformationPages.Enabled = True;
	Items.InformationPages.Visible = True;
	
	Items.InformationPages.CurrentPage = Items.DeletionFailureReasonsPage;
	Items.StatePresentationPages.Visible = False;
	Items.InformationPages.ReadOnly = False;
	Items.ActiveAfterSearchMarkedObjectsGroup.ReadOnly = False;
	
	Items.CommandBarMarkedObjectsSearch.Visible = False;
	Items.CommandBarErrorsProcessing.Visible = True;
	
	Items.SearchFilterSettingsGroup.Enabled = False;
	Items.ProgressPresentation.Visible = False;
	Items.CommandBarForm.Visible = True;
	Items.ExecuteActionsAndDelete.DefaultButton = True;
	Items.DetailsRef.Visible = False;
	Items.SearchStringForDeletion.Visible = False;
EndProcedure

&AtServer
Procedure SetStateUnsuccessfulDeletionWithStatePanel()
	Items.CommandBarForm.Enabled = True;
	Items.RunningState.Visible = True;
	Items.InformationPages.Enabled = True;
	Items.InformationPages.Visible = True;
	
	Items.InformationPages.CurrentPage = Items.DeletionFailureReasonsPage;
	Items.StatePresentationPages.Visible = True;
	Items.InformationPages.ReadOnly = False;
	Items.ActiveAfterSearchMarkedObjectsGroup.ReadOnly = False;
	
	Items.CommandBarMarkedObjectsSearch.Visible = False;
	Items.CommandBarErrorsProcessing.Visible = True;
	
	Items.SearchFilterSettingsGroup.Enabled = False;
	Items.ProgressPresentation.Visible = False;
	Items.CommandBarForm.Visible = True;
	Items.ExecuteActionsAndDelete.DefaultButton = True;
	
	If IsMobileClient Then
		Items.NotDeletedItemsGroup.Visible = False;
	EndIf;
	Items.DetailsRef.Visible = False;
	Items.SearchStringForDeletion.Visible = False;
EndProcedure

#EndRegion

// Parameters:
//   Ref - AnyRef
// Returns:
//   String
//
&AtServerNoContext
Function NameOfMetadataObjects(Ref)
	Return Ref.Metadata().FullName();
EndFunction

&AtClient
Procedure UpdateTheTreeMarkedForDeletion()
	
	UpdateTheTreeMarkedForDeletionOnTheServer();
	
EndProcedure

&AtServer
Procedure UpdateTheTreeMarkedForDeletionOnTheServer()
	
	MarkedForDeletion = FormAttributeToValue("MarkedForDeletionItemsTree");
	For Each ListItem In ItemsWithoutDeletionMark Do
	
		MetadataKind = MarkedForDeletion.Rows.FindRows(
							New Structure("ItemToDeleteRef", Upper(NameOfMetadataObjects(ListItem.Value))))[0];
		LinesToDelete = MetadataKind.Rows.FindRows(
							New Structure("ItemToDeleteRef", ListItem.Value));
		For Each TreeRow In LinesToDelete Do
			MetadataKind.Rows.Delete(TreeRow);
		EndDo;
		
		If MetadataKind.Rows.Count() = 0 Then
			MarkedForDeletion.Rows.Delete(MetadataKind);
		EndIf;
	
	EndDo;
	
	For Each NodeOfType In MarkedForDeletion.Rows Do
		NodeElements = NodeOfType.Rows;
		NodeOfType.Check = ItemMarkValues(NodeElements);
		If NodeOfType.Rows.Count() > 0 Then
			NodeMetadataObject = NodeOfType.Rows[0].ItemToDeleteRef.Metadata();
			NodeOfType.Presentation = Common.ListPresentation(NodeMetadataObject) + " (" + NodeOfType.Rows.Count() + ")";
		EndIf;
	EndDo;
	
	ValueToFormAttribute(MarkedForDeletion, "MarkedForDeletionItemsTree");
	ItemsWithoutDeletionMark.Clear();
	
EndProcedure

#Region Settings

&AtServer
Function SettingsChanged(SelectedAttributes)
	Result = False;
	
	ComparisonTable = MarkedObjectsDeletionInternal.TablesMerge(
		SelectedAttributes,
		AdditionalAttributesOfItemsMarkedForDeletion.Unload());
		
	ComparisonTable.Columns.Add("Number", New TypeDescription("Number"));
	ComparisonTable.FillValues(1,"Number");
	ComparisonTable.GroupBy("Metadata, Attribute", "Number");
	For Each Item In ComparisonTable Do
		If Item.Number <> 2 Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;		
EndFunction

&AtServer
Function CurrentGeneratedAttributesCount(CurrentAdditionalAttributesCount, NewAdditionalAttributesNumber)
	Result = CurrentAdditionalAttributesCount;
	
	For Cnt = CurrentAdditionalAttributesCount + 1 To NewAdditionalAttributesNumber Do
		If Items.Find("MarkedForDeletionItemsTreeAttribute"+Cnt) <> Undefined Then
			Result = Cnt;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Procedure SetAdditionalAttributesVisibility(InitialNumber, EndNumber, Visible)
	For Cnt = InitialNumber To EndNumber Do
		Items["MarkedForDeletionItemsTreeAttribute" + Cnt].Visible = Visible;
	EndDo;
EndProcedure

&AtServer
Procedure AddAdditionalAttributes(InitialNumber, AttributesToAddNumber)
	AttributesToBeAdded = New Array;
	LastDigitInAttributeName = InitialNumber+AttributesToAddNumber-1;
	For Cnt = InitialNumber To LastDigitInAttributeName Do
		AttributesToBeAdded.Add(New FormAttribute("Attribute"+Cnt, New TypeDescription(), "MarkedForDeletionItemsTree"));
	EndDo;
	ChangeAttributes(AttributesToBeAdded);
	
	For Cnt = InitialNumber To LastDigitInAttributeName Do
		FormItem = Items.Add("MarkedForDeletionItemsTreeAttribute"+Cnt, Type("FormField"), Items.MarkedForDeletionItemsTree);
		FormItem.Type = FormFieldType.InputField;
		FormItem.DataPath = "MarkedForDeletionItemsTree.Attribute"+Cnt;
	EndDo;
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Function SelectedObjectsCount()
	Result = New Structure;
	Result.Insert("SelectedCount", 0);
	Result.Insert("TotalCount1", 0);
	
	For Each GroupRow In MarkedForDeletionItemsTree.GetItems() Do
		
		For Each ElementString In GroupRow.GetItems() Do
			If ElementString.Check = 1 Then
				Result.SelectedCount = Result.SelectedCount + 1;
			EndIf;
			Result.TotalCount1 = Result.TotalCount1 + 1;
		EndDo;
		
	EndDo;
	
	// All metadata objects are never selected.
	If MetadataFilter.Count() <> 0 Then
		Result.TotalCount1 = -1;
	EndIf;
	
	Return Result;
EndFunction

&AtClient
Function CurrentRowOfNotDeletedItemsUsageInstances()

	CurrentData = Items.NotDeletedItemsUsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Return Undefined;
	EndIf;
	Return CurrentData.FoundItemReference;
	
EndFunction

&AtClient
Procedure SetCurrentRowOfNotDeletedItemsUsageInstances(Value)

	TreeItems = NotDeletedItemsUsageInstances.GetItems();
	If Value = Undefined Or TreeItems.Count() = 0 Then
		Return;
	EndIf;
	TreeRowID = 0;
	CommonClientServer.GetTreeRowIDByFieldValue("FoundItemReference",
		TreeRowID, TreeItems, Value, False);
	Items.NotDeletedItemsUsageInstances.CurrentRow = TreeRowID;
EndProcedure

&AtServer
Function SetReplaceOnServer(ItemToDeleteRef, ValueSelected)
	
	If ValueSelected = Undefined Then
		Return "";
	EndIf;

	SelectedTableRows = New Array;
	For Each TableRowID_ In Items.NotDeletedItemsUsageInstances.SelectedRows Do

		SelectedRow = NotDeletedItemsUsageInstances.FindByID(TableRowID_);
		If SelectedRow.ItemToDeleteRef <> ItemToDeleteRef Then
			Continue;
		EndIf;
		
		If SelectedRow.MainReason Then
			SelectedTableRows.Add(TableRowID_);
		EndIf;
	EndDo;
	
	Return SetActionForUsageInstances(SelectedTableRows, "ReplaceRef", ValueSelected);

EndFunction

&AtServer
Function SetActionForUsageInstances(Val TableRowsIDs, Val Action, Val Parameter = Undefined)
	
	ActionPresentation = ?(Parameter = Undefined,
		NotDeletedItemsUsageInstancesActions.FindByValue(Action).Presentation,
		"");
	MessageText = "";
	ValueTable = ActionsTable();
	Success = False;

	For Each TableRowID_ In TableRowsIDs Do
		UsageInstance1 = NotDeletedItemsUsageInstances.FindByID(TableRowID_);
		If Parameter <> Undefined Then
			ActionPresentation = ReplaceWithCommandPresentation(UsageInstance1, Parameter);
		EndIf;
		
		If Action = "Delete" Then

			Filter = New Structure("FoundItemReference", UsageInstance1.FoundItemReference);
			For Each ActionToDelete In ValueTable.FindRows(Filter) Do
				ValueTable.Delete(ActionToDelete);
			EndDo;
			
			NewAction = ValueTable.Add();
			NewAction.Action = Action;
			NewAction.FoundItemReference = UsageInstance1.FoundItemReference;
			NewAction.ActionParameter = Parameter;
			NewAction.Source = UsageInstance1.ItemToDeleteRef;
			Success = True;
			
		ElsIf Action = "ReplaceRef" Then

			Filter = New Structure("FoundItemReference", UsageInstance1.FoundItemReference);
			For Each ActionToDelete In ValueTable.FindRows(Filter) Do
				ValueTable.Delete(ActionToDelete);
			EndDo;
			
			Filter = New Structure("Source, Action", UsageInstance1.ItemToDeleteRef, "ReplaceRef");
			ActionsToChange = ValueTable.FindRows(Filter);	
			For Each ModifiableAction In ActionsToChange Do
				ModifiableAction.ActionParameter = Parameter;
			EndDo;
			
			If ActionsToChange.Count() = 0 Then
				NewAction = ValueTable.Add();
				NewAction.Action = Action;
				NewAction.FoundItemReference = UsageInstance1.FoundItemReference;
				NewAction.ActionParameter = Parameter;
				NewAction.Source = UsageInstance1.ItemToDeleteRef;
			EndIf;
			Success = True;
			
		Else
			If IsBlankString(MessageText) Then
				MessageText = NStr("vi = 'Đối với nơi sử dụng %1 không thể chọn hành động %2.';
									|ru = 'Для места использования %1 нельзя выбрать действие %2.';
									|en = 'Object %1 does not support action ""%2"".'; fa = 'Object %1 does not support action ""%2"".';
									|it = 'Для места использования %1 нельзя выбрать действие %2.';
									|pl = 'Dla miejsca używania %1 nie można wybrać działania %2.';
									|tr = 'Kullanım yeri için%1 bir işlem seçemezsiniz%2.'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, 
					UsageInstance1.FoundItemReference,
					UsageInstance1.ActionPresentation);
			EndIf;
			Continue;
		EndIf;

		UsageInstance1.Action = Action;
		UsageInstance1.ActionPresentation = ActionPresentation;
			
	EndDo;

	If Success Then // If at least one action was modified.
		
		If Action = "ReplaceRef" Then
			// Replace the reference in all objects except the objects marked for deletion.
			Filter = New Structure("FoundItemReference");
			For Each UsageInstance1 In NotDeletedItemsUsageInstances.GetItems() Do
				Filter.FoundItemReference = UsageInstance1.FoundItemReference;
				CurrentAction1 = ValueTable.FindRows(Filter);
				
				If CurrentAction1.Count() = 0 Then
					NewAction = ValueTable.Add();
					NewAction.Action = Action;
					NewAction.FoundItemReference = UsageInstance1.FoundItemReference;
					NewAction.ActionParameter = Parameter;
					NewAction.Source = UsageInstance1.ItemToDeleteRef;
				EndIf;
			EndDo;
		EndIf;
		
		ValueToFormAttribute(ValueTable, "ActionsTable");
		FillNotDeletedObjectsUsageInstances(ValueTable);
	EndIf;
	Return MessageText;
	
EndFunction

&AtServer
Function SetActionForUsageInstance(Val TableRowID_, Val Action, Val Parameter = Undefined)

	Return SetActionForUsageInstances(CommonClientServer.ValueInArray(TableRowID_),
		Action, Parameter);
	
EndFunction

// Returns:
//   ValueTable
//
&AtServer
Function ActionsTable()
	ValueTable = FormAttributeToValue("ActionsTable", Type("ValueTable")); // ValueTable
	ValueTable.Indexes.Add("FoundItemReference");
	ValueTable.Indexes.Add("FoundItemReference, Action");
	ValueTable.Indexes.Add("Source, Action");
	Return ValueTable;
EndFunction

&AtClient
Procedure OnConfirmationDelete(Result, AdditionalParameters) Export
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	ActionParameter = ?(AdditionalParameters.TotalCount1 = AdditionalParameters.SelectedCount,
		"CompleteRemoval", "");
	AddJob(FormJobs().DeleteMarkedObjects, ActionParameter);
	RunJob();
EndProcedure

&AtClient
Procedure ToOpenTheFormCompleteTheUserExperience()
	
	If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
		Notification = New CallbackDescription("AfterSettingTheExclusiveMode", ThisObject);
		ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
		FormParameters = ModuleIBConnectionsClient.ExclusiveModeSetErrorFormOpenParameters();
		FormParameters.Title = NStr("vi = 'Không thể xóa các đối tượng có đặt dấu';
									|ru = 'Не удалось удалить помеченные объекты';
									|en = 'Cannot delete marked objects'; fa = 'Cannot delete marked objects';
									|it = 'Non è stato possibile eliminare gli oggetti contrassegnati';
									|pl = 'Nie udało się usunąć zaznaczonych obiektów';
									|tr = 'İşaretli nesneler silinemedi'");
		FormParameters.ErrorMessageText = NStr("vi = 'Không thể xóa các đối tượng đã đánh dấu vì có người sử dụng khác đang làm việc trong ứng dụng:';
												|ru = 'Невозможно выполнить удаление помеченных объектов, т.к. в приложении работают другие пользователи:';
												|en = 'Cannot delete the marked objects because other users are logged in:'; fa = 'Cannot delete the marked objects because other users are logged in:';
												|it = 'Невозможно выполнить удаление помеченных объектов, т.к. в приложении работают другие пользователи:';
												|pl = 'Cannot delete the marked objects because other users are logged in:';
												|tr = 'İşaretli nesneleri silmek imkansızdır çünkü Uygulamada diğer kullanıcılar çalışmaktadır:'");
		FormParameters.ErrorTextExitFailed = NStr("vi = 'Không thể xóa các đối tượng được đánh dấu vì không thể kết thúc công việc của người sử dụng:';
													|ru = 'Невозможно выполнить удаление помеченных объектов, т.к. не удалось завершить работу пользователей:';
													|en = 'Cannot delete the marked objects because the following users are still logged in:'; fa = 'Cannot delete the marked objects because the following users are still logged in:';
													|it = 'Impossibile eseguire la cancellazione degli elementi selezionati, poiché non è stato possibile terminare il lavoro degli utenti:';
													|pl = 'Nie można usunąć oznaczonych obiektów, ponieważ nie udało się zamknąć użytkowników:';
													|tr = 'İşaretli nesneler silinemiyor çünkü Kullanıcıların işi kapatılamadı:'");
		FormParameters.ShouldCloseAllSessionsButCurrent = True;
		FormParameters.LoginMessage = NStr("vi = 'Tạm thời, không thể làm việc với ứng dụng để xóa các đối tượng bị đặt dấu xóa.';
											|ru = 'Работа с приложением временно недоступна для удаления помеченных объектов.';
											|en = 'The app is temporarily unavailable while deleting objects marked for deletion.'; fa = 'The app is temporarily unavailable while deleting objects marked for deletion.';
											|it = 'Работа с приложением временно недоступна для удаления помеченных объектов.';
											|pl = 'The app is temporarily unavailable while deleting objects marked for deletion.';
											|tr = 'Uygulama, işaretli nesnelerin silinmesi için geçici olarak kullanılamıyor.'");
		FormParameters.BlockingPeriod = 60;
		
		ModuleIBConnectionsClient.OnOpenExclusiveModeSetErrorForm(Notification, FormParameters);
	Else
		StandardSubsystemsClient.OpenActiveUserList();
	EndIf;

EndProcedure

&AtClient
Procedure AfterSettingTheExclusiveMode(Result, AdditionalParameters) Export
	If Result = False Then // The exclusive mode is set.
		AddJob(FormJobs().DeleteMarkedObjects);
		RunJob();
	EndIf;
EndProcedure

#EndRegion

#Region FormEvents

&AtServerNoContext
Function SelectionOfMetadataOnlyExisting(MetadataFilter)
	Result = New ValueList;
	
	For Each MetadataIsSelected In MetadataFilter Do
		If Common.MetadataObjectByFullName(MetadataIsSelected.Value) = Undefined Then
			Continue;
		EndIf;     
		
		Result.Add(MetadataIsSelected.Value, MetadataIsSelected.Presentation);
	EndDo;                     
	
	Return Result;
EndFunction

&AtServer
Procedure SetPassedMetadataFilter()

	ActiveFilter = New ValueList;
	For Each Item In Parameters.MetadataFilter Do
		ActiveFilter.Add(Item.Value, Common.MetadataObjectByFullName(Item.Value).Presentation());
	EndDo;
	SetMetadataFilter(ThisObject, ActiveFilter);
	Parameters.MetadataFilter = ActiveFilter;

EndProcedure

&AtServer
Procedure ConfigureFormToWorkAsService()

	DeleteOnOpen = True;
	Items.InformationPages.Visible = False;
	Items.MarkedForDeletionItemsTreeConfigure.Visible = False;
	Items.Back.Visible = False;
	Items.SearchFilterSettingsGroup.Visible = False;
	Items.CommandBarForm.Visible = False;
	Items.StatePresentationPages.Visible = True;
	AutoTitle = False;
	Title = "";

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	ColorHyperlink = Metadata.StyleItems.HyperlinkColor.Value;
	InactiveLabelColor = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	ConditionalAppearanceItems.Clear();

	AppearanceItem = ConditionalAppearanceItems.Add();

	AndGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FilterDesignFeatures = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.LeftValue = New DataCompositionField("NotDeletedItemsUsageInstances.Action");
	FilterDesignFeatures.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterDesignFeatures = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.LeftValue = New DataCompositionField("NotDeletedItemsUsageInstances.MainReason");
	FilterDesignFeatures.ComparisonType = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Hãy chọn thao tác';
															|ru = 'Выберите действие';
															|en = 'Select an action'; fa = 'Select an action';
															|it = 'Selezionare un''azione';
															|pl = 'Wybierz czynność';
															|tr = 'Eylem seçin'"));
	AppearanceItem.Appearance.SetParameterValue("Font", Metadata.StyleItems.ActionInListColumnFont.Value);

	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("NotDeletedItemRelationsAction");
	
	// Hyperlink color.
	AppearanceItem = ConditionalAppearanceItems.Add();
	FilterDesignFeatures = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.LeftValue = New DataCompositionField("NotDeletedItemsUsageInstances.MainReason");
	FilterDesignFeatures.ComparisonType = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", ColorHyperlink);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("NotDeletedItemRelationsAction");
	
	// Column titles.
	SetConditionalAppearanceOfAdditionalAttributes(ConditionalAppearanceItems, InactiveLabelColor);
	
	// Action availability.
	AppearanceItem = ConditionalAppearanceItems.Add();
	FilterDesignFeatures = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.LeftValue = New DataCompositionField("NotDeletedItemsUsageInstances.MainReason");
	FilterDesignFeatures.ComparisonType = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("NotDeletedItemRelationsAction");
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfAdditionalAttributes(ConditionalAppearanceItems, InactiveLabelColor)
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	FilterDesignFeatures = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.LeftValue = New DataCompositionField("MarkedForDeletionItemsTree.IsMetadataObjectDetails");
	FilterDesignFeatures.ComparisonType = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", InactiveLabelColor);
	
	AdditionalAttributesNumber = MarkedObjectsDeletionInternal.AdditionalAttributesNumber(
		AdditionalAttributesOfItemsMarkedForDeletion.Unload());
	
	For Cnt = 1 To AdditionalAttributesNumber Do
		AppearanceField = AppearanceItem.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField("MarkedForDeletionItemsTreeAttribute" + Cnt);
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Procedure SetUsageInstancesActionsList(Form)
	Form.NotDeletedItemsUsageInstancesActions.Clear();
	Form.NotDeletedItemsUsageInstancesActions.Add("Delete", NStr("vi = 'Xóa bỏ';
																|ru = 'Удалить';
																|en = 'Delete'; fa = 'حذف';
																|it = 'Eliminare';
																|pl = 'Delete';
																|tr = 'Sil'"));
	Form.NotDeletedItemsUsageInstancesActions.Add("ReplaceRef", NStr("vi = 'Thay thế %PresentationRef% thành';
																	|ru = 'Заменить %PresentationRef% на';
																	|en = 'Replace %PresentationRef% with'; fa = 'Replace %PresentationRef% with';
																	|it = 'Sostituire %PresentationRef% con';
																	|pl = 'Zmień %PresentationRef% na';
																	|tr = '%PresentationRef% değiştir'"));
	
	Form.Items.NotDeletedItemRelationsAction.ChoiceList.Clear();
	For Each ListItem In Form.NotDeletedItemsUsageInstancesActions Do
		Form.Items.NotDeletedItemRelationsAction.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;
EndProcedure

#EndRegion

#Region OnActivateNotDeletedItemsRow

&AtClient
Procedure ShowNotDeletedItemsLinksAtClient()
	If NotDeletedItemsCurrentRowID = Items.NotTrash.CurrentRow Then
		Return;
	EndIf;

	ReportToSend = Undefined;
	DetailedErrorText = "";
	FillNotDeletedObjectsUsageInstances();
	
	If NotDeletedItemsUsageInstances.GetItems().Count() = 0 Then
		Items.ReasonsDisplayOptionsPages.CurrentPage = Items.ErrorTextPage;
		SetErrorText();
		Items.Actions.Enabled = False;
	Else	
		Items.ReasonsDisplayOptionsPages.CurrentPage = Items.ReasonsForNotDeletionPage;
		StandardSubsystemsClient.ExpandTreeNodes(ThisObject, "NotDeletedItemsUsageInstances", "*", True);
		Items.Actions.Enabled = True;
	EndIf;
EndProcedure

&AtClient
Procedure SetErrorText()
	Items.ErrorText.Title = ErrorText;
	Items.DetailsRef.Visible = ValueIsFilled(DetailedErrorText) ;
EndProcedure

&AtServer
Procedure FillNotDeletedObjectsUsageInstances(Val ActionsTable = Undefined)

	NotDeletedItemsCurrentRowID = Items.NotTrash.CurrentRow;
	TreeRow = ?(NotDeletedItemsCurrentRowID <> Undefined,
		NotTrash.FindByID(NotDeletedItemsCurrentRowID), Undefined);
	
	DisplayedRows = NotDeletedItemsUsageInstances.GetItems();
	DisplayedRows.Clear();
	ReasonsForNotDeletionCache.Clear();
	
	If TreeRow = Undefined Or TreeRow.PictureNumber < 1 Then
		// Nothing or a group is selected.
		ErrorText = NStr("vi = 'Chọn một mục để tìm hiểu lý do
			|không thể xóa nó.';
			|ru = 'Выберите объект, чтобы узнать причину,
			|по которой его не удалось удалить.';
			|en = 'Select an object to view the reason
			|why it cannot be deleted.'; fa = 'Select an object to view the reason
			|why it cannot be deleted.';
			|it = 'Выберите объект, чтобы узнать причину,
			|по которой его не удалось удалить.';
			|pl = 'Wybierz obiekt, aby dowiedzieć się 
			| z jakiej przyczyny jego nie udało się usunąć.';
			|tr = 'Nesnenin silinememesinin nedenini öğrenmek için nesneyi seçin
			|.'");
		Return;
	EndIf;

	If ActionsTable = Undefined Then
		ActionsTable = ActionsTable();
	EndIf;

	TableOfNotDeletedItemsLinks = FormAttributeToValue("NotDeletedItemsLinks", Type("ValueTable")); // ValueTable
	TableOfNotDeletedItemsLinks.Indexes.Add("ItemToDeleteRef");
	
	// Reference to a not deleted object is selected.
	ItemsToShow = TableOfNotDeletedItemsLinks.FindRows(New Structure("ItemToDeleteRef", TreeRow.ItemToDeleteRef));
	For Each TableRow In ItemsToShow Do
		If TableRow.IsError Then
			ErrorText = TableRow.FoundItemReference;
			DetailedErrorText = TableRow.Presentation;
			Break;
		EndIf;
			
		AddReasonsForNotDeletionRecursively(ActionsTable, TableOfNotDeletedItemsLinks, DisplayedRows, TableRow);
		ReasonsForNotDeletionCache.Add(TableRow.ItemToDeleteRef);
	EndDo;

EndProcedure

&AtServer
Procedure FillInTheActionInTheLineOfThePlaceOfUseOfTheUndeletedOnes(ActionsTable, Val ReasonForNotDeletion, Action = "")
	If ReasonForNotDeletion.IsError Then
		Return;
	EndIf;
	
	Filter = New Structure("FoundItemReference, Action", ReasonForNotDeletion.FoundItemReference, "Delete");
	SelectedActions = ActionsTable.FindRows(Filter);
	
	If SelectedActions.Count() = 0 Then
		Filter = New Structure("Source, Action", ReasonForNotDeletion.ItemToDeleteRef, "ReplaceRef");
		SelectedActions = ActionsTable.FindRows(Filter);
	EndIf;
	
	If SelectedActions.Count() > 0 Then
		Action = SelectedActions[0].Action;
		ActionParameter = SelectedActions[0].ActionParameter;
	EndIf;	
	
	If Not ReasonForNotDeletion.MainReason Then
		Action = "Delete";
	EndIf;
	
	ReasonForNotDeletion.Action = Action;
			
	If Action = "ReplaceRef" Then
		ReasonForNotDeletion.ActionPresentation = ReplaceWithCommandPresentation(ReasonForNotDeletion, ActionParameter);
	ElsIf Action = "Delete" Then
		ReasonForNotDeletion.ActionPresentation = NotDeletedItemsUsageInstancesActions.FindByValue(Action).Presentation;
	Else
		ReasonForNotDeletion.ActionPresentation = "";
	EndIf;
EndProcedure

&AtServer
Procedure AddReasonsForNotDeletionRecursively(ActionsTable, TableOfNotDeletedItemsLinks, ParentRowsCollection, RowData)

	NewRow = ParentRowsCollection.Add();
	SubordinateRows = NewRow.GetItems();
	If RowData.IsError Then
		FillPropertyValues(NewRow, RowData,"IsError,PictureNumber");
		NewRow.Presentation = RowData.FoundItemReference;
		NewRow.FoundItemReference = ?(ValueIsFilled(RowData.Presentation), RowData.Presentation, RowData.FoundItemReference);
	Else	
		FillPropertyValues(NewRow, RowData);
	EndIf;

	ItemsToShow = TableOfNotDeletedItemsLinks.FindRows(New Structure("ItemToDeleteRef", RowData.FoundItemReference));
	HasErrorsOnly = True;
	For Each TableRow In ItemsToShow Do
		If Not TableRow.IsError Then
			HasErrorsOnly = False;
		EndIf;
		
		If ReasonsForNotDeletionCache.FindByValue(TableRow.FoundItemReference) = Undefined Then
			ReasonsForNotDeletionCache.Add(TableRow.ItemToDeleteRef);
			AddReasonsForNotDeletionRecursively(ActionsTable, TableOfNotDeletedItemsLinks, SubordinateRows, TableRow);
		EndIf;
	EndDo;

	NewRow.MainReason = Not NewRow.IsError 
		And (SubordinateRows.Count() = 0 Or HasErrorsOnly Or ItemsToShow.Count() = 0);
									
	FillInTheActionInTheLineOfThePlaceOfUseOfTheUndeletedOnes(ActionsTable, NewRow, ?(ItemsToShow.Count() <> 0, "Delete", ""));

EndProcedure

#EndRegion

#Region OnActivateNotDeletedItemsUsageInstancesRow

&AtClient
Procedure NotDeletedItemsUsageInstancesOnActivateRow(Item)
	CurrentData = Items.NotDeletedItemsUsageInstances.CurrentData;

	If CurrentData = Undefined Then
		Return;
	EndIf;

	If ValueIsFilled(CurrentData.FoundItemReference) Then
		Items.NotDeletedItemRelationsAction.ChoiceList.Clear();
		
		// Deletion is not available for errors and constants.
		If TypeOf(CurrentData.FoundItemReference) <> Type("String") Then
			Items.NotDeletedItemRelationsAction.ChoiceList.Add("Delete", ViewOfTheDeleteCommand(CurrentData));
		EndIf;
		
		Actions = ActionsTable.FindRows(New Structure("FoundItemReference", CurrentData.FoundItemReference));
		If Not(Actions.Count() > 0 
				And Actions[0].Action = "Delete" 
				And Actions[0].Source <> CurrentData.ItemToDeleteRef) Then
		
			Items.NotDeletedItemRelationsAction.ChoiceList.Add("ReplaceRef", 
				ReplaceWithCommandPresentation(CurrentData));
		EndIf;

	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ReplaceWithCommandPresentation(CurrentData, Parameter = Undefined)

	UpperLevelRow = CurrentData.GetParent();
	UpperLevelRowPresentation = ?(UpperLevelRow <> Undefined,
		UpperLevelRow.Presentation, CurrentData.PresentationItemToDelete);

	If Parameter <> Undefined Then
		Result = StrReplace(NStr("vi = 'Thay thế %1 sang %2';
								|ru = 'Заменить %1 на %2';
								|en = 'Replace %1 with %2'; fa = 'Replace %1 with %2';
								|it = 'Заменить %1 на %2';
								|pl = 'Replace %1 with %2';
								|tr = '%1i %2 ile değiştir'"), "%1", UpperLevelRowPresentation);
		Return StrReplace(Result, "%2", Parameter);
	Else
		Return StrReplace(NStr("vi = 'Thay thế %1 sang...';
								|ru = 'Заменить %1 на...';
								|en = 'Replace %1 with…'; fa = 'Replace %1 with…';
								|it = 'Заменить %1 на...';
								|pl = 'Replace %1 with…';
								|tr = '%1i ... ile değiştir'"), "%1", UpperLevelRowPresentation);
	EndIf;
		
EndFunction

&AtClientAtServerNoContext
Function ViewOfTheDeleteCommand(CurrentData)
	Presentation = NStr("vi = 'Xóa bỏ';
						|ru = 'Удалить';
						|en = 'Delete'; fa = 'حذف';
						|it = 'Eliminare';
						|pl = 'Usuń';
						|tr = 'Sil'") + Chars.NBSp + CurrentData.Presentation;
	Return Presentation;
EndFunction

#EndRegion

&AtClient
Procedure ShowTableObject(TableItem)
	TableRow = TableItem.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	Value = Undefined;
	If Not TableRow.Property("FoundItemReference", Value)
		And Not TableRow.Property("ItemToDeleteRef", Value) Then
		Return;
	EndIf;
	
	If TypeOf(Value) = Type("String") 
		And Not CommonClientServer.StructureProperty(TableRow, "IsError", False) Then
			
		If TableRow.Property("IsConstant") And TableRow.IsConstant Then
			FormPath = Value + ".ConstantsForm";
		Else
			FormPath = Value + ".ListForm";
		EndIf;
		OpenForm(FormPath);
	ElsIf CommonClientServer.StructureProperty(TableRow, "IsError", False) Then
		StandardSubsystemsClient.ShowDetailedInfo(Undefined, TableRow.FoundItemReference);
	Else
		ShowValue(, Value);
	EndIf;
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeSetMarkInList(Data, Check, CheckParent)
	
	// Mark as a subordinate item.
	RowItems = Data.GetItems();
	
	For Each Item In RowItems Do
		Item.Check = Check;
		MarkedForDeletionItemsTreeSetMarkInList(Item, Check, False);
	EndDo;
	
	// Check the parent item.
	Parent = Data.GetParent();
	
	If CheckParent And Parent <> Undefined Then 
		MarkedForDeletionItemsTreeCheckParent(Parent);
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeCheckParent(Parent)
	
	RowItems = Parent.GetItems();
	Parent.Check = ItemMarkValues(RowItems);
	
EndProcedure

// Parameters:
//   Result - ValueList of String
//   AdditionalParameters - Structure
//
&AtClient
Procedure ConfigureFilterCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentFilter = CommonClient.CopyRecursive(MetadataFilter);
	SetMetadataFilter(ThisObject, Result);
	
	If MetadataFilterChanged(CurrentFilter, Result) Then
		RunJob(FormJobs().MarkedObjectsSearch);
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure SetMetadataFilter(Form, Result)
	Form.MetadataFilter = ?(Result = Undefined, New ValueList, Result.Copy());// ValueList of String.
	Form.Items.ConfigureFilter.Title = MetadataFilterPresentation(Result);
EndProcedure

&AtClientAtServerNoContext
Function MetadataFilterPresentation(FilterValue)
	FilterPresentation = "";
	Presentation = New Array;
	For Each Filter In FilterValue Do
		Presentation.Add(Filter.Presentation);
	EndDo;
	FilterPresentation = StrConcat(Presentation, ", ");
	Return ?(IsBlankString(FilterPresentation), NStr("vi = 'Tất cả đã được đánh dấu để xóa';
													|ru = 'Все помеченные на удаление';
													|en = 'All objects marked for deletion'; fa = 'همه اشیای علامت‌خورده برای حذف';
													|it = 'Tutti i contrassegnati per la cancellazione';
													|pl = 'Wszystkie zaznaczone do usunięcia';
													|tr = 'Hepsi silinmek üzere işaretlendi'"), FilterPresentation);
EndFunction

&AtClient
Function MetadataFilterChanged(OldFilter, Result)
	RepeatedSearchRequired = False;
	For Each Item In Result Do
		If MetadataFilter.FindByValue(Item.Value) = Undefined Then
			RepeatedSearchRequired = True;
			Break;
		EndIf;
	EndDo;
	
	If OldFilter.Count() <> Result.Count() Then
		RepeatedSearchRequired = True;
	EndIf;
	
	Return RepeatedSearchRequired;
EndFunction

#Region BackgroundJobs

#Region SearchForItemsmarkedForDeletion

&AtClient
Procedure StartMarkedObjectsSearch(SearchForTechnologicalObjects)
	SetObjectsMarkedForDeletionSelectionStateWithStatePanel();
	
	PresentationOperation = NStr("vi = 'Tìm kiếm đối tượng có đánh dấu xóa';
								|ru = 'Поиск помеченных на удаление';
								|en = 'Search for objects marked for deletion'; fa = 'Search for objects marked for deletion';
								|it = 'Ricerca dei contrassegnati per la cancellazione';
								|pl = 'Wyszukiwanie zaznaczonych do usunięcia';
								|tr = 'Silinmek için işaretlilerin aranması'");
	ToStartSearchingForTheMarkedSettingOfTheForm(ThisObject);

	
	Handler = New CallbackDescription("AfterMarkedObjectsSearchCompletion", ThisObject);
	
	CurrentOperation1 = StartMarkedObjectsSearchServer(MetadataFilter, UUID, SearchForTechnologicalObjects);
	OnStartBackgroundJob(Handler);
EndProcedure

&AtClientAtServerNoContext
Procedure ToStartSearchingForTheMarkedSettingOfTheForm(Form)
	
	Form.Items.StatePresentationPages.CurrentPage = Form.Items.RunningState;
	Form.Items.LongRunningOperationPresentationDecoration.Title = NStr("vi = 'Đang tìm kiếm những mục được đánh dấu để xóa ...';
																		|ru = 'Выполняется поиск помеченных на удаление...';
																		|en = 'Searching for objects marked for deletion…'; fa = 'Searching for objects marked for deletion…';
																		|it = 'Ricerca dei contrassegnati per la cancellazione in corso...';
																		|pl = 'Trwa wyszukiwanie zaznaczonych do usunięcia...';
																		|tr = 'Silinmek üzere işaretli aranıyor...'");
	Form.Items.InformationPages.ReadOnly = True;
	Form.Items.ActiveAfterSearchMarkedObjectsGroup.Enabled = False;

EndProcedure

&AtClient
Procedure OnStartBackgroundJob(Val Handler, IsDeletionProcess = False)
	Var WaitSettings;
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	WaitSettings.OutputProgressBar = True;
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("IsDeletionProcess", IsDeletionProcess);
	WaitSettings.ExecutionProgressNotification = New CallbackDescription("OnUpdateBackgroundJobProgress",
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(CurrentOperation1, Handler, WaitSettings);
	If CurrentOperation1 <> Undefined And CurrentOperation1.Status = "Running" Then
		ShowDialogBeforeClose = True;
	EndIf;
EndProcedure

&AtClient
Procedure AfterCompleteBackgroundJob1(Result)
	PreviousStepResult = Result;
	ShowDialogBeforeClose = False;
	CurrentOperation1 = Undefined;
	JobParameter = DeleteCurrentJob();	
	JobInProgress = False;
	
	If JobsCountInQueue() = 0 Then
		SetExclusiveModeAtServer(False);
	EndIf;
	
	If Result.Status <> "Error" Then
		RunJob(,JobParameter);
	EndIf;
EndProcedure

&AtServer
Function StartMarkedObjectsSearchServer(MetadataFilter, FormUniqueID, SearchForTechnologicalObjects = False)
	
	UpdateAdditionalAttributesSettingsBeforeSearchForMarkedItems();
	MethodParameters = TimeConsumingOperations.FunctionExecutionParameters(FormUniqueID);
	MethodParameters.BackgroundJobDescription = NStr("vi = 'Tìm kiếm đối tượng có đánh dấu xóa';
													|ru = 'Поиск помеченных на удаление';
													|en = 'Search for objects marked for deletion'; fa = 'Search for objects marked for deletion';
													|it = 'Ricerca dei contrassegnati per la cancellazione';
													|pl = 'Wyszukiwanie zaznaczonych do usunięcia';
													|tr = 'Silinmek için işaretlilerin aranması'");
	Job = TimeConsumingOperations.ExecuteFunction(MethodParameters,
		"MarkedObjectsDeletionInternal.MarkedForDeletion",
		MetadataFilter, 
		AdditionalAttributesOfItemsMarkedForDeletion.Unload(), 
		FormAttributeToValue("MarkedForDeletionItemsTree"),
		SearchForTechnologicalObjects);

	Return Job;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterMarkedObjectsSearchCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	JobInProgress = False;
	If Result.Status = "Error" Then
		FillBackgroundJobErrorInfo(ThisObject, Result);
		SetObjectsMarkedForDeletionSelectionStateWithStatePanel();
	Else
		FillMarkedForDeletionItemsTree(Result);
		If MarkedForDeletionItemsTree.GetItems().Count() = 0 Then
			Items.StatePresentationPages.CurrentPage = Items.DeletionNotRequiredState;
			JobInProgress = True;
			SetObjectsMarkedForDeletionSelectionStateWithStatePanel();
			ClearFormJobsQueue();
		Else
			SetObjectsMarkedForDeletionSelectionState();
		EndIf;
	EndIf;
	
	AfterCompleteBackgroundJob1(Result);
EndProcedure

&AtClientAtServerNoContext
Procedure FillBackgroundJobErrorInfo(Form, Result)
	Form.BackgroundJobErrorInfo = Result.ErrorInfo;
	Form.Items.CompletionPresentationFailedDecoration.Title = 
		?(IsExclusiveModeSettingError(Result.ErrorInfo),
			NStr("vi = 'Không thể thiết lập chế độ độc quyền';
				|ru = 'Не удалось установить монопольный режим';
				|en = 'Couldn''t set exclusive mode'; fa = 'Couldn''t set exclusive mode';
				|it = 'Impossibile stabilire la modalità esclusiva';
				|pl = 'Nie udało się ustawić tryb wyłączności';
				|tr = 'Özel mod ayarlanamadı'"),
			ErrorProcessing.ErrorMessageForUser(Result.ErrorInfo));
	Form.Items.StatePresentationPages.CurrentPage = Form.Items.CompletedWithErrorsState;
EndProcedure

&AtServer
Procedure FillMarkedForDeletionItemsTree(Result)
	ValueTree = GetFromTempStorage(Result.ResultAddress);
	DeleteFromTempStorage(Result.ResultAddress);
	FillFormDataTreeItemCollection(MarkedForDeletionItemsTree, ValueTree);
	DeleteFromTempStorage(Result.ResultAddress);
EndProcedure

#EndRegion

#Region DeleteMarkedObjects

&AtClient
Procedure StartMarkedObjectsDeletion(Parameter = Undefined)
	PresentationOperation = NStr("vi = 'Xóa đối tượng bị đánh dấu xóa';
								|ru = 'Удаление помеченных';
								|en = 'Delete marked objects'; fa = 'Delete marked objects';
								|it = 'Eliminazione dei contrassegnati';
								|pl = 'Usunięcie zaznaczonych';
								|tr = 'İşaretlilerin silinmesi'");
	Items.StatePresentationPages.CurrentPage = Items.RunningState;
	Items.LongRunningOperationPresentationDecoration.Title = NStr("vi = 'Đang xóa những mục được đánh dấu...';
																	|ru = 'Выполняется удаление помеченных...';
																	|en = 'Deleting objects marked for deletion…'; fa = 'Deleting objects marked for deletion…';
																	|it = 'Cancellazione dei contrassegnati in corso...';
																	|pl = 'Trwa usunięcie zaznaczonych...';
																	|tr = 'İşaretliler siliniyor...'");
	SetObjectsMarkedForDeletionSelectionStateWithStatePanel();
	
	Items.CommandBarForm.Enabled = False;
	Items.InformationPages.ReadOnly = True;

	Handler = New CallbackDescription("AfterMarkedObjectsDeletionCompletion", ThisObject);
	CurrentOperation1 = StartMarkedObjectsDeletionServer(UUID, PreviousStepResult,
		Parameter = "CompleteRemoval");
	OnStartBackgroundJob(Handler);
EndProcedure

&AtServer
Function SetExclusiveModeAtServer(ExclusiveMode)
	Result = New Structure;
	Result.Insert("Status", "Completed2");
	Result.Insert("ErrorInfo", Undefined);

	If ExclusiveMode() <> ExclusiveMode Then
		Try
			SetExclusiveMode(ExclusiveMode);
		Except
			Result.Status = "Error";
			Result.ErrorInfo = ErrorInfo();
			WriteLogEvent(NStr("vi = 'Xóa đối tượng bị đánh dấu xóa';
								|ru = 'Удаление помеченных';
								|en = 'Delete marked objects'; fa = 'Delete marked objects';
								|it = 'Eliminazione dei contrassegnati';
								|pl = 'Usunięcie zaznaczonych';
								|tr = 'İşaretlilerin silinmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(Result.ErrorInfo));
		EndTry;
	EndIf;
	
	If Not ExclusiveMode Then
		If Common.SubsystemExists("StandardSubsystems.UsersSessions") Then
			ModuleIBConnections = Common.CommonModule("IBConnections");
			ModuleIBConnections.AllowUserAuthorization();
		EndIf;
	EndIf;
			
	Return Result;
EndFunction

&AtServer
Function StartMarkedObjectsDeletionServer(FormUniqueID, PreviousStepResult, RepeatSearch = False)
	If DeleteOnOpen Then
		ObjectsToDeleteSource = Parameters.ObjectsToDelete;
	ElsIf RepeatSearch Then
		ObjectsToDeleteSource = Undefined;
	Else	
		ObjectsToDeleteSource = FormAttributeToValue("MarkedForDeletionItemsTree");
	EndIf;
	
	AdditionalAttributesSettings = FormAttributeToValue("AdditionalAttributesOfItemsMarkedForDeletion");
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(FormUniqueID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Xóa các đối tượng có đánh dấu';
														|ru = 'Удаление помеченных объектов';
														|en = 'Marked object deletion'; fa = 'حذف اشیای علامت‌گذاری‌شده';
														|it = 'Eliminazione degli oggetti selezionati';
														|pl = 'Usuwanie zaznaczonych obiektów';
														|tr = 'İşaretli nesnelerin silinmesi'");
	
	PreviousStepResultValue = ?(PreviousStepResult <> Undefined 
			And IsTempStorageURL(PreviousStepResult.ResultAddress),
		GetFromTempStorage(PreviousStepResult.ResultAddress),
		Undefined);
	
	AllowedDeletionModes = MarkedObjectsDeletionInternal.AllowedDeletionModes();
	ResultingDeletionMode = ?(AllowedDeletionModes.Find(DeletionMode) <> Undefined,
		DeletionMode, "Standard");
	If ResultingDeletionMode = "Exclusive" Then
		AllowedDeletionModes = MarkedObjectsDeletionInternal.AllowedDeletionModes();
		Job = TimeConsumingOperations.ExecuteFunction(ExecutionParameters,
			"MarkedObjectsDeletionInternal.ToDeleteMarkedObjects",
			ObjectsToDeleteSource,
			ResultingDeletionMode,
			AdditionalAttributesSettings,
			PreviousStepResultValue,
			FormUniqueID,
			Items.ShowTechnologicalData.Check);
	Else
		DeletionParameters = ParametersOfMarkedObjectsDeletion(ObjectsToDeleteSource, ResultingDeletionMode,
			AdditionalAttributesSettings, PreviousStepResultValue, FormUniqueID,
		Items.ShowTechnologicalData.Check);
		BatchesCount = DeletionParameters.Count();
		
		Job = TimeConsumingOperations.ExecuteFunctionInMultipleThreads(
			"MarkedObjectsDeletionInternal.ToDeleteMarkedObjects",
			ExecutionParameters, DeletionParameters);
	EndIf;
	
	Return Job;
EndFunction

&AtServer
Function ParametersOfMarkedObjectsDeletion(ObjectsToDeleteSource, ResultingDeletionMode,
	AdditionalAttributesSettings, PreviousStepResultValue, FormUniqueID,
	ShouldDeleteTechnologicalObjects)
	
	If ObjectsToDeleteSource = Undefined Then
		ObjectsToDeleteSource = FormAttributeToValue("MarkedForDeletionItemsTree");
	EndIf;
	
	DeletionParameters = New Map;
	If TypeOf(ObjectsToDeleteSource) <> Type("ValueTree") Then
		ServerCallParameters = New Array;
		ServerCallParameters.Add(ObjectsToDeleteSource);
		ServerCallParameters.Add(ResultingDeletionMode);
		ServerCallParameters.Add(AdditionalAttributesSettings);
		ServerCallParameters.Add(PreviousStepResultValue);
		ServerCallParameters.Add(FormUniqueID);
		ServerCallParameters.Add(ShouldDeleteTechnologicalObjects);
		DeletionParameters.Insert(0, ServerCallParameters);
		Return DeletionParameters;
	EndIf;
	
	BatchIndex = 0;
	
	ServerCallParameters = New Array;
	ServerCallParameters.Add(ObjectsToDeleteSource);
	ServerCallParameters.Add(ResultingDeletionMode);
	ServerCallParameters.Add(AdditionalAttributesSettings);
	ServerCallParameters.Add(PreviousStepResultValue);
	ServerCallParameters.Add(FormUniqueID);
	ServerCallParameters.Add(ShouldDeleteTechnologicalObjects);
	DeletionParameters.Insert(BatchIndex, ServerCallParameters);
	
	Return DeletionParameters;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterMarkedObjectsDeletionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	JobInProgress = False;
	ShowDialogBeforeClose = False;
	
	If Result.Status = "Error" Then
		DeletionResultsInfo = ProcessDeletionResultError(Result);
	ElsIf Result.Status = "Completed2" Then 
		UUIDConsideringOwner = ?(FormOwner = Undefined, UUID, FormOwner.UUID);
		DeletionResultsInfo = ProcessTheDeletionResultSuccess(Result, 
			UUIDConsideringOwner, DeletionResultsInfo);
		CommonClient.NotifyObjectsChanged(DeletionResultsInfo.Trash);
	EndIf;
	
	AfterCompleteBackgroundJob1(Result);
	
	If DeletionResultsInfo.Success Then
		If DeleteOnOpen Then
			Close(DeletionResultsInfo);
		Else
			UpdateTheTreeMarkedForDeletion();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ProcessDeletionResultError(Result)
	SetObjectsMarkedForDeletionSelectionStateWithStatePanel();
	FillBackgroundJobErrorInfo(ThisObject, Result);
	SetExclusiveModeAtServer(False);
	Return NewDeletionResultsInfo();
EndFunction

&AtServer
Function ProcessTheDeletionResultSuccess(Result, FormUniqueID, DeletionResultsInfo)
	
	DeletionResultsInfo = ImportDeletionResult(Result, FormUniqueID, 
		DeletionResultsInfo);
	If DeletionResultsInfo.ResultAddress <> "" Then 
		ProcessDeletionExecutionResult(DeletionResultsInfo);
	EndIf;
	SetExclusiveModeAtServer(False);
	Return DeletionResultsInfo;
	
EndFunction

// Parameters:
//   DeletionResultsInfo - See NewDeletionResultsInfo
//
&AtServer
Procedure ProcessDeletionExecutionResult(DeletionResultsInfo)
	
	If NotTrash.GetItems().Count() > 0 Then
		Items.StatePresentationPages.CurrentPage = Items.PartialDeletionState;
		Items.PartialDeletionStateLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xóa %1 từ %2.';
				|ru = 'Удалено %1 из %2.';
				|en = 'Deleted %1 of %2.'; fa = 'Deleted %1 of %2.';
				|it = 'Cancellato %1 di %2.';
				|pl = 'Usunięto %1 z %2.';
				|tr = '%2 dan %1silindi.'"),
			DeletionResultsInfo.DeletedItemsCount1,
	 		DeletionResultsInfo.NotDeletedItemsCount1 + DeletionResultsInfo.DeletedItemsCount1);
		SetStateUnsuccessfulDeletionWithStatePanel();
	ElsIf DeletionResultsInfo.DeletedItemsCount1 > 0 Then
		SetObjectsMarkedForDeletionSelectionStateWithStatePanel();
		
		Items.StatePresentationPages.CurrentPage = Items.CompletedState;
		Items.CompletionPresentationSuccessDecoration.Title = NStr("vi = 'Đã xóa thành công.';
																	|ru = 'Удаление успешно завершено.';
																	|en = 'Deleted successfully.'; fa = 'با موفقیت حذف شد.';
																	|it = 'Cancellazione completata con successo.';
																	|pl = 'Usunięcie zakończono pomyślnie.';
																	|tr = 'Kaldırma işlemi başarıyla tamamlandı.'");
	Else
		SetObjectsMarkedForDeletionSelectionState();
	EndIf;
	
EndProcedure

// Parameters:
//   DeletionResult - Structure:
//   * ResultAddress - String
//   
// Returns:
//   See NewDeletionResultsInfo
//
&AtServer
Function ImportDeletionResult(DeletionResult, ResultStorageID, ResultInfo)
	GeneralOutput = GetFromTempStorage(DeletionResult.ResultAddress);
	If TypeOf(GeneralOutput) = Type("Structure") Then
		BackgroundExecutionResult = GeneralOutput;
	Else
		If GeneralOutput[0].Status = "Error" Then
			Return ProcessDeletionResultError(GeneralOutput[0]);
		EndIf;	
		
		BackgroundExecutionResult = GetFromTempStorage(GeneralOutput[0].ResultAddress);
		For BatchIndex = 1 To BatchesCount - 1 Do
			BatchResultAddress = GeneralOutput[BatchIndex].ResultAddress;
			ResultOfBatchExecutionInBackground = GetFromTempStorage(BatchResultAddress);
			
			BackgroundExecutionResult.NotDeletedObjectsCount = BackgroundExecutionResult.NotDeletedObjectsCount
				+ ResultOfBatchExecutionInBackground.NotDeletedObjectsCount;
			BackgroundExecutionResult.DeletedItemsCount = BackgroundExecutionResult.DeletedItemsCount
				+ ResultOfBatchExecutionInBackground.DeletedItemsCount;
			CommonClientServer.SupplementTable(ResultOfBatchExecutionInBackground.NotDeletedItemsLinks,
				BackgroundExecutionResult.NotDeletedItemsLinks);
			CommonClientServer.SupplementArray(BackgroundExecutionResult.Trash,
				ResultOfBatchExecutionInBackground.Trash);
			BackgroundExecutionResult.MarkedForDeletionItemsTree =
				MarkedForDeletionItemsTreeWithoutDeletedItems(BackgroundExecutionResult.MarkedForDeletionItemsTree,
				ResultOfBatchExecutionInBackground.Trash);
			MergeItemsMarkedForDeletion(BackgroundExecutionResult.MarkedForDeletionItemsTree,
				ResultOfBatchExecutionInBackground.MarkedForDeletionItemsTree);
			MergeAllNonDeleted(BackgroundExecutionResult.NotTrash, ResultOfBatchExecutionInBackground.NotTrash);
		EndDo;
		ProcessedTotalCount = 0;
		SelectedCountTotal = 0;
		BatchesCount = 0;
		DeletionProgress.Clear();
	EndIf;
	ResultInfo = ?(DeleteOnOpen, ResultInfo, Undefined);

	Result = GenerateDeletionResult(ResultInfo, BackgroundExecutionResult,
		ResultStorageID);

	If BackgroundExecutionResult <> Undefined Then
		FillFormDataTreeItemCollection(MarkedForDeletionItemsTree,
			BackgroundExecutionResult.MarkedForDeletionItemsTree);
		FillFormDataTreeItemCollection(NotTrash, BackgroundExecutionResult.NotTrash);
		NotDeletedItemsLinks.Load(BackgroundExecutionResult.NotDeletedItemsLinks);
	EndIf;
	Return Result;
EndFunction

&AtServerNoContext
Function MarkedForDeletionItemsTreeWithoutDeletedItems(MarkedForDeletion, Trash)
	
	Result = MarkedForDeletion.Copy();
	ModifiedParents = New Array;
	
	For Each ItemToDeleteRef In Trash Do
		TreeRow = Result.Rows.Find(ItemToDeleteRef, "ItemToDeleteRef", True);
		If TreeRow = Undefined Then
			Continue;
		EndIf;
		
		If TreeRow.Parent <> Undefined Then
			ModifiedParents.Add(TreeRow.Parent);
		EndIf;
		TreeRow.Parent.Rows.Delete(TreeRow);
	EndDo;
	
	ModifiedParents = CommonClientServer.CollapseArray(ModifiedParents);
	
	For Each ModifiedParent In ModifiedParents Do
		If ModifiedParent.Rows.Count() > 0 Then
			Continue;
		EndIf;
		
		Result.Rows.Delete(ModifiedParent);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure MergeItemsMarkedForDeletion(Receiver, Source)
	
	RowsCount = Source.Rows.Count();
	
	For RowIndex = 0 To RowsCount - 1 Do
		TreeRowSource = Source.Rows[RowIndex];
		If TreeRowSource.Check = 0 Then
			Continue;
		EndIf;
		
		TreeRowDestination = Receiver.Rows.Find(TreeRowSource.ItemToDeleteRef, "ItemToDeleteRef"); 
		If TreeRowDestination  = Undefined Then
			Continue;
		EndIf;
		
		TreeRowDestination.Check = TreeRowSource.Check;
		SubstringCount = TreeRowSource.Rows.Count();
		For SubstringIndex = 0 To SubstringCount - 1 Do
			
			TreeSubRowSource = TreeRowSource.Rows[SubstringIndex];
			
			TreeSubRowDestination = TreeRowDestination.Rows.Find(TreeSubRowSource.ItemToDeleteRef, "ItemToDeleteRef");
			If TreeSubRowDestination = Undefined Then
				Continue;
			EndIf;
			
			TreeSubRowDestination.Check = TreeSubRowSource.Check;
		EndDo;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure MergeAllNonDeleted(Receiver, Source)
	
	RowsCount = Source.Rows.Count();
	
	For Each TreeRowSource In Source.Rows Do
		TreeRowDestination = Receiver.Rows.Add();
		FillPropertyValues(TreeRowDestination, TreeRowSource);
		For Each TreeSubRowSource In TreeRowSource.Rows Do
			TreeSubRowDestination = TreeRowDestination.Rows.Add();
			FillPropertyValues(TreeSubRowDestination, TreeSubRowSource);
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Function GenerateDeletionResult(ResultInfo, BackgroundExecutionResult, ResultStorageID)
	Result = ?(ResultInfo = Undefined, NewDeletionResultsInfo(), ResultInfo);
	
	ItemsPreventingDeletionResult = ?(IsTempStorageURL(Result.ResultAddress), 
		GetFromTempStorage(Result.ResultAddress),
		MarkedObjectsDeletionInternal.ObjectsPreventingDeletion());
	
	If BackgroundExecutionResult <> Undefined Then
		CommonClientServer.SupplementArray(Result.Trash, BackgroundExecutionResult.Trash);
		Result.DeletedItemsCount1 = BackgroundExecutionResult.DeletedItemsCount + Result.DeletedItemsCount1;
		Result.NotDeletedItemsCount1 = BackgroundExecutionResult.NotDeletedObjectsCount + Result.NotDeletedItemsCount1;
		Result.Success = Result.DeletedItemsCount1 > 0 And Result.NotDeletedItemsCount1 = 0;
	
		NotDeletedResultItemRelations = MarkedObjectsDeletionInternal.TablesMerge(
				ItemsPreventingDeletionResult,
				BackgroundExecutionResult.NotDeletedItemsLinks,
				True);
	Else
		NotDeletedResultItemRelations = ItemsPreventingDeletionResult;
	EndIf;

	Result.ResultAddress = PutToTempStorage(
		NotDeletedResultItemRelations, ResultStorageID);
			
	Return Result;		
EndFunction

#EndRegion

#Region ActionsExecution

&AtClient
Procedure StartAdditionalDataProcessorExecution(Parameter)
	
	PresentationOperation = NStr("vi = 'Xử lý bổ sung các đối tượng cản trở';
								|ru = 'Дополнительная обработка мешающих удалению объектов';
								|en = 'Additional processing of objects preventing deletion'; fa = 'Additional processing of objects preventing deletion';
								|it = 'Elaborazione aggiuntiva degli oggetti che inficiano la cancellazione';
								|pl = 'Dodatkowe przetwarzanie przeszkadzających usunięciu obiektów';
								|tr = 'Silme işlemine müdahale eden nesnelerin ek işlenmesi'");
	SetStateUnsuccessfulDeletionWithStatePanel();
	
	Items.StatePresentationPages.CurrentPage = Items.RunningState;
	Items.LongRunningOperationPresentationDecoration.Title = NStr("vi = 'Xử lý bổ sung các lý do không xóa được thực hiện...';
																	|ru = 'Выполняется дополнительная обработка причин неудаления...';
																	|en = 'Additional processing of reasons preventing deleting…'; fa = 'Additional processing of reasons preventing deleting…';
																	|it = 'Elaborazione aggiuntiva delle cause di fallimento in corso...';
																	|pl = 'Trwa dodatkowe przetwarzanie przyczyn nieusunięcia...';
																	|tr = 'Silinmeme nedenleriyle ilgili ek işlemler devam ediyor...'");
	Items.CommandBarForm.Enabled = False;
	Items.InformationPages.ReadOnly = True;
	
	Handler = New CallbackDescription("AfterCompleteExecutingAdditionalDataProcessor", ThisObject);
	CurrentOperation1 = StartAdditionalDataProcessorExecutionServer();
	OnStartBackgroundJob(Handler);

EndProcedure

&AtServer
Function StartAdditionalDataProcessorExecutionServer()
	
	MethodParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	MethodParameters.BackgroundJobDescription = NStr("vi = 'Xử lý thêm các đối tượng cản trở vào việc xóa';
													|ru = 'Дополнительная обработка мешающих удалению объектов';
													|en = 'Additional processing of objects preventing deletion'; fa = 'Additional processing of objects preventing deletion';
													|it = 'Elaborazione aggiuntiva degli oggetti che inficiano la cancellazione';
													|pl = 'Dodatkowe przetwarzanie przeszkadzających usunięciu obiektów';
													|tr = 'Silme işlemine müdahale eden nesnelerin ek işlenmesi'");
	Job = TimeConsumingOperations.ExecuteFunction(MethodParameters,
		"MarkedObjectsDeletionInternal.RunDataProcessorOfReasonsForNotDeletion",
		ActionsTable.Unload());
	Return Job;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterCompleteExecutingAdditionalDataProcessor(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	JobInProgress = False;
	If Result.Status = "Error" Then
		SetStateUnsuccessfulDeletionWithStatePanel();
		FillBackgroundJobErrorInfo(ThisObject, Result);
		SetExclusiveModeAtServer(False);
	EndIf;
	
	AfterCompleteBackgroundJob1(Result);
EndProcedure

#EndRegion

&AtClient
Procedure AfterConfirmCancelJob(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Abort Then
		ShowDialogBeforeClose = False;
		CancelOperationServer(CurrentOperation1);
		SetExclusiveModeAtServer(False);	
		Close(DeletionResultsInfo);
	EndIf;
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.LongRunningOperationNewState
//  AdditionalParameters - Structure:
//    * IsDeletionProcess - Boolean
//
&AtClient
Procedure OnUpdateBackgroundJobProgress(Result, AdditionalParameters) Export
	If Result.Progress <> Undefined Then
		ProgressParameters = Undefined;
		If Result.Progress.Property("AdditionalParameters", ProgressParameters)
			And ProgressParameters = "ProgressofMultithreadedProcess" Then
			Return;
		EndIf;
		
		Items.ProgressPresentation.Visible = True;
		If Not AdditionalParameters.IsDeletionProcess Or ProgressParameters = Undefined Then
			ProgressText = Result.Progress.Text;
		Else
			ProgressText = ProgressText(ProgressParameters);
		EndIf;
		Items.ProgressPresentation.Title = ProgressText;
	EndIf;
EndProcedure

&AtServer
Function ProgressText(ProgressParameters)
	
	Filter = New Structure;
	Filter.Insert("SessionNumber", ProgressParameters.SessionNumber);
	TableRows = DeletionProgress.FindRows(Filter);
	If TableRows.Count() = 0 Then
		TableRow = DeletionProgress.Add();
		TableRow.SessionNumber = ProgressParameters.SessionNumber;
		PreviousProcessedCount = 0;
	Else
		TableRow = TableRows[0];
		PreviousProcessedCount = TableRow.ProcessedItemsCount;
	EndIf;
	TableRow.ProcessedItemsCount = ProgressParameters.ProcessedItemsCount;
	ProcessedTotalCount = ProcessedTotalCount
		+ (ProgressParameters.ProcessedItemsCount - PreviousProcessedCount);
	
	ProgressText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã xử lý %1 trong số %2';
			|ru = 'Обработано %1 из %2';
			|en = 'Processed %1 of %2'; fa = 'Processed %1 of %2';
			|it = 'Elaborato %1 di %2';
			|pl = 'Przetworzono %1 z %2';
			|tr = '%2 dan %1 işlendi'"),
		ProcessedTotalCount,
		SelectedCountTotal);
	Return ProgressText;
	
EndFunction

&AtClientAtServerNoContext
Function ItemMarkValues(ParentItems1)
	
	HasMarkedItems    = False;
	HasUnmarkedItems = False;
	
	For Each ParentItem1 In ParentItems1 Do
		
		If ParentItem1.Check = 0 Then
			HasUnmarkedItems = True;
		ElsIf ParentItem1.Check = 1 Then 	
			HasMarkedItems = True;
		EndIf;
		
		If HasUnmarkedItems And HasMarkedItems Then
			Break;
		EndIf;
		
	EndDo;
	
	If HasMarkedItems Then
		If HasUnmarkedItems Then
			Return 2;
		Else
			Return 1;
		EndIf;
	Else
		Return 0;
	EndIf;
	
EndFunction

#EndRegion

&AtServer
Procedure FillFormDataTreeItemCollection(FormData1, ValueTree)
	FormDataRows = FormData1.GetItems();
	FormDataRows.Clear();
	Common.FillFormDataTreeItemCollection(FormDataRows, ValueTree);
EndProcedure

&AtClientAtServerNoContext
Function IsExclusiveModeSettingError(ErrorInfo)
	If ErrorInfo = Undefined Then
		Return False;
	EndIf;
	ErrorTextExclusive = NStr("vi = 'Lỗi truy cập cơ sở dữ liệu được chia sẻ';
								|ru = 'Ошибка разделенного доступа к базе';
								|en = 'Error of separated infobase access'; fa = 'Error of separated infobase access';
								|it = 'Errore di accesso condiviso alla base';
								|pl = 'Błąd podzielonego dostępu do bazy';
								|tr = 'Veritabanı paylaşım hatası'");
	Return StrFind(ErrorProcessing.BriefErrorDescription(ErrorInfo), ErrorTextExclusive) <> 0;
EndFunction

&AtClient
Function OperationDescription(OperationName, Parameter = Undefined)

	Return New Structure("Name, Parameter", OperationName, Parameter);

EndFunction

&AtClient
Procedure AddJob(OperationName, JobParameter = Undefined)
	FormJobsQueue.Add(OperationDescription(OperationName, JobParameter));
EndProcedure

&AtClient
Function DeleteCurrentJob()
	JobDetails = OperationDescription("");
	
	If FormJobsQueue.Count() <> 0 Then
		JobDetails = FormJobsQueue[0];
		FormJobsQueue.Delete(0);
	EndIf;
	
	Return JobDetails.Parameter;
EndFunction

&AtClient
Function CurrentJob()
	Return ?(FormJobsQueue.Count() = 0, OperationDescription(""), FormJobsQueue[0]);
EndFunction

&AtClient
Procedure RunJobWithPending()
	RunJob();
	ReadOnly = False;
EndProcedure

&AtClient
Procedure RunJob(Job = "", Parameter = Undefined)
	Result = New Structure("Success", True);
	
	If Not IsBlankString(Job) And Job <> CurrentJob().Name Then
		AddJob(Job);
	EndIf;
	
	If CurrentOperation1 <> Undefined Then
		Return;
	EndIf;
	
	CurrentFormJob = CurrentJob();
	If Not IsBlankString(CurrentFormJob.Name) Then
		
		If DeletionMode = "Exclusive" 
			And CurrentFormJob.Name <> FormJobs().MarkedObjectsSearch Then
				
			Result = TimeConsumingOperationsClient.NewResultLongOperation();
			FillPropertyValues(Result, SetExclusiveModeAtServer(True));
			If Result.Status = "Error" Then
				FillBackgroundJobErrorInfo(ThisObject, Result);
				Items.StatePresentationPages.Visible = True;
				Items.StatePresentationPages.CurrentPage = Items.CompletedWithErrorsState;
				Return;
			EndIf;
		EndIf;	
		
		JobInProgress = True;
		
		If CurrentFormJob.Name = FormJobs().DeleteMarkedObjects Then
			StartMarkedObjectsDeletion(CurrentFormJob.Parameter);
		ElsIf CurrentFormJob.Name = FormJobs().MarkedObjectsSearch Then
			StartMarkedObjectsSearch(Items.ShowTechnologicalData.Check);
		ElsIf CurrentFormJob.Name = FormJobs().AdditionalDataProcessorExecution Then 
			StartAdditionalDataProcessorExecution(CurrentFormJob.Parameter);
		EndIf;
		
	EndIf;
EndProcedure

&AtClient
Function FormJobs()
	Jobs = New Structure;
	Jobs.Insert("DeleteMarkedObjects", "DeleteMarkedObjects");
	Jobs.Insert("MarkedObjectsSearch", "MarkedObjectsSearch");
	Jobs.Insert("AdditionalDataProcessorExecution", "AdditionalDataProcessorExecution");
	Return Jobs;
EndFunction

&AtClient
Procedure ClearFormJobsQueue()
	FormJobsQueue.Clear();
EndProcedure

&AtClient
Function JobsCountInQueue()
	Return  FormJobsQueue.Count();
EndFunction

&AtClient
Procedure MarkedForDeletionItemsTreeSetAllClearAll(Value)
	
	If Items.MarkedForDeletionItemsTree.SelectedRows.Count() > 1 Then
		For Each RowID In Items.MarkedForDeletionItemsTree.SelectedRows Do
			SelectedItem = MarkedForDeletionItemsTree.FindByID(RowID);
			If SelectedItem = Undefined Then
				Continue;
			EndIf;
			
			SelectedItem.Check = Value;
			RowItems = SelectedItem.GetItems();
			For Each StringItem In RowItems Do
				StringItem.Check = Value;
				MarkedForDeletionItemsTreeSetMarkInList(StringItem, Value, False);
			EndDo;
			
			Parent = SelectedItem.GetParent();
			If Parent = Undefined Then
				MarkedForDeletionItemsTreeCheckParent(SelectedItem);
			Else
				MarkedForDeletionItemsTreeCheckParent(Parent);
			EndIf;
			
		EndDo;
		Return;
	EndIf;
	
	ListItems = MarkedForDeletionItemsTree.GetItems();
	
	For Each Item In ListItems Do
		MarkedForDeletionItemsTreeSetMarkInList(Item, Value, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			MarkedForDeletionItemsTreeCheckParent(Item)
		EndIf;
	EndDo;
EndProcedure

// Generates the result of calling the method "MarkedObjectsDeletionClient.StartMarkedObjectsDeletion".
//
// Returns:
//   Structure:
//   * DeletedItemsCount1 - Number
//   * NotDeletedItemsCount1 - Number
//   * ResultAddress - String
//   * Success - Boolean
//
&AtClientAtServerNoContext
Function NewDeletionResultsInfo()
	Result = New Structure;
	Result.Insert("Trash", New Array);
	Result.Insert("DeletedItemsCount1", 0);
	Result.Insert("NotDeletedItemsCount1", 0);
	Result.Insert("ResultAddress", "");
	Result.Insert("Success", False);
	Return Result;
EndFunction

&AtServer
Procedure UpdateAdditionalAttributesSettingsBeforeSearchForMarkedItems();
	
	AdditionalAttributesSettings = AdditionalAttributesOfItemsMarkedForDeletion.Unload();
	LinesToDelete = New Array;
	For Each Setting In AdditionalAttributesSettings Do
		MetadataObject = Metadata.FindByFullName(Setting.Metadata);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		If Not CommonClientServer.HasAttributeOrObjectProperty(MetadataObject.Attributes, Setting.Attribute) Then
			LinesToDelete.Add(Setting);
		EndIf;
	EndDo;
	
	If LinesToDelete.Count() > 0 Then
		For Each RowToDelete In LinesToDelete Do
			AdditionalAttributesSettings.Delete(RowToDelete);
		EndDo;
		AdditionalAttributesOfItemsMarkedForDeletion.Load(AdditionalAttributesSettings);
	EndIf;
	
EndProcedure

#EndRegion
