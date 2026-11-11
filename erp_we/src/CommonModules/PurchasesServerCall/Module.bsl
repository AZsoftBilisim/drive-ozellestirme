////////////////////////////////////////////////////////////////////////////////
// The module "Purchasing a Server call" contains procedures and functions for 
// server processing of user actions in the process of working with purchase documents.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Checks whether the table part contains rows with an empty receipt date in rows that are not canceled.
//	
// Parameters:
//		Object - FormDataStructure - object being checked
//		TSName - String - name of the PM being checked.
//
// Returns:
//		Boolean - indicates whether there are lines with an empty receipt date.
Function ReceiptDateIsBlank(Val Object, TSName) Export
	
	For Each CurRow In Object[TSName] Do
		
		If Not CurRow.Canceled 
			And Not ValueIsFilled(CurRow.DateOfReceipt) Then
			
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

//This function generates a request text based on order data
Function QueryTextByOrders()
	QueryText =
	"SELECT
	|	PurchaseOrder.Ref AS PurchaseOrder,
	|	PurchaseOrder.Department AS Department,
	|	PurchaseOrder.Partner AS Partner,
	|	PurchaseOrder.Counterparty AS Counterparty,
	|	PurchaseOrder.Contract AS Contract,
	|	PurchaseOrder.Organization AS Organization,
	|	PurchaseOrder.Terms AS Terms,
	|	PurchaseOrder.Warehouse AS Warehouse,
	|	PurchaseOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	PurchaseOrder.BusinessOperation AS BusinessOperation,
	|	PurchaseOrder.Currency AS ARAPCurrency,
	|	PurchaseOrder.VATTaxation AS VATTaxation,
	|	PurchaseOrder.PurchaseForActivity AS PurchaseForActivity,
	|	PurchaseOrder.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseOrder.ARAPObjectSettings AS ARAPObjectSettings,
	|	PurchaseOrder.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	PurchaseOrder.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
	|	PurchaseOrder.PackageDepositIsRequired AS PackageDepositIsRequired,
	|	ISNULL(PurchaseOrder.Terms.CalculatePackageReturnDateAccordingToCalendar, FALSE) AS CalculatePackageReturnDateAccordingToCalendar,
	|	ISNULL(PurchaseOrder.Terms.ScheduleOfPackageReturn, UNDEFINED) AS ScheduleOfPackageReturn,
	|	PurchaseOrder.LineOfBusiness AS LineOfBusiness,
	|	PurchaseOrder.Status AS Status,
	|	VALUE(Enum.PurchaseOrderStatuses.Confirmed_) AS AcceptableStatus1,
	|	VALUE(Enum.PurchaseOrderStatuses.Closed) AS AcceptableStatus2,
	|	UNDEFINED AS AcceptableStatus3,
	|	NOT PurchaseOrder.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
	|				OR PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus,
	|	PurchaseOrder.BusinessOperation NOT IN (&ValidOperations) AS ThereIsInvalidOperation,
	|	UNDEFINED AS VendorPriceKind,
	|	PurchaseOrder.GoodsReceiptOption AS GoodsReceiptOption,
	|	PurchaseOrder.RegisterVendorPrices AS RegisterVendorPrices,
	|	PurchaseOrder.PaymentMethod AS PaymentMethod,
	|	UNDEFINED AS PaymentSchedule,
	|	PurchaseOrder.CashAccount AS CashAccount,
	|	PurchaseOrder.BankAccount AS BankAccount,
	|	PurchaseOrder.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
	|	PurchaseOrder.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson
	|INTO PurchaseOrders
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref IN(&ReferencesArrray)
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialProviderOrder2_5.Ref                                               AS PurchaseOrder,
	|	MaterialProviderOrder2_5.Department                                        AS Department,
	|	MaterialProviderOrder2_5.Partner                                              AS Partner,
	|	MaterialProviderOrder2_5.Counterparty                                           AS Counterparty,
	|	MaterialProviderOrder2_5.Contract                                              AS Contract,
	|	MaterialProviderOrder2_5.Organization                                          AS Organization,
	|	UNDEFINED                                                          AS Terms,
	|	MaterialProviderOrder2_5.WarehouseForReceipt                                     AS Warehouse,
	|	MaterialProviderOrder2_5.FinancialAccountingGroup                               AS FinancialAccountingGroup,
	|	VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5) AS BusinessOperation,
	|	MaterialProviderOrder2_5.Currency                                               AS ARAPCurrency,
	|	UNDEFINED                                                          AS VATTaxation,
	|	UNDEFINED                                                          AS PurchaseForActivity,
	|	UNDEFINED                                                          AS PriceIncludesVAT,
	|	MaterialProviderOrder2_5.ARAPObjectSettings                                      AS ARAPObjectSettings,
	|	FALSE                                                                  AS ToReturnReusablePackage,
	|	DATETIME(1, 1, 1)                                                    AS ReusablePackageReturnCycleLength,
	|	MaterialProviderOrder2_5.PackageDepositIsRequired                                 AS PackageDepositIsRequired,
	|	FALSE                                                                  AS CalculatePackageReturnDateAccordingToCalendar,
	|	UNDEFINED                                                          AS ScheduleOfPackageReturn,
	|	MaterialProviderOrder2_5.LineOfBusiness                              AS LineOfBusiness,
	|	MaterialProviderOrder2_5.Status                                               AS Status,
	|	VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)          AS AcceptableStatus1,
	|	VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip)              AS AcceptableStatus2,
	|	VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)                 AS AcceptableStatus3,
	|	NOT MaterialProviderOrder2_5.Posted                                          AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN MaterialProviderOrder2_5.Status IN (
	|					VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
	|					VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|					VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                                                 AS ThereAreErrorsStatus,
	|	NOT VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5) IN (
	|													&ValidOperations)  AS ThereIsInvalidOperation,
	|	MaterialProviderOrder2_5.PriceTypeMaterials                                     AS VendorPriceKind,
	|	UNDEFINED                                                          AS GoodsReceiptOption,
	|	MaterialProviderOrder2_5.RegisterVendorPrices                         AS RegisterVendorPrices,
	|	MaterialProviderOrder2_5.PaymentMethod                                          AS PaymentMethod,
	|	MaterialProviderOrder2_5.PaymentSchedule                                         AS PaymentSchedule,
	|	MaterialProviderOrder2_5.CashAccount                                                AS CashAccount,
	|	MaterialProviderOrder2_5.BankAccount                                       AS BankAccount,
	|	MaterialProviderOrder2_5.ForeignCurrencyTransaction                                        AS ForeignCurrencyTransaction,
	|	FALSE                                                                  AS OperationWithSelfEmployedPerson
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	MaterialProviderOrder2_5.Ref IN(&ReferencesArrray)
	|;
	|SELECT
	|	CASE WHEN OrderWarehouse.IsFolder
	|		THEN OrderWarehouse.Ref
	|		ELSE OrderWarehouse.Parent
	|	END AS GroupOfWarehouses,
	|	PurchaseOrders.Warehouse AS Warehouse
	|INTO OrdersWarehouses
	|FROM PurchaseOrders
	|	LEFT JOIN Catalog.Warehouses AS OrderWarehouse
	|		ON OrderWarehouse.Ref = PurchaseOrders.Warehouse
	|
	|WHERE PurchaseOrders.BusinessOperation IN (&ValidOperations)
	|;
	|SELECT PurchaseOrder, BusinessOperation FROM PurchaseOrders WHERE ThereIsInvalidOperation
	|
	|;
	|SELECT
	|	MIN(PurchaseOrders.Department)                  AS Department,
	|	MIN(PurchaseOrders.Partner)                        AS Partner,
	|	MIN(PurchaseOrders.Counterparty)                     AS Counterparty,
	|	MIN(PurchaseOrders.Contract)                        AS Contract,
	|	MIN(PurchaseOrders.Organization)                    AS Organization,
	|	MIN(PurchaseOrders.Terms)                     AS Terms,
	|	CASE
	|		WHEN &UseReceiptForMultipleOrders
	|				AND COUNT(DISTINCT PurchaseOrders.Warehouse) > 1
	|				AND MIN(OrdersWarehouses.GroupOfWarehouses.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)
	|		THEN
	|			MIN(OrdersWarehouses.GroupOfWarehouses)
	|		ELSE
	|			MIN(PurchaseOrders.Warehouse)
	|	END                                                     AS Warehouse,
	|	MIN(PurchaseOrders.BusinessOperation)          AS BusinessOperation,
	|	MIN(PurchaseOrders.ARAPCurrency)           AS ARAPCurrency,
	|	MIN(PurchaseOrders.VATTaxation)             AS VATTaxation,
	|	MIN(PurchaseOrders.PurchaseForActivity)         AS PurchaseForActivity,
	|	MIN(PurchaseOrders.PriceIncludesVAT)                AS PriceIncludesVAT,
	|	MIN(PurchaseOrders.ARAPObjectSettings)                AS ARAPObjectSettings,
	|	MIN(PurchaseOrders.ToReturnReusablePackage)      AS ToReturnReusablePackage,
	|	MIN(PurchaseOrders.ReusablePackageReturnCycleLength) AS ReusablePackageReturnCycleLength,
	|	MIN(PurchaseOrders.PackageDepositIsRequired)           AS PackageDepositIsRequired,
	|	MIN(PurchaseOrders.CalculatePackageReturnDateAccordingToCalendar) AS CalculatePackageReturnDateAccordingToCalendar,
	|	MIN(PurchaseOrders.ScheduleOfPackageReturn)          AS ScheduleOfPackageReturn,
	|	MIN(PurchaseOrders.LineOfBusiness)        AS LineOfBusiness,
	|	MIN(PurchaseOrders.VendorPriceKind)              AS VendorPriceKind,
	|	MIN(PurchaseOrders.GoodsReceiptOption)          AS GoodsReceiptOption,
	|	MIN(PurchaseOrders.FinancialAccountingGroup)         AS FinancialAccountingGroup,
	|	MIN(PurchaseOrders.RegisterVendorPrices)   AS RegisterVendorPrices,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.Department) > 1
	|			AND MAX(PurchaseOrders.ARAPObjectSettings) = VALUE(Enum.ARAPObjectSettings.ByOrders)
	|			AND &UseLocal = TRUE
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesDepartment,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.Partner) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesPartner,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.Counterparty) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCounterparty,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.Contract) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesContract,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.Organization) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCompany,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.Terms) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesAgreement,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.Warehouse) > 1
	|		THEN
	|			CASE WHEN &UseReceiptForMultipleOrders
	|				AND COUNT(DISTINCT OrdersWarehouses.GroupOfWarehouses) = 1
	|				AND MIN(OrdersWarehouses.GroupOfWarehouses.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)
	|				THEN FALSE
	|			ELSE TRUE
	|			END
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesWarehouse,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.BusinessOperation) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesEconomicOperation,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.ARAPCurrency) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInCurrencyOfMutualSettlements,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.VATTaxation) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesVATTaxation,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.PurchaseForActivity) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesPurchasingForActivities,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.PriceIncludesVAT) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesPriceIncludesVAT,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.ToReturnReusablePackage) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInMultiTurnContainers,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.ReusablePackageReturnCycleLength) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInReturnPeriodOfMultiTurnContainers,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.PackageDepositIsRequired) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesDepositForContainerIsRequired,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.ARAPObjectSettings) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInOrderOfCalculations,
	|	CASE
	|		WHEN
	|			MIN(PurchaseOrders.Warehouse.IsFolder) = TRUE AND MIN(PurchaseOrders.Warehouse.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|		THEN
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|		WHEN &UseReceiptForMultipleOrders
	|				AND COUNT(DISTINCT PurchaseOrders.Warehouse) > 1
	|				AND MIN(OrdersWarehouses.GroupOfWarehouses.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)
	|		THEN
	|			MIN(OrdersWarehouses.GroupOfWarehouses)
	|		ELSE
	|			MIN(PurchaseOrders.Warehouse)
	|	END AS WarehouseForReceipt,
	|	CASE
	|		WHEN
	|			MIN(PurchaseOrders.Warehouse.IsFolder) = TRUE AND MIN(PurchaseOrders.Warehouse.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|		THEN
	|			TRUE
	|		WHEN &UseReceiptForMultipleOrders
	|				AND COUNT(DISTINCT PurchaseOrders.Warehouse) > 1
	|				AND (MIN(OrdersWarehouses.GroupOfWarehouses.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|					OR MIN(OrdersWarehouses.GroupOfWarehouses.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.Disable))
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ItIsForbiddenToSelectWarehouseGroup,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.LineOfBusiness) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInDirectionOfActivity_,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.VendorPriceKind) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInPriceOfSupplier,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.GoodsReceiptOption) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInAcceptanceOfGoods,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.FinancialAccountingGroup) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInFinancialAccounting,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						PurchaseOrders.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|					THEN
	|						PurchaseOrders.BankAccount
	|					ELSE
	|						NULL
	|				END) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesBankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.PaymentMethod) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInFormOfPayment,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.ForeignCurrencyTransaction) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesPaymentInCurrency,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						PurchaseOrders.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|					THEN
	|						PurchaseOrders.BankAccount
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(PurchaseOrders.BankAccount)
	|		ELSE
	|			VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|	END AS BankAccount,
	|	MIN(PurchaseOrders.ForeignCurrencyTransaction)                  AS ForeignCurrencyTransaction,
	|	MIN(PurchaseOrders.PaymentSchedule)                   AS PaymentSchedule,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.PaymentMethod) > 1
	|		THEN
	|			VALUE(Enum.PaymentForms.EmptyRef)
	|		ELSE
	|			MIN(PurchaseOrders.PaymentMethod)
	|	END AS PaymentMethod,
	|	MIN(PurchaseOrders.OperationWithSelfEmployedPerson)           AS OperationWithSelfEmployedPerson,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT PurchaseOrders.OperationWithSelfEmployedPerson) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesOfOperationWithSelfEmployed
	|FROM
	|	PurchaseOrders AS PurchaseOrders
	|
	|	LEFT JOIN OrdersWarehouses AS OrdersWarehouses
	|		ON OrdersWarehouses.Warehouse = PurchaseOrders.Warehouse
	|
	|WHERE PurchaseOrders.BusinessOperation IN (&ValidOperations)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOrder,
	|	Status,
	|	AcceptableStatus1,
	|	AcceptableStatus2,
	|	AcceptableStatus3,
	|	ThereAreErrorsPosted,
	|	ThereAreErrorsStatus
	|FROM
	|	PurchaseOrders AS PurchaseOrders
	|WHERE
	|	PurchaseOrders.BusinessOperation IN (&ValidOperations)
	|	AND (ThereAreErrorsPosted
	|		OR ThereAreErrorsPosted)";

	Return QueryText;
EndFunction

// Checks whether it is possible to use several different orders in the same document
// If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
// 		ReferencesArrray   - Array - orders to suppliers, which are specified in the document
// 		DocumentName   - String - name of the document in the metadata that is being validated
//
// Returns:
// 		Boolean - True, if the details of the header differ in the transferred orders and it is impossible to carry out a document with these orders.
//
Function CheckCompatibilityOfOrdersInOneDocument(Val ReferencesArrray, DocumentName) Export
	
	Query = New Query;
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	ValidOperations = TMCommonUse.PermissibleBusinessOperationsOfDocument(DocumentName);
	Query.SetParameter("ValidOperations", ValidOperations);
	Query.SetParameter("UseLocal", GetFunctionalOption("UseLocal"));
	Query.SetParameter("UseReceiptForMultipleOrders",GetFunctionalOption("UseReceiptForMultipleOrders"));
	
	Query.Text = QueryTextByOrders();
		
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch(); 
	SetPrivilegedMode(False);
	SampleOrders = QueryResult[QueryResult.UBound()].Select();
	
	ExcludedOrders = New Array;
	FetchingOrdersWithInvalidOperation = QueryResult[QueryResult.UBound() - 2].Select();
	
	While FetchingOrdersWithInvalidOperation.Next() Do
		
		If ReferencesArrray.Count() > 1 Then
			MessageText = NStr("vi = 'Đơn hàng %ReferenceOrder% bị bỏ qua vì không thể thực thi chứng từ ""%DocumentSynonym%"" trên cơ sở đơn hàng với giao dịch ""%BusinessOperation%"".';
								|ru = 'Распоряжение %ReferenceOrder% пропущено, т.к. невозможно оформить документ ""%DocumentSynonym%"" на основании распоряжения с операцией ""%BusinessOperation%"".';
								|en = 'The %ReferenceOrder% reference is skipped as you cannot generate the ""%DocumentSynonym%"" document based on the reference with the ""%BusinessOperation%"" operation.'; fa = 'The %ReferenceOrder% reference is skipped as you cannot generate the ""%DocumentSynonym%"" document based on the reference with the ""%BusinessOperation%"" operation.';
								|it = 'Il riferimento  %ReferenceOrder% è mancante, poiché non è possibile formalizzare il documento ""%DocumentSynonym%"" sulla base del referimento con operazione ""%BusinessOperation%"".';
								|pl = 'Zamówienie %ReferenceOrder% jest przepuszczone, ponieważ niemożliwe jest sporządzenie dokumentu ""%DocumentSynonym%"" na podstawie zamówienia z operacją ""%BusinessOperation%"".';
								|tr = 'Sipariş %ReferenceOrder% atlandı çünkü ""%BusinessOperation%"" işlemi ile siparişe göre ""%DocumentSynonym%"" belgesini düzenlemek mümkün değil.'");
			MessageText = StrReplace(MessageText, "%ReferenceOrder%", FetchingOrdersWithInvalidOperation.PurchaseOrder);
		Else
			MessageText = NStr("vi = 'Không thể thực thi chứng từ ""%DocumentSynonym%"" trên cơ sở đơn đặt hàng với hoạt động ""%BusinessOperation%"".';
								|ru = 'Невозможно оформить документ ""%DocumentSynonym%"" на основании распоряжения с операцией ""%BusinessOperation%"".';
								|en = 'Cannot register the ""%DocumentSynonym%"" document based on the reference with the ""%BusinessOperation%"" operation.'; fa = 'Cannot register the ""%DocumentSynonym%"" document based on the reference with the ""%BusinessOperation%"" operation.';
								|it = 'Non è possibile formalizzare il documento %DocumentSynonym%"" sulla base del referimento con operazione ""%BusinessOperation%"".';
								|pl = 'Niemożliwe jest sporządzenie dokumentu ""%DocumentSynonym%"" na podstawie zamówienia z operacją ""%BusinessOperation%"".';
								|tr = '""%DocumentSynonym%"" belgesini ""%BusinessOperation%"" işlemiyle siparişe göre düzenlemek mümkün değil.'");
		EndIf;
		
		MessageText = StrReplace(MessageText, "%DocumentSynonym%", Metadata.Documents[DocumentName].Synonym);
		MessageText = StrReplace(MessageText, "%BusinessOperation%", FetchingOrdersWithInvalidOperation.BusinessOperation);
		CommonClientServer.MessageToUser(MessageText,FetchingOrdersWithInvalidOperation.PurchaseOrder);
		
		ExcludedOrders.Add(FetchingOrdersWithInvalidOperation.PurchaseOrder);
	EndDo;
	
	If FetchingOrdersWithInvalidOperation.Count() = ReferencesArrray.Count() Then
		Return False;
	EndIf;
	
	ReferencesArrray = CommonClientServer.ReduceArray(ReferencesArrray, ExcludedOrders);
	
	SelectionHeaderDetails = QueryResult[QueryResult.UBound() - 1].Select();
	SelectionHeaderDetails.Next();
	
	Cancel = False;
	
	MessageText = NStr("vi = 'Các đơn hàng được chỉ định khác nhau trong trường ""%FieldPresentation%""';
						|ru = 'У указанных распоряжений отличается поле ""%FieldPresentation%""';
						|en = 'The ""%FieldPresentation%"" field of the specified references differs.'; fa = 'The ""%FieldPresentation%"" field of the specified references differs.';
						|it = 'Nelle disposizioni evidenziate il campo ""%FieldPresentation%"" differisce';
						|pl = 'U podanych zamówień różni się pole ""%FieldPresentation%""';
						|tr = 'Belirtilen siparişler farklı bir alana sahip ""%FieldPresentation%""'");
	
	If SelectionHeaderDetails.ThereAreDifferencesDepartment Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Bộ phận';
																|ru = 'Подразделение';
																|en = 'Business unit'; fa = 'Business unit';
																|it = 'Reparto';
																|pl = 'Dział';
																|tr = 'Departman'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesPartner Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Bạn hàng';
																|ru = 'Партнер';
																|en = 'Partner'; fa = 'شریک تجاری';
																|it = 'Partner';
																|pl = 'Partner';
																|tr = 'İş ortağı'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesCounterparty Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Controparte';
																|pl = 'Kontrahent';
																|tr = 'Cari hesap'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesCompany Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Doanh nghiệp';
																|ru = 'Организация';
																|en = 'Company'; fa = 'Company';
																|it = 'Azienda';
																|pl = 'Firma';
																|tr = 'İş yeri'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesAgreement Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thỏa thuận';
																|ru = 'Соглашение';
																|en = 'Agreement'; fa = 'توافق‌نامه';
																|it = 'Accordo';
																|pl = 'Porozumienie';
																|tr = 'Anlaşma'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesContract Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Hợp đồng';
																|ru = 'Договор';
																|en = 'Contract'; fa = 'قرارداد';
																|it = 'Contratto';
																|pl = 'Contract';
																|tr = 'Sözleşme'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesWarehouse Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Kho bãi';
																|ru = 'Склад';
																|en = 'Warehouse'; fa = 'Warehouse';
																|it = 'Magazzino';
																|pl = 'Magazyn';
																|tr = 'Ambar'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesEconomicOperation Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giao dịch';
																|ru = 'Операция';
																|en = 'Transaction'; fa = 'تراکنش';
																|it = 'Operazione';
																|pl = 'Transaction';
																|tr = 'İşlem'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInCurrencyOfMutualSettlements Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Tiền tệ hạch toán công nợ';
																|ru = 'Валюта взаиморасчетов';
																|en = 'AR/AP currency'; fa = 'ارز دریافتنی/پرداختنی';
																|it = 'Valuta di regolamento dei conti';
																|pl = 'Waluta rozliczeń wzajemnych';
																|tr = 'Alacak/Borç muhasebesi para birimi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesVATTaxation Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Chịu thuế GTGT';
																|ru = 'Налогообложение НДС';
																|en = 'VAT taxation'; fa = 'مشمولیت مالیات بر ارزش افزوده';
																|it = 'Tassazione IVA';
																|pl = 'Opodatkowanie VAT';
																|tr = 'KDV vergilendirilmesi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesPriceIncludesVAT Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giá gồm thuế GTGT';
																|ru = 'Цена включает НДС';
																|en = 'Price includes VAT'; fa = 'قیمت شامل مالیات بر ارزش افزوده است';
																|it = 'Il prezzo include l''IVA';
																|pl = 'Cena zawiera VAT';
																|tr = 'Fiyata KDV dahildir'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInMultiTurnContainers Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Trả lại bao bì luân chuyển';
																|ru = 'Вернуть многооборотную тару';
																|en = 'Return reusable packaging'; fa = 'برگشت بسته‌بندی قابل استفاده مجدد';
																|it = 'Restituire l''imballaggio riutilizzabile';
																|pl = 'Zwrócić tarę wielokrotnego użytku';
																|tr = 'Yeniden kullanılabilir ambalajı iade et'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInReturnPeriodOfMultiTurnContainers Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thời hạn trả lại bao bì luân chuyển';
																|ru = 'Срок возврата многооборотной тары';
																|en = 'Reusable packaging return date'; fa = 'تاریخ بازگشت بسته‌بندی قابل استفاده مجدد';
																|it = 'Periodo di reso dell''imballaggio riutilizzabile';
																|pl = 'Termin zwrotu tary wielokrotnego użytku';
																|tr = 'Yeniden kullanılabilir ambalajın iade süresi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesDepositForContainerIsRequired Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Cần ký cược bao bì';
																|ru = 'Требуется залог за тару';
																|en = 'Packaging deposit is required'; fa = 'ودیعه بسته‌بندی لازم است';
																|it = 'È prevista la cauzione per l''imballaggio';
																|pl = 'Jest wymagana kaucja za tarę';
																|tr = 'Depozito gerekli'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInOrderOfCalculations Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Quy trình thanh toán';
																|ru = 'Порядок расчетов';
																|en = 'Payment terms'; fa = 'شرایط پرداخت';
																|it = 'Modalità di regolamenti';
																|pl = 'Sposób rozliczeń';
																|tr = 'Ödeme şartları'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInDirectionOfActivity_ Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Lĩnh vực hoạt động';
																|ru = 'Направление деятельности';
																|en = 'Line of business'; fa = 'خط کسب‌وکار';
																|it = 'Settore di attività';
																|pl = 'Rodzaj działalności';
																|tr = 'İş kolu'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInPriceOfSupplier Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Dạng giá nhà cung cấp';
																|ru = 'Вид цены поставщика';
																|en = 'Vendor price type'; fa = 'نوع قیمت تأمین‌کننده';
																|it = 'Tipo di prezzo del fornitore';
																|pl = 'Rodzaj cen dostawcy';
																|tr = 'Tedarikçi fiyat türü'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	
	If SelectionHeaderDetails.ThereAreDifferencesInAcceptanceOfGoods Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Phương án nhập hàng';
																|ru = 'Вариант приемки товаров';
																|en = 'Goods receipt option'; fa = 'گزینه رسید کالا';
																|it = 'Opzione di accettazione della merce';
																|pl = 'Wariant przyjęcia towarów';
																|tr = 'Mal girişi seçeneği'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInFinancialAccounting Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Nhóm kế toán tài chính';
																|ru = 'Группа финансового учета';
																|en = 'Financial accounting group'; fa = 'گروه حسابداری مالی';
																|it = 'Gruppo di contabilità finanziaria';
																|pl = 'Grupa ewidencji finansowej';
																|tr = 'Finansal muhasebe grubu'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesBankAccount Then
	
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Tài khoản ngân hàng';
																|ru = 'Банковский счет';
																|en = 'Bank account'; fa = 'حساب بانکی';
																|it = 'Conto corrente bancario';
																|pl = 'Rachunek bankowy';
																|tr = 'Banka hesabı'")),
			,
			,
			,
			Cancel);
	
	EndIf;
		
	If SelectionHeaderDetails.ThereAreDifferencesInFormOfPayment Then
	
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Hình thức thanh toán';
																|ru = 'Форма оплаты';
																|en = 'Payment method'; fa = 'روش پرداخت';
																|it = 'Modalità di pagamento';
																|pl = 'Forma płatności';
																|tr = 'Ödeme formu'")),
			,
			,
			,
			Cancel);
	
	EndIf;
		
	If SelectionHeaderDetails.ThereAreDifferencesPaymentInCurrency Then
	
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thanh toán bằng tiền';
																|ru = 'Оплата в валюте';
																|en = 'Payment in currency'; fa = 'پرداخت ارزی';
																|it = 'Pagamento in valuta';
																|pl = 'Płatność w walucie';
																|tr = 'Para birimindeki ödeme'")),
			,
			,
			,
			Cancel);
	
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesOfOperationWithSelfEmployed Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giao dịch với cá nhân kinh doanh';
																|ru = 'Операция с самозанятым';
																|en = 'Operation with self-employed person'; fa = 'عملیات با شخص خوداشتغال';
																|it = 'Операция с самозанятым';
																|pl = 'Operation with self-employed person';
																|tr = 'Serbest meslek erbabı işlemi'")), , , , Cancel);
		
	EndIf;
	
	If Cancel Then
		
		ErrorText = NStr("vi = 'Không thể nhập một chứng từ ""%DocumentSynonym%"" dựa trên các đơn đặt hàng này';
						|ru = 'Ввод одного документа ""%DocumentSynonym%"" на основании указанных распоряжений невозможен';
						|en = 'Cannot generate one document ""%DocumentSynonym%"" based on the selected references'; fa = 'Cannot generate one document ""%DocumentSynonym%"" based on the selected references';
						|it = 'Impossibile inserire un documento  ""%DocumentSynonym%"" sulla base delle disposizioni evidenziate';
						|pl = 'Wprowadzenie jednego dokumentu ""%DocumentSynonym%"" na podstawie podanych zamówień nie jest możliwe';
						|tr = 'Belirtilen siparişlere göre tek bir belgeye ""%DocumentSynonym%"" girilmesi mümkün değil'");
		ErrorText = StrReplace(ErrorText, "%DocumentSynonym%", Metadata.Documents[DocumentName].Synonym);
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			,
			,
			Cancel);
		
	Else
		
		While SampleOrders.Next() Do
		
			If SampleOrders.ThereAreErrorsPosted Then
				
				ErrorText = NStr("vi = 'Chưa kết chuyển chứng từ %Document%. Nhập chứng từ theo một đơn đặt hàng chưa kết chuyển bị cấm.';
								|ru = 'Документ %Document% не проведен. Ввод документа по непроведенному распоряжению запрещен.';
								|en = 'Document %Document% is not posted. Entering a document under an unposted reference is not allowed.'; fa = 'Document %Document% is not posted. Entering a document under an unposted reference is not allowed.';
								|it = 'Documento %Document% non è registrato. è vietato inserire il documento in base alla disposizione non registrata.';
								|pl = 'Dokument %Document% nie został zatwierdzony. Wprowadzanie dokumentu według niezatwierdzonego zamówienia jest zabronione.';
								|tr = 'Belge %Document% kaydedilmedi. Planlanmamış bir sırada bir belgenin girilmesi yasaktır.'");
				ErrorText = StrReplace(ErrorText, "%Document%", SampleOrders.PurchaseOrder);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					SampleOrders.PurchaseOrder,
					,
					,
					Cancel);
				
			ElsIf SampleOrders.ThereAreErrorsStatus Then
				
				ErrorText = NStr("vi = 'Chứng từ %Document% ở trạng thái ""%Status%"". Thứ tự chỉ nên ở trạng thái';
								|ru = 'Документ %Document% находится в статусе ""%Status%"". Распоряжение должно быть только в статусах';
								|en = 'Document %Document% is in the status ""%Status%"". The reference should be only in statuses'; fa = 'Document %Document% is in the status ""%Status%"". The reference should be only in statuses';
								|it = 'Il documento %Document% è nello stato ""%Status%"". La disposizione deve avere esclusivamente gli stati';
								|pl = 'Dokument  %Document% jest w statusie ""%Status%"". Zamówienie powinno być tylko w statusach';
								|tr = 'Belge %Document%, ""%Status%"" durumunda. Sipariş yalnızca durumlarda olmalıdır'") + " ";
				
				For Cnt = 1 To 3 Do
					
					AcceptableStatus = SampleOrders["AcceptableStatus" + Cnt];
					If ValueIsFilled(AcceptableStatus) Then
						ErrorText = ErrorText + """" + AcceptableStatus + """, "
					EndIf;
					
				EndDo;
				
				ErrorText = Left(ErrorText, StrLen(ErrorText) - 2); // Trim the last comma
				ErrorText = ErrorText + ".";
				
				ErrorText = StrReplace(ErrorText, "%Document%", SampleOrders.PurchaseOrder);
				ErrorText = StrReplace(ErrorText, "%Status%",   SampleOrders.Status);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					SampleOrders.PurchaseOrder,
					,
					,
					Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Cancel;
	
EndFunction

// Creates a structure for creating receipts for one or more orders
// If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
// 		ReferencesArrray   - Array - orders to suppliers for which you need to enter a receipt
// 		DocumentName   - String - name of the document created based on the order in the metadata
// 		HeaderAttributes - Structure - structure where the header details from the order array will be placed
//
// Returns:
// 		Boolean - False if the details of the header differ in the transferred orders.
//
Function GenerateReceiptFillingData(ReferencesArrray, DocumentName, HeaderAttributes) Export
	
	Query = New Query;
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	ValidOperations = TMCommonUse.PermissibleBusinessOperationsOfDocument(DocumentName);
	Query.SetParameter("ValidOperations", ValidOperations);
	Query.SetParameter("UseLocal", GetFunctionalOption("UseLocal"));
	Query.SetParameter("UseReceiptForMultipleOrders",GetFunctionalOption("UseReceiptForMultipleOrders"));
	
	Query.Text = QueryTextByOrders();
		
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch(); 
	SetPrivilegedMode(False);
	SampleOrders = QueryResult[QueryResult.UBound()].Select();
	
	ExcludedOrders = New Array;
	FetchingOrdersWithInvalidOperation = QueryResult[QueryResult.UBound() - 2].Select();
	
	While FetchingOrdersWithInvalidOperation.Next() Do
		
		If ReferencesArrray.Count() > 1 Then
			MessageText = NStr("vi = 'Đơn hàng %ReferenceOrder% bị bỏ qua vì không thể thực thi chứng từ ""%DocumentSynonym%"" trên cơ sở đơn hàng với giao dịch ""%BusinessOperation%"".';
								|ru = 'Распоряжение %ReferenceOrder% пропущено, т.к. невозможно оформить документ ""%DocumentSynonym%"" на основании распоряжения с операцией ""%BusinessOperation%"".';
								|en = 'The %ReferenceOrder% reference is skipped as you cannot generate the ""%DocumentSynonym%"" document based on the reference with the ""%BusinessOperation%"" operation.'; fa = 'The %ReferenceOrder% reference is skipped as you cannot generate the ""%DocumentSynonym%"" document based on the reference with the ""%BusinessOperation%"" operation.';
								|it = 'Il riferimento  %ReferenceOrder% è mancante, poiché non è possibile formalizzare il documento ""%DocumentSynonym%"" sulla base del referimento con operazione ""%BusinessOperation%"".';
								|pl = 'Zamówienie %ReferenceOrder% jest przepuszczone, ponieważ niemożliwe jest sporządzenie dokumentu ""%DocumentSynonym%"" na podstawie zamówienia z operacją ""%BusinessOperation%"".';
								|tr = 'Sipariş %ReferenceOrder% atlandı çünkü ""%BusinessOperation%"" işlemi ile siparişe göre ""%DocumentSynonym%"" belgesini düzenlemek mümkün değil.'");
			MessageText = StrReplace(MessageText, "%ReferenceOrder%", FetchingOrdersWithInvalidOperation.PurchaseOrder);
		Else
			MessageText = NStr("vi = 'Không thể thực thi chứng từ ""%DocumentSynonym%"" trên cơ sở đơn đặt hàng với thao tác ""%BusinessOperation%"".';
								|ru = 'Невозможно оформить документ ""%DocumentSynonym%"" на основании распоряжения с операцией ""%BusinessOperation%"".';
								|en = 'Cannot register the ""%DocumentSynonym%"" document based on the reference with the ""%BusinessOperation%"" operation.'; fa = 'Cannot register the ""%DocumentSynonym%"" document based on the reference with the ""%BusinessOperation%"" operation.';
								|it = 'Non è possibile formalizzare il documento %DocumentSynonym%"" sulla base del referimento con operazione ""%BusinessOperation%"".';
								|pl = 'Niemożliwe jest sporządzenie dokumentu ""%DocumentSynonym%"" na podstawie zamówienia z operacją ""%BusinessOperation%"".';
								|tr = '""%DocumentSynonym%"" belgesini ""%BusinessOperation%"" işlemiyle siparişe göre düzenlemek mümkün değil.'");
		EndIf;
		
		MessageText = StrReplace(MessageText, "%DocumentSynonym%", Metadata.Documents[DocumentName].Synonym);
		MessageText = StrReplace(MessageText, "%BusinessOperation%", FetchingOrdersWithInvalidOperation.BusinessOperation);
		CommonClientServer.MessageToUser(MessageText,FetchingOrdersWithInvalidOperation.PurchaseOrder);
		
		ExcludedOrders.Add(FetchingOrdersWithInvalidOperation.PurchaseOrder);
	EndDo;
	
	If FetchingOrdersWithInvalidOperation.Count() = ReferencesArrray.Count() Then
		Return False;
	EndIf;
	
	ReferencesArrray = CommonClientServer.ReduceArray(ReferencesArrray, ExcludedOrders);
	
	SelectionHeaderDetails = QueryResult[QueryResult.UBound() - 1].Select();
	SelectionHeaderDetails.Next();
	
	Cancel = False;
	
	MessageText = NStr("vi = 'Trong các lệnh đã chọn có khác biệt tại trường ""%FieldPresentation%""';
						|ru = 'У выделенных распоряжений отличается поле ""%FieldPresentation%""';
						|en = 'The ""%FieldPresentation%"" field of the selected references differs.'; fa = 'The ""%FieldPresentation%"" field of the selected references differs.';
						|it = 'Nei riferimenti evidenziati il campo ""%FieldPresentation%"" differisce';
						|pl = 'W zaznaczonych zamówieniach różni się pole ""%FieldPresentation%""';
						|tr = 'Seçilen siparişler farklı bir alana sahip ""%FieldPresentation%""'");
	
	If SelectionHeaderDetails.ThereAreDifferencesDepartment Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Bộ phận';
																|ru = 'Подразделение';
																|en = 'Business unit'; fa = 'Business unit';
																|it = 'Reparto';
																|pl = 'Dział';
																|tr = 'Departman'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesPartner Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Bạn hàng';
																|ru = 'Партнер';
																|en = 'Partner'; fa = 'شریک تجاری';
																|it = 'Partner';
																|pl = 'Partner';
																|tr = 'İş ortağı'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesCounterparty Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Controparte';
																|pl = 'Kontrahent';
																|tr = 'Cari hesap'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesCompany Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Doanh nghiệp';
																|ru = 'Организация';
																|en = 'Company'; fa = 'Company';
																|it = 'Azienda';
																|pl = 'Firma';
																|tr = 'İş yeri'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesAgreement Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thỏa thuận';
																|ru = 'Соглашение';
																|en = 'Agreement'; fa = 'توافق‌نامه';
																|it = 'Accordo';
																|pl = 'Porozumienie';
																|tr = 'Anlaşma'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesContract Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Hợp đồng';
																|ru = 'Договор';
																|en = 'Contract'; fa = 'قرارداد';
																|it = 'Contratto';
																|pl = 'Contract';
																|tr = 'Sözleşme'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesWarehouse Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Kho bãi';
																|ru = 'Склад';
																|en = 'Warehouse'; fa = 'Warehouse';
																|it = 'Magazzino';
																|pl = 'Magazyn';
																|tr = 'Ambar'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesEconomicOperation Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giao dịch';
																|ru = 'Операция';
																|en = 'Transaction'; fa = 'تراکنش';
																|it = 'Operazione';
																|pl = 'Transaction';
																|tr = 'İşlem'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInCurrencyOfMutualSettlements Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Tiền tệ hạch toán công nợ';
																|ru = 'Валюта взаиморасчетов';
																|en = 'AR/AP currency'; fa = 'ارز دریافتنی/پرداختنی';
																|it = 'Valuta di regolamento dei conti';
																|pl = 'Waluta rozliczeń wzajemnych';
																|tr = 'Alacak/Borç muhasebesi para birimi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesVATTaxation Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Chịu thuế GTGT';
																|ru = 'Налогообложение НДС';
																|en = 'VAT taxation'; fa = 'مشمولیت مالیات بر ارزش افزوده';
																|it = 'Tassazione IVA';
																|pl = 'Opodatkowanie VAT';
																|tr = 'KDV vergilendirilmesi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesPurchasingForActivities Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Mua hàng trong mảng hoạt động';
																|ru = 'Закупка под деятельность';
																|en = 'Purchase for activity'; fa = 'خرید برای فعالیت';
																|it = 'Acquisto per attività';
																|pl = 'Zakup w ramach działalności';
																|tr = 'Faaliyet kapsamında satın alma'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesPriceIncludesVAT Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giá gồm thuế GTGT';
																|ru = 'Цена включает НДС';
																|en = 'Price includes VAT'; fa = 'قیمت شامل مالیات بر ارزش افزوده است';
																|it = 'Il prezzo include l''IVA';
																|pl = 'Cena zawiera VAT';
																|tr = 'Fiyata KDV dahildir'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInMultiTurnContainers Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Trả lại bao bì luân chuyển';
																|ru = 'Вернуть многооборотную тару';
																|en = 'Return reusable packaging'; fa = 'برگشت بسته‌بندی قابل استفاده مجدد';
																|it = 'Restituire l''imballaggio riutilizzabile';
																|pl = 'Zwrócić tarę wielokrotnego użytku';
																|tr = 'Yeniden kullanılabilir ambalajı iade et'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInReturnPeriodOfMultiTurnContainers Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thời hạn trả lại bao bì luân chuyển';
																|ru = 'Срок возврата многооборотной тары';
																|en = 'Reusable packaging return date'; fa = 'تاریخ بازگشت بسته‌بندی قابل استفاده مجدد';
																|it = 'Periodo di reso dell''imballaggio riutilizzabile';
																|pl = 'Termin zwrotu tary wielokrotnego użytku';
																|tr = 'Yeniden kullanılabilir ambalajın iade süresi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesDepositForContainerIsRequired Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Cần ký cược bao bì';
																|ru = 'Требуется залог за тару';
																|en = 'Packaging deposit is required'; fa = 'ودیعه بسته‌بندی لازم است';
																|it = 'È prevista la cauzione per l''imballaggio';
																|pl = 'Jest wymagana kaucja za tarę';
																|tr = 'Depozito gerekli'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInOrderOfCalculations Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Quy trình thanh toán';
																|ru = 'Порядок расчетов';
																|en = 'Payment terms'; fa = 'شرایط پرداخت';
																|it = 'Modalità di regolamenti';
																|pl = 'Sposób rozliczeń';
																|tr = 'Ödeme şartları'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInDirectionOfActivity_ Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Lĩnh vực hoạt động';
																|ru = 'Направление деятельности';
																|en = 'Line of business'; fa = 'خط کسب‌وکار';
																|it = 'Settore di attività';
																|pl = 'Rodzaj działalności';
																|tr = 'İş kolu'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInPriceOfSupplier Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Dạng giá nhà cung cấp';
																|ru = 'Вид цены поставщика';
																|en = 'Vendor price type'; fa = 'نوع قیمت تأمین‌کننده';
																|it = 'Tipo di prezzo del fornitore';
																|pl = 'Rodzaj cen dostawcy';
																|tr = 'Tedarikçi fiyat türü'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	
	If SelectionHeaderDetails.ThereAreDifferencesInAcceptanceOfGoods Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Phương án nhập hàng';
																|ru = 'Вариант приемки товаров';
																|en = 'Goods receipt option'; fa = 'گزینه رسید کالا';
																|it = 'Opzione di accettazione della merce';
																|pl = 'Wariant przyjęcia towarów';
																|tr = 'Mal girişi seçeneği'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesBankAccount Then
	
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Tài khoản ngân hàng';
																|ru = 'Банковский счет';
																|en = 'Bank account'; fa = 'حساب بانکی';
																|it = 'Conto corrente bancario';
																|pl = 'Rachunek bankowy';
																|tr = 'Banka hesabı'")),
			,
			,
			,
			Cancel);
	
	EndIf;
		
	If SelectionHeaderDetails.ThereAreDifferencesInFormOfPayment Then
	
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Hình thức thanh toán';
																|ru = 'Форма оплаты';
																|en = 'Payment method'; fa = 'روش پرداخت';
																|it = 'Modalità di pagamento';
																|pl = 'Forma płatności';
																|tr = 'Ödeme formu'")),
			,
			,
			,
			Cancel);
	
	EndIf;
		
	If SelectionHeaderDetails.ThereAreDifferencesPaymentInCurrency Then
	
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thanh toán bằng tiền';
																|ru = 'Оплата в валюте';
																|en = 'Payment in currency'; fa = 'پرداخت ارزی';
																|it = 'Pagamento in valuta';
																|pl = 'Płatność w walucie';
																|tr = 'Para birimindeki ödeme'")),
			,
			,
			,
			Cancel);
	
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesOfOperationWithSelfEmployed Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giao dịch với cá nhân kinh doanh';
																|ru = 'Операция с самозанятым';
																|en = 'Operation with self-employed person'; fa = 'عملیات با شخص خوداشتغال';
																|it = 'Операция с самозанятым';
																|pl = 'Operation with self-employed person';
																|tr = 'Serbest meslek erbabı işlemi'")), , , , Cancel);
		
	EndIf;
	
	If Cancel Then
		
		ErrorText = NStr("vi = 'Không thể nhập một chứng từ ""%DocumentSynonym%"" dựa trên các đơn đặt hàng được phân bổ';
						|ru = 'Ввод одного документа ""%DocumentSynonym%"" на основании выделенных распоряжений невозможен';
						|en = 'Cannot generate one document ""%DocumentSynonym%"" based on the selected references'; fa = 'Cannot generate one document ""%DocumentSynonym%"" based on the selected references';
						|it = 'Impossibile inserire un documento  ""%DocumentSynonym%"" sulla base dei riferimenti evidenziati';
						|pl = 'Wprowadzanie dokumentu ""%DocumentSynonym%"" na podstawie zaznaczonych zamówień jest niemożliwe';
						|tr = 'Seçilen siparişlere göre tek bir belge ""%DocumentSynonym%"" olarak girilemiyor'");
		ErrorText = StrReplace(ErrorText, "%DocumentSynonym%", Metadata.Documents[DocumentName].Synonym);
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			,
			,
			Cancel);
		
	Else
		
		While SampleOrders.Next() Do
		
			If SampleOrders.ThereAreErrorsPosted Then
				
				ErrorText = NStr("vi = 'Chưa kết chuyển chứng từ %Document%. Việc nhập trên cơ sở chứng từ chưa kết chuyển bị cấm.';
								|ru = 'Документ %Document% не проведен. Ввод на основании непроведенного документа запрещен.';
								|en = 'Document %Document% is not posted. Generation from unposted documents is not allowed.'; fa = 'Document %Document% is not posted. Generation from unposted documents is not allowed.';
								|it = 'Il documento %Document% non è stato registrato. L''immissione in base al documento non registrato è proibita.';
								|pl = 'Dokument %Document% nie jest zaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
								|tr = '%Document% belgesi kaydedilmedi. Kaydedilmemiş belgeye dayalı giriş yasaktır.'");
				ErrorText = StrReplace(ErrorText, "%Document%", SampleOrders.PurchaseOrder);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					SampleOrders.PurchaseOrder,
					,
					,
					Cancel);
				
			ElsIf SampleOrders.ThereAreErrorsStatus Then
				
				ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"". Chỉ cho phép nhập trên cơ sở với trạng thái';
								|ru = 'Документ %Document% находится в статусе ""%Status%"". Ввод на основании разрешен только в статусах';
								|en = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in statuses'; fa = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in statuses';
								|it = 'Il documento  %Document% si trova nello stato  ""%Status%"". L''inserimento sulla base è possibile solamente negli stati';
								|pl = 'Dokument %Document% ma status ""%Status%"". Wprowadzenie na podstawie jest dozwolone tylko przy statusach';
								|tr = 'Belge %Document%, ""%Status%"" durumundadır. Gerekçeye dayalı girişe yalnızca durumlarında izin verilir'") + " ";
				
				For Cnt = 1 To 3 Do
					
					AcceptableStatus = SampleOrders["AcceptableStatus" + Cnt];
					If ValueIsFilled(AcceptableStatus) Then
						ErrorText = ErrorText + """" + AcceptableStatus + """, "
					EndIf;
					
				EndDo;
				
				ErrorText = Left(ErrorText, StrLen(ErrorText) - 2); // Trim the last comma
				ErrorText = ErrorText + ".";
				
				ErrorText = StrReplace(ErrorText, "%Document%", SampleOrders.PurchaseOrder);
				ErrorText = StrReplace(ErrorText, "%Status%",   SampleOrders.Status);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					SampleOrders.PurchaseOrder,
					,
					,
					Cancel);
				
			EndIf;
			
		EndDo;
		
		HeaderAttributes.Insert("Department",                           SelectionHeaderDetails.Department);
		HeaderAttributes.Insert("Partner",                                 SelectionHeaderDetails.Partner);
		HeaderAttributes.Insert("Counterparty",                              SelectionHeaderDetails.Counterparty);
		HeaderAttributes.Insert("Contract",                                 SelectionHeaderDetails.Contract);
		HeaderAttributes.Insert("Organization",                             SelectionHeaderDetails.Organization);
		HeaderAttributes.Insert("Warehouse",                                   SelectionHeaderDetails.Warehouse);
		HeaderAttributes.Insert("Terms",                              SelectionHeaderDetails.Terms);
		HeaderAttributes.Insert("BusinessOperation",                   SelectionHeaderDetails.BusinessOperation);
		HeaderAttributes.Insert("ARAPCurrency",                    SelectionHeaderDetails.ARAPCurrency);
		HeaderAttributes.Insert("Currency",                                  SelectionHeaderDetails.ARAPCurrency);
		HeaderAttributes.Insert("VATTaxation",                      SelectionHeaderDetails.VATTaxation);
		HeaderAttributes.Insert("PurchaseForActivity",                  SelectionHeaderDetails.PurchaseForActivity);
		HeaderAttributes.Insert("PriceIncludesVAT",                         SelectionHeaderDetails.PriceIncludesVAT);
		HeaderAttributes.Insert("ARAPObjectSettings",                         SelectionHeaderDetails.ARAPObjectSettings);
		HeaderAttributes.Insert("ToReturnReusablePackage",               SelectionHeaderDetails.ToReturnReusablePackage);
		HeaderAttributes.Insert("CalculatePackageReturnDateAccordingToCalendar", SelectionHeaderDetails.CalculatePackageReturnDateAccordingToCalendar);
		HeaderAttributes.Insert("ScheduleOfPackageReturn",                   SelectionHeaderDetails.ScheduleOfPackageReturn);
		HeaderAttributes.Insert("ReusablePackageReturnCycleLength",          SelectionHeaderDetails.ReusablePackageReturnCycleLength);
		HeaderAttributes.Insert("WarehouseForReceipt",                        SelectionHeaderDetails.WarehouseForReceipt);
		HeaderAttributes.Insert("ItIsForbiddenToSelectWarehouseGroup",          SelectionHeaderDetails.ItIsForbiddenToSelectWarehouseGroup);
		HeaderAttributes.Insert("LineOfBusiness",                 SelectionHeaderDetails.LineOfBusiness);
		HeaderAttributes.Insert("VendorPriceKind",                       SelectionHeaderDetails.VendorPriceKind);
		HeaderAttributes.Insert("FinancialAccountingGroup",                  SelectionHeaderDetails.FinancialAccountingGroup);
		HeaderAttributes.Insert("PackageDepositIsRequired",                    SelectionHeaderDetails.PackageDepositIsRequired);
		HeaderAttributes.Insert("RegisterVendorPrices",            SelectionHeaderDetails.RegisterVendorPrices);
		HeaderAttributes.Insert("PaymentMethod",                             SelectionHeaderDetails.PaymentMethod);
		HeaderAttributes.Insert("CompanyBankAccount",               SelectionHeaderDetails.BankAccount);
		HeaderAttributes.Insert("OperationWithSelfEmployedPerson",                    SelectionHeaderDetails.OperationWithSelfEmployedPerson);
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// The procedure fills in the Bank account of the contract document.
//
// Parameters:
//		Contract - CatalogRef.CounterpartyContracts - Contract;
//		CompanyBankAccount - CatalogRef.CompaniesBankAccounts - Organization's Bank account;
//		CounterpartyBankAccount - CatalogRef.CounterpartyBankAccounts - Counterparty's Bank account.
//
Procedure FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount = Undefined, CounterpartyBankAccount = Undefined) Export
	
	If ValueIsFilled(Contract) Then
		Catalogs.CounterpartyContracts.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
	EndIf;
	
