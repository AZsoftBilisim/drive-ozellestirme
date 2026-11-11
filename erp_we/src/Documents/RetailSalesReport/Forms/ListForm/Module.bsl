
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FilterCashRegister = Undefined;
	If Parameters.Property("CashRegister") Then
		FilterCashRegister = Parameters.CashRegister;
	EndIf;
	SetSelectionByCashAccountCashRegister(FilterCashRegister);
	
	SupportedPeripheralTypes = "BarcodeScanner";
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "RetailReports.Date", Items.Date.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedPeripheralTypes);
	
EndProcedure

&AtClient
Procedure OnClose()
	
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
	
	If EventName = "Write_RetailSalesReport" Then
		
		Items.RetailReports.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	// Software opening of the list form with selection by cash account Cash register
	If Parameters.Property("CashRegister") Then
		Settings.Delete(Items.CheckoutSelection.DataPath);
	Else
		SetSelectionByCashAccountCashRegister(Settings.Get("CashRegister"));
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CheckoutSelectionOnChange(Item)
	
	SetDynamicListSelectionOnClient();
	SetAccessibilityButtonsForCreatingNewDocuments(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRetailReports

&AtClient
Procedure RetailReportsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	CashRegisterFull = ValueIsFilled(CashRegister);
	
	If Not(Not ProhibitedToAddNewDocuments And CashRegisterFull) Then
		Cancel = True;	
	EndIf;
	
EndProcedure

&AtClient
Procedure RetailReportsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure RetailReportsOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.RetailReports);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.RetailReports, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.RetailReports);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.RetailReports);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If Not ReferencesArrray.Count() > 0 Then
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	Else
		Items.RetailReports.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.RetailSalesReport.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#EndRegion

#Region Other

&AtServerNoContext
Function ProhibitedToAddNewDocuments(CashRegister)
	
	Attributes = Catalogs.CashRegisters.CashRegisterDetails(CashRegister);
	Return Attributes.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters
	    Or Attributes.CashRegisterType = Enums.CashRegisterTypes.CashRegisterOffline;
	
EndFunction

// Also called prizagruzkedannyhiznadjustments on the Server
&AtClientAtServerNoContext
Procedure SetAccessibilityButtonsForCreatingNewDocuments(Form)
	
	Form.ProhibitedToAddNewDocuments = ProhibitedToAddNewDocuments(Form.CashRegister);
	
	CreationOfNewDocumentsIsAvailable = (Not Form.ProhibitedToAddNewDocuments And ValueIsFilled(Form.CashRegister));
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, "CreateRetailSalesReports", "Enabled", CreationOfNewDocumentsIsAvailable);
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, "RetailSalesReports", "Enabled", CreationOfNewDocumentsIsAvailable);
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, "ContextMenuRetailSalesReportsCreate", "Enabled", CreationOfNewDocumentsIsAvailable);
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, "ContextMenuRetailSalesReportsCopy", "Enabled", CreationOfNewDocumentsIsAvailable);
	
EndProcedure

// The procedure sets the selection of dynamic lists of the form.
//
&AtServer
Procedure SetDynamicListSelection()
	
	CommonClientServer.SetDynamicListFilterItem(RetailReports, "CashRegister", CashRegister, DataCompositionComparisonType.Equal,, ValueIsFilled(CashRegister));
	
EndProcedure

// The procedure sets the selection of dynamic lists of the form.
//
&AtClient
Procedure SetDynamicListSelectionOnClient()
	
	CommonClientServer.SetDynamicListFilterItem(RetailReports, "CashRegister", CashRegister, DataCompositionComparisonType.Equal,, ValueIsFilled(CashRegister));
	
EndProcedure

&AtServer
Procedure SetSelectionByCashAccountCashRegister(FilterCashRegister)
	
	CashRegister = FilterCashRegister;
	If Not ValueIsFilled(FilterCashRegister) Then
		If Not GetFunctionalOption("UseSeveralCashRegisters") Then
			CashRegister = Catalogs.CashRegisters.CashRegisterByDefault();
		EndIf;
	EndIf;
	
	SetDynamicListSelection();
	SetAccessibilityButtonsForCreatingNewDocuments(ThisObject);

EndProcedure

#EndRegion

#EndRegion
