
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetConditionalAppearance();
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
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
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization     = Settings.Get("Organization");
	AdvanceHolder = Settings.Get("AdvanceHolder");
	Currency          = Settings.Get("Currency");
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(
		List, "AdvanceHolder", AdvanceHolder, DataCompositionComparisonType.Equal,, ValueIsFilled(AdvanceHolder));
	CommonClientServer.SetDynamicListFilterItem(
		List, "Currency", Currency, DataCompositionComparisonType.Equal,, ValueIsFilled(Currency));
	
	SetVisibility1();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CompanyFilterOnChangeServer();
	
EndProcedure

&AtClient
Procedure ThePersonAccountableSelectionOnChange(Item)
	
	ThePersonAccountableSelectionOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencySelection_3OnChange(Item)
	
	CurrencySelection_3OnChangeServer();
	
EndProcedure

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	DepartmentFilterOnChangeServer();

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

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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


&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure CompanyFilterOnChangeServer()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure ThePersonAccountableSelectionOnChangeServer()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "AdvanceHolder", AdvanceHolder, DataCompositionComparisonType.Equal,, ValueIsFilled(AdvanceHolder));
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure CurrencySelection_3OnChangeServer()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Currency", Currency, DataCompositionComparisonType.Equal,, ValueIsFilled(Currency));
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure DepartmentFilterOnChangeServer()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	SetVisibility1();
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ExpenseReport.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
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

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Currency.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đa tiền tệ>';
													|ru = '<Мультивалютный>';
													|en = '<Multicurrency>'; fa = '<Multicurrency>';
													|it = '<Мультивалютный>';
													|pl = '<Multicurrency>';
													|tr = '<Çoklu para birimi>'"));  
	Item.Appearance.SetParameterValue("MarkIncomplete",False);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.Organization.Visible = Not ValueIsFilled(Organization);
	Items.AdvanceHolder.Visible = Not ValueIsFilled(AdvanceHolder);
	Items.Currency.Visible = Not ValueIsFilled(Currency);
	
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
