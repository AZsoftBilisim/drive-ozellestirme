///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not SafeModeManagerInternal.SecurityProfilesUsageAvailable() Then
		Raise NStr("vi = 'Không cho phép sử dụng hồ sơ bảo mật.';
					|ru = 'Недоступно использование профилей безопасности.';
					|en = 'Security profiles are unavailable'; fa = 'Security profiles are unavailable';
					|it = 'Недоступно использование профилей безопасности.';
					|pl = 'Security profiles are unavailable';
					|tr = 'Güvenlik profillerini kullanma ayarlar.'");
	EndIf;
	
	If Not SafeModeManagerInternal.CanSetUpSecurityProfiles() Then
		Raise NStr("vi = 'Không cho phép tùy chỉnh hồ sơ an toàn.';
					|ru = 'Настройка профилей безопасности недоступна.';
					|en = 'Setting of security profiles is unavailable.'; fa = 'Setting of security profiles is unavailable.';
					|it = 'Настройка профилей безопасности недоступна.';
					|pl = 'Setting of security profiles is unavailable.';
					|tr = 'Güvenlik profilleri yapılandırılamaz.'");
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền truy cập.';
					|ru = 'Недостаточно прав доступа.';
					|en = 'Insufficient access rights.'; fa = 'حقوق دسترسی ناکافی.';
					|it = 'Diritti di accesso insufficienti.';
					|pl = 'Niewystarczające uprawnienia dostępu.';
					|tr = 'Yetersiz erişim hakı.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	ReadSecurityProfilesUsageMode();
	SetAvailability();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProfileSecurityUsageModeOnChange(Item)
	
	Try
		
		StartApplyingSecurityProfilesSettings(UUID);
		
		PreviousMode = CurrentSecurityProfilesUsageMode();
		NewMode = ProfileSecurityUsageMode;
		
		If (PreviousMode <> NewMode) Then
			
			If (PreviousMode = 2 Or NewMode = 2) Then
				
				ClosingNotification1 = New CallbackDescription("AfterCloseSecurityProfileCustomizationWizard", ThisObject, True);
				
				If NewMode = 2 Then
					
					ExternalResourcesPermissionsSetupClient.StartEnablingSecurityProfilesUsage(ThisObject, ClosingNotification1);
					
				Else
					
					ExternalResourcesPermissionsSetupClient.StartDisablingSecurityProfilesUsage(ThisObject, ClosingNotification1);
					
				EndIf;
				
			Else
				
				EndApplyingSecurityProfilesSettings();
				SetAvailability("ProfileSecurityUsageMode");
				
			EndIf;
			
		EndIf;
		
	Except
		
		ReadSecurityProfilesUsageMode();
		Raise;
		
	EndTry;
	
EndProcedure

&AtClient
Procedure InfobaseSecurityProfileOnChange(Item)
	If TypeOf(ConstantsSet.InfobaseSecurityProfile) <> Type("String") Then
		ConstantsSet.InfobaseSecurityProfile = "";
	EndIf;
	Attachable_OnChangeAttribute(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RequiredPermissions(Command)
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	
	OpenForm(
		"Report.ExternalResourcesInUse.ObjectForm",
		ReportParameters);
	
EndProcedure

&AtClient
Procedure RestoreSecurityProfiles(Command)
	
	Try
		
		StartApplyingSecurityProfilesSettings(UUID);
		ClosingNotification1 = New CallbackDescription("AfterCloseSecurityProfileCustomizationWizard", ThisObject, True);
		ExternalResourcesPermissionsSetupClient.StartRestoringSecurityProfiles(ThisObject, ClosingNotification1);
		
	Except
		
		ReadSecurityProfilesUsageMode();
		Raise;
		
	EndTry;
	
EndProcedure

&AtClient
Procedure OpenExternalDataProcessor(Command)
	
	SafeModeManagerClient.OpenExternalDataProcessorOrReport(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterCloseSecurityProfileCustomizationWizard(Result, ClientApplicationRestartRequired) Export
	
	If Result = DialogReturnCode.OK Then
		EndApplyingSecurityProfilesSettings();
	EndIf;
	
	ReadSecurityProfilesUsageMode();
	
	If Result = DialogReturnCode.OK And ClientApplicationRestartRequired Then
		Terminate(True);
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadSecurityProfilesUsageMode()
	
	ProfileSecurityUsageMode = CurrentSecurityProfilesUsageMode();
	SetAvailability("ProfileSecurityUsageMode");
	
EndProcedure

&AtServer
Function CurrentSecurityProfilesUsageMode()
	
	If SafeModeManagerInternal.SecurityProfilesUsageAvailable() And GetFunctionalOption("UseSecurityProfiles") Then
		
		If Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get() Then
			
			Result = 2; // From the current infobase
			
		Else
			
			Result = 1; // Via the cluster console
			
		EndIf;
		
	Else
		
		Result = 0; // Obsolete
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure StartApplyingSecurityProfilesSettings(Val UUID)
	
	If Not SafeModeManagerInternal.SecurityProfilesUsageAvailable() Then
		Raise NStr("vi = 'Chú ý! Không sử dụng bật yêu cầu quyền tự động';
					|ru = 'Внимание! Включение автоматического запроса разрешений недоступно';
					|en = 'Warning! Enabling automatic permission request is not available.'; fa = 'Warning! Enabling automatic permission request is not available.';
					|it = 'Attenzione! La connessione della richiesta automatica di autorizzazione non è disponibile';
					|pl = 'Uwaga! Włączenie automatycznego żądania uprawnień jest niedostępne.';
					|tr = 'Dikkat! Otomatik izin istemleri etkinleştirilemez'");
	EndIf;
	
	SetExclusiveMode(True);
	
EndProcedure

&AtServer
Procedure EndApplyingSecurityProfilesSettings()
	
	If ProfileSecurityUsageMode = 0 Then
		
		Constants.UseSecurityProfiles.Set(False);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(False);
		Constants.InfobaseSecurityProfile.Set("");
		
	ElsIf ProfileSecurityUsageMode = 1 Then
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(False);
		
	ElsIf ProfileSecurityUsageMode = 2 Then
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(True);
		
	EndIf;
	
	If ExclusiveMode() Then
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	Return ConstantName;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If Users.IsFullUser(, True) Then
		
		If DataPathAttribute = "ProfileSecurityUsageMode" Or DataPathAttribute = "" Then
			
			Items.InfobaseSecurityProfileGroup.Enabled = ProfileSecurityUsageMode > 0;
			
			Items.InfobaseSecurityProfile.ReadOnly = (ProfileSecurityUsageMode = 2);
			Items.SecurityProfilesRestorationGroup.Enabled = (ProfileSecurityUsageMode = 2);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
