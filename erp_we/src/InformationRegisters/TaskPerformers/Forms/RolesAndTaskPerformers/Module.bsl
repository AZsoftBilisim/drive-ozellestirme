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
	
	MainAddressingObject = Parameters.MainAddressingObject;
	RefreshItemsData();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "WriteRoleAddressing" Then
		RefreshItemsData();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	AssignPerformers(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	AssignPerformers(Undefined);
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AllAssignmentsExecute(Command)
	
	FilterValue = New Structure("MainAddressingObject", MainAddressingObject);
	FormParameters = New Structure("Filter", FilterValue);
	OpenForm("InformationRegister.TaskPerformers.ListForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure RefreshExecute(Command)
	RefreshItemsData();
EndProcedure

&AtClient
Procedure AssignPerformers(Command)
	
	Purpose = Items.List.CurrentData;
	If Purpose = Undefined Then
		ShowMessageBox(,NStr("vi = 'Hãy chọn vai trò trong danh sách.';
							|ru = 'Выберите роль в списке.';
							|en = 'Select a role in the list.'; fa = 'Select a role in the list.';
							|it = 'Selezionare ruolo nell''elenco.';
							|pl = 'Wybierz rolę na liście.';
							|tr = 'Listede rolü seçin'"));
		Return;
	EndIf;
	
	OpenForm("InformationRegister.TaskPerformers.Form.PerformersOfRoleWithAddressingObject", 
		New Structure("MainAddressingObject,Role", 
			MainAddressingObject, 
			Purpose.RoleRef));
			
EndProcedure

&AtClient
Procedure RolesList(Command)
	OpenForm("Catalog.PerformerRoles.ListForm",,ThisObject);
EndProcedure

&AtClient
Procedure OpenRoleInfo(Command)
	
	If Items.List.CurrentData = Undefined Then
		Return;	
	EndIf;
	
	ShowValue(, Items.List.CurrentData.RoleRef);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RefreshItemsData()
	
	QuerySelection = BusinessProcessesAndTasksServer.SelectRolesWithPerformerCount(MainAddressingObject);
	ListObject = FormAttributeToValue("List");
	ListObject.Clear();
	While QuerySelection.Next() Do
		ValueType = QuerySelection.MainAddressingObjectTypes.ValueType;
		IncludedType = True;
		If MainAddressingObject <> Undefined Then
			IncludedType = ValueType <> Undefined And ValueType.ContainsType(TypeOf(MainAddressingObject));
		EndIf;
		If IncludedType Then
			NewRow = ListObject.Add();
			FillPropertyValues(NewRow, QuerySelection, "Assignees,Role,RoleRef,ExternalRole"); 
		EndIf;
	EndDo;
	ListObject.Sort("Role");
	For Each ListLine In ListObject Do
		If ListLine.Assignees = 0 Then
			ListLine.PerformersString = ?(ListLine.ExternalRole, NStr("vi = 'đã xác định trong ứng dụng khác';
																		|ru = 'заданы в другом приложении';
																		|en = 'specified in another app'; fa = 'specified in another app';
																		|it = 'заданы в другом приложении';
																		|pl = 'specified in another app';
																		|tr = 'başka bir uygulamada ayarla'"), NStr("vi = 'chưa xác định';
																												|ru = 'не заданы';
																												|en = 'not specified'; fa = 'مشخص نشده';
																												|it = 'non impostati';
																												|pl = 'nie ustawione';
																												|tr = 'belirtilmedi'"));
			ListLine.Picture = ?(ListLine.ExternalRole, -1, 1);
		ElsIf ListLine.Assignees = 1 Then
			ListLine.PerformersString = String(BusinessProcessesAndTasksServer.SelectPerformer(MainAddressingObject, ListLine.RoleRef));
			ListLine.Picture = -1;
		Else
			ListLine.PerformersString = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 người';
																										|ru = '%1 чел';
																										|en = '%1 users'; fa = '%1 users';
																										|it = '%1';
																										|pl = '%1 os';
																										|tr = '%1 kişi'"), String(ListLine.Assignees) );
			ListLine.Picture = -1;
		EndIf;
	EndDo;
	ValueToFormAttribute(ListObject, "List");
	
EndProcedure

#EndRegion
