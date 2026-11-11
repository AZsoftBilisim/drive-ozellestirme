
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("TypeOfAccrualDeduction", TypeOfAccrualDeduction); 
	Parameters.Property("Department", Department); 
	Parameters.Property("Employee",     Employee); 
	Parameters.Property("DocumentCalculation", DocumentCalculation); 
	Parameters.Property("SelectionLevel", SelectionLevel); 
	
	SelectionLevels = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels();
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"TypeOfAccrualDeduction",
		TypeOfAccrualDeduction,
		DataCompositionComparisonType.Equal,,,,);
	CommonClientServer.SetDynamicListFilterItem(List,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,,,);
	CommonClientServer.SetDynamicListFilterItem(List,
		"Employee",
		Employee,
		DataCompositionComparisonType.Equal,,,,);
	CommonClientServer.SetDynamicListFilterItem(List,
		"DocumentCalculation",
		DocumentCalculation,
		DataCompositionComparisonType.Equal,,,,);
		
	SetConditionalAppearance();	
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.List.CurrentData; 
	
	NotifyChoice(New Structure("Period", 
		CurrentData.Period));
	
EndProcedure

#EndRegion
	
#Region FormCommandsEventHandlers

&AtClient
Procedure Add(Command)

	NotifyChoice(New Structure("Period", 
		CommonClient.SessionDate()));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	// The level of selection of types of deduction of deductions
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Employee.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentCalculation.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionLevel");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = SelectionLevels.AccrualRetentionLevel;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);

	// Selection level Division level
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TypeOfAccrualDeduction.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Employee.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentCalculation.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionLevel");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = SelectionLevels.DivisionLevel;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);

	// Selection levelframe documents
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentCalculation.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionLevel");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = SelectionLevels.LevelPersonnelDocuments;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);	
	
EndProcedure	

#EndRegion
