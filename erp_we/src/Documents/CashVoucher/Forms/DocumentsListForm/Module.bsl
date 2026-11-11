
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	URL = "e1cib/list/Document.CashVoucher";
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UsePayroll                  = Constants.UsePayroll.Get();
	//++ WE
	PayrollAndHumanResourcesWE                  	= GetFunctionalOption("PayrollAndHumanResourcesWE");
	//-- WE
	UsePaymentRequests = GetFunctionalOption("UsePaymentRequests");
	UseMultipleCashAccounts                       = GetFunctionalOption("UseMultipleCashAccounts");
	UseRetailSales                    = GetFunctionalOption("UseRetailSales");
	UseTheLease = NonCurrentAssets.VNAManagementIsUsed();
	BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount;
	
	InitializeListOfPaymentOperations();
	
	FiltersDetails = New Map;
	FiltersDetails.Insert("Organization", Type("CatalogRef.Companies"));
	AccessManagement.SetDynamicListFilters(CashAccountIssueNotes, FiltersDetails);
	
	If Not Users.IsFullUser() Then
		PermittedOrganizations = AccessManagement.AllowedDynamicListValues(
			"InformationRegister.ScheduleOfPayments", Type("CatalogRef.Companies"));
		If PermittedOrganizations <> Undefined Then
			OrdersPendingPayment.Parameters.SetParameterValue("AllowedValuesForTheOrganizationField", PermittedOrganizations);
			PaymentRequests.Parameters.SetParameterValue("AllowedValuesForTheOrganizationField", PermittedOrganizations);
		EndIf;
		AuthorizedSalesRegisters = AccessManagement.AllowedDynamicListValues(
			"InformationRegister.ScheduleOfPayments", Type("CatalogRef.CashAccounts"));
		If AuthorizedSalesRegisters <> Undefined Then
			AuthorizedSalesRegisters.Add(Undefined);
			OrdersPendingPayment.Parameters.SetParameterValue("AllowedValuesOfTheCashRegisterField", AuthorizedSalesRegisters);
			PaymentRequests.Parameters.SetParameterValue("AllowedValuesOfTheCashRegisterField", AuthorizedSalesRegisters);
		EndIf;
	EndIf;
	
	CashAccountIssueNotes.Parameters.SetParameterValue("UsingOfCheckIsAnOption", False);
	CashAccountIssueNotes.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.CashVoucher"));
	
	SetParametersForDynamicLists();
	SetDynamicListSelection();
	FormItemsManagement();
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.CashVoucher"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.CashAccountIssueNotesCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.CashAccountIssueNotes,
		Metadata.Documents.CashVoucher.FullName());
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "CashAccountIssueNotes.Date", "Date");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "OrdersPendingPayment.Date", "Date");
	
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
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals"
		And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			// Convert it to the expected format beforehand
			If Parameter[1] = Undefined Then
				ProcessBarcodes(New Structure("Barcode, Count", Parameter[0], 1)); // We get the barcode from the main data
			Else
				ProcessBarcodes(New Structure("Barcode, Count", Parameter[1][1], 1)); // We get the barcode from the additional data
			EndIf;
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_CashVoucher" Then
		UpdateDynamicLists();
		Items.CashAccountIssueNotes.Refresh();
	ElsIf EventName = "Conducting_Storno"
				Or EventName = "Write_ReversingEntry" Then 
				Items.CashAccountIssueNotes.Refresh();
	EndIf;

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

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization              = Settings.Get("Organization");
	CashAccount                    = Settings.Get("CashAccount");
	Employee_                 = Settings.Get("Employee_");
	BusinessOperation    = Settings.Get("BusinessOperation");
	PaymentDate              = Settings.Get("PaymentDate");
	TransactionList           = Settings.Get("TransactionListPayments");
	Period                   = Settings.Get("Period");
	
	InitializeListOfPaymentOperations();
	If TransactionList <> Undefined Then
		For Each Operation In TransactionList Do
			If Operation.Check Then
				ListOperation_ = TransactionListPayments.FindByValue(Operation.Value);
				If ListOperation_ <> Undefined Then
					ListOperation_.Check = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	TransactionListPaymentsPresentation = TransactionListPaymentsPresentation(TransactionListPayments);
	
	SetDynamicListSelection();
	
	EmployeeBenefits = (BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee);
	Items.SalaryPaymentEmployeeSelection.Enabled = EmployeeBenefits;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	UpdateDynamicLists();
	
EndProcedure

&AtClient
Procedure PaymentRequestsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(Undefined, Items.PaymentRequests.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure OrdersPendingPaymentSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(Undefined, Items.OrdersPendingPayment.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure CheckoutSelectionOnChange(Item)
	
	CheckoutChangesWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure PaymentOrdersPaymentDateSelectionOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	SetParametersForDynamicLists();
EndProcedure

&AtClient
Procedure OrdersToBePaidPaymentDateSelectionOnChange(Item)
	SetParametersForDynamicLists();
EndProcedure

&AtClient
Procedure ListOfTransactionsToBePaidSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If UsePaymentRequests Then
		OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
			New Structure("TransactionList", TransactionListPayments), Item);
	Else
		OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
			New Structure("TransactionList, Title", TransactionListPayments, NStr("vi = 'Căn cứ để thanh toán';
																					|ru = 'Основания платежа';
																					|en = 'Payment base objects'; fa = 'موضوعات مبنای پرداخت';
																					|it = 'Motivazioni del pagamento';
																					|pl = 'Podstawy płatności';
																					|tr = 'Ödeme gerekçesi'")), Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOfTransactionsToBePaidSelectionClearing(Item, StandardProcessing)
	
	TransactionListPayments.FillChecks(False);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure ListOfTransactionsToBePaidSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		
		TransactionListPayments = ValueSelected;
	Else
		
		For Each ListItem In TransactionListPayments Do
			ListItem.Check = (ListItem.Value = ValueSelected);
		EndDo;
	EndIf;
	
	TransactionListPaymentsPresentation = TransactionListPaymentsPresentation(TransactionListPayments);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure SalaryPaymentSelection(Item, RowSelected, Field, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure SalaryPaymentEmployeeSelectionOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure SalaryPaymentPayrollPaymentOnChange(Item)
	
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashAccountIssueNotes

&AtClient
Procedure CashAccountIssueNotesOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure CashAccountIssueNotesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Not Copy Then
		CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.PaymentToVendor"));
	Else
		TMCommonUseClient.CopyItem(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure CashAccountIssueNotesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure CashAccountIssueNotesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	Else
		StandardProcessing = False;	
		TMCommonUseClient.ChangeElement(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure SpendingCashOrdersToHold(Command)
	
	TMCommonUseClient.PostDocuments(Items.CashAccountIssueNotes, Title);
	
EndProcedure

&AtClient
Procedure ExpenditureCashOrdersCancellationOfTheEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.CashAccountIssueNotes, Title);
	
EndProcedure

&AtClient
Procedure CashExpenseOrdersCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.CashAccountIssueNotes);
	
EndProcedure

&AtClient
Procedure ExpenseCashOrdersSetRemoveTheDeleteMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.CashAccountIssueNotes, Title);

EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Items.CashAccountIssueNotes, Title);
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
	
	FilterItems1 = TMCommonUseClientServer.GetDynamicListSelection(CashAccountIssueNotes).Items;
	
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
	
	TMCommonUseClient.UndoPosting(Items.CashAccountIssueNotes, Title);

EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.CashAccountIssueNotes, Title);

EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.CashAccountIssueNotes, Title);

EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateCashPaymentToAdvanceHolder(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder"));
EndProcedure

&AtClient
Procedure CreateARefundToTheCustomer(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.RefundToCustomer"));
EndProcedure

&AtClient
Procedure CreateOtherCashPayment(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.OtherCashIssue"));
EndProcedure

&AtClient
Procedure CreatePassCashToBank(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.CashDepositToBankAccount"));
EndProcedure

&AtClient
Procedure CreateACashCollection(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.CashCollectionToBank"));
EndProcedure

&AtClient
Procedure CreateCashPaymentToAnotherCashAccount(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.CashIssueToAnotherCashAccount"));
EndProcedure

&AtClient
Procedure CreateCashPaymentToCashRegister(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.CashIssueToCashRegister"));
EndProcedure

&AtClient
Procedure CreateIntercompanyPayment(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany"));
EndProcedure

&AtClient
Procedure CreateCashReturnToAnotherCompany(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany"));
EndProcedure

&AtClient
Procedure CreateInternalCashTransfer(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices"));
EndProcedure

&AtClient
Procedure CreateCurrencyConversion(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.CurrencyConversion"));
EndProcedure

&AtClient
Procedure CreateSalaryPaymentViaCashDesk(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentViaCashAccount"));
EndProcedure

&AtClient
Procedure CreateAPaymentStatementByTheDistributor(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentByDistributor"));
EndProcedure

&AtClient
Procedure CreateSalaryPaymentToEmployee(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentToEmployee"));
EndProcedure

&AtClient
Procedure CreatePaymentForLoans(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived"));
EndProcedure

&AtClient
Procedure CreateLoanIssueToCounterparty(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.CashIssueAsLoanToCounterparty"));
EndProcedure

&AtClient
Procedure CreateALoanToAnEmployee(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.CashIssueAsLoanToEmployee"));
EndProcedure

&AtClient
Procedure CreateAPaymentToTheLandlord(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.PaymentToLessor"));
EndProcedure

&AtClient
Procedure PayForDocument(Command)
	
	CashClient.PayChartLines(Items.OrdersPendingPayment, "CashVoucher");
	
EndProcedure

&AtClient
Procedure PayRequest(Command)
	
	CashClient.PayChartLines(Items.PaymentRequests, "CashVoucher");
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.CashAccountIssueNotes);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.CashAccountIssueNotes, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.CashAccountIssueNotes);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.CashAccountIssueNotes);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


&AtClient
Procedure PaySalary(Command)
	
	Return;
	
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
	Managers.Add(PredefinedValue("Document.CashVoucher.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		
		Ref = ReferencesArrray[0];
		If TypeOf(Ref) = Type("DocumentRef.CashVoucher") Then
			Items.CashAccountIssueNotes.CurrentRow = Ref;
			Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.ExpenseCashOrdersPage;
		EndIf;
		
		ShowValue(, Ref);
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrdersPendingPaymentPaymentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrdersPendingPayment.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentRequestsPaymentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentRequests.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Items.SalaryPaymentPage.Visible                  = False;
	Items.PaymentOrderPage.Visible             = UsePaymentRequests;
	Items.OrdersForPaymentPage.Visible                    = Not UsePaymentRequests;
	Items.CheckoutSelection.Visible                               = UseMultipleCashAccounts;
	Items.CreateAPaymentToTheLandlord.Visible                = UseTheLease;
	Items.CreateALoanToAnEmployee.Visible             = False;
	
	//++ WE
	If Not GetFunctionalOption("RFPaymentsSupport") Then
		Items.CreateAPaymentStatementByTheDistributor.Visible = Not PayrollAndHumanResourcesWE;
		Items.CreateSalaryPaymentToEmployee.Visible 	= Not PayrollAndHumanResourcesWE;
	EndIf;
	//-- WE
EndProcedure

#EndRegion

#Region CreatingDocuments

&AtClient
Procedure CreateSpendingCashOrder(BusinessOperation)
	
	BaseStructure = New Structure;
	BaseStructure.Insert("BusinessOperation", BusinessOperation);
	If ValueIsFilled(CashAccount) Then
		BaseStructure.Insert("CashAccount", CashAccount);
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", BaseStructure);
	OpenForm("Document.CashVoucher.ObjectForm", ParametersStructure1, Items.CashAccountIssueNotes);

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure InitializeListOfPaymentOperations()
	
	TransactionList = New ValueList;
	
	If UsePaymentRequests Then
		Operations = Enums.BusinessTransactions;
		TransactionList.Add(Operations.PaymentToVendor);
		TransactionList.Add(Operations.RefundToCustomer);
		TransactionList.Add(Operations.IssueCashToAdvanceHolder, NStr("vi = 'Chi tạm ứng';
																		|ru = 'Выдача подотчетнику';
																		|en = 'Payment to advance holder'; fa = 'پرداخت به تنخواه‌گردان';
																		|it = 'Rilasciare alla persona responsabile';
																		|pl = 'Wydanie osobie rozliczającej';
																		|tr = 'Avans sahibine transfer'"));
		TransactionList.Add(Operations.CustomsPayment, NStr("vi = 'Thanh toán hải quan';
															|ru = 'Таможенный платеж';
															|en = 'Customs payment'; fa = 'پرداخت گمرکی';
															|it = 'Dazio';
															|pl = 'Płatność celna';
															|tr = 'Gümrük ödemesi'"));
		TransactionList.Add(Operations.CurrencyConversion);
		TransactionList.Add(Operations.CashPaymentToAnotherCompany, NStr("vi = 'Thanh toán cho doanh nghiệp khác';
																		|ru = 'Оплата в другую организацию';
																		|en = 'Intercompany payment'; fa = 'پرداخت درون‌گروهی';
																		|it = 'Pagamento ad un''altra organizzazione';
																		|pl = 'Płatność do innej firm';
																		|tr = 'Başka bir iş yerine ödeme'"));
		TransactionList.Add(Operations.RefundToAnotherCompany, NStr("vi = 'Trả lại cho doanh nghiệp khác';
																	|ru = 'Возврат в другую организацию';
																	|en = 'Return to another company'; fa = 'برگشت به شرکت دیگر';
																	|it = 'Reso in un''altra organizzazione';
																	|pl = 'Zwrot do innej firmy';
																	|tr = 'Başka bir iş yerine iade'"));
		TransactionList.Add(Operations.TransferCashBetweenCompanyAndItsBranchOffices, NStr("vi = 'Chuyển tiền nội bộ';
																							|ru = 'Внутренняя передача';
																							|en = 'Internal transfer'; fa = 'انتقال داخلی';
																							|it = 'Trasmissione interna';
																							|pl = 'Przekazanie wewnętrzne';
																							|tr = 'İç aktarım'"));
		TransactionList.Add(Operations.SalaryPayment);
		TransactionList.Add(Operations.OtherExpenses);
		TransactionList.Add(Operations.OtherCashIssue, NStr("vi = 'Chi khác';
															|ru = 'Прочая выдача';
															|en = 'Other issue'; fa = 'Other issue';
															|it = 'Altri rilasci';
															|pl = 'Inne wydanie';
															|tr = 'Diğer aktarma'"));
		TransactionList.Add(Operations.PaymentOnLoansAndBorrowingsReceived);
		TransactionList.Add(Operations.TransferToDeposits);
		TransactionList.Add(Operations.CashIssueAsLoanToCounterparty);
	Else
		TransactionList.Add(Enums.PaymentPlanningAreas.VendorsARAPAccounting);
		TransactionList.Add(Enums.PaymentPlanningAreas.ReturnsToCustomers);
		TransactionList.Add(Enums.PaymentPlanningAreas.CashInTransit);
	EndIf;
	
	For Each Operation In TransactionListPayments Do
		If Operation.Check Then
			ListOperation_ = TransactionList.FindByValue(Operation.Value);
			If ListOperation_ <> Undefined Then
				ListOperation_.Check = True;
			EndIf;
		EndIf;
	EndDo;
	
	TransactionListPayments = TransactionList;
	
	Items.ListOfTransactionsToBePaidSelection.ChoiceList.Clear();
	For Each Operation In TransactionListPayments Do
		Items.ListOfTransactionsToBePaidSelection.ChoiceList.Add(Operation.Value, Operation.Presentation);
	EndDo;
	Items.OrdersListOfOperationsToBePaidSelection.ChoiceList.Clear();
	For Each Operation In TransactionListPayments Do
		Items.OrdersListOfOperationsToBePaidSelection.ChoiceList.Add(Operation.Value, Operation.Presentation);
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveWorkingValuesOfFormFields(SaveUndefined = False)
	
	Common.CommonSettingsStorageSave("CurrentCompany", "", ?(SaveUndefined, Undefined, Organization));
	Common.CommonSettingsStorageSave("CurrentCashAccount", "", ?(SaveUndefined, Undefined, CashAccount));
	
EndProcedure

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
	CashAccountList.Add(CashAccount);
	CashAccountList.Add(Catalogs.CashAccounts.EmptyRef());
	
	For Each DynamicList In ArrayOfDynamicLists() Do
		
		CommonClientServer.SetDynamicListFilterItem(
			DynamicList,
			"Organization",
			CompaniesList,
			DataCompositionComparisonType.InList,,
			ValueIsFilled(Organization));
			
		CommonClientServer.SetDynamicListFilterItem(
			DynamicList,
			"CashAccount",
			CashAccountList,
			DataCompositionComparisonType.InList,,
			ValueIsFilled(CashAccount));
	EndDo;
	
	SetSelectionByPeriod();
	
	SaveWorkingValuesOfFormFields();
	
	If UsePaymentRequests Then
		
		SelectedOperations = New Array;
		For Each ListItem In TransactionListPayments Do
			If ListItem.Check Then
				SelectedOperations.Add(ListItem.Value);
			EndIf;
		EndDo;
		
		CommonClientServer.SetDynamicListFilterItem(
			PaymentRequests,
			"BusinessOperation",
			SelectedOperations,
			DataCompositionComparisonType.InList,,
			SelectedOperations.Count());
	Else
		
		PlanningAreas = New Array;
		For Each ListItem In TransactionListPayments Do
			If ListItem.Check Then
				PlanningAreas.Add(ListItem.Value);
			EndIf;
		EndDo;
		CommonClientServer.SetDynamicListFilterItem(
			OrdersPendingPayment,
			"PlanningArea",
			PlanningAreas,
			DataCompositionComparisonType.InList,,
			PlanningAreas.Count());
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForDynamicLists()
	
	Boundary = ?(ValueIsFilled(PaymentDate), PaymentDate, Date('39990101'));
	PaymentRequests.Parameters.SetParameterValue("PaymentDate", Boundary);
	OrdersPendingPayment.Parameters.SetParameterValue("PaymentDate", Boundary);
	
EndProcedure

&AtClient
Procedure UpdateDynamicLists()
	
	If Items.GroupPages.CurrentPage = Items.PaymentOrderPage Then
		Items.PaymentRequests.Refresh();
	ElsIf Items.GroupPages.CurrentPage = Items.OrdersForPaymentPage Then
		Items.OrdersPendingPayment.Refresh();
	ElsIf Items.GroupPages.CurrentPage = Items.SalaryPaymentPage Then
		Items.SalaryPayment.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Function ArrayOfDynamicLists()
	
	ArrayOfLists = New Array;
	ArrayOfLists.Add(CashAccountIssueNotes);
	ArrayOfLists.Add(PaymentRequests);
	ArrayOfLists.Add(OrdersPendingPayment);
	ArrayOfLists.Add(SalaryPayment);
	
	Return ArrayOfLists;
	
EndFunction

&AtClientAtServerNoContext
Function TransactionListPaymentsPresentation(TransactionList)
	
	TransactionListPaymentsPresentation = "";
	For Each ListItem In TransactionList Do
		If ListItem.Check Then
			TransactionListPaymentsPresentation = TransactionListPaymentsPresentation
				+ ?(ValueIsFilled(TransactionListPaymentsPresentation), ", ", "")
				+ ?(ValueIsFilled(ListItem.Presentation), ListItem.Presentation, ListItem.Value);
		EndIf;
	EndDo;
	
	Return TransactionListPaymentsPresentation;
	
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
	If Item.Name = "sh_ShamsiInput_F_PaymentDate" Then
		PaymentOrdersPaymentDateSelectionOnChange(Items.PaymentOrdersPaymentDateSelection);
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
