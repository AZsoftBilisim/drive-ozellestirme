#Region Public

#Region CalculationDocumentSelectionProceduresAndFunctions

// Filling in the data of the calculation object selection.
//  
// Parameters:
//		ChoiceData - ValueList of CatalogRef.ARAPObjects - The selection data to be filled in.
//		FilterStructure1 - See ARAPAccountingClientServer.SelectionDataSelectionStructure
//		InputByString - Boolean - Indicates that line-by-line input is occurring.
//		ThisIsWhip - Boolean - Unique payment ID
//
Procedure FillInDataOfCalculationObjectSelection(ChoiceData, FilterStructure1, InputByString = True, ThisIsWhip = False) Export
	
	Query = New Query;
	
	QueryConditions = New Array;
	QueryConditions.Add("TRUE");
	QueryConditions.Add("NOT ARAPObjects.IsInternal"); // @query-part
	
	Query.Text = QueryTextOfTemporarySelectionDataTables();
	Query.SetParameter("RecordBranches", FilterStructure1.RecordBranches);
		
	Query.SetParameter("Organization", FilterStructure1.Organization);
	QueryConditions.Add(
		"(ARAPObjects.Organization = &Organization
		|OR 
		|	NOT &Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
		| 	AND ARAPObjects.Contract IN 
		|		(SELECT 
		|			TTCentralizedContracts.Ref 
		|		FROM TTCentralizedContracts)
		|	AND (ARAPObjects.Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
		|		OR ISNULL(Contracts.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed, FALSE))
		|OR 
		|	&Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
		|	AND ARAPObjects.Organization.ParentCompany = &Organization
		|	AND ARAPObjects.Organization.TransactionsUsingParentCompanyAreAllowed)");
	
	If FilterStructure1.OBEntry Then
		
		If FilterStructure1.BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses") Then
			
			QueryConditions.Add("(CAST(ARAPObjects.Object AS Document.SourceDocument).SourceDocumentType = VALUE(Enum.SourceDocumentTypes.CustomerBonusCertificate))");
			
		ElsIf FilterStructure1.BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryVendorBonuses") Then
			
			QueryConditions.Add("(CAST(ARAPObjects.Object AS Document.SourceDocument).SourceDocumentType = VALUE(Enum.SourceDocumentTypes.VendorBonusCertificate))");
			
		Else
			
			Query.SetParameter("ChoosingAdvancePayment", FilterStructure1.ChoosingAdvancePayment);
			QueryConditions.Add("((ARAPObjects.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.Invoice)
				|		OR ARAPObjects.Object REFS Document.SourceDocument
				|			AND CAST(ARAPObjects.Object AS Document.SourceDocument).SourceDocumentType <> VALUE(Enum.SourceDocumentTypes.CustomerBonusCertificate)
				|			AND CAST(ARAPObjects.Object AS Document.SourceDocument).SourceDocumentType <> VALUE(Enum.SourceDocumentTypes.VendorBonusCertificate)
				|			AND NOT &ChoosingAdvancePayment)
				|	AND (ARAPObjects.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.PaymentReturn)
				|		OR (ARAPObjects.Object REFS Document.SourceDocument
				|			OR ARAPObjects.Object REFS Catalog.GiftCertificates
				|			OR ARAPObjects.Object REFS Document.RequestForReturnOfGoodsFromCustomer)
				|			AND &ChoosingAdvancePayment))");
			
		EndIf;
		
	Else
		QueryConditions.Add("
			|(NOT ARAPObjects.Object REFS Catalog.GiftCertificates)");
	EndIf;
	
	If ValueIsFilled(FilterStructure1.PaymentType_) Then
		QueryConditions.Add("ARAPObjects.PaymentType_ = &PaymentType_");
		Query.SetParameter("PaymentType_", FilterStructure1.PaymentType_);
	EndIf;
	
	If ValueIsFilled(FilterStructure1.Counterparty) Then
		If FilterStructure1.OBEntry Then
			QueryConditions.Add("(ARAPObjects.Counterparty IN (&Counterparty)
				|	OR ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract)
				|	AND ISNULL(Contracts.ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers, FALSE)
				|	AND Contracts.Counterparty IN(&Counterparty))");
			QueryConditions.Add("NOT (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract)
				|	AND ISNULL(Contracts.ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers, FALSE)
				|	AND Contracts.CounterpartyCommissionAgent IN(&Counterparty))");
		Else
			QueryConditions.Add("ARAPObjects.Counterparty = &Counterparty");
		EndIf;
		Query.SetParameter("Counterparty", FilterStructure1.Counterparty);
	EndIf;
	
	If ValueIsFilled(FilterStructure1.Text) Then
		If InputByString Then
			Query.SetParameter("SearchString", "%" + FilterStructure1.Text + "%");
			If ThisIsWhip Then
				QueryConditions.Add("ARAPObjects.PaymentID LIKE &SearchString");
			Else
				QueryConditions.Add("ARAPObjects.Number LIKE &SearchString");
			EndIf;
		Else
			Query.SetParameter("SearchString", FilterStructure1.Text);
			If ThisIsWhip Then
				QueryConditions.Add("ARAPObjects.PaymentID IN (&SearchString)");
			Else
				QueryConditions.Add("ARAPObjects.Number IN (&SearchString)");
			EndIf;
		EndIf;
	EndIf;
	
	Query.Text = Query.Text + TextOfRequestToSelectSettlementObject(InputByString);
	
	Query.Text = StrReplace(Query.Text, "&DynamicConditions", StrConcat(QueryConditions, " And ")); 
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		SelectionValue = StructureOfSelectionValue();
		FillPropertyValues(SelectionValue, Selection);
		
		ChoiceData.Add(
			New Structure("Value, DeletionMark", 
				SelectionValue, 
				Selection.State = 2 Or Selection.DeletionMark),
			String(Selection.ARAPObject));
	EndDo;
	
	If InputByString Then
		ChoiceData.SortByPresentation();
	EndIf;
	
EndProcedure

// Filling in the data for selecting the payment basis.
//
// Parameters:
//		ChoiceData - ValueList of DocumentRef - The selection data to be filled in.
//		FilterStructure1 - See ARAPAccountingClientServer.SelectionDataSelectionStructure
//		InputByString - Boolean - Indicates that line-by-line input is occurring.
//		ThisIsWhip - Boolean - Unique payment ID
//
Procedure FillInDataForSelectingPaymentBasis(ChoiceData, FilterStructure1, InputByString = True, ThisIsWhip = False) Export
	
	If Not ValueIsFilled(FilterStructure1.Text) Then
		Return;
	EndIf;
	
	Query = New Query;
	
	UseIntercompanyContracts = GetFunctionalOption("UseIntercompanyContracts");
	TheseAreSettlementsWithClient = FilterStructure1.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	Query.SetParameter("Organization", FilterStructure1.Organization);
	Query.SetParameter("RecordBranches", FilterStructure1.RecordBranches);
	
	ListOfContractsTypes = ?(TheseAreSettlementsWithClient, 
	                         ARAPAccountingClientServer.TypesOfContractsWithClient(),
	                         ARAPAccountingClientServer.TypesOfContractsWithSupplier());
	Query.SetParameter("ContractTypes", ListOfContractsTypes.UnloadValues());
	
	TextOfTTRequestBetweenCompanies = "";
	If ValueIsFilled(FilterStructure1.Counterparty) Then
		Query.SetParameter("Counterparty", FilterStructure1.Counterparty);
		If UseIntercompanyContracts Then
			TextOfTTRequestBetweenCompanies = "
				|SELECT ALLOWED
				|	Companies.Ref AS Ref
				|INTO TTSelectionBetweenCompanies
				|FROM
				|	Catalog.Companies AS Companies
				|WHERE
				|	Companies.Ref IN (&Counterparty)
				|
				|UNION ALL
				|
				|SELECT
				|	Companies.Ref AS Ref
				|FROM
				|	Catalog.Companies AS Companies
				|WHERE
				|	Companies.ParentCompany IN (&Counterparty)
				|	AND Companies.TransactionsUsingParentCompanyAreAllowed
				|;
				|";
		EndIf;
	EndIf;
	
	If FilterStructure1.TypesOfBases_.Count() > 0 Then
		Query.SetParameter("TypesOfBases_", FilterStructure1.TypesOfBases_);
	EndIf;
	
	If InputByString Then
		Query.SetParameter("SearchString", "%" + FilterStructure1.Text + "%");
	Else
		Query.SetParameter("SearchString", FilterStructure1.Text);
	EndIf;
	
	TextOfRequestToSelectPaymentBasis = QueryTextForSelectingPaymentBasisByLine(InputByString, FilterStructure1,
		TheseAreSettlementsWithClient, ThisIsWhip);
	
	Query.Text = QueryTextOfTemporarySelectionDataTables() 
	               + TextOfTTRequestBetweenCompanies
	               + TextOfRequestToSelectPaymentBasis;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		SelectionValue = StructureOfSelectionValue();
		FillPropertyValues(SelectionValue, Selection);
		
		ChoiceData.Add(
			New Structure("Value, DeletionMark", 
				SelectionValue, 
				Selection.State = 2),
			String(Selection.PaymentPurpose));
		
	EndDo;
	
	If InputByString Then
		ChoiceData.SortByPresentation();
		Counter = ChoiceData.Count();
		While Counter > 10 Do
			Counter = Counter - 1;
			ChoiceData.Delete(Counter);
		EndDo;
	EndIf;
	
EndProcedure

// Filling in the payment ID selection data.
//
// Parameters:
//		ChoiceData - ValueList of CatalogRef.ARAPObjects - The selection data to be filled in.
//		FilterStructure1 - See ARAPAccountingClientServer.SelectionDataSelectionStructure
//		InputByString - Boolean - Indicates that line-by-line input is occurring.
//
Procedure FillInUIPSelectionData(ChoiceData, FilterStructure1, InputByString = True) Export
	
	SelectionDataByObjects = New ValueList();
	FillInDataOfCalculationObjectSelection(SelectionDataByObjects, FilterStructure1, InputByString, True);
	FoundUIPS = New Array;
	
	For Each ListItem In SelectionDataByObjects Do
		If FoundUIPS.Find(ListItem.Value.Value.PaymentID) = Undefined Then
			ChoiceData.Add( 
				ListItem.Value, 
				String(ListItem.Value.Value.PaymentID) + " (" + String(ListItem.Value.Value.Counterparty)+ ")");
			FoundUIPS.Add(ListItem.Value.Value.PaymentID);
		EndIf;
	EndDo;
	
	SearchForReasons = False;
	If InputByString Then
		If SelectionDataByObjects.Count() < 10 Then
			SearchForReasons = True;
		EndIf;
	Else
		If TypeOf(FilterStructure1.Text) = Type("Array") Then
			If FoundUIPS.Count() < FilterStructure1.Text.Count() Then
				SearchForReasons = True;
			EndIf;
		Else
			If FoundUIPS.Count() = 0 Then
				SearchForReasons = True;
			EndIf;
		EndIf;
	EndIf;
	
	If SearchForReasons Then
		
		SelectionDataByReason = New ValueList();
		FillInDataForSelectingPaymentBasis(SelectionDataByReason, FilterStructure1, InputByString, True);
		
		For Each ListItem In SelectionDataByReason Do
			If FoundUIPS.Find(ListItem.Value.Value.PaymentID) = Undefined Then
				ChoiceData.Add( 
					ListItem.Value, 
					String(ListItem.Value.Value.PaymentID) + " (" + String(ListItem.Value.Value.Counterparty)+ ")");
				FoundUIPS.Add(ListItem.Value.Value.PaymentID);
			EndIf;
		EndDo;
	EndIf;
	
	If InputByString Then
		ChoiceData.SortByPresentation();
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfFillingOutDocuments

// Deprecated. Procedure for filling in the table part "payment Decryption" on the client's order.
//
// Parameters:
//	FillParameters - See ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption.
//	ARAPDetails - TabularSection, ValueTable - Tabular part of the document, unloading columns of the tabular part of the document.
//	AmountToPay - Number - The amount to be paid, if known.
//	Organization - CatalogRef.Companies - The organization that carries out the sale.
//	BusinessOperation - EnumRef.BusinessTransactions - type of payment document operation.
//
Procedure FillInTranscriptOfPaymentOnClientSOrder(FillParameters, ARAPDetails, AmountToPay = 0, Organization = Undefined, BusinessOperation = Undefined) Export
	
	ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(FillParameters, ARAPDetails, AmountToPay, Organization, BusinessOperation)
	
EndProcedure

// Deprecated. Procedure for filling in the table part "payment Decryption" for the payment invoice.
//
// Parameters:
//	ProformaInvoice - DocumentRef.CustomerCommercialInvoice - The Foundation document.
//	Organization - CatalogRef.Companies - The Foundation document.
//	SalesOrder - DocumentRef.SalesOrder - order.
//	DocumentCurrency - CatalogRef.Currencies - Currency of the cash receipt document.
//	ARAPDetails - TabularSection - the tabular part of the document.
//
Procedure FillInTranscriptOfPaymentOnInvoice(ProformaInvoice, Organization, SalesOrder, DocumentCurrency, ARAPDetails) Export
	
	ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnInvoice(ProformaInvoice, Organization, SalesOrder, DocumentCurrency, ARAPDetails)
	
EndProcedure

// Deprecated. Procedure for filling in the table part "decoding Payment" for the return of goods from the client.
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
	
	ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfPaymentForReturnOfGoodsFromClient(Objects, Organization, DocumentCurrency, DocumentAmount, Partner, ARAPDetails)
	
EndProcedure

// Deprecated. Procedure for filling in the table part "payment Decryption" by order to the supplier.
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
	
	ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(PurchaseOrder, Contract, DocumentCurrency, AmountToPay, ARAPDetails, RequiredPaymentDate, Organization)
	
EndProcedure

// Deprecated. Procedure for filling in the table part "payment Decryption" for the return to the supplier.
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
	
	ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfRefundPaymentToSupplier(Objects, Organization, DocumentCurrency, DocumentAmount, Partner, ARAPDetails)
	
EndProcedure

// Deprecated. Procedure for filling in the table part "payment Decryption" under the agreement.
//
// Parameters:
//		Contract - CatalogRef.CounterpartyContracts - A contract to obtain a residue.
//		DocumentCurrency - CatalogRef.Currencies - the currency of the document.
//		ARAPDetails - ValueTable - the table to fill in.
//		Organization - CatalogRef.Companies - Optional, organization for receiving settlement balances.
//
Procedure FillInTranscriptOfPaymentUnderContractWithSupplier(Contract, DocumentCurrency, ARAPDetails, Organization) Export
	
	ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentUnderContractWithSupplier(Contract, DocumentCurrency, ARAPDetails, Organization)
	
EndProcedure

// The procedure gets the result of a request for the balance of payments with the partner.
//
// Parameters:
//	Organization - CatalogRef.Companies - Organization of the document.
//	Counterparty - CatalogRef.Counterparties - The counterparty selected in the document.
//	DebtType - EnumRef.DebtTypes - Type of debt.
//	PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of calculations.
//	Date - Date - document date.
//	Currency - CatalogRef.Currencies - the currency of the document.
//	Debt_ - ValueTable - Decryption of the payment document.
//
Procedure FillInOutstandingBalances(Organization, Counterparty, DebtType, PaymentType_, Date, Currency, Debt_) Export
	
	TextSettlementsWithClients = 
	"SELECT
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
	|	CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingBalance.ARAPObject.Organization AS Organization,
	|	CustomersARAPAccountingBalance.ARAPObject.Date AS Date,
	|	CustomersARAPAccountingBalance.ARAPObject.Number AS Number,
	|	CustomersARAPAccountingBalance.Currency AS ARAPCurrency,
	|	
	|	
	|	CASE WHEN CustomersARAPAccountingBalance.SumBalance < 0 THEN
	|		-CustomersARAPAccountingBalance.SumBalance
	|	ELSE
	|		CustomersARAPAccountingBalance.SumBalance
	|	END AS AmountARAP,
	|	0 AS Sum
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(&Boundary,
	|		AccountingDimensionByPartners IN (
	|			SELECT
	|				RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners
	|			FROM
	|				InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|			WHERE
	|				RegisterAccountingAnalyticsForPartners.Organization = &Organization
	|				AND RegisterAccountingAnalyticsForPartners.Counterparty = &Counterparty
	|			)
	|		) AS CustomersARAPAccountingBalance
	|	LEFT JOIN 
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON 
	|		CustomersARAPAccountingBalance.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|
	|WHERE
	|	CASE WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsReceivableType)
	|		AND CustomersARAPAccountingBalance.SumBalance >= 0
	|	THEN
	|		TRUE
	|	WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsPayableType)
	|		AND CustomersARAPAccountingBalance.SumBalance <= 0
	|	THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END";
	
	TextSettlementsWithSuppliers = 
	"SELECT
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
	|	VendorsARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingBalance.ARAPObject.Organization AS Organization,
	|	VendorsARAPAccountingBalance.ARAPObject.Date AS Date,
	|	VendorsARAPAccountingBalance.ARAPObject.Number AS Number,
	|	VendorsARAPAccountingBalance.Currency AS ARAPCurrency,
	|	
	|	
	|	CASE WHEN VendorsARAPAccountingBalance.SumBalance < 0 THEN
	|		-VendorsARAPAccountingBalance.SumBalance
	|	ELSE
	|		VendorsARAPAccountingBalance.SumBalance
	|	END AS AmountARAP,
	|	0 AS Sum
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(&Boundary,
	|		AccountingDimensionByPartners IN (
	|			SELECT
	|				RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners
	|			FROM
	|				InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|			WHERE
	|				RegisterAccountingAnalyticsForPartners.Organization = &Organization
	|				AND RegisterAccountingAnalyticsForPartners.Counterparty = &Counterparty
	|			)
	|		) AS VendorsARAPAccountingBalance
	|
	|	LEFT JOIN 
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON 
	|		VendorsARAPAccountingBalance.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|
	|WHERE
	|	CASE WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsReceivableType) 
	|		AND VendorsARAPAccountingBalance.SumBalance >= 0
	|	THEN
	|		TRUE
	|	WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsPayableType)
	|		AND VendorsARAPAccountingBalance.SumBalance <= 0
	|	THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END";
	
	QueryText = "";
	
	If Not ValueIsFilled(PaymentType_) Then
		
		QueryText = TextSettlementsWithClients + "
		|
		|UNION ALL
		|
		|" + TextSettlementsWithSuppliers;
		
	ElsIf PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
		QueryText = TextSettlementsWithClients;
	Else //VendorARAPAccounting
		QueryText = TextSettlementsWithSuppliers;
	EndIf;
	
	QueryText = QueryText + "
	|
	|ORDER BY
	|	DATE,
	|	Number
	|";
	
	Query = New Query(QueryText);
	
	PointInTime = EndOfDay(Date);
	Boundary = New Boundary(PointInTime, BoundaryType.Including);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Boundary", Boundary);
	Query.SetParameter("DebtType", DebtType);
	
	Debt_.Clear();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If ValueIsFilled(Currency)
		 And Currency <> Selection.ARAPCurrency Then
		
			Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
			        	Selection.AmountARAP,
			        	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
			        	Selection.ARAPCurrency,
			        	Currency,
			        	PointInTime,
			        	Selection.ARAPObject);
		
		Else
			Sum = Selection.AmountARAP;
		EndIf;
		
		If Sum <> 0 Then
			NewRow = Debt_.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Sum = Sum;
		EndIf;
		
	EndDo;
	
EndProcedure

// The procedure receives the result of a request for the balance of payments with the partner for documents.
//
// Parameters:
//	Organization - CatalogRef.Companies - Organization of the document.
//	Counterparty - CatalogRef.Counterparties - The counterparty selected in the document.
//	DebtType - EnumRef.DebtTypes - Type of debt.
//	PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of calculations.
//	Date - Date - document date.
//	Currency - CatalogRef.Currencies - the currency of the document.
//	Debt_ - FormDataCollection - the tabular part of the document.
//
Procedure FillInDebtOnBalanceOfSettlements(Organization, Counterparty, DebtType, PaymentType_, Date, Currency, Debt_) Export
	
	Debt_.Clear();
	
	TextTTAnalytics = 
	"SELECT
	|	Companies.Ref AS Ref
	|INTO TTOrganizations
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.ParentCompany = &Organization
	|	AND Companies.TransactionsUsingParentCompanyAreAllowed
	|	AND Companies.BranchOffice
	|	OR Companies.Ref = &Organization
	|;
	|SELECT
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners
	|INTO TTAnalytics_
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		INNER JOIN TTOrganizations
	|			ON TTOrganizations.Ref = RegisterAccountingAnalyticsForPartners.Organization
	|WHERE
	|	RegisterAccountingAnalyticsForPartners.Counterparty = &Counterparty
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		TextSettlementsWithClients = 
		
		"SELECT ALLOWED
		|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
		|	RegisterAccountingAnalyticsForPartners.Partner     AS Partner,
		|	RegisterAccountingAnalyticsForPartners.LineOfBusiness AS LineOfBusiness,
		|	RegisterAccountingAnalyticsForPartners.Organization AS Organization,
		|	CustomersARAPAccountingBalance.SalesOrder        AS ARAPObject,
		|	CustomersARAPAccountingBalance.Currency              AS ARAPCurrency,
		|	CustomersARAPAccountingBalance.ARAPDocument AS ARAPDocument,
		|	
		|	CASE WHEN CustomersARAPAccountingBalance.DebtBalance + CustomersARAPAccountingBalance.PrepaymentBalance < 0 THEN
		|		-(CustomersARAPAccountingBalance.DebtBalance + CustomersARAPAccountingBalance.PrepaymentBalance)
		|	ELSE
		|		CustomersARAPAccountingBalance.DebtBalance + CustomersARAPAccountingBalance.PrepaymentBalance
		|	END AS AmountARAP,
		|
		|	CASE WHEN CustomersARAPAccountingBalance.DebtLocalBalance + CustomersARAPAccountingBalance.PrepaymentLocalBalance < 0 THEN
		|		-(CustomersARAPAccountingBalance.DebtLocalBalance + CustomersARAPAccountingBalance.PrepaymentLocalBalance)
		|	ELSE
		|		CustomersARAPAccountingBalance.DebtLocalBalance + CustomersARAPAccountingBalance.PrepaymentLocalBalance
		|	END AS SumCompl,
		|
		|	CASE WHEN CustomersARAPAccountingBalance.ARAPManBalance + CustomersARAPAccountingBalance.PrepaymentManBalance < 0 THEN
		|		-(CustomersARAPAccountingBalance.ARAPManBalance + CustomersARAPAccountingBalance.PrepaymentManBalance)
		|	ELSE
		|		CustomersARAPAccountingBalance.ARAPManBalance + CustomersARAPAccountingBalance.PrepaymentManBalance
		|	END AS SumMan
		|
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&Boundary,
		|		AccountingDimensionByPartners IN (
		|			SELECT
		|				TTAnalytics_.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)
		|		) AS CustomersARAPAccountingBalance
		|	LEFT JOIN 
		|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|	ON 
		|		CustomersARAPAccountingBalance.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
		|
		|WHERE
		|	CASE WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsReceivableType)
		|		AND (CustomersARAPAccountingBalance.DebtBalance > 0 OR CustomersARAPAccountingBalance.PrepaymentBalance > 0)
		|	THEN
		|		TRUE
		|	WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsPayableType)
		|		AND (CustomersARAPAccountingBalance.DebtBalance < 0 OR CustomersARAPAccountingBalance.PrepaymentBalance < 0)
		|	THEN
		|		TRUE
		|	ELSE
		|		FALSE
		|	END";
		
		TextSettlementsWithSuppliers = 
		"SELECT ALLOWED
		|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
		|	RegisterAccountingAnalyticsForPartners.Partner     AS Partner,
		|	RegisterAccountingAnalyticsForPartners.LineOfBusiness AS LineOfBusiness,
		|	RegisterAccountingAnalyticsForPartners.Organization AS Organization,
		|	VendorsARAPAccountingBalance.PurchaseOrder  AS ARAPObject,
		|	VendorsARAPAccountingBalance.Currency           AS ARAPCurrency,
		|	VendorsARAPAccountingBalance.ARAPDocument AS ARAPDocument,
		|	
		|	CASE WHEN VendorsARAPAccountingBalance.DebtBalance + VendorsARAPAccountingBalance.PrepaymentBalance < 0 THEN
		|		-(VendorsARAPAccountingBalance.DebtBalance + VendorsARAPAccountingBalance.PrepaymentBalance)
		|	ELSE
		|		VendorsARAPAccountingBalance.DebtBalance + VendorsARAPAccountingBalance.PrepaymentBalance
		|	END AS AmountARAP,
		|	
		|	CASE WHEN VendorsARAPAccountingBalance.DebtLocalBalance + VendorsARAPAccountingBalance.PrepaymentLocalBalance < 0 THEN
		|		-(VendorsARAPAccountingBalance.DebtLocalBalance + VendorsARAPAccountingBalance.PrepaymentLocalBalance)
		|	ELSE
		|		VendorsARAPAccountingBalance.DebtLocalBalance + VendorsARAPAccountingBalance.PrepaymentLocalBalance
		|	END AS SumCompl,
		|
		|	CASE WHEN VendorsARAPAccountingBalance.ARAPManBalance + VendorsARAPAccountingBalance.PrepaymentManBalance < 0 THEN
		|		-(VendorsARAPAccountingBalance.ARAPManBalance + VendorsARAPAccountingBalance.PrepaymentManBalance)
		|	ELSE
		|		VendorsARAPAccountingBalance.ARAPManBalance + VendorsARAPAccountingBalance.PrepaymentManBalance
		|	END AS SumMan
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(&Boundary,
		|		AccountingDimensionByPartners IN (
		|			SELECT
		|				TTAnalytics_.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)
		|		) AS VendorsARAPAccountingBalance
		|
		|	LEFT JOIN 
		|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|	ON 
		|		VendorsARAPAccountingBalance.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
		|
		|WHERE
		|	CASE WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsReceivableType) 
		|		AND (VendorsARAPAccountingBalance.DebtBalance > 0 OR VendorsARAPAccountingBalance.PrepaymentBalance > 0)
		|	THEN
		|		TRUE
		|	WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsPayableType)
		|		AND (VendorsARAPAccountingBalance.DebtBalance < 0 OR VendorsARAPAccountingBalance.PrepaymentBalance < 0)
		|	THEN
		|		TRUE
		|	ELSE
		|		FALSE
		|	END";
		
		QueryText = "";
		
		If Not ValueIsFilled(PaymentType_) Then
			
			QueryText = TextTTAnalytics + TextSettlementsWithClients + "
			|
			|UNION ALL
			|
			|" + TextSettlementsWithSuppliers;
			
		ElsIf PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			QueryText = TextTTAnalytics + TextSettlementsWithClients;
		Else
			QueryText = TextTTAnalytics + TextSettlementsWithSuppliers;
		EndIf;
		
		Query = New Query(QueryText);
		
		PointInTime = EndOfDay(Date);
		Boundary = New Boundary(PointInTime, BoundaryType.Including);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("Counterparty", Counterparty);
		Query.SetParameter("Boundary", Boundary);
		Query.SetParameter("DebtType", DebtType);
		
	Else
		
		TextSettlementsWithClients = "
			|SELECT ALLOWED
			|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
			|	RegisterAccountingAnalyticsForPartners.Partner     AS Partner,
			|	RegisterAccountingAnalyticsForPartners.LineOfBusiness AS LineOfBusiness,
			|	RegisterAccountingAnalyticsForPartners.Organization AS Organization,
			|	CustomersARAPAccountingBalance.ARAPObject      AS ARAPObject,
			|	CustomersARAPAccountingBalance.Currency              AS ARAPCurrency,
			|	
			|	CustomersARAPAccountingBalance.DebtBalance + CustomersARAPAccountingBalance.PrepaymentBalance AS AmountARAP,
			|	CustomersARAPAccountingBalance.DebtLocalBalance + CustomersARAPAccountingBalance.PrepaymentLocalBalance AS SumCompl,
			|	CustomersARAPAccountingBalance.ARAPManBalance + CustomersARAPAccountingBalance.PrepaymentManBalance AS SumMan
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&Boundary,
			|		&Currency
			|		AND AccountingDimensionByPartners IN (
			|			SELECT
			|				TTAnalytics_.AccountingDimensionByPartners AS AccountingDimensionByPartners
			|			FROM
			|				TTAnalytics_ AS TTAnalytics_)
			|		) AS CustomersARAPAccountingBalance
			|	LEFT JOIN 
			|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
			|	ON
			|		CustomersARAPAccountingBalance.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
			|WHERE
			|	CASE WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsReceivableType)
			|		AND CustomersARAPAccountingBalance.DebtBalance > 0
			|	THEN
			|		TRUE
			|	WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsPayableType)
			|		AND CustomersARAPAccountingBalance.PrepaymentBalance > 0
			|	THEN
			|		TRUE
			|	ELSE
			|		FALSE
			|	END";
		
		TextSettlementsWithSuppliers = "
			|SELECT ALLOWED
			|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
			|	RegisterAccountingAnalyticsForPartners.Partner          AS Partner,
			|	RegisterAccountingAnalyticsForPartners.LineOfBusiness AS LineOfBusiness,
			|	RegisterAccountingAnalyticsForPartners.Organization      AS Organization,
			|	VendorsARAPAccountingBalance.ARAPObject   AS ARAPObject,
			|	VendorsARAPAccountingBalance.Currency           AS ARAPCurrency,
			|	
			|	VendorsARAPAccountingBalance.DebtBalance + VendorsARAPAccountingBalance.PrepaymentBalance AS AmountARAP,
			|	VendorsARAPAccountingBalance.DebtLocalBalance + VendorsARAPAccountingBalance.PrepaymentLocalBalance AS SumCompl,
			|	VendorsARAPAccountingBalance.ARAPManBalance + VendorsARAPAccountingBalance.PrepaymentManBalance AS SumMan
			|FROM
			|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&Boundary,
			|		&Currency
			|		AND AccountingDimensionByPartners IN (
			|			SELECT
			|				TTAnalytics_.AccountingDimensionByPartners AS AccountingDimensionByPartners
			|			FROM
			|				TTAnalytics_ AS TTAnalytics_)
			|		) AS VendorsARAPAccountingBalance
			|	LEFT JOIN 
			|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
			|	ON
			|		VendorsARAPAccountingBalance.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
			|WHERE
			|	CASE WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsReceivableType) 
			|		AND VendorsARAPAccountingBalance.PrepaymentBalance > 0
			|	THEN
			|		TRUE
			|	WHEN &DebtType = VALUE(Enum.DebtTypes.AccountsPayableType)
			|		AND VendorsARAPAccountingBalance.DebtBalance > 0
			|	THEN
			|		TRUE
			|	ELSE
			|		FALSE
			|	END";
		
		Query     = New Query;
		
		PointInTime = EndOfDay(Date);
		Boundary = New Boundary(PointInTime, BoundaryType.Including);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("Counterparty", Counterparty);
		Query.SetParameter("Boundary", Boundary);
		Query.SetParameter("DebtType", DebtType);
		Query.SetParameter("Currency", Currency);
		
		If Not ValueIsFilled(PaymentType_) Then
			QueryText = TextTTAnalytics + TextSettlementsWithClients + "
			|
			|UNION ALL
			|
			|" + TextSettlementsWithSuppliers;
		ElsIf PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			QueryText =  TextTTAnalytics + TextSettlementsWithClients;
		Else
			QueryText = TextTTAnalytics + TextSettlementsWithSuppliers;
		EndIf;
		
		If ValueIsFilled(Currency) Then
			QueryText = StrReplace(QueryText, "&Currency", "Currency = &Currency");
		Else
			QueryText = StrReplace(QueryText, "&Currency", "TRUE");
		EndIf;
		
		Query.Text = QueryText;
		
	EndIf;
	
	Balance = Query.Execute().Unload();
	Balance.GroupBy("PaymentType_, Partner, LineOfBusiness,Organization, ARAPObject, ARAPCurrency","AmountARAP, SumCompl, SumMan");
	
	For Each RemainderLine_ In Balance Do
		
		NewRow = Debt_.Add();
		FillPropertyValues(NewRow, RemainderLine_);
		
	EndDo;
	
EndProcedure

// Deprecated. Recalculates the amount of the payment decryption to the selected currency.
//
// Parameters:
//		Object - DocumentObject - Document for recalculating the amount.
//		AmountTotal - Number - the amount of the document.
//
Procedure ConvertAmountsToCurrencyPaymentDecryption(Object, AmountTotal) Export
	
	ARAPAccountingARAPDetailsFillingIn.ConvertAmountsToCurrencyPaymentDecryption(Object, AmountTotal);
	
EndProcedure

// This function determines the order of payment in a foreign currency.
//
// Parameters:
//  CurrencyOfPayment - CatalogRef.Currencies - Optional, the currency of the intended payment.
//  Organization - CatalogRef.Companies - Optional, defines the currency of regulated accounting.
//
// Returns:
//  Boolean - payment is made in a foreign currency.
//
Function GetPaidInDefaultCurrency(Val CurrencyOfPayment = Undefined, Val Organization = Undefined) Export
	
	If ValueIsFilled(Organization) Then
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Else
		LocalAccountingCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	If Not ValueIsFilled(CurrencyOfPayment) Then
		CurrencyOfPayment = LocalAccountingCurrency;
	EndIf;
	
	If Not CurrencyOfPayment = LocalAccountingCurrency Then
		ForeignCurrencyTransaction = True;
	Else
		ForeignCurrencyTransaction = False;
	EndIf;
	
	Return ForeignCurrencyTransaction;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsOfFormingRegisteredRecordsForSettlementsWithCounterparties

// The procedure fills in the amount of mutual settlements in the table part "payment Transcript"
// in the cash flow documents.
//
// Parameters:
//	Currency - CatalogRef.Currencies - The currency specified in the document.
//	Date - Date - document date.
//	TabularSection - TabularSection - the tabular part of the document.
//	Organization - CatalogRef.Companies - Document organization. Determines the base currency for receiving rates.
Procedure FillInAmountOfSettlementsInTablePart(Currency, Date, TabularSection, Organization) Export
	
	// If the tabular part is empty or the amount of settlements is filled in the tabular part,
	// then the procedure is not required.
	If (TabularSection.Count() = 0
	 Or TabularSection.Find(0, "AmountARAP") = Undefined)
	 And TabularSection.Find(Catalogs.Currencies.EmptyRef(), "ARAPCurrency") = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	*
	|INTO SourceDocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|WHERE
	|	DocumentTable.AmountARAP = 0
	|	OR DocumentTable.ARAPCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.*,
	|	Table.Currency AS Currency,
	|	Table.ARAPObject AS ARAPObject,
	|		
	|	CASE WHEN Table.Partner = VALUE(Catalog.Partners.EmptyRef) THEN
	|		Table.ARAPObject.Partner
	|	ELSE
	|		Table.Partner
	|	END AS Partner,
	|	
	|	CASE WHEN Table.ARAPCurrency <> VALUE(Catalog.Currencies.EmptyRef) THEN
	|		Table.ARAPCurrency
	|	ELSE
	|		CASE WHEN Table.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef) THEN
	|			Table.ARAPObject.ARAPCurrency
	|		ELSE
	|			&Currency
	|		END
	|	END AS ARAPCurrency
	|	
	|INTO DocumentTable
	|FROM
	|	SourceDocumentTable AS Table
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractCourse.Period AS Period,
	|	ContractCourse.Contract AS Contract,
	|	ContractCourse.CourseNumerator AS CourseNumerator,
	|	ContractCourse.CourseDenominator AS CourseDenominator
	|INTO ContractTTCourses
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&Date) AS ContractCourse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable)) = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|			THEN VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		ELSE ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable))
	|	END AS ContractRateOption,
	|	ARAPObjects.ARAPObjectType AS ARAPObjectType,
	|	DocumentCourses.RateARAPCurrencyNumerator AS RateARAPCurrencyNumerator,
	|	DocumentCourses.RateARAPCurrencyDenominator AS RateARAPCurrencyDenominator,
	|	DocumentCourses.RateManagementAccountingCurrencyNumerator AS RateManagementAccountingCurrencyNumerator,
	|	DocumentCourses.RateManagementAccountingCurrencyDenominator AS RateManagementAccountingCurrencyDenominator,
	|	DocumentCourses.RateDocumentCurrencyNumerator AS RateDocumentCurrencyNumerator,
	|	DocumentCourses.RateDocumentCurrencyDenominator AS RateDocumentCurrencyDenominator,
	|	DocumentCourses.DocumentCurrency AS DocumentCurrency,
	|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
	|	ARAPObjects.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	ARAPObjects.Date AS Date,
	|	ISNULL(ContractRates.Period, DATETIME(1, 1, 1)) AS ContractCoursePeriod,
	|	ContractRates.CourseNumerator AS ExchangeRateNumeratorOfContractCurrency,
	|	ContractRates.CourseDenominator AS ExchangeRateDenominatorOfContractCurrency
	|INTO CalculationObjectData
	|FROM
	|	DocumentTable AS DocumentTable
	|	INNER JOIN 
	|		Catalog.ARAPObjects AS ARAPObjects 
	|		ON DocumentTable.ARAPObject = ARAPObjects.Ref
	|		LEFT JOIN InformationRegister.DocumentCurrenciesAndRates AS DocumentCourses
	|		ON ARAPObjects.Object = DocumentCourses.Document
	|		LEFT JOIN ContractTTCourses AS ContractRates
	|		ON ARAPObjects.Contract = ContractRates.Contract
	|WHERE 
	|	DocumentTable.AmountARAP = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	ExchangeRates.ARAPObject AS ARAPObject,
	|	ExchangeRates.DocumentCurrency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	ExchangeRates.DateOfCourse AS DateOfCourse,
	|	MAX(ExchangeRates.CourseNumerator) AS CourseNumerator,
	|	MAX(ExchangeRates.CourseDenominator) AS CourseDenominator
	|INTO TTExchangeRates
	|FROM (
	|	SELECT 
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.DocumentCurrency AS DocumentCurrency,
	|		CalculationObjectData.LocalAccountingCurrency AS BaseCurrency,
	|		CalculationObjectData.Date AS DateOfCourse,
	|		CalculationObjectData.RateDocumentCurrencyNumerator AS CourseNumerator,
	|		CalculationObjectData.RateDocumentCurrencyDenominator AS CourseDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND CalculationObjectData.DocumentCurrency = &Currency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.DocumentCurrency AS Currency,
	|		CalculationObjectData.LocalAccountingCurrency AS BaseCurrency,
	|		CalculationObjectData.Date AS DateOfCourse,
	|		CalculationObjectData.RateDocumentCurrencyNumerator AS CourseNumerator,
	|		CalculationObjectData.RateDocumentCurrencyDenominator AS CourseDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND CalculationObjectData.DocumentCurrency IN (SELECT T.ARAPCurrency FROM DocumentTable AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.DocumentCurrency AS Currency,
	|		CalculationObjectData.LocalAccountingCurrency AS BaseCurrency,
	|		CalculationObjectData.Date AS DateOfCourse,
	|		CalculationObjectData.RateDocumentCurrencyNumerator AS CourseNumerator,
	|		CalculationObjectData.RateDocumentCurrencyDenominator AS CourseDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND CalculationObjectData.DocumentCurrency IN (SELECT T.Currency FROM DocumentTable AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.Date,
	|		CalculationObjectData.RateARAPCurrencyNumerator,
	|		CalculationObjectData.RateARAPCurrencyDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND CalculationObjectData.ARAPCurrency = &Currency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.Date,
	|		CalculationObjectData.RateARAPCurrencyNumerator,
	|		CalculationObjectData.RateARAPCurrencyDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND CalculationObjectData.ARAPCurrency IN (SELECT T.ARAPCurrency FROM DocumentTable AS T)
	|	
	|		UNION ALL
	|	
	|	SELECT
	|			CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.Date,
	|		CalculationObjectData.RateARAPCurrencyNumerator,
	|		CalculationObjectData.RateARAPCurrencyDenominator
	|		FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND CalculationObjectData.ARAPCurrency IN (SELECT T.Currency FROM DocumentTable AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		&CurrencyOfMan,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.Date,
	|		CalculationObjectData.RateManagementAccountingCurrencyNumerator,
	|		CalculationObjectData.RateManagementAccountingCurrencyDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND &CurrencyOfMan = &Currency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		&CurrencyOfMan,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.Date,
	|		CalculationObjectData.RateManagementAccountingCurrencyNumerator,
	|		CalculationObjectData.RateManagementAccountingCurrencyDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND &CurrencyOfMan IN (SELECT T.ARAPCurrency FROM DocumentTable AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		&CurrencyOfMan,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.Date,
	|		CalculationObjectData.RateManagementAccountingCurrencyNumerator,
	|		CalculationObjectData.RateManagementAccountingCurrencyDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND &CurrencyOfMan IN (SELECT T.Currency FROM DocumentTable AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.ContractCoursePeriod,
	|		CalculationObjectData.ExchangeRateNumeratorOfContractCurrency,
	|		CalculationObjectData.ExchangeRateDenominatorOfContractCurrency
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		AND CalculationObjectData.ARAPCurrency = &Currency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.ContractCoursePeriod,
	|		CalculationObjectData.ExchangeRateNumeratorOfContractCurrency,
	|		CalculationObjectData.ExchangeRateDenominatorOfContractCurrency
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		AND CalculationObjectData.ARAPCurrency IN (SELECT T.Currency FROM DocumentTable AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		CalculationObjectData.LocalAccountingCurrency,
	|		CalculationObjectData.ContractCoursePeriod,
	|		CalculationObjectData.ExchangeRateNumeratorOfContractCurrency,
	|		CalculationObjectData.ExchangeRateDenominatorOfContractCurrency
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|	WHERE
	|		CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		AND CalculationObjectData.ARAPCurrency IN (SELECT T.ARAPCurrency FROM DocumentTable AS T)) AS ExchangeRates
	|GROUP BY
	|	ExchangeRates.ARAPObject,
	|	ExchangeRates.DocumentCurrency,
	|	ExchangeRates.BaseCurrency,
	|	ExchangeRates.DateOfCourse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|	
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.ARAPCurrency AS ARAPCurrency,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	DocumentTable.Partner AS Partner,
	|
	|	CASE WHEN DocumentTable.AmountARAP = 0 AND MultiCurrencyDocumentExchangeRates.CourseNumerator IS NULL THEN
	|		(DocumentTable.Sum *
	|		ISNULL(TTExchangeRatesOfDocument.CourseNumerator, ISNULL(DocumentExchangeRates.CourseNumerator, 1)) * 
	|		ISNULL(TTExchangeRates.CourseDenominator, ISNULL(ExchangeRates.CourseDenominator, 1))
	|		) / (
	|		ISNULL(TTExchangeRates.CourseNumerator, ISNULL(ExchangeRates.CourseNumerator, 1)) * 
	|		ISNULL(TTExchangeRatesOfDocument.CourseDenominator, ISNULL(DocumentExchangeRates.CourseDenominator, 1))
	|		)
	|	WHEN DocumentTable.AmountARAP = 0 AND NOT MultiCurrencyDocumentExchangeRates.CourseNumerator IS NULL THEN
	|		(DocumentTable.Sum *
	|		ISNULL(TTMultiCurrencyDocumentExchangeRates.CourseNumerator, ISNULL(MultiCurrencyDocumentExchangeRates.CourseNumerator, 1)) * 
	|		ISNULL(TTExchangeRates.CourseDenominator, ISNULL(ExchangeRates.CourseDenominator, 1))
	|		) / (
	|		ISNULL(TTExchangeRates.CourseNumerator, ISNULL(ExchangeRates.CourseNumerator, 1)) * 
	|		ISNULL(TTMultiCurrencyDocumentExchangeRates.CourseDenominator, ISNULL(MultiCurrencyDocumentExchangeRates.CourseDenominator, 1))
	|		)
	|	ELSE
	|		DocumentTable.AmountARAP
	|	END AS AmountARAP
	|FROM
	|	DocumentTable AS DocumentTable
	|	
	|	// Let's determine the currency exchange rate of the document.
	|	LEFT JOIN
	|		TTExchangeRates AS TTExchangeRatesOfDocument
	|	ON DocumentTable.ARAPObject = TTExchangeRatesOfDocument.ARAPObject
	|		AND TTExchangeRatesOfDocument.Currency = &Currency	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS DocumentExchangeRates
	|	ON
	|		TRUE
	|	
	|	// Let's determine the currency exchange rate of the document
	|	LEFT JOIN
	|		TTExchangeRates AS TTMultiCurrencyDocumentExchangeRates
	|	ON DocumentTable.ARAPObject = TTMultiCurrencyDocumentExchangeRates.ARAPObject
	|		AND DocumentTable.Currency = TTMultiCurrencyDocumentExchangeRates.Currency	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS MultiCurrencyDocumentExchangeRates
	|	ON
	|		DocumentTable.Currency = MultiCurrencyDocumentExchangeRates.Currency
	|		
	|	// Let's determine the exchange rate of mutual settlements.
	|	LEFT JOIN
	|		TTExchangeRates AS TTExchangeRates
	|	ON DocumentTable.ARAPObject = TTExchangeRates.ARAPObject
	|		AND DocumentTable.ARAPCurrency = TTExchangeRates.Currency	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS ExchangeRates
	|	ON
	|		DocumentTable.ARAPCurrency = ExchangeRates.Currency
	|
	|ORDER BY
	|	DocumentTable.LineNumber
	|;
	|");
	Query.SetParameter("Date", Date);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	Query.SetParameter("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	
	DocumentTable = TabularSection.Unload();
	If DocumentTable.Columns.Find("Partner") = Undefined Then
		DocumentTable.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
	EndIf;
	If DocumentTable.Columns.Find("Currency") = Undefined Then
		DocumentTable.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	EndIf;
	
	Query.SetParameter("DocumentTable", DocumentTable);
	
	// We will get a table of the document with the calculated amount of mutual settlements.
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TableRow = TabularSection.Find(Selection.LineNumber, "LineNumber");
		FillPropertyValues(TableRow, Selection, ,"LineNumber");
		
	EndDo;
	
EndProcedure

// Deprecated.
// The procedure fills in the amount of settlements in the header of the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	TSName - String - Optional, name of the table part for calculating the document amount
//	RateStructure - Structure - Optional, document course parameters:
//       * CourseNumerator - Number - The exchange rate is the numerator of the currency.
//       * CourseDenominator - Number - The exchange rate is the denominator of the currency.
//	Date - Date - The date on which the course will be received, if the course structure is not set.
// 
Procedure FillInAmountOfSettlements(DocumentObject, TSName = "", RateStructure = Undefined, Date = Undefined) Export
	
	If ValueIsFilled(TSName) Then
		DocumentAmount = DocumentObject[TSName].Total("Sum");
		If Not DocumentObject.PriceIncludesVAT Then
			DocumentAmount = DocumentAmount + DocumentObject[TSName].Total("VATAmount");
		EndIf;
	Else
		DocumentAmount = DocumentObject.DocumentAmount;
	EndIf;
	
	If Not ValueIsFilled(Date) Then
		Date = DocumentObject.Date;
	EndIf;
	
	If ValueIsFilled(RateStructure) And TypeOf(RateStructure) = Type("Structure") Then
		
		ComplAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
		
		If  DocumentObject.Currency = ComplAccountingCurrency And Not DocumentObject.ARAPCurrency = ComplAccountingCurrency Then
			RateDocumentCurrencyNumerator = 1;
			RateDocumentCurrencyDenominator = 1;
			RateARAPCurrencyNumerator = RateStructure.CourseNumerator;
			RateARAPCurrencyDenominator = RateStructure.CourseDenominator;
		Else
			RateDocumentCurrencyNumerator = RateStructure.CourseNumerator;
			RateDocumentCurrencyDenominator  = RateStructure.CourseDenominator;
			RateARAPCurrencyNumerator = 1;
			RateARAPCurrencyDenominator = 1;
		EndIf;
		
		CurrencySettingsDoc = New Structure("Currency, CourseNumerator, CourseDenominator",
				DocumentObject.Currency, RateDocumentCurrencyNumerator, RateDocumentCurrencyDenominator);
		TDCurrencySettings  = New Structure("Currency, CourseNumerator, CourseDenominator",
				DocumentObject.ARAPCurrency, RateARAPCurrencyNumerator, RateARAPCurrencyDenominator);
			
		DocumentObject.AmountARAP = ProcessingOfExchangeRatesTM.ConvertAtRate(DocumentAmount,
				CurrencySettingsDoc,TDCurrencySettings);
			
	Else
		
		Query = New Query("
		|SELECT
		|	(&DocumentAmount *
		|	ISNULL(DocumentExchangeRates.CourseNumerator, 1) * 
		|	ISNULL(ExchangeRates.CourseDenominator, 1)
		|	) / (
		|	ISNULL(ExchangeRates.CourseNumerator, 1) * 
		|	ISNULL(DocumentExchangeRates.CourseDenominator, 1)
		|	) AS AmountARAP
		|	
		|FROM	
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date,
		|		Currency = &DocumentCurrency AND BaseCurrency = &BaseCurrency
		|	) AS DocumentExchangeRates
		|	
		|	// Let's determine the exchange rate of mutual settlements.
		|	LEFT JOIN
		|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, 
		|			Currency = &ARAPCurrency AND BaseCurrency = &BaseCurrency
		|	) AS ExchangeRates ON TRUE
		|");
		
		Query.SetParameter("Date", Date);
		Query.SetParameter("DocumentCurrency", DocumentObject.Currency);
		Query.SetParameter("ARAPCurrency", DocumentObject.ARAPCurrency);
		Query.SetParameter("DocumentAmount", DocumentAmount);
		Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization));
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			If DocumentObject.AmountARAP <> Selection.AmountARAP Then
				DocumentObject.AmountARAP = Selection.AmountARAP;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Deprecated.
// The procedure fills in the amount of settlements in the header of the document.
//
// Parameters:
// DocumentObject - DocumentObject - Current document
// TSName - String - Optional, name of the table part where the settlement amount is calculated
// RateStructure - Structure - Optional, document course parameters:
//       * CourseNumerator   - Number - Exchange rate currency numerator
//       * CourseDenominator - Number - Exchange rate denominator of the currency
//
Procedure FillInAmountOfSettlementsInReceipt(DocumentObject, TSName = "Goods", RateStructure = Undefined) Export
	
	If DocumentObject[TSName].FindRows(New Structure("AmountARAP", 0)).Count()=0 Then
		
		DocumentObject.AmountARAP = DocumentObject[TSName].Total("AmountARAP");
		
	Else
		
		DocumentAmount = DocumentObject[TSName].Total("Sum");
		If Not DocumentObject.PriceIncludesVAT Then
			DocumentAmount = DocumentAmount + DocumentObject[TSName].Total("VATAmount");
		EndIf;
		
		If ValueIsFilled(RateStructure) And TypeOf(RateStructure) = Type("Structure") Then
			
			ComplAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
			
			If DocumentObject.Currency = ComplAccountingCurrency And Not DocumentObject.ARAPCurrency = ComplAccountingCurrency Then
				RateDocumentCurrencyNumerator = 1;
				RateDocumentCurrencyDenominator = 1;
				RateARAPCurrencyNumerator = RateStructure.CourseNumerator;
				RateARAPCurrencyDenominator = RateStructure.CourseDenominator;
			Else
				RateDocumentCurrencyNumerator = RateStructure.CourseNumerator;
				RateDocumentCurrencyDenominator = RateStructure.CourseDenominator;
				RateARAPCurrencyNumerator = 1;
				RateARAPCurrencyDenominator = 1;
			EndIf;
			
			CurrencySettingsDoc = New Structure("Currency, CourseNumerator, CourseDenominator",
				DocumentObject.Currency, RateDocumentCurrencyNumerator, RateDocumentCurrencyDenominator);
			TDCurrencySettings  = New Structure("Currency, CourseNumerator, CourseDenominator",
				DocumentObject.ARAPCurrency, RateARAPCurrencyNumerator, RateARAPCurrencyDenominator);
			
			DocumentObject.AmountARAP = ProcessingOfExchangeRatesTM.ConvertAtRate(DocumentAmount,
				CurrencySettingsDoc,TDCurrencySettings);
			
		Else
			
			Query = New Query("
			|SELECT
			|	(&DocumentAmount *
			|	ISNULL(DocumentExchangeRates.CourseNumerator, 1) * 
			|	ISNULL(ExchangeRates.CourseDenominator, 1)
			|	) / (
			|	ISNULL(ExchangeRates.CourseNumerator, 1) * 
			|	ISNULL(DocumentExchangeRates.CourseDenominator, 1)
			|	) AS AmountARAP
			|	
			|FROM	
			|	InformationRegister.RelativeExchangeRates.SliceLast(&Date,
			|		Currency = &DocumentCurrency AND BaseCurrency = &BaseCurrency
			|	) AS DocumentExchangeRates
			|	
			|	// Let's determine the exchange rate of mutual settlements.
			|	LEFT JOIN
			|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, 
			|			Currency = &ARAPCurrency AND BaseCurrency = &BaseCurrency
			|	) AS ExchangeRates ON TRUE
			|");
			
			Query.SetParameter("Date", DocumentObject.Date);
			Query.SetParameter("DocumentCurrency", DocumentObject.Currency);
			Query.SetParameter("ARAPCurrency", DocumentObject.ARAPCurrency);
			Query.SetParameter("DocumentAmount", DocumentAmount);
			Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization));
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				If DocumentObject.AmountARAP <> Selection.AmountARAP Then
					DocumentObject.AmountARAP = Selection.AmountARAP;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Deprecated.
// The procedure fills in the amount of VAT settlements in the tabular part of the document.
//
// Parameters:
//	Document - DocumentObject - Current document.
//	TabularSectionName - String - Name of the table part of the document to fill in.
// 
Procedure FillInAmountOfVATSettlementsInTablePart(Document, TabularSectionName) Export
	
	TabularSection = Document[TabularSectionName];
	
	DocumentCurrency = Document.Currency;
	OrderCurrency    = Document.ARAPCurrency;
	
	If DocumentCurrency = OrderCurrency Then
		
		For IndexOf = 0 To TabularSection.Count()-1 Do
			If Not ValueIsFilled(TabularSection[IndexOf].AmountVATARAP)
			 Or TabularSection[IndexOf].AmountVATARAP <> TabularSection[IndexOf].VATAmount Then
				TabularSection[IndexOf].AmountVATARAP = TabularSection[IndexOf].VATAmount;
			EndIf;
		EndDo;
		
	Else
	
		For Each String In TabularSection Do
			
			String.AmountVATARAP = PriceManagementSystemClientServer.CalculateVATAmount(String.AmountARAP, String.VATRate);
			
		EndDo;
	
	EndIf;
	
EndProcedure

// The procedure fills in the amount of the payment transcript in accordance with the amount of the document.
//
// Parameters:
//		DocumentAmount - Number - The amount of the document to fill in.
//		ARAPDetails - ValueTable - the table to fill in.
//		ARAPCurrency - CatalogRef.Currencies - default currency.
//
Procedure FillInAmountOfPaymentDecryptionForDocumentAmount(Val DocumentAmount, ARAPDetails, ARAPCurrency = Undefined) Export
	
	AmountOfPaymentDecryption = ARAPDetails.Total("Sum");
	If DocumentAmount <> AmountOfPaymentDecryption Then
		
		If ARAPDetails.Count() = 0 Then
			NewRow = ARAPDetails.Add();
			NewRow.Sum = DocumentAmount;
			If Not ARAPCurrency = Undefined Then
				NewRow.ARAPCurrency = ARAPCurrency;
			EndIf;
		Else
			
			Difference = DocumentAmount - AmountOfPaymentDecryption;
			ArrayOfRowsToDelete_1 = New Array;
			
			// The amounts in the lines with an empty order are adjusted.
			For Each TableRow In ARAPDetails Do
				
				If Not ValueIsFilled(TableRow.ARAPObject) Then
					TableRow.Sum = Max(TableRow.Sum + Difference, 0);
					TableRow.AmountARAP = 0;
					Difference = DocumentAmount - ARAPDetails.Total("Sum");
				EndIf;
				
				If TableRow.Sum = 0 Then
					ArrayOfRowsToDelete_1.Add(TableRow);
				EndIf;
				
				If Difference = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			// The amounts in the lines with the specified order are reduced.
			If Difference < 0 Then
				
				For Each TableRow In ARAPDetails Do
					
					If ValueIsFilled(TableRow.ARAPObject) Then
						TableRow.Sum = Max(TableRow.Sum + Difference, 0);
						TableRow.AmountARAP = 0;
						Difference = DocumentAmount - ARAPDetails.Total("Sum");
					EndIf;
					
					If TableRow.Sum = 0 Then
						ArrayOfRowsToDelete_1.Add(TableRow);
					EndIf;
					
					If Difference = 0 Then
						Break;
					EndIf;
					
				EndDo;
				
			EndIf;
			
			// The remaining undistributed amount will be assigned to a new line.
			If Difference <> 0 Then
				NewRow = ARAPDetails.Add();
				NewRow.Sum = Difference;
				If Not ARAPCurrency = Undefined Then
					NewRow.ARAPCurrency = ARAPCurrency;
				EndIf;
			EndIf;
			
			// Zero-sum rows will be deleted.
			For Each TableRow In ArrayOfRowsToDelete_1 Do
				ARAPDetails.Delete(TableRow);
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure populates or clears the table part of the transcript of the payment invoice from the settlement of invoices.
//
// Parameters:
//	DocumentAmount		- Number - The amount of the current document.
//	AmountARAP - Number - The amount of mutual settlements of the document.
//	ARAPDetails	- ValueTable - Decryption of the invoice payment to be filled in:
//		* AmountARAP	- Number - The amount of settlements on the line.
//		* Sum					- Number - The amount in the currency of the document.
//		* ARAPObject		- CatalogRef.ARAPObjects - Links to the settlement objects of the credited payments/the document itself.
//	ARAPObject		- CatalogRef.ARAPObjects - A reference to the calculation object of the decryption owner's document.
//
Procedure FillInAmountOfInvoiceDecryption(Val DocumentAmount, Val AmountARAP, ARAPDetails, ARAPObject) Export
	
	If DocumentAmount = 0 Or AmountARAP = 0 Then
		ARAPDetails.Clear();
		Return;
	EndIf;
	
	RedistributionOfAmountIsRequired = False;
	AmountOfPaymentDecryption = ARAPDetails.Total("AmountARAP");
	NewRateNumeratorOfMutualSettlements = ?(DocumentAmount = 0 Or AmountARAP = 0, 0, DocumentAmount / AmountARAP);
	
	If AmountARAP <> AmountOfPaymentDecryption Then
		
		Difference = AmountARAP - AmountOfPaymentDecryption;
		RedistributionOfAmountIsRequired = True;
		
		If Difference > 0 Then
			
			For Cnt = 0 To ARAPDetails.Count()-1 Do
				DecryptionString = ARAPDetails[Cnt];
				If DecryptionString.ARAPObject = ARAPObject Then
					DecryptionString.AmountARAP = DecryptionString.AmountARAP + Difference;
					Difference = 0;
				EndIf;
			EndDo;
			
			If Difference > 0 Then
				DecryptionString = ARAPDetails.Add();
				DecryptionString.AmountARAP = Difference;
				DecryptionString.ARAPObject = ARAPObject;
			EndIf;
			
		EndIf;
		
		If Difference < 0 Then
			
			For Cnt = 0 To ARAPDetails.Count()-1 Do
				DecryptionString = ARAPDetails[Cnt];
				If DecryptionString.ARAPObject = ARAPObject Then
					AmountOfSettlementsUpTo = DecryptionString.AmountARAP;
					DecryptionString.AmountARAP = Max(0,DecryptionString.AmountARAP + Difference);
					Difference = Difference + (AmountOfSettlementsUpTo - DecryptionString.AmountARAP);
				EndIf;
			EndDo;
			
			If Difference < 0 Then
			
				For Cnt = 0 To ARAPDetails.Count()-1 Do
					DecryptionString = ARAPDetails[Cnt];
					If DecryptionString.ARAPObject <> ARAPObject Then
						AmountOfSettlementsUpTo = DecryptionString.AmountARAP;
						DecryptionString.AmountARAP = Max(0,DecryptionString.AmountARAP + Difference);
						Difference = Difference + (AmountOfSettlementsUpTo - DecryptionString.AmountARAP);
					EndIf;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	AmountOfPaymentDecryption = ARAPDetails.Total("Sum");
	If RedistributionOfAmountIsRequired Or DocumentAmount <> AmountOfPaymentDecryption Then
		
		If ARAPDetails.Count() = 1 Then
			ARAPDetails[0].Sum = DocumentAmount;
		ElsIf ARAPDetails.Count() > 1 Then
			
			RetainedEarnings = DocumentAmount;
			For Cnt = 0 To ARAPDetails.Count()-1 Do
				DecryptionString = ARAPDetails[Cnt];
				If Cnt = ARAPDetails.Count()-1 Then
					DecryptionString.Sum = RetainedEarnings;
				Else
					DecryptionString.Sum = DecryptionString.AmountARAP * NewRateNumeratorOfMutualSettlements;
					RetainedEarnings = RetainedEarnings - DecryptionString.Sum;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Cnt = 0;
	While Cnt < ARAPDetails.Count() Do
		
		If ARAPDetails[Cnt].AmountARAP = 0 Then
			ARAPDetails.Delete(Cnt);
		Else
			Cnt = Cnt +1;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Posting

// Deprecated. Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - a recordable document.
//  Properties - See DocumentsPosting.DocumentProperties.
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism.
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Return ARAPAccountingPosting.ParametersForHoldingDocument(Document, Properties);
	
EndFunction

// Deprecated. Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map of KeyAndValue - Contains the texts of the cancellation requests, where:
// 		* Key - String - full name of the register.
// 		* Value - String - query text.
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	Return ARAPAccountingPosting.TextsOfCancellationRequests(MetadataOfDocument);
	
EndFunction

// Deprecated. Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map of KeyAndValue:
//		* Key - String - The name of the temporary register change table.
//		* Value - String - query text.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	Return ARAPAccountingPosting.QueryTextsMonitoringBanDateBasedOnChangesTable(Query);
	
EndFunction

// Deprecated. The procedure of formation of movements on the slave registers of settlements.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	ARAPAccountingPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel)
	
EndProcedure

// Deprecated. Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	ARAPAccountingPosting.InitializeChangeControlData(Query, QueryTexts, Document);
	
EndProcedure

// Deprecated. Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	ARAPAccountingPosting.ReportChangeControlResults(ControlResults, Document, Cancel);
	
EndProcedure

// Deprecated. Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//								used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	ARAPAccountingPosting.BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel);
	
EndProcedure

// Deprecated. Occurs after execution of the write registers of the instrument.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//								used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	ARAPAccountingPosting.AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel);
	
EndProcedure

#EndRegion

#Region CalculationOfPaymentDates_OfflineCalculations
// Deprecated. In the temporary table Manager, it places the table "table of client Statistics",
// which contains the payment dates. It is based on the "Settlements with clients by documents" register.
//
// Parameters:
//		TempTablesManager - TempTablesManager - The current Manager of temporary tables for placing tables.
//		DateOfRemainingGoods - Date - Date of balances.
//
Procedure CalculateCustomerPaymentDates(TempTablesManager, DateOfRemainingGoods) Export
	If AccessRight("Read",Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments)
		And AccessRight("Read",Metadata.AccumulationRegisters.CustomersARAPAccounting) 
		And Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query("
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                          AS SalesOrder,
		|	Calculations.Currency                                  AS Currency,
		|	CASE WHEN (Calculations.SumBalance - Calculations.AmountDueBalance) > 0
		|		THEN Calculations.AmountDueBalance
		|		ELSE Calculations.SumBalance
		|	END                                           AS DebtBalance,
		|	CASE WHEN (Calculations.SumBalance - Calculations.AmountDueBalance) > 0
		|		THEN Calculations.AmountDueBalance
		|		ELSE Calculations.SumBalance
		|	END                                           AS DebtBalanceAtEndOfPeriod,
		|	&DateOfRemainingGoods                                   AS PaymentDate,
		|	DATEADD(&DateOfRemainingGoods, SECOND, 1)        AS Period,
		|	TRUE                                          AS ARAPOverdue
		|INTO CustomerBalanceTable
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(&Boundary, ) AS Calculations
		|WHERE
		|	Calculations.AmountDueBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Calculations.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                          AS SalesOrder,
		|	Calculations.Currency                                  AS Currency,
		|	CASE WHEN Calculations.AmountDueBalance < 0
		|			THEN Calculations.SumBalance
		|			ELSE CASE WHEN (Calculations.SumBalance - Calculations.AmountDueBalance) > 0
		|					THEN Calculations.SumBalance - Calculations.AmountDueBalance
		|					ELSE Calculations.AmountDueBalance
		|			END
		|	END                                           AS DebtBalance,
		|	CASE WHEN Calculations.AmountDueBalance < 0
		|			THEN Calculations.SumBalance
		|			ELSE CASE WHEN (Calculations.SumBalance - Calculations.AmountDueBalance) > 0
		|					THEN Calculations.SumBalance - Calculations.AmountDueBalance
		|					ELSE Calculations.AmountDueBalance
		|			END
		|	END                                           AS DebtBalanceAtEndOfPeriod,
		|	&DateOfRemainingGoods                                   AS PaymentDate,
		|	DATEADD(&DateOfRemainingGoods, SECOND, 1)        AS Period,
		|	FALSE                                            AS ARAPOverdue
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(&Boundary, ) AS Calculations
		|WHERE
		|	Calculations.AmountDueBalance <= 0
		|;
		|/////////////////////////////////////////////////////////
		|SELECT 
		|	1
		|INTO CustomerShipmentTable
		|;
		|/////////////////////////////////////////////////////////
		|SELECT 
		|	1
		|INTO CustomerPeriodTable
		|");
		
		Parameters = New Array(2);
		Parameters[0] = DateOfRemainingGoods;
		Parameters[1] = BoundaryType.Including;
		Boundary = New(Type("Boundary"),Parameters);
		
		Query.SetParameter("DateOfRemainingGoods", DateOfRemainingGoods);
		Query.SetParameter("Boundary", Boundary);
		
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
		
 		Query.Text = "
		|DROP CustomerPeriodTable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CustomerShipmentTable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners                  AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                             AS SalesOrder,
		|	Calculations.Currency                                     AS Currency,
		|	MAX(BEGINOFPERIOD(Calculations.PaymentDate, DAY)) AS PaymentDate,
		|	MAX(Calculations.Period)                           AS Period,
		|	BalanceTable.ARAPOverdue          AS ARAPOverdue
		|INTO CustomerPeriodTable
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|		INNER JOIN CustomerBalanceTable AS BalanceTable
		|		ON Calculations.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|			AND Calculations.ARAPObject = BalanceTable.SalesOrder
		|			AND Calculations.Currency = BalanceTable.Currency
		|			AND BalanceTable.DebtBalance <> 0
		|WHERE
		|	Calculations.Active
		|	AND Calculations.Period <= &DateOfRemainingGoods
		|	AND Calculations.Period < BalanceTable.Period
		|	AND (Calculations.AmountDue <> 0 OR Calculations.ToShip <> 0)
		|	AND BalanceTable.ARAPOverdue
		|
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency,
		|	BalanceTable.ARAPOverdue
		|
		|UNION ALL
		|
		|SELECT
		|	Calculations.AccountingDimensionByPartners                  AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                             AS SalesOrder,
		|	Calculations.Currency                                     AS Currency,
		|	MIN(BEGINOFPERIOD(Calculations.PaymentDate, DAY))  AS PaymentDate,
		|	MIN(Calculations.Period)                            AS Period,
		|	BalanceTable.ARAPOverdue          AS ARAPOverdue
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|		INNER JOIN CustomerBalanceTable AS BalanceTable
		|		ON Calculations.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|			AND Calculations.ARAPObject = BalanceTable.SalesOrder
		|			AND Calculations.Currency = BalanceTable.Currency
		|			AND BalanceTable.DebtBalance <> 0
		|WHERE
		|	(Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		OR (Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND Calculations.AmountDue < 0))
		|	AND Calculations.Active
		|	AND Calculations.Period > &DateOfRemainingGoods
		|	AND Calculations.Period > BalanceTable.Period
		|	AND (Calculations.AmountDue <> 0 OR Calculations.ToShip <> 0)
		|	AND NOT BalanceTable.ARAPOverdue
		|
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency,
		|	BalanceTable.ARAPOverdue
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	TimeIntervals.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	TimeIntervals.SalesOrder                          AS SalesOrder,
		|	TimeIntervals.Currency                                AS Currency,
		|	TimeIntervals.Period                                AS Period,
		|	BEGINOFPERIOD(CASE WHEN TimeIntervals.SalesOrder.Object REFS Catalog.CounterpartyContracts
		|		AND Calculations.Recorder REFS Document.ContractSchedule
		|		THEN Calculations.PaymentDate
		|		WHEN Calculations.PaymentDate = DATETIME(1,1,1)
		|		THEN Calculations.Period
		|		ELSE TimeIntervals.PaymentDate
		|	END, DAY)                                  AS PaymentDate,
		|	SUM(CASE WHEN ISNULL(Calculations.AmountDue, 0) < 0
		|			THEN 0 - Calculations.AmountDue
		|			ELSE ISNULL(Calculations.AmountDue, 0)
		|	END)                                        AS Debt,
		|	TimeIntervals.ARAPOverdue             AS ARAPOverdue
		|INTO CustomerShipmentTable
		|FROM
		|	CustomerPeriodTable AS TimeIntervals
		|		
		|	LEFT JOIN AccumulationRegister.CustomersARAPAccounting AS Calculations
		|	ON TimeIntervals.AccountingDimensionByPartners   = Calculations.AccountingDimensionByPartners
		|		AND TimeIntervals.SalesOrder             = Calculations.ARAPObject
		|		AND TimeIntervals.Currency                   = Calculations.Currency
		|		AND Calculations.Active
		|		AND Calculations.Period = TimeIntervals.Period
		|		AND (Calculations.AmountDue <> 0 OR Calculations.ToShip <> 0)
		|		AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			OR (Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND Calculations.AmountDue < 0))
		|GROUP BY
		|	TimeIntervals.AccountingDimensionByPartners,
		|	TimeIntervals.SalesOrder,
		|	TimeIntervals.Currency,
		|	TimeIntervals.Period,
		|	BEGINOFPERIOD(CASE WHEN TimeIntervals.SalesOrder.Object REFS Catalog.CounterpartyContracts
		|		AND Calculations.Recorder REFS Document.ContractSchedule
		|		THEN Calculations.PaymentDate
		|		WHEN Calculations.PaymentDate = DATETIME(1,1,1)
		|		THEN Calculations.Period
		|		ELSE TimeIntervals.PaymentDate
		|	END, DAY),
		|	TimeIntervals.ARAPOverdue
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.AccountingDimensionByPartners                   AS AccountingDimensionByPartners,
		|	Balance.SalesOrder                                AS SalesOrder,
		|	Balance.Currency                                      AS Currency,
		|	CASE WHEN Balance.DebtBalance > ISNULL(Shipments.Debt, 0)
		|			THEN Balance.DebtBalance - ISNULL(Shipments.Debt, 0)
		|		ELSE 0
		|	END                                               AS NewDebtBalance,
		|	CASE WHEN ISNULL(Shipments.Debt, 0) = 0
		|		THEN Balance.DebtBalanceAtEndOfPeriod
		|		ELSE CASE WHEN Balance.DebtBalance > Shipments.Debt
		|			THEN Shipments.Debt
		|			ELSE Balance.DebtBalance
		|		END
		|	END                                               AS DebtBalanceAtEndOfPeriod,
		|	Shipments.Period                                     AS Period,
		|	ISNULL(Shipments.PaymentDate, Balance.PaymentDate) AS PaymentDate,
		|	Balance.ARAPOverdue                   AS ARAPOverdue
		|INTO NewCustomerBalances
		|FROM
		|	CustomerBalanceTable AS Balance
		|
		|	LEFT JOIN CustomerShipmentTable AS Shipments
		|	ON Balance.AccountingDimensionByPartners = Shipments.AccountingDimensionByPartners
		|		AND Balance.SalesOrder = Shipments.SalesOrder
		|		AND Balance.Currency  = Shipments.Currency
		|		AND Balance.ARAPOverdue = Shipments.ARAPOverdue
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CustomerBalanceTable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|	Balance.SalesOrder                 AS SalesOrder,
		|	Balance.Currency                       AS Currency,
		|	Balance.Period                       AS Period,
		|	Balance.PaymentDate                  AS PaymentDate,
		|	Balance.NewDebtBalance             AS DebtBalance,
		|	Balance.DebtBalanceAtEndOfPeriod    AS DebtBalanceAtEndOfPeriod,
		|	Balance.ARAPOverdue    AS ARAPOverdue
		|INTO CustomerBalanceTable
		|FROM
		|	NewCustomerBalances AS Balance
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	SalesOrder,
		|	Currency
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP NewCustomerBalances
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	1
		|FROM CustomerPeriodTable
		|";
		
		Result = Query.Execute();
		Counter = 0;
		MaxNumberOfIterations = 1000;
		While Not Result.IsEmpty() Do 
			Result = Query.Execute();
			Counter = Counter + 1;
			If Counter >= MaxNumberOfIterations Then
				Break;
			EndIf;
		EndDo;
		Query.Text = "
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	Calculations.SalesOrder                      AS SalesOrder,
		|	Calculations.ARAPDocument                 AS ARAPDocument,
		|	Calculations.Currency                            AS Currency,
		|	BalanceTable.PaymentDate               AS PaymentDate,
		|	BalanceTable.DebtBalanceAtEndOfPeriod AS Debt
		|INTO TableOfCustomerBalancesByDocuments
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&Boundary, ) AS Calculations
		|
		|	INNER JOIN CustomerBalanceTable AS BalanceTable
		|	ON Calculations.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|		AND Calculations.SalesOrder = BalanceTable.SalesOrder
		|		AND Calculations.Currency = BalanceTable.Currency
		|WHERE
		|	Calculations.DebtBalance > 0
		|;
		|//////////////////////////////////////////////
		|DROP CustomerBalanceTable
		|;
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.SalesOrder              AS SalesOrder,
		|	Calculations.ARAPDocument         AS ARAPDocument,
		|	Calculations.Currency                    AS Currency,
		|	Calculations.PaymentDate               AS PaymentDate,
		|	Calculations.Debt                      AS AmountDue,
		|	Calculations.Debt                      AS DebtBalance
		|INTO CustomerBalanceTable
		|FROM
		|	TableOfCustomerBalancesByDocuments AS Calculations
		|";
		Query.Execute();
	Else
		Query = New Query("
		 |SELECT DISTINCT
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED                                                     AS SalesOrder,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	VALUE(Catalog.Currencies.EmptyRef)                         AS Currency,
		|	DATETIME(1,1,1)                                                 AS PaymentDate,
		|	0                                                                AS AmountDue,
		|	0                                                                AS DebtBalance
		|INTO CustomerBalanceTable");
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	EndIf;
EndProcedure

// Deprecated. In the temporary table Manager, it places the table "table of suppliers 'Statistics",
// which contains the payment dates. It is based on the "Payments to suppliers by documents" register.
//
// Parameters:
//		TempTablesManager - TempTablesManager - The current Manager of temporary tables for placing tables.
//		DateOfRemainingGoods - Date - Date of balances.
//
Procedure CalculateSupplierPaymentDates(TempTablesManager, DateOfRemainingGoods) Export
	If AccessRight("Read",Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments)
		And AccessRight("Read",Metadata.AccumulationRegisters.VendorsARAPAccounting)
		And Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query("
		|SELECT ALLOWED 
		|	Calculations.AccountingDimensionByPartners        AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                   AS PurchaseOrder,
		|	Calculations.Currency                           AS Currency,
		|	-Calculations.AmountDueBalance                  AS AmountDueBalance,
		|	-Calculations.AmountDueBalance                  AS BalancePayableAtEndOfPeriod,
		|	&DateOfRemainingGoods                            AS PaymentDate,
		|	DATEADD(&DateOfRemainingGoods, SECOND, 1) AS Period,
		|	TRUE                                   AS ARAPOverdue
		|INTO TableOfSupplierBalances
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(&Boundary, ) AS Calculations
		|WHERE
		|	Calculations.AmountDueBalance < 0
		|
		|UNION ALL
		|
		|SELECT
		|	Calculations.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                          AS PurchaseOrder,
		|	Calculations.Currency                                  AS Currency,
		|	(Calculations.SumBalance - Calculations.AmountDueBalance) AS AmountDueBalance,
		|	(Calculations.SumBalance - Calculations.AmountDueBalance) AS BalancePayableAtEndOfPeriod,
		|	&DateOfRemainingGoods                                   AS PaymentDate,
		|	DATEADD(&DateOfRemainingGoods, SECOND, 1)        AS Period,
		|	FALSE                                            AS ARAPOverdue
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(&Boundary, ) AS Calculations
		|WHERE
		|	Calculations.AmountDueBalance >= 0 AND Calculations.SumBalance <> 0
		|	AND Calculations.SumBalance - Calculations.AmountDueBalance > 0
		|;
		|/////////////////////////////////////////////////////////
		|SELECT 
		|	1
		|INTO TableOfSupplierReceipts
		|;
		|/////////////////////////////////////////////////////////
		|SELECT 
		|	1
		|INTO TableOfSupplierPeriods
		|");
		
		Parameters = New Array(2);
		Parameters[0] = DateOfRemainingGoods;
		Parameters[1] = BoundaryType.Including;
		Boundary = New(Type("Boundary"),Parameters);
		
		Query.SetParameter("DateOfRemainingGoods", DateOfRemainingGoods);
		Query.SetParameter("Boundary", Boundary);
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
		
		Query.Text = "
		|DROP TableOfSupplierPeriods
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfSupplierReceipts
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners                  AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                             AS PurchaseOrder,
		|	Calculations.Currency                                     AS Currency,
		|	MAX(BEGINOFPERIOD(Calculations.PaymentDate, DAY)) AS PaymentDate,
		|	MAX(Calculations.Period)                           AS Period,
		|	BalanceTable.ARAPOverdue          AS ARAPOverdue
		|INTO TableOfSupplierPeriods
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|		INNER JOIN TableOfSupplierBalances AS BalanceTable
		|		ON Calculations.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|			AND Calculations.ARAPObject = BalanceTable.PurchaseOrder
		|			AND Calculations.Currency = BalanceTable.Currency
		|			AND BalanceTable.AmountDueBalance <> 0
		|WHERE
		|	Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Calculations.Active
		|	AND Calculations.Period <= &DateOfRemainingGoods
		|	AND Calculations.Period < BalanceTable.Period
		|	AND (Calculations.AmountDue <> 0 OR Calculations.ToReceive <> 0)
		|	AND BalanceTable.ARAPOverdue
		|
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency,
		|	BalanceTable.ARAPOverdue
		|
		|UNION ALL
		|
		|SELECT
		|	Calculations.AccountingDimensionByPartners                  AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                             AS PurchaseOrder,
		|	Calculations.Currency                                     AS Currency,
		|	MIN(BEGINOFPERIOD(Calculations.PaymentDate, DAY))  AS PaymentDate,
		|	MAX(Calculations.Period)                           AS Period,
		|	BalanceTable.ARAPOverdue          AS ARAPOverdue
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|		INNER JOIN TableOfSupplierBalances AS BalanceTable
		|		ON Calculations.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|			AND Calculations.ARAPObject = BalanceTable.PurchaseOrder
		|			AND Calculations.Currency = BalanceTable.Currency
		|			AND BalanceTable.AmountDueBalance <> 0
		|WHERE
		|	Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Calculations.Active
		|	AND Calculations.Period > &DateOfRemainingGoods
		|	AND Calculations.Period > BalanceTable.Period
		|	AND (Calculations.AmountDue <> 0 OR Calculations.ToReceive <> 0)
		|	AND NOT BalanceTable.ARAPOverdue
		|
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency,
		|	BalanceTable.ARAPOverdue
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	TimeIntervals.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	TimeIntervals.PurchaseOrder                       AS PurchaseOrder,
		|	TimeIntervals.Currency                                AS Currency,
		|	TimeIntervals.Period                                AS Period,
		|	CASE WHEN TimeIntervals.PurchaseOrder.Object REFS Catalog.CounterpartyContracts
		|		AND Calculations.Recorder REFS Document.ContractSchedule
		|		THEN Calculations.PaymentDate
		|		WHEN Calculations.PaymentDate = DATETIME(1,1,1)
		|		THEN Calculations.Period
		|		ELSE TimeIntervals.PaymentDate
		|	END                                         AS PaymentDate,
		|	SUM(CASE WHEN ISNULL(Calculations.AmountDue, 0) < 0
		|			THEN 0 - Calculations.AmountDue
		|			ELSE ISNULL(Calculations.AmountDue, 0)
		|	END)                                        AS AmountDue,
		|	TimeIntervals.ARAPOverdue             AS ARAPOverdue
		|INTO TableOfSupplierReceipts
		|FROM
		|	TableOfSupplierPeriods AS TimeIntervals
		|		
		|	LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS Calculations
		|	ON TimeIntervals.AccountingDimensionByPartners   = Calculations.AccountingDimensionByPartners
		|		AND TimeIntervals.PurchaseOrder          = Calculations.ARAPObject
		|		AND TimeIntervals.Currency                   = Calculations.Currency
		|		AND Calculations.Active
		|		AND Calculations.Period = TimeIntervals.Period
		|		AND (Calculations.AmountDue <> 0 OR Calculations.ToReceive <> 0)
		|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|GROUP BY
		|	TimeIntervals.AccountingDimensionByPartners,
		|	TimeIntervals.PurchaseOrder,
		|	TimeIntervals.Currency,
		|	TimeIntervals.Period,
		|	CASE WHEN TimeIntervals.PurchaseOrder.Object REFS Catalog.CounterpartyContracts
		|		AND Calculations.Recorder REFS Document.ContractSchedule
		|		THEN Calculations.PaymentDate
		|		WHEN Calculations.PaymentDate = DATETIME(1,1,1)
		|		THEN Calculations.Period
		|		ELSE TimeIntervals.PaymentDate
		|	END,
		|	TimeIntervals.ARAPOverdue
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.AccountingDimensionByPartners                      AS AccountingDimensionByPartners,
		|	Balance.PurchaseOrder                                AS PurchaseOrder,
		|	Balance.Currency                                         AS Currency,
		|	CASE WHEN Balance.AmountDueBalance > ISNULL(Inflow.AmountDue, 0)
		|			THEN Balance.AmountDueBalance - ISNULL(Inflow.AmountDue, 0)
		|		ELSE 0
		|	END                                                  AS NewBalanceDue,
		|	CASE WHEN ISNULL(Inflow.AmountDue, 0) = 0
		|		THEN Balance.BalancePayableAtEndOfPeriod
		|		ELSE CASE WHEN Balance.BalancePayableAtEndOfPeriod > Inflow.AmountDue
		|			THEN Inflow.AmountDue
		|			ELSE Balance.BalancePayableAtEndOfPeriod
		|		END
		|	END                                                  AS BalancePayableAtEndOfPeriod,
		|	Inflow.Period                                     AS Period,
		|	ISNULL(Inflow.PaymentDate, Balance.PaymentDate) AS PaymentDate,
		|	Balance.ARAPOverdue                      AS ARAPOverdue
		|INTO NewSupplierBalances
		|FROM
		|	TableOfSupplierBalances AS Balance
		|
		|	LEFT JOIN TableOfSupplierReceipts AS Inflow
		|	ON Balance.AccountingDimensionByPartners = Inflow.AccountingDimensionByPartners
		|		AND Balance.PurchaseOrder = Inflow.PurchaseOrder
		|		AND Balance.Currency  = Inflow.Currency
		|		AND Balance.ARAPOverdue = Inflow.ARAPOverdue
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfSupplierBalances
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|	Balance.PurchaseOrder              AS PurchaseOrder,
		|	Balance.Currency                       AS Currency,
		|	Balance.Period                       AS Period,
		|	Balance.PaymentDate                  AS PaymentDate,
		|	Balance.NewBalanceDue          AS AmountDueBalance,
		|	Balance.BalancePayableAtEndOfPeriod AS BalancePayableAtEndOfPeriod,
		|	Balance.ARAPOverdue    AS ARAPOverdue
		|INTO TableOfSupplierBalances
		|FROM
		|	NewSupplierBalances AS Balance
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	PurchaseOrder,
		|	Currency
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP NewSupplierBalances
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	1
		|FROM TableOfSupplierPeriods
		|";
		
		Result = Query.Execute();
		Counter = 0;
		MaxNumberOfIterations = 1000;
		While Not Result.IsEmpty() Do 
			Result = Query.Execute();
			Counter = Counter + 1;
			If Counter >= MaxNumberOfIterations Then
				Break;
			EndIf;
		EndDo;
		Query.Text = "
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners            AS AccountingDimensionByPartners,
		|	Calculations.PurchaseOrder                      AS PurchaseOrder,
		|	Calculations.ARAPDocument                    AS ARAPDocument,
		|	Calculations.Currency                               AS Currency,
		|	BalanceTable.PaymentDate                  AS PaymentDate,
		|	BalanceTable.BalancePayableAtEndOfPeriod AS AmountDue
		|INTO TableOfSupplierBalancesByDocuments
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(&Boundary, ) AS Calculations
		|
		|	INNER JOIN TableOfSupplierBalances AS BalanceTable
		|	ON Calculations.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|		AND Calculations.PurchaseOrder = BalanceTable.PurchaseOrder
		|		AND Calculations.Currency = BalanceTable.Currency
		|WHERE
		|	Calculations.DebtBalance < 0
		|;
		|//////////////////////////////////////////////
		|DROP TableOfSupplierBalances
		|;
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.PurchaseOrder           AS PurchaseOrder,
		|	Calculations.ARAPDocument         AS ARAPDocument,
		|	Calculations.Currency                    AS Currency,
		|	Calculations.PaymentDate               AS PaymentDate,
		|	Calculations.AmountDue                   AS AmountDue,
		|	Calculations.AmountDue                   AS DebtBalance
		|INTO TableOfSupplierBalances
		|FROM
		|	TableOfSupplierBalancesByDocuments AS Calculations
		|";
		Query.Execute();
	Else
		Query = New Query("
		 |SELECT DISTINCT
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED                                                     AS PurchaseOrder,
		|	UNDEFINED                                                     AS ARAPDocument,
		|	VALUE(Catalog.Currencies.EmptyRef)                         AS Currency,
		|	DATETIME(1,1,1)                                                 AS PaymentDate,
		|	0                                                                AS AmountDue,
		|	0                                                                AS DebtBalance
		|INTO TableOfSupplierBalances");
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	EndIf;
EndProcedure

// Deprecated. The temporary table Manager places a table containing the payment dates.
// It is based on the "Settlements with clients" register.
// Parameters:
//	TemporaryTable - TempTablesManager - Temporary table Manager where the calculation result will be placed.
//	DateOfRemainingGoods - Date - The period for which payment dates are calculated.
Procedure CalculateCustomerSOperationalPaymentDates(TemporaryTable, DateOfRemainingGoods) Export
	If AccessRight("Read",Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		Query = New Query("
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners        AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                   AS SalesOrder,
		|	Calculations.Currency                           AS Currency,
		|	Calculations.AmountDueBalance                   AS AmountDueBalance,
		|	Calculations.AmountDueBalance                   AS BalancePayableAtEndOfPeriod,
		|	&DateOfRemainingGoods                            AS PaymentDate,
		|	DATEADD(&DateOfRemainingGoods, SECOND, 1) AS Period
		|INTO TableOfCustomerBalancesPayable
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(&DateOfRemainingGoods, ) AS Calculations
		|;
		|/////////////////////////////////////////////////////////
		|SELECT 
		|	1
		|INTO TableOfCustomerPeriodsPayable
		|");
		Query.SetParameter("DateOfRemainingGoods", DateOfRemainingGoods);
		Query.TempTablesManager = TemporaryTable;
		Query.Execute();
		
		Query.Text = "
		|DROP TableOfCustomerPeriodsPayable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                        AS SalesOrder,
		|	Calculations.Currency                                AS Currency,
		|	MAX(Calculations.PaymentDate)                 AS PaymentDate,
		|	MAX(BEGINOFPERIOD(Calculations.Period, DAY)) AS Period
		|INTO TableOfCustomerPeriodsPayable
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|		
		|	INNER JOIN TableOfCustomerBalancesPayable AS BalanceTable
		|	ON Calculations.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|		AND Calculations.ARAPObject = BalanceTable.SalesOrder
		|		AND Calculations.Currency = BalanceTable.Currency
		|		AND BalanceTable.AmountDueBalance <> 0
		|WHERE
		|	Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND Calculations.Active
		|	AND Calculations.Period <= &DateOfRemainingGoods
		|	AND Calculations.Period < BalanceTable.Period
		|	AND Calculations.AmountDue <> 0
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	TimeIntervals.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	TimeIntervals.SalesOrder                          AS SalesOrder,
		|	TimeIntervals.Currency                                AS Currency,
		|	TimeIntervals.Period                                AS Period,
		|	TimeIntervals.PaymentDate                           AS PaymentDate,
		|	SUM(ISNULL(Calculations.AmountDue, 0))      AS AmountDue
		|INTO TableOfCustomerShipmentsForPayment
		|FROM
		|	TableOfCustomerPeriodsPayable AS TimeIntervals
		|		
		|	LEFT JOIN AccumulationRegister.CustomersARAPAccounting AS Calculations
		|	ON TimeIntervals.AccountingDimensionByPartners   = Calculations.AccountingDimensionByPartners
		|		AND TimeIntervals.SalesOrder             = Calculations.ARAPObject
		|		AND TimeIntervals.Currency                   = Calculations.Currency
		|		AND TimeIntervals.PaymentDate              = Calculations.PaymentDate
		|		AND Calculations.Active
		|		AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt))
		|		AND (Calculations.Period BETWEEN TimeIntervals.Period AND ENDOFPERIOD(TimeIntervals.Period, DAY))
		|GROUP BY
		|	TimeIntervals.AccountingDimensionByPartners,
		|	TimeIntervals.SalesOrder,
		|	TimeIntervals.Currency,
		|	TimeIntervals.Period,
		|	TimeIntervals.PaymentDate
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	Balance.SalesOrder                      AS SalesOrder,
		|	Balance.Currency                            AS Currency,
		|	CASE WHEN Balance.AmountDueBalance > ISNULL(Shipments.AmountDue, 0)
		|			THEN Balance.AmountDueBalance - ISNULL(Shipments.AmountDue, 0)
		|		ELSE 0
		|	END                                     AS NewBalanceDue,
		|	Balance.BalancePayableAtEndOfPeriod AS BalancePayableAtEndOfPeriod,
		|	Shipments.Period                           AS Period,
		|	ISNULL(Shipments.PaymentDate, Balance.PaymentDate) AS PaymentDate
		|INTO NewCustomerBalancesPayable
		|FROM
		|	TableOfCustomerBalancesPayable AS Balance
		|
		|	LEFT JOIN TableOfCustomerShipmentsForPayment AS Shipments
		|	ON Balance.AccountingDimensionByPartners = Shipments.AccountingDimensionByPartners
		|		AND Balance.SalesOrder = Shipments.SalesOrder
		|		AND Balance.Currency  = Shipments.Currency
		|		AND Balance.AmountDueBalance <> 0
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfCustomerBalancesPayable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfCustomerShipmentsForPayment
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Balance.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	Balance.SalesOrder                      AS SalesOrder,
		|	Balance.SalesOrder.Object               AS Object,
		|	Balance.Currency                            AS Currency,
		|	Balance.Period                            AS Period,
		|	Balance.PaymentDate                       AS PaymentDate,
		|	Balance.NewBalanceDue          AS AmountDueBalance,
		|	Balance.NewBalanceDue          AS AmountDue,
		|	Balance.BalancePayableAtEndOfPeriod AS BalancePayableAtEndOfPeriod
		|INTO TableOfCustomerBalancesPayable
		|FROM
		|	NewCustomerBalancesPayable AS Balance
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	SalesOrder,
		|	Currency
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP NewCustomerBalancesPayable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	1
		|FROM TableOfCustomerPeriodsPayable
		|";
		
		Result = Query.Execute();
		While Not Result.IsEmpty() Do 
			Result = Query.Execute();
		EndDo;
	EndIf;
EndProcedure

// Deprecated. The temporary table Manager places a table containing the payment dates.
// It is based on the "Payments with suppliers" register.
// Parameters:
//	TemporaryTable - TempTablesManager - Temporary table Manager where the calculation result will be placed.
//	DateOfRemainingGoods - Date - The period for which payment dates are calculated.
Procedure CalculateSupplierSOperationalPaymentDates(TemporaryTable, DateOfRemainingGoods) Export
	If AccessRight("Read",Metadata.AccumulationRegisters.VendorsARAPAccounting) Then
		Query = New Query("
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners        AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                   AS PurchaseOrder,
		|	Calculations.Currency                           AS Currency,
		|	Calculations.AmountDueBalance                   AS AmountDueBalance,
		|	Calculations.AmountDueBalance                   AS BalancePayableAtEndOfPeriod,
		|	&DateOfRemainingGoods                            AS PaymentDate,
		|	DATEADD(&DateOfRemainingGoods, SECOND, 1) AS Period
		|INTO TableOfSupplierBalancesPayable
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(&DateOfRemainingGoods, ) AS Calculations
		|;
		|/////////////////////////////////////////////////////////
		|SELECT 
		|	1
		|INTO TableOfSupplierPeriodsPayable
		|");
		Query.SetParameter("DateOfRemainingGoods", DateOfRemainingGoods);
		Query.TempTablesManager = TemporaryTable;
		Query.Execute();
		
		Query.Text = "
		|DROP TableOfSupplierPeriodsPayable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                        AS PurchaseOrder,
		|	Calculations.Currency                                AS Currency,
		|	MAX(Calculations.PaymentDate)                 AS PaymentDate,
		|	MAX(BEGINOFPERIOD(Calculations.Period, DAY)) AS Period
		|INTO TableOfSupplierPeriodsPayable
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|		
		|	INNER JOIN TableOfSupplierBalancesPayable AS BalanceTable
		|	ON Calculations.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|		AND Calculations.ARAPObject = BalanceTable.PurchaseOrder
		|		AND Calculations.Currency = BalanceTable.Currency
		|		AND BalanceTable.AmountDueBalance <> 0
		|WHERE
		|	Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Calculations.Active
		|	AND Calculations.Period <= &DateOfRemainingGoods
		|	AND Calculations.Period < BalanceTable.Period
		|	AND Calculations.AmountDue <> 0
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	TimeIntervals.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	TimeIntervals.PurchaseOrder                       AS PurchaseOrder,
		|	TimeIntervals.Currency                                AS Currency,
		|	TimeIntervals.Period                                AS Period,
		|	TimeIntervals.PaymentDate                           AS PaymentDate,
		|	SUM(ISNULL(Calculations.AmountDue, 0))           AS AmountDue
		|INTO TableOfSupplierShipmentsPayable
		|FROM
		|	TableOfSupplierPeriodsPayable AS TimeIntervals
		|		
		|	LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS Calculations
		|	ON TimeIntervals.AccountingDimensionByPartners   = Calculations.AccountingDimensionByPartners
		|		AND TimeIntervals.PurchaseOrder          = Calculations.ARAPObject
		|		AND TimeIntervals.PaymentDate              = Calculations.PaymentDate
		|		AND TimeIntervals.Currency                   = Calculations.Currency
		|		AND Calculations.Active
		|		AND (Calculations.RecordType = VALUE(AccumulationRecordType.Expense))
		|		AND (Calculations.Period BETWEEN TimeIntervals.Period AND ENDOFPERIOD(TimeIntervals.Period, DAY))
		|GROUP BY
		|	TimeIntervals.AccountingDimensionByPartners,
		|	TimeIntervals.PurchaseOrder,
		|	TimeIntervals.Currency,
		|	TimeIntervals.Period,
		|	TimeIntervals.PaymentDate
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	Balance.PurchaseOrder                   AS PurchaseOrder,
		|	Balance.Currency                            AS Currency,
		|	CASE WHEN Balance.AmountDueBalance > ISNULL(Shipments.AmountDue, 0)
		|			THEN Balance.AmountDueBalance - ISNULL(Shipments.AmountDue, 0)
		|		ELSE 0
		|	END                                     AS NewBalanceDue,
		|	Balance.BalancePayableAtEndOfPeriod      AS BalancePayableAtEndOfPeriod,
		|	Shipments.Period                           AS Period,
		|	ISNULL(Shipments.PaymentDate, Balance.PaymentDate) AS PaymentDate
		|INTO NewSupplierBalancesPayable
		|FROM
		|	TableOfSupplierBalancesPayable AS Balance
		|
		|	LEFT JOIN TableOfSupplierShipmentsPayable AS Shipments
		|	ON Balance.AccountingDimensionByPartners = Shipments.AccountingDimensionByPartners
		|		AND Balance.PurchaseOrder = Shipments.PurchaseOrder
		|		AND Balance.Currency  = Shipments.Currency
		|		AND Balance.AmountDueBalance <> 0
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfSupplierBalancesPayable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfSupplierShipmentsPayable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	Balance.PurchaseOrder                   AS PurchaseOrder,
		|	Balance.PurchaseOrder.Object            AS Object,
		|	Balance.Currency                            AS Currency,
		|	Balance.Period                            AS Period,
		|	Balance.PaymentDate                       AS PaymentDate,
		|	Balance.NewBalanceDue          AS AmountDueBalance,
		|	Balance.NewBalanceDue          AS AmountDue,
		|	Balance.BalancePayableAtEndOfPeriod AS BalancePayableAtEndOfPeriod
		|INTO TableOfSupplierBalancesPayable
		|FROM
		|	NewSupplierBalancesPayable AS Balance
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	PurchaseOrder,
		|	Currency
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP NewSupplierBalancesPayable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	1
		|FROM TableOfSupplierPeriodsPayable
		|";
		
		Result = Query.Execute();
		While Not Result.IsEmpty() Do 
			Result = Query.Execute();
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region ARAPObjectSettings

// Deprecated.
// Returns the order of settlements under the agreement/contract specified in the object.
//
// Parameters:
//	Object - DocumentObject, Structure - The document for which you need to get the order of payments.
//
// Returns:
//	EnumRef.ARAPObjectSettings - The default order of calculations.
//
Function DefaultCalculationOrder(Object) Export
	
	SetPrivilegedMode(True);
	
	ObjectStructure = New Structure("Terms, Contract");
	FillPropertyValues(ObjectStructure, Object);
	
	If ValueIsFilled(ObjectStructure.Terms) Then
		DetailsOfAgreement = ARAPAccountingInternal.DetailsOfAgreement(ObjectStructure.Terms);
		If DetailsOfAgreement.ContractsAreUsed = True And ValueIsFilled(ObjectStructure.Contract) Then
			OrderOfCalculationsForDocument = Common.ObjectAttributeValue(ObjectStructure.Contract, "ARAPObjectSettings");
		ElsIf DetailsOfAgreement.ContractsAreUsed = False Then
			OrderOfCalculationsForDocument = DetailsOfAgreement.ARAPObjectSettings;
		Else
			OrderOfCalculationsForDocument = Enums.ARAPObjectSettings.ByOrders;
		EndIf;
	ElsIf ValueIsFilled(ObjectStructure.Contract) Then
		OrderOfCalculationsForDocument = Common.ObjectAttributeValue(ObjectStructure.Contract, "ARAPObjectSettings");
	Else
		OrderOfCalculationsForDocument = Enums.ARAPObjectSettings.ByOrders;
	EndIf;
	
	Return OrderOfCalculationsForDocument;
	
EndFunction

// Determines which calculation orders can be used in the selected document.
//
// Parameters:
//	ValueInDocument - EnumRef.ARAPObjectSettings - The calculation order selected in the document.
//	DefaultValue - EnumRef.ARAPObjectSettings - Payment procedure defined by the agreement / agreement of the document.
//	ByOrder - Boolean - The document was entered by order.
//	ThisIsOrder - Boolean - This is an order.
//	OrderAsAProformaInvoice - Boolean - this is an order and the FO order is included as an invoice.
//
// Returns:
//	ValueList - A list of available calculation orders.
//
Function AvailableCalculationProceduresForDocument(ValueInDocument, DefaultValue, ByOrder = False, ThisIsOrder = False, OrderAsAProformaInvoice = False) Export
	
	CalculationProcedures = New ValueList;
	
	If ValueIsFilled(ValueInDocument) Then
		CalculationProcedures.Add(ValueInDocument);
	EndIf;
	
	If Not ByOrder Then
	
		If DefaultValue = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
			CalculationProcedures.Add(Enums.ARAPObjectSettings.ByCounterpartyContracts);
			CalculationProcedures.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		EndIf;
		
		If DefaultValue = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			CalculationProcedures.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		EndIf;
		
		If DefaultValue <> Enums.ARAPObjectSettings.ByARAPDocuments
				And (ByOrder Or ThisIsOrder) Then
			CalculationProcedures.Add(Enums.ARAPObjectSettings.ByOrders);
			If Not OrderAsAProformaInvoice Then
				CalculationProcedures.Add(Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice);
			EndIf;
		EndIf;
		
		CalculationProcedures.Add(Enums.ARAPObjectSettings.ByARAPDocuments);
		
	EndIf;
	ArrayOfOrders_ = CalculationProcedures.UnloadValues();
	ArrayOfOrders_ = CommonClientServer.CollapseArray(ArrayOfOrders_);
	CalculationProcedures.LoadValues(ArrayOfOrders_);
	
	Return CalculationProcedures;
	
EndFunction

// Returns the order of calculations based on the passed parameters.
//
// Parameters:
//    ThisIsOrder - Boolean - True if it is an order.
//    ReferenceOrder - DocumentRef.SourceDocument,
//    	Document link.Client's requestcountry goods,
//    	Document link.Customer Order,
//    	Document link.Shipment of goods to the client is optional, the order for which the document is entered.
//    Terms - CatalogRef.TermsOfSale, CatalogRef.TermsOfPurchaseFromVendors - Optional, the agreement document.
//    Contract - CatalogRef.CounterpartyContracts - Optional, document agreement.
//
// Returns:
//    EnumRef.ARAPObjectSettings - Procedure of settlements.
//
Function ARAPObjectSettings(ThisIsOrder, ReferenceOrder = Undefined, Terms = Undefined, Contract = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(ReferenceOrder)
		And Common.HasObjectAttribute("ARAPObjectSettings", ReferenceOrder.Metadata()) Then
		OrderOfCalculationsForDocument = Common.ObjectAttributeValue(ReferenceOrder, "ARAPObjectSettings");
	ElsIf ValueIsFilled(Terms) Then
		DetailsOfAgreement = ARAPAccountingInternal.DetailsOfAgreement(Terms);
		If DetailsOfAgreement.ContractsAreUsed And ValueIsFilled(Contract) Then
			OrderOfCalculationsForDocument = Common.ObjectAttributeValue(Contract, "ARAPObjectSettings");
		ElsIf DetailsOfAgreement.ContractsAreUsed = False Then
			OrderOfCalculationsForDocument = DetailsOfAgreement.ARAPObjectSettings;
		Else
			OrderOfCalculationsForDocument = Enums.ARAPObjectSettings.ByOrders;
		EndIf;
	ElsIf ValueIsFilled(Contract) Then
		OrderOfCalculationsForDocument = Common.ObjectAttributeValue(Contract, "ARAPObjectSettings");
	ElsIf ThisIsOrder Then
		OrderOfCalculationsForDocument = Enums.ARAPObjectSettings.ByOrders;
	Else 
		OrderOfCalculationsForDocument = Enums.ARAPObjectSettings.ByARAPDocuments;
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return OrderOfCalculationsForDocument;
	
EndFunction

#EndRegion

#Region OtherProcedures

// Deprecated. Replaces settlement documents when calling settlement reports from the implementation.
// If the implementation is on the client's order, the settlement document is the client's order.
//
// Parameters:
// Parameters - FormDataStructure - Report parameter.
//
Procedure ReplaceCustomerSettlementDocuments(Parameters) Export
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("CustomerOrderSelection") Then
		
		SetPrivilegedMode(True);
		
		CustomerOrderParameter = Parameters.Filter.CustomerOrderSelection;
		
		Query = New Query("
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|INTO DocumentsData
		|FROM
		|	Document.SalesOrder AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.MaterialProviderOrder2_5 AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|			THEN DocumentData.Contract
		|		ELSE DocumentData.MaterialProviderOrder
		|	END AS ARAPObject
		|FROM
		|	Document.ReportToMaterialProvider2_5 AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|			OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	WHEN DocumentData.OrderSales AND NOT GoodsTable.SalesOrder IS NULL
		|		AND NOT DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) THEN
		|		GoodsTable.SalesOrder
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.CustomerInvoice AS DocumentData
		|		LEFT JOIN Document.CustomerInvoice.Goods AS GoodsTable
		|		ON GoodsTable.Ref = DocumentData.Ref
		|		AND DocumentData.OrderSales
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	WHEN DocumentData.InvoiceByOrders AND NOT TableServices.SalesOrder IS NULL
		|		AND NOT DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) THEN
		|		TableServices.SalesOrder
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.CustomerInvoiceServices AS DocumentData
		|		LEFT JOIN Document.CustomerInvoiceServices.Services AS TableServices
		|		ON TableServices.Ref = DocumentData.Ref
		|		AND DocumentData.InvoiceByOrders
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	WHEN DocumentData.SaleByOrders
		|		AND NOT DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) THEN
		|		GoodsTable.SalesOrder
		|	ELSE
		|		DocumentData.DocumentBasis
		|	END AS ARAPObject
		|FROM
		|	Document.SaleAdjustment AS DocumentData
		|		LEFT JOIN Document.SaleAdjustment.Goods AS GoodsTable
		|		ON GoodsTable.Ref = DocumentData.Ref
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	WHEN DocumentData.RequestForReturnOfGoodsFromCustomer <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|			AND NOT DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) THEN
		|		DocumentData.RequestForReturnOfGoodsFromCustomer
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.ReturnOfGoodsFromCustomer AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&SalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	RegisterData.ARAPObject AS ARAPObject
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS RegisterData
		|WHERE
		|	RegisterData.Recorder IN (&SalesOrder)
		|	AND RegisterData.ARAPObject.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DocumentsData.ARAPObject AS ARAPObject
		|FROM
		|	DocumentsData AS DocumentsData
		|");
		
		Query.SetParameter("SalesOrder", CustomerOrderParameter);
		
		DocumentsArray = Query.Execute().Unload().UnloadColumn("ARAPObject");
		
		If TypeOf(CustomerOrderParameter) = Type("Array") Then
			For Each CurItem In CustomerOrderParameter Do
				If TypeOf(CurItem) <> Type("DocumentRef.SalesOrder")
				 And TypeOf(CurItem) <> Type("DocumentRef.MaterialProviderOrder2_5")
				 And TypeOf(CurItem) <> Type("DocumentRef.ReportToMaterialProvider2_5")
				 And TypeOf(CurItem) <> Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
				 And TypeOf(CurItem) <> Type("DocumentRef.CustomerInvoice")
				 And TypeOf(CurItem) <> Type("DocumentRef.CustomerInvoiceServicesAndAssets")
				 And TypeOf(CurItem) <> Type("DocumentRef.CustomerInvoiceServices")
				 And TypeOf(CurItem) <> Type("DocumentRef.SaleAdjustment") Then
					DocumentsArray.Add(CurItem);
				EndIf;
			EndDo;
		ElsIf TypeOf(CustomerOrderParameter) <> Type("DocumentRef.SalesOrder")
		 And TypeOf(CustomerOrderParameter) <> Type("DocumentRef.MaterialProviderOrder2_5")
		 And TypeOf(CustomerOrderParameter) <> Type("DocumentRef.ReportToMaterialProvider2_5")
		 And TypeOf(CustomerOrderParameter) <> Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
		 And TypeOf(CustomerOrderParameter) <> Type("DocumentRef.CustomerInvoice")
		 And TypeOf(CustomerOrderParameter) <> Type("DocumentRef.CustomerInvoiceServicesAndAssets")
		 And TypeOf(CustomerOrderParameter) <> Type("DocumentRef.CustomerInvoiceServices")
		 And TypeOf(CustomerOrderParameter) <> Type("DocumentRef.SaleAdjustment") Then
		 	DocumentsArray.Add(CustomerOrderParameter);
		EndIf;
		
		For Counter = 0 To DocumentsArray.Count() - 1 Do
			If Not TypeOf(DocumentsArray[Counter]) = Type("CatalogRef.ARAPObjects") Then
				DocumentsArray[Counter] = ARAPObjectsServer.GetCalculationObjectFromLink(DocumentsArray[Counter]);
			EndIf;
		EndDo;
		
		Parameters.Filter.CustomerOrderSelection = DocumentsArray;
		
	EndIf;
	
EndProcedure

// Deprecated. Replaces documents calculations in the call report of settlement of revenues.
// If the receipt is for an order to a supplier , the payment document is an order to a supplier.
//
// Parameters:
// Parameters - FormDataStructure - Report parameter.
//
Procedure ReplaceDocumentsOfSettlementsWithSuppliers(Parameters) Export
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("OrderToSupplierSelection") Then
		
		SetPrivilegedMode(True);
		
		OrderToSupplierParameter = Parameters.Filter.OrderToSupplierSelection;
		
		Query = New Query("
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|			OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|INTO DocumentsData
		|FROM
		|	Document.PurchaseOrder AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&PurchaseOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.SubcontractOrder2_5 AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&PurchaseOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	WHEN DocumentData.ByOrders
		|		AND NOT DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) THEN
		|		DocumentData.SubcontractOrder
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.SubcontractorReport2_5 AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&PurchaseOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	WHEN DocumentData.ReceiptUnderOrders AND NOT GoodsTable.PurchaseOrder IS NULL
		|		AND NOT DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) THEN
		|		GoodsTable.PurchaseOrder
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.VendorInvoice AS DocumentData
		|		LEFT JOIN Document.VendorInvoice.Goods AS GoodsTable
		|		ON GoodsTable.Ref = DocumentData.Ref
		|		AND DocumentData.ReceiptUnderOrders
		|WHERE
		|	DocumentData.Ref IN (&PurchaseOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject
		|FROM
		|	Document.VendorInvoiceServicesAndAssets AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&PurchaseOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	RegisterData.ARAPObject.Object AS ARAPObject
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS RegisterData
		|WHERE
		|	RegisterData.Recorder IN (&PurchaseOrder)
		|	AND VALUETYPE(RegisterData.ARAPObject.Object) IN (TYPE(Document.BankAccountReceiptNote),
		|												TYPE(Document.BankAccountIssue),
		|												TYPE(Document.CashAccountReceiptNote),
		|												TYPE(Document.CashVoucher),
		|												TYPE(Document.PaymentCardTransaction),
		|												TYPE(Document.OBEntry),
		|												TYPE(Document.OBEntryARAP))
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DocumentsData.ARAPObject AS ARAPObject
		|FROM
		|	DocumentsData AS DocumentsData
		|");
		
		Query.SetParameter("PurchaseOrder", OrderToSupplierParameter);
		
		DocumentsArray = Query.Execute().Unload().UnloadColumn("ARAPObject");
		
		If TypeOf(OrderToSupplierParameter) = Type("Array") Then
			For Each CurItem In OrderToSupplierParameter Do
				If TypeOf(CurItem) <> Type("DocumentRef.PurchaseOrder")
				 And TypeOf(CurItem) <> Type("DocumentRef.SubcontractOrder2_5")
				 And TypeOf(CurItem) <> Type("DocumentRef.SubcontractorReport2_5")
				 And TypeOf(CurItem) <> Type("DocumentRef.VendorInvoice")
				 And TypeOf(CurItem) <> Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
					DocumentsArray.Add(CurItem);
				EndIf;
			EndDo;
		ElsIf TypeOf(OrderToSupplierParameter) <> Type("DocumentRef.PurchaseOrder")
		 And TypeOf(OrderToSupplierParameter) <> Type("DocumentRef.SubcontractOrder2_5")
		 And TypeOf(OrderToSupplierParameter) <> Type("DocumentRef.SubcontractorReport2_5")
		 And TypeOf(OrderToSupplierParameter) <> Type("DocumentRef.VendorInvoice")
		 And TypeOf(OrderToSupplierParameter) <> Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		 	DocumentsArray.Add(OrderToSupplierParameter);
		EndIf;
		
		For Counter = 0 To DocumentsArray.Count() - 1 Do
			If Not TypeOf(DocumentsArray[Counter]) = Type("CatalogRef.ARAPObjects") Then
				DocumentsArray[Counter] = ARAPObjectsServer.GetCalculationObjectFromLink(DocumentsArray[Counter]);
			EndIf;
		EndDo;
		
		Parameters.Filter.OrderToSupplierSelection = DocumentsArray;
		
	EndIf;
	
EndProcedure

// Deprecated. Returns the result of checking the number of classification options when the "use multiple Classificationsadjustments" option is disabled.
//
// Parameters:
// Count - Number - the number of items in the "Variantclassificationsadjustments" reference list.
// Form - ClientApplicationForm - form, the source of verification.
//
// Returns:
// Boolean - False if the check is passed, True if the check is not passed, issue an error message.
//
Function VerificationAndReportingOfDebtClassificationOptions(Count, Form) Export
	If Form = Undefined Then
		MessagePrefix = NStr("vi = 'Không thể điền trường ""Phương án phân loại công nợ"".';
							|ru = 'Не удалось заполнить поле ""Вариант классификации задолженности"".';
							|en = 'Cannot fill in field ""Time buckets for aging analysis"".'; fa = 'Cannot fill in field ""Time buckets for aging analysis"".';
							|it = 'Non è stato possibile compilare il campo ""Variante di classificazione del debito"".';
							|pl = 'Nie udało się wypełnić pole ""Wariant klasyfikacji zadłużenia"".';
							|tr = '""Yaşlandırma analizi için zaman dilimleri"" alanı doldurulamadı.'");
	Else
		MessagePrefix = "";
	EndIf;
	
	RefundStatus = False;
	If Count > 1 Then
		ErrorMessage = MessagePrefix + NStr("vi = 'Một số tùy chọn để phân loại nợ đã được giới thiệu trong CSTT.';
											|ru = 'В информационной базе введено несколько вариантов классификации задолженности.';
											|en = 'Several time buckets for aging analysis are specified in the infobase.'; fa = 'Several time buckets for aging analysis are specified in the infobase.';
											|it = 'Nel database informatico sono state inserite alcune varianti di classificazione del debito.';
											|pl = 'W bazie informacyjnej wprowadzono kilka wariantów klasyfikacji zobowiązania.';
											|tr = 'Infobase''de birden fazla yaşlandırma analizi için zaman dilimleri girildi.'") 
			+ Chars.LF + Chars.LF
			+ NStr("vi = 'Bật tùy chọn chức năng ""Doanh nghiệp - Nhiều tùy chọn phân loại nợ"".';
					|ru = 'Включите функциональную опцию ""Предприятие - Несколько вариантов классификации задолженности"".';
					|en = 'Enable the ""Enterprise - Several time buckets for aging analysis"" functional option.'; fa = 'Enable the ""Enterprise - Several time buckets for aging analysis"" functional option.';
					|it = 'Abilitare l''opzione funzionale ""Impresa - alcune varianti di classificazione di debito"".';
					|pl = 'Włącz funkcjonalną opcję "" Przedsiębiorstwo ---- kilka wariantów klasyfikacji zobowiązania"".';
					|tr = '""İşletme - Yaşlandırma analizi için zaman dilimleri"" işlevsel seçeneğini etkinleştir.'");
		Common.MessageToUser(ErrorMessage);
		RefundStatus = True;
	ElsIf Count <> 1 Then
		ErrorMessage = MessagePrefix + NStr("vi = 'Có thể, trong cơ sở thông tin chưa nhập phương án phân loại công nợ nào.';
											|ru = 'Возможно, в информационной базе не введено ни одного варианта классификации задолженности.';
											|en = 'Maybe, no time bucket for aging analysis is specified in the infobase.'; fa = 'Maybe, no time bucket for aging analysis is specified in the infobase.';
											|it = 'È probabile che nel database informatico non sia inserita alcuna variante di classificazione del debito.';
											|pl = 'Możliwe że w bazie informacyjnej nie wprowadzono ani jednego wariantu klasyfikacji zobowiązania.';
											|tr = 'Infobase''de herhangi bir yaşlandırma analizi için zaman dilimleri girilmemiş olabilir.'");
		Common.MessageToUser(ErrorMessage);
		RefundStatus = True;
	EndIf;

	Return RefundStatus;
EndFunction 

// Deprecated. Creates the structure of selections by partner and organization for contextually called reports 
//   on settlements with the client.
//
// Parameters:
//  DocumentsArray  - Array - array of documents that the report is parameterized with.
//  ReportName         - String - name of the report to call.
//  CommandName        - String - name of the command that is used to call the report.the report being called.
//  Types              - Array - Array of parameter types for the command calling the report.
//
// Returns:
//   Structure   - the formed selection structure, where:
//      * Partner - Array of CatalogRef.Partners
//      * Organization - Array of CatalogRef.Companies
//
Function StructureOfReportSelectionsSettlementsWithClients(DocumentsArray, ReportName, CommandName, Types = Undefined) Export
	
	FiltersStructure = New Structure;
	
	RequestTemplateForDocuments = "
	|SELECT 
	|	Document.Partner,
	|	Document.Organization
	|INTO DocumentsPartnersOfOrganization
	|FROM
	|	&TableName AS Document
	|WHERE
	|	Document.Ref IN(&DocumentsArray)";
	
	TextUnion = "
	|	
	|UNION ALL
	|";
	
	ThisIsFirstJoinRequest = True;
	
	QueryText = "";
	
	Collection = ?(ValueIsFilled(Types), Types, Metadata.Reports[ReportName].Commands[CommandName].CommandParameterType.Types());
	
	For Each CommandParameterType In Collection Do
		
		DocumentMetadataObject = Metadata.FindByType(CommandParameterType);
		If AccessRight("Read", DocumentMetadataObject) Then
			TableName = DocumentMetadataObject.Name;
			
			QueryTextByDocument = StrReplace(RequestTemplateForDocuments, "&TableName", "Document." + TableName);
			QueryTextByDocument = StrReplace(QueryTextByDocument, 
			                                      "INTO DocumentsPartnersOfOrganization",
			                                      ?(Not ThisIsFirstJoinRequest,"", "INTO DocumentsPartnersOfOrganization"));
			
			QueryText = QueryText + ?(ThisIsFirstJoinRequest, "", TextUnion) + QueryTextByDocument;
			
			ThisIsFirstJoinRequest = False;
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = QueryText;
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text = "
	|SELECT ALLOWED DISTINCT
	|	DocumentsPartnersOfOrganization.Partner
	|FROM
	|	Catalog.Partners AS Partners
	|		INNER JOIN DocumentsPartnersOfOrganization AS DocumentsPartnersOfOrganization
	|		ON Partners.Ref = DocumentsPartnersOfOrganization.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	DocumentsPartnersOfOrganization.Organization
	|FROM
	|	Catalog.Companies AS Companies
	|		INNER JOIN DocumentsPartnersOfOrganization AS DocumentsPartnersOfOrganization
	|		ON Companies.Ref = DocumentsPartnersOfOrganization.Organization";
	
	
	Result = Query.ExecuteBatch();
	
	FiltersStructure.Insert("Partner", Result[0].Unload().UnloadColumn("Partner"));
	FiltersStructure.Insert("Organization", Result[1].Unload().UnloadColumn("Organization"));
	
	Return FiltersStructure;
	
EndFunction

// The possible amount of debiting from the current balance is determined - the entire balance or only part of the balance equal to the amount of debiting.
// This reduces the current balance by the amount of debiting and the amount of debiting itself.
//
// Parameters:
//  Amount_Balance - Number - The current balance from which the amount must be debited.
//  AmountToBeDebited_ - Number - the amount to be debited.
//  LastPart - Boolean - if true, then write off the entire balance.
//
// Returns:
//  Number - the amount to be debited or the entire Balance if it is less than the specified amount or
//          The last part = The truth.
//
Function DeductAmount(Amount_Balance, AmountToBeDebited_, LastPart = False) Export
	
	DebitedAmount = 0;
	ToWriteOff = Max(AmountToBeDebited_, -AmountToBeDebited_);
	Character = ?(ToWriteOff = 0, 1, AmountToBeDebited_/ToWriteOff);
	
	If Amount_Balance >= ToWriteOff And Not LastPart Then
		DebitedAmount = ToWriteOff;
		Amount_Balance = Amount_Balance - DebitedAmount;
		ToWriteOff = 0;
	Else
		DebitedAmount = Amount_Balance;
		ToWriteOff = ToWriteOff - DebitedAmount;
		Amount_Balance = 0;
	EndIf;
	
	AmountToBeDebited_ = Character * ToWriteOff;
	
	Return DebitedAmount;
	
EndFunction

// The possible amount of deduction from the current balance of one indicator 
// is determined in proportion to the amount already deducted for another indicator.
// This reduces the current balance.
//
// Parameters:
//	Amount_Balance - Number - The current balance from which the amount must be debited.
//	AmountCredited - Number - The amount that has already been debited from another indicator.
//	AmountTotal - Number - Amount at a different rate to the cancellation.
//
// Returns:
//	Number - the amount to be debited.
//
Function WriteOffAmountProportionally(Amount_Balance, AmountCredited, AmountTotal) Export
	
	AmountToBeDebited_ = 0;
	If AmountTotal > 0 Then
		AmountToBeDebited_ = Round(Amount_Balance * AmountCredited / AmountTotal, 2);
	EndIf;
	
	Return DeductAmount(Amount_Balance, AmountToBeDebited_);
	
EndFunction

// Deprecated. Function-constructor of the mutual settlement procedure Server.Fill out the payment decryption for the client's account.
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
	
	Return ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
	
EndFunction

// Deprecated. The function returns the maximum date from a temporary table that contains a list of documents.
//
// Parameters:
//	TempTablesManager - TempTablesManager - Contains a temporary table of document data Tables,
//														with a list of documents of the same type.
// Returns:
// 	Date - The maximum date in the collection of documents.
Function GetMaximumDateInDocumentCollection(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	ISNULL(MAX(DocumentCollection.Ref.DATE), UNDEFINED) AS Period
	|FROM
	|	DocumentDataTable_ AS DocumentCollection
	|");
	
	Query.TempTablesManager = TempTablesManager;
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		MaxDate = Result.Unload()[0].Period;
		
		If MaxDate = Undefined Then
			MaxDate = CurrentSessionDate();
		EndIf;
	Else
		MaxDate = CurrentSessionDate();
	EndIf;
	
	Return MaxDate;
EndFunction

// Deprecated. The procedure generates entries in the "tasks for distribution of accounts with clients" information register
// if the current document changes entries in the "accounts With clients"register.
// Parameters:
//	Document - DocumentRef - Link to the registration document
//	TempTablesManager - TempTablesManager - Contains a temporary table of changes.
Procedure ReflectTasksForDistributionOfSettlementsWithCustomers(Document, TempTablesManager) Export
	
	If Constants.NewOnlineARAPAccounting.Get() Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccountingServer.ReflectTasksForDistributionOfSettlementsWithCustomers");
	
	TemporaryTable = TempTablesManager;
	
	If (TemporaryTable.Tables.Find("SettlementsWithCustomersChanges") <> Undefined
			Or TemporaryTable.Tables.Find("SettlementsWithClientsAccordingToDocumentsTasksForSettlementsWithClients") <> Undefined)
		And ExchangePlans.MasterNode() = Undefined Then // there are changes in the operational register
		
		NestedRequestTemplate_ = "
		|SELECT
		|	Table.Month                        AS Month,
		|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|	Keys.Organization                    AS Organization,
		|	Table.ARAPObject               AS ARAPObject,
		|	Table.Document                     AS Document
		|FROM
		|	&DataTable AS Table
		|
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Keys
		|	ON Keys.Ref = Table.AccountingDimensionByPartners
		|";
		
		TemplateTextDestructionTT = "
		|;
		|//////////////////////////////
		|DROP &DataTable
		|";
		
		TextDestructionW = "";
		NestedQuery = "";
		NumberOfTables = 0;
		
		If TemporaryTable.Tables.Find("SettlementsWithCustomersChanges") <> Undefined Then
			NestedQuery = StrReplace(NestedRequestTemplate_, "&DataTable", "(" + TestRequestDistributionOfSettlementsWithCustomers() + ")");
			NestedQuery = StrReplace(NestedQuery, "Keys.Organization", "Table.Organization");
			NumberOfTables = NumberOfTables + 1;
		EndIf;
		
		If TemporaryTable.Tables.Find("SettlementsWithClientsAccordingToDocumentsTasksForSettlementsWithClients") <> Undefined Then
			If NumberOfTables = 0 Then
				NestedQuery = StrReplace(NestedRequestTemplate_, "&DataTable", "SettlementsWithClientsAccordingToDocumentsTasksForSettlementsWithClients");
				TextDestructionW = StrReplace(TemplateTextDestructionTT, "&DataTable", "SettlementsWithClientsAccordingToDocumentsTasksForSettlementsWithClients");
			Else
				NestedQuery = NestedQuery + "
					|UNION ALL
					|"
					+ StrReplace(NestedRequestTemplate_, "&DataTable", "SettlementsWithClientsAccordingToDocumentsTasksForSettlementsWithClients");
				TextDestructionW = TextDestructionW + StrReplace(TemplateTextDestructionTT, "&DataTable", "SettlementsWithClientsAccordingToDocumentsTasksForSettlementsWithClients");
			EndIf;
			NumberOfTables = NumberOfTables + 1;
		EndIf;
		
		If NumberOfTables = 1 Then
			QueryText = NestedQuery + TextDestructionW;
		Else
			QueryTextTemplate2 = "
			|SELECT DISTINCT
			|	Table.Month                        AS Month,
			|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
			|	Table.Organization                  AS Organization,
			|	Table.ARAPObject               AS ARAPObject,
			|	Table.Document                     AS Document
			|FROM
			|	(SELECT &NestedQuery
			|	) AS Table
			|
			|";
			QueryText = StrReplace(QueryTextTemplate2, "SELECT &NestedQuery", NestedQuery) + TextDestructionW;
		EndIf;
		
		Query = New Query(QueryText);
		Query.TempTablesManager = TemporaryTable;
		Query.SetParameter("NewCalculations", GetFunctionalOption("NewOnlineARAPAccounting"));
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			RecordSet = InformationRegisters.JobsForAllocatingCustomersARAP.CreateRecordManager();
			FillPropertyValues(RecordSet, Selection);
			RecordSet.JobNumber = Constants.NumberOfJobForAllocatingCustomersARAP.Get();
			RecordSet.Write();
		EndDo;
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

// Deprecated. The procedure generates entries in the "tasks for distribution of accounts payable" information register
// if the current document changes entries in the "accounts payable"register.
//
// Parameters:
//  Document - DocumentRef - Link to the registration document
//  TempTablesManager - TempTablesManager - Contains a temporary table of changes.
//
Procedure ReflectTasksForDistributionOfSettlementsWithSuppliers(Document, TempTablesManager) Export
	
	If Constants.NewOnlineARAPAccounting.Get() Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccountingServer.ReflectTasksForDistributionOfSettlementsWithSuppliers");

	TemporaryTable = TempTablesManager;
	
	If (TemporaryTable.Tables.Find("VendorsARAPAccountingChanges") <> Undefined
			Or TemporaryTable.Tables.Find("SettlementsWithSuppliersAccordingToDocumentsOfTaskForSettlementsWithSuppliers") <> Undefined)
		And ExchangePlans.MasterNode() = Undefined Then // there are changes in the operational register
		
		NestedRequestTemplate_ = "
		|SELECT
		|	Table.Month                        AS Month,
		|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|	Keys.Organization                    AS Organization,
		|	Table.ARAPObject               AS ARAPObject,
		|	Table.Document                     AS Document
		|FROM
		|	&DataTable AS Table
		|
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Keys
		|	ON Keys.Ref = Table.AccountingDimensionByPartners
		|";
		
		TemplateTextDestructionTT = "
		|;
		|//////////////////////////////
		|DROP &DataTable
		|";
		
		TextDestructionW = "";
		NestedQuery = "";
		NumberOfTables = 0;
		
		If TemporaryTable.Tables.Find("VendorsARAPAccountingChanges") <> Undefined Then
			NestedQuery = StrReplace(NestedRequestTemplate_, "&DataTable", "(" + TestRequestDistributionOfSettlementsWithSuppliers() + ")");
			NestedQuery = StrReplace(NestedQuery, "Keys.Organization", "Table.Organization");
			NumberOfTables = NumberOfTables + 1;
		EndIf;
		
		If TemporaryTable.Tables.Find("SettlementsWithSuppliersAccordingToDocumentsOfTaskForSettlementsWithSuppliers") <> Undefined Then
			If NumberOfTables = 0 Then
				NestedQuery = StrReplace(NestedRequestTemplate_, "&DataTable", "SettlementsWithSuppliersAccordingToDocumentsOfTaskForSettlementsWithSuppliers");
				TextDestructionW = StrReplace(TemplateTextDestructionTT, "&DataTable", "SettlementsWithSuppliersAccordingToDocumentsOfTaskForSettlementsWithSuppliers");
			Else
				NestedQuery = NestedQuery + "
					|UNION ALL
					|"
					+ StrReplace(NestedRequestTemplate_, "&DataTable", "SettlementsWithSuppliersAccordingToDocumentsOfTaskForSettlementsWithSuppliers");
				TextDestructionW = TextDestructionW + StrReplace(TemplateTextDestructionTT, "&DataTable", "SettlementsWithSuppliersAccordingToDocumentsOfTaskForSettlementsWithSuppliers");
			EndIf;
			NumberOfTables = NumberOfTables + 1;
		EndIf;
		
		If NumberOfTables = 1 Then
			QueryText = NestedQuery + TextDestructionW;
		Else
			QueryTextTemplate2 = "
			|SELECT DISTINCT
			|	Table.Month                        AS Month,
			|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
			|	Table.Organization                  AS Organization,
			|	Table.ARAPObject               AS ARAPObject,
			|	Table.Document                     AS Document
			|FROM
			|	(SELECT &NestedQuery
			|	) AS Table
			|
			|";
			QueryText = StrReplace(QueryTextTemplate2, "SELECT &NestedQuery", NestedQuery) + TextDestructionW;
		EndIf;
		
		Query = New Query(QueryText);
		Query.TempTablesManager = TemporaryTable;
		Query.SetParameter("NewCalculations", GetFunctionalOption("NewOnlineARAPAccounting"));
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			RecordSet = InformationRegisters.JobsForAllocatingVendorsARAP.CreateRecordManager();
			FillPropertyValues(RecordSet, Selection);
			RecordSet.JobNumber = Constants.NumberOfJobForAllocatingVendorsARAPAccounting.Get();
			RecordSet.Write();
		EndDo;
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

// Deprecated.
// The function determines whether the transferred business operation is an intercampany operation.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - Business operation for verification.
//
// Returns:
//	Boolean - True if it is an intercampany operation.
//
Function IntercompanyBusinessTransaction(BusinessOperation) Export
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromOtherCompany") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Deprecated.
// The function determines whether the transferred business transaction is an operation with the client.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - Business operation for verification.
//
// Returns:
//	Boolean - True if it is an operation with a client.
//
Function BusinessTransactionWithClient(BusinessOperation) Export
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Deprecated.
// The function determines whether the transferred business transaction is an operation with a supplier.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - Business operation for verification.
//
// Returns:
//	Boolean - True if it is an operation with a supplier.
//
Function BusinessTransactionWithSupplier(BusinessOperation) Export
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PaymentToVendor") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromVendor") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CustomsPayment") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Deprecated.
// The function determines whether the transferred business transaction is a refund operation.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - Business operation for verification.
//
// Returns:
//	Boolean - True if it is a refund operation.
//
Function BusinessOperationRefundOfFunds(BusinessOperation) Export
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromVendor")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Getting a list of counterparties for transactions for sending invitations.
//
// Parameters:
//  Organization			 - CatalogRef - link to the organization that the invitation is being issued from.
//  FillMode		 - String - counterparty filling mode: "fill in for Deliveries", "fill in for Purchases", "fill in for purchases".
//  BeginOfPeriod		 - Date - start of the fill-in period.
//  ListOfCounterparties_	 - ValueTable - List Of Counterparties:
//    * Ref - CatalogRef - Contractor.
//    * Email - String - email address.
//
Procedure GetCounterpartiesForTransactions(Organization, FillMode, BeginOfPeriod, ListOfCounterparties_) Export
	
	Query = New Query;
	Query.SetParameter("DeliveryServices",   FillMode = "DeliveryServices");
	Query.SetParameter("PurchasingManager",    FillMode = "PurchasingManager");
	Query.SetParameter("FillInAllTransactions", FillMode = "FillInAllTransactions");
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("Organization",   Organization);
	
	Query.Text =
	"SELECT DISTINCT
	|	Counterparties.Ref AS Ref
	|FROM
	|	(SELECT DISTINCT
	|		DimensionKeysOfAccountingByPartners.Counterparty AS Ref
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting.Turnovers(&BeginOfPeriod, , , ) AS SettlementsWithCustomersTurnover
	|			LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON SettlementsWithCustomersTurnover.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|	WHERE
	|		DimensionKeysOfAccountingByPartners.Organization = &Organization
	|		AND (&DeliveryServices
	|				OR &FillInAllTransactions)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		DimensionKeysOfAccountingByPartners.Counterparty
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting.Turnovers(&BeginOfPeriod, , , ) AS SettlementsWithSuppliersTurnover
	|			LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON SettlementsWithSuppliersTurnover.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|	WHERE
	|		DimensionKeysOfAccountingByPartners.Organization = &Organization
	|		AND (&PurchasingManager
	|				OR &FillInAllTransactions)) AS Counterparties
	|
	|ORDER BY
	|	Counterparties.Ref";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If TypeOf(Selection.Ref) = Type("CatalogRef.Counterparties") Then
			NewRow = ListOfCounterparties_.Add();
			FillPropertyValues(NewRow, Selection);
		EndIf;
	EndDo;
	
EndProcedure


// Deprecated. The function returns a reference to the calculation object of the passed reference.
//
// Parameters:
//		ObjectRef - DefinedType.ARAPObject - The document for which you need to determine the object of calculations.
//
// Returns:
// 		DefinedType.ARAPObject - The object of calculations of the document..
//
Function ObjectOfCalculationsByReference(ObjectRef) Export
	
	If CommonClientServer.HasAttributeOrObjectProperty(ObjectRef, "ARAPObjectSettings") Then 
		Order = Common.ObjectAttributeValue(ObjectRef, "ARAPObjectSettings");
		If Order = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
			If TypeOf(ObjectRef) = Type("CatalogRef.CounterpartyContracts") 
				Or TypeOf(ObjectRef) = Type("CatalogRef.IntercompanyContracts") Then
				Return ObjectRef
			Else
				Return Common.ObjectAttributeValue(ObjectRef, "Contract");
			EndIf;
		ElsIf Order = Enums.ARAPObjectSettings.ByOrders 
			And CommonClientServer.HasAttributeOrObjectProperty(ObjectRef, "SalesOrder") Then
			OrderDocument = Common.ObjectAttributeValue(ObjectRef, "SalesOrder");
			If ValueIsFilled(OrderDocument) Then
				Return OrderDocument;
			EndIf;
		ElsIf Order = Enums.ARAPObjectSettings.ByOrders 
			And CommonClientServer.HasAttributeOrObjectProperty(ObjectRef, "PurchaseOrder") Then
			OrderDocument = Common.ObjectAttributeValue(ObjectRef, "PurchaseOrder");
			If ValueIsFilled(OrderDocument) Then
				Return OrderDocument;
			EndIf;
		EndIf;
	EndIf;
	
	Return ObjectRef;
	
EndFunction

// See ReportsTMOverridable.SupplementComplianceOfTrafficReportRegistrars
//
Procedure SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching) Export
	
	If Document.Metadata().RegisterRecords.Contains(Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		RegisterMatching.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates, "DocumentRecorder");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan, "DocumentRecorder");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingPlannedShipments, "DocumentRecorder");
	EndIf;
	
	If Document.Metadata().RegisterRecords.Contains(Metadata.AccumulationRegisters.VendorsARAPAccounting) Then
		RegisterMatching.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates, "DocumentRecorder");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan, "DocumentRecorder");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries, "DocumentRecorder");
	EndIf;
	
	If TypeOf(Document) = Type("DocumentRef.ExchangeDifferenceCalculation") Then
		RegisterMatching.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates, "DocumentRecorder");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates, "DocumentRecorder");
	EndIf;
	
EndProcedure


// Returns the Query Text for creating a temporary batch payment table.
//
// Parameters:
//  NameOfInputDataTable - String - Name of the input data table. The table should contain a Batch column.
//  NameOfPaymentTable - String - Name of the resulting payment table
//
// Returns:
// 	String - The text of the request that forms a temporary table of batch payments. The table contains columns: Batch, Document payments, Data payments, Payment amount.
// 			
Function QueryTextOfBatchPaymentDataTable(NameOfInputDataTable, NameOfPaymentTable) Export
	
	QueryText = "
	|SELECT DISTINCT
	|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	VendorsARAPAccounting.Recorder AS Lot
	|INTO TTCalculationSelection
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|WHERE
	|	VendorsARAPAccounting.Recorder IN
	|			(SELECT
	|				T.Lot
	|			FROM
	|				#NameOfInputDataTable AS T)
	|	AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization IN (&CompaniesList)
	|	AND VendorsARAPAccounting.Active
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationsByTerms.ARAPDocument   AS ARAPDocument,
	|	CalculationsByTerms.ARAPObject      AS ARAPObject,
	|	CalculationsByTerms.DocumentRecorder AS DocumentPayments,
	|	SUM(&Paid)                    AS Paid,
	|	0                                   AS SetOff
	|INTO TTCalculationsByTerms
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|WHERE
	|	(CalculationsByTerms.AccountingDimensionByPartners, 
	|	 CalculationsByTerms.ARAPObject, 
	|	 CalculationsByTerms.ARAPDocument) IN
	|			(SELECT
	|				T.AccountingDimensionByPartners,
	|				T.ARAPObject,
	|				T.Lot
	|			FROM
	|				TTCalculationSelection AS T)
	|	AND CalculationsByTerms.Active
	|	AND CalculationsByTerms.Period <= &EndOfMonth
	|
	|GROUP BY
	|	CalculationsByTerms.DocumentRecorder,
	|	CalculationsByTerms.ARAPObject,
	|	CalculationsByTerms.ARAPDocument
	|
	|HAVING
	|	SUM(&Paid) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationsByTerms.ARAPDocument    AS ARAPDocument,
	|	CalculationsByTerms.ARAPObject       AS ARAPObject,
	|	CalculationsByTermsBalanced.ARAPDocument AS DocumentPayments,
	|	SUM(0)                             AS Paid,
	|	SUM(&SetOff)                      AS SetOff
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|		INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTermsBalanced
	|		ON CalculationsByTerms.AccountingDimensionByPartners = CalculationsByTermsBalanced.AccountingDimensionByPartners
	|			AND CalculationsByTerms.Currency = CalculationsByTermsBalanced.Currency
	|			AND CalculationsByTerms.BusinessTransactionSetting = CalculationsByTermsBalanced.BusinessTransactionSetting
	|			AND CalculationsByTerms.FinRecordID = CalculationsByTermsBalanced.FinRecordID
	|			AND CalculationsByTerms.ARAPDocument <> CalculationsByTermsBalanced.ARAPDocument
	|WHERE
	|	(CalculationsByTerms.AccountingDimensionByPartners, 
	|	 CalculationsByTerms.ARAPObject, 
	|	 CalculationsByTerms.ARAPDocument) IN
	|			(SELECT
	|				T.AccountingDimensionByPartners,
	|				T.ARAPObject,
	|				T.Lot
	|			FROM
	|				TTCalculationSelection AS T)
	|	AND CalculationsByTerms.Active
	|	AND CalculationsByTerms.Period <= &EndOfMonth
	|
	|GROUP BY
	|	CalculationsByTerms.ARAPDocument,
	|	CalculationsByTerms.ARAPObject,
	|	CalculationsByTermsBalanced.ARAPDocument
	|
	|HAVING
	|	SUM(&SetOff) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationsByTerms.ARAPDocument    AS ARAPDocument,
	|	CalculationsByTerms.ARAPObject       AS ARAPObject,
	|	CalculationsByTermsBalanced.DocumentRecorder AS DocumentPayments,
	|	SUM(0)                             AS Paid,
	|	SUM(&SetOff)                      AS SetOff
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|		INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTermsBalanced
	|		ON CalculationsByTerms.AccountingDimensionByPartners = CalculationsByTermsBalanced.AccountingDimensionByPartners
	|			AND CalculationsByTerms.Currency = CalculationsByTermsBalanced.Currency
	|			AND CalculationsByTerms.BusinessTransactionSetting = CalculationsByTermsBalanced.BusinessTransactionSetting
	|			AND CalculationsByTerms.FinRecordID = CalculationsByTermsBalanced.FinRecordID
	|			AND CalculationsByTerms.ARAPDocument = CalculationsByTermsBalanced.ARAPDocument
	|			AND VALUETYPE(CalculationsByTermsBalanced.DocumentRecorder) = TYPE(Document.ARAPSettlement)
	|WHERE
	|	(CalculationsByTerms.AccountingDimensionByPartners, 
	|	 CalculationsByTerms.ARAPObject, 
	|	 CalculationsByTerms.ARAPDocument) IN
	|			(SELECT
	|				T.AccountingDimensionByPartners,
	|				T.ARAPObject,
	|				T.Lot
	|			FROM
	|				TTCalculationSelection AS T)
	|	AND CalculationsByTerms.Active
	|	AND CalculationsByTerms.Period <= &EndOfMonth
	|
	|GROUP BY
	|	CalculationsByTerms.ARAPDocument,
	|	CalculationsByTerms.ARAPObject,
	|	CalculationsByTermsBalanced.DocumentRecorder
	|
	|HAVING
	|	SUM(&SetOff) <> 0
	|
	|INDEX BY
	|	DocumentPayments,
	|	ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationsByTerms.DocumentPayments AS DocumentPayments,
	|	CalculationsByTerms.ARAPObject AS ARAPObject,
	|	SUM(ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, DocumentAmountsInAccountingCurrenciesAreSummarized.AmountExcludingVATCompl)) AS AmountExcludingVAT,
	|	SUM(ISNULL(DocumentAmountsInAccountingCurrency.VATAmountCompl, DocumentAmountsInAccountingCurrenciesAreSummarized.VATAmountCompl)) AS VATAmount
	|INTO TTOfAmountOfPaymentDocuments
	|FROM
	|	TTCalculationsByTerms AS CalculationsByTerms
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|		ON CalculationsByTerms.DocumentPayments = DocumentAmountsInAccountingCurrency.Recorder
	|			AND CalculationsByTerms.ARAPObject = DocumentAmountsInAccountingCurrency.ARAPObject
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrenciesAreSummarized
	|		ON CalculationsByTerms.DocumentPayments = DocumentAmountsInAccountingCurrenciesAreSummarized.Recorder
	|
	|GROUP BY
	|	CalculationsByTerms.DocumentPayments,
	|	CalculationsByTerms.ARAPObject
	|
	|INDEX BY
	|	DocumentPayments,
	|	ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationsByTerms.ARAPDocument AS ARAPDocument,
	|	CalculationsByTerms.DocumentPayments AS DocumentPayments,
	|	SUM((CalculationsByTerms.Paid + CalculationsByTerms.SetOff) 
	|		* ISNULL(AmountsOfPaymentDocuments.AmountExcludingVAT, 0)
	|		/ (CASE 
	|				WHEN ISNULL((AmountsOfPaymentDocuments.AmountExcludingVAT + AmountsOfPaymentDocuments.VATAmount), 0) <> 0
	|					THEN (AmountsOfPaymentDocuments.AmountExcludingVAT + AmountsOfPaymentDocuments.VATAmount)
	|					ELSE 1 
	|				END)) AS AmountOfPaymentWithoutVAT
	|INTO TTOfPaymentForSettlementDocuments
	|FROM
	|	TTCalculationsByTerms AS CalculationsByTerms
	|	LEFT JOIN
	|		TTOfAmountOfPaymentDocuments AS AmountsOfPaymentDocuments
	|	ON
	|		CalculationsByTerms.DocumentPayments = AmountsOfPaymentDocuments.DocumentPayments
	|		AND CalculationsByTerms.ARAPObject = AmountsOfPaymentDocuments.ARAPObject
	|
	|GROUP BY
	|	CalculationsByTerms.ARAPDocument,
	|	CalculationsByTerms.DocumentPayments
	|
	|INDEX BY
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInputData.Lot AS Lot,
	|	ISNULL(PaymentOfSettlementDocuments.DocumentPayments, UNDEFINED) AS DocumentPayments,
	|	ISNULL(BEGINOFPERIOD(DocumentsRegistry.IBDocumentDate, DAY), DATETIME(1, 1, 1)) AS PayDate,
	|	ISNULL(PaymentOfSettlementDocuments.AmountOfPaymentWithoutVAT, 0) AS PayAmount
	|INTO #NameOfPaymentTable
	|FROM
	|	#NameOfInputDataTable AS TTInputData
	|
	|		LEFT JOIN TTOfPaymentForSettlementDocuments AS PaymentOfSettlementDocuments
	|		ON TTInputData.Lot = PaymentOfSettlementDocuments.ARAPDocument
	|
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON PaymentOfSettlementDocuments.DocumentPayments = DocumentsRegistry.Ref
	|
	|INDEX BY
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTCalculationSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTCalculationsByTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTOfAmountOfPaymentDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTOfPaymentForSettlementDocuments
	|";
	
	QueryText = StrReplace(QueryText, "#NameOfInputDataTable", NameOfInputDataTable);
	QueryText = StrReplace(QueryText, "#NameOfPaymentTable", NameOfPaymentTable);
	QueryText = StrReplace(QueryText, "&Paid", TemplateForPaidToSupplierField());
	QueryText = StrReplace(QueryText, "&SetOff", FieldTemplateCreditedBySupplier());
	// We get data in the currency:
	//  4 - mutual settlements
	//  2 - management accounting
	//  3 - regulated accounting
	QueryText = StrReplace(QueryText,"&ReportData", "3");
	
	Return QueryText;

EndFunction

#EndRegion

#Region CreatingTasksForEndOfMonth

// Deprecated. Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	
	MonthEndClosingARAPAccounting.AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames);
	
EndProcedure

#EndRegion

#Region Modularity

#Region CommonProgrammingInterface

// Returns the structure of parameters of the settlement mechanism.
// Parameters are described either by a path to the object data, or by a fixed value of the Boolean, String, and so on.
// The data path can lead to the document header ("Object.Organization"), and in the table part ("Object.Decryption of the payment.Partner").
// Several parameter structures can be set in a single document (for example, a report from a Commission agent).
// For embedding in documents, we recommend using a template at the end of the method.
//
// Returns:
// 	Structure - Structure of parameters with keys:
// 		* FormItems - Structure - The names of the form elements used to associate the element with the Cur parameters:
// 			** PaymentSettlement - String - The name of the element that is calling the helper classification fees.
// 			** AmountOfTSSettlements - String - Name of the element that displays the settlement Amount column in the main table part.
// 			** HyperlinkPaymentDecryption - String - Name of the element that displays the amount of the payment transcript and opens its editing.
// 			** ARAPDetails - String - Name of the element that displays the payment Description table part on the form.
// 			** AddToPaymentDecryption - String - Name of the button that calls the selection in the payment transcript.
// 			** LabelCurrencies - String - Name of the hyperlink that displays the currency and exchange rate of the document and calls the form for editing them.
// 			** InscriptionStages - String - Name of the hyperlink that displays the payment schedule and opens the payment rules editing form.
// 			** InscriptionCalculations - String - Name of the hyperlink that displays the settlement status and opens the settlement report.
// 			** DebtLimitationText - String - Name of the hyperlink that displays the text of the debt limit and opens the corresponding report.
// 			** DebtLimitation - String - Name of the image that displays an exclamation mark when debt is restricted.
// 		* ThisIsOrder - Boolean - This is the order document on the basis of which invoices will be entered.
// 		* IsCatalog - Boolean - This is a reference book (contracts or claims).
// 		* ThisIsSalePurchase - Boolean - This is an invoice document.
// 		* PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of settlement.
// 		* ChangesPaymentPlan - Boolean - Reduces or increases payment plans from the customer or supplier.
// 		* ModifiesDeliveryShipmentPlan - Boolean - Reduces or increases the shipment or delivery plan.
// 		* ItCanBeARAPObject - Boolean - False if you don't need to create an AR/AP object.
// 		
// 		* Date - String - Path to the object's details containing the document date.
// 		* DocumentCurrency - String - The path to the item details containing the document currency.
// 		* DocumentAmount - String - Path to the object's details containing the document amount in the document's currency.
// 		* Organization - String- The path to the item details that contain the organization that the business operation is performed on behalf of.
// 		* Partner - String - The path to the object's details containing the partner that the organization is settling accounts with.
// 		* Counterparty - String - The path to the item details that contain the counterparty or organization that the organization has settlements with.
// 		
// 		* ARAPCurrency - String - The path to the item's details containing the currency used for the organization's settlements with the counterparty.
// 		* AmountARAP - String - The path to the item's details, which contains the total amount of mutual settlements of the document, without taking into account the Deposit for the container.
// 		* AmountVATARAP - String - The path to the object's details containing the amount of VAT in the currency of mutual settlements.
// 		* AmountARAPByPackage - String - The path to the item details containing the total amount of the Deposit for the container.
// 		
// 		* Contract - String - The path to the item details that contain the organization's contract with the counterparty, within which settlements occur.
// 		* LineOfBusiness - String - The path to the item's details, which contains the direction of the organization's activity, within which mutual settlements should be reflected.
// 		* ARAPObjectSettings - String - The path to the object's details containing the document calculation order.
// 		* DocumentAmountForm - String - Path to the form details containing the amount of the document including the collateral container.
// 		
// 		* PathToTSData - String - The path to the object's details containing the main table part of the document.
// 		* PropsNameTSAmountWithVAT - String - The name of the details of the tabular part containing the amount of the VAT line in the currency of the document.
// 		* PropsNameTSOrder  - String - Name of the details of the table part containing the order for which the shipment/delivery is made.
// 		
// 		* PathToTSDataPaymentDecryption - String - The path to the item details that contain the table part "payment Decryption" of the document.
// 		* Terms - String - The path to the object's details that contain the agreement with the customer or supplier.
// 		* CompanyBankAccount - String - The path to the item details that contain the organization's Bank account.
// 		* CounterpartyBankAccount - String - The path to the item details containing the counterparty's Bank account.
// 		* CashAccount - String - The path to the item details containing the cash register.
// 		* PaymentMethod - String - The path to the item details containing the payment form.
// 		* ForeignCurrencyTransaction - String - Path to the item's details containing the "Payment in currency" attribute.
// 		* PaymentID - String - Path to the object's details containing the payment ID.
// 		* FinancialAccountingGroup - String - The path to the item details that contain the financial accounting group of calculations.
// 		* ARAPObject - String - Let's go to the item's details or the PM column that stores the reference / links to the calculation Objects reference list.
// 		* Ref - String - Let's add a link to the details That will be the object of calculations when calculating invoices.
// 		* Department - String - Path to the object's details containing the division.
// 		* Manager - String - Path to the object's details containing the responsible Manager.
// 		* IncomingDocumentNumber - String - Path to the object's details containing the number of the incoming document.
// 		* IncomingDocumentDate - String - Path to the object's details containing the date of the incoming document.
// 		* SourceDocumentName - String - The path to the item details containing the name of the primary document.
// 		
// 		* InvoiceForOrders - String - The path to the object's details that indicates that the document was entered by order.
// 		* OrderBase - String - The path to the item details containing the order for which the document was entered.
// 		* PartnerOtherRelations - Boolean - True, if you should only select partners with the "other relationships" attribute.
// 		* SelectAccountsReceivable - Boolean - True if accounts receivable is selected.
// 		* SelectOnlyUnconditionalDebt - Boolean - True if only the actual debt is selected.
// 		* PaymentByRequests - String - The path to the payment document flag for requests for spending funds.
// 		
// 		* CourseNumerator - String - The path to the object's details containing the exchange rate-the numerator of the document's currency relative to the currency of mutual settlements.
// 		* CourseDenominator - String - The path to the object's details containing the exchange rate-the denominator of the document's currency relative to the currency of mutual settlements.
// 		* CurrencyAndExchangeRateDocumentViewOnly - Boolean - True if nothing can be changed in the document's currency and exchange rate editing form.
// 		* DocumentCurrencyViewOnly - Boolean - True if you can't change the document currency in the document currency and exchange rate editing form.
// 		* MutualSettlementsCurrencyViewOnly - Boolean - True if you can't change the settlement currency in the document's currency and exchange rate editing form.
// 		* DonTShowCalculations - Boolean - True if you want to hide the currency and settlement amount in the document's currency and exchange rate editing form.
// 		* DoNotRecalculateTheAmountOfTheDocument - Boolean - True if you don't need to offer to recalculate the document amount in the document currency and exchange rate editing form.
// 		
// 		* PathToTSDataPaymentSteps - String - The path to the item details containing the table part of the payment schedule stages.
// 		* PaymentDate - String - The path to the item's details containing the date of the planned payment for the document.
// 		* PaymentSchedule - String - The path to the item details that contain the document payment schedule template.
// 		* ApprovalDate - String - The path to the object's details containing the date from which the stages of the payment schedule should be counted from the date of approval.
// 		* DateOfShipment - String - The path to the object's details containing the date from which the stages of the payment schedule should be counted from/to the date of shipment and from the date of transfer of ownership.
// 		
// 		* AmountOfDepositForContainerForm - String - Path to the form details containing the Deposit amount for the container in the document currency.
// 		* PaymentStagesViewOnly - Boolean - The view only flag for the payment rules editing form that is being opened.
// 		* InvoiceForSeveralOrdersIsPossible - Boolean - True if the invoice can be entered for multiple orders.
// 		* SourceOfAmountsTabularPart - Boolean - True if the object provides an interface to place the sum of the order in a time storage() for complex calculation of document amounts
// 		
// 		* CommissionAgentSAgreement - String - The path to the Attribute of the object containing the Contract with the commission agent for determining the Attributes of the HFC, the procedure for settlements, foreign exchange settlements, and payments in the currency when accounting for sales.
// 		* ConductARAPAccountingThroughEndCustomers - Boolean - A sign that the commission sales are being made through the end customer AR/AP accounting.
// 		* DocumentBasis - String - the path to the bottom of the document.
// 		* PaymentPurposes - String - the path to the purpose of payment in the object.
// 		* TSP - String - the path to the warehouse in the object, used to get the settings for connecting to the SBP.
// 		* AdditionalInformation - String - The path to the Attribute with additional information on the document is used on the online order page.
// 		* ThisIsTransferOfOwnership2_5 - Boolean - A sign of a sale with deferred ownership 2.5.
// 		* ARAPObjectInternal - Boolean - An indication that the AR/AP object is a service one and is not intended for interactive selection.
//
Function MechanismParameters() Export
	
	ParametersStructure = New Structure;
	
	//Names of form elements for the current set of parameters
	FormItems = New Structure();
	
	#Region RequiredParameters2
	
	//If all options are false, then this is a payment or a service document.
	ParametersStructure.Insert("ThisIsOrder",                         False);
	ParametersStructure.Insert("IsCatalog",                    False);
	ParametersStructure.Insert("ThisIsSalePurchase",                False);
	
	//Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.Insert("PaymentType_",                      Enums.PartnersARAPAccountingTypes.EmptyRef());
	ParametersStructure.Insert("Organization",                      "Object.Organization");
	
	// With certain values of the document details, he may not change the mutual settlements in terms of payments or shipments.
	// An example is the transfer of goods to the commission.
	//
	// If both flags are negative, then the hyperlink "Calculations" is hidden, the amounts of mutual settlements and tabular parts of the mechanism are cleared.
	// If the value is negative, the Offset and Payment stages buttons will be hidden, but it will be possible to change currencies and the exchange rate.
	ParametersStructure.Insert("ChangesPaymentPlan",               True);
	ParametersStructure.Insert("ModifiesDeliveryShipmentPlan",     True);
	
	//Responsible for creating an AR/AP object. By default, all objects can be an AR/AP object.
	ParametersStructure.Insert("ItCanBeARAPObject",    True);
	
	// The date the document was reflected in the system.
	// It is used to get overdue balances for the debt limitation function.
	// Used to get the document's currency rates. 
	// Used to fill in the payment stages and decrypt the default payment.
	ParametersStructure.Insert("Date",                             "Object.Date");
	// The system number of the object
	ParametersStructure.Insert("Number",                            "Object.Number");
	
	// Currency and amount of the transaction. The path to the object's details is required.
	ParametersStructure.Insert("DocumentCurrency",                  "Object.Currency");
	ParametersStructure.Insert("DocumentAmount",                   "Object.DocumentAmount");
	
	// They are used to generate calculation and analytics objects.
	ParametersStructure.Insert("Partner",                          "Object.Partner");
	ParametersStructure.Insert("Counterparty",                       "Object.Counterparty");
	
	//When these Attributes Of the object are changed, the parameters Of the mechanism will be recached.
	ParametersStructure.Insert("InfluencingAttributes",                "");
	
	#EndRegion
	
	#Region OptionalParameters
	
	// Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.Insert("ARAPCurrency",             "");
	ParametersStructure.Insert("AmountARAP",              "");
	ParametersStructure.Insert("AmountVATARAP",              "");
	ParametersStructure.Insert("AmountARAPByPackage",        "");
	
	// It is used to generate analytics for the conduct and object of calculations, to determine the schedule for the execution of the contract.
	ParametersStructure.Insert("Contract",                          "Object.Contract");
	// It is used to obtain the details of the HFC, the order of settlements, currency settlements, payments in the currency when accounting for sales to end customers.
	ParametersStructure.Insert("CommissionAgentSAgreement",              "");
	ParametersStructure.Insert("ConductARAPAccountingThroughEndCustomers", False);
	
	// Used for the calculation object.
	ParametersStructure.Insert("LineOfBusiness",          "Object.LineOfBusiness");
	
	// The procedure for calculating the document.
	ParametersStructure.Insert("ARAPObjectSettings",                  "Object.ARAPObjectSettings");
	ParametersStructure.Insert("ConditionalOrderOfCalculations",          "");
	
	// The total amount with the collateral container. The path to the final indicator of the form (props).
	// It is used to display hyperlinks, edit and fill in the schedule of scheduled payments
	// , edit the payment transcript, etc.
	ParametersStructure.Insert("DocumentAmountForm",              ""); 
	
	// The details of the final indicators form containing the amount of the deposit for the container in the currency of the document.
	// It is used in filling out the stages of the payment schedule.
	ParametersStructure.Insert("AmountOfDepositForContainerForm",               "");
	
	// The tabular part, according to which the amount of mutual settlements is distributed, the amount of the deposit for the container or the breakdown of the invoice by orders.
	// It is used to display hyperlinks, edit and fill in the schedule of scheduled payments
	// , edit the payment transcript if the Summadocumentform parameter is not filled in.
	// In PM, the objects of calculations for orders are filled in.
	ParametersStructure.Insert("PathToTSData",                    "");
	// The name of the details of the amount with VAT of the tabular part.
	ParametersStructure.Insert("PropsNameTSAmountWithVAT",          "AmountIncludingVAT");
	// The name of the pm item containing the order.
	ParametersStructure.Insert("PropsNameTSOrder",              "");
	
	// The path to the tabular part of the payment decryption.
	// It is used in the function of offsetting payments, distribution of mutual settlements, distribution of payments.
	ParametersStructure.Insert("PathToTSDataPaymentDecryption",  "");
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Insert("Terms",                       "Object.Terms");
	
	// They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.Insert("CompanyBankAccount",        "Object.CompanyBankAccount");
	ParametersStructure.Insert("CounterpartyBankAccount",        "Object.CounterpartyBankAccount");
	ParametersStructure.Insert("CashAccount",                            "Object.CashAccount");
	ParametersStructure.Insert("PaymentMethod",                      "Object.PaymentMethod");
	ParametersStructure.Insert("ForeignCurrencyTransaction",                    "Object.ForeignCurrencyTransaction");
	// It is used in the form of payment rules and for the selection of settlement objects in the decryption of the payment.
	ParametersStructure.Insert("PaymentID",             "Object.PaymentID");
	ParametersStructure.Insert("VATTaxation",               "Object.VATTaxation");
	
	// The details for the object of calculations are used in conducting.
	ParametersStructure.Insert("FinancialAccountingGroup",           "Object.FinancialAccountingGroup");
	ParametersStructure.Insert("Department",                    "Object.Department");
	ParametersStructure.Insert("Manager",                         "");
	ParametersStructure.Insert("IncomingDocumentNumber",          "");
	ParametersStructure.Insert("IncomingDocumentDate",           "");
	ParametersStructure.Insert("SourceDocumentName",  "");
		
	// Used to determine the object of calculations.
	ParametersStructure.Insert("InvoiceForOrders",               "");
	
	// Order the base from the header.
	// It is used when determining the default calculation order and the list of available orders to choose from.
	// Used to determine the object of calculations.
	ParametersStructure.Insert("OrderBase",                   ""); 
	
	// The name of the button that opens the Payment offset assistant for the current set of parameters.
	FormItems.Insert("PaymentSettlement",                      "");
	// The name of the table element of the form that displays the amount of settlements.
	// Used to set the conditional design.
	// It should be filled in if the document supports line-by-line manual editing of settlement amounts.
	FormItems.Insert("AmountOfTSSettlements",            "");
	
	// The name of the form element containing the financial accounting group to reflect the current set of parameters for the BU.
	FormItems.Insert("FinancialAccountingGroup",           "");
	FormItems.Insert("LineOfBusiness",          "");
	
	// The storage location of the reference/references to the Calculation Objects directory. It can be in the header or in the tabular part.
	ParametersStructure.Insert("ARAPObject",             "");
	
	ParametersStructure.Insert("Ref",                     "Object.Ref");
	
	// Calculation of document amounts via the document object module algorithm
	ParametersStructure.Insert("SourceOfAmountsTabularPart", False);
	
	#EndRegion
	
	#Region EditingPaymentDecryption
	
	// If the transcript is edited in a general form, it is used in the Offset of returns of goods.
	FormItems.Insert("HyperlinkPaymentDecryption",    "");
	
	// If the transcript is being edited in the document.
	// Used in payment distribution.
	ParametersStructure.Insert("PaymentsAsPer275FZ",             "");
	FormItems.Insert("ARAPDetails",               "");
	FormItems.Insert("AddToPaymentDecryption",        "");
	
	// Selection and selection settings in PM Payment decryption
	
	// To select the balances of settlements by partners with the type of settlements Other relations, without selection by partner.
	ParametersStructure.Insert("PartnerOtherRelations",               False); 
	ParametersStructure.Insert("SelectAccountsReceivable",       False);
	ParametersStructure.Insert("SelectOnlyUnconditionalDebt", False);
	ParametersStructure.Insert("PaymentByRequests",                      False);
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	// The course of the document is one pair for the document.
	// They are used to calculate the amount of mutual settlements and in the form of editing the currencies and exchange rates of the document.
	ParametersStructure.Insert("CourseNumerator",                           "");
	ParametersStructure.Insert("CourseDenominator",                         "");
	
	// The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	FormItems.Insert("LabelCurrencies",                    "");
	
	// It is used when the calling form does not have the Only Review flag, but it is necessary to restrict currency editing.
	ParametersStructure.Insert("CurrencyAndExchangeRateDocumentViewOnly", False);
	
	// Are used in the condition through OR with the right to deviate from the terms of sale/purchases.
	ParametersStructure.Insert("DocumentCurrencyViewOnly",      False);
	ParametersStructure.Insert("MutualSettlementsCurrencyViewOnly", False);
	// Used to restrict editing the amount in the document currency on the currency and exchange rate form
	ParametersStructure.Insert("DocumentAmountViewOnly",       False);
	
	// If it is not necessary to show the amount and currency of mutual settlements based on the data of the document.
	ParametersStructure.Insert("DonTShowCalculations",                False);
	// If it is not required to offer recalculation of the amount of the document.
	ParametersStructure.Insert("DoNotRecalculateTheAmountOfTheDocument",      False);
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	
	// Function Payment stages and payment date
	ParametersStructure.Insert("PathToTSDataPaymentSteps",           "");
	ParametersStructure.Insert("PaymentDate",                        "");
	ParametersStructure.Insert("PaymentSchedule",                       "");
	ParametersStructure.Insert("ApprovalDate",                   "");
	ParametersStructure.Insert("DateOfShipment",                       "Object.Date");
	ParametersStructure.Insert("DateOfReceipt",                    "");
	ParametersStructure.Insert("DateOfTransferOfTitleToGoods",     "");
	ParametersStructure.Insert("NoPrepaymentControl",              False);
	ParametersStructure.Insert("ThereIsDateOfTransferOfOwnership", False);
	ParametersStructure.Insert("ShipInOneDay",                "");
	
	// The name of the hyperlink that displays the current payment rules of the document and opens the Payment Rules form.
	FormItems.Insert("InscriptionStages",                     "");
	// The path to the form details displayed in the hyperlink label field
	ParametersStructure.Insert("PaymentStepsText",                  "");
	// Payment order input field
	FormItems.Insert("ARAPObjectSettings",                  "");
	
	// If you need to restrict the editing of payment melts.
	ParametersStructure.Insert("PaymentStagesViewOnly",            False);
	// If the order invoice is also true, the extended form of the payment schedule will be displayed, despite the functional option "Simplified form of payment".
	ParametersStructure.Insert("InvoiceForSeveralOrdersIsPossible", False);
	// Hides a bank account, cash register, payment in foreign currency and UIP in the form of payment melting, used in self-service.
	ParametersStructure.Insert("DoNotSpecifyPaymentSources", False);
	// Allows you to specify the payment schedule in the absence of movements according to the payment plan.
	ParametersStructure.Insert("OrderAsAProformaInvoice", False);
	ParametersStructure.Insert("ThisIsTransferOfOwnership2_5", False);
	
	#EndRegion
	
	#Region MutualSettlementsStatus
	
	FormItems.Insert("InscriptionCalculations",                   ""); // The name of the hyperlink that displays the status of calculations and opens the corresponding report,
	
	#EndRegion
	
	#Region LimitsOnDebtUnderAgreement
	
	FormItems.Insert("DebtLimitationText",    ""); // Hyperlink displaying the status of the debt limit
	FormItems.Insert("DebtLimitation", ""); // A picture showing the shipment ban
	
	#EndRegion
	
	ParametersStructure.Insert("ChangesCalculationsByString", "TRUE");
	ParametersStructure.Insert("OnlyBalance", False);
	ParametersStructure.Insert("FormItems", FormItems);
	ParametersStructure.Insert("OrganizationOfContract", Catalogs.Companies.EmptyRef());
	ParametersStructure.Insert("CounterpartyOfContract", Catalogs.Counterparties.EmptyRef());
	ParametersStructure.Insert("DocumentExchangeRateDate", "");
	ParametersStructure.Insert("KeepCommissionFee", False);
	ParametersStructure.Insert("ToReturnReusablePackage", False);
	ParametersStructure.Insert("PackageDepositIsRequired", False);
	ParametersStructure.Insert("OperationWithSelfEmployedPerson", False);
	ParametersStructure.Insert("RecordBranches", True);
	ParametersStructure.Insert("ARAPObjectInternal", False);
	
	ParametersStructure.Insert("DocumentBasis", "");
	ParametersStructure.Insert("PaymentPurposes", "");
	ParametersStructure.Insert("TSP", ""); // A sales and service enterprise to get the connection settings
	ParametersStructure.Insert("AdditionalInformation", "");
	
	Return ParametersStructure;
	
EndFunction

// Complements the structure / array of structures with data from the information security settings, sets the correspondence of form elements to indexes of elements in the parameter array.
// 
// Parameters:
// 	Object - DocumentObject, CatalogObject, ClientApplicationForm - Object to add parameters to
// 	MechanismParameters - See MechanismParameters
//
// Returns:
// 	Structure - LongDesc:
// * ParametersArray - Array of See MechanismParameters - Includes an array of parameter structures and General data.
//
Function AugmentedMechanismParameters(Object, MechanismParameters = Undefined) Export
	
	If TypeOf(Object) <> Type("ClientApplicationForm") And MechanismParameters = Undefined Then
		ObjectManager = Common.ObjectManagerByRef(Object.Ref);
		MechanismParameters = ObjectManager.SettlementParameters_(Object);
	EndIf;
	
	If TypeOf(MechanismParameters) = Type("Array") Then
		ParametersArray = MechanismParameters;
	Else
		ParametersArray = CommonClientServer.ValueInArray(MechanismParameters);
	EndIf;
	
	For Each ParametersStructure In ParametersArray Do
		
		ParametersStructure.Insert("ExecutionScheduleIsSpecified", False);
		ParametersStructure.Insert("ContractSchedule", Undefined);
		ParametersStructure.Insert("ContractRateOption", Enums.ContractRateOptions.Mutable);
		
		// Stores shipping dates before editing the tabular part of the order to determine changes
		ParametersStructure.Insert("ShippingDates", ARAPAccountingClientServer.ArrayOfShipmentDates(Object, ParametersStructure));
		// The Flag Is Raised for Orders with Multiple shipping Dates when the shipping dates change
		ParametersStructure.Insert("SeveralShippingDatesHaveChanged", False);
		//This Flag Indicates That The Payment Schedule is filled in by default and has not been changed
		ParametersStructure.Insert("ThereAreManualChangesToPaymentSchedule", False);
		
		// Parameters are used to calculate the planned payment schedule
		// Taken from the agreement or the value of the "payment schedule"
		ParametersStructure.Insert("Calendar", Catalogs.BusinessCalendars.EmptyRef());
		// Taken from the agreement
		ParametersStructure.Insert("DeadlineOfTransferOfTitleToGoods", 0);
		
		If ValueIsFilled(ParametersStructure.Contract) Then
			Contract = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
			If ValueIsFilled(Contract) Then
				SetPrivilegedMode(True);
				If TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts") Then
					ContractDetails_ = Common.ObjectAttributesValues(Contract, "ExecutionScheduleIsSpecified, ContractSchedule, Organization, ContractRateOption, Counterparty");
					ParametersStructure.ExecutionScheduleIsSpecified    = ContractDetails_.ExecutionScheduleIsSpecified;
					ParametersStructure.ContractSchedule = ContractDetails_.ContractSchedule;
					ParametersStructure.OrganizationOfContract      = ContractDetails_.Organization;
					ParametersStructure.CounterpartyOfContract       = ContractDetails_.Counterparty;
					ParametersStructure.ContractRateOption     = ContractDetails_.ContractRateOption;
				Else
					ParametersStructure.ContractRateOption     = Common.ObjectAttributeValue(Contract, "ContractRateOption");
				EndIf;
				SetPrivilegedMode(False);
			EndIf;
		EndIf;
		
		AgreementPaymentSchedule = Catalogs.PaymentSchedules.EmptyRef();
		PaymentSchedule = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PaymentSchedule); // CatalogRef.PaymentSchedules
		If ValueIsFilled(ParametersStructure.Terms) Then
			Terms = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Terms);
			If ValueIsFilled(Terms) Then
				DetailsOfAgreement = ARAPAccountingInternal.DetailsOfAgreement(Terms);
				
				ParametersStructure.Calendar                      = DetailsOfAgreement.Calendar;
				ParametersStructure.DeadlineOfTransferOfTitleToGoods = DetailsOfAgreement.DeadlineOfTransferOfTitleToGoods;
				If TypeOf(Terms) = Type("CatalogRef.TermsOfSale") And GetFunctionalOption("UsePaymentSchedules") Then
					AgreementPaymentSchedule                         = DetailsOfAgreement.PaymentSchedule;
				EndIf;
				
			EndIf;
		EndIf;
		
		// We take the calendar as a priority from the specified payment schedule, and not from the agreement schedule.
		If ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting
			And ValueIsFilled(PaymentSchedule) And GetFunctionalOption("UsePaymentSchedules")
			And (AgreementPaymentSchedule <> PaymentSchedule Or Not ValueIsFilled(ParametersStructure.Calendar)) Then
			SetPrivilegedMode(True);
			ParametersStructure.Calendar = Common.ObjectAttributeValue(PaymentSchedule, "Calendar");
			SetPrivilegedMode(False);
		EndIf;
		
		If TypeOf(Object) = Type("ClientApplicationForm") Then
		
			ArrayOfUsedFormElements = New Array;
			For Each Item In ParametersStructure.FormItems Do
				If ValueIsFilled(Item.Value) Then
					ArrayOfUsedFormElements.Add(Item.Value);
				EndIf;
			EndDo;
			ParametersStructure.Insert("UsedFormElements", ArrayOfUsedFormElements);
			
			If ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
				FormObject = Object.Object; //DocumentObject
				ObjectMetadata = FormObject.Ref.Metadata();
				ParametersStructure.Insert("AttributeSelectionParameters", PaymentStepsServer.ParametersForSelectingPaymentDetails(ObjectMetadata));
			EndIf;
			
			MatchingDetailsUsed = New Map;
			For Each Item In ParametersStructure Do
				If ValueIsFilled(Item.Value) Then
					If MatchingDetailsUsed.Get(Item.Value) = Undefined Then
						MatchingDetailsUsed.Insert(Item.Value, CommonClientServer.ValueInArray(Item.Key));
					Else
						MatchingDetailsUsed[Item.Value].Add(Item.Key);
					EndIf;
				EndIf;
			EndDo;
			ParametersStructure.Insert("DetailsUsed", MatchingDetailsUsed);
		
		EndIf;
		
		ParametersStructure.Insert("ChangesCalculations", ParametersStructure.ChangesPaymentPlan Or ParametersStructure.ModifiesDeliveryShipmentPlan);
		
		ParametersStructure.Insert("CustomerSettlementDocument", ParametersStructure.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
		ParametersStructure.Insert("DocumentOfSettlementsWithSuppliers", ParametersStructure.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"));
		
		ParametersStructure.Insert("IsItPaymentOrOtherDocument", Not ParametersStructure.ThisIsOrder And Not ParametersStructure.IsCatalog And Not ParametersStructure.ThisIsSalePurchase);
		
		ParametersStructure.Insert("AddressStagesOfPayment", "");
		ParametersStructure.Insert("AddressOfOrderAmounts", "");
		ParametersStructure.Insert("AddressPaymentDecryption", "");
		ParametersStructure.Insert("AmountOfPaymentDecryption", 0);
		
		If Not ParametersStructure.IsItPaymentOrOtherDocument Then
			MetadataObject = TMCommonUseClientServer.DataAlongWay(Object, "Object.Ref").Metadata();
			ParametersStructure.Insert("AttributeSelectionParameters", PaymentStepsServer.ParametersForSelectingPaymentDetails(MetadataObject))
		EndIf;
		
		ParametersStructure.Insert("OrganizationInRows", StrOccurrenceCount(ParametersStructure.Organization, ".") > 1
			And ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption)
			And StrSplit(ParametersStructure.Organization, ".")[1] = StrSplit(ParametersStructure.PathToTSDataPaymentDecryption, ".")[1]);
		ParametersStructure.Insert("CounterpartyInLines", StrOccurrenceCount(ParametersStructure.Counterparty, ".") > 1
			And ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption)
			And StrSplit(ParametersStructure.Counterparty, ".")[1] = StrSplit(ParametersStructure.PathToTSDataPaymentDecryption, ".")[1]);
		ParametersStructure.Insert("PartnerInRows", StrOccurrenceCount(ParametersStructure.Partner, ".") > 1
			And ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption)
			And StrSplit(ParametersStructure.Partner, ".")[1] = StrSplit(ParametersStructure.PathToTSDataPaymentDecryption, ".")[1]);
		ParametersStructure.Insert("CurrencyOfMutualSettlementsInLines", StrOccurrenceCount(ParametersStructure.ARAPCurrency, ".") > 1
			And ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption)
			And StrSplit(ParametersStructure.ARAPCurrency, ".")[1] = StrSplit(ParametersStructure.PathToTSDataPaymentDecryption, ".")[1]);
			
		If Not ValueIsFilled(ParametersStructure.ARAPCurrency) And ValueIsFilled(ParametersStructure.DocumentCurrency) Then
			ParametersStructure.ARAPCurrency = ParametersStructure.DocumentCurrency;
		EndIf;
			
	EndDo;
	
	SystemSettings_ = New Structure();
	SystemSettings_.Insert("UsePaymentSchedules",                                    GetFunctionalOption("UsePaymentSchedules"));
	SystemSettings_.Insert("ToUseTermsOfSales",                             GetFunctionalOption("ToUseTermsOfSales"));
	SystemSettings_.Insert("UseTermsOfPurchases",                          GetFunctionalOption("UseTermsOfPurchases"));
	SystemSettings_.Insert("UseCustomerContracts",                               GetFunctionalOption("UseCustomerContracts"));
	SystemSettings_.Insert("UseContractsWithVendors",                            GetFunctionalOption("UseContractsWithVendors"));
	SystemSettings_.Insert("UseIntercompanyContracts",                       GetFunctionalOption("UseIntercompanyContracts"));
	SystemSettings_.Insert("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving", GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving"));
	SystemSettings_.Insert("UseSimplifiedPaymentSchemeInPurchasing",                   GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing"));
	SystemSettings_.Insert("UseSimplifiedPaymentSchemeInSales",                   GetFunctionalOption("UseSimplifiedPaymentSchemeInSales"));
	SystemSettings_.Insert("UseSaleByMultipleOrders",                    GetFunctionalOption("UseSaleByMultipleOrders"));
	
	SystemSettings_.Insert("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	
	SystemSettings_.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	
	AugmentedMechanismParameters = New Structure();
	AugmentedMechanismParameters.Insert("ParametersArray", ParametersArray);
	AugmentedMechanismParameters.Insert("SystemSettings_", SystemSettings_);
	AugmentedMechanismParameters.Insert("NotifyAboutCompletionOfStages", False);
	AugmentedMechanismParameters.Insert("NotifyAboutChangesToPaymentObject", False);
	AugmentedMechanismParameters.Insert("ModifiedCalculationObject", Catalogs.ARAPObjects.EmptyRef());
	
	
	Return AugmentedMechanismParameters;
	
EndFunction

#Region ObjectModule

//Performs initial filling in of currencies, settlement order, payment in currency, payment schedule stages, exchange rate, and multiplicity
//with default values, if the values are not filled in yet.
//
// Parameters:
// 	Object - DocumentObject, CatalogObject - The object being processed.
// 	FillingData - Structure, DocumentObject - Data from the document completion processing.
// 
Procedure Filling(Object, FillingData) Export
	
	ObjectManager = Common.ObjectManagerByRef(Object.Ref);
	MechanismParameters = ObjectManager.SettlementParameters_(Object);
	
	AugmentedMechanismParameters = AugmentedMechanismParameters(Object, MechanismParameters);
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		Organization = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
		If ValueIsFilled(Organization) Then
			LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		ElsIf TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("Organization")
			And ValueIsFilled(FillingData.Organization)
			And TypeOf(FillingData.Organization) = Type("CatalogRef.Companies") Then
			LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
		Else
			LocalAccountingCurrency = Undefined;
		EndIf;
		
		ProcessFill_(Object, ParametersStructure, FillingData, "DocumentCurrency", LocalAccountingCurrency);
		ProcessFill_(Object, ParametersStructure, FillingData, "ARAPCurrency", LocalAccountingCurrency);
		ProcessFill_(Object, ParametersStructure, FillingData, "ARAPObjectSettings", ARAPAccountingInternal.CalculationProcedureForParameters(Object, ParametersStructure));
		// Payment in currency:
		PaymentInDefaultCurrency = ARAPAccountingInternal.PaymentInDefaultCurrency(Object, ParametersStructure);
		ForeignCurrencyTransaction = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.ForeignCurrencyTransaction);
		If ForeignCurrencyTransaction <> Undefined Then
			ForeignCurrencyTransaction.Data[ForeignCurrencyTransaction.Name] = PaymentInDefaultCurrency
		EndIf;
		
		If FillingData <> Undefined
			And CommonClientServer.HasAttributeOrObjectProperty(FillingData, "FinancialAccountingGroup")
			And Not ValueIsFilled(FillingData.FinancialAccountingGroup)
			And ValueIsFilled(ParametersStructure.FinancialAccountingGroup) Then
			
			DefaultHFCS = ARAPAccountingInternal.DefaultHFCS(Object, ParametersStructure, AugmentedMechanismParameters.SystemSettings_);
			HFCsForAssignment = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.FinancialAccountingGroup);
			
			If HFCsForAssignment <> Undefined Then
				HFCsForAssignment.Data[HFCsForAssignment.Name] = DefaultHFCS;
			EndIf;
		
		EndIf;
		
	EndDo;
	
	If AugmentedMechanismParameters.ParametersArray.Count() > 0
		And ValueIsFilled(AugmentedMechanismParameters.ParametersArray[0].CourseNumerator)
		And TMCommonUseClientServer.DataAlongWay(Object, AugmentedMechanismParameters.ParametersArray[0].CourseNumerator) = 0 Then
		ARAPAccountingInternal.FillCourseMultiplicityByDefault(Object, AugmentedMechanismParameters);
	EndIf;
	
EndProcedure

//Clears Bank details when copying documents.
//In sales and purchases, the payment transcript, payment schedule stages, and settlement amounts are cleared.
//
// Parameters:
// 	Object - DocumentObject, CatalogObject - The object being processed.
// 
Procedure OnCopy(Object) Export
	
	ObjectManager = Common.ObjectManagerByRef(Object.Ref);
	MechanismParameters = ObjectManager.SettlementParameters_(Object);
	
	AugmentedMechanismParameters = AugmentedMechanismParameters(Object, MechanismParameters);
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
			ARAPDetails = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption);
			If ParametersStructure.ThisIsSalePurchase Then
				ARAPDetails.Clear();
			Else
				ArrayOfCalculationObjects_ = ARAPDetails.UnloadColumn("ARAPObject");
				AttributesOfSettlementObjects = Common.ObjectsAttributeValue(ArrayOfCalculationObjects_,"Object");
				For Each Page1 In ARAPDetails Do
					If TypeOf(AttributesOfSettlementObjects[Page1.ARAPObject]) = TypeOf(Object.Ref) Then
						Page1.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		PaymentIdAttribute = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.PaymentID);
		If PaymentIdAttribute <> Undefined Then
			PaymentIdAttribute.Data[PaymentIdAttribute.Name] = "";
		EndIf;
		
		ARAPAccountingInternal.ClearPaymentScheduleStages(Object, ParametersStructure);
		ARAPAccountingInternal.ClearAmountsOfTSSettlements(Object, ParametersStructure);
		ARAPAccountingInternal.ClearCalculationObject(Object, ParametersStructure);
	EndDo;
	
EndProcedure

//Checks and fills in the necessary data of the mechanism and the document:
//	The amount of mutual settlements of the document;
//	The amount of settlements in the main tabular parts of the document;
//	Payment procedure;
//	Payment in foreign currency;
//	Decryption of the payment;
//	Stages of the payment schedule.
//
// Parameters:
// 	Object - DocumentObject, CatalogObject - The object being processed.
// 	Cancel - Boolean - Flag failure from the document handler before Writing.
// 	WriteMode - DocumentWriteMode - the recording mode of the document.
// 
Procedure BeforeWrite(Object, Cancel, Val WriteMode = Undefined) Export
	
	If CommonClientServer.HasAttributeOrObjectProperty(Object,"AdditionalProperties")
		And Object.AdditionalProperties.Property("UpdatedSettlementParameters") Then
		AugmentedMechanismParameters = Object.AdditionalProperties.UpdatedSettlementParameters;
	Else
		ObjectManager = Common.ObjectManagerByRef(Object.Ref);
		MechanismParameters = ObjectManager.SettlementParameters_(Object);
		AugmentedMechanismParameters = AugmentedMechanismParameters(Object, MechanismParameters);
	EndIf;
	
	SystemSettings_ = AugmentedMechanismParameters.SystemSettings_;
	
	Ref = TMCommonUseClientServer.DataAlongWay(Object, "Object.Ref");
	
	If Object.IsNew() Then
		RefToNew = Object.GetNewObjectRef();
		If Not ValueIsFilled(RefToNew) Then
			RefToNew = Common.ObjectManagerByRef(Ref).GetRef();
			Object.SetNewObjectRef(RefToNew);
		EndIf;
	ElsIf Metadata.EventSubscriptions.CheckDocumentNumberByDateAndCompany.Source.ContainsType(TypeOf(Object)) Then
		ObjectsPrefixesEvents.CheckDocumentNumberByDateAndCompany(Object, Cancel, WriteMode, Undefined);
		If Not ValueIsFilled(Object.Number) Then
			Object.SetNewNumber()
		EndIf;
		Object.AdditionalProperties.Insert("DocumentNumberCheckedByDateAndOrganization", True);
	EndIf;
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		If Object.IsNew() Then
			ParametersStructure.Insert("RefToNew", RefToNew);
		EndIf;
		
		CheckFillInBankingDetails(Object, ParametersStructure, "ARAPObjectSettings", ARAPAccountingInternal.CalculationProcedureForParameters(Object, ParametersStructure));
		CheckFillInBankingDetails(Object, ParametersStructure, "ForeignCurrencyTransaction", ARAPAccountingInternal.PaymentInDefaultCurrency(Object, ParametersStructure));
		
		CheckAndFillInAmountOfSettlements(Object, ParametersStructure, SystemSettings_);
		CheckAndFillInAmountsOfSettlementsInTablePart(Object, ParametersStructure);
		
		If ParametersStructure.IsCatalog And ParametersStructure.Ref = ParametersStructure.Contract Then
			If Not ValueIsFilled(Object.ContractRateOption) Then
				Object.ContractRateOption = Enums.ContractRateOptions.Mutable;
			EndIf;
		EndIf;
		
		If Not ParametersStructure.Property("DocumentAmounts") And WriteMode <> DocumentWriteMode.UndoPosting Then
			If ParametersStructure.Property("SourceOfAmountsTabularPart") And ParametersStructure.SourceOfAmountsTabularPart Then
				ParametersStructure.Insert("DocumentAmounts", ARAPAccountingInternal.DocumentAmounts(Object,ParametersStructure));
			EndIf;
		EndIf;
		
	EndDo;
	
	If WriteMode = DocumentWriteMode.Posting Then
		PaymentStepsServer.CheckAndFillInPaymentScheduleStages(Object, AugmentedMechanismParameters);
		PaymentStepsServer.CheckCompletionOfPaymentScheduleStages(Object, Cancel, AugmentedMechanismParameters);
	EndIf;
	
	ARAPObjectsServer.CheckCalculationObjectsBeforeRecording(Object, AugmentedMechanismParameters.ParametersArray, WriteMode, Cancel);
	RecordExchangeRatesAndCurrenciesOfDocument(Object, AugmentedMechanismParameters.ParametersArray, Cancel);
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		If WriteMode = DocumentWriteMode.Posting And Not Object.Posted Then
			FillInPossibleAdvancesInInvoice(Object, ParametersStructure);
		EndIf;
		
		//Clearing the amount cache
		If ParametersStructure.Property("DocumentAmounts") Then
			ParametersStructure.Delete("DocumentAmounts");
		EndIf;
		
	EndDo
	
EndProcedure

// Before recording on the server.
// 
// Parameters:
//  Form Form
//  CurrentObject Current object
Procedure BeforeWriteAtServer(Form, CurrentObject) Export
	CurrentObject.AdditionalProperties.Insert("UpdatedSettlementParameters", TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting"));
EndProcedure

// When the approval date changes, clears the stages of the payment schedule.
// 
// Parameters:
//  Object - DocumentObject, CatalogObject - The object being processed.
Procedure WhenChangingApprovalDate(Object) Export
	
	ObjectManager = Common.ObjectManagerByRef(Object.Ref);
	MechanismParameters = ObjectManager.SettlementParameters_(Object);
	AugmentedMechanismParameters = AugmentedMechanismParameters(Object, MechanismParameters);
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		ScheduleStages = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentSteps);
		
		ApprovalDate = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ApprovalDate);
		OrderDate = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
		
		For Each StageString_ In ScheduleStages Do
			If StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.FromApprovalDate Then
				ParametersStructure = PaymentStepsClientServer.PaymentDateCalculationParameters();
				ParametersStructure.CalculateFrom                 = StageString_.CalculateFrom;
				ParametersStructure.Formula                        = StageString_.Formula;
				ParametersStructure.Move                          = StageString_.Move;
				ParametersStructure.OrderDate                     = OrderDate;
				ParametersStructure.ApprovalDate               = ApprovalDate;
				ParametersStructure.DateOfShipment                   = Date(1,1,1);
				ParametersStructure.DateOfReceipt                = Date(1,1,1);
				ParametersStructure.DateOfTransferOfTitleToGoods = Date(1,1,1);
				ParametersStructure.DeadlineOfTransferOfTitleToGoods = 0;
				
				If ValueIsFilled(ParametersStructure.Calendar)  Then
					StageString_.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(ParametersStructure);
				Else
					StageString_.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(ParametersStructure);
				EndIf;
			EndIf;
		EndDo;
		
		PaymentStepsClientServer.SortStageTable(ScheduleStages);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormModule

// Deprecated. Adds and caches the mechanism parameters to the form details, updates the hyperlink texts
//, and sets the visibility of the "payment Offset" command for new documents.
//
// Parameters:
// 	Form - ClientApplicationForm, ManagedFormExtensionForDocuments, CatalogItemFormExtension - The form of the document/directory.
// 
Procedure FormWhenCreatedOnServer(Form) Export
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(Form);
	
EndProcedure

// Deprecated. Caches the mechanism parameters in the form details, updates the hyperlink texts
//, and sets the visibility of the "payment Offset" command for existing documents.
//
// Parameters:
// 	Form - ClientApplicationForm, ManagedFormExtensionForDocuments, CatalogItemFormExtension - The form of the document/directory.
// 
Procedure FormWhenReadingOnServer(Form) Export
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(Form);
	
EndProcedure

// Deprecated. Updates the hyperlink texts after recording and sets the values of the parameters of the mechanism of Mutual settlements on notification
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 	AdditionalProperties - Structure - Additional properties of the recorded object
// 
Procedure FormAfterRecordingOnServer(Form, AdditionalProperties = Undefined) Export
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(Form, AdditionalProperties);
	
EndProcedure

// Deprecated. Performs the necessary actions when changing the key details of the document / directory.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
//	ChangedBankingDetails - Array of String - The list of names of the changed details in terms of the document.
//						- Structure - The list of names of the changed details in terms of the document, only the keys (names of the details) of the structure are analyzed.
//						- String - The name of the changed props.
// 	TheseAreMechanismChanges - Boolean - Flag that the call is made by the mechanism itself.
// 
// Returns:
// 	Structure - The structure of the changed document details after processing, where the Key is the Name of the detail, the value is the value of the detail before the change.
//
Function FormWhenChangingBankingDetails(Form, ChangedBankingDetails, TheseAreMechanismChanges = False) Export
	
	Return ARAPAccountingFormWork.FormWhenChangingBankingDetails(Form, ChangedBankingDetails, TheseAreMechanismChanges);
	
EndFunction

// Deprecated. Updates hyperlink texts and visibility of the "payment Offset" command.
//Cleans all the details of settlement, if the document does not change the mutual.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 
Procedure WhenChangingParametersOfMechanism(Form) Export
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(Form);
	
EndProcedure

// Deprecated. Used for the processing of alerts related to the mechanism of mutual settlements.
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	 * Data Object Forms
// 	  ** Link - Document link, Reference link
// 	EventName - String - event name.
// 	Parameter - Arbitrary - event parameter.
Procedure NotificationProcessing(Form, EventName, Parameter) Export
	
	ARAPAccountingFormWork.NotificationProcessing(Form, EventName, Parameter);
	
EndProcedure

// Function - Currency rates for conversion
//
// Parameters:
//  Form			 - ClientApplicationForm	 - The form of the document/directory.
//  OldCurrency	 - CatalogRef.Currencies	 - the currency to be converted from
//  NewCurrency		 - CatalogRef.Currencies	 - the currency to convert to
//  BaseCurrency	 - CatalogRef.Currencies	 - base currency of exchange rates
//  DocumentDate	 - Date	 - date of receipt of courses
// 
// Returns:
//  Structure:
//   *StructureOfOldCurrencyRates - See ProcessingOfExchangeRatesTM.GetCurrencyRate
//   *StructureOfNewCurrencyRates - See ProcessingOfExchangeRatesTM.GetCurrencyRate
//
Function ExchangeRatesForTranslation(Form, OldCurrency, NewCurrency, BaseCurrency, DocumentDate) Export
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	If MechanismParameters <> Undefined Then
		ParametersStructure = MechanismParameters.ParametersArray[0];
		If ValueIsFilled(ParametersStructure.ContractRateOption) 
			And ParametersStructure.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract 
			And OldCurrency = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPCurrency) Then
			StructureOfOldCurrencyRates = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(
				TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract),
				DocumentDate);
			StructureOfOldCurrencyRates.Insert("Currency", OldCurrency);
			StructureOfOldCurrencyRates.Insert("BaseCurrency", BaseCurrency);
		Else
			StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, BaseCurrency);
		EndIf;
		If ValueIsFilled(ParametersStructure.ContractRateOption) 
			And ParametersStructure.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract 
			And NewCurrency = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPCurrency) Then
			StructureOfNewCurrencyRates = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(
				TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract),
				DocumentDate);
			StructureOfNewCurrencyRates.Insert("Currency", NewCurrency);
			StructureOfNewCurrencyRates.Insert("BaseCurrency", BaseCurrency);
		Else
			StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency, DocumentDate, BaseCurrency);
		EndIf;
	Else
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, BaseCurrency);
		StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency, DocumentDate, BaseCurrency);
	EndIf;
	
	Result = New Structure;
	Result.Insert("StructureOfOldCurrencyRates", StructureOfOldCurrencyRates);
	Result.Insert("StructureOfNewCurrencyRates", StructureOfNewCurrencyRates);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region PaymentSteps

// Deprecated. Performs filling/cleaning/redistribution of the phases of the schedule of payments
//
// Parameters:
// 	Object - DocumentObject, CatalogObject, ClientApplicationForm - The object being processed.
// 	AugmentedMechanismParameters - See ARAPAccountingServer.AugmentedMechanismParameters
// 	TableOfStagesOfPaymentSchedule - ValueTable - Unloading the tabular part of the payment stagesgraphicoply
// 
Procedure CheckAndFillInPaymentScheduleStages(Object, Val AugmentedMechanismParameters = Undefined, TableOfStagesOfPaymentSchedule = Undefined) Export
	
	PaymentStepsServer.CheckAndFillInPaymentScheduleStages(Object, AugmentedMechanismParameters, TableOfStagesOfPaymentSchedule);
	
EndProcedure

// Deprecated. Should be used See PaymentStepsServer.PlacePaymentStepsInTemporaryStorage
Procedure PlacePaymentStepsInTemporaryStorage(Form, TagName) Export
	
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(Form, TagName);
	
EndProcedure

// Deprecated. Should be used See PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage
Procedure LoadPaymentStagesFromTemporaryStorage(Form) Export
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(Form);
	
EndProcedure

// Deprecated. Service procedure that fills in the hyperlink text of the payment rules 
// 
// Parameters:
//	Form       - ClientApplicationForm - Agreement specified in the document:
//	 * Items - FormItems - elements of the calling form
//	ParametersStructure - See ARAPAccountingServer.MechanismParameters
//	SystemSettings_  - Structure - System settings from advanced settings, if already received.
//
Procedure UpdateHyperlinkTextPaymentSteps(Form, ParametersStructure = Undefined, SystemSettings_ = Undefined) Export
	
	ARAPAccountingFormWork.UpdateHyperlinkTextPaymentSteps(Form, ParametersStructure, SystemSettings_);
	
EndProcedure

#EndRegion

#Region Reports

// Deprecated. Adds the "customer account Statement" report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function StatementOfSettlementsWithCustomers_AddReportCommand(ReportsCommands) Export
	
	Return ARAPAccountingReports.StatementOfSettlementsWithCustomers_AddReportCommand(ReportsCommands);
	
EndFunction

// Deprecated. Adds the "Statement of payments between organizations" report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function StatementOfSettlementsBetweenOrganizations_AddReportCommand(ReportsCommands) Export
	
	Return ARAPAccountingReports.StatementOfSettlementsBetweenOrganizations_AddReportCommand(ReportsCommands);
	
EndFunction

// Deprecated. Adds the "statement of payments with partners" report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands) Export
	
	Return ARAPAccountingReports.StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands);
	
EndFunction

// Deprecated. Adds the vendor billing Statement report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function SupplierBillingStatement_AddReportCommand(ReportsCommands) Export
	
	Return ARAPAccountingReports.SupplierBillingStatement_AddReportCommand(ReportsCommands);
	
EndFunction

// Deprecated. Adds the "customer debt" report command in standard form to the list of commands.
// The report is grouped by partner.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function CustomerDebt_AddReportCommand(ReportsCommands) Export
	Return ARAPAccountingReports.CustomerDebt_AddReportCommand(ReportsCommands);
EndFunction

// Deprecated. Adds the "customer debt" report command to the list of commands. 
// The report is grouped by calculation object.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function CustomerDebt_AddDocumentReportCommand(ReportsCommands) Export
	Return ARAPAccountingReports.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
EndFunction

// Deprecated. Adds the "Customer Settlement Card" report command to the list of commands.
// Grouping by partner/counterparty.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function PaymentCardWithClient_AddReportCommand(ReportsCommands) Export
	Return ARAPAccountingReports.PaymentCardWithClient_AddReportCommand(ReportsCommands);
EndFunction

// Deprecated. Adds the "customer payment Card" report command to the list of commands.
// Grouping by calculation object.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands) Export
	Return ARAPAccountingReports.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
EndFunction

// Deprecated. Adds the vendor Debt report command in standard format to the list of commands.
// The report is grouped by partner.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function IndebtednessToSuppliers_AddReportCommand(ReportsCommands) Export
	Return ARAPAccountingReports.IndebtednessToSuppliers_AddReportCommand(ReportsCommands);
EndFunction

// Deprecated. Adds the supplier Debt report command to the list of commands. 
// The report is grouped by calculation object.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands) Export
	Return ARAPAccountingReports.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
EndFunction

// Deprecated. Adds the "Supplier Settlement Card" report command to the list of commands.
// Grouping by partner/counterparty.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function PaymentCardWithSupplier_AddReportCommand(ReportsCommands) Export
	Return ARAPAccountingReports.PaymentCardWithSupplier_AddReportCommand(ReportsCommands);
EndFunction

// Deprecated. Adds the "payment card with supplier" report command to the list of commands.
// Grouping by calculation object.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands) Export
	Return ARAPAccountingReports.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
EndFunction

#EndRegion

#Region OffsetOfPaymentDecryptionOfPayment

//Fills in the table parts "payment Decryption" with the remaining debt.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 	ARAPDetails - ValueTable - Table To Fill In
// 
Procedure FillInPaymentTranscriptWithBalances(Form, ARAPDetails) Export
	
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		Organization = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization);
		Counterparty = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Counterparty);
		Date = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date);
		Currency = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentCurrency);
		
		DebtType = ?(ParametersStructure.CustomerSettlementDocument, Enums.DebtTypes.AccountsReceivableType, Enums.DebtTypes.AccountsPayableType);
		
		FillInOutstandingBalances(
			Organization, 
			Counterparty,
			DebtType,
			Undefined, //PaymentType_
			Date,
			Currency,
			ARAPDetails);
		If ARAPDetails.Count() = 0 Then
			ARAPDetails.Add();
		EndIf;
	EndDo;
	
EndProcedure

// Deprecated. Places the table part of the payment Description in temporary storage and writes a link to it in the structure of settlement parameters.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 	TagName - String - Name of the element that can be used to determine which structure of settlement parameters the decryption is placed for.
//
Procedure PlacePaymentDecryptionInTemporaryStorage(Form, TagName = Undefined) Export
	
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(Form, TagName);
	
EndProcedure

// Deprecated. 
Procedure DownloadPaymentTranscriptFromTemporaryStorage(Form) Export
	
	ARAPAccountingFormWork.DownloadPaymentTranscriptFromTemporaryStorage(Form);
	
EndProcedure

// Deprecated. 
Procedure UpdateDistributedDecryptionAmount(Form) Export
	
	ARAPAccountingFormWork.UpdateDistributedDecryptionAmount(Form);
	
EndProcedure

// Deprecated. 
Procedure BlockSettlementObjects(Form) Export
	
	ARAPAccountingFormWork.BlockSettlementObjects(Form) ;
	
EndProcedure

#EndRegion

#Region HyperlinkCalculations

// Deprecated.
// 
// Parameters:
// 	Form - ClientApplicationForm - 
Procedure UpdateHyperlinkTextStateOfCalculations(Form) Export
	
	ARAPAccountingFormWork.UpdateHyperlinkTextStateOfCalculations(Form);
	
EndProcedure

#Region SettlementsAmounts

// The procedure checks and fills in the amounts of settlements in the tabular part of the object
// 
// Parameters:
//  Object - DocumentObject, CatalogObject, ClientApplicationForm - object being checked
//  ParametersStructure - See MechanismParameters
Procedure CheckAndFillInAmountsOfSettlementsInTablePart(Object, ParametersStructure) Export
	
	If Not ValueIsFilled(ParametersStructure.PathToTSData)
		Or Not ValueIsFilled(ParametersStructure.AmountARAP)
		Or TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.AmountARAP) = Undefined Then
		Return;
	EndIf;
	
	ARAPAccountingClientServer.CheckRequiredParameters(ParametersStructure,
		"PathToTSData, CourseNumerator, CourseDenominator, AmountARAP,
		| DocumentCurrency, ARAPCurrency, PropsNameTSAmountWithVAT, Organization");
	
	TSData             = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSData); // TabularSection
	CourseNumerator        = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CourseNumerator);
	CourseDenominator      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CourseDenominator);
	AmountARAP  = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.AmountARAP);
	DocumentCurrency      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentCurrency);
	ARAPCurrency = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPCurrency);
	Organization          = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
	NameSumWithVAT         = ParametersStructure.PropsNameTSAmountWithVAT;
	ToReturnReusablePackage = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ToReturnReusablePackage,,False);
	PackageDepositIsRequired      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PackageDepositIsRequired,,False);
	ThereIsNonTaxContainer = ToReturnReusablePackage And Not PackageDepositIsRequired;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	If TSData = Undefined Then 
		Return;
	EndIf;
	
	VT = TSData.Unload();
	ThereIsSumOfMutualSettlements = VT.Columns.Find("AmountARAP") <> Undefined;
	
	If Not ThereIsSumOfMutualSettlements Then
		Return;
	EndIf;
	
	ThereIsVATAmountOfMutualSettlements = VT.Columns.Find("AmountVATARAP") <> Undefined;
	
	//If there is a non-tax container in the document, then we do not distribute the amount of mutual settlements to the lines with the container.
	ArrayOfItemsToSkip = New Array;
	If ThereIsNonTaxContainer Then
		ProductsArray = VT.UnloadColumn("Products");
		ProductsArray = CommonClientServer.CollapseArray(ProductsArray);
		AttributesArray = Common.ObjectsAttributeValue(ProductsArray,"ItemsType");
		For Each Products In ProductsArray Do
			If AttributesArray[Products] = Enums.ItemsTypes.ReusablePackage Then
				ArrayOfItemsToSkip.Add(Products);
			EndIf;
		EndDo;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("AmountARAP", 0);
	
	AmountOfMutualSettlementsTSPlus  = 0;
	SumOfSettlementsTSMinus = 0;
	AmountPlus                  = 0;
	AmountMinus                 = 0;
	
	For Each Page1 In TSData Do
		If ThereIsNonTaxContainer And ArrayOfItemsToSkip.Find(Page1.Products) <> Undefined Then
			Continue;
		EndIf;
		If Page1[NameSumWithVAT] > 0 Then
			AmountPlus = AmountPlus + Page1[NameSumWithVAT];
			If ValueIsFilled(Page1.AmountARAP) Then
				AmountOfMutualSettlementsTSPlus = AmountOfMutualSettlementsTSPlus + Page1.AmountARAP;
			EndIf;
		Else
			AmountMinus = AmountMinus + Page1[NameSumWithVAT];
			If ValueIsFilled(Page1.AmountARAP) Then
				SumOfSettlementsTSMinus = SumOfSettlementsTSMinus + Page1.AmountARAP;
			EndIf;
		EndIf;
	EndDo;
	
	AmountOfMutualSettlementsForTS = TSData.Total("AmountARAP");
	
	If TSData.FindRows(TheStructureOfTheSearch).Count() = 0
		And AmountARAP = AmountOfMutualSettlementsForTS 
		And (Not ThereIsVATAmountOfMutualSettlements Or TSData.FindRows(New Structure("AmountVATARAP",0)).Count() = 0) Then
		Return;
	ElsIf AmountPlus = 0 
			And AmountMinus = 0 Then
		ARAPAccountingInternal.ClearAmountsOfTSSettlements(Object, ParametersStructure);
		Return;
	EndIf;
	
	If DocumentCurrency = ARAPCurrency Then
		
		For IndexOf = 0 To TSData.Count()-1 Do
			If ThereIsNonTaxContainer And ArrayOfItemsToSkip.Find(TSData[IndexOf].Products) <> Undefined Then
				Continue;
			EndIf;
			If Not ValueIsFilled(TSData[IndexOf].AmountARAP)
			 Or TSData[IndexOf].AmountARAP <> TSData[IndexOf][NameSumWithVAT] Then
				TSData[IndexOf].AmountARAP = TSData[IndexOf][NameSumWithVAT];
				If ThereIsVATAmountOfMutualSettlements Then
					TSData[IndexOf].AmountVATARAP = TSData[IndexOf].VATAmount;
				EndIf;
			EndIf;
		EndDo;
		
	Else
		
		ConversionFactor_ = ConversionRateAtExchangeRate(LocalAccountingCurrency,
																		DocumentCurrency,
																		ARAPCurrency,
																		CourseNumerator,
																		CourseDenominator); 
		
		// The amount that should be distributed over the tabular part
		// 		will be obtained from the difference between the total amount of settlements
		// 		and the total for the filled values of the column "Sum of settlements".
		If AmountMinus = 0 Then
			AmountOfSettlementsForDistributionPlus = AmountARAP;
			AmountOfSettlementsForDistributionMinus = 0;
		Else
			AmountOfSettlementsForDistributionPlus = Round(AmountPlus*ConversionFactor_, 2) - AmountOfMutualSettlementsTSPlus;
			AmountOfSettlementsForDistributionMinus = Round(AmountMinus*ConversionFactor_, 2) - SumOfSettlementsTSMinus;
		EndIf;
		
		//We distribute the positive deviation.
		ArrayOfAmounts = New Array;
		For IndexOf = 0 To TSData.Count()-1 Do
			If ThereIsNonTaxContainer And ArrayOfItemsToSkip.Find(TSData[IndexOf].Products) <> Undefined Then
				Continue;
			EndIf;
			If TSData[IndexOf][NameSumWithVAT] > 0 Then
				If Not ValueIsFilled(TSData[IndexOf].AmountARAP) Then
					ArrayOfAmounts.Add(Round(TSData[IndexOf][NameSumWithVAT] * ConversionFactor_, 2));
				Else
					AmountOfSettlementsForDistributionPlus = AmountOfSettlementsForDistributionPlus - TSData[IndexOf].AmountARAP;
				EndIf;
			EndIf;
		EndDo;
		
		ArrayOfAmounts = CommonClientServer.DistributeAmountInProportionToCoefficients(AmountOfSettlementsForDistributionPlus, ArrayOfAmounts);
		
		IndexOfSumArray = 0;
		If ArrayOfAmounts <> Undefined Then
			For IndexOf=0 To TSData.Count()-1 Do
				If ThereIsNonTaxContainer And ArrayOfItemsToSkip.Find(TSData[IndexOf].Products) <> Undefined Then
					Continue;
				EndIf;
				If Not ValueIsFilled(TSData[IndexOf].AmountARAP) And TSData[IndexOf][NameSumWithVAT] > 0 Then
					TSData[IndexOf].AmountARAP = ArrayOfAmounts[IndexOfSumArray];
					IndexOfSumArray = IndexOfSumArray + 1;
				EndIf;
			EndDo;
		EndIf;
		
		//We distribute the negative deviation.
		ArrayOfAmounts = New Array;
		For IndexOf = 0 To TSData.Count()-1 Do
			If ThereIsNonTaxContainer And ArrayOfItemsToSkip.Find(TSData[IndexOf].Products) <> Undefined Then
				Continue;
			EndIf;
			If TSData[IndexOf][NameSumWithVAT] < 0 Then
				If Not ValueIsFilled(TSData[IndexOf].AmountARAP) Then
					ArrayOfAmounts.Add(Round(TSData[IndexOf][NameSumWithVAT] * ConversionFactor_, 2));
				Else
					AmountOfSettlementsForDistributionMinus = AmountOfSettlementsForDistributionMinus - TSData[IndexOf].AmountARAP;
				EndIf;
			EndIf;
		EndDo;
		
		ArrayOfAmounts = CommonClientServer.DistributeAmountInProportionToCoefficients(AmountOfSettlementsForDistributionMinus, ArrayOfAmounts);
		
		IndexOfSumArray = 0;
		If ArrayOfAmounts <> Undefined Then
			For IndexOf=0 To TSData.Count()-1 Do
				If ThereIsNonTaxContainer And ArrayOfItemsToSkip.Find(TSData[IndexOf].Products) <> Undefined Then
					Continue;
				EndIf;
				If Not ValueIsFilled(TSData[IndexOf].AmountARAP) And TSData[IndexOf][NameSumWithVAT] < 0 Then
					TSData[IndexOf].AmountARAP = ArrayOfAmounts[IndexOfSumArray];
					IndexOfSumArray = IndexOfSumArray + 1;
				EndIf;
			EndDo;
		EndIf;
		
		If ThereIsVATAmountOfMutualSettlements Then
			For IndexOf=0 To TSData.Count()-1 Do
				If ThereIsNonTaxContainer And ArrayOfItemsToSkip.Find(TSData[IndexOf].Products) <> Undefined Then
					Continue;
				EndIf;
				TSData[IndexOf].AmountVATARAP = PriceManagementSystemClientServer.CalculateVATAmount(TSData[IndexOf].AmountARAP, TSData[IndexOf].VATRate);
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Posting

#Region CustomersARAPAccounting

// Deprecated. Supplements the texts of the document execution request with the texts of the contract execution schedule with the client in the accounts With clients register.
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
	
	ARAPAccountingPostingCustomers.CarryingOutScheduleOfExecutionOfContractWithClient(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans) 
	
EndProcedure

// Deprecated. Supplements the texts of the document request with the texts of the client's order execution in the accounts With clients register.
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
	
	ARAPAccountingPostingCustomers.ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);
	
EndProcedure

// Deprecated. Supplements the texts of the request for the document with the texts of the sale and transfer of settlements in the accounts With customers register.
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
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlan, TextTransferOfAdvancePayment, TextProducts_1, TextPayment);
	
EndProcedure

// Deprecated. Supplements the texts of the document request with the texts of payment from the client in the accounts With clients register.
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
	
	ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment, TypeOfOperationForSorting);
	
EndProcedure

// Deprecated. Complements the text of the requested document with text running the application for a refund of the DS client on a case-accounts receivable.
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
	
	ARAPAccountingPostingCustomers.ConductingRequestForRefundToClient(Query, QueryTexts, Registers, TextSettlements);
	
EndProcedure

// Deprecated. Supplements the texts of the document request with the texts of the payment refund to the client in the accounts With clients register.
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
// 	TextIsPaidFor - String - The text of the request for return data to be reduced to "Paid".
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
Procedure MakingRefundToClient(Query, QueryTexts, Registers, TextOfReport = "", TextTransferOfCalculations = "", TextIsPaidFor = "") Export
	
	ARAPAccountingPostingCustomers.MakingRefundToClient(Query, QueryTexts, Registers, TextOfReport, TextTransferOfCalculations, TextIsPaidFor);
	
EndProcedure

// Deprecated. Supplements the texts of the request for the document with the texts of the return of goods(valuables) from the client in the accounts With clients register.
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
	
	ARAPAccountingPostingCustomers.CarryingOutReturnOfGoodsFromCustomer(Query, QueryTexts, Registers, TextReturn, TextTransferOfCalculations);
	
EndProcedure

// Deprecated. supplements the texts of the request for the document with the texts of the client's order according to the register of scheduled customer payments.
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
	
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans)
	
EndProcedure

// Deprecated. supplements the texts of the request for the document with the texts of the client's order according to the register of scheduled customer payments.
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
	
	ARAPAccountingPostingCustomers.ConductingSettlementsWithCustomersShippingPlan(Query, QueryTexts, Registers, TextShipmentPlans, ThisIsScheduleOfContract);
	
EndProcedure

#EndRegion

#Region OffsetOfCounterDebt

// Deprecated. Supplements the texts of the request for the document with the texts of the payment from the client according to the register of Settlements with customers
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.OffsettingOfCounterDebt(Query, QueryTexts, Registers, TextOfClientSObligation, TextOfObligationToSupplier);
	
EndProcedure

#EndRegion

#Region VendorsARAPAccounting

// Deprecated. Supplements the texts of the document execution request with the texts of the contract execution schedule
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutScheduleOfExecutionOfContractWithSupplier(Query, QueryTexts, Registers, TextPaymentPlans, TextDeliveryPlans);
	
EndProcedure

// Deprecated. Supplements the texts of the request for the document with the texts of the order to the supplier in the Accounts with suppliers register.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ExecutionOfOrderToSupplier(Query, QueryTexts, Registers, TextPaymentPlans, TextDeliveryPlans)
	
EndProcedure

// Deprecated. Supplements the texts of the document request with the texts of payment to the supplier in the Payments with suppliers register.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment, TypeOfOperationForSorting)
	
EndProcedure

// Deprecated. Supplements the texts of the request for the document with the texts of the purchase in the register of Payments with suppliers.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan, TextTransferOfAdvancePayment, TextProducts_1, TypeOfOperationForSorting)
	
EndProcedure

// Deprecated. Supplements the texts of the request for the document with the texts of the request for payment to the supplier in the Payments with suppliers register.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ExecutionOfRequestForPaymentToSupplier(Query, QueryTexts, Registers, TextSettlements);
	
EndProcedure

// Deprecated. Supplements the text of the document request with the text of the payment refund from the supplier in the Payments with suppliers register.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingRefundFromSupplier(Query, QueryTexts, Registers, TextOfReport, TextTransferOfCalculations);
	
EndProcedure

// Deprecated. Supplements the texts of the request for the document with the texts of the return of goods to the supplier in the register of Payments with suppliers.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextReturn, TextTransferOfCalculations);
	
EndProcedure

// Deprecated. Supplements the texts of the document request with the texts of the client's order execution in the accounts With clients register.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingSettlementsWithSuppliersPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	
EndProcedure

// Deprecated. Supplements the texts of the document request with the texts of the client's order execution in the accounts With clients register.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingSettlementsWithSuppliersDeliveryPlan(Query, QueryTexts, Registers, TextDeliveryPlans, ThisIsScheduleOfContract)
	
EndProcedure

// Deprecated. Supplements the texts of the request for the document with the texts of the return of goods to the supplier in the register of Payments with suppliers.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutTransferOfAdvancePaymentToSupplier(Query, QueryTexts, Registers, TextTransferOfCalculations);
	
EndProcedure

// Deprecated. Supplements the texts of the request for the document with the texts of the return of goods to the supplier in the register of Payments with suppliers.
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
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutReturnOfAdvanceTransferToSupplier(Query, QueryTexts, Registers, TextTransferOfCalculations);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region SearchForPaymentGroundsAndDocuments

// Deprecated. Creates a structure for search parameters for payment grounds and payment documents
// 
// Parameters:
// 	SearchMode_ - Number - matching the search mode code:
// 		1 - Search for payment documents; 
// 		2 - Search for the basis (objects) of the payment.
// 
// Returns:
// 	Structure - Contains:
// 	* SearchMode_ - Number - matching the search mode code:
// 		1 - Search for payment documents; 
// 		2 - Search for the basis (objects) of the payment.
// 	* Companies - CatalogRef.Companies, Array of CatalogRef.Companies -
// 	* Documents   - Array of DocumentRef - documents that are used to search for payments.
// 	* OnDate      - Date - for a cross-section of found documents on the date
// 	* AdvancesOnly - Boolean - If "True", only advance payments will be refunded
// 	* RestrictPaymentDocumentTypes - Boolean - If "True", payment documents will be limited to the possible types
// 	                                                of incoming and outgoing payment documents.
// 	* LimitTypesOfPaymentGrounds  - Boolean - If "True", the payment grounds will be limited to the possible types
// 	                                                of incoming and outgoing documents.
// 	* SelectionParametersForDocumentTable - Structure - For selection according to a temporary table with documents, where:
//  	** FieldName - String - Name of the field that contains the document
//  	** SelectionTableName_ - String - name of the temporary table that contains the document
//
Function InitializeSearchParametersForPaymentBasesAndDocuments(SearchMode_ = 1) Export
	
	Return ARAPAccountingVAT.InitializeSearchParametersForPaymentBasesAndDocuments(SearchMode_);
	
EndFunction

// Deprecated. Prepare a temporary table "Calculation by clients_The basis of the Payment document"
// Creates a temporary table with columns:
// 	  Organization;
// 	  Document payments - payment document;
// 	  The basis of payment is a paid document;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Directions of activity;
// 	  Counterparty;
// 	  Contract;
// 	  Payment totals;
// 	  Payment totalupr;
// 	  The amount of the payment is correct.
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - 
// 	SearchParameters         - See InitializeSearchParametersForPaymentBasesAndDocuments
Procedure PrepareVT_SettlementsWithClients_GroundsAndPaymentDocuments(TempTablesManager, SearchParameters) Export
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithClients_GroundsAndPaymentDocuments(TempTablesManager, SearchParameters);
	
EndProcedure

// Deprecated. Prepare a temporary table "Settlements by suppliers_The basis of the Payment document"
// Creates a temporary table with columns:
// 	  Organization;
// 	  Document payments - payment document;
// 	  The basis of payment is a paid document;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Directions of activity;
// 	  Counterparty;
// 	  Contract;
// 	  Payment totals;
// 	  Payment totalupr;
// 	  The amount of the payment is correct.
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - 
// 	SearchParameters         - See InitializeSearchParametersForPaymentBasesAndDocuments
Procedure PrepareVT_SettlementsWithSuppliers_GroundsAndPaymentDocuments(TempTablesManager, SearchParameters) Export
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithSuppliers_GroundsAndPaymentDocuments(TempTablesManager, SearchParameters)
	
EndProcedure

#EndRegion

#Region AdvancesBasedOnSettlementData

// Deprecated. Creates a structure of parameters for the preparation of temporary tables with the calculations
// 
// Parameters:
//  InitialParameters - Undefined, Structure - custom structure with filled in values
// 
// Returns:
// 	Structure - LongDesc:
//   * StartDate                    - Date -
//   * EndDate                 - Date -
//   * Companies                   - Undefined, CatalogRef.Companies, Array of CatalogRef.Companies -
//   * ARAPDocument             - Undefined, DocumentRef - additional filter for the settlement document
//   * CreateEmptyTable          - Boolean - allows you to create a temporary table frame without data
//   * NewOnlineARAPAccounting - Boolean - mutual settlements "online" / " offline"
//   * EnableOrganizationSelection - Boolean - apply selection by organization
//   * ManualIndexFields           - Array of String - the ability to override the index field of the result
//   * TakeIntoAccountReservationOfAdvances   - Boolean - if "True", credited advances
//                                     that were previously reserved will not be included in the selection.
//   * SelectionParametersForSettlementDocument - Structure - For selection according to a temporary table with settlement documents, where:
//   	** FieldName - String - Name of the field that contains the document
//   	** SelectionTableName_ - String - name of the temporary table that contains the document
//   * AdvanceSelectionRule          - EnumRef.ProcedureOfRegisteringTaxInvoicesForPrepayment - the rule of selection of advances.
//
Function InitializeParametersForPreparationOfAdvancePayments(InitialParameters = Undefined) Export
	
	Return ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments(InitialParameters);
	
EndFunction

#Region PrepaymentsFromCustomer

// Deprecated. Prepare a temporary table "calculationsclienta_avances"
// Creates a temporary table with columns:
// 	  Calculation document;
// 	  Document Recorder;
// 	  Organization;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Directions of activity;
// 	  Counterparty;
// 	  Contract;
// 	  Datavance;
// 	  Document currency;
// 	  SummaAvancaVal - the amount in the document currency;
// 	  SummaAvance;
// 	  SummaAvansaUpr;
// 	  SummaAvansaRegl.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithCustomers_Advances(TempTablesManager, CalculationParameters) Export
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithCustomers_Advances(TempTablesManager, CalculationParameters);
	
EndProcedure

// Deprecated. Prepare a temporary table "Calculation by clients_Repayment of balances"
// Creates a temporary table with columns:
// 	  Calculation document;
// 	  Organization;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Document Recorder;
// 	  Counterparty;
// 	  Contract;
// 	  Directions of activity;
// 	  Iscontragent - the counterparty for which the advance arose;
// 	  IshDogovor - Contract Under Which there Was an advance;
// 	  From the direction of activity - the direction in which the advance arose;
// 	  Coralitikauchetapopartners;
// 	  Initial analyticsaccounts to partners - analytics for which an advance was formed;
// 	  Account Object Box;
// 	  Initial account objectobject - the settlement object for which the advance payment was generated;
// 	  Datavance;
// 	  Data settlement;
// 	  EVENTSNAK - If the repayment occurred due to the offset of the advance, then EVENTSNAK >= 0,
// 	                If the repayment occurred due to the repayment/write-off of debt, then EVENTSNAK < 0;
// 	  Type of event - the event in connection with which the advance payment occurred. Possible events:
// 	         - Enumeration.Economic operations.Write-offs of loan indebtedness,
// 	         - Enumeration.Economic operations.Return payment to the client,
// 	         - Enumeration.Economic operations.Offsetting the client;
// 	  Document currency;
// 	  Repayment totals;
// 	  Repayment Amount - the amount in the document currency;
// 	  The sum of the repayment of the;
// 	  The sum of the cancellation rules.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithCustomers_RepaymentOfAdvances(TempTablesManager, CalculationParameters) Export
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithCustomers_RepaymentOfAdvances(TempTablesManager, CalculationParameters);
	
EndProcedure

// Deprecated. Prepare a temporary table "CalculaTIon_transfErences_"
// Creates a temporary table with columns:
// 	  Organization;
// 	  Document payments;
// 	  Transfer Document;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Counterparty;
// 	  Directions of activity;  
// 	  Division;
// 	  Coralitikauchetapopartners;
// 	  Account Object Box;
// 	  CorContragent;
// 	  Root direction of activity;  
// 	  Corps Division;
// 	  Period;
// 	  Setting up an economic operation
// 	  Record ID;
// 	  Currency;
// 	  Prepayment;
// 	  PrepaymentRegl;
// 	  PrepaymentUpr.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithClients_TransfersOfAdvances(TempTablesManager, CalculationParameters) Export
		
	ARAPAccountingVAT.PrepareVT_SettlementsWithClients_TransfersOfAdvances(TempTablesManager, CalculationParameters);
	
EndProcedure

// Deprecated. Prepare a temporary table of "Received balances for cancellations and losses"
// Creates a temporary table with columns:
//   Organization;
//   Directions of activity;
//   Counterparty;
//   Contract;
//   From the direction of activity - the direction in which the advance arose;
//   Iscontragent - the counterparty for which the advance arose;
//   IshDogovor - Contract Under Which there Was an advance;
//   Settlement document;
//   Initial analyticsaccounts to partners - analytics for which an advance was formed;
//   Initial account objectobject - the settlement object for which the advance payment was generated;
//   Datavance;
//   Cancellation date - if it Is Empty, then it Is The Balance;
//   Document currency;
//   Document Recorder;
//   SummaVal - the amount in the document currency;
//   SummaUpr;
//   Summareg;
//   The amount.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_ReceivedAdvancesInTermsOfRepaymentsAndBalances(TempTablesManager, CalculationParameters) Export
	
	ARAPAccountingVAT.PrepareVT_ReceivedAdvancesInTermsOfRepaymentsAndBalances(TempTablesManager, CalculationParameters);
	
EndProcedure

#EndRegion

#Region PrepaymentsToVendor

// Deprecated. Prepare a temporary table "computersposters_avances"
// Creates a temporary table with the columns:
// 	  Calculation document;
// 	  Document Recorder;
// 	  Organization;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Directions of activity;
// 	  Counterparty;
// 	  Contract;
// 	  Datavance;
// 	  Document currency;
// 	  SummaAvancaVal - the amount in the document currency;
// 	  SummaAvance;
// 	  SummaAvansaUpr;
// 	  SummaAvansaRegl.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithSuppliers_Advances(TempTablesManager, CalculationParameters) Export
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithSuppliers_Advances(TempTablesManager, CalculationParameters);
	
EndProcedure

// Deprecated. Prepare a temporary table "Settlements by suppliers_Repayment of balances"
// Creates a temporary table with columns:
// 	  Calculation document;
// 	  Organization;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Document Recorder;
// 	  Counterparty;
// 	  Contract;
// 	  Directions of activity;
// 	  Iscontragent - the counterparty for which the advance arose;
// 	  IshDogovor - Contract Under Which there Was an advance;
// 	  From the direction of activity - the direction in which the advance arose;
// 	  Coralitikauchetapopartners;
// 	  Initial analyticsaccounts to partners - analytics for which an advance was formed;
// 	  Account Object Box;
// 	  Initial account objectobject - the settlement object for which the advance payment was generated;
// 	  Datavance;
// 	  Data settlement;
// 	  EVENTSNAK - If the repayment occurred due to the offset of the advance, then EVENTSNAK >= 0,
// 	                If the repayment occurred due to the repayment/write-off of debt, then EVENTSNAK < 0;
// 	  Type of event - the event in connection with which the advance payment occurred. Possible events:
// 	         - Enumeration.Economic operations.Return of the supplier's moneyreferences,
// 	         - Enumeration.Economic operations.Offsetting to the supplier;
// 	  Document currency;
// 	  Repayment totals;
// 	  Repayment Amount - the amount in the document currency;
// 	  The sum of the repayment of the;
// 	  The sum of the cancellation rules.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithSuppliers_RepaymentOfAdvances(TempTablesManager, CalculationParameters) Export
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithSuppliers_RepaymentOfAdvances(TempTablesManager, CalculationParameters);
	
EndProcedure

// Deprecated. Prepare a temporary table "computationsproviders_transferances"
// Creates a temporary table with columns:
// 	  Organization;
// 	  Document payments;
// 	  Transfer Document;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Counterparty;
// 	  Directions of activity;  
// 	  Division;
// 	  Coralitikauchetapopartners;
// 	  Account Object Box;
// 	  CorContragent;
// 	  Root direction of activity;  
// 	  Corps Division;
// 	  Period;
// 	  Setting up an economic operation
// 	  Record ID;
// 	  Currency;
// 	  Prepayment;
// 	  PrepaymentRegl;
// 	  PrepaymentUpr.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithSuppliers_TransfersOfAdvances(TempTablesManager, CalculationParameters) Export
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithSuppliers_TransfersOfAdvances(TempTablesManager, CalculationParameters)
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

// Deprecated. Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_PostingToPartnersARAPAccountingAndARAPRevaluation(StepsTable,CurrentParent) Export
	MonthEndClosingARAPAccounting.AddStage_PostingToPartnersARAPAccountingAndARAPRevaluation(StepsTable,CurrentParent);
EndProcedure

// Deprecated. 
// Parameters:
// 	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure Use_FormationOfRegisteredRecordsForSettlementsWithPartnersAndReEvaluationOfSettlements(HandlerParameters) Export
	
	MonthEndClosingARAPAccounting.Use_FormationOfRegisteredRecordsForSettlementsWithPartnersAndReEvaluationOfSettlements(HandlerParameters);
	
EndProcedure

// Deprecated. 
// Parameters:
// 	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure Registration_FormationOfRegisteredRecordsForSettlementsWithPartnersAndReassessmentOfSettlements(HandlerParameters) Export
	
	MonthEndClosingARAPAccounting.Registration_FormationOfRegisteredRecordsForSettlementsWithPartnersAndReassessmentOfSettlements(HandlerParameters);
	
EndProcedure

// Deprecated.
Procedure DescriptionOfChecks_FormationOfRegisteredRecordsOnSettlementsWithPartnersAndReassessmentOfSettlements(TableOfChecks) Export
	
	MonthEndClosingARAPAccounting.DescriptionOfChecks_FormationOfRegisteredRecordsOnSettlementsWithPartnersAndReassessmentOfSettlements(TableOfChecks);
	
EndProcedure

// Deprecated.
Procedure CheckingSettlementBalances(CheckParameters) Export
	
	MonthEndClosingARAPAccounting.CheckingSettlementBalances(CheckParameters);
	
EndProcedure

// Deprecated.
Procedure CheckingSettlementBalancesManualAdjustment(CheckParameters) Export
	
	MonthEndClosingARAPAccounting.CheckingSettlementBalancesManualAdjustment(CheckParameters);
	
EndProcedure

// Deprecated.
Procedure CheckingExpandedBalance(CheckParameters) Export 
	
	MonthEndClosingARAPAccounting.CheckingExpandedBalance(CheckParameters);
		
EndProcedure

// Deprecated.
Procedure CheckingExpandedBalanceManualAdjustment(CheckParameters) Export 
	
	MonthEndClosingARAPAccounting.CheckingExpandedBalanceManualAdjustment(CheckParameters);
		
EndProcedure

// Deprecated.
Procedure Perform_GenerationOfRegisteredRecordsForPartnersARAPAccountingAndRevaluationOfCalculations(HandlerParameters) Export
	
	MonthEndClosingARAPAccounting.Perform_GenerationOfRegisteredRecordsForPartnersARAPAccountingAndRevaluationOfCalculations(HandlerParameters);
	
EndProcedure

#EndRegion

#Region Modularity

// Returns the structure of the settlement status.
// 
// Parameters:
// 	Object - ClientApplicationForm - LongDesc:
// * Object - CatalogRef, DocumentRef - object to the form.
// 	ParametersStructure - See ARAPAccountingServer.MechanismParameters
// Returns:
// 	See StructureOfStateOfCalculations
//
Function MutualSettlementsStatus(Object, ParametersStructure) Export
	
	DataPathAmountOfSettlements = ?(ParametersStructure.AmountARAP="",ParametersStructure.DocumentAmount,ParametersStructure.AmountARAP);
	AmountARAP = TMCommonUseClientServer.DataAlongWay(Object, DataPathAmountOfSettlements,,0);
	Organization         = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
	PaymentType_         = ParametersStructure.PaymentType_;
	ARAPObjectSettings     = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings);
	
	If ParametersStructure.ThisIsOrder 
		And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
			Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)Then
		LinkToOrder = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Ref);
		If Metadata.InformationRegisters.SalesOrderStates.Dimensions.OrderDocument.Type.ContainsType(TypeOf(LinkToOrder))
			Or Metadata.InformationRegisters.PurchaseOrderStates.Dimensions.OrderDocument.Type.ContainsType(TypeOf(LinkToOrder)) Then
			Result = OrderARAPAccountingState(LinkToOrder, PaymentType_);
			If Result <> Undefined Then
				Return Result;
			EndIf;
		EndIf;
	EndIf;
	
	ARAPObject = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObject);
	If TypeOf(ARAPObject) = Type("Array") Then
		CommonClientServer.DeleteAllValueOccurrencesFromArray(ARAPObject, PredefinedValue("Catalog.ARAPObjects.EmptyRef"));
		ARAPObject = CommonClientServer.CollapseArray(ARAPObject);
		If ARAPObject.Count() = 1 Then
			ARAPObject = ARAPObject[0];
			AmountARAP = 0;
		Else
			ARAPObject = Undefined;
		EndIf;
	EndIf;
	If Not ValueIsFilled(ARAPObject) Then
		If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
			Contract = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
			ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(Contract, Organization, PaymentType_);
		ElsIf ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders Then 
			OrderBase = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
			ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(OrderBase, Organization, PaymentType_);
		EndIf;
	EndIf;
	
	ThisIsContractWithInvoices = ParametersStructure.IsCatalog 
	                        And ParametersStructure.Ref = ParametersStructure.Contract
	                        And ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
	ThisIsOrderWithInvoices   = ParametersStructure.ThisIsOrder
	                        And ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice;
	
	Return StateOfSettlementsOfSettlementObject(ARAPObject, AmountARAP, PaymentType_, Organization, ThisIsOrderWithInvoices, ThisIsContractWithInvoices);
	
EndFunction

// Parameters:
// 	ARAPObject - CatalogRef.ARAPObjects - The object of calculations.
// 	AmountARAP - Number - the amount of mutual settlements for calculating the percentage of payments and shipments.
// 	PaymentType_ - EnumRef.PartnersARAPAccountingTypes - determines by which register to view the status.
// 	Organization - CatalogRef.Companies - The organization for which you need to view the status of calculations.
// 	ThisIsOrderWithInvoices - Boolean - indicates that the AR/AP object is an order with the details of the calculations by the order of the invoice
// 	ThisIsContractWithInvoices - Boolean - an indication that the AR/AP object is a Contract detailing the calculations of the sub-agreements with the invoice
// 	
// Returns:
// 	See StructureOfStateOfCalculations
//
Function StateOfSettlementsOfSettlementObject(ARAPObject, AmountARAP, PaymentType_, Organization = Undefined, ThisIsOrderWithInvoices = False, ThisIsContractWithInvoices = False) Export
	
	StructureOfCalculations = StructureOfStateOfCalculations();
	
	If Not ValueIsFilled(ARAPObject)
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) 
			And PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting")
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting)
			And PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting") Then
		Return StructureOfCalculations;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("AmountOfInitialSettlements", AmountARAP);
	Query.SetParameter("ARAPObject", ARAPObject);
	Query.SetParameter("ReportData", 4);
	
	ArrayOfTexts = New Array;

	TextOfInitialSettlements = "
		|SELECT ALLOWED
		|	CASE WHEN &AmountOfInitialSettlements = 0
		|		THEN CASE WHEN ARAPObjects.AmountARAP = 0
		|						THEN ARAPObjects.Sum
		|					ELSE ARAPObjects.AmountARAP
		|				END
		|		ELSE &AmountOfInitialSettlements
		|	END AS Sum
		|INTO TTAmountOfInitialSettlements
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Ref = &ARAPObject";
	ArrayOfTexts.Add(TextOfInitialSettlements);
	
	If PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting") 
		And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			
			If ThisIsOrderWithInvoices Then
				
				QueryText = "
					|SELECT ALLOWED
					|	ARAPObjects.Ref AS ARAPObjectInvoice,
					|	ARAPObjectsOrder.Ref AS ARAPObjectOrder,
					|	ARAPObjectsOrder.Object AS SalesOrder,
					|	SUM(CASE
					|			WHEN ARAPObjects.AmountARAP = 0
					|				THEN CASE
					|					WHEN ARAPObjects.Sum = 0
					|						THEN 0
					|					ELSE SettlementsWithCustomersTurnover.ToShipReceipt / ARAPObjects.Sum
					|				END
					|			ELSE SettlementsWithCustomersTurnover.ToShipReceipt / ARAPObjects.AmountARAP
					|		END) AS OrderShare,
					|	MAX (ARAPObjectsOrder.Sum) AS OrderAmount
					|INTO TTCommunicationOrdersINVOICES
					|FROM
					|	AccumulationRegister.CustomersARAPAccounting.Turnovers( , , Recorder, ARAPObject = &ARAPObject) AS SettlementsWithCustomersTurnover
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjectsOrder
					|		ON SettlementsWithCustomersTurnover.ARAPObject = ARAPObjectsOrder.Ref
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|		ON SettlementsWithCustomersTurnover.Recorder = ARAPObjects.Object
					|			AND NOT ARAPObjects.DeletionMark
					|
					|GROUP BY
					|	ARAPObjects.Ref,
					|	ARAPObjectsOrder.Ref,
					|	ARAPObjectsOrder.Object
					|";

				ArrayOfTexts.Add(QueryText); 
				
				QueryText = "
					|SELECT ALLOWED
					|	ISNULL(SUM(Calculations.AmountOfPayments), 0) AS AmountOfPayments,
					|	ISNULL(SUM(Calculations.AmountByShipments), 0) AS AmountByShipments,
					|	ISNULL(SUM(Calculations.DebtAmount), 0) AS DebtAmount,
					|	ISNULL(MAX(Calculations.AmountOfInitialSettlements), &AmountOfInitialSettlements) AS AmountOfInitialSettlements
					|INTO TTCalculations
					|FROM (SELECT
					|		&TemplateForPaidField AS AmountOfPayments,
					|
					|		&TemplateOfShippedField AS AmountByShipments,
					|
					|		CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN CalculationsByTerms.Debt
					|			ELSE 0
					|		END AS DebtAmount,
					|
					|		CASE WHEN &AmountOfInitialSettlements = 0
					|			THEN CASE WHEN ARAPObjects.AmountARAP = 0
					|							THEN ARAPObjects.Sum
					|							ELSE ARAPObjects.AmountARAP
					|						END
					|			ELSE &AmountOfInitialSettlements
					|		END AS AmountOfInitialSettlements
					|
					|	FROM
					|			AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
					|				INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|				ON CalculationsByTerms.ARAPObject = ARAPObjects.Ref
					|		WHERE
					|			ARAPObjects.Ref = &ARAPObject
					|			AND CalculationsByTerms.AccountingDimensionByPartners.Organization = &Organization
					|			AND CalculationsByTerms.Active
					|	
					|	UNION ALL
					|	
					|	SELECT
					|		(&TemplateForPaidField) * TTCommunicationOrdersINVOICES.OrderShare AS AmountOfPayments,
					|		0 AS AmountByShipments,
					|		0 AS DebtAmount,
					|		CASE WHEN &AmountOfInitialSettlements = 0
					|			THEN TTCommunicationOrdersINVOICES.OrderAmount
					|			ELSE &AmountOfInitialSettlements
					|		END AS AmountOfInitialSettlements
					|	FROM
					|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
					|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
					|			ON CalculationsByTerms.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice 
					|	WHERE
					|		CalculationsByTerms.ARAPObject IN (SELECT
					|							T.ARAPObjectInvoice
					|						FROM
					|							TTCommunicationOrdersINVOICES AS T)
					|		AND CalculationsByTerms.AccountingDimensionByPartners.Organization = &Organization
					|		AND CalculationsByTerms.Active
					|	
					|	UNION ALL
					|	
					|	SELECT
					|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN Calculations.BeingPaid
					|			ELSE -Calculations.BeingPaid
					|		END AS AmountOfPayments,
					|		0 AS AmountByShipments,
					|		0 AS DebtAmount,
					|		CASE WHEN &AmountOfInitialSettlements = 0
					|			THEN CASE WHEN ARAPObjects.AmountARAP = 0
					|							THEN ARAPObjects.Sum
					|							ELSE ARAPObjects.AmountARAP
					|						END
					|			ELSE &AmountOfInitialSettlements
					|		END AS AmountOfInitialSettlements
					|	FROM
					|		AccumulationRegister.CustomersARAPAccounting AS Calculations
					|				INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|				ON Calculations.ARAPObject = ARAPObjects.Ref
					|		WHERE
					|			ARAPObjects.Ref = &ARAPObject
					|			AND Calculations.AccountingDimensionByPartners.Organization = &Organization
					|			AND Calculations.Active
					|	
					|	UNION ALL
					|	
					|	SELECT
					|		(CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN Calculations.BeingPaid
					|			ELSE -Calculations.BeingPaid
					|		END) * TTCommunicationOrdersINVOICES.OrderShare AS AmountOfPayments,
					|		0 AS AmountByShipments,
					|		0 AS DebtAmount,
					|		CASE WHEN &AmountOfInitialSettlements = 0
					|			THEN TTCommunicationOrdersINVOICES.OrderAmount
					|			ELSE &AmountOfInitialSettlements
					|		END AS AmountOfInitialSettlements
					|	FROM
					|		AccumulationRegister.CustomersARAPAccounting AS Calculations
					|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
					|			ON Calculations.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice 
					|	WHERE
					|		Calculations.ARAPObject IN (SELECT
					|							T.ARAPObjectInvoice
					|						FROM
					|							TTCommunicationOrdersINVOICES AS T)
					|		AND Calculations.AccountingDimensionByPartners.Organization = &Organization
					|		AND Calculations.Active
					|	) AS Calculations
					|";
				
			ElsIf ThisIsContractWithInvoices Then
				
				QueryText = "
					|SELECT ALLOWED
					|	ISNULL(SUM(Calculations.AmountOfPayments),0) AS AmountOfPayments,
					|
					|	ISNULL(SUM(Calculations.AmountByShipments),0) AS AmountByShipments,
					|
					|	ISNULL(SUM(Calculations.DebtAmount),0) AS DebtAmount,
					|
					|	CASE WHEN &AmountOfInitialSettlements = 0
					|		THEN MAX(Calculations.AmountOfInitialSettlements)
					|		ELSE &AmountOfInitialSettlements
					|	END AS AmountOfInitialSettlements
					|
					|INTO TTCalculations
					|FROM (SELECT
					|		(&TemplateForPaidField) AS AmountOfPayments,
					|	
					|		(&TemplateOfShippedField) AS AmountByShipments,
					|	
					|		CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN CAST(ISNULL(CalculationsByTerms.Debt, 0) AS NUMBER(31,2))
					|			ELSE 0
					|		END AS DebtAmount,
					|	
					|		CASE WHEN CalculationsByTerms.ARAPObject.AmountARAP = 0
					|			THEN CalculationsByTerms.ARAPObject.Sum
					|			ELSE CalculationsByTerms.ARAPObject.AmountARAP
					|		END AS AmountOfInitialSettlements
					|	FROM
					|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjectsOfContract
					|		ON CalculationsByTerms.ARAPObject = ARAPObjectsOfContract.Ref
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|		ON ARAPObjectsOfContract.Contract = ARAPObjects.Contract
					|		AND NOT ARAPObjects.DeletionMark
					|	WHERE
					|		ARAPObjects.Ref = &ARAPObject
					|		AND CalculationsByTerms.Active
					|		AND CalculationsByTerms.AccountingDimensionByPartners.Organization = &Organization
					|	
					|	UNION ALL
					|	
					|	SELECT
					|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN Calculations.BeingPaid
					|			ELSE -Calculations.BeingPaid
					|		END AS AmountOfPayments,
					|		0 AS AmountOfDeliveries,
					|		0 AS DebtAmount,
					|		CASE WHEN Calculations.ARAPObject.AmountARAP = 0
					|			THEN Calculations.ARAPObject.Sum
					|			ELSE Calculations.ARAPObject.AmountARAP
					|		END AS AmountOfInitialSettlements
					|	FROM
					|	AccumulationRegister.CustomersARAPAccounting AS Calculations
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjectsOfContract
					|		ON Calculations.ARAPObject = ARAPObjectsOfContract.Ref
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|		ON ARAPObjectsOfContract.Contract = ARAPObjects.Contract
					|		AND NOT ARAPObjects.DeletionMark
					|	WHERE
					|		ARAPObjects.Ref = &ARAPObject
					|		AND Calculations.Active
					|		AND Calculations.AccountingDimensionByPartners.Organization = &Organization
					|	) AS Calculations
					|";
				
			Else
				
				QueryText = "
					|SELECT ALLOWED
					|	ISNULL(SUM(Calculations.AmountOfPayments),0) AS AmountOfPayments,
					|
					|	ISNULL(SUM(Calculations.AmountByShipments),0) AS AmountByShipments,
					|
					|	ISNULL(SUM(Calculations.DebtAmount),0) AS DebtAmount,
					|
					|	CASE WHEN &AmountOfInitialSettlements = 0
					|		THEN MAX(Calculations.AmountOfInitialSettlements)
					|		ELSE &AmountOfInitialSettlements
					|	END AS AmountOfInitialSettlements
					|
					|INTO TTCalculations
					|FROM (SELECT
					|		(&TemplateForPaidField) AS AmountOfPayments,
					|	
					|		(&TemplateOfShippedField) AS AmountByShipments,
					|	
					|		CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN CalculationsByTerms.Debt - CalculationsByTerms.Prepayment
					|			ELSE CalculationsByTerms.Prepayment - CalculationsByTerms.Debt
					|		END AS DebtAmount,
					|	
					|		CASE WHEN CalculationsByTerms.ARAPObject.AmountARAP = 0
					|			THEN CalculationsByTerms.ARAPObject.Sum
					|			ELSE CalculationsByTerms.ARAPObject.AmountARAP
					|		END AS AmountOfInitialSettlements
					|	
					|	FROM
					|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
					|			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|			ON CalculationsByTerms.ARAPObject = ARAPObjects.Ref
					|	WHERE
					|		ARAPObjects.Ref = &ARAPObject
					|		AND CalculationsByTerms.AccountingDimensionByPartners.Organization = &Organization
					|		AND CalculationsByTerms.Active
					|	
					|	UNION ALL
					|	
					|	SELECT
					|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN Calculations.BeingPaid
					|			ELSE -Calculations.BeingPaid
					|		END AS AmountOfPayments,
					|		0 AS AmountByShipments,
					|		0 AS DebtAmount,
					|		CASE WHEN Calculations.ARAPObject.AmountARAP = 0
					|			THEN Calculations.ARAPObject.Sum
					|			ELSE Calculations.ARAPObject.AmountARAP
					|		END AS AmountOfInitialSettlements
					|	
					|	FROM
					|		AccumulationRegister.CustomersARAPAccounting AS Calculations
					|			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|			ON Calculations.ARAPObject = ARAPObjects.Ref
					|	WHERE
					|		ARAPObjects.Ref = &ARAPObject
					|		AND Calculations.AccountingDimensionByPartners.Organization = &Organization
					|		AND Calculations.Active
					|	) AS Calculations
					|";
				
			EndIf;
			
			QueryText = StrReplace(QueryText, "&TemplateForPaidField", StrTemplate("%1 + %2", FieldTemplatePaidByCustomer(), FieldTemplateCreditedToClient())); 
			QueryText = StrReplace(QueryText, "&TemplateOfShippedField", TemplateFieldShippedToClient());
			
			ArrayOfTexts.Add(QueryText);
			
		Else
			QueryText = "
				|SELECT ALLOWED
				|	ISNULL(SUM(CASE WHEN CalculationsBalancesAndTurnover.Recorder REFS Document.SaleAdjustment
				|		THEN 0
				|		ELSE CalculationsBalancesAndTurnover.SumExpense
				|	END),0) AS AmountOfPayments,
				|
				|	ISNULL(SUM(CASE WHEN ISNULL(CalculationsBalancesAndTurnover.SumReceipt, 0) < 0
				|		OR CalculationsBalancesAndTurnover.Recorder REFS Document.SaleAdjustment 
				|		THEN 0
				|		ELSE CAST(ISNULL(CalculationsBalancesAndTurnover.SumReceipt, 0) AS NUMBER(31,2))
				|	END),0) AS AmountByShipments,
				|
				|	ISNULL(SUM(CAST(ISNULL(CalculationsBalancesAndTurnover.SumReceipt - CalculationsBalancesAndTurnover.SumExpense, 0) AS NUMBER(31,2))),0) AS DebtAmount
				|
				|INTO TTCalculations
				|FROM
				|	AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(, , Recorder, , ARAPObject = &ARAPObject) AS CalculationsBalancesAndTurnover
				|WHERE
				|	CalculationsBalancesAndTurnover.AccountingDimensionByPartners.Organization = &Organization
				|";
			ArrayOfTexts.Add(QueryText);
		EndIf;
		
		QueryText = "
			|SELECT
			|	Calculations.AmountOfPayments         AS AmountOfPayments,
			|	Calculations.AmountByShipments      AS AmountByShipments,
			|	CASE WHEN Calculations.AmountOfPayments = 0
			|		OR TTAmountOfInitialSettlements.Sum = 0
			|			THEN 0
			|		ELSE CAST(Calculations.AmountOfPayments * 100 / TTAmountOfInitialSettlements.Sum AS NUMBER(20, 2))
			|	END                      AS PercentageOfPayments,
			|	CASE WHEN Calculations.AmountByShipments = 0
			|		OR TTAmountOfInitialSettlements.Sum = 0
			|			THEN 0
			|		ELSE CAST(Calculations.AmountByShipments * 100 / TTAmountOfInitialSettlements.Sum AS NUMBER(20, 2))
			|	END                      AS PercentageOfShipments,
			|	Calculations.DebtAmount AS DebtAmount
			|FROM
			|	TTAmountOfInitialSettlements AS TTAmountOfInitialSettlements
			|	INNER JOIN TTCalculations AS Calculations
			|		ON (TRUE)";
		ArrayOfTexts.Add(QueryText);
		
	ElsIf AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting) Then
		
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			
			If ThisIsOrderWithInvoices Then
				
				QueryText = "
					|SELECT ALLOWED
					|	ARAPObjects.Ref AS ARAPObjectInvoice,
					|	ARAPObjectsOrder.Ref AS ARAPObjectOrder,
					|	ARAPObjectsOrder.Object AS PurchaseOrder,
					|	SUM(CASE
					|			WHEN ARAPObjects.AmountARAP = 0
					|				THEN CASE
					|					WHEN ARAPObjects.Sum = 0
					|						THEN 0
					|					ELSE SettlementsWithSuppliersTurnover.ToReceiveExpense / ARAPObjects.Sum
					|				END
					|			ELSE SettlementsWithSuppliersTurnover.ToReceiveExpense / ARAPObjects.AmountARAP
					|		END) AS OrderShare,
					|	MAX (ARAPObjectsOrder.Sum) AS OrderAmount
					|INTO TTCommunicationOrdersINVOICES
					|FROM
					|	AccumulationRegister.VendorsARAPAccounting.Turnovers( , , Recorder, ARAPObject = &ARAPObject) AS SettlementsWithSuppliersTurnover
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjectsOrder
					|		ON SettlementsWithSuppliersTurnover.ARAPObject = ARAPObjectsOrder.Ref
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|		ON SettlementsWithSuppliersTurnover.Recorder = ARAPObjects.Object
					|		AND NOT ARAPObjects.DeletionMark
					|
					|GROUP BY
					|	ARAPObjects.Ref,
					|	ARAPObjectsOrder.Ref,
					|	ARAPObjectsOrder.Object
					|";
				
				ArrayOfTexts.Add(QueryText); 
				
				QueryText = "
					|SELECT ALLOWED
					|	ISNULL(SUM(Calculations.AmountOfPayments), 0) AS AmountOfPayments,
					|	ISNULL(SUM(Calculations.AmountOfDeliveries), 0) AS AmountOfDeliveries,
					|	ISNULL(SUM(Calculations.DebtAmount), 0) AS DebtAmount,
					|	ISNULL(MAX(Calculations.AmountOfInitialSettlements), &AmountOfInitialSettlements) AS AmountOfInitialSettlements
					|INTO TTCalculations
					|FROM (SELECT
					|		&TemplateForPaidField AS AmountOfPayments,
					|
					|		&FieldTemplateSupplied AS AmountOfDeliveries,
					|
					|		CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN CalculationsByTerms.Debt
					|			ELSE 0
					|		END AS DebtAmount,
					|
					|		CASE WHEN &AmountOfInitialSettlements = 0
					|			THEN CASE WHEN ARAPObjects.AmountARAP = 0
					|							THEN ARAPObjects.Sum
					|							ELSE ARAPObjects.AmountARAP
					|						END
					|			ELSE &AmountOfInitialSettlements
					|		END AS AmountOfInitialSettlements
					|
					|	FROM
					|		AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
					|			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|			ON CalculationsByTerms.ARAPObject = ARAPObjects.Ref
					|	WHERE
					|		ARAPObjects.Ref = &ARAPObject
					|		AND CalculationsByTerms.AccountingDimensionByPartners.Organization = &Organization
					|		AND CalculationsByTerms.Active
					|	
					|	UNION ALL
					|	
					|	SELECT
					|		(&TemplateForPaidField) * TTCommunicationOrdersINVOICES.OrderShare AS AmountOfPayments, 
					|		0 AS AmountByShipments,
					|		0 AS DebtAmount,
					|		CASE WHEN &AmountOfInitialSettlements = 0
					|			THEN TTCommunicationOrdersINVOICES.OrderAmount
					|			ELSE &AmountOfInitialSettlements
					|		END AS AmountOfInitialSettlements
					|	FROM
					|		AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
					|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
					|			ON CalculationsByTerms.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice 
					|	WHERE
					|		CalculationsByTerms.ARAPObject IN (SELECT
					|							T.ARAPObjectInvoice
					|						FROM
					|							TTCommunicationOrdersINVOICES AS T)
					|		AND CalculationsByTerms.AccountingDimensionByPartners.Organization = &Organization
					|		AND CalculationsByTerms.Active
					|	) AS Calculations
					|";
				
			ElsIf ThisIsContractWithInvoices Then
				
				QueryText = "
					|SELECT ALLOWED
					|	ISNULL(SUM(&TemplateForPaidField), 0) AS AmountOfPayments,
					|
					|	ISNULL(SUM(&FieldTemplateSupplied), 0) AS AmountOfDeliveries,
					|
					|	ISNULL(SUM(CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN CalculationsByTerms.Debt
					|		ELSE 0
					|	END), 0) AS DebtAmount,
					|
					|	CASE WHEN &AmountOfInitialSettlements = 0
					|		THEN MAX(CASE WHEN CalculationsByTerms.ARAPObject.AmountARAP = 0
					|							THEN CalculationsByTerms.ARAPObject.Sum
					|							ELSE CalculationsByTerms.ARAPObject.AmountARAP
					|						END)
					|		ELSE &AmountOfInitialSettlements
					|	END AS AmountOfInitialSettlements
					|
					|INTO TTCalculations
					|FROM
					|AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
					|	INNER JOIN Catalog.ARAPObjects AS ARAPObjectsOfContract
					|	ON CalculationsByTerms.ARAPObject = ARAPObjectsOfContract.Ref
					|	INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|	ON ARAPObjectsOfContract.Contract = ARAPObjects.Contract
					|	AND NOT ARAPObjects.DeletionMark
					|WHERE
					|	ARAPObjects.Ref  	= &ARAPObject
					|	AND CalculationsByTerms.Active
					|	AND CalculationsByTerms.AccountingDimensionByPartners.Organization = &Organization
					|";
				
			Else
				
				QueryText = "
					|SELECT ALLOWED
					|	ISNULL(SUM(&TemplateForPaidField), 0) AS AmountOfPayments,
					|
					|	ISNULL(SUM(&FieldTemplateSupplied), 0) AS AmountOfDeliveries,
					|
					|	ISNULL(SUM(CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
					|			THEN CalculationsByTerms.Debt - CalculationsByTerms.Prepayment
					|		ELSE CalculationsByTerms.Prepayment - CalculationsByTerms.Debt
					|	END), 0) AS DebtAmount,
					|
					|	CASE WHEN &AmountOfInitialSettlements = 0
					|		THEN MAX(CASE WHEN CalculationsByTerms.ARAPObject.AmountARAP = 0
					|							THEN CalculationsByTerms.ARAPObject.Sum
					|							ELSE CalculationsByTerms.ARAPObject.AmountARAP
					|						END)
					|		ELSE &AmountOfInitialSettlements
					|	END AS AmountOfInitialSettlements
					|
					|INTO TTCalculations
					|FROM
					|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|		ON CalculationsByTerms.ARAPObject = ARAPObjects.Ref
					|WHERE
					|	ARAPObjects.Ref = &ARAPObject
					|	AND CalculationsByTerms.AccountingDimensionByPartners.Organization = &Organization
					|	AND CalculationsByTerms.Active
					|";
				
			EndIf;
			
			QueryText = StrReplace(QueryText, "&TemplateForPaidField", StrTemplate("%1 + %2", TemplateForPaidToSupplierField(), FieldTemplateCreditedBySupplier())); 
			QueryText = StrReplace(QueryText, "&FieldTemplateSupplied", FieldTemplateSuppliedBySupplier());
			ArrayOfTexts.Add(QueryText);
			
		Else
			QueryText = "
				|SELECT ALLOWED
				|	ISNULL(SUM(CASE WHEN CalculationsBalancesAndTurnover.Recorder REFS Document.PurchaseAdjustment
				|			THEN 0
				|		ELSE CalculationsBalancesAndTurnover.SumReceipt
				|	END), 0) AS AmountOfPayments,
				|
				|	ISNULL(SUM(CASE WHEN CalculationsBalancesAndTurnover.SumExpense < 0
				|					OR CalculationsBalancesAndTurnover.Recorder REFS Document.PurchaseAdjustment
				|			THEN 0
				|		ELSE CalculationsBalancesAndTurnover.SumExpense
				|	END), 0) AS AmountOfDeliveries,
				|
				|	ISNULL(SUM(CalculationsBalancesAndTurnover.SumExpense - CalculationsBalancesAndTurnover.SumReceipt), 0) AS DebtAmount
				|
				|INTO TTCalculations
				|FROM
				|	AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(, , Recorder, , ARAPObject = &ARAPObject) AS CalculationsBalancesAndTurnover
				|WHERE
				|	CalculationsBalancesAndTurnover.AccountingDimensionByPartners.Organization = &Organization
				|";
			ArrayOfTexts.Add(QueryText);
		EndIf;
		
		QueryText = "
			|SELECT
			|	Calculations.AmountOfPayments         AS AmountOfPayments,
			|	Calculations.AmountOfDeliveries      AS AmountOfDeliveries,
			|	CASE WHEN Calculations.AmountOfPayments = 0
			|		OR TTAmountOfInitialSettlements.Sum = 0
			|			THEN 0
			|		ELSE CAST(Calculations.AmountOfPayments * 100 / TTAmountOfInitialSettlements.Sum AS NUMBER(20, 2))
			|	END                      AS PercentageOfPayments,
			|	CASE WHEN Calculations.AmountOfDeliveries = 0
			|		OR TTAmountOfInitialSettlements.Sum = 0
			|			THEN 0
			|		ELSE CAST(Calculations.AmountOfDeliveries* 100 / TTAmountOfInitialSettlements.Sum AS NUMBER(20, 2))
			|	END                      AS PercentageOfDeliveries,
			|	Calculations.DebtAmount AS DebtAmount
			|FROM
			|	TTAmountOfInitialSettlements AS TTAmountOfInitialSettlements
			|	INNER JOIN TTCalculations AS Calculations
			|		ON (TRUE)";
		ArrayOfTexts.Add(QueryText);
		
	EndIf;
	
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		FillPropertyValues(StructureOfCalculations, Result.Unload()[0]);
	EndIf;
	
	Return StructureOfCalculations;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ServiceProceduresAndFunctionsForSelectingCalculationDocument

// The Query Text for selecting the payment basis, the UIP by the number of the payment basis / UIP for the search.
// 
// Parameters:
//  InputByString - Boolean - Indicates that the line is being entered. Says that you need to select the first 10. 
//  	The search is based on the part of the name/number of the basis of the payment, or part of the UIP.
//  FilterStructure1 - See ARAPAccountingClientServer.SelectionDataSelectionStructure.
//  TheseAreSettlementsWithClient  - Boolean - Flag containing True
//  	if "The selection structure.Type of settlements = Transfers.Types of settlements by partners.Calculation by client".
//  ThisIsWhip - Boolean - Flag that indicates that the Query Text is generated to search for the basis of the payment by the UIP number.
//
// Returns:
//  String - query text.
//
Function QueryTextForSelectingPaymentBasisByLine(InputByString, FilterStructure1, TheseAreSettlementsWithClient,
	ThisIsWhip)
	
	QueriesTexts = New Array;
	
	QueryText = "
	|SELECT //First10
	|	DocumentsRegistry.Ref AS PaymentPurpose,
	|	DocumentsRegistry.Counterparty.Key AS Counterparty,
	|	DocumentsRegistry.Contract AS Contract,
	|	CASE
	|		WHEN VALUETYPE(DocumentsRegistry.Ref) = TYPE(Document.CustomerCommercialInvoice)
	|		THEN CAST(DocumentsRegistry.Ref AS Document.CustomerCommercialInvoice).PaymentID
	|		ELSE """"
	|	END AS PaymentID,
	|	CASE
	|		WHEN DocumentsRegistry.Posted
	|		THEN 1
	|		WHEN DocumentsRegistry.DeletionMark
	|		THEN 2
	|		ELSE 0
	|	END AS State
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|
	|LEFT JOIN
	|	Catalog.CounterpartyContracts AS Contracts
	|ON
	|	DocumentsRegistry.Contract = Contracts.Ref
	|WHERE
	|	(DocumentsRegistry.Organization IN (&Organization)
	|		OR NOT &Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
	|		AND DocumentsRegistry.Contract IN (SELECT T.Ref FROM TTCentralizedContracts AS T)
	|		AND (DocumentsRegistry.Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
	|			OR ISNULL(Contracts.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed, FALSE))
	|		OR DocumentsRegistry.Organization.ParentCompany IN (&Organization)
	|		AND DocumentsRegistry.Organization.TransactionsUsingParentCompanyAreAllowed)
	|
	|	AND &DynamicConditionsRegistry
	|";
	
	QueriesTexts.Add(QueryText);
	
	If ThisIsWhip Then
		
		QueryText = "
		|SELECT //First10
		|	ARAPObjects.Object AS PaymentPurpose,
		|	ARAPObjects.Counterparty AS Counterparty,
		|	ARAPObjects.Contract AS Contract,
		|	ARAPObjects.PaymentID AS PaymentID,
		|	ARAPObjects.State AS State
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|
		|LEFT JOIN
		|	Catalog.CounterpartyContracts AS Contracts
		|ON
		|	ARAPObjects.Contract = Contracts.Ref
		|WHERE
		|	(ARAPObjects.Organization IN (&Organization)
		|	OR NOT &Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
		|		AND ARAPObjects.Contract IN (SELECT T.Ref FROM TTCentralizedContracts AS T)
		|		AND (ARAPObjects.Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
		|			OR ISNULL(Contracts.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed, FALSE))
		|	OR ARAPObjects.Organization.ParentCompany IN (&Organization)
		|		AND ARAPObjects.Organization.TransactionsUsingParentCompanyAreAllowed)
		|
		|	AND ARAPObjects.PaymentID IN (&SearchString)
		|
		|	AND &DynamicConditionsARAPObjects
		|";
		
		QueriesTexts.Add(QueryText);
	EndIf;
	
	QueryText = "
	|SELECT //First10
	|	Contracts.Ref AS PaymentPurpose,
	|	Contracts.Counterparty AS Counterparty,
	|	Contracts.Ref AS Contract,
	|	Contracts.PaymentID AS PaymentID,
	|	CASE
	|		WHEN Contracts.DeletionMark
	|		THEN 2
	|		ELSE 0
	|	END AS State
	|FROM
	|	Catalog.CounterpartyContracts AS Contracts
	|WHERE
	|	(Contracts.Organization IN (&Organization)
	|		OR NOT &Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
	|			AND Contracts.Ref IN (SELECT 
	|			                                 TTCentralizedContracts.Ref 
	|			                                 FROM TTCentralizedContracts)
	|			AND (Contracts.Organization IN (SELECT T.ParentCompany FROM TTParentCompany AS T)
	|				OR Contracts.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed)
	|		OR Contracts.Organization.ParentCompany IN (&Organization)
	|			AND Contracts.Organization.TransactionsUsingParentCompanyAreAllowed)
	|	AND Contracts.ContractType IN (&ContractTypes)
	|
	|	AND &DynamicConditionsContractsOfCounterparties
	|";
	
	QueriesTexts.Add(QueryText);
	
	UseIntercompanyContracts = GetFunctionalOption("UseIntercompanyContracts");
	
	If UseIntercompanyContracts Then
		
		QueryText = "
		|SELECT //First10
		|	Contracts.Ref AS PaymentPurpose,
		|	Contracts.CompanyRecipient AS Counterparty,
		|	Contracts.Ref AS Contract,
		|	Contracts.PaymentID AS PaymentID,
		|	CASE
		|		WHEN Contracts.DeletionMark
		|		THEN 2
		|		ELSE 0
		|	END AS State
		|FROM
		|	Catalog.IntercompanyContracts AS Contracts
		|WHERE
		|	&DynamicConditionsContractsBetweenOrganizations
		|";
		
		QueriesTexts.Add(QueryText);
	EndIf;
	
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());

	ConditionsForRegistryRequest = New Array;
	ConditionsForRegistryRequest.Add("TRUE");
	
	RequestConditionsARAPObject = New Array;
	RequestConditionsARAPObject.Add("TRUE");
	
	TermsOfRequestContractsOfCounterparties = New Array;
	TermsOfRequestContractsOfCounterparties.Add("TRUE");
	
	TermsOfRequestContractsBetweenOrganizations = New Array;
	TermsOfRequestContractsBetweenOrganizations.Add("TRUE");
		
	If ValueIsFilled(FilterStructure1.Counterparty) Then
		
		ConditionsForRegistryRequest.Add("(DocumentsRegistry.Counterparty.Key IN (&Counterparty))");
		
		TermsOfRequestContractsOfCounterparties.Add("(Contracts.Counterparty IN (&Counterparty))");
		
		If ThisIsWhip Then
			RequestConditionsARAPObject.Add("(ARAPObjects.Counterparty IN (&Counterparty))");
		EndIf;
		
		If UseIntercompanyContracts Then
			
			TermsOfRequestContractsBetweenOrganizations.Add(?(TheseAreSettlementsWithClient,
				"Contracts.CompanyRecipient IN (SELECT T.Ref FROM TTSelectionBetweenCompanies AS T)",
				"Contracts.Organization IN (SELECT T.Ref FROM TTSelectionBetweenCompanies AS T)"));
		EndIf;
	EndIf;
		
	If FilterStructure1.TypesOfBases_.Count() > 0 Then
		ConditionsForRegistryRequest.Add("VALUETYPE(DocumentsRegistry.Ref) IN (&TypesOfBases_)");
	EndIf;
	
	If ThisIsWhip Then
		
		ConditionsForRegistryRequest.Add("
		|CASE
		|	WHEN VALUETYPE(DocumentsRegistry.Ref) = TYPE(Document.CustomerCommercialInvoice)
		|	THEN CAST(DocumentsRegistry.Ref AS Document.CustomerCommercialInvoice).PaymentID
		|		IN (&SearchString)
		|	ELSE FALSE
		|END
		|");
		
		TermsOfRequestContractsOfCounterparties.Add("Contracts.PaymentID IN (&SearchString)");
		
		If UseIntercompanyContracts Then
			TermsOfRequestContractsBetweenOrganizations.Add("Contracts.PaymentID IN (&SearchString)");
		EndIf;
		
		RequestConditionsARAPObject.Add(?(TheseAreSettlementsWithClient,
			"(ARAPObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))",
			"(ARAPObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))"));
		
		QueryText = StrReplace(QueryText, "&DynamicConditionsARAPObjects",
			StrConcat(RequestConditionsARAPObject, " And "));
	Else
		ConditionsForRegistryRequest.Add("DocumentsRegistry.IBDocumentNumber IN (&SearchString)");
		TermsOfRequestContractsOfCounterparties.Add("Contracts.Description IN (&SearchString)");
		
		If UseIntercompanyContracts Then
			TermsOfRequestContractsBetweenOrganizations.Add("Contracts.Description IN (&SearchString)");
		EndIf;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DynamicConditionsRegistry", StrConcat(ConditionsForRegistryRequest, " And "));
	QueryText = StrReplace(QueryText, "&DynamicConditionsContractsOfCounterparties", 
		StrConcat(TermsOfRequestContractsOfCounterparties, " And "));
	
	If UseIntercompanyContracts Then
		QueryText = StrReplace(QueryText, "&DynamicConditionsContractsBetweenOrganizations",
			StrConcat(TermsOfRequestContractsBetweenOrganizations, " And "));
	EndIf;
	
	If InputByString Then
		QueryText = StrReplace(QueryText, "//First10", "TOP 10"); //@Query-part-1 @Query-part-2
		QueryText = StrReplace(QueryText, "IN (&SearchString)", "LIKE &SearchString");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns:
// 	String
//
Function QueryTextOfTemporarySelectionDataTables() Export
	
	QueryText = "
		|SELECT ALLOWED DISTINCT
		|	BranchOffices_.Ref AS Ref
		|INTO TTCentralizedContracts
		|FROM
		|	Catalog.CounterpartyContracts.BranchOffices_ AS BranchOffices_
		|WHERE
		|	BranchOffices_.Organization = &Organization
		|	AND &RecordBranches
		|;
		|SELECT ALLOWED
		|	Companies.ParentCompany AS ParentCompany
		|INTO TTParentCompany
		|FROM 
		|	Catalog.Companies AS Companies
		|WHERE 
		|	Companies.Ref = &Organization
		|	AND &RecordBranches
		|;
		|";
	
	Return QueryText;
	
EndFunction

// Returns:
// 	String
//
Function TextOfRequestToSelectSettlementObject(InputByString) Export
	
	QueryText = "
	|SELECT ALLOWED
	|	ARAPObjects.Object                  AS PaymentPurpose,
	|	ARAPObjects.Ref                  AS ARAPObject,
	|	ARAPObjects.Object                  AS Object,
	|	ARAPObjects.Partner                 AS Partner,
	|	ARAPObjects.Organization             AS Organization,
	|	ARAPObjects.Counterparty              AS Counterparty,
	|	ARAPObjects.Contract                 AS Contract,
	|	ARAPObjects.LineOfBusiness AS LineOfBusiness,
	|	ARAPObjects.ARAPCurrency    AS ARAPCurrency,
	|	ARAPObjects.PaymentID    AS PaymentID,
	|	ARAPObjects.Number                   AS Number,
	|	ARAPObjects.Date                    AS Date,
	|	ARAPObjects.IncomingDocumentDate  AS IncomingDocumentDate,
	|	ARAPObjects.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	ARAPObjects.Sum                   AS OrderAmount,
	|	0                                       AS PaymentAmount,
	|	ARAPObjects.Currency                  AS Currency,
	|	ARAPObjects.State               AS State,
	|	ARAPObjects.DeletionMark         AS DeletionMark,
	|	ISNULL(Contracts.CentralizedContract, FALSE) AS CentralizedContract, 
	|	ISNULL(Contracts.ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers, FALSE) AS FeeViaEndCustomers,
	|	ISNULL(Contracts.ItIsAllowedToWorkWithSubsidiaryPartners, FALSE) AS ItIsAllowedToWorkWithSubsidiaryPartners,
	|	ARAPObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS TheseAreSettlementsWithCustomers
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON ARAPObjects.Contract = Contracts.Ref
	|WHERE &DynamicConditions
	|	AND NOT ARAPObjects.DeletionMark
	|";
	
	If InputByString Then
		QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT ALLOWED TOP 10"); //@Query-part-1 @Query-part-2
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the parameters used when you select a document in the accounts receivable.
// It is used in the General form of "payment document Selection" and in the processing of receiving data for selecting the payment basis.
// 
// Returns: 
// Structure :
//	* InputByString - Boolean - Indicates whether the selection data is received.
//	* ThisIsWhip - Boolean - The search for the settlement document is carried out by the UIP.
//	* SelectionByOrganizationAndCounterparty - Boolean - There is a selection by organization and counterparty.
//	* ExcludeEditedDocument - Boolean - Do not include the document from which the selection is called in the selection data.
//	* ProhibitContractsBasedOnDocuments - Boolean - Prohibit contracts with the order of settlements "on orders/invoice".
//
Function SelectionParametersWhenSelectingCustomerSettlementDocument() Export 
	
	FilterParameters = New Structure;
	FilterParameters.Insert("InputByString",                   False);
	FilterParameters.Insert("ThisIsWhip",                         False);
	FilterParameters.Insert("SelectionByOrganizationAndCounterparty", False);
	FilterParameters.Insert("ExcludeEditedDocument", False);
	FilterParameters.Insert("ProhibitContractsBasedOnDocuments",  False);
	
	Return FilterParameters;
	
EndFunction

// the structure of the selected value.
// 
// Returns:
// Structure: 
// 	* PaymentPurpose - Document Link, Undefined
// 	* ARAPObject - CatalogRef.ARAPObjects
// 	* DocumentBasis - Document Link, Undefined
// 	* Partner - CatalogRef.Partners
// 	* Counterparty - CatalogRef.Counterparties
// 	* PaymentID - String
// 	* ARAPCurrency - CatalogRef.Currencies
// 	* TheseAreSettlementsWithCustomers - Boolean
// 	* PaymentAmount - Number
// 	* OrderAmount - Number
// 	* Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts, Undefined - Contract of the selected document
// 	* Organization - CatalogRef.Companies
// 	* MaturityDate - Date
// 	* PaymentDate - Date
// 	* Date - Date
// 	* CentralizedContract - Boolean
// 	* FeeViaEndCustomers - Boolean
// 	* ItIsAllowedToWorkWithSubsidiaryPartners - Boolean
// 	* Object - DefinedType.ARAPObject
// 	* LineOfBusiness - CatalogRef.LinesOfBusiness
// 	* AmountARAP - Number
// 	* VATRate - CatalogRef.VATRates
// 	* VATAmount - Number
//  
Function StructureOfSelectionValue()
	
	SelectionValue = New Structure;
	
	SelectionValue.Insert("PaymentPurpose", Undefined);
	SelectionValue.Insert("ARAPObject", Catalogs.ARAPObjects.EmptyRef());
	SelectionValue.Insert("DocumentBasis", Undefined);
	SelectionValue.Insert("Partner", Catalogs.Partners.EmptyRef());
	SelectionValue.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	SelectionValue.Insert("PaymentID", "");
	SelectionValue.Insert("ARAPCurrency", Catalogs.Currencies.EmptyRef());
	SelectionValue.Insert("TheseAreSettlementsWithCustomers", False);
	SelectionValue.Insert("PaymentAmount", 0);
	SelectionValue.Insert("OrderAmount", 0);
	SelectionValue.Insert("Contract", Undefined);
	SelectionValue.Insert("Organization", Catalogs.Companies.EmptyRef());
	SelectionValue.Insert("MaturityDate", Date(1, 1, 1));
	SelectionValue.Insert("PaymentDate", Date(1, 1, 1));
	SelectionValue.Insert("Date", Date(1, 1, 1));
	SelectionValue.Insert("Number", "");
	SelectionValue.Insert("CentralizedContract", False);
	SelectionValue.Insert("FeeViaEndCustomers", False);
	SelectionValue.Insert("ItIsAllowedToWorkWithSubsidiaryPartners", False);
	SelectionValue.Insert("Object", Undefined);
	SelectionValue.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	SelectionValue.Insert("AmountARAP", 0);
	SelectionValue.Insert("VATRate", PredefinedValue("Catalog.VATRates.EmptyRef"));
	SelectionValue.Insert("VATAmount", 0);
	
	Return SelectionValue;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions_

// Returns:
// 	String - Warning text
Function TextOfWarningOfAssignmentOfDistributionOfMutualSettlements() Export
	
	ReasonText =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đang có nhiệm vụ phân bổ hoãn lại các khoản hạch toán công nợ (biểu ghi %1)';
						|ru = 'Имеются невыполненные задания отложенного распределения взаиморасчетов (регистр %1)';
						|en = 'There are unexecuted jobs of deferred AR/AP distribution (the %1 register)'; fa = 'There are unexecuted jobs of deferred AR/AP distribution (the %1 register)';
						|it = 'There are unexecuted jobs of deferred AR/AP distribution (the %1 register)';
						|pl = 'There are unexecuted jobs of deferred AR/AP distribution (the %1 register)';
						|tr = 'Ertelenmiş karşılıklı mutabakat dağıtımı için bekleyen görevler bulunmaktadır (kayıt tablosu %1)'", Common.DefaultLanguageCode()),
					Metadata.InformationRegisters.JobsForARAPAllocating.Synonym);
	
	Return ReasonText;
	
EndFunction

Function RequestTextForBalancesWithSuppliers(ByPaymentDates)
	
	QueryText = "
		|SELECT
		|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
		|	FALSE                                    AS Selected,
		|	0                                       AS Sum,
		|	DATETIME(1, 1, 1)                      AS MaturityDate,
		|	&DocumentCurrency                        AS DocumentCurrency,
		|	ARAPObjects.Date                    AS Date,
		|	ARAPObjects.Number                   AS Number,
		|	ARAPObjects.Ref                  AS ARAPObject,
		|	ARAPObjects.PaymentID    AS PaymentID,
		|	CalculationData.ARAPCurrency    AS ARAPCurrency,
		|	CalculationData.Organization              AS Organization,
		|	CalculationData.Partner                  AS Partner,
		|	ARAPObjects.Counterparty              AS Counterparty,
		|	ARAPObjects.Contract                 AS Contract,
		|	ARAPObjects.Object                  AS Object,
		|	ARAPObjects.LineOfBusiness AS LineOfBusiness,
		|	ARAPObjects.Department           AS Department,
		|	ISNULL(ISNULL(CounterpartyContracts.ContractRateOption, IntercompanyContracts.ContractRateOption), VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
		|	CASE
		|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|			THEN CASE
		|					WHEN ISNULL(ARAPObjects.Terms.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|						THEN &CashFlowItem
		|					ELSE ARAPObjects.Terms.CashFlowItem
		|				END
		|		ELSE ARAPObjects.Contract.CashFlowItem
		|	END                                   AS CashFlowItem,
		|	ISNULL(ARAPObjects.Contract.PaymentsAsPer275FZ, FALSE) AS PaymentsAsPer275FZ,
		|	SUM(CalculationData.PartnerDebt_)      AS PartnerDebt_,
		|	SUM(CalculationData.AmountDue)           AS AmountDue,
		|	0                                       AS BeingPaid,
		|	SUM(CalculationData.AccountsPayableOfCompany)           AS AccountsPayableOfCompany,
		|	&PaymentDate                            AS PaymentDate,
		|	ARAPObjects.OperationWithSelfEmployedPerson    AS OperationWithSelfEmployedPerson
		|FROM
		|	(SELECT
		|		VendorsARAPAccounting.ARAPObject                        AS ARAPObject,
		|		VendorsARAPAccounting.Currency                                AS ARAPCurrency,
		|		VendorsARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
		|		VendorsARAPAccounting.AccountingDimensionByPartners.Partner     AS Partner,
		|		VendorsARAPAccounting.PrepaymentBalance                     AS PartnerDebt_,
		|		VendorsARAPAccounting.AmountDue                               AS AmountDue,
		|		0                                                          AS BeingPaid,
		|		VendorsARAPAccounting.DebtBalance                           AS AccountsPayableOfCompany,
		|		VendorsARAPAccounting.PlannedRepaymentDate                AS PaymentDate
		|	FROM
		|		VendorsARAPAccountingByDueDatesBalance AS VendorsARAPAccounting
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VendorsARAPAccounting.ARAPObject                        AS ARAPObject,
		|		VendorsARAPAccounting.Currency                                AS ARAPCurrency,
		|		VendorsARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
		|		VendorsARAPAccounting.AccountingDimensionByPartners.Partner     AS Partner,
		|		0                                                          AS PartnerDebt_,
		|		VendorsARAPAccounting.AmountDueBalance                        AS AmountDue,
		|		0                                                          AS BeingPaid,
		|		0                                                          AS AccountsPayableOfCompany,
		|		VendorsARAPAccounting.PlannedRepaymentDate                AS PaymentDate
		|	FROM
		|		VendorsARAPAccountingCashFlowPlanBalance AS VendorsARAPAccounting
		|		) AS CalculationData
		| 			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|				LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|				ON ARAPObjects.Contract = CounterpartyContracts.Ref
		|				LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|				ON ARAPObjects.Contract = IntercompanyContracts.Ref
		|			ON CalculationData.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	NOT ARAPObjects.Object REFS Catalog.GiftCertificates
		|
		|GROUP BY
		|	ARAPObjects.Date,
		|	ARAPObjects.Number,
		|	ARAPObjects.Ref,
		|	ARAPObjects.PaymentID,
		|	CalculationData.ARAPCurrency,
		|	CalculationData.Organization,
		|	CalculationData.Partner,
		|	ARAPObjects.Counterparty,
		|	ARAPObjects.Contract,
		|	ARAPObjects.Object,
		|	ARAPObjects.LineOfBusiness,
		|	ARAPObjects.Department,
		|	CalculationData.PaymentDate,
		|	ISNULL(ISNULL(CounterpartyContracts.ContractRateOption, IntercompanyContracts.ContractRateOption), VALUE(Enum.ContractRateOptions.Mutable)),
		|	CASE
		|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|			THEN CASE
		|					WHEN ISNULL(ARAPObjects.Terms.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|						THEN &CashFlowItem
		|					ELSE ARAPObjects.Terms.CashFlowItem
		|				END
		|		ELSE ARAPObjects.Contract.CashFlowItem
		|	END,
		|	ISNULL(ARAPObjects.Contract.PaymentsAsPer275FZ, FALSE),
		|	ARAPObjects.OperationWithSelfEmployedPerson
		|
		|ORDER BY
		|	Organization,
		|	Counterparty,
		|	&PaymentDate,
		|	Date,
		|	Number
		|;
		|
		|SELECT
		|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
		|	VendorsARAPAccounting.Currency AS ARAPCurrency,
		|	VendorsARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
		|	VendorsARAPAccounting.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|	VendorsARAPAccounting.AccountingDimensionByPartners.Partner AS Partner,
		|	-VendorsARAPAccounting.BeingPaidBalance AS Sum
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(
		|			,
		|			NOT &AccountsReceivable
		|			AND NOT &OnlyUnconditionalDebt
		|			AND NOT &SelectionOfPaymentByRequest
		|			AND ARAPObject IN
		|				(SELECT
		|					ARAPObjects.ARAPObject
		|				FROM
		|					ARAPObjects AS ARAPObjects)) AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.BeingPaidBalance < 0
		|";
	
	QueryText = StrReplace(QueryText, "CalculationData.PaymentDate,", ?(ByPaymentDates, "CalculationData.PaymentDate,", ""));
	QueryText = StrReplace(QueryText, "&PaymentDate", ?(ByPaymentDates, "CalculationData.PaymentDate", "MIN(CalculationData.PaymentDate)"));
	
	Return QueryText;
	
EndFunction

Function RequestTextForBalancesWithCustomers(ByPaymentDates)
	
	QueryText = "
		|SELECT
		|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
		|	FALSE                                    AS Selected,
		|	0                                       AS Sum,
		|	DATETIME(1, 1, 1)                      AS MaturityDate,
		|	&DocumentCurrency                        AS DocumentCurrency,
		|	ARAPObjects.Date                    AS Date,
		|	ARAPObjects.Number                   AS Number,
		|	ARAPObjects.Ref                  AS ARAPObject,
		|	ARAPObjects.PaymentID    AS PaymentID,
		|	ARAPObjects.ARAPCurrency    AS ARAPCurrency,
		|	CalculationData.Organization              AS Organization,
		|	CalculationData.Partner                  AS Partner,
		|	ARAPObjects.Counterparty              AS Counterparty,
		|	ARAPObjects.Contract                 AS Contract,
		|	ARAPObjects.Object                  AS Object,
		|	ARAPObjects.LineOfBusiness AS LineOfBusiness,
		|	ARAPObjects.Department           AS Department,
		|	ISNULL(ISNULL(CounterpartyContracts.ContractRateOption, IntercompanyContracts.ContractRateOption), VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
		|	CASE
		|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|			THEN CASE
		|					WHEN ISNULL(ARAPObjects.Terms.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|						THEN &CashFlowItem
		|					ELSE ARAPObjects.Terms.CashFlowItem
		|				END
		|		ELSE ARAPObjects.Contract.CashFlowItem
		|	END                                   AS CashFlowItem,
		|	SUM(CalculationData.PartnerDebt_)      AS PartnerDebt_,
		|	SUM(CalculationData.AmountDue)           AS AmountDue,
		|	0                                       AS BeingPaid,
		|	SUM(CalculationData.AccountsPayableOfCompany)           AS AccountsPayableOfCompany,
		|	&PaymentDate                            AS PaymentDate,
		|	ARAPObjects.OperationWithSelfEmployedPerson    AS OperationWithSelfEmployedPerson
		|FROM
		|	(SELECT
		|		CustomersARAPAccounting.ARAPObject                        AS ARAPObject,
		|		CustomersARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
		|		CustomersARAPAccounting.AccountingDimensionByPartners.Partner     AS Partner,
		|		CustomersARAPAccounting.DebtBalance                           AS PartnerDebt_,
		|		CustomersARAPAccounting.AmountDue                               AS AmountDue,
		|		0                                                       AS BeingPaid,
		|		CustomersARAPAccounting.PrepaymentBalance                     AS AccountsPayableOfCompany,
		|		CustomersARAPAccounting.PlannedRepaymentDate                AS PaymentDate
		|	FROM
		|		CustomersARAPAccountingByDueDatesBalance AS CustomersARAPAccounting
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccounting.ARAPObject                        AS ARAPObject,
		|		CustomersARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
		|		CustomersARAPAccounting.AccountingDimensionByPartners.Partner     AS Partner,
		|		0                                                       AS PartnerDebt_,
		|		CustomersARAPAccounting.AmountDueBalance                        AS AmountDue,
		|		0                                                       AS BeingPaid,
		|		0                                                       AS AccountsPayableOfCompany,
		|		CustomersARAPAccounting.PlannedRepaymentDate                AS PaymentDate
		|	FROM
		|		CustomersARAPAccountingCashFlowPlanBalance AS CustomersARAPAccounting
		|		) AS CalculationData
		| 			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|				LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|				ON ARAPObjects.Contract = CounterpartyContracts.Ref
		|				LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|				ON ARAPObjects.Contract = IntercompanyContracts.Ref
		|			ON CalculationData.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	NOT ARAPObjects.Object REFS Catalog.GiftCertificates
		|
		|GROUP BY
		|	ARAPObjects.Date,
		|	ARAPObjects.Number,
		|	ARAPObjects.Ref,
		|	ARAPObjects.PaymentID,
		|	ARAPObjects.ARAPCurrency,
		|	CalculationData.Organization,
		|	CalculationData.Partner,
		|	ARAPObjects.Counterparty,
		|	ARAPObjects.Contract,
		|	ARAPObjects.Object,
		|	ARAPObjects.LineOfBusiness,
		|	ARAPObjects.Department,
		|	CalculationData.PaymentDate,
		|	ISNULL(ISNULL(CounterpartyContracts.ContractRateOption, IntercompanyContracts.ContractRateOption), VALUE(Enum.ContractRateOptions.Mutable)),
		|	CASE
		|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|			THEN CASE
		|					WHEN ISNULL(ARAPObjects.Terms.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
		|						THEN &CashFlowItem
		|					ELSE ARAPObjects.Terms.CashFlowItem
		|				END
		|		ELSE ARAPObjects.Contract.CashFlowItem
		|	END,
		|	ARAPObjects.OperationWithSelfEmployedPerson
		|
		|ORDER BY
		|	Organization,
		|	Counterparty,
		|	&PaymentDate,
		|	Date,
		|	Number
		|;
		|
		|SELECT
		|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
		|	CustomersARAPAccounting.Currency AS ARAPCurrency,
		|	CustomersARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
		|	CustomersARAPAccounting.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|	CustomersARAPAccounting.AccountingDimensionByPartners.Partner AS Partner,
		|	CustomersARAPAccounting.BeingPaidBalance AS Sum
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(
		|			,
		|			&AccountsReceivable
		|			AND NOT &OnlyUnconditionalDebt
		|			AND NOT &SelectionOfPaymentByRequest
		|			AND ARAPObject IN
		|				(SELECT
		|					ARAPObjects.ARAPObject
		|				FROM
		|					ARAPObjects AS ARAPObjects)) AS CustomersARAPAccounting
		|WHERE
		|	CustomersARAPAccounting.BeingPaidBalance > 0
		|";
	
	QueryText = StrReplace(QueryText, "CalculationData.PaymentDate,", ?(ByPaymentDates, "CalculationData.PaymentDate,", ""));
	QueryText = StrReplace(QueryText, "&PaymentDate", ?(ByPaymentDates, "CalculationData.PaymentDate", "MIN(CalculationData.PaymentDate)"));
	
	Return QueryText;
	
EndFunction

// Deprecated.
Function QueryTextForBalancesOfPaymentsWithSuppliersOffline()
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	CASE WHEN PaymentTable_3.Sum IS NULL THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS Selected,
	|	ISNULL(PaymentTable_3.Sum, 0) AS Sum,
	|	ISNULL(PaymentTable_3.MaturityDate, DATETIME(1, 1, 1)) AS MaturityDate,
	|	CASE WHEN &DocumentCurrency <> VALUE(Catalog.Currencies.EmptyRef)
	|		THEN &DocumentCurrency
	|		ELSE ARAPObjects.ARAPCurrency
	|	END AS DocumentCurrency,
	|
	|	ARAPObjects.Date AS Date,
	|	ARAPObjects.Number AS Number,
	|	ARAPObjects.Ref AS ARAPObject,
	|	"""" AS PaymentID,
	|	VendorsARAPAccounting.Currency AS ARAPCurrency,
	|	VendorsARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
	|	VendorsARAPAccounting.AccountingDimensionByPartners.Partner AS Partner,
	|	ARAPObjects.Counterparty AS Counterparty,
	|	ARAPObjects.Contract AS Contract,
	|	ARAPObjects.Object AS Object,
	|	ARAPObjects.LineOfBusiness AS LineOfBusiness,
	|	ARAPObjects.Department AS Department,
	|	ISNULL(
	|		ISNULL(
	|			CounterpartyContracts.ContractRateOption, 
	|			IntercompanyContracts.ContractRateOption), 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
	|
	|	CASE
	|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, 
	|			VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|		THEN
	|			CASE
	|				WHEN ISNULL(ARAPObjects.Terms.CashFlowItem,
	|					VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|					THEN &CashFlowItem
	|				ELSE ARAPObjects.Terms.CashFlowItem
	|			END
	|		ELSE ARAPObjects.Contract.CashFlowItem
	|	END AS CashFlowItem,
	|
	|	ISNULL(ARAPObjects.Contract.PaymentsAsPer275FZ, FALSE) AS PaymentsAsPer275FZ,
	|	
	|	CASE WHEN VendorsARAPAccounting.SumBalance > 0 THEN
	|		VendorsARAPAccounting.SumBalance
	|	ELSE
	|		0
	|	END AS PartnerDebt_,
	|
	|	CASE WHEN VendorsARAPAccounting.BeingPaidBalance - VendorsARAPAccounting.AmountDueBalance > 0
	|		AND NOT &OnlyUnconditionalDebt
	|	THEN
	|		VendorsARAPAccounting.BeingPaidBalance - VendorsARAPAccounting.AmountDueBalance
	|	ELSE
	|		0
	|	END AS AmountDue,
	|
	|	0 AS BeingPaid,
	|
	|	CASE WHEN VendorsARAPAccounting.SumBalance < 0 THEN
	|		-VendorsARAPAccounting.SumBalance
	|	ELSE
	|		0
	|	END AS AccountsPayableOfCompany,
	|
	|	ARAPObjects.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson
	|
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(, 
	|		ARAPObject IN (
	|			SELECT
	|				ARAPObjects.ARAPObject
	|			FROM
	|				ARAPObjects AS ARAPObjects)
	|	) AS VendorsARAPAccounting
	|		
	|	INNER JOIN 
	|		Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON ARAPObjects.Contract = CounterpartyContracts.Ref
	|		LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
	|		ON ARAPObjects.Contract = IntercompanyContracts.Ref
	|	ON 
	|		VendorsARAPAccounting.ARAPObject = ARAPObjects.Ref
	|
	|	LEFT JOIN
	|		PaymentTable_3 AS PaymentTable_3
	|	ON
	|		VendorsARAPAccounting.ARAPObject = PaymentTable_3.ARAPObject
	|		AND (VendorsARAPAccounting.AccountingDimensionByPartners.Partner = PaymentTable_3.Partner
	|			OR PaymentTable_3.Partner = VALUE(Catalog.Partners.EmptyRef))
	|		AND VendorsARAPAccounting.Currency = PaymentTable_3.Currency
	|
	|WHERE
	|	(&AccountsReceivable
	|	AND VendorsARAPAccounting.SumBalance > 0)
	|	OR 
	|	(NOT &AccountsReceivable
	|	AND VendorsARAPAccounting.BeingPaidBalance - VendorsARAPAccounting.AmountDueBalance > 0
	|	AND NOT &OnlyUnconditionalDebt
	|	)
	|	OR 
	|	(NOT &AccountsReceivable
	|	AND VendorsARAPAccounting.BeingPaidBalance - VendorsARAPAccounting.SumBalance > 0
	|	)
	|ORDER BY
	|	Organization,
	|	Counterparty,
	|	Date,
	|	Number
	|";
	
	Return QueryText;
	
EndFunction

// Deprecated.
Function QueryTextForBalancesOfPaymentsWithCustomersOffline()
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	CASE WHEN PaymentTable_3.Sum IS NULL THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS Selected,
	|	ISNULL(PaymentTable_3.Sum, 0) AS Sum,
	|	ISNULL(PaymentTable_3.MaturityDate, DATETIME(1, 1, 1)) AS MaturityDate,
	|	CASE WHEN &DocumentCurrency <> VALUE(Catalog.Currencies.EmptyRef)
	|		THEN &DocumentCurrency
	|		ELSE ARAPObjects.ARAPCurrency
	|	END AS DocumentCurrency,
	|
	|	ARAPObjects.Date AS Date,
	|	ARAPObjects.Number AS Number,
	|	ARAPObjects.Ref AS ARAPObject,
	|	ARAPObjects.PaymentID AS PaymentID,
	|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
	|	CustomersARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
	|	CustomersARAPAccounting.AccountingDimensionByPartners.Partner AS Partner,
	|	ARAPObjects.Counterparty AS Counterparty,
	|	ARAPObjects.Contract AS Contract,
	|	ARAPObjects.Object AS Object,
	|	ARAPObjects.LineOfBusiness AS LineOfBusiness,
	|	ARAPObjects.Department AS Department,
	|	ISNULL(
	|		ISNULL(
	|			CounterpartyContracts.ContractRateOption, 
	|			IntercompanyContracts.ContractRateOption), 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
	|	
	|	CASE
	|		WHEN ISNULL(ARAPObjects.Contract.CashFlowItem, 
	|			VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|		THEN
	|			CASE
	|				WHEN ISNULL(ARAPObjects.Terms.CashFlowItem,
	|					VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|					THEN &CashFlowItem
	|				ELSE ARAPObjects.Terms.CashFlowItem
	|			END
	|		ELSE ARAPObjects.Contract.CashFlowItem
	|	END AS CashFlowItem,
	|
	|	CASE WHEN CustomersARAPAccounting.SumBalance > 0 THEN
	|		CustomersARAPAccounting.SumBalance
	|	ELSE
	|		0
	|	END AS PartnerDebt_,
	|	
	|	CASE WHEN CustomersARAPAccounting.AmountDueBalance - CustomersARAPAccounting.BeingPaidBalance > 0
	|		AND NOT &OnlyUnconditionalDebt
	|	THEN
	|		CustomersARAPAccounting.AmountDueBalance - CustomersARAPAccounting.BeingPaidBalance
	|	ELSE
	|		0
	|	END AS AmountDue,
	|	
	|	0 AS BeingPaid,
	|
	|	CASE WHEN CustomersARAPAccounting.SumBalance < 0 THEN
	|		-CustomersARAPAccounting.SumBalance
	|	ELSE
	|		0
	|	END AS AccountsPayableOfCompany,
	|
	|	ARAPObjects.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson
	|
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, 
	|		ARAPObject IN (
	|			SELECT
	|				ARAPObjects.ARAPObject
	|			FROM
	|				ARAPObjects AS ARAPObjects)
	|	) AS CustomersARAPAccounting
	|		
	|	INNER JOIN 
	|		Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON ARAPObjects.Contract = CounterpartyContracts.Ref
	|		LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
	|		ON ARAPObjects.Contract = IntercompanyContracts.Ref
	|	ON 
	|		CustomersARAPAccounting.ARAPObject = ARAPObjects.Ref
	|		
	|	LEFT JOIN
	|		PaymentTable_3 AS PaymentTable_3
	|	ON
	|		CustomersARAPAccounting.ARAPObject = PaymentTable_3.ARAPObject
	|		AND (CustomersARAPAccounting.AccountingDimensionByPartners.Partner = PaymentTable_3.Partner
	|			OR PaymentTable_3.Partner = VALUE(Catalog.Partners.EmptyRef))
	|		AND CustomersARAPAccounting.Currency = PaymentTable_3.Currency
	|
	|WHERE
	|	NOT (ARAPObjects.Object REFS Catalog.GiftCertificates)
	|	AND ((NOT &AccountsReceivable
	|		AND CustomersARAPAccounting.SumBalance < 0)
	|		OR 
	|		(&AccountsReceivable
	|		AND CustomersARAPAccounting.AmountDueBalance - CustomersARAPAccounting.BeingPaidBalance > 0
	|		AND NOT &OnlyUnconditionalDebt
	|		)
	|		OR 
	|		(&AccountsReceivable
	|		AND CustomersARAPAccounting.SumBalance > 0
	|		))
	|ORDER BY
	|	Organization,
	|	Counterparty,
	|	Date,
	|	Number
	|";
	
	Return QueryText;
	
EndFunction

// The procedure fills in the balance table of payments with the partner.
//
// Parameters:
//	Attributes - Structure:
//	 * Date - Date
//	 * Organization - CatalogRef.Companies
//	 * DocumentAmount - Number
//	 * Currency - CatalogRef.Currencies
//	 * Counterparty - CatalogRef.Counterparties
//	 * Partner - CatalogRef.Partners
//	 * BusinessOperation - EnumRef.BusinessTransactions
//	 * PartnerOtherRelations - Boolean
//	 * RecordBranches - Boolean
//	 * SelectAccountsReceivable - Boolean
//	 * SelectOnlyUnconditionalDebt - Boolean
//	 * SelectionOfPaymentByRequest - Boolean
//	 * PaymentType_ - EnumRef.PartnersARAPAccountingTypes
//	 * ByPaymentDates - Boolean
//	AddressOfPaymentsInTheStorage - String - Address in the temporary storage where the table part of the document is placed.
//	PaymentBalanceTable - ValueTable - A table with Balances of calculations.
//	AdditionalFilters - Map of KeyAndValue:
//	 * Key - String - field name
//	 * Value - Arbitrary - the value of the selection.
//
Procedure FillInTableOfSettlementBalances(Attributes, AddressOfPaymentsInTheStorage, PaymentBalanceTable, AdditionalFilters = Undefined) Export
	
	Query = New Query;
	Query.SetParameter("DocumentCurrency", Attributes.Currency);
	Query.SetParameter("Period", ?(Attributes.Date <> '00010101',Attributes.Date, CurrentSessionDate()));
	
	RecordBranches = ?(Attributes.Property("RecordBranches"), Attributes.RecordBranches, True);
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	If RecordBranches And TypeOf(Attributes.Organization) <> Type("Array") Then
		ParentCompany = Common.ObjectAttributeValue(Attributes.Organization,"ParentCompany");
		If ParentCompany = Attributes.Organization Then
			ParentCompany = Undefined;
			ThisIsParentOrganization = True;
		Else
			ThisIsParentOrganization = False;
		EndIf;
	Else
		ThisIsParentOrganization = False;
		ParentCompany = Undefined;
	EndIf;
	
	Query.SetParameter("AccountsReceivable", Attributes.SelectAccountsReceivable);
	Query.SetParameter("OnlyUnconditionalDebt", Attributes.SelectOnlyUnconditionalDebt);
	Query.SetParameter("SelectionOfPaymentByRequest", Attributes.SelectionOfPaymentByRequest);
	
	If Attributes.Property("BusinessOperation") Then
		CashFlowItem =
			Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
			Attributes.BusinessOperation);
	Else
		CashFlowItem = Catalogs.CashFlowReportItems.EmptyRef();
	EndIf;
	Query.SetParameter("CashFlowItem", CashFlowItem);
	
	RequestARAPObjects = New Query;
	RequestARAPObjects.TempTablesManager = New TempTablesManager;
	
	RequestARAPObjects.SetParameter("Organization", Attributes.Organization);
	RequestARAPObjects.SetParameter("ThisIsParentOrganization", ThisIsParentOrganization);
	RequestARAPObjects.SetParameter("ParentCompany", ParentCompany);
	RequestARAPObjects.SetParameter("ForAllCounterparties", Not ValueIsFilled(Attributes.Counterparty));
	RequestARAPObjects.SetParameter("Counterparty", Attributes.Counterparty);
	RequestARAPObjects.SetParameter("ForAllPartners", Not ValueIsFilled(Attributes.Partner));
	RequestARAPObjects.SetParameter("Partner", Attributes.Partner);
	RequestARAPObjects.SetParameter("PartnerOtherRelations", Attributes.PartnerOtherRelations);
	
	RequestARAPObjects.Text = QueryTextOfARAPObjects();
	
	SetPrivilegedMode(True);
	
	RequestARAPObjects.Execute();
	TempTablesManager = RequestARAPObjects.TempTablesManager;
	
	QueryText = "
	|SELECT
	|	ARAPDetails.ARAPObject AS ARAPObject,
	|	ARAPDetails.Partner AS Partner,
	|	ARAPDetails.ARAPCurrency AS Currency,
	|	ARAPDetails.MaturityDate AS MaturityDate,
	|	ARAPDetails.Sum AS Sum
	|
	|INTO PaymentTable_3
	|FROM
	|	&ARAPDetails AS ARAPDetails
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	ARAPObjects.ARAPObject                                   AS ARAPObject,
	|	DocumentCurrenciesAndRates.RateARAPCurrencyNumerator         AS RateARAPCurrencyNumerator,
	|	DocumentCurrenciesAndRates.RateARAPCurrencyDenominator       AS RateARAPCurrencyDenominator,
	|	DocumentCurrenciesAndRates.RateManagementAccountingCurrencyNumerator   AS RateManagementAccountingCurrencyNumerator,
	|	DocumentCurrenciesAndRates.RateManagementAccountingCurrencyDenominator AS RateManagementAccountingCurrencyDenominator,
	|	DocumentCurrenciesAndRates.RateDocumentCurrencyNumerator              AS RateDocumentCurrencyNumerator,
	|	DocumentCurrenciesAndRates.RateDocumentCurrencyDenominator            AS RateDocumentCurrencyDenominator,
	|	DocumentCurrenciesAndRates.DocumentCurrency                           AS DocumentCurrency,
	|	DocumentCurrenciesAndRates.ARAPCurrency                      AS ARAPCurrency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator               AS CourseNumeratorVariable,
	|	RelativeExchangeRatesSliceLast.CourseDenominator             AS CourseDenominatorIsVariable
	|FROM
	|	ARAPObjects AS ARAPObjects
	|		INNER JOIN InformationRegister.DocumentCurrenciesAndRates AS DocumentCurrenciesAndRates
	|		ON ARAPObjects.Object = DocumentCurrenciesAndRates.Document,
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			Currency = &DocumentCurrency
	|				AND BaseCurrency IN
	|					(SELECT
	|						T.LocalAccountingCurrency
	|					FROM
	|						ARAPObjects AS T)) AS RelativeExchangeRatesSliceLast
	|
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|
	|SELECT &QueryTextCalculations
	|
	|";
	ByPaymentDates = False;
	If Attributes.Property("ByPaymentDates") Then
		ByPaymentDates = Attributes.ByPaymentDates;
	EndIf;
	
	If Attributes.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
		
		If NewOnlineARAPAccounting Then
			
			RequestingBalances = New Query;
			RequestingBalances.TempTablesManager = TempTablesManager;
			RequestingBalances.Text = QueryTextBalancesOnCustomerSettlementRegisters();
			
			If CommonClientServer.HasAttributeOrObjectProperty(Attributes, "AsOfDateOfOccurrence") Then
				
				RequestingBalances.Text = StrReplace(
					RequestingBalances.Text,
					"&ExcludeByDateOfOccurrence",
					"CustomersARAPAccountingByDueDates.OccurrenceDate > &OccurrenceDate");
				RequestingBalances.Text = StrReplace(
					RequestingBalances.Text,
					"&SelectionByDateOfOccurrence",
					"OccurrenceDate <= &OccurrenceDate");
				RequestingBalances.SetParameter("OccurrenceDate", Attributes.AsOfDateOfOccurrence);
				
			Else
				
				RequestingBalances.Text = StrReplace(
					RequestingBalances.Text,
					"&ExcludeByDateOfOccurrence",
					"CustomersARAPAccountingByDueDates.OccurrenceDate = Undefined");
				RequestingBalances.Text = StrReplace(RequestingBalances.Text, "AND &SelectionByDateOfOccurrence", "");
				
			EndIf;
			
			RequestingBalances.SetParameter("AccountsReceivable", Attributes.SelectAccountsReceivable);
			RequestingBalances.SetParameter("OnlyUnconditionalDebt", Attributes.SelectOnlyUnconditionalDebt);
			RequestingBalances.SetParameter("SelectionOfPaymentByRequest", Attributes.SelectionOfPaymentByRequest);
			
			RequestingBalances.Execute();
			TempTablesManager = RequestingBalances.TempTablesManager;
			
			QueryText = StrReplace(
				QueryText,
				"SELECT &QueryTextCalculations",
				RequestTextForBalancesWithCustomers(ByPaymentDates));
			
		Else
			QueryText = StrReplace(
				QueryText,
				"SELECT &QueryTextCalculations",
				QueryTextForBalancesOfPaymentsWithCustomersOffline());
		EndIf;
		
	Else
		
		If NewOnlineARAPAccounting Then
			
			RequestingBalances = New Query;
			RequestingBalances.TempTablesManager = TempTablesManager;
			RequestingBalances.Text = QueryTextBalancesOnRegistersOfSettlementsWithSuppliers();
			
			If CommonClientServer.HasAttributeOrObjectProperty(Attributes, "AsOfDateOfOccurrence") Then
				
				RequestingBalances.Text = StrReplace(
					RequestingBalances.Text,
					"&ExcludeByDateOfOccurrence",
					"VendorsARAPAccountingByDueDates.OccurrenceDate > &OccurrenceDate");
				RequestingBalances.Text = StrReplace(
					RequestingBalances.Text,
					"&SelectionByDateOfOccurrence",
					"OccurrenceDate <= &OccurrenceDate");
				RequestingBalances.SetParameter("OccurrenceDate", Attributes.AsOfDateOfOccurrence);
				
			Else
				
				RequestingBalances.Text = StrReplace(
					RequestingBalances.Text,
					"&ExcludeByDateOfOccurrence",
					"VendorsARAPAccountingByDueDates.OccurrenceDate = Undefined");
				RequestingBalances.Text = StrReplace(RequestingBalances.Text, "AND &SelectionByDateOfOccurrence", "");
				
			EndIf;
			
			RequestingBalances.SetParameter("AccountsReceivable", Attributes.SelectAccountsReceivable);
			RequestingBalances.SetParameter("OnlyUnconditionalDebt", Attributes.SelectOnlyUnconditionalDebt);
			RequestingBalances.SetParameter("SelectionOfPaymentByRequest", Attributes.SelectionOfPaymentByRequest);
			
			RequestingBalances.Execute();
			TempTablesManager = RequestingBalances.TempTablesManager;
			
			QueryText = StrReplace(
				QueryText,
				"SELECT &QueryTextCalculations",
				RequestTextForBalancesWithSuppliers(ByPaymentDates));
			
		Else
			QueryText = StrReplace(
				QueryText,
				"SELECT &QueryTextCalculations",
				QueryTextForBalancesOfPaymentsWithSuppliersOffline());
		EndIf;
		
	EndIf;
	
	
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	
	If ValueIsFilled(AddressOfPaymentsInTheStorage) Then
		ARAPDetails = GetFromTempStorage(AddressOfPaymentsInTheStorage);
		If ARAPDetails.Columns.Find("Partner") = Undefined Then
			ARAPDetails.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
			ARAPDetails.FillValues(Attributes.Partner, "Partner");
			If ARAPDetails.Columns.Find("Vendor") <> Undefined Then
				For Each TableRow In ARAPDetails Do
					TableRow.Partner = TableRow.Vendor;
				EndDo;
			EndIf;
		EndIf;
		If ARAPDetails.Columns.Find("MaturityDate") = Undefined Then
			ARAPDetails.Columns.Add("MaturityDate", New TypeDescription("Date"));
		EndIf;
		If ARAPDetails.Columns.Find("AmountARAP") = Undefined Then
			ARAPDetails.Columns.Add("AmountARAP", New TypeDescription("Number"));
			For Each TableRow In ARAPDetails Do
				TableRow.AmountARAP = TableRow.Sum;
			EndDo;
		EndIf;
	Else
		If PaymentBalanceTable = Undefined Then
			ARAPDetails = New ValueTable;
			ARAPDetails.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
			ARAPDetails.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
			ARAPDetails.Columns.Add("ARAPCurrency", New TypeDescription("CatalogRef.Currencies"));
			ARAPDetails.Columns.Add("MaturityDate", New TypeDescription("Date"));
			ARAPDetails.Columns.Add("Sum", New TypeDescription("Number"));
			ARAPDetails.Columns.Add("AmountARAP", New TypeDescription("Number"));
		Else
			ARAPDetails = PaymentBalanceTable.Unload(,).CopyColumns();
		EndIf;
	EndIf;
	ARAPDetails.GroupBy("ARAPObject, Partner, ARAPCurrency, MaturityDate", "Sum, AmountARAP");
	
	If ARAPDetails.Count() = 1 And Not ValueIsFilled(ARAPDetails[0].ARAPObject) Then
		ARAPDetails.Clear();
	EndIf;
	
	Query.SetParameter("ARAPDetails", ARAPDetails);
	
	If AdditionalFilters <> Undefined Then
		
		RequestSchemeForBalances = New QuerySchema;
		RequestSchemeForBalances.SetQueryText(Query.Text);
		Operator = RequestSchemeForBalances.QueryBatch[2].Operators[0];
		
		Cnt = 0;
		For Each KeyAndValue In AdditionalFilters Do
			If TypeOf(KeyAndValue.Value) = Type("Array") Then
				Filter = StrTemplate("ISNULL(ARAPObjects.%1, UNDEFINED) IN (&Parameter%2)", KeyAndValue.Key, String(Cnt));
			Else
				Filter = "ISNULL(ARAPObjects."+KeyAndValue.Key+", UNDEFINED) = &Parameter"+String(Cnt);
			EndIf;
			Query.SetParameter("Parameter"+String(Cnt), KeyAndValue.Value);
			Operator.Filter.Add(Filter);
			Cnt= Cnt + 1;
		EndDo;
		
		Query.Text = RequestSchemeForBalances.GetQueryText();
		
	EndIf;
	
	QueryResult = Query.ExecuteBatch();
	TableOfBalancesOfCalculationsIsPreliminary = QueryResult[2].Unload();
	
	If NewOnlineARAPAccounting Then
		TableOfBalancesOfCalculationsIsPreliminary.Indexes.Add("ARAPObject, Partner, ARAPCurrency");
		FilterStructure1 = New Structure("ARAPObject, Partner, ARAPCurrency");
		If Not Attributes.SelectOnlyUnconditionalDebt
			And Not Attributes.SelectionOfPaymentByRequest Then
			// The Distribution Is Paid. Since Payment is recorded in settlement movements without specifying the 
			// payment data Attribute, this cannot be done in the request 
			BalancesArePaid = QueryResult[3].Unload();
			For Each BalanceIsPaid In BalancesArePaid Do
				FillPropertyValues(FilterStructure1, BalanceIsPaid);
				RemainderLines_ = TMCommonUse.FindRowsWithPreservingOrder(TableOfBalancesOfCalculationsIsPreliminary, FilterStructure1);
				For Each RemainderLine In RemainderLines_ Do
					If BalanceIsPaid.Sum <= 0 Then
						Break;
					Else
						AmountAllocated = Min(BalanceIsPaid.Sum, RemainderLine.AmountDue);
						RemainderLine.BeingPaid = AmountAllocated;
						BalanceIsPaid.Sum = BalanceIsPaid.Sum - AmountAllocated;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		// Note the Settlement objects that are already in the decryption of the payment. 
		// Since there is no data payment field in the decryption, this cannot be done in the request
		For Each DecryptionString In ARAPDetails Do
			FillPropertyValues(FilterStructure1, DecryptionString);
			RemainderLines_ = TMCommonUse.FindRowsWithPreservingOrder(TableOfBalancesOfCalculationsIsPreliminary, FilterStructure1);
			BalanceOfSettlementAmount = DecryptionString.AmountARAP;
			If BalanceOfSettlementAmount = 0 Then
				If DecryptionString.ARAPCurrency = Attributes.Currency Then
					BalanceOfSettlementAmount = DecryptionString.Sum;
				Else
					BalanceOfSettlementAmount = ProcessingOfExchangeRatesTM.ConvertToCurrency(
						DecryptionString.Sum,
						Catalogs.Currencies.EmptyRef(),
						Attributes.Currency,
						DecryptionString.ARAPCurrency,
						Attributes.Date,
						DecryptionString.ARAPObject);
				EndIf;
			EndIf;
			SettlementsAmounts = New Array;
			For Each RemainderLine In RemainderLines_ Do
				CurrentSettlementAmount = 0;
				If RemainderLine.PartnerDebt_ <> 0 And Attributes.SelectAccountsReceivable Then
					CurrentSettlementAmount = Min(RemainderLine.PartnerDebt_, RemainderLine.AmountDue - RemainderLine.BeingPaid, BalanceOfSettlementAmount);
					SettlementsAmounts.Add(CurrentSettlementAmount);
				ElsIf RemainderLine.AccountsPayableOfCompany <> 0  And Not Attributes.SelectAccountsReceivable Then
					CurrentSettlementAmount = Min(RemainderLine.AccountsPayableOfCompany,RemainderLine.AmountDue - RemainderLine.BeingPaid, BalanceOfSettlementAmount);
					SettlementsAmounts.Add(CurrentSettlementAmount);
				ElsIf RemainderLine.AmountDue <> 0 Then
					CurrentSettlementAmount = Min(RemainderLine.AmountDue - RemainderLine.BeingPaid, BalanceOfSettlementAmount);
					SettlementsAmounts.Add(CurrentSettlementAmount);
				EndIf;
				BalanceOfSettlementAmount = BalanceOfSettlementAmount - CurrentSettlementAmount;
			EndDo;
			DistributedAmount = TMCommonUseClientServer.DistributeProportionally(DecryptionString.Sum, SettlementsAmounts);
			If DistributedAmount <> Undefined Then
				For Counter = 0 To RemainderLines_.Count() - 1 Do
					RemainderLines_[Counter].Sum = DistributedAmount[Counter];
					If DistributedAmount[Counter] > 0 Then
						RemainderLines_[Counter].MaturityDate = DecryptionString.MaturityDate;
						RemainderLines_[Counter].Selected = True;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	If PaymentBalanceTable = Undefined Then
		PaymentBalanceTable = TableOfBalancesOfCalculationsIsPreliminary;
	Else
		PaymentBalanceTable.Load(TableOfBalancesOfCalculationsIsPreliminary);
	EndIf;
	
	If ARAPDetails.Count() = 0 Then
		AmountForAllocation = Attributes.DocumentAmount;
	Else
		AmountForAllocation = 0;
	EndIf;
	
	CorrespondenceOfExchangeRates = New Map;
	
	FixedCourseSelection = QueryResult[1].Select();
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	While FixedCourseSelection.Next() Do
		If Attributes.Currency = FixedCourseSelection.ARAPCurrency Then
			ConversionFactor_ = 1;
		ElsIf Attributes.Currency = FixedCourseSelection.DocumentCurrency Then
			ConversionFactor_ = FixedCourseSelection.RateARAPCurrencyNumerator * FixedCourseSelection.RateDocumentCurrencyDenominator 
			                       / (FixedCourseSelection.RateARAPCurrencyDenominator * FixedCourseSelection.RateDocumentCurrencyNumerator)
		ElsIf Attributes.Currency = ManagementAccountingCurrency Then
			ConversionFactor_ = FixedCourseSelection.RateARAPCurrencyNumerator * FixedCourseSelection.RateManagementAccountingCurrencyDenominator 
			                       / (FixedCourseSelection.RateARAPCurrencyDenominator * FixedCourseSelection.RateManagementAccountingCurrencyNumerator)
		Else
			ConversionFactor_ = FixedCourseSelection.RateARAPCurrencyNumerator * FixedCourseSelection.CourseDenominatorIsVariable 
			                       / (FixedCourseSelection.RateARAPCurrencyDenominator * FixedCourseSelection.CourseNumeratorVariable)
		EndIf;
		CorrespondenceOfExchangeRates.Insert(FixedCourseSelection.ARAPObject, ConversionFactor_);
	EndDo;
	
	For Each TableRow In PaymentBalanceTable Do
		
		If Not TableRow.Selected Then
				
			If TableRow.PartnerDebt_ <> 0 And Attributes.SelectAccountsReceivable Then
				If Attributes.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
					TableRow.Sum = Min(TableRow.PartnerDebt_, TableRow.AmountDue - TableRow.BeingPaid);
				Else
					TableRow.Sum = TableRow.PartnerDebt_;
				EndIf;
			ElsIf TableRow.AccountsPayableOfCompany <> 0  And Not Attributes.SelectAccountsReceivable Then
				If Attributes.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
					TableRow.Sum = TableRow.AccountsPayableOfCompany;
				Else
					TableRow.Sum = Min(TableRow.AccountsPayableOfCompany,TableRow.AmountDue - TableRow.BeingPaid);
				EndIf;
			ElsIf TableRow.AmountDue <> 0 Then
				TableRow.Sum = TableRow.AmountDue - TableRow.BeingPaid;
			EndIf;
			
			If ValueIsFilled(Attributes.Currency) And Attributes.Currency <> TableRow.ARAPCurrency Then
				
				If TableRow.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
					ZoomRatio = CorrespondenceOfExchangeRates.Get(TableRow.Contract);
				ElsIf TableRow.ContractRateOption = Enums.ContractRateOptions.FixedAsOfShipmentDate Then
					ZoomRatio = CorrespondenceOfExchangeRates.Get(TableRow.ARAPObject);
				Else
					ZoomRatio = CorrespondenceOfExchangeRates.Get(TableRow.ARAPCurrency);
				EndIf;
				If ZoomRatio = Undefined Then
					CourseParameters = ProcessingOfExchangeRatesTM.ParametersOfContractCourseOption();
					FillPropertyValues(CourseParameters, TableRow);
					ZoomRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
					              	TableRow.ARAPCurrency,
					              	Attributes.Currency,
					              	?(Attributes.Date <> '00010101',Attributes.Date, CurrentSessionDate()),
					              	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(TableRow.Organization),
					              	CourseParameters);
					If TableRow.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
						CorrespondenceOfExchangeRates.Insert(TableRow.Contract, ZoomRatio);
					ElsIf TableRow.ContractRateOption = Enums.ContractRateOptions.FixedAsOfShipmentDate Then
						CorrespondenceOfExchangeRates.Insert(TableRow.ARAPObject, ZoomRatio);
					Else
						CorrespondenceOfExchangeRates.Insert(TableRow.ARAPCurrency, ZoomRatio);
					EndIf;
				EndIf;
				
				TableRow.Sum = TableRow.Sum * ZoomRatio;
				
			EndIf;
			
		EndIf;
		
		If AmountForAllocation > 0 
			And TableRow.Sum - TableRow.BeingPaid > 0 Then
			
			TableRow.Selected = True;
			If TableRow.BeingPaid > 0 Then
				TableRow.Sum = TableRow.Sum - TableRow.BeingPaid;
			EndIf;
			If TableRow.Sum > AmountForAllocation Then
				TableRow.Sum = AmountForAllocation;
			EndIf;
			AmountForAllocation = AmountForAllocation - TableRow.Sum;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deprecated. The function generates an array of acceptable business transactions of the contract with the counterparty.
//
// Parameters:
//	DocumentOperation_ - EnumRef.BusinessTransactions - business operation of the document.
//
// Returns:
//	Array of EnumRef.BusinessTransactions - Array of business operations.
//
Function ContractBusinessTransaction(DocumentOperation_) Export
	
	ContractBusinessTransaction = New Array;
	If DocumentOperation_ = Enums.BusinessTransactions.CashReceiptFromCustomer
	 Or DocumentOperation_ = Enums.BusinessTransactions.RefundToCustomer Then
		
		ContractBusinessTransaction.Add(Enums.BusinessTransactions.SaleToCustomer);
		ContractBusinessTransaction.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		
	ElsIf DocumentOperation_ = Enums.BusinessTransactions.PaymentToVendor
	 Or DocumentOperation_ = Enums.BusinessTransactions.RefundFromVendor Then
		
		ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseByImport);
		ContractBusinessTransaction.Add(Enums.BusinessTransactions.ImportFromEAEU);
		ContractBusinessTransaction.Add(Enums.BusinessTransactions.ConsignmentProcurement);
		
	EndIf;
	
	Return ContractBusinessTransaction;
	
EndFunction

// Deprecated. Fills in the fields:
//	Operation Order - used to search for Registered Records before and after the document being modified, to sort documents for offsetting payments and invoices.
//	The offsetting procedure of the payment date is used to search for Registered Records before and after the document being modified when offsetting documents by payment date.
// Parameters:
//  TableCalculations - ValueTable - the table of Registered Records according to the register of calculations with mandatory columns:
//   * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners,
//   * Period - Date,
//   * RecorderDate - Date,
//   * RecorderNumber - String,
//   * Kind - Number
//  DocumentType - Type - Type of registrar's document
//  ProceduresForOffsettingPaymentsOfInvoicesContracts - Map of KeyAndValue -Where:
// 		* Key - CatalogRef.CounterpartyContracts,CatalogRef.IntercompanyContracts - the calculation object for which the data was received.
// 		* Value - EnumRef.OffsetOrdersOfPaymentsAndInvoices
Procedure AddFillInOrderOfOperation(TableCalculations, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts = Undefined) Export
	
	ARAPAccountingPosting.AddFillInOrderOfOperation(TableCalculations, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts);
	
EndProcedure

// Deprecated.
Function TestRequestDistributionOfSettlementsWithCustomers()
	
	QueryText = "
	|SELECT DISTINCT
	|	Table.Month AS Month,
	|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
	|	Table.ARAPObject               AS ARAPObject,
	|	CASE WHEN &NewCalculations
	|		THEN UNDEFINED
	|		ELSE Table.Document
	|	END								 AS Document,
	|	Table.Organization AS Organization,
	|	VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation) AS Operation
	|FROM SettlementsWithCustomersChanges AS Table
	|WHERE
	|	Table.Sum <> 0 OR Table.SumCompl <> 0 OR Table.SumMan <> 0
	|";
	Return QueryText
EndFunction

// Deprecated.
Function TestRequestDistributionOfSettlementsWithSuppliers()
	
	QueryText = "
	|SELECT DISTINCT
	|	Table.Month AS Month,
	|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
	|	Table.ARAPObject               AS ARAPObject,
	|	CASE WHEN &NewCalculations
	|		THEN UNDEFINED
	|		ELSE Table.Document
	|	END								 AS Document,
	|	Table.Organization AS Organization,
	|	VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation) AS Operation
	|FROM VendorsARAPAccountingChanges AS Table
	|WHERE
	|	Table.Sum <> 0 OR Table.SumCompl <> 0 OR Table.SumMan <> 0
	|";
	Return QueryText
EndFunction

// Deprecated.
Procedure CheckAndFillOutPartnerAccountingAnalytics(RegisterRecordTable) Export
	
	ARAPAccountingPosting.CheckAndFillOutPartnerAccountingAnalytics(RegisterRecordTable);
	
EndProcedure

Procedure DisplayUpdateWarning(Template) Export
	
	If Not InfobaseUpdate.DeferredUpdateCompleted() Then
		
		WarningTable_ = New SpreadsheetDocument;
		AreaWarning = WarningTable_.Area(1,1,1,1);
		
		WarningText = NStr("vi = 'Chưa hoàn thành cập nhật hoãn lại cơ sở thông tin, dữ liệu trong báo cáo có thể không chính xác.';
							|ru = 'Не завершено отложенное обновление информационной базы, данные в отчетах могут быть некорректными.';
							|en = 'Deferred update of the infobase is not completed, report data might be incorrect.'; fa = 'Deferred update of the infobase is not completed, report data might be incorrect.';
							|it = 'L''aggiornamento differito dell''infobase non è stato completato, i dati nei report potrebbero non essere corretti.';
							|pl = 'Nie zakończono odroczonej aktualizacji bazy informacyjnej, dane w raportach mogą być niepoprawne.';
							|tr = 'Infobase''in ertelenen güncellemesi tamamlanmadı, raporlardaki veriler yanlış olabilir.'");
		AreaWarning.Text = WarningText;
		AreaWarning.TextColor = StyleColors.NegativeTextColor;
		
		Template.InsertArea(WarningTable_.Area(1,1,1,1), Template.Area(1,1,1,1), SpreadsheetDocumentShiftType.Vertical);
		
	EndIf;
	
EndProcedure

Procedure DisplayWarningAboutEndOfOfflinePaymentSupport(Template) Export
	
	If Constants.NewOnlineARAPAccounting.Get() Then
		Return;
	EndIf;
	
	WarningTable_ = New SpreadsheetDocument;
	AreaWarning = WarningTable_.Area(1,1,1,1);
	
	RowsArray = New Array;
	If Not Users.IsFullUser() Then
		WarningText = NStr("ru = 'Внимание! Данный отчет больше не поддерживается и может содержать ошибки.
		|Необходимо выполнить переход на режим учета взаиморасчетов «онлайн». Обратитесь к администратору системы.';
		|vi = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode. Please contact the system administrator.';
		|en = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode. Please contact the system administrator.'; fa = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode. Please contact the system administrator.';
		|it = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode. Please contact the system administrator.';
		|pl = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode. Please contact the system administrator.';
		|tr = 'Dikkat! Bu rapor artık desteklenmiyor ve hatalar içerebilir. 
		|  Karşılıklı hesaplaşmaların muhasebeleştirilmesinde ""online"" moduna geçiş yapılması gerekir. Sistem yöneticisine başvurun.'");
	Else
		WarningText = NStr("ru = 'Внимание! Данный отчет больше не поддерживается и может содержать ошибки. 
		|Необходимо выполнить переход на режим учета взаиморасчетов «онлайн».';
		|vi = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode.';
		|en = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode.'; fa = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode.';
		|it = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode.';
		|pl = 'Important. This report is no longer supported and may contain errors.
		|Switch to the online accounting mode.';
		|tr = 'Dikkat! Bu rapor artık desteklenmiyor ve hatalar içerebilir.  
		|Alacak/borç muhasebesinde ""online"" moduna geçiş yapılması gerekir.'");
	EndIf;
	RowsArray.Add(WarningText);
	
	RowsArray.Add(Chars.LF);
	RowsArray.Add(NStr("ru = 'Подробнее можно ознакомиться';
						|vi = 'For more information, see';
						|en = 'For more information, see'; fa = 'For more information, see';
						|it = 'For more information, see';
						|pl = 'For more information, see';
						|tr = 'Daha fazla bilgi almak için tıklayın'") + " ");
	RowsArray.Add(New FormattedString("here",,,,"https://its.1c.ru/lector/21056822"));
	RowsArray.Add(".");
	
	AreaWarning.Text = New FormattedString(RowsArray);
	AreaWarning.TextColor = StyleColors.NegativeTextColor;
	Template.InsertArea(WarningTable_.Area(1,1,1,1), Template.Area(1,1,1,1), SpreadsheetDocumentShiftType.Vertical);
	
EndProcedure

// Compliance of settlement objects and the exchange rate with the currency of the Contract.
// 
// Parameters:
//  ARAPObjects - Array of CatalogRef.ARAPObjects - Calculation objects for obtaining data.
// 
// Returns:
// 	Map of KeyAndValue - Contains the texts of the cancellation requests, where:
// 		* Key - CatalogRef.ARAPObjects - the calculation object for which the data was received.
// 		* Value - Structure:
//      ** ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements of this settlement object
//      ** ContractRateOption - EnumRef.ContractRateOptions - a variant of the Contract course for determining the source of the course
//      ** ARAPObjectType - EnumRef.ARAPObjectTypes - type of settlement object 
//
Function ComplianceOfARAPObjectsAndParametersOfContract(ARAPObjects) Export 
	
	Result = New Map;
	
	Query = New Query;
	Query.SetParameter("ARAPObjects", ARAPObjects);
	Query.Text = 
	"SELECT
	|	ARAPObjects.Ref AS ARAPObject,
	|	ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
	|	ISNULL(CounterpartyContracts.ItIsAllowedToWorkWithSubsidiaryPartners, FALSE) AS ItIsAllowedToWorkWithSubsidiaryPartners,
	|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
	|	ARAPObjects.Object AS Object,
	|	ARAPObjects.ARAPObjectType AS ARAPObjectType
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON ARAPObjects.Contract = CounterpartyContracts.Ref
	|WHERE
	|	ARAPObjects.Ref IN(&ARAPObjects)";
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	While Selection.Next() Do
		StructureOfCurrencyExchangeRateOption = New Structure("ARAPCurrency, ContractRateOption, ARAPObjectType");
		StructureOfCurrencyExchangeRateOption.Insert("ItIsAllowedToWorkWithSubsidiaryPartners");
		StructureOfCurrencyExchangeRateOption.Insert("Object");
		FillPropertyValues(StructureOfCurrencyExchangeRateOption, Selection);
		Result[Selection.ARAPObject] = StructureOfCurrencyExchangeRateOption;
	EndDo;
	If ARAPObjects.Find(Catalogs.ARAPObjects.EmptyRef()) <> Undefined Then
		StructureOfCurrencyExchangeRateOption = New Structure(
			"ARAPCurrency, ContractRateOption, ARAPObjectType, Object, ItIsAllowedToWorkWithSubsidiaryPartners",
			Catalogs.Currencies.EmptyRef(),
			Enums.ContractRateOptions.Mutable,
			Enums.ARAPObjectTypes.EmptyRef(),
			Undefined,
			False);
		Result[Catalogs.ARAPObjects.EmptyRef()] = StructureOfCurrencyExchangeRateOption;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure RecordExchangeRatesAndCurrenciesOfDocument(Object, ParametersArray, Cancel)
	
	If Cancel Then 
		Return;
	EndIf;
	
	For Each ParametersStructure In ParametersArray Do
		If ParametersStructure.ThisIsSalePurchase And ParametersStructure.ContractRateOption = Enums.ContractRateOptions.FixedAsOfShipmentDate Then
			
			Organization = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
			LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
			
			CurrenciesForRequestingExchangeRates = New Array;
			
			DateOfCourse = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
			If ValueIsFilled(ParametersStructure.DocumentExchangeRateDate) 
				And ValueIsFilled(TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentExchangeRateDate)) Then
				DateOfCourse = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentExchangeRateDate);
			ElsIf ParametersStructure.ThereIsDateOfTransferOfOwnership
				And ValueIsFilled(TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfTransferOfTitleToGoods)) Then
				DateOfCourse = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfTransferOfTitleToGoods);
			EndIf;
			
			SetPrivilegedMode(True);
			RecordManager = InformationRegisters.DocumentCurrenciesAndRates.CreateRecordManager();
			If ParametersStructure.Property("RefToNew") Then
				RecordManager.Document                   = ParametersStructure.RefToNew;
			Else
				RecordManager.Document                   = Object.Ref;
			EndIf;
			RecordManager.ARAPCurrency           = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPCurrency);
			RecordManager.DocumentCurrency                = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentCurrency);
			RecordManager.LocalAccountingCurrency = LocalAccountingCurrency;
			
			If RecordManager.DocumentCurrency = LocalAccountingCurrency Then
				RecordManager.RateARAPCurrencyNumerator = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CourseNumerator);
				RecordManager.RateARAPCurrencyDenominator = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CourseDenominator);
				RecordManager.RateDocumentCurrencyNumerator = 1;
				RecordManager.RateDocumentCurrencyDenominator = 1;
			ElsIf RecordManager.ARAPCurrency = LocalAccountingCurrency Then
				RecordManager.RateARAPCurrencyNumerator = 1;
				RecordManager.RateARAPCurrencyDenominator = 1;
				RecordManager.RateDocumentCurrencyNumerator = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CourseNumerator);
				RecordManager.RateDocumentCurrencyDenominator = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CourseDenominator);
			Else
				CurrenciesForRequestingExchangeRates.Add(RecordManager.DocumentCurrency);
				CurrenciesForRequestingExchangeRates.Add(RecordManager.ARAPCurrency);
			EndIf;
			
			If ManagementAccountingCurrency = RecordManager.DocumentCurrency Then
				RecordManager.RateManagementAccountingCurrencyNumerator = RecordManager.RateDocumentCurrencyNumerator;
				RecordManager.RateManagementAccountingCurrencyDenominator = RecordManager.RateDocumentCurrencyDenominator;
			ElsIf ManagementAccountingCurrency = RecordManager.ARAPCurrency Then
				RecordManager.RateManagementAccountingCurrencyNumerator = RecordManager.RateARAPCurrencyNumerator;
				RecordManager.RateManagementAccountingCurrencyDenominator = RecordManager.RateARAPCurrencyDenominator;
			Else
				CurrenciesForRequestingExchangeRates.Add(ManagementAccountingCurrency);
			EndIf;
			
			Query = New Query;
			Query.SetParameter("ArrayOfCurrencies", CurrenciesForRequestingExchangeRates);
			Query.SetParameter("BaseCurrency", LocalAccountingCurrency);
			Query.SetParameter("Period", DateOfCourse);
			Query.Text = 
				"SELECT
				|	RelativeExchangeRatesSliceLast.Currency AS Currency,
				|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
				|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
				|FROM
				|	InformationRegister.RelativeExchangeRates.SliceLast(
				|			&Period,
				|			BaseCurrency = &BaseCurrency
				|				AND Currency IN (&ArrayOfCurrencies)) AS RelativeExchangeRatesSliceLast";
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				If Selection.Currency = ManagementAccountingCurrency Then
					RecordManager.RateManagementAccountingCurrencyNumerator = Selection.CourseNumerator;
					RecordManager.RateManagementAccountingCurrencyDenominator = Selection.CourseDenominator;
				EndIf;
				If Selection.Currency = RecordManager.ARAPCurrency Then
					RecordManager.RateARAPCurrencyNumerator = Selection.CourseNumerator;
					RecordManager.RateARAPCurrencyDenominator = Selection.CourseDenominator;
				EndIf;
				If Selection.Currency = RecordManager.DocumentCurrency Then
					RecordManager.RateDocumentCurrencyNumerator = Selection.CourseNumerator;
					RecordManager.RateDocumentCurrencyDenominator = Selection.CourseDenominator;
				EndIf;
			EndDo;
			
			RecordManager.Write(True);
			SetPrivilegedMode(False);
			Break;
			
		EndIf;
	EndDo;
	
EndProcedure

// Deprecated. 
// Parameters:
//  Object - CatalogObject.CounterpartyContracts, CatalogObject.IntercompanyContracts - Object to check for filling
Procedure CheckFillInCurrencyExchangeRateOptionOfContract(Object) Export
	If Not ValueIsFilled(Object.ContractRateOption) Then
		Object.ContractRateOption = Enums.ContractRateOptions.Mutable;
	EndIf;
EndProcedure

// Deprecated. finds invoice and order AR/AP objects by reference to the order
// 
// Parameters:
//  ARAPObject - CatalogRef.ARAPObjects - AR/AP object waybill
//  TheseAreSettlementsWithClient - Boolean - In what calculations to look for
// 
// Returns:
//  Array of CatalogRef.ARAPObjects - the found orders AR/AP objects
Function ARAPObjectsOfOrdersByWaybill(ARAPObject, TheseAreSettlementsWithClient) Export
	
	Query = New Query;
	Query.SetParameter("ARAPObject", ARAPObject);
	If TheseAreSettlementsWithClient Then
		Query.Text = 
			"SELECT DISTINCT
			|	ARAPObjects.Ref AS ARAPObjectOrder
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
			|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
			|		ON CustomersARAPAccounting.SaleByOrder = ARAPObjects.Object
			|			AND NOT ARAPObjects.DeletionMark
			|WHERE
			|	CustomersARAPAccounting.ARAPObject IN (&ARAPObject)
			|	AND CustomersARAPAccounting.Active";
	Else
		Query.Text = 
			"SELECT DISTINCT
			|	ARAPObjects.Ref AS ARAPObjectOrder
			|FROM
			|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
			|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
			|		ON VendorsARAPAccounting.PurchaseByOrder = ARAPObjects.Object
			|			AND NOT ARAPObjects.DeletionMark
			|WHERE
			|	VendorsARAPAccounting.ARAPObject IN (&ARAPObject)
			|	AND VendorsARAPAccounting.Active";
	EndIf;
	
	Result = New Array;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If ValueIsFilled(Selection.ARAPObjectOrder) Then
			Result.Add(Selection.ARAPObjectOrder);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// finds AR/AP objects to display in the report on the submitted documents
// 
// Parameters:
//  ReportParameter_ - DocumentRef, Array of DocumentRef - The document from which the contextual report opens
// 
// Returns:
//  Array of CatalogRef.ARAPObjects, CatalogRef.ARAPObjects - Found Calculation Objects
Function GetARAPObjectsForSelectingReport(ReportParameter_) Export
	
	Result = Catalogs.ARAPObjects.EmptyRef();
	
	If TypeOf(ReportParameter_) = Type("Array") Then
		If ReportParameter_.Count() > 0 Then
			TheFirstControl = ReportParameter_[0];
		Else
			Return Result;
		EndIf;
	Else
		TheFirstControl = ReportParameter_;
	EndIf;
	
	MetadataByLink = TheFirstControl.Metadata();
	Manager = Common.ObjectManagerByRef(TheFirstControl);
	SettlementParameters_ = Manager.SettlementParameters_();
	
	If TypeOf(SettlementParameters_) = Type("Array") Then
		ParametersArray = SettlementParameters_;
	Else
		ParametersArray = CommonClientServer.ValueInArray(SettlementParameters_);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", ReportParameter_);
	
	For Each ParametersStructure In ParametersArray Do
		If ValueIsFilled(ParametersStructure.ARAPObject) Then
			
			// We will form a request to receive the object of calculations and the Order of calculations in a temporary table
			PathParts = StrSplit(ParametersStructure.ARAPObject, ".");
			If PathParts.Count() = 2 Then
				QueryTextOfARAPObject = "
					|SELECT
					|	Table.Ref AS Ref,
					|	Table.AttributeName AS ARAPObject,
					|	&ARAPObjectSettings AS ARAPObjectSettings
					|INTO TTIsARAPObject
					|FROM
					|	&Table AS Table
					|WHERE
					|	Table.Ref IN (&Ref)";
				QueryTextOfARAPObject = StrReplace(QueryTextOfARAPObject, "&Table", MetadataByLink.FullName());
				QueryTextOfARAPObject = StrReplace(QueryTextOfARAPObject, "AttributeName", PathParts[1]);
				TSRequest = False;
			Else
				QueryTextOfARAPObject = "
					|SELECT DISTINCT
					|	TabularSection.Ref AS Ref,
					|	TabularSection.AttributeName AS ARAPObject,
					|	&ARAPObjectSettings AS ARAPObjectSettings
					|INTO TTIsARAPObject
					|FROM
					|	&TabularSection AS TabularSection
					|WHERE
					|	TabularSection.Ref IN (&Ref)";
				QueryTextOfARAPObject = StrReplace(QueryTextOfARAPObject, "&TabularSection", MetadataByLink.FullName() + "." + PathParts[1]);
				QueryTextOfARAPObject = StrReplace(QueryTextOfARAPObject, "AttributeName", PathParts[2]);
				TSRequest = True;
			EndIf;
			
			If TypeOf(ParametersStructure.ARAPObjectSettings) = Type("EnumRef.ARAPObjectSettings") Then
				Query.SetParameter("ARAPObjectSettings", ParametersStructure.ARAPObjectSettings);
			Else
				PathParts = StrSplit(ParametersStructure.ARAPObjectSettings, ".");
				PathParts.Delete(0);
				If TSRequest Then
					PathParts.Insert(0, "TabularSection.Ref");
				Else
					PathParts.Insert(0, "Table");
				EndIf;
				QueryTextOfARAPObject = StrReplace(QueryTextOfARAPObject, "&ARAPObjectSettings", StrConcat(PathParts, "."));
			EndIf;
			
			// we get AR/AP objects from the temporary table and add related AR/AP objects depending on the order of calculations
			QueryText = "
				|SELECT
				|	TTIsARAPObject.ARAPObject AS ARAPObject
				|FROM
				|	TTIsARAPObject AS TTIsARAPObject 
				|WHERE
				|	TTIsARAPObject.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
				|";
				
			If ParametersStructure.ThisIsSalePurchase Then
				QueryText = QueryText + TMCommonUse.QuerySeparatorInJoin() + "
					|SELECT
					|	ARAPObjectsContract.Ref
					|FROM
					|	TTIsARAPObject AS TTIsARAPObject
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|			INNER JOIN Catalog.ARAPObjects AS ARAPObjectsContract
					|			ON ARAPObjects.Contract = ARAPObjectsContract.Object
					|				AND NOT ARAPObjects.DeletionMark
					|				AND NOT ARAPObjects.OnlyBalance
					|		ON TTIsARAPObject.ARAPObject = ARAPObjects.Ref
					|WHERE
					|	TTIsARAPObject.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
					|
					|UNION ALL
					|
					|SELECT
					|	ARAPObjects.Ref
					|FROM
					|	TTIsARAPObject AS TTIsARAPObject
					|		INNER JOIN AccumulationRegister.CustomersARAPAccounting AS Calculations
					|			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|			ON (Calculations.SaleByOrder = ARAPObjects.Object)
					|				AND NOT ARAPObjects.DeletionMark
					|				AND NOT ARAPObjects.OnlyBalance
					|		ON (TTIsARAPObject.ARAPObject = Calculations.ARAPObject)
					|WHERE
					|	TTIsARAPObject.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
					|";
			ElsIf ParametersStructure.ThisIsOrder Then
				
				If ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting Then
					
					QueryText = QueryText +
					TMCommonUse.QuerySeparatorInJoin() +
					"SELECT
					|	ARAPObjects.Ref
					|FROM
					|	TTIsARAPObject AS TTIsARAPObject
					|		INNER JOIN AccumulationRegister.PurchaseOrders.Turnovers(,, Recorder, PurchaseOrder IN
					|			(SELECT
					|				T.Ref
					|			FROM
					|				TTIsARAPObject AS T)) AS PurchaseOrdersTurnovers
					|		ON TTIsARAPObject.Ref = PurchaseOrdersTurnovers.PurchaseOrder
					|		AND TTIsARAPObject.Ref <> PurchaseOrdersTurnovers.Recorder
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|		ON PurchaseOrdersTurnovers.Recorder = ARAPObjects.Object
					|			AND NOT ARAPObjects.DeletionMark
					|			AND NOT ARAPObjects.OnlyBalance
					|WHERE
					|	TTIsARAPObject.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice),
					|		VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice), VALUE(Enum.ARAPObjectSettings.ByARAPDocuments))";
					
				Else
					
					TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
					TableFormationParameters.Periodicity = "Recorder";
					TableFormationParameters.ConditionText =
						"ReferenceOrder IN
						|		(SELECT
						|			T.Ref
						|		FROM
						|			TTIsARAPObject AS T)";
					TableFormationParameters.Group = "Recorder, ReferenceOrder";
					TableFormationParameters.Indicators = "Ordered, ToRegister, Issued_1, ToShip, Shipped";
					TableFormationParameters.Resources = "Count";
					TableFormationParameters.Indexes = TableFormationParameters.Group;
					TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
					
					TT_ShipmentOrdersTurnoverExpanded =
						AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
							TableFormationParameters);
					
					QueryText = TT_ShipmentOrdersTurnoverExpanded +
					Common.QueryBatchSeparator() +
					QueryText +
					TMCommonUse.QuerySeparatorInJoin() +
					"SELECT
					|	ARAPObjects.Ref
					|FROM
					|	TTIsARAPObject AS TTIsARAPObject
					|		INNER JOIN TT_ShipmentOrdersTurnoverExpanded AS TurnoversByOrders
					|		ON TTIsARAPObject.Ref = TurnoversByOrders.ReferenceOrder
					|		AND TTIsARAPObject.Ref <> TurnoversByOrders.Recorder
					|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
					|		ON TurnoversByOrders.Recorder = ARAPObjects.Object
					|			AND NOT ARAPObjects.DeletionMark
					|			AND NOT ARAPObjects.OnlyBalance
					|WHERE
					|	TTIsARAPObject.ARAPObjectSettings IN
					|		(VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice),
					|		VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice),
					|		VALUE(Enum.ARAPObjectSettings.ByARAPDocuments))";
					
				EndIf
				
			EndIf;
			
			If ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting Then
				QueryText = StrReplace(QueryText, Metadata.AccumulationRegisters.CustomersARAPAccounting.Name, Metadata.AccumulationRegisters.VendorsARAPAccounting.Name);
				QueryText = StrReplace(QueryText, Metadata.AccumulationRegisters.CustomersARAPAccounting.Attributes.SaleByOrder.Name, Metadata.AccumulationRegisters.VendorsARAPAccounting.Attributes.PurchaseByOrder.Name);
				QueryText = StrReplace(QueryText, Metadata.AccumulationRegisters.ShipmentAndReturnReferences.Dimensions.ReferenceOrder.Name, Metadata.AccumulationRegisters.PurchaseOrders.Dimensions.PurchaseOrder.Name);
				QueryText = StrReplace(QueryText, Metadata.AccumulationRegisters.ShipmentAndReturnReferences.Name, Metadata.AccumulationRegisters.PurchaseOrders.Name);
			EndIf;
			
			Query.Text = QueryTextOfARAPObject + Common.QueryBatchSeparator() + QueryText;
			
			Break;
			
		EndIf;
	EndDo;
	
	If Not IsBlankString(Query.Text) Then
		Result = Query.Execute().Unload().UnloadColumn("ARAPObject");
		Result = CommonClientServer.CollapseArray(Result);
		If Result.Count() = 0 Then
			Result = Catalogs.ARAPObjects.EmptyRef();
		ElsIf Result.Count() = 1 Then
			Result = Result[0];
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  OrderDocument		 - DocumentRef - Link To Order
//  PaymentType_	 - EnumRef.PartnersARAPAccountingTypes - Settlements with the client or supplier
// 
// Returns: 
//  - Undefined - if no record of the State of the order is found
//  - See StructureOfStateOfCalculations
//
Function OrderARAPAccountingState(OrderDocument, PaymentType_)
	
	Query = New Query;
	Query.SetParameter("OrderDocument", OrderDocument);
	If PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
		Query.Text = 
			"SELECT
			|	SalesOrderStates.PayAmount     AS AmountOfPayments,
			|	SalesOrderStates.PayPercentage   AS PercentageOfPayments,
			|	SalesOrderStates.AmountByShipment   AS AmountByShipments,
			|	SalesOrderStates.OrderShipmentPercentage AS PercentageOfShipments,
			|	SalesOrderStates.AmountOfDebt      AS DebtAmount
			|FROM
			|	InformationRegister.SalesOrderStates AS SalesOrderStates
			|WHERE
			|	SalesOrderStates.OrderDocument = &OrderDocument";
	Else
		Query.Text = 
			"SELECT
			|	PurchaseOrderStates.PayAmount        AS AmountOfPayments,
			|	PurchaseOrderStates.PayPercentage      AS PercentageOfPayments,
			|	PurchaseOrderStates.OrderReceiptAmount   AS AmountOfDeliveries,
			|	PurchaseOrderStates.PercentageOfOrderReceipt AS PercentageOfDeliveries,
			|	PurchaseOrderStates.AmountOfDebt         AS DebtAmount
			|FROM
			|	InformationRegister.PurchaseOrderStates AS PurchaseOrderStates
			|WHERE
			|	PurchaseOrderStates.OrderDocument = &OrderDocument";
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = StructureOfStateOfCalculations();
		FillPropertyValues(Result, Selection);
		Return Result;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns:
//   Structure:
//      * AmountOfPayments - Number
//      * PercentageOfPayments - Number
//      * AmountByShipments - Number
//      * PercentageOfShipments - Number
//      * AmountOfDeliveries - Number
//      * PercentageOfDeliveries - Number
//      * DebtAmount - Number
//
Function StructureOfStateOfCalculations()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("AmountOfPayments", 0 );
	StructureOfStateOfCalculations.Insert("PercentageOfPayments", 0 );
	StructureOfStateOfCalculations.Insert("AmountByShipments", 0 );
	StructureOfStateOfCalculations.Insert("PercentageOfShipments", 0 );
	StructureOfStateOfCalculations.Insert("AmountOfDeliveries", 0 );
	StructureOfStateOfCalculations.Insert("PercentageOfDeliveries", 0 );
	StructureOfStateOfCalculations.Insert("DebtAmount", 0 );
	
	Return StructureOfStateOfCalculations;
	
EndFunction

// Deprecated.
Function QueryTextOfARAPObjects()

	Return 
	"SELECT ALLOWED DISTINCT
	|	BranchOffices_.Ref AS Ref
	|INTO CentralizedContracts
	|FROM
	|	Catalog.CounterpartyContracts.BranchOffices_ AS BranchOffices_
	|WHERE
	|	BranchOffices_.Organization = &Organization
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ARAPObjects.Ref AS ARAPObject,
	|	ARAPObjects.Object AS Object,
	|	ARAPObjects.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|INTO ARAPObjects
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	NOT ARAPObjects.DeletionMark
	|	AND NOT ARAPObjects.IsInternal
	|	AND (ARAPObjects.Organization IN (&Organization) 
	|	OR NOT &ThisIsParentOrganization 
	|		AND ARAPObjects.Contract IN (SELECT Ref FROM CentralizedContracts)
	|		AND (ARAPObjects.Organization = &ParentCompany
	|			OR ARAPObjects.Contract.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed)
	|	OR &ThisIsParentOrganization
	|		AND ARAPObjects.Organization.ParentCompany IN (&Organization)
	|		AND ARAPObjects.Organization.TransactionsUsingParentCompanyAreAllowed)
	|	AND (ARAPObjects.Partner = &Partner OR &ForAllPartners)
	|	AND (ARAPObjects.Counterparty = &Counterparty OR &ForAllCounterparties)
	|	AND (&PartnerOtherRelations AND ARAPObjects.Partner.OtherRelations
	|		OR NOT &PartnerOtherRelations)
	|
	|INDEX BY
	|	ARAPObject
	|";

EndFunction

Function QueryTextBalancesOnCustomerSettlementRegisters()

	Return 
	"SELECT DISTINCT
	|	CustomersARAPAccountingByDueDates.DocumentRecorder AS DocumentRecorder
	|INTO ExcludedDocumentsByDateOfOccurrence
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|		INNER JOIN ARAPObjects AS ARAPObjects
	|		ON CustomersARAPAccountingByDueDates.ARAPObject = ARAPObjects.ARAPObject
	|WHERE
	|	CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND &ExcludeByDateOfOccurrence
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomersARAPAccountingCashFlowPlanTurnovers.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingCashFlowPlanTurnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingCashFlowPlanTurnovers.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CustomersARAPAccountingCashFlowPlanTurnovers.AmountDueReceipt AS AmountDueReceipt
	|INTO ScheduledPayment
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Turnovers(
	|			,
	|			,
	|			,
	|			&AccountsReceivable
	|				AND NOT &OnlyUnconditionalDebt
	|				AND ARAPObject IN
	|					(SELECT
	|						ARAPObjects.ARAPObject
	|					FROM
	|						ARAPObjects AS ARAPObjects)
	|				AND &SelectionByDateOfOccurrence) AS CustomersARAPAccountingCashFlowPlanTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomersARAPAccountingCashFlowPlan.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingCashFlowPlan.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingCashFlowPlan.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	SUM(CustomersARAPAccountingCashFlowPlan.AmountDue) AS AmountDueExpense
	|INTO PaymentReceivedAccordingToPaymentPlan
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS CustomersARAPAccountingCashFlowPlan
	|		INNER JOIN ARAPObjects AS ARAPObjects
	|		ON (CustomersARAPAccountingCashFlowPlan.ARAPObject = ARAPObjects.ARAPObject)
	|WHERE
	|	CustomersARAPAccountingCashFlowPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND &AccountsReceivable
	|	AND NOT &OnlyUnconditionalDebt
	|	AND NOT CustomersARAPAccountingCashFlowPlan.DocumentRecorder IN
	|				(SELECT
	|					ExcludedDocumentsByDateOfOccurrence.DocumentRecorder
	|				FROM
	|					ExcludedDocumentsByDateOfOccurrence)
	|
	|GROUP BY
	|	CustomersARAPAccountingCashFlowPlan.AccountingDimensionByPartners,
	|	CustomersARAPAccountingCashFlowPlan.ARAPObject,
	|	CustomersARAPAccountingCashFlowPlan.PlannedRepaymentDate
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduledPayment.ARAPObject AS ARAPObject,
	|	ScheduledPayment.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ScheduledPayment.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	ScheduledPayment.AmountDueReceipt - ISNULL(PaymentReceivedAccordingToPaymentPlan.AmountDueExpense, 0) AS AmountDueBalance
	|INTO CustomersARAPAccountingCashFlowPlanBalance
	|FROM
	|	ScheduledPayment AS ScheduledPayment
	|		LEFT JOIN PaymentReceivedAccordingToPaymentPlan AS PaymentReceivedAccordingToPaymentPlan
	|		ON ScheduledPayment.ARAPObject = PaymentReceivedAccordingToPaymentPlan.ARAPObject
	|			AND ScheduledPayment.AccountingDimensionByPartners = PaymentReceivedAccordingToPaymentPlan.AccountingDimensionByPartners
	|			AND ScheduledPayment.PlannedRepaymentDate = PaymentReceivedAccordingToPaymentPlan.PlannedRepaymentDate
	|WHERE
	|	ScheduledPayment.AmountDueReceipt - ISNULL(PaymentReceivedAccordingToPaymentPlan.AmountDueExpense, 0) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccounting.DebtBalance AS DebtBalance,
	|	CASE
	|		WHEN &OnlyUnconditionalDebt
	|			THEN 0
	|		ELSE CustomersARAPAccounting.DebtBalance
	|	END AS AmountDue,
	|	CustomersARAPAccounting.PrepaymentBalance AS PrepaymentBalance,
	|	CustomersARAPAccounting.PlannedRepaymentDate AS PlannedRepaymentDate
	|INTO CustomersARAPAccountingByDueDatesBalance
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
	|			,
	|			ARAPObject IN
	|					(SELECT
	|						ARAPObjects.ARAPObject
	|					FROM
	|						ARAPObjects AS ARAPObjects)
	|				AND &SelectionByDateOfOccurrence) AS CustomersARAPAccounting
	|WHERE
	|	(NOT &AccountsReceivable
	|				AND CustomersARAPAccounting.PrepaymentBalance > 0
	|			OR &AccountsReceivable
	|				AND CustomersARAPAccounting.DebtBalance > 0)
	|";

EndFunction

Function QueryTextBalancesOnRegistersOfSettlementsWithSuppliers()

	Return 
	"SELECT DISTINCT
	|	VendorsARAPAccountingByDueDates.DocumentRecorder AS DocumentRecorder
	|INTO ExcludedDocumentsByDateOfOccurrence
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN ARAPObjects AS ARAPObjects
	|		ON VendorsARAPAccountingByDueDates.ARAPObject = ARAPObjects.ARAPObject
	|WHERE
	|	VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND &ExcludeByDateOfOccurrence
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorsARAPAccountingCashFlowPlanTurnovers.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingCashFlowPlanTurnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingCashFlowPlanTurnovers.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	VendorsARAPAccountingCashFlowPlanTurnovers.AmountDueReceipt AS AmountDueReceipt,
	|	VendorsARAPAccountingCashFlowPlanTurnovers.Currency AS Currency
	|INTO ScheduledPayment
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Turnovers(
	|			,
	|			,
	|			,
	|			NOT &AccountsReceivable
	|				AND NOT &OnlyUnconditionalDebt
	|				AND ARAPObject IN
	|					(SELECT
	|						ARAPObjects.ARAPObject
	|					FROM
	|						ARAPObjects AS ARAPObjects)
	|				AND &SelectionByDateOfOccurrence) AS VendorsARAPAccountingCashFlowPlanTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorsARAPAccountingCashFlowPlan.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingCashFlowPlan.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingCashFlowPlan.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	VendorsARAPAccountingCashFlowPlan.Currency AS Currency,
	|	SUM(VendorsARAPAccountingCashFlowPlan.AmountDue) AS AmountDueExpense
	|INTO CompletedPaymentAccordingToPaymentPlan
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan AS VendorsARAPAccountingCashFlowPlan
	|		INNER JOIN ARAPObjects AS ARAPObjects
	|		ON (VendorsARAPAccountingCashFlowPlan.ARAPObject = ARAPObjects.ARAPObject)
	|WHERE
	|	VendorsARAPAccountingCashFlowPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND NOT &AccountsReceivable
	|	AND NOT &OnlyUnconditionalDebt
	|	AND NOT VendorsARAPAccountingCashFlowPlan.DocumentRecorder IN
	|				(SELECT
	|					ExcludedDocumentsByDateOfOccurrence.DocumentRecorder
	|				FROM
	|					ExcludedDocumentsByDateOfOccurrence)
	|
	|GROUP BY
	|	VendorsARAPAccountingCashFlowPlan.AccountingDimensionByPartners,
	|	VendorsARAPAccountingCashFlowPlan.ARAPObject,
	|	VendorsARAPAccountingCashFlowPlan.Currency,
	|	VendorsARAPAccountingCashFlowPlan.PlannedRepaymentDate
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduledPayment.ARAPObject AS ARAPObject,
	|	ScheduledPayment.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ScheduledPayment.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	ScheduledPayment.Currency AS Currency,
	|	ScheduledPayment.AmountDueReceipt - ISNULL(CompletedPaymentAccordingToPaymentPlan.AmountDueExpense, 0) AS AmountDueBalance
	|INTO VendorsARAPAccountingCashFlowPlanBalance
	|FROM
	|	ScheduledPayment AS ScheduledPayment
	|		LEFT JOIN CompletedPaymentAccordingToPaymentPlan AS CompletedPaymentAccordingToPaymentPlan
	|		ON ScheduledPayment.ARAPObject = CompletedPaymentAccordingToPaymentPlan.ARAPObject
	|			AND ScheduledPayment.AccountingDimensionByPartners = CompletedPaymentAccordingToPaymentPlan.AccountingDimensionByPartners
	|			AND ScheduledPayment.Currency = CompletedPaymentAccordingToPaymentPlan.Currency
	|			AND ScheduledPayment.PlannedRepaymentDate = CompletedPaymentAccordingToPaymentPlan.PlannedRepaymentDate
	|WHERE
	|	ScheduledPayment.AmountDueReceipt - ISNULL(CompletedPaymentAccordingToPaymentPlan.AmountDueExpense, 0) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccounting.DebtBalance AS DebtBalance,
	|	CASE
	|		WHEN &OnlyUnconditionalDebt
	|			THEN 0
	|		ELSE VendorsARAPAccounting.DebtBalance
	|	END AS AmountDue,
	|	VendorsARAPAccounting.PrepaymentBalance AS PrepaymentBalance,
	|	VendorsARAPAccounting.Currency AS Currency,
	|	VendorsARAPAccounting.PlannedRepaymentDate AS PlannedRepaymentDate
	|INTO VendorsARAPAccountingByDueDatesBalance
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
	|			,
	|			ARAPObject IN
	|					(SELECT
	|						ARAPObjects.ARAPObject
	|					FROM
	|						ARAPObjects AS ARAPObjects)
	|				AND &SelectionByDateOfOccurrence) AS VendorsARAPAccounting
	|WHERE
	|	(&AccountsReceivable
	|				AND VendorsARAPAccounting.PrepaymentBalance > 0
	|			OR NOT &AccountsReceivable
	|				AND VendorsARAPAccounting.DebtBalance > 0)
	|";

EndFunction

#EndRegion

#Region FieldTemplatesForReports

// Deprecated. The field template is shipped to the client.
//
// Returns: 
//  String - template text
//
Function TemplateFieldShippedToClient() Export
	
	Return ARAPAccountingReports.TemplateOfShippedField();
	
EndFunction

// Deprecated. The field template is credited to the client.
//
// Returns: 
//  String - template text
//
Function FieldTemplateCreditedToClient() Export
	
	Return ARAPAccountingReports.TemplateOfCreditedField();
	
EndFunction

// Deprecated. Field template paid for by the client.
//
// Returns: 
//  String - template text
//
Function FieldTemplatePaidByCustomer() Export
	
	Return ARAPAccountingReports.TemplateForPaidField();
	
EndFunction

// Deprecated. The field template is supplied by the supplier.
//
// Returns: 
//  String - template text
//
Function FieldTemplateSuppliedBySupplier() Export
	
	Return ARAPAccountingReports.TemplateOfShippedField();
	
EndFunction

// Deprecated. The field template is credited by the supplier.
//
// Returns: 
//  String - template text
//
Function FieldTemplateCreditedBySupplier() Export
	
	Return ARAPAccountingReports.TemplateOfCreditedField();
	
EndFunction

// Deprecated. Template for the paid to supplier field.
//
// Returns: 
//  String - template text
//
Function TemplateForPaidToSupplierField() Export
	
	Return ARAPAccountingReports.TemplateForPaidField();
	
EndFunction

// Deprecated. Template for the write-off revaluation of debt field.
//
// Returns: 
//  String - template text
//
Function TemplateForWriteOffRevaluationOfDebtField() Export
	
	Return ARAPAccountingReports.TemplateForWriteOffRevaluationField();
	
EndFunction

// Deprecated. 
// Parameters:
// 	QueryText - String -
// 	ReportSettings - DataCompositionSettings - 
// 	CalculatedFields - DataCompositionSchemaCalculatedFields -
// 	TableName - String -
Procedure AddSelectionsOfSelectedFieldsToQuery(QueryText, ReportSettings, CalculatedFields, TableName) Export
	
	ARAPAccountingReports.AddSelectionsOfSelectedFieldsToQuery(QueryText, ReportSettings, CalculatedFields, TableName);
	
EndProcedure

#EndRegion

#Region FormationOfTasksForEndOfMonthServiceTasks

#Region RequestTextsForTasksAtEndOfMonth

// Deprecated. 
// Parameters:
//   Query - Query
//
// Returns:
//   See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function QueryTextCustomersARAPAccounting(Query) Export
	
	Return MonthEndClosingARAPAccounting.QueryTextCustomersARAPAccounting(Query);
	
EndFunction

// Deprecated. 
// Parameters:
//   Query - Query
//
// Returns:
//   See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function QueryTextVendorsARAPAccounting(Query) Export
	
	Return MonthEndClosingARAPAccounting.QueryTextVendorsARAPAccounting(Query);
	
EndFunction

// Deprecated. 
// Parameters:
//   Query - Query
//
// Returns:
//   See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function QueryTextDocumentAmountsInAccountingCurrency(Query) Export
	
	Return MonthEndClosingARAPAccounting.QueryTextDocumentAmountsInAccountingCurrency(Query);
	
EndFunction

// Deprecated. 
// Parameters:
//   Query - Query
//
// Returns:
//   See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function QueryTextVendorsARAPAccountingByDueDates(Query) Export
	
	Return MonthEndClosingARAPAccounting.QueryTextVendorsARAPAccountingByDueDates(Query);
	
EndFunction

#EndRegion

#EndRegion

#Region Modularity

#Region Common

Function ConversionRateAtExchangeRate(LocalAccountingCurrency, Currency, ARAPCurrency, CourseNumerator, CourseDenominator)
		
	If CourseNumerator = 0 Or CourseDenominator = 0 Then
		Return 0;
	ElsIf Currency = ARAPCurrency Then
		Return 1;
	ElsIf Not ARAPCurrency = LocalAccountingCurrency
			And Currency = LocalAccountingCurrency Then
		Return CourseDenominator / CourseNumerator;
	Else
		Return CourseNumerator / CourseDenominator;
	EndIf;
	
EndFunction

// Parameters:
// 	Object - CatalogObject, DocumentObject - LongDesc
// 	ParametersStructure - See ARAPAccountingServer.MechanismParameters
// 	SystemSettings_ - Structure - LongDesc
Procedure CheckAndFillInAmountOfSettlements(Object, ParametersStructure, SystemSettings_) Export
	
	If Not ValueIsFilled(ParametersStructure.AmountARAP)
		Or TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.AmountARAP) = Undefined Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("AmountARAP", 0);
	
	AmountOfSettlementsDetails = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.AmountARAP);
	AmountOfSettlementsByContainerDetails = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.AmountARAPByPackage);
	
	CourseNumerator        = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CourseNumerator);
	CourseDenominator      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CourseDenominator);
	DocumentCurrency      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentCurrency);
	ARAPCurrency = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPCurrency);
	Organization          = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
	ToReturnReusablePackage = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ToReturnReusablePackage,,False);
	PackageDepositIsRequired = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PackageDepositIsRequired,,False);
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	ConversionFactor_ = ConversionRateAtExchangeRate(LocalAccountingCurrency,
																		DocumentCurrency,
																		ARAPCurrency,
																		CourseNumerator,
																		CourseDenominator);
	
	DocumentAmounts = ARAPAccountingInternal.DocumentAmounts(Object, ParametersStructure);
	DocumentAmount = DocumentAmounts.DocumentAmount;
	
	If ValueIsFilled(ParametersStructure.PathToTSData) Then
		
		GoodsTable = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSData).Unload();
		
		If GoodsTable.Count() = 0 Or Not CommonClientServer.HasAttributeOrObjectProperty(GoodsTable[0], "AmountARAP") Then
			AmountARAPByPackage = 0;
			AmountARAP = DocumentAmount;
		Else
			If ToReturnReusablePackage And Not PackageDepositIsRequired Then
				Query = New Query;
				Query.Text = "
				|SELECT
				|	Products AS Products,
				|	AmountARAP AS AmountARAP
				|INTO TTProducts_1
				|FROM &GoodsTable AS GoodsTable
				|;
				|SELECT
				|	*
				|FROM TTProducts_1 AS GoodsTable
				|WHERE
				|	Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
				|";
				Query.SetParameter("GoodsTable",GoodsTable);
				GoodsTable = Query.Execute().Unload();
			EndIf;
			
			If GoodsTable.FindRows(TheStructureOfTheSearch).Count() = 0 Then
				AmountARAPByPackage = Round(DocumentAmounts.PackageDepositValue * ConversionFactor_, 2);
				AmountARAP       = ARAPAccountingClientServer.TotalForSumsOfOneCharacter(GoodsTable, "AmountARAP");
			Else
				
				If ParametersStructure.SourceOfAmountsTabularPart Then
					AmountARAPByPackage   = Round(DocumentAmounts.PackageDepositValue * ConversionFactor_, 2);
				Else
					AmountARAPByPackage = 0;
				EndIf;
					
				AmountARAP         = Round(DocumentAmounts.AmountOfDocumentWithoutCollateral * ConversionFactor_, 2) + AmountARAPByPackage;
			EndIf;
		EndIf;
		
	Else
		
		AmountARAP = Round(DocumentAmount * ConversionFactor_, 2);
		AmountARAPByPackage = 0;
		
	EndIf;
	
	AmountOfSettlementsDetails.Data[AmountOfSettlementsDetails.Name] = AmountARAP;
	
	If ValueIsFilled(ParametersStructure.AmountVATARAP) Then
		Attribute = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.AmountVATARAP);
		VATRate = TMCommonUseClientServer.DataAlongWay(Object, "Object.VATRate");
		Attribute.Data[Attribute.Name] = PriceManagementSystemClientServer.CalculateVATAmount(AmountARAP, VATRate);
	EndIf;
	
	If AmountOfSettlementsByContainerDetails <> Undefined Then
		AmountOfSettlementsByContainerDetails.Data[AmountOfSettlementsByContainerDetails.Name] = AmountARAPByPackage;
	EndIf;
	
	If ParametersStructure.Property("DocumentAmounts") Then
		ParametersStructure.DocumentAmounts.AmountARAP = AmountARAP;
		ParametersStructure.DocumentAmounts.AmountOfSettlementsWithoutCollateral = AmountARAP - AmountARAPByPackage;
		ParametersStructure.DocumentAmounts.AmountARAPByPackage = AmountARAPByPackage;
	EndIf;
	
EndProcedure

Procedure ProcessFill_(Object, ParametersStructure, FillingData, ParameterName, DefaultValue)
	
	If ValueIsFilled(ParametersStructure[ParameterName]) 
		And TypeOf(ParametersStructure[ParameterName]) = Type("String")
		And StrOccurrenceCount(ParametersStructure[ParameterName], ".") = 1 Then
		Attribute = StrSplit(ParametersStructure[ParameterName],".")[1];
		
		DetailsInData = Undefined;
		
		If TypeOf(FillingData) = Type("Structure")
			And FillingData.Property(Attribute) Then
			If Not ValueIsFilled(FillingData[Attribute]) Then
				FillingData[Attribute] = DefaultValue;
			Else
				DetailsInData = FillingData[Attribute];
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(DetailsInData) Then
			CheckFillInBankingDetails(Object, ParametersStructure, ParameterName, DefaultValue);
		Else
			CheckFillInBankingDetails(Object, ParametersStructure, ParameterName, DetailsInData);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckFillInBankingDetails(Object, ParametersStructure, AttributeName, DefaultValue)
	
	If ParametersStructure[AttributeName] = "" 
		Or TypeOf(ParametersStructure[AttributeName]) <> Type("String")
		Or StrOccurrenceCount(ParametersStructure[AttributeName],".") <> 1 Then
		Return;
	EndIf;
	
	Attribute = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure[AttributeName]);
	If Attribute.Data <> Undefined
		And Not ValueIsFilled(Attribute.Data[Attribute.Name]) Then
		Attribute.Data[Attribute.Name] = DefaultValue; 
	EndIf;
	
EndProcedure

// Table of amounts by orders. Should not be called if the parameter structure.Sourcesummtable chast = A lie.
// 
// Parameters:
//  Object - FormDataStructure, DocumentObject - Form or document object.
//  ParametersStructure - See ARAPAccountingServer.MechanismParameters
// 
// Returns:
//  ValueTable:
// 		* OrderDocument - DocumentRef - The order of the line.
// 		* ExceedingOrder - Boolean - Indicates that the line is being shipped over schedule.
// 		* Date - Date - document date.
// 		* ApprovalDate - Date - Approval date (for orders).
// 		* DateOfShipment - Date - Scheduled shipment date.
// 		* PaymentAmount - Number - The amount of payments in the currency of the document.
// 		* PackageDepositValue - Number - The amount of the deposit in the currency of the document.
// 		* AmountARAP - Number - The amount of settlements on the line.
// 		* AmountARAPByPackage - Number - The amount of settlements by container per line.
Function TableOfOrderAmounts(Object, ParametersStructure) Export
	
	TSName = StrSplit(ParametersStructure.PathToTSData, ".")[1];
	OrderingCaps = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
	OrderingCaps = ?(OrderingCaps = Undefined, Documents.SalesOrder.EmptyRef(),OrderingCaps);
	Date = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date,,Date(1,1,1));
	ApprovalDate = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ApprovalDate,,Date(1,1,1));
	
	If TypeOf(Object) = Type("FormDataStructure") Then
		If Object.Property("Ref") And Common.IsReference(TypeOf(Object.Ref)) Then
			Manager = Common.ObjectManagerByRef(
				TMCommonUseClientServer.DataAlongWay(Object, Object.Ref));
		Else
			Manager = DataProcessors.SalesWizard;
		EndIf;
	Else
		Manager = Common.ObjectManagerByFullName(Object.Metadata().FullName());
	EndIf;
	
	AttributesValues = New Structure;
	ValueTable = Object[TSName].Unload();
	AttributesValues.Insert("ValueTable", ValueTable);
	AttributesValues.Insert("Date", Date);
	AttributesValues.Insert("ApprovalDate", ApprovalDate);
	AttributesValues.Insert("ToReturnReusablePackage", TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ToReturnReusablePackage,,False));
	AttributesValues.Insert("PackageDepositIsRequired", TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PackageDepositIsRequired,,False));
	
	AttributesValues.Insert("OrderingCaps", OrderingCaps);
	AttributesValues.Insert("ByOrders", TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.InvoiceForOrders,,False));
	AttributesValues.Insert("ThisIsTransferOfOwnership2_5", ParametersStructure.ThisIsTransferOfOwnership2_5);
	AttributesValues.Insert("Ref", Object.Ref);
	
	Return Manager.OrderAmounts(Object.Ref, AttributesValues); 
		
EndFunction

#EndRegion

#Region AutomaticOffsettingOfAdvancesBetweenSettlementObjects

//It is called from the sales assistant and during the execution of documents.
Procedure FillInPossibleAdvancesInInvoice(Object, ParametersStructure) Export
	
	If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption)
		Or Not ParametersStructure.ChangesCalculations
		Or Not ParametersStructure.ThisIsSalePurchase Then
		Return;
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Object,"AdditionalProperties")
		And Object.AdditionalProperties.Property("PaymentSettlement") Then
		Return;
	EndIf;
	
	ARAPObjectSettings = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings);
	InvoiceForOrders = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.InvoiceForOrders,,False);
	Contract = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
	ARAPDetails = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption);
	TheseAreSettlementsWithCustomers = ParametersStructure.CustomerSettlementDocument;
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	CustomerInvoiceDate = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
	LinkToInvoice = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Ref);
	MaximumAmountOfCredit = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.AmountARAP, , 0)
	                        + TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.AmountARAPByPackage, , 0);
	ARAPObjectInvoice = ARAPObjectsServer.GetCalculationObjectFromLink(
		LinkToInvoice,
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization),
		?(TheseAreSettlementsWithCustomers, Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting, Enums.PartnersARAPAccountingTypes.VendorARAPAccounting));
	
	AdvanceIsCredited = False;
	If InvoiceForOrders And ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice Then
		
		Query = New Query;
		QueriesTexts = New Array;
		
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
			PaymentStagesTable = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentSteps);
			QueriesTexts.Add("
			|SELECT
			|	Table.ExceedingOrder AS ExceedingOrder,
			|	Table.OrderDocument AS OrderDocument,
			|	Table.PaymentOption AS PaymentOption,
			|	Table.AmountARAP + Table.AmountARAPByPackage AS AmountInInvoice
			|INTO TTPaymentMilestones
			|FROM &PaymentStagesTable AS Table
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.ExceedingOrder AS ExceedingOrder,
			|	Goods.OrderDocument AS OrderDocument,
			|	SUM(Goods.AmountInInvoice) AS AmountInInvoice,
			|	SUM(CASE WHEN Goods.PaymentOption IN (&PrepaymentOptions)
			|			THEN Goods.AmountInInvoice
			|			ELSE 0
			|		END) AS RequiredPrepayment
			|INTO TTProducts_1
			|FROM TTPaymentMilestones AS Goods
			|GROUP BY
			|	Goods.ExceedingOrder,
			|	Goods.OrderDocument
			|;");
			Query.SetParameter("PaymentStagesTable", PaymentStagesTable.Unload());
			OrderDocument = PaymentStagesTable.UnloadColumn("OrderDocument");
			BasisObject = OrderDocument;
		Else
			OrderDocument = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
			Sum = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.AmountARAP);
			QueriesTexts.Add("
			|SELECT
			|	FALSE AS ExceedingOrder,
			|	&OrderDocument AS OrderDocument,
			|	&Sum AS AmountInInvoice,
			|	0 AS RequiredPrepayment
			|INTO TTProducts_1
			|;");
			Query.SetParameter("OrderDocument", OrderDocument);
			Query.SetParameter("Sum", Sum);
			BasisObject = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase,,Undefined);
		EndIf;
		
		If TypeOf(BasisObject) <> Type("Array") Then
			BasisObject = CommonClientServer.ValueInArray(BasisObject);
		EndIf;
		
		QueriesTexts.Add("
		|SELECT
		|	Goods.ExceedingOrder AS ExceedingOrder,
		|	SUM(Goods.AmountInInvoice) AS InvoiceAmount,
		|	SUM(Goods.RequiredPrepayment) AS RequiredPrepayment
		|INTO TTInvoiceAmount
		|FROM TTProducts_1 AS Goods
		|GROUP BY
		|	Goods.ExceedingOrder
		|;");
		
		If Not NewOnlineARAPAccounting Then
		QueriesTexts.Add("
		|SELECT
		|	Calculations.ARAPObject        AS ARAPObject,
		|	Calculations.ARAPObject.Object AS Object,
		|	SUM(CASE 
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND &TheseAreSettlementsWithCustomers
		|			OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT &TheseAreSettlementsWithCustomers
		|			THEN Calculations.Sum
		|		ELSE -Calculations.Sum
		|	END)                        AS PrepaymentBalance,
		|	SUM(CASE 
		|		WHEN Calculations.Recorder IN (&ObjectsArray) 
		|			AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND &TheseAreSettlementsWithCustomers
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND NOT &TheseAreSettlementsWithCustomers)
		|				THEN AmountDue
		|			ELSE 0
		|	END)                         AS PaymentPlanForEverything,
		|	SUM(CASE 
		|		WHEN Calculations.Recorder IN (&ObjectsArray)
		|			AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND &TheseAreSettlementsWithCustomers
		|				AND (Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision) 
		|					OR Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment))
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND NOT &TheseAreSettlementsWithCustomers
		|					AND (Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation)
		|						OR Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt))) 
		|					THEN AmountDue
		|			ELSE 0
		|	END)                         AS PrepaymentPlan,
		|	SUM(CASE 
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND &TheseAreSettlementsWithCustomers
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT &TheseAreSettlementsWithCustomers
		|			THEN Calculations.Sum
		|		ELSE 0
		|	END)                         AS TotalPaid,
		|	0                              AS PaymentByInvoice,
		|	ISNULL(TTInvoiceAmount.InvoiceAmount, 0) AS InvoiceAmount,
		|	ISNULL(TTAmountOfInvoiceInExcessOfOrder.InvoiceAmount, 0) AS AmountOfInvoiceInExcessOfOrder
		|INTO TTCalculations
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|		LEFT JOIN TTInvoiceAmount AS TTInvoiceAmount
		|			ON NOT TTInvoiceAmount.ExceedingOrder
		|		LEFT JOIN TTInvoiceAmount AS TTAmountOfInvoiceInExcessOfOrder
		|			ON TTAmountOfInvoiceInExcessOfOrder.ExceedingOrder
		|WHERE
		|	ARAPObject.Object IN (&ObjectsArray)
		|GROUP BY
		|	Calculations.ARAPObject,
		|	TTInvoiceAmount.InvoiceAmount,
		|	TTAmountOfInvoiceInExcessOfOrder.InvoiceAmount
		|HAVING
		|	SUM(CASE 
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND &TheseAreSettlementsWithCustomers
		|			OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT &TheseAreSettlementsWithCustomers
		|			THEN Calculations.Sum
		|		ELSE -Calculations.Sum
		|	END) > 0
		|	AND 
		|	SUM(CASE 
		|		WHEN Calculations.Recorder IN (&ObjectsArray)
		|			AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND &TheseAreSettlementsWithCustomers
		|				AND (Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision) 
		|					OR Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment))
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND NOT &TheseAreSettlementsWithCustomers
		|					AND (Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation)
		|						OR Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt))) 
		|					THEN AmountDue
		|			ELSE 0
		|	END) > 0
		|	AND 
		|	SUM(CASE 
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND &TheseAreSettlementsWithCustomers
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT &TheseAreSettlementsWithCustomers
		|			THEN Calculations.Sum
		|		ELSE 0
		|	END) > 0
		|;");
		Else
			QueriesTexts.Add(QueryTextForPrepaymentBalances(TheseAreSettlementsWithCustomers));
			Query.SetParameter("CustomerInvoiceDate", CustomerInvoiceDate);
			Query.SetParameter("Objects", BasisObject);
			Query.SetParameter("PlanDocuments", BasisObject);
			Query.SetParameter("ReportData", 4);
			Query.SetParameter("LinkToInvoice", LinkToInvoice);
		EndIf;
		
		QueriesTexts.Add("
		|SELECT
		|	CASE 
		|		//The order received more prepayment
		|		WHEN TotalPaid >= PaymentPlanForEverything THEN
		|			CASE
		|				WHEN PrepaymentBalance >= Goods.AmountInInvoice + GoodsInExcessOfOrder.AmountInInvoice
		|					THEN ISNULL(Goods.AmountInInvoice, 0) + ISNULL(GoodsInExcessOfOrder.AmountInInvoice, 0)
		|				WHEN PrepaymentBalance >= Goods.AmountInInvoice
		|					THEN ISNULL(Goods.AmountInInvoice, 0)
		|				ELSE 0
		|			END
		|		//The Balance has the required prepayment for the current invoice
		|		WHEN ISNULL(Goods.RequiredPrepayment, 0) + ISNULL(GoodsInExcessOfOrder.RequiredPrepayment, 0) > 0 AND PrepaymentBalance >= ISNULL(Goods.RequiredPrepayment, 0) + ISNULL(GoodsInExcessOfOrder.RequiredPrepayment, 0)
		|			THEN ISNULL(Goods.RequiredPrepayment, 0) + ISNULL(GoodsInExcessOfOrder.RequiredPrepayment, 0)
		|		WHEN ISNULL(Goods.RequiredPrepayment, 0) > 0 AND PrepaymentBalance >= ISNULL(Goods.RequiredPrepayment, 0)
		|			THEN ISNULL(Goods.RequiredPrepayment, 0)
		|		//If the required prepayment is not completed, we will calculate the prepayment amount for scheduled payments
		|		WHEN PrepaymentBalance >= CAST((ISNULL(Goods.AmountInInvoice, 0) + ISNULL(GoodsInExcessOfOrder.AmountInInvoice, 0)) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|			THEN CAST((ISNULL(Goods.AmountInInvoice, 0) + ISNULL(GoodsInExcessOfOrder.AmountInInvoice, 0)) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|		WHEN PrepaymentBalance >= CAST(ISNULL(Goods.AmountInInvoice, 0) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|			THEN CAST(ISNULL(Goods.AmountInInvoice, 0) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS Sum,
		|	Calculations.PaymentByInvoice AS PaymentByInvoice,
		|	ARAPObject AS ARAPObject,
		|	ARAPObject.ARAPCurrency AS ARAPCurrency
		|FROM
		|	TTCalculations AS Calculations
		|		LEFT JOIN TTProducts_1 AS Goods
		|			ON Calculations.Object = Goods.OrderDocument
		|				AND NOT Goods.ExceedingOrder
		|		LEFT JOIN TTProducts_1 AS GoodsInExcessOfOrder
		|			ON Calculations.Object = GoodsInExcessOfOrder.OrderDocument
		|				AND GoodsInExcessOfOrder.ExceedingOrder
		|WHERE
		|	CASE 
		|		//The order received more prepayment
		|		WHEN TotalPaid >= PaymentPlanForEverything THEN
		|			CASE
		|				WHEN PrepaymentBalance >= Goods.AmountInInvoice + GoodsInExcessOfOrder.AmountInInvoice
		|					THEN ISNULL(Goods.AmountInInvoice, 0) + ISNULL(GoodsInExcessOfOrder.AmountInInvoice, 0)
		|				WHEN PrepaymentBalance >= Goods.AmountInInvoice
		|					THEN ISNULL(Goods.AmountInInvoice, 0)
		|				ELSE 0
		|			END
		|		//The Balance has the required prepayment for the current invoice
		|		WHEN ISNULL(Goods.RequiredPrepayment, 0) + ISNULL(GoodsInExcessOfOrder.RequiredPrepayment, 0) > 0 AND PrepaymentBalance >= ISNULL(Goods.RequiredPrepayment, 0) + ISNULL(GoodsInExcessOfOrder.RequiredPrepayment, 0)
		|			THEN ISNULL(Goods.RequiredPrepayment, 0) + ISNULL(GoodsInExcessOfOrder.RequiredPrepayment, 0)
		|		WHEN ISNULL(Goods.RequiredPrepayment, 0) > 0 AND PrepaymentBalance >= ISNULL(Goods.RequiredPrepayment, 0)
		|			THEN ISNULL(Goods.RequiredPrepayment, 0)
		|		//If the required prepayment is not completed, we will calculate the prepayment amount for scheduled payments
		|		WHEN PrepaymentBalance >= CAST((ISNULL(Goods.AmountInInvoice, 0) + ISNULL(GoodsInExcessOfOrder.AmountInInvoice, 0)) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|			THEN CAST((ISNULL(Goods.AmountInInvoice, 0) + ISNULL(GoodsInExcessOfOrder.AmountInInvoice, 0)) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|		WHEN PrepaymentBalance >= CAST(ISNULL(Goods.AmountInInvoice, 0) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|			THEN CAST(ISNULL(Goods.AmountInInvoice, 0) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|		ELSE 0
		|	END > 0
		|");
		Query.SetParameter("ObjectsArray", BasisObject);
		Query.SetParameter("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
		PrepaymentOptions = New Array;
		If TheseAreSettlementsWithCustomers Then
			PrepaymentOptions.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision);
			PrepaymentOptions.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment);
		Else
			PrepaymentOptions.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation);
			PrepaymentOptions.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt);
		EndIf;
		Query.SetParameter("PrepaymentOptions", PrepaymentOptions);
		Query.Text = StrConcat(QueriesTexts);
		If Not TheseAreSettlementsWithCustomers Then
			Query.Text = StrReplace(Query.Text,".CustomersARAPAccounting",".VendorsARAPAccounting");
		EndIf;
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			MaximumAmountOfCredit = MaximumAmountOfCredit - Selection.PaymentByInvoice;
		EndIf;
		Selection.Reset();
		While Selection.Next() Do
			If MaximumAmountOfCredit <= 0 Then
				Continue;
			EndIf;
			AdvanceIsCredited = True;
			NwRw = ARAPDetails.Add();
			NwRw.ARAPObject = Selection.ARAPObject;
			If CommonClientServer.HasAttributeOrObjectProperty(NwRw,"ARAPCurrency") Then
				NwRw.ARAPCurrency = Selection.ARAPCurrency;
			EndIf;
			NwRw.AmountARAP = Min(Selection.Sum, MaximumAmountOfCredit);
			NwRw.Sum = Min(Selection.Sum, MaximumAmountOfCredit);
			ShouldReduce = NwRw.AmountARAP;
			For Each DecryptionString In ARAPDetails Do
				If ShouldReduce > 0
					And (Not ValueIsFilled(DecryptionString.ARAPObject)
						Or DecryptionString.ARAPObject = ARAPObjectInvoice) Then
					DecryptionString.AmountARAP = DecryptionString.AmountARAP - Min(DecryptionString.AmountARAP, ShouldReduce);
					DecryptionString.Sum = DecryptionString.AmountARAP;
					ShouldReduce = ShouldReduce - DecryptionString.AmountARAP;
				EndIf;
			EndDo;
			MaximumAmountOfCredit = MaximumAmountOfCredit - NwRw.Sum;
		EndDo;
		IndexOf = ARAPDetails.Count();
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			If ARAPDetails[IndexOf].AmountARAP = 0 Then
				ARAPDetails.Delete(IndexOf);
			EndIf;
		EndDo;
		
	ElsIf InvoiceForOrders And ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice And Not ParametersStructure.ExecutionScheduleIsSpecified Then
			
		If TypeOf(BasisObject) <> Type("Array") Then
			BasisObject = CommonClientServer.ValueInArray(BasisObject);
		EndIf;
		BasisObject.Add(Contract);
		
		Query = New Query;
		QueriesTexts = New Array;
		
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
			PaymentStagesTable = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentSteps);
			QueriesTexts.Add("
			|SELECT
			|	Table.ExceedingOrder AS ExceedingOrder,
			|	Table.PaymentOption AS PaymentOption,
			|	Table.AmountARAP + Table.AmountARAPByPackage AS Sum
			|INTO TTPaymentMilestones
			|FROM &PaymentStagesTable AS Table
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.ExceedingOrder AS ExceedingOrder,
			|	SUM(Goods.Sum) AS Sum,
			|	SUM(CASE WHEN Goods.PaymentOption IN (&PrepaymentOptions)
			|			THEN Goods.Sum
			|			ELSE 0
			|		END) AS RequiredPrepayment
			|INTO TTProducts_1
			|FROM TTPaymentMilestones AS Goods
			|GROUP BY
			|	Goods.ExceedingOrder
			|;");
			Query.SetParameter("PaymentStagesTable", PaymentStagesTable.Unload());
			OrderDocument = PaymentStagesTable.UnloadColumn("OrderDocument");
		Else
			OrderDocument = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
			Sum = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.AmountARAP);
			QueriesTexts.Add("
			|SELECT
			|	FALSE AS ExceedingOrder,
			|	&Sum AS Sum,
			|	0 AS RequiredPrepayment
			|INTO TTProducts_1
			|;");
			Query.SetParameter("Sum", Sum);
		EndIf;
		
		QueriesTexts.Add("
		|SELECT
		|	Goods.ExceedingOrder AS ExceedingOrder,
		|	SUM(Goods.Sum) AS InvoiceAmount,
		|	SUM(Goods.RequiredPrepayment) AS RequiredPrepayment
		|INTO TTInvoiceAmount
		|FROM TTProducts_1 AS Goods
		|GROUP BY
		|	Goods.ExceedingOrder
		|;");
		
		If Not NewOnlineARAPAccounting Then
		QueriesTexts.Add("
		|SELECT
		|	Calculations.ARAPObject        AS ARAPObject,
		|	SUM(CASE 
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND &TheseAreSettlementsWithCustomers
		|			OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT &TheseAreSettlementsWithCustomers
		|			THEN Calculations.Sum
		|		ELSE -Calculations.Sum
		|	END)                        AS PrepaymentBalance,
		|	SUM(CASE 
		|		WHEN Calculations.Recorder IN (&OrderDocument) 
		|			AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND &TheseAreSettlementsWithCustomers
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND NOT &TheseAreSettlementsWithCustomers)
		|				THEN AmountDue
		|			ELSE 0
		|	END)                         AS PaymentPlanForEverything,
		|	SUM(CASE 
		|		WHEN Calculations.Recorder IN (&OrderDocument)
		|			AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND &TheseAreSettlementsWithCustomers
		|				AND (Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision) 
		|					OR Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment))
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND NOT &TheseAreSettlementsWithCustomers
		|					AND (Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation)
		|						OR Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt))) 
		|					THEN AmountDue
		|			ELSE 0
		|	END)                         AS PrepaymentPlan,
		|	SUM(CASE 
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND &TheseAreSettlementsWithCustomers
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT &TheseAreSettlementsWithCustomers
		|			THEN Calculations.Sum
		|		ELSE 0
		|	END)                         AS TotalPaid,
		|	0                              AS PaymentByInvoice,
		|	TTInvoiceAmount.InvoiceAmount AS InvoiceAmount,
		|	TTAmountOfInvoiceInExcessOfOrder.InvoiceAmount AS AmountOfInvoiceInExcessOfOrder,
		|	TTInvoiceAmount.RequiredPrepayment AS RequiredPrepayment,
		|	TTAmountOfInvoiceInExcessOfOrder.RequiredPrepayment AS RequiredPrepaymentInExcessOfOrder
		|INTO TTCalculations
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|		LEFT JOIN TTInvoiceAmount AS TTInvoiceAmount
		|			ON NOT TTInvoiceAmount.ExceedingOrder
		|		LEFT JOIN TTInvoiceAmount AS TTAmountOfInvoiceInExcessOfOrder
		|			ON TTAmountOfInvoiceInExcessOfOrder.ExceedingOrder
		|WHERE
		|	ARAPObject.Object IN (&ObjectsArray)
		|GROUP BY
		|	Calculations.ARAPObject,
		|	TTInvoiceAmount.InvoiceAmount,
		|	TTAmountOfInvoiceInExcessOfOrder.InvoiceAmount,
		|	TTInvoiceAmount.RequiredPrepayment,
		|	TTAmountOfInvoiceInExcessOfOrder.RequiredPrepayment
		|HAVING
		|	SUM(CASE 
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND &TheseAreSettlementsWithCustomers
		|			OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT &TheseAreSettlementsWithCustomers
		|			THEN Calculations.Sum
		|		ELSE -Calculations.Sum
		|	END) > 0
		|	AND 
		|	SUM(CASE 
		|		WHEN Calculations.Recorder IN (&OrderDocument)
		|			AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND &TheseAreSettlementsWithCustomers
		|				AND (Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision) 
		|					OR Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment))
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND NOT &TheseAreSettlementsWithCustomers
		|					AND (Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation)
		|						OR Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt))) 
		|					THEN AmountDue
		|			ELSE 0
		|	END) > 0
		|	AND 
		|	SUM(CASE 
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND &TheseAreSettlementsWithCustomers
		|				OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT &TheseAreSettlementsWithCustomers
		|			THEN Calculations.Sum
		|		ELSE 0
		|	END) > 0
		|;");
		Else
			QueriesTexts.Add(QueryTextForPrepaymentBalances(TheseAreSettlementsWithCustomers));
			Query.SetParameter("CustomerInvoiceDate", CustomerInvoiceDate);
			Query.SetParameter("Objects", Contract);
			Query.SetParameter("PlanDocuments", OrderDocument);
			Query.SetParameter("ReportData", 4);
			Query.SetParameter("LinkToInvoice", LinkToInvoice);
		EndIf;
		
		QueriesTexts.Add("
		|SELECT
		|	CASE 
		|		//The order received more prepayment
		|		WHEN TotalPaid >= PaymentPlanForEverything
		|			THEN CASE
		|					WHEN TotalPaid * (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) / PaymentPlanForEverything > PaymentPlanForEverything
		|						THEN CASE
		|								WHEN PaymentPlanForEverything > InvoiceAmount
		|									AND (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) <= PrepaymentBalance
		|									THEN (InvoiceAmount + AmountOfInvoiceInExcessOfOrder)
		|								WHEN PaymentPlanForEverything <= (InvoiceAmount + AmountOfInvoiceInExcessOfOrder)
		|									AND PaymentPlanForEverything <= PrepaymentBalance
		|									THEN PaymentPlanForEverything
		|								ELSE PrepaymentBalance
		|							END
		|					ELSE CASE
		|								WHEN TotalPaid * (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) / PaymentPlanForEverything > (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) 
		|									AND (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) <= PrepaymentBalance
		|									THEN (InvoiceAmount + AmountOfInvoiceInExcessOfOrder)
		|								WHEN TotalPaid * (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) / PaymentPlanForEverything <= (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) 
		|									AND PaymentPlanForEverything <= PrepaymentBalance
		|									THEN PaymentPlanForEverything
		|								ELSE PrepaymentBalance
		|							END
		|				END 
		|		//The Balance has the required prepayment for the current invoice
		|		WHEN RequiredPrepayment + RequiredPrepaymentInExcessOfOrder > 0 AND PrepaymentBalance >= RequiredPrepayment + RequiredPrepaymentInExcessOfOrder
		|			THEN RequiredPrepayment + RequiredPrepaymentInExcessOfOrder
		|		WHEN RequiredPrepayment > 0 AND PrepaymentBalance >= RequiredPrepayment
		|			THEN RequiredPrepayment
		|		//If the required prepayment is not completed, we will calculate the prepayment amount for scheduled payments
		|		WHEN PrepaymentBalance >= CAST((InvoiceAmount + AmountOfInvoiceInExcessOfOrder) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|			THEN CAST((InvoiceAmount + AmountOfInvoiceInExcessOfOrder) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|		WHEN PrepaymentBalance >= CAST(InvoiceAmount * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|			THEN CAST(InvoiceAmount * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS Sum,
		|	Calculations.PaymentByInvoice AS PaymentByInvoice,
		|	ARAPObject AS ARAPObject,
		|	ARAPObject.ARAPCurrency AS ARAPCurrency
		|FROM
		|	TTCalculations AS Calculations
		|WHERE
		|	CASE 
		|		//The order received more prepayment
		|		WHEN TotalPaid >= PaymentPlanForEverything
		|			THEN CASE
		|					WHEN TotalPaid * (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) / PaymentPlanForEverything > PaymentPlanForEverything
		|						THEN CASE
		|								WHEN PaymentPlanForEverything > InvoiceAmount
		|									AND (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) <= PrepaymentBalance
		|									THEN (InvoiceAmount + AmountOfInvoiceInExcessOfOrder)
		|								WHEN PaymentPlanForEverything <= (InvoiceAmount + AmountOfInvoiceInExcessOfOrder)
		|									AND PaymentPlanForEverything <= PrepaymentBalance
		|									THEN PaymentPlanForEverything
		|								ELSE PrepaymentBalance
		|							END
		|					ELSE CASE
		|								WHEN TotalPaid * (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) / PaymentPlanForEverything > (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) 
		|									AND (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) <= PrepaymentBalance
		|									THEN (InvoiceAmount + AmountOfInvoiceInExcessOfOrder)
		|								WHEN TotalPaid * (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) / PaymentPlanForEverything <= (InvoiceAmount + AmountOfInvoiceInExcessOfOrder) 
		|									AND PaymentPlanForEverything <= PrepaymentBalance
		|									THEN PaymentPlanForEverything
		|								ELSE PrepaymentBalance
		|							END
		|				END 
		|		//The Balance has the required prepayment for the current invoice
		|		WHEN RequiredPrepayment + RequiredPrepaymentInExcessOfOrder > 0 AND PrepaymentBalance >= RequiredPrepayment + RequiredPrepaymentInExcessOfOrder
		|			THEN RequiredPrepayment + RequiredPrepaymentInExcessOfOrder
		|		WHEN RequiredPrepayment > 0 AND PrepaymentBalance >= RequiredPrepayment
		|			THEN RequiredPrepayment
		|		//If the required prepayment is not completed, we will calculate the prepayment amount for scheduled payments
		|		WHEN PrepaymentBalance >= CAST((InvoiceAmount + AmountOfInvoiceInExcessOfOrder) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|			THEN CAST((InvoiceAmount + AmountOfInvoiceInExcessOfOrder) * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|		WHEN PrepaymentBalance >= CAST(InvoiceAmount * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|			THEN CAST(InvoiceAmount * CAST(PrepaymentPlan / PaymentPlanForEverything AS NUMBER(31,10)) AS NUMBER(31,2))
		|		ELSE 0
		|	END > 0
		|");
		Query.SetParameter("ObjectsArray", Contract);
		Query.SetParameter("OrderDocument", OrderDocument);
		Query.SetParameter("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
		PrepaymentOptions = New Array;
		If TheseAreSettlementsWithCustomers Then
			PrepaymentOptions.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision);
			PrepaymentOptions.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment);
		Else
			PrepaymentOptions.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation);
			PrepaymentOptions.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt);
		EndIf;
		Query.SetParameter("PrepaymentOptions", PrepaymentOptions);
		Query.Text = StrConcat(QueriesTexts);
		If Not TheseAreSettlementsWithCustomers Then
			Query.Text = StrReplace(Query.Text,".CustomersARAPAccounting",".VendorsARAPAccounting");
		EndIf;
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			MaximumAmountOfCredit = MaximumAmountOfCredit - Selection.PaymentByInvoice;
		EndIf;
		Selection.Reset();
		While Selection.Next() Do
			If MaximumAmountOfCredit <= 0 Then
				Continue;
			EndIf;
			AdvanceIsCredited = True;
			NwRw = ARAPDetails.Add();
			NwRw.ARAPObject = Selection.ARAPObject;
			If CommonClientServer.HasAttributeOrObjectProperty(NwRw,"ARAPCurrency") Then
				NwRw.ARAPCurrency = Selection.ARAPCurrency;
			EndIf;
			NwRw.AmountARAP = Min(Selection.Sum, MaximumAmountOfCredit);
			NwRw.Sum = Min(Selection.Sum, MaximumAmountOfCredit);
			ShouldReduce = NwRw.AmountARAP;
			For Each DecryptionString In ARAPDetails Do
				If ShouldReduce > 0
					And (Not ValueIsFilled(DecryptionString.ARAPObject)
						Or DecryptionString.ARAPObject = ARAPObjectInvoice) Then
					DecryptionString.AmountARAP = DecryptionString.AmountARAP - Min(DecryptionString.AmountARAP, ShouldReduce);
					DecryptionString.Sum = DecryptionString.AmountARAP;
					ShouldReduce = ShouldReduce - DecryptionString.AmountARAP;
				EndIf;
			EndDo;
			MaximumAmountOfCredit = MaximumAmountOfCredit - NwRw.Sum;
		EndDo;
		IndexOf = ARAPDetails.Count();
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			If ARAPDetails[IndexOf].AmountARAP = 0 Then
				ARAPDetails.Delete(IndexOf);
			EndIf;
		EndDo;
		
	ElsIf ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice And ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
		
		TSPaymentSteps = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentSteps);
		
		PrepaymentAmountMan = 0;
		For Each PaymentStageLine In TSPaymentSteps Do
			If PaymentStageLine.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision
				Or PaymentStageLine.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment
				Or PaymentStageLine.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation
				Or PaymentStageLine.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt Then
				PrepaymentAmountMan = PrepaymentAmountMan + PaymentStageLine.AmountARAP;
				If CommonClientServer.HasAttributeOrObjectProperty(PaymentStageLine, "AmountARAPByPackage") Then
					PrepaymentAmountMan = PrepaymentAmountMan + PaymentStageLine.AmountARAPByPackage;
				EndIf;
			EndIf;
		EndDo;
		
		Query = New Query;
		If Not NewOnlineARAPAccounting Then
		Query.Text = "
		|SELECT
		|	Calculations.ARAPObject AS ARAPObject,
		|	CASE
		|		WHEN &TheseAreSettlementsWithCustomers
		|			THEN -Calculations.SumBalance
		|		ELSE Calculations.SumBalance
		|	END AS PrepaymentBalance
		|INTO TTCalculations
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object = &Contract) AS Calculations
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN Calculations.PrepaymentBalance >= &PrepaymentAmountMan
		|			THEN &PrepaymentAmountMan
		|		ELSE 0
		|	END AS Sum,
		|	0 AS PaymentByInvoice,
		|	Calculations.ARAPObject AS ARAPObject,
		|	Calculations.ARAPObject.ARAPCurrency AS ARAPCurrency
		|FROM
		|	TTCalculations AS Calculations
		|WHERE
		|	CASE
		|		WHEN Calculations.PrepaymentBalance >= &PrepaymentAmountMan
		|			THEN &PrepaymentAmountMan
		|		ELSE 0
		|	END > 0";
		Else
			Query.Text = "
				|SELECT
				|	Calculations.ARAPObject AS ARAPObject,
				|	&PrepaymentAmountMan AS Sum,
				|	ISNULL(MAX(InvoiceCalculations.PrepaymentBalance), 0) AS PaymentByInvoice,
				|	Calculations.ARAPObject.ARAPCurrency AS ARAPCurrency
				|FROM
				|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, ARAPObject.Object = &Contract) AS Calculations
				|		LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, ARAPObject.Object = &LinkToInvoice) AS InvoiceCalculations
				|		ON (TRUE)
				|WHERE
				|	Calculations.OccurrenceDate <= &CustomerInvoiceDate
				|
				|GROUP BY
				|	Calculations.ARAPObject,
				|	Calculations.ARAPObject.ARAPCurrency
				|
				|HAVING
				|	CASE
				|		WHEN SUM(Calculations.PrepaymentBalance) >= &PrepaymentAmountMan
				|			THEN &PrepaymentAmountMan
				|		ELSE 0
				|	END > 0
				|";
			Query.SetParameter("CustomerInvoiceDate", CustomerInvoiceDate);
		EndIf;
		Query.SetParameter("Contract", Contract);
		Query.SetParameter("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
		Query.SetParameter("PrepaymentAmountMan", PrepaymentAmountMan);
		Query.SetParameter("LinkToInvoice", LinkToInvoice);
		If Not TheseAreSettlementsWithCustomers Then
			Query.Text = StrReplace(Query.Text,".CustomersARAPAccounting",".VendorsARAPAccounting");
		EndIf;
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			MaximumAmountOfCredit = MaximumAmountOfCredit - Selection.PaymentByInvoice;
		EndIf;
		Selection.Reset();
		While Selection.Next() Do
			If MaximumAmountOfCredit <= 0 Then
				Continue;
			EndIf;
			AdvanceIsCredited = True;
			NwRw = ARAPDetails.Add();
			NwRw.ARAPObject = Selection.ARAPObject;
			If CommonClientServer.HasAttributeOrObjectProperty(NwRw,"ARAPCurrency") Then
				NwRw.ARAPCurrency = Selection.ARAPCurrency;
			EndIf;
			NwRw.AmountARAP = Min(Selection.Sum, MaximumAmountOfCredit);
			NwRw.Sum = Min(Selection.Sum, MaximumAmountOfCredit);
			ShouldReduce = NwRw.AmountARAP;
			For Each DecryptionString In ARAPDetails Do
				If ShouldReduce > 0
					And (Not ValueIsFilled(DecryptionString.ARAPObject)
						Or DecryptionString.ARAPObject = ARAPObjectInvoice) Then
					DecryptionString.AmountARAP = DecryptionString.AmountARAP - Min(DecryptionString.AmountARAP, ShouldReduce);
					DecryptionString.Sum = DecryptionString.AmountARAP;
					ShouldReduce = ShouldReduce - DecryptionString.AmountARAP;
				EndIf;
			EndDo;
			MaximumAmountOfCredit = MaximumAmountOfCredit - NwRw.Sum;
		EndDo;
		IndexOf = ARAPDetails.Count();
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			If ARAPDetails[IndexOf].AmountARAP = 0 Then
				ARAPDetails.Delete(IndexOf);
			EndIf;
		EndDo;
	EndIf;
	
	If AdvanceIsCredited Then
		DocumentAmounts = ARAPAccountingInternal.DocumentAmounts(Object, ParametersStructure);
		DocumentAmount = DocumentAmounts.PackageDepositValue + DocumentAmounts.AmountOfDocumentWithoutCollateral;
		AmountARAP = DocumentAmounts.AmountOfSettlementsWithoutCollateral + DocumentAmounts.AmountARAPByPackage;
		ARAPAccountingServer.FillInAmountOfInvoiceDecryption(DocumentAmount, AmountARAP, ARAPDetails, ARAPObjectInvoice);
	EndIf;
	
EndProcedure

Function QueryTextForPrepaymentBalances(TheseAreSettlementsWithCustomers)
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject                                      AS ARAPObject,
	|	Calculations.ARAPObject.Object                               AS Object,
	|	SUM(Calculations.PrepaymentBalance)                            AS PrepaymentBalance,
	|	SUM(Calculations.PaymentPlanForEverything)                              AS PaymentPlanForEverything,
	|	SUM(Calculations.PrepaymentPlan)                               AS PrepaymentPlan,
	|	SUM(Calculations.TotalPaid)                                AS TotalPaid,
	|	ISNULL(MAX(InvoiceCalculations.PrepaymentBalance), 0) AS PaymentByInvoice,
	|	TTInvoiceAmount.InvoiceAmount                             AS InvoiceAmount,
	|	TTInvoiceAmount.RequiredPrepayment                        AS RequiredPrepayment,
	|	TTAmountOfInvoiceInExcessOfOrder.InvoiceAmount                  AS AmountOfInvoiceInExcessOfOrder,
	|	TTAmountOfInvoiceInExcessOfOrder.RequiredPrepayment             AS RequiredPrepaymentInExcessOfOrder
	|INTO TTCalculations
	|FROM
	|	(SELECT
	|		TermBalances.ARAPObject    AS ARAPObject,
	|		TermBalances.PrepaymentBalance AS PrepaymentBalance,
	|		0                                 AS PaymentPlanForEverything,
	|		0                                 AS PrepaymentPlan,
	|		0                                 AS TotalPaid
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, ARAPObject.Object IN (&Objects)) AS TermBalances
	|	WHERE
	|		TermBalances.OccurrenceDate <= &CustomerInvoiceDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PaymentPlan_.ARAPObject          AS ARAPObject,
	|		0                                 AS PrepaymentBalance,
	|		PaymentPlan_.AmountDue                 AS PaymentPlanForEverything,
	|		CASE
	|			WHEN PaymentPlan_.PaymentOption IN (&PrepaymentOptions)
	|				THEN PaymentPlan_.AmountDue
	|			ELSE 0
	|		END                             AS PrepaymentPlan,
	|		0                                 AS TotalPaid
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlan_
	|	WHERE
	|		PaymentPlan_.Recorder IN(&PlanDocuments)
	|		AND PaymentPlan_.Active
	|		AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationsByTerms.ARAPObject    AS ARAPObject,
	|		0                                 AS PrepaymentBalance,
	|		0                                 AS PaymentPlanForEverything,
	|		0                                 AS PrepaymentPlan,
	|		&TemplateForPaidField               AS TotalPaid
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|	WHERE
	|		CalculationsByTerms.ARAPObject.Object IN (&Objects)
	|		AND CalculationsByTerms.OccurrenceDate <= &CustomerInvoiceDate
	|		AND CalculationsByTerms.Active) AS Calculations
	|		LEFT JOIN TTInvoiceAmount AS TTInvoiceAmount
	|		ON NOT TTInvoiceAmount.ExceedingOrder
	|		LEFT JOIN TTInvoiceAmount AS TTAmountOfInvoiceInExcessOfOrder
	|		ON TTAmountOfInvoiceInExcessOfOrder.ExceedingOrder
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, ARAPObject.Object = &LinkToInvoice) AS InvoiceCalculations
	|		ON (TRUE)
	|
	|GROUP BY
	|	Calculations.ARAPObject,
	|	TTInvoiceAmount.InvoiceAmount,
	|	TTAmountOfInvoiceInExcessOfOrder.InvoiceAmount,
	|	TTInvoiceAmount.RequiredPrepayment,
	|	TTAmountOfInvoiceInExcessOfOrder.RequiredPrepayment
	|HAVING 
	|	SUM(Calculations.PrepaymentBalance) > 0
	|	AND SUM(Calculations.PrepaymentPlan) > 0
	|;";
	QueryText = StrReplace(QueryText, "&TemplateForPaidField", ?(TheseAreSettlementsWithCustomers, FieldTemplatePaidByCustomer(), TemplateForPaidToSupplierField()));
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Posting

// Deprecated. The function receives temporary tables of exchange rates and areas of activity.
// 
// Parameters:
//  QueryTextOfSourceTable - String - Query Text with data on settlement objects, currencies, And exchange rate dates
//  ThisIsPaymentOperation - Boolean - The default value is False, True for payment and refund operations
// 
// Returns:
//  String - Query Text With the created temporary tables vtcoefficientcounts currency And Vtdirection of activity
Function GetTableOfExchangeRatesLinesOfBusiness(QueryTextOfSourceTable, ThisIsPaymentOperation = False) Export
	
	Return ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextOfSourceTable, ThisIsPaymentOperation);
	
EndFunction

// Deprecated. The function receives a temporary table of activity directions.
// 
// Parameters:
//  QueryTextOfSourceTable - String - Query Text with data on settlement objects, currencies, And exchange rate dates
// 
// Returns:
//  String - Query Text With the created temporary Tablereferencesexternal Links
Function GetTableOfLinesOfBusiness(QueryTextOfSourceTable) Export
	
	Return ARAPAccountingPosting.GetTableOfLinesOfBusiness(QueryTextOfSourceTable);
	
EndFunction

// Deprecated. The text of the TT of the transfer of calculations.
// 
// Parameters:
//  TableName - String - table name
// 
// Returns:
//  String - TT Text For Transferring Calculations
Function TTTextForTransferringCalculations(TableName = "") Export
	
	Return ARAPAccountingPosting.TTTextForTransferringCalculations(TableName);
	
EndFunction

#EndRegion

#EndRegion

#EndRegion
