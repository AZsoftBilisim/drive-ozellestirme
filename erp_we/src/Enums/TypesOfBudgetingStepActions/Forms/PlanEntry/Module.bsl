
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Address = Parameters.Address;
	BudgetingModel = Parameters.BudgetingModel;
	
	ActionSettings = GetFromTempStorage(Address);
	Enums.TypesOfBudgetingStepActions.RestoreActionSettings(ActionSettings, ThisObject);
	
	OptionsParameters = New Structure("BudgetingModel", BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	
	ConfigureListToSelectPlanTypes();
	SetScriptSelectionParameters(Items.Scenario, PlanType);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PlanTypeOnChange(Item)
	
	Scenario = Undefined;
	PlanProfile = Undefined;
	SetScriptSelectionParameters(Items.Scenario, PlanType);
	
EndProcedure

&AtClient
Procedure ScenarioOnChange(Item)
	
	ScenarioOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShouldSaveSettings(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Close(SaveSettingsAtServer());
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetScriptSelectionParameters(FormItem, PlanType)
	
	ChoiceParametersArray = New Array;
	
	If PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan") Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseInPurchasePlanning", True));
	ElsIf PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlan") Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseInSalesPlanning", True));
	ElsIf PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan") Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseInProductionPlanning", True));
	ElsIf PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan") Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseInAssemblyDisassemblyPlanning", True));
	ElsIf PlanType = PredefinedValue("Enum.TypesOfPlans.InventoryConsumptionPlan") Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseInPlanningOfInternalConsumption", True));
	EndIf;
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.RecordedInBudgeting", True));
	
	FormItem.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

&AtServer
Procedure ConfigureListToSelectPlanTypes()
	
	ListTypesOfPlans = Items.PlanType.ChoiceList;
	ListTypesOfPlans.Clear();
	If GetFunctionalOption("UsePurchasePlanning") Then
		ListTypesOfPlans.Add(Enums.TypesOfPlans.PurchasePlan);
	EndIf;
	If GetFunctionalOption("UseSalesPlans") Then
		ListTypesOfPlans.Add(Enums.TypesOfPlans.SalesPlan);
	EndIf;
	If GetFunctionalOption("UseSalesPlansByCategories") Then
		ListTypesOfPlans.Add(Enums.TypesOfPlans.SalesPlanByCategories);
	EndIf;
	If GetFunctionalOption("UsePlanningOfGoodsStock") Then
		ListTypesOfPlans.Add(Enums.TypesOfPlans.PlanOfGoodsStock);
	EndIf;
	If GetFunctionalOption("UseProductionPlanning") Then
		ListTypesOfPlans.Add(Enums.TypesOfPlans.ProductionPlan);
	EndIf;
	If GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
		ListTypesOfPlans.Add(Enums.TypesOfPlans.AssemblyDisassemblyPlan);
	EndIf;
	If GetFunctionalOption("UsePlanningOfInventoryConsumption") Then
		ListTypesOfPlans.Add(Enums.TypesOfPlans.InventoryConsumptionPlan);
	EndIf;
	
	If Not ValueIsFilled(PlanType) And ListTypesOfPlans.Count() = 1 Then
		PlanType = ListTypesOfPlans[0].Value;
	EndIf;
	
EndProcedure

&AtServer
Procedure ScenarioOnChangeServer()
	
	PlanProfile = Planning.GetDefaultPlanView(PlanType, Scenario);
	
EndProcedure

&AtServer
Function SaveSettingsAtServer()
	
	Settings = Enums.TypesOfBudgetingStepActions.ActionSettings(ThisObject);
	Return PutToTempStorage(Settings, Address);
	
EndFunction

#EndRegion
