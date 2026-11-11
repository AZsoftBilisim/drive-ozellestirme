
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Filter.Property("Status") Then
		Status = Parameters.Filter.Status;
		Parameters.Filter.Delete("Status");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"StatusFromHistoryOfGiftCertificates",
				Status,
				DataCompositionComparisonType.InList);   		
	EndIf;    
	
	If Parameters.Filter.Property("GiftCardAccounting25") Then
		GiftCardAccounting25 = Parameters.Filter.GiftCardAccounting25;
		Parameters.Filter.Delete("GiftCardAccounting25");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"GiftCardAccounting25",
				GiftCardAccounting25,
				DataCompositionComparisonType.Equal);   		
	EndIf;    
	
	If Parameters.Filter.Property("Currency") Then
		Currency = Parameters.Filter.Currency;
		Parameters.Filter.Delete("Currency");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"Currency",
				Currency,
				DataCompositionComparisonType.InList);   		
	EndIf;    
	
	If Parameters.Filter.Property("Organization") Then
		Organization = Parameters.Filter.Organization;
		Parameters.Filter.Delete("Organization");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"Organization",
				Organization,
				DataCompositionComparisonType.InList);   		
	EndIf;    
	
	If Parameters.Filter.Property("JustNotZeroBalances") Then
		JustNotZeroBalances = Parameters.Filter.JustNotZeroBalances;
		Parameters.Filter.Delete("JustNotZeroBalances");
		If JustNotZeroBalances Then
			CommonClientServer.SetDynamicListFilterItem(List,
					"Balance",
					0,
					DataCompositionComparisonType.NotEqual);   		
		EndIf;
	EndIf;
	
	If Parameters.Filter.Property("OnlyBalancesGreaterThanZero") Then
		OnlyBalancesGreaterThanZero = Parameters.Filter.OnlyBalancesGreaterThanZero;
		Parameters.Filter.Delete("OnlyBalancesGreaterThanZero");
		If OnlyBalancesGreaterThanZero Then
			CommonClientServer.SetDynamicListFilterItem(List,
					"Balance",
					0,
					DataCompositionComparisonType.Greater);
		EndIf;
	EndIf;

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Balance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkNegatives", True);

EndProcedure

#EndRegion
