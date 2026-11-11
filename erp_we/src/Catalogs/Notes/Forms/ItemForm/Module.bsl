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
	
	If ValueIsFilled(Parameters.SubjectOf) Then
		Object.SubjectOf = Parameters.SubjectOf;
		Object.SubjectPresentation = Common.SubjectString(Object.SubjectOf);
	EndIf;
	
	Items.SubjectOf.Title = Object.SubjectPresentation;
	Items.SubjectGroup.Visible = ValueIsFilled(Object.SubjectOf);
	
	If Object.Ref.IsEmpty() Then
		Object.Author = Users.CurrentUser();
		FormattedText = Parameters.CopyingValue.Content.Get();
		
		Items.NoteDate.Title = NStr("vi = 'Chưa ghi lại';
									|ru = 'Не записано';
									|en = 'Not saved'; fa = 'Not saved';
									|it = 'Non scritto';
									|pl = 'Nie zapisano';
									|tr = 'Kaydedilmedi'")
	Else
		Items.NoteDate.Title = NStr("vi = 'Đã ghi lại';
									|ru = 'Записано';
									|en = 'Saved'; fa = 'ذخیره‌شده';
									|it = 'Scritto';
									|pl = 'Saved';
									|tr = 'Kaydedildi'") + ": " + Format(Object.ChangeDate, "DLF=DDT");
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	FormattedText = CurrentObject.Content.Get();

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Content = New ValueStorage(FormattedText, New Deflation(9));
	
	HTMLText = "";
	Attachments = New Structure;
	FormattedText.GetHTML(HTMLText, Attachments);
	
	CurrentObject.ContentText = StringFunctionsClientServer.ExtractTextFromHTML(HTMLText);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	Items.NoteDate.Title = NStr("vi = 'Đã ghi lại';
								|ru = 'Записано';
								|en = 'Saved'; fa = 'ذخیره‌شده';
								|it = 'Scritto';
								|pl = 'Saved';
								|tr = 'Kaydedildi'") + ": " + Format(Object.ChangeDate, "DLF=DDT");
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotifyChanged(Object.Ref);
	If ValueIsFilled(Object.SubjectOf) Then
		NotifyChanged(Object.SubjectOf);
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SubjectOfClick(Item)
	ShowValue(,Object.SubjectOf);
EndProcedure

&AtClient
Procedure AuthorClick(Item)
	ShowValue(,Object.Author);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetVisibility1()
	Items.Author.Title = Object.Author;
	OpenedByAuthor = Object.Author = Users.CurrentUser();
	Items.DisplayParameters.Visible = OpenedByAuthor;
	Items.AuthorInfo.Visible = Not OpenedByAuthor;
	
	ReadOnly = Not OpenedByAuthor;
	Items.Content.ReadOnly = Not OpenedByAuthor;
	Items.EditingCommandBar.Visible = OpenedByAuthor;
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
