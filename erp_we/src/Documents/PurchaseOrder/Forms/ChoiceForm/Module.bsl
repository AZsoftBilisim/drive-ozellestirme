
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("BusinessOperation")
		 And Not ValueIsFilled(Parameters.Filter.BusinessOperation) Then
			Parameters.Filter.Delete("BusinessOperation");
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"BusinessOperation",
				Enums.BusinessTransactions.TransferToCommissionAgent,
				DataCompositionComparisonType.NotEqual,, True);
		EndIf;
		
		If Parameters.Filter.Property("Owner") Then
			Parameters.Filter.Delete("Owner");
		EndIf;
		
		If Parameters.Property("WarehouseGroup_") Then
			
			 TheGroupName = NStr("vi = '%1';
								|ru = '%1';
								|en = '%1'; fa = '%1';
								|it = '%1';
								|pl = '%1';
								|tr = '%1'");
			 TheGroupName = StrTemplate(TheGroupName, "WarehouseGroup_");
			 
			 WarehouseSelectionGroup_ = CommonClientServer.CreateFilterItemGroup(
				TMCommonUseClientServer.GetDynamicListSelection(List).Items,
				TheGroupName,
				DataCompositionFilterItemsGroupType.OrGroup);
			CommonClientServer.AddCompositionItem(WarehouseSelectionGroup_,
				"Warehouse",
				DataCompositionComparisonType.Equal,
				Parameters.WarehouseGroup_,
				, // Presentation
				True);
			CommonClientServer.AddCompositionItem(WarehouseSelectionGroup_,
				"Warehouse",
				DataCompositionComparisonType.InHierarchy,
				Parameters.WarehouseGroup_,
				, // Presentation
				True);
			CommonClientServer.AddCompositionItem(WarehouseSelectionGroup_,
				"Warehouse",
				DataCompositionComparisonType.Equal,
				Documents.PurchaseOrder.EmptyRef(),
				, // Presentation
				True);
		EndIf;
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
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
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
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
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ClearMessages();
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

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.PurchaseOrder.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
