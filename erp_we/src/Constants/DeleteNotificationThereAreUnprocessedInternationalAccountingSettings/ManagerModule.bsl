#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function DisplayAlertThereAreRawAccountSettingsAndExtDimension() Export
	
	NotificationIsHidden = False;
	SettingsStorage = Get();
	
	If TypeOf(SettingsStorage) = Type("ValueStorage") Then
		NotificationsSettings = SettingsStorage.Get();
		If TypeOf(NotificationsSettings) <> Type("Structure") Then
		ElsIf NotificationsSettings.Property("HideAlertThereAreRawAccountSettingsAndExtDimension", NotificationIsHidden) Then
		Else
			NotificationIsHidden = False;
		EndIf;
	EndIf;
	
	Return Not NotificationIsHidden;
	
EndFunction

Function DisplayAlertThereAreUnprocessedCorrespondenceSettings() Export
	
	NotificationIsHidden = False;
	SettingsStorage = Get();
	
	If TypeOf(SettingsStorage) = Type("ValueStorage") Then
		NotificationsSettings = SettingsStorage.Get();
		If TypeOf(NotificationsSettings) <> Type("Structure") Then
		ElsIf NotificationsSettings.Property("HideNotificationThereAreUnprocessedCorrespondenceSettings", NotificationIsHidden) Then
		Else
			NotificationIsHidden = False;
		EndIf;
	EndIf;
	
	Return Not NotificationIsHidden;
	
EndFunction

Procedure HideAlertThereAreRawAccountSettingsAndExtDimension() Export
	
	SettingsStorage = Get();
	
	If TypeOf(SettingsStorage) = Type("ValueStorage") Then
		NotificationsSettings = SettingsStorage.Get();
	Else
		NotificationsSettings = New Structure();
	EndIf;
		
	If TypeOf(NotificationsSettings) <> Type("Structure") Then
		NotificationsSettings = New Structure();
	EndIf;
		
	NotificationsSettings.Insert("HideAlertThereAreRawAccountSettingsAndExtDimension", True);
	
	SetPrivilegedMode(True);
	
	SettingsStorage = New ValueStorage(NotificationsSettings);
	Set(SettingsStorage);
	
EndProcedure

Procedure HideNotificationThereAreUnprocessedCorrespondenceSettings() Export
	
	SettingsStorage = Get();
	
	If TypeOf(SettingsStorage) = Type("ValueStorage") Then
		NotificationsSettings = SettingsStorage.Get();
	Else
		NotificationsSettings = New Structure();
	EndIf;
		
	If TypeOf(NotificationsSettings) <> Type("Structure") Then
		NotificationsSettings = New Structure();
	EndIf;
		
	NotificationsSettings.Insert("HideNotificationThereAreUnprocessedCorrespondenceSettings", True);
	
	SetPrivilegedMode(True);
	
	SettingsStorage = New ValueStorage(NotificationsSettings);
	Set(SettingsStorage);
	
EndProcedure

#EndRegion

#EndIf
