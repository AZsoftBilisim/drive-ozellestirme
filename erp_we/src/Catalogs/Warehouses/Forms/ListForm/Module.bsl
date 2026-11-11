
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// set the selection header
	If Parameters.Property("RetailStores") Then
		AutoTitle = False;
		Title = NStr("vi = 'Cửa hàng bán lẻ';
					|ru = 'Розничные магазины';
					|en = 'Retail stores'; fa = 'Retail stores';
					|it = 'Negozi a dettaglio';
					|pl = 'Sklepy detaliczne';
					|tr = 'Perakende mağazaları'");
	EndIf;
		
	If GetFunctionalOption("UseRetailSales") Then
		CommonClientServer.SetFormItemProperty(Items, "FormCreate", "Visible", False);		
		Items.CreateWarehouseGroup.Visible = True;
	Else
		CommonClientServer.SetFormItemProperty(Items, "FormCreate", "Visible", True);		
		Items.CreateWarehouseGroup.Visible = False;
	EndIf;
	
	If Not AccessRight("InteractiveInsert", Metadata.Catalogs.Warehouses) Then
		Items.CreateWarehouseGroup.Visible = False;
	EndIf;
	
	Items.List.ChangeRowSet = GetFunctionalOption("UseSeveralWarehouses");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure // Joining the Server()

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateWholesaleWarehouse(Command)
	
	OpenNewElementForm(PredefinedValue("Enum.TypesOfWarehouses.WholesaleWarehouse"));
	
EndProcedure

&AtClient
Procedure CreateRetailStore(Command)
	
	OpenNewElementForm(PredefinedValue("Enum.TypesOfWarehouses.RetailStore"));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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

#Region Private

&AtClient
Procedure OpenNewElementForm(WarehouseStore)
	
	FillingValues = New Structure;
	FillingValues.Insert("WarehouseStore",	WarehouseStore);
	FillingValues.Insert("Group",		CurWarehouseGroup());
	
	ParametersStructure = New Structure("FillingValues", FillingValues);
	
	OpenForm("Catalog.Warehouses.ObjectForm", ParametersStructure, ThisForm);
	
EndProcedure

&AtClient
Function CurWarehouseGroup()
	
	CurrentParent	= Items.List.CurrentParent;
	CurrentData	= Items.List.CurrentData;
	CurrentGroup	= ?(CurrentData <> Undefined,
						?(CurrentData.IsFolder,
							CurrentData.Ref,
							CurrentData.Parent),
						?(Items.List.Representation = TableRepresentation.HierarchicalList,
							CurrentParent,
							Undefined));
	
	Return CurrentGroup;
	
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
