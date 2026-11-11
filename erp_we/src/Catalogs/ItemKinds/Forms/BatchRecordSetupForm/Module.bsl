
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ConfigureBatchAccounting.Parameters.SetParameterValue("Warehouse", Parameters.Warehouse); 

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersConfigureBatchAccounting

&AtClient
Procedure ConfigureBatchAccountingSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(Undefined, Item.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure ConfigureBatchAccountingOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.ConfigureBatchAccounting);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.ConfigureBatchAccounting);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ConfigureBatchAccounting);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ConfigureBatchAccountingBatchAccountingPolicy.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ConfigureBatchAccounting.BatchAccountingPolicy");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<trong kho này không ghi nhận sê-ri>';
													|ru = '<на этом складе серии не учитываются>';
													|en = '<batches are not recorded in this warehouse>'; fa = '<batches are not recorded in this warehouse>';
													|it = '<in questo magazzino le serie non sono conteggiate>';
													|pl = '<w tym magazynie serii nie są rejestrowane>';
													|tr = '<bu ambarda parti sayılmamaktadır>'"));
	
EndProcedure

#EndRegion
