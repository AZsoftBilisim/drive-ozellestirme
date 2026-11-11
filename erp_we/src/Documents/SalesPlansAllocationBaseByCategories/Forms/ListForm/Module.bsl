#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	SetAvailability(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);


	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ProductCategory  = Settings.Get("ProductCategory");
	If ValueIsFilled(ProductCategory) Then
		Attribute = Settings.Get("Attribute");
	Else
		Attribute = Undefined;
	EndIf; 
	
	EmployeeResponsible = Settings.Get("EmployeeResponsible");
	
	CommonClientServer.SetDynamicListFilterItem(List, "ProductCategory",  ProductCategory, DataCompositionComparisonType.Equal,, ValueIsFilled(ProductCategory));
	CommonClientServer.SetDynamicListFilterItem(List, "Attribute",  Attribute, DataCompositionComparisonType.Equal,, ValueIsFilled(Attribute));
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible",  EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
	SetAvailability(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterProductCategoryOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "ProductCategory",  ProductCategory, DataCompositionComparisonType.Equal,, ValueIsFilled(ProductCategory));
	
	SetAvailability(ThisForm);
	
	If ValueIsFilled(ProductCategory) Then
	
		FillInListOfBankingDetails();
		
	Else
		
		Attribute = Undefined;
		
		CommonClientServer.SetDynamicListFilterItem(List, "Attribute",  Attribute, DataCompositionComparisonType.Equal,, ValueIsFilled(Attribute));
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure FilterAttributeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Attribute",  Attribute, DataCompositionComparisonType.Equal,, ValueIsFilled(Attribute));
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible",  EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure StandardLockByAttribute(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("Operation", PredefinedValue("Enum.TransactionsOfStandardsAllocation.StandardLock"));
	FillingValues.Insert("ProductCategory", ProductCategory);
	FillingValues.Insert("Attribute", Attribute);
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Document.SalesPlansAllocationBaseByCategories.ObjectForm", FormParameters, ThisForm); 
	
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
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetAvailability(Form)

	If ValueIsFilled(Form.ProductCategory) Then
	
		Form.Items.FilterAttribute.Enabled = True;
	
	Else
	
		Form.Items.FilterAttribute.Enabled = False;
	
	EndIf; 

EndProcedure

&AtServer
Procedure FillInListOfBankingDetails()

	AttributesStructure1 = Documents.SalesPlansAllocationBaseByCategories.GetDetailsForRegulations();
	
	Items.FilterAttribute.ChoiceList.Clear();
	For Each KeyValue In AttributesStructure1 Do
		Items.FilterAttribute.ChoiceList.Add(KeyValue.Key, KeyValue.Value.Presentation);
	EndDo; 
	
	ListOfAdditionalBankingDetails = Documents.SalesPlansAllocationBaseByCategories.GetAdditionalDetailsForRegulations(ProductCategory);
	
	For Each ListItem In ListOfAdditionalBankingDetails Do
		Items.FilterAttribute.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;

EndProcedure 

#EndRegion
