#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document that you want to get the data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableProductsRelease(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
			DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		AddTextsToReflectSettlements(Query, QueryTexts, Registers);
		
		ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion


#Region Assignments


#EndRegion

#Region CostShares

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of cost allocation.
//
// Returns:
//  See ProductionClientServer.CostAllocationParametersForOutputProducts
//
Function CostAllocationParameters(Object) Export
	
	CostAllocationParameters = ProductionClientServer.CostAllocationParametersForOutputProducts("Goods", Object.CostsAllocationMethod);
	
	CostAllocationParameters.CalculateShareCostPercentageField = True;
	CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors = True;
	CostAllocationParameters.CalculateShareOfCostAttributeRequired = True;
	
	CostAllocationParameters.ParametersForFillingInCostShares.Date =
		?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Date"),
			Object.Date,
			Date("00010101"));
	
	CostAllocationParameters.ParametersForFillingInCostShares.Currency =
		?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Currency"),
			Object.Currency,
			Catalogs.Currencies.EmptyRef());
	
	CostAllocationParameters.CostGroupingField = "ProductionLot";
	CostAllocationParameters.CostGroupingPresentationField = "ProductionLot";
	
	Return CostAllocationParameters;
	
EndFunction

#EndRegion

#Region ArticleSelectionAndAnalytics

// Returns the parameters of the selection of articles and analyst.
//
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Goods";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("GoodsAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

#Region VATAccounting

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany, DocumentObject.ConsumptionReportSubcontractingServicesDeliveredIntercompany - The document is a report to the giver between organizations.
//
// Returns:
//	See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInVATTaxation_(Document) Export
	
	DocumentAttributes = "Date, Organization, Contract, LineOfBusiness";
	DocumentAttributes = New Structure(DocumentAttributes);
	
	If TypeOf(Document) = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillPropertyValues(FillParameters, DocumentAttributes, "Date, Contract, LineOfBusiness");
	
	FillParameters.Organization                   = DocumentAttributes.Organization;
	FillParameters.ReportToMaterialProvider                 = True;
	FillParameters.ThisIsOperationBetweenOrganizations = True;
	
	Return FillParameters;
	
EndFunction

// Returns the parameters to register the issued invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany, DocumentObject.ConsumptionReportSubcontractingServicesDeliveredIntercompany - The document is a report to the giver between organizations.
//
// Returns:
//	See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Document) Export
	
	DocumentAttributes = "Ref, Date, Organization, MaterialProvider, VATTaxation";
	DocumentAttributes = New Structure(DocumentAttributes);
	
	If TypeOf(Document) = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Date, VATTaxation");
	
	RegistrationParameters.Organization = DocumentAttributes.Organization;
	RegistrationParameters.Counterparty  = DocumentAttributes.MaterialProvider;
	
	RegistrationParameters.ImplementationOfWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#Region ARAPAccounting

// This function defines the document details.
//
// Parameters:
//  DocumentRef - DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date                    AS Date,
	|	DocumentData.MaterialProvider                 AS Organization,
	|	DocumentData.Organization             AS SenderOrganization,
	|	DocumentData.MaterialProvider                 AS CompanyRecipient,
	|	DocumentData.ARAPCurrency    AS ARAPCurrency,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	CASE
	|		WHEN DocumentData.Posted
	|			THEN DocumentData.AmountARAP
	|		ELSE 0
	|	END                                   AS AmountARAP,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.CourseNumerator           AS Rate,
	|	DocumentData.CourseDenominator         AS Repetition,
	|	DocumentData.ARAPObjectSettings         AS ARAPObjectSettings
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	AttributesStructure1 = New Structure;
	
	Result = Query.Execute();
	For Each Column In Result.Columns Do
		AttributesStructure1.Insert(Column.Name, Column.ValueType.AdjustValue(Undefined));
	EndDo;
	
	Attributes = Result.Select();
	If Attributes.Next() Then
		FillPropertyValues(AttributesStructure1, Attributes);
	EndIf;
	
	Return AttributesStructure1;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject.ConsumptionReportSubcontractingServicesDeliveredIntercompany, DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany, Structure, FormDataStructure -
// 		An object or collection for calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	SettlementParameters = New Array();
	
	// Array of parameters - separately for shipment and acceptance
	// Shipment (Processing organization):
	
	#Region Shipment
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.ThisIsSalePurchase = True;
	
	// Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	// They are used to generate calculation and analytics objects.
	ParametersStructure.Organization = "Object.Organization";
	ParametersStructure.Partner     = Catalogs.Partners.OurEnterprise;
	ParametersStructure.Counterparty  = "Object.MaterialProvider";
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.Contract         = "Object.Contract";
	ParametersStructure.ARAPObjectSettings = "Object.ARAPObjectSettings";
	
	// Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency            = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP             = "Object.AmountARAP";
	ParametersStructure.PathToTSData                   = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption = "Object.ARAPDetailsWithCustomer";
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                = "";
	ParametersStructure.CashAccount                     = "";
	ParametersStructure.CompanyBankAccount = "Object.SubcontractorAccount";
	ParametersStructure.CounterpartyBankAccount = "Object.MaterialProviderAccount";
	
	// They are used to determine the value of payments in the currency and in the form of editing payment rules.
	// The details for the object of calculations are used in conducting.
	ParametersStructure.Manager                        = "Object.EmployeeResponsible";
	ParametersStructure.ARAPObject                  = "Object.ARAPObject";
	ParametersStructure.FinancialAccountingGroup          = "Object.SubcontractorFinancialAccountingGroup";
		
	ParametersStructure.FormItems.FinancialAccountingGroup  = "SubcontractorFinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	// The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement           = "SetOffOfPaymentFormOfProcessor";
	ParametersStructure.FormItems.AmountOfTSSettlements = "GoodsAmountARAP";
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	ParametersStructure.CourseNumerator   = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator = "Object.CourseDenominator";
	
	// The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies  = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages   = "DecorationPaymentMilestonesOfProcessor";
	ParametersStructure.PaymentStepsText           = "Form.InscriptionPaymentMilestonesOfProcessor";
	ParametersStructure.FormItems.InscriptionCalculations = "DecorationStateOfProcessorSCalculations";
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	// Function Payment stages and payment date
	ParametersStructure.PaymentDate = "Object.PaymentDate";
	#EndRegion
	
	SettlementParameters.Add(ParametersStructure);
	
	#EndRegion
	
	#Region Receiving
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.ThisIsSalePurchase = True;
	
	// Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	// They are used to generate calculation and analytics objects.
	ParametersStructure.Organization = "Object.MaterialProvider";
	ParametersStructure.Partner     = Catalogs.Partners.OurEnterprise;
	ParametersStructure.Counterparty  = "Object.Organization";
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.Contract         = "Object.Contract";
	ParametersStructure.ARAPObjectSettings = "Object.ARAPObjectSettings";
	
	// Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency            = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP             = "Object.AmountARAP";
	ParametersStructure.PathToTSData                   = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption = "Object.ARAPDetailsWithVendor";
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                = "";
	ParametersStructure.CashAccount                     = "";
	ParametersStructure.CompanyBankAccount = "Object.MaterialProviderAccount";
	ParametersStructure.CounterpartyBankAccount = "Object.SubcontractorAccount";
	
	// The details for the object of calculations are used in conducting.
	ParametersStructure.Manager                        = "Object.EmployeeResponsible";
	ParametersStructure.ARAPObject                  = "Object.ARAPObjectOfRecipient";
	ParametersStructure.FinancialAccountingGroup          = "Object.MaterialProviderFinancialAccountingGroup";
	
	ParametersStructure.FormItems.FinancialAccountingGroup  = "MaterialProviderFinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	// The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement           = "PaymentOffsetFormOfGiver";
	ParametersStructure.FormItems.AmountOfTSSettlements = "GoodsAmountARAP";
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument

	ParametersStructure.CourseNumerator   = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator = "Object.CourseDenominator";
	
	// The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies  = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages   = "DecorationPaymentMilestonesOfGiver";
	ParametersStructure.PaymentStepsText           = "Form.InscriptionPaymentMilestonesOfGiver";
	ParametersStructure.FormItems.InscriptionCalculations = "DecorationStateOfGiverSCalculations";
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	// Function Payment stages and payment date
	ParametersStructure.PaymentDate = "Object.PaymentDate";
	#EndRegion
	
	SettlementParameters.Add(ParametersStructure);
	
	#EndRegion
	
	Return SettlementParameters;
	
EndFunction

#Region State

// Calculates the current status of the report to the giver on the recipient's side.
//
// Parameters:
//	ReportToMaterialProvider     - DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany - Document whose state needs to be calculated
//	Contract           - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations - ClientApplicationForm - The form in which the calculated state will be placed.
//
Procedure CalculateRecipientState(Val ReportToMaterialProvider, Val Contract, StateOfCalculations) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfSettlementStatusRecipient());
	
	If ValueIsFilled(ReportToMaterialProvider) And AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting) Then
		
		SetPrivilegedMode(True);
		Query = New Query(
		"SELECT
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS PaymentAmountRecipient,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) * 100 / VendorsARAPAccountingBalance.AmountDueExpense AS NUMBER(15, 0))
		|		ELSE 0
		|	END AS PaymentPercentageRecipient,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|				AND ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) < 0
		|			THEN CAST(-ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS AmountOfOverduePaymentRecipient,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0)
		|		ELSE 0
		|	END AS OrderReceiptAmount,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		|		ELSE 0
		|	END AS PercentageOfOrderReceipt,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.Posted
		|				AND (ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|					OR DocumentReportToMaterialProvider.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS AmountOfDebtRecipient,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN CASE
		|					WHEN ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) > 0
		|						THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		|					ELSE CAST(ISNULL(-VendorsARAPAccountingBalance.SumClosingBalance, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		|				END
		|		ELSE 0
		|	END AS PercentageOfDebtRecipient,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.Posted
		|				AND DocumentReportToMaterialProvider.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|			THEN -VendorsARAPAccountingBalance.AmountDueClosingBalance
		|		ELSE 0
		|	END AS AmountPayableRecipient
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentReportToMaterialProvider
		|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(, , , , ARAPObject = &ARAPObject) AS VendorsARAPAccountingBalance
		|		ON (TRUE)
		|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Balance(ENDOFPERIOD(&CurrentDate, DAY), ARAPObject = &ARAPObject) AS SettlementsWithSuppliersBalancesAsOfDate
		|		ON (TRUE)
		|WHERE
		|	DocumentReportToMaterialProvider.Ref = &ReportToMaterialProvider
		|");
		
		ARAPObject = Common.ObjectAttributeValue(ReportToMaterialProvider, "ARAPObjectOfRecipient");
		
		Query.SetParameter("ReportToMaterialProvider", ReportToMaterialProvider);
		Query.SetParameter("ARAPObject", ARAPObject);
		Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

// Calculates the current status of the report to the giver on the sender's side.
//
// Parameters:
//	ReportToMaterialProvider     - DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany - Document whose state needs to be calculated
//	Contract           - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations - ClientApplicationForm - The form in which the calculated state will be placed.
//
Procedure CalculateSenderState(Val ReportToMaterialProvider, Val Contract, StateOfCalculations) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfSettlementStatusSender());
	
	If ValueIsFilled(ReportToMaterialProvider) And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		
		SetPrivilegedMode(True);
		Query = New Query(
		"SELECT
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND DocumentReportToMaterialProvider.AmountARAP > 0
		|			THEN ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0)
		|		ELSE 0
		|	END AS PaymentAmountSender,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND DocumentReportToMaterialProvider.AmountARAP > 0
		|			THEN CAST(ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0) * 100 / DocumentReportToMaterialProvider.AmountARAP AS NUMBER(15, 0))
		|		ELSE 0
		|	END AS PaymentPercentageSender,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND DocumentReportToMaterialProvider.AmountARAP > 0
		|			THEN CAST(ISNULL(SettlementsWithCustomersBalancesAsOfDateOfRelevance.AmountDueBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS AmountOfOverduePaymentSender,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND DocumentReportToMaterialProvider.AmountARAP > 0
		|			THEN ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0)
		|		ELSE 0
		|	END AS AmountByShipment,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND DocumentReportToMaterialProvider.AmountARAP > 0
		|			THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0) * 100 / DocumentReportToMaterialProvider.AmountARAP AS NUMBER(15, 0))
		|		ELSE 0
		|	END AS OrderShipmentPercentage,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.Posted
		|				AND (DocumentReportToMaterialProvider.AmountARAP > 0
		|					OR DocumentReportToMaterialProvider.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		|			THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS AmountOwedSender,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportToMaterialProvider.Posted
		|				AND DocumentReportToMaterialProvider.AmountARAP > 0
		|			THEN CASE
		|					WHEN ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) > 0
		|						THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) * 100 / DocumentReportToMaterialProvider.AmountARAP AS NUMBER(15, 0))
		|					ELSE CAST(ISNULL(-CustomersARAPAccountingBalance.SumClosingBalance, 0) * 100 / DocumentReportToMaterialProvider.AmountARAP AS NUMBER(15, 0))
		|				END
		|		ELSE 0
		|	END AS PercentageOfDebtSender,
		|	CASE
		|		WHEN DocumentReportToMaterialProvider.Posted
		|				AND DocumentReportToMaterialProvider.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|			THEN CustomersARAPAccountingBalance.AmountDueClosingBalance
		|		ELSE 0
		|	END AS AmountPayableSender
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentReportToMaterialProvider
		|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(, , , , ARAPObject = &ARAPObject) AS CustomersARAPAccountingBalance
		|		ON (TRUE)
		|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(ENDOFPERIOD(&CurrentDate, DAY), ARAPObject = &ARAPObject) AS SettlementsWithCustomersBalancesAsOfDateOfRelevance
		|		ON (TRUE)
		|WHERE
		|	DocumentReportToMaterialProvider.Ref = &ReportToMaterialProvider");
		
		ARAPObject = Common.ObjectAttributeValue(ReportToMaterialProvider, "ARAPObject");
		
		Query.SetParameter("ReportToMaterialProvider", ReportToMaterialProvider);
		Query.SetParameter("ARAPObject", ARAPObject); 
		Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region GLAccountSettings

