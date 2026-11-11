
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InitializingFormWhenCreatingItOnServer();
	
	#Region StandardMechanisms
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);
	#EndRegion
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	SavedOperations = Settings.Get("AvailableBusinessTransactions");	
	If SavedOperations <> Undefined Then
		
		For Each SavedOperation In SavedOperations Do
			
			If SavedOperation.Check Then
				
				FoundOperation = AvailableBusinessTransactions.FindByValue(SavedOperation.Value);
				If FoundOperation <> Undefined Then
					FoundOperation.Check = True;
				EndIf;	
				
			EndIf;	
			
		EndDo;
		
		Settings.Delete("AvailableBusinessTransactions");
		
	EndIf;	
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetSelectionByDivision(ThisForm);
	SetSelectionByOperation(ThisForm);
	SetSelectionByResponsible(ThisForm);
	SetSelectionByStatus(ThisForm);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetSelectionByDivision(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterOperationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
		New Structure("TransactionList", AvailableBusinessTransactions), Item);
	
EndProcedure

&AtClient
Procedure FilterOperationOnChange(Item)
	
	SetSelectionByOperation(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterOperationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		StandardProcessing = False;
		AvailableBusinessTransactions = ValueSelected;
		SetSelectionByOperation(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterOperationClearing(Item, StandardProcessing)
	
	AvailableBusinessTransactions.FillChecks(False);
	SetSelectionByOperation(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	SetSelectionByResponsible(ThisForm);
	
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
Procedure ListOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#Region AttachableCommands

// Parameters:
// 	Command - FormCommand - Command
&AtClient
Procedure Attachable_CreateDocument(Command)
	
	NamesArray = StrSplit(Command.Name, "_");
	
	FillingValues = New Structure;
	FillingValues.Insert("BusinessOperation", AvailableBusinessTransactions.Get(NamesArray[1]).Value);
	
	If ValueIsFilled(FilterDepartment) Then
		FillingValues.Insert("Department", FilterDepartment);
	EndIf;
	
	OpenForm("Document.MovementOfProductsAndMaterials.ObjectForm", New Structure("FillingValues", FillingValues));
	
EndProcedure

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

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.MovementOfProductsAndMaterials.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	Documents.MovementOfProductsAndMaterials.SetConditionalAppearanceOfOperation(List.ConditionalAppearance);

EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()
	
	AvailableBusinessTransactions = Documents.MovementOfProductsAndMaterials.TransactionList();
	
	SetSelectionByDivision(ThisForm); //To initialize the parameters of the din list.
	
	If AccessRight("InteractiveInsert", Metadata.Documents.MovementOfProductsAndMaterials) Then
		
		For IndexOf = 0 To AvailableBusinessTransactions.Count() - 1 Do
		
			Presentation = AvailableBusinessTransactions.Get(IndexOf).Presentation;
			
			CommandName = "Create_" + IndexOf;
			FoundCommand = Commands.Find(CommandName);
			
			If FoundCommand = Undefined Then
				NewCommand = Commands.Add(CommandName);
				NewCommand.Action = "Attachable_CreateDocument";
			Else
				NewCommand = FoundCommand;
			EndIf;
			
			ItemButtonSubmenu = Items.Add(CommandName, Type("FormButton"), Items.TheDocumentsListTheGroupToCreate);
			ItemButtonSubmenu.Type = FormButtonType.CommandBarButton;
			ItemButtonSubmenu.CommandName = NewCommand.Name;
			ItemButtonSubmenu.Title = Presentation;
			
		EndDo;
		
	EndIf;
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.MovementOfProductsAndMaterials);
	Items.ListChangeSelectedItems.Visible          = ChangeSelectedAvailable;
	Items.ContextMenuChangeSelected.Visible = ChangeSelectedAvailable;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByDivision(Form)

	CommonClientServer.SetDynamicListParameter(
		Form.List,
		"RecipientOrSender",
		Form.FilterDepartment);

	CommonClientServer.SetDynamicListParameter(
		Form.List,
		"ToUseTheReceiverOrTheSender",
		Not Form.FilterDepartment.IsEmpty());
		
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByOperation(Form)

	FillInSelectionPresentationForOperation(Form);
	
	SelectedOperations = New ValueList;
	For Each CollectionItem In Form.AvailableBusinessTransactions Do
		If CollectionItem.Check Then
			SelectedOperations.Add(CollectionItem.Value);
		EndIf; 
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"BusinessOperation",
		SelectedOperations,
		DataCompositionComparisonType.InList,,
		SelectedOperations.Count() <> 0);

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByResponsible(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"EmployeeResponsible",
		Form.FilterEmployeeResponsible,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterEmployeeResponsible));

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByStatus(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Status",
		Form.FilterStatus,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterStatus));

EndProcedure

&AtClientAtServerNoContext
Procedure FillInSelectionPresentationForOperation(Form)
	
	Form.FilterOperation = "";
	For Each ListItem In Form.AvailableBusinessTransactions Do
		If ListItem.Check Then
			Presentation = ?(IsBlankString(ListItem.Presentation), ListItem.Value, ListItem.Presentation);
			Form.FilterOperation = Form.FilterOperation +
				?(ValueIsFilled(Form.FilterOperation), ", ", "") + Presentation;
		EndIf;
	EndDo;
		
EndProcedure

#EndRegion

#EndRegion
