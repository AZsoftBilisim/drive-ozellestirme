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
	
	ReadOnly = True;
	
	Storage = FormAttributeToValue("Record").NotificationContent;
	Items.PageContent.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nội dung (dung lượng, byte: %1)';
			|ru = 'Содержимое (размер, байт: %1)';
			|en = 'Content (size, bytes: %1)'; fa = 'Content (size, bytes: %1)';
			|it = 'Содержимое (размер, байт: %1)';
			|pl = 'Content (size, bytes: %1)';
			|tr = 'İçerik (boyut, bayt:%1)'"),
		String(Base64Value(XMLString(Storage)).Size()));
	
	StorageContents = Storage.Get();
	Try
		NotificationContent = Common.ValueToXMLString(StorageContents);
	Except
		NotificationContent = ValueToStringInternal(StorageContents);
	EndTry;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

#EndRegion
