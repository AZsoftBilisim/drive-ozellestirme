
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ConfigureDependentFormElements();
	SetAvailability(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetFilters(ThisObject);
	SetAvailability(ThisObject);

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

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetFilters(ThisObject);

EndProcedure

&AtClient
Procedure FilterOperatingBusinessUnitOnChange(Item)
	
	SetFilters(ThisObject);

EndProcedure

&AtClient
Procedure FilterClassOnChange(Item)
	
	SetFilters(ThisObject);
	SetAvailability(ThisObject);

EndProcedure

&AtClient
Procedure FilterSubclassOnChange(Item)
	
	SetFilters(ThisObject);

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
Procedure SetTheStatusToBeEdited(Command)
	
	SetStatus("IsBeingEdited", NStr("vi = 'Được soạn';
									|ru = 'Редактируется';
									|en = 'Under development'; fa = 'در حال توسعه';
									|it = 'Viene modificato';
									|pl = 'Under development';
									|tr = 'Düzenleniyor'"));

EndProcedure

&AtClient
Procedure SetTheStatusInOperation(Command)
	
	SetStatus("InOperation", NStr("vi = 'Đang vận hành';
									|ru = 'В эксплуатации';
									|en = 'In operation'; fa = 'در حال بهره‌برداری';
									|it = 'In esercizio';
									|pl = 'W eksploatacji';
									|tr = 'Kullanımda'"));

EndProcedure

&AtClient
Procedure SetTheLiquidatedStatus(Command)
	
	SetStatus("Disposed", NStr("vi = 'Thanh lý';
								|ru = 'Ликвидирован';
								|en = 'Decommissioned'; fa = 'از رده خارج‌شده';
								|it = 'Liquidato';
								|pl = 'Zlikwidowany';
								|tr = 'Tasfiye Edildi'"));

EndProcedure

&AtClient
Procedure ChangeTheClass(Command)
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	RMManagementClient.ChangeClassOfOperationalObjects(HighlightedLinks);
	Return; // there is an empty handler in the SC
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List, List);
	
EndProcedure

#Region StandardSubsystems

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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure ConfigureDependentFormElements()
	
	If Not GetFunctionalOption("UseRMManagement")
		Or Not AccessRight("Edit", Metadata.Catalogs.Assets) Then
		
		Items.SetTheStatusToBeEdited.Visible = False;
		Items.SetTheStatusInOperation.Visible = False;
		Items.SetTheLiquidatedStatus.Visible = False;
		Items.ChangeTheClass.Visible = False;
		Items.ChangeSelectedItems.Visible = False;
	EndIf;
		
	If Not GetFunctionalOption("UseBusinessUnits") Then
		Items.RMBusinessUnit.Visible = False;
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure SetFilters(Form)
	
	List = Form.List;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Form.FilterStatus,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterStatus));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"OperatingBusinessUnit",
		Form.FilterOperatingBusinessUnit,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterOperatingBusinessUnit));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Class",
		Form.FilterClass,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterClass));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Subclass",
		Form.FilterSubclass,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterSubclass));
	
EndProcedure

&AtClient
Procedure SetStatus(StatusValue, StatusPresentation)
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	RMManagementClient.EstablishStatusOfObjectsOfOperation(StatusValue, StatusPresentation, HighlightedLinks);
	Return; // there is an empty handler in the SC

EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
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
	Managers.Add(PredefinedValue("Catalog.Assets.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClientAtServerNoContext
Procedure SetAvailability(Form)
	
	Items = Form.Items;
	Items.FilterSubclass.ReadOnly = Not ValueIsFilled(Form.FilterClass);
	
EndProcedure

#EndRegion