
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetAvailabilityOfPrintCommands(Items);
	SetAvailabilityOfOrderCommands(Items);
	
	// StandardSubsystems.AttachableCommands
	TypesList = StructureOfTargetsList.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.GroupsPrefix = "StructureOfTargetsList";
	PlacementParameters.CommandBar = Items.StructureOfTargetsListCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	TypesList = AnalysisOptionsList.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.GroupsPrefix = "AnalysisOptionsList";
	PlacementParameters.CommandBar = Items.AnalysisOptionsListCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStructureOfTargetsList

&AtClient
Procedure StructureOfTargetsListOnActivateRow(Item)
	
	UpdateFormContentWhenGoalIsActivated();
	
	SetAvailabilityOfPrintCommands(Items);
	SetAvailabilityOfOrderCommands(Items);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAnalysisOptionsList

&AtClient
Procedure AnalysisOptionsListOnActivateRow(Item)
	
	SetAvailabilityOfPrintCommands(Items);
	SetAvailabilityOfOrderCommands(Items);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
// 
// Parameters:
// 	Command - FormCommand -
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If Find(Command.Name, "AnalysisOptionsList") Then
		List = Items.AnalysisOptionsList;
	Else
		List = Items.StructureOfTargetsList;
	EndIf;
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	If Find(Context.CommandNameInForm, "AnalysisOptionsList") Then
		List = Items.AnalysisOptionsList;
	Else
		List = Items.StructureOfTargetsList;
	EndIf;
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.StructureOfTargetsList);
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.AnalysisOptionsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsList.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseAnalysisOptions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("Enabled", False);

EndProcedure

&AtClient 
Function FindSelectionField(Var_Items, FilterName)
	
	SearchField = Undefined;
	
	FilterField = New DataCompositionField(FilterName);
	
	For Each Var_10_FilterField In Var_Items Do
		
		If TypeOf(Var_10_FilterField) = Type("DataCompositionFilterItemGroup") Then
			SearchField = FindSelectionField(Var_10_FilterField.Items, FilterName);
		Else
			If Var_10_FilterField.Use And Var_10_FilterField.LeftValue = FilterField Then
				
				SearchField = Var_10_FilterField;
				
				Break;
				
			EndIf;
		EndIf;
		
	EndDo;
	
	Return SearchField;
	
EndFunction

&AtClient
Procedure UpdateFormContentWhenGoalIsActivated()
	
	If TypeOf(Items.StructureOfTargetsList.CurrentRow) = Type("CatalogRef.StructureOfTargets") Then
		CurGoal = Items.StructureOfTargetsList.CurrentRow;
		UseAnalysisOptions = MeasurableTarget(CurGoal);
		
	Else
		CurGoal = Undefined;
		UseAnalysisOptions = False;
		
	EndIf;
	
	SearchSelectionField = FindSelectionField(TMCommonUseClientServer.GetDynamicListSelection(AnalysisOptionsList).Items, "Owner");
	
	If SearchSelectionField = Undefined Then
		GoalSelection = TMCommonUseClientServer.GetDynamicListSelection(AnalysisOptionsList).Items.Add(Type("DataCompositionFilterItem"));
		GoalSelection.Use = True;
		GoalSelection.LeftValue = New DataCompositionField("Owner");
		GoalSelection.ComparisonType = DataCompositionComparisonType.Equal;
		GoalSelection.RightValue = CurGoal;
		GoalSelection.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		
	Else
		SearchSelectionField.Use = True;
		SearchSelectionField.LeftValue = New DataCompositionField("Owner");
		SearchSelectionField.ComparisonType = DataCompositionComparisonType.Equal;
		SearchSelectionField.RightValue = CurGoal;
		SearchSelectionField.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		
	EndIf;
	
	Items.AnalysisOptionsList.ReadOnly = Not UseAnalysisOptions;
	
EndProcedure

&AtClientAtServerNoContext 
Procedure SetAvailabilityOfPrintCommands(Items)
	
	If Items.AnalysisOptionsList.CurrentRow = Undefined Then
		Items.AnalysisOptionsListReportTargetMonitorPrintForm.Enabled = False;
		Items.AnalysisOptionsListReportTargetMonitorPrintFormContext.Enabled = False;
	Else
		Items.AnalysisOptionsListReportTargetMonitorPrintForm.Enabled = True;
		Items.AnalysisOptionsListReportTargetMonitorPrintFormContext.Enabled = True;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext 
Procedure SetAvailabilityOfOrderCommands(Items)
	
	If Items.AnalysisOptionsList.CurrentRow = Undefined Then
		Items.AnalysisOptionsListGroupSequenceChange.Enabled = False;
	Else
		Items.AnalysisOptionsListGroupSequenceChange.Enabled = True;
	EndIf;
	
	If Items.StructureOfTargetsList.CurrentRow = Undefined Then
		Items.GoalStructureListGroupChangingTheOrderOfGoals.Enabled = False;
	Else
		Items.GoalStructureListGroupChangingTheOrderOfGoals.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer 
Function MeasurableTarget(Target)
	
	MeasurableTarget = False;
	
	Query = New Query;
	Query.SetParameter("Target", Target);
	Query.Text = "SELECT
	|	StructureOfTargets.MeasurableTarget
	|FROM
	|	Catalog.StructureOfTargets AS StructureOfTargets
	|WHERE
	|	StructureOfTargets.Ref = &Target";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		MeasurableTarget = Selection.MeasurableTarget;
		
	EndIf;
	
	Return MeasurableTarget;
	
EndFunction

#EndRegion
