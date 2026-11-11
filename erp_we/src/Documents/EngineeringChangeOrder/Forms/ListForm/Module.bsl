
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetDynamicListPropertiesList();
	
	If TypeOf(Parameters.Basis) = Type("CatalogRef.Products") Then
		
		Products = Parameters.Basis;
		Items.NomenclatureSelection.Visible = False;
		
	ElsIf TypeOf(Parameters.Basis) = Type("CatalogRef.BillsOfMaterials") Then
		
		BillOfMaterials = Parameters.Basis;
		Items.SpecificationSelection.Visible = False;
		
	ElsIf TypeOf(Parameters.Basis) = Type("DocumentRef.ProductionOrder2_2") Then
		
		ProductionOrder = Parameters.Basis;
		Items.ProductionOrderSelection.Visible = False;
		
	EndIf;
	
	SetSelectionByProductRange();
	SetSelectionBySpecification();
	EstablishSelectionByProductionOrder();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusFilterOnChange(Item)
	SetSelectionByStatus();
EndProcedure

&AtClient
Procedure SpecificationSelectionOnChange(Item)
	SetSelectionBySpecification();
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	SetSelectionByProductRange();
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	SetSelectionByResponsible();
EndProcedure

&AtClient
Procedure ProductionOrderSelectionOnChange(Item)
	EstablishSelectionByProductionOrder();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy And Not Products.IsEmpty() And BillOfMaterials.IsEmpty() Then
		
		Cancel = True;
		
		Basis = New Structure;
		
		Basis.Insert("Material", Products);
		
		FormParameters = New Structure("Basis", Basis);
		
		OpenForm("Document.EngineeringChangeOrder.ObjectForm", FormParameters, , True);
		
	ElsIf Not Copy And Not BillOfMaterials.IsEmpty() Then
		
		Basis = New Structure;
		
		Basis.Insert("BillOfMaterials", BillOfMaterials);
		
		FormParameters = New Structure("Basis", Basis);
		
		OpenForm("Document.EngineeringChangeOrder.ObjectForm", FormParameters, , True);
		
	ElsIf Not Copy And Not ProductionOrder.IsEmpty() Then
		
		Basis = New Structure;
		
		Basis.Insert("ProductionOrder", ProductionOrder);
		
		FormParameters = New Structure("Basis", Basis);
		
		OpenForm("Document.EngineeringChangeOrder.ObjectForm", FormParameters, , True);
		
	EndIf;
	
EndProcedure

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

#EndRegion

#Region Private

#Region Filters

&AtServer
Procedure SetSelectionByStatus()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Status,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(Status));
	
EndProcedure

&AtServer
Procedure SetSelectionBySpecification()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref.AreasOfAction.BillOfMaterials",
		BillOfMaterials,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(BillOfMaterials));
	
EndProcedure

&AtServer
Procedure SetSelectionByResponsible()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"EmployeeResponsible",
		EmployeeResponsible,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtServer
Procedure SetSelectionByProductRange()
	
	Documents.EngineeringChangeOrder.SetSelectionByProductInDynamicListOfMaterialReplacementPermits(List, Products);
	
EndProcedure

&AtServer
Procedure EstablishSelectionByProductionOrder()

	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref.AreasOfAction.ProductionOrder",
		ProductionOrder,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(ProductionOrder));

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Number.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Date.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageNote.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Status.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidityStartDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidityEndDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeeResponsible.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeeResponsible.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfEngineeringChangeOrders.Terminated;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.OutdatedListTextColor);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure

&AtServer
Procedure SetDynamicListPropertiesList()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = Documents.EngineeringChangeOrder.RequestTextForDynamicListOfPermissionsToReplaceMaterials();
	ListProperties.QueryText = QueryText;
	
	ListProperties.MainTable = "Document.EngineeringChangeOrder";
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
		
EndProcedure

#EndRegion

#EndRegion
