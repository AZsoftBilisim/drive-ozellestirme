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
	
	FillObjectsTypesList();
	
	If Not IsBlankString(Parameters.SelectedTypes) Then
		SelectedTypes = StrSplit(Parameters.SelectedTypes, ",", True);
		For Each Selected_2Type In SelectedTypes Do
			Found3Type = EditableObjects.FindByValue(Selected_2Type);
			If Found3Type <> Undefined Then
				EditableObjects.FindByValue(Selected_2Type).Check = True;
				Items.EditableObjects.CurrentRow = Found3Type.GetID();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEditableObjects

&AtClient
Procedure EditableObjectsOnChange(Item)
	UpdateSelectedCount();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	SelectObjectsAndCloseForm();
EndProcedure

&AtClient
Procedure EditableObjectsSelection(Item, RowSelected, Field, StandardProcessing)
	SelectObjectsAndCloseForm();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillObjectsTypesList()
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.FillEditableObjectsCollection(EditableObjects, Parameters.ShowHiddenItems);
EndProcedure

// Parameters:
//   ParentSubsystem - MetadataObjectSubsystem 
// Returns:
//   Map
//
&AtServerNoContext
Function SubordinateSubsystemsNames(ParentSubsystem)
	
	Names = New Map;
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		Names.Insert(CurrentSubsystem.Name, True);
		SubordinatesNames = SubordinateSubsystemsNames(CurrentSubsystem);
		
		For Each SubordinateFormName In SubordinatesNames Do
			Names.Insert(CurrentSubsystem.Name + "." + SubordinateFormName.Key, True);
		EndDo;
	EndDo;
	
	Return Names;
	
EndFunction

&AtClient
Function SelectedItems()
	Result = New Array;
	For Each Item In EditableObjects Do
		If Item.Check Then
			Result.Add(Item.Value);
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtClient
Procedure SelectObjectsAndCloseForm()
	SelectedItems = SelectedItems();
	If SelectedItems.Count() = 0 Then
		SelectedItems.Add(Items.EditableObjects.CurrentData.Value);
	EndIf;
	Close(SelectedItems);
EndProcedure

&AtClient
Procedure UpdateSelectedCount()
	SelectButtonText = NStr("vi = 'Chọn';
							|ru = 'Выбрать';
							|en = 'Select'; fa = 'انتخاب';
							|it = 'Selezionare';
							|pl = 'Wybierz';
							|tr = 'Seç'");
	SelectedCount = SelectedItems().Count();
	If SelectedCount > 0 Then
		SelectButtonText = SelectButtonText + " (" + SelectedCount + ")";
	EndIf;
	Items.FormSelect.Title = SelectButtonText;
EndProcedure

#EndRegion
