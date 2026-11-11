// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)
	
	Notify("Write_Vehicle_",, Object.Ref);
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CodeOnChange(Item)
	
	GenerateName();
	
EndProcedure

&AtClient
Procedure BrandOnChange(Item)
	
	GenerateName();
	
EndProcedure

&AtClient
Procedure TypeOnChange(Item)
	
	If Not ValueIsFilled(Object.Type) Then
		Return;
	EndIf;
	
	TypeOnChangeServer(Object.Type);
	
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

#Region Private

#Region Other

&AtClient
Procedure GenerateName()
	
	Object.Description = TrimAll(Object.Code) + " " + TrimAll(Object.Brand);
	
EndProcedure

&AtServer
Procedure TypeOnChangeServer(VehicleType_1)
	
	AttributesStructure1 = Common.ObjectAttributesValues(
		VehicleType_1, "CapacityInCubicMeters, CarryingCapacityInTons");
	FillPropertyValues(Object, AttributesStructure1);
	
EndProcedure

#EndRegion

#EndRegion
