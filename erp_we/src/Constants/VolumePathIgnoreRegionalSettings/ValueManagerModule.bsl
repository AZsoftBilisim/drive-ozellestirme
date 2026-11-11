///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers
		
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	PreviousValue = 	Constants.VolumePathIgnoreRegionalSettings.Get();
	
	If PreviousValue <> Value 
			And FilesOperationsInVolumesInternal.HasFileStorageVolumes() Then
		
		Common.MessageToUser(
			NStr("vi = 'Cấm thay đổi phương thức tạo đường dẫn đến quyển. Đang có các tệp trong quyển.';
				|ru = 'Изменение способа формирования пути к тому запрещено. Есть файлы в томах.';
				|en = 'Changing a method of the volume path generation is restricted. There are files in volumes.'; fa = 'Changing a method of the volume path generation is restricted. There are files in volumes.';
				|it = 'La modifica del metodo di formazione del percorso ad esso non è consentita. Vi sono file nei volumi.';
				|pl = 'Zmiana sposobu utworzenia ścieżki do woluminu jest zabroniona. Są pliki w woluminach.';
				|tr = 'Birim yolunun oluşturulma şekli değiştirilemez. Klasörlerde dosyalar var.'"),
			,,,Cancel);
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf