
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AllowEditingIsPhysicallyDifferentFromTheDestination = True;

	ConfigurationModificationOverridable.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	
	If AllowEditingIsPhysicallyDifferentFromTheDestination Then
		Result.Add("PhysicallyDifferentFromAssignment");
	EndIf;
	
	Close(Result);

EndProcedure

#EndRegion
