
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
    PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

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
	
	OnReadCreateAtServer();
	
	If Not Object.ContainsNestedRoute Then
		// The details may be different when changing the type of operation
		Object.ContainsNestedRoute = True;
		Modified = True;
	EndIf; 
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NestedRouteOnChange(Item)
	
	If ValueIsFilled(Object.NestedRoute) And Not ValueIsFilled(Object.Description) Then
		Object.Description = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.NestedRoute, "Presentation");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
    PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not Object.Owner.IsEmpty() Then
		
		DetailsOfOwner = Common.ObjectAttributesValues(Object.Owner, "Status,Department");
		
		OwnerStatus    = DetailsOfOwner.Status;
		FilterDepartment = DetailsOfOwner.Department;
		
	EndIf;
	
	SetAvailabilityOfItemsByStatusServer();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	If Not Object.Owner.IsEmpty() Then
		AttributeAvailability = (OwnerStatus <> Enums.StatusesOfRouteSheets.Valid
								And OwnerStatus <> Enums.StatusesOfRouteSheets.Closed_
								And Not ReadOnly);
								
	Else
		AttributeAvailability = False;
	EndIf;
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("OperationNumber");
	ItemArray.Add("NextOperation");
	ItemArray.Add("Count");
	ItemArray.Add("UnitOfMeasure");
	ItemArray.Add("NestedRoute");
	ItemArray.Add("Owner");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", Not AttributeAvailability)
	
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
// End StandardSubsystems.Properties

#EndRegion
