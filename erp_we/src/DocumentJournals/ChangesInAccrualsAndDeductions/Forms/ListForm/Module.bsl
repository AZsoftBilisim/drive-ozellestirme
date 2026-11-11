#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBarForm;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization", FilterOrganization);
		QuickFilterStructure.Property("Department", FilterDepartment);
		QuickFilterStructure.Property("Employee", FilterEmployee);
		QuickFilterStructure.Property("RegistrationMonth", FilterRegistrationMonth);
		
		Items.FilterOrganization.ReadOnly = True;		
		Items.FilterDepartment.ReadOnly = True;		
		Items.FilterEmployee.ReadOnly = True;		
		
		SetDynamicListSelectionOnServer();
		
	EndIf;
	
EndProcedure 

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure = Undefined Then
		FilterOrganization = Settings.Get("FilterOrganization");
		FilterDepartment = Settings.Get("FilterDepartment");
		FilterEmployee = Settings.Get("FilterEmployee");

		SetDynamicListSelectionOnServer();
	Else	
		
		FilterOrganization = QuickFilterStructure.Organization;
		FilterDepartment = QuickFilterStructure.Department;
		FilterEmployee = QuickFilterStructure.Employee;

	EndIf;	
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure = Undefined Then
		FilterOrganization = Settings.Get("FilterOrganization");
		FilterDepartment = Settings.Get("FilterDepartment");
		FilterEmployee = Settings.Get("FilterEmployee");

		SetDynamicListSelectionOnServer();
	Else	
		
		FilterOrganization = QuickFilterStructure.Organization;
		FilterDepartment = QuickFilterStructure.Department;
		FilterEmployee = QuickFilterStructure.Employee;

	EndIf;	
	
EndProcedure

#EndRegion  

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", FilterOrganization, 
			DataCompositionComparisonType.Equal,, ValueIsFilled(FilterOrganization));
EndProcedure

&AtClient
Procedure FilterOrganizationClearing(Item, StandardProcessing)
	If Not ValueIsFilled(FilterOrganization) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", FilterDepartment, 
			DataCompositionComparisonType.Equal,, ValueIsFilled(FilterDepartment));
	
EndProcedure

&AtClient
Procedure FilterDepartmentClearing(Item, StandardProcessing)
	If Not ValueIsFilled(FilterDepartment) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterEmployeeOnChange(Item)
	
	Use = ?(ValueIsFilled(FilterEmployee), True, False);
	
	CommonClientServer.SetDynamicListParameter(List, "FilterEmployee", FilterEmployee, Use);

EndProcedure

&AtClient
Procedure FilterEmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	FormParameters = New Structure;
	FormParameters.Insert("Filter", ParametersForOpeningSelection);
	
	OpenForm("Catalog.EmployeesHR.Form.ChoiceFormInternational", FormParameters, Items.FilterEmployee);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) 
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtClient
Procedure Attachable_CreateDocument(Command) 
	
	AdditionalFillInValues = New Structure("Employee, Organization, FilterDepartment", FilterEmployee, FilterOrganization, FilterDepartment);
	
	DocumentsPayrollAndHumanResourcesClient.CreateDocumentBasedOnDescription(ThisObject, Command.Name, AdditionalFillInValues);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetDynamicListSelectionOnServer()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", FilterOrganization, 
									DataCompositionComparisonType.Equal,,ValueIsFilled(FilterOrganization));
									
	CommonClientServer.SetDynamicListFilterItem(List, "Department", FilterDepartment, 
									DataCompositionComparisonType.Equal,,ValueIsFilled(FilterDepartment));
									
	CommonClientServer.SetDynamicListFilterItem(List, "ChangeDate", FilterRegistrationMonth, 
									DataCompositionComparisonType.GreaterOrEqual,,ValueIsFilled(FilterRegistrationMonth));
	CommonClientServer.SetDynamicListFilterItem(List, "ChangeDate", EndOfMonth(FilterRegistrationMonth), 
									DataCompositionComparisonType.LessOrEqual,,ValueIsFilled(FilterRegistrationMonth));
					
	Use = ?(ValueIsFilled(FilterEmployee), True, False);
	
	CommonClientServer.SetDynamicListParameter(List, "FilterEmployee", FilterEmployee, Use);
	
EndProcedure

#EndRegion

#EndRegion
