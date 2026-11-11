///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Parameters:
//  Ref  - CatalogRef.IncomingEmailAttachedFiles,
//            CatalogRef.IncomingEmailAttachedFiles - a reference to file that
//                                                                            is to be opened.
//
Procedure OpenAttachment(Ref, Form, ForEditing = False) Export

	FileData = FilesOperationsInternalServerCall.NameAndExtensionOfFile(Ref);
	
	If Form.RestrictedExtensions.FindByValue(FileData.Extension) <> Undefined Then

		AdditionalParameters = New Structure("ForEditing", ForEditing);
		AdditionalParameters.Insert("AttachedFile", Ref);
		AdditionalParameters.Insert("Form", Form);

		Notification = New CallbackDescription("OpenFileAfterConfirm", ThisObject, AdditionalParameters);
		UsersInternalClient.ShowSecurityWarning(Notification,
			UsersInternalClientServer.SecurityWarningKinds().BeforeOpenFile,
			FileData.FileName);
		Return;
		
	EndIf;

	OpenAttachmentFile(Ref, Form, ForEditing);

EndProcedure

Procedure OpenFileAfterConfirm(Result, AdditionalParameters) Export

	If Result <> Undefined And Result = "Continue" Then

		OpenAttachmentFile(AdditionalParameters.AttachedFile, 
								AdditionalParameters.Form, 
								AdditionalParameters.ForEditing);
	EndIf;

EndProcedure

Procedure OpenAttachmentFile(Ref, Form, ForEditing)
	
	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("OpenFile", "FilesOperationsInternal.FileDataEmailManagementAsync");
	FileGettingParameters.AttachedFile	= Ref;
	FileGettingParameters.OwnerForm 		= Form;

	FileGettingParameters.ActionParameters.ForEditing = ForEditing;

	FilesOperationsClient.OpenFile(FileGettingParameters);	
	
EndProcedure

// Parameters:
//  TableOfContacts - FormDataCollection - contains descriptions and references to interaction contacts
//                                            or interaction subject participants.
//
// Returns:
//  Array of Structure:
//    * Address - String
//    * Presentation - String
//    * Contact - Arbitrary 
//
Function ContactsTableToArray(TableOfContacts) Export
	
	Result = New Array;
	For Each TableRow In TableOfContacts Do
		Contact = ?(TypeOf(TableRow.Contact) = Type("String"), Undefined, TableRow.Contact);
		Record = New Structure(
		"Address, Presentation, Contact", TableRow.Address, TableRow.Presentation, Contact);
		Result.Add(Record);
	EndDo;
	
	Return Result;
	
EndFunction

// Get email by all available accounts.
// 
// Parameters:
//  ItemList - FormField - a form item that has to be updated after getting emails.
//
Procedure SendReceiveUserEmail(UUID, Form, ItemList = Undefined, DisplayProgress = True) Export

	TimeConsumingOperation =  InteractionsServerCall.SendReceiveUserEmailInBackground(UUID);
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	Form.SendReceiveEmailInProgress = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemList",       ItemList);
	AdditionalParameters.Insert("URL", Undefined);
	AdditionalParameters.Insert("Form",               Form);
	AdditionalParameters.Insert("DisplayProgress",    DisplayProgress);
	If Form.Window <> Undefined Then
		AdditionalParameters.URL = Form.Window.GetURL();
	EndIf;	
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	If DisplayProgress Then
		IdleParameters.OutputProgressBar = True;
	Else
		IdleParameters.OutputIdleWindow = False;
	EndIf;
	CallbackOnCompletion = New CallbackDescription("SendReceiveUserEmailCompletion", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// The processing of user email import completion
// 
// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Structure:
//   * ItemList - FormTable - an item containing a dynamic list.
//
Procedure SendReceiveUserEmailCompletion(Result, AdditionalParameters) Export
	
	AdditionalParameters.Form.SendReceiveEmailInProgress = False;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		If AdditionalParameters.ItemList <> Undefined 
		     And AdditionalParameters.ItemList.Visible
		     And AdditionalParameters.ItemList.CurrentData <> Undefined Then
			AdditionalParameters.ItemList.Refresh();
		EndIf;
		
		AdditionalParameters.Form.DateOfPreviousEmailReceiptSending = CommonClient.SessionDate();
		
		If AdditionalParameters.DisplayProgress Then
		
			Title = NStr("vi = 'Gửi và nhận thư';
						|ru = 'Отправка и получение почты';
						|en = 'Mail Sync'; fa = 'Mail Sync';
						|it = 'Invio e ricezione della posta';
						|pl = 'Wysyłanie i odbieranie poczty';
						|tr = 'E-posta gönder ve al'");
			ExecutionResult = GetFromTempStorage(Result.ResultAddress);
			If ExecutionResult.HasErrors Then
				ShowUserNotification(Title, "e1cib/app/DataProcessor.EventLog", 
					NStr("vi = 'Không thể hoàn thành tất cả thao tác. Chi tiết kỹ thuật cho người quản trị trong nhật ký sự kiện.';
						|ru = 'Не удалось выполнить все действия. Технические подробности для администратора в журнале регистрации.';
						|en = 'Not all the mail has been synced. See the event log for details.'; fa = 'Not all the mail has been synced. See the event log for details.';
						|it = 'Non è stato possibile eseguire tutte le azioni. I dettagli tecnici per l''amministratore si trovano nel registro.';
						|pl = 'Nie udało się wykonać wszystkie działania. Szczegóły techniczne dla administratora w dzienniku rejestracji.';
						|tr = 'Tüm işlemler gerçekleştirilemiyor. Yöneticiyseniz, lütfen ayrıntılar için kayıt günlüğüne bakın.'"), 
					PictureLib.Warning, UserNotificationStatus.Important);
			Else	
				ShowUserNotification(Title, AdditionalParameters.URL,
					EmailsSendingReceivingResult(ExecutionResult));
			EndIf;
			
		EndIf;
		
		Notify("SendAndReceiveEmailDone");
	EndIf;
	
EndProcedure

Function EmailsSendingReceivingResult(ExecutionResult)
	
	If ExecutionResult.EmailsReceived1 > 0 And ExecutionResult.SentEmails1 > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã nhận: %1, đã gửi: %2';
																					|ru = 'Получено: %1, отправлено: %2';
																					|en = 'Received: %1; Sent: %2'; fa = 'Received: %1; Sent: %2';
																					|it = 'Ricevuto: %1, inviato: %2';
																					|pl = 'Otrzymano: %1, wysłano: %2';
																					|tr = 'Alındı: %1 gönderildi: %2'"), 
			ExecutionResult.EmailsReceived1, ExecutionResult.SentEmails1);
	ElsIf ExecutionResult.EmailsReceived1 > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã nhận: %1';
																					|ru = 'Получено: %1';
																					|en = 'Received: %1'; fa = 'Received: %1';
																					|it = 'Ricevuto: %1';
																					|pl = 'Otrzymano: %1';
																					|tr = 'Alındı: %1'"), 
			ExecutionResult.EmailsReceived1);
	ElsIf ExecutionResult.SentEmails1 > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã gửi: %1';
																					|ru = 'Отправлено: %1';
																					|en = 'Sent: %1'; fa = 'Sent: %1';
																					|it = 'Inviato: %1';
																					|pl = 'Wysłano: %1';
																					|tr = 'Gönderildi: %1'"), 
			ExecutionResult.SentEmails1);
	Else
		MessageText = NStr("vi = 'Không có email mới';
							|ru = 'Нет новых писем';
							|en = 'No new messages.'; fa = 'No new messages.';
							|it = 'Non ci sono nuove lettere';
							|pl = 'Brak nowych wiadomości';
							|tr = 'Yeni e-posta yok'");
	EndIf;	
	If ExecutionResult.UserAccountsAvailable > 1 Then
		MessageText = MessageText + Chars.LF  
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(tài khoản: %1)';
																			|ru = '(учетных записей: %1)';
																			|en = 'Accounts synced: %1'; fa = 'Accounts synced: %1';
																			|it = '(account: %1)';
																			|pl = '(kont: %1)';
																			|tr = '(hesaplar: %1)'"),
				ExecutionResult.UserAccountsAvailable);
	EndIf;
	
	Return MessageText;
	
EndFunction

#EndRegion