EndProcedure

// Returns the number of agreements with the specified provider
//
// Parameters:
//  Partner           - CatalogRef.Partners - the partner to get the number of agreements for.
//  FilterParameters   - Structure - structure with parameters for selecting agreements.
//
// Returns:
//  Structure - a structure that includes the terms of purchase.
//
Function GetNumberOfAgreementsWithSupplier(Val Partner,
	                                      Val FilterParameters = Undefined) Export
	
	AllSelectionParameters = New Structure();
	AllSelectionParameters.Insert("ForPurchaseOnly",                        True);
	AllSelectionParameters.Insert("OnlyValid",                       True);
	AllSelectionParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", False);
	AllSelectionParameters.Insert("BusinessTransactions",                   Undefined);
	
	If FilterParameters <> Undefined Then
		FillPropertyValues(AllSelectionParameters, FilterParameters);
	EndIf;
	
	ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingOutSupplierAgreements();
	ActionParameters.OnlyValid = AllSelectionParameters.OnlyValid;
	ActionParameters.BusinessOperation = AllSelectionParameters.BusinessTransactions;
	
	RowData = New Structure;
	RowData.Insert("Partner",              Partner);
	RowData.Insert("NumberOfAgreements", 0);
	
	Actions = New Structure;
	Actions.Insert("FillInNumberOfSupplierAgreements", ActionParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(
		RowData,
		Actions,
		BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues());
	
	Return RowData.NumberOfAgreements;
	
EndFunction // Get the quantity of the agreement by the supplier()

// Get the terms of purchase.
// 
// Parameters:
//  Terms - CatalogRef.TermsOfPurchaseFromVendors - the agreement is subject to standard
//                                                          terms and conditions of purchase.
//  ConsiderWarehouseGroups - Boolean - Consider warehouse groups
//  ExcludeWarehouseGroupsAvailableInOrders - Boolean - Exclude warehouse groups available in orders
// 
// Returns:
//  Structure - a structure that includes the terms of purchase.
Function GetPurchaseTermsAndConditions(Val Terms,Val ConsiderWarehouseGroups = False, Val ExcludeWarehouseGroupsAvailableInOrders = False) Export
	Return PurchasesServer.GetPurchaseTermsAndConditions(Terms,
		ConsiderWarehouseGroups, 
		ExcludeWarehouseGroupsAvailableInOrders);
EndFunction

// Returns an array of households. operations - transferred utility. operation and operations for use in the "Goods in transit"
// and "non-Invoiced deliveries" schemes.
//
// Parameters:
//  BasicEconomicOperation	 - EnumRef.BusinessTransactions	 - the main business operation.
// 
// Returns:
//  Array - array of business operations including the main one.
//
Function BusinessOperationsOnMain(BasicEconomicOperation) Export
	
	Return PurchasesServer.BusinessOperationsOnMain(BasicEconomicOperation);
	
EndFunction

#Region ProceduresAndFunctionsOfWorkingWithCCDNumbers

// Generates a list of the values of the CCD Product numbers, characteristics.
//
// Parameters:
//	Products - CatalogRef.Products - range of the company for the selection of the numbers of GTE.
//	Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the company's nomenclature
//																	for selecting GTD numbers.
//	OriginCountry - CatalogRef.WorldCountries - country, for the selection of the numbers of GTE.
//
// Returns:
//	ValueList of Structure - a list of a collection of CCD room properties with the following properties:
//		* Value - CatalogRef.CCDNumbers - the number of CCD.
//		* DeletionMark - Boolean - indicates whether the CCD number has been marked for deletion.
//
Function FillInListOfCCDNumberSelection(Products, Characteristic, OriginCountry) Export
	
	ChoiceList = New ValueList;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 100
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.CCDNumber,
	|	PurchaseOfGoodsServicesGoods.Ref,
	|	PurchaseOfGoodsServicesGoods.Ref.Date AS Date
	|INTO GeneralProductsOfCCD
	|FROM
	|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|WHERE
	|	PurchaseOfGoodsServicesGoods.Products = &Products
	|	AND PurchaseOfGoodsServicesGoods.Characteristic = &Characteristic
	|	AND PurchaseOfGoodsServicesGoods.Ref.Posted
	|	AND PurchaseOfGoodsServicesGoods.CCDNumber <> &CCDNumber
	|
	|UNION ALL
	|
	|SELECT TOP 100
	|	InventorySurplusRecognitionGoods.Products,
	|	InventorySurplusRecognitionGoods.Characteristic,
	|	InventorySurplusRecognitionGoods.CCDNumber,
	|	InventorySurplusRecognitionGoods.Ref,
	|	InventorySurplusRecognitionGoods.Ref.Date
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS InventorySurplusRecognitionGoods
	|WHERE
	|	InventorySurplusRecognitionGoods.Products = &Products
	|	AND InventorySurplusRecognitionGoods.Characteristic = &Characteristic
	|	AND InventorySurplusRecognitionGoods.Ref.Posted
	|	AND InventorySurplusRecognitionGoods.CCDNumber <> &CCDNumber
	|
	|UNION ALL
	|
	|SELECT TOP 100
	|	AdjustmentOfAcquisitionOfGoods.Products,
	|	AdjustmentOfAcquisitionOfGoods.Characteristic,
	|	AdjustmentOfAcquisitionOfGoods.CCDNumber,
	|	AdjustmentOfAcquisitionOfGoods.Ref,
	|	AdjustmentOfAcquisitionOfGoods.Ref.Date
	|FROM
	|	Document.PurchaseAdjustment.Goods AS AdjustmentOfAcquisitionOfGoods
	|WHERE
	|	AdjustmentOfAcquisitionOfGoods.Products = &Products
	|	AND AdjustmentOfAcquisitionOfGoods.Characteristic = &Characteristic
	|	AND AdjustmentOfAcquisitionOfGoods.Ref.Posted
	|	AND AdjustmentOfAcquisitionOfGoods.CCDNumber <> &CCDNumber
	|
	|UNION ALL
	|
	|SELECT TOP 100
	|	GoodsMisgradingGoods.Products,
	|	GoodsMisgradingGoods.Characteristic,
	|	GoodsMisgradingGoods.CCDNumber,
	|	GoodsMisgradingGoods.Ref,
	|	GoodsMisgradingGoods.Ref.Date
	|FROM
	|	Document.GoodsMisgrading.Goods AS GoodsMisgradingGoods
	|WHERE
	|	GoodsMisgradingGoods.Products = &Products
	|	AND GoodsMisgradingGoods.Characteristic = &Characteristic
	|	AND GoodsMisgradingGoods.Ref.Posted
	|	AND GoodsMisgradingGoods.CCDNumber <> &CCDNumber
	|
	|UNION ALL
	|
	|SELECT TOP 100
	|	CustomsDeclarationImportGoods.Products,
	|	CustomsDeclarationImportGoods.Characteristic,
	|	CustomsDeclarationImportGoods.CCDNumber,
	|	CustomsDeclarationImportGoods.Ref,
	|	CustomsDeclarationImportGoods.Ref.Date
	|FROM
	|	Document.CCDImport.Goods AS CustomsDeclarationImportGoods
	|WHERE
	|	CustomsDeclarationImportGoods.Products = &Products
	|	AND CustomsDeclarationImportGoods.Characteristic = &Characteristic
	|	AND CustomsDeclarationImportGoods.Ref.Posted
	|	AND CustomsDeclarationImportGoods.CCDNumber <> &CCDNumber
	|
	|ORDER BY
	|	Date DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 10
	|	CatalogData.Ref AS Ref,
	|	CatalogData.Presentation AS Presentation,
	|	CatalogData.DeletionMark AS DeletionMark,
	|	CatalogData.OriginCountry.Presentation AS CountryPresentation,
	|	MAX(GeneralProductsOfCCD.Date) AS Order
	|FROM
	|	GeneralProductsOfCCD AS GeneralProductsOfCCD
	|		INNER JOIN Catalog.CCDNumbers AS CatalogData
	|		ON GeneralProductsOfCCD.CCDNumber = CatalogData.Ref
	|WHERE
	|	(NOT &SelectionByCountry
	|		OR CatalogData.OriginCountry = &Country)
	|
	|GROUP BY
	|	CatalogData.Ref,
	|	CatalogData.Presentation,
	|	CatalogData.DeletionMark,
	|	CatalogData.OriginCountry.Presentation
	|
	|ORDER BY
	|	Order DESC";
	
	Query.SetParameter("Products",	Products);
	Query.SetParameter("Characteristic",	Characteristic);
	Query.SetParameter("SelectionByCountry",	ValueIsFilled(OriginCountry));
	Query.SetParameter("Country",			OriginCountry);
	Query.SetParameter("CCDNumber",		Catalogs.CCDNumbers.EmptyRef());
	
	SetPrivilegedMode(True);
	SamplingOfCCD = Query.Execute().Select();
	
	While SamplingOfCCD.Next() Do
		ChoiceItem = New Structure("Value, DeletionMark",
										SamplingOfCCD.Ref, SamplingOfCCD.DeletionMark);
		Presentation = TrimAll(SamplingOfCCD.Presentation)
								+ ?(ValueIsFilled(SamplingOfCCD.CountryPresentation),
								" (" + SamplingOfCCD.CountryPresentation + ")", "");
		
		ChoiceList.Add(ChoiceItem, Presentation);
	EndDo;
	
	Return ChoiceList;
	
EndFunction

// Generates a representation for the elements of the Catalog 'GTD number' with the value of the RPT type of the set.
//
// Parameters:
//	Data - Structure- a collection containing the values of the fields from which the view is formed.
//	Presentation - String- the string to put the representation of the object or link in.
//	StandardProcessing -Boolean - this parameter is passed a sign of forming a standard representation of the object
//									or link. If you set this parameter
//									to False in the body of the handler procedure, the standard event processing will not be performed.
//
Procedure CCDNumbersProcessingReceiptOfSubmission(Data, Presentation, StandardProcessing) Export
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Date(1, 1, 1));
	
	If Not UseTraceableImportedGoodsAccounting Then
		Return;
	Else
		StandardProcessing = False;
		If Data.NumberOfComponents_ > 1 Then
			TemplateOfPresentation = NStr("vi = '%1 và %2 số đăng ký lô hàng trong bộ đóng gói';
											|ru = '%1 и еще %2 РНПТ в комплекте';
											|en = '%1 and also %2 RNPT in a kit'; fa = '%1 and also %2 RNPT in a kit';
											|it = '%1 и еще %2 РНПТ в комплекте';
											|pl = '%1 and also %2 RNPT in a kit';
											|tr = '%1 ve %2 RNPT sette'");
			NumberOfComponents_ = Data.NumberOfComponents_ - 1;			
			Presentation = StrTemplate(TemplateOfPresentation, TrimAll(Data.Code), String(NumberOfComponents_));
		Else
			TemplateOfPresentation = NStr("vi = '%1 số đăng ký lô hàng trong bộ đóng gói';
											|ru = '%1 РНПТ в комплекте';
											|en = '%1 RNPT in a kit'; fa = '%1 RNPT in a kit';
											|it = '%1 РНПТ в комплекте';
											|pl = '%1 RNPT in a kit';
											|tr = '%1 RNPT sette'");
			Presentation = StrTemplate(TemplateOfPresentation, TrimAll(Data.Code));			
		EndIf;
	EndIf;
	
EndProcedure

// Generates a selection list for the Catalog 'GTD Number' field.
//
// Parameters:
//	ChoiceData - ValueList of Structure - a list of Catalog item data selections.
//	Parameters - Structure - settings for processing receiving data for selecting Catalog items.
//	StandardProcessing -Boolean - this parameter is passed a sign of receiving object selection data.
//									If you set this parameter
//									to False in the body of the handler procedure, the standard event processing will not be performed.
//
Procedure CCDNumbersProcessingReceiptOfSelectionData(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	QueryText = "";
	
	If Parameters.SearchString = Undefined Then
		
		QueryText =
		"SELECT ALLOWED
		|	CatalogData.Ref AS Ref,
		|	CatalogData.Presentation AS Presentation,
		|	CatalogData.DeletionMark AS DeletionMark,
		|	CatalogData.OriginCountry.Presentation AS CountryPresentation
		|FROM
		|	Catalog.CCDNumbers AS CatalogData
		|WHERE
		|	NOT CatalogData.Predefined
		|";
		
	Else
		
		RequestTextsByDocumentType = New Array;
		
		If AccessRight("Read", Metadata.Documents.VendorInvoice) Then
			RequestTextsByDocumentType.Add("
				|SELECT TOP 100
				|	Goods.Products		AS Products,
				|	Goods.Characteristic	AS Characteristic,
				|	Goods.CCDNumber			AS CCDNumber,
				|	Goods.Ref			AS Ref,
				|	Goods.Ref.Date		AS Date
				|FROM
				|	Document.VendorInvoice.Goods AS Goods
				|WHERE
				|	Goods.Products = &Products
				|	AND Goods.Characteristic = &Characteristic
				|	AND Goods.Ref.Posted
				|");
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.PurchaseAdjustment) Then
			RequestTextsByDocumentType.Add("
				|SELECT TOP 100
				|	Goods.Products		AS Products,
				|	Goods.Characteristic	AS Characteristic,
				|	Goods.CCDNumber			AS CCDNumber,
				|	Goods.Ref			AS Ref,
				|	Goods.Ref.Date		AS Date
				|FROM
				|	Document.PurchaseAdjustment.Goods AS Goods
				|WHERE
				|	Goods.Products = &Products
				|	AND Goods.Characteristic = &Characteristic
				|	AND Goods.Ref.Posted
				|");
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.InventorySurplusRecognition) Then
			RequestTextsByDocumentType.Add("
				|SELECT TOP 100
				|	Goods.Products		AS Products,
				|	Goods.Characteristic	AS Characteristic,
				|	Goods.CCDNumber			AS CCDNumber,
				|	Goods.Ref			AS Ref,
				|	Goods.Ref.Date		AS Date
				|FROM
				|	Document.InventorySurplusRecognition.Goods AS Goods
				|WHERE
				|	Goods.Products = &Products
				|	AND Goods.Characteristic = &Characteristic
				|	AND Goods.Ref.Posted
				|");
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.GoodsMisgrading) Then
			RequestTextsByDocumentType.Add("
				|SELECT TOP 100
				|	Goods.Products		AS Products,
				|	Goods.Characteristic	AS Characteristic,
				|	Goods.CCDNumber			AS CCDNumber,
				|	Goods.Ref			AS Ref,
				|	Goods.Ref.Date		AS Date
				|FROM
				|	Document.GoodsMisgrading.Goods AS Goods
				|WHERE
				|	Goods.Products = &Products
				|	AND Goods.Characteristic = &Characteristic
				|	AND Goods.Ref.Posted
				|");
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.CCDImport) Then
			RequestTextsByDocumentType.Add("
				|SELECT TOP 100
				|	Goods.Products		AS Products,
				|	Goods.Characteristic	AS Characteristic,
				|	Goods.CCDNumber			AS CCDNumber,
				|	Goods.Ref			AS Ref,
				|	Goods.Ref.Date		AS Date
				|FROM
				|	Document.CCDImport.Goods AS Goods
				|WHERE
				|	Goods.Products = &Products
				|	AND Goods.Characteristic = &Characteristic
				|	AND Goods.Ref.Posted
				|");
		EndIf;
		
		If RequestTextsByDocumentType.Count() > 0 Then
			
			TextOfNestedRequestForCombinationOfGTDNomenclatureToInsert = "("
			 + StrConcat(RequestTextsByDocumentType, Chars.LF + "UNION ALL" + Chars.LF)
			 + ")";
			
			QueryTextGeneralProductsOfCCD =
				"SELECT ALLOWED TOP 10000
				|	GeneralProductsOfCCD.CCDNumber AS CCDNumber,
				|	GeneralProductsOfCCD.Date AS Date
				|INTO GeneralProductsOfCCD
				|FROM
				|	&TextOfNestedRequestForCombinationOfGTDNomenclatureToInsert AS GeneralProductsOfCCD
				|
				|ORDER BY
				|	Date DESC";
			
			QueryTextGeneralProductsOfCCD = StrReplace(QueryTextGeneralProductsOfCCD,
				"&TextOfNestedRequestForCombinationOfGTDNomenclatureToInsert",
				TextOfNestedRequestForCombinationOfGTDNomenclatureToInsert);
			
			QueryText = QueryTextGeneralProductsOfCCD + "
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT ALLOWED TOP 10
				|	CatalogData.Ref							AS Ref,
				|	CatalogData.Presentation						AS Presentation,
				|	CatalogData.DeletionMark					AS DeletionMark,
				|	CatalogData.OriginCountry.Presentation	AS CountryPresentation,
				|	CatalogData.UnitOfMeasure					AS UnitOfMeasure,
				|	MAX(GeneralProductsOfCCD.Date)				AS Order
				|FROM
				|	Catalog.CCDNumbers AS CatalogData
				|		LEFT JOIN GeneralProductsOfCCD AS GeneralProductsOfCCD
				|		ON (GeneralProductsOfCCD.CCDNumber = CatalogData.Ref)
				|WHERE
				|	CatalogData.Code LIKE &SearchString ESCAPE ""~""
				|	AND (NOT &ExcludeCurrentLink
				|		OR CatalogData.Ref <> &CurrentRef)
				|	AND (NOT &SelectionByCCDRoomType
				|		OR CatalogData.CCDNumberType = &CCDNumberType)
				|	AND (NOT &SelectionByCountry
				|			OR CatalogData.OriginCountry = &Country)
				|	AND (NOT &SelectionAccordingToListOfCCDTypes
				|		OR CatalogData.CCDNumberType IN(&ListOfCCDTypes))
				|
				|GROUP BY
				|	CatalogData.Ref,
				|	CatalogData.Presentation,
				|	CatalogData.DeletionMark,
				|	CatalogData.OriginCountry.Presentation,
				|	CatalogData.UnitOfMeasure
				|
				|ORDER BY
				|	Order DESC";
			
		EndIf;
		
	EndIf;
	
	ChoiceData = New ValueList;
	
	If Not IsBlankString(QueryText) Then
		
		Date				= ?(Parameters.Property("Date"), Parameters.Date, Date(1, 1, 1));
		Products		= ?(Parameters.Property("Products"), Parameters.Products, Undefined);
		Characteristic		= ?(Parameters.Property("Characteristic"), Parameters.Characteristic, Undefined);
		CurrentRef		= ?(Parameters.Filter.Property("CurrentRef"), Parameters.Filter.CurrentRef, Undefined);
		CCDNumberType		= ?(Parameters.Filter.Property("CCDNumberType"), Parameters.Filter.CCDNumberType, Undefined);
		ListOfCCDTypes		= ?(Parameters.Property("ListOfCCDTypes"), Parameters.ListOfCCDTypes, Undefined);
		OriginCountry	= ?(Parameters.Filter.Property("OriginCountry"),
								Parameters.Filter.OriginCountry,
								Undefined);
		
		CreatingElementOfAnyType		= ?(Parameters.Property("CreatingElementOfAnyType"),
											Parameters.CreatingElementOfAnyType,
											False);
		GetAdditionalData	= ?(Parameters.Filter.Property("GetAdditionalData"),
											Parameters.Filter.GetAdditionalData,
											False);
		
		If ValueIsFilled(Products)
			And Not ValueIsFilled(ListOfCCDTypes) Then
			
			If Not AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date) Then
				TracedGoods = False;
			Else
				TracedGoods = Common.ObjectAttributeValue(Products, "TracedGoods");
			EndIf;
			
			If Not (TracedGoods
				And CreatingElementOfAnyType) Then
				
				ListOfCCDTypes = AccountingForTraceableGoodsClientServerLocalization.CCDNumberTypes(TracedGoods);
				
			EndIf;
			
		EndIf;
		
		Query = New Query(QueryText);
		Query.SetParameter("Products",			Products);
		Query.SetParameter("Characteristic",			Characteristic);
		Query.SetParameter("SearchString", Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
		Query.SetParameter("ExcludeCurrentLink",	ValueIsFilled(CurrentRef));
		Query.SetParameter("CurrentRef",			CurrentRef);
		Query.SetParameter("SelectionByCCDRoomType",	ValueIsFilled(CCDNumberType));
		Query.SetParameter("CCDNumberType",			CCDNumberType);
		Query.SetParameter("SelectionByCountry",			ValueIsFilled(OriginCountry));
		Query.SetParameter("Country",					OriginCountry);
		Query.SetParameter("SelectionAccordingToListOfCCDTypes",	ValueIsFilled(ListOfCCDTypes));
		Query.SetParameter("ListOfCCDTypes",			ListOfCCDTypes);
		
		SamplingOfCCD = Query.Execute().Select();
		
		While SamplingOfCCD.Next() Do
			ChoiceItem = New Structure;
			ChoiceItem.Insert("Value",			SamplingOfCCD.Ref);
			ChoiceItem.Insert("DeletionMark",	SamplingOfCCD.DeletionMark);
			
			If GetAdditionalData Then
				AdditionalData = New Structure;
				AdditionalData.Insert("UnitOfMeasure", SamplingOfCCD.UnitOfMeasure);
				
				ChoiceItem.Insert("AdditionalData", AdditionalData);
			EndIf;
			
			Presentation = TrimAll(SamplingOfCCD.Presentation)
							+ ?(ValueIsFilled(SamplingOfCCD.CountryPresentation),
								" (" + SamplingOfCCD.CountryPresentation + ")",
								"");
			
			ChoiceData.Add(ChoiceItem, Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Checks the availability of the previously matched supplier's nomenclature in the information database.
//
// Parameters:
//   Object - FormDataCollection - a document in which you need to compare the supplier's item.
//
// Returns:
//   Boolean - True if it is necessary to display a warning about the mapping.
//
Function CheckMatchedSupplierProducts(Val Object) Export
	
	Return False;
	
EndFunction

// Deprecated. You should use the method of the same name from the module of comparison of nomenclatedcompetentsclient. 
// Generates a list of supplier item values by partner, item, characteristic, and package.
//
// Parameters:
//  Partner        - CatalogRef.Partners - the supplier to create the list for.
//  Products   - CatalogRef.Products - the nomenclature of the enterprise to filter the item of the supplier.
//  Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the company's nomenclature
//                    for filtering the supplier's nomenclature.
//  Packaging-Reference Link.Opakowaniowej - packaging nomenclature of the enterprise
//                                                                   to filter the item supplier.
//
// Returns:
//   Array - the supplier's nomenclature that fits the filtering conditions.
//
Function CreateListToSelectSupplierProducts(Val Partner, Val Products, Val Characteristic) Export
	
	Return New Array();
	
EndFunction

#EndRegion

#Region ProcedureForCheckingContractInDocument

// Returns the result of partner verification in the created Contract and document.
//
//Parameters:
//	Contract - CatalogRef.CounterpartyContracts - a Contract has been CREATED.
//	SelectionData_ - Structure - the selection parameters depend on the document.
//	DocumentPartner - CatalogRef.Partners - The partner from the document.
//	ErrorMessage - String - generated error message.
//	 
//Returns:
//	Boolean - indicates that the check passed.
//
Function CheckSelectionAndPartnerData(Contract, Val SelectionData_, DocumentPartner, ErrorMessage = "") Export
	
	SelectionData_ = Common.CopyRecursive(SelectionData_); // For modification.
	CheckPassed = True;
	ParametersArray = New Array;
	
	#Region NonStandardParameters
	DestinationLineOfBusiness = Undefined;
	If SelectionData_.Property("SupplyAssignment") Then
		
		// We use the line of business from the destination to select Contracts with the procedure for calculating "Sub-agreements of contractors":
		SupplyAssignment = SelectionData_.SupplyAssignment;
		SelectionData_.Delete("SupplyAssignment");
			
		If ValueIsFilled(SupplyAssignment)
			And Not SelectionData_.Property("LineOfBusiness") Then
			
			LinesOfBusiness = Catalogs.Assignments.AreasOfActivityOfAppointments(
				CommonClientServer.ValueInArray(SupplyAssignment));
			DestinationLineOfBusiness = LinesOfBusiness.Get(SupplyAssignment);
			
			ParametersArray.Add("LineOfBusiness");
			ParametersArray.Add("ARAPObjectSettings");
			
		EndIf;
		
	EndIf;
	
	If SelectionData_.Property("Terms") Then
		
		Terms = SelectionData_.Terms;
		SelectionData_.Delete("Terms");
		
		If ValueIsFilled(Terms)
			And Not SelectionData_.Property("BusinessOperation") Then
			// There is no selection of operation, but the agreement is specified.
			// We take as a selection an economic of operation from the agreement for data consistency:
			BusinessOperation = Catalogs.TermsOfPurchaseFromVendors.BusinessTransactionFromAgreement(Terms);
			SelectionData_.Insert("BusinessOperation", BusinessOperation);
		EndIf;
		
	EndIf;
	#EndRegion
	
	For Each FilterParameter In SelectionData_ Do
		ParametersArray.Add(FilterParameter.Key);
	EndDo;
	
	If ParametersArray.Find("Partner") = Undefined Then
		ParametersArray.Add("Partner");
	EndIf;
	If ParametersArray.Find("ItIsAllowedToWorkWithSubsidiaryPartners") = Undefined Then
		ParametersArray.Add("ItIsAllowedToWorkWithSubsidiaryPartners");
	EndIf;
	
	ParametersArray = CommonClientServer.CollapseArray(ParametersArray);
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, ParametersArray);
	For Each FilterParameter In SelectionData_ Do
		If TypeOf(FilterParameter.Value) = Type("FixedArray") Then
			If FilterParameter.Value.Find(ContractDetails_[FilterParameter.Key]) = Undefined Then
				CheckPassed = False;
				Break;
			EndIf;
		ElsIf ContractDetails_[FilterParameter.Key] <> FilterParameter.Value Then
			CheckPassed = False;
			Break;
		EndIf;
	EndDo;
	
	If CheckPassed
		And ValueIsFilled(DestinationLineOfBusiness)
		And ValueIsFilled(ContractDetails_.LineOfBusiness)
		And DestinationLineOfBusiness <> ContractDetails_.LineOfBusiness Then
		CheckPassed = False;
	EndIf;
	
	If CheckPassed Then
		
		AgreementPartner = ContractDetails_.Partner;
		
		If ContractDetails_.ItIsAllowedToWorkWithSubsidiaryPartners Then
			
			PartnerList = New ValueList;
			PartnersAndCounterparties.FillInListOfPartnersWithParents(DocumentPartner, PartnerList);
			
			ArrayOfPartners = PartnerList.UnloadValues();
			If ArrayOfPartners.Find(AgreementPartner) = Undefined Then
				CheckPassed = False;
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối tác được chỉ ra trong hợp đồng ""%1"" cần là ""%2"" hoặc đối tác mẹ';
						|ru = 'Указанный партнер в договоре ""%1"" должен быть ""%2"" или головной партнер';
						|en = 'The partner specified in the ""%1"" contract must be ""%2"" or the main partner'; fa = 'The partner specified in the ""%1"" contract must be ""%2"" or the main partner';
						|it = 'Указанный партнер в договоре ""%1"" должен быть ""%2"" или головной партнер';
						|pl = 'The partner specified in the ""%1"" contract must be ""%2"" or the main partner';
						|tr = '""%1"" sözleşmesinde belirtilen ortak, ""%2"" veya baş ortak olmalıdır'"),
					Contract, DocumentPartner);
			EndIf;
			
		ElsIf AgreementPartner <> DocumentPartner Then
			CheckPassed = False;
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối tác được chỉ ra trong hợp đồng ""%1"" cần là ""%2""';
					|ru = 'Указанный партнер в договоре ""%1"" должен быть ""%2""';
					|en = 'The partner specified in the ""%1"" contract must be ""%2""'; fa = 'The partner specified in the ""%1"" contract must be ""%2""';
					|it = 'Указанный партнер в договоре ""%1"" должен быть ""%2""';
					|pl = 'The partner specified in the ""%1"" contract must be ""%2""';
					|tr = '""%1"" sözleşmesinde belirtilen ortak, ""%2"" olmalıdır'"),
				Contract, DocumentPartner);
		EndIf;
		
	Else
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '""%1"" không tương ứng với điều kiện lựa chọn';
				|ru = '""%1"" не соответствует условиям выбора';
				|en = '""%1"" does not meet the selection criteria'; fa = '""%1"" does not meet the selection criteria';
				|it = '""%1"" не соответствует условиям выбора';
				|pl = '""%1"" does not meet the selection criteria';
				|tr = '""%1"" seçim koşullarıyla eşleşmiyor'"),
			Contract);
	EndIf;
		
	Return CheckPassed;
	
EndFunction

#EndRegion

#EndRegion
