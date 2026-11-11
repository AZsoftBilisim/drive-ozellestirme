#Region Public

#Region GettingVATAccountingSettingsAndParameters

// Returns a list of tax types for sales and/or purchases that are available in the configuration.
//
//Parameters:
// Sales- Boolean
// Purchases - Boolean
// SeparateAccounting - Boolean
// Returns:
// 	ValueList of EnumRef.VATTaxationTypes
//
Function ApplicableTypesOfVATTaxation(Sales = True, Purchases = True, SeparateAccounting = False) Export
	
	Return VATAccountingERPServerCall.ApplicableTypesOfVATTaxation(Sales, Purchases, SeparateAccounting);
	
EndFunction

// Returns a list of types of VAT taxation for which the documents hide the details of the VAT rate and amount
//
// Returns:
// 	Array of EnumRef.VATTaxationTypes - Types of VAT taxation
//
Function TypesOfTaxationThatHideVATDetails(NameOfVATRateField = "") Export
	
	Result = New Array;
	Result.Add(PredefinedValue("Enum.VATTaxationTypes.EmptyRef"));
	Result.Add(PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT"));
	Result.Add(PredefinedValue("Enum.VATTaxationTypes.VATReverseCharge"));
	VATAccountingClientServerLocalization.AddTaxTypesThatHideVATDetails(Result, NameOfVATRateField);
	
	Return Result;
	
EndFunction

#EndRegion

#Region VATRates

// The function returns the percentage of the VAT rate.
//
// Parameters:
//  VATRate - CatalogRef.VATRates - VAT rate.
//
// Returns:
//	Number - The percentage of the VAT rate.
//
Function ValueOfVATRate(VATRate) Export
	
	Return VATAccountingERPInternalClientServerCached.ValueOfVATRate(VATRate);
	
EndFunction

// Calculates the VAT amount based on the amount and tax flags.
//
// Parameters:
//  Sum            - Number - the amount from which taxes should be calculated;
//  VATRate        - Number, CatalogRef.VATRates - Value or reference to the VAT rate.
//  AmountIncludesVAT - Boolean - whether VAT is included in the amount ("inside" or " above");
//  VATTaxation - EnumRef.VATTaxationTypes - document taxation
//
// Returns:
//  Number - the amount of VAT received.
//
Function CalculateVATAmount(Sum, VATRate, AmountIncludesVAT = True, VATTaxation = Undefined) Export
	
	TypesOfTaxation = TypesOfTaxationThatHideVATDetails();
	If ValueIsFilled(VATTaxation) And TypesOfTaxation.Find(VATTaxation) <> Undefined Then
		Return 0;
	EndIf;
	
	If TypeOf(VATRate) = Type("CatalogRef.VATRates") Then
		ValueOfVATRate = ValueOfVATRate(VATRate);
	Else
		ValueOfVATRate = VATRate; 
	EndIf;
	
	VATAmount = VATAccountingClientServerLocalization.CalculateVATAmount(Sum, VATRate, AmountIncludesVAT, VATTaxation);
	
	If VATAmount = Undefined Then
		If AmountIncludesVAT Then
			VATAmount = Round(Sum - 100 * Sum / (100 + ValueOfVATRate), 2, RoundMode.Round15as20);
		Else
			VATAmount = Round(Sum * ValueOfVATRate / 100, 2, RoundMode.Round15as20);
		EndIf;
	EndIf;
	
	Return VATAmount;

EndFunction

#EndRegion

#Region AccountingForIncomingVAT

#Region FillingInVATTaxationForPurchases

// Returns the structure of the parameters for filling in the VAT tax for the purchase of goods or the return of goods to the supplier.
//
// Returns: 
// 	Structure - The fill parameters:
//		* Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Counterparty or supplier organization.
//		* Contract - CatalogRef.CounterpartyContracts, 
//					Reference link.agreements between organizations - a Contract under which a purchase or refund is carried out. 
// 	Operation parameters.
// 		* PurchaseOfGoods - Boolean - The document reflects the purchase of goods or transactions related to the purchase:
//		                                 , the receipt of goods, the acceptance of goods for storage for subsequent redemption, the act of divergence during acceptance.
// 		* AcquisitionOfWorks - Boolean - The document reflects the acquisition of works.
// 		* PurchaseOnArticles - Boolean - The document reflects the acquisition of valuables that relate to items of other expenses or other assets.
// 		* RedemptionOfReturnablePackagingFromVendor - Boolean - The document reflects the repurchase of returnable containers accepted from the supplier.
//		* ConsignmentProcurement - Boolean - Indicates that the product is accepted for commission.
//		* ImportOfGoods - Boolean - A sign that the purchased goods are imported from another country, with the passage of the customs procedure.
//		* RentalService - Boolean - A sign that rental services are reflected.
//		* ImportOfGoodsFromCustomsUnion - Boolean - A sign that the goods are imported from the countries of the Customs Union. In this case, an import application is issued.
//		* PurchaseViaAdvanceHolder - Boolean - An indication that the document reflects acquisition transactions through an accountable person.
//		* ReturnOfGoodsToVendor - Boolean - Indicates that the document reflects the return of goods to the supplier.
//		* ReturnOfGoodsToConsignor - Boolean - Indicates that the document reflects the return of goods to the committee.
//		* ReceiptOfGoodsInTransit - Boolean - An indication that the document reflects the receipt of goods to the warehouse for which the purchase was previously reflected.
//		
//	    * ThisIsOperationBetweenOrganizations - Boolean - True if an operation between own organizations (intercampany) is reflected.
//	                           This parameter is specified to specify the operation parameters (for example, together with the Return goods to the supplier parameter).
//	                           
//	    * RentalServiceTaxAgent - Boolean - A sign that rental services are reflected with the option of taxing "VAT Tax Agent".
//
Function ParametersForFillingInVATTaxationPurchases() Export
	
	FillParameters = New Structure;
	FillParameters.Insert("Counterparty");
	FillParameters.Insert("Contract");
	
	// Parameters of the reflected operation
	FillParameters.Insert("PurchaseOfGoods",            False);
	FillParameters.Insert("AcquisitionOfWorks",              False);
	FillParameters.Insert("PurchaseOnArticles",           False);
	FillParameters.Insert("RedemptionOfReturnablePackagingFromVendor", False);
	FillParameters.Insert("ConsignmentProcurement",                False);
	FillParameters.Insert("ImportOfGoods",                  False);
	FillParameters.Insert("RentalService",                 False);
	FillParameters.Insert("ImportOfGoodsFromCustomsUnion",  False);
	FillParameters.Insert("PurchaseViaAdvanceHolder",    False);
	FillParameters.Insert("ReturnOfGoodsToVendor",       False);
	FillParameters.Insert("ReturnOfGoodsToConsignor",        False);
	FillParameters.Insert("ReceiptOfGoodsInTransit",      False);
	FillParameters.Insert("ReceiptFromProcessing",       False);
	FillParameters.Insert("VMIProcurement",                False); 
	FillParameters.Insert("ThisIsOperationBetweenOrganizations",  False);
	FillParameters.Insert("RentalServiceTaxAgent",   False); 
	
	FillParameters.Insert("Period",                         Date(1,1,1));
	
	Return FillParameters;
	
EndFunction

// Determines whether VAT should be displayed in the purchase document totals 
// 
// Parameters:
// 	VATTaxation - EnumRef.VATTaxationTypes - taxation of the purchase document
// 
// Returns:
// 	Boolean - True if subject to VAT
//
Function DisplayNDSInResultsOfProcurementDocument(VATTaxation) Export
	
	TypesOfTaxationThatHideVATDetails = TypesOfTaxationThatHideVATDetails();
	Return (TypesOfTaxationThatHideVATDetails.Find(VATTaxation) = Undefined);
	
EndFunction

#Region BatchProcessingOfTablePart

// Parameters for the action "Fill in the tax charge for the purchase" batch processing of the tabular part.
// 
// Returns:
//  Structure - Parameters of batch filling in the taxation of personal income tax purchases:
// * Document - DocumentRef - in which the filling is performed.
// * Date - Date - Document date
Function ParametersOfBatchFillingInOfTaxationVATPurchases() Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Document");
	ReturnValue.Insert("Date", '00010101');
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndRegion

#Region FillingInVATActivityType

// Returns the structure of parameters for filling in the separate VAT accounting activity type.
//
// Returns:
// 	Structure - Structure of parameters with keys:
// 		* Organization - CatalogRef.Companies - Organization of the document.
// 		* Date - Date - Document date
// 		* Warehouse - CatalogRef.Warehouses - Warehouse-recipient of goods (optional). If there are several recipients, but it is not filled in.
// 		* Contract - CatalogRef.CounterpartyContracts, 
// 		            Reference link.agreements between organizations - Contract with the supplier (optional). 
// 		                                                          It is indicated if the purchase of valuables is reflected.
// 		* LineOfBusiness - CatalogRef.LinesOfBusiness - The field of activity is the recipient of values (optional).
// 		* Department - CatalogRef.BusinessStructure - Document subdivision.
// 		Document operations.
// 		* PurchaseOfGoods - Boolean - The document reflects the purchase of goods or transactions related to the purchase:
//		                                 , the receipt of goods, the act of divergence, the adjustment of the purchase of goods.
// 		* AcquisitionOfWorks - Boolean - The document reflects the acquisition of works.
// 		* PurchaseOnArticles - Boolean - The document reflects the acquisition of valuables that, at the time of acquisition, are attributed to items of other expenses or other assets.
// 		* MovementOfGoodsInWarehouses - Boolean - The document reflects the movement (movement) of goods within the warehouse contour.
// 		* MovementOfGoodsAndWorksInProduction - Boolean - The document reflects the transfer of goods to production, the movement of goods and works within the production loop. 
// 		* WriteOffOfGoodsAndWorksForItems - Boolean - The document reflects the write-off of goods and works on items of expenses or other assets.
// 		* TransferToOperation - Boolean - The document reflects the transfer of materials into operation.
// 		* AssemblyDisassemblyOfGoods - Boolean - The document reflects the assembly or disassembly of goods.
// 		* OutputOfProductsAndWorks - Boolean - The document reflects the output of products (semi-finished products) or works (creating value on your own).
// 		* OtherDisposalOfGoods - Boolean - The document reflects damage, write-off of shortages or re-sorting of goods.
// 		* LeasingPropertyOnBalanceSheet - Boolean - The document reflects the receipt of leasing services for property on the balance sheet of the lessee.
// 		* AdjustmentOfVATActivity - Boolean - The document reflects the change in the type of VAT activity without real movement of goods.
// 		* ExpenseReport - Boolean - Despite the fact that the advance report reflects the purchase, a separate parameter is used for it,
// 		                             because the document is not included in the circuit of automated separate VAT accounting.
Function ParametersForFillingInVATActivityType() Export
	
	FillParameters = New Structure();
	
	// The details of the document
	FillParameters.Insert("Organization",             Undefined);
	FillParameters.Insert("Date",                    '00010101');
	FillParameters.Insert("Warehouse",                   Undefined);
	FillParameters.Insert("Contract",                 Undefined);
	FillParameters.Insert("LineOfBusiness", Undefined);
	FillParameters.Insert("Department",           Undefined);
	
	// Operation parameters
	FillParameters.Insert("PurchaseOfGoods",                False);
	FillParameters.Insert("AcquisitionOfWorks",                  False);
	FillParameters.Insert("PurchaseOnArticles",               False);
	FillParameters.Insert("MovementOfGoodsInWarehouses",           False);
	FillParameters.Insert("MovementBetweenBranches",             False);
	FillParameters.Insert("MovementOfGoodsAndWorksInProduction", False);
	FillParameters.Insert("WriteOffOfGoodsAndWorksForItems",      False);
	FillParameters.Insert("TransferToOperation",              False);
	FillParameters.Insert("AssemblyDisassemblyOfGoods",              False);
	FillParameters.Insert("OutputOfProductsAndWorks",              False);
	FillParameters.Insert("OtherDisposalOfGoods",               False);
	FillParameters.Insert("LeasingPropertyOnBalanceSheet",       False);
	FillParameters.Insert("AdjustmentOfVATActivity",   False);
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region RegistrationOfInvoicesReceived

// Returns the structure of parameters for registering invoices based on purchase documents or returning goods from the customer.
//
// Returns:
// 	Structure - Structure of parameters with keys:
// 	     * Ref - DocumentRef - Link to the purchase document.
// 	     * Organization - CatalogRef.Companies - The organization that records the purchase or return of goods.
// 	     * Counterparty - CatalogRef.Counterparties,
// 	                    Reference link.Organizations - Counterparty or supplier organization.
// 	                                                   The buyer of the goods upon return.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - taxation of VAT of the purchasing document or refund.
// 	    Operation parameters.
// 	     * PurchaseOfGoodsWorksServices - Boolean - A sign that the purchase of goods, works, services 
// 	                                       or other valuables from a supplier (commission agent, processor) on the domestic market is reflected.
// 	     * ConsignmentProcurement - Boolean - Indicates that the operation of accepting goods for a commission is reflected.
// 	     * ImportOfGoods - Boolean - A sign that the import operation is reflected with the passage of the customs procedure.
// 	     * ImportOfGoodsFromCustomsUnion - Boolean - A sign that the operation of importing goods from the countries of the customs Union with the registration of an import application is reflected.
// 	     * PurchaseViaAdvanceHolder - Boolean - Indicates that the document reflects a purchase transaction through an accountable person.
// 	     * OtherVATConfirmationDocument - Boolean - indicates that another document confirming the payment of vat amounts to the budget has been received (ticket, Cash register receipt, etc.).
// 	     * ReturnOfGoodsFromVATPayer - Boolean - Indicates that the document reflects the return of goods from the VAT payer.
// 	                                                 In this case, the client is expected to receive an invoice.
// 	     * ReturnOfGoodsFromVATDefaulter - Boolean - Indicates that the document reflects the return of goods from the non-payer of VAT.
// 	                                                 In this case, receipt of the invoice from the customer is not expected.
// 	     * ErrorCorrection - Boolean - Indicates that the document reflects the correction of errors in the purchase document.
// 	     * AdjustmentUnderApprovalOfParties - Boolean - A sign that the document reflects the adjustment of the acquisition by agreement of the parties.
// 	     * OtherVATConfirmationDocument - Boolean - indicates that another document confirming the payment of vat amounts to the budget has been received (ticket, Cash register receipt, etc.).
//
Function ParametersForRegisteringInvoicesReceived() Export
	
	RegistrationParameters = New Structure();
	RegistrationParameters.Insert("Ref");
	RegistrationParameters.Insert("Date", '00010101');
	RegistrationParameters.Insert("Organization");
	RegistrationParameters.Insert("Counterparty");
	RegistrationParameters.Insert("VATTaxation");
	
	RegistrationParameters.Insert("PurchaseOfGoodsWorksServices",     False);
	RegistrationParameters.Insert("ConsignmentProcurement",                   False);
	RegistrationParameters.Insert("ImportOfGoods",                     False);
	RegistrationParameters.Insert("ImportOfGoodsFromCustomsUnion",     False);
	RegistrationParameters.Insert("PurchaseViaAdvanceHolder",       False);
	RegistrationParameters.Insert("OtherVATConfirmationDocument",      False);
	RegistrationParameters.Insert("ReturnOfGoodsFromVATPayer",    False);
	RegistrationParameters.Insert("ReturnOfGoodsFromVATDefaulter",  False);
	RegistrationParameters.Insert("ErrorCorrection",                 False);
	RegistrationParameters.Insert("AdjustmentUnderApprovalOfParties", False);
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#Region RegisteringManualPurchaseBookEntries

// Returns the structure of parameters for registering purchase book entries based on the document.
//
// Returns:
// 	Structure - structure with keys:
// 	         * Ref - DocumentRef - Link to the Foundation document.
// 	         * Organization - CatalogRef.Companies - The organization in which the record should be reflected.
// 	         * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Supplier of values.
//
Function ParametersForRegisteringPurchaseBookEntries() Export
	
	RegistrationParameters = New Structure;
	RegistrationParameters.Insert("Ref");
	RegistrationParameters.Insert("Organization");
	RegistrationParameters.Insert("Counterparty");
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region AccountingForOutgoingVAT

#Region FillingInSalesVATTaxation

// Returns the structure of parameters for filling in VAT taxation for sales or returns of goods from the buyer.
//
// Returns:
// 	Structure - The fill parameters:
// 	     * Organization - CatalogRef.Companies - Organization of the document.
// 	     * Date - Date - document date.
// 	     * Contract - CatalogRef.CounterpartyContracts,
// 	                 Referenceslink.Agreements between organizations - An agreement with the buyer.
// 	     * LineOfBusiness - CatalogRef.LinesOfBusiness - The line of activity within which the sale is carried out.
// 	                                                                            If the goods are returned to the supplier, it is not filled in.
// 	     * Department - CatalogRef.BusinessStructure - Document subdivision.
// 	    Operation parameters.
// 	     * GoodsSales - Boolean- A sign that the document reflects the sale or return of goods, works or services directly to the client or his own organization.
// 	     * ImplementationOfWorksServices - Boolean - A sign that the document reflects the sale of goods, works or services directly to the client or his own organization.
// 	     * OtherAssetSale - Boolean - A sign that the document reflects the sale of other services (without nomenclature) or other assets.
// 	     * ReturnablePackagingRedemptionByCustomer - Boolean - The document reflects the customer's purchase of previously transferred returnable containers.
// 	     * RedemptionOfGoodsByCustodian - Boolean - The document reflects the redemption of goods that were previously deposited with the right to sell.
// 	     * TransferToCommissionAgent - Boolean - A sign that the document reflects the transfer of goods to the commission.
// 	     * ReportToMaterialProvider - Boolean -A sign that the document reflects the implementation of services for the processing of tolling materials.
// 	     * ConsignmentReportFromCustomer - Boolean -A sign that the document reflects the fact that the goods are sold by a commission agent.
// 	     * Retail_ - Boolean - A sign that the document reflects the retail sale or return of goods sold at retail.
// 	     * ReturnOfGoodsFromCustomer - Boolean - A sign that the return of goods from the customer is reflected.
// 	     * ReturnOfGoodsFromCommissionAgent - Boolean - A sign that the return of the commission agent is being reflected.
// 	     * PurchasingReportToConsignorPrincipal - Boolean - A sign that the document reflects the report to the committee on the purchase.
// 	     
// 	     * ThisIsOrder - Boolean - True if the taxation is filled in in the Customer's Order or the Giver's Order.
// 	                           The parameter is specified for refinement to the operation parameters. 
// 	                           For example, together with the parameters of the implementation of work services and the implementation of goods.
// 	     * ThisIsOperationBetweenOrganizations - Boolean - True if the operation between own organizations (intercampany) is reflected.
// 	                           The parameter is specified for refinement to the operation parameters. 
// 	                           For example, together with the parameters of the implementation of work services and the implementation of goods.                       
//
Function ParametersForFillingInSalesVATTaxation() Export
	
	FillParameters = New Structure;
	FillParameters.Insert("Organization");
	FillParameters.Insert("Date");
	FillParameters.Insert("Warehouse");
	FillParameters.Insert("Contract");
	FillParameters.Insert("LineOfBusiness");
	FillParameters.Insert("Department");
	
	FillParameters.Insert("GoodsSales", False);
	FillParameters.Insert("ImplementationOfWorksServices", False);
	FillParameters.Insert("OtherAssetSale", False);
	FillParameters.Insert("ReturnablePackagingRedemptionByCustomer", False);
	FillParameters.Insert("RedemptionOfGoodsByCustodian", False);
	FillParameters.Insert("TransferToCommissionAgent", False);
	FillParameters.Insert("ReportToMaterialProvider", False);
	FillParameters.Insert("ConsignmentReportFromCustomer", False);
	FillParameters.Insert("ReturnOfGoodsFromCustomer", False);
	FillParameters.Insert("ReturnOfGoodsFromCommissionAgent", False);
	FillParameters.Insert("PurchasingReportToConsignorPrincipal", False);
	FillParameters.Insert("TransferToStorage", False);
	FillParameters.Insert("ReturnFromStorage", False);
	
	FillParameters.Insert("Retail_", False);
	
	FillParameters.Insert("ThisIsOrder", False);
	FillParameters.Insert("ThisIsOperationBetweenOrganizations", False);
	
	Return FillParameters;
	
EndFunction

// Determines whether VAT should be displayed in the sales document totals 
// 
// Parameters:
// 	VATTaxation - EnumRef.VATTaxationTypes - taxation of the sales document
// Returns:
// 	Boolean - True if subject to VAT
//
Function DisplayNDSInResultsOfSalesDocument(VATTaxation) Export
	
	TypesOfTaxationThatHideVATDetails = TypesOfTaxationThatHideVATDetails();
	Return (TypesOfTaxationThatHideVATDetails.Find(VATTaxation) = Undefined);
	
EndFunction

#EndRegion


#Region FormationOfInvoicesIssued

// Returns the structure of parameters for registering invoices based on documents for the sale or return of goods to the supplier.
//
// Returns:
// 	Structure - Structure of parameters with keys:
// 	     * Ref - DocumentRef - Link to the sales document.
// 	     * Organization - CatalogRef.Companies - The organization in which the sale or return of goods is reflected.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Counterparty or organization buyer.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - taxation of VAT of the sale or refund document.
// 	   Operation parameters.
// 	     * GoodsSales - Boolean - A sign that the document reflects the sale of goods.
// 	     * ImplementationOfWorksServices - Boolean - A sign that the document reflects the implementation of works or services.
// 	     * OtherAssetSale - Boolean - A sign that the document reflects the sale of other assets, for example, OS.
// 	     * TransferToCommissionAgent  - Boolean - A sign that the transfer of goods to the commission operation is reflected.
// 	     * ReturnOfGoodsToVendor  - Boolean - Indicates that the operation of returning goods to the supplier is reflected.
// 	     * ErrorCorrection - Boolean - A sign that the document reflects the correction of errors in the implementation or other VAT accrual.
// 	     * AdjustmentUnderApprovalOfParties - Boolean - A sign that the document reflects the adjustment of the implementation by agreement of the parties.
// 	     * OtherVATAccrual - Boolean - A sign that the document reflects other VAT accrual.
// 	     * SalesViaCommissionAgent - Boolean - Indicates that the transaction is reflected by the commission version 2.5.
//
Function ParametersForRegisteringInvoicesIssued() Export
	
	RegistrationParameters = New Structure();
	RegistrationParameters.Insert("Ref");
	RegistrationParameters.Insert("Date", '00010101');
	RegistrationParameters.Insert("Organization");
	RegistrationParameters.Insert("Counterparty");
	RegistrationParameters.Insert("VATTaxation");
	
	RegistrationParameters.Insert("GoodsSales", False);
	RegistrationParameters.Insert("ImplementationOfWorksServices", False);
	RegistrationParameters.Insert("OtherAssetSale", False);
	RegistrationParameters.Insert("TransferToCommissionAgent", False);
	RegistrationParameters.Insert("ReturnOfGoodsToVendor", False);
	RegistrationParameters.Insert("ErrorCorrection", False);
	RegistrationParameters.Insert("AdjustmentUnderApprovalOfParties", False);
	RegistrationParameters.Insert("OtherVATAccrual", False);
	RegistrationParameters.Insert("SalesViaCommissionAgent", False);
	RegistrationParameters.Insert("VATAccrualUponShipment", False);
	RegistrationParameters.Insert("TransferOfTitleToGoods", False);
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#Region FormationOfInvoicesToCommissionAgent
	
// Returns the structure of invoice registration parameters based on the Commission agent's report.
//
// Returns:
// 	Structure - Structure of parameters with keys:
// 	     * Ref - DocumentRef - Link to the commission agent's report.
// 	     * Organization - CatalogRef.Companies - The organization in which the commission agent's report is reflected.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Commission agent.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the commission agent's report.
// 	     * SalesViaCommissionAgent - Boolean -Indicates that the transaction is reflected by the commission version 2.5.
// 	     * GoodsSales - Boolean - A sign that the document reflects the sale of goods.
// 	     * ImplementationOfWorksServices - Boolean -A sign that the document reflects the implementation of works or services.
//
Function ParametersForRegisteringInvoicesToCommissionAgent() Export
	
	RegistrationParameters = New Structure();
	RegistrationParameters.Insert("Ref");
	RegistrationParameters.Insert("Organization");
	RegistrationParameters.Insert("Counterparty");
	RegistrationParameters.Insert("VATTaxation");
	RegistrationParameters.Insert("Date");
	RegistrationParameters.Insert("SalesViaCommissionAgent", False);
	RegistrationParameters.Insert("GoodsSales");
	RegistrationParameters.Insert("ImplementationOfWorksServices");
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion
