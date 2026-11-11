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
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure UpdateRegisterData(Command)
	
	HasChanges = False;
	
	UpdateRegisterDataAtServer(HasChanges);
	
	If HasChanges Then
		Text = NStr("vi = 'Đã cập nhật thành công.';
					|ru = 'Обновление выполнено успешно.';
					|en = 'Updated successfully.'; fa = 'Updated successfully.';
					|it = 'Aggiornamento effettuato con successo.';
					|pl = 'Aktualizacja zakończona powodzeniem.';
					|tr = 'Güncelleme başarılı.'");
	Else
		Text = NStr("vi = 'Không cần cập nhật.';
					|ru = 'Обновление не требуется.';
					|en = 'No update required.'; fa = 'No update required.';
					|it = 'Aggiornamento non richiesto.';
					|pl = 'Aktualizacja nie jest konieczna.';
					|tr = 'Güncelleme gerekmiyor.'");
	EndIf;
	
	ShowMessageBox(, Text);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateRegisterDataAtServer(HasChanges)
	
	SetPrivilegedMode(True);
	
	InformationRegisters.AccessGroupsValues.UpdateRegisterData(, HasChanges);
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
