//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		Items.List.ChangeRowSet = False;
		
	EndIf;
	
	If Parameters.Property("PickupByCounterparty") Then
		
		List.Parameters.SetParameterValue("Counterparty", Parameters.Counterparty);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetConditionalAppearance();
	
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

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem


#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	#Region ActionPeriod
	TextNotUsed = NStr("vi = '<không sử dụng>';
						|ru = '<не используется>';
						|en = '<not used>'; fa = '<استفاده نمی‌شود>';
						|it = '<не используется>';
						|pl = '<nie używa się>';
						|tr = '<kullanılmıyor>'");
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidOnDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidTo.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BonusType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VendorRebateTypes.Balance;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	#EndRegion
	
	#Region DateOfRemainingGoods
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfRemainingGoods.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BonusType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.VendorRebateTypes.Balance;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region BonusType
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BonusType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.WithoutCalculation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region AccrualFrequency
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualFrequency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BonusType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VendorRebateTypes.Balance;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	RebatesServer.SetStatusFormalization(ThisObject);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion