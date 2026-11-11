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
	
	ErrorsMessages = Parameters.ErrorText;
	Account = Parameters.Account;
	
	If ValueIsFilled(ErrorsMessages) Then
		Title = Parameters.Title;
		AutoTitle = False;
		Items.Pages.CurrentPage = Items.ErrorsFoundOnCheck;
		FillinExplanations();
		FillInInformationForSupport();
		SetKeyToSaveWindowPosition();
	Else
		Items.Pages.CurrentPage = Items.SettingsCheckInProgress;
		Items.FormClose.Title = NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Anuluj';
									|tr = 'İptal'");
		Items.FormGoToSettings.Visible = False;
		Items.AssistanceRequiredGroup.Visible = False;
	EndIf;
	
	Items.FormBack.Visible = False;
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
			"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.OnCreateAtServer(ThisObject);
		
	Else
		Items.AssistanceRequiredGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(ErrorsMessages) Then
		AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RecommendationsPossibleReasonsURLProcessing(Item, Var_URL, StandardProcessing)
	
	If CommonClientServer.URIStructure(Var_URL).Schema = "" Then
		StandardProcessing = False;
		PatchID = Var_URL;
		GotoMailSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationTechnicalDetailsClick(Item)
	
	Items.Pages.CurrentPage = Items.TechnicalDetails;
	Items.FormBack.Visible = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToSettings(Command)
	
	GotoMailSettings();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.Pages.CurrentPage = Items.ErrorsFoundOnCheck;
	Items.FormBack.Visible = False;
	
EndProcedure

&AtClient
Procedure SupportTicket(Command)
	
	// StandardSubsystems.SupportRequests
	If CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
			"SupportRequestsInternalClient");
		
		RequestParameters_ = ModuleSupportRequestsInternalClient.RequestParameters_();
		RequestParameters_.TechnologicalInfo = SupportInformation;
		RequestParameters_.EventLogFilter.Insert("StartDate", ErrorRegistrationTime);
		
		RequestParameters_.Subject = EmailOperationsInternalClient.SupportRequestTopic(
			ErrorsMessages);
		
		RequestParameters_.Message = EmailOperationsInternalClient.SupportRequestText(
			Parameters.Account,
			ErrorsMessages);
		
		ModuleSupportRequestsInternalClient.SubmitSupportTicket(
			ThisObject,
			RequestParameters_);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure InfoForSupport(Command)
	
	// StandardSubsystems.SupportRequests
	If CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
			"SupportRequestsInternalClient");
		
		RequestParameters_ = ModuleSupportRequestsInternalClient.RequestParameters_();
		RequestParameters_.TechnologicalInfo = SupportInformation;
		RequestParameters_.EventLogFilter.Insert("StartDate", ErrorRegistrationTime);
		
		ModuleSupportRequestsInternalClient.DownloadInfoForSupport(
			ThisObject,
			RequestParameters_);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExecuteSettingsCheck()
	TimeConsumingOperation = StartExecutionAtServer();
	CallbackOnCompletion = New CallbackDescription("ProcessResult", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
EndProcedure

&AtServer
Function StartExecutionAtServer()
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "Catalogs.EmailAccounts.ValidateAccountSettings",
		Parameters.Account);
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ProcessResult(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Items.FormClose.Title = NStr("vi = 'Đóng';
								|ru = 'Закрыть';
								|en = 'Close'; fa = 'بستن';
								|it = 'Chiudere';
								|pl = 'Zamknij';
								|tr = 'Kapat'");
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	CheckResult = GetFromTempStorage(Result.ResultAddress);
	
	SupportInformation = CheckResult.ConnectionErrors;
	ExecutedChecks = CheckResult.ExecutedChecks;
	
	If ValueIsFilled(SupportInformation) Then
		
		ErrorsMessages = StrConcat(CheckResult.ErrorsTexts, Chars.LF);
		FillinExplanations();
		
		Items.Pages.CurrentPage = Items.ErrorsFoundOnCheck;
		
		ErrorRegistrationTime = CommonClient.SessionDate();
		ShowNeedHelpSection();
		
	Else
		Items.Pages.CurrentPage = Items.CheckCompletedSuccessfully;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowNeedHelpSection()
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
			"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.ShowNeedHelpSection(Items);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtServer
Procedure FillinExplanations()
	
	ExplanationOnError = ExplanationOnError();
	
	PossibleReasons = EmailOperationsInternal.FormattedList(ExplanationOnError.PossibleReasons);
	MethodsToFixError = EmailOperationsInternal.FormattedList(ExplanationOnError.MethodsToFixError);
	
	Items.DecorationRecommendations.Title = MethodsToFixError;
	Items.DecorationPossibleReasons.Title = PossibleReasons;
	
EndProcedure

&AtServer
Function ExplanationOnError()
	
	UserAccountAttributes = Common.ObjectAttributesValues(Account, "IncomingMailServer, OutgoingMailServer");
	IncomingMailServer = UserAccountAttributes.IncomingMailServer;
	OutgoingMailServer = UserAccountAttributes.OutgoingMailServer;
	
	ExplanationParameters = EmailOperationsInternal.ExplanationParameters();
	ExplanationParameters.ErrorText = ErrorsMessages;
	ExplanationParameters.Context = EmailOperationsInternal.ContextForExplanation().ManualSetting;
	ExplanationParameters.ServerNames = EmailOperationsInternal.ServersNamesForExplanation(IncomingMailServer, OutgoingMailServer);
	
	Return EmailOperationsInternal.ExplanationOnError(ExplanationParameters);
	
EndFunction

&AtServer
Procedure FillInInformationForSupport(DetailedErrorDetails = "")
	
	If ValueIsFilled(DetailedErrorDetails) Then
		SupportInformation = DetailedErrorDetails;
		Return;
	EndIf;
	
	ErrorDescriptionTemplate = NStr("vi = '%1
		|
		|Khuyến cáo:
		|%2
		|
		|Nguyên nhân có thể có:
		|%3
		|
		|============================
		|
		|Thông tin để hỗ trợ kỹ thuật:
		|
		|%4';
		|ru = '%1
		|
		|Рекомендации:
		|%2
		|
		|Возможные причины:
		|%3
		|
		|============================
		|
		|Информация для техподдержки:
		|
		|%4';
		|en = '%1
		|
		|Troubleshooting:
		|%2
		|
		|Possible reasons:
		|%3
		|
		|============================
		|
		|Information for technical support:
		|
		|%4'; fa = '%1
		|
		|Troubleshooting:
		|%2
		|
		|Possible reasons:
		|%3
		|
		|============================
		|
		|Information for technical support:
		|
		|%4';
		|it = '%1
		|
		|Troubleshooting:
		|%2
		|
		|Possible reasons:
		|%3
		|
		|============================
		|
		|Information for technical support:
		|
		|%4';
		|pl = '%1
		|
		|Troubleshooting:
		|%2
		|
		|Possible reasons:
		|%3
		|
		|============================
		|
		|Information for technical support:
		|
		|%4';
		|tr = '%1
		|
		|Öneriler:
		|%2
		|
		|Mümkün sebepler:
		|%3
		|
		|============================
		|
		|Teknik destek için bilgiler:
		|
		|%4'");
	
	DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorDescriptionTemplate,
		ErrorsMessages,
		MethodsToFixError,
		PossibleReasons,
		TechnicalDetailsForSupport(Parameters.Account));
	
	SupportInformation = DetailedErrorDetails;
	
EndProcedure

&AtServerNoContext
Function TechnicalDetailsForSupport(Account)
	
	Result = New Array;
	
	MailProfile = EmailOperationsInternal.InternetMailProfile(Account);
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		ConnectionDiagnostics = ModuleNetworkDownload.ConnectionDiagnostics(MailProfile.SMTPServerAddress);
		Result.Add(ConnectionDiagnostics.DiagnosticsLog);
	EndIf;
	
	SettingsDescription = Catalogs.EmailAccounts.SettingsDescription(MailProfile, Undefined);
	Result.Add(SettingsDescription);
	
	Result.Add("");
	
	ApplicationInfo = Catalogs.EmailAccounts.ApplicationInfo();
	Result.Add(ApplicationInfo);
	
	Return StrConcat(Result, Chars.LF);
	
EndFunction

&AtServer
Procedure SetKeyToSaveWindowPosition()
	
	WindowOptionsKey = Common.CheckSumString(String(PossibleReasons) + String(MethodsToFixError));
	
EndProcedure

&AtClient
Procedure GotoMailSettings()
	
	If FormOwner <> Undefined And FormOwner.FormName = "Catalog.EmailAccounts.Form.ItemForm" Then
		Close(PatchID);
	Else
		OpeningParameters = New Structure;
		OpeningParameters.Insert("Key", Parameters.Account);
		OpeningParameters.Insert("PatchID", PatchID);
		
		OpenForm("Catalog.EmailAccounts.ObjectForm", OpeningParameters, ThisObject);
	EndIf;
	
EndProcedure

#EndRegion
