//////////////////////////////////////////////////////////////////////////////////////////////
// Document verification: methods that work on the client side.
//  
//////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Executes the command To Change The Status Of The Document Verification,
// See DocumentCheckServerCall.ExecuteCommandToChangeDocumentVerificationStatus.
//
// Parameters:
//  Form - ClientApplicationForm - The form where the team is located;
//  Command - FormCommand - The command you want to execute.
//
Procedure ExecuteCommandToChangeDocumentVerificationStatus(Form, Command) Export
	
	If StrFind(Command.Name, "DocumentVerification_CommandToChangeDocumentVerificationStatus") And TMCommonUseClientServer.HasObjectAttribute(Form, "DocumentVerification_DocumentVerified") Then
		
		If Not Form.Object.Posted Then
			AdditionalNotificationParameters = New Structure("Form, Command, Posting", Form, Command, True);
			CallbackDescription = New CallbackDescription("NotificationHandlerQuestionBeforeChecking", ThisObject, AdditionalNotificationParameters);
			QueryText = NStr("vi = 'Chỉ có thể kiểm tra đối với các chứng từ đã kết chuyển. Kết chuyển chứng từ và tiếp tục thực hiện kiểm tra?';
							|ru = 'Проверка возможна только для проведенных документов. Провести документ и продолжить выполнение проверки?';
							|en = 'Check is available only for posted documents. Do you want to post the document and continue checking?'; fa = 'Check is available only for posted documents. Do you want to post the document and continue checking?';
							|it = 'LA verifica è possibile solo per i documenti pubblicati. Pubblicare il documento e continuare con la verifica?';
							|pl = 'Sprawdzenie jest możliwe tylko dla zatwierdzonych dokumentów. Zatwierdzić dokument i kontynuować wykonanie sprawdzenia?';
							|tr = 'Kontrol sadece deftere kaydedilen belgeler için mümkündür. Belgeyi kaydet kontrole devam edilsin mi?'");
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		ElsIf Form.Modified Then
			AdditionalNotificationParameters = New Structure("Form, Command", Form, Command);
			CallbackDescription = New CallbackDescription("NotificationHandlerQuestionBeforeChecking", ThisObject, AdditionalNotificationParameters);
			QueryText = NStr("vi = 'Đã thay đổi chứng từ. Để thay đổi trạng thái kiểm tra, cần ghi lại chứng từ. Tiếp tục?';
							|ru = 'Документ был изменен. Для изменения статуса проверки необходимо записать документ. Продолжить?';
							|en = 'Document was modified. To change the check status, save the document. Do you want to continue?'; fa = 'Document was modified. To change the check status, save the document. Do you want to continue?';
							|it = 'Documento modificato. Per la modifica dello stato di verifica è necessario salvare il documento. Continuare?';
							|pl = 'Dokument został zmieniony. Aby zmienić status sprawdzenia należy zapisać dokument. Kontynuować?';
							|tr = 'Belge değiştirildi. Kontrol durumunu değiştirmek için belgenin kaydedilmesi gerekir. Devam edilsin mi?'");
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Else
			ErrorData = New Map;
			Form.UnlockFormDataForEdit();
			DocumentCheckServerCall.ExecuteCommandToChangeDocumentVerificationStatus(Form.Object.Ref, ErrorData);
			If ErrorData.Count() Then
				ShowMessageBox(, ErrorData.Get(Form.Object.Ref), 15, NStr("vi = 'Không thể thay đổi trạng thái kiểm tra chứng từ';
																			|ru = 'Не удалось изменить статус проверки документа';
																			|en = 'Cannot change the document check status'; fa = 'Cannot change the document check status';
																			|it = 'Non è stato possibile modificare lo stato di verifica del documento';
																			|pl = 'Zmiana statusu sprawdzenia dokumentu nie powiodła się';
																			|tr = 'Belge doğrulama durumu değiştirilemedi'"));
			Else
				Notify("Record_DocumentVerificationStatus", Form.Object.Ref, Form);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// A procedure called from the form event handler of the same name. Checks if the alert is triggered by a new
// verification status-updates the command to change the form verification status and blocks the form if necessary (when
//            the document verification status is "Verified").
//
// Parameters:
//  Form - ClientApplicationForm - The Form from whose event handler the procedure is called:
//  	* Object - DocumentObject -
//  EventName - String - ID of the message in the receiving form (see the Notify method) ;
//	Parameter - Structure - message parameter (see Notify method) ;
//	Source - Arbitrary - the source of the event (see the Notify method).
//
Procedure NotificationProcessing(Form, EventName, Parameter, Source) Export
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "DocumentVerification_DocumentVerified") Then
		TypesOfDocumentsWithDisabledVerification = TypesOfDocumentsWithDisabledVerificationDuringBackgroundTesting();
		If EventName = "Record_DocumentVerificationStatus" Or StrStartsWith(EventName, "Record")
			And TypesOfDocumentsWithDisabledVerification.Find(TypeOf(Form.Object.Ref)) <> Undefined Then
			
			Form.Read();
			
		EndIf;
	EndIf;
	
EndProcedure

// A procedure called from the form event handler of the same name.
// When recording a verified document, you must display a warning that the document was checked and
// will be removed from verification when recording. The user will have the option to cancel the recording. This check will
// be called regardless of the hard / soft check option, since it is not possible to write the modified document during hard check.
//
// Parameters:
//  Form - ClientApplicationForm - The Form from whose event handler the procedure is called:
//  	* Object - DocumentObject -
//  Cancel - Boolean - flag for refusing to write a document;
//	WriteParameters - Structure - recording parameters (see the event before recording) .
//
Procedure BeforeWrite(Form, Cancel, WriteParameters) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "DocumentVerification_DocumentVerified")
		And TMCommonUseClientServer.HasObjectAttribute(Form, "DocumentVerification_RecordConfirmation")
		And Form.DocumentVerification_RecordConfirmation And Form.DocumentVerification_DocumentVerified Then
		
		If TMCommonUseClientServer.HasObjectAttribute(Form, "NotExecuteCheck1BeforeWrite") Then
			Form.NotExecuteCheck1BeforeWrite = True;
		EndIf;
		
		Cancel = True;
		
		AdditionalNotificationParameters = New Structure("Form, WriteParameters", Form, WriteParameters);
		CallbackDescription = New CallbackDescription("HandlerAlertQuestionBeforeRecording", ThisObject, AdditionalNotificationParameters);
		QueryText = NStr("vi = 'Chứng từ này đã được kiểm tra từ trước. Khi ghi lại chứng từ sẽ đánh dấu nó là cần kiểm tra lại. Tiếp tục?';
						|ru = 'Данный документ ранее был проверен. Запись документа пометит его к повторной проверке. Продолжить?';
						|en = 'This document has already been checked. If you save the document, it will be marked for recheck. Continue?'; fa = 'This document has already been checked. If you save the document, it will be marked for recheck. Continue?';
						|it = 'Questo documento è stato precedentemente verificato. Il salvataggio del documento lo contrassegna come nuova verifica. Continuare?';
						|pl = 'Niniejszy dokument wcześniej został sprawdzony. Zapisywanie dokumentu zaznacz go do ponownego sprawdzenia. Kontynuować?';
						|tr = 'Bu belge daha önce kontrol edildi. Bir belgenin kaydedilmesi, onu yeniden doğrulama için işaretleyecektir. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure HandlerAlertQuestionBeforeRecording(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		AdditionalParameters.Form.DocumentVerification_RecordConfirmation = False;
		If TMCommonUseClientServer.HasObjectAttribute(AdditionalParameters.Form, "NotExecuteCheck1BeforeWrite") Then
			AdditionalParameters.Form.NotExecuteCheck1BeforeWrite = False;
		EndIf;
		If AdditionalParameters.Form.Write(AdditionalParameters.WriteParameters) Then
			CloseForm_ = Undefined;
			AdditionalParameters.WriteParameters.Property("ForceCloseTheForm", CloseForm_);
			If CloseForm_ = True Then
				AdditionalParameters.Form.Close();
			Else
				Notify("Record_DocumentVerificationStatus");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure NotificationHandlerQuestionBeforeChecking(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes And AdditionalParameters.Property("Form") Then
		Form = AdditionalParameters.Form; // ManagedFormExtensionForDocuments -
		If TMCommonUseClientServer.HasObjectAttribute(Form, "DocumentVerification_RecordConfirmation") Then
			Form.DocumentVerification_RecordConfirmation = False;
		EndIf;
		RecordStructure = New Structure("WriteMode", DocumentWriteMode.Posting);
		RecordStructure = ?(AdditionalParameters.Property("Posting"), RecordStructure, Undefined);
		If Form.Write(RecordStructure) Then
			ExecuteCommandToChangeDocumentVerificationStatus(Form, AdditionalParameters.Command);
		EndIf;
	EndIf;
	
EndProcedure

Function TypesOfDocumentsWithDisabledVerificationDuringBackgroundTesting()
	
	ReturnArray = New Array;
	
	ReturnArray.Add(Type("DocumentRef.IssuedTaxInvoicePrepayment"));
	ReturnArray.Add(Type("DocumentRef.ReceivedTaxInvoicePrepayment"));
	
	DocumentVerificationClientLocalization.ToSupplementTypesOfDocumentsWithDisabledVerificationDuringBackgroundTesting(ReturnArray);
	
	Return ReturnArray;
	
EndFunction

#EndRegion
