///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Checks whether infobase configuration update in the subordinate node is required.
//
Procedure CheckSubordinateNodeConfigurationUpdateRequired() Export
	
	UpdateRequired = StandardSubsystemsClient.ClientRunParameters().DIBNodeConfigurationUpdateRequired;
	CheckUpdateRequired(UpdateRequired);
	
EndProcedure

// Checks whether infobase configuration update in the subordinate node is required. The check is performed on application startup.
//
Procedure CheckSubordinateNodeConfigurationUpdateRequiredOnStart() Export
	
	UpdateRequired = StandardSubsystemsClient.ClientParametersOnStart().DIBNodeConfigurationUpdateRequired;
	CheckUpdateRequired(UpdateRequired);
	
EndProcedure

Procedure CheckUpdateRequired(DIBNodeConfigurationUpdateRequired)
	
	If DIBNodeConfigurationUpdateRequired Then
		Explanation = NStr("vi = 'Đã nhận bản cập nhật chương trình từ ""%1"".
			|Hãy cài đặt bản cập nhật chương trình, sau đó sẽ tiếp tục đồng bộ dữ liệu.';
			|ru = 'Получено обновление программы из ""%1"".
			|Установите обновление программы, после чего синхронизация данных будет продолжена.';
			|en = 'The application update is received from ""%1"".
			|Install the update to continue the synchronization.'; fa = 'The application update is received from ""%1"".
			|Install the update to continue the synchronization.';
			|it = 'Aggiornamento del programma ricevuto da ""%1"".
			|Impostare l''aggiornamento del programma, dopo proseguirà la sincronizzazione dati.';
			|pl = 'Pobrano aktualizację programu z ""%1"".
			|Zainstaluj aktualizację programu, po czym synchronizacja danych zostanie kontynuowana.';
			|tr = 'Bu uygulamanın güncellemesi ""%1""dan alınmaktadır.
			|Veri senkronizasyonuna devam etmek için güncellemeyi kurun.'");
		Explanation = StringFunctionsClientServer.SubstituteParametersToString(Explanation, StandardSubsystemsClient.ClientRunParameters().MasterNode);
		ShowUserNotification(NStr("vi = 'Cài đặt bản cập nhật';
									|ru = 'Установить обновление';
									|en = 'Install update'; fa = 'نصب به‌روزرسانی';
									|it = 'Installare l''aggiornamento';
									|pl = 'Zainstaluj aktualizację';
									|tr = 'Güncellemeyi ayarla'"), "e1cib/app/DataProcessor.DataExchangeExecution",
			Explanation, PictureLib.Warning32);
		Notify("DataExchangeCompleted");
	EndIf;
	
	AttachIdleHandler("CheckSubordinateNodeConfigurationUpdateRequired", 60 * 60, True); // Once an hour.
	
EndProcedure

#EndRegion
