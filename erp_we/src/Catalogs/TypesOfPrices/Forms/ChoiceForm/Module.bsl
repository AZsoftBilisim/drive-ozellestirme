#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("Title", Title);
	
	Items.List.ChangeRowSet = GetFunctionalOption("UseSeveralPriceTypes");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	If Parameters.OutputAnArbitraryTypeOfPrices Then
		
		UsePriceManagementSystem25 = True;
		If Not Parameters.Property("UsePriceManagementSystem25", UsePriceManagementSystem25) Then
			UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
		EndIf;
		
		OwnerOfAnIndividualPriceType = Undefined;
		ToUseTermsOfSales = False;
		If UsePriceManagementSystem25 And Parameters.Property("ToUseTermsOfSales", ToUseTermsOfSales) Then
			If ToUseTermsOfSales Then
				OwnerOfAnIndividualPriceType = ?(Parameters.Property("Terms"), Parameters.Terms, Undefined);
			Else
				OwnerOfAnIndividualPriceType = ?(Parameters.Property("Partner"), Parameters.Partner, Undefined);
			EndIf;
		EndIf;
		
		If ValueIsFilled(OwnerOfAnIndividualPriceType) Then
			CommonClientServer.SetDynamicListParameter(List, "OwnerOfAnIndividualPriceType", OwnerOfAnIndividualPriceType, True);
			CommonClientServer.SetDynamicListFilterItem(List,
																				"OwnerOfAnIndividualPriceType",
																				OwnerOfAnIndividualPriceType,
																				DataCompositionComparisonType.Equal,
																				"FilterDefault",
																				True);
		Else
			If Not Parameters.Filter.Property("Purpose") Then
				CommonClientServer.SetDynamicListFilterItem(List,
																					"Purpose",
																					Enums.PriceTypesAssignment.Shared,
																					DataCompositionComparisonType.Equal,
																					"FilterDefault",
																					True);
			EndIf;
		EndIf;
		
		Parameters.Filter.Delete("Purpose");
		
		If Parameters.TypesOfPrices.Count() Then
			CommonClientServer.SetDynamicListFilterItem(List,
																				"Ref",
																				Parameters.TypesOfPrices,
																				DataCompositionComparisonType.InList,
																				"FilterDefault",
																				True);
			
		EndIf;
	EndIf;
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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

//@skip-warning
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

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
