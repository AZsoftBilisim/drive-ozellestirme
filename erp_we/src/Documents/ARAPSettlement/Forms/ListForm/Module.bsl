
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	If TypeOf(Parameters.QuickFilterStructure) = Type("Structure") Then
		QuickFilterStructure = New Structure;
		QuickFilterStructure.Insert("Organization",        Catalogs.Companies.EmptyRef());
		QuickFilterStructure.Insert("CounterpartyDebtor",  Undefined);
		QuickFilterStructure.Insert("Creditor", Undefined);
		FillPropertyValues(QuickFilterStructure, Parameters.QuickFilterStructure);
		
		Organization        = QuickFilterStructure.Organization;
		CounterpartyDebtor  = QuickFilterStructure.CounterpartyDebtor;
		Creditor = QuickFilterStructure.Creditor;
		
		If ValueIsFilled(Organization) Then
			CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization,
				DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
		EndIf;
		If ValueIsFilled(CounterpartyDebtor) Then
			CommonClientServer.SetDynamicListFilterItem(List, "CounterpartyDebtor", CounterpartyDebtor,
				DataCompositionComparisonType.Equal,, ValueIsFilled(CounterpartyDebtor));
		EndIf;
		If ValueIsFilled(Creditor) Then
			CommonClientServer.SetDynamicListFilterItem(List, "Creditor", Creditor,
				DataCompositionComparisonType.Equal,, ValueIsFilled(Creditor));
		EndIf;
	EndIf;
	
	URL = "e1cib/list/" + Metadata.Documents.ARAPSettlement.FullName();
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	Items.List.ChangeRowSet = AccessRight("Update", Metadata.Documents.ARAPSettlement);
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.ARAPSettlement"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	ConfigureDocumentManagementButtons();
	If Parameters.Property("CurrentRow") And ValueIsFilled(Parameters.CurrentRow) Then
		Parameters.CurrentRow = InformationRegisters.DocumentsRegistry.DocumentRecordingKey(Parameters.CurrentRow);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.ARAPSettlement"));
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		Metadata.Documents.ARAPSettlement.FullName());
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
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
	
	If EventName = "Conducting_Storno"
			Or EventName = "Write_ReversingEntry"
			Or EventName = "Write_ARAPSettlement" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization = Settings.Get("Organization");
	CounterpartyDebtor  = Settings.Get("CounterpartyDebtor");
	Creditor = Settings.Get("Creditor");
	Period = Settings.Get("Period");
	
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(List, "CounterpartyDebtor", CounterpartyDebtor, DataCompositionComparisonType.Equal,, ValueIsFilled(CounterpartyDebtor));
	CommonClientServer.SetDynamicListFilterItem(List, "Creditor", Creditor, DataCompositionComparisonType.Equal,, ValueIsFilled(Creditor));
	
	SetSelectionByPeriod();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure CounterpartyDebtorSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "CounterpartyDebtor", CounterpartyDebtor, DataCompositionComparisonType.Equal,, ValueIsFilled(CounterpartyDebtor));
	
EndProcedure

&AtClient
Procedure CounterpartyLenderSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Creditor", Creditor, DataCompositionComparisonType.Equal,, ValueIsFilled(Creditor));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		StructureFilter = New Structure;
		StructureFilter.Insert("Organization", Organization);
		StructureFilter.Insert("CounterpartyDebtor", CounterpartyDebtor);
		StructureFilter.Insert("Creditor", Creditor);
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		OpenForm("Document.ARAPSettlement.ObjectForm", ParametersStructure1, Items.List);
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure


&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Items.List, Title);
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Period = ValueSelected;
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		Period.EndDate);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ARAPSettlement.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

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

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	AccessRightInsert = AccessRight("Insert", Metadata.Documents.ARAPSettlement);
	AccessRightUpdate = AccessRight("Update", Metadata.Documents.ARAPSettlement);
	
	ItemArray = New Array;
	ItemArray.Add("ListCopy");
	ItemArray.Add("ListContextMenuCopy");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", AccessRightInsert);
	
	ItemArray = New Array;
	ItemArray.Add("ListContextMenuSetDeletionMark");
	ItemArray.Add("ListContextMenuPost");
	ItemArray.Add("ListContextMenuUndoPosting");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", AccessRightUpdate);
	
EndProcedure

#EndRegion
