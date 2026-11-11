
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Status", Status);
		QuickFilterStructure.Property("SaleRegistrationOption", SaleRegistrationOption);
		QuickFilterStructure.Property("BusinessOperation", BusinessOperation);
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListGoodsServicesSale, "Manager", Manager, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListGoodsServicesSale, "Status", Status, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListGoodsServicesSale, 
		"BusinessOperation",
		BusinessOperation,
		QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListGoodsServicesSale, 
		"SaleRegistrationOption",
		SaleRegistrationOption,
		QuickFilterStructure);
	
	If Not GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
		
		Item = Items.Status.ChoiceList.FindByValue(Enums.StatusesOfCustomerInvoices.InTransit);
		If Item <> Undefined Then
			Items.Status.ChoiceList.Delete(Item);
		EndIf;
		
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.ListGoodsServicesSale.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListGoodsServicesSaleCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListGoodsServicesSale.Date", Items.ListGoodsServicesSaleDate.Name);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
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
	
	
	If EventName = "Write_CustomerInvoice" Then
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListGoodsServicesSale, 
		"Manager", 
		Manager, 
		QuickFilterStructure,
		Settings);
	
	Settings.Insert("Manager", Manager);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListGoodsServicesSale,
		"Status",
		Status,
		QuickFilterStructure,
		Settings);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListGoodsServicesSale,
		"SaleRegistrationOption",
		SaleRegistrationOption,
		QuickFilterStructure,
		Settings);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListGoodsServicesSale

&AtClient
Procedure ListGoodsServicesSaleOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListGoodsServicesSaleOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtServerNoContext
Procedure ListGoodsServicesSaleOnGetDataAtServer(TagName, Settings, Rows)
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.ListGoodsServicesSale);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListGoodsServicesSale,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListGoodsServicesSale, 
		"Status",
		Status,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure SaleRegistrationOptionOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(ListGoodsServicesSale, 
		"SaleRegistrationOption",
		SaleRegistrationOption,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(SaleRegistrationOption));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.ListGoodsServicesSale);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListGoodsServicesSale);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListGoodsServicesSale);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


&AtClient
Procedure ListGoodsServicesSaleSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.CustomerInvoice.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.ListGoodsServicesSale.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
