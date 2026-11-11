///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Creates a support ticket. Attachments:
// - Technical information.txt
//   - Event log.xml
//   - Screenshot.png (optional)
//   - Additional files (optional)
//   - Options for opening a support ticket depending on the integrated subsystems
//
// (from most preferred to least preferred):
//  1. Via online support. Requires the subsystem "OnlineUserSupport.MessagesToTechSupportService".
//  2. Via email. Requires the subsystem: "StandardSubsystems.EmailOperations".
//  3. Via saving a file.
//
// Parameters:
//  Form              - ClientApplicationForm - Owner.
//  RequestParameters_ - See SupportRequestsInternalClient.RequestParameters_
//
Procedure SubmitSupportTicket(Form, RequestParameters_) Export
	
	If Not IsScreenshotAppAvailable() Then
		ContinueSubmitSupportTicket(Undefined, RequestParameters_);
		Return;
	EndIf;
	
	// JPG and PNG files cannot be attached to support tickets.
	If IsMessagesToTechSupportServiceAvailable() Then
		ContinueSubmitSupportTicket(Undefined, RequestParameters_);
		Return;
	EndIf;
	
	If Form.Items.Find("AssistanceRequiredGroup") <> Undefined Then
		Form.Items.AssistanceRequiredGroup.Hide();
	EndIf;
	
	CompletionHandler = New CallbackDescription(
		"ContinueSubmitSupportTicket",
		ThisObject,
		RequestParameters_);
	
	RequestTakeScreenshot(CompletionHandler);
	
EndProcedure

// Downloads a file with technical details to be attached to the support ticket.
// The ZIP archive contains:
//   - Technical information.txt
//   - Event log.xml
//   - Screenshot.png (optional)
//   - Additional files (optional)
//
// Parameters:
//  Form              - ClientApplicationForm - Owner.
//  RequestParameters_ - See SupportRequestsInternalClient.RequestParameters_
//
Procedure DownloadInfoForSupport(Form, RequestParameters_) Export
	
	If Not IsScreenshotAppAvailable() Then
		ContinueDownloadInfoForSupport(Undefined, RequestParameters_);
		Return;
	EndIf;
	
	If Form.Items.Find("AssistanceRequiredGroup") <> Undefined Then
		Form.Items.AssistanceRequiredGroup.Hide();
	EndIf;
	
	CompletionHandler = New CallbackDescription(
		"ContinueDownloadInfoForSupport",
		ThisObject,
		RequestParameters_);
	
	RequestTakeScreenshot(CompletionHandler);
	
EndProcedure

// Ticket parameter constructor.
//
// Returns:
//  Structure:
//    * TechnologicalInfo - String - The reason for the request. (The content of the "Technical information.txt" file.)
//    * EventLogFilter   - Structure - An event log filter. Same as the filter used in the
//                                              "UnloadEventLog" method.
//    * Recipient                - See SupportRequestRecipient. Intended only to create a support ticket.
//    * RecipientAddress           - See SupportRequestRecipientAddress. Intended only to create a support ticket.
//    * Subject                      - String - Ticket subject. Intended only to create a support ticket.
//    * Message                 - See SupportMessageText. Intended only to create a support ticket.
//    * AdditionalFiles       - Array of See SupportRequestsInternalClient.AdditionalFileData.
//
Function RequestParameters_() Export
	
	Result = New Structure;
	Result.Insert("TechnologicalInfo", StandardSubsystemsClient.SupportInformation());
	Result.Insert("EventLogFilter",   New Structure);
	Result.Insert("Recipient",                SupportRequestRecipient());
	Result.Insert("RecipientAddress",           SupportRequestRecipientAddress());
	Result.Insert("Subject",                      "");
	Result.Insert("Message",                 SupportMessageText());
	Result.Insert("AdditionalFiles",       New Array);
	
	Return Result;
	
EndFunction

// Additional file data constructor.
//
// Parameters:
//  FileAddress - String - File address in temporary storage with the "BinaryData" data type.
//  FullFileName - String - Full filename. For example, "Technical information.txt".
//
// Returns:
//  Structure:
//    * FileAddress - String
//    * FullFileName - String
//
Function AdditionalFileData(FileAddress, FullFileName) Export
	
	Result = New Structure;
	Result.Insert("FileAddress", FileAddress);
	Result.Insert("FullFileName", FullFileName);
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.DigitalSignature

// Validates if the "Messages to technical support" subsystem is available.
// The subsystem is available if external resource management is enabled.
//
// Returns:
//  Boolean - "True" if creating support tickets is available.
//
Function IsMessagesToTechSupportServiceAvailable() Export
	
	SubsystemExists = CommonClient.SubsystemExists(
		"OnlineUserSupport.MessagesToTechSupportService");
	
	IsOperationsWithExternalResourcesAvailable =
		SupportRequestsInternalServerCall.IsOperationsWithExternalResourcesAvailable();
	
	Return SubsystemExists And IsOperationsWithExternalResourcesAvailable;
	
EndFunction

// Validates that the screenshot tool is available.
//
// Returns:
//  Boolean - "True" if the screenshot tool is available. Otherwise, "False".
//
Function IsScreenshotAppAvailable() Export
	
	Return CommonClient.IsWindowsClient() And ClipboardTools.CanUse();
	
EndFunction

// Requests user confirmation to take a screenshot.
// If confirmation is received, it launches the screenshot application.
// The application captures a screenshot and passes it to the specified completion handler.
//
// Parameters:
//  CompletionHandler - CallbackDescription, Undefined - Completion handler that is called after the screenshot is saved.
//                                                            Returns a structure. See SupportRequestsInternalClient.AdditionalFileData.
//
Procedure RequestTakeScreenshot(CompletionHandler = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	
	Notification = New CallbackDescription("AfterRequestTakeScreenshot", ThisObject, AdditionalParameters);
	
	QueryText = NStr("vi = 'Nên tạo ảnh chụp màn hình. Cần chọn toàn bộ màn hình hoặc vùng có nội dung của sự cố đã xảy ra.';
					|ru = 'Рекомендуется создать снимок экрана. Необходимо выделить весь экран или область с текстом возникшей проблемы.';
					|en = 'We recommend taking a screenshot of the entire screen or the area containing the error message.'; fa = 'We recommend taking a screenshot of the entire screen or the area containing the error message.';
					|it = 'We recommend taking a screenshot of the entire screen or the area containing the error message.';
					|pl = 'We recommend taking a screenshot of the entire screen or the area containing the error message.';
					|tr = 'Ekran görüntüsü almanız önerilmektedir. Ekranın tamamını veya sorunun bulunduğu metin alanını seçmeniz gerekmektedir.'");
	
	Buttons = New ValueList();
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tạo ảnh chụp màn hình';
											|ru = 'Создать снимок экрана';
											|en = 'Take screenshot'; fa = 'Take screenshot';
											|it = 'Take screenshot';
											|pl = 'Take screenshot';
											|tr = 'Ekran görüntüsü oluştur'"));
	Buttons.Add(DialogReturnCode.Ignore, NStr("vi = 'Bỏ qua';
												|ru = 'Пропустить';
												|en = 'Skip'; fa = 'رد کردن';
												|it = 'Skip';
												|pl = 'Skip';
												|tr = 'Atla'"));
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = NStr("vi = 'Tạo thông tin kỹ thuật';
									|ru = 'Формирование технической информации';
									|en = 'Generate technical information'; fa = 'Generate technical information';
									|it = 'Generate technical information';
									|pl = 'Generate technical information';
									|tr = 'Teknik bilgilerin oluşturulması'");
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.DefaultButton = DialogReturnCode.Yes;
	
	StandardSubsystemsClient.ShowQuestionToUser(Notification, QueryText, Buttons, QuestionParameters);
	
EndProcedure

// End StandardSubsystems.DigitalSignature

#EndRegion

#EndRegion

#Region Private

#Region Screenshot

Procedure AfterRequestTakeScreenshot(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = DialogReturnCode.Yes Then
		LaunchScreenshotApp(AdditionalParameters.CompletionHandler);
		Return;
	EndIf;
	
	If AdditionalParameters.CompletionHandler <> Undefined Then
		RunCallback(AdditionalParameters.CompletionHandler, Undefined);
	EndIf
	
EndProcedure

Procedure LaunchScreenshotApp(CompletionHandler = Undefined)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.Notification = New CallbackDescription(
		"AfterLaunchScreenshotApp",
		ThisObject,
		AdditionalParameters);
	
	FileSystemClient.StartApplication("explorer.exe ms-screenclip:", ApplicationStartupParameters);
	
EndProcedure

Procedure AfterLaunchScreenshotApp(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Not Result.ApplicationStarted Then
		ShowMessageBox(, Result.ErrorDescription);
		Return;
	EndIf;
	
	ClearClipboard();
	
	ClipboardProcessingParameters = New Structure;
	ClipboardProcessingParameters.Insert("CurrentAttempt", 0);
	ClipboardProcessingParameters.Insert("MaxAttempt", 10);
	
	ParametersToSave1 = New Structure;
	ParametersToSave1.Insert("ClipboardProcessingParameters", ClipboardProcessingParameters);
	ParametersToSave1.Insert("CompletionHandler", AdditionalParameters.CompletionHandler);
	
	ParameterName = "StandardSubsystems.SupportRequests";
	ApplicationParameters.Insert(ParameterName, ParametersToSave1);
	
	AttachIdleHandler("ContinueSaveScreenshot", 1, True);
	
EndProcedure

Procedure ClearClipboard()
	
	DataToPut = New ClipboardItem(ClipboardDataStandardFormat.Text, "");
	ClipboardTools.PutDataAsync(DataToPut);
	
EndProcedure

Async Procedure SaveScreenshot() Export
	
	DataFormat = ClipboardDataStandardFormat.Picture;
	Screenshot = Undefined;
	
	If ClipboardTools.CanUse() Then
		If Await ClipboardTools.ContainsDataAsync(DataFormat) Then
			Screenshot = Await ClipboardTools.GetDataAsync(DataFormat);
		EndIf;
	EndIf;
	
	ParameterName = "StandardSubsystems.SupportRequests";
	SavedParameters1 = ApplicationParameters[ParameterName];
	
	ClipboardProcessingParameters = SavedParameters1.ClipboardProcessingParameters;
	
	If Screenshot = Undefined Then
		
		If ClipboardProcessingParameters.CurrentAttempt < ClipboardProcessingParameters.MaxAttempt Then
			// Retry retrieving the screenshot from the clipboard.
			AttachIdleHandler("ContinueSaveScreenshot", 1, True);
			ClipboardProcessingParameters.CurrentAttempt = ClipboardProcessingParameters.CurrentAttempt + 1;
		Else
			// Resume without a screenshot.
			If SavedParameters1.CompletionHandler <> Undefined Then
				RunCallback(SavedParameters1.CompletionHandler);
			EndIf;
			MessageText = NStr("vi = 'Không thể lưu ảnh chụp màn hình.';
								|ru = 'Не удалось сохранить снимок экрана.';
								|en = 'Failed to take a screenshot.'; fa = 'Failed to take a screenshot.';
								|it = 'Failed to take a screenshot.';
								|pl = 'Failed to take a screenshot.';
								|tr = 'Ekran görüntüsü kaydedilemedi.'");
			CommonClient.MessageToUser(MessageText);
		EndIf;
		
		Return;
		
	EndIf;
	
	FileAddress = SupportRequestsInternalServerCall.AddressOfScreenshot(Screenshot);
	DataOfScreenshot = AdditionalFileData(FileAddress, NStr("vi = 'Ảnh chụp màn hình.png';
															|ru = 'Снимок экрана.png';
															|en = 'Screenshot.png'; fa = 'Screenshot.png';
															|it = 'Screenshot.png';
															|pl = 'Screenshot.png';
															|tr = 'Ekran görüntüsü.png'"));
	
	If SavedParameters1.CompletionHandler <> Undefined Then
		RunCallback(SavedParameters1.CompletionHandler, DataOfScreenshot);
	EndIf
	
EndProcedure

#EndRegion

#Region InformationDownload

Procedure ContinueDownloadInfoForSupport(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AdditionalParameters.AdditionalFiles.Add(Result);
	EndIf;
	
	ArchiveAddress = SupportRequestsInternalServerCall.TechnicalInformationArchiveAddress(
		AdditionalParameters);
	
	CompletionHandler = New CallbackDescription(
		"AfterDownloadInfoForSupport",
		ThisObject,
		New Structure("ArchiveAddress", ArchiveAddress));
	
	FileSystemClient.SaveFile(CompletionHandler, ArchiveAddress, "service_info.zip");
	
EndProcedure

Procedure AfterDownloadInfoForSupport(SavedFiles, AdditionalParameters) Export
	
	If ValueIsFilled(SavedFiles) Then
		FileSystemClient.OpenExplorer(SavedFiles[0].FullName);
	EndIf;
	
	DeleteFromTempStorage(AdditionalParameters.ArchiveAddress);
	
EndProcedure

#EndRegion

#Region TicketSubmission

Procedure ContinueSubmitSupportTicket(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AdditionalParameters.AdditionalFiles.Add(Result);
	EndIf;
	
	If IsMessagesToTechSupportServiceAvailable() Then
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient = CommonClient.CommonModule(
			"MessagesToTechSupportServiceClient");
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer = CommonClient.CommonModule(
			"MessagesToTechSupportServiceClientServer");
		
		MessageData = TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer.MessageData();
		MessageData.Recipient = AdditionalParameters.Recipient;
		MessageData.Subject = AdditionalParameters.Subject;
		MessageData.Message = AdditionalParameters.Message;
		
		AttachedFilesForSupport = AttachmentsForSupport(AdditionalParameters, "Data");
		
		CompletionHandler = New CallbackDescription(
			"AfterSubmitSupportTicket",
			ThisObject,
			AdditionalParameters);
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient.SendMessage(
			MessageData,
			AttachedFilesForSupport,
			,
			CompletionHandler);
		
		Return;
		
	EndIf;
	
	// Attempt to send the support ticket via email.
	AfterSubmitSupportTicket(Undefined, AdditionalParameters);
	
EndProcedure

Procedure AfterSubmitSupportTicket(Result, AdditionalParameters) Export
	
	If Result <> Undefined And ValueIsFilled(Result.ErrorCode) Then
		
		EventName = NStr("vi = 'Làm việc với thư điện tử. Gửi câu hỏi để hỗ trợ';
						|ru = 'Работа с почтовыми сообщениями.Отправка вопроса в поддержку';
						|en = 'Email management.Send support ticket'; fa = 'Email management.Send support ticket';
						|it = 'Email management.Send support ticket';
						|pl = 'Email management.Send support ticket';
						|tr = 'E-posta yönetimi. Desteğe soru gönderimi'");
		
		EventComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2';
				|ru = '%1 %2';
				|en = '%1 %2'; fa = '%1 %2';
				|it = '%1 %2';
				|pl = '%1 %2';
				|tr = '%1 %2'"),
			Result.ErrorCode,
			Result.ErrorMessage);
		
		EventLogClient.AddMessageForEventLog(
			EventName,
			"Error",
			EventComment,
			,
			True);
		
	ElsIf Result <> Undefined Then
		Return;
	EndIf;
	
	If IsEmailOperationsAvailable() Then
		
		ModuleEmailOperationsClient = CommonClient.CommonModule(
			"EmailOperationsClient");
		
		CompletionHandler = New CallbackDescription(
			"AfterEmailAccountVerified",
			ThisObject,
			AdditionalParameters);
		
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CompletionHandler);
		Return;
		
	EndIf;
	
	// Attempt to save the file.
	AfterEmailAccountVerified(Undefined, AdditionalParameters);
	
EndProcedure

Procedure AfterEmailAccountVerified(Result, AdditionalParameters) Export
	
	If Result = True Then
		
		ModuleEmailOperationsClient = CommonClient.CommonModule(
			"EmailOperationsClient");
		
		EmailSendOptions = ModuleEmailOperationsClient.EmailSendOptions();
		EmailSendOptions.Recipient = AdditionalParameters.RecipientAddress;
		EmailSendOptions.Subject = AdditionalParameters.Subject;
		EmailSendOptions.Text = SupportMessageTextTemplate(AdditionalParameters.Message);
		
		Attachments = AttachmentsForSupport(AdditionalParameters, "AddressInTempStorage");
		EmailSendOptions.Attachments = Attachments;
		
		CompletionHandler = New CallbackDescription(
			"AfterEmailMessageSentToSupport",
			ThisObject,
			EmailSendOptions);
		
		ModuleEmailOperationsClient.CreateNewEmailMessage(EmailSendOptions, CompletionHandler);
		Return;
		
	EndIf;
	
	// Attempt to save the file.
	ContinueDownloadInfoForSupport(Undefined, AdditionalParameters);
	
EndProcedure

Procedure AfterEmailMessageSentToSupport(Result, AdditionalParameters) Export
	
	For Each Attachment In AdditionalParameters.Attachments Do
		DeleteFromTempStorage(Attachment.AddressInTempStorage);
	EndDo;
	
EndProcedure

Function SupportRequestRecipient()
	
	Return "v8";
	
EndFunction

Function SupportRequestRecipientAddress()
	
	Return "v8@1c.ru";
	
EndFunction

Function SupportMessageText()
	
	Return NStr("vi = '<Vui lòng mô tả sự cố đã xảy ra và đính kèm ảnh chụp màn hình của lỗi.>';
				|ru = '<Опишите возникшую проблему и приложите скриншоты ошибки.>';
				|en = '<Describe your issue and attach a screenshot.>'; fa = '<Describe your issue and attach a screenshot.>';
				|it = '<Describe your issue and attach a screenshot.>';
				|pl = '<Describe your issue and attach a screenshot.>';
				|tr = '<Sorunu açıklayın ve hatanın ekran görüntülerini ekleyin.>'");
	
EndFunction

Function SupportMessageTextTemplate(RequestText_)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xin chào.
			|
			|%1
			|
			|<Hãy chỉ ra họ tên>.';
			|ru = 'Здравствуйте.
			|
			|%1
			|
			|<Укажите ФИО>.';
			|en = 'Hello.
			|
			|%1
			|
			|<Specify the full name>.'; fa = 'Hello.
			|
			|%1
			|
			|<Specify the full name>.';
			|it = 'Hello.
			|
			|%1
			|
			|<Specify the full name>.';
			|pl = 'Hello.
			|
			|%1
			|
			|<Specify the full name>.';
			|tr = 'Merhaba.
			|
			|%1
			|
			|<Tam adınızı belirtin>.'"),
		RequestText_);
	
EndFunction

#EndRegion

#Region Other

// Validates that the "Email management" subsystem is integrated.
//
// Returns:
//  Boolean - "True" if the subsystem is integrated.
//
Function IsEmailOperationsAvailable()
	
	Return CommonClient.SubsystemExists(
		"StandardSubsystems.EmailOperations");
	
EndFunction

Function AttachmentsForSupport(RequestParameters_, FilesAddressKey)
	
	FilesAddresses = SupportRequestsInternalServerCall.TechnicalInfoFilesAddresses(
		RequestParameters_);
	
	Result = New Array;
	
	FileData = New Structure;
	FileData.Insert(FilesAddressKey, FilesAddresses.TechnologicalInfo);
	FileData.Insert("Presentation", NStr("vi = 'Thông tin kỹ thuật.txt';
										|ru = 'Технологическая информация.txt';
										|en = 'Technical information.txt'; fa = 'Technical information.txt';
										|it = 'Technical information.txt';
										|pl = 'Technical information.txt';
										|tr = 'Teknik bilgi.txt'"));
	FileData.Insert("DataKind", "Address");
	Result.Add(FileData);
	
	FileData = New Structure;
	FileData.Insert(FilesAddressKey, FilesAddresses.EventLog);
	FileData.Insert("Presentation", NStr("vi = 'Nhật ký sự kiện.xml';
										|ru = 'Журнал регистрации.xml';
										|en = 'Event log.xml'; fa = 'Event log.xml';
										|it = 'Event log.xml';
										|pl = 'Event log.xml';
										|tr = 'Olay günlüğü.xml'"));
	FileData.Insert("DataKind", "Address");
	Result.Add(FileData);
	
	For Each AdditionalFile In RequestParameters_.AdditionalFiles Do
		FileData = New Structure;
		FileData.Insert(FilesAddressKey, AdditionalFile.FileAddress);
		FileData.Insert("Presentation", AdditionalFile.FullFileName);
		FileData.Insert("DataKind", "Address");
		Result.Add(FileData);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
