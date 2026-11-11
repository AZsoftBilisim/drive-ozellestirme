///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Report form command handler.
//
// Parameters:
//   Form     - ClientApplicationForm - a report form.
//   Command   - FormCommand     - Command that was called.
//
// Usage locations::
//   CommonForm.ReportForm.Attachable_Command().
//
Procedure CreateNewBulkEmailFromReport(Form, Command) Export
	OpenReportMailingFromReportForm(Form);
EndProcedure

// Report form command handler.
//
// Parameters:
//   Form     - ClientApplicationForm - a report form.
//   Command   - FormCommand     - Command that was called.
//
// Usage locations::
//   CommonForm.ReportForm.Attachable_Command().
//
Procedure AttachReportToExistingBulkEmail(Form, Command) Export
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	FormParameters.Insert("MultipleChoice", False);
	
	OpenForm("Catalog.ReportMailings.ChoiceForm", FormParameters, Form);
EndProcedure

// Report form command handler.
//
// Parameters:
//   Form     - ClientApplicationForm - a report form.
//   Command   - FormCommand     - Command that was called.
//
// Usage locations::
//   CommonForm.ReportForm.Attachable_Command().
//
Procedure OpenBulkEmailsWithReport(Form, Command) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Report", Form.ReportSettings.OptionRef);
	OpenForm("Catalog.ReportMailings.ListForm", FormParameters, Form);
	
EndProcedure

// Report form selection handler.
//
// Parameters:
//   Form             - ClientApplicationForm - a report form.
//   ValueSelected - Arbitrary     - a selection result in a subordinate form.
//   ChoiceSource    - ClientApplicationForm - a form where the choice is made.
//   Result         - Boolean           - True if the selection result is processed.
//
// Usage locations::
//   CommonForm.ReportForm.ChoiceProcessing().
//
Procedure ChoiceProcessingReportForm(Form, ValueSelected, ChoiceSource, Result) Export
	
	If Result = True Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("CatalogRef.ReportMailings") Then
		
		OpenReportMailingFromReportForm(Form, ValueSelected);
		
		Result = True;
		
	EndIf;
	
EndProcedure

Procedure ClearReportDistributionHistory(Form) Export

	If Form.ConstantsSet.RetainReportDistributionHistory Then
		QueryText = StringFunctionsClient.FormattedString(NStr(
		"vi = 'Xóa lịch sử cũ gửi báo cáo hàng loạt?';
		|ru = 'Очистить устаревшую историю рассылки отчетов?';
		|en = 'Do you want to clear an obsolete report distribution history?'; fa = 'Do you want to clear an obsolete report distribution history?';
		|it = 'Очистить устаревшую историю рассылки отчетов?';
		|pl = 'Do you want to clear an obsolete report distribution history?';
		|tr = 'Eski rapor dağıtım geçmişi temizlensin mi?'"));
	Else
		QueryText = StringFunctionsClient.FormattedString(NStr(
		"vi = 'Xóa lịch sử gửi báo cáo hàng loạt?';
		|ru = 'Очистить историю рассылки отчетов?';
		|en = 'Do you want to clear the report distribution history?'; fa = 'Do you want to clear the report distribution history?';
		|it = 'Очистить историю рассылки отчетов?';
		|pl = 'Do you want to clear the report distribution history?';
		|tr = 'Rapor dağıtım geçmişi temizlensin mi?'"));
	EndIf;

	Parameters = New Structure("Form", Form);

	ShowQueryBox(New CallbackDescription("ResponseClearUpReportDistributionHistory", ThisObject, Parameters), QueryText,
		QuestionDialogMode.YesNo, , DialogReturnCode.Yes);

EndProcedure

#EndRegion

#Region Private

// Generates a mailing recipients list, suggests the user to select a
//   specific recipient or all recipients of the mailing and returns the
//   result of the user selection.
// Called from the items form.
//
Procedure SelectRecipient(HandlerResults_1, Object, MultipleChoice, ReturnsMap) Export
	
	If Object.Personal = True Then
		ParametersSet = "Ref, RecipientsEmailAddressKind, Personal, Author";
	Else
		ParametersSet = "Ref, RecipientsEmailAddressKind, Personal, MailingRecipientType, Recipients";
	EndIf;
	
	RecipientsParameters = New Structure(ParametersSet);
	FillPropertyValues(RecipientsParameters, Object);
	ExecutionResult = ReportMailingServerCall.GenerateMailingRecipientsList(RecipientsParameters);
	
	If ExecutionResult.HadCriticalErrors Then
		QuestionToUserParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionToUserParameters.PromptDontAskAgain = False;
		QuestionToUserParameters.Picture = PictureLib.DialogExclamation;
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, ExecutionResult.Text, 
			QuestionDialogMode.OK, QuestionToUserParameters);
		Return;
	EndIf;
	
	Recipients = ExecutionResult.Recipients;
	If Recipients.Count() = 1 Then
		Result = Recipients;
		If Not ReturnsMap Then
			For Each KeyAndValue In Recipients Do
				Result = New Structure("Recipient, MailAddress", KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
		EndIf;
		RunCallback(HandlerResults_1, Result);
		Return;
	EndIf;
	
	PossibleRecipients = New ValueList;
	For Each KeyAndValue In Recipients Do
		PossibleRecipients.Add(KeyAndValue.Key, String(KeyAndValue.Key) +" <"+ KeyAndValue.Value +">");
	EndDo;
	If MultipleChoice Then
		PossibleRecipients.Insert(0, Undefined, NStr("vi = 'Cho tất cả người nhận';
													|ru = 'Всем получателям';
													|en = 'To all recipients'; fa = 'To all recipients';
													|it = 'A tutti i destinatari';
													|pl = 'Do wszystkich odbiorców';
													|tr = 'Tüm alıcılara'"));
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("HandlerResults_1", HandlerResults_1);
	AdditionalParameters.Insert("Recipients", Recipients);
	AdditionalParameters.Insert("ReturnsMap", ReturnsMap);
	
	Handler = New CallbackDescription("SelectRecipientCompletion", ThisObject, AdditionalParameters);
	PossibleRecipients.ShowChooseItem(Handler, NStr("vi = 'Chọn người nhận';
													|ru = 'Выбор получателя';
													|en = 'Select recipient'; fa = 'انتخاب گیرنده';
													|it = 'Selezione del destinatario';
													|pl = 'Wybór odbiorcy';
													|tr = 'Alıcı seç'"));
	
EndProcedure

// SelectRecipient procedure execution result handler.
// 
// Parameters:
//   SelectedElement - ValueListItem
//   AdditionalParameters - Structure:
//     * HandlerResults_1 - CallbackDescription
//     * Recipients - Map of KeyAndValue:
//       ** Key - Arbitrary
//       ** Value - String 
//     * ReturnsMap - Boolean
//
Procedure SelectRecipientCompletion(SelectedElement, AdditionalParameters) Export
	If SelectedElement = Undefined Then
		Result = Undefined;
	Else
		If AdditionalParameters.ReturnsMap Then
			If SelectedElement.Value = Undefined Then
				Result = AdditionalParameters.Recipients;
			Else
				Result = New Map;
				Result.Insert(SelectedElement.Value, AdditionalParameters.Recipients[SelectedElement.Value]);
			EndIf;
		Else
			Result = New Structure("Recipient, MailAddress", SelectedElement.Value, AdditionalParameters.Recipients[SelectedElement.Value]);
		EndIf;
	EndIf;
	
	RunCallback(AdditionalParameters.HandlerResults_1, Result);
EndProcedure

// Executes mailing in the background.
Procedure ExecuteNow(Parameters) Export
	Handler = New CallbackDescription("ExecuteNowInBackground", ThisObject, Parameters);
	If Parameters.IsItemForm Then
		Object = Parameters.Form.Object;
		If Not Object.IsPrepared Then
			ShowMessageBox(, NStr("vi = 'Chưa chuẩn bị gửi hàng loạt.';
									|ru = 'Рассылка не подготовлена.';
									|en = 'The report distribution is not prepared.'; fa = 'The report distribution is not prepared.';
									|it = 'Рассылка не подготовлена.';
									|pl = 'The report distribution is not prepared.';
									|tr = 'Bülten hazırlanmadı.'"));
			Return;
		EndIf;
		If Object.UseEmail Then
			SelectRecipient(Handler, Parameters.Form.Object, True, True);
			Return;
		EndIf;
	EndIf;
	RunCallback(Handler, Undefined);
EndProcedure

// Runs background job, it is called when all parameters are ready.
Procedure ExecuteNowInBackground(Recipients, Parameters) Export
	PreliminarySettings = Undefined;
	If Parameters.IsItemForm Then
		If Parameters.Form.Object.UseEmail Then
			If Recipients = Undefined Then
				Return;
			EndIf;
			PreliminarySettings = New Structure("Recipients", Recipients);
		EndIf;
		StateText = NStr("vi = 'Đang gửi báo cáo hàng loạt.';
						|ru = 'Выполняются рассылки отчетов.';
						|en = 'Distributing reports.'; fa = 'Distributing reports.';
						|it = 'Invii massivi dei report in corso.';
						|pl = 'Trwają wysyłki raportów.';
						|tr = 'Raporlar, bülten ile gönderiliyor.'");
	Else
		StateText = NStr("vi = 'Đang gửi báo cáo hàng loạt.';
						|ru = 'Выполняются рассылки отчетов.';
						|en = 'Distributing reports.'; fa = 'Distributing reports.';
						|it = 'Invii massivi dei report in corso.';
						|pl = 'Trwają wysyłki raportów.';
						|tr = 'Raporlar, bülten ile gönderiliyor.'");
	EndIf;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("MailingArray", Parameters.MailingArray);
	MethodParameters.Insert("PreliminarySettings", PreliminarySettings);
	
	Job = ReportMailingServerCall.RunBackgroundJob1(MethodParameters, Parameters.Form.UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(Parameters.Form);
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MessageText = StateText;
	WaitSettings.OutputProgressBar = True;
	
	Handler = New CallbackDescription("ExecuteNowInBackgroundCompletion", ThisObject, Parameters);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
	
EndProcedure

// Accepts the background job result.
//
// Parameters:
//  Job - See TimeConsumingOperationsClient.NewResultLongOperation
//  Parameters - Arbitrary
//
Procedure ExecuteNowInBackgroundCompletion(Job, Parameters) Export
	
	If Job = Undefined Then
		Return; // Canceled.
	EndIf;
	
	If Job.Status = "Completed2" Then
		Result = GetFromTempStorage(Job.ResultAddress);
		MailingNumber = Result.BulkEmails.Count();
		If MailingNumber > 0 Then
			NotifyChanged(?(MailingNumber > 1, Type("CatalogRef.ReportMailings"), Result.BulkEmails[0]));
		EndIf;
		ShowUserNotification(,, Result.Text, PictureLib.ReportMailing, UserNotificationStatus.Information);
		
	Else
		Result = GetFromTempStorage(Job.ResultAddress);
		If Result <> Undefined And Result.HasEncryptionErrors
		   And CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			AdditionalData = New Structure;
			AdditionalData.Insert("Certificate", Result.CertificateToEncrypt);
			FormParameters = New Structure;
			FormParameters.Insert("WarningTitle", NStr("vi = 'Không thể gửi báo cáo hàng loạt';
														|ru = 'Не удалось выполнить рассылку отчетов';
														|en = 'Report distribution failed'; fa = 'Report distribution failed';
														|it = 'Не удалось выполнить рассылку отчетов';
														|pl = 'Report distribution failed';
														|tr = 'Raporlar gönderilemiyor'"));
			FormParameters.Insert("ErrorTextServer", ErrorProcessing.BriefErrorDescription(Job.ErrorInfo));
			FormParameters.Insert("AdditionalData", AdditionalData);
			FormParameters.Insert("ShowNeedHelp", True);
			FormParameters.Insert("ShowInstruction", True);
			ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
			ModuleDigitalSignatureClient.OpenExtendedErrorPresentationForm(FormParameters);
		Else
			StandardSubsystemsClient.OutputErrorInfo(Job.ErrorInfo);
		EndIf;
	EndIf;
	
EndProcedure

// Opens report mailing from the report form.
//
// Parameters:
//   Form  - ClientApplicationForm - a report form.
//   Ref - CatalogRef.ReportMailings - report mailing reference.
//
Procedure OpenReportMailingFromReportForm(Form, Ref = Undefined)
	ReportSettings = Form.ReportSettings;
	ReportOptionMode = (TypeOf(Form.CurrentVariantKey) = Type("String") And Not IsBlankString(Form.CurrentVariantKey));
	
	ReportsParametersRow = New Structure("ReportFullName, VariantKey, OptionRef, Settings");
	ReportsParametersRow.ReportFullName = ReportSettings.FullName;
	ReportsParametersRow.VariantKey   = Form.CurrentVariantKey;
	ReportsParametersRow.OptionRef  = ReportSettings.OptionRef;
	If ReportOptionMode Then
		ReportsParametersRow.Settings = Form.Report.SettingsComposer.UserSettings;
	EndIf;
	
	ReportsToAttach = New Array;
	ReportsToAttach.Add(ReportsParametersRow);
	
	FormParameters = New Structure;
	FormParameters.Insert("ReportsToAttach", ReportsToAttach);
	If Ref <> Undefined Then
		FormParameters.Insert("Key", Ref);
	EndIf;
	
	OpenForm("Catalog.ReportMailings.ObjectForm", FormParameters, , String(Form.UUID) + ".OpenReportsMailing");
	
EndProcedure

// Returns set of scheduled job schedules filling templates.
Function ScheduleFillingOptionsList() Export
	
	VariantList = New ValueList;
	VariantList.Add(1, NStr("vi = 'Hàng ngày';
							|ru = 'Каждый день';
							|en = 'Every day'; fa = 'Every day';
							|it = 'Ogni giorno';
							|pl = 'Codziennie';
							|tr = 'Her gün'"));
	VariantList.Add(2, NStr("vi = 'Cứ sau hai ngày';
							|ru = 'Каждый второй день';
							|en = 'Every second day'; fa = 'Every second day';
							|it = 'Ogni due giorni';
							|pl = 'Co drugi dzień';
							|tr = 'İki günde bir'"));
	VariantList.Add(3, NStr("vi = 'Cứ sau bốn ngày';
							|ru = 'Каждый четвертый день';
							|en = 'Every fourth day'; fa = 'Every fourth day';
							|it = 'Ogni quattro giorni';
							|pl = 'Co czwarty dzień';
							|tr = 'Dört günde bir'"));
	VariantList.Add(4, NStr("vi = 'Vào ngày làm việc';
							|ru = 'По будням';
							|en = 'On weekdays'; fa = 'On weekdays';
							|it = 'Nei giorni feriali';
							|pl = 'W dni powszednie';
							|tr = 'Hafta içi'"));
	VariantList.Add(5, NStr("vi = 'Vào ngày nghỉ';
							|ru = 'По выходным';
							|en = 'On weekends'; fa = 'On weekends';
							|it = 'Nei giorni festivi';
							|pl = 'W weekendy';
							|tr = 'Hafta sonu'"));
	VariantList.Add(6, NStr("vi = 'Vào thứ hai';
							|ru = 'По понедельникам';
							|en = 'On Mondays'; fa = 'On Mondays';
							|it = 'Ogni lunedì';
							|pl = 'W poniedziałki';
							|tr = 'Pazartesileri'"));
	VariantList.Add(7, NStr("vi = 'Vào thứ sáu';
							|ru = 'По пятницам';
							|en = 'On Fridays'; fa = 'On Fridays';
							|it = 'Ogni venerdì';
							|pl = 'W piątki';
							|tr = 'Cumaları'"));
	VariantList.Add(8, NStr("vi = 'Vào chủ nhật';
							|ru = 'По воскресеньям';
							|en = 'On Sundays'; fa = 'On Sundays';
							|it = 'Ogni domenica';
							|pl = 'W niedzele';
							|tr = 'Pazarları'"));
	VariantList.Add(9, NStr("vi = 'Vào ngày đầu tiên của tháng';
							|ru = 'В первый день месяца';
							|en = 'On the first day of the month'; fa = 'On the first day of the month';
							|it = 'Il primo giorno del mese';
							|pl = 'W pierwszy dzień miesiąca';
							|tr = 'Ayın ilk gününde'"));
	VariantList.Add(10, NStr("vi = 'Vào ngày cuối cùng của tháng';
							|ru = 'В последний день месяца';
							|en = 'On the last day of the month'; fa = 'On the last day of the month';
							|it = 'L''ultimo giorno del mese';
							|pl = 'W ostatni dzień miesiąca';
							|tr = 'Ayın son gününde'"));
	VariantList.Add(11, NStr("vi = 'Vào ngày thứ 10 mỗi quý';
							|ru = 'Каждый квартал десятого числа';
							|en = 'On the 10th day of every quarter'; fa = 'On the 10th day of every quarter';
							|it = 'Il 10 del primo mese del trimestre';
							|pl = 'Co kwartał dziesiątego dnia';
							|tr = 'Her çeyreğin onuncu gününde'"));
	If Not CommonClient.DataSeparationEnabled() Then
		VariantList.Add(12, NStr("vi = 'Khác...';
								|ru = 'Другое...';
								|en = 'Other…'; fa = 'Other…';
								|it = 'Altro...';
								|pl = 'Other…';
								|tr = 'Diğer...'"));
	EndIf;
	
	Return VariantList;
EndFunction

// Parses the FTP address string into the Username, Password, Port and Directory.
//   Detailed - see RFC 1738 (http://tools.ietf.org/html/rfc1738#section-3.1). 
//   Template: ftp://<user>:<password>@<host>:<port>/<url-path>.
//   Fragments <user>:<password>@,:<password>,:<port> and /<url-path> can be absent.
//
// Parameters:
//   FTPAddress - String - a full path to the ftp resource.
//
// Returns:
//   Structure - Result - Structure - Result of parsing the full path:
//       * Login - String - ftp user name.
//       * Password - String - ftp user password.
//       * Server - String - Server name.
//       * Port - Number - a server port. 21 by default.
//       * Directory - String - a path to the directory at the FTP server. The first character is always /.
//
Function ParseFTPAddress(FullFTPAddress) Export
	
	Result = New Structure;
	Result.Insert("Login", "");
	Result.Insert("Password", "");
	Result.Insert("Server", "");
	Result.Insert("Port", 21);
	Result.Insert("Directory", "/");
	
	FTPAddress = FullFTPAddress;
	
	// Trim "ftp://".
	Pos = StrFind(FTPAddress, "://");
	If Pos > 0 Then
		FTPAddress = Mid(FTPAddress, Pos + 3);
	EndIf;
	
	// Directory.
	Pos = StrFind(FTPAddress, "/");
	If Pos > 0 Then
		Result.Directory = Mid(FTPAddress, Pos);
		FTPAddress = Left(FTPAddress, Pos - 1);
	EndIf;
	
	// Username and password.
	Pos = StrFind(FTPAddress, "@");
	If Pos > 0 Then
		UsernamePassword = Left(FTPAddress, Pos - 1);
		FTPAddress = Mid(FTPAddress, Pos + 1);
		
		Pos = StrFind(UsernamePassword, ":");
		If Pos > 0 Then
			Result.Login = Left(UsernamePassword, Pos - 1);
			Result.Password = Mid(UsernamePassword, Pos + 1);
		Else
			Result.Login = UsernamePassword;
		EndIf;
	EndIf;
	
	// Server and port.
	Pos = StrFind(FTPAddress, ":");
	If Pos > 0 Then
		
		Result.Server = Left(FTPAddress, Pos - 1);
		
		NumberType = New TypeDescription("Number");
		Port     = NumberType.AdjustValue(Mid(FTPAddress, Pos + 1));
		Result.Port = ?(Port > 0, Port, Result.Port);
		
	Else
		
		Result.Server = FTPAddress;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Sends out text messages with archive passwords in the background.
Procedure SendBulkSMSMessages(Parameters) Export
	Handler = New CallbackDescription("SendBulkSMSMessagesInBackground", ThisObject, Parameters);
	RunCallback(Handler, Undefined);
EndProcedure

// Runs background job, it is called when all parameters are ready.
Procedure SendBulkSMSMessagesInBackground(Recipients, Parameters) Export

	MethodParameters = New Structure;
	MethodParameters.Insert("PreparedSMSMessages", Parameters.PreparedSMSMessages);
	MethodParameters.Insert("UnsentCount", Parameters.UnsentCount);
	
	Job = ReportMailingServerCall.RunBackgroundJobToSendSMSWithPasswords(MethodParameters,
		Parameters.Form.UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(Parameters.Form);
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MessageText = NStr("vi = 'Đang gửi SMS hàng loạt có mật khẩu để gửi báo cáo hàng loạt.';
									|ru = 'Выполняется рассылка SMS с паролями для рассылки отчетов.';
									|en = 'Sending text messages with passwords for the report distribution.'; fa = 'Sending text messages with passwords for the report distribution.';
									|it = 'Выполняется рассылка SMS с паролями для рассылки отчетов.';
									|pl = 'Sending text messages with passwords for the report distribution.';
									|tr = 'Rapor dağıtımı için şifreli SMS dağıtımı gerçekleştiriliyor.'");
	
	Handler = New CallbackDescription("SendBulkSMSMessagesInBackgroundCompletion", ThisObject, Parameters);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);

EndProcedure

// Accepts the background job result.
//
// Parameters:
//   Job - See TimeConsumingOperationsClient.NewResultLongOperation
//   Parameters - Structure:
//     * UnsentCount - Number
//     * PreparedSMSMessages - Array of Structure:
//         ** PhoneNumbers - Array of String - Report recipient's phone numbers.
//         ** SMSMessageText - String
//         ** Recipient - DefinedType.BulkEmailRecipient	
//     * Form - ClientApplicationForm:
//         ** Items - FormAllItems
//         ** SMSDistributionResult - FormDataCollection
//         ** SMSDistributionResultNoFilters - FormDataCollection
//
Procedure SendBulkSMSMessagesInBackgroundCompletion(Job, Parameters) Export
	
	If Job = Undefined Then
		Return; // Canceled.
	EndIf;
		
	Form = Parameters.Form;     
	
	If Not Form.Items.Close.Visible Then
		Form.Items.Close.Visible = True;      
	EndIf;
	
	If Job.Status = "Completed2" Then
		Result = GetFromTempStorage(Job.ResultAddress);
		ShowUserNotification(,, Result.Text, PictureLib.ReportMailing, UserNotificationStatus.Information);	
		For Each RecipientResult In Result.ResultByRecipients Do
			ResultString1 = Form.SMSDistributionResult.Add();
			FillPropertyValues(ResultString1, RecipientResult);
			StringResultNoFilters = Form.SMSDistributionResultNoFilters.Add();
			FillPropertyValues(StringResultNoFilters, ResultString1);
		EndDo;      
		Form.SentCount = Result.SentCount;
		Form.UnsentCount = Result.UnsentCount;
		Form.AutoTitle = False;
		Form.Title = NStr("vi = 'Kết quả gửi SMS có mật khẩu nén';
							|ru = 'Результат отправки SMS с паролями архивов';
							|en = 'The result of sending text messages with archive passwords'; fa = 'The result of sending text messages with archive passwords';
							|it = 'Результат отправки SMS с паролями архивов';
							|pl = 'The result of sending text messages with archive passwords';
							|tr = 'Şifreli arşiv ile SMS mesajlaşmasının sonucu'");
		Form.Items.Pages.CurrentPage = Form.Items.InformationPage;
	Else
		Form.Items.Pages.CurrentPage = Form.Items.InformationPage;
		StandardSubsystemsClient.OutputErrorInfo(
			Job.ErrorInfo);
	EndIf;
	
EndProcedure

Procedure ResponseClearUpReportDistributionHistory(Result, Parameters) Export  
	
	If Result = DialogReturnCode.Yes Then
		Handler = New CallbackDescription("ClearUpReportDistributionHistoryInBackground", ThisObject, Parameters);
		RunCallback(Handler, Undefined);
	EndIf;
	
EndProcedure

// Runs background job, it is called when all parameters are ready.
Procedure ClearUpReportDistributionHistoryInBackground(Parameters, AdditionalParameters) Export

	MethodParameters = New Structure;
	
	Job = ReportMailingServerCall.RunBackgroundJobToClearUpReportDistributionHistory(MethodParameters,
		AdditionalParameters.Form.UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(AdditionalParameters.Form);
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MessageText = NStr("vi = 'Đang xóa lịch sử gửi báo cáo hàng loạt.';
									|ru = 'Выполняется очистка истории рассылки отчетов.';
									|en = 'Clearing the report distribution history.'; fa = 'Clearing the report distribution history.';
									|it = 'Выполняется очистка истории рассылки отчетов.';
									|pl = 'Clearing the report distribution history.';
									|tr = 'Rapor dağıtım geçmişinin temizlenmesi gerçekleştiriliyor.'");
	
	Handler = New CallbackDescription("ClearUpReportDistributionHistoryCompletion", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);

EndProcedure

// Parameters:
//  Job - See TimeConsumingOperationsClient.NewResultLongOperation
//  Parameters - Arbitrary
//
Procedure ClearUpReportDistributionHistoryCompletion(Job, Parameters) Export
	
	If Job = Undefined Then
		Return; // Canceled.
	EndIf;
	
	If Job.Status = "Completed2" Then
		Result = GetFromTempStorage(Job.ResultAddress);
		ShowUserNotification(,, Result.Text, , UserNotificationStatus.Information);	
	Else
		StandardSubsystemsClient.OutputErrorInfo(
			Job.ErrorInfo);
	EndIf;	
	
EndProcedure

#EndRegion
