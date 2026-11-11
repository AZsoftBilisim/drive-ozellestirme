#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Parameters, "OnlyBalance") Then
		OnlyBalance = Parameters.OnlyBalance;
	Else
		NoFilter = True;
	EndIf;
	
	If Not NoFilter Then
		
		FillFilterParameters();
		LimitListOfRequests();
	
	EndIf;
	
	Items.OnlyBalance.Visible = Not NoFilter;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

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

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure OnlyBalancesOnChangeAtServer()

	LimitListOfRequests();

EndProcedure

&AtServer
Procedure LimitListOfRequests()

	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "Document.ApplicationForBusinessTrip";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = ListRequestText();
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	List.Parameters.SetParameterValue("Currency", FilterParameters.Currency);
	List.Parameters.SetParameterValue("Organization", FilterParameters.Organization);
	List.Parameters.SetParameterValue("PaymentMethod", FilterParameters.PaymentMethod);
	List.Parameters.SetParameterValue("BankAccountCashAccount", FilterParameters.BankAccountCashAccount);
	List.Parameters.SetParameterValue("Recipient", FilterParameters.AdvanceHolder);

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
	
	FilterParameters.PaymentMethod = CashServer.ValueOfRequestPaymentFormParameter(FilterParameters.PaymentMethod);

EndProcedure

&AtServer
Function NewRequestsFilterParameters()

	Filter = New Structure;
	Filter.Insert("Organization", Catalogs.Companies.EmptyRef());
	Filter.Insert("AdvanceHolder", Undefined);
	Filter.Insert("PaymentMethod", Undefined);
	Filter.Insert("Currency", Catalogs.Currencies.EmptyRef());
	Filter.Insert("BankAccountCashAccount", Undefined);
	
	Return Filter;

EndFunction

&AtServer
Function ListRequestText()

	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfSampleOfApplications());
	
	If OnlyBalance Then
		QueriesTexts.Add(TextOfSampleOfUnpaidApplications());
	EndIf;
	
	FinalSelection = 
		"SELECT
		|	SpendingRequests.Number AS Number,
		|	SpendingRequests.Date AS Date
		|FROM
		|	Document.ApplicationForBusinessTrip AS SpendingRequests
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
Function TextOfSampleOfApplications()

	Return 
	"SELECT ALLOWED
	|	ApplicationForBusinessTrip.Ref AS Ref,
	|	ApplicationForBusinessTrip.Employee AS Employee
	|INTO RequestsWithFilter
	|FROM
	|	Document.ApplicationForBusinessTrip AS ApplicationForBusinessTrip
	|WHERE
	|	ApplicationForBusinessTrip.PaymentMethodOfPaymentRequest IN (&PaymentMethod)
	|	AND ApplicationForBusinessTrip.Currency = &Currency
	|	AND ApplicationForBusinessTrip.Status = VALUE(Enum.EmployeeApplicationStatuses.AgreedUpon)
	|	AND ApplicationForBusinessTrip.Organization = &Organization
	|	AND (ApplicationForBusinessTrip.BankAccount = &BankAccountCashAccount
	|			OR ApplicationForBusinessTrip.BankAccount = VALUE(Catalog.CompaniesBankAccounts.EmptyRef))
	|	AND (ApplicationForBusinessTrip.CashAccount = &BankAccountCashAccount
	|			OR ApplicationForBusinessTrip.CashAccount = VALUE(Catalog.CashAccounts.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RequestsWithFilter.Ref AS Ref
	|INTO RequestsByEmployee
	|FROM
	|	RequestsWithFilter AS RequestsWithFilter
	|		INNER JOIN Document.ApplicationForBusinessTrip.TravellingEmployees AS ApplicationForBusinessTripTravellingEmployees
	|		ON RequestsWithFilter.Ref = ApplicationForBusinessTripTravellingEmployees.Ref
	|WHERE
	|	ApplicationForBusinessTripTravellingEmployees.Employee IN(&Recipient)
	|
	|UNION ALL
	|
	|SELECT
	|	RequestsWithFilter.Ref
	|FROM
	|	RequestsWithFilter AS RequestsWithFilter
	|		INNER JOIN Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder AS ApplicationForBusinessTripFundsIssueToAdvanceHolder
	|		ON RequestsWithFilter.Ref = ApplicationForBusinessTripFundsIssueToAdvanceHolder.Ref
	|WHERE
	|	ApplicationForBusinessTripFundsIssueToAdvanceHolder.Employee IN(&Recipient)
	|
	|UNION ALL
	|
	|SELECT
	|	RequestsWithFilter.Ref
	|FROM
	|	RequestsWithFilter AS RequestsWithFilter
	|WHERE
	|	RequestsWithFilter.Employee IN(&Recipient)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RequestsByEmployee.Ref AS Ref
	|INTO Requests
	|FROM
	|	RequestsByEmployee AS RequestsByEmployee";

EndFunction

&AtServer
Function TextOfSampleOfUnpaidApplications()

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

