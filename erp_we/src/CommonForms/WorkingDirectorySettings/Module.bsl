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
	
	If Common.IsWebClient() Then
		Items.WorkingDirectoryFilesSize.Visible = False;
		Items.CleanUpWorkingDirectory.Visible = False;
	EndIf;
	
	FillParametersAtServer();
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.CleanUpWorkingDirectory.Title = NStr("vi = 'Xóa';
													|ru = 'Очистить';
													|en = 'Clear working directory'; fa = 'پاک کردن پوشه کاری';
													|it = 'Cancellare';
													|pl = 'Clear working directory';
													|tr = 'Temizle'");
		Items.UserWorkingDirectory.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("Show1CEnterpriseExtensionRequiredMessageBox", 0.1, True);
		Cancel = True;
		Return;
	EndIf;
	
	UserWorkingDirectory = FilesOperationsInternalClient.UserWorkingDirectory();
	
	UpdateWorkDirectoryCurrentStatus();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UserWorkingDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		Return;
	EndIf;
	
	// Selecting a new path to a working directory.
	DirectoryName = UserWorkingDirectory;
	Title = NStr("vi = 'Hãy chọn thư mục làm việc';
				|ru = 'Выберите рабочий каталог';
				|en = 'Select working directory'; fa = 'Select working directory';
				|it = 'Scegliete una directory di lavoro';
				|pl = 'Wybierz katalog roboczy';
				|tr = 'Çalışma dizini seç'");
	If Not FilesOperationsInternalClient.ChoosePathToWorkingDirectory(DirectoryName, Title, False) Then
		Return;
	EndIf;
	
	SetNewWorkDirectory(DirectoryName);
	
EndProcedure

&AtClient
Procedure LocalFileCacheMaxSizeOnChange(Item)
	
	SaveParameters();
	
EndProcedure

&AtClient
Procedure DeleteFileFromLocalFileCacheOnCompleteEditOnChange(Item)
	
	SaveParameters();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Show1CEnterpriseExtensionRequiredMessageBox()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	FilesOperationsInternalClient.Show1CEnterpriseExtensionRequiredMessageBox(Undefined);
	
EndProcedure

&AtClient
Procedure CleanUpLocalFileCache(Command)
	
	QueryText =
		NStr("vi = 'Tất cả các tệp sẽ bị xóa khỏi thư mục đang làm việc, 
		           |ngoại trừ những tệp được sử dụng để chỉnh sửa.
		           |
		           |Tiếp tục?';
		           |ru = 'Из рабочего каталога будут удалены все файлы,
		           |кроме занятых для редактирования.
		           |
		           |Продолжить?';
		           |en = 'All files except for ones locked for editing
		           |will be deleted from the working directory.
		           |
		           |Do you want to continue?'; fa = 'All files except for ones locked for editing
		           |will be deleted from the working directory.
		           |
		           |Do you want to continue?';
		           |it = 'Dalla directory di lavoro verranno eliminati tutti i file,
		           |tranne quelli in corso di modifica.
		           |
		           |Continuare?';
		           |pl = 'Z katalogu roboczego zostaną usunięte wszystkie pliki, 
		           |oprócz zajętych do edycji.
		           |
		           |Kontynuować?';
		           |tr = 'Çalışma dizininden, 
		           |düzenleme için kullanılan dosyalar hariç tüm dosyaları silinecektir. 
		           |
		           |Devam edilsin mi?'");
	Handler = New CallbackDescription("ClearLocalFileCacheCompletionAfterAnswerQuestionContinue", ThisObject);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DefaultPathToWorkingDirectory(Command)
	
	SetNewWorkDirectory(FilesOperationsInternalClient.SelectPathToUserDataDirectory());
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SaveParameters()
	
	PersonalSettings = New Array;
	
	Item = New Structure;
	Item.Insert("Object",    "LocalFileCache");
	Item.Insert("Setting", "PathToLocalFileCache");
	Item.Insert("Value",  UserWorkingDirectory);
	PersonalSettings.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "LocalFileCache");
	Item.Insert("Setting", "LocalFileCacheMaxSize");
	Item.Insert("Value", LocalFileCacheMaxSize * 1048576);
	PersonalSettings.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "LocalFileCache");
	Item.Insert("Setting", "DeleteFileFromLocalFileCacheOnCompleteEdit");
	Item.Insert("Value", DeleteFileFromLocalFileCacheOnCompleteEdit);
	PersonalSettings.Add(Item);
	
	CommonClient.CommonSettingsStorageSaveArray(PersonalSettings, True);
	
EndProcedure

&AtClient
Procedure ClearLocalFileCacheCompletionAfterAnswerQuestionContinue(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Handler = New CallbackDescription("CleanUpLocalFileCacheCompletion", ThisObject);
	// ClearAll = True.
	FilesOperationsInternalClient.CleanUpWorkingDirectory(Handler, WorkingDirectoryFilesSize, 0, True);
	
EndProcedure

&AtClient
Procedure CleanUpLocalFileCacheCompletion(Result, ExecutionParameters) Export
	
	UpdateWorkDirectoryCurrentStatus();
	
	ShowUserNotification(NStr("vi = 'Thư mục làm việc';
								|ru = 'Рабочий каталог';
								|en = 'Working directory'; fa = 'پوشه کاری';
								|it = 'Directory di lavoro';
								|pl = 'Katalog roboczy';
								|tr = 'Çalışma kataloğu'"),, NStr("vi = 'Đã hoàn tất thành công xóa thư mục làm việc.';
																|ru = 'Очистка рабочего каталога успешно завершена.';
																|en = 'The working directory is cleared.'; fa = 'The working directory is cleared.';
																|it = 'Directory di lavoro ripulita correttamente.';
																|pl = 'Oczyszczenie katalogu roboczego zostało zakończone pomyślnie.';
																|tr = 'Çalışma dizinini temizleme başarıyla tamamlandı.'"));
	
EndProcedure

&AtServer
Procedure FillParametersAtServer()
	
	DeleteFileFromLocalFileCacheOnCompleteEdit = Common.CommonSettingsStorageLoad(
		"LocalFileCache", "DeleteFileFromLocalFileCacheOnCompleteEdit", False);
	MaxSize1 = Common.CommonSettingsStorageLoad(
		"LocalFileCache", "LocalFileCacheMaxSize");
	If MaxSize1 = Undefined Then
		MaxSize1 = 100*1024*1024; // 100 MB
		Common.CommonSettingsStorageSave(
			"LocalFileCache", "LocalFileCacheMaxSize", MaxSize1);
	EndIf;
	LocalFileCacheMaxSize = MaxSize1 / 1048576;
	
EndProcedure

&AtClient
Procedure UpdateWorkDirectoryCurrentStatus()
	
#If Not WebClient Then
	FilesArray = FindFiles(UserWorkingDirectory, GetAllFilesMask());
	WorkingDirectoryFilesSize = 0;
	TotalFilesCount = 0;
	
	FilesOperationsInternalClient.GetFileListSize(
		UserWorkingDirectory,
		FilesArray,
		WorkingDirectoryFilesSize,
		TotalFilesCount); 
	
	WorkingDirectoryFilesSize = WorkingDirectoryFilesSize / 1048576;
#EndIf
	
EndProcedure

&AtClient
Procedure SetNewWorkDirectory(NewDirectory)
	
	If NewDirectory = UserWorkingDirectory Then
		Return;
	EndIf;
	
#If Not WebClient Then
	Handler = New CallbackDescription(
		"SetNewWorkDirectoryCompletion", ThisObject, NewDirectory);
	
	FilesOperationsInternalClient.MoveWorkingDirectoryContent(
		Handler, UserWorkingDirectory, NewDirectory);
#Else
	SetNewWorkDirectoryCompletion(-1, NewDirectory);
#EndIf
	
EndProcedure

&AtClient
Procedure SetNewWorkDirectoryCompletion(Result, NewDirectory) Export
	
	If Result <> -1 Then
		If Result <> True Then
			Return;
		EndIf;
	EndIf;
	
	UserWorkingDirectory = NewDirectory;
	
	SaveParameters();
	
EndProcedure

#EndRegion
