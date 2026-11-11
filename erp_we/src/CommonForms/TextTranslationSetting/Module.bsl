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
	
	If Common.IsMobileClient() Then
		Items.WriteAndClose.Representation = ButtonRepresentation.Picture;
	EndIf;
	
	Items.ContextModeTitle.Visible = Parameters.IsContextCall;
	
	If Parameters.IsContextCall Then
		Items.WriteAndClose.Title = NStr("vi = 'Ghi lại và tiếp tục';
										|ru = 'Записать и продолжить';
										|en = 'Save and continue'; fa = 'Save and continue';
										|it = 'Registrare e continuare';
										|pl = 'Zapisz i kontynuuj';
										|tr = 'Kaydet ve devam et'");
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.UseTextTranslationService = ValueIsFilled(CurrentObject.TextTranslationService);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Owner = Common.MetadataObjectID("Constant.TextTranslationService");
	
	SetPrivilegedMode(True);
	For Each Parameter In AuthorizationParameters Do
		If Parameter.Presentation <> String(UUID) Then
			Common.WriteDataToSecureStorage(Owner, Parameter.Presentation, Parameter.Value);
		EndIf;
	EndDo;
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Not ValueIsFilled(ConstantsSet.TextTranslationService) Then
	
		TextTranslationService = Undefined;
		TextTranslationToolLocalization.OnDefineTranslationService(TextTranslationService);
		
		ConstantsSet.TextTranslationService = ?(ValueIsFilled(TextTranslationService),
			TextTranslationService, Enums.TextTranslationServices.GoogleTranslate);
	EndIf;
	
	FillSettings();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WrittenValues = New Structure;
	WrittenValues.Insert("TextTranslationService", ConstantsSet.TextTranslationService);
	
	Notify("Write_ConstantsSet", WrittenValues, "UseTextTranslationService");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TextTranslationServiceOnChange(Item)
	
	FillSettings();
	
EndProcedure

&AtClient
Procedure Attachable_AuthorizationParameterChangeOfEditingText(Item, Text, StandardProcessing)
	Item.ChoiceButton = True;
EndProcedure

// Parameters:
//  Item - FormField
//
&AtClient
Procedure Attachable_AuthorizationParameterStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	IndexOf = AuthorizationParameters.IndexOf(AuthorizationParameters.FindByValue(Item.Name));
	SwitchPasswordMode(Item, AuthorizationParameters[IndexOf].Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	Write();
	Close(ConstantsSet.TextTranslationService);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSettings()
	
	TextTranslationService = ConstantsSet.TextTranslationService;
	
	For Each Parameter In AuthorizationParameters Do
		Items.Delete(Items[Parameter.Value]);
	EndDo;
	AuthorizationParameters.Clear();
	
	Items.Instruction.Title = "";
	
	SetPrivilegedMode(True);
	
	AuthorizationSettings = TextTranslationTool.AuthorizationSettings(TextTranslationService);
	If AuthorizationSettings = Undefined Then
		Return;
	EndIf;
	
	TextTranslationServiceSettings = TextTranslationTool.TextTranslationServiceSettings(TextTranslationService);
	Items.Instruction.Title = TextTranslationServiceSettings.ConnectionInstructions;
	
	For IndexOf = 0 To TextTranslationServiceSettings.AuthorizationParameters.Count() - 1  Do
		ParameterDetails = TextTranslationServiceSettings.AuthorizationParameters[IndexOf];
		ParameterValue = AuthorizationSettings[ParameterDetails.Name];
		AuthorizationParameters.Add(ParameterDetails.Name, ?(ValueIsFilled(ParameterValue), UUID, ""));
		
		InputField = Items.Add(ParameterDetails.Name, Type("FormField"), Items.AuthorizationParameters);
		InputField.Type = FormFieldType.InputField;
		InputField.Title = ParameterDetails.Presentation;
		InputField.DataPath = "AuthorizationParameters[" + IndexOf + "].Presentation";
		InputField.ToolTipRepresentation = ParameterDetails.ToolTipRepresentation;
		InputField.ExtendedTooltip.Title = ParameterDetails.ToolTip;
		InputField.SetAction("StartChoice", "Attachable_AuthorizationParameterStartOfSelection");
		InputField.SetAction("EditTextChange", "Attachable_AuthorizationParameterChangeOfEditingText");
		InputField.PasswordMode = True;
		InputField.ChoiceButton = Not ValueIsFilled(ParameterValue);
		InputField.ChoiceButtonPicture = PictureLib.CharsBeingTypedShown;
	EndDo;
	
EndProcedure

&AtClient
Procedure SwitchPasswordMode(Item, Attribute, StandardProcessing)
	
	StandardProcessing = False;
	Attribute = Item.EditText;
	Item.PasswordMode = Not Item.PasswordMode;
	If Item.PasswordMode Then
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedShown;
	Else
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedHidden;
	EndIf;
	
EndProcedure

#EndRegion

