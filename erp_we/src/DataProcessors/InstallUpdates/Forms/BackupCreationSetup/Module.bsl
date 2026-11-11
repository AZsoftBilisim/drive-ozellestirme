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
	
	FillPropertyValues(Object, Parameters);
	UpdateControlsStates(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BackupDirectoryFieldStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Directory = Object.IBBackupDirectoryName;
	Dialog.CheckFileExistence = True;
	Dialog.Title = NStr("vi = 'Chọn thư mục của bản sao lưu dự phòng cơ sở thông tin';
						|ru = 'Выбор каталога резервной копии ИБ';
						|en = 'Select infobase backup directory'; fa = 'Select infobase backup directory';
						|it = 'Selezione della directory della copia di backup del database informatico';
						|pl = 'Wybór katalogu kopii zapasowej BI';
						|tr = 'Infobase yedekleme dizini seç'");
	If Dialog.Choose() Then
		Object.IBBackupDirectoryName = Dialog.Directory;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDataBackupOnChange(Item)
	UpdateControlsStates(ThisObject);
EndProcedure

&AtClient
Procedure RestoreInfobaseOnChange(Item)
	UpdateManualRollbackLabel(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	Cancel = False;
	If Object.CreateDataBackup = 2 Then
		File = New File(Object.IBBackupDirectoryName);
		Cancel = Not File.Exists() Or Not File.IsDirectory();
		If Cancel Then
			ShowMessageBox(, NStr("vi = 'Hãy chỉ ra thư mục hiện tại để lưu bản sao dự phòng cơ sở thông tin.';
									|ru = 'Укажите существующий каталог для сохранения резервной копии ИБ.';
									|en = 'Please specify an existing directory for storing the infobase backup.'; fa = 'Please specify an existing directory for storing the infobase backup.';
									|it = 'Indicare una directory esistente per salvare la copia di backup del database informatico.';
									|pl = 'Podaj istniejący katalog do zachowania kopii zapasowej BI.';
									|tr = 'IB yedeğini kaydetmek için varolan bir dizini belirtin.'"));
			CurrentItem = Items.BackupDirectoryField;
		EndIf;
	EndIf;
	If Not Cancel Then
		SelectionResult = New Structure;
		SelectionResult.Insert("CreateDataBackup",           Object.CreateDataBackup);
		SelectionResult.Insert("IBBackupDirectoryName",       Object.IBBackupDirectoryName);
		SelectionResult.Insert("RestoreInfobase", Object.RestoreInfobase);
		Close(SelectionResult);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure UpdateControlsStates(Form)
	
	Form.Items.BackupDirectoryField.AutoMarkIncomplete = (Form.Object.CreateDataBackup = 2);
	Form.Items.BackupDirectoryField.Enabled = (Form.Object.CreateDataBackup = 2);
	InfoPages = Form.Items.InfoPanel.ChildItems;
	CreateDataBackup = Form.Object.CreateDataBackup;
	InfoPanel = Form.Items.InfoPanel;
	If CreateDataBackup = 0 Then // Do not create a backup.
		Form.Object.RestoreInfobase = False;
		InfoPanel.CurrentPage = InfoPages.NoRollback;
	ElsIf CreateDataBackup = 1 Then // Create a temporary backup.
		InfoPanel.CurrentPage = InfoPages.ManualRollback;
		UpdateManualRollbackLabel(Form);
	ElsIf CreateDataBackup = 2 Then // Create a backup in the specified directory.
		Form.Object.RestoreInfobase = True;
		InfoPanel.CurrentPage = InfoPages.AutomaticRollback;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateManualRollbackLabel(Form)
	LabelPages = Form.Items.ManualRollbackLabelsPages.ChildItems;
	Form.Items.ManualRollbackLabelsPages.CurrentPage = ?(Form.Object.RestoreInfobase,
		LabelPages.Restore, LabelPages.DontRestore);
EndProcedure

#EndRegion
