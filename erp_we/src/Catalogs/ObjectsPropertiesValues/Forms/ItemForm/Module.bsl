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
	
	If Not ValueIsFilled(Object.Ref)
	   And Parameters.FillingValues.Property("Description") Then
		
		Object.Description = Parameters.FillingValues.Description;
	EndIf;
	
	If Not Parameters.HideOwner Then
		Items.Owner.Visible = True;
	EndIf;
	
	If TypeOf(Parameters.ShowWeight) = Type("Boolean") Then
		ShowWeight = Parameters.ShowWeight;
	Else
		ShowWeight = Common.ObjectAttributeValue(Object.Owner, "AdditionalValuesWithWeight");
	EndIf;
	
	If ShowWeight = True Then
		Items.Weight.Visible = True;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ValuesWithWeight");
	Else
		Items.Weight.Visible = False;
		Object.Weight = 0;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ValuesWithoutWeight");
	EndIf;
	
	SetHeader();
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangeValueIsCharacterizedByWeightCoefficient"
	   And Source = Object.Owner Then
		
		If Parameter = True Then
			Items.Weight.Visible = True;
		Else
			Items.Weight.Visible = False;
			Object.Weight = 0;
		EndIf;
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
	
	SetHeader();
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ObjectsPropertiesValues",
		New Structure("Ref", Object.Ref), Object.Ref);
	
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

#Region Private

&AtServer
Procedure SetHeader()
	
	AttributesValues = Common.ObjectAttributesValues(
		Object.Owner, "Title, ValueFormTitle",,  CurrentLanguage().LanguageCode);
	
	PropertyName = TrimAll(AttributesValues.ValueFormTitle);
	
	If Not IsBlankString(PropertyName) Then
		If ValueIsFilled(Object.Ref) Then
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																					|ru = '%1 (%2)';
																					|en = '%1 (%2)'; fa = '%1 (%2)';
																					|it = '%1 (%2)';
																					|pl = '%1 (%2)';
																					|tr = '%1 (%2)'"),
				Object.Description,
				PropertyName);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (Tạo mới)';
																					|ru = '%1 (Создание)';
																					|en = '%1 (Create)'; fa = '%1 (Create)';
																					|it = '%1 (creazione)';
																					|pl = '%1 (utworzenie)';
																					|tr = '%1 (Oluştur)'"), PropertyName);
		EndIf;
	Else
		PropertyName = String(AttributesValues.Title);
		
		If ValueIsFilled(Object.Ref) Then
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (Giá trị thuộc tính %2)';
																					|ru = '%1 (Значение свойства %2)';
																					|en = '%1 (""%2"" property value)'; fa = '%1 (""%2"" property value)';
																					|it = '%1 (Valore della proprietà %2)';
																					|pl = '%1 (Znaczenie właściwości %2)';
																					|tr = '%1 (özniteliğin değeri %2)'"),
				Object.Description,
				PropertyName);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Giá trị thuộc tính %1 (Tạo mới)';
																					|ru = 'Значение свойства %1 (Создание)';
																					|en = '""%1"" property value (Create)'; fa = '""%1"" property value (Create)';
																					|it = 'Valore della proprietà %1 (Creazione)';
																					|pl = 'Znaczenie właściwości %1 (Tworzenie)';
																					|tr = '%1 özellik değeri (Oluştur)'"), PropertyName);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
