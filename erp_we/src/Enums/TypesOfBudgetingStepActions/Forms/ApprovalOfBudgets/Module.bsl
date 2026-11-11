#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Address = Parameters.Address;
	BudgetingStep = Parameters.BudgetingStep;
	BudgetingModel = Parameters.BudgetingModel;
	ActionType = Parameters.ActionType;
	
	ActionSettings = GetFromTempStorage(Address);
	Enums.TypesOfBudgetingStepActions.RestoreActionSettings(ActionSettings, ThisObject);
	
	For Each Item In ApprovedStagesOfBudgetPreparation Do
		NewRow = BudgetingSteps.Add();
		NewRow.BudgetingStep = Item.Value;
	EndDo;
	
	FillInParametersForSelectingApprovedSteps();
	
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
Procedure FillInParametersForSelectingApprovedSteps()
	
	// Let's define the steps of the process, the input of documents on which can be approved at this step.
	StepsForApproval = New Array;
	
	TaskTable_ = Catalogs.BudgetingModels.GetBudgetIssues(BudgetingModel, Undefined,
		Undefined, CurrentSessionDate());
	ModelStart = Common.ObjectAttributeValue(BudgetingModel, "ValidOnDate");
	SearchParameters = New Structure("BudgetingStep, Period", BudgetingStep, ModelStart);
	StageLines_ = TaskTable_.FindRows(SearchParameters);
	If StageLines_.Count() Then
		ProcessStepString = StageLines_[0];
		FillInStepsForApprovalRecursively(TaskTable_, ProcessStepString, StepsForApproval);
	EndIf;
	
	ChoiceParameters = New Array;
	ChoiceParameters.Add(New ChoiceParameter("Filter.Ref", New FixedArray(StepsForApproval)));
	ChoiceParameters.Add(New ChoiceParameter("Filter.DeletionMark", False));
	ChoiceParameters.Add(New ChoiceParameter("Filter.NotRunning", False));
	Items.BudgetingStep.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

&AtServer
Procedure FillInStepsForApprovalRecursively(TaskTable_, ProcessStepString, StepsForApproval)
	
	For Each PreviousTask In ProcessStepString.PreviousTasks Do
		TaskNumber = PreviousTask.TaskNumber;
		PreviousTaskLine = TaskTable_.Find(TaskNumber, "TaskNumber");
		If ActionType = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets
			And (PreviousTaskLine.Action = Enums.TypesOfBudgetingStepActions.PlanEntry
			Or PreviousTaskLine.Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm) Then
			StepsForApproval.Add(PreviousTaskLine.BudgetingStep);
		ElsIf ActionType = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover
			And PreviousTaskLine.Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
			StepsForApproval.Add(PreviousTaskLine.BudgetingStep);
		EndIf;
		FillInStepsForApprovalRecursively(TaskTable_, PreviousTaskLine, StepsForApproval)
	EndDo;
	
EndProcedure

&AtServer
Function SaveSettingsAtServer()
	
	ApprovedStagesOfBudgetPreparation.Clear();
	For Each String In BudgetingSteps Do
		ApprovedStagesOfBudgetPreparation.Add(String.BudgetingStep);
	EndDo;
	
	Settings = Enums.TypesOfBudgetingStepActions.ActionSettings(ThisObject);
	Return PutToTempStorage(Settings, Address);
	
EndFunction

#EndRegion
