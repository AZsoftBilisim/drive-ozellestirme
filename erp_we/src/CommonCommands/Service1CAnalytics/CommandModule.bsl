#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	InformationLink = ServerAddress();
	If IsBlankString(InformationLink) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ định địa chỉ server 1C:Analytics. Cần hoàn thành tùy chỉnh tích hợp với 1C:Analytics. Hãy liên hệ với người quản trị';
										|ru = 'Адрес сервера 1С:Аналитики не указан. Необходимо завершить настройку интеграции с 1С:Аналитикой. Обратитесь к администратору';
										|en = '1C:Analytics server address is not specified. Complete the 1C:Analytics integration setup. Contact the administrator'; fa = '1C:Analytics server address is not specified. Complete the 1C:Analytics integration setup. Contact the administrator';
										|it = 'Адрес сервера 1С:Аналитики не указан. Необходимо завершить настройку интеграции с 1С:Аналитикой. Обратитесь к администратору';
										|pl = '1C:Analytics server address is not specified. Complete the 1C:Analytics integration setup. Contact the administrator';
										|tr = '1C:Analytics sunucusunun adresi belirtilmedi. 1C:Analytics ile entegrasyon ayarlanmalıdır. Yönetici ile iletişime geçin'"));
		Return;
	EndIf;
	
	FileSystemClient.OpenURL(InformationLink);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ServerAddress()
	Return AnalyticsSystem.GetAnalyticsSystemServerAddress();
EndFunction

#EndRegion