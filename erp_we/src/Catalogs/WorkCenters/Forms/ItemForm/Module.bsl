
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		
		If Parameters.FillingValues.Property("Department", Department)
			And Not Department.IsEmpty() Then
			ConfigureByDivision();
		Else
			FillInTheDepartment();
		EndIf;
		
		OnReadCreateAtServer();
		
	EndIf;
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Object.ProductionArea.IsEmpty() And Not ReadOnly Then
		// Subsystem prohibiting editing of key details of objects
		ObjectAttributesLockClient.SetFormItemEnabled(
			ThisObject,
			CommonClientServer.ValueInArray("ProductionArea"));
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_WorkCenters");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FillInTheDepartment();
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServer
Procedure OnReadCreateAtServer()
	
	SetVisibilityOfLoadingDetails();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	ConfigureByDivision();
	
EndProcedure

&AtClient
Procedure WorkCenterTypeOnChange(Item)
	
	ViewOfWorkCenterWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure ViewOfWorkCenterWhenChangingOnServer()
	
	If Department.IsEmpty() Then
		
		FillInTheDepartment();
		
	EndIf;
	
	SetVisibilityOfLoadingDetails();
	
EndProcedure

&AtClient
Procedure ProductionAreaOnChange(Item)
	
	If Department.IsEmpty() Then
		
		FillInTheDepartment();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#Region StandardSubsystems

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

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetVisibilityOfLoadingDetails()
	
	ParallelLoad = False;
	
	If Not Object.WorkCenterType.IsEmpty() Then
		
		ParallelLoad = Common.ObjectAttributeValue(
			Object.WorkCenterType,
			"ParallelLoad");
		
	EndIf;
	
	Items.MaximumLoad.Visible = ParallelLoad;
	Items.WorkCenterTypeUnitOfMeasureOfLoad.Visible = ParallelLoad;
	
EndProcedure

&AtServer
Procedure FillInTheDepartment()
	
	If Object.WorkCenterType.IsEmpty() And Object.ProductionArea.IsEmpty() Then
		
		Department = Undefined;
		
	Else
		
		Department = ?(Object.ProductionArea.IsEmpty(),
			Common.ObjectAttributeValue(Object.WorkCenterType, "Department"),
			Common.ObjectAttributeValue(Object.ProductionArea, "Owner"));
		
	EndIf;
	
	ConfigureByDivision();
	
EndProcedure

&AtServer
Procedure ConfigureByDivision()
	
	If Department.IsEmpty() Then
		
		SetFormFunctionalOptionParameters(New Structure("Department", Undefined));
		
		Items.WorkCenterType.ChoiceParameterLinks = New FixedArray(New Array);
		
		Items.ProductionArea.ChoiceParameterLinks = New FixedArray(New Array);
		
	Else
		
		SetFormFunctionalOptionParameters(New Structure("Department", Department));
		
		Links = CommonClientServer.ValueInArray(
			New ChoiceParameterLink("Filter.Department", "Department"));
		Items.WorkCenterType.ChoiceParameterLinks = New FixedArray(Links);
		
		Links = CommonClientServer.ValueInArray(
			New ChoiceParameterLink("Filter.Owner", "Department"));
		Items.ProductionArea.ChoiceParameterLinks = New FixedArray(Links);
		
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion
