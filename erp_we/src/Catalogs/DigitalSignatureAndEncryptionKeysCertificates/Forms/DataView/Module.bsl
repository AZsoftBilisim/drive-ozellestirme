///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var ListDataPresentations;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.DataPresentation;
	
	For Each Presentation In Parameters.ListDataPresentations Do
		List.Add().Presentation = Presentation;
	EndDo;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenData();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure SetPresentationList(PresentationsList, Context) Export
	
	ListDataPresentations = PresentationsList;
	
	Context = New CallbackDescription("SetPresentationList", ThisObject, Context);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ListOpen(Command)
	
	OpenData();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenData()
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	String = List.FindByID(Items.List.CurrentRow);
	If String = Undefined Then
		Return;
	EndIf;
	IndexOf = List.IndexOf(String);
	
	Value = ListDataPresentations[IndexOf].Value;
	
	If TypeOf(Value) = Type("CallbackDescription") Then
		RunCallback(Value);
	Else
		ShowValue(, Value);
	EndIf;
	
EndProcedure

#EndRegion