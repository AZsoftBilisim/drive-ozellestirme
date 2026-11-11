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
	UseLabels        = SetPropertiesTypes.Labels;
	
	If UseAddlInfo And Not UseAddlAttributes And Not UseLabels Then
		Title = Object.Description + " " + NStr("vi = '(Tập hợp các thông tin bổ sung)';
												|ru = '(Набор дополнительных сведений)';
												|en = '(Set of additional information records)'; fa = '(Set of additional information records)';
												|it = '(Insieme di informazioni aggiuntive)';
												|pl = '(Zestaw informacji dodatkowych)';
												|tr = '(Ek bilgi kümesi)'")
	ElsIf UseLabels And Not UseAddlInfo And Not UseAddlAttributes Then
		Title = Object.Description + " " + NStr("vi = '(Tập hợp nhãn đánh dấu)';
												|ru = '(Набор меток)';
												|en = '(Label set)'; fa = '(Label set)';
												|it = '(Набор меток)';
												|pl = '(Label set)';
												|tr = '(Etiket kümesi)'")
	ElsIf UseAddlAttributes And Not UseAddlInfo And Not UseLabels Then
		Title = Object.Description + " " + NStr("vi = '(Tập hợp các mục tin bổ sung)';
												|ru = '(Набор дополнительных реквизитов)';
												|en = '(Set of additional attributes)'; fa = '(Set of additional attributes)';
												|it = '(Insieme di requisiti aggiuntivi)';
												|pl = '(Zestaw atrybutów dodatkowych)';
												|tr = '(Ek öznitelikler kümesi)'")
	Else
		Title = Object.Description + " " + NStr("vi = '(Tập hợp thuộc tính bổ sung)';
												|ru = '(Набор дополнительных свойств)';
												|en = '(Set of additional properties)'; fa = '(Set of additional properties)';
												|it = '(Набор дополнительных свойств)';
												|pl = '(Set of additional properties)';
												|tr = '(Ek özellik kümesi)'")
	EndIf;
	
	If Not UseAddlAttributes And Object.AdditionalAttributes.Count() = 0 Then
		Items.AdditionalAttributes.Visible = False;
	EndIf;
	
	If Not UseAddlInfo And Object.AdditionalInfo.Count() = 0 Then
		Items.AdditionalInfo.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
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
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClient = CommonClient.CommonModule("NationalLanguageSupportClient");
		ModuleNationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	EndIf;
	
EndProcedure

#EndRegion
