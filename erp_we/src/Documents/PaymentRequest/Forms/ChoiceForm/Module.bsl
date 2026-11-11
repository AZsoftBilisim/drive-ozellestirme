
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter")
	   And Parameters.Filter.Property("Recipient")
	   And Not ValueIsFilled(Parameters.Filter.Recipient) Then
		Parameters.Filter.Delete("Recipient");
	EndIf;
	
	NoFilter = False;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Parameters, "OnlyBalance") Then
		OnlyBalance = Parameters.OnlyBalance;
	Else
		NoFilter = True;
	EndIf;
	
	Items.OnlyBalance.Visible = Not NoFilter;
	
	If Not NoFilter Then
		
		FillFilterParameters();
		LimitListOfRequests();
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnlyBalanceOnChange(Item)
	
	OnlyBalancesOnChangeAtServer();
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure OnlyBalancesOnChangeAtServer()

	LimitListOfRequests();

EndProcedure

&AtServer
Procedure FillFilterParameters()

	FilterParameters = NewRequestsFilterParameters();
	
	For Each FilterElement In Parameters.Filter Do
		
		If FilterParameters.Property(FilterElement.Key)
			And ValueIsFilled(Parameters.Filter[FilterElement.Key]) Then
			FilterParameters.Insert(FilterElement.Key, Parameters.Filter[FilterElement.Key]);
		EndIf;
		
	EndDo;
	
	For Each ParameterElement In FilterParameters Do
		
		If Parameters.Property(ParameterElement.Key)
			And ValueIsFilled(Parameters[ParameterElement.Key]) Then
			FilterParameters.Insert(ParameterElement.Key, Parameters[ParameterElement.Key]);
		EndIf;
		
	EndDo;
	
	If Parameters.Filter.Property("PayrollTransaction") Then
		FilterParameters.Insert("BusinessOperation", Parameters.Filter.PayrollTransaction);
	EndIf;
	
	FilterParameters.PaymentMethod = CashServer.ValueOfRequestPaymentFormParameter(FilterParameters.PaymentMethod);

EndProcedure

&AtServer
Procedure LimitListOfRequests()

	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "Document.PaymentRequest";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryTextWithSelection();
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	Recipient = CashServer.PaymentBeneficiary(FilterParameters);
	
	List.Parameters.SetParameterValue("Currency", FilterParameters.Currency);
	List.Parameters.SetParameterValue("Organization", FilterParameters.Organization);
	List.Parameters.SetParameterValue("OperationWithSelfEmployedPerson", FilterParameters.OperationWithSelfEmployedPerson);
	List.Parameters.SetParameterValue("PaymentMethod", FilterParameters.PaymentMethod);
	List.Parameters.SetParameterValue("BusinessOperation", FilterParameters.BusinessOperation);
	List.Parameters.SetParameterValue("BankAccountCashAccount", FilterParameters.BankAccountCashAccount);
	List.Parameters.SetParameterValue("Recipient", Recipient);

EndProcedure

&AtServer
Function NewRequestsFilterParameters()

	Filter = New Structure;
	Filter.Insert("Organization", Catalogs.Companies.EmptyRef());
	Filter.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	Filter.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	Filter.Insert("AdvanceHolder", Undefined);
	Filter.Insert("PaymentMethod", Undefined);
	Filter.Insert("Currency", Catalogs.Currencies.EmptyRef());
	Filter.Insert("BankAccountCashAccount", Undefined);
	Filter.Insert("BankAccountBeneficiary", Catalogs.CompaniesBankAccounts.EmptyRef());
	Filter.Insert("CashAccountRecipient", Catalogs.CashAccounts.EmptyRef());
	Filter.Insert("ListOfCounterparties_", False);
	Filter.Insert("OperationWithSelfEmployedPerson", Undefined);
	
	Return Filter;

EndFunction

&AtServer
Function QueryTextWithSelection()

	QueriesTexts = New Array;
	QueriesTexts.Add(SelectionTextOfRequestsWithFilter());
	
	If OnlyBalance Then
		QueriesTexts.Add(SelectionTextOfUnpaidRequestsWithFilter());
	EndIf;
	
	FinalSelection = 
		"SELECT
		|	SpendingRequests.Ref AS Ref,
		|	SpendingRequests.DeletionMark AS DeletionMark,
		|	SpendingRequests.Number AS Number,
		|	SpendingRequests.Date AS Date,
		|	SpendingRequests.Posted AS Posted,
		|	SpendingRequests.Organization AS Organization,
		|	SpendingRequests.Status AS Status,
		|	SpendingRequests.BusinessOperation AS BusinessOperation,
		|	SpendingRequests.PayrollTransaction AS PayrollTransaction,
		|	SpendingRequests.DocumentAmount AS DocumentAmount,
		|	SpendingRequests.Currency AS Currency,
		|	SpendingRequests.PaymentDate AS PaymentDate,
		|	SpendingRequests.Counterparty AS Counterparty,
		|	SpendingRequests.Department AS Department,
		|	SpendingRequests.WhoStated AS WhoStated,
		|	SpendingRequests.PaymentPriority AS PaymentPriority
		|FROM
		|	Document.PaymentRequest AS SpendingRequests
		|		INNER JOIN &TableBeingReplaced AS SummaryTable
		|		ON SpendingRequests.Ref = SummaryTable.Ref
		|";
	
	If OnlyBalance Then
		FinalSelection = StrReplace(FinalSelection, "&TableBeingReplaced", "UnpaidRequests");
	Else
		FinalSelection = StrReplace(FinalSelection, "&TableBeingReplaced", "Requests");
	EndIf;
	
	QueriesTexts.Add(FinalSelection);
	
	Return StrConcat(QueriesTexts, ";");

