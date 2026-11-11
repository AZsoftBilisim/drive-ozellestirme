
#Region FormEventHandlers

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CertificateAddress) Then
		BinaryData = GetFromTempStorage(CertificateAddress);
		CurrentObject.IOSMobileApplicationCertificate = New ValueStorage(BinaryData, New Deflation());
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	OnReadCreateAtServer();
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
EndProcedure

#EndRegion

#Region FormHeaderEventHandlers

&AtClient
Procedure UseAPNSOnChange(Item)
	
	If Not Object.UseAPNS Then
		CertificateIsLoaded = False;
	EndIf;
	SetAvailability();
EndProcedure

&AtClient
Procedure UseGCMOnChange(Item)
	
	If Not Object.UseGCM Then
		Object.GoogleCloudAppsApplicationNumber = "";
		Object.ServerAPIKeySenderGCM = "";
	EndIf;
	SetAvailability();
EndProcedure

&AtClient
Procedure UsePushNotificationsOnChange(Item)
	
	UsePushNotificationsOnChangeAtServer();
EndProcedure

&AtClient
Procedure UsePushNotificationsExtendedPushPrompt(Item)
	
	CommonClient.OpenURL("http://its.1c.ru/db/v83doc#bookmark:dev:TI000001541");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportCertificate(Command)
	
	Notification = New CallbackDescription("ImportCertificateCompletion", ThisObject);
	BeginPutFile(Notification, , "", True, UUID);
EndProcedure

&AtClient
Procedure GetLogin(Command)
	
	CommonClient.OpenURL("https://pushnotifications.1c.com/push/publishers/new");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportCertificateCompletion(Result, TempStorageAddress, SelectedName, AdditionalParameters) Export
	
	If Result Then
		CertificateAddress = TempStorageAddress;
		CertificateIsLoaded = Not IsBlankString(CertificateAddress);
	EndIf;
EndProcedure

&AtServer
Procedure UsePushNotificationsOnChangeAtServer()
	
	If Not Object.PushNotificationOption = Enums.PushNotificationOptions.SendDirectly Then
		If Object.UseAPNS Then
			Object.UseAPNS = False;
		EndIf;
		If Object.UseGCM Then
			Object.UseGCM = False;
		EndIf;
	EndIf;
	
	If Object.PushNotificationOption = Enums.PushNotificationOptions.SendViaSupportingService Then
		Items.ThirdPartyGroup.Enabled = False;
		Items.ServiceGroup_3.Enabled = True;
	ElsIf Object.PushNotificationOption = Enums.PushNotificationOptions.SendDirectly Then
		Items.ThirdPartyGroup.Enabled = True;
		Items.ServiceGroup_3.Enabled = False;
	Else
		Items.ThirdPartyGroup.Enabled = False;
		Items.ServiceGroup_3.Enabled = False;
	EndIf;
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	Title = NStr("vi = 'Tùy chỉnh gửi thông báo đẩy cho người sử dụng ứng dụng di động ""1C:Đơn hàng"".';
				|ru = 'Настройка отправки push-уведомлений пользователям мобильного приложения ""1С:Заказы"".';
				|en = 'Set up push notifications to 1C:Orders mobile application users'; fa = 'Set up push notifications to 1C:Orders mobile application users';
				|it = 'Configurazione delle notifiche push agli utenti di app mobili ""1C:Orders"".';
				|pl = 'Ustawienia synchronizacji wysyłania powiadomień push do użytkowników aplikacji mobilnej ""1C:Orders"".';
				|tr = '""1C:Orders"" mobil uygulamasının kullanıcılarına anlık bildirim gönderiminin ayarlanması.'");
	If Not ValueIsFilled(Object.Ref) Then
		MasterNode = ExchangePlans.MobileApplicationSalesOrders.MainExchangeNode();
		ValueToFormAttribute(MasterNode.GetObject(), "Object");
	EndIf;
	CertificateStorage = Common.ObjectAttributeValue(Object.Ref, "IOSMobileApplicationCertificate");
	If CertificateStorage <> Undefined Then
		Certificate = CertificateStorage.Get();
		CertificateIsLoaded = ValueIsFilled(Certificate);
	Else
		CertificateIsLoaded = False;
	EndIf;
	UsePushNotificationsOnChangeAtServer();
	SetAvailability();
EndProcedure

&AtServer
Procedure SetAvailability()
	
	Items.ApplicationNumber.Enabled = Object.UseGCM;
	Items.SenderKey.Enabled = Object.UseGCM;
	Items.ImportCertificate.Enabled = Object.UseAPNS;
EndProcedure

#EndRegion
