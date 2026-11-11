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
	
	If ValueIsFilled(Parameters.LanguageCode) Then
		Items.DefaultPrintForm.Enabled = (Parameters.LanguageCode = Common.DefaultLanguageCode());
	EndIf;
	
	GroupVisibility = PrintManagement.IsIncludedInObjectsWithDefaultPrintForms(TypeOf(Parameters.LayoutOwner));
	Items.GroupDefaultPrintForm.Visible = GroupVisibility;
	
	If GroupVisibility Then
		RefTemplate = Catalogs.PrintFormTemplates.RefTemplate(Parameters.IdentifierOfTemplate);
		
		If ValueIsFilled(RefTemplate) Then
			AttributesNames = "Description,DefaultPrintForm,PrintFormDescription";
			TemplateData1 = Common.ObjectAttributesValues(RefTemplate, AttributesNames);
			
			TemplateDescr        = TemplateData1.Description;
			DefaultPrintForm     = TemplateData1.DefaultPrintForm;
			PrintFormDescription = TemplateData1.PrintFormDescription;
		Else
			TemplateDescr = Parameters.TemplateDescr;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("OnConfirmClosing", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,, WarningText);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateFormDisplay();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TemplateDescrOnChange(Item)
	UpdateFormDisplay();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	SaveAndLoad();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OnConfirmClosing(Result = Undefined, AdditionalParameters = Undefined) Export
	SaveAndLoad();
EndProcedure

&AtClient
Procedure SaveAndLoad()
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("DocumentName", TemplateDescr);
	ParametersStructure.Insert("DefaultPrintForm", DefaultPrintForm);
	ParametersStructure.Insert("PrintFormDescription", PrintFormDescription);
	
	Close(ParametersStructure);
	
EndProcedure

&AtClient
Procedure UpdateFormDisplay()
	Items.PrintFormDescription.InputHint = TemplateDescr;
EndProcedure
#EndRegion
