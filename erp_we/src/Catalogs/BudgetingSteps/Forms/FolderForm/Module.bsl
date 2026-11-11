
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PeriodicityOfParent = ?(ValueIsFilled(Object.Parent), Common.ObjectAttributeValue(Object.Parent,
		"Periodicity"), Common.ObjectAttributeValue(Object.Owner, "Periodicity"));
	
	If Not ValueIsFilled(Object.Ref) Then
		If Not ValueIsFilled(Object.Periodicity) Then
			If Not ValueIsFilled(Object.Parent) Then
				Object.Periodicity = Enums.Periodicity.Year;
			Else
				Object.Periodicity = PeriodicityOfParent;
			EndIf;
		EndIf;
		If Not ValueIsFilled(Object.StageExecutionProcedure) Then
			Object.StageExecutionProcedure = Enums.BudgetingStageExecutionProcedure.Sequentially;
		EndIf;
	EndIf;
	
	Periodic = Object.Periodicity <> PeriodicityOfParent;
	SetPeriodicityParameters();
	SetFormElementHeaders(Object, Items);
	SetVisibility1(Object, Items);

	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	Items.Periodic.ReadOnly = Items.Periodicity.ReadOnly;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheOrderOfTheStepsOnChange(Item)
	
	SetFormElementHeaders(Object, Items);
	
EndProcedure

&AtClient
Procedure StartConditionOnChange(Item)
	
	If Object.StartCondition = PredefinedValue(
		"Enum.TypesOfBudgetingStepStartConditions.Manually") Then
		Object.DueDate = 0;
		Periodic = False;
		SetPeriodicityParameters();
	EndIf;
	
	SetFormElementHeaders(Object, Items);
	SetVisibility1(Object, Items);
	
EndProcedure

&AtClient
Procedure PeriodicOnChange(Item)
	
	SetPeriodicityParameters();
	
EndProcedure

&AtClient
Procedure ParentOnChange(Item)
	
	SetPeriodicityParameters();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure NotificationAboutUnblocking(Result, AdditionalParameters) Export
	
	Items.Periodic.ReadOnly = Items.Periodicity.ReadOnly;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("NotificationAboutUnblocking", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFormElementHeaders(Object, Items)
	
	If Object.StageExecutionProcedure = PredefinedValue("Enum.BudgetingStageExecutionProcedure.Parallel") Then
		Items.StartCondition.Title = NStr("vi = 'Chạy tất cả các nhiệm vụ';
											|ru = 'Запускать все задачи';
											|en = 'Start all tasks'; fa = 'Start all tasks';
											|it = 'Eseguire tutti i task';
											|pl = 'Uruchamiaj wszystkie zadania';
											|tr = 'Tüm görevleri çalıştır'");
	Else
		Items.StartCondition.Title = NStr("vi = 'Chạy nhiệm vụ đầu tiên';
											|ru = 'Запускать первую задачу';
											|en = 'Start the first task'; fa = 'Start the first task';
											|it = 'Eseguire il primo task';
											|pl = 'Uruchamiaj pierwsze zadanie';
											|tr = 'İlk görevi çalıştır'");
	EndIf;
	
	If Object.StartCondition = PredefinedValue("Enum.TypesOfBudgetingStepStartConditions.BeforePeriodStart")
		Or Object.StartCondition = PredefinedValue("Enum.TypesOfBudgetingStepStartConditions.BeforePeriodEnd") Then
		Items.DueDate.Title = NStr("vi = 'trong';
									|ru = 'за';
									|en = 'not later than'; fa = 'not later than';
									|it = 'per';
									|pl = 'not later than';
									|tr = 'için'");
	Else
		Items.DueDate.Title = NStr("vi = 'sau';
									|ru = 'через';
									|en = 'every'; fa = 'every';
									|it = 'fra';
									|pl = 'every';
									|tr = 'aracılığıyla'");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibility1(Object, Items)
	
	Items.LaunchOrderClarifications.Visible = (Object.StartCondition <> PredefinedValue(
		"Enum.TypesOfBudgetingStepStartConditions.Manually"));
	
EndProcedure

&AtServer
Procedure SetPeriodicityParameters()
	
	Items.Periodicity.Enabled = Periodic;
	PeriodicityOfParent = ?(ValueIsFilled(Object.Parent), Common.ObjectAttributeValue(Object.Parent,
		"Periodicity"), Common.ObjectAttributeValue(Object.Owner, "Periodicity"));
	
	If Periodic Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	TableOfPeriodicities.Periodicity,
		|	TableOfPeriodicities.Order
		|INTO OrderedPeriodicities
		|FROM
		|	&TableOfPeriodicities AS TableOfPeriodicities
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderedPeriodicities.Order
		|INTO PeriodicityCur
		|FROM
		|	OrderedPeriodicities AS OrderedPeriodicities
		|		INNER JOIN Enum.Periodicity AS EnumPeriodicity
		|		ON OrderedPeriodicities.Periodicity = EnumPeriodicity.Ref
		|			AND (EnumPeriodicity.Ref = &Ref)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderedPeriodicities.Periodicity AS Periodicity
		|FROM
		|	PeriodicityCur AS PeriodicityTable
		|		INNER JOIN OrderedPeriodicities AS OrderedPeriodicities
		|		ON PeriodicityTable.Order > OrderedPeriodicities.Order
		|		INNER JOIN Enum.Periodicity AS EnumPeriodicity
		|		ON (OrderedPeriodicities.Periodicity = EnumPeriodicity.Ref)";
		
		TableOfPeriodicities = Enums.Periodicity.OrderedPeriodicities(True);
		Query.SetParameter("TableOfPeriodicities", TableOfPeriodicities);
		Query.SetParameter("Ref", PeriodicityOfParent);
		
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		
		Items.Periodicity.ChoiceList.Clear();
		
		While SelectionDetailRecords.Next() Do
			
			Items.Periodicity.ChoiceList.Add(SelectionDetailRecords.Periodicity);
			
		EndDo;
		
	Else
		
		Object.Periodicity = PeriodicityOfParent;
		
	EndIf;
	
EndProcedure

#EndRegion
