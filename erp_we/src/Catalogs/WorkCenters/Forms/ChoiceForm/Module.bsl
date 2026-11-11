
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") Then 
		
		If Parameters.Filter.Property("Department") Then
			
			CommonClientServer.SetDynamicListFilterItem(
					List,
					"WorkCenterType.Department",
					Parameters.Filter.Department);
			
			SetFormFunctionalOptionParameters(New Structure("Department",
				Parameters.Filter.Department));
			
			Parameters.Filter.Delete("Department");
			
		ElsIf Parameters.Filter.Property("WorkCenterType") Then
			
			SetFormFunctionalOptionParameters(New Structure("Department",
				Common.ObjectAttributeValue(Parameters.Filter.WorkCenterType, "Department")));
			
		EndIf;

		If Parameters.Filter.Property("ProductionArea") Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "ProductionArea", Parameters.Filter.ProductionArea);
		EndIf;
		
	EndIf;
	
	If Parameters.Property("ChooseSetupOption") Then
		ChooseSetupOption = Parameters.ChooseSetupOption;
	Else
		ChooseSetupOption = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	If ChooseSetupOption And SetupSettingsAreUsed(Item.CurrentData.WorkCenterType) Then
		
		StandardProcessing = False;
		
		Filter_Settings = New Structure;
		Filter_Settings.Insert("Owner", Item.CurrentData.WorkCenterType);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", Filter_Settings);
		
		AddlParameters = New Structure("WorkCenter", Value);
		
		OpenForm("Catalog.SetupOptions.ChoiceForm",
			FormParameters,
			FormOwner,
			,
			,
			,
			New CallbackDescription("ListValueChoiceCompletion", ThisObject, AddlParameters));
	
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ListValueChoiceCompletion(SetupSettings, AddlParameters) Export
	If SetupSettings = Undefined Then
		Close(Undefined);
	Else
		Close(New Structure("WorkCenter, SetupSettings", AddlParameters.WorkCenter, SetupSettings));
	EndIf;
EndProcedure

// Parameters:
//  WorkCenterType - CatalogRef.WorkCenterTypes
// 
// Returns:
//  Boolean
&AtServerNoContext
Function SetupSettingsAreUsed(WorkCenterType)
	Return Common.ObjectAttributeValue(WorkCenterType, "SetupSettingsAreUsed");
EndFunction

#EndRegion