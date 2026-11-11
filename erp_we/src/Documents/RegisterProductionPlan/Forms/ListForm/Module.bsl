
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	Recorders = Rows.GetKeys();
	
	If Recorders.UBound() = -1 Then
		Return;
	EndIf;
	
	ThereIsProductionPlan = Rows[Recorders[0]].Appearance.Get("QuantityProductionPlans") <> Undefined;
	ThereIsPlanForReleaseOfProducts = Rows[Recorders[0]].Appearance.Get("NumberOfProductReleasePlans") <> Undefined;
	ThereIsPlanForConsumptionOfMaterials = Rows[Recorders[0]].Appearance.Get("QuantityMaterialConsumptionPlans") <> Undefined;
	ThereIsPlanOfEmploymentOfTypesOfWorkCenters = Rows[Recorders[0]].Appearance.Get("NumberOfEmploymentPlansTypesOfWorkCenters") <> Undefined;
	ThereIsPlanForEmploymentOfLaborResources = Rows[Recorders[0]].Appearance.Get("NumberOfWorkforceEmploymentPlans") <> Undefined;
	
	If Not ( ThereIsProductionPlan
		Or ThereIsPlanForReleaseOfProducts
		Or ThereIsPlanForConsumptionOfMaterials
		Or ThereIsPlanOfEmploymentOfTypesOfWorkCenters
		Or ThereIsPlanForEmploymentOfLaborResources ) Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	Turnovers.Recorder AS Ref,
	|	SUM(Turnovers.QuantityProductionPlans) AS QuantityProductionPlans,
	|	SUM(Turnovers.NumberOfProductReleasePlans) AS NumberOfProductReleasePlans,
	|	SUM(Turnovers.QuantityMaterialConsumptionPlans) AS QuantityMaterialConsumptionPlans,
	|	SUM(Turnovers.NumberOfEmploymentPlansTypesOfWorkCenters) AS NumberOfEmploymentPlansTypesOfWorkCenters,
	|	SUM(Turnovers.NumberOfWorkforceEmploymentPlans) AS NumberOfWorkforceEmploymentPlans
	|FROM
	|	(SELECT
	|		Table.Recorder AS Recorder,
	|		COUNT(Table.LineNumber) AS QuantityProductionPlans,
	|		0 AS NumberOfProductReleasePlans,
	|		0 AS QuantityMaterialConsumptionPlans,
	|		0 AS NumberOfEmploymentPlansTypesOfWorkCenters,
	|		0 AS NumberOfWorkforceEmploymentPlans
	|	FROM
	|		AccumulationRegister.ProductionPlans AS Table
	|	WHERE
	|		Table.Recorder IN(&Recorders)
	|		AND &ThereIsProductionPlan
	|	
	|	GROUP BY
	|		Table.Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Recorder,
	|		0,
	|		COUNT(Table.LineNumber),
	|		0,
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.ReleasePlansProducts_ AS Table
	|	WHERE
	|		Table.Recorder IN(&Recorders)
	|		AND &ThereIsPlanForReleaseOfProducts
	|	
	|	GROUP BY
	|		Table.Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Recorder,
	|		0,
	|		0,
	|		COUNT(Table.LineNumber),
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.MaterialConsumptionPlans AS Table
	|	WHERE
	|		Table.Recorder IN(&Recorders)
	|		AND &ThereIsPlanForConsumptionOfMaterials
	|	
	|	GROUP BY
	|		Table.Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Recorder,
	|		0,
	|		0,
	|		0,
	|		COUNT(Table.LineNumber),
	|		0
	|	FROM
	|		AccumulationRegister.OccupancyPlansForWorkCenterTypes AS Table
	|	WHERE
	|		Table.Recorder IN(&Recorders)
	|		AND &ThereIsPlanOfEmploymentOfTypesOfWorkCenters
	|	
	|	GROUP BY
	|		Table.Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Recorder,
	|		0,
	|		0,
	|		0,
	|		0,
	|		COUNT(Table.LineNumber)
	|	FROM
	|		AccumulationRegister.PlansOfHumanResourcesOccupancy AS Table
	|	WHERE
	|		Table.Recorder IN(&Recorders)
	|		AND &ThereIsPlanForEmploymentOfLaborResources
	|	
	|	GROUP BY
	|		Table.Recorder) AS Turnovers
	|
	|GROUP BY
	|	Turnovers.Recorder");
	Query.SetParameter("Recorders", Recorders);
	Query.SetParameter("ThereIsProductionPlan", ThereIsProductionPlan);
	Query.SetParameter("ThereIsPlanForReleaseOfProducts", ThereIsPlanForReleaseOfProducts);
	Query.SetParameter("ThereIsPlanForConsumptionOfMaterials", ThereIsPlanForConsumptionOfMaterials);
	Query.SetParameter("ThereIsPlanOfEmploymentOfTypesOfWorkCenters", ThereIsPlanOfEmploymentOfTypesOfWorkCenters);
	Query.SetParameter("ThereIsPlanForEmploymentOfLaborResources", ThereIsPlanForEmploymentOfLaborResources);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ListLine = Rows[Selection.Ref];
		FillPropertyValues(ListLine.Data, Selection,, "Ref")
	EndDo;
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion
