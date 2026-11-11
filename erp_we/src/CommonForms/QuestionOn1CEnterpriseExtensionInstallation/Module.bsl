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
	
	If Not IsBlankString(Parameters.SuggestionText) Then
		Items.DecorationNote.Title = Parameters.SuggestionText
			+ Chars.LF
			+ NStr("vi = 'Cài đặt?';
					|ru = 'Установить?';
					|en = 'Do you want to install the extension?'; fa = 'Do you want to install the extension?';
					|it = 'Impostare?';
					|pl = 'Do you want to install the extension?';
					|tr = 'Ayarla?'");
		
	ElsIf Not Parameters.CanContinueWithoutInstalling Then
		Items.DecorationNote.Title =
			NStr("vi = 'Để thực hiện hành động này, cần cài đặt một tiện ích mở rộng để làm việc với 1C:Enterprise.
			           |Cài đặt?';
			           |ru = 'Для выполнения действия требуется установить расширение для работы с 1С:Предприятием.
			           |Установить?';
			           |en = 'This operation requires 1C:Enterprise Extension.
			           |Do you want to install it?'; fa = 'This operation requires 1C:Enterprise Extension.
			           |Do you want to install it?';
			           |it = 'Per eseguire l''azione, è necessario installare un''estensione di lavoro con 1C:Enterprise.
			           |Installare?';
			           |pl = 'Aby wykonać działanie, należy zainstalować rozszerzenie do pracy z 1C:Enterprise.
			           |Zainstalować?';
			           |tr = 'İşlemin yürütülmesi için 1C:Enterprise web istemcisi eklentisinin yüklenmesi gerekiyor.
			           |Eklenti yüklensin mi?'");
	EndIf;
	
	If Not Parameters.CanContinueWithoutInstalling Then
		Items.ContinueWithoutInstalling.Title = NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InstallAndContinue(Command)
	
	Notification = New CallbackDescription("InstallAndContinueCompletion", ThisObject);
	BeginInstallFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure ContinueWithoutInstalling(Command)
	
	Close("DoNotPrompt");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure InstallAndContinueCompletion(Context) Export
	
	Notification = New CallbackDescription("InstallAndContinueAfterAttachExtension", ThisObject);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure InstallAndContinueAfterAttachExtension(Attached, Context) Export
	
	If Attached Then
		Close("ExtensionAttached");
	Else
		Close("ContinueWithoutInstalling");
	EndIf;
	
EndProcedure

#EndRegion
