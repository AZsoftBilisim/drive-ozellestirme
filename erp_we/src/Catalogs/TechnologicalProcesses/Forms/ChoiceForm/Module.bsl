
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter") Then
		// It is necessary to fill in the quick selection fields
		// so that their values match the selection in the list.
		FilterStructure1 = Parameters.Filter;
		If FilterStructure1.Property("Department", FilterDepartment) Then
			If FilterDepartment.IsEmpty() Then
				Parameters.Filter.Delete("Department");
			EndIf;
			If Parameters.Property("UnitViewOnly") Then
				Items.FilterDepartment.ReadOnly = True;
			EndIf;
		EndIf;
		If FilterStructure1.Property("Status", FilterStatus) Then
			If FilterStatus.IsEmpty() Then
				Parameters.Filter.Delete("Status");
			EndIf;
			If Parameters.Property("StatusViewOnly") Then
				Items.FilterStatus.ReadOnly = True;
			EndIf;
		EndIf;
		If FilterStructure1.Property("ForFinishedProductsKind") Then
			If TypeOf(FilterStructure1.ForFinishedProductsKind) = Type("Array") Then
				FilterProduct_Type.LoadValues(FilterStructure1.ForFinishedProductsKind);
			Else
				FilterProduct_Type.Add(FilterStructure1.ForFinishedProductsKind);
			EndIf;
			If Parameters.Property("ForTypeOfProductsOnlyViewing") Then
				Items.FilterProduct_Type.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
	
	If Parameters.Property("DisableSelection") Then
		CommonClientServer.SetDynamicListFilterItem(
			List, 
			"Ref", 
			Parameters.DisableSelection, 
			DataCompositionComparisonType.NotEqual,
			, 
			ValueIsFilled(Parameters.DisableSelection));
	EndIf;
	
	CustomizeFormElements();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region QuickFilters

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetSelectionByDivision(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterProductsOnChange(Item)
	
	SetSelectionByProductRange();
	
EndProcedure

&AtClient
Procedure SelectionTypeOfProductOnChange(Item)
	
	SetSelectionByKindOfProduct(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If IsFolder Then
		Return;
	EndIf;
	
	If Copy Then
		
		Cancel = True;
		
		CopyTechnologicalProcess();
		
	ElsIf Not FilterProducts.IsEmpty() Then
		
		Cancel = True;
		
		FormParameters = New Structure;
		FormParameters.Insert("Basis", FilterProducts);
		OpenForm("Catalog.TechnologicalProcesses.ObjectForm", FormParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region Filters

&AtClientAtServerNoContext
Procedure SetSelectionByStatus(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"Status", 
		Form.FilterStatus, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterStatus));
		
	ConfigureDependentFormElements(Form, "Filter");

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByDivision(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"Department", 
		Form.FilterDepartment, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterDepartment));
		
	ConfigureDependentFormElements(Form, "Filter");

EndProcedure

&AtServer
Procedure SetSelectionByProductRange()
	
	Catalogs.TechnologicalProcesses.SetSelectionByProductInListOfTechnologicalProcesses(
		List,
		FilterProducts);
		
	ConfigureDependentFormElements(ThisObject, "Filter");

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByKindOfProduct(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"ForFinishedProductsKind",
		Form.FilterProduct_Type,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Form.FilterProduct_Type));
		
	ConfigureDependentFormElements(Form, "Filter");

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Catalogs.TechnologicalProcesses.EstablishConditionalAppearanceOfListOfTechnologicalProcesses(List.ConditionalAppearance);
	
EndProcedure

&AtClient
Procedure CopyTechnologicalProcess()
	
	CallbackDescription = New CallbackDescription("QuestionCopyTechnologicalProcess", ThisObject);
	
	ProductDataManagementClient.ShowQuestionCopyWorkflowWithOperations(CallbackDescription)
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()

	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Filter")
		Or Initialize Then
			
			Items.FilterProduct_Type.InputHint = ?(ValueIsFilled(Form.FilterProduct_Type), "", NStr("vi = '<không lọc>';
																									|ru = '<без отбора>';
																									|en = '<No filter>'; fa = '<بدون فیلتر>';
																									|it = '<senza selezione>';
																									|pl = '<bez filtru>';
																									|tr = '<filtresiz>'"));
			
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionCopyTechnologicalProcess(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Ref = CopyWorkflowOnServer(Items.List.CurrentData.Ref);
	
	If Ref <> Undefined Then
		
		Items.List.CurrentRow = Ref;
		
		ProductDataManagementClient.NotifyAboutCopyingTechnologicalProcessWithOperations();
		
		OpenForm("Catalog.TechnologicalProcesses.ObjectForm", New Structure("Key", Ref));
	
	EndIf; 

EndProcedure

&AtServerNoContext
Function CopyWorkflowOnServer(Source)
	
	Return Catalogs.TechnologicalProcesses.CopyWorkflowWithOperations(Source);
	
EndFunction

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