// Returns parameters for setting up accounting accounts in the document.
//  
// Returns:
//  See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	SettingsParameters = GLAccountSettingsServer.SetupParameters();
	SettingsParameters.AvailabilityByOperation = True;
	SettingsParameters.Organization           = "Object.Organization";
	SettingsParameters.ArticleType             = "ArticleType";
	SettingsParameters.DataPath           = "Object.Goods";
	SettingsParameters.AssetAndLiabilityItem = "ExpenseItem";
	
	SettingsParameters.FormItems.Add("GoodsTransactionRecordingPresentation");
	
	SettingsParameters.HideUnavailableInvoiceInRows = True;
	SettingsParameters.ConditionsForAvailabilityOfAccountingAccountInLines.Insert(
		"ToExpenseAs",
		True);
	
	Return SettingsParameters;
	
EndFunction

#EndRegion

#Region Workplace

// Generates a table of reports to the giver for registration
// 
// Parameters:
// 	Parameters - Structure - Where:
// * Organization - CatalogRef.Companies
// * MaterialProvider - CatalogRef.Companies
// * Department - CatalogRef.BusinessStructure
// * Products - Boolean
//  TempStorageAddress - UUID, String - Temporary storage address
//
Procedure FillOutReportsForRegistration(Parameters, TempStorageAddress) Export
	
	Query = RequestRemainingReportsToBeProcessed(Parameters);
	Query.Text = Query.Text + "
	|ORDER BY
	|	StatusID DESC,
	|	MONTH,
	|	Organization,
	|	MaterialProvider,
	|	ProductionLot
	|";
	
	ReportsToBeProcessed = Query.Execute().Unload();
	
	PutToTempStorage(ReportsToBeProcessed, TempStorageAddress);
	
EndProcedure

// Request for Balance of reports to be processed.
// 
// Parameters:
//  Parameters - Structure
// 
// Returns:
//  Query -  Request The Remaining Reports To Be Processed
//
Function RequestRemainingReportsToBeProcessed(Parameters) Export
	
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	QueryTexts = New Array;
	QueryTexts.Add(
	"
	// Batches of production of internal processing.
	|SELECT
	|	PartyCompanies.Organization  AS Organization,
	|	CatProductionLots.Ref   AS ProductionLot,
	|	CatProductionLots.Document AS Document,
	|	CatProductionLots.Code      AS CostGroupNumber,
	|	MAX(BEGINOFPERIOD(ISNULL(GoodsOfReportsToGiver.Ref.Date, DATETIME(1,1,1)), MONTH)) AS MonthOfLastReport
	|INTO DomesticProductionBatches
	|FROM
	|	Catalog.ProductionLots AS CatProductionLots
	|	
	|	INNER JOIN Catalog.ProductionLots.Companies AS PartyCompanies
	|	ON PartyCompanies.Ref = CatProductionLots.Ref
	|	
	|	INNER JOIN InformationRegister.DocumentsRegistry AS AttributesOfPartyDocument
	|	ON AttributesOfPartyDocument.Ref = CatProductionLots.Document
	|	AND AttributesOfPartyDocument.Posted
	|	
	|	LEFT JOIN Document.BackflushProduction AS AttributesOfBatchOfProductionWithoutOrder
	|	ON AttributesOfBatchOfProductionWithoutOrder.Ref = CatProductionLots.Document
	|	
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS SideOfParty
	|	ON SideOfParty.ReversedDocument = CatProductionLots.Document
	|	AND SideOfParty.Posted
	|	AND NOT ISNULL(AttributesOfBatchOfProductionWithoutOrder.CorrectionSavesProductionLots, FALSE)
	|	
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS StornoOfSavedBatch
	|	ON StornoOfSavedBatch.CorrectedDocument = CatProductionLots.Document
	|	AND StornoOfSavedBatch.Posted
	|	AND ISNULL(AttributesOfBatchOfProductionWithoutOrder.CorrectionSavesProductionLots, FALSE)
	|	AND VALUETYPE(StornoOfSavedBatch.Ref) = TYPE(Document.ReversingEntry)
	|	
	|	LEFT JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS ReportsToGiver
	|	ON ReportsToGiver.Organization = PartyCompanies.Organization
	|	AND ReportsToGiver.Posted
	|	AND NOT ReportsToGiver.Ref = &Recorder
	|	
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS SideOfReport
	|	ON SideOfReport.ReversedDocument = ReportsToGiver.Ref
	|	AND SideOfReport.Posted
	|	
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS ReportCorrections
	|	ON ReportCorrections.CorrectedDocument = ReportsToGiver.Ref
	|	AND ReportCorrections.Posted
	|	
	|	LEFT JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS GoodsOfReportsToGiver
	|	ON GoodsOfReportsToGiver.Ref = ReportsToGiver.Ref
	|	AND GoodsOfReportsToGiver.ProductionLot = PartyCompanies.Ref
	|	AND SideOfReport.Ref IS NULL
	|	AND ReportCorrections.Ref IS NULL
	|
	|WHERE
	|	CatProductionLots.InternalSubcontracting
	|	AND (SideOfParty.Ref IS NULL
	|		AND StornoOfSavedBatch.Ref IS NULL
	// Production Lot reference, without saving when correcting, corrected/suspended in the following months
	|		OR SideOfParty.Ref IS NOT NULL
	|			AND BEGINOFPERIOD(SideOfParty.IBDocumentDate, MONTH) > BEGINOFPERIOD(AttributesOfPartyDocument.IBDocumentDate, MONTH)
	// and there is a non-suspended report
	|			AND GoodsOfReportsToGiver.Ref IS NOT NULL
	// The production Lot reference, with preservation during correction, is suspended in the following months
	|		OR StornoOfSavedBatch.Ref IS NOT NULL
	|			AND BEGINOFPERIOD(StornoOfSavedBatch.IBDocumentDate, MONTH) > BEGINOFPERIOD(AttributesOfPartyDocument.IBDocumentDate, MONTH)
	// and there is a non-suspended report
	|			AND GoodsOfReportsToGiver.Ref IS NOT NULL)
	|	AND NOT CatProductionLots.DeletionMark
	|	AND NOT PartyCompanies.Organization = CatProductionLots.Organization
	|	AND (&ForAllGivers OR CatProductionLots.Organization IN(&MaterialProvider))
	|	AND (&ForAllProductionBatches OR CatProductionLots.Ref IN(&ProductionLots))
	|
	|GROUP BY
	|	PartyCompanies.Organization,
	|	CatProductionLots.Ref,
	|	CatProductionLots.Document,
	|	CatProductionLots.Code
	|
	|INDEX BY
	|	ProductionLot,
	|	Organization
	|");
	
	QueryTexts.Add(Catalogs.ProductionLots.QueryTextOfProductionBatchIsInProgress("DomesticProductionBatches"));
	
	QueryTexts.Add(
	"
	// Extreme Receipts to the Unfinished production by domestic processing batches by organizations.
	|SELECT
	|	ReceiptsOfUnfinishedProduction.Organization        AS Organization,
	|	ReceiptsOfUnfinishedProduction.ProductionLot AS ProductionLot,
	|	MAX(ReceiptsOfUnfinishedProduction.Month)    AS Month
	|INTO ReceiptsOfUnfinishedProduction
	|FROM
	|	(SELECT
	|		ReceiptsOfUnfinishedProduction.Organization                          AS Organization,
	|		DomesticProductionBatches.ProductionLot AS ProductionLot,
	|		BEGINOFPERIOD(ReceiptsOfUnfinishedProduction.Period, MONTH)         AS Month
	|	FROM
	|		DomesticProductionBatches AS DomesticProductionBatches
	|		
	|		INNER JOIN AccumulationRegister.InventoryCost AS ReceiptsOfUnfinishedProduction
	|		ON DomesticProductionBatches.ProductionLot = ReceiptsOfUnfinishedProduction.Lot
	|		AND DomesticProductionBatches.Organization = ReceiptsOfUnfinishedProduction.Organization
	|	
	|	WHERE
	|		BEGINOFPERIOD(ReceiptsOfUnfinishedProduction.Period, MONTH) > DomesticProductionBatches.MonthOfLastReport
	|		AND NOT ReceiptsOfUnfinishedProduction.LotCalculation
	|		AND NOT ReceiptsOfUnfinishedProduction.CalculationOfCost
	|		AND NOT ReceiptsOfUnfinishedProduction.ReversingEntry
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReceiptsOfUnfinishedProduction.Organization                          AS Organization,
	|		DomesticProductionBatches.ProductionLot AS ProductionLot,
	|		BEGINOFPERIOD(ReceiptsOfUnfinishedProduction.Period, MONTH)         AS Month
	|	FROM
	|		DomesticProductionBatches AS DomesticProductionBatches
	|		
	|		INNER JOIN AccumulationRegister.OtherWorkInProgressExpenses AS ReceiptsOfUnfinishedProduction
	|		ON DomesticProductionBatches.ProductionLot = ReceiptsOfUnfinishedProduction.ProductionLot
	|		AND DomesticProductionBatches.Organization = ReceiptsOfUnfinishedProduction.Organization
	|	
	|	WHERE
	|		BEGINOFPERIOD(ReceiptsOfUnfinishedProduction.Period, MONTH) > DomesticProductionBatches.MonthOfLastReport
	|		AND NOT ReceiptsOfUnfinishedProduction.LotCalculation
	|		AND NOT ReceiptsOfUnfinishedProduction.CalculationOfCost
	|		AND NOT ReceiptsOfUnfinishedProduction.ReversingEntry
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReceiptsOfUnfinishedProduction.Organization                          AS Organization,
	|		DomesticProductionBatches.ProductionLot AS ProductionLot,
	|		BEGINOFPERIOD(ReceiptsOfUnfinishedProduction.Period, MONTH)         AS Month
	|	FROM
	|		DomesticProductionBatches AS DomesticProductionBatches
	|		
	|		INNER JOIN AccumulationRegister.OtherExpenses AS ReceiptsOfUnfinishedProduction
	|		ON DomesticProductionBatches.ProductionLot = ReceiptsOfUnfinishedProduction.DimensionOfExpenses
	|		AND DomesticProductionBatches.Organization = ReceiptsOfUnfinishedProduction.Organization
	|	
	|	WHERE
	|		BEGINOFPERIOD(ReceiptsOfUnfinishedProduction.Period, MONTH) > DomesticProductionBatches.MonthOfLastReport
	|		AND NOT ReceiptsOfUnfinishedProduction.LotCalculation
	|		AND NOT ReceiptsOfUnfinishedProduction.CalculationOfCost
	|		AND NOT ReceiptsOfUnfinishedProduction.ReversingEntry
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReceiptsOfUnfinishedProduction.Organization                          AS Organization,
	|		DomesticProductionBatches.ProductionLot AS ProductionLot,
	|		BEGINOFPERIOD(ReceiptsOfUnfinishedProduction.Period, MONTH)         AS Month
	|	FROM
	|		DomesticProductionBatches AS DomesticProductionBatches
	|		
	|		INNER JOIN AccumulationRegister.WIPLaborCosts AS ReceiptsOfUnfinishedProduction
	|		ON DomesticProductionBatches.ProductionLot = ReceiptsOfUnfinishedProduction.ProductionLot
	|		AND DomesticProductionBatches.Organization = ReceiptsOfUnfinishedProduction.Organization
	|	
	|	WHERE
	|		BEGINOFPERIOD(ReceiptsOfUnfinishedProduction.Period, MONTH) > DomesticProductionBatches.MonthOfLastReport
	|		AND NOT ReceiptsOfUnfinishedProduction.LotCalculation
	|		AND NOT ReceiptsOfUnfinishedProduction.ReversingEntry
	|	) AS ReceiptsOfUnfinishedProduction
	|
	|GROUP BY
	|	ReceiptsOfUnfinishedProduction.Organization,
	|	ReceiptsOfUnfinishedProduction.ProductionLot
	|
	|INDEX BY
	|	ProductionLot,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Months of extreme Receipt of Unfinished production in the domestic processing production lots.
	|SELECT
	|	ReceiptsOfUnfinishedProduction.ProductionLot AS ProductionLot,
	|	MAX(ReceiptsOfUnfinishedProduction.Month)    AS Month
	|INTO MonthsOfExtremePartyReceipts
	|FROM
	|	ReceiptsOfUnfinishedProduction AS ReceiptsOfUnfinishedProduction
	|
	|GROUP BY
	|	ReceiptsOfUnfinishedProduction.ProductionLot
	|
	|INDEX BY
	|	ProductionLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReceiptsOfUnfinishedProduction.Organization                                      AS Organization,
	|	ReceiptsOfUnfinishedProduction.ProductionLot.Organization                   AS MaterialProvider,
	|	ReceiptsOfUnfinishedProduction.ProductionLot                               AS ProductionLot,
	|	CASE
	// The "In progress" ID
	|		WHEN PartiesInWork.ProductionLot IS NOT NULL
	|			THEN 1
	// ID "Completed"
	|		ELSE 2
	|	END                                                       AS StatusID,
	|	MAX(MonthsOfExtremePartyReceipts.Month)              AS Month,
	|	ReceiptsOfUnfinishedProduction.ProductionLot.MainProductProducts   AS Products,
	|	ReceiptsOfUnfinishedProduction.ProductionLot.MainProductCharacteristic AS Characteristic,
	|	ReceiptsOfUnfinishedProduction.ProductionLot.BillOfMaterials                  AS BillOfMaterials,
	|	ReceiptsOfUnfinishedProduction.ProductionLot.Purpose                    AS Purpose,
	|	ReceiptsOfUnfinishedProduction.ProductionLot.LineOfBusiness       AS LineOfBusiness
	|FROM
	|	ReceiptsOfUnfinishedProduction AS ReceiptsOfUnfinishedProduction
	|
	|	INNER JOIN MonthsOfExtremePartyReceipts AS MonthsOfExtremePartyReceipts
	|	ON MonthsOfExtremePartyReceipts.ProductionLot = ReceiptsOfUnfinishedProduction.ProductionLot
	|	
	|	LEFT JOIN PartiesInWork AS PartiesInWork
	|	ON PartiesInWork.ProductionLot = ReceiptsOfUnfinishedProduction.ProductionLot
	|	
	|WHERE
	|	(&ForAllProcessors OR ReceiptsOfUnfinishedProduction.Organization IN(&Organization))
	|	AND NOT ReceiptsOfUnfinishedProduction.Organization = ReceiptsOfUnfinishedProduction.ProductionLot.Organization
	|	AND (&ForAllMonths OR MonthsOfExtremePartyReceipts.Month = &Month)
	|	AND NOT(&OnlyCompleted
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ProductionStage2_2 AS ProductionStages
	|			WHERE
	|				ProductionStages.ProductionLot = ReceiptsOfUnfinishedProduction.ProductionLot
	|				AND ProductionStages.Posted
	|				AND NOT ProductionStages.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)))
	|
	|GROUP BY
	|	ReceiptsOfUnfinishedProduction.ProductionLot,
	|	ReceiptsOfUnfinishedProduction.Organization,
	|	PartiesInWork.ProductionLot
	|");
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Organization",               Parameters.Organization);
	Query.SetParameter("ForAllProcessors",      Not ValueIsFilled(Parameters.Organization));
	Query.SetParameter("MaterialProvider",                   Parameters.MaterialProvider);
	Query.SetParameter("ForAllGivers",           Not ValueIsFilled(Parameters.MaterialProvider));
	Query.SetParameter("ProductionLots",        Parameters.ProductionLots);
	Query.SetParameter("ForAllProductionBatches", Not ValueIsFilled(Parameters.ProductionLots));
	Query.SetParameter("Month",                     Parameters.Month);
	Query.SetParameter("ForAllMonths",             Not ValueIsFilled(Parameters.Month));
	Query.SetParameter("Recorder",               Parameters.Recorder);
	Query.SetParameter("OnlyCompleted",         Parameters.OnlyCompleted);
	
	Return Query;
	
