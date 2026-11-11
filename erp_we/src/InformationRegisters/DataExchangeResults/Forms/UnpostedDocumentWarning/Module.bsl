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

&AtClient
Procedure PostDocument(Command)
	
	HideFromListFlagUpdateRequired = True;
	
	ClearMessages();
	ErrorMessage = "";
	
	PostDocuments(ObjectWithIssue, ErrorMessage);
	
	If Not IsBlankString(ErrorMessage) Then
		
		ShowMessageBox(, ErrorMessage);
		
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

&AtServer
Procedure PostDocuments(ObjectWithIssue, ErrorMessage)
	
	BeginTransaction();
	Try
		
		LockDataForEdit(ObjectWithIssue);
		
		DocumentObject = ObjectWithIssue.GetObject();
		If DocumentObject.CheckFilling() Then
			
			DocumentObject.Write(DocumentWriteMode.Posting);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageTemplate = NStr("vi = 'Không thể kết chuyển chứng từ ""%1"" do nguyên nhân:%2 %3.';
								|ru = 'Не удалось провести документ ""%1"" по причине:%2 %3.';
								|en = 'Cannot post the document ""%1"" due to:%2 %3.'; fa = 'Cannot post the document ""%1"" due to:%2 %3.';
								|it = 'Non è stato possibile pubblicare il documento ""%1"" a causa di:%2 %3.';
								|pl = 'Nie udało się zaksięgować dokument ""%1"" z powodu:%2 %3.';
								|tr = '""%1"" belgesi bu nedenle geçirilemedi:%2 %3.'", Common.DefaultLanguageCode());
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ObjectWithIssue, Chars.LF, ErrorPresentation));
			
	EndTry;
	
EndProcedure

#EndRegion
