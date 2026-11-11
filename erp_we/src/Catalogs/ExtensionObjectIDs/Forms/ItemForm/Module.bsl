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
	
	Catalogs.MetadataObjectIDs.ItemFormOnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	Items.FormEnableEditing.Enabled = False;
	
EndProcedure

&AtClient
Procedure FullNameOnChange(Item)
	
	FullName = Object.FullName;
	UpdateIDProperties();
	
	If FullName <> Object.FullName Then
		Object.FullName = FullName;
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy đối tượng metadata theo tên đầy đủ:
			           |%1.';
			           |ru = 'Объект метаданных не найден по полному имени:
			           |%1.';
			           |en = 'Metadata object is not found by full name:
			           |%1.'; fa = 'Metadata object is not found by full name:
			           |%1.';
			           |it = 'Oggetto dei metadati non trovato per nome completo: 
			           |%1.';
			           |pl = 'Obiekt metadanych nie został znlaleziony wg pełnej nazwy:
			           |%1.';
			           |tr = 'Meta veri nesnesi tam adı ile bulunamadı: 
			           |%1'"),
			FullName));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateIDProperties()
	
	Catalogs.MetadataObjectIDs.UpdateIDProperties(Object);
	
EndProcedure

#EndRegion
