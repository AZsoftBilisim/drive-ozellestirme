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
	
	File = Parameters.FileRef;
	VersionComment = Parameters.VersionComment;
	CreateNewVersion = Parameters.CreateNewVersion;
	
	If Common.ObjectAttributeValue(File, "StoreVersions") Then
		CreateNewVersion = True;
		Items.CreateNewVersion.Enabled = Parameters.CreateNewVersionAvailability;
		If Not Parameters.CreateNewVersionAvailability Then
			Items.CreateNewVersion.ToolTip = NStr("vi = 'Tác giả tệp đã đặt tùy chỉnh lưu phiên bản tệp đính kèm và không thể thay đổi.';
													|ru = 'Настройка сохранения версии присоединенного файла задана его автором и не может быть изменена.';
													|en = 'Settings for saving the attached file version are specified by its author and cannot be changed.'; fa = 'Settings for saving the attached file version are specified by its author and cannot be changed.';
													|it = 'Impostazione di salvataggio della versione del file allegato indicata dal proprio autore e non può essere modificata.';
													|pl = 'Konfiguracja zapisu wersji załączonego pliku jest zadany przez jego autora i nie może być zmieniona.';
													|tr = 'Eklenmiş dosya versiyonunun kaydetme yapılandırması yazan tarafından yapılmıştır ve değiştirilemez.'");
			Items.CreateNewVersion.ToolTipRepresentation = ToolTipRepresentation.Button;
		EndIf;
	Else
		CreateNewVersion = False;
		Items.CreateNewVersion.Enabled = False;
		Items.CreateNewVersion.ToolTip = NStr("vi = 'Đã vô hiệu hóa các phiên bản đối với tệp đính kèm này.';
												|ru = 'Версии для этого присоединенного файла отключены.';
												|en = 'Versions for this attachment are disabled.'; fa = 'Versions for this attachment are disabled.';
												|it = 'Le versioni per questo file allegato sono annullate.';
												|pl = 'Wersje dla tego załączonego pliku są wyłączone.';
												|tr = 'Bu eklenmiş dosyanın versiyonları etkisizleştirilmiştir.'");
		Items.CreateNewVersion.ToolTipRepresentation = ToolTipRepresentation.Button;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	ReturnStructure = New Structure("VersionComment, CreateNewVersion, ReturnCode",
		VersionComment, CreateNewVersion, DialogReturnCode.OK);
	
	Close(ReturnStructure);
	
	Notify("FilesOperationsNewFileVersionSaved");
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ReturnStructure = New Structure("VersionComment, CreateNewVersion, ReturnCode",
		VersionComment, CreateNewVersion, DialogReturnCode.Cancel);
	
	Close(ReturnStructure);
	
EndProcedure

#EndRegion