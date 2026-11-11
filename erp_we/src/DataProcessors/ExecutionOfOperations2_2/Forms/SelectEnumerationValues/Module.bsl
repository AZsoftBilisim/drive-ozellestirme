#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	EnumerationParameter = Undefined;
	Parameters.Property("Enum", EnumerationParameter);
	
	MetadataObject = Metadata.FindByType(EnumerationParameter);
	Title = MetadataObject.Synonym;
	
	AvailableValues = Undefined;
	If Not Parameters.Property("AvailableValues", AvailableValues) Or Not ValueIsFilled(AvailableValues) Then
		AvailableValues = Enums[MetadataObject.Name];
	EndIf;
	
	For Each Value In AvailableValues Do
		List.Add(Value);
	EndDo;
		
	SelectedValues = Undefined;
	If Parameters.Property("SelectedValues", SelectedValues) And ValueIsFilled(SelectedValues) Then
		For Each Item In List Do
			If SelectedValues.Find(Item.Value) <> Undefined Then
				Item.Check = True;
			EndIf;
		EndDo;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Result = New Array;
	For Each Item In List Do
		If Item.Check Then
			Result.Add(Item.Value);
		EndIf;
	EndDo;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion