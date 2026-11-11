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
	
	If Not Parameters.Property("OpenByScenario") Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	SkipExit = Parameters.SkipExit;
	
	Items.MessageText.Title = Parameters.MessageText;
	SystemInfo = New SystemInfo;
	Current       = SystemInfo.AppVersion;
	Min   = Parameters.MinPlatformVersion;
	Recommended = Parameters.RecommendedPlatformVersion;
	
	Items.MessageText.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.MessageText.Title, Min);
	
	VersionNumber   = Recommended;
	CannotContinue = False;
	TextCondition = "";
	If CommonClientServer.CompareVersions(Current, Min) < 0 Then
		TextCondition = NStr("vi = 'Để làm việc với ứng dụng, hãy sử dụng phiên bản của nền tảng ""1C:Enterprise 8"" không thấp hơn %1.
			|Phiên bản đang được sử dụng: %2.';
			|ru = 'Для работы с приложением необходимо использовать версию платформы ""1С:Предприятие 8"" не ниже %1.
			|Используемая сейчас версия: %2.';
			|en = 'The app requires 1C:Enterprise version %1 or later.
			|Current version is %2.'; fa = 'The app requires 1C:Enterprise version %1 or later.
			|Current version is %2.';
			|it = 'Для работы с приложением необходимо использовать версию платформы ""1С:Предприятие 8"" не ниже %1.
			|Используемая сейчас версия: %2.';
			|pl = 'The app requires 1C:Enterprise version %1 or later.
			|Current version is %2.';
			|tr = 'Uygulamayla çalışmak için 1C:Enterprise 8 platformunun %1''den düşük olmayan bir sürümünü kullanmanız gerekir.
			|Şu anda kullanımda olan sürüm:%2.'");
		CannotContinue = True;
		VersionNumber = Min;
	Else
		TextCondition = NStr("vi = 'Để làm việc với ứng dụng, hãy sử dụng phiên bản của nền tảng ""1C:Enterprise 8"" không thấp hơn %1.
			|Phiên bản đang được sử dụng: %2.';
			|ru = 'Для работы с приложением рекомендуется использовать версию платформы ""1С:Предприятие 8"" не ниже %1.
			|Используемая сейчас версия: %2.';
			|en = 'We recommend using 1C:Enterprise version %1 or later.
			|Current version is %2.'; fa = 'We recommend using 1C:Enterprise version %1 or later.
			|Current version is %2.';
			|it = 'Для работы с приложением рекомендуется использовать версию платформы ""1С:Предприятие 8"" не ниже %1.
			|Используемая сейчас версия: %2.';
			|pl = 'We recommend using 1C:Enterprise version %1 or later.
			|Current version is %2.';
			|tr = 'Programla çalışmak için,%1 ""1C:Enterprise 8"" platform sürümünü kullanın%2. 
			|Şu anda kullanımda olan sürüm:%3'");
	EndIf;
	
	Items.Version.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TextCondition,
		VersionNumber,
		SystemInfo.AppVersion);
	
	If CannotContinue Then
		Items.QueryText.Visible = False;
		Items.FormNo.Visible     = False;
		Title = NStr("vi = 'Cần cập nhật phiên bản nền tảng';
					|ru = 'Необходимо обновить версию платформы';
					|en = '1C:Enterprise update required'; fa = '1C:Enterprise update required';
					|it = 'È necessario aggiornare la versione della piattaforma';
					|pl = 'Musisz zaktualizować wersję platformy';
					|tr = '1C:Enterprise''ın güncellenmesi gerekiyor'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not ActionDefined Then
		ActionDefined = True;
		
		If Not SkipExit Then
			Terminate();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HyperlinkAnchorTextClick(Item)
	
	OpenForm("DataProcessor.PlatformUpdateRecommended.Form.PlatformUpdateOrder",,ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ContinueWork(Command)
	
	ActionDefined = True;
	Close("Continue");
	
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	
	ActionDefined = True;
	If Not SkipExit Then
		Terminate();
	EndIf;
	Close();
	
EndProcedure

#EndRegion
