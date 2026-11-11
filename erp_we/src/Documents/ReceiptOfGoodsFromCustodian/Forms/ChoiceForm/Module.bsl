
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.ListOfReceiptOfGoodsFromCustodian.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject,
		Items.ListOfReceiptOfGoodsFromCustodian.CommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
	If Source = "Peripherals"
		And IsInputAvailable() Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Manager = Settings.Get("Manager");
	
	CommonClientServer.SetDynamicListFilterItem(ListOfReceiptOfGoodsFromCustodian, "Manager",
		Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListOfReceiptOfGoodsFromCustodian, "Manager",
		Manager, DataCompositionComparisonType.Equal, , ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransferListOfGoodsToCustodian

&AtClient
Procedure ListOfReceiptOfGoodsFromCustodianOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListOfReceiptOfGoodsFromCustodian);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListOfReceiptOfGoodsFromCustodian, Result);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListOfReceiptOfGoodsFromCustodian);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListOfReceiptOfGoodsFromCustodian);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	
	If ReferencesArrray.Count() > 0 Then
		Items.ListOfReceiptOfGoodsFromCustodian.CurrentRow = ReferencesArrray[0];
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ReceiptOfGoodsFromCustodian.EmptyRef"));
	
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#EndRegion

#EndRegion
