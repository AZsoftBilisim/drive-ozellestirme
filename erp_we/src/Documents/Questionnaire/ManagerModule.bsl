///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("Respondent");
	Result.Add("EditDate");
	Result.Add("Comment");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsAuthorizedUser(Respondent)
	|	OR IsAuthorizedUser(Interviewer)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS Questionnaire
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersRespondent
	|	ON ExternalUsersRespondent.AuthorizationObject = Questionnaire.Respondent
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersInterviewer
	|	ON ExternalUsersInterviewer.AuthorizationObject = Questionnaire.Interviewer
	|;
	|AllowReadUpdate
	|WHERE
	|	IsAuthorizedUser(ExternalUsersRespondent.Ref)
	|	OR IsAuthorizedUser(ExternalUsersInterviewer.Ref)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

// Registers the objects to be updated in the InfobaseUpdate exchange plan.
// 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Questionnaire.Ref
		|FROM
		|	Document.Questionnaire AS Questionnaire
		|WHERE
		|	Questionnaire.SurveyMode = &EmptyRef
		|
		|ORDER BY
		|	Questionnaire.Date DESC";
	Query.Parameters.Insert("EmptyRef", Enums.SurveyModes.EmptyRef());
	
	Result = Query.Execute().Unload();
	ReferencesArrray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// Fill in a value of the new SurveyMode attribute in the Questionnaire document.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Document.Questionnaire");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While Selection.Next() Do
		RepresentationOfTheReference = String(Selection.Ref);
		Try
			
			FillSurveyModeAttribute(Selection);
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				Selection.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Document.Questionnaire");
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý nhiều bảng câu hỏi (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые анкеты (пропущены): %1';
				|en = 'Couldn''t process (skipped) some questionnaire: %1'; fa = 'Couldn''t process (skipped) some questionnaire: %1';
				|it = 'Non è stato possibile elaborare alcuni questionari (saltati): %1';
				|pl = 'Nie udało się przetworzyć niektórych ankiet (pominięte): %1';
				|tr = 'Bazı soru formları işlenemedi (atlandı): %1'"), ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Documents.Questionnaire,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xử lý một loạt bảng câu hỏi khác: %1';
					|ru = 'Обработана очередная порция анкет: %1';
					|en = 'Yet another batch of questionnaires is processed: %1'; fa = 'Yet another batch of questionnaires is processed: %1';
					|it = 'È stata elaborata una nuova parte di questionari: %1';
					|pl = 'Przetworzono kolejną część ankiet: %1';
					|tr = 'İşlenen başka bir soru formu grubu: %1'"), ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills a value of the new SurveyMode attribute in the passed document.
//
Procedure FillSurveyModeAttribute(Selection)
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Document.Questionnaire");
		LockItem.SetValue("Ref", Selection.Ref);
		Block.Lock();
		
		DocumentObject = Selection.Ref.GetObject();
		
		If DocumentObject.SurveyMode <> Enums.SurveyModes.EmptyRef() Then
			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			CommitTransaction();
			Return;
		EndIf;
		
		DocumentObject.SurveyMode = Enums.SurveyModes.Questionnaire;
		
		InfobaseUpdate.WriteData(DocumentObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf