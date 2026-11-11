///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

// Mandatory form parameters:
//
// ObjectToMap - String - Object details in the current app.
// Application1 - String - Name of the peer app.
// Application2 - String - Name of the current app.
//
// UsedFieldsList - ValueList - Fields to be used for mapping.
//     Value - String - Field name. 
//     Presentation - String - Field header.
//     Check - Boolean - Flag indicating whether the field is being used.
//
// MaxUserFields - Number - Mapped field threshold.
//
// StartRowSerialNumber - Number - Current row key in the input table.
//
// TempStorageAddress - String - Address of the input mapping table. Columns are:
//     PictureIndex - Number
//     IndexNumber - Number - Row's unique key.
//     OrderField1 - String - Value of the attribute #1 in the used fields list.
//     …
//     OrderFieldNN - String - Value of the attribute #NN in the used fields list.
//
// After the form opens, data at the address "TempStorageAddress" is deleted from the temporary storage.
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("ObjectToMap") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	ObjectToMap = Parameters.ObjectToMap;
	
	Items.ObjectToMap.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đối tượng trong ""%1""';
			|ru = 'Объект в ""%1""';
			|en = 'Object in ""%1""'; fa = 'Object in ""%1""';
			|it = 'Oggetto in ""%1""';
			|pl = 'Obiekt w ""%1""';
			|tr = '""%1"" ''deki nesne'"), Parameters.Application1);
		
	Items.Header.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đối tượng trong ""%1""';
			|ru = 'Объект в ""%1""';
			|en = 'Object in ""%1""'; fa = 'Object in ""%1""';
			|it = 'Oggetto in ""%1""';
			|pl = 'Obiekt w ""%1""';
			|tr = '""%1"" ''deki nesne'"), Parameters.Application2);
	
	// Setting up choice table on the form.
	GenerateChoiceTable(Parameters.MaxUserFields, Parameters.UsedFieldsList, 
		Parameters.TempStorageAddress);
		
	SetChoiceTableCursor(Parameters.StartRowSerialNumber);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersChoiceTable

&AtClient
Procedure ChoiceTableSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	MakeChoice(RowSelected);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	MakeChoice(Items.ChoiceTable.CurrentRow);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure MakeChoice(Val SelectionRowID)
	If SelectionRowID=Undefined Then
		Return;
	EndIf;
		
	ChoiceData = ChoiceTable.FindByID(SelectionRowID);
	If ChoiceData<>Undefined Then
		NotifyChoice(ChoiceData.SerialNumber);
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateChoiceTable(Val FieldsTotal, Val UsedFields, Val DataAddress)
	
	// Adding attribute columns.
	ItemsToAdd = New Array;
	StringType   = New TypeDescription("String");
	For FieldNumber=1 To FieldsTotal Do
		ItemsToAdd.Add(New FormAttribute("SortField" + Format(FieldNumber, "NZ=; NG="), StringType, "ChoiceTable"));
	EndDo;
	ChangeAttributes(ItemsToAdd);
	
	// Add it on form.
	ColumnGroup = Items.FieldsGrouping;
	ElementType   = Type("FormField");
	ListSize  = UsedFields.Count() - 1;
	
	For FieldNumber=0 To FieldsTotal-1 Do
		Attribute = ItemsToAdd[FieldNumber];
		
		NewColumn = Items.Add("ChoiceTable" + Attribute.Name, ElementType, ColumnGroup);
		NewColumn.DataPath = Attribute.Path + "." + Attribute.Name;
		If FieldNumber<=ListSize Then
			Field = UsedFields[FieldNumber];
			NewColumn.Visible = Field.Check;
			NewColumn.Title = Field.Presentation;
		Else
			NewColumn.Visible = False;
		EndIf;
	EndDo;
	
	// Filling the selection table and clearing data in the temporary storage.
	If Not IsBlankString(DataAddress) Then
		ChoiceTable.Load( GetFromTempStorage(DataAddress) );
		DeleteFromTempStorage(DataAddress);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetChoiceTableCursor(Val StartRowSerialNumber)
	
	For Each String In ChoiceTable Do
		If String.SerialNumber=StartRowSerialNumber Then
			Items.ChoiceTable.CurrentRow = String.GetID();
			Break;
			
		ElsIf String.SerialNumber>StartRowSerialNumber Then
			PreviousRowIndex = ChoiceTable.IndexOf(String) - 1;
			If PreviousRowIndex>0 Then
				Items.ChoiceTable.CurrentRow = ChoiceTable[PreviousRowIndex].GetID();
			EndIf;
			Break;
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
