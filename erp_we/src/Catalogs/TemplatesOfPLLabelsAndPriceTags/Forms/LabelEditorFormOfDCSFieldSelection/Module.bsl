
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
    If Parameters.Property("AutoTest_2") Then
        Return;
    EndIf;
	
	If Parameters.Property("DCSStorageAddress") Then
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Parameters.DCSStorageAddress));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAvailableFields

&AtClient
Procedure AvailableFieldsSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectDCSField(RowSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectField(Command)
	
	CurrentRow = Items.AvailableFields.CurrentRow;
	
	If CurrentRow <> Undefined Then
		SelectDCSField(CurrentRow);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectDCSField(RowSelected)
	
	DCSField = String(SettingsComposer.Settings.OrderAvailableFields.GetObjectByID(RowSelected).Field);
	ThisObject.Close(DCSField);
	
EndProcedure

#EndRegion