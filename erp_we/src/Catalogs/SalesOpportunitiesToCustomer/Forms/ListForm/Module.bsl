
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
	
	// exclude grouping by type of transaction if management is not used
	If Not GetFunctionalOption("UseOpportunityManagement") Then
		Items.QuickGrouping.ChoiceList.Delete(
			Items.QuickGrouping.ChoiceList.FindByValue("SalesOpportunityKind"));
	EndIf;
	// exclude grouping by agreements if agreements are not used
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
		Items.QuickGrouping.ChoiceList.Delete(
			Items.QuickGrouping.ChoiceList.FindByValue("CustomerTermsOfSales"));
	EndIf;
	
	If Parameters.Property("ByParticipant") Then
		
		Member = Parameters.ByParticipant;

		Query = New Query(
			"SELECT
			|	ParticipationInSalesOpportunities.Ref
			|FROM
			|	FilterCriterion.ParticipationInSalesOpportunities(&Member) AS ParticipationInSalesOpportunities");
		Query.SetParameter("Member", Member);
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Ref",
			Query.Execute().Unload().UnloadColumn("Ref"),
			DataCompositionComparisonType.InList,,True);
		
	EndIf;
	
	OnClosingByDefault = Parameters.Property("ForClosing");
	If OnClosingByDefault Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			Enums.OpportunityStatuses.InProgress,
			DataCompositionComparisonType.NotEqual,,True);
		
		CommonClientServer.SetDynamicListFilterItem(List, "Closed_", False, DataCompositionComparisonType.Equal,,True);
		
		AutoTitle = False;
		Title     = NStr("vi = 'Vụ việc chờ đóng';
						|ru = 'Сделки на закрытие';
						|en = 'Sales opportunities to close'; fa = 'Sales opportunities to close';
						|it = 'Transazioni per la chiusura';
						|pl = 'Umowy do zamknięcia';
						|tr = 'Kapanış üzerine satış fırsatı'");
		Items.Status_Filter.Visible = False;
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("EmployeeResponsible",EmployeeResponsible);
		QuickFilterStructure.Property("Status",       Status);
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	SetSelectionByStatusServer(Status);
	
	If IsBlankString(Status) Then
		Status = "All";
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.SalesOpportunitiesToCustomer);
	Items.ListChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	
	If Status = "All" Then
		Status = Settings.Get("Status");
		SetSelectionByStatusServer(Status);
	Else
		Settings.Delete("Status");
	EndIf;
	
	SetQuickGrouping(
		TMCommonUseClientServer.GetDynamicListGroupingFields(List),
		Settings.Get("QuickGrouping"));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QuickGroupingOnChange(Item)
	
	SetQuickGrouping(
		TMCommonUseClientServer.GetDynamicListGroupingFields(List),
		QuickGrouping);
	
EndProcedure

&AtClient
Procedure Status_FilterOnChange(Item)

	CommonClientServer.DeleteDynamicListFilterGroupItems(List,"Status");
	CommonClientServer.DeleteDynamicListFilterGroupItems(List,"Closed_");

	If Status = "InProgress" Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			PredefinedValue("Enum.OpportunityStatuses.InProgress"),
			DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "Won" Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			PredefinedValue("Enum.OpportunityStatuses.Won"),
			DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "Lost" Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			PredefinedValue("Enum.OpportunityStatuses.Lost"),
			DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "ForClosing" Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			PredefinedValue("Enum.OpportunityStatuses.InProgress"),
			DataCompositionComparisonType.NotEqual,,True);
		CommonClientServer.SetDynamicListFilterItem(List, "Closed_", False, DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "Open_" Then
		CommonClientServer.SetDynamicListFilterItem(List, "Closed_", False, DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "Closed" Then
		CommonClientServer.SetDynamicListFilterItem(List, "Closed_", True, DataCompositionComparisonType.Equal,,True);
	EndIf;

	If ValueIsFilled(EmployeeResponsible) Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"EmployeeResponsible",
			EmployeeResponsible,
			DataCompositionComparisonType.Equal,, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ResponsibleFilterOnChange(Item)

	CommonClientServer.SetDynamicListFilterItem(
		List,
		"EmployeeResponsible",
		EmployeeResponsible,
		DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));

EndProcedure

&AtClient
Procedure Status_FilterClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Status = "All";
	Status_FilterOnChange(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If ValueIsFilled(Member) Then
		
		Cancel = True;
		FormParameters = New Structure("Basis", Member);
		OpenForm("Catalog.SalesOpportunitiesToCustomer.ObjectForm", FormParameters, ThisObject);
		
	EndIf;
	
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

#Region FormControlEventHandlers

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ListSubjectDragCheck(Item, DragParameters, StandardProcessing, String, Field);
	// End StandardSubsystems.Interactions
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ListSubjectDrag(Item, DragParameters, StandardProcessing, String, Field);
	// End StandardSubsystems.Interactions

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#Region Other

&AtServer
Procedure SetSelectionByStatusServer(Status)
	
	If Not OnClosingByDefault And ValueIsFilled(Status) And Status <> "All" Then
		If Status = "InProgress" Then
			CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			PredefinedValue("Enum.OpportunityStatuses.InProgress"),
			DataCompositionComparisonType.Equal,,True);
		ElsIf Status = "Won" Then
			CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			PredefinedValue("Enum.OpportunityStatuses.Won"),
			DataCompositionComparisonType.Equal,,True);
		ElsIf Status = "Lost" Then
			CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			PredefinedValue("Enum.OpportunityStatuses.Lost"),
			DataCompositionComparisonType.Equal,,True);
		ElsIf Status = "ForClosing" Then
			CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			PredefinedValue("Enum.OpportunityStatuses.InProgress"),
			DataCompositionComparisonType.NotEqual,,True);
			CommonClientServer.SetDynamicListFilterItem(List, "Closed_", False, DataCompositionComparisonType.Equal,,True);
		ElsIf Status = "Open_" Then
			CommonClientServer.SetDynamicListFilterItem(List, "Closed_", False, DataCompositionComparisonType.Equal,,True);
		ElsIf Status = "Closed" Then
			CommonClientServer.SetDynamicListFilterItem(List, "Closed_", True, DataCompositionComparisonType.Equal,,True);
		EndIf;
	Else
		Status = "All";
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetQuickGrouping(GroupFields, FieldName)
	
	GroupFields.Items.Clear();
	
	If ValueIsFilled(FieldName) Then
		GroupingField = GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupingField.Field = New DataCompositionField(FieldName);
		GroupingField.Use = True;
	EndIf;

EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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
