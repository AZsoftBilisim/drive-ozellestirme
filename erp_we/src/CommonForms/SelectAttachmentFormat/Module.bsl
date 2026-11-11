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
	
	// Import passed parameters.
	PassedFormatArray = New Array;
	If Parameters.SaveFormats <> Undefined Then
		PassedFormatArray = Parameters.SaveFormats;
	EndIf;
	PackToArchive = Parameters.PackToArchive;
	TransliterateFilesNames = Parameters.TransliterateFilesNames;
	Items.Sign.Visible = Parameters.Sign <> Undefined;
	Sign = Parameters.Sign;
	
	// Populate format list.
	For Each SaveFormat In StandardSubsystemsServer.SpreadsheetDocumentSaveFormatsSettings() Do
		Check = False;
		If Parameters.SaveFormats <> Undefined Then 
			PassedFormat = PassedFormatArray.Find(String(SaveFormat.SpreadsheetDocumentFileType));
			If PassedFormat <> Undefined Then
				Check = True;
			EndIf;
		EndIf;
		
		SelectedSaveFormats.Add(String(SaveFormat.SpreadsheetDocumentFileType), 
			SaveFormat.Presentation, Check, SaveFormat.Picture);
	EndDo;
	
	If SelectedSaveFormats.Count() = 1 Then
		Items.FormatsSelectionGroup.Visible = False;
		AutoTitle = False;
		Title = NStr("vi = 'Chọn tham số đính kèm';
					|ru = 'Выбор параметров вложений';
					|en = 'Select attachment parameters'; fa = 'Select attachment parameters';
					|it = 'Выбор параметров вложений';
					|pl = 'Select attachment parameters';
					|tr = 'İç içe parametre seçimi'");
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "WithoutChoosingFormat");
	ElsIf SelectedSaveFormats.Count() > 1 Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "");
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.Sign.Visible = False;
	EndIf;

EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	If Parameters.SaveFormats <> Undefined And Parameters.SaveFormats.Count() > 0 Then
		Settings.Delete("SelectedSaveFormats");
		Settings.Delete("PackToArchive");
		Settings.Delete("TransliterateFilesNames");
		Settings.Delete("Sign");
		Return;
	EndIf;
	
	If SelectedSaveFormats.Count() <> 1 Then
		SaveFormatsFromSettings = Settings["SelectedSaveFormats"];
		If SaveFormatsFromSettings <> Undefined Then
			For Each SelectedFormat In SelectedSaveFormats Do 
				FormatFromSettings = SaveFormatsFromSettings.FindByValue(SelectedFormat.Value);
				SelectedFormat.Check = FormatFromSettings <> Undefined And FormatFromSettings.Check;
			EndDo;
			Settings.Delete("SelectedSaveFormats");
		EndIf;
	Else
		Settings.Delete("SelectedSaveFormats");
	EndIf;
	
	If Common.IsMobileClient() Then
		Settings["Sign"] = False;
	EndIf;

EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	If SelectedSaveFormats.Count() = 1 Then
		Settings.Delete("SelectedSaveFormats");
	EndIf;
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	SetFormatSelection();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	SelectionResult = SelectedFormatSettings();
	NotifyChoice(SelectionResult);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFormatSelection()
	
	HasSelectedFormat = False;
	For Each SelectedFormat In SelectedSaveFormats Do
		If SelectedFormat.Check Then
			HasSelectedFormat = True;
		EndIf;
	EndDo;
	
	If Not HasSelectedFormat Then
		SelectedSaveFormats[0].Check = True; // The default choice is the first in the list.
	EndIf;
	
EndProcedure

&AtClient
Function SelectedFormatSettings()
	
	SaveFormats = New Array;
	
	For Each SelectedFormat In SelectedSaveFormats Do
		If SelectedFormat.Check Then
			SaveFormats.Add(SelectedFormat.Value);
		EndIf;
	EndDo;	
	
	Result = New Structure;
	Result.Insert("PackToArchive", PackToArchive);
	Result.Insert("SaveFormats", SaveFormats);
	Result.Insert("TransliterateFilesNames", TransliterateFilesNames);
	Result.Insert("Sign", Sign);
	
	Return Result;
	
EndFunction

#EndRegion
