#Region Public

Procedure NotifyAboutEnd() Export
	
	NewEntries = ExchangeMobileOfflineServer.NewEntriesAcceptedSent();
	If NewEntries.Accepted <> 0 Or NewEntries.Sent <> 0 Then
		NotifyChanged(Type("CatalogRef.PackagesAndUnitsOfMeasure"));
		NotifyChanged(Type("CatalogRef.Products"));
		RefreshInterface();
		ShowUserNotification(NStr("vi = 'Đã thực hiện đồng bộ';
									|ru = 'Выполнена синхронизация';
									|en = 'Synchronization is completed'; fa = 'Synchronization is completed';
									|it = 'Выполнена синхронизация';
									|pl = 'Synchronization is completed';
									|tr = 'Senkronizasyon gerçekleştirildi'"), ,
			StrTemplate(NStr("vi = 'Đã nhận đối tượng: %1. Đã gửi đối tượng: %2.';
							|ru = 'Принято объектов: %1. Отправлено объектов: %2.';
							|en = 'Objects received: %1. Objects sent: %2.'; fa = 'Objects received: %1. Objects sent: %2.';
							|it = 'Принято объектов: %1. Отправлено объектов: %2.';
							|pl = 'Objects received: %1. Objects sent: %2.';
							|tr = 'Alınan nesneler: %1. Gönderilen nesneler: %2.'"), NewEntries.Accepted, NewEntries.Sent));
	EndIf

EndProcedure

#If MobileClient Then

// The procedure starts data exchange with an offline configuration
// and connects a wait handler for regular synchronization
Procedure EnableSharing() Export
	
	If ExchangeMobilePCCall.RequiresDataExchangeWithStandaloneApplication(ExchangeMobileOfflineClient.CurrentNode()) Then
		If MainServerAvailable() = True Then
			ExchangeMobileOfflineClient.StartExchange();
		EndIf;
		AttachIdleHandler("CheckingNeedForSynchronization", 10);
	EndIf;
	
EndProcedure

// The procedure disables the wait handler that performs data synchronization between the main configuration and the offline one
Procedure DisableSharing() Export
	
	DetachIdleHandler("CheckingNeedForSynchronization");
	
EndProcedure

#EndIf

#EndRegion