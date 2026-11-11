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
	
	Parameters.Property("ObjectWithIssue", ObjectWithIssue);
	Parameters.Property("LongDesc", LongDesc);
	Parameters.Property("WarningType", WarningType);
	Parameters.Property("InfobaseNode", InfobaseNode);
	Parameters.Property("HideWarning", HideWarning);
	Parameters.Property("OccurrenceDate", OccurrenceDate);
	Parameters.Property("MetadataObject", MetadataObject);
	Parameters.Property("UniqueKey", InformationRegisterRecordUniqueKey);
	Parameters.Property("WarningComment", WarningComment);
	
	HideFromListFlagUpdateRequired = False;
	CommentUpdateRequired = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ChangeThePictureOfTheScenery()
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HideWarningOnChange(Item)
	
	HideFromListFlagUpdateRequired = True;
	
	If HideWarning Then
		
		Items.PictureDecoration.Picture = PictureLib.Information32;
		
	Else
		
		Items.PictureDecoration.Picture = PictureLib.Error32;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectWithIssueClick(Item, StandardProcessing)
	
	HideFromListFlagUpdateRequired = True;
	
EndProcedure

&AtClient
Procedure WarningCommentOnChange(Item)
	
	CommentUpdateRequired = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	BeforeCloseAtServer();
	
	If HideFromListFlagUpdateRequired
		Or CommentUpdateRequired Then
		
		Close(New Structure("TheListNeedsToBeUpdated", True));
		
	Else
		
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeThePictureOfTheScenery()
	
	If HideWarning Then
		
		Items.PictureDecoration.Picture = PictureLib.Information32;
		
	Else
		
		Items.PictureDecoration.Picture = PictureLib.Error32;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeCloseAtServer()
	
	If Not HideFromListFlagUpdateRequired
		And Not CommentUpdateRequired Then
		
		Return;
		
	EndIf;
	
	BeginTransaction();
	
	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("InformationRegister.DataExchangeResults");
		DataLockItem.SetValue("IssueType", WarningType);
		DataLockItem.SetValue("InfobaseNode", InfobaseNode);
		DataLockItem.SetValue("MetadataObject", MetadataObject);
		DataLockItem.SetValue("ObjectWithIssue", ObjectWithIssue);
		DataLockItem.SetValue("UniqueKey", InformationRegisterRecordUniqueKey);
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();

		RecordManager = InformationRegisters.DataExchangeResults.CreateRecordManager();
		RecordManager.IssueType = WarningType;
		RecordManager.InfobaseNode = InfobaseNode;
		RecordManager.MetadataObject = MetadataObject;
		RecordManager.ObjectWithIssue = ObjectWithIssue;
		RecordManager.UniqueKey = InformationRegisterRecordUniqueKey;

		RecordManager.Read(); // Read data to save the attributes that won't be passed to the form.
		If Not RecordManager.Selected() Then
		
			// Use case: A user opened the warning dialog and fixed the issue.
			CommitTransaction();
			Return;

		EndIf;

		RecordManager.OccurrenceDate = OccurrenceDate;
		RecordManager.Comment = WarningComment;
		RecordManager.IsSkipped = HideWarning;

		RecordManager.Write(True);

		CommitTransaction();
	Except
		RollbackTransaction();

		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

		Event = NStr("vi = 'Обмен данными.Запись результата обмена данными';
					|ru = 'Обмен данными.Запись результата обмена данными';
					|en = 'Data exchange.Record data exchange result'; fa = 'Data exchange.Record data exchange result';
					|it = 'Обмен данными.Запись результата обмена данными';
					|pl = 'Data exchange.Record data exchange result';
					|tr = 'Обмен данными.Запись результата обмена данными'", Common.DefaultLanguageCode());

		WriteLogEvent(Event, EventLogLevel.Error,
			Metadata.InformationRegisters.DataExchangeResults, , ErrorMessage);
	EndTry;
	
EndProcedure

#EndRegion
