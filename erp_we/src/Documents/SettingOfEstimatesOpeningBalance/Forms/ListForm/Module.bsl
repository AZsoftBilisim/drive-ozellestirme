
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BudgetIndicatorSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "BudgetBalanceItem",
		BudgetBalanceItem, DataCompositionComparisonType.Equal, , ValueIsFilled(BudgetBalanceItem));
	
EndProcedure

&AtClient
Procedure DateOfBalanceSelectionClearing(Item, StandardProcessing)
	
	CommonClientServer.SetDynamicListFilterItem(List, "DateOfRemainingGoods",
		DateOfRemainingGoods, DataCompositionComparisonType.Equal, , False);
	
EndProcedure

&AtClient
Procedure DateOfBalanceSelectionStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("DateOfRemainingGoodsStartChoiceCompletion", ThisObject);
	FormParameters = New Structure("Value, PeriodSelectionMode", DateOfRemainingGoods, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection", FormParameters, ThisObject, UUID, , ,
		CloseHandler, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DateOfRemainingGoodsStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	DateOfRemainingGoods = BegOfMonth(SelectedPeriod);
	PresentationOfBalanceDate = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(DateOfRemainingGoods);
	
	CommonClientServer.SetDynamicListFilterItem(List, "DateOfRemainingGoods",
		DateOfRemainingGoods, DataCompositionComparisonType.Equal, , True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion