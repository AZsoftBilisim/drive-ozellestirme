
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("ReferenceOrder", ReferenceOrder) Then
		
			EstablishSelectionByOrder(ThisForm);
		
		ElsIf Parameters.Filter.Property("ProductionLot", ProductionLot) Then
			
			Items.ReferenceOrder.Visible = False;
			Items.ProductionLot.Visible = True;
		
		EndIf;
		
	EndIf;
	
	If Not Parameters.ExcludeLink.IsEmpty() Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Ref",
			Parameters.ExcludeLink,
			DataCompositionComparisonType.NotEqual,
			,
			True);
		
	EndIf;
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
	
	If EventName = "Write_ProductionStages" Then
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ReferenceOrderOnChange(Item)
	
	EstablishSelectionByOrder(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure EstablishSelectionByOrder(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"ReferenceOrder",
		Form.ReferenceOrder,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Form.ReferenceOrder));
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
	Ref = LinkToListItemByBarcode(Data.Barcode);
	If Ref <> Undefined Then
		Items.List.CurrentRow = Ref;
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Return ProductionManagementClient.LinkToProductionStageByBarcode(Barcode);
	
EndFunction

#EndRegion
