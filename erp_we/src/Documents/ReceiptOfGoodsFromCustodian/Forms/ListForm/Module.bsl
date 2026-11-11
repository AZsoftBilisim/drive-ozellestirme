
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListOfReceiptOfGoodsFromCustodian, "Manager",
		Manager, QuickFilterStructure);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	FillInHeaderByFunctionOption();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.ListOfReceiptOfGoodsFromCustodian.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
																	"ListOfReceiptOfGoodsFromCustodian.Date",
																	Items.ListOfReceiptOfGoodsFromCustodianDate.Name);
	
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
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListOfReceiptOfGoodsFromCustodian, "Manager",
		Manager, QuickFilterStructure, Settings);
	
	Settings.Insert("Manager", Manager);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListOfReceiptOfGoodsFromCustodian, "Manager",
		Manager, DataCompositionComparisonType.Equal, Undefined, ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfReceiptOfGoodsFromCustodian

&AtClient
Procedure ListOfReceiptOfGoodsFromCustodianOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListOfReceiptOfGoodsFromCustodianOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtClient
Procedure ListOfReceiptOfGoodsFromCustodianSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject,
		Items.ListOfReceiptOfGoodsFromCustodian);
	
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
	
	If UseSalesCommission And UseSalesCommission Then
		Title = NStr("vi = 'Tiếp nhận hàng hóa từ bên cho thuê kho/bên nhận ký gửi';
					|ru = 'Поступление товаров от хранителей/комиссионеров';
					|en = 'VMI return/Receipt of goods from consignee'; fa = 'VMI return/Receipt of goods from consignee';
					|it = 'Ricezione articoli dai magazzini/commissionari';
					|pl = 'Przyjęcie towarów od depozytariuszy/komisantów';
					|tr = 'Malların VMI''dan/konsinyeden teslim alınması'");
	ElsIf UseTransferToCustodyWithRightOfSale Then
		Title = NStr("vi = 'Tiếp nhận hàng hóa từ bên cho thuê kho';
					|ru = 'Поступление товаров от хранителей';
					|en = 'VMI return'; fa = 'برگشت VMI';
					|it = 'Ricezione articoli dai magazzini';
					|pl = 'Przyjęcie towarów od depozytariuszy';
					|tr = 'Malların VMI''dan teslim alınması'");
	Else
		Title = NStr("vi = 'Tiếp nhận hàng hóa từ bên nhận ký gửi';
					|ru = 'Поступление товаров от комиссионеров';
					|en = 'Receipt of goods from consignee'; fa = 'Receipt of goods from consignee';
					|it = 'Ricezione articoli dai commissionari';
					|pl = 'Przyjęcie towarów od komisantów';
					|tr = 'Malların konsinyelerden teslim alınması'");
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
		Items.ListOfReceiptOfGoodsFromCustodian.CurrentRow = ReferencesArrray[0];
		
		ShowValue(Undefined, ReferencesArrray[0]);
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
