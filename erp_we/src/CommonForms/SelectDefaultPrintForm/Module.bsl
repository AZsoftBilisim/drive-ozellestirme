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
	
	If TypeOf(Parameters.PrintCommands) <> Type("Array") Then
		Cancel = True;
		Return;
	EndIf;
	
	CommandsIDs = InformationRegisters.DefaultObjectPrintForms.CommandsIDs(Parameters.ObjectsArray);
	StoredID = "";
	CommandsIDsCount = CommandsIDs.Count();
	If CommandsIDsCount = 1 Then
		For Each KeyValue In CommandsIDs Do
			StoredID = KeyValue.Key;
			SavedPresentation = PrintManagement.DescriptionOfGeneratedDefaultPrintForm(KeyValue.Value[0]);
		EndDo;
	EndIf;
	
	ProcessSetIDs();
	
	Cnt = 0;
	
	For Each Command In Parameters.PrintCommands Do
		Cnt = Cnt + 1;
		If Command.DefaultPrintForm Then
			Items.DefaultPrintForm.ChoiceList.Add(Cnt, Command.Presentation, False);
			If PrintManagementClientServer.IDWithoutSpecialChars(Command.Id) = StoredID Then
				DefaultPrintForm = Cnt;
				SavedPresentation = Command.Presentation;
			EndIf;
		EndIf;
	EndDo;
	
	TitleText = "";
	If CommandsIDsCount = 1 Then
		TextTemplate1 = NStr("vi = 'Mẫu in chính được lưu: %1.';
							|ru = 'Сохраненная основная печатная форма: %1.';
							|en = 'Saved default print form: %1.'; fa = 'Saved default print form: %1.';
							|it = 'Saved default print form: %1.';
							|pl = 'Saved default print form: %1.';
							|tr = 'Kaydedilen ana yazdırma formu: %1.'");
		TitleText = StrTemplate(TextTemplate1, SavedPresentation);
	EndIf;
	
	If Not IsBlankString(TitleText) Then
		Items.DecorationNoteToSelectedPrintForms.Visible = True;
		Items.DecorationNoteToSelectedPrintForms.Title = TitleText;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesToExclude = New Array;
	AttributesToExclude.Add("DefaultPrintForm");
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesToExclude);
	
	If Not ValueIsFilled(DefaultPrintForm) Then
		Common.MessageToUser(NStr("vi = 'Chưa chọn mẫu in chính';
									|ru = 'Не выбрана основная печатная форма';
									|en = 'Default print form is not selected'; fa = 'Default print form is not selected';
									|it = 'Default print form is not selected';
									|pl = 'Default print form is not selected';
									|tr = 'Ana yazdırma formu seçilmedi'"), , "DefaultPrintForm");
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAndGenerate(Command)
	
	ClearMessages();

	If CheckFilling() Then
		Close(DefaultPrintForm - 1);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessSetIDs()
	
	For Each Command In Parameters.PrintCommands Do
		If StrFind(Command.Id, ",") Then
			Command.Id = StrSplit(Command.Id, ",", False)[0];
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
