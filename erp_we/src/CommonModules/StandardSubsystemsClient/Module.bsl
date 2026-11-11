///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Sets the application main window caption using the value of the
// ApplicationCaption constant and application caption by default.
//
// Parameters:
//   OnStart - Boolean - True if the procedure is called on the application start.
//
Procedure SetAdvancedApplicationCaption(OnStart = False) Export
	
	ClientParameters = ?(OnStart, ClientParametersOnStart(),
		ClientRunParameters());
		
	If CommonClient.SeparatedDataUsageAvailable() Then
		CaptionPresentation = ClientParameters.ApplicationCaption;
		ConfigurationPresentation = ClientParameters.DetailedInformation;
		
		If IsBlankString(TrimAll(CaptionPresentation)) Then
			If ClientParameters.Property("DataAreaPresentation") Then
				TitleTemplate1 = "%1 / %2";
				ApplicationCaption = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, ClientParameters.DataAreaPresentation,
					ConfigurationPresentation);
			Else
				TitleTemplate1 = "%1";
				ApplicationCaption = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, ConfigurationPresentation);
			EndIf;
		Else
			TitleTemplate1 = "%1 / %2";
			ApplicationCaption = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1,
				TrimAll(CaptionPresentation), ConfigurationPresentation);
		EndIf;
	Else
		TitleTemplate1 = "%1 / %2";
		ApplicationCaption = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, NStr("vi = 'Chưa thiết lập đường chia tách';
																											|ru = 'Не установлены разделители';
																											|en = 'Separators are not set'; fa = 'Separators are not set';
																											|it = 'Non sono impostati i separatori';
																											|pl = 'Nie są ustawione separatory';
																											|tr = 'Ayırıcılar belirlenmedi'"), ClientParameters.DetailedInformation);
	EndIf;
	
	If Not CommonClient.DataSeparationEnabled()
	   And ClientParameters.Property("OperationsWithExternalResourcesLocked") Then
		ApplicationCaption = "[" + NStr("vi = 'BẢN SAO';
										|ru = 'КОПИЯ';
										|en = 'COPY'; fa = 'COPY';
										|it = 'COPIA';
										|pl = 'KOPIA';
										|tr = 'KOPYA'") + "]" + " " + ApplicationCaption;
	EndIf;
	
	CommonClientOverridable.ClientApplicationCaptionOnSet(ApplicationCaption, OnStart);
	
	ClientApplication.SetCaption(ApplicationCaption);
	
EndProcedure

// Show the question form.
//
// Parameters:
//   CallbackDescriptionOnCompletion - CallbackDescription - Describes the procedure that is called upon closing the question window
//                                                        with the following parameters:
//                                                         * QuestionResult - Structure:
//                                                            ** Value - User selection result: a value of
//                                                                       system enumeration or a value
//                                                                       related to the pressed button. If the dialog is closed
//                                                                       after a timeout, the Timeout
//                                                                       value is used.
//                                                            ** NeverAskAgain - Boolean - User selection
//                                                                                                  result in the
//                                                                                                  checkbox of the same name.
//                                                          * AdditionalParameters - Structure
//   QueryText                  - String, FormattedString - Text of the question. 
//   Buttons                        - QuestionDialogMode
//                                 - ValueList     - Value list, where:
//                                       Value - Value connected to the button and returned when the button is clicked. 
//                                                  Takes a value of the DialogReturnCode enumeration or any XDTO-serializable value.
//                                                  Presentation - Button text.
//                                                  
//                                       
//
//   AdditionalParameters       - See StandardSubsystemsClient.QuestionToUserParameters.
//
Procedure ShowQuestionToUser(CallbackDescriptionOnCompletion, QueryText, Buttons, AdditionalParameters = Undefined) Export
	
	Parameters = QuestionToUserParameters();
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(Parameters, AdditionalParameters);
	EndIf;
	
	DialogReturnCodes = New Map;
	DialogReturnCodes.Insert(DialogReturnCode.Yes, "DialogReturnCode.Yes");
	DialogReturnCodes.Insert(DialogReturnCode.No, "DialogReturnCode.None");
	DialogReturnCodes.Insert(DialogReturnCode.OK, "DialogReturnCode.OK");
	DialogReturnCodes.Insert(DialogReturnCode.Cancel, "DialogReturnCode.Cancel");
	DialogReturnCodes.Insert(DialogReturnCode.Retry, "DialogReturnCode.Retry");
	DialogReturnCodes.Insert(DialogReturnCode.Abort, "DialogReturnCode.Abort");
	DialogReturnCodes.Insert(DialogReturnCode.Ignore, "DialogReturnCode.Ignore");
	DialogReturnCodes.Insert(DialogReturnCode.Timeout, "DialogReturnCode.Timeout");
	
	ButtonsPresentations = New Map;
	ButtonsPresentations.Insert(DialogReturnCode.Yes, NStr("vi = 'Có';
															|ru = 'Да';
															|en = 'Yes'; fa = 'بله';
															|it = 'Sì';
															|pl = 'Tak';
															|tr = 'Evet'"));
	ButtonsPresentations.Insert(DialogReturnCode.No, NStr("vi = 'Không';
															|ru = 'Нет';
															|en = 'No'; fa = 'خیر';
															|it = 'No';
															|pl = 'Nie';
															|tr = 'Hayır'"));
	ButtonsPresentations.Insert(DialogReturnCode.OK, NStr("vi = 'Đồng ý';
															|ru = 'ОК';
															|en = 'OK'; fa = 'تأیید';
															|it = 'OK';
															|pl = 'OK';
															|tr = 'Tamam'"));
	ButtonsPresentations.Insert(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отмена';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annulla';
																|pl = 'Anuluj';
																|tr = 'İptal'"));
	ButtonsPresentations.Insert(DialogReturnCode.Retry, NStr("vi = 'Lặp lại';
															|ru = 'Повторить';
															|en = 'Repeat'; fa = 'Repeat';
															|it = 'Ripetere';
															|pl = 'Repeat';
															|tr = 'Tekrarla'"));
	ButtonsPresentations.Insert(DialogReturnCode.Abort, NStr("vi = 'Ngừng';
															|ru = 'Прервать';
															|en = 'Abort'; fa = 'توقف';
															|it = 'Interrompere';
															|pl = 'Przerwij';
															|tr = 'Durdur'"));
	ButtonsPresentations.Insert(DialogReturnCode.Ignore, NStr("vi = 'Bỏ qua';
																|ru = 'Пропустить';
																|en = 'Ignore'; fa = 'نادیده گرفتن';
																|it = 'Ignorare';
																|pl = 'Pomiń';
																|tr = 'Atla'"));
	ButtonsPresentations.Insert(DialogReturnCode.Timeout, NStr("vi = 'Hết giờ';
																|ru = 'Таймаут';
																|en = 'Timeout'; fa = 'زمان انتظار';
																|it = 'Timeout';
																|pl = 'Timeout';
																|tr = 'Zaman aşımı'"));
	
	QuestionDialogModes = New Map;
	QuestionDialogModes.Insert(QuestionDialogMode.YesNo, "QuestionDialogMode.YesNo");
	QuestionDialogModes.Insert(QuestionDialogMode.YesNoCancel, "QuestionDialogMode.YesNoCancel");
	QuestionDialogModes.Insert(QuestionDialogMode.OK, "QuestionDialogMode.OK");
	QuestionDialogModes.Insert(QuestionDialogMode.OKCancel, "QuestionDialogMode.OKCancel");
	QuestionDialogModes.Insert(QuestionDialogMode.RetryCancel, "QuestionDialogMode.RetryCancel");
	QuestionDialogModes.Insert(QuestionDialogMode.AbortRetryIgnore, "QuestionDialogMode.AbortRetryIgnore");
	
	DialogButtons = Buttons;
	
	If TypeOf(Buttons) = Type("ValueList") Then
		DialogButtons = CommonClient.CopyRecursive(Buttons);
		For Each Button In DialogButtons Do
			If Button.Presentation = "" Then
				Button.Presentation = ButtonsPresentations[Button.Value];
			EndIf;
			If TypeOf(Button.Value) = Type("DialogReturnCode") Then
				Button.Value = DialogReturnCodes[Button.Value];
			EndIf;
		EndDo;
	EndIf;
	
	If TypeOf(Buttons) = Type("QuestionDialogMode") Then
		DialogButtons = QuestionDialogModes[Buttons];
	EndIf;
	
	If TypeOf(Parameters.DefaultButton) = Type("DialogReturnCode") Then
		Parameters.DefaultButton = DialogReturnCodes[Parameters.DefaultButton];
	EndIf;
	
	If TypeOf(Parameters.TimeoutButton) = Type("DialogReturnCode") Then
		Parameters.TimeoutButton = DialogReturnCodes[Parameters.TimeoutButton];
	EndIf;
	
	Parameters.Insert("Buttons", DialogButtons);
	Parameters.Insert("MessageText", QueryText);
	
	OpenForm("CommonForm.DoQueryBox", Parameters, , , , , CallbackDescriptionOnCompletion);
	
EndProcedure

// Returns a new structure with additional parameters for the ShowQuestionToUser procedure.
//
// Returns:
//  Structure:
//    * DefaultButton             - Arbitrary - defines the default button by the button type or by the value associated
//                                                     with it.
//    * Timeout                       - Number        - a period of time in seconds in which the question
//                                                     window waits for user to respond.
//    * TimeoutButton                - Arbitrary - a button (by button type or value associated with it) 
//                                                     on which the timeout
//                                                     remaining seconds are displayed.
//    * Title                     - String       - a question title. 
//    * PromptDontAskAgain - Boolean - If True, a check box with the same name is available in the window.
//    * NeverAskAgain    - Boolean       - a value set by the user in the matching
//                                                     check box.
//    * LockWholeInterface      - Boolean       - If True, the question window opens locking all
//                                                     other opened windows including the main one.
//    * Picture                      - Picture     - a picture displayed in the question window.
//    * CheckBoxText                   - String       - text of the "Do not ask again" check box.
//
Function QuestionToUserParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("DefaultButton", Undefined);
	Parameters.Insert("Timeout", 0);
	Parameters.Insert("TimeoutButton", Undefined);
	Parameters.Insert("Title", ClientApplication.GetCaption());
	Parameters.Insert("PromptDontAskAgain", True);
	Parameters.Insert("NeverAskAgain", False);
	Parameters.Insert("LockWholeInterface", False);
	Parameters.Insert("Picture", PictureLib.DialogQuestion);
	Parameters.Insert("CheckBoxText", "");
	
	Return Parameters;
	
EndFunction	

// Is called if there is a need to open the list of active users
// to see who is logged on to the system now.
//
// Parameters:
//    FormParameters - Structure        - See the "Parameters" parameter of the "OpenForm" method in Syntax Assistant.
//    FormOwner  - ClientApplicationForm - See the "Owner" parameter of the "OpenForm" method in Syntax Assistant.
//
Procedure OpenActiveUserList(FormParameters = Undefined, FormOwner = Undefined) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
		
		FormName = "";
		ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
		ModuleIBConnectionsClient.OnDefineActiveUserForm(FormName);
		OpenForm(FormName, FormParameters, FormOwner);
		
	Else
		
		ShowMessageBox(,
			NStr("vi = 'Để mở danh sách người sử dụng đang làm việc, hãy chuyển đến menu 
				       |Tất cả tính năng - Chuẩn - Người sử dụng đang làm việc.';
				       |ru = 'Для того чтобы открыть список активных пользователей, перейдите в меню
				       |Все функции - Стандартные - Активные пользователи.';
				       |en = 'To open the list of active users, on the main menu, click
				       |All functions—Standard—Active users.'; fa = 'To open the list of active users, on the main menu, click
				       |All functions—Standard—Active users.';
				       |it = 'Per aprire l''elenco degli utenti attivi, andare nel menu
				       |Tutte le funzioni - Standard - Utenti attivi.';
				       |pl = 'Aby otworzyć listę aktywnych użytkowników, przejdź do menu
				       |Wszystkie funkcje - Standardowe - Aktywni użytkownicy.';
				       |tr = 'Aktif kullanıcıların listesini açmak için, 
				       |Tüm işlevler - Standart - Aktif kullanıcılar menüsüne gidin.'"));
		
	EndIf;
	
EndProcedure

// Select metadata objects.
// 
// Parameters:
//  FormParameters - See StandardSubsystemsClientServer.MetadataObjectsSelectionParameters
//  OnCloseNotifyDescription - CallbackDescription - The notification that is called when the form closes. Has the following parameters:: 
//			# SelectedMetadataObjects - The full names of the selected metadata objects.
//				Or references to object IDs if "ChooseRefs" is set to "True". 
//			# AdditionalParameters - Arbitrary - The parameters that were passed when creating the notification. 
//		If "OnCloseNotifyDescription" is not specified, a notification is called that can be received 
//		with the "NotificationProcessing" handler:
//			# EventName - String - "SelectMetadataObjects"
//			# Parameter - ValueList - Selected metadata objects.
//			# Source - See StandardSubsystemsClientServer.MetadataObjectsSelectionParameters.
//
Procedure ChooseMetadataObjects(FormParameters, OnCloseNotifyDescription = Undefined) Export
	OpenForm("CommonForm.SelectMetadataObjects", FormParameters,,,,, OnCloseNotifyDescription);
EndProcedure

// Opens a spreadsheet for viewing or editing.
// When saving an edited spreadsheet, also calls a notification 
// that can be received using the "NotificationProcessing" handler:
//	# EventName - String - "Write_SpreadsheetDocument" or "CancelEditSpreadsheetDocument"
//	# Parameter - Structure:
//	  ## PathToFile - String - The full path to the spreadsheet file.
//	  ## Presentation - String - The spreadsheet name as specified in "SpreadsheetEditorParameters.DocumentName
//	# Source - ClientApplicationForm - The editor form.
// 
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - The opened spreadsheet.
//  FormParameters - See StandardSubsystemsClient.SpreadsheetEditorParameters
//  OnCloseNotifyDescription - CallbackDescription - Notifications to be displayed when the spreadsheet editor closes.
//                                                     
//  Owner - ClientApplicationForm - Owner form.
//
Procedure ShowSpreadsheetEditor(Val SpreadsheetDocument, Val FormParameters = Undefined, 
	Val OnCloseNotifyDescription = Undefined, Owner = Undefined) Export
	
	If FormParameters = Undefined Then
		FormParameters = SpreadsheetEditorParameters();
	EndIf;
	FormParameters.SpreadsheetDocument = SpreadsheetDocument;
	
	OpenForm("CommonForm.EditSpreadsheetDocument", FormParameters, Owner,,,
		OnCloseNotifyDescription);
	
EndProcedure

// Parameters of the spreadsheet editor for "StandardSubsystemsClient.ShowSpreadsheetEditor".
// 
// Returns:
//  Structure:
//   * DocumentName - String - The spreadsheet name (shown in the editor's header). 
//   * SpreadsheetDocument - SpreadsheetDocument, String - The spreadsheet being displayed or edited.
//                         Also, you can specify the address of the spreadsheet in the temporary storage.
//   * PathToFile - String - The full path to the spreadsheet (optional).
//   * Edit - Boolean - If set to "True", the spreadsheet is editable. By default, "False".
//
Function SpreadsheetEditorParameters() Export
	
	Result = New Structure;
	Result.Insert("DocumentName", "");
	Result.Insert("SpreadsheetDocument", Undefined);
	Result.Insert("PathToFile", "");
	Result.Insert("Edit", False);
	Return Result;
	
EndFunction

// Opens a form where you can compare spreadsheets and view the difference.
// 
// Parameters:
//  SpreadsheetDocumentLeft - SpreadsheetDocument - The first spreadsheet to compare.
//  SpreadsheetDocumentRight - SpreadsheetDocument - The second spreadsheet to compare.
//  Parameters - See SpreadsheetComparisonParameters
//
Procedure ShowSpreadsheetComparison(SpreadsheetDocumentLeft, SpreadsheetDocumentRight, Parameters) Export
	
	If SpreadsheetDocumentLeft <> Undefined Then
		FormParameters = SpreadsheetComparisonParameters();
		CommonClientServer.SupplementStructure(FormParameters, Parameters, True);
		ComparableDocuments = New Structure("Left_1, Right", SpreadsheetDocumentLeft, SpreadsheetDocumentRight);
		FormParameters.SpreadsheetDocumentsAddress = PutToTempStorage(ComparableDocuments, Undefined);
	Else
		FormParameters = Parameters;
	EndIf;
	OpenForm("CommonForm.CompareSpreadsheetDocuments", FormParameters);
	
EndProcedure

// Parameters for comparing spreadsheets using the ShowSpreadsheetComparison procedure.
// 
// Returns:
//  Structure:
//    * SpreadsheetDocumentsAddress - String - The addresses in the temporary storage of the spreadsheets being compared.
//    * Title - String - The form's title. If not specified, then "Compare spreadsheet documents".
//    * TitleLeft - String - The title of the first spreadsheet (on the left).
//    * TitleRight - String - The title of the second spreadsheet (on the right).
//
Function SpreadsheetComparisonParameters() Export
	
	Result = New Structure;
	Result.Insert("SpreadsheetDocumentsAddress", "");
	Result.Insert("Title", "");
	Result.Insert("TitleLeft", "");
	Result.Insert("TitleRight", "");
	Return Result;
	
EndFunction

// See StandardSubsystemsServer.IsBaseConfigurationVersion
Function IsBaseConfigurationVersion() Export
	
	Return ClientParameter("IsBaseConfigurationVersion");
	
EndFunction

// See StandardSubsystemsServer.IsTrainingPlatform
Function IsTrainingPlatform() Export
	
	Return ClientParameter("IsTrainingPlatform");
	
EndFunction

#Region ErrorProcessing

// Calls the method "ShowErrorInfo" (object "ErrorProcessing").
// Intended for catching errors with the extension
// during automatic testing. 
//
// Parameters:
//  ErrorInfo - ErrorInfo
//
// Example:
//	Parameters:
//	Result - See TimeConsumingOperationsClient.NewResultLongOperation
//	AdditionalParameters - Undefined
//	//
//	
//	&AtClient
//		Procedure RefreshCurrentListCompletion(Result, AdditionalParameters) Export
//			If Result = Undefined Then
//		Return;
//		EndIf;
//			If Result.Status = "Error" Then
//			 StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
//		Return;
//		EndIf;
//	... // Status = "Completed2"
// EndProcedure
//
Procedure OutputErrorInfo(ErrorInfo) Export
	
	ErrorProcessing.ShowErrorInfo(ErrorInfo);
	
EndProcedure

// Hides the form element if the error category allows it
// considering the "IsErrorRequiresRestart" parameter.
// Sets the text of mandatory reporting if "ErrorInformationSendingMode" is set to "Send".
// If it is set to "AskUser" or "Auto", it sets the text of optional reporting.
// We recommend that you call "OnOpen" in custom error forms.
// 
// 
//
// Parameters:
//  Item - FormField, FormButton - Form element the visibility and title applies to.
//  ErrorInfo  - ErrorInfo - Error whose category is used to determine the reporting.
//  IsErrorRequiresRestart - Boolean - The flag is considered when determining the link visibility.
//    Usually, if an error invokes exit or reboot, its reporting is mandatory.
//
// Example:
//	#Region Variables
//	&AtClient
//	Var ErrorReport, ErrorInfoReport;
//	#EndRegion
//	#Region EventHandlersForm
//	&AtClient
//	Procedure OnOpen(Cancel)
//		If Parameters.ErrorInfo <> Undefined Then
//			ErrorInfoReport = Parameters.ErrorInfo;
//			ErrorReport = New ErrorReport(ErrorInfoReport);
//			StandardSubsystemsClient.ConfigureVisibilityAndTitleForURLSendErrorReport(
//				Items.GenerateErrorReport, ErrorInfoReport);
//		EndIf;
//	EndProcedure
//	&AtClient
//	Procedure OnClose(Exit)
//		If ErrorReport <> Undefined Then
//			StandardSubsystemsClient.SendErrorReport(ErrorReport, ErrorInfoReport);
//		EndIf;
//	EndProcedure
//	#EndRegion
//	#Region FormHeaderItemsEventHandlers
//	&AtClient
//	Procedure GenerateErrorReport(Item)
//		StandardSubsystemsClient.ShowErrorReport(ErrorReport);
//	EndProcedure
//	#EndRegion
//
Procedure ConfigureVisibilityAndTitleForURLSendErrorReport(Item, ErrorInfo, IsErrorRequiresRestart = False) Export
	
	Settings = ClientParameter("ErrorInfoSendingSettings");
	CategoryForUser = ErrorProcessing.ErrorCategoryForUser(ErrorInfo);
	
	Item.Visible =
		    Not IsErrorRequiresRestart And CategoryForUser = ErrorCategory.OtherError
		Or Not IsErrorRequiresRestart And CategoryForUser = ErrorCategory.ConfigurationError
		Or    IsErrorRequiresRestart And CategoryForUser <> ErrorCategory.SessionError;
	
	If Settings.SendOutMode = ErrorReportingMode.Send Then
		Item.Title = NStr("vi = 'Sẽ gửi tự động báo cáo về lỗi.
			|Tùy chỉnh báo cáo...';
			|ru = 'Отчет об ошибке будет отправлен автоматически.
			|Настроить отчет...';
			|en = 'The error report will be sent out automatically.
			|Configure the report…'; fa = 'The error report will be sent out automatically.
			|Configure the report…';
			|it = 'Отчет об ошибке будет отправлен автоматически.
			|Настроить отчет...';
			|pl = 'The error report will be sent out automatically.
			|Configure the report…';
			|tr = 'Hata raporu otomatik olarak gönderilecektir.
			|Rapor ayarla..'");
	Else
		Item.Title = NStr("vi = 'Lập báo cáo về lỗi';
							|ru = 'Сформировать отчет об ошибке';
							|en = 'Generate error report'; fa = 'ایجاد گزارش خطا';
							|it = 'Сформировать отчет об ошибке';
							|pl = 'Generate error report';
							|tr = 'Hata raporu oluştur'");
	EndIf;
	
EndProcedure

// Opens an error report for the user to review and configure.
// The report will be either saved to a file or sent to support
// (if a service address is specified and "DontSend" is not configured in "ErrorReportingMode").
// 
//
// Parameters:
//  ReportToSend - ErrorReport
//
// Example:
//	#Region Variables
//	&AtClient
//	Var ErrorReport, ErrorInfoReport;
//	#EndRegion
//	#Region EventHandlersForm
//	&AtClient
//	Procedure OnOpen(Cancel)
//		If Parameters.ErrorInfo <> Undefined Then
//			ErrorInfoReport = Parameters.ErrorInfo;
//			ErrorReport = New ErrorReport(ErrorInfoReport);
//			StandardSubsystemsClient.ConfigureVisibilityAndTitleForURLSendErrorReport(
//				Items.GenerateErrorReport, ErrorInfoReport);
//		EndIf;
//	EndProcedure
//	&AtClient
//	Procedure OnClose(Exit)
//		If ErrorReport <> Undefined Then
//			StandardSubsystemsClient.SendErrorReport(ErrorReport, ErrorInfoReport);
//		EndIf;
//	EndProcedure
//	#EndRegion
//	#Region FormHeaderItemsEventHandlers
//	&AtClient
//	Procedure GenerateErrorReport(Item)
//		StandardSubsystemsClient.ShowErrorReport(ErrorReport);
//	EndProcedure
//	#EndRegion
//
Procedure ShowErrorReport(ReportToSend) Export
	
	Settings = ClientParameter("ErrorInfoSendingSettings");
	
	If ValueIsFilled(Settings.SendOutAddress)
	   And Settings.SendOutMode <> ErrorReportingMode.DontSend Then
		
		ReportToSend.Send(True);
	Else
		ReportToSend.Write(, True);
	EndIf;
	
EndProcedure

// Non-interactively sends an error report if the category allows it
// (considering the "Exit" parameter) and the admin configured "Send" in "ErrorInformationSendingMode".
// We recommend that you call "OnOpen" in custom error forms.
// 
//
// Parameters:
//  ReportToSend - ErrorReport
//  ErrorInfo  - ErrorInfo - Error whose category is used to determine the reporting.
//  IsErrorRequiresRestart - Boolean - The flag is considered when determining error reporting.
//    Usually, if an error invokes exit or reboot, reporting is mandatory.
//    Should be assigned the same value as in "ConfigureVisibilityAndTitleForURLSendErrorReport".
//
// Example:
//	#Region Variables
//	&AtClient
//	Var ErrorReport, ErrorInfoReport;
//	#EndRegion
//	#Region EventHandlersForm
//	&AtClient
//	Procedure OnOpen(Cancel)
//		If Parameters.ErrorInfo <> Undefined Then
//			ErrorInfoReport = Parameters.ErrorInfo;
//			ErrorReport = New ErrorReport(ErrorInfoReport);
//			StandardSubsystemsClient.ConfigureVisibilityAndTitleForURLSendErrorReport(
//				Items.GenerateErrorReport, ErrorInfoReport);
//		EndIf;
//	EndProcedure
//	&AtClient
//	Procedure OnClose(Exit)
//		If ErrorReport <> Undefined Then
//			StandardSubsystemsClient.SendErrorReport(ErrorReport, ErrorInfoReport);
//		EndIf;
//	EndProcedure
//	#EndRegion
//	#Region FormHeaderItemsEventHandlers
//	&AtClient
//	Procedure GenerateErrorReport(Item)
//		StandardSubsystemsClient.ShowErrorReport(ErrorReport);
//	EndProcedure
//	#EndRegion
//
Procedure SendErrorReport(ReportToSend, ErrorInfo, IsErrorRequiresRestart = False) Export
	
	Settings = ClientParameter("ErrorInfoSendingSettings");
	
	If Not ValueIsFilled(Settings.SendOutAddress)
	 Or Settings.SendOutMode <> ErrorReportingMode.Send Then
		Return;
	EndIf;
	
	CategoryForUser = ErrorProcessing.ErrorCategoryForUser(ErrorInfo);
	
	If IsErrorRequiresRestart And CategoryForUser <> ErrorCategory.SessionError
	 Or Not IsErrorRequiresRestart
	   And (    CategoryForUser = ErrorCategory.OtherError
	      Or CategoryForUser = ErrorCategory.ConfigurationError) Then
		
		ReportToSend.Send(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region ApplicationEventsProcessing

// Disables the exit confirmation.
Procedure SkipExitConfirmation() Export
	
	ApplicationParameters.Insert("StandardSubsystems.SkipExitConfirmation", True);
	
EndProcedure

// Performs the standard actions before the user starts working
// with a data area or with an infobase in the local mode.
//
// Is intended for calling modules of the managed or ordinary application from the BeforeStart handler.
//
// Parameters:
//  CompletionNotification - CallbackDescription - Is skipped if managed or ordinary application modules are called from the BeforeStart 
//                         handler. In other cases, after the application started up, the notification with a parameter of the Structure type
//                         is called. The structure fields are:
//                         > Cancel - Boolean - False if the application started successfully, True if authorization is not
//                         executed;
//                         > Restart - Boolean - if the application should be restarted;
//                         > AdditionalParametersOfCommandLine - String - for restart.
//
Procedure BeforeStart(Val CompletionNotification = Undefined) Export
	
	BeginTime = CurrentUniversalDateInMilliseconds();
	
	If ApplicationParameters = Undefined Then
		ApplicationParameters = New Map;
	EndIf;
	
	ApplicationParameters.Insert("StandardSubsystems.PerformanceMonitor.StartTime1", BeginTime);
	
	If CompletionNotification <> Undefined Then
		CommonClientServer.CheckParameter("StandardSubsystemsClient.BeforeStart", 
			"CompletionNotification", CompletionNotification, Type("CallbackDescription"));
	EndIf;
	
	SignInToDataArea();
	
	ActionsBeforeStart(CompletionNotification);
	
	If Not ApplicationStartupLogicDisabled()
	   And Not CommonClient.SubsystemExists("OnlineUserSupport.CoreISL") Then
		Return;
	EndIf;
	
	Try
		ModuleOnlineUserSupportClientServer =
			CommonClient.CommonModule("OnlineUserSupportClientServer");
		ISLVersion = ModuleOnlineUserSupportClientServer.LibraryVersion();
		// Attach the settings request handler for the licensing client
		// to validate the update's legitimacy.
		If CommonClientServer.CompareVersions(ISLVersion, "2.7.1.0") > 0 Then
			ModuleLicensingClientClient = CommonClient.CommonModule("LicensingClientClient");
			ModuleLicensingClientClient.AttachLicensingClientSettingsRequest();
		EndIf;
	Except
		If ApplicationStartupLogicDisabled() Then
			Return;
		EndIf;
		Raise;
	EndTry;
	
EndProcedure

// Performs the standard actions when the user starts working
// with a data area or with an infobase in the local mode.
//
// Is intended for calling modules of the managed or ordinary application from the OnStart handler.
//
// Parameters:
//  CompletionNotification - CallbackDescription - Is skipped if managed or ordinary application modules are called from the OnStart 
//                         handler. In other cases, after the application started up, the notification with a parameter of the Structure type
//                         is called. The structure fields are:
//                         > Cancel - Boolean - False if the application started successfully, True if authorization is not
//                         executed;
//                         > Restart - Boolean - if the application should be restarted;
//                         > AdditionalParametersOfCommandLine - String - for restart.
//
//  ContinuousExecution - Boolean - For internal use only.
//                          For proceeding from the BeforeStart
//                          handler executed in the interactive processing mode.
//
Procedure OnStart(Val CompletionNotification = Undefined, ContinuousExecution = True) Export
	
	If InteractiveHandlerBeforeStartInProgress() Then
		Return;
	EndIf;
	
	If ApplicationStartupLogicDisabled() Then
		Return;
	EndIf;
	
	If CompletionNotification <> Undefined Then
		CommonClientServer.CheckParameter("StandardSubsystemsClient.OnStart", 
			"CompletionNotification", CompletionNotification, Type("CallbackDescription"));
	EndIf;
	CommonClientServer.CheckParameter("StandardSubsystemsClient.OnStart", 
		"ContinuousExecution", ContinuousExecution, Type("Boolean"));
	
	ActionsOnStart(CompletionNotification, ContinuousExecution);
	
EndProcedure

// Performs the standard actions when the user logs off
// from a data area or exits the application in the local mode.
//
// Is intended for calling modules of the managed or ordinary application from the BeforeExit handler.
//
// Parameters:
//  Cancel                - Boolean - a return value. A flag indicates whether the exit must be canceled 
//                         for the BeforeExit event handler, both for program
//                         or for interactive cases. If the user
//                         interaction was successful, the application exit can be continued.
//  WarningText  - String - See BeforeExit() in Syntax Assistant.
//
Procedure BeforeExit(Cancel = False, WarningText = "") Export
	
	If Not DisplayWarningsBeforeShuttingDownTheSystem(Cancel) Then
		Return;
	EndIf;
	
	Warnings = WarningsBeforeSystemShutdown(Cancel);
	If Warnings.Count() = 0 Then
		If Not ClientParameter("AskConfirmationOnExit") Then
			Return;
		EndIf;
		WarningText = NStr("vi = 'Kết thúc làm việc với ứng dụng?';
							|ru = 'Завершить работу с приложением?';
							|en = 'Exit the app?'; fa = 'Exit the app?';
							|it = 'Завершить работу с приложением?';
							|pl = 'Exit the app?';
							|tr = 'Uygulamadan çıkılsın mı?'");
		Cancel = True;
	Else
		Cancel = True;
		WarningArray = New Array;
		For Each Warning In Warnings Do
			WarningArray.Add(Warning.WarningText);
		EndDo;
		If Not IsBlankString(WarningText) Then
			WarningText = WarningText + Chars.LF;
		EndIf;
		WarningArray.Add(Chars.LF);
		WarningArray.Add(NStr("vi = 'Để thực hiện điều này, hãy chọn ""Tiếp tục làm việc"" và sau đó nhấn vào cảnh báo bật lên.';
								|ru = 'Для этого выберите ""Продолжить работу"" и затем нажмите на всплывающее оповещение.';
								|en = 'To do so, select ""Continue"" and click the pop-up notification.'; fa = 'To do so, select ""Continue"" and click the pop-up notification.';
								|it = 'Для этого выберите ""Продолжить работу"" и затем нажмите на всплывающее оповещение.';
								|pl = 'To do so, select ""Continue"" and click the pop-up notification.';
								|tr = 'Bunu yapmak için ""Devam Et""i seçin ve ardından açılır bildirime tıklayın.'"));
		WarningText = WarningText + StrConcat(WarningArray, Chars.LF);
		
		AttachIdleHandler("ShowExitWarning", 0.1, True);
	EndIf;
	SetClientParameter("ExitWarnings", Warnings);
	
EndProcedure

// Runs standard actions when handling the acquisition of the Collaboration System user choice form.
//
// Parameters:
//  ChoicePurpose - CollaborationSystemUsersChoicePurpose
//  Form - ClientApplicationForm
//  ConversationID - CollaborationSystemConversationID
//  Parameters - Structure
//  SelectedForm - String
//  StandardProcessing - Boolean
//
Procedure CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
			Form, ConversationID, Parameters, SelectedForm, StandardProcessing) Export
	
	// StandardSubsystems.Conversations
	If CommonClient.SubsystemExists("StandardSubsystems.Conversations") Then
		ModuleConversationsInternalClient = CommonClient.CommonModule("ConversationsInternalClient");
		ModuleConversationsInternalClient.OnGetCollaborationSystemUsersChoiceForm(ChoicePurpose,
			Form, ConversationID, Parameters, SelectedForm, StandardProcessing);
	EndIf;
	// End StandardSubsystems.Conversations
		
EndProcedure

// Returns a structure parameters for showing the warnings before exit the application.
// To use in CommonClientOverridable.BeforeExit.
//
// Returns:
//  Structure:
//    WarningText - String - Dialog text displayed upon exiting the web or thin client.
//                                    For example: "Unsaved changes will be lost."
//                                    The other parameters affect the dialog appearance:
//                                    CheckBoxText - String - Displays a checkbox with the passed text.
//    For example: "Finish editing files (5)." 
//                                    NoteText - String - Text displayed above the control (checkbox or hyperlink).
//    For example: "Unsaved files".
//                                    HyperlinkText - String - Text of the hyperlink displayed on the form.
//    For example: "Files being edited (5)."
//                                    ExtendedTooltip - String - Text of the tooltip displayed to the right from the control.
//    For example: "View the list of files being edited".
//                                    Priorities - Number - Warning's position in the list (the greater, the higher). 
//                                    OutputSingleWarning - Boolean - If set to "True", other warnings are hidden from the list.
//    ActionIfFlagSet - Structure with the following fields:
//    
//                                         
//    
//      * Form          - String    - Form to open if the user selected the checkbox.
//                                     For example, "DataProcessor.Files.FilesToEdit".
//      * FormParameters - Structure - Arbitrary structure of form open parameters. 
//    :
//      * Form          - String    - Form to open if the user selected the checkbox.
//                                     For example, "DataProcessor.Files.FilesToEdit".
//      * FormParameters - Structure - Arbitrary structure of form open parameters.
//      * ApplicationWarningForm - String - a path to the form to be opened
//                                        instead of the standard form if the current 
//                                        warning is the only one in the list.
//                                        For example, "DataProcessor.Files.FilesToEdit".
//      * ApplicationWarningFormParameters - Structure - an arbitrary structure of
//                                                 parameters for the form described above.
//      * WindowOpeningMode - FormWindowOpeningMode - a mode of opening the Form or ApplicationWarningForm forms.
// 
Function WarningOnExit() Export
	
	ActionIfFlagSet = New Structure;
	ActionIfFlagSet.Insert("Form", "");
	ActionIfFlagSet.Insert("FormParameters", Undefined);
	
	ActionOnClickHyperlink = New Structure;
	ActionOnClickHyperlink.Insert("Form", "");
	ActionOnClickHyperlink.Insert("FormParameters", Undefined);
	ActionOnClickHyperlink.Insert("ApplicationWarningForm", "");
	ActionOnClickHyperlink.Insert("ApplicationWarningFormParameters", Undefined);
	ActionOnClickHyperlink.Insert("WindowOpeningMode", Undefined);
	
	WarningParameters = New Structure;
	WarningParameters.Insert("CheckBoxText", "");
	WarningParameters.Insert("NoteText", "");
	WarningParameters.Insert("WarningText", "");
	WarningParameters.Insert("ExtendedTooltip", "");
	WarningParameters.Insert("HyperlinkText", "");
	WarningParameters.Insert("ActionIfFlagSet", ActionIfFlagSet);
	WarningParameters.Insert("ActionOnClickHyperlink", ActionOnClickHyperlink);
	WarningParameters.Insert("Priority", 0);
	WarningParameters.Insert("OutputSingleWarning", False);
	
	Return WarningParameters;
	
EndFunction

// Returns the values of parameters required for the operation of client-side code
// when starting configuration for one server call (to minimize client-server interaction
// and reduce startup time). 
// Using this function, you can access parameters in client-side code called from the event handlers:
// - BeforeStart,
// - OnStart.
//
// In these handlers, when starting the application, do not use cache reset commands
// of modules that reuse return values because this can lead to
// unpredictable errors and unneeded server calls.
// 
// Returns:
//   FixedStructure - Client parameters at startup. 
//                            See: CommonOverridable.OnAddClientParametersOnStart.
//
//
Function ClientParametersOnStart() Export
	
	Return StandardSubsystemsClientCached.ClientParametersOnStart();
	
EndFunction

// Returns parameters values required for the operation of client-side code configuration
// without additional server calls.
// 
// Returns:
//   FixedStructure - client parameters.
//                            See the content of properties at CommonOverridable.OnAddClientParameters.
//
Function ClientRunParameters() Export
	
	Return StandardSubsystemsClientCached.ClientRunParameters();
	
EndFunction

// See CommonClientOverridable.OnGlobalSearch
Procedure OnGlobalSearch(SearchString, SearchPlan) Export
	
	SSLSubsystemsIntegrationClient.OnGlobalSearch(SearchString, SearchPlan);
	CommonClientOverridable.OnGlobalSearch(SearchString, SearchPlan);
	
EndProcedure

// See CommonClientOverridable.OnGlobalSearchResultChoice
Procedure OnGlobalSearchResultChoice(ResultItem, StandardProcessing) Export
	
	SSLSubsystemsIntegrationClient.OnGlobalSearchResultChoice(
		ResultItem,
		StandardProcessing);
	CommonClientOverridable.OnGlobalSearchResultChoice(
		ResultItem,
		StandardProcessing);
	
EndProcedure

// See CommonClientOverridable.OnGlobalSearchResultActionChoice
Procedure OnGlobalSearchResultActionChoice(ResultItem, Action) Export
	
	SSLSubsystemsIntegrationClient.OnGlobalSearchResultActionChoice(
		ResultItem,
		Action);
	CommonClientOverridable.OnGlobalSearchResultActionChoice(
		ResultItem,
		Action);
	
EndProcedure

// See CommonClientOverridable.NavigationByURLProcessing
Procedure NavigationByURLProcessing(URLNavigationData,
	StandardProcessing) Export
	
	SSLSubsystemsIntegrationClient.NavigationByURLProcessing(
		URLNavigationData,
		StandardProcessing);
	CommonClientOverridable.NavigationByURLProcessing(
		URLNavigationData,
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// Called upon receiving a server notification.
// The notifications are sent on server in the OnSendServerNotification procedures.
// See the notification list in CommonOverridable.OnAddServerNotifications.
// 
// Parameters:
//  NameOfAlert - See ServerNotifications.SendServerNotification.NameOfAlert
//  Result     - See ServerNotifications.SendServerNotification.Result
//
// Example:
//	If NotificationName <> "StandardSubsystems.UsersSessions.SessionsLock" Then
//		Return;
//	EndIf;
//	If SessionTerminationInProgress() Then
//		EndUserSessions(Result);
//	ElsIf IsUserExitControlEnabled() Then
//		SessionTerminationModeManagement(Result);
//	EndIf;
//
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert = "StandardSubsystems.Core.FunctionalOptionsModified" Then
		DetachIdleHandler("RefreshInterfaceOnFunctionalOptionToggle");
		AttachIdleHandler("RefreshInterfaceOnFunctionalOptionToggle", 5*60, True);
		
	ElsIf NameOfAlert = "StandardSubsystems.Core.CachedValuesOutdated" Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Function ApplicationStartCompleted() Export
	
	ParameterName = "StandardSubsystems.ApplicationStartCompleted";
	If ApplicationParameters[ParameterName] = True Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function ClientParameter(ParameterName = Undefined) Export
	
	GlobalParameterName = "StandardSubsystems.ClientParameters";
	ClientParameters = ApplicationParameters[GlobalParameterName];
	
	If ClientParameters = Undefined Then
		// Filling the permanent parameters of the client.
		StandardSubsystemsClientCached.ClientParametersOnStart();
		ClientParameters = ApplicationParameters[GlobalParameterName];
	EndIf;
	
	If ParameterName = Undefined Then
		Return ClientParameters;
	Else
		Return ClientParameters[ParameterName];
	EndIf;
	
EndFunction

Procedure SetClientParameter(ParameterName, Value) Export
	GlobalParameterName = "StandardSubsystems.ClientParameters";
	ApplicationParameters[GlobalParameterName].Insert(ParameterName, Value);
EndProcedure

Procedure FillClientParameters(ClientParameters) Export
	
	ParameterName = "StandardSubsystems.ClientParameters";
	If TypeOf(ApplicationParameters[ParameterName]) <> Type("Structure") Then
		ApplicationParameters[ParameterName] = New Structure;
		ApplicationParameters[ParameterName].Insert("DataSeparationEnabled");
		ApplicationParameters[ParameterName].Insert("FileInfobase");
		ApplicationParameters[ParameterName].Insert("IsBaseConfigurationVersion");
		ApplicationParameters[ParameterName].Insert("IsTrainingPlatform");
		ApplicationParameters[ParameterName].Insert("IsExternalUserSession");
		ApplicationParameters[ParameterName].Insert("IsFullUser");
		ApplicationParameters[ParameterName].Insert("IsSystemAdministrator");
		ApplicationParameters[ParameterName].Insert("AuthorizedUser");
		ApplicationParameters[ParameterName].Insert("AskConfirmationOnExit");
		ApplicationParameters[ParameterName].Insert("SeparatedDataUsageAvailable");
		ApplicationParameters[ParameterName].Insert("StandaloneModeParameters");
		ApplicationParameters[ParameterName].Insert("PersonalFilesOperationsSettings");
		ApplicationParameters[ParameterName].Insert("LockedFilesCount");
		ApplicationParameters[ParameterName].Insert("IBBackupOnExit");
		ApplicationParameters[ParameterName].Insert("DisplayPermissionSetupAssistant");
		ApplicationParameters[ParameterName].Insert("SessionTimeOffset");
		ApplicationParameters[ParameterName].Insert("UniversalTimeCorrection");
		ApplicationParameters[ParameterName].Insert("StandardTimeOffset");
		ApplicationParameters[ParameterName].Insert("ClientDateOffset");
		ApplicationParameters[ParameterName].Insert("DefaultLanguageCode");
		ApplicationParameters[ParameterName].Insert("AdditionalLanguagesCount");
		ApplicationParameters[ParameterName].Insert("ErrorInfoSendingSettings");
		ApplicationParameters[ParameterName].Insert("StyleItems");
	EndIf;
	If Not ApplicationParameters[ParameterName].Property("PerformanceMonitor")
	   And ClientParameters.Property("PerformanceMonitor") Then
		ApplicationParameters[ParameterName].Insert("PerformanceMonitor");
	EndIf;
	
	FillPropertyValues(ApplicationParameters[ParameterName], ClientParameters);
	
EndProcedure

// After the warning, calls the procedure with the following parameters: Result, AdditionalParameters.
//
// Parameters:
//  Parameters           - Structure - Contains the property:
//                          ContinuationHandler - NotifyDescription - Contains
//                          a procedure taking two parameters:
//                            Result, AdditionalParameters.
//
//  WarningDetails - Undefined - warning is not required.
//  WarningDetails - String - a warning text that should be shown.
//  WarningDetails - Structure:
//       * WarningText - String - a warning text that should be shown.
//       * Buttons              - ValueList - for the ShowQuestionToUser procedure.
//       * QuestionParameters    - Structure - contains a subset of the properties
//                                 to be overridden from among ones that
//                                 returned by the QuestionToUserParameters function.
//
Procedure ShowMessageBoxAndContinue(Parameters, WarningDetails) Export
	
	NotificationWithResult = Parameters.ContinuationHandler;
	
	If WarningDetails = Undefined Then
		RunCallback(NotificationWithResult);
		Return;
	EndIf;
	
	Buttons = New ValueList;
	QuestionParameters = QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.LockWholeInterface = True;
	QuestionParameters.Picture = PictureLib.DialogExclamation;
	
	If Parameters.Cancel Then
		Buttons.Add("ExitApp", NStr("vi = 'Kết thúc công việc';
									|ru = 'Завершить работу';
									|en = 'Exit'; fa = 'خروج';
									|it = 'La sessione è stata completata ';
									|pl = 'Zakończ pracę';
									|tr = 'Sonuçlandır'"));
		QuestionParameters.DefaultButton = "ExitApp";
	Else
		Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Continue';
									|tr = 'Devam'"));
		Buttons.Add("ExitApp",  NStr("vi = 'Kết thúc công việc';
									|ru = 'Завершить работу';
									|en = 'Exit'; fa = 'خروج';
									|it = 'La sessione è stata completata ';
									|pl = 'Zakończ pracę';
									|tr = 'Sonuçlandır'"));
		QuestionParameters.DefaultButton = "Continue";
	EndIf;
	
	If TypeOf(WarningDetails) = Type("Structure") Then
		WarningText = WarningDetails.WarningText;
		Buttons = WarningDetails.Buttons;
		FillPropertyValues(QuestionParameters, WarningDetails.QuestionParameters);
	Else
		WarningText = WarningDetails;
	EndIf;
	
	ClosingNotification1 = New CallbackDescription("ShowMessageBoxAndContinueCompletion", ThisObject, Parameters);
	ShowQuestionToUser(ClosingNotification1, WarningText, Buttons, QuestionParameters);
	
EndProcedure

// Returns a name of the executable file depending on the client type.
//
// Returns:
//  String
//
Function ApplicationExecutableFileName(GetDesignerFileName = False) Export
	
	FileNameTemplate = "1cv8[TrainingPlatform].exe";
	
#If ThinClient Then
	If Not GetDesignerFileName Then
		FileNameTemplate = "1cv8c[TrainingPlatform].exe";
	EndIf;	
#EndIf
	
	Return StrReplace(FileNameTemplate, "[TrainingPlatform]", ?(IsTrainingPlatform(), "t", ""));
	
EndFunction

// Sets or cancels the storage of a client application form reference in a global variable.
// Required when a reference to a form is passed through AdditionalParameters
// in the NotifyDescription object that does not lock the release of a closed form.
//
Procedure SetFormStorageOption(Form, Location) Export
	
	Storage = ApplicationParameters["StandardSubsystems.TemporaryManagedFormsRefStorage"];
	If Storage = Undefined Then
		Storage = New Map;
		ApplicationParameters.Insert("StandardSubsystems.TemporaryManagedFormsRefStorage", Storage);
	EndIf;
	
	If Location Then
		Storage.Insert(Form, New Structure("Form", Form));
	ElsIf Storage.Get(Form) <> Undefined Then
		Storage.Delete(Form);
	EndIf;
	
EndProcedure

// Checks that the current data is not defined and not a group.
// Intended for dynamic list form table handlers.
//
// Parameters:
//  TableOrCurrentData - FormTable - a dynamic list form table to check the current data.
//                          - Undefined
//                          - FormDataStructure
//                          - Structure - current data to be checked.
//
// Returns:
//  Boolean
//
Function IsDynamicListItem(TableOrCurrentData) Export
	
	If TypeOf(TableOrCurrentData) = Type("FormTable") Then
		CurrentData = TableOrCurrentData.CurrentData;
	Else
		CurrentData = TableOrCurrentData;
	EndIf;
	
	If TypeOf(CurrentData) <> Type("FormDataStructure")
	   And TypeOf(CurrentData) <> Type("Structure") Then
		Return False;
	EndIf;
	
	If CurrentData.Property("RowGroup") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// See StandardSubsystemsServer.ApplicationStartupLogicDisabled
Function ApplicationStartupLogicDisabled() Export
	Return StrFind(LaunchParameter, "DisableSystemStartupLogic") > 0;
EndFunction

// Returns configuration style elements.
//
// Returns:
//  Structure:
//   * Key - String - Name of the style element. For example, "HyperlinkColor".
//   * Value - MetadataObjectStyleItem
//
Function StyleItems() Export
	
	StyleElementsParameter = ClientParameter("StyleItems");
	If TypeOf(StyleElementsParameter) = Type("Structure") Then
		Return StyleElementsParameter;
	EndIf;
	
	StyleItems = New Structure;
	
	For Each StyleItem In StyleElementsParameter Do
#If ThickClientOrdinaryApplication Then
		StyleItems.Insert(StyleItem.Key, StyleItem.Value.Get());
#Else
		StyleItems.Insert(StyleItem.Key, StyleItem.Value);
#EndIf
	EndDo;
	
	SetClientParameter("StyleItems", StyleItems);
	
	Return StyleItems;
	
EndFunction

// Modifies the notification without result to the notification with result
//
// Returns:
//  CallbackDescription
//
Function NotificationWithoutResult(NotificationWithResult) Export
	
	Return New CallbackDescription("NotifyWithEmptyResult", ThisObject, NotificationWithResult);
	
EndFunction

Function NewNotificationParameterForSpreadsheetDocumentWrite() Export
	
	NotificationParameters = New Structure;
	
	NotificationParameters.Insert("PathToFile", "");
	NotificationParameters.Insert("TemplateMetadataObjectName", "");
	NotificationParameters.Insert("LanguageCode", "");
	NotificationParameters.Insert("Presentation", "");
	NotificationParameters.Insert("DataSources", New Array());
	NotificationParameters.Insert("DefaultPrintForm", False);
	NotificationParameters.Insert("PrintFormDescription", "");
	NotificationParameters.Insert(
		"ExportSaveFormat",
		PredefinedValue("Enum.ObjectsExportFormats.EmptyRef"));
	NotificationParameters.Insert("TemplateForObjectExport", False);
	
	Return NotificationParameters;
	
EndFunction

#Region TechnicalSupport

// Returns main, system, and additional information for online support.
//
// The system information includes the client computer details.
// Server method: See StandardSubsystemsServer.SupportInformation.
//
// Example:
//  Demo configuration, version X.X, X.X.XX.XX
//   1C:Enterprise: X.X.XX.XXXX
//  Standart Subsystem Library: X.X.XX.XX
//
//  System info
//  OS: XXX
//  CPU: XXX
//  RAM: XXX
//  Application: XXX
//
//  Additional info
//  COM connector: XXX
//  Base configuration: No
//  Full-access user: No
//  Sandbox: No
//  Modified configuration: No
//
// Returns:
//  String - Information for technical support.
//
Function SupportInformation() Export
	
	SupportInformation = StandardSubsystemsClientServer.NewInfoForSupport();
	
	SystemInfo = New SystemInfo;
	FillPropertyValues(SupportInformation, SystemInfo);
	
	If ApplicationStartCompleted() Then
		ConfigurationParameters = ClientRunParameters();
	Else
		ConfigurationParameters = ClientParametersOnStart();
	EndIf;
	
	ParameterUnavailable = NStr("vi = 'không hợp lệ';
								|ru = 'недоступно';
								|en = 'Unavailable'; fa = 'در دسترس نیست';
								|it = 'Unavailable';
								|pl = 'Unavailable';
								|tr = 'kullanılamaz'");
	
	// ACC:1417-off - A dynamic property set.
	SupportInformation.ApplicationName1 = CommonClientServer.StructureProperty(
		ConfigurationParameters,
		"DetailedInformation",
		ParameterUnavailable);
	// ACC:1417-on
	
	// ACC:1417-off - A dynamic property set.
	SupportInformation.ApplicationVersion = CommonClientServer.StructureProperty(
		ConfigurationParameters,
		"ConfigurationVersion",
		ParameterUnavailable);
	// ACC:1417-on
	
	SupportInformation.SSLVersion = StandardSubsystemsServerCall.LibraryVersion();
	SupportInformation.COMConnectorName = CommonClientServer.COMConnectorName();
	SupportInformation.IsBaseConfiguration = IsBaseConfigurationVersion();
	SupportInformation.IsFullUser = UsersClient.IsFullUser();
	SupportInformation.IsTrainingPlatform = IsTrainingPlatform();
	
	// ACC:1417-off - A dynamic property set.
	SettingsOfUpdate = CommonClientServer.StructureProperty(
		ConfigurationParameters,
		"SettingsOfUpdate");
	// ACC:1417-on
	
	// ACC:1417-off - A dynamic property set.
	SupportInformation.ConfigurationChanged = CommonClientServer.StructureProperty(
		SettingsOfUpdate,
		"ConfigurationChanged",
		ParameterUnavailable);
	// ACC:1417-on
	
	Return StandardSubsystemsClientServer.SupportInformationText(SupportInformation);
	
EndFunction

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See SSLSubsystemsIntegrationClient.BeforeRecurringClientDataSendToServer
Procedure BeforeRecurringClientDataSendToServer(Parameters) Export
	
	ParameterName = "StandardSubsystems.Core.DynamicUpdateControl";
	If Not ServerNotificationsClient.TimeoutExpired(ParameterName) Then
		Return;
	EndIf;
	
	// ConfigurationOrExtensionsWasModified
	Parameters.Insert(ParameterName, True);
	
EndProcedure

// See CommonClientOverridable.AfterRecurringReceiptOfClientDataOnServer
Procedure AfterRecurringReceiptOfClientDataOnServer(Results) Export
	
	ParameterName = "StandardSubsystems.Core.DynamicUpdateControl";
	Result = Results.Get(ParameterName);
	If Result = Undefined Then
		Return;
	EndIf;
	
	// ConfigurationOrExtensionsWasModified
	PictureDialogInformation = PictureLib.DialogInformation;
	ShowUserNotification(
		NStr("vi = 'Đã cài đặt bản cập nhật ứng dụng';
			|ru = 'Установлено обновление приложения';
			|en = 'Application update installed'; fa = 'به‌روزرسانی برنامه نصب شد';
			|it = 'Установлено обновление приложения';
			|pl = 'Application update installed';
			|tr = 'Uygulama güncellemesi kuruldu'"),
		"e1cib/app/CommonForm.DynamicUpdateControl",
		Result, PictureDialogInformation,
		UserNotificationStatus.Important,
		"TheProgramUpdateIsInstalled");
	
EndProcedure

#EndRegion

#Region OutputOfExecutionResult

// Expands nodes of the specified tree on the form.
//
// Parameters:
//   Form                     - ClientApplicationForm - a form where the control item with a value tree is placed.
//   FormItemName          - String           - a name of the item with a form table (value tree) and the associated with it
//                                                  form attribute (should match).
//   TreeRowID - Arbitrary     - an ID of the tree row to be expanded.
//                                                  If "*" is passed, only top-level nodes are expanded.
//                                                  If Undefined is passed, tree rows are not expanded.
//                                                  By default: "*".
//   ExpandWithSubordinates   - Boolean           - If True, all subordinate nodes should also be expanded.
//                                                  Default value is False.
//
Procedure ExpandTreeNodes(Form, FormItemName, TreeRowID = "*", ExpandWithSubordinates = False) Export
	
	TableItem = Form.Items[FormItemName];
	If TreeRowID = "*" Then
		Nodes = Form[FormItemName].GetItems();
		For Each Node In Nodes Do
			TableItem.Expand(Node.GetID(), ExpandWithSubordinates);
		EndDo;
	Else
		TableItem.Expand(TreeRowID, ExpandWithSubordinates);
	EndIf;
	
EndProcedure

// Notifies the forms opening and dynamic lists about mass changes in objects of various types,
// using Notify and NotifyChange global context methods.
//
// Parameters:
//  ModifiedObjectTypes - See StandardSubsystemsServer.PrepareFormChangeNotification
//  FormNotificationParameter - Arbitrary - a message parameter for the Notify method.
//
Procedure NotifyFormsAboutChange(ModifiedObjectTypes, FormNotificationParameter = Undefined) Export
	
	For Each ObjectType In ModifiedObjectTypes Do
		Notify(ObjectType.Value.EventName, 
			?(FormNotificationParameter <> Undefined, FormNotificationParameter, New Structure), 
			ObjectType.Value.EmptyRef);
		NotifyChanged(ObjectType.Key);
	EndDo;
	
EndProcedure

// Opens the object list form with positioning on the object.
//
// Parameters:
//   Ref - AnyRef - an object to be shown in the list.
//   ListFormName - String - a list form name.
//       If Undefined the transfer will automatically defined requires Server call).
//   FormParameters - Structure - additional list form opening parameters.
//
Procedure ShowInList(Ref, ListFormName, FormParameters = Undefined) Export
	If Ref = Undefined Then
		Return;
	EndIf;
	
	If ListFormName = Undefined Then
		FullName = StandardSubsystemsServerCall.FullMetadataObjectName(TypeOf(Ref));
		If FullName = Undefined Then
			Return;
		EndIf;
		ListFormName = FullName + ".ListForm";
	EndIf;
	
	If FormParameters = Undefined Then
		FormParameters = New Structure;
	EndIf;
	
	FormParameters.Insert("CurrentRow", Ref);
	
	Form = GetForm(ListFormName, FormParameters, , True);
	Form.Open();
	Form.ExecuteNavigation(Ref);
EndProcedure

// Displays the text, which users can copy.
//
// Parameters:
//   Handler - CallbackDescription - description of the procedure to be called after showing the message.
//       Returns a value like ShowQuestionToUser().
//   Text     - String - an information text.
//   Title - String - window title. "Details" by default.
//
Procedure ShowDetailedInfo(Handler, Text, Title = Undefined) Export
	DialogSettings = New Structure;
	DialogSettings.Insert("PromptDontAskAgain", False);
	DialogSettings.Insert("Picture", Undefined);
	DialogSettings.Insert("ShowPicture", False);
	DialogSettings.Insert("CanCopy", True);
	DialogSettings.Insert("DefaultButton", 0);
	DialogSettings.Insert("HighlightDefaultButton", False);
	DialogSettings.Insert("Title", Title);
	
	If Not ValueIsFilled(DialogSettings.Title) Then
		DialogSettings.Title = NStr("vi = 'Chi tiết';
									|ru = 'Подробнее';
									|en = 'Details'; fa = 'جزئیات';
									|it = 'Dettagliatamente';
									|pl = 'Details';
									|tr = 'Ayrıntılar'");
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add(0, NStr("vi = 'Đóng';
						|ru = 'Закрыть';
						|en = 'Close'; fa = 'بستن';
						|it = 'Chiudere';
						|pl = 'Close';
						|tr = 'Kapat'"));
	
	ShowQuestionToUser(Handler, Text, Buttons, DialogSettings);
EndProcedure

#If Not WebClient And Not MobileClient Then

// System application directory, for example "C:\Windows\System32".
// It is used only in Windows OS.
//
// Returns:
//  String
//
Function SystemApplicationsDirectory() Export
	
	ShellObject = New COMObject("Shell.Application");
	
	SystemInfo = New SystemInfo;
	If SystemInfo.PlatformType = PlatformType.Windows_x86 Then 
		// For 32-bit OS: "C:\Windows\System32".
		// For 64-bit OS: "C:\Windows\SysWOW64".
		FolderObject = ShellObject.Namespace(41);
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then 
		// For any system: "C:WindowsSystem32".
		FolderObject = ShellObject.Namespace(37);
	EndIf;
	
	Return FolderObject.Self.Path + "\";
	
EndFunction

#EndIf

// The asynchronous alternative of the 1C:Enterprise method ExecuteNotifyProcessing.
// It handles notifications asynchronously, like 1C:Enterprise methods (for example, StartGetFiles).
// Intended for cases when notifications should be processed after the synchronous call end.
// That is, when you need to minimize the delay.
// 
// Parameters:
//  CallbackDescription - CallbackDescription - Notification to be handled.
//  Result  - Arbitrary - Value to be passed to the "Result" parameter
//               of the RunCallback platform method.
//
Procedure StartNotificationProcessing(CallbackDescription, Result = Undefined) Export
	
	Context = New Structure;
	Context.Insert("Notification", CallbackDescription);
	Context.Insert("Result", Result);
	
	Stream = New MemoryStream;
	Stream.BeginGetSize(New CallbackDescription(
		"StartNotificationProcessingCompletion", ThisObject, Context));
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region BeforeStart

// Continues the BeforeStart procedure.
Procedure ActionsBeforeStart(CompletionNotification)
	
	Parameters = ProcessingParametersBeforeStartSystem();
	
	// External parameters of the result description.
	Parameters.Insert("Cancel", False);
	Parameters.Insert("Restart", False);
	Parameters.Insert("AdditionalParametersOfCommandLine", "");
	
	// External parameters of the execution management.
	Parameters.Insert("InteractiveHandler", Undefined); // CallbackDescription
	Parameters.Insert("ContinuationHandler",   Undefined); // CallbackDescription
	Parameters.Insert("ContinuousExecution", True);
	Parameters.Insert("RetrievedClientParameters", New Structure);
	Parameters.Insert("CalledProcedures", New Array);
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient", "BeforeStart");
	
	// Internal parameters.
	Parameters.Insert("CompletionNotification", CompletionNotification);
	Parameters.Insert("CompletionProcessing", New CallbackDescription(
		"ActionsBeforeStartCompletionHandler", ThisObject));
	
	UpdateClientParameters(Parameters, True, CompletionNotification <> Undefined);
	
	// Preparing to proceed to the next procedure
	Parameters.Insert("ContinuationHandler", New CallbackDescription(
		"ActionsBeforeStartInIntegrationProcedure", ThisObject));
	
	If ApplicationStartupLogicDisabled() Then
		Try
			// Check the right to disable the startup logic. Specify server parameters.
			ClientProperties = New Structure;
			FillInTheClientParametersOnTheServer(ClientProperties);
			StandardSubsystemsServerCall.CheckDisableStartupLogicRight(ClientProperties);
			If ClientProperties.Property("ErrorThereIsNoRightToDisableTheSystemStartupLogic") Then
				UsersInternalClient.InstallInteractiveDataProcessorOnInsufficientRightsToSignInError(
					Parameters, ClientProperties.ErrorThereIsNoRightToDisableTheSystemStartupLogic);
				InstallLatestProcedure(Parameters, "UsersInternalClient",
					"InstallInteractiveDataProcessorOnInsufficientRightsToSignInError");
			EndIf;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			StandardSubsystemsServerCall.WriteErrorToEventLogOnStartOrExit(
				False, "Run", ErrorText);
			UsersInternalClient.InstallInteractiveDataProcessorOnInsufficientRightsToSignInError(
				Parameters, ErrorText);
			InstallLatestProcedure(Parameters, "UsersInternalClient",
				"InstallInteractiveDataProcessorOnInsufficientRightsToSignInError");
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		HideDesktopOnStart(True, True);
		Return;
	EndIf;
	
	// The standard initial server call in order to
	// pre-populate the client operating parameters on the server.
	Try
		CommonClient.SubsystemExists("StandardSubsystems.Core");
	Except
		HandleErrorBeforeStart(Parameters, ErrorInfo(), True);
	EndTry;
	InstallLatestProcedure(Parameters, "CommonClient", "SubsystemExists");
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartInIntegrationProcedure(Var_Undefined, Context) Export
	
	Parameters = ProcessingParametersBeforeStartSystem();
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
		"ActionsBeforeStartInIntegrationProcedure");
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New CallbackDescription(
		"ActionsBeforeStartInIntegrationProcedureModules", ThisObject));
	
	Parameters.Insert("CurrentModuleIndex", 0);
	Parameters.Insert("AddedModules", New Array);
	Try
		Parameters.Insert("Modules", New Array);
		SSLSubsystemsIntegrationClient.BeforeStart(Parameters);
		InstallLatestProcedure(Parameters, "SSLSubsystemsIntegrationClient", "BeforeStart");
		Parameters.Insert("AddedModules", Parameters.Modules);
		Parameters.Delete("Modules");
	Except
		HandleErrorBeforeStart(Parameters, ErrorInfo(), True);
	EndTry;
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartInIntegrationProcedureModules(Var_Undefined, Context) Export
	
	While True Do
		
		Parameters = ProcessingParametersBeforeStartSystem();
		InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
			"ActionsBeforeStartInIntegrationProcedureModules");
		
		If Not ContinueActionsBeforeStart(Parameters) Then
			Return;
		EndIf;
		
		If Parameters.CurrentModuleIndex >= Parameters.AddedModules.Count() Then
			ActionsBeforeStartInOverridableProcedure(Undefined, Undefined);
			Return;
		EndIf;
	
		ModuleDetails = Parameters.AddedModules[Parameters.CurrentModuleIndex];
		Parameters.CurrentModuleIndex = Parameters.CurrentModuleIndex + 1;
		
		Try
			If TypeOf(ModuleDetails) <> Type("Structure") Then
				CurrentModule = ModuleDetails;
				CurrentModule.BeforeStart(Parameters);
				InstallLatestProcedure(Parameters, CurrentModule, "BeforeStart");
			Else
				CurrentModule = ModuleDetails.Module;
				If ModuleDetails.Number = 2 Then
					CurrentModule.BeforeStart2(Parameters);
					InstallLatestProcedure(Parameters, CurrentModule, "BeforeStart2");
				ElsIf ModuleDetails.Number = 3 Then
					CurrentModule.BeforeStart3(Parameters);
					InstallLatestProcedure(Parameters, CurrentModule, "BeforeStart3");
				ElsIf ModuleDetails.Number = 4 Then
					CurrentModule.BeforeStart4(Parameters);
					InstallLatestProcedure(Parameters, CurrentModule, "BeforeStart4");
				ElsIf ModuleDetails.Number = 5 Then
					CurrentModule.BeforeStart5(Parameters);
					InstallLatestProcedure(Parameters, CurrentModule, "BeforeStart5");
				EndIf;
			EndIf;
		Except
			HandleErrorBeforeStart(Parameters, ErrorInfo(), True);
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartInOverridableProcedure(Var_Undefined, Context)
	
	Parameters = ProcessingParametersBeforeStartSystem();
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
		"ActionsBeforeStartInOverridableProcedure");
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New CallbackDescription(
		"ActionsBeforeStartInOverridableProcedureModules", ThisObject));
	
	Parameters.InteractiveHandler = Undefined;
	
	Parameters.Insert("CurrentModuleIndex", 0);
	Parameters.Insert("AddedModules", New Array);
	
	If CommonClient.SeparatedDataUsageAvailable() Then
		Try
			Parameters.Insert("Modules", New Array);
			CommonClientOverridable.BeforeStart(Parameters);
			InstallLatestProcedure(Parameters, "CommonClientOverridable",
				"BeforeStart");
			Parameters.Insert("AddedModules", Parameters.Modules);
			Parameters.Delete("Modules");
		Except
			HandleErrorBeforeStart(Parameters, ErrorInfo());
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartInOverridableProcedureModules(Var_Undefined, Context) Export
	
	While True Do
		
		Parameters = ProcessingParametersBeforeStartSystem();
		InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
			"ActionsBeforeStartInOverridableProcedureModules");
		
		If Not ContinueActionsBeforeStart(Parameters) Then
			Return;
		EndIf;
		
		If Parameters.CurrentModuleIndex >= Parameters.AddedModules.Count() Then
			ActionsBeforeStartAfterAllProcedures(Undefined, Undefined);
			Return;
		EndIf;
		
		CurrentModule = Parameters.AddedModules[Parameters.CurrentModuleIndex];
		Parameters.CurrentModuleIndex = Parameters.CurrentModuleIndex + 1;
		
		Try
			CurrentModule.BeforeStart(Parameters);
			InstallLatestProcedure(Parameters, CurrentModule, "BeforeStart");
		Except
			HandleErrorBeforeStart(Parameters, ErrorInfo());
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartAfterAllProcedures(Var_Undefined, Context)
	
	Parameters = ProcessingParametersBeforeStartSystem();
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
		"ActionsBeforeStartAfterAllProcedures");
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionProcessing);
	
	Try
		SetInterfaceFunctionalOptionParametersOnStart();
		InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
			"SetInterfaceFunctionalOptionParametersOnStart");
	Except
		HandleErrorBeforeStart(Parameters, ErrorInfo(), True);
	EndTry;
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. The BeforeStart procedure completion.
Procedure ActionsBeforeStartCompletionHandler(Var_Undefined, Context) Export
	
	Parameters = ProcessingParametersBeforeStartSystem(True);
	
	Parameters.ContinuationHandler = Undefined;
	Parameters.CompletionProcessing  = Undefined;
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	ApplicationStartParameters.Delete("RetrievedClientParameters");
	ApplicationParameters["StandardSubsystems.ApplicationStartCompleted"] = True;
	
	If Parameters.CompletionNotification <> Undefined Then
		Result = New Structure;
		Result.Insert("Cancel", Parameters.Cancel);
		Result.Insert("Restart", Parameters.Restart);
		Result.Insert("AdditionalParametersOfCommandLine", Parameters.AdditionalParametersOfCommandLine);
		RunCallback(Parameters.CompletionNotification, Result);
		Return;
	EndIf;
	
	If Parameters.Cancel Then
		If Parameters.Restart <> True Then
			Terminate();
		ElsIf ValueIsFilled(Parameters.AdditionalParametersOfCommandLine) Then
			Terminate(Parameters.Restart, Parameters.AdditionalParametersOfCommandLine);
		Else
			Terminate(Parameters.Restart);
		EndIf;
		
	ElsIf Not Parameters.ContinuousExecution Then
		If ApplicationStartParameters.Property("ProcessingParameters") Then
			ApplicationStartParameters.Delete("ProcessingParameters");
		EndIf;
		AttachIdleHandler("OnStartIdleHandler", 0.1, True);
	EndIf;
	
EndProcedure

// For internal use only.
Function ProcessingParametersBeforeStartSystem(Delete = False)
	
	ParameterName = "StandardSubsystems.ApplicationStartParameters";
	Properties = ApplicationParameters[ParameterName];
	If Properties = Undefined Then
		Properties = New Structure;
		ApplicationParameters.Insert(ParameterName, Properties);
	EndIf;
	
	PropertyName = "ProcessingParametersBeforeStartSystem";
	If Properties.Property(PropertyName) Then
		Parameters = Properties[PropertyName];
	Else
		Parameters = New Structure;
		Properties.Insert(PropertyName, Parameters);
	EndIf;
	
	If Delete Then
		Properties.Delete(PropertyName);
	EndIf;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region OnStart

// Continues the OnStart procedure.
Procedure ActionsOnStart(CompletionNotification, ContinuousExecution)
	
	Parameters = ProcessingParametersOnStartSystem();
	
	// External parameters of the result description.
	Parameters.Insert("Cancel", False);
	Parameters.Insert("Restart", False);
	Parameters.Insert("AdditionalParametersOfCommandLine", "");
	
	// External parameters of the execution management.
	Parameters.Insert("InteractiveHandler", Undefined); // CallbackDescription
	Parameters.Insert("ContinuationHandler",   Undefined); // CallbackDescription
	Parameters.Insert("ContinuousExecution", ContinuousExecution);
	
	// Internal parameters.
	Parameters.Insert("CompletionNotification", CompletionNotification);
	Parameters.Insert("CompletionProcessing", New CallbackDescription(
		"ActionsOnStartCompletionHandler", ThisObject));
	
	// Preparing to proceed to the next procedure
	Parameters.Insert("ContinuationHandler", New CallbackDescription(
		"ActionsOnStartInIntegrationProcedure", ThisObject));
	
	If Not ApplicationStartCompleted() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra tình huống bất thường khi khởi động ứng dụng.
			           |
			           |Thông tin kỹ thuật:
			           |Lần gọi không hợp lệ %1 khi khởi động ứng dụng. Ban đầu, cần hoàn thành thủ tục %2.
			           |Có thể là một trong các hàm sự kiện không gọi ra thông báo để tiếp tục.
			           |Thủ tục được gọi ra (theo trình tự ngược lại):
			           |%3';
			           |ru = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация:
			           |Недопустимый вызов %1 при запуске приложения. Сначала должна быть завершена процедура %2.
			           |Предположительно, один из обработчиков события не вызвал оповещение для продолжения.
			           |Вызванные процедуры (в обратном порядке):
			           |%3';
			           |en = 'An exception occurred during startup.
			           |
			           |Details:
			           |Invalid %1 call during startup. The procedure %2 must be completed first.
			           |Presumably, one of the event handlers did not trigger the notification to continue.
			           |The invoked procedures (most recent first):
			           |%3'; fa = 'An exception occurred during startup.
			           |
			           |Details:
			           |Invalid %1 call during startup. The procedure %2 must be completed first.
			           |Presumably, one of the event handlers did not trigger the notification to continue.
			           |The invoked procedures (most recent first):
			           |%3';
			           |it = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация:
			           |Недопустимый вызов %1 при запуске приложения. Сначала должна быть завершена процедура %2.
			           |Предположительно, один из обработчиков события не вызвал оповещение для продолжения.
			           |Вызванные процедуры (в обратном порядке):
			           |%3';
			           |pl = 'An exception occurred during startup.
			           |
			           |Details:
			           |Invalid %1 call during startup. The procedure %2 must be completed first.
			           |Presumably, one of the event handlers did not trigger the notification to continue.
			           |The invoked procedures (most recent first):
			           |%3';
			           |tr = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация:
			           |Недопустимый вызов %1 при запуске приложения. Сначала должна быть завершена процедура %2.
			           |Предположительно, один из обработчиков события не вызвал оповещение для продолжения.
			           |Вызванные процедуры (в обратном порядке):
			           |%3'"),
			"StandardSubsystemsClient.OnStart",
			"StandardSubsystemsClient.BeforeStart",
			CalledProceduresBeforeStart());
		Try
			Raise ErrorText;
		Except
			HandleErrorOnStart(Parameters, ErrorInfo(), True);
		EndTry;
		If OnStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	Try
		SetAdvancedApplicationCaption(True); // For the main window.
		
		If Not ProcessStartParameters() Then
			Parameters.Cancel = True;
			RunCallback(Parameters.CompletionProcessing);
			Return;
		EndIf;
	Except
		HandleErrorOnStart(Parameters, ErrorInfo(), True);
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continues the execution of OnStart procedure.
Procedure ActionsOnStartInIntegrationProcedure(Var_Undefined, Context) Export
	
	Parameters = ProcessingParametersOnStartSystem();
	
	If Not ContinueActionsOnStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New CallbackDescription(
		"ActionsOnStartInIntegrationProcedureModules", ThisObject));
	
	Parameters.Insert("CurrentModuleIndex", 0);
	Parameters.Insert("AddedModules", New Array);
	Try
		Parameters.Insert("Modules", New Array);
		SSLSubsystemsIntegrationClient.OnStart(Parameters);
		Parameters.Insert("AddedModules", Parameters.Modules);
		Parameters.Delete("Modules");
	Except
		HandleErrorOnStart(Parameters, ErrorInfo());
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continues the execution of OnStart procedure.
Procedure ActionsOnStartInIntegrationProcedureModules(Var_Undefined, Context) Export
	
	While True Do
		Parameters = ProcessingParametersOnStartSystem();
		
		If Not ContinueActionsOnStart(Parameters) Then
			Return;
		EndIf;
		
		If Parameters.CurrentModuleIndex >= Parameters.AddedModules.Count() Then
			ActionsOnStartInOverridableProcedure(Undefined, Undefined);
			Return;
		EndIf;
		
		ModuleDetails = Parameters.AddedModules[Parameters.CurrentModuleIndex];
		Parameters.CurrentModuleIndex = Parameters.CurrentModuleIndex + 1;
		
		Try
			If TypeOf(ModuleDetails) <> Type("Structure") Then
				CurrentModule = ModuleDetails;
				CurrentModule.OnStart(Parameters);
			Else
				CurrentModule = ModuleDetails.Module;
				If ModuleDetails.Number = 2 Then
					CurrentModule.OnStart2(Parameters);
				ElsIf ModuleDetails.Number = 3 Then
					CurrentModule.OnStart3(Parameters);
				ElsIf ModuleDetails.Number = 4 Then
					CurrentModule.OnStart4(Parameters);
				EndIf;
			EndIf;
		Except
			HandleErrorOnStart(Parameters, ErrorInfo());
		EndTry;
		If OnStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only. Continues the execution of OnStart procedure.
Procedure ActionsOnStartInOverridableProcedure(Var_Undefined, Context)
	
	Parameters = ProcessingParametersOnStartSystem();
	
	If Not ContinueActionsOnStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New CallbackDescription(
		"ActionsOnStartInOverridableProcedureModules", ThisObject));
	
	Parameters.Insert("CurrentModuleIndex", 0);
	Parameters.Insert("AddedModules", New Array);
	Try
		Parameters.Insert("Modules", New Array);
		CommonClientOverridable.OnStart(Parameters);
		Parameters.Insert("AddedModules", Parameters.Modules);
		Parameters.Delete("Modules");
	Except
		HandleErrorOnStart(Parameters, ErrorInfo());
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continues the execution of OnStart procedure.
Procedure ActionsOnStartInOverridableProcedureModules(Var_Undefined, Context) Export
	
	While True Do
		
		Parameters = ProcessingParametersOnStartSystem();
		
		If Not ContinueActionsOnStart(Parameters) Then
			Return;
		EndIf;
		
		If Parameters.CurrentModuleIndex >= Parameters.AddedModules.Count() Then
			ActionsOnStartAfterAllProcedures(Undefined, Undefined);
			Return;
		EndIf;
		
		CurrentModule = Parameters.AddedModules[Parameters.CurrentModuleIndex];
		Parameters.CurrentModuleIndex = Parameters.CurrentModuleIndex + 1;
		
		Try
			CurrentModule.OnStart(Parameters);
		Except
			HandleErrorOnStart(Parameters, ErrorInfo());
		EndTry;
		If OnStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only. Continues the execution of OnStart procedure.
Procedure ActionsOnStartAfterAllProcedures(Var_Undefined, Context)
	
	Parameters = ProcessingParametersOnStartSystem();
	
	If Not ContinueActionsOnStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New CallbackDescription(
		"ActionsOnStartBeforeCompletion", ThisObject));
	
	Try
		SSLSubsystemsIntegrationClient.AfterStart();
		CommonClientOverridable.AfterStart();
	Except
		HandleErrorOnStart(Parameters, ErrorInfo());
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continues the execution of OnStart procedure.
Procedure ActionsOnStartBeforeCompletion(Var_Undefined, Context) Export
	
	Parameters = ProcessingParametersOnStartSystem();
	
	If Not ContinueActionsOnStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionProcessing);
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	ApplicationStartParameters.Insert("ProcedureOnStartCompleted");
	Try
		If DisplayWarningsBeforeShuttingDownTheSystem(False) Then
			// Pre-compilate the client modules to avoid implicit server calls
			// in the "BeforeExit" handler.
			WarningsBeforeSystemShutdown(False); 
		EndIf;
	Except
		HandleErrorOnStart(Parameters, ErrorInfo());
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. The OnStart procedure completion.
Procedure ActionsOnStartCompletionHandler(Var_Undefined, Context) Export
	
	Parameters = ProcessingParametersOnStartSystem(True);
	
	Parameters.ContinuationHandler = Undefined;
	Parameters.CompletionProcessing  = Undefined;
	
	If Not Parameters.Cancel Then
		ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
		If ApplicationStartParameters.Property("SkipClearingDesktopHiding") Then
			ApplicationStartParameters.Delete("SkipClearingDesktopHiding");
		EndIf;
		HideDesktopOnStart(False);
	EndIf;
	
	If Parameters.CompletionNotification <> Undefined Then
		
		Result = New Structure;
		Result.Insert("Cancel", Parameters.Cancel);
		Result.Insert("Restart", Parameters.Restart);
		Result.Insert("AdditionalParametersOfCommandLine", Parameters.AdditionalParametersOfCommandLine);
		RunCallback(Parameters.CompletionNotification, Result);
		Return;
		
	Else
		If Parameters.Cancel Then
			If Parameters.Restart <> True Then
				Terminate();
				
			ElsIf ValueIsFilled(Parameters.AdditionalParametersOfCommandLine) Then
				Terminate(Parameters.Restart, Parameters.AdditionalParametersOfCommandLine);
			Else
				Terminate(Parameters.Restart);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// For internal use only.
Function ProcessingParametersOnStartSystem(Delete = False)
	
	ParameterName = "StandardSubsystems.ApplicationStartParameters";
	Properties = ApplicationParameters[ParameterName];
	If Properties = Undefined Then
		Properties = New Structure;
		ApplicationParameters.Insert(ParameterName, Properties);
	EndIf;
	
	PropertyName = "ProcessingParametersOnStartSystem";
	If Properties.Property(PropertyName) Then
		Parameters = Properties[PropertyName];
	Else
		Parameters = New Structure;
		Properties.Insert(PropertyName, Parameters);
	EndIf;
	
	If Delete Then
		Properties.Delete(PropertyName);
	EndIf;
	
	Return Parameters;
	
EndFunction

// Processes the application start parameters.
//
// Returns:
//   Boolean   - True if the OnStart procedure execution should be aborted.
//
Function ProcessStartParameters()

	If IsBlankString(LaunchParameter) Then
		Return True;
	EndIf;
	
	// The parameter can be separated with the semicolons symbol (;).
	StartupParameters = StrSplit(LaunchParameter, ";", False);
	
	Cancel = False;
	SSLSubsystemsIntegrationClient.LaunchParametersOnProcess(StartupParameters, Cancel);
	CommonClientOverridable.LaunchParametersOnProcess(StartupParameters, Cancel);
	
	Return Not Cancel;
	
EndFunction

#EndRegion

#Region BeforeExit

// For internal use only. 
// 
// Parameters:
//  ReCreate - Boolean
//
// Returns:
//   Structure:
//     Cancel - Boolean
//     Warning - Array of See StandardSubsystemsClient.WarningOnExit.
//     InteractiveHandler - NotifyDescription, Undefined
//     ContinuationHandler - NotifyDescription, Undefined
//     ContinuousExecution - Boolean
//     CompletionProcessing - NotifyDescription
//
Function ParametersOfActionsBeforeShuttingDownTheSystem(ReCreate = False) Export
	
	ParameterName = "StandardSubsystems.ParametersOfActionsBeforeShuttingDownTheSystem";
	If ReCreate Or ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Structure);
	EndIf;
	Parameters = ApplicationParameters[ParameterName];
	
	If Not ReCreate Then
		Return Parameters;
	EndIf;
	
	// External parameters of the result description.
	Parameters.Insert("Cancel", False);
	Parameters.Insert("Warnings", ClientParameter("ExitWarnings"));
	
	// External parameters of the execution management.
	Parameters.Insert("InteractiveHandler", Undefined); // CallbackDescription
	Parameters.Insert("ContinuationHandler",   Undefined); // CallbackDescription
	Parameters.Insert("ContinuousExecution", True);
	
	// Internal parameters.
	Parameters.Insert("CompletionProcessing", New CallbackDescription(
		"ActionsBeforeExitCompletionHandler", StandardSubsystemsClient));
	Return Parameters;
	
EndFunction	
	
// For internal use only. Continues the execution of BeforeExit procedure.
//
// Parameters:
//   Parameters - See StandardSubsystemsClient.ParametersOfActionsBeforeShuttingDownTheSystem
//
Procedure ActionsBeforeExit(Parameters) Export
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionProcessing);
	
	If CommonClient.SeparatedDataUsageAvailable() Then
		Try
			OpenMessageFormOnExit(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "End");
		EndTry;
		If InteractiveHandlerBeforeExit(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. The BeforeExit procedure completion.
//
// Parameters:
//   Var_Undefined - Undefined
//   Parameters - See StandardSubsystemsClient.ParametersOfActionsBeforeShuttingDownTheSystem
//
Procedure ActionsBeforeExitCompletionHandler(Var_Undefined, Parameters) Export
	
	Parameters = ParametersOfActionsBeforeShuttingDownTheSystem();
	Parameters.ContinuationHandler = Undefined;
	Parameters.CompletionProcessing  = Undefined;
	ParameterName = "StandardSubsystems.SkipQuitSystemAfterWarningsHandled";
	
	If Not Parameters.Cancel
	   And Not Parameters.ContinuousExecution
	   And ApplicationParameters.Get(ParameterName) = Undefined Then
		
		SkipExitConfirmation();
		Exit();
	EndIf;
	
EndProcedure

// For internal use only. The BeforeExit procedure completion.
// 
// Parameters:
//  Var_Undefined - Undefined
//  ContinuationHandler - CallbackDescription
//
Procedure ActionsBeforeExitAfterErrorProcessing(Var_Undefined, ContinuationHandler) Export
	
	Parameters = ParametersOfActionsBeforeShuttingDownTheSystem();
	Parameters.ContinuationHandler = ContinuationHandler;
	
	If Parameters.Cancel Then
		Parameters.Cancel = False;
		RunCallback(Parameters.CompletionProcessing);
	Else
		RunCallback(Parameters.ContinuationHandler);
	EndIf;
	
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctionsForStartingAndClosingApp

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart2(Parameters) Export
	
	// Checks the minimum required 1C:Enterprise version.
	// If the current version is earlier than "RecommendedPlatformVersion",
	// the user is shown a warning.
	// If "ClientParameters.MustExit" is set to "True", the session will be terminated.
	
	ClientParameters = ClientParametersOnStart();
	
	If ClientParameters.Property("ShowDeprecatedPlatformVersion") Then
		Parameters.InteractiveHandler = New CallbackDescription(
			"Check1CEnterpriseVersionOnStartup", ThisObject);
	ElsIf ClientParameters.Property("InvalidPlatformVersionUsed") Then
		Parameters.InteractiveHandler = New CallbackDescription(
			"WarnAboutInvalidPlatformVersion", ThisObject);
	EndIf;
	
EndProcedure

// For internal use only. Continuation of the BeforeStart2 procedure.
Procedure Check1CEnterpriseVersionOnStartup(Parameters, Context) Export
	
	ClientParameters = ClientParametersOnStart();
	
	SystemInfo = New SystemInfo;
	Current             = SystemInfo.AppVersion;
	Min         = ClientParameters.MinPlatformVersion;
	If StrFind(LaunchParameter, "UpdateAndExit") > 0
		And CommonClientServer.CompareVersions(Current, Min) < 0
		And CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		MessageText = NStr("vi = 'Không thể cập nhật ứng dụng sang phiên bản mới.
			|Trước tiên, hãy cập nhật phiên bản nền tảng 1C:Enterprise.
			|Phiên bản nền tảng đang sử dụng là %1.
			|Phiên bản nền tảng tối thiểu cần thiết là %2';
			|ru = 'Обновление приложения на новую версию невозможно.
			|Предварительно обновите версию платформы 1С:Предприятие.
			|Используемая версия платформы - %1.
			|Минимально необходимая версия платформы - %2';
			|en = 'Cannot update the application.
			|
			|The current 1C:Enterprise version %1 is not supported.
			|Update 1C:Enterprise to version %2 or later'; fa = 'Cannot update the application.
			|
			|The current 1C:Enterprise version %1 is not supported.
			|Update 1C:Enterprise to version %2 or later';
			|it = 'Обновление приложения на новую версию невозможно.
			|Предварительно обновите версию платформы 1С:Предприятие.
			|Используемая версия платформы - %1.
			|Минимально необходимая версия платформы - %2';
			|pl = 'Cannot update the application.
			|
			|The current 1C:Enterprise version %1 is not supported.
			|Update 1C:Enterprise to version %2 or later';
			|tr = 'Uygulamanın yeni bir sürüme güncellenmesi mümkün değildir.
			|1C:Enterprise platformunun sürümünü önceden güncelleyin.
			|Kullanılan platform sürümü %1''dir.
			|Gerekli minimum platform sürümü:'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Current, Min);
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleConfigurationUpdateClient.WriteDownTheErrorOfTheNeedToUpdateThePlatform(MessageText);
	EndIf;
	
	ClosingNotification1 = New CallbackDescription("AfterClosingDeprecatedPlatformVersionForm", ThisObject, Parameters);
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		StandardProcessing = True;
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.WhenCheckingPlatformVersionAtStartup(ClosingNotification1, StandardProcessing);
		If Not StandardProcessing Then
			Return;
		EndIf;
	EndIf;
	
	If CommonClientServer.CompareVersions(Current, Min) < 0 Then
		If UsersClient.IsFullUser(True) Then
			MessageText =
				NStr("vi = 'Không thể đăng nhập vào ứng dụng.
				           |Trước tiên, hãy cập nhật phiên bản nền tảng 1C:Enterprise.';
				           |ru = 'Вход в приложение невозможен.
				           |Предварительно обновите версию платформы 1С:Предприятие.';
				           |en = 'Cannot start the application.
				           |1C:Enterprise platform update is required.'; fa = 'Cannot start the application.
				           |1C:Enterprise platform update is required.';
				           |it = 'Вход в приложение невозможен.
				           |Предварительно обновите версию платформы 1С:Предприятие.';
				           |pl = 'Cannot start the application.
				           |1C:Enterprise platform update is required.';
				           |tr = 'Uygulamaya giriş yapılamıyor.
				           |Önce 1C:Enterprise platform sürümünü güncelleyin.'");
		Else
			MessageText =
				NStr("vi = 'Không thể đăng nhập vào ứng dụng.
				           |Hãy liên hệ với người quản trị để cập nhật phiên bản nền tảng 1C:Enterprise.';
				           |ru = 'Вход в приложение невозможен.
				           |Обратитесь к администратору для обновления версии платформы 1С:Предприятие.';
				           |en = 'Cannot start the application.
				           |1C:Enterprise platform update is required. Contact the administrator.'; fa = 'Cannot start the application.
				           |1C:Enterprise platform update is required. Contact the administrator.';
				           |it = 'Вход в приложение невозможен.
				           |Обратитесь к администратору для обновления версии платформы 1С:Предприятие.';
				           |pl = 'Cannot start the application.
				           |1C:Enterprise platform update is required. Contact the administrator.';
				           |tr = 'Uygulamaya giriş yapılamıyor.
				           |1C:Enterprise platform sürümünün güncellenmesi için yöneticiye başvurun'");
		EndIf;
	Else
		If UsersClient.IsFullUser(True) Then
			MessageText =
				NStr("vi = 'Nên kết thúc công việc của ứng dụng và cập nhật phiên bản nền tảng 1C:Enterprise.
				         |Phiên bản mới của nền tảng này đã sửa lỗi mà cho phép ứng dụng hoạt động ổn định hơn.
				         |Bạn cũng có thể tiếp tục làm việc trên phiên bản hiện tại.
				         |Phiên bản yêu cầu tối thiểu của nền tảng là %1.';
				         |ru = 'Рекомендуется завершить работу приложения и обновить версию платформы 1С:Предприятия.
				         |Новая версия платформы содержит исправления ошибок, которые позволят приложению работать более стабильно.
				         |Вы также можете продолжить работу на текущей версии.
				         |Минимально необходимая версия платформы %1.';
				         |en = 'It is recommended that you close the application and update the 1C:Enterprise platform version.
				         |The new 1C:Enterprise platform version includes bug fixes that improve the application stability.
				         |You can also continue using the current version.
				         |The minimum required platform version is %1.'; fa = 'It is recommended that you close the application and update the 1C:Enterprise platform version.
				         |The new 1C:Enterprise platform version includes bug fixes that improve the application stability.
				         |You can also continue using the current version.
				         |The minimum required platform version is %1.';
				         |it = 'Рекомендуется завершить работу приложения и обновить версию платформы 1С:Предприятия.
				         |Новая версия платформы содержит исправления ошибок, которые позволят приложению работать более стабильно.
				         |Вы также можете продолжить работу на текущей версии.
				         |Минимально необходимая версия платформы %1.';
				         |pl = 'It is recommended that you close the application and update the 1C:Enterprise platform version.
				         |The new 1C:Enterprise platform version includes bug fixes that improve the application stability.
				         |You can also continue using the current version.
				         |The minimum required platform version is %1.';
				         |tr = 'Uygulamayı kapatmanız ve 1C:Enterprise platformunun sürümünü güncellemeniz önerilir.
				         |Platformun yeni sürümü, Uygulamanın daha kararlı çalışmasına olanak sağlayacak hata düzeltmeleri içeriyor.
				         |Ayrıca mevcut sürüm üzerinde çalışmaya devam edebilirsiniz.
				         |Minimum gerekli platform sürümü %1.'");
		Else
			MessageText = 
				NStr("vi = 'Nên kết thúc làm việc của ứng dụng và liên hệ với người quản trị để cập nhật phiên bản nền tảng 1C:Enterprise.
				         |Phiên bản mới của nền tảng đã sửa lỗi mà cho phép ứng dụng hoạt động ổn định hơn
				         |Bạn cũng có thể tiếp tục làm việc trên phiên bản hiện tại.
				         |Phiên bản nền tảng bắt buộc tối thiểu là %1.';
				         |ru = 'Рекомендуется завершить работу приложения и обратиться к администратору для обновления версии платформы 1С:Предприятия.
				         |Новая версия платформы содержит исправления ошибок, которые позволят приложению работать более стабильно.
				         |Вы также можете продолжить работу на текущей версии.
				         |Минимально необходимая версия платформы %1.';
				         |en = 'It is recommended that you close the application and contact the administrator to update the 1C:Enterprise platform version.
				         |The new platform version includes bug fixes that improve the application stability.
				         |You can also continue using the current version.
				         |The minimum required platform version is %1.'; fa = 'It is recommended that you close the application and contact the administrator to update the 1C:Enterprise platform version.
				         |The new platform version includes bug fixes that improve the application stability.
				         |You can also continue using the current version.
				         |The minimum required platform version is %1.';
				         |it = 'Рекомендуется завершить работу приложения и обратиться к администратору для обновления версии платформы 1С:Предприятия.
				         |Новая версия платформы содержит исправления ошибок, которые позволят приложению работать более стабильно.
				         |Вы также можете продолжить работу на текущей версии.
				         |Минимально необходимая версия платформы %1.';
				         |pl = 'It is recommended that you close the application and contact the administrator to update the 1C:Enterprise platform version.
				         |The new platform version includes bug fixes that improve the application stability.
				         |You can also continue using the current version.
				         |The minimum required platform version is %1.';
				         |tr = '1C:Enterprise platformunun sürümünü güncellemek için uygulamayı kapatmanız ve yöneticiyle iletişime geçmeniz önerilir.
				         |Platformun yeni sürümü, uygulamanın daha kararlı çalışmasını sağlayacak hata düzeltmeleri içeriyor.
				         |Ayrıca mevcut sürüm üzerinde çalışmaya devam edebilirsiniz.
				         |Minimum gerekli platform sürümü %1.'");
		EndIf;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("MessageText", MessageText);
	FormParameters.Insert("RecommendedPlatformVersion", ClientParameters.RecommendedPlatformVersion);
	FormParameters.Insert("MinPlatformVersion", ClientParameters.MinPlatformVersion);
	FormParameters.Insert("OpenByScenario", True);
	FormParameters.Insert("SkipExit", True);
	
	Form = OpenForm("DataProcessor.PlatformUpdateRecommended.Form.PlatformUpdateRecommended", FormParameters,
		, , , , ClosingNotification1);	
	If Form = Undefined Then
		AfterClosingDeprecatedPlatformVersionForm("Continue", Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continues the execution of CheckPlatformVersionOnStart procedure.
Procedure AfterClosingDeprecatedPlatformVersionForm(Result, Parameters) Export
	
	If Result <> "Continue" Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert("ShowDeprecatedPlatformVersion");
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continuation of the BeforeStart2 procedure.
Procedure WarnAboutInvalidPlatformVersion(Parameters, Context) Export

	ClosingNotification1 = New CallbackDescription("AfterCloseInvalidPlatformVersionForm", ThisObject, Parameters);
	
	Form = OpenForm("DataProcessor.PlatformUpdateRecommended.Form.PlatformUpdateIsRequired", ,
		, , , , ClosingNotification1); 
	
	If Form = Undefined Then
		AfterCloseInvalidPlatformVersionForm("Continue", Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continues the execution of CheckPlatformVersionOnStart procedure.
Procedure AfterCloseInvalidPlatformVersionForm(Result, Parameters) Export
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart3(Parameters) Export
	
	// Checks if the connection with the master node is broken.
	// If case it is, the procedure restores it.
	
	ClientParameters = ClientParametersOnStart();
	
	If Not ClientParameters.Property("ReconnectMasterNode") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New CallbackDescription(
		"MasterNodeReconnectionInteractiveHandler", ThisObject);
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart4(Parameters) Export
	
	// Checks if the main language and time zone are set up.
	// If they are not set up, the procedure opens the regional settings form.
	
	ClientParameters = ClientParametersOnStart();
	
	If Not ClientParameters.Property("SelectInitialRegionalIBSettings") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New CallbackDescription(
		"InteractiveInitialRegionalInfobaseSettingsProcessing", ThisObject, Parameters);
	
EndProcedure

// For internal use only. Continues the execution of CheckReconnectToMasterNodeRequired procedure.
Procedure MasterNodeReconnectionInteractiveHandler(Parameters, Context) Export
	
	ClientParameters = ClientParametersOnStart();
	
	If ClientParameters.ReconnectMasterNode = False Then
		Parameters.Cancel = True;
		ShowMessageBox(
			NotificationWithoutResult(Parameters.ContinuationHandler),
			NStr("vi = 'Tạm thời, không thể đăng nhập vào ứng dụng cho đến khi khôi phục kết nối với nút chính.
			           |Hãy liên hệ với người quản trị để biết thêm chi tiết.';
			           |ru = 'Вход в приложение временно невозможен до восстановления связи с главным узлом.
			           |Обратитесь к администратору за подробностями.';
			           |en = 'Cannot log in because the connection to the master node is lost.
			           |Please contact the administrator.'; fa = 'Cannot log in because the connection to the master node is lost.
			           |Please contact the administrator.';
			           |it = 'Вход в приложение временно невозможен до восстановления связи с главным узлом.
			           |Обратитесь к администратору за подробностями.';
			           |pl = 'Cannot log in because the connection to the master node is lost.
			           |Please contact the administrator.';
			           |tr = 'Uygulamaya giriş, ana ünite ile bağlantının geri yüklenmesinden önce geçici olarak kullanılamıyor. 
			           |Ayrıntılar için yöneticiyle iletişime geçin.'"),
			15);
		Return;
	EndIf;
	
	Form = OpenForm("CommonForm.ReconnectToMasterNode",,,,,,
		New CallbackDescription("ReconnectToMasterNodeAfterCloseForm", ThisObject, Parameters));
	
	If Form = Undefined Then
		ReconnectToMasterNodeAfterCloseForm(New Structure("Cancel", True), Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continuation of the BeforeStart4 procedure.
Procedure InteractiveInitialRegionalInfobaseSettingsProcessing(Parameters, Context) Export
	
	ClientParameters = ClientParametersOnStart();
	
	If ClientParameters.SelectInitialRegionalIBSettings = False Then
		Parameters.Cancel = True;
		ShowMessageBox(
			NotificationWithoutResult(Parameters.ContinuationHandler),
			NStr("vi = 'Không thể đăng nhập vào ứng dụng cho đến khi thiết lập tùy chỉnh địa phương ban đầu.
			           |Hãy liên hệ với người quản trị để biết thêm chi tiết.';
			           |ru = 'Вход в приложение невозможен до установки начальных региональных настроек.
			           |Обратитесь к администратору за подробностями.';
			           |en = 'Cannot start the application. Regional settings need to be configured.
			           |Contact the administrator.'; fa = 'Cannot start the application. Regional settings need to be configured.
			           |Contact the administrator.';
			           |it = 'Вход в приложение невозможен до установки начальных региональных настроек.
			           |Обратитесь к администратору за подробностями.';
			           |pl = 'Cannot start the application. Regional settings need to be configured.
			           |Contact the administrator.';
			           |tr = 'Uygulamanın ilk bölgesel ayarları yapılmadan programa girmek mümkün değildir.
			           |Ayrıntılar için yöneticinize başvurun.'"),
			15);
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClient = CommonClient.CommonModule("NationalLanguageSupportClient");
		
		CallbackDescription = New CallbackDescription("AfterCloseInitialRegionalInfobaseSettingsChoiceForm", ThisObject, Parameters);
		OpeningParameters  = New Structure("Source", "InitialFilling");
		ModuleNationalLanguageSupportClient.OpenTheRegionalSettingsForm(CallbackDescription, OpeningParameters);
		
	Else
		AfterCloseInitialRegionalInfobaseSettingsChoiceForm(New Structure("Cancel", True), Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continues the execution of CheckReconnectToMasterNodeRequired procedure.
Procedure ReconnectToMasterNodeAfterCloseForm(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Or Result.Cancel Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert("ReconnectMasterNode");
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continuation of the BeforeStart4 procedure.
Procedure AfterCloseInitialRegionalInfobaseSettingsChoiceForm(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Or Result.Cancel Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert("SelectInitialRegionalIBSettings");
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// Hides the desktop when the application starts using flag
// that prevents form creation on the desktop.
// Makes the desktop visible and updates it when possible
// if the desktop is hidden.
//
// Parameters:
//  Hide - Boolean - pass False to make desktop
//           visible if it is hidden.
//
//  AlreadyDoneAtServer - Boolean - pass True if the method was already executed
//           in the StandardSubsystemsServerCall module and it should not be
//           executed again here but only set the flag showing that desktop
//           is hidden and it will be shown lately.
//
Procedure HideDesktopOnStart(Hide = True, AlreadyDoneAtServer = False) Export
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	If Hide Then
		If Not ApplicationStartParameters.Property("HideDesktopOnStart") Then
			ApplicationStartParameters.Insert("HideDesktopOnStart");
			If Not AlreadyDoneAtServer Then
				StandardSubsystemsServerCall.HideDesktopOnStart();
			EndIf;
			RefreshInterface();
		EndIf;
	Else
		If ApplicationStartParameters.Property("HideDesktopOnStart") Then
			ApplicationStartParameters.Delete("HideDesktopOnStart");
			If Not AlreadyDoneAtServer Then
				StandardSubsystemsServerCall.HideDesktopOnStart(False);
			EndIf;
			CommonClient.RefreshApplicationInterface();
		EndIf;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure NotifyWithEmptyResult(NotificationWithResult) Export
	
	RunCallback(NotificationWithResult);
	
EndProcedure

// For internal use only.
Procedure StartInteractiveHandlerBeforeExit() Export
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	If Not ApplicationStartParameters.Property("ExitProcessingParameters") Then
		Return;
	EndIf;
	
	Parameters = ApplicationStartParameters.ExitProcessingParameters;
	ApplicationStartParameters.Delete("ExitProcessingParameters");
	
	InteractiveHandler = Parameters.InteractiveHandler;
	Parameters.InteractiveHandler = Undefined;
	RunCallback(InteractiveHandler, Parameters);
	
EndProcedure

// For internal use only.
//
// Parameters:
//  Result - DialogReturnCode 
//            - Undefined
//  AdditionalParameters - Structure
//
Procedure AfterClosingWarningFormOnExit(Result, AdditionalParameters) Export
	
	Parameters = ParametersOfActionsBeforeShuttingDownTheSystem();
	
	If AdditionalParameters.FormOption = "DoQueryBox" Then
		
		If Result = Undefined Or Result.Value <> DialogReturnCode.Yes Then
			Parameters.Cancel = True;
		EndIf;
		
	ElsIf AdditionalParameters.FormOption = "StandardForm" Then
	
		If Result = True Or Result = Undefined Then
			Parameters.Cancel = True;
		EndIf;
		
	Else // AppliedForm
		If Result = True Or Result = Undefined Or Result = DialogReturnCode.No Then
			Parameters.Cancel = True;
		EndIf;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	If MustShowRAMSizeRecommendations() Then
		AttachIdleHandler("ShowRAMRecommendation", 10, True);
	EndIf;
	
EndProcedure

Function DisplayWarningsBeforeShuttingDownTheSystem(Cancel)
	
	If ApplicationStartupLogicDisabled() Then
		Return False;
	EndIf;
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	If ApplicationStartParameters.Property("HideDesktopOnStart") Then
		// An exit attempt had been made before the startup was completed.
		// For the web client, it can be a standard behavior if the user closes the browser tab.
		// Therefore, the closure is blocked since it can be force-closed if needed.
		// And in case the user closes the tab by accident, they should be able to stay on that tab.
		// For other clients, it can be caused by errors in the modeless startup sequence.
		// That is, there are no windows that overlap the entire UI.
		// In this case, the closure should be allowed without the standard exit procedures
		// as they may cause errors since the startup process is not completed.
#If Not WebClient Then
		Cancel = True;
#EndIf
		If Not ApplicationStartParameters.Property("ProcedureOnStartCompleted") Then
			Return False;
		EndIf;
	EndIf;
	
	// In thick client (ordinary application) mode, the warning list is not displayed.
#If ThickClientOrdinaryApplication Then
	Return False;
#EndIf
	
	If ApplicationParameters["StandardSubsystems.SkipExitConfirmation"] = True Then
		Return False;
	EndIf;
	
	If Not CommonClient.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction
	
Function WarningsBeforeSystemShutdown(Cancel)
	
	Warnings = New Array;
	SSLSubsystemsIntegrationClient.BeforeExit(Cancel, Warnings);
	CommonClientOverridable.BeforeExit(Cancel, Warnings);
	Return Warnings;

EndFunction

#EndRegion

#Region ForMetadataObjectIDsCatalog

// For internal use only.
Procedure MetadataObjectIDsListFormListValueChoice(Form, Item, Value, StandardProcessing) Export
	
	If Not Form.SelectMetadataObjectsGroups
	   And Item.CurrentData <> Undefined
	   And Not Item.CurrentData.DeletionMark
	   And Not ValueIsFilled(Item.CurrentData.Parent) Then
		
		StandardProcessing = False;
		
		If Item.Representation = TableRepresentation.Tree Then
			If Item.Expanded(Item.CurrentRow) Then
				Item.GroupBy(Item.CurrentRow);
			Else
				Item.Expand(Item.CurrentRow);
			EndIf;
			
		ElsIf Item.Representation = TableRepresentation.HierarchicalList Then
			
			If Item.CurrentParent <> Item.CurrentRow Then
				Item.CurrentParent = Item.CurrentRow;
			Else
				CurrentRow = Item.CurrentRow;
				Item.CurrentParent = Undefined;
				Item.CurrentRow = CurrentRow;
			EndIf;
		Else
			ShowMessageBox(,
				NStr("vi = 'Không thể chọn nhóm đối tượng metadata.
				           |Hãy chọn đối tượng metadata.';
				           |ru = 'Невозможно выбрать группу объектов метаданных.
				           |Выберите объект метаданных.';
				           |en = 'Cannot select a group of metadata objects.
				           |Please select a metadata object.'; fa = 'Cannot select a group of metadata objects.
				           |Please select a metadata object.';
				           |it = 'Impossibile selezionare un gruppo di oggetti di metadati.
				           |Selezionate un oggetto di metadati.';
				           |pl = 'Nie można wybrać grupę obiektów metadanych.
				           |Wybierz obiekt metadanych.';
				           |tr = 'Bir meta veri nesnesi grubu seçilemez. 
				           |Meta veri nesnesini seçin.'"));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region TheParametersOfTheClientToTheServer

Procedure FillInTheClientParametersOnTheServer(Parameters) Export
	
	Parameters.Insert("LaunchParameter", LaunchParameter);
	Parameters.Insert("InfoBaseConnectionString", InfoBaseConnectionString());
	Parameters.Insert("IsWebClient", IsWebClient());
	Parameters.Insert("IsLinuxClient", CommonClient.IsLinuxClient());
	Parameters.Insert("IsMacOSClient", CommonClient.IsMacOSClient());
	Parameters.Insert("IsWindowsClient", CommonClient.IsWindowsClient());
	Parameters.Insert("IsMobileClient", IsMobileClient());
	Parameters.Insert("ClientUsed", ClientUsed());
	Parameters.Insert("BinDir", CurrentAppllicationDirectory());
	Parameters.Insert("ClientID", ClientID());
	Parameters.Insert("HideDesktopOnStart", False);
	Parameters.Insert("RAM", CommonClient.RAMAvailableForClientApplication());
	Parameters.Insert("MainDisplayResolotion", MainDisplayResolotion());
	Parameters.Insert("SystemInfo", ClientSystemInfo());
	
	// Set the client date right before the call to reduce error.
	Parameters.Insert("CurrentDateOnClient", CurrentDate()); // ACC:143-off To calculate SessionTimeOffset, CurrentDate is required.
	Parameters.Insert("CurrentUniversalDateInMillisecondsOnClient", CurrentUniversalDateInMilliseconds());
	
EndProcedure

// Returns:
//   See Common.ClientUsed
//
Function ClientUsed()
	
	ClientUsed = "";
#If ThinClient Then
		ClientUsed = "ThinClient";
#ElsIf ThickClientManagedApplication Then
		ClientUsed = "ThickClientManagedApplication";
#ElsIf ThickClientOrdinaryApplication Then
		ClientUsed = "ThickClientOrdinaryApplication";
#ElsIf WebClient Then
		BrowserDetails = CurrentBrowser();
		If IsBlankString(BrowserDetails.Version) Then
			ClientUsed = StringFunctionsClientServer.SubstituteParametersToString("WebClient.%1", BrowserDetails.Name1);
		Else
			ClientUsed = StringFunctionsClientServer.SubstituteParametersToString("WebClient.%1.%2", BrowserDetails.Name1, StrSplit(BrowserDetails.Version, ".")[0]);
		EndIf;
#EndIf
	
	Return ClientUsed;
	
EndFunction

Function CurrentBrowser()
	
	Result = New Structure("Name1,Version", "Other", "");
	
	SystemInfo = New SystemInfo;
	String = SystemInfo.UserAgentInformation;
	String = StrReplace(String, ",", ";");

	// Opera
	Id = "Opera";
	Position = StrFind(String, Id, SearchDirection.FromEnd);
	If Position > 0 Then
		String = Mid(String, Position + StrLen(Id));
		Result.Name1 = "Opera";
		Id = "Version/";
		Position = StrFind(String, Id);
		If Position > 0 Then
			String = Mid(String, Position + StrLen(Id));
			Result.Version = TrimAll(String);
		Else
			String = TrimAll(String);
			If StrStartsWith(String, "/") Then
				String = Mid(String, 2);
			EndIf;
			Result.Version = TrimL(String);
		EndIf;
		Return Result;
	EndIf;

	// IE
	Id = "MSIE"; // v11-
	Position = StrFind(String, Id);
	If Position > 0 Then
		Result.Name1 = "IE";
		String = Mid(String, Position + StrLen(Id));
		Position = StrFind(String, ";");
		If Position > 0 Then
			String = TrimL(Left(String, Position - 1));
			Result.Version = String;
		EndIf;
		Return Result;
	EndIf;

	Id = "Trident"; // v11+
	Position = StrFind(String, Id);
	If Position > 0 Then
		Result.Name1 = "IE";
		String = Mid(String, Position + StrLen(Id));
		
		Id = "rv:";
		Position = StrFind(String, Id);
		If Position > 0 Then
			String = Mid(String, Position + StrLen(Id));
			Position = StrFind(String, ")");
			If Position > 0 Then
				String = TrimL(Left(String, Position - 1));
				Result.Version = String;
			EndIf;
		EndIf;
		Return Result;
	EndIf;

	// Chrome
	Id = "Chrome/";
	Position = StrFind(String, Id);
	If Position > 0 Then
		Result.Name1 = "Chrome";
		String = Mid(String, Position + StrLen(Id));
		Position = StrFind(String, " ");
		If Position > 0 Then
			String = TrimL(Left(String, Position - 1));
			Result.Version = String;
		EndIf;
		Return Result;
	EndIf;

	// Safari
	Id = "Safari/";
	If StrFind(String, Id) > 0 Then
		Result.Name1 = "Safari";
		Id = "Version/";
		Position = StrFind(String, Id);
		If Position > 0 Then
			String = Mid(String, Position + StrLen(Id));
			Position = StrFind(String, " ");
			If Position > 0 Then
				Result.Version = TrimAll(Left(String, Position - 1));
			EndIf;
		EndIf;
		Return Result;
	EndIf;

	// Firefox
	Id = "Firefox/";
	Position = StrFind(String, Id);
	If Position > 0 Then
		Result.Name1 = "Firefox";
		String = Mid(String, Position + StrLen(Id));
		If Not IsBlankString(String) Then
			Result.Version = TrimAll(String);
		EndIf;
		Return Result;
	EndIf;
	
	Return Result;
	
EndFunction

Function CurrentAppllicationDirectory()
	
#If WebClient Or MobileClient Then
	BinDir = "";
#Else
	BinDir = BinDir();
#EndIf
	
	Return BinDir;
	
EndFunction

Function MainDisplayResolotion()
	
	ClientDisplaysInformation = GetClientDisplaysInformation();
	If ClientDisplaysInformation.Count() > 0 Then
		DPI = ClientDisplaysInformation[0].DPI; // ACC:1353 - Don't translate to Russian.
		MainDisplayResolotion = ?(DPI = 0, 72, DPI);
	Else
		MainDisplayResolotion = 72;
	EndIf;
	
	Return MainDisplayResolotion;
	
EndFunction

Function ClientID()
	
	SystemInfo = New SystemInfo;
	Return SystemInfo.ClientID;
	
EndFunction

Function IsWebClient()
	
#If WebClient Then
	Return True;
#Else
	Return False;
#EndIf
	
EndFunction

Function IsMobileClient()
	
#If MobileClient Then
	Return True;
#Else
	Return False;
#EndIf
	
EndFunction

// Returns:
//   See Common.ClientSystemInfo
//
Function ClientSystemInfo()
	
	Result = New Structure(
		"OSVersion,
		|AppVersion,
		|ClientID,
		|UserAgentInformation,
		|RAM,
		|Processor,
		|PlatformType");
	
	SystemInfo = New SystemInfo;
	FillPropertyValues(Result, SystemInfo);
	Result.PlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion

// Continues the StartNotificationProcessing procedure.
//
// Parameters:
//  Size - Number
//  Context - Structure:
//   * Notification - CallbackDescription
//   * Result  - Arbitrary
//
Procedure StartNotificationProcessingCompletion(Size, Context) Export
	
	RunCallback(Context.Notification, Context.Result);
	
EndProcedure

#Region AuxiliaryProceduresAndFunctions

Procedure SignInToDataArea()
	
	If IsBlankString(LaunchParameter) Then
		Return;
	EndIf;
	
	StartupParameters = StrSplit(LaunchParameter, ";", False);
	
	If StartupParameters.Count() = 0 Then
		Return;
	EndIf;
	
	StartParameterValue = Upper(StartupParameters[0]);
	
	If StartParameterValue <> Upper("SignInToDataArea") Then
		Return;
	EndIf;
	
	If StartupParameters.Count() < 2 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong tham số khởi động %1 hãy chỉ ra thêm giá trị đường chia tách (số).';
				|ru = 'В параметре запуска %1 дополнительно укажите значение разделителя (число).';
				|en = 'Specify a separator value (a number) in startup parameter %1.'; fa = 'Specify a separator value (a number) in startup parameter %1.';
				|it = 'Nela parametro di avvio %1 indicare in modo aggiuntivo il valore del divisore (numero).';
				|pl = 'W parametrze uruchomienia %1 dodatkowo podaj wartość separatora (liczba).';
				|tr = 'Başlatma parametresinde %1 isteğe bağlı olarak bir sınırlayıcı değeri (sayı) belirtin.'"),
			"SignInToDataArea");
	EndIf;
	
	Try
		SeparatorValue = Number(StartupParameters[1]);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giá trị đường chia tách trong tham số %1 phải là số.';
				|ru = 'Значением разделителя в параметре %1 должно быть число.';
				|en = 'A separator value in parameter %1 must be a number.'; fa = 'A separator value in parameter %1 must be a number.';
				|it = 'Come valore del divisore nel parametro %1 deve esserci un numero.';
				|pl = 'Wartością separatora w opcji %1 powinna być liczba.';
				|tr = '%1 parametresindeki ayırıcı değer bir sayı olmalıdır.'"),
			"SignInToDataArea");
	EndTry;
	
	StandardSubsystemsServerCall.SignInToDataArea(SeparatorValue);
	
EndProcedure

// Updates the client parameters after interactive data processing on application start.
Procedure UpdateClientParameters(Parameters, InitialCall = False, RefreshReusableValues = True)
	
	If InitialCall Then
		ParameterName = "StandardSubsystems.ApplicationStartParameters";
		If ApplicationParameters[ParameterName] = Undefined Then
			ApplicationParameters.Insert(ParameterName, New Structure);
		EndIf;
		ParameterName = "StandardSubsystems.ApplicationStartCompleted";
		If ApplicationParameters[ParameterName] = Undefined Then
			ApplicationParameters.Insert(ParameterName, False);
		EndIf;
	ElsIf Parameters.CountOfReceivedClientParameters = Parameters.RetrievedClientParameters.Count() Then
		Return;
	EndIf;
	
	Parameters.Insert("CountOfReceivedClientParameters", Parameters.RetrievedClientParameters.Count());
	
	ApplicationParameters["StandardSubsystems.ApplicationStartParameters"].Insert(
		"RetrievedClientParameters", Parameters.RetrievedClientParameters);
	
	If RefreshReusableValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Checks the result of the interactive processing. If False, calls the exit handler.
// If a new received client parameter is added, it updates the client operation parameters.
//
// Parameters:
//   Parameters - See CommonClientOverridable.BeforeStart.Parameters.
//
// Returns:
//   Boolean - True if the execution can continue and, accordingly, the notification
//            handler specified in the CompletionProcessing properties has not been executed.
//
Function ContinueActionsBeforeStart(Parameters)
	
	If Parameters.Cancel Then
		RunCallback(Parameters.CompletionProcessing);
		Return False;
	EndIf;
	
	UpdateClientParameters(Parameters);
	
	Return True;
	
EndFunction

// Processes the error found when calling the OnStart event handler.
//
// Parameters:
//   Parameters          - See CommonClientOverridable.OnStart.Parameters.
//   ErrorInfo - ErrorInfo - an error description.
//   Shutdown   - Boolean - If True is set, you will not be able to continue operation in case of startup error.
//
Procedure HandleErrorBeforeStart(Parameters, ErrorInfo, Shutdown = False)
	
	HandleErrorOnStartOrExit(Parameters, ErrorInfo, "Run", Shutdown);
	
EndProcedure

// Checks the result of the BeforeStart event handler and executes the notification handler.
//
// Parameters:
//   Parameters - See CommonClientOverridable.BeforeStart.Parameters.
//
// Returns:
//   Boolean - True if the notification handler, specified
//            CompletionProcessing CompletionProcessing or planned moving to the execution of
//            the interactive processing specified in the InteractiveProcessing property, was executed.
//
Function BeforeStartInteractiveHandler(Parameters)
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel Then
			RunCallback(Parameters.CompletionProcessing);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	UpdateClientParameters(Parameters);
	
	If Not Parameters.ContinuousExecution Then
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		InstallLatestProcedure(Parameters,,, InteractiveHandler);
		RunCallback(InteractiveHandler, Parameters);
		
	Else
		// The UI should be prepared before starting the interactive data processor requested
		// in the "BeforeStart" handler runtime. The preparation hides the desktop and refreshes the IU
		// 
		//  proceeding with the first call to "OnAppStart".
		ApplicationStartParameters.Insert("ProcessingParameters", Parameters);
		HideDesktopOnStart();
		ApplicationStartParameters.Insert("SkipClearingDesktopHiding");
		
		If Parameters.CompletionNotification = Undefined Then
			// "BeforeExit" was called by 1C:Enterprise as an event handler
			// before opening the main 1C:Enterprise window.
			If Not ApplicationStartupLogicDisabled() Then
				SetInterfaceFunctionalOptionParametersOnStart();
			EndIf;
		Else
			// "BeforeExit" was called programmatically as access to a data area.
			// Therefore, after refreshing the UI, use an idle handler to resume.
			AttachIdleHandler("OnStartIdleHandler", 0.1, True);
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

Procedure InstallLatestProcedure(Parameters, ModuleName = "", ProcedureName = "", CallbackDescription = Undefined)
	
	ProcedureDetails = New Structure("Module, Name");
	
	If CallbackDescription = Undefined Then
		ProcedureDetails.Module = ModuleName;
		ProcedureDetails.Name = ProcedureName;
	Else
		ProcedureDetails.Module = CallbackDescription.Module;
		ProcedureDetails.Name = CallbackDescription.ProcedureName;
	EndIf;
	
	Parameters.CalledProcedures.Insert(0, ProcedureDetails);
	
EndProcedure

// Intended for procedure "ActionsOnStart".
Function CalledProceduresBeforeStart() Export
	
	Properties = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	If Properties = Undefined
	 Or Not Properties.Property("ProcessingParametersBeforeStartSystem") Then
		Return "";
	EndIf;
	Parameters = Properties.ProcessingParametersBeforeStartSystem;
	NamesOfClientModules = Undefined;
	
	Rows = New Array;
	For Each ProcedureDetails In Parameters.CalledProcedures Do
		If TypeOf(ProcedureDetails.Module) = Type("CommonModule") Then
			If NamesOfClientModules = Undefined Then
				NamesOfClientModules = StandardSubsystemsServerCall.NamesOfClientModules();
			EndIf;
			For Each NameOfClientModule In NamesOfClientModules Do
				Try
					CurrentModule = CommonClient.CommonModule(NameOfClientModule);
				Except
					CurrentModule = Undefined;
				EndTry;
				If CurrentModule = ProcedureDetails.Module Then
					ModuleName = NameOfClientModule;
					Break;
				EndIf;
			EndDo;
		ElsIf TypeOf(ProcedureDetails.Module) = Type("ClientApplicationForm") Then
			ModuleName = ProcedureDetails.Module.FormName;
		Else
			ModuleName = String(ProcedureDetails.Module);
		EndIf;
		Rows.Add("- " + String(ModuleName) + "." + ProcedureDetails.Name);
	EndDo;
	
	Return StrConcat(Rows, Chars.LF);
	
EndFunction

// Checks the result of the interactive processing. If False, calls the exit handler.
//
// Parameters:
//   Parameters - See CommonClientOverridable.OnStart.Parameters.
//
// Returns:
//   Boolean - True if the execution can continue and, accordingly, the notification
//            handler specified in the CompletionProcessing properties has not been executed.
//
Function ContinueActionsOnStart(Parameters)
	
	If Parameters.Cancel Then
		RunCallback(Parameters.CompletionProcessing);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Processes the error found when calling the OnStart event handler.
//
// Parameters:
//   Parameters          - See CommonClientOverridable.OnStart.Parameters.
//   ErrorInfo - ErrorInfo - an error description.
//   Shutdown   - Boolean - If True is set, you will not be able to continue operation in case of startup error.
//
Procedure HandleErrorOnStart(Parameters, ErrorInfo, Shutdown = False)
	
	HandleErrorOnStartOrExit(Parameters, ErrorInfo, "Run", Shutdown);
	
EndProcedure

// Checks the result of the OnStart event handler and executes the notification handler.
//
// Parameters:
//   Parameters - See CommonClientOverridable.OnStart.Parameters.
//
// Returns:
//   Boolean - True if notification handler, specified in
//            the CompletionProcessing or InteractiveHandler properties, was executed.
//
Function OnStartInteractiveHandler(Parameters)
	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel Then
			RunCallback(Parameters.CompletionProcessing);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	InteractiveHandler = Parameters.InteractiveHandler;
	
	Parameters.ContinuousExecution = False;
	Parameters.InteractiveHandler = Undefined;
	
	RunCallback(InteractiveHandler, Parameters);
	
	Return True;
	
EndFunction

Function InteractiveHandlerBeforeStartInProgress()
	
	If ApplicationParameters = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra tình huống bất thường khi khởi động ứng dụng.
			           |
			           |Thông tin kỹ thuật:
			           |Lần gọi không hợp lệ %1 khi khởi động ứng dụng. Ban đầu cần hoàn thành thủ tục %2.';
			           |ru = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация:
			           |Недопустимый вызов %1 при запуске приложения. Сначала должна быть завершена процедура %2.';
			           |en = 'An unexpected error occurred during the application startup.
			           |
			           |Technical details:
			           |Invalid call %1 during the application startup. First, you need to complete the %2 procedure.'; fa = 'An unexpected error occurred during the application startup.
			           |
			           |Technical details:
			           |Invalid call %1 during the application startup. First, you need to complete the %2 procedure.';
			           |it = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация:
			           |Недопустимый вызов %1 при запуске приложения. Сначала должна быть завершена процедура %2.';
			           |pl = 'An unexpected error occurred during the application startup.
			           |
			           |Technical details:
			           |Invalid call %1 during the application startup. First, you need to complete the %2 procedure.';
			           |tr = 'Uygulama başlatılırken beklenmedik bir durum oluştu.
			           |
			           |Teknik bilgi:
			           |Uygulama başlatılırken izin verilmeyen çağrılar %1. Başlangıçta %2 prosedürünün bitmesi zorunludur.'"),
			"StandardSubsystemsClient.OnStart",
			"StandardSubsystemsClient.BeforeStart");
		Raise ErrorText;
	EndIf;	

	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"]; // Structure
	If Not ApplicationStartParameters.Property("ProcessingParameters") Then
		Return False;
	EndIf;
	
	Parameters = ApplicationStartParameters.ProcessingParameters;
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
		"InteractiveHandlerBeforeStartInProgress");
	If Parameters.InteractiveHandler = Undefined Then
		Return False;
	EndIf;
	
	AttachIdleHandler("TheHandlerWaitsToStartInteractiveProcessingBeforeTheSystemStartsWorking", 0.1, True);
	Parameters.ContinuousExecution = False;
	
	Return True;
	
EndFunction

Procedure StartInteractiveProcessingBeforeStartingTheSystem() Export
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"]; // Structure
	
	Parameters = ApplicationStartParameters.ProcessingParameters;
	InteractiveHandler = Parameters.InteractiveHandler;
	Parameters.InteractiveHandler = Undefined;
	InstallLatestProcedure(Parameters,,, InteractiveHandler);
	
	RunCallback(InteractiveHandler, Parameters);
	
	ApplicationStartParameters.Delete("ProcessingParameters");
	
EndProcedure

Function InteractiveHandlerBeforeExit(Parameters)
	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel Then
			RunCallback(Parameters.CompletionProcessing);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	If Not Parameters.ContinuousExecution Then
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		RunCallback(InteractiveHandler, Parameters);
		
	Else
		// The "BeforeExit" event handler made a call to prepare for running
		// the interactive data processor via the idle handler.
		ApplicationParameters["StandardSubsystems.ApplicationStartParameters"].Insert("ExitProcessingParameters", Parameters);
		Parameters.ContinuousExecution = False;
		AttachIdleHandler(
			"BeforeExitInteractiveHandlerIdleHandler", 0.1, True);
	EndIf;
	
	Return True;
	
EndFunction

// Displays a user message form or a message.
Procedure OpenMessageFormOnExit(Parameters)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormOption", "DoQueryBox");
	
	ResponseHandler = New CallbackDescription("AfterClosingWarningFormOnExit",
		ThisObject, AdditionalParameters);
		
	Warnings = Parameters.Warnings;
	Parameters.Delete("Warnings");
	
	FormParameters = New Structure;
	FormParameters.Insert("Warnings", Warnings);
	
	FormName = "CommonForm.ExitWarnings";
	
	If Warnings.Count() = 1 And IsBlankString(Warnings[0].CheckBoxText) Then
		AdditionalParameters.Insert("FormOption", "AppliedForm");
		OpenApplicationWarningForm(Parameters, ResponseHandler, Warnings[0], FormName, FormParameters);
	Else	
		AdditionalParameters.Insert("FormOption", "StandardForm");
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("FormName", FormName);
		FormOpenParameters.Insert("FormParameters", FormParameters);
		FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
		FormOpenParameters.Insert("WindowOpeningMode", Undefined);
		Parameters.InteractiveHandler = New CallbackDescription(
			"WarningInteractiveHandlerOnExit", ThisObject, FormOpenParameters);
	EndIf;
	
EndProcedure

// Continues the execution of OpenOnExitMessageForm procedure.
Procedure WarningInteractiveHandlerOnExit(Parameters, FormOpenParameters) Export
	
	OpenForm(
		FormOpenParameters.FormName,
		FormOpenParameters.FormParameters, , , , ,
		FormOpenParameters.ResponseHandler,
		FormOpenParameters.WindowOpeningMode);
	
EndProcedure

// Continues the execution of ShowMessageBoxAndContinue procedure.
Procedure ShowMessageBoxAndContinueCompletion(Result, Parameters) Export
	
	If Result <> Undefined Then
		If Result.Value = "ExitApp" Then
			Parameters.Cancel = True;
		ElsIf Result.Value = "Restart" Or Result.Value = DialogReturnCode.Timeout Then
			Parameters.Cancel = True;
			Parameters.Restart = True;
		EndIf;
	EndIf;
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// Generates representation of a single question.
//
//	If UserWarning has the HyperlinkText property, IndividualOpeningForm is opened from
//	the Structure of the question.
//	If UserWarning has the CheckBoxText property,
//	the CommonForm.QuestionBeforeExit form will be opened.
//
// Parameters:
//  Parameters - See StandardSubsystemsClient.ParametersOfActionsBeforeShuttingDownTheSystem.
//  ResponseHandler - CallbackDescription - to continue once the user answered the question.
//  UserWarning - See StandardSubsystemsClient.WarningOnExit.
//  FormName - String - a name of the common form with questions.
//  FormParameters - Structure - parameters for the form with questions.
//
Procedure OpenApplicationWarningForm(Parameters, ResponseHandler, UserWarning, FormName, FormParameters)
	
	HyperlinkText = "";
	If Not UserWarning.Property("HyperlinkText", HyperlinkText) Then
		Return;
	EndIf;
	If IsBlankString(HyperlinkText) Then
		Return;
	EndIf;
	
	ActionOnClickHyperlink = Undefined;
	If Not UserWarning.Property("ActionOnClickHyperlink", ActionOnClickHyperlink) Then
		Return;
	EndIf;
	
	ActionHyperlink = UserWarning.ActionOnClickHyperlink;
	Form = Undefined;
	
	If ActionHyperlink.Property("ApplicationWarningForm", Form) Then
		FormParameters = Undefined;
		If ActionHyperlink.Property("ApplicationWarningFormParameters", FormParameters) Then
			If TypeOf(FormParameters) = Type("Structure") Then 
				FormParameters.Insert("ApplicationShutdown", True);
			ElsIf FormParameters = Undefined Then 
				FormParameters = New Structure;
				FormParameters.Insert("ApplicationShutdown", True);
			EndIf;
			
			FormParameters.Insert("YesButtonTitle",  NStr("vi = 'Kết thúc';
															|ru = 'Завершить';
															|en = 'Exit'; fa = 'خروج';
															|it = 'Completare';
															|pl = 'Zakończ';
															|tr = 'Tamamla'"));
			FormParameters.Insert("NoButtonTitle", NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Anuluj';
														|tr = 'İptal'"));
			
		EndIf;
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("FormName", Form);
		FormOpenParameters.Insert("FormParameters", FormParameters);
		FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
		FormOpenParameters.Insert("WindowOpeningMode", ActionHyperlink.WindowOpeningMode);
		Parameters.InteractiveHandler = New CallbackDescription(
			"WarningInteractiveHandlerOnExit", ThisObject, FormOpenParameters);
		
	ElsIf ActionHyperlink.Property("Form", Form) Then 
		FormParameters = Undefined;
		If ActionHyperlink.Property("FormParameters", FormParameters) Then
			If TypeOf(FormParameters) = Type("Structure") Then 
				FormParameters.Insert("ApplicationShutdown", True);
			ElsIf FormParameters = Undefined Then 
				FormParameters = New Structure;
				FormParameters.Insert("ApplicationShutdown", True);
			EndIf;
		EndIf;
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("FormName", Form);
		FormOpenParameters.Insert("FormParameters", FormParameters);
		FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
		FormOpenParameters.Insert("WindowOpeningMode", ActionHyperlink.WindowOpeningMode);
		Parameters.InteractiveHandler = New CallbackDescription(
			"WarningInteractiveHandlerOnExit", ThisObject, FormOpenParameters);
		
	EndIf;
	
EndProcedure

// If Shutdown = True is specified, abort the further execution of client-side code and shut down the application.
//
Procedure HandleErrorOnStartOrExit(Parameters, ErrorInfo, Event, Shutdown = False)
	
	If Event = "Run" Then
		If Shutdown Then
			Parameters.Cancel = True;
			Parameters.ContinuationHandler = Parameters.CompletionProcessing;
		EndIf;
	Else
		Parameters.ContinuationHandler = New CallbackDescription(
			"ActionsBeforeExitAfterErrorProcessing", ThisObject, Parameters.ContinuationHandler);
	EndIf;
	
	StandardSubsystemsServerCall.WriteErrorToEventLogOnStartOrExit(
		Shutdown, Event, ErrorProcessing.DetailErrorDescription(ErrorInfo));	
		
	WarningText = ErrorProcessing.BriefErrorDescription(ErrorInfo) + Chars.LF + Chars.LF
		+ NStr("vi = 'Ghi lại thông tin kỹ thuật vào nhật ký sự kiện.';
				|ru = 'Техническая информация записана в журнал регистрации.';
				|en = 'Technical information has been saved to the event log.'; fa = 'Technical information has been saved to the event log.';
				|it = 'L''informazione tecnica è registrata nel registro degli eventi.';
				|pl = 'Informacje techniczne są zapisane do dziennika rejestracji.';
				|tr = 'Hata hakkındaki teknik bilgiler kayıt günlüğüne kaydedildi.'");
		
	If Event = "Run" And Shutdown Then
		WarningText = NStr("vi = 'Không thể khởi động ứng dụng:';
							|ru = 'Запуск приложения невозможен:';
							|en = 'Cannot start the application:'; fa = 'Cannot start the application:';
							|it = 'Запуск приложения невозможен:';
							|pl = 'Cannot start the application:';
							|tr = 'Uygulama başlatılamıyor:'")
			+ Chars.LF + Chars.LF + WarningText;
	EndIf;
	
	InteractiveHandler = New CallbackDescription("ShowMessageBoxAndContinue", ThisObject, WarningText);
	Parameters.InteractiveHandler = InteractiveHandler;
	
EndProcedure

Procedure SetInterfaceFunctionalOptionParametersOnStart()
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	If TypeOf(ApplicationStartParameters) <> Type("Structure")
	 Or Not ApplicationStartParameters.Property("InterfaceOptions") Then
		// Startup error processing.
		Return;
	EndIf;
	
	If ApplicationStartParameters.Property("InterfaceOptionsSet") Then
		Return;
	EndIf;
	
	InterfaceOptions = New Structure(ApplicationStartParameters.InterfaceOptions);
	
	// Parameters of the functional options are set only if they are specified
	If InterfaceOptions.Count() > 0 Then
		SetInterfaceFunctionalOptionParameters(InterfaceOptions);
	EndIf;
	
	ApplicationStartParameters.Insert("InterfaceOptionsSet");
	
EndProcedure

Function MustShowRAMSizeRecommendations()
	ClientParameters = ClientParametersOnStart();
	Return ClientParameters.MustShowRAMSizeRecommendations;
EndFunction

Procedure NotifyLowMemory() Export
	RecommendedSize = ClientParametersOnStart().RecommendedRAM;
	
	Title = NStr("vi = 'Giảm tốc độ làm việc';
				|ru = 'Скорость работы снижена';
				|en = 'Application performance degraded'; fa = 'Application performance degraded';
				|it = 'Velocità di lavoro abbassata';
				|pl = 'Szybkość pracy została zmniejszona';
				|tr = 'Çalışma hızı düştü'");
	Text = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nên tăng dung lượng bộ nhớ lên %1 Gb.';
			|ru = 'Рекомендуется увеличить объем памяти до %1 Гб.';
			|en = 'Consider increasing RAM size to %1 GB.'; fa = 'Consider increasing RAM size to %1 GB.';
			|it = 'È consigliabile aumentare il volume della memoria fino a %1 Gb.';
			|pl = 'Zaleca się zwiększyć pojemność pamięci do %1 GB.';
			|tr = 'Bellek kapasitesini %1GB''ye yükseltmeniz önerilir.'"), RecommendedSize);
	
	ShowUserNotification(Title, 
		"e1cib/app/DataProcessor.SpeedupRecommendation",
		Text, PictureLib.DialogExclamation, UserNotificationStatus.Important);
EndProcedure

Procedure NotifyCurrentUserOfUpcomingRestart(SecondsBeforeRestart) Export

	RestartTime = StandardSubsystemsServerCall.AppRestartTimeForApplyPatches();
	RestartTime = ?(RestartTime <> Undefined, Format(RestartTime,"DF=HH:mm"),
		Format(CommonClient.SessionDate() + SecondsBeforeRestart, "DF=HH:mm"));
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã khởi động ứng dụng trong %1';
																				|ru = 'Перезапуск приложения в %1';
																				|en = 'Application restart at %1'; fa = 'Application restart at %1';
																				|it = 'Перезапуск приложения в %1';
																				|pl = 'Application restart at %1';
																				|tr = 'Uygulamanın %1 üzerinde yeniden başlatılması'"), RestartTime);
	MessageText = NStr("vi = 'Đã dự tính từ trước khởi động lại ứng dụng để áp dụng các chỉnh sửa. Hãy nhấn ở đây để hoãn lại.';
						|ru = 'Ранее был запланирован перезапуск приложения для применения исправлений. Нажмите здесь, чтобы отложить.';
						|en = 'You have scheduled the application restart to apply the patches. Click here to postpone.'; fa = 'You have scheduled the application restart to apply the patches. Click here to postpone.';
						|it = 'Ранее был запланирован перезапуск приложения для применения исправлений. Нажмите здесь, чтобы отложить.';
						|pl = 'You have scheduled the application restart to apply the patches. Click here to postpone.';
						|tr = 'Uygulama daha önce yamaların uygulanması için yeniden başlatılmak üzere planlanmıştır. Ertelemek için buraya tıklayın.'");
	ShowUserNotification(
		TitleText,
		"e1cib/app/CommonForm.DynamicUpdateControl",
		MessageText, PictureLib.DialogExclamation,
		UserNotificationStatus.Important,
		"AppRestartToday");

EndProcedure
	
Procedure AttachHandlersOfRestartAndNotificationsWait(SecondsBeforeRestart) Export
	AttachIdleHandler("NotificationFiveMinutesBeforeRestart", SecondsBeforeRestart - 300, True);
	AttachIdleHandler("NotificationThreeMinutesBeforeRestart", SecondsBeforeRestart - 180, True);
	AttachIdleHandler("NotificationOneMinuteBeforeRestart", SecondsBeforeRestart - 60, True);
	AttachIdleHandler("RestartingApplication", SecondsBeforeRestart, True);
EndProcedure 

Procedure DisableScheduledRestart() Export
	DetachIdleHandler("NotificationFiveMinutesBeforeRestart");
	DetachIdleHandler("NotificationThreeMinutesBeforeRestart");
	DetachIdleHandler("NotificationOneMinuteBeforeRestart");
	DetachIdleHandler("RestartingApplication");
EndProcedure

#EndRegion

#EndRegion