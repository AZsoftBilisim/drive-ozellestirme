
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	For Each AvailableType In Parameters.AvailableTypes.Types() Do
		
		TypeMetadata = Metadata.FindByType(AvailableType);
		If TypeMetadata = Undefined Then
			Continue;
		EndIf;
		
		If Not Common.MetadataObjectAvailableByFunctionalOptions(TypeMetadata) Then
			Continue;
		EndIf;
		
		AvailableTypes.Add(AvailableType);
		
	EndDo;
	
	AvailableTypes.SortByValue();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AvailableTypesSelection(Item, RowSelected, Field, StandardProcessing)
	
	Close(Items.AvailableTypes.CurrentData.Value);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(Items.AvailableTypes.CurrentData.Value);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(Undefined);
EndProcedure

#EndRegion
