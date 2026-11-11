///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure ShowExchangeRatesImport(FormParameters = Undefined) Export
	
	CurrencyRateOperationsClientLocalization.ShowExchangeRatesImport(FormParameters);
	
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("Currencies") And ClientParameters.Currencies.ExchangeRatesUpdateRequired Then
		AttachIdleHandler("CurrencyRateOperationsOutputObsoleteDataNotification", 180, True);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Update currency rates.

Function SettingsOnClient()
	
	ParameterName = "StandardSubsystems.Currencies";
	Settings = ApplicationParameters[ParameterName];
	
	If Settings = Undefined Then
		Settings = New Structure;
		Settings.Insert("LastNotificationDayStart", '00010101');
		ApplicationParameters[ParameterName] = Settings;
	EndIf;
	
	Return Settings;
	
EndFunction

Procedure NotifyRatesObsolete(Val ShouldCheckValidity = False) Export
	
	If ShouldCheckValidity And CurrenciesExchangeRatesServerCall.RatesUpToDate() Then
		Return;
	EndIf;
	
	DateStartOfDay = BegOfDay(CommonClient.SessionDate());
	Settings = SettingsOnClient();
	
	If Settings.LastNotificationDayStart >= DateStartOfDay Then
		Return;
	EndIf;
	Settings.LastNotificationDayStart = DateStartOfDay;
	
	ShowNotification(
		NStr("vi = 'Tỷ giá ngoại tệ đã cũ';
			|ru = 'Курсы валют устарели';
			|en = 'Outdated exchange rates'; fa = 'Outdated exchange rates';
			|it = 'I tassi di cambio sono obsoleti';
			|pl = 'Kursy walut są nieaktualne';
			|tr = 'Döviz kurları güncel değil'"),
		DataProcessorURL(),
		NStr("vi = 'Cập nhật tỷ giá ngoại tệ';
			|ru = 'Обновить курсы валют';
			|en = 'Update exchange rates'; fa = 'Update exchange rates';
			|it = 'Aggiornare i tassi di cambio';
			|pl = 'Aktualizuj kursy walut';
			|tr = 'Döviz kurlarını güncelle'"),
		PictureLib.DialogExclamation,
		UserNotificationStatus.Important,
		"ExchangeRatesAreOutdated");
	
EndProcedure

// Displays the update notification.
//
Procedure NotifyRatesAreUpdated() Export
	
	ShowUserNotification(
		NStr("vi = 'Đã cập nhật thành công tỷ giá ngoại tệ';
			|ru = 'Курсы валют успешно обновлены';
			|en = 'Exchange rates updated'; fa = 'Exchange rates updated';
			|it = 'Tassi di cambio aggiornati con successo';
			|pl = 'Kursy walut pomyślnie zaktualizowane';
			|tr = 'Döviz kurları güncellendi'"),
		,
		NStr("vi = 'Đã cập nhật tỷ giá ngoại tệ';
			|ru = 'Курсы валют обновлены';
			|en = 'The exchange rates are updated.'; fa = 'The exchange rates are updated.';
			|it = 'Tassi di cambio aggiornati';
			|pl = 'Kursy walut zaktualizowane';
			|tr = 'Döviz kurları güncellendi.'"),
		PictureLib.DialogInformation);
	
EndProcedure

// Displays the update notification.
//
Procedure NotifyRatesUpToDate() Export
	
	ShowMessageBox(,NStr("vi = 'Đã kết nhập thành công tỷ giá hối đoái.';
						|ru = 'Актуальные курсы валют успешно загружены.';
						|en = 'Up-to-date exchange rates are imported.'; fa = 'Up-to-date exchange rates are imported.';
						|it = 'Актуальные курсы валют успешно загружены.';
						|pl = 'Up-to-date exchange rates are imported.';
						|tr = 'Gerçek para birimi döviz kurları başarıyla indirildi.'"));
	
EndProcedure

// Returns a notification URL.
//
Function DataProcessorURL()
	Return "e1cib/app/DataProcessor.CurrenciesRatesImport";
EndFunction

Procedure ShowNotification(Text, ActionOnClick, Explanation, Picture, Var_UserNotificationStatus, UniqueKey)
	
	ShowUserNotification(
		Text,
		ActionOnClick,
		Explanation,
		Picture,
		Var_UserNotificationStatus,
		UniqueKey);
		
EndProcedure

#EndRegion