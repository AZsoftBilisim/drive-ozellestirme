
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// 1- for the directory "Store formats", 2 - for the directory "Warehouses"
	Parameters.Property("FormMode", FormMode);
	
	AllowEditingInTheStoreOrderAssemblyIsSupported           = True;
	AllowEditingInTheStoreDeliveryByYourOwnCouriersIsSupported = True;
	AllowEditingOfStartDateOfDeliveryTheirCouriers              = True; 
	AllowEditingOrderBuildStartDate                        = True; 

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetVisibilityAvailability();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;

	If AllowEditingInTheStoreOrderAssemblyIsSupported Then
		Result.Add("StoreSupportsOrderAssembly");
	EndIf;
	
	If AllowEditingInTheStoreDeliveryByYourOwnCouriersIsSupported Then
		Result.Add("StoreSupportsDeliveryByOwnCouriers");
	EndIf;
	
	If FormMode = 2 Then
		If AllowEditingOfStartDateOfDeliveryTheirCouriers Then
			Result.Add("StartDateOfDeliveryByOwnCouriers");
		EndIf;
			
		If AllowEditingOrderBuildStartDate Then
			Result.Add("OrderAssemblyStartDate");
		EndIf;
	EndIf;
	
	Close(Result);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetVisibilityAvailability()
	
	FormItem = Items.Find("AllowEditingGroupOrderBuildStartDate");
	If FormItem <> Undefined Then
		FormItem.Visible = (FormMode = 2);
	EndIf;
	
	FormItem = Items.Find("GroupAllowEditingOfStartDateOfDeliveryTheirCouriers");
	If FormItem <> Undefined Then
		FormItem.Visible = (FormMode = 2);
	EndIf;
	
	UseDeliveryManagement = GetFunctionalOption("UseDeliveryManagement");
	
	FormItem = Items.Find("GroupDeliveryByCouriers");
	If FormItem <> Undefined Then
		FormItem.Visible = UseDeliveryManagement;
	EndIf;
	
EndProcedure

#EndRegion
