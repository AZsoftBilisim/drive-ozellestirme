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
	
	SetPropertiesTypes = PropertyManagerInternal.SetPropertiesTypes(Object.Ref);
	UseAddlAttributes = SetPropertiesTypes.AdditionalAttributes;
	UseAddlInfo  = SetPropertiesTypes.AdditionalInfo;
	
	If UseAddlAttributes And UseAddlInfo Then
		Title = Object.Description + " " + NStr("vi = '(Nhóm tập hợp mục tin và thông tin bổ sung)';
												|ru = '(Группа наборов дополнительных реквизитов и сведений)';
												|en = '(Group of additional attribute and information record sets)'; fa = '(Group of additional attribute and information record sets)';
												|it = '(Gruppo degli insiemi di informazioni e requisiti aggiuntivi)';
												|pl = '(Grupa zestawów atrybutów dodatkowych i informacji)';
												|tr = '(Ek öznitelikler ve bilgi kümeleri grubu)'")
		
	ElsIf UseAddlAttributes Then
		Title = Object.Description + " " + NStr("vi = '(Nhóm tập hợp mục tin bổ sung)';
												|ru = '(Группа наборов дополнительных реквизитов)';
												|en = '(Group of additional attribute sets)'; fa = '(Group of additional attribute sets)';
												|it = '(Gruppo degli insiemi di requisiti aggiuntivi)';
												|pl = '(Grupa zestawów atrybutów dodatkowych)';
												|tr = '(Ek öznitelikler grubu)'")
		
	ElsIf UseAddlInfo Then
		Title = Object.Description + " " + NStr("vi = '(Nhóm tập hợp thông tin bổ sung)';
												|ru = '(Группа наборов дополнительных сведений)';
												|en = '(Group of additional information records sets)'; fa = '(Group of additional information records sets)';
												|it = '(Gruppo degli insiemi di informazioni aggiuntive)';
												|pl = '(Grupa zestawów informacji dodatkowych)';
												|tr = '(Ek bilgi grubu)'")
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion
