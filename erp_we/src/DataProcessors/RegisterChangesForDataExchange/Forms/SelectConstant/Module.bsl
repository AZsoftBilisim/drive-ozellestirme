///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers
//

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ConstantsList.Clear();
	For CurIndex = 0 To Parameters.MetadataNamesArray.UBound() Do
		String = ConstantsList.Add();
		String.AutoRecordPictureIndex = Parameters.AutoRecordsArray[CurIndex];
		String.PictureIndex                = 2;
		String.MetaFullName                 = Parameters.MetadataNamesArray[CurIndex];
		String.Description                  = Parameters.PresentationsArray[CurIndex];
	EndDo;
	
	AutoRecordTitle = NStr("vi = 'Tự động ghi nhận cho nút ""%1""';
							|ru = 'Авторегистрация для узла ""%1""';
							|en = 'Autoregistration for node %1'; fa = 'Autoregistration for node %1';
							|it = 'Registrazione automatica per il nodo ""%1""';
							|pl = 'Automatyczna rejestracja dla węzła ""%1""';
							|tr = '%1 ünitesi için otomatik hazırla'");
	
	Items.AutoRecordDecoration.Title = StrReplace(AutoRecordTitle, "%1", Parameters.ExchangeNode);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	CurParameters = SetFormParameters();
	Items.ConstantsList.CurrentRow = CurParameters.CurrentRow;
EndProcedure

&AtClient
Procedure OnReopen()
	CurParameters = SetFormParameters();
	Items.ConstantsList.CurrentRow = CurParameters.CurrentRow;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersConstantsList
//

&AtClient
Procedure ConstantsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	PerformConstantSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
//

// Selects a constant
//
&AtClient
Procedure SelectConstant(Command)
	
	PerformConstantSelection();
	
EndProcedure

#EndRegion

#Region Private
//

// Performs the selection and notifies of it.
//
&AtClient
Procedure PerformConstantSelection()
	Data = New Array;
	For Each CurrentRowItem In Items.ConstantsList.SelectedRows Do
		CurRow = ConstantsList.FindByID(CurrentRowItem);
		Data.Add(CurRow.MetaFullName);
	EndDo;
	NotifyChoice(Data);
EndProcedure	

&AtServer
Function SetFormParameters()
	Result = New Structure("CurrentRow");
	If Parameters.ChoiceInitialValue <> Undefined Then
		Result.CurrentRow = MetaNameRowID(Parameters.ChoiceInitialValue);
	EndIf;
	Return Result;
EndFunction

&AtServer
Function MetaNameRowID(FullMetadataName)
	Data = FormAttributeToValue("ConstantsList");
	CurRow = Data.Find(FullMetadataName, "MetaFullName");
	If CurRow <> Undefined Then
		Return CurRow.GetID();
	EndIf;
	Return Undefined;
EndFunction

#EndRegion
