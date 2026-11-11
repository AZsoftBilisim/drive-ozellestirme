
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(TransferListOfGoodsToCustodian, "Manager",
		Manager, QuickFilterStructure);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	FillInHeaderByFunctionOption();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.TransferListOfGoodsToCustodian.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "TransferListOfGoodsToCustodian.Date",
		Items.TransferListOfGoodsToCustodianDate.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	ListOfAvailableHO = Documents.TransferOfGoodsToBailee.GetAvailableOperationsForDocument();
	
	ThisObject.ReadOnly = Not AccessRight("Update", Metadata.Documents.TransferOfGoodsToBailee)
		Or ListOfAvailableHO.Count() = 0;
	
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
	
	
	If EventName = "Write_TransferOfGoodsToBailee" Then
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(TransferListOfGoodsToCustodian, "Manager",
		Manager, QuickFilterStructure, Settings);
	
	Settings.Insert("Manager", Manager);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(TransferListOfGoodsToCustodian, "Manager",
		Manager, DataCompositionComparisonType.Equal, Undefined, ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransferListOfGoodsToCustodian

&AtClient
Procedure TransferListOfGoodsToCustodianOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure TransferListOfGoodsToCustodianOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtClient
Procedure TransferListOfGoodsToCustodianSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.TransferListOfGoodsToCustodian);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.TransferListOfGoodsToCustodian, Result);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.TransferListOfGoodsToCustodian);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject,
		Items.TransferListOfGoodsToCustodian);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure FillInHeaderByFunctionOption()
	
	UseSalesCommission                           = GetFunctionalOption("UseSalesCommission");
	UseTransferToCustodyWithRightOfSale = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	
	If UseTransferToCustodyWithRightOfSale
		And UseTransferToCustodyWithRightOfSale Then
		Title = NStr("vi = 'Chuyển giao hàng hóa cho bên cho thuê kho/bên nhận ký gửi';
					|ru = 'Передачи товаров хранителям/комиссионерам';
					|en = 'VMI/Customer stock fill-up documents'; fa = 'VMI/Customer stock fill-up documents';
					|it = 'Trasferimento articoli ai magazzini/commissionari';
					|pl = 'Przeniesienia towarów do depozytariuszy/komisantów';
					|tr = 'Konsinye/emanetçi tarafından malların transferi'");
	ElsIf UseTransferToCustodyWithRightOfSale Then
		Title = NStr("vi = 'Chuyển giao hàng hóa cho bên cho thuê kho';
					|ru = 'Передачи товаров хранителям';
					|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
					|it = 'Trasferimento articoli ai magazzini';
					|pl = 'Przeniesienia towarów przez depozytariuszy';
					|tr = 'Emanetçi tarafından malların transferi'");
	Else
		Title = NStr("vi = 'Chuyển giao hàng hóa cho bên nhận ký gửi';
					|ru = 'Передачи товаров комиссионерам';
					|en = 'Customer stock fill-up documents'; fa = 'Customer stock fill-up documents';
					|it = 'Trasferimento articoli ai commissionari';
					|pl = 'Przeniesienia towarów komisantom';
					|tr = 'Malların konsinyeden transferi'");
	EndIf;
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	
	If ReferencesArrray.Count() > 0 Then
		Items.TransferListOfGoodsToCustodian.CurrentRow = ReferencesArrray[0];
		
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.TransferOfGoodsToBailee.EmptyRef"));
	
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#EndRegion

#EndRegion
