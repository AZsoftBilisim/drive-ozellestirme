///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var CloseProgrammatically;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Timeout = Parameters.Timeout;
	QueryText = Parameters.QueryText;
	Title = Parameters.Title;
	ListOfCommands = Parameters.ListOfCommands;
	
	If IsBlankString(Title) Then
		Title = NStr("vi = 'Câu hỏi';
					|ru = 'Вопрос';
					|en = 'Question'; fa = 'پرسش';
					|it = 'Domanda';
					|pl = 'Pytanie';
					|tr = 'Soru'");
	EndIf;
	
	If ValueIsFilled(Parameters.ConfirmationHeader) Then
		Items.ConfirmationMode.Title = Parameters.ConfirmationHeader;
	Else
		Items.ConfirmationMode.Visible = False;
	EndIf;
	
	PrepareQuestionForm(QueryText);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CloseProgrammatically = False;
	AttachIdleHandler("Attachable_ChangeSizeOfForm", 0.2, True);
	
	If ValueIsFilled(Timeout) Then
		AttachIdleHandler("Attachable_CloseForm", Timeout, True);
	EndIf;	
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CloseProgrammatically Then
		Cancel = True;
		CloseForm(DialogReturnCode.Cancel);
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
										
&AtClient
Procedure ConfirmationOnChange(Item)
	
	For Each ListLine In ListOfCommands Do
		
		If ListLine.Check Then
			CommandElement = Items[ListLine.Value];
			CommandElement.Enabled = Confirmation;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Attachable_PressingButton(Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PrepareQuestionForm(InputText)
	
	ThereIsConfirmation = Items.ConfirmationMode.Visible;
	
	Items.InformationDecoration.Title = InputText;
	Items.PictureDecoration.Picture = GetFormResource("DialogQuestion");
	Items.OK.Visible = ListOfCommands.Count() = 0; 
	Items.PictureDecoration.Visible = Not Items.PictureDecoration.Picture.Type = PictureType.Empty;
	
	TheFirstControl = Undefined;
	
	For Counter = 1 To ListOfCommands.Count() Do
		CommandString = ListOfCommands[Counter - 1];
		CommandName = CommandString.Value;
		
		NewCommand = Commands.Add(CommandName);
		NewCommand.Action = "Attachable_PressingButton"; 
		NewCommand.Title = CommandString.Presentation;
		If ValueIsFilled(CommandString.Picture) Then
			NewCommand.Picture = CommandString.Picture;
		EndIf;
		
		NewItem = Items.Add(CommandName, Type("FormButton"), Items.CommandGroup);
		NewItem.CommandName = CommandName;
		
		If ThereIsConfirmation And CommandString.Check Then
			NewItem.Enabled = False;
		EndIf;
		
		If TheFirstControl = Undefined Or CommandString.Check Then
			TheFirstControl = NewItem;
		EndIf;
		
	EndDo;
	
	If TheFirstControl <> Undefined Then
		TheFirstControl.DefaultButton = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetFormResource(ResourceName)
	
	Result = New Picture();
	FoundResource = New Structure(ResourceName);
	
	Try
		FillPropertyValues(FoundResource, PictureLib);
	Except
	EndTry;
	
	If FoundResource[ResourceName] <> Undefined Then
		Result = FoundResource[ResourceName];
	EndIf;
		
	Return Result;  
	
EndFunction
	
&AtClient
Procedure Attachable_PressingButton(Command)
	
	CloseForm(Command.Name);
	
EndProcedure

&AtClient
Procedure Attachable_ChangeSizeOfForm()
	
	Items.CommandGroup.Visible = Not Items.CommandGroup.Visible;
	Items.DisplayGroup.Visible = Not Items.DisplayGroup.Visible;
	
	Items.CommandGroup.Visible = Not Items.CommandGroup.Visible;
	Items.DisplayGroup.Visible = Not Items.DisplayGroup.Visible;
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	CloseForm(DialogReturnCode.Timeout);
	
EndProcedure

&AtClient
Procedure CloseForm(SelectionResult = "")
	
	CloseProgrammatically = True;
	
	Close(SelectionResult);
	
EndProcedure

#EndRegion

