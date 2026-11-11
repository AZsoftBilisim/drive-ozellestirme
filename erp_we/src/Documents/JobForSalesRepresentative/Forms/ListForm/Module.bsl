
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	SetListParameters();
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.QuickSelectionsRelevance.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Status", Status, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Supervisor_", Supervisor_, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "PresenceOfOrders", PresenceOfOrders, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.QuickSelectionsRelevance.ChoiceList, EventDate, QuickFilterStructure);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.FormCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);


	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetListParameters();
	
	If QuickFilterStructure=Undefined Or Not QuickFilterStructure.Property("Supervisor_") Then
		ValueFromSettings = Settings.Get("Supervisor_");
		If ValueIsFilled(ValueFromSettings) Then
			Supervisor_ = ValueFromSettings;
		EndIf;
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Status", Status, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Supervisor_", Supervisor_, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "PresenceOfOrders", PresenceOfOrders, QuickFilterStructure, Settings);
	
	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, Items.QuickSelectionsRelevance.ChoiceList, EventDate, QuickFilterStructure, Settings);
	
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

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QuickSelectionsStatusOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure QuickSelectionsCuratorOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Supervisor_", Supervisor_, DataCompositionComparisonType.Equal,, ValueIsFilled(Supervisor_));
	
EndProcedure

&AtClient
Procedure QuickSelectionsRelevanceOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Overdue", Relevance = "Overdue1", DataCompositionComparisonType.Equal,, ValueIsFilled(Relevance));
	
EndProcedure

&AtClient
Procedure QuickSelectionsOrderAvailabilityOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "PresenceOfOrders", PresenceOfOrders, DataCompositionComparisonType.Equal,, ValueIsFilled(PresenceOfOrders));
	
EndProcedure

&AtClient
Procedure QuickSelectionsRelevanceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"QuickSelectionsRelevance",
		"EventDate");
	
EndProcedure

&AtClient
Procedure QuickSelectionsRelevanceClearing(Item, StandardProcessing)
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
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

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
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
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.JobForSalesRepresentative.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetListParameters()
	
	List.Parameters.SetParameterValue("UpdateDate",CurrentSessionDate());
	List.Parameters.SetParameterValue("DateEmpty",'00010101000000');
	List.Parameters.SetParameterValue("OrdersArePlaced", NStr("vi = 'Đơn hàng đã lập';
																|ru = 'Заказы оформлены';
																|en = 'Orders are placed'; fa = 'سفارش‌ها ثبت شده‌اند';
																|it = 'Ordini compilati';
																|pl = 'Złożone zamówienia';
																|tr = 'Siparişler düzenlendi'"));
	List.Parameters.SetParameterValue("OrdersAreNotPlaced",NStr("vi = 'Đơn hàng chưa lập';
																|ru = 'Заказы не оформлены';
																|en = 'Orders are not placed'; fa = 'سفارش‌ها ثبت نشده‌اند';
																|it = 'Ordini non compilati';
																|pl = 'Niezłożone zamówienia';
																|tr = 'Siparişler düzenlenmedi'"));
	
EndProcedure

#EndRegion

#EndRegion
