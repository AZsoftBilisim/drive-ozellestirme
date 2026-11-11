#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
		
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Object.LimitByWeight And Object.LimitByVolume Then
		LimitByWeightVolume = "WeightAndVolume";
	ElsIf Object.LimitByWeight Then
		LimitByWeightVolume = "Weight";
	ElsIf Object.LimitByVolume Then
		LimitByWeightVolume = "VolumeM3";
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If PhysicallyDifferentFromTheDestinationString = "PhysicallyDifferentFromAssignment" Then
		CurrentObject.PhysicallyDifferentFromAssignment = True;
	Else
		CurrentObject.PhysicallyDifferentFromAssignment = False;
	EndIf;
	
	If LimitByWeightVolume = "WeightAndVolume" Then
		CurrentObject.LimitByWeight = True;
		CurrentObject.LimitByVolume = True;
	ElsIf LimitByWeightVolume = "Weight" Then
		CurrentObject.LimitByWeight = True;
		CurrentObject.LimitByVolume = False;
	ElsIf LimitByWeightVolume = "VolumeM3" Then
		CurrentObject.LimitByWeight = False;
		CurrentObject.LimitByVolume = True;
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ItemsTypeOnChange(Item)
	
	FlagManagementIsPhysicallyDifferentFromAssignment();
	
EndProcedure

&AtClient
Procedure LimitByWeightVolumeOnChange(Item)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.WarehouseGroupsOfItems.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
    EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
		
	FlagManagementIsPhysicallyDifferentFromAssignment();
	
EndProcedure

&AtServer
Procedure FlagManagementIsPhysicallyDifferentFromAssignment()
	
	If GetFunctionalOption("UseOrderSupplyWithAssignment")
		And Object.ItemsType = Enums.ItemsTypes.OwnGoods Then
		Items.TheGroupIsPhysicallyDifferentFromTheDestination.Visible = True;
		If Object.PhysicallyDifferentFromAssignment Then
			PhysicallyDifferentFromTheDestinationString = "PhysicallyDifferentFromAssignment";
		Else
			PhysicallyDifferentFromTheDestinationString = "NotPhysicallyDifferentFromAssignment";
		EndIf;
	Else
		Items.TheGroupIsPhysicallyDifferentFromTheDestination.Visible = False;
		PhysicallyDifferentFromTheDestinationString = "NotPhysicallyDifferentFromAssignment";
		Object.PhysicallyDifferentFromAssignment = False;
	EndIf;
	
EndProcedure

#EndRegion
