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
	Result.Add("IsRequired");
	Result.Add("Notes");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

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
		|	QuestionnaireTemplateQuestions.Ref
		|FROM
		|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
		|WHERE
		|	QuestionnaireTemplateQuestions.HintPlacement = &EmptyRef";
	Query.Parameters.Insert("EmptyRef", Enums.TooltipDisplayMethods.EmptyRef());
	
	Result = Query.Execute().Unload();
	ReferencesArrray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// Assign a value to the HintPlacement attribute in the QuestionnaireTemplateQuestions catalog.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.QuestionnaireTemplateQuestions");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While Selection.Next() Do
		RepresentationOfTheReference = String(Selection.Ref);
		Try
			
			FillTooltipDisplayMethodAttribute(Selection);
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				Selection.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.QuestionnaireTemplateQuestions");
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý nhiều câu hòi trong mẫu bảng hỏi (đã bỏ qua):%1';
				|ru = 'Не удалось обработать некоторые вопросы шаблона анкеты (пропущены): %1';
				|en = 'Couldn''t process (skipped) some questionnaire template questions: %1'; fa = 'Couldn''t process (skipped) some questionnaire template questions: %1';
				|it = 'Non è stato possibile elaborare alcune domande di modello del questionario (saltate): %1';
				|pl = 'Nie udało się przetworzyć niektórych pytań szablonu ankiety (pominięte): %1';
				|tr = 'Soru formu şablonunun bazı soruları işlenemedi (atlandı): %1'"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.QuestionnaireTemplateQuestions,,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã xử lý tùy chọn theo trình tự các câu hỏi trong mẫu bảng hỏi: %1';
																				|ru = 'Обработана очередная порция вопросов шаблона анкеты: %1';
																				|en = 'Yet another batch of questionnaire template questions is processed: %1'; fa = 'Yet another batch of questionnaire template questions is processed: %1';
																				|it = 'È stata elaborata un''altra porzione di domande di modello di questionario: %1';
																				|pl = 'Przetworzono kolejną część pytań szablonu ankiety: %1';
																				|tr = 'Soru formu şablonunun yeni soru grubu işlendi: %1'"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Assign a value to the HintPlacement attribute in the passed object.
//
Procedure FillTooltipDisplayMethodAttribute(Selection)
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Catalog.QuestionnaireTemplateQuestions");
		LockItem.SetValue("Ref", Selection.Ref);
		Block.Lock();
		
		CatalogObject = Selection.Ref.GetObject();
		
		If CatalogObject.HintPlacement <> Enums.TooltipDisplayMethods.EmptyRef() Then
			RollbackTransaction();
			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			Return;
		EndIf;
		
		CatalogObject.HintPlacement = Enums.TooltipDisplayMethods.AsTooltip;
		
		InfobaseUpdate.WriteData(CatalogObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf
