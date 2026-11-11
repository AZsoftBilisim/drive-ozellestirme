
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	FormItemsManagement();
	
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.PaymentCardTransaction"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	URL = "e1cib/list/Document.PaymentCardTransaction";
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.PaymentCardTransaction"));
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		Metadata.Documents.PaymentCardTransaction.FullName());
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "PaymentRequests.Date", Items.PaymentRequestsDate.Name);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	SaveWorkingValuesOfFormFields(True);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	UseOrdersForPayment = GetFunctionalOption("UseSalesOrders")
							And (GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption")
							Or GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption"));
	UsePaymentRequests = GetFunctionalOption("UsePaymentRequests");
	
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
	
	If EventName = "Write_PaymentCardTransaction"
			Or EventName = "Conducting_Storno"
			Or EventName = "Write_ReversingEntry" Then
		UpdateDynamicLists();
	EndIf;

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization           = Settings.Get("Organization");
	POSTerminal = Settings.Get("AcquiringContract");
	POSTerminal = Settings.Get("POSTerminal");
	Period = Settings.Get("Period");
	
	EstablishConnectionsOfAcquiringTerminalParameters();
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	UpdateDynamicLists();
	
EndProcedure

&AtClient
Procedure AcquiringAgreementSelectionOnChange(Item)
	
	AcquiringAgreementIsValidWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure AcquiringAgreementIsValidWhenChangedOnServer()
	
	Organization = Catalogs.AcquiringContracts.ContractDetails_(AcquiringContract).Organization;
	
	EstablishConnectionsOfAcquiringTerminalParameters();
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure AcquiringTerminalSelectionOnChange(Item)
	
	AcquiringTerminalSelectionWhenChangesAreMadeOnServer()
	
EndProcedure

&AtServer
Procedure AcquiringTerminalSelectionWhenChangesAreMadeOnServer()
	
	Organization = Catalogs.POSTerminals.GetDetailsOfAcquiringTerminal(POSTerminal).Organization;
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		
		FillingData = New Structure;
		FillingData.Insert("AcquiringContract", AcquiringContract);
		FillingData.Insert("POSTerminal", POSTerminal);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("FillingValues", FillingData);
		
		OpenForm("Document.PaymentCardTransaction.ObjectForm", OpeningParameters, Items.List);
		
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
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

&AtClient
Procedure CreateARefundToTheCustomer()
	
	Basis = New Structure;
	Basis.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.RefundToCustomer"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Basis", Basis);
	
	OpenForm("Document.PaymentCardTransaction.ObjectForm", FormParameters, Items.List);
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.PaymentCardTransaction.EmptyRef"));
	Managers.Add(PredefinedValue("Document.SalesOrder.EmptyRef"));
	Managers.Add(PredefinedValue("Document.CustomerCommercialInvoice.EmptyRef"));
	Managers.Add(PredefinedValue("Document.PaymentRequest.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		
		Ref = ReferencesArrray[0];
		If TypeOf(Ref) = Type("DocumentRef.PaymentCardTransaction") Then
			Items.List.CurrentRow = Ref;
			Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.PaymentCardTransactionsPage;
		ElsIf TypeOf(Ref) = Type("DocumentRef.SalesOrder") Then
			Items.OrdersPendingPayment.CurrentRow = Ref;
			Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.OrdersForPaymentPage;
		ElsIf TypeOf(Ref) = Type("DocumentRef.PaymentRequest") Then
			Items.PaymentRequests.CurrentRow = Ref;
			Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.PaymentOrderPage;
		EndIf;
		
		ShowValue(Undefined, Ref);
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	If Not GetFunctionalOption("UseSalesOrders")
	   And Not GetFunctionalOption("UsePaymentRequests") Then
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	If Not GetFunctionalOption("UseSalesOrders") Then
		Items.OrdersPendingPaymentAmountToPay.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function ArrayOfDynamicLists()

	ArrayOfLists = New Array;
	ArrayOfLists.Add(List);
	ArrayOfLists.Add(OrdersPendingPayment);
	ArrayOfLists.Add(PaymentRequests);
	
	Return ArrayOfLists;

EndFunction

&AtServer
Procedure EstablishConnectionsOfAcquiringTerminalParameters()
	
	If ValueIsFilled(AcquiringContract) Then
		ChoiceParameterLinks = New Array;
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.Owner", "AcquiringContract"));
		Items.POSTerminal.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	Else
		Items.POSTerminal.ChoiceParameterLinks = New FixedArray(New Array);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection()
	
	For Each DynamicList In ArrayOfDynamicLists() Do
		CommonClientServer.SetDynamicListFilterItem(
			DynamicList,
			"Organization",
			Organization,
			DataCompositionComparisonType.Equal,,
			ValueIsFilled(Organization));
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"AcquiringContract",
		AcquiringContract,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(AcquiringContract));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"POSTerminal",
		POSTerminal,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(POSTerminal));
	
	SetSelectionByPeriod();
	
	SaveWorkingValuesOfFormFields();
	
EndProcedure

&AtClient
Procedure UpdateDynamicLists()
	
	Items.List.Refresh();
	
	If UseOrdersForPayment Then
		Items.OrdersPendingPayment.Refresh();
	EndIf;
	
	If UsePaymentRequests Then
		Items.PaymentRequests.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveWorkingValuesOfFormFields(SaveUndefined = False)
	
	Common.CommonSettingsStorageSave(
		"CurrentCompany", "", ?(SaveUndefined, Undefined, Organization));
	Common.CommonSettingsStorageSave(
		"CurrentAcquiringAgreement", "", ?(SaveUndefined, Undefined, AcquiringContract));
	Common.CommonSettingsStorageSave(
		"CurrentPOSTerminal", "", ?(SaveUndefined, Undefined, POSTerminal));
	
EndProcedure

#EndRegion

#EndRegion
