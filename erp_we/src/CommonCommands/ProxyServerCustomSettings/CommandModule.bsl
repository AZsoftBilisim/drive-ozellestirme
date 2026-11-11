///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
#If WebClient Then
	ShowMessageBox(, NStr("vi = 'Trong web-client, cần đặt tham số proxy-server trong tùy chỉnh trình duyệt.';
							|ru = 'В веб-клиенте параметры прокси-сервера необходимо задавать в настройках браузера.';
							|en = 'Please specify the proxy server parameters in the browser settings.'; fa = 'Please specify the proxy server parameters in the browser settings.';
							|it = 'Nel client Web, i parametri del server proxy devono essere forniti nelle impostazioni del browser';
							|pl = 'Dla klienta sieci Web parametry serwera proxy należy określać w ustawieniach przeglądarki.';
							|tr = 'Tarayıcı ayarlarında web istemcisinin proxy sunucu parametrelerini ayarlayın.'"));
	Return;
#EndIf
	
	OpenForm("CommonForm.ProxyServerParameters", New Structure("ProxySettingAtClient", True));
	
EndProcedure

#EndRegion
