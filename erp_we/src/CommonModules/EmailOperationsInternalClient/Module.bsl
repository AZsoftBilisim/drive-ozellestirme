///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// See StandardSubsystemsClient.OnReceiptServerNotification
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert <> EmailOperationsInternalClientServer.ServerNotificationName() Then
		Return;
	EndIf;
	
	If Result.EventName = "OpenAuthorizationOfTheEmailService" Then
		Notify("OpenAuthorizationOfTheEmailService", Result.Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function SupportRequestTopic(Val TechnicalInformation) Export
	
	MainReason = StrReplace(TechnicalInformation, Chars.LF, " ");
	
	LengthLimitation = 500;
	MainReason = Left(MainReason, LengthLimitation);
	
	Template = NStr("vi = 'Cài đặt hộp thư: %1';
					|ru = 'Настройка почтового ящика: %1';
					|en = 'Configure email: %1'; fa = 'Configure email: %1';
					|it = 'Configure email: %1';
					|pl = 'Configure email: %1';
					|tr = 'Posta kutusu ayarı: %1'");
	Result = StringFunctionsClientServer.SubstituteParametersToString(Template, MainReason);
	
	Return Result;
	
EndFunction

Function SupportRequestText(Val Email, Val TechnicalInformation) Export
	
	MainReason = StrReplace(TechnicalInformation, Chars.LF, " ");
	
	Template = NStr("vi = 'Vấn đề khi cài đặt hộp thư %1: %2.
		|
		|<Vui lòng mô tả sự cố đã xảy ra và đính kèm ảnh chụp màn hình của lỗi.>';
		|ru = 'Проблема при настройке почтового ящика %1: %2.
		|
		|<Опишите возникшую проблему и приложите скриншоты ошибки.>';
		|en = 'Issue when configuring email %1: %2.
		|
		|<Describe the issue and attach screenshots.>'; fa = 'Issue when configuring email %1: %2.
		|
		|<Describe the issue and attach screenshots.>';
		|it = 'Issue when configuring email %1: %2.
		|
		|<Describe the issue and attach screenshots.>';
		|pl = 'Issue when configuring email %1: %2.
		|
		|<Describe the issue and attach screenshots.>';
		|tr = '%1 posta kutusu ayarlanırken sorun oluştu: %2.
		|
		|<Sorunu açıklayın ve hatanın ekran görüntülerini ekleyin.>'");
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		Email,
		MainReason);
	
	Return Result;
	
EndFunction

#EndRegion
