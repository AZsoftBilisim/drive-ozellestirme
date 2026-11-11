#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Address				 	= Parameters.Address;
	BudgetingModel 	= Parameters.BudgetingModel;
	
	ActionSettings = GetFromTempStorage(Address);
	Enums.TypesOfBudgetingStepActions.RestoreActionSettings(ActionSettings, ThisObject);
	
	If Not ValueIsFilled(OperationKind) Then
		OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterIndicatorValue;
	EndIf;
	
	If OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		Items.PagesSelectionSettings.CurrentPage = Items.PageLayout;
		Attributes = GetHeaderFields(InputTemplate);
	Else
		Items.PagesSelectionSettings.CurrentPage = Items.PageDirectly;
		Attributes = GetHeaderFields(NonFinancialItem);
	EndIf;
	
	Items.Scenario.Visible		 = Attributes.ByScenarios;
	Items.Organization.Visible	 = Attributes.ByCompanies;
	Items.Department.Visible = Attributes.ByBusinessUnits;
	
	OperationKindEnterValuesFromTemplate =
		Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingUpInputWhenChanging(Item)
	
	If OperationKind = OperationKindEnterValuesFromTemplate Then
		Attributes = GetHeaderFields(InputTemplate);
		Items.PagesSelectionSettings.CurrentPage = Items.PageLayout;
	Else
		Attributes = GetHeaderFields(NonFinancialItem);
		Items.PagesSelectionSettings.CurrentPage = Items.PageDirectly;
	EndIf;
		
	Items.Organization.Visible = Attributes.ByCompanies;
	Items.Department.Visible = Attributes.ByBusinessUnits;
	Items.Scenario.Visible = Attributes.ByScenarios;
	
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

&AtServer
Function GetHeaderFields(Ref)
	
	Return Enums.TypesOfBudgetingStepActions.GetHeaderFields(Ref);
	
EndFunction

&AtServer
Function SaveSettingsAtServer()
	
	Settings = Enums.TypesOfBudgetingStepActions.ActionSettings(ThisObject);
	Return PutToTempStorage(Settings, Address);
	
EndFunction

#EndRegion
