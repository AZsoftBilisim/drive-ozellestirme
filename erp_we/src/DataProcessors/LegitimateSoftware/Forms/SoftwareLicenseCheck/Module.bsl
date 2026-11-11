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
	
	If Not Parameters.OpenProgrammatically Then
		Raise
			NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp';
				|ru = 'Обработка не предназначена для непосредственного использования.';
				|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
				|it = 'L''elaborazione non è destinata all''uso diretto.';
				|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
				|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	SkipRestart = Parameters.SkipRestart;
	
	WarningText = TextFromUpdateDistributionTermsTemplate();
	
	FileInfobase = Common.FileInfobase();
	
	// StandardSubsystems.MonitoringCenter
	MonitoringCenterExists = Common.SubsystemExists("StandardSubsystems.MonitoringCenter");
	If MonitoringCenterExists Then
		ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
		MonitoringCenterParameters = ModuleMonitoringCenterInternal.GetMonitoringCenterParametersExternalCall();
				
		If (Not MonitoringCenterParameters.EnableMonitoringCenter And  Not MonitoringCenterParameters.ApplicationInformationProcessingCenter) Then
			AllowSendStatistics = True;
			Items.SendStatisticsGroup.Visible = True;
		Else
			AllowSendStatistics = True;
			Items.SendStatisticsGroup.Visible = False;
		EndIf;
	Else
		Items.SendStatisticsGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.MonitoringCenter
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.FormContinue.Representation = ButtonRepresentation.Picture;
	EndIf;
	
	CurrentItem = Items.AcceptTermsBoolean;
	
EndProcedure

&AtServerNoContext
Function TextFromUpdateDistributionTermsTemplate()

	CodeCurrentLanguage = ?(TypeOf(CurrentLanguage()) = Type("String"), CurrentLanguage(), CurrentLanguage().LanguageCode);
	TemplateName = "UpdateDistributionTerms";
	
	InformationTemplate = Undefined;
	If Metadata.Languages.Count() > 0 Then
		InformationTemplate = Metadata.DataProcessors.LegitimateSoftware.Templates.Find(
			StrTemplate("%1_%2", TemplateName, CodeCurrentLanguage));
	EndIf;
	
	If InformationTemplate = Undefined Then
		InformationTemplate = Metadata.DataProcessors.LegitimateSoftware.Templates.Find(TemplateName);
	EndIf;
	
	If InformationTemplate = Undefined Then
		InformationTemplate = Metadata.DataProcessors.LegitimateSoftware.Templates.Find(
			StrTemplate("%1_%2", TemplateName, Common.DefaultLanguageCode()));
	EndIf;
	
	If InformationTemplate = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong bộ xử lý %1 không có khuôn in %2. Cần thêm khuôn in vào cấu hình.';
					|ru = 'В обработке %1 отсутствует макет %2. Требуется добавить его в конфигурацию.';
					|en = 'The required template %2 is missing from the data processor %1.'; fa = 'The required template %2 is missing from the data processor %1.';
					|it = 'The required template %2 is missing from the data processor %1.';
					|pl = 'The required template %2 is missing from the data processor %1.';
					|tr = 'Veri işlemcisi %1''de şablon %2 yoktur. Konfigürasyona eklenmesi gerekmektedir.'"),
				Metadata.DataProcessors.LegitimateSoftware.Name, TemplateName);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
 	EndIf;
	
	DocumentTemplate = DataProcessors.LegitimateSoftware.GetTemplate(
		InformationTemplate.Name);
	
	Return DocumentTemplate.GetText();
	
EndFunction

&AtClient
Procedure OnOpen(Cancel)
	
	EnablingPatches = StrFind(LaunchParameter, "EnablePatchesAndExit") > 0;
	UpdateWithExit = StrFind(LaunchParameter, "UpdateAndExit") > 0;
	
	If FileInfobase
	   And (EnablingPatches Or UpdateWithExit) Then
		
		If UpdateWithExit Then
			WriteLegitimateSoftwareConfirmation();
		EndIf;
		Cancel = True;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("ConfirmSoftwareLicense", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ContinueFormMainActions(Command)
	
	Result = AcceptTermsBoolean;
	
	If Result <> True Then
		If Parameters.ShowRestartWarning And Not SkipRestart Then
			Terminate();
		EndIf;
	Else
		WriteLegalityAndStatisticsSendingConfirmation(AllowSendStatistics);
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	ElsIf Result <> True Then
		If Parameters.ShowRestartWarning And Not SkipRestart Then
			Terminate();
		EndIf;
	EndIf;
	
	Notify("LegitimateSoftware", Result);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConfirmSoftwareLicense()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	RunCallback(CallbackDescriptionOnClose, True);
	
EndProcedure

&AtServerNoContext
Procedure WriteLegalityAndStatisticsSendingConfirmation(AllowSendStatistics)
	
	WriteLegitimateSoftwareConfirmation();
	
	SetPrivilegedMode(True);
	
	MonitoringCenterExists = Common.SubsystemExists("StandardSubsystems.MonitoringCenter");
	If MonitoringCenterExists Then
		ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
		
		SendStatisticsParameters = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter", Undefined, Undefined);
		SendStatisticsParameters = ModuleMonitoringCenterInternal.GetMonitoringCenterParametersExternalCall(SendStatisticsParameters);
		
		If (Not SendStatisticsParameters.EnableMonitoringCenter And SendStatisticsParameters.ApplicationInformationProcessingCenter) Then
			// Sending statistics to a third-party developer is configured.
			// Do not change it.
			//
		Else
			If AllowSendStatistics Then
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("EnableMonitoringCenter", AllowSendStatistics);
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("ApplicationInformationProcessingCenter", False);
				SchedJob = ModuleMonitoringCenterInternal.GetScheduledJobExternalCall("StatisticsDataCollectionAndSending", True);
				ModuleMonitoringCenterInternal.SetDefaultScheduleExternalCall(SchedJob);
			Else
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("EnableMonitoringCenter", AllowSendStatistics);
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("ApplicationInformationProcessingCenter", False);
				ModuleMonitoringCenterInternal.DeleteScheduledJobExternalCall("StatisticsDataCollectionAndSending");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure WriteLegitimateSoftwareConfirmation()
	SetPrivilegedMode(True);
	InfobaseUpdateInternal.WriteLegitimateSoftwareConfirmation();
EndProcedure

#EndRegion