
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	URL = "e1cib/list/Document.CashAccountReceiptNote";
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	InitializeBankingDetails();
	
	FiltersDetails = New Map;
	FiltersDetails.Insert("Organization", Type("CatalogRef.Companies"));
	AccessManagement.SetDynamicListFilters(CashAccountReceiptNotes, FiltersDetails);
	
	If Not Users.IsFullUser() Then
		PermittedOrganizations = AccessManagement.AllowedDynamicListValues("InformationRegister.ScheduleOfPayments", Type("CatalogRef.Companies"));
		If PermittedOrganizations <> Undefined Then
			ReceiptOrders.Parameters.SetParameterValue("AllowedValuesForTheOrganizationField", PermittedOrganizations);
		EndIf;
		AuthorizedSalesRegisters = AccessManagement.AllowedDynamicListValues("InformationRegister.ScheduleOfPayments", Type("CatalogRef.CashAccounts"));
		If AuthorizedSalesRegisters <> Undefined Then
			AuthorizedSalesRegisters.Add(Undefined);
			ReceiptOrders.Parameters.SetParameterValue("AllowedValuesOfTheCashRegisterField", AuthorizedSalesRegisters);
		EndIf;
	EndIf;
	
	CashAccountReceiptNotes.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.CashAccountReceiptNote"));
	
	SetDynamicListSelection();
	FormItemsManagement();
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.CashAccountReceiptNote"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.CashAccountReceiptNotesCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.CashAccountReceiptNotes,
		Metadata.Documents.CashAccountReceiptNote.FullName());
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "CashAccountReceiptNotes.Date", "Date");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ReceiptOrders.Date", "Date");
	
	SaveWorkingValuesOfFormFields(True);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// ExternalEquipmentMechanism
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	// End ExternalEquipmentMechanism
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	// ExternalEquipmentMechanism
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	// End ExternalEquipmentMechanism
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals"
		And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			// Convert it to the expected format beforehand
			If Parameter[1] = Undefined Then
				ProcessBarcodes(New CallbackDescription("PostProcessingAlertProcessing", ThisObject, New Structure("EventName, Parameter", EventName, Parameter)), New Structure("Barcode, Count", Parameter[0], 1));
				Return;
			Else
				ProcessBarcodes(New CallbackDescription("NotificationProcessingCompletion", ThisObject, New Structure("EventName", EventName)), New Structure("Barcode, Count", Parameter[1][1], 1));
				Return;
			EndIf;
		EndIf;
	EndIf;
	// End Peripherals

	
	HandlingFragmentAlerts(EventName);
EndProcedure

&AtClient
Procedure PostProcessingAlertProcessing(Result, AdditionalParameters) Export
    
    EventName = AdditionalParameters.EventName;
    Parameter = AdditionalParameters.Parameter;
    
    
    // We get the barcode from the main data;
    
    HandlingFragmentAlerts(EventName);

EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(Result, AdditionalParameters) Export
    
    EventName = AdditionalParameters.EventName;
    
    
    // We get the barcode from the additional data;
    
    HandlingFragmentAlerts(EventName);

EndProcedure

&AtClient
Procedure HandlingFragmentAlerts(Val EventName)
	
	If EventName = "Write_CashAccountReceiptNote" Then
		UpdateDynamicLists();
		Items.CashAccountReceiptNotes.Refresh();
	ElsIf EventName = "Conducting_Storno"
				Or EventName = "Write_ReversingEntry" Then 
				Items.CashAccountReceiptNotes.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization                 = Settings.Get("Organization");
	CashAccount                       = Settings.Get("CashAccount");
	Period                      = Settings.Get("Period");
	
	TransactionList              = Settings.Get("TransactionListReceipts");
	InitializeListOfReceiptOperations();
	If TransactionList <> Undefined Then
		For Each Operation In TransactionList Do
			If Operation.Check Then
				ListOperation_ = TransactionListReceipts.FindByValue(Operation.Value);
				If ListOperation_ <> Undefined Then
					ListOperation_.Check = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	BusinessOperationPresentation = TransactionListPresentation(TransactionListReceipts);
	
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CheckoutSelectionOnChange(Item)
	
	CheckoutChangesWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure ReceiptOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	Ref = Items.ReceiptOrders.CurrentData.Ref;
	If ValueIsFilled(Ref) Then
		ShowValue(Undefined, Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	UpdateDynamicLists();
	
EndProcedure

&AtClient
Procedure DateForReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateToBeReceivedWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DateToBeReceivedWhenChangedOnServer()
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure BusinessOperationSubmissionSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		
		TransactionListReceipts = ValueSelected;
		
	ElsIf TypeOf(ValueSelected) = Type("EnumRef.PaymentPlanningAreas") Then
		
		For Each ListItem In TransactionListReceipts Do
			ListItem.Check = (ListItem.Value = ValueSelected);
		EndDo;
	EndIf;
	
	BusinessOperationPresentation = TransactionListPresentation(TransactionListReceipts);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure BusinessOperationSubmissionSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
		New Structure("TransactionList, Title", TransactionListReceipts, NStr("vi = 'Căn cứ để thanh toán';
																				|ru = 'Основания платежа';
																				|en = 'Payment base objects'; fa = 'موضوعات مبنای پرداخت';
																				|it = 'Motivazioni del pagamento';
																				|pl = 'Podstawy płatności';
																				|tr = 'Ödeme gerekçesi'")), Item);
	
EndProcedure

&AtClient
Procedure BusinessOperationSubmissionSelectionClearing(Item, StandardProcessing)
	
	TransactionListReceipts.FillChecks(False);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure PayerSubmissionSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ReceiptOrders,
		"PayerPresentation",
		PayerPresentation,
		DataCompositionComparisonType.Contains,,
		ValueIsFilled(PayerPresentation));
		
	CommonClientServer.SetDynamicListFilterItem(
		CashAccountReceiptNotes,
		"PayerPresentation",
		PayerPresentation,
		DataCompositionComparisonType.Contains,,
		ValueIsFilled(PayerPresentation));
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashAccountReceiptNotes

&AtClient
Procedure CashAccountReceiptNotesOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure CashAccountReceiptNotesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	Else
		StandardProcessing = False;	
		TMCommonUseClient.ChangeElement(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure CashAccountReceiptNotesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure CashAccountReceiptNotesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Not Copy Then
		CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer"));
	Else
		TMCommonUseClient.CopyItem(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure CashReceiptOrdersToHold(Command)
	
	TMCommonUseClient.PostDocuments(Items.CashAccountReceiptNotes, Title);
	
EndProcedure

&AtClient
Procedure IncomingCashOrdersCancellationOfTheTransaction(Command)
	
	TMCommonUseClient.UndoPosting(Items.CashAccountReceiptNotes, Title);
	
EndProcedure

&AtClient
Procedure CashReceiptOrdersCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.CashAccountReceiptNotes);
	
EndProcedure

&AtClient
Procedure IncomingCashOrdersSetRemoveTheDeleteMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.CashAccountReceiptNotes, Title);
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Items.CashAccountReceiptNotes, Title);
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
	
	FilterItems1 = TMCommonUseClientServer.GetDynamicListSelection(CashAccountReceiptNotes).Items;
	
	PeriodSelectionGroup = CommonClientServer.CreateFilterItemGroup(
		FilterItems1, "PeriodSelectionGroup", DataCompositionFilterItemsGroupType.AndGroup);
			
	CommonClientServer.AddCompositionItem(
		PeriodSelectionGroup,
		"Date", 
		DataCompositionComparisonType.GreaterOrEqual, 
		Period.StartDate,
		,
		ValueIsFilled(Period.StartDate));
		
	CommonClientServer.AddCompositionItem(
		PeriodSelectionGroup,
		"Date", 
		DataCompositionComparisonType.LessOrEqual, 
		Period.EndDate,
		,
		ValueIsFilled(Period.EndDate));
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.CashAccountReceiptNotes, Title);

EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.CashAccountReceiptNotes, Title);

EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.CashAccountReceiptNotes, Title);

EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateCashReturnFromSupplier(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.RefundFromVendor"));
	
EndProcedure

&AtClient
Procedure CreateInpaymentFromCashRegister(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCashRegister"));
	
EndProcedure

&AtClient
Procedure CreateInpaymentFromBank(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromBank"));
	
EndProcedure

&AtClient
Procedure CreateCashWithdrawalFromBank(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashCollectionFromBank"));
	
EndProcedure

&AtClient
Procedure CreateInpaymentFromAnotherCashAccount(Command)

	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount"));

EndProcedure

&AtClient
Procedure CreateCashReturnFromAdvanceHolder(Command)

	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReturnByAdvanceHolder"));
	
EndProcedure

&AtClient
Procedure CreateInpaymentFromAnotherCompany(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromOtherCompany"));
	
EndProcedure

&AtClient
Procedure CreateCashReturnFromAnotherCompany(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany"));
	
EndProcedure

&AtClient
Procedure CreateOtherInpayment(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.OtherCashReceipt"));
	
EndProcedure

&AtClient
Procedure CreateInternalCashTransfer(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices"));
	
EndProcedure

&AtClient
Procedure CreateCurrencyConversion(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CurrencyConversion"));
	
EndProcedure

&AtClient
Procedure CreateLoanRepaymentReceipt(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromLoansRepayment"));
	
EndProcedure

&AtClient
Procedure CreateLoanRepaymentByCounterparty(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty"));
	
EndProcedure

&AtClient
Procedure CreateLoanRepaymentByEmployee(Command)
	
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.LoanRepaymentByEmployee"));
	
EndProcedure

&AtClient
Procedure CreateCashReceiptStatementFromReference(Command)
	
	CashClient.PayChartLines(Items.ReceiptOrders, "CashAccountReceiptNote");
	
EndProcedure

&AtClient
Procedure CreateARefundFromTheLandlord(Command)
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.RefundFromLessor"));
	Return;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.CashAccountReceiptNotes);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.CashAccountReceiptNotes, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.CashAccountReceiptNotes);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.CashAccountReceiptNotes);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure CheckoutChangesWhenChangesAreMadeOnServer()
	
	Organization = Catalogs.CashAccounts.GetCheckoutDetails(CashAccount).Organization;
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.CashAccountReceiptNote.EmptyRef"));
	Managers.Add(PredefinedValue("Document.CustomerCommercialInvoice.EmptyRef"));
	Managers.Add(PredefinedValue("Document.SalesOrder.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Val Notification, Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		
		Ref = ReferencesArrray[0];
		If TypeOf(Ref) = Type("DocumentRef.CashAccountReceiptNote") Then
			Items.CashAccountReceiptNotes.CurrentRow = Ref;
			Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.IncomingCashOrdersPage;
		EndIf;
		
		ShowValue(New CallbackDescription("ProcessBarcodesCompletion", ThisObject, New Structure("Data, Notification", Data, Notification)), Ref);
        Return;
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
	ProcessBarcodesFragment(Notification);
EndProcedure

&AtClient
Procedure ProcessBarcodesCompletion(AdditionalParameters) Export
    
    Data = AdditionalParameters.Data;
    Notification = AdditionalParameters.Notification;
    
    
    ProcessBarcodesFragment(Notification);

EndProcedure

&AtClient
Procedure ProcessBarcodesFragment(Val Notification)
    
    RunCallback(Notification);

EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceiptOrdersPaymentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReceiptOrders.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Items.CheckoutSelection.Visible = UseMultipleCashAccounts;
	Items.CashAccountReceiptNotesCreateInpaymentFromAnotherCashAccount.Visible =
		UseMultipleCashAccounts Or UseRetailSales;
		
	Items.CashAccountReceiptNotesCreateLoanRepaymentByEmployee.Visible = False;
	Items.CashAccountReceiptNotesCreateARefundFromTheLandlord.Visible = False;
	Items.CashAccountReceiptNotesCreateLoanRepaymentByEmployee.Visible = Not GetFunctionalOption("UsePayroll");
	Items.CashAccountReceiptNotesCreateARefundFromTheLandlord.Visible = True;
	
EndProcedure

#EndRegion

#Region CreatingDocuments

&AtClient
Procedure CreateCashReceiptOrder(BusinessOperation)
	
	BaseStructure = New Structure;
	BaseStructure.Insert("BusinessOperation", BusinessOperation);
	If ValueIsFilled(CashAccount) Then
		BaseStructure.Insert("CashAccount", CashAccount);
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", BaseStructure);
	OpenForm("Document.CashAccountReceiptNote.ObjectForm", ParametersStructure1, Items.CashAccountReceiptNotes);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure InitializeBankingDetails()
	
	UseMultipleCashAccounts = GetFunctionalOption("UseMultipleCashAccounts");
	UseRetailSales = GetFunctionalOption("UseRetailSales");
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "OrdersForReceiptCounterparty", "Visible", False);
	EndIf;
	UseLettersOfAuthority = GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt");
	UsePaymentRequests = GetFunctionalOption("UsePaymentRequests");
	UseProformaInvoices = GetFunctionalOption("UseCustomerCommercialInvoices");
	
	InitializeListOfReceiptOperations();
	
EndProcedure

&AtServer
Procedure SaveWorkingValuesOfFormFields(SaveUndefined = False)
	
	Common.CommonSettingsStorageSave("CurrentCompany", "", ?(SaveUndefined, Undefined, Organization));
	Common.CommonSettingsStorageSave("CurrentCashAccount", "", ?(SaveUndefined, Undefined, CashAccount));
	
EndProcedure

&AtServer
Function ArrayOfDynamicLists()

	ArrayOfLists = New Array;
	ArrayOfLists.Add(CashAccountReceiptNotes);
	ArrayOfLists.Add(ReceiptOrders);
	
	Return ArrayOfLists;

EndFunction

&AtServer
Procedure SetDynamicListSelection()
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	
	If ValueIsFilled(Organization)
		And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		Query = New Query("SELECT
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed");
		Query.SetParameter("Organization", Organization);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
		SetPrivilegedMode(False);
	EndIf;
	
	CashAccountList = New ValueList;
	CashAccountList.Add(Catalogs.CashAccounts.EmptyRef());
	If ValueIsFilled(CashAccount) Then
		CashAccountList.Add(CashAccount);
	EndIf;
	
	For Each DynamicList In ArrayOfDynamicLists() Do
		CommonClientServer.SetDynamicListFilterItem(
			DynamicList,
			"CashAccount",
			CashAccountList,
			DataCompositionComparisonType.InList,
			,
			ValueIsFilled(CashAccount));
		
		CommonClientServer.SetDynamicListFilterItem(
			DynamicList,
			"Organization",
			CompaniesList,
			DataCompositionComparisonType.InList,
			,
			ValueIsFilled(Organization));
	EndDo;
	
	Boundary = ?(ValueIsFilled(DateForReceipt), EndOfDay(DateForReceipt), Date('39990101'));
	ReceiptOrders.Parameters.SetParameterValue("PaymentDate", Boundary);
	
	PlanningAreas = New Array;
	For Each ListItem In TransactionListReceipts Do
		If ListItem.Check Then
			PlanningAreas.Add(ListItem.Value);
		EndIf;
	EndDo;
	CommonClientServer.SetDynamicListFilterItem(
		ReceiptOrders,
		"PlanningArea",
		PlanningAreas,
		DataCompositionComparisonType.InList,,
		PlanningAreas.Count());
	
	SetSelectionByPeriod();
	
	SaveWorkingValuesOfFormFields();
	
EndProcedure

&AtClient
Procedure UpdateDynamicLists()
	
	If Items.GroupPages.CurrentPage = Items.ReceiptOrderPage Then
		Items.ReceiptOrders.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeListOfReceiptOperations()
	
	TransactionListReceipts.Clear();
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.CustomersARAPAccounting);
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.ReturnsFromVendors);
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.CashInTransit);
	
	Items.BusinessOperationSubmissionSelection.ChoiceList.Clear();
	For Each Operation In TransactionListReceipts Do
		Items.BusinessOperationSubmissionSelection.ChoiceList.Add(Operation.Value, Operation.Presentation);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function TransactionListPresentation(TransactionList)
	
	TransactionListPresentation = "";
	For Each ListItem In TransactionList Do
		If ListItem.Check Then
			TransactionListPresentation = TransactionListPresentation
				+ ?(ValueIsFilled(TransactionListPresentation), ", ", "")
				+ ?(ValueIsFilled(ListItem.Presentation), ListItem.Presentation, ListItem.Value);
		EndIf;
	EndDo;
	
	Return TransactionListPresentation;
	
EndFunction



#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_DateForReceipt" Then
		DateForReceiptOnChange(Items.DateForReceipt);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
