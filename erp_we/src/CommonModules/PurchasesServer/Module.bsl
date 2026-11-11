////////////////////////////////////////////////////////////////////////////////
// The module "Procurement Server" contains procedures and functions for 
// obtaining the values of the details for substitution in the procurement documents.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ProceduresForInitializingProcurementRules

// Returns the structure of the purchase terms for a trade agreement.
//
// Parameters:
// 	Terms - CatalogRef.TermsOfSale - the agreement is subject to standard terms and conditions of purchase
// 	ConsiderWarehouseGroups - Boolean -
// 	ExcludeWarehouseGroupsAvailableInOrders - Boolean -
//
// Returns:
// 	Structure - A structure that includes sales conditions.
//
Function GetPurchaseTermsAndConditions(Val Terms,
	                           Val ConsiderWarehouseGroups=False,
	                           Val ExcludeWarehouseGroupsAvailableInOrders=False) Export
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	TermsOfPurchases.Ref             AS Terms,
	|	TermsOfPurchases.Partner            AS Partner,
	|	TermsOfPurchases.Counterparty         AS Counterparty,
	|	TermsOfPurchases.Organization        AS Organization,
	|	TermsOfPurchases.VendorPriceKind  AS VendorPriceKind,
	|	TermsOfPurchases.Currency             AS Currency,
	|	CASE
	|		WHEN TermsOfPurchases.ContractsAreUsed
	|			THEN TermsOfPurchases.Currency
	|		ELSE TermsOfPurchases.ARAPCurrency
	|	END                                     AS ARAPCurrency,
	|	TermsOfPurchases.PriceIncludesVAT    AS PriceIncludesVAT,
	|	CASE
	|		WHEN
	|			NOT TermsOfPurchases.Warehouse.IsFolder
	|		THEN
	|			TermsOfPurchases.Warehouse
	|		WHEN
	|			TermsOfPurchases.Warehouse.IsFolder
	|			AND &ConsiderWarehouseGroups
	|			AND TermsOfPurchases.Warehouse.SelectGroup IN (&SelectWarehouseGroup)
	|		THEN
	|			TermsOfPurchases.Warehouse
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                               AS Warehouse,
	|	TermsOfPurchases.PaymentMethod                  AS PaymentMethod,
	|	TermsOfPurchases.ForeignCurrencyTransaction                AS ForeignCurrencyTransaction,
	|	TermsOfPurchases.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	TermsOfPurchases.CashFlowItem AS CashFlowItem,
	|	TermsOfPurchases.ShipmentDueDate                 AS ShipmentDueDate,
	|	TermsOfPurchases.BusinessOperation        AS BusinessOperation,
	|	TermsOfPurchases.RegisterVendorPrices AS RegisterVendorPrices,
	|	TermsOfPurchases.CommissionFeeCalculationMethod  AS CommissionFeeCalculationMethod,
	|	TermsOfPurchases.RemunerationPercentage        AS RemunerationPercentage,
	|	TermsOfPurchases.KeepCommissionFee       AS KeepCommissionFee,
	|	
	|	TermsOfPurchases.ContractsAreUsed            AS ContractsAreUsed,
	|	TermsOfPurchases.ARAPObjectSettings                             AS ARAPObjectSettings,
	|	TermsOfPurchases.ReturnReusablePackage                AS ReturnReusablePackage,
	|	TermsOfPurchases.ReusablePackageReturnCycleLength              AS ReusablePackageReturnCycleLength,
	|	TermsOfPurchases.CalculatePackageReturnDateAccordingToCalendar     AS CalculatePackageReturnDateAccordingToCalendar,
	|	TermsOfPurchases.ScheduleOfPackageReturn                       AS ScheduleOfPackageReturn,
	|	TermsOfPurchases.PackageDepositIsRequired                        AS PackageDepositIsRequired,
	|	TermsOfPurchases.LineOfBusiness                     AS LineOfBusiness,
	|	TermsOfPurchases.MinimumOrderAmount                      AS MinimumOrderAmount,
	|	TermsOfPurchases.DeliveryTime                                AS DeliveryDuration
	|
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
	|WHERE
	|	TermsOfPurchases.Ref = &Terms";
	
	Query.SetParameter("Terms",             Terms);
	Query.SetParameter("SelectWarehouseGroup",     Catalogs.Warehouses.OptionsForSelectingWarehouseGroup(ExcludeWarehouseGroupsAvailableInOrders));
	Query.SetParameter("ConsiderWarehouseGroups", ConsiderWarehouseGroups);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	AttributesStructure1 = ProcurementConditionsTemplate();
	FillPropertyValues(AttributesStructure1, Selection);
	
	If Not GetFunctionalOption("UseContractsWithVendors") Then
		AttributesStructure1.Insert("ContractsAreUsed", False);
	EndIf;
		
	Return AttributesStructure1;
	
EndFunction

// Returns the date of the last stage on the schedule.
//
// Parameters:
// 	DocumentDate          - Date - the date from which you want to get the latest date on the schedule
// 	TermsOfPurchases - CatalogRef.TermsOfPurchaseFromVendors - 
//
// Returns:
// 	Number - The last date on the schedule, taking into account the calendar.
//
Function GetLatestDateOnSchedule(Val DocumentDate, Val TermsOfPurchases) Export
	
	If Not ValueIsFilled(DocumentDate) Then
		DocumentDate = CurrentSessionDate();
	EndIf;
	
	Query = New Query(
	"SELECT
	|	MAX(PaymentScheduleSteps.Move) AS Move,
	|	PaymentScheduleSteps.Ref.Calendar AS Calendar,
	|	BEGINOFPERIOD(DATEADD(&DocumentDate, DAY, ISNULL(MAX(PaymentScheduleSteps.Move), 0)), DAY) AS PaymentDate
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref = &TermsOfPurchases
	|	AND (PaymentScheduleSteps.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment)
	|		OR PaymentScheduleSteps.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt))
	|
	|GROUP BY
	|	PaymentScheduleSteps.Ref,
	|	PaymentScheduleSteps.Ref.Calendar");
	
	Query.SetParameter("TermsOfPurchases",  TermsOfPurchases);
	Query.SetParameter("DocumentDate", DocumentDate);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	Calendar = Selection.Calendar;
	If ValueIsFilled(Calendar) Then
		PaymentDate = CalendarSchedules.DateByCalendar(Calendar, DocumentDate, Selection.Move);
	Else
		PaymentDate = Selection.PaymentDate;
	EndIf;
		
	Return PaymentDate;
	
EndFunction

// Returns the structure of purchasing conditions for the partner.
//
// Parameters:
//  Partner           - CatalogRef.Partners - partner for which you want to receive conditions of purchase,
//  FilterParameters   - Structure - contains parameters for selecting an agreement.
//
// Returns:
//  Structure - a structure that includes the terms of purchase.
//
Function GetDefaultPurchaseTerms(Val Partner, Val FilterParameters = Undefined) Export
	
	AllSelectionParameters = New Structure();
	AllSelectionParameters.Insert("OnlyValid",                       True);
	AllSelectionParameters.Insert("ConsiderWarehouseGroups",                  False);
	AllSelectionParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", False);
	AllSelectionParameters.Insert("BusinessTransactions",                   Undefined);
	AllSelectionParameters.Insert("SelectedAgreement",                     Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	AllSelectionParameters.Insert("ContractsAreUsed",        Undefined);
	AllSelectionParameters.Insert("PriceIncludesVAT",                         Undefined);
	
	If FilterParameters <> Undefined Then
		FillPropertyValues(AllSelectionParameters, FilterParameters);
	EndIf;
	
	// Getting the default agreement:
	ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingOutSupplierAgreements();
	ActionParameters.OnlyValid = AllSelectionParameters.OnlyValid;
	ActionParameters.BusinessOperation = AllSelectionParameters.BusinessTransactions;
	ActionParameters.PriceIncludesVAT = AllSelectionParameters.PriceIncludesVAT;
	ActionParameters.ContractsAreUsed = AllSelectionParameters.ContractsAreUsed;
	
	RowData = New Structure;
	RowData.Insert("Partner",    Partner);
	RowData.Insert("Terms", AllSelectionParameters.SelectedAgreement);
	
	Actions = New Structure;
	Actions.Insert("FillInDefaultSupplierAgreement", ActionParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(
		RowData,
		Actions,
		BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues());
		
	// Getting purchase terms for the selected default agreement:
	ReturnValue = Undefined;
	If ValueIsFilled(RowData.Terms) Then
		ReturnValue = GetPurchaseTermsAndConditions(
			RowData.Terms,
			AllSelectionParameters.ConsiderWarehouseGroups,
			AllSelectionParameters.ExcludeWarehouseGroupsAvailableInOrders);
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Returns additional business of operations for the main one.
// 
// Parameters:
//  BasicEconomicOperation - EnumRef.BusinessTransactions - Basic Economic Operation
// 
// Returns:
//  Array of EnumRef.BusinessTransactions
Function BusinessOperationsOnMain(BasicEconomicOperation) Export
	
	AdditionalBusinessOperationsOnMain = AdditionalBusinessOperationsOnMain(); 

	SearchParameters = New Structure("BasicOperation", BasicEconomicOperation);
	FoundRows = AdditionalBusinessOperationsOnMain.FindRows(SearchParameters);
	If FoundRows.Count() = 0 Then
		ReturnValue = CommonClientServer.ValueInArray(BasicEconomicOperation);
	Else
		ReturnValue = Common.UnloadColumn(FoundRows, "AdditionalOperation");
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Returns business operations that can be used in the document. If you pass an empty link to
// a contract or agreement, several business operations that can be used will be returned.
//
// Parameters:
//	FullDocumentName	 - String 									 - name of the document to get a list of business operations for.
//	Terms			 - CatalogRef.TermsOfPurchaseFromVendors	 - the agreement that is used in the document.
//	Contract				 - CatalogRef.CounterpartyContracts     - the contract that is used in the document.
//
// Returns:
//	Array - an array of elements with the enumeration type of the link.Economic operations.
//
Function EconomicOperationsOfSeparatePurchase(FullDocumentName, Terms = Undefined, Contract = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TermsOfPurchaseFromVendors.BusinessOperation AS BusinessOperation
	|INTO TermsOfPurchaseFromVendors
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|WHERE
	|	TermsOfPurchaseFromVendors.Ref = &Terms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(NestedQuery.PurchaseRegistrationOption) AS PurchaseRegistrationOption,
	|	MAX(NestedQuery.BusinessOperation)    AS BusinessOperation
	|INTO ParameterData
	|FROM
	|	(SELECT
	|		CounterpartyContracts.PurchaseRegistrationOption AS PurchaseRegistrationOption,
	|		ISNULL(CounterpartyContracts.BusinessOperation, TermsOfPurchaseFromVendors.BusinessOperation) AS BusinessOperation
	|	FROM
	|		(SELECT
	|			CounterpartyContracts.PurchaseRegistrationOption AS PurchaseRegistrationOption,
	|			CounterpartyContracts.BusinessOperation    AS BusinessOperation
	|		FROM
	|			Catalog.CounterpartyContracts AS CounterpartyContracts
	|		WHERE
	|			CounterpartyContracts.Ref = &Contract) AS CounterpartyContracts
	|			FULL JOIN TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|			ON (TRUE)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NULL,
	|		NULL) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessTransactions.Ref AS BusinessTransaction
	|INTO BusinessTransactionsByTerms
	|FROM
	|	ParameterData AS ParameterData,
	|	Enum.BusinessTransactions AS BusinessTransactions
	|WHERE
	|	BusinessTransactions.Ref IN(&BusinessTransactionsPurchasingFromSupplier)
	|	AND (ParameterData.BusinessOperation IN (&BusinessTransactionsPurchasingFromSupplier)
	|			OR ParameterData.BusinessOperation IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	BusinessTransactions.Ref
	|FROM
	|	Enum.BusinessTransactions AS BusinessTransactions,
	|	ParameterData AS ParameterData
	|WHERE
	|	BusinessTransactions.Ref IN(&BusinessTransactionsImportPurchase)
	|	AND (ParameterData.BusinessOperation IN (&BusinessTransactionsImportPurchase)
	|			OR ParameterData.BusinessOperation IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	BusinessTransactions.Ref
	|FROM
	|	Enum.BusinessTransactions AS BusinessTransactions,
	|	ParameterData AS ParameterData
	|WHERE
	|	BusinessTransactions.Ref IN(&BusinessTransactionsProcurementInEAEUCountries)
	|	AND (ParameterData.BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|			OR ParameterData.BusinessOperation IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	BusinessTransactions.Ref
	|FROM
	|	Enum.BusinessTransactions AS BusinessTransactions,
	|	ParameterData AS ParameterData
	|WHERE
	|	BusinessTransactions.Ref IN(&BusinessTransactionsAdmissionToCommission)
	|	AND (ParameterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|			OR ParameterData.BusinessOperation IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	BusinessTransactions.Ref
	|FROM
	|	Enum.BusinessTransactions AS BusinessTransactions,
	|	ParameterData AS ParameterData
	|WHERE
	|	BusinessTransactions.Ref IN(&BusinessTransactionsAcceptanceForResponsibleStorage)
	|	AND (ParameterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
	|			OR ParameterData.BusinessOperation IS NULL)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessTransactions.Ref AS BusinessTransaction
	|INTO BusinessTransactionsByContract
	|FROM
	|	ParameterData AS ParameterData,
	|	Enum.BusinessTransactions AS BusinessTransactions
	|WHERE
	|	BusinessTransactions.Ref IN(&BusinessTransactionsUnfacturedDeliveries)
	|	AND (ParameterData.PurchaseRegistrationOption IN (
	|				VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods),
	|				VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices))
	|		OR ParameterData.PurchaseRegistrationOption IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	BusinessTransactions.Ref
	|FROM
	|	ParameterData AS ParameterData,
	|	Enum.BusinessTransactions AS BusinessTransactions
	|WHERE
	|	BusinessTransactions.Ref IN(&BusinessTransactionsGoodsInTransit)
	|	AND (ParameterData.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.GoodsInTransit)
	|			OR ParameterData.PurchaseRegistrationOption IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	BusinessTransactions.Ref
	|FROM
	|	ParameterData AS ParameterData,
	|	Enum.BusinessTransactions AS BusinessTransactions
	|WHERE
	|	BusinessTransactions.Ref IN(&BusinessTransactionsDoNotShareProcurementProcessing)
	|	AND (ParameterData.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.NotSeparate)
	|			OR ParameterData.PurchaseRegistrationOption IS NULL)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessTransactionsByContract.BusinessTransaction         AS BusinessTransaction,
	|	BusinessTransactionsByContract.BusinessTransaction.Order AS Order,
	|	CASE
	|		WHEN BusinessTransactionsByContract.BusinessTransaction = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|			THEN 0
	|		WHEN BusinessTransactionsByContract.BusinessTransaction = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|				OR BusinessTransactionsByContract.BusinessTransaction = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|			THEN 2
	|		WHEN BusinessTransactionsByContract.BusinessTransaction IN(&BusinessTransactionsPurchasingFromSupplier)
	|			THEN 1
	|		WHEN BusinessTransactionsByContract.BusinessTransaction IN(&BusinessTransactionsImportPurchase)
	|			THEN 3
	|		WHEN BusinessTransactionsByContract.BusinessTransaction IN(&BusinessTransactionsProcurementInEAEUCountries)
	|			THEN 4
	|		WHEN BusinessTransactionsByContract.BusinessTransaction IN(&BusinessTransactionsAdmissionToCommission)
	|			THEN 5
	|		ELSE 6
	|	END                                     AS Number
	|FROM
	|	BusinessTransactionsByContract AS BusinessTransactionsByContract
	|
	|UNION
	|
	|SELECT
	|	BusinessTransactionsByTerms.BusinessTransaction         AS BusinessTransaction,
	|	BusinessTransactionsByTerms.BusinessTransaction.Order AS Order,
	|	CASE
	|		WHEN BusinessTransactionsByTerms.BusinessTransaction = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|			THEN 0
	|		WHEN BusinessTransactionsByTerms.BusinessTransaction = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|				OR BusinessTransactionsByTerms.BusinessTransaction = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|			THEN 2
	|		WHEN BusinessTransactionsByTerms.BusinessTransaction IN(&BusinessTransactionsPurchasingFromSupplier)
	|			THEN 1
	|		WHEN BusinessTransactionsByTerms.BusinessTransaction IN(&BusinessTransactionsImportPurchase)
	|			THEN 3
	|		WHEN BusinessTransactionsByTerms.BusinessTransaction IN(&BusinessTransactionsProcurementInEAEUCountries)
	|			THEN 4
	|		WHEN BusinessTransactionsByTerms.BusinessTransaction IN(&BusinessTransactionsAdmissionToCommission)
	|			THEN 5
	|		ELSE 6
	|	END                                       AS Number
	|FROM
	|	BusinessTransactionsByTerms AS BusinessTransactionsByTerms
	|
	|ORDER BY
	|	Number,
	|	Order";
	
	DefaultParameter = New Array;
	
	Query.SetParameter("Contract",    Contract);
	Query.SetParameter("Terms", Terms);
	
	Query.SetParameter("BusinessTransactionsPurchasingFromSupplier",           DefaultParameter);
	Query.SetParameter("BusinessTransactionsImportPurchase",             DefaultParameter);
	Query.SetParameter("BusinessTransactionsAdmissionToCommission",              DefaultParameter);
	Query.SetParameter("BusinessTransactionsAcceptanceForResponsibleStorage", DefaultParameter);
	Query.SetParameter("BusinessTransactionsProcurementInEAEUCountries",          DefaultParameter);
	Query.SetParameter("BusinessTransactionsGoodsInTransit",                  DefaultParameter);
	Query.SetParameter("BusinessTransactionsUnfacturedDeliveries",    DefaultParameter);
	Query.SetParameter("BusinessTransactionsDoNotShareProcurementProcessing", DefaultParameter);
	
	ManagerOfDocument = Common.ObjectManagerByFullName(FullDocumentName);
	ManagerOfDocument.FillInParametersOfBusinessOperations(Query.Parameters);
	
	SetPrivilegedMode(True);
	EconomicOperationsOfSeparatePurchase = Query.Execute().Unload().UnloadColumn("BusinessTransaction");
	SetPrivilegedMode(False);
	
	Return EconomicOperationsOfSeparatePurchase;
	
EndFunction

// Fills in the parameters of the query that performs ordering of business operations.
//
// Parameters:
//	QueryOptions - Structure - request parameters to initialize:
//		* BusinessTransactionsPurchasingFromSupplier				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsImportPurchase				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsProcurementInEAEUCountries			 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsAdmissionToCommission				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsGoodsInTransit					 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsUnfacturedDeliveries		 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsDoNotShareProcurementProcessing	 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//
Procedure FillInParametersOfRequestForOrderingBusinessOperations(QueryOptions) Export
	
	UseImports = GetFunctionalOption("UseImports");
	UseImportOfGoodsFromCustomsUnion = GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
	UsePurchaseCommission = GetFunctionalOption("UsePurchaseCommission");
	UseGoodsInTransitFromVendors = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	UseManagementCompany = GetFunctionalOption("UseManagementCompany");
	
	BusinessTransactionsPurchasingFromSupplier = New Array;
	BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
	
	If UseManagementCompany Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseFromVendorLocal);
	EndIf;
	
	If UseGoodsInTransitFromVendors Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	EndIf;
	
	If UseUninvoicedDeliveries Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	EndIf;
	
	BusinessTransactionsImportPurchase = New Array;
	If UseImports Then
		BusinessTransactionsImportPurchase.Add(Enums.BusinessTransactions.PurchaseByImport);
		
		If UseGoodsInTransitFromVendors Then
			BusinessTransactionsImportPurchase.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		EndIf;
	EndIf;
	
	BusinessTransactionsProcurementInEAEUCountries = New Array;
	If UseImportOfGoodsFromCustomsUnion Then
		BusinessTransactionsProcurementInEAEUCountries.Add(Enums.BusinessTransactions.ImportFromEAEU);
		
		If UseGoodsInTransitFromVendors Then
			BusinessTransactionsProcurementInEAEUCountries.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		EndIf;
		
		If UseUninvoicedDeliveries Then
			BusinessTransactionsProcurementInEAEUCountries.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		EndIf;
	EndIf;
	
	BusinessTransactionsAdmissionToCommission = New Array;
	If UsePurchaseCommission Then
		BusinessTransactionsAdmissionToCommission.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	EndIf;
	
	BusinessTransactionsGoodsInTransit = New Array;
	If UseGoodsInTransitFromVendors Then
		BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
		
		If UseImports Then
			BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		EndIf;
		If UseImportOfGoodsFromCustomsUnion Then
			BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		EndIf;
	EndIf;
	
	BusinessTransactionsUnfacturedDeliveries = New Array;
	If UseUninvoicedDeliveries Then
		BusinessTransactionsUnfacturedDeliveries.Add(
			Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
		
		If UseImportOfGoodsFromCustomsUnion Then
			BusinessTransactionsUnfacturedDeliveries.Add(
				Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		EndIf;
	EndIf;
	
	BusinessTransactionsDoNotShareProcurementProcessing = New Array;
	BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
	
	If UseManagementCompany Then
		BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.PurchaseFromVendorLocal);
	EndIf;
	
	If UsePurchaseCommission Then
		BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	EndIf;
	
	If UseImports Then
		BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.PurchaseByImport);
	EndIf;
	If UseImportOfGoodsFromCustomsUnion Then
		BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.ImportFromEAEU);
	EndIf;
	
	QueryOptions.BusinessTransactionsPurchasingFromSupplier           = BusinessTransactionsPurchasingFromSupplier;
	QueryOptions.BusinessTransactionsImportPurchase             = BusinessTransactionsImportPurchase;
	QueryOptions.BusinessTransactionsAdmissionToCommission              = BusinessTransactionsAdmissionToCommission;
	QueryOptions.BusinessTransactionsProcurementInEAEUCountries          = BusinessTransactionsProcurementInEAEUCountries;
	QueryOptions.BusinessTransactionsGoodsInTransit                  = BusinessTransactionsGoodsInTransit;
	QueryOptions.BusinessTransactionsUnfacturedDeliveries    = BusinessTransactionsUnfacturedDeliveries;
	QueryOptions.BusinessTransactionsDoNotShareProcurementProcessing = BusinessTransactionsDoNotShareProcurementProcessing;

EndProcedure

// Returns a complete list of business operations for a split purchase
// 
// Returns:
//	Array - an array of elements with the enumeration type of the link.Economic operations.
//
Function EconomicOperationsOfSeparatePurchaseWithoutSelections() Export
	
	Array = New Array;
	
	Array.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	Array.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	Array.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	Array.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
	
	Array.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	Array.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	Array.Add(Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
	Array.Add(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
	
	Array.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	Array.Add(Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
	
	Return Array;
	
EndFunction

// Returns a complete list of business operations for the import customs declaration.
// 
// Returns:
//	Array - an array of elements with the enumeration type of the link.Economic operations.
//
Function BusinessOperationsOfCustomsDeclarationImport() Export
	
	Array = New Array;
	
	Array.Add(Enums.BusinessTransactions.RegisterCCDThroughBroker);
	Array.Add(Enums.BusinessTransactions.RegisterCCDUnassisted);
	
	Return Array;
	
EndFunction

// Returns the full list of supported business operations for Agency purchases under the principal
// 
// Returns:
//  Array - Array from the link enumeration.Economic operations.
//
Function BusinessOperationsForAgencyProcurementUnderPrincipal() Export
	Array = New Array;
	
	Array.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	Array.Add(Enums.BusinessTransactions.ImportFromEAEU);
	
	Return Array;
EndFunction

// Returns the business transaction used for the undivided purchase form.
//
// Parameters:
//	SeparatePurchaseBusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//
// Returns:
//	EnumRef.BusinessTransactions - an economic operation used in the undivided version 
//		of the procurement.
//
Function MainEconomicOperationOfSeparatePurchase(SeparatePurchaseBusinessOperation) Export
	
	UseImports              = GetFunctionalOption("UseImports");
	UseImportOfGoodsFromCustomsUnion = GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
	UseGoodsInTransitFromVendors      = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries     = GetFunctionalOption("UseUninvoicedDeliveries");
	
	If UseGoodsInTransitFromVendors
		Or UseUninvoicedDeliveries Then
		
		BusinessProcurementOperations = New Array;
		BusinessProcurementOperations.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		
		EconomicImportOperations = New Array;
		EconomicImportOperations.Add(Enums.BusinessTransactions.PurchaseByImport);
		
		EconomicOperationsImportFromEAEU = New Array;
		EconomicOperationsImportFromEAEU.Add(Enums.BusinessTransactions.ImportFromEAEU);
		
		BusinessProcurementOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
		BusinessProcurementOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
		EconomicImportOperations.Add(Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
		EconomicImportOperations.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		EconomicOperationsImportFromEAEU.Add(Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
		EconomicOperationsImportFromEAEU.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	
		BusinessProcurementOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
		BusinessProcurementOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
		EconomicOperationsImportFromEAEU.Add(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
		EconomicOperationsImportFromEAEU.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		
		If BusinessProcurementOperations.Find(SeparatePurchaseBusinessOperation) <> Undefined Then
			Return Enums.BusinessTransactions.PurchaseFromSupplier;
		EndIf;
		
		If UseImports Then
			If EconomicImportOperations.Find(SeparatePurchaseBusinessOperation) <> Undefined Then
				Return Enums.BusinessTransactions.PurchaseByImport;
			EndIf;
		EndIf;
		
		If UseImportOfGoodsFromCustomsUnion Then
			If EconomicOperationsImportFromEAEU.Find(SeparatePurchaseBusinessOperation) <> Undefined Then
				Return Enums.BusinessTransactions.ImportFromEAEU;
			EndIf;
		EndIf;
		
		
		Return SeparatePurchaseBusinessOperation;
		
	Else
		Return SeparatePurchaseBusinessOperation;
	EndIf;
	
EndFunction

// Returns the attribute of a separate purchase business operation
//
// Parameters:
//  BusinessOperation	 - EnumRef.BusinessTransactions	 - a business transaction for which you need to define the attribute.
// 
// Returns:
//  Boolean - True if a separate purchase is used.
//
Function ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation) Export
	
	EconomicOperationsOfSeparatePurchase = EconomicOperationsOfSeparatePurchaseWithoutSelections();
	Return EconomicOperationsOfSeparatePurchase.Find(BusinessOperation) <> Undefined;
	
EndFunction

// Returns a match that defines pairs of separate purchase operations.
//
// Parameters:
//  KeyOperationsOfTransferOfOwnershipAre	 - Boolean - inverts the keys and values of the returned match.
// 
// Returns:
//  Map - the key and value are logically identical separate purchase operations,
//              for example, "Procurement of the supplier of the goods on the way" and "Procurement of the supplier of the goods on the way".
//
Function PairsOfSeparatePurchaseOperations(KeyOperationsOfTransferOfOwnershipAre = False) Export
	
	TransferOfOwnershipOperations = New Array(5);
	GoodsReceiptOperations = New Array(5);
	
	TransferOfOwnershipOperations.Insert(0, Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	GoodsReceiptOperations.Insert(0, Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	
	TransferOfOwnershipOperations.Insert(1, Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	GoodsReceiptOperations.Insert(1, Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
	
	TransferOfOwnershipOperations.Insert(2, Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	GoodsReceiptOperations.Insert(2, Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
	
	TransferOfOwnershipOperations.Insert(3, Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	GoodsReceiptOperations.Insert(3, Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
	
	TransferOfOwnershipOperations.Insert(4, Enums.BusinessTransactions.ImportGoodsInTransit);
	GoodsReceiptOperations.Insert(4, Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
	
	ReturnValue = New Map();
	
	For Counter = 0 To 5 Do
		If KeyOperationsOfTransferOfOwnershipAre Then
			ReturnValue.Insert(TransferOfOwnershipOperations[Counter], GoodsReceiptOperations[Counter]);
		Else
			ReturnValue.Insert(GoodsReceiptOperations[Counter], TransferOfOwnershipOperations[Counter]);
		EndIf;
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Initializes and returns the structure of additional contract selection parameters.
// 
// Returns:
//  Structure - structure with properties:
// 	* ARAPCurrency - CatalogRef.Currencies - currency of mutual settlements under the agreement
// 	* Taxation - EnumRef.VATTaxationTypes - type of VAT taxation
// 	* LineOfBusiness - CatalogRef.LinesOfBusiness - direction of activity under the agreement.
// 	* ConsignmentSales25 - Boolean - A sign of attribution of the contract to commission sales of version 2.5.
// 	* RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage - EnumRef.RegistrationOfWriteOffOfGoodsAcceptedForStorage, Undefined -
// 	* ARAPObjectSettings - EnumRef.ARAPObjectSettings, Undefined -
// 	* ContractWithSelfEmployedPerson - Boolean - indicates a Contract with a NAP payer (self-employed).
//
Function AdditionalContractSelectionParameters() Export
	
	FilterParameters = New Structure;
	FilterParameters.Insert("BusinessTransactions");
	FilterParameters.Insert("ARAPCurrency");
	FilterParameters.Insert("Taxation");
	FilterParameters.Insert("LineOfBusiness");
	FilterParameters.Insert("ConsignmentSales25");
	FilterParameters.Insert("RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage");
	FilterParameters.Insert("ARAPObjectSettings");
	FilterParameters.Insert("ContractWithSelfEmployedPerson", False);
	
	Return FilterParameters;
	
EndFunction

// Gets the option to make purchases from the Contract.
//
// Parameters:
//  Contract	 - CatalogRef.CounterpartyContracts - Contract with the counterparty.
// 
// Returns:
//	EnumRef.PurchaseRegistrationOptions - the option of making purchases under the specified Contract.
//
Function GetVariantOfProcurementContract(Contract) Export
	
	PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.EmptyRef();
	If ValueIsFilled(Contract) Then
		SetPrivilegedMode(True);
		PurchaseRegistrationOption = Common.ObjectAttributeValue(Contract, "PurchaseRegistrationOption");
		SetPrivilegedMode(False);
	EndIf;
	
	Return PurchaseRegistrationOption;
	
EndFunction

// Receives the option of processing the receipt documents for services from the Contract.
//
// Parameters:
//  Contract	 - CatalogRef.CounterpartyContracts - Contract with the counterparty.
// 
// Returns:
//	EnumRef.OptionsForRegisteringServiceDocuments - the option of processing documents for services under the specified Contract.
//
Function GetVariantOfRegistrationOfDocumentsForAdmissionToServices(Contract) Export
	
	OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.EmptyRef();
	If ValueIsFilled(Contract) Then
		SetPrivilegedMode(True);
		OptionForRegisteringServiceReceiptDocuments = Common.ObjectAttributeValue(Contract, "OptionForRegisteringServiceReceiptDocuments");
		SetPrivilegedMode(False);
	EndIf;
	
	Return OptionForRegisteringServiceReceiptDocuments;
	
EndFunction

// According to the business of operation of the document and the Contract, it determines whether this document is an unfactured delivery.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - business transaction of the document.
//  Variant formalizations of documents for services - Listing link.Formalizationdocumentservices - a variant of processing documents for services under the specified Contract.
// 
// Returns:
//	Boolean - This is an unfactured delivery.
//
Function ThisIsUnfacturedDeliveryOfServicesWorks(BusinessOperation, OptionOfProcessingDocumentsForServices) Export
	
	InvoicingOperations = New Array;
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	
	UnfacturedDeliveriesOfServicesWorks = InvoicingOperations.Find(BusinessOperation) <> Undefined
		And OptionOfProcessingDocumentsForServices = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced");
	
	Return UnfacturedDeliveriesOfServicesWorks;
	
EndFunction

// See SalesServer.DocumentBasis
//
Function DocumentBasis(Object, SearchFields) Export
	
	Return SalesServer.DocumentBasis(Object, SearchFields);
	
EndFunction

// The procedure establishes conditional registration in the lists for the business transaction of orders to the supplier.
// 
// The presentation of the operations "Purchase from a supplier (delivery invoice)" and "Import from the EAEU (delivery invoice)"
// are changed to "Purchase from a supplier (unfactured delivery)" and "Import from the EAEU (unfactured delivery)", respectively.
// 
// Parameters:
//  Form - ClientApplicationForm - Form for conditional registration:
//  	* List - DynamicList - List of orders to the supplier.
//  	* Items - FormAllItems - Form elements for conditional design:
//  		** BusinessOperation - FormField - A field for displaying a business of operation.
//
Procedure SetConditionalAppearanceOfOperationOfOrderToSupplier(Form) Export
	
	ListOfConditionalAppearance = Form.List.SettingsComposer.Settings.ConditionalAppearance;
	
	//
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Mua hàng từ một nhà cung cấp (Giao hàng chưa có hóa đơn)';
							|ru = 'Закупка у поставщика (неотфактурованная поставка)';
							|en = 'Purchase from vendor (GRNI)'; fa = 'خرید از تأمین‌کننده (کالای دریافت‌شده بدون فاکتور)';
							|it = 'Acquisto dal fornitore (consegna non fatturata)';
							|pl = 'Zakup u dostawcy (niefakturowana dostawa)';
							|tr = 'Tedarikçiden satın alma (teslim edilmemiş teslimat)'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("BusinessOperation");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
	
	Item.Appearance.SetParameterValue("Text", Item.Presentation);
	
	//
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Nhập khẩu từ liên minh kinh tế Á-Âu (cung cấp không có hóa đơn)';
							|ru = 'Ввоз из ЕАЭС (неотфактурованная поставка)';
							|en = 'Import from EAEU (GRNI)'; fa = 'واردات از EAEU (کالای دریافت‌شده بدون فاکتور)';
							|it = 'Importazione dall''UEE (consegna non fatturata)';
							|pl = 'Wwóz z EWG (niefakturowana dostawa)';
							|tr = 'AEB''DEN ithalat (teslim edilmemiş teslimat)'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("BusinessOperation");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
	
	Item.Appearance.SetParameterValue("Text", Item.Presentation);
	
EndProcedure

#EndRegion

#Region ProceduresForCheckingCorrectnessOfFillingInDocuments

// Checks the correctness of filling in the purchase document in accordance with the array of checks
// Called from the procedure of the document "report Processing".
//
// Parameters:
// DocumentPurchases  - DocumentObject - Document to be checked for
// Cancel            - Boolean - flag for refusing to carry out the document.
//
Procedure CheckCorrectnessOfPurchaseDocument(DocumentPurchases, Cancel) Export
	
	// If the document has already been filled in incorrectly, we will not fulfill requests	
	If Cancel Then
		Return;
	EndIf;
	
	// Let's check the availability of roles
	VarianceFromPurchaseConditions = UserRightsCached.VarianceFromPurchaseConditions();
	
	SetPrivilegedMode(True);
	
	// Let's check whether it is necessary to check the range of acceptable prices
	KindOfMaximumAllowablePurchasePrice  = Constants.KindOfMaximumAllowablePurchasePrice.Get();
	CheckPriceRange                = ValueIsFilled(KindOfMaximumAllowablePurchasePrice);
	ThereAreErrorsAgreementIsNotSpecified       = False;
	UseManualDiscounts            = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	UsePartnersProducts   = GetFunctionalOption("UsePartnersProducts");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	UsePriceManagementSystem25       = PriceManagementSystemServerCall.UsePriceManagementSystem25(DocumentPurchases.Date);
	
	WorkingOutGiverSOrder2_5 = GetFunctionalOption("DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment2_5");
	UseAgencyPurchasing			= GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
	
	AllLinesAreCanceled = False;
	ReturnOfMultiTurnContainers = False;
	PresentationOfWarehouseField = Undefined;
	
	// Fill in the array of necessary checks depending on the type of document
	
	ChecksArray = New Array();
	TableName     = DocumentPurchases.Metadata().FullName();
	
	If TableName = "Document.PurchaseOrder" Then
		
		AllLinesAreCanceled = TMCommonUse.AllLinesAreCanceled(DocumentPurchases, "Goods", "Canceled");
		
		NeedToAgree_ = ?(AllLinesAreCanceled, False, Not DocumentPurchases.Approved And Not VarianceFromPurchaseConditions);
	ElsIf TableName = "Document.PurchaseRequest" Then
		
		AllLinesAreCanceled = TMCommonUse.AllLinesAreCanceled(DocumentPurchases, "Goods", "Canceled");
		NeedToAgree_ = Not VarianceFromPurchaseConditions
			And Not DocumentPurchases.Approved // Previously, the application has already been agreed, minor Attributes have been changed.
			And Enums.PurchaseRequestStatuses.AgreedUpon(DocumentPurchases.Status) // Checking the Status setting that needs to be checked.
			And Not AllLinesAreCanceled;
			
	ElsIf TableName = "Document.IssuedLetterOfAuthority"
		Or TableName = "Document.RedemptionOfReturnablePackagingFromVendor"
		Or TableName = "Document.ReturnOfGoodsToVendor"
		Or TableName = "Document.ReceiptOfGoodsToWarehouse"
		Or TableName = "Document.RedemptionOfGoodsFromStorage"
		Or TableName = "Document.GoodsShipmentFromStorage"
		Or TableName = "Document.ReportOnVMIAdjustment"
		Or TableName = "Document.MovementOfProductsAndMaterials"
		Or TableName = "Document.MaterialProviderOrder2_5" 
		Or TableName = "Document.DiscrepancyReportFollowingShipment"
		Or TableName = "Document.CustomerInvoiceIntercompany"
		Or TableName = "Document.DiscrepancyReportFollowingReceipt" Then
		NeedToAgree_ = False;
	Else
		NeedToAgree_ = Not DocumentPurchases.Approved And Not VarianceFromPurchaseConditions;
	EndIf;
	
	// AGREEMENT WITH THE SUPPLIER
	
	If TableName = "Catalog.TermsOfPurchaseFromVendors" Then
		
		ChecksArray.Add("TemporaryTableOfGoods_");
		ReturnOfMultiTurnContainers = DocumentPurchases.ReturnReusablePackage;
		
		If CheckPriceRange And NeedToAgree_ And
			DocumentPurchases.Status <> Enums.StatusesOfTermsOfPurchase.NotApproved Then
			
			ChecksArray.Add("TemporaryTableProcurementDocument");
			ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
			If UsePriceManagementSystem25 Then
				ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
			EndIf;
			ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
			
		EndIf;
		
		If DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
			Or DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
			
			ChecksArray.Add("AvailabilityOfServicesAndWorks");
		EndIf;
	
	// Purchase Request
		
	ElsIf TableName = "Document.PurchaseRequest" Then
	
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("TemporaryTableOfGoods_");
		
		PresentationOfWarehouseField = NStr("vi = 'Người nhận';
											|ru = 'Получатель';
											|en = 'Recipient'; fa = 'گیرنده';
											|it = 'Destinatario';
											|pl = 'Odbiorca';
											|tr = 'Alıcı'");
		ChecksArray.Add("CorrectFillingOfWarehouse");
		ChecksArray.Add("CorrectFillingOfWarehouseInProductsTabularSection");
	
		If UsePartnersProducts Then
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
	
		ChecksArray.Add("CorrectnessOfAmountAndAmountOfVAT");
		
		If NeedToAgree_ Then
			ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
			ChecksArray.Add("TempTableWarehousesCorrectByAgreement");
			ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
			
			If CheckPriceRange Then
				If UsePriceManagementSystem25 Then
					ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
				EndIf;
				ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
			EndIf;
			
		EndIf;
		
	// Order to supplier
		
	ElsIf TableName = "Document.PurchaseOrder" Then
		
		AgreementIsSpecified = ValueIsFilled(DocumentPurchases.Terms);
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("CorrectFillingOfWarehouse");
		ChecksArray.Add("CorrectFillingOfWarehouseInProductsTabularSection");
		ChecksArray.Add("AbilityToWriteOffGoodsForExpenses");
		ChecksArray.Add("ControlOfFillingOfPricesTakingIntoAccountCancelledOnes");
		ReturnOfMultiTurnContainers = DocumentPurchases.ToReturnReusablePackage;
		PackageDepositIsRequired = DocumentPurchases.PackageDepositIsRequired;
		
		If UsePartnersProducts Then
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;

		If Not DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
			ChecksArray.Add("CorrectnessOfAmountAndAmountOfVAT");
		EndIf;
		
		If NeedToAgree_ And
			DocumentPurchases.Status <> Enums.PurchaseOrderStatuses.NotApproved Then
			
			ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
			
			If AgreementIsSpecified Then
				
				If Not DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
					ChecksArray.Add("CorrectIndicationOfVATRate");
				EndIf;
				ChecksArray.Add("TemporaryTableWarehousesCorrectByAgreement");
				ChecksArray.Add("ComplianceOfHeaderWithPurchaseConditions");
				ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
				
			Else
				
				ThereAreErrorsAgreementIsNotSpecified = UseTermsOfPurchases;
				
			EndIf;
			
			If UseManualDiscounts
				And DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement
				And DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
				ChecksArray.Add("ToleranceForManualMarkUpDiscounts");
			EndIf;
			
			If CheckPriceRange Then
				If UsePriceManagementSystem25 Then
					ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
				EndIf;
				ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
			EndIf;
			
			If DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement
				And DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
				And DocumentPurchases.DocumentAmount <> 0
				And DocumentPurchases.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments Then
				
				ChecksArray.Add("TimeTableStagesOfPaymentSchedule");
				ChecksArray.Add("CorrectnessOfPaymentScheduleStages");
				
			EndIf;
			
		EndIf;
		
		ListOfBusinessOperationsExcludingServicesAndWorks = ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks();
		ListOfBusinessOperationsExcludingWork = ProductsServer.ListOfBusinessOperationsExcludingWork();
		ListOfBusinessOfOperationsExcludingTraceableWorks = ProductsServer.ListOfBusinessOfOperationsExcludingTraceableWorks();
		
		If ListOfBusinessOperationsExcludingServicesAndWorks.FindByValue(DocumentPurchases.BusinessOperation) <> Undefined Then
			ChecksArray.Add("AvailabilityOfServicesAndWorks");
		ElsIf ListOfBusinessOperationsExcludingWork.FindByValue(DocumentPurchases.BusinessOperation) <> Undefined Then
			ChecksArray.Add("AvailabilityOfWorks");
		ElsIf ListOfBusinessOfOperationsExcludingTraceableWorks.FindByValue(DocumentPurchases.BusinessOperation) <> Undefined Then
			ChecksArray.Add("AvailabilityOfTraceableWorks");
		EndIf;
		
		PresentationOfWarehouseField = NStr("vi = 'Người nhận';
											|ru = 'Получатель';
											|en = 'Recipient'; fa = 'گیرنده';
											|it = 'Destinatario';
											|pl = 'Odbiorca';
											|tr = 'Alıcı'")
		
	//THE ACT AFTER ACCEPTANCE
	ElsIf TableName = "Document.DiscrepancyReportFollowingReceipt" Then

		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("CorrectFillingOfWarehouseInProductsWithoutWarehouseTabInHeader");
		
	// PURCHASE OF GOODS AND SERVICES
		
	ElsIf TableName = "Document.VendorInvoice" Then
		
		AgreementIsSpecified     = ValueIsFilled(DocumentPurchases.Terms);
		ThereAreErrorsAgreementIsNotSpecified = UseTermsOfPurchases
		                                And Not AgreementIsSpecified
		                                And Not DocumentPurchases.ReceiptUnderOrders
										And Not DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
		                                And NeedToAgree_;

		ChecksArray.Add("TemporaryTableProcurementDocument");
		
		If Not DocumentPurchases.ReceiptUnderOrders And AgreementIsSpecified And NeedToAgree_ Then
			ChecksArray.Add("TemporaryTableWarehousesCorrectByAgreement");
			ChecksArray.Add("ComplianceOfHeaderWithPurchaseConditions");
		EndIf;
		
		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("CorrectFillingOfWarehouse");
		ChecksArray.Add("CorrectFillingOfWarehouseInProductsTabularSection");
		If UsePartnersProducts Then
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
		
		ChecksArray.Add("PriceFillingControl");
		ChecksArray.Add("CorrectnessOfAmountAndAmountOfVAT");
		ChecksArray.Add("AbilityToWriteOffGoodsForExpenses");
		
		ReturnOfMultiTurnContainers = DocumentPurchases.ToReturnReusablePackage;
		PackageDepositIsRequired = DocumentPurchases.PackageDepositIsRequired;
		
		ListOfBusinessOperationsExcludingServicesAndWorks = ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks();
		ListOfBusinessOperationsExcludingWork = ProductsServer.ListOfBusinessOperationsExcludingWork();
		ListOfBusinessOfOperationsExcludingTraceableWorks = ProductsServer.ListOfBusinessOfOperationsExcludingTraceableWorks();
		
		If ListOfBusinessOperationsExcludingServicesAndWorks.FindByValue(DocumentPurchases.BusinessOperation) <> Undefined Then
			ChecksArray.Add("AvailabilityOfServicesAndWorks");
		ElsIf ListOfBusinessOperationsExcludingWork.FindByValue(DocumentPurchases.BusinessOperation) <> Undefined Then
			ChecksArray.Add("AvailabilityOfWorks");
		ElsIf ListOfBusinessOfOperationsExcludingTraceableWorks.FindByValue(DocumentPurchases.BusinessOperation) <> Undefined Then
			ChecksArray.Add("AvailabilityOfTraceableWorks");
		EndIf;
		
		ThisIsPurchaseOfWorksUnderProcessingContract = False;
		If ValueIsFilled(DocumentPurchases.Contract) Then
			ContractType = Common.ObjectAttributeValue(DocumentPurchases.Contract, "ContractType");
			ThisIsPurchaseOfWorksUnderProcessingContract = (ContractType = Enums.ContractTypes.TransferToTolling2_5
													Or ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries);
		EndIf;
		
		If ThisIsPurchaseOfWorksUnderProcessingContract Then
			ChecksArray.Add("AvailabilityOfItemsUnderProcessingContract");
		EndIf;
			
		If NeedToAgree_ Then
			
			ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
			
			If AgreementIsSpecified Then
				ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
				ChecksArray.Add("CorrectIndicationOfVATRate");
			EndIf;
			
			If AgreementIsSpecified
				And UseManualDiscounts
				And DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement Then
				ChecksArray.Add("ToleranceForManualMarkUpDiscounts");
			EndIf;
				
			If CheckPriceRange Then
				If UsePriceManagementSystem25 Then
					ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
				EndIf;
				ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
			EndIf;
			
		EndIf;
		
		PresentationOfWarehouseField = NStr("vi = 'Người nhận';
											|ru = 'Получатель';
											|en = 'Recipient'; fa = 'گیرنده';
											|it = 'Destinatario';
											|pl = 'Odbiorca';
											|tr = 'Alıcı'")
		
	ElsIf TableName = "Document.CustomerInvoiceIntercompany" Then
		
		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("CorrectFillingOfWarehouse");

	ElsIf TableName = "Document.RedemptionOfReturnablePackagingFromVendor" Then
		
		If UsePartnersProducts Then
			ChecksArray.Add("TemporaryTableOfGoods_");
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
		
	ElsIf TableName = "Document.IssuedLetterOfAuthority" Then
		
		If UsePartnersProducts Then
			ChecksArray.Add("TemporaryTableOfGoods_");
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
		
		
	// MOVEMENT OF PRODUCTS AND MATERIALS
	ElsIf TableName = "Document.MovementOfProductsAndMaterials" Then
		
		If DocumentPurchases.ByReferences Then
			ChecksArray.Add("TemporaryTableProcurementDocument");
			ChecksArray.Add("TemporaryTableOfGoods_");
			ChecksArray.Add("ComplianceOfOrganizationWithOrders");
		EndIf;
	
	// GIVER'S ORDER
	
	ElsIf TableName = "Document.MaterialProviderOrder2_5" Then
		
		If DocumentPurchases.Status = Enums.StatusesOfMaterialProviderOrders.Closed And Not AllLinesAreCanceled Then
			
			If WorkingOutGiverSOrder2_5 Then
				ChecksArray.Add("ReceiptControl");
			EndIf;
			
		EndIf;

	// INCOME ADJUSTMENT
		
	ElsIf TableName = "Document.PurchaseAdjustment" Then
		
		ThereAreErrorsAgreementIsNotSpecified = False;
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("CorrectFillingOfWarehouse");
		ChecksArray.Add("CorrectFillingOfWarehouseInProductsTabularSection");
		ChecksArray.Add("CorrectnessOfAmountAndAmountOfVAT");
		
		If UsePartnersProducts Then
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
		
		PresentationOfWarehouseField = NStr("vi = 'Người nhận';
											|ru = 'Получатель';
											|en = 'Recipient'; fa = 'گیرنده';
											|it = 'Destinatario';
											|pl = 'Odbiorca';
											|tr = 'Alıcı'");
		
	// RETURN OF GOODS TO THE SUPPLIER
		
	ElsIf TableName = "Document.ReturnOfGoodsToVendor" Then
		
		If DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			ChecksArray.Add("TemporaryTableProcurementDocument");
			ChecksArray.Add("TemporaryTableOfGoods_");
			ChecksArray.Add("PriceFillingControl");
			ChecksArray.Add("CorrectnessOfAmountAndAmountOfVAT");
			
			If UseAgencyPurchasing Then
				ChecksArray.Add("CurrencyMatchingForAgencyPurchases");
			EndIf;
			
			ChecksArray.Add("CorrectFillingOfWarehouseInProductsTabularSection");
			
			ReturnOfMultiTurnContainers = DocumentPurchases.ReturnOfReceivedReusablePackages;
			PackageDepositIsRequired = DocumentPurchases.DepositForPackageIsRequired;
		EndIf;
		
		PresentationOfWarehouseField = NStr("vi = 'Người gửi';
											|ru = 'Отправитель';
											|en = 'Sender'; fa = 'فرستنده';
											|it = 'Отправитель';
											|pl = 'Sender';
											|tr = 'Gönderici'")
		
	// Shipment of goods from storage
		
	ElsIf TableName = "Document.GoodsShipmentFromStorage" Then
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("CorrectFillingOfWarehouseInProductsTabularSection");
		If DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.TransferToMaterialProvider2_5
		   And DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			ChecksArray.Add("PriceFillingControl");
		EndIf;
		If UsePartnersProducts Then
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
		
		If DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			ChecksArray.Add("ControlOfAssignmentFilling");
			If DocumentPurchases.ByOrder Then
				ChecksArray.Add("ControlOfFillingOfCustomerSOrder");
			EndIf;
		EndIf;
		
		ReturnOfMultiTurnContainers = False;
		PackageDepositIsRequired      = False;
		
	// Acceptance of goods for storage
		
	ElsIf TableName = "Document.GoodsReceiptForStorage" Then
		
		AgreementIsSpecified     = ValueIsFilled(DocumentPurchases.Terms);
		ThereAreErrorsAgreementIsNotSpecified = UseTermsOfPurchases
		                                And Not DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
		                                And Not AgreementIsSpecified
		                                And Not DocumentPurchases.ReceiptUnderOrders
		                                And NeedToAgree_;

		ChecksArray.Add("TemporaryTableProcurementDocument");
		
		If Not DocumentPurchases.ReceiptUnderOrders And AgreementIsSpecified And NeedToAgree_ Then
			ChecksArray.Add("TemporaryTableWarehousesCorrectByAgreement");
			ChecksArray.Add("ComplianceOfHeaderWithPurchaseConditions");
		EndIf;
		
		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("CorrectFillingOfWarehouseInProductsTabularSection");
		If UsePartnersProducts Then
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
		If Not DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ChecksArray.Add("PriceFillingControl");
		EndIf;
		ReturnOfMultiTurnContainers = False;
		PackageDepositIsRequired = False;
		
		If NeedToAgree_ Then
			
			ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
			
			If AgreementIsSpecified Then
				ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
			EndIf;
			
			If CheckPriceRange
				And Not DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
				And True Then
				If UsePriceManagementSystem25 Then
					ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
				EndIf;
				ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
			EndIf;
			
		EndIf;
		
	//REPURCHASE OF GOODS ACCEPTED FOR STORAGE
		
	ElsIf TableName = "Document.RedemptionOfGoodsFromStorage" Then
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("CorrectFillingOfStorageLocations");
		ChecksArray.Add("PriceFillingControl");
		ChecksArray.Add("CorrectnessOfAmountAndAmountOfVAT");
		
		If UsePartnersProducts Then
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
		
		ReturnOfMultiTurnContainers = False;
		PackageDepositIsRequired      = False;
		
	//Report On The Write-Off Of Goods From Storage
		
	ElsIf TableName = "Document.ReportOnVMIAdjustment" Then
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("TemporaryTableOfGoods_");
		ChecksArray.Add("CorrectFillingOfStorageLocations");
		
		If DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
			Or DocumentPurchases.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
			Or False Then
			ChecksArray.Add("PriceFillingControl");
		EndIf;
		
		If UsePartnersProducts Then
			ChecksArray.Add("CorrectFillingInOfPartnerProducts");
		EndIf;
		
		ReturnOfMultiTurnContainers = False;
		PackageDepositIsRequired      = False;
		
	EndIf;
	
	// Let's form the text of the request for the necessary checks in accordance with the array of checks
	
	QueryText     = "";
	QueryOptions = New Structure();

	QueryOptions.Insert("Date",                      DocumentPurchases.Date);
	QueryOptions.Insert("Ref",                    DocumentPurchases.Ref);
	QueryOptions.Insert("ReturnOfMultiTurnContainers", ReturnOfMultiTurnContainers);
	QueryOptions.Insert("PackageDepositIsRequired",      PackageDepositIsRequired);
	QueryOptions.Insert("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentPurchases.Organization));
	QueryOptions.Insert("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(DocumentPurchases.Organization));
	QueryOptions.Insert("UseTraceableImportedGoodsAccounting",
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date(1,1,1)));
	QueryOptions.Insert("DateOfTraceableImportedGoodsAccountingStart",
		AccountingForTraceableGoodsLocalization.DateOfTraceableImportedGoodsAccountingStart());
	
	For Each CurItem In ChecksArray Do
		
		If CurItem = "TemporaryTableProcurementDocument" Then
			
			CreateRequestTemporaryTablePurchaseDocumentHeader(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "TemporaryTableOfGoods_" Then
			
			GenerateTemporaryTableProductsQueryInPurchaseDocument(QueryText, QueryOptions, DocumentPurchases, TableName);
			
		ElsIf CurItem = "TemporaryTableWarehousesCorrectByAgreement" Then
			
			GenerateRequestTemporaryTableWarehousesCorrectByAgreement(QueryText);
			
		ElsIf CurItem = "TempTableWarehousesCorrectByAgreement" Then
			
			CreateQueryTempTableWarehousesCorrectByAgreement(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "ComplianceOfHeaderWithPurchaseConditions" Then
			
			GenerateRequestPurchaseDocumentHeader(QueryText, TableName);
			
		ElsIf CurItem = "TimeTableStagesOfPaymentSchedule" Then
			
			CreateRequestTemporaryTablePaymentStages(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "TemporaryTableCurrencyExchangeRates" Then
			
			GenerateQueryTemporaryTableCurrencyExchangeRates(QueryText);
			
		ElsIf CurItem = "CorrectFillingInOfPartnerProducts" Then
			
			PartnersProductsServer.GenerateRequestForFillingInPartnerProductListCorrectly(QueryText, QueryOptions);
			
		ElsIf CurItem = "GoodsComplianceWithPurchasingConditions" Then
			
			GenerateRequestProductsOfPurchaseDocument(QueryText, TableName);
			
		ElsIf CurItem = "EntryOfPricesIntoAcceptableRange" Then
			
			If UsePriceManagementSystem25 Then
				GenerateRequestForPricesInAcceptableRange2_5(QueryText);
			Else
				GenerateRequestForPricesInAcceptableRange(QueryText);
			EndIf;
			
		ElsIf CurItem = "CorrectnessOfFillingOutServiceAnalytics" Then
			
			GenerateRequestForCorrectnessOfFillingOutServiceAnalytics(QueryText);
			
		ElsIf CurItem = "AvailabilityOfServicesAndWorks" Then
			
			GenerateRequestForAvailabilityOfServicesAndWorksInPurchaseDocument(QueryText);
			
		ElsIf CurItem = "AvailabilityOfWorks" Then
			
			GenerateRequestForAvailabilityOfWorksInPurchaseDocument(QueryText);
		
		ElsIf CurItem = "AvailabilityOfItemsUnderProcessingContract" Then 
			
			GenerateRequestForAvailabilityOfItemsOfServicesInPurchasingDocument(QueryText);
			
		ElsIf CurItem = "AvailabilityOfTraceableWorks" Then
			
			GenerateRequestForTraceableWorksInPurchaseDocument(QueryText);
			
		ElsIf CurItem = "ToleranceForManualMarkUpDiscounts" Then
			
			GenerateRequestWhetherManualDiscountsAndSurchargesAreAcceptable(QueryText);
			
		ElsIf  CurItem = "CorrectFillingOfWarehouse" Then
			
			GenerateRequestWhetherWarehouseIsFilledInCorrectly(QueryText);
			
		ElsIf  CurItem = "CorrectFillingOfWarehouseInProductsTabularSection" Then
			
			GenerateRequestForCorrectFillingOfWarehousesInProductsTabularSection(QueryText);
			
		ElsIf  CurItem = "CorrectFillingOfWarehouseInProductsWithoutWarehouseTabInHeader" Then
		
			GenerateRequestForCorrectnessOfFillingWarehousesInTablePartProductsWithoutWarehouseInHeader(QueryText);
			
		ElsIf CurItem = "CorrectnessOfPaymentScheduleStages" Then
			
			GenerateRequestForCorrectnessOfPaymentScheduleStages(QueryText);
		ElsIf CurItem = "ControlOfCompletionOfCalculations" Then
			
			GenerateRequestForPaymentCompletionControl(QueryText);
			
		ElsIf CurItem = "CorrectFillingOfStorageLocations" Then
			
			GenerateRequestForCorrectFillingOfStorageLocations(QueryText);
			
		ElsIf CurItem = "ReceiptControl" Then
			
			GenerateReceiptControlRequest(QueryText);
		ElsIf CurItem = "ControlOfFillingOfPricesTakingIntoAccountCancelledOnes" Then
			
			CreateRequestToControlFillingInPricesBasedOnCanceledPrices(QueryText);
			
		ElsIf CurItem = "PriceFillingControl" Then
			
			GenerateRequestToFillInPrices(QueryText);
			
		ElsIf CurItem = "ComplianceOfOrganizationWithOrders" Then
			
			GenerateRequestForComplianceWithOrganizationOfOrders(QueryText);
		
		ElsIf  CurItem = "CorrectIndicationOfVATRate" Then
			
			GenerateRequestToSpecifyPurchaseVATRateCorrectly(QueryText);
		
		ElsIf  CurItem = "CorrectnessOfAmountAndAmountOfVAT" Then
			
			GenerateRequestForCorrectnessOfPurchaseAmountAndVATAmount(QueryText);
			
		ElsIf  CurItem = "CurrencyMatchingForAgencyPurchases" Then
			
			GenerateCurrencyMatchingRequestForAgencyPurchases(QueryText);
			
		ElsIf  CurItem = "ControlOfFillingOfCustomerSOrder" Then
			
			GenerateRequestForFillingClientSOrder(QueryText);
			
		ElsIf  CurItem = "ControlOfAssignmentFilling" Then
			
			GenerateDestinationControlRequest(QueryText);
			
		ElsIf  CurItem = "AbilityToWriteOffGoodsForExpenses" Then
			
			GenerateRequestToDeductItemsForExpenses(QueryText);
			
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(QueryText) Then
		SetPrivilegedMode(False);
		Return;
	EndIf;

	Query = New Query(QueryText);
	
	For Each QueryParameter In QueryOptions Do
		Query.SetParameter(QueryParameter.Key,QueryParameter.Value);
	EndDo;
	
	ResultsArray = Query.ExecuteBatch(); 
	
	// We will inform the user about the verification results for each query result
	ImpossibleToHoldWithoutApproval = False;
	For CurIndex__ = 0 To ResultsArray.Count()-1 Do
		
		Selection = ResultsArray[CurIndex__].Select();
		
		If ChecksArray[CurIndex__] = "ComplianceOfHeaderWithPurchaseConditions" Then
			
			ReportErrorsPurchaseDocumentHeader(Selection, DocumentPurchases, ImpossibleToHoldWithoutApproval);
			
		ElsIf ChecksArray[CurIndex__] = "CorrectFillingInOfPartnerProducts" Then
			
			PartnersProductsServer.ReportErrorsCorrectFillingOfPartnerProducts(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "GoodsComplianceWithPurchasingConditions" Then
			
			ReportErrorsInPurchaseDocument(Selection,DocumentPurchases, ImpossibleToHoldWithoutApproval);
			
		ElsIf ChecksArray[CurIndex__] = "EntryOfPricesIntoAcceptableRange" Then
			
			ReportErrorsWhenPricesFallWithinAcceptableRange(Selection, DocumentPurchases, Cancel, UseManualDiscounts);
			
		ElsIf ChecksArray[CurIndex__] = "CorrectnessOfFillingOutServiceAnalytics" Then
			
			ReportErrorsCorrectnessOfServiceAnalytics(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "AvailabilityOfServicesAndWorks"
			Or ChecksArray[CurIndex__] = "AvailabilityOfWorks" Then
			
			ReportErrorsAvailabilityOfServicesWorksInPurchaseDocument(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "AvailabilityOfItemsUnderProcessingContract" Then
		
			ReportErrorsAvailabilityOfItemsOfServicesWorksInPurchasingDocument(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "AvailabilityOfTraceableWorks" Then
			
			ReportErrorsAboutTraceableWorksInPurchaseDocument(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "ToleranceForManualMarkUpDiscounts" Then
			
			ReportErrorsAcceptanceOfManualDiscountsMargins(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "CorrectFillingOfWarehouse" Then
			
			ReportErrorsCorrectWarehouseFilling(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "CorrectFillingOfWarehouseInProductsTabularSection"
			Or ChecksArray[CurIndex__] = "CorrectFillingOfWarehouseInProductsWithoutWarehouseTabInHeader" Then
			
			ReportErrorsInFillingOutWarehouseCorrectlyInProductsTabularSection(Selection, DocumentPurchases, Cancel, PresentationOfWarehouseField);
			
		ElsIf ChecksArray[CurIndex__] = "CorrectnessOfPaymentScheduleStages" Then
			
			ReportErrorsCorrectnessOfPaymentScheduleStages(Selection, DocumentPurchases, ImpossibleToHoldWithoutApproval);
		ElsIf ChecksArray[CurIndex__] = "ControlOfCompletionOfCalculations" Then
			
			ReportErrorsMonitoringCompletionOfCalculations(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "ReceiptControl" Then
			
			ReportErrorsReceiptControl(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "CorrectFillingOfStorageLocations" Then
			
			ReportErrorsCorrectFillingOfStorageLocations(Selection, DocumentPurchases, Cancel);
		ElsIf ChecksArray[CurIndex__] = "PriceFillingControl"
			Or ChecksArray[CurIndex__] = "ControlOfFillingOfPricesTakingIntoAccountCancelledOnes" Then
			
			ReportErrorsPriceFillingControl(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "ComplianceOfOrganizationWithOrders" Then
			
			ReportErrorsInOrganizingOrders(Selection, DocumentPurchases, Cancel);
		
		ElsIf ChecksArray[CurIndex__] = "CorrectIndicationOfVATRate" Then
			
			ReportErrorsWhenSpecifyingPurchaseVATRateCorrectly(Selection, DocumentPurchases, Cancel);
		
		ElsIf ChecksArray[CurIndex__] = "CorrectnessOfAmountAndAmountOfVAT" Then
			
			ReportErrorsCorrectnessOfPurchaseAmountAndVATAmount(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "CurrencyMatchingForAgencyPurchases" Then
			
			ReportCurrencyMatchingErrorsForAgencyPurchases(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "ControlOfFillingOfCustomerSOrder" Then
			
			ReportErrorsCustomerOrderControl(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "ControlOfAssignmentFilling" Then
			
			ReportErrorsDestinationControl(Selection, DocumentPurchases, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "AbilityToWriteOffGoodsForExpenses" Then
			
			ReportErrorsAbilityToChargeItemsForExpenses(Selection, DocumentPurchases, Cancel);
			
		EndIf;
		
	EndDo;
	
	ReportErrorsAgreementNotSpecified(ThereAreErrorsAgreementIsNotSpecified, DocumentPurchases, Cancel);
	
	If ImpossibleToHoldWithoutApproval Then
		ErrorText = NStr("vi = 'Không đủ quyền để làm sai lệch điều kiện mua hàng.';
						|ru = 'Недостаточно прав на отклонение от условий закупок.';
						|en = 'Insufficient rights to deviate from purchase conditions.'; fa = 'Insufficient rights to deviate from purchase conditions.';
						|it = 'Diritti insufficienti per variazioni dalle condizioni di acquisto.';
						|pl = 'Nie wystarczające uprawnienia do odejścia od warunków zakupów.';
						|tr = 'Satın alma şartlarından sapma yetkisi eksik.'");
		
		UseStatuses = GetFunctionalOption("UsePurchaseOrderStatuses");
		
		If (TableName = "Document.PurchaseOrder" And UseStatuses)
			Or TableName = "Document.PurchaseRequest" Then 
			ErrorText = ErrorText + Chars.LF + NStr("vi = 'Cần kết chuyển chứng từ với trạng thái ""Cần thống nhất"".';
													|ru = 'Документ необходимо провести в статусе ""На согласовании"".';
													|en = 'Post the document in the ""Pending approval"" status.'; fa = 'Post the document in the ""Pending approval"" status.';
													|it = 'È necessario impostare il documento sullo stato ""In approvazione""';
													|pl = 'Dokument należy zatwierdzić w statusie ""Na uzgodnienie"".';
													|tr = 'Belge ""Onay bekliyor"" durumunda kaydedilmelidir.'");
		EndIf;
		
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			,
			,
			Cancel);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure CheckSeparateRegistrationOfGoods(Organization, BusinessOperation, Contract, GoodsTable, Cancel) Export

	If Not(BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery) Then
		Return;
	EndIf;
	
	PurchaseRegistrationOption = Common.ObjectAttributeValue(Contract, "PurchaseRegistrationOption");

	If PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS Products
	|INTO TTProducts_1
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.LineNumber AS LineNumber,
	|	CatProducts.ItemsType AS ItemsType,
	|	CatProducts.Ref AS Ref
	|FROM
	|	Catalog.Products AS CatProducts
	|		INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON CatProducts.Ref = TTProducts_1.Products
	|WHERE
	|	CatProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	Query.SetParameter("GoodsTable", GoodsTable);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		MessageTemplate = NStr("ru = 'По организации ""%1"" в договоре ""%2"" не установлено раздельное оформление товаров, 
			|Проведение документа с хозяйственной операцией ""%3"" для товаров не допускается';
			|vi = 'Separate registration of goods is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for goods';
			|en = 'Separate registration of goods is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for goods'; fa = 'Separate registration of goods is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for goods';
			|it = 'Separate registration of goods is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for goods';
			|pl = 'Separate registration of goods is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for goods';
			|tr = '“%1“ organizasyonunda “%2“ sözleşmesinde mallar için ayrı düzenleme belirlenmemiş.
			| Ürünler için “%3“ ticari işlemli belge kaydedilemez.'");
		
		MessageText = StrTemplate(MessageTemplate, Organization, Contract, BusinessOperation);	
		
		Common.MessageToUser(MessageText,,,, Cancel);
		
		Selection = Result.Select();
		
		While Selection.Next() Do
			MessageTemplate = NStr("ru = 'В строке %1 списка ""Товары"" выбрана номенклатура ""%2"" с типом ""%3""';
									|vi = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected';
									|en = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected'; fa = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected';
									|it = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected';
									|pl = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected';
									|tr = '""Ürünler"" liste satırında %1 türü  ""%3"" olan öğe ""%2"" seçildi'");
			
			MessageText = StrTemplate(MessageTemplate, Selection.LineNumber, Selection.Ref, Selection.ItemsType);
			
			CommonClientServer.MessageToUser(MessageText,,,, Cancel);		
		EndDo;
	EndIf;

EndProcedure

// Checks the correctness of filling in the purchase document in accordance with the array of checks
// by executing a batch of requests.
//
// Parameters:
//		DocumentPurchases - DocumentRef - reference to the object to be checked for
//		ThereAreVariancesFromPriceConditions - Boolean - It is set in the procedure if it is necessary to further agree on price conditions
//		ThereAreVariancesFromFinancialConditions - Boolean - It is established in the procedure if it is necessary to further agree on financial terms
//		ThereAreVariancesFromLogisticConditions - Boolean - It is set in the procedure if it is necessary to further coordinate the logistics conditions.
//
Procedure CheckNeedToAgreeOnTermsOfPurchase(Val DocumentPurchases,
	                                                       ThereAreVariancesFromPriceConditions,
	                                                       ThereAreVariancesFromFinancialConditions,
	                                                       ThereAreVariancesFromLogisticConditions) Export
	
	AgreementOfProcurementDocument = Common.ObjectAttributeValue(DocumentPurchases, "Terms");
	If Not ValueIsFilled(AgreementOfProcurementDocument) Then
		
		ThereAreVariancesFromPriceConditions = True;
		ThereAreVariancesFromFinancialConditions = True;
		ThereAreVariancesFromLogisticConditions= True;
		
		Return;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	TableName     = DocumentPurchases.Metadata().FullName();
	
	// Let's check whether it is necessary to check the range of acceptable prices
	KindOfMaximumAllowablePurchasePrice = Constants.KindOfMaximumAllowablePurchasePrice.Get();
	CheckPriceRange = ValueIsFilled(KindOfMaximumAllowablePurchasePrice);
	
	// Let's check whether it is necessary to check discounts and margins
	UseManualDiscounts = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	
	NamesOfPurchaseDetails = "BusinessOperation, Date, Terms, DocumentAmount, ToReturnReusablePackage, Organization";
	
	FillInPackagingDepositAccordingToDocument = False;
	If DocumentPurchases.Metadata().Attributes.Find("PackageDepositIsRequired") <> Undefined Then
		NamesOfPurchaseDetails = NamesOfPurchaseDetails +", PackageDepositIsRequired";
		FillInPackagingDepositAccordingToDocument = True;
	EndIf;
	
	AttributesOfPurchaseDocument = Common.ObjectAttributesValues(DocumentPurchases, NamesOfPurchaseDetails);
	
	// Let's check whether the document is accepted for commission
	DocumentOfAdmissionToCommission = AttributesOfPurchaseDocument.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement;
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(AttributesOfPurchaseDocument.Date);
	
	// Fill in the array of necessary checks depending on the type of document
	
	ChecksArray  = New Array();
	
	If Not ValueIsFilled(AttributesOfPurchaseDocument.Terms) Then
		
		ThereAreVariancesFromPriceConditions = True;
		ThereAreVariancesFromFinancialConditions = True;
		ThereAreVariancesFromLogisticConditions= True;
		
		SetPrivilegedMode(False);
		Return;
		
	EndIf;
	
	ChecksArray.Add("TemporaryTableProcurementDocument");
	ChecksArray.Add("TemporaryTableOfGoods_");
	ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
	 
	ChecksArray.Add("TemporaryTableWarehousesCorrectByAgreement");
	
	ChecksArray.Add("ComplianceOfHeaderWithPurchaseConditions");
	ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
	
	If UseManualDiscounts And Not DocumentOfAdmissionToCommission Then
		ChecksArray.Add("ToleranceForManualMarkUpDiscounts");
	EndIf;
	
	If CheckPriceRange Then
		If UsePriceManagementSystem25 Then
			ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
		EndIf;
		ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
	EndIf;
	
	If Not DocumentOfAdmissionToCommission And AttributesOfPurchaseDocument.DocumentAmount <> 0 Then
		
		ChecksArray.Add("TimeTableStagesOfPaymentSchedule");
		ChecksArray.Add("CorrectnessOfPaymentScheduleStages");
		
	EndIf;
	
	If TableName = "Document.PurchaseOrder" 
		Or TableName = "Document.VendorInvoice" Then 
			AgreementIsSpecified = ValueIsFilled(AttributesOfPurchaseDocument.Terms);
			If AgreementIsSpecified Then
				ChecksArray.Add("CorrectIndicationOfVATRate");
			EndIf;
	EndIf;		
			
	
	PackageDepositIsRequired = ?(FillInPackagingDepositAccordingToDocument, AttributesOfPurchaseDocument.PackageDepositIsRequired, False);
	
	// We will form a verification request
	
	QueryText = "";
	QueryOptions = New Structure();
	
	QueryOptions.Insert("Date", AttributesOfPurchaseDocument.Date);
	QueryOptions.Insert("ReturnOfMultiTurnContainers",AttributesOfPurchaseDocument.ToReturnReusablePackage);
	QueryOptions.Insert("PackageDepositIsRequired", PackageDepositIsRequired);
	QueryOptions.Insert("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(AttributesOfPurchaseDocument.Organization));
	QueryOptions.Insert("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(AttributesOfPurchaseDocument.Organization));
	
	For Each CurItem In ChecksArray Do
		
		If CurItem = "TemporaryTableProcurementDocument" Then
			
			CreateRequestTemporaryTablePurchaseDocumentHeader(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "TemporaryTableOfGoods_" Then
			
			GenerateTemporaryTableProductsQueryInPurchaseDocument(QueryText, QueryOptions, DocumentPurchases, TableName);
			
		ElsIf CurItem = "TemporaryTableCurrencyExchangeRates" Then
			
			GenerateQueryTemporaryTableCurrencyExchangeRates(QueryText);
			
		ElsIf CurItem = "TemporaryTableWarehousesCorrectByAgreement" Then
			
			GenerateRequestTemporaryTableWarehousesCorrectByAgreement(QueryText);
			
		ElsIf CurItem = "TempTableWarehousesCorrectByAgreement" Then
			
			CreateQueryTempTableWarehousesCorrectByAgreement(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "ComplianceOfHeaderWithPurchaseConditions" Then
			
			GenerateRequestPurchaseDocumentHeader(QueryText, TableName);
			
		ElsIf CurItem = "TimeTableStagesOfPaymentSchedule" Then
			
			CreateRequestTemporaryTablePaymentStages(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "GoodsComplianceWithPurchasingConditions" Then
			
			GenerateRequestProductsOfPurchaseDocument(QueryText, TableName);
			
		ElsIf CurItem = "EntryOfPricesIntoAcceptableRange" Then
			
			If UsePriceManagementSystem25 Then
				GenerateRequestForPricesInAcceptableRange2_5(QueryText);
			Else
				GenerateRequestForPricesInAcceptableRange(QueryText);
			EndIf;
			
		ElsIf CurItem = "ToleranceForManualMarkUpDiscounts" Then
			
			GenerateRequestWhetherManualDiscountsAndSurchargesAreAcceptable(QueryText);
			
		ElsIf  CurItem = "CorrectFillingOfWarehouse" Then
			
			GenerateRequestWhetherWarehouseIsFilledInCorrectly(QueryText);
			
		ElsIf CurItem = "CorrectnessOfPaymentScheduleStages" Then
			
			GenerateRequestForCorrectnessOfPaymentScheduleStages(QueryText);
		
		ElsIf CurItem = "CorrectIndicationOfVATRate" Then
			
			GenerateRequestToSpecifyPurchaseVATRateCorrectly(QueryText);
			
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(QueryText) Then
		
		ThereAreVariancesFromPriceConditions = True;
		ThereAreVariancesFromFinancialConditions = True;
		ThereAreVariancesFromLogisticConditions= True;
		
		SetPrivilegedMode(False);
		Return;
		
	EndIf;
	
	Query = New Query(QueryText);
	
	For Each QueryParameter In QueryOptions Do
		Query.SetParameter(QueryParameter.Key,QueryParameter.Value);
	EndDo;
	
	ResultsArray = Query.ExecuteBatch(); 
	
	// Let's define the validation results for each query result
	
	For CurIndex__ = 0 To ResultsArray.Count()-1 Do
		
		// If there are deviations from all the conditions being checked, no further verification is required.
		If ThereAreVariancesFromPriceConditions And 
			ThereAreVariancesFromFinancialConditions And 
			ThereAreVariancesFromLogisticConditions Then
			Break;
		EndIf;
		
		CurItem = ChecksArray[CurIndex__];
		Selection = ResultsArray[CurIndex__].Select();
		
		If CurItem = "ComplianceOfHeaderWithPurchaseConditions" Then
			
			While Selection.Next() Do
				If ThereAreVariancesFromPriceConditions And ThereAreVariancesFromLogisticConditions And ThereAreVariancesFromFinancialConditions Then
					Break;
				EndIf;
				If Selection.ThereAreErrorsInFillingInCurrency // The currency should not differ from the value in the agreement
					Or Selection.ThereAreErrorsInFillingPriceIncludesVAT Then // The sign ""Price includes VAT"" should not differ from the value in the agreement
					ThereAreVariancesFromPriceConditions = True;
				EndIf;
				If Selection.ThereAreErrorsFillingWarehouse Then // The warehouse must not differ from the value in the agreement
					ThereAreVariancesFromLogisticConditions = True;
				EndIf;
				If Selection.ThereAreErrorsFillingOutPaymentForm Then // The payment form should not differ from the value in the agreement
					ThereAreVariancesFromFinancialConditions = True;
				EndIf;
			EndDo;
			
		ElsIf CurItem = "GoodsComplianceWithPurchasingConditions" Then
			
			While Selection.Next() Do
				If ThereAreVariancesFromPriceConditions Then
					Break;
				EndIf;
				If Selection.ThereAreErrorsMaximumAllowablePrice Then // The price must not exceed the maximum allowable
					
					ThereAreVariancesFromPriceConditions = True;
					Break;
				EndIf;
			EndDo;
			
		ElsIf CurItem = "EntryOfPricesIntoAcceptableRange" Then
			
			While Selection.Next() Do
				If ThereAreVariancesFromPriceConditions Then
					Break;
				EndIf;
				If Selection.ThereAreErrorsMaximumAllowablePrice Then
					ThereAreVariancesFromPriceConditions = True;
					Break;
				EndIf;
			EndDo;
			
		ElsIf CurItem = "ToleranceForManualMarkUpDiscounts" Then
			
			While Selection.Next() Do
				If ThereAreVariancesFromPriceConditions Then
					Break;
				EndIf;
				If Selection.ThereAreErrorsFillingManualMarkUp Then
					ThereAreVariancesFromPriceConditions = True;
					Break;
				EndIf;
			EndDo;
			
		ElsIf CurItem = "CorrectnessOfPaymentScheduleStages" Then
			
			DefaultGraph = New ValueTable();
			DefaultGraph.Columns.Add("PaymentOption");
			DefaultGraph.Columns.Add("CalculateFrom");
			DefaultGraph.Columns.Add("PaymentDate");
			DefaultGraph.Columns.Add("PaymentPercentage");
			DefaultGraph.Columns.Add("PaymentAmount");
			DefaultGraph.Columns.Add("PackageDepositPercentage");
			DefaultGraph.Columns.Add("PackageDepositValue");
			DefaultGraph.Columns.Add("Move");
			DefaultGraph.Columns.Add("Formula");
			
			If Selection.Next() 
				And Not Selection.InvoiceForOrders Then
				FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
				FillParameters.TheseAreSettlementsWithCustomers = False;
				FillParameters.InvoiceForOrders   = False;
				FillParameters.ARAPObjectSettings      = Selection.ARAPObjectSettings;
				FillParameters.ThisIsOrder             = Selection.ThisIsOrder;
				FillParameters.OrderDate           = ?(Selection.ThisIsOrder,Selection.Date,Date(1,1,1));
				FillParameters.ApprovalDate     = Selection.ApprovalDate;
				FillParameters.ThereIsDateOfTransferOfOwnership = False;
				If Selection.NotShipInInstallments Then
					FillParameters.DateOfShipment = Selection.DateOfShipment;
					ThereIsDeposit = False;
				Else
					GoodsTable = Common.ObjectManagerByRef(DocumentPurchases).OrderAmounts(DocumentPurchases);
					FillParameters.TabularSection = GoodsTable;
					ThereIsDeposit = GoodsTable.Total("PackageDepositValue") <> 0;
				EndIf;
				FillParameters.Terms        = Selection.Terms;
				FillParameters.PackageDepositValue = ?(ThereIsDeposit,100,0);
				FillParameters.PayAmount       = 100;
				PaymentStepsServer.FillInPaymentStages(DefaultGraph, FillParameters);
			EndIf;
			
			AmountOfInterestPayment = 0;
			AmountOfTemplatePaymentInterest = 0;
			
			Selection.Reset();
			Cnt = 0;
			
			While Selection.Next() Do
				
				If ThereAreVariancesFromFinancialConditions Then
					Break;
				EndIf;
				
				If Not Selection.ThereAreErrorsFillingStagesOfPaymentSchedule Then// The agreement is not filled in in the document or the amount of the document is 0
					Break;
				EndIf;
				
				DefaultPlotLine = DefaultGraph[Cnt];
				
				If DefaultPlotLine.PaymentDate > Selection.PaymentDate Then // The payment date must be no less than in the payment schedule
					ThereAreVariancesFromFinancialConditions = True;
					Break;
				EndIf;
				
				AmountOfTemplatePaymentInterest = AmountOfTemplatePaymentInterest + DefaultPlotLine.PaymentPercentage;
				AmountOfInterestPayment = AmountOfInterestPayment + Selection.PaymentPercentage;
				
				If AmountOfInterestPayment > AmountOfTemplatePaymentInterest Then // The interest until the next payment according to the schedule should not exceed the interest according to the schedule of the agreement
					
					ThereAreVariancesFromFinancialConditions = True;
					Break;
				EndIf;
				
			EndDo;
			
		ElsIf ChecksArray[CurIndex__] = "CorrectIndicationOfVATRate" Then
			
			While Selection.Next() Do
				ThereAreVariancesFromPriceConditions = True;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Checks the correctness of filling in the return document in accordance 
// with the goods sold, taking into account adjustments.
// Is called from the procedure of the document "Obrabatyvaniya".
//
// Parameters:
// DocumentPurchases  - DocumentObject - The object for which you want to audit
// Cancel            - Boolean - Flag for refusing to carry out the document
// TableOfCheckedProducts - ValueTable - The items in the table are checked if it is passed.
//
Procedure CheckCorrectnessOfReturnedProducts(Val DocumentPurchases, Cancel, TableOfCheckedProducts = Undefined) Export
	
	If TableOfCheckedProducts = Undefined Then
		TableOfCheckedProducts = DocumentPurchases.Goods.Unload();
	EndIf;
	
	If TableOfCheckedProducts.Count() > 0 Then
		
		Query = New Query;
		If TypeOf(DocumentPurchases) = Type("DocumentObject.DiscrepancyReportFollowingShipment") Then
			RequestText = "
				|SELECT
				|	CAST(GoodsTable.Products AS Catalog.Products) AS Products,
				|	GoodsTable.Characteristic                                     AS Characteristic,
				|	CAST(GoodsTable.Purpose AS Catalog.Assignments)     AS Purpose,
				|	GoodsTable.Series                                              AS Series,
				|	GoodsTable.NumberOfPackages - 
				|		GoodsTable.NumberOfPackagesByDocument                  AS NumberOfPackages,
				|	GoodsTable.Count - GoodsTable.CountByDocument   AS Count,
				|	GoodsTable.DocumentInflow                                AS DocumentInflow
				|
				|INTO TTTableProducts
				|FROM
				|	&TableOfCheckedProducts AS GoodsTable
				|WHERE
				|	NOT GoodsTable.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
				|	AND NOT GoodsTable.DocumentInflow = UNDEFINED
				|	AND (GoodsTable.Count-GoodsTable.CountByDocument) > 0
				|	AND GoodsTable.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
				|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))
				|;";
		ElsIf TypeOf(DocumentPurchases) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
			RequestText = "
				|SELECT
				|	CAST(GoodsTable.Products AS Catalog.Products)                 AS Products,
				|	GoodsTable.Characteristic                                                     AS Characteristic,
				|	CAST(GoodsTable.Purpose AS Catalog.Assignments)                     AS Purpose,
				|	GoodsTable.Series                                                              AS Series,
				|	GoodsTable.NumberOfPackagesAccordingToAct -
				|		GoodsTable.NumberOfPackagesBase                                    AS NumberOfPackages,
				|	(GoodsTable.NumberOfPackagesAccordingToAct -
				|	GoodsTable.NumberOfPackagesBase) * GoodsTable.PackagingFactor   AS Count,
				|	GoodsTable.DocumentInflow                                                AS DocumentInflow
				|
				|INTO TTTableProducts
				|FROM
				|	&TableOfCheckedProducts AS GoodsTable
				|WHERE
				|	NOT GoodsTable.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
				|	AND NOT GoodsTable.DocumentInflow = UNDEFINED
				|	AND GoodsTable.NumberOfPackagesAccordingToAct-GoodsTable.NumberOfPackagesBase > 0
				|;";
		ElsIf TypeOf(DocumentPurchases) = Type("DocumentObject.ReturnOfGoodsToVendor") Then
			RequestText = "
				|SELECT 
				|	GoodsTable.Products                                   AS Products,
				|	GoodsTable.Characteristic                                 AS Characteristic,
				|	GoodsTable.Purpose                                     AS Purpose,
				|	GoodsTable.Series                                          AS Series,
				|	GoodsTable.BatchesIndicationStatus                            AS BatchesIndicationStatus,
				|	GoodsTable.NumberOfPackages                             AS NumberOfPackages,
				|	GoodsTable.Count                                     AS Count,
				|	GoodsTable.DocumentInflow                            AS DocumentInflow
				|INTO TTTableProductsSource
				|FROM &TableOfCheckedProducts AS GoodsTable
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	GoodsTable.Products                                   AS Products,
				|	GoodsTable.Characteristic                                 AS Characteristic,
				|	CAST(GoodsTable.Purpose AS Catalog.Assignments) AS Purpose,
				|	CASE
				|		WHEN ProductTypeData.BatchAccountingPolicy IS NULL
				|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
				|		ELSE CASE
				|				WHEN ProductTypeData.BatchAccountingPolicy.UseCostAccountingByBatches
				|					AND CAST(GoodsTable.DocumentInflow AS Document.VendorInvoice).BusinessOperation IN (&TransactionsGoodsInTransitAndNonInvoicing)
				|					THEN
				|						CASE
				|							WHEN ((ProductTypeData.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries
				|										AND NOT CAST(GoodsTable.DocumentInflow AS Document.VendorInvoice).BusinessOperation IN (&OperationsInTransit))
				|									OR (ProductTypeData.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor)
				|										AND CAST(GoodsTable.DocumentInflow AS Document.VendorInvoice).BusinessOperation IN (&OperationsInTransit))
				|								THEN GoodsTable.Series
				|								ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
				|						END
				|				WHEN GoodsTable.BatchesIndicationStatus = 14
				|					THEN GoodsTable.Series
				|				ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
				|			END
				|	END                                                        AS Series,
				|	GoodsTable.NumberOfPackages                             AS NumberOfPackages,
				|	GoodsTable.Count                                     AS Count,
				|	GoodsTable.DocumentInflow                            AS DocumentInflow
				|
				|INTO TTTableProducts
				|FROM
				|	TTTableProductsSource AS GoodsTable
				|
				|	INNER JOIN Catalog.Products AS ProductData_1
				|		ON GoodsTable.Products = ProductData_1.Ref
				|
				|	INNER JOIN Catalog.ItemKinds AS ProductTypeData
				|		ON ProductData_1.ProductKind = ProductTypeData.Ref
				|
				|WHERE
				|	NOT GoodsTable.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
				|	AND NOT GoodsTable.DocumentInflow = UNDEFINED
				|INDEX BY
				|	Products,
				|	Characteristic,
				|	Series
				|;";
		ElsIf TypeOf(DocumentPurchases) = Type("DocumentObject.GoodsShipmentFromStorage") Then
			RequestText = "
				|SELECT 
				|	GoodsTable.Products                                   AS Products,
				|	GoodsTable.Characteristic                                 AS Characteristic,
				|	GoodsTable.Purpose                                     AS Purpose,
				|	GoodsTable.Series                                          AS Series,
				|	GoodsTable.BatchesIndicationStatus                            AS BatchesIndicationStatus,
				|	GoodsTable.NumberOfPackages                             AS NumberOfPackages,
				|	GoodsTable.Count                                     AS Count,
				|	GoodsTable.DocumentInflow                            AS DocumentInflow
				|INTO TTTableProductsSource
				|FROM &TableOfCheckedProducts AS GoodsTable
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	GoodsTable.Products                                   AS Products,
				|	GoodsTable.Characteristic                                 AS Characteristic,
				|	CAST(GoodsTable.Purpose AS Catalog.Assignments) AS Purpose,
				|	CASE
				|		WHEN GoodsTable.BatchesIndicationStatus = 14
				|			THEN GoodsTable.Series
				|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
				|	END                                                        AS Series,
				|	GoodsTable.NumberOfPackages                             AS NumberOfPackages,
				|	GoodsTable.Count                                     AS Count,
				|	GoodsTable.DocumentInflow                            AS DocumentInflow
				|
				|INTO TTTableProducts
				|FROM
				|	TTTableProductsSource AS GoodsTable
				|WHERE
				|	NOT GoodsTable.DocumentInflow = VALUE(Document.GoodsReceiptForStorage.EmptyRef)
				|INDEX BY
				|	Products,
				|	Characteristic,
				|	Series
				|;";
		Else
			RequestText = "
				|SELECT
				|	GoodsTable.Products                                   AS Products,
				|	GoodsTable.Characteristic                                 AS Characteristic,
				|	CAST(GoodsTable.Purpose AS Catalog.Assignments) AS Purpose,
				|	CASE
				|		WHEN GoodsTable.BatchesIndicationStatus = 14
				|			THEN GoodsTable.Series
				|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
				|	END                                                        AS Series,
				|	GoodsTable.NumberOfPackages                             AS NumberOfPackages,
				|	GoodsTable.Count                                     AS Count,
				|	GoodsTable.DocumentInflow                            AS DocumentInflow
				|
				|INTO TTTableProducts
				|FROM
				|	&TableOfCheckedProducts AS GoodsTable
				|WHERE
				|	NOT GoodsTable.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
				|	AND NOT GoodsTable.DocumentInflow = UNDEFINED
				|INDEX BY
				|	Products,
				|	Characteristic,
				|	Series
				|;";
		EndIf;
		Query.Text = RequestText + "
		|SELECT
		|	CAST(GoodsTable.Products AS Catalog.Products)	AS Products,
		|	GoodsTable.Characteristic			AS Characteristic,
		|	GoodsTable.Purpose                AS Purpose,
		|	GoodsTable.Series						AS Series,
		|	GoodsTable.DocumentInflow		AS DocumentInflow,
		|	ISNULL(PurchasesOfGoodsAndServices.ToReturnReusablePackage, FALSE) AS ToReturnReusablePackage,
		|	SUM(GoodsTable.NumberOfPackages) AS NumberOfPackages,
		|	SUM(GoodsTable.Count) 		AS Count
		|INTO InspectedGoods
		|FROM
		|	TTTableProducts AS GoodsTable
		|	
		|	LEFT JOIN Document.VendorInvoice AS PurchasesOfGoodsAndServices
		|	ON PurchasesOfGoodsAndServices.Ref = GoodsTable.DocumentInflow
		|
		|GROUP BY
		|	Products,
		|	CHARACTERISTIC,
		|	GoodsTable.Purpose,
		|	Series,
		|	GoodsTable.DocumentInflow,
		|	ISNULL(PurchasesOfGoodsAndServices.ToReturnReusablePackage, FALSE)
		|	
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Series;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(PurchaseAdjustment.Date) AS Date,
		|	InspectedGoods.DocumentInflow AS ReceiptLink
		|INTO AdjustmentData
		|FROM
		|	InspectedGoods AS InspectedGoods
		|		LEFT JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
		|		ON (PurchaseAdjustment.DocumentBasis = InspectedGoods.DocumentInflow)
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
		|		ON PurchaseAdjustment.Ref = RegisterOfDocumentsStorno.ReversedDocument
		|			AND RegisterOfDocumentsStorno.Posted
		|			AND NOT RegisterOfDocumentsStorno.AdditionalRecord
		|WHERE
		|	PurchaseAdjustment.Posted
		|	AND RegisterOfDocumentsStorno.Ref IS NULL
		|
		|GROUP BY
		|	InspectedGoods.DocumentInflow
		|
		|INDEX BY
		|	ReceiptLink
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(PurchaseAdjustment.Ref) AS Ref,
		|	MAX(PurchaseAdjustment.Ref.Date) AS Date,
		|	PurchaseAdjustment.Ref.DocumentBasis AS ReceiptLink
		|INTO LastAdjustmentData
		|FROM
		|	Document.PurchaseAdjustment AS PurchaseAdjustment
		|WHERE
		|	(PurchaseAdjustment.Ref.DocumentBasis, PurchaseAdjustment.Ref.Date) IN
		|			(SELECT
		|				AdjustmentData.ReceiptLink AS ReceiptLink,
		|				AdjustmentData.Date AS Date
		|			FROM
		|				AdjustmentData)
		|	AND PurchaseAdjustment.Ref.Posted
		|
		|GROUP BY
		|	PurchaseAdjustment.Ref.DocumentBasis
		|
		|INDEX BY
		|	Ref,
		|	ReceiptLink
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CASE
		|		WHEN LastAdjustmentData.Ref IS NULL 
		|			THEN InspectedGoods.DocumentInflow
		|		ELSE LastAdjustmentData.Ref
		|	END AS Ref
		|INTO LinksToReceipts
		|FROM
		|	InspectedGoods AS InspectedGoods
		|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
		|		ON InspectedGoods.DocumentInflow = LastAdjustmentData.ReceiptLink
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AdjustmentOfAcquisitionOfGoods.Products AS Products,
		|	AdjustmentOfAcquisitionOfGoods.Characteristic AS Characteristic,
		|	AdjustmentOfAcquisitionOfGoods.Series AS Series,
		|	AdjustmentOfAcquisitionOfGoods.Purpose AS Purpose,
		|	SUM(AdjustmentOfAcquisitionOfGoods.NumberOfPackages) AS NumberOfPackages,
		|	SUM(AdjustmentOfAcquisitionOfGoods.Count) AS Count,
		|	AVG(AdjustmentOfAcquisitionOfGoods.Price) AS Price,
		|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis AS DocumentInflow
		|INTO ReceiptData
		|FROM
		|	Document.PurchaseAdjustment.Goods AS AdjustmentOfAcquisitionOfGoods
		|
		|WHERE
		|	AdjustmentOfAcquisitionOfGoods.Ref.Posted
		|	AND (Products,Characteristic,Purpose,Series) IN 
		|	(SELECT 
		|		InspectedGoods.Products AS Products,
		|		InspectedGoods.Characteristic AS Characteristic,
		|		InspectedGoods.Purpose AS Purpose,
		|		InspectedGoods.Series AS Series
		|	FROM
		|		InspectedGoods AS InspectedGoods	
		|	) AND  (Ref) IN 
		|	(SELECT 
		|		LinksToReceipts.Ref AS Ref
		|	FROM
		|		LinksToReceipts AS LinksToReceipts
		|	) 
		|
		|GROUP BY
		|	AdjustmentOfAcquisitionOfGoods.Products,
		|	AdjustmentOfAcquisitionOfGoods.Characteristic,
		|	AdjustmentOfAcquisitionOfGoods.Series,
		|	AdjustmentOfAcquisitionOfGoods.Purpose,		
		|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis
		|
		|UNION
		|
		|SELECT
		|	PurchaseOfGoodsServicesGoods.Products,
		|	PurchaseOfGoodsServicesGoods.Characteristic,
		|	PurchaseOfGoodsServicesGoods.Series,
		|	PurchaseOfGoodsServicesGoods.Purpose,
		|	SUM(PurchaseOfGoodsServicesGoods.NumberOfPackages),
		|	SUM(PurchaseOfGoodsServicesGoods.Count),
		|	AVG(PurchaseOfGoodsServicesGoods.Price),
		|	PurchaseOfGoodsServicesGoods.Ref
		|FROM
		|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
		|		ON PurchaseOfGoodsServicesGoods.Ref = RegisterOfDocumentsStorno.ReversedDocument
		|			AND RegisterOfDocumentsStorno.Posted
		|			AND NOT RegisterOfDocumentsStorno.AdditionalRecord
		|
		|WHERE
		|	PurchaseOfGoodsServicesGoods.Ref.Posted
		|	AND (Products,Characteristic,Purpose) IN 
		|	(SELECT 
		|		InspectedGoods.Products AS Products,
		|		InspectedGoods.Characteristic AS Characteristic,
		|		InspectedGoods.Purpose AS Purpose
		|	FROM
		|		InspectedGoods AS InspectedGoods
		|	) AND  (PurchaseOfGoodsServicesGoods.Ref) IN 
		|	(SELECT 
		|		LinksToReceipts.Ref AS Ref
		|	FROM
		|		LinksToReceipts AS LinksToReceipts
		|	) 
		|	AND RegisterOfDocumentsStorno.Ref IS NULL
		|
		|GROUP BY
		|	PurchaseOfGoodsServicesGoods.Products,
		|	PurchaseOfGoodsServicesGoods.Characteristic,
		|	PurchaseOfGoodsServicesGoods.Series,
		|	PurchaseOfGoodsServicesGoods.Purpose,
		|	PurchaseOfGoodsServicesGoods.Ref
		|
		|UNION
		|
		|SELECT
		|	GoodsReceiptForStorage.Products,
		|	GoodsReceiptForStorage.Characteristic,
		|	GoodsReceiptForStorage.Series,
		|	GoodsReceiptForStorage.Purpose,
		|	SUM(GoodsReceiptForStorage.NumberOfPackages),
		|	SUM(GoodsReceiptForStorage.Count),
		|	AVG(GoodsReceiptForStorage.Price),
		|	GoodsReceiptForStorage.Ref
		|FROM
		|	Document.GoodsReceiptForStorage.Goods AS GoodsReceiptForStorage
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
		|		ON GoodsReceiptForStorage.Ref = RegisterOfDocumentsStorno.ReversedDocument
		|			AND RegisterOfDocumentsStorno.Posted
		|			AND NOT RegisterOfDocumentsStorno.AdditionalRecord
		|
		|WHERE
		|	GoodsReceiptForStorage.Ref.Posted
		|	AND (Products,Characteristic,Purpose,Series) IN 
		|	(SELECT 
		|		InspectedGoods.Products AS Products,
		|		InspectedGoods.Characteristic AS Characteristic,
		|		InspectedGoods.Purpose AS Purpose,
		|		InspectedGoods.Series AS Series
		|	FROM
		|		InspectedGoods AS InspectedGoods
		|	) AND  (GoodsReceiptForStorage.Ref) IN 
		|	(SELECT 
		|		LinksToReceipts.Ref AS Ref
		|	FROM
		|		LinksToReceipts AS LinksToReceipts
		|	) 
		|	AND RegisterOfDocumentsStorno.Ref IS NULL
		|
		|GROUP BY
		|	GoodsReceiptForStorage.Products,
		|	GoodsReceiptForStorage.Characteristic,
		|	GoodsReceiptForStorage.Series,
		|	GoodsReceiptForStorage.Purpose,
		|	GoodsReceiptForStorage.Ref
		|
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	DocumentInflow
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfCheckedProducts.Products AS Products,
		|	TableOfCheckedProducts.Characteristic AS Characteristic,
		|	TableOfCheckedProducts.Series AS Series,
		|	TableOfCheckedProducts.Purpose AS Purpose,
		|	SUM(TableOfCheckedProducts.NumberOfPackages) AS NumberOfPackages,
		|	SUM(TableOfCheckedProducts.Count) AS Count,
		|	TableOfCheckedProducts.DocumentInflow AS DocumentInflow
		|
		|INTO ReturnDocumentData
		|FROM
		|	InspectedGoods AS InspectedGoods
		|
		|	LEFT JOIN
		|		Document.ReturnOfGoodsToVendor.Goods AS TableOfCheckedProducts
		|	ON
		|		(TableOfCheckedProducts.DocumentInflow = InspectedGoods.DocumentInflow)
		|		AND InspectedGoods.Products = TableOfCheckedProducts.Products
		|		AND InspectedGoods.Characteristic = TableOfCheckedProducts.Characteristic
		|		AND InspectedGoods.Series = TableOfCheckedProducts.Series
		|		AND InspectedGoods.Purpose = TableOfCheckedProducts.Purpose
		|	
		|	LEFT JOIN
		|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
		|	ON
		|		TableOfCheckedProducts.Ref = RegisterOfDocumentsStorno.ReversedDocument
		|			AND RegisterOfDocumentsStorno.Posted
		|			AND NOT RegisterOfDocumentsStorno.AdditionalRecord
		|WHERE
		|	TableOfCheckedProducts.Ref.Posted
		|	AND RegisterOfDocumentsStorno.Ref IS NULL
		|	AND TableOfCheckedProducts.Ref <> &ThisReturnLink
		|	AND TableOfCheckedProducts.Ref <> &ReversedDocument
		|
		|GROUP BY
		|	TableOfCheckedProducts.Products,
		|	TableOfCheckedProducts.Characteristic,
		|	TableOfCheckedProducts.Series,
		|	TableOfCheckedProducts.Purpose,
		|	TableOfCheckedProducts.DocumentInflow
		|
		|UNION ALL
		|
		|SELECT
		|	TableOfCheckedProducts.Products AS Products,
		|	TableOfCheckedProducts.Characteristic AS Characteristic,
		|	TableOfCheckedProducts.Series AS Series,
		|	TableOfCheckedProducts.Purpose AS Purpose,
		|	SUM(TableOfCheckedProducts.NumberOfPackages) AS NumberOfPackages,
		|	SUM(TableOfCheckedProducts.Count) AS Count,
		|	TableOfCheckedProducts.DocumentInflow AS DocumentInflow
		|
		|FROM
		|	InspectedGoods AS InspectedGoods
		|
		|	LEFT JOIN
		|		Document.GoodsShipmentFromStorage.Goods AS TableOfCheckedProducts
		|	ON
		|		(TableOfCheckedProducts.DocumentInflow = InspectedGoods.DocumentInflow)
		|		AND InspectedGoods.Products = TableOfCheckedProducts.Products
		|		AND InspectedGoods.Characteristic = TableOfCheckedProducts.Characteristic
		|		AND InspectedGoods.Series = TableOfCheckedProducts.Series
		|		AND InspectedGoods.Purpose = TableOfCheckedProducts.Purpose
		|	
		|	LEFT JOIN
		|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
		|	ON
		|		TableOfCheckedProducts.Ref = RegisterOfDocumentsStorno.ReversedDocument
		|			AND RegisterOfDocumentsStorno.Posted
		|			AND NOT RegisterOfDocumentsStorno.AdditionalRecord
		|WHERE
		|	TableOfCheckedProducts.Ref.Posted
		|	AND RegisterOfDocumentsStorno.Ref IS NULL
		|	AND TableOfCheckedProducts.Ref <> &ThisReturnLink
		|	AND TableOfCheckedProducts.Ref <> &ReversedDocument
		|
		|GROUP BY
		|	TableOfCheckedProducts.Products,
		|	TableOfCheckedProducts.Characteristic,
		|	TableOfCheckedProducts.Series,
		|	TableOfCheckedProducts.Purpose,
		|	TableOfCheckedProducts.DocumentInflow
		|
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Series,
		|	DocumentInflow
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InspectedGoods.Products AS Products,
		|	ISNULL(ReceiptData.Count, 0) - ISNULL(ReturnDocumentData.Count, 0) - ISNULL(InspectedGoods.Count, 0) AS Count,
		|	InspectedGoods.Characteristic AS Characteristic,
		|	InspectedGoods.Series AS Series,
		|	InspectedGoods.Purpose AS Purpose,
		|	InspectedGoods.DocumentInflow AS DocumentInflow,
		|	InspectedGoods.Products.UnitOfMeasure AS UnitOfMeasure,
		|	InspectedGoods.DocumentInflow.Number AS NumberOfReceipt
		|FROM
		|	ReceiptData AS ReceiptData
		|		LEFT JOIN ReturnDocumentData AS ReturnDocumentData
		|		ON ReceiptData.DocumentInflow = ReturnDocumentData.DocumentInflow
		|			AND ReceiptData.Products = ReturnDocumentData.Products
		|			AND ReceiptData.Characteristic = ReturnDocumentData.Characteristic
		|			AND ReceiptData.Series = ReturnDocumentData.Series
		|			AND ReceiptData.Purpose = ReturnDocumentData.Purpose
		|		FULL JOIN InspectedGoods AS InspectedGoods
		|		ON ReceiptData.DocumentInflow = InspectedGoods.DocumentInflow
		|			AND ReceiptData.Products = InspectedGoods.Products
		|			AND ReceiptData.Characteristic = InspectedGoods.Characteristic
		|			AND (ReceiptData.Series = InspectedGoods.Series
		|				OR ReceiptData.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|					AND InspectedGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef))
		|			AND ReceiptData.Purpose = InspectedGoods.Purpose
		|		
		|WHERE
		|	ISNULL(ReceiptData.Count, 0) - ISNULL(ReturnDocumentData.Count, 0) - ISNULL(InspectedGoods.Count, 0) < 0
		|	AND (InspectedGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|	OR (InspectedGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) 
		|		AND NOT InspectedGoods.ToReturnReusablePackage))
		|";
		
		TransactionsGoodsInTransitAndNonInvoicing = New Array();
		TransactionsGoodsInTransitAndNonInvoicing.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
		TransactionsGoodsInTransitAndNonInvoicing.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		TransactionsGoodsInTransitAndNonInvoicing.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		TransactionsGoodsInTransitAndNonInvoicing.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
		TransactionsGoodsInTransitAndNonInvoicing.Add(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
		TransactionsGoodsInTransitAndNonInvoicing.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
		
		OperationsInTransit = New Array();
		OperationsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
		OperationsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		OperationsInTransit.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		
		Query.SetParameter("TableOfCheckedProducts", TableOfCheckedProducts);
		Query.SetParameter("ThisReturnLink", DocumentPurchases.Ref);
		ReversedDocument = Undefined;
		If DocumentCorrection.ThisIsCorrectiveDocument(DocumentPurchases) Then
			ReversedDocument = DocumentPurchases.ReversedDocument;
		EndIf;
		Query.SetParameter("ReversedDocument", ReversedDocument);
		
		Query.SetParameter("TransactionsGoodsInTransitAndNonInvoicing", TransactionsGoodsInTransitAndNonInvoicing);
		Query.SetParameter("OperationsInTransit", OperationsInTransit);
		
		SetPrivilegedMode(True);
		Result = Query.Execute().Unload();
		If Result.Count() > 0 Then
			Cancel = True;
			ReportErrorsInCorrectnessOfReturnedProducts(Result);
		EndIf; 
	EndIf;

EndProcedure

// Generates the "Deviations from purchase conditions" report by executing a batch of requests. 
// 
// Parameters:
// 	DocumentPurchases  - DocumentObject -Document to be checked for
// 	ReportTable  - SpreadsheetDocument - Table document of the report.
//
Procedure GenerateReportDeviationsFromTermsOfPurchase(Val DocumentPurchases, ReportTable) Export
	
	SetPrivilegedMode(True);
	
	// Let's check whether it is necessary to check the range of acceptable prices
	KindOfMaximumAllowablePurchasePrice  = Constants.KindOfMaximumAllowablePurchasePrice.Get();
	CheckPriceRange                = ValueIsFilled(KindOfMaximumAllowablePurchasePrice);
	ThereAreErrorsAgreementIsNotSpecified       = False;
	UseManualDiscounts            = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	UsePartnersProducts = GetFunctionalOption("UsePartnersProducts");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	UsePriceManagementSystem25       = PriceManagementSystemServerCall.UsePriceManagementSystem25(DocumentPurchases.Date);
	
	ReturnOfMultiTurnContainers          = False;
	
	// Fill in the array of necessary checks depending on the type of document
	
	ChecksArray = New Array();
	TableName     = DocumentPurchases.Metadata().FullName();
	
	// Order to supplier
	If TableName = "Document.PurchaseOrder" Then
		
		AgreementIsSpecified = ValueIsFilled(DocumentPurchases.Terms);
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("TemporaryTableOfGoods_");
		
		ReturnOfMultiTurnContainers = DocumentPurchases.ToReturnReusablePackage;
		PackageDepositIsRequired = DocumentPurchases.PackageDepositIsRequired;
		
		ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
			
		If AgreementIsSpecified Then
			
			ChecksArray.Add("TemporaryTableWarehousesCorrectByAgreement");
			ChecksArray.Add("ComplianceOfHeaderWithPurchaseConditions");
			ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
			
		Else
			
			ThereAreErrorsAgreementIsNotSpecified = UseTermsOfPurchases;
			
		EndIf;
			
		If UseManualDiscounts And DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement Then
			ChecksArray.Add("ToleranceForManualMarkUpDiscounts");
		EndIf;
		
		If CheckPriceRange Then
			If UsePriceManagementSystem25 Then
				ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
			EndIf;
			ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
		EndIf;
		
		If DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement
			And DocumentPurchases.DocumentAmount <> 0
			And DocumentPurchases.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments Then
			
			ChecksArray.Add("TimeTableStagesOfPaymentSchedule");
			ChecksArray.Add("CorrectnessOfPaymentScheduleStages");
			
		EndIf;
		
	ElsIf TableName = "Document.PurchaseRequest" Then
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		ChecksArray.Add("TemporaryTableOfGoods_");
		
		ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
		
		ChecksArray.Add("TempTableWarehousesCorrectByAgreement");
		ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
		
		If CheckPriceRange Then
			If UsePriceManagementSystem25 Then
				ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
			EndIf;
			ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
		EndIf;
	
	// PURCHASE OF GOODS AND SERVICES
		
	ElsIf TableName = "Document.VendorInvoice" Then
		
		AgreementIsSpecified     = ValueIsFilled(DocumentPurchases.Terms);
		ThereAreErrorsAgreementIsNotSpecified = UseTermsOfPurchases
		                                And Not AgreementIsSpecified
		                                And Not DocumentPurchases.ReceiptUnderOrders;
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		
		If Not DocumentPurchases.ReceiptUnderOrders And AgreementIsSpecified Then
			ChecksArray.Add("TemporaryTableWarehousesCorrectByAgreement");
			ChecksArray.Add("ComplianceOfHeaderWithPurchaseConditions");
		EndIf;
		
		ChecksArray.Add("TemporaryTableOfGoods_");
		
		ReturnOfMultiTurnContainers = DocumentPurchases.ToReturnReusablePackage;
		PackageDepositIsRequired = DocumentPurchases.PackageDepositIsRequired;
		
		ChecksArray.Add("TemporaryTableCurrencyExchangeRates");
		
		If AgreementIsSpecified Then
			ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
		EndIf;
		
		If AgreementIsSpecified And UseManualDiscounts And DocumentPurchases.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement Then
			ChecksArray.Add("ToleranceForManualMarkUpDiscounts");
		EndIf;
			
		If CheckPriceRange Then
			If UsePriceManagementSystem25 Then
				ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
			EndIf;
			ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
		EndIf;
		
	// Acceptance of goods for storage
		
	ElsIf TableName = "Document.GoodsReceiptForStorage" Then
		
		AgreementIsSpecified     = ValueIsFilled(DocumentPurchases.Terms);
		ThereAreErrorsAgreementIsNotSpecified = UseTermsOfPurchases
		                                And Not AgreementIsSpecified
		                                And Not DocumentPurchases.ReceiptUnderOrders;
		
		ChecksArray.Add("TemporaryTableProcurementDocument");
		
		If Not DocumentPurchases.ReceiptUnderOrders And AgreementIsSpecified Then
			ChecksArray.Add("TemporaryTableWarehousesCorrectByAgreement");
			ChecksArray.Add("ComplianceOfHeaderWithPurchaseConditions");
		EndIf;
		
		ChecksArray.Add("TemporaryTableOfGoods_");
		
		ReturnOfMultiTurnContainers = DocumentPurchases.ToReturnReusablePackage;
		PackageDepositIsRequired = False;
		
		If AgreementIsSpecified Then
			ChecksArray.Add("GoodsComplianceWithPurchasingConditions");
		EndIf;
		
		If CheckPriceRange Then
			If UsePriceManagementSystem25 Then
				ChecksArray.Add("EnteringPricesIntoAcceptableRangePreprocessing");
			EndIf;
			ChecksArray.Add("EntryOfPricesIntoAcceptableRange");
		EndIf;
		
	EndIf;
	
	// Let's form the text of the request for the necessary checks in accordance with the array of checks
	
	QueryText     = "";
	QueryOptions = New Structure();

	QueryOptions.Insert("Date",                      DocumentPurchases.Date);
	QueryOptions.Insert("Ref",                    DocumentPurchases.Ref);
	QueryOptions.Insert("ReturnOfMultiTurnContainers", ReturnOfMultiTurnContainers);
	QueryOptions.Insert("PackageDepositIsRequired",      PackageDepositIsRequired);
	QueryOptions.Insert("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentPurchases.Organization));
	QueryOptions.Insert("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(DocumentPurchases.Organization));
		
	For Each CurItem In ChecksArray Do
		
		If CurItem = "TemporaryTableProcurementDocument" Then
			
			CreateRequestTemporaryTablePurchaseDocumentHeader(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "TemporaryTableOfGoods_" Then
			
			GenerateTemporaryTableProductsQueryInPurchaseDocument(QueryText, QueryOptions, DocumentPurchases, TableName);
			
		ElsIf CurItem = "TemporaryTableWarehousesCorrectByAgreement" Then
			
			GenerateRequestTemporaryTableWarehousesCorrectByAgreement(QueryText);
			
		ElsIf CurItem = "TempTableWarehousesCorrectByAgreement" Then
			
			CreateQueryTempTableWarehousesCorrectByAgreement(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "ComplianceOfHeaderWithPurchaseConditions" Then
			
			GenerateRequestPurchaseDocumentHeader(QueryText, TableName);
			
		ElsIf CurItem = "TimeTableStagesOfPaymentSchedule" Then
			
			CreateRequestTemporaryTablePaymentStages(QueryText, QueryOptions, DocumentPurchases);
			
		ElsIf CurItem = "TemporaryTableCurrencyExchangeRates" Then
			
			GenerateQueryTemporaryTableCurrencyExchangeRates(QueryText);
			
		ElsIf CurItem = "GoodsComplianceWithPurchasingConditions" Then
			
			GenerateRequestProductsOfPurchaseDocument(QueryText, TableName);
			
		ElsIf CurItem = "EntryOfPricesIntoAcceptableRange" Then
			
			If UsePriceManagementSystem25 Then
				GenerateRequestForPricesInAcceptableRange2_5(QueryText);
			Else
				GenerateRequestForPricesInAcceptableRange(QueryText);
			EndIf;
			
		ElsIf CurItem = "ToleranceForManualMarkUpDiscounts" Then
			
			GenerateRequestWhetherManualDiscountsAndSurchargesAreAcceptable(QueryText);
			
		ElsIf CurItem = "CorrectnessOfPaymentScheduleStages" Then
			
			GenerateRequestForCorrectnessOfPaymentScheduleStages(QueryText);
			
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(QueryText) Then
		SetPrivilegedMode(False);
		Return;
	EndIf;

	Query = New Query(QueryText);
	
	For Each QueryParameter In QueryOptions Do
		Query.SetParameter(QueryParameter.Key,QueryParameter.Value);
	EndDo;
	
	ResultsArray = Query.ExecuteBatch(); 
	
	ArrayOfHeaderDeviations         = New Array;
	DeviationTreeGoods        = Reports.VariancesFromPurchaseConditions.InitializeRejectionTree();
	DeviationTreePaymentStages   = Reports.VariancesFromPurchaseConditions.InitializeRejectionTree();
	
	For CurIndex__ = 0 To ResultsArray.Count()-1 Do
		
		Selection = ResultsArray[CurIndex__].Select();
		
		If ChecksArray[CurIndex__] = "ComplianceOfHeaderWithPurchaseConditions" Then
			
			ReportErrorsPurchaseDocumentHeader(Selection, DocumentPurchases, False, ArrayOfHeaderDeviations);
			
		ElsIf ChecksArray[CurIndex__] = "GoodsComplianceWithPurchasingConditions" Then
			
			ReportErrorsInPurchaseDocument(Selection, DocumentPurchases, False, DeviationTreeGoods);
			
		ElsIf ChecksArray[CurIndex__] = "EntryOfPricesIntoAcceptableRange" Then
			
			ReportErrorsWhenPricesFallWithinAcceptableRange(Selection, DocumentPurchases, False, UseManualDiscounts, DeviationTreeGoods);
			
		ElsIf ChecksArray[CurIndex__] = "ToleranceForManualMarkUpDiscounts" Then
			
			ReportErrorsAcceptanceOfManualDiscountsMargins(Selection, DocumentPurchases, False, DeviationTreeGoods);
			
		ElsIf ChecksArray[CurIndex__] = "CorrectnessOfPaymentScheduleStages" Then
			
			ReportErrorsCorrectnessOfPaymentScheduleStages(Selection, DocumentPurchases, False, DeviationTreePaymentStages, ArrayOfHeaderDeviations);
			
		EndIf;
		
	EndDo;
	
	ThereAreVariances = ArrayOfHeaderDeviations.Count() > 0 
		Or DeviationTreeGoods.Rows.Count() > 0 
		Or DeviationTreePaymentStages.Rows.Count() > 0;
	
	Reports.VariancesFromPurchaseConditions.OutputReportHeader(ReportTable, ThereAreVariances, ThereAreErrorsAgreementIsNotSpecified);
	
	If ArrayOfHeaderDeviations.Count() > 0 Then
		Reports.VariancesFromPurchaseConditions.DisplayDeviationsInHeaderArea(ArrayOfHeaderDeviations, ReportTable);
	EndIf;
	
	If DeviationTreeGoods.Rows.Count() > 0 Then
		Reports.VariancesFromPurchaseConditions.OutputAllItemsInPurchaseDocument(DocumentPurchases, DeviationTreeGoods, ReportTable);
	EndIf;
	
	If DeviationTreePaymentStages.Rows.Count() > 0 Then
		Reports.VariancesFromPurchaseConditions.DisplayAllStagesOfPaymentForPurchaseDocument(DocumentPurchases, DeviationTreePaymentStages, ReportTable);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Displays messages that there are adjustments based on the document.
//
// Parameters:
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCancellationsAndAdjustments(Val DocumentPurchases, Cancel) Export

	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã nhập điều chỉnh mua hàng dựa trên chứng từ %1. Không thể hủy bỏ kết chuyển.';
			|ru = 'На основании документа %1 введена корректировка приобретения. Отмена проведения невозможна.';
			|en = 'Purchase adjustment is registered for document %1. Cannot cancel posting.'; fa = 'Purchase adjustment is registered for document %1. Cannot cancel posting.';
			|it = 'In base al documento %1 è stata inserita la rettifica dell''acquisto. Impossibile annullare la registrazione.';
			|pl = 'Na podstawie dokumentu %1 wprowadzono korekcje nabycia. Nie można anulować zaksięgowania  ';
			|tr = '%1 belgesine dayalı olarak bir satın alma düzeltmesi girildi. Kayıt iptali mümkün değildir.'"),
		DocumentPurchases);
	
	Common.MessageToUser(
			ErrorText,
			DocumentPurchases,
			,
			,
			Cancel);
	
EndProcedure

// Displays messages that the basis of the document has not been carried out.
//
// Parameters:
// 	DocumentPurchases - DocumentRef - The document is the basis of the correction.
// 	Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsOnUnverifiedBasis(Val DocumentPurchases, Cancel) Export

	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chưa kết chuyển chứng từ-cơ sở %1. Không thể tiến hành điều chỉnh.';
			|ru = 'Документ-основание %1 не проведен. Проведение корректировки невозможно.';
			|en = 'The %1 base document is not posted. Adjustment is unavailable.'; fa = 'The %1 base document is not posted. Adjustment is unavailable.';
			|it = 'Документ-основание %1 не проведен. Проведение корректировки невозможно.';
			|pl = 'The %1 base document is not posted. Adjustment is unavailable.';
			|tr = 'Temel belge %1 gerçekleştirilmedi. Düzeltme yapmak mümkün değildir.'"),
		DocumentPurchases);
	
	Common.MessageToUser(
		ErrorText,
		DocumentPurchases,
		,
		,
		Cancel);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithDiscountsInProcurementDocuments

 // Fills in the price conditions and prices in PM Goods by type of price on the selected lines.
//
// Parameters:
// 		Object - DocumentObject - the object for which you want to cancel a manual discount
// 		TabularSectionName  - String - name of the table part of the object where you want to cancel manual discounts
// 		ClearSettlementAmounts - Boolean - True if the table part contains the settlement amount.
//
Procedure CancelManualDiscounts(Object, TabularSectionName, ClearSettlementAmounts = False) Export
	
	DiscountsChanged = False;
	
	For Each TSRow In Object[TabularSectionName] Do
		
		If TSRow.ManualDiscount <> 0 Or TSRow.PercentRateOfManualDiscount <> 0 Then
			
			TSRow.ManualDiscount = 0;
			TSRow.PercentRateOfManualDiscount = 0;
			PriceManagementSystem.RecalculateAmountsInRow(TSRow, False, False, True, Object.PriceIncludesVAT);
			DiscountsChanged = True;
			If ClearSettlementAmounts Then
				TSRow.AmountARAP = 0;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If DiscountsChanged Then
		Object.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Object[TabularSectionName], Object.PriceIncludesVAT);
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfWorkingWithSupplierProductsInProcurementDocuments

// Puts the product table in temporary storage
// 
// Parameters:
//  Goods - FormDataCollection - a table of products to be placed in temporary storage.
//
// Returns:
//  String - The address of the product table in the temporary storage.
//
Function PlaceGoodsInTemporaryStorage(Goods) Export
	
	RowsArray = New Array();
	
	For Each CurRow In Goods Do
		If ValueIsFilled(CurRow.PartnerProducts) And Not ValueIsFilled(CurRow.Products) Then
			RowsArray.Add(CurRow);
		EndIf;
	EndDo;
	
	If RowsArray.Count() = 0 Then
		AddressOfTheGoodsInTheTemporaryStorage = Undefined;
	Else
		PartnerProducts = Goods.Unload(RowsArray, "LineNumber,PartnerProducts");
		AddressOfTheGoodsInTheTemporaryStorage = PutToTempStorage(PartnerProducts);
	EndIf;
	
	Return AddressOfTheGoodsInTheTemporaryStorage;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForObtainingDefaultPropsValues

// Returns the structure for the responsible person of the specified warehouse
// If the warehouse is a group, returns the values
// 		used in the last document of the specified Manager with the specified warehouse.
//
// Parameters:
// 		Warehouse - CatalogRef.Warehouses - warehouse.
// 		Manager - CatalogRef.Users - manager.
//
// Returns:
// 		Structure - structure with fields:
// 		* EmployeeResponsible - CatalogRef.Persons - 
// 		* ResponsiblePosition - String - 
// 		Undefined - if fill-in data is not found 
//
Function GetWarehouseManager(Warehouse, Manager) Export
	
	If Not ValueIsFilled(Warehouse) Then
		Return Undefined;
	EndIf;
	
	If Not Catalogs.Warehouses.IsFolder(Warehouse) Then
		StructureOfResponsible = SettingsValueCached.GetWarehouseManager(Warehouse);
		If StructureOfResponsible <> Undefined Then
			Return StructureOfResponsible;
		EndIf;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	LastResponsible.EmployeeResponsible AS EmployeeResponsible,
	|	LastResponsible.ResponsiblePosition AS ResponsiblePosition,
	|	LastResponsible.PointInTime AS PointInTime
	|FROM
	|	(SELECT TOP 1
	|		VendorInvoice.ReceivedBy AS EmployeeResponsible,
	|		VendorInvoice.AcceptedPosition AS ResponsiblePosition,
	|		VendorInvoice.PointInTime AS PointInTime
	|	FROM
	|		Document.VendorInvoice AS VendorInvoice
	|	WHERE
	|		VendorInvoice.Warehouse = &Warehouse
	|		AND VendorInvoice.Manager = &Manager
	|		AND VendorInvoice.Posted = TRUE
	|	ORDER BY
	|		PointInTime DESC) AS LastResponsible
	|
	|UNION ALL
	|
	|SELECT
	|	LastResponsible.EmployeeResponsible AS EmployeeResponsible,
	|	LastResponsible.ResponsiblePosition AS ResponsiblePosition,
	|	LastResponsible.PointInTime AS PointInTime
	|FROM
	|	(SELECT TOP 1
	|		GoodsReceiptForStorage.ReceivedBy AS EmployeeResponsible,
	|		GoodsReceiptForStorage.AcceptedPosition AS ResponsiblePosition,
	|		GoodsReceiptForStorage.PointInTime
	|	FROM
	|		Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|	WHERE
	|		GoodsReceiptForStorage.Warehouse = &Warehouse
	|		AND GoodsReceiptForStorage.Manager = &Manager
	|		AND GoodsReceiptForStorage.Posted = TRUE
	|	ORDER BY
	|		PointInTime DESC) AS LastResponsible
	|
	|ORDER BY
	|	PointInTime DESC");
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Manager", Manager);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		If ValueIsFilled(Selection.EmployeeResponsible) Or ValueIsFilled(Selection.ResponsiblePosition) Then
			Return New Structure("EmployeeResponsible, ResponsiblePosition", Selection.EmployeeResponsible, Selection.ResponsiblePosition);
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Searches for a valid contract with a counterparty using the specified details.
// If one valid contract is found, it returns a link to it, otherwise it returns an empty link.
//
// Parameters:
//  Object - DocumentRef, DocumentObject, Structure - a document or an arbitrary structure for which you need to get
//  a Contract.
//		The properties must be defined in the object:
// 		* Partner 		- CatalogRef.Partners 				- the partner with whom the contract is concluded.
//		* Contract 		- CatalogRef.CounterpartyContracts 	- the contract that is currently set for the item. It may be empty.
//  	* Counterparty 	- CatalogRef.Counterparties 				- the counterparty with whom the contract is concluded.
//  	* Organization 	- CatalogRef.Companies 				- the organization of the enterprise on whose behalf the contract was concluded.
//  BusinessTransactions - EnumRef.BusinessTransactions, Array - one or more business operations
//  (contract type). 
//  AdditionalContractSelectionParameters - Structure - additional parameters for selecting Contracts
//  (See AdditionalContractSelectionParameters).
//
// Returns:
//  CatalogRef.CounterpartyContracts - the default agreement.
//
Function GetDefaultContract(
	Object,
	BusinessTransactions,
	AdditionalContractSelectionParameters = Undefined) Export
	
	If AdditionalContractSelectionParameters = Undefined Then
		AdditionalContractSelectionParameters = AdditionalContractSelectionParameters();
	EndIf;
	
	ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
	ParametersForFillingOutContract.Organization = Object.Organization;
	ParametersForFillingOutContract.BusinessOperation = BusinessTransactions;
	ParametersForFillingOutContract.ARAPCurrency = AdditionalContractSelectionParameters.ARAPCurrency;
	ParametersForFillingOutContract.LineOfBusiness = AdditionalContractSelectionParameters.LineOfBusiness;
	ParametersForFillingOutContract.ConsignmentSales25 = AdditionalContractSelectionParameters.ConsignmentSales25;
	ParametersForFillingOutContract.ARAPObjectSettings = AdditionalContractSelectionParameters.ARAPObjectSettings;
	ParametersForFillingOutContract.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage = AdditionalContractSelectionParameters.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage;
	ParametersForFillingOutContract.Taxation = AdditionalContractSelectionParameters.Taxation;
	ParametersForFillingOutContract.ContractWithSelfEmployedPerson = AdditionalContractSelectionParameters.ContractWithSelfEmployedPerson;
	
	RowData = New Structure;
	RowData.Insert("Partner");
	RowData.Insert("Counterparty");
	RowData.Insert("Contract");
	FillPropertyValues(RowData, Object);
	
	Actions = New Structure;
	Actions.Insert("FillInDefaultContract", ParametersForFillingOutContract);
	
	BatchProcessingOfTablePartServer.ProcessTSString(
		RowData,
		Actions,
		BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues());
	
	Return RowData.Contract;
	
EndFunction

// Sets the visibility of the contract details depending on the agreement data
//
// Parameters:
// 		Object - Structure, DocumentRef - 
// 		ElementAvailability - Boolean - 
// 		ItemVisibility - Boolean - 
// 		Contract - CatalogRef.CounterpartyContracts - 
//
Procedure SetContractAvailability(Object, ElementAvailability, ItemVisibility, Contract = Undefined) Export
	
	SetPrivilegedMode(True);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	ContractsAreUsed     = GetFunctionalOption("UseContractsWithVendors");
	
	InfluenceFieldsFilledIn = 
		ValueIsFilled(Object.Partner)
		And (ValueIsFilled(Object.Counterparty) Or UsePartnersAsCounterparties)
		And ValueIsFilled(Object.Organization);
		
	If TMCommonUseClientServer.HasObjectAttribute(Object, "Terms")
		And GetFunctionalOption("UseTermsOfPurchases") Then
		
		If ValueIsFilled(Object.Terms) Then
			SetPrivilegedMode(True);
			ContractsAreUsed =
				ContractsAreUsed
				And Common.ObjectAttributeValue(Object.Terms, "ContractsAreUsed");
			SetPrivilegedMode(False);	
		EndIf;
		
	EndIf;
	
	ElementAvailability = InfluenceFieldsFilledIn And ContractsAreUsed;
	
	ItemVisibility = ContractsAreUsed;
	
	If Not ElementAvailability And ValueIsFilled(Object.Contract) Then
		Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
EndProcedure

// Returns the data of the invoice in the form of the structure
//
// Parameters:
//  DocumentBasis - DocumentRef - The document on the basis of which the invoice is entered.
//  Organization - CatalogRef.Companies - The organization in whose name the invoice is issued.
//  Counterparty - CatalogRef.Counterparties - 
//  Number - String - Invoice number.
//  DateCreated - Date - The date of the invoice.
//  Currency - CatalogRef.Currencies - The currency of the invoice.
//  DateReceived - Date - Date of receipt of the invoice.
//
// Returns:
//  Structure - invoice fields.
//
Function InvoiceDataByStructure(DocumentBasis, Organization, Counterparty, Number, DateCreated, Currency, DateReceived) Export
	
	InvoiceData_3 = New Structure;
	
	InvoiceData_3.Insert("DocumentBasis", DocumentBasis);
	InvoiceData_3.Insert("Organization",       Organization);
	InvoiceData_3.Insert("Counterparty",        Counterparty);
	InvoiceData_3.Insert("Number",             Number);
	InvoiceData_3.Insert("DateCreated",   DateCreated);
	InvoiceData_3.Insert("Currency",            Currency);
	InvoiceData_3.Insert("Date",              DateReceived);
	
	Return InvoiceData_3;
	
EndFunction

// Sets the mode for selecting groups and items for the warehouse on the form
//
// Parameters:
//  Warehouse - FormField - changes the selection mode for warehouses in this group.
//
Procedure SetModeForSelectingGroupsOfWarehouseItems(Warehouse) Export
	
	If GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
		Warehouse.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	Else
		Warehouse.ChoiceFoldersAndItems = FoldersAndItems.Items;
	EndIf;
	
EndProcedure

// Checks for adjustments and invoices entered based on the document being modified.
//
// Parameters:
// Ref - DocumentRef - Document to change
// Basis - DocumentRef - The basis for the adjustments
// ThereAreAdjustingEntries - Boolean - Return parameter. Indicates whether the document being modified has any adjustments.
// ThereAreInvoices_1 - Boolean - Return parameter. Indicates whether there are invoices for the document being modified.
//
Procedure CheckForAdjustmentsAndInvoices(Ref, Basis, ThereAreAdjustingEntries, ThereAreInvoices_1) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT TOP 1
	|	DocumentData.Ref AS Adjusting,
	|	DocumentData.PointInTime AS PointInTime
	|FROM
	|	Document.PurchaseAdjustment AS DocumentData
	|WHERE
	|	DocumentData.DocumentBasis = &Basis
	|	AND (DocumentData.Posted
	|	OR DocumentData.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentData.Ref AS Adjusting,
	|	DocumentData.Ref.PointInTime AS PointInTime
	|FROM
	|	Document.PurchaseAdjustment.ARAPAdjustment AS DocumentData
	|WHERE
	|	DocumentData.DocumentAcquisitions = &Basis
	|	AND DocumentData.Ref.Posted
	|
	|ORDER BY
	|	PointInTime DESC
	|");
	Query.SetParameter("Basis", Basis);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	If TypeOf(Ref) = Type("DocumentRef.PurchaseAdjustment") Then
		Selection = QueryResult.Select();
		Selection.Next();
		ThereAreAdjustingEntries = ValueIsFilled(Selection.Adjusting) And Selection.Adjusting <> Ref;
	Else
		ThereAreAdjustingEntries = Not QueryResult.IsEmpty();
	EndIf;	
	
	If Not ThereAreAdjustingEntries Then
		Invoices_ = VATAccountingERP.InvoicesReceivedOnLegalGrounds(Ref, True);
		ThereAreInvoices_1 = Invoices_.Count() > 0;
	Else
		ThereAreInvoices_1 = False;
	EndIf;
	
EndProcedure

// Returns the type of the last correction for the document.
//
// Parameters:
// Ref - DocumentRef - Document to change
// Basis - DocumentRef - The basis for the adjustments
//
// Returns:
//		EnumRef.AdjustingEntryTypes - the type of adjustment, if any.
//
Function GetTypeOfLastAdjustment(Ref, Basis) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT TOP 1
	|	DocumentData.Ref AS Adjusting,
	|	DocumentData.PointInTime AS PointInTime,
	|	DocumentData.Ref.AdjustingEntryType AS AdjustingEntryType
	|FROM
	|	Document.PurchaseAdjustment AS DocumentData
	|WHERE
	|	DocumentData.DocumentBasis = &Basis
	|	AND (DocumentData.Posted
	|	OR DocumentData.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentData.Ref AS Adjusting,
	|	DocumentData.Ref.PointInTime AS PointInTime,
	|	DocumentData.Ref.AdjustingEntryType AS AdjustingEntryType
	|FROM
	|	Document.PurchaseAdjustment.ARAPAdjustment AS DocumentData
	|WHERE
	|	DocumentData.DocumentAcquisitions = &Basis
	|	AND DocumentData.Ref.Posted
	|
	|ORDER BY
	|	PointInTime DESC
	|");
	Query.SetParameter("Basis", Basis);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	If TypeOf(Ref) = Type("DocumentRef.PurchaseAdjustment") Then
		Selection = QueryResult.Select();
		Selection.Next();
		ThereAreAdjustingEntries = ValueIsFilled(Selection.Adjusting) And Selection.Adjusting <> Ref;
		AdjustingEntryType = ?(ThereAreAdjustingEntries, Selection.AdjustingEntryType, Enums.AdjustingEntryTypes.EmptyRef());
	Else
		ThereAreAdjustingEntries = Not QueryResult.IsEmpty();
		Selection = QueryResult.Select();
		AdjustingEntryType =  ?(Selection.Next(), Selection.AdjustingEntryType, Enums.AdjustingEntryTypes.EmptyRef());
	EndIf;
	
	Return AdjustingEntryType;
	
EndFunction

// Updates information about the number of receipt documents in the table part of the refund document.
//
// Parameters:
//		ReceiptsList - ValueList - list of receipt documents
//		ReceiptInHeader - DocumentRef -  Link to the receipt document in the document header
//		CaptionTitle - String - Label containing information about the number of documents received
//		FormItems - FormItems - Elements of the return document form
//		ColumnInTablePart - TableBoxColumn - containing the receipt documents
//		TabularSection - TabularSection - return document
//		ReceiptNameInTablePart - String - Name of the column with receipt documents in the table part.
//		
Procedure UpdateInformationOnReceiptsInForm(ReceiptsList,
	                                             ReceiptInHeader,
	                                             CaptionTitle,
	                                             FormItems,
	                                             ColumnInTablePart,
	                                             Val TabularSection,
	                                             Val ReceiptNameInTablePart) Export
	
	ReceiptsList.Clear();
	For Each CurRow In TabularSection Do
		If ValueIsFilled(CurRow[ReceiptNameInTablePart]) And ReceiptsList.FindByValue(CurRow[ReceiptNameInTablePart]) = Undefined Then
			ReceiptsList.Add(CurRow[ReceiptNameInTablePart]);
		EndIf;
	EndDo;
	
	If ReceiptsList.Count() = 1 Then
		ReceiptInHeader = ReceiptsList[0].Value;
	Else
		ReceiptInHeader = Undefined;
	EndIf;
	
	If ReceiptsList.Count() > 1 Then
		CaptionTitle = StrReplace(
			NStr("vi = 'Tất cả chứng từ: %NumberOfReceipts_%';
				|ru = 'Всего документов: %NumberOfReceipts_%';
				|en = 'Total documents: %NumberOfReceipts_%'; fa = 'Total documents: %NumberOfReceipts_%';
				|it = 'Totale documenti: %NumberOfReceipts_%';
				|pl = 'Razem dokumentów: %NumberOfReceipts_%';
				|tr = 'Toplam belgeler: %NumberOfReceipts_%'"), "%NumberOfReceipts_%",
			ReceiptsList.Count());
	EndIf;
	
	If ReceiptsList.Count() < 1 Then
		ReceiptInHeader = Undefined;
	EndIf;
	
	If ReceiptsList.Count() <= 1 Then
		FormItems.PagesReceipts.CurrentPage = FormItems.PageReceipt;
	Else
		FormItems.PagesReceipts.CurrentPage = FormItems.PageReceipts;
	EndIf;
	
EndProcedure

// Defines the business operation of the return for the business operation of the receipt
//
// Parameters:
//	BusinessOperationReceipt - EnumRef.BusinessTransactions - initial business transaction.
//
// Returns:
//	EnumRef.BusinessTransactions - business operation of the refund.
//
Function GetRefundTransactionOnReceipt(Val BusinessOperationReceipt) Export
	
	If BusinessOperationReceipt = Enums.BusinessTransactions.PurchaseFromSupplier
		Or BusinessOperationReceipt = Enums.BusinessTransactions.PurchaseByImport
		Or BusinessOperationReceipt = Enums.BusinessTransactions.ImportFromEAEU
		Or Not ValueIsFilled(BusinessOperationReceipt) Then
		Return Enums.BusinessTransactions.ReturnOfGoodsToVendor;
	ElsIf BusinessOperationReceipt = Enums.BusinessTransactions.ConsignmentProcurement Then
		Return Enums.BusinessTransactions.ReturnOfGoodsToConsignor;
	ElsIf BusinessOperationReceipt = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		Return Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale;
	ElsIf BusinessOperationReceipt = Enums.BusinessTransactions.DeliveryForPrincipal Then
		Return BusinessOperationReceipt = Enums.BusinessTransactions.DeliveryForPrincipal;
	ElsIf BusinessOperationReceipt = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		Return Enums.BusinessTransactions.ReturnToMaterialProvider2_5;
	EndIf;
	
EndFunction

// Returns the structure of parameters to pass to the function fill in the item in the tactical Receipt().
//
// Returns:
//   Structure - structure with the fields required for filling in the actual acceptance:
//   * DocumentInflow - DocumentRef - Link to the receipt document
//   * DateOfReceipt - Date - Date of receipt of goods
//   * StructureOfActionsWithModifiedStrings - Structure - Action to be applied to the modified lines
//   * StructureOfActionsWithAddedStrings - Structure - Actions to perform on the added rows
//   * Terms - CatalogRef.TermsOfPurchaseFromVendors - receipt agreement
//   * Contract - CatalogRef.CounterpartyContracts - The contract counterparties
//   * Warehouse - CatalogRef.Warehouses, Array of CatalogRef.Warehouses - The warehouse receipt
//   * CurrentDocument - DocumentRef - Link to the current document
//   * ReferenceArray - Array - Orders for admission
//   * FillingInDiscrepancyReport - Boolean - Indicates that the "Report of discrepancies after acceptance" is being filled in"
//   * FillInByReceipts - Boolean - 
//   * GoodsReceiptOption - EnumRef.GoodsReceiptOptions - 
//
Function FillingParametersForActualAcceptance() Export
	
	FillParameters = New Structure("DocumentInflow,
	                                      |DateOfReceipt,
	                                      |StructureOfActionsWithModifiedStrings,
                                          |StructureOfActionsWithAddedStrings");
	FillParameters.Insert("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	FillParameters.Insert("Contract",    Catalogs.CounterpartyContracts.EmptyRef());
	FillParameters.Insert("Warehouse",                        Undefined);
	FillParameters.Insert("CurrentDocument",              Undefined);
	FillParameters.Insert("ReferenceArray",           Undefined);
	FillParameters.Insert("FillingInDiscrepancyReport", False);
	FillParameters.Insert("FillInByReceipts",      False);
	FillParameters.Insert("GoodsReceiptOption",        Enums.GoodsReceiptOptions.EmptyRef());
	Return FillParameters;
	
EndFunction

// Fills in the quantity in PM of Products for the products actually accepted.
//
// Parameters:
//	Goods                                 - ValueTable - item table of the document,
//	FillParameters                    - See FillingParametersForActualAcceptance
//	ThereAreAcceptedGoods                     - Boolean - flag that can be used to determine that the goods have been shipped,
//  AdditionalSearchParameters_          - Structure - ability to set additional search fields.
//
// Returns:
//	Boolean - A flag by which it can be determined that the PM of the document has changed as a result of re-filling.
//
Function FillInGoodsOnActualAcceptance(Goods, FillParameters, ThereAreAcceptedGoods, AdditionalSearchParameters_ = Undefined) Export
	
	CurrentDocument                        = FillParameters.CurrentDocument;
	DocumentInflow                    = FillParameters.DocumentInflow;
	DateOfReceipt                        = FillParameters.DateOfReceipt;
	StructureOfActionsWithModifiedStrings  = FillParameters.StructureOfActionsWithModifiedStrings;
	StructureOfActionsWithAddedStrings = FillParameters.StructureOfActionsWithAddedStrings;
	Warehouse                                  = FillParameters.Warehouse;
	Terms                             = FillParameters.Terms;
	Contract                                = FillParameters.Contract;
	ReferenceArray                     = FillParameters.ReferenceArray;
	FillingInDiscrepancyReport           = FillParameters.FillingInDiscrepancyReport;
	FillInByReceipts                = FillParameters.FillInByReceipts;
	
	GoodsReceiptOption = Undefined;
	
	If FillParameters.Property("GoodsReceiptOption")
		And ValueIsFilled(FillParameters.GoodsReceiptOption) Then
		
		GoodsReceiptOption = FillParameters.GoodsReceiptOption;
		
	Else
		GoodsReceiptOption = Common.ObjectAttributeValue(DocumentInflow, "GoodsReceiptOption");
	EndIf;
	
	SetPrivilegedMode(True);
	
	HasChanges = False;
	ThereAreAcceptedGoods = False;
	
	TypeOfReceipt = TypeOf(DocumentInflow);
	PossibleDamage = GetFunctionalOption("UseGoodsQuality")
					And TypeOfReceipt = Type("DocumentRef.ReturnOfGoodsFromCustomer");
	
	If ReferenceArray <> Undefined Then
		
		SampleIndex = ?(TypeOfReceipt = Type("DocumentRef.ReceiptOfGoodsToWarehouse"), 5, 3);
		
		Query = New Query(RequestTextVerificationOfAcceptedGoodsByOrders(TypeOfReceipt));
		Query.SetParameter("ReferenceArray",  ReferenceArray);
		Query.SetParameter("DocumentInflow", DocumentInflow);
		Query.SetParameter("Terms",          Terms);
		Query.SetParameter("Contract",             Contract);
		Query.SetParameter("Warehouse",               Warehouse);
		Query.SetParameter("GoodsReceiptOption", GoodsReceiptOption);
		Query.SetParameter("FillInByReceipts", FillInByReceipts);
		SetOrderSelectionParameterInGoodsForReceiptRegister(Query);
		Result = Query.ExecuteBatch(); 
		Selection = Result[SampleIndex].Select();
	Else
		Query = New Query(RequestTextVerificationOfAcceptedGoodsByConsignmentNote());
		Query.SetParameter("DocumentInflow",   DocumentInflow);
		Query.SetParameter("Terms",            Terms);
		Query.SetParameter("Contract",               Contract);
		Query.SetParameter("Warehouse",                 Warehouse);
		Query.SetParameter("GoodsReceiptOption", GoodsReceiptOption);
		SetOrderSelectionParameterInGoodsForReceiptRegister(Query);
		Result = Query.Execute();
		Selection = Result.Select();
	EndIf;
	
	If Selection.Next() Then
		ThereAreAcceptedGoods = (Selection.Count > 0);
	EndIf;
	
	LinesToDelete = New Map;
	
	UnloadedColumns = "Products, Characteristic, Series, Package, Count, Purpose";
	
	If Warehouse = Undefined
		Or TypeOf(Warehouse) = Type("Array") Then
		AddWarehouseColumn = False;
		UnloadedColumns = UnloadedColumns + ", Warehouse";
	Else
		AddWarehouseColumn = True;
	EndIf;
	
	AddOrderToSupplierColumn = True;
	
	If ReferenceArray <> Undefined
		And (TypeOfReceipt = Type("DocumentRef.VendorInvoice")
			Or TypeOfReceipt = Type("DocumentRef.GoodsReceiptForStorage"))
		And GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
		
		AddOrderToSupplierColumn = False;
		UnloadedColumns = UnloadedColumns + ", PurchaseOrder";
		
	EndIf;
	
	TableOfGoods = Goods.Unload(, UnloadedColumns); // ValueTable
	
	If AddWarehouseColumn Then
		TableOfGoods.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		For Each CurRow In TableOfGoods Do
			CurRow.Warehouse = Warehouse;
		EndDo;
	EndIf;
	
	If AddOrderToSupplierColumn Then
		
		OrderTypes = New Array;
		OrderTypes.Add(Type("DocumentRef.PurchaseOrder"));
		OrderTypes.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
		TableOfGoods.Columns.Add("PurchaseOrder", New TypeDescription(OrderTypes));
		
	EndIf;
	
	If ReferenceArray <> Undefined Then
		Query = New Query(QueryTextByReferences(TypeOfReceipt));
		Query.SetParameter("ReferenceArray", ReferenceArray);
	Else
		Query = New Query(RequestTextForInvoiceOrAgreement());
	EndIf;
	
	Query.SetParameter("Date",       ?(ValueIsFilled(DateOfReceipt), DateOfReceipt, CurrentSessionDate()));
	Query.SetParameter("Ref",     ?(ValueIsFilled(CurrentDocument), CurrentDocument, DocumentInflow));
	Query.SetParameter("DocumentInflow", DocumentInflow);
	Query.SetParameter("Goods",     TableOfGoods);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Contract",    Contract);
	Query.SetParameter("Warehouse",      Warehouse);
	Query.SetParameter("GoodsReceiptOption", GoodsReceiptOption);
	Query.SetParameter("FillInByReceipts", FillInByReceipts);
	SetOrderSelectionParameterInGoodsForReceiptRegister(Query);
	
	QueryResult = Query.ExecuteBatch(); 
	
	If QueryResult[0].IsEmpty() Or Not ThereAreAcceptedGoods Then
		Return HasChanges;
	EndIf;
	
	If ReferenceArray <> Undefined
		And TypeOfReceipt = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		BalanceTable = QueryResult[4].Unload();
		BalanceTable.Indexes.Add("Products, Characteristic");
		
		SelectionOfServices             = QueryResult[6].Select();
		SelectionOfPackages          = QueryResult[7].Select();
		SelectionOfNonRandomWarehouses = QueryResult[8].Select();
		
	ElsIf ReferenceArray <> Undefined Then
		BalanceTable = QueryResult[2].Unload();
		BalanceTable.Indexes.Add("Products, Characteristic");
		
		SelectionOfServices             = QueryResult[4].Select();
		SelectionOfPackages          = QueryResult[5].Select();
		SelectionOfNonRandomWarehouses = QueryResult[6].Select();
		
	Else
		BalanceTable = QueryResult[1].Unload();
		BalanceTable.Indexes.Add("Products, Characteristic");
		
		SelectionOfServices             = QueryResult[3].Select();
		SelectionOfPackages          = QueryResult[4].Select();
		SelectionOfNonRandomWarehouses = QueryResult[5].Select();
		
	EndIf;
	
	RowsDistributedBySeries = New Array; // Array of See NewStructureForDistribution
	
	InitialRowsToBeRefilledWithResidues = New Array; // Array of See NewStructureToRefilling
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;

	For Each CurRow In Goods Do
		
		If AdditionalSearchParameters_ <> Undefined Then
			ThereIsDiscrepancy_ = False;
			For Each AdditionalSearchParameter In AdditionalSearchParameters_ Do
				If CurRow[AdditionalSearchParameter.Key] <> AdditionalSearchParameter.Value Then
					ThereIsDiscrepancy_ = True;
					Break;
				EndIf;
			EndDo;
			
			If ThereIsDiscrepancy_ Then
				Continue;
			EndIf;
			
		EndIf;
		
		If PossibleDamage And (Not FillingInDiscrepancyReport) And CurRow.Damage Then
			CurProducts   = CurRow.ProductsRecordingAsReceived;
			CurCharacteristic = CurRow.CharacteristicRecordingAsReceived;
		Else
			CurProducts   = CurRow.Products;
			CurCharacteristic = CurRow.Characteristic;
		EndIf;
		
		SelectionOfServices.Reset();
		If SelectionOfServices.FindNext(CurProducts, "Products") Then
			Continue;
		EndIf;
		
		If Warehouse = Undefined Or TypeOf(Warehouse) = Type("Array") Then
			SearchWarehouse = CurRow.Warehouse;
		ElsIf CurRow.ItemsType = Enums.ItemsTypes.OperationService
			Or CurRow.ItemsType = Enums.ItemsTypes.Work_5 Then
			
			SearchWarehouse = Catalogs.Warehouses.EmptyRef();
			
		Else
			SearchWarehouse = Warehouse;
		EndIf;
		
		SelectionOfNonRandomWarehouses.Reset();
		If SelectionOfNonRandomWarehouses.FindNext(SearchWarehouse, "Warehouse")
			And Not FillInByReceipts Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products", CurProducts);
		TheStructureOfTheSearch.Insert("Characteristic", CurCharacteristic);
		TheStructureOfTheSearch.Insert("Series", CurRow.Series);
		TheStructureOfTheSearch.Insert("Warehouse", SearchWarehouse);
		TheStructureOfTheSearch.Insert("Purpose", CurRow.Purpose);
			
		If ReferenceArray <> Undefined
			And (TypeOfReceipt = Type("DocumentRef.VendorInvoice")
				Or TypeOfReceipt = Type("DocumentRef.GoodsReceiptForStorage"))
			And GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
			
			TheStructureOfTheSearch.Insert("ReferenceOrder", CurRow.PurchaseOrder);
			
		EndIf;
		
		If ValueIsFilled(CurRow.Package) Then
			If SelectionOfPackages.FindNext(CurRow.Package, "Package") Then
				PackagingFactor = SelectionOfPackages.ZoomRatio;
			Else
				PackagingFactor = 1;
			EndIf;
			SelectionOfPackages.Reset();
		Else
			PackagingFactor = 1;
		EndIf;
		
		InitialQuantity_ = CurRow.Count;
		CurrentCount = CurRow.Count;
		
		OriginalStringIsProcessed = False;
		
		RowsOfRemainderTable = BalanceTable.FindRows(TheStructureOfTheSearch);
		
		If RowsOfRemainderTable.Count() > 0
			And RowsOfRemainderTable[0].Count > 0 Then
			
			RemainderLine_ = RowsOfRemainderTable[0];
			ThereAreAcceptedGoods = True;
			
			If CurrentCount > 0 Then
				
				QuantityToAdd = Min(CurrentCount, RemainderLine_.Count);
				
				CurrentCount = CurrentCount - QuantityToAdd;
				RemainderLine_.Count = RemainderLine_.Count - QuantityToAdd;
				RemainderLine_.ProductsAdded = (RemainderLine_.Count = 0);
				
				AddedNumberOfPackages = QuantityToAdd / PackagingFactor;
				
				CurRow.Series = RemainderLine_.Series;
				CurRow.Count = QuantityToAdd;
				CurRow.NumberOfPackages = AddedNumberOfPackages;
				OriginalStringIsProcessed = True;
				
				If RemainderLine_.Count = 0 Then
					BalanceTable.Delete(RemainderLine_)
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If CurrentCount > 0
			And CurRow.BatchesIndicationStatus > 0 Then
				
			RefillingLine = NewStructureToRefilling();
			FillPropertyValues(RefillingLine, TheStructureOfTheSearch);
			RefillingLine.String = CurRow;
			RefillingLine.Count = CurrentCount;
			RefillingLine.PackagingFactor = PackagingFactor;
			RefillingLine.StringProcessed = OriginalStringIsProcessed;
			InitialRowsToBeRefilledWithResidues.Add(RefillingLine);
			
		ElsIf CurRow.Count = 0
			Or Not OriginalStringIsProcessed Then
			
			LinesToDelete.Insert(CurRow);
			
		EndIf;
		
		If CurRow.Count <> InitialQuantity_ Then
			
			RowsToProcess.Add(CurRow);
			
		EndIf;
		
		HasChanges = HasChanges 
			Or CurRow.Count <> InitialQuantity_;
			
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActionsWithModifiedStrings,
		Goods,
		CachedValues);

	// Search in the balances for registration of receipts without taking into account the series
	TheStructureOfTheSearch = New Structure("ProductsAdded, Products, Characteristic, Warehouse");
	TheStructureOfTheSearch.ProductsAdded = False;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;

	For Each RefillingLine In InitialRowsToBeRefilledWithResidues Do
		
		CurRow                = RefillingLine.String;
		CurrentCount        = RefillingLine.Count;
		OriginalStringIsProcessed = RefillingLine.StringProcessed;
		InitialQuantity_       = CurRow.Count;
		OriginalSeries            = CurRow.Series;
		
		FillPropertyValues(TheStructureOfTheSearch,RefillingLine);
		
		TheStructureOfTheSearch.Insert("Purpose", CurRow.Purpose);
			
		If ReferenceArray <> Undefined
			And (TypeOfReceipt = Type("DocumentRef.VendorInvoice")
				Or TypeOfReceipt = Type("DocumentRef.GoodsReceiptForStorage"))
			And GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
			
			TheStructureOfTheSearch.Insert("ReferenceOrder", CurRow.PurchaseOrder);
			
		EndIf;
		
		RowsOfRemainderTable = BalanceTable.FindRows(TheStructureOfTheSearch);
		
		For Each RemainderLine_ In RowsOfRemainderTable Do
			
			If RemainderLine_.Count = 0 Then
				Continue;
			EndIf;
			
			ThereAreAcceptedGoods = True;
			
			If CurrentCount = 0 Then
				Break;
			EndIf;
			
			QuantityToAdd = Min(CurrentCount, RemainderLine_.Count);
			
			CurrentCount = CurrentCount - QuantityToAdd;
			RemainderLine_.Count = RemainderLine_.Count - QuantityToAdd;
			RemainderLine_.ProductsAdded = (RemainderLine_.Count = 0);
			
			AddedNumberOfPackages = QuantityToAdd / RefillingLine.PackagingFactor;
			
			If Not OriginalStringIsProcessed Then
				
				CurRow.Series = RemainderLine_.Series;
				CurRow.Count = QuantityToAdd;
				CurRow.NumberOfPackages = AddedNumberOfPackages;
				OriginalStringIsProcessed = True;
				
			Else
				
				AddedRowsDistributedBySeries = NewStructureForDistribution();
				AddedRowsDistributedBySeries.String = CurRow;
				AddedRowsDistributedBySeries.Series = RemainderLine_.Series;
				AddedRowsDistributedBySeries.Count = QuantityToAdd;
				AddedRowsDistributedBySeries.NumberOfPackages = AddedNumberOfPackages;
				
				RowsDistributedBySeries.Add(AddedRowsDistributedBySeries);
				
			EndIf;
			
		EndDo;
		
		If CurRow.Count = 0
			Or Not OriginalStringIsProcessed Then
			LinesToDelete.Insert(CurRow);
		ElsIf CurRow.Count <> InitialQuantity_ Then
			RowsToProcess.Add(CurRow);
		EndIf;
		
		HasChanges = HasChanges 
			Or CurRow.Count <> InitialQuantity_
			Or OriginalSeries <> CurRow.Series;
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActionsWithModifiedStrings,
		Goods,
		CachedValues);

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;

	For Each RowWithSeries In RowsDistributedBySeries Do
		NewRow = Goods.Insert(Goods.IndexOf(RowWithSeries.String)+1);
		FillPropertyValues(NewRow,RowWithSeries.String);
		FillPropertyValues(NewRow,RowWithSeries); // Series, Quantity, quantity of packages
		RowsToProcess.Add(NewRow);
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActionsWithModifiedStrings,
		Goods,
		CachedValues);

	UnallocatedRows = BalanceTable.FindRows(New Structure("ProductsAdded", False));
	HasChanges = HasChanges
		Or RowsDistributedBySeries.Count() > 0
		Or LinesToDelete.Count() > 0
		Or UnallocatedRows.Count() > 0;
	
	For Each CurItem In LinesToDelete Do
		Goods.Delete(CurItem.Key);
	EndDo;
	
	PropertiesToExclude = New Structure("RowCode, DocumentSalesOfGoodsAndServices, OrderPrice", 0, Undefined, 0);
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Series, Purpose");
	If Warehouse = Undefined Or TypeOf(Warehouse) = Type("Array") Then
		TheStructureOfTheSearch.Insert("Warehouse");
	EndIf;
	If ReferenceArray <> Undefined
		And (TypeOfReceipt = Type("DocumentRef.VendorInvoice")
			Or TypeOfReceipt = Type("DocumentRef.GoodsReceiptForStorage"))
		And GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
		
		TheStructureOfTheSearch.Insert("PurchaseOrder");
		
	EndIf;
	
	If UnallocatedRows.Count() > 0 Then
		OrderOrder		= ValueIsFilled(ReferenceArray)
									And ReferenceArray.Count() > 0
									And (TypeOf(ReferenceArray[0]) = Type("DocumentRef.PurchaseOrder")
										Or TypeOf(ReferenceArray[0]) = Type("DocumentRef.SubcontractOrder2_5")
										Or TypeOf(ReferenceArray[0]) = Type("DocumentRef.MaterialProviderOrder2_5")
										Or TypeOf(ReferenceArray[0]) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
		AcceptableDeviations	= PermissibleDeviationsOfMeasuredGoods(ReferenceArray, OrderOrder);
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;
	
	For Each LineToAdd_ In UnallocatedRows Do
		
		If Not TheStructureOfTheSearch.Property("Warehouse")
			And Warehouse <> LineToAdd_.Warehouse Then
			Continue;
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, LineToAdd_);
		If TheStructureOfTheSearch.Property("PurchaseOrder") Then
			TheStructureOfTheSearch.PurchaseOrder = LineToAdd_.ReferenceOrder;
		EndIf;
		
		ProductLines_2 = Goods.FindRows(TheStructureOfTheSearch);
		
		If ProductLines_2.Count() = 0 Then
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, LineToAdd_);
			
			If TheStructureOfTheSearch.Property("PurchaseOrder") 
				And ValueIsFilled(LineToAdd_.ReferenceOrder)
				And TypeOf(LineToAdd_.ReferenceOrder) = Type("DocumentRef.PurchaseOrder") Then
				NewRow.PurchaseOrder = LineToAdd_.ReferenceOrder;
			ElsIf TheStructureOfTheSearch.Property("PurchaseOrder")
					And ValueIsFilled(LineToAdd_.ReferenceOrder)
					And TypeOf(LineToAdd_.ReferenceOrder) = Type("DocumentRef.MaterialProviderOrder2_5") Then
						
						NewRow.PurchaseOrder = LineToAdd_.ReferenceOrder;
			EndIf;	
				

			NewRow.NumberOfPackages = LineToAdd_.Count;
			ProcessedLinesAreNew.Add(NewRow);
		Else
			RowOfGoods = ProductLines_2[0];
			
			If ValueIsFilled(RowOfGoods.Package) Then
				If SelectionOfPackages.FindNext(RowOfGoods.Package, "Package") Then
					PackagingFactor = SelectionOfPackages.ZoomRatio;
				Else
					PackagingFactor = 1;
				EndIf;
				SelectionOfPackages.Reset();
			Else
				PackagingFactor = 1;
			EndIf;
			
			DeviationSearchStructure = New Structure("Products, Characteristic",
											LineToAdd_.Products,
											LineToAdd_.Characteristic);
			
			If ReferenceArray <> Undefined
				And (TypeOfReceipt = Type("DocumentRef.VendorInvoice")
					Or TypeOfReceipt = Type("DocumentRef.GoodsReceiptForStorage"))
				And GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
				
				DeviationSearchStructure.Insert("OrderDocument",LineToAdd_.ReferenceOrder);
				
			EndIf;
			
			ToleranceLines = AcceptableDeviations.FindRows(DeviationSearchStructure);
			
			ThereIsLineCode = CommonClientServer.HasAttributeOrObjectProperty(RowOfGoods, "RowCode");
			
			If ReferenceArray <> Undefined
				And ThereIsLineCode
				And ValueIsFilled(RowOfGoods.RowCode) Then
				
				If ToleranceLines.Count() > 0
					And ToleranceLines[0].AllowableVariance >= LineToAdd_.Count Then
					RowOfGoods.Count = RowOfGoods.Count + LineToAdd_.Count;
					RowOfGoods.NumberOfPackages = RowOfGoods.Count / PackagingFactor;
					RowsToProcess.Add(RowOfGoods);
				Else
					NewRow = Goods.Add();
					FillPropertyValues(NewRow, RowOfGoods);
					FillPropertyValues(NewRow, PropertiesToExclude);
					NewRow.Count = LineToAdd_.Count;
					NewRow.NumberOfPackages = NewRow.Count / PackagingFactor;
					ProcessedLinesAreNew.Add(NewRow);
				EndIf;
				
			Else
				RowOfGoods.Count = RowOfGoods.Count + LineToAdd_.Count;
				RowOfGoods.NumberOfPackages = RowOfGoods.NumberOfPackages + LineToAdd_.Count / PackagingFactor;
				RowsToProcess.Add(RowOfGoods);
			EndIf;
		EndIf;
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActionsWithAddedStrings,
		Goods,
		CachedValues);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActionsWithModifiedStrings,
		Goods,
		CachedValues);

	Return HasChanges;
	
EndFunction

// Returns:
// 	Structure:
// * StringProcessed - Boolean
// * PackagingFactor - Number
// * Count - Number
// * Warehouse - CatalogRef.Warehouses
// * Characteristic - CatalogRef.ItemsCharacteristics
// * Products - CatalogRef.Products
// * String - ValueTableRow
//
Function NewStructureToRefilling()

	Result = New Structure;
	
	Result.Insert("String");
	Result.Insert("Products");
	Result.Insert("Characteristic");
	Result.Insert("Warehouse");
	Result.Insert("Count");
	Result.Insert("PackagingFactor");
	Result.Insert("StringProcessed");

	Return Result;
	
EndFunction

// Returns:
// 	Structure:
// * NumberOfPackages - Number
// * Count - Number
// * Series - CatalogRef.ItemsBatches
// * String - ValueTableRow
//
Function NewStructureForDistribution()

	Result = New Structure;
	
	Result.Insert("String");
	Result.Insert("Series");
	Result.Insert("Count");
	Result.Insert("NumberOfPackages");

	Return Result;
	
EndFunction

// Returns the table of acceptable deviations of measured products
//
// Parameters:
//  ReferenceArray - Array - array of orders.
//  OrderOrder  - Boolean - .
// 
// Returns:
//  ValueTable
//
Function PermissibleDeviationsOfMeasuredGoods(ReferenceArray, OrderOrder = True) Export
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If Not ValueIsFilled(ReferenceArray)
		Or Not OrderOrder
		Or AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 
		Or ReferenceArray.Count() = 0 Then
		Table = New ValueTable;
		Table.Columns.Add("OrderDocument");
		Table.Columns.Add("PurchaseOrder");
		Table.Columns.Add("Products");
		Table.Columns.Add("Characteristic");
		Table.Columns.Add("Warehouse");
		Return Table;
	EndIf;
	
	Query = New Query;
	
	Query.SetParameter("ReferenceArray", ReferenceArray);
	Query.SetParameter("DimensionalTypesOfUnits",
	                           Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
	                           AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	
	If TypeOf(ReferenceArray[0]) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		Query.Text =
		"SELECT
		|	GoodsToReceive.ReferenceOrder AS OrderDocument,
		|	GoodsToReceive.Products AS Products,
		|	GoodsToReceive.Characteristic AS Characteristic,
		|	SUM(GoodsToReceive.ForRegistrationOnReturnsQuantityTurnover *
		|		(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|FROM
		|	#RequestsForReturnsTurnoverExpanded AS GoodsToReceive
		|GROUP BY
		|	GoodsToReceive.ReferenceOrder,
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.BeginOfPeriod = "&StartPeriod_";
		TableFormationParameters.EndOfPeriod = "&ConPeriod";
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&ReferenceArray)
			|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
		TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic";
		TableFormationParameters.Indicators = "ToRegisterForReturns";
		TableFormationParameters.Resources = "Count";
		
		RequestsForReturnsTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#RequestsForReturnsTurnoverExpanded",
			RequestsForReturnsTurnoverExpanded);
		
		SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns(
			"ShipmentAndReturnReferences",
			"ReferenceOrder IN (&ReferenceArray)",
			Query.Parameters);
		
		Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
		Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
		
	ElsIf TypeOf(ReferenceArray[0]) = Type("DocumentRef.PurchaseOrder")
		Or TypeOf(ReferenceArray[0]) = Type("DocumentRef.MaterialProviderOrder2_5")
		Or TypeOf(ReferenceArray[0]) = Type("DocumentRef.SubcontractOrder2_5")
		Then
		Query.Text =
		"SELECT
		|	GoodsToReceive.PurchaseOrder AS PurchaseOrder,
		|	GoodsToReceive.PurchaseOrder AS OrderDocument,
		|	GoodsToReceive.Products    AS Products,
		|	GoodsToReceive.Characteristic  AS Characteristic,
		|	GoodsToReceive.Warehouse           AS Warehouse,
		|	SUM(GoodsToReceive.ToRegisterReceipt * 
		|		(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|FROM
		|	AccumulationRegister.PurchaseOrders.Turnovers(&StartPeriod_,&ConPeriod,, 
		|		PurchaseOrder IN (&ReferenceArray)) AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	GoodsToReceive.PurchaseOrder,
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Warehouse";
		
		SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("PurchaseOrders",
																"PurchaseOrder IN (&ReferenceArray)",
																Query.Parameters);
		
		Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
		Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
		
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithAcceptanceOptions

// Fills in the list of acceptance options
//
// Parameters:
//  ExecutionOfAnOrder - FormField - field of the form with the order execution settings.
//
Procedure FillInListOfAcceptanceOptions(ExecutionOfAnOrder) Export
	
	OrderExecutionValue = "";
	ConstantValue = Constants.GoodsReceiptOption.Get();
	FillInAcceptanceOptionsSettings(ConstantValue, OrderExecutionValue);
	
	SelectionListOrder = ExecutionOfAnOrder.ChoiceList;
	
	SelectionListOrder.Clear();
	
	OrdersAreUsed_ = GetFunctionalOption("UsePurchaseOrders")
		Or GetFunctionalOption("UseTransferOrders")
		Or GetFunctionalOption("UseProductionManagement2_2")
		Or GetFunctionalOption("UseAssemblyDisassemblyOrders");
	
	If OrdersAreUsed_ Then
		SelectionListOrder.Add("AfterOrdering", NStr("vi = 'Sau khi tạo đơn hàng';
													|ru = 'После оформления заказа';
													|en = 'After order registration'; fa = 'After order registration';
													|it = 'Dopo aver effettuato l''ordine';
													|pl = 'Po sporządzeniu zamówienia';
													|tr = 'Sipariş kaydedildikten sonra'"));
		SelectionListOrder.Add("AfterInvoice", NStr("vi = 'Sau khi tạo hóa đơn';
													|ru = 'После оформления накладной';
													|en = 'After invoice registration'; fa = 'After invoice registration';
													|it = 'Dopo aver eseguito il documento di trasporto';
													|pl = 'Po sporządzeniu listu przewozowego';
													|tr = 'Fatura kaydedildikten sonra'"));
	Else
		ValueSelectionList = ?(OrderExecutionValue = "AfterInvoice", OrderExecutionValue, "AfterOrdering");
		SelectionListOrder.Add(ValueSelectionList, NStr("vi = 'Sau khi tạo hóa đơn';
														|ru = 'После оформления накладной';
														|en = 'After invoice registration'; fa = 'After invoice registration';
														|it = 'Dopo aver eseguito il documento di trasporto';
														|pl = 'Po sporządzeniu listu przewozowego';
														|tr = 'Fatura kaydedildikten sonra'"));
	EndIf;
	
EndProcedure

// Fills in the list of acceptance options for agreements
//
// Parameters:
//  ExecutionOfAnOrder - FormField - the form field by setting an order
//  GoodsReceipt	 - FormField - field of the form with the product acceptance settings.
//
Procedure FillInListOfSelectionOfAcceptanceOptionsForAgreements(ExecutionOfAnOrder, GoodsReceipt) Export
	
	OrderExecutionValue = "";
	ConstantValue = Constants.GoodsReceiptOption.Get();
	FillInAcceptanceOptionsSettings(ConstantValue, OrderExecutionValue);
	
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	SelectionListOrder = ExecutionOfAnOrder.ChoiceList;
	
	SelectionListOrder.Clear();
	If GetFunctionalOption("UsePurchaseOrders") Then
		SelectionListOrder.Add("AfterOrdering", NStr("vi = 'Sau khi tạo đơn hàng';
													|ru = 'После оформления заказа';
													|en = 'After order registration'; fa = 'After order registration';
													|it = 'Dopo aver effettuato l''ordine';
													|pl = 'Po sporządzeniu zamówienia';
													|tr = 'Sipariş kaydedildikten sonra'"));
		SelectionListOrder.Add("AfterInvoice", NStr("vi = 'Sau khi tạo hóa đơn';
													|ru = 'После оформления накладной';
													|en = 'After invoice registration'; fa = 'After invoice registration';
													|it = 'Dopo aver eseguito il documento di trasporto';
													|pl = 'Po sporządzeniu listu przewozowego';
													|tr = 'Fatura kaydedildikten sonra'"));
	Else
		ValueSelectionList = ?(OrderExecutionValue = "AfterInvoice", OrderExecutionValue, "AfterOrdering");
		SelectionListOrder.Add(ValueSelectionList, NStr("vi = 'Sau khi tạo hóa đơn';
														|ru = 'После оформления накладной';
														|en = 'After invoice registration'; fa = 'After invoice registration';
														|it = 'Dopo aver eseguito il documento di trasporto';
														|pl = 'Po sporządzeniu listu przewozowego';
														|tr = 'Fatura kaydedildikten sonra'"));
	EndIf;
	
	If UseTermsOfPurchases Then
		SelectionListOrder.Add("ByAgreement", NStr("vi = 'Theo thỏa thuận hiện tại (bao gồm không có chứng từ)';
													|ru = 'По текущему соглашению (в т.ч. без документов)';
													|en = 'By the current agreement (including without documents)'; fa = 'By the current agreement (including without documents)';
													|it = 'In base all''accordo corrente (inclusi senza documenti)';
													|pl = 'Z tytułu bieżącej umowy (w tym bez dokumentów)';
													|tr = 'Mevcut anlaşmaya göre (aynı zamanda belgesiz)'"));
	EndIf;
	ExecutionOfAnOrder.Enabled = SelectionListOrder.Count()>1;
	
	If GoodsReceipt <> Undefined Then
		AcceptanceSelectionList = GoodsReceipt.ChoiceList;
		AcceptanceSelectionList.Clear();
		AcceptanceSelectionList.Add("Divided", NStr("vi = 'Chia theo chứng từ';
													|ru = 'Разделена по документам';
													|en = 'Split by documents'; fa = 'Split by documents';
													|it = 'Diviso per documenti';
													|pl = 'Jest podzielona wg dokumentów';
													|tr = 'Belgelere göre bölündü'"));
		If UseTermsOfPurchases Then
			AcceptanceSelectionList.Add("NotDivided", NStr("vi = 'Nhóm theo thỏa thuận';
															|ru = 'Сгруппирована по соглашениям';
															|en = 'Grouped by agreements'; fa = 'Grouped by agreements';
															|it = 'Raggruppato per accordi';
															|pl = 'Zgrupowano wg umów';
															|tr = 'Anlaşmalara göre gruplandırılmış'"));
		EndIf;
		GoodsReceipt.Enabled = AcceptanceSelectionList.Count()>1;
	EndIf;
	
EndProcedure

// Fills in the settings for acceptance options based on the enumeration value
//
// Parameters:
//  GoodsReceiptOption	 - EnumRef.GoodsReceiptOptions - Acceptance option
//  ExecutionOfAnOrder		 - String - customizing the appearance of the order
//  GoodsReceipt			 - String - setting up the acceptance division.
// 
Procedure FillInAcceptanceOptionsSettings(GoodsReceiptOption, ExecutionOfAnOrder, GoodsReceipt = Undefined) Export
	
	If GoodsReceiptOption = Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices Then
		ExecutionOfAnOrder = "ByContract";
		GoodsReceipt = "NotDivided";
	ElsIf GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices Then
		ExecutionOfAnOrder = "AfterOrdering";
		GoodsReceipt = "NotDivided";
	ElsIf GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterInvoices Then
		ExecutionOfAnOrder = "AfterInvoice";
		GoodsReceipt = "NotDivided";
	ElsIf GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
		ExecutionOfAnOrder = "AfterOrdering";
		GoodsReceipt = "Divided";
	ElsIf GoodsReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly Then
		ExecutionOfAnOrder = "AfterInvoice";
		GoodsReceipt = "Divided";
	EndIf;
	
EndProcedure

// Fills in the settings for acceptance options based on the enumeration value
//
// Parameters:
//  ExecutionOfAnOrder - String - customizing the appearance of the order
//  GoodsReceipt   - String - setting up the acceptance division.
//
// Returns:
//  EnumRef.GoodsReceiptOptions - Acceptance option.
//
Function GetOptionsForAcceptanceBySettings(ExecutionOfAnOrder, GoodsReceipt) Export
	
	If ExecutionOfAnOrder = "ByContract" Then
		GoodsReceiptOption = Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices
	ElsIf ExecutionOfAnOrder = "AfterOrdering" And GoodsReceipt = "NotDivided" Then
		GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices
	ElsIf ExecutionOfAnOrder = "AfterInvoice" And GoodsReceipt = "NotDivided" Then
		GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterInvoices
	ElsIf ExecutionOfAnOrder = "AfterOrdering" And GoodsReceipt = "Divided" Then
		GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices;
	ElsIf ExecutionOfAnOrder = "AfterInvoice" And GoodsReceipt = "Divided" Then
		GoodsReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly;
	EndIf;
	
	Return GoodsReceiptOption;
	
EndFunction

// Returns whether the invoice is used as an acceptance order
//
// Parameters:
//	GoodsReceiptOption - EnumRef.GoodsReceiptOptions - link to the acceptance option.
//
// Returns:
//	Boolean - True if the acceptance agreement is used.
//
Function OrderForAcceptanceOfGoodsConsignmentNote(Val GoodsReceiptOption) Export
	
	If Not ValueIsFilled(GoodsReceiptOption) Then
		GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	EndIf;
	
	Result = False;
	
	If GoodsReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly Then 
		
		Result = True;
		
	EndIf;
	
	Return Result
	
EndFunction

// Returns whether an order / invoice without an order is used as an order for acceptance.
//
// Parameters:
//	GoodsReceiptOption - EnumRef.GoodsReceiptOptions - link to the acceptance option.
//
// Returns:
//	Boolean - True if the acceptance agreement is used.
//
Function OrderForAcceptanceOfGoodsOrder(Val GoodsReceiptOption) Export
	
	If Not ValueIsFilled(GoodsReceiptOption) Then
		GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	EndIf;
	
	Result = False;
	
	If GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then 
		
		Result = True;
		
	EndIf;
	
	Return Result
	
EndFunction

// Fills in the list of acceptance options for agreements
//
// Parameters:
//	ExecutionOfAnOrder - FormField - the form field by setting an order
//	GoodsReceipt - FormField - field of the form with the product acceptance settings.
//	PurchaseRegistrationOption - EnumRef.PurchaseRegistrationOptions - option for making a separate purchase.
//
Procedure FillInListOfContractAcceptanceOptions(ExecutionOfAnOrder, GoodsReceipt, PurchaseRegistrationOption = Undefined) Export
	
	OrderExecutionValue = "";
	ConstantValue = Constants.GoodsReceiptOption.Get();
	FillInAcceptanceOptionsSettings(ConstantValue, OrderExecutionValue);
	
	UseContractsWithVendors = GetFunctionalOption("UseContractsWithVendors");
	SelectionListOrder = ExecutionOfAnOrder.ChoiceList;
	
	UnfacturedDeliverySelected = (PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods
										Or PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices);
	SelectedProductsOnWay = (PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.GoodsInTransit);
	
	SelectionListOrder.Clear();
	If GetFunctionalOption("UsePurchaseOrders") 
		And UnfacturedDeliverySelected Then
		SelectionListOrder.Add("AfterOrdering", NStr("vi = 'Sau khi tạo đơn hàng';
													|ru = 'После оформления заказа';
													|en = 'After order registration'; fa = 'After order registration';
													|it = 'Dopo aver effettuato l''ordine';
													|pl = 'Po sporządzeniu zamówienia';
													|tr = 'Sipariş kaydedildikten sonra'"));
	ElsIf GetFunctionalOption("UsePurchaseOrders") 
		And Not UnfacturedDeliverySelected Then
		SelectionListOrder.Add("AfterOrdering", NStr("vi = 'Sau khi tạo đơn hàng';
													|ru = 'После оформления заказа';
													|en = 'After order registration'; fa = 'After order registration';
													|it = 'Dopo aver effettuato l''ordine';
													|pl = 'Po sporządzeniu zamówienia';
													|tr = 'Sipariş kaydedildikten sonra'"));
		SelectionListOrder.Add("AfterInvoice", NStr("vi = 'Sau khi tạo hóa đơn';
													|ru = 'После оформления накладной';
													|en = 'After invoice registration'; fa = 'After invoice registration';
													|it = 'Dopo aver eseguito il documento di trasporto';
													|pl = 'Po sporządzeniu listu przewozowego';
													|tr = 'Fatura kaydedildikten sonra'"));
	ElsIf SelectedProductsOnWay Then
		SelectionListOrder.Add("AfterInvoice", NStr("vi = 'Sau khi tạo hóa đơn';
													|ru = 'После оформления накладной';
													|en = 'After invoice registration'; fa = 'After invoice registration';
													|it = 'Dopo aver eseguito il documento di trasporto';
													|pl = 'Po sporządzeniu listu przewozowego';
													|tr = 'Fatura kaydedildikten sonra'"));
	ElsIf Not UnfacturedDeliverySelected Then
		ValueSelectionList = ?(OrderExecutionValue = "AfterInvoice", OrderExecutionValue, "AfterOrdering");
		SelectionListOrder.Add(ValueSelectionList, NStr("vi = 'Sau khi tạo hóa đơn';
														|ru = 'После оформления накладной';
														|en = 'After invoice registration'; fa = 'After invoice registration';
														|it = 'Dopo aver eseguito il documento di trasporto';
														|pl = 'Po sporządzeniu listu przewozowego';
														|tr = 'Fatura kaydedildikten sonra'"));
	EndIf;
	
	If UseContractsWithVendors Then
		SelectionListOrder.Add("ByContract", NStr("vi = 'Theo hợp đồng hiện tại (ngay cả khi không có chứng từ)';
													|ru = 'По текущему договору (в т.ч. без документов)';
													|en = 'Under the current contract (including without documents)'; fa = 'Under the current contract (including without documents)';
													|it = 'In base all''accordo corrente (inclusi senza documenti)';
													|pl = 'Z tytułu bieżącego kontraktu (w tym bez dokumentów)';
													|tr = 'Mevcut anlaşma kapsamında (aynı zamanda belgesiz dahil)'"));
	EndIf;
	
	ExecutionOfAnOrder.Enabled = SelectionListOrder.Count() > 1;
	
	If GoodsReceipt <> Undefined Then
		AcceptanceSelectionList = GoodsReceipt.ChoiceList;
		AcceptanceSelectionList.Clear();
		AcceptanceSelectionList.Add("Divided", NStr("vi = 'Chia theo chứng từ';
													|ru = 'Разделена по документам';
													|en = 'Split by documents'; fa = 'Split by documents';
													|it = 'Diviso per documenti';
													|pl = 'Jest podzielona wg dokumentów';
													|tr = 'Belgelere göre bölündü'"));
		If UseContractsWithVendors Then
			AcceptanceSelectionList.Add("NotDivided", NStr("vi = 'Nhóm theo thỏa thuận';
															|ru = 'Сгруппирована по договорам';
															|en = 'Grouped by contracts'; fa = 'Grouped by contracts';
															|it = 'Raggruppato per contratti';
															|pl = 'Zgrupowano wg kontraktów';
															|tr = 'Anlaşmalara göre gruplandırılmış'"));
		EndIf;
		GoodsReceipt.Enabled = AcceptanceSelectionList.Count() > 1;
	EndIf;
	
EndProcedure

// Fills in the list of service acceptance options
//
// Parameters:
//	ExecutionOfAnOrder - FormField - field of the form with the order execution settings.
//	AcceptanceOfServices - FormField - the Form field with the service acceptance settings.
//	OptionForRegisteringServiceReceiptDocuments - EnumRef.OptionsForRegisteringServiceDocuments - option for making a separate purchase.
//
Procedure FillInListOfOptionsForAcceptingServicesUnderContracts(ExecutionOfAnOrder, AcceptanceOfServices, OptionForRegisteringServiceReceiptDocuments) Export
	
	OrderExecutionValue = "";
	ConstantValue = Constants.GoodsReceiptOption.Get();
	FillInAcceptanceOptionsSettings(ConstantValue, OrderExecutionValue);
	
	UseContractsWithVendors = GetFunctionalOption("UseContractsWithVendors");
	SelectionListOrder = ExecutionOfAnOrder.ChoiceList;
	
	UnfacturedDeliverySelected = OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed;
	
	SelectionListOrder.Clear();
	If GetFunctionalOption("UsePurchaseOrders") Then
		SelectionListOrder.Add("AfterOrdering", NStr("vi = 'Sau khi tạo đơn hàng';
													|ru = 'После оформления заказа';
													|en = 'After order registration'; fa = 'After order registration';
													|it = 'Dopo aver effettuato l''ordine';
													|pl = 'Po sporządzeniu zamówienia';
													|tr = 'Sipariş kaydedildikten sonra'"));
	ElsIf Not UnfacturedDeliverySelected Then
		ValueSelectionList = ?(OrderExecutionValue = "AfterInvoice", OrderExecutionValue, "AfterOrdering");
		SelectionListOrder.Add(ValueSelectionList, NStr("vi = 'Sau khi tạo hóa đơn';
														|ru = 'После оформления накладной';
														|en = 'After invoice registration'; fa = 'After invoice registration';
														|it = 'Dopo aver eseguito il documento di trasporto';
														|pl = 'Po sporządzeniu listu przewozowego';
														|tr = 'Fatura kaydedildikten sonra'"));
	EndIf;
	
	If UseContractsWithVendors Then
		SelectionListOrder.Add("ByContract", NStr("vi = 'Theo hợp đồng hiện tại (ngay cả khi không có chứng từ)';
													|ru = 'По текущему договору (в т.ч. без документов)';
													|en = 'Under the current contract (including without documents)'; fa = 'Under the current contract (including without documents)';
													|it = 'In base all''accordo corrente (inclusi senza documenti)';
													|pl = 'Z tytułu bieżącego kontraktu (w tym bez dokumentów)';
													|tr = 'Mevcut anlaşma kapsamında (aynı zamanda belgesiz dahil)'"));
	EndIf;
	
	ExecutionOfAnOrder.Enabled = SelectionListOrder.Count() > 1;
	
	If AcceptanceOfServices <> Undefined Then
		AcceptanceSelectionList = AcceptanceOfServices.ChoiceList;
		AcceptanceSelectionList.Clear();
		AcceptanceSelectionList.Add("Divided", NStr("vi = 'Chia theo chứng từ';
													|ru = 'Разделена по документам';
													|en = 'Split by documents'; fa = 'Split by documents';
													|it = 'Diviso per documenti';
													|pl = 'Jest podzielona wg dokumentów';
													|tr = 'Belgelere göre bölündü'"));
		If UseContractsWithVendors Then
			AcceptanceSelectionList.Add("NotDivided", NStr("vi = 'Nhóm theo thỏa thuận';
															|ru = 'Сгруппирована по договорам';
															|en = 'Grouped by contracts'; fa = 'Grouped by contracts';
															|it = 'Raggruppato per contratti';
															|pl = 'Zgrupowano wg kontraktów';
															|tr = 'Anlaşmalara göre gruplandırılmış'"));
		EndIf;
		AcceptanceOfServices.Enabled = AcceptanceSelectionList.Count() > 1;
	EndIf;
	
EndProcedure

// Gets the option of accepting goods by order, by agreement, or by the constant of the same name.
//
// Parameters:
//  ReferenceOrder - DocumentRef - the document contains the requisite "Parentpreneur"
//  Contract		 - CatalogRef.CounterpartyContracts - agreement that redefines the option of accepting goods.
// 
// Returns:
//   - EnumRef.GoodsReceiptOptions - the found acceptance option.
//
Function GetProductAcceptanceOption(ReferenceOrder = Undefined, Contract = Undefined) Export
	
	GoodsReceiptOption = Enums.GoodsReceiptOptions.EmptyRef();
	
	If ValueIsFilled(ReferenceOrder)
		And CommonClientServer.HasAttributeOrObjectProperty(ReferenceOrder, "GoodsReceiptOption") Then
		GoodsReceiptOption = Common.ObjectAttributeValue(ReferenceOrder, "GoodsReceiptOption");
	EndIf;
	If ValueIsFilled(Contract) Then
		
		SetPrivilegedMode(True);
		GoodsReceiptOption = ?(ValueIsFilled(GoodsReceiptOption),
								 GoodsReceiptOption,
								 Common.ObjectAttributeValue(Contract, "GoodsReceiptOption"));
		SetPrivilegedMode(False);
	EndIf;
	
	GoodsReceiptOption = ?(ValueIsFilled(GoodsReceiptOption),
							 GoodsReceiptOption,
							 Constants.GoodsReceiptOption.Get());
	
	Return GoodsReceiptOption;
	
EndFunction

// Receives the option of accepting services under the Contract.
//
// Parameters:
//  Contract - CatalogRef.CounterpartyContracts - Contract defining the option of acceptance of services.
// 
// Returns:
//   - EnumRef.GoodsReceiptOptions - the found acceptance option.
//
Function GetServiceAcceptanceOption(Contract) Export
	
	ServiceReceiptOption = Enums.GoodsReceiptOptions.EmptyRef();
	
	If ValueIsFilled(Contract) Then
		SetPrivilegedMode(True);
		
		ContractDetails_ = Common.ObjectAttributesValues(Contract,
			"GoodsReceiptOption, ServiceReceiptOption");
		
		// If the Service Acceptance variant Attribute has not been filled in yet, for example, 
		// when the Catalog update has not yet been completed, 
		// the value of the Product Acceptance variant development is returned.
		If ValueIsFilled(ContractDetails_.ServiceReceiptOption) Then
			ServiceReceiptOption = ContractDetails_.ServiceReceiptOption;
		Else
			ServiceReceiptOption = ContractDetails_.GoodsReceiptOption;
		EndIf;
		
		SetPrivilegedMode(False);
	EndIf;
	
	Return ServiceReceiptOption;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForUpdatingDependentDetailsInOrdersAndInvoices

// Updates the details of debiting expenses in the table part of the document, depending on the purpose.
// 
// Parameters:
//   CollectionRows - Array - array of rows in the collection to update the details in.
//
Procedure ClearDetailsOfChargeForExpensesWhenSettingDestinationInTablePart(CollectionRows) Export
	
	For Each TableRow In CollectionRows Do
	
		If ValueIsFilled(TableRow.Purpose) Then
			
			TableRow.ToExpenseAs = False;
			TableRow.ExpenseItem = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
			TableRow.DimensionOfExpenses = Undefined;
			
		EndIf;
	
	EndDo;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfWorkingWithCCDNumbers

#Region FillingInTablePartGoods

// Constructor for the collection of parameters for creating the default helpdesk 'Number' element.
//
// Returns:
//	Structure - a collection that contains the following properties:
//		* Code - String - the number of CCD.
//		* ProductData_8 - Structure - product information containing the following data:
//			** Products - CatalogRef.Products - information about the nomenclature.
//			** Characteristic - CatalogRef.ItemsCharacteristics - information about the characteristics of the Product.
//			** Package - CatalogRef.PackagesAndUnitsOfMeasure - information about the product packaging.
//			** KitCount - Number - amount of goods.
//			** AmountByProductBatchID - Number - the cost of the product.
//		* OriginCountry - CatalogRef.WorldCountries - information about the country of origin of the goods.
//		* Date - Date- document date.
//		* DocumentCurrency - CatalogRef.Currencies - the currency of the document.
//		* CreatingElementOfAnyType - Boolean - indicates that the Catalog item being created does not depend on the settings
//												for using traceability tracking and the item traceability attribute.
//		* ShowCostByDocument - Boolean - indicates whether the document uses summary indicators.
//		* UseTraceableImportedGoodsAccounting - Boolean - indicates whether tracking of traceable imported
//																	goods is used.
//
Function DefaultCCDNumberCreationParameters() Export
	
	ProductData_8 = New Structure;
	ProductData_8.Insert("Products",			PredefinedValue("Catalog.Products.EmptyRef"));
	ProductData_8.Insert("Characteristic",			PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	ProductData_8.Insert("Package",				PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	ProductData_8.Insert("KitCount",	0);
	ProductData_8.Insert("AmountByProductBatchID",			0);
	
	CreationParameters = New Structure;
	CreationParameters.Insert("Code",					"");
	CreationParameters.Insert("ProductData_8",			ProductData_8);
	CreationParameters.Insert("OriginCountry",	PredefinedValue("Catalog.WorldCountries.EmptyRef"));
	CreationParameters.Insert("Date",					Date(1, 1, 1));
	CreationParameters.Insert("DocumentCurrency",		PredefinedValue("Catalog.Currencies.EmptyRef"));
	CreationParameters.Insert("CreatingElementOfAnyType",	False);
	CreationParameters.Insert("ShowCostByDocument",	False);
	CreationParameters.Insert("UseTraceableImportedGoodsAccounting", False);
	
	Return CreationParameters;
	
EndFunction

// Returns the parameters used when filling in the tabular part of the object with CCD numbers.
//
// Returns:
//	Structure - parameters used when filling in the tabular part of the object with CCD numbers, with the following properties:
//		* NameOfProductsField - String - The name of the column in the tabular part that contains information about the Product for which
//											the CCD number is being filled in.
//		* FieldNameNumberOfPackages - String - the name of the column of the tabular part containing information about the number of packages
//												of the Product for which the CCD number is filled in.
//		* RecalculateQuantityByRNPT - Boolean - a sign of the need to recalculate the quantity according to the RNPT in the rows of the tabular
//													part, filled in with CCD numbers.
//
Function ParametersForFillingInGTDVNumberOfTabularPart() Export
	
	FillParameters = New Structure;
	FillParameters.Insert("NameOfProductsField",			"Products");
	FillParameters.Insert("FieldNameNumberOfPackages",	"NumberOfPackages");
	FillParameters.Insert("RecalculateQuantityByRNPT",	True);
	
	Return FillParameters;
	
EndFunction

// Fills in the CCD numbers in the rows of the tabular part of the object.
//
// Parameters:
//	Goods - FormDataCollection - the tabular part of the object in which information about
//									CCD numbers is filled in.
//	CCDNumber - CatalogRef.CCDNumbers - the value of the CCD number that is used to fill in the table part.
//	RowsIDs - Array of Number - collection of IDs of rows in the table part of the object that need
//											to be filled in.
//	CCDNumbersFilledIn - Boolean - indicates that the table part has been filled in.
//	FillParameters - See ParametersForFillingInGTDVNumberOfTabularPart
//
Procedure FillInGTNumbersInTabularPart(Goods,
											CCDNumber,
											RowsIDs,
											CCDNumbersFilledIn,
											FillParameters = Undefined) Export
	
	If FillParameters = Undefined Then
		FillParameters = ParametersForFillingInGTDVNumberOfTabularPart();
	EndIf;
	
	NameOfProductsField = FillParameters.NameOfProductsField;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ProductData_1.Ref			AS Ref,
	|	ProductData_1.ItemsType	AS ItemsType
	|FROM
	|	Catalog.Products AS ProductData_1
	|WHERE
	|	ProductData_1.Ref IN(&ItemList)
	|	AND ProductData_1.KeepRecordsByCCD
	|	AND ProductData_1.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.Work_5),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CCDNumbers.Ref				AS CCDNumber,
	|	CCDNumbers.CCDNumberType			AS CCDNumberType,
	|	CCDNumbers.OriginCountry	AS OriginCountry
	|FROM
	|	Catalog.CCDNumbers AS CCDNumbers
	|WHERE
	|	CCDNumbers.Ref = &CCDNumber";
	
	Query.SetParameter("CCDNumber", CCDNumber);
	Query.SetParameter("ItemList",
								Goods.Unload(, NameOfProductsField).UnloadColumn(NameOfProductsField));
	
	QueryResult		= Query.ExecuteBatch();
	ResultByProduct	= QueryResult[0];
	ResultOfCCD			= QueryResult[1];
	
	If ResultOfCCD.IsEmpty()
		Or ResultByProduct.IsEmpty() Then
		
		Return;
		
	EndIf;
	
	ImportedGoods = ResultByProduct.Unload();
	
	CCDData = ResultOfCCD.Select();
	CCDData.Next();
	
	CCDNumbersFilledIn	= False;
	ListOfCCDTypes		= AccountingForTraceableGoodsClientServerLocalization.CCDNumberTypes(True);
	
	For Each RowID In RowsIDs Do
		TableRow = Goods.FindByID(RowID);
		
		ProductData_1 = ImportedGoods.Find(TableRow[NameOfProductsField], "Ref");
		
		If ProductData_1 <> Undefined Then
			If ListOfCCDTypes.Find(CCDData.CCDNumberType) = Undefined
				And ProductData_1.ItemsType = Enums.ItemsTypes.Work_5 Then
				
				Continue;
				
			EndIf;
			
			CCDNumbersFilledIn = True;
			
			FillPropertyValues(TableRow, CCDData);
			
			If FillParameters.RecalculateQuantityByRNPT Then
				If TableRow.CCDNumberType = Enums.CCDNumberTypes.KitRNPT Then
					TableRow.QuantityByGBRN = TableRow[FillParameters.FieldNameNumberOfPackages];
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Fills in the CCD numbers in the rows of the tabular part of the object according to the latest receipts.
//
// Parameters:
//	Goods - FormDataCollection - the tabular part of the object in which information about
//									CCD numbers is filled in.
//	CCDNumbersFilledIn - Boolean - indicates that the table part has been filled in.
//	FillParameters - See ParametersForFillingInGTDVNumberOfTabularPart
//
Procedure FillIn_CCDNumbersForLatestReceipts(Goods,
													CCDNumbersFilledIn,
													FillParameters = Undefined) Export
	
	If FillParameters = Undefined Then
		FillParameters = ParametersForFillingInGTDVNumberOfTabularPart();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SourceTable.LineNumber		AS LineNumber,
	|	SourceTable.Products	AS Products
	|INTO GoodsTable
	|FROM
	|	&SourceTable AS SourceTable
	|WHERE
	|	SourceTable.TheRecordsAreKeptByCCD
	|	AND SourceTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND SourceTable.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|										VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData.Products					AS Products,
	|	MAX(RegisterData.DateOfReceipt)	AS DateOfReceipt
	|INTO DatesOfCompanyGoodsReceipt
	|FROM
	|	InformationRegister.DatesOfCompanyGoodsReceipt AS RegisterData
	|WHERE
	|	RegisterData.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|
	|GROUP BY
	|	RegisterData.Products
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber			AS LineNumber,
	|	GoodsTable.Products			AS Products,
	|	MAX(RegisterData.CCDNumber)	AS CCDNumber
	|INTO CCDNumbersOfGoods
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN DatesOfCompanyGoodsReceipt AS DatesOfCompanyGoodsReceipt
	|		ON GoodsTable.Products = DatesOfCompanyGoodsReceipt.Products
	|		
	|		INNER JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS RegisterData
	|		ON GoodsTable.Products = RegisterData.Products
	|			AND RegisterData.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|			AND DatesOfCompanyGoodsReceipt.DateOfReceipt = RegisterData.DateOfReceipt
	|
	|GROUP BY
	|	GoodsTable.LineNumber,
	|	GoodsTable.Products
	|;
	|
	|////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber		AS LineNumber,
	|	GoodsTable.Products		AS Products,
	|	GoodsTable.CCDNumber			AS CCDNumber,
	|	CCDNumbers.CCDNumberType			AS CCDNumberType,
	|	CCDNumbers.OriginCountry	AS OriginCountry
	|
	|FROM
	|	CCDNumbersOfGoods AS GoodsTable
	|		LEFT JOIN Catalog.CCDNumbers AS CCDNumbers
	|		ON GoodsTable.CCDNumber = CCDNumbers.Ref";
	
	UnloadedColumns = "LineNumber, Products, CCDNumber, ItemsType, TheRecordsAreKeptByCCD";
	
	Query.SetParameter("SourceTable", Goods.Unload(, UnloadedColumns));
	
	Selection = Query.Execute().Select();
	
	CCDNumbersFilledIn = Selection.Count() > 0;
	
	While Selection.Next() Do
		TableRow = Goods.Get(Selection.LineNumber - 1);
		FillPropertyValues(TableRow, Selection, ,"LineNumber");
		
		If FillParameters.RecalculateQuantityByRNPT Then
			If TableRow.CCDNumberType = Enums.CCDNumberTypes.KitRNPT Then
				TableRow.QuantityByGBRN = TableRow[FillParameters.FieldNameNumberOfPackages];
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Returns the parameters used when filling in the tabular part of the object with CCD numbers based on credentials.
//
// Returns:
//	Structure - contains the following properties:
//	* QueryOptions - Structure - a collection of request parameters for CCD Balances containing the following fields:
//		** Ref - DocumentRef - a link to the document in which the CCD numbers are filled in (required to be filled
//										in with the option of obtaining data 'by location').
//		** Period - Date, Boundary - the period for which information is received about the Balances of CCD numbers (required
//									to be filled in with the option of obtaining the data 'Postage transmitted to the Commission'
//									and 'Postage of the collector').
//		** Organization - CatalogRef.Companies, Undefined - the organization that receives information
//																		about the Balances of CCD numbers (required
//																		to be filled in with the data acquisition option
//																		'Postatka of the Treasurer').
//		** Partner - CatalogRef.Partners, Undefined - the partner for whom information about the Balances
//																of CCD numbers is received (it is mandatory to fill in the option
//																of receiving data 'by sending it to the Commission').
//		** Contract - CatalogRef.CounterpartyContracts, Undefined - the Contract under which information about
//																			the Balances of CCD numbers is obtained (required
//																			to be filled in with the option of obtaining data
//																			'Postatka of the Treasurer').
//	* NameOfOrderField - String - the name of the field of the order by which information about the CCD numbers is obtained.
//	* ActionsWithString - Structure, Undefined - actions for processing rows in the table part.
//
Function ParametersForFillingInCCDNumbersBasedOnCredentials() Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert("Ref");
	QueryOptions.Insert("Period", Date(1, 1, 1));
	QueryOptions.Insert("Organization");
	QueryOptions.Insert("Partner");
	QueryOptions.Insert("Contract");
	
	FillParameters = New Structure;
	FillParameters.Insert("QueryOptions", QueryOptions);
	FillParameters.Insert("NameOfOrderField", "");
	FillParameters.Insert("ActionsWithString", Undefined);
	
	Return FillParameters;
	
EndFunction

// Fills in the GTD numbers in the table part of the object.
//
// Parameters:
//	TableOfGoods - FormDataCollection, TabularSection - the table in which the CCD numbers are filled in, containing
//															the following columns:
//		* NameOfOrderField - DocumentRef - a column with an arbitrary name containing a link to the order
//													(it is mandatory for the option of getting data 'by Location').
//		* Products - CatalogRef.Products - Product information.
//		* Characteristic - CatalogRef.ItemsCharacteristics - information about the characteristics of the Product.
//		* Purpose - CatalogRef.Assignments - information about the purpose of the product.
//		* Series - CatalogRef.ItemsBatches - information about the series of Products.
//		* CCDNumber - CatalogRef.CCDNumbers - information about the CCD number.
//		* Count - Number - amount of goods.
//	DataAcquisitionOption - String - the option of obtaining data on the numbers of GTE.
//	AdditionalParameters - See ParametersForFillingInCCDNumbersBasedOnCredentials
//
Procedure FillInCCDNumbersAccordingToCredentials(TableOfGoods, DataAcquisitionOption, AdditionalParameters) Export
	
	NameOfOrderField	= AdditionalParameters.NameOfOrderField;
	ActionsWithString	= AdditionalParameters.ActionsWithString;
	
	QueryText = TextOfRequestForFormationOfTableOfCCDNumbers(DataAcquisitionOption);
	QueryText = StrReplace(QueryText, "NameOfOrderField", NameOfOrderField);
	
	DefaultCCDNumber = Catalogs.CCDNumbers.EmptyRef();
	
	ProductsToFillIn_ = TableOfGoods.Unload();
	ProductsToFillIn_.FillValues(DefaultCCDNumber, "CCDNumber");
	GoodsAmountToBeFilledIn = TableOfGoods.Unload();
	
	FillNumberOfPackages		= ProductsToFillIn_.Columns.Find("NumberOfPackages") <> Undefined;
	FillInCCDNumberType			= ProductsToFillIn_.Columns.Find("CCDNumberType") <> Undefined;
	FillInCountryOfOrigin_	= ProductsToFillIn_.Columns.Find("OriginCountry") <> Undefined;
	
	If FillInCCDNumberType Then
		DefaultCCDNumberType = Enums.CCDNumberTypes.EmptyRef();
		ProductsToFillIn_.FillValues(DefaultCCDNumberType, "CCDNumberType");
	EndIf;
	
	If FillInCountryOfOrigin_ Then
		DefaultCountryOfOrigin = Catalogs.WorldCountries.EmptyRef();
		ProductsToFillIn_.FillValues(DefaultCountryOfOrigin, "OriginCountry");
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	QueryOptions = Query.FindParameters();
	
	For Each QueryParameter In AdditionalParameters.QueryOptions Do
		If QueryOptions.Find(QueryParameter.Key) <> Undefined Then
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		EndIf;
	EndDo;
	
	Query.SetParameter("GoodsTable", ProductsToFillIn_);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	GTDCNumbersToFillIn = QueryResult.Unload();
	
	SearchFields = "Products, Characteristic, Series, Purpose, CCDNumber";
	
	If ValueIsFilled(NameOfOrderField) Then
		SearchFields = SearchFields + ", " + NameOfOrderField;
	EndIf;
	
	RecalculationOfAmount = False;
	RecalculationOfVATAmount = False;
	RecalculationOfAmountWithVAT = False;
	
	If ActionsWithString <> Undefined Then
		If ActionsWithString.Property("RecalculateAmount") Then
			RecalculationOfAmount = True;
		EndIf;
		If ActionsWithString.Property("RecalculateVATAmount") Then
			RecalculationOfVATAmount = True;
		EndIf;
		If ActionsWithString.Property("RecalculateAmountWithVAT") Then
			RecalculationOfAmountWithVAT = True;
		EndIf;
	EndIf;
	
	AdditionalData = New Structure();
	AdditionalData.Insert("ActionsWithString", ActionsWithString);
	AdditionalData.Insert("FillInCCDNumberType", FillInCCDNumberType);
	AdditionalData.Insert("FillNumberOfPackages", FillNumberOfPackages);
	AdditionalData.Insert("FillInCountryOfOrigin_", FillInCountryOfOrigin_);
	AdditionalData.Insert("ExcludeWarehouseSeriesFromSearch", (DataAcquisitionOption = "ByBalanceOnWay"));
	
	ThereArePrices = GTDCNumbersToFillIn.Columns.Find("Price") <> Undefined
		And GTDCNumbersToFillIn.Total("Price") > 0;
	
	If ThereArePrices Then
		// Search for lines with a matching price.
		SearchFieldsWithPrice = SearchFields + ", Price";
		AdditionalData.Insert("SearchFields", SearchFieldsWithPrice);
		FillInCCDNumbersAccordingToCredentialsInternal(ProductsToFillIn_,
			GTDCNumbersToFillIn, AdditionalData);
	EndIf;
	
	// Additional distribution on the remaining lines, excluding the price.
	AdditionalData.Insert("SearchFields", SearchFields);
	FillInCCDNumbersAccordingToCredentialsInternal(ProductsToFillIn_,
		GTDCNumbersToFillIn, AdditionalData);
	
	// Due to incorrect rounding, additional amount control is required when allocating CCD numbers.
	
	SearchFieldsUpTo = "Products, Characteristic, Series, Purpose";
	SearchStructureBefore = New Structure(SearchFieldsUpTo);
	
	SummationFields = "Count";
	SummationFields = ?(RecalculationOfAmount, SummationFields + ", Sum", SummationFields);
	SummationFields = ?(RecalculationOfVATAmount, SummationFields + ", VATAmount", SummationFields);
	SummationFields = ?(RecalculationOfAmountWithVAT, SummationFields + ", AmountIncludingVAT", SummationFields);
	
	GoodsAmountToBeFilledIn.GroupBy(SearchFieldsUpTo, SummationFields); 
	
	ItemsToBeFilledInAmountsWithoutCCD = ProductsToFillIn_.Copy();
	ItemsToBeFilledInAmountsWithoutCCD.Columns.Add("IsVerificationRequired", New TypeDescription("Boolean"));
	For Each String In ItemsToBeFilledInAmountsWithoutCCD Do
		String.IsVerificationRequired = ValueIsFilled(String.CCDNumber);
	EndDo;
	
	ItemsToBeFilledInAmountsWithoutCCD.GroupBy(SearchFieldsUpTo, SummationFields + ", IsVerificationRequired");
	
	For Each LineOfGoodsBefore In GoodsAmountToBeFilledIn Do
		
		FillPropertyValues(SearchStructureBefore, LineOfGoodsBefore);
		
		// Checking the correctness of the amounts.
		
		DistributedItemAmounts = ItemsToBeFilledInAmountsWithoutCCD.FindRows(SearchStructureBefore);
		If DistributedItemAmounts.Count() = 0 Then
			Continue;
		EndIf;
		
		AmountsForDistributedItem = DistributedItemAmounts[0];
		
		If Not AmountsForDistributedItem.IsVerificationRequired Then
			Continue;
		EndIf;
		
		// If the amount was unknown before the distribution, then there is no control value. It is impossible to carry out control.
		// This is a manual return entry scenario (not based on a document) when the user has not filled in the price.
		If RecalculationOfAmount
			And LineOfGoodsBefore.Sum = 0 Then
			Continue;
		EndIf;
		
		ThereIsDifferenceInAmounts = False;
		If RecalculationOfAmount
			And AmountsForDistributedItem.Sum <> LineOfGoodsBefore.Sum Then
			ThereIsDifferenceInAmounts = True;
		EndIf;
		If RecalculationOfAmountWithVAT
			And AmountsForDistributedItem.AmountIncludingVAT <> LineOfGoodsBefore.AmountIncludingVAT Then
			ThereIsDifferenceInAmounts = True;
		EndIf;
		If RecalculationOfVATAmount
			And AmountsForDistributedItem.VATAmount <> LineOfGoodsBefore.VATAmount Then
			ThereIsDifferenceInAmounts = True;
		EndIf;
		
		If Not ThereIsDifferenceInAmounts Then
			Continue;
		EndIf;
		
		// Control failed, you need to correct the amounts.
		// It is assumed that the deviation is units of kopecks.
		// The discrepancy is reflected in the last line.
		
		ProductLines_2 = ProductsToFillIn_.FindRows(SearchStructureBefore);
		LastRowIndex = ProductLines_2.Count() - 1;
		LineToMakeAdjustments = ProductLines_2[LastRowIndex];
		
		If RecalculationOfAmount Then
			Adjusting = AmountsForDistributedItem.Sum - LineOfGoodsBefore.Sum;
			LineToMakeAdjustments.Sum = LineToMakeAdjustments.Sum - Adjusting;
		EndIf;
		If RecalculationOfVATAmount Then
			Adjusting = AmountsForDistributedItem.VATAmount - LineOfGoodsBefore.VATAmount;
			LineToMakeAdjustments.VATAmount = LineToMakeAdjustments.VATAmount - Adjusting;
		EndIf;
		If RecalculationOfAmountWithVAT Then
			Adjusting = AmountsForDistributedItem.AmountIncludingVAT - LineOfGoodsBefore.AmountIncludingVAT;
			LineToMakeAdjustments.AmountIncludingVAT = LineToMakeAdjustments.AmountIncludingVAT - Adjusting;
		EndIf;
		
	EndDo;
	
	TableOfGoods.Load(ProductsToFillIn_);
	
EndProcedure

// Returns the parameters used when selecting the CCD number in the tabular part of the object.
//
// Returns:
//	Structure - parameters used when selecting the CCD number in the tabular part of the object, with the following properties:
//		* SourceOfTS - String - the path to the table part. If the value is not specified, then the table part is
//								the Attribute of the client application form. The default value is 'Object'.
//		* TSName - String - the name of the tabular part in which the CCD number is selected.
//		* FormTableName - String - Name of the form table.
//		* NameOfProductsField - String - The name of the column in the tabular part that contains information about the Product for which
//											the CCD number is being filled in.
//		* NameOfItemTypeField - String - The name of the column in the tabular part that contains information about the type of item
//											for which the CCD number is being filled in.
//		* FieldNameNumberOfPackages - String - the name of the column of the tabular part containing information about the number of packages
//												of the Product for which the CCD number is filled in.
//		* RecalculateQuantityByRNPT - Boolean - a sign of the need to recalculate the quantity according to the RNPT in the rows of the tabular
//													part, filled in with CCD numbers.
//
Function CCDNumberSelectionParameters() Export
	
	PickingParameters = New Structure;
	PickingParameters.Insert("SourceOfTS",						"Object");
	PickingParameters.Insert("TSName",							"Goods");
	PickingParameters.Insert("FormTableName",				"Goods");
	PickingParameters.Insert("NameOfProductsField",			"Products");
	PickingParameters.Insert("NameOfItemTypeField",			"ItemsType");
	PickingParameters.Insert("FieldNameNumberOfPackages",		"NumberOfPackages");
	PickingParameters.Insert("RecalculateQuantityByRNPT",	True);
	
	Return PickingParameters;
	
EndFunction

// Fills in the result of the selection of CCD numbers in the tabular part of the object.
//
// Parameters:
//	Form - ClientApplicationForm - the form in which the selection is carried out.
//	RowID -  Number - ID of the row for which the values are being selected.
//	SelectionData_1 - Structure - a collection containing the following information:
//					* CCDNumberType - EnumRef.CCDNumberTypes - the type of the main CCD number received during the selection.
//					* MainNumberOfCCD - CatalogRef.CCDNumbers - the main CCD number received during the selection process.
//					* ResidualNumberOfCCD - CatalogRef.CCDNumbers - the main RNPT number of the kit received during
//																		selection.
//	CCDNumbersFilledIn - Boolean - indicates that the table part has been filled in.
//	PickingParameters - See CCDNumberSelectionParameters
//	StringProcessingActions - Structure, Undefined - a collection containing parameters for processing rows in the table part.
//
Procedure ProcessIndicationOfCCDNumber(Form,
										RowID,
										SelectionData_1,
										CCDNumbersFilledIn,
										PickingParameters = Undefined,
										StringProcessingActions = Undefined) Export
	
	If PickingParameters = Undefined Then
		PickingParameters = CCDNumberSelectionParameters();
	EndIf;
	
	If Not IsBlankString(PickingParameters.SourceOfTS) Then
		Goods = Form[PickingParameters.SourceOfTS][PickingParameters.TSName];
	Else
		Goods = Form[PickingParameters.TSName];
	EndIf;
	
	CurrentRow = Goods.FindByID(RowID);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = True;
	
	CurrentRow.CCDNumber = SelectionData_1.MainNumberOfCCD;
	
	AttributesNames = "CCDNumberType, OriginCountry";
	AttributesOfCCD	= Common.ObjectAttributesValues(CurrentRow.CCDNumber, AttributesNames);
	
	FillPropertyValues(CurrentRow, AttributesOfCCD);
	
	StringProcessingIsRequired = StringProcessingActions <> Undefined
								And StringProcessingActions.Count() > 0;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		NewRow = Goods.Insert(Goods.IndexOf(CurrentRow) + 1);
		FillPropertyValues(NewRow, CurrentRow);
		
		NewRow.CCDNumber = SelectionData_1.ResidualNumberOfCCD;
		
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesWhenSelectingCCDNumber(
			CurrentRow,
			NewRow,
			PickingParameters.FieldNameNumberOfPackages);
		
		If StringProcessingIsRequired Then
			BatchProcessingOfTablePartServer.ProcessTSString(NewRow, StringProcessingActions, Undefined);
		EndIf;
		
		FormTable = Form.Items[PickingParameters.FormTableName]; // FormTable -
		FormTable.CurrentRow = NewRow.GetID();
	EndIf;
	
	If StringProcessingIsRequired Then
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StringProcessingActions, Undefined);
	EndIf;
	
EndProcedure

// Returns the parameters used when filling in the service Attributes of the CCD number in the tabular part of the object.
//
// Returns:
//	Structure - parameters used when selecting the CCD number in the tabular part of the object, with the following properties:
//		* NameOfProductsField - String - The name of the column in the tabular part that contains information about the Product for which
//											the CCD number is being filled in.
//		* FillInCountryOfOrigin - Boolean - indicates whether there is a country of origin in the tabular part of the column
//													that needs to be filled in.
//
Function ParametersForFillingInServiceAttributesOfCCDNumber() Export
	
	PickingParameters = New Structure;
	PickingParameters.Insert("NameOfProductsField", "Products");
	PickingParameters.Insert("FillInCountryOfOrigin", True);
	
	Return PickingParameters;
	
EndFunction

// The procedure fills in the service Attributes of the CCD numbers in the tabular part.
//
// Parameters:
//	Goods - FormDataCollection - the tabular part in which the service Attributes are filled in.
//	FillParameters - See ParametersForFillingInServiceAttributesOfCCDNumber
//
Procedure FillInServiceAttributesOfCCDNumber(Goods, FillParameters = Undefined) Export
	
	If Not GetFunctionalOption("UseImportedGoods") Then
		Return;
	EndIf;
	
	If Goods.Count() = 0 Then
		Return;
	EndIf;
	
	If FillParameters = Undefined Then
		FillParameters = ParametersForFillingInServiceAttributesOfCCDNumber()
	EndIf;
	
	NameOfProductsField = FillParameters.NameOfProductsField;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CAST(Goods.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(&NameOfProductsField AS Catalog.Products) AS Products,
	|	CAST(Goods.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber,
	|	&OriginCountry AS OriginCountry
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN NOT Goods.OriginCountry IN(UNDEFINED,
	|												VALUE(Catalog.WorldCountries.EmptyRef))
	|			THEN Goods.OriginCountry
	|		WHEN NOT Goods.CCDNumber IN(UNDEFINED,
	|									VALUE(Catalog.CCDNumbers.EmptyRef))
	|			THEN Goods.CCDNumber.OriginCountry
	|		WHEN NOT Goods.Products IN(UNDEFINED,
	|										VALUE(Catalog.Products.EmptyRef))
	|			THEN Goods.Products.OriginCountry
	|		ELSE VALUE(Catalog.WorldCountries.EmptyRef)
	|	END AS OriginCountry,
	|	ISNULL(CCDNumbers.CCDNumberType, VALUE(Enum.CCDNumberTypes.EmptyRef)) AS CCDNumberType
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON Goods.Products = ProductData_1.Ref
	|		
	|		LEFT JOIN Catalog.CCDNumbers AS CCDNumbers
	|		ON Goods.CCDNumber = CCDNumbers.Ref
	|WHERE
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE)
	|	AND (NOT &SelectionByCountryOfOrigin
	|			OR (Goods.OriginCountry IN(UNDEFINED,
	|												VALUE(Catalog.WorldCountries.EmptyRef))
	|				AND (NOT Goods.CCDNumber IN(UNDEFINED,
	|										VALUE(Catalog.CCDNumbers.EmptyRef))
	|					OR NOT Goods.Products IN(UNDEFINED,
	|													VALUE(Catalog.CCDNumbers.EmptyRef)))))
	|		OR NOT Goods.CCDNumber IN(UNDEFINED,
	|									VALUE(Catalog.CCDNumbers.EmptyRef))
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = StrReplace(Query.Text,
								"&NameOfProductsField",
								"Goods." + NameOfProductsField);
	
	ColumnsNames = New Array;
	ColumnsNames.Add("LineNumber");
	ColumnsNames.Add(NameOfProductsField);
	ColumnsNames.Add("CCDNumber");
	
	If FillParameters.FillInCountryOfOrigin Then
		ColumnsNames.Add("OriginCountry");
		
		Query.Text = StrReplace(Query.Text,
									"&OriginCountry",
									"CAST(Goods.OriginCountry AS Catalog.WorldCountries)");
	Else
		Query.Text = StrReplace(Query.Text,
									"&OriginCountry",
									"VALUE(Catalog.WorldCountries.EmptyRef)");
	EndIf;
	
	UnloadedColumns = StrConcat(ColumnsNames, ",");
	
	Query.SetParameter("Goods", Goods.Unload(, UnloadedColumns));
	Query.SetParameter("SelectionByCountryOfOrigin", FillParameters.FillInCountryOfOrigin);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		FillPropertyValues(Goods[Selection.LineNumber - 1], Selection, , "LineNumber");
	EndDo;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the country of origin by CCD number
// when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextOfCountryOfOriginByCCDNumber(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInCountryOfOriginForCCDNumber",
		StructureOfActions,
		CachedValues,
		Parameters) Then
	
		QueryText = "
			|SELECT ALLOWED
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	ISNULL(CCDNumbers.OriginCountry, VALUE(Catalog.WorldCountries.EmptyRef)) AS OriginCountry
			|FROM
			|	TTDataSource AS DataSource
			|	LEFT JOIN Catalog.CCDNumbers AS CCDNumbers
			|		ON CCDNumbers.Ref = &CCDNumberFillingInCountry";
		
		If Parameters = Undefined Then
			QueryText = StrReplace(QueryText, "&CCDNumberFillingInCountry", "DataSource.CCDNumber");
		Else
			QueryDetails.QueryOptions.Insert("CCDNumberFillingInCountry", Parameters.CCDNumber);
		EndIf;
		
		QueryDetails.QueriesTexts.Add(QueryText, "CountryOfOriginByCCDNumber");
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the CCD number type when 
// processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextToCCDNumberType(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInCCDNumberType",
		StructureOfActions,
		CachedValues,
		Parameters) Then
	
		QueryText = "
			|SELECT ALLOWED
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	CCDNumbers.CCDNumberType AS CCDNumberType
			|FROM
			|	TTDataSource AS DataSource
			|	LEFT JOIN Catalog.CCDNumbers AS CCDNumbers
			|		ON CCDNumbers.Ref = &CCDNumberIsDefinitionOfType";
		
		QueryDetails.QueriesTexts.Add(QueryText, "CCDNumberType");
		QueryDetails.QueryOptions.Insert("CCDNumberIsDefinitionOfType", Parameters.CCDNumber);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region AssemblyDisassemblyOfCompositeCCD

// Checks whether the transmitted table contains the traceable CCD number (RNPT).
// 
// Parameters:
//  Goods - ValueTable - :
//   * CCDNumber - CatalogRef.CCDNumbers -
// 
// Returns:
//  Structure:
//   * NumberOfSimpleCCDNumbers - Number -
//   * NumberOfTraceableCCDNumbers - Number -
//   * NumberOfCompositeCCDNumbers - Number -
//   * ThereIsSimpleCCDNumber - Boolean -
//   * ThereIsTraceableCCDNumber - Boolean -
//   * ThereIsCompositeCCDNumber - Boolean -
Function TypesOfGTDRoomsInTable(Goods) Export
	
	ReturnValue = New Structure();
	ReturnValue.Insert("NumberOfSimpleCCDNumbers", 0);
	ReturnValue.Insert("NumberOfTraceableCCDNumbers", 0);
	ReturnValue.Insert("NumberOfCompositeCCDNumbers", 0);
	ReturnValue.Insert("ThereIsSimpleCCDNumber", False);
	ReturnValue.Insert("ThereIsTraceableCCDNumber", False);
	ReturnValue.Insert("ThereIsCompositeCCDNumber", False);
	
	Query = New Query();
	Query.Text = 
	"SELECT DISTINCT
	|	CAST(Goods.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(CASE
	|		WHEN Goods.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.CCDNumber)
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfSimpleCCDNumbers,
	|	SUM(CASE
	|		WHEN Goods.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfTraceableCCDNumbers,
	|	SUM(CASE
	|		WHEN Goods.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT)
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfCompositeCCDNumbers
	|INTO TTCountingTypesOfCCD
	|FROM
	|	TTProducts_1 AS Goods
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.NumberOfSimpleCCDNumbers AS NumberOfSimpleCCDNumbers,
	|	Goods.NumberOfTraceableCCDNumbers AS NumberOfTraceableCCDNumbers,
	|	Goods.NumberOfCompositeCCDNumbers AS NumberOfCompositeCCDNumbers,
	|	Goods.NumberOfSimpleCCDNumbers > 0 AS ThereIsSimpleCCDNumber,
	|	Goods.NumberOfTraceableCCDNumbers > 0 AS ThereIsTraceableCCDNumber,
	|	Goods.NumberOfCompositeCCDNumbers > 0 AS ThereIsCompositeCCDNumber
	|FROM
	|	TTCountingTypesOfCCD AS Goods";
	
	Query.SetParameter("Goods", Goods);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(ReturnValue, Selection);
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Extract a field from a table.
// 
// Parameters:
//  Table - ValueTable - must contain a column whose name is passed in the column parameter for the output.
//  ColumnForExtraction - String - A column that stores an object from which you can extract a field.
//  ExtractedField - String - The name of the field to be extracted from the column for extraction.
//  NameOfNewColumn - String - The name of the column to be added to the incoming table. The extracted values will be loaded into it.
//  DescriptionOfNewColumnTypes - TypeDescription - Type of new column.
//
Procedure ExtractFieldFromTableColumn(Table,
	ColumnForExtraction,
	ExtractedField,
	NameOfNewColumn = "",
	DescriptionOfNewColumnTypes = Undefined) Export
	
	If IsBlankString(NameOfNewColumn) Then
		NameOfNewColumn = ExtractedField;
	EndIf;
	If DescriptionOfNewColumnTypes <> Undefined Then
		Table.Columns.Add(NameOfNewColumn, DescriptionOfNewColumnTypes);
	Else
		Table.Columns.Add(NameOfNewColumn);
	EndIf;
	
	NomenclatureAnalysts = Table.UnloadColumn(ColumnForExtraction);
	NomenclatureItems = Common.ObjectsAttributeValue(NomenclatureAnalysts, ExtractedField);
	
	For Each KeyValue In NomenclatureItems Do
		Filter = New Structure(ColumnForExtraction, KeyValue.Key);
		FoundRows = Table.FindRows(Filter);
		For Each String In FoundRows Do
			String[NameOfNewColumn] = KeyValue.Value;
		EndDo;
	EndDo;
	
EndProcedure

// Returns the default parameters used when searching for or creating items in the 'GTD Number' Catalog
// type number of the RNPT kit.
//
// Returns:
//	Structure - a collection that contains the following properties:
//		* ExtractProductFromObjectInColumn - String - the name of the column that contains information about the item,
//															if not specified explicitly.
//		* ExtractCharacteristicFromObjectInColumn - String - the name of the column that contains information about the item's characteristics,
//															if not explicitly specified.
//		* ExtractBatchFromObjectInColumn - String - the name of the column that contains information about the item series,
//															unless explicitly specified.
//		* ItemOfHeader - CatalogRef.Products, Undefined - The item of the kit.
//		* CharacteristicsOfCap - CatalogRef.ItemsCharacteristics, Undefined - characteristics of the kit.
//		* CapsBatch - CatalogRef.ItemsBatches, Undefined - the batch of the kit.
//		* AmountByProductBatchID - Number - the cost of the composite set, if the price for it is not known. Used in EDO.
//		* AlwaysUseAmountByProductBatchIDForCostOfKit - Boolean - ignore the selection of prices, take the transferred prices.
//			It is used when entering the ProductBatchID number manually, and when exchanging data.
//		* NormalizeAmountAccordingToProductBatchIDWhenCreatingCompositeSet - Boolean - divide the sum values by the number of sets.
//			Used for data exchange.
//		* ExpandCCDNumberSearchKeyWithProductBatchIDAmount - Boolean - adds the cost of ProductBatchID to the Catalog search key for the CCD number
//			when loading the UPD from the EDI.
//
Function ParametersForSearchingOrCreatingCompositeTraceableSets() Export
	
	CreationParameters = New Structure;
	CreationParameters.Insert("ExtractProductFromObjectInColumn", "");
	CreationParameters.Insert("ExtractCharacteristicFromObjectInColumn", "");
	CreationParameters.Insert("ExtractBatchFromObjectInColumn", "");
	CreationParameters.Insert("ItemOfHeader", Undefined);
	CreationParameters.Insert("CharacteristicsOfCap", Undefined);
	CreationParameters.Insert("CapsBatch", Undefined);
	CreationParameters.Insert("AmountByProductBatchID", 0);
	CreationParameters.Insert("AlwaysUseAmountByProductBatchIDForCostOfKit", False);
	CreationParameters.Insert("NormalizeAmountAccordingToProductBatchIDWhenCreatingCompositeSet", False);
	CreationParameters.Insert("ExpandCCDNumberSearchKeyWithProductBatchIDAmount", False);
	
	Return CreationParameters;
	
EndFunction

// Find or create composite traceable CCD numbers from 2 or more traceable products.
// There are 2 main ways to use the method - with the transfer of Product, and without.
// In this case, the Product can be passed either explicitly or extracted from some object (for example, from
// Product Accounting Analytics).
// If you completely refuse to transfer the Product list, you should explicitly transfer the unit of measurement of the Customs Code of Foreign Economic activity.
// 
// Parameters:
//  Goods - ValueTable - Traceable CCD Numbers, from which you need to create a composite CCD number:
//   * Products - CatalogRef.Products, Undefined - It is transmitted to control the traceability of the goods.
//     It is possible to leave the field unfilled, then it will be considered that the line is traced.
//     It is possible not to pass this column, but to pass the column through the type of which it will be possible
//     to extract the item (see Extract nomenclature from the Column object).
//   * Characteristic - CatalogRef.ItemsCharacteristics, Undefined - It is transmitted to control the traceability of the goods.
//   * Series - CatalogRef.ItemsBatches, Undefined - It is transmitted to control the traceability of the goods.
//   * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure, Undefined - The unit of measurement of HS.
//     If not specified explicitly, it is retrieved via the Product list.
//   * QuantityByGBRN - Number - 
//   * CCDNumber - CatalogRef.CCDNumbers -  
//  KitCount - Number - Set Quantity
//  DateOfTraceabilityControl - Date - Date Of Traceability Control
//  Cancel - Boolean - True, indicates that the 'TDC Number' Catalog item could not be found or created
//  				type number of the RNPT kit.
//  CreationParameters - See ParametersForSearchingOrCreatingCompositeTraceableSets.
// 
// Returns:
//  Structure:
//   * ThereAreCompositeTraceableCCDNumbers - Boolean - indicates that it was possible to find or create composite CCD numbers.
//   * MainCompositeNumberOfCCD - CatalogRef.CCDNumbers, Undefined -
//   * ResidualCompositeNumberOfCCD - CatalogRef.CCDNumbers, Undefined -
//
Function FindOrCreateCompositeTraceableCCDNumbers(Goods,
	KitCount,
	DateOfTraceabilityControl,
	Cancel = False,
	CreationParameters = Undefined) Export
	
	If CreationParameters = Undefined Then
		CreationParameters = ParametersForSearchingOrCreatingCompositeTraceableSets();
	EndIf;
	
	If Not IsBlankString(CreationParameters.ExtractProductFromObjectInColumn) Then
		ExtractFieldFromTableColumn(Goods,
									CreationParameters.ExtractProductFromObjectInColumn,
									"Products",
									"Products",
									New TypeDescription("CatalogRef.Products"));
	EndIf;
	
	If Not IsBlankString(CreationParameters.ExtractCharacteristicFromObjectInColumn) Then
		ExtractFieldFromTableColumn(Goods,
									CreationParameters.ExtractCharacteristicFromObjectInColumn,
									"Characteristic",
									"Characteristic",
									New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	If Goods.Columns.Find("Characteristic") = Undefined Then
		Goods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	
	If Not IsBlankString(CreationParameters.ExtractBatchFromObjectInColumn) Then
		ExtractFieldFromTableColumn(Goods,
									CreationParameters.ExtractBatchFromObjectInColumn,
									"Series",
									"Series",
									New TypeDescription("CatalogRef.ItemsBatches"));
	EndIf;
	If Goods.Columns.Find("Series") = Undefined Then
		Goods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	EndIf;
	
	If Goods.Columns.Find("UnitOfMeasure") = Undefined Then
		Goods.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	EndIf;
	
	ReturnValue = New Structure();
	ReturnValue.Insert("ThereAreCompositeTraceableCCDNumbers", False);
	ReturnValue.Insert("MainCompositeNumberOfCCD", Undefined);
	ReturnValue.Insert("ResidualCompositeNumberOfCCD", Undefined);
	
	Query = New Query();
	Query.Text =
	// 0.
	"SELECT
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	CAST(Goods.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(Goods.Series AS Catalog.ItemsBatches) AS Series,
	|	CAST(Goods.UnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure) AS UnitOfMeasure,
	|	Goods.QuantityByGBRN,
	|	&GoodsAmountAccordingToProductBatchID AS AmountByProductBatchID,
	|	CAST(Goods.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 1.
	|SELECT
	|	ISNULL(MAX(Goods.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)),FALSE) AS GenerationOfCompositeCCDIsRequired,
	|	ISNULL(MAX(Goods.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT)),FALSE) AS HasError
	|FROM
	|	TTProducts_1 AS Goods
	|
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND BEGINOFPERIOD(&Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|	AND (Goods.Products = VALUE(Catalog.Products.EmptyRef)
	|		OR Goods.Products.TracedGoods)
	|	AND Goods.CCDNumber.CCDNumberType IN (
	|		VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber),
	|		VALUE(Enum.CCDNumberTypes.KitRNPT)
	|		)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 2.
	// Selection of lines that contain errors.
	|SELECT
	|	Goods.CCDNumber,
	|	Goods.Products,
	|	TRUE AS ThisIsCompositeCCD
	|FROM
	|	TTProducts_1 AS Goods
	|
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND BEGINOFPERIOD(&Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|	AND (Goods.Products = VALUE(Catalog.Products.EmptyRef)
	|		OR Goods.Products.TracedGoods)
	// RPT of the incorrect type.
	|	AND Goods.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT)
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 3.
	|SELECT
	|	SUM(Goods.QuantityByGBRN),
	|	SUM(Goods.AmountByProductBatchID),
	|	Goods.CCDNumber,
	|	CASE
	|		WHEN Goods.CCDNumber.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.CCDNumber.UnitOfMeasure
	|		WHEN Goods.Products.FEACNUnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.Products.FEACNUnitOfMeasure
	|		WHEN Goods.Products.FEACNCode.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.Products.FEACNCode.UnitOfMeasure
	|		WHEN Goods.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.UnitOfMeasure
	|		ELSE Goods.Products.UnitOfMeasure
	|	END AS FEACNUnitOfMeasure,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series
	|INTO TTTraceableProducts
	|FROM
	|	TTProducts_1 AS Goods
	|
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND BEGINOFPERIOD(&Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|	AND (Goods.Products = VALUE(Catalog.Products.EmptyRef)
	|		OR Goods.Products.TracedGoods)
	|	AND Goods.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|
	|GROUP BY
	|	Goods.CCDNumber,
	|	CASE
	|		WHEN Goods.CCDNumber.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.CCDNumber.UnitOfMeasure
	|		WHEN Goods.Products.FEACNUnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.Products.FEACNUnitOfMeasure
	|		WHEN Goods.Products.FEACNCode.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.Products.FEACNCode.UnitOfMeasure
	|		WHEN Goods.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.UnitOfMeasure
	|		ELSE Goods.Products.UnitOfMeasure
	|	END,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 4.
	// The main set of components for the composite number of the CCD (kit).
	|SELECT
	|	TRUE AS ThisIsBasicKit,
	|	CompositeNumber.CCDNumber AS ProductBatchIDNumber,
	|	CAST(
	|		CAST(CompositeNumber.QuantityByGBRN AS NUMBER(23, 11)) / CAST(&KitCount AS NUMBER(23, 11))
	|	AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	CompositeNumber.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	CompositeNumber.Products AS Products,
	|	CompositeNumber.Characteristic AS Characteristic,
	|	CompositeNumber.Series AS Series,
	|	CAST(CompositeNumber.AmountByProductBatchID / &NumberOfSetsForRationingAmount AS NUMBER(31, 2)) AS AmountByProductBatchID
	|INTO TTCompositeNumberSource
	|FROM
	|	TTTraceableProducts AS CompositeNumber
	|
	|UNION ALL
	|
	// The residual set of components for the composite number of the CCD (kit).
	|SELECT
	|	FALSE AS ThisIsBasicKit,
	|	CompositeNumber.CCDNumber AS ProductBatchIDNumber,
	// Normalized quantity + Balance (Where Balance = Original quantity - Restored quantity)
	|	CAST(
	|		CAST(CompositeNumber.QuantityByGBRN AS NUMBER(23, 11)) / CAST(&KitCount AS NUMBER(23, 11))
	|	AS NUMBER(23, 11))
	|	
	|		+ CAST(
	|				CAST(CompositeNumber.QuantityByGBRN AS NUMBER(23, 11))
	// Obtaining a normalized amount.
	|				- (
	|					CAST(
	|						CAST(CompositeNumber.QuantityByGBRN AS NUMBER(23, 11)) / CAST(&KitCount AS NUMBER(23, 11))
	|					AS NUMBER(23, 11))
	// Restoring the quantity from the normalized and the number of sets (with a possible rounding error).
	|						* CAST(&KitCount AS NUMBER(23, 11))
	|				)
	|		AS NUMBER(23, 11)
	|	) AS QuantityByGBRN,
	|	CompositeNumber.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	CompositeNumber.Products AS Products,
	|	CompositeNumber.Characteristic AS Characteristic,
	|	CompositeNumber.Series AS Series,
	|	CAST(CompositeNumber.AmountByProductBatchID / &NumberOfSetsForRationingAmount AS NUMBER(31, 2)) AS AmountByProductBatchID
	|FROM
	|	TTTraceableProducts AS CompositeNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 5.
	// The aggregated table of CCD numbers, by key fields.
	|SELECT
	|	CompositeNumber.ThisIsBasicKit AS ThisIsBasicKit,
	|	CompositeNumber.ProductBatchIDNumber AS ProductBatchIDNumber,
	|	CompositeNumber.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	SUM(CompositeNumber.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(CompositeNumber.AmountByProductBatchID) AS AmountByProductBatchID
	|INTO TTCompositeNumberGrouped
	|FROM
	|	TTCompositeNumberSource AS CompositeNumber
	|
	|GROUP BY
	|	CompositeNumber.ThisIsBasicKit,
	|	CompositeNumber.ProductBatchIDNumber,
	|	CompositeNumber.FEACNUnitOfMeasure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 6.
	// Data for creating composite CCD numbers, if no suitable ones are found.
	|SELECT
	|	CompositeNumber.ThisIsBasicKit AS ThisIsBasicKit,
	|	CompositeNumber.ProductBatchIDNumber AS ProductBatchIDNumber,
	|	SUM(CompositeNumber.QuantityByGBRN) AS QuantityByGBRN,
	|	CompositeNumber.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	// The nomenclature, characteristics and batch are reference information, and are not the key when searching/creating traceable kits.
	// Used to calculate prices.
	|	CompositeNumber.Products AS Products,
	|	CompositeNumber.Characteristic AS Characteristic,
	|	CompositeNumber.Series AS Series,
	|	SUM(CompositeNumber.AmountByProductBatchID) AS AmountByProductBatchID
	|FROM
	|	TTCompositeNumberSource AS CompositeNumber
	|
	|GROUP BY
	|	CompositeNumber.ThisIsBasicKit,
	|	CompositeNumber.ProductBatchIDNumber,
	|	CompositeNumber.FEACNUnitOfMeasure,
	|	CompositeNumber.Products,
	|	CompositeNumber.Characteristic,
	|	CompositeNumber.Series
	|
	|ORDER BY
	|	CompositeNumber.ProductBatchIDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 7.
	// Calculation of the feature, whether the creation of a second composite CCD number (residual) is required.
	|SELECT
	|	ISNULL(MAX(Group.ItIsRequiredToUseSecondCompositeCCD), FALSE) AS ItIsRequiredToUseSecondCompositeCCD
	|FROM
	|	(SELECT
	|		SUM(Set.QuantityByGBRN) <> 0 AS ItIsRequiredToUseSecondCompositeCCD
	|	FROM
	|		(SELECT
	|			CompositeNumber.ProductBatchIDNumber AS ProductBatchIDNumber,
	|			CompositeNumber.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|			CompositeNumber.QuantityByGBRN AS QuantityByGBRN
	|		FROM
	|			TTCompositeNumberGrouped AS CompositeNumber
	|		WHERE
	|			CompositeNumber.ThisIsBasicKit
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CompositeNumber.ProductBatchIDNumber AS ProductBatchIDNumber,
	|			CompositeNumber.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|			-CompositeNumber.QuantityByGBRN AS QuantityByGBRN
	|		FROM
	|			TTCompositeNumberGrouped AS CompositeNumber
	|		WHERE
	|			NOT CompositeNumber.ThisIsBasicKit
	|		
	|		) AS Set
	|	
	|	GROUP BY
	|		Set.ProductBatchIDNumber,
	|		Set.FEACNUnitOfMeasure
	|	
	|	) AS Group
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 8.
	|SELECT
	|	CompositeNumber.ThisIsBasicKit AS ThisIsBasicKit,
	|	SUM(1) AS RowsCount,
	|	CAST(SUM(CompositeNumber.QuantityByGBRN) AS NUMBER(23, 11)) AS QuantityForAllLines,
	|	CAST(SUM(CompositeNumber.AmountByProductBatchID) AS NUMBER(31, 2)) AS SumOfAllLines
	|INTO TTCompositeNumberQuantity
	|FROM
	|	TTCompositeNumberGrouped AS CompositeNumber
	|
	|GROUP BY
	|	CompositeNumber.ThisIsBasicKit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 9.
	|SELECT
	|	CompositeNumber.ThisIsBasicKit AS ThisIsBasicKit,
	|	CompositeNumber.ProductBatchIDNumber AS ProductBatchIDNumber,
	|	CompositeNumber.QuantityByGBRN AS QuantityByGBRN,
	|	CompositeNumber.AmountByProductBatchID AS AmountByProductBatchID,
	|	CompositeNumber.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	QuantityTable.RowsCount AS RowsCount,
	|	QuantityTable.QuantityForAllLines AS QuantityForAllLines,
	|	QuantityTable.SumOfAllLines AS SumOfAllLines	
	|INTO TTCompositeNumber
	|FROM
	|	TTCompositeNumberGrouped AS CompositeNumber
	|		LEFT JOIN TTCompositeNumberQuantity AS QuantityTable
	|		ON CompositeNumber.ThisIsBasicKit = QuantityTable.ThisIsBasicKit
	|
	|INDEX BY
	|	ProductBatchIDNumber,
	|	QuantityByGBRN,
	|	AmountByProductBatchID,
	|	FEACNUnitOfMeasure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 10.
	|SELECT
	|	CompositeNumber.ThisIsBasicKit AS ThisIsBasicKit,
	|	CCDNumbers.Ref AS Ref
	|FROM
	|	Catalog.CCDNumbers.TraceableComponents AS CCDNumbers
	|		INNER JOIN TTCompositeNumber AS CompositeNumber
	|		ON (CompositeNumber.ProductBatchIDNumber = CCDNumbers.ProductBatchIDNumber)
	|			AND (CompositeNumber.QuantityByGBRN = CCDNumbers.QuantityByGBRN)
	|			AND &ConditionForAmountOfProductBatchID
	|			AND (CompositeNumber.FEACNUnitOfMeasure = CCDNumbers.FEACNUnitOfMeasure)
	|WHERE
	|	CCDNumbers.Ref.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT)
	|	AND NOT CCDNumbers.Ref.DeletionMark
	|
	|GROUP BY
	|	CompositeNumber.ThisIsBasicKit,
	|	CCDNumbers.Ref
	|
	|HAVING
	|	CCDNumbers.Ref.NumberOfComponents_ = MAX(CompositeNumber.RowsCount) 
	|	AND SUM(CCDNumbers.QuantityByGBRN) = MAX(CompositeNumber.QuantityForAllLines)
	|	AND &SelectionByAmountAccordingToProductBatchID";
	
	If KitCount = 0 Then
		KitCount = 1;
	EndIf;
	
	NumberOfSetsForRationingAmount = 1;
	If CreationParameters.NormalizeAmountAccordingToProductBatchIDWhenCreatingCompositeSet Then
		NumberOfSetsForRationingAmount = KitCount;
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	Query.SetParameter("Date", DateOfTraceabilityControl);
	Query.SetParameter("Goods", Goods);
	Query.SetParameter("KitCount", KitCount);
	Query.SetParameter("NumberOfSetsForRationingAmount", NumberOfSetsForRationingAmount);
	
	Query.TempTablesManager = New TempTablesManager;
	
	If Goods.Columns.Find("AmountByProductBatchID") = Undefined Then
		Query.Text = StrReplace(Query.Text, "&GoodsAmountAccordingToProductBatchID", "0");
	Else
		Query.Text = StrReplace(Query.Text, "&GoodsAmountAccordingToProductBatchID", "Goods.AmountByProductBatchID");
	EndIf;

	If CreationParameters.ExpandCCDNumberSearchKeyWithProductBatchIDAmount Then
		Query.Text = StrReplace(Query.Text, "&ConditionForAmountOfProductBatchID", "(CompositeNumber.AmountByProductBatchID = CCDNumbers.AmountByProductBatchID)");
		Query.Text = StrReplace(Query.Text, "&SelectionByAmountAccordingToProductBatchID", "SUM(CCDNumbers.AmountByProductBatchID) = MAX(CompositeNumber.SumOfAllLines)");
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionForAmountOfProductBatchID", "True");
		Query.Text = StrReplace(Query.Text, "&SelectionByAmountAccordingToProductBatchID", "True");
	EndIf;
	
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	StatusesForCreatingCompositeCCDNumbers = QueryResult[1].Select();
	LinesWithErrors = QueryResult[2].Select();
	AccessoriesForCreatingCompositeCCDNumber = QueryResult[6].Unload();
	CheckingAmountOfTraceableMaterialsBeingWrittenOff = QueryResult[5].Unload();
	ItIsRequiredToUseSecondCompositeCCDSample = QueryResult[7].Select();
	DecommissionedCCD = QueryResult[10].Select();
	
	If StatusesForCreatingCompositeCCDNumbers.Next() Then
		If StatusesForCreatingCompositeCCDNumbers.HasError Then
			While LinesWithErrors.Next() Do
				If LinesWithErrors.ThisIsCompositeCCD Then
					ErrorText = ?(ValueIsFilled(LinesWithErrors.Products), 
						NStr("vi = 'Số tờ khai hải quan (số đăng ký lô hàng) %1 được chọn cho mặt hàng %2 là thành phần bộ đóng gói. Cấm thu thập bộ đóng gói từ các bộ đóng gói.';
							|ru = 'Номер ГТД (РНПТ) %1, подобранный для номенклатурной позиции %2 является составным комплектом. Сборка комплектов из комплектов запрещена.';
							|en = 'CCD number (RNPT) %1 picked for the product item %2 is a composite kit. Assembly of kits from kits is restricted.'; fa = 'CCD number (RNPT) %1 picked for the product item %2 is a composite kit. Assembly of kits from kits is restricted.';
							|it = 'Numero di polizza doganale di carico (numero di registrazione lotti prodotti) %1, selezionato per la posizione dell''articolo %2 è il kit composito. Non è consentito assemblare kit di kit.';
							|pl = 'Numer ładunkowej deklaracji celnej (numer rejestracyjny partii towaru) %1, wybrany dla produktu %2 jest składnikowym zestawem. Zbieranie zestawów z zestawów jest zabronione.';
							|tr = '%2 stok öğesi için seçilen Gümrük Kargo Beyannamesi numarası (RNPT) %1, bileşik bir settir. Setlerden set montajı yasaktır.'"),
						NStr("vi = 'Số tờ khai hải quan (số đăng ký lô hàng) %1 là thành phần bộ đóng gói. Cấm thu thập bộ đóng gói từ bộ đóng gói.';
							|ru = 'Номер ГТД (РНПТ) %1 является составным комплектом. Сборка комплектов из комплектов запрещена.';
							|en = 'CCD number (RNPT) %1 is a composite kit. Assembly of kits from kits is restricted.'; fa = 'CCD number (RNPT) %1 is a composite kit. Assembly of kits from kits is restricted.';
							|it = 'Numero di polizza di carico doganale (numero di registrazione lotti prodotti) %1 è un kit composito. Non è consentito assemblare kit di kit.';
							|pl = 'Numer ładunkowej deklaracji celnej (numer rejestracyjny partii towaru) %1 jest składnikowym zestawem. Zbieranie zestawów z zestawów jest zabronione.';
							|tr = 'Gümrük Kargo Beyannamesi numarası (RNPT) %1, bileşik bir settir. Setlerden set montajı yasaktır.'"));
					ErrorText = StrTemplate(ErrorText, LinesWithErrors.CCDNumber, LinesWithErrors.Products);
					Common.MessageToUser(ErrorText,,,,Cancel);
				EndIf;
			EndDo;
		ElsIf Not StatusesForCreatingCompositeCCDNumbers.GenerationOfCompositeCCDIsRequired Then
			// There are no CCD numbers that can be debited (RNPT). The creation of composite CCD numbers is not required.
			Return ReturnValue;
		EndIf;
	Else
		// There are no CCD numbers that can be debited (RNPT). The creation of composite CCD numbers is not required.
		Return ReturnValue;
	EndIf;
	
	CompositeNumberOfCCD = Undefined;
	CompositeCCDResidualNumber = Undefined;
	While DecommissionedCCD.Next() Do
		If DecommissionedCCD.ThisIsBasicKit Then
			CompositeNumberOfCCD = DecommissionedCCD.Ref;
		ElsIf Not DecommissionedCCD.ThisIsBasicKit Then
			CompositeCCDResidualNumber = DecommissionedCCD.Ref;
		EndIf;
	EndDo;
	
	ItIsRequiredToUseSecondCompositeCCD = False;
	If ItIsRequiredToUseSecondCompositeCCDSample.Next() Then
		ItIsRequiredToUseSecondCompositeCCD = ItIsRequiredToUseSecondCompositeCCDSample.ItIsRequiredToUseSecondCompositeCCD;
	EndIf;
	
	ErrorText = NStr("vi = 'Để tạo số tờ khai hải quan (số đăng ký lô hàng) tổng hợp, cần chọn ít nhất một số tờ khai hải quan (số đăng ký lô hàng).
	|Hãy kiểm tra số lượng nguyên liệu có nguồn gốc xuất xứ được ghi giảm, và số dư số tờ khai hải quan (số đăng ký lô hàng) theo đó.';
	|ru = 'Для создания составного номера ГТД (РНПТ) требуется подобрать хотя бы один номер ГТД (РНПТ).
	|Проверьте количество списываемых прослеживаемых материалов, а так же остаток номеров ГТД (РНПТ) по ним.';
	|en = 'To create a composite CCD number (RNPT), pick at least one CCD number (RNPT).
	|Check the number of traceable materials to write off and remaining CCD (RNPT) numbers for them.'; fa = 'To create a composite CCD number (RNPT), pick at least one CCD number (RNPT).
	|Check the number of traceable materials to write off and remaining CCD (RNPT) numbers for them.';
	|it = 'Для создания составного номера ГТД (РНПТ) требуется подобрать хотя бы один номер ГТД (РНПТ).
	|Проверьте количество списываемых прослеживаемых материалов, а так же остаток номеров ГТД (РНПТ) по ним.';
	|pl = 'To create a composite CCD number (RNPT), pick at least one CCD number (RNPT).
	|Check the number of traceable materials to write off and remaining CCD (RNPT) numbers for them.';
	|tr = 'Bileşik bir GKB (RNPT) numarası oluşturmak için en az bir GKB (RNPT) numarası seçilmelidir.
	|Kayıttan düşülen izlenebilir malzemelerin miktarını ve bunlar için GKB (RNPT) numaralarının bakiyesini kontrol edin.'");
	RowFilter = New Structure("ThisIsBasicKit", False);
	FoundRows = CheckingAmountOfTraceableMaterialsBeingWrittenOff.FindRows(RowFilter);
	If FoundRows.Count() = 0
		And (CompositeNumberOfCCD = Undefined
			Or CompositeCCDResidualNumber = Undefined
			And ItIsRequiredToUseSecondCompositeCCD) Then
		Common.MessageToUser(ErrorText,,,,Cancel);
	EndIf;
	
	If CompositeNumberOfCCD = Undefined
		And Not Cancel Then
		CompositeNumberOfCCD = CreateCompositeTraceableCCDNumber(AccessoriesForCreatingCompositeCCDNumber,
			True,
			CreationParameters.ItemOfHeader,
			CreationParameters.CharacteristicsOfCap,
			CreationParameters.CapsBatch,
			CreationParameters.AmountByProductBatchID / NumberOfSetsForRationingAmount,
			CreationParameters.AlwaysUseAmountByProductBatchIDForCostOfKit);
	EndIf;
	
	If Not ItIsRequiredToUseSecondCompositeCCD Then
		CompositeCCDResidualNumber = Undefined;
	ElsIf CompositeCCDResidualNumber = Undefined
		And ItIsRequiredToUseSecondCompositeCCD
		And Not Cancel Then
		
		CompositeCCDResidualNumber = CreateCompositeTraceableCCDNumber(
										AccessoriesForCreatingCompositeCCDNumber,
										False,
										CreationParameters.ItemOfHeader,
										CreationParameters.CharacteristicsOfCap,
										CreationParameters.CapsBatch,
										CreationParameters.AmountByProductBatchID / NumberOfSetsForRationingAmount,
										CreationParameters.AlwaysUseAmountByProductBatchIDForCostOfKit);
		
	EndIf;
	
	ReturnValue.ThereAreCompositeTraceableCCDNumbers = CompositeNumberOfCCD <> Undefined;
	ReturnValue.MainCompositeNumberOfCCD = CompositeNumberOfCCD;
	ReturnValue.ResidualCompositeNumberOfCCD = CompositeCCDResidualNumber;
	
	Return ReturnValue;

EndFunction

// Disassembly of traceable CCD numbers.
// There are 2 main ways to use the method - with the transfer of Product, and without.
// In this case, the Product can be passed either explicitly or extracted from some object (for example, from
// Product Accounting Analytics).
// If you completely refuse to transfer the Product list, you should explicitly transfer the unit of measurement of the Customs Code of Foreign Economic activity.
// 
// Parameters:
//  GoodsToWriteOff - ValueTable - A table containing composite traceable CCD numbers:
//  * CCDNumber - CatalogRef.CCDNumbers - 
//  * Count - Number - 
//  GoodsToRecordAsReceived - ValueTable - The table to which it is necessary to distribute the CCD numbers of the product table to the list:
//  * ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - 
//  * Count - Number - 
//  * InventoryOwnerAttribute - CatalogRef.InventoryKinds - 
//  FieldsFromObject - Array of String, Undefined - The names of the columns (non-numeric) in the Product arrival table that need to be saved
//  until the function returns the result. If omitted, the returned table will contain only the required columns. These fields
//  will be counted as grouping fields, or the maximum will be taken from them, depending on the section of the request.
//  FieldsNumeric - Array of String, Undefined - The names of the columns (numeric) in the Product arrival table that need to be saved
//  until the function returns the result. If omitted, the returned table will contain only the required columns. These fields
//  will be summed up and participate in the distribution on a par with quantitative fields.
//  Cancel - Boolean - 
// 
// Returns:
//  ValueTable:
//  * ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - 
//  * InventoryOwnerAttribute - CatalogRef.InventoryKinds - 
//  * CCDNumber - CatalogRef.CCDNumbers - 
//  * QuantityByGBRN - Number -
//  * Count - Number -  
Function DisassembleCompositeTraceableCCDNumbers(GoodsToWriteOff, GoodsToRecordAsReceived, FieldsFromObject = Undefined, FieldsNumeric = Undefined, Cancel = False) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	CAST(Goods.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber,
	|	CAST(Goods.Count AS NUMBER(15, 3)) AS Count
	|INTO TTComponents
	|FROM
	|	&Components AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(Goods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS
	|		ItemsLocationAttributes,
	|	&GoodsObjectFields,
	|	&GoodsNumericFields,
	|	CAST(Goods.Count AS NUMBER(15, 3)) AS Count,
	|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Components.ProductBatchIDNumber AS CCDNumber,
	// The item of the disassembled kit.
	|	MAX(ISNULL(TTComponents.CCDNumber.Products, VALUE(Catalog.Products.EmptyRef))) AS Products,
	|	CAST(SUM(Components.QuantityByGBRN) AS NUMBER(23, 11)) AS OriginalQuantity,
	|	CAST(SUM(Components.QuantityByGBRN * TTComponents.Count) AS NUMBER(23, 11)) AS Count,
	|	Components.FEACNUnitOfMeasure AS FEACNUnitOfMeasure
	|INTO TTListOfComponents
	|FROM
	|	TTComponents AS TTComponents
	|		INNER JOIN Catalog.CCDNumbers.TraceableComponents AS Components
	|		ON TTComponents.CCDNumber = Components.Ref
	|
	|GROUP BY
	|	Components.ProductBatchIDNumber,
	|	Components.FEACNUnitOfMeasure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	&MaximumObjectFields,
	|	&SumOfFieldIsNumeric,
	|	CASE
	|		WHEN Goods.ItemsLocationAttributes.Products.FEACNUnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.ItemsLocationAttributes.Products.FEACNUnitOfMeasure
	|		WHEN Goods.ItemsLocationAttributes.Products.FEACNCode.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.ItemsLocationAttributes.Products.FEACNCode.UnitOfMeasure
	|		ELSE Goods.ItemsLocationAttributes.Products.UnitOfMeasure
	|	END AS FEACNUnitOfMeasure,
	|	SUM(Goods.Count) AS Count
	|INTO TTProductsList
	|FROM
	|	TTProducts_1 AS Goods
	|WHERE
	|	Goods.ItemsLocationAttributes.Products.TracedGoods
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute,
	|	CASE
	|		WHEN Goods.ItemsLocationAttributes.Products.FEACNUnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.ItemsLocationAttributes.Products.FEACNUnitOfMeasure
	|		WHEN Goods.ItemsLocationAttributes.Products.FEACNCode.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.ItemsLocationAttributes.Products.FEACNCode.UnitOfMeasure
	|		ELSE Goods.ItemsLocationAttributes.Products.UnitOfMeasure
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	SUM(TTProducts_1.Count) AS CountTotal
	|INTO TTListOfComponentsSum
	|FROM
	|	TTListOfComponents AS TTProducts_1
	|GROUP BY
	|	TTProducts_1.FEACNUnitOfMeasure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	&SumOfFieldIsNumeric,
	|	SUM(Goods.Count) AS CountTotal
	|INTO TTListOfProductsAmount
	|FROM
	|	TTProductsList AS Goods
	|GROUP BY
	|	Goods.FEACNUnitOfMeasure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTListOfComponents.CCDNumber AS CCDNumber,
	|	TTListOfComponents.FEACNUnitOfMeasure,
	|	&GoodsObjectFields,
	|	&DivisionFieldsAreNumeric,
	|	CAST(TTListOfComponents.Count / TTListOfProductsAmount.CountTotal * Goods.Count AS NUMBER(23, 11)) AS
	|		QuantityByGBRN,
	|	CAST(TTListOfComponents.Count / TTListOfComponentsSum.CountTotal * Goods.Count AS NUMBER(15, 3)) AS
	|		Count
	|	
	|INTO TTDistributionResult
	|FROM
	|	TTListOfComponents AS TTListOfComponents
	|		INNER JOIN TTProductsList AS Goods
	|		ON Goods.FEACNUnitOfMeasure = TTListOfComponents.FEACNUnitOfMeasure
	|		INNER JOIN TTListOfProductsAmount AS TTListOfProductsAmount
	|		ON TTListOfProductsAmount.FEACNUnitOfMeasure = TTListOfComponents.FEACNUnitOfMeasure
	|		INNER JOIN TTListOfComponentsSum AS TTListOfComponentsSum
	|		ON TTListOfComponentsSum.FEACNUnitOfMeasure = TTListOfComponents.FEACNUnitOfMeasure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	SUM(Goods.Count) AS Count
	|INTO TTResultOfDistributionOfGoodsAmount
	|FROM
	|	TTDistributionResult AS Goods
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.CCDNumber AS CCDNumber,
	|	Goods.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	SUM(Goods.QuantityByGBRN) AS QuantityByGBRN
	|INTO TTIsResultOfDistributionOfRNPTSum
	|FROM
	|	TTDistributionResult AS Goods
	|GROUP BY
	|	Goods.CCDNumber,
	|	Goods.FEACNUnitOfMeasure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CAST(Goods.Count - TTProductsList.Count AS NUMBER(15, 3)) AS DeltaQuantityByProduct
	|INTO TTDeltaNumberOfProducts
	|FROM
	|	TTResultOfDistributionOfGoodsAmount AS Goods
	|		INNER JOIN TTProductsList AS TTProductsList
	|		ON Goods.ItemsLocationAttributes = TTProductsList.ItemsLocationAttributes
	|		AND Goods.InventoryOwnerAttribute = TTProductsList.InventoryOwnerAttribute
	|
	|WHERE
	|	CAST(Goods.Count - TTProductsList.Count AS NUMBER(15, 3)) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.CCDNumber AS CCDNumber,
	|	Goods.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	CAST(Goods.QuantityByGBRN - TTProductsList.Count AS NUMBER(23, 11)) AS DeltaQuantityAccordingToRNPT
	|INTO TTDeltaQuantityAccordingToRNPT
	|FROM
	|	TTIsResultOfDistributionOfRNPTSum AS Goods
	|		INNER JOIN TTListOfComponents AS TTProductsList
	|		ON Goods.CCDNumber = TTProductsList.CCDNumber
	|		AND Goods.FEACNUnitOfMeasure = TTProductsList.FEACNUnitOfMeasure
	|
	|WHERE
	|	CAST(Goods.QuantityByGBRN - TTProductsList.Count AS NUMBER(23, 11)) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataSet.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DataSet.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DataSet.CCDNumber AS CCDNumber,
	|	DataSet.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|	&DataSetObjectFields,
	|	&DataSetFieldsNumericSum,
	|	SUM(DataSet.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(DataSet.Count) AS Count
	|FROM
	|	(SELECT
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		Goods.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|		&GoodsObjectFields,
	|		&GoodsNumericFields,
	|		Goods.QuantityByGBRN AS QuantityByGBRN,
	|		Goods.Count AS Count
	|	FROM
	|		TTDistributionResult AS Goods
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		MAX(Goods.CCDNumber) AS CCDNumber,
	|		MAX(Goods.FEACNUnitOfMeasure) AS FEACNUnitOfMeasure,
	|		&MaximumObjectFields,
	|		&SumOfFieldIsNumeric,
	|		0 AS QuantityByGBRN,
	|		-TTDelta.DeltaQuantityByProduct AS Count
	|	FROM
	|		TTDistributionResult AS Goods
	|			INNER JOIN TTDeltaNumberOfProducts AS TTDelta
	|			ON Goods.ItemsLocationAttributes = TTDelta.ItemsLocationAttributes
	|			AND Goods.InventoryOwnerAttribute = TTDelta.InventoryOwnerAttribute
	|	GROUP BY
	|		Goods.ItemsLocationAttributes,
	|		Goods.InventoryOwnerAttribute,
	|		TTDelta.DeltaQuantityByProduct
	|
	|	UNION ALL
	|
	|	SELECT
	|		MAX(Goods.ItemsLocationAttributes) AS ItemsLocationAttributes,
	|		MAX(Goods.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		Goods.FEACNUnitOfMeasure AS FEACNUnitOfMeasure,
	|		&MaximumObjectFields,
	|		&SumOfFieldIsNumeric,
	|		-TTDelta.DeltaQuantityAccordingToRNPT AS QuantityByGBRN,
	|		0 AS Count
	|	FROM
	|		TTDistributionResult AS Goods
	|			INNER JOIN TTDeltaQuantityAccordingToRNPT AS TTDelta
	|			ON Goods.CCDNumber = TTDelta.CCDNumber
	|			AND Goods.FEACNUnitOfMeasure = TTDelta.FEACNUnitOfMeasure
	|	GROUP BY
	|		Goods.CCDNumber,
	|		Goods.FEACNUnitOfMeasure,
	|		TTDelta.DeltaQuantityAccordingToRNPT) AS DataSet
	|GROUP BY
	|	DataSet.ItemsLocationAttributes,
	|	DataSet.InventoryOwnerAttribute,
	|	DataSet.CCDNumber,
	|	&DataSetWithoutDereferenceObjectFields,
	|	DataSet.FEACNUnitOfMeasure
	|HAVING
	|	SUM(DataSet.QuantityByGBRN) > 0
	|	OR SUM(DataSet.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfComponents.CCDNumber AS CCDNumber,
	|	ListOfComponents.Products AS Products,
	|	ISNULL(CatalogProducts.DescriptionFull, """") AS ItemName,
	|	ISNULL(ListOfComponents.CCDNumber.Products, VALUE(Catalog.Products.EmptyRef))
	|		= VALUE(Catalog.Products.EmptyRef) AS ItIsRequiredToFillInItemToCCD,
	|	ListOfComponents.OriginalQuantity AS AmountOfRNPTIsInitial,
	|	ListOfComponents.Count AS TotalNumberOfRNPT,
	|	ListOfComponents.FEACNUnitOfMeasure AS FEACNUnitOfMeasure
	|FROM
	|	TTListOfComponents AS ListOfComponents
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON ListOfComponents.Products = CatalogProducts.Ref";
	
	Query.SetParameter("Components", GoodsToWriteOff);
	Query.SetParameter("Goods", GoodsToRecordAsReceived);
	
	// Templates for parts of the request to replace.
	// Object and numeric.
	GoodsTemplate = "Goods.%1 AS %1,"; // @query-part
	TemplateDataSet = "DataSet.%1 AS %1,"; // @query-part
	TemplateSetOfDataWithoutDereference = "DataSet.%1,"; // @query-part
	TemplateMaximumGoods = "MAX(Goods.%1) AS %1,"; // @query-part
	// Numeric.
	TemplateSumDataSet = "SUM(DataSet.%1) AS %1,"; // @query-part
	TemplateAmountOfGoods = "SUM(Goods.%1) AS %1,"; // @query-part
	PatternDivision = "TTListOfProductsAmount.%1 * (Goods.Count / TTListOfComponents.Count) AS %1,"; // @query-part
	
	// Request parameters for substitution.
	// Object.
	ParametersOfGoods = "&GoodsObjectFields,"; // @query-part
	MaximumParameters = "&MaximumObjectFields,"; // @query-part
	ParametersSet = "&DataSetObjectFields,"; // @query-part
	ParametersSetWithoutDereference = "&DataSetWithoutDereferenceObjectFields,"; // @query-part
	// Numeric.
	GoodsParametersAreNumeric = "&GoodsNumericFields,"; // @query-part
	ParametersAmount = "&SumOfFieldIsNumeric,"; // @query-part
	ParametersDivision = "&DivisionFieldsAreNumeric,"; // @query-part
	SetNumericParameters = "&DataSetFieldsNumericSum,"; // @query-part
	
	// Matching templates to request parameters.
	Templates_Parameters = New Map();
	// Object.
	If FieldsFromObject <> Undefined Then
		Templates_Parameters.Insert(GoodsTemplate, ParametersOfGoods);
		Templates_Parameters.Insert(TemplateMaximumGoods, MaximumParameters);
		Templates_Parameters.Insert(TemplateDataSet, ParametersSet);
		Templates_Parameters.Insert(TemplateSetOfDataWithoutDereference, ParametersSetWithoutDereference);
		
		Query.Text = ReplaceParametersOfTextOfDisassemblyRequestForCompositeTraceableCCDNumbers(Query.Text,
			Templates_Parameters,
			FieldsFromObject);
	Else
		Query.Text = StrReplace(Query.Text, ParametersOfGoods, "");
		Query.Text = StrReplace(Query.Text, MaximumParameters, "");
		Query.Text = StrReplace(Query.Text, ParametersSet, "");
		Query.Text = StrReplace(Query.Text, ParametersSetWithoutDereference, "");
	EndIf;
	
	// Matching templates to request parameters.
	Templates_Parameters = New Map();
	// Numeric.
	If FieldsNumeric <> Undefined Then
		Templates_Parameters.Insert(GoodsTemplate, GoodsParametersAreNumeric);
		Templates_Parameters.Insert(TemplateAmountOfGoods, ParametersAmount);
		Templates_Parameters.Insert(PatternDivision, ParametersDivision);
		Templates_Parameters.Insert(TemplateSumDataSet, SetNumericParameters);
		
		Query.Text = ReplaceParametersOfTextOfDisassemblyRequestForCompositeTraceableCCDNumbers(Query.Text,
			Templates_Parameters,
			FieldsNumeric);
	Else
		Query.Text = StrReplace(Query.Text, GoodsParametersAreNumeric, "");
		Query.Text = StrReplace(Query.Text, ParametersAmount, "");
		Query.Text = StrReplace(Query.Text, ParametersDivision, "");
		Query.Text = StrReplace(Query.Text, SetNumericParameters, "");
	EndIf;
	
	QueryResult = Query.ExecuteBatch();
	
	RNPTComponents = QueryResult[QueryResult.UBound()].Select();
	
	Result = QueryResult[QueryResult.UBound() - 1].Unload(); // ValueTable -
	Result.Indexes.Add("CCDNumber, FEACNUnitOfMeasure");
	
	SearchParameters = New Structure("CCDNumber, FEACNUnitOfMeasure");
	While RNPTComponents.Next() Do
		FillPropertyValues(SearchParameters, RNPTComponents);
		FoundRows = Result.FindRows(SearchParameters);
		InitialQuantity_ = RNPTComponents.TotalNumberOfRNPT;
		For Each FoundRow In FoundRows Do
			InitialQuantity_ = InitialQuantity_ - FoundRow.QuantityByGBRN;
		EndDo;
		If InitialQuantity_ <> 0 Then
			MessageTemplate = NStr("vi = 'Khi phân tích bộ truy xuất tổng hợp đã ghi nhận lỗi: không thể gán số đăng ký lô hàng ""%1"" sang một sản phẩm có thể được truy xuất nguồn gốc (thành phần chi tiết), bởi vì không có sản phẩm (thành phần chi tiết) với đơn vị tính phù hợp của hàng hóa xuất nhập khẩu (""%2"").
			|Để ngăn chặn mất thông tin về số dư số đăng ký lô hàng, hãy chỉ ra sản phẩm bổ sung (thành phần chi tiết), với đơn vị tính cần thiết của hàng hóa xuất nhập khẩu.';
			|ru = 'При разборке составных прослеживаемых комплектов зафиксирована ошибка: невозможно отнести номер РНПТ ""%1"" на прослеживаемое изделие (комплектующее), поскольку нет изделия (комплектующего) с подходящей единицей измерения ТНВЭД (""%2"").
			|Для предотвращения потери информации об остатках номера РНПТ, укажите дополнительное изделие (комплектующее), с необходимой единицей измерения ТНВЭД.';
			|en = 'An error occurred when performing the reverse kitting of traceable kits: cannot attribute RNPT number ""%1"" to a traceable finished product (component) as there is no finished product (component) with a suitable FEACN unit of measure (""%2"").
			|To prevent the loss of information about the RNPT number balance, specify an additional finished product (component) with the required FEACN unit of measure.'; fa = 'An error occurred when performing the reverse kitting of traceable kits: cannot attribute RNPT number ""%1"" to a traceable finished product (component) as there is no finished product (component) with a suitable FEACN unit of measure (""%2"").
			|To prevent the loss of information about the RNPT number balance, specify an additional finished product (component) with the required FEACN unit of measure.';
			|it = 'При разборке составных прослеживаемых комплектов зафиксирована ошибка: невозможно отнести номер РНПТ ""%1"" на прослеживаемое изделие (комплектующее), поскольку нет изделия (комплектующего) с подходящей единицей измерения ТНВЭД (""%2"").
			|Для предотвращения потери информации об остатках номера РНПТ, укажите дополнительное изделие (комплектующее), с необходимой единицей измерения ТНВЭД.';
			|pl = 'An error occurred when performing the reverse kitting of traceable kits: cannot attribute RNPT number ""%1"" to a traceable finished product (component) as there is no finished product (component) with a suitable FEACN unit of measure (""%2"").
			|To prevent the loss of information about the RNPT number balance, specify an additional finished product (component) with the required FEACN unit of measure.';
			|tr = 'Bileşik izlenebilir set ""%1"" sökülürken hata kaydedildi: Dış Ekonomik Faaliyetlerin Stok Ürünlerinin (""%3"") uygun ölçüm birimine sahip bir ürün (bileşen) olmadığından, izlenebilir ürüne (bileşene) RNPT ""%2"" numarasını atamak imkansızdır.
			|RNPT numarasının kalıntıları hakkında bilgi kaybını önlemek için, gerekli DEFSÜ ölçüm birimiyle birlikte ek bir ürün (bileşen) belirt.'");
			MessageText = StrTemplate(MessageTemplate, TrimAll(RNPTComponents.CCDNumber), TrimAll(RNPTComponents.FEACNUnitOfMeasure));
			Common.MessageToUser(MessageText, Undefined, "", "", Cancel);
		EndIf;
		
		If ValueIsFilled(RNPTComponents.Products)
			And RNPTComponents.ItIsRequiredToFillInItemToCCD Then
			
			UpdatingProductBatchIDItemList(RNPTComponents.CCDNumber,
											RNPTComponents.Products,
											RNPTComponents.ItemName);
			
		EndIf;
		
	EndDo;
	
	// Without explicit typing of the value table, when it is further loaded into the temporary query table
	// , the accuracy of numeric fields will be cut off to 9 characters.
	Qualifier = New NumberQualifiers(23, 11);
	Result.Columns.QuantityByGBRN.Name = "QuantityAccordingToProductBatchIDWithoutTyping";
	Result.Columns.Add("QuantityByGBRN", New TypeDescription("Number", Qualifier));
	Result.LoadColumn(Result.UnloadColumn("QuantityAccordingToProductBatchIDWithoutTyping"), "QuantityByGBRN");
	
	Return Result;
	
EndFunction

// Receives a table of goods with traceable CCD numbers, the transmitted table of goods, including the
// extraction of components from kits, traceable CCD numbers.
//
// Parameters:
//	Goods - ValueTable - The products table:
//		* ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - Analytics of inventory accounting.
//		* CCDNumber - CatalogRef.CCDNumbers - the product's GTD number.
//		* Count - Number - the quantity of goods in a storage unit.
//		* QuantityByGBRN - Number - the quantity of goods in the unit of measurement of the Customs Code of Foreign Economic Activity, for traceable goods,
//									or the unit of storage of goods for sets, traceable CCD numbers.
//
// Returns:
//	ValueTable - a table containing analytics for tracking traceable goods with traceability credentials:
//		* ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - Analytics of accounting for traceable items.
//		* CCDNumber - CatalogRef.CCDNumbers - the traceable CCD number.
//		* QuantityByGBRN - Number -  the quantity of the goods in the unit of measurement of the FEA.
//
Function GetTraceableCCDNumbers(Goods) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|	Goods.CCDNumber										AS CCDNumber,
	|	CAST(Goods.Count AS NUMBER(15, 3))		AS Count,
	|	CAST(Goods.QuantityByGBRN AS NUMBER(23, 11))	AS QuantityByGBRN
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Components.ProductBatchIDNumber				AS CCDNumber,
	// The item of the disassembled kit.
	|	MAX(ISNULL(CatalogCCDNumbers.Products, VALUE(Catalog.Products.EmptyRef))) AS Products,
	|	CAST(SUM(Components.QuantityByGBRN * Goods.Count) AS NUMBER(23, 11)) AS QuantityByGBRN
	|INTO TTListOfComponents
	|FROM
	|	TTProducts_1 AS Goods
	|		INNER JOIN Catalog.CCDNumbers.TraceableComponents AS Components
	|		ON Goods.CCDNumber = Components.Ref
	|		
	|		INNER JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
	|		ON Goods.CCDNumber = CatalogCCDNumbers.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON Goods.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON DimensionKeys.Products = CatalogProducts.Ref
	|
	|WHERE
	|	ISNULL(CatalogProducts.TracedGoods, FALSE)
	|
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Components.ProductBatchIDNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	ListOfComponents.CCDNumber		AS CCDNumber,
	|	ListOfComponents.Products	AS Products,
	|	ISNULL(CatalogProducts.DescriptionFull, """") AS ItemName
	|FROM
	|	TTListOfComponents AS ListOfComponents
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON ListOfComponents.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
	|		ON ListOfComponents.CCDNumber = CatalogCCDNumbers.Ref
	|WHERE
	|	ListOfComponents.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND ISNULL(CatalogCCDNumbers.Products, VALUE(Catalog.Products.EmptyRef)) = VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Goods.CCDNumber						AS CCDNumber,
	|	Goods.QuantityByGBRN				AS QuantityByGBRN
	|FROM
	|	TTProducts_1 AS Goods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON Goods.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON DimensionKeys.Products = CatalogProducts.Ref
	|		
	|		INNER JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
	|		ON Goods.CCDNumber = CatalogCCDNumbers.Ref
	|
	|WHERE
	|	ISNULL(CatalogProducts.TracedGoods, FALSE)
	|	AND CatalogCCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Goods.CCDNumber						AS CCDNumber,
	|	Goods.QuantityByGBRN				AS QuantityByGBRN
	|FROM
	|	TTListOfComponents AS Goods";
	
	Query.SetParameter("Goods", Goods);
	
	QueryResult	= Query.ExecuteBatch();
	RNPTComponents	= QueryResult[QueryResult.UBound() - 1].Select();
	Result			= QueryResult[QueryResult.UBound()].Unload(); // ValueTable -
	
	While RNPTComponents.Next() Do
		UpdatingProductBatchIDItemList(RNPTComponents.CCDNumber,
										RNPTComponents.Products,
										RNPTComponents.ItemName);
	EndDo;
	
	// Without explicit typing of the value table, when it is further loaded into the temporary query table
	// , the accuracy of numeric fields will be cut off to 9 characters.
	Qualifier = New NumberQualifiers(23, 11);
	
	Result.Columns.QuantityByGBRN.Name = "QuantityAccordingToProductBatchIDWithoutTyping";
	Result.Columns.Add("QuantityByGBRN", New TypeDescription("Number", Qualifier));
	
	Result.LoadColumn(Result.UnloadColumn("QuantityAccordingToProductBatchIDWithoutTyping"), "QuantityByGBRN");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

// Fills in the list of names of incoming documents for the last 5 documents of the counterparty.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document.
// 	Counterparty - CatalogRef.Counterparties - link to the counterparty to search for.
// 	NameOfTheItemName - String - The name of the Attribute with the name of the incoming document.
//
Procedure FillInSelectionListNameOfIncomingDocument(Form, Counterparty, NameOfTheItemName = "ExternalDocumentName") Export
	Item = Form.Items.ExternalDocumentName;
	Document = Form.Object; // DocumentObjectDocumentName - 
	FullName = Document.Ref.Metadata().FullName();
	
	QueryText = "SELECT DISTINCT
	|	NestedTable.Description AS Description
	|FROM
	|	(SELECT TOP 5
	|		&NameOfTheFieldName AS Description
	|	FROM
	|		&FullName AS Table
	|	WHERE
	|		Table.Counterparty = &Counterparty
	|		AND &NameOfTheFieldName <> &IsBlankString
	|	ORDER BY
	|		Table.Date DESC) AS NestedTable";
	
	NameOfTheFieldName = "Table" + "." + NameOfTheItemName;
	QueryText = StrReplace(QueryText, "&NameOfTheFieldName", NameOfTheFieldName);
	QueryText = StrReplace(QueryText, "&FullName", FullName);
	
	Query = New Query(QueryText);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("RefType", Common.MetadataObjectID(TypeOf(Document.Ref)));
	Query.SetParameter("IsBlankString", "");
	
	SetPrivilegedMode(True);
	ArrayOfNames = Query.Execute().Unload().UnloadColumn("Description");
	SetPrivilegedMode(False);
	ManagerModule = Common.ObjectManagerByFullName(FullName);
	ArrayOfPredefinedNames = ManagerModule.NamesOfIncomingDocuments();
	
	For Each ArrayElement In ArrayOfPredefinedNames Do
		If ArrayOfNames.Find(ArrayElement) = Undefined Then
			ArrayOfNames.Add(ArrayElement);
		EndIf;
	EndDo;
	Item.ChoiceList.LoadValues(ArrayOfNames);
	
EndProcedure

// Fills in the receipt and price documents in the tabular part of the return documents
//
// Parameters:
//		DocumentReturnPolicy - DocumentObject.ReturnOfGoodsToVendor - Return document 
//		TableName - String - Name of the Products table
Procedure FillInTheReceiptsAndPrices(DocumentReturnPolicy, TableName) Export
	
	TableOfCheckedGoods = DocumentReturnPolicy[TableName].Unload();
	TabularPartOfReturn = DocumentReturnPolicy[TableName];
	
	QueryText =
	"SELECT ALLOWED
	|	ReturnOfGoodsToSupplier.Products,
	|	ReturnOfGoodsToSupplier.Characteristic,
	|	ReturnOfGoodsToSupplier.Series,
	|	ReturnOfGoodsToSupplier.NumberOfPackages,
	|	ReturnOfGoodsToSupplier.Package,
	|	ReturnOfGoodsToSupplier.Count
	|INTO ProductsToFillIn
	|FROM
	|	&GoodsTable AS ReturnOfGoodsToSupplier
	|
	|INDEX BY
	|	ReturnOfGoodsToSupplier.Products,
	|	ReturnOfGoodsToSupplier.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	PurchaseOfGoodsServicesGoods.Ref AS Ref
	|INTO ReceiptDocuments
	|FROM
	|	ProductsToFillIn AS ProductsToFillIn
	|		LEFT JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|		ON ProductsToFillIn.Products = PurchaseOfGoodsServicesGoods.Products
	|			AND ProductsToFillIn.Characteristic = PurchaseOfGoodsServicesGoods.Characteristic
	|WHERE
	|	PurchaseOfGoodsServicesGoods.Ref.Posted
	|	AND PurchaseOfGoodsServicesGoods.Ref.Counterparty = &Counterparty
	|	AND PurchaseOfGoodsServicesGoods.Ref.Organization = &Organization
	|	AND PurchaseOfGoodsServicesGoods.Ref.Terms = &Terms
	|	AND PurchaseOfGoodsServicesGoods.Ref.VATTaxation = &VATTaxation
	|	AND PurchaseOfGoodsServicesGoods.Ref.Partner = &Partner
	|	AND PurchaseOfGoodsServicesGoods.Ref.LineOfBusiness = &LineOfBusiness
	|	AND PurchaseOfGoodsServicesGoods.Ref.Date <= &ReturnDate
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MAX(PurchaseAdjustment.Date) AS Date,
	|	ReceiptDocuments.Ref AS ReceiptLink
	|INTO AdjustmentData
	|FROM
	|	ReceiptDocuments AS ReceiptDocuments
	|		LEFT JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
	|		ON (PurchaseAdjustment.DocumentBasis = ReceiptDocuments.Ref)
	|WHERE
	|	PurchaseAdjustment.Posted
	|
	|GROUP BY
	|	ReceiptDocuments.Ref
	|
	|INDEX BY
	|	ReceiptLink
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MAX(PurchaseAdjustment.Ref) AS Ref,
	|	MAX(PurchaseAdjustment.Ref.Date) AS Date,
	|	PurchaseAdjustment.Ref.DocumentBasis AS ReceiptLink
	|INTO LastAdjustmentData
	|FROM
	|	Document.PurchaseAdjustment AS PurchaseAdjustment
	|WHERE
	|	(PurchaseAdjustment.Ref.DocumentBasis, PurchaseAdjustment.Ref.Date) IN
	|			(SELECT
	|				AdjustmentData.ReceiptLink AS ReceiptLink,
	|				AdjustmentData.Date AS Date
	|			FROM
	|				AdjustmentData)
	|
	|GROUP BY
	|	PurchaseAdjustment.Ref.DocumentBasis
	|
	|INDEX BY
	|	Ref,
	|	ReceiptLink
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	CASE
	|		WHEN LastAdjustmentData.Ref IS NULL 
	|			THEN ReceiptDocuments.Ref
	|		ELSE LastAdjustmentData.Ref
	|	END AS Ref
	|INTO LinksToReceipts
	|FROM
	|	ReceiptDocuments AS ReceiptDocuments
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON ReceiptDocuments.Ref = LastAdjustmentData.ReceiptLink
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AdjustmentOfAcquisitionOfGoods.Products AS Products,
	|	AdjustmentOfAcquisitionOfGoods.Characteristic AS Characteristic,
	|	AdjustmentOfAcquisitionOfGoods.Series AS Series,
	|	AdjustmentOfAcquisitionOfGoods.NumberOfPackages,
	|	AdjustmentOfAcquisitionOfGoods.Count,
	|	AdjustmentOfAcquisitionOfGoods.Price,
	|	AdjustmentOfAcquisitionOfGoods.Sum,
	|	AdjustmentOfAcquisitionOfGoods.Package,
	|	0 AS ManualDiscount,
	|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis AS DocumentInflow
	|INTO ReceiptData
	|FROM
	|	LinksToReceipts AS LinksToReceipts
	|		INNER JOIN Document.PurchaseAdjustment.Goods AS AdjustmentOfAcquisitionOfGoods
	|		ON (AdjustmentOfAcquisitionOfGoods.Ref = LinksToReceipts.Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.Series,
	|	PurchaseOfGoodsServicesGoods.NumberOfPackages,
	|	PurchaseOfGoodsServicesGoods.Count,
	|	CASE
	|		WHEN PurchaseOfGoodsServicesGoods.ManualDiscount = 0
	|				OR PurchaseOfGoodsServicesGoods.NumberOfPackages = 0
	|			THEN PurchaseOfGoodsServicesGoods.Price
	|		ELSE PurchaseOfGoodsServicesGoods.Sum / PurchaseOfGoodsServicesGoods.NumberOfPackages
	|	END,
	|	PurchaseOfGoodsServicesGoods.Sum,
	|	PurchaseOfGoodsServicesGoods.Package,
	|	PurchaseOfGoodsServicesGoods.ManualDiscount,
	|	PurchaseOfGoodsServicesGoods.Ref
	|FROM
	|	LinksToReceipts AS LinksToReceipts
	|		INNER JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|		ON (PurchaseOfGoodsServicesGoods.Ref = LinksToReceipts.Ref)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfCheckedProducts.Products AS Products,
	|	TableOfCheckedProducts.Characteristic AS Characteristic,
	|	TableOfCheckedProducts.Series AS Series,
	|	SUM(TableOfCheckedProducts.NumberOfPackages) AS NumberOfPackages,
	|	SUM(TableOfCheckedProducts.Count) AS Count,
	|	TableOfCheckedProducts.DocumentInflow AS DocumentInflow
	|INTO ReturnDocumentData
	|FROM
	|	ReceiptDocuments AS ReceiptDocuments
	|		LEFT JOIN Document.ReturnOfGoodsToVendor.Goods AS TableOfCheckedProducts
	|		ON (TableOfCheckedProducts.DocumentInflow = ReceiptDocuments.Ref)
	|WHERE
	|	TableOfCheckedProducts.Ref.Posted
	|	AND TableOfCheckedProducts.Ref <> &DocumentReturnPolicy
	|
	|GROUP BY
	|	TableOfCheckedProducts.Products,
	|	TableOfCheckedProducts.Characteristic,
	|	TableOfCheckedProducts.Series,
	|	TableOfCheckedProducts.DocumentInflow
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	ReceiptData.Products,
	|	ReceiptData.Count - ISNULL(ReturnDocumentData.Count, 0) AS Count,
	|	ReceiptData.Characteristic,
	|	ReceiptData.Series,
	|	CASE
	|		WHEN ReceiptData.Package = ProductsToFillIn.Package
	|			THEN CASE
	|					WHEN ReceiptData.Package IS NULL 
	|							OR ReceiptData.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|						THEN ReceiptData.Count - ISNULL(ReturnDocumentData.Count, 0)
	|					ELSE (ReceiptData.Count - ISNULL(ReturnDocumentData.Count, 0)) / &QueryTextPackagingFactor1
	|				END
	|		ELSE CASE
	|				WHEN ProductsToFillIn.Package IS NULL 
	|						OR ProductsToFillIn.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|					THEN ReceiptData.Count - ISNULL(ReturnDocumentData.Count, 0)
	|				ELSE (ReceiptData.Count - ISNULL(ReturnDocumentData.Count, 0)) / &QueryTextPackagingFactor2
	|			END
	|	END AS NumberOfPackages,
	|	CASE
	|		WHEN ReceiptData.Count - ISNULL(ReturnDocumentData.Count, 0) = 0
	|			THEN ReceiptData.Price
	|		ELSE CASE
	|				WHEN ReceiptData.Package = ProductsToFillIn.Package
	|					THEN CASE
	|							WHEN ReceiptData.Package IS NULL 
	|									OR ReceiptData.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|								THEN ReceiptData.Sum / ReceiptData.Count
	|							ELSE ReceiptData.Sum / (ReceiptData.Count / &QueryTextPackagingFactor1)
	|						END
	|				ELSE CASE
	|						WHEN ProductsToFillIn.Package IS NULL 
	|								OR ProductsToFillIn.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|							THEN ReceiptData.Sum / ReceiptData.Count
	|						ELSE ReceiptData.Sum / (ReceiptData.Count / &QueryTextPackagingFactor2)
	|					END
	|			END
	|	END AS Price,
	|	ReceiptData.DocumentInflow
	|FROM
	|	ProductsToFillIn AS ProductsToFillIn
	|		LEFT JOIN ReceiptData AS ReceiptData
	|			LEFT JOIN ReturnDocumentData AS ReturnDocumentData
	|			ON ReceiptData.DocumentInflow = ReturnDocumentData.DocumentInflow
	|				AND ReceiptData.Products = ReturnDocumentData.Products
	|				AND ReceiptData.Characteristic = ReturnDocumentData.Characteristic
	|				AND ReceiptData.Series = ReturnDocumentData.Series
	|		ON ProductsToFillIn.Products = ReceiptData.Products
	|			AND ReceiptData.Characteristic = ProductsToFillIn.Characteristic
	|			AND ReceiptData.Series = ProductsToFillIn.Series
	|WHERE
	|	ReceiptData.Count - ISNULL(ReturnDocumentData.Count, 0) > 0
	|	AND ReceiptData.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|ORDER BY
	|	ReceiptData.DocumentInflow.Date DESC";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ReceiptData.Package",
		"ReceiptData.Products"));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductsToFillIn.Package",
		"ProductsToFillIn.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Partner", DocumentReturnPolicy.Partner);
	Query.SetParameter("Counterparty", DocumentReturnPolicy.Counterparty);
	Query.SetParameter("Organization", DocumentReturnPolicy.Organization);
	Query.SetParameter("Terms", DocumentReturnPolicy.Terms);
	Query.SetParameter("VATTaxation", DocumentReturnPolicy.VATTaxation);
	Query.SetParameter("GoodsTable", TableOfCheckedGoods);
	Query.SetParameter("DocumentReturnPolicy", DocumentReturnPolicy.Ref);
	Query.SetParameter("LineOfBusiness", DocumentReturnPolicy.LineOfBusiness);
	Query.SetParameter("ReturnDate", ?(ValueIsFilled(DocumentReturnPolicy.Date),DocumentReturnPolicy.Date,CurrentSessionDate()));
	
	QueryResult = Query.Execute().Unload();
	For Each LineProducts_ In TabularPartOfReturn Do
		FoundRows = QueryResult.FindRows(New Structure("Products, Characteristic, Series",
														LineProducts_.Products, LineProducts_.Characteristic, LineProducts_.Series));
		For Each FoundRow In FoundRows Do
			If LineProducts_.Count <= FoundRow.Count Then
				LineProducts_.DocumentInflow = FoundRow.DocumentInflow;
				LineProducts_.Price = FoundRow.Price;
				FoundRow.NumberOfPackages = FoundRow.NumberOfPackages - LineProducts_.NumberOfPackages;
				FoundRow.Count = FoundRow.Count - LineProducts_.Count;
				If FoundRow.Count = 0 Then
					QueryResult.Delete(FoundRow);
				EndIf;
			Else
				LineProducts_.DocumentInflow = FoundRow.DocumentInflow;
				LineProducts_.Price = FoundRow.Price;
				AddedRow = TabularPartOfReturn.Add();
				FillPropertyValues(AddedRow, LineProducts_);
				AddedRow.NumberOfPackages = LineProducts_.NumberOfPackages -  FoundRow.NumberOfPackages;
				AddedRow.Count = LineProducts_.Count - FoundRow.Count;
				LineProducts_.NumberOfPackages = FoundRow.NumberOfPackages;
				LineProducts_.Count = FoundRow.Count;
				QueryResult.Delete(FoundRow);
			EndIf;
			Break;
		EndDo;
		If FoundRows.Count() = 0 Then
			LineProducts_.DocumentInflow = Documents.VendorInvoice.EmptyRef();
			LineProducts_.Price = 0;
		EndIf;
	EndDo;
		
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(DocumentReturnPolicy);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartServer.TreatTS(TabularPartOfReturn, StructureOfActions, Undefined);
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. Should be used See PartnersProductsServer.FillInPartnerProductsByProductsInTable
// Fills in the supplier nomenclature when the supplier changes in the document
//
// Parameters:
//  Table - FormDataCollection, ValueTable - the table where you need to fill in the supplier's item.
//  Partner - CatalogRef.Partners - the supplier that the item belongs to.
//
Procedure FillInSupplierProductsInTable(Table, Partner) Export
	
	PartnersProductsServer.FillInPartnerProductsByProductsInTable(Table, Partner);

EndProcedure

// Deprecated. Should be used See PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner.
// Fills in the nomenclature, characteristics, and packaging in the supplier's nomenclature with an empty nomenclature.
//
// Parameters:
//  Goods - ValueTable - a table containing data for linking the item to the supplier's item.
//  Cancel - Boolean - True if the item could not be linked to the supplier's item.
//
Procedure LinkProductsToSupplierProducts(Goods, Cancel) Export

	PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);

EndProcedure

#EndRegion

#EndRegion

#Region Private

Function ProcurementConditionsTemplate()
	
	Return New Structure("
		|Terms,
		|Partner,
		|Counterparty,
		|Organization,
		|Currency,
		|ARAPCurrency,
		|PriceIncludesVAT,
		|Warehouse,
		|PaymentMethod,
		|ForeignCurrencyTransaction,
		|FinancialAccountingGroup,
		|CashFlowItem,
		|ShipmentDueDate,
		|BusinessOperation,
		|VendorPriceKind,
		|RegisterVendorPrices,
		|FinancialAccountingGroup,
		|CommissionFeeCalculationMethod,
		|RemunerationPercentage,
		|KeepCommissionFee,
		|ContractsAreUsed,
		|ARAPObjectSettings,
		|ReturnReusablePackage,
		|ReusablePackageReturnCycleLength,
		|CalculatePackageReturnDateAccordingToCalendar,
		|ScheduleOfPackageReturn,
		|PackageDepositIsRequired,
		|LineOfBusiness,
		|MinimumOrderAmount,
		|DeliveryDuration
		|");
		
EndFunction

Function RequestTextVerificationOfAcceptedGoodsByOrders(TypeOfReceipt)
	
	QueryTextByReferences = "";
	
	If TypeOfReceipt = Type("DocumentRef.VendorInvoice") Then
		
		QueryTextByReferences = 
		"SELECT
		|	GoodsReceipts.Products AS Products,
		|	GoodsReceipts.Characteristic AS Characteristic,
		|	GoodsReceipts.Series AS Series,
		|	GoodsReceipts.Warehouse AS Warehouse,
		|	SUM(GoodsReceipts.Count) AS NumberOfReceipts_1
		|INTO TTGoodsReceipts
		|FROM
		|	Document.VendorInvoice.Goods AS GoodsReceipts
		|WHERE
		|	CASE
		|			WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|				THEN GoodsReceipts.PurchaseOrder IN (&ReferenceArray)
		|			WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed), VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|				THEN GoodsReceipts.Ref.Terms = &Terms
		|			WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|				THEN GoodsReceipts.Ref.Contract = &Contract
		|		END
		|	AND GoodsReceipts.Ref <> &DocumentInflow
		|	AND GoodsReceipts.Ref.Posted
		|
		|GROUP BY
		|	GoodsReceipts.Products,
		|	GoodsReceipts.Characteristic,
		|	GoodsReceipts.Series,
		|	GoodsReceipts.Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	ElsIf TypeOfReceipt = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		
		QueryTextByReferences = 
		"SELECT
		|	GoodsReceipts.Products AS Products,
		|	GoodsReceipts.Characteristic AS Characteristic,
		|	GoodsReceipts.Series AS Series,
		|	GoodsReceipts.Ref.Warehouse AS Warehouse,
		|	SUM(GoodsReceipts.Count) AS NumberOfReceipts_1,
		|	GoodsReceipts.Ref.CorrectedDocument,
		|	GoodsReceipts.Ref.ReversedDocument
		|INTO TTGoodsReceiptsBeforeDeductionReverse
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsReceipts
		|WHERE
		|	GoodsReceipts.Ref <> &DocumentInflow
		|	AND GoodsReceipts.Ref.Posted
		|	AND CASE
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly),
		|			VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices))
		|			THEN GoodsReceipts.Ref.ReferenceOrder IN (&ReferenceArray)
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices),
		|			VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|			VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices))
		|			THEN GoodsReceipts.Ref.ReferenceOrder = &Contract
		|		ELSE FALSE
		|	END
		|GROUP BY
		|	GoodsReceipts.Products,
		|	GoodsReceipts.Characteristic,
		|	GoodsReceipts.Series,
		|	GoodsReceipts.Ref.Warehouse,
		|	GoodsReceipts.Ref.CorrectedDocument,
		|	GoodsReceipts.Ref.ReversedDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsReceipts.Products AS Products,
		|	GoodsReceipts.Characteristic AS Characteristic,
		|	GoodsReceipts.Series AS Series,
		|	GoodsReceipts.Ref.Warehouse AS Warehouse,
		|	-GoodsReceipts.Count AS NumberOfReceipts_1
		|INTO TTReversedDocuments
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsReceipts
		|WHERE
		|	GoodsReceipts.Ref IN
		|		(SELECT DISTINCT
		|			Table.CorrectedDocument
		|		FROM
		|			TTGoodsReceiptsBeforeDeductionReverse AS Table
		|
		|		UNION ALL
		|
		|		SELECT DISTINCT
		|			Table.ReversedDocument
		|		FROM
		|			TTGoodsReceiptsBeforeDeductionReverse AS Table)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataSet.Products AS Products,
		|	DataSet.Characteristic AS Characteristic,
		|	DataSet.Series AS Series,
		|	DataSet.Warehouse AS Warehouse,
		|	SUM(DataSet.NumberOfReceipts_1) AS NumberOfReceipts_1
		|INTO TTGoodsReceipts
		|FROM
		|	(SELECT
		|		GoodsReceipts.Products AS Products,
		|		GoodsReceipts.Characteristic AS Characteristic,
		|		GoodsReceipts.Series AS Series,
		|		GoodsReceipts.Warehouse AS Warehouse,
		|		GoodsReceipts.NumberOfReceipts_1 AS NumberOfReceipts_1
		|	FROM
		|		TTGoodsReceiptsBeforeDeductionReverse AS GoodsReceipts
		|
		|	UNION ALL
		|
		|	SELECT
		|		GoodsReceipts.Products AS Products,
		|		GoodsReceipts.Characteristic AS Characteristic,
		|		GoodsReceipts.Series AS Series,
		|		GoodsReceipts.Warehouse AS Warehouse,
		|		GoodsReceipts.NumberOfReceipts_1 AS NumberOfReceipts_1
		|	FROM
		|		TTReversedDocuments AS GoodsReceipts) AS DataSet
		|GROUP BY
		|	DataSet.Products,
		|	DataSet.Characteristic,
		|	DataSet.Series,
		|	DataSet.Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	ElsIf TypeOfReceipt = Type("DocumentRef.GoodsReceiptForStorage") Then
		
		QueryTextByReferences = 
		"SELECT
		|	GoodsReceipts.Products AS Products,
		|	GoodsReceipts.Characteristic AS Characteristic,
		|	GoodsReceipts.Series AS Series,
		|	GoodsReceipts.Warehouse AS Warehouse,
		|	SUM(GoodsReceipts.Count) AS NumberOfReceipts_1
		|INTO TTGoodsReceipts
		|FROM
		|	Document.GoodsReceiptForStorage.Goods AS GoodsReceipts
		|WHERE
		|	GoodsReceipts.Ref.Posted
		|	AND GoodsReceipts.Ref <> &DocumentInflow
		|	AND CASE
		|			WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|				THEN GoodsReceipts.PurchaseOrder IN (&ReferenceArray)
		|			WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed), VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|				THEN GoodsReceipts.Ref.Terms = &Terms
		|			WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|				THEN GoodsReceipts.Ref.Contract = &Contract
		|		END
		|
		|GROUP BY
		|	GoodsReceipts.Products,
		|	GoodsReceipts.Characteristic,
		|	GoodsReceipts.Series,
		|	GoodsReceipts.Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		
	ElsIf TypeOfReceipt = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		QueryTextByReferences = 
		"SELECT
		|	CASE
		|		WHEN Inpayment.Damage
		|			THEN Inpayment.ProductsRecordingAsReceived
		|		ELSE Inpayment.Products
		|	END AS Products,
		|	CASE
		|		WHEN Inpayment.Damage
		|			THEN Inpayment.CharacteristicRecordingAsReceived
		|		ELSE Inpayment.Characteristic
		|	END AS Characteristic,
		|	Inpayment.Series AS Series,
		|	Inpayment.Ref.Warehouse AS Warehouse,
		|	SUM(Inpayment.Count) AS NumberOfReceipts_1
		|INTO TTGoodsReceipts
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Goods AS Inpayment
		|WHERE
		|	&GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|	AND Inpayment.Ref.RequestForReturnOfGoodsFromCustomer IN(&ReferenceArray)
		|	AND Inpayment.Ref <> &DocumentInflow
		|	AND Inpayment.Ref.Posted
		|
		|GROUP BY
		|	CASE
		|		WHEN Inpayment.Damage
		|			THEN Inpayment.ProductsRecordingAsReceived
		|		ELSE Inpayment.Products
		|	END,
		|	CASE
		|		WHEN Inpayment.Damage
		|			THEN Inpayment.CharacteristicRecordingAsReceived
		|		ELSE Inpayment.Characteristic
		|	END,
		|	Inpayment.Series,
		|	Inpayment.Ref.Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	QueryTextByReferences = QueryTextByReferences + 
	"SELECT
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) AS Count
	|INTO TTProductsForRegistration_
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	NOT &FillInByReceipts
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND GoodsToReceive.DocumentInflow IN(&ArrayOfUserOrdersForRegister)
	|	AND GoodsToReceive.Warehouse IN(&Warehouse)
	|	AND GoodsToReceive.ToRegisterGoodsReceipts > 0
	|GROUP BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Warehouse
	|	
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterReceiptsByInvoices) AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	&FillInByReceipts
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND GoodsToReceive.DocumentInflow IN(&ArrayOfUserOrdersForRegister)
	|	AND GoodsToReceive.Warehouse IN(&Warehouse)
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Series,
	|	GoodsToReceive.Warehouse
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterReceiptsByInvoices) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProductsForRegistration_.Products AS Products,
	|	TTProductsForRegistration_.Characteristic AS Characteristic,
	|	TTProductsForRegistration_.Series AS Series,
	|	TTProductsForRegistration_.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TTProductsForRegistration_.Count > ISNULL(TTGoodsReceipts.NumberOfReceipts_1, 0)
	|			THEN TTProductsForRegistration_.Count - ISNULL(TTGoodsReceipts.NumberOfReceipts_1, 0)
	|		ELSE 0
	|	END AS Count
	|INTO TTUnformattedGoods
	|FROM
	|	TTProductsForRegistration_ AS TTProductsForRegistration_
	|		LEFT JOIN TTGoodsReceipts AS TTGoodsReceipts
	|		ON TTProductsForRegistration_.Products = TTGoodsReceipts.Products
	|			AND TTProductsForRegistration_.Characteristic = TTGoodsReceipts.Characteristic
	|			AND TTProductsForRegistration_.Series = TTGoodsReceipts.Series
	|			AND TTProductsForRegistration_.Warehouse = TTGoodsReceipts.Warehouse
	|WHERE
	|	TTProductsForRegistration_.Count - ISNULL(TTGoodsReceipts.NumberOfReceipts_1, 0) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(UnformulatedGoods.Count), 0) AS Count
	|FROM
	|	TTUnformattedGoods AS UnformulatedGoods";
	
	Return QueryTextByReferences;
	
EndFunction

Procedure SetOrderSelectionParameterInGoodsForReceiptRegister(Query)
	
	ReferenceArray = New Array;
	
	If Query.Parameters.GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
		
		If Query.Parameters.Property("ReferenceArray") Then
			ReferenceArray = Query.Parameters.ReferenceArray;
		Else
			ReferenceArray.Add(Query.Parameters.DocumentInflow);
		EndIf;
		
	ElsIf Query.Parameters.GoodsReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly Then
		
		ReferenceArray.Add(Query.Parameters.DocumentInflow);
		
	ElsIf Query.Parameters.GoodsReceiptOption = Enums.GoodsReceiptOptions.NotSeparatedByInvoices 
		Or Query.Parameters.GoodsReceiptOption = Enums.GoodsReceiptOptions.NotDividedByOrdersAndInvoices
		Or Query.Parameters.GoodsReceiptOption = Enums.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed Then
		
		ReferenceArray.Add(Query.Parameters.Terms);
		
	ElsIf Query.Parameters.GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterInvoices
		Or Query.Parameters.GoodsReceiptOption = Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices
		Or Query.Parameters.GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices Then
		
		ReferenceArray.Add(Query.Parameters.Contract);
		
	EndIf;
	
	Query.SetParameter("ArrayOfUserOrdersForRegister", ReferenceArray);
	
EndProcedure

Function RequestTextVerificationOfAcceptedGoodsByConsignmentNote()
	
	InvoiceRequestText = 
	"SELECT
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND GoodsToReceive.DocumentInflow IN (&ArrayOfUserOrdersForRegister)
	|	AND GoodsToReceive.Warehouse IN (&Warehouse)
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) > 0";
	
	Return InvoiceRequestText;
	
EndFunction

Function QueryTextByReferences(TypeOfReceipt)
	
	QueryTextByReferences = "";
	
	If TypeOfReceipt = Type("DocumentRef.VendorInvoice") Then
		
		QueryTextByReferences = 
		"SELECT
		|	CASE
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|			THEN GoodsReceipts.PurchaseOrder
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			THEN GoodsReceipts.Ref
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices), VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed))
		|			THEN GoodsReceipts.Ref.Terms
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN GoodsReceipts.Ref.Contract
		|		END AS ReferenceOrder,
		|	GoodsReceipts.Products AS Products,
		|	GoodsReceipts.Characteristic AS Characteristic,
		|	GoodsReceipts.Series AS Series,
		|	GoodsReceipts.Warehouse AS Warehouse,
		|	GoodsReceipts.Purpose AS Purpose,
		|	SUM(GoodsReceipts.Count) AS NumberOfReceipts_1
		|INTO TTGoodsReceipts
		|FROM
		|	Document.VendorInvoice.Goods AS GoodsReceipts
		|WHERE
		|	CASE
		|			WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|				THEN GoodsReceipts.PurchaseOrder IN (&ReferenceArray)
		|			WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices), VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed))
		|				THEN GoodsReceipts.Ref.Terms = &Terms
		|			WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|				THEN GoodsReceipts.Ref.Contract = &Contract
		|		END
		|	AND GoodsReceipts.Ref <> &Ref
		|	AND GoodsReceipts.Ref.Posted
		|
		|GROUP BY
		|	CASE
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|			THEN GoodsReceipts.PurchaseOrder
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			THEN GoodsReceipts.Ref
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices), VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed))
		|			THEN GoodsReceipts.Ref.Terms
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN GoodsReceipts.Ref.Contract
		|		END,
		|	GoodsReceipts.Products,
		|	GoodsReceipts.Characteristic,
		|	GoodsReceipts.Series,
		|	GoodsReceipts.Warehouse,
		|	GoodsReceipts.Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	ElsIf TypeOfReceipt = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		
		QueryTextByReferences = 
		"SELECT
		|	GoodsReceipts.Ref.ReferenceOrder AS ReferenceOrder,
		|	GoodsReceipts.Products AS Products,
		|	GoodsReceipts.Characteristic AS Characteristic,
		|	GoodsReceipts.Series AS Series,
		|	GoodsReceipts.Ref.Warehouse AS Warehouse,
		|	GoodsReceipts.Purpose AS Purpose,
		|	SUM(GoodsReceipts.Count) AS NumberOfReceipts_1,
		|	GoodsReceipts.Ref.CorrectedDocument,
		|	GoodsReceipts.Ref.ReversedDocument
		|INTO TTGoodsReceiptsBeforeDeductionReverse
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsReceipts
		|WHERE
		|	GoodsReceipts.Ref <> &Ref
		|	AND GoodsReceipts.Ref.Posted
		|	AND CASE
		|		WHEN &GoodsReceiptOption IN(VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly),
		|										VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices))
		|			THEN GoodsReceipts.Ref.ReferenceOrder IN(&ReferenceArray)
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices),
		|										VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|										VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices))
		|			THEN GoodsReceipts.Ref.ReferenceOrder = &Contract
		|		ELSE FALSE
		|	END
		|GROUP BY
		|	GoodsReceipts.Ref.ReferenceOrder,
		|	GoodsReceipts.Products,
		|	GoodsReceipts.Characteristic,
		|	GoodsReceipts.Series,
		|	GoodsReceipts.Ref.Warehouse,
		|	GoodsReceipts.Purpose,
		|	GoodsReceipts.Ref.CorrectedDocument,
		|	GoodsReceipts.Ref.ReversedDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsReceipts.Ref.ReferenceOrder AS ReferenceOrder,
		|	GoodsReceipts.Products AS Products,
		|	GoodsReceipts.Characteristic AS Characteristic,
		|	GoodsReceipts.Series AS Series,
		|	GoodsReceipts.Ref.Warehouse AS Warehouse,
		|	GoodsReceipts.Purpose AS Purpose,
		|	-GoodsReceipts.Count AS NumberOfReceipts_1
		|INTO TTReversedDocuments
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsReceipts
		|WHERE
		|	GoodsReceipts.Ref IN
		|		(SELECT DISTINCT
		|			Table.CorrectedDocument
		|		FROM
		|			TTGoodsReceiptsBeforeDeductionReverse AS Table
		|
		|		UNION ALL
		|
		|		SELECT DISTINCT
		|			Table.ReversedDocument
		|		FROM
		|			TTGoodsReceiptsBeforeDeductionReverse AS Table)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataSet.ReferenceOrder AS ReferenceOrder,
		|	DataSet.Products AS Products,
		|	DataSet.Characteristic AS Characteristic,
		|	DataSet.Series AS Series,
		|	DataSet.Warehouse AS Warehouse,
		|	DataSet.Purpose AS Purpose,
		|	SUM(DataSet.NumberOfReceipts_1) AS NumberOfReceipts_1
		|INTO TTGoodsReceipts
		|FROM
		|	(SELECT
		|		GoodsReceipts.ReferenceOrder AS ReferenceOrder,
		|		GoodsReceipts.Products AS Products,
		|		GoodsReceipts.Characteristic AS Characteristic,
		|		GoodsReceipts.Series AS Series,
		|		GoodsReceipts.Warehouse AS Warehouse,
		|		GoodsReceipts.Purpose AS Purpose,
		|		GoodsReceipts.NumberOfReceipts_1 AS NumberOfReceipts_1
		|	FROM
		|		TTGoodsReceiptsBeforeDeductionReverse AS GoodsReceipts
		|
		|	UNION ALL
		|
		|	SELECT
		|		GoodsReceipts.ReferenceOrder AS ReferenceOrder,
		|		GoodsReceipts.Products AS Products,
		|		GoodsReceipts.Characteristic AS Characteristic,
		|		GoodsReceipts.Series AS Series,
		|		GoodsReceipts.Warehouse AS Warehouse,
		|		GoodsReceipts.Purpose AS Purpose,
		|		GoodsReceipts.NumberOfReceipts_1 AS NumberOfReceipts_1
		|	FROM
		|		TTReversedDocuments AS GoodsReceipts) AS DataSet
		|GROUP BY
		|	DataSet.ReferenceOrder,
		|	DataSet.Products,
		|	DataSet.Characteristic,
		|	DataSet.Series,
		|	DataSet.Warehouse,
		|	DataSet.Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	ElsIf TypeOfReceipt = Type("DocumentRef.GoodsReceiptForStorage") Then
		
		QueryTextByReferences = 
		"SELECT
		|	CASE
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|			THEN GoodsReceipts.PurchaseOrder
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			THEN GoodsReceipts.Ref
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices), VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed))
		|			THEN GoodsReceipts.Ref.Terms
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN GoodsReceipts.Ref.Contract
		|		END AS ReferenceOrder,
		|	GoodsReceipts.Products AS Products,
		|	GoodsReceipts.Characteristic AS Characteristic,
		|	GoodsReceipts.Series AS Series,
		|	GoodsReceipts.Warehouse AS Warehouse,
		|	GoodsReceipts.Purpose,
		|	SUM(GoodsReceipts.Count) AS NumberOfReceipts_1
		|INTO TTGoodsReceipts
		|FROM
		|	Document.GoodsReceiptForStorage.Goods AS GoodsReceipts
		|WHERE
		|	GoodsReceipts.Ref.Posted
		|	AND GoodsReceipts.Ref <> &Ref
		|	AND CASE
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|			THEN GoodsReceipts.PurchaseOrder IN (&ReferenceArray)
		|		WHEN &GoodsReceiptOption IN (
		|				VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed))
		|			THEN GoodsReceipts.Ref.Terms = &Terms
		|	END
		|
		|GROUP BY
		|	CASE
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|			THEN GoodsReceipts.PurchaseOrder
		|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			THEN GoodsReceipts.Ref
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices), VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed))
		|			THEN GoodsReceipts.Ref.Terms
		|		WHEN &GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN GoodsReceipts.Ref.Contract
		|		END,
		|	GoodsReceipts.Products,
		|	GoodsReceipts.Characteristic,
		|	GoodsReceipts.Series,
		|	GoodsReceipts.Warehouse,
		|	GoodsReceipts.Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	ElsIf TypeOfReceipt = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		QueryTextByReferences = 
		"SELECT
		|	Inpayment.Ref AS ReferenceOrder,
		|	CASE
		|		WHEN Inpayment.Damage
		|			THEN Inpayment.ProductsRecordingAsReceived
		|		ELSE Inpayment.Products
		|	END AS Products,
		|	CASE
		|		WHEN Inpayment.Damage
		|			THEN Inpayment.CharacteristicRecordingAsReceived
		|		ELSE Inpayment.Characteristic
		|	END AS Characteristic,
		|	Inpayment.Series AS Series,
		|	Inpayment.Ref.Warehouse AS Warehouse,
		|	Inpayment.Purpose,
		|	SUM(Inpayment.Count) AS NumberOfReceipts_1
		|INTO TTGoodsReceipts
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Goods AS Inpayment
		|WHERE
		|	Inpayment.Ref.RequestForReturnOfGoodsFromCustomer IN(&ReferenceArray)
		|	AND Inpayment.Ref <> &Ref
		|	AND Inpayment.Ref.Posted
		|
		|GROUP BY
		|	Inpayment.Ref,
		|	CASE
		|		WHEN Inpayment.Damage
		|			THEN Inpayment.ProductsRecordingAsReceived
		|		ELSE Inpayment.Products
		|	END,
		|	CASE
		|		WHEN Inpayment.Damage
		|			THEN Inpayment.CharacteristicRecordingAsReceived
		|		ELSE Inpayment.Characteristic
		|	END,
		|	Inpayment.Series,
		|	Inpayment.Ref.Warehouse,
		|	Inpayment.Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	
	
	QueryTextByReferences = QueryTextByReferences +
	"SELECT
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Products AS Products,
	|	TRUE AS ThisIsAProduct,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) AS Count,
	|   GoodsToReceive.Purpose AS Purpose
	|INTO TTProductsForReceipt
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	NOT &FillInByReceipts
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND GoodsToReceive.DocumentInflow IN(&ArrayOfUserOrdersForRegister)
	|	AND GoodsToReceive.Warehouse IN(&Warehouse)
	|	AND GoodsToReceive.ToRegisterGoodsReceipts > 0
	|	AND NOT GoodsToReceive.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|GROUP BY
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Series,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.Purpose
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Products AS Products,
	|	TRUE AS ThisIsAProduct,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterReceiptsByInvoices) AS Count,
	|	GoodsToReceive.Purpose AS Purpose
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	&FillInByReceipts
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND GoodsToReceive.DocumentInflow IN(&ArrayOfUserOrdersForRegister)
	|	AND GoodsToReceive.Warehouse IN(&Warehouse)
	|	AND NOT GoodsToReceive.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|GROUP BY
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Series,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.Purpose
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterReceiptsByInvoices) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Products AS Products,
	|	FALSE AS ThisIsAProduct,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) AS Count,
	|	GoodsToReceive.Purpose AS Purpose
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	NOT &FillInByReceipts
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND GoodsToReceive.DocumentInflow IN(&ArrayOfUserOrdersForRegister)
	|	AND GoodsToReceive.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND GoodsToReceive.ToRegisterGoodsReceipts > 0
	|	AND GoodsToReceive.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|GROUP BY
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Series,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.Purpose
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Products AS Products,
	|	FALSE AS ThisIsAProduct,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterReceiptsByInvoices) AS Count,
	|	GoodsToReceive.Purpose AS Purpose
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	&FillInByReceipts
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND GoodsToReceive.DocumentInflow IN(&ArrayOfUserOrdersForRegister)
	|	AND GoodsToReceive.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND GoodsToReceive.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|GROUP BY
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Series,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.Purpose
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterReceiptsByInvoices) > 0
	|;
	|
	|SELECT
	|	TTProductsForReceipt.DocumentInflow AS ReferenceOrder,
	|	TTProductsForReceipt.Products AS Products,
	|	TTProductsForReceipt.Characteristic AS Characteristic,
	|	TTProductsForReceipt.Series AS Series,
	|	TTProductsForReceipt.Warehouse AS Warehouse,
	|	TTProductsForReceipt.Purpose AS Purpose,	
	|	CASE
	|		WHEN TTProductsForReceipt.Count > ISNULL(TTGoodsReceipts.NumberOfReceipts_1, 0)
	|			THEN TTProductsForReceipt.Count - ISNULL(TTGoodsReceipts.NumberOfReceipts_1, 0)
	|		ELSE 0
	|	END AS Count,
	|	FALSE AS ProductsAdded
	|FROM
	|	TTProductsForReceipt AS TTProductsForReceipt
	|		LEFT JOIN TTGoodsReceipts AS TTGoodsReceipts
	|			ON TTProductsForReceipt.DocumentInflow = TTGoodsReceipts.ReferenceOrder
	|			AND TTProductsForReceipt.Products = TTGoodsReceipts.Products
	|			AND TTProductsForReceipt.Characteristic = TTGoodsReceipts.Characteristic
	|			AND TTProductsForReceipt.Series = TTGoodsReceipts.Series
	|			AND TTProductsForReceipt.Warehouse = TTGoodsReceipts.Warehouse
	|			AND TTProductsForReceipt.Purpose = TTGoodsReceipts.Purpose
	|WHERE
	|	TTProductsForReceipt.Count - ISNULL(TTGoodsReceipts.NumberOfReceipts_1, 0) > 0
	|	AND ((TTProductsForReceipt.ThisIsAProduct AND TTProductsForReceipt.Warehouse IN(&Warehouse))
	|		OR (NOT TTProductsForReceipt.ThisIsAProduct AND TTProductsForReceipt.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)))
	|
	|ORDER BY
	|	Products,
	|	Characteristic
	|;
	|
	|SELECT
	|	Goods.PurchaseOrder AS PurchaseOrder,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Package AS Package,
	|	Goods.Purpose AS Purpose,	
	|	Goods.Count AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|;
	|
	|SELECT DISTINCT
	|	Goods.Products AS Products
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN TTProductsForReceipt AS TTProductsForReceipt
	|		ON Goods.Products = TTProductsForReceipt.Products
	|WHERE
	|	NOT CAST(Goods.Products AS Catalog.Products).ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|		AND TTProductsForReceipt.Products IS NULL
	|
	|;
	|
	|SELECT
	|	Goods.Package AS Package,
	|	&QueryTextPackagingFactor AS ZoomRatio
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|
	|;
	|
	|SELECT DISTINCT
	|	Goods.Warehouse AS Warehouse
	|FROM
	|	Goods AS Goods
	|WHERE
	|	NOT CAST(Warehouse AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsReceipt
	|	OR &Date < CAST(Warehouse AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsReceipt";
	
	QueryTextByReferences = StrReplace(QueryTextByReferences, 
		"&QueryTextPackagingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("Goods.Package", "Goods.Products"));
	
	Return QueryTextByReferences;
	
EndFunction

Function RequestTextForInvoiceOrAgreement()
	
	QueryText = 
		"SELECT
		|		GoodsReadyForReceiptBalance.Products AS Products,
		|		GoodsReadyForReceiptBalance.Characteristic AS Characteristic,
		|		GoodsReadyForReceiptBalance.Series AS Series,
		|		GoodsReadyForReceiptBalance.Purpose AS Purpose,
		|		GoodsReadyForReceiptBalance.Warehouse AS Warehouse,
		|		CASE
		|			WHEN &FillInByReceipts = TRUE THEN
		|				-GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance
		|			ELSE
		|				GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance
		|		END AS Count
		|INTO TTProductsForReceipt
		|	FROM
		|		AccumulationRegister.GoodsToReceive.Balance(
		|				,
		|				DocumentInflow IN (&ArrayOfUserOrdersForRegister)) AS GoodsReadyForReceiptBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsReadyForReceipt.Products,
		|		GoodsReadyForReceipt.Characteristic,
		|		GoodsReadyForReceipt.Series,
		|		GoodsReadyForReceipt.Purpose,
		|		GoodsReadyForReceipt.Warehouse,
		|		CASE
		|			WHEN &FillInByReceipts = TRUE THEN
		|				GoodsReadyForReceipt.ToRegisterReceiptsByInvoices
		|			ELSE
		|				GoodsReadyForReceipt.ToRegisterGoodsReceipts
		|		END AS Count
		|	FROM
		|		AccumulationRegister.GoodsToReceive AS GoodsReadyForReceipt
		|	WHERE
		|		GoodsReadyForReceipt.Recorder = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalanceTable.Products,
		|	BalanceTable.Characteristic,
		|	BalanceTable.Series,
		|	BalanceTable.Purpose,
		|	BalanceTable.Warehouse,
		|	SUM(BalanceTable.Count) AS Count,
		|	FALSE AS ProductsAdded
		|FROM
		|	TTProductsForReceipt AS BalanceTable
		|
		|GROUP BY
		|	BalanceTable.Products,
		|	BalanceTable.Characteristic,
		|	BalanceTable.Series,
		|	BalanceTable.Purpose,
		|	BalanceTable.Warehouse
		|
		|HAVING
		|	SUM(BalanceTable.Count) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Series AS Series,
		|	Goods.Purpose AS Purpose,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Package AS Package,
		|	Goods.Count AS Count
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.Products AS Products
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN TTProductsForReceipt AS TTProductsForReceipt
		|	ON Goods.Products = TTProductsForReceipt.Products
		|WHERE
		|	NOT CAST(Goods.Products AS Catalog.Products).ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TTProductsForReceipt.Products IS NULL
		|	
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Package AS Package,
		|	CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).Numerator /
		|	CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS ZoomRatio
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.Warehouse AS Warehouse
		|FROM
		|	Goods AS Goods
		|WHERE
		|	(NOT CAST(Goods.Warehouse AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsReceipt
		|			OR &Date < CAST(Goods.Warehouse AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsReceipt)";
		
	Return QueryText;
	
EndFunction

Procedure AdjustListOfSelectionOfBusinessOperationOfReceipt(Form) Export
	
	If Not Form.GetFormFunctionalOption("UsePurchaseCommission") Then
		
		ListItem = Form.Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ConsignmentProcurement);
		If ListItem <> Undefined Then
			Form.Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	If Not Form.GetFormFunctionalOption("UseManagementCompany") Then
		
		ListItem = Form.Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.PurchaseFromVendorLocal);
		If ListItem <> Undefined Then
			Form.Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	If Not Form.GetFormFunctionalOption("UseImports") Then
		
		ListItem = Form.Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.PurchaseByImport);
		If ListItem <> Undefined Then
			Form.Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	If Not Form.GetFormFunctionalOption("UseImportOfGoodsFromCustomsUnion") Then
		
		ListItem = Form.Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ImportFromEAEU);
		If ListItem <> Undefined Then
			Form.Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
EndProcedure

#Region ProceduresForCreatingTemporaryTables

// Generates a request to the document header and places it in a temporary table
//
// Parameters:
// QueryText     - String - text string to which you want to add the query text
// QueryOptions - Structure - structure containing request parameters
// DocumentPurchases  - DocumentObject - the object that you want to check.
//
Procedure CreateRequestTemporaryTablePurchaseDocumentHeader(QueryText,
	                                                              QueryOptions,
	                                                              Val DocumentPurchases)

	QueryText = QueryText + "
		|SELECT
		|	DocumentPurchases.Partner                                 AS Partner,
		|	DocumentPurchases.Counterparty                              AS Counterparty,
		|	DocumentPurchases.Currency                                  AS Currency,
		|	DocumentPurchases.ARAPCurrency                    AS ARAPCurrency,
		|	DocumentPurchases.PriceIncludesVAT                         AS PriceIncludesVAT,
		|	DocumentPurchases.VATTaxation                      AS VATTaxation,
		|	DocumentPurchases.BusinessOperation                   AS BusinessOperation,
		|	DocumentPurchases.Terms                              AS Terms,
		|	DocumentPurchases.Date                                    AS Date,
		|	DocumentPurchases.NotShipInInstallments                      AS NotShipInInstallments,
		|	DocumentPurchases.ApprovalDate                        AS ApprovalDate,
		|	DocumentPurchases.DateOfShipment                            AS DateOfShipment,
		|	DocumentPurchases.ThisIsOrder                                AS ThisIsOrder,
		|	DocumentPurchases.ARAPObjectSettings                         AS ARAPObjectSettings,
		|	DocumentPurchases.InvoiceForOrders                      AS InvoiceForOrders,
		|	DocumentPurchases.ReceiptUnderOrders                    AS ReceiptUnderOrders,
		|	DocumentPurchases.ByOrders                               AS ByOrders,
		|	DocumentPurchases.Organization                             AS Organization,
		|	DocumentPurchases.Warehouse                                   AS Warehouse,
		|	DocumentPurchases.PaymentMethod                             AS PaymentMethod,
		|	DocumentPurchases.DocumentAmount                          AS DocumentAmount,
		|	DocumentPurchases.CalculatePackageReturnDateAccordingToCalendar AS CalculatePackageReturnDateAccordingToCalendar,
		|	DocumentPurchases.ScheduleOfPackageReturn                   AS ScheduleOfPackageReturn,
		|	DocumentPurchases.ReusablePackageReturnCycleLength          AS ReusablePackageReturnCycleLength,
		|	DocumentPurchases.Contract                                 AS Contract
		|INTO
		|	TemporaryTableProcurementDocument
		|FROM
		|	&DocumentPurchases AS DocumentPurchases
		|;
		|";
	
	// We will form the necessary columns of the purchase document header table
	
	TypeCurrency   = New TypeDescription("CatalogRef.Currencies");
	DateType     = New TypeDescription("Date");
	BooleanType   = New TypeDescription("Boolean");
	NumberType    = New TypeDescription("Number");
	TypeBooleanUndefined = New TypeDescription("Boolean, Undefined");
	
	DocumentTable = New ValueTable();
	
	DocumentTable.Columns.Add("Partner",                              New TypeDescription("CatalogRef.Partners"));
	DocumentTable.Columns.Add("Counterparty",                           New TypeDescription("CatalogRef.Counterparties"));
	DocumentTable.Columns.Add("Currency",                               TypeCurrency);
	DocumentTable.Columns.Add("ARAPCurrency",                 TypeCurrency);
	DocumentTable.Columns.Add("PriceIncludesVAT",                      TypeBooleanUndefined);
	DocumentTable.Columns.Add("VATTaxation",                   New TypeDescription("EnumRef.VATTaxationTypes"));
	DocumentTable.Columns.Add("Date",                                 DateType);
	DocumentTable.Columns.Add("DateOfShipment",                         DateType);
	DocumentTable.Columns.Add("ApprovalDate",                     DateType);
	DocumentTable.Columns.Add("NotShipInInstallments",                   BooleanType);
	DocumentTable.Columns.Add("ThisIsOrder",                             BooleanType);
	DocumentTable.Columns.Add("InvoiceForOrders",                   BooleanType);
	DocumentTable.Columns.Add("ReceiptUnderOrders",                 BooleanType);
	DocumentTable.Columns.Add("ByOrders",                            BooleanType);
	DocumentTable.Columns.Add("ARAPObjectSettings",                      New TypeDescription("EnumRef.ARAPObjectSettings, Undefined"));
	DocumentTable.Columns.Add("Organization",                          New TypeDescription("CatalogRef.Companies"));
	DocumentTable.Columns.Add("Warehouse",                                New TypeDescription("CatalogRef.Warehouses"));
	DocumentTable.Columns.Add("PaymentMethod",                          New TypeDescription("EnumRef.PaymentForms, Undefined"));
	DocumentTable.Columns.Add("DocumentAmount",                       New TypeDescription("Number"));
	DocumentTable.Columns.Add("Terms",                           New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors"));
	DocumentTable.Columns.Add("BusinessOperation",                New TypeDescription("EnumRef.BusinessTransactions"));
	DocumentTable.Columns.Add("CalculatePackageReturnDateAccordingToCalendar", BooleanType);
	DocumentTable.Columns.Add("ScheduleOfPackageReturn",                New TypeDescription("CatalogRef.BusinessCalendars"));
	DocumentTable.Columns.Add("ReusablePackageReturnCycleLength",       NumberType);
	DocumentTable.Columns.Add("Contract",                              New TypeDescription("CatalogRef.CounterpartyContracts"));
	
	// Add a line and fill in the values from the header of the document
	
	NewRow = DocumentTable.Add();
	FillPropertyValues(NewRow, DocumentPurchases);
	
	NewRow.InvoiceForOrders = NewRow.ReceiptUnderOrders 
			Or NewRow.ByOrders;
	
	
	NewRow.ThisIsOrder = TypeOf(DocumentPurchases.Ref) = Type("DocumentRef.PurchaseOrder")
	;
	
	QueryOptions.Insert("DocumentPurchases", DocumentTable);

EndProcedure

// Generates a request to the PM for the document and puts It in a temporary table
//
// Parameters:
// QueryText           -String - text string to which you want to add the query text
// QueryOptions       - Structure - structure containing request parameters
// DocumentPurchases        - DocumentObject - the object that you want to check
// TableName             - String - name of the table to be queried.
//
Procedure GenerateTemporaryTableProductsQueryInPurchaseDocument(QueryText,
	                                                               QueryOptions,
	                                                               DocumentPurchases,
	                                                               TableName)
	
	TabularSectionPresentation = NStr("vi = 'Hàng hóa';
										|ru = 'Товары';
										|en = 'Goods'; fa = 'کالاها';
										|it = 'Merci';
										|pl = 'Wiersze pozycji';
										|tr = 'Ürünler'");
	TabularSectionName = "Goods";
	
	If TableName = "Document.PurchaseOrder" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Products           AS Products,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Price                   AS Price,
			|	Goods.Sum                  AS Sum,
			|	Goods.VATAmount               AS VATAmount,
			|	Goods.VendorPriceKind      AS VendorPriceKind,
			|	Goods.Package               AS Package,
			|	Goods.ExpenseItem         AS ExpenseItem,
			|	Goods.ToExpenseAs       AS ToExpenseAs,
			|	Goods.VATRate              AS VATRate,
			|	Goods.PercentRateOfManualDiscount    AS PercentRateOfManualDiscount,
			|	Goods.Warehouse                  AS Warehouse,
			|	Goods.Canceled               AS Canceled,
			|	Goods.DateOfReceipt        AS DateOfReceipt,
			|	Goods.Price - Goods.Price * Goods.PercentRateOfManualDiscount / 100 AS DiscountedPrice_
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|Characteristic,
			|PartnerProducts,
			|Price,
			|Sum,
			|VATAmount,
			|VendorPriceKind,
			|Package,
			|ExpenseItem,
			|ToExpenseAs,
			|VATRate,
			|PercentRateOfManualDiscount,
			|Warehouse,
			|Canceled,
			|DateOfReceipt";
		
	ElsIf TableName = "Document.VendorInvoice" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Products           AS Products,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Price                   AS Price,
			|	Goods.Sum                  AS Sum,
			|	Goods.VATAmount               AS VATAmount,
			|	Goods.VendorPriceKind      AS VendorPriceKind,
			|	Goods.Package               AS Package,
			|	Goods.ExpenseItem         AS ExpenseItem,
			|	Goods.ToExpenseAs       AS ToExpenseAs,
			|	Goods.VATRate              AS VATRate,
			|	Goods.PercentRateOfManualDiscount    AS PercentRateOfManualDiscount,
			|	Goods.Warehouse                  AS Warehouse,
			|	Goods.Price - Goods.Price * Goods.PercentRateOfManualDiscount / 100 AS DiscountedPrice_
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|Characteristic,
			|PartnerProducts,
			|Price,
			|Sum,
			|VATAmount,
			|VendorPriceKind,
			|Package,
			|ExpenseItem,
			|ToExpenseAs,
			|VATRate,
			|PercentRateOfManualDiscount,
			|Warehouse";
			
	ElsIf TableName = "Document.CustomerInvoiceIntercompany" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.ToExpenseAs       AS ToExpenseAs,
			|	Goods.Products           AS Products
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products
			|;
			|";
			
		ColumnsNames = "LineNumber,
		|ToExpenseAs,
		|Products";
		
	ElsIf TableName = "Document.DiscrepancyReportFollowingReceipt" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Products           AS Products,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Warehouse                  AS Warehouse,
			|	Goods.ToExpenseAs       AS ToExpenseAs,
			|	Goods.Package               AS Package
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|Characteristic,
			|PartnerProducts,
			|Warehouse,
			|ToExpenseAs,
			|Package";
			
		
	ElsIf TableName = "Document.IssuedLetterOfAuthority" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Products           AS Products,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Package               AS Package
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|Characteristic,
			|PartnerProducts,
			|Package";
			
	ElsIf TableName = "Document.RedemptionOfReturnablePackagingFromVendor" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Products           AS Products,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Package               AS Package
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|Characteristic,
			|PartnerProducts,
			|Package";
		
	ElsIf TableName = "Document.PurchaseAdjustment" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Products           AS Products,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Price                   AS Price,
			|	Goods.Sum                  AS Sum,
			|	Goods.VATAmount               AS VATAmount,
			|	Goods.Package               AS Package,
			|	Goods.ExpenseItem         AS ExpenseItem,
			|	Goods.ToExpenseAs       AS ToExpenseAs,
			|	Goods.VATRate              AS VATRate,
			|	Goods.Warehouse                  AS Warehouse
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|Characteristic,
			|PartnerProducts,
			|Price,
			|Sum,
			|VATAmount,
			|Package,
			|ExpenseItem,
			|ToExpenseAs,
			|VATRate,
			|Warehouse";
		
	ElsIf TableName = "Document.ReturnOfGoodsToVendor" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.Products           AS Products,
			|	Goods.Purpose             AS Purpose,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Price                   AS Price,
			|	Goods.Warehouse                  AS Warehouse,
			|	FALSE				          AS ToExpenseAs,
			|	Goods.VATAmount               AS VATAmount,
			|	Goods.VATRate              AS VATRate,
			|	Goods.Sum                  AS Sum,
			|	Goods.Package               AS Package
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|Purpose,
			|Characteristic,
			|Price,
			|VATAmount,
			|VATRate,
			|Sum,
			|Warehouse,
			|Package";
		
	ElsIf TableName = "Document.GoodsShipmentFromStorage" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.Products           AS Products,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Purpose             AS Purpose,
			|	Goods.SalesOrder           AS SalesOrder,
			|	FALSE                          AS ToExpenseAs,
			|	Goods.Price                   AS Price,
			|	Goods.Sum                  AS Sum,
			|	0                             AS VATAmount,
			|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
			|	Goods.Warehouse                  AS Warehouse,
			|	Goods.Package               AS Package
			|
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|PartnerProducts,
			|Characteristic,
			|Purpose,
			|SalesOrder,
			|Price,
			|Sum,
			|Warehouse,
			|Package";
		
	ElsIf TableName = "Document.GoodsReceiptForStorage" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Products           AS Products,
			|	Goods.Characteristic         AS Characteristic,
			|	ISNULL(&VendorPriceKind, VALUE(Catalog.VendorPriceTypes.EmptyRef)) AS VendorPriceKind,
			|	FALSE					      AS ToExpenseAs,
			|	Goods.Price                   AS Price,
			|	Goods.Price                   AS DiscountedPrice_,
			|	Goods.Sum                  AS Sum,
			|	Goods.Package               AS Package,
			|	Goods.Warehouse                  AS Warehouse
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|Characteristic,
			|PartnerProducts,
			|Price,
			|Sum,
			|Package,
			|Warehouse";
		
		QueryOptions.Insert("VendorPriceKind", DocumentPurchases.VendorPriceKind);

	ElsIf TableName = "Document.RedemptionOfGoodsFromStorage" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.Products           AS Products,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Package               AS Package,
			|	Goods.Price                   AS Price,
			|	Goods.VATRate              AS VATRate,
			|	Goods.Sum                  AS Sum,
			|	Goods.VATAmount               AS VATAmount,
			|	Goods.Warehouse                  AS Warehouse,
			|	Goods.Department          AS Department,
			|	Goods.Contract                AS Contract
			|
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|PartnerProducts,
			|Characteristic,
			|Package,
			|Price,
			|VATRate,
			|VATAmount,
			|Sum,
			|Warehouse,
			|Department,
			|Contract";
			

	ElsIf TableName = "Document.ReportOnVMIAdjustment" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation  AS TabularSectionPresentation,
			|	&TabularSectionName            AS TabularSectionName,
			|	Goods.LineNumber            AS LineNumber,
			|	Goods.Products           AS Products,
			|	Goods.PartnerProducts   AS ProductCrossReference,
			|	Goods.Characteristic         AS Characteristic,
			|	Goods.Package               AS Package,
			|	Goods.Price                   AS Price,
			|	Goods.Sum                  AS Sum,
			|	Goods.Warehouse                  AS Warehouse,
			|	Goods.Department          AS Department,
			|	Goods.Contract                AS Contract
			|
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|
			|INDEX BY
			|	Products,
			|	Characteristic
			|;
			|";
			
		ColumnsNames = "LineNumber,
			|Products,
			|PartnerProducts,
			|Characteristic,
			|Package,
			|Price,
			|Sum,
			|Warehouse,
			|Department,
			|Contract";
	ElsIf TableName = "Document.MovementOfProductsAndMaterials" Then
		
		QueryText = QueryText + "
			|SELECT
			|	&TabularSectionPresentation    AS TabularSectionPresentation,
			|	&TabularSectionName              AS TabularSectionName,
			|	Goods.LineNumber              AS LineNumber,
			|	Goods.Products             AS Products,
			|	CAST(Goods.ReferenceOrder AS Document.ProductionStage2_2) AS ReferenceOrder
			|INTO TemporaryTableOfGoods_
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products
			|;
			|";
		
		TabularSectionPresentation = Documents.MovementOfProductsAndMaterials.FieldsPresentation(DocumentPurchases).Goods;
		
		ColumnsNames = "LineNumber,
			|Products,
			|ReferenceOrder
			|";
		
	
	ElsIf TableName = "Document.PurchaseRequest" Then
		
		QueryText = QueryText + "
		|SELECT
		|	&TabularSectionPresentation  AS TabularSectionPresentation,
		|	&TabularSectionName            AS TabularSectionName,
		|	Goods.LineNumber            AS LineNumber,
		|	Goods.PartnerProducts   AS ProductCrossReference,
		|	Goods.Products           AS Products,
		|	Goods.Characteristic         AS Characteristic,
		|	Goods.Price                   AS Price,
		|	Goods.Price                   AS DiscountedPrice_,
		|	Goods.Sum                  AS Sum,
		|	Goods.VATAmount               AS VATAmount,
		|	Goods.Partner                AS Partner,
		|	Goods.Counterparty             AS Counterparty,
		|	Goods.Terms             AS Terms,
		|	Goods.Contract                AS Contract,
		|	Goods.VendorPriceKind      AS VendorPriceKind,
		|	Goods.Package               AS Package,
		|	Goods.VATRate              AS VATRate,
		|	Goods.Warehouse                  AS Warehouse,
		|	Goods.Canceled               AS Canceled,
		|	FALSE                          AS ToExpenseAs
		|INTO TemporaryTableOfGoods_
		|FROM
		|	&Goods AS Goods
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
		ColumnsNames = 
		"LineNumber,
		|PartnerProducts,
		|Products,
		|Characteristic,
		|Price,
		|Sum,
		|VATAmount,
		|Partner,
		|Counterparty,
		|Terms,
		|Contract,
		|VendorPriceKind,
		|Package,
		|VATRate,
		|Warehouse,
		|Canceled";
			
	EndIf;
	
	QueryOptions.Insert("Goods", DocumentPurchases[TabularSectionName].Unload(,ColumnsNames));
	QueryOptions.Insert("TabularSectionName", TabularSectionName);
	QueryOptions.Insert("TabularSectionPresentation", TabularSectionPresentation);
	
EndProcedure

// Generates a query for currency exchange rates on the date of the document and puts it in a temporary table.
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateQueryTemporaryTableCurrencyExchangeRates(QueryText)

	QueryText = QueryText + "
	|SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS
	|		RelativeExchangeRatesSliceLast
	|INDEX BY
	|	Currency
	|;
	|";

EndProcedure

// Generates a request to the PM Stages of payment of the document and puts it in a temporary table
//
// Parameters:
//		QueryText     - String - text string to which you want to add the query text
//		QueryOptions - Structure - structure containing request parameters
//		DocumentPurchases  - DocumentObject, DocumentRef - document to make a request for
//		ByReference_         - Boolean - flag if True check is performed by reference to an object
//		TableName       - String - name of the document table to be queried.
//
Procedure CreateRequestTemporaryTablePaymentStages(QueryText, QueryOptions, DocumentPurchases, ByReference_ = False, TableName = "")

	If ByReference_ Then
		
		QueryText = QueryText + "
			|SELECT
			|	PaymentScheduleSteps.LineNumber     AS LineNumber,
			|	PaymentScheduleSteps.PaymentOption   AS PaymentOption,
			|	PaymentScheduleSteps.CalculateFrom  AS CalculateFrom,   
			|	PaymentScheduleSteps.Move           AS Move,
			|	PaymentScheduleSteps.PaymentDate     AS PaymentDate,
			|	PaymentScheduleSteps.PaymentPercentage  AS PaymentPercentage,
			|	PaymentScheduleSteps.PaymentPercentage  AS PackageDepositPercentage
			|INTO
			|	TimeTableStagesOfPaymentSchedule
			|FROM
			|	&NameOfPaymentScheduleStagesTable AS PaymentScheduleSteps
			|WHERE
			|	PaymentScheduleSteps.Ref = &DocumentPurchases
			|INDEX BY
			|	LineNumber
			|;
			|";
			
			QueryText = StrReplace(QueryText, "&NameOfPaymentScheduleStagesTable", TableName + ".PaymentScheduleSteps");
			QueryOptions.Insert("DocumentPurchases", DocumentPurchases);
		
	Else
		
		QueryText = QueryText + "
			|SELECT
			|	PaymentScheduleSteps.LineNumber     AS LineNumber,
			|	PaymentScheduleSteps.PaymentOption   AS PaymentOption,
			|	PaymentScheduleSteps.CalculateFrom  AS CalculateFrom,
			|	PaymentScheduleSteps.Move           AS Move,
			|	PaymentScheduleSteps.PaymentDate     AS PaymentDate,
			|	PaymentScheduleSteps.PaymentPercentage  AS PaymentPercentage,
			|	PaymentScheduleSteps.PaymentPercentage  AS PackageDepositPercentage
			|INTO
			|	TimeTableStagesOfPaymentSchedule
			|FROM
			|	&PaymentScheduleSteps AS PaymentScheduleSteps
			|;
			|";
	
		QueryOptions.Insert("PaymentScheduleSteps", DocumentPurchases.PaymentScheduleSteps.Unload(, "LineNumber,PaymentDate,PaymentOption,CalculateFrom,Move,PaymentPercentage"));
		
	EndIf;
		
EndProcedure

// Generates a query for items in the "Warehouses" directory and places them in a temporary table
// To the correct warehouses are:
// 		- Warehouse equal to the agreement warehouse from the temporary table for the document
// 		- Warehouses, included in a hierarchy of the warehouse agreement from a temporary table in the document.
//
Procedure GenerateRequestTemporaryTableWarehousesCorrectByAgreement(QueryText)
	
	QueryText = QueryText + "
	|SELECT
	|	Warehouses.Ref AS Warehouse
	|INTO WarehousesAreCorrectByAgreement
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|LEFT JOIN
	|	TemporaryTableProcurementDocument AS TemporaryDocumentTable
	|ON
	|	TRUE
	|WHERE
	|	TemporaryDocumentTable.Terms.Warehouse IS NOT NULL
	|	AND TemporaryDocumentTable.Terms.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND Warehouses.Ref IN HIERARCHY
	|			(SELECT
	|				TemporaryDocumentTable.Terms.Warehouse
	|			FROM
	|				TemporaryTableProcurementDocument AS TemporaryDocumentTable)
	|;
	|";
	
EndProcedure

// Generates queries for items in the Warehouses Catalog and places them in a temporary table
// Correct warehouses include:
// 		- A warehouse equal to the warehouse of the agreement from the document table
// 		- Warehouses included in the agreement warehouse hierarchy from the document table.
//
Procedure CreateQueryTempTableWarehousesCorrectByAgreement(QueryText,  QueryOptions, DocumentPurchases)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	TermsOfPurchaseFromVendors.Ref AS Terms,
		|	Warehouses.Ref AS Warehouse,
		|	Warehouses.IsFolder AS WarehouseGroup_
		|INTO AgreementWarehouses
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON TermsOfPurchaseFromVendors.Warehouse = Warehouses.Ref
		|WHERE
		|	TermsOfPurchaseFromVendors.Ref IN(&Terms1)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AgreementWarehouses.Warehouse AS Warehouse
		|FROM
		|	AgreementWarehouses AS AgreementWarehouses
		|WHERE
		|	AgreementWarehouses.WarehouseGroup_";
	
	Query.SetParameter("Terms1", DocumentPurchases.Goods.UnloadColumn("Terms"));
	
	PackageResult = Query.ExecuteBatchWithIntermediateData();
	Selection = PackageResult[0].Select();
	
	GroupWarehouses_ = PackageResult[1].Unload().UnloadColumn("Warehouse");
	WarehouseHierarchy_ = New Map;
	QueryingHierarchy = New Query;
	HierarchyTexts = New Array;
	For ElementIndex = 0 To GroupWarehouses_.UBound() Do
		
		WarehouseGroup_ = GroupWarehouses_.Get(ElementIndex);
		ParameterName = "Warehouse" + Format(ElementIndex, "NG=0");
		
		HierarchyQueryText = StrReplace(
		"SELECT
		|	&Warehouse AS Parent,
		|	Warehouses.Ref AS Item
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref IN HIERARCHY(&Warehouse)",
		"&Warehouse", "&" + ParameterName);
		
		HierarchyTexts.Add(HierarchyQueryText);
		QueryingHierarchy.SetParameter(ParameterName, WarehouseGroup_);
		
	EndDo;
	
	If ValueIsFilled(HierarchyTexts) Then
		QueryingHierarchy.Text = StrConcat(HierarchyTexts, TMCommonUse.QuerySeparatorInJoin());
		HierarchySelection = QueryingHierarchy.Execute().Select();
		While HierarchySelection.Next() Do
			
			GroupItems1 = WarehouseHierarchy_.Get(HierarchySelection.Parent);
			If GroupItems1 = Undefined Then
				GroupItems1 = New Array;
				WarehouseHierarchy_.Insert(HierarchySelection.Parent, GroupItems1);
			EndIf;
			
			GroupItems1.Add(HierarchySelection.Item);
			
		EndDo;
	EndIf;
	
	AgreementWarehouses = New ValueTable;
	AgreementWarehouses.Columns.Add("Terms", New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors"));
	AgreementWarehouses.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	
	While Selection.Next() Do
		
		WarehouseHierarchy = WarehouseHierarchy_.Get(Selection.Warehouse); 
		If Not ValueIsFilled(WarehouseHierarchy) Then
			WarehouseHierarchy = CommonClientServer.ValueInArray(Selection.Warehouse);
		EndIf;
		
		For Each Warehouse In WarehouseHierarchy Do
			
			TableRow = AgreementWarehouses.Add();
			TableRow.Terms = Selection.Terms;
			TableRow.Warehouse = Warehouse;
			
		EndDo;
		
	EndDo;
	
	QueryOptions.Insert("AgreementWarehouses", AgreementWarehouses);
	QueryText = QueryText + 
	"SELECT
	|	AgreementWarehouses.Terms AS Terms,
	|	AgreementWarehouses.Warehouse AS Warehouse
	|INTO WarehousesAreCorrectByTerms
	|FROM
	|	&AgreementWarehouses AS AgreementWarehouses"
	+ Common.QueryBatchSeparator();

EndProcedure

#EndRegion

#Region ProceduresForGeneratingRequestsAndCheckingCorrectnessOfFillingInDocuments

// Generates the Query Text to check the availability of services and works in the purchase document
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForAvailabilityOfServicesAndWorksInPurchaseDocument(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	DocumentGoods.LineNumber                  AS LineNumber,
		|	DocumentGoods.Products                 AS Products,
		|	DocumentGoods.Products.ItemsType AS ItemsType
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products.ItemsType NOT IN
		|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure

// Generates the Query Text to check the availability of works in the purchase document
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForAvailabilityOfWorksInPurchaseDocument(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	DocumentGoods.LineNumber                  AS LineNumber,
		|	DocumentGoods.Products                 AS Products,
		|	DocumentGoods.Products.ItemsType AS ItemsType
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure

// Generates the Query Text to check whether the purchase document contains lines with a item type other than the "Work" type.
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForAvailabilityOfItemsOfServicesInPurchasingDocument(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	DocumentGoods.LineNumber                  AS LineNumber,
		|	DocumentGoods.Products                 AS Products,
		|	DocumentGoods.Products.ItemsType AS ItemsType
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure

// Generates the Query Text to check the availability of traceable works in the purchase document
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForTraceableWorksInPurchaseDocument(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	DocumentGoods.LineNumber                  AS LineNumber,
		|	DocumentGoods.Products                 AS Products,
		|	DocumentGoods.Products.ItemsType AS ItemsType
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND DocumentGoods.Products.TracedGoods
		|	AND &UseTraceableImportedGoodsAccounting
		|	AND BEGINOFPERIOD(&Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
		|
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure

// Generates the request text to check whether the service Analytics for services are full in the purchase document.
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForCorrectnessOfFillingOutServiceAnalytics(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	DocumentGoods.LineNumber  AS LineNumber,
		|	DocumentGoods.Products AS Products
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
		|	AND DocumentGoods.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure

// Generates the request body for the verification of occupancy of the warehouse
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestWhetherWarehouseIsFilledInCorrectly(QueryText)
	
	QueryText = QueryText + "
		|SELECT TOP 1
		|	TRUE AS ThereAreErrorsFillingWarehouse
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|LEFT JOIN
		|	TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
		|ON
		|	TRUE
		|WHERE
		|	TemporaryTableOfGoods_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND NOT TemporaryTableOfGoods_.ToExpenseAs
		|	AND TemporaryTableProcurementDocument.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|;
		|";
	
EndProcedure

// Generates the request text to check whether the "Warehouse" details are filled in the rows of the table part of the goods
// The check should only be performed if:
// 		- the item type item is selected in the table part row;
//
Procedure GenerateRequestForCorrectnessOfFillingWarehousesInTablePartProductsWithoutWarehouseInHeader(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
		|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|WHERE
		|	TemporaryTableOfGoods_.Products.ItemsType IN
		|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND NOT TemporaryTableOfGoods_.ToExpenseAs
		|	AND TemporaryTableOfGoods_.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|;
		|";
	
EndProcedure

// Generates the request text to check whether the "Warehouse" details are filled in the rows of the table part of the goods
// The check should only be performed if:
// 		- the item type item is selected in the table part row;
// 		- the "Warehouse"field is filled in in the document header.
//
Procedure GenerateRequestForCorrectFillingOfWarehousesInProductsTabularSection(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
		|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|LEFT JOIN
		|	TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
		|ON
		|	TRUE
		|WHERE
		|	TemporaryTableProcurementDocument.Warehouse.IsFolder
		|	AND TemporaryTableProcurementDocument.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|	AND TemporaryTableOfGoods_.Products.ItemsType IN
		|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND NOT TemporaryTableOfGoods_.ToExpenseAs
		|	AND TemporaryTableOfGoods_.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|;
		|";
	
EndProcedure

// Generates checks to monitor the completion of order receipts
// and to monitor the completion of order payments.
//
// Parameters:
// ControlledOrder - DocumentRef.PurchaseOrder - controlled document.
// Cancel - Boolean - the opt-Out parameter.
//
Procedure PerformOrderControlAfterConducting(ControlledOrder, Cancel) Export
	
	Query = New Query("
		|SELECT
		|	PurchaseOrdersBalance.PurchaseOrder AS PurchaseOrder
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, 
		|			PurchaseOrder = &Ref
		|			AND PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|			AND PurchaseOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|			AND PurchaseOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
		|	) AS PurchaseOrdersBalance
		|WHERE
		|	&MonitorReceipt
		|	AND &UseStatuses
		|	AND (PurchaseOrdersBalance.OrderedBalance <> 0 
		|		OR PurchaseOrdersBalance.ToRegisterBalance <> 0)
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow AS PurchaseOrder
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, 
		|			DocumentInflow = &Ref
		|			AND CAST(DocumentInflow AS Document.PurchaseOrder).Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|			AND CAST(DocumentInflow AS Document.PurchaseOrder).BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|			AND CAST(DocumentInflow AS Document.PurchaseOrder).BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
		|	) AS GoodsToReceiveBalance
		|WHERE
		|	&MonitorReceipt
		|	AND &UseStatuses
		|	AND ((GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance + GoodsToReceiveBalance.AcceptsBalance) <> 0
		|		OR GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance <> 0)
		|;
		|
		|SELECT
		|	VendorsARAPAccountingBalance.Currency AS Currency,
		|	-1*(VendorsARAPAccountingBalance.AmountDueBalance) AS AmountDueBalance
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(, 
		|			ARAPObject.Object = &Ref
		|	) AS VendorsARAPAccountingBalance
		|WHERE
		|	&MonitorCalculations
		|	AND &UseStatuses
		|	AND VendorsARAPAccountingBalance.AmountDueBalance < 0
		|	AND CAST(ARAPObject.Object AS Document.PurchaseOrder).Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|	AND CAST(ARAPObject.Object AS Document.PurchaseOrder).BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|	AND CAST(ARAPObject.Object AS Document.PurchaseOrder).BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
		|");
		
	MonitorReceipt = GetFunctionalOption("DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived");
	MonitorCalculations     = GetFunctionalOption("DoNotClosePurchaseOrdersWithoutCompletePayment");
	UseStatuses       = GetFunctionalOption("UsePurchaseOrderStatuses");
	
	Query.SetParameter("Ref",                    ControlledOrder);
	Query.SetParameter("MonitorReceipt", MonitorReceipt);
	Query.SetParameter("MonitorCalculations",     MonitorCalculations);
	Query.SetParameter("UseStatuses",       UseStatuses);
	
	Result = Query.ExecuteBatch(); 
	
	SampleReceipt = Result[0].Select();
	SampleCalculations_  = Result[1].Select();
	
	If SampleReceipt.Next() Then 
		If TypeOf(ControlledOrder) = Type("DocumentRef.PurchaseOrder") Then
			ErrorText = NStr("vi = 'Chứng từ ""%OrderDocument%"" đã tiếp nhận không đầy đủ.
			|Chỉ có thể đóng tháng với các dòng đã tiếp nhận/hủy bỏ toàn bộ';
			|ru = 'Документ ""%OrderDocument%"" поступил не полностью.
			|Закрытие заказа возможно только с полностью поступившими/отмененными строками';
			|en = 'The ""%OrderDocument%"" document is received incompletely.
			|Order can be closed only with lines fully received/canceled'; fa = 'The ""%OrderDocument%"" document is received incompletely.
			|Order can be closed only with lines fully received/canceled';
			|it = 'Il documento ""%OrderDocument%"" non è arrivato completamente.
			| L''ordine si può chiudere solamente solo se le righe sono completamente ricevute o eliminate.';
			|pl = 'Dokument ""%OrderDocument%"" wpłynął nie w całości.
			|Zamknięcie zamówienia jest możliwe tylko z całkowicie otrzymanymi/anulowanymi wierszami';
			|tr = '""%OrderDocument%"" belgesi tam olarak alınmadı.
			|Bir siparişin kapatılması yalnızca tamamen girilen/iptal edilen satırlarla mümkündür'");
		EndIf;
		
		ErrorText = StrReplace(ErrorText, "%OrderDocument%", ControlledOrder);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ControlledOrder,
			,
			,
			Cancel);
	EndIf;
	
	If SampleCalculations_.Next() Then 
		If TypeOf(ControlledOrder) = Type("DocumentRef.PurchaseOrder") Then
			ErrorText = NStr("vi = 'Chưa hoàn thành thanh toán theo chứng từ ""%OrderDocument%"".
			|Để đóng đơn hàng, cần thanh toán %AmountToPay% %Currency%.
			|Chỉ có thể đóng đơn hàng với các dòng đã thanh toán/hủy bỏ toàn bộ';
			|ru = 'Расчеты по документу ""%OrderDocument%"" не завершены.
			|Для закрытия заказа требуется оплата %AmountToPay% %Currency%.
			|Закрытие заказа возможно только с полностью оплаченными/отмененными строками';
			|en = 'Settlements against the ""%OrderDocument%"" document are not completed.
			|To close the order, payment is required: %AmountToPay% %Currency%.
			|You can close the order only with fully paid/canceled lines'; fa = 'Settlements against the ""%OrderDocument%"" document are not completed.
			|To close the order, payment is required: %AmountToPay% %Currency%.
			|You can close the order only with fully paid/canceled lines';
			|it = 'I calcoli relativi al documento ""%OrderDocument%"" non sono completi.
			|Per la chiusura dell''ordine è necessario il pagamento %AmountToPay% %Currency%. 
			| La chiusura dell''ordine è possibile solamente se le voci sono completamente pagate/eliminate.';
			|pl = 'Obliczenia wg dokumentu ""%OrderDocument%"" nie są zakończone.
			|W celu zamknięcia zamówienia jest konieczna płatność %AmountToPay% %Currency%.
			|Zamknięcie zamówienia jest możliwe tylko z całkowicie opłaconymi/anulowanymi wierszami';
			|tr = '""%OrderDocument%"" belgesindeki ödemeler tamamlanmadı.
			|Bir siparişi kapatmak için %AmountToPay% %Currency% ödenmesi gerekiyor.
			|Bir siparişin kapatılması yalnızca tamamen ödenen/iptal edilen satırlarla mümkündür'");
		EndIf;
		
		ErrorText = StrReplace(ErrorText, "%OrderDocument%",        ControlledOrder);
		ErrorText = StrReplace(ErrorText, "%AmountToPay%", String(SampleCalculations_.AmountDueBalance));
		ErrorText = StrReplace(ErrorText, "%Currency%",       String(SampleCalculations_.Currency));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ControlledOrder,
			,
			,
			Cancel);
	EndIf;
	
EndProcedure

// Generates the request text for monitoring the completion of order receipt
// and for monitoring the completion of order calculations.
//
//	Returns:
//		String - Query text
//
Function RequestTextOrderControlAfterExecution() Export
	
	Return "
		|SELECT
		|	ARAPObjects.Ref AS ARAPObject,
		|	ARAPObjects.Object AS Object
		|INTO ObjectsOfCalculationsControlOfOrderAfterCarryingOut
		|FROM Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object IN (&DocumentsArray)
		|	AND NOT ARAPObjects.DeletionMark
		|;
		|SELECT DISTINCT
		|	ClosingControl.PurchaseOrder AS PurchaseOrder
		|INTO
		|	TTOrderBalances_
		|FROM (SELECT
		|	PurchaseOrdersBalance.PurchaseOrder AS PurchaseOrder
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, 
		|			PurchaseOrder IN (&DocumentsArray)
		|			AND &Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|			AND PurchaseOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|			AND PurchaseOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
		|	) AS PurchaseOrdersBalance
		|WHERE
		|	&MonitorReceipt
		|	AND &UseStatuses
		|	AND (PurchaseOrdersBalance.OrderedBalance > 0 
		|		OR PurchaseOrdersBalance.ToRegisterBalance > 0)
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow AS PurchaseOrder
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, 
		|			DocumentInflow IN (&DocumentsArray)
		|			AND CAST(DocumentInflow AS Document.PurchaseOrder).Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|			AND CAST(DocumentInflow AS Document.PurchaseOrder).BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|			AND CAST(DocumentInflow AS Document.PurchaseOrder).BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
		|	) AS GoodsToReceiveBalance
		|WHERE
		|	&MonitorReceipt
		|	AND &UseStatuses
		|	AND (GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance + GoodsToReceiveBalance.AcceptsBalance) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Object AS PurchaseOrder
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(, 
		|			ARAPObject IN (SELECT ARAPObject FROM ObjectsOfCalculationsControlOfOrderAfterCarryingOut)
		|			AND &Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|	) AS VendorsARAPAccountingBalance
		|	INNER JOIN ObjectsOfCalculationsControlOfOrderAfterCarryingOut AS ARAPObjects
		|		ON ARAPObjects.ARAPObject = VendorsARAPAccountingBalance.ARAPObject
		|WHERE
		|	&MonitorCalculations
		|	AND &UseStatuses
		|	AND VendorsARAPAccountingBalance.AmountDueBalance < 0
		|	AND ARAPObjects.Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|	AND ARAPObjects.Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
		|	AND ARAPObjects.Object.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|	AND ARAPObjects.Object.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)) AS ClosingControl
		|;"
	
EndFunction

// Generates the request text to check whether the "place of Storage" details are filled in the rows of the table part of the goods.
//
// Parameters:
// 	QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForCorrectFillingOfStorageLocations(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
		|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|WHERE
		|	TemporaryTableOfGoods_.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|	AND TemporaryTableOfGoods_.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|	AND TemporaryTableOfGoods_.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|;
		|";
	
EndProcedure

#EndRegion

#Region ProceduresForGeneratingRequestsToVerifyComplianceOfDocumentsWithTermsOfPurchase

// Generates the request text for checking the header of the purchase document
//
// Parameters:
// 	QueryText - String - text string to which you want to add the query text.
// 	TableName - String - the name of the document table that checks are performed on.
//
Procedure GenerateRequestPurchaseDocumentHeader(QueryText, TableName)
	
	GenerateRequestToVerifyTermsOfPurchase(QueryText, TableName, True);

EndProcedure

// Generates the request text for checking the PM Products of the purchase document
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
// TableName - String - the name of the document table that checks are performed on.
Procedure GenerateRequestProductsOfPurchaseDocument(QueryText, TableName)

	GenerateRequestToVerifyTermsOfPurchase(QueryText, TableName, False);
	
EndProcedure

// Generates the Query Text for checking the purchase conditions
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text.
//  TableName - String - the name of the document table that checks are performed on.
//  ThisIsCapCheck - Boolean - Defines the type of checks: header or tabular part.
Procedure GenerateRequestToVerifyTermsOfPurchase(QueryText, TableName, ThisIsCapCheck)
	
	SelectedFields = New Array;
	
	If Not ThisIsCapCheck Then
		SelectedFields.Add("TemporaryTableOfGoods_.LineNumber AS LineNumber"); // @query-part
	EndIf;
	
	// Initialization of the description of the placement of Attributes:
	PlacementHeader   = "Header";
	Placement_Table = "Table";
	
	PlacementOfAttributes = New Structure;
	PlacementOfAttributes.Insert("Partner",         PlacementHeader);
	PlacementOfAttributes.Insert("Counterparty",      PlacementHeader);
	PlacementOfAttributes.Insert("Organization",     PlacementHeader);
	PlacementOfAttributes.Insert("PaymentMethod",     PlacementHeader);
	PlacementOfAttributes.Insert("Currency",          PlacementHeader);
	PlacementOfAttributes.Insert("PriceIncludesVAT", PlacementHeader);
	PlacementOfAttributes.Insert("Terms",      PlacementHeader);
	
	PlacementOfAttributes.Insert("VendorPriceKind", Placement_Table);
	
	CheckCanceledLines = True;
	
	// Non-standard placement of Attributes:
	If TableName = "Document.PurchaseRequest" Then
		PlacementOfAttributes.Partner    = Placement_Table;
		PlacementOfAttributes.Counterparty = Placement_Table;
		PlacementOfAttributes.Terms = Placement_Table;
		
		CheckCanceledLines = False;
	EndIf;
	
	AddAgreementChecks = AddVerificationByAgreement(PlacementOfAttributes, "Terms", ThisIsCapCheck);
	
	#Region CheckingAttributesOfSameNameForCompliance
	For Each VerificationDescription In DescriptionOfChecksOfComplianceOfValuesWithAgreement() Do
		
		AttributeName = VerificationDescription.AttributeName;
		EmptyValue = VerificationDescription.EmptyValueInRequest;
		
		If VerificationDescription.CalculationOfConditionsHasBeenRedefined Then
			Continue;
		EndIf;
		
		If Not AddVerificationByAgreement(PlacementOfAttributes, AttributeName, ThisIsCapCheck) Then
			Continue;
		EndIf;
		
		ConditionText = "TermsOfPurchases.AttributeName IS NOT NULL // The Agreement Is Specified
		|		AND DocumentPurchases.AttributeName <> UNDEFINED // The Attribute exists in the document
		|		AND &CheckingForEmptyValueInAgreement // The value in the agreement is filled in
		|		AND &CheckingForEmptyValueInDocument // The value in the document is filled in
		|		AND TermsOfPurchases.AttributeName <> DocumentPurchases.AttributeName AS FieldNameThereAreErrors,
		|	PRESENTATION(TermsOfPurchases.AttributeName) AS AttributeNameAgreement,
		|	PRESENTATION(DocumentPurchases.AttributeName) AS AttributeName"; // @query-part

		RowToReplace = "&CheckingForEmptyValueInAgreement";
		If IsBlankString(EmptyValue) Then
			ConditionText = StrReplace(ConditionText, RowToReplace, "TRUE");
		Else
			ConditionText = StrReplace(
				ConditionText, 
				RowToReplace,
				"TermsOfPurchases.AttributeName <> " + EmptyValue);
		EndIf;
		
		RowToReplace = "&CheckingForEmptyValueInDocument";
		If Not VerificationDescription.OnlyWhenValueInDocumentIsFilledIn Or IsBlankString(EmptyValue) Then
			ConditionText = StrReplace(ConditionText, RowToReplace, "TRUE");
		Else
			ConditionText = StrReplace(
				ConditionText, 
				RowToReplace,
				"DocumentPurchases.AttributeName <> " + EmptyValue);
		EndIf;
		
		If PlacementOfAttributes[AttributeName] = Placement_Table Then
			ConditionText = StrReplace(ConditionText, "DocumentPurchases", "TemporaryTableOfGoods_");
		EndIf;
		
		ConditionText = StrReplace(ConditionText, "FieldNameThereAreErrors", VerificationDescription.FieldNameThereAreErrors);
		ConditionText = StrReplace(ConditionText, "AttributeName", AttributeName);
		
		SelectedFields.Add(ConditionText);
		
	EndDo;
	#EndRegion
	
	WorkWithReusablePackagingIsSupported = TableName <> "Document.PurchaseRequest";
	
	#Region CheckingAgreementByParameters	
	If AddAgreementChecks And WorkWithReusablePackagingIsSupported Then
		
		ConditionTemplate = "TermsOfPurchases.%1 IS NOT NULL
		|	AND TermsOfPurchases.%1 <> &%2 AS %3"; // @query-part
		
		ConditionText = StrTemplate(
			ConditionTemplate,
			"ReturnReusablePackage",
			"ReturnOfMultiTurnContainers",
			"ThereAreFillingErrorsToReturnMultiTurnContainer");
		SelectedFields.Add(ConditionText);
		
		ConditionText = StrTemplate(
			ConditionTemplate,
			"PackageDepositIsRequired",
			"PackageDepositIsRequired",
			"ThereAreFillingErrorsDepositForContainerIsRequired");
		SelectedFields.Add(ConditionText);
	
	EndIf;
	#EndRegion
	
	If AddAgreementChecks Then
		SelectedFields.Add("TermsOfPurchases.Status IS NOT NULL AND
			|	TermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.NotApproved) AS ThereAreErrorsAgreementStatus"); // @query-part
	EndIf;
	
	#Region BusinessOperation
	If AddAgreementChecks
		And TableName <> "Document.PurchaseRequest" // There is no business of operation
		Then
		
		SelectedFields.Add(
		"CASE
		|		WHEN NOT TermsOfPurchases.BusinessOperation IS NULL
		|			AND NOT DocumentPurchases.BusinessOperation IS NULL
		|			AND DocumentPurchases.BusinessOperation <> TermsOfPurchases.BusinessOperation
		|			AND DocumentPurchases.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
		|			AND NOT DocumentPurchases.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
		|				VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))
		|		THEN
		|			TRUE
		|		WHEN
		|			DocumentPurchases.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
		|			AND TermsOfPurchases.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|			AND NOT TermsOfPurchases.BusinessOperation IS NULL
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsFillingBusinessOperation,
		|	PRESENTATION(DocumentPurchases.BusinessOperation) AS BusinessOperation,
		|	PRESENTATION(TermsOfPurchases.BusinessOperation) AS BusinessTransactionAgreement"); // @query-part
		
	EndIf;
	#EndRegion
	
	#Region Warehouse
	CheckWarehouseByAgreementInTabularPart = False;
	If ThisIsCapCheck And AddAgreementChecks Then
		// Checking the warehouse in the header by agreement in the header:
		SelectedFields.Add(
		"TermsOfPurchases.Warehouse IS NOT NULL
		|		AND TermsOfPurchases.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|		AND WarehousesAreCorrectByAgreement.Warehouse IS NULL AS ThereAreErrorsFillingWarehouse,
		|	ISNULL(TermsOfPurchases.Warehouse.IsFolder, FALSE) AS WarehouseAgreementIsGroup,
		|	PRESENTATION(DocumentPurchases.Warehouse) AS Warehouse,
		|	PRESENTATION(TermsOfPurchases.Warehouse) AS WarehouseAgreement"); // @query-part
	ElsIf TableName = "Document.PurchaseRequest" Then
		// Inspection of the warehouse in TS by agreement in TS:
		SelectedFields.Add(
		"TemporaryTableOfGoods_.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|		AND TermsOfPurchases.Warehouse IS NOT NULL
		|		AND TermsOfPurchases.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|		AND WarehousesAreCorrectByTerms.Warehouse IS NULL AS ThereAreErrorsFillingWarehouse,
		|	ISNULL(TermsOfPurchases.Warehouse.IsFolder, FALSE) AS WarehouseAgreementIsGroup,
		|	ISNULL(DocumentPurchases.Warehouse.IsFolder, FALSE) AS WarehouseInGroupHeader,
		|	PRESENTATION(TemporaryTableOfGoods_.Warehouse) AS Warehouse,
		|	PRESENTATION(TermsOfPurchases.Warehouse) AS WarehouseAgreement"); // @query-part
		
		CheckWarehouseByAgreementInTabularPart = True;
	EndIf;
	#EndRegion
		
	If ThisIsCapCheck And AddAgreementChecks Then
		#Region ARAPObjectSettings
		SelectedFields.Add( 
		"DocumentPurchases.ARAPObjectSettings <> UNDEFINED // The Attribute exists in the document
		|	AND ISNULL(DocumentPurchases.ARAPObjectSettings <> CASE 
		|		WHEN TermsOfPurchases.ContractsAreUsed THEN
		|			DocumentPurchases.Contract.ARAPObjectSettings
		|		ELSE
		|			TermsOfPurchases.ARAPObjectSettings
		|		END, FALSE) AS ThereAreErrorsFillingOrderOfCalculations,
		|	PRESENTATION(CASE
		|		WHEN TermsOfPurchases.ContractsAreUsed
		|			THEN DocumentPurchases.Contract.ARAPObjectSettings
		|		ELSE TermsOfPurchases.ARAPObjectSettings
		|	END) AS SettlementProcedureAgreement,
		|	TermsOfPurchases.ContractsAreUsed AS ContractsAreUsed"); // @query-part
		#EndRegion
	EndIf;
	
	If TableName = "Document.VendorInvoice" Then
		#Region ARAPCurrency
		// Verification also uses the currency of the agreement, but the field is added to the mandatory currency verification.
		SelectedFields.Add(
		"TermsOfPurchases.Currency IS NOT NULL AND
		|		DocumentPurchases.ARAPCurrency <> TermsOfPurchases.Currency
		|		AND DocumentPurchases.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|		AND DocumentPurchases.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale) 
		|			AS ThereAreErrorsInFillingOutCurrencyOfMutualSettlements,
		|	PRESENTATION(DocumentPurchases.ARAPCurrency) AS ARAPCurrency,
		|	PRESENTATION(TermsOfPurchases.Currency) AS CurrencyOfSettlementsAgreement"); // @query-part
		#EndRegion
	EndIf;
	
	#Region ReusablePackage
	If TableName = "Document.VendorInvoice" Then 
		SelectedFields.Add("TRUE AS ThereAreErrorsReturnDateOfMultiTurnContainer,
		|	TermsOfPurchases.CalculatePackageReturnDateAccordingToCalendar AS CalculatePackageReturnDateAccordingToCalendar,
		|	TermsOfPurchases.ScheduleOfPackageReturn AS ScheduleOfPackageReturn"); // @query-part
	ElsIf WorkWithReusablePackagingIsSupported Then
		SelectedFields.Add(
		"CASE
		|		WHEN DocumentPurchases.ReusablePackageReturnCycleLength <> TermsOfPurchases.ReusablePackageReturnCycleLength
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreErrorsInFillingReturnPeriodOfMultiTurnContainers"); // @query-part
	EndIf;
	SelectedFields.Add("&ReturnOfMultiTurnContainers AS ReturnOfMultiTurnContainers,
		|	TermsOfPurchases.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength"); // @query-part
	#EndRegion
	
	If Not ThisIsCapCheck Then
		#Region MaximumAllowablePrice
		
		ConditionText = 
		"PRESENTATION(TemporaryTableOfGoods_.Products) AS Products,
		|	PRESENTATION(TemporaryTableOfGoods_.Characteristic) AS Characteristic,
		|	PRESENTATION(DocumentPurchases.Currency) AS PriceCurrency,
		|	&MaximumAllowablePrice AS MaximumAllowablePrice,
		|	ISNULL(TermsOfPurchases.ControlPurchasePrices, FALSE)
		|		AND PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Price IS NOT NULL
		|		AND TemporaryTableOfGoods_.Price > &MaximumAllowablePrice AS ThereAreErrorsMaximumAllowablePrice"; // @query-part
		
		TextMaximumAllowablePrice = "
		|	// Maximum allowable price
		|	CASE
		|		WHEN
		|			PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Price IS NULL
		|		THEN
		|			0
		|		ELSE
		|			CAST(
		|			CASE
		|				WHEN
		|					TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				THEN
		|					&QueryTextPackagingFactor1
		|				ELSE
		|					1
		|			END
		|			* PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Price/ISNULL(&QueryTextPackagingFactor2,1)
		|			* CASE
		|				WHEN DocumentPurchases.Currency <> PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency
		|					THEN CASE
		|							WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
		|								AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
		|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
		|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
		|							THEN
		|								(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
		|								/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
		|							ELSE 0
		|						END
		|				ELSE
		|					1
		|			END AS NUMBER(31,2))
		|	END"; // @query-part
		
		TextMaximumAllowablePrice = StrReplace(TextMaximumAllowablePrice,
			"&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TemporaryTableOfGoods_.Package",
			"TemporaryTableOfGoods_.Products"));
		
		TextMaximumAllowablePrice = StrReplace(TextMaximumAllowablePrice,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
			"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
			
		ConditionText = StrReplace(ConditionText, "&MaximumAllowablePrice", TextMaximumAllowablePrice);
		SelectedFields.Add(ConditionText);
		#EndRegion
	EndIf;
	
	If ThisIsCapCheck Then
		QueryTextChecks = 
		"SELECT
		|	&SelectedFields
		|FROM
		|	TemporaryTableProcurementDocument AS DocumentPurchases
		|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
		|		ON DocumentPurchases.Terms = TermsOfPurchases.Ref
		|		LEFT JOIN WarehousesAreCorrectByAgreement AS WarehousesAreCorrectByAgreement
		|		ON DocumentPurchases.Warehouse = WarehousesAreCorrectByAgreement.Warehouse"; // @query-part
	Else
		QueryTextChecks = 
		"SELECT
		|	&SelectedFields
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|		LEFT JOIN TemporaryTableProcurementDocument AS DocumentPurchases
		|		ON (TRUE)
		|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
		|		ON (TemporaryTableOfGoods_.Terms = TermsOfPurchases.Ref)
		|// ThereAreErrorsMaximumAllowablePrice
		|LEFT JOIN
		|	InformationRegister.ItemsPricesOfVendor.SliceLast(ENDOFPERIOD(&DATE, DAY),
		|				(Partner, VendorPriceKind, Products, Characteristic) IN (&SelectionOfItemPricesVendorPriceType)
		|) AS PricesOfSupplierNomenclatureCrossSectionOfTheLatest
		|ON
		|	TemporaryTableOfGoods_.Partner = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Partner
		|	AND TemporaryTableOfGoods_.VendorPriceKind = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.VendorPriceKind
		|	AND TemporaryTableOfGoods_.Products = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products
		|	AND TemporaryTableOfGoods_.Characteristic = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Characteristic 
		|	AND TermsOfPurchases.ControlPurchasePrices
		|LEFT JOIN
		|	InformationRegister.RelativeExchangeRates.SliceLast(&DATE, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
		|ON 
		|	PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
		|	
		|LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&DATE,
		|				Currency IN
		|				(SELECT
		|					TemporaryTableProcurementDocument.Currency
		|				FROM
		|					TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument)
		|					AND BaseCurrency = &BaseCurrency
		|) AS Currency_Rates
		|	ON TRUE"; // @query-part
		
		If CheckWarehouseByAgreementInTabularPart Then
			QueryTextChecks = QueryTextChecks + "
			|	LEFT JOIN WarehousesAreCorrectByTerms AS WarehousesAreCorrectByTerms
			|	ON TemporaryTableOfGoods_.Terms = WarehousesAreCorrectByTerms.Terms 
			|		AND TemporaryTableOfGoods_.Warehouse = WarehousesAreCorrectByTerms.Warehouse"; // @query-part
		EndIf;
		
		LinkToPurchaseDocumentIsRequired = PlacementOfAttributes.Partner = PlacementHeader;
		
		SelectionOfItemPricesVendorPriceType =
		"SELECT
		|	TemporaryTableOfGoods_.Partner AS Partner,
		|	TemporaryTableOfGoods_.VendorPriceKind AS VendorPriceKind,
		|	TemporaryTableOfGoods_.Products AS Products,
		|	TemporaryTableOfGoods_.Characteristic AS Characteristic
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_"
			+ ?(LinkToPurchaseDocumentIsRequired, "
			|	LEFT JOIN TemporaryTableProcurementDocument AS DocumentPurchases ON (TRUE)", "");
		
		QueryTextChecks = StrReplace(QueryTextChecks,
		"&SelectionOfItemPricesVendorPriceType",
		SelectionOfItemPricesVendorPriceType);
		
		If PlacementOfAttributes.Terms = PlacementHeader Then
			QueryTextChecks = StrReplace(
				QueryTextChecks,
				"TemporaryTableOfGoods_.Terms",
				"DocumentPurchases.Terms");
		EndIf;
		
		If PlacementOfAttributes.Partner = PlacementHeader Then
			QueryTextChecks = StrReplace(
				QueryTextChecks,
				"TemporaryTableOfGoods_.Partner",
				"DocumentPurchases.Partner");
		EndIf;
		
		If Not CheckCanceledLines Then
			QueryTextChecks = QueryTextChecks + "
			|WHERE
			|	NOT TemporaryTableOfGoods_.Canceled"; // @query-part
		EndIf;
		
	EndIf;
	
	QueryTextChecks = StrReplace(QueryTextChecks,
		"&SelectedFields",
		StrConcat(SelectedFields, ",
		|	")) + Common.QueryBatchSeparator();
		
	QueryText = QueryText + QueryTextChecks;
	
EndProcedure

Function AddVerificationByAgreement(PlacementOfAttributes, AttributeName, ThisIsCapCheck)
	
	If PlacementOfAttributes.Terms = "Table"
		And ThisIsCapCheck Then
		// You can't check the header by agreement if the agreement is in the table part.
		Return False;
		
	EndIf;
	
	Return 
		// The agreement is always checked if it is in the table part:
		PlacementOfAttributes.Terms = "Table"
		// The placement of the Attribute coincides with the verification option:
		Or PlacementOfAttributes[AttributeName] = "Header" = ThisIsCapCheck;
	
EndFunction

// A list of object fields, a description of their verification for compliance with the Attributes values in the agreement, 
// as well as text templates for displayed messages.
// 
// Returns:
//  ValueTable:
//   * AttributeName - String - The name of the Attributes of the document and the agreement.
//   * FieldNameThereAreErrors - String - Alias for the request field containing the boolean flag for errors found in the check.
//   * AttributeRepresentation - String - Presentation of the Attribute name for output to the report.
//   * EmptyValueInRequest - String - If it is not empty, then the Attribute verification is performed only if 
//                                     the value in the agreement differs from the specified one (checking that the value in the agreement is filled in).
//   * OnlyWhenValueInDocumentIsFilledIn - Boolean - If it is True and the Attribute is not filled in in the document, the check is not performed
//                                                      so as not to duplicate the message about the lack of filling.
//   * CalculationOfConditionsHasBeenRedefined - Boolean - Verification is not performed according to the standard comparison condition, but messages are output by a similar algorithm.
//
//   * ErrorTemplateInHeader - String - Template for the message text displayed if 
//                                     the Attribute is in the header of the document.
//   * ErrorTemplateInTable - String - Template for the message text displayed if
//                                     the Attribute is in the tabular part of the document.
//   * ErrorTemplateInHeaderForReport - String - Template for the message text displayed in the report if
//                                     the Attribute is in the header of the document.
//   * ErrorTemplateInTableForReport - String - Template for the text of the message displayed in the report if
//                                     the Attribute is in the table part of the document.
//   * AgreementSelectionErrorTemplateInTable - String - Template for the text of a message displayed in an error or report if
//                                     the Attribute in the document is "primary" and the error is displayed on an incorrectly selected agreement in the table part.
//   * ErrorTemplateDifferencesFromStandardAgreement - String - Template for the message text displayed if 
//                                     the Attribute is in the header of the agreement.
//   * ErrorTemplateDifferencesFromStandardAgreementForReport - String - Template for the message text to be displayed in the report if 
//                                     the Attribute is in the header of the agreement.
Function DescriptionOfChecksOfComplianceOfValuesWithAgreement()
	
	StringTypeDetails150 = Common.StringTypeDetails(150);
	DescriptionOfUnlimitedStringType = Common.StringTypeDetails(0);
	BooleanTypeDetails = New TypeDescription("Boolean");
	
	ReturnValue = New ValueTable;
	ReturnValue.Columns.Add("AttributeName",                                     StringTypeDetails150);
	ReturnValue.Columns.Add("FieldNameThereAreErrors",                                StringTypeDetails150);
	ReturnValue.Columns.Add("AttributeRepresentation",                           StringTypeDetails150);
	ReturnValue.Columns.Add("EmptyValueInRequest",                           StringTypeDetails150);
	ReturnValue.Columns.Add("OnlyWhenValueInDocumentIsFilledIn",           BooleanTypeDetails); 
	ReturnValue.Columns.Add("CalculationOfConditionsHasBeenRedefined",                       BooleanTypeDetails);
	
	// The message texts are identical, but they are formed explicitly for each case for the correct operation of the translation of strings into other languages.
	ReturnValue.Columns.Add("ErrorTemplateInHeader",                               DescriptionOfUnlimitedStringType);
	ReturnValue.Columns.Add("ErrorTemplateInTable",                             DescriptionOfUnlimitedStringType);
	ReturnValue.Columns.Add("ErrorTemplateInHeaderForReport",                      DescriptionOfUnlimitedStringType);
	ReturnValue.Columns.Add("ErrorTemplateInTableForReport",                    DescriptionOfUnlimitedStringType);
	ReturnValue.Columns.Add("AgreementSelectionErrorTemplateInTable",             DescriptionOfUnlimitedStringType);
	ReturnValue.Columns.Add("ErrorTemplateDifferencesFromStandardAgreement",          DescriptionOfUnlimitedStringType);
	ReturnValue.Columns.Add("ErrorTemplateDifferencesFromStandardAgreementForReport", DescriptionOfUnlimitedStringType);
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"BusinessOperation",
		"ThereAreErrorsFillingBusinessOperation",
		NStr("ru = 'Операция';
			|vi = 'Transaction';
			|en = 'Transaction'; fa = 'تراکنش';
			|it = 'Transaction';
			|pl = 'Transaction';
			|tr = 'İşlem'"));
	VerificationDescription.CalculationOfConditionsHasBeenRedefined = True;
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Операция не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = 'İşlem, ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Операция не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The transaction must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = 'İşlem, ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от операции в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki işlemden farklıdır'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от операции в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the transaction in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"" ""%ValueOfAgreementAttribute%"" anlaşmasının %TabularSectionName% listesinin %LineNumber% satırında bulunan işlemden farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Операция в соглашении (%ValueOfAgreementAttribute%) не должна отличаться от операции в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The transaction in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the transaction in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The transaction in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the transaction in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The transaction in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the transaction in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The transaction in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the transaction in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The transaction in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the transaction in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki işlem (%DocumentAttributeValue%) belgesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan işlemden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от операции в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"" , ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki işlemden farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от операции в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the transaction in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"" , ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki işlemden farklıdır.'");
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"ARAPCurrency",
		"ThereAreErrorsInFillingOutCurrencyOfMutualSettlements",
		NStr("ru = 'Валюта взаиморасчетов';
			|vi = 'AR/AP currency';
			|en = 'AR/AP currency'; fa = 'ارز دریافتنی/پرداختنی';
			|it = 'Valuta di regolamento dei conti';
			|pl = 'Waluta rozliczeń wzajemnych';
			|tr = 'Alacak/borç para birimi'"));
	VerificationDescription.CalculationOfConditionsHasBeenRedefined = True;
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Валюта взаиморасчетов"" не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The AR/AP currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The AR/AP currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The AR/AP currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The AR/AP currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The AR/AP currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = 'Uzlaşma para birimi, ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklı olmamalıdır.'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Валюта взаиморасчетов"" не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The AR/AP currency must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The AR/AP currency must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The AR/AP currency must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The AR/AP currency must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The AR/AP currency must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = 'Uzlaşma para birimi, ""%ValueOfAgreementAttribute%""  sözleşmesindeki %TabularSectionName%listesinin %LineNumber%satırında bulunan değerden farklı olmamalıdır.'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от валюты взаиморасчетов в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"" , ""%ValueOfAgreementAttribute%"" anlaşmasındaki uzlaşma para biriminden farklıdır.'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от валюты взаиморасчетов в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"" ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan  uzlaşma para biriminden farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Валюта взаиморасчетов"" в соглашении (%ValueOfAgreementAttribute%) не должна отличаться от валюты взаиморасчетов в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the AR/AP currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the AR/AP currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the AR/AP currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the AR/AP currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The AR/AP currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the AR/AP currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki uzlaşma para birimi, (%DocumentAttributeValue%) belgesindeki %TabularSectionName%listesinin %LineNumber% satırında bulunan uzlaşma para biriminden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от валюты взаиморасчетов в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"" ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki uzlaşma para biriminden farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от валюты взаиморасчетов в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the AR/AP currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"" ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki uzlaşma para biriminden farklıdır'");
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"Partner",
		"ThereAreErrorsInFillingOutPartner",
		NStr("ru = 'Партнер';
			|vi = 'Partner';
			|en = 'Partner'; fa = 'شریک تجاری';
			|it = 'Partner';
			|pl = 'Partner';
			|tr = 'İş ortağı'"),
		"VALUE(Catalog.Partners.EmptyRef)");
	VerificationDescription.OnlyWhenValueInDocumentIsFilledIn = True;
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Партнер не должен отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = 'İş ortağı, ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Партнер не должен отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The partner must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = 'İş ortağı ""%ValueOfAgreementAttribute%"" sözleşmesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от партнера в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki iş ortağından farklıdır'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от партнера в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the partner in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listenin %LineNumber% satırında bulunan iş ortağından farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Партнер в соглашении (%ValueOfAgreementAttribute%) не должен отличаться от партнера в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The partner in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the partner in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The partner in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the partner in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The partner in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the partner in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The partner in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the partner in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The partner in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the partner in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki iş ortağı, (%DocumentAttributeValue%) belgesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan iş ortağından farklı olmamalıdır.'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от партнера в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki iş ortağından farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от партнера в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the partner in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki iş ortağından farklıdır'");
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"Counterparty",
		"ThereAreErrorsFillingInCounterparty",
		NStr("ru = 'Контрагент';
			|vi = 'Counterparty';
			|en = 'Counterparty'; fa = 'طرف حساب';
			|it = 'Counterparty';
			|pl = 'Counterparty';
			|tr = 'Cari hesap'"),
		"VALUE(Catalog.Counterparties.EmptyRef)");
	VerificationDescription.OnlyWhenValueInDocumentIsFilledIn = True;
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Контрагент не должен отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The counterparty must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The counterparty must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The counterparty must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The counterparty must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The counterparty must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = 'Cari hesap, ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Контрагент не должен отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The counterparty must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The counterparty must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The counterparty must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The counterparty must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The counterparty must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = 'Cari hesap, ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от контрагента в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" sözleşmesindeki cari hesaptan farklıdır'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от контрагента в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the counterparty in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" sözleşmesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan cari hesaptan farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Контрагент в соглашении (%ValueOfAgreementAttribute%) не должен отличаться от контрагента в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The counterparty in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the counterparty in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The counterparty in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the counterparty in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The counterparty in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the counterparty in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The counterparty in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the counterparty in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The counterparty in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the counterparty in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki cari hesap, (%DocumentAttributeValue%) belgesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan cari hesaptan farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от контрагента в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki cari hesaptan farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от контрагента в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the counterparty in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki cari hesaptan farklıdır'");
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"Organization",
		"ThereAreErrorsInFillingOutOrganization",
		NStr("ru = 'Организация';
			|vi = 'Company';
			|en = 'Company'; fa = 'Company';
			|it = 'Company';
			|pl = 'Company';
			|tr = 'İş yeri'"),
		"VALUE(Catalog.Companies.EmptyRef)");
	VerificationDescription.OnlyWhenValueInDocumentIsFilledIn = True;
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Организация не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The company must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The company must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The company must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The company must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The company must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = 'İş yeri ""%ValueOfAgreementAttribute%"" sözleşmesindeki değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Организация не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The company must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The company must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The company must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The company must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The company must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = 'İş yeri, ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от организации в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki iş yerinden farklıdır'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от организации в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the company in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"" ""%ValueOfAgreementAttribute%"" sözleşmesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan iş yerinden farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Организация в соглашении (%ValueOfAgreementAttribute%) не должна отличаться от организации в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The company in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the company in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The company in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the company in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The company in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the company in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The company in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the company in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The company in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the company in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki iş yeri,  (%DocumentAttributeValue%) belgesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan iş yerinden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от организации в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"" ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki iş yerinden farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от организации в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the company in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"" ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki iş yerinden farklıdır'");
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"Currency",
		"ThereAreErrorsInFillingInCurrency",
		NStr("ru = 'Валюта';
			|vi = 'Currency';
			|en = 'Currency'; fa = 'ارز';
			|it = 'Currency';
			|pl = 'Currency';
			|tr = 'Para birimi'"));
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Валюта не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = 'Para birimi ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Валюта не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The currency must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = 'Para birimi ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от валюты в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki para biriminden farklıdır'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от валюты в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the currency in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan para biriminden farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Валюта в соглашении (%ValueOfAgreementAttribute%) не должна отличаться от валюты в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The currency in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the currency in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki para birimi  (%DocumentAttributeValue%) belgesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan para biriminden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от валюты в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki para biriminden farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от валюты в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the currency in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki para biriminden farklıdır'");
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"PaymentMethod",
		"ThereAreErrorsFillingOutPaymentForm",
		NStr("ru = 'Форма оплаты';
			|vi = 'Payment method';
			|en = 'Payment method'; fa = 'روش پرداخت';
			|it = 'Modalità di pagamento';
			|pl = 'Forma płatności';
			|tr = 'Ödeme formu'"),
		"VALUE(Enum.PaymentForms.EmptyRef)");
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Форма оплаты не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The payment method must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The payment method must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The payment method must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The payment method must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The payment method must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = 'Ödeme şekli, ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Форма оплаты не должна отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The payment method must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The payment method must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The payment method must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The payment method must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The payment method must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = 'Ödeme şekli ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от формы оплаты в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"" ""%ValueOfAgreementAttribute%"" anlaşmasındaki ödeme şeklinden farklıdır'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от формы оплаты в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the payment method in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan ödeme şeklinden farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Форма оплаты в соглашении (%ValueOfAgreementAttribute%) не должна отличаться от формы оплаты в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The payment method in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the payment method in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The payment method in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the payment method in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The payment method in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the payment method in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The payment method in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the payment method in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The payment method in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the payment method in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki ödeme şekli  (%DocumentAttributeValue%) belgesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan ödeme şeklinden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от формы оплаты в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki ödeme yönteminden farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от формы оплаты в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the payment method in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki ödeme yönteminden farklıdır'");
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"PriceIncludesVAT",
		"ThereAreErrorsInFillingPriceIncludesVAT",
		NStr("ru = 'Признак ""Цена включает НДС""';
			|vi = '""Price includes VAT"" checkbox';
			|en = '""Price includes VAT"" checkbox'; fa = '""Price includes VAT"" checkbox';
			|it = '""Price includes VAT"" checkbox';
			|pl = '""Price includes VAT"" checkbox';
			|tr = '""KDV fiyata dahildir"" işareti'"));
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Признак ""Цена включает НДС"" не должен отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The ""Price includes VAT"" checkbox must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The ""Price includes VAT"" checkbox must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The ""Price includes VAT"" checkbox must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The ""Price includes VAT"" checkbox must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The ""Price includes VAT"" checkbox must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = '""KDV fiyata dahildir"" işareti ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Признак ""Цена включает НДС"" не должен отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The ""Price includes VAT"" checkbox must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The ""Price includes VAT"" checkbox must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The ""Price includes VAT"" checkbox must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The ""Price includes VAT"" checkbox must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The ""Price includes VAT"" checkbox must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = '""KDV fiyata dahildir"" işareti ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от значения в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklıdır'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the value in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Признак ""Цена включает НДС"" в соглашении (%ValueOfAgreementAttribute%) не должен отличаться от значения в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The ""Price includes VAT"" checkbox in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the ""Price includes VAT"" checkbox in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The ""Price includes VAT"" checkbox in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the ""Price includes VAT"" checkbox in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The ""Price includes VAT"" checkbox in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the ""Price includes VAT"" checkbox in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The ""Price includes VAT"" checkbox in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the ""Price includes VAT"" checkbox in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The ""Price includes VAT"" checkbox in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the ""Price includes VAT"" checkbox in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki ""KDV fiyata dahildir"" işareti, (%DocumentAttributeValue%) belgesindeki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от значения в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki değerden farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от значения в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the value in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki değerden farklıdır'");
	
	VerificationDescription = NewDescriptionOfCheckingWhetherValueMatchesAgreement(ReturnValue, 
		"VendorPriceKind",
		"ThereAreErrorsInFillingInVendorPriceType",
		NStr("ru = 'Вид цен поставщика';
			|vi = 'Vendor price type';
			|en = 'Vendor price type'; fa = 'نوع قیمت تأمین‌کننده';
			|it = 'Vendor price type';
			|pl = 'Vendor price type';
			|tr = 'Tedarikçi fiyat türü'"),
		"VALUE(Catalog.VendorPriceTypes.EmptyRef)");
	VerificationDescription.ErrorTemplateInHeader = NStr("ru = 'Вид цен поставщика не должен отличаться от значения в соглашении ""%ValueOfAgreementAttribute%""';
														|vi = 'The vendor price type must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|en = 'The vendor price type must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = 'The vendor price type must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|it = 'The vendor price type must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|pl = 'The vendor price type must not differ from the value in the terms of purchase (%ValueOfAgreementAttribute%)';
														|tr = 'Tedarikçi fiyat türü ""%ValueOfAgreementAttribute%"" anlaşmasındaki değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInTable = NStr("ru = 'Вид цен поставщика не должен отличаться от значения в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
														|vi = 'The vendor price type must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|en = 'The vendor price type must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The vendor price type must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|it = 'The vendor price type must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|pl = 'The vendor price type must not differ from the one in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
														|tr = 'Tedarikçi fiyat türü ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateInHeaderForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от вида цен поставщика в соглашении ""%ValueOfAgreementAttribute%""';
																	|vi = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|en = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|it = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|pl = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%)';
																	|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki tedarikçi fiyat türünden farklıdır'");
	VerificationDescription.ErrorTemplateInTableForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от вида цен поставщика в соглашении ""%ValueOfAgreementAttribute%"" в строке %LineNumber% списка %TabularSectionName%';
																|vi = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|en = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list'; fa = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|it = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|pl = '""%DocumentAttributeValue%"" is different from the vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) in line %LineNumber% of the %TabularSectionName% list';
																|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" anlaşmasındaki %TabularSectionName% listesinin %LineNumber% satırında bulunan tedarikçi fiyat türünden farklıdır'");
	VerificationDescription.AgreementSelectionErrorTemplateInTable = NStr("ru = 'Вид цен поставщика в соглашении (%ValueOfAgreementAttribute%) не должен отличаться от вида цен поставщика в документе (%DocumentAttributeValue%) в строке %LineNumber% списка %TabularSectionName%';
																			|vi = 'The vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the vendor price type in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|en = 'The vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the vendor price type in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list'; fa = 'The vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the vendor price type in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|it = 'The vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the vendor price type in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|pl = 'The vendor price type in the terms of purchase (%ValueOfAgreementAttribute%) must not differ from the vendor price type in the document (%DocumentAttributeValue%) in line %LineNumber% of the %TabularSectionName% list';
																			|tr = '(%ValueOfAgreementAttribute%) anlaşmasındaki tedarikçi fiyat türü (%DocumentAttributeValue%) belgesindeki  %TabularSectionName% listesinin %LineNumber% satırında bulunan değerden farklı olmamalıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement = NStr("ru = '""%DocumentAttributeValue%"" отличается от вида цен поставщика в типовом соглашении ""%ValueOfAgreementAttribute%""';
																				|vi = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|en = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|it = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|pl = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																				|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki tedarikçi fiyat türünden farklıdır'");
	VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport = NStr("ru = '""%DocumentAttributeValue%"" отличается от вида цен поставщика в типовом соглашении ""%ValueOfAgreementAttribute%""';
																							|vi = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|en = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)'; fa = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|it = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|pl = '""%DocumentAttributeValue%"" is different from the vendor price type in the standard terms of purchase (%ValueOfAgreementAttribute%)';
																							|tr = '""%DocumentAttributeValue%"", ""%ValueOfAgreementAttribute%"" standart anlaşmasındaki tedarikçi fiyat türünden farklıdır'");
	
	Return ReturnValue;
	
EndFunction

Function NewDescriptionOfCheckingWhetherValueMatchesAgreement(DescriptionOfChecks, AttributeName, FieldNameThereAreErrors, AttributeRepresentation, EmptyValueInRequest = "")
	
	VerificationDescription = DescriptionOfChecks.Add();
	
	VerificationDescription.AttributeName = AttributeName;
	VerificationDescription.FieldNameThereAreErrors = FieldNameThereAreErrors;
	VerificationDescription.AttributeRepresentation = AttributeRepresentation;
	VerificationDescription.EmptyValueInRequest = EmptyValueInRequest;
	
	Return VerificationDescription;
	
EndFunction

// Generates the request text to check whether the purchase document prices are within the acceptable range.
//
// Parameters:
// QueryText     - String - text string to which you want to add the query text
// Query parametres-Structure - a structure containing query parameters
// Purchase document - a document Object that needs to be checked.
//
Procedure GenerateRequestForPricesInAcceptableRange(QueryText)
		
	QueryText = QueryText + "
		|SELECT
		|	NestedQuery.LineNumber                 AS LineNumber,
		|	NestedQuery.Products                AS Products,
		|	NestedQuery.Characteristic              AS Characteristic,
		|	NestedQuery.PriceCurrency                  AS PriceCurrency,
		|	NestedQuery.Price                        AS Price,
		|	NestedQuery.MaximumAllowablePrice   AS MaximumAllowablePrice,
		|	CASE
		|		WHEN
		|			NOT ThereIsNoMaximumPrice
		|			AND NestedQuery.Price > NestedQuery.MaximumAllowablePrice
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END                                       AS ThereAreErrorsMaximumAllowablePrice
		|FROM (
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber          AS LineNumber,
		|	TemporaryTableOfGoods_.Products         AS Products,
		|	TemporaryTableOfGoods_.Characteristic       AS Characteristic,
		|	TemporaryTableProcurementDocument.Currency      AS PriceCurrency,
		|	TemporaryTableOfGoods_.DiscountedPrice_        AS Price,
		|	CASE
		|		WHEN
		|			MaximumPricesOfCrossSectionProductRange.Price IS NULL
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereIsNoMaximumPrice,
		|	CAST(ISNULL(MaximumPricesOfCrossSectionProductRange.Price,0)
		|		/ ISNULL(&QueryTextPackagingFactor1,1)
		|			* CASE
		|				WHEN
		|					TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				THEN
		|					&QueryTextPackagingFactor2
		|				ELSE 
		|					1
		|			END
		|			* CASE
		|				WHEN
		|					MaximumPricesOfCrossSectionProductRange.Currency <> TemporaryTableProcurementDocument.Currency
		|				THEN
		|					CASE
		|						WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
		|							AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
		|							AND ISNULL(MaximumPriceCurrencyRates.CourseDenominator, 0) > 0
		|							AND ISNULL(MaximumPriceCurrencyRates.CourseNumerator, 0) > 0
		|						THEN
		|							(MaximumPriceCurrencyRates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
		|							/ (CurrencyRatesPrices.CourseNumerator * MaximumPriceCurrencyRates.CourseDenominator)
		|						ELSE
		|							0
		|					END
		|				ELSE 
		|					1
		|			END AS NUMBER(31,2))
		|	AS MaximumAllowablePrice
		|
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|
		|		LEFT JOIN
		|			TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
		|		ON
		|			TRUE
		|
		|		LEFT JOIN
		|			TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
		|		ON
		|			TemporaryTableProcurementDocument.Currency = CurrencyRatesPrices.Currency
		|
		|/////////////////////////////////////////////////////////////////////////////
		|
		|		LEFT JOIN
		|			InformationRegister.ItemsPrices.SliceLast(
		|				ENDOFPERIOD(&Date, DAY),
		|				PriceKind IN (
		|					SELECT
		|						Constants.KindOfMaximumAllowablePurchasePrice AS PriceKind
		|					FROM
		|						Constants AS Constants
		|					)
		|				AND (Products,Characteristic) IN (
		|					SELECT
		|						Goods.Products,
		|						Goods.Characteristic
		|					FROM
		|						TemporaryTableOfGoods_ AS Goods
		|					)
		|			) AS MaximumPricesOfCrossSectionProductRange
		|		ON
		|			TemporaryTableOfGoods_.Products = MaximumPricesOfCrossSectionProductRange.Products
		|			AND TemporaryTableOfGoods_.Characteristic = MaximumPricesOfCrossSectionProductRange.Characteristic
		|
		|		LEFT JOIN
		|			TemporaryTableCurrencyExchangeRates AS MaximumPriceCurrencyRates
		|		ON
		|			MaximumPricesOfCrossSectionProductRange.Currency = MaximumPriceCurrencyRates.Currency
		|
		|WHERE
		|	TemporaryTableOfGoods_.Price > 0
		|) AS NestedQuery
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"MaximumPricesOfCrossSectionProductRange.Package",
		"MaximumPricesOfCrossSectionProductRange.Products"));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
		
EndProcedure

// Generates the request text to check whether the purchase document prices are within the acceptable range.
//
// Parameters:
// QueryText     - String - text string to which you want to add the query text
// Query parametres-Structure - a structure containing query parameters
// Purchase document - a document Object that needs to be checked.
//
Procedure GenerateRequestForPricesInAcceptableRange2_5(QueryText)
		
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
		|	TemporaryTableOfGoods_.Products AS Products,
		|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
		|	ISNULL(CASE
		|			WHEN ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|				THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|			ELSE TemporaryTableOfGoods_.Characteristic.ItemsCharacteristicForPricing
		|		END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
		|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PricingPackage,
		|	TemporaryTableOfGoods_.Price AS Price,
		|	TemporaryTableOfGoods_.DiscountedPrice_ AS DiscountedPrice_,
		|	TemporaryTableOfGoods_.Package AS Package
		|INTO TemporaryTableProductsAugmented
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON (ItemKinds.Ref = TemporaryTableOfGoods_.Products.ProductKind)
		|;
		|
		|SELECT
		|	NestedQuery.LineNumber                 AS LineNumber,
		|	NestedQuery.Products                AS Products,
		|	NestedQuery.Characteristic              AS Characteristic,
		|	NestedQuery.PriceCurrency                  AS PriceCurrency,
		|	NestedQuery.Price                        AS Price,
		|	NestedQuery.MaximumAllowablePrice   AS MaximumAllowablePrice,
		|	CASE
		|		WHEN
		|			NOT ThereIsNoMaximumPrice
		|			AND NestedQuery.Price > NestedQuery.MaximumAllowablePrice
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END                                       AS ThereAreErrorsMaximumAllowablePrice
		|FROM (
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber          AS LineNumber,
		|	TemporaryTableOfGoods_.Products         AS Products,
		|	TemporaryTableOfGoods_.Characteristic       AS Characteristic,
		|	TemporaryTableProcurementDocument.Currency      AS PriceCurrency,
		|	TemporaryTableOfGoods_.DiscountedPrice_        AS Price,
		|	CASE
		|		WHEN
		|			MaximumPricesOfCrossSectionProductRange.Price IS NULL
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereIsNoMaximumPrice,
		|	CAST(ISNULL(MaximumPricesOfCrossSectionProductRange.Price,0)
		|		/ ISNULL(&QueryTextPackagingFactor1,1)
		|			* CASE
		|				WHEN
		|					TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				THEN
		|					&QueryTextPackagingFactor2
		|				ELSE 
		|					1
		|			END
		|			* CASE
		|				WHEN
		|					MaximumPricesOfCrossSectionProductRange.Currency <> TemporaryTableProcurementDocument.Currency
		|				THEN
		|					CASE
		|						WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
		|							AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
		|							AND ISNULL(MaximumPriceCurrencyRates.CourseDenominator, 0) > 0
		|							AND ISNULL(MaximumPriceCurrencyRates.CourseNumerator, 0) > 0
		|						THEN
		|							(MaximumPriceCurrencyRates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
		|							/ (CurrencyRatesPrices.CourseNumerator * MaximumPriceCurrencyRates.CourseDenominator)
		|						ELSE
		|							0
		|					END
		|				ELSE 
		|					1
		|			END AS NUMBER(31,2))
		|	AS MaximumAllowablePrice
		|
		|FROM
		|	TemporaryTableProductsAugmented AS TemporaryTableOfGoods_
		|
		|		LEFT JOIN
		|			TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
		|		ON
		|			TRUE
		|
		|		LEFT JOIN
		|			TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
		|		ON
		|			TemporaryTableProcurementDocument.Currency = CurrencyRatesPrices.Currency
		|
		|/////////////////////////////////////////////////////////////////////////////
		|
		|		LEFT JOIN
		|			InformationRegister.ItemsPrices25.SliceLast(
		|				ENDOFPERIOD(&Date, DAY),
		|				PriceKind IN (
		|					SELECT
		|						Constants.KindOfMaximumAllowablePurchasePrice AS PriceKind
		|					FROM
		|						Constants AS Constants
		|					)
		|				AND (Products, PricingVariant, PricingBatch, PricingPackage) IN (
		|					SELECT
		|						Goods.Products,
		|						Goods.PricingVariant,
		|						Goods.PricingBatch,
		|						Goods.PricingPackage
		|					FROM
		|						TemporaryTableProductsAugmented AS Goods
		|					)
		|			) AS MaximumPricesOfCrossSectionProductRange
		|		ON
		|			TemporaryTableOfGoods_.Products = MaximumPricesOfCrossSectionProductRange.Products
		|			AND TemporaryTableOfGoods_.PricingVariant = MaximumPricesOfCrossSectionProductRange.PricingVariant
		|
		|		LEFT JOIN
		|			TemporaryTableCurrencyExchangeRates AS MaximumPriceCurrencyRates
		|		ON
		|			MaximumPricesOfCrossSectionProductRange.Currency = MaximumPriceCurrencyRates.Currency
		|
		|WHERE
		|	TemporaryTableOfGoods_.Price > 0
		|) AS NestedQuery
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"MaximumPricesOfCrossSectionProductRange.Package",
		"MaximumPricesOfCrossSectionProductRange.Products"));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
		
EndProcedure

// Generates the request text to check whether manual discounts and markups are allowed
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestWhetherManualDiscountsAndSurchargesAreAcceptable(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber               AS LineNumber,
		|	CASE
		|		WHEN
		|			TemporaryTableOfGoods_.PercentRateOfManualDiscount < 0
		|			AND -TemporaryTableOfGoods_.PercentRateOfManualDiscount > TermsOfPurchases.MaximumPercentageForManualMarkup
		|			AND TermsOfPurchases.Ref.ControlPurchasePrices
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END                                            AS ThereAreErrorsFillingManualMarkUp,
		|	TermsOfPurchases.PercentRateOfManualDiscount       AS MaximumAmountOfManualDiscount,
		|	TermsOfPurchases.MaximumPercentageForManualMarkup      AS MaximumAmountOfManualMarkUp
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|LEFT JOIN
		|	TemporaryTableProcurementDocument
		|ON
		|	TRUE
		|LEFT JOIN
		|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
		|ON
		|	TemporaryTableProcurementDocument.Terms = TermsOfPurchases.Ref
		|WHERE
		|	TemporaryTableOfGoods_.PercentRateOfManualDiscount <> 0
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure

// Generates a request to check whether the payment schedule stages are filled in correctly
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForCorrectnessOfPaymentScheduleStages(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	CASE
		|		WHEN TemporaryTableProcurementDocument.DocumentAmount = 0
		|			OR TemporaryTableProcurementDocument.Terms = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsFillingStagesOfPaymentSchedule,
		|	
		|	TemporaryTableProcurementDocument.Terms AS Terms,
		|	TemporaryTableProcurementDocument.Date AS Date,
		|	TemporaryTableProcurementDocument.DateOfShipment AS DateOfShipment,
		|	TemporaryTableProcurementDocument.ApprovalDate AS ApprovalDate,
		|	TemporaryTableProcurementDocument.InvoiceForOrders AS InvoiceForOrders,
		|	TemporaryTableProcurementDocument.ARAPObjectSettings AS ARAPObjectSettings,
		|
		|	CASE WHEN TemporaryTableProcurementDocument.Terms <> VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|		THEN TemporaryTableProcurementDocument.Terms.Calendar
		|		ELSE UNDEFINED
		|	END AS Calendar,
		|	
		|	DocumentStages.LineNumber       AS LineNumber,
		|	DocumentStages.PaymentOption     AS PaymentOption,
		|	DocumentStages.CalculateFrom    AS CalculateFrom,
		|	DocumentStages.Move             AS Move,
		|	TemporaryTableProcurementDocument.ThisIsOrder AS ThisIsOrder,
		|	TemporaryTableProcurementDocument.NotShipInInstallments AS NotShipInInstallments,
		|	DocumentStages.PaymentDate       AS PaymentDate,
		|	DocumentStages.PaymentPercentage    AS PaymentPercentage,
		|	
		|	CASE WHEN &PackageDepositIsRequired THEN
		|		DocumentStages.PackageDepositPercentage
		|	ELSE
		|		0
		|	END                            AS PackageDepositPercentage
		|FROM
		|	TimeTableStagesOfPaymentSchedule AS DocumentStages
		|
		|LEFT JOIN
		|	TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
		|ON
		|	TRUE
		|
		|ORDER BY
		|	LineNumber ASC
		|;
		|";

EndProcedure

// Generates a request to monitor the completion of calculations for the order
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForPaymentCompletionControl(QueryText)

	QueryText = QueryText + "
		|SELECT
		|	CASE
		|		WHEN ISNULL(VendorsARAPAccountingBalance.AmountDueClosingBalance, 0) >= 0
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreIncompleteCalculations,
		|	VendorsARAPAccountingBalance.Currency AS Currency,
		|	-1*(VendorsARAPAccountingBalance.AmountDueClosingBalance) AS AmountDueClosingBalance
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(, , , , ARAPObject.Object = &Ref) AS VendorsARAPAccountingBalance
		|;
		|";
EndProcedure

// Generates a request to monitor the completion of the order receipt
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateReceiptControlRequest(QueryText)

	QueryText = QueryText + "
		|SELECT
		|	CASE
		|		WHEN ISNULL(VendorsARAPAccountingBalance.ToReceiveClosingBalance, 0) <= 0
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereIsIncompleteReceipt
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(, , , , ARAPObject.Object = &Ref) AS VendorsARAPAccountingBalance
		|;
		|";
EndProcedure

// Generates the request text to check whether prices are filled in in the document, allowing zero prices in canceled lines.
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure CreateRequestToControlFillingInPricesBasedOnCanceledPrices(QueryText)
	
		QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
		|	CASE
		|		WHEN
		|			TemporaryTableOfGoods_.Sum = 0
		|		THEN
		|			CASE
		|				WHEN (&ReturnOfMultiTurnContainers AND NOT &PackageDepositIsRequired
		|					AND TemporaryTableOfGoods_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage))
		|					OR TemporaryTableOfGoods_.Canceled THEN
		|					FALSE
		|				ELSE
		|					TRUE
		|			END
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsFillingAmounts,
		|	CASE
		|		WHEN
		|			TemporaryTableOfGoods_.Price = 0
		|		THEN
		|			CASE
		|				WHEN (&ReturnOfMultiTurnContainers AND NOT &PackageDepositIsRequired
		|					AND TemporaryTableOfGoods_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage))
		|					OR TemporaryTableOfGoods_.Canceled THEN
		|					FALSE
		|				ELSE
		|					TRUE
		|			END
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsFillingPrices
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
		
EndProcedure

// Generates the request text to check whether prices are filled in in the document
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestToFillInPrices(QueryText)
	
		QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
		|	CASE
		|		WHEN
		|			TemporaryTableOfGoods_.Sum = 0
		|		THEN
		|			CASE
		|				WHEN (&ReturnOfMultiTurnContainers AND NOT &PackageDepositIsRequired
		|					AND TemporaryTableOfGoods_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
		|					FALSE
		|				ELSE
		|					TRUE
		|			END
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsFillingAmounts,
		|	CASE
		|		WHEN
		|			TemporaryTableOfGoods_.Price = 0
		|		THEN
		|			CASE
		|				WHEN (&ReturnOfMultiTurnContainers AND NOT &PackageDepositIsRequired
		|					AND TemporaryTableOfGoods_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
		|					FALSE
		|				ELSE
		|					TRUE
		|			END
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsFillingPrices
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
		
EndProcedure

// Generates the request text for checking the organization of orders
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForComplianceWithOrganizationOfOrders(QueryText)

	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
		|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|LEFT JOIN
		|	TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
		|ON
		|	TRUE
		|WHERE
		|	TemporaryTableProcurementDocument.Organization <> TemporaryTableOfGoods_.ReferenceOrder.Organization
		|;
		|";
	
EndProcedure

// Generates a request for checking the VAT rate depending on taxation.
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestToSpecifyPurchaseVATRateCorrectly(QueryText)
	
	QueryText = QueryText 
		+ "SELECT
		|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
		|	TemporaryTableProcurementDocument.VATTaxation AS VATTaxation,
		|	TemporaryTableOfGoods_.VATRate AS SelectedVATRate,
		|	CASE
		|		WHEN TemporaryTableOfGoods_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|			AND &ReturnOfMultiTurnContainers
		|			AND TemporaryTableOfGoods_.VATRate <> VALUE(Catalog.VATRates.EXCLUDINGVAT)
		|			THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
		|		WHEN TemporaryTableProcurementDocument.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|			AND TemporaryTableOfGoods_.VATRate <> ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
		|				VALUE(Catalog.VATRates.EmptyRef)))
		|			THEN ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
		|					VALUE(Catalog.VATRates.EmptyRef)))
		|		ELSE
		|			UNDEFINED
		|	END AS CorrectVATRate
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|
		|	LEFT JOIN TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
		|	ON
		|		(TRUE)
		|
		|	LEFT JOIN
		|		Catalog.VATRates.VATTaxationTypes AS VATRates
		|	ON
		|		VATRates.VATTaxationType = TemporaryTableProcurementDocument.VATTaxation
		|		AND VATRates.Ref = TemporaryTableOfGoods_.VATRate
		|
		|	LEFT JOIN
		|		InformationRegister.ProductsVATRates.SliceLast(&Date,
		|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
		|	ON
		|		TemporaryTableOfGoods_.Products = ProductsVATRates.Products
		|	
		|	LEFT JOIN
		|		InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
		|	ON
		|		TRUE
		|
		|WHERE
		|	CASE
		|		WHEN TemporaryTableOfGoods_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|				AND &ReturnOfMultiTurnContainers
		|				AND TemporaryTableOfGoods_.VATRate <> VALUE(Catalog.VATRates.EXCLUDINGVAT)
		|			THEN TRUE
		|		WHEN TemporaryTableProcurementDocument.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|				AND TemporaryTableOfGoods_.VATRate <> ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
		|					VALUE(Catalog.VATRates.EmptyRef)))
		|			THEN TRUE
		|		WHEN VATRates.Ref IS NULL
		|			THEN TRUE
		|		ELSE FALSE
		|	END
		|;
		|";
	
EndProcedure

// Generates a request to check whether the VAT amount is specified depending on the line amount.
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForCorrectnessOfPurchaseAmountAndVATAmount(QueryText)
	
	QueryText = QueryText + "SELECT
	|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
	|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	TemporaryTableOfGoods_.Sum AS Sum,
	|	TemporaryTableOfGoods_.VATAmount AS VATAmount,
	|	TemporaryTableOfGoods_.VATRate AS VATRate,
	|	TemporaryTableProcurementDocument.Currency AS Currency,
	|	CASE
	|		WHEN TemporaryTableOfGoods_.Sum < 0 AND TemporaryTableOfGoods_.Sum - TemporaryTableOfGoods_.VATAmount <= 0
	|			THEN FALSE
	|		WHEN TemporaryTableOfGoods_.Sum >= 0 AND TemporaryTableOfGoods_.Sum - TemporaryTableOfGoods_.VATAmount >= 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsVATAmount
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
	|		ON (TRUE)
	|WHERE
	|	CASE
	|		WHEN TemporaryTableOfGoods_.Sum < 0 AND TemporaryTableOfGoods_.Sum - TemporaryTableOfGoods_.VATAmount <= 0
	|			THEN FALSE
	|		WHEN TemporaryTableOfGoods_.Sum >= 0 AND TemporaryTableOfGoods_.Sum - TemporaryTableOfGoods_.VATAmount >= 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|;
	|";
	
EndProcedure

// Generates a request to check whether the document currency matches the currency specified in the contract with the principal for each line of goods purchased under the Agency purchase.
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateCurrencyMatchingRequestForAgencyPurchases(QueryText)
		QueryText = QueryText + "SELECT
	|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
	|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	TemporaryTableOfGoods_.Products AS Products,
	|	CASE
	|		WHEN TemporaryTableOfGoods_.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN FALSE
	|		WHEN TemporaryTableOfGoods_.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			AND TemporaryTableProcurementDocument.Currency <> TemporaryTableOfGoods_.Purpose.Contract.ARAPCurrency
	|				THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreCurrencyErrorsOnAgencyPurchase
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
	|		ON (TRUE)
	|
	|WHERE
	|	CASE
	|		WHEN TemporaryTableOfGoods_.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN FALSE
	|		WHEN TemporaryTableOfGoods_.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			AND TemporaryTableProcurementDocument.Currency <> TemporaryTableOfGoods_.Purpose.Contract.ARAPCurrency
	|				THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|";
EndProcedure

// Generates a request to check the completion of the customer's order in the table part of the document
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForFillingClientSOrder(QueryText)
		QueryText = QueryText + "SELECT
	|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
	|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	TemporaryTableOfGoods_.SalesOrder IN (
	|								UNDEFINED,
	|								VALUE(Document.MaterialProviderOrder2_5.EmptyRef),
	|								VALUE(Document.SalesOrder.EmptyRef)) AS ThereAreErrorsFillingCustomerSOrder
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
	|		ON (TRUE)
	|
	|WHERE
	|	TemporaryTableOfGoods_.SalesOrder IN (
	|								UNDEFINED,
	|								VALUE(Document.MaterialProviderOrder2_5.EmptyRef),
	|								VALUE(Document.SalesOrder.EmptyRef))
	|;
	|";
EndProcedure

// Generates a request to check whether the destination is filled in in the table part of the document
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateDestinationControlRequest(QueryText)
		QueryText = QueryText + "SELECT
	|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
	|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	CASE
	|		WHEN TemporaryTableOfGoods_.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsFillingAssignment
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
	|		ON (TRUE)
	|
	|WHERE
	|	CASE
	|		WHEN TemporaryTableOfGoods_.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|";
EndProcedure

// Generates a request to check the possibility of writing off goods for expenses
//
// Parameters:
// QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestToDeductItemsForExpenses(QueryText)
		QueryText = QueryText + "SELECT
	|	TemporaryTableOfGoods_.TabularSectionName AS TabularSectionName,
	|	TemporaryTableOfGoods_.TabularSectionPresentation AS TabularSectionPresentation,
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	TemporaryTableProcurementDocument.BusinessOperation AS BusinessOperation
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN TemporaryTableProcurementDocument AS TemporaryTableProcurementDocument
	|		ON (TRUE)
	|
	|WHERE
	|	TemporaryTableOfGoods_.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND TemporaryTableOfGoods_.ToExpenseAs
	|	AND TemporaryTableProcurementDocument.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PurchaseByImport),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEU),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
	|;
	|";
EndProcedure
	
#EndRegion

#Region ServiceProceduresAndFunctionsForCheckingCorrectnessOfDocuments

// Displays error messages in the header of the purchase document
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	DocumentPurchases  - DocumentObject - The object for which you want to show error messages
// 	Cancel            - Boolean - Flag for refusing to carry out the document
// 	Variances       - Array - The array of deviations of the terms and conditions of sale at the top of the document.
//
Procedure ReportErrorsPurchaseDocumentHeader(Selection,
	                                             DocumentPurchases,
	                                             Cancel,
	                                             Variances = Undefined)
	
	ReportErrorsInPurchaseConditions(Selection, DocumentPurchases, Cancel, Variances);
	
EndProcedure

// Displays error messages in the PM Items in the purchase document
//
// Parameters:
// Selection         - QueryResultSelection
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean- Flag for refusing to carry out the document
// DeviationTree  - ValueTree - Tree with deviations of the table part from the purchase conditions.
//
Procedure ReportErrorsInPurchaseDocument(Selection,
	                                              DocumentPurchases,
	                                              Cancel,
	                                              DeviationTree = Undefined)
	
	ReportErrorsInPurchaseConditions(Selection, DocumentPurchases, Cancel, DeviationTree);
	
EndProcedure

// Displays error messages in the purchase document
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	DocumentPurchases  - DocumentObject - The object for which you want to show error messages.
// 	Cancel            - Boolean - flag for refusing to carry out the document.
// 	Variances       - Array, ValueTree, Undefined - Deviations from the terms of purchase.
//
Procedure ReportErrorsInPurchaseConditions(Selection, DocumentPurchases, Cancel, Variances)
	
	OutputToReport = Variances <> Undefined;

	AvailabilityOfChecks = New Structure; //Describes the presence of columns with checks in the request selection.
	
	// Description of non-universal checks:
	AvailabilityOfChecks.Insert("ThereAreErrorsAgreementStatus");
	AvailabilityOfChecks.Insert("ThereAreErrorsFillingWarehouse");
	AvailabilityOfChecks.Insert("ThereAreFillingErrorsToReturnMultiTurnContainer");
	AvailabilityOfChecks.Insert("ThereAreFillingErrorsDepositForContainerIsRequired");
	AvailabilityOfChecks.Insert("ThereAreErrorsReturnDateOfMultiTurnContainer");
	AvailabilityOfChecks.Insert("ThereAreErrorsInFillingReturnPeriodOfMultiTurnContainers");
	AvailabilityOfChecks.Insert("ThereAreErrorsFillingOrderOfCalculations");
	AvailabilityOfChecks.Insert("ThereAreErrorsMaximumAllowablePrice");
	
	// Universal checks:
	DescriptionOfChecks = DescriptionOfChecksOfComplianceOfValuesWithAgreement();
	For Each VerificationDescription In DescriptionOfChecks Do
		AvailabilityOfChecks.Insert(VerificationDescription.FieldNameThereAreErrors);
	EndDo;
	
	ColumnsFromSelection = Selection.Owner().Columns;
	
	FillPropertyValues(AvailabilityOfChecks, ColumnsFromSelection);
	ThisIsCapCheck = ColumnsFromSelection.Find("LineNumber") = Undefined;
	
	For Each KeyAndValue In AvailabilityOfChecks Do
		CheckName = KeyAndValue.Key;
		AvailabilityOfChecks[CheckName] = KeyAndValue.Value <> Undefined;
	EndDo;
	
	TypeOfPurchaseDocument = TypeOf(DocumentPurchases);
	ThisIsConvention = TypeOfPurchaseDocument = Type("CatalogObject.TermsOfPurchaseFromVendors")
		Or TypeOfPurchaseDocument = Type("CatalogRef.TermsOfPurchaseFromVendors"); 
	ThisIsPurchaseOrder = TypeOfPurchaseDocument = Type("DocumentObject.PurchaseRequest")
		Or TypeOfPurchaseDocument = Type("DocumentRef.PurchaseRequest"); // To report deviations
	
	ErrorOutputParameters = New Structure;
	
	ErrorOutputParameters.Insert("DocumentObject",   DocumentPurchases);
	ErrorOutputParameters.Insert("Cancel",            False);
	
	ErrorOutputParameters.Insert("OutputToReport",   OutputToReport);
	ErrorOutputParameters.Insert("Variances",       Variances);
	
	ErrorOutputParameters.Insert("ThisIsCapCheck",  ThisIsCapCheck);
	ErrorOutputParameters.Insert("TabularSectionName", "Goods");
	ErrorOutputParameters.Insert("LineNumber",       0);
	
	While Selection.Next() Do
		
		If Not ThisIsCapCheck Then
			ErrorOutputParameters.LineNumber = Selection.LineNumber;
		EndIf;
		
		ErrorAddress = "";
	    If Not ThisIsCapCheck And Not OutputToReport Then
			ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
										|ru = 'в строке %LineNumber% списка ""Товары""';
										|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
										|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
										|pl = 'w wierszu %LineNumber% listy ""Towary""';
										|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
			ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", Selection.LineNumber);
		EndIf;
		
		For Each VerificationDescription In DescriptionOfChecks Do
			
			CheckName = VerificationDescription.FieldNameThereAreErrors;
			If Not AvailabilityOfChecks[CheckName] Or Not Selection[CheckName] Then
				Continue;
			EndIf;
			
			If ThisIsConvention Then
				
				// Output messages for standard agreements:
				ErrorText = ?(OutputToReport,
					VerificationDescription.ErrorTemplateDifferencesFromStandardAgreementForReport,
					VerificationDescription.ErrorTemplateDifferencesFromStandardAgreement);
			
			ElsIf ThisIsPurchaseOrder Then
				
				// Displaying messages about the wrong choice of agreement in the table part:
				ErrorText = VerificationDescription.AgreementSelectionErrorTemplateInTable;
			
			ElsIf ThisIsCapCheck Then
				
				// Displaying messages about header Attributes: 
				ErrorText = ?(OutputToReport,
					VerificationDescription.ErrorTemplateInHeaderForReport,
					VerificationDescription.ErrorTemplateInHeader);
					
			Else // Displaying messages about Attributes in the table part:
				
				ErrorText = ?(OutputToReport,
					VerificationDescription.ErrorTemplateInTableForReport,
					VerificationDescription.ErrorTemplateInTable);
			
			EndIf;
			
			// Substituting parameters into the resulting template:
			ErrorText = StrReplace(ErrorText,
				"%DocumentAttributeValue%",
				Selection[VerificationDescription.AttributeName]);
				
			ErrorText = StrReplace(ErrorText,
				"%ValueOfAgreementAttribute%",
				Selection[VerificationDescription.AttributeName + "Terms"]);
				
			ErrorText = StrReplace(ErrorText,
				"%TabularSectionName%",
				ErrorOutputParameters.TabularSectionName);
				
			ErrorText = StrReplace(ErrorText,
				"%LineNumber%",
				ErrorOutputParameters.LineNumber);
				
			ReportErrorInPurchaseCondition(ErrorOutputParameters,
				ErrorText,
				VerificationDescription.AttributeName,
				VerificationDescription.AttributeRepresentation);
				
		EndDo;
		
		If AvailabilityOfChecks.ThereAreErrorsAgreementStatus And Selection.ThereAreErrorsAgreementStatus Then
			
			ErrorText = StrTemplate(NStr("ru = 'Соглашение находится в статусе ""Не согласовано""%1%2';
										|vi = 'The terms of purchase are in the ""Not approved"" status%1.%2';
										|en = 'The terms of purchase are in the ""Not approved"" status%1.%2'; fa = 'The terms of purchase are in the ""Not approved"" status%1.%2';
										|it = 'The terms of purchase are in the ""Not approved"" status%1.%2';
										|pl = 'The terms of purchase are in the ""Not approved"" status%1.%2';
										|tr = 'Anlaşma ""Onaylanmadı""%1 durumundadır. %2'"),
						?(OutputToReport, "", ErrorAddress),
						?(OutputToReport Or Not ThisIsCapCheck, "", " " + NStr("ru = 'Проведение документа запрещено.';
																				|vi = 'Document posting is prohibited.';
																				|en = 'Document posting is prohibited.'; fa = 'Document posting is prohibited.';
																				|it = 'Document posting is prohibited.';
																				|pl = 'Document posting is prohibited.';
																				|tr = 'Belgenin kaydedilmesi yasaktır.'")));
			
			ReportErrorInPurchaseCondition(ErrorOutputParameters,
				ErrorText,
				"Terms",
				NStr("ru = 'Соглашение';
					|vi = 'Terms of purchase';
					|en = 'Terms of purchase'; fa = 'شرایط خرید';
					|it = 'Terms of purchase';
					|pl = 'Terms of purchase';
					|tr = 'Anlaşma'"));

		EndIf;
		
		If AvailabilityOfChecks.ThereAreErrorsFillingWarehouse And Selection.ThereAreErrorsFillingWarehouse Then
			
			If ThisIsPurchaseOrder Then
				
				If Selection.WarehouseAgreementIsGroup Then
					ErrorText = NStr("ru = 'Группа складов соглашения ""%WarehouseAgreement%"" не содержит склад-получатель ""%Warehouse%""%ErrorAddress%';
									|vi = 'The ""%WarehouseAgreement%"" terms of purchase warehouse group does not contain the ""%Warehouse%"" destination warehouse%ErrorAddress%';
									|en = 'The ""%WarehouseAgreement%"" terms of purchase warehouse group does not contain the ""%Warehouse%"" destination warehouse%ErrorAddress%'; fa = 'The ""%WarehouseAgreement%"" terms of purchase warehouse group does not contain the ""%Warehouse%"" destination warehouse%ErrorAddress%';
									|it = 'The ""%WarehouseAgreement%"" terms of purchase warehouse group does not contain the ""%Warehouse%"" destination warehouse%ErrorAddress%';
									|pl = 'The ""%WarehouseAgreement%"" terms of purchase warehouse group does not contain the ""%Warehouse%"" destination warehouse%ErrorAddress%';
									|tr = '""%WarehouseAgreement%"" anlaşmasının ambar grubu hedef ambar ""%Warehouse%"" içermiyor%ErrorAddress%'");
				Else
					ErrorText = NStr("ru = 'Склад соглашения ""%WarehouseAgreement%"" не должен отличаться от значения в документе ""%Warehouse%""%ErrorAddress%';
									|vi = 'The terms of purchase warehouse (%WarehouseAgreement%) must not differ from the value in the document (%Warehouse%)%ErrorAddress%';
									|en = 'The terms of purchase warehouse (%WarehouseAgreement%) must not differ from the value in the document (%Warehouse%)%ErrorAddress%'; fa = 'The terms of purchase warehouse (%WarehouseAgreement%) must not differ from the value in the document (%Warehouse%)%ErrorAddress%';
									|it = 'The terms of purchase warehouse (%WarehouseAgreement%) must not differ from the value in the document (%Warehouse%)%ErrorAddress%';
									|pl = 'The terms of purchase warehouse (%WarehouseAgreement%) must not differ from the value in the document (%Warehouse%)%ErrorAddress%';
									|tr = '""%WarehouseAgreement%"" anlaşmasındaki ambar ""%Warehouse%"" belgesindeki değerden farklı olmamalıdır%ErrorAddress%'");
				EndIf;
				
				ErrorText = StrReplace(ErrorText,
					"%ErrorAddress%",
					?(OutputToReport, "", ErrorAddress));
					
			ElsIf Not OutputToReport Then
				If Selection.WarehouseAgreementIsGroup Then
					ErrorText = NStr("vi = 'Kho phải nằm trong nhóm kho ""%WarehouseAgreement%""';
									|ru = 'Склад должен входить в группу складов ""%WarehouseAgreement%""';
									|en = 'Warehouse should be included in group of the ""%WarehouseAgreement%"" warehouses'; fa = 'Warehouse should be included in group of the ""%WarehouseAgreement%"" warehouses';
									|it = 'Il magazzino deve essere incluso nel gruppo dei magazzini ""%WarehouseAgreement%""';
									|pl = 'Magazyn musi należeć do grupy magazynów ""%WarehouseAgreement%""';
									|tr = 'Ambar, ""%WarehouseAgreement%"" ambar grubunun parçası olmalıdır'");
				Else
					ErrorText = NStr("vi = 'Kho không được khác với giá trị trong thỏa thuận ""%WarehouseAgreement%""';
									|ru = 'Склад не должен отличаться от значения в соглашении ""%WarehouseAgreement%""';
									|en = 'Warehouse should not differ from the value in agreement ""%WarehouseAgreement%""'; fa = 'Warehouse should not differ from the value in agreement ""%WarehouseAgreement%""';
									|it = 'Il magazzino non deve differire dal valore nell''accordo ""%WarehouseAgreement%""';
									|pl = 'Magazyn nie powinien różnić się  od wartości w umowie ""%WarehouseAgreement%""';
									|tr = 'Ambar, ""%WarehouseAgreement%"" anlaşmasındaki değerden farklı olmamalıdır'");
				EndIf;
			Else 
				If Selection.WarehouseAgreementIsGroup Then
					ErrorText = NStr("vi = '""%Warehouse%"" phải thuộc nhóm kho trong thỏa thuận ""%WarehouseAgreement%""';
									|ru = '""%Warehouse%"" должен входить в группу складов соглашения ""%WarehouseAgreement%""';
									|en = '""%Warehouse%"" must be in the warehouse group of the ""%WarehouseAgreement%"" agreement'; fa = '""%Warehouse%"" must be in the warehouse group of the ""%WarehouseAgreement%"" agreement';
									|it = '""%Warehouse%""deve essere incluso nel gruppo dei magazzini dell''accordo ""%WarehouseAgreement%""';
									|pl = '""%Warehouse%"" musi należeć do grupy magazynów umowy ""%WarehouseAgreement%""';
									|tr = '""%Warehouse%"", ""%WarehouseAgreement%"" anlaşmasının ambar grubuna dahil edilmelidir'");
				Else
					ErrorText = NStr("vi = '""%Warehouse%"" khác với kho bãi trong thỏa thuận ""%WarehouseAgreement%""';
									|ru = '""%Warehouse%"" отличается от склада в соглашении ""%WarehouseAgreement%""';
									|en = '""%Warehouse%"" is different from the warehouse in the ""%WarehouseAgreement%"" agreement'; fa = '""%Warehouse%"" is different from the warehouse in the ""%WarehouseAgreement%"" agreement';
									|it = '""%Warehouse%"" differisce dal magazzino nell''accordo ""%WarehouseAgreement%""';
									|pl = '""%Warehouse%"" różni się od magazynu w umowie ""%WarehouseAgreement%""';
									|tr = '""%Warehouse%"", ""%WarehouseAgreement%"" anlaşmasındaki ambardan farklı'");
				EndIf;
			EndIf;
			
			ErrorText = StrReplace(ErrorText, "%WarehouseAgreement%", Selection.WarehouseAgreement);
			ErrorText = StrReplace(ErrorText, "%Warehouse%", Selection.Warehouse);
			
			ReportErrorInPurchaseCondition(ErrorOutputParameters,
				ErrorText,
				"Warehouse",
				NStr("vi = 'Kho bãi';
					|ru = 'Склад';
					|en = 'Warehouse'; fa = 'Warehouse';
					|it = 'Magazzino';
					|pl = 'Warehouse';
					|tr = 'Ambar'"));
			
		EndIf;
		
		#Region ReusablePackage
		If AvailabilityOfChecks.ThereAreFillingErrorsToReturnMultiTurnContainer And Selection.ThereAreFillingErrorsToReturnMultiTurnContainer Then
			
			If ThisIsConvention Then
				ErrorText = NStr("vi = 'Dấu hiệu trả lại bao bì luân chuyển không được khác với giá trị trong thỏa thuận chung';
								|ru = 'Признак возврата многооборотной тары не должен отличаться от значения в типовом соглашении';
								|en = 'Flag of reusable packaging return cannot differ from the value in the standard agreement'; fa = 'Flag of reusable packaging return cannot differ from the value in the standard agreement';
								|it = 'Il segno di restituzione dell''imballaggio restituibile non deve differire dal valore nel modello di accordo';
								|pl = 'Oznaka zwrotu tary do wielokrotnego użytku nie powinna różnić się  od wartości w umowie typowej';
								|tr = 'Yeniden kullanılabilir ambalajın iade bayrağı, standart sözleşmedeki değerden farklı olmamalıdır'");
			Else
				ErrorText = NStr("vi = 'Dấu hiệu trả lại bao bì luân chuyển không được khác với giá trị trong thỏa thuận';
								|ru = 'Признак возврата многооборотной тары не должен отличаться от значения в соглашении';
								|en = 'Flag of reusable packaging return cannot differ from the value in the agreement'; fa = 'Flag of reusable packaging return cannot differ from the value in the agreement';
								|it = 'Il segno di restituzione dell''imballaggio restituibile non deve differire dal valore nell''accordo';
								|pl = 'Oznaka zwrotu tary do wielokrotnego użytku nie powinna różnić się  od wartości w umowie';
								|tr = 'Yeniden kullanılabilir ambalajın iade bayrağı, sözleşmedeki değerden farklı olmamalıdır'");
			EndIf;
			
			If Not OutputToReport Then
				CommonClientServer.MessageToUser(
					ErrorText,
					DocumentPurchases,
					?(ThisIsConvention,"ReturnReusablePackage","ToReturnReusablePackage"),
					,
					Cancel);
			Else 
				Reports.VariancesFromPurchaseConditions.AddHeaderDeviationToArrayOfDeviations(NStr("vi = 'Trả lại bao bì';
																									|ru = 'Возврат тары';
																									|en = 'Return package'; fa = 'Return package';
																									|it = 'Restituzione dell''imballaggio';
																									|pl = 'Zwrot tary';
																									|tr = 'Ambalaj iadesi'"), ErrorText, Variances);
			EndIf;
		EndIf;
		
		If AvailabilityOfChecks.ThereAreErrorsInFillingReturnPeriodOfMultiTurnContainers And Selection.ThereAreErrorsInFillingReturnPeriodOfMultiTurnContainers And Selection.ReturnOfMultiTurnContainers Then
			
			If Not OutputToReport Then
				ErrorText = NStr("vi = 'Thời hạn trả lại bao bì luân chuyển không nên khác với giá trị trong thỏa thuận (%ReturnCycleLength%)';
								|ru = 'Срок возврата многооборотной тары не должен отличаться от значения в соглашении (%ReturnCycleLength%)';
								|en = 'Reusable packaging return date should not differ from the value in agreement (%ReturnCycleLength%)'; fa = 'Reusable packaging return date should not differ from the value in agreement (%ReturnCycleLength%)';
								|it = 'Il periodo di restituzione dell''imballaggio restituibile non deve differire dal valore nell''accordo (%ReturnCycleLength%)';
								|pl = 'Termin zwrotu tary do wielokrotnego użytku nie powinien różnić się  od wartości w umowie (%ReturnCycleLength%)';
								|tr = 'Yeniden kullanılabilir ambalajın iade süresi sözleşmedeki değerden farklı olmamalıdır (%ReturnCycleLength%)'");
				ErrorText = StrReplace(ErrorText, "%ReturnCycleLength%", Selection.ReusablePackageReturnCycleLength);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					DocumentPurchases,
					"ReusablePackageReturnCycleLength",
					,
					Cancel);
			Else 
					
				ErrorText = NStr("vi = '(%ReturnPeriodStandard%) khác với thời hạn trong thỏa thuận (%ReturnCycleLength%)';
								|ru = '(%ReturnPeriodStandard%) отличается от срока в соглашении (%ReturnCycleLength%)';
								|en = '(%ReturnPeriodStandard%) is different from the period in the (%ReturnCycleLength%) agreement'; fa = '(%ReturnPeriodStandard%) is different from the period in the (%ReturnCycleLength%) agreement';
								|it = '(%ReturnPeriodStandard%) differisce dalla riga nell''accordo (%ReturnCycleLength%)';
								|pl = '(%ReturnPeriodStandard%) różni się od terminu w umowie (%ReturnCycleLength%)';
								|tr = '(%ReturnPeriodStandard%) sözleşmedeki süreden farklıdır (%ReturnCycleLength%)'");
				ErrorText = StrReplace(ErrorText, "%ReturnCycleLength%", Selection.ReusablePackageReturnCycleLength);
				ErrorText = StrReplace(ErrorText, "%ReturnPeriodStandard%", DocumentPurchases.ReusablePackageReturnCycleLength);
				Reports.VariancesFromPurchaseConditions.AddHeaderDeviationToArrayOfDeviations(NStr("vi = 'Thời hạn trả lại bao bì';
																									|ru = 'Срок возврата тары';
																									|en = 'Date of packaging return'; fa = 'Date of packaging return';
																									|it = 'Periodo di restituzione dell''imballaggio';
																									|pl = 'Termin zwrotu tary';
																									|tr = 'Ambalaj iade süresi'"), ErrorText, Variances);
			EndIf;

		EndIf;
		
		If AvailabilityOfChecks.ThereAreFillingErrorsDepositForContainerIsRequired And Selection.ThereAreFillingErrorsDepositForContainerIsRequired Then
			
			If ThisIsConvention Then
				ErrorText = NStr("vi = 'Dấu hiệu của nhu cầu ký cược bao bì không khác với giá trị trong thỏa thuận tiêu chuẩn';
								|ru = 'Признак требования залога за тару не должен отличаться от значения в типовом соглашении';
								|en = 'Flag of requirement for a deposit for package should not differ from the value in standard agreement'; fa = 'Flag of requirement for a deposit for package should not differ from the value in standard agreement';
								|it = 'indicazione di cauzione obbligatoria per l''imballaggio non deve differire dal valore nel modello di accordo';
								|pl = 'Oznaka konieczności zastawu za opakowanie nie może różnić się od wartości standardowej umowy';
								|tr = 'Ambalaj için depozito gerekliliğinin bayrağı, standart sözleşmedeki değerden farklı olmamalıdır'");
			Else
				ErrorText = NStr("vi = 'Dấu hiệu của nhu cầu ký cược bao bì sẽ không khác với giá trị trong thỏa thuận';
								|ru = 'Признак требования залога за тару не должен отличаться от значения в соглашении';
								|en = 'Flag of requirement for a deposit for package should not differ from the value in agreement'; fa = 'Flag of requirement for a deposit for package should not differ from the value in agreement';
								|it = 'Indicazione di cauzione per l''imballaggio richiesta non deve differire dal valore nel modello di accordo';
								|pl = 'Oznaka konieczności zastawu za opakowanie nie może różnić się od wartości w umowie';
								|tr = 'Ambalaj için depozito gerekliliğinin bayrağı, sözleşmedeki değerden farklı olmamalıdır'");
			EndIf;
			
			If Not OutputToReport Then
				CommonClientServer.MessageToUser(
					ErrorText,
					DocumentPurchases,
					"PackageDepositIsRequired",
					,
					Cancel);
			Else 
				Reports.VariancesFromPurchaseConditions.AddHeaderDeviationToArrayOfDeviations(NStr("vi = 'Yêu cầu ký cược bao bì';
																									|ru = 'Требование залога за тару';
																									|en = 'Requirement for a deposit for package'; fa = 'Requirement for a deposit for package';
																									|it = 'Richiesta di cauzione per l''imballaggio';
																									|pl = 'Konieczność zastawu za opakowanie';
																									|tr = 'Ambalaj için depozito gerekliliği'"), ErrorText, Variances);
			EndIf;
		EndIf;
		
		If AvailabilityOfChecks.ThereAreErrorsReturnDateOfMultiTurnContainer And Selection.ThereAreErrorsReturnDateOfMultiTurnContainer And Selection.ReturnOfMultiTurnContainers Then
			
			ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
				DocumentPurchases,
				Selection.ReusablePackageReturnCycleLength,
				Selection.CalculatePackageReturnDateAccordingToCalendar,
				Selection.ScheduleOfPackageReturn);
			
			If ReusablePackagesReturnDate <> DocumentPurchases.ReusablePackagesReturnDate Then
				ErrorText = NStr("vi = 'Ngày trả lại bao bì luân chuyển không được khác với thời hạn trả lại trong thỏa thuận';
								|ru = 'Дата возврата многооборотной тары не должна отличаться от срока возврата в соглашении';
								|en = 'Reusable packaging return date should not differ from the one in the agreement'; fa = 'Reusable packaging return date should not differ from the one in the agreement';
								|it = 'La data di restituzione dell''imballaggio restituibile non deve differire dalla riga della restituzione nell''accordo';
								|pl = 'Data zwrotu tary do wielokrotnego użytku nie powinna różnić się od terminu zwrotu w umowie';
								|tr = 'Yeniden kullanılabilir ambalajın iade tarihi, sözleşmedeki iade süresinden farklı olmamalıdır'");
				
				If Not OutputToReport Then
					CommonClientServer.MessageToUser(
							ErrorText,
							DocumentPurchases,
							"ReusablePackagesReturnDate",
							,
							Cancel);
				Else 
					Reports.VariancesFromPurchaseConditions.AddHeaderDeviationToArrayOfDeviations(NStr("vi = 'Ngày trả lại bao bì';
																										|ru = 'Дата возврата тары';
																										|en = 'Package return date'; fa = 'Package return date';
																										|it = 'Data di restituzione dell''imballaggio';
																										|pl = 'Data zwrotu tary';
																										|tr = 'Ambalaj iade tarihi'"), ErrorText, Variances);
				EndIf;
			EndIf;
		EndIf;
		#EndRegion
		
		If AvailabilityOfChecks.ThereAreErrorsFillingOrderOfCalculations And Selection.ThereAreErrorsFillingOrderOfCalculations Then
			If Selection.ContractsAreUsed Then
				ErrorText = NStr("vi = 'Trình tự hạch toán không cần khác với giá trị trong hợp đồng ""%ARAPObjectSettings%""';
								|ru = 'Порядок расчетов не должен отличаться от значения в договоре ""%ARAPObjectSettings%""';
								|en = 'Payment terms cannot differ from the value in the ""%ARAPObjectSettings%"" contract'; fa = 'Payment terms cannot differ from the value in the ""%ARAPObjectSettings%"" contract';
								|it = 'Порядок расчетов не должен отличаться от значения в договоре ""%ARAPObjectSettings%""';
								|pl = 'Payment terms cannot differ from the value in the ""%ARAPObjectSettings%"" contract';
								|tr = 'Mutabakat sırası, ""%ARAPObjectSettings%"" sözleşmesindeki değerden farklı olmamalıdır'");
				ErrorText = StrReplace(ErrorText, "%ARAPObjectSettings%", Selection.SettlementProcedureAgreement);
				If Not OutputToReport Then
					CommonClientServer.MessageToUser(
						ErrorText,
						DocumentPurchases,
						"ARAPObjectSettings",
						,
						Cancel);
				Else 
					Reports.VariancesFromPurchaseConditions.AddHeaderDeviationToArrayOfDeviations(NStr("vi = 'Trình tự hạch toán';
																										|ru = 'Порядок расчетов';
																										|en = 'Payment terms'; fa = 'شرایط پرداخت';
																										|it = 'Modalità di regolamenti';
																										|pl = 'Sposób rozliczeń';
																										|tr = 'Hesaplama prosedürü'"), ErrorText, Variances);
				EndIf;
			Else
				If ThisIsConvention Then
					ErrorText = NStr("vi = 'Trình tự hạch toán không được khác so với giá trị trong thỏa thuận chung ""%ARAPObjectSettings%""';
									|ru = 'Порядок расчетов не должен отличаться от значения в типовом соглашении ""%ARAPObjectSettings%""';
									|en = 'Payment terms cannot differ from the value in the ""%ARAPObjectSettings%"" standard agreement'; fa = 'Payment terms cannot differ from the value in the ""%ARAPObjectSettings%"" standard agreement';
									|it = 'La modalità di regolamento non deve differire dal valore nel modello di accordo ""%ARAPObjectSettings%""';
									|pl = 'Procedura rozrachunku nie powinna różnić się od wartości standardowej umowy ""%ARAPObjectSettings%""';
									|tr = 'Mutabakat sırası, ""%ARAPObjectSettings%"" standart sözleşmedeki değerden farklı olmamalıdır'");
				Else
					ErrorText = NStr("vi = 'Thủ tục giải quyết không nên khác với giá trị trong thỏa thuận ""%ARAPObjectSettings%""';
									|ru = 'Порядок расчетов не должен отличаться от значения в соглашении ""%ARAPObjectSettings%""';
									|en = 'Payment terms cannot differ from the value in the ""%ARAPObjectSettings%"" agreement'; fa = 'Payment terms cannot differ from the value in the ""%ARAPObjectSettings%"" agreement';
									|it = 'La modalità di regolamento non deve differire dal valore nell''accordo ""%ARAPObjectSettings%""';
									|pl = 'Procedura rozrachunku nie powinna różnić się od wartości umowy ""%ARAPObjectSettings%""';
									|tr = 'Mutabakat sırası, ""%ARAPObjectSettings%"" sözleşmesindeki değerden farklı olmamalıdır'");
				EndIf;
				ErrorText = StrReplace(ErrorText, "%ARAPObjectSettings%", Selection.SettlementProcedureAgreement);
				
				If Not OutputToReport Then
					CommonClientServer.MessageToUser(
						ErrorText,
						DocumentPurchases,
						"ARAPObjectSettings",
						,
						Cancel);
				Else 
					Reports.VariancesFromPurchaseConditions.AddHeaderDeviationToArrayOfDeviations(NStr("vi = 'Trình tự hạch toán';
																										|ru = 'Порядок расчетов';
																										|en = 'Payment terms'; fa = 'شرایط پرداخت';
																										|it = 'Modalità di regolamenti';
																										|pl = 'Sposób rozliczeń';
																										|tr = 'Hesaplama prosedürü'"), ErrorText, Variances);
				EndIf;
			EndIf;
		EndIf;
		
		If AvailabilityOfChecks.ThereAreErrorsMaximumAllowablePrice And Selection.ThereAreErrorsMaximumAllowablePrice Then
			
			If ValueIsFilled(Selection.Characteristic) Then
				
				ErrorText = NStr("vi = 'Đơn giá đối với mặt hàng ""%Products%"" có đặc tính ""%Characteristic%"" không được lớn hơn đơn giá theo thỏa thuận ""%MaximumAllowablePrice% %PriceCurrency%""';
								|ru = 'Цена на номенклатуру ""%Products%"" с характеристикой ""%Characteristic%"" не должна быть выше цены по соглашению ""%MaximumAllowablePrice% %PriceCurrency%""';
								|en = 'Price for variant ""%Characteristic%"" of item ""%Products%"" should not exceed the agreement price ""%MaximumAllowablePrice% %PriceCurrency%""'; fa = 'Price for variant ""%Characteristic%"" of item ""%Products%"" should not exceed the agreement price ""%MaximumAllowablePrice% %PriceCurrency%""';
								|it = 'Il prezzo dell''articolo ""%Products%"" con caratteristica ""%Characteristic%"" non deve essere maggiore del prezzo da accordo ""%MaximumAllowablePrice% %PriceCurrency%""';
								|pl = 'Cena na nomenklaturę ""%Products%"" z charakterystyką ""%Characteristic%"" nie powinna być wyższa od ceny zgodnie z umową ""%MaximumAllowablePrice% %PriceCurrency%""';
								|tr = '""%Characteristic%"" özelliğine sahip ""%Products%"" öğesinin fiyatı, ""%MaximumAllowablePrice% %PriceCurrency%"" anlaşmasına göre fiyattan yüksek olmamalıdır'");
				ErrorText = StrReplace(ErrorText,"%Products%",              Selection.Products);
				ErrorText = StrReplace(ErrorText,"%Characteristic%",            Selection.Characteristic);
				ErrorText = StrReplace(ErrorText,"%MaximumAllowablePrice%", Selection.MaximumAllowablePrice);
				ErrorText = StrReplace(ErrorText,"%PriceCurrency%",                Selection.PriceCurrency);
				
			Else
				
				ErrorText = NStr("vi = 'Đơn giá đối với mặt hàng ""%Products%"" không được lớn hơn đơn giá theo thỏa thuận ""%MaximumAllowablePrice% %PriceCurrency%""';
								|ru = 'Цена на номенклатуру ""%Products%"" не должна быть выше цены по соглашению ""%MaximumAllowablePrice% %PriceCurrency%""';
								|en = 'Price of the ""%Products%"" items should not exceed the ""%MaximumAllowablePrice% %PriceCurrency%"" price under the agreement'; fa = 'Price of the ""%Products%"" items should not exceed the ""%MaximumAllowablePrice% %PriceCurrency%"" price under the agreement';
								|it = 'Il prezzo dell''articolo ""%Products%"" non deve essere superiore all''accordo ""%MaximumAllowablePrice% %PriceCurrency%""';
								|pl = 'Cena na nomenklaturę ""%Products%"" nie powinna być wyższa od ceny zgodnie z umową ""%MaximumAllowablePrice% %PriceCurrency%""';
								|tr = '""%Products%"" öğesinin fiyatı, ""%MaximumAllowablePrice% %PriceCurrency%"" anlaşmasına göre fiyattan yüksek olmamalıdır'");
				ErrorText = StrReplace(ErrorText, "%Products%",              Selection.Products);
				ErrorText = StrReplace(ErrorText, "%MaximumAllowablePrice%", Selection.MaximumAllowablePrice);
				ErrorText = StrReplace(ErrorText, "%PriceCurrency%",                Selection.PriceCurrency);
				
			EndIf;
			
			If OutputToReport Then
				Reports.VariancesFromPurchaseConditions.AddRowDeviationToDeviationTree(Selection.LineNumber, "Price", ErrorText, Variances);
			Else
				CommonClientServer.MessageToUser(
					ErrorText,
					DocumentPurchases,
					CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "Price"),
					,
					Cancel);
			EndIf;
		EndIf;
		
	EndDo;
	
	If ErrorOutputParameters.Cancel Then
		Cancel = True;
	EndIf;
	
EndProcedure

// Displays a message on the screen / in the collection of deviations for the report
// Parameters:
//  ErrorOutputParameters - Structure:
//    * DocumentObject - DocumentObject - Which the error refers to
//    * Cancel - Boolean - The returned parameter. Sets a rejection for processing the fill check
//
//    * OutputToReport - Boolean - Defines the output option: True - to the deviation collection, False - to the screen.
//    * Variances - Array, ValueTree - Collection for the report.
//
//    * ThisIsCapCheck - Boolean - Determines the positioning of the message: True - in the header, false - in the table part.
//    * TabularSectionName - String - The name of the tabular part of the document.
//    * LineNumber - Number - to position the message.
//  ErrorText - String - the displayed message.
//  AttributeName - String - The name of the Attribute for positioning the error message.
//  AttributeRepresentation - String - For output to the report.
Procedure ReportErrorInPurchaseCondition(ErrorOutputParameters, ErrorText, AttributeName, AttributeRepresentation)
	
	If ErrorOutputParameters.OutputToReport
		And ErrorOutputParameters.ThisIsCapCheck Then
		
		Reports.VariancesFromPurchaseConditions.AddHeaderDeviationToArrayOfDeviations(
			AttributeRepresentation,
			ErrorText,
			ErrorOutputParameters.Variances);
		
	ElsIf ErrorOutputParameters.OutputToReport
		And Not ErrorOutputParameters.ThisIsCapCheck Then
		
		Reports.VariancesFromPurchaseConditions.AddRowDeviationToDeviationTree(
			ErrorOutputParameters.LineNumber,
			AttributeRepresentation,
			ErrorText,
			ErrorOutputParameters.Variances);
		
	Else // Message output to the user:
			
		If ErrorOutputParameters.ThisIsCapCheck Then
			
			AttributePath1 = AttributeName;
			
		Else
			
			TableAttributeName = AttributeName;
			If TypeOf(ErrorOutputParameters.DocumentObject) = Type("DocumentObject.PurchaseRequest") Then
				// The Attributes are displayed in the "basement", the values in the table can be hidden. We display the Attributes displayed by default:
				TableAttributeName = "PresentationOfTermsOfPurchase";
			EndIf;
			
			AttributePath1 = CommonClientServer.PathToTabularSection(
				ErrorOutputParameters.TabularSectionName,
				ErrorOutputParameters.LineNumber,
				TableAttributeName);
			
		EndIf;
		
		Common.MessageToUser(
			ErrorText,
			ErrorOutputParameters.DocumentObject,
			AttributePath1,
			,
			ErrorOutputParameters.Cancel);
		
	EndIf;

EndProcedure

// Displays error messages when the purchase document prices fall within the acceptable range.
//
// Parameters:
// Selection         - QueryResultSelection
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - Flag for refusing to carry out the document
// DeviationTree  - ValueTree - Tree with deviations of the table part from the purchase conditions.
//
Procedure ReportErrorsWhenPricesFallWithinAcceptableRange(Selection,
	                                                       DocumentPurchases,
	                                                       Cancel,
	                                                       UseDiscountsMarkups,
	                                                       DeviationTree = Undefined)
	
	OutputToReport = (DeviationTree <> Undefined);
	
	While Selection.Next() Do
		LineNumber = Selection.LineNumber;
		
		If Selection.ThereAreErrorsMaximumAllowablePrice Then
			
			If ValueIsFilled(Selection.Characteristic) Then
				
				If UseDiscountsMarkups Then
					ErrorText = NStr("vi = 'Đơn giá có tính chiết khấu (phụ thu) đối với mặt hàng ""%Products%"" có đặc tính ""%Characteristic%"" không được lớn hơn đơn giá được phép tối đa ""%MaximumAllowablePrice% %PriceCurrency%""';
									|ru = 'Цена с учетом скидки (наценки) на номенклатуру ""%Products%"" с характеристикой ""%Characteristic%"" не должна быть выше максимально допустимой цены ""%MaximumAllowablePrice% %PriceCurrency%""';
									|en = 'Price with discount (markup) for variant ""%Characteristic%"" of item ""%Products%"" should not exceed maximum allowable price ""%MaximumAllowablePrice% %PriceCurrency%""'; fa = 'Price with discount (markup) for variant ""%Characteristic%"" of item ""%Products%"" should not exceed maximum allowable price ""%MaximumAllowablePrice% %PriceCurrency%""';
									|it = 'Il prezzo dell''articolo ""%Products%"" con sconto (maggiorazione) e caratteristica ""%Characteristic%"" non può essere maggiore al prezzo massimo disponibile ""%MaximumAllowablePrice% %PriceCurrency%""';
									|pl = 'Cena z uwzględnieniem zniżki (marży) na nomenklaturę ""%Products%"" z charakterystyką ""%Characteristic%"" nie powinna być wyższa od maksymalnie dopuszczalnej ceny ""%MaximumAllowablePrice% %PriceCurrency%""';
									|tr = '""%Characteristic%"" özelliğine sahip ""%Products%"" öğesi için indirim/zam dikkate alındığında fiyat, izin verilen maksimum ""%MaximumAllowablePrice% %PriceCurrency%"" fiyatından yüksek olmamalıdır'");
				Else
					ErrorText = NStr("vi = 'Đơn giá đối với mặt hàng ""%Products%"" có đặc tính ""%Characteristic%"" không được lớn hơn đơn giá tối đa được phép ""%MaximumAllowablePrice% %PriceCurrency%""';
									|ru = 'Цена на номенклатуру ""%Products%"" с характеристикой ""%Characteristic%"" не должна быть выше максимально допустимой цены ""%MaximumAllowablePrice% %PriceCurrency%""';
									|en = 'Price for variant ""%Characteristic%"" of item ""%Products%"" should not exceed maximum allowable price ""%MaximumAllowablePrice% %PriceCurrency%""'; fa = 'Price for variant ""%Characteristic%"" of item ""%Products%"" should not exceed maximum allowable price ""%MaximumAllowablePrice% %PriceCurrency%""';
									|it = 'Il prezzo dell''articolo ""%Products%""  con caratteristica  ""%Characteristic%"" non può essere maggiore al prezzo massimo disponibile ""%MaximumAllowablePrice% %PriceCurrency%""';
									|pl = 'Cena na nomenklaturę ""%Products%"" z charakterystyką ""%Characteristic%"" nie powinna być wyższa od maksymalnie dopuszczalnej ceny ""%MaximumAllowablePrice% %PriceCurrency%""';
									|tr = '""%Characteristic%"" özelliğine sahip ""%Products%"" öğesinin fiyatı, izin verilen maksimum ""%MaximumAllowablePrice% %PriceCurrency%"" fiyatından yüksek olmamalıdır'");
				EndIf;
					
				ErrorText = StrReplace(ErrorText,"%Products%",              Selection.Products);
				ErrorText = StrReplace(ErrorText,"%Characteristic%",            Selection.Characteristic);
				ErrorText = StrReplace(ErrorText,"%MaximumAllowablePrice%", Selection.MaximumAllowablePrice);
				ErrorText = StrReplace(ErrorText,"%PriceCurrency%",                Selection.PriceCurrency);
				
			Else
				
				If UseDiscountsMarkups Then
					ErrorText = NStr("vi = 'Đơn giá có tính chiết khấu (phụ thu) đối với mặt hàng ""%Products%"" không được lớn hơn đơn giá được phép tối đa ""%MaximumAllowablePrice% %PriceCurrency%""';
									|ru = 'Цена с учетом скидки (наценки) на номенклатуру ""%Products%"" не должна быть выше максимально допустимой цены ""%MaximumAllowablePrice% %PriceCurrency%""';
									|en = 'Price with discount (markup) for the ""%Products%"" items should not exceed maximum allowable price ""%MaximumAllowablePrice% %PriceCurrency%""'; fa = 'Price with discount (markup) for the ""%Products%"" items should not exceed maximum allowable price ""%MaximumAllowablePrice% %PriceCurrency%""';
									|it = 'Il prezzo dell''articolo ""%Products%"" con sconto (maggiorazione) non può essere maggiore del prezzo massimo disponibile ""%MaximumAllowablePrice% %PriceCurrency%""';
									|pl = 'Cena z uwzględnieniem zniżki (marży) na nomenklaturę ""%Products%"" nie powinna być wyższa od maksymalnie dopuszczalnej ceny ""%MaximumAllowablePrice% %PriceCurrency%""';
									|tr = '""%Products%"" öğesi için indirim/zam içeren fiyat, izin verilen maksimum ""%MaximumAllowablePrice% %PriceCurrency%"" fiyatından yüksek olmamalıdır'");
				Else
					ErrorText = NStr("vi = 'Đơn giá đối với mặt hàng ""%Products%"" không được lớn hơn đơn giá được phép tối đa ""%MaximumAllowablePrice% %PriceCurrency%""';
									|ru = 'Цена на номенклатуру ""%Products%"" не должна быть выше максимально допустимой цены ""%MaximumAllowablePrice% %PriceCurrency%""';
									|en = 'Price of the ""%Products%"" items should not exceed maximum allowable price ""%MaximumAllowablePrice% %PriceCurrency%""'; fa = 'Price of the ""%Products%"" items should not exceed maximum allowable price ""%MaximumAllowablePrice% %PriceCurrency%""';
									|it = 'Il prezzo dell''articolo ""%Products%"" non può essere maggiore del prezzo massimo disponibile ""%MaximumAllowablePrice% %PriceCurrency%""';
									|pl = 'Cena na nomenklaturę ""%Products%"" nie powinna być wyższa od maksymalnie dopuszczalnej ceny ""%MaximumAllowablePrice% %PriceCurrency%""';
									|tr = '""%Products%"" öğesinin fiyatı, izin verilen maksimum ""%MaximumAllowablePrice% %PriceCurrency%"" fiyatından yüksek olmamalıdır'");
				EndIf;
					
				ErrorText = StrReplace(ErrorText, "%Products%",              Selection.Products);
				ErrorText = StrReplace(ErrorText, "%MaximumAllowablePrice%", Selection.MaximumAllowablePrice);
				ErrorText = StrReplace(ErrorText, "%PriceCurrency%",                Selection.PriceCurrency);
				
			EndIf;
			
			If OutputToReport Then
				Reports.VariancesFromPurchaseConditions.AddRowDeviationToDeviationTree(LineNumber, "Price", ErrorText, DeviationTree);
			Else
				CommonClientServer.MessageToUser(
					ErrorText,
					DocumentPurchases,
					CommonClientServer.PathToTabularSection("Goods", LineNumber, "Price"),
					,
					Cancel);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Displays error messages about fullness of service Analytics for services in the purchase document.
//
// Parameters:
// Selection         - QueryResultSelection
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCorrectnessOfServiceAnalytics(Selection, DocumentPurchases, Cancel)
	
	If GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
	
		While Selection.Next() Do
			
			ErrorText = NStr("vi = 'Cần điền dạng chi phí đối với dịch vụ ""%Products%"" trong dòng %LineNumber% danh sách ""Hàng hóa""';
							|ru = 'Необходимо заполнить статью расходов для услуги ""%Products%"" в строке %LineNumber% списка ""Товары""';
							|en = 'Fill in expense item for service ""%Products%"" in line %LineNumber% of the ""Goods"" list'; fa = 'Fill in expense item for service ""%Products%"" in line %LineNumber% of the ""Goods"" list';
							|it = 'È necessario compilare la voce di spesa per il servizio ""%Products%"" nella riga  %LineNumber% dell''elenco ""Merce""';
							|pl = 'Należy wypełnić pozycję rozchodów dla usługi ""%Products%"" w wierszu %LineNumber% listy ""Товары""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""%Products%"" hizmeti için gider kaleminin doldurulması gerekmektedir'");
			ErrorText = StrReplace(ErrorText, "%Products%", Selection.Products);
			ErrorText = StrReplace(ErrorText, "%LineNumber%",  Selection.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				DocumentPurchases,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber,"ExpenseItem"),
				,
				Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Displays error messages about the availability of services in the purchase document
//
// Parameters:
// Selection         - QueryResultSelection
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsAvailabilityOfServicesWorksInPurchaseDocument(Selection, DocumentPurchases, Cancel)
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Không thể chỉ ra mặt hàng ""%Products%"" với kiểu ""%ItemsType%"" (dòng %LineNumber% danh sách ""Hàng hóa""), cho chứng từ với kiểu giao dịch kinh tế ""%BusinessOperation%""';
						|ru = 'Нельзя указывать номенклатуру ""%Products%"" с типом ""%ItemsType%"" (строка %LineNumber% списка ""Товары""), для документа с типом хоз. операции ""%BusinessOperation%""';
						|en = 'You cannot specify items ""%Products%"" with the ""%ItemsType%"" type (line %LineNumber% of the Item list) for the document with the ""%BusinessOperation%"" business transaction type'; fa = 'You cannot specify items ""%Products%"" with the ""%ItemsType%"" type (line %LineNumber% of the Item list) for the document with the ""%BusinessOperation%"" business transaction type';
						|it = 'Non indicare l''articolo ""%Products%"" con tipo ""%ItemsType%"" (riga %LineNumber% dell''elenco ""Товары""), per il documento con tipo di operazione economica  ""%BusinessOperation%""';
						|pl = 'Niedopuszczalne jest wskazywanie nomenklatury ""%Products%"" z typem ""%ItemsType%"" (wiersz %LineNumber% listy ""Товары""), dla dokumentu z typem operacje gospodarcze ""%BusinessOperation%""';
						|tr = '""%BusinessOperation%"" ev işlem tipine sahip bir belge için ""%Products%"" kalemini ""%ItemsType%"" tipiyle (""Ürünler"" listesinin %LineNumber% satırı) belirtemezsiniz'");
		ErrorText = StrReplace(ErrorText, "%Products%",          Selection.Products);
		ErrorText = StrReplace(ErrorText, "%ItemsType%",       Selection.ItemsType);
		ErrorText = StrReplace(ErrorText, "%LineNumber%",           Selection.LineNumber);
		ErrorText = StrReplace(ErrorText, "%BusinessOperation%", DocumentPurchases.BusinessOperation);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber,"Products"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure

// Displays error messages about the availability of items and services in the purchase document
//
// Parameters:
// Selection         - QueryResultSelection
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsAvailabilityOfItemsOfServicesWorksInPurchasingDocument(Selection, DocumentPurchases, Cancel)
	
	ContractType = Enums.ContractTypes.EmptyRef();
	
	If ValueIsFilled(DocumentPurchases.Contract) Then
		SetPrivilegedMode(True);
		ContractType = Common.ObjectAttributeValue(DocumentPurchases.Contract, "ContractType");
		SetPrivilegedMode(False);
	EndIf;
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Không thể chỉ định mặt hàng ""%Products%"" có kiểu ""%ItemsType%"" (dòng %LineNumber% trong danh sách ""Hàng hóa""), đối với chứng từ có kiểu hợp đồng ""%ContractType%""';
						|ru = 'Нельзя указывать номенклатуру ""%Products%"" с типом ""%ItemsType%"" (строка %LineNumber% списка ""Товары""), для документа с типом договора ""%ContractType%""';
						|en = 'You cannot specify the ""%Products%"" item with the ""%ItemsType%"" type (line %LineNumber% of the Item list) for the document with the ""%ContractType%"" contract type'; fa = 'You cannot specify the ""%Products%"" item with the ""%ItemsType%"" type (line %LineNumber% of the Item list) for the document with the ""%ContractType%"" contract type';
						|it = 'You cannot specify the ""%Products%"" item with the ""%ItemsType%"" type (line %LineNumber% of the Item list) for the document with the ""%ContractType%"" contract type';
						|pl = 'You cannot specify the ""%Products%"" item with the ""%ItemsType%"" type (line %LineNumber% of the Item list) for the document with the ""%ContractType%"" contract type';
						|tr = '""%ContractType%"" sözleşme tipine sahip belge için ""%Products%"" öğesini ""%ItemsType%"" tipiyle (""Ürünler"" listesinin %LineNumber%. satırı) belirtemezsiniz'");
		ErrorText = StrReplace(ErrorText, "%Products%",          Selection.Products);
		ErrorText = StrReplace(ErrorText, "%ItemsType%",       Selection.ItemsType);
		ErrorText = StrReplace(ErrorText, "%LineNumber%",           Selection.LineNumber);
		ErrorText = StrReplace(ErrorText, "%ContractType%",           ContractType);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber,"Products"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure

// Displays error messages about the presence of traceable works in the purchase document
//
// Parameters:
// Selection         - QueryResultSelection
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsAboutTraceableWorksInPurchaseDocument(Selection, DocumentPurchases, Cancel)
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Không thể chỉ ra công việc được truy xuất ""%Products%"" (dòng %LineNumber% danh sách ""Hàng hóa""), cho chứng từ có kiểu giao dịch kinh tế ""%BusinessOperation%""';
						|ru = 'Нельзя указывать прослеживаемую работу ""%Products%"" (строка %LineNumber% списка ""Товары""), для документа с типом хоз. операции ""%BusinessOperation%""';
						|en = 'You cannot specify the ""%Products%"" traceable work (line %LineNumber% of the ""Items"" list) for the document with the ""%BusinessOperation%"" business transaction type'; fa = 'You cannot specify the ""%Products%"" traceable work (line %LineNumber% of the ""Items"" list) for the document with the ""%BusinessOperation%"" business transaction type';
						|it = 'Нельзя указывать прослеживаемую работу ""%Products%"" (строка %LineNumber% списка ""Товары""), для документа с типом хоз. операции ""%BusinessOperation%""';
						|pl = 'You cannot specify the ""%Products%"" traceable work (line %LineNumber% of the ""Items"" list) for the document with the ""%BusinessOperation%"" business transaction type';
						|tr = 'Ticari işlem türüne sahip bir belge için izlenebilir bir işlem “%Products%“ (liste satırı %LineNumber% ‘Mallar’) belirtemezsiniz ""%BusinessOperation%""'");
		ErrorText = StrReplace(ErrorText, "%Products%",          Selection.Products);
		ErrorText = StrReplace(ErrorText, "%LineNumber%",           Selection.LineNumber);
		ErrorText = StrReplace(ErrorText, "%BusinessOperation%", DocumentPurchases.BusinessOperation);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber,"Products"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure

// Displays error messages about the absence of an agreement in the purchase document
//
// Parameters:
// ThereAreErrorsAgreementIsNotSpecified - Boolean - indicates if there is an error or if the agreement is incomplete 
// DocumentPurchases               - DocumentObject - The object for which you want to show error messages
// Cancel                         - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsAgreementNotSpecified(ThereAreErrorsAgreementIsNotSpecified, DocumentPurchases, Cancel)
	
	If ThereAreErrorsAgreementIsNotSpecified Then
	
		ErrorText = NStr("vi = 'Chưa chỉ ra thỏa thuận. Không thể kết chuyển chứng từ mà không có thỏa thuận';
						|ru = 'Соглашение не указано. Документ не может быть проведен без согласования';
						|en = 'Agreement is not specified. The document cannot be posted without approval'; fa = 'Agreement is not specified. The document cannot be posted without approval';
						|it = 'Accordo non indicato. Il documento non può essere eseguito senza accordo';
						|pl = 'Umowa nie jest wskazana. Dokument nie może być zatwierdzony bez uzgodnienia';
						|tr = 'Anlaşma belirtilmedi. Belge onaylanmadan kaydedilemez'");
			
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			"Terms",
			,
			Cancel);
			
	EndIf;
		
EndProcedure

// Displays error messages about the availability of services in the purchase document
//
// Parameters:
// Selection         - QueryResultSelection
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - Flag for refusing to carry out the document
// DeviationTree  - ValueTree - Tree with deviations of the table part from the purchase conditions.
//
Procedure ReportErrorsAcceptanceOfManualDiscountsMargins(Val Selection,
	                                                       Val DocumentPurchases,
	                                                       Cancel,
	                                                       DeviationTree = Undefined)
	
	OutputToReport = (DeviationTree <> Undefined);
	
	While Selection.Next() Do
		
		If Selection.ThereAreErrorsFillingManualMarkUp Then
			LineNumber = Selection.LineNumber;
			ErrorText = NStr("vi = 'Phụ thu thủ công vượt phụ thu được phép tối đa ""%MaximumAmountOfManualMarkUp% %"" ở dòng %LineNumber% trong danh sách ""Hàng hóa""';
							|ru = 'Ручная наценка превышает максимально допустимую наценку ""%MaximumAmountOfManualMarkUp% %"" в строке %LineNumber% списка ""Товары""';
							|en = 'Manual markup exceeds maximum allowed markup ""%MaximumAmountOfManualMarkUp% %"" in line %LineNumber% of the ""Goods"" list'; fa = 'Manual markup exceeds maximum allowed markup ""%MaximumAmountOfManualMarkUp% %"" in line %LineNumber% of the ""Goods"" list';
							|it = 'La maggiorazione manuale supera la maggiorazione massima consentita ""%MaximumAmountOfManualMarkUp% %"" nella riga  %LineNumber%  dell''elenco ""Prodotti""';
							|pl = 'Ręczna marża przekracza maksymalnie dopuszczalną marżę ""%MaximumAmountOfManualMarkUp% %"" w wierszu %LineNumber% listy ""Товары""';
							|tr = 'Manuel zam, ""Ürünler"" listesinin %LineNumber% satırında izin verilen maksimum zamı ""%MaximumAmountOfManualMarkUp%"" aşıyor'");
			ErrorText = StrReplace(ErrorText, "%MaximumAmountOfManualMarkUp%", Selection.MaximumAmountOfManualMarkUp);
			ErrorText = StrReplace(ErrorText, "%LineNumber%",                    LineNumber);
			
			If OutputToReport Then
				Reports.VariancesFromPurchaseConditions.AddRowDeviationToDeviationTree(LineNumber, "PercentRateOfManualDiscount", ErrorText, DeviationTree);
			Else
				CommonClientServer.MessageToUser(
					ErrorText,
					DocumentPurchases,
					CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber,"PercentRateOfManualDiscount"),
					,
					Cancel);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Displays error messages about filling in the warehouse in the purchase document
//
// Parameters:
// Selection         - QueryResultSelection
// DocumentPurchases - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCorrectWarehouseFilling(Val Selection,
	                                                    Val DocumentPurchases,
	                                                    Cancel)
	
	If Selection.Next() Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
						|ru = 'Поле ""Склад"" не заполнено';
						|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
						|it = 'Il campo ""Magazzino"" non è compilato';
						|pl = 'Nie wypełniono pola ""Magazyn""';
						|tr = '""Ambar"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			"Warehouse",
			,
			Cancel);
		
	EndIf;
	
EndProcedure

// Displays error messages about filling in the warehouse in the "Products" tabular part of the purchase document.
//
Procedure ReportErrorsInFillingOutWarehouseCorrectlyInProductsTabularSection(Val Selection,
	                                                    Val DocumentPurchases,
	                                                    Cancel,
	                                                    PresentationOfWarehouseField = Undefined)
	
	While Selection.Next() Do
		
		If Not ValueIsFilled(PresentationOfWarehouseField) Then
			PresentationOfWarehouseField = NStr("vi = 'Kho bãi';
												|ru = 'Склад';
												|en = 'Warehouse'; fa = 'Warehouse';
												|it = 'Magazzino';
												|pl = 'Magazyn';
												|tr = 'Ambar'");
		EndIf;
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 của danh sách ""%3""';
				|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
				|en = 'Column ""%1"" in line %2 of list ""%3"" is required'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required';
				|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
				|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
				|tr = '""%2"" listesinin %3 satırındaki ""%1"" sütunu doldurulmadı'"),
			PresentationOfWarehouseField,
			Selection.LineNumber,
			Selection.TabularSectionPresentation);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber,"Warehouse"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure

// Displays error messages about the correctness of filling in the payment schedule stages
//
// Parameters:
// Selection           - QueryResultSelection
// DocumentPurchases   - DocumentObject - The object for which you want to show error messages
// Cancel             - Boolean - Flag for refusing to carry out the document
// DeviationTree  - ValueTree - Tree with deviations of the table part from the purchase conditions.
//
Procedure ReportErrorsCorrectnessOfPaymentScheduleStages(Val Selection, Val DocumentPurchases, Cancel, DeviationTree = Undefined, ArrayOfDeviations = Undefined)
	
	DefaultGraph = New ValueTable();
	DefaultGraph.Columns.Add("PaymentOption");
	DefaultGraph.Columns.Add("CalculateFrom");
	DefaultGraph.Columns.Add("PaymentDate", Common.DateTypeDetails(DateFractions.Date));
	DefaultGraph.Columns.Add("PaymentPercentage");
	DefaultGraph.Columns.Add("PaymentAmount");
	DefaultGraph.Columns.Add("PackageDepositPercentage");
	DefaultGraph.Columns.Add("PackageDepositValue");
	DefaultGraph.Columns.Add("Move");
	DefaultGraph.Columns.Add("Formula");
	
	If Selection.Next() And Not Selection.InvoiceForOrders Then
		FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
		FillParameters.TheseAreSettlementsWithCustomers = False;
		FillParameters.InvoiceForOrders   = False;
		FillParameters.ARAPObjectSettings      = Selection.ARAPObjectSettings;
		FillParameters.ThisIsOrder             = Selection.ThisIsOrder;
		FillParameters.OrderDate           = ?(Selection.ThisIsOrder,Selection.Date,Date(1,1,1));
		FillParameters.ApprovalDate     = Selection.ApprovalDate;
		If Selection.NotShipInInstallments Then
			FillParameters.DateOfShipment = Selection.DateOfShipment;
			FillParameters.PayAmount       = 100;
			FillParameters.PackageDepositValue = 0;
		Else
			ManagerOfDocument = Common.ObjectManagerByRef(DocumentPurchases.Ref);
			SettlementParameters_ = ManagerOfDocument.SettlementParameters_(DocumentPurchases);
			If TypeOf(SettlementParameters_) = Type("Array") Then
				ParametersStructure = SettlementParameters_[0];
			Else
				ParametersStructure = SettlementParameters_;
			EndIf;
			GoodsTable = ARAPAccountingServer.TableOfOrderAmounts(DocumentPurchases, ParametersStructure);
			FillParameters.TabularSection = GoodsTable;
			FillParameters.PackageDepositValue = GoodsTable.Total("PackageDepositValue");
			FillParameters.PayAmount       = GoodsTable.Total("PaymentAmount");
		EndIf;
		FillParameters.Terms               = Selection.Terms;
		FillParameters.AgreementScheduleIsFilledIn = PaymentStepsServerCall.AgreementScheduleIsFilledIn(Selection.Terms);
		FillParameters.Calendar                = Selection.Calendar;
		
		PaymentStepsServer.FillInPaymentStages(DefaultGraph, FillParameters);
	EndIf;
	
	AmountOfInterestPayment = 0;
	AmountOfTemplatePaymentInterest = 0;
	OutputToReport = (DeviationTree <> Undefined);
	
	Selection.Reset();
	
	If Selection.Count() <> DefaultGraph.Count() Then
			
		ErrorText = NStr("vi = 'Số lượng các giai đoạn thanh toán trong chứng từ (%NumberOfDocumentStages%) cần trùng với số lượng giai đoạn trong lịch biểu (%NumberOfScheduleStages%)';
						|ru = 'Количество этапов оплаты в документе (%NumberOfDocumentStages%) должно совпадать с количеством этапов в графике (%NumberOfScheduleStages%)';
						|en = 'The number of payment milestones in the (%NumberOfDocumentStages%) document must match the number of stages in the (%NumberOfScheduleStages%) schedule'; fa = 'The number of payment milestones in the (%NumberOfDocumentStages%) document must match the number of stages in the (%NumberOfScheduleStages%) schedule';
						|it = 'La quantità delle fasi di pagamento nel documento (%NumberOfDocumentStages%) deve coincidere con la quantità di fasi nel grafico (%NumberOfScheduleStages%)';
						|pl = 'Ilość etapów płatności w dokumencie (%NumberOfDocumentStages%) powinna zgadzać się z ilością etapów w harmonogramie (%NumberOfScheduleStages%)';
						|tr = 'Belgedeki ödeme aşaması sayısı (%NumberOfDocumentStages%) programdaki aşama sayısıyla (%NumberOfScheduleStages%) eşleşmelidir'");
		ErrorText = StrReplace(ErrorText, "%NumberOfDocumentStages%", Selection.Count());
		ErrorText = StrReplace(ErrorText, "%NumberOfScheduleStages%",   DefaultGraph.Count());
		
		If OutputToReport Then
			Reports.VariancesFromPurchaseConditions.AddHeaderDeviationToArrayOfDeviations(NStr("vi = 'Các giai đoạn thanh toán';
																								|ru = 'Этапы оплаты';
																								|en = 'Payment milestones'; fa = 'مراحل پرداخت';
																								|it = 'Fasi del pagamento';
																								|pl = 'Etapy płatności';
																								|tr = 'Ödeme aşamaları'"), ErrorText, ArrayOfDeviations);
		Else
			CommonClientServer.MessageToUser(
				ErrorText,
				DocumentPurchases,
				"PaymentStepsText",
				Cancel);
		EndIf;
	EndIf;
	
	Cnt = 0;
	While Selection.Next() Do
		
		If Not Selection.ThereAreErrorsFillingStagesOfPaymentSchedule Then
			Return;
		EndIf;
		
		DefaultPlotLine = DefaultGraph[Cnt];
		
		LineNumber = Selection.LineNumber;
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Giai đoạn thanh toán""';
									|ru = 'в строке %LineNumber% списка ""Этапы оплаты""';
									|en = 'in line %LineNumber% of the ""Payment milestones"" list'; fa = 'in line %LineNumber% of the ""Payment milestones"" list';
									|it = 'nella riga  %LineNumber% dell''elenco ""Fasi di pagamento""';
									|pl = 'w wierszu %LineNumber% listy ""Этапы оплаты""';
									|tr = '""Ödeme Aşamaları"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", LineNumber);
		
		If DefaultPlotLine.PaymentOption <> Selection.PaymentOption Then
			
			ErrorText = NStr("vi = 'Phương án kiểm soát khác với giá trị trong lịch biểu thanh toán ""%TemplatePaymentOption%""';
							|ru = 'Вариант контроля отличается от значения в графике оплаты ""%TemplatePaymentOption%""';
							|en = 'Control option differs from the value in the ""%TemplatePaymentOption%"" payment schedule'; fa = 'Control option differs from the value in the ""%TemplatePaymentOption%"" payment schedule';
							|it = 'La variante di controllo differisce dal valore nel grafico di pagamento ""%TemplatePaymentOption%""';
							|pl = 'Wariant kontroli różni się od wartości w harmonogramie płatności ""%TemplatePaymentOption%""';
							|tr = 'Kontrol seçeneği, ""%TemplatePaymentOption%"" ödeme programındaki değerden farklı'");
			ErrorText = StrReplace(ErrorText, "%TemplatePaymentOption%", DefaultPlotLine.PaymentOption); 
			
			If OutputToReport Then
				Reports.VariancesFromPurchaseConditions.AddRowDeviationToDeviationTree(LineNumber, "PaymentOption", ErrorText, DeviationTree);
			Else
				CommonClientServer.MessageToUser(
					ErrorText + ErrorAddress,
					,
					"PaymentStepsText",
					,
					Cancel);
			EndIf;
		EndIf;
		
		If DefaultPlotLine.PaymentDate > Selection.PaymentDate Then
			
			ErrorText = NStr("vi = 'Ngày thanh toán phải nhỏ hơn ngày trong lịch thanh toán ""%TemplatePaymentDate%""';
							|ru = 'Дата платежа должна быть не меньше, чем в графике оплаты ""%TemplatePaymentDate%""';
							|en = 'Payment date must be not less than those specified in the payment schedule ""%TemplatePaymentDate%""'; fa = 'Payment date must be not less than those specified in the payment schedule ""%TemplatePaymentDate%""';
							|it = 'La data del pagamento non deve essere precedente a quanto indicato nel grafico di pagamento ""%TemplatePaymentDate%""';
							|pl = 'Data płatności powinna być nie mniejsza, niż w harmonogramie płatności ""%TemplatePaymentDate%""';
							|tr = 'Ödeme tarihi, ""%TemplatePaymentDate%"" ödeme programındaki tarihten önce olmamalıdır'");
			ErrorText = StrReplace(ErrorText, "%TemplatePaymentDate%", Format(DefaultPlotLine.PaymentDate, "DLF=DD")); 
			
			If OutputToReport Then
				Reports.VariancesFromPurchaseConditions.AddRowDeviationToDeviationTree(LineNumber, "PaymentDate", ErrorText, DeviationTree);
			Else
				CommonClientServer.MessageToUser(
					ErrorText + ErrorAddress,
					,
					"PaymentStepsText",
					,
					Cancel);
			EndIf;
		EndIf;
		
		AmountOfTemplatePaymentInterest = AmountOfTemplatePaymentInterest + DefaultPlotLine.PaymentPercentage;
		AmountOfInterestPayment = AmountOfInterestPayment + Selection.PaymentPercentage;
		
		If AmountOfInterestPayment > AmountOfTemplatePaymentInterest Then
			
			ErrorText = NStr("vi = 'Tiền lãi cho đến lần thanh toán tiếp theo trong lịch biểu (""%PaymentPercentage%%"") không được vượt quá lãi suất theo lịch trình của thỏa thuận (""%TemplatePaymentPercentage%%"")';
							|ru = 'Проценты до следующего платежа по графику (""%PaymentPercentage%%"") не должны превышать проценты по графику соглашения (""%TemplatePaymentPercentage%%"")';
							|en = 'Interest before the next payment on schedule (""%PaymentPercentage%%"") cannot exceed the interest under the agreement schedule (""%TemplatePaymentPercentage%%"")'; fa = 'Interest before the next payment on schedule (""%PaymentPercentage%%"") cannot exceed the interest under the agreement schedule (""%TemplatePaymentPercentage%%"")';
							|it = 'Gli interessi fino al prossimo pagamento in base al grafico (""%PaymentPercentage%%"") non devono essere superiori agli interessi in base al grafico dell''accordo (""%TemplatePaymentPercentage%%"")';
							|pl = 'Odsetki do następnej płatności wg harmonogramu (""%PaymentPercentage%%"") nie powinny przekraczać odsetki wg harmonogramu umowy (""%TemplatePaymentPercentage%%"")';
							|tr = 'Programa göre bir sonraki ödemeye kadar olan faiz (""%PaymentPercentage%%""), anlaşma planına göre olan faizi (""%TemplatePaymentPercentage%%"") aşmamalıdır'");
			ErrorText = StrReplace(ErrorText, "%PaymentPercentage%", AmountOfInterestPayment); 
			ErrorText = StrReplace(ErrorText, "%TemplatePaymentPercentage%", AmountOfTemplatePaymentInterest); 
			
			If OutputToReport Then
				Reports.VariancesFromPurchaseConditions.AddRowDeviationToDeviationTree(LineNumber, "PaymentPercentage", ErrorText, DeviationTree);
			Else
				CommonClientServer.MessageToUser(
					ErrorText + ErrorAddress,
					,
					"PaymentStepsText",
					,
					Cancel);
			EndIf;
		EndIf;
		
		Cnt = Cnt + 1 ;
		
	EndDo;

EndProcedure

// Displays error messages about the correctness of filling in returned products
//
// Parameters:
// 	ErrorsTable - ValueTable - Uploading the query result.
Procedure ReportErrorsInCorrectnessOfReturnedProducts(Val ErrorsTable)
	
	For Each ErrorString In ErrorsTable Do
		ErrorMessage = NStr("vi = 'Việc trả lại theo mặt hàng %Products% \ %Characteristic% vượt quá số lượng hàng hóa đã nhận theo chứng từ tiếp nhận %SalesNumber% đối với %Count%%UnitOfMeasure%';
							|ru = 'Возврат по номенклатуре %Products% \ %Characteristic% превышает количество полученных товаров по документу поступления %SalesNumber% на %Count% %UnitOfMeasure%';
							|en = 'Return on the %Products% item \ %Characteristic% exceeds the quantity of received goods under the receipt document %SalesNumber% for %Count% %UnitOfMeasure%'; fa = 'Return on the %Products% item \ %Characteristic% exceeds the quantity of received goods under the receipt document %SalesNumber% for %Count% %UnitOfMeasure%';
							|it = 'Reso in base alla nomenclatura %Products% \%Characteristic%supera la quantità di merci in base al documento di ricezione %SalesNumber% di %Count%%UnitOfMeasure%';
							|pl = 'Zwrot według produktu %Products% \ %Characteristic% przekracza ilość otrzymanych towarów według dokumentu przyjęcia %SalesNumber% o %Count% %UnitOfMeasure%';
							|tr = 'Öğeye göre iade %Products% \ %Characteristic%, giriş​​ belgesine göre alınan ürün miktarını aşıyor %SalesNumber%, %Miktar% %Count% %UnitOfMeasure%'");
		If ErrorString.Count < 0 Then
			ErrorMessage = StrReplace(ErrorMessage, "%Products%",         ErrorString.Products);
			ErrorMessage = StrReplace(ErrorMessage, "%Characteristic%",       ErrorString.Characteristic);
			ErrorMessage = StrReplace(ErrorMessage, "%Count%",          -ErrorString.Count);
			ErrorMessage = StrReplace(ErrorMessage, "%UnitOfMeasure%",     ErrorString.UnitOfMeasure);
			ErrorMessage = StrReplace(ErrorMessage, "%SalesNumber%",      ErrorString.NumberOfReceipt);
			If Not ValueIsFilled(ErrorString.Characteristic) Then
				ErrorMessage = StrReplace(ErrorMessage, " \ ",      "");
			EndIf;
			Common.MessageToUser(ErrorMessage);
		EndIf;
	EndDo; 
	
EndProcedure

// Displays error messages for monitoring the completion of calculations
//
// Parameters:
// Selection          - QueryResultSelection
// DocumentPurchases  - DocumentObject - The object for which you want to show error messages
// Cancel            - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsMonitoringCompletionOfCalculations(Val Selection, Val DocumentPurchases, Cancel)
	
	If Selection.Next() Then 
		If Selection.ThereAreIncompleteCalculations  Then
			ErrorText = NStr("vi = 'Chưa thực hiện thanh toán theo đơn hàng.
			|Để đóng đơn hàng, cần thanh toán %AmountToPay% %Currency%.
			|Chỉ có thể đóng đơn hàng với các dòng đã thanh toán/hủy bỏ toàn bộ';
			|ru = 'Расчеты по заказу не завершены.
			|Для закрытия заказа требуется оплата %AmountToPay% %Currency%.
			|Закрытие заказа возможно только с полностью оплаченными/отмененными строками';
			|en = 'Order settlements are not complete.
			|To close the order, payment required: %AmountToPay% %Currency%.
			|You can close orders only when all lines are paid/canceled'; fa = 'Order settlements are not complete.
			|To close the order, payment required: %AmountToPay% %Currency%.
			|You can close orders only when all lines are paid/canceled';
			|it = 'Le regolazioni dei conti relativi all''ordine non sono completi.
			|Per la chiusura dell''ordine è richiesto il pagamento di %AmountToPay% %Currency%.
			|È possibile concludere l''ordine soltanto se le righe sono completamente pagate/cancellate';
			|pl = 'Obliczenia z tytułu zamówienia nie są zakończone.
			|W celu zamknięcia zamówienia jest konieczna płatność %AmountToPay% %Currency%.
			|Zamknięcie zamówienia jest możliwe tylko z całkowicie opłaconymi/anulowanymi wierszami';
			|tr = 'Siparişin kapatılması tamamlanmamıştır.
			| Siparişi kapatmak için %AmountToPay% %Currency%bir ödeme yapılması gerekmektedir.
			| Sipariş yalnızca tamamen ödenmiş/iptal edilmiş satırlarla kapatılabilir'");
			
			ErrorText = StrReplace(ErrorText, "%AmountToPay%",      String(Selection.AmountDueClosingBalance));
			ErrorText = StrReplace(ErrorText, "%Currency%",      String(Selection.Currency));
			
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				,
				,
				Cancel);
		EndIf;
	EndIf;
		
	If DocumentPurchases.IsNew() Then
		
			ErrorText = NStr("vi = 'Đặt hàng chưa thanh toán. 
			|Chỉ có thể đóng đơn hàng với các dòng được thanh toán / hủy hoàn toàn';
			|ru = 'Заказ не оплачен. 
			|Закрытие заказа возможно только с полностью оплаченными/отмененными строками';
			|en = 'Order is not paid.
			|You can close orders only with fully paid/canceled lines'; fa = 'Order is not paid.
			|You can close orders only with fully paid/canceled lines';
			|it = 'Ordine non pagato.
			| L''ordine si può concludere solamente se le righe sono pagate completamente o annullate';
			|pl = 'Zamówienie nie jest opłacone. 
			|Zamknięcie zamówienia jest możliwe tylko z całkowicie opłaconymi/anulowanymi wierszami';
			|tr = 'Sipariş ödenmedi. 
			|Bir siparişin kapatılması yalnızca tamamen ödenen/iptal edilen satırlarla mümkündür'");
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				,
				,
				Cancel);
		
	EndIf;
	
EndProcedure

// Displays error messages about receipt completion control
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	DocumentPurchases  - DocumentObject - The object for which you want to show error messages
// 	Cancel            - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsReceiptControl (Val Selection, Val DocumentPurchases, Cancel)
	
	If Selection.Next() Then 
		If Selection.ThereIsIncompleteReceipt Then
			
			ErrorText = NStr("vi = 'Nguyên vật liệu theo đơn hàng chưa được tiếp nhận đầy đủ.
				|Chỉ có thể đóng đơn hàng với các dòng tiếp nhận/hủy bỏ toàn bộ';
				|ru = 'Сырье и материалы по заказу поступили не полностью.
				|Закрытие заказа возможно только с полностью поступившими/отмененными строками';
				|en = 'Raw and consumable materials against the order were received partially.
				|The order can be closed only for fully received/canceled lines'; fa = 'Raw and consumable materials against the order were received partially.
				|The order can be closed only for fully received/canceled lines';
				|it = 'Non sono stati ricevuti tutti i materiali come indicato da ordine.
				| La chiusura dell''ordine è possibile solamente quando tutte le righe sono completamente ricevute o annullate.';
				|pl = 'Surowiec i materiały na zamówienie wpłynęły nie w całości.
				|Zamknięcie zamówienia jest możliwe tylko z całkowicie otrzymanymi/anulowanymi wierszami';
				|tr = 'Siparişe ait hammadde ve malzemeler tam olarak giriş yapmadı.
				|Siparişin kapatılması yalnızca tam giriş yapan/iptal edilen satırlar ile mümkündür'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				,
				,
				Cancel);
			
		EndIf;
	EndIf;
	
	If DocumentPurchases.IsNew() Then
		
			ErrorText = NStr("vi = 'Nguyên vật liệu theo đơn hàng chưa được tiếp nhận đầy đủ.
				|Chỉ có thể đóng đơn hàng với các dòng tiếp nhận/hủy bỏ toàn bộ';
				|ru = 'Сырье и материалы по заказу не поступили.
				|Закрытие заказа возможно только с полностью поступившими/отмененными строками';
				|en = 'Raw and consumable materials against the order were not received.
				|The order can be canceled only for fully received/canceled lines'; fa = 'Raw and consumable materials against the order were not received.
				|The order can be canceled only for fully received/canceled lines';
				|it = 'I materiali come indicato da ordine non sono stati ricevuti.
				| La chiusura dell''ordine è possibile solamente quando tutte le righe sono completamente ricevute o annullate.';
				|pl = 'Surowiec i materiały na zamówienie nie wpłynęły.
				|Zamknięcie zamówienia jest możliwe tylko z całkowicie otrzymanymi/anulowanymi wierszami';
				|tr = 'Siparişe ait hammadde ve malzemeler giriş yapmadı.
				|Siparişin kapatılması yalnızca tam giriş yapan/iptal edilen satırlar ile mümkündür'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				,
				,
				Cancel);
		
	EndIf;
	
EndProcedure

// Displays error messages about filling in prices in the "Products" tabular part of the purchase document.
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	DocumentPurchases  - DocumentObject - The object for which you want to show error messages
// 	Cancel            - Boolean - flag for refusing to carry out the document.
// 
Procedure ReportErrorsPriceFillingControl(Val Selection,
	                                             Val DocumentPurchases,
	                                             Cancel)
	
	While Selection.Next() Do
		If Selection.ThereAreErrorsFillingPrices Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Đơn giá"" tại dòng %LineNumber% trong danh sách ""Hàng hóa""';
							|ru = 'Не заполнена колонка ""Цена"" в строке %LineNumber% списка ""Товары""';
							|en = 'Column ""Price"" in line %LineNumber% of the ""Goods"" list is not filled in'; fa = 'Column ""Price"" in line %LineNumber% of the ""Goods"" list is not filled in';
							|it = 'La colonna ""Prezzo"" nella riga %LineNumber% dell''elenco ""Merce"" non è stata compilata';
							|pl = 'Nie wypełniono kolumny ""Цена"" w wierszu %LineNumber% listy ""Товары""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Fiyat"" sütunu doldurulmadı'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%",  Selection.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				DocumentPurchases,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber,"Price"),
				,
				Cancel);
			
		EndIf;
			
		If Selection.ThereAreErrorsFillingAmounts Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Số tiền"" tại dòng %LineNumber% trong danh sách ""Hàng hóa""';
							|ru = 'Не заполнена колонка ""Сумма"" в строке %LineNumber% списка ""Товары""';
							|en = 'Column ""Amount"" in line %LineNumber% of the ""Goods"" list is not filled in'; fa = 'Column ""Amount"" in line %LineNumber% of the ""Goods"" list is not filled in';
							|it = 'La colonna ""Importo"" nella riga  %LineNumber% dell''elenco ""Merce"" non è stata compilata';
							|pl = 'Nie wypełniono kolumny ""Сумма"" w wierszu %LineNumber% listy ""Товары""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Tutar"" sütunu doldurulmadı'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%",  Selection.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				DocumentPurchases,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber,"Sum"),
				,
				Cancel);
			
		EndIf;
	EndDo;
	
EndProcedure

// Displays a message if the organization of the order differs from the organization of the document.
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	DocumentPurchases  - DocumentObject - The object for which you want to show error messages
// 	Cancel            - Boolean - flag for refusing to carry out the document.
// 
Procedure ReportErrorsInOrganizingOrders(Val Selection, Val DocumentPurchases, Cancel)
	
	While Selection.Next() Do
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Doanh nghiệp trong lệnh đã chỉ ra tại dòng %1 trong danh sách ""%2"" cần trùng với doanh nghiệp trên chứng từ';
				|ru = 'Организация распоряжения указанного в строке %1 списка ""%2"" должна совпадать с организацией документа';
				|en = 'The company in the reference specified in line %1 of the ""%2"" list must be the same as the company specified in the document.'; fa = 'The company in the reference specified in line %1 of the ""%2"" list must be the same as the company specified in the document.';
				|it = 'L''azienda di riferimento indicata nella riga %1 dell''elenco ""%2"" deve coincidere con l''azienda del documento';
				|pl = 'Firma zamówienia wskazanego w wierszu %1 listy ""%2"" powina zgadzać się z firmą dokumentu';
				|tr = '%1 satırında belirtilen ""%2"" sipariş listesinin düzeni, belgenin düzeniyle eşleşmelidir'"),
			Selection.LineNumber,
			Selection.TabularSectionPresentation);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "ReferenceOrder"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure

// Displays error messages about specifying the VAT rate in the table part of the purchase document.
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	DocumentPurchases  - DocumentObject - The object for which you want to show error messages
// 	Cancel            - Boolean - flag for refusing to carry out the document.
// 
Procedure ReportErrorsWhenSpecifyingPurchaseVATRateCorrectly(Val Selection, Val DocumentPurchases, Cancel)

	While Selection.Next() Do
		
		ErrorText = "";
		
		If ValueIsFilled(Selection.CorrectVATRate) Then
			ErrorText = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""Hàng hóa"", chọn tỷ lệ thuế GTGT ""%VATRate%"".';
							|ru = 'В строке %LineNumber% списка ""Товары"" необходимо выбрать ставку НДС ""%VATRate%"".';
							|en = 'Select VAT rate ""%VATRate%"" in line %LineNumber% of the ""Goods"" list.'; fa = 'Select VAT rate ""%VATRate%"" in line %LineNumber% of the ""Goods"" list.';
							|it = 'Nella riga %LineNumber% dell''elenco ""Merci"" è necessario scegliere l''aliquota IVA""%VATRate%"".';
							|pl = 'W wierszu %LineNumber% listy ""Wiersze pozycji"" należy wybrać stawkę VAT ""%VATRate%"".';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında, ""%VATRate%"" KDV oranını seç.'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%",        Selection.LineNumber);
			ErrorText = StrReplace(ErrorText, "%VATRate%",          Selection.CorrectVATRate);
			
		Else
			ErrorText = NStr("vi = 'Trong dòng %LineNumber% danh sách ""Hàng hóa"" chọn chế độ thuế không phù hợp ""%VATTaxation%"" thuế GTGT ""%VATRate%"".';
							|ru = 'В строке %LineNumber% списка ""Товары"" выбрана несоответствующая налогообложению ""%VATTaxation%"" ставка НДС ""%VATRate%"".';
							|en = 'VAT rate ""%VATRate%"" selected in line %LineNumber% of the ""Goods"" list does not match taxation ""%VATTaxation%""'; fa = 'VAT rate ""%VATRate%"" selected in line %LineNumber% of the ""Goods"" list does not match taxation ""%VATTaxation%""';
							|it = 'Nella riga %LineNumber% dell''elenco ""Merci"" è stata scelta non corrispondente alla tassazione""%VATTaxation%"" aliquota IVA ""%VATRate%"".';
							|pl = 'W wierszu %LineNumber% listy ""Товары"" wybrano nieodpowiednią do systemu opodatkowania ""%VATTaxation%"" stawkę VAT ""%VATRate%"".';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""%VATTaxation%"" vergilendirmesine karşılık gelmeyen KDV oranı ""%VATRate%"" seçildi.'");
			
			ErrorText = StrReplace(ErrorText, "%LineNumber%",        Selection.LineNumber);
			ErrorText = StrReplace(ErrorText, "%VATTaxation%", Selection.VATTaxation);
			ErrorText = StrReplace(ErrorText, "%VATRate%",          Selection.SelectedVATRate);
			
		EndIf;

			
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "VATRate"),
			Cancel);
		
	EndDo;
	
EndProcedure

// Displays error messages about specifying the VAT amount in the table part of the purchase document.
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	DocumentPurchases  - DocumentObject - The object for which you want to show error messages
// 	Cancel            - Boolean - flag for refusing to carry out the document.
// 
Procedure ReportErrorsCorrectnessOfPurchaseAmountAndVATAmount(Val Selection, Val DocumentPurchases, Cancel)
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Thuế GTGT %VATAmount% %Currency% thuế suất ""%VATRate%"" nhiều hơn dòng %Sum% %Currency%';
						|ru = 'Сумма НДС %VATAmount% %Currency% при ставке ""%VATRate%"" больше общей суммы по строке %Sum% %Currency%';
						|en = 'The VAT amount %VATAmount% %Currency% at rate %VATRate% exceeds the total amount for the line %Sum% %Currency%'; fa = 'The VAT amount %VATAmount% %Currency% at rate %VATRate% exceeds the total amount for the line %Sum% %Currency%';
						|it = 'Importo IVA %VATAmount% %Currency% при ставке ""%VATRate%"" больше общей суммы по строке %Sum% %Currency%';
						|pl = 'Wartość VAT %VATAmount% %Currency% przy stawce ""%VATRate%"" jest większa niż ogólna wartość wg wiersza %Sum% %Currency%';
						|tr = 'KDV tutarı %VATAmount% ""%VATRate%"" oranındaki %Currency%, satırındaki toplam tutardan büyük %Sum% %Currency%'");
		ErrorText = StrReplace(ErrorText, "%VATAmount%",          Selection.VATAmount);
		ErrorText = StrReplace(ErrorText, "%Sum%",             Selection.Sum);
		ErrorText = StrReplace(ErrorText, "%VATRate%",         Selection.VATRate);
		ErrorText = StrReplace(ErrorText, "%Currency%",            Selection.Currency);
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% danh sách ""%PresentationOfTS%""';
									|ru = 'в строке %LineNumber% списка ""%PresentationOfTS%""';
									|en = 'in line %LineNumber% of the ""%PresentationOfTS%"" list'; fa = 'in line %LineNumber% of the ""%PresentationOfTS%"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
									|pl = 'w wierszu %LineNumber% listy ""%PresentationOfTS%""';
									|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%",     Selection.LineNumber);
		ErrorAddress = StrReplace(ErrorAddress, "%PresentationOfTS%", Selection.TabularSectionPresentation);
		
		SalesServer.ReportErrorToUser(
			ErrorText + ErrorAddress,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "VATAmount"),
			Cancel);
				
	EndDo;
	
EndProcedure

// Displays error messages about matching the currency specified in the Agency purchase agreement and the document currency.
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	Sales Document - A Document Object.Return to the supplier-the document for which you want to display error messages.
// 	Cancel            - Boolean - flag for refusing to carry out the document.
//
Procedure ReportCurrencyMatchingErrorsForAgencyPurchases(Selection, DocumentPurchases, Cancel)
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Đối với mặt hàng %Nomeclature% được mua theo sơ đồ đại lý, loại tiền được chỉ định trong hợp đồng đích phải khớp với loại tiền của chứng từ';
						|ru = 'Для номенклатуры %Nomeclature%, закупаемой по агентской схеме, валюта, указанная в договоре назначения, должна совпадать с валютой документа';
						|en = 'The currency specified in the assignment contract must match with the currency of the document to %Nomeclature% items purchased on agency basis.'; fa = 'The currency specified in the assignment contract must match with the currency of the document to %Nomeclature% items purchased on agency basis.';
						|it = 'Per l''articolo %Nomeclature%, acquistato con il regime di agenzia, la valuta indicata nel contratto deve coincidere con la valuta del documento.';
						|pl = 'Dla nomenklatury %Nomeclature%, nabywanej wg schematu agencyjnego, waluta, podana w umowie przeznaczenia, powinna zbiegać się z walutą dokumentu';
						|tr = 'Acente şeması kapsamında satın alınan %Nomeclature% kalemi için, amaç sözleşmesinde belirtilen para birimi, belgenin para birimiyle eşleşmelidir'");
		ErrorText = StrReplace(ErrorText, "%Nomeclature%",          Selection.Products);
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% danh sách ""%PresentationOfTS%""';
									|ru = 'в строке %LineNumber% списка ""%PresentationOfTS%""';
									|en = 'in line %LineNumber% of the ""%PresentationOfTS%"" list'; fa = 'in line %LineNumber% of the ""%PresentationOfTS%"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
									|pl = 'w wierszu %LineNumber% listy ""%PresentationOfTS%""';
									|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%",     Selection.LineNumber);
		ErrorAddress = StrReplace(ErrorAddress, "%PresentationOfTS%", Selection.TabularSectionPresentation);
		
		SalesServer.ReportErrorToUser(
			ErrorText + ErrorAddress,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "Purpose"),
			Cancel);
				
	EndDo;
	
EndProcedure

// Displays error messages about filling in the customer's order if the shipment is used according to the Agency purchase scheme with separation by orders.
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	Sales Document - A Document Object.Storage shipment - a document for which you want to display error messages.
// 	Cancel            - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCustomerOrderControl(Selection, DocumentPurchases, Cancel)
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Chưa điền Đơn hàng của khách';
						|ru = 'Не заполнен Заказ клиента';
						|en = 'Sales order is not filled in'; fa = 'Sales order is not filled in';
						|it = 'Non compilato Ordine del cliente';
						|pl = 'Nie wypełniono Zamówienia klienta';
						|tr = 'Müşteri siparişi doldurulmadı'");
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% danh sách ""%PresentationOfTS%""';
									|ru = 'в строке %LineNumber% списка ""%PresentationOfTS%""';
									|en = 'in line %LineNumber% of the ""%PresentationOfTS%"" list'; fa = 'in line %LineNumber% of the ""%PresentationOfTS%"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
									|pl = 'w wierszu %LineNumber% listy ""%PresentationOfTS%""';
									|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%",     Selection.LineNumber);
		ErrorAddress = StrReplace(ErrorAddress, "%PresentationOfTS%", Selection.TabularSectionPresentation);
		
		SalesServer.ReportErrorToUser(
			ErrorText + ErrorAddress,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "SalesOrder"),
			Cancel);
				
	EndDo;
	
EndProcedure

// Displays error messages about filling in the destination.
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	Sales Document - A Document Object.Storage shipment - a document for which you want to display error messages.
// 	Cancel            - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsDestinationControl(Selection, DocumentPurchases, Cancel);
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Chưa điền giá trị';
						|ru = 'Не заполнено Назначение';
						|en = 'Assignment is not filled in'; fa = 'Assignment is not filled in';
						|it = 'Non compilato Destinazione';
						|pl = 'Nie wypełniono Przeznaczenie';
						|tr = 'Atama doldurulmadı'");
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% danh sách ""%PresentationOfTS%""';
									|ru = 'в строке %LineNumber% списка ""%PresentationOfTS%""';
									|en = 'in line %LineNumber% of the ""%PresentationOfTS%"" list'; fa = 'in line %LineNumber% of the ""%PresentationOfTS%"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
									|pl = 'w wierszu %LineNumber% listy ""%PresentationOfTS%""';
									|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%",     Selection.LineNumber);
		ErrorAddress = StrReplace(ErrorAddress, "%PresentationOfTS%", Selection.TabularSectionPresentation);
		
		SalesServer.ReportErrorToUser(
			ErrorText + ErrorAddress,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "Purpose"),
			Cancel);
				
	EndDo;
	
EndProcedure

// Displays error messages about the use of write-off of goods for expenses when household services are prohibited for this. operations.
//
// Parameters:
// 	Selection          - QueryResultSelection
// 	A Sales document is a document object.The acquisition of a service provider is a document for which you need to display error messages.
// 	Cancel            - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsAbilityToChargeItemsForExpenses(Selection, DocumentPurchases, Cancel)
	
	While Selection.Next() Do
		
		ErrorText = StrTemplate(NStr("vi = 'Đối với giao dịch kinh tế %1 cấm ghi giảm hàng hóa vào chi phí';
									|ru = 'Для хозяйственной операции %1 запрещено списание товаров на расходы';
									|en = 'You cannot write off goods as expenses for the %1 business transaction'; fa = 'You cannot write off goods as expenses for the %1 business transaction';
									|it = 'Per l''operazione commerciale %1 non è permesso lo storno di articoli di spesa';
									|pl = 'Dla operacji gospodarczej %1 zabroniony jest rozchód towarów na koszty';
									|tr = 'Ticari işlem için %1 ürünün gider kaydından düşülmesi yasaktır'"),
			Selection.BusinessOperation);
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""%PresentationOfTS%""';
									|ru = 'в строке %LineNumber% списка ""%PresentationOfTS%""';
									|en = 'in line %LineNumber% of the ""%PresentationOfTS%"" list'; fa = 'in line %LineNumber% of the ""%PresentationOfTS%"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
									|pl = 'w wierszu %LineNumber% listy ""%PresentationOfTS%""';
									|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%",     Selection.LineNumber);
		ErrorAddress = StrReplace(ErrorAddress, "%PresentationOfTS%", Selection.TabularSectionPresentation);
		
		SalesServer.ReportErrorToUser(
			ErrorText + ErrorAddress,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "ToExpenseAs"),
			Cancel);
				
	EndDo;
	
EndProcedure

// For use with the methods of software interface Whatsup
// Complements the passed Representation in the parameter parametersforforming the Representation with the formatted text of the fiscal transaction representation in the document.
//
// Parameters:
//	Basis - DocumentRef - Document used to enter the invoice / receipt;
//	ParametersForCreatingPresentation - See VATAccountingERP.InvoicesReceivedOnBasisOf
//
// Returns:
//	String, FormattedString - The representation in the parameter Parametres for the formation of the representation supplemented with the formatted text of the presentation of the fiscal transaction in the document.
Function SupplementPresentationWithPresentationOfFiscalTransactionInProcurementDocument(Basis, ParametersForCreatingPresentation) Export
	
	PresentationsArray = New Array;
	PresentationsArray.Add(ParametersForCreatingPresentation.Presentation);
	
	PossibleReceiptBreach = False;
	FiscalOperationLogData = Undefined;
	If TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		PossibleReceiptBreach = True;
		FiscalOperationLogData = EquipmentReceiptPrintersServerCall.FiscalOperationData(Basis);
	EndIf;
	
	If ( PossibleReceiptBreach
		  And ParametersForCreatingPresentation.Invoices_.Count()=0 
		  And ParametersForCreatingPresentation.DocumentOnBasisIsRequired) Then
		
		If FiscalOperationLogData = Undefined Then
			  
			If Not ParametersForCreatingPresentation.ThereIsRightToInteractivelyAddDocumentOnBasisOf Then
				
				If ValueIsFilled(ParametersForCreatingPresentation.Presentation) Then
					PresentationsArray.Add(".");
					PresentationsArray.Add(" ");
				EndIf;
				
				PresentationsArray.Add(
					New FormattedString(
						NStr("vi = 'đánh phiếu';
							|ru = 'пробить чек';
							|en = 'issue cash receipt'; fa = 'issue cash receipt';
							|it = 'emettere lo scontrino';
							|pl = 'wydrukuj paragon';
							|tr = 'fiş kes'"),,
						StyleColors.HyperlinkColor,,
						"IssueCashReceipt"));
						
			Else
				
				PresentationsArray.Add(" ");
				PresentationsArray.Add(NStr("vi = 'hoặc';
											|ru = 'или';
											|en = 'or'; fa = 'یا';
											|it = 'oppure';
											|pl = 'or';
											|tr = 'veya'"));
				PresentationsArray.Add(" ");
				PresentationsArray.Add(
					New FormattedString(
						NStr("vi = 'đánh phiếu';
							|ru = 'пробить чек';
							|en = 'issue cash receipt'; fa = 'issue cash receipt';
							|it = 'emettere lo scontrino';
							|pl = 'wydrukuj paragon';
							|tr = 'fiş kes'"),,
						StyleColors.HyperlinkColor,,
						"IssueCashReceipt"));
				
			EndIf;
					
		Else	
			
			If ValueIsFilled(ParametersForCreatingPresentation.Presentation) Then
				//The fact that the check has been broken replaces all the previous representation
				PresentationsArray.Clear();
			EndIf;
			
			PresentationsArray.Add(
				New FormattedString(
					StrTemplate(
						NStr("vi = 'Đã đánh phiếu số%1';
							|ru = 'Пробит чек №%1';
							|en = 'Receipt No.%1 is issued'; fa = 'Receipt No.%1 is issued';
							|it = 'Scontrino №%1 emesso';
							|pl = 'Wydrukowano paragon nr%1';
							|tr = 'Fiş No%1 kesildi'"),
						FiscalOperationLogData.CashRegisterReceiptNumber),,
					StyleColors.HyperlinkColor,,
					"OpenRecordOfFiscalTransaction"));
			
		EndIf;
				
	EndIf;
	
	Result = New FormattedString(PresentationsArray);
	
	Return Result;
	
EndFunction

// Raises an exception if the partner is not a supplier
//
// Parameters:
//	Partner       - CatalogRef.Partners - Verified partner.
//
Procedure CheckPossibilityOfEnteringBasedOnPartnerSupplierCompetitor(Partner) Export
	
	If Not ValueIsFilled(Partner) Then
		Return;
	EndIf;
	
	PartnerDetails_ = Common.ObjectAttributesValues(Partner, "Vendor,Competitor");
	
	If Not PartnerDetails_.Vendor And Not PartnerDetails_.Competitor Then
		
		If GetFunctionalOption("UseCompetitiveIntelligence") Then
			ErrorText = NStr("vi = 'Bạn hàng không phải là nhà cung cấp hoặc đối thủ cạnh tranh. Chỉ có thể nhập trên cơ sở đối với nhà cung cấp hoặc đối thủ cạnh tranh.';
							|ru = 'Партнер не является поставщиком или конкурентом. Ввод на основании доступен только для поставщика или конкурента.';
							|en = 'The partner is not a vendor or a competitor. Generation from base documents is only allowed for vendors or competitors.'; fa = 'The partner is not a vendor or a competitor. Generation from base documents is only allowed for vendors or competitors.';
							|it = 'Il partner non è un fornitore o un concorrente. L''inserimento in causale è disponibile solamente per fornitori o concorrenti.';
							|pl = 'Partner nie jest dostawcą lub konkurentem. Wprowadzenie na podstawie dostępne tylko dla dostawcy lub konkurenta.';
							|tr = 'İş ortağı, bir tedarikçi veya rakip değildir. Buna dayalı giriş yalnızca bir tedarikçi veya rakip için mevcuttur.'");
		Else
			ErrorText = NStr("vi = 'Bạn hàng không phải là nhà cung cấp. Chỉ có thể nhập trên cơ sở đối với nhà cung cấp.';
							|ru = 'Партнер не является поставщиком. Ввод на основании доступен только для поставщика.';
							|en = 'The partner is not a vendor. Generation from base documents is only allowed for vendors.'; fa = 'The partner is not a vendor. Generation from base documents is only allowed for vendors.';
							|it = 'Il partner non è un fornitore. L''inserimento in causale è disponibile solamente per fornitori.';
							|pl = 'Partner nie jest dostawcą. Wprowadzenie na podstawie dostępne tylko dla dostawcy.';
							|tr = 'İş ortağı bir tedarikçi değildir. Buna dayalı giriş yalnızca tedarikçi için mevcuttur.'");
		EndIf;
		
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			ErrorText = StrReplace(ErrorText, NStr("vi = 'Bạn hàng';
													|ru = 'Партнер';
													|en = 'Partner'; fa = 'شریک تجاری';
													|it = 'Partner';
													|pl = 'Partner';
													|tr = 'İş ortağı'"), NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Controparte';
																			|pl = 'Kontrahent';
																			|tr = 'Cari hesap'"));
		EndIf;
		
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

// Displays error messages about filling in the storage location in the "Products" tabular part of the purchase document.
//
// Parameters:
// Selection          - QueryResultSelection
// DocumentPurchases  - DocumentObject - The object for which you want to show error messages.
// Cancel            - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCorrectFillingOfStorageLocations(Val Selection, Val DocumentPurchases, Cancel)
	
	While Selection.Next() Do
		
		ErrorTextTemplate = NStr("vi = 'Chưa điền cột ""Nơi cất giữ"" trong dòng %1 của danh sách ""%2""';
								|ru = 'Не заполнена колонка ""Место хранения"" в строке %1 списка ""%2""';
								|en = 'Column ""Storage location"" in line %1 of the ""%2"" list is not filled in'; fa = 'Column ""Storage location"" in line %1 of the ""%2"" list is not filled in';
								|it = 'Colonna ""Posizione di stoccaggio"" nella riga %1 dell''elenco ""%2"" non compilata';
								|pl = 'Nie wypełniona kolumna ""Miejsce przechowywania"" w wierszu %1 listy ""%2""';
								|tr = '""%2"" listesinin %1 satırında ""Ambar konumu"" sütunu doldurulmadı'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTextTemplate,
			Selection.LineNumber,
			Selection.TabularSectionPresentation);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentPurchases,
			CommonClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "StorageLocation"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

// Sets a conditional value for the details related to the allocation of expenses in the table part "Goods".
//
// Parameters:
//	Form - ClientApplicationForm - the form for which the conditional design is configured.
//
Procedure EstablishConditionalAppearanceForExpenses(Form) Export
	
	// design of items and cost analytics

	// Disabling visibility of fields required for services and works for certain operations.

	Item = Form.ConditionalAppearance.Items.Add();
	
	ChargeItemsToExpensesElement  = Form.Items.GoodsToExpenseAs;  // FormField
	ItemGoodsExpenseItem    = Form.Items.GoodsExpenseItem;    // FormField
	ItemProductsExpenseAnalytics = Form.Items.GoodsDimensionOfExpenses; // FormField

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ChargeItemsToExpensesElement.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemGoodsExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemProductsExpenseAnalytics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks();

	Item.Appearance.SetParameterValue("Visible", False);

	// only view if the product

	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ChargeItemsToExpensesElement.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemGoodsExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemProductsExpenseAnalytics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	// only viewing if the job is under assignment

	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ChargeItemsToExpensesElement.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemGoodsExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemProductsExpenseAnalytics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	// view only if the service

	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ChargeItemsToExpensesElement.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	// explanatory inscription, if the product

	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemGoodsExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemProductsExpenseAnalytics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho công việc/dịch vụ không có mục đích>';
													|ru = '<для работ/услуг без назначения>';
													|en = '<for works/services without assignment>'; fa = '<for works/services without assignment>';
													|it = '<per i lavori/servizi senza assegnazione>';
													|pl = '<dla robót/usług bez przeznaczenia>';
													|tr = '<atama olmadan işler/hizmetler için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// explanatory inscription, if the work is for the purpose

	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemGoodsExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemProductsExpenseAnalytics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho công việc/dịch vụ không có mục đích>';
													|ru = '<для работ/услуг без назначения>';
													|en = '<for works/services without assignment>'; fa = '<for works/services without assignment>';
													|it = '<per i lavori/servizi senza assegnazione>';
													|pl = '<dla robót/usług bez przeznaczenia>';
													|tr = '<atama olmadan işler/hizmetler için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// explanatory inscription, if we do not write off work and expenses

	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemProductsExpenseAnalytics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi ghi giảm vào chi phí>';
													|ru = '<при списании на расходы>';
													|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
													|it = '<durante lo storno sulle spese>';
													|pl = '<przy wyksięgowaniu na rozchody>';
													|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// the mark of an unfilled expense item, if we write off for expenses

	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemGoodsExpenseItem.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// the text of the expense analysis, if the item is not selected
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemProductsExpenseAnalytics.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DimensionOfExpenses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn dạng chi phí>';
													|ru = '<выберите статью расходов>';
													|en = '<select an expense item>'; fa = '<select an expense item>';
													|it = '<selezionare la voce delle spese>';
													|pl = '<wybierz pozycję wydatków>';
													|tr = '<maliyet kalemini seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Cost analytics "View only" if the expense item is not filled in
	
	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemProductsExpenseAnalytics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctionsOfWorkingWithCCDNumbers

Function TextOfRequestForFormationOfTableOfCCDNumbers(DataAcquisitionOption)
	
	If DataAcquisitionOption = "ByReferences" Then
		
		QueryText =
		"SELECT
		|	FilterTable.NameOfOrderField AS DocumentSalesOfGoodsAndServices,
		|	FilterTable.Products        AS Products,
		|	FilterTable.Characteristic      AS Characteristic,
		|	FilterTable.Purpose          AS Purpose,
		|	FilterTable.Series               AS Series,
		|	FilterTable.Count          AS Count
		|INTO TTExternalTable
		|FROM
		|	&GoodsTable AS FilterTable
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	FilterTable.Products       AS Products,
		|	FilterTable.Characteristic     AS Characteristic,
		|	FilterTable.Purpose         AS Purpose,
		|	FilterTable.Series              AS Series,
		|	SUM(FilterTable.Count)  AS Count
		|INTO TTSelectionTable
		|FROM
		|	TTExternalTable AS FilterTable
		|
		|GROUP BY
		|	FilterTable.DocumentSalesOfGoodsAndServices,
		|	FilterTable.Products,
		|	FilterTable.Characteristic,
		|	FilterTable.Purpose,
		|	FilterTable.Series
		|
		|INDEX BY
		|	DocumentSalesOfGoodsAndServices,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT DISTINCT ALLOWED
		|	SaleAdjustment.Ref            AS Ref,
		|	SaleAdjustment.DocumentBasis AS DocumentBasis
		|INTO TTAdjustments
		|FROM
		|	TTSelectionTable AS FilterTable
		|		INNER JOIN Document.SaleAdjustment AS SaleAdjustment
		|		ON FilterTable.DocumentSalesOfGoodsAndServices = SaleAdjustment.DocumentBasis
		|WHERE
		|	SaleAdjustment.Posted
		|	AND NOT SaleAdjustment.AdjustmentKind IN(VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
		|													VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT ALLOWED
		|	DataSet.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	DataSet.Products       AS Products,
		|	DataSet.Characteristic     AS Characteristic,
		|	DataSet.Purpose         AS Purpose,
		|	DataSet.Series              AS Series,
		|	DataSet.CCDNumber           AS CCDNumber,
		|	SUM(DataSet.Count)  AS Count,
		|	CASE
		|		WHEN SUM(DataSet.Count) = 0
		|			THEN SUM(DataSet.Sum)
		|		ELSE CAST(SUM(DataSet.Sum) / SUM(DataSet.Count) AS NUMBER(31,2))
		|	END AS Price
		|INTO TTImplemented
		|FROM
		|	(SELECT
		|		FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|		FilterTable.Products       AS Products,
		|		FilterTable.Characteristic     AS Characteristic,
		|		FilterTable.Purpose         AS Purpose,
		|		FilterTable.Series              AS Series,
		|		GoodsSales_.CCDNumber        AS CCDNumber,
		|		GoodsSales_.Count      AS Count,
		|		(GoodsSales_.AmountIncludingVAT - CASE WHEN DocumentData.PriceIncludesVAT THEN 0 ELSE GoodsSales_.VATAmount END) AS Sum
		|	FROM
		|		TTSelectionTable AS FilterTable
		|			INNER JOIN Document.CustomerInvoice.InventoryKinds AS GoodsSales_
		|			ON FilterTable.DocumentSalesOfGoodsAndServices = GoodsSales_.Ref
		|				AND FilterTable.Products = GoodsSales_.ItemsLocationAttributes.Products
		|				AND FilterTable.Characteristic = GoodsSales_.ItemsLocationAttributes.Characteristic
		|				AND FilterTable.Purpose = GoodsSales_.ItemsLocationAttributes.Purpose
		|				AND FilterTable.Series = GoodsSales_.ItemsLocationAttributes.Series
		|			
		|			INNER JOIN Document.CustomerInvoice AS DocumentData
		|			ON GoodsSales_.Ref = DocumentData.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|		FilterTable.Products       AS Products,
		|		FilterTable.Characteristic     AS Characteristic,
		|		FilterTable.Purpose         AS Purpose,
		|		FilterTable.Series              AS Series,
		|		GoodsSales_.CCDNumber        AS CCDNumber,
		|		GoodsSales_.Count      AS Count,
		|		GoodsSales_.Sum           AS Sum
		|	FROM
		|		TTSelectionTable AS FilterTable
		|			INNER JOIN Document.GoodsShipmentToCustomer.InventoryKinds AS GoodsSales_
		|			ON FilterTable.DocumentSalesOfGoodsAndServices = GoodsSales_.Ref
		|				AND FilterTable.Products = GoodsSales_.ItemsLocationAttributes.Products
		|				AND FilterTable.Characteristic = GoodsSales_.ItemsLocationAttributes.Characteristic
		|				AND FilterTable.Purpose = GoodsSales_.ItemsLocationAttributes.Purpose
		|				AND FilterTable.Series = GoodsSales_.ItemsLocationAttributes.Series
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|		FilterTable.Products       AS Products,
		|		FilterTable.Characteristic     AS Characteristic,
		|		FilterTable.Purpose         AS Purpose,
		|		FilterTable.Series              AS Series,
		|		GoodsSales_.CCDNumber        AS CCDNumber,
		|		-GoodsSales_.Count     AS Count,
		|		-(GoodsSales_.AmountIncludingVAT - CASE WHEN DocumentData.PriceIncludesVAT THEN 0 ELSE GoodsSales_.VATAmount END) AS Sum
		|	FROM
		|		TTSelectionTable AS FilterTable
		|			INNER JOIN TTAdjustments AS AdjustingEntries
		|			ON FilterTable.DocumentSalesOfGoodsAndServices = AdjustingEntries.DocumentBasis
		|			
		|			INNER JOIN Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS GoodsSales_
		|			ON AdjustingEntries.Ref = GoodsSales_.Ref
		|				AND FilterTable.Products = GoodsSales_.ItemsLocationAttributes.Products
		|				AND FilterTable.Characteristic = GoodsSales_.ItemsLocationAttributes.Characteristic
		|				AND FilterTable.Purpose = GoodsSales_.ItemsLocationAttributes.Purpose
		|				AND FilterTable.Series = GoodsSales_.ItemsLocationAttributes.Series
		|			
		|			INNER JOIN Document.SaleAdjustment AS DocumentData
		|			ON GoodsSales_.Ref = DocumentData.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|		FilterTable.Products       AS Products,
		|		FilterTable.Characteristic     AS Characteristic,
		|		FilterTable.Purpose         AS Purpose,
		|		FilterTable.Series              AS Series,
		|		GoodsSales_.CCDNumber        AS CCDNumber,
		|		GoodsSales_.Count      AS Count,
		|		(GoodsSales_.AmountIncludingVAT - CASE WHEN DocumentData.PriceIncludesVAT THEN 0 ELSE GoodsSales_.VATAmount END) AS Sum
		|	FROM
		|		TTSelectionTable AS FilterTable
		|			INNER JOIN TTAdjustments AS AdjustingEntries
		|			ON FilterTable.DocumentSalesOfGoodsAndServices = AdjustingEntries.DocumentBasis
		|			
		|			INNER JOIN Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS GoodsSales_
		|			ON AdjustingEntries.Ref = GoodsSales_.Ref
		|				AND FilterTable.Products = GoodsSales_.ItemsLocationAttributes.Products
		|				AND FilterTable.Characteristic = GoodsSales_.ItemsLocationAttributes.Characteristic
		|				AND FilterTable.Purpose = GoodsSales_.ItemsLocationAttributes.Purpose
		|				AND FilterTable.Series = GoodsSales_.ItemsLocationAttributes.Series
		|			
		|			INNER JOIN Document.SaleAdjustment AS DocumentData
		|			ON GoodsSales_.Ref = DocumentData.Ref
		|	
		|	UNION ALL
		|
		|	SELECT
		|		FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|		FilterTable.Products       AS Products,
		|		FilterTable.Characteristic     AS Characteristic,
		|		FilterTable.Purpose         AS Purpose,
		|		FilterTable.Series              AS Series,
		|		GoodsSales_.CCDNumber        AS CCDNumber,
		|		GoodsSales_.Count      AS Count,
		|		(GoodsSales_.AmountIncludingVAT - CASE WHEN DocumentData.PriceIncludesVAT THEN 0 ELSE GoodsSales_.VATAmount END) AS Sum
		|	FROM
		|		TTSelectionTable AS FilterTable
		|			INNER JOIN Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS GoodsSales_
		|			ON FilterTable.DocumentSalesOfGoodsAndServices = GoodsSales_.Ref
		|				AND FilterTable.Products = GoodsSales_.ItemsLocationAttributes.Products
		|				AND FilterTable.Characteristic = GoodsSales_.ItemsLocationAttributes.Characteristic
		|				AND FilterTable.Purpose = GoodsSales_.ItemsLocationAttributes.Purpose
		|				AND FilterTable.Series = GoodsSales_.ItemsLocationAttributes.Series
		|	
		|			INNER JOIN Document.SaleAdjustment AS DocumentData
		|			ON GoodsSales_.Ref = DocumentData.Ref
		|
		|	UNION ALL
		|	
		|	SELECT
		|		FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|		FilterTable.Products       AS Products,
		|		FilterTable.Characteristic     AS Characteristic,
		|		FilterTable.Purpose         AS Purpose,
		|		FilterTable.Series              AS Series,
		|		GoodsSales_.CCDNumber        AS CCDNumber,
		|		GoodsSales_.Count      AS Count,
		|		(GoodsSales_.AmountIncludingVAT - CASE WHEN DocumentData.PriceIncludesVAT THEN 0 ELSE GoodsSales_.VATAmount END) AS Sum
		|	FROM
		|		TTSelectionTable AS FilterTable
		|			INNER JOIN Document.RetailSalesReport.InventoryKinds AS GoodsSales_
		|			ON FilterTable.DocumentSalesOfGoodsAndServices = GoodsSales_.Ref
		|				AND FilterTable.Products = GoodsSales_.ItemsLocationAttributes.Products
		|				AND FilterTable.Characteristic = GoodsSales_.ItemsLocationAttributes.Characteristic
		|				AND FilterTable.Purpose = GoodsSales_.ItemsLocationAttributes.Purpose
		|				AND FilterTable.Series = GoodsSales_.ItemsLocationAttributes.Series
		|			
		|			INNER JOIN Document.RetailSalesReport AS DocumentData
		|			ON GoodsSales_.Ref = DocumentData.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|		FilterTable.Products       AS Products,
		|		FilterTable.Characteristic     AS Characteristic,
		|		FilterTable.Purpose         AS Purpose,
		|		FilterTable.Series              AS Series,
		|		GoodsSales_.CCDNumber        AS CCDNumber,
		|		GoodsSales_.Count      AS Count,
		|		(GoodsSales_.AmountIncludingVAT - CASE WHEN DocumentData.PriceIncludesVAT THEN 0 ELSE GoodsSales_.VATAmount END) AS Sum
		|	FROM
		|		TTSelectionTable AS FilterTable
		|			INNER JOIN Document.CustomerInvoiceIntercompany.InventoryKinds AS GoodsSales_
		|			ON FilterTable.DocumentSalesOfGoodsAndServices = GoodsSales_.Ref
		|				AND FilterTable.Products = GoodsSales_.ItemsLocationAttributes.Products
		|				AND FilterTable.Characteristic = GoodsSales_.ItemsLocationAttributes.Characteristic
		|				AND FilterTable.Purpose = GoodsSales_.ItemsLocationAttributes.Purpose
		|				AND FilterTable.Series = GoodsSales_.ItemsLocationAttributes.Series
		|			
		|			INNER JOIN Document.CustomerInvoiceIntercompany AS DocumentData
		|			ON GoodsSales_.Ref = DocumentData.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FilterTable.DocumentSalesOfGoodsAndServices	AS DocumentSalesOfGoodsAndServices,
		|		FilterTable.Products			AS Products,
		|		FilterTable.Characteristic		AS Characteristic,
		|		FilterTable.Purpose			AS Purpose,
		|		FilterTable.Series					AS Series,
		|		GoodsSales_.CCDNumber			AS CCDNumber,
		|		-GoodsSales_.Count		AS Count,
		|		-(GoodsSales_.AmountIncludingVAT - CASE WHEN DocumentData.PriceIncludesVAT THEN 0 ELSE GoodsSales_.VATAmount END) AS Sum
		|	FROM
		|		TTSelectionTable AS FilterTable
		|			INNER JOIN Document.ReturnablePackagingRedemptionByCustomer.InventoryKinds AS GoodsSales_
		|			ON FilterTable.DocumentSalesOfGoodsAndServices = GoodsSales_.DocumentSalesOfGoodsAndServices
		|				AND FilterTable.Products = GoodsSales_.ItemsLocationAttributes.Products
		|				AND FilterTable.Characteristic = GoodsSales_.ItemsLocationAttributes.Characteristic
		|				AND FilterTable.Purpose = GoodsSales_.ItemsLocationAttributes.Purpose
		|				AND FilterTable.Series = GoodsSales_.ItemsLocationAttributes.Series
		|			
		|			INNER JOIN Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
		|			ON GoodsSales_.Ref = DocumentData.Ref
		|	
		|	) AS DataSet
		|
		|GROUP BY
		|	DataSet.DocumentSalesOfGoodsAndServices,
		|	DataSet.Products,
		|	DataSet.Characteristic,
		|	DataSet.Purpose,
		|	DataSet.Series,
		|	DataSet.CCDNumber
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 4
		|SELECT ALLOWED
		|	GoodsTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	GoodsTable.Products       AS Products,
		|	GoodsTable.Characteristic     AS Characteristic,
		|	GoodsTable.Purpose         AS Purpose,
		|	GoodsTable.Series              AS Series,
		|	GoodsTable.CCDNumber           AS CCDNumber,
		|	SUM(GoodsTable.Count)  AS Count
		|INTO TTReturnedItems
		|FROM
		|	TTSelectionTable AS FilterTable
		|		INNER JOIN Document.ReturnOfGoodsFromCustomer.Goods AS GoodsTable
		|		ON FilterTable.DocumentSalesOfGoodsAndServices = GoodsTable.DocumentSalesOfGoodsAndServices
		|			AND FilterTable.Products = GoodsTable.Products
		|			AND FilterTable.Characteristic = GoodsTable.Characteristic
		|			AND FilterTable.Purpose = GoodsTable.Purpose
		|			AND FilterTable.Series = GoodsTable.Series
		|			AND GoodsTable.Ref.Posted
		|			AND NOT GoodsTable.Ref = &Ref
		|
		|GROUP BY
		|	GoodsTable.DocumentSalesOfGoodsAndServices,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Purpose,
		|	GoodsTable.Series,
		|	GoodsTable.CCDNumber
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.DocumentTransfers_  AS DocumentSalesOfGoodsAndServices,
		|	GoodsTable.Products      AS Products,
		|	GoodsTable.Characteristic    AS Characteristic,
		|	GoodsTable.Purpose        AS Purpose,
		|	GoodsTable.Series             AS Series,
		|	GoodsTable.CCDNumber          AS CCDNumber,
		|	SUM(GoodsTable.Count) AS Count
		|FROM
		|	TTSelectionTable AS FilterTable
		|		INNER JOIN Document.IntercompanyGoodsReturn.Goods AS GoodsTable
		|		ON FilterTable.DocumentSalesOfGoodsAndServices = GoodsTable.DocumentTransfers_
		|			AND FilterTable.Products = GoodsTable.Products
		|			AND FilterTable.Characteristic = GoodsTable.Characteristic
		|			AND FilterTable.Purpose = GoodsTable.Purpose
		|			AND FilterTable.Series = GoodsTable.Series
		|		
		|		INNER JOIN Document.IntercompanyGoodsReturn AS DocumentData
		|		ON GoodsTable.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.Posted
		|	AND NOT DocumentData.Ref = &Ref
		|
		|GROUP BY
		|	GoodsTable.DocumentTransfers_,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Purpose,
		|	GoodsTable.Series,
		|	GoodsTable.CCDNumber
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 5
		|SELECT
		|	SoldGoods.DocumentSalesOfGoodsAndServices AS NameOfOrderField,
		|	SoldGoods.Products       AS Products,
		|	SoldGoods.Characteristic     AS Characteristic,
		|	SoldGoods.Purpose         AS Purpose,
		|	SoldGoods.Series              AS Series,
		|	SoldGoods.CCDNumber           AS CCDNumber,
		|	ISNULL(CCDNumbers.CCDNumberType, VALUE(Enum.CCDNumberTypes.EmptyRef)) AS CCDNumberType,
		|	ISNULL(CCDNumbers.OriginCountry, VALUE(Catalog.WorldCountries.EmptyRef)) AS OriginCountry,
		|	SUM(SoldGoods.Count - ISNULL(ReturnedGoods_.Count, 0)) AS Count,
		|	ISNULL(SoldGoods.Price, 0)  AS Price
		|FROM
		|	TTImplemented AS SoldGoods
		|		LEFT JOIN TTReturnedItems AS ReturnedGoods_
		|		ON SoldGoods.DocumentSalesOfGoodsAndServices = ReturnedGoods_.DocumentSalesOfGoodsAndServices
		|			AND SoldGoods.Products = ReturnedGoods_.Products
		|			AND SoldGoods.Characteristic = ReturnedGoods_.Characteristic
		|			AND SoldGoods.Purpose = ReturnedGoods_.Purpose
		|			AND SoldGoods.Series = ReturnedGoods_.Series
		|			AND SoldGoods.CCDNumber = ReturnedGoods_.CCDNumber
		|		
		|		LEFT JOIN Catalog.CCDNumbers AS CCDNumbers
		|		ON SoldGoods.CCDNumber = CCDNumbers.Ref
		|
		|GROUP BY
		|	SoldGoods.DocumentSalesOfGoodsAndServices,
		|	SoldGoods.Products,
		|	SoldGoods.Characteristic,
		|	SoldGoods.Purpose,
		|	SoldGoods.Series,
		|	SoldGoods.CCDNumber,
		|	ISNULL(CCDNumbers.CCDNumberType, VALUE(Enum.CCDNumberTypes.EmptyRef)),
		|	ISNULL(CCDNumbers.OriginCountry, VALUE(Catalog.WorldCountries.EmptyRef)),
		|	ISNULL(SoldGoods.Price, 0)
		|
		|HAVING
		|	SUM(SoldGoods.Count - ISNULL(ReturnedGoods_.Count, 0)) > 0";
		
	ElsIf DataAcquisitionOption = "ForBalancesTransferredToCommission" Then
		
		QueryText =
		"SELECT
		|	FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	FilterTable.Products       AS Products,
		|	FilterTable.Characteristic     AS Characteristic
		|INTO TTExternalTable
		|FROM
		|	&GoodsTable AS FilterTable
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT DISTINCT
		|	ItemsLocationAttributes.DimensionKey AS ItemsLocationAttributes
		|INTO TTSelectionTableSubmittedToCommission
		|FROM
		|	TTExternalTable AS FilterTable
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS ItemsLocationAttributes
		|		ON FilterTable.Products = ItemsLocationAttributes.Products
		|			AND FilterTable.Characteristic = ItemsLocationAttributes.Characteristic
		|			AND ItemsLocationAttributes.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|WHERE
		|	ItemsLocationAttributes.StorageLocation = &Partner
		|	AND ItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|
		|INDEX BY
		|	ItemsLocationAttributes.DimensionKey
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT DISTINCT
		|	&Partner                         AS Partner,
		|	FilterTable.Products       AS Products,
		|	FilterTable.Characteristic     AS Characteristic,
		|	FilterTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
		|INTO TTTableOfSelectionOfTransferredContainers
		|FROM
		|	TTExternalTable AS FilterTable
		|
		|INDEX BY
		|	&Partner,
		|	Products,
		|	Characteristic,
		|	DocumentSalesOfGoodsAndServices
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT
		|	DataSet.DocumentSalesOfGoodsAndServices  AS DocumentSalesOfGoodsAndServices,
		|	DataSet.Products        AS Products,
		|	DataSet.Characteristic      AS Characteristic,
		|	DataSet.Purpose          AS Purpose,
		|	DataSet.Series               AS Series,
		|	DataSet.CCDNumber            AS CCDNumber,
		|	DataSet.CCDNumberType        AS CCDNumberType,
		|	DataSet.OriginCountry AS OriginCountry,
		|	SUM(DataSet.Count)   AS Count
		|FROM
		|	(SELECT
		|		UNDEFINED AS DocumentSalesOfGoodsAndServices,
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes.Products   AS Products,
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes.Characteristic AS Characteristic,
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes.Purpose     AS Purpose,
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes.Series          AS Series,
		|		GoodsTransferredToCommissionAgent.CCDNumber                                  AS CCDNumber,
		|		GoodsTransferredToCommissionAgent.CCDNumber.CCDNumberType                     AS CCDNumberType,
		|		GoodsTransferredToCommissionAgent.CCDNumber.OriginCountry              AS OriginCountry,
		|		GoodsTransferredToCommissionAgent.CountBalance                         AS Count
		|	FROM
		|		AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(
		|				&Period,
		|				ItemsLocationAttributes IN
		|					(SELECT
		|						TTSelectionTableSubmittedToCommission.ItemsLocationAttributes
		|					FROM
		|						TTSelectionTableSubmittedToCommission AS TTSelectionTableSubmittedToCommission)
		|				AND Organization = &Organization
		|		) AS GoodsTransferredToCommissionAgent
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		UNDEFINED AS DocumentSalesOfGoodsAndServices,
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes.Products   AS Products,
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes.Characteristic AS Characteristic,
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes.Purpose     AS Purpose,
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes.Series          AS Series,
		|		GoodsTransferredToCommissionAgent.CCDNumber                                  AS CCDNumber,
		|		GoodsTransferredToCommissionAgent.CCDNumber.CCDNumberType                     AS CCDNumberType,
		|		GoodsTransferredToCommissionAgent.CCDNumber.OriginCountry              AS OriginCountry,
		|		CASE
		|			WHEN GoodsTransferredToCommissionAgent.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|				GoodsTransferredToCommissionAgent.Count
		|			ELSE
		|				-GoodsTransferredToCommissionAgent.Count
		|		END                                                                AS Count
		|	FROM
		|		AccumulationRegister.GoodsTransferredToCommissionAgent AS GoodsTransferredToCommissionAgent
		|	WHERE
		|		GoodsTransferredToCommissionAgent.ItemsLocationAttributes IN
		|			(SELECT
		|				TTSelectionTableSubmittedToCommission.ItemsLocationAttributes
		|			FROM
		|				TTSelectionTableSubmittedToCommission AS TTSelectionTableSubmittedToCommission)
		|		AND GoodsTransferredToCommissionAgent.Organization = &Organization
		|		AND GoodsTransferredToCommissionAgent.Recorder = &Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TransferredPackage.DocumentTransfers_              AS DocumentSalesOfGoodsAndServices,
		|		TransferredPackage.Products                  AS Products,
		|		TransferredPackage.Characteristic                AS Characteristic,
		|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|		TransferredPackage.CCDNumber                      AS CCDNumber,
		|		TransferredPackage.CCDNumber.CCDNumberType         AS CCDNumberType,
		|		TransferredPackage.CCDNumber.OriginCountry  AS OriginCountry,
		|		TransferredPackage.CountBalance             AS Count
		|	FROM
		|		AccumulationRegister.TransferredReturnablePackaging.Balance(
		|				&Period,
		|				(Partner, Products, Characteristic, DocumentTransfers_) IN
		|					(SELECT
		|						TTTableOfSelectionOfTransferredContainers.Partner,
		|						TTTableOfSelectionOfTransferredContainers.Products,
		|						TTTableOfSelectionOfTransferredContainers.Characteristic,
		|						TTTableOfSelectionOfTransferredContainers.DocumentSalesOfGoodsAndServices
		|					FROM
		|						TTTableOfSelectionOfTransferredContainers AS TTTableOfSelectionOfTransferredContainers)
		|		
		|		) AS TransferredPackage
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TransferredPackage.DocumentTransfers_              AS DocumentSalesOfGoodsAndServices,
		|		TransferredPackage.Products                  AS Products,
		|		TransferredPackage.Characteristic                AS Characteristic,
		|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|		TransferredPackage.CCDNumber                      AS CCDNumber,
		|		TransferredPackage.CCDNumber.CCDNumberType         AS CCDNumberType,
		|		TransferredPackage.CCDNumber.OriginCountry  AS OriginCountry,
		|		CASE
		|			WHEN TransferredPackage.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|				TransferredPackage.Count
		|			ELSE
		|				-TransferredPackage.Count
		|		END                                        AS Count
		|	FROM
		|		AccumulationRegister.TransferredReturnablePackaging AS TransferredPackage
		|	WHERE
		|		(Partner, Products, Characteristic, DocumentTransfers_) IN
		|			(SELECT
		|				TTTableOfSelectionOfTransferredContainers.Partner,
		|				TTTableOfSelectionOfTransferredContainers.Products,
		|				TTTableOfSelectionOfTransferredContainers.Characteristic,
		|				TTTableOfSelectionOfTransferredContainers.DocumentSalesOfGoodsAndServices
		|			FROM
		|				TTTableOfSelectionOfTransferredContainers AS TTTableOfSelectionOfTransferredContainers)
		|		AND TransferredPackage.Recorder = &Ref
		|	
		|	) AS DataSet
		|
		|WHERE
		|	DataSet.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
		|
		|GROUP BY
		|	DataSet.DocumentSalesOfGoodsAndServices,
		|	DataSet.Products,
		|	DataSet.Characteristic,
		|	DataSet.Purpose,
		|	DataSet.Series,
		|	DataSet.CCDNumber,
		|	DataSet.CCDNumberType,
		|	DataSet.OriginCountry
		|
		|HAVING
		|	SUM(DataSet.Count) <> 0
		|";
		
	ElsIf DataAcquisitionOption = "KeeperSLeftovers" Then
		
		QueryText =
		"SELECT
		|	FilterTable.Products   AS Products,
		|	FilterTable.Characteristic AS Characteristic,
		|	FilterTable.Purpose     AS Purpose,
		|	FilterTable.Series          AS Series
		|INTO TTExternalTable
		|FROM
		|	&GoodsTable AS FilterTable
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT DISTINCT
		|	ItemsLocationAttributes.DimensionKey AS DimensionKey
		|INTO TTSelectionTable
		|FROM
		|	InformationRegister.ItemsLocationAttributes AS ItemsLocationAttributes
		|		INNER JOIN TTExternalTable AS FilterTable
		|		ON ItemsLocationAttributes.Products = FilterTable.Products
		|			AND ItemsLocationAttributes.Characteristic = FilterTable.Characteristic
		|			AND ItemsLocationAttributes.Series = FilterTable.Series
		|			AND ItemsLocationAttributes.Purpose = FilterTable.Purpose
		|WHERE
		|	ItemsLocationAttributes.StorageLocation = &Contract
		|
		|INDEX BY
		|	DimensionKey
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	DataSet.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DataSet.CCDNumber AS CCDNumber,
		|	SUM(DataSet.Count) AS Count
		|INTO TTTableTransmitted
		|FROM
		|	(SELECT
		|		CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		CompanyGoodsBalance.CCDNumber AS CCDNumber,
		|		CompanyGoodsBalance.CountBalance AS Count
		|	FROM
		|		AccumulationRegister.CompanyGoods.Balance(
		|				&Period,
		|				ItemsLocationAttributes IN
		|						(SELECT
		|							TTSelectionTable.DimensionKey AS DimensionKey
		|						FROM
		|							TTSelectionTable AS TTSelectionTable)
		|					AND Organization = &Organization) AS CompanyGoodsBalance
		|	WHERE
		|		CompanyGoodsBalance.CountBalance > 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CompanyGoods.ItemsLocationAttributes,
		|		CompanyGoods.CCDNumber,
		|		CASE
		|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN CompanyGoods.Count
		|			ELSE -CompanyGoods.Count
		|		END
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoods
		|	WHERE
		|		CompanyGoods.ItemsLocationAttributes IN
		|				(SELECT
		|					TTSelectionTable.DimensionKey AS DimensionKey
		|				FROM
		|					TTSelectionTable AS TTSelectionTable)
		|		AND CompanyGoods.Organization = &Organization
		|		AND CompanyGoods.Recorder = &Ref
		|		AND CompanyGoods.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)) AS DataSet
		|WHERE
		|	DataSet.Count > 0
		|
		|GROUP BY
		|	DataSet.ItemsLocationAttributes,
		|	DataSet.CCDNumber
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT
		|	TTTableTransmitted.ItemsLocationAttributes.Products   AS Products,
		|	TTTableTransmitted.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	TTTableTransmitted.ItemsLocationAttributes.Series          AS Series,
		|	TTTableTransmitted.ItemsLocationAttributes.Purpose     AS Purpose,
		|	TTTableTransmitted.CCDNumber                                  AS CCDNumber,
		|	TTTableTransmitted.CCDNumber.CCDNumberType                     AS CCDNumberType,
		|	TTTableTransmitted.CCDNumber.OriginCountry              AS OriginCountry,
		|	TTTableTransmitted.Count                                AS Count
		|FROM
		|	TTTableTransmitted AS TTTableTransmitted";
		
	ElsIf DataAcquisitionOption = "ByBalanceOnWay" Then
		
		QueryText =
		"SELECT DISTINCT
		|	FilterTable.Products                         AS Products,
		|	FilterTable.Characteristic                       AS Characteristic,
		|	FilterTable.Purpose                           AS Purpose,
		|	CASE
		|		WHEN FilterTable.BatchesIndicationStatusOfGoodsTransferred <> 0
		|			THEN FilterTable.Series
		|		ELSE
		|			VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END                                              AS Series,
		|	FilterTable.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred
		|INTO TTExternalTable
		|FROM
		|	&GoodsTable AS FilterTable
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT DISTINCT
		|	ItemsLocationAttributes.DimensionKey AS DimensionKey
		|INTO TTSelectionTable
		|FROM
		|	InformationRegister.ItemsLocationAttributes AS ItemsLocationAttributes
		|		INNER JOIN TTExternalTable AS FilterTable
		|		ON ItemsLocationAttributes.Products = FilterTable.Products
		|			AND ItemsLocationAttributes.Characteristic = FilterTable.Characteristic
		|			AND ItemsLocationAttributes.Series = FilterTable.Series
		|			AND ItemsLocationAttributes.Purpose = FilterTable.Purpose
		|WHERE
		|	ItemsLocationAttributes.StorageLocation = &Contract
		|
		|INDEX BY
		|	DimensionKey
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	DataSet.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DataSet.CCDNumber AS CCDNumber,
		|	SUM(DataSet.Count) AS Count
		|INTO TTTableTransmitted
		|FROM
		|	(SELECT
		|		CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		CompanyGoodsBalance.CCDNumber AS CCDNumber,
		|		CompanyGoodsBalance.CountBalance AS Count
		|	FROM
		|		AccumulationRegister.CompanyGoods.Balance(
		|				&Period,
		|				ItemsLocationAttributes IN
		|						(SELECT
		|							TTSelectionTable.DimensionKey AS DimensionKey
		|						FROM
		|							TTSelectionTable AS TTSelectionTable)
		|					AND Organization = &Organization) AS CompanyGoodsBalance
		|	WHERE
		|		CompanyGoodsBalance.CountBalance > 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CompanyGoods.ItemsLocationAttributes,
		|		CompanyGoods.CCDNumber,
		|		CASE
		|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN CompanyGoods.Count
		|			ELSE -CompanyGoods.Count
		|		END
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoods
		|	WHERE
		|		CompanyGoods.ItemsLocationAttributes IN
		|				(SELECT
		|					TTSelectionTable.DimensionKey AS DimensionKey
		|				FROM
		|					TTSelectionTable AS TTSelectionTable)
		|		AND CompanyGoods.Organization = &Organization
		|		AND CompanyGoods.Recorder = &Ref
		|		AND CompanyGoods.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)) AS DataSet
		|WHERE
		|	DataSet.Count > 0
		|
		|GROUP BY
		|	DataSet.ItemsLocationAttributes,
		|	DataSet.CCDNumber
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT
		|	TTTableTransmitted.ItemsLocationAttributes.Products     AS Products,
		|	TTTableTransmitted.ItemsLocationAttributes.Characteristic   AS Characteristic,
		|	TTTableTransmitted.ItemsLocationAttributes.Series            AS Series,
		|	TTTableTransmitted.ItemsLocationAttributes.Purpose       AS Purpose,
		|	TTTableTransmitted.CCDNumber                                    AS CCDNumber,
		|	TTTableTransmitted.CCDNumber.CCDNumberType                       AS CCDNumberType,
		|	TTTableTransmitted.CCDNumber.OriginCountry                AS OriginCountry,
		|	TTTableTransmitted.Count                                  AS Count,
		|	ISNULL(FilterTable.BatchesIndicationStatusOfGoodsTransferred, 0) AS BatchesIndicationStatusOfGoodsTransferred
		|FROM
		|	TTTableTransmitted AS TTTableTransmitted
		|	LEFT JOIN TTExternalTable AS FilterTable
		|		ON TTTableTransmitted.ItemsLocationAttributes.Products = FilterTable.Products
		|			AND TTTableTransmitted.ItemsLocationAttributes.Characteristic = FilterTable.Characteristic
		|			AND TTTableTransmitted.ItemsLocationAttributes.Purpose = FilterTable.Purpose
		|			AND TTTableTransmitted.ItemsLocationAttributes.Series = FilterTable.Series";
		
	Else
		Raise NStr("vi = 'Không hỗ trợ phương án nhận dữ liệu theo số tờ khai hải quan.';
					|ru = 'Неподдерживаемый вариант получения данных по номерам ГТД.';
					|en = 'Unsupported option of CFD numbers data receipt.'; fa = 'Unsupported option of CFD numbers data receipt.';
					|it = 'Opzione non supportata per ottenere i dati sui numeri della polizza doganale di carico.';
					|pl = 'Nieobsługiwana opcja pobierania danych według numerów ŁDC.';
					|tr = 'Gümrük Kargo Beyannamesi numaralarıyla veri almak için desteklenmeyen seçenek.'");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function CreateCompositeTraceableCCDNumber(AccessoriesForCreatingCompositeCCDNumber,
	ThisIsBasicKit,
	ItemOfHeader = Undefined,
	CharacteristicsOfCap = Undefined,
	CapsBatch = Undefined,
	AmountByProductBatchID = 0,
	AlwaysUseAmountByProductBatchIDForCostOfKit = False)
	
	AttributesOfCCD = "Code, OriginCountry";
	
	Filter = New Structure("ThisIsBasicKit", ThisIsBasicKit);
	FoundRows = AccessoriesForCreatingCompositeCCDNumber.FindRows(Filter);
	
	CompositeNumberOfCCDObject = Catalogs.CCDNumbers.CreateItem();
	Initialized = False;
	
	AmountByTS = 0;
	For Each String In FoundRows Do
		If Not Initialized Then
			ValuesOfAttributesOfCCD = Common.ObjectAttributesValues(String.ProductBatchIDNumber, AttributesOfCCD);
			
			CompositeNumberOfCCDObject.Code = ValuesOfAttributesOfCCD.Code;
			CompositeNumberOfCCDObject.OriginCountry = ValuesOfAttributesOfCCD.OriginCountry;
			CompositeNumberOfCCDObject.CCDNumberType = Enums.CCDNumberTypes.KitRNPT;
			CompositeNumberOfCCDObject.Products = ItemOfHeader;
			If ItemOfHeader <> Undefined Then
				CompositeNumberOfCCDObject.ProductName = Common.ObjectAttributeValue(ItemOfHeader, "DescriptionFull");
				CompositeNumberOfCCDObject.AmountByProductBatchID = AmountByProductBatchID;
				If CompositeNumberOfCCDObject.AmountByProductBatchID = 0 Then
					CompositeNumberOfCCDObject.AmountByProductBatchID = AmountForSelectedTraceableGoods(ItemOfHeader, CharacteristicsOfCap, CapsBatch);
				EndIf;
			EndIf;
			
			If AlwaysUseAmountByProductBatchIDForCostOfKit Then
				CompositeNumberOfCCDObject.AmountByProductBatchID = AmountByProductBatchID;
			EndIf;
			
			Initialized = True;
		EndIf;
		NewRow = CompositeNumberOfCCDObject.TraceableComponents.Add();
		NewRow.ProductBatchIDNumber = String.ProductBatchIDNumber;
		NewRow.QuantityByGBRN = String.QuantityByGBRN;
		NewRow.FEACNUnitOfMeasure = String.FEACNUnitOfMeasure;
		
		NewRow.AmountByProductBatchID = AmountForSelectedTraceableGoods(String.Products, String.Characteristic, String.Series, String.ProductBatchIDNumber, String.QuantityByGBRN);
		If AlwaysUseAmountByProductBatchIDForCostOfKit Or NewRow.AmountByProductBatchID = 0 Then
			NewRow.AmountByProductBatchID = String.AmountByProductBatchID;
		EndIf;
		
		AmountByTS = AmountByTS + NewRow.AmountByProductBatchID;
		
	EndDo;
	CompositeNumberOfCCDObject.TraceableComponents.GroupBy("ProductBatchIDNumber,FEACNUnitOfMeasure", "QuantityByGBRN,AmountByProductBatchID");
	
	CompositeNumberOfCCDObject.NumberOfComponents_ = CompositeNumberOfCCDObject.TraceableComponents.Count();
	If CompositeNumberOfCCDObject.AmountByProductBatchID < AmountByTS Then
		CompositeNumberOfCCDObject.AmountByProductBatchID = AmountByTS;
	EndIf;
	
	CompositeNumberOfCCDObject.Write();
	
	Return CompositeNumberOfCCDObject.Ref;
	
EndFunction

Function AmountForSelectedTraceableGoods(Products, Characteristic, Series, ProductBatchIDNumber = Undefined, QuantityByGBRN = 1)
	
	FilterParameterStructure = EnterprisePricesFillingServer.NewSelectionParametersGetPriceBySelection();
	
	FilterParameterStructure.Date = CurrentSessionDate();
	FilterParameterStructure.Products = Products;
	FilterParameterStructure.Characteristic = Characteristic;
	FilterParameterStructure.Series = Series;
	FilterParameterStructure.PriceKind = AccountingForTraceableGoodsLocalization.PriceTypeOfCostOfTraceableGoods();
	FilterParameterStructure.Currency = Common.ObjectAttributeValue(FilterParameterStructure.PriceKind, "PriceCurrency");
	
	Price = EnterprisePricesFillingServer.GetPriceBySelection(FilterParameterStructure);
	
	If Price = 0 And ValueIsFilled(Series) Then
		FilterParameterStructure.Series = Catalogs.ItemsBatches.EmptyRef();
		Price = EnterprisePricesFillingServer.GetPriceBySelection(FilterParameterStructure);
	EndIf;
	
	Sum = Price * QuantityByGBRN;
	
	If Sum = 0 And ProductBatchIDNumber <> Undefined Then
		Sum = Common.ObjectAttributeValue(ProductBatchIDNumber, "AmountByProductBatchID");
		Sum = Sum * QuantityByGBRN;
	EndIf;
	
	Return Sum;
	
EndFunction

Function ReplaceParametersOfTextOfDisassemblyRequestForCompositeTraceableCCDNumbers(QueryText, Templates_Parameters, Fields)
	For Each KeyValue In Templates_Parameters Do
		Template = KeyValue.Key;
		Parameter_For_Substitution = KeyValue.Value;
		
		FieldsSet = New Array();
		For Each FieldName In Fields Do
			FieldsSet.Add(StrTemplate(Template, FieldName));
		EndDo;
		AssembledSubstring = StrConcat(FieldsSet, Chars.LF);
		QueryText = StrReplace(QueryText, Parameter_For_Substitution, AssembledSubstring);
	EndDo;
	Return QueryText;
EndFunction

Procedure FillInCCDNumbersAccordingToCredentialsInternal(ProductsToFillIn_, GTDCNumbersToFillIn,
	AdditionalData)
	
	ActionsWithString = AdditionalData.ActionsWithString;
	FillInCCDNumberType = AdditionalData.FillInCCDNumberType;
	FillNumberOfPackages = AdditionalData.FillNumberOfPackages;
	FillInCountryOfOrigin_ = AdditionalData.FillInCountryOfOrigin_;
	SearchFields = AdditionalData.SearchFields;
	ExcludeWarehouseSeriesFromSearch = AdditionalData.ExcludeWarehouseSeriesFromSearch;
	
	TheStructureOfTheSearch = New Structure(SearchFields);
	SearchStructureWithoutSeries_ = New Structure(SearchFields);
	SearchStructureWithoutSeries_.Delete("Series");
	
	For Each LineOfGTDCNumberToFillIn In GTDCNumbersToFillIn Do
		
		If LineOfGTDCNumberToFillIn.Count <= 0
			Or LineOfGTDCNumberToFillIn.CCDNumber = Catalogs.CCDNumbers.EmptyRef() Then
			Continue;
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, LineOfGTDCNumberToFillIn);
		TheStructureOfTheSearch.CCDNumber = Catalogs.CCDNumbers.EmptyRef();
		
		If ExcludeWarehouseSeriesFromSearch
			And LineOfGTDCNumberToFillIn.BatchesIndicationStatusOfGoodsTransferred = 0 Then
			
			FillPropertyValues(SearchStructureWithoutSeries_, TheStructureOfTheSearch);
			ProductLines_2 = ProductsToFillIn_.FindRows(SearchStructureWithoutSeries_);
			
		Else
			ProductLines_2 = ProductsToFillIn_.FindRows(TheStructureOfTheSearch);
		EndIf;
		
		For Each RowOfGoods In ProductLines_2 Do
			
			If LineOfGTDCNumberToFillIn.Count >= RowOfGoods.Count Then
				LineOfGTDCNumberToFillIn.Count = LineOfGTDCNumberToFillIn.Count - RowOfGoods.Count;
			Else
				
				NewRowProducts = ProductsToFillIn_.Add();
				FillPropertyValues(NewRowProducts, RowOfGoods);
				
				NewCount = RowOfGoods.Count - LineOfGTDCNumberToFillIn.Count;
				
				NewRowProducts.Count = NewCount;
				
				If FillNumberOfPackages Then
					NewNumberOfPackages = Round(RowOfGoods.NumberOfPackages * NewCount / RowOfGoods.Count,
					3,
					RoundMode.Round15as20);
					
					NewRowProducts.NumberOfPackages = NewNumberOfPackages;
					
					RowOfGoods.NumberOfPackages = RowOfGoods.NumberOfPackages - NewNumberOfPackages;
				EndIf;
				
				RowOfGoods.Count = LineOfGTDCNumberToFillIn.Count;
				
				If ActionsWithString <> Undefined Then
					BatchProcessingOfTablePartServer.ProcessTSString(NewRowProducts, ActionsWithString, Undefined);
				EndIf;
				
				LineOfGTDCNumberToFillIn.Count = 0;
				
			EndIf;
			
			RowOfGoods.CCDNumber = LineOfGTDCNumberToFillIn.CCDNumber;
			
			If FillInCCDNumberType Then
				RowOfGoods.CCDNumberType = LineOfGTDCNumberToFillIn.CCDNumberType;
			EndIf;
			
			If FillInCountryOfOrigin_ Then
				RowOfGoods.OriginCountry = LineOfGTDCNumberToFillIn.OriginCountry;
			EndIf;
			
			If ActionsWithString <> Undefined Then
				BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, ActionsWithString, Undefined);
			EndIf;
			
			If Not LineOfGTDCNumberToFillIn.Count Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;

EndProcedure

Procedure UpdatingProductBatchIDItemList(CCDNumber, Products, ItemName = "")
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("Catalog.CCDNumbers"); 
		LockItem.SetValue("Ref", CCDNumber);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		ObjectOfCCD = CCDNumber.GetObject(); // CatalogObject.CCDNumbers -
		ObjectOfCCD.Products = Products;
		ObjectOfCCD.ProductName = ?(IsBlankString(ItemName),
										Common.ObjectAttributeValue(Products, "DescriptionFull"),
										ItemName);
		
		ObjectOfCCD.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		// Failure to fill in the item in the CCD header is not a blocking problem.
		// We do not raise the flag.
		ErrorText = NStr("vi = 'Không thể ghi lại mặt hàng liên quan vào số TKHQ (số đăng ký lô hàng).';
						|ru = 'Не удалось записать связанную номенклатуру в номер ГТД (РНПТ).';
						|en = 'Cannot write the related item to the CCD number (RNPT).'; fa = 'Cannot write the related item to the CCD number (RNPT).';
						|it = 'Не удалось записать связанную номенклатуру в номер ГТД (РНПТ).';
						|pl = 'Cannot write the related item to the CCD number (RNPT).';
						|tr = 'GKB (RNPT) numarasına ilgili öğe kaydedilemedi.'")
			+ Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(
			NStr("vi = 'Phân tích số tổng hợp TKHQ (số đăng ký lô hàng)';
				|ru = 'Разборка составного номера ГТД (РНПТ)';
				|en = 'Decode the composite CCD number (RNPT)'; fa = 'Decode the composite CCD number (RNPT)';
				|it = 'Разборка составного номера ГТД (РНПТ)';
				|pl = 'Decode the composite CCD number (RNPT)';
				|tr = 'GKB (RNPT) numarasının tasnifi'",
			Common.DefaultLanguageCode()),
			EventLogLevel.Warning,
			,
			,
			ErrorText);
		
	EndTry;
	
EndProcedure

#EndRegion

// Returns the period of the customs declaration number that was adjusted when entering.
//
// Returns:
//	Structure - collection containing information about the correct period of the customs declaration number:
//		* BeginningOfCorrectPeriod - Date - the start date of the correct period.
//		* EndOfCorrectPeriod - Date - the end date of the correct period.
//
Function CorrectPeriodForEnteringDocumentsCustomsDeclarationNumbers() Export
	
	// We control the error by one digit. For example, 0017 instead of 2017; 2071 instead of 2017.
	// We consider it acceptable to enter documents for 9 years in the future. For example, in 2020, we allow
	// you to enter dates in the interval from January 2000 to December 2029.
	
	EndOfCorrectPeriod = AddMonth(EndOfYear(CurrentSessionDate()), 9 * 12);
	
	CorrectPeriod = New Structure;
	CorrectPeriod.Insert("BeginningOfCorrectPeriod", Date(2000, 01, 01));
	CorrectPeriod.Insert("EndOfCorrectPeriod",  EndOfCorrectPeriod);
	
	Return CorrectPeriod;
	
EndFunction

#Region BatchProcessingOfTablePart

// Adds a request to the request package to receive:
//    - Default vendor agreements.
//    - The number of supplier agreements.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextAndFillInParametersOfSupplierSAgreements(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters, ParametersForFillingOutAgreement, QuantityFillingParameters;
	
	FillInDefaultSupplierAgreement = BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInDefaultSupplierAgreement",
		StructureOfActions,
		CachedValues,
		ParametersForFillingOutAgreement);
		
	FillInNumberOfSupplierAgreements = BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInNumberOfSupplierAgreements",
		StructureOfActions,
		CachedValues,
		QuantityFillingParameters);
		
	If Not FillInDefaultSupplierAgreement
		And Not FillInNumberOfSupplierAgreements Then
		// None of the actions are performed.
		Return;
	ElsIf FillInDefaultSupplierAgreement
		And FillInNumberOfSupplierAgreements
		And Not Common.IdenticalCollections(ParametersForFillingOutAgreement, QuantityFillingParameters) Then
		
		// Both actions are performed, but with different parameters.
		NameOfActionFillInDefaultSupplierAgreement = "FillInDefaultSupplierAgreement";
		NameOfActionFillInNumberOfSupplierAgreements = "FillInNumberOfSupplierAgreements";
		ErrorTextTemplate = NStr("ru = 'Недопустимый вызов одновременной обработки действий таблицы ""%1"" и ""%2"" с различными параметрами';
								|vi = 'Invalid call for simultaneous processing of the ""%1"" and ""%2"" table actions with different parameters';
								|en = 'Invalid call for simultaneous processing of the ""%1"" and ""%2"" table actions with different parameters'; fa = 'Invalid call for simultaneous processing of the ""%1"" and ""%2"" table actions with different parameters';
								|it = 'Invalid call for simultaneous processing of the ""%1"" and ""%2"" table actions with different parameters';
								|pl = 'Invalid call for simultaneous processing of the ""%1"" and ""%2"" table actions with different parameters';
								|tr = '""%1"" ve ""%2"" tablo eylemlerinin farklı parametrelerle eşzamanlı işlenmesine yönelik geçersiz çağrı'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTextTemplate,
			NameOfActionFillInDefaultSupplierAgreement,
			NameOfActionFillInNumberOfSupplierAgreements);
		
		Raise ErrorText;
		
	// Using parameters from the action being performed
	ElsIf FillInNumberOfSupplierAgreements Then
		Parameters = QuantityFillingParameters;
		QueryDetails.PrivilegedMode = True; // Backward compatibility to fill the visibility of agreements.
	Else
		Parameters = ParametersForFillingOutAgreement;
	EndIf;
	
	QueryOptions = QueryDetails.QueryOptions;
	
	QueryText = 
	"SELECT ALLOWED
	|	DataSource.IdOfTTRow AS IdOfTTRow,
	|	ISNULL( // 1. Selecting the current specified agreement:
	|		MAX(CASE WHEN DataSource.Terms = TermsOfPurchaseFromVendors.Ref
	|					AND &SelectionExclusionOfBusinessOfOperations THEN 
	|					TermsOfPurchaseFromVendors.Ref
	|				ELSE 
	|					NULL
	|				END),
	|		// 2. Checking that the only suitable agreement fits:
	|		CASE WHEN COUNT(DISTINCT 
	|				CASE WHEN &SelectionExclusionOfBusinessOfOperations THEN
	|					TermsOfPurchaseFromVendors.Ref
	|				ELSE
	|					NULL
	|				END) = 1 THEN 
	|			// 2. The choice of this agreement:
	|			MAX(
	|				CASE WHEN &SelectionExclusionOfBusinessOfOperations THEN
	|					TermsOfPurchaseFromVendors.Ref
	|				ELSE
	|					NULL
	|				END)
	|
	|		ELSE // 3. There is no way to automatically select a value: 
	|			VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|		END) AS Terms,
	|		COUNT(DISTINCT TermsOfPurchaseFromVendors.Ref) AS NumberOfAgreements
	|FROM
	|	TTDataSource AS DataSource
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|		ON DataSource.Partner = TermsOfPurchaseFromVendors.Partner
	|		AND &UseTermsOfPurchases
	|		AND NOT TermsOfPurchaseFromVendors.DeletionMark
	|		AND &FilterStatus
	|		AND &FilterBusinessTransactions
	|		AND &FilterPriceIncludesVAT
	|		AND &FilterContractsAreUsed
	|
	|GROUP BY
	|	DataSource.IdOfTTRow";
	
	If Not FillInDefaultSupplierAgreement Then
		// When filling in only the quantity, the "Agreement" column is not used and may not exist.
		QueryText = StrReplace(QueryText,
			"DataSource.Terms",
			"VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)");
	EndIf;
	
	QueryOptions.Insert("UseTermsOfPurchases",
		GetFunctionalOption("UseTermsOfPurchases"));
	
	TextToReplace = "&FilterStatus";
	If Parameters.OnlyValid Then
		QueryText = StrReplace(QueryText,
			TextToReplace,
			"TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)");
	Else	
		QueryText = StrReplace(TextToReplace,
			TextToReplace,
			"TRUE");
	EndIf;
	
	TextToReplace = "&FilterBusinessTransactions";
	ReplacementExceptionText = "&SelectionExclusionOfBusinessOfOperations"; // For backward compatibility, households are excluded. of operations from the selection of the default value.
	If Parameters.BusinessOperation = Undefined Then
		
		BusinessTransactions = New Array;
		BusinessTransactions.Add(Enums.BusinessTransactions.AgentServicesDelivery);
		BusinessTransactions.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
		
		QueryText = StrReplace(
			QueryText,
			TextToReplace, 
			"TRUE");
		
		QueryText = StrReplace(
			QueryText,
			ReplacementExceptionText, 
			"TermsOfPurchaseFromVendors.BusinessOperation NOT IN (&BusinessTransactions)");
	
	Else
	
		QueryText = StrReplace(
			QueryText,
			TextToReplace, 
			"TermsOfPurchaseFromVendors.BusinessOperation IN (&BusinessTransactions)");
		
		QueryText = StrReplace(
			QueryText,
			ReplacementExceptionText, 
			"TRUE");
		
		BusinessTransactions = Parameters.BusinessOperation;
		
	EndIf;
	QueryOptions.Insert("BusinessTransactions", BusinessTransactions);
	
	TextToReplace = "&FilterPriceIncludesVAT";
	If Parameters.PriceIncludesVAT = Undefined Then
		QueryText = StrReplace(QueryText,
			TextToReplace,
			"TRUE");
	Else
		QueryText = StrReplace(QueryText,
			TextToReplace,
			"TermsOfPurchaseFromVendors.PriceIncludesVAT = &PriceIncludesVAT");
			QueryOptions.Insert("PriceIncludesVAT", Parameters.PriceIncludesVAT);
	EndIf;
	
	TextToReplace = "&FilterContractsAreUsed";
	If Parameters.ContractsAreUsed = Undefined Then
		QueryText = StrReplace(QueryText,
			TextToReplace,
			"TRUE");
	Else
		QueryText = StrReplace(QueryText,
			TextToReplace,
			"TermsOfPurchaseFromVendors.ContractsAreUsed = &ContractsAreUsed");
		QueryOptions.Insert("ContractsAreUsed", Parameters.ContractsAreUsed);
	EndIf;
	
	QueryDetails.QueriesTexts.Add(QueryText, "ParametersOfSupplierAgreements");
	
EndProcedure

// Adds a request to the request package to get the service Attributes of the agreement when processing table rows.
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextAndFillInAttributesAccordingToSupplierSAgreement(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters;
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInAttributesAccordingToSupplierSAgreement",
		StructureOfActions,
		CachedValues,
		Parameters) Then
		
		Return;
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	DataSource.IdOfTTRow AS IdOfTTRow,
	|	ISNULL(TermsOfPurchaseFromVendors.ContractsAreUsed, TRUE) AS ContractsAreUsed
	|FROM
	|	TTDataSource AS DataSource
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|		ON DataSource.Terms = TermsOfPurchaseFromVendors.Ref";
		
	QueryDetails.QueriesTexts.Add(QueryText, "FillInAttributesAccordingToSupplierSAgreement");
	
EndProcedure

// Adds a request to the request package for obtaining a Contract by default 
// for processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextAndFillInDefaultContract(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters;
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInDefaultContract",
		StructureOfActions,
		CachedValues,
		Parameters) Then
		
		Return;
		
	EndIf;
	
	QueryOptions = QueryDetails.QueryOptions;
	QueryOptions.Insert("Organization", Parameters.Organization);
	
	ThereIsSelectionOfOperations = ValueIsFilled(Parameters.BusinessOperation);
	QueryOptions.Insert("ThereIsSelectionOfOperations", ThereIsSelectionOfOperations);
	
	AdditionalBusinessOperationsOnMain = AdditionalBusinessOperationsOnMain();
	If ThereIsSelectionOfOperations Then
		
		If TypeOf(Parameters.BusinessOperation) = Type("Array") Then
			BusinessTransactions = Parameters.BusinessOperation;
		Else
			BusinessTransactions = CommonClientServer.ValueInArray(Parameters.BusinessOperation);
		EndIf;
		
		// Let's add additional business operations of operations with a match:
		// Empty link --> Array from selection.
		// This will allow you to "multiply" the number of entries of input parameters to all possible combinations
		For Each AdditionalOperation In BusinessTransactions Do
			NewDescriptionOfAdditionalBusinessOfOperation(AdditionalBusinessOperationsOnMain,
				Enums.BusinessTransactions.EmptyRef(),
				AdditionalOperation)
		EndDo;
			
	EndIf;
	
	QueryText = 
	"SELECT
	|	AdditionalBusinessOperationsOnMain.BasicOperation,
	|	AdditionalBusinessOperationsOnMain.AdditionalOperation
	|INTO AdditionalBusinessOperationsOnMain
	|FROM
	|	&AdditionalBusinessOperationsOnMain AS AdditionalBusinessOperationsOnMain";
	QueryDetails.QueriesTexts.Add(QueryText, "AdditionalBusinessOperationsOnMain");
	QueryOptions.Insert("AdditionalBusinessOperationsOnMain", AdditionalBusinessOperationsOnMain);
		
	QueryText = 
	"SELECT ALLOWED
	|	InputParameters.IdOfTTRow             AS IdOfTTRow,
	|	InputParameters.Organization                       AS Organization,
	|	InputParameters.Partner                           AS Partner,
	|	InputParameters.Counterparty                        AS Counterparty,
	|	InputParameters.DestinationLineOfBusiness AS DestinationLineOfBusiness,
	|	InputParameters.Contract                           AS Contract,
	|	InputParameters.SelectContract                  AS SelectContract,
	|	InputParameters.ThereIsSelectionOfOperations AS ThereIsSelectionOfOperations,
	|	ISNULL(AdditionalBusinessOperationsOnMain.AdditionalOperation,
	|		InputParameters.BusinessOperation)         AS BusinessOperation
	|INTO DefaultContractSearchParameters
	|FROM
	|	(SELECT
	|		DataSource.IdOfTTRow AS IdOfTTRow,
	|		&Organization                         AS Organization,
	|		ISNULL(PartnerHierarchy.Parent, 
	|		DataSource.Partner)              AS Partner,
	|		DataSource.Counterparty            AS Counterparty,
	|		&DestinationLineOfBusiness   AS DestinationLineOfBusiness,
	|		DataSource.Contract               AS Contract,
	|		&SelectContract                    AS SelectContract,
	|		&ThereIsSelectionOfOperations   AS ThereIsSelectionOfOperations,
	|		&BusinessOperation               AS BusinessOperation
	|	FROM
	|		TTDataSource AS DataSource
	|			LEFT JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|			ON DataSource.Partner = PartnerHierarchy.Parent) AS InputParameters
	|	LEFT JOIN AdditionalBusinessOperationsOnMain AS AdditionalBusinessOperationsOnMain
	|		ON InputParameters.BusinessOperation = AdditionalBusinessOperationsOnMain.BasicOperation";
	
	If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Terms", CachedValues) Then 
		
		// You cannot select a Contract if the agreement states that Contracts are not used.
		QueryText = StrReplace(QueryText,
			"&SelectContract",
			"ISNULL(
			|	CAST(DataSource.Terms AS Catalog.TermsOfPurchaseFromVendors).ContractsAreUsed,
			|	TRUE)"); 
		
		// In priority, we use the business of operation from the agreement for data consistency.
		QueryText = StrReplace(QueryText,
			"&BusinessOperation",
			"ISNULL(
			|	CAST(DataSource.Terms AS Catalog.TermsOfPurchaseFromVendors).BusinessOperation,
			|	&BusinessOperation)");
		
		// If an agreement is specified, then selection of operation must necessarily be established.
		QueryText = StrReplace(QueryText,
			"&ThereIsSelectionOfOperations",
			"CAST(DataSource.Terms AS Catalog.TermsOfPurchaseFromVendors).BusinessOperation IS NOT NULL
			|	OR &ThereIsSelectionOfOperations");
			
	Else
		
		QueryOptions.Insert("SelectContract", True);
	
	EndIf; 
	
	QueryText = StrReplace(QueryText, 
		"&BusinessOperation",
		"VALUE(Enum.BusinessTransactions.EmptyRef)");
	
	If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Purpose", CachedValues)
		And Not ValueIsFilled(Parameters.LineOfBusiness) Then
		// We use the line of business from the destination to select Contracts with the procedure for calculating "Sub-agreements of contractors":
		QueryText = StrReplace(QueryText, 
			"&DestinationLineOfBusiness",
			"ISNULL(
			|	CAST(DataSource.Purpose AS Catalog.Assignments).LineOfBusiness,
			|	&DestinationLineOfBusiness)");
	EndIf;
	
	QueryText = StrReplace(QueryText, 
		"&DestinationLineOfBusiness",
		"UNDEFINED");
		
	QueryDetails.QueriesTexts.Add(QueryText, "DefaultContractSearchParameters");
	
	QueryText = 
	"SELECT ALLOWED
	|	SearchParameters.IdOfTTRow AS IdOfTTRow,
	|	ISNULL( // 1. Selection of the current specified Contract:
	|		MAX(CASE WHEN SearchParameters.Contract = CounterpartyContracts.Ref THEN 
	|					CounterpartyContracts.Ref
	|				ELSE 
	|					NULL
	|				END),
	|			
	|		CASE WHEN COUNT(DISTINCT CounterpartyContracts.Ref) = 1 THEN 
	|			// 2. The only suitable Contract:
	|			MAX(CounterpartyContracts.Ref)
	|		ELSE // 3. There is no way to automatically select a value: 
	|			VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		END) AS Contract
	|FROM
	|	DefaultContractSearchParameters AS SearchParameters
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON SearchParameters.SelectContract
	|			AND SearchParameters.Organization = CounterpartyContracts.Organization
	|			AND SearchParameters.Partner    = CounterpartyContracts.Partner
	|			AND SearchParameters.Counterparty = CounterpartyContracts.Counterparty
	|			AND NOT CounterpartyContracts.DeletionMark
	|			AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|			AND (NOT SearchParameters.ThereIsSelectionOfOperations
	|				OR SearchParameters.BusinessOperation = CounterpartyContracts.BusinessOperation
	|				OR &ConsignmentSales25 <> UNDEFINED
	|					AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|					AND CounterpartyContracts.ConsignmentSales25 = &ConsignmentSales25)
	|			AND (SearchParameters.DestinationLineOfBusiness = UNDEFINED // There is no selection
	|				OR CounterpartyContracts.LineOfBusiness IN (SearchParameters.DestinationLineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|				OR CounterpartyContracts.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)) // Selection is only for ""Sub-agreements of contractors""
	|			AND &FilterARAPCurrency
	|			AND &FilterARAPObjectSettings
	|			AND &FilterLineOfBusiness
	|			AND &FilterContractType
	|			AND CounterpartyContracts.CompanyActsAsAVATTaxAgent = &CompanyActsAsAVATTaxAgent
	|			AND CounterpartyContracts.ContractWithSelfEmployedPerson = &ContractWithSelfEmployedPerson
	|
	|GROUP BY
	|	SearchParameters.IdOfTTRow";
	
	NamesOfConditionalSelectionFields = New Array;
	NamesOfConditionalSelectionFields.Add("ARAPCurrency");
	NamesOfConditionalSelectionFields.Add("ARAPObjectSettings");
	NamesOfConditionalSelectionFields.Add("LineOfBusiness");
	NamesOfConditionalSelectionFields.Add("RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage");
	NamesOfConditionalSelectionFields.Add("ContractType");
	
	For Each FieldName In NamesOfConditionalSelectionFields Do
		
		FilterValue = Parameters[FieldName];
		
		If FieldName = "LineOfBusiness" Then
			
			FilterUsed = FilterValue <> Undefined
				And GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
			
		ElsIf FieldName = "RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage" Then
			
			FilterUsed = FilterValue <> Undefined;
			
		Else
			
			FilterUsed = ValueIsFilled(FilterValue);
			
		EndIf;
			
		ReplacementString = "TRUE";
		If FilterUsed Then
				
			ReplacementString = StrTemplate("CounterpartyContracts.%1 IN (&%1)", FieldName);
				
		EndIf;
				
		SearchSubstring = StrTemplate("&Filter%1", FieldName);
		QueryText = StrReplace(QueryText, SearchSubstring, ReplacementString);
		QueryOptions.Insert(FieldName, FilterValue);
		
	EndDo;
	
	QueryOptions.Insert("CompanyActsAsAVATTaxAgent",     Parameters.Taxation = Enums.VATTaxationTypes.VATTaxAgent);
	QueryOptions.Insert("ConsignmentSales25", Parameters.ConsignmentSales25);
	QueryOptions.Insert("ContractWithSelfEmployedPerson",   Parameters.ContractWithSelfEmployedPerson);
	
	QueryDetails.QueriesTexts.Add(QueryText, "FillInDefaultContract");
	
EndProcedure

// Adds a request to the request package to get the Contract Attributes when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextAndCompleteOperationOfOperationAccordingToAgreementContract(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters;
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"CompleteOfOperationAccordingToAgreementContract",
		StructureOfActions,
		CachedValues,
		Parameters) Then
		
		Return;
		
	EndIf;
	
	QueryText =
	"SELECT
	|	Source.IdOfTTRow AS IdOfTTRow,
	|	CASE WHEN Terms1.Ref IS NOT NULL THEN
	|		Terms1.BusinessOperation
	|	WHEN Contracts.Ref IS NOT NULL THEN
	|		Contracts.BusinessOperation
	|	ELSE
	|		&DefaultValueOfOperation
	|	END AS BusinessOperation
	|FROM
	|	TTDataSource AS Source
	|		LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON Source.Contract = Contracts.Ref
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON Source.Terms = Terms1.Ref";
	
	QueryOptions = QueryDetails.QueryOptions;
	QueryOptions.Insert("DefaultValueOfOperation", Parameters.DefaultValue);
	QueryDetails.QueriesTexts.Add(QueryText, "CompleteOfOperationAccordingToAgreementContract");
	
EndProcedure

// Adds a request to the request package for receiving Presentations of links involved in the formation of the Presentation of the purchase conditions
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextAndFillInPresentationOfTermsOfPurchase(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters;
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInPresentationOfTermsOfPurchase",
		StructureOfActions,
		CachedValues,
		Parameters) Then
		
		Return;
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	DataSource.IdOfTTRow AS IdOfTTRow,
	|	PRESENTATION(DataSource.Partner) AS Partner
	|FROM
	|	TTDataSource AS DataSource";
		
	QueryDetails.QueriesTexts.Add(QueryText, "FillInPresentationOfTermsOfPurchase");
	
EndProcedure

#EndRegion

#Region BusinessTransactions

Function AdditionalBusinessOperationsOnMain()
	
	DescriptionOfTypeOfOperations = New TypeDescription("EnumRef.BusinessTransactions");
	
	ReturnValue = New ValueTable();
	ReturnValue.Columns.Add("BasicOperation", DescriptionOfTypeOfOperations);
	ReturnValue.Columns.Add("AdditionalOperation", DescriptionOfTypeOfOperations);

	UseGoodsInTransitFromVendors  = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	UseImportOfGoodsFromCustomsUnion = GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
	
	PurchaseFromSupplier = Enums.BusinessTransactions.PurchaseFromSupplier;
	NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
		PurchaseFromSupplier,
		PurchaseFromSupplier);
	
	ImportFromEAEU = Enums.BusinessTransactions.ImportFromEAEU;
	NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
		ImportFromEAEU,
		ImportFromEAEU);
	
	PurchaseByImport = Enums.BusinessTransactions.PurchaseByImport;	
	NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
		PurchaseByImport,
		PurchaseByImport);
	
	ProductionByToller2_5 = Enums.BusinessTransactions.ProductionByToller2_5;
	NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
		ProductionByToller2_5,
		ProductionByToller2_5);

	If UseGoodsInTransitFromVendors Then
			
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			PurchaseFromSupplier,
			Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
			
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			PurchaseFromSupplier,
			Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
			
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			ImportFromEAEU,
			Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
				
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			ImportFromEAEU,
			Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
				
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			PurchaseByImport,
			Enums.BusinessTransactions.ImportGoodsInTransit);
				
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			PurchaseByImport,
			Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
			
	EndIf;
	
	If UseUninvoicedDeliveries Then
			
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			PurchaseFromSupplier,
			Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
			
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			PurchaseFromSupplier,
			Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
				
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			ImportFromEAEU,
			Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
			
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			ImportFromEAEU,
			Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
	
	EndIf;

	If UseImportOfGoodsFromCustomsUnion Then
		
		NewDescriptionOfAdditionalBusinessOfOperation(ReturnValue,
			ProductionByToller2_5,
			Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5);
	
	EndIf;
	
	Return ReturnValue;

EndFunction

Function NewDescriptionOfAdditionalBusinessOfOperation(Links, BasicOperation, AdditionalOperation)
	
	LinkDetails = Links.Add();
	
	LinkDetails.BasicOperation = BasicOperation;
	LinkDetails.AdditionalOperation = AdditionalOperation;
	
	Return LinkDetails;
	
EndFunction

#EndRegion

#EndRegion
