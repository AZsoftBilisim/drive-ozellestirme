// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

