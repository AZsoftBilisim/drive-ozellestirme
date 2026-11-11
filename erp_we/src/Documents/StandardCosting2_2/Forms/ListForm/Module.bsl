#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	#Region Filters
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "State", State, QuickFilterStructure);
	
	If Parameters.Property("Basis", Basis) Then
		EstablishSelectionOnBasisOf();
	EndIf;
	#EndRegion
	
	#Region UniversalMechanisms
	
	ToDoListOverridable.OnCreateAtServer(ThisObject, List);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem


	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	#EndRegion
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ToDoListOverridable.BeforeLoadDataFromSettingsAtServer(ThisObject, Settings);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Var FiltersStructure;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		
		If FiltersStructure.Property("ProductionDispatcherBusinessUnit") Then
			Settings.Insert("ProductionDispatcherBusinessUnit", FiltersStructure.ProductionDispatcherBusinessUnit)
		EndIf;
		
		If FiltersStructure.Property("Organization") Then
			Settings.Insert("Organization", FiltersStructure.Organization)
		EndIf;
		
		If FiltersStructure.Property("State") Then
			Settings.Insert("State", FiltersStructure.State)
		EndIf;
		
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Organization", Organization, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "State", State, QuickFilterStructure, Settings);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_StandardCosting2_2" Then
		EstablishSelectionOnBasisOf();
	EndIf;
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DivisionManagerSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "ProductionDispatcherBusinessUnit",
		ProductionDispatcherBusinessUnit, DataCompositionComparisonType.Equal,, ValueIsFilled(ProductionDispatcherBusinessUnit));
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization",
		Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure StateFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "State",
		State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#Region Universal_

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List", "Date");
	
EndProcedure

&AtServer
Procedure EstablishSelectionOnBasisOf()
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	StandardCosting2_2.Ref AS Ref
		|FROM
		|	Document.StandardCosting2_2.CostObjects AS StandardCosting2_2CostObjects
		|		INNER JOIN Document.StandardCosting2_2 AS StandardCosting2_2
		|		ON StandardCosting2_2CostObjects.Ref = StandardCosting2_2.Ref
		|WHERE
		|	StandardCosting2_2.CostObject = VALUE(Enum.CostObjects.BillOfMaterial)
		|	AND StandardCosting2_2CostObjects.Object = &BillOfMaterials";
	
	Query.SetParameter("BillOfMaterials", Basis);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref",
		Query.Execute().Unload().UnloadColumn("Ref"),
		DataCompositionComparisonType.InList,,,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

#EndRegion
