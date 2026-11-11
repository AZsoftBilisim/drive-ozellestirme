#Region Public

// Supplements the texts of the document execution request with the texts of the contract execution schedule
// with the supplier in the Accounts with suppliers register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextPaymentPlans - String - The text of the request to receive data to reflect the payment plan to the supplier.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of settlement is a contract.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - The currency of the document.
// 	     [Details of the mechanism]
// 	     * PaymentDate - Date - The planned payment date of the stage.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements. 
// 	     * PaymentOption - EnumRef.OptionsForControllingPaymentToSupplier - Payment option for the schedule stage.
// 	TextDeliveryPlans - String - The text of the request to receive document data to reflect the delivery plan.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - The currency of the document.
// 	     [Document details]
// 	     * DateOfReceipt - Date - The planned delivery date of the line/document.
// 	     * IncreaseToAdmission - DefinedType.MonetaryAmountPositiveNegative - The amount to be received in the currency of mutual settlements.
//
Procedure CarryingOutScheduleOfExecutionOfContractWithSupplier(Query, QueryTexts, Registers, TextPaymentPlans, TextDeliveryPlans) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	Operation = "ExecutionScheduleSupplier";
	TypeOfOperationForSorting = "1";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	TextsOfDocumentDataRequests.Insert("IncreasingPaymentPlanToSupplier", TextPaymentPlans);
	ArrayOfTexts.Add(IncreasePaymentPlanToSupplier(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("IncreasingDeliveryPlan", TextDeliveryPlans);
	TTTemplateTexts.Insert("TTIncreaseInDeliveryPlan", QueryTextTTIncreasingDeliveryPlan());
	ArrayOfTexts.Add(IncreaseDeliveryPlanFromSupplier(Operation, TypeOfOperationForSorting));
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the order to the supplier in the Accounts with suppliers register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextPaymentPlans - String - The text of the request to receive data to reflect the payment plan to the supplier.
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
// 	     * PaymentOption - EnumRef.OptionsForControllingPaymentToSupplier - Payment option for the schedule stage.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements (including the deposit for the container).
// 	TextDeliveryPlans - String - The text of the request to receive document data to reflect the shipment plan.
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
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * DateOfReceipt - Date - The planned delivery date of the line/document.
// 	     * IncreaseToAdmission - DefinedType.MonetaryAmountPositiveNegative - The amount to be received in the currency of the document (including the deposit for the container).
// 
Procedure ExecutionOfOrderToSupplier(Query, QueryTexts, Registers, TextPaymentPlans = "", TextDeliveryPlans = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If TextPaymentPlans = "" And TextDeliveryPlans = "" Then
		Return;
	EndIf;
	
	Operation = "PurchaseOrder";
	TypeOfOperationForSorting = "1";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	If ValueIsFilled(TextPaymentPlans) Then
		TextsOfDocumentDataRequests.Insert("IncreasingPaymentPlanToSupplier", TextPaymentPlans);
		ArrayOfTexts.Add(IncreasePaymentPlanToSupplier(Operation, TypeOfOperationForSorting));
	EndIf;
	
	If ValueIsFilled(TextDeliveryPlans) Then
		TextsOfDocumentDataRequests.Insert("IncreasingDeliveryPlan", TextDeliveryPlans);
		TTTemplateTexts.Insert("TTIncreaseInDeliveryPlan", QueryTextTTIncreasingDeliveryPlan());
		ArrayOfTexts.Add(IncreaseDeliveryPlanFromSupplier(Operation, TypeOfOperationForSorting));
	EndIf;
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the document request with the texts of payment to the supplier in the Payments with suppliers register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextPayment - String - The text of the request to receive payment data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The settlement object for which the payment is made.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of the mutual settlements of the document.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * MaturityDate - Date - The planned repayment date of the advance
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of the payment in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The amount of the payment in the settlement currency.
// 	     * ReductionIsPaid - DefinedType.MonetaryAmountPositiveNegative - The amount to be reduced is "Paid", for example, when paying by request.
// 	     * IncreaseIsPaid - DefinedType.MonetaryAmountPositiveNegative - The amount to be increased is "Paid", for example, when the payment is made in the system, but not confirmed by the bank.
// 	     * SumMan - DefinedType.MonetaryAmountPositiveNegative - The amount of payment in the currency of management accounting
// 	     * SumCompl - DefinedType.MonetaryAmountPositiveNegative - The amount of payment in the currency of regulated accounting
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * PaymentRequest - DocumentRef.PaymentRequest - The application for which the payment is made.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * FinRecordID - String - A string with the value of the unique identifier of the header or line of the document.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up the business operation of the document.
// 	TypeOfOperationForSorting - String - The type of operation is a string for sorting the distribution within a day, if it differs from the default value.
Procedure MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment, TypeOfOperationForSorting = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(TextPayment) Then
		Return;
	EndIf;
	
	Operation = "PaymentToVendor";
	TypeOfOperationForSorting = ?(ValueIsFilled(TypeOfOperationForSorting),TypeOfOperationForSorting,"4");
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	//Transfer of payment under the central agreement
	TTTemplateTexts.Insert("TTTransferOfPaymentsSupplier", ARAPAccountingPosting.TTTextForTransferringCalculations("IncreaseInSupplierDebt"));
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();

	//Transfer of payment under the central agreement
	ArrayOfTexts.Add(ReflectTransferOfSettlementsWithSupplier(Query, "TransferOfPaymentUnderCentralizedContract", TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("ReducingPaymentPlanToSupplier", TextPayment);
	ArrayOfTexts.Add(ReducePaymentPlanToSupplier(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("IncreaseInSupplierDebt", TextPayment);
	ArrayOfTexts.Add(IncreaseSupplierDebt(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("IncreaseIsPaidToSupplier", TextPayment);
	ArrayOfTexts.Add(IncreaseIsPaidToSupplier_(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("ReductionIsPaidToSupplier", TextPayment);
	ArrayOfTexts.Add(FeeIsPaidToSupplier(TypeOfOperationForSorting));
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the purchase in the register of Payments with suppliers.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextPurchase - String - The text of the request to receive document data. Reflects the purchase itself.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of the mutual settlements of the document.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * PaymentDate - Date - The planned date of payment for the entire document/payment stage.
// 	     * PurchaseOrder_ - DocumentRef - The order for which the purchase takes place.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The purchase amount in the currency of the document (including the deposit for the container).
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The purchase amount in the currency of mutual settlements (including the deposit for the container).
// 	     * DepositForPackage - DefinedType.MonetaryAmountPositiveNegative - The amount of the deposit for the container in the currency of mutual settlements.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * InvoiceForOrders - Boolean - The invoice was entered by order(s).
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	TextPaymentPlan - String - The text of the request to receive data from the planned payment document to the supplier. Reflects the increase in the payment plan to the supplier.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of the mutual settlements of the document.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * PaymentDate - Date - The planned date of payment for the entire document/payment stage.
// 	     * InvoiceForOrders - Boolean - The invoice was entered by order(s).
// 	     * ExceedingOrder - Boolean - This is an over-order purchase.
// 	     * PurchaseOrder_ - DocumentRef - The order for which the purchase takes place.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * PaymentOption - EnumRef.OptionsForControllingPaymentToSupplier - Payment option for the schedule stage.
// 	TextTransferOfAdvancePayment - String - The text of the request to receive document data on credited advances.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * CalculationObjectSource - CatalogRef.ARAPObjects - Object of advance payment calculations.
// 	     * CalculationObjectReceiver - CatalogRef.ARAPObjects - The object of the document calculations.
// 	     [General]
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of the mutual settlements of the document.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - An economic operation of transferring or reserving an advance.
// 	     [Document details]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The settlement amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	TextProducts_1 - String - The text of the request to receive the data of the planned delivery document from the supplier. Reflects an increase in the supplier's delivery plan.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the document.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of the mutual settlements of the document.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * ARAPObjectSettings - EnumRef.ARAPObjectSettings - The order /detail of the calculations of the document.
// 	     * InvoiceForOrders - Boolean - The invoice was entered by order(s).
// 	     * ExceedingOrder - Boolean - This is an over-order purchase.
// 	     * PurchaseOrder_ - DocumentRef - The order for which the purchase takes place.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The amount of mutual settlements of the line of goods, reduces the delivery plan.
// 	     * IncreaseToAdmission - DefinedType.MonetaryAmountPositiveNegative - The amount of the increase in the delivery plan.
// 	     * ReduceToAdmission - DefinedType.MonetaryAmountPositiveNegative - The amount of reduction of the delivery plan.
// 	TypeOfOperationForSorting - String - The type of operation is a string for sorting the distribution within a day,
// 	                                    if it differs from the default value.
//
Procedure Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan, TextTransferOfAdvancePayment = "", TextProducts_1 = "", TypeOfOperationForSorting = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If TextPurchase = "" And TextPaymentPlan = "" And TextTransferOfAdvancePayment = "" And TextProducts_1 = "" Then
		Return;
	EndIf;
	
	Operation = "Purchase";
	TypeOfOperationForSorting = ?(ValueIsFilled(TypeOfOperationForSorting), TypeOfOperationForSorting, "2");
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	// Offsetting the advance
	If ValueIsFilled(TextTransferOfAdvancePayment) Then
		TextsOfDocumentDataRequests.Insert("PaymentDecryptionTableSupplier", TextTransferOfAdvancePayment);
		ArrayOfTexts.Add(ReflectTransferOfSettlementsWithSupplier(Query, Operation, TypeOfOperationForSorting)); //Transfer of advances on invoices
	EndIf;
	
	// Transfer of debt under the central agreement
	If ValueIsFilled(TextPurchase) Then
		ArrayOfTexts.Add(TextTransferOfSupplierDebtBetweenBranches(TypeOfOperationForSorting));
	EndIf;
	
	If ValueIsFilled(TextPaymentPlan) Then
		
		// Increasing the payment plan
		TextsOfDocumentDataRequests.Insert("IncreasingPaymentPlanToSupplier", TextPaymentPlan);
		ArrayOfTexts.Add(IncreasePaymentPlanToSupplier(Operation,TypeOfOperationForSorting));
		
		// reduction of the payment plan for orders
		TextsOfDocumentDataRequests.Insert("ReducingPaymentPlanToSupplier", TextPaymentPlan);
		ArrayOfTexts.Add(ReducePaymentPlanToSupplier(Operation, TypeOfOperationForSorting, ,ValueIsFilled(TextProducts_1)));
		
	EndIf;
	
	// Increase in debt to the supplier
	If ValueIsFilled(TextPurchase) Then
		TextsOfDocumentDataRequests.Insert("IncreasingOurSupplierDebt", TextPurchase);
		ArrayOfTexts.Add(IncreaseOurSupplierDebt(Operation, TypeOfOperationForSorting));
	EndIf;
	
	If ValueIsFilled(TextProducts_1) Then
		
		// Reducing the delivery plan
		TextsOfDocumentDataRequests.Insert("ReducingDeliveryPlan", TextProducts_1);
		TTTemplateTexts.Insert("TTReductionOfDeliveryPlan", QueryTextTTReducingDeliveryPlan());
		ArrayOfTexts.Add(ReduceDeliveryPlanFromSupplier(TypeOfOperationForSorting));
	
		// Increase in the delivery plan - over the order
		TextsOfDocumentDataRequests.Insert("IncreasingDeliveryPlan", TextProducts_1);
		TTTemplateTexts.Insert("TTIncreaseInDeliveryPlan", QueryTextTTIncreasingDeliveryPlan(True));
		ArrayOfTexts.Add(IncreaseDeliveryPlanFromSupplier(Operation, TypeOfOperationForSorting));
		
	EndIf;
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the request for payment to the supplier in the Payments with suppliers register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextSettlements - String - The text of the request to receive application data.
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
// 	     * IncreaseIsPaid - DefinedType.MonetaryAmountPositiveNegative - The amount of the application in the currency of mutual settlements to be paid.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
//
Procedure ExecutionOfRequestForPaymentToSupplier(Query, QueryTexts, Registers, TextSettlements) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If TextSettlements = "" Then
		Return;
	EndIf;
	
	Operation = "RequestForPaymentToSupplier";
	TypeOfOperationForSorting = "1";
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	TextsOfDocumentDataRequests = New Structure();
	
	TextsOfDocumentDataRequests.Insert("IncreaseIsPaidToSupplier", TextSettlements);
	TextOfPaymentPlanIncrease = IncreaseIsPaidToSupplier_(Operation,TypeOfOperationForSorting);
	
	TextSettlementsWithSuppliers = TextOfPaymentPlanIncrease;
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the text of the document request with the text of the payment refund from the supplier in the Payments with suppliers register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextOfReport - String - The text of the request to receive return data. Reflects the Cash return itself.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * FinRecordID - String - The ID of the financial movement for the organization of a double entry.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up the reflection of a business transaction in the fin. accounting.
// 	     [Document details]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * FinRecordID - String - A string with the value of the unique identifier of the header or line of the document.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up the business operation of the document.
// 	TextTransferOfCalculations - String - Optional, the text of the request to receive payment decryption data to which the Cash return should be transferred.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * CalculationObjectSource - CatalogRef.ARAPObjects - The object of calculations to which the return of the DS is credited.
// 	     * CalculationObjectReceiver - CatalogRef.ARAPObjects - The settlement object for which the payment is planned.
// 	     [General]
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The economic operation of transferring payments.
// 	     [Details of the tabular part]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of the offset in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The amount of the offset in the currency of mutual settlements.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
//
Procedure ConductingRefundFromSupplier(Query, QueryTexts, Registers, TextOfReport, TextTransferOfCalculations = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	If TextOfReport = "" And TextTransferOfCalculations = "" Then
		Return;
	EndIf;
	
	Operation = "RefundOfPaymentFromSupplier";
	TypeOfOperationForSorting = "5";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	If ValueIsFilled(TextOfReport) Then
	
		TextsOfDocumentDataRequests.Insert("IncreasingOurSupplierDebt", TextOfReport);
		ArrayOfTexts.Add(IncreaseOurSupplierDebt(Operation, TypeOfOperationForSorting));
		
		TextsOfDocumentDataRequests.Insert("IncreasingPaymentPlanToSupplier", TextOfReport);
		ArrayOfTexts.Add(IncreasePaymentPlanToSupplier(Operation, TypeOfOperationForSorting));
	
	EndIf;
	
	// Transfer of advance payment
	If ValueIsFilled(TextTransferOfCalculations) Then
		TextsOfDocumentDataRequests.Insert("PaymentDecryptionTableSupplier", TextTransferOfCalculations);
		ArrayOfTexts.Add(ReflectTransferOfSettlementsWithSupplier(Query, Operation, TypeOfOperationForSorting, "2"));
	EndIf;
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the return of goods to the supplier in the register of Payments with suppliers.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextReturn - String - The text of the request to get document data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * Organization - CatalogRef.Companies - Organization of the return of goods.
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * FinRecordID - String - The ID of the financial movement for the organization of a double entry.
// 	       In most cases, the field is defined as an object of accounts.A unique identifier, in special cases, may have a value unrelated to the object of calculations.
// 	     * BusinessTransactionSetting - Undefined, CatalogRef.BusinessTransactionsSettings - Setting up the reflection of a business transaction in the fin. accounting.
// 	       In most cases, the field has the value Undefined, in special cases, a reference to a directory element may be specified.
// 	     [Document details]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	TextTransferOfCalculations - String - The text of the request to receive the decryption data of the refund payment for which the refund is credited.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * CalculationObjectSource - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     * CalculationObjectReceiver - CatalogRef.ARAPObjects - The settlement object to which the refund is credited.
// 	     [General]
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements of the settlement object to which the refund is credited.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Details of the tabular part]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The settlement amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
//
Procedure CarryingOutReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextReturn, TextTransferOfCalculations = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	Operation = "ReturnOfGoodsToVendor";
	TypeOfOperationForSorting = "3";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	// Transfer of debt under the central agreement
	TTTemplateTexts.Insert("TTTransferOfPaymentsSupplier", ARAPAccountingPosting.TTTextForTransferringCalculations("IncreaseInSupplierDebt"));
	
	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	ArrayOfTexts.Add(ReflectTransferOfSettlementsWithSupplier(Query, "PostponementOfReturnOfGoodsUnderCentralizedContract", TypeOfOperationForSorting, "1"));
	
	TextsOfDocumentDataRequests.Insert("ReducingPaymentPlanToSupplier", TextReturn);
	ArrayOfTexts.Add(ReducePaymentPlanToSupplier(Operation, TypeOfOperationForSorting, "2"));
	
	TextsOfDocumentDataRequests.Insert("IncreaseInSupplierDebt", TextReturn);
	ArrayOfTexts.Add(IncreaseSupplierDebt(Operation, TypeOfOperationForSorting, "2"));
	
	If ValueIsFilled(TextTransferOfCalculations) Then
		TextsOfDocumentDataRequests.Insert("PaymentDecryptionTableSupplier", TextTransferOfCalculations);
		ArrayOfTexts.Add(ReflectTransferOfSettlementsWithSupplier(Query, Operation, TypeOfOperationForSorting, "3"));
	EndIf;
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
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
// 	     * PaymentDate - Date - The planned date of payment for the entire document/payment stage.
// 	     * PaymentOption - EnumRef.CustomerPaymentControlOptions - Payment option for the schedule stage.
// 	     * AmountDue - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements (including the deposit for the container).
// 
Procedure ConductingSettlementsWithSuppliersPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccountingCashFlowPlan", Registers) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(TextPaymentPlans) Then
		Return;
	EndIf;
	
	ReflectionTemplateTexts = New Structure();
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	#EndRegion
	
	#Region ConductingSettlementsWithSuppliersPaymentPlan
	
	TextsOfDocumentDataRequests = New Structure();
	TextsOfDocumentDataRequests.Insert("IncreasingPaymentPlanToSupplier", TextPaymentPlans);
	
	QueryText ="SELECT
		|	IncreasingPaymentPlanToSupplier.RecorderDate                    AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                              AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                     AS AccountingDimensionByPartners,
		|	IncreasingPaymentPlanToSupplier.ARAPObject                      AS ARAPObject,
		|	IncreasingPaymentPlanToSupplier.ARAPCurrency                AS Currency,
		|	
		|	IncreasingPaymentPlanToSupplier.AmountDue                             AS AmountDue,
		|	
		|	IncreasingPaymentPlanToSupplier.Ref                              AS DocumentPlan,
		|	IncreasingPaymentPlanToSupplier.PaymentDate                         AS PlannedRepaymentDate,
		|	IncreasingPaymentPlanToSupplier.RecorderDate                    AS OccurrenceDate,
		|	IncreasingPaymentPlanToSupplier.RecorderDate                    AS RecorderDate,
		|	IncreasingPaymentPlanToSupplier.RecorderNumber                   AS RecorderNumber,
		|	IncreasingPaymentPlanToSupplier.PaymentOption                       AS PaymentOption,
		|	1                                                                   AS Kind,
		|	IncreasingPaymentPlanToSupplier.Ref                              AS DocumentRecorder,
		|	
		|	IncreasingPaymentPlanToSupplier.ARAPObject.Organization          AS Organization,
		|	IncreasingPaymentPlanToSupplier.Partner                             AS Partner,
		|	IncreasingPaymentPlanToSupplier.ARAPObject.Counterparty           AS Counterparty,
		|	IncreasingPaymentPlanToSupplier.ARAPObject.Contract              AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                        AS LineOfBusiness
		|FROM
		|	#IncreasingPaymentPlanToSupplier AS IncreasingPaymentPlanToSupplier
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreasingPaymentPlanToSupplier.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON IncreasingPaymentPlanToSupplier.ARAPObject.Organization = Dimension.Organization
		|				AND IncreasingPaymentPlanToSupplier.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND IncreasingPaymentPlanToSupplier.Partner = Dimension.Partner
		|				AND IncreasingPaymentPlanToSupplier.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|";
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccountingCashFlowPlan", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccountingCashFlowPlan", QueryText);
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
EndProcedure

// Supplements the texts of the document request with the texts of the client's order execution in the accounts With clients register.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextDeliveryPlans - String - The text of the request to receive data to reflect the payment plan.
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
// 	     * MaturityDate - Date - Planned delivery date
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount to be paid in the currency of mutual settlements (including the deposit for the container).
// 	ThisIsScheduleOfContract - Boolean - The schedule of execution of the Contract is carried out, otherwise the Order
//
Procedure ConductingSettlementsWithSuppliersDeliveryPlan(Query, QueryTexts, Registers, TextDeliveryPlans, ThisIsScheduleOfContract = False) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccountingPlannedDeliveries", Registers) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(TextDeliveryPlans) Then
		Return;
	EndIf;
	
	ReflectionTemplateTexts = New Structure();
	
	#Region ConductingSettlementsWithSuppliersDeliveryPlan
	
	TextsOfDocumentDataRequests = New Structure();
	TextsOfDocumentDataRequests.Insert("IncreasingDeliveryPlan", TextDeliveryPlans);
	
	Query.SetParameter("ThisIsScheduleOfContract",ThisIsScheduleOfContract);
	
	QueryText ="SELECT
		|	IncreasingDeliveryPlan.RecorderDate                    AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                      AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)             AS AccountingDimensionByPartners,
		|	IncreasingDeliveryPlan.ARAPObject                      AS ARAPObject,
		|	IncreasingDeliveryPlan.ARAPCurrency                AS Currency,
		|	
		|	IncreasingDeliveryPlan.IncreaseToAdmission               AS Sum,
		|	
		|	IncreasingDeliveryPlan.Ref                              AS DocumentPlan,
		|	IncreasingDeliveryPlan.DateOfReceipt                     AS PlannedRepaymentDate,
		|	IncreasingDeliveryPlan.RecorderDate                    AS OccurrenceDate,
		|	IncreasingDeliveryPlan.RecorderDate                    AS RecorderDate,
		|	IncreasingDeliveryPlan.RecorderNumber                   AS RecorderNumber,
		|	FALSE                                                        AS UnallocatedAdvancePayment,
		|	1                                                           AS Kind,
		|	IncreasingDeliveryPlan.Ref                              AS DocumentRecorder,
		|	
		|	CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|					THEN IncreasingDeliveryPlan.Organization
		|					ELSE IncreasingDeliveryPlan.ARAPObject.Organization
		|	END                                                       AS Organization,
		|	IncreasingDeliveryPlan.Partner                             AS Partner,
		|	IncreasingDeliveryPlan.ARAPObject.Counterparty           AS Counterparty,
		|	IncreasingDeliveryPlan.ARAPObject.Contract              AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                AS LineOfBusiness
		|FROM
		|	#IncreasingDeliveryPlan AS IncreasingDeliveryPlan
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreasingDeliveryPlan.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = IncreasingDeliveryPlan.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|			ON CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|					THEN IncreasingDeliveryPlan.Organization
		|					ELSE IncreasingDeliveryPlan.ARAPObject.Organization
		|				END = Dimension.Organization
		|				AND IncreasingDeliveryPlan.ARAPObject.Counterparty = Dimension.Counterparty
		|				AND IncreasingDeliveryPlan.Partner = Dimension.Partner
		|				AND IncreasingDeliveryPlan.ARAPObject.Contract = Dimension.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	IncreasingDeliveryPlan.IncreaseToAdmission <> 0
		|	AND IncreasingDeliveryPlan.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|	AND (&ThisIsScheduleOfContract OR NOT ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE))
		|";
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccountingPlannedDeliveries", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccountingPlannedDeliveries", QueryText);
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the return of goods to the supplier in the register of Payments with suppliers.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	Text Return - String is the Query Text for receiving document data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * Organization - CatalogRef.Companies - Organization of the return of goods.
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * FinRecordID - String - The ID of the financial movement for the organization of a double entry.
// 	       In most cases, the field is defined as an object of accounts.A unique identifier, in special cases, may have a value unrelated to the object of calculations.
// 	     * BusinessTransactionSetting - Undefined, CatalogRef.BusinessTransactionsSettings - Setting up the reflection of a business transaction in the fin. accounting.
// 	       In most cases, the field has the value Undefined, in special cases, a reference to a directory element may be specified.
// 	     [Document details]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	TextTransferOfCalculations - String - The text of the request to receive the decryption data of the refund payment for which the refund is credited.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * CalculationObjectSource - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     * CalculationObjectReceiver - CatalogRef.ARAPObjects - The settlement object to which the refund is credited.
// 	     [General]
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements of the settlement object to which the refund is credited.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Details of the tabular part]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The settlement amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
//
Procedure CarryingOutTransferOfAdvancePaymentToSupplier(Query, QueryTexts, Registers, TextTransferOfCalculations = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	Operation = "TransferOfAdvancePaymentToSupplier";
	TypeOfOperationForSorting = "4";
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	TextsOfDocumentDataRequests.Insert("PaymentDecryptionTableSupplier", TextTransferOfCalculations);
	ArrayOfTexts.Add(ReflectTransferOfSettlementsWithSupplier(Query, Operation,TypeOfOperationForSorting));
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the return of goods to the supplier in the register of Payments with suppliers.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	Text Return - String is the Query Text for receiving document data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * Organization - CatalogRef.Companies - Organization of the return of goods.
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * FinRecordID - String - The ID of the financial movement for the organization of a double entry.
// 	       In most cases, the field is defined as an object of accounts.A unique identifier, in special cases, may have a value unrelated to the object of calculations.
// 	     * BusinessTransactionSetting - Undefined, CatalogRef.BusinessTransactionsSettings - Setting up the reflection of a business transaction in the fin. accounting.
// 	       In most cases, the field has the value Undefined, in special cases, a reference to a directory element may be specified.
// 	     [Document details]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The refund amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	TextTransferOfCalculations - String - The text of the request to receive the decryption data of the refund payment for which the refund is credited.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * CalculationObjectSource - CatalogRef.ARAPObjects - The object of the refund calculations.
// 	     * CalculationObjectReceiver - CatalogRef.ARAPObjects - The settlement object to which the refund is credited.
// 	     [General]
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements of the settlement object to which the refund is credited.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Details of the tabular part]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The settlement amount in the settlement currency.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
//
Procedure CarryingOutReturnOfAdvanceTransferToSupplier(Query, QueryTexts, Registers, TextTransferOfCalculations = "") Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;
	
	Operation = "ReturnOfAdvanceTransferToSupplier";
	TypeOfOperationForSorting = "5";
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	TextsOfDocumentDataRequests.Insert("PaymentDecryptionTableSupplier", TextTransferOfCalculations);
	ArrayOfTexts.Add(ReflectTransferOfSettlementsWithSupplier(Query, Operation, TypeOfOperationForSorting));
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the payment from the client according to the register of Settlements with customers
// and the register of Settlements with suppliers. Expense on the register settlements with customers and arrival on the register settlements with suppliers
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextOfClientSObligation - String - The text of the request to receive payment data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The settlement object for which the payment is made.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - The business operation of the document.
// 	     [Document details]
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The amount of payment in the currency of mutual settlements.
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of payments in the currency of the document.
// 	     * BeingPaid - DefinedType.MonetaryAmountPositiveNegative - The amount of the increase is "Paid".
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * ProformaInvoice - DocumentRef.CustomerCommercialInvoice - The invoice for which the payment is made.
// 	     * LinkedDocument - DocumentRef.CustomerInvoice,
// 	                           Document link.The implementation of the services of other assets is a related adjustment document for determining the reflection rate.
// 	     * FinRecordID - String - A string with the value of the unique identifier of the header or line of the document.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up the business operation of the document.
// 	TextOfObligationToSupplier - String - The text of the request to receive payment data.
// 	     The request should return a selection of fields:
// 	     * Ref - DocumentRef - The document is the registrar of the operation.
// 	     [General]
// 	     * ARAPObject - CatalogRef.ARAPObjects - The settlement object for which the payment is made.
// 	     * RecorderDate - Date - Date and time of the registrar's document.
// 	     * RecorderNumber - String - The number of the registrar's document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of the mutual settlements of the document.
// 	     * DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * FinRecordID - String - The ID of the financial movement for the organization of a double entry.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up the reflection of a business transaction in the fin. accounting.
// 	     [Document details]
// 	     * Sum - DefinedType.MonetaryAmountPositiveNegative - The amount of the payment in the currency of the document.
// 	     * AmountARAP - DefinedType.MonetaryAmountPositiveNegative - The amount of the payment in the settlement currency.
// 	     * ReductionIsPaid - DefinedType.MonetaryAmountPositiveNegative - The amount to be reduced is "Paid", for example, when paying by request.
// 	     * IncreaseIsPaid - DefinedType.MonetaryAmountPositiveNegative - The amount to be increased is "Paid", for example, when the payment is made in the system, but not confirmed by the bank.
// 	     * CashFlowItem - CatalogRef.CashFlowReportItems - The DDS article.
// 	     * PaymentRequest - DocumentRef.PaymentRequest - The application for which the payment is made.
// 	     * PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
// 	     * DateOfCourse - Date - The date on which the exchange rates should be taken to calculate the amounts in management and regulated accounting.
// 	     * FinRecordID - String - A string with the value of the unique identifier of the header or line of the document.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up the business operation of the document.
//
Procedure OffsettingOfCounterDebt(Query, QueryTexts, Registers, TextOfClientSObligation, TextOfObligationToSupplier) Export
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers)
			And Not DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		Return;
	EndIf;

	#Region CustomersARAPAccounting
	// Conducting by clients
	Operation = "OffsettingClientSCounterObligations";
	TypeOfOperationForSorting = "4";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	// Transfer of payment under the central agreement
	TTTemplateTexts.Insert("TTTransferOfPaymentsClient", ARAPAccountingPosting.TTTextForTransferringCalculations("TablePaymentFromCustomer"));

	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	TextsOfDocumentDataRequests.Insert("ReductionOfPaymentPlanFromCustomer", TextOfClientSObligation);
	ArrayOfTexts.Add(ARAPAccountingPostingCustomers.ReducePaymentPlanFromCustomer(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("TablePaymentFromCustomer", TextOfClientSObligation);
	ArrayOfTexts.Add(ARAPAccountingPostingCustomers.IncreaseOurCustomerDebt(Operation, TypeOfOperationForSorting, "5"));
	
	TextSettlementsWithClients = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("CustomersARAPAccounting", TextSettlementsWithClients);
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	// Conducting by suppliers
	Operation = "OffsettingSupplierSObligations";
	
	#Region TemporaryTable
	
	TTTemplateTexts = New Structure();
	
	//Transfer of payment under the central agreement
	TTTemplateTexts.Insert("TTTransferOfPaymentsSupplier", ARAPAccountingPosting.TTTextForTransferringCalculations("IncreaseInSupplierDebt"));

	#EndRegion
	
	#Region Posting
	
	ArrayOfTexts = New Array;
	TextsOfDocumentDataRequests = New Structure();
	
	TextsOfDocumentDataRequests.Insert("ReducingPaymentPlanToSupplier", TextOfObligationToSupplier);
	ArrayOfTexts.Add(ReducePaymentPlanToSupplier(Operation, TypeOfOperationForSorting));
	
	TextsOfDocumentDataRequests.Insert("IncreaseInSupplierDebt", TextOfObligationToSupplier);
	ArrayOfTexts.Add(IncreaseSupplierDebt(Operation, TypeOfOperationForSorting, "5"));
	
	TextSettlementsWithSuppliers = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VendorsARAPAccounting", Registers) Then
		ReflectionTemplateTexts.Insert("VendorsARAPAccounting", TextSettlementsWithSuppliers);
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TTTemplateTexts);
	
	#EndRegion
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
EndProcedure

#EndRegion

#Region Private

Function ReflectTransferOfSettlementsWithSupplier(Query, Operation, TypeOfOperationForSorting, OrderOfOperationsWithinDocument = "1")
	
	If Not Query.Parameters.Property("ARAPObjectPrepayment") Then
		ARAPObjectPrepayment = Metadata.DefinedTypes.ARAPObjectPrepayment.Type.Types();
		Query.SetParameter("ARAPObjectPrepayment", ARAPObjectPrepayment);
	EndIf;
	
	If Operation = "Purchase" Then
		
		AccountsPayable = "FALSE"; // what's in the source
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "TRUE";
		
		OperationCondition = "
		|	PaymentDecryptionTableSupplier.CalculationObjectSource <> PaymentDecryptionTableSupplier.CalculationObjectReceiver";
		
		BusinessOperation = "PaymentDecryptionTableSupplier.BusinessOperation";
		
		PaymentMethod = "Undefined";
		
		SettlementObjectSourceOrganization = "CalculationObjectsSources.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
	
		SettlementObjectSourcePartner = "CalculationObjectsSources.Partner";
		SettlementObjectReceiverPartner = "CalculationObjectsReceivers.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTableSupplier.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTableSupplier.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTableSupplier.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTableSupplier.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTableSupplier.RecorderDate";
		
		PaymentOption = "VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt)";
		CashFlowItem = "Undefined";
	
		FinRecordID = "PaymentDecryptionTableSupplier.CalculationObjectSource.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)"; 
		
		SettlementOperationSource = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		SettlementOperationReceiver = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		
	ElsIf Operation = "TransferOfPaymentUnderCentralizedContract" Then
		
		AccountsPayable = "FALSE"; // what's in the source
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "TRUE";
		
		OperationCondition = "PaymentDecryptionTableSupplier.Organization <> CalculationObjectsReceivers.Organization";
		
		BusinessOperation = "VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)";

		PaymentMethod = "Undefined";
		
		SettlementObjectSourceOrganization = "PaymentDecryptionTableSupplier.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
		
		SettlementObjectSourcePartner = "PaymentDecryptionTableSupplier.Partner";
		SettlementObjectReceiverPartner = "PaymentDecryptionTableSupplier.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTableSupplier.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTableSupplier.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTableSupplier.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTableSupplier.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTableSupplier.RecorderDate";
		PaymentOption = "VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned)";
		CashFlowItem = "PaymentDecryptionTableSupplier.CashFlowItem";
	
		FinRecordID = "PaymentDecryptionTableSupplier.CalculationObjectSource.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.PaymentTransferBetweenBranchOffices)";
		
		SettlementOperationSource = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		SettlementOperationReceiver = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		OrderOfOperationsWithinDocument = "2";
		
	ElsIf Operation = "PostponementOfReturnOfGoodsUnderCentralizedContract" Then
		
		AccountsPayable = "FALSE"; // what's in the source
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "FALSE";
		
		OperationCondition = "ISNULL(ContractData.CentralizedContract, FALSE)
		|	AND PaymentDecryptionTableSupplier.Organization <> CalculationObjectsReceivers.Organization";
		
		BusinessOperation = "VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)";

		PaymentMethod = "Undefined";
		
		SettlementObjectSourceOrganization = "PaymentDecryptionTableSupplier.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
		
		SettlementObjectSourcePartner = "PaymentDecryptionTableSupplier.Partner";
		SettlementObjectReceiverPartner = "PaymentDecryptionTableSupplier.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTableSupplier.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTableSupplier.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTableSupplier.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTableSupplier.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTableSupplier.RecorderDate";
		PaymentOption = "VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned)";
		CashFlowItem = "PaymentDecryptionTableSupplier.CashFlowItem";
	
		FinRecordID = "PaymentDecryptionTableSupplier.CalculationObjectSource.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.DebtTransferBetweenBranchOffices)";
		
		SettlementOperationSource = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		SettlementOperationReceiver = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		OrderOfOperationsWithinDocument = "2";
		
	ElsIf Operation = "RefundOfPaymentFromSupplier" Then
		
		AccountsPayable = "FALSE";
		StornoSource = "TRUE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "TRUE";
		
		OperationCondition = "PaymentDecryptionTableSupplier.CalculationObjectSource <> PaymentDecryptionTableSupplier.CalculationObjectReceiver";
		
		BusinessOperation = "PaymentDecryptionTableSupplier.BusinessOperation";
		
		PaymentMethod = "PaymentDecryptionTableSupplier.PaymentMethod";
		
		SettlementObjectSourceOrganization = "CalculationObjectsSources.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
	
		//The refund of the payment from the subsidiary partner should be made by the subsidiary partner, not by the parent
		SettlementObjectSourcePartner = "PaymentDecryptionTableSupplier.Partner";
		SettlementObjectReceiverPartner = "PaymentDecryptionTableSupplier.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTableSupplier.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTableSupplier.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTableSupplier.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTableSupplier.AmountARAP";
		
		PaymentDate = "Undefined";
		PaymentOption = "Undefined";
		CashFlowItem = "PaymentDecryptionTableSupplier.CashFlowItem";
		
		//To transfer, you need to write the source identifiers from the settlement objects in the payment decryption.
		FinRecordID = "PaymentDecryptionTableSupplier.CalculationObjectSource.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)";
		
		SettlementOperationSource = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		SettlementOperationReceiver = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		
	ElsIf Operation = "ReturnOfGoodsToVendor" Then
		
		AccountsPayable = "FALSE";
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "FALSE";
		
		OperationCondition = "PaymentDecryptionTableSupplier.CalculationObjectSource <> PaymentDecryptionTableSupplier.CalculationObjectReceiver";
		
		BusinessOperation = "PaymentDecryptionTableSupplier.BusinessOperation";
		
		PaymentMethod = "Undefined";
		
		SettlementObjectSourceOrganization = "CalculationObjectsSources.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
	
		SettlementObjectSourcePartner = "CalculationObjectsSources.Partner";
		SettlementObjectReceiverPartner = "CalculationObjectsReceivers.Partner";
		
		CurrencyOfSettlementsSource = "PaymentDecryptionTableSupplier.DocumentCurrency";
		CurrencyOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTableSupplier.Sum";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTableSupplier.Sum";
		ReceiverForPayment = "PaymentDecryptionTableSupplier.AmountARAP";
		
		PaymentDate = "Undefined";
		PaymentOption = "Undefined";
		CashFlowItem = "Undefined";
		
		FinRecordID = "PaymentDecryptionTableSupplier.CalculationObjectReceiver.UUID";
		BusinessTransactionSetting = "VALUE(Catalog.BusinessTransactionsSettings.ARAPSettlement)";
		
		SettlementOperationSource = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		SettlementOperationReceiver = "VALUE(Enum.SettlementOperations.TransferOfSettlements)";
		
	ElsIf Operation = "TransferOfAdvancePaymentToSupplier" Then
		AccountsPayable = "FALSE";
		StornoSource = "FALSE";
		StornoReceiver = "FALSE";
		FillingReceiverInSource = "TRUE";
		
		OperationCondition = "PaymentDecryptionTableSupplier.CalculationObjectSource <> PaymentDecryptionTableSupplier.CalculationObjectReceiver";
		
		BusinessOperation = "PaymentDecryptionTableSupplier.BusinessOperation";
		
		PaymentMethod = "VALUE(Enum.PaymentForms.SettlementOfARAP)";
		
		SettlementObjectSourceOrganization = "CalculationObjectsSources.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
	
		SettlementObjectSourcePartner = "CalculationObjectsSources.Partner";
		SettlementObjectReceiverPartner = "CalculationObjectsReceivers.Partner";
		
		CurrencyOfSettlementsSource = "CalculationObjectsSources.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "CalculationObjectsReceivers.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTableSupplier.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTableSupplier.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTableSupplier.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTableSupplier.PaymentDate";
		PaymentOption = "Undefined";
		CashFlowItem = "PaymentDecryptionTableSupplier.CashFlowItem";
		
		FinRecordID = "PaymentDecryptionTableSupplier.FinRecordID";
		BusinessTransactionSetting = "PaymentDecryptionTableSupplier.BusinessTransactionSetting";
		
		SettlementOperationSource = "VALUE(Enum.SettlementOperations.Shipment)";
		SettlementOperationReceiver = "VALUE(Enum.SettlementOperations.ARAPAdjustment)";
		
	ElsIf Operation = "ReturnOfAdvanceTransferToSupplier" Then
		AccountsPayable = "FALSE";
		StornoSource = "TRUE";
		StornoReceiver = "TRUE";
		FillingReceiverInSource = "TRUE";
		
		OperationCondition = "PaymentDecryptionTableSupplier.CalculationObjectSource <> PaymentDecryptionTableSupplier.CalculationObjectReceiver";
		
		BusinessOperation = "PaymentDecryptionTableSupplier.BusinessOperation";
		
		PaymentMethod = "VALUE(Enum.PaymentForms.SettlementOfARAP)";
		
		SettlementObjectSourceOrganization = "CalculationObjectsSources.Organization";
		SettlementObjectReceiverOrganization = "CalculationObjectsReceivers.Organization";
	
		SettlementObjectSourcePartner = "CalculationObjectsSources.Partner";
		SettlementObjectReceiverPartner = "CalculationObjectsReceivers.Partner";
		
		CurrencyOfSettlementsSource = "CalculationObjectsSources.ARAPCurrency";
		CurrencyOfMutualSettlementsReceiver = "CalculationObjectsReceivers.ARAPCurrency";
		
		AmountOfSettlementsSource = "PaymentDecryptionTableSupplier.AmountARAP";
		AmountOfMutualSettlementsReceiver = "PaymentDecryptionTableSupplier.AmountARAP";
		
		ForPaymentSource = "PaymentDecryptionTableSupplier.AmountARAP";
		ReceiverForPayment = "PaymentDecryptionTableSupplier.AmountARAP";
		
		PaymentDate = "PaymentDecryptionTableSupplier.PaymentDate";
		PaymentOption = "Undefined";
		CashFlowItem = "PaymentDecryptionTableSupplier.CashFlowItem";
		
		FinRecordID = "PaymentDecryptionTableSupplier.FinRecordID";
		BusinessTransactionSetting = "PaymentDecryptionTableSupplier.BusinessTransactionSetting";
		
		SettlementOperationSource = "VALUE(Enum.SettlementOperations.ARAPAdjustment)";
		SettlementOperationReceiver = "VALUE(Enum.SettlementOperations.AdjustmentOfInvoice)";
		
	EndIf;
	
	#Region QueryText
	QueryText = "
		|SELECT
		|	PaymentDecryptionTableSupplier.RecorderDate       AS Period,
		|	CASE
		|		WHEN NOT &StornoSource AND &AccountsPayable
		|			OR &StornoSource AND NOT &AccountsPayable
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END                                                     AS RecordType,
		|	
		|	ISNULL(DimensionSource.DimensionKey, UNDEFINED)   AS AccountingDimensionByPartners,
		|	PaymentDecryptionTableSupplier.CalculationObjectSource AS ARAPObject,
		|	&CurrencyOfSettlementsSource                             AS Currency,
		|	
		|	&AmountOfSettlementsSource *
		|		CASE WHEN &StornoSource THEN -1 ELSE 1 END    AS Sum,
		|	0                                                         AS BeingPaid,
		|	&ForPaymentSource *
		|		CASE WHEN &StornoSource THEN -1 ELSE 1 END    AS AmountDue,
		|	0                                                         AS ToReceive,
		|	
		|	&BusinessOperation                                    AS BusinessOperation,
		|	&PaymentMethod                                              AS PaymentMethod,
		|	UNDEFINED                                              AS PaymentRequest,
		|	UNDEFINED                                              AS PurchaseByOrder,
		|	PaymentDecryptionTableSupplier.RecorderDate       AS RecorderDate,
		|	&PaymentDate                                              AS PaymentDate,
		|	
		|	CASE WHEN &CurrencyOfSettlementsSource = Coefficients.LocalAccountingCurrency
		|				THEN &AmountOfSettlementsSource
		|			WHEN PaymentDecryptionTableSupplier.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN PaymentDecryptionTableSupplier.Sum
		|			ELSE CAST(PaymentDecryptionTableSupplier.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END *
		|		CASE WHEN &StornoSource THEN -1 ELSE 1 END AS SumCompl,
		|	CASE WHEN &CurrencyOfSettlementsSource = &ManagementAccountingCurrency
		|				THEN &AmountOfSettlementsSource
		|			WHEN PaymentDecryptionTableSupplier.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN PaymentDecryptionTableSupplier.Sum
		|			ELSE CAST(PaymentDecryptionTableSupplier.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END *
		|		CASE WHEN &StornoSource THEN -1 ELSE 1 END AS SumMan,
		|
		|	0                                                         AS DepositForPackage,
		|	&CashFlowItem                            AS CashFlowItem,
		|	UNDEFINED                                              AS ARAPDocument,
		|	UNDEFINED                                              AS LinkedDocument,
		|	&PaymentOption                                            AS PaymentOption,
		|	PaymentDecryptionTableSupplier.DocumentCurrency        AS DocumentCurrency,
		|	UNDEFINED                                              AS CorARAPObject,
		|	UNDEFINED                                              AS CorPartnerAccountingDimension,
		|	
		|	&SettlementObjectSourceOrganization                        AS Organization,
		|	&SettlementObjectSourcePartner                            AS Partner,
		|	CalculationObjectsSources.Counterparty                       AS Counterparty,
		|	CalculationObjectsSources.Contract                          AS Contract,
		|	AreasOfActivitySource.DirectionOfAnalytics      AS LineOfBusiness,
		|
		|	UNDEFINED                                              AS CorPartner,
		|	UNDEFINED                                              AS CorCompany,
		|	UNDEFINED                                              AS CorCounterparty,
		|	UNDEFINED                                              AS CorContract,
		|	UNDEFINED                                              AS CorLineOfBusiness,
		|	PaymentDecryptionTableSupplier.RecorderNumber      AS RecorderNumber,
		|	&FinRecordID                                   AS FinRecordID,
		|	&TypeOfOperationForSorting                                 AS TypeOfOperationForSorting,
		|	&OrderOfOperationsWithinDocumentSource                AS OrderOfOperationsWithinDocument,
		|	&SettlementOperationSource                           AS SettlementTransaction,
		|	&BusinessTransactionSetting                           AS BusinessTransactionSetting,
		|
		|	CASE WHEN &CurrencyOfSettlementsSource = Coefficients.LocalAccountingCurrency
		|		OR PaymentDecryptionTableSupplier.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                 AS RateARAPCurrencyNumerator,
		|	CASE WHEN &CurrencyOfSettlementsSource = Coefficients.LocalAccountingCurrency
		|		OR PaymentDecryptionTableSupplier.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                 AS RateARAPCurrencyDenominator,
		|	CASE WHEN &CurrencyOfSettlementsSource = &ManagementAccountingCurrency
		|		OR PaymentDecryptionTableSupplier.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                 AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN &CurrencyOfSettlementsSource = &ManagementAccountingCurrency
		|		OR PaymentDecryptionTableSupplier.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                 AS ExchangeRateDenominatorCurrencyMan,
		|
		|	CASE WHEN &FillingReceiverInSource
		|		THEN ISNULL(DimensionReceiver.DimensionKey, UNDEFINED)
		|		ELSE UNDEFINED
		|	END                                                     AS DestinationAccountingDimensionByPartners,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsReceivers.Ref
		|		ELSE UNDEFINED
		|	END                                                     AS CalculationObjectReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &CurrencyOfMutualSettlementsReceiver
		|		ELSE UNDEFINED
		|	END                                                     AS CurrencyReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &SettlementObjectReceiverPartner
		|		ELSE UNDEFINED
		|	END                                                     AS PartnerReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &SettlementObjectReceiverOrganization
		|		ELSE UNDEFINED
		|	END                                                     AS CompanyDestination,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsReceivers.Counterparty
		|		ELSE UNDEFINED
		|	END                                                     AS CounterpartyReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsReceivers.Contract
		|		ELSE UNDEFINED
		|	END                                                     AS ContractDestination,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN AreasOfActivityReceiver.DirectionOfAnalytics
		|		ELSE UNDEFINED
		|	END                                                     AS FieldOfActivityReceiver,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &AmountOfMutualSettlementsReceiver
		|		ELSE UNDEFINED
		|	END                                                     AS AmountReceiver,
		|	FALSE                                                      AS ByDataOfSourceARAPObject
		|FROM
		|	#PaymentDecryptionTableSupplier AS PaymentDecryptionTableSupplier
		|		INNER JOIN Catalog.ARAPObjects AS CalculationObjectsSources
		|			ON PaymentDecryptionTableSupplier.CalculationObjectSource = CalculationObjectsSources.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = CalculationObjectsSources.Contract
		|		INNER JOIN Catalog.ARAPObjects AS CalculationObjectsReceivers
		|			ON PaymentDecryptionTableSupplier.CalculationObjectReceiver = CalculationObjectsReceivers.Ref
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
		|			ON Coefficients.Ref = PaymentDecryptionTableSupplier.Ref
		|				AND Coefficients.ARAPObject = PaymentDecryptionTableSupplier.CalculationObjectSource
		|				AND Coefficients.ARAPCurrency = &CurrencyOfSettlementsSource
		|				AND Coefficients.DateOfCourse = PaymentDecryptionTableSupplier.DateOfCourse
		|WHERE
		|	&AmountOfSettlementsSource > 0
		|	AND &OperationCondition
		|
		|UNION ALL
		|
		|SELECT
		|	PaymentDecryptionTableSupplier.RecorderDate              AS Period,
		|	CASE
		|		WHEN NOT &StornoReceiver AND &AccountsPayable
		|			OR &StornoReceiver AND NOT &AccountsPayable
		|			THEN VALUE(AccumulationRecordType.Expense)
		|		ELSE VALUE(AccumulationRecordType.Receipt)
		|	END                                                            AS RecordType,
		|	
		|	ISNULL(DimensionReceiver.DimensionKey, UNDEFINED)          AS AccountingDimensionByPartners,
		|	PaymentDecryptionTableSupplier.CalculationObjectReceiver        AS ARAPObject,
		|	&CurrencyOfMutualSettlementsReceiver                                    AS Currency,
		|	
		|	&AmountOfMutualSettlementsReceiver *
		|		CASE WHEN &StornoReceiver THEN -1 ELSE 1 END           AS Sum,
		|	0                                                                AS BeingPaid,
		|	&ReceiverForPayment *
		|		CASE WHEN &StornoReceiver THEN -1 ELSE 1 END           AS AmountDue,
		|	0                                                                AS ToReceive,
		|	
		|	&BusinessOperation                                           AS BusinessOperation,
		|	&PaymentMethod                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	UNDEFINED                                                     AS PurchaseByOrder,
		|	PaymentDecryptionTableSupplier.RecorderDate              AS RecorderDate,
		|	&PaymentDate                                                     AS PaymentDate,
		|	
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = Coefficients.LocalAccountingCurrency
		|				THEN &AmountOfMutualSettlementsReceiver
		|			WHEN PaymentDecryptionTableSupplier.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN PaymentDecryptionTableSupplier.Sum
		|			ELSE CAST(PaymentDecryptionTableSupplier.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END*
		|		CASE WHEN &StornoReceiver THEN -1 ELSE 1 END           AS SumCompl,
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = &ManagementAccountingCurrency
		|				THEN &AmountOfMutualSettlementsReceiver
		|			WHEN PaymentDecryptionTableSupplier.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN PaymentDecryptionTableSupplier.Sum
		|			ELSE CAST(PaymentDecryptionTableSupplier.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END*
		|		CASE WHEN &StornoReceiver THEN -1 ELSE 1 END           AS SumMan,
		|
		|	0                                                                AS DepositForPackage,
		|	&CashFlowItem                                   AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	&PaymentOption                                                   AS PaymentOption,
		|	PaymentDecryptionTableSupplier.DocumentCurrency               AS DocumentCurrency,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsSources.Ref
		|		ELSE UNDEFINED
		|	END                                                            AS CorARAPObject,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN ISNULL(DimensionSource.DimensionKey, UNDEFINED)
		|		ELSE UNDEFINED
		|	END                                                            AS CorPartnerAccountingDimension,
		|	
		|	&SettlementObjectReceiverOrganization                               AS Organization,
		|	&SettlementObjectReceiverPartner                                   AS Partner,
		|	CalculationObjectsReceivers.Counterparty                              AS Counterparty,
		|	CalculationObjectsReceivers.Contract                                 AS Contract,
		|	AreasOfActivityReceiver.DirectionOfAnalytics             AS LineOfBusiness,
		|
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &SettlementObjectSourcePartner
		|		ELSE UNDEFINED
		|	END                                                            AS CorPartner,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN &SettlementObjectSourceOrganization
		|		ELSE UNDEFINED
		|	END                                                            AS CorCompany,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsSources.Counterparty
		|		ELSE UNDEFINED
		|	END                                                            AS CorCounterparty,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN CalculationObjectsSources.Contract
		|		ELSE UNDEFINED
		|	END                                                            AS CorContract,
		|	CASE WHEN &FillingReceiverInSource
		|		THEN AreasOfActivitySource.DirectionOfAnalytics
		|		ELSE UNDEFINED
		|	END                                                            AS CorLineOfBusiness,
		|
		|	PaymentDecryptionTableSupplier.RecorderNumber             AS RecorderNumber,
		|	&FinRecordID                                          AS FinRecordID,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	&OrderOfOperationsWithinDocumentReceiver                       AS OrderOfOperationsWithinDocument,
		|	&SettlementOperationReceiver                                  AS SettlementTransaction,
		|	&BusinessTransactionSetting                                  AS BusinessTransactionSetting,
		|
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = Coefficients.LocalAccountingCurrency
		|		OR PaymentDecryptionTableSupplier.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                            AS RateARAPCurrencyNumerator,
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = Coefficients.LocalAccountingCurrency
		|		OR PaymentDecryptionTableSupplier.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                            AS RateARAPCurrencyDenominator,
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = &ManagementAccountingCurrency
		|		OR PaymentDecryptionTableSupplier.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                            AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN &CurrencyOfMutualSettlementsReceiver = &ManagementAccountingCurrency
		|		OR PaymentDecryptionTableSupplier.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                            AS ExchangeRateDenominatorCurrencyMan,
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
		|	&FillingReceiverInSource                                     AS ByDataOfSourceARAPObject
		|FROM
		|	#PaymentDecryptionTableSupplier AS PaymentDecryptionTableSupplier
		|		INNER JOIN Catalog.ARAPObjects AS CalculationObjectsSources
		|			ON PaymentDecryptionTableSupplier.CalculationObjectSource = CalculationObjectsSources.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractDataSource
		|			ON ContractDataSource.Ref = CalculationObjectsSources.Contract
		|		INNER JOIN Catalog.ARAPObjects AS CalculationObjectsReceivers
		|			ON PaymentDecryptionTableSupplier.CalculationObjectReceiver = CalculationObjectsReceivers.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = CalculationObjectsReceivers.Contract
		|		INNER JOIN TTLinesOfBusiness AS AreasOfActivitySource
		|			ON PaymentDecryptionTableSupplier.CalculationObjectSource = AreasOfActivitySource.ARAPObject
		|		INNER JOIN TTLinesOfBusiness AS AreasOfActivityReceiver
		|			ON PaymentDecryptionTableSupplier.CalculationObjectReceiver = AreasOfActivityReceiver.ARAPObject
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
		|			ON Coefficients.Ref = PaymentDecryptionTableSupplier.Ref
		|				AND Coefficients.ARAPObject = PaymentDecryptionTableSupplier.CalculationObjectReceiver
		|				AND Coefficients.ARAPCurrency = &CurrencyOfMutualSettlementsReceiver
		|				AND Coefficients.DateOfCourse = PaymentDecryptionTableSupplier.DateOfCourse
		|WHERE
		|	&AmountOfMutualSettlementsReceiver > 0
		|	AND &OperationCondition
		|";
	#EndRegion
	
	QueryText = StrReplace(QueryText,"&OperationCondition",OperationCondition);
	
	QueryText = StrReplace(QueryText,"&AccountsPayable",       AccountsPayable);
	QueryText = StrReplace(QueryText,"&StornoSource",                  StornoSource);
	QueryText = StrReplace(QueryText,"&StornoReceiver",                  StornoReceiver);
	
	QueryText = StrReplace(QueryText,"&ForPaymentSource",                 ForPaymentSource);
	
	QueryText = StrReplace(QueryText,"&BusinessOperation",           BusinessOperation);
	QueryText = StrReplace(QueryText,"&PaymentMethod",                     PaymentMethod);
	
	QueryText = StrReplace(QueryText,"&ReceiverForPayment",                 ReceiverForPayment);
	
	QueryText = StrReplace(QueryText,"&SettlementObjectSourceOrganization", SettlementObjectSourceOrganization);
	QueryText = StrReplace(QueryText,"&SettlementObjectReceiverOrganization", SettlementObjectReceiverOrganization);
	
	QueryText = StrReplace(QueryText,"&SettlementObjectSourcePartner",   SettlementObjectSourcePartner);
	QueryText = StrReplace(QueryText,"&SettlementObjectReceiverPartner",   SettlementObjectReceiverPartner);
	
	QueryText = StrReplace(QueryText,"&CurrencyOfSettlementsSource",    CurrencyOfSettlementsSource);
	QueryText = StrReplace(QueryText,"&CurrencyOfMutualSettlementsReceiver",    CurrencyOfMutualSettlementsReceiver);
	QueryText = StrReplace(QueryText,"&AmountOfSettlementsSource",     AmountOfSettlementsSource);
	QueryText = StrReplace(QueryText,"&AmountOfMutualSettlementsReceiver",     AmountOfMutualSettlementsReceiver);
	
	QueryText = StrReplace(QueryText,"&PaymentDate",                     PaymentDate);
	QueryText = StrReplace(QueryText,"&PaymentOption",                   PaymentOption);
	QueryText = StrReplace(QueryText,"&CashFlowItem",   CashFlowItem);
	
	QueryText = StrReplace(QueryText,"&FillingReceiverInSource",     FillingReceiverInSource);
	
	QueryText = StrReplace(QueryText,"&FinRecordID",          FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting",  BusinessTransactionSetting);
	
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",  TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&OrderOfOperationsWithinDocumentSource", OrderOfOperationsWithinDocument);
	QueryText = StrReplace(QueryText,"&OrderOfOperationsWithinDocumentReceiver", String(Number(OrderOfOperationsWithinDocument)+1));
	QueryText = StrReplace(QueryText,"&SettlementOperationSource",  SettlementOperationSource);
	QueryText = StrReplace(QueryText,"&SettlementOperationReceiver",  SettlementOperationReceiver);
	
	If Operation = "ReschedulingPurchase" Or Operation = "TransferOfPaymentUnderCentralizedContract" Or Operation = "PostponementOfReturnOfGoodsUnderCentralizedContract" Then
		QueryText = StrReplace(QueryText,"#PaymentDecryptionTable",  "TTTransferOfPayments");
		QueryText = StrReplace(QueryText,"PaymentDecryptionTable",  "TransferOfCalculations");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextTransferOfSupplierDebtBetweenBranches(TypeOfOperationForSorting)
	
	QueryText = "
		|SELECT
		|	IncreasingOurSupplierDebt.RecorderDate          AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
		|	
		|	ISNULL(DimensionSource.DimensionKey, UNDEFINED)          AS AccountingDimensionByPartners,
		|	IncreasingOurSupplierDebt.ARAPObject            AS ARAPObject,
		|	IncreasingOurSupplierDebt.ARAPCurrency      AS Currency,
		|	
		|	IncreasingOurSupplierDebt.AmountARAP       AS Sum,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS AmountDue,
		|	0                                                                AS ToReceive,
		|	
		|	VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices) AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	IncreasingOurSupplierDebt.PurchaseOrder_              AS PurchaseByOrder,
		|	IncreasingOurSupplierDebt.RecorderDate          AS RecorderDate,
		|	IncreasingOurSupplierDebt.PaymentDate               AS PaymentDate,
		|	
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.AmountARAP
		|			WHEN IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.Sum
		|			ELSE CAST(IncreasingOurSupplierDebt.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END AS SumCompl,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.AmountARAP
		|			WHEN IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.Sum
		|			ELSE CAST(IncreasingOurSupplierDebt.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END AS SumMan,
		|
		|	0                                                       AS DepositForPackage,
		|	UNDEFINED                                            AS CashFlowItem,
		|	UNDEFINED                                            AS ARAPDocument,
		|	UNDEFINED                                            AS LinkedDocument,
		|	IncreasingOurSupplierDebt.PaymentOption    AS PaymentOption,
		|	IncreasingOurSupplierDebt.DocumentCurrency  AS DocumentCurrency,
		|	UNDEFINED                                            AS CorARAPObject,
		|	UNDEFINED                                            AS CorPartnerAccountingDimension,
		|	
		|	IncreasingOurSupplierDebt.Organization      AS Organization,
		|	IncreasingOurSupplierDebt.Partner          AS Partner,
		|	DataCenterARAPObject.Counterparty                             AS Counterparty,
		|	DataCenterARAPObject.Contract                                AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics            AS LineOfBusiness,
		|
		|	UNDEFINED                                            AS CorPartner,
		|	UNDEFINED                                            AS CorCompany,
		|	UNDEFINED                                            AS CorCounterparty,
		|	UNDEFINED                                            AS CorContract,
		|	UNDEFINED                                            AS CorLineOfBusiness,
		|	IncreasingOurSupplierDebt.RecorderNumber AS RecorderNumber,
		|	DataCenterARAPObject.UUID                AS FinRecordID,
		|	&TypeOfOperationForSorting                               AS TypeOfOperationForSorting,
		|	5                                                       AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.TransferOfSettlements) AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.DebtTransferBetweenBranchOffices) AS BusinessTransactionSetting,
		|
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                            AS RateARAPCurrencyNumerator,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                            AS RateARAPCurrencyDenominator,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                            AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                            AS ExchangeRateDenominatorCurrencyMan,
		|
		|	ISNULL(DimensionReceiver.DimensionKey, UNDEFINED) AS DestinationAccountingDimensionByPartners,
		|	DataCenterARAPObject.Ref                                 AS CalculationObjectReceiver,
		|	DataCenterARAPObject.ARAPCurrency                   AS CurrencyReceiver,
		|	IncreasingOurSupplierDebt.Partner          AS PartnerReceiver,
		|	DataCenterARAPObject.Organization                            AS CompanyDestination,
		|	DataCenterARAPObject.Counterparty                             AS CounterpartyReceiver,
		|	DataCenterARAPObject.Contract                                AS ContractDestination,
		|	LinesOfBusiness.DirectionOfAnalytics            AS FieldOfActivityReceiver,
		|	IncreasingOurSupplierDebt.AmountARAP AS AmountReceiver,
		|	FALSE                                                    AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreasingOurSupplierDebt AS IncreasingOurSupplierDebt
		|		INNER JOIN Catalog.ARAPObjects AS DataCenterARAPObject
		|			ON IncreasingOurSupplierDebt.ARAPObject = DataCenterARAPObject.Ref
		|		INNER JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = DataCenterARAPObject.Contract
		|				AND ContractData.CentralizedContract
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON DataCenterARAPObject.Ref = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionReceiver
		|			ON DataCenterARAPObject.Organization = DimensionReceiver.Organization
		|				AND DataCenterARAPObject.Counterparty = DimensionReceiver.Counterparty
		|				AND IncreasingOurSupplierDebt.Partner = DimensionReceiver.Partner
		|				AND DataCenterARAPObject.Contract = DimensionReceiver.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = DimensionReceiver.LineOfBusiness
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionSource
		|			ON IncreasingOurSupplierDebt.Organization = DimensionSource.Organization
		|				AND DataCenterARAPObject.Counterparty = DimensionSource.Counterparty
		|				AND IncreasingOurSupplierDebt.Partner = DimensionSource.Partner
		|				AND DataCenterARAPObject.Contract = DimensionSource.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = DimensionSource.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = IncreasingOurSupplierDebt.Ref
		|				AND Coefficients.ARAPObject = IncreasingOurSupplierDebt.ARAPObject
		|				AND Coefficients.ARAPCurrency = IncreasingOurSupplierDebt.ARAPCurrency
		|				AND Coefficients.DateOfCourse = IncreasingOurSupplierDebt.DateOfCourse
		|WHERE
		|	IncreasingOurSupplierDebt.AmountARAP > 0
		|	AND IncreasingOurSupplierDebt.Organization <> DataCenterARAPObject.Organization
		|
		|UNION ALL
		|
		|SELECT
		|	IncreasingOurSupplierDebt.RecorderDate          AS Period,
		|	VALUE(AccumulationRecordType.Expense)                           AS RecordType,
		|	
		|	ISNULL(DimensionReceiver.DimensionKey, UNDEFINED)          AS AccountingDimensionByPartners,
		|	IncreasingOurSupplierDebt.ARAPObject            AS ARAPObject,
		|	IncreasingOurSupplierDebt.ARAPCurrency      AS Currency,
		|	
		|	IncreasingOurSupplierDebt.AmountARAP       AS Sum,
		|	0                                                                AS BeingPaid,
		|	0                                                                AS AmountDue,
		
		|	0                                                                AS ToReceive,
		|	
		|	VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices) AS BusinessOperation,
		|	UNDEFINED                                                     AS PaymentMethod,
		|	UNDEFINED                                                     AS PaymentRequest,
		|	IncreasingOurSupplierDebt.PurchaseOrder_              AS PurchaseByOrder,
		|	IncreasingOurSupplierDebt.RecorderDate          AS RecorderDate,
		|	IncreasingOurSupplierDebt.PaymentDate               AS PaymentDate,
		|	
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.AmountARAP
		|			WHEN IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.Sum
		|			ELSE CAST(IncreasingOurSupplierDebt.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END AS SumCompl,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.AmountARAP
		|			WHEN IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.Sum
		|			ELSE CAST(IncreasingOurSupplierDebt.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END AS SumMan,
		|
		|	0                                                                AS DepositForPackage,
		|	UNDEFINED                                                     AS CashFlowItem,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	IncreasingOurSupplierDebt.PaymentOption             AS PaymentOption,
		|	IncreasingOurSupplierDebt.DocumentCurrency           AS DocumentCurrency,
		|	DataCenterARAPObject.Ref                                          AS CorARAPObject,
		|	ISNULL(DimensionSource.DimensionKey, UNDEFINED)          AS CorPartnerAccountingDimension,
		|	
		|	DataCenterARAPObject.Organization                                     AS Organization,
		|	IncreasingOurSupplierDebt.Partner                   AS Partner,
		|	DataCenterARAPObject.Counterparty                                      AS Counterparty,
		|	DataCenterARAPObject.Contract                                         AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS LineOfBusiness,
		|
		|	IncreasingOurSupplierDebt.Partner                   AS CorPartner,
		|	IncreasingOurSupplierDebt.Organization               AS CorCompany,
		|	DataCenterARAPObject.Counterparty                                      AS CorCounterparty,
		|	DataCenterARAPObject.Contract                                         AS CorContract,
		|	LinesOfBusiness.DirectionOfAnalytics                     AS CorLineOfBusiness,
		|
		|	IncreasingOurSupplierDebt.RecorderNumber         AS RecorderNumber,
		|	DataCenterARAPObject.UUID                         AS FinRecordID,
		|	&TypeOfOperationForSorting                                        AS TypeOfOperationForSorting,
		|	5                                                                AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.TransferOfSettlements) AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.DebtTransferBetweenBranchOffices) AS BusinessTransactionSetting,
		|
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                            AS RateARAPCurrencyNumerator,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                            AS RateARAPCurrencyDenominator,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                            AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                            AS ExchangeRateDenominatorCurrencyMan,
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
		|	TRUE                                                           AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreasingOurSupplierDebt AS IncreasingOurSupplierDebt
		|		INNER JOIN Catalog.ARAPObjects AS DataCenterARAPObject
		|			ON IncreasingOurSupplierDebt.ARAPObject = DataCenterARAPObject.Ref
		|		INNER JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = DataCenterARAPObject.Contract
		|				AND ContractData.CentralizedContract
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON DataCenterARAPObject.Ref = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionReceiver
		|			ON DataCenterARAPObject.Organization = DimensionReceiver.Organization
		|				AND DataCenterARAPObject.Counterparty = DimensionReceiver.Counterparty
		|				AND IncreasingOurSupplierDebt.Partner = DimensionReceiver.Partner
		|				AND DataCenterARAPObject.Contract = DimensionReceiver.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = DimensionReceiver.LineOfBusiness
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionSource
		|			ON IncreasingOurSupplierDebt.Organization = DimensionSource.Organization
		|				AND DataCenterARAPObject.Counterparty = DimensionSource.Counterparty
		|				AND IncreasingOurSupplierDebt.Partner = DimensionSource.Partner
		|				AND DataCenterARAPObject.Contract = DimensionSource.Contract
		|				AND LinesOfBusiness.DirectionOfAnalytics = DimensionSource.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = IncreasingOurSupplierDebt.Ref
		|				AND Coefficients.ARAPObject = IncreasingOurSupplierDebt.ARAPObject
		|				AND Coefficients.ARAPCurrency = IncreasingOurSupplierDebt.ARAPCurrency
		|				AND Coefficients.DateOfCourse = IncreasingOurSupplierDebt.DateOfCourse
		|WHERE
		|	IncreasingOurSupplierDebt.AmountARAP > 0
		|	AND IncreasingOurSupplierDebt.Organization <> DataCenterARAPObject.Organization
		|";
	
	QueryText = StrReplace(QueryText, "&TypeOfOperationForSorting", TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function IncreasePaymentPlanToSupplier(Operation, TypeOfOperationForSorting)
	
	If Operation = "ExecutionScheduleSupplier" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "FALSE";
		Period = "ENDOFPERIOD(IncreasingPaymentPlanToSupplier.PaymentDate, DAY)";
		
		ARAPObjectSettings = "VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)";
		InvoiceForOrders = "FALSE";
		PurchaseOrder_ = "Undefined";
		ExceedingOrder = "FALSE";
		AmountDue = "IncreasingPaymentPlanToSupplier.AmountDue";
		
		LinkedDocument = "Undefined";
		PaymentMethod = "Undefined";
		CashFlowItem = "Undefined";
		PaymentDate = "ENDOFPERIOD(IncreasingPaymentPlanToSupplier.PaymentDate, DAY)";
		PaymentOption = "IncreasingPaymentPlanToSupplier.PaymentOption";
		FinRecordID = "&IDOfUnusedFinRecord";
		BusinessTransactionSetting = "Undefined";
		
	ElsIf Operation = "PurchaseOrder" Then
		
		ThisIsOrder = "TRUE";
		ThisIsAnInvoice = "FALSE";
		Period = "ENDOFPERIOD(IncreasingPaymentPlanToSupplier.PaymentDate, DAY)";
				
		ARAPObjectSettings = "IncreasingPaymentPlanToSupplier.ARAPObjectSettings";
		InvoiceForOrders = "FALSE";
		PurchaseOrder_ = "Undefined";
		ExceedingOrder = "FALSE";
		
		AmountDue = "IncreasingPaymentPlanToSupplier.AmountDue";
		
		LinkedDocument = "Undefined";
		PaymentMethod = "IncreasingPaymentPlanToSupplier.PaymentMethod";
		CashFlowItem = "Undefined";
		PaymentDate = "ENDOFPERIOD(IncreasingPaymentPlanToSupplier.PaymentDate)";
		PaymentOption = "IncreasingPaymentPlanToSupplier.PaymentOption";
		FinRecordID = "&IDOfUnusedFinRecord";
		BusinessTransactionSetting = "Undefined";
		
	ElsIf Operation = "Purchase" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "TRUE";
		Period = "CASE WHEN IncreasingPaymentPlanToSupplier.AmountDue < 0 OR IncreasingPaymentPlanToSupplier.PaymentDate < IncreasingPaymentPlanToSupplier.RecorderDate
				|		THEN IncreasingPaymentPlanToSupplier.RecorderDate
				|	ELSE ENDOFPERIOD(IncreasingPaymentPlanToSupplier.PaymentDate, DAY)
				|END";
		ARAPObjectSettings = "IncreasingPaymentPlanToSupplier.ARAPObjectSettings";
		InvoiceForOrders = "IncreasingPaymentPlanToSupplier.InvoiceForOrders";
		PurchaseOrder_ = "IncreasingPaymentPlanToSupplier.PurchaseOrder_";
		ExceedingOrder = "IncreasingPaymentPlanToSupplier.ExceedingOrder";
		
		AmountDue = "IncreasingPaymentPlanToSupplier.AmountDue";
		
		LinkedDocument = "IncreasingPaymentPlanToSupplier.LinkedDocument";
		PaymentMethod = "IncreasingPaymentPlanToSupplier.PaymentMethod";
		CashFlowItem = "Undefined";

		PaymentDate = "CASE WHEN IncreasingPaymentPlanToSupplier.AmountDue < 0 
				|		THEN DATETIME(1,1,1)
				|	ELSE IncreasingPaymentPlanToSupplier.PaymentDate
				|END";
		PaymentOption = "IncreasingPaymentPlanToSupplier.PaymentOption";
		FinRecordID = "IncreasingPaymentPlanToSupplier.ARAPObject.UUID";
		BusinessTransactionSetting = "Undefined";
		
	ElsIf Operation = "RefundOfPaymentFromSupplier" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "FALSE";
		Period = "IncreasingPaymentPlanToSupplier.RecorderDate";
		
		ARAPObjectSettings = "Undefined";
		InvoiceForOrders = "FALSE";
		PurchaseOrder_ = "Undefined";
		ExceedingOrder = "FALSE";
		
		AmountDue = "IncreasingPaymentPlanToSupplier.AmountARAP";
		
		LinkedDocument = "Undefined";
		PaymentMethod = "IncreasingPaymentPlanToSupplier.PaymentMethod";
		CashFlowItem = "IncreasingPaymentPlanToSupplier.CashFlowItem";
		PaymentDate = "DATETIME(1,1,1)";
		PaymentOption = "Undefined";
		FinRecordID = "IncreasingPaymentPlanToSupplier.FinRecordID";
		BusinessTransactionSetting = "IncreasingPaymentPlanToSupplier.BusinessTransactionSetting";
		
	EndIf;
	
	QueryText = 
		"SELECT
		|	&Period                                                             AS Period,
		|	VALUE(AccumulationRecordType.Expense)                              AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                     AS AccountingDimensionByPartners,
		|	IncreasingPaymentPlanToSupplier.ARAPObject                      AS ARAPObject,
		|	IncreasingPaymentPlanToSupplier.ARAPCurrency                AS Currency,
		|	
		|	0                                                                   AS Sum,
		|	0                                                                   AS BeingPaid,
		|	&AmountDue                                                            AS AmountDue,
		|	0                                                                   AS ToReceive,
		|	
		|	IncreasingPaymentPlanToSupplier.BusinessOperation               AS BusinessOperation,
		|	&PaymentMethod                                                        AS PaymentMethod,
		|	UNDEFINED                                                        AS PaymentRequest,
		|	&PurchaseOrder_                                                       AS PurchaseByOrder,
		|	IncreasingPaymentPlanToSupplier.RecorderDate                    AS RecorderDate,
		|	&PaymentDate                                                        AS PaymentDate,
		|	0                                                                   AS SumCompl,
		|	0                                                                   AS SumMan,
		|	0                                                                   AS DepositForPackage,
		|	&CashFlowItem                                      AS CashFlowItem,
		|	UNDEFINED                                                        AS ARAPDocument,
		|	//Payment procedure
		|	//The order of offsetting by payment date
		|	&LinkedDocument                                                  AS LinkedDocument,
		|	
		|	&PaymentOption                                                      AS PaymentOption,
		|	IncreasingPaymentPlanToSupplier.DocumentCurrency                     AS DocumentCurrency,
		|	UNDEFINED                                                        AS CorARAPObject,
		|	UNDEFINED                                                        AS CorPartnerAccountingDimension,
		|	
		|	IncreasingPaymentPlanToSupplier.ARAPObject.Organization          AS Organization,
		|	IncreasingPaymentPlanToSupplier.Partner                             AS Partner,
		|	IncreasingPaymentPlanToSupplier.ARAPObject.Counterparty           AS Counterparty,
		|	IncreasingPaymentPlanToSupplier.ARAPObject.Contract              AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                        AS LineOfBusiness,
		|	
		|	UNDEFINED                                                        AS CorPartner,
		|	UNDEFINED                                                        AS CorCompany,
		|	UNDEFINED                                                        AS CorCounterparty,
		|	UNDEFINED                                                        AS CorContract,
		|	UNDEFINED                                                        AS CorLineOfBusiness,
		|	IncreasingPaymentPlanToSupplier.RecorderNumber                   AS RecorderNumber,
		|	&FinRecordID                                             AS FinRecordID,
		|	&TypeOfOperationForSorting                                           AS TypeOfOperationForSorting,
		|	1                                                       AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)          AS SettlementTransaction,
		|	&BusinessTransactionSetting                                     AS BusinessTransactionSetting,
		|
		|	0                                                                   AS RateARAPCurrencyNumerator,
		|	0                                                                   AS RateARAPCurrencyDenominator,
		|	0                                                                   AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                   AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                        AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                        AS CalculationObjectReceiver,
		|	UNDEFINED                                                        AS CurrencyReceiver,
		|	UNDEFINED                                                        AS PartnerReceiver,
		|	UNDEFINED                                                        AS CompanyDestination,
		|	UNDEFINED                                                        AS CounterpartyReceiver,
		|	UNDEFINED                                                        AS ContractDestination,
		|	UNDEFINED                                                        AS FieldOfActivityReceiver,
		|	0                                                                   AS AmountReceiver,
		|	FALSE                                                                AS ByDataOfSourceARAPObject
		|	
		|FROM
		|	#IncreasingPaymentPlanToSupplier AS IncreasingPaymentPlanToSupplier
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreasingPaymentPlanToSupplier.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = IncreasingPaymentPlanToSupplier.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|				ON IncreasingPaymentPlanToSupplier.ARAPObject.Organization = Dimension.Organization
		|					AND IncreasingPaymentPlanToSupplier.ARAPObject.Counterparty = Dimension.Counterparty
		|					AND IncreasingPaymentPlanToSupplier.Partner = Dimension.Partner
		|					AND IncreasingPaymentPlanToSupplier.ARAPObject.Contract = Dimension.Contract
		|					AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	&AmountDue <> 0
		|	//When making payments under a contract with a schedule, the payment plan does not increase
		|	AND NOT (&ThisIsOrder
		|			AND ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)
		|			AND ISNULL(ContractData.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) 
		|				IN (VALUE(Enum.ContractTypes.WithVendor),
		|					VALUE(Enum.ContractTypes.WithConsignor),
		|					VALUE(Enum.ContractTypes.Import),
		|					VALUE(Enum.ContractTypes.TransferToTolling),
		|					VALUE(Enum.ContractTypes.TransferToTolling2_5))
		|			AND &ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		|	//An order with calculations not based on invoices
		|	AND (&ThisIsOrder AND &ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|		//Over the order or not under the order
		|		OR &ThisIsAnInvoice
		|		//Contract execution schedule, refund of payment
		|		OR NOT (&ThisIsAnInvoice OR &ThisIsOrder)
		|		)
		|";
	
	QueryText = StrReplace(QueryText,"&ARAPObjectSettings",               ARAPObjectSettings);
	QueryText = StrReplace(QueryText,"&PaymentMethod",                   PaymentMethod);
	QueryText = StrReplace(QueryText,"&ThisIsOrder",                      ThisIsOrder);
	QueryText = StrReplace(QueryText,"&ThisIsAnInvoice",                  ThisIsAnInvoice);
	QueryText = StrReplace(QueryText,"&InvoiceForOrders",            InvoiceForOrders);
	QueryText = StrReplace(QueryText,"&PurchaseOrder_",                  PurchaseOrder_);
	QueryText = StrReplace(QueryText,"&ExceedingOrder",                   ExceedingOrder);
	QueryText = StrReplace(QueryText,"&Period",                        Period);
	QueryText = StrReplace(QueryText,"&AmountDue",                       AmountDue);
	QueryText = StrReplace(QueryText,"&CashFlowItem", CashFlowItem);
	QueryText = StrReplace(QueryText,"&PaymentDate",                   PaymentDate);
	QueryText = StrReplace(QueryText,"&PaymentOption",                 PaymentOption);
	QueryText = StrReplace(QueryText,"&LinkedDocument",             LinkedDocument);
	QueryText = StrReplace(QueryText,"&FinRecordID",        FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting", BusinessTransactionSetting);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",       TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function ReducePaymentPlanToSupplier(Operation, TypeOfOperationForSorting, OrderOfOperationsWithinDocument = "1", InvoiceForOrders = False)
	
	If Operation = "PaymentToVendor" Or Operation = "OffsettingSupplierSObligations" Then
		
		AmountDue = "ReducingPaymentPlanToSupplier.AmountARAP";
		PaymentMethod = "ReducingPaymentPlanToSupplier.PaymentMethod";
		PaymentRequest = "ReducingPaymentPlanToSupplier.PaymentRequest";
		CashFlowItem = "ReducingPaymentPlanToSupplier.CashFlowItem";
		LinkedDocument = "ReducingPaymentPlanToSupplier.LinkedDocument";
		FinRecordID = "ReducingPaymentPlanToSupplier.FinRecordID";
		BusinessTransactionSetting = "ReducingPaymentPlanToSupplier.BusinessTransactionSetting";
		PurchaseOrder_ = "Undefined";
		ARAPObject = "ReducingPaymentPlanToSupplier.ARAPObject";
		OperationCondition = "TRUE";
		Organization = "ReducingPaymentPlanToSupplier.Organization";
		PaymentOption = "Undefined";
		
	ElsIf Operation = "Purchase" Then
		
		AmountDue = "ReducingPaymentPlanToSupplier.AmountDue";
		PaymentMethod = "Undefined";
		PaymentRequest = "Undefined";
		CashFlowItem = "Undefined";
		LinkedDocument = "Undefined";
		If InvoiceForOrders Then
			PaymentOption = "ReducingPaymentPlanToSupplier.PaymentOption";
			FinRecordID = "CASE 
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|			THEN ReducingPaymentPlanToSupplier.PurchaseOrder_.ARAPObject.UUID
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ISNULL(ContractData.ARAPObject.UUID, """")
			|		ELSE ReducingPaymentPlanToSupplier.ARAPObject.UUID
			|	END";
			BusinessTransactionSetting = "Undefined";
			PurchaseOrder_ = "ReducingPaymentPlanToSupplier.PurchaseOrder_";
			ARAPObject = "CASE 
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|			THEN ReducingPaymentPlanToSupplier.PurchaseOrder_.ARAPObject
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ISNULL(ContractData.ARAPObject, UNDEFINED)
			|		ELSE ReducingPaymentPlanToSupplier.ARAPObject
			|	END";
			OperationCondition = "	(ReducingPaymentPlanToSupplier.InvoiceForOrders AND NOT ReducingPaymentPlanToSupplier.ExceedingOrder 
			|		OR ISNULL(ContractData.ExecutionScheduleIsSpecified,FALSE))
			|		AND ReducingPaymentPlanToSupplier.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)";
			Organization = "CASE 
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|			THEN ReducingPaymentPlanToSupplier.PurchaseOrder_.Organization
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ISNULL(ContractData.Organization, UNDEFINED)
			|		ELSE ReducingPaymentPlanToSupplier.ARAPObject.Organization
			|	END";
		Else
			PaymentOption = "Undefined";
			FinRecordID = "CASE 
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ISNULL(ContractData.ARAPObject.UUID, """")
			|		ELSE ReducingPaymentPlanToSupplier.ARAPObject.UUID
			|	END";
			BusinessTransactionSetting = "Undefined";
			PurchaseOrder_ = "Undefined";
			ARAPObject = "CASE 
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ISNULL(ContractData.ARAPObject, UNDEFINED)
			|		ELSE ReducingPaymentPlanToSupplier.ARAPObject
			|	END";
			OperationCondition = "ISNULL(ContractData.ExecutionScheduleIsSpecified,FALSE)
			|		AND ReducingPaymentPlanToSupplier.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
			|		AND ReducingPaymentPlanToSupplier.BusinessOperation <> VALUE(Enum.BusinessTransactions.ARAPAdjustment)";
			Organization = "CASE 
			|		WHEN ReducingPaymentPlanToSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|			THEN ISNULL(ContractData.Organization, UNDEFINED)
			|		ELSE ReducingPaymentPlanToSupplier.ARAPObject.Organization
			|	END";
		EndIf;
		
	ElsIf Operation = "ReturnOfGoodsToVendor" Then
		
		AmountDue = "ReducingPaymentPlanToSupplier.AmountARAP";
		PaymentMethod = "Undefined";
		PaymentRequest = "Undefined";
		CashFlowItem = "Undefined";
		LinkedDocument = "Undefined";
		FinRecordID = "ReducingPaymentPlanToSupplier.FinRecordID";
		BusinessTransactionSetting = "ReducingPaymentPlanToSupplier.BusinessTransactionSetting";
		PurchaseOrder_ = "Undefined";
		ARAPObject = "ReducingPaymentPlanToSupplier.ARAPObject";
		OperationCondition = "TRUE";
		Organization = "ReducingPaymentPlanToSupplier.Organization";
		PaymentOption = "Undefined";
		
	EndIf;
	
	QueryText = 
		"SELECT
		|	ReducingPaymentPlanToSupplier.RecorderDate                    AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                              AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                     AS AccountingDimensionByPartners,
		|	&ARAPObject                                                     AS ARAPObject,
		|	ReducingPaymentPlanToSupplier.ARAPCurrency                AS Currency,
		|	
		|	0                                                                   AS Sum,
		|	0                                                                   AS BeingPaid,
		|	&AmountDue                                                            AS AmountDue,
		|	0                                                                   AS ToReceive,
		|	
		|	ReducingPaymentPlanToSupplier.BusinessOperation               AS BusinessOperation,
		|	&PaymentMethod                                                        AS PaymentMethod,
		|	&PaymentRequest                                AS PaymentRequest,
		|	&PurchaseOrder_                                                       AS PurchaseByOrder,
		|	ReducingPaymentPlanToSupplier.RecorderDate                    AS RecorderDate,
		|	CASE WHEN &AmountDue < 0
		|			THEN BEGINOFPERIOD(ReducingPaymentPlanToSupplier.RecorderDate, DAY)
		|		ELSE DATETIME(1,1,1)
		|	END                                                               AS PaymentDate,
		|	0                                                                   AS SumCompl,
		|	0                                                                   AS SumMan,
		|	0                                                                   AS DepositForPackage,
		|	&CashFlowItem                                      AS CashFlowItem,
		|	UNDEFINED                                                        AS ARAPDocument,
		|	//Payment procedure
		|	//The order of offsetting by payment date
		|	&LinkedDocument                                                  AS LinkedDocument,
		|	&PaymentOption                                                      AS PaymentOption,
		|	ReducingPaymentPlanToSupplier.DocumentCurrency                     AS DocumentCurrency,
		|	UNDEFINED                                                        AS CorARAPObject,
		|	UNDEFINED                                                        AS CorPartnerAccountingDimension,
		|	
		|	&Organization                                                        AS Organization,
		|	ReducingPaymentPlanToSupplier.Partner                             AS Partner,
		|	ReducingPaymentPlanToSupplier.ARAPObject.Counterparty           AS Counterparty,
		|	ReducingPaymentPlanToSupplier.ARAPObject.Contract              AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                        AS LineOfBusiness,
		|	
		|	UNDEFINED                                                        AS CorPartner,
		|	UNDEFINED                                                        AS CorCompany,
		|	UNDEFINED                                                        AS CorCounterparty,
		|	UNDEFINED                                                        AS CorContract,
		|	UNDEFINED                                                        AS CorLineOfBusiness,
		|	ReducingPaymentPlanToSupplier.RecorderNumber                   AS RecorderNumber,
		|	&FinRecordID                                             AS FinRecordID,
		|	&TypeOfOperationForSorting                                           AS TypeOfOperationForSorting,
		|	&OrderOfOperationsWithinDocument                                  AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)          AS SettlementTransaction,
		|	&BusinessTransactionSetting                                     AS BusinessTransactionSetting,
		|
		|	0                                                                   AS RateARAPCurrencyNumerator,
		|	0                                                                   AS RateARAPCurrencyDenominator,
		|	0                                                                   AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                   AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                        AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                        AS CalculationObjectReceiver,
		|	UNDEFINED                                                        AS CurrencyReceiver,
		|	UNDEFINED                                                        AS PartnerReceiver,
		|	UNDEFINED                                                        AS CompanyDestination,
		|	UNDEFINED                                                        AS CounterpartyReceiver,
		|	UNDEFINED                                                        AS ContractDestination,
		|	UNDEFINED                                                        AS FieldOfActivityReceiver,
		|	0                                                                   AS AmountReceiver,
		|	FALSE                                                                AS ByDataOfSourceARAPObject
		|FROM
		|	#ReducingPaymentPlanToSupplier AS ReducingPaymentPlanToSupplier
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ReducingPaymentPlanToSupplier.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref =  ReducingPaymentPlanToSupplier.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|				ON &Organization = Dimension.Organization
		|					AND ReducingPaymentPlanToSupplier.ARAPObject.Counterparty = Dimension.Counterparty
		|					AND ReducingPaymentPlanToSupplier.Partner = Dimension.Partner
		|					AND ReducingPaymentPlanToSupplier.ARAPObject.Contract = Dimension.Contract
		|					AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	&AmountDue <> 0 AND &OperationCondition
		|";
	
	QueryText = StrReplace(QueryText,"&AmountDue",                             AmountDue);
	QueryText = StrReplace(QueryText,"&PaymentMethod",                         PaymentMethod);
	QueryText = StrReplace(QueryText,"&PaymentRequest", PaymentRequest);
	QueryText = StrReplace(QueryText,"&CashFlowItem",       CashFlowItem);
	QueryText = StrReplace(QueryText,"&LinkedDocument",                   LinkedDocument);
	QueryText = StrReplace(QueryText,"&FinRecordID",              FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting",      BusinessTransactionSetting);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",            TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&OrderOfOperationsWithinDocument",   OrderOfOperationsWithinDocument);
	QueryText = StrReplace(QueryText,"&ARAPObject",                      ARAPObject);
	QueryText = StrReplace(QueryText,"&OperationCondition",                     OperationCondition);
	QueryText = StrReplace(QueryText,"&Organization",                         Organization);
	QueryText = StrReplace(QueryText,"&PurchaseOrder_",                        PurchaseOrder_);
	QueryText = StrReplace(QueryText,"&PaymentOption",                       PaymentOption);
	
	Return QueryText;
	
EndFunction

Function IncreaseDeliveryPlanFromSupplier(Operation, TypeOfOperationForSorting)
	
	If Operation = "ExecutionScheduleSupplier" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "FALSE";
		ARAPObjectSettings = "VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)";
		
	ElsIf Operation = "PurchaseOrder" Then
		
		ThisIsOrder = "TRUE";
		ThisIsAnInvoice = "FALSE";
		ARAPObjectSettings = "IncreasingDeliveryPlan.ARAPObjectSettings";
		
	ElsIf Operation = "Purchase" Then
		
		ThisIsOrder = "FALSE";
		ThisIsAnInvoice = "TRUE";
		ARAPObjectSettings = "IncreasingDeliveryPlan.ARAPObjectSettings";
		
	EndIf;
	
	QueryText = "
		|SELECT
		|	IncreasingDeliveryPlan.Period                           AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                   AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)          AS AccountingDimensionByPartners,
		|	IncreasingDeliveryPlan.ARAPObject                   AS ARAPObject,
		|	IncreasingDeliveryPlan.ARAPCurrency             AS Currency,
		|	
		|	0                                                        AS Sum,
		|	0                                                        AS BeingPaid,
		|	0                                                        AS AmountDue,
		|	IncreasingDeliveryPlan.IncreaseToAdmission            AS ToReceive,
		|	
		|	IncreasingDeliveryPlan.BusinessOperation            AS BusinessOperation,
		|	UNDEFINED                                             AS PaymentMethod,
		|	UNDEFINED                                             AS PaymentRequest,
		|	IncreasingDeliveryPlan.PurchaseOrder_                     AS PurchaseByOrder,
		|	IncreasingDeliveryPlan.RecorderDate                 AS RecorderDate,
		|	DATETIME(1,1,1)                                         AS PaymentDate,
		|	0                                                        AS SumCompl,
		|	0                                                        AS SumMan,
		|	0                                                        AS DepositForPackage,
		|	UNDEFINED                                             AS CashFlowItem,
		|	UNDEFINED                                             AS ARAPDocument,
		|	UNDEFINED                                             AS LinkedDocument,
		|	UNDEFINED                                             AS PaymentOption,
		|	IncreasingDeliveryPlan.DocumentCurrency                  AS DocumentCurrency,
		|	UNDEFINED                                             AS CorARAPObject,
		|	UNDEFINED                                             AS CorPartnerAccountingDimension,
		|	
		|	IncreasingDeliveryPlan.Organization                      AS Organization,
		|	IncreasingDeliveryPlan.Partner                          AS Partner,
		|	IncreasingDeliveryPlan.Counterparty                       AS Counterparty,
		|	IncreasingDeliveryPlan.Contract                          AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics             AS LineOfBusiness,
		|	UNDEFINED                                             AS CorPartner,
		|	UNDEFINED                                             AS CorCompany,
		|	UNDEFINED                                             AS CorCounterparty,
		|	UNDEFINED                                             AS CorContract,
		|	UNDEFINED                                             AS CorLineOfBusiness,
		|	IncreasingDeliveryPlan.RecorderNumber                AS RecorderNumber,
		|	&IDOfUnusedFinRecord                    AS FinRecordID,
		|	&TypeOfOperationForSorting                                AS TypeOfOperationForSorting,
		|	1                                                        AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef) AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                        AS RateARAPCurrencyNumerator,
		|	0                                                        AS RateARAPCurrencyDenominator,
		|	0                                                        AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                        AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                             AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                             AS CalculationObjectReceiver,
		|	UNDEFINED                                             AS CurrencyReceiver,
		|	UNDEFINED                                             AS PartnerReceiver,
		|	UNDEFINED                                             AS CompanyDestination,
		|	UNDEFINED                                             AS CounterpartyReceiver,
		|	UNDEFINED                                             AS ContractDestination,
		|	UNDEFINED                                             AS FieldOfActivityReceiver,
		|	0                                                        AS AmountReceiver,
		|	FALSE                                                     AS ByDataOfSourceARAPObject
		|FROM
		|	TTIncreaseInDeliveryPlan AS IncreasingDeliveryPlan
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreasingDeliveryPlan.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|				ON IncreasingDeliveryPlan.Organization = Dimension.Organization
		|					AND IncreasingDeliveryPlan.ARAPObject.Counterparty = Dimension.Counterparty
		|					AND IncreasingDeliveryPlan.Partner = Dimension.Partner
		|					AND IncreasingDeliveryPlan.Contract = Dimension.Contract
		|					AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	NOT ((&ThisIsOrder OR &ThisIsAnInvoice) 
		|		AND IncreasingDeliveryPlan.ExecutionScheduleIsSpecified 
		|		AND &ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts), VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|		AND NOT IncreasingDeliveryPlan.ExceedingOrder)
		|	AND (&ThisIsOrder 
		|			AND &ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|		OR &ThisIsAnInvoice
		|			AND IncreasingDeliveryPlan.InvoiceForOrders
		|			AND &ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|			AND IncreasingDeliveryPlan.ExceedingOrder
		|		OR NOT (&ThisIsOrder OR &ThisIsAnInvoice))
		|";
	
	QueryText = StrReplace(QueryText,"&ARAPObjectSettings",               ARAPObjectSettings);
	QueryText = StrReplace(QueryText,"&ThisIsOrder",                      ThisIsOrder);
	QueryText = StrReplace(QueryText,"&ThisIsAnInvoice",                  ThisIsAnInvoice);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",      TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function ReduceDeliveryPlanFromSupplier(TypeOfOperationForSorting)
	
	QueryText = "
		|SELECT
		|	ReducingDeliveryPlan.RecorderDate                 AS Period,
		|	VALUE(AccumulationRecordType.Expense)                   AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)          AS AccountingDimensionByPartners,
		|	ReducingDeliveryPlan.ARAPObject                   AS ARAPObject,
		|	ReducingDeliveryPlan.ARAPCurrency             AS Currency,
		|	
		|	0                                                        AS Sum,
		|	0                                                        AS BeingPaid,
		|	0                                                        AS AmountDue,
		|	ReducingDeliveryPlan.ReduceToAdmission            AS ToReceive,
		|	
		|	ReducingDeliveryPlan.BusinessOperation            AS BusinessOperation,
		|	UNDEFINED                                             AS PaymentMethod,
		|	UNDEFINED                                             AS PaymentRequest,
		|	ReducingDeliveryPlan.PurchaseOrder_                     AS PurchaseByOrder,
		|	ReducingDeliveryPlan.RecorderDate                 AS RecorderDate,
		|	DATETIME(1,1,1)                                         AS PaymentDate,
		|	0                                                        AS SumCompl,
		|	0                                                        AS SumMan,
		|	0                                                        AS DepositForPackage,
		|	UNDEFINED                                             AS CashFlowItem,
		|	UNDEFINED                                             AS ARAPDocument,
		|	UNDEFINED                                             AS LinkedDocument,
		|	UNDEFINED                                             AS PaymentOption,
		|	ReducingDeliveryPlan.DocumentCurrency                  AS DocumentCurrency,
		|	UNDEFINED                                             AS CorARAPObject,
		|	UNDEFINED                                             AS CorPartnerAccountingDimension,
		|	
		|	ReducingDeliveryPlan.Organization                      AS Organization,
		|	ReducingDeliveryPlan.Partner                          AS Partner,
		|	ReducingDeliveryPlan.ARAPObject.Counterparty        AS Counterparty,
		|	ReducingDeliveryPlan.ARAPObject.Contract           AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics             AS LineOfBusiness,
		|	UNDEFINED                                             AS CorPartner,
		|	UNDEFINED                                             AS CorCompany,
		|	UNDEFINED                                             AS CorCounterparty,
		|	UNDEFINED                                             AS CorContract,
		|	UNDEFINED                                             AS CorLineOfBusiness,
		|	ReducingDeliveryPlan.RecorderNumber                AS RecorderNumber,
		|	&IDOfUnusedFinRecord                    AS FinRecordID,
		|	&TypeOfOperationForSorting                                AS TypeOfOperationForSorting,
		|	1                                                        AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef) AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
		|
		|	0                                                        AS RateARAPCurrencyNumerator,
		|	0                                                        AS RateARAPCurrencyDenominator,
		|	0                                                        AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                        AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                             AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                             AS CalculationObjectReceiver,
		|	UNDEFINED                                             AS CurrencyReceiver,
		|	UNDEFINED                                             AS PartnerReceiver,
		|	UNDEFINED                                             AS CompanyDestination,
		|	UNDEFINED                                             AS CounterpartyReceiver,
		|	UNDEFINED                                             AS ContractDestination,
		|	UNDEFINED                                             AS FieldOfActivityReceiver,
		|	0                                                        AS AmountReceiver,
		|	FALSE                                                     AS ByDataOfSourceARAPObject
		|FROM
		|	TTReductionOfDeliveryPlan AS ReducingDeliveryPlan
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ReducingDeliveryPlan.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|				ON ReducingDeliveryPlan.Organization = Dimension.Organization
		|					AND ReducingDeliveryPlan.Counterparty = Dimension.Counterparty
		|					AND ReducingDeliveryPlan.Partner = Dimension.Partner
		|					AND ReducingDeliveryPlan.Contract = Dimension.Contract
		|					AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	(ReducingDeliveryPlan.ExecutionScheduleIsSpecified 
		|		AND ReducingDeliveryPlan.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts),
		|		                                             VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|	OR ReducingDeliveryPlan.InvoiceForOrders 
		|		AND (ReducingDeliveryPlan.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders),
		|		                                              VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			OR ReducingDeliveryPlan.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts),
		|			                                               VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|				AND NOT ReducingDeliveryPlan.ExecutionScheduleIsSpecified))
		|";
	
	QueryText = StrReplace(QueryText, "&TypeOfOperationForSorting", TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function IncreaseSupplierDebt(Operation, TypeOfOperationForSorting, OrderOfOperationsWithinDocument = "1")
	
	If Operation = "PaymentToVendor" Or Operation = "OffsettingSupplierSObligations" Then
		
		PaymentMethod = "IncreaseInSupplierDebt.PaymentMethod";
		PaymentRequest = "IncreaseInSupplierDebt.PaymentRequest";
		CashFlowItem = "IncreaseInSupplierDebt.CashFlowItem";
		LinkedDocument = "IncreaseInSupplierDebt.LinkedDocument";
		FinRecordID = "IncreaseInSupplierDebt.FinRecordID";
		BusinessTransactionSetting = "IncreaseInSupplierDebt.BusinessTransactionSetting";
		SettlementTransaction = "CASE WHEN IncreaseInSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		THEN VALUE(Enum.SettlementOperations.AdjustmentOfInvoice)
		|	WHEN IncreaseInSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
		|		OR IncreaseInSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor)
		|		OR IncreaseInSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction)
		|		OR IncreaseInSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|		OR IncreaseInSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
		|		THEN VALUE(Enum.SettlementOperations.ARAPAdjustment)
		|	ELSE VALUE(Enum.SettlementOperations.Payment)
		|END";
		If Operation = "PaymentToVendor" Then
			SumCompl = "IncreaseInSupplierDebt.SumCompl";
			SumMan = "IncreaseInSupplierDebt.SumMan";
			PaymentDate = "CASE WHEN IncreaseInSupplierDebt.AmountARAP < 0
			|			THEN BEGINOFPERIOD(IncreaseInSupplierDebt.RecorderDate, DAY)
			|		ELSE IncreaseInSupplierDebt.MaturityDate
			|	END";
		Else
			SumCompl = "0";
			SumMan = "0";
			PaymentDate = "CASE WHEN IncreaseInSupplierDebt.AmountARAP < 0
			|			THEN BEGINOFPERIOD(IncreaseInSupplierDebt.RecorderDate, DAY)
			|		ELSE DATETIME(1,1,1)
			|	END";
		EndIf;
		
	ElsIf Operation = "ReturnOfGoodsToVendor" Then
		
		PaymentMethod = "Undefined";
		PaymentRequest = "Undefined";
		CashFlowItem = "Undefined";
		LinkedDocument = "Undefined";
		FinRecordID = "IncreaseInSupplierDebt.FinRecordID";
		BusinessTransactionSetting = "IncreaseInSupplierDebt.BusinessTransactionSetting";
		SettlementTransaction = "CASE WHEN
		|	IncreaseInSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolderStorno)
		|		THEN VALUE(Enum.SettlementOperations.ARAPAdjustment)
		|	ELSE VALUE(Enum.SettlementOperations.AdjustmentOfInvoice)
		|END";
		SumCompl = "0";
		SumMan = "0";
		PaymentDate = "CASE WHEN IncreaseInSupplierDebt.AmountARAP < 0
		|			THEN BEGINOFPERIOD(IncreaseInSupplierDebt.RecorderDate, DAY)
		|		ELSE DATETIME(1,1,1)
		|	END";
		
	ElsIf Operation = "Purchase" Then
		
		PaymentMethod = "Undefined";
		PaymentRequest = "Undefined";
		CashFlowItem = "Undefined";
		LinkedDocument = "Undefined";
		FinRecordID = "IncreaseInSupplierDebt.ARAPObject.UUID";
		BusinessTransactionSetting = "Undefined";
		SettlementTransaction = "VALUE(Enum.SettlementOperations.Shipment)";
		SumCompl = "0";
		SumMan = "0";
		PaymentDate = "CASE WHEN IncreaseInSupplierDebt.AmountARAP < 0
		|			THEN BEGINOFPERIOD(IncreaseInSupplierDebt.RecorderDate, DAY)
		|		ELSE DATETIME(1,1,1)
		|	END";
		
	EndIf;
	
	QueryText = 
		"SELECT
		|	IncreaseInSupplierDebt.RecorderDate                   AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                               AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                      AS AccountingDimensionByPartners,
		|	IncreaseInSupplierDebt.ARAPObject                     AS ARAPObject,
		|	IncreaseInSupplierDebt.ARAPCurrency               AS Currency,
		|	
		|	IncreaseInSupplierDebt.AmountARAP                AS Sum,
		|	0                                                                    AS BeingPaid,
		|	0                                                                    AS AmountDue,
		|	0                                                                    AS ToReceive,
		|	
		|	IncreaseInSupplierDebt.BusinessOperation              AS BusinessOperation,
		|	&PaymentMethod                                                         AS PaymentMethod,
		|	&PaymentRequest                                 AS PaymentRequest,
		|	UNDEFINED                                                         AS PurchaseByOrder,
		|	IncreaseInSupplierDebt.RecorderDate                   AS RecorderDate,
		|	&PaymentDate                                                         AS PaymentDate,
		|	CASE WHEN IncreaseInSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreaseInSupplierDebt.AmountARAP
		|			WHEN IncreaseInSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreaseInSupplierDebt.Sum
		|			ELSE CASE WHEN &SumCompl = 0 
		|						THEN CAST(IncreaseInSupplierDebt.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|					ELSE &SumCompl
		|				END
		|	END                                                                AS SumCompl,
		|	CASE WHEN IncreaseInSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|				THEN IncreaseInSupplierDebt.AmountARAP
		|			WHEN IncreaseInSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN IncreaseInSupplierDebt.Sum
		|			ELSE CASE WHEN &SumMan = 0 
		|						THEN CAST(IncreaseInSupplierDebt.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|					ELSE &SumMan
		|				END
		|	END                                                               AS SumMan,
		|	0                                                                   AS DepositForPackage,
		|	&CashFlowItem                                      AS CashFlowItem,
		|	UNDEFINED                                                        AS ARAPDocument,
		|	//Payment procedure
		|	//The order of offsetting by payment date
		|	&LinkedDocument                                                  AS LinkedDocument,
		|	UNDEFINED                                                        AS PaymentOption,
		|	IncreaseInSupplierDebt.DocumentCurrency                   AS DocumentCurrency,
		|	UNDEFINED                                                        AS CorARAPObject,
		|	UNDEFINED                                                        AS CorPartnerAccountingDimension,
		|	
		|	CASE WHEN IncreaseInSupplierDebt.Organization <> IncreaseInSupplierDebt.ARAPObject.Organization
		|		THEN IncreaseInSupplierDebt.Organization
		|		ELSE IncreaseInSupplierDebt.ARAPObject.Organization
		|	END                                                               AS Organization,
		|	IncreaseInSupplierDebt.Partner                           AS Partner,
		|	IncreaseInSupplierDebt.ARAPObject.Counterparty         AS Counterparty,
		|	IncreaseInSupplierDebt.ARAPObject.Contract            AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                        AS LineOfBusiness,
		|	
		|	UNDEFINED                                                        AS CorPartner,
		|	UNDEFINED                                                        AS CorCompany,
		|	UNDEFINED                                                        AS CorCounterparty,
		|	UNDEFINED                                                        AS CorContract,
		|	UNDEFINED                                                        AS CorLineOfBusiness,
		|	IncreaseInSupplierDebt.RecorderNumber                 AS RecorderNumber,
		|	&FinRecordID                                             AS FinRecordID,
		|	&TypeOfOperationForSorting                                           AS TypeOfOperationForSorting,
		|	&OrderOfOperationsWithinDocument                                  AS OrderOfOperationsWithinDocument,
		|	&SettlementTransaction                                             AS SettlementTransaction,
		|	&BusinessTransactionSetting                                     AS BusinessTransactionSetting,
		|
		|	CASE WHEN IncreaseInSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreaseInSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|		OR &SumCompl <> 0
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                               AS RateARAPCurrencyNumerator,
		|	CASE WHEN IncreaseInSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreaseInSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|		OR &SumCompl <> 0
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                               AS RateARAPCurrencyDenominator,
		|	CASE WHEN IncreaseInSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreaseInSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|		OR &SumMan <> 0
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                               AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN IncreaseInSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreaseInSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|		OR &SumMan <> 0
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                               AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                        AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                        AS CalculationObjectReceiver,
		|	UNDEFINED                                                        AS CurrencyReceiver,
		|	UNDEFINED                                                        AS PartnerReceiver,
		|	UNDEFINED                                                        AS CompanyDestination,
		|	UNDEFINED                                                        AS CounterpartyReceiver,
		|	UNDEFINED                                                        AS ContractDestination,
		|	UNDEFINED                                                        AS FieldOfActivityReceiver,
		|	0                                                                   AS AmountReceiver,
		|	FALSE                                                                AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreaseInSupplierDebt AS IncreaseInSupplierDebt
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreaseInSupplierDebt.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = IncreaseInSupplierDebt.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|				ON CASE WHEN IncreaseInSupplierDebt.Organization <> IncreaseInSupplierDebt.ARAPObject.Organization
		|							THEN IncreaseInSupplierDebt.Organization
		|							ELSE IncreaseInSupplierDebt.ARAPObject.Organization
		|					END = Dimension.Organization
		|					AND IncreaseInSupplierDebt.ARAPObject.Counterparty = Dimension.Counterparty
		|					AND IncreaseInSupplierDebt.Partner = Dimension.Partner
		|					AND IncreaseInSupplierDebt.ARAPObject.Contract = Dimension.Contract
		|					AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = IncreaseInSupplierDebt.Ref
		|				AND Coefficients.ARAPObject = IncreaseInSupplierDebt.ARAPObject
		|				AND Coefficients.ARAPCurrency = IncreaseInSupplierDebt.ARAPCurrency
		|				AND Coefficients.DateOfCourse = IncreaseInSupplierDebt.DateOfCourse
		|WHERE
		|	IncreaseInSupplierDebt.AmountARAP <> 0
		|";
	
	QueryText = StrReplace(QueryText,"&PaymentMethod",                         PaymentMethod);
	QueryText = StrReplace(QueryText,"&PaymentRequest", PaymentRequest);
	QueryText = StrReplace(QueryText,"&CashFlowItem",       CashFlowItem);
	QueryText = StrReplace(QueryText,"&LinkedDocument",                   LinkedDocument);
	QueryText = StrReplace(QueryText,"&FinRecordID",              FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting",      BusinessTransactionSetting);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",            TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&OrderOfOperationsWithinDocument",   OrderOfOperationsWithinDocument);
	QueryText = StrReplace(QueryText,"&SettlementTransaction",              SettlementTransaction);
	QueryText = StrReplace(QueryText,"&SumCompl",                           SumCompl);
	QueryText = StrReplace(QueryText,"&SumMan",                            SumMan);
	QueryText = StrReplace(QueryText,"&PaymentDate",                         PaymentDate);
	
	Return QueryText;
	
EndFunction

Function IncreaseOurSupplierDebt(Operation, TypeOfOperationForSorting)
	
	If Operation = "Purchase" Then
		
		PurchaseOrder_ = "IncreasingOurSupplierDebt.PurchaseOrder_";
		PaymentDate = "CASE WHEN IncreasingOurSupplierDebt.Sum < 0
						|		THEN DATETIME(1,1,1)
						|	ELSE IncreasingOurSupplierDebt.PaymentDate
						|END";
		DepositForPackage = "IncreasingOurSupplierDebt.AmountARAPByPackage";
		CashFlowItem = "Undefined";
		LinkedDocument = "IncreasingOurSupplierDebt.LinkedDocument";
		FinRecordID = "IncreasingOurSupplierDebt.ARAPObject.UUID";
		BusinessTransactionSetting = "Undefined";
		BusinessOperation = "IncreasingOurSupplierDebt.BusinessOperation";
		SettlementTransaction = "CASE WHEN IncreasingOurSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolder)
						|		THEN VALUE(Enum.SettlementOperations.ARAPAdjustment)
						|	WHEN IncreasingOurSupplierDebt.Sum < 0
						|		THEN VALUE(Enum.SettlementOperations.AdjustmentOfInvoice)
						|	ELSE VALUE(Enum.SettlementOperations.Shipment)
						|END";
		PaymentOption = "IncreasingOurSupplierDebt.PaymentOption";
		
	ElsIf Operation = "RefundOfPaymentFromSupplier" Then
		
		PurchaseOrder_ = "Undefined";
		PaymentDate = "BEGINOFPERIOD(IncreasingOurSupplierDebt.RecorderDate, DAY)";
		DepositForPackage = "0";
		CashFlowItem = "IncreasingOurSupplierDebt.CashFlowItem";
		LinkedDocument = "Undefined";
		FinRecordID = "IncreasingOurSupplierDebt.FinRecordID";
		BusinessTransactionSetting = "IncreasingOurSupplierDebt.BusinessTransactionSetting";
		BusinessOperation = "IncreasingOurSupplierDebt.BusinessOperation";
		SettlementTransaction = "CASE WHEN IncreasingOurSupplierDebt.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundOfAdvanceHolderBooking)
						|		THEN VALUE(Enum.SettlementOperations.ARAPAdjustment)
						|	ELSE VALUE(Enum.SettlementOperations.Refund)
						|END";
		PaymentOption = "Undefined";
		
	EndIf;
	
	QueryText = 
		"SELECT
		|	IncreasingOurSupplierDebt.RecorderDate               AS Period,
		|	VALUE(AccumulationRecordType.Expense)                                AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                       AS AccountingDimensionByPartners,
		|	IncreasingOurSupplierDebt.ARAPObject                 AS ARAPObject,
		|	IncreasingOurSupplierDebt.ARAPCurrency           AS Currency,
		|	
		|	(IncreasingOurSupplierDebt.AmountARAP)          AS Sum,
		|	0                                                                     AS BeingPaid,
		|	0                                                                     AS AmountDue,
		|	0                                                                     AS ToReceive,
		|	
		|	&BusinessOperation                                                AS BusinessOperation,
		|	IncreasingOurSupplierDebt.PaymentMethod                    AS PaymentMethod,
		|	UNDEFINED                                                          AS PaymentRequest,
		|	&PurchaseOrder_                                                         AS PurchaseByOrder,
		|	IncreasingOurSupplierDebt.RecorderDate               AS RecorderDate,
		|	&PaymentDate                                                          AS PaymentDate,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.AmountARAP
		|			WHEN IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.Sum
		|			ELSE CAST(IncreasingOurSupplierDebt.Sum * Coefficients.LocalCoefficient AS NUMBER(31,2))
		|	END                                                                 AS SumCompl,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.AmountARAP
		|			WHEN IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|				THEN IncreasingOurSupplierDebt.Sum
		|			ELSE CAST(IncreasingOurSupplierDebt.Sum * Coefficients.ManSCoefficient AS NUMBER(31,2))
		|	END                                                                 AS SumMan,
		|	&DepositForPackage                                                          AS DepositForPackage,
		|	&CashFlowItem                                        AS CashFlowItem,
		|	UNDEFINED                                                          AS ARAPDocument,
		|	//Payment procedure
		|	//The order of offsetting by payment date
		|	&LinkedDocument                                                    AS LinkedDocument,
		|	&PaymentOption                                                        AS PaymentOption,
		|	IncreasingOurSupplierDebt.DocumentCurrency                AS DocumentCurrency,
		|	UNDEFINED                                                          AS CorARAPObject,
		|	UNDEFINED                                                          AS CorPartnerAccountingDimension,
		|	
		|	CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|		THEN IncreasingOurSupplierDebt.Organization
		|		ELSE IncreasingOurSupplierDebt.ARAPObject.Organization
		|	END                                                                 AS Organization,
		|	IncreasingOurSupplierDebt.Partner                        AS Partner,
		|	IncreasingOurSupplierDebt.ARAPObject.Counterparty      AS Counterparty,
		|	IncreasingOurSupplierDebt.ARAPObject.Contract         AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                          AS LineOfBusiness,
		|	
		|	UNDEFINED                                                          AS CorPartner,
		|	UNDEFINED                                                          AS CorCompany,
		|	UNDEFINED                                                          AS CorCounterparty,
		|	UNDEFINED                                                          AS CorContract,
		|	UNDEFINED                                                          AS CorLineOfBusiness,
		|	IncreasingOurSupplierDebt.RecorderNumber              AS RecorderNumber,
		|	&FinRecordID                                               AS FinRecordID,
		|	&TypeOfOperationForSorting                                             AS TypeOfOperationForSorting,
		|	CASE 
		|		WHEN &SettlementTransaction = VALUE(Enum.SettlementOperations.Shipment)
		|			THEN 4
		|		ELSE 1
		|	END                                                                 AS OrderOfOperationsWithinDocument,
		|	&SettlementTransaction                                               AS SettlementTransaction,
		|	&BusinessTransactionSetting                                       AS BusinessTransactionSetting,
		|
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyNumerator
		|	END                                                            AS RateARAPCurrencyNumerator,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = Coefficients.LocalAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = Coefficients.LocalAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.RateARAPCurrencyDenominator
		|	END                                                            AS RateARAPCurrencyDenominator,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateNumeratorOfManSCurrency
		|	END                                                            AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE WHEN IncreasingOurSupplierDebt.ARAPCurrency = &ManagementAccountingCurrency
		|		OR IncreasingOurSupplierDebt.DocumentCurrency = &ManagementAccountingCurrency
		|			THEN 0
		|		ELSE Coefficients.ExchangeRateDenominatorCurrencyMan
		|	END                                                            AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                          AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                          AS CalculationObjectReceiver,
		|	UNDEFINED                                                          AS CurrencyReceiver,
		|	UNDEFINED                                                          AS PartnerReceiver,
		|	UNDEFINED                                                          AS CompanyDestination,
		|	UNDEFINED                                                          AS CounterpartyReceiver,
		|	UNDEFINED                                                          AS ContractDestination,
		|	UNDEFINED                                                          AS FieldOfActivityReceiver,
		|	0                                                                     AS AmountReceiver,
		|	FALSE                                                                  AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreasingOurSupplierDebt AS IncreasingOurSupplierDebt
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreasingOurSupplierDebt.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = IncreasingOurSupplierDebt.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|				ON CASE WHEN ISNULL(ContractData.CentralizedContract, FALSE)
		|							THEN IncreasingOurSupplierDebt.Organization
		|							ELSE IncreasingOurSupplierDebt.ARAPObject.Organization
		|					END = Dimension.Organization
		|					AND IncreasingOurSupplierDebt.ARAPObject.Counterparty = Dimension.Counterparty
		|					AND IncreasingOurSupplierDebt.Partner = Dimension.Partner
		|					AND IncreasingOurSupplierDebt.ARAPObject.Contract = Dimension.Contract
		|					AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|		LEFT JOIN ARAPAccountingOfTTCurrencyConversionRates AS Coefficients
		|			ON Coefficients.Ref = IncreasingOurSupplierDebt.Ref
		|				AND Coefficients.ARAPObject = IncreasingOurSupplierDebt.ARAPObject
		|				AND Coefficients.ARAPCurrency = IncreasingOurSupplierDebt.ARAPCurrency
		|				AND Coefficients.DateOfCourse = IncreasingOurSupplierDebt.DateOfCourse
		|WHERE
		|	IncreasingOurSupplierDebt.AmountARAP <> 0
		|";
	
	QueryText = StrReplace(QueryText,"&PurchaseOrder_",                   PurchaseOrder_);
	QueryText = StrReplace(QueryText,"&PaymentDate",                    PaymentDate);
	QueryText = StrReplace(QueryText,"&DepositForPackage",                    DepositForPackage);
	QueryText = StrReplace(QueryText,"&CashFlowItem",  CashFlowItem);
	QueryText = StrReplace(QueryText,"&LinkedDocument",              LinkedDocument);
	QueryText = StrReplace(QueryText,"&FinRecordID",         FinRecordID);
	QueryText = StrReplace(QueryText,"&BusinessTransactionSetting", BusinessTransactionSetting);
	QueryText = StrReplace(QueryText,"&BusinessOperation",          BusinessOperation);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",       TypeOfOperationForSorting);
	QueryText = StrReplace(QueryText,"&SettlementTransaction",         SettlementTransaction);
	QueryText = StrReplace(QueryText,"&PaymentOption",                  PaymentOption);
	
	Return QueryText;
	
EndFunction

Function IncreaseIsPaidToSupplier_(Operation, TypeOfOperationForSorting)
	
	If Operation = "RequestForPaymentToSupplier" Then
		PaymentRequest = "IncreaseIsPaidToSupplier.Ref";
	ElsIf Operation = "PaymentToVendor" Then
		PaymentRequest = "IncreaseIsPaidToSupplier.PaymentRequest";
	EndIf;
	
	QueryText = 
		"SELECT
		|	IncreaseIsPaidToSupplier.RecorderDate                   AS Period,
		|	VALUE(AccumulationRecordType.Expense)                              AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                     AS AccountingDimensionByPartners,
		|	IncreaseIsPaidToSupplier.ARAPObject                     AS ARAPObject,
		|	IncreaseIsPaidToSupplier.ARAPCurrency               AS Currency,
		|	
		|	0                                                                   AS Sum,
		|	(IncreaseIsPaidToSupplier.IncreaseIsPaid)           AS BeingPaid,
		|	0                                                                   AS AmountDue,
		|	0                                                                   AS ToReceive,
		|	
		|	IncreaseIsPaidToSupplier.BusinessOperation              AS BusinessOperation,
		|	IncreaseIsPaidToSupplier.PaymentMethod                        AS PaymentMethod,
		|	&PaymentRequest                                AS PaymentRequest,
		|	UNDEFINED                                                        AS PurchaseByOrder,
		|	IncreaseIsPaidToSupplier.RecorderDate                   AS RecorderDate,
		|	DATETIME(1,1,1)                                                    AS PaymentDate,
		|	0                                                                   AS SumCompl,
		|	0                                                                   AS SumMan,
		|	0                                                                   AS DepositForPackage,
		|	IncreaseIsPaidToSupplier.CashFlowItem      AS CashFlowItem,
		|	UNDEFINED                                                        AS ARAPDocument,
		|	//Payment procedure
		|	//The order of offsetting by payment date
		|	UNDEFINED                                                        AS LinkedDocument,
		|	UNDEFINED                                                        AS PaymentOption,
		|	IncreaseIsPaidToSupplier.DocumentCurrency                    AS DocumentCurrency,
		|	UNDEFINED                                                        AS CorARAPObject,
		|	UNDEFINED                                                        AS CorPartnerAccountingDimension,
		|	
		|	IncreaseIsPaidToSupplier.ARAPObject.Organization         AS Organization,
		|	IncreaseIsPaidToSupplier.Partner                            AS Partner,
		|	IncreaseIsPaidToSupplier.ARAPObject.Counterparty          AS Counterparty,
		|	IncreaseIsPaidToSupplier.ARAPObject.Contract             AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                        AS LineOfBusiness,
		|	
		|	UNDEFINED                                                        AS CorPartner,
		|	UNDEFINED                                                        AS CorCompany,
		|	UNDEFINED                                                        AS CorCounterparty,
		|	UNDEFINED                                                        AS CorContract,
		|	UNDEFINED                                                        AS CorLineOfBusiness,
		|	IncreaseIsPaidToSupplier.RecorderNumber                  AS RecorderNumber,
		|	&IDOfUnusedFinRecord                               AS FinRecordID,
		|	&TypeOfOperationForSorting                                           AS TypeOfOperationForSorting,
		|	1                                                                   AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)          AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)    AS BusinessTransactionSetting,
		|
		|	0                                                                   AS RateARAPCurrencyNumerator,
		|	0                                                                   AS RateARAPCurrencyDenominator,
		|	0                                                                   AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                   AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                        AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                        AS CalculationObjectReceiver,
		|	UNDEFINED                                                        AS CurrencyReceiver,
		|	UNDEFINED                                                        AS PartnerReceiver,
		|	UNDEFINED                                                        AS CompanyDestination,
		|	UNDEFINED                                                        AS CounterpartyReceiver,
		|	UNDEFINED                                                        AS ContractDestination,
		|	UNDEFINED                                                        AS FieldOfActivityReceiver,
		|	0                                                                   AS AmountReceiver,
		|	FALSE                                                                AS ByDataOfSourceARAPObject
		|FROM
		|	#IncreaseIsPaidToSupplier AS IncreaseIsPaidToSupplier
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON IncreaseIsPaidToSupplier.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref =  IncreaseIsPaidToSupplier.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|				ON IncreaseIsPaidToSupplier.ARAPObject.Organization = Dimension.Organization
		|					AND IncreaseIsPaidToSupplier.ARAPObject.Counterparty = Dimension.Counterparty
		|					AND IncreaseIsPaidToSupplier.Partner = Dimension.Partner
		|					AND IncreaseIsPaidToSupplier.ARAPObject.Contract = Dimension.Contract
		|					AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	IncreaseIsPaidToSupplier.IncreaseIsPaid > 0
		|";
	
	QueryText = StrReplace(QueryText,"&PaymentRequest", PaymentRequest);
	QueryText = StrReplace(QueryText,"&TypeOfOperationForSorting",            TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function FeeIsPaidToSupplier(TypeOfOperationForSorting)
	
	QueryText = 
		"SELECT
		|	ReductionIsPaidToSupplier.RecorderDate                    AS Period,
		|	VALUE(AccumulationRecordType.Receipt)                               AS RecordType,
		|	
		|	ISNULL(Dimension.DimensionKey, UNDEFINED)                      AS AccountingDimensionByPartners,
		|	ReductionIsPaidToSupplier.ARAPObject                      AS ARAPObject,
		|	ReductionIsPaidToSupplier.ARAPCurrency                AS Currency,
		|	
		|	0                                                                    AS Sum,
		|	(ReductionIsPaidToSupplier.ReductionIsPaid)            AS BeingPaid,
		|	0                                                                    AS AmountDue,
		|	0                                                                    AS ToReceive,
		|	
		|	ReductionIsPaidToSupplier.BusinessOperation               AS BusinessOperation,
		|	ReductionIsPaidToSupplier.PaymentMethod                         AS PaymentMethod,
		|	ReductionIsPaidToSupplier.PaymentRequest AS PaymentRequest,
		|	UNDEFINED                                                         AS PurchaseByOrder,
		|	ReductionIsPaidToSupplier.RecorderDate                    AS RecorderDate,
		|	DATETIME(1,1,1)                                                     AS PaymentDate,
		|	0                                                                    AS SumCompl,
		|	0                                                                    AS SumMan,
		|	0                                                                    AS DepositForPackage,
		|	ReductionIsPaidToSupplier.CashFlowItem       AS CashFlowItem,
		|	UNDEFINED                                                         AS ARAPDocument,
		|	//Payment procedure
		|	//The order of offsetting by payment date
		|	UNDEFINED                                                         AS LinkedDocument,
		|	UNDEFINED                                                         AS PaymentOption,
		|	ReductionIsPaidToSupplier.DocumentCurrency                     AS DocumentCurrency,
		|	UNDEFINED                                                         AS CorARAPObject,
		|	UNDEFINED                                                         AS CorPartnerAccountingDimension,
		|	
		|	ReductionIsPaidToSupplier.ARAPObject.Organization          AS Organization,
		|	ReductionIsPaidToSupplier.Partner                             AS Partner,
		|	ReductionIsPaidToSupplier.ARAPObject.Counterparty           AS Counterparty,
		|	ReductionIsPaidToSupplier.ARAPObject.Contract              AS Contract,
		|	LinesOfBusiness.DirectionOfAnalytics                         AS LineOfBusiness,
		|	
		|	UNDEFINED                                                         AS CorPartner,
		|	UNDEFINED                                                         AS CorCompany,
		|	UNDEFINED                                                         AS CorCounterparty,
		|	UNDEFINED                                                         AS CorContract,
		|	UNDEFINED                                                         AS CorLineOfBusiness,
		|	ReductionIsPaidToSupplier.RecorderNumber                   AS RecorderNumber,
		|	&IDOfUnusedFinRecord                                AS FinRecordID,
		|	&TypeOfOperationForSorting                                            AS TypeOfOperationForSorting,
		|	1                                                                    AS OrderOfOperationsWithinDocument,
		|	VALUE(Enum.SettlementOperations.EmptyRef)           AS SettlementTransaction,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)     AS BusinessTransactionSetting,
		|
		|	0                                                                    AS RateARAPCurrencyNumerator,
		|	0                                                                    AS RateARAPCurrencyDenominator,
		|	0                                                                    AS ExchangeRateNumeratorOfManSCurrency,
		|	0                                                                    AS ExchangeRateDenominatorCurrencyMan,
		|
		|	UNDEFINED                                                         AS DestinationAccountingDimensionByPartners,
		|	UNDEFINED                                                         AS CalculationObjectReceiver,
		|	UNDEFINED                                                         AS CurrencyReceiver,
		|	UNDEFINED                                                         AS PartnerReceiver,
		|	UNDEFINED                                                         AS CompanyDestination,
		|	UNDEFINED                                                         AS CounterpartyReceiver,
		|	UNDEFINED                                                         AS ContractDestination,
		|	UNDEFINED                                                         AS FieldOfActivityReceiver,
		|	0                                                                    AS AmountReceiver,
		|	FALSE                                                                 AS ByDataOfSourceARAPObject
		|FROM
		|	#ReductionIsPaidToSupplier AS ReductionIsPaidToSupplier
		|		INNER JOIN TTLinesOfBusiness AS LinesOfBusiness
		|			ON ReductionIsPaidToSupplier.ARAPObject = LinesOfBusiness.ARAPObject
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref =  ReductionIsPaidToSupplier.ARAPObject.Contract
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|				ON ReductionIsPaidToSupplier.ARAPObject.Organization = Dimension.Organization
		|					AND ReductionIsPaidToSupplier.ARAPObject.Counterparty = Dimension.Counterparty
		|					AND ReductionIsPaidToSupplier.Partner = Dimension.Partner
		|					AND ReductionIsPaidToSupplier.ARAPObject.Contract = Dimension.Contract
		|					AND LinesOfBusiness.DirectionOfAnalytics = Dimension.LineOfBusiness
		|WHERE
		|	ReductionIsPaidToSupplier.ReductionIsPaid > 0
		|";
	
	QueryText = StrReplace(QueryText, "&TypeOfOperationForSorting", TypeOfOperationForSorting);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTReducingDeliveryPlan()
	
	QueryText = "
		|SELECT
		|	ReducingDeliveryPlan.ARAPObjectSettings                  AS ARAPObjectSettings,
		|	ReducingDeliveryPlan.InvoiceForOrders               AS InvoiceForOrders,
		|	
		|	CASE
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN ReducingDeliveryPlan.PurchaseOrder_.ARAPObject
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectContract.Ref
		|		ELSE ReducingDeliveryPlan.ARAPObject
		|	END                                                    AS ARAPObject,
		|	ReducingDeliveryPlan.ARAPCurrency             AS ARAPCurrency,
		|	
		|	ReducingDeliveryPlan.ReduceToAdmission            AS ReduceToAdmission,
		|	
		|	ReducingDeliveryPlan.BusinessOperation            AS BusinessOperation,
		|	CASE WHEN ReducingDeliveryPlan.ExceedingOrder
		|			THEN UNDEFINED 
		|			ELSE ReducingDeliveryPlan.PurchaseOrder_
		|	END                                                    AS PurchaseOrder_,
		|	ReducingDeliveryPlan.RecorderDate                 AS RecorderDate,
		|	ReducingDeliveryPlan.DocumentCurrency                  AS DocumentCurrency,
		|	
		|	CASE
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN ReducingDeliveryPlan.PurchaseOrder_.ARAPObject.Organization
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectContract.Organization
		|		WHEN ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)
		|			THEN ReducingDeliveryPlan.ARAPObject.Organization
		|		ELSE ReducingDeliveryPlan.Organization
		|	END                                                    AS Organization,
		|	CASE
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN ReducingDeliveryPlan.PurchaseOrder_.ARAPObject.Partner
		|		ELSE ReducingDeliveryPlan.Partner
		|	END                                                    AS Partner,
		|	CASE
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN ReducingDeliveryPlan.PurchaseOrder_.ARAPObject.Counterparty
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectContract.Counterparty
		|		ELSE ReducingDeliveryPlan.ARAPObject.Counterparty
		|	END                                                    AS Counterparty,
		|	CASE
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN ReducingDeliveryPlan.PurchaseOrder_.ARAPObject.Contract
		|		WHEN ReducingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectContract.Contract
		|		ELSE ReducingDeliveryPlan.ARAPObject.Contract
		|	END                                                    AS Contract,
		|	ReducingDeliveryPlan.RecorderNumber                AS RecorderNumber,
		|	ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)     AS ExecutionScheduleIsSpecified
		|INTO TTReductionOfDeliveryPlan
		|FROM
		|	#ReducingDeliveryPlan AS ReducingDeliveryPlan
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref = ReducingDeliveryPlan.ARAPObject.Contract
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectContract
		|			ON ReducingDeliveryPlan.ARAPObject.Contract = ARAPObjectContract.Object
		|				AND ARAPObjectContract.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
		|				AND ReducingDeliveryPlan.ARAPObject.Organization = ARAPObjectContract.Organization
		|				AND NOT ARAPObjectContract.OnlyBalance
		|				AND NOT ARAPObjectContract.DeletionMark
		|WHERE
		|	ReducingDeliveryPlan.ReduceToAdmission <> 0 
		|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTIncreasingDeliveryPlan(ThisIsPurchase=False)
	
	If ThisIsPurchase Then
		InvoiceForOrders = "IncreasingDeliveryPlan.InvoiceForOrders";
		ExceedingOrder = "IncreasingDeliveryPlan.ExceedingOrder";
		Period = "IncreasingDeliveryPlan.RecorderDate";
		PurchaseOrder_ = "CASE WHEN IncreasingDeliveryPlan.ExceedingOrder
						|		THEN UNDEFINED
						|	ELSE IncreasingDeliveryPlan.PurchaseOrder_
						|END";
		ARAPObjectOfOrder = "IncreasingDeliveryPlan.PurchaseOrder_.ARAPObject";
	Else
		InvoiceForOrders = "FALSE";
		ExceedingOrder = "FALSE";
		Period = "ENDOFPERIOD(IncreasingDeliveryPlan.DateOfReceipt, DAY)";
		PurchaseOrder_ = "UNDEFINED";
		ARAPObjectOfOrder = "UNDEFINED";
	EndIf;
	
	
	QueryText = "
		|SELECT
		|	IncreasingDeliveryPlan.ARAPObjectSettings                  AS ARAPObjectSettings,
		|	&InvoiceForOrders                                      AS InvoiceForOrders,
		|	&Period                                                  AS Period,
		|	&ExceedingOrder                                             AS ExceedingOrder,
		|	
		|	CASE
		|		WHEN IncreasingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			AND ISNULL(&ARAPObjectOfOrder, UNDEFINED) <> UNDEFINED
		|			THEN ARAPObjectOrder.Ref
		|		WHEN IncreasingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectContract.Ref
		|		ELSE IncreasingDeliveryPlan.ARAPObject
		|	END                                                    AS ARAPObject,
		|	IncreasingDeliveryPlan.ARAPCurrency             AS ARAPCurrency,
		|	
		|	IncreasingDeliveryPlan.IncreaseToAdmission            AS IncreaseToAdmission,
		|	
		|	IncreasingDeliveryPlan.BusinessOperation            AS BusinessOperation,
		|	&PurchaseOrder_                                            AS PurchaseOrder_,
		|	IncreasingDeliveryPlan.RecorderDate                 AS RecorderDate,
		|	IncreasingDeliveryPlan.DocumentCurrency                  AS DocumentCurrency,
		|	
		|	CASE
		|		WHEN IncreasingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN IncreasingDeliveryPlan.ARAPObject.Organization
		|		WHEN IncreasingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectContract.Organization
		|		WHEN ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)
		|			THEN IncreasingDeliveryPlan.ARAPObject.Organization
		|		ELSE IncreasingDeliveryPlan.Organization
		|	END                                                    AS Organization,
		|	CASE
		|		WHEN IncreasingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|			THEN IncreasingDeliveryPlan.ARAPObject.Partner
		|		ELSE IncreasingDeliveryPlan.Partner
		|	END                                                    AS Partner,
		|	CASE
		|		WHEN IncreasingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectContract.Counterparty
		|		ELSE IncreasingDeliveryPlan.ARAPObject.Counterparty
		|	END                                                    AS Counterparty,
		|	CASE
		|		WHEN IncreasingDeliveryPlan.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN ARAPObjectContract.Contract
		|		ELSE IncreasingDeliveryPlan.ARAPObject.Contract
		|	END                                                    AS Contract,
		|	IncreasingDeliveryPlan.RecorderNumber                AS RecorderNumber,
		|	ISNULL(ContractData.ExecutionScheduleIsSpecified, FALSE)     AS ExecutionScheduleIsSpecified
		|INTO TTIncreaseInDeliveryPlan
		|FROM
		|	#IncreasingDeliveryPlan AS IncreasingDeliveryPlan
		|		LEFT JOIN Catalog.CounterpartyContracts AS ContractData
		|			ON ContractData.Ref =  IncreasingDeliveryPlan.ARAPObject.Contract
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectContract
		|			ON IncreasingDeliveryPlan.ARAPObject.Contract = ARAPObjectContract.Object
		|				AND ARAPObjectContract.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
		|				AND IncreasingDeliveryPlan.ARAPObject.Organization = ARAPObjectContract.Organization
		|				AND NOT ARAPObjectContract.OnlyBalance
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectOrder
		|			ON &ARAPObjectOfOrder = ARAPObjectOrder.Ref
		|				AND NOT ARAPObjectOrder.OnlyBalance
		|WHERE
		|	IncreasingDeliveryPlan.IncreaseToAdmission <> 0
		|";
	
	QueryText = StrReplace(QueryText,"&Period",               Period);
	QueryText = StrReplace(QueryText,"&ExceedingOrder",          ExceedingOrder);
	QueryText = StrReplace(QueryText,"&InvoiceForOrders",   InvoiceForOrders);
	QueryText = StrReplace(QueryText,"&PurchaseOrder_",         PurchaseOrder_);
	QueryText = StrReplace(QueryText,"&ARAPObjectOfOrder", ARAPObjectOfOrder);
	
	Return QueryText;
	
EndFunction

#EndRegion