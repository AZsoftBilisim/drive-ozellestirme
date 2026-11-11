
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Items.List.ChoiceMode = Parameters.ChoiceMode;
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "DocumentBasis" And ValueIsFilled(Item.CurrentData[Field.Name]) Then
		StandardProcessing = False;
		ShowValue(, Item.CurrentData[Field.Name]);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	Query = New Query;
	Query.SetParameter("Keys", Rows.GetKeys());
	Query.Text = 
		"SELECT
		|	RegistrarOfBudgetTurnover.Ref AS Ref,
		|	RegistrarOfBudgetTurnover.PlanningPeriod AS BeginOfPeriod,
		|	CASE
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, WEEK)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, TENDAYS)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, MONTH)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, QUARTER)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, HALFYEAR)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, YEAR)
		|		ELSE ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, DAY)
		|	END AS EndOfPeriod
		|FROM
		|	Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
		|WHERE
		|	RegistrarOfBudgetTurnover.Ref IN (&Keys)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		String = Rows.Get(Selection.Ref);
		String.Appearance.Get("PlanningPeriod").SetParameterValue("Text",
			New StandardPeriod(Selection.BeginOfPeriod, Selection.EndOfPeriod));
	EndDo;
	
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion
