#Region Public

// Supplements the texts of the document execution request with the texts of the contract execution schedule with the client in the accounts With clients register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextPaymentPlans - String - The text of the request to receive the planned payment data for the document.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of settlement is a contract.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of the mutual settlements of the document.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * PaymentDate - Date - Scheduled payment date.
// 	     * PaymentOption - EnumRef.CustomerPaymentControlOptions - Payment option.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The amount of the planned payment.
// 	     * ExcludeDuringControl - Boolean - Flag for controlling the amount of the planned payment during the execution.
// 	TextShipmentPlans - String - The text of the request to receive the data of the planned shipment of the document.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of settlement is a contract.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of the mutual settlements of the document.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * DateOfShipment - Date - Scheduled payment date.
// 	     * IncreaseToBeSHIPPED - DefinedType.MonetaryAmountPositiveNegative - The amount of the planned shipment.
// 
Procedure CarryingOutScheduleOfExecutionOfContractWithClient(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	Operation = "ClientExecutionSchedule";
	TypeOfOperationForSorting = "1";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	TextsOfDocumentDataRequests.Insert("CustomerPaymentPlanIncrease", TextPaymentPlans);
	ArrayOfTexts.Add(IncreasePaymentPlanFromCustomer(Query, Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("IncreasingShipmentPlanToCustomer", TextShipmentPlans);
	TTTemplateTexts.Insert("TTIncreaseInShipmentPlanToCustomer", QueryTextTTIncreaseInShipmentPlan());
	ArrayOfTexts.Add(IncreaseShipmentPlanToCustomer(Query, Operation, TypeOfOperationForSorting));
	
	TextSettlementsWithClients = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccounting", TextSettlementsWithClients);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the document request with the texts of the client's order execution in the accounts With clients register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextPaymentPlans - String - The text of the request to receive data to reflect the payment plan.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - The currency of the document.
// 	     [Details of the mechanism]
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * PaymentDate - Date - The planned date of payment for the entire document/payment stage.
// 	     * ExcludeDuringControl - Boolean - Whether to exclude the check for payment for this line of movements.
// 	     * PaymentOption - EnumRef.CustomerPaymentControlOptions - Payment option for the schedule stage.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements (including the deposit for the container).
// 	     * MeasuringGoodsVarianceAmount - DefinedType.MonetaryAmountPositiveNegative - The amount of deviation of measured goods in the currency of mutual settlements to be paid.
// 	TextShipmentPlans - String - The text of the request to receive document data to reflect the shipment plan.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - The currency of the document.
// 	     [Document details]
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * DateOfShipment - Date - The planned date of shipment of the line/document.
// 	     * IncreaseToBeSHIPPED - DefinedType.MonetaryAmountPositiveNegative - The amount to be shipped in the currency of mutual settlements (including the deposit for the container).
// 	     * IncreaseShipping - DefinedType.MonetaryAmountPositiveNegative - The amount of the increase is being shipped.
// 
Procedure ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans = "", TextShipmentPlans = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If TextPaymentPlans = "" And TextShipmentPlans = "" Then
		Return;
	EndIf;
	
	Operation = "SalesOrder";
	TypeOfOperationForSorting = "1";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	If ValueIsFilled(TextPaymentPlans) Then
		TextsOfDocumentDataRequests.Insert("CustomerPaymentPlanIncrease", TextPaymentPlans);
		ArrayOfTexts.Add(IncreasePaymentPlanFromCustomer(Query, Operation, TypeOfOperationForSorting));
	EndIf;
	
	If ValueIsFilled(TextShipmentPlans) Then
		TextsOfDocumentDataRequests.Insert("IncreasingShipmentPlanToCustomer", TextShipmentPlans);
		TTTemplateTexts.Insert("TTIncreaseInShipmentPlanToCustomer", QueryTextTTIncreaseInShipmentPlan());
		ArrayOfTexts.Add(IncreaseShipmentPlanToCustomer(Query, Operation, TypeOfOperationForSorting));
	EndIf;
	
	If ValueIsFilled(TextShipmentPlans) Then
		TextsOfDocumentDataRequests.Insert("IncreaseIsShipped", TextShipmentPlans);
		ArrayOfTexts.Add(IncreaseShipping(Operation, TypeOfOperationForSorting));
	EndIf;
	
	TextSettlementsWithClients = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccounting", TextSettlementsWithClients);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the sale and transfer of settlements in the accounts With customers register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextSale - String - The text of the request for sale data and the planned dates of its repayment.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * PaymentDate - Date - The planned date of payment for the sale.
// 	     * PaymentOption - EnumRef.CustomerPaymentControlOptions - Payment option for the sale.
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * InvoiceForOrders - Boolean - The invoice was entered by order(s).
// 	     * ExceedingOrder - Boolean - This is a shipment in excess of the order.
// 	     * SalesOrder_ - DocumentRef, Undefined - The order for which the sale takes place.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The settlement amount in the settlement currency.
// 	     * AmountARAPByPackage - DefinedType.MonetaryAmountPositiveNegative - The amount of the deposit for the container in the currency of mutual settlements.
// 	     * LinkedDocument - DocumentRef.CustomerInvoice,
// 	                           Document link.The implementation of the services of other assets is a related adjustment document for determining the reflection rate.
// 	TextPaymentPlan - String - The text of the request to receive data for increasing payment plans.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * PaymentDate - Date - Scheduled payment date.
// 	     * PaymentOption - EnumRef.CustomerPaymentControlOptions - Payment option of the payment plan.
// 	     * ExcludeDuringControl - Boolean - Whether to exclude the check for payment for this line of movements.
// 	     * InvoiceForOrders - Boolean - The invoice was entered by order(s).
// 	     * ExceedingOrder - Boolean - This is a shipment in excess of the order.
// 	     * SalesOrder_ - DocumentRef, Undefined - The order for which the sale takes place.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements.
// 	TextTransferOfAdvancePayment - String - Optional. The text of the request to receive the data of the credited advances.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * CalculationObjectSource - CatalogRef.ARAPObjects - Object of advance payment calculations.
// 	     * CalculationObjectReceiver - CatalogRef.ARAPObjects - The object of the document calculations.
// 	     [General]
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - An economic operation of transferring or reserving an advance.
// 	     [Document details]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The settlement amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	TextProducts_1 - String - The text of the request to receive data from the Goods tabular part - changes the shipment plans and is "shipped".
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * InvoiceForOrders - Boolean - The invoice was entered by order(s).
// 	     * SalesOrder_ - DocumentRef, Undefined - The order for which the sale takes place.
// 	     * ExceedingOrder - Boolean - This is a shipment in excess of the order.
// 	     * DateOfShipment - Date - Planned date of shipment.
// 	     * IncreaseToBeSHIPPED - DefinedType.MonetaryAmountPositiveNegative - The amount of the increase in the plan for shipment in the currency of mutual settlements.
// 	     * ReduceToBESHIPPED - DefinedType.MonetaryAmountPositiveNegative - the amount of the plan reduction to be shipped in the settlement currency.
// 	     * IncreaseShipping - DefinedType.MonetaryAmountPositiveNegative - The amount of the increase is "Shipped".
// 	     * ReduceShipping - DefinedType.MonetaryAmountPositiveNegative - The amount by which the resource should be reduced is "Shipped". 
// 	     The resource is used to control the maximum allowable amount of debt. That is, if the order has already been increased, it means that the shipment is in progress and the order amount will be included in the amount of the controlled debt.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The amount of mutual settlements on the line of goods, for which the shipment plan will not be reduced.
// 	     * DepositForPackage - DefinedType.MonetaryAmountPositiveNegative - The amount of the deposit for the container.
//
Procedure ConductingSale(Query, QueryTexts, Registers, TextSale = "", TextPaymentPlan = "", TextTransferOfAdvancePayment = "", TextProducts_1 = "", TextPayment = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If TextSale = "" And TextPaymentPlan = "" And TextTransferOfAdvancePayment = "" And TextProducts_1 = "" And TextPayment = "" Then
		Return;
	EndIf;
	
	Operation = "Sale";
	TypeOfOperationForSorting = "2";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();

	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	// Offsetting the advance
	If ValueIsFilled(TextTransferOfAdvancePayment) Then
		TextsOfDocumentDataRequests.Insert("PaymentDecryptionTable", TextTransferOfAdvancePayment);
		ArrayOfTexts.Add(ReflectTransferOfSettlementsWithClient(Query, Operation, TypeOfOperationForSorting)); //Transfer of advances on invoices
	EndIf;
	
	// Transfer of debt under the central agreement
	If ValueIsFilled(TextSale) Then
		ArrayOfTexts.Add(TextTransferOfCustomerDebtBetweenBranches(TypeOfOperationForSorting));
	EndIf;
	
	// Increasing the payment plan
	If ValueIsFilled(TextPaymentPlan) Then 
		TextsOfDocumentDataRequests.Insert("CustomerPaymentPlanIncrease", TextPaymentPlan);
		ArrayOfTexts.Add(IncreasePaymentPlanFromCustomer(Query, Operation, TypeOfOperationForSorting));
		// reduction of the payment plan for orders
		TextsOfDocumentDataRequests.Insert("ReductionOfPaymentPlanFromCustomer", TextPaymentPlan);
		ArrayOfTexts.Add(ReducePaymentPlanFromCustomer(Operation, TypeOfOperationForSorting, , ValueIsFilled(TextProducts_1)));
	EndIf;
		
	// Increase in customer debt
	If ValueIsFilled(TextSale) Then 
		TextsOfDocumentDataRequests.Insert("IncreasingCustomerDebt", TextSale);
		ArrayOfTexts.Add(IncreaseCustomerDebt(Operation,TypeOfOperationForSorting));
	EndIf;
	
	If ValueIsFilled(TextProducts_1) Then
		
		AvailableFields = ARAPAccountingInternal.AvailableRequestFields(TextProducts_1); 
		
		// Reduction Is Being Shipped
		TextsOfDocumentDataRequests.Insert("ReductionIsShipped", TextProducts_1);
		TextIsNotBeingShipped = ReduceShipping(TypeOfOperationForSorting);
		
		If AvailableFields.Find("ThisIsTransferOfOwnershipBasedOnShipment") <> Undefined Then
			
			TextOfConditionTransferOfOwnershipOnBasisOfShipment =
				"ReductionIsShipped.ThisIsTransferOfOwnershipBasedOnShipment";
			
		Else
			TextOfConditionTransferOfOwnershipOnBasisOfShipment = "FALSE";
		EndIf;
		
		TextIsNotBeingShipped = StrReplace(TextIsNotBeingShipped,
			"&TextOfConditionTransferOfOwnershipOnBasisOfShipment",
			TextOfConditionTransferOfOwnershipOnBasisOfShipment);
		
		ArrayOfTexts.Add(TextIsNotBeingShipped);
		
		// Reducing the shipment plan
		TextsOfDocumentDataRequests.Insert("ReducingShipmentPlanToCustomer", TextProducts_1);
		TTTemplateTexts.Insert("TTReductionOfShipmentPlanToCustomer", QueryTextTTReductionOfShipmentPlan());
		ArrayOfTexts.Add(ReduceShipmentPlanToCustomer(TypeOfOperationForSorting));
		
		// Increase in the shipment plan - in excess of the order
		TextsOfDocumentDataRequests.Insert("IncreasingShipmentPlanToCustomer", TextProducts_1);
		TTTemplateTexts.Insert("TTIncreaseInShipmentPlanToCustomer", QueryTextTTIncreaseInShipmentPlan(True));
		ArrayOfTexts.Add(IncreaseShipmentPlanToCustomer(Query, Operation, TypeOfOperationForSorting));
		
		// The increase is shipped - in excess of the order
		TextsOfDocumentDataRequests.Insert("IncreaseIsShipped", TextProducts_1);
		ArrayOfTexts.Add(IncreaseShipping(Operation, TypeOfOperationForSorting));
		
	EndIf;
	
	TextSettlementsWithClients = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccounting", TextSettlementsWithClients);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the document request with the texts of payment from the client in the accounts With clients register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextPayment - String - The text of the request to receive payment data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * Organization - 
// 	     * Partner -
// 	     [Overall]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The settlement object for which the payment is made.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * MaturityDate - Date - The planned repayment date of the advance
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The amount of payment in the currency of mutual settlements.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * IncreaseIsPaid - DefinedType.MonetaryAmountPositiveNegative - The amount of the increase is "Paid".
// 	     * ReductionIsPaid - DefinedType.MonetaryAmountPositiveNegative - The amount of reduction is "Paid".
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * ProformaInvoice - DocumentRef.CustomerCommercialInvoice - The invoice for which the payment is made.
// 	     * LinkedDocument - DocumentRef.CustomerInvoice,
// 	                           Document link.The implementation of the services of other assets is a related adjustment document for determining the reflection rate.
// 	     * FinRecordID - String - A string with the value of the unique identifier of the header or line of the document.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up the business operation of the document.
// 	TypeOfOperationForSorting - String - The type of operation is a string for sorting the distribution within a day, if it differs from the default value.
//
Procedure CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment, TypeOfOperationForSorting = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		Return;
	EndIf; 
	
	If Not ValueIsFilled(TextPayment) Then
		Return;
	EndIf;
	
	Operation = "PaymentFromCustomer";
	TypeOfOperationForSorting = ?(ValueIsFilled(TypeOfOperationForSorting),TypeOfOperationForSorting,"4");
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	// Transfer of payment under the central agreement
	TTTemplateTexts.Insert("TTTransferOfPaymentsClient", ARAPAccountingPosting.TTTextForTransferringCalculations("TablePaymentFromCustomer"));
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	// Transfer of payment under the central agreement
	ArrayOfTexts.Add(ReflectTransferOfSettlementsWithClient(Query, "TransferOfPaymentUnderCentralizedContract", TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("ReductionOfPaymentPlanFromCustomer", TextPayment);
	ArrayOfTexts.Add(ReducePaymentPlanFromCustomer(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("TablePaymentFromCustomer", TextPayment);
	ArrayOfTexts.Add(IncreaseOurCustomerDebt(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("IncreaseIsPaidByClient", TextPayment);
	ArrayOfTexts.Add(FeeIsPaidByClient(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("ReductionIsPaidByClient", TextPayment);
	ArrayOfTexts.Add(FeeIsPaidByCustomer(Operation, TypeOfOperationForSorting));
	
	TextSettlementsWithClients = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccounting", TextSettlementsWithClients);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Complements the text of the requested document with text running the application for a refund of the DS client on a case-accounts receivable.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextSettlements - String - The text of the request to get document data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The settlement object for which the payment is planned.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * BeingPaid - DefinedType.MonetaryAmountPositiveNegative - The amount of reduction is "Paid" (return planning).
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - DDS article
// 
Procedure ConductingRequestForRefundToClient(Query, QueryTexts, Registers, TextSettlements) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If TextSettlements = "" Then
		Return;
	EndIf;
	
	Operation = "RequestForRefundToClient";
	TypeOfOperationForSorting = "1";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	TextsOfDocumentDataRequests = New Structure();
	
	TextsOfDocumentDataRequests.Insert("ReductionIsPaidByClient", TextSettlements);
	TextSettlementsWithClients = FeeIsPaidByCustomer(Operation, TypeOfOperationForSorting);
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccounting", TextSettlementsWithClients);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the document request with the texts of the payment refund to the client in the accounts With clients register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextOfReport - String - The text of the request to receive payment data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the settlement currency.
// 	     * AmountNotPaid - DefinedType.MonetaryAmountPositiveNegative - The amount is being paid.
// 	     * FinRecordID - String - A string with the value of the unique identifier of the header or line of the document.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up the business operation of the document.
// 	TextTransferOfCalculations - String - The text of the request to receive the data of the Cash refund set-off to the client for the objects of the decryption calculations.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * CalculationObjectSource - CatalogRef.ARAPObjects - The settlement object for which the funds are returned.
// 	     * CalculationObjectReceiver - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     [General]
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The settlement amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	Text is being paid - String is the text of the request for receiving refund data for which it is necessary to reduce "Being paid".
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations for which it is necessary to reduce the "Paid", usually the object of decoding calculations.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * BeingPaid - DefinedType.MonetaryAmountPositiveNegative - The amount of reduction is "Paid".
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * PaymentRequest - DocumentRef.PaymentRequest - If the refund is made on request.
// 
Procedure MakingRefundToClient(Query, QueryTexts, Registers, TextOfReport = "", TextTransferOfCalculations = "", ReduceTextIsPaidToClient = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If TextOfReport = "" And TextTransferOfCalculations = "" And ReduceTextIsPaidToClient = "" Then
		Return;
	EndIf;
	
	Operation = "RefundToCustomer";
	TypeOfOperationForSorting = "5";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	If ValueIsFilled(TextOfReport) Then
	
		TextsOfDocumentDataRequests.Insert("IncreasingCustomerDebt", TextOfReport);
		ArrayOfTexts.Add(IncreaseCustomerDebt(Operation, TypeOfOperationForSorting));
		
		TextsOfDocumentDataRequests.Insert("CustomerPaymentPlanIncrease", TextOfReport);
		ArrayOfTexts.Add(IncreasePaymentPlanFromCustomer(Query, Operation, TypeOfOperationForSorting));
		
		TextsOfDocumentDataRequests.Insert("ReductionIsPaidByClient", TextOfReport);
		ArrayOfTexts.Add(FeeIsPaidByCustomer(Operation,TypeOfOperationForSorting));
	
	EndIf;
	
	// Transfer of advance payment
	If ValueIsFilled(TextTransferOfCalculations) Then
		TextsOfDocumentDataRequests.Insert("PaymentDecryptionTable", TextTransferOfCalculations);
		ArrayOfTexts.Add(ReflectTransferOfSettlementsWithClient(Query, Operation, TypeOfOperationForSorting, "2"));
	EndIf;
	
	// The reduction is paid to the client
	If ValueIsFilled(ReduceTextIsPaidToClient) Then
		TextsOfDocumentDataRequests.Insert("IncreaseIsPaidByClient", ReduceTextIsPaidToClient);
		ArrayOfTexts.Add(FeeIsPaidByClient(Operation, TypeOfOperationForSorting));
	EndIf;
	
	TextSettlementsWithClients = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccounting", TextSettlementsWithClients);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the return of goods(valuables) from the client in the accounts With clients register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextReturn - String - The text of the request to receive data from the return document. Reflects the return of the goods itself.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * Organization - CatalogRef.Companies - Organization of the return of goods.
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations for the return of goods.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - Household Operation of the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - Article DDS.
// 	     [Document Attributes]
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the settlement currency.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the settlement currency by which the client's payment plan should be reduced.
// 	TextTransferOfCalculations - String - The text of the request to receive payment decryption data. Reflects the offset of the refund to other payment objects.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * CalculationObjectSource - CatalogRef.ARAPObjects - The object of calculations for the return of goods.
// 	     * CalculationObjectReceiver - CatalogRef.ARAPObjects - The object of calculations for which the offset is made.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements of the settlement object to which the transfer is made.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The utility operation of the document.
// 	     [Details of the tabular part]
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The transfer amount in the document currency.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The transfer amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
//
Procedure CarryingOutReturnOfGoodsFromCustomer(Query, QueryTexts, Registers, TextReturn, TextTransferOfCalculations = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	Operation = "ReturnOfGoods";
	TypeOfOperationForSorting = "3"; 
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	// Transfer of debt under the central agreement
	TTTemplateTexts.Insert("TTTransferOfPaymentsClient", ARAPAccountingPosting.TTTextForTransferringCalculations("TablePaymentFromCustomer"));
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	If Not Query.Parameters.Property("ManagementAccountingCurrency") Then
		Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	EndIf;
	TextsOfDocumentDataRequests = New Structure();
	
	ArrayOfTexts.Add(ReflectTransferOfSettlementsWithClient(Query, "PostponementOfReturnOfGoodsUnderCentralizedContract", TypeOfOperationForSorting, "1"));
	
	TextsOfDocumentDataRequests.Insert("ReductionOfPaymentPlanFromCustomer", TextReturn);
	ArrayOfTexts.Add(ReducePaymentPlanFromCustomer(Operation, TypeOfOperationForSorting, "2"));
	
	TextsOfDocumentDataRequests.Insert("TablePaymentFromCustomer", TextReturn);
	ArrayOfTexts.Add(IncreaseOurCustomerDebt(Operation, TypeOfOperationForSorting,"2"));
	
	If ValueIsFilled(TextTransferOfCalculations) Then
		TextsOfDocumentDataRequests.Insert("PaymentDecryptionTable", TextTransferOfCalculations);
		ArrayOfTexts.Add(ReflectTransferOfSettlementsWithClient(Query, Operation, TypeOfOperationForSorting,"3"));
	EndIf;
	
	TextSettlementsWithClients = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccounting", TextSettlementsWithClients);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// supplements the texts of the request for the document with the texts of the client's order according to the register of scheduled customer payments.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextPaymentPlans - String - The text of the request to receive data to reflect the payment plan.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - The currency of the document.
// 	     [Details of the mechanism]
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * PaymentDate - Date - The planned date of payment for the entire document/payment stage.
// 	     * PaymentOption - EnumRef.CustomerPaymentControlOptions - Payment option for the schedule stage.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements (including the deposit for the container).
// 
Procedure ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccountingCashFlowPlan", Registers) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(TextPaymentPlans) Then
		Return;
	EndIf;
	
	ReflectionTemplateTexts = New Structure();
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region ConductingSettlementsWithClientsPaymentPlan
	
	TextsOfDocumentDataRequests = New Structure();
	TextsOfDocumentDataRequests.Insert("CustomerPaymentPlanIncrease", TextPaymentPlans);
	
	AvailableRequestFields = ARAPAccountingInternal.AvailableRequestFields(TextPaymentPlans);
	
	If AvailableRequestFields.Find("MeasuringGoodsVarianceAmount") <> Undefined  Then
		MeasuringGoodsVarianceAmount = "CustomerPaymentPlanIncrease.MeasuringGoodsVarianceAmount";
	Else
		MeasuringGoodsVarianceAmount = "0";
	EndIf;
	
	If AvailableRequestFields.Find("MeasuringGoodsVarianceAmount.OrderDate") <> Undefined  Then
		OccurrenceDate = "CustomerPaymentPlanIncrease.OrderDate"
	Else
		OccurrenceDate = "CustomerPaymentPlanIncrease.RecorderDate"
	EndIf;
	
	If AvailableRequestFields.Find("ReferenceOrder") <> Undefined Then
		TextOfDocumentPlanField = "CustomerPaymentPlanIncrease.ReferenceOrder";
	Else
		TextOfDocumentPlanField = "CustomerPaymentPlanIncrease.Ref";
	EndIf;
	
	QueryText = "SELECT
		|	CustomerPaymentPlanIncrease.RecorderDate                   AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	CustomerPaymentPlanIncrease.ARAPObject                     AS ARAPObject,
		|	CustomerPaymentPlanIncrease.ARAPCurrency               AS Currency,
		|	&TextOfDocumentPlanField                                           AS DocumentPlan,
		|	CustomerPaymentPlanIncrease.PaymentDate                        AS PlannedRepaymentDate,
		|	&OccurrenceDate                                               AS OccurrenceDate,
		|	CustomerPaymentPlanIncrease.RecorderDate                   AS RecorderDate,
		|	CustomerPaymentPlanIncrease.RecorderNumber                  AS RecorderNumber,
		|	CustomerPaymentPlanIncrease.PaymentOption                      AS PaymentOption,
		|	1                                                                AS Kind,
		|	
		|	CustomerPaymentPlanIncrease.AmountDue + &MeasuringGoodsVarianceAmount AS AmountDue,
		|	
		|	CustomerPaymentPlanIncrease.Ref                             AS DocumentRecorder,
		|	
		|	CustomerPaymentPlanIncrease.ARAPObject.Organization         AS Organization,
		|	CustomerPaymentPlanIncrease.Partner                            AS Partner,
		|	CustomerPaymentPlanIncrease.ARAPObject.Counterparty          AS Counterparty,
		|	CustomerPaymentPlanIncrease.ARAPObject.Contract             AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness
		|FROM
		|	#CustomerPaymentPlanIncrease AS CustomerPaymentPlanIncrease
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON CustomerPaymentPlanIncrease.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CustomerPaymentPlanIncrease.ARAPObject.Organization = Dimension.Organization
		|				AND CustomerPaymentPlanIncrease.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND CustomerPaymentPlanIncrease.Partner = Dimension.Partner
		|				AND CustomerPaymentPlanIncrease.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|";
	
	QueryText = StrReplace(QueryText, "&MeasuringGoodsVarianceAmount", MeasuringGoodsVarianceAmount);
	QueryText = StrReplace(QueryText, "&OccurrenceDate", OccurrenceDate);
	QueryText = StrReplace(QueryText, "&TextOfDocumentPlanField", TextOfDocumentPlanField);
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccountingCashFlowPlan", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccountingCashFlowPlan", QueryText);
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// supplements the texts of the request for the document with the texts of the client's order according to the register of scheduled customer payments.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextShipmentPlans - String - the Query Text for receiving data to reflect the shipment plan.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - The currency of the document.
// 	     [Details of the mechanism]
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * PaymentDate - Date - The planned date of payment for the entire document/payment stage.
// 	     * PaymentOption - EnumRef.CustomerPaymentControlOptions - Payment option for the schedule stage.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements (including the deposit for the container).
// 	ThisIsScheduleOfContract - Boolean - The schedule of execution of the Contract is carried out, otherwise the Order
// 
Procedure ConductingSettlementsWithCustomersShippingPlan(Query, QueryTexts, Registers, TextShipmentPlans, ThisIsScheduleOfContract = False) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccountingPlannedShipments", Registers) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(TextShipmentPlans) Then
		Return;
	EndIf;
	
	ReflectionTemplateTexts = New Structure();
	
	#Region ConductingSettlementsWithCustomersShippingPlan
	
	TextsOfDocumentDataRequests = New Structure();
	TextsOfDocumentDataRequests.Insert("IncreasingShipmentPlanToCustomer", TextShipmentPlans);
	
	Query.SetParameter("ThisIsScheduleOfContract",ThisIsScheduleOfContract);
	
	AvailableRequestFields = ARAPAccountingInternal.AvailableRequestFields(TextShipmentPlans);
	
	If AvailableRequestFields.Find("OrderDate") <> Undefined Then
		OccurrenceDate = "IncreasingShipmentPlanToCustomer.OrderDate"
	Else
		OccurrenceDate = "IncreasingShipmentPlanToCustomer.RecorderDate"
	EndIf;
	
	If AvailableRequestFields.Find("ReferenceOrder") <> Undefined Then
		TextOfDocumentPlanField = "IncreasingShipmentPlanToCustomer.ReferenceOrder";
	Else
		TextOfDocumentPlanField = "&Ref";
	EndIf;
	
	QueryText = 
		"SELECT
		|	IncreasingShipmentPlanToCustomer.RecorderDate                  AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	IncreasingShipmentPlanToCustomer.ARAPObject                    AS ARAPObject,
		|	IncreasingShipmentPlanToCustomer.ARAPCurrency              AS Currency,
		|	&TextOfDocumentPlanField                                           AS DocumentPlan,
		|	IncreasingShipmentPlanToCustomer.DateOfShipment                      AS PlannedRepaymentDate,
		|	&OccurrenceDate                                               AS OccurrenceDate,
		|	FALSE                                                             AS UnallocatedAdvancePayment,
		|	
		|	IncreasingShipmentPlanToCustomer.IncreaseToBeSHIPPED                AS Sum,
		|
		|	&Ref                                                          AS DocumentRecorder,
		|
		|	CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|		THEN IncreasingShipmentPlanToCustomer.Organization
		|		ELSE IncreasingShipmentPlanToCustomer.ARAPObject.Organization
		|	END                                                            AS Organization,
		|	IncreasingShipmentPlanToCustomer.Partner                           AS Partner,
		|	IncreasingShipmentPlanToCustomer.ARAPObject.Counterparty         AS Counterparty,
		|	IncreasingShipmentPlanToCustomer.ARAPObject.Contract            AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	IncreasingShipmentPlanToCustomer.RecorderNumber                 AS RecorderNumber,
		|	IncreasingShipmentPlanToCustomer.RecorderDate                  AS RecorderDate,
		|	1                                                                AS Kind
		|FROM
		|	#IncreasingShipmentPlanToCustomer AS IncreasingShipmentPlanToCustomer
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreasingShipmentPlanToCustomer.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = IncreasingShipmentPlanToCustomer.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|					THEN IncreasingShipmentPlanToCustomer.Organization
		|					ELSE IncreasingShipmentPlanToCustomer.ARAPObject.Organization
		|				END = Dimension.Organization
		|				AND IncreasingShipmentPlanToCustomer.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND IncreasingShipmentPlanToCustomer.Partner = Dimension.Partner
		|				AND IncreasingShipmentPlanToCustomer.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	IncreasingShipmentPlanToCustomer.IncreaseToBeSHIPPED <> 0
		|	AND IncreasingShipmentPlanToCustomer.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|	AND (&ThisIsScheduleOfContract OR NOT ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE))
		|";
	
	QueryText = StrReplace(QueryText, "&OccurrenceDate", OccurrenceDate);
	QueryText = StrReplace(QueryText, "&TextOfDocumentPlanField", TextOfDocumentPlanField);
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccountingPlannedShipments", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccountingPlannedShipments", QueryText);
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
EndProcedure

#EndRegion

#Region Private

Function ReflectTransferOfSettlementsWithClient(Query, Operation, TypeOfOperationForSorting, OrderOfOperationsWithinDocument = "1")
	
	If Not Query.Parameters.Property("ARAPObjectPrepayment") Then
		ARAPObjectPrepayment = Metadata.DefinedTypes.ARAPObjectPrepayment.Type.Types();
		Query.SetParameter("ARAPObjectPrepayment", ARAPObjectPrepayment);
	EndIf;
	
	If Operation = "Sale" Then
		
		AccountsPayable = "TRUE"; // what's in the source
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		
		FillingReceiverInSource = "TRUE";
		
		OperationCondition = "
		|	PaymentDecryptionTable.CalculationObjectSource <> PaymentDecryptionTable.CalculationObjectReceiver";
		
		BusinessOperation = "PaymentDecryptionTable.BusinessOperation";
		
		PaymentMethod = "Undefined";
		
		SettlementObjectSourceOrganization = "CalculationObjectsSources.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
	
		SettlementObjectSourcePartner = "CalculationObjectsSources.Partner";
		SettlementObjectReceiverPartner = "CalculationObjectsReceivers.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTable.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTable.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTable.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTable.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTable.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTable.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTable.RecorderDate";
		PaymentOption = "VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)";
		CashFlowItem = "Undefined";
	
		FinRecordID = "PaymentDecryptionTable.CalculationObjectSource.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)"; 
		
		ExcludeDuringControl = "FALSE";
		
		ApplicationSource = "Undefined";
		
	ElsIf Operation = "TransferOfPaymentUnderCentralizedContract" Then
		
		AccountsPayable = "TRUE"; // what's in the source
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		
		FillingReceiverInSource = "TRUE";
		
		OperationCondition = "PaymentDecryptionTable.Organization <> CalculationObjectsReceivers.Organization";
		
		BusinessOperation = "VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)";
		
		PaymentMethod = "Undefined";
		
		SettlementObjectSourceOrganization = "PaymentDecryptionTable.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
		
		SettlementObjectSourcePartner = "PaymentDecryptionTable.Partner";
		SettlementObjectReceiverPartner = "PaymentDecryptionTable.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTable.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTable.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTable.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTable.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTable.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTable.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTable.RecorderDate";
		PaymentOption = "VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned)";
		CashFlowItem = "PaymentDecryptionTable.CashFlowItem";
	
		FinRecordID = "PaymentDecryptionTable.CalculationObjectSource.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.PaymentTransferBetweenBranchOffices)";
		
		ExcludeDuringControl = "FALSE";
		OrderOfOperationsWithinDocument = "2";
		
		ApplicationSource = "Undefined";
		
	ElsIf Operation = "PostponementOfReturnOfGoodsUnderCentralizedContract" Then
		
		AccountsPayable = "TRUE"; // what's in the source
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "FALSE";
		
		OperationCondition = "ISNULL(ContractData.CentralizedContract, FALSE)
		|	AND PaymentDecryptionTable.Organization <> CalculationObjectsReceivers.Organization";
		
		BusinessOperation = "VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)";
		
		PaymentMethod = "Undefined";
		
		SettlementObjectSourceOrganization = "PaymentDecryptionTable.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
		
		SettlementObjectSourcePartner = "PaymentDecryptionTable.Partner";
		SettlementObjectReceiverPartner = "PaymentDecryptionTable.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTable.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTable.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTable.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTable.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTable.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTable.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTable.RecorderDate";
		PaymentOption = "VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned)";
		CashFlowItem = "PaymentDecryptionTable.CashFlowItem";
	
		FinRecordID = "PaymentDecryptionTable.CalculationObjectSource.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.DebtTransferBetweenBranchOffices)";
		
		ExcludeDuringControl = "TRUE";
		OrderOfOperationsWithinDocument = "2";
		
		ApplicationSource = "Undefined";
		
	ElsIf Operation = "RefundToCustomer" Then
		
		AccountsPayable = "TRUE";
		StornoSource = "TRUE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "TRUE";
		
		OperationCondition = "PaymentDecryptionTable.CalculationObjectSource <> PaymentDecryptionTable.CalculationObjectReceiver";
		
		BusinessOperation = "PaymentDecryptionTable.BusinessOperation";
	
		PaymentMethod = "PaymentDecryptionTable.PaymentMethod";
		
		SettlementObjectSourceOrganization = "CalculationObjectsSources.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
	
		//The refund of the payment to the subsidiary partner must be made by the subsidiary partner, and not by the parent
		SettlementObjectSourcePartner = "PaymentDecryptionTable.Partner";
		SettlementObjectReceiverPartner = "PaymentDecryptionTable.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTable.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTable.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTable.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTable.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTable.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTable.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTable.RecorderDate";
		PaymentOption = "Undefined";
		CashFlowItem = "PaymentDecryptionTable.CashFlowItem";
		
		//To transfer, you need to write the source identifiers from the settlement objects in the payment decryption.
		FinRecordID = "PaymentDecryptionTable.CalculationObjectSource.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)";
		
		OrderOfOperationsWithinDocument = "2";
		
		ExcludeDuringControl = "TRUE";
		
		ApplicationSource = "PaymentDecryptionTable.PaymentRequest";
		
	ElsIf Operation = "ReturnOfGoods" Then
		
		AccountsPayable = "TRUE";
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "FALSE";
		
		OperationCondition = "PaymentDecryptionTable.CalculationObjectSource <> PaymentDecryptionTable.CalculationObjectReceiver";
		
		BusinessOperation = "PaymentDecryptionTable.BusinessOperation";
		
		PaymentMethod = "Undefined";
		
		SettlementObjectSourceOrganization = "CalculationObjectsSources.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
	
		SettlementObjectSourcePartner = "CalculationObjectsSources.Partner";
		SettlementObjectReceiverPartner = "CalculationObjectsReceivers.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTable.DocumentCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTable.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTable.Sum";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTable.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTable.Sum";
		ReceiverForPayment = "PaymentDecryptionTable.AmountARAP";
		
		PaymentDate = "Undefined";
		PaymentOption = "Undefined";
		CashFlowItem = "Undefined";
		
		FinRecordID = "PaymentDecryptionTable.CalculationObjectReceiver.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.ARAPSettlement)";
		
		ExcludeDuringControl = "TRUE";
		
		ApplicationSource = "Undefined";
		
	EndIf;
	
	#Region QueryText
	QueryText = "
		|SELECT
		|	PaymentDecryptionTable.RecorderDate              AS Period,
		|	CASE
		|		WHEN NOT &StornoSource AND &AccountsPayable
		|			OR &StornoSource AND NOT &AccountsPayable
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END                                                   AS RecordType,
		|	
		|	ISNULL(DimensionSource.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.CalculationObjectSource        AS ARAPObject,
		|	&CurrencyOfSettlementsSource                           AS Currency,
		|	
		|	(&AmountOfSettlementsSource *
		|		CASE WHEN &StornoSource THEN -1 ELSE 1 END) AS Sum,
		|	(&ForPaymentSource *
		|		CASE WHEN &StornoSource THEN -1 ELSE 1 END) AS AmountDue,
		|	0                                                       AS BeingPaid,
		|	0                                                       AS ToShip,
		|	0                                                       AS BeingShipped,
		|	
		|	&BusinessOperation                                  AS BusinessOperation,
		|	&PaymentMethod                                            AS PaymentMethod,
		|	UNDEFINED                                            AS ProformaInvoice,
		|	UNDEFINED                                            AS SaleByOrder,
		|	PaymentDecryptionTable.RecorderDate              AS RecorderDate,
		|	&PaymentDate                                            AS PaymentDate,
		|	
		|	(CASE WHEN &CurrencyOfSettlementsSource = Coefficients.LocalAccountingCurrency
		|				THEN &AmountOfSettlementsSource
		|			WHEN PaymentDecryptionTable.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN PaymentDecryptionTable.Sum
		|			ELSE CAST(PaymentDecryptionTable.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END *
		|		CASE WHEN &StornoSource THEN -1 ELSE 1 END) AS SumCompl,
		|	(CASE WHEN &CurrencyOfSettlementsSource = &ManagementAccountingCurrency
		|				THEN &AmountOfSettlementsSource
		|			WHEN PaymentDecryptionTable.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN PaymentDecryptionTable.Sum
		|			ELSE CAST(PaymentDecryptionTable.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END *
		|		CASE WHEN &StornoSource THEN -1 ELSE 1 END) AS SumMan,
		|
		|	&ExcludeDuringControl                                    AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0) AS AllowableAmountPayable,
		|	0                                                       AS DepositForPackage,
		|	&CashFlowItem                          AS CashFlowItem,
		|	UNDEFINED                                            AS ARAPDocument,
		|	UNDEFINED                                            AS LinkedDocument,
		|	&PaymentOption                                          AS PaymentOption,
		|	PaymentDecryptionTable.DocumentCurrency               AS DocumentCurrency,
		|	UNDEFINED                                            AS CorARAPObject,
		|	UNDEFINED                                            AS CorPartnerAccountingDimension,
		|	
		|	&SettlementObjectSourceOrganization                      AS Organization,
		|	&SettlementObjectSourcePartner                          AS Partner,
		|	CalculationObjectsSources.Counterparty                     AS Counterparty,
		|	CalculationObjectsSources.Contract                        AS Contract,
		|	AreasOfActivitySource.DirectionOfAnalytics    AS LineOfBusiness,
		|
		|	UNDEFINED                                            AS CorPartner,
		|	UNDEFINED                                            AS CorCompany,
		|	UNDEFINED                                            AS CorCounterparty,
		|	UNDEFINED                                            AS CorContract,
		|	UNDEFINED                                            AS CorLineOfBusiness,
		|	PaymentDecryptionTable.RecorderNumber             AS RecorderNumber,
		|	&FinRecordID                                 AS FinRecordID,
		|	&ApplicationSource                                            AS PaymentRequest,
		|	&TypeOfOperationForSorting                               AS TypeOfOperationForSorting,
		|	&OrderOfOperationsWithinDocumentSource              AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.TransferOfSettlements) AS SettlementTransaction,
		|	&BusinessTransactionSetting                         AS BusinessTransactionSetting,
		|
		|	CASE WHEN &CurrencyOfSettlementsSource = Coefficients.LocalAccountingCurrency
		|		OR PaymentDecryptionTable.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                   AS RateARAPCurrencyNumerator,
		|	CASE WHEN &CurrencyOfSettlementsSource = Coefficients.LocalAccountingCurrency
		|		OR PaymentDecryptionTable.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                   AS RateARAPCurrencyDenominator,
		|	CASE WHEN &CurrencyOfSettlementsSource = &ManagementAccountingCurrency
		|		OR PaymentDecryptionTable.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                   AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN &CurrencyOfSettlementsSource = &ManagementAccountingCurrency
		|		OR PaymentDecryptionTable.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                   AS ExchangeRateDenominatorCurrencyMan,
		|
		|	CASE WHEN &FillingReceiverInSource
		|		THEN ISNULL(DimensionReceiver.DimensionKey, UNDEFINED)
		|		ELSE UNDEFINED
		|	END                                                   AS DestinationAccountingDimensionByPartners,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsReceivers.Ref
		|		ELSE UNDEFINED
		|	END                                                   AS CalculationObjectReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &CurrencyOfMutualSettlementsReceiver
		|		ELSE UNDEFINED
		|	END                                                   AS CurrencyReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &SettlementObjectReceiverPartner
		|		ELSE UNDEFINED
		|	END                                                   AS PartnerReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &SettlementObjectReceiverOrganization
		|		ELSE UNDEFINED
		|	END                                                   AS CompanyDestination,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsReceivers.Counterparty
		|		ELSE UNDEFINED
		|	END                                                   AS CounterpartyReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsReceivers.Contract
		|		ELSE UNDEFINED
		|	END                                                   AS ContractDestination,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN AreasOfActivityReceiver.DirectionOfAnalytics
		|		ELSE UNDEFINED
		|	END                                                   AS FieldOfActivityReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &AmountOfMutualSettlementsReceiver
		|		ELSE UNDEFINED
		|	END                                                   AS AmountReceiver,
		|	FALSE                                                    AS ByDataOfSourceARAPObject
		|FROM
		|	#PaymentDecryptionTable AS PaymentDecryptionTable
		|		INNER JOIN Catalog.ARAPObjects AS CalculationObjectsSources
		|			ON PaymentDecryptionTable.CalculationObjectSource = CalculationObjectsSources.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = CalculationObjectsSources.Contract
		|		INNER JOIN Catalog.ARAPObjects AS CalculationObjectsReceivers
		|			ON PaymentDecryptionTable.CalculationObjectReceiver = CalculationObjectsReceivers.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractDataReceiver
		|			ON ContractDataReceiver.Ref = CalculationObjectsReceivers.Contract
		|		INNER JOIN TTLinesOfBusiness AS AreasOfActivitySource
		|			ON CalculationObjectsSources.Ref = AreasOfActivitySource.ARAPObject
		|		INNER JOIN TTLinesOfBusiness AS AreasOfActivityReceiver
		|			ON CalculationObjectsReceivers.Ref = AreasOfActivityReceiver.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionSource
		|			ON &SettlementObjectSourceOrganization = DimensionSource.Organization
		|				AND CalculationObjectsSources.Counterparty = DimensionSource.Counterparty
		|				AND &SettlementObjectSourcePartner = DimensionSource.Partner
		|				AND CalculationObjectsSources.Contract = DimensionSource.Contract
		|				AND AreasOfActivitySource.DirectionOfAnalytics = DimensionSource.LineOfBusiness
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionReceiver
		|			ON &SettlementObjectReceiverOrganization = DimensionReceiver.Organization
		|				AND CalculationObjectsReceivers.Counterparty = DimensionReceiver.Counterparty
		|				AND &SettlementObjectReceiverPartner = DimensionReceiver.Partner
		|				AND CalculationObjectsReceivers.Contract = DimensionReceiver.Contract
		|				AND AreasOfActivityReceiver.DirectionOfAnalytics = DimensionReceiver.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = PaymentDecryptionTable.Ref
		|				AND Coefficients.ARAPObject = PaymentDecryptionTable.CalculationObjectSource
		|				AND Coefficients.ARAPCurrency = &CurrencyOfSettlementsSource
		|				AND Coefficients.DateOfCourse = PaymentDecryptionTable.DateOfCourse
		|WHERE
		|	&AmountOfSettlementsSource > 0
		|	AND &OperationCondition
		|
		|
		|UNION ALL
		|
		|SELECT
		|	PaymentDecryptionTable.RecorderDate              AS Period,
		|	CASE
		|		WHEN NOT &StornoReceiver AND &AccountsPayable
		|			OR &StornoReceiver AND NOT &AccountsPayable
		|			THEN VALUE(AccumulationRecordType.Expense)
		|		ELSE VALUE(AccumulationRecordType.Receipt)
		|	END                                                   AS RecordType,
		|	
		|	ISNULL(DimensionReceiver.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.CalculationObjectReceiver        AS ARAPObject,
		|	&CurrencyOfMutualSettlementsReceiver                           AS Currency,
		|	
		|	(&AmountOfMutualSettlementsReceiver *
		|		CASE WHEN &StornoReceiver THEN -1 ELSE 1 END) AS Sum,
		|	(&ReceiverForPayment *
		|		CASE WHEN &StornoReceiver THEN -1 ELSE 1 END) AS AmountDue,
		|	0                                                       AS BeingPaid,
		|	0                                                       AS ToShip,
		|	0                                                       AS BeingShipped,
		|	
		|	&BusinessOperation                                  AS BusinessOperation,
		|	&PaymentMethod                                            AS PaymentMethod,
		|	UNDEFINED                                            AS ProformaInvoice,
		|	UNDEFINED                                            AS SaleByOrder,
		|	PaymentDecryptionTable.RecorderDate              AS RecorderDate,
		|	&PaymentDate                                            AS PaymentDate,
		|	
		|	(CASE WHEN &CurrencyOfMutualSettlementsReceiver = Coefficients.LocalAccountingCurrency
		|				THEN &AmountOfMutualSettlementsReceiver
		|			WHEN PaymentDecryptionTable.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN PaymentDecryptionTable.Sum
		|			ELSE CAST(PaymentDecryptionTable.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END*
		|		CASE WHEN &StornoReceiver THEN -1 ELSE 1 END) AS SumCompl,
		|	(CASE WHEN &CurrencyOfMutualSettlementsReceiver = &ManagementAccountingCurrency
		|				THEN &AmountOfMutualSettlementsReceiver
		|			WHEN PaymentDecryptionTable.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN PaymentDecryptionTable.Sum
		|			ELSE CAST(PaymentDecryptionTable.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END*
		|		CASE WHEN &StornoReceiver THEN -1 ELSE 1 END) AS SumMan,
		|
		|	&ExcludeDuringControl                                    AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0) AS AllowableAmountPayable,
		|	0                                                       AS DepositForPackage,
		|	&CashFlowItem                          AS CashFlowItem,
		|	UNDEFINED                                            AS ARAPDocument,
		|	UNDEFINED                                            AS LinkedDocument,
		|	&PaymentOption                                          AS PaymentOption,
		|	PaymentDecryptionTable.DocumentCurrency               AS DocumentCurrency,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsSources.Ref
		|		ELSE UNDEFINED
		|	END                                                   AS CorARAPObject,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN ISNULL(DimensionSource.DimensionKey, UNDEFINED)
		|		ELSE UNDEFINED
		|	END                                                   AS CorPartnerAccountingDimension,
		|	
		|	&SettlementObjectReceiverOrganization                      AS Organization,
		|	&SettlementObjectReceiverPartner                          AS Partner,
		|	CalculationObjectsReceivers.Counterparty                     AS Counterparty,
		|	CalculationObjectsReceivers.Contract                        AS Contract,
		|	AreasOfActivityReceiver.DirectionOfAnalytics    AS LineOfBusiness,
		|
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &SettlementObjectSourcePartner
		|		ELSE UNDEFINED
		|	END                                                   AS CorPartner,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &SettlementObjectSourceOrganization
		|		ELSE UNDEFINED
		|	END                                                   AS CorCompany,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsSources.Counterparty
		|		ELSE UNDEFINED
		|	END                                                   AS CorCounterparty,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsSources.Contract
		|		ELSE UNDEFINED
		|	END                                                   AS CorContract,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN AreasOfActivitySource.DirectionOfAnalytics
		|		ELSE UNDEFINED
		|	END                                                   AS CorLineOfBusiness,
		|
		|	PaymentDecryptionTable.RecorderNumber             AS RecorderNumber,
		|	&FinRecordID                                 AS FinRecordID,
		|	UNDEFINED                                            AS PaymentRequest,
		|	&TypeOfOperationForSorting                               AS TypeOfOperationForSorting,
		|	&OrderOfOperationsWithinDocumentReceiver              AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.TransferOfSettlements) AS SettlementTransaction,
		|	&BusinessTransactionSetting                         AS BusinessTransactionSetting,
		|
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = Coefficients.LocalAccountingCurrency
		|		OR PaymentDecryptionTable.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                   AS RateARAPCurrencyNumerator,
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = Coefficients.LocalAccountingCurrency
		|		OR PaymentDecryptionTable.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                   AS RateARAPCurrencyDenominator,
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = &ManagementAccountingCurrency
		|		OR PaymentDecryptionTable.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                   AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = &ManagementAccountingCurrency
		|		OR PaymentDecryptionTable.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                   AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                            AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                            AS CalculationObjectReceiver,
		|	UNDEFINED                                            AS CurrencyReceiver,
		|	UNDEFINED                                            AS PartnerReceiver,
		|	UNDEFINED                                            AS CompanyDestination,
		|	UNDEFINED                                            AS CounterpartyReceiver,
		|	UNDEFINED                                            AS ContractDestination,
		|	UNDEFINED                                            AS FieldOfActivityReceiver,
		|	0                                                       AS AmountReceiver,
		|	&FillingReceiverInSource                            AS ByDataOfSourceARAPObject
		|FROM
		|	#PaymentDecryptionTable AS PaymentDecryptionTable
		|		INNER JOIN Catalog.ARAPObjects AS CalculationObjectsSources
		|			ON PaymentDecryptionTable.CalculationObjectSource = CalculationObjectsSources.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractDataSource
		|			ON ContractDataSource.Ref = CalculationObjectsSources.Contract
		|		INNER JOIN Catalog.ARAPObjects AS CalculationObjectsReceivers
		|			ON PaymentDecryptionTable.CalculationObjectReceiver = CalculationObjectsReceivers.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = CalculationObjectsReceivers.Contract
		|		INNER JOIN TTLinesOfBusiness AS AreasOfActivitySource
		|			ON CalculationObjectsSources.Ref = AreasOfActivitySource.ARAPObject
		|		INNER JOIN TTLinesOfBusiness AS AreasOfActivityReceiver
		|			ON CalculationObjectsReceivers.Ref = AreasOfActivityReceiver.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionReceiver
		|			ON &SettlementObjectReceiverOrganization = DimensionReceiver.Organization
		|				AND CalculationObjectsReceivers.Counterparty = DimensionReceiver.Counterparty
		|				AND &SettlementObjectReceiverPartner = DimensionReceiver.Partner
		|				AND CalculationObjectsReceivers.Contract = DimensionReceiver.Contract
		|				AND AreasOfActivityReceiver.DirectionOfAnalytics = DimensionReceiver.LineOfBusiness
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionSource
		|			ON &SettlementObjectSourceOrganization = DimensionSource.Organization
		|				AND CalculationObjectsSources.Counterparty = DimensionSource.Counterparty
		|				AND &SettlementObjectSourcePartner = DimensionSource.Partner
		|				AND CalculationObjectsSources.Contract = DimensionSource.Contract
		|				AND AreasOfActivitySource.DirectionOfAnalytics = DimensionSource.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = PaymentDecryptionTable.Ref
		|				AND Coefficients.ARAPObject = PaymentDecryptionTable.CalculationObjectReceiver
		|				AND Coefficients.ARAPCurrency = &CurrencyOfMutualSettlementsReceiver
		|				AND Coefficients.DateOfCourse = PaymentDecryptionTable.DateOfCourse
		|WHERE
		|	&AmountOfMutualSettlementsReceiver > 0
		|	AND &OperationCondition
		|";
	#EndRegion
	
	QueryText = StrReplace(QueryText,"&OperationCondition",OperationCondition);
	
	QueryText = StrReplace(QueryText,"&AccountsPayable", AccountsPayable);
	QueryText = StrReplace(QueryText,"&StornoSource",            StornoSource);
	QueryText = StrReplace(QueryText,"&StornoReceiver",StornoReceiver);
	
	QueryText = StrReplace(QueryText,"&ForPaymentSource",ForPaymentSource);
	
	QueryText = StrReplace(QueryText, "&BusinessOperation", BusinessOperation);
	QueryText = StrReplace(QueryText,"&PaymentMethod",PaymentMethod);
	
	QueryText = StrReplace(QueryText,"&ReceiverForPayment",ReceiverForPayment);
	
	QueryText = StrReplace(QueryText,"&SettlementObjectSourceOrganization", SettlementObjectSourceOrganization);
	QueryText = StrReplace(QueryText,"&SettlementObjectReceiverOrganization", SettlementObjectReceiverOrganization);
	
	QueryText = StrReplace(QueryText,"&SettlementObjectSourcePartner", SettlementObjectSourcePartner);
	QueryText = StrReplace(QueryText,"&SettlementObjectReceiverPartner", SettlementObjectReceiverPartner);
	
	QueryText = StrReplace(QueryText,"&CurrencyOfSettlementsSource",CurrencyOfSettlementsSource);
	QueryText = StrReplace(QueryText,"&CurrencyOfMutualSettlementsReceiver",CurrencyOfMutualSettlementsReceiver);
	QueryText = StrReplace(QueryText,"&AmountOfSettlementsSource",AmountOfSettlementsSource);
	QueryText = StrReplace(QueryText,"&AmountOfMutualSettlementsReceiver",AmountOfMutualSettlementsReceiver);
	
	QueryText = StrReplace(QueryText,"&PaymentDate", PaymentDate);
	QueryText = StrReplace(QueryText,"&PaymentOption", PaymentOption);
	QueryText = StrReplace(QueryText,"&CashFlowItem", CashFlowItem);
	
	QueryText = StrReplace(QueryText,"&FillingReceiverInSource", FillingReceiverInSource);
	
	QueryText = StrReplace(QueryText,"&FinRecordID",          FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting",  BusinessTransactionSetting);
	
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting", TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&OrderOfOperationsWithinDocumentSource", OrderOfOperationsWithinDocument);
	QueryText = StrReplace(QueryText,"&OrderOfOperationsWithinDocumentReceiver", String(Number(OrderOfOperationsWithinDocument)+1));
	
	QueryText = StrReplace(QueryText,"&ExcludeDuringControl", ExcludeDuringControl);
	
	QueryText = StrReplace(QueryText,"&ApplicationSource", ApplicationSource);
	
	If Operation = "ReschedulingSale" Or Operation = "TransferOfPaymentUnderCentralizedContract" Or Operation = "PostponementOfReturnOfGoodsUnderCentralizedContract" Then
		QueryText = StrReplace(QueryText,"#PaymentDecryptionTable",  "TTTransferOfPaymentsClient");
		QueryText = StrReplace(QueryText,"PaymentDecryptionTable",  "TransferOfCalculations");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextTransferOfCustomerDebtBetweenBranches(TypeOfOperationForSorting)
	
	QueryText = "
		|SELECT
		|	IncreasingCustomerDebt.RecorderDate         AS Period,
		|	VALUE(AccumulationRecordType.Expense)                  AS RecordType,
		|	
		|	ISNULL(DimensionSource.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
		|	IncreasingCustomerDebt.ARAPObject           AS ARAPObject,
		|	IncreasingCustomerDebt.ARAPCurrency     AS Currency,
		|	
		|	IncreasingCustomerDebt.AmountARAP      AS Sum,
		|	0                                                       AS AmountDue,
		|	0                                                       AS BeingPaid,
		|	0                                                       AS ToShip,
		|	0                                                       AS BeingShipped,
		|	
		|	VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices) AS BusinessOperation,
		|	UNDEFINED                                            AS PaymentMethod,
		|	UNDEFINED                                            AS ProformaInvoice,
		|	IncreasingCustomerDebt.SalesOrder_             AS SaleByOrder,
		|	IncreasingCustomerDebt.RecorderDate         AS RecorderDate,
		|	IncreasingCustomerDebt.PaymentDate              AS PaymentDate,
		|	
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingCustomerDebt.AmountARAP
		|			WHEN IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingCustomerDebt.Sum
		|			ELSE CAST(IncreasingCustomerDebt.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END AS SumCompl,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingCustomerDebt.AmountARAP
		|			WHEN IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingCustomerDebt.Sum
		|			ELSE CAST(IncreasingCustomerDebt.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END AS SumMan,
		|
		|	FALSE                                                    AS ExcludeDuringControl,
		|	ContractData.AllowableAmountPayable             AS AllowableAmountPayable,
		|	0                                                       AS DepositForPackage,
		|	UNDEFINED                                            AS CashFlowItem,
		|	UNDEFINED                                            AS ARAPDocument,
		|	UNDEFINED                                            AS LinkedDocument,
		|	IncreasingCustomerDebt.PaymentOption            AS PaymentOption,
		|	IncreasingCustomerDebt.DocumentCurrency          AS DocumentCurrency,
		|	UNDEFINED                                            AS CorARAPObject,
		|	UNDEFINED                                            AS CorPartnerAccountingDimension,
		|	
		|	IncreasingCustomerDebt.Organization              AS Organization,
		|	IncreasingCustomerDebt.Partner                  AS Partner,
		|	DataCenterARAPObject.Counterparty                             AS Counterparty,
		|	DataCenterARAPObject.Contract                                AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics            AS LineOfBusiness,
		|
		|	UNDEFINED                                            AS CorPartner,
		|	UNDEFINED                                            AS CorCompany,
		|	UNDEFINED                                            AS CorCounterparty,
		|	UNDEFINED                                            AS CorContract,
		|	UNDEFINED                                            AS CorLineOfBusiness,
		|	IncreasingCustomerDebt.RecorderNumber        AS RecorderNumber,
		|	DataCenterARAPObject.UUID                AS FinRecordID,
		|	UNDEFINED                                            AS PaymentRequest,
		|	&TypeOfOperationForSorting                               AS TypeOfOperationForSorting,
		|	5                                                       AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.TransferOfSettlements) AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.DebtTransferBetweenBranchOffices) AS BusinessTransactionSetting,
		|
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                   AS RateARAPCurrencyNumerator,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                   AS RateARAPCurrencyDenominator,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                   AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                   AS ExchangeRateDenominatorCurrencyMan,
		|
		|	ISNULL(DimensionReceiver.DimensionKey, UNDEFINED) AS DestinationAccountingDimensionByPartners,
		|	DataCenterARAPObject.Ref                                 AS CalculationObjectReceiver,
		|	DataCenterARAPObject.ARAPCurrency                   AS CurrencyReceiver,
		|	IncreasingCustomerDebt.Partner                  AS PartnerReceiver,
		|	DataCenterARAPObject.Organization                            AS CompanyDestination,
		|	DataCenterARAPObject.Counterparty                             AS CounterpartyReceiver,
		|	DataCenterARAPObject.Contract                                AS ContractDestination,
		|	LinesOfBusiness.DirectionOfAnalytics            AS FieldOfActivityReceiver,
		|	IncreasingCustomerDebt.AmountARAP      AS AmountReceiver,
		|	FALSE                                                    AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreasingCustomerDebt AS IncreasingCustomerDebt
		|		INNER JOIN Catalog.ARAPObjects AS DataCenterARAPObject
		|			ON IncreasingCustomerDebt.ARAPObject = DataCenterARAPObject.Ref
		|		INNER JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = DataCenterARAPObject.Contract
		|				AND ContractData.CentralizedContract
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON DataCenterARAPObject.Ref = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionReceiver
		|			ON DataCenterARAPObject.Organization = DimensionReceiver.Organization
		|				AND DataCenterARAPObject.Counterparty = DimensionReceiver.Counterparty
		|				AND IncreasingCustomerDebt.Partner = DimensionReceiver.Partner
		|				AND DataCenterARAPObject.Contract = DimensionReceiver.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = DimensionReceiver.LineOfBusiness
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionSource
		|			ON IncreasingCustomerDebt.Organization = DimensionSource.Organization
		|				AND DataCenterARAPObject.Counterparty = DimensionSource.Counterparty
		|				AND IncreasingCustomerDebt.Partner = DimensionSource.Partner
		|				AND DataCenterARAPObject.Contract = DimensionSource.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = DimensionSource.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = IncreasingCustomerDebt.Ref
		|				AND Coefficients.ARAPObject = IncreasingCustomerDebt.ARAPObject
		|				AND Coefficients.ARAPCurrency = IncreasingCustomerDebt.ARAPCurrency
		|				AND Coefficients.DateOfCourse = IncreasingCustomerDebt.DateOfCourse
		|WHERE
		|	IncreasingCustomerDebt.AmountARAP > 0
		|	AND IncreasingCustomerDebt.Organization <> DataCenterARAPObject.Organization
		|
		|UNION ALL
		|
		|SELECT
		|	IncreasingCustomerDebt.RecorderDate         AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                  AS RecordType,
		|	
		|	ISNULL(DimensionReceiver.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
		|	IncreasingCustomerDebt.ARAPObject           AS ARAPObject,
		|	IncreasingCustomerDebt.ARAPCurrency     AS Currency,
		|	
		|	IncreasingCustomerDebt.AmountARAP      AS Sum,
		|	0                                                       AS AmountDue,
		|	0                                                       AS BeingPaid,
		|	0                                                       AS ToShip,
		|	0                                                       AS BeingShipped,
		|	
		|	VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices) AS BusinessOperation,
		|	UNDEFINED                                            AS PaymentMethod,
		|	UNDEFINED                                            AS ProformaInvoice,
		|	IncreasingCustomerDebt.SalesOrder_             AS SaleByOrder,
		|	IncreasingCustomerDebt.RecorderDate         AS RecorderDate,
		|	IncreasingCustomerDebt.PaymentDate              AS PaymentDate,
		|	
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingCustomerDebt.AmountARAP
		|			WHEN IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingCustomerDebt.Sum
		|			ELSE CAST(IncreasingCustomerDebt.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END AS SumCompl,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingCustomerDebt.AmountARAP
		|			WHEN IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingCustomerDebt.Sum
		|			ELSE CAST(IncreasingCustomerDebt.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END AS SumMan,
		|
		|	FALSE                                                    AS ExcludeDuringControl,
		|	ContractData.AllowableAmountPayable             AS AllowableAmountPayable,
		|	0                                                       AS DepositForPackage,
		|	UNDEFINED                                            AS CashFlowItem,
		|	UNDEFINED                                            AS ARAPDocument,
		|	UNDEFINED                                            AS LinkedDocument,
		|	IncreasingCustomerDebt.PaymentOption            AS PaymentOption,
		|	IncreasingCustomerDebt.DocumentCurrency          AS DocumentCurrency,
		|	DataCenterARAPObject.Ref                                 AS CorARAPObject,
		|	ISNULL(DimensionSource.DimensionKey, UNDEFINED) AS CorPartnerAccountingDimension,
		|	
		|	DataCenterARAPObject.Organization                            AS Organization,
		|	IncreasingCustomerDebt.Partner                  AS Partner,
		|	DataCenterARAPObject.Counterparty                             AS Counterparty,
		|	DataCenterARAPObject.Contract                                AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics            AS LineOfBusiness,
		|
		|	IncreasingCustomerDebt.Partner                  AS CorPartner,
		|	IncreasingCustomerDebt.Organization              AS CorCompany,
		|	DataCenterARAPObject.Counterparty                             AS CorCounterparty,
		|	DataCenterARAPObject.Contract                                AS CorContract,
		|	LinesOfBusiness.DirectionOfAnalytics            AS CorLineOfBusiness,
		|
		|	IncreasingCustomerDebt.RecorderNumber        AS RecorderNumber,
		|	DataCenterARAPObject.UUID                AS FinRecordID,
		|	UNDEFINED                                            AS PaymentRequest,
		|	&TypeOfOperationForSorting                               AS TypeOfOperationForSorting,
		|	5                                                       AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.TransferOfSettlements) AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.DebtTransferBetweenBranchOffices) AS BusinessTransactionSetting,
		|
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                   AS RateARAPCurrencyNumerator,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                   AS RateARAPCurrencyDenominator,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                   AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                   AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                            AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                            AS CalculationObjectReceiver,
		|	UNDEFINED                                            AS CurrencyReceiver,
		|	UNDEFINED                                            AS PartnerReceiver,
		|	UNDEFINED                                            AS CompanyDestination,
		|	UNDEFINED                                            AS CounterpartyReceiver,
		|	UNDEFINED                                            AS ContractDestination,
		|	UNDEFINED                                            AS FieldOfActivityReceiver,
		|	0                                                       AS AmountReceiver,
		|	TRUE                                                  AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreasingCustomerDebt AS IncreasingCustomerDebt
		|		INNER JOIN Catalog.ARAPObjects AS DataCenterARAPObject
		|			ON IncreasingCustomerDebt.ARAPObject = DataCenterARAPObject.Ref
		|		INNER JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = DataCenterARAPObject.Contract
		|				AND ContractData.CentralizedContract
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON DataCenterARAPObject.Ref = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionReceiver
		|			ON DataCenterARAPObject.Organization = DimensionReceiver.Organization
		|				AND DataCenterARAPObject.Counterparty = DimensionReceiver.Counterparty
		|				AND IncreasingCustomerDebt.Partner = DimensionReceiver.Partner
		|				AND DataCenterARAPObject.Contract = DimensionReceiver.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = DimensionReceiver.LineOfBusiness
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionSource
		|			ON IncreasingCustomerDebt.Organization = DimensionSource.Organization
		|				AND DataCenterARAPObject.Counterparty = DimensionSource.Counterparty
		|				AND IncreasingCustomerDebt.Partner = DimensionSource.Partner
		|				AND DataCenterARAPObject.Contract = DimensionSource.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = DimensionSource.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = IncreasingCustomerDebt.Ref
		|				AND Coefficients.ARAPObject = IncreasingCustomerDebt.ARAPObject
		|				AND Coefficients.ARAPCurrency = IncreasingCustomerDebt.ARAPCurrency
		|				AND Coefficients.DateOfCourse = IncreasingCustomerDebt.DateOfCourse
		|WHERE
		|	IncreasingCustomerDebt.AmountARAP > 0
		|	AND IncreasingCustomerDebt.Organization <> DataCenterARAPObject.Organization
		|";
	
	QueryText = StrReplace(QueryText, "&TypeOfOperationForSorting", TypeOfOperationForSorting);
	Return QueryText;
	
EndFunction

Function IncreasePaymentPlanFromCustomer(Query, Operation, TypeOfOperationForSorting)
	
	If Operation = "ClientExecutionSchedule" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "FALSE";
		Period = "ENDOFPERIOD(CustomerPaymentPlanIncrease.PaymentDate, DAY)";
		
		ARAPObjectSettings = "VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)";
		InvoiceForOrders = "FALSE";
		ExceedingOrder = "FALSE";
		SalesOrder_ = "Undefined";
		
		AmountDue = "CustomerPaymentPlanIncrease.AmountDue";
		
		PaymentMethod = "Undefined";
		CashFlowItem = "Undefined";
		PaymentDate = "ENDOFPERIOD(CustomerPaymentPlanIncrease.PaymentDate, DAY)";
		MeasuringGoodsVarianceAmount = "0";
		PaymentOption = "CustomerPaymentPlanIncrease.PaymentOption";
		ExcludeDuringControl = "CustomerPaymentPlanIncrease.ExcludeDuringControl";
		LinkedDocument = "Undefined";
		FinRecordID = "&IDOfUnusedFinRecord";
		BusinessTransactionSetting = "Undefined";
		//View = "1";
		
	ElsIf Operation = "SalesOrder" Then
		
		ThisIsOrder = "TRUE";
		ThisIsAnInvoice = "FALSE";
		Period = "ENDOFPERIOD(CustomerPaymentPlanIncrease.PaymentDate, DAY)";
		
		ARAPObjectSettings = "CustomerPaymentPlanIncrease.ARAPObjectSettings";
		InvoiceForOrders = "FALSE";
		ExceedingOrder = "FALSE";
		SalesOrder_ = "Undefined";
		
		AmountDue = "CustomerPaymentPlanIncrease.AmountDue";
		
		PaymentMethod = "CustomerPaymentPlanIncrease.PaymentMethod";
		CashFlowItem = "Undefined";
		PaymentDate = "ENDOFPERIOD(CustomerPaymentPlanIncrease.PaymentDate, DAY)";
		MeasuringGoodsVarianceAmount = "CustomerPaymentPlanIncrease.MeasuringGoodsVarianceAmount";
		PaymentOption = "CustomerPaymentPlanIncrease.PaymentOption";
		ExcludeDuringControl = "
		|CASE 
		|	WHEN CustomerPaymentPlanIncrease.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|		THEN TRUE
		|	ELSE CustomerPaymentPlanIncrease.ExcludeDuringControl
		|END";
		LinkedDocument = "Undefined";
		FinRecordID = "&IDOfUnusedFinRecord";
		BusinessTransactionSetting = "Undefined";
		
	ElsIf Operation = "Sale" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "TRUE";
		Period = "CASE WHEN CustomerPaymentPlanIncrease.AmountDue < 0 OR CustomerPaymentPlanIncrease.PaymentDate < CustomerPaymentPlanIncrease.RecorderDate
				|		THEN CustomerPaymentPlanIncrease.RecorderDate
				|	ELSE ENDOFPERIOD(CustomerPaymentPlanIncrease.PaymentDate, DAY)
				|END";
		
		ARAPObjectSettings = "CustomerPaymentPlanIncrease.ARAPObjectSettings";
		InvoiceForOrders = "CustomerPaymentPlanIncrease.InvoiceForOrders";
		ExceedingOrder = "CustomerPaymentPlanIncrease.ExceedingOrder";
		SalesOrder_ = "CASE WHEN NOT CustomerPaymentPlanIncrease.ExceedingOrder
						|		THEN CustomerPaymentPlanIncrease.SalesOrder_
						|	ELSE UNDEFINED
						|END";
		
		AmountDue = "CustomerPaymentPlanIncrease.AmountDue";
		
		PaymentMethod = "CustomerPaymentPlanIncrease.PaymentMethod";
		CashFlowItem = "Undefined";
		
		PaymentDate = "CASE WHEN CustomerPaymentPlanIncrease.AmountDue < 0 
				|		THEN DATETIME(1,1,1)
				|	ELSE CustomerPaymentPlanIncrease.PaymentDate
				|END";
		
		MeasuringGoodsVarianceAmount = "0";
		PaymentOption = "CustomerPaymentPlanIncrease.PaymentOption";
		ExcludeDuringControl = "CustomerPaymentPlanIncrease.ExcludeDuringControl";
		LinkedDocument = "CustomerPaymentPlanIncrease.LinkedDocument";
		FinRecordID = "CustomerPaymentPlanIncrease.ARAPObject.UUID";
		BusinessTransactionSetting = "Undefined";
		
	ElsIf Operation = "RefundToCustomer" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "FALSE";
		Period = "CustomerPaymentPlanIncrease.RecorderDate";
		
		ARAPObjectSettings = "Undefined";
		InvoiceForOrders = "FALSE";
		ExceedingOrder = "FALSE";
		SalesOrder_ = "Undefined";
		
		AmountDue = "CustomerPaymentPlanIncrease.AmountARAP";
		
		PaymentMethod = "CustomerPaymentPlanIncrease.PaymentMethod";
		CashFlowItem = "CustomerPaymentPlanIncrease.CashFlowItem";
		PaymentDate = "DATETIME(1,1,1)";
		MeasuringGoodsVarianceAmount = "0";
		PaymentOption = "Undefined";
		ExcludeDuringControl = "TRUE";
		LinkedDocument = "Undefined";
		FinRecordID = "CustomerPaymentPlanIncrease.FinRecordID";
		BusinessTransactionSetting = "CustomerPaymentPlanIncrease.BusinessTransactionSetting";
		
	EndIf;
	
	QueryText =
		"SELECT
		|	&Period                                                          AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	CustomerPaymentPlanIncrease.ARAPObject                     AS ARAPObject,
		|	CustomerPaymentPlanIncrease.ARAPCurrency               AS Currency,
		|	
		|	0                                                                AS Sum,
		|	&AmountDue                                                         AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS ToShip,
		|	0                                                                AS BeingShipped,
		|	
		|	CustomerPaymentPlanIncrease.BusinessOperation              AS BusinessOperation,
		|	&PaymentMethod                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS ProformaInvoice,
		|	&SalesOrder_                                                    AS SaleByOrder,
		|	CustomerPaymentPlanIncrease.RecorderDate                   AS RecorderDate,
		|	&PaymentDate                                                     AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	&ExcludeDuringControl                                            AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0)         AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	&CashFlowItem                                   AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	&LinkedDocument                                               AS LinkedDocument,
		|	&PaymentOption                                                   AS PaymentOption,
		|	CustomerPaymentPlanIncrease.DocumentCurrency                    AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	
		|	CustomerPaymentPlanIncrease.ARAPObject.Organization         AS Organization,
		|	CustomerPaymentPlanIncrease.Partner                            AS Partner,
		|	CustomerPaymentPlanIncrease.ARAPObject.Counterparty          AS Counterparty,
		|	CustomerPaymentPlanIncrease.ARAPObject.Contract             AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	CustomerPaymentPlanIncrease.RecorderNumber                  AS RecorderNumber,
		|	&FinRecordID                                          AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	&BusinessTransactionSetting                                  AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#CustomerPaymentPlanIncrease AS CustomerPaymentPlanIncrease
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON CustomerPaymentPlanIncrease.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = CustomerPaymentPlanIncrease.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CustomerPaymentPlanIncrease.ARAPObject.Organization = Dimension.Organization
		|				AND CustomerPaymentPlanIncrease.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND CustomerPaymentPlanIncrease.Partner = Dimension.Partner
		|				AND CustomerPaymentPlanIncrease.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	&AmountDue <> 0
		|	//When making payments under a contract with a schedule, the payment plan does not increase
		|	AND NOT (&ThisIsOrder
		|			AND ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)
		|			AND ISNULL(ContractData.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) 
		|				IN (VALUE(Enum.ContractTypes.WithCustomer),
		|					VALUE(Enum.ContractTypes.WithConsignee),
		|					VALUE(Enum.ContractTypes.ReceiptForTolling))
		|			AND &ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		|	//An order with calculations not based on invoices
		|	AND (&ThisIsOrder AND &ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|		OR &ThisIsAnInvoice
		|		// Contract execution schedule, refund of payment
		|		OR NOT (&ThisIsAnInvoice OR &ThisIsOrder)
		|		)
		|
		|
		|UNION ALL
		|
		|SELECT
		|	&Period                                                         AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                          AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                 AS AccountingDimensionByPartners,
		|	CustomerPaymentPlanIncrease.ARAPObject                    AS ARAPObject,
		|	CustomerPaymentPlanIncrease.ARAPCurrency              AS Currency,
		|	
		|	0                                                               AS Sum,
		|	&MeasuringGoodsVarianceAmount                                   AS AmountDue,
		|	0                                                               AS BeingPaid,
		|	0                                                               AS ToShip,
		|	0                                                               AS BeingShipped,
		|
		|	CustomerPaymentPlanIncrease.BusinessOperation             AS BusinessOperation,
		|	&PaymentMethod                                                    AS PaymentMethod,
		|	UNDEFINED                                                    AS ProformaInvoice,
		|	UNDEFINED                                                    AS SaleByOrder,
		|	CustomerPaymentPlanIncrease.RecorderDate                  AS RecorderDate,
		|	&PaymentDate                                                    AS PaymentDate,
		|	0                                                               AS SumCompl,
		|	0                                                               AS SumMan,
		|	TRUE                                                          AS ExcludeDuringControl,
		|	0                                                               AS AllowableAmountPayable,
		|	0                                                               AS DepositForPackage,
		|	UNDEFINED                                                    AS CashFlowItem,
		|	UNDEFINED                                                    AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	&PaymentOption                                                   AS PaymentOption,
		|	CustomerPaymentPlanIncrease.DocumentCurrency                    AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	   
		|	CustomerPaymentPlanIncrease.ARAPObject.Organization         AS Organization,
		|	CustomerPaymentPlanIncrease.ARAPObject.Partner             AS Partner,
		|	CustomerPaymentPlanIncrease.ARAPObject.Counterparty          AS Counterparty,
		|	CustomerPaymentPlanIncrease.ARAPObject.Contract             AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	CustomerPaymentPlanIncrease.RecorderNumber                  AS RecorderNumber,
		|	&FinRecordID                                          AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	&BusinessTransactionSetting                                  AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#CustomerPaymentPlanIncrease AS CustomerPaymentPlanIncrease
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON CustomerPaymentPlanIncrease.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CustomerPaymentPlanIncrease.ARAPObject.Organization = Dimension.Organization
		|				AND CustomerPaymentPlanIncrease.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND CustomerPaymentPlanIncrease.ARAPObject.Partner = Dimension.Partner
		|				AND CustomerPaymentPlanIncrease.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	&MeasuringGoodsVarianceAmount <> 0
		|	AND &ThisIsOrder AND NOT &ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|";
	
	QueryText = StrReplace(QueryText,"&ARAPObjectSettings",ARAPObjectSettings);
	QueryText = StrReplace(QueryText,"&PaymentMethod",PaymentMethod);
	QueryText = StrReplace(QueryText,"&MeasuringGoodsVarianceAmount",MeasuringGoodsVarianceAmount);
	QueryText = StrReplace(QueryText,"&ThisIsOrder",ThisIsOrder);
	QueryText = StrReplace(QueryText,"&ThisIsAnInvoice",ThisIsAnInvoice);
	QueryText = StrReplace(QueryText,"&InvoiceForOrders", InvoiceForOrders);
	QueryText = StrReplace(QueryText,"&ExceedingOrder", ExceedingOrder);
	QueryText = StrReplace(QueryText,"&SalesOrder_", SalesOrder_);
	QueryText = StrReplace(QueryText,"&CashFlowItem", CashFlowItem);
	QueryText = StrReplace(QueryText,"&AmountDue", AmountDue);
	QueryText = StrReplace(QueryText,"&Period", Period);
	QueryText = StrReplace(QueryText,"&PaymentDate", PaymentDate);
	QueryText = StrReplace(QueryText,"&PaymentOption", PaymentOption);
	QueryText = StrReplace(QueryText,"&ExcludeDuringControl", ExcludeDuringControl);
	QueryText = StrReplace(QueryText,"&LinkedDocument", LinkedDocument);
	QueryText = StrReplace(QueryText,"&FinRecordID", FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting", BusinessTransactionSetting);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting", TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function ReducePaymentPlanFromCustomer(Operation, TypeOfOperationForSorting, OrderOfOperationsWithinDocument = "1", InvoiceForOrders = False) Export

	If Operation = "ReturnOfGoods" Then
		
		ProformaInvoice = "Undefined";
		PaymentMethod = "Undefined";
		CashFlowItem = "Undefined";
		AmountDue = "ReductionOfPaymentPlanFromCustomer.AmountDue";
		LinkedDocument = "Undefined";
		FinRecordID = "ReductionOfPaymentPlanFromCustomer.ARAPObject.UUID";
		BusinessTransactionSetting = "Undefined";
		SaleByOrder = "Undefined";
		ARAPObject = "ReductionOfPaymentPlanFromCustomer.ARAPObject";
		OperationCondition = "TRUE";
		Organization = "ReductionOfPaymentPlanFromCustomer.Organization";
		PaymentOption = "Undefined";
	ElsIf Operation = "Sale" Then
		
		ProformaInvoice = "Undefined";
		PaymentMethod = "Undefined";
		CashFlowItem = "Undefined";
		LinkedDocument = "Undefined";
		BusinessTransactionSetting = "Undefined";
		AmountDue = "ReductionOfPaymentPlanFromCustomer.AmountDue";
		
		If InvoiceForOrders Then
			PaymentOption = "ReductionOfPaymentPlanFromCustomer.PaymentOption";
			FinRecordID = "CASE 
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|			THEN ReductionOfPaymentPlanFromCustomer.SalesOrder_.ARAPObject.UUID
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ContractData.ARAPObject.UUID
			|		ELSE ReductionOfPaymentPlanFromCustomer.ARAPObject.UUID
			|	END";
			
			SaleByOrder = "ReductionOfPaymentPlanFromCustomer.SalesOrder_";
			
			ARAPObject = "CASE 
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|			THEN ReductionOfPaymentPlanFromCustomer.SalesOrder_.ARAPObject
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ContractData.ARAPObject
			|		ELSE ReductionOfPaymentPlanFromCustomer.ARAPObject
			|	END";
			OperationCondition = "	(ReductionOfPaymentPlanFromCustomer.InvoiceForOrders 
			|						AND NOT ReductionOfPaymentPlanFromCustomer.ExceedingOrder 
			|						AND UseAdvancedFeaturesOfSalesOrder.Value
			|					OR ReductionOfPaymentPlanFromCustomer.ARAPObject.Contract.ExecutionScheduleIsSpecified)
			|						AND ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)";
			Organization = "CASE 
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|			THEN ReductionOfPaymentPlanFromCustomer.SalesOrder_.Organization
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ContractData.Organization
			|		ELSE ReductionOfPaymentPlanFromCustomer.ARAPObject.Organization
			|	END";
		Else
			PaymentOption = "Undefined";
			FinRecordID = "CASE 
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ContractData.ARAPObject.UUID
			|		ELSE ReductionOfPaymentPlanFromCustomer.ARAPObject.UUID
			|	END";
			SaleByOrder = "Undefined";
			ARAPObject = "CASE 
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ContractData.ARAPObject
			|		ELSE ReductionOfPaymentPlanFromCustomer.ARAPObject
			|	END";
			OperationCondition = "ReductionOfPaymentPlanFromCustomer.ARAPObject.Contract.ExecutionScheduleIsSpecified
			|		AND ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
			|		AND ReductionOfPaymentPlanFromCustomer.BusinessOperation <> VALUE(Enum.BusinessTransactions.ARAPAdjustment)";
			Organization = "CASE 
			|		WHEN ReductionOfPaymentPlanFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ContractData.Organization
			|		ELSE ReductionOfPaymentPlanFromCustomer.ARAPObject.Organization
			|	END";
		EndIf;
	ElsIf Operation = "PaymentFromCustomer" Or Operation = "OffsettingClientSCounterObligations" Then
		
		ProformaInvoice = "ReductionOfPaymentPlanFromCustomer.ProformaInvoice";
		PaymentMethod = "ReductionOfPaymentPlanFromCustomer.PaymentMethod";
		CashFlowItem = "ReductionOfPaymentPlanFromCustomer.CashFlowItem";
		AmountDue = "ReductionOfPaymentPlanFromCustomer.AmountARAP";
		LinkedDocument = "ReductionOfPaymentPlanFromCustomer.LinkedDocument";
		FinRecordID = "ReductionOfPaymentPlanFromCustomer.FinRecordID";
		BusinessTransactionSetting = "ReductionOfPaymentPlanFromCustomer.BusinessTransactionSetting";
		SaleByOrder = "Undefined";
		ARAPObject = "ReductionOfPaymentPlanFromCustomer.ARAPObject";
		OperationCondition = "TRUE";
		Organization = "ReductionOfPaymentPlanFromCustomer.Organization";
		PaymentOption = "Undefined";
		
	EndIf;
	
	QueryText =
		"SELECT
		|	ReductionOfPaymentPlanFromCustomer.RecorderDate                  AS Period,
		|	VALUE(AccumulationRecordType.Expense)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	&ARAPObject                                                  AS ARAPObject,
		|	ReductionOfPaymentPlanFromCustomer.ARAPCurrency              AS Currency,
		|	
		|	0                                                                AS Sum,
		|	(&AmountDue)                                                       AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS ToShip,
		|	0                                                                AS BeingShipped,
		|	
		|	ReductionOfPaymentPlanFromCustomer.BusinessOperation             AS BusinessOperation,
		|	&PaymentMethod                                                     AS PaymentMethod,
		|	&ProformaInvoice                                                    AS ProformaInvoice,
		|	&SaleByOrder                                                 AS SaleByOrder,
		|	ReductionOfPaymentPlanFromCustomer.RecorderDate                  AS RecorderDate,
		|	CASE WHEN &AmountDue < 0
		|			THEN BEGINOFPERIOD(ReductionOfPaymentPlanFromCustomer.RecorderDate, DAY)
		|		ELSE DATETIME(1,1,1)
		|	END                                                     AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	FALSE                                                             AS ExcludeDuringControl,
		|	0                                                                AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	&CashFlowItem                                   AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	&LinkedDocument                                               AS LinkedDocument,
		|	&PaymentOption                                                   AS PaymentOption,
		|	ReductionOfPaymentPlanFromCustomer.DocumentCurrency                   AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	
		|	&Organization                                                     AS Organization,
		|	ReductionOfPaymentPlanFromCustomer.Partner                           AS Partner,
		|	ReductionOfPaymentPlanFromCustomer.ARAPObject.Counterparty         AS Counterparty,
		|	ReductionOfPaymentPlanFromCustomer.ARAPObject.Contract            AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	ReductionOfPaymentPlanFromCustomer.RecorderNumber                 AS RecorderNumber,
		|	&FinRecordID                                          AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	&OrderOfOperationsWithinDocument                               AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	&BusinessTransactionSetting                                  AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#ReductionOfPaymentPlanFromCustomer AS ReductionOfPaymentPlanFromCustomer
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref =  ReductionOfPaymentPlanFromCustomer.ARAPObject.Contract
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON &ARAPObject = LinesOfBusiness.ARAPObject
		|		INNER JOIN Constant.UseAdvancedFeaturesOfSalesOrder AS UseAdvancedFeaturesOfSalesOrder
		|			ON TRUE
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON &Organization = Dimension.Organization
		|				AND ReductionOfPaymentPlanFromCustomer.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND ReductionOfPaymentPlanFromCustomer.Partner = Dimension.Partner
		|				AND ReductionOfPaymentPlanFromCustomer.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	&AmountDue <> 0
		|	AND &OperationCondition
		|";
	
	QueryText = StrReplace(QueryText,"&PaymentMethod",                   PaymentMethod);
	QueryText = StrReplace(QueryText,"&ProformaInvoice",                  ProformaInvoice);
	QueryText = StrReplace(QueryText,"&CashFlowItem", CashFlowItem);
	QueryText = StrReplace(QueryText,"&AmountDue",                       AmountDue);
	QueryText = StrReplace(QueryText,"&LinkedDocument",             LinkedDocument);
	QueryText = StrReplace(QueryText,"&FinRecordID",        FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting", BusinessTransactionSetting);
	QueryText = StrReplace(QueryText,"&SaleByOrder",                SaleByOrder);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",       TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&OrderOfOperationsWithinDocument", OrderOfOperationsWithinDocument);
	QueryText = StrReplace(QueryText,"&ARAPObject",                 ARAPObject);
	QueryText = StrReplace(QueryText,"&OperationCondition",                OperationCondition);
	QueryText = StrReplace(QueryText,"&Organization",                    Organization);
	QueryText = StrReplace(QueryText,"&PaymentOption",                  PaymentOption);
	
	Return QueryText;
	
EndFunction

Function IncreaseCustomerDebt(Operation, TypeOfOperationForSorting)

	If Operation = "Sale" Then
		
		SalesOrder_ = "CASE WHEN NOT IncreasingCustomerDebt.ExceedingOrder
						|		THEN IncreasingCustomerDebt.SalesOrder_
						|	ELSE UNDEFINED
						|END";
		AmountARAPByPackage = "IncreasingCustomerDebt.AmountARAPByPackage";
		PaymentOption = "IncreasingCustomerDebt.PaymentOption";
		PaymentMethod = "Undefined";
		CashFlowItem = "Undefined";
		ExcludeDuringControl = "IncreasingCustomerDebt.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|	OR NOT ContractData.ExecutionScheduleIsSpecified";
		PaymentDate = "CASE WHEN IncreasingCustomerDebt.Sum < 0
						|		THEN DATETIME(1,1,1)
						|	ELSE IncreasingCustomerDebt.PaymentDate
						|END";
		LinkedDocument = "IncreasingCustomerDebt.LinkedDocument";
		FinRecordID = "IncreasingCustomerDebt.ARAPObject.UUID";
		BusinessTransactionSetting = "Undefined";
		BusinessOperation = "IncreasingCustomerDebt.BusinessOperation";
		// With a negative amount, reducing reports of the commission agent are possible
		SettlementTransaction = "CASE WHEN IncreasingCustomerDebt.Sum < 0
						|		THEN VALUE(Enum.SettlementOperations.AdjustmentOfInvoice)
						|	ELSE VALUE(Enum.SettlementOperations.Shipment)
						|END";
		
	ElsIf Operation = "RefundToCustomer" Then
		
		SalesOrder_ = "Undefined";
		AmountARAPByPackage = "0";
		PaymentOption = "VALUE(Enum.CustomerPaymentControlOptions.EmptyRef)";
		PaymentMethod = "IncreasingCustomerDebt.PaymentMethod";
		CashFlowItem = "IncreasingCustomerDebt.CashFlowItem";
		ExcludeDuringControl = "TRUE";
		PaymentDate = "BEGINOFPERIOD(IncreasingCustomerDebt.RecorderDate, DAY)";
		LinkedDocument = "Undefined";
		FinRecordID = "IncreasingCustomerDebt.FinRecordID";
		BusinessTransactionSetting = "IncreasingCustomerDebt.BusinessTransactionSetting";
		BusinessOperation = "IncreasingCustomerDebt.BusinessOperation";
		SettlementTransaction = "VALUE(Enum.SettlementOperations.Refund)";
		
	EndIf;
	
	QueryText = "
		|SELECT
		|	IncreasingCustomerDebt.RecorderDate           AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                    AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)           AS AccountingDimensionByPartners,
		|	IncreasingCustomerDebt.ARAPObject             AS ARAPObject,
		|	IncreasingCustomerDebt.ARAPCurrency       AS Currency,
		|	
		|	(IncreasingCustomerDebt.AmountARAP)      AS Sum,
		|	0                                                         AS AmountDue,
		|	0                                                         AS BeingPaid,
		|	0                                                         AS ToShip,
		|	0                                                         AS BeingShipped,
		|	
		|	&BusinessOperation                                    AS BusinessOperation,
		|	&PaymentMethod                                              AS PaymentMethod,
		|	UNDEFINED                                              AS ProformaInvoice,
		|	&SalesOrder_                                             AS SaleByOrder,
		|	IncreasingCustomerDebt.RecorderDate           AS RecorderDate,
		|	&PaymentDate                                              AS PaymentDate,
		|	
		|	(CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingCustomerDebt.AmountARAP
		|			WHEN IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingCustomerDebt.Sum
		|			ELSE CAST(IncreasingCustomerDebt.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END)                                                    AS SumCompl,
		|	(CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingCustomerDebt.AmountARAP
		|			WHEN IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingCustomerDebt.Sum
		|			ELSE CAST((IncreasingCustomerDebt.Sum * Coefficients.ManSCoefficient) AS NUMBER(31,2))
		|	END)                                                    AS SumMan,
		|
		|	&ExcludeDuringControl                                     AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0)  AS AllowableAmountPayable,
		|	(&AmountARAPByPackage)                              AS DepositForPackage,
		|	&CashFlowItem                            AS CashFlowItem,
		|	UNDEFINED                                              AS ARAPDocument,
		|	&LinkedDocument                                        AS LinkedDocument,
		|	&PaymentOption                                            AS PaymentOption,
		|	IncreasingCustomerDebt.DocumentCurrency            AS DocumentCurrency,
		|	UNDEFINED                                              AS CorARAPObject,
		|	UNDEFINED                                              AS CorPartnerAccountingDimension,
		|	  
		|	CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|		THEN IncreasingCustomerDebt.Organization
		|		ELSE IncreasingCustomerDebt.ARAPObject.Organization
		|	END                                                     AS Organization,
		|	IncreasingCustomerDebt.Partner                    AS Partner,
		|	IncreasingCustomerDebt.ARAPObject.Counterparty  AS Counterparty,
		|	IncreasingCustomerDebt.ARAPObject.Contract     AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics              AS LineOfBusiness,
		|	UNDEFINED                                              AS CorPartner,
		|	UNDEFINED                                              AS CorCompany,
		|	UNDEFINED                                              AS CorCounterparty,
		|	UNDEFINED                                              AS CorContract,
		|	UNDEFINED                                              AS CorLineOfBusiness,
		|	IncreasingCustomerDebt.RecorderNumber          AS RecorderNumber,
		|	&FinRecordID                                   AS FinRecordID,
		|	UNDEFINED                                              AS PaymentRequest,
		|	&TypeOfOperationForSorting                                 AS TypeOfOperationForSorting,
		|	CASE 
		|		WHEN &SettlementTransaction = VALUE(Enum.SettlementOperations.Shipment)
		|			THEN 4
		|		ELSE 1
		|	END                                                     AS OrderOfOperationsWithinDocument,
		|	&SettlementTransaction                                   AS SettlementTransaction,
		|	&BusinessTransactionSetting                           AS BusinessTransactionSetting,
		|
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                     AS RateARAPCurrencyNumerator,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                     AS RateARAPCurrencyDenominator,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                     AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN IncreasingCustomerDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingCustomerDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                     AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                              AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                              AS CalculationObjectReceiver,
		|	UNDEFINED                                              AS CurrencyReceiver,
		|	UNDEFINED                                              AS PartnerReceiver,
		|	UNDEFINED                                              AS CompanyDestination,
		|	UNDEFINED                                              AS CounterpartyReceiver,
		|	UNDEFINED                                              AS ContractDestination,
		|	UNDEFINED                                              AS FieldOfActivityReceiver,
		|	0                                                         AS AmountReceiver,
		|	FALSE                                                      AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreasingCustomerDebt AS IncreasingCustomerDebt
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreasingCustomerDebt.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = IncreasingCustomerDebt.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|					THEN IncreasingCustomerDebt.Organization
		|					ELSE IncreasingCustomerDebt.ARAPObject.Organization
		|				END = Dimension.Organization
		|				AND IncreasingCustomerDebt.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND IncreasingCustomerDebt.Partner = Dimension.Partner
		|				AND IncreasingCustomerDebt.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = IncreasingCustomerDebt.Ref
		|				AND Coefficients.ARAPObject = IncreasingCustomerDebt.ARAPObject
		|				AND Coefficients.ARAPCurrency = IncreasingCustomerDebt.ARAPCurrency
		|				AND Coefficients.DateOfCourse = IncreasingCustomerDebt.DateOfCourse
		|WHERE 
		|	IncreasingCustomerDebt.AmountARAP <> 0
		|";
	
	QueryText = StrReplace(QueryText,"&SalesOrder_",                  SalesOrder_);
	QueryText = StrReplace(QueryText,"&AmountARAPByPackage",     AmountARAPByPackage);
	QueryText = StrReplace(QueryText,"&PaymentOption",                 PaymentOption);
	QueryText = StrReplace(QueryText,"&PaymentMethod",                   PaymentMethod);
	QueryText = StrReplace(QueryText,"&CashFlowItem", CashFlowItem);
	QueryText = StrReplace(QueryText,"&ExcludeDuringControl",          ExcludeDuringControl);
	QueryText = StrReplace(QueryText,"&PaymentDate",                   PaymentDate);
	QueryText = StrReplace(QueryText,"&LinkedDocument",             LinkedDocument);
	QueryText = StrReplace(QueryText,"&FinRecordID",        FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting", BusinessTransactionSetting);
	QueryText = StrReplace(QueryText,"&BusinessOperation",         BusinessOperation);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting", TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&SettlementTransaction",        SettlementTransaction);
	
	Return QueryText;
	
EndFunction

Function IncreaseOurCustomerDebt(Operation, TypeOfOperationForSorting, OrderOfOperationsWithinDocument = "1") Export
	
	If Operation = "ReturnOfGoods" Then
		
		ProformaInvoice = "Undefined";
		PaymentMethod = "Undefined";
		CashFlowItem = "Undefined";
		LinkedDocument = "Undefined";
		PaymentDate = "DATETIME(1,1,1)";
		FinRecordID = "TablePaymentFromCustomer.ARAPObject.UUID";
		BusinessTransactionSetting = "Undefined";
		SettlementTransaction = "VALUE(Enum.SettlementOperations.AdjustmentOfInvoice)";
		
	ElsIf Operation = "PaymentFromCustomer" Or Operation = "OffsettingClientSCounterObligations" Then
		
		ProformaInvoice = "TablePaymentFromCustomer.ProformaInvoice";
		PaymentMethod = "TablePaymentFromCustomer.PaymentMethod";
		CashFlowItem = "TablePaymentFromCustomer.CashFlowItem";
		LinkedDocument = "TablePaymentFromCustomer.LinkedDocument";
		If Operation = "PaymentFromCustomer" Then
			PaymentDate = "CASE WHEN TablePaymentFromCustomer.AmountARAP < 0
			|			THEN BEGINOFPERIOD(TablePaymentFromCustomer.RecorderDate, DAY)
			|		ELSE TablePaymentFromCustomer.MaturityDate
			|	END";
		Else
			PaymentDate = "CASE WHEN TablePaymentFromCustomer.AmountARAP < 0
			|			THEN BEGINOFPERIOD(TablePaymentFromCustomer.RecorderDate, DAY)
			|		ELSE DATETIME(1,1,1)
			|	END";
		EndIf;
		FinRecordID = "TablePaymentFromCustomer.FinRecordID";
		BusinessTransactionSetting = "TablePaymentFromCustomer.BusinessTransactionSetting";
		SettlementTransaction = "CASE WHEN TablePaymentFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction)
		|		OR TablePaymentFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor)
		|		OR TablePaymentFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
		|		OR TablePaymentFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.DeductionFromAnEmployeeSalaryAgainstSale)
		|		THEN VALUE(Enum.SettlementOperations.ARAPAdjustment)
		|	WHEN TablePaymentFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		THEN VALUE(Enum.SettlementOperations.AdjustmentOfInvoice)
		|	ELSE VALUE(Enum.SettlementOperations.Payment)
		|END";
		
	EndIf;
	
	QueryText = "
		|SELECT
		|	TablePaymentFromCustomer.RecorderDate               AS Period,
		|	VALUE(AccumulationRecordType.Expense)                AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)       AS AccountingDimensionByPartners,
		|	TablePaymentFromCustomer.ARAPObject                 AS ARAPObject,
		|	TablePaymentFromCustomer.ARAPCurrency           AS Currency,
		|	
		|	(TablePaymentFromCustomer.AmountARAP)          AS Sum,
		|	0                                                     AS AmountDue,
		|	0                                                     AS BeingPaid,
		|	0                                                     AS ToShip,
		|	0                                                     AS BeingShipped,
		|	
		|	TablePaymentFromCustomer.BusinessOperation          AS BusinessOperation,
		|	&PaymentMethod                                          AS PaymentMethod,
		|	&ProformaInvoice                                         AS ProformaInvoice,
		|	UNDEFINED                                          AS SaleByOrder,
		|	TablePaymentFromCustomer.RecorderDate               AS RecorderDate,
		|	&PaymentDate                                          AS PaymentDate,
		|	
		|	(CASE WHEN TablePaymentFromCustomer.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|				THEN TablePaymentFromCustomer.AmountARAP
		|			WHEN TablePaymentFromCustomer.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN TablePaymentFromCustomer.Sum
		|			ELSE CAST(TablePaymentFromCustomer.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END)                                                AS SumCompl,
		|	(CASE WHEN TablePaymentFromCustomer.ARAPCurrency = &ManagementAccountingCurrency
		|				THEN TablePaymentFromCustomer.AmountARAP
		|			WHEN TablePaymentFromCustomer.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN TablePaymentFromCustomer.Sum
		|			ELSE CAST(TablePaymentFromCustomer.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END)                                                AS SumMan,
		|
		|	FALSE                                                  AS ExcludeDuringControl,
		|	0                                                     AS AllowableAmountPayable,
		|	0                                                     AS DepositForPackage,
		|	&CashFlowItem                        AS CashFlowItem,
		|	UNDEFINED                                          AS ARAPDocument,
		|	&LinkedDocument                                    AS LinkedDocument,
		|	UNDEFINED                                          AS PaymentOption,
		|	TablePaymentFromCustomer.DocumentCurrency                AS DocumentCurrency,
		|	UNDEFINED                                          AS CorARAPObject,
		|	UNDEFINED                                          AS CorPartnerAccountingDimension,
		|	
		|	CASE WHEN TablePaymentFromCustomer.Organization <> TablePaymentFromCustomer.ARAPObject.Organization
		|		THEN TablePaymentFromCustomer.Organization
		|		ELSE TablePaymentFromCustomer.ARAPObject.Organization
		|	END                                                 AS Organization,
		|	TablePaymentFromCustomer.Partner                        AS Partner,
		|	TablePaymentFromCustomer.ARAPObject.Counterparty      AS Counterparty,
		|	TablePaymentFromCustomer.ARAPObject.Contract         AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics          AS LineOfBusiness,
		|	UNDEFINED                                          AS CorPartner,
		|	UNDEFINED                                          AS CorCompany,
		|	UNDEFINED                                          AS CorCounterparty,
		|	UNDEFINED                                          AS CorContract,
		|	UNDEFINED                                          AS CorLineOfBusiness,
		|	TablePaymentFromCustomer.RecorderNumber              AS RecorderNumber,
		|	&FinRecordID                               AS FinRecordID,
		|	UNDEFINED                                          AS PaymentRequest,
		|	&TypeOfOperationForSorting                             AS TypeOfOperationForSorting,
		|	&OrderOfOperationsWithinDocument                    AS OrderOfOperationsWithinDocument,
		|	&SettlementTransaction                               AS SettlementTransaction,
		|	&BusinessTransactionSetting                       AS BusinessTransactionSetting,
		|
		|	CASE WHEN TablePaymentFromCustomer.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR TablePaymentFromCustomer.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                 AS RateARAPCurrencyNumerator,
		|	CASE WHEN TablePaymentFromCustomer.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR TablePaymentFromCustomer.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                 AS RateARAPCurrencyDenominator,
		|	CASE WHEN TablePaymentFromCustomer.ARAPCurrency = &ManagementAccountingCurrency
		|		OR TablePaymentFromCustomer.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                 AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN TablePaymentFromCustomer.ARAPCurrency = &ManagementAccountingCurrency
		|		OR TablePaymentFromCustomer.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                 AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                          AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                          AS CalculationObjectReceiver,
		|	UNDEFINED                                          AS CurrencyReceiver,
		|	UNDEFINED                                          AS PartnerReceiver,
		|	UNDEFINED                                          AS CompanyDestination,
		|	UNDEFINED                                          AS CounterpartyReceiver,
		|	UNDEFINED                                          AS ContractDestination,
		|	UNDEFINED                                          AS FieldOfActivityReceiver,
		|	0                                                     AS AmountReceiver,
		|	FALSE                                                  AS ByDataOfSourceARAPObject
		|FROM
		|	#TablePaymentFromCustomer AS TablePaymentFromCustomer
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON TablePaymentFromCustomer.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON TablePaymentFromCustomer.ARAPObject.Contract = ContractData.Ref
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CASE WHEN TablePaymentFromCustomer.Organization <> TablePaymentFromCustomer.ARAPObject.Organization
		|						THEN TablePaymentFromCustomer.Organization
		|					ELSE TablePaymentFromCustomer.ARAPObject.Organization
		|				END = Dimension.Organization
		|				AND TablePaymentFromCustomer.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND TablePaymentFromCustomer.Partner = Dimension.Partner
		|				AND TablePaymentFromCustomer.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = TablePaymentFromCustomer.Ref
		|				AND Coefficients.ARAPObject = TablePaymentFromCustomer.ARAPObject
		|				AND Coefficients.ARAPCurrency = TablePaymentFromCustomer.ARAPCurrency
		|				AND Coefficients.DateOfCourse = TablePaymentFromCustomer.DateOfCourse
		|WHERE
		|	TablePaymentFromCustomer.AmountARAP <> 0 
		|";
	
	QueryText = StrReplace(QueryText,"&PaymentMethod",                   PaymentMethod);
	QueryText = StrReplace(QueryText,"&ProformaInvoice",                  ProformaInvoice);
	QueryText = StrReplace(QueryText,"&CashFlowItem", CashFlowItem);
	QueryText = StrReplace(QueryText,"&LinkedDocument",             LinkedDocument);
	QueryText = StrReplace(QueryText,"&PaymentDate",                   PaymentDate);
	QueryText = StrReplace(QueryText,"&FinRecordID",        FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting", BusinessTransactionSetting);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",       TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&OrderOfOperationsWithinDocument",       OrderOfOperationsWithinDocument);
	QueryText = StrReplace(QueryText,"&SettlementTransaction",        SettlementTransaction);
	
	Return QueryText;
	
EndFunction

Function FeeIsPaidByClient(Operation, TypeOfOperationForSorting)

	If Operation = "PaymentFromCustomer" Then
		ProformaInvoice = "IncreaseIsPaidByClient.ProformaInvoice";
		PaymentRequest = "Undefined";
	ElsIf Operation = "RefundToCustomer" Then
		ProformaInvoice = "Undefined";
		PaymentRequest = "IncreaseIsPaidByClient.PaymentRequest";
	EndIf;
	
	QueryText = "
		|SELECT
		|	IncreaseIsPaidByClient.RecorderDate                  AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	IncreaseIsPaidByClient.ARAPObject                    AS ARAPObject,
		|	
		|	IncreaseIsPaidByClient.ARAPCurrency              AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	(IncreaseIsPaidByClient.IncreaseIsPaid)          AS BeingPaid,
		|	0                                                                AS ToShip,
		|	0                                                                AS BeingShipped,
		|	
		|	IncreaseIsPaidByClient.BusinessOperation             AS BusinessOperation,
		|	IncreaseIsPaidByClient.PaymentMethod                       AS PaymentMethod,
		|	&ProformaInvoice                                                    AS ProformaInvoice,
		|	UNDEFINED                                                     AS SaleByOrder,
		|	IncreaseIsPaidByClient.RecorderDate                  AS RecorderDate,
		|	DATETIME(1,1,1)                                                 AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	FALSE                                                             AS ExcludeDuringControl,
		|	0                                                                AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	IncreaseIsPaidByClient.CashFlowItem     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	IncreaseIsPaidByClient.DocumentCurrency                   AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	
		|	IncreaseIsPaidByClient.ARAPObject.Organization        AS Organization,
		|	IncreaseIsPaidByClient.Partner                           AS Partner,
		|	IncreaseIsPaidByClient.ARAPObject.Counterparty         AS Counterparty,
		|	IncreaseIsPaidByClient.ARAPObject.Contract            AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	IncreaseIsPaidByClient.RecorderNumber                 AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	&PaymentRequest                             AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreaseIsPaidByClient AS IncreaseIsPaidByClient
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreaseIsPaidByClient.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref =  IncreaseIsPaidByClient.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON IncreaseIsPaidByClient.ARAPObject.Organization = Dimension.Organization
		|				AND IncreaseIsPaidByClient.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND IncreaseIsPaidByClient.Partner = Dimension.Partner
		|				AND IncreaseIsPaidByClient.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	IncreaseIsPaidByClient.IncreaseIsPaid <> 0
		|	AND IncreaseIsPaidByClient.ARAPObject.OBJECT <> IncreaseIsPaidByClient.Ref
		|";
	
	QueryText = StrReplace(QueryText,"&ProformaInvoice", ProformaInvoice);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting", TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&PaymentRequest", PaymentRequest);
	
	Return QueryText;
	
EndFunction

Function FeeIsPaidByCustomer(Operation,TypeOfOperationForSorting)
	
	If Operation = "PaymentFromCustomer" Then
		
		BeingPaid = "ReductionIsPaidByClient.ReductionIsPaid";
		ProformaInvoice = "ReductionIsPaidByClient.ProformaInvoice";
		ExcludeDuringControl = "FALSE";
		PaymentRequest = "Undefined";
		
	ElsIf Operation = "RequestForRefundToClient" Then
		
		BeingPaid = "ReductionIsPaidByClient.BeingPaid";
		ProformaInvoice = "Undefined";
		ExcludeDuringControl = "FALSE";
		PaymentRequest = "&Ref";
		
	ElsIf Operation = "RefundToCustomer" Then
		
		BeingPaid = "ReductionIsPaidByClient.BeingPaid";
		ProformaInvoice = "Undefined";
		ExcludeDuringControl = "TRUE";
		PaymentRequest = "ReductionIsPaidByClient.PaymentRequest";
		
	EndIf;
	
	QueryText = "
		|SELECT
		|	ReductionIsPaidByClient.RecorderDate                  AS Period,
		|	VALUE(AccumulationRecordType.Expense)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	ReductionIsPaidByClient.ARAPObject                    AS ARAPObject,
		|	ReductionIsPaidByClient.ARAPCurrency              AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	(&BeingPaid)                                                  AS BeingPaid,
		|	0                                                                AS ToShip,
		|	0                                                                AS BeingShipped,
		|	
		|	ReductionIsPaidByClient.BusinessOperation             AS BusinessOperation,
		|	ReductionIsPaidByClient.PaymentMethod                       AS PaymentMethod,
		|	&ProformaInvoice                                                    AS ProformaInvoice,
		|	UNDEFINED                                                     AS SaleByOrder,
		|	ReductionIsPaidByClient.RecorderDate                  AS RecorderDate,
		|	DATETIME(1,1,1)                                                 AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	&ExcludeDuringControl                                            AS ExcludeDuringControl,
		|	0                                                                AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	ReductionIsPaidByClient.CashFlowItem     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	ReductionIsPaidByClient.DocumentCurrency                   AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	
		|	ReductionIsPaidByClient.ARAPObject.Organization        AS Organization,
		|	ReductionIsPaidByClient.Partner                           AS Partner,
		|	ReductionIsPaidByClient.ARAPObject.Counterparty         AS Counterparty,
		|	ReductionIsPaidByClient.ARAPObject.Contract            AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	ReductionIsPaidByClient.RecorderNumber                 AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	&PaymentRequest                             AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#ReductionIsPaidByClient AS ReductionIsPaidByClient
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ReductionIsPaidByClient.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref =  ReductionIsPaidByClient.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON ReductionIsPaidByClient.ARAPObject.Organization = Dimension.Organization
		|				AND ReductionIsPaidByClient.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND ReductionIsPaidByClient.Partner = Dimension.Partner
		|				AND ReductionIsPaidByClient.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	&BeingPaid <> 0
		|";
	
	QueryText = StrReplace(QueryText,"&BeingPaid", BeingPaid);
	QueryText = StrReplace(QueryText,"&ProformaInvoice", ProformaInvoice);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting", TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&PaymentRequest", PaymentRequest);
	QueryText = StrReplace(QueryText,"&ExcludeDuringControl", ExcludeDuringControl);
	
	Return QueryText;
	
EndFunction

Function IncreaseShipping(Operation, TypeOfOperationForSorting)
	
	If Operation = "SalesOrder" Then
		
		ThisIsOrder = "TRUE";
		ThisIsAnInvoice = "FALSE";
		InvoiceForOrders = "FALSE";
		
	ElsIf Operation = "Sale" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "TRUE";
		InvoiceForOrders = "IncreaseIsShipped.InvoiceForOrders";
		
	EndIf;
	
	QueryText = "
		|SELECT
		|	IncreaseIsShipped.DateOfShipment                               AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	IncreaseIsShipped.ARAPObject                             AS ARAPObject,
		|	IncreaseIsShipped.ARAPCurrency                       AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS ToShip,
		|	(IncreaseIsShipped.IncreaseShipping)                     AS BeingShipped,
		|	
		|	IncreaseIsShipped.BusinessOperation                      AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS ProformaInvoice,
		|	UNDEFINED                                                     AS SaleByOrder,
		|	IncreaseIsShipped.RecorderDate                           AS RecorderDate,
		|	DATETIME(1,1,1)                                                 AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	TRUE                                                           AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0)         AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	UNDEFINED                                                     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	IncreaseIsShipped.DocumentCurrency                            AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	              
		|	CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|		THEN IncreaseIsShipped.Organization
		|		ELSE IncreaseIsShipped.ARAPObject.Organization
		|	END                                                            AS Organization,
		|	IncreaseIsShipped.Partner                                    AS Partner,
		|	IncreaseIsShipped.ARAPObject.Counterparty                  AS Counterparty,
		|	IncreaseIsShipped.ARAPObject.Contract                     AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	IncreaseIsShipped.RecorderNumber                          AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreaseIsShipped AS IncreaseIsShipped
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreaseIsShipped.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = IncreaseIsShipped.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|					THEN IncreaseIsShipped.Organization
		|					ELSE IncreaseIsShipped.ARAPObject.Organization
		|				END = Dimension.Organization
		|				AND IncreaseIsShipped.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND IncreaseIsShipped.Partner = Dimension.Partner
		|				AND IncreaseIsShipped.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	IncreaseIsShipped.IncreaseShipping <> 0 
		|	AND (&ThisIsOrder AND IncreaseIsShipped.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|		OR &ThisIsAnInvoice AND (IncreaseIsShipped.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|			OR NOT &InvoiceForOrders))
		|";
	
	QueryText = StrReplace(QueryText,"&ThisIsOrder", ThisIsOrder);
	QueryText = StrReplace(QueryText,"&ThisIsAnInvoice", ThisIsAnInvoice);
	QueryText = StrReplace(QueryText,"&InvoiceForOrders", InvoiceForOrders);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting", TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function ReduceShipping(TypeOfOperationForSorting)
	
	QueryText = "SELECT
		|	ReductionIsShipped.RecorderDate                           AS Period,
		|	VALUE(AccumulationRecordType.Expense)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	ReductionIsShipped.ARAPObject                             AS ARAPObject,
		|	ReductionIsShipped.ARAPCurrency                       AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS ToShip,
		|	(ReductionIsShipped.ReduceShipping)                     AS BeingShipped,
		|	
		|	ReductionIsShipped.BusinessOperation                      AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS ProformaInvoice,
		|	ReductionIsShipped.SalesOrder_                               AS SaleByOrder,
		|	ReductionIsShipped.RecorderDate                           AS RecorderDate,
		|	ReductionIsShipped.RecorderDate                           AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	TRUE                                                           AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0)         AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	UNDEFINED                                                     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	ReductionIsShipped.DocumentCurrency                            AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	   
		|	CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|		THEN ReductionIsShipped.Organization
		|		ELSE ReductionIsShipped.ARAPObject.Organization
		|	END                                                            AS Organization,
		|	ReductionIsShipped.Partner                                    AS Partner,
		|	ReductionIsShipped.ARAPObject.Counterparty                  AS Counterparty,
		|	ReductionIsShipped.ARAPObject.Contract                     AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	ReductionIsShipped.RecorderNumber                          AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                       AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#ReductionIsShipped AS ReductionIsShipped
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ReductionIsShipped.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = ReductionIsShipped.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|					THEN ReductionIsShipped.Organization
		|					ELSE ReductionIsShipped.ARAPObject.Organization
		|				END = Dimension.Organization
		|				AND ReductionIsShipped.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND ReductionIsShipped.Partner = Dimension.Partner
		|				AND ReductionIsShipped.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|		LEFT JOIN Document.SalesOrder AS DocumentSalesOrder
		|			ON ReductionIsShipped.SalesOrder_ = DocumentSalesOrder.Ref
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|			ON ReductionIsShipped.SalesOrder_ = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|WHERE
		|	ReductionIsShipped.ReduceShipping <> 0
		|	AND (ReductionIsShipped.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|		OR ReductionIsShipped.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|			AND NOT ContractData.ExecutionScheduleIsSpecified)
		|	AND ReductionIsShipped.InvoiceForOrders
		|	AND NOT ISNULL(ISNULL(DocumentSalesOrder.ThisIsOrderAsInvoice, DocumentRequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice), FALSE)
		|	AND NOT ReductionIsShipped.ExceedingOrder
		|
		|UNION ALL
		|
		|SELECT
		|	ReductionIsShipped.RecorderDate                           AS Period,
		|	VALUE(AccumulationRecordType.Expense)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	ReductionIsShipped.SalesOrder_.ARAPObject                AS ARAPObject,
		|	ReductionIsShipped.ARAPCurrency                       AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS ToShip,
		|	(ReductionIsShipped.ReduceShipping)                     AS BeingShipped,
		|	
		|	ReductionIsShipped.BusinessOperation                      AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS ProformaInvoice,
		|	ReductionIsShipped.SalesOrder_                               AS SaleByOrder,
		|	ReductionIsShipped.RecorderDate                           AS RecorderDate,
		|	ReductionIsShipped.RecorderDate                           AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	TRUE                                                           AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0)         AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	UNDEFINED                                                     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	ReductionIsShipped.DocumentCurrency                            AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	 
		|	ReductionIsShipped.SalesOrder_.ARAPObject.Organization    AS Organization,
		|	ReductionIsShipped.SalesOrder_.ARAPObject.Partner        AS Partner,
		|	ReductionIsShipped.SalesOrder_.ARAPObject.Counterparty     AS Counterparty,
		|	ReductionIsShipped.SalesOrder_.ARAPObject.Contract        AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	ReductionIsShipped.RecorderNumber                          AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#ReductionIsShipped AS ReductionIsShipped
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ReductionIsShipped.SalesOrder_.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = ReductionIsShipped.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON ReductionIsShipped.SalesOrder_.ARAPObject.Organization = Dimension.Organization
		|				AND ReductionIsShipped.SalesOrder_.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND ReductionIsShipped.SalesOrder_.ARAPObject.Partner = Dimension.Partner
		|				AND ReductionIsShipped.SalesOrder_.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|		LEFT JOIN Document.SalesOrder AS DocumentSalesOrder
		|			ON ReductionIsShipped.SalesOrder_ = DocumentSalesOrder.Ref
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|			ON ReductionIsShipped.SalesOrder_ = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|WHERE
		|	ReductionIsShipped.ReduceShipping <> 0
		|	AND ReductionIsShipped.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|	AND ReductionIsShipped.InvoiceForOrders
		|	AND NOT ISNULL(ISNULL(DocumentSalesOrder.ThisIsOrderAsInvoice, DocumentRequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice), FALSE)
		|	AND NOT ReductionIsShipped.ExceedingOrder
		|
		|UNION ALL
		|
		|SELECT
		|	ReductionIsShipped.RecorderDate                           AS Period,
		|	VALUE(AccumulationRecordType.Expense)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	ContractData.ARAPObject                                    AS ARAPObject,
		|	ReductionIsShipped.ARAPCurrency                       AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS ToShip,
		|	(ReductionIsShipped.ReduceShipping)                     AS BeingShipped,
		|	
		|	ReductionIsShipped.BusinessOperation                      AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS ProformaInvoice,
		|	ReductionIsShipped.SalesOrder_                               AS SaleByOrder,
		|	ReductionIsShipped.RecorderDate                           AS RecorderDate,
		|	ReductionIsShipped.RecorderDate                           AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	TRUE                                                           AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0)         AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	UNDEFINED                                                     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	ReductionIsShipped.DocumentCurrency                            AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	  
		|	ContractData.ARAPObject.Organization                        AS Organization,
		|	ReductionIsShipped.Partner                                    AS Partner,
		|	ContractData.ARAPObject.Counterparty                         AS Counterparty,
		|	ContractData.ARAPObject.Contract                            AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	ReductionIsShipped.RecorderNumber                          AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                       AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#ReductionIsShipped AS ReductionIsShipped
		|		INNER JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = ReductionIsShipped.ARAPObject.Contract
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ContractData.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON ContractData.ARAPObject.Organization = Dimension.Organization
		|				AND ContractData.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND ReductionIsShipped.Partner = Dimension.Partner
		|				AND ContractData.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|		LEFT JOIN Document.SalesOrder AS DocumentSalesOrder
		|			ON ReductionIsShipped.SalesOrder_ = DocumentSalesOrder.Ref
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|			ON ReductionIsShipped.SalesOrder_ = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|WHERE
		|	ReductionIsShipped.ReduceShipping <> 0
		|	AND ReductionIsShipped.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|	AND NOT &TextOfConditionTransferOfOwnershipOnBasisOfShipment
		|	AND NOT ContractData.ExecutionScheduleIsSpecified
		|	AND ReductionIsShipped.InvoiceForOrders
		|	AND NOT ISNULL(ISNULL(DocumentSalesOrder.ThisIsOrderAsInvoice, DocumentRequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice), FALSE)
		|	AND NOT ReductionIsShipped.ExceedingOrder
		|
		|UNION ALL
		|
		|SELECT
		|	ReductionIsShipped.RecorderDate                           AS Period,
		|	VALUE(AccumulationRecordType.Expense)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	ReductionIsShipped.ARAPObject                             AS ARAPObject,
		|	ReductionIsShipped.ARAPCurrency                       AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS ToShip,
		|	(ReductionIsShipped.ReduceShipping)                     AS BeingShipped,
		|	
		|	ReductionIsShipped.BusinessOperation                      AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS ProformaInvoice,
		|	ReductionIsShipped.SalesOrder_                               AS SaleByOrder,
		|	ReductionIsShipped.RecorderDate                           AS RecorderDate,
		|	ReductionIsShipped.RecorderDate                           AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	TRUE                                                           AS ExcludeDuringControl,
		|	ISNULL(ContractData.AllowableAmountPayable, 0)         AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	UNDEFINED                                                     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	ReductionIsShipped.DocumentCurrency                            AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	   
		|	CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|		THEN ReductionIsShipped.Organization
		|		ELSE ReductionIsShipped.ARAPObject.Organization
		|	END                                                            AS Organization,
		|	ReductionIsShipped.Partner                                    AS Partner,
		|	ReductionIsShipped.ARAPObject.Counterparty                  AS Counterparty,
		|	ReductionIsShipped.ARAPObject.Contract                     AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	ReductionIsShipped.RecorderNumber                          AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                       AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	#ReductionIsShipped AS ReductionIsShipped
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ReductionIsShipped.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = ReductionIsShipped.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|					THEN ReductionIsShipped.Organization
		|					ELSE ReductionIsShipped.ARAPObject.Organization
		|				END = Dimension.Organization
		|				AND ReductionIsShipped.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND ReductionIsShipped.Partner = Dimension.Partner
		|				AND ReductionIsShipped.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|		LEFT JOIN Document.SalesOrder AS DocumentSalesOrder
		|			ON ReductionIsShipped.SalesOrder_ = DocumentSalesOrder.Ref
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|			ON ReductionIsShipped.SalesOrder_ = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|WHERE
		|	ReductionIsShipped.ReduceShipping <> 0
		|	AND ReductionIsShipped.ARAPObjectSettings IN
		|		(VALUE(Enum.ARAPObjectSettings.ByARAPDocuments),
		|		VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|	AND &TextOfConditionTransferOfOwnershipOnBasisOfShipment
		|	AND ReductionIsShipped.InvoiceForOrders
		|	AND NOT ISNULL(ISNULL(DocumentSalesOrder.ThisIsOrderAsInvoice, DocumentRequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice), FALSE)
		|	AND NOT ReductionIsShipped.ExceedingOrder";
	
	QueryText = StrReplace(QueryText, "&TypeOfOperationForSorting", TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function IncreaseShipmentPlanToCustomer(Query, Operation, TypeOfOperationForSorting)
	
	If Operation = "ClientExecutionSchedule" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "FALSE";
		ARAPObjectSettings = "VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)";
		PaymentDate = "DATETIME(1,1,1)";
		
	ElsIf Operation = "SalesOrder" Then
		
		ThisIsOrder = "TRUE";
		ThisIsAnInvoice = "FALSE";
		ARAPObjectSettings = "IncreasingShipmentPlanToCustomer.ARAPObjectSettings";
		PaymentDate = "DATETIME(1,1,1)";
		
	ElsIf Operation = "Sale" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "TRUE";
		ARAPObjectSettings = "IncreasingShipmentPlanToCustomer.ARAPObjectSettings";
		PaymentDate = "IncreasingShipmentPlanToCustomer.RecorderDate";
		
	EndIf;
	
	QueryText = 
		"SELECT
		|	IncreasingShipmentPlanToCustomer.DateOfShipment                      AS Period,
		|	VALUE(AccumulationRecordType.Expense)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	IncreasingShipmentPlanToCustomer.ARAPObject                    AS ARAPObject,
		|	IncreasingShipmentPlanToCustomer.ARAPCurrency              AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	IncreasingShipmentPlanToCustomer.IncreaseToBeSHIPPED                AS ToShip,
		|	0                                                                AS BeingShipped,
		|
		|	IncreasingShipmentPlanToCustomer.BusinessOperation             AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS ProformaInvoice,
		|	IncreasingShipmentPlanToCustomer.SalesOrder_                      AS SaleByOrder,
		|	IncreasingShipmentPlanToCustomer.RecorderDate                  AS RecorderDate,
		|	&PaymentDate                                                     AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	TRUE                                                           AS ExcludeDuringControl,
		|	IncreasingShipmentPlanToCustomer.AllowableAmountPayable      AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	UNDEFINED                                                     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	IncreasingShipmentPlanToCustomer.DocumentCurrency                   AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|
		|	IncreasingShipmentPlanToCustomer.Organization                       AS Organization,
		|	IncreasingShipmentPlanToCustomer.Partner                           AS Partner,
		|	IncreasingShipmentPlanToCustomer.Counterparty                        AS Counterparty,
		|	IncreasingShipmentPlanToCustomer.Contract                           AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	IncreasingShipmentPlanToCustomer.RecorderNumber                 AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	TTIncreaseInShipmentPlanToCustomer AS IncreasingShipmentPlanToCustomer
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreasingShipmentPlanToCustomer.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON IncreasingShipmentPlanToCustomer.Organization = Dimension.Organization
		|				AND IncreasingShipmentPlanToCustomer.Counterparty = Dimension.Counterparty
		|				AND IncreasingShipmentPlanToCustomer.Partner = Dimension.Partner
		|				AND IncreasingShipmentPlanToCustomer.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	NOT (&ThisIsOrder
		|			AND IncreasingShipmentPlanToCustomer.ExecutionScheduleIsSpecified 
		|			AND &ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts),
		|									VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|		OR &ThisIsAnInvoice
		|			AND NOT IncreasingShipmentPlanToCustomer.ExceedingOrder
		|			AND IncreasingShipmentPlanToCustomer.ExecutionScheduleIsSpecified
		|			AND &ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		|	AND IncreasingShipmentPlanToCustomer.IncreaseToBeSHIPPED <> 0
		|	AND (&ThisIsOrder 
		|			AND &ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|		OR IncreasingShipmentPlanToCustomer.InvoiceForOrders
		|			AND &ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|			AND IncreasingShipmentPlanToCustomer.ExceedingOrder
		|			AND NOT IncreasingShipmentPlanToCustomer.ThisIsOrderAsInvoice
		|		OR NOT (&ThisIsOrder OR &ThisIsAnInvoice))
		|";
	
	QueryText = StrReplace(QueryText,"&ThisIsOrder",           ThisIsOrder);
	QueryText = StrReplace(QueryText,"&ThisIsAnInvoice",       ThisIsAnInvoice);
	QueryText = StrReplace(QueryText,"&ARAPObjectSettings",    ARAPObjectSettings);
	QueryText = StrReplace(QueryText,"&PaymentDate",        PaymentDate);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting", TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function ReduceShipmentPlanToCustomer(TypeOfOperationForSorting)
	
	TextForShipment = "
		|SELECT
		|	ReducingShipmentPlanToCustomer.RecorderDate                  AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                  AS AccountingDimensionByPartners,
		|	ReducingShipmentPlanToCustomer.ARAPObject                    AS ARAPObject,
		|	ReducingShipmentPlanToCustomer.ARAPCurrency              AS Currency,
		|	
		|	0                                                                AS Sum,
		|	0                                                                AS AmountDue,
		|	0                                                                AS BeingPaid,
		|	ReducingShipmentPlanToCustomer.ReduceToBESHIPPED                AS ToShip,
		|	0                                                                AS BeingShipped,
		|	
		|	ReducingShipmentPlanToCustomer.BusinessOperation             AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS ProformaInvoice,
		|	ReducingShipmentPlanToCustomer.SalesOrder_                      AS SaleByOrder,
		|	ReducingShipmentPlanToCustomer.RecorderDate                  AS RecorderDate,
		|	ReducingShipmentPlanToCustomer.RecorderDate                  AS PaymentDate,
		|	0                                                                AS SumCompl,
		|	0                                                                AS SumMan,
		|	TRUE                                                           AS ExcludeDuringControl,
		|	ReducingShipmentPlanToCustomer.AllowableAmountPayable      AS AllowableAmountPayable,
		|	0                                                                AS DepositForPackage,
		|	UNDEFINED                                                     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	UNDEFINED                                                     AS PaymentOption,
		|	ReducingShipmentPlanToCustomer.DocumentCurrency                   AS DocumentCurrency,
		|	UNDEFINED                                                     AS CorARAPObject,
		|	UNDEFINED                                                     AS CorPartnerAccountingDimension,
		|	
		|	ReducingShipmentPlanToCustomer.Organization                       AS Organization,
		|	ReducingShipmentPlanToCustomer.Partner                           AS Partner,
		|	ReducingShipmentPlanToCustomer.Counterparty                        AS Counterparty,
		|	ReducingShipmentPlanToCustomer.Contract                           AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|	UNDEFINED                                                     AS CorPartner,
		|	UNDEFINED                                                     AS CorCompany,
		|	UNDEFINED                                                     AS CorCounterparty,
		|	UNDEFINED                                                     AS CorContract,
		|	UNDEFINED                                                     AS CorLineOfBusiness,
		|	ReducingShipmentPlanToCustomer.RecorderNumber                 AS RecorderNumber,
		|	&IDOfUnusedFinRecord                            AS FinRecordID,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	1                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)       AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                                AS RateARAPCurrencyNumerator,
		|	0                                                                AS RateARAPCurrencyDenominator,
		|	0                                                                AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                     AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                     AS CalculationObjectReceiver,
		|	UNDEFINED                                                     AS CurrencyReceiver,
		|	UNDEFINED                                                     AS PartnerReceiver,
		|	UNDEFINED                                                     AS CompanyDestination,
		|	UNDEFINED                                                     AS CounterpartyReceiver,
		|	UNDEFINED                                                     AS ContractDestination,
		|	UNDEFINED                                                     AS FieldOfActivityReceiver,
		|	0                                                                AS AmountReceiver,
		|	FALSE                                                             AS ByDataOfSourceARAPObject
		|FROM
		|	TTReductionOfShipmentPlanToCustomer AS ReducingShipmentPlanToCustomer
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ReducingShipmentPlanToCustomer.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON ReducingShipmentPlanToCustomer.Organization = Dimension.Organization
		|				AND ReducingShipmentPlanToCustomer.Counterparty = Dimension.Counterparty
		|				AND ReducingShipmentPlanToCustomer.Partner = Dimension.Partner
		|				AND ReducingShipmentPlanToCustomer.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	(ReducingShipmentPlanToCustomer.ExecutionScheduleIsSpecified 
		|		AND ReducingShipmentPlanToCustomer.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts),
		|		                                                    VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|	OR ReducingShipmentPlanToCustomer.InvoiceForOrders 
		|		AND NOT ReducingShipmentPlanToCustomer.ThisIsOrderAsInvoice
		|		AND (ReducingShipmentPlanToCustomer.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders),
		|		                                                     VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			OR ReducingShipmentPlanToCustomer.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts),
		|			                                                      VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|				AND NOT ReducingShipmentPlanToCustomer.ExecutionScheduleIsSpecified))
		|";
	
	TextForShipment = StrReplace(TextForShipment, "&TypeOfOperationForSorting", TypeOfOperationForSorting);
	
	Return TextForShipment;
	
EndFunction

Function QueryTextTTReductionOfShipmentPlan()
	
	QueryText = "
		|SELECT
		|	ReducingShipmentPlanToCustomer.RecorderDate          AS Period,
		|	ReducingShipmentPlanToCustomer.ARAPObjectSettings           AS ARAPObjectSettings,
		|	ReducingShipmentPlanToCustomer.InvoiceForOrders        AS InvoiceForOrders,
		|	
		|	CASE
		|		WHEN ReducingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN ReducingShipmentPlanToCustomer.SalesOrder_.ARAPObject
		|		WHEN ReducingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectsContract.Ref
		|		ELSE ReducingShipmentPlanToCustomer.ARAPObject
		|	END                                                    AS ARAPObject,
		|	ReducingShipmentPlanToCustomer.ARAPCurrency      AS ARAPCurrency,
		|	
		|	ReducingShipmentPlanToCustomer.ReduceToBESHIPPED        AS ReduceToBESHIPPED,
		|	
		|	ReducingShipmentPlanToCustomer.BusinessOperation     AS BusinessOperation,
		|	CASE WHEN ReducingShipmentPlanToCustomer.ExceedingOrder
		|			THEN UNDEFINED
		|		ELSE ReducingShipmentPlanToCustomer.SalesOrder_
		|	END                                                    AS SalesOrder_,
		|	ReducingShipmentPlanToCustomer.RecorderDate          AS RecorderDate,
		|	ReducingShipmentPlanToCustomer.RecorderDate          AS PaymentDate,
		|	ISNULL(ContractData.AllowableAmountPayable, 0) AS AllowableAmountPayable,
		|	ReducingShipmentPlanToCustomer.DocumentCurrency           AS DocumentCurrency,
		|	
		|	CASE
		|		WHEN ReducingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN ReducingShipmentPlanToCustomer.ARAPObject.Organization
		|		WHEN ReducingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectsContract.Organization
		|		WHEN ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)
		|			THEN ReducingShipmentPlanToCustomer.ARAPObject.Organization
		|		ELSE ReducingShipmentPlanToCustomer.Organization
		|	END                                                    AS Organization,
		|	CASE
		|		WHEN ReducingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN ReducingShipmentPlanToCustomer.ARAPObject.Partner
		|		ELSE ReducingShipmentPlanToCustomer.Partner
		|	END                                                    AS Partner,
		|	CASE
		|		WHEN ReducingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectsContract.Counterparty
		|		ELSE ReducingShipmentPlanToCustomer.ARAPObject.Counterparty
		|	END                                                    AS Counterparty,
		|	CASE
		|		WHEN ReducingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ContractData.Ref
		|		ELSE ReducingShipmentPlanToCustomer.ARAPObject.Contract
		|	END                                                    AS Contract,
		|	ReducingShipmentPlanToCustomer.RecorderNumber         AS RecorderNumber,
		|	ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)     AS ExecutionScheduleIsSpecified,
		|	ISNULL(ISNULL(DocumentSalesOrder.ThisIsOrderAsInvoice, DocumentRequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice), FALSE) AS ThisIsOrderAsInvoice
		|INTO TTReductionOfShipmentPlanToCustomer
		|FROM
		|	#ReducingShipmentPlanToCustomer AS ReducingShipmentPlanToCustomer
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = ReducingShipmentPlanToCustomer.ARAPObject.Contract
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectsContract
		|			ON ARAPObjectsContract.Object = ContractData.Ref
		|				AND ARAPObjectsContract.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|				AND ARAPObjectsContract.Organization = ReducingShipmentPlanToCustomer.ARAPObject.Organization
		|				AND NOT ARAPObjectsContract.OnlyBalance
		|				AND NOT ARAPObjectsContract.DeletionMark
		|		LEFT JOIN Document.SalesOrder AS DocumentSalesOrder
		|			ON ReducingShipmentPlanToCustomer.SalesOrder_ = DocumentSalesOrder.Ref
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|			ON ReducingShipmentPlanToCustomer.SalesOrder_ = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|WHERE
		|	ReducingShipmentPlanToCustomer.ReduceToBESHIPPED <> 0 
		|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTIncreaseInShipmentPlan(ThisIsSale=False)
	
	If ThisIsSale Then
		
		InvoiceForOrders = "IncreasingShipmentPlanToCustomer.InvoiceForOrders";
		ExceedingOrder = "IncreasingShipmentPlanToCustomer.ExceedingOrder";
		SalesOrder_ = "CASE WHEN IncreasingShipmentPlanToCustomer.ExceedingOrder 
						|		THEN UNDEFINED
						|	ELSE IncreasingShipmentPlanToCustomer.SalesOrder_
						|END";
		ARAPObjectOfOrder = "IncreasingShipmentPlanToCustomer.SalesOrder_.ARAPObject";
		
	Else
		
		InvoiceForOrders = "FALSE";
		ExceedingOrder = "FALSE";
		SalesOrder_ = "UNDEFINED";
		ARAPObjectOfOrder = "UNDEFINED";
		
	EndIf;
	
	QueryText = 
		"SELECT
		|	IncreasingShipmentPlanToCustomer.DateOfShipment                      AS DateOfShipment,
		|	IncreasingShipmentPlanToCustomer.ARAPObjectSettings                   AS ARAPObjectSettings,
		|	&InvoiceForOrders                                              AS InvoiceForOrders,
		|	&ExceedingOrder                                                     AS ExceedingOrder,
		|	
		|	CASE
		|		WHEN IncreasingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			AND ISNULL(&ARAPObjectOfOrder, UNDEFINED) <> UNDEFINED
		|			THEN ARAPObjectOrder.Ref
		|		WHEN IncreasingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectsContract.Ref
		|		ELSE IncreasingShipmentPlanToCustomer.ARAPObject
		|	END                                                            AS ARAPObject,
		|	IncreasingShipmentPlanToCustomer.ARAPCurrency              AS ARAPCurrency,
		|	
		|	IncreasingShipmentPlanToCustomer.IncreaseToBeSHIPPED                AS IncreaseToBeSHIPPED,
		|
		|	IncreasingShipmentPlanToCustomer.BusinessOperation             AS BusinessOperation,
		|	&SalesOrder_                                                    AS SalesOrder_,
		|	IncreasingShipmentPlanToCustomer.RecorderDate                  AS RecorderDate,
		|	ISNULL(ContractData.AllowableAmountPayable, 0)         AS AllowableAmountPayable,
		|	IncreasingShipmentPlanToCustomer.DocumentCurrency                   AS DocumentCurrency,
		|
		|	CASE
		|		WHEN IncreasingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN IncreasingShipmentPlanToCustomer.ARAPObject.Organization
		|		WHEN IncreasingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectsContract.Organization
		|		WHEN ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)
		|			THEN IncreasingShipmentPlanToCustomer.ARAPObject.Organization
		|		ELSE IncreasingShipmentPlanToCustomer.Organization
		|	END                                                            AS Organization,
		|	CASE
		|		WHEN IncreasingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN IncreasingShipmentPlanToCustomer.ARAPObject.Partner
		|		ELSE IncreasingShipmentPlanToCustomer.Partner
		|	END                                                            AS Partner,
		|	CASE
		|		WHEN IncreasingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectsContract.Counterparty
		|		ELSE IncreasingShipmentPlanToCustomer.ARAPObject.Counterparty
		|	END                                                            AS Counterparty,
		|	CASE
		|		WHEN IncreasingShipmentPlanToCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ContractData.Ref
		|		ELSE IncreasingShipmentPlanToCustomer.ARAPObject.Contract
		|	END                                                            AS Contract,
		|	IncreasingShipmentPlanToCustomer.RecorderNumber                 AS RecorderNumber,
		|	ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)             AS ExecutionScheduleIsSpecified,
		|	ISNULL(ISNULL(DocumentSalesOrder.ThisIsOrderAsInvoice, DocumentRequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice), FALSE) AS ThisIsOrderAsInvoice
		|FROM
		|	#IncreasingShipmentPlanToCustomer AS IncreasingShipmentPlanToCustomer
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = IncreasingShipmentPlanToCustomer.ARAPObject.Contract
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectsContract
		|			ON ARAPObjectsContract.Object = ContractData.Ref
		|				AND ARAPObjectsContract.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|				AND ARAPObjectsContract.Organization = IncreasingShipmentPlanToCustomer.ARAPObject.Organization
		|				AND NOT ARAPObjectsContract.OnlyBalance
		|				AND NOT ARAPObjectsContract.DeletionMark
		|		LEFT JOIN Document.SalesOrder AS DocumentSalesOrder
		|			ON &SalesOrder_ = DocumentSalesOrder.Ref
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|			ON &SalesOrder_ = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectOrder
		|			ON &ARAPObjectOfOrder = ARAPObjectOrder.Ref
		|				AND NOT ARAPObjectOrder.OnlyBalance
		|WHERE
		|	IncreasingShipmentPlanToCustomer.IncreaseToBeSHIPPED <> 0
		|";
	
	QueryText = StrReplace(QueryText,"&InvoiceForOrders",   InvoiceForOrders);
	QueryText = StrReplace(QueryText,"&ExceedingOrder",          ExceedingOrder);
	QueryText = StrReplace(QueryText,"&SalesOrder_",         SalesOrder_);
	QueryText = StrReplace(QueryText,"&ARAPObjectOfOrder", ARAPObjectOfOrder);
	
	Return QueryText;
	
EndFunction

#EndRegion