#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ThereIsModelInParameters = False;
	ParameterValue = Undefined;
	If Parameters.Property("Filter", ParameterValue) Then
		If ParameterValue.Property("Owner", ParameterValue) Then
			ThereIsModelInParameters = True;
		EndIf;
	EndIf;
	
	If ThereIsModelInParameters Then
		BudgetingModel = ParameterValue;
	Else
		BudgetingModel = DefaultBudgetingModel();
	EndIf;
	
	Items.BudgetingModel.Visible = Not ThereIsModelInParameters;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Owner", BudgetingModel,,, ValueIsFilled(BudgetingModel));
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BudgetingModelOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Owner", BudgetingModel,,, ValueIsFilled(BudgetingModel));
	RecordSelectedBudgetingModel(BudgetingModel);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)

	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function DefaultBudgetingModel()
	
	BudgetingModel = FormDataSettingsStorage.Load("Catalog.BudgetProfiles.Form.ChoiceForm", "BudgetingModel");
	If BudgetingModel = Undefined Then
		BudgetingModel = Catalogs.BudgetingModels.EmptyRef();
	EndIf;
	Return BudgetingModel;
	
EndFunction

&AtServerNoContext
Procedure RecordSelectedBudgetingModel(Model)
	FormDataSettingsStorage.Save("Catalog.BudgetProfiles.Form.ChoiceForm", "BudgetingModel", Model);
EndProcedure

#EndRegion

