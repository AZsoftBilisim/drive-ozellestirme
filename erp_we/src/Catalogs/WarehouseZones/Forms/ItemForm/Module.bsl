
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	WeightUnit   = Constants.UnitOfMeasureForWeight.Get();
	VolumeUnit = Constants.UnitOfMeasureForVolume.Get();
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

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
Procedure OwnerOnChange(Item)
	OwnerOfRoomWhenServerChanges();	
EndProcedure

&AtClient
Procedure LimitByVolumeOnChange(Item)
	Items.LimitationByVolume.Enabled = Object.LimitByVolume;
	Object.LimitationByVolume               = 0;
EndProcedure

&AtClient
Procedure LimitByWeightOnChange(Item)
	Items.LimitationByWeight.Enabled = Object.LimitByWeight;
	Object.LimitationByWeight               = 0;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	If Not Object.Ref.IsEmpty() Then
		Result = Undefined;

		OpenForm("Catalog.WarehouseZones.Form.AttributeUnlocking",,,,,, New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
    EndIf;

EndProcedure

&AtClient
Procedure ShowHideOnlineHelp(Command)
	
	ShowHideBuiltInHelpOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure OwnerOfRoomWhenServerChanges()
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Owner, Object.Premise);

	SetFormFunctionalOptionParameters(New Structure("Warehouse",Object.Owner));
	
	SetVisibility1();
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	// Get the values of the functional options.
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Owner, Object.Premise);
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse",Object.Owner));
	
	Items.LimitationByVolume.Enabled = Object.LimitByVolume;
	Items.LimitationByWeight.Enabled = Object.LimitByWeight;
	
	// Indicates whether the built-in help is displayed.
	DisplayOnlineHelp = True;
	
	FormSettings = Common.CommonSettingsStorageLoad("Workspaces_ElementForm_FormSettings", "");
	
	If Not (FormSettings = Undefined) Then
		
		If FormSettings.Property("DisplayOnlineHelp") Then
			DisplayOnlineHelp = FormSettings.DisplayOnlineHelp;
		EndIf;
		
	EndIf;
	
	Items.FormShowHideOnlineHelp.Check = DisplayOnlineHelp;
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	// The order of processing the warehouse task.
	Items.HowWarehouseTasksAreProcessed.Visible = UseBinLocationWarehousing;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"LimitByWeight,LimitByVolume,LimitationByWeight,LimitationByVolume,WeightUnit,VolumeUnit",
		"Visible", UseBinLocationWarehousing);
	
	// Visibility of the built-in help elements.
	BuiltInHelpElements = BuiltInHelpElements();
	
	For Each HelpElement In BuiltInHelpElements Do
		Items[HelpElement.TagName].Visible = HelpElement.Visible;
	EndDo;
	
EndProcedure

&AtServer
Procedure ShowHideBuiltInHelpOnServer()
	
	Items.FormShowHideOnlineHelp.Check = Not Items.FormShowHideOnlineHelp.Check;
	DisplayOnlineHelp = Items.FormShowHideOnlineHelp.Check;
	
	SetVisibility1();
	SaveFormSettingsOnServer();
	
EndProcedure

// Returns:
// 	Array of Structure - Contains:
// 		* TagName - String - 
// 		* Visible - Boolean - 
&AtServer
Function BuiltInHelpElements()
	
	Result = New Array;
	
	Result.Add(New Structure("TagName, Visible", 
		"LabelHintForTheOrderInWhichTheWarehouseTaskIsProcessed", DisplayOnlineHelp And UseBinLocationWarehousing));
	
	Return Result;
	
EndFunction

&AtServer
Procedure SaveFormSettingsOnServer()
	
	FormSettings = New Structure;
	FormSettings.Insert("DisplayOnlineHelp", DisplayOnlineHelp);
	
	CommonServerCall.CommonSettingsStorageSave("Workspaces_ElementForm_FormSettings", "",
		FormSettings);
	
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

&AtClient
Procedure PremiseOnChange(Item)
	OwnerOfRoomWhenServerChanges();
EndProcedure

#EndRegion

#EndRegion