EndFunction

// Parameters for requesting the Balance of reports for registration.
// 
// Returns:
//  Structure -  Parameters For Requesting Report Balances For Registration:
// * Organization - CatalogRef.Companies
// * MaterialProvider - CatalogRef.Companies
// * ProductionLots - CatalogRef.ProductionLots
// * Recorder - DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany
// * Month - Date
// * OnlyCompleted - Boolean
//
Function ParametersForRequestingReportBalancesForRegistration() Export
	
	Result = New Structure;
	Result.Insert("Organization");
	Result.Insert("MaterialProvider");
	Result.Insert("ProductionLots");
	Result.Insert("Recorder");
	Result.Insert("Month", Date(1, 1, 1));
	Result.Insert("OnlyCompleted", False);
	
	Return Result;
	
EndFunction

#EndRegion

#Region StandardMechanisms

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization,Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "MaterialProvider", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization,MaterialProvider";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization,MaterialProvider";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Contract", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "SubcontractorAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "MaterialProvider";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "MaterialProvider";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "MaterialProviderAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
EndProcedure

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If Not UserRightsCached.ThisIsPartner() Then
		
		// The act on the provision of services
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCertificateOfRenderedServices";
		PrintCommand.Id = "Act";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ';
										|ru = 'Акт об оказании услуг';
										|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
										|it = 'Atto di prestazione dei servizi';
										|pl = 'Protokół świadczenia usług';
										|tr = 'Hizmet tutanağı'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản cung cấp dịch vụ';
												|ru = 'Акт об оказании услуг';
												|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
												|it = 'Atto di prestazione dei servizi';
												|pl = 'Protokół świadczenia usług';
												|tr = 'Hizmet tutanağı'");
		
		If Constants.UseInternationalPrintingForms.Get() Then
			
			// Invoice
			PrintCommand = PrintCommands.Add();
			PrintCommand.Id = "InvoiceInt";
			PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
			PrintCommand.Presentation = NStr("vi = 'Commercial invoice';
											|ru = 'Commercial invoice';
											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
											|it = 'Commercial invoice';
											|pl = 'Commercial invoice';
											|tr = 'Commercial invoice'");
			PrintCommand.CheckPostingBeforePrint = True;
			
		EndIf;
		
	EndIf;
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the command to create the document "Transfer of goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseInternalSubcontracting";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.ProductsCostTree.AddReportCommand(ReportsCommands);
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// StandardSubsystems.AccessManagement

// When filling out access restrictions.
// 
// Parameters:
//  Restriction - See AccessManagementOverridable.OnFillListsWithAccessRestriction
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	(ValueAllowed(Organization)
	|	OR ValueAllowed(MaterialProvider))
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region TransactionsForLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the temporary table query.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Other

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Báo cáo dành cho người đặt gia công giữa các doanh nghiệp';
		|ru = 'Отчет давальцу между организациями';
		|en = 'Intercompany consumption report — Subcontracting services delivered'; fa = 'گزارش مصرف بین‌شرکتی — خدمات پیمانکاری فرعی ارائه‌شده';
		|it = 'Отчет давальцу между организациями';
		|pl = 'Intercompany consumption report — Subcontracting services delivered';
		|tr = 'İş yerleri arası Tüketim raporu-Verilen fason hizmetleri'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data on the work of the processor.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure;
	DocumentTables.Insert("Goods");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#Region Private

#Region ARAPAccounting

// Initializes the calculation state structure.
//
Function StructureOfSettlementStatusRecipient()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("PaymentAmountRecipient", 0);
	StructureOfStateOfCalculations.Insert("OrderReceiptAmount", 0);
	StructureOfStateOfCalculations.Insert("PaymentPercentageRecipient", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfOrderReceipt", 0);
	StructureOfStateOfCalculations.Insert("AmountOfOverduePaymentRecipient", 0);
	StructureOfStateOfCalculations.Insert("AmountOfDebtRecipient", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfDebtRecipient", 0);
	StructureOfStateOfCalculations.Insert("AmountPayableRecipient", 0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

// Initializes the calculation state structure.
//
Function StructureOfSettlementStatusSender()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("PaymentAmountSender", 0);
	StructureOfStateOfCalculations.Insert("AmountByShipment", 0);
	StructureOfStateOfCalculations.Insert("PaymentPercentageSender", 0);
	StructureOfStateOfCalculations.Insert("OrderShipmentPercentage", 0);
	StructureOfStateOfCalculations.Insert("AmountOfOverduePaymentSender", 0);
	StructureOfStateOfCalculations.Insert("AmountOwedSender", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfDebtSender", 0);
	StructureOfStateOfCalculations.Insert("AmountPayableSender", 0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

#EndRegion

#Region Posting

#Region InitializationOfEvent

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                      AS Ref,
	|	DocumentData.DeletionMark             AS DeletionMark,
	|	DocumentData.Number                       AS Number,
	|	DocumentData.Date                        AS Period,
	|	DocumentData.Posted                    AS Posted,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.MaterialProvider                     AS CompanyRecipient,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.MaterialProvider                     AS MaterialProvider,
	|	DocumentData.BusinessOperation       AS BusinessOperation,
	|	DocumentData.Contract                     AS Contract,
	|	DocumentData.Department               AS Department,
	|	DocumentData.LineOfBusiness     AS LineOfBusiness,
	|	DocumentData.PriceIncludesVAT             AS PriceIncludesVAT,
	|	DocumentData.VATTaxation          AS VATTaxation,
	|	DocumentData.Currency                      AS Currency,
	|	DocumentData.ARAPCurrency        AS ARAPCurrency,
	|	DocumentData.DocumentAmount              AS DocumentAmount,
	|	DocumentData.AmountARAP         AS AmountARAP,
	|	DocumentData.CourseNumerator               AS CourseNumerator,
	|	DocumentData.CourseDenominator             AS CourseDenominator,
	|	DocumentData.PaymentDate                 AS PaymentDate,
	|	DocumentData.ARAPObjectSettings             AS ARAPObjectSettings,
	|	DocumentData.PaymentMethod                 AS PaymentMethod,
	|	DocumentData.PaymentID        AS PaymentID,
	|	DocumentData.SubcontractorAccount AS SubcontractorAccount,
	|	DocumentData.MaterialProviderAccount      AS MaterialProviderAccount,
	|	DocumentData.PowerOfAttorneyNumber           AS PowerOfAttorneyNumber,
	|	DocumentData.PowerOfAttorneyDate            AS PowerOfAttorneyDate,
	|	DocumentData.LetterOfAuthorityIssuedBy          AS LetterOfAuthorityIssuedBy,
	|	DocumentData.PowerOfAttorneyPerson            AS PowerOfAttorneyPerson,
	|	DocumentData.Director                AS Director,
	|	DocumentData.ChiefAccountant            AS ChiefAccountant,
	|	DocumentData.Basis                   AS Basis,
	|	DocumentData.ReferenceDocumentDateForPrintForms               AS ReferenceDocumentDateForPrintForms,
	|	DocumentData.BaseDocumentNumber              AS BaseDocumentNumber,
	|	DocumentData.ARAPObject              AS ARAPObject,
	|	DocumentData.ARAPObjectOfRecipient    AS ARAPObjectOfRecipient,
	|	DocumentData.EmployeeResponsible               AS EmployeeResponsible,
	|	DocumentData.Author                       AS Author,
	|	DocumentData.Comment                 AS Comment,
	|	BusinessTransactionsSettings.Ref       AS BusinessTransactionSetting,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE)                AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	UNDEFINED                                AS AdjustmentPeriod_
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentData
	|	
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	
	If Attributes.Next() Then
		For Each Column In Result.Columns Do
			Query.SetParameter(Column.Name, Attributes[Column.Name]);
		EndDo;
	EndIf;
	
	Query.SetParameter("Ref",                     DocumentRef);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
	Query.SetParameter(
		"MetadataIdentifier",
		Common.MetadataObjectID("Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany"));
	
	Query.SetParameter(
		"NumberForPrinting",
		ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	GiverSAccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Attributes.CompanyRecipient,
		Attributes.Period);
	MovingAverageAtGiver = (GiverSAccountingPolicyParameters <> Undefined
		And GiverSAccountingPolicyParameters.InventoryValuationMethod = Enums.InventoryValuationMethods.MovingAverage);
	Query.SetParameter("MovingAverageAtGiver", MovingAverageAtGiver);
	
EndProcedure

Procedure SetParameterForPartnerAccountingAnalyticsRequest(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	StructureSupplier = New Structure;
	StructureSupplier.Insert("Organization", Query.Parameters.Organization);
	StructureSupplier.Insert("Partner",     Catalogs.Partners.OurEnterprise);
	StructureSupplier.Insert("Counterparty",  Query.Parameters.MaterialProvider);
	StructureSupplier.Insert("Contract",     Query.Parameters.Contract);
	StructureSupplier.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureSupplier);
	
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	AnalystTable.Products      AS Products,
	|	AnalystTable.Characteristic    AS Characteristic,
	|	AnalystTable.Purpose        AS Purpose,
	|	AnalystTable.Series             AS Series,
	|	AnalystTable.StorageLocation     AS StorageLocation,
	|	AnalystTable.ProductCostElement AS ProductCostElement
	|FROM
	|	(
	// Analytics with a calculation article with an appointment
	|	SELECT
	|		Goods.ItemsLocationAttributes.Products   AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		Goods.ItemsLocationAttributes.Purpose     AS Purpose,
	|		Goods.ItemsLocationAttributes.Series          AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation  AS StorageLocation,
	|		Goods.ProductCostElement                         AS ProductCostElement
	|	FROM
	|		Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS Goods
	|	WHERE
	|		&KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// Analytics with a calculation article without an appointment
	|	SELECT
	|		Goods.ItemsLocationAttributes.Products   AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)     AS Purpose,
	|		Goods.ItemsLocationAttributes.Series          AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation  AS StorageLocation,
	|		Goods.ProductCostElement                         AS ProductCostElement
	|	FROM
	|		Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS Goods
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// Analytics without a calculation article without an appointment
	|	SELECT
	|		Goods.ItemsLocationAttributes.Products      AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic    AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)        AS Purpose,
	|		Goods.ItemsLocationAttributes.Series             AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation     AS StorageLocation,
	|		Goods.ItemsLocationAttributes.ProductCostElement AS ProductCostElement
	|	FROM
	|		Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS Goods
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.Ref = &Ref
	|	) AS AnalystTable
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Dimension.Products     = AnalystTable.Products
	|	AND Dimension.Characteristic    = AnalystTable.Characteristic
	|	AND Dimension.Series             = AnalystTable.Series
	|	AND Dimension.StorageLocation     = AnalystTable.StorageLocation
	|	AND Dimension.Purpose        = AnalystTable.Purpose
	|	AND Dimension.ProductCostElement = AnalystTable.ProductCostElement
	|
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|";
	
	QueryAnalyst.SetParameter("Ref",                                     Query.Parameters.Ref);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany";
	SynonymForDocumentTable = "DocumentsTable";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
	Else
		
		ExceptionText = StrTemplate(
			NStr("vi = 'Trong chứng từ %1 đã không thực hiện việc điều chỉnh văn bản của yêu cầu Lập các chuyển động trong thanh ghi %2.';
				|ru = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
				|en = 'In the %1 document, adaptation of request for generating records of the %2 register is not implemented.'; fa = 'In the %1 document, adaptation of request for generating records of the %2 register is not implemented.';
				|it = 'Nel documento %1 non è stato effettuato l''adattamento del testo di richiesta di generazione dei movimenti sul registro %2.';
				|pl = 'W dokumencie %1 nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %2.';
				|tr = '%1 belgesinde, %2 kaydına göre hareketlerin düzenlenmesi isteğinin metin uyarlaması uygulanmadı.'"),
			FullDocumentName,
			RegisterName);
		
		Raise ExceptionText;
		
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText       = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region QueryTextsTemporaryTables

Function QueryTextTableTTProducts_1(Query, QueryTexts)
	
	RegisterName = "TTProducts_1";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.Ref                     AS Ref,
	|	GoodsTable.LineNumber                AS LineNumber,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	GoodsTable.Products                    AS Products,
	|	GoodsTable.Characteristic                  AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	ISNULL(ItemAnalyticsWithoutAssignments.DimensionKey, GoodsTable.ItemsLocationAttributes) AS ProcessorInventoryLocationAttributedToProcessingCompany,
	|	ISNULL(AnalyticsOfGiverSItemListWithoutAppointment.DimensionKey, AnalyticsOfGiverSItemList.DimensionKey) AS GiverSInventoryLocationAttributeAccounting,
	|
	|	TableOfBatchAccountingAnalysts.VATTaxation AS GiverSVATTaxationTypeOfActivity,
	|	CASE WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END                                            AS VATTaxationProcessorSTypeOfActivity,
	|	GoodsTable.ProductionLot                 AS ProductionLot,
	|	GoodsTable.VATRate                          AS VATRate,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes  AS LotVendorAttributes,
	|	GoodsTable.ProductionLot.ProductsGroup AS FinancialAccountingDimension,
	|	GoodsTable.ExpenseItem             AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses          AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)          AS CCDNumber,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	GoodsTable.Count                 AS Count,
	|	0                                        AS QuantityByGBRN,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)          AS Cost,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)        AS CostExcludingVAT,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)       AS LocalCost,
	|	CASE WHEN &CompanyManagementAccounting
	|		THEN ISNULL(Amounts.AmountExcludingVATMan, 0)
	|		ELSE 0
	|	END                                    AS CostMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)       AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)          AS VATAmountCompl,
	|	ISNULL(Amounts.VATAmountMan, 0)           AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT                  AS AmountIncludingVAT,
	|	GoodsTable.VATAmount                   AS VATAmount,
	|	GoodsTable.AmountARAP        AS AmountARAP,
	|	GoodsTable.AmountVATARAP     AS AmountVATARAP,
	|	GoodsTable.GLAccountSettings       AS GLAccountSettings,
	|	GoodsTable.RowID        AS RowID,
	|	GoodsTable.RowID        AS FinRecordID,
	|	GoodsTable.ToExpenseAs           AS ToExpenseAs,
	|	&BusinessOperation                   AS BusinessOperation,
	|	&BusinessTransactionSetting          AS BusinessTransactionSetting,
	|	GoodsTable.Products.TracedGoods AS TracedGoods
	|INTO TTProducts_1
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS GoodsTable
	|
	// Processor Inventory Location Attributed to the Processing Company
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|	ON DimensionOfProductItem.Ref = GoodsTable.ItemsLocationAttributes
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ItemAnalyticsWithoutAssignments
	|	ON NOT &KeepRecordsOfInventoryCostByAssignments
	|	AND ItemAnalyticsWithoutAssignments.Products      = DimensionOfProductItem.Products
	|	AND ItemAnalyticsWithoutAssignments.Characteristic    = DimensionOfProductItem.Characteristic
	|	AND ItemAnalyticsWithoutAssignments.Series             = DimensionOfProductItem.Series
	|	AND ItemAnalyticsWithoutAssignments.StorageLocation     = DimensionOfProductItem.StorageLocation
	|	AND ItemAnalyticsWithoutAssignments.Purpose        = VALUE(Catalog.Assignments.EmptyRef)
	|	AND ItemAnalyticsWithoutAssignments.ProductCostElement = DimensionOfProductItem.ProductCostElement
	|	
	// Giver's Inventory Location Attribute Accounting
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfGiverSItemList
	|	ON AnalyticsOfGiverSItemList.Products     = DimensionOfProductItem.Products
	|	AND AnalyticsOfGiverSItemList.Characteristic    = DimensionOfProductItem.Characteristic
	|	AND AnalyticsOfGiverSItemList.Series             = DimensionOfProductItem.Series
	|	AND AnalyticsOfGiverSItemList.StorageLocation     = DimensionOfProductItem.StorageLocation
	|	AND AnalyticsOfGiverSItemList.Purpose        = DimensionOfProductItem.Purpose
	|	AND AnalyticsOfGiverSItemList.ProductCostElement = GoodsTable.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfGiverSItemListWithoutAppointment
	|	ON NOT &KeepRecordsOfInventoryCostByAssignments
	|	AND AnalyticsOfGiverSItemListWithoutAppointment.Products     = DimensionOfProductItem.Products
	|	AND AnalyticsOfGiverSItemListWithoutAppointment.Characteristic    = DimensionOfProductItem.Characteristic
	|	AND AnalyticsOfGiverSItemListWithoutAppointment.Series             = DimensionOfProductItem.Series
	|	AND AnalyticsOfGiverSItemListWithoutAppointment.StorageLocation     = DimensionOfProductItem.StorageLocation
	|	AND AnalyticsOfGiverSItemListWithoutAppointment.Purpose        = VALUE(Catalog.Assignments.EmptyRef)
	|	AND AnalyticsOfGiverSItemListWithoutAppointment.ProductCostElement = GoodsTable.ProductCostElement
	|	
	// Document amounts
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref             = GoodsTable.Ref
	|	AND Amounts.RowID = GoodsTable.RowID
	|
	// Lot's:Vendor attribute
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber = GoodsTable.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""ManufacturedProducts""
	|	
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTableTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_                   AS VariancePeriod,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	TableExpenses.ExpenseItem          AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses       AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	UNDEFINED                           AS VATActivityType,
	|	0                                      AS AmountIncludingVAT,
	|	0                                      AS AmountExcludingVAT,
	|	0                                      AS AmountExcludingVATMan,
	|	0                                      AS AmountIncludingVATCompl,
	|	0                                      AS AmountExcludingVATCompl,
	|	0                                      AS PermanentDifference,
	|	0                                      AS CostTD,
	|	&BusinessOperation                 AS BusinessOperation,
	|	UNDEFINED                           AS ItemsLocationAttributes,
	|	TableExpenses.RowID     AS RowID,
	|	TableExpenses.FinRecordID  AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTProducts_1 AS TableExpenses
	|WHERE
	|	TableExpenses.ToExpenseAs
	|	AND VALUETYPE(TableExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""ManufacturedProducts""										AS TabularSectionName,
	|	DocumentTable.LineNumber							AS LineNumber,
	|	VALUE(Catalog.Partners.OurEnterprise)			AS Vendor,
	|	DocumentTable.Ref.Organization						AS Counterparty,
	|	DocumentTable.VATRate								AS VATRate,
	//	The type of activity of the giver is taken from the production party, because the giver's activity type is determined by the production party
	|	DocumentTable.ProductionLot.VATActivityType	AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods)				AS AssetTaxClass,
	|	DocumentTable.RowCode								AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(
		TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

Function QueryTextTableProductsRelease(Query, QueryTexts, Registers)
	
	RegisterName = "ProductsRelease";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTableTTProducts_1(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&Period                                 AS Period,
	|	TabularSection.ProcessorInventoryLocationAttributedToProcessingCompany AS ItemsLocationAttributes,
	|	TabularSection.Count               AS Count,
	|	TabularSection.ExpenseItem           AS ExpenseItem,
	|	TabularSection.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TabularSection.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|FROM
	|	TTProducts_1 AS TabularSection
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTableTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                           AS Period,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromAnotherCompany) AS BusinessOperation,
	|	&MaterialProvider                                          AS Organization,
	|	VALUE(Catalog.Partners.OurEnterprise)     AS Partner,
	|	&Organization                                      AS Counterparty,
	|	&Contract                                          AS Contract,
	|	UNDEFINED                                      AS OrderDocument,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB
	|			THEN &LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                             AS CounterpartyLineOfBusiness,
	|	UNDEFINED AS Terms,
	|	&Department                                    AS Department,
	|	&EmployeeResponsible                                    AS Manager,
	|
	|	GoodsTable.GiverSInventoryLocationAttributeAccounting  AS ItemsLocationAttributes,
	|	CASE
	|		WHEN &AccountingForLBCosts
	|			THEN &LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                             AS ProductLineOfBusiness,
	|	&Department                                    AS Warehouse,
	|	VALUE(Enum.InventoryTypes.OperationService)         AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)     AS InventoryOwnerAttribute,
	|
	|	SUM(GoodsTable.Count)                   AS Count,
	|
	|	SUM(ISNULL(GoodsTable.Cost, 0))       AS Sum,
	|	SUM(ISNULL(GoodsTable.CostExcludingVAT, 0)) AS AmountExcludingVAT,
	|	SUM(ISNULL(GoodsTable.AmountExcludingVATCompl, 0) + ISNULL(GoodsTable.VATAmountCompl, 0)) AS SumCompl,
	|	SUM(ISNULL(GoodsTable.AmountExcludingVATCompl, 0)) AS LocalAmountExcludingVAT,
	|	SUM(ISNULL(GoodsTable.Cost, 0))       AS Cost,
	|	SUM(ISNULL(GoodsTable.CostExcludingVAT, 0)) AS CostExcludingVAT,
	|	SUM(CASE
	|		WHEN ISNULL(GoodsTable.ProductionLot.VATActivityType,
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)) IN(
	|					VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|					VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN ISNULL(GoodsTable.AmountExcludingVATCompl, 0) + ISNULL(GoodsTable.VATAmountCompl, 0)
	|		ELSE ISNULL(GoodsTable.AmountExcludingVATCompl, 0)
	|	END)                                            AS LocalCost,
	|
	|	&Currency                                           AS DocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT)                    AS AmountInDocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency                             AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP)          AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	GoodsTable.Products                        AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectOfRecipient                         AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	NOT GoodsTable.ToExpenseAs
	|
	|GROUP BY
	|	GoodsTable.GiverSInventoryLocationAttributeAccounting,
	|	GoodsTable.Products
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTableTTProducts_1(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Count               AS Count
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	NOT GoodsTable.TracedGoods
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Count               AS Count
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	NOT GoodsTable.TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref                  AS Ref,
	|	DocumentsTable.Date                    AS IBDocumentDate,
	|	DocumentsTable.Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier                  AS RefType,
	|	DocumentsTable.Organization             AS Organization,
	|	DocumentsTable.BusinessOperation   AS BusinessOperation,
	|	DocumentsTable.Contract                 AS Contract,
	|	DocumentsTable.LineOfBusiness AS LineOfBusiness,
	|	DocumentsTable.Department           AS Department,
	|	DocumentsTable.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentsTable.Author                   AS Author,
	|	CAST(DocumentsTable.Comment    AS STRING(100)) AS Comment,
	|	DocumentsTable.Currency                  AS Currency,
	|	DocumentsTable.DocumentAmount          AS Sum,
	|	DocumentsTable.Posted                AS Posted,
	|	DocumentsTable.DeletionMark         AS DeletionMark,
	|	FALSE                                      AS AdditionalRecord,
	|	DocumentsTable.Date                    AS SourceDocumentDate,
	|	&NumberForPrinting                            AS SourceDocumentNumber
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref                  AS Ref,
	|	DocumentsTable.Date                    AS IBDocumentDate,
	|	DocumentsTable.Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier                  AS RefType,
	|	DocumentsTable.MaterialProvider                 AS Organization,
	|	DocumentsTable.BusinessOperation   AS BusinessOperation,
	|	DocumentsTable.Contract                 AS Contract,
	|	DocumentsTable.LineOfBusiness AS LineOfBusiness,
	|	DocumentsTable.Department           AS Department,
	|	DocumentsTable.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentsTable.Author                   AS Author,
	|	CAST(DocumentsTable.Comment    AS STRING(100)) AS Comment,
	|	DocumentsTable.Currency                  AS Currency,
	|	DocumentsTable.DocumentAmount          AS Sum,
	|	DocumentsTable.Posted                AS Posted,
	|	DocumentsTable.DeletionMark         AS DeletionMark,
	|	TRUE                                    AS AdditionalRecord,
	|	DocumentsTable.Date                    AS SourceDocumentDate,
	|	&NumberForPrinting                            AS SourceDocumentNumber
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTableTTProducts_1(Query, QueryTexts);
	EndIf;
	
	SetParameterForPartnerAccountingAnalyticsRequest(Query);
	
	QueryText = 
	"SELECT
	|	ProductTable.LineNumber	AS LineNumber,
	|	&Period							AS Period,
	|	&Department					AS Department,
	|	&AdjustmentPeriod_			AS AdjustmentPeriod_,
	|	ProductTable.ProcessorInventoryLocationAttributedToProcessingCompany						AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners														AS AccountingDimensionByPartners,
	|	VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)	AS BusinessOperation,
	|	CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|			THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|		ELSE &VATTaxation
	|	END																			AS VATTaxation,
	|	VALUE(Enum.InventoryTypes.OperationService)										AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)									AS InventoryOwnerAttribute,
	// Filling in the field "Accounting section" must correspond to the function of the description of the operation of the recording_realization_work()
	// #REALIZATION_REALIZATION_WORKING_2_PROCESSOR_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2
	|	(CASE
	|		WHEN &ProductCostingByPlannedCost
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) END) AS AccountingSection,
	|	(CASE
	|		WHEN &MovingAverage THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE ProductTable.FinancialAccountingDimension END)						AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &MovingAverage THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE ProductTable.VATTaxationProcessorSTypeOfActivity END)				AS VATActivityType,
	|
	|	&EmployeeResponsible					AS Manager,
	|	ProductTable.Count		AS Count,
	|	&Ref							AS SalesOrder,
	// Batch Accounting Analysis Fields
	|	(CASE
	|		WHEN &FIFORollingValuation THEN &Ref
	|		ELSE UNDEFINED END) 	AS Lot,
	|	(CASE
	|		WHEN &FIFORollingValuation THEN ProductTable.LotVendorAttributes
	|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) END) AS LotVendorAttributes,
	|
	|	ProductTable.Cost			AS RevenueAmount,
	|	ProductTable.CostExcludingVAT	AS RevenueAmountExcludingVAT,
	|	ProductTable.AmountExcludingVATCompl	AS RevenueAmountExclVATLocal,
	|	ProductTable.AmountExcludingVATCompl + ProductTable.VATAmountCompl AS RevenueAmountIncludingVATLocal,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	&Department	AS Warehouse,
	|	&Contract		AS Contract,
	|	UNDEFINED	AS Terms,
	|
	|	&LineOfBusiness							AS CounterpartyLineOfBusiness,
	|	ProductTable.Purpose.LineOfBusiness	AS ProductLineOfBusiness,
	|
	|	&ARAPCurrency											AS ARAPCurrency,
	|	ProductTable.AmountARAP							AS AmountInARAPCurrency,
	|	ProductTable.AmountARAP - ProductTable.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency													AS DocumentCurrency,
	|	ProductTable.AmountIncludingVAT								AS AmountInDocumentCurrency,
	|	ProductTable.AmountIncludingVAT - ProductTable.VATAmount	AS AmountExcludingVATInDocumentCurrency,
	|
	|	ProductTable.Products	AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject					AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	ProductTable.FinRecordID			AS FinRecordID,
	|	ProductTable.BusinessTransactionSetting	AS BusinessTransactionSetting,
	|
	|	ProductTable.VATRate AS VATRate
	|	
	|FROM
	|	TTProducts_1 AS ProductTable
	|
	|WHERE
	|	NOT ProductTable.ToExpenseAs
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = 
	"SELECT
	|	""Covariability""                           AS DataSource,
	|	TRUE                                           AS DistributeTotalAmount,
	|	GoodsTable.Ref                             AS Ref,
	|	GoodsTable.Ref.Date                        AS Date,
	|	GoodsTable.Ref.Organization                 AS Organization,
	|	GoodsTable.Ref.Currency                      AS DocumentCurrency,
	|	GoodsTable.Ref.ARAPCurrency        AS ARAPCurrency,
	|	GoodsTable.Ref.Date                        AS VATBasePeriod,
	|	GoodsTable.Ref.Date                        AS DateOfCourse,
	|	GoodsTable.LineNumber                        AS LineNumber,
	|	GoodsTable.RowID                AS RowID,
	|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount AS AmountExcludingVAT,
	|	GoodsTable.VATRate                          AS VATRate,
	|	GoodsTable.VATAmount                           AS VATAmount,
	|	GoodsTable.AmountARAP                AS AmountARAP,
	|	GoodsTable.AmountVATARAP             AS AmountVATARAP,
	|	0                                                AS AmountExcludingVATCompl,
	|	0                                                AS AmountExcludingVATMan,
	|
	|	TRUE                                           AS RecordedInARAPAccounting,
	|	GoodsTable.Ref.ARAPObject              AS ARAPObject,
	|	TRUE                                           AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|	AND NOT GoodsTable.Products.TracedGoods
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

#Region ARAPAccounting

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.MaterialProvider AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectOfRecipient AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.MaterialProvider AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ARAPDetailsWithVendor AS Table
		|	
		|	LEFT JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentDataHeader
		|	ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ARAPDetailsWithCustomer AS Table
		|	
		|	LEFT JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentDataHeader
		|	ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region AddTextsToReflectMutualSettlements
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                                AS Ref,
		|	Table.MaterialProvider                               AS Organization,
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|	Table.Date                                  AS RecorderDate,
		|	Table.Number                                 AS RecorderNumber,
		|	Table.ARAPObjectOfRecipient              AS ARAPObject,
		|	Table.PaymentDate                           AS PaymentDate,
		|	UNDEFINED                                  AS PaymentOption,
		|	UNDEFINED                                  AS PurchaseOrder_,
		|	Table.DocumentAmount                        AS Sum,
		|	Table.AmountARAP                   AS AmountARAP,
		|	0                                             AS AmountARAPByPackage,
		|
		|	Table.ARAPObjectSettings                       AS ARAPObjectSettings,
		|	FALSE                                          AS InvoiceForOrders,
		|	Table.ARAPCurrency                  AS ARAPCurrency,
		|	Table.BusinessOperation                 AS BusinessOperation,
		|	Table.PaymentMethod                           AS PaymentMethod,
		|	Table.Currency                                AS DocumentCurrency,
		|	Table.Date                                  AS DateOfCourse,
		|	UNDEFINED                                  AS LinkedDocument
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                                AS Ref,
		|	Table.MaterialProvider                               AS Organization,
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|	Table.Date                                  AS RecorderDate,
		|	Table.Number                                 AS RecorderNumber,
		|	Table.PaymentDate                           AS PaymentDate,
		|	
		|	Table.ARAPObjectOfRecipient              AS ARAPObject,
		|	Table.ARAPObjectSettings                       AS ARAPObjectSettings,
		|	FALSE                                          AS InvoiceForOrders,
		|	FALSE                                          AS ExceedingOrder,
		|	UNDEFINED                                  AS PurchaseOrder_,
		|	Table.AmountARAP                   AS AmountDue,
		|	Table.ARAPCurrency                  AS ARAPCurrency,
		|	Table.BusinessOperation                 AS BusinessOperation,
		|	Table.PaymentMethod                           AS PaymentMethod,
		|	Table.Currency                                AS DocumentCurrency,
		|	UNDEFINED                                  AS PaymentOption,
		|	UNDEFINED                                  AS LinkedDocument
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";

	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                AS Ref,
		|	Table.Ref.MaterialProvider                        AS Organization,
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|	
		|	Table.ARAPObject                        AS CalculationObjectSource,
		|	Table.Ref.ARAPObjectOfRecipient       AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency           AS ARAPCurrency,
		|	Table.AmountARAP                   AS AmountARAP,
		|	Table.Ref.Currency                         AS DocumentCurrency,
		|	Table.Sum                                 AS Sum,
		|
		|	Table.Ref.Date                           AS DateOfCourse,
		|	Table.Ref.Date                           AS RecorderDate,
		|	Table.Ref.Number                          AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ARAPDetailsWithVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
	#EndRegion
	
	#Region AddTextsToReflectSalesSettlements
	
	#Region Sale
	
	TextSale =
		"SELECT
		|	Table.Ref                                AS Ref,
		|	Table.Organization                           AS Organization,
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|	
		|	Table.ARAPObject                        AS ARAPObject,
		|	Table.PaymentDate                           AS PaymentDate,
		|	UNDEFINED                                  AS SalesOrder_,
		|	FALSE                                          AS InvoiceForOrders,
		|	Table.AmountARAP                   AS AmountARAP,
		|	0                                             AS AmountARAPByPackage,
		|	Table.DocumentAmount                        AS Sum,
		|	
		|	Table.ARAPObjectSettings                       AS ARAPObjectSettings,
		|	Table.Date                                  AS RecorderDate,
		|	Table.Number                                 AS RecorderNumber,
		|	Table.ARAPCurrency                  AS ARAPCurrency,
		|	Table.BusinessOperation                 AS BusinessOperation,
		|	Table.Date                                  AS DateOfCourse,
		|	Table.Currency                                AS DocumentCurrency,
		|	UNDEFINED                                  AS PaymentOption,
		|	FALSE                                          AS ExceedingOrder,
		|	UNDEFINED                                  AS LinkedDocument
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                AS Ref,
		|	Table.Organization                           AS Organization,
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|	
		|	Table.ARAPObject                        AS ARAPObject,
		|	Table.Date                                  AS RecorderDate,
		|	Table.Number                                 AS RecorderNumber,
		|	Table.ARAPObjectSettings                       AS ARAPObjectSettings,
		|	Table.ARAPCurrency                  AS ARAPCurrency,
		|	Table.Currency                                AS DocumentCurrency,
		|	Table.BusinessOperation                 AS BusinessOperation,
		|	Table.PaymentMethod                           AS PaymentMethod,
		|	
		|	Table.PaymentDate                           AS PaymentDate,
		|	UNDEFINED                                  AS PaymentOption,
		|	Table.AmountARAP                   AS AmountDue,
		|	
		|	TRUE                                        AS ExcludeDuringControl,
		|	FALSE                                          AS InvoiceForOrders,
		|	UNDEFINED                                  AS SalesOrder_,
		|	FALSE                                          AS ExceedingOrder,
		|	UNDEFINED                                  AS LinkedDocument
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                AS Ref,
		|	Table.Ref.Organization                    AS Organization,
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|
		|	Table.ARAPObject                        AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                 AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency           AS ARAPCurrency,
		|	Table.AmountARAP                   AS AmountARAP,
		|	Table.Ref.Currency                         AS DocumentCurrency,
		|	Table.Sum                                 AS Sum,
		|
		|	Table.Ref.Date                           AS DateOfCourse,
		|	Table.Ref.Date                           AS RecorderDate,
		|	Table.Ref.Number                          AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ARAPDetailsWithCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AccountingDimensionByPartners");
	
	If Query <> Undefined Then
		SetParameterForPartnerAccountingAnalyticsRequest(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTProducts_1");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTableTTProducts_1(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region InternalReceipt_ReleaseOfProcessorSWork_U_1
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED			AS DocumentToBeCorrected,
	|	0						AS RowCode,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TTProducts_1.ProcessorInventoryLocationAttributedToProcessingCompany	AS ItemsLocationAttributes,
	|	TTProducts_1.InventoryOwnerAttribute									AS InventoryOwnerAttribute,
	|	TTProducts_1.VATTaxationProcessorSTypeOfActivity			AS VATActivityType,
	|	TTProducts_1.VATTaxationProcessorSTypeOfActivity			AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref							AS Lot,
	|	TTProducts_1.LotVendorAttributes					AS LotVendorAttributes,
	|
	// Corresponding fields
	|	TTProducts_1.LotVendorAttributes	AS LotVendorAttributesCorr,
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|	UNDEFINED					AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	TTProducts_1.FinancialAccountingDimension	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTProducts_1.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS CostMan,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|	0 AS OffBalanceCost,
	|	0 AS OffBalanceCostLocal,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS CorGrossInitialCostENT,
	|
	// Other fields
	|	(CASE
	|		WHEN &ProductCostingByPlannedCost
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE UNDEFINED END)										AS AccountingSection,
	|	VALUE(Enum.LotRecordTypes.Supplement)					AS EntryType,
	|	TTProducts_1.RowID										AS RowID,
	|	TTProducts_1.FinRecordID										AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease)		AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsRelease)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);

	#EndRegion
	
	#Region Implementation_ImplementationOfWorkOnlyLocalAccounting_UProcessor_2
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	DocumentTable.Ref	AS DocumentRegisterRecords,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TTProducts_1.ProcessorInventoryLocationAttributedToProcessingCompany	AS ItemsLocationAttributes,
	|	TTProducts_1.InventoryOwnerAttribute									AS InventoryOwnerAttribute,
	|	TTProducts_1.VATTaxationProcessorSTypeOfActivity			AS VATActivityType,
	|	TTProducts_1.GiverSVATTaxationTypeOfActivity					AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref			AS Lot,
	|	TTProducts_1.LotVendorAttributes	AS LotVendorAttributes,
	|
	// Corresponding fields
	|	DocumentTable.MaterialProvider							AS CorCompany,
	|	TTProducts_1.ProcessorInventoryLocationAttributedToProcessingCompany	AS CorItemsLocationAttributes,
	|	TTProducts_1.CorInventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|	DocumentTable.Ref						AS CorLot,
	|	TTProducts_1.LotVendorAttributes				AS LotVendorAttributesCorr,
	|	TTProducts_1.GiverSVATTaxationTypeOfActivity			AS CorVATActivityTypes,
	|	&AccountingDimensionByPartners					AS AccountingDimensionByPartners,
	|	DocumentTable.Ref						AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	TTProducts_1.FinancialAccountingDimension	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTProducts_1.Count AS Count,
	|
	// Other fields
	// Filling in the "Accounting Section" field must correspond to the function of the text request for a handle and the value of sales(). 
	|	(CASE
	|		WHEN &ProductCostingByPlannedCost
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE UNDEFINED END)						AS AccountingSection,
	|	VALUE(Enum.LotRecordTypes.Supplement)	AS EntryType,
	|	TTProducts_1.RowID						AS RowID,
	|	TTProducts_1.FinRecordID						AS FinRecordID,
	|	TTProducts_1.BusinessOperation						AS BusinessOperation,
	|	TTProducts_1.BusinessTransactionSetting				AS BusinessTransactionSetting,
	|	(CASE
	|		WHEN &ProductCostingByPlannedCost
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.FromDocument)
	|		ELSE VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef) END)	AS CostDefiningMethod
	|
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT TTProducts_1.ToExpenseAs
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);

	#EndRegion
	
	#Region WriteOffForExpensesAssets_WriteOffOfWorkForExpensesAssetsOfProcessor_3
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TTProducts_1.ProcessorInventoryLocationAttributedToProcessingCompany	AS ItemsLocationAttributes,
	|	TTProducts_1.InventoryOwnerAttribute									AS InventoryOwnerAttribute,
	|	TTProducts_1.VATTaxationProcessorSTypeOfActivity			AS VATActivityType,
	|	TTProducts_1.VATTaxationProcessorSTypeOfActivity			AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref			AS Lot,
	|	TTProducts_1.LotVendorAttributes	AS LotVendorAttributes,
	|
	// Corresponding fields
	|	UNDEFINED										AS CorCompany,
	|	UNDEFINED										AS CorItemsLocationAttributes,
	|	UNDEFINED										AS CorInventoryOwnerAttribute,
	|	TTProducts_1.ExpenseItem								AS ExpenseItemAssets,
	|	CASE WHEN TTProducts_1.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|		THEN TTProducts_1.DimensionOfExpenses
	|		ELSE TTProducts_1.AssetsLiabilitiesDimension
	|	END												AS AssetExpenseAnalytics,
	|	DocumentTable.LineOfBusiness			AS CorLineOfBusiness,
	|	DocumentTable.Ref								AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	TTProducts_1.FinancialAccountingDimension	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTProducts_1.Count		AS Count,
	|	0						AS Cost,
	|	0						AS CostExcludingVAT,
	|	0						AS LocalCost,
	|	0						AS CostMan,
	|
	// Other fields
	|	(CASE
	|		WHEN &ProductCostingByPlannedCost
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE UNDEFINED END)						AS AccountingSection,
	|	VALUE(Enum.LotRecordTypes.Supplement)	AS EntryType,
	|	TTProducts_1.GLAccountSettings						AS GLAccountSettings,
	|	TTProducts_1.RowID						AS RowID,
	|	TTProducts_1.FinRecordID						AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)		AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TTProducts_1.ToExpenseAs
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);

	#EndRegion
	
	#Region ExternalReceipt_ReceiptOfProcessorSWork_UGiver_4
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.MaterialProvider							AS Organization,
	|	TTProducts_1.ProcessorInventoryLocationAttributedToProcessingCompany	AS ItemsLocationAttributes,
	|	TTProducts_1.CorInventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	TTProducts_1.GiverSVATTaxationTypeOfActivity				AS VATActivityType,
	|	TTProducts_1.GiverSVATTaxationTypeOfActivity				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref							AS Lot,
	|	TTProducts_1.LotVendorAttributes					AS LotVendorAttributes,
	|	VALUE(Catalog.Partners.OurEnterprise)	AS Vendor,
	|	DocumentTable.Organization					AS Counterparty,
	|	TTProducts_1.VATRate								AS VATRate,
	|
	// Corresponding fields
	|	TTProducts_1.LotVendorAttributes	AS LotVendorAttributesCorr,
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|	DocumentTable.Organization	AS CorCompany,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	TTProducts_1.FinancialAccountingDimension	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTProducts_1.Count		AS Count,
	|	TTProducts_1.Cost		AS Cost,
	|	TTProducts_1.CostExcludingVAT AS CostExcludingVAT,
	|	TTProducts_1.LocalCost	AS LocalCost,
	|	TTProducts_1.CostMan	AS CostMan,
	|	TTProducts_1.VATAmountCompl	AS VATLocal,
	|	TTProducts_1.VATAmountMan	AS VATManag,
	|	0						AS OffBalanceCost,
	|	0						AS OffBalanceCostLocal,
	|	0						AS AddExpensesForGoods,
	|	0						AS AdditionalExpensesExcludingVAT,
	|	0						AS AddExpensesLocal,
	|	0						AS AddExpensesMan,
	|	0						AS PermanentDifference,
	|	0						AS CostTD,
	|	0						AS CorGrossInitialCostENT,
	|
	// Other fields
	|	TTProducts_1.RowID										AS RowID,
	|	DocumentTable.ARAPObjectOfRecipient.UUID	AS FinRecordID,
	|	TTProducts_1.BusinessOperation			AS BusinessOperation,
	|	TTProducts_1.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT TTProducts_1.ToExpenseAs
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);

	#EndRegion
	
	#Region WriteOffToOtherBatches_ExpenseOfWorkFromUnitAndReceiptOf_UGiver_5ForProductionBatch
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.MaterialProvider							AS Organization,
	|	TTProducts_1.ProcessorInventoryLocationAttributedToProcessingCompany	AS ItemsLocationAttributes,
	|	TTProducts_1.CorInventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	TTProducts_1.GiverSVATTaxationTypeOfActivity				AS VATActivityType,
	|	TTProducts_1.GiverSVATTaxationTypeOfActivity				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref			AS Lot,
	|	TTProducts_1.LotVendorAttributes	AS LotVendorAttributes,
	|
	// Corresponding fields
	|	TTProducts_1.GiverSInventoryLocationAttributeAccounting	AS CorItemsLocationAttributes,
	|	TTProducts_1.ProductionLot			AS CorLot,
	|	TTProducts_1.CorInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorCompany,
	|	UNDEFINED						AS LotVendorAttributesCorr,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	TTProducts_1.FinancialAccountingDimension	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTProducts_1.Count AS Count,
	|	(CASE
	|		WHEN &MovingAverageAtGiver THEN TTProducts_1.Cost
	|		ELSE 0 END)		AS Cost,
	|	(CASE
	|		WHEN &MovingAverageAtGiver THEN TTProducts_1.CostExcludingVAT
	|		ELSE 0 END)		AS CostExcludingVAT,
	|	(CASE
	|		WHEN &MovingAverageAtGiver THEN TTProducts_1.LocalCost
	|		ELSE 0 END)		AS LocalCost,
	|	(CASE
	|		WHEN &MovingAverageAtGiver THEN TTProducts_1.CostMan
	|		ELSE 0 END)		AS CostMan,
	|
	// Other fields
	|	VALUE(Enum.LotRecordTypes.Supplement)	AS EntryType,
	|	TTProducts_1.RowID						AS RowID,
	|	TTProducts_1.FinRecordID						AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)			AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExpensingToProductionLots)	AS BusinessTransactionSetting,
	|	(CASE
	|		WHEN &MovingAverageAtGiver THEN VALUE(Enum.WaysToCalculateInventoryCost.FromDocument)
	|		ELSE VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef) END)	AS CostDefiningMethod
	|
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT TTProducts_1.ToExpenseAs
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);

	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#Region VATAccounting

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTableTTProducts_1(Query, QueryTexts);
	EndIf;
	
	ValueText_ =
	"SELECT
	|	HeaderData_.Date                  AS Period,
	|	HeaderData_.Ref                AS Ref,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	HeaderData_.MaterialProvider               AS Organization,
	|	HeaderData_.Organization           AS Counterparty,
	|	HeaderData_.Contract               AS Contract,
	|	HeaderData_.Department         AS Department,
	|	HeaderData_.Department         AS AccountingDivision,
	|	HeaderData_.VATTaxation    AS VATTaxation,
	|	CatProductionLots.VATActivityType      AS VATActivityType,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	FALSE                                AS PurchasePerBatchOfProduction,
	|	UNDEFINED                        AS LineOfBusinessOfProductionParty,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Shipper,
	|	HeaderData_.Ref                AS DocumentAcquisitions,
	|	HeaderData_.Ref                AS OriginalTradeDocument,
	|	FALSE                              AS ErrorCorrection,
	|	FALSE                              AS AdjustmentUnderApprovalOfParties,
	|	FALSE                              AS ReduceAmountVATDeduction,
	|	UNDEFINED                      AS PurchaseAdjustmentDocument,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	GoodsTable.VATRate           AS VATRate,
	|	GoodsTable.CCDNumber            AS CCDNumber,
	|	UNDEFINED                      AS ToExpenseAs,
	|	UNDEFINED                      AS ExpenseItem,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	UNDEFINED                      AS ItemOfOtherAssets,
	|	UNDEFINED                      AS AnalyticsOfOtherAssets,
	|	GoodsTable.RowID    AS RowID,
	|	HeaderData_.ARAPObjectOfRecipient.UUID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|FROM
	|	TTProducts_1 AS GoodsTable
	|	
	|	LEFT JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS HeaderData_
	|	ON HeaderData_.Ref = GoodsTable.Ref
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = GoodsTable.ProductionLot
	|WHERE
	|	NOT GoodsTable.ToExpenseAs
	|";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
	ValueText_ = "
	|SELECT
	|	HeaderData_.Date                     AS Period,
	|	HeaderData_.Ref                   AS Ref,
	|	HeaderData_.BusinessOperation    AS BusinessOperation,
	|	HeaderData_.Organization              AS Organization,
	|	HeaderData_.MaterialProvider                  AS Counterparty,
	|	HeaderData_.Contract                  AS Contract,
	|	HeaderData_.Department            AS Department,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Shipper,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS GoodsRecipient,
	|	FALSE                                 AS RetailSaleOfGoods,
	|	HeaderData_.Ref                   AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED                         AS ImplementationAdjustmentDocument,
	|	UNDEFINED                         AS ConsignedGoodsCustomer,
	|	FALSE                                 AS SalesViaCommissionAgent,
	|	FALSE                                 AS ErrorCorrection,
	|	FALSE                                 AS AdjustmentUnderApprovalOfParties,
	|	HeaderData_.ARAPObject           AS ARAPObject,
	|	UNDEFINED                         AS DocumentSaleAdjustment,
	|	HeaderData_.VATTaxation       AS VATTaxation,
	|	GoodsTable.LineNumber            AS LineNumber,
	|	GoodsTable.Products           AS Products,
	|	GoodsTable.Characteristic         AS Characteristic,
	|	GoodsTable.Series                  AS Series,
	|	GoodsTable.VATRate              AS VATRate,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef)   AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	""""                                 AS Content,
	|	GoodsTable.Count             AS Count,
	|	GoodsTable.QuantityByGBRN       AS QuantityByGBRN,
	|	0                                    AS ExciseTaxAmount,
	|	GoodsTable.Products.UnitOfMeasure AS UnitOfMeasure,
	|	GoodsTable.CCDNumber               AS CCDNumber,
	|	GoodsTable.FEACNCode               AS FEACNCode,
	|	GoodsTable.InventoryOwnerAttribute             AS InventoryOwnerAttribute,
	|	GoodsTable.RowID    AS RowID,
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting      AS BusinessTransactionSetting
	|FROM
	|	TTProducts_1 AS GoodsTable
	|	
	|	LEFT JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS HeaderData_
	|	ON GoodsTable.Ref = HeaderData_.Ref
	|WHERE
	|	NOT GoodsTable.ToExpenseAs
	|";
	
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray        - Array of DocumentRef - references to objects that should be printed;
//  PrintParameters       - Structure       - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - The value is a reference to the object, the Presentation is the name of the area in which the object was output (output parameter).
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

// Returns the data required for the printed form "Act of rendering services".
// 
// Parameters:
// 	PrintParameters - Structure - advanced print settings
// 	ObjectsArray  - Array    - references to objects that should be printed
// 	
// Returns:
// 	Structure - Contains data on the header of the document, the tabular part:
// 	* HeaderResults          - QueryResult - 
// 	* ResultForTabularPart - QueryResult - 
//
Function GetDataForPrintedServiceDeliveryReportForm(PrintParameters, ObjectsArray) Export
	
	Query = New Query(
	"SELECT
	|	TableOfGoods.Ref       AS Ref,
	|	TableOfGoods.LineNumber  AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic  AS Characteristic,
	|	TableOfGoods.Products.DescriptionFull AS ServiceNameFull,
	|	TableOfGoods.VATRate    AS VATRate,
	|	TableOfGoods.Price         AS Price,
	|	TableOfGoods.Count   AS Count,
	|	TableOfGoods.Sum        AS Sum,
	|	TableOfGoods.VATAmount     AS VATAmount,
	|	FALSE                        AS ThisIsAProduct
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS TableOfGoods
	|
	|	LEFT JOIN Constants AS Constants
	|	ON TRUE
	|
	|WHERE
	|	TableOfGoods.Ref IN (&DocumentsArray)
	|");
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	ContentTemplate = NStr("vi = 'Dịch vụ xuất xưởng thành phẩm ""%1"" từ nguyên liệu gia công';
							|ru = 'Услуга по выпуску продукции ""%1"" из давальческого сырья';
							|en = 'Service to release the ""%1"" product from provided materials'; fa = 'Service to release the ""%1"" product from provided materials';
							|it = 'Услуга по выпуску продукции ""%1"" из давальческого сырья';
							|pl = 'Service to release the ""%1"" product from provided materials';
							|tr = 'Tedarikçi hammaddelerinden ""%1"" imal edilen ürününün çıkışına yönelik hizmet'");
	TableOfGoods = Query.Execute().Unload();
	For Each CurrentData In TableOfGoods Do
		If CurrentData.ThisIsAProduct Then
			CurrentData.ServiceNameFull = StrTemplate(ContentTemplate, CurrentData.ServiceNameFull);
		EndIf;
	EndDo;
	
	Query.Text =
	"SELECT
	|	ReportToMaterialProvider.Ref                          AS Ref,
	|	ReportToMaterialProvider.Number                           AS Number,
	|	ReportToMaterialProvider.Date                            AS Date,
	|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
	|	ReportToMaterialProvider.MaterialProvider                         AS Counterparty,
	|	ReportToMaterialProvider.Organization                     AS Organization,
	|	ReportToMaterialProvider.Organization.Prefix             AS Prefix,
	|	ReportToMaterialProvider.Currency                          AS Currency,
	|	ReportToMaterialProvider.PriceIncludesVAT                 AS PriceIncludesVAT,
	|	CASE
	|		WHEN ReportToMaterialProvider.VATTaxation IN (&TaxationWithoutVAT)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                         AS ConsiderVAT
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS ReportToMaterialProvider
	|WHERE
	|	ReportToMaterialProvider.Ref IN (&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref                   AS Ref,
	|	TableOfGoods.LineNumber              AS LineNumber,
	|	TableOfGoods.Products             AS Products,
	|	TableOfGoods.ServiceNameFull AS ServiceNameFull,
	|	TableOfGoods.Characteristic           AS Characteristic,
	|	TableOfGoods.VATRate                AS VATRate,
	|	TableOfGoods.Price                     AS Price,
	|	TableOfGoods.Count               AS Count,
	|	TableOfGoods.Sum                    AS Sum,
	|	TableOfGoods.VATAmount                 AS VATAmount
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref                            AS Ref,
	|	TableOfGoods.LineNumber                       AS LineNumber,
	|	TableOfGoods.Products                      AS Products,
	|	TableOfGoods.ServiceNameFull          AS ServiceNameFull,
	|	TableOfGoods.Products.Code                  AS Code,
	|	TableOfGoods.Products.SKU              AS SKU,
	|	TableOfGoods.Products.UnitOfMeasure.Description AS UnitPrice,
	|	TableOfGoods.Products.UnitOfMeasure     AS UnitOfMeasure,
	|	TableOfGoods.Characteristic                    AS Characteristic,
	|	TableOfGoods.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	UNDEFINED                                     AS PackagingName_,
	|	TableOfGoods.VATRate                         AS VATRate,
	|	TableOfGoods.Price                              AS Price,
	|	TableOfGoods.Count                        AS Count,
	|	TableOfGoods.Sum                             AS Sum,
	|	TableOfGoods.VATAmount                          AS VATAmount,
	|	0                                                AS DiscountAmount,
	|	TableOfGoods.Sum                             AS AmountWithoutADiscount,
	|	FALSE                                             AS ThisIsReusablePackage
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS BY
	|	Ref
	|";
	
	Query.SetParameter("TableOfGoods", TableOfGoods);
	TaxationWithoutVAT = New Array();
	TaxationWithoutVAT.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	TaxationWithoutVAT.Add(Enums.VATTaxationTypes.SaleIsSubjectToUTII);
	Query.SetParameter("TaxationWithoutVAT", TaxationWithoutVAT);
	
	ResultsArray = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",          ResultsArray[0]);
	DataStructureForPrinting.Insert("ResultForTabularPart", ResultsArray[2]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref                                            AS Ref,
	|	Documents.Number                                             AS Number,
	|	Documents.Date                                              AS Date,
	|	UNDEFINED                                                AS DocumentBasis,
	|	ISNULL(Documents.SubcontractorAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization                                       AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription           AS Director,
	|	TableResponsiblePersons.DirectorJobTitle              AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription       AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                                       AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.MaterialProvider                                           AS Counterparty,
	|	Documents.MaterialProvider.LegalEntityIndividual                                 AS CounterpartyLegEntInd,
	|	Documents.SubcontractorAccount                       AS BankAccount,
	|	
	|	CASE
	|		WHEN Documents.SubcontractorAccount.ForeignBank
	|			OR Documents.SubcontractorAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|			OR Documents.MaterialProviderAccount.ForeignBank
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                       AS PaymentAbroad,
	|	Documents.SubcontractorAccount.CashCurrency AS CashCurrency,
	|	Documents.SubcontractorAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.SubcontractorAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.SubcontractorAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.SubcontractorAccount.DigitalRoubleAccountID
	|		ELSE Documents.SubcontractorAccount.AccountNumber
	|	END                                                       AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.ManualBankDetailsChange
	|			THEN Documents.SubcontractorAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END                                                       AS BICBank,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.ManualBankDetailsChange
	|			THEN Documents.SubcontractorAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END                                                       AS BankDescription,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.ManualBankDetailsChange
	|			THEN Documents.SubcontractorAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END                                                       AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.ManualBankDetailsChange
	|			THEN Documents.SubcontractorAccount.BankCity
	|		ELSE BankClassifier.City
	|	END                                                       AS BankCity,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END                                                       AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END                                                       AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END                                                       AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END                                                       AS TransferBankCity,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END                                                       AS BankNameInt,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END                                                       AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END                                                       AS BankCityInt,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END                                                       AS BankAddress,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END                                                       AS BankAddressInt,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END                                                       AS CountryOfBank,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END                                                       AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END                                                       AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END                                                       AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END                                                       AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END                                                       AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN Documents.SubcontractorAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END                                                       AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END                                                       AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.SubcontractorAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END                                                       AS NameOfBankSRCCForSettlements,
	|	Documents.SubcontractorAccount.CorrespondentText   AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT                                   AS PriceIncludesVAT,
	|	Documents.Currency                                            AS Currency,
	|	Documents.EmployeeResponsible.Individual                      AS Manager,
	|	Documents.DocumentAmount                                    AS AmountToReturn,
	|	FALSE                                                        AS PartialPayment,
	|	""""                                                        AS PaymentPurposes,
	|	100                                                         AS PayPercentage,
	|	""""                                                        AS AdditionalInformation,
	|	Documents.DocumentAmount                                    AS DocumentAmount,
	|	Documents.Organization                                       AS Shipper,
	|	Documents.MaterialProvider                                           AS GoodsRecipient,
	|	Documents.PaymentID                              AS PaymentID,
	|	FALSE                                                        AS InvoiceToBeRefunded
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS Documents
	|	
	|	LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|	ON Documents.Ref = TableResponsiblePersons.Ref
	|	
	|	LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|	ON Documents.SubcontractorAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|	
	|	LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|	ON Documents.SubcontractorAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	0            AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	0            AS PaymentPercentage,
	|	0            AS PaymentAmount,
	|	FALSE         AS ThisIsDepositForPackage
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref         AS Ref,
	|	Goods.LineNumber    AS LineNumber,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Count     AS Count,
	|	Goods.Price           AS Price,
	|	Goods.Sum          AS Sum,
	|	Goods.VATRate      AS VATRate,
	|	Goods.VATAmount       AS VATAmount
	|INTO TTProducts_1
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS Goods
	|	
	|	LEFT JOIN Constants AS Constants
	|	ON TRUE
	|	
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                        AS Ref,
	|	Goods.LineNumber                   AS LineNumber,
	|	Goods.Products                  AS Products,
	|	Goods.Products.Code              AS Code,
	|	Goods.Products.SKU          AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE 
	|		WHEN &ThisIsMainLanguageOfSystem THEN
	|			PRESENTATION(Goods.Products.UnitOfMeasure)
	|		ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|	END AS UnitOfMeasure,
	|	Goods.Count                    AS Count,
	|	Goods.Price                          AS Price,
	|	Goods.Sum                         AS Sum,
	|	Goods.VATRate                     AS VATRate,
	|	Goods.VATAmount                      AS VATAmount,
	|	Goods.Sum                         AS AmountWithoutADiscount,
	|	UNDEFINED                         AS TypeOfContractorSPrice,
	|	UNDEFINED                         AS Package,
	|	0                                    AS DiscountAmount,
	|	FALSE                                 AS ThisIsReusablePackage
	|FROM
	|	TTProducts_1 AS Goods
	|	
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON Goods.Products = ProductsPresentations.Ref
	|	AND ProductsPresentations.LanguageCode = &LanguageCode
	|	
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|	AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode
	|
	|ORDER BY
	|	Goods.LineNumber
	|";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInIntercampanyDocumentLog

// Returns the text of the hyperlink of the transition from the document log to the workplace for issuing reports to the giver between organizations.
//
// Parameters:
//	Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//  Undefined, FormattedString - the text of the hyperlink of the transition to the workplace for the preparation of reports to the giver between organizations.
Function CreateHyperlinkToDesign(Parameters) Export
	
	BusinessTransactionsAndDocuments = Parameters.BusinessTransactionsAndDocuments;
	
	Filter = New Structure("Filter, PurposeUseKey", True, "ConsumptionReportSubcontractingServicesDeliveredIntercompany");
	BusinessOperationsReports = BusinessTransactionsAndDocuments.FindRows(Filter);
	
	If BusinessOperationsReports.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	RequestParametersForBalances = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRequestingReportBalancesForRegistration();
	RequestParametersForBalances.Organization = Parameters.Organization;
	
	Query = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.RequestRemainingReportsToBeProcessed(RequestParametersForBalances);
	Query = RequestSchemes.SetNumberOfRecordsReceived(Query, 1);
	
	HyperlinkText = NStr("vi = 'Bảng kê dành cho bên đặt gia công';
						|ru = 'Отчеты давальцу';
						|en = 'Consumption reports — Subcontracting services delivered'; fa = 'گزارش‌های مصرف — خدمات پیمانکاری فرعی ارائه‌شده';
						|it = 'Report al fornitore';
						|pl = 'Raporty dla właściciela surowców';
						|tr = 'Tüketim raporu-Verilen fason hizmetleri'");
	
	If Query.Execute().IsEmpty() Then
		Return
			New FormattedString(
					HyperlinkText,,
					StyleColors.EmptyTableField,,
					"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.WorkplaceForm");
	Else
		Return
			New FormattedString(
					HyperlinkText,,,,
					"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.WorkplaceForm");
	EndIf;
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	Return
		New FormattedString(
				NStr("vi = 'Chứng từ giữa các doanh nghiệp (báo cáo cho người đặt gia công)';
					|ru = 'Документы между организациями (отчеты давальцу)';
					|en = 'Intercompany documents (consumption reports — subcontracting services delivered)'; fa = 'Intercompany documents (consumption reports — subcontracting services delivered)';
					|it = 'Документы между организациями (отчеты давальцу)';
					|pl = 'Intercompany documents (consumption reports — subcontracting services delivered)';
					|tr = 'İş yerleri arasındaki belgeler (Tüketim raporu-Verilen fason hizmetleri)'"),,,,
				"DataProcessor.LogOfIntercompanyDocuments.Form.ListForm");
	
EndFunction

#EndRegion

#EndRegion

#EndIf
