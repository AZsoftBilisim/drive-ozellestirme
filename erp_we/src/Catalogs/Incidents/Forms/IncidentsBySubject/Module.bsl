#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("SubjectOf") Then 
		Basis = Parameters.SubjectOf;
		List.Parameters.SetParameterValue("Basis", Basis);
	EndIf;
	
	List.Parameters.SetParameterValue("ShowDeleted", False);
	List.Parameters.SetParameterValue("ShowClosed", False);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	List.Parameters.SetParameterValue("ShowDeleted", ShowDeleted);
	List.Parameters.SetParameterValue("ShowClosed", ShowClosed);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowDeletedOnChange(Item)
	List.Parameters.SetParameterValue("ShowDeleted", ShowDeleted);
EndProcedure

&AtClient
Procedure ShowClosedOnChange(Item)
	List.Parameters.SetParameterValue("ShowClosed", ShowClosed);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Not Copy Then
		Cancel = True;
		FormParameters = New Structure("SubjectOf", Basis);
		OpenForm("Catalog.Incidents.ObjectForm", FormParameters);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.RegistrationDate", "RegistrationDate");

	// highlighting an overdue incident in color
	#Region OverdueIncidents
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField("RequiredClosingDate");
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.RequiredClosingDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = CurrentSessionDate();
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.IncidentStatuses.Registered;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	#EndRegion
	
EndProcedure

#EndRegion