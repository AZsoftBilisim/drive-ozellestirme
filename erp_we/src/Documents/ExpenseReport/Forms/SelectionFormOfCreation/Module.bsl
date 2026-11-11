
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Filter.Property("Organization", Organization);
	Parameters.Filter.Property("Department", Department);
	Parameters.Filter.Property("AdvanceHolder", AdvanceHolder);
	Parameters.Property("DocumentPurchases", DocumentPurchases);
	Parameters.Property("Currency", Currency);
	Parameters.Property("IDOfPurchasingDocumentForm", IDOfPurchasingDocumentForm);
	CommonClientServer.SetDynamicListFilterItem(
		List,"Date", Parameters.Date, DataCompositionComparisonType.GreaterOrEqual,, True, DataCompositionSettingsItemViewMode.Inaccessible);
		
	VisibilityOfCreationCommands = AccessRight("Insert", Metadata.Documents.ExpenseReport);
	Items.FormCreate.Visible = ValueIsFilled(DocumentPurchases) And VisibilityOfCreationCommands;
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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

&AtClient
Procedure Create(Command)
	
	Basis = New Structure;
	Basis.Insert("Organization", Organization);
	Basis.Insert("Department", Department);
	Basis.Insert("AdvanceHolder", AdvanceHolder);
	Basis.Insert("Currency", Currency);
	
	PurchaseDocumentsAll = New Array;
	PurchaseDocumentsAll.Add(DocumentPurchases);
	
	FormParameters = New Structure("Basis, PurchaseDocumentsAll, PurchasingEditableDocument",
		Basis, PurchaseDocumentsAll, DocumentPurchases);
	
	OpenForm("Document.ExpenseReport.ObjectForm", FormParameters, ThisObject,,,,
		New CallbackDescription("AfterCreatingAdvanceReport", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterCreatingAdvanceReport(Result, AdditionalParameters) Export
	
	If Result <> Undefined And ValueIsFilled(Result) Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

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
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
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

#EndRegion

#EndRegion