EndFunction

&AtServer
Function SelectionTextOfRequestsWithFilter()

	Return 
	"SELECT DISTINCT ALLOWED
	|	Request.Ref AS Ref,
	|	Request.BusinessOperation AS BusinessOperation,
	|	Request.PayrollTransaction AS PayrollTransaction,
	|	Request.Counterparty AS Counterparty,
	|	Request.AdvanceHolder AS AdvanceHolder,
	|	Request.CompanyRecipient AS CompanyRecipient,
	|	Request.PersonsList AS PersonsList,
	|	Request.ListOfCounterparties_ AS ListOfCounterparties_
	|INTO RequestsWithFilter
	|FROM
	|	Document.PaymentRequest AS Request
	|		LEFT JOIN Document.PaymentRequest.AllocationByAccounts AS RequestDistributionByAccounts
	|		ON Request.Ref = RequestDistributionByAccounts.Ref
	|WHERE
	|	(Request.PaymentMethodOfPaymentRequest IN (&PaymentMethod))
	|	AND (Request.Currency = &Currency
	|			OR Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency))
	|	AND Request.Status = VALUE(Enum.StatusesOfPaymentRequests.AmountDue)
	|	AND (Request.OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson
	|			OR &OperationWithSelfEmployedPerson = UNDEFINED)
	|	AND Request.Organization = &Organization
	|	AND (RequestDistributionByAccounts.BankAccountCashAccount = &BankAccountCashAccount
	|			OR RequestDistributionByAccounts.BankAccountCashAccount IS NULL)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Requests.Ref AS Ref,
	|	Requests.Counterparty AS Counterparty,
	|	Requests.AdvanceHolder AS AdvanceHolder,
	|	Requests.CompanyRecipient AS CompanyRecipient,
	|	Requests.PersonsList AS PersonsList,
	|	Requests.ListOfCounterparties_ AS ListOfCounterparties_
	|INTO RequestsForSelectedOfOperation
	|FROM
	|	RequestsWithFilter AS Requests
	|WHERE
	|	Requests.BusinessOperation = &BusinessOperation
	|	AND Requests.PayrollTransaction <> &BusinessOperation
	|
	|UNION ALL
	|
	|SELECT
	|	Requests.Ref,
	|	Requests.Counterparty,
	|	Requests.AdvanceHolder,
	|	Requests.CompanyRecipient,
	|	Requests.PersonsList,
	|	Requests.ListOfCounterparties_
	|FROM
	|	RequestsWithFilter AS Requests
	|WHERE
	|	Requests.PayrollTransaction IN(&BusinessOperation)
	|	AND NOT Requests.BusinessOperation IN (&BusinessOperation)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RequestsForSelectedOfOperation.Ref AS Ref
	|INTO Requests
	|FROM
	|	RequestsForSelectedOfOperation AS RequestsForSelectedOfOperation
	|WHERE
	|	RequestsForSelectedOfOperation.Counterparty IN(&Recipient)
	|	AND NOT RequestsForSelectedOfOperation.ListOfCounterparties_
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RequestsForSelectedOfOperation.Ref
	|FROM
	|	RequestsForSelectedOfOperation AS RequestsForSelectedOfOperation
	|		INNER JOIN Document.PaymentRequest.ARAPDetails AS ARAPDetails
	|		ON RequestsForSelectedOfOperation.Ref = ARAPDetails.Ref
	|WHERE
	|	ARAPDetails.Counterparty IN(&Recipient)
	|	AND RequestsForSelectedOfOperation.ListOfCounterparties_
	|
	|UNION ALL
	|
	|SELECT
	|	RequestsForSelectedOfOperation.Ref
	|FROM
	|	RequestsForSelectedOfOperation AS RequestsForSelectedOfOperation
	|WHERE
	|	RequestsForSelectedOfOperation.AdvanceHolder IN(&Recipient)
	|	AND NOT RequestsForSelectedOfOperation.PersonsList
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RequestsForSelectedOfOperation.Ref
	|FROM
	|	RequestsForSelectedOfOperation AS RequestsForSelectedOfOperation
	|		INNER JOIN Document.PaymentRequest.PersonalAccountsOfStaff AS PersonalAccountsOfStaff
	|		ON RequestsForSelectedOfOperation.Ref = PersonalAccountsOfStaff.Ref
	|WHERE
	|	PersonalAccountsOfStaff.Individual IN(&Recipient)
	|	AND RequestsForSelectedOfOperation.PersonsList
	|
	|UNION ALL
	|
	|SELECT
	|	RequestsForSelectedOfOperation.Ref
	|FROM
	|	RequestsForSelectedOfOperation AS RequestsForSelectedOfOperation
	|WHERE
	|	RequestsForSelectedOfOperation.CompanyRecipient IN(&Recipient)";

EndFunction

&AtServer
Function SelectionTextOfUnpaidRequestsWithFilter()

	Return 
		"SELECT ALLOWED
		|	Cash.PaymentRequest AS Ref
		|INTO UnpaidRequests
		|FROM
		|	AccumulationRegister.CashToBePaid.Balance(
		|			,
		|			PaymentRequest IN
		|				(SELECT
		|					Requests.Ref
		|				FROM
		|					Requests AS Requests)) AS Cash
		|";

EndFunction

#EndRegion
