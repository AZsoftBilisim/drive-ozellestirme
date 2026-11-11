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
	
	FillPropertyValues(
		ThisObject,
		Parameters,
		"ChangeDateInWorkingDirectory,
		|ChangeDateInFileStorage,
		|FullFileNameInWorkingDirectory,
		|SizeInWorkingDirectory,
		|SizeInFileStorage,
		|Message,
		|Title");
		
	TestNewer = " (" + NStr("vi = 'mới hơn';
							|ru = 'новее';
							|en = 'newer'; fa = 'newer';
							|it = 'più nuovo';
							|pl = 'nowsze';
							|tr = 'daha yeni'") + ")";
	If ChangeDateInWorkingDirectory > ChangeDateInFileStorage Then
		ChangeDateInWorkingDirectory = String(ChangeDateInWorkingDirectory) + TestNewer;
	ElsIf ChangeDateInWorkingDirectory < ChangeDateInFileStorage Then
		ChangeDateInFileStorage = String(ChangeDateInFileStorage) + TestNewer;
	EndIf;
	
	Items.Message.Height = StrLineCount(Message) + 2;
	
	If Parameters.FileOperation = "PutInFileStorage" Then
		
		Items.FormOpenExistingFile.Visible = False;
		Items.FormGetFromStorage.Visible    = False;
		Items.FormInto.DefaultButton   = True;
		
	ElsIf Parameters.FileOperation = "OpenInWorkingFolder" Then
		
		Items.FormInto.Visible  = False;
		Items.FormDontPut.Visible = False;
		Items.FormOpenExistingFile.DefaultButton = True;
	Else
		Raise NStr("vi = 'Thao tác không xác định với tệp';
					|ru = 'Неизвестное действие над файлом';
					|en = 'Unknown file operation.'; fa = 'Unknown file operation.';
					|it = 'Azione sul file sconosciuta';
					|pl = 'Nieznane działanie z plikiem';
					|tr = 'Dosyada bilinmeyen işlem'");
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.MessageIcon.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenExistingFile(Command)
	
	Close("OpenExistingFile");
	
EndProcedure

&AtClient
Procedure Into(Command)
	
	Close("Into");
	
EndProcedure

&AtClient
Procedure GetFromApplication(Command)
	
	Close("GetFromStorageAndOpen");
	
EndProcedure

&AtClient
Procedure DontPut(Command)
	
	Close("DontPut");
	
EndProcedure

&AtClient
Procedure OpenDirectory(Command)
	
	FilesOperationsInternalClient.OpenExplorerWithFile(FullFileNameInWorkingDirectory);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close("Cancel");
	
EndProcedure

#EndRegion
