#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	CustomizeList();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeList()

	QueryText = ListRequestText();
		
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText					= QueryText;
	ListProperties.MainTable				= "Catalog.AcquiringContracts";
	ListProperties.DynamicDataRead	= True;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	CustomizeListLocalization();
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure CustomizeListLocalization()

	
EndProcedure

&AtServerNoContext
Function ListRequestText()

	QueryText = "SELECT
	               |	CatalogAcquiringContracts.Ref AS Ref,
	               |	CatalogAcquiringContracts.DeletionMark AS DeletionMark,
	               |	CatalogAcquiringContracts.Code AS Code,
	               |	CatalogAcquiringContracts.Description AS Description,
	               |	CatalogAcquiringContracts.Number AS Number,
	               |	CatalogAcquiringContracts.Date AS Date,
	               |	CatalogAcquiringContracts.Status AS Status,
	               |	CatalogAcquiringContracts.Approved AS Approved,
	               |	CatalogAcquiringContracts.Organization AS Organization,
	               |	CatalogAcquiringContracts.Department AS Department,
	               |	CatalogAcquiringContracts.BankAccount AS BankAccount,
	               |	CatalogAcquiringContracts.EmployeeResponsible AS EmployeeResponsible,
	               |	CatalogAcquiringContracts.Partner AS Partner,
	               |	CatalogAcquiringContracts.Counterparty AS Counterparty,
	               |	CatalogAcquiringContracts.CounterpartyBankAccount AS CounterpartyBankAccount,
	               |	CatalogAcquiringContracts.ContactPerson AS ContactPerson,
	               |	CatalogAcquiringContracts.POSTerminalsAreUsed AS POSTerminalsAreUsed,
	               |	CatalogAcquiringContracts.DetailedTransactionReconciliation AS DetailedTransactionReconciliation,
	               |	CatalogAcquiringContracts.EnableCreatingCashIssueWithoutPaymentRequest AS EnableCreatingCashIssueWithoutPaymentRequest,
	               |	CatalogAcquiringContracts.PaymentPeriod AS PaymentPeriod,
	               |	CatalogAcquiringContracts.FixedFeeRate AS FixedFeeRate,
	               |	CatalogAcquiringContracts.CommissionRate AS CommissionRate,
	               |	CatalogAcquiringContracts.CommissionPostingMethod AS CommissionPostingMethod,
	               |	CatalogAcquiringContracts.FeeIsChargedOnRefund AS FeeIsChargedOnRefund,
	               |	CatalogAcquiringContracts.CashFlowItemCashReceipt AS CashFlowItemCashReceipt,
	               |	CatalogAcquiringContracts.CashFlowItemReturn AS CashFlowItemReturn,
	               |	CatalogAcquiringContracts.CashFlowItemCommission AS CashFlowItemCommission,
	               |	CatalogAcquiringContracts.LineOfBusiness AS LineOfBusiness,
	               |	CatalogAcquiringContracts.ExpenseItem AS ExpenseItem,
	               |	CatalogAcquiringContracts.DimensionOfExpenses AS DimensionOfExpenses,
	               |	CatalogAcquiringContracts.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	               |	CatalogAcquiringContracts.Comment AS Comment,
	               |	CatalogAcquiringContracts.MakingPaymentMethod AS MakingPaymentMethod,
	               |	FALSE AS ThereIsIntegrationSetting
	               |{SELECT
	               |	ThereIsIntegrationSetting}
	               |FROM
	               |	Catalog.AcquiringContracts AS CatalogAcquiringContracts
	               |{WHERE
	               |	(FALSE) AS ThereIsIntegrationSetting}";
	
	QueryText = ListRequestTextLocalization(QueryText);
	
    Return QueryText
EndFunction

&AtServerNoContext
Function ListRequestTextLocalization(Val QueryText)

    Return QueryText
EndFunction

#EndRegion