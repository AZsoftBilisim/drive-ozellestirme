
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("DepartmentFilter", Department)  Then
		ConfigureByDivision(ThisObject);
	EndIf;
	
	Stage = Undefined;
	If Parameters.Property("StepFilter", Stage) Then
		ConfigureSelectionByStage(Stage);
	EndIf;
	
	AccountingForLaborCostsByEmployees = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate());
	
	#Region UniversalMechanisms
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	// End Peripherals
	
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
	If ValueIsFilled(Department)
		And Settings.Get("Department") <> Undefined Then
		Settings.Delete("Department");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	ConfigureByDivision(ThisForm);
	
EndProcedure

&AtClient
Procedure ShiftTaskSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"ShiftTask",
		ShiftTask,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(ShiftTask));
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Status,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure PerformerFilterOnChange(Item)
	
	If AccountingForLaborCostsByEmployees Then
		
		Person = GetIndividualByEmployee(Performer);
		Assignees = New Array;
		Assignees.Add(Performer);
		Assignees.Add(Person);
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Performer",
			Assignees,
			DataCompositionComparisonType.InList,
			,
			ValueIsFilled(Performer));
	Else
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Performer",
			Performer,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Performer));
	EndIf;
EndProcedure

&AtClient
Procedure InfoMessageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "DisableStageSelection" Then
		
		StandardProcessing = False;
		
		ConfigureSelectionByStage(Undefined);
		
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

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ProductionManagementClient.OpenOperationDocumentForm(RowSelected);
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	ProductionAccounting.SetStatusRegistrationInListOfProductionOperations(Rows);
	
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
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#Region Universal_

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

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List", "Date");

EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	If Common.IsMobileClient() Then
		ConfigureFormElementsForYourMobileDevice();
		Return;
	EndIf;
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.ProductionOperation2_2);
	Items.ListChangeSelectedItems.Visible          = ChangeSelectedAvailable;
	Items.ContextMenuChangeSelected.Visible = ChangeSelectedAvailable;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ConfigureByDivision(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureByDivision(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Department",
		Form.Department,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Form.Department));
		
	FOParameters = New Structure(
		"Department",
		?(ValueIsFilled(Form.Department), Form.Department, Undefined));
	
	Form.SetFormFunctionalOptionParameters(FOParameters);
	
	DivisionParameters = GetDivisionParameters(Form.Department);
	
	Form.Items.ShiftTaskSelection.Visible = DivisionParameters.UseShiftTasks;
	
	Form.Performer = Undefined;
	
	ProductionManagementClientServer.SetArtistType(
		Form.Performer, 
		DivisionParameters.UseTeamWorkOrders,
		Form.AccountingForLaborCostsByEmployees);
	
EndProcedure

&AtServer
Procedure ConfigureSelectionByStage(Stage)
	
	If Stage = Undefined Then
		
		Items.InfoMessage.Visible = False;
		
	Else
		
		// Setting up an information message
		RowsArray = New Array;
		
		PresentationStage = Documents.ProductionStage2_2.PresentationStage(
			Common.ObjectAttributesValues(Stage, "Number, StageName"));
				
		RowsArray.Add(NStr("vi = 'Đã thiết lập lọc theo công đoạn';
							|ru = 'Установлен отбор по этапу';
							|en = 'Stage filter is set'; fa = 'Stage filter is set';
							|it = 'Impostata la selezione per fase';
							|pl = 'Ustawiono selekcję wg etapu';
							|tr = 'Aşamaya göre filtre yapılandırıldı'"));
		RowsArray.Add(" ");
				
		RowsArray.Add(New FormattedString(
			PresentationStage,
			,
			,
			,
			GetURL(Stage)));
					
		RowsArray.Add(" (");
				
		RowsArray.Add(New FormattedString(NStr("vi = 'ngắt kết nối';
												|ru = 'отключить';
												|en = 'disable'; fa = 'disable';
												|it = 'disattivare';
												|pl = 'disable';
												|tr = 'devre dışı bırak'"),,,, "DisableStageSelection"));
				
		RowsArray.Add(") ");
				
		InfoMessage = New FormattedString(RowsArray);
			
		Items.InfoMessage.Visible = True;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Stage", Stage, DataCompositionComparisonType.Equal,, ValueIsFilled(Stage));
	
EndProcedure

&AtServerNoContext
Function GetDivisionParameters(Department)
	Return ProductionServer.ProductionBusinessUnitDescription(Department);
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionOperation2_2.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtServer
Procedure ConfigureFormElementsForYourMobileDevice()
	Items.List.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	
	Items.GroupFilter.Behavior           = UsualGroupBehavior.Collapsible;
	Items.GroupFilter.ShowTitle = True;
	
EndProcedure

&AtServerNoContext
Function GetIndividualByEmployee(Employee)
	Return Common.ObjectAttributeValue(Employee, "Individual");
EndFunction

#EndRegion
