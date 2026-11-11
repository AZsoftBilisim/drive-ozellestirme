
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not GetFunctionalOption("UseShipmentProhibition") Then
		Items.PagesSegments.PagesRepresentation = FormPagesRepresentation.None;
	EndIf; 
	
	CreationIsAvailable = AccessRight("Insert", Metadata.Catalogs.PartnersSegments);
	ItemArray = New Array;
	ItemArray.Add("ShipmentProhibitionListCreateASegmentOfShipmentProhibition");
	ItemArray.Add("ShipmentProhibitionListContextMenuCreateASegmentOfShipmentProhibition");
	ItemArray.Add("ShipmentProhibitionListCopy");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", CreationIsAvailable);
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.PartnersSegments);
	Items.FormChangeSelectedItems.Visible                  = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible  = CanBeEdited;
	Items.ShipmentProhibitionListChangeSelectedItems.Visible  = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems1.Visible = CanBeEdited;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	
	PlacementParameters = New Structure;
	PlacementParameters.Insert("Sources", New TypeDescription("CatalogRef.PartnersSegments"));
	PlacementParameters.Insert("CommandBar", Items.ShipmentProhibitionList.CommandBar);
	PlacementParameters.Insert("GroupsPrefix", "SegmentIsUsedToProhibitShipment");
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

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

&AtClient
Procedure ChangeSelectedItems(Command)
	If Items.PagesSegments.CurrentPage = Items.PartnersSegments Then
		BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	ElsIf Items.PagesSegments.CurrentPage = Items.ShipmentProhibitionSegments Then
		BatchEditObjectsClient.ChangeSelectedItems(Items.ShipmentProhibitionList);
	EndIf;
EndProcedure

&AtClient
Procedure CreateASegmentOfShipmentProhibition(Command)
	
	FillingData = New Structure;
	FillingData.Insert("SegmentIsUsedToProhibitShipment",     True);
	FillingData.Insert("GenerationMethod", PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly"));
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", FillingData);
	OpenForm("Catalog.PartnersSegments.ObjectForm", ParametersStructure1, Items.ShipmentProhibitionList);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	If Items.PagesSegments.CurrentPage = Items.ShipmentProhibitionSegments Then
		AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ShipmentProhibitionList);
	Else
		AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
	EndIf;
	
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
