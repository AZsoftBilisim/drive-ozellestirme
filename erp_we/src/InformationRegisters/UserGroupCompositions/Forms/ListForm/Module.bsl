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
	
	ShowMessageBox(, DataUpdateResult());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DataUpdateResult()
	
	TemplateUpdated = NStr("vi = '%1: Đã cập nhật thành công.';
							|ru = '%1: Обновление выполнено успешно.';
							|en = '%1: Updated successfully.'; fa = '%1: Updated successfully.';
							|it = '%1: Обновление выполнено успешно.';
							|pl = '%1: Updated successfully.';
							|tr = '%1: Güncelleme başarılı.'");
	TemplateNoUpdateRequired = NStr("vi = '%1: Không cần cập nhật.';
									|ru = '%1: Обновление не требуется.';
									|en = '%1: No update required.'; fa = '%1: No update required.';
									|it = '%1: Обновление не требуется.';
									|pl = '%1: No update required.';
									|tr = '%1: Güncelleme gerekmiyor.'");
	
	HasHierarchyChanges = False;
	HasChangesInComposition = False;
	
	InformationRegisters.UserGroupCompositions.UpdateHierarchyAndComposition(HasHierarchyChanges,
		HasChangesInComposition);
	
	Result = New Array;
	Result.Add(StringFunctionsClientServer.SubstituteParametersToString(
		?(HasHierarchyChanges, TemplateUpdated, TemplateNoUpdateRequired),
		Metadata.InformationRegisters.UserGroupsHierarchy.Presentation()));
	
	Result.Add(StringFunctionsClientServer.SubstituteParametersToString(
		?(HasChangesInComposition, TemplateUpdated, TemplateNoUpdateRequired),
		Metadata.InformationRegisters.UserGroupCompositions.Presentation()));
	
	Items.List.Refresh();
	
	Return StrConcat(Result, Chars.LF);
	
EndFunction

#EndRegion
