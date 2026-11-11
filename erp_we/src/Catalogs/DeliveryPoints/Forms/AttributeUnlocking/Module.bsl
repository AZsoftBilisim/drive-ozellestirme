//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Object") Then
		
		DeliveryPoint = Parameters.Object;
		MainDeliveryPoint = Common.ObjectAttributeValue(DeliveryPoint, "MainPoint");
		
	Else
		
		ExceptionText = NStr("ru = 'Форма не предназначена для непосредственного открытия';
							|vi = 'Form is not intended for direct opening';
							|en = 'Form is not intended for direct opening'; fa = 'Form is not intended for direct opening';
							|it = 'Form is not intended for direct opening';
							|pl = 'Form is not intended for direct opening';
							|tr = 'Form doğrudan açılmak için tasarlanmamıştır'");
		Raise ExceptionText;
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AdjustElementVisibility();
	ConfigureAvailabilityOfCheckboxes();
	EditCheckboxes(True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	MatchingBankDetails = New Map;
	MatchingBankDetails.Insert("AllowEditingOwner", "Owner");
	MatchingBankDetails.Insert("AllowEditingAddress", "Address");
	MatchingBankDetails.Insert("AllowEditingDeliveryZone", "DeliveryZone");
	
	
	Result = New Array; // Array of String
	For Each KeyValue In MatchingBankDetails Do
		
		If ThisObject[KeyValue.Key] = True Then
			
			Result.Add(KeyValue.Value);
			
		EndIf;
		
	EndDo;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure CheckIfUsed(Command)
	
	Notification = New CallbackDescription("CheckIfUsedCompletion", ThisObject);
	TimeConsumingOperation = CheckUsageATServer();
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Notification);
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	EditCheckboxes(True);
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	EditCheckboxes(False);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConfigureAvailabilityOfCheckboxes()
	
	If MainDeliveryPoint Then
		
		ItemArray = New Array; // Array of String
		ItemArray.Add(Items.AllowEditingOwner.Name);
		ItemArray.Add(Items.AllowEditingAddress.Name);
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EditCheckboxes(Value)
	
	AllowEditingDeliveryZone = Value;
	
	If Not MainDeliveryPoint Then
		
		AllowEditingOwner = Value;
		AllowEditingAddress = Value;
		
	EndIf;
	
	
EndProcedure

&AtServer
Function CheckUsageATServer()
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"GoodsDelivery.PointIsUsedWhenPlanningDelivery",
		DeliveryPoint);
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure CheckIfUsedCompletion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult = Undefined Then
		
		Return;
		
	EndIf;
	
	If ExecutionResult.Status = "Completed2" Then
		
		DotIsUsed = GetFromTempStorage(ExecutionResult.ResultAddress); // Boolean
		AdjustElementVisibility(DotIsUsed);
		
	ElsIf ExecutionResult.Status = "Error" Then 
		
		CommonClient.MessageToUser(
			ExecutionResult.BriefErrorDescription,
			,
			"CheckIfUsed");
		
		AdjustElementVisibility();
		
	EndIf;
	
EndProcedure

// Parameters:
//  DeliveryPointIsUsed - Boolean
//
&AtClient
Procedure AdjustElementVisibility(DeliveryPointIsUsed = Undefined)
	
	ArrayOfAllElements = New Array; // Array of String
	ArrayOfAllElements.Add(Items.DecorationObjectUsed.Name);
	ArrayOfAllElements.Add(Items.DecorationObjectNotUsed.Name);
	ArrayOfAllElements.Add(Items.DecorationRecommendation.Name);
	
	ArrayOfVisible = New Array; // Array of String
	
	If DeliveryPointIsUsed = Undefined Then
		
		ArrayOfVisible.Add(Items.DecorationRecommendation.Name);
		
	ElsIf DeliveryPointIsUsed Then
		
		ArrayOfVisible.Add(Items.DecorationObjectUsed.Name);
		
	Else
		
		ArrayOfVisible.Add(Items.DecorationObjectNotUsed.Name);
		
	EndIf;
	
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Items, ArrayOfAllElements, ArrayOfVisible);
	
EndProcedure

#EndRegion
