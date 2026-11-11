
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	
	If Parameters.Property("Filter")
		And  (Parameters.Filter.Property("Premise")
		Or Parameters.Filter.Property("Owner")) Then
		If Parameters.Filter.Property("Premise") Then
			Owner = Common.ObjectAttributeValue(Parameters.Filter.Premise, "Owner");
			Parameters.Filter.Insert("Owner",Owner);
		EndIf;
		Items.WarehousesWarerooms.Visible = False;
		Items.Owner.Visible = False;
		Items.Premise.Visible = False;
	Else
		CreateWarehousesPremises();
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.StorageBins);
	Items.FormChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
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

#Region FormTableItemsEventHandlersWarehousesWarerooms

&AtClient
Procedure WarehousesWareroomsOnActivateRow(Item)
	CurrentData = Item.CurrentData;
	
	If CurrentData <> Undefined Then
		CommonClientServer.SetDynamicListFilterItem(List, "Owner", CurrentData.Warehouse,
																DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "Premise", CurrentData.Premise,
																DataCompositionComparisonType.Equal,, True);
	EndIf;
EndProcedure

&AtClient
Procedure WarehousesWareroomsPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure WarehousesWareroomsPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure WarehousesWareroomsSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	
	If CurrentData <> Undefined Then
		
		ShowValue(Undefined, CurrentData.Presentation);
		
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure CreateWarehousesPremises()
	Tree = New ValueTree;
	Tree.Columns.Add("Presentation");
	Tree.Columns.Add("Warehouse");
	Tree.Columns.Add("Premise");
	Tree.Columns.Add("UseBinLocationWarehousing");
	Tree.Columns.Add("DeletionMark");
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	History_.Warehouse AS Warehouse,
	|	History_.Premise AS Premise
	|FROM
	|	(SELECT DISTINCT
	|		Warehouses.Warehouse AS Warehouse,
	|		Warehouses.Premise AS Premise,
	|		Warehouses.UseBinLocationWarehousing AS UseBinLocationWarehousing
	|	FROM
	|		(SELECT 
	|			Warehouses.Ref AS Warehouse,
	|			NULL AS Premise,
	|			TRUE AS UseBinLocationWarehousing
	|		FROM
	|			Catalog.Warehouses AS Warehouses
	|		WHERE
	|			(Warehouses.UseBinLocationWarehousing
	|					OR Warehouses.UseBinLocationWarehousingForInformation)
	|		
	|		UNION ALL
	|		
	|		SELECT 
	|			Warerooms.Owner,
	|			NULL,
	|			FALSE
	|		FROM
	|			Catalog.Warerooms AS Warerooms
	|		WHERE
	|			(Warerooms.UseBinLocationWarehousing
	|					OR Warerooms.UseBinLocationWarehousingForInformation)) AS Warehouses
	|	
	|	UNION ALL
	|	
	|	SELECT 
	|		Warerooms.Owner,
	|		Warerooms.Ref,
	|		CASE
	|			WHEN Warerooms.UseBinLocationWarehousing
	|					OR Warerooms.UseBinLocationWarehousingForInformation
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|	FROM
	|		Catalog.Warerooms AS Warerooms
	|	WHERE
	|		(Warerooms.UseBinLocationWarehousing
	|				OR Warerooms.UseBinLocationWarehousingForInformation)) AS History_
	|
	|ORDER BY
	|	History_.Warehouse.Description,
	|	History_.Premise.Description
	|TOTALS BY
	|	Warehouse";
	
	SampleWarehouses = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	WarehouseLine = Undefined;
	
	While SampleWarehouses.Next() Do
		
		WarehouseLine 					= Tree.Rows.Add();
		WarehouseLine.Warehouse				= SampleWarehouses.Warehouse;
		WarehouseLine.Presentation 		= SampleWarehouses.Warehouse;
		WarehouseLine.DeletionMark 	= ?(SampleWarehouses.Warehouse.DeletionMark,3,2);
		
		RoomSelection = SampleWarehouses.Select(QueryResultIteration.ByGroups);
		
		While RoomSelection.Next() Do
			
			If ValueIsFilled(RoomSelection.Premise) Then	
				StringRoom 				= WarehouseLine.Rows.Add();
				StringRoom.Warehouse 			= RoomSelection.Warehouse;
				StringRoom.Premise 		= RoomSelection.Premise;
				StringRoom.Presentation 	= RoomSelection.Premise;			
				StringRoom.DeletionMark = ?(RoomSelection.Premise.DeletionMark,3,2);
			EndIf;
			                           
		EndDo;
		
	EndDo;
	
	ValueToFormAttribute(Tree, "WarehousesWarerooms");	
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

#EndRegion
