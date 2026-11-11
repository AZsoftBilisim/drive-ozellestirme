#Region Public

// The constructor function of the mutual settlement procedure for completing the payment encryption.Fill in the decryption of the client's paymentpositioning.
//
// Returns:
//	Structure - parameter structure:
//		* Partner          - CatalogRef.Partners - Partner of the initiator document.
//		* Contract          - CatalogRef.CounterpartyContracts - The contract of object calculations.
//		* SalesOrder     - DocumentRef.SalesOrder - The object of calculations.
//		* DocumentCurrency  - CatalogRef.Currencies - Currency of the cash receipt document.
//		* PaymentPurpose - DocumentRef - The Foundation document.
//
Function ParametersForFillingInOrderPaymentDecryption() Export
	
	Parameters = New Structure;
	Parameters.Insert("Partner");
	Parameters.Insert("Contract");
	Parameters.Insert("SalesOrder");
	Parameters.Insert("DocumentCurrency");
	Parameters.Insert("PaymentPurpose");
	Parameters.Insert("CashFlowItem");
	
	Return Parameters;
EndFunction

// Procedure for filling in the table part "payment Decryption" on the client's order.
//
// Parameters:
//	FillParameters - See ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption.
//	ARAPDetails - TabularSection, ValueTable - Tabular part of the document, unloading columns of the tabular part of the document.
//	AmountToPay - Number - The amount to be paid, if known.
//	Organization - CatalogRef.Companies - The organization that carries out the sale.
//	BusinessOperation - EnumRef.BusinessTransactions - type of payment document operation.
//
Procedure FillInTranscriptOfPaymentOnClientSOrder(FillParameters, ARAPDetails, AmountToPay = 0, Organization = Undefined, BusinessOperation = Undefined) Export
	
	SalesOrder     = FillParameters.SalesOrder;
	Contract          = FillParameters.Contract;
	DocumentCurrency  = FillParameters.DocumentCurrency;
	Partner          = FillParameters.Partner;
	PaymentPurpose = FillParameters.PaymentPurpose;
	CashFlowItem = FillParameters.CashFlowItem;

	SetPrivilegedMode(True);
	If ValueIsFilled(DocumentCurrency) Then
		
		IsItOrderOrRequest = TypeOf(SalesOrder) = Type("DocumentRef.SalesOrder")
			Or TypeOf(SalesOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
			Or (TypeOf(SalesOrder) = Type("Array") 
				And (TypeOf(SalesOrder[0]) = Type("DocumentRef.SalesOrder")
				Or TypeOf(SalesOrder[0]) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")));
		
		ThisIsOrder = TypeOf(SalesOrder) = Type("DocumentRef.SalesOrder")
			Or TypeOf(SalesOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
			Or TypeOf(SalesOrder) = Type("DocumentRef.MaterialProviderOrder2_5")
			Or TypeOf(SalesOrder) = Type("Array");
			
		AttributesNames = "ARAPObjectSettings";
		AttributesNames = AttributesNames + ?(IsItOrderOrRequest, ",ThisIsOrderAsInvoice","");
		
		If TypeOf(SalesOrder) = Type("Array") Then
			AttributesStructure1 = Common.ObjectAttributesValues(SalesOrder[0], AttributesNames);
		Else
			AttributesStructure1 = Common.ObjectAttributesValues(SalesOrder, AttributesNames);
		EndIf;
		
		UseAdvancedFeaturesOfSalesOrder = ?(IsItOrderOrRequest,
			Not AttributesStructure1.ThisIsOrderAsInvoice,
			GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
		ARAPObjectSettings = AttributesStructure1.ARAPObjectSettings;
		
		ColumnsOfPaymentDecryptionTable = Undefined;
		
		If TypeOf(ARAPDetails) = Type("ValueTable") Then
			ColumnsOfPaymentDecryptionTable = ARAPDetails.Columns;
		Else
			ColumnsOfPaymentDecryptionTable = Metadata.FindByType(TypeOf(ARAPDetails)).Attributes;
		EndIf;
		
		If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
			Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice 
				And (ThisIsOrder Or TypeOf(SalesOrder) = Type("CatalogRef.CounterpartyContracts")) Then
			
			If Not Constants.NewOnlineARAPAccounting.Get() Then
			QueryText = 
			"SELECT
			|	CustomersARAPAccounting.PaymentDate AS Period,
			|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
			|	CustomersARAPAccounting.Currency AS Currency,
			|	CustomersARAPAccounting.AmountDue AS AmountDue,
			|	CounterpartyContracts.CashFlowItem AS CashFlowItem,
			|	ARAPObjects.Object AS Object,
			|	ARAPObjects.Organization AS Organization
			|INTO TTSettlementsWithCustomers
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
			|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
			|			LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
			|			ON ARAPObjects.Object = CounterpartyContracts.Ref
			|		ON CustomersARAPAccounting.ARAPObject = ARAPObjects.Ref
			|			AND NOT ARAPObjects.DeletionMark
			|WHERE
			|	CustomersARAPAccounting.Active
			|	AND CustomersARAPAccounting.Recorder IN(&SalesOrder)
			|	AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
			|	AND CustomersARAPAccounting.AmountDue > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CustomersARAPAccounting.Period AS Period,
			|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
			|	CustomersARAPAccounting.CashFlowItem AS CashFlowItem,
			|	Dimension.Partner AS Partner,
			|	CustomersARAPAccounting.Currency AS Currency,
			|	CustomersARAPAccounting.Object AS Object,
			|	CustomersARAPAccounting.Organization AS Organization,
			|	SUM(CustomersARAPAccounting.AmountDue) AS AmountAccordingToSchedule
			|INTO TableForPayment
			|FROM
			|	TTSettlementsWithCustomers AS CustomersARAPAccounting
			|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
			|		ON CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
			|			AND (&Organization = Dimension.Organization
			|				OR &Organization = UNDEFINED)
			|
			|GROUP BY
			|	CustomersARAPAccounting.Period,
			|	CustomersARAPAccounting.ARAPObject,
			|	CustomersARAPAccounting.AccountingDimensionByPartners,
			|	CustomersARAPAccounting.Currency,
			|	Dimension.Partner,
			|	CustomersARAPAccounting.CashFlowItem,
			|	CustomersARAPAccounting.Object,
			|	CustomersARAPAccounting.Organization
			|
			|UNION ALL
			|
			|SELECT
			|	&CurrentDate,
			|	Dimension.DimensionKey,
			|	ARAPObjects.Ref,
			|	ContractData.CashFlowItem,
			|	ContractData.Partner,
			|	ContractData.ARAPCurrency,
			|	ARAPObjects.Object,
			|	ARAPObjects.Organization,
			|	0
			|FROM
			|	Catalog.CounterpartyContracts AS ContractData
			|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
			|		ON ContractData.Partner = Dimension.Partner
			|			AND ContractData.Counterparty = Dimension.Counterparty
			|			AND ContractData.Organization = Dimension.Organization
			|			AND ContractData.Ref = Dimension.Contract
			|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
			|			ON ContractData.Ref = ARAPObjects.Object
			|				AND NOT ARAPObjects.DeletionMark
			|WHERE
			|	ContractData.Ref IN(&SalesOrder)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableForPayment.Partner AS Partner,
			|	TableForPayment.Organization AS Organization,
			|	TableForPayment.ARAPObject AS ARAPObject,
			|	TableForPayment.Currency AS ARAPCurrency,
			|	TableForPayment.CashFlowItem AS CashFlowItem,
			|	TableForPayment.Object AS PaymentPurpose
			|FROM
			|	TableForPayment AS TableForPayment
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MIN(TableForPayment.Period) AS Period,
			|	TableForPayment.Object AS PaymentPurpose,
			|	TableForPayment.ARAPObject AS ARAPObject,
			|	TableForPayment.Organization AS Organization,
			|	TableForPayment.CashFlowItem AS CashFlowItem,
			|	TableForPayment.Partner AS Partner,
			|	TableForPayment.Currency AS ARAPCurrency,
			|	CASE
			|		WHEN SUM(TableForPayment.AmountAccordingToSchedule) > 0
			|				AND SUM(TableForPayment.AmountAccordingToSchedule) <= MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
			|			THEN SUM(TableForPayment.AmountAccordingToSchedule)
			|		ELSE MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
			|	END AS AmountAccordingToSchedule,
			|	SUM(0) AS PayAmount
			|FROM
			|	TableForPayment AS TableForPayment
			|		INNER JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
			|				,
			|				(AccountingDimensionByPartners, ARAPObject, Currency) IN
			|					(SELECT
			|						TableForPayment.AccountingDimensionByPartners,
			|						TableForPayment.ARAPObject,
			|						TableForPayment.Currency
			|					FROM
			|						TableForPayment)) AS CustomersARAPAccountingBalance
			|		ON TableForPayment.AccountingDimensionByPartners = CustomersARAPAccountingBalance.AccountingDimensionByPartners
			|			AND TableForPayment.ARAPObject = CustomersARAPAccountingBalance.ARAPObject
			|			AND TableForPayment.Currency = CustomersARAPAccountingBalance.Currency
			|
			|GROUP BY
			|	TableForPayment.ARAPObject,
			|	TableForPayment.CashFlowItem,
			|	TableForPayment.Partner,
			|	TableForPayment.Currency,
			|	TableForPayment.Object,
			|	TableForPayment.Organization
			|TOTALS BY
			|	PaymentPurpose";
			Else
				QueryText = 
				"SELECT
				|	ShipmentReferences.Recorder AS Object
				|INTO ttObjects
				|FROM
				|	AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
				|WHERE
				|	ShipmentReferences.ReferenceOrder IN(&SalesOrder)
				|	AND ShipmentReferences.Active
				|	AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
				|
				|UNION ALL
				|
				|SELECT
				|	&Contract
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ARAPObjects.Ref AS ARAPObject,
				|	ARAPObjects.PaymentMethod AS PaymentMethod,
				|	ARAPObjects.Contract AS Contract,
				|	ARAPObjects.Terms AS Terms,
				|	ARAPObjects.Object AS Object,
				|	CASE
				|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
				|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfSale).CashFlowItem
				|		ELSE ARAPObjects.Contract.CashFlowItem
				|	END AS CashFlowItem,
				|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
				|	ARAPObjects.Partner AS Partner,
				|	ARAPObjects.Organization AS Organization
				|INTO TTCalculationObjects_
				|FROM
				|	Catalog.ARAPObjects AS ARAPObjects
				|WHERE
				|	ARAPObjects.Object IN
				|			(SELECT
				|				T.Object
				|			FROM
				|				ttObjects AS T)
				|	AND NOT ARAPObjects.DeletionMark
				|
				|UNION ALL
				|
				|SELECT
				|	ARAPObjects.Ref AS ARAPObject,
				|	ARAPObjects.PaymentMethod AS PaymentMethod,
				|	ARAPObjects.Contract AS Contract,
				|	ARAPObjects.Terms AS Terms,
				|	ARAPObjects.Object AS Object,
				|	CASE
				|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
				|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfSale).CashFlowItem
				|		ELSE ARAPObjects.Contract.CashFlowItem
				|	END AS CashFlowItem,
				|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
				|	ARAPObjects.Partner AS Partner,
				|	ARAPObjects.Organization AS Organization
				|FROM
				|	Catalog.ARAPObjects AS ARAPObjects
				|WHERE
				|	ARAPObjects.Object IN (&SalesOrder)
				|	AND NOT ARAPObjects.DeletionMark
				|
				|INDEX BY
				|	ARAPObject
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ContractSchedule.Ref AS DocumentPlan
				|INTO ttPlanDocs
				|FROM
				|	Document.ContractSchedule AS ContractSchedule
				|WHERE
				|	ContractSchedule.Contract = &Contract
				|
				|UNION ALL
				|
				|SELECT
				|	DocumentsRegistry.Ref
				|FROM
				|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
				|WHERE
				|	DocumentsRegistry.Ref IN(&SalesOrder)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TTCalculationObjects_.ARAPObject AS ARAPObject,
				|	TTCalculationObjects_.Object AS PaymentPurpose,
				|	TTCalculationObjects_.CashFlowItem AS CashFlowItem,
				|	TTCalculationObjects_.ARAPCurrency AS ARAPCurrency,
				|	TTCalculationObjects_.Partner AS Partner,
				|	TTCalculationObjects_.Organization AS Organization
				|FROM
				|	TTCalculationObjects_ AS TTCalculationObjects_
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ARAPObjects.Object AS PaymentPurpose,
				|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
				|	Dimension.Organization AS Organization,
				|	Dimension.Partner AS Partner,
				|	ARAPObjects.CashFlowItem AS CashFlowItem,
				|	CustomersARAPAccounting.PlannedRepaymentDate AS Period,
				|	CustomersARAPAccounting.Currency AS ARAPCurrency,
				|	ARAPObjects.PaymentMethod AS PaymentMethod,
				|	CustomersARAPAccounting.AmountDueBalance AS AmountAccordingToSchedule,
				|	ISNULL(SettlementsWithCustomersTurnover.BeingPaidTurnover, 0) AS PayAmount
				|FROM
				|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(
				|			,
				|			ARAPObject IN
				|					(SELECT
				|						TTCalculationObjects_.ARAPObject
				|					FROM
				|						TTCalculationObjects_)
				|				AND (VALUETYPE(&SalesOrder) = TYPE(Catalog.CounterpartyContracts)
				|					OR DocumentPlan IN
				|						(SELECT
				|							T.DocumentPlan
				|						FROM
				|							ttPlanDocs AS T))) AS CustomersARAPAccounting
				|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
				|		ON CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
				|			AND (&Organization = Dimension.Organization
				|				OR &Organization = UNDEFINED)
				|		INNER JOIN TTCalculationObjects_ AS ARAPObjects
				|		ON CustomersARAPAccounting.ARAPObject = ARAPObjects.ARAPObject
				|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Turnovers(, , Period, ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS SettlementsWithCustomersTurnover
				|			ON (SettlementsWithCustomersTurnover.ARAPObject = CustomersARAPAccounting.ARAPObject)
				|				AND (SettlementsWithCustomersTurnover.Currency = CustomersARAPAccounting.Currency)
				|				AND (SettlementsWithCustomersTurnover.AccountingDimensionByPartners = CustomersARAPAccounting.AccountingDimensionByPartners)
				|
				|UNION ALL
				|
				|SELECT
				|	ARAPObjects.Object,
				|	CustomersARAPAccounting.ARAPObject,
				|	Dimension.Organization,
				|	Dimension.Partner,
				|	ARAPObjects.CashFlowItem,
				|	CustomersARAPAccounting.PlannedRepaymentDate,
				|	CustomersARAPAccounting.Currency,
				|	ARAPObjects.PaymentMethod,
				|	CustomersARAPAccounting.DebtBalance,
				|	ISNULL(SettlementsWithCustomersTurnover.BeingPaidTurnover, 0) AS PayAmount
				|FROM
				|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
				|			,
				|			ARAPObject IN
				|				(SELECT
				|					TTCalculationObjects_.ARAPObject
				|				FROM
				|					TTCalculationObjects_)) AS CustomersARAPAccounting
				|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
				|		ON CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
				|			AND (&Organization = Dimension.Organization
				|				OR &Organization = UNDEFINED)
				|		INNER JOIN TTCalculationObjects_ AS ARAPObjects
				|		ON CustomersARAPAccounting.ARAPObject = ARAPObjects.ARAPObject
				|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Turnovers(, , Period, ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS SettlementsWithCustomersTurnover
				|			ON (SettlementsWithCustomersTurnover.ARAPObject = CustomersARAPAccounting.ARAPObject)
				|				AND (SettlementsWithCustomersTurnover.Currency = CustomersARAPAccounting.Currency)
				|				AND (SettlementsWithCustomersTurnover.AccountingDimensionByPartners = CustomersARAPAccounting.AccountingDimensionByPartners)
				|
				|ORDER BY
				|	CustomersARAPAccounting.PlannedRepaymentDate
				|TOTALS BY
				|	ARAPObject"
			EndIf;
			
		ElsIf Not UseAdvancedFeaturesOfSalesOrder
			And ThisIsOrder
			And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments Then
			
			QueryText = "
			|SELECT
			|	ARAPObjects.Ref AS ARAPObject,
			|	ARAPObjects.Organization AS Organization,
			|	ARAPObjects.Partner AS Partner,
			|	ARAPObjects.Object AS Object,
			|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
			|	CASE
			|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
			|			THEN ARAPObjects.Terms.CashFlowItem
			|		ELSE ARAPObjects.Contract.CashFlowItem
			|	END AS CashFlowItem
			|INTO TTCalculationObjects_
			|FROM 
			|	Catalog.ARAPObjects AS ARAPObjects
			|WHERE
			|	ARAPObjects.Object IN (&SalesOrder)
			|	AND NOT ARAPObjects.DeletionMark
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TTCalculationObjects_.ARAPObject AS ARAPObject,
			|	TTCalculationObjects_.ARAPCurrency AS ARAPCurrency,
			|	TTCalculationObjects_.CashFlowItem AS CashFlowItem,
			|	TTCalculationObjects_.Partner AS Partner,
			|	TTCalculationObjects_.Organization AS Organization,
			|	TTCalculationObjects_.Object AS PaymentPurpose
			|FROM
			|	TTCalculationObjects_ AS TTCalculationObjects_
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	OrderDocument.Ref AS PaymentPurpose,
			|	ARAPObjects.ARAPObject AS ARAPObject,
			|	ARAPObjects.Organization AS Organization,
			|	ARAPObjects.Partner AS Partner,
			|	OrderDocument.Terms AS Terms,
			|	CASE
			|		WHEN ISNULL(OrderDocument.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
			|			THEN CAST(OrderDocument.Terms AS Catalog.TermsOfSale).CashFlowItem
			|		ELSE OrderDocument.Contract.CashFlowItem
			|	END AS CashFlowItem,
			|	StagesOfOrderPayment.PaymentDate AS Period,
			|	OrderDocument.Currency AS ARAPCurrency,
			|	OrderDocument.PaymentMethod AS PaymentMethod,
			|	StagesOfOrderPayment.LineNumber AS LineNumber,
			|	StagesOfOrderPayment.PaymentAmount + StagesOfOrderPayment.PackageDepositValue AS AmountAccordingToSchedule,
			|	ISNULL(SettlementsWithCustomersTurnover.SumExpense, 0) AS PayAmount
			|FROM
			|	Document.SalesOrder AS OrderDocument
			|		INNER JOIN Document.SalesOrder.PaymentScheduleSteps AS StagesOfOrderPayment
			|		ON OrderDocument.Ref = StagesOfOrderPayment.Ref
			|		LEFT JOIN TTCalculationObjects_ AS ARAPObjects
			|		ON ARAPObjects.Object = OrderDocument.Ref
			|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Turnovers(, , , ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS SettlementsWithCustomersTurnover
			|		ON ARAPObjects.ARAPObject = SettlementsWithCustomersTurnover.ARAPObject
			|WHERE
			|	OrderDocument.Ref IN(&SalesOrder)
			|	AND OrderDocument.ThisIsOrderAsInvoice
			|
			|UNION ALL
			|
			|SELECT
			|	RequestForReturnOfGoodsFromCustomer.Ref,
			|	ARAPObjects.ARAPObject AS ARAPObject,
			|	ARAPObjects.Organization AS Organization,
			|	Dimension.Partner,
			|	RequestForReturnOfGoodsFromCustomer.Terms,
			|	CASE
			|		WHEN ISNULL(RequestForReturnOfGoodsFromCustomer.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
			|			THEN CAST(RequestForReturnOfGoodsFromCustomer.Terms AS Catalog.TermsOfSale).CashFlowItem
			|		ELSE RequestForReturnOfGoodsFromCustomer.Contract.CashFlowItem
			|	END,
			|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate,
			|	RequestForReturnOfGoodsFromCustomer.Currency,
			|	RequestForReturnOfGoodsFromCustomer.PaymentMethod,
			|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.LineNumber AS LineNumber,
			|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentAmount + RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PackageDepositValue,
			|	ISNULL(SettlementsWithCustomersTurnover.SumExpense, 0)
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
			|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps
			|		ON RequestForReturnOfGoodsFromCustomer.Ref = RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref
			|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
			|		ON RequestForReturnOfGoodsFromCustomer.Partner = Dimension.Partner
			|			AND RequestForReturnOfGoodsFromCustomer.Counterparty = Dimension.Counterparty
			|			AND RequestForReturnOfGoodsFromCustomer.Organization = Dimension.Organization
			|			AND RequestForReturnOfGoodsFromCustomer.Contract = Dimension.Contract
			|		LEFT JOIN TTCalculationObjects_ AS ARAPObjects
			|		ON ARAPObjects.Object = RequestForReturnOfGoodsFromCustomer.Ref
			|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Turnovers(, , , ARAPObject IN (SELECT Object FROM TTCalculationObjects_)) AS SettlementsWithCustomersTurnover
			|		ON ARAPObjects.ARAPObject = SettlementsWithCustomersTurnover.ARAPObject
			|WHERE
			|	RequestForReturnOfGoodsFromCustomer.Ref IN(&SalesOrder)
			|	AND RequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice
			|ORDER BY
			|	LineNumber
			|TOTALS BY
			|	PaymentPurpose";
		Else
				
			If Not Constants.NewOnlineARAPAccounting.Get() Then
			QueryText = "
			|SELECT
			|	ARAPObjects.Ref AS ARAPObject,
			|	ARAPObjects.Organization AS Organization,
			|	ARAPObjects.Partner AS Partner,
			|	ARAPObjects.Contract AS Contract,
			|	CASE
			|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
			|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfSale).CashFlowItem
			|		ELSE ARAPObjects.Contract.CashFlowItem
			|	END AS CashFlowItem,
			|	ARAPObjects.Object AS Object,
			|	ARAPObjects.ARAPCurrency AS ARAPCurrency
			|INTO TTCalculationObjects_
			|FROM 
			|	Catalog.ARAPObjects AS ARAPObjects
			|WHERE
			|	ARAPObjects.Object IN (&SalesOrder)
			|	AND NOT ARAPObjects.DeletionMark
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TTCalculationObjects_.ARAPObject AS ARAPObject,
			|	TTCalculationObjects_.Organization AS Organization,
			|	TTCalculationObjects_.Partner AS Partner,
			|	TTCalculationObjects_.Contract AS Contract,
			|	TTCalculationObjects_.CashFlowItem AS CashFlowItem,
			|	TTCalculationObjects_.Object AS PaymentPurpose,
			|	TTCalculationObjects_.ARAPCurrency AS ARAPCurrency
			|FROM
			|	TTCalculationObjects_ AS TTCalculationObjects_
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ARAPObjects.Object AS PaymentPurpose,
			|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
			|	ARAPObjects.Organization AS Organization,
			|	Dimension.Partner AS Partner,
			|	ARAPObjects.CashFlowItem AS CashFlowItem,
			|	CustomersARAPAccounting.PaymentDate AS Period,
			|	CustomersARAPAccounting.Currency AS ARAPCurrency,
			|	CustomersARAPAccounting.PaymentMethod AS PaymentMethod,
			|	CustomersARAPAccounting.AmountDue AS AmountAccordingToSchedule,
			|	ISNULL(SettlementsWithCustomersTurnover.AmountDueExpense, 0) + ISNULL(SettlementsWithCustomersTurnover.BeingPaidTurnover, 0) AS PayAmount
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
			|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Turnovers(, , Period, ) AS SettlementsWithCustomersTurnover
			|		ON CustomersARAPAccounting.ARAPObject = SettlementsWithCustomersTurnover.ARAPObject
			|			AND CustomersARAPAccounting.Currency = SettlementsWithCustomersTurnover.Currency
			|			AND CustomersARAPAccounting.AccountingDimensionByPartners = SettlementsWithCustomersTurnover.AccountingDimensionByPartners
			|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
			|		ON CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
			|			AND (&Organization = Dimension.Organization
			|				OR &Organization = UNDEFINED)
			|		INNER JOIN TTCalculationObjects_ AS ARAPObjects
			|		ON CustomersARAPAccounting.ARAPObject = ARAPObjects.ARAPObject
			|WHERE
			|	CustomersARAPAccounting.Active
			|	AND CustomersARAPAccounting.ARAPObject IN(SELECT ARAPObject FROM TTCalculationObjects_)
			|	AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
			|	AND CustomersARAPAccounting.AmountDue > 0
			|
			|ORDER BY
			|	CustomersARAPAccounting.PaymentDate,
			|	CustomersARAPAccounting.LineNumber
			|TOTALS BY
			|	PaymentPurpose";
			Else
			QueryText = "
				|SELECT
				|	ARAPObjects.Ref AS ARAPObject,
				|	ARAPObjects.PaymentMethod AS PaymentMethod,
				|	ARAPObjects.Contract AS Contract,
				|	ARAPObjects.Terms AS Terms,
				|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
				|	ARAPObjects.Object AS Object,
				|	CASE
				|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
				|			THEN ARAPObjects.Terms.CashFlowItem
				|		ELSE ARAPObjects.Contract.CashFlowItem
				|	END AS CashFlowItem,
				|	ARAPObjects.Partner AS Partner,
				|	ARAPObjects.Organization AS Organization
				|INTO TTCalculationObjects_
				|FROM 
				|	Catalog.ARAPObjects AS ARAPObjects
				|WHERE
				|	ARAPObjects.Object IN (&SalesOrder)
				|	AND NOT ARAPObjects.DeletionMark
				|INDEX BY 
				|	ARAPObject
				|;
				|SELECT
				|	NestedQuery.ARAPObject            AS ARAPObject,
				|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	NestedQuery.Period                    AS Period,
				|	NestedQuery.ARAPCurrency      AS ARAPCurrency,
				|	SUM(NestedQuery.AmountAccordingToSchedule)     AS AmountAccordingToSchedule
				|INTO BalanceAmountsDue
				|FROM (SELECT
				|		CustomersARAPAccounting.ARAPObject            AS ARAPObject,
				|		CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|		CustomersARAPAccounting.PlannedRepaymentDate    AS Period,
				|		CustomersARAPAccounting.Currency                    AS ARAPCurrency,
				|		CustomersARAPAccounting.AmountDueBalance            AS AmountAccordingToSchedule
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(,ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS CustomersARAPAccounting
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		CustomersARAPAccounting.ARAPObject            AS ARAPObject,
				|		CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|		CustomersARAPAccounting.PlannedRepaymentDate    AS Period,
				|		CustomersARAPAccounting.Currency                    AS ARAPCurrency,
				|		CustomersARAPAccounting.DebtBalance               AS AmountAccordingToSchedule
				|	FROM
				|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(,ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS CustomersARAPAccounting
				|	) AS NestedQuery
				|GROUP BY
				|	NestedQuery.ARAPObject,
				|	NestedQuery.AccountingDimensionByPartners,
				|	NestedQuery.Period,
				|	NestedQuery.ARAPCurrency 
				|HAVING 
				|	SUM(NestedQuery.AmountAccordingToSchedule) > 0 
				|;
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TTCalculationObjects_.ARAPObject AS ARAPObject,
				|	TTCalculationObjects_.ARAPCurrency AS ARAPCurrency,
				|	TTCalculationObjects_.CashFlowItem AS CashFlowItem,
				|	TTCalculationObjects_.Partner AS Partner,
				|	TTCalculationObjects_.Organization AS Organization,
				|	TTCalculationObjects_.Object AS PaymentPurpose
				|FROM
				|	TTCalculationObjects_ AS TTCalculationObjects_
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	CustomersARAPAccounting.ARAPObject            AS ARAPObject,
				|	CustomersARAPAccounting.Period                    AS Period,
				|	CustomersARAPAccounting.ARAPCurrency      AS ARAPCurrency,
				|	CustomersARAPAccounting.AmountAccordingToSchedule            AS AmountAccordingToSchedule,
				|
				|	ARAPObjects.Object                      AS PaymentPurpose,
				|	ARAPObjects.PaymentMethod                 AS PaymentMethod,
				|	ARAPObjects.CashFlowItem AS CashFlowItem,
				|
				|	Dimension.Organization                       AS Organization,
				|	Dimension.Partner                           AS Partner,
				|	ISNULL(SettlementsWithCustomersTurnover.BeingPaidTurnover, 0) AS PayAmount
				|FROM
				|	BalanceAmountsDue AS CustomersARAPAccounting
				|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
				|			ON CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
				|				AND (&Organization = Dimension.Organization
				|					OR &Organization = UNDEFINED)
				|		INNER JOIN TTCalculationObjects_ AS ARAPObjects
				|			ON CustomersARAPAccounting.ARAPObject = ARAPObjects.ARAPObject
				|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Turnovers(, , Period, ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS SettlementsWithCustomersTurnover
				|			ON (SettlementsWithCustomersTurnover.ARAPObject = CustomersARAPAccounting.ARAPObject)
				|				AND (SettlementsWithCustomersTurnover.Currency = CustomersARAPAccounting.ARAPCurrency)
				|				AND (SettlementsWithCustomersTurnover.AccountingDimensionByPartners = CustomersARAPAccounting.AccountingDimensionByPartners)
				|ORDER BY
				|	Period
				|TOTALS BY
				|	ARAPObject";
			EndIf;
			
		EndIf;
		
		Query = New Query(QueryText);
		
		Query.SetParameter("SalesOrder", SalesOrder);
		Query.SetParameter("ByContracts", ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
												Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		Query.SetParameter("Contract", Contract);
		Query.SetParameter("CurrentDate", CurrentSessionDate());
		Query.SetParameter("Organization", Organization);
		
		If BusinessOperation = Undefined Then 
			CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Enums.BusinessTransactions.CashReceiptFromCustomer);
		Else
			CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(BusinessOperation);
		EndIf;
		
		Queries = Query.ExecuteBatch();
		SelectionByOrders = Queries[Queries.UBound()].Select(QueryResultIteration.ByGroups);
		While SelectionByOrders.Next() Do
			
			TotalAmountOnSchedule = 0;
			PaymentAmountTakenIntoAccount = 0;
		
			Selection = SelectionByOrders.Select();
			While Selection.Next() Do
				
				PayAmount = ?(Selection.PayAmount < 0, 0, Selection.PayAmount);
				// We will find the first unpaid stage.
				If (Selection.AmountAccordingToSchedule + TotalAmountOnSchedule) > PayAmount Then
					
					NewRow = ARAPDetails.Add();
					FillPropertyValues(NewRow, Selection);
					
					If ColumnsOfPaymentDecryptionTable.Find("PaymentPurpose") <> Undefined Then
						
						NewRow.PaymentPurpose = PaymentPurpose;
						
						If Not ValueIsFilled(NewRow.PaymentPurpose) Then
							NewRow.PaymentPurpose = Selection.PaymentPurpose;
						EndIf;
					
					EndIf;
					
					If ColumnsOfPaymentDecryptionTable.Find("Organization") <> Undefined Then
						NewRow.Organization = Common.ObjectAttributeValue(NewRow.ARAPObject, "Organization");
					EndIf;
					
					If Not ValueIsFilled(NewRow.CashFlowItem) Then
						NewRow.CashFlowItem = CFItemByBT;
					Else
						
						If BusinessOperation <> Undefined Then
							NewRow.CashFlowItem = CFItemByBT;
						EndIf;
						
					EndIf;
					
					NewRow.AmountARAP = Selection.AmountAccordingToSchedule + TotalAmountOnSchedule - (PayAmount + PaymentAmountTakenIntoAccount);
					
					If AmountToPay <> 0 Then
						NewRow.AmountARAP = Min(NewRow.AmountARAP, AmountToPay);
						AmountToPay = AmountToPay - NewRow.AmountARAP;
						PaymentAmountTakenIntoAccount = PaymentAmountTakenIntoAccount + NewRow.AmountARAP;
						TotalAmountOnSchedule = TotalAmountOnSchedule + Selection.AmountAccordingToSchedule;
					EndIf;
					
					If ValueIsFilled(Contract) Then
						ContractAttributes = Common.ObjectAttributesValues(Contract, "ConductARAPAccountingThroughEndCustomers, Partner");
					EndIf;
					
					If TypeOf(PaymentPurpose) = Type("DocumentRef.CustomerInvoice")
						And Common.ObjectAttributeValue(PaymentPurpose, "BusinessOperation") = Enums.BusinessTransactions.SalesViaCommissionAgent
						And ValueIsFilled(Contract) And ContractAttributes.ConductARAPAccountingThroughEndCustomers Then
						NewRow.ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(Contract,
							Organization,
							Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
						NewRow.Partner = ContractAttributes.Partner;
					EndIf;
					
					NewRow.Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
					                    	NewRow.AmountARAP,
					                    	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
					                    	Selection.ARAPCurrency,
					                    	DocumentCurrency,
					                    	CurrentSessionDate(),
					                    	NewRow.ARAPObject);
					
					If AmountToPay = 0 Then
						Break;
					EndIf;
					
				Else
					
					If BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then 
						
						NewRow = ARAPDetails.Add();
						FillPropertyValues(NewRow, Selection);
						
						If Not ValueIsFilled(NewRow.CashFlowItem) Then
							NewRow.CashFlowItem = CFItemByBT;
						EndIf;
						
						If ColumnsOfPaymentDecryptionTable.Find("Organization") <> Undefined Then
							NewRow.Organization = Common.ObjectAttributeValue(NewRow.ARAPObject, "Organization");
						EndIf;
						
						NewRow.AmountARAP = Selection.AmountAccordingToSchedule;
						NewRow.Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
						                    	NewRow.AmountARAP,
						                    	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(
						                    		?(ColumnsOfPaymentDecryptionTable.Find("Organization") <> Undefined, NewRow.Organization, Selection.Organization)),
						                    	Selection.ARAPCurrency,
						                    	DocumentCurrency,
						                    	CurrentSessionDate(),
						                    	Selection.ARAPObject);
					Else
						TotalAmountOnSchedule = TotalAmountOnSchedule + Selection.AmountAccordingToSchedule;
					EndIf;

				EndIf;
			EndDo;
		EndDo;
		
		If ARAPDetails.Count() = 0 Then
			NewRow = ARAPDetails.Add();
			
			NewRow.Partner = Partner;
			NewRow.ARAPCurrency = DocumentCurrency;
			NewRow.CashFlowItem = CashFlowItem;
			
			ARAPObjects = Queries[Queries.UBound() - 1].Unload();
			
			If ValueIsFilled(Contract)
				And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
				Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) Then
				
				If ColumnsOfPaymentDecryptionTable.Find("PaymentPurpose") <> Undefined Then
					NewRow.PaymentPurpose = Contract;
				EndIf;
				
				CalculationObjectData = ARAPObjects.Find(Contract, "PaymentPurpose");
				
				If CalculationObjectData <> Undefined Then
					
					NewRow.ARAPObject = CalculationObjectData.ARAPObject;
					NewRow.ARAPCurrency = CalculationObjectData.ARAPCurrency;
					
					If Not ValueIsFilled(NewRow.CashFlowItem) Then
						NewRow.CashFlowItem = CalculationObjectData.CashFlowItem;
					EndIf;
					
					If Not ValueIsFilled(NewRow.Partner) Then
						NewRow.Partner = CalculationObjectData.Partner;
					EndIf;
					
					If ColumnsOfPaymentDecryptionTable.Find("Organization") <> Undefined Then
						NewRow.Organization = CalculationObjectData.Organization;
					EndIf;
					
				EndIf;
				
			Else
				
				If ColumnsOfPaymentDecryptionTable.Find("PaymentPurpose") <> Undefined Then
					NewRow.PaymentPurpose = PaymentPurpose;
				EndIf;
				
				If ARAPObjects.Count() > 0 Then
					
					NewRow.ARAPObject = ARAPObjects[0].ARAPObject;
					NewRow.ARAPCurrency = ARAPObjects[0].ARAPCurrency;
					
					If ColumnsOfPaymentDecryptionTable.Find("PaymentPurpose") <> Undefined
						And Not ValueIsFilled(NewRow.PaymentPurpose) Then
						NewRow.PaymentPurpose = ARAPObjects[0].PaymentPurpose;
					EndIf;
					
					If Not ValueIsFilled(NewRow.CashFlowItem) Then
						NewRow.CashFlowItem = ARAPObjects[0].CashFlowItem;
					EndIf;
					
					If Not ValueIsFilled(NewRow.Partner) Then
						NewRow.Partner = ARAPObjects[0].Partner;
					EndIf;
					
					If ColumnsOfPaymentDecryptionTable.Find("Organization") <> Undefined Then
						NewRow.Organization = ARAPObjects[0].Organization;
					EndIf;
					
				EndIf; 
				
			EndIf;
			
			If Not ValueIsFilled(NewRow.CashFlowItem) Then
				NewRow.CashFlowItem = CFItemByBT;
			EndIf;
			
			If ColumnsOfPaymentDecryptionTable.Find("Organization") <> Undefined 
				And Not ValueIsFilled(NewRow.Organization) Then
				NewRow.Organization = Organization;
			EndIf;
			
		Else
			
			GroupColumns = "ARAPObject, CashFlowItem, Partner, ARAPCurrency, MaturityDate";
			
			If ColumnsOfPaymentDecryptionTable.Find("PaymentPurpose") <> Undefined Then
				GroupColumns = GroupColumns + ", PaymentPurpose";
			EndIf;
			
			If ColumnsOfPaymentDecryptionTable.Find("Organization") <> Undefined Then
				GroupColumns = GroupColumns + ", Organization";
			EndIf;
			
			ARAPDetails.GroupBy(GroupColumns, "Sum, AmountARAP");
			
		EndIf;
		
		CashServer.FillInNDSInDecryption(ARAPDetails,
			CashServer.TranscriptOfVATPayment(Organization, CurrentSessionDate(), DocumentCurrency, ARAPDetails.UnloadColumn("ARAPObject"), True));
	EndIf;
	
EndProcedure

// Procedure for filling in the table part "payment Decryption" for the payment invoice.
//
// Parameters:
//	ProformaInvoice - DocumentRef.CustomerCommercialInvoice - The Foundation document.
//	Organization - CatalogRef.Companies - The Foundation document.
//	SalesOrder - DocumentRef.SalesOrder - order.
//	DocumentCurrency - CatalogRef.Currencies - Currency of the cash receipt document.
//	ARAPDetails - TabularSection - the tabular part of the document.
//
Procedure FillInTranscriptOfPaymentOnInvoice(ProformaInvoice, Organization, SalesOrder, DocumentCurrency, ARAPDetails) Export
	
	SetPrivilegedMode(True);
	
	ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(SalesOrder);
	
	// Filling in the tabular part "Payment decryption"
	QueryText = "
	|SELECT
	|	CustomersARAPAccounting.ProformaInvoice,
	|	SUM(
	|		CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense) THEN
	|			CustomersARAPAccounting.Sum
	|		ELSE
	|			0
	|		END
	|		) AS PayAmount
	|INTO TTAccountCalculations
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|WHERE
	|	CustomersARAPAccounting.Active
	|	AND CustomersARAPAccounting.ProformaInvoice = &ProformaInvoice
	|GROUP BY
	|	CustomersARAPAccounting.ProformaInvoice
	|INDEX BY
	|	ProformaInvoice
	|;
	|
	|SELECT
	|	ISNULL(SUM(Calculations.AmountDueBalance - Calculations.BeingPaidBalance), 0) AS AmountARAP
	|INTO TTCalculations
	|FROM
	|	(SELECT
	|		CustomersARAPAccounting.AmountDueBalance      AS AmountDueBalance,
	|		0                                     AS BeingPaidBalance
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(,ARAPObject = &ARAPObject) AS CustomersARAPAccounting
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomersARAPAccounting.DebtBalance         AS AmountDueBalance,
	|		0                                     AS BeingPaidBalance
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(,ARAPObject = &ARAPObject) AS CustomersARAPAccounting
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		0                                     AS AmountDueBalance,
	|		CustomersARAPAccounting.BeingPaidBalance AS BeingPaidBalance
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting.Balance(,ARAPObject = &ARAPObject) AS CustomersARAPAccounting) AS Calculations
	|;
	|
	|SELECT
	|	CustomerCommercialInvoice.Ref AS PaymentPurpose,
	|	ARAPObjects.Ref AS ARAPObject,
	|	ARAPObjects.Organization AS Organization,
	|	CustomerCommercialInvoice.DocumentBasis.Partner AS Partner,
	|	CustomerCommercialInvoice.DocumentBasis.Terms AS Terms,
	|	
	|	CASE WHEN CustomerCommercialInvoice.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		CustomerCommercialInvoice.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(CustomerCommercialInvoice.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			CAST(CustomerCommercialInvoice.DocumentBasis.Terms AS Catalog.TermsOfSale).CashFlowItem
	|		ELSE
	|			CustomerCommercialInvoice.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	
	|	ISNULL(ARAPObjects.ARAPCurrency,
	|		ISNULL(
	|			CustomerCommercialInvoice.DocumentBasis.ARAPCurrency, 
	|			CustomerCommercialInvoice.DocumentBasis.Currency)
	|	) AS ARAPCurrency,
	|	CustomerCommercialInvoice.Currency AS AccountCurrency,
	|
	|	CustomerCommercialInvoice.DocumentAmount AS AmountOfInvoice,
	|	ISNULL(CustomersARAPAccountingBalance.AmountARAP, 0) AS AmountARAP,
	|	ISNULL(CustomersARAPAccounting.PayAmount, 0) AS AmountOfPaymentOnInvoice,
	|
	|	CustomerCommercialInvoice.DocumentBasis REFS Catalog.CounterpartyContracts
	|		OR ISNULL(CustomerCommercialInvoice.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts), FALSE) AS PaymentUnderContract
	|FROM
	|	Document.CustomerCommercialInvoice AS CustomerCommercialInvoice
	|	
	|	LEFT JOIN TTAccountCalculations AS CustomersARAPAccounting
	|	ON
	|		CustomerCommercialInvoice.Ref = CustomersARAPAccounting.ProformaInvoice
	|	
	|	LEFT JOIN
	|		TTCalculations AS CustomersARAPAccountingBalance
	|	ON
	|		TRUE
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON CASE WHEN CustomerCommercialInvoice.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) 
	|			THEN CustomerCommercialInvoice.Contract
	|			ELSE CustomerCommercialInvoice.DocumentBasis
	|		END = ARAPObjects.Object
	|		AND ARAPObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		AND NOT ARAPObjects.DeletionMark
	|		
	|WHERE
	|	CustomerCommercialInvoice.Ref = &ProformaInvoice
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ProformaInvoice", ProformaInvoice);
	Query.SetParameter("ARAPObject", ARAPObject);
	
	CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Enums.BusinessTransactions.CashReceiptFromCustomer);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, Selection);
		If Not ValueIsFilled(NewRow.CashFlowItem) Then
			NewRow.CashFlowItem = CFItemByBT;
		EndIf;
		
		// The invoice may not be issued in the settlement currency,
		// so you need to convert its amount to the settlement currency
		// in order to compare it with account payments and settlement Balances
		InvoiceAmountInSettlementCurrency = Selection.AmountOfInvoice;
		If Selection.AccountCurrency <> Selection.ARAPCurrency Then
			InvoiceAmountInSettlementCurrency = ProcessingOfExchangeRatesTM.ConvertToCurrency(
			                                  	Selection.AmountOfInvoice,
			                                  	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
			                                  	Selection.AccountCurrency,
			                                  	Selection.ARAPCurrency,
			                                  	CurrentSessionDate(),
			                                  	ARAPObject);
		EndIf;
		If Selection.PaymentUnderContract Then
			AmountARAP = InvoiceAmountInSettlementCurrency - Selection.AmountOfPaymentOnInvoice;
		ElsIf Selection.AmountARAP < InvoiceAmountInSettlementCurrency Then
			AmountARAP = Selection.AmountARAP;
		ElsIf InvoiceAmountInSettlementCurrency > Selection.AmountOfPaymentOnInvoice Then
			AmountARAP = InvoiceAmountInSettlementCurrency - Selection.AmountOfPaymentOnInvoice;
		Else
			AmountARAP = 0;
		EndIf;
		NewRow.AmountARAP = AmountARAP;
		
		If AmountARAP = InvoiceAmountInSettlementCurrency
			And DocumentCurrency = Selection.AccountCurrency Then
			NewRow.Sum = Selection.AmountOfInvoice;
		ElsIf DocumentCurrency = Selection.ARAPCurrency Then
			NewRow.Sum = AmountARAP;
		Else
			NewRow.Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
			                    	AmountARAP,
			                    	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
			                    	Selection.ARAPCurrency,
			                    	DocumentCurrency,
			                    	CurrentSessionDate(),
			                    	ARAPObject);
		EndIf;
	EndIf;
	
	If ARAPDetails.Count() = 0 Then
		NewRow = ARAPDetails.Add();
		NewRow.ProformaInvoice = ProformaInvoice;
	EndIf;
	
	CashServer.FillInNDSInDecryption(ARAPDetails,
		CashServer.TranscriptOfVATPayment(Organization, CurrentSessionDate(), DocumentCurrency, ARAPObject, True));
	
EndProcedure

// Procedure for filling in the table part "decoding Payment" for the return of goods from the client.
//
// Parameters:
//	Objects - DocumentRef, Array of DocumentRef - document Foundation.
//	Organization - CatalogRef.Companies - Organization of the document.
//	DocumentCurrency - CatalogRef.Currencies - Currency of the cash receipt document.
//	DocumentAmount - Number - The amount of the base document.
//	Partner - CatalogRef.Partners - Partner of the Foundation document.
//	ARAPDetails - TabularSection - the tabular part of the document.
//
Procedure FillInDecryptionOfPaymentForReturnOfGoodsFromClient(Objects, Organization, DocumentCurrency, DocumentAmount, Partner, ARAPDetails) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(DocumentCurrency) Then
		
		Query = New Query("
		|SELECT
		|	ARAPObjects.Object AS Object,
		|	ARAPObjects.Ref AS ARAPObject,
		|	ARAPObjects.Organization AS Organization
		|INTO TTCalculationObjects_
		|FROM Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object IN (&Objects)
		|	AND NOT ARAPObjects.DeletionMark
		|;
		|SELECT
		|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
		|	ARAPObjects.Organization AS Organization,
		|	CustomersARAPAccounting.Currency AS ARAPCurrency,
		|	(-CustomersARAPAccounting.AmountDueBalance) AS AmountARAP
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(,
		|		ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)
		|	) AS CustomersARAPAccounting
		|		INNER JOIN TTCalculationObjects_ AS ARAPObjects
		|		ON CustomersARAPAccounting.ARAPObject = ARAPObjects.ARAPObject
		|WHERE
		|	CustomersARAPAccounting.AmountDueBalance < 0
		|ORDER BY
		|	CASE WHEN ARAPObjects.Object REFS Document.ReturnOfGoodsFromCustomer THEN
		|		1
		|	ELSE
		|		2
		|	END
		|");
		
		Query.SetParameter("Objects", Objects);
		
		CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
			Enums.BusinessTransactions.RefundToCustomer);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Partner = Partner;
			NewRow.CashFlowItem = CFItemByBT;
			
			Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
			        	NewRow.AmountARAP,
			        	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
			        	Selection.ARAPCurrency,
			        	DocumentCurrency,
			        	CurrentSessionDate(),
			        	Selection.ARAPObject);
			
			If Sum <= DocumentAmount Then
				NewRow.Sum = Sum;
			Else
				NewRow.Sum = DocumentAmount;
				NewRow.AmountARAP = 0;
			EndIf;
		Else
			NewRow = ARAPDetails.Add();
			NewRow.Partner = Partner;
			NewRow.Sum = DocumentAmount;
		EndIf;
		
		CashServer.FillInNDSInDecryption(ARAPDetails,
			CashServer.TranscriptOfVATPayment(Organization, CurrentSessionDate(), DocumentCurrency, ARAPDetails.UnloadColumn("ARAPObject"), False));
	EndIf;
EndProcedure

// Procedure for filling in the table part "payment Decryption" by order to the supplier.
//
// Parameters:
//	PurchaseOrder - DocumentRef.PurchaseOrder - The Foundation document.
//	Contract - CatalogRef.CounterpartyContracts - Contract to fill out.
//	DocumentCurrency - CatalogRef.Currencies - Currency of the cash receipt document.
//	AmountToPay - Number - Amount to be paid to the supplier.
//	ARAPDetails - TabularSection - the tabular part of the document.
//	RequiredPaymentDate - Date - Payment date according to the schedule.
//  Organization - CatalogRef.Companies - The organization that makes the purchase.
//
Procedure FillInTranscriptOfOrderPaymentToSupplier(PurchaseOrder, Contract, DocumentCurrency, Val AmountToPay, ARAPDetails, RequiredPaymentDate = Undefined, Organization = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(DocumentCurrency) Then
		
		If TypeOf(PurchaseOrder) = Type("Array") Then
			ARAPObjectSettings = Common.ObjectAttributeValue(PurchaseOrder[0], "ARAPObjectSettings");
		Else
			ARAPObjectSettings = Common.ObjectAttributeValue(PurchaseOrder, "ARAPObjectSettings");
		EndIf;
		
		If (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
			Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			And TypeOf(PurchaseOrder) <> Type("CatalogRef.CounterpartyContracts") Then
			
			If Not Constants.NewOnlineARAPAccounting.Get() Then
			QueryText = "
			|SELECT
			|	CASE
			|		WHEN VendorsARAPAccounting.PaymentDate < &CurrentDate
			|			THEN &CurrentDate
			|		ELSE VendorsARAPAccounting.PaymentDate
			|	END                                          AS Period,
			|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	VendorsARAPAccounting.ARAPObject            AS ARAPObject,
			|	CASE
			|		WHEN ISNULL(VendorsARAPAccounting.ARAPObject.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
			|			THEN CAST(VendorsARAPAccounting.ARAPObject.Terms AS Catalog.TermsOfPurchaseFromVendors).CashFlowItem
			|		ELSE VendorsARAPAccounting.ARAPObject.Contract.CashFlowItem
			|	END AS CashFlowItem,
			|	Dimension.Partner							   AS Partner,
			|	VendorsARAPAccounting.Currency					   AS Currency,
			|	SUM(VendorsARAPAccounting.AmountDue)			   AS AmountAccordingToSchedule
			|INTO TableForPayment
			|FROM
			|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
			|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
			|		ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
			|		AND (&Organization = Dimension.Organization
			|			OR &Organization = UNDEFINED)
			|WHERE
			|	VendorsARAPAccounting.Active
			|	AND VendorsARAPAccounting.Recorder IN (&PurchaseOrder)
			|	AND (VendorsARAPAccounting.ARAPObject.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.Contract)
			|		OR &ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
			|	AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
			|	AND VendorsARAPAccounting.AmountDue > 0
			|
			|GROUP BY
			|	CASE
			|		WHEN VendorsARAPAccounting.PaymentDate < &CurrentDate
			|			THEN &CurrentDate
			|		ELSE VendorsARAPAccounting.PaymentDate
			|	END,
			|	VendorsARAPAccounting.ARAPObject,
			|	CASE
			|		WHEN ISNULL(VendorsARAPAccounting.ARAPObject.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
			|			THEN CAST(VendorsARAPAccounting.ARAPObject.Terms AS Catalog.TermsOfPurchaseFromVendors).CashFlowItem
			|		ELSE VendorsARAPAccounting.ARAPObject.Contract.CashFlowItem
			|	END,
			|	VendorsARAPAccounting.AccountingDimensionByPartners,
			|	VendorsARAPAccounting.Currency,
			|	Dimension.Partner
			|UNION ALL
			|
			|SELECT
			|	&CurrentDate AS Period,
			|	Dimension.DimensionKey AS AccountingDimensionByPartners,
			|	ARAPObjects.Ref AS ARAPObject,
			|	ContractData.CashFlowItem AS CashFlowItem,
			|	ContractData.Partner AS Partner,
			|	ContractData.ARAPCurrency AS Currency,
			|	0 AS AmountAccordingToSchedule
			|FROM
			|	Catalog.CounterpartyContracts AS ContractData
			|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
			|		ON ContractData.Partner = Dimension.Partner
			|			AND ContractData.Counterparty = Dimension.Counterparty
			|			AND ContractData.Organization = Dimension.Organization
			|			AND ContractData.Ref = Dimension.Contract
			|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
			|			ON ContractData.Ref = ARAPObjects.Object
			|				AND NOT ARAPObjects.DeletionMark
			|WHERE
			|	ContractData.Ref IN (&PurchaseOrder)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MIN(TableForPayment.Period) AS Period,
			|	TableForPayment.ARAPObject  AS ARAPObject,
			|	TableForPayment.ARAPObject.Organization  AS Organization,
			|	TableForPayment.CashFlowItem AS CashFlowItem,
			|	TableForPayment.Partner		   AS Partner,
			|	TableForPayment.Currency		   AS ARAPCurrency,
			|
			|	CASE
			|		WHEN SUM(TableForPayment.AmountAccordingToSchedule) > 0 AND SUM(TableForPayment.AmountAccordingToSchedule) <=
			|				MAX(VendorsARAPAccountingBalance.BeingPaidBalance-VendorsARAPAccountingBalance.AmountDueBalance)
			|			THEN SUM(TableForPayment.AmountAccordingToSchedule)
			|		ELSE MAX(VendorsARAPAccountingBalance.BeingPaidBalance-VendorsARAPAccountingBalance.AmountDueBalance)
			|	END AS AmountAccordingToSchedule,
			|	SUM(0) AS PayAmount
			|
			|FROM
			|	TableForPayment AS TableForPayment
			|		INNER JOIN AccumulationRegister.VendorsARAPAccounting.Balance(
			|				,
			|				(AccountingDimensionByPartners, ARAPObject, Currency) IN
			|					(SELECT
			|						TableForPayment.AccountingDimensionByPartners,
			|						TableForPayment.ARAPObject,
			|						TableForPayment.Currency
			|					FROM
			|						TableForPayment)) AS VendorsARAPAccountingBalance
			|		ON TableForPayment.AccountingDimensionByPartners = VendorsARAPAccountingBalance.AccountingDimensionByPartners
			|			AND TableForPayment.ARAPObject = VendorsARAPAccountingBalance.ARAPObject
			|			AND TableForPayment.Currency = VendorsARAPAccountingBalance.Currency
			|
			|GROUP BY
			|	TableForPayment.ARAPObject,
			|	TableForPayment.CashFlowItem,
			|	TableForPayment.Partner,
			|	TableForPayment.Currency
			|
			|TOTALS BY
			|	TableForPayment.ARAPObject
			|";
			Else
				QueryText = 
				"SELECT
				|	PurchaseOrders.Recorder AS Object
				|INTO ttObjects
				|FROM
				|	AccumulationRegister.PurchaseOrders AS PurchaseOrders
				|WHERE
				|	PurchaseOrders.PurchaseOrder IN(&PurchaseOrder)
				|	AND PurchaseOrders.Active
				|	AND PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Expense)
				|
				|UNION ALL
				|
				|SELECT
				|	&Contract
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ARAPObjects.Ref AS ARAPObject,
				|	ARAPObjects.PaymentMethod AS PaymentMethod,
				|	ARAPObjects.Contract AS Contract,
				|	ARAPObjects.Terms AS Terms
				|INTO TTCalculationObjects_
				|FROM
				|	Catalog.ARAPObjects AS ARAPObjects
				|WHERE
				|	ARAPObjects.Object IN
				|			(SELECT
				|				T.Object
				|			FROM
				|				ttObjects AS T)
				|	AND NOT ARAPObjects.DeletionMark
				|
				|UNION ALL
				|
				|SELECT
				|	ARAPObjects.Ref AS ARAPObject,
				|	ARAPObjects.PaymentMethod AS PaymentMethod,
				|	ARAPObjects.Contract AS Contract,
				|	ARAPObjects.Terms AS Terms
				|FROM
				|	Catalog.ARAPObjects AS ARAPObjects
				|WHERE
				|	ARAPObjects.Object IN (&PurchaseOrder)
				|	AND NOT ARAPObjects.DeletionMark
				|
				|INDEX BY
				|	ARAPObject
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ContractSchedule.Ref AS DocumentPlan
				|INTO ttPlanDocs
				|FROM
				|	Document.ContractSchedule AS ContractSchedule
				|WHERE
				|	ContractSchedule.Contract = &Contract
				|
				|UNION ALL
				|
				|SELECT
				|	DocumentsRegistry.Ref
				|FROM
				|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
				|WHERE
				|	DocumentsRegistry.Ref IN(&PurchaseOrder)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	SettlementsWithSuppliersTurnover.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	SettlementsWithSuppliersTurnover.ARAPObject AS ARAPObject,
				|	SettlementsWithSuppliersTurnover.Currency AS Currency,
				|	-SettlementsWithSuppliersTurnover.BeingPaidTurnover AS PayAmount
				|INTO PreparedAmountDue
				|FROM
				|	AccumulationRegister.VendorsARAPAccounting.Turnovers(
				|			,
				|			,
				|			Period,
				|			ARAPObject IN
				|				(SELECT
				|					TTCalculationObjects_.ARAPObject
				|				FROM
				|					TTCalculationObjects_)) AS SettlementsWithSuppliersTurnover
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	VendorsARAPAccounting.ARAPObject            AS ARAPObject,
				|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	Dimension.Partner                              AS Partner,
				|	Dimension.Organization                          AS Organization,
				|	CASE
				|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
				|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfPurchaseFromVendors).CashFlowItem
				|		ELSE ARAPObjects.Contract.CashFlowItem
				|	END                                          AS CashFlowItem,
				|	CASE
				|		WHEN VendorsARAPAccounting.PlannedRepaymentDate < &CurrentDate
				|			THEN &CurrentDate
				|		ELSE VendorsARAPAccounting.PlannedRepaymentDate
				|	END                                          AS Period,
				|	VendorsARAPAccounting.Currency                    AS ARAPCurrency,
				|	ARAPObjects.PaymentMethod                    AS PaymentMethod,
				|	VendorsARAPAccounting.AmountDueBalance            AS AmountAccordingToSchedule
				|INTO BalanceAmountsDue
				|FROM
				|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(
				|			,
				|			ARAPObject IN
				|					(SELECT
				|						ARAPObject 
				|					FROM 
				|						TTCalculationObjects_)
				|				AND DocumentPlan IN
				|						(SELECT
				|							T.DocumentPlan
				|						FROM
				|							ttPlanDocs AS T)) AS VendorsARAPAccounting
				|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
				|			ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
				|				AND (&Organization = Dimension.Organization
				|					OR &Organization = UNDEFINED)
				|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
				|			ON VendorsARAPAccounting.ARAPObject = ARAPObjects.Ref
				|
				|UNION ALL
				|
				|SELECT
				|	VendorsARAPAccounting.ARAPObject            AS ARAPObject,
				|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	Dimension.Partner                              AS Partner,
				|	Dimension.Organization                          AS Organization,
				|	CASE
				|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
				|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfPurchaseFromVendors).CashFlowItem
				|		ELSE ARAPObjects.Contract.CashFlowItem
				|	END                                          AS CashFlowItem,
				|	CASE
				|		WHEN VendorsARAPAccounting.PlannedRepaymentDate < &CurrentDate
				|			THEN &CurrentDate
				|		ELSE VendorsARAPAccounting.PlannedRepaymentDate
				|	END                                          AS Period,
				|	VendorsARAPAccounting.Currency                    AS ARAPCurrency,
				|	ARAPObjects.PaymentMethod                    AS PaymentMethod,
				|	VendorsARAPAccounting.DebtBalance               AS AmountAccordingToSchedule
				|FROM
				|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(,ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS VendorsARAPAccounting
				|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
				|			ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
				|				AND (&Organization = Dimension.Organization
				|					OR &Organization = UNDEFINED)
				|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
				|			ON VendorsARAPAccounting.ARAPObject = ARAPObjects.Ref
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	NestedQuery.ARAPObject AS ARAPObject,
				|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	NestedQuery.Partner AS Partner,
				|	NestedQuery.Organization AS Organization,
				|	NestedQuery.CashFlowItem AS CashFlowItem,
				|	NestedQuery.Period AS Period,
				|	NestedQuery.ARAPCurrency AS ARAPCurrency,
				|	NestedQuery.PaymentMethod AS PaymentMethod,
				|	NestedQuery.AmountAccordingToSchedule AS AmountAccordingToSchedule,
				|	ISNULL(PreparedAmountDue.PayAmount, 0) AS PayAmount
				|FROM
				|	(SELECT
				|		BalanceAmountsDue.ARAPObject AS ARAPObject,
				|		BalanceAmountsDue.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|		BalanceAmountsDue.Partner AS Partner,
				|		BalanceAmountsDue.Organization AS Organization,
				|		BalanceAmountsDue.CashFlowItem AS CashFlowItem,
				|		BalanceAmountsDue.Period AS Period,
				|		BalanceAmountsDue.ARAPCurrency AS ARAPCurrency,
				|		BalanceAmountsDue.PaymentMethod AS PaymentMethod,
				|		SUM(BalanceAmountsDue.AmountAccordingToSchedule) AS AmountAccordingToSchedule
				|	FROM
				|		BalanceAmountsDue AS BalanceAmountsDue
				|	
				|	GROUP BY
				|		BalanceAmountsDue.ARAPObject,
				|		BalanceAmountsDue.AccountingDimensionByPartners,
				|		BalanceAmountsDue.Partner,
				|		BalanceAmountsDue.Organization,
				|		BalanceAmountsDue.CashFlowItem,
				|		BalanceAmountsDue.Period,
				|		BalanceAmountsDue.ARAPCurrency,
				|		BalanceAmountsDue.PaymentMethod) AS NestedQuery
				|		LEFT JOIN PreparedAmountDue AS PreparedAmountDue
				|		ON (NestedQuery.ARAPObject = PreparedAmountDue.ARAPObject
				|				AND NestedQuery.AccountingDimensionByPartners = PreparedAmountDue.AccountingDimensionByPartners
				|				AND NestedQuery.ARAPCurrency = PreparedAmountDue.Currency)
				|
				|ORDER BY
				|	Period
				|TOTALS BY
				|	ARAPObject
				|";
			EndIf;
			
		Else
			
			If Not Constants.NewOnlineARAPAccounting.Get() Then
			QueryText = "
			|SELECT
			|	ARAPObjects.Ref AS ARAPObject,
			|	ARAPObjects.Object AS Object,
			|	CASE
			|		WHEN
			|			ISNULL(ARAPObjects.Contract.CashFlowItem,VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
			|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfPurchaseFromVendors).CashFlowItem
			|		ELSE ARAPObjects.Contract.CashFlowItem
			|	END AS CashFlowItem
			|INTO TTCalculationObjects_
			|FROM 
			|	Catalog.ARAPObjects AS ARAPObjects
			|WHERE
			|	ARAPObjects.Object IN (&PurchaseOrder)
			|	AND NOT ARAPObjects.DeletionMark
			|; 
			|SELECT
			|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
			|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	Dimension.Partner AS Partner,
			|	ARAPObjects.CashFlowItem AS CashFlowItem,
			|	CASE
			|		WHEN VendorsARAPAccounting.PaymentDate < &CurrentDate
			|			THEN &CurrentDate
			|		ELSE VendorsARAPAccounting.PaymentDate
			|	END AS Period,
			|	VendorsARAPAccounting.Currency AS ARAPCurrency,
			|	VendorsARAPAccounting.PaymentMethod AS PaymentMethod,
			|	SUM(VendorsARAPAccounting.AmountDue) AS AmountAccordingToSchedule
			|INTO PaymentSteps
			|FROM
			|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
			|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
			|		ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
			|			AND (&Organization = Dimension.Organization
			|				OR &Organization = UNDEFINED)
			|		INNER JOIN TTCalculationObjects_ AS ARAPObjects
			|			ON VendorsARAPAccounting.ARAPObject = ARAPObjects.ARAPObject
			|WHERE
			|	VendorsARAPAccounting.Active
			|	AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
			|	AND VendorsARAPAccounting.AmountDue > 0
			|GROUP BY
			|	VendorsARAPAccounting.ARAPObject,
			|	VendorsARAPAccounting.AccountingDimensionByPartners,
			|	Dimension.Partner,
			|	CASE
			|		WHEN VendorsARAPAccounting.PaymentDate < &CurrentDate
			|			THEN &CurrentDate
			|		ELSE VendorsARAPAccounting.PaymentDate
			|	END,
			|	VendorsARAPAccounting.Currency,
			|	VendorsARAPAccounting.PaymentMethod,
			|	ARAPObjects.CashFlowItem
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	PaymentSteps.ARAPObject AS ARAPObject,
			|	PaymentSteps.ARAPObject.Organization AS Organization,
			|	PaymentSteps.Partner,
			|	PaymentSteps.CashFlowItem,
			|	PaymentSteps.Period,
			|	PaymentSteps.ARAPCurrency,
			|	PaymentSteps.PaymentMethod,
			|	PaymentSteps.AmountAccordingToSchedule,
			|	SUM(ISNULL(SettlementsWithSuppliersTurnover.AmountDueReceipt, 0) -
			|		ISNULL(SettlementsWithSuppliersTurnover.BeingPaidTurnover, 0)) AS PayAmount
			|FROM
			|	PaymentSteps AS PaymentSteps
			|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Turnovers(, , Period, ) AS SettlementsWithSuppliersTurnover
			|		ON (SettlementsWithSuppliersTurnover.ARAPObject = PaymentSteps.ARAPObject)
			|			AND (SettlementsWithSuppliersTurnover.Currency = PaymentSteps.ARAPCurrency)
			|			AND (SettlementsWithSuppliersTurnover.AccountingDimensionByPartners = PaymentSteps.AccountingDimensionByPartners)
			|
			|GROUP BY
			|	PaymentSteps.ARAPObject,
			|	PaymentSteps.Partner,
			|	PaymentSteps.CashFlowItem,
			|	PaymentSteps.Period,
			|	PaymentSteps.ARAPCurrency,
			|	PaymentSteps.PaymentMethod,
			|	PaymentSteps.AmountAccordingToSchedule
			|
			|ORDER BY
			|	PaymentSteps.Period
			|TOTALS BY
			|	ARAPObject";
			Else
			QueryText = "
				|SELECT
				|	ARAPObjects.Ref AS ARAPObject,
				|	ARAPObjects.PaymentMethod AS PaymentMethod,
				|	ARAPObjects.Contract AS Contract,
				|	ARAPObjects.Terms AS Terms
				|INTO TTCalculationObjects_
				|FROM 
				|	Catalog.ARAPObjects AS ARAPObjects
				|WHERE
				|	ARAPObjects.Object IN (&PurchaseOrder)
				|	AND NOT ARAPObjects.DeletionMark
				|INDEX BY 
				|	ARAPObject
				|; 
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	SettlementsWithSuppliersTurnover.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	SettlementsWithSuppliersTurnover.ARAPObject AS ARAPObject,
				|	SettlementsWithSuppliersTurnover.Currency AS Currency,
				|	-SettlementsWithSuppliersTurnover.BeingPaidTurnover AS PayAmount
				|INTO PreparedAmountDue
				|FROM
				|	AccumulationRegister.VendorsARAPAccounting.Turnovers(
				|			,
				|			,
				|			Period,
				|			ARAPObject IN
				|				(SELECT
				|					TTCalculationObjects_.ARAPObject
				|				FROM
				|					TTCalculationObjects_)) AS SettlementsWithSuppliersTurnover
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	VendorsARAPAccounting.ARAPObject            AS ARAPObject,
				|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	Dimension.Partner                              AS Partner,
				|	Dimension.Organization                          AS Organization,
				|	CASE
				|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
				|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfPurchaseFromVendors).CashFlowItem
				|		ELSE ARAPObjects.Contract.CashFlowItem
				|	END                                          AS CashFlowItem,
				|	CASE
				|		WHEN VendorsARAPAccounting.PlannedRepaymentDate < &CurrentDate
				|			THEN &CurrentDate
				|		ELSE VendorsARAPAccounting.PlannedRepaymentDate
				|	END                                          AS Period,
				|	VendorsARAPAccounting.Currency                    AS ARAPCurrency,
				|	ARAPObjects.PaymentMethod                    AS PaymentMethod,
				|	VendorsARAPAccounting.AmountDueBalance            AS AmountAccordingToSchedule
				|INTO BalanceAmountsDue
				|FROM
				|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(,ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS VendorsARAPAccounting
				|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
				|			ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
				|				AND (&Organization = Dimension.Organization
				|					OR &Organization = UNDEFINED)
				|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
				|			ON VendorsARAPAccounting.ARAPObject = ARAPObjects.Ref
				|
				|UNION ALL
				|
				|SELECT
				|	VendorsARAPAccounting.ARAPObject            AS ARAPObject,
				|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	Dimension.Partner                              AS Partner,
				|	Dimension.Organization                          AS Organization,
				|	CASE
				|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
				|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfPurchaseFromVendors).CashFlowItem
				|		ELSE ARAPObjects.Contract.CashFlowItem
				|	END                                          AS CashFlowItem,
				|	CASE
				|		WHEN VendorsARAPAccounting.PlannedRepaymentDate < &CurrentDate
				|			THEN &CurrentDate
				|		ELSE VendorsARAPAccounting.PlannedRepaymentDate
				|	END                                          AS Period,
				|	VendorsARAPAccounting.Currency                    AS ARAPCurrency,
				|	ARAPObjects.PaymentMethod                    AS PaymentMethod,
				|	VendorsARAPAccounting.DebtBalance               AS AmountAccordingToSchedule
				|FROM
				|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(,ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)) AS VendorsARAPAccounting
				|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
				|			ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
				|				AND (&Organization = Dimension.Organization
				|					OR &Organization = UNDEFINED)
				|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
				|			ON VendorsARAPAccounting.ARAPObject = ARAPObjects.Ref
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	NestedQuery.ARAPObject AS ARAPObject,
				|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|	NestedQuery.Partner AS Partner,
				|	NestedQuery.Organization AS Organization,
				|	NestedQuery.CashFlowItem AS CashFlowItem,
				|	NestedQuery.Period AS Period,
				|	NestedQuery.ARAPCurrency AS ARAPCurrency,
				|	NestedQuery.PaymentMethod AS PaymentMethod,
				|	NestedQuery.AmountAccordingToSchedule AS AmountAccordingToSchedule,
				|	ISNULL(PreparedAmountDue.PayAmount, 0) AS PayAmount
				|FROM
				|	(SELECT
				|		BalanceAmountsDue.ARAPObject AS ARAPObject,
				|		BalanceAmountsDue.AccountingDimensionByPartners AS AccountingDimensionByPartners,
				|		BalanceAmountsDue.Partner AS Partner,
				|		BalanceAmountsDue.Organization AS Organization,
				|		BalanceAmountsDue.CashFlowItem AS CashFlowItem,
				|		BalanceAmountsDue.Period AS Period,
				|		BalanceAmountsDue.ARAPCurrency AS ARAPCurrency,
				|		BalanceAmountsDue.PaymentMethod AS PaymentMethod,
				|		SUM(BalanceAmountsDue.AmountAccordingToSchedule) AS AmountAccordingToSchedule
				|	FROM
				|		BalanceAmountsDue AS BalanceAmountsDue
				|	
				|	GROUP BY
				|		BalanceAmountsDue.ARAPObject,
				|		BalanceAmountsDue.AccountingDimensionByPartners,
				|		BalanceAmountsDue.Partner,
				|		BalanceAmountsDue.Organization,
				|		BalanceAmountsDue.CashFlowItem,
				|		BalanceAmountsDue.Period,
				|		BalanceAmountsDue.ARAPCurrency,
				|		BalanceAmountsDue.PaymentMethod) AS NestedQuery
				|		LEFT JOIN PreparedAmountDue AS PreparedAmountDue
				|		ON (NestedQuery.ARAPObject = PreparedAmountDue.ARAPObject
				|				AND NestedQuery.AccountingDimensionByPartners = PreparedAmountDue.AccountingDimensionByPartners
				|				AND NestedQuery.ARAPCurrency = PreparedAmountDue.Currency)
				|
				|ORDER BY
				|	Period
				|TOTALS BY
				|	ARAPObject
				|";
			EndIf;
			
		EndIf;
		
		Query = New Query(QueryText);
		
		Query.SetParameter("ARAPObjectSettings",ARAPObjectSettings);
		Query.SetParameter("PurchaseOrder", PurchaseOrder);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("Contract", Contract);
		Query.SetParameter("CurrentDate", CurrentSessionDate());
		
		CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Enums.BusinessTransactions.PaymentToVendor);
		AmountForAllocation = AmountToPay;
		
		SelectionByOrders = Query.Execute().Select(QueryResultIteration.ByGroups);
		While SelectionByOrders.Next() Do
			
			TotalAmountOnSchedule = 0;
			PaymentAmountTakenIntoAccount = 0;
			
			Selection = SelectionByOrders.Select();
			While Selection.Next() Do
				
				If (AmountForAllocation <> 0 And AmountToPay = 0) 
					Or (AmountForAllocation = 0
					And Selection.Period > CurrentSessionDate()
					And ARAPDetails.Count() <> 0) Then
					Break;
				EndIf;
					
				PayAmount = ?(Selection.PayAmount < 0, 0, Selection.PayAmount);
				// We will find the first unpaid stage.
				If (Selection.AmountAccordingToSchedule + TotalAmountOnSchedule) > PayAmount
				 Or AmountToPay <> 0 Then
					
					NewRow = ARAPDetails.Add();
					FillPropertyValues(NewRow, Selection);
					If Not ValueIsFilled(NewRow.CashFlowItem) Then
						NewRow.CashFlowItem = CFItemByBT;
					EndIf;
					NewRow.AmountARAP = Selection.AmountAccordingToSchedule + TotalAmountOnSchedule - (PayAmount + PaymentAmountTakenIntoAccount);
					If AmountToPay <> 0 Then
						NewRow.AmountARAP = Min(NewRow.AmountARAP, AmountToPay);
						AmountToPay = AmountToPay - NewRow.AmountARAP;
						PaymentAmountTakenIntoAccount = PaymentAmountTakenIntoAccount + NewRow.AmountARAP;
						TotalAmountOnSchedule = TotalAmountOnSchedule + Selection.AmountAccordingToSchedule;
					EndIf;
					
					NewRow.Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
					                    	NewRow.AmountARAP,
					                    	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
					                    	Selection.ARAPCurrency,
					                    	DocumentCurrency,
					                    	CurrentSessionDate(),
					                    	Selection.ARAPObject);
					
					If ValueIsFilled(RequiredPaymentDate) Then
						RequiredPaymentDate = Min(RequiredPaymentDate, Selection.Period);
					Else
						RequiredPaymentDate = Selection.Period;
					EndIf;
					
					If NewRow.AmountARAP = 0 And NewRow.Sum = 0 Then
						ARAPDetails.Delete(NewRow);
					EndIf;
					
				Else
					
					TotalAmountOnSchedule = TotalAmountOnSchedule + Selection.AmountAccordingToSchedule;
					
				EndIf;
				
			EndDo;
			
		EndDo;
	
		If ARAPDetails.Count() = 0 Then
			NewRow = ARAPDetails.Add();
			If ValueIsFilled(Contract)
				And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
				Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) Then
				
				NewRow.ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(
					Contract,, Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
				SetPrivilegedMode(True);
				ContractDetails_ = Common.ObjectAttributesValues(
					Contract, "Partner, CashFlowItem, ARAPCurrency");
				SetPrivilegedMode(False);
				NewRow.Partner = ContractDetails_.Partner;
				NewRow.CashFlowItem = ContractDetails_.CashFlowItem;
				If Not ValueIsFilled(NewRow.CashFlowItem) Then
					NewRow.CashFlowItem = CFItemByBT;
				EndIf;
				NewRow.ARAPCurrency = ContractDetails_.ARAPCurrency;
				
			ElsIf TypeOf(PurchaseOrder) <> Type("Array") Then
				
				NewRow.ARAPObject	= ARAPObjectsServer.GetCalculationObjectFromLink(PurchaseOrder,,Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
				If ValueIsFilled(NewRow.ARAPObject) Then
					APARObjectDetails = Common.ObjectAttributesValues(NewRow.ARAPObject, "Partner, ARAPCurrency");
					FillPropertyValues(NewRow, APARObjectDetails);
				Else
					NewRow.Partner = Common.ObjectAttributeValue(PurchaseOrder, "Partner");
				EndIf;
				If ValueIsFilled(Contract) Then
					NewRow.CashFlowItem = Common.ObjectAttributeValue(Contract, "CashFlowItem");
				EndIf;
				If Not ValueIsFilled(NewRow.CashFlowItem) Then
					NewRow.CashFlowItem = CFItemByBT;
				EndIf;
			EndIf;
		
		Else
			ARAPDetails.GroupBy("ARAPObject, Partner, CashFlowItem, ARAPCurrency", "Sum, AmountARAP");
		EndIf;
		
		CashServer.FillInNDSInDecryption(ARAPDetails,
			CashServer.TranscriptOfVATPayment(Organization, CurrentSessionDate(), DocumentCurrency, ARAPDetails.UnloadColumn("ARAPObject"), False));
	EndIf;
	
EndProcedure

// Procedure for filling in the table part "payment Decryption" for the return to the supplier.
//
// Parameters:
//	Objects - DocumentRef, Array of DocumentRef - document Foundation.
//	Organization - CatalogRef.Companies - Organization of the document.
//	DocumentCurrency - CatalogRef.Currencies - Currency of the cash receipt document.
//	DocumentAmount - Number - The amount of the base document.
//	Partner - CatalogRef.Partners - Partner of the Foundation document.
//	ARAPDetails - TabularSection - the tabular part of the document.
//
Procedure FillInDecryptionOfRefundPaymentToSupplier(Objects, Organization, DocumentCurrency, DocumentAmount, Partner, ARAPDetails) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(DocumentCurrency) Then
		
		Query = New Query("SELECT
		|	ARAPObjects.Object AS Object,
		|	ARAPObjects.Ref AS ARAPObject,
		|	ARAPObjects.Organization AS Organization,
		|	ARAPObjects.Contract AS Contract,
		|	CASE WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Catalog.CounterpartyContracts)
		|			THEN ARAPObjects.Contract.CashFlowItem
		|		WHEN
		|			ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = 
		|				VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|			THEN CAST(ARAPObjects.Terms AS Catalog.TermsOfPurchaseFromVendors).CashFlowItem
		|		ELSE ARAPObjects.Contract.CashFlowItem
		|	END AS CashFlowItem
		|INTO TTCalculationObjects_
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object IN (&Objects)
		|	AND NOT ARAPObjects.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ARAPObjects.Object AS PaymentPurpose,
		|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
		|	ARAPObjects.Organization AS Organization,
		|	ARAPObjects.CashFlowItem AS CashFlowItem,
		|	VendorsARAPAccounting.Currency AS ARAPCurrency,
		|	VendorsARAPAccounting.AmountDueBalance AS AmountARAP
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(,
		|		ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)
		|	) AS VendorsARAPAccounting
		|	INNER JOIN TTCalculationObjects_ AS ARAPObjects
		|		ON ARAPObjects.ARAPObject = VendorsARAPAccounting.ARAPObject
		|WHERE
		|	VendorsARAPAccounting.AmountDueBalance > 0
		|");
		
		Query.SetParameter("Objects", Objects);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Partner = Partner;
			
			Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
			        	NewRow.AmountARAP,
			        	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
			        	Selection.ARAPCurrency,
			        	DocumentCurrency,
			        	CurrentSessionDate(),
			        	Selection.ARAPObject);
			
			If Sum <= DocumentAmount Then
				NewRow.Sum = Sum;
			Else
				NewRow.Sum = DocumentAmount;
				NewRow.AmountARAP = 0;
			EndIf;
		EndIf;
		
		CashServer.FillInNDSInDecryption(ARAPDetails,
			CashServer.TranscriptOfVATPayment(Organization, CurrentSessionDate(), DocumentCurrency, ARAPDetails.UnloadColumn("ARAPObject"), True));
	EndIf;
	
EndProcedure

// Procedure for filling in the table part "payment Decryption" under the agreement.
//
// Parameters:
//		Contract - CatalogRef.CounterpartyContracts - A contract to obtain a residue.
//		DocumentCurrency - CatalogRef.Currencies - the currency of the document.
//		ARAPDetails - ValueTable - the table to fill in.
//		Organization - CatalogRef.Companies - Optional, organization for receiving settlement balances.
//
Procedure FillInTranscriptOfPaymentUnderContractWithSupplier(Contract, DocumentCurrency, ARAPDetails, Organization) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(DocumentCurrency) Then
		
		Query = New Query("
		|SELECT
		|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
		|	ISNULL(Dimension.Partner, ContractData.Partner) AS Partner,
		|	ISNULL(VendorsARAPAccountingBalance.Currency, ContractData.ARAPCurrency) AS ARAPCurrency,
		|	ISNULL(VendorsARAPAccountingBalance.BeingPaidBalance - VendorsARAPAccountingBalance.AmountDueBalance, 0) AS AmountARAP
		|FROM
		|	Catalog.CounterpartyContracts AS ContractData
		|
		|	LEFT JOIN
		|		Catalog.ARAPObjects AS ARAPObjects
		|	ON
		|		ARAPObjects.Object = &Contract
		|		AND ARAPObjects.Organization = &Organization
		|		AND NOT ARAPObjects.DeletionMark
		|
		|	LEFT JOIN
		|		AccumulationRegister.VendorsARAPAccounting.Balance(, ARAPObject.Object = &Contract) AS VendorsARAPAccountingBalance
		|	ON
		|		TRUE
		|		
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|		ON VendorsARAPAccountingBalance.AccountingDimensionByPartners = Dimension.DimensionKey
		|			AND (&Organization = Dimension.Organization
		|				OR &Organization = UNDEFINED)
		|WHERE
		|	ContractData.Ref = &Contract
		|");
		
		Query.SetParameter("Contract", Contract);
		Query.SetParameter("Organization", Organization);
		
		CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
			Enums.BusinessTransactions.PaymentToVendor);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewRow.CashFlowItem = Common.ObjectAttributeValue(Contract, "CashFlowItem");
		If Not ValueIsFilled(NewRow.CashFlowItem) Then
			NewRow.CashFlowItem = CFItemByBT;
		EndIf;
		
		NewRow.Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
		                    	NewRow.AmountARAP,
		                    	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization),
		                    	Selection.ARAPCurrency,
		                    	DocumentCurrency,
		                    	CurrentSessionDate(),
		                    	Selection.ARAPObject);
		
		CashServer.FillInNDSInDecryption(ARAPDetails,
			CashServer.TranscriptOfVATPayment(Organization, CurrentSessionDate(), DocumentCurrency, ARAPDetails.UnloadColumn("ARAPObject"), False));
	EndIf;
	
EndProcedure

// Recalculates the amount of the payment decryption to the selected currency.
//
// Parameters:
//		Object - DocumentObject - Document for recalculating the amount.
//		AmountTotal - Number - the amount of the document.
//
Procedure ConvertAmountsToCurrencyPaymentDecryption(Object, AmountTotal) Export
	
	DocumentAmount = AmountTotal;
	TotalAmount_5 = Object.ARAPDetails.Total("Sum");
	
	// Let's recalculate the amounts in the tabular part of the document.
	If TotalAmount_5 <> 0 Then
		
		For Each TableRow In Object.ARAPDetails Do
			
			Sum = Round(DocumentAmount * TableRow.Sum / TotalAmount_5, 2, 1);
			TotalAmount_5 = TotalAmount_5 - TableRow.Sum;
			DocumentAmount = DocumentAmount - Sum;
			TableRow.Sum = Sum;
			
			If ValueIsFilled(TableRow.ARAPObject) Then
				If TableRow.ARAPCurrency = Object.Currency Then
					TableRow.AmountARAP = 0;
				EndIf;
			Else
				TableRow.ARAPCurrency = Undefined;
				TableRow.AmountARAP = 0;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion