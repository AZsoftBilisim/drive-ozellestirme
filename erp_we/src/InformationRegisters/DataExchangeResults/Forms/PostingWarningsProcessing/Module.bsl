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
	
	If Not Parameters.Property("DataForSelectedRows") Then
		
		Raise NStr("vi = 'Không cho phép sử dụng độc lập biểu mẫu.';
					|ru = 'Самостоятельное использование формы не предусмотрено.';
					|en = 'The form cannot be used independently.'; fa = 'The form cannot be used independently.';
					|it = 'Utilizzo autonomo del modulo non previsto.';
					|pl = 'Samodzielne użycie formularza nie jest przewidziane.';
					|tr = 'Form bağımsız kullanılamaz. '", Common.DefaultLanguageCode());
		
	EndIf;
	
	ConditionalFormDesign();
	FillInTheFormTable();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostDocuments(Command)
	
	ParametersOfTheEvent = New Structure;
	ParametersOfTheEvent.Insert("NumberOfDaysSpent", 0);
	ParametersOfTheEvent.Insert("TotalCount1", 0);
	
	HoldDocumentsOnTheServer(ParametersOfTheEvent);
	
	If ParametersOfTheEvent.NumberOfDaysSpent > 0 Then
		
		Notify("CorrectionOfDocumentSynchronizationWarnings");
		
	EndIf;
	
	ClearMessages();
	If ParametersOfTheEvent.NumberOfDaysSpent <> ParametersOfTheEvent.TotalCount1 Then
		
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã kết chuyển %1 trong số %2 chứng từ.';
				|ru = 'Проведено документов %1 из %2.';
				|en = 'Posted documents: %1 from %2.'; fa = 'Posted documents: %1 from %2.';
				|it = 'Pubblicati documenti %1 di %2.';
				|pl = 'Zatwierdzono dokumentów %1 z %2.';
				|tr = 'Geçirilen belgeler %1 / %2.'"),
			Format(ParametersOfTheEvent.NumberOfDaysSpent, "NZ=; NG=0"),
			Format(ParametersOfTheEvent.TotalCount1, "NZ=; NG=0"));
		
		ShowMessageBox(Undefined, ErrorMessage);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	ChangeTheLineMark(True);
	
EndProcedure

&AtClient
Procedure RemoveSelection(Command)
	
	ChangeTheLineMark(False);
	
EndProcedure

&AtClient
Procedure PostInDeveloperMode(Command)
	
	Items.PatchObjectsTablePostInDeveloperMode.Check 
		= Not Items.PatchObjectsTablePostInDeveloperMode.Check;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeTheLineMark(MarkValue)
	
	For Each SelectedRow In PatchObjectsTable Do
		
		SelectedRow.ProcessString = MarkValue;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ConditionalFormDesign()
	
	ErrorsInRed = ConditionalAppearance.Items.Add();
	
	CommonClientServer.AddCompositionItem(ErrorsInRed.Filter, "PatchObjectsTable.UnsuccessfulAttempt", DataCompositionComparisonType.Equal, True);
	ErrorsInRed.Appearance.SetParameterValue("TextColor", WebColors.DarkRed);
	
	AppearanceField = ErrorsInRed.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("PatchObjectsTableObjectWithIssue");
	AppearanceField = ErrorsInRed.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("TableOfObjectsOfCorrectionTheResultOfThe");
	AppearanceField = ErrorsInRed.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("PatchObjectsTableUnsuccessfulAttempt");
	
EndProcedure

&AtServer
Procedure FillInTheFormTable()
	
	If TypeOf(Parameters.DataForSelectedRows) <> Type("Array") Then
		
		Return;
		
	EndIf;
	
	For Each ObjectWithIssue In Parameters.DataForSelectedRows Do
		
		NewRow = PatchObjectsTable.Add();
		NewRow.ProcessString = True;
		NewRow.ObjectWithIssue = ObjectWithIssue;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure HoldDocumentsOnTheServer(ParametersOfTheEvent)
	
	WarningTemplate = NStr("vi = 'Chứng từ [%1] chưa kết chuyển do lỗi kiểm tra điền.
		|Để sửa lỗi, hãy mở chứng từ và kết chuyển thủ công.';
		|ru = 'Документ [%1] не проводился из-за ошибок проверки заполнения. 
		|Для устранения проблемы откройте документ и выполните проведение в ручном режиме.';
		|en = 'The [%1] document was not posted due to filling check errors. 
		|To fix the issue, open the document and post it manually.'; fa = 'The [%1] document was not posted due to filling check errors. 
		|To fix the issue, open the document and post it manually.';
		|it = 'Il documento [%1] non è stato pubblicato a causa di un errore di verifica della compilazione. 
		|Per la risoluzione del problema, aprire il documento ed eseguire la pubblicazione in modalità manuale.';
		|pl = 'Dokument [%1] nie był zatwierdzony z powodu błędów sprawdzenia wypełnienia. 
		|W celu rozwiązania problemów otwórz dokument i zatwierdź dokument ręcznie.';
		|tr = 'Belge [%1] dolduruma kontrolü hataları nedeniyle geçirilmedi. 
		|Sorunun çözümü için belgeyi açık ve manüel olarak geçirmeyi deneyin.'", Common.DefaultLanguageCode());
	
	
	For Each SelectedRow In PatchObjectsTable Do
		
		If Not SelectedRow.ProcessString Then
			
			Continue;
			
		EndIf;
		
		ParametersOfTheEvent.TotalCount1 = ParametersOfTheEvent.TotalCount1 + 1;
		
		BeginTransaction();
		Try
			
			LockDataForEdit(SelectedRow.ObjectWithIssue);
			
			DocumentObject = SelectedRow.ObjectWithIssue.GetObject();
			If DocumentObject.CheckFilling() Then
				
				If Items.PatchObjectsTablePostInDeveloperMode.Check Then
					
					DocumentObject.DataExchange.Load = True;
					
				EndIf;
				
				DocumentObject.Write(DocumentWriteMode.Posting);
				
				SelectedRow.PatchResult = NStr("vi = 'Chứng từ đã được kết chuyển thành công.';
												|ru = 'Документ успешно проведен.';
												|en = 'Document successfully posted.'; fa = 'Document successfully posted.';
												|it = 'Documento pubblicato con successo.';
												|pl = 'Dokument został pomyślnie zatwierdzony.';
												|tr = 'Belge başarıyla geçirildi.'");
				ParametersOfTheEvent.NumberOfDaysSpent = ParametersOfTheEvent.NumberOfDaysSpent + 1;
				
			Else
				
				SelectedRow.PatchResult = StrTemplate(WarningTemplate, SelectedRow.ObjectWithIssue);
				SelectedRow.UnsuccessfulAttempt = True;
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			SelectedRow.PatchResult = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			SelectedRow.UnsuccessfulAttempt = True;
			
		EndTry;
		
	EndDo;
	
	
EndProcedure

#EndRegion
