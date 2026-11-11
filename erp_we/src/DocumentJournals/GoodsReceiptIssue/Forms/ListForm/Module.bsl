
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Query = New Query(
	"SELECT ALLOWED
	|	Warehouses.Ref AS Warehouse
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	(Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|			OR Warehouses.UseWarehouseManagemantSystemForGoodsReceipt)
	|	AND Warehouses.IsFolder = FALSE
	|
	|ORDER BY
	|	Warehouses.Description");
	TMCommonUseClientServer.AddSelectionParameter(Items.Warehouse, "Ref", Query.Execute().Unload().UnloadColumn("Warehouse"));

	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	WarehouseSpaceWhenServerChanges();
	
	Items.TheOrderBookCreateAReturnOfUnacceptedGoods.Visible = AccessRight("Insert", Metadata.Documents.GoodsReceiptNote);
	Items.NoteJournalCreateTransferNote.Visible = AccessRight("Insert", Metadata.Documents.GoodsTransferNote);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.NoteJournalCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "NoteJournal.Date", Items.NoteJournalDate.Name);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	WarehouseSpaceWhenServerChanges();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
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

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges();

EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNoteJournal

&AtClient
Procedure NoteJournalBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
	If UseWarerooms Then
		CreateTransferNoteClient();
	EndIf;
EndProcedure

&AtClient
Procedure NoteJournalOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure NoteJournalSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateTransferNote(Command)
	
	CreateTransferNoteClient();
	
EndProcedure

&AtClient
Procedure CreateReturnOfUnreceivedGoods(Command)
	
	Basis = New Structure;
	Basis.Insert("Warehouse", Warehouse);
	Basis.Insert("Premise", Premise);
	Basis.Insert("WarehouseOperation", PredefinedValue("Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient"));
	OpenForm("Document.GoodsReceiptNote.Form.DocumentForm", New Structure("Basis",Basis));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.NoteJournal);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.NoteJournal, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.NoteJournal);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.NoteJournal);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem


#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure WarehouseSpaceWhenServerChanges()
	
	If ValueIsFilled(Warehouse) Then
		SetFormFunctionalOptionParameters(New Structure("Warehouse", Warehouse));
		Items.GroupRoom.CurrentPage = Items.PageWareroom;
	Else
		SetFormFunctionalOptionParameters(New Structure("Warehouse", Undefined));
		Items.GroupRoom.CurrentPage = Items.BlankPage;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(Items, "NoteJournalStatus", "Visible",
		WarehousesServer.UseOrderStatuses(Warehouse));
	
	UseWarerooms = WarehousesServer.UseWarerooms(Warehouse);
	UseRoomSelection   = ValueIsFilled(Premise);
	
	CommonClientServer.SetDynamicListFilterItem(NoteJournal, "Warehouse", Warehouse, DataCompositionComparisonType.Equal,,True);
	
	FilterItemsGroup = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(NoteJournal).Items, "SelectionByRoom",
		DataCompositionFilterItemsGroupType.OrGroup);
																					
	If Not UseRoomSelection Then
		FilterItemsGroup.Use = False;
	Else
		FilterItemsGroup.Use = True;
		
		CommonClientServer.SetFilterItem(FilterItemsGroup, "SenderWareroom", Premise,
															DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetFilterItem(FilterItemsGroup, "ReceivingWareroom", Premise,
															DataCompositionComparisonType.Equal,,True);
	EndIf;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.GoodsReceiptNote.EmptyRef"));
	Managers.Add(PredefinedValue("Document.GoodsIssueNote.EmptyRef"));
	Managers.Add(PredefinedValue("Document.GoodsTransferNote.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		
		Ref = ReferencesArrray[0];
		Items.NoteJournal.CurrentRow = Ref;
		
		ShowValue(Undefined, Ref);
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure CreateTransferNoteClient()
	
	Basis = New Structure;
	Basis.Insert("Warehouse", Warehouse);
	Basis.Insert("SenderWareroom", Premise);
	
	OpenForm("Document.GoodsTransferNote.Form.DocumentForm",New Structure("Basis",Basis));
	
EndProcedure

#EndRegion