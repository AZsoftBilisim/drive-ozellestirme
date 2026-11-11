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
	
	CanAddFromClassifier = True;
	If Not AccessRight("Insert", Metadata.Catalogs.BusinessCalendars) Then
		CanAddFromClassifier = False;
	Else
		If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
			CanAddFromClassifier = False;
		EndIf;
	EndIf;
	
	Items.FormPickFromClassifier.Visible = CanAddFromClassifier;
	If Not CanAddFromClassifier Then
		CommonClientServer.SetFormItemProperty(Items, "CreateCalendar", "Title", NStr("vi = 'Tạo mới';
																						|ru = 'Создать';
																						|en = 'Create'; fa = 'ایجاد';
																						|it = 'Creare';
																						|pl = 'Create';
																						|tr = 'Oluştur'"));
		Items.Create.Type = FormGroupType.ButtonGroup;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(Items, "CreateCalendar", "Representation", ButtonRepresentation.Text);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	Items.List.Refresh();
	Items.List.CurrentRow = SelectionResult;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PickFromClassifier(Command)
	
	PickingFormName = "DataProcessor.FillCalendarSchedules.Form.PickCalendarsFromClassifier";
	OpenForm(PickingFormName, , ThisObject);
	
EndProcedure

#EndRegion
