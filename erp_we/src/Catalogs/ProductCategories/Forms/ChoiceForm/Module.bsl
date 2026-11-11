#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	OwnerValue_ = Undefined;
	
	If Parameters.Property("Owner") Then
		DetailsOfOwner = Common.ObjectAttributesValues(Parameters.Owner,
					"ProductCategoriesCommonWithAnotherKindOfItems,ProductCategoryOwner");
					
		If DetailsOfOwner.ProductCategoriesCommonWithAnotherKindOfItems Then
			OwnerValue_ = Parameters.ProductCategoryOwner;
		Else
			OwnerValue_ = Parameters.Owner;
		EndIf;
	ElsIf Parameters.Property("Filter")
		And (Parameters.Filter.Property("Owner")
		Or Parameters.Filter.Property("ProductCategoryOwner")) Then
		
		If Parameters.Filter.Property("ProductCategoryOwner") Then
			OwnerValue_ = Parameters.Filter.ProductCategoryOwner;
			Parameters.Filter.Delete("ProductCategoryOwner");
		EndIf;
		
		If Parameters.Filter.Property("Owner") Then
			
			If Not ValueIsFilled(OwnerValue_) Then
				OwnerValue_ = Parameters.Filter.Owner;
			EndIf;
			
			Parameters.Filter.Delete("Owner");
		EndIf;	
		
	EndIf;	
	
	If ValueIsFilled(OwnerValue_) Then
		Items.ListOfProductKinds.Visible = False;
		ListSelectionsClientServer.ChangeListSelectionElement(
			List,
			"Owner",
			OwnerValue_,
			True,
			DataCompositionComparisonType.Equal);
	Else
		Items.ListOfProductKinds.Visible = True;
		ListSelectionsClientServer.ChangeListSelectionElement(
			List,
			"Owner",
			Catalogs.ItemKinds.EmptyRef(),
			False,
			DataCompositionComparisonType.Equal);
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfProductKinds

&AtClient
Procedure ListOfProductKindsOnActivateRow(Item)
	
	SetSelectionByCurRowOfProductType(Item.CurrentRow);
	
	Items.List.Enabled = Item.CurrentData <> Undefined And (Item.CurrentData.IsFolder = False);
	
EndProcedure

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

&AtClient
Procedure SetSelectionByCurRowOfProductType(CurLineOfForm)
	ProductCategoryOwner = CurLineOfForm;
	DetailsOfOwner        = GeneralPurposeTMServerCall.ObjectAttributesValues(ProductCategoryOwner, "ProductCategoriesCommonWithAnotherKindOfItems, ProductCategoryOwner");
	
	If DetailsOfOwner.ProductCategoriesCommonWithAnotherKindOfItems = True Then
		ProductCategoryOwner = DetailsOfOwner.ProductCategoryOwner;
	EndIf;
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		List,
		"Owner",
		ProductCategoryOwner,
		True,
		DataCompositionComparisonType.Equal);
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
