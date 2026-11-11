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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	//++ WE
	DocumentMechanisms.Add("PayrollAccountingHR");
	//-- WE
	ExchangeDifferenceCalculationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ExchangeDifferenceCalculation") Then
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
		
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			RequestTextTTTableSettlementsWithSuppliersByTerms(QueryTexts);
			RequestTextTTTableSettlementsWithClientsByTerms(QueryTexts);
		Else
			RequestTextTTTableSettlementsWithSuppliersBasedOnDocuments(QueryTexts);
			RequestTextTTTableSettlementsWithClientsByDocuments(QueryTexts);
		EndIf;
		RequestTextTTTableCashNonCash(QueryTexts);
		RequestTextTTTableCashCash(QueryTexts);
		RequestTextTTTableCashInCashRegistersCashRegister(QueryTexts);
		RequestTextTTCashInTransitTable(QueryTexts);
		RequestTextTTTableFundsHeldByAccountablePersons(QueryTexts);
		QueryTextTTTableFinancialInstruments(QueryTexts);
		RequestTextTTTableProvisionsForDoubtfulDebts(QueryTexts);
		RequestTextTTTableOfDiscountAmounts(QueryTexts);
		
		QueryTextTTGoodsToCommitteeForPreparationOfReports(QueryTexts);
		QueryTextTTGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases(QueryTexts);
		QueryTextTTServicesToDesignOfReportsToPrincipal(QueryTexts);
		
		QueryTextTTSettlementsWithCustomers(QueryTexts);
		RequestTextTTSettlementsWithClientsForSettlementObjects(QueryTexts);
		QueryTextTTSettlementsWithSuppliers(QueryTexts);
		RequestTextTTSettlementsWithSuppliersForSettlementObjects(QueryTexts);
		QueryTextTTInvestmentInRent(QueryTexts);
		//++ WE
		QueryTextPayrollCalculations(QueryTexts);
		//-- WE
		// On-line Registered Records
		QueryTextTableOtherIncome(QueryTexts, Registers);
		QueryTextTableOtherExpenses(QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(QueryTexts, Registers);
		
		QueryTextTableRecordsCashIncomeExpenses(QueryTexts, Registers);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		ExchangeDifferenceCalculationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	ExchangeDifferenceCalculationLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "calculation of exchange differences".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// 	Undefined
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ExchangeDifferenceCalculation) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ExchangeDifferenceCalculation.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ExchangeDifferenceCalculation);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMultipleCurrencies";
	
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
	
	ExchangeDifferenceCalculationLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Returns revaluation registers for the specified business transaction.
// If a business transaction is not specified, all operational registers that are re-evaluated by the document are returned.
//
// Parameters:
//  Operation - EnumRef.BusinessTransactions - business operation for which you need to get a list of registers.
//	RegisterNames - Structure - the structure previously filled with the names of registers (for adding new registers).
//
// Returns:
//  Structure of KeyAndValue - the structure keys list the names of the overestimated registers
//
Function CalculationRegisters(Operation = Undefined, RegisterNames = Undefined) Export
	
	If RegisterNames = Undefined Then
		RegisterNames = New Structure;
	EndIf;
	
	NewArchitecture = GetFunctionalOption("NewOnlineARAPAccounting");
	
	If Operation = Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting Or Operation = Undefined Then
		If NewArchitecture Then
			RegisterNames.Insert("VendorsARAPAccountingByDueDates");
		Else
			RegisterNames.Insert("VendorsARAPAccountingByDocuments");
		EndIf;
	EndIf;
	
	If Operation = Enums.BusinessTransactions.RevaluationOfCustomersARAP Or Operation = Undefined Then
		If NewArchitecture Then
			RegisterNames.Insert("CustomersARAPAccountingByDueDates");
		Else
			RegisterNames.Insert("CustomersARAPAccountingByDocuments");
		EndIf;
	EndIf;
		
	If Operation = Enums.BusinessTransactions.CashRevaluation Or Operation = Undefined Then
		RegisterNames.Insert("BankAccountCash");
		RegisterNames.Insert("CashAccountBalance");
		RegisterNames.Insert("CashInCashRegistersCR");
		RegisterNames.Insert("CashInTransit");
		RegisterNames.Insert("AdvanceHolderCash");
	EndIf;
		
	If Operation = Enums.BusinessTransactions.RevaluationOfFinancialInstruments Or Operation = Undefined Then
		If GetFunctionalOption("UseLoanAndDepositContracts") Then
			RegisterNames.Insert("FinancialInstrumentsARAP");
		EndIf;
		If GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
			RegisterNames.Insert("InvestmentInRent");
		EndIf;
	EndIf;
	If Operation = Enums.BusinessTransactions.RevaluationOfLeaseARAP Or Operation = Undefined Then
		RegisterNames.Insert("FinancialInstrumentsARAP");
	EndIf;
	
	If Operation = Enums.BusinessTransactions.RevaluationOfLossAllowance Or Operation = Undefined Then
		RegisterNames.Insert("LossAllowance");
	EndIf;
	//++ WE
	If Operation = Enums.BusinessTransactions.PayrollCalculationRevaluation Or Operation = Undefined Then
		RegisterNames.Insert("PayrollCalculationsHR");
	EndIf;
	//-- WE
	If Operation = Enums.BusinessTransactions.RevaluationOfDiscountAmounts Or Operation = Undefined Then
		RegisterNames.Insert("DiscountInterestExpense");
	EndIf;
	
	If Operation = Enums.BusinessTransactions.RevaluationOfConsignorPrincipalARAP Or Operation = Undefined Then
		RegisterNames.Insert("GoodsToBeRegisteredInReportsToConsignor");
		RegisterNames.Insert("GoodsAndServicesToRegisterPurchasingReportsToConsignor");
		RegisterNames.Insert("ServicesForRegistrationOfReportsToPrincipal");
	EndIf;
	
	ExchangeDifferenceCalculationLocalization.AddCalculationRegisters(RegisterNames, Operation);
	
	Return RegisterNames;
	
EndFunction

// Performs a revaluation of everything that is possible in operational accounting.
//	Overestimate:
//	- Cash balances.
//	- Settlements with clients.
//	- Mutual settlements with suppliers.
//	- Balances on loans, deposits, and loans.
//
// Parameters:
//	Period - Date - any date of the month for which the revaluation should be performed
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//
Procedure PerformReevaluation(Period, Organization = Undefined) Export
	
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.CashRevaluation);
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.RevaluationOfCustomersARAP);
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting);
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.RevaluationOfFinancialInstruments);
	//++ WE
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.PayrollCalculationRevaluation);
	//-- WE
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.RevaluationOfLossAllowance);
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.RevaluationOfDiscountAmounts);
	
EndProcedure

// Performs revaluation of cash balances.
//
// Parameters:
//	CompanyArray - CatalogRef.Companies, Array of CatalogRef.Companies - The organization (list of organizations) that needs to be re-evaluated.
//	Period - Date - any date of the month for which the revaluation should be performed.
//
Procedure RevalueCash(CompanyArray, Period) Export
	
	For Each Organization In TMCommonUseClientServer.Array(CompanyArray) Do
		ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.CashRevaluation);
	EndDo;
	
EndProcedure

// Performs revaluation of cash balances in the specified cash registers of the organization.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//	DimensionCalculation - CatalogRef.CashAccounts, Array of CatalogRef.Companies, Undefined - The cash register (list of cash registers) that needs to be re-evaluated.
//	                   If not set, then for all.
//
Procedure ReevaluateOrganizationSCashRegisters(Organization, Period, DimensionCalculation = Undefined) Export
	
	Operation = Enums.BusinessTransactions.CashRevaluation;
	RegistersForCalculation = New Structure("CashAccountBalance");
	Dimension = New Structure("CashAccounts", DimensionCalculation);
	RevaluationParameters = New Structure("DimensionCalculation, CalculationRegisters", Dimension, RegistersForCalculation);
	
	ConductReevaluationDocument(Organization, Period, Operation, RevaluationParameters);
	
EndProcedure

// Performs revaluation of cash balances of accountable persons.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//	DimensionCalculation - CatalogRef.Persons, Array of CatalogRef.Persons, Undefined - An individual (list of persons) who needs to be revalued.
//	                   If not specified, then for all.
//
Procedure RevaluateFundsHeldByAccountablePersons(Organization, Period, DimensionCalculation = Undefined) Export
	
	Operation = Enums.BusinessTransactions.CashRevaluation;
	RegistersForCalculation = New Structure("AdvanceHolderCash");
	Dimension = New Structure("Persons", DimensionCalculation);
	RevaluationParameters = New Structure("DimensionCalculation, CalculationRegisters", Dimension, RegistersForCalculation);
	
	ConductReevaluationDocument(Organization, Period, Operation, RevaluationParameters);
	
EndProcedure

// Performs revaluation of settlements with clients.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//	DimensionCalculation - CatalogRef.DimensionKeysOfAccountingByPartners, Array of CatalogRef.DimensionKeysOfAccountingByPartners, Undefined - Analyticaccount to partners (list of analysts)
//	                   for which you need to perform a revaluation. If not set, then for all.
//	ProcessedItemsCount - Number - the variable is placed in the number of recorded entries
//                                            in the case Resetaccountstat when calculating exchange rate differences.
//
Procedure ReassessCustomerSettlements(Organization, Period, DimensionCalculation = Undefined, ProcessedItemsCount = 0) Export
	
	Operation = Enums.BusinessTransactions.RevaluationOfCustomersARAP;
	Dimension = New Structure("AccountingDimensionByPartners", DimensionCalculation);
	RevaluationParameters = New Structure("DimensionCalculation, ProcessedItemsCount", Dimension, ProcessedItemsCount);
	ConductReevaluationDocument(Organization, Period, Operation, RevaluationParameters);
	ProcessedItemsCount = RevaluationParameters.ProcessedItemsCount;
	
EndProcedure

// Performs revaluation of settlements with suppliers.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//	DimensionCalculation - CatalogRef.DimensionKeysOfAccountingByPartners, Array of CatalogRef.DimensionKeysOfAccountingByPartners, Undefined - Analyticaccount to partners (list of analysts)
//	                   for which you need to perform a revaluation. If not set, then for all.
//	ProcessedItemsCount - Number - the variable is placed in the number of recorded entries
//                                            in the case Resetinputcontext when calculating exchange rate differences.
//
Procedure ReassessSettlementsWithSuppliers(Organization, Period, DimensionCalculation = Undefined, ProcessedItemsCount = 0) Export
	
	Operation = Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting;
	Dimension = New Structure("AccountingDimensionByPartners", DimensionCalculation);
	RevaluationParameters = New Structure("DimensionCalculation, ProcessedItemsCount", Dimension, ProcessedItemsCount);
	ConductReevaluationDocument(Organization, Period, Operation, RevaluationParameters);
	ProcessedItemsCount = RevaluationParameters.ProcessedItemsCount;
	
EndProcedure

// Performs revaluation of loans, deposits, and loans.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//  DimensionCalculation - EnumRef.LoanAndDepositScheduleAmountTypes, Array of EnumRef.LoanAndDepositScheduleAmountTypes, Undefined - Types of amounts that need to be revalued.//	
//
Procedure RevalueFinancialInstruments(Organization, Period, DimensionCalculation = Undefined) Export
	
	RevaluationParameters = New Structure;
	Dimension = New Structure("AccountingDimensionByPartners", DimensionCalculation);
	RevaluationParameters.Insert("DimensionCalculation", Dimension);
	
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.RevaluationOfFinancialInstruments, RevaluationParameters);
	
EndProcedure
//++ WE

// Performs a reevaluation of payroll calculations.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//
Procedure ReevaluatePayrollCalculations(Organization, Period) Export
	
	RevaluationParameters = New Structure;
	RevaluationParameters.Insert("Organization", Organization);
	
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.PayrollCalculationRevaluation, RevaluationParameters);
	
EndProcedure

//-- WE 

// Performs a lease revaluation.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//  DimensionCalculation - EnumRef.TypesOfLeasePayments, Array of EnumRef.TypesOfLeasePayments, Undefined - Types of amounts that need to be revalued.	
//
Procedure ReassessLeases(Organization, Period, DimensionCalculation = Undefined) Export
	
	RevaluationParameters = New Structure;
	Dimension = New Structure("AccountingDimensionByPartners", DimensionCalculation);
	RevaluationParameters.Insert("DimensionCalculation", Dimension);
	
	ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.RevaluationOfLeaseARAP, RevaluationParameters);
	
EndProcedure

// Performs revaluation of reserves for doubtful debts.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//	DimensionCalculation - CatalogRef.DimensionKeysOfAccountingByPartners, Array of CatalogRef.DimensionKeysOfAccountingByPartners, Undefined - The cash register (list of cash registers) that needs to be re-evaluated.
//	                   If not set, then for all.
//
Procedure RevaluationOfProvisionsForDoubtfulDebts(Organization, Period, DimensionCalculation = Undefined) Export
	
	Operation = Enums.BusinessTransactions.RevaluationOfLossAllowance;
	Dimension = New Structure("AccountingDimensionByPartners", DimensionCalculation);
	RevaluationParameters = New Structure("DimensionCalculation", Dimension);
	ConductReevaluationDocument(Organization, Period, Operation, RevaluationParameters);
	
EndProcedure
// Performs a revaluation of interest expenses of discount amounts.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization (list of organizations) that needs to be re-evaluated.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//	DimensionCalculation - CatalogRef.DimensionKeysOfAccountingByPartners, Array of CatalogRef.DimensionKeysOfAccountingByPartners, Undefined - The cash register (list of cash registers) that needs to be re-evaluated.
//	                   If not set, then for all.
//
Procedure ReassessDiscountAmounts(Organization, Period, DimensionCalculation = Undefined) Export
	
	Operation = Enums.BusinessTransactions.RevaluationOfDiscountAmounts;
	Dimension = New Structure("AccountingDimensionByPartners", DimensionCalculation);
	RevaluationParameters = New Structure("DimensionCalculation", Dimension);
	ConductReevaluationDocument(Organization, Period, Operation, RevaluationParameters);
	
EndProcedure

// Performs revaluation of settlements with the committee/commission agent.
//
// Parameters:
//	CompanyArray - CatalogRef.Companies, Array of CatalogRef.Companies - The organization (list of organizations) that needs to be re-evaluated.
//	Period - Date - any date of the month for which the revaluation should be performed.
//
Procedure ReevaluateCommissionCalculations(CompanyArray, Period) Export
	
	For Each Organization In TMCommonUseClientServer.Array(CompanyArray) Do
		ConductReevaluationDocument(Organization, Period, Enums.BusinessTransactions.RevaluationOfConsignorPrincipalARAP);
	EndDo;
	
EndProcedure

// To reflect the income and expenses from exchange rate differences in the settlement with the partners in the account.
//
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - Organization (list of organizations)
//                for which you need to reflect exchange differences.
//                If not specified, then for all.
//	Period - Date - any date of the month for which the revaluation should be performed.
//
Procedure ReflectExchangeDifferencesOnSettlements(Organization, Period) Export
	
	ReassessSettlementsWithSuppliers(Organization, Period);
	ReassessCustomerSettlements(Organization, Period);
	
EndProcedure

// Returns documents for calculating exchange rate differences for the specified period (one or an arbitrary number of months)
// in the form of a match to the Month date - the month document account.
// The number of documents is equal to the number of months in the specified period.
// If there is no completed document in any of the months, it will be created.
//
// Parameters:
//	Organization - CatalogRef.Companies - Organization for which you need to get documents for calculating exchange differences
//	BeginOfPeriod - Date - Date start of the document selection period (will be shown by the beginning of the month)
//	EndOfPeriod - Date - End date of the document selection period (will be shown by the end of the month)
//	TheseAreSettlementsWithCustomers - Boolean - If True, then select revaluation documents by customer or by supplier
//
// Returns:
//	Map of KeyAndValue - in the matching keys, the date of the beginning of the month, in the values of the document for calculating the exchange rate differences of the corresponding month:
//		* Key - Date - The date of the revaluation.
//		* Value - DocumentRef.ExchangeDifferenceCalculation - Registrar.
//
Function RevaluationDocuments(Organization, BeginOfPeriod, EndOfPeriod, TheseAreSettlementsWithCustomers) Export
	
	If BeginOfPeriod <= Date('19800101') Or Not ValueIsFilled(BeginOfPeriod) Then
		Raise NStr("vi = 'Đã xác định sai ngày của kỳ thứ nhất tính toán chênh lệch tỷ giá.';
					|ru = 'Задана некорректная дата первого периода расчета курсовых разниц.';
					|en = 'Incorrect date of the first period of exchange difference calculation is specified.'; fa = 'Incorrect date of the first period of exchange difference calculation is specified.';
					|it = 'È stata impostata la data scorretta del primo periodo di calcolo delle differenze di cambio.';
					|pl = 'Ustalono niepoprawną datę pierwszego okresu obliczania różnic kursowych.';
					|tr = 'Kur farkı hesaplamasının ilk dönem tarihi hatalı olarak belirlendi.'");
	EndIf;
	
	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = CurrentSessionDate();
	EndIf;
	
	RevaluationDocuments = New Map;
	DifferenceOfMonths = Month(EndOfPeriod) - Month(BeginOfPeriod) + 12*(Year(EndOfPeriod) - Year(BeginOfPeriod));
	For MonthIndex = 0 To DifferenceOfMonths Do
		NewMonth = AddMonth(BeginOfPeriod, MonthIndex);
		RevaluationDocuments.Insert(BegOfMonth(NewMonth));
	EndDo;
	
	Query = New Query(
	"SELECT
	|	BEGINOFPERIOD(ExchangeDifferenceCalculation.Date, MONTH) AS Date,
	|	ExchangeDifferenceCalculation.Ref AS Ref
	|FROM
	|	Document.ExchangeDifferenceCalculation AS ExchangeDifferenceCalculation
	|WHERE
	|	NOT ExchangeDifferenceCalculation.DeletionMark
	|	AND ExchangeDifferenceCalculation.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ExchangeDifferenceCalculation.Organization = &Organization
	|	AND ExchangeDifferenceCalculation.BusinessOperation = &BusinessOperation");
	
	BusinessOperation = Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting;
	If TheseAreSettlementsWithCustomers Then
		BusinessOperation = Enums.BusinessTransactions.RevaluationOfCustomersARAP;
	EndIf;
	Query.SetParameter("BeginOfPeriod", BegOfMonth(BeginOfPeriod));
	Query.SetParameter("EndOfPeriod", EndOfMonth(EndOfPeriod));
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RevaluationDocuments[Selection.Date] = Selection.Ref;
	EndDo;
	
	RevaluationByDays = Constants.RevalueCurrencyByDays.Get();
	For Each Recorder In RevaluationDocuments Do
		If Recorder.Value = Undefined Then
			DocumentObject_ = Documents.ExchangeDifferenceCalculation.CreateDocument();
			DocumentObject_.Date = EndOfMonth(Recorder.Key);
			DocumentObject_.Organization = Organization;
			DocumentObject_.BusinessOperation = BusinessOperation;
			DocumentObject_.RevaluationByDays = RevaluationByDays;
			DocumentObject_.Posted = True;
			DocumentObject_.Write();
			RevaluationDocuments[Recorder.Key] = DocumentObject_.Ref;
		EndIf;
	EndDo;
	
	Return RevaluationDocuments;
	
EndFunction

// Returns documents for calculating exchange rate differences for the specified period (one or any number of months)
// in the form of an indexed table of document values by month and organization.
// There can be only one document for calculating personnel differences in one period for one organization.
// If there is no completed document for an organization in any of the months, it will be created.
//
// Parameters:
//	CompanyArray - Array of CatalogRef.Companies - Array of organizations for which you need to get documents for calculating exchange rate differences
//	BeginOfPeriod - Date - Date start of the document selection period (will be shown by the beginning of the month)
//	EndOfPeriod - Date - End date of the document selection period (will be shown by the end of the month)
//	TheseAreSettlementsWithCustomers - Boolean - If True, then select revaluation documents by customer or by supplier
//
// Returns:
//	ValueTable - in the matching keys, the date of the beginning of the month, in the values of the document for calculating the exchange rate differences of the corresponding month:
//		* Date - Date - Revaluation period (Beginning of the month).
//		* Organization - CatalogRef.Companies - the owner of the document.
//		* Ref - DocumentRef.ExchangeDifferenceCalculation - the document of calculation of personnel differences.		
//
Function RevaluationDocumentsForOrganizations(CompanyArray, BeginOfPeriod, EndOfPeriod, TheseAreSettlementsWithCustomers) Export
	
	If BeginOfPeriod <= Date('19800101') Or Not ValueIsFilled(BeginOfPeriod) Then
		Raise NStr("vi = 'Đã xác định sai ngày bắt đầu tính toán chênh lệch tỷ giá.
		|Có thể, trong biểu ghi thông tin ""Nhiệm vụ chờ đóng tháng"" có ngày nhỏ hơn 01.01.1980';
		|ru = 'Задана некорректная дата начала расчета курсовых разниц.
		|Возможно в регистре сведений ""Задания к закрытию месяца"" имеются даты ранее 01.01.1980';
		|en = 'An incorrect start date for calculating exchange differences is set.
		|The ""Jobs for month-end closing"" information register might contain dates earlier than 01/01/1980'; fa = 'An incorrect start date for calculating exchange differences is set.
		|The ""Jobs for month-end closing"" information register might contain dates earlier than 01/01/1980';
		|it = 'Задана некорректная дата начала расчета курсовых разниц.
		|Возможно в регистре сведений ""Задания к закрытию месяца"" имеются даты ранее 01.01.1980';
		|pl = 'An incorrect start date for calculating exchange differences is set.
		|The ""Jobs for month-end closing"" information register might contain dates earlier than 01/01/1980';
		|tr = 'Kur farkı hesaplamasının başlangıç tarihi yanlış belirlendi.
		|""Ay sonu kapanış görevleri"" bilgi kaydında 01.01.1980''den daha önceki tarihler olması mümkündür'");
	EndIf;
	
	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = CurrentSessionDate();
	EndIf;
		
	Query = New Query(
	"SELECT
	|	BEGINOFPERIOD(ExchangeDifferenceCalculation.Date, MONTH) AS Date,
	|	ExchangeDifferenceCalculation.Organization AS Organization,
	|	ExchangeDifferenceCalculation.Ref AS Ref
	|FROM
	|	Document.ExchangeDifferenceCalculation AS ExchangeDifferenceCalculation
	|WHERE
	|	NOT ExchangeDifferenceCalculation.DeletionMark
	|	AND ExchangeDifferenceCalculation.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ExchangeDifferenceCalculation.Organization IN (&CompanyArray)
	|	AND ExchangeDifferenceCalculation.BusinessOperation = &BusinessOperation");
	
	BusinessOperation = Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting;
	If TheseAreSettlementsWithCustomers Then
		BusinessOperation = Enums.BusinessTransactions.RevaluationOfCustomersARAP;
	EndIf;
	Query.SetParameter("BeginOfPeriod", BegOfMonth(BeginOfPeriod));
	Query.SetParameter("EndOfPeriod", EndOfMonth(EndOfPeriod));
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	RevaluationDocuments = Query.Execute().Unload();
	
	RevaluationByDays = Constants.RevalueCurrencyByDays.Get();
	DifferenceOfMonths = Month(EndOfPeriod) - Month(BeginOfPeriod) + 12*(Year(EndOfPeriod) - Year(BeginOfPeriod));
	For MonthIndex = 0 To DifferenceOfMonths Do
		Period = AddMonth(BegOfMonth(BeginOfPeriod), MonthIndex);
		For Each Organization In CompanyArray Do
			DocumentSearchStructure = New Structure("Date, Organization", Period, Organization);
			FoundDocuments = RevaluationDocuments.FindRows(DocumentSearchStructure);// Array of ValueTableRow
			If FoundDocuments.Count() = 0 Then
				DocumentObject_ = Documents.ExchangeDifferenceCalculation.CreateDocument();
				DocumentObject_.Date = EndOfMonth(Period);
				DocumentObject_.Organization = Organization;
				DocumentObject_.BusinessOperation = BusinessOperation;
				DocumentObject_.RevaluationByDays = RevaluationByDays;
				DocumentObject_.Posted = True;
				DocumentObject_.Write();
				
				NewDocument = RevaluationDocuments.Add();
				NewDocument.Date = Period;
				NewDocument.Organization = Organization;
				NewDocument.Ref = DocumentObject_.Ref;
			EndIf;
		EndDo;		
	EndDo;
	
	RevaluationDocuments.Indexes.Add("Date");
	RevaluationDocuments.Indexes.Add("Organization");
	
	Return RevaluationDocuments;
	
EndFunction
// Returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ExchangeDifferenceCalculationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ExchangeDifferenceCalculationLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction
#Region CreatingTasksForEndOfMonth

// Complements the request text of the mechanism for generating monthly closing tasks.
//
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	
	MatchingRequests = MatchingRequestsToControlRegisters(Query);
	
	For Each MapItem In MatchingRequests Do
		MonthEndTransactionsServer.AddTableNamesForTasks(Query, MapItem.Key);
		MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
			MapItem.Value,
			Query.TempTablesManager.Tables,
			QueryText,
			TempTablesQueryText,
			TemporaryTableNames);
	EndDo;
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

#Region RevaluationOfCashAndFinancialInstruments

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_RevaluationOfCashAndFinancialInstruments(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RevaluationOfCashAndFinancialInstruments);
		
	NewRow.MultilingualName = "vi = 'Đánh giá lại tiền mặt và các công cụ tài chính';
								|ru = 'Переоценка денежных средств и финансовых инструментов';
								|en = 'Revaluate cash and financial instruments';
								|it = 'Rivalutazione dei fondi monetari e strumenti finanziari';
								|pl = 'Aktualizacja wartości środków pieniężnych i instrumentów finansowych';
								|tr = 'Nakit ve finansal araçların yeniden değerlemesi'"; // @NStr-1
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.ExchangeDifferenceCalculation.Use_RevaluationOfCashAndFinancialInstruments");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.ExchangeDifferenceCalculation.Registration_RevaluationOfCashAndFinancialInstruments");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.ExchangeDifferenceCalculation.Perform_RevaluationOfCashAndFinancialInstruments");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.ExchangeDifferenceCalculation.Forms.ListForm.FullName(), True);
EndProcedure

// Stage handlers.

Procedure Use_RevaluationOfCashAndFinancialInstruments(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không có kế toán đa tiền tệ';
				|ru = 'Мультивалютный учет не ведется';
				|en = 'Multicurrency accounting is not kept'; fa = 'Multicurrency accounting is not kept';
				|it = 'La contabilità multivaluta non viene mantenuta';
				|pl = 'Ewidencja wielowalutowa nie jest prowadzona';
				|tr = 'Çoklu para birimi muhasebesi yapılmıyor'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Reports.DetailedCalculationOfCurrencyRevaluation.FullName() + ".Form", True);
	ActionMoreDetails.FormParameters.Insert("GenerateOnOpen", True);
	ActionMoreDetails.FormParameters.Insert("AllCompanies", HandlerParameters.CalculationParameters.AllCompanies);
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters,True,,,ActionMoreDetails) Then
		Return;
	EndIf;
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	RegistersForCalculation = CalculationRegisters(Enums.BusinessTransactions.CashRevaluation);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	DimensionCalculation = New Structure("TypesOfAmounts", New Array);
	If GetFunctionalOption("UseLoanAndDepositContracts") Then
		RegistersForCalculation = CalculationRegisters(
			Enums.BusinessTransactions.RevaluationOfFinancialInstruments,
			RegistersForCalculation);
		DimensionCalculation.TypesOfAmounts = TypesOfAmountsOfLoansDepositsLoans();
	ElsIf GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		RegistersForCalculation.Insert("InvestmentInRent");
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	ReEvaluationRequired = ReEvaluationRequired(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation,
		DimensionCalculation);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	ThereAreCurrencyBalances = ThereAreCurrencyBalances(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation,
		DimensionCalculation);
		
	If ReEvaluationRequired Then
		
		MonthEndTransactionsServer.SetStateExecutedWithErrors(
			HandlerParameters,
			NStr("vi = 'Đã tìm thấy chênh lệch tỷ giá theo các biểu ghi kế toán vốn bằng tiền.';
				|ru = 'Обнаружены курсовые разницы по регистрам учета денежных средств.';
				|en = 'Exchange differences are found in cash management registers.'; fa = 'Exchange differences are found in cash management registers.';
				|it = 'Differenze di cambio rilevate nei registri di contabilità dei fondi monetari.';
				|pl = 'Wykryto różnice kursowe wg rejestrów ewidencji środków pieniężnych.';
				|tr = 'Kur farkları nakit kayıtları muhasebesinde bulundu.'", Common.DefaultLanguageCode()),
			MonthEndTransactionsServer.DefaultDetailsText(),
			ActionMoreDetails);
		
	ElsIf Not ThereAreCurrencyBalances Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư tiền tệ theo biểu ghi kế toán vốn bằng tiền.';
				|ru = 'Нет валютных остатков по регистрам учета денежных средств.';
				|en = 'No currency balance in cash management registers.'; fa = 'No currency balance in cash management registers.';
				|it = 'Non ci sono gli importi residui valutari nei registri della contabilità dei fondi monetari.';
				|pl = 'Brak sald walutowych wg rejestrów ewidencji środków pieniężnych.';
				|tr = 'Nakit kayıtları muhasebesinde para birimi bakiyeleri mevcut değil.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
	MonthEndTransactionsServer.SetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", ReEvaluationRequired);
	
EndProcedure

// Draws up the closing stage of the month for production without orders.
//
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Registration_RevaluationOfCashAndFinancialInstruments(HandlerParameters) Export
	
	If GetFunctionalOption("BaseVersion") Then
		HandlerParameters.Data_Stage.Description = NStr("vi = 'Đánh giá lại tiền mặt';
														|ru = 'Переоценка денежных средств';
														|en = 'Cash revaluation'; fa = 'تجدید ارزیابی نقد';
														|it = 'Rivalutazione dei fondi monetari';
														|pl = 'Przeszacowanie środków pieniężnych';
														|tr = 'Nakit yeniden değerleme'");
	EndIf;
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Thực hiện';
													|ru = 'Выполнить';
													|en = 'Run'; fa = 'اجرا';
													|it = 'Eseguire';
													|pl = 'Run';
													|tr = 'Yürüt'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

Procedure Perform_RevaluationOfCashAndFinancialInstruments(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	CalculationStart = MonthEndTransactionsServer.CalculationStart(
		HandlerParameters.Data_Stage.Code,
		HandlerParameters.CalculationParameters.EndOfPeriod,
		Undefined,
		CalculationParameters.CompanyArray);
	
	FirstPass  = True;
	
	ReEvaluationRequired = MonthEndTransactionsServer.GetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", False);
	ThereIsTaskForCalculation = (CalculationStart <= CalculationParameters.EndOfPeriod);
	
	If ReEvaluationRequired And Not ThereIsTaskForCalculation Then
		CalculationStart = CalculationParameters.EndOfPeriod; // recalculate only the specified month
	EndIf;
	
	While CalculationStart <= CalculationParameters.EndOfPeriod Or ReEvaluationRequired Do
		
		PeriodEnding = EndOfMonth(CalculationStart);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
		
		If ThereIsTaskForCalculation Then
			
			If FirstPass Then
				TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
			EndIf;
		
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, AvailableCompanies, HandlerParameters.Data_Stage.Code);
				
				MonthlyRevaluationData = MonthEndTransactionsServer.MonthlyTasks(
					CalculationStart,
					PeriodEnding,
					TaskNumberBeforeCalculation,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi thực hiện tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
		Else
			
			MonthlyRevaluationData = New Structure("Organization", AvailableCompanies);
			
		EndIf;
		
		Try
			RegistersForCalculation = CalculationRegisters(Enums.BusinessTransactions.CashRevaluation);
			OrganizationsToReevaluate = ReEvaluationRequired(
										AvailableCompanies, PeriodEnding, RegistersForCalculation,,True);
			CommonClientServer.SupplementArray(OrganizationsToReevaluate, MonthlyRevaluationData.Organization, True);
			
			RevalueCash(OrganizationsToReevaluate, CalculationStart);
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kết thúc đánh giá lại vốn bằng tiền trong kỳ %1 bị lỗi:
					|%2';
					|ru = 'Переоценка денежных средств за период %1 завершилась с ошибкой:
					|%2';
					|en = 'Cash revaluation for period %1 is completed with error:
					|%2'; fa = 'Cash revaluation for period %1 is completed with error:
					|%2';
					|it = 'Rivalutazione dei fondi monetari per il periodo %1 si è conclusa con un errore:
					|%2';
					|pl = 'Przeszacowanie środków pieniężnych za okres %1 jest zakończone z błędem:
					|%2';
					|tr = '%1''inci dönem için nakit yeniden değerlemesi hata ile bitti:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				MonthlyRevaluationData.Organization,
				CalculationStart);
			
		EndTry;
		
		Try
			AdditionalCondition = False;
			AdditionalCondition = GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25");
			If GetFunctionalOption("UseLoanAndDepositContracts")
				Or AdditionalCondition Then
				For Each Organization In MonthlyRevaluationData.Organization Do
					RevalueFinancialInstruments(Organization, CalculationStart);
				EndDo;
			EndIf;
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kết thúc đánh giá lại các công cụ tài chính trong kỳ %1 bị lỗi:
					|%2';
					|ru = 'Переоценка финансовых инструментов за период %1 завершилась с ошибкой:
					|%2';
					|en = 'Revaluation of financial instruments for the %1 period completed with an error:
					|%2'; fa = 'Revaluation of financial instruments for the %1 period completed with an error:
					|%2';
					|it = 'Переоценка финансовых инструментов за период %1 завершилась с ошибкой:
					|%2';
					|pl = 'Revaluation of financial instruments for the %1 period completed with an error:
					|%2';
					|tr = 'Finansal araçların %1 dönemine ilişkin yeniden değerlemesi hata ile tamamlandı:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				MonthlyRevaluationData.Organization,
				CalculationStart);
			
		EndTry;
		
		NextMonth = NextMonthForCalculationOfFunds(CalculationStart, AvailableCompanies);
		
		If ThereIsTaskForCalculation And HandlerParameters.ExplanationTable_.Count() = 0 Then
			
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(
					TaskNumberBeforeCalculation,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				MonthEndTransactionsServer.FixCalculation(
					NextMonth,
					HandlerParameters.Data_Stage.Code,
					MonthlyRevaluationData.TemporaryTable);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi thực hiện tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
		EndIf;
		
		If ThereIsTaskForCalculation And ValueIsFilled(NextMonth) Then
			CalculationStart = NextMonth;
		Else
			If ThereIsTaskForCalculation Then
				CalculationStart = EndOfMonth(CalculationStart) + 1; // next month
			Else
				CalculationStart = CalculationParameters.EndOfPeriod + 1; // exit the loop
			EndIf;
		EndIf;
		
		ReEvaluationRequired = False;
		FirstPass = False;
		
	EndDo;
	
EndProcedure

// Auxiliary methods of the stage.

Function NextMonthForCalculationOfFunds(CalculationPeriod, CompanyArray)
	
	Query = New Query;
	Query.Text =
	"SELECT 
	|	MIN(Cash.Month) AS MonthToPay
	|FROM
	|	(SELECT
	|		MIN(Cash.Period) AS Month
	|	FROM
	|		AccumulationRegister.BankAccountCash AS Cash
	|	WHERE
	|		(Cash.BankAccount.CashCurrency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.BankAccount.CashCurrency <> &CurrencyOfMan)
	|		AND Cash.Period > &ProcessedMonth_
	|		AND Cash.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&NextMonth AS Month
	|	FROM
	|		AccumulationRegister.BankAccountCash.Balance(
	|			&AtEndOfCalculatedMonth,
	|			Organization IN (&CompanyArray)
	|		) AS Cash
	|	WHERE
	|		Cash.BankAccount.CashCurrency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.BankAccount.CashCurrency <> &CurrencyOfMan
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(Cash.Period) AS Month
	|	FROM
	|		AccumulationRegister.CashInCashRegistersCR AS Cash
	|	WHERE
	|		(Cash.CashRegister.CashCurrency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.CashRegister.CashCurrency <> &CurrencyOfMan)
	|		AND Cash.Period > &ProcessedMonth_
	|		AND Cash.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&NextMonth AS Month
	|	FROM
	|		AccumulationRegister.CashInCashRegistersCR.Balance(
	|			&AtEndOfCalculatedMonth,
	|			Organization IN (&CompanyArray)
	|		) AS Cash
	|	WHERE
	|		Cash.CashRegister.CashCurrency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.CashRegister.CashCurrency <> &CurrencyOfMan
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(Cash.Period) AS Month
	|	FROM
	|		AccumulationRegister.CashInTransit AS Cash
	|	WHERE
	|		(Cash.Currency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.Currency <> &CurrencyOfMan)
	|		AND Cash.Period > &ProcessedMonth_
	|		AND Cash.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&NextMonth AS Month
	|	FROM
	|		AccumulationRegister.CashInTransit.Balance(
	|			&AtEndOfCalculatedMonth,
	|			Organization IN (&CompanyArray)
	|		) AS Cash
	|	WHERE
	|		Cash.Currency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.Currency <> &CurrencyOfMan
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(Cash.Period) AS Month
	|	FROM
	|		AccumulationRegister.CashAccountBalance AS Cash
	|	WHERE
	|		(Cash.CashAccount.CashCurrency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.CashAccount.CashCurrency <> &CurrencyOfMan)
	|		AND Cash.Period > &ProcessedMonth_
	|		AND Cash.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&NextMonth AS Month
	|	FROM
	|		AccumulationRegister.CashAccountBalance.Balance(
	|			&AtEndOfCalculatedMonth,
	|			Organization IN (&CompanyArray)
	|		) AS Cash
	|	WHERE
	|		(Cash.CashAccount.CashCurrency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.CashAccount.CashCurrency <> &CurrencyOfMan)
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(Cash.Period) AS Month
	|	FROM
	|		AccumulationRegister.AdvanceHolderCash AS Cash
	|	WHERE
	|		(Cash.Currency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.Currency <> &CurrencyOfMan)
	|		AND Cash.Period > &ProcessedMonth_
	|		AND Cash.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&NextMonth AS Month
	|	FROM
	|		AccumulationRegister.AdvanceHolderCash.Balance(
	|			&AtEndOfCalculatedMonth,
	|			Organization IN (&CompanyArray)
	|		) AS Cash
	|	WHERE
	|		Cash.SumBalance < 0
	|		AND (Cash.Currency <> Cash.Organization.LocalAccountingCurrency
	|			OR Cash.Currency <> &CurrencyOfMan)
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(FinancialInstruments.Period) AS Month
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP AS FinancialInstruments
	|	WHERE
	|		(FinancialInstruments.Currency <> FinancialInstruments.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
	|			OR FinancialInstruments.Currency <> &CurrencyOfMan)
	|		AND FinancialInstruments.Period > &ProcessedMonth_
	|		AND FinancialInstruments.AmountType IN (&TypesOfAmounts)
	|		AND FinancialInstruments.AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&NextMonth AS Month
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|			&AtEndOfCalculatedMonth,
	|			AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|			AND AmountType IN (&TypesOfAmounts)
	|		) AS FinancialInstruments
	|	WHERE
	|		FinancialInstruments.Currency <> FinancialInstruments.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
	|			OR FinancialInstruments.Currency <> &CurrencyOfMan
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(TasksForReevaluation.Month) AS Month
	|	FROM
	|		InformationRegister.JobsForMonthEndClosing AS TasksForReevaluation
	|	WHERE
	|		TasksForReevaluation.Month > &ProcessedMonth_
	|		AND TasksForReevaluation.Organization IN (&CompanyArray)
	|		AND TasksForReevaluation.Operation = VALUE(Catalog.MonthEndClosingOperations.RevaluationOfCashAndFinancialInstruments)
	|
	|	) AS Cash
	|HAVING 
	|	NOT (MIN(Cash.Month) IS NULL)";
	
	Query.SetParameter("CurrencyOfMan",                  Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("ProcessedMonth_",          EndOfMonth(CalculationPeriod));
	Query.SetParameter("NextMonth",             EndOfMonth(CalculationPeriod) + 1);
	Query.SetParameter("AtEndOfCalculatedMonth", New Boundary(EndOfMonth(CalculationPeriod), BoundaryType.Including));
	Query.SetParameter("CompanyArray",          CompanyArray);
	Query.SetParameter("TypesOfAmounts",                   TypesOfAmountsOfLoansDepositsLoans());
	
	Selection = Query.Execute().Select();
	
	Return ?(Selection.Next(), BegOfMonth(Selection.MonthToPay), Date(1, 1, 1));
	
EndFunction

#EndRegion

#Region RevaluationOfSettlementsWithCommitteeCommissionAgent

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_RevaluationOfSettlementsWithCommitteeCommissionAgent(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RevaluationOfConsignorPrincipalARAP);
		
	NewRow.MultilingualName = "vi = 'Đánh giá hạch toán với người đặt ký gửi';
								|ru = 'Переоценка расчетов с комитентом (принципалом)';
								|en = 'Revaluation of consignor (principal) AR/AP';
								|it = 'Revaluation of consignor (principal) AR/AP';
								|pl = 'Revaluation of consignor (principal) AR/AP';
								|tr = 'Göndericiyle (yöneticiyle) yapılan hesaplamaların yeniden değerlemesi'"; // @NStr-1
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.ExchangeDifferenceCalculation.Use_RevaluationOfSettlementsWithCommitteeCommissionAgent");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.ExchangeDifferenceCalculation.Registration_RevaluationOfSettlementsWithCommitteeCommissionAgent");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.ExchangeDifferenceCalculation.Perform_RevaluationOfSettlementsWithCommitteeCommissionAgent");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.ExchangeDifferenceCalculation.Forms.ListForm.FullName(), True);
EndProcedure

// Stage handlers.

Procedure Use_RevaluationOfSettlementsWithCommitteeCommissionAgent(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không có kế toán đa tiền tệ';
				|ru = 'Мультивалютный учет не ведется';
				|en = 'Multicurrency accounting is not kept'; fa = 'Multicurrency accounting is not kept';
				|it = 'La contabilità multivaluta non viene mantenuta';
				|pl = 'Ewidencja wielowalutowa nie jest prowadzona';
				|tr = 'Çoklu para birimi muhasebesi yapılmıyor'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	If Not GetFunctionalOption("UsePurchaseCommission")
		And Not GetFunctionalOption("UseBasePurchaseCommission")
		And Not GetFunctionalOption("UseSalesCommission")
		And Not GetFunctionalOption("UseBaseSalesCommission") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không sử dụng ký gửi khi bán hàng/mua hàng';
				|ru = 'Комиссия при продаже/закупке не используется';
				|en = 'Sales/purchasing commission is not used'; fa = 'Sales/purchasing commission is not used';
				|it = 'Комиссия при продаже/закупке не используется';
				|pl = 'Sales/purchasing commission is not used';
				|tr = 'Satış/satın alma komisyonları kullanılmamaktadır'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Reports.DetailedCalculationOfCurrencyRevaluation.FullName() + ".Form", True);
	ActionMoreDetails.FormParameters.Insert("GenerateOnOpen", True);
	ActionMoreDetails.FormParameters.Insert("AllCompanies", HandlerParameters.CalculationParameters.AllCompanies);
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters,True,,,ActionMoreDetails) Then
		Return;
	EndIf;
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	RegistersForCalculation = CalculationRegisters(Enums.BusinessTransactions.RevaluationOfConsignorPrincipalARAP);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	DimensionCalculation = Undefined;
	ReEvaluationRequired = ReEvaluationRequired(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation,
		DimensionCalculation);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	ThereAreCurrencyBalances = ThereAreCurrencyBalances(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation,
		DimensionCalculation);
		
	If ReEvaluationRequired Then
		
		MonthEndTransactionsServer.SetStateExecutedWithErrors(
			HandlerParameters,
			NStr("vi = 'Đã phát hiện chênh lệch tỷ giá theo công nợ với người đặt ký gửi (đại lý).';
				|ru = 'Обнаружены курсовые разницы по расчетам с комитентом (принципалом).';
				|en = 'Exchange differences for consignor (principal) AR/AP are found.'; fa = 'Exchange differences for consignor (principal) AR/AP are found.';
				|it = 'Обнаружены курсовые разницы по расчетам с комитентом (принципалом).';
				|pl = 'Exchange differences for consignor (principal) AR/AP are found.';
				|tr = 'Gönderici (tedarikçi) ile yapılan hesaplamalarda kur farkları tespit edildi.'", Common.DefaultLanguageCode()),
			MonthEndTransactionsServer.DefaultDetailsText(),
			ActionMoreDetails);
		
	ElsIf Not ThereAreCurrencyBalances Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có hạch toán tiền tệ với người đặt ký gửi (đại lý).';
				|ru = 'Нет валютных расчетов с комитентом (принципалом).';
				|en = 'There are no currency AR/AP with the consignor (principal).'; fa = 'There are no currency AR/AP with the consignor (principal).';
				|it = 'Нет валютных расчетов с комитентом (принципалом).';
				|pl = 'There are no currency AR/AP with the consignor (principal).';
				|tr = 'Gönderici (tedarikçi) ile herhangi bir para birimi mutabakatı yoktur.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
	MonthEndTransactionsServer.SetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", ReEvaluationRequired);
	
EndProcedure

// Draws up the closing stage of the month for production without orders.
//
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Registration_RevaluationOfSettlementsWithCommitteeCommissionAgent(HandlerParameters) Export
	
	If GetFunctionalOption("BaseVersion") Then
		HandlerParameters.Data_Stage.Description = NStr("vi = 'Đánh giá hạch toán với người đặt ký gửi/người nhận ký gửi';
														|ru = 'Переоценка расчетов с комитентом/комиссионером';
														|en = 'Revaluation of consignor/consignee AR/AP'; fa = 'Revaluation of consignor/consignee AR/AP';
														|it = 'Переоценка расчетов с комитентом/комиссионером';
														|pl = 'Revaluation of consignor/consignee AR/AP';
														|tr = 'Göndericiyle/konsinyeyle yapılan hesaplamaların yeniden değerlemesi'");
	EndIf;
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Thực hiện';
													|ru = 'Выполнить';
													|en = 'Run'; fa = 'اجرا';
													|it = 'Выполнить';
													|pl = 'Run';
													|tr = 'Gerçekleştir'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

Procedure Perform_RevaluationOfSettlementsWithCommitteeCommissionAgent(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	CalculationStart = MonthEndTransactionsServer.CalculationStart(
		HandlerParameters.Data_Stage.Code,
		HandlerParameters.CalculationParameters.EndOfPeriod,
		Undefined,
		CalculationParameters.CompanyArray);
	
	FirstPass  = True;
	
	ReEvaluationRequired = MonthEndTransactionsServer.GetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", False);
	ThereIsTaskForCalculation = (CalculationStart <= CalculationParameters.EndOfPeriod);
	
	If ReEvaluationRequired And Not ThereIsTaskForCalculation Then
		CalculationStart = CalculationParameters.EndOfPeriod; // recalculate only the specified month
	EndIf;
	
	While CalculationStart <= CalculationParameters.EndOfPeriod Or ReEvaluationRequired Do
		
		PeriodEnding = EndOfMonth(CalculationStart);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
		
		If ThereIsTaskForCalculation Then
			
			If FirstPass Then
				TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
			EndIf;
		
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, AvailableCompanies, HandlerParameters.Data_Stage.Code);
				
				MonthlyRevaluationData = MonthEndTransactionsServer.MonthlyTasks(
					CalculationStart,
					PeriodEnding,
					TaskNumberBeforeCalculation,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
		Else
			
			MonthlyRevaluationData = New Structure("Organization", AvailableCompanies);
			
		EndIf;
		
		Try
			RegistersForCalculation = CalculationRegisters(Enums.BusinessTransactions.RevaluationOfConsignorPrincipalARAP);
			OrganizationsToReevaluate = ReEvaluationRequired(
										AvailableCompanies, PeriodEnding, RegistersForCalculation,,True);
			CommonClientServer.SupplementArray(OrganizationsToReevaluate, MonthlyRevaluationData.Organization, True);
			
			ReevaluateCommissionCalculations(OrganizationsToReevaluate, CalculationStart);
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kết thúc đánh giá lại vốn bằng tiền trong kỳ %1 bị lỗi:
					|%2';
					|ru = 'Переоценка денежных средств за период %1 завершилась с ошибкой:
					|%2';
					|en = 'Cash revaluation for period %1 is completed with error:
					|%2'; fa = 'Cash revaluation for period %1 is completed with error:
					|%2';
					|it = 'Rivalutazione dei fondi monetari per il periodo %1 si è conclusa con un errore:
					|%2';
					|pl = 'Przeszacowanie środków pieniężnych za okres %1 jest zakończone z błędem:
					|%2';
					|tr = '%1''inci dönem için nakit yeniden değerlemesi hata ile bitti:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				MonthlyRevaluationData.Organization,
				CalculationStart);
			
		EndTry;
		
		NextMonth = EndOfMonth(CalculationStart) + 1;
		
		If ThereIsTaskForCalculation And HandlerParameters.ExplanationTable_.Count() = 0 Then
			
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(
					TaskNumberBeforeCalculation,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				MonthEndTransactionsServer.FixCalculation(
					NextMonth,
					HandlerParameters.Data_Stage.Code,
					MonthlyRevaluationData.TemporaryTable);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
		EndIf;
		
		If ThereIsTaskForCalculation And ValueIsFilled(NextMonth) Then
			CalculationStart = NextMonth;
		Else
			If ThereIsTaskForCalculation Then
				CalculationStart = EndOfMonth(CalculationStart) + 1; // next month
			Else
				CalculationStart = CalculationParameters.EndOfPeriod + 1; // exit the loop
			EndIf;
		EndIf;
		
		ReEvaluationRequired = False;
		FirstPass = False;
		
	EndDo;
	
EndProcedure

#EndRegion

//++ WE

 #Region RevaluationOfPayrollCalculations

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_PayrollCalculationRevaluation(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.PayrollCalculationRevaluation,True,,True);
		
	NewRow.MultilingualName = "ru = 'Переоценка расчетов по оплате труда';
								|vi = 'Payroll calculation revaluation';
								|en = 'Payroll calculation revaluation';
								|it = 'Payroll calculation revaluation';
								|pl = 'Payroll calculation revaluation';
								|tr = 'Bordro hesaplamalarının yeniden değerlemesi'"; // @NStr-1
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.ExchangeDifferenceCalculation.Use_RevaluationOfPayrollCalculations");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.ExchangeDifferenceCalculation.Registration_RevaluationOfPayrollCalculations");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.ExchangeDifferenceCalculation.Perform_RevaluationOfPayrollCalculations");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.ExchangeDifferenceCalculation.Forms.ListForm.FullName(), True);
EndProcedure

// Stage handlers.

Procedure Use_RevaluationOfPayrollCalculations(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không có kế toán đa tiền tệ';
				|ru = 'Мультивалютный учет не ведется';
				|en = 'Multicurrency accounting is not kept'; fa = 'Multicurrency accounting is not kept';
				|it = 'La contabilità multivaluta non viene mantenuta';
				|pl = 'Ewidencja wielowalutowa nie jest prowadzona';
				|tr = 'Çoklu para birimi muhasebesi yapılmıyor'", Common.DefaultLanguageCode()));
		Return;
		
	EndIf;
	
	ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Reports.DetailedCalculationOfCurrencyRevaluation.FullName() + ".Form", True);
	ActionMoreDetails.FormParameters.Insert("GenerateOnOpen", True);
	ActionMoreDetails.FormParameters.Insert("AllCompanies", HandlerParameters.CalculationParameters.AllCompanies);
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters,True,,,ActionMoreDetails) Then
		Return;
	EndIf;
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	RegistersForCalculation = CalculationRegisters(Enums.BusinessTransactions.PayrollCalculationRevaluation);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	DimensionCalculation = New Structure("TypesOfAmounts", "");
	ReEvaluationRequired = ReEvaluationRequired(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation,
		DimensionCalculation);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	ThereAreCurrencyBalances = ThereAreCurrencyBalances(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation,
		DimensionCalculation);
		
	If ReEvaluationRequired Then
		
		MonthEndTransactionsServer.SetStateExecutedWithErrors(
			HandlerParameters,
			NStr("ru = 'Обнаружены курсовые разницы по расчетам на оплату труда.';
				|vi = 'Exchange differences in payroll calculations are found.';
				|en = 'Exchange differences in payroll calculations are found.'; fa = 'Exchange differences in payroll calculations are found.';
				|it = 'Exchange differences in payroll calculations are found.';
				|pl = 'Exchange differences in payroll calculations are found.';
				|tr = 'Maaş ödemeleri hesaplamalarında kur farkları tespit edildi.'", Common.DefaultLanguageCode()),
			MonthEndTransactionsServer.DefaultDetailsText(),
			ActionMoreDetails);
		
	ElsIf Not ThereAreCurrencyBalances Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("ru = 'Нет валютных остатков по расчетам на оплату труда.';
				|vi = 'There are no currency balances for payroll calculations.';
				|en = 'There are no currency balances for payroll calculations.'; fa = 'There are no currency balances for payroll calculations.';
				|it = 'There are no currency balances for payroll calculations.';
				|pl = 'There are no currency balances for payroll calculations.';
				|tr = 'Maaş ödemeleri hesaplamalarında döviz bakiyesi bulunmamaktadır.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
	MonthEndTransactionsServer.SetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", ReEvaluationRequired);
	
EndProcedure

// Draws up the closing stage of the month for production without orders.
//
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Registration_RevaluationOfPayrollCalculations(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.TextExecute = NStr("ru = 'Выполнить';
													|vi = 'Run';
													|en = 'Run'; fa = 'اجرا';
													|it = 'Run';
													|pl = 'Run';
													|tr = 'Yürüt'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

Procedure Perform_RevaluationOfPayrollCalculations(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	CalculationStart = MonthEndTransactionsServer.CalculationStart(
		HandlerParameters.Data_Stage.Code,
		HandlerParameters.CalculationParameters.EndOfPeriod,
		Undefined,
		CalculationParameters.CompanyArray);
	
	FirstPass  = True;
	
	ReEvaluationRequired = MonthEndTransactionsServer.GetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", False);
	ThereIsTaskForCalculation = (CalculationStart <= CalculationParameters.EndOfPeriod);
	
	If ReEvaluationRequired And Not ThereIsTaskForCalculation Then
		CalculationStart = CalculationParameters.EndOfPeriod; // recalculate only the specified month
	EndIf;
	
	While CalculationStart <= CalculationParameters.EndOfPeriod Or ReEvaluationRequired Do
		
		PeriodEnding = EndOfMonth(CalculationStart);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
		
		If ThereIsTaskForCalculation Then
			
			If FirstPass Then
				TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
			EndIf;
		
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, AvailableCompanies, HandlerParameters.Data_Stage.Code);
				
				MonthlyRevaluationData = MonthEndTransactionsServer.MonthlyTasks(
					CalculationStart,
					PeriodEnding,
					TaskNumberBeforeCalculation,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken bir hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
		Else
			
			MonthlyRevaluationData = New Structure("Organization", AvailableCompanies);
			
		EndIf;
		
		Try
			RegistersForCalculation = CalculationRegisters(Enums.BusinessTransactions.PayrollCalculationRevaluation);
			OrganizationsToReevaluate = ReEvaluationRequired(AvailableCompanies, PeriodEnding,
										RegistersForCalculation, "", True);
			CommonClientServer.SupplementArray(OrganizationsToReevaluate, MonthlyRevaluationData.Organization, True);
			For Each Organization In OrganizationsToReevaluate Do
				ReevaluatePayrollCalculations(Organization, CalculationStart);
			EndDo;
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Переоценка остатков по расчетам по оплате труда за период %1 завершилась с ошибкой:
					|%2';
					|vi = 'An error occurred while revaluating payroll calculation balance for period %1:
					|%2';
					|en = 'An error occurred while revaluating payroll calculation balance for period %1:
					|%2'; fa = 'An error occurred while revaluating payroll calculation balance for period %1:
					|%2';
					|it = 'An error occurred while revaluating payroll calculation balance for period %1:
					|%2';
					|pl = 'An error occurred while revaluating payroll calculation balance for period %1:
					|%2';
					|tr = '%1 dönemi için maaş ödemeleri hesaplamalarındaki bakiyelerin yeniden değerlemesi hatayla sonuçlandı: 
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				MonthlyRevaluationData.Organization,
				CalculationStart);
			
		EndTry;
		
		NextMonth = NextMonthToCalculationOfWages(CalculationStart, AvailableCompanies);
		
		If ThereIsTaskForCalculation And HandlerParameters.ExplanationTable_.Count() = 0 Then
			
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(
					TaskNumberBeforeCalculation,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				MonthEndTransactionsServer.FixCalculation(
					NextMonth,
					HandlerParameters.Data_Stage.Code,
					MonthlyRevaluationData.TemporaryTable);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken bir hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
		EndIf;
		
		If ThereIsTaskForCalculation And ValueIsFilled(NextMonth) Then
			CalculationStart = NextMonth;
		Else
			If ThereIsTaskForCalculation Then
				CalculationStart = EndOfMonth(CalculationStart) + 1; // next month
			Else
				CalculationStart = CalculationParameters.EndOfPeriod + 1; // exit the loop
			EndIf;
		EndIf;
		
		ReEvaluationRequired = False;
		FirstPass = False;
		
	EndDo;
	
EndProcedure

#EndRegion
//-- WE
#Region RevaluationOfLeases

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_RevaluationOfLeases(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RevaluationOfLeases);
		
	NewRow.MultilingualName = "vi = 'Đánh giá lại công nợ tiền thuê';
								|ru = 'Переоценка взаиморасчетов по аренде';
								|en = 'Revaluation of lease AR/AP accounting';
								|it = 'Rivalutazione di pagamenti relativi all''affitto';
								|pl = 'Przeszacowanie rozliczeń wzajemnych z tytułu dzierżawy';
								|tr = 'Kira hesaplaşmalarının yeniden değerlemesi'"; // @NStr-1
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.ExchangeDifferenceCalculation.Use_RevaluationOfLeases");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.ExchangeDifferenceCalculation.Registration_RevaluationOfLease");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.ExchangeDifferenceCalculation.Perform_LeaseRevaluation");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.ExchangeDifferenceCalculation.Forms.ListForm.FullName(), True);
EndProcedure

// Stage handlers.

Procedure Use_RevaluationOfLeases(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không có kế toán đa tiền tệ';
				|ru = 'Мультивалютный учет не ведется';
				|en = 'Multicurrency accounting is not kept'; fa = 'Multicurrency accounting is not kept';
				|it = 'La contabilità multivaluta non viene mantenuta';
				|pl = 'Ewidencja wielowalutowa nie jest prowadzona';
				|tr = 'Çoklu para birimi muhasebesi yapılmıyor'", Common.DefaultLanguageCode()));
		Return;
		
	EndIf;
	
	ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Reports.DetailedCalculationOfCurrencyRevaluation.FullName() + ".Form", True);
	ActionMoreDetails.FormParameters.Insert("GenerateOnOpen", True);
	ActionMoreDetails.FormParameters.Insert("AllCompanies", HandlerParameters.CalculationParameters.AllCompanies);
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters,True,,,ActionMoreDetails) Then
		Return;
	EndIf;
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	RegistersForCalculation = CalculationRegisters(Enums.BusinessTransactions.RevaluationOfLeaseARAP);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	DimensionCalculation = New Structure("TypesOfAmounts", TypesOfLeasePaymentAmounts());
	ReEvaluationRequired = ReEvaluationRequired(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation,
		DimensionCalculation);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	ThereAreCurrencyBalances = ThereAreCurrencyBalances(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation,
		DimensionCalculation);
		
	If ReEvaluationRequired Then
		
		MonthEndTransactionsServer.SetStateExecutedWithErrors(
			HandlerParameters,
			NStr("vi = 'Đã tìm thấy chênh lệch tỷ giá theo hợp đồng thuê.';
				|ru = 'Обнаружены курсовые разницы по договорам аренды.';
				|en = 'Exchange differences under rental contracts are found.'; fa = 'Exchange differences under rental contracts are found.';
				|it = 'Sono stati rilevati differenze di tassi di cambio nei contratti di affitto.';
				|pl = 'Wykryto różnice kursowe według umów dzierżawy.';
				|tr = 'Kira sözleşmelerindeki kur farkları bulundu.'", Common.DefaultLanguageCode()),
			MonthEndTransactionsServer.DefaultDetailsText(),
			ActionMoreDetails);
		
	ElsIf Not ThereAreCurrencyBalances Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư ngoại tệ theo hợp đồng thuê.';
				|ru = 'Нет валютных остатков по договорам аренды.';
				|en = 'No currency balance under rental contracts.'; fa = 'No currency balance under rental contracts.';
				|it = 'Non esistono saldi in valuta dei contratti di affitto.';
				|pl = 'Brak reszt walutowych według umów dzierżawy.';
				|tr = 'Kira sözleşmeleri ilgili para bakiyesi bulunmamaktadır.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
	MonthEndTransactionsServer.SetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", ReEvaluationRequired);
	
EndProcedure

// Draws up the closing stage of the month for production without orders.
//
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Registration_RevaluationOfLease(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Thực hiện';
													|ru = 'Выполнить';
													|en = 'Run'; fa = 'اجرا';
													|it = 'Eseguire';
													|pl = 'Run';
													|tr = 'Yürüt'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

Procedure Perform_LeaseRevaluation(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	CalculationStart = MonthEndTransactionsServer.CalculationStart(
		HandlerParameters.Data_Stage.Code,
		HandlerParameters.CalculationParameters.EndOfPeriod,
		Undefined,
		CalculationParameters.CompanyArray);
	
	FirstPass  = True;
	
	ReEvaluationRequired = MonthEndTransactionsServer.GetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", False);
	ThereIsTaskForCalculation = (CalculationStart <= CalculationParameters.EndOfPeriod);
	
	If ReEvaluationRequired And Not ThereIsTaskForCalculation Then
		CalculationStart = CalculationParameters.EndOfPeriod; // recalculate only the specified month
	EndIf;
	
	While CalculationStart <= CalculationParameters.EndOfPeriod Or ReEvaluationRequired Do
		
		PeriodEnding = EndOfMonth(CalculationStart);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
		
		If ThereIsTaskForCalculation Then
			
			If FirstPass Then
				TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
			EndIf;
		
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, AvailableCompanies, HandlerParameters.Data_Stage.Code);
				
				MonthlyRevaluationData = MonthEndTransactionsServer.MonthlyTasks(
					CalculationStart,
					PeriodEnding,
					TaskNumberBeforeCalculation,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi thực hiện tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
		Else
			
			MonthlyRevaluationData = New Structure("Organization", AvailableCompanies);
			
		EndIf;
		
		Try
			RegistersForCalculation = CalculationRegisters(Enums.BusinessTransactions.RevaluationOfLeaseARAP);
			OrganizationsToReevaluate = ReEvaluationRequired(AvailableCompanies, PeriodEnding,
										RegistersForCalculation, TypesOfLeasePaymentAmounts(), True);
			CommonClientServer.SupplementArray(OrganizationsToReevaluate, MonthlyRevaluationData.Organization, True);
			For Each Organization In OrganizationsToReevaluate Do
				ReassessLeases(Organization, CalculationStart);
			EndDo;
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đánh giá lại số dư theo hợp đồng thuê trong kỳ %1 có lỗi:
					|%2';
					|ru = 'Переоценка остатков по договорам аренды за период %1 завершилась с ошибкой:
					|%2';
					|en = 'An error occurred while revaluating balance under the rental contract for period %1:
					|%2'; fa = 'An error occurred while revaluating balance under the rental contract for period %1:
					|%2';
					|it = 'La rivalutazione di residui dei contratti di affitto per il periodo %1 si è conclusa con un errore:
					|%2%';
					|pl = 'Przeszacowanie sald według umów dzierżawy za okres %1 zostało zakończone z błędem:
					|%2';
					|tr = '%1''inci dönem için kira bakiyelerinin yeniden değerlendirilmesi hata ile bitti:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				MonthlyRevaluationData.Organization,
				CalculationStart);
			
		EndTry;
		
		NextMonth = NextMonthToCalculateRent(CalculationStart, AvailableCompanies);
		
		If ThereIsTaskForCalculation And HandlerParameters.ExplanationTable_.Count() = 0 Then
			
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(
					TaskNumberBeforeCalculation,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				MonthEndTransactionsServer.FixCalculation(
					NextMonth,
					HandlerParameters.Data_Stage.Code,
					MonthlyRevaluationData.TemporaryTable);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi thực hiện tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
		EndIf;
		
		If ThereIsTaskForCalculation And ValueIsFilled(NextMonth) Then
			CalculationStart = NextMonth;
		Else
			If ThereIsTaskForCalculation Then
				CalculationStart = EndOfMonth(CalculationStart) + 1; // next month
			Else
				CalculationStart = CalculationParameters.EndOfPeriod + 1; // exit the loop
			EndIf;
		EndIf;
		
		ReEvaluationRequired = False;
		FirstPass = False;
		
	EndDo;
	
EndProcedure

// Auxiliary methods of the stage.

Function NextMonthToCalculateRent(CalculationPeriod, CompanyArray)
	
	Query = New Query;
	Query.Text =
	"SELECT 
	|	MIN(Cash.Month) AS MonthToPay
	|FROM
	|	(SELECT
	|		MIN(FinancialInstruments.Period) AS Month
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP AS FinancialInstruments
	|	WHERE
	|		(FinancialInstruments.Currency <> FinancialInstruments.AccountingDimensionByPartners.Organization
	|			OR FinancialInstruments.Currency <> &CurrencyOfMan)
	|		AND FinancialInstruments.Period > &ProcessedMonth_
	|		AND FinancialInstruments.AmountType IN (&TypesOfAmounts)
	|		AND FinancialInstruments.AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&NextMonth AS Month
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|			&AtEndOfCalculatedMonth,
	|			AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|			AND AmountType IN (&TypesOfAmounts)
	|		) AS FinancialInstruments
	|	WHERE
	|		FinancialInstruments.Currency <> FinancialInstruments.AccountingDimensionByPartners.Organization
	|			OR FinancialInstruments.Currency <> &CurrencyOfMan
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(TasksForReevaluation.Month) AS Month
	|	FROM
	|		InformationRegister.JobsForMonthEndClosing AS TasksForReevaluation
	|	WHERE
	|		TasksForReevaluation.Month > &ProcessedMonth_
	|		AND TasksForReevaluation.Organization IN (&CompanyArray)
	|		AND TasksForReevaluation.Operation = VALUE(Catalog.MonthEndClosingOperations.RevaluationOfCashAndFinancialInstruments)
	|
	|	) AS Cash
	|HAVING 
	|	NOT (MIN(Cash.Month) IS NULL)";
	
	Query.SetParameter("CurrencyOfMan",                  Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("ProcessedMonth_",          EndOfMonth(CalculationPeriod));
	Query.SetParameter("NextMonth",             EndOfMonth(CalculationPeriod) + 1);
	Query.SetParameter("AtEndOfCalculatedMonth", New Boundary(EndOfMonth(CalculationPeriod), BoundaryType.Including));
	Query.SetParameter("CompanyArray",          CompanyArray);
	Query.SetParameter("TypesOfAmounts",                   TypesOfLeasePaymentAmounts());
	
	Selection = Query.Execute().Select();
	
	Return ?(Selection.Next(), BegOfMonth(Selection.MonthToPay), Date(1, 1, 1));
	
EndFunction

#EndRegion
#EndRegion

#EndRegion

#Region Private

//++ WE

// Auxiliary methods of the stage.
Function NextMonthToCalculationOfWages(CalculationPeriod, CompanyArray)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MIN(Cash.Month) AS MonthToPay
	|FROM
	|	(SELECT
	|		MIN(PayrollCalculationsHR.Period) AS Month,
	|		PayrollCalculationsHR.Organization AS Organization
	|	FROM
	|		AccumulationRegister.PayrollCalculationsHR AS PayrollCalculationsHR
	|	WHERE
	|		PayrollCalculationsHR.Period > &ProcessedMonth_
	|		AND PayrollCalculationsHR.Organization IN(&CompanyArray)
	|	
	|	GROUP BY
	|		PayrollCalculationsHR.Organization
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&NextMonth,
	|		PayrollCalculationsHR.Organization
	|	FROM
	|		AccumulationRegister.PayrollCalculationsHR.Balance(&AtEndOfCalculatedMonth, Organization IN (&CompanyArray)) AS PayrollCalculationsHR
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MIN(TasksForReevaluation.Month),
	|		NULL
	|	FROM
	|		InformationRegister.JobsForMonthEndClosing AS TasksForReevaluation
	|	WHERE
	|		TasksForReevaluation.Month > &ProcessedMonth_
	|		AND TasksForReevaluation.Organization IN(&CompanyArray)
	|		AND TasksForReevaluation.Operation = VALUE(Catalog.MonthEndClosingOperations.PayrollCalculationRevaluation)) AS Cash
	|
	|HAVING
	|	NOT MIN(Cash.Month) IS NULL";
	
	Query.SetParameter("ProcessedMonth_",          EndOfMonth(CalculationPeriod));
	Query.SetParameter("NextMonth",             EndOfMonth(CalculationPeriod) + 1);
	Query.SetParameter("AtEndOfCalculatedMonth", New Boundary(EndOfMonth(CalculationPeriod), BoundaryType.Including));
	Query.SetParameter("CompanyArray",          CompanyArray);
	
	Selection = Query.Execute().Select();
	
	Return ?(Selection.Next(), BegOfMonth(Selection.MonthToPay), Date(1, 1, 1));
	
EndFunction

//-- WE

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Date,
	|	DocumentData.Organization,
	|	ISNULL(DocumentData.Organization.ParentCompany, DocumentData.Organization) AS ParentCompany,
	|	DocumentData.BusinessOperation,
	|	DocumentData.RevaluationByDays,
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashRevaluation)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS RevaluationOfCash,
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfVendorsARAPAccounting)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS RevaluationOfVendorsARAPAccounting,
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfCustomersARAP)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS RevaluationOfCustomersARAP,
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfFinancialInstruments)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS RevaluationOfFinancialInstruments,
	//++ WE
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PayrollCalculationRevaluation)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS RevaluationPayrollCalculations,
	//-- WE
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	DocumentData.Number AS Number,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark
	|
	|FROM
	|	Document.ExchangeDifferenceCalculation AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	BeginOfPeriod = BegOfMonth(Attributes.Date);
	EndOfPeriod = EndOfMonth(Attributes.Date);
	Query.SetParameter("BeginOfPeriod",                         BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",                          EndOfPeriod);
	Query.SetParameter("EndOfMonth",                           EndOfPeriod);
	Query.SetParameter("BorderStartOfPeriod",                  New Boundary(BeginOfPeriod, BoundaryType.Including));
	Query.SetParameter("BorderEndOfPeriod",                   New Boundary(EndOfPeriod,  BoundaryType.Including));
	Query.SetParameter("Organization",                           Attributes.Organization);
	Query.SetParameter("ParentCompany",                   Attributes.ParentCompany);
	Query.SetParameter("OrderDivision",                    Undefined);
	Query.SetParameter("BusinessOperation",                 Attributes.BusinessOperation);
	Query.SetParameter("BusinessTransactionSetting",        Attributes.BusinessTransactionSetting);
	Query.SetParameter("ManagementAccountingCurrency",            Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("LocalAccountingCurrency",        SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("RevaluationByDays",                      Attributes.RevaluationByDays);
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", Constants.UseAccountingOfOtherIncomeExpenses.Get());
	Query.SetParameter("DimensionCalculation",
		InformationRegisters.AccountingDimensionByPartners.OrganizationAnalyticsKeys(Attributes.Organization));
	Query.SetParameter("CashAccounts",                                 Undefined);
	Query.SetParameter("ForAllSalesRegisters",                          True);
	Query.SetParameter("AdvanceHolders",                       Undefined);
	Query.SetParameter("ForAllAccountablePersons",                True);
	Query.SetParameter("DepositPayment",                 Undefined);
	Query.SetParameter("NatureOfLeaseContract",                Enums.ContractKindsOfFinancialInstruments.Lease);
	Query.SetParameter("NatureOfContractDeposit",               Enums.ContractKindsOfFinancialInstruments.Deposit);
	Query.SetParameter("NatureOfContractLoanIssued",          Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing);
	Query.SetParameter("TypesOfAmounts",                              TypesOfAmountsOfLoansDepositsLoans());
	Query.SetParameter("ForAllTypesOfAmounts",                       False);
	Query.SetParameter("ItSLease",                             False);
	Query.SetParameter("DepositPayment",                 Enums.TypesOfLeasePayments.DepositPayment);
	Query.SetParameter("ReverseReflectionOfExpenses",             TypesOfAmountsOfReverseReflectionOfExpenses());
	If Attributes.BusinessOperation = Enums.BusinessTransactions.RevaluationOfLeaseARAP Then
		Query.SetParameter("ItSLease", True);
		Query.SetParameter("TypesOfAmounts", TypesOfLeasePaymentAmounts());
	EndIf;
	Query.SetParameter("UseLocal",GetFunctionalOption("UseLocal"));
	Query.SetParameter("OperationProcedure", OnlineARAPAccountingServer.Order(EndOfPeriod,"",Type("DocumentRef.ExchangeDifferenceCalculation"),"9","99"));
		
	CustomerPayment = New Array;
	CustomerPayment.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
	CustomerPayment.Add(Enums.BusinessTransactions.RepaymentOfCustomerReceivables);
	CustomerPayment.Add(Enums.BusinessTransactions.ARWriteOff);
	CustomerPayment.Add(Enums.BusinessTransactions.APWriteOff);
	CustomerPayment.Add(Enums.BusinessTransactions.ARAPSettlement);
	Query.SetParameter("CustomerPayment", CustomerPayment);
	
	PaymentToVendor = New Array;
	PaymentToVendor.Add(Enums.BusinessTransactions.PaymentToVendor);
	PaymentToVendor.Add(Enums.BusinessTransactions.AccountsPayableRepayment);
	PaymentToVendor.Add(Enums.BusinessTransactions.ARWriteOff);
	PaymentToVendor.Add(Enums.BusinessTransactions.APWriteOff);
	PaymentToVendor.Add(Enums.BusinessTransactions.ARAPSettlement);
	Query.SetParameter("PaymentToVendor", PaymentToVendor);
	
	Query.SetParameter("RegisterNames", CalculationRegisters(Attributes.BusinessOperation));
	
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.ExchangeDifferenceCalculation"));
	Query.SetParameter("Number", Attributes.Number);
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("Comment", Attributes.Comment);
	Query.SetParameter("Posted", Attributes.Posted);
	Query.SetParameter("DeletionMark", Attributes.DeletionMark);
	Query.SetParameter("Period", Attributes.Date);
	Query.SetParameter("ReFillingTARegisters", False);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function RequestTextTTTableSettlementsWithClientsByTerms(QueryTexts)

	RegisterName = "TableSettlementsWithCustomers";
	
	QueryText = 
	"SELECT
	|	CalculationsAccordingToDocuments.RecordType,
	|	CalculationsAccordingToDocuments.Currency AS Currency,
	|	CalculationsAccordingToDocuments.Period AS Period,
	|	CalculationsAccordingToDocuments.AccountingDimensionByPartners,
	|	ISNULL(CalculationsAccordingToDocuments.ARAPObject.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	CalculationsAccordingToDocuments.ARAPObject AS ARAPObject,
	|	CalculationsAccordingToDocuments.ARAPDocument,
	|	CalculationsAccordingToDocuments.DebtLocal AS DebtLocal,
	|	CalculationsAccordingToDocuments.ARAPMan AS ARAPMan,
	|	CalculationsAccordingToDocuments.PrepaymentLocal AS PrepaymentLocal,
	|	CalculationsAccordingToDocuments.PrepaymentMan AS PrepaymentMan,
	|	CalculationsAccordingToDocuments.FinRecordID AS FinRecordID,
	|	CalculationsAccordingToDocuments.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TableSettlementsWithCustomers
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsAccordingToDocuments
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfCustomersARAP)
	|	AND VALUETYPE(CalculationsAccordingToDocuments.DocumentRecorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND CalculationsAccordingToDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CalculationsAccordingToDocuments.AccountingDimensionByPartners IN (&DimensionCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTTTableSettlementsWithSuppliersByTerms(QueryTexts)

	RegisterName = "TableSettlementsWithSuppliers";

	QueryText =
	"SELECT
	|	CalculationsAccordingToDocuments.RecordType,
	|	CalculationsAccordingToDocuments.Currency AS Currency,
	|	CalculationsAccordingToDocuments.Period AS Period,
	|	CalculationsAccordingToDocuments.AccountingDimensionByPartners,
	|	ISNULL(CalculationsAccordingToDocuments.ARAPObject.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	CalculationsAccordingToDocuments.ARAPObject AS ARAPObject,
	|	CalculationsAccordingToDocuments.ARAPDocument,
	|	CalculationsAccordingToDocuments.ARAPMan AS ARAPMan,
	|	CalculationsAccordingToDocuments.DebtLocal AS DebtLocal,
	|	CalculationsAccordingToDocuments.PrepaymentLocal AS PrepaymentLocal,
	|	CalculationsAccordingToDocuments.PrepaymentMan AS PrepaymentMan,
	|	CalculationsAccordingToDocuments.FinRecordID AS FinRecordID,
	|	CalculationsAccordingToDocuments.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TableSettlementsWithSuppliers
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsAccordingToDocuments
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfVendorsARAPAccounting)
	|	AND VALUETYPE(CalculationsAccordingToDocuments.DocumentRecorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND CalculationsAccordingToDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CalculationsAccordingToDocuments.AccountingDimensionByPartners IN (&DimensionCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTTTableSettlementsWithSuppliersBasedOnDocuments(QueryTexts)

	RegisterName = "TableSettlementsWithSuppliers";

	QueryText =
	"SELECT
	|	CalculationsAccordingToDocuments.RecordType,
	|	CalculationsAccordingToDocuments.Currency AS Currency,
	|	CalculationsAccordingToDocuments.Period AS Period,
	|	CalculationsAccordingToDocuments.AccountingDimensionByPartners,
	|	CalculationsAccordingToDocuments.PurchaseOrder.Department AS Department,
	|	CalculationsAccordingToDocuments.PurchaseOrder AS ARAPObject,
	|	CalculationsAccordingToDocuments.ARAPDocument,
	|	-CalculationsAccordingToDocuments.ARAPMan AS ARAPMan,
	|	-CalculationsAccordingToDocuments.DebtLocal AS DebtLocal,
	|	CalculationsAccordingToDocuments.PrepaymentLocal AS PrepaymentLocal,
	|	CalculationsAccordingToDocuments.PrepaymentMan AS PrepaymentMan,
	|	"""" AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting
	|
	|INTO TableSettlementsWithSuppliers
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS CalculationsAccordingToDocuments
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfVendorsARAPAccounting)
	|	AND VALUETYPE(CalculationsAccordingToDocuments.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND CalculationsAccordingToDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CalculationsAccordingToDocuments.AccountingDimensionByPartners IN (&DimensionCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTTTableSettlementsWithClientsByDocuments(QueryTexts)

	RegisterName = "TableSettlementsWithCustomers";
	
	QueryText = 
	"SELECT
	|	CalculationsAccordingToDocuments.RecordType,
	|	CalculationsAccordingToDocuments.Currency AS Currency,
	|	CalculationsAccordingToDocuments.Period AS Period,
	|	CalculationsAccordingToDocuments.AccountingDimensionByPartners,
	|	CalculationsAccordingToDocuments.SalesOrder.Department AS Department,
	|	CalculationsAccordingToDocuments.SalesOrder AS ARAPObject,
	|	CalculationsAccordingToDocuments.ARAPDocument,
	|	CalculationsAccordingToDocuments.PaymentDate,
	|	CalculationsAccordingToDocuments.DebtLocal AS DebtLocal,
	|	CalculationsAccordingToDocuments.ARAPMan AS ARAPMan,
	|	-CalculationsAccordingToDocuments.PrepaymentLocal AS PrepaymentLocal,
	|	-CalculationsAccordingToDocuments.PrepaymentMan AS PrepaymentMan,
	|	"""" AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting
	|
	|INTO TableSettlementsWithCustomers
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS CalculationsAccordingToDocuments
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfCustomersARAP)
	|	AND VALUETYPE(CalculationsAccordingToDocuments.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND CalculationsAccordingToDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CalculationsAccordingToDocuments.AccountingDimensionByPartners IN (&DimensionCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTTTableCashNonCash(QueryTexts)

	RegisterName = "TableCashless";
	
	QueryText = 
	"SELECT
	|	Cash.RecordType,
	|	Cash.Period AS Period,
	|	Cash.Organization,
	|	Cash.BankAccount AS BankAccount,
	|	Cash.BankAccount.Department AS Department,
	|	Cash.BankAccount.LineOfBusiness AS LineOfBusiness,
	|	Cash.SumMan AS SumMan,
	|	Cash.SumCompl AS SumCompl,
	|	Cash.BusinessOperation AS BusinessOperation,
	|	Cash.CashFlowItem  AS CashFlowItem,
	|	Cash.FinRecordID         AS FinRecordID,
	|	Cash.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableCashless
	|FROM
	|	AccumulationRegister.BankAccountCash AS Cash
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CashRevaluation)
	|	AND VALUETYPE(Cash.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND Cash.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Cash.Organization = &Organization";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTTTableCashCash(QueryTexts)

	RegisterName = "TableCashCash";
	
	QueryText = 
	"SELECT
	|	Cash.RecordType,
	|	Cash.Period AS Period,
	|	Cash.Organization,
	|	Cash.CashAccount AS CashAccount,
	|	Cash.CashAccount.Department AS Department,
	|	Cash.CashAccount.LineOfBusiness AS LineOfBusiness,
	|	Cash.SumMan AS SumMan,
	|	Cash.SumCompl AS SumCompl,
	|	Cash.BusinessOperation AS BusinessOperation,
	|	Cash.CashFlowItem  AS CashFlowItem,
	|	Cash.FinRecordID         AS FinRecordID,
	|	Cash.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableCashCash
	|FROM
	|	AccumulationRegister.CashAccountBalance AS Cash
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CashRevaluation)
	|	AND VALUETYPE(Cash.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND Cash.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Cash.Organization = &Organization";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTTTableCashInCashRegistersCashRegister(QueryTexts)

	RegisterName = "TableCashInCashCashRegisters";
	
	QueryText = 
	"SELECT
	|	Cash.RecordType,
	|	Cash.Period AS Period,
	|	Cash.Organization,
	|	Cash.CashRegister AS CashRegister,
	|	Cash.CashRegister.Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	Cash.SumMan AS SumMan,
	|	Cash.SumCompl AS SumCompl,
	|	Cash.FinRecordID         AS FinRecordID,
	|	Cash.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableCashInCashCashRegisters
	|FROM
	|	AccumulationRegister.CashInCashRegistersCR AS Cash
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CashRevaluation)
	|	AND VALUETYPE(Cash.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND Cash.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Cash.Organization = &Organization";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTTTableFundsHeldByAccountablePersons(QueryTexts)

	RegisterName = "TableCashHeldByAccountablePersons";
	
	QueryText = 
	"SELECT
	|	Cash.RecordType,
	|	Cash.Period AS Period,
	|	Cash.Organization,
	|	Cash.AdvanceHolder AS AdvanceHolder,
	|	Cash.Department AS Department,
	|	Cash.IssuancePurpose AS IssuancePurpose,
	|	Cash.Currency AS Currency,
	|	Cash.SumMan AS SumMan,
	|	Cash.SumCompl AS SumCompl,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	Cash.BusinessOperation AS BusinessOperation,
	|	Cash.CashFlowItem  AS CashFlowItem,
	|	Cash.FinRecordID         AS FinRecordID,
	|	Cash.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableCashHeldByAccountablePersons
	|FROM
	|	AccumulationRegister.AdvanceHolderCash AS Cash
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CashRevaluation)
	|	AND VALUETYPE(Cash.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND Cash.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Cash.Organization = &Organization";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTTCashInTransitTable(QueryTexts)

	RegisterName = "TableCashInTransit";
	
	QueryText = 
	"SELECT
	|	Cash.Period AS Period,
	|	Cash.Organization,
	|	ISNULL(Cash.Recipient.Department,
	|			VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	ISNULL(Cash.Recipient.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	Cash.CashTransferKind AS CashTransferKind,
	|	Cash.Counterparty AS Counterparty,
	|	Cash.Contract AS Contract,
	|	Cash.Currency AS Currency,
	|	SUM(CASE WHEN Cash.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -Cash.SumMan
	|			ELSE Cash.SumMan
	|	END) AS SumMan,
	|	SUM(
	|		CASE WHEN Cash.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -Cash.SumCompl
	|			ELSE Cash.SumCompl
	|		END) AS SumCompl,
	|	Cash.FinRecordID         AS FinRecordID,
	|	Cash.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TTCashInTransit
	|FROM
	|	AccumulationRegister.CashInTransit AS Cash
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CashRevaluation)
	|	AND VALUETYPE(Cash.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND Cash.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Cash.Organization = &Organization
	|
	|GROUP BY
	|	Cash.Period,
	|	Cash.Organization,
	|	ISNULL(Cash.Recipient.Department,
	|			VALUE(Catalog.BusinessStructure.EmptyRef)),
	|	ISNULL(Cash.Recipient.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	|	Cash.CashTransferKind,
	|	Cash.Counterparty,
	|	Cash.Contract,
	|	Cash.Currency,
	|	Cash.FinRecordID,
	|	Cash.BusinessTransactionSetting";
	QueryTexts.Add(QueryText, "TTCashInTransit");
	
	QueryText = 
	"SELECT
	|	CASE WHEN Cash.SumMan > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|			ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	Cash.Period AS Period,
	|	Cash.Organization,
	|	Cash.Department AS Department,
	|	Cash.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS Recipient,
	|	UNDEFINED AS Sender,
	|	Cash.CashTransferKind AS CashTransferKind,
	|	Cash.Counterparty AS Counterparty,
	|	Cash.Contract AS Contract,
	|	Cash.Currency AS Currency,
	|	CASE WHEN Cash.SumMan > 0
	|			THEN Cash.SumMan
	|			ELSE -Cash.SumMan
	|	END AS SumMan,
	|	0 AS SumCompl,
	|	CASE WHEN Cash.SumMan > 0
	|			THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|			ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END AS CashFlowItem,
	|	Cash.FinRecordID         AS FinRecordID,
	|	Cash.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableCashInTransit
	|FROM
	|	TTCashInTransit AS Cash
	|WHERE
	|	Cash.SumMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	CASE WHEN Cash.SumCompl > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|			ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	Cash.Period AS Period,
	|	Cash.Organization,
	|	Cash.Department AS Department,
	|	Cash.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS Recipient,
	|	UNDEFINED AS Sender,
	|	Cash.CashTransferKind AS CashTransferKind,
	|	Cash.Counterparty AS Counterparty,
	|	Cash.Contract AS Contract,
	|	Cash.Currency AS Currency,
	|	0 AS SumMan,
	|	CASE WHEN Cash.SumCompl > 0
	|			THEN Cash.SumCompl
	|			ELSE -Cash.SumCompl
	|	END AS SumCompl,
	|	CASE WHEN Cash.SumCompl > 0
	|			THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|			ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END AS CashFlowItem,
	|	Cash.FinRecordID         AS FinRecordID,
	|	Cash.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTCashInTransit AS Cash
	|WHERE
	|	Cash.SumCompl <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableFinancialInstruments(QueryTexts)

	RegisterName = "TableFinancialInstruments";
	
	QueryText = 
	"SELECT
	|	FinancialInstruments.RecordType,
	|	FinancialInstruments.Period AS Period,
	|	FinancialInstruments.AccountingDimensionByPartners,
	|	FinancialInstruments.Contract AS Contract,
	|	FinancialInstruments.Contract.Department AS Department,
	|	FinancialInstruments.Contract.LineOfBusiness AS LineOfBusiness,
	|	CASE WHEN VALUETYPE(FinancialInstruments.Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|		THEN CAST(FinancialInstruments.Contract AS Catalog.LoanAndDepositContracts).ContractKind
	|		WHEN VALUETYPE(FinancialInstruments.Contract) = TYPE(Catalog.LeaseContract)
	|		THEN VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|		ELSE UNDEFINED
	|	END AS ContractKind,
	|	FinancialInstruments.AmountType AS AmountType,
	|	FinancialInstruments.Contract.ARAPCurrency AS Currency,
	|	FinancialInstruments.Sum AS Sum,
	|	FinancialInstruments.SumMan AS SumMan,
	|	FinancialInstruments.SumCompl AS SumCompl,
	|	FinancialInstruments.FinRecordID AS FinRecordID,
	|	FinancialInstruments.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableFinancialInstruments
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS FinancialInstruments
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON FinancialInstruments.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	(&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfFinancialInstruments)
	|		AND VALUETYPE(FinancialInstruments.Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|	OR &BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfLeaseARAP)
	|		AND VALUETYPE(FinancialInstruments.Contract) = TYPE(Catalog.LeaseContract)
	|	) AND FinancialInstruments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Dimension.Organization = &Organization
	|	AND VALUETYPE(FinancialInstruments.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Function RequestTextTTTableProvisionsForDoubtfulDebts(QueryTexts)

	RegisterName = "TableProvisionsForDoubtfulDebts";
	
	QueryText = 
	"SELECT
	|	DebtReserves.RecordType,
	|	DebtReserves.Period AS Period,
	|	DebtReserves.AccountingDimensionByPartners,
	|	DebtReserves.ARAPObject AS ARAPObject,
	|	ISNULL(DebtReserves.ARAPObject.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	ISNULL(DebtReserves.ARAPObject.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	DebtReserves.ARAPDocument AS ARAPDocument,
	|	DebtReserves.AmountType AS AmountType,
	|	DebtReserves.Currency AS Currency,
	|	DebtReserves.Sum AS Sum,
	|	DebtReserves.SumMan AS SumMan,
	|	DebtReserves.SumCompl AS SumCompl,
	|	DebtReserves.FinRecordID         AS FinRecordID,
	|	DebtReserves.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableProvisionsForDoubtfulDebts
	|FROM
	|	AccumulationRegister.LossAllowance AS DebtReserves
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON DebtReserves.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfLossAllowance)
	|	AND VALUETYPE(DebtReserves.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND DebtReserves.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DebtReserves.AccountingDimensionByPartners IN (&DimensionCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
//++ WE
Function QueryTextPayrollCalculations(QueryTexts)

	RegisterName = "TableHRPayrollCalculations";
	
	QueryText = 
	"SELECT
	|	PayrollCalculationsHR.RecordType AS RecordType,
	|	PayrollCalculationsHR.Period AS Period,
	|	PayrollCalculationsHR.Organization AS Organization,
	|	PayrollCalculationsHR.ARAPType AS ARAPType,
	|	ISNULL(PayrollCalculationsHR.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	PayrollCalculationsHR.Sum AS Sum,
	|	PayrollCalculationsHR.SumMan AS SumMan,
	|	PayrollCalculationsHR.SumCompl AS SumCompl,
	|	PayrollCalculationsHR.FinRecordID AS FinRecordID,
	|	PayrollCalculationsHR.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	PayrollCalculationsHR.Individual AS Individual
	|INTO PayrollCalculationsHR
	|FROM
	|	AccumulationRegister.PayrollCalculationsHR AS PayrollCalculationsHR
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.PayrollCalculationRevaluation)
	|	AND VALUETYPE(PayrollCalculationsHR.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND PayrollCalculationsHR.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollCalculationsHR.RecordType AS RecordType,
	|	PayrollCalculationsHR.Period AS Period,
	|	PayrollCalculationsHR.Organization AS Organization,
	|	PayrollCalculationsHR.ARAPType AS ARAPType,
	|	PayrollCalculationsHR.Department AS Department,
	|	PayrollCalculationsHR.LineOfBusiness AS LineOfBusiness,
	|	PayrollCalculationsHR.Sum AS Sum,
	|	PayrollCalculationsHR.SumMan AS SumMan,
	|	PayrollCalculationsHR.SumCompl AS SumCompl,
	|	PayrollCalculationsHR.FinRecordID AS FinRecordID,
	|	PayrollCalculationsHR.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	PayrollCalculationsHR.Individual AS Individual
	|FROM
	|	PayrollCalculationsHR AS PayrollCalculationsHR";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
//-- WE
Function RequestTextTTTableOfDiscountAmounts(QueryTexts)

	RegisterName = "TableOfDiscountAmounts";
	
	QueryText = 
	"SELECT
	|	InterestExpense.RecordType AS RecordType,
	|	InterestExpense.Period AS Period,
	|	InterestExpense.AccountingDimensionByPartners,
	|	InterestExpense.ARAPObject AS ARAPObject,
	|	InterestExpense.ARAPObject.Contract AS Contract,
	|	InterestExpense.ARAPObject.Department AS Department,
	|	InterestExpense.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	InterestExpense.ARAPDocument AS ARAPDocument,
	|	InterestExpense.Currency AS Currency,
	|	InterestExpense.DiscountingAmount AS Sum,
	|	InterestExpense.DiscountingAmountMan AS SumMan,
	|	InterestExpense.DiscountingAmountCompl AS SumCompl,
	|	InterestExpense.FinRecordID AS FinRecordID,
	|	InterestExpense.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableOfDiscountAmounts
	|FROM
	|	AccumulationRegister.DiscountInterestExpense AS InterestExpense
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON InterestExpense.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfDiscountAmounts)
	|	AND InterestExpense.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Dimension.Organization = &Organization
	|	AND VALUETYPE(InterestExpense.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsToCommitteeForPreparationOfReports(QueryTexts)

	RegisterName = "TableGoodsForMakingReportsToCommittee";
	
	QueryText = 
	"SELECT
	|	GoodsForRegistration.RecordType AS RecordType,
	|	GoodsForRegistration.Period AS Period,
	|	GoodsForRegistration.Organization AS Organization,
	|	GoodsForRegistration.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsForRegistration.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsForRegistration.CCDNumber AS CCDNumber,
	|	GoodsForRegistration.DocumentSales AS DocumentSales,
	|	InventoryKinds.Contract AS Contract,
	|	ISNULL(Contracts.Department, UNDEFINED) AS Department,
	|	ISNULL(Contracts.LineOfBusiness, UNDEFINED) AS LineOfBusiness,
	|	GoodsForRegistration.Currency AS Currency,
	|	GoodsForRegistration.RevenueAmount AS RevenueAmount,
	|	GoodsForRegistration.RevenueAmountExclVATLocal AS RevenueAmountExclVATLocal,
	|	GoodsForRegistration.RevenueAmountMan AS RevenueAmountMan,
	|	GoodsForRegistration.FinRecordID AS FinRecordID,
	|	GoodsForRegistration.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableGoodsForMakingReportsToCommittee
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON GoodsForRegistration.InventoryOwnerAttribute = InventoryKinds.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON InventoryKinds.Contract = Contracts.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfConsignorPrincipalARAP)
	|	AND GoodsForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND GoodsForRegistration.Organization = &Organization
	|	AND VALUETYPE(GoodsForRegistration.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases(QueryTexts)

	RegisterName = "TableGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases";
	
	QueryText = 
	"SELECT
	|	GoodsForRegistration.RecordType AS RecordType,
	|	GoodsForRegistration.Period AS Period,
	|	GoodsForRegistration.Organization AS Organization,
	|	GoodsForRegistration.Products AS Products,
	|	GoodsForRegistration.Characteristic AS Characteristic,
	|	GoodsForRegistration.DocumentAcquisitions AS DocumentAcquisitions,
	|	GoodsForRegistration.Purpose AS Purpose,
	|	GoodsForRegistration.CCDNumber AS CCDNumber,
	|	Assignments.Contract AS Contract,
	|	ISNULL(Contracts.Department, UNDEFINED) AS Department,
	|	ISNULL(Contracts.LineOfBusiness, UNDEFINED) AS LineOfBusiness,
	|	GoodsForRegistration.Currency AS Currency,
	|	GoodsForRegistration.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsForRegistration.SumCompl AS SumCompl,
	|	GoodsForRegistration.SumMan AS SumMan,
	|	GoodsForRegistration.FinRecordID AS FinRecordID,
	|	GoodsForRegistration.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases
	|FROM
	|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor AS GoodsForRegistration
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON GoodsForRegistration.Purpose = Assignments.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON Assignments.Contract = Contracts.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfConsignorPrincipalARAP)
	|	AND GoodsForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND GoodsForRegistration.Organization = &Organization
	|	AND VALUETYPE(GoodsForRegistration.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTServicesToDesignOfReportsToPrincipal(QueryTexts)

	RegisterName = "TableServicesForPreparationOfReportsToPrincipal";
	
	QueryText = 
	"SELECT
	|	ServicesForRegistration.RecordType AS RecordType,
	|	ServicesForRegistration.Period AS Period,
	|	ServicesForRegistration.Organization AS Organization,
	|	ServicesForRegistration.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ServicesForRegistration.Terms AS Terms,
	|	ServicesForRegistration.DocumentSales AS DocumentSales,
	|	ISNULL(DocumentMOUTH.Contract, UNDEFINED) AS Contract,
	|	ISNULL(Contracts.Department, UNDEFINED) AS Department,
	|	ISNULL(Contracts.LineOfBusiness, UNDEFINED) AS LineOfBusiness,
	|	ServicesForRegistration.Currency AS Currency,
	|	ServicesForRegistration.RevenueAmount AS RevenueAmount,
	|	ServicesForRegistration.RevenueAmountExclVATLocal AS RevenueAmountExclVATLocal,
	|	ServicesForRegistration.RevenueAmountMan AS RevenueAmountMan,
	|	ServicesForRegistration.FinRecordID AS FinRecordID,
	|	ServicesForRegistration.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TableServicesForPreparationOfReportsToPrincipal
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS ServicesForRegistration
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON ServicesForRegistration.Terms = Terms1.Ref
	|	LEFT JOIN Document.CustomerInvoice AS DocumentMOUTH
	|		ON ServicesForRegistration.DocumentSales = DocumentMOUTH.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON DocumentMOUTH.Contract = Contracts.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfConsignorPrincipalARAP)
	|	AND ServicesForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ServicesForRegistration.Organization = &Organization
	|	AND VALUETYPE(ServicesForRegistration.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSettlementsWithCustomers(QueryTexts = Undefined)

	RegisterName = "CustomersARAPAccounting";
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Currency AS Currency,
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -RegisterData.DebtLocal
	|		ELSE RegisterData.DebtLocal
	|	END DebtLocal,
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -RegisterData.ARAPMan
	|		ELSE RegisterData.ARAPMan
	|	END ARAPMan,
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -RegisterData.PrepaymentLocal
	|		ELSE RegisterData.PrepaymentLocal
	|	END PrepaymentLocal,
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -RegisterData.PrepaymentMan
	|		ELSE RegisterData.PrepaymentMan
	|	END PrepaymentMan,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.Department AS Department,
	|	RegisterData.FinRecordID AS FinRecordID,
	|	RegisterData.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO CustomersARAPAccounting
	|FROM
	|	TableSettlementsWithCustomers AS RegisterData";
	
	If QueryTexts <> Undefined Then
		QueryTexts.Add(QueryText, RegisterName);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextTTSettlementsWithClientsForSettlementObjects(QueryTexts = Undefined, VendorsARAPAccounting = False)

	RegisterName = "SettlementsWithClientsOnSettlementObjects";
	
	If QueryTexts <> Undefined Then
		If Not DocumentsPosting.ThereIsQueryTable("TableSettlementsWithCustomers", QueryTexts) Then
			If GetFunctionalOption("NewOnlineARAPAccounting") Then
				RequestTextTTTableSettlementsWithClientsByTerms(QueryTexts);
			Else
				RequestTextTTTableSettlementsWithClientsByDocuments(QueryTexts);
			EndIf;
		EndIf;

		If Not DocumentsPosting.ThereIsQueryTable("CustomersARAPAccounting", QueryTexts) Then
			QueryTextTTSettlementsWithCustomers(QueryTexts);
		EndIf;
	EndIf;
	
	QueryText = 
	"SELECT
	|	CustomersARAPAccounting.Period AS Period,
	|	CustomersARAPAccounting.Currency AS Currency,
	|	SUM(CustomersARAPAccounting.DebtLocal) AS DebtLocal,
	|	SUM(CustomersARAPAccounting.ARAPMan) AS ARAPMan,
	|	SUM(CustomersARAPAccounting.PrepaymentLocal) AS PrepaymentLocal,
	|	SUM(CustomersARAPAccounting.PrepaymentMan) AS PrepaymentMan,
	|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccounting.Department AS Department,
	|	Dimension.LineOfBusiness AS LineOfBusiness,
	|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|	Dimension.Counterparty AS Counterparty,
	|	Dimension.Contract AS Contract,
	|	CustomersARAPAccounting.FinRecordID,
	|	CustomersARAPAccounting.BusinessTransactionSetting
	|INTO SettlementsWithCounterpartiesOnSettlementObjects
	|FROM
	|	CustomersARAPAccounting
	|	INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
	|	
	|GROUP BY
	|	CustomersARAPAccounting.Period,
	|	CustomersARAPAccounting.Currency,
	|	CustomersARAPAccounting.AccountingDimensionByPartners,
	|	CustomersARAPAccounting.Department,
	|	Dimension.LineOfBusiness,
	|	CustomersARAPAccounting.ARAPObject,
	|	Dimension.Counterparty,
	|	Dimension.Contract,
	|	CustomersARAPAccounting.FinRecordID,
	|	CustomersARAPAccounting.BusinessTransactionSetting";
	
	If VendorsARAPAccounting Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
		QueryText = StrReplace(
			QueryText, "SettlementsWithCounterpartiesOnSettlementObjects", "SettlementsWithSuppliersOnSettlementObjects");
	Else
		QueryText = StrReplace(
			QueryText, "SettlementsWithCounterpartiesOnSettlementObjects", "SettlementsWithClientsOnSettlementObjects");
	EndIf;
	
	If QueryTexts <> Undefined Then
		QueryTexts.Add(QueryText, RegisterName);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSettlementsWithSuppliers(QueryTexts = Undefined)

	RegisterName = "VendorsARAPAccounting";
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Currency AS Currency,
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -RegisterData.DebtLocal
	|		ELSE RegisterData.DebtLocal
	|	END DebtLocal,
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -RegisterData.ARAPMan
	|		ELSE RegisterData.ARAPMan
	|	END ARAPMan,
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -RegisterData.PrepaymentLocal
	|		ELSE RegisterData.PrepaymentLocal
	|	END PrepaymentLocal,
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -RegisterData.PrepaymentMan
	|		ELSE RegisterData.PrepaymentMan
	|	END PrepaymentMan,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.Department AS Department,
	|	RegisterData.FinRecordID AS FinRecordID,
	|	RegisterData.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO VendorsARAPAccounting
	|FROM
	|	TableSettlementsWithSuppliers AS RegisterData";
	
	If QueryTexts <> Undefined Then
		QueryTexts.Add(QueryText, RegisterName);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextTTSettlementsWithSuppliersForSettlementObjects(QueryTexts)

	RegisterName = "SettlementsWithSuppliersOnSettlementObjects";

	If Not DocumentsPosting.ThereIsQueryTable("TableSettlementsWithSuppliers", QueryTexts) Then
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			RequestTextTTTableSettlementsWithSuppliersByTerms(QueryTexts);
		Else
			RequestTextTTTableSettlementsWithSuppliersBasedOnDocuments(QueryTexts);
		EndIf;
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("VendorsARAPAccounting", QueryTexts) Then
		QueryTextTTSettlementsWithSuppliers(QueryTexts);
	EndIf;
	
	QueryText = RequestTextTTSettlementsWithClientsForSettlementObjects( , True);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTInvestmentInRent(QueryTexts = Undefined, VendorsARAPAccounting = False)

	RegisterName = "RentalInvestmentTable";
	
	QueryText = 
	"SELECT
	|	InvestmentInRent.RecordType AS RecordType,
	|	InvestmentInRent.Period AS Period,
	|	InvestmentInRent.Organization AS Organization,
	|	InvestmentInRent.Contract AS Contract,
	|	InvestmentInRent.Currency AS Currency,
	|	InvestmentInRent.FixedAsset AS FixedAsset,
	|	InvestmentInRent.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ISNULL(Contracts.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	ISNULL(Contracts.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|
	|	InvestmentInRent.RentalPayments AS Sum,
	|	InvestmentInRent.RentalPaymentsLocal AS SumCompl,
	|	InvestmentInRent.RentalPaymentsManag AS SumMan,
	|	FALSE AS ThisIsPercentageDiscount,
	|	InvestmentInRent.FinRecordID         AS FinRecordID,
	|	InvestmentInRent.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO RentalInvestmentTable
	|FROM
	|	AccumulationRegister.InvestmentInRent AS InvestmentInRent
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|	ON InvestmentInRent.Contract = Contracts.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfFinancialInstruments)
	|	AND VALUETYPE(InvestmentInRent.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND InvestmentInRent.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InvestmentInRent.Organization = &Organization
	|
	|UNION ALL
	|
	|SELECT
	|	InvestmentInRent.RecordType AS RecordType,
	|	InvestmentInRent.Period AS Period,
	|	InvestmentInRent.Organization AS Organization,
	|	InvestmentInRent.Contract AS Contract,
	|	InvestmentInRent.Currency AS Currency,
	|	InvestmentInRent.FixedAsset AS FixedAsset,
	|	InvestmentInRent.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ISNULL(Contracts.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	ISNULL(Contracts.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|
	|	InvestmentInRent.InterestDiscount AS Sum,
	|	InvestmentInRent.InterestDiscountLocal AS SumCompl,
	|	InvestmentInRent.InterestDiscountMan AS SumMan,
	|	TRUE AS ThisIsPercentageDiscount,
	|	InvestmentInRent.FinRecordID         AS FinRecordID,
	|	InvestmentInRent.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	AccumulationRegister.InvestmentInRent AS InvestmentInRent
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|	ON InvestmentInRent.Contract = Contracts.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfFinancialInstruments)
	|	AND VALUETYPE(InvestmentInRent.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|	AND InvestmentInRent.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InvestmentInRent.Organization = &Organization";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Procedure AddTemporaryTables(QueryTexts, TablesGroup = "") Export
	
	If TablesGroup = "Cash" Or IsBlankString(TablesGroup) Then
		If Not DocumentsPosting.ThereIsQueryTable("TableCashless", QueryTexts) Then
			RequestTextTTTableCashNonCash(QueryTexts);
		EndIf;

		If Not DocumentsPosting.ThereIsQueryTable("TableCashCash", QueryTexts) Then
			RequestTextTTTableCashCash(QueryTexts);
		EndIf;

		If Not DocumentsPosting.ThereIsQueryTable("TableCashInCashCashRegisters", QueryTexts) Then
			RequestTextTTTableCashInCashRegistersCashRegister(QueryTexts);
		EndIf;

		If Not DocumentsPosting.ThereIsQueryTable("TableCashHeldByAccountablePersons", QueryTexts) Then
			RequestTextTTTableFundsHeldByAccountablePersons(QueryTexts);
		EndIf;

		If Not DocumentsPosting.ThereIsQueryTable("TableCashInTransit", QueryTexts) Then
			RequestTextTTCashInTransitTable(QueryTexts);
		EndIf;
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TableFinancialInstruments", QueryTexts) Then
		QueryTextTTTableFinancialInstruments(QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TableProvisionsForDoubtfulDebts", QueryTexts) Then
		RequestTextTTTableProvisionsForDoubtfulDebts(QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TableOfDiscountAmounts", QueryTexts) Then
		RequestTextTTTableOfDiscountAmounts(QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableGoodsForMakingReportsToCommittee", QueryTexts) Then
		QueryTextTTGoodsToCommitteeForPreparationOfReports(QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases", QueryTexts) Then
		QueryTextTTGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases(QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableServicesForPreparationOfReportsToPrincipal", QueryTexts) Then
		QueryTextTTServicesToDesignOfReportsToPrincipal(QueryTexts);
	EndIf;
	
	If TablesGroup = "PartnersARAPAccounting" Or IsBlankString(TablesGroup) Then
		If Not DocumentsPosting.ThereIsQueryTable("SettlementsWithClientsOnSettlementObjects", QueryTexts) Then
			RequestTextTTSettlementsWithClientsForSettlementObjects(QueryTexts);
		EndIf;
		If Not DocumentsPosting.ThereIsQueryTable("SettlementsWithSuppliersOnSettlementObjects", QueryTexts) Then
			RequestTextTTSettlementsWithSuppliersForSettlementObjects(QueryTexts);
		EndIf;
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("RentalInvestmentTable", QueryTexts) Then
		QueryTextTTInvestmentInRent(QueryTexts);
	EndIf;
	ExchangeDifferenceCalculationLocalization.AddTemporaryTables(QueryTexts, TablesGroup);
	
EndProcedure

Function QueryTextTableOtherIncome(QueryTexts, Registers = Undefined)

	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	AddTemporaryTables(QueryTexts);
	
	QueryText = 
	"SELECT
	|	NestedQuery.Period AS Period,
	|	&Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) AS IncomeItem,
	|	NestedQuery.DimensionOfRevenue AS DimensionOfRevenue,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN NestedQuery.Sum
	|		ELSE 0 END) AS SumMan,
	|	SUM(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpenses
	|			THEN NestedQuery.SumCompl
	|		ELSE 0 END) AS SumCompl,
	|	NestedQuery.BusinessOperation AS BusinessOperation,
	|	NestedQuery.FinRecordID         AS FinRecordID,
	|	NestedQuery.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM (
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		Table.BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashless AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		Table.BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashCash AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashInCashCashRegisters AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		Table.BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashHeldByAccountablePersons AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashInTransit AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableFinancialInstruments AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.LossAllowance) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableProvisionsForDoubtfulDebts AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableOfDiscountAmounts AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.ARAPWithConsignorConsignee) AS DimensionOfRevenue,
	|		Table.RevenueAmountMan AS Sum,
	|		Table.RevenueAmountExclVATLocal AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableGoodsForMakingReportsToCommittee AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.ARAPWithConsignorConsignee) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.ARAPWithConsignorConsignee) AS DimensionOfRevenue,
	|		Table.RevenueAmountMan AS Sum,
	|		Table.RevenueAmountExclVATLocal AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableServicesForPreparationOfReportsToPrincipal AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.InvestmentInRent) AS DimensionOfRevenue,
	|		Table.SumMan AS Sum,
	|		Table.SumCompl AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		RentalInvestmentTable AS Table
	|	WHERE
	|		NOT Table.ThisIsPercentageDiscount
	|			AND Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.InvestmentInRent) AS DimensionOfRevenue,
	|		-Table.SumMan AS Sum,
	|		-Table.SumCompl AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		RentalInvestmentTable AS Table
	|	WHERE
	|		Table.ThisIsPercentageDiscount
	|			AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	//++ WE
	|	//Exchange differences in payroll calculations
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.PayrollCalculations) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		0 AS SumCompl,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		PayrollCalculationsHR AS Table
	|	WHERE  Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	//-- WE
	|
	|	// Exchange rate differences from settlements with customers
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting) AS DimensionOfRevenue,
	|		Table.ARAPMan AS Sum,
	|		Table.DebtLocal AS SumCompl,
	|		VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain) AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		SettlementsWithClientsOnSettlementObjects AS Table
	|	WHERE
	|		Table.ARAPMan > 0 OR Table.DebtLocal > 0
	|	
	|	UNION ALL
	|
	|	// Exchange differences from settlements with customers: rounding errors, refund of advances
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting) AS DimensionOfRevenue,
	|		-Table.PrepaymentMan AS Sum,
	|		-Table.PrepaymentLocal AS SumCompl,
	|		VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain) AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		SettlementsWithClientsOnSettlementObjects AS Table
	|	WHERE
	|		Table.PrepaymentMan < 0 OR Table.PrepaymentLocal < 0
	|	
	|	UNION ALL
	|	
	|	// Exchange differences from settlements with suppliers
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting) AS DimensionOfRevenue,
	|		-Table.ARAPMan AS Sum,
	|		-Table.DebtLocal AS SumCompl,
	|		VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain) AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		SettlementsWithSuppliersOnSettlementObjects AS Table
	|	WHERE
	|		Table.ARAPMan < 0 OR Table.DebtLocal < 0
	|	
	|	UNION ALL
	|	
	|	// Exchange differences from settlements with suppliers: rounding errors, refund of advances
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting) AS DimensionOfRevenue,
	|		Table.PrepaymentMan AS Sum,
	|		Table.PrepaymentLocal AS SumCompl,
	|		VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain) AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		SettlementsWithSuppliersOnSettlementObjects AS Table
	|	WHERE
	|		Table.PrepaymentMan > 0 OR Table.PrepaymentLocal > 0
	|AND &MergingWithLocalizationTables
	|
	|	) AS NestedQuery
	|
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.DimensionOfRevenue,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.FinRecordID,
	|	NestedQuery.BusinessTransactionSetting
	|
	|ORDER BY
	|	NestedQuery.Period";
	
	ExchangeDifferenceCalculationLocalization.CompleteJoinOfOtherIncomeQueryTables(QueryText);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(QueryTexts)

	RegisterName = "TTInitialOtherExpenses";
	
	AddTemporaryTables(QueryTexts);
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses();
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	NestedQuery.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) AS ExpenseItem,
	|	NestedQuery.DimensionOfExpenses AS DimensionOfExpenses,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	SUM(NestedQuery.SumMan) AS AmountIncludingVAT,
	|	SUM(NestedQuery.SumMan) AS AmountExcludingVAT,
	|	SUM(NestedQuery.SumMan) AS AmountExcludingVATMan,
	|	SUM(NestedQuery.SumCompl) AS AmountIncludingVATCompl,
	|	SUM(NestedQuery.SumCompl) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	SUM(NestedQuery.CostTD) AS CostTD,
	|	NestedQuery.BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	NestedQuery.FinRecordID         AS FinRecordID,
	|	NestedQuery.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM (
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		Table.BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashless AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		Table.BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashCash AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashInCashCashRegisters AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		Table.BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashHeldByAccountablePersons AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableCashInTransit AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableFinancialInstruments AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.LossAllowance) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableProvisionsForDoubtfulDebts AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		Table.SumCompl AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableOfDiscountAmounts AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.ARAPWithConsignorConsignee) AS DimensionOfExpenses,
	|		Table.RevenueAmountMan AS SumMan,
	|		Table.RevenueAmountExclVATLocal AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableGoodsForMakingReportsToCommittee AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.ARAPWithConsignorConsignee) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.ARAPWithConsignorConsignee) AS DimensionOfExpenses,
	|		Table.RevenueAmountMan AS SumMan,
	|		Table.RevenueAmountExclVATLocal AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		TableServicesForPreparationOfReportsToPrincipal AS Table
	|	WHERE
	|		Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.InvestmentInRent) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		RentalInvestmentTable AS Table
	|	WHERE
	|		NOT Table.ThisIsPercentageDiscount
	|			AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.InvestmentInRent) AS DimensionOfExpenses,
	|		-Table.SumMan AS SumMan,
	|		-Table.SumCompl AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		RentalInvestmentTable AS Table
	|	WHERE
	|		Table.ThisIsPercentageDiscount
	|			AND Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	//++ WE
	|	//Exchange differences in payroll calculations
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.PayrollCalculations) AS DimensionOfExpenses,
	|		Table.SumMan AS SumMan,
	|		0 AS SumCompl,
	|		0 AS CostTD,
	|		&BusinessOperation AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		PayrollCalculationsHR AS Table
	|	WHERE Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	//-- WE
	|	//Exchange rate differences from settlements with customers
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting) AS DimensionOfExpenses,
	|		-Table.ARAPMan AS SumMan,
	|		-Table.DebtLocal AS SumCompl,
	|		0 AS CostTD,
	|		VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss) AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		SettlementsWithClientsOnSettlementObjects AS Table
	|	WHERE
	|		Table.DebtLocal < 0 OR Table.ARAPMan < 0
	|	
	|	UNION ALL
	|	
	|	//Exchange differences from settlements with customers: rounding errors, refund of advances
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting) AS DimensionOfExpenses,
	|		Table.PrepaymentMan AS SumMan,
	|		Table.PrepaymentLocal AS SumCompl,
	|		0 AS CostTD,
	|		VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss) AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		SettlementsWithClientsOnSettlementObjects AS Table
	|	WHERE
	|		Table.PrepaymentLocal > 0 OR Table.PrepaymentMan > 0
	|	
	|	UNION ALL
	|
	|	//Exchange differences from settlements with suppliers
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting) AS DimensionOfExpenses,
	|		Table.ARAPMan AS SumMan,
	|		Table.DebtLocal AS SumCompl,
	|		0 AS CostTD,
	|		VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss) AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		SettlementsWithSuppliersOnSettlementObjects AS Table
	|	WHERE
	|		Table.DebtLocal > 0 OR Table.ARAPMan > 0
	|	
	|	UNION ALL
	|
	|	//Exchange differences from settlements with suppliers: rounding errors, refund of advances
	|	SELECT
	|		Table.Period AS Period,
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting) AS DimensionOfExpenses,
	|		-Table.PrepaymentMan AS SumMan,
	|		-Table.PrepaymentLocal AS SumCompl,
	|		0 AS CostTD,
	|		VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss) AS BusinessOperation,
	|		Table.FinRecordID AS FinRecordID,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		SettlementsWithSuppliersOnSettlementObjects AS Table
	|	WHERE
	|		Table.PrepaymentLocal < 0 OR Table.PrepaymentMan < 0
	|AND &MergingWithLocalizationTables
	|
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.DimensionOfExpenses,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.FinRecordID,
	|	NestedQuery.BusinessTransactionSetting
	|";
	
	ExchangeDifferenceCalculationLocalization.CompleteMergingOfQueryTablesSourceOtherExpenses(QueryText);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(QueryTexts, Registers = Undefined)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(QueryTexts, Registers = Undefined)

	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	AddTemporaryTables(QueryTexts, "PartnersARAPAccounting");
	
	QueryText = 
	"SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|
	|	AnalyticsRegister.Partner AS Partner,
	|	AnalyticsRegister.Counterparty AS Counterparty,
	|	NestedQuery.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.LineOfBusiness AS LineOfBusinessItems,
	|	NestedQuery.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	NestedQuery.DimensionOfRevenue AS DimensionOfRevenue,
	|	NestedQuery.DimensionOfExpenses AS DimensionOfExpenses,
	|	NestedQuery.Currency AS Currency,
	|	NestedQuery.Currency AS ARAPCurrency,
	|	NestedQuery.FinRecordID AS FinRecordID,
	|
	|	SUM(NestedQuery.SumMan) AS Sum,
	|	SUM(NestedQuery.SumMan) AS AmountExcludingVAT,
	|	SUM(NestedQuery.SumCompl) AS SumCompl,
	|	SUM(NestedQuery.SumCompl) AS LocalAmountExcludingVAT,
	|
	|	NestedQuery.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	(SELECT
	|		Table.Period AS Period,
	|		CASE
	|			WHEN Table.ARAPMan < 0 THEN
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss)
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.ARAPMan < 0 THEN
	|				VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting) 
	|			ELSE
	|				UNDEFINED 
	|		END AS DimensionOfRevenue,
	|		CASE
	|			WHEN Table.ARAPMan < 0 THEN
	|				UNDEFINED
	|			ELSE
	|				VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting) 
	|		END AS DimensionOfExpenses,
	|		CASE 
	|			WHEN Table.ARAPMan < 0 THEN
	|				VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.ARAPMan < 0
	|			THEN -Table.ARAPMan
	|			ELSE Table.ARAPMan
	|		END AS SumMan,
	|		0 AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		SettlementsWithSuppliersOnSettlementObjects AS Table
	|	WHERE
	|		Table.ARAPMan <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE
	|			WHEN Table.DebtLocal < 0 THEN
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss)
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.DebtLocal < 0 THEN
	|				VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting) 
	|			ELSE
	|				UNDEFINED 
	|		END AS DimensionOfRevenue,
	|		CASE
	|			WHEN Table.DebtLocal < 0 THEN
	|				UNDEFINED
	|			ELSE
	|				VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting) 
	|		END AS DimensionOfExpenses,
	|		CASE 
	|			WHEN Table.DebtLocal < 0 THEN
	|				VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		0 AS SumMan,
	|		CASE WHEN Table.DebtLocal < 0
	|			THEN -Table.DebtLocal
	|			ELSE Table.DebtLocal
	|		END AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		SettlementsWithSuppliersOnSettlementObjects AS Table
	|	WHERE
	|		Table.DebtLocal <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE
	|			WHEN Table.PrepaymentMan > 0 THEN
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.PrepaymentMan > 0 THEN
	|				VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting)
	|			ELSE
	|				UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE
	|			WHEN Table.PrepaymentMan > 0 THEN
	|				UNDEFINED
	|			ELSE
	|				VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting)
	|		END AS DimensionOfExpenses,
	|		CASE
	|			WHEN Table.PrepaymentMan > 0 THEN
	|				VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.PrepaymentMan < 0
	|			THEN -Table.PrepaymentMan
	|			ELSE Table.PrepaymentMan
	|		END AS SumMan,
	|		0 AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		SettlementsWithSuppliersOnSettlementObjects AS Table
	|	WHERE
	|		Table.PrepaymentMan <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.PrepaymentLocal > 0 THEN
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.PrepaymentLocal > 0 THEN
	|				VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting)
	|			ELSE
	|				UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.PrepaymentLocal > 0 THEN
	|				UNDEFINED
	|			ELSE
	|				VALUE(Enum.ExchangeDifferencesDimension.VendorsARAPAccounting)
	|		END AS DimensionOfExpenses,
	|		CASE
	|			WHEN Table.PrepaymentLocal > 0 THEN
	|				VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		0 AS SumMan,
	|		CASE WHEN Table.PrepaymentLocal < 0
	|			THEN -Table.PrepaymentLocal
	|			ELSE Table.PrepaymentLocal
	|		END AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		SettlementsWithSuppliersOnSettlementObjects AS Table
	|	WHERE
	|		Table.PrepaymentLocal <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE
	|			WHEN Table.ARAPMan > 0 THEN
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.ARAPMan > 0 THEN
	|				VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting)
	|			ELSE
	|				UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE
	|			WHEN Table.ARAPMan > 0 THEN
	|				UNDEFINED
	|			ELSE
	|				VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting)
	|		END AS DimensionOfExpenses,
	|		CASE
	|			WHEN Table.ARAPMan > 0 THEN
	|				VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.ARAPMan < 0
	|			THEN -Table.ARAPMan
	|			ELSE Table.ARAPMan
	|		END AS SumMan,
	|		0 AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		SettlementsWithClientsOnSettlementObjects AS Table
	|	WHERE
	|		Table.ARAPMan <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE
	|			WHEN Table.DebtLocal > 0 THEN
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.DebtLocal > 0 THEN
	|				VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting)
	|			ELSE
	|				UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE
	|			WHEN Table.DebtLocal > 0 THEN
	|				UNDEFINED
	|			ELSE
	|				VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting)
	|		END AS DimensionOfExpenses,
	|		CASE
	|			WHEN Table.DebtLocal > 0 THEN
	|				VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		0 AS SumMan,
	|		CASE WHEN Table.DebtLocal < 0
	|			THEN -Table.DebtLocal
	|			ELSE Table.DebtLocal
	|		END AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		SettlementsWithClientsOnSettlementObjects AS Table
	|	WHERE
	|		Table.DebtLocal <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE
	|			WHEN Table.PrepaymentMan < 0 THEN
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.PrepaymentMan < 0 THEN
	|				VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting)
	|			ELSE
	|				UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE
	|			WHEN Table.PrepaymentMan < 0 THEN
	|				UNDEFINED
	|			ELSE
	|				VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting)
	|		END AS DimensionOfExpenses,
	|		CASE
	|			WHEN Table.PrepaymentMan < 0 THEN
	|				VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.PrepaymentMan < 0
	|			THEN -Table.PrepaymentMan
	|			ELSE Table.PrepaymentMan
	|		END AS SumMan,
	|		0 AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		SettlementsWithClientsOnSettlementObjects AS Table
	|	WHERE
	|		Table.PrepaymentMan <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE
	|			WHEN Table.PrepaymentLocal < 0 THEN
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.PrepaymentLocal < 0 THEN
	|				VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting)
	|			ELSE
	|				UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE
	|			WHEN Table.PrepaymentLocal < 0 THEN
	|				UNDEFINED
	|			ELSE
	|				VALUE(Enum.ExchangeDifferencesDimension.CustomersARAPAccounting)
	|		END AS DimensionOfExpenses,
	|		CASE
	|			WHEN Table.PrepaymentLocal < 0 THEN
	|				VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		0 AS SumMan,
	|		CASE WHEN Table.PrepaymentLocal < 0
	|			THEN -Table.PrepaymentLocal
	|			ELSE Table.PrepaymentLocal
	|		END AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		SettlementsWithClientsOnSettlementObjects AS Table
	|	WHERE
	|		Table.PrepaymentLocal <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForLoansAndBorrowingsExchangeGain) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForLoansAndBorrowingsExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.Contract AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|			ELSE UNDEFINED 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED 
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		TableFinancialInstruments AS Table
	|	WHERE
	|		Table.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForIssuedBorrowingsExchangeGain) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForIssuedBorrowingsExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.Contract AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|			ELSE UNDEFINED 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED 
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		TableFinancialInstruments AS Table
	|	WHERE
	|		Table.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForLeaseProfit) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForLeaseLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.Contract AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|			ELSE UNDEFINED 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED 
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		TableFinancialInstruments AS Table
	|	WHERE
	|		Table.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesLossAllowanceExchangeGain) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesLossAllowanceExchangeLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CASE WHEN VALUETYPE(Table.ARAPObject) IN(
	|					TYPE(Catalog.CounterpartyContracts),
	|					TYPE(Catalog.IntercompanyContracts),
	|					TYPE(Catalog.LoanAndDepositContracts),
	|					TYPE(Catalog.LeaseContract))
	|			THEN Table.ARAPObject
	|			ELSE Table.ARAPObject.Contract
	|		END AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|			ELSE UNDEFINED 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED 
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.LossAllowance) 
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		TableProvisionsForDoubtfulDebts AS Table
	|	WHERE
	|		Table.SumMan <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeRateDifferencesOnDiscountingProfit) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeRateDifferencesOnDiscountingLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Table.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|			ELSE UNDEFINED
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		TableOfDiscountAmounts AS Table
	|	WHERE
	|		Table.SumCompl <> 0 OR Table.SumMan <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Dimension.DimensionKey AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Contracts.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|			ELSE UNDEFINED
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|
	|		Table.RevenueAmountMan AS SumMan,
	|		Table.RevenueAmountExclVATLocal AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		TableGoodsForMakingReportsToCommittee AS Table
	|		INNER JOIN Catalog.CounterpartyContracts AS Contracts
	|			ON Table.Contract = Contracts.Ref
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON Dimension.Partner = Contracts.Partner
	|			AND Dimension.Organization = Contracts.Organization
	|			AND Dimension.Counterparty = Contracts.Counterparty
	|			AND Dimension.Contract = Contracts.Ref
	|			AND Dimension.LineOfBusiness = Contracts.LineOfBusiness
	|	WHERE
	|		Table.RevenueAmountExclVATLocal <> 0 OR Table.RevenueAmountMan <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Dimension.DimensionKey AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Contracts.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|		
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|			ELSE UNDEFINED
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		TableGoodsAndServicesForPreparationOfReportsToCommitteeOnPurchases AS Table
	|		INNER JOIN Catalog.CounterpartyContracts AS Contracts
	|			ON Table.Contract = Contracts.Ref
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON Dimension.Partner = Contracts.Partner
	|			AND Dimension.Organization = Contracts.Organization
	|			AND Dimension.Counterparty = Contracts.Counterparty
	|			AND Dimension.Contract = Contracts.Ref
	|			AND Dimension.LineOfBusiness = Contracts.LineOfBusiness
	|	WHERE
	|		Table.SumCompl <> 0 OR Table.SumMan <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Dimension.DimensionKey AS AccountingDimensionByPartners,
	|		Table.Contract AS Contract,
	|		Contracts.ARAPObject AS ARAPObject,
	|		Table.Currency AS Currency,
	|
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments) 
	|			ELSE UNDEFINED
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|
	|		Table.RevenueAmountMan AS Sum,
	|		Table.RevenueAmountExclVATLocal AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		TableServicesForPreparationOfReportsToPrincipal AS Table
	|		INNER JOIN Catalog.CounterpartyContracts AS Contracts
	|			ON Table.Contract = Contracts.Ref
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON Dimension.Partner = Contracts.Partner
	|			AND Dimension.Organization = Contracts.Organization
	|			AND Dimension.Counterparty = Contracts.Counterparty
	|			AND Dimension.Contract = Contracts.Ref
	|			AND Dimension.LineOfBusiness = Contracts.LineOfBusiness
	|	WHERE
	|		Table.RevenueAmountExclVATLocal <> 0 OR Table.RevenueAmountMan <> 0
	|	) AS NestedQuery
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalyticsRegister
	|		ON NestedQuery.AccountingDimensionByPartners = AnalyticsRegister.DimensionKey
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.Department,
	|	AnalyticsRegister.Counterparty,
	|	AnalyticsRegister.Partner,
	|	NestedQuery.IncomeAndExpenseItem,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.DimensionOfRevenue,
	|	NestedQuery.DimensionOfExpenses,
	|	NestedQuery.Contract,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.Currency,
	|	NestedQuery.FinRecordID
	|
	|UNION ALL
	|
	|SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.BusinessOperation AS BusinessOperation,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|
	|	NestedQuery.Partner AS Partner,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.LineOfBusiness AS LineOfBusinessItems,
	|	NestedQuery.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	NestedQuery.DimensionOfRevenue AS DimensionOfRevenue,
	|	NestedQuery.DimensionOfExpenses AS DimensionOfExpenses,
	|	NestedQuery.Currency AS Currency,
	|	NestedQuery.Currency AS ARAPCurrency,
	|	NestedQuery.FinRecordID AS FinRecordID,
	|
	|	SUM(NestedQuery.SumMan) AS Sum,
	|	SUM(NestedQuery.SumMan) AS AmountExcludingVAT,
	|	SUM(NestedQuery.SumCompl) AS SumCompl,
	|	SUM(NestedQuery.SumCompl) AS LocalAmountExcludingVAT,
	|
	|	NestedQuery.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	(SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesOfRentalInvestmentProfit) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesOfRentalInvestmentLoss) 
	|		END AS BusinessOperation,
	|
	|		Table.Department AS Department,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		ARAPObjects.Organization AS Organization,
	|		ARAPObjects.Counterparty AS Counterparty,
	|		ARAPObjects.Partner AS Partner,
	|		Table.Contract AS Contract,
	|		ARAPObjects.Ref AS ARAPObject,
	|		Table.Currency AS Currency,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.InvestmentInRent) 
	|			ELSE UNDEFINED 
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.InvestmentInRent) 
	|		END AS DimensionOfExpenses,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) 
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) 
	|		END AS IncomeAndExpenseItem,
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|		Table.FinRecordID AS FinRecordID
	|	FROM
	|		RentalInvestmentTable AS Table
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON Table.Contract = ARAPObjects.Object
	|	) AS NestedQuery
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.Department,
	|	NestedQuery.Organization,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Partner,
	|	NestedQuery.IncomeAndExpenseItem,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.DimensionOfRevenue,
	|	NestedQuery.DimensionOfExpenses,
	|	NestedQuery.Contract,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.Currency,
	|	NestedQuery.FinRecordID
	|
	|ORDER BY
	|	NestedQuery.Period";


	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashIncomeExpenses(QueryTexts, Registers = Undefined)

	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	AddTemporaryTables(QueryTexts, "Cash");
	
	QueryText = 
	"SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.Department AS IncomeExpenseBusinessUnit,
	|
	|	NestedQuery.LineOfBusiness AS LineOfBusinessCash,
	|	NestedQuery.Cash AS Cash,
	|	NestedQuery.CashType AS CashType,
	|	NestedQuery.CashFlowItem AS CashFlowItem,
	|	NestedQuery.Currency AS Currency,
	|
	|	NestedQuery.LineOfBusiness AS LineOfBusinessItems,
	|	NestedQuery.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	NestedQuery.DimensionOfRevenue AS DimensionOfRevenue,
	|	NestedQuery.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|	SUM(NestedQuery.SumMan) AS Sum,
	|	SUM(NestedQuery.SumCompl) AS SumCompl,
	|	0 AS AmountInCurrency,
	|	
	|	NestedQuery.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	NestedQuery.SourceOfIncomeExpensesFinancialAccountingGroup AS SourceOfIncomeExpensesFinancialAccountingGroup
	|
	|FROM (
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain) 
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss) 
	|		END AS BusinessOperation,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.CashFlowItem,
	|
	|		Table.BankAccount AS Cash,
	|		Table.Department AS Department,
	|		VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
	|		Table.BankAccount.CashCurrency AS Currency,
	|
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|			ELSE UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|		END AS DimensionOfExpenses,
	|
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|
	|		Table.BankAccount AS SourceOfCashFinancialAccountingGroup,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS SourceOfIncomeExpensesFinancialAccountingGroup
	|	
	|	FROM
	|		TableCashless AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|		END AS BusinessOperation,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.CashFlowItem,
	|
	|		Table.CashAccount AS Cash,
	|		Table.Department AS Department,
	|		VALUE(Enum.CashTypes.CashPayment) AS CashType,
	|		Table.CashAccount.CashCurrency AS Currency,
	|
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|			ELSE UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|		END AS DimensionOfExpenses,
	|
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|
	|		Table.CashAccount AS SourceOfCashFinancialAccountingGroup,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS SourceOfIncomeExpensesFinancialAccountingGroup
	|	
	|	FROM
	|		TableCashCash AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|		END AS BusinessOperation,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_) 
	|			ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss) 
	|		END AS CashFlowItem,
	|
	|		Table.CashRegister AS Cash,
	|		Table.Department AS Department,
	|		VALUE(Enum.CashTypes.CashPayment) AS CashType,
	|		Table.CashRegister.CashCurrency AS Currency,
	|
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|			ELSE UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|		END AS DimensionOfExpenses,
	|
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|
	|		Table.CashRegister AS SourceOfCashFinancialAccountingGroup,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS SourceOfIncomeExpensesFinancialAccountingGroup
	|	
	|	FROM
	|		TableCashInCashCashRegisters AS Table
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|		END AS BusinessOperation,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.CashFlowItem,
	|
	|		Table.AdvanceHolder AS Cash,
	|		Table.Department AS Department,
	|		VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|		Table.Currency AS Currency,
	|
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|			ELSE UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|		END AS DimensionOfExpenses,
	|
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|
	|		Table.AdvanceHolder AS SourceOfCashFinancialAccountingGroup,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS SourceOfIncomeExpensesFinancialAccountingGroup
	|	
	|	FROM
	|		TableCashHeldByAccountablePersons AS Table
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|		END AS BusinessOperation,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.CashFlowItem,
	|
	|		Table.Counterparty AS Cash,
	|		Table.Department AS Department,
	|		VALUE(Enum.CashTypes.CashInTransit) AS CashType,
	|		Table.Currency AS Currency,
	|
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|			ELSE UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.Cash)
	|		END AS DimensionOfExpenses,
	|
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|
	|		Table.Counterparty AS SourceOfCashFinancialAccountingGroup,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS SourceOfIncomeExpensesFinancialAccountingGroup
	|	
	|	FROM
	|		TableCashInTransit AS Table
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForDepositsExchangeGain)
	|			ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForDepositsExchangeLoss)
	|		END AS BusinessOperation,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_) 
	|			ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss) 
	|		END AS CashFlowItem,
	|
	|		Table.Contract AS Cash,
	|		Table.Department AS Department,
	|		VALUE(Enum.CashTypes.Deposits) AS CashType,
	|		Table.Currency AS Currency,
	|
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS IncomeAndExpenseItem,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments)
	|			ELSE UNDEFINED
	|		END AS DimensionOfRevenue,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN UNDEFINED
	|			ELSE VALUE(Enum.ExchangeDifferencesDimension.FinancialInstruments)
	|		END AS DimensionOfExpenses,
	|
	|		Table.SumMan AS SumMan,
	|		Table.SumCompl AS SumCompl,
	|
	|		Table.Contract AS SourceOfCashFinancialAccountingGroup,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences)
	|			ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences)
	|		END AS SourceOfIncomeExpensesFinancialAccountingGroup
	|	
	|	FROM
	|		TableFinancialInstruments AS Table
	|	WHERE
	|		Table.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|AND &MergingWithLocalizationTables
	|
	|	) AS NestedQuery
	|
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashRevaluation),
	|		VALUE(Enum.BusinessTransactions.RevaluationOfFinancialInstruments))
	|
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.CashFlowItem,
	|	NestedQuery.Cash,
	|	NestedQuery.Department,
	|	NestedQuery.CashType,
	|	NestedQuery.Currency,
	|	NestedQuery.IncomeAndExpenseItem,
	|	NestedQuery.DimensionOfRevenue,
	|	NestedQuery.DimensionOfExpenses,
	|	NestedQuery.SourceOfCashFinancialAccountingGroup,
	|	NestedQuery.SourceOfIncomeExpensesFinancialAccountingGroup
	|
	|ORDER BY
	|	NestedQuery.Period";
	
	ExchangeDifferenceCalculationLocalization.CompleteJoinOfCashFlowQueryTablesIncomeExpenses(QueryText);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	UNDEFINED AS EmployeeResponsible,
	|	UNDEFINED AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	0 AS Sum,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ExchangeDifferenceCalculation";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ExchangeDifferenceCalculation"));
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, False);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ExchangeDifferenceCalculation

Procedure CompleteCalculateExchangeDifferences(DocumentRef, RegisterNames, DimensionCalculation = Undefined, ProcessedItemsCount = 0)
	
	Query = New Query;
	FillInInitializationParameters(Query, DocumentRef);
	Query.SetParameter("RegisterNames", RegisterNames);
	If TypeOf(DimensionCalculation) = Type("Structure") Then
		AccountingDimensionByPartners = GetAnalytics("AccountingDimensionByPartners", DimensionCalculation);
		OrganizationKeys = GetCatalogLinks("DimensionKeysOfAccountingByPartners", AccountingDimensionByPartners, Query.Parameters.Organization);
		If ValueIsFilled(OrganizationKeys) Then
			Query.SetParameter("DimensionCalculation", OrganizationKeys);
		EndIf;
		CashAccounts = GetAnalytics("CashAccounts", DimensionCalculation);
		If ValueIsFilled(CashAccounts) Then
			Query.SetParameter("CashAccounts", CashAccounts);
			Query.SetParameter("ForAllSalesRegisters", Not ValueIsFilled(CashAccounts));
		EndIf;
		Persons = GetAnalytics("Persons", DimensionCalculation);
		If ValueIsFilled(Persons) Then
			Query.SetParameter("AdvanceHolders", Persons);
			Query.SetParameter("ForAllAccountablePersons", Not ValueIsFilled(Persons));
		EndIf;
	EndIf;
		
	If Not Query.Parameters.ReFillingTARegisters Then
		PrepareRecordSetsForCalculation(DocumentRef, RegisterNames, DimensionCalculation);
	EndIf;
	Calculate_ExchangeDifferences(Query.Parameters, ProcessedItemsCount);
	
EndProcedure

Procedure Calculate_ExchangeDifferences(Val Parameters, ProcessedItemsCount = 0) Export
	
	AllTypesOfDocuments = New TypeDescription(Documents.AllRefsType().Types());
	If AllTypesOfDocuments.ContainsType(TypeOf(Parameters)) Then
		RequestingParameters = New Query;
		RequestingParameters.TempTablesManager = New TempTablesManager;
		FillInInitializationParameters(RequestingParameters, Parameters);
		Parameters = RequestingParameters.Parameters;
	EndIf;
	
	CheckBlockingIncomingDataWhenUpdatingInformationSecurity(NStr("vi = 'Tính toán chênh lệch tỷ giá';
																	|ru = 'Расчет курсовых разниц';
																	|en = 'Exchange difference calculation'; fa = 'محاسبه تفاوت نرخ ارز';
																	|it = 'Calcolo delle differenze di cambio';
																	|pl = 'Obliczenie różnic kursowych';
																	|tr = 'Döviz kuru farkı hesaplaması'"), Parameters.RegisterNames);
	
	ExchangeDifferenceCalculation = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.ExchangeDifferenceCalculation.ManagerModule.ExchangeDifferenceCalculation");
	
	Query = InitializeRequestForExchangeDifferences(Parameters);
	If Query <> Undefined Then
		DaysOfReassessment = DaysOfReassessment(Parameters);
		For Each Day In DaysOfReassessment Do
			
			TableManager = New TempTablesManager;
			
			Query.TempTablesManager = TableManager;
			Query.SetParameter("BeginOfPeriod", Day.Date);
			Query.SetParameter("EndOfPeriod" , EndOfDay(Day.Date));
			Query.SetParameter("BorderStartOfPeriod", New Boundary(Day.Date, BoundaryType.Including));
			Query.SetParameter("BorderEndOfPeriod" , New Boundary(EndOfDay(Day.Date), BoundaryType.Including));
			Query.SetParameter("AllRegisteredRecords", True);
			If Parameters.ItSLease Then
				Query.SetParameter("TypesOfAmounts", TypesOfRentalPaymentAmounts());
				If EndOfDay(Day.Date) = EndOfMonth(Day.Date) Then
					Query.SetParameter("TypesOfAmounts", TypesOfLeasePaymentAmounts());
				EndIf;
			EndIf;
			
			Query.ExecuteBatch();
			
			For Each Register In Parameters.RegisterNames Do
				TotalRecorded = RecordRegisteredRecords(Parameters.Ref, TableManager, Register.Key, Day.Date, Parameters);
				ProcessedItemsCount = ProcessedItemsCount + TotalRecorded;
			EndDo;
			
			TableManager.Close();
			
		EndDo;
	EndIf;
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(ExchangeDifferenceCalculation, ProcessedItemsCount/1000);
	
EndProcedure

Procedure CalculateExchangeDifferencesByTerms(Organization, Date, Operation, RevaluationByDays = Undefined, ProcessedItemsCount = 0) Export
	
	CompanyArray = Organization;
	If Organization = Undefined Then
		CompanyArray = Catalogs.Companies.AvailableCompanies(True);
	ElsIf TypeOf(Organization) = Type("CatalogRef.Companies") Then
		CompanyArray = New Array;
		CompanyArray.Add(Organization);
	EndIf;
	
	CustomersARAPAccounting = Operation = Enums.BusinessTransactions.RevaluationOfCustomersARAP;
	
	RevaluationParameters = ARAPAccountingRevaluationServer.RevaluationParameters(CustomersARAPAccounting, RevaluationByDays);
	ARAPAccountingRevaluationServer.PerformRevaluationForPeriod(CompanyArray, BegOfMonth(Date), EndOfMonth(Date), RevaluationParameters);
	
EndProcedure

// Defines the days on which to revalue the current balances for a given household. operations:
// - for revaluation "on the date of payment and at the end of the month" - the days when payments were made in the currency and the last day of the month.
// - for revaluation "for each day of the month" - the days when payments were made in the currency and the days when the exchange rate changed.
//
// Parameters:
//  <Parameters> - structure with required keys:
//                 period Start - <date> - sets the beginning of the search period for revaluation dates.
//                 End of period - <date> - sets the end of the search period for revaluation dates.
//                 Organization- < Directory.Organizations> - the organization for which it is necessary to re-evaluate the balances.
//                 Pereotsenit - <Boolean> - True - dates of revaluation dates are all dates of changes in exchange rates and
//                                               date of payment, otherwise, only the date of payment.
//                 Economic operation - <Transfer.Business operations> - sets the accumulation register for which
//                                                                                payment dates are determined.
//                 Analysis of the calculation- < Array> - keys of the organization's analysis for which it is necessary to re-evaluate the balances.
//
// Returns:
//   ValueTable - with one "Date" column of the <Date> type.
//
Function DaysOfReassessment(Parameters)
	
	UnionAll = "
		|
		|UNION ALL
		|
		|";
	
	QueryText = "";
	If Parameters.RegisterNames.Property("VendorsARAPAccountingByDueDates") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Payments to suppliers in foreign currency
		|SELECT
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	DATETIME(1,1,1) AS Period
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
		|	AND (Calculations.RecordType = VALUE(AccumulationRecordType.Expense) OR &RevaluationByDays)
		|	AND Calculations.AccountingDimensionByPartners IN (&DimensionCalculation)
		|	AND Calculations.Debt <> 0
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	//++ WE  
	If Parameters.RegisterNames.Property("PayrollCalculationsHR") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Payment settlements in foreign currency
		|SELECT
		|	Calculations.Organization.LocalAccountingCurrency AS Currency,
		|	Calculations.Period
		|FROM
		|	AccumulationRegister.PayrollCalculationsHR AS Calculations
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) OR &RevaluationByDays)
		|	AND VALUETYPE(Calculations.Recorder) <> TYPE(Document.PostingPayrollExpensesInFinancialAccounting2_5)
		|	AND Calculations.Organization.LocalAccountingCurrency <> &ManagementAccountingCurrency
		|	AND Calculations.Sum <> 0
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	//-- WE
	If Parameters.RegisterNames.Property("CustomersARAPAccountingByDueDates") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Customer payments in foreign currency
		|SELECT
		|	Calculations.Currency AS Currency,
		|	Calculations.Period AS Period
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
		|	AND (Calculations.RecordType = VALUE(AccumulationRecordType.Expense) OR &RevaluationByDays)
		|	AND Calculations.AccountingDimensionByPartners IN (&DimensionCalculation)
		|	AND Calculations.Debt <> 0
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("VendorsARAPAccountingByDocuments") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Payments to suppliers in foreign currency
		|SELECT
		|	Calculations.Currency AS Currency,
		|	Calculations.Period AS Period
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
		|	AND (Calculations.BusinessOperation IN (&PaymentToVendor) OR &RevaluationByDays)
		|	AND Calculations.AccountingDimensionByPartners IN (&DimensionCalculation)
		|	AND Calculations.Debt <> 0
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("CustomersARAPAccountingByDocuments") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Customer payments in foreign currency
		|SELECT
		|	Calculations.Currency AS Currency,
		|	Calculations.Period AS Period
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
		|	AND (Calculations.BusinessOperation IN (&CustomerPayment) OR &RevaluationByDays)
		|	AND Calculations.AccountingDimensionByPartners IN (&DimensionCalculation)
		|	AND Calculations.Debt <> 0
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("BankAccountCash") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Non-Cash Funds
		|SELECT
		|	NonCashCashSystems.BankAccount.CashCurrency AS Currency,
		|	NonCashCashSystems.Period
		|FROM
		|	AccumulationRegister.BankAccountCash.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (BankAccount.CashCurrency <> &ManagementAccountingCurrency
		|					OR BankAccount.CashCurrency <> &LocalAccountingCurrency)
		|	) AS NonCashCashSystems
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("CashAccountBalance") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Cash in hand
		|SELECT
		|	CashCash.CashAccount.CashCurrency AS Currency,
		|	CashCash.Period
		|FROM
		|	AccumulationRegister.CashAccountBalance.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (CashAccount IN (&CashAccounts) OR &ForAllSalesRegisters)
		|				AND (CashAccount.CashCurrency <> &ManagementAccountingCurrency
		|					OR CashAccount.CashCurrency <> &LocalAccountingCurrency)
		|	) AS CashCash
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("CashInCashRegistersCR") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Cash at the Cash register offices of the >KKM
		|SELECT
		|	DAtCashRegister.CashRegister.CashCurrency AS Currency,
		|	DAtCashRegister.Period
		|FROM
		|	AccumulationRegister.CashInCashRegistersCR.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (CashRegister.CashCurrency <> &ManagementAccountingCurrency
		|					OR CashRegister.CashCurrency <> &LocalAccountingCurrency)
		|	) AS DAtCashRegister
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("CashInTransit") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Cash-in-transit
		|SELECT
		|	ESVWays.Currency AS Currency,
		|	ESVWays.Period
		|FROM
		|	AccumulationRegister.CashInTransit.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
		|	) AS ESVWays
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("AdvanceHolderCash") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Funds held by accountable persons
		|SELECT
		|	AccountablePersonsFunds.Currency AS Currency,
		|	AccountablePersonsFunds.Period
		|FROM
		|	AccumulationRegister.AdvanceHolderCash.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (AdvanceHolder IN (&AdvanceHolders) OR &ForAllAccountablePersons)
		|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
		|	) AS AccountablePersonsFunds
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("FinancialInstrumentsARAP") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"SELECT DISTINCT
		|	FinancialInstrumentsARAP.Contract.ARAPCurrency AS Currency,
		|	BEGINOFPERIOD(FinancialInstrumentsARAP.Period, DAY) AS Period
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP AS FinancialInstrumentsARAP
		|WHERE
		|	FinancialInstrumentsARAP.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND FinancialInstrumentsARAP.AccountingDimensionByPartners.Organization = &Organization
		|	AND (FinancialInstrumentsARAP.Contract.ARAPCurrency <> &ManagementAccountingCurrency
		|		OR FinancialInstrumentsARAP.Contract.ARAPCurrency <> &LocalAccountingCurrency)
		|	AND VALUETYPE(FinancialInstrumentsARAP.Recorder) <> TYPE(Document.LoanAndDepositInterestCharge)
		|	AND (FinancialInstrumentsARAP.AmountType IN (&TypesOfAmounts) OR &ForAllTypesOfAmounts)
		|	AND (&AllRegisteredRecords
		|		OR FinancialInstrumentsARAP.RecordType = VALUE(AccumulationRecordType.Receipt))
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	If Parameters.RegisterNames.Property("LossAllowance") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"SELECT
		|	Reserves.Currency AS Currency,
		|	Reserves.Period AS Period
		|FROM
		|	AccumulationRegister.LossAllowance AS Reserves
		|WHERE
		|	Reserves.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Reserves.Currency <> &ManagementAccountingCurrency
		|	AND (Reserves.RecordType = VALUE(AccumulationRecordType.Receipt) OR &RevaluationByDays)
		|	AND Reserves.AccountingDimensionByPartners IN (&DimensionCalculation)
		|	AND Reserves.Sum <> 0";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	If Parameters.RegisterNames.Property("DiscountInterestExpense") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"SELECT
		|	DiscountAmounts.Currency AS Currency,
		|	DiscountAmounts.Period AS Period
		|FROM
		|	AccumulationRegister.DiscountInterestExpense AS DiscountAmounts
		|WHERE
		|	DiscountAmounts.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DiscountAmounts.Currency <> &ManagementAccountingCurrency
		|	AND (DiscountAmounts.RecordType = VALUE(AccumulationRecordType.Receipt) OR &RevaluationByDays)
		|	AND DiscountAmounts.AccountingDimensionByPartners IN (&DimensionCalculation)
		|	AND DiscountAmounts.DiscountingAmount <> 0";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("GoodsToBeRegisteredInReportsToConsignor") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"SELECT
		|	GoodsForRegistration.Currency AS Currency,
		|	GoodsForRegistration.Period AS Period
		|FROM
		|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (Currency <> &ManagementAccountingCurrency
		|					OR Currency <> &LocalAccountingCurrency)
		|	) AS GoodsForRegistration
		|	INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON GoodsForRegistration.InventoryOwnerAttribute = InventoryKinds.Ref
		|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
		|		ON InventoryKinds.Contract = Contracts.Ref
		|WHERE
		|	ISNULL(Contracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE)";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("GoodsAndServicesToRegisterPurchasingReportsToConsignor") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"SELECT
		|	GoodsForRegistration.Currency AS Currency,
		|	GoodsForRegistration.Period AS Period
		|FROM
		|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (Currency <> &ManagementAccountingCurrency
		|					OR Currency <> &LocalAccountingCurrency)
		|	) AS GoodsForRegistration
		|	INNER JOIN Catalog.Assignments AS Assignments
		|		ON GoodsForRegistration.Purpose = Assignments.Ref
		|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
		|		ON Assignments.Contract = Contracts.Ref
		|WHERE
		|	ISNULL(Contracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE)";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	
	If Parameters.RegisterNames.Property("ServicesForRegistrationOfReportsToPrincipal") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"SELECT
		|	ServicesForRegistration.Currency AS Currency,
		|	ServicesForRegistration.Period AS Period
		|FROM
		|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (Currency <> &ManagementAccountingCurrency
		|					OR Currency <> &LocalAccountingCurrency)
		|	) AS ServicesForRegistration
		|	INNER JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
		|		ON ServicesForRegistration.Terms = Terms1.Ref
		|WHERE
		|	ISNULL(Terms1.RevalueServicesForConsignmentNotification, FALSE)";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	If Parameters.RegisterNames.Property("InvestmentInRent") Then
		FirstQuery = IsBlankString(QueryText);
		QueryText = QueryText + ?(FirstQuery,"",UnionAll) +
		"// Investment In Rent
		|SELECT
		|	InvestmentInRent.Currency AS Currency,
		|	InvestmentInRent.Period
		|FROM
		|	AccumulationRegister.InvestmentInRent.Turnovers(
		|			&BorderStartOfPeriod,
		|			&BorderEndOfPeriod,
		|			Day,
		|			Organization = &Organization
		|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
		|	) AS InvestmentInRent
		|";
		If FirstQuery Then
			QueryText = StrReplace(QueryText,"FROM","INTO TTCurrencyTurnover" + Chars.LF + "FROM");
		EndIf;
	EndIf;
	ExchangeDifferenceCalculationLocalization.SupplementRevaluationDays(Parameters.RegisterNames, QueryText);
	
	QueryText = QueryText + 
	"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BEGINOFPERIOD(TTCurrencyTurnover.Period, DAY) AS Date
	|FROM
	|	TTCurrencyTurnover AS TTCurrencyTurnover
	|
	|UNION
	|
	|SELECT DISTINCT
	|	ExchangeRates.Period
	|FROM
	|	InformationRegister.RelativeExchangeRates AS ExchangeRates
	|WHERE
	|	ExchangeRates.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND &RevaluationByDays
	|
	|UNION
	|
	|SELECT
	|	BEGINOFPERIOD(&EndOfPeriod, DAY)
	|
	|ORDER BY
	|	Date";
	
	Query = New Query(QueryText);
	For Each Parameter In Parameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	Query.SetParameter("BorderStartOfPeriod", New Boundary(Parameters.BeginOfPeriod, BoundaryType.Including));
	Query.SetParameter("BorderEndOfPeriod",  New Boundary(Parameters.EndOfPeriod,  BoundaryType.Including));
	Query.SetParameter("AllRegisteredRecords",  True);
	If Parameters.BusinessOperation = Enums.BusinessTransactions.RevaluationOfLeaseARAP Then
		Query.SetParameter("AllRegisteredRecords", False);
		Query.SetParameter("TypesOfAmounts", TypesOfRentalPaymentAmounts());
	EndIf;
	Selection = Query.Execute().Unload();
	Return Selection;
	
EndFunction

Function InitializeRequestForExchangeDifferences(Parameters)
	
	QueriesTexts = New Array;
	QueriesTexts.Add(QueryTextsOfExchangeRates());
	For Each Register In Parameters.RegisterNames Do
			
		If Register.Key = "VendorsARAPAccountingByDocuments" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesVendorsARAPAccountingByDocuments());
			
		ElsIf Register.Key = "CustomersARAPAccountingByDocuments" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesCustomersARAPAccountingByDocuments());
		//++ WE
		ElsIf Register.Key = "PayrollCalculationsHR" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesPayrollCalculations());
		//-- WE
		ElsIf Register.Key = "BankAccountCash" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesBankAccountCash());
			
		ElsIf Register.Key = "CashAccountBalance" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesCashAccountBalance());
			
		ElsIf Register.Key = "CashInCashRegistersCR" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesCashInCashRegistersCR());
			
		ElsIf Register.Key = "AdvanceHolderCash" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesAdvanceHolderCash());
			
		ElsIf Register.Key = "CashInTransit" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesCashInTransit());
			
		ElsIf Register.Key = "FinancialInstrumentsARAP" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesFinancialInstrumentsARAP());
		ElsIf Register.Key = "LossAllowance" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesLossAllowance());
		ElsIf Register.Key = "DiscountInterestExpense" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesDiscountInterestExpense());
			
		ElsIf Register.Key = "GoodsToBeRegisteredInReportsToConsignor" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesGoodsToBeRegisteredInReportsToConsignor());
			
		ElsIf Register.Key = "GoodsAndServicesToRegisterPurchasingReportsToConsignor" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesGoodsAndServicesToRegisterPurchasingReportsToConsignor());
			
		ElsIf Register.Key = "ServicesForRegistrationOfReportsToPrincipal" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesServicesForRegistrationOfReportsToPrincipal());
		ElsIf Register.Key = "InvestmentInRent" Then
			QueriesTexts.Add(QueryTextExchangeRateDifferencesInvestmentInRent());
		EndIf;
	
		ExchangeDifferenceCalculationLocalization.SupplementRequestForExchangeDifferences(Register.Key, QueriesTexts);
		
	EndDo;
	
	If QueriesTexts.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	QueryText = StrConcat(QueriesTexts);
	Query = New Query(QueryText);
	For Each Parameter In Parameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	Return Query;
	
EndFunction

Function QueryTextsOfExchangeRates()
	
	Return "SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator AS CourseNumerator,
	|	CurrencyExchangeRate.CourseDenominator AS CourseDenominator
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&EndOfPeriod,
	|			BaseCurrency = &LocalAccountingCurrency) AS CurrencyExchangeRate
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator AS CourseNumerator,
	|	CurrencyExchangeRate.CourseDenominator AS CourseDenominator
	|INTO TTExchangeRatesMan
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|		&EndOfPeriod,
	|		Currency = &ManagementAccountingCurrency AND BaseCurrency = &LocalAccountingCurrency) AS CurrencyExchangeRate
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractCourse.Contract AS Contract,
	|	ContractCourse.CourseNumerator AS CourseNumerator,
	|	ContractCourse.CourseDenominator AS CourseDenominator
	|INTO ContractTTCourses
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&EndOfPeriod) AS ContractCourse
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesVendorsARAPAccountingByDocuments()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	Calculations.AccountingDimensionByPartners AS DimensionKey,
	|	Calculations.PurchaseOrder AS ARAPObject
	|INTO TTAnalyticsPerDay
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|WHERE
	|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
	|	AND Calculations.BusinessOperation IN (&PaymentToVendor)
	|	AND Calculations.AccountingDimensionByPartners IN (&DimensionCalculation)
	|	AND Calculations.Debt <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemnantsOfDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	RemnantsOfDay.AccountingDimensionByPartners,
	|	RemnantsOfDay.PurchaseOrder AS OrderDocument,
	|	RemnantsOfDay.ARAPDocument,
	|	RemnantsOfDay.DebtBalance AS Debt,
	|	RemnantsOfDay.DebtLocalBalance AS DebtLocal,
	|	RemnantsOfDay.ARAPManBalance AS ARAPMan,
	|	0 AS PrepaymentLocal,
	|	0 AS PrepaymentMan
	|INTO TTBalancesAtEndOfDay
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners IN (&DimensionCalculation)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	LEFT JOIN TTAnalyticsPerDay AS AnalyticsOfDay
	|		ON RemnantsOfDay.AccountingDimensionByPartners = AnalyticsOfDay.DimensionKey
	|			AND RemnantsOfDay.PurchaseOrder = AnalyticsOfDay.ARAPObject
	|WHERE
	|	RemnantsOfDay.DebtBalance <> 0
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	
	|UNION ALL
	|
	|SELECT
	|	RemnantsOfDay.Currency,
	|	&EndOfPeriod,
	|	RemnantsOfDay.AccountingDimensionByPartners,
	|	RemnantsOfDay.PurchaseOrder,
	|	RemnantsOfDay.ARAPDocument,
	|	RemnantsOfDay.DebtBalance,
	|	RemnantsOfDay.DebtLocalBalance,
	|	RemnantsOfDay.ARAPManBalance,
	|	0,
	|	0
	|
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners IN (&DimensionCalculation)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	LEFT JOIN TTAnalyticsPerDay AS AnalyticsOfDay
	|		ON RemnantsOfDay.AccountingDimensionByPartners = AnalyticsOfDay.DimensionKey
	|			AND RemnantsOfDay.PurchaseOrder = AnalyticsOfDay.ARAPObject
	|WHERE
	|	RemnantsOfDay.DebtBalance = 0
	|	AND (RemnantsOfDay.DebtLocalBalance <> 0 OR RemnantsOfDay.ARAPManBalance <> 0)
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|
	|UNION ALL
	|
	|SELECT
	|	RemnantsOfDay.Currency,
	|	&EndOfPeriod,
	|	RemnantsOfDay.AccountingDimensionByPartners,
	|	RemnantsOfDay.PurchaseOrder,
	|	RemnantsOfDay.ARAPDocument,
	|	0,
	|	0,
	|	0,
	|	RemnantsOfDay.PrepaymentLocalBalance,
	|	RemnantsOfDay.PrepaymentManBalance
	|
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners IN (&DimensionCalculation)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|WHERE
	|	RemnantsOfDay.ForReturnBalance = 0
	|	AND RemnantsOfDay.PrepaymentBalance = 0
	|	AND (RemnantsOfDay.PrepaymentLocalBalance <> 0 OR RemnantsOfDay.PrepaymentManBalance <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.OrderDocument AS OrderDocument,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	(CAST(Balance.Debt * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - Balance.DebtLocal AS DebtLocal,
	|	(CAST(Balance.Debt * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - Balance.ARAPMan AS ARAPMan
	|
	|INTO TTUnrealizedKr
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|			ON Balance.Currency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|			ON (TRUE)
	|WHERE
	|	Balance.Debt <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.DebtLocal > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.OrderDocument AS PurchaseOrder,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	CASE WHEN Balance.DebtLocal < 0
	|		THEN -Balance.DebtLocal
	|		ELSE Balance.DebtLocal
	|	END AS DebtLocal,
	|	0 AS ARAPMan,
	|	0 AS PrepaymentLocal,
	|	0 AS PrepaymentMan,
	|	CASE WHEN Balance.DebtLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|	END AS BusinessOperation
	|INTO CalculationTable
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|WHERE
	|	Balance.Debt = 0 AND Balance.DebtLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.ARAPMan > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	0,
	|	CASE WHEN Balance.ARAPMan < 0
	|		THEN -Balance.ARAPMan
	|		ELSE Balance.ARAPMan
	|	END,
	|	0,
	|	0,
	|	CASE WHEN Balance.ARAPMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|	END
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|WHERE
	|	Balance.Debt = 0 AND Balance.ARAPMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.PrepaymentLocal > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	0,
	|	0,
	|	CASE WHEN Balance.PrepaymentLocal < 0
	|		THEN -Balance.PrepaymentLocal
	|		ELSE Balance.PrepaymentLocal
	|	END,
	|	0,
	|	CASE WHEN Balance.PrepaymentLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|	END
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|WHERE
	|	Balance.PrepaymentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.PrepaymentMan > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	0,
	|	0,
	|	0,
	|	CASE WHEN Balance.PrepaymentMan < 0
	|		THEN -Balance.PrepaymentMan
	|		ELSE Balance.PrepaymentMan
	|	END,
	|	CASE WHEN Balance.PrepaymentMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|	END
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|WHERE
	|	Balance.PrepaymentMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE
	|		WHEN Balance.DebtLocal < 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	CASE WHEN Balance.DebtLocal < 0
	|		THEN -Balance.DebtLocal
	|		ELSE Balance.DebtLocal
	|	END,
	|	0,
	|	0,
	|	0,
	|	CASE WHEN Balance.DebtLocal < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|	END
	|FROM
	|	TTUnrealizedKr AS Balance
	|WHERE
	|	Balance.DebtLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.ARAPMan < 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	0,
	|	CASE WHEN Balance.ARAPMan < 0
	|		THEN -Balance.ARAPMan
	|		ELSE Balance.ARAPMan
	|	END,
	|	0,
	|	0,
	|	CASE WHEN Balance.ARAPMan < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain)
	|	END
	|FROM
	|	TTUnrealizedKr AS Balance
	|WHERE
	|	Balance.ARAPMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationTable.Currency,
	|	CalculationTable.RecordType,
	|	CalculationTable.Period AS Period,
	|	CalculationTable.AccountingDimensionByPartners,
	|	CalculationTable.PurchaseOrder,
	|	CalculationTable.ARAPDocument,
	|	SUM(CalculationTable.DebtLocal) AS DebtLocal,
	|	SUM(CalculationTable.ARAPMan) AS ARAPMan,
	|	SUM(CalculationTable.PrepaymentLocal) AS PrepaymentLocal,
	|	SUM(CalculationTable.PrepaymentMan) AS PrepaymentMan,
	|	CalculationTable.BusinessOperation
	|INTO ExchangeRateDifferencesVendorsARAPAccountingByDocuments
	|FROM
	|	CalculationTable AS CalculationTable
	|
	|GROUP BY
	|	CalculationTable.Period,
	|	CalculationTable.BusinessOperation,
	|	CalculationTable.AccountingDimensionByPartners,
	|	CalculationTable.ARAPDocument,
	|	CalculationTable.PurchaseOrder,
	|	CalculationTable.Currency,
	|	CalculationTable.RecordType"
	+"
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesCustomersARAPAccountingByDocuments()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	Calculations.AccountingDimensionByPartners AS DimensionKey,
	|	Calculations.SalesOrder AS ARAPObject
	|INTO TTAnalyticsPerDay
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|WHERE
	|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
	|	AND Calculations.BusinessOperation IN (&CustomerPayment)
	|	AND Calculations.AccountingDimensionByPartners IN (&DimensionCalculation)
	|	AND Calculations.Debt <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemnantsOfDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	RemnantsOfDay.AccountingDimensionByPartners,
	|	RemnantsOfDay.SalesOrder AS OrderDocument,
	|	RemnantsOfDay.ARAPDocument,
	|	RemnantsOfDay.DebtBalance AS Debt,
	|	RemnantsOfDay.DebtLocalBalance AS DebtLocal,
	|	RemnantsOfDay.ARAPManBalance AS ARAPMan,
	|	0 AS PrepaymentLocal,
	|	0 AS PrepaymentMan
	|INTO TTBalancesAtEndOfDay
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners IN (&DimensionCalculation)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	LEFT JOIN TTAnalyticsPerDay AS AnalyticsOfDay
	|		ON RemnantsOfDay.AccountingDimensionByPartners = AnalyticsOfDay.DimensionKey
	|		AND RemnantsOfDay.SalesOrder = AnalyticsOfDay.ARAPObject
	|WHERE
	|	RemnantsOfDay.DebtBalance <> 0
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	
	|UNION ALL
	|
	|SELECT
	|	RemnantsOfDay.Currency,
	|	&EndOfPeriod,
	|	RemnantsOfDay.AccountingDimensionByPartners,
	|	RemnantsOfDay.SalesOrder,
	|	RemnantsOfDay.ARAPDocument,
	|	RemnantsOfDay.DebtBalance,
	|	RemnantsOfDay.DebtLocalBalance,
	|	RemnantsOfDay.ARAPManBalance,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners IN (&DimensionCalculation)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	LEFT JOIN TTAnalyticsPerDay AS AnalyticsOfDay
	|		ON RemnantsOfDay.AccountingDimensionByPartners = AnalyticsOfDay.DimensionKey
	|			AND RemnantsOfDay.SalesOrder = AnalyticsOfDay.ARAPObject
	|WHERE
	|	RemnantsOfDay.DebtBalance = 0
	|	AND (RemnantsOfDay.DebtLocalBalance <> 0 OR RemnantsOfDay.ARAPManBalance <> 0)
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|
	|UNION ALL
	|
	|SELECT
	|	RemnantsOfDay.Currency,
	|	&EndOfPeriod,
	|	RemnantsOfDay.AccountingDimensionByPartners,
	|	RemnantsOfDay.SalesOrder,
	|	RemnantsOfDay.ARAPDocument,
	|	0,
	|	0,
	|	0,
	|	RemnantsOfDay.PrepaymentLocalBalance,
	|	RemnantsOfDay.PrepaymentManBalance
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners IN (&DimensionCalculation)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|WHERE
	|	RemnantsOfDay.ForReturnBalance = 0
	|	AND RemnantsOfDay.PrepaymentBalance = 0
	|	AND (RemnantsOfDay.PrepaymentLocalBalance <> 0 OR RemnantsOfDay.PrepaymentManBalance <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.OrderDocument AS OrderDocument,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	(CAST(Balance.Debt * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - Balance.DebtLocal AS DebtLocal,
	|	(CAST(Balance.Debt * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - Balance.ARAPMan AS ARAPMan
	|INTO TTUnrealizedKr
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|			ON Balance.Currency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|			ON (TRUE)
	|WHERE
	|	Balance.Debt <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.DebtLocal > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.OrderDocument AS SalesOrder,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	CASE WHEN Balance.DebtLocal < 0
	|		THEN -Balance.DebtLocal
	|		ELSE Balance.DebtLocal
	|	END AS DebtLocal,
	|	0 AS ARAPMan,
	|	0 AS PrepaymentLocal,
	|	0 AS PrepaymentMan,
	|	CASE WHEN Balance.DebtLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|	END AS BusinessOperation
	|INTO CalculationTable
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|WHERE
	|	Balance.Debt = 0 AND Balance.DebtLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.ARAPMan > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	0,
	|	CASE WHEN Balance.ARAPMan < 0
	|		THEN -Balance.ARAPMan
	|		ELSE Balance.ARAPMan
	|	END,
	|	0,
	|	0,
	|	CASE WHEN Balance.ARAPMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|	END
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|WHERE
	|	Balance.Debt = 0 AND Balance.ARAPMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.PrepaymentLocal > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	0,
	|	0,
	|	CASE WHEN Balance.PrepaymentLocal < 0
	|		THEN -Balance.PrepaymentLocal
	|		ELSE Balance.PrepaymentLocal
	|	END,
	|	0,
	|	CASE WHEN Balance.PrepaymentLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|	END
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|WHERE
	|	Balance.PrepaymentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.PrepaymentMan > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	0,
	|	0,
	|	0,
	|	CASE WHEN Balance.PrepaymentMan < 0
	|		THEN -Balance.PrepaymentMan
	|		ELSE Balance.PrepaymentMan
	|	END,
	|	CASE WHEN Balance.PrepaymentMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|	END
	|FROM
	|	TTBalancesAtEndOfDay AS Balance
	|WHERE
	|	Balance.PrepaymentMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE
	|		WHEN Balance.DebtLocal < 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	CASE WHEN Balance.DebtLocal < 0
	|		THEN -Balance.DebtLocal
	|		ELSE Balance.DebtLocal
	|	END,
	|	0,
	|	0,
	|	0,
	|	CASE WHEN Balance.DebtLocal < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|	END
	|FROM
	|	TTUnrealizedKr AS Balance
	|WHERE
	|	Balance.DebtLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.ARAPMan < 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	&EndOfPeriod,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.OrderDocument,
	|	Balance.ARAPDocument,
	|	0,
	|	CASE WHEN Balance.ARAPMan < 0
	|		THEN -Balance.ARAPMan
	|		ELSE Balance.ARAPMan
	|	END,
	|	0,
	|	0,
	|	CASE WHEN Balance.ARAPMan < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain)
	|	END
	|FROM
	|	TTUnrealizedKr AS Balance
	|WHERE
	|	Balance.ARAPMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationTable.Currency,
	|	CalculationTable.RecordType,
	|	CalculationTable.Period AS Period,
	|	CalculationTable.AccountingDimensionByPartners,
	|	CalculationTable.SalesOrder,
	|	CalculationTable.ARAPDocument,
	|	SUM(CalculationTable.DebtLocal) AS DebtLocal,
	|	SUM(CalculationTable.ARAPMan) AS ARAPMan,
	|	SUM(CalculationTable.PrepaymentLocal) AS PrepaymentLocal,
	|	SUM(CalculationTable.PrepaymentMan) AS PrepaymentMan,
	|	CalculationTable.BusinessOperation
	|INTO ExchangeRateDifferencesCustomersARAPAccountingByDocuments
	|FROM
	|	CalculationTable AS CalculationTable
	|
	|GROUP BY
	|	CalculationTable.Period,
	|	CalculationTable.BusinessOperation,
	|	CalculationTable.AccountingDimensionByPartners,
	|	CalculationTable.ARAPDocument,
	|	CalculationTable.SalesOrder,
	|	CalculationTable.Currency,
	|	CalculationTable.RecordType"
	+"
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesBankAccountCash()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.BankAccount AS Account
	|INTO BillsForDay
	|FROM
	|	AccumulationRegister.BankAccountCash.Turnovers(
	|			&BorderStartOfPeriod,
	|			&BorderEndOfPeriod,
	|			,
	|			Organization = &Organization
	|			AND (BankAccount.CashCurrency <> &ManagementAccountingCurrency
	|					OR BankAccount.CashCurrency <> &LocalAccountingCurrency)
	|	) AS RevolutionsPerDay
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.BankAccount.CashCurrency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.BankAccount AS BankAccount,
	|	(CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	(CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan
	|
	|INTO TTNonCashBalances
	|FROM
	|	AccumulationRegister.BankAccountCash.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|				AND (BankAccount.CashCurrency <> &ManagementAccountingCurrency
	|					OR BankAccount.CashCurrency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN BillsForDay
	|		ON LeftoversForDay.BankAccount = BillsForDay.Account
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.BankAccount.CashCurrency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|WHERE
	|	LeftoversForDay.SumBalance <> 0
	|	AND (NOT BillsForDay.Account IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND ((CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - LeftoversForDay.SumComplBalance <> 0
	|			OR (CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - LeftoversForDay.SumManBalance <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.BankAccount.CashCurrency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization Organization,
	|	LeftoversForDay.BankAccount AS BankAccount,
	|	-LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	-LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan
	|
	|FROM
	|	AccumulationRegister.BankAccountCash.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|				AND (BankAccount.CashCurrency <> &ManagementAccountingCurrency
	|					OR BankAccount.CashCurrency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN BillsForDay
	|		ON LeftoversForDay.BankAccount = BillsForDay.Account
	|WHERE
	|	LeftoversForDay.SumBalance = 0
	|	AND (NOT BillsForDay.Account IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.SumComplBalance <> 0 OR LeftoversForDay.SumManBalance <> 0)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.BankAccount AS BankAccount,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal < 0
	|		THEN -Balance.ExchangeRateDifferenceIsLocal
	|		ELSE Balance.ExchangeRateDifferenceIsLocal
	|	END AS ExchangeRateDifferenceIsLocal,
	|	0 AS ExchangeRateDifferenceMan,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END AS CashFlowItem,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessTransactionSetting
	|INTO TableOfNonCashCashTransactions
	|FROM
	|	TTNonCashBalances AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceIsLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.BankAccount AS BankAccount,
	|	0 AS ExchangeRateDifferenceIsLocal,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan < 0
	|		THEN -Balance.ExchangeRateDifferenceMan
	|		ELSE Balance.ExchangeRateDifferenceMan
	|	END AS ExchangeRateDifferenceMan,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END
	|FROM
	|	TTNonCashBalances AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfNonCashCashTransactions.Currency,
	|	TableOfNonCashCashTransactions.RecordType,
	|	TableOfNonCashCashTransactions.Period AS Period,
	|	TableOfNonCashCashTransactions.Organization,
	|	TableOfNonCashCashTransactions.BankAccount,
	|	SUM(TableOfNonCashCashTransactions.ExchangeRateDifferenceIsLocal) AS SumCompl,
	|	SUM(TableOfNonCashCashTransactions.ExchangeRateDifferenceMan) AS SumMan,
	|	TableOfNonCashCashTransactions.BusinessOperation,
	|	TableOfNonCashCashTransactions.CashFlowItem,
	|	TableOfNonCashCashTransactions.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO ExchangeRateDifferencesBankAccountCash
	|FROM
	|	TableOfNonCashCashTransactions AS TableOfNonCashCashTransactions
	|
	|GROUP BY
	|	TableOfNonCashCashTransactions.Currency,
	|	TableOfNonCashCashTransactions.Period,
	|	TableOfNonCashCashTransactions.Organization,
	|	TableOfNonCashCashTransactions.BankAccount,
	|	TableOfNonCashCashTransactions.BusinessOperation,
	|	TableOfNonCashCashTransactions.CashFlowItem,
	|	TableOfNonCashCashTransactions.RecordType,
	|	TableOfNonCashCashTransactions.BusinessTransactionSetting
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesCashAccountBalance()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.CashAccount AS CashAccount
	|INTO CheckoutForDay
	|FROM
	|	AccumulationRegister.CashAccountBalance.Turnovers(
	|			&BorderStartOfPeriod,
	|			&BorderEndOfPeriod,
	|			,
	|			Organization = &Organization
	|			AND (CashAccount IN (&CashAccounts) OR &ForAllSalesRegisters)
	|			AND (CashAccount.CashCurrency <> &ManagementAccountingCurrency
	|					OR CashAccount.CashCurrency <> &LocalAccountingCurrency)
	|	) AS RevolutionsPerDay
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.CashAccount.CashCurrency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.CashAccount AS CashAccount,
	|	(CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	(CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan
	|
	|INTO TTCashBalances
	|FROM
	|	AccumulationRegister.CashAccountBalance.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|			AND (CashAccount IN (&CashAccounts) OR &ForAllSalesRegisters)
	|			AND (CashAccount.CashCurrency <> &ManagementAccountingCurrency
	|				OR CashAccount.CashCurrency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN CheckoutForDay
	|		ON LeftoversForDay.CashAccount = CheckoutForDay.CashAccount
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.CashAccount.CashCurrency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|WHERE
	|	LeftoversForDay.SumBalance <> 0
	|	AND (NOT CheckoutForDay.CashAccount IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND ((CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - LeftoversForDay.SumComplBalance <> 0
	|			OR (CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - LeftoversForDay.SumManBalance <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.CashAccount.CashCurrency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.CashAccount AS CashAccount,
	|	-LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	-LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan
	|
	|FROM
	|	AccumulationRegister.CashAccountBalance.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|			AND (CashAccount IN (&CashAccounts) OR &ForAllSalesRegisters)
	|			AND (CashAccount.CashCurrency <> &ManagementAccountingCurrency
	|				OR CashAccount.CashCurrency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN CheckoutForDay
	|		ON LeftoversForDay.CashAccount = CheckoutForDay.CashAccount
	|WHERE
	|	LeftoversForDay.SumBalance = 0
	|	AND (NOT CheckoutForDay.CashAccount IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.SumComplBalance <> 0 OR LeftoversForDay.SumManBalance <> 0)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.CashAccount AS CashAccount,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal < 0
	|		THEN -Balance.ExchangeRateDifferenceIsLocal
	|		ELSE Balance.ExchangeRateDifferenceIsLocal
	|	END AS ExchangeRateDifferenceIsLocal,
	|	0 AS ExchangeRateDifferenceMan,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END AS CashFlowItem,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessTransactionSetting
	|INTO CashOnHandTable
	|FROM
	|	TTCashBalances AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceIsLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	&EndOfPeriod,
	|	Balance.Organization,
	|	Balance.CashAccount,
	|	0,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan < 0
	|		THEN -Balance.ExchangeRateDifferenceMan
	|		ELSE Balance.ExchangeRateDifferenceMan
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END
	|FROM
	|	TTCashBalances AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashOnHandTable.Currency,
	|	CashOnHandTable.RecordType,
	|	CashOnHandTable.Period AS Period,
	|	CashOnHandTable.Organization,
	|	CashOnHandTable.CashAccount,
	|	SUM(CashOnHandTable.ExchangeRateDifferenceIsLocal) AS SumCompl,
	|	SUM(CashOnHandTable.ExchangeRateDifferenceMan) AS SumMan,
	|	CashOnHandTable.BusinessOperation,
	|	CashOnHandTable.CashFlowItem,
	|	CashOnHandTable.BusinessTransactionSetting
	|INTO ExchangeRateDifferencesCashAccountBalance
	|FROM
	|	CashOnHandTable AS CashOnHandTable
	|
	|GROUP BY
	|	CashOnHandTable.Currency,
	|	CashOnHandTable.Period,
	|	CashOnHandTable.Organization,
	|	CashOnHandTable.CashAccount,
	|	CashOnHandTable.BusinessOperation,
	|	CashOnHandTable.CashFlowItem,
	|	CashOnHandTable.RecordType,
	|	CashOnHandTable.BusinessTransactionSetting
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesCashInCashRegistersCR()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.CashRegister AS CashRegister
	|INTO CashRegisterForDay
	|FROM
	|	AccumulationRegister.CashInCashRegistersCR.Turnovers(
	|			&BorderStartOfPeriod,
	|			&BorderEndOfPeriod,
	|			,
	|			Organization = &Organization
	|			AND (CashRegister.CashCurrency <> &ManagementAccountingCurrency
	|					OR CashRegister.CashCurrency <> &LocalAccountingCurrency)
	|	) AS RevolutionsPerDay
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.CashRegister.CashCurrency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.CashRegister AS CashAccount,
	|	CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2)) - LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2)) - LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan
	|
	|INTO TTBalancesAtCashRegister
	|FROM
	|	AccumulationRegister.CashInCashRegistersCR.Balance(
	|		&BorderEndOfPeriod,
	|		Organization = &Organization
	|			AND (CashRegister.CashCurrency <> &ManagementAccountingCurrency 
	|				OR CashRegister.CashCurrency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN CashRegisterForDay
	|		ON LeftoversForDay.CashRegister = CashRegisterForDay.CashRegister
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.CashRegister.CashCurrency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON TRUE
	|WHERE
	|	LeftoversForDay.SumBalance <> 0
	|	AND (NOT CashRegisterForDay.CashRegister IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2)) - LeftoversForDay.SumComplBalance <> 0
	|		OR CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2)) - LeftoversForDay.SumManBalance <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.CashRegister.CashCurrency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.CashRegister AS CashAccount,
	|	-LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	-LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan
	|FROM
	|	AccumulationRegister.CashInCashRegistersCR.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|				AND (CashRegister.CashCurrency <> &ManagementAccountingCurrency
	|					OR CashRegister.CashCurrency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN CashRegisterForDay
	|		ON LeftoversForDay.CashRegister = CashRegisterForDay.CashRegister
	|WHERE
	|	LeftoversForDay.SumBalance = 0
	|	AND (NOT CashRegisterForDay.CashRegister IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.SumComplBalance <> 0 OR LeftoversForDay.SumManBalance <> 0)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.CashAccount AS CashAccount,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal < 0
	|		THEN -Balance.ExchangeRateDifferenceIsLocal
	|		ELSE Balance.ExchangeRateDifferenceIsLocal
	|	END AS ExchangeRateDifferenceIsLocal,
	|	0 AS ExchangeRateDifferenceMan,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END AS CashFlowItem,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessTransactionSetting
	|
	|INTO TableDSVCashCashRegisters
	|FROM
	|	TTBalancesAtCashRegister AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceIsLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	&EndOfPeriod,
	|	Balance.Organization,
	|	Balance.CashAccount,
	|	0,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan < 0
	|		THEN -Balance.ExchangeRateDifferenceMan
	|		ELSE Balance.ExchangeRateDifferenceMan
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END AS CashFlowItem,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTBalancesAtCashRegister AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableDSVCashCashRegisters.Currency,
	|	TableDSVCashCashRegisters.RecordType,
	|	TableDSVCashCashRegisters.Period AS Period,
	|	TableDSVCashCashRegisters.Organization,
	|	TableDSVCashCashRegisters.CashAccount AS CashRegister,
	|	SUM(TableDSVCashCashRegisters.ExchangeRateDifferenceIsLocal) AS SumCompl,
	|	SUM(TableDSVCashCashRegisters.ExchangeRateDifferenceMan) AS SumMan,
	|	TableDSVCashCashRegisters.BusinessOperation,
	|	TableDSVCashCashRegisters.CashFlowItem,
	|	TableDSVCashCashRegisters.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO ExchangeRateDifferencesCashInCashRegistersCR
	|FROM
	|	TableDSVCashCashRegisters AS TableDSVCashCashRegisters
	|
	|GROUP BY
	|	TableDSVCashCashRegisters.Currency,
	|	TableDSVCashCashRegisters.Period,
	|	TableDSVCashCashRegisters.Organization,
	|	TableDSVCashCashRegisters.CashAccount,
	|	TableDSVCashCashRegisters.BusinessOperation,
	|	TableDSVCashCashRegisters.CashFlowItem,
	|	TableDSVCashCashRegisters.RecordType,
	|	TableDSVCashCashRegisters.BusinessTransactionSetting
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesAdvanceHolderCash()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.Currency AS Currency,
	|	RevolutionsPerDay.Organization AS Organization,
	|	RevolutionsPerDay.AdvanceHolder AS AdvanceHolder,
	|	RevolutionsPerDay.Department AS Department,
	|	RevolutionsPerDay.IssuancePurpose AS IssuancePurpose
	|
	|INTO AccountabilityForDay
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Turnovers(
	|			&BorderStartOfPeriod,
	|			&BorderEndOfPeriod,
	|			,
	|			Organization = &Organization
	|			AND (AdvanceHolder IN (&AdvanceHolders) OR &ForAllAccountablePersons)
	|			AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RevolutionsPerDay
	|WHERE
	|	RevolutionsPerDay.SumTurnover <> 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.AdvanceHolder AS AdvanceHolder,
	|	LeftoversForDay.Department AS Department,
	|	LeftoversForDay.IssuancePurpose AS IssuancePurpose,
	|	(CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - LeftoversForDay.SumComplBalance AS SumCompl,
	|	(CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - LeftoversForDay.SumManBalance AS SumMan
	|
	|INTO TTBalancesOfAccountablePersons
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|			AND (AdvanceHolder IN (&AdvanceHolders) OR &ForAllAccountablePersons)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN AccountabilityForDay
	|		ON LeftoversForDay.Currency = AccountabilityForDay.Currency
	|			AND LeftoversForDay.Currency = AccountabilityForDay.Currency
	|			AND LeftoversForDay.Organization = AccountabilityForDay.Organization
	|			AND LeftoversForDay.AdvanceHolder = AccountabilityForDay.AdvanceHolder
	|			AND LeftoversForDay.Department = AccountabilityForDay.Department
	|			AND LeftoversForDay.IssuancePurpose = AccountabilityForDay.IssuancePurpose
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.Currency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|WHERE
	|	LeftoversForDay.SumBalance < 0
	|	AND (NOT AccountabilityForDay.AdvanceHolder IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND ((CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - LeftoversForDay.SumComplBalance <> 0
	|			OR (CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - LeftoversForDay.SumManBalance <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY),
	|	LeftoversForDay.Organization,
	|	LeftoversForDay.AdvanceHolder,
	|	LeftoversForDay.Department,
	|	LeftoversForDay.IssuancePurpose,
	|	-LeftoversForDay.SumComplBalance,
	|	-LeftoversForDay.SumManBalance
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|			AND (AdvanceHolder IN (&AdvanceHolders) OR &ForAllAccountablePersons)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN AccountabilityForDay
	|		ON LeftoversForDay.Currency = AccountabilityForDay.Currency
	|			AND LeftoversForDay.Currency = AccountabilityForDay.Currency
	|			AND LeftoversForDay.Organization = AccountabilityForDay.Organization
	|			AND LeftoversForDay.AdvanceHolder = AccountabilityForDay.AdvanceHolder
	|			AND LeftoversForDay.Department = AccountabilityForDay.Department
	|			AND LeftoversForDay.IssuancePurpose = AccountabilityForDay.IssuancePurpose
	|WHERE
	|	LeftoversForDay.SumBalance = 0
	|	AND (NOT AccountabilityForDay.AdvanceHolder IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.SumComplBalance <> 0 OR LeftoversForDay.SumManBalance <> 0)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.AdvanceHolder AS AdvanceHolder,
	|	Balance.Department AS Department,
	|	Balance.IssuancePurpose AS IssuancePurpose,
	|	CASE WHEN Balance.SumCompl < 0
	|		THEN -Balance.SumCompl
	|		ELSE Balance.SumCompl
	|	END AS SumCompl,
	|	0 AS SumMan,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END AS CashFlowItem,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessTransactionSetting
	|INTO TableOfDSOOfAccountablePersons
	|FROM
	|	TTBalancesOfAccountablePersons AS Balance
	|WHERE
	|	Balance.SumCompl <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	&EndOfPeriod,
	|	Balance.Organization,
	|	Balance.AdvanceHolder,
	|	Balance.Department,
	|	Balance.IssuancePurpose,
	|	0,
	|	CASE WHEN Balance.SumMan < 0
	|		THEN -Balance.SumMan
	|		ELSE Balance.SumMan
	|	END,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END
	|FROM
	|	TTBalancesOfAccountablePersons AS Balance
	|WHERE
	|	Balance.SumMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfDSOOfAccountablePersons.Currency,
	|	TableOfDSOOfAccountablePersons.RecordType,
	|	TableOfDSOOfAccountablePersons.Period AS Period,
	|	TableOfDSOOfAccountablePersons.Organization,
	|	TableOfDSOOfAccountablePersons.AdvanceHolder,
	|	TableOfDSOOfAccountablePersons.Department,
	|	TableOfDSOOfAccountablePersons.IssuancePurpose,
	|	SUM(TableOfDSOOfAccountablePersons.SumCompl) AS SumCompl,
	|	SUM(TableOfDSOOfAccountablePersons.SumMan) AS SumMan,
	|	TableOfDSOOfAccountablePersons.BusinessOperation,
	|	TableOfDSOOfAccountablePersons.CashFlowItem,
	|	TableOfDSOOfAccountablePersons.BusinessTransactionSetting
	|INTO ExchangeRateDifferencesAdvanceHolderCash
	|FROM
	|	TableOfDSOOfAccountablePersons AS TableOfDSOOfAccountablePersons
	|
	|GROUP BY
	|	TableOfDSOOfAccountablePersons.Currency,
	|	TableOfDSOOfAccountablePersons.Period,
	|	TableOfDSOOfAccountablePersons.Organization,
	|	TableOfDSOOfAccountablePersons.AdvanceHolder,
	|	TableOfDSOOfAccountablePersons.Department,
	|	TableOfDSOOfAccountablePersons.IssuancePurpose,
	|	TableOfDSOOfAccountablePersons.BusinessOperation,
	|	TableOfDSOOfAccountablePersons.CashFlowItem,
	|	TableOfDSOOfAccountablePersons.RecordType,
	|	TableOfDSOOfAccountablePersons.BusinessTransactionSetting
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesCashInTransit()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.Currency AS Currency,
	|	RevolutionsPerDay.Organization AS Organization,
	|	RevolutionsPerDay.Recipient AS Recipient,
	|	RevolutionsPerDay.Sender AS Sender,
	|	RevolutionsPerDay.CashTransferKind AS TypeOfTransfer,
	|	RevolutionsPerDay.Counterparty AS Counterparty
	|
	|INTO MoneyOnRoadForDay
	|FROM
	|	AccumulationRegister.CashInTransit.Turnovers(
	|			&BorderStartOfPeriod,
	|			&BorderEndOfPeriod,
	|			,
	|			Organization = &Organization
	|			AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RevolutionsPerDay
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.Recipient AS Recipient,
	|	LeftoversForDay.Sender AS Sender,
	|	LeftoversForDay.CashTransferKind AS CashTransferKind,
	|	LeftoversForDay.Counterparty AS Counterparty,
	|	LeftoversForDay.Contract AS Contract,
	|	LeftoversForDay.SumBalance AS Sum,
	|	(CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	(CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan
	|
	|INTO TTRemainsInTransit
	|FROM
	|	AccumulationRegister.CashInTransit.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN MoneyOnRoadForDay
	|		ON LeftoversForDay.Currency = MoneyOnRoadForDay.Currency
	|			AND LeftoversForDay.Currency = MoneyOnRoadForDay.Currency
	|			AND LeftoversForDay.Organization = MoneyOnRoadForDay.Organization
	|			AND LeftoversForDay.Recipient = MoneyOnRoadForDay.Recipient
	|			AND LeftoversForDay.Sender = MoneyOnRoadForDay.Sender
	|			AND LeftoversForDay.CashTransferKind = MoneyOnRoadForDay.TypeOfTransfer
	|			AND LeftoversForDay.Counterparty = MoneyOnRoadForDay.Counterparty
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.Currency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|WHERE
	|	LeftoversForDay.SumBalance <> 0
	|	AND (NOT MoneyOnRoadForDay.Currency IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND ((CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2))) - LeftoversForDay.SumComplBalance <> 0
	|			OR (CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2))) - LeftoversForDay.SumManBalance <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.Recipient AS Recipient,
	|	LeftoversForDay.Sender AS Sender,
	|	LeftoversForDay.CashTransferKind AS CashTransferKind,
	|	LeftoversForDay.Counterparty AS Counterparty,
	|	LeftoversForDay.Contract AS Contract,
	|	-LeftoversForDay.SumBalance AS Sum,
	|	-LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	-LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan
	|FROM
	|	AccumulationRegister.CashInTransit.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN MoneyOnRoadForDay
	|		ON LeftoversForDay.Currency = MoneyOnRoadForDay.Currency
	|			AND LeftoversForDay.Currency = MoneyOnRoadForDay.Currency
	|			AND LeftoversForDay.Organization = MoneyOnRoadForDay.Organization
	|			AND LeftoversForDay.Recipient = MoneyOnRoadForDay.Recipient
	|			AND LeftoversForDay.Sender = MoneyOnRoadForDay.Sender
	|			AND LeftoversForDay.CashTransferKind = MoneyOnRoadForDay.TypeOfTransfer
	|			AND LeftoversForDay.Counterparty = MoneyOnRoadForDay.Counterparty
	|WHERE
	|	LeftoversForDay.SumBalance = 0
	|	AND (NOT MoneyOnRoadForDay.Currency IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.SumComplBalance <> 0 OR LeftoversForDay.SumManBalance <> 0)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.Recipient AS Recipient,
	|	Balance.Sender AS Sender,
	|	Balance.CashTransferKind AS CashTransferKind,
	|	Balance.Counterparty AS Counterparty,
	|	Balance.Contract AS Contract,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal < 0
	|		THEN -Balance.ExchangeRateDifferenceIsLocal
	|		ELSE Balance.ExchangeRateDifferenceIsLocal
	|	END AS ExchangeRateDifferenceIsLocal,
	|	0 AS ExchangeRateDifferenceMan,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END AS CashFlowItem,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END AS BusinessTransactionSetting
	|INTO TableOfArcPaths
	|FROM
	|	TTRemainsInTransit AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceIsLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	&EndOfPeriod,
	|	Balance.Organization,
	|	Balance.Recipient,
	|	Balance.Sender,
	|	Balance.CashTransferKind,
	|	Balance.Counterparty,
	|	Balance.Contract,
	|	0,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan < 0
	|		THEN -Balance.ExchangeRateDifferenceMan
	|		ELSE Balance.ExchangeRateDifferenceMan
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss)
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Catalog.CashFlowReportItems.ExchangeRateDifferencesProfit_)
	|		ELSE VALUE(Catalog.CashFlowReportItems.ExchangeDifferencesLoss)
	|	END,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
	|	END
	|FROM
	|	TTRemainsInTransit AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfArcPaths.Currency,
	|	TableOfArcPaths.RecordType,
	|	TableOfArcPaths.Period AS Period,
	|	TableOfArcPaths.Organization,
	|	TableOfArcPaths.Recipient,
	|	TableOfArcPaths.Sender AS Sender,
	|	TableOfArcPaths.CashTransferKind,
	|	TableOfArcPaths.Counterparty,
	|	TableOfArcPaths.Contract AS Contract,
	|	SUM(TableOfArcPaths.ExchangeRateDifferenceIsLocal) AS SumCompl,
	|	SUM(TableOfArcPaths.ExchangeRateDifferenceMan) AS SumMan,
	|	TableOfArcPaths.BusinessOperation,
	|	TableOfArcPaths.CashFlowItem,
	|	TableOfArcPaths.BusinessTransactionSetting
	|INTO ExchangeRateDifferencesCashInTransit
	|FROM
	|	TableOfArcPaths AS TableOfArcPaths
	|
	|GROUP BY
	|	TableOfArcPaths.Currency,
	|	TableOfArcPaths.Period,
	|	TableOfArcPaths.Organization,
	|	TableOfArcPaths.Recipient,
	|	TableOfArcPaths.Sender,
	|	TableOfArcPaths.CashTransferKind,
	|	TableOfArcPaths.Counterparty,
	|	TableOfArcPaths.Contract,
	|	TableOfArcPaths.BusinessOperation,
	|	TableOfArcPaths.CashFlowItem,
	|	TableOfArcPaths.RecordType,
	|	TableOfArcPaths.BusinessTransactionSetting
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesFinancialInstrumentsARAP()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT
	|	RevolutionsPerDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RevolutionsPerDay.Contract AS Contract,
	|	RevolutionsPerDay.Contract.ContractKind AS ContractKind,
	|	RevolutionsPerDay.ARAPDocument AS ARAPDocument,
	|	RevolutionsPerDay.Currency AS Currency,
	|	RevolutionsPerDay.AmountType AS AmountType,
	|	RevolutionsPerDay.Recorder AS DocumentPayments,
	|	RevolutionsPerDay.PointInTime AS PointInTime,
	|	SUM(CASE WHEN RevolutionsPerDay.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RevolutionsPerDay.Sum
	|		ELSE -RevolutionsPerDay.Sum
	|	END) AS SumTurnover,
	|	SUM(CASE WHEN RevolutionsPerDay.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RevolutionsPerDay.SumCompl
	|		ELSE -RevolutionsPerDay.SumCompl
	|	END) AS SumComplTurnover
	|INTO ContractPerDayAccordingToPaymentDocuments
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS RevolutionsPerDay
	|WHERE
	|	RevolutionsPerDay.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RevolutionsPerDay.AccountingDimensionByPartners.Organization = &Organization
	|	AND VALUETYPE(RevolutionsPerDay.Recorder) <> TYPE(Document.ExchangeDifferenceCalculation)
	|	AND VALUETYPE(RevolutionsPerDay.Recorder) <> TYPE(Document.LoanAndDepositInterestCharge)
	|	AND RevolutionsPerDay.SumCompl <> 0
	|	AND (RevolutionsPerDay.Currency <> &ManagementAccountingCurrency
	|		OR RevolutionsPerDay.Currency <> &LocalAccountingCurrency)
	|	AND (RevolutionsPerDay.AmountType IN (&TypesOfAmounts) OR &ForAllTypesOfAmounts)
	|	AND (CASE WHEN RevolutionsPerDay.Contract.ContractKind = &NatureOfContractDeposit
	|				OR RevolutionsPerDay.Contract.ContractKind = &NatureOfContractLoanIssued
	|			THEN VALUE(AccumulationRecordType.Expense)
	|			ELSE VALUE(AccumulationRecordType.Receipt)
	|		END) = RevolutionsPerDay.RecordType
	|
	|GROUP BY
	|	RevolutionsPerDay.AccountingDimensionByPartners,
	|	RevolutionsPerDay.Contract,
	|	RevolutionsPerDay.ARAPDocument,
	|	RevolutionsPerDay.Currency,
	|	RevolutionsPerDay.AmountType,
	|	RevolutionsPerDay.Recorder,
	|	RevolutionsPerDay.PointInTime
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RevolutionsPerDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RevolutionsPerDay.Contract AS Contract,
	|	RevolutionsPerDay.AmountType AS AmountType,
	|	SUM(RevolutionsPerDay.SumTurnover) AS SumTurnover,
	|	SUM(RevolutionsPerDay.SumComplTurnover) AS SumComplTurnover
	|INTO ContractsPerDay
	|FROM
	|	ContractPerDayAccordingToPaymentDocuments AS RevolutionsPerDay
	|
	|GROUP BY
	|	RevolutionsPerDay.AccountingDimensionByPartners,
	|	RevolutionsPerDay.Contract,
	|	RevolutionsPerDay.AmountType
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	Contract,
	|	AmountType
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS AccountingDimensionByPartners,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS AmountType
	|INTO ConclusionOfLeaseContracts
	|WHERE FALSE
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RegisterRecords.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RegisterRecords.Contract AS Contract,
	|	RegisterRecords.AmountType AS AmountType
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS RegisterRecords
	|WHERE
	|	VALUETYPE(RegisterRecords.Recorder) = TYPE(Document.SigningOfLeaseContract)
	|	AND RegisterRecords.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|	AND RegisterRecords.Period <= &EndOfPeriod
	|	AND RegisterRecords.AccountingDimensionByPartners.Organization = &Organization
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	Contract,
	|	AmountType
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&EndOfPeriod AS Period,
	|	LeftoversForDay.Currency AS Currency,
	|	LeftoversForDay.SumBalance AS CurrencyBalance_,
	|	LeftoversForDay.SumComplBalance AS RemainderOfLocal,
	|	LeftoversForDay.SumManBalance AS BalanceMan,
	|	ISNULL(ContractsPerDay.SumTurnover, 0) AS SumTurnover,
	|	ISNULL(ContractsPerDay.SumComplTurnover, 0) AS SumComplTurnover,
	|	CASE
	|		WHEN LeftoversForDay.Contract.ContractKind = &NatureOfLeaseContract
	|				AND NOT LeftoversForDay.Contract.RecognizeLeasedItemsInLocalAccounting
	|			THEN 0
	|		ELSE
	|			CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2)) - LeftoversForDay.SumComplBalance
	|	END AS ExchangeRateDifferenceIsLocal,
	|	CASE 
	|		WHEN LeftoversForDay.Contract.ContractKind = &NatureOfLeaseContract
	|				AND NOT LeftoversForDay.Contract.RecognizeLeasedAssetsInManagementAccounting
	|			THEN 0
	|		ELSE
	|			CAST(LeftoversForDay.SumBalance * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2)) - LeftoversForDay.SumManBalance
	|	END AS ExchangeRateDifferenceMan,
	|	CurrencyExchangeRate.CourseNumerator AS CourseNumeratorLocal,
	|	CurrencyExchangeRate.CourseDenominator AS CourseDenominatorLocal,
	|	ManSExchangeRate.CourseNumerator AS CourseNumeratorMan,
	|	ManSExchangeRate.CourseDenominator AS CourseDenominatorMan,
	|	LeftoversForDay.AmountType AS AmountType,
	|	LeftoversForDay.Contract AS Contract,
	|	LeftoversForDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	LeftoversForDay.ARAPDocument AS ARAPDocument,
	|	LeftoversForDay.Contract.ContractKind AS ContractKind
	|
	|INTO TTBalancesWithExchangeRate
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners.Organization = &Organization
	|			AND (AmountType IN (&TypesOfAmounts) OR &ForAllTypesOfAmounts)
	|			AND (Currency <> &ManagementAccountingCurrency
	|				OR Currency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|	LEFT JOIN ContractsPerDay
	|	ON LeftoversForDay.AccountingDimensionByPartners = ContractsPerDay.AccountingDimensionByPartners
	|		AND LeftoversForDay.Contract = ContractsPerDay.Contract
	|		AND LeftoversForDay.AmountType = ContractsPerDay.AmountType
	|	LEFT JOIN ConclusionOfLeaseContracts
	|	ON LeftoversForDay.AccountingDimensionByPartners = ConclusionOfLeaseContracts.AccountingDimensionByPartners
	|		AND LeftoversForDay.Contract = ConclusionOfLeaseContracts.Contract
	|		AND LeftoversForDay.AmountType = ConclusionOfLeaseContracts.AmountType
	|	LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.Currency = CurrencyExchangeRate.Currency
	|	LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|WHERE
	|	LeftoversForDay.SumBalance <> 0
	|	AND (NOT ContractsPerDay.Contract IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			AND NOT ConclusionOfLeaseContracts.Contract IS NULL
	|		OR LeftoversForDay.AmountType <> VALUE(Enum.TypesOfLeasePayments.DepositPayment))
	|
	|UNION ALL
	|
	|SELECT
	|	&EndOfPeriod AS Period,
	|	LeftoversForDay.Currency AS Currency,
	|	0 AS CurrencyBalance_,
	|	LeftoversForDay.SumComplBalance AS RemainderOfLocal,
	|	LeftoversForDay.SumManBalance AS BalanceMan,
	|	ISNULL(ContractsPerDay.SumTurnover, 0) AS SumTurnover,
	|	ISNULL(ContractsPerDay.SumComplTurnover, 0) AS SumComplTurnover,
	|	-LeftoversForDay.SumComplBalance AS ExchangeRateDifferenceIsLocal,
	|	-LeftoversForDay.SumManBalance AS ExchangeRateDifferenceMan,
	|	CurrencyExchangeRate.CourseNumerator AS CourseNumeratorLocal,
	|	CurrencyExchangeRate.CourseDenominator AS CourseDenominatorLocal,
	|	ManSExchangeRate.CourseNumerator AS CourseNumeratorMan,
	|	ManSExchangeRate.CourseDenominator AS CourseDenominatorMan,
	|	LeftoversForDay.AmountType AS AmountType,
	|	LeftoversForDay.Contract AS Contract,
	|	LeftoversForDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	LeftoversForDay.ARAPDocument AS ARAPDocument,
	|	LeftoversForDay.Contract.ContractKind AS ContractKind
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners.Organization = &Organization
	|			AND (AmountType IN (&TypesOfAmounts) OR &ForAllTypesOfAmounts)
	|			AND (Currency <> &ManagementAccountingCurrency
	|				OR Currency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|	LEFT JOIN ContractsPerDay
	|	ON LeftoversForDay.AccountingDimensionByPartners = ContractsPerDay.AccountingDimensionByPartners
	|		AND LeftoversForDay.Contract = ContractsPerDay.Contract
	|		AND LeftoversForDay.AmountType = ContractsPerDay.AmountType
	|	LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.Currency = CurrencyExchangeRate.Currency
	|	LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|WHERE
	|	LeftoversForDay.SumBalance = 0
	|	AND (LeftoversForDay.SumComplBalance <> 0 OR LeftoversForDay.SumManBalance <> 0)
	|	AND (NOT ContractsPerDay.Contract IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|
	|INDEX BY
	|	LeftoversForDay.AccountingDimensionByPartners,
	|	LeftoversForDay.Contract,
	|	LeftoversForDay.AmountType
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	LeftoversForDay.CurrencyBalance_ AS CurrencyBalance_,
	|	LeftoversForDay.RemainderOfLocal AS RemainderOfLocal,
	|	LeftoversForDay.BalanceMan AS BalanceMan,
	|	LeftoversForDay.ExchangeRateDifferenceIsLocal AS ExchangeRateDifferenceIsLocal,
	|	LeftoversForDay.ExchangeRateDifferenceMan AS ExchangeRateDifferenceMan,
	|	LeftoversForDay.SumTurnover AS SumTurnover,
	|	LeftoversForDay.SumComplTurnover AS SumComplTurnover,
	|	LeftoversForDay.CourseNumeratorLocal AS CourseNumeratorLocal,
	|	LeftoversForDay.CourseDenominatorLocal AS CourseDenominatorLocal,
	|	LeftoversForDay.CourseNumeratorMan AS CourseNumeratorMan,
	|	LeftoversForDay.CourseDenominatorMan AS CourseDenominatorMan,
	|	LeftoversForDay.AmountType AS AmountType,
	|	LeftoversForDay.Contract AS Contract,
	|	LeftoversForDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	LeftoversForDay.ARAPDocument AS ARAPDocument,
	|	LeftoversForDay.ContractKind AS ContractKind,
	|	&BusinessOperation AS BusinessOperation,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTLoanDepositBalances
	|FROM
	|	TTBalancesWithExchangeRate AS LeftoversForDay
	|WHERE
	|	(LeftoversForDay.ExchangeRateDifferenceIsLocal <> 0 OR LeftoversForDay.ExchangeRateDifferenceMan <> 0)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0 
	|		THEN VALUE(AccumulationRecordType.Receipt) 
	|		ELSE VALUE(AccumulationRecordType.Expense) 
	|	END AS RecordType,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal < 0
	|		THEN -Balance.ExchangeRateDifferenceIsLocal
	|		ELSE Balance.ExchangeRateDifferenceIsLocal
	|	END AS SumCompl,
	|	0 AS SumMan,
	|	Balance.ExchangeRateDifferenceIsLocal AS ExchangeRateDifferenceLocalReg,
	|	0 AS ExchangeRateDifferenceManReg,
	|	Balance.AmountType AS AmountType,
	|	Balance.Contract AS Contract,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	Balance.ContractKind AS ContractKind,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TableOfLoansDeposits
	|FROM
	|	TTLoanDepositBalances AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceIsLocal <> 0
	|	AND NOT Balance.AmountType IN (&ReverseReflectionOfExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0 
	|		THEN VALUE(AccumulationRecordType.Receipt) 
	|		ELSE VALUE(AccumulationRecordType.Expense) 
	|	END AS RecordType,
	|	0 AS SumCompl,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan < 0
	|		THEN -Balance.ExchangeRateDifferenceMan
	|		ELSE Balance.ExchangeRateDifferenceMan
	|	END AS SumMan,
	|	0 AS ExchangeRateDifferenceLocalReg,
	|	Balance.ExchangeRateDifferenceMan AS ExchangeRateDifferenceManReg,
	|	Balance.AmountType AS AmountType,
	|	Balance.Contract AS Contract,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	Balance.ContractKind AS ContractKind,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTLoanDepositBalances AS Balance
	|WHERE
	|	Balance.ExchangeRateDifferenceMan <> 0
	|	AND NOT Balance.AmountType IN (&ReverseReflectionOfExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	CASE WHEN Balance.ExchangeRateDifferenceIsLocal > 0
	|		THEN -Balance.ExchangeRateDifferenceIsLocal
	|		ELSE Balance.ExchangeRateDifferenceIsLocal
	|	END AS SumCompl,
	|	0 AS SumMan,
	|	Balance.ExchangeRateDifferenceIsLocal AS ExchangeRateDifferenceLocalReg,
	|	0 AS ExchangeRateDifferenceManReg,
	|	Balance.AmountType AS AmountType,
	|	Balance.Contract AS Contract,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	Balance.ContractKind AS ContractKind,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTLoanDepositBalances AS Balance
	|WHERE
	|	Balance.AmountType IN (&ReverseReflectionOfExpenses)
	|	AND Balance.ExchangeRateDifferenceIsLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	0 AS SumCompl,
	|	CASE WHEN Balance.ExchangeRateDifferenceMan > 0
	|		THEN -Balance.ExchangeRateDifferenceMan
	|		ELSE Balance.ExchangeRateDifferenceMan
	|	END AS SumMan,
	|	0 AS ExchangeRateDifferenceLocalReg,
	|	Balance.ExchangeRateDifferenceMan AS ExchangeRateDifferenceManReg,
	|	Balance.AmountType AS AmountType,
	|	Balance.Contract AS Contract,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	Balance.ContractKind AS ContractKind,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTLoanDepositBalances AS Balance
	|WHERE
	|	Balance.AmountType IN (&ReverseReflectionOfExpenses)
	|	AND Balance.ExchangeRateDifferenceMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfLoansDeposits.Currency AS Currency,
	|	TableOfLoansDeposits.Period AS Period,
	|	TableOfLoansDeposits.RecordType AS RecordType,
	|	SUM(TableOfLoansDeposits.SumCompl) AS SumCompl,
	|	SUM(TableOfLoansDeposits.SumMan) AS SumMan,
	|	SUM(TableOfLoansDeposits.ExchangeRateDifferenceLocalReg) AS SumOfLocalReg,
	|	SUM(TableOfLoansDeposits.ExchangeRateDifferenceManReg) AS AmountOfManReg,
	|	TableOfLoansDeposits.AmountType AS AmountType,
	|	TableOfLoansDeposits.Contract AS Contract,
	|	TableOfLoansDeposits.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableOfLoansDeposits.ARAPDocument AS ARAPDocument,
	|	TableOfLoansDeposits.ContractKind AS ContractKind,
	|	TableOfLoansDeposits.BusinessOperation,
	|	TableOfLoansDeposits.BusinessTransactionSetting
	|INTO ExchangeRateDifferencesFinancialInstrumentsARAP
	|FROM
	|	TableOfLoansDeposits AS TableOfLoansDeposits
	|
	|GROUP BY
	|	TableOfLoansDeposits.Currency,
	|	TableOfLoansDeposits.Period,
	|	TableOfLoansDeposits.AccountingDimensionByPartners,
	|	TableOfLoansDeposits.ARAPDocument,
	|	TableOfLoansDeposits.Contract,
	|	TableOfLoansDeposits.ContractKind,
	|	TableOfLoansDeposits.AmountType,
	|	TableOfLoansDeposits.BusinessOperation,
	|	TableOfLoansDeposits.RecordType,
	|	TableOfLoansDeposits.BusinessTransactionSetting
	|;
	|";
	
EndFunction
Function QueryTextExchangeRateDifferencesLossAllowance()
	
	// we overestimate only the currency of the upr.
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.AccountingDimensionByPartners AS DimensionKey,
	|	RevolutionsPerDay.ARAPObject AS ARAPObject,
	|	RevolutionsPerDay.ARAPDocument AS ARAPDocument,
	|	RevolutionsPerDay.AmountType AS AmountType
	|INTO AnalyticsOfDay
	|FROM
	|	AccumulationRegister.LossAllowance.Turnovers(
	|			&BorderStartOfPeriod,
	|			&BorderEndOfPeriod,
	|			,
	|			AccountingDimensionByPartners IN (&DimensionCalculation) AND Currency <> &ManagementAccountingCurrency
	|	) AS RevolutionsPerDay
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.ARAPObject AS ARAPObject,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	Balance.AmountType AS AmountType,
	|	Balance.Currency AS Currency,
	|	Balance.SumBalance AS AmountInCurrency,
	|	Balance.SumComplBalance AS SumCompl,
	|	Balance.SumManBalance AS SumMan,
	|	ISNULL(
	|		ARAPObjects.Contract.ContractRateOption, 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption
	|INTO TTBalancesForDay
	|FROM
	|	AccumulationRegister.LossAllowance.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners IN (&DimensionCalculation) AND Currency <> &ManagementAccountingCurrency
	|	) AS Balance
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON Balance.ARAPObject = ARAPObjects.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.AmountInCurrency AS CurrencyBalance_,
	|	0 AS SumCompl,
	|	LeftoversForDay.SumMan AS SumMan,
	|	CASE 
	|		WHEN LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseNumerator,1)
	|		ELSE ISNULL(CurrencyExchangeRate.CourseNumerator,1)
	|	END                                                                       AS CourseNumeratorLocal,
	|	CASE 
	|		WHEN LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseDenominator,1)
	|		ELSE ISNULL(CurrencyExchangeRate.CourseDenominator,1)
	|	END                                                                       AS CourseDenominatorLocal,
	|	CASE 
	|		WHEN LeftoversForDay.Currency = &ManagementAccountingCurrency
	|			AND LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseNumerator,1)
	|		ELSE ISNULL(ManSExchangeRate.CourseNumerator,1)
	|	END                                                                       AS CourseNumeratorMan,
	|	CASE 
	|		WHEN LeftoversForDay.Currency = &ManagementAccountingCurrency
	|			AND LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseDenominator,1)
	|		ELSE ISNULL(ManSExchangeRate.CourseDenominator,1)
	|	END                                                                       AS CourseDenominatorMan,
	|	LeftoversForDay.AmountType AS AmountType,
	|	LeftoversForDay.ARAPObject AS ARAPObject,
	|	LeftoversForDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	LeftoversForDay.ARAPDocument AS ARAPDocument,
	|	&BusinessOperation AS BusinessOperation,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTBalanceOfReservesWithExchangeRates
	|FROM
	|	TTBalancesForDay AS LeftoversForDay
	|		LEFT JOIN AnalyticsOfDay
	|		ON LeftoversForDay.AccountingDimensionByPartners = AnalyticsOfDay.DimensionKey
	|			AND LeftoversForDay.ARAPObject = AnalyticsOfDay.ARAPObject
	|			AND LeftoversForDay.ARAPDocument = AnalyticsOfDay.ARAPDocument
	|			AND LeftoversForDay.AmountType = AnalyticsOfDay.AmountType
	|	LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.Currency = CurrencyExchangeRate.Currency
	|	LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN ContractTTCourses AS ContractCourse
	|			ON ARAPObjects.Contract = ContractCourse.Contract
	|		ON LeftoversForDay.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	LeftoversForDay.AmountInCurrency <> 0
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND LeftoversForDay.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalanceOfReservesWithExchangeRates.Currency AS Currency,
	|	TTBalanceOfReservesWithExchangeRates.Period AS Period,
	|	TTBalanceOfReservesWithExchangeRates.CurrencyBalance_ AS CurrencyBalance_,
	|	TTBalanceOfReservesWithExchangeRates.SumCompl AS SumCompl,
	|	CAST(TTBalanceOfReservesWithExchangeRates.CurrencyBalance_ 
	|			* TTBalanceOfReservesWithExchangeRates.CourseNumeratorLocal 
	|			/ TTBalanceOfReservesWithExchangeRates.CourseDenominatorLocal 
	|			* TTBalanceOfReservesWithExchangeRates.CourseDenominatorMan 
	|			/ TTBalanceOfReservesWithExchangeRates.CourseNumeratorMan 
	|		AS NUMBER(31,2)) - TTBalanceOfReservesWithExchangeRates.SumMan AS SumMan,
	|	TTBalanceOfReservesWithExchangeRates.AmountType AS AmountType,
	|	TTBalanceOfReservesWithExchangeRates.ARAPObject AS ARAPObject,
	|	TTBalanceOfReservesWithExchangeRates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTBalanceOfReservesWithExchangeRates.ARAPDocument AS ARAPDocument,
	|	TTBalanceOfReservesWithExchangeRates.BusinessOperation AS BusinessOperation,
	|	TTBalanceOfReservesWithExchangeRates.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TueReserveBalances
	|FROM
	|	TTBalanceOfReservesWithExchangeRates
	|WHERE
	|	CAST(TTBalanceOfReservesWithExchangeRates.CurrencyBalance_ 
	|			* TTBalanceOfReservesWithExchangeRates.CourseNumeratorLocal 
	|			/ TTBalanceOfReservesWithExchangeRates.CourseDenominatorLocal 
	|			* TTBalanceOfReservesWithExchangeRates.CourseDenominatorMan 
	|			/ TTBalanceOfReservesWithExchangeRates.CourseNumeratorMan 
	|		AS NUMBER(31,2)) <> TTBalanceOfReservesWithExchangeRates.SumMan
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY),
	|	0,
	|	0,
	|	-LeftoversForDay.SumMan,
	|	LeftoversForDay.AmountType,
	|	LeftoversForDay.ARAPObject,
	|	LeftoversForDay.AccountingDimensionByPartners,
	|	LeftoversForDay.ARAPDocument,
	|	&BusinessOperation,
	|	&BusinessTransactionSetting
	|FROM
	|	TTBalancesForDay AS LeftoversForDay
	|		LEFT JOIN AnalyticsOfDay
	|		ON LeftoversForDay.AccountingDimensionByPartners = AnalyticsOfDay.DimensionKey
	|			AND LeftoversForDay.ARAPObject = AnalyticsOfDay.ARAPObject
	|			AND LeftoversForDay.ARAPDocument = AnalyticsOfDay.ARAPDocument
	|			AND LeftoversForDay.AmountType = AnalyticsOfDay.AmountType
	|WHERE
	|	LeftoversForDay.AmountInCurrency = 0
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND LeftoversForDay.SumMan <> 0
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.SumMan > 0 
	|		THEN VALUE(AccumulationRecordType.Receipt) 
	|		ELSE VALUE(AccumulationRecordType.Expense) 
	|	END AS RecordType,
	|	0 AS SumCompl,
	|	CASE WHEN Balance.SumMan < 0
	|		THEN -Balance.SumMan
	|		ELSE Balance.SumMan
	|	END AS SumMan,
	|	0 AS SumOfLocalReg,
	|	Balance.SumMan AS AmountOfManReg,
	|	Balance.AmountType AS AmountType,
	|	Balance.ARAPObject AS ARAPObject,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TableOfDebtReserves
	|FROM
	|	TueReserveBalances AS Balance
	|WHERE
	|	Balance.SumMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfDebtReserves.Currency,
	|	TableOfDebtReserves.Period AS Period,
	|	TableOfDebtReserves.RecordType AS RecordType,
	|	SUM(TableOfDebtReserves.SumCompl) AS SumCompl,
	|	SUM(TableOfDebtReserves.SumMan) AS SumMan,
	|	SUM(TableOfDebtReserves.SumOfLocalReg) AS SumOfLocalReg,
	|	SUM(TableOfDebtReserves.AmountOfManReg) AS AmountOfManReg,
	|	TableOfDebtReserves.AmountType AS AmountType,
	|	TableOfDebtReserves.ARAPObject AS ARAPObject,
	|	TableOfDebtReserves.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableOfDebtReserves.ARAPDocument AS ARAPDocument,
	|	TableOfDebtReserves.BusinessOperation AS BusinessOperation,
	|	TableOfDebtReserves.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO ExchangeRateDifferencesLossAllowance
	|FROM
	|	TableOfDebtReserves AS TableOfDebtReserves
	|
	|GROUP BY
	|	TableOfDebtReserves.Currency,
	|	TableOfDebtReserves.Period,
	|	TableOfDebtReserves.AccountingDimensionByPartners,
	|	TableOfDebtReserves.ARAPObject,
	|	TableOfDebtReserves.ARAPDocument,
	|	TableOfDebtReserves.AmountType,
	|	TableOfDebtReserves.BusinessOperation,
	|	TableOfDebtReserves.RecordType,
	|	TableOfDebtReserves.BusinessTransactionSetting
	|;
	|";
	
EndFunction
Function QueryTextExchangeRateDifferencesDiscountInterestExpense()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RevolutionsPerDay.ARAPObject AS ARAPObject,
	|	RevolutionsPerDay.ARAPDocument AS ARAPDocument,
	|	RevolutionsPerDay.Currency AS Currency
	|INTO RevolutionsPerDay
	|FROM
	|	AccumulationRegister.DiscountInterestExpense.Turnovers(
	|			&BorderStartOfPeriod,
	|			&BorderEndOfPeriod,
	|			,
	|			(Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RevolutionsPerDay
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	ARAPDocument
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	LeftoversForDay.DiscountingAmountBalance AS DiscountingAmountBalance,
	|	LeftoversForDay.DiscountingAmountComplBalance AS DiscountingAmountComplBalance,
	|	LeftoversForDay.DiscountingAmountManBalance AS DiscountingAmountManBalance,
	|	LeftoversForDay.ARAPObject AS ARAPObject,
	|	LeftoversForDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	LeftoversForDay.ARAPDocument AS ARAPDocument,
	|	ISNULL(
	|		ARAPObjects.Contract.ContractRateOption, 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption
	|
	|INTO TTBalancesForDay
	|FROM
	|	AccumulationRegister.DiscountInterestExpense.Balance(
	|		&BorderEndOfPeriod,
	|		AccountingDimensionByPartners.Organization = &Organization
	|		AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON LeftoversForDay.ARAPObject = ARAPObjects.Ref
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.DiscountingAmountBalance AS CurrencyBalance_,
	|	LeftoversForDay.DiscountingAmountComplBalance AS RemainderOfLocal,
	|	LeftoversForDay.DiscountingAmountManBalance AS BalanceMan,
	|	CASE 
	|		WHEN LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseNumerator,1)
	|		ELSE ISNULL(CurrencyExchangeRate.CourseNumerator,1)
	|	END                                                                       AS CourseNumeratorLocal,
	|	CASE 
	|		WHEN LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseDenominator,1)
	|		ELSE ISNULL(CurrencyExchangeRate.CourseDenominator,1)
	|	END                                                                       AS CourseDenominatorLocal,
	|	CASE 
	|		WHEN LeftoversForDay.Currency = &ManagementAccountingCurrency
	|			AND LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseNumerator,1)
	|		ELSE ISNULL(ManSExchangeRate.CourseNumerator,1)
	|	END                                                                       AS CourseNumeratorMan,
	|	CASE 
	|		WHEN LeftoversForDay.Currency = &ManagementAccountingCurrency
	|			AND LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseDenominator,1)
	|		ELSE ISNULL(ManSExchangeRate.CourseDenominator,1)
	|	END                                                                       AS CourseDenominatorMan,
	|	LeftoversForDay.ARAPObject AS ARAPObject,
	|	LeftoversForDay.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	LeftoversForDay.ARAPDocument AS ARAPDocument,
	|	&BusinessOperation AS BusinessOperation,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTBalancesOfDiscountAmountsWithExchangeRates
	|FROM
	|	TTBalancesForDay AS LeftoversForDay
	|	LEFT JOIN RevolutionsPerDay
	|		ON LeftoversForDay.AccountingDimensionByPartners = RevolutionsPerDay.AccountingDimensionByPartners
	|		AND LeftoversForDay.ARAPObject = RevolutionsPerDay.ARAPObject
	|		AND LeftoversForDay.ARAPDocument = RevolutionsPerDay.ARAPDocument
	|	LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.Currency = CurrencyExchangeRate.Currency
	|	LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			LEFT JOIN ContractTTCourses AS ContractCourse
	|				ON ARAPObjects.Contract = ContractCourse.Contract
	|		ON LeftoversForDay.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	LeftoversForDay.DiscountingAmountBalance <> 0
	|	AND (NOT RevolutionsPerDay.ARAPObject IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND LeftoversForDay.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalancesOfDiscountAmountsWithExchangeRates.Currency AS Currency,
	|	TTBalancesOfDiscountAmountsWithExchangeRates.Period AS Period,
	|	TTBalancesOfDiscountAmountsWithExchangeRates.CurrencyBalance_ AS CurrencyBalance_,
	|	CAST(TTBalancesOfDiscountAmountsWithExchangeRates.CurrencyBalance_ 
	|		* TTBalancesOfDiscountAmountsWithExchangeRates.CourseNumeratorLocal / TTBalancesOfDiscountAmountsWithExchangeRates.CourseDenominatorLocal AS NUMBER(31,2)) 
	|		- TTBalancesOfDiscountAmountsWithExchangeRates.RemainderOfLocal AS SumCompl,
	|	CAST(TTBalancesOfDiscountAmountsWithExchangeRates.CurrencyBalance_ 
	|		* TTBalancesOfDiscountAmountsWithExchangeRates.CourseNumeratorLocal / TTBalancesOfDiscountAmountsWithExchangeRates.CourseDenominatorLocal 
	|			* TTBalancesOfDiscountAmountsWithExchangeRates.CourseDenominatorMan / TTBalancesOfDiscountAmountsWithExchangeRates.CourseNumeratorMan AS NUMBER(31,2)) 
	|		- TTBalancesOfDiscountAmountsWithExchangeRates.BalanceMan AS SumMan,
	|	TTBalancesOfDiscountAmountsWithExchangeRates.ARAPObject AS ARAPObject,
	|	TTBalancesOfDiscountAmountsWithExchangeRates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTBalancesOfDiscountAmountsWithExchangeRates.ARAPDocument AS ARAPDocument,
	|	TTBalancesOfDiscountAmountsWithExchangeRates.BusinessOperation AS BusinessOperation,
	|	TTBalancesOfDiscountAmountsWithExchangeRates.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTBalancesOfDiscountAmounts
	|FROM
	|	TTBalancesOfDiscountAmountsWithExchangeRates AS TTBalancesOfDiscountAmountsWithExchangeRates
	|WHERE
	|	CAST(TTBalancesOfDiscountAmountsWithExchangeRates.CurrencyBalance_ 
	|		* TTBalancesOfDiscountAmountsWithExchangeRates.CourseNumeratorLocal / TTBalancesOfDiscountAmountsWithExchangeRates.CourseDenominatorLocal AS NUMBER(31,2)) <> TTBalancesOfDiscountAmountsWithExchangeRates.RemainderOfLocal
	|	OR CAST(TTBalancesOfDiscountAmountsWithExchangeRates.CurrencyBalance_ 
	|		* TTBalancesOfDiscountAmountsWithExchangeRates.CourseNumeratorLocal / TTBalancesOfDiscountAmountsWithExchangeRates.CourseDenominatorLocal 
	|			* TTBalancesOfDiscountAmountsWithExchangeRates.CourseDenominatorMan / TTBalancesOfDiscountAmountsWithExchangeRates.CourseNumeratorMan AS NUMBER(31,2)) <> TTBalancesOfDiscountAmountsWithExchangeRates.BalanceMan
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY),
	|	0,
	|	-LeftoversForDay.DiscountingAmountComplBalance,
	|	-LeftoversForDay.DiscountingAmountManBalance,
	|	LeftoversForDay.ARAPObject,
	|	LeftoversForDay.AccountingDimensionByPartners,
	|	LeftoversForDay.ARAPDocument,
	|	&BusinessOperation,
	|	&BusinessTransactionSetting
	|FROM
	|	AccumulationRegister.DiscountInterestExpense.Balance(
	|			&BorderEndOfPeriod,
	|			AccountingDimensionByPartners.Organization = &Organization
	|			AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS LeftoversForDay
	|		LEFT JOIN RevolutionsPerDay
	|		ON LeftoversForDay.AccountingDimensionByPartners = RevolutionsPerDay.AccountingDimensionByPartners
	|			AND LeftoversForDay.ARAPObject = RevolutionsPerDay.ARAPObject
	|			AND LeftoversForDay.ARAPDocument = RevolutionsPerDay.ARAPDocument
	|WHERE
	|	LeftoversForDay.DiscountingAmountBalance = 0
	|	AND (NOT RevolutionsPerDay.ARAPObject IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.DiscountingAmountComplBalance <> 0 OR LeftoversForDay.DiscountingAmountManBalance <> 0)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.SumCompl > 0 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN -Balance.SumCompl
	|		ELSE Balance.SumCompl
	|	END AS SumCompl,
	|	0 AS SumMan,
	|	Balance.SumCompl AS SumOfLocalReg,
	|	0 AS AmountOfManReg,
	|	Balance.ARAPObject AS ARAPObject,
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeRateDifferencesOnDiscountingLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeRateDifferencesOnDiscountingProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeRateDifferencesOnDiscountingLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeRateDifferencesOnDiscountingProfit)
	|	END AS BusinessTransactionSetting
	|
	|INTO DiscountTable
	|FROM
	|	TTBalancesOfDiscountAmounts AS Balance
	|WHERE
	|	Balance.SumCompl <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency,
	|	&EndOfPeriod,
	|	CASE WHEN Balance.SumMan > 0 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	0,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN -Balance.SumMan
	|		ELSE Balance.SumMan
	|	END,
	|	0,
	|	Balance.SumMan AS AmountOfManReg,
	|	Balance.ARAPObject,
	|	Balance.AccountingDimensionByPartners,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeRateDifferencesOnDiscountingLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeRateDifferencesOnDiscountingProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeRateDifferencesOnDiscountingLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeRateDifferencesOnDiscountingProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTBalancesOfDiscountAmounts AS Balance
	|WHERE
	|	Balance.SumMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscountTable.Currency,
	|	DiscountTable.Period AS Period,
	|	DiscountTable.RecordType,
	|	SUM(DiscountTable.SumCompl) AS DiscountingAmountCompl,
	|	SUM(DiscountTable.SumMan) AS DiscountingAmountMan,
	|	SUM(DiscountTable.SumOfLocalReg) AS LocalRegisterAmount,
	|	SUM(DiscountTable.AmountOfManReg) AS AmountOfRegisterMan,
	|	DiscountTable.ARAPObject,
	|	DiscountTable.AccountingDimensionByPartners,
	|	DiscountTable.ARAPDocument AS ARAPDocument,
	|	DiscountTable.BusinessOperation,
	|	DiscountTable.BusinessTransactionSetting
	|INTO ExchangeRateDifferencesDiscountInterestExpense
	|FROM
	|	DiscountTable AS DiscountTable
	|
	|GROUP BY
	|	DiscountTable.Currency,
	|	DiscountTable.Period,
	|	DiscountTable.AccountingDimensionByPartners,
	|	DiscountTable.ARAPObject,
	|	DiscountTable.ARAPDocument,
	|	DiscountTable.BusinessOperation,
	|	DiscountTable.RecordType,
	|	DiscountTable.BusinessTransactionSetting
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesGoodsToBeRegisteredInReportsToConsignor()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	Calculations.ItemsLocationAttributes AS DimensionKey,
	|	Calculations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Calculations.CCDNumber AS CCDNumber,
	|	Calculations.DocumentSales AS DocumentSales
	|INTO DailyAnalyticsTTForGoodsToBeProcessed
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS Calculations
	|WHERE
	|	Calculations.Organization = &Organization
	|	AND Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
	|	AND Calculations.RevenueAmount <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemnantsOfDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	RemnantsOfDay.Organization AS Organization,
	|	RemnantsOfDay.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	RemnantsOfDay.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	RemnantsOfDay.CCDNumber AS CCDNumber,
	|	RemnantsOfDay.DocumentSales AS DocumentSales,
	|	InventoryKinds.Contract AS Contract,
	|	ISNULL(Contracts.ContractRateOption, UNDEFINED) AS ContractRateOption,
	|	RemnantsOfDay.RevenueAmountBalance AS RevenueAmount,
	|	RemnantsOfDay.RevenueAmountExclVATLocalBalance AS RevenueAmountExclVATLocal,
	|	RemnantsOfDay.RevenueAmountManBalance AS RevenueAmountMan
	|INTO TTBalanceAtEndOfDayGoodsToBeProcessed
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(
	|			&BorderEndOfPeriod,
	|			Organization IN (&Organization)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON RemnantsOfDay.InventoryOwnerAttribute = InventoryKinds.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON InventoryKinds.Contract = Contracts.Ref
	|	LEFT JOIN DailyAnalyticsTTForGoodsToBeProcessed AS AnalyticsOfDay
	|		ON RemnantsOfDay.ItemsLocationAttributes = AnalyticsOfDay.DimensionKey
	|		AND RemnantsOfDay.InventoryOwnerAttribute = AnalyticsOfDay.InventoryOwnerAttribute
	|		AND RemnantsOfDay.CCDNumber = AnalyticsOfDay.CCDNumber
	|		AND RemnantsOfDay.DocumentSales = AnalyticsOfDay.DocumentSales
	|WHERE
	|	RemnantsOfDay.RevenueAmountBalance <> 0
	|	AND ISNULL(Contracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	
	|UNION ALL
	|
	|SELECT
	|	RemnantsOfDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	RemnantsOfDay.Organization AS Organization,
	|	RemnantsOfDay.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	RemnantsOfDay.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	RemnantsOfDay.CCDNumber AS CCDNumber,
	|	RemnantsOfDay.DocumentSales AS DocumentSales,
	|	InventoryKinds.Contract AS Contract,
	|	ISNULL(Contracts.ContractRateOption, UNDEFINED) AS ContractRateOption,
	|	RemnantsOfDay.RevenueAmountBalance AS RevenueAmount,
	|	RemnantsOfDay.RevenueAmountExclVATLocalBalance AS RevenueAmountExclVATLocal,
	|	RemnantsOfDay.RevenueAmountManBalance AS RevenueAmountMan
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(
	|			&BorderEndOfPeriod,
	|			Organization IN (&Organization)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON RemnantsOfDay.InventoryOwnerAttribute = InventoryKinds.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON InventoryKinds.Contract = Contracts.Ref
	|	LEFT JOIN DailyAnalyticsTTForGoodsToBeProcessed AS AnalyticsOfDay
	|		ON RemnantsOfDay.ItemsLocationAttributes = AnalyticsOfDay.DimensionKey
	|		AND RemnantsOfDay.InventoryOwnerAttribute = AnalyticsOfDay.InventoryOwnerAttribute
	|		AND RemnantsOfDay.CCDNumber = AnalyticsOfDay.CCDNumber
	|		AND RemnantsOfDay.DocumentSales = AnalyticsOfDay.DocumentSales
	|WHERE
	|	RemnantsOfDay.RevenueAmountBalance = 0
	|	AND ISNULL(Contracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|	AND (RemnantsOfDay.RevenueAmountExclVATLocalBalance <> 0 OR RemnantsOfDay.RevenueAmountManBalance <> 0)
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.DocumentSales AS DocumentSales,
	|	Balance.Contract AS Contract,
	|	Balance.ContractRateOption AS ContractRateOption,
	|	CASE WHEN Balance.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|			THEN CAST(Balance.RevenueAmount * ExchangeRatesUnderContracts.CourseNumerator / ExchangeRatesUnderContracts.CourseDenominator AS NUMBER(31,2)) - Balance.RevenueAmountExclVATLocal
	|		ELSE 
	|			CAST(Balance.RevenueAmount * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2)) - Balance.RevenueAmountExclVATLocal
	|	END AS RevenueAmountExclVATLocal,
	|	CASE WHEN Balance.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|					AND Balance.Currency = &ManagementAccountingCurrency
	|			THEN (CAST(Balance.RevenueAmount * ExchangeRatesUnderContracts.CourseNumerator / ExchangeRatesUnderContracts.CourseDenominator AS NUMBER(31,2))) - Balance.RevenueAmountMan
	|		ELSE
	|			CAST(Balance.RevenueAmount * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2)) - Balance.RevenueAmountMan
	|	END AS RevenueAmountMan
	|INTO GoodsNotSoldInKyrgyzRepublicAreTTForRegistration
	|FROM
	|	TTBalanceAtEndOfDayGoodsToBeProcessed AS Balance
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|			ON Balance.Currency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|			ON (TRUE)
	|		LEFT JOIN ContractTTCourses AS ExchangeRatesUnderContracts
	|			ON Balance.Contract = ExchangeRatesUnderContracts.Contract
	|WHERE
	|	Balance.RevenueAmount <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.DocumentSales AS DocumentSales,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal < 0
	|		THEN -Balance.RevenueAmountExclVATLocal
	|		ELSE Balance.RevenueAmountExclVATLocal
	|	END AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountMan,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|INTO CalculationTableForGoodsToBeProcessed
	|FROM
	|	TTBalanceAtEndOfDayGoodsToBeProcessed AS Balance
	|WHERE
	|	Balance.RevenueAmount = 0 AND Balance.RevenueAmountExclVATLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.RevenueAmountMan > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.DocumentSales AS DocumentSales,
	|	0 AS RevenueAmountExclVATLocal,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN -Balance.RevenueAmountMan
	|		ELSE Balance.RevenueAmountMan
	|	END AS RevenueAmountMan,
	|	CASE WHEN Balance.RevenueAmountMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.RevenueAmountMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTBalanceAtEndOfDayGoodsToBeProcessed AS Balance
	|WHERE
	|	Balance.RevenueAmount = 0 AND Balance.RevenueAmountMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE
	|		WHEN Balance.RevenueAmountExclVATLocal < 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.DocumentSales AS DocumentSales,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal < 0
	|		THEN -Balance.RevenueAmountExclVATLocal
	|		ELSE Balance.RevenueAmountExclVATLocal
	|	END AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountMan,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal < 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	GoodsNotSoldInKyrgyzRepublicAreTTForRegistration AS Balance
	|WHERE
	|	Balance.RevenueAmountExclVATLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.DocumentSales AS DocumentSales,
	|	0 AS RevenueAmountExclVATLocal,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN -Balance.RevenueAmountMan
	|		ELSE Balance.RevenueAmountMan
	|	END AS RevenueAmountMan,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	GoodsNotSoldInKyrgyzRepublicAreTTForRegistration AS Balance
	|WHERE
	|	Balance.RevenueAmountMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationTable.Currency,
	|	CalculationTable.RecordType,
	|	CalculationTable.Period AS Period,
	|	CalculationTable.Organization AS Organization,
	|	CalculationTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CalculationTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CalculationTable.CCDNumber AS CCDNumber,
	|	CalculationTable.DocumentSales AS DocumentSales,
	|	SUM(CalculationTable.RevenueAmountExclVATLocal) AS RevenueAmountExclVATLocal,
	|	SUM(CalculationTable.RevenueAmountMan) AS RevenueAmountMan,
	|	CalculationTable.BusinessOperation AS BusinessOperation,
	| 	CalculationTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO ExchangeRateDifferencesGoodsToBeRegisteredInReportsToConsignor
	|FROM
	|	CalculationTableForGoodsToBeProcessed AS CalculationTable
	|
	|GROUP BY
	|	CalculationTable.Currency,
	|	CalculationTable.RecordType,
	|	CalculationTable.Period,
	|	CalculationTable.Organization,
	|	CalculationTable.ItemsLocationAttributes,
	|	CalculationTable.InventoryOwnerAttribute,
	|	CalculationTable.CCDNumber,
	|	CalculationTable.DocumentSales,
	|	CalculationTable.BusinessOperation,
	| 	CalculationTable.BusinessTransactionSetting"
	+"
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesGoodsAndServicesToRegisterPurchasingReportsToConsignor()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	Calculations.Products AS Products,
	|	Calculations.Characteristic AS Characteristic,
	|	Calculations.DocumentAcquisitions AS DocumentAcquisitions,
	|	Calculations.Purpose AS Purpose,
	|	Calculations.CCDNumber AS CCDNumber
	|INTO AnalyticsTTPerDayGoodsToBeProcessedForPurchase
	|FROM
	|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor AS Calculations
	|WHERE
	|	Calculations.Organization = &Organization
	|	AND Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
	|	AND Calculations.AmountIncludingVAT <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemnantsOfDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	RemnantsOfDay.Organization AS Organization,
	|	RemnantsOfDay.Products AS Products,
	|	RemnantsOfDay.Characteristic AS Characteristic,
	|	RemnantsOfDay.DocumentAcquisitions AS DocumentAcquisitions,
	|	RemnantsOfDay.Purpose AS Purpose,
	|	RemnantsOfDay.CCDNumber AS CCDNumber,
	|	Assignments.Contract AS Contract,
	|	ISNULL(Contracts.ContractRateOption, UNDEFINED) AS ContractRateOption,
	|	RemnantsOfDay.AmountIncludingVATBalance AS AmountIncludingVAT,
	|	RemnantsOfDay.SumComplBalance AS SumCompl,
	|	RemnantsOfDay.SumManBalance AS SumMan
	|INTO TTBalanceAtEndOfDayGoodsForPurchasing
	|FROM
	|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Balance(
	|			&BorderEndOfPeriod,
	|			Organization IN (&Organization)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	INNER JOIN Catalog.Assignments AS Assignments
	|		ON RemnantsOfDay.Purpose = Assignments.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON Assignments.Contract = Contracts.Ref
	|	LEFT JOIN AnalyticsTTPerDayGoodsToBeProcessedForPurchase AS AnalyticsOfDay
	|		ON RemnantsOfDay.Products = AnalyticsOfDay.Products
	|		AND RemnantsOfDay.Characteristic = AnalyticsOfDay.Characteristic
	|		AND RemnantsOfDay.DocumentAcquisitions = AnalyticsOfDay.DocumentAcquisitions
	|		AND RemnantsOfDay.CCDNumber = AnalyticsOfDay.CCDNumber
	|		AND RemnantsOfDay.Purpose = AnalyticsOfDay.Purpose
	|WHERE
	|	RemnantsOfDay.AmountIncludingVATBalance <> 0
	|	AND ISNULL(Contracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|	AND (NOT AnalyticsOfDay.Products IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	
	|UNION ALL
	|
	|SELECT
	|	RemnantsOfDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	RemnantsOfDay.Organization AS Organization,
	|	RemnantsOfDay.Products AS Products,
	|	RemnantsOfDay.Characteristic AS Characteristic,
	|	RemnantsOfDay.DocumentAcquisitions AS DocumentAcquisitions,
	|	RemnantsOfDay.Purpose AS Purpose,
	|	RemnantsOfDay.CCDNumber AS CCDNumber,
	|	Assignments.Contract AS Contract,
	|	ISNULL(Contracts.ContractRateOption, UNDEFINED) AS ContractRateOption,
	|	RemnantsOfDay.AmountIncludingVATBalance AS AmountIncludingVAT,
	|	RemnantsOfDay.SumComplBalance AS SumCompl,
	|	RemnantsOfDay.SumManBalance AS SumMan
	|FROM
	|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Balance(
	|			&BorderEndOfPeriod,
	|			Organization IN (&Organization)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	INNER JOIN Catalog.Assignments AS Assignments
	|		ON RemnantsOfDay.Purpose = Assignments.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON Assignments.Contract = Contracts.Ref
	|	LEFT JOIN AnalyticsTTPerDayGoodsToBeProcessedForPurchase AS AnalyticsOfDay
	|		ON RemnantsOfDay.Products = AnalyticsOfDay.Products
	|		AND RemnantsOfDay.Characteristic = AnalyticsOfDay.Characteristic
	|		AND RemnantsOfDay.DocumentAcquisitions = AnalyticsOfDay.DocumentAcquisitions
	|		AND RemnantsOfDay.CCDNumber = AnalyticsOfDay.CCDNumber
	|		AND RemnantsOfDay.Purpose = AnalyticsOfDay.Purpose
	|WHERE
	|	RemnantsOfDay.AmountIncludingVATBalance = 0
	|	AND ISNULL(Contracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|	AND (RemnantsOfDay.SumComplBalance <> 0 OR RemnantsOfDay.SumManBalance <> 0)
	|	AND (NOT AnalyticsOfDay.Products IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.DocumentAcquisitions AS DocumentAcquisitions,
	|	Balance.Purpose AS Purpose,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.Contract AS Contract,
	|	Balance.ContractRateOption AS ContractRateOption,
	|	CASE WHEN Balance.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|			THEN CAST(Balance.AmountIncludingVAT * ExchangeRatesUnderContracts.CourseNumerator / ExchangeRatesUnderContracts.CourseDenominator AS NUMBER(31,2)) - Balance.SumCompl
	|		ELSE 
	|			CAST(Balance.AmountIncludingVAT * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2)) - Balance.SumCompl
	|	END AS SumCompl,
	|	CASE WHEN Balance.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|					AND Balance.Currency = &ManagementAccountingCurrency
	|			THEN (CAST(Balance.AmountIncludingVAT * ExchangeRatesUnderContracts.CourseNumerator / ExchangeRatesUnderContracts.CourseDenominator AS NUMBER(31,2))) - Balance.SumMan
	|		ELSE
	|			CAST(Balance.AmountIncludingVAT * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2)) - Balance.SumMan
	|	END AS SumMan
	|INTO GoodsNotSoldInKyrgyzRepublicForPurchasingTTAreToBeProcessed
	|FROM
	|	TTBalanceAtEndOfDayGoodsForPurchasing AS Balance
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|			ON Balance.Currency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|			ON (TRUE)
	|		LEFT JOIN ContractTTCourses AS ExchangeRatesUnderContracts
	|			ON Balance.Contract = ExchangeRatesUnderContracts.Contract
	|WHERE
	|	Balance.AmountIncludingVAT <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.DocumentAcquisitions AS DocumentAcquisitions,
	|	Balance.Purpose AS Purpose,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.Contract AS Contract,
	|	Balance.ContractRateOption AS ContractRateOption,
	|	CASE WHEN Balance.SumCompl < 0
	|		THEN -Balance.SumCompl
	|		ELSE Balance.SumCompl
	|	END AS SumCompl,
	|	0 AS SumMan,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.SumCompl > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|INTO TableOfCalculationsOfGoodsForPurchasing
	|FROM
	|	TTBalanceAtEndOfDayGoodsForPurchasing AS Balance
	|WHERE
	|	Balance.AmountIncludingVAT = 0 AND Balance.SumCompl <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.DocumentAcquisitions AS DocumentAcquisitions,
	|	Balance.Purpose AS Purpose,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.Contract AS Contract,
	|	Balance.ContractRateOption AS ContractRateOption,
	|	0 AS RevenueAmountExclVATLocal,
	|	CASE WHEN Balance.SumMan < 0
	|		THEN -Balance.SumMan
	|		ELSE Balance.SumMan
	|	END AS SumMan,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.SumMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTBalanceAtEndOfDayGoodsForPurchasing AS Balance
	|WHERE
	|	Balance.AmountIncludingVAT = 0 AND Balance.SumMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE
	|		WHEN Balance.SumCompl < 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.DocumentAcquisitions AS DocumentAcquisitions,
	|	Balance.Purpose AS Purpose,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.Contract AS Contract,
	|	Balance.ContractRateOption AS ContractRateOption,
	|	CASE WHEN Balance.SumCompl < 0
	|		THEN -Balance.SumCompl
	|		ELSE Balance.SumCompl
	|	END AS SumCompl,
	|	0 AS SumMan,
	|	CASE WHEN Balance.SumCompl < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.SumCompl < 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	GoodsNotSoldInKyrgyzRepublicForPurchasingTTAreToBeProcessed AS Balance
	|WHERE
	|	Balance.SumCompl <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.SumMan < 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.DocumentAcquisitions AS DocumentAcquisitions,
	|	Balance.Purpose AS Purpose,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.Contract AS Contract,
	|	Balance.ContractRateOption AS ContractRateOption,
	|	0 AS SumCompl,
	|	CASE WHEN Balance.SumMan < 0
	|		THEN -Balance.SumMan
	|		ELSE Balance.SumMan
	|	END AS SumMan,
	|	CASE WHEN Balance.SumMan < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.SumMan < 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	GoodsNotSoldInKyrgyzRepublicForPurchasingTTAreToBeProcessed AS Balance
	|WHERE
	|	Balance.SumMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationTable.Currency AS Currency,
	|	CalculationTable.RecordType AS RecordType,
	|	CalculationTable.Period AS Period,
	|	CalculationTable.Organization AS Organization,
	|	CalculationTable.Products AS Products,
	|	CalculationTable.Characteristic AS Characteristic,
	|	CalculationTable.DocumentAcquisitions AS DocumentAcquisitions,
	|	CalculationTable.Purpose AS Purpose,
	|	CalculationTable.CCDNumber AS CCDNumber,
	|	CalculationTable.Contract AS Contract,
	|	CalculationTable.ContractRateOption AS ContractRateOption,
	|	SUM(CalculationTable.SumCompl) AS SumCompl,
	|	SUM(CalculationTable.SumMan) AS SumMan,
	|	CalculationTable.BusinessOperation AS BusinessOperation,
	| 	CalculationTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO ExchangeRateDifferencesGoodsAndServicesToRegisterPurchasingReportsToConsignor
	|FROM
	|	TableOfCalculationsOfGoodsForPurchasing AS CalculationTable
	|
	|GROUP BY
	|	
	|	CalculationTable.Currency,
	|	CalculationTable.RecordType,
	|	CalculationTable.Period,
	|	CalculationTable.Organization,
	|	CalculationTable.Products,
	|	CalculationTable.Characteristic,
	|	CalculationTable.DocumentAcquisitions,
	|	CalculationTable.Purpose,
	|	CalculationTable.CCDNumber,
	|	CalculationTable.Contract,
	|	CalculationTable.ContractRateOption,
	|	CalculationTable.BusinessOperation,
	| 	CalculationTable.BusinessTransactionSetting"
	+"
	|;
	|";
	
EndFunction

Function QueryTextExchangeRateDifferencesServicesForRegistrationOfReportsToPrincipal()
	
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	Calculations.ItemsLocationAttributes AS DimensionKey,
	|	Calculations.Terms AS Terms,
	|	Calculations.DocumentSales AS DocumentSales
	|INTO AnalyticsTTPerDayServicesForRegistration
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS Calculations
	|WHERE
	|	Calculations.Organization = &Organization
	|	AND Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> &LocalAccountingCurrency)
	|	AND Calculations.RevenueAmount <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemnantsOfDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	RemnantsOfDay.Organization AS Organization,
	|	RemnantsOfDay.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	RemnantsOfDay.Terms AS Terms,
	|	RemnantsOfDay.DocumentSales AS DocumentSales,
	|	VALUE(Enum.ContractRateOptions.Mutable) AS ContractRateOption,
	|	RemnantsOfDay.RevenueAmountBalance AS RevenueAmount,
	|	RemnantsOfDay.RevenueAmountExclVATLocalBalance AS RevenueAmountExclVATLocal,
	|	RemnantsOfDay.RevenueAmountManBalance AS RevenueAmountMan
	|INTO TTBalanceAtEndOfDayServicesForRegistration
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Balance(
	|			&BorderEndOfPeriod,
	|			Organization IN (&Organization)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON RemnantsOfDay.Terms = Terms1.Ref
	|	LEFT JOIN AnalyticsTTPerDayServicesForRegistration AS AnalyticsOfDay
	|		ON RemnantsOfDay.ItemsLocationAttributes = AnalyticsOfDay.DimensionKey
	|		AND RemnantsOfDay.Terms = AnalyticsOfDay.Terms
	|		AND RemnantsOfDay.DocumentSales = AnalyticsOfDay.DocumentSales
	|WHERE
	|	RemnantsOfDay.RevenueAmountBalance <> 0
	|	AND ISNULL(Terms1.RevalueServicesForConsignmentNotification, FALSE)
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	
	|UNION ALL
	|
	|SELECT
	|	RemnantsOfDay.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	RemnantsOfDay.Organization AS Organization,
	|	RemnantsOfDay.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	RemnantsOfDay.Terms AS Terms,
	|	RemnantsOfDay.DocumentSales AS DocumentSales,
	|	VALUE(Enum.ContractRateOptions.Mutable) AS ContractRateOption,
	|	RemnantsOfDay.RevenueAmountBalance AS RevenueAmount,
	|	RemnantsOfDay.RevenueAmountExclVATLocalBalance AS RevenueAmountExclVATLocal,
	|	RemnantsOfDay.RevenueAmountManBalance AS RevenueAmountMan
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Balance(
	|			&BorderEndOfPeriod,
	|			Organization IN (&Organization)
	|				AND (Currency <> &ManagementAccountingCurrency OR Currency <> &LocalAccountingCurrency)
	|	) AS RemnantsOfDay
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON RemnantsOfDay.Terms = Terms1.Ref
	|	LEFT JOIN AnalyticsTTPerDayServicesForRegistration AS AnalyticsOfDay
	|		ON RemnantsOfDay.ItemsLocationAttributes = AnalyticsOfDay.DimensionKey
	|		AND RemnantsOfDay.Terms = AnalyticsOfDay.Terms
	|		AND RemnantsOfDay.DocumentSales = AnalyticsOfDay.DocumentSales
	|WHERE
	|	RemnantsOfDay.RevenueAmountBalance = 0
	|	AND ISNULL(Terms1.RevalueServicesForConsignmentNotification, FALSE)
	|	AND (RemnantsOfDay.RevenueAmountExclVATLocalBalance <> 0 OR RemnantsOfDay.RevenueAmountManBalance <> 0)
	|	AND (NOT AnalyticsOfDay.DimensionKey IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.Terms AS Terms,
	|	Balance.DocumentSales AS DocumentSales,
	|	Balance.ContractRateOption AS ContractRateOption,
	|	CAST(Balance.RevenueAmount * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS NUMBER(31,2)) - Balance.RevenueAmountExclVATLocal AS RevenueAmountExclVATLocal,
	|	CAST(Balance.RevenueAmount * CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseDenominator / ManSExchangeRate.CourseNumerator AS NUMBER(31,2)) - Balance.RevenueAmountMan AS RevenueAmountMan
	|INTO TTUnrealizedCDServicesForRegistration
	|FROM
	|	TTBalanceAtEndOfDayServicesForRegistration AS Balance
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|			ON Balance.Currency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|			ON (TRUE)
	|WHERE
	|	Balance.RevenueAmount <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.Terms AS Terms,
	|	Balance.DocumentSales AS DocumentSales,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal < 0
	|		THEN -Balance.RevenueAmountExclVATLocal
	|		ELSE Balance.RevenueAmountExclVATLocal
	|	END AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountMan,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|INTO TableOfCalculationsOfServicesForRegistration
	|FROM
	|	TTBalanceAtEndOfDayServicesForRegistration AS Balance
	|WHERE
	|	Balance.RevenueAmount = 0 AND Balance.RevenueAmountExclVATLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.RevenueAmountMan > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.Terms AS Terms,
	|	Balance.DocumentSales AS DocumentSales,
	|	0 AS RevenueAmountExclVATLocal,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN -Balance.RevenueAmountMan
	|		ELSE Balance.RevenueAmountMan
	|	END AS RevenueAmountMan,
	|	CASE WHEN Balance.RevenueAmountMan > 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.RevenueAmountMan > 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTBalanceAtEndOfDayServicesForRegistration AS Balance
	|WHERE
	|	Balance.RevenueAmount = 0 AND Balance.RevenueAmountMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE
	|		WHEN Balance.RevenueAmountExclVATLocal < 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.Terms AS Terms,
	|	Balance.DocumentSales AS DocumentSales,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal < 0
	|		THEN -Balance.RevenueAmountExclVATLocal
	|		ELSE Balance.RevenueAmountExclVATLocal
	|	END AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountMan,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.RevenueAmountExclVATLocal < 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTUnrealizedCDServicesForRegistration AS Balance
	|WHERE
	|	Balance.RevenueAmountExclVATLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&EndOfPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.Terms AS Terms,
	|	Balance.DocumentSales AS DocumentSales,
	|	0 AS RevenueAmountExclVATLocal,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN -Balance.RevenueAmountMan
	|		ELSE Balance.RevenueAmountMan
	|	END AS RevenueAmountMan,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Enum.BusinessTransactions.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessOperation,
	|	CASE WHEN Balance.RevenueAmountMan < 0
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPLoss)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForConsignorARAPProfit)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTUnrealizedCDServicesForRegistration AS Balance
	|WHERE
	|	Balance.RevenueAmountMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationTable.Currency AS Currency,
	|	CalculationTable.RecordType AS RecordType,
	|	CalculationTable.Period AS Period,
	|	CalculationTable.Organization AS Organization,
	|	CalculationTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CalculationTable.Terms AS Terms,
	|	CalculationTable.DocumentSales AS DocumentSales,
	|	SUM(CalculationTable.RevenueAmountExclVATLocal) AS RevenueAmountExclVATLocal,
	|	SUM(CalculationTable.RevenueAmountMan) AS RevenueAmountMan,
	|	CalculationTable.BusinessOperation AS BusinessOperation,
	| 	CalculationTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO ExchangeRateDifferencesServicesForRegistrationOfReportsToPrincipal
	|FROM
	|	TableOfCalculationsOfServicesForRegistration AS CalculationTable
	|
	|GROUP BY
	|	CalculationTable.Currency,
	|	CalculationTable.RecordType,
	|	CalculationTable.Period,
	|	CalculationTable.Organization,
	|	CalculationTable.ItemsLocationAttributes,
	|	CalculationTable.Terms,
	|	CalculationTable.DocumentSales,
	|	CalculationTable.BusinessOperation,
	| 	CalculationTable.BusinessTransactionSetting"
	+"
	|;
	|";
	
EndFunction
Function QueryTextExchangeRateDifferencesInvestmentInRent()
	
	// we overestimate only the currency of the upr.
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.Organization AS Organization,
	|	RevolutionsPerDay.Contract AS Contract,
	|	RevolutionsPerDay.Currency AS Currency,
	|	RevolutionsPerDay.FixedAsset AS FixedAsset,
	|	RevolutionsPerDay.FinancialAccountingGroup AS FinancialAccountingGroup
	|INTO AnalyticsOfDay
	|FROM
	|	AccumulationRegister.InvestmentInRent.Turnovers(
	|			&BorderStartOfPeriod,
	|			&BorderEndOfPeriod,
	|			,
	|			Organization = &Organization
	|			AND (Currency <> &ManagementAccountingCurrency
	|				OR Currency <> &LocalAccountingCurrency)
	|	) AS RevolutionsPerDay
	|
	|INDEX BY
	|	Organization,
	|	Contract,
	|	Currency,
	|	FixedAsset,
	|	FinancialAccountingGroup
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Organization AS Organization,
	|	Balance.Contract AS Contract,
	|	Balance.Currency AS Currency,
	|	Balance.FixedAsset AS FixedAsset,
	|	Balance.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	Balance.RentalPaymentsBalance AS RentalPaymentsInForeignCurrency,
	|	Balance.RentalPaymentsLocalBalance AS RentalPaymentsLocal,
	|	Balance.RentalPaymentsManagBalance AS RentalPaymentsManag,
	|
	|	Balance.InterestDiscountBalance AS InterestDiscountInForeignCurrency,
	|	Balance.InterestDiscountLocalBalance AS InterestDiscountLocal,
	|	Balance.InterestDiscountManBalance AS InterestDiscountMan,
	|
	|	ISNULL(Contracts.ContractRateOption, 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption
	|INTO TTBalancesForDay
	|FROM
	|	AccumulationRegister.InvestmentInRent.Balance(
	|			&BorderEndOfPeriod,
	|			Organization = &Organization
	|			AND (Currency <> &ManagementAccountingCurrency
	|				OR Currency <> &LocalAccountingCurrency)
	|	) AS Balance
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON Balance.Contract = Contracts.Ref
	|
	|INDEX BY
	|	Organization,
	|	Contract,
	|	Currency,
	|	FixedAsset,
	|	FinancialAccountingGroup
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.RentalPaymentsInForeignCurrency AS RentalPaymentsInForeignCurrency,
	|	LeftoversForDay.RentalPaymentsLocal AS RentalPaymentsLocal,
	|	LeftoversForDay.RentalPaymentsManag AS RentalPaymentsManag,
	|	LeftoversForDay.InterestDiscountInForeignCurrency AS InterestDiscountInForeignCurrency,
	|	LeftoversForDay.InterestDiscountLocal AS InterestDiscountLocal,
	|	LeftoversForDay.InterestDiscountMan AS InterestDiscountMan,
	|	CASE 
	|		WHEN LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseNumerator,1)
	|		ELSE ISNULL(CurrencyExchangeRate.CourseNumerator,1)
	|	END                                                    AS CourseNumeratorLocal,
	|	CASE 
	|		WHEN LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseDenominator,1)
	|		ELSE ISNULL(CurrencyExchangeRate.CourseDenominator,1)
	|	END                                                    AS CourseDenominatorLocal,
	|	CASE 
	|		WHEN LeftoversForDay.Currency = &ManagementAccountingCurrency
	|			AND LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseNumerator,1)
	|		ELSE ISNULL(ManSExchangeRate.CourseNumerator,1)
	|	END                                                    AS CourseNumeratorMan,
	|	CASE 
	|		WHEN LeftoversForDay.Currency = &ManagementAccountingCurrency
	|			AND LeftoversForDay.ContractRateOption 
	|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|		THEN ISNULL(ContractCourse.CourseDenominator,1)
	|		ELSE ISNULL(ManSExchangeRate.CourseDenominator,1)
	|	END                                                    AS CourseDenominatorMan,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.Contract AS Contract,
	|	LeftoversForDay.FixedAsset AS FixedAsset,
	|	LeftoversForDay.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	&BusinessOperation AS BusinessOperation,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTBalanceOfInvestmentsWithExchangeRates
	|FROM
	|	TTBalancesForDay AS LeftoversForDay
	|		LEFT JOIN AnalyticsOfDay
	|		ON LeftoversForDay.Organization = AnalyticsOfDay.Organization
	|			AND LeftoversForDay.Contract = AnalyticsOfDay.Contract
	|			AND LeftoversForDay.Currency= AnalyticsOfDay.Currency
	|			AND LeftoversForDay.FixedAsset = AnalyticsOfDay.FixedAsset
	|			AND LeftoversForDay.FinancialAccountingGroup = AnalyticsOfDay.FinancialAccountingGroup
	|	LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.Currency = CurrencyExchangeRate.Currency
	|	LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|	LEFT JOIN ContractTTCourses AS ContractCourse
	|		ON LeftoversForDay.Contract = ContractCourse.Contract
	|WHERE
	|	(LeftoversForDay.RentalPaymentsInForeignCurrency <> 0
	|		OR LeftoversForDay.InterestDiscountInForeignCurrency <> 0)
	|	AND (NOT AnalyticsOfDay.Organization IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND LeftoversForDay.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesOfInvestmentsWithExchangeRates.Currency AS Currency,
	|	BalancesOfInvestmentsWithExchangeRates.Period AS Period,
	|
	|	BalancesOfInvestmentsWithExchangeRates.RentalPaymentsInForeignCurrency AS RentalPaymentsInForeignCurrency,
	|	CAST(BalancesOfInvestmentsWithExchangeRates.RentalPaymentsInForeignCurrency 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseNumeratorLocal 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseDenominatorLocal 
	|		AS NUMBER(31,2)) - BalancesOfInvestmentsWithExchangeRates.RentalPaymentsLocal AS RentalPaymentsLocal,
	|	CAST(BalancesOfInvestmentsWithExchangeRates.RentalPaymentsInForeignCurrency 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseNumeratorLocal 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseDenominatorLocal 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseDenominatorMan 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseNumeratorMan 
	|		AS NUMBER(31,2)) - BalancesOfInvestmentsWithExchangeRates.RentalPaymentsManag AS RentalPaymentsManag,
	|
	|	BalancesOfInvestmentsWithExchangeRates.InterestDiscountInForeignCurrency AS InterestDiscountInForeignCurrency,
	|	CAST(BalancesOfInvestmentsWithExchangeRates.InterestDiscountInForeignCurrency 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseNumeratorLocal 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseDenominatorLocal 
	|		AS NUMBER(31,2)) - BalancesOfInvestmentsWithExchangeRates.InterestDiscountLocal AS InterestDiscountLocal,
	|	CAST(BalancesOfInvestmentsWithExchangeRates.InterestDiscountInForeignCurrency 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseNumeratorLocal 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseDenominatorLocal 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseDenominatorMan 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseNumeratorMan 
	|		AS NUMBER(31,2)) - BalancesOfInvestmentsWithExchangeRates.InterestDiscountMan AS InterestDiscountMan,
	|
	|	BalancesOfInvestmentsWithExchangeRates.Organization AS Organization,
	|	BalancesOfInvestmentsWithExchangeRates.Contract AS Contract,
	|	BalancesOfInvestmentsWithExchangeRates.FixedAsset AS FixedAsset,
	|	BalancesOfInvestmentsWithExchangeRates.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	BalancesOfInvestmentsWithExchangeRates.BusinessOperation AS BusinessOperation,
	|	BalancesOfInvestmentsWithExchangeRates.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTExchangeRateDifferencesOfInvestments
	|FROM
	|	TTBalanceOfInvestmentsWithExchangeRates AS BalancesOfInvestmentsWithExchangeRates
	|WHERE
	|	CAST(BalancesOfInvestmentsWithExchangeRates.RentalPaymentsInForeignCurrency 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseNumeratorLocal 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseDenominatorLocal 
	|		AS NUMBER(31,2)) <> BalancesOfInvestmentsWithExchangeRates.RentalPaymentsLocal
	|	OR CAST(BalancesOfInvestmentsWithExchangeRates.RentalPaymentsInForeignCurrency 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseNumeratorLocal 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseDenominatorLocal 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseDenominatorMan 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseNumeratorMan 
	|		AS NUMBER(31,2)) <> BalancesOfInvestmentsWithExchangeRates.RentalPaymentsManag
	|
	|	OR CAST(BalancesOfInvestmentsWithExchangeRates.InterestDiscountInForeignCurrency 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseNumeratorLocal 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseDenominatorLocal 
	|		AS NUMBER(31,2)) <> BalancesOfInvestmentsWithExchangeRates.InterestDiscountLocal
	|	OR CAST(BalancesOfInvestmentsWithExchangeRates.InterestDiscountInForeignCurrency 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseNumeratorLocal 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseDenominatorLocal 
	|			* BalancesOfInvestmentsWithExchangeRates.CourseDenominatorMan 
	|			/ BalancesOfInvestmentsWithExchangeRates.CourseNumeratorMan 
	|		AS NUMBER(31,2)) <> BalancesOfInvestmentsWithExchangeRates.InterestDiscountMan
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|
	|	0 AS RentalPaymentsInForeignCurrency,
	|	-LeftoversForDay.RentalPaymentsLocal AS RentalPaymentsLocal,
	|	-LeftoversForDay.RentalPaymentsManag AS RentalPaymentsManag,
	|
	|	0 AS InterestDiscountInForeignCurrency,
	|	0 AS InterestDiscountLocal,
	|	0 AS InterestDiscountMan,
	|
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.Contract AS Contract,
	|	LeftoversForDay.FixedAsset AS FixedAsset,
	|	LeftoversForDay.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	&BusinessOperation,
	|	&BusinessTransactionSetting
	|FROM
	|	TTBalancesForDay AS LeftoversForDay
	|		LEFT JOIN AnalyticsOfDay
	|		ON LeftoversForDay.Organization = AnalyticsOfDay.Organization
	|			AND LeftoversForDay.Contract = AnalyticsOfDay.Contract
	|			AND LeftoversForDay.Currency= AnalyticsOfDay.Currency
	|			AND LeftoversForDay.FixedAsset = AnalyticsOfDay.FixedAsset
	|			AND LeftoversForDay.FinancialAccountingGroup = AnalyticsOfDay.FinancialAccountingGroup
	|WHERE
	|	LeftoversForDay.RentalPaymentsInForeignCurrency = 0
	|	AND (NOT AnalyticsOfDay.Organization IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.RentalPaymentsLocal <> 0 OR LeftoversForDay.RentalPaymentsManag <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|
	|	0 AS RentalPaymentsInForeignCurrency,
	|	0 AS RentalPaymentsLocal,
	|	0 AS RentalPaymentsManag,
	|
	|	0 AS InterestDiscountInForeignCurrency,
	|	-LeftoversForDay.InterestDiscountLocal AS InterestDiscountLocal,
	|	-LeftoversForDay.InterestDiscountMan AS InterestDiscountMan,
	|
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.Contract AS Contract,
	|	LeftoversForDay.FixedAsset AS FixedAsset,
	|	LeftoversForDay.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	&BusinessOperation,
	|	&BusinessTransactionSetting
	|FROM
	|	TTBalancesForDay AS LeftoversForDay
	|		LEFT JOIN AnalyticsOfDay
	|		ON LeftoversForDay.Organization = AnalyticsOfDay.Organization
	|			AND LeftoversForDay.Contract = AnalyticsOfDay.Contract
	|			AND LeftoversForDay.Currency= AnalyticsOfDay.Currency
	|			AND LeftoversForDay.FixedAsset = AnalyticsOfDay.FixedAsset
	|			AND LeftoversForDay.FinancialAccountingGroup = AnalyticsOfDay.FinancialAccountingGroup
	|WHERE
	|	LeftoversForDay.InterestDiscountInForeignCurrency = 0
	|	AND (NOT AnalyticsOfDay.Organization IS NULL
	|		OR &EndOfPeriod = &EndOfMonth
	|		OR &RevaluationByDays)
	|	AND (LeftoversForDay.InterestDiscountLocal <> 0 OR LeftoversForDay.InterestDiscountMan <> 0)
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.RentalPaymentsLocal <> 0 AND Balance.RentalPaymentsLocal > 0
	|		THEN VALUE(AccumulationRecordType.Receipt) 
	|		ELSE VALUE(AccumulationRecordType.Expense) 
	|	END AS RecordType,
	|	CASE WHEN Balance.RentalPaymentsLocal < 0
	|		THEN -Balance.RentalPaymentsLocal
	|		ELSE Balance.RentalPaymentsLocal
	|	END AS RentalPaymentsLocal,
	|	0 AS RentalPaymentsManag,
	|	0 AS InterestDiscountLocal,
	|	0 AS InterestDiscountMan,
	|	FALSE AS ThisIsPercentageDiscount,
	|	Balance.Organization AS Organization,
	|	Balance.Contract AS Contract,
	|	Balance.FixedAsset AS FixedAsset,
	|	Balance.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO RentalInvestmentsTable
	|FROM
	|	TTExchangeRateDifferencesOfInvestments AS Balance
	|WHERE
	|	Balance.RentalPaymentsLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.InterestDiscountLocal <> 0 AND Balance.InterestDiscountLocal > 0
	|		THEN VALUE(AccumulationRecordType.Receipt) 
	|		ELSE VALUE(AccumulationRecordType.Expense) 
	|	END AS RecordType,
	|	0 AS RentalPaymentsLocal,
	|	0 AS RentalPaymentsManag,
	|	CASE WHEN Balance.InterestDiscountLocal < 0
	|		THEN -Balance.InterestDiscountLocal
	|		ELSE Balance.InterestDiscountLocal
	|	END AS InterestDiscountLocal,
	|	0 AS InterestDiscountMan,
	|	TRUE AS ThisIsPercentageDiscount,
	|	Balance.Organization AS Organization,
	|	Balance.Contract AS Contract,
	|	Balance.FixedAsset AS FixedAsset,
	|	Balance.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTExchangeRateDifferencesOfInvestments AS Balance
	|WHERE
	|	Balance.InterestDiscountLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.RentalPaymentsManag <> 0 AND Balance.RentalPaymentsManag > 0
	|		THEN VALUE(AccumulationRecordType.Receipt) 
	|		ELSE VALUE(AccumulationRecordType.Expense) 
	|	END AS RecordType,
	|	0 AS RentalPaymentsLocal,
	|	CASE WHEN Balance.RentalPaymentsManag < 0
	|		THEN -Balance.RentalPaymentsManag
	|		ELSE Balance.RentalPaymentsManag
	|	END AS RentalPaymentsManag,
	|	0 AS InterestDiscountLocal,
	|	0 AS InterestDiscountMan,
	|	FALSE AS ThisIsPercentageDiscount,
	|	Balance.Organization AS Organization,
	|	Balance.Contract AS Contract,
	|	Balance.FixedAsset AS FixedAsset,
	|	Balance.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTExchangeRateDifferencesOfInvestments AS Balance
	|WHERE
	|	Balance.RentalPaymentsManag <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Currency AS Currency,
	|	&EndOfPeriod AS Period,
	|	CASE WHEN Balance.InterestDiscountMan <> 0 AND Balance.InterestDiscountMan > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	0 AS RentalPaymentsLocal,
	|	0 AS RentalPaymentsManag,
	|	0 AS InterestDiscountLocal,
	|	CASE WHEN Balance.InterestDiscountMan < 0
	|		THEN -Balance.InterestDiscountMan
	|		ELSE Balance.InterestDiscountMan
	|	END AS InterestDiscountMan,
	|	TRUE AS ThisIsPercentageDiscount,
	|	Balance.Organization AS Organization,
	|	Balance.Contract AS Contract,
	|	Balance.FixedAsset AS FixedAsset,
	|	Balance.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTExchangeRateDifferencesOfInvestments AS Balance
	|WHERE
	|	Balance.InterestDiscountMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RentalInvestmentsTable.Currency,
	|	RentalInvestmentsTable.Period AS Period,
	|	RentalInvestmentsTable.RecordType AS RecordType,
	|	SUM(RentalInvestmentsTable.RentalPaymentsLocal) AS RentalPaymentsLocal,
	|	SUM(RentalInvestmentsTable.RentalPaymentsManag) AS RentalPaymentsManag,
	|	SUM(RentalInvestmentsTable.InterestDiscountLocal) AS InterestDiscountLocal,
	|	SUM(RentalInvestmentsTable.InterestDiscountMan) AS InterestDiscountMan,
	|	RentalInvestmentsTable.ThisIsPercentageDiscount AS ThisIsPercentageDiscount,
	|	RentalInvestmentsTable.Organization AS Organization,
	|	RentalInvestmentsTable.Contract AS Contract,
	|	RentalInvestmentsTable.FixedAsset AS FixedAsset,
	|	RentalInvestmentsTable.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RentalInvestmentsTable.BusinessOperation AS BusinessOperation,
	|	RentalInvestmentsTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO ExchangeRateDifferencesInvestmentInRent
	|FROM
	|	RentalInvestmentsTable AS RentalInvestmentsTable
	|
	|GROUP BY
	|	RentalInvestmentsTable.Currency,
	|	RentalInvestmentsTable.Period,
	|	RentalInvestmentsTable.ThisIsPercentageDiscount,
	|	RentalInvestmentsTable.Organization,
	|	RentalInvestmentsTable.Contract,
	|	RentalInvestmentsTable.FixedAsset,
	|	RentalInvestmentsTable.FinancialAccountingGroup,
	|	RentalInvestmentsTable.BusinessOperation,
	|	RentalInvestmentsTable.RecordType,
	|	RentalInvestmentsTable.BusinessTransactionSetting
	|;
	|";
	
EndFunction
//++ WE

Function QueryTextExchangeRateDifferencesPayrollCalculations()
	
	// we overestimate only the currency of the upr.
	Return 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|"+
	"SELECT DISTINCT
	|	RevolutionsPerDay.Organization AS Organization,
	|	RevolutionsPerDay.Individual AS Individual,
	|	RevolutionsPerDay.ARAPType AS ARAPType
	|INTO AnalyticsOfDay
	|FROM
	|	AccumulationRegister.PayrollCalculationsHR.Turnovers(&BorderStartOfPeriod, &BorderEndOfPeriod, , Organization = &Organization) AS RevolutionsPerDay
	|
	|INDEX BY
	|	Organization,
	|	Individual,
	|	ARAPType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Organization AS Organization,
	|	Balance.Individual AS Individual,
	|	Balance.ARAPType AS ARAPType,
	|	Balance.SumBalance AS AmountInCurrency,
	|	Balance.SumManBalance AS SumMan,
	|	Balance.SumComplBalance AS SumCompl,
	|	&LocalAccountingCurrency AS Currency
	|INTO TTBalancesForDay
	|FROM
	|	AccumulationRegister.PayrollCalculationsHR.Balance(&BorderEndOfPeriod, Organization = &Organization) AS Balance
	|
	|INDEX BY
	|	Organization,
	|	Individual,
	|	ARAPType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversForDay.Currency AS Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY) AS Period,
	|	LeftoversForDay.AmountInCurrency AS AmountInCurrency,
	|	LeftoversForDay.SumCompl AS SumCompl,
	|	LeftoversForDay.SumMan AS SumMan,
	|	ISNULL(CurrencyExchangeRate.CourseNumerator, 1) AS CourseNumeratorLocal,
	|	ISNULL(CurrencyExchangeRate.CourseDenominator, 1) AS CourseDenominatorLocal,
	|	ISNULL(ManSExchangeRate.CourseNumerator, 1) AS CourseNumeratorMan,
	|	ISNULL(ManSExchangeRate.CourseDenominator, 1) AS CourseDenominatorMan,
	|	LeftoversForDay.Organization AS Organization,
	|	LeftoversForDay.Individual AS Individual,
	|	LeftoversForDay.ARAPType AS ARAPType,
	|	&BusinessOperation AS BusinessOperation,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TTBalancePayWithCourses
	|FROM
	|	TTBalancesForDay AS LeftoversForDay
	|		LEFT JOIN AnalyticsOfDay AS AnalyticsOfDay
	|		ON LeftoversForDay.Organization = AnalyticsOfDay.Organization
	|			AND LeftoversForDay.Individual = AnalyticsOfDay.Individual
	|			AND LeftoversForDay.ARAPType = AnalyticsOfDay.ARAPType
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON LeftoversForDay.Currency = CurrencyExchangeRate.Currency
	|		LEFT JOIN TTExchangeRatesMan AS ManSExchangeRate
	|		ON (TRUE)
	|WHERE
	|	LeftoversForDay.AmountInCurrency <> 0
	|	AND (NOT AnalyticsOfDay.Organization IS NULL
	|			OR &EndOfPeriod = &EndOfMonth
	|			OR &RevaluationByDays)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftoversPayWithCourses.Currency AS Currency,
	|	LeftoversPayWithCourses.Period AS Period,
	|	LeftoversPayWithCourses.AmountInCurrency AS AmountInCurrency,
	|	0 AS SumCompl,
	|	(CAST(LeftoversPayWithCourses.AmountInCurrency * LeftoversPayWithCourses.CourseNumeratorLocal / LeftoversPayWithCourses.CourseDenominatorLocal * LeftoversPayWithCourses.CourseDenominatorMan / LeftoversPayWithCourses.CourseNumeratorMan AS NUMBER(31, 2))) - LeftoversPayWithCourses.SumMan AS SumMan,
	|	LeftoversPayWithCourses.Organization AS Organization,
	|	LeftoversPayWithCourses.Individual AS Individual,
	|	LeftoversPayWithCourses.ARAPType AS ARAPType,
	|	LeftoversPayWithCourses.BusinessOperation AS BusinessOperation,
	|	LeftoversPayWithCourses.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TTExchangeRateDifferencesPayrollCalculations
	|FROM
	|	TTBalancePayWithCourses AS LeftoversPayWithCourses
	|WHERE
	|	CAST(LeftoversPayWithCourses.AmountInCurrency * LeftoversPayWithCourses.CourseNumeratorLocal / LeftoversPayWithCourses.CourseDenominatorLocal * LeftoversPayWithCourses.CourseDenominatorMan / LeftoversPayWithCourses.CourseNumeratorMan AS NUMBER(31, 2)) <> LeftoversPayWithCourses.SumMan
	|
	|UNION ALL
	|
	|SELECT
	|	LeftoversForDay.Currency,
	|	ENDOFPERIOD(&EndOfPeriod, DAY),
	|	0,
	|	0,
	|	-LeftoversForDay.SumMan,
	|	LeftoversForDay.Organization,
	|	LeftoversForDay.Individual,
	|	LeftoversForDay.ARAPType,
	|	&BusinessOperation,
	|	&BusinessTransactionSetting
	|FROM
	|	TTBalancesForDay AS LeftoversForDay
	|		LEFT JOIN AnalyticsOfDay AS AnalyticsOfDay
	|		ON LeftoversForDay.Organization = AnalyticsOfDay.Organization
	|			AND LeftoversForDay.Individual = AnalyticsOfDay.Individual
	|			AND LeftoversForDay.ARAPType = AnalyticsOfDay.ARAPType
	|WHERE
	|	LeftoversForDay.AmountInCurrency = 0
	|	AND (NOT AnalyticsOfDay.Organization IS NULL
	|			OR &EndOfPeriod = &EndOfMonth
	|			OR &RevaluationByDays)
	|	AND (LeftoversForDay.SumCompl <> 0
	|			OR LeftoversForDay.SumMan <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&EndOfPeriod AS Period,
	|	CASE
	|		WHEN Balance.SumCompl <> 0
	|				AND Balance.SumCompl > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	CASE
	|		WHEN Balance.SumCompl < 0
	|			THEN -Balance.SumCompl
	|		ELSE Balance.SumCompl
	|	END AS SumCompl,
	|	0 AS SumMan,
	|	Balance.Organization AS Organization,
	|	Balance.Individual AS Individual,
	|	Balance.ARAPType AS ARAPType,
	|	Balance.BusinessOperation AS BusinessOperation,
	|	Balance.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TablePayrollCalculations
	|FROM
	|	TTExchangeRateDifferencesPayrollCalculations AS Balance
	|WHERE
	|	Balance.SumCompl <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&EndOfPeriod,
	|	CASE
	|		WHEN Balance.SumMan <> 0
	|				AND Balance.SumMan > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	0,
	|	CASE
	|		WHEN Balance.SumMan < 0
	|			THEN -Balance.SumMan
	|		ELSE Balance.SumMan
	|	END,
	|	Balance.Organization,
	|	Balance.Individual,
	|	Balance.ARAPType,
	|	Balance.BusinessOperation,
	|	Balance.BusinessTransactionSetting
	|FROM
	|	TTExchangeRateDifferencesPayrollCalculations AS Balance
	|WHERE
	|	Balance.SumMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&EndOfPeriod,
	|	CASE
	|		WHEN Balance.SumMan <> 0
	|				AND Balance.SumMan > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	0,
	|	0,
	|	Balance.Organization,
	|	Balance.Individual,
	|	Balance.ARAPType,
	|	Balance.BusinessOperation,
	|	Balance.BusinessTransactionSetting
	|FROM
	|	TTExchangeRateDifferencesPayrollCalculations AS Balance
	|WHERE
	|	Balance.SumMan <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TablePayrollCalculations.Period AS Period,
	|	TablePayrollCalculations.RecordType AS RecordType,
	|	SUM(TablePayrollCalculations.SumCompl) AS SumCompl,
	|	SUM(TablePayrollCalculations.SumMan) AS SumMan,
	|	TablePayrollCalculations.Organization AS Organization,
	|	TablePayrollCalculations.Individual AS Individual,
	|	TablePayrollCalculations.ARAPType AS ARAPType,
	|	TablePayrollCalculations.BusinessOperation AS BusinessOperation,
	|	TablePayrollCalculations.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO ExchangeRateDifferencesPayrollCalculationsHR
	|FROM
	|	TablePayrollCalculations AS TablePayrollCalculations
	|
	|GROUP BY
	|	TablePayrollCalculations.Period,
	|	TablePayrollCalculations.Organization,
	|	TablePayrollCalculations.Individual,
	|	TablePayrollCalculations.ARAPType,
	|	TablePayrollCalculations.BusinessOperation,
	|	TablePayrollCalculations.RecordType,
	|	TablePayrollCalculations.BusinessTransactionSetting";
	
EndFunction

//-- WE
#EndRegion

#Region BlockingWhenUpdatingInformationSecurity

Procedure CheckBlockingIncomingDataWhenUpdatingInformationSecurity(PresentationOperation, RegistersForCalculation)
	
	IncomingData = New Map;
	IncomingData.Insert(Metadata.Documents.ExchangeDifferenceCalculation);
	For Each Register In RegistersForCalculation Do
		IncomingData.Insert(Metadata.AccumulationRegisters[Register.Key]);
	EndDo;
	IncomingData.Insert(Metadata.InformationRegisters.AccountingDimensionByPartners);
	IncomingData.Insert(Metadata.InformationRegisters.RelativeExchangeRates);
	
	MonthEndTransactionsServer.CheckBlockingIncomingDataWhenUpdatingInformationSecurity(IncomingData, PresentationOperation);
	
EndProcedure

#EndRegion

#Region FormationOfTasksForEndOfMonthServiceTasks

Function MatchingRequestsToControlRegisters(Query)
	
	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableBankAccountCash", QueryTextCash(
		Query, "ChangesTableBankAccountCash", "BankAccount.CashCurrency"));
	MatchingQueryTexts.Insert("ChangesTableCashInCashRegistersCR", QueryTextCash(
		Query, "ChangesTableCashInCashRegistersCR", "CashRegister.CashCurrency"));
	MatchingQueryTexts.Insert("ChangesTableCashInTransit", QueryTextCash(
		Query, "ChangesTableCashInTransit"));
	MatchingQueryTexts.Insert("ChangesTableCashAccountBalance", QueryTextCash(
		Query, "ChangesTableCashAccountBalance", "CashAccount.CashCurrency"));
	MatchingQueryTexts.Insert("ChangesTableAdvanceHolderCash",
		QueryTextCash(Query, "ChangesTableAdvanceHolderCash"));
	MatchingQueryTexts.Insert("ChangesTableFinancialInstrumentsARAP",
		QueryTextFinancialInstrumentsARAP(Query));
	ExchangeDifferenceCalculationLocalization.AddMatchingRequestsToControlRegisters(Query, MatchingQueryTexts);
	//++ WE
	If Constants.PayrollAndHumanResourcesWE.Get() Then
		MatchingQueryTexts.Insert("ChangesTablePayrollCalculationsHR",
			QueryTextControlPayrollCalculations(Query));
	EndIf;
	//-- WE
	
	Return MatchingQueryTexts;
	
EndFunction

#Region RequestTextsForTasksAtEndOfMonth

Function QueryTextCash(Query, TempTableName, AccessingCurrencyField = "Currency") Export
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.RevaluationOfCashAndFinancialInstruments) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	&TempTableName AS Table
	|	INNER JOIN Constants AS Constants
	|	ON TRUE
	|WHERE
	|	VALUETYPE(Table.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|		OR &CurrencyOverridable <> Constants.ManagementAccountingCurrency
	|		OR &CurrencyOverridable <> Table.Organization.LocalAccountingCurrency
	|";
	QueryText = StrReplace(QueryText, "&TempTableName", TempTableName);
	QueryText = StrReplace(QueryText, "&CurrencyOverridable", "Table." + AccessingCurrencyField);
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextFinancialInstrumentsARAP(Query) Export
	If Not Query.Parameters.Property("CurrencyOfMan") Then
		Query.SetParameter("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.RevaluationOfCashAndFinancialInstruments) AS Operation,
	|	Dimension.Organization AS Organization,
	|	ChangesTable.Recorder AS Document
	|FROM
	|	ChangesTableFinancialInstrumentsARAP AS ChangesTable
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON ChangesTable.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	(VALUETYPE(ChangesTable.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			OR ChangesTable.Contract.ARAPCurrency <> &CurrencyOfMan
	|			OR ChangesTable.Contract.ARAPCurrency <> Dimension.Organization.LocalAccountingCurrency)
	|	AND (ChangesTable.Sum <> 0
	|		OR ChangesTable.SumMan <> 0
	|		OR ChangesTable.SumCompl <> 0)
	|	AND VALUETYPE(ChangesTable.Contract) <> TYPE(Catalog.LeaseContract)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.RevaluationOfLeases) AS Operation,
	|	Dimension.Organization AS Organization,
	|	ChangesTable.Recorder AS Document
	|FROM
	|	ChangesTableFinancialInstrumentsARAP AS ChangesTable
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON ChangesTable.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	(VALUETYPE(ChangesTable.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			OR ChangesTable.Contract.ARAPCurrency <> &CurrencyOfMan
	|			OR ChangesTable.Contract.ARAPCurrency <> Dimension.Organization.LocalAccountingCurrency)
	|	AND (ChangesTable.Sum <> 0
	|		OR ChangesTable.SumMan <> 0
	|		OR ChangesTable.SumCompl <> 0)
	|	AND VALUETYPE(ChangesTable.Contract) = TYPE(Catalog.LeaseContract)
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_

EndFunction

//++ WE

// Generates and returns the Query Text for monitoring payroll settlements when revaluing foreign currency obligations.
//
// Parameters:
//   Query - Query - Request object for setting parameters.
//
// Returns:
//   Structure - Structure with Query Texts for performing control
//
Function QueryTextControlPayrollCalculations(Query)
	If Not Query.Parameters.Property("CurrencyOfMan") Then
		Query.SetParameter("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.PayrollCalculationRevaluation) AS Operation,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Recorder AS Document
	|FROM
	|	ChangesTablePayrollCalculationsHR AS ChangesTable
	|WHERE
	|	(VALUETYPE(ChangesTable.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			OR ChangesTable.Organization.LocalAccountingCurrency <> &CurrencyOfMan)
	|	AND (ChangesTable.Sum <> 0
	|		OR ChangesTable.SumMan <> 0
	|		OR ChangesTable.SumCompl <> 0)
	|
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_

EndFunction
//-- WE
#EndRegion

#EndRegion

#Region Other

Procedure ConductReevaluationDocument(Organization, Period, Operation, RevaluationParameters = Undefined)
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Return;
	EndIf;
	
	If ValueIsFilled(ExchangePlans.MasterNode()) Then
		Return;
	EndIf;
	
	#Region InitializingRevaluationParameters
	RegistersForCalculation = CalculationRegisters(Operation);
	DimensionCalculation = Undefined;
	ProcessedItemsCount = 0;
	If ValueIsFilled(RevaluationParameters) Then
		If RevaluationParameters.Property("CalculationRegisters") Then
			RegistersForCalculation = RevaluationParameters.CalculationRegisters;
		EndIf;
		RevaluationParameters.Property("DimensionCalculation", DimensionCalculation);
		If TypeOf(DimensionCalculation) = Type("Structure") Then
			AllEmpty = True;
			For Each Dimension In DimensionCalculation Do
				If TypeOf(Dimension.Value) = Type("Array") Then
					For Each Value In Dimension.Value Do
						If ValueIsFilled(Value) Then
							AllEmpty = False;
							Break;
						EndIf;
					EndDo;
				ElsIf ValueIsFilled(Dimension.Value) Then
					AllEmpty = False;
					Break;
				EndIf;
			EndDo;
			If AllEmpty Then
				DimensionCalculation = Undefined;
			EndIf;
		EndIf;
		If RevaluationParameters.Property("ProcessedItemsCount") Then
			ProcessedItemsCount = RevaluationParameters.ProcessedItemsCount;
		EndIf;
	EndIf;
	#EndRegion
	
	AccessManagement.DisableAccessKeysUpdate(True);
	BeginTransaction();
	Try
		CalculationIsExecuted = False;
		If GetFunctionalOption("NewOnlineARAPAccounting")
			And (Operation = Enums.BusinessTransactions.RevaluationOfCustomersARAP 
				Or Operation = Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting) Then
			CalculateExchangeDifferencesByTerms(Organization, Period, Operation);
			CalculationIsExecuted = True;
		EndIf;
		
	
		If Not CalculationIsExecuted And Not ReEvaluationRequired(Organization, Period, RegistersForCalculation, DimensionCalculation)  Then
			AccessManagement.DisableAccessKeysUpdate(False);
			CommitTransaction();
			Return;
		EndIf;
		
		Query = New Query(
		"SELECT
		|	Document.Ref AS Ref,
		|	Document.Organization AS Organization
		|INTO TTRevaluationDocument
		|FROM
		|	Document.ExchangeDifferenceCalculation AS Document
		|WHERE
		|	Document.BusinessOperation = &Operation
		|	AND NOT Document.DeletionMark
		|	AND Document.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (Document.Organization IN (&Organization) OR &AllCompanies)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Companies.Ref AS Organization,
		|	ISNULL(Document.Ref, UNDEFINED) AS Document
		|FROM
		|	Catalog.Companies AS Companies
		|		LEFT JOIN TTRevaluationDocument AS Document
		|		ON Companies.Ref = Document.Organization
		|WHERE
		|	NOT Companies.DeletionMark
		|	AND (Companies.Ref IN (&Organization) OR (&AllCompanies
		|			AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)))
		|	AND (Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
		|		OR &ConsiderManOrganization)");
		
		Query.SetParameter("Operation",       Operation);
		Query.SetParameter("BeginOfPeriod",  BegOfMonth(Period));
		Query.SetParameter("EndOfPeriod",   EndOfMonth(Period));
		Query.SetParameter("Organization",    Organization);
		Query.SetParameter("AllCompanies", Not ValueIsFilled(Organization));
		Query.SetParameter("ConsiderManOrganization", GetFunctionalOption("UseManagementCompany"));
		
		MigrationToOnlineARAPAccountingHasStarted = Constants.MigrationToOnlineARAPAccountingHasStarted.Get();
		ReevaluateByDay = Constants.RevalueCurrencyByDays.Get();
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			If ValueIsFilled(Selection.Document) Then
				
				If Not CalculationIsExecuted Then
					CompleteCalculateExchangeDifferences(Selection.Document, RegistersForCalculation, DimensionCalculation, ProcessedItemsCount);
				EndIf;
				
				DocumentObject = Selection.Document.GetObject();
				DocumentObject.DeletionMark = False;
				DocumentObject.AdditionalProperties.Insert("CalculationIsExecuted", True);// disable re-calculation when conducting
				If MigrationToOnlineARAPAccountingHasStarted Then
					DocumentObject.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
				EndIf;
				DocumentObject.Write(DocumentWriteMode.Posting);
				
			Else
				
				DocumentObject = Documents.ExchangeDifferenceCalculation.CreateDocument();
				DocumentObject.Date = EndOfMonth(Period);
				DocumentObject.Organization = Selection.Organization;
				DocumentObject.BusinessOperation = Operation;
				DocumentObject.RevaluationByDays = ReevaluateByDay;
				If MigrationToOnlineARAPAccountingHasStarted Then
					DocumentObject.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
				EndIf;
				DocumentObject.Write();
				
				If Not CalculationIsExecuted Then
					CompleteCalculateExchangeDifferences(DocumentObject.Ref, RegistersForCalculation, DimensionCalculation, ProcessedItemsCount);
				EndIf;
				
				DocumentObject.AdditionalProperties.Insert("CalculationIsExecuted", True);// disable re-calculation when conducting
				DocumentObject.Write(DocumentWriteMode.Posting);
				
			EndIf;
			
		EndDo;// On the organization
		
		AccessManagement.DisableAccessKeysUpdate(False);
		CommitTransaction();
		
	Except
		RollbackTransaction();
		AccessManagement.DisableAccessKeysUpdate(False);
		ErrorText = DetailErrorDescription(ErrorInfo());
		Raise ErrorText;
	EndTry;
	
	If ValueIsFilled(RevaluationParameters) And RevaluationParameters.Property("ProcessedItemsCount") Then
		RevaluationParameters.ProcessedItemsCount = ProcessedItemsCount;
	EndIf;
	
EndProcedure

Function RecordRegisteredRecords(DocumentRef, TableManager, RegisterName, Day, AdditionalParameters)
	
	TotalRecorded = 0;
	ExchangeRateDifferences = TableManager.Tables["ExchangeRateDifferences" + RegisterName].GetData().Unload();
	FillInIdsOfFinRecords(ExchangeRateDifferences, DocumentRef, RegisterName, Day);
	If ExchangeRateDifferences.Count() > 0 Then
		Set = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet - 
		Set.Filter.Recorder.Set(DocumentRef);
		Set.Load(ExchangeRateDifferences);
		Set.Write(False);
		TotalRecorded = ExchangeRateDifferences.Count();
	EndIf;
	

	Return TotalRecorded;
	
EndFunction

// In some cases, the calculation of exchange rate differences according to the register "Calculation of Financial Instruments" may not be transmitted to the MFIs.
// If the MFIs uses the allocation of long-term assets and liabilities, then the amount of the financial instrument can be accounted
// for in the long-term account, and the amount of the calculated exchange rate difference will be reflected in the short-term account, as well as all transactions on
// financial instruments. After that, the routine operation of closing the month for calculating exchange differences in the "International" register
// will form another transaction on a short-term account to "neutralize" the transaction for calculating the exchange difference from the operating account.
// In order to get rid of unnecessary turnovers and an expanded balance on income - expense accounts, the movements of calculating exchange rate differences
// according to the "Settlement of Financial Instruments" register when using the division of debts by the terms of circulation are not transmitted to the MFIs.
//
Procedure FillInIdsOfFinRecords(ExchangeRateDifferences, DocumentRef, RegisterName, Day)
	
	TMCommonUse.AddRowIDToTable(ExchangeRateDifferences, "FinRecordID", "String");
	If RegisterName = "FinancialInstrumentsARAP" Then
		Organization = Common.ObjectAttributeValue(DocumentRef, "Organization");
		If FinancialAccountingByFinancialRegisterData.AllocationOfLongTermAssetsAndLiabilitiesIsUsed(Organization, Day) Then
			ExchangeRateDifferences.FillValues(DocumentsPosting.IDOfUnusedFinRecord(), "FinRecordID");
		EndIf;
	EndIf;
EndProcedure

// There are currency balances.
// 
// Parameters:
//  Organization - Referenceslink.Organizations, Array from the reference link.Organizations
//  Period - Date
//  RegistersForCalculation - Undefined, Structure - in the keys of which the registers for the calculation are specified:
// 	* VendorsARAPAccountingByDocuments 
// 	* CustomersARAPAccountingByDocuments 
// 	* BankAccountCash 
// 	* CashAccountBalance 
// 	* CashInCashRegistersCR 
// 	* CashInTransit 
// 	* AdvanceHolderCash 
// 	* FinancialInstrumentsARAP 
// 	* FinancialInstrumentsARAP 
// 	* LossAllowance 
// 	* DiscountInterestExpense 
//  DimensionCalculation - Undefined, Structure - Calculation Analytics:
// * TypesOfAmounts - Array of EnumRef.FinancialInstrumentScheduleTypes, EnumRef.TypesOfLeasePayments
// 
// Returns:
//  Boolean - There are currency balances
Function ThereAreCurrencyBalances(Organization, Period, RegistersForCalculation = Undefined, DimensionCalculation = Undefined) Export
	
	QueryTextTT = "";
	If RegistersForCalculation.Property("VendorsARAPAccountingByDueDates")
		Or RegistersForCalculation.Property("CustomersARAPAccountingByDueDates")
		Or RegistersForCalculation.Property("VendorsARAPAccountingByDocuments")
		Or RegistersForCalculation.Property("CustomersARAPAccountingByDocuments")
		Or RegistersForCalculation.Property("LossAllowance") Then
		QueryTextTT = QueryTextTT + 
		"SELECT
		|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
		|	AccountingDimensionByPartners.Organization AS Organization
		|INTO TTPartnerAnalyticsKeys
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|WHERE
		|	(AccountingDimensionByPartners.Organization IN (&Organization) OR &AllCompanies)
		|	AND (AccountingDimensionByPartners.DimensionKey IN (&AccountingDimensionByPartners) OR &ForAllAnalysts)"
		+ RequestPacketSeparator();
	EndIf;
	
	If Not ValueIsFilled(RegistersForCalculation) Then
		RegistersForCalculation = CalculationRegisters();
	EndIf;
	Separator = Chars.LF+Chars.LF;
	Union = Separator+"UNION ALL"+Separator;
	QueryText = "";
	
	#Region VendorsARAPAccountingByDocuments
	If RegistersForCalculation.Property("VendorsARAPAccountingByDocuments") Then
		QueryText = QueryText + 
		"SELECT TOP 1
		|	""VendorsARAPAccountingByDocuments"" AS SubjectOfRevaluation,
		|	Balance.Currency AS Currency
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
		|		&BorderEndOfPeriod,
		|		AccountingDimensionByPartners IN (SELECT T.DimensionKey FROM TTPartnerAnalyticsKeys AS T)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region CustomersARAPAccountingByDocuments
	If RegistersForCalculation.Property("CustomersARAPAccountingByDocuments") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""CustomersARAPAccountingByDocuments"" AS SubjectOfRevaluation,
		|	Balance.Currency AS Currency
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
		|		&BorderEndOfPeriod,
		|		AccountingDimensionByPartners IN (SELECT T.DimensionKey FROM TTPartnerAnalyticsKeys AS T)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region VendorsARAPAccountingByDueDates
	If RegistersForCalculation.Property("VendorsARAPAccountingByDueDates") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""VendorsARAPAccountingByDueDates"" AS SubjectOfRevaluation,
		|	Balance.Currency AS Currency
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|		&BorderEndOfPeriod,
		|		AccountingDimensionByPartners IN (SELECT T.DimensionKey FROM TTPartnerAnalyticsKeys AS T)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region CustomersARAPAccountingByDueDates
	If RegistersForCalculation.Property("CustomersARAPAccountingByDueDates") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""CustomersARAPAccountingByDueDates"" AS SubjectOfRevaluation,
		|	Balance.Currency AS Currency
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
		|		&BorderEndOfPeriod,
		|		AccountingDimensionByPartners IN (SELECT T.DimensionKey FROM TTPartnerAnalyticsKeys AS T)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region BankAccountCash
	If RegistersForCalculation.Property("BankAccountCash") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""BankAccountCash"" AS SubjectOfRevaluation,
		|	Balance.BankAccount AS Cash
		|FROM
		|	AccumulationRegister.BankAccountCash.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (BankAccount IN (&BankAccounts) OR &ForAllAccounts)
		|			AND (BankAccount.CashCurrency <> &CurrencyOfManAccounting
		|				OR BankAccount.CashCurrency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region CashAccountBalance
	If RegistersForCalculation.Property("CashAccountBalance") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""CashAccountBalance"" AS SubjectOfRevaluation,
		|	Balance.CashAccount AS Cash
		|FROM
		|	AccumulationRegister.CashAccountBalance.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (CashAccount IN (&CashAccounts) OR &ForAllSalesRegisters)
		|			AND (CashAccount.CashCurrency <> &CurrencyOfManAccounting
		|				OR CashAccount.CashCurrency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region CashInCashRegistersCR
	If RegistersForCalculation.Property("CashInCashRegistersCR") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""CashInCashRegistersCR"" AS SubjectOfRevaluation,
		|	Balance.CashRegister AS Cash
		|FROM
		|	AccumulationRegister.CashInCashRegistersCR.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (CashRegister IN (&CashRegisters) OR &ForAllCashRegisterSalesRegisters)
		|			AND (CashRegister.CashCurrency <> &CurrencyOfManAccounting
		|			OR CashRegister.CashCurrency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region AdvanceHolderCash
	If RegistersForCalculation.Property("AdvanceHolderCash") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""AdvanceHolderCash"" AS SubjectOfRevaluation,
		|	Balance.AdvanceHolder AS Cash
		|FROM
		|	AccumulationRegister.AdvanceHolderCash.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (AdvanceHolder IN (&Persons) OR &ForAllIndividuals)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	//++ WE
	#Region CashSettlementsOnLaborRemuneration
	If RegistersForCalculation.Property("PayrollCalculationsHR") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""PayrollCalculations"" AS SubjectOfRevaluation,
		|	Balance.Individual AS Cash
		|FROM
		|	AccumulationRegister.PayrollCalculationsHR.Balance(
		|			&BorderEndOfPeriod,
		|			Organization IN (&Organization)
		|				OR &AllCompanies) AS Balance";
	EndIf;
	#EndRegion
	//-- WE
	#Region CashInTransit
	If RegistersForCalculation.Property("CashInTransit") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""CashInTransit"" AS SubjectOfRevaluation,
		|	Balance.CashTransferKind AS Cash
		|FROM
		|	AccumulationRegister.CashInTransit.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region FinancialInstrumentsARAP
	If RegistersForCalculation.Property("FinancialInstrumentsARAP") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""FinancialInstrumentsARAP"" AS SubjectOfRevaluation,
		|	Balance.Contract AS Currency
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
		|		&BorderEndOfPeriod,
		|		(AccountingDimensionByPartners.Organization IN (&Organization) OR &AllCompanies)
		|			AND (AmountType IN (&TypesOfAmounts) OR &ForAllTypesOfAmounts)
		|			AND (Contract.ARAPCurrency <> &CurrencyOfManAccounting
		|				OR Contract.ARAPCurrency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	#Region LossAllowance
	If RegistersForCalculation.Property("LossAllowance") Then
		QueryText = QueryText + 
		"SELECT TOP 1
		|	""LossAllowance"" AS SubjectOfRevaluation,
		|	Balance.Currency AS Currency
		|FROM
		|	AccumulationRegister.LossAllowance.Balance(
		|		&BorderEndOfPeriod,
		|		AccountingDimensionByPartners IN (SELECT T.DimensionKey FROM TTPartnerAnalyticsKeys AS T)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	#Region GoodsToBeRegisteredInReportsToConsignor
	If RegistersForCalculation.Property("GoodsToBeRegisteredInReportsToConsignor") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""GoodsToBeRegisteredInReportsToConsignor"" AS SubjectOfRevaluation,
		|	Balance.Currency AS Currency
		|FROM
		|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting
		|				OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region GoodsAndServicesToRegisterPurchasingReportsToConsignor
	If RegistersForCalculation.Property("GoodsAndServicesToRegisterPurchasingReportsToConsignor") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""GoodsAndServicesToRegisterPurchasingReportsToConsignor"" AS SubjectOfRevaluation,
		|	Balance.Currency AS Currency
		|FROM
		|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting
		|				OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	
	#Region ServicesForRegistrationOfReportsToPrincipal
	If RegistersForCalculation.Property("ServicesForRegistrationOfReportsToPrincipal") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""ServicesForRegistrationOfReportsToPrincipal"" AS SubjectOfRevaluation,
		|	Balance.Currency AS Currency
		|FROM
		|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting
		|				OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	#Region InvestmentInRent
	If RegistersForCalculation.Property("InvestmentInRent") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""InvestmentInRent"" AS SubjectOfRevaluation,
		|	Balance.FixedAsset AS FixedAsset
		|FROM
		|	AccumulationRegister.InvestmentInRent.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance";
	EndIf;
	#EndRegion
	ExchangeDifferenceCalculationLocalization.SupplementCheckThereAreCurrencyBalances(RegistersForCalculation, QueryText);
	
	Query = New Query(QueryTextTT + QueryText);
	Query.SetParameter("OnDate",              EndOfMonth(Period));
	Query.SetParameter("BorderEndOfPeriod", New Boundary(EndOfMonth(Period), BoundaryType.Including));
	Query.SetParameter("CurrencyOfManAccounting",      Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("Organization",         Organization);
	Query.SetParameter("AllCompanies",      Not ValueIsFilled(Organization));
	Query.SetParameter("AccountingDimensionByPartners", GetAnalytics("AccountingDimensionByPartners", DimensionCalculation));
	Query.SetParameter("ForAllAnalysts",    Not ValueIsFilled(Query.Parameters.AccountingDimensionByPartners));
	Query.SetParameter("BankAccounts",     GetAnalytics("BankAccounts", DimensionCalculation));
	Query.SetParameter("ForAllAccounts",        Not ValueIsFilled(Query.Parameters.BankAccounts));
	Query.SetParameter("CashAccounts",               GetAnalytics("CashAccounts", DimensionCalculation));
	Query.SetParameter("ForAllSalesRegisters",        Not ValueIsFilled(Query.Parameters.CashAccounts));
	Query.SetParameter("CashRegisters",            GetAnalytics("CashRegisters", DimensionCalculation));
	Query.SetParameter("ForAllCashRegisterSalesRegisters",     Not ValueIsFilled(Query.Parameters.CashRegisters));
	Query.SetParameter("Persons",      GetAnalytics("Persons", DimensionCalculation));
	Query.SetParameter("ForAllIndividuals",      Not ValueIsFilled(Query.Parameters.Persons));
	Query.SetParameter("TypesOfAmounts",            GetAnalytics("TypesOfAmounts", DimensionCalculation));
	Query.SetParameter("ForAllTypesOfAmounts",     Not ValueIsFilled(Query.Parameters.TypesOfAmounts));
	
	Result = Query.Execute();
	Return Not Result.IsEmpty();
	
EndFunction

// A reassessment is required.
// 
// Parameters:
//  Organization - CatalogRef.Companies, Array of CatalogRef.Companies - 
//  Period - Date
//   RegistersForCalculation - Undefined, Structure - in the keys of which the registers for the calculation are specified:
// 	* VendorsARAPAccountingByDocuments 
// 	* CustomersARAPAccountingByDocuments 
// 	* BankAccountCash 
// 	* CashAccountBalance 
// 	* CashInCashRegistersCR 
// 	* CashInTransit 
// 	* AdvanceHolderCash 
// 	* FinancialInstrumentsARAP 
// 	* FinancialInstrumentsARAP 
// 	* LossAllowance 
// 	* DiscountInterestExpense 
//  DimensionCalculation - Structure, Array, Undefined - Calculation Analytics:
// * TypesOfAmounts - Array of EnumRef.FinancialInstrumentScheduleTypes, EnumRef.TypesOfLeasePayments -
//  ReturnOrganizationsToReassessment - Boolean - Return organizations to revaluation
//  ForDebugging - Undefined - For debugging
// 
// Returns:
//  Boolean, Array of CatalogRef.Companies - Need to be reevaluated
Function ReEvaluationRequired(Organization, Period, RegistersForCalculation = Undefined, DimensionCalculation = Undefined, ReturnOrganizationsToReassessment = False, ForDebugging = Undefined) Export
	
	If Not ValueIsFilled(RegistersForCalculation) Then
		RegistersForCalculation = CalculationRegisters();
	EndIf;
	
	#Region TemporaryTablesAnalyticsExchangeRates
	QueryTextTT = "";
	If RegistersForCalculation.Property("VendorsARAPAccountingByDueDates")
		Or RegistersForCalculation.Property("CustomersARAPAccountingByDueDates")
		Or RegistersForCalculation.Property("VendorsARAPAccountingByDocuments")
		Or RegistersForCalculation.Property("CustomersARAPAccountingByDocuments")
		Or RegistersForCalculation.Property("FinancialInstrumentsARAP")
		Or RegistersForCalculation.Property("LossAllowance")
		Or RegistersForCalculation.Property("DiscountInterestExpense") Then
		QueryTextTT = QueryTextTT + 
		"SELECT DISTINCT
		|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
		|	AccountingDimensionByPartners.Organization AS Organization,
		|	AccountingDimensionByPartners.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	AccountingDimensionByPartners.Contract                                    AS Contract,
		|	ISNULL(
		|		AccountingDimensionByPartners.Contract.ContractRateOption, 
		|		VALUE(Enum.ContractRateOptions.Mutable))            AS ContractRateOption

		|INTO TTPartnerAnalyticsKeys
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|WHERE
		|	(AccountingDimensionByPartners.Organization IN (&Organization) OR &AllCompanies)
		|	AND (AccountingDimensionByPartners.DimensionKey IN (&AccountingDimensionByPartners) OR &ForAllAnalysts)
		|INDEX BY
		|	DimensionKey
		|;
		|
		|"
	EndIf;
	
	QueryTextTT = QueryTextTT + 
	"////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyRatesCut.Period,
	|	CurrencyRatesCut.BaseCurrency,
	|	CurrencyRatesCut.Currency,
	|	CurrencyRatesCut.CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator
	|INTO TTCourses
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&OnDate,) AS CurrencyRatesCut"
	+"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryTextTT = QueryTextTT + 
	"////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExchangeRateOfSettlementsUnderContractsCutOfLatest.Period,
	|	ExchangeRateOfSettlementsUnderContractsCutOfLatest.Contract,
	|	ExchangeRateOfSettlementsUnderContractsCutOfLatest.CourseNumerator,
	|	ExchangeRateOfSettlementsUnderContractsCutOfLatest.CourseDenominator
	|INTO TTCoursesOnContracts
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&OnDate,) AS ExchangeRateOfSettlementsUnderContractsCutOfLatest"
	+"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	#EndRegion
	
	Separator = Chars.LF+Chars.LF;
	Union = Separator+"UNION ALL"+Separator;
	QueryText = "";
	#Region VendorsARAPAccountingByDocuments
	If RegistersForCalculation.Property("VendorsARAPAccountingByDocuments") Then
		QueryText = QueryText + 
		"SELECT TOP 1
		|	""VendorsARAPAccountingByDocuments"" AS AccumulationRegister,
		|	Balance.Currency AS Currency,
		|	Balance.DebtBalance AS DebtBalance,
		|	Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.DebtLocalBalance AS DebtRateIsDifferentLocal,
		|	Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS DebtBalanceLocalSettlement,
		|	Balance.DebtLocalBalance AS RemainderOfLocal,
		|	Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.ARAPManBalance AS DebtRateIsDifferentMen,
		|	Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS DebtBalanceManSettlement,
		|	Balance.ARAPManBalance AS DebtBalanceMan,
		|
		|	Balance.PrepaymentBalance AS PrepaymentBalance,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.PrepaymentLocalBalance AS PrepaymentCourseIsDifferentLocal,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS PrepaymentBalanceLocalSettlement,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS PrepaymentBalanceLocal,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.PrepaymentManBalance AS PrepaymentCourseDifferentMen,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS PrepaymentBalanceManSettlement,
		|	Balance.PrepaymentManBalance AS PrepaymentBalanceMan,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Dimension.Organization AS Organization,
		|	Balance.PurchaseOrder AS Object,
		|	Balance.ARAPDocument AS ARAPDocument,
		|	UNDEFINED AS PlannedRepaymentDate,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
		|		&BorderEndOfPeriod,
		|		(Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTPartnerAnalyticsKeys AS Dimension
		|	ON Balance.AccountingDimensionByPartners = Dimension.DimensionKey
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|WHERE
		|	CAST(Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.ARAPManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.ARAPManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.DebtLocalBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.DebtLocalBalance AS NUMBER(31,2)) < -0.01
		|	OR (Balance.DebtBalance = 0 AND (Balance.DebtLocalBalance <> 0 OR Balance.ARAPManBalance <> 0))
		|	OR (Balance.PrepaymentBalance = 0 AND Balance.ForReturnBalance = 0 AND (Balance.PrepaymentLocalBalance <> 0 OR Balance.PrepaymentManBalance <> 0))";
	EndIf;
	#EndRegion
	
	#Region CustomersARAPAccountingByDocuments
	If RegistersForCalculation.Property("CustomersARAPAccountingByDocuments") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""CustomersARAPAccountingByDocuments"" AS AccumulationRegister,
		|	Balance.DebtBalance AS DebtBalance,
		|	Balance.Currency AS Currency,
		|	Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.DebtLocalBalance AS CourseIsDifferentLocal,
		|	Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.DebtLocalBalance AS RemainderOfLocal,
		|	Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.ARAPManBalance AS CourseIsDifferentMan,
		|	Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.ARAPManBalance AS BalanceMan,
		|
		|	Balance.PrepaymentBalance AS PrepaymentBalance,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.PrepaymentLocalBalance AS PrepaymentCourseIsDifferentLocal,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS PrepaymentBalanceLocalSettlement,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS PrepaymentBalanceLocal,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.PrepaymentManBalance AS PrepaymentCourseDifferentMen,
		|	Balance.PrepaymentBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS PrepaymentBalanceManSettlement,
		|	Balance.PrepaymentManBalance AS PrepaymentBalanceMan,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Dimension.Organization AS Organization,
		|	Balance.SalesOrder AS Object,
		|	Balance.ARAPDocument AS ARAPDocument,
		|	UNDEFINED AS PlannedRepaymentDate,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
		|		&BorderEndOfPeriod,
		|		(Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTPartnerAnalyticsKeys AS Dimension
		|	ON Balance.AccountingDimensionByPartners = Dimension.DimensionKey
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	CAST(Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.ARAPManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.ARAPManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.DebtLocalBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DebtBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.DebtLocalBalance AS NUMBER(31,2)) < -0.01
		|	OR (Balance.DebtBalance = 0 AND (Balance.DebtLocalBalance <> 0 OR Balance.ARAPManBalance <> 0))
		|	OR (Balance.PrepaymentBalance = 0 AND Balance.ForReturnBalance = 0 AND (Balance.PrepaymentLocalBalance <> 0 OR Balance.PrepaymentManBalance <> 0))";
	EndIf;
	#EndRegion
	
	#Region VendorsARAPAccountingByDueDates
	If RegistersForCalculation.Property("VendorsARAPAccountingByDueDates") Then
		
		QueryTextTT = QueryTextTT + 
		"////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""VendorsARAPAccountingByDueDates""  AS AccumulationRegister,
		|	Balance.Currency                    AS Currency,
		|	Balance.DebtBalance               AS DebtBalance,
		|	Balance.ARAPManBalance            AS ARAPManBalance,
		|	Balance.DebtLocalBalance           AS DebtLocalBalance,
		|	Balance.PrepaymentBalance         AS PrepaymentBalance,
		|	Balance.PrepaymentManBalance      AS PrepaymentManBalance,
		|	Balance.PrepaymentLocalBalance     AS PrepaymentLocalBalance,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Dimension.Organization             AS Organization,
		|	Balance.ARAPObject            AS ARAPObject,
		|	Balance.ARAPDocument         AS ARAPDocument,
		|	Dimension.ContractRateOption    AS ContractRateOption,
		|	CASE 
		|		WHEN Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseNumerator,1)
		|		ELSE LocalCourse.CourseNumerator
		|	END                             AS CourseNumeratorLocal,
		|	CASE 
		|		WHEN Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseDenominator,1)
		|		ELSE LocalCourse.CourseDenominator
		|	END                             AS CourseDenominatorLocal,
		|	CASE 
		|		WHEN Balance.Currency = &CurrencyOfManAccounting
		|			AND Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseNumerator,1)
		|		ELSE ManSCourse.CourseNumerator
		|	END                             AS CourseNumeratorMan,
		|	CASE 
		|		WHEN Balance.Currency = &CurrencyOfManAccounting
		|			AND Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseDenominator,1)
		|		ELSE ManSCourse.CourseDenominator
		|	END                             AS CourseDenominatorMan
		|
		|INTO TTSettlementsWithSuppliersOnTimeBalancesWithExchangeRates
		|
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|		&BorderEndOfPeriod,
		|		(Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTPartnerAnalyticsKeys AS Dimension
		|	ON Balance.AccountingDimensionByPartners = Dimension.DimensionKey
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|
		|	LEFT JOIN TTCoursesOnContracts AS ContractCourse
		|		ON Dimension.Contract = ContractCourse.Contract
		|
		|WHERE
		|	Dimension.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
		|"
		+"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	Balance.AccumulationRegister         AS AccumulationRegister,
		|	Balance.Currency                    AS Currency,
		|	Balance.DebtBalance AS DebtBalance,
		|	Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DebtLocalBalance AS CourseIsDifferentLocal,
		|	Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal AS BalanceOfLocalCalculation,
		|	Balance.DebtLocalBalance AS RemainderOfLocal,
		|	Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.ARAPManBalance AS CourseIsDifferentMan,
		|	Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan AS BalanceOfManIsCalculated,
		|	Balance.ARAPManBalance AS BalanceMan,
		|
		|	Balance.PrepaymentBalance AS PrepaymentBalance,
		|	Balance.PrepaymentBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.PrepaymentLocalBalance AS PrepaymentCourseIsDifferentLocal,
		|	Balance.PrepaymentBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal AS PrepaymentBalanceLocalSettlement,
		|	Balance.PrepaymentLocalBalance AS PrepaymentBalanceLocal,
		|	Balance.PrepaymentBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.PrepaymentManBalance AS PrepaymentCourseDifferentMen,
		|	Balance.PrepaymentBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan AS PrepaymentBalanceManSettlement,
		|	Balance.PrepaymentManBalance AS PrepaymentBalanceMan,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Balance.Organization               AS Organization,
		|	Balance.ARAPObject            AS Object,
		|	Balance.ARAPDocument         AS ARAPDocument,
		|	UNDEFINED                      AS PlannedRepaymentDate,
		|	UNDEFINED                      AS OccurrenceDate
		|FROM
		|	TTSettlementsWithSuppliersOnTimeBalancesWithExchangeRates AS Balance
		|
		|WHERE
		|	CAST(Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.ARAPManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.ARAPManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DebtLocalBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DebtLocalBalance AS NUMBER(31,2)) < -0.01
		|	OR (Balance.DebtBalance = 0 AND (Balance.DebtLocalBalance <> 0 OR Balance.ARAPManBalance <> 0))
		|	OR (Balance.PrepaymentBalance = 0 AND (Balance.PrepaymentLocalBalance <> 0 OR Balance.PrepaymentManBalance <> 0))
		|";
		
	EndIf;
	#EndRegion
	
	#Region CustomersARAPAccountingByDueDates
	If RegistersForCalculation.Property("CustomersARAPAccountingByDueDates") Then
		
		QueryTextTT = QueryTextTT + 
		"////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""CustomersARAPAccountingByDueDates""     AS AccumulationRegister,
		|	Balance.Currency                    AS Currency,
		|	Balance.DebtBalance               AS DebtBalance,
		|	Balance.ARAPManBalance            AS ARAPManBalance,
		|	Balance.DebtLocalBalance           AS DebtLocalBalance,
		|	Balance.PrepaymentBalance         AS PrepaymentBalance,
		|	Balance.PrepaymentManBalance      AS PrepaymentManBalance,
		|	Balance.PrepaymentLocalBalance     AS PrepaymentLocalBalance,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Dimension.Organization             AS Organization,
		|	Balance.ARAPObject            AS ARAPObject,
		|	Balance.ARAPDocument         AS ARAPDocument,
		|	Dimension.ContractRateOption      AS ContractRateOption,
		|	CASE 
		|		WHEN Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseNumerator,1)
		|		ELSE LocalCourse.CourseNumerator
		|	END                             AS CourseNumeratorLocal,
		|	CASE 
		|		WHEN Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseDenominator,1)
		|		ELSE LocalCourse.CourseDenominator
		|	END                             AS CourseDenominatorLocal,
		|	CASE 
		|		WHEN Balance.Currency = &CurrencyOfManAccounting
		|			AND Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseNumerator,1)
		|		ELSE ManSCourse.CourseNumerator
		|	END                             AS CourseNumeratorMan,
		|	CASE 
		|		WHEN Balance.Currency = &CurrencyOfManAccounting
		|			AND Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseDenominator,1)
		|		ELSE ManSCourse.CourseDenominator
		|	END                             AS CourseDenominatorMan
		|
		|INTO TTSettlementsWithClientsByTimeBalancesWithExchangeRates
		|
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
		|		&BorderEndOfPeriod,
		|		(Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTPartnerAnalyticsKeys AS Dimension
		|	ON Balance.AccountingDimensionByPartners = Dimension.DimensionKey
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|
		|	LEFT JOIN TTCoursesOnContracts AS ContractCourse
		|		ON Dimension.Contract = ContractCourse.Contract
		|
		|WHERE
		|	Dimension.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
		|"
		+"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	Balance.AccumulationRegister         AS AccumulationRegister,
		|	Balance.Currency                    AS Currency,
		|	Balance.DebtBalance AS DebtBalance,
		|	Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DebtLocalBalance AS DebtRateIsDifferentLocal,
		|	Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal AS DebtBalanceLocalSettlement,
		|	Balance.DebtLocalBalance AS DebtBalanceLocal,
		|	Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.ARAPManBalance AS DebtRateIsDifferentMen,
		|	Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan AS DebtBalanceManSettlement,
		|	Balance.ARAPManBalance AS DebtBalanceMan,
		|
		|	Balance.PrepaymentBalance AS PrepaymentBalance,
		|	Balance.PrepaymentBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.PrepaymentLocalBalance AS PrepaymentCourseIsDifferentLocal,
		|	Balance.PrepaymentBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal AS PrepaymentBalanceLocalSettlement,
		|	Balance.PrepaymentLocalBalance AS PrepaymentBalanceLocal,
		|	Balance.PrepaymentBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.PrepaymentManBalance AS PrepaymentCourseDifferentMen,
		|	Balance.PrepaymentBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan AS PrepaymentBalanceManSettlement,
		|	Balance.PrepaymentManBalance AS PrepaymentBalanceMan,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Balance.Organization               AS Organization,
		|	Balance.ARAPObject            AS Object,
		|	Balance.ARAPDocument         AS ARAPDocument,
		|	UNDEFINED                      AS PlannedRepaymentDate,
		|	UNDEFINED                      AS OccurrenceDate
		|FROM
		|	TTSettlementsWithClientsByTimeBalancesWithExchangeRates AS Balance
		|
		|WHERE
		|	CAST(Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.ARAPManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.ARAPManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DebtLocalBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DebtBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DebtLocalBalance AS NUMBER(31,2)) < -0.01
		|	OR (Balance.DebtBalance = 0 AND (Balance.DebtLocalBalance <> 0 OR Balance.ARAPManBalance <> 0))
		|	OR (Balance.PrepaymentBalance = 0 AND (Balance.PrepaymentLocalBalance <> 0 OR Balance.PrepaymentManBalance <> 0))
		|";
		
	EndIf;
	#EndRegion
	
	#Region BankAccountCash
	If RegistersForCalculation.Property("BankAccountCash") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""BankAccountCash"" AS AccumulationRegister,
		|	UNDEFINED AS Currency,
		|	Balance.SumBalance AS SumBalance,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS CourseIsDifferentLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.SumComplBalance AS RemainderOfLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS CourseIsDifferentMan,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.SumManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseDifferentMen,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	UNDEFINED AS IssuancePurpose,
		|	Balance.Organization AS Organization,
		|	Balance.BankAccount AS Cash,
		|	UNDEFINED AS ARAPDocument,
		|	UNDEFINED AS PlannedRepaymentDate,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.BankAccountCash.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (BankAccount IN (&BankAccounts) OR &ForAllAccounts)
		|			AND (BankAccount.CashCurrency <> &CurrencyOfManAccounting
		|				OR BankAccount.CashCurrency <> Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.BankAccount.CashCurrency = LocalCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) < -0.01
		|	OR (Balance.SumBalance = 0 AND (Balance.SumComplBalance <> 0 OR Balance.SumManBalance <> 0))";
	EndIf;
	#EndRegion
	
	#Region CashAccountBalance
	If RegistersForCalculation.Property("CashAccountBalance") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""CashAccountBalance"" AS AccumulationRegister,
		|	UNDEFINED AS Currency,
		|	Balance.SumBalance AS SumBalance,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS CourseIsDifferentLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.SumComplBalance AS RemainderOfLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS CourseIsDifferentMan,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.SumManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseDifferentMen,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	UNDEFINED AS IssuancePurpose,
		|	Balance.Organization AS Organization,
		|	Balance.CashAccount AS Cash,
		|	UNDEFINED AS ARAPDocument,
		|	UNDEFINED AS PlannedRepaymentDate,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.CashAccountBalance.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (CashAccount IN (&CashAccounts) OR &ForAllSalesRegisters)
		|			AND (CashAccount.CashCurrency <> &CurrencyOfManAccounting
		|				OR CashAccount.CashCurrency <> Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.CashAccount.CashCurrency = LocalCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) < -0.01
		|	OR (Balance.SumBalance = 0 AND (Balance.SumComplBalance <> 0 OR Balance.SumManBalance <> 0))";
	EndIf;
	#EndRegion
	
	#Region CashInCashRegistersCR
	If RegistersForCalculation.Property("CashInCashRegistersCR") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""CashInCashRegistersCR"" AS AccumulationRegister,
		|	UNDEFINED AS Currency,
		|	Balance.SumBalance AS SumBalance,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS CourseIsDifferentLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.SumComplBalance AS RemainderOfLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS CourseIsDifferentMan,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.SumManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseDifferentMen,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	UNDEFINED AS IssuancePurpose,
		|	Balance.Organization AS Organization,
		|	Balance.CashRegister AS Cash,
		|	UNDEFINED AS ARAPDocument,
		|	UNDEFINED AS PlannedRepaymentDate,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.CashInCashRegistersCR.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (CashRegister IN (&CashRegisters) OR &ForAllCashRegisterSalesRegisters)
		|			AND (CashRegister.CashCurrency <> &CurrencyOfManAccounting
		|				OR CashRegister.CashCurrency <> Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.CashRegister.CashCurrency = LocalCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) < -0.01
		|	OR (Balance.SumBalance = 0 AND (Balance.SumComplBalance <> 0 OR Balance.SumManBalance <> 0))";
	EndIf;
	#EndRegion
	
	#Region AdvanceHolderCash
	If RegistersForCalculation.Property("AdvanceHolderCash") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""AdvanceHolderCash"" AS AccumulationRegister,
		|	Balance.Currency AS Currency,
		|	Balance.SumBalance AS SumBalance,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS CourseIsDifferentLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.SumComplBalance AS RemainderOfLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS CourseIsDifferentMan,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.SumManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseDifferentMen,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	Balance.IssuancePurpose AS IssuancePurpose,
		|	Balance.Organization AS Organization,
		|	Balance.AdvanceHolder AS Cash,
		|	Balance.Department AS ARAPDocument,
		|	UNDEFINED AS PlannedRepaymentDate,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.AdvanceHolderCash.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (AdvanceHolder IN (&Persons) OR &ForAllIndividuals)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	Balance.SumBalance < 0
		|	AND (CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) < -0.01)
		|	OR (Balance.SumBalance = 0 AND (Balance.SumComplBalance <> 0 OR Balance.SumManBalance <> 0))";
	EndIf;
	#EndRegion
	
	#Region FinancialInstrumentsARAP
	If RegistersForCalculation.Property("FinancialInstrumentsARAP") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""FinancialInstrumentsARAP"" AS AccumulationRegister,
		|	UNDEFINED AS Currency,
		|	Balance.SumBalance AS SumBalance,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS CourseIsDifferentLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.SumComplBalance AS RemainderOfLocal,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS CourseIsDifferentMan,
		|	Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.SumManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseDifferentMen,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Dimension.Organization AS Organization,
		|	Balance.Contract AS Contract,
		|	Balance.AmountType AS AmountType,
		|	UNDEFINED AS PlannedRepaymentDate,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
		|		&BorderEndOfPeriod,
		|		(AmountType IN (&TypesOfAmounts) OR &ForAllTypesOfAmounts)
		|		AND (Contract.ARAPCurrency <> &CurrencyOfManAccounting
		|				OR Contract.ARAPCurrency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTPartnerAnalyticsKeys AS Dimension
		|	ON Balance.AccountingDimensionByPartners = Dimension.DimensionKey
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	(CASE
		|		WHEN Balance.Contract.ContractKind = &NatureOfLeaseContract
		|				AND NOT Balance.Contract.RecognizeLeasedAssetsInManagementAccounting
		|			THEN FALSE
		|		ELSE
		|			CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) > 0.01
		|			OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) < -0.01
		|	END
		|	OR CASE
		|		WHEN Balance.Contract.ContractKind = &NatureOfLeaseContract
		|				AND NOT Balance.Contract.RecognizeLeasedItemsInLocalAccounting
		|			THEN FALSE
		|		ELSE
		|			CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) > 0.01
		|			OR CAST(Balance.SumBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) < -0.01
		|	END)
		|	AND (Balance.AmountType IN (&DepositPayment) AND Balance.SumBalance = 0 OR Balance.AmountType NOT IN (&DepositPayment))
		|";
	EndIf;
	#EndRegion

	#Region DiscountInterestExpense
	If RegistersForCalculation.Property("DiscountInterestExpense") Then
		
		QueryTextTT = QueryTextTT + 
		"////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""DiscountInterestExpense""    AS AccumulationRegister,
		|	Balance.Currency                          AS Currency,
		|	Balance.DiscountingAmountBalance     AS DiscountingAmountBalance,
		|	Balance.DiscountingAmountManBalance  AS DiscountingAmountManBalance,
		|	Balance.DiscountingAmountComplBalance AS DiscountingAmountComplBalance,
		|	Balance.AccountingDimensionByPartners       AS AccountingDimensionByPartners,
		|	Balance.ARAPObject                  AS ARAPObject,
		|	Balance.ARAPDocument               AS ARAPDocument,
		|	Dimension.ContractRateOption          AS ContractRateOption,
		|	CASE 
		|		WHEN Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseNumerator,1)
		|		ELSE LocalCourse.CourseNumerator
		|	END                                   AS CourseNumeratorLocal,
		|	CASE 
		|		WHEN Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseDenominator,1)
		|		ELSE LocalCourse.CourseDenominator
		|	END                                   AS CourseDenominatorLocal,
		|	CASE 
		|		WHEN Balance.Currency = &CurrencyOfManAccounting
		|			AND Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseNumerator,1)
		|		ELSE ManSCourse.CourseNumerator
		|	END                                   AS CourseNumeratorMan,
		|	CASE 
		|		WHEN Balance.Currency = &CurrencyOfManAccounting
		|			AND Dimension.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseDenominator,1)
		|		ELSE ManSCourse.CourseDenominator
		|	END                                   AS CourseDenominatorMan
		|
		|INTO TTInterestExpenseOfDiscountingBalancesWithExchangeRates
		|
		|FROM
		|	AccumulationRegister.DiscountInterestExpense.Balance(
		|		&BorderEndOfPeriod,
		|		(Currency <> &CurrencyOfManAccounting OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN TTPartnerAnalyticsKeys AS Dimension
		|	ON Balance.AccountingDimensionByPartners = Dimension.DimensionKey
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Dimension.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|
		|	LEFT JOIN TTCoursesOnContracts AS ContractCourse
		|		ON Dimension.Contract = ContractCourse.Contract
		|
		|WHERE
		|	Dimension.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
		|"
		+"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") + 
		"SELECT TOP 1
		|	Balance.AccumulationRegister         AS AccumulationRegister,
		|	Balance.Currency                    AS Currency,
		|	Balance.DiscountingAmountBalance AS SumBalance,
		|	Balance.DiscountingAmountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DiscountingAmountComplBalance AS CourseIsDifferentLocal,
		|	Balance.DiscountingAmountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal AS BalanceOfLocalCalculation,
		|	Balance.DiscountingAmountComplBalance AS RemainderOfLocal,
		|	Balance.DiscountingAmountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.DiscountingAmountManBalance AS CourseIsDifferentMan,
		|	Balance.DiscountingAmountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan AS BalanceOfManIsCalculated,
		|	Balance.DiscountingAmountManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseDifferentMen,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	UNDEFINED                      AS Organization,
		|	Balance.ARAPObject            AS ARAPObject,
		|	Balance.ARAPDocument         AS ARAPDocument,
		|	UNDEFINED                      AS PlannedRepaymentDate,
		|	UNDEFINED                      AS OccurrenceDate
		|FROM
		|	TTInterestExpenseOfDiscountingBalancesWithExchangeRates AS Balance
		|
		|WHERE
		|	CAST(Balance.DiscountingAmountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.DiscountingAmountManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DiscountingAmountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.DiscountingAmountManBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.DiscountingAmountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DiscountingAmountComplBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.DiscountingAmountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.DiscountingAmountComplBalance AS NUMBER(31,2)) < -0.01
		|	OR (Balance.DiscountingAmountBalance = 0 AND (Balance.DiscountingAmountComplBalance <> 0 OR Balance.DiscountingAmountManBalance <> 0))
		|";
		
	EndIf;
	#EndRegion
	
	#Region GoodsToBeRegisteredInReportsToConsignor
	If RegistersForCalculation.Property("GoodsToBeRegisteredInReportsToConsignor") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""GoodsToBeRegisteredInReportsToConsignor"" AS AccumulationRegister,
		|	Balance.Currency AS Currency,
		|	Balance.RevenueAmountBalance AS SumBalance,
		|	Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.RevenueAmountExclVATLocalBalance AS CourseIsDifferentLocal,
		|	Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.RevenueAmountExclVATLocalBalance AS RemainderOfLocal,
		|	Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.RevenueAmountManBalance AS CourseIsDifferentMan,
		|	Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.RevenueAmountManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseDifferentMen,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Balance.Organization AS Organization,
		|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Balance.DocumentSales AS DocumentSales,
		|	Balance.CCDNumber AS CCDNumber,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting
		|				OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance
		|	INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON Balance.InventoryOwnerAttribute = InventoryKinds.Ref
		|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
		|		ON InventoryKinds.Contract = Contracts.Ref
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	ISNULL(Contracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
		|	AND (CAST(Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.RevenueAmountManBalance AS NUMBER(31,2)) > 0.01
		|		OR CAST(Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.RevenueAmountManBalance AS NUMBER(31,2)) < -0.01
		|		OR CAST(Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.RevenueAmountExclVATLocalBalance AS NUMBER(31,2)) > 0.01
		|		OR CAST(Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.RevenueAmountExclVATLocalBalance AS NUMBER(31,2)) < -0.01
		|		OR (Balance.RevenueAmountBalance = 0 AND (Balance.RevenueAmountExclVATLocalBalance <> 0 OR Balance.RevenueAmountManBalance <> 0)))";
	EndIf;
	#EndRegion
	
	#Region GoodsAndServicesToRegisterPurchasingReportsToConsignor
	If RegistersForCalculation.Property("GoodsAndServicesToRegisterPurchasingReportsToConsignor") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""GoodsAndServicesToRegisterPurchasingReportsToConsignor"" AS AccumulationRegister,
		|	Balance.Currency AS Currency,
		|	Balance.AmountIncludingVATBalance AS SumBalance,
		|	Balance.AmountIncludingVATBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS CourseIsDifferentLocal,
		|	Balance.AmountIncludingVATBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.SumComplBalance AS RemainderOfLocal,
		|	Balance.AmountIncludingVATBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS CourseIsDifferentMan,
		|	Balance.AmountIncludingVATBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.SumManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	0 AS PrepaymentCourseDifferentMen,
		|	Balance.Products AS Products,
		|	Balance.Organization AS Organization,
		|	Balance.Purpose AS Purpose,
		|	Balance.DocumentAcquisitions AS DocumentAcquisitions,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.CCDNumber AS CCDNumber
		|FROM
		|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting
		|				OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance
		|	INNER JOIN Catalog.Assignments AS Assignments
		|		ON Balance.Purpose = Assignments.Ref
		|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
		|		ON Assignments.Contract = Contracts.Ref
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	ISNULL(Contracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
		|	AND (CAST(Balance.AmountIncludingVATBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) > 0.01
		|		OR CAST(Balance.AmountIncludingVATBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.SumManBalance AS NUMBER(31,2)) < -0.01
		|		OR CAST(Balance.AmountIncludingVATBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) > 0.01
		|		OR CAST(Balance.AmountIncludingVATBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.SumComplBalance AS NUMBER(31,2)) < -0.01
		|		OR (Balance.AmountIncludingVATBalance = 0 AND (Balance.SumComplBalance <> 0 OR Balance.SumManBalance <> 0)))";
	EndIf;
	#EndRegion
	
	#Region ServicesForRegistrationOfReportsToPrincipal
	If RegistersForCalculation.Property("ServicesForRegistrationOfReportsToPrincipal") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") +
		"SELECT TOP 1
		|	""ServicesForRegistrationOfReportsToPrincipal"" AS AccumulationRegister,
		|	Balance.Currency AS Currency,
		|	Balance.RevenueAmountBalance AS SumBalance,
		|	Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.RevenueAmountExclVATLocalBalance AS CourseIsDifferentLocal,
		|	Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator AS BalanceOfLocalCalculation,
		|	Balance.RevenueAmountExclVATLocalBalance AS RemainderOfLocal,
		|	Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.RevenueAmountManBalance AS CourseIsDifferentMan,
		|	Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator AS BalanceOfManIsCalculated,
		|	Balance.RevenueAmountManBalance AS BalanceMan,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	0 AS PrepaymentCourseDifferentMen,
		|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Balance.Organization AS Organization,
		|	Balance.Terms AS Terms,
		|	Balance.DocumentSales AS DocumentSales,
		|	UNDEFINED AS PlannedRepaymentDate,
		|	UNDEFINED AS OccurrenceDate
		|FROM
		|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting
		|				OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance
		|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
		|		ON Balance.Terms = Terms1.Ref
		|
		|	INNER JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	INNER JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|WHERE
		|	ISNULL(Terms1.RevalueServicesForConsignmentNotification, FALSE)
		|	AND (CAST(Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.RevenueAmountManBalance AS NUMBER(31,2)) > 0.01
		|		OR CAST(Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator * ManSCourse.CourseDenominator / ManSCourse.CourseNumerator - Balance.RevenueAmountManBalance AS NUMBER(31,2)) < -0.01
		|		OR CAST(Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.RevenueAmountExclVATLocalBalance AS NUMBER(31,2)) > 0.01
		|		OR CAST(Balance.RevenueAmountBalance * LocalCourse.CourseNumerator / LocalCourse.CourseDenominator - Balance.RevenueAmountExclVATLocalBalance AS NUMBER(31,2)) < -0.01
		|		OR (Balance.RevenueAmountBalance = 0 AND (Balance.RevenueAmountExclVATLocalBalance <> 0 OR Balance.RevenueAmountManBalance <> 0)))";
	EndIf;
	#EndRegion
	#Region InvestmentInRent
	If RegistersForCalculation.Property("InvestmentInRent") Then
		
		QueryTextTT = QueryTextTT + 
		"////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""InvestmentInRent""                   AS AccumulationRegister,
		|	Balance.Currency                          AS Currency,
		|	Balance.RentalPaymentsBalance          AS RentalPaymentsBalance,
		|	Balance.RentalPaymentsManagBalance       AS RentalPaymentsManagBalance,
		|	Balance.RentalPaymentsLocalBalance      AS RentalPaymentsLocalBalance,
		|	Balance.InterestDiscountBalance        AS InterestDiscountBalance,
		|	Balance.InterestDiscountManBalance     AS InterestDiscountManBalance,
		|	Balance.InterestDiscountLocalBalance    AS InterestDiscountLocalBalance,
		|	Balance.Organization                     AS Organization,
		|	Balance.Contract                         AS Contract,
		|	Balance.FixedAsset                AS FixedAsset,
		|	Balance.FinancialAccountingGroup          AS FinancialAccountingGroup,
		|	Contracts.ContractRateOption           AS ContractRateOption,
		|	CASE 
		|		WHEN Contracts.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseNumerator,1)
		|		ELSE LocalCourse.CourseNumerator
		|	END                                   AS CourseNumeratorLocal,
		|	CASE 
		|		WHEN Contracts.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseDenominator,1)
		|		ELSE LocalCourse.CourseDenominator
		|	END                                   AS CourseDenominatorLocal,
		|	CASE 
		|		WHEN Balance.Currency = &CurrencyOfManAccounting
		|			AND Contracts.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseNumerator,1)
		|		ELSE ManSCourse.CourseNumerator
		|	END                                   AS CourseNumeratorMan,
		|	CASE 
		|		WHEN Balance.Currency = &CurrencyOfManAccounting
		|			AND Contracts.ContractRateOption 
		|				= VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		THEN ISNULL(ContractCourse.CourseDenominator,1)
		|		ELSE ManSCourse.CourseDenominator
		|	END                                   AS CourseDenominatorMan
		|
		|INTO TTInvestmentInRentBalancesWithExchangeRates
		|
		|FROM
		|	AccumulationRegister.InvestmentInRent.Balance(
		|		&BorderEndOfPeriod,
		|		(Organization IN (&Organization) OR &AllCompanies)
		|			AND (Currency <> &CurrencyOfManAccounting OR Currency <> Organization.LocalAccountingCurrency)
		|	) AS Balance
		|
		|	INNER JOIN Catalog.CounterpartyContracts AS Contracts
		|	ON Balance.Contract = Contracts.Ref
		|
		|	LEFT JOIN TTCourses AS LocalCourse
		|	ON Balance.Currency = LocalCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|
		|	LEFT JOIN TTCourses AS ManSCourse
		|	ON &CurrencyOfManAccounting = ManSCourse.Currency
		|		AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|
		|	LEFT JOIN TTCoursesOnContracts AS ContractCourse
		|		ON Balance.Contract = ContractCourse.Contract
		|
		|WHERE
		|	Contracts.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
		|"
		+"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") + 
		"SELECT TOP 1
		|	Balance.AccumulationRegister         AS AccumulationRegister,
		|	Balance.Currency                    AS Currency,
		|	Balance.RentalPaymentsBalance AS RentalPaymentsBalance,
		|	Balance.RentalPaymentsBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.RentalPaymentsLocalBalance AS RentalPaymentsRateIsDifferentLocal,
		|	Balance.RentalPaymentsBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal AS LeasePaymentsBalanceOfLocalSettlement,
		|	Balance.RentalPaymentsLocalBalance AS LeasePaymentsBalanceLocal,
		|	Balance.RentalPaymentsBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.RentalPaymentsManagBalance AS RentalPaymentsRateDifferentMen,
		|	Balance.RentalPaymentsBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan AS LeasePaymentsBalanceOfManSettlement,
		|	Balance.RentalPaymentsManagBalance AS LeasePaymentsBalanceOfMan,
		|	
		|	Balance.InterestDiscountBalance AS InterestDiscountBalance,
		|	Balance.InterestDiscountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.InterestDiscountLocalBalance AS PercentageDiscountRateIsDifferentLocal,
		|	Balance.InterestDiscountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal AS PercentageDiscountBalanceLocalCalculation,
		|	Balance.InterestDiscountLocalBalance AS InterestDiscountBalanceLocal,
		|	Balance.InterestDiscountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.InterestDiscountManBalance AS PercentageDiscountRateIsDifferentMan,
		|	Balance.InterestDiscountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan AS PercentageDiscountBalanceManCalculation,
		|	Balance.InterestDiscountManBalance AS InterestDiscountBalanceMan,
		|	Balance.FinancialAccountingGroup    AS FinancialAccountingGroup,
		|	Balance.Organization               AS Organization,
		|	Balance.FixedAsset          AS FixedAsset,
		|	Balance.Contract                   AS Contract,
		|	UNDEFINED                      AS PlannedRepaymentDate,
		|	UNDEFINED                      AS OccurrenceDate
		|FROM
		|	TTInvestmentInRentBalancesWithExchangeRates AS Balance
		|
		|WHERE
		|	CAST(Balance.RentalPaymentsBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.RentalPaymentsManagBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.RentalPaymentsBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.RentalPaymentsManagBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.RentalPaymentsBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.RentalPaymentsLocalBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.RentalPaymentsBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.RentalPaymentsLocalBalance AS NUMBER(31,2)) < -0.01
		|
		|	OR CAST(Balance.InterestDiscountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.InterestDiscountLocalBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.InterestDiscountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal - Balance.InterestDiscountLocalBalance AS NUMBER(31,2)) < -0.01
		|	OR CAST(Balance.InterestDiscountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.InterestDiscountManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.InterestDiscountBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.InterestDiscountManBalance AS NUMBER(31,2)) < -0.01
		|";
		
	EndIf;
	#EndRegion
	//++ WE
	#Region PayrollAccountsPayable
	If RegistersForCalculation.Property("PayrollCalculationsHR") Then
		
		QueryTextTT = QueryTextTT + 
		"SELECT
		|	""PayrollCalculationsHR""                AS AccumulationRegister,
		|	Companies.LocalAccountingCurrency AS Currency,
		|	Balance.SumBalance                       AS SumBalance,
		|	Balance.SumManBalance                    AS SumManBalance,
		|	0                                          AS SumComplBalance,
		|	Balance.Organization                        AS Organization,
		|	Balance.Individual                     AS Individual,
		|	Balance.ARAPType                        AS ARAPType,
		|	LocalCourse.CourseNumerator                     AS CourseNumeratorLocal,
		|	LocalCourse.CourseDenominator                   AS CourseDenominatorLocal,
		|	ManSCourse.CourseNumerator                      AS CourseNumeratorMan,
		|	ManSCourse.CourseDenominator                    AS CourseDenominatorMan
		|INTO TTPayrollCalculationsBalancesWithCourses
		|FROM
		|	AccumulationRegister.PayrollCalculationsHR.Balance(
		|			&BorderEndOfPeriod,
		|			Organization IN (&Organization)
		|				OR &AllCompanies) AS Balance
		|		LEFT JOIN TTCourses AS LocalCourse
		|		ON (Balance.Organization.LocalAccountingCurrency = LocalCourse.Currency)
		|			AND Balance.Organization.LocalAccountingCurrency = LocalCourse.BaseCurrency
		|		LEFT JOIN TTCourses AS ManSCourse
		|		ON (&CurrencyOfManAccounting = ManSCourse.Currency)
		|			AND Balance.Organization.LocalAccountingCurrency = ManSCourse.BaseCurrency
		|		LEFT JOIN Catalog.Companies AS Companies
		|		ON Balance.Organization = Companies.Ref"
		+"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + ?(Not IsBlankString(QueryText), Union, "") + 
		"SELECT TOP 1
		|	Balance.AccumulationRegister         AS AccumulationRegister,
		|	Balance.Currency                    AS Currency,
		|	Balance.SumBalance              AS SumBalance,
		|	0                                 AS AmountOfCourseIsDifferentLocal,
		|	0                                 AS AmountBalanceLocalCalculation,
		|	Balance.SumComplBalance          AS RemainderOfLocal,
		|	Balance.SumBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.SumManBalance AS AmountOfCourseIsDifferentMan,
		|	Balance.SumBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan AS AmountBalanceManCalculation,
		|	Balance.SumManBalance AS AmountManBalance,
		|
		|	0 AS PrepaymentBalance,
		|	0 AS PrepaymentCourseIsDifferentLocal,
		|	0 AS PrepaymentBalanceLocalSettlement,
		|	0 AS PrepaymentBalanceLocal,
		|	0 AS PrepaymentCourseDifferentMen,
		|	0 AS PrepaymentBalanceManSettlement,
		|	0 AS PrepaymentBalanceMan,
		|	UNDEFINED                      AS AccountingDimensionByPartners,
		|	Balance.Organization               AS Organization,
		|	Balance.Individual            AS Individual,
		|	Balance.ARAPType               AS ARAPType,
		|	UNDEFINED                      AS PlannedRepaymentDate,
		|	UNDEFINED                      AS OccurrenceDate
		|FROM
		|	TTPayrollCalculationsBalancesWithCourses AS Balance
		|
		|WHERE
		|	CAST(Balance.SumBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.SumManBalance AS NUMBER(31,2)) > 0.01
		|	OR CAST(Balance.SumBalance * Balance.CourseNumeratorLocal / Balance.CourseDenominatorLocal * Balance.CourseDenominatorMan / Balance.CourseNumeratorMan - Balance.SumManBalance AS NUMBER(31,2)) < -0.01
		|
		|";
		
	EndIf;
	#EndRegion
	//-- WE
	ExchangeDifferenceCalculationLocalization.SupplementVerificationRequiresReassessment(RegistersForCalculation, QueryText);
	
	QueryText = QueryTextTT + QueryText;
	If ReturnOrganizationsToReassessment Then
		QueryText = StrReplace(QueryText, "TOP 1", "DISTINCT");
	EndIf;
	Query = New Query(QueryText);
	Query.SetParameter("OnDate",              EndOfMonth(Period));
	Query.SetParameter("BorderEndOfPeriod", New Boundary(EndOfMonth(Period), BoundaryType.Including));
	Query.SetParameter("CurrencyOfManAccounting",      Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("Organization",         Organization);
	Query.SetParameter("AllCompanies",      Not ValueIsFilled(Organization));
	Query.SetParameter("AccountingDimensionByPartners", GetAnalytics("AccountingDimensionByPartners", DimensionCalculation));
	Query.SetParameter("ForAllAnalysts",    Not ValueIsFilled(Query.Parameters.AccountingDimensionByPartners));
	Query.SetParameter("BankAccounts",     GetAnalytics("BankAccounts", DimensionCalculation));
	Query.SetParameter("ForAllAccounts",        Not ValueIsFilled(Query.Parameters.BankAccounts));
	Query.SetParameter("CashAccounts",               GetAnalytics("CashAccounts", DimensionCalculation));
	Query.SetParameter("ForAllSalesRegisters",        Not ValueIsFilled(Query.Parameters.CashAccounts));
	Query.SetParameter("CashRegisters",            GetAnalytics("CashRegisters", DimensionCalculation));
	Query.SetParameter("ForAllCashRegisterSalesRegisters",     Not ValueIsFilled(Query.Parameters.CashRegisters));
	Query.SetParameter("Persons",      GetAnalytics("Persons", DimensionCalculation));
	Query.SetParameter("ForAllIndividuals",      Not ValueIsFilled(Query.Parameters.Persons));
	Query.SetParameter("TypesOfAmounts",            GetAnalytics("TypesOfAmounts", DimensionCalculation));
	Query.SetParameter("ForAllTypesOfAmounts",     Not ValueIsFilled(Query.Parameters.TypesOfAmounts));
	
	Query.SetParameter("NatureOfLeaseContract", Enums.ContractKindsOfFinancialInstruments.Lease);
	Query.SetParameter("DepositPayment", Undefined);
	Query.SetParameter("DepositPayment", Enums.TypesOfLeasePayments.DepositPayment);
	If ForDebugging <> Undefined Then
		ForDebugging.Insert("ReEvaluationRequired", Query);
	EndIf;
	
	QueryResult = Query.Execute();
	If ReturnOrganizationsToReassessment Then
		ExchangeRateDifferences = QueryResult.Unload();// uncalculated exchange differences
		ExchangeRateDifferences.GroupBy("Organization");
		Companies = ExchangeRateDifferences.UnloadColumn("Organization");
		Return Companies;
	EndIf;
	Return Not QueryResult.IsEmpty();
	
EndFunction

// A reassessment of mutual settlements is required.
// 
// Parameters:
//  Organization - CatalogRef.Companies, Array of CatalogRef.Companies - 
//  Period - Date - Date of the month of revaluation
//  DimensionCalculation - Undefined - Calculation Analytics
// 
// Returns:
//  Boolean, Array of CatalogRef.Companies - Requires Reassessment Of Settlements
Function RequiresReassessmentOfSettlements(Organization, Period, DimensionCalculation = Undefined) Export
	
	RegistersForCalculation = New Structure;
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		RegistersForCalculation.Insert("VendorsARAPAccountingByDocuments");
		RegistersForCalculation.Insert("CustomersARAPAccountingByDocuments");
	Else
		RegistersForCalculation.Insert("VendorsARAPAccountingByDueDates");
		RegistersForCalculation.Insert("CustomersARAPAccountingByDueDates");
	EndIf;
	
	Return ReEvaluationRequired(Organization, Period, RegistersForCalculation, DimensionCalculation);
	
EndFunction

Procedure DeleteAnalyticsRegisteredRecords(DocumentRef, RegisterName, DimensionCalculation)
	
	Query = New Query();
	Query.SetParameter("DimensionCalculation", GetAnalytics("CashAccounts", DimensionCalculation));
	QueryText = 
	"SELECT
	|	*
	|FROM
	|	AccumulationRegister.CashAccountBalance AS RegisterData
	|WHERE
	|	RegisterData.Recorder = &Recorder
	|	AND NOT (RegisterData.CashAccount IN (&DimensionCalculation))
	|	AND &EverythingExceptAnalytics";
	
	QueryText = StrReplace(QueryText, "CashAccountBalance", RegisterName);
	AccountingDimensionByPartners = GetAnalytics("AccountingDimensionByPartners", DimensionCalculation);
	TypesOfAmounts = GetAnalytics("TypesOfAmounts", DimensionCalculation);
	If RegisterName = "CustomersARAPAccountingByDocuments" Or RegisterName = "VendorsARAPAccountingByDocuments" Then
		QueryText = StrReplace(QueryText, "CashAccount", "AccountingDimensionByPartners");
		Query.SetParameter("DimensionCalculation", AccountingDimensionByPartners);
		
	ElsIf RegisterName = "FinancialInstrumentsARAP" Then
		If ValueIsFilled(AccountingDimensionByPartners) Then
			QueryText = StrReplace(QueryText, "CashAccount", "AccountingDimensionByPartners");
			Query.SetParameter("DimensionCalculation", AccountingDimensionByPartners);
			If ValueIsFilled(TypesOfAmounts) Then
				QueryText = StrReplace(
									QueryText, 
									"&EverythingExceptAnalytics", 
									"&EverythingExceptAnalytics
									|	AND NOT (RegisterData.AmountType IN (&TypesOfAmounts))");
				Query.SetParameter("TypesOfAmounts", TypesOfAmounts);
			EndIf;
		Else
			QueryText = StrReplace(QueryText, "CashAccount", "AmountType");
			Query.SetParameter("DimensionCalculation", TypesOfAmounts);
		EndIf;
		
	ElsIf RegisterName = "BankAccountCash" Then
		QueryText = StrReplace(QueryText, "CashAccount", "BankAccount");
		Query.SetParameter("DimensionCalculation", GetAnalytics("CompaniesBankAccounts", DimensionCalculation));
		
	ElsIf RegisterName = "CashInCashRegistersCR" Then
		QueryText = StrReplace(QueryText, "CashAccount", "CashRegister");
		Query.SetParameter("DimensionCalculation", GetAnalytics("CashRegisters", DimensionCalculation));
		
	ElsIf RegisterName = "CashInTransit" Then
		QueryText = StrReplace(QueryText, "CashAccount", "Recipient");
		Query.SetParameter("DimensionCalculation", GetAnalytics("CompaniesBankAccounts,CashAccounts,CashRegisters", DimensionCalculation));
		
	ElsIf RegisterName = "AdvanceHolderCash" Then
		QueryText = StrReplace(QueryText, "CashAccount", "AdvanceHolder");
		Query.SetParameter("DimensionCalculation", GetAnalytics("Persons", DimensionCalculation));
	EndIf;
	
	ExchangeDifferenceCalculationLocalization.ReplaceQueryCleaningWithAnalytics(RegisterName, QueryText);
	
	// We will get a new set of movements - a set without movements that need to be deleted
	Query.Text = QueryText;
	Query.SetParameter("Recorder", DocumentRef);
	Query.SetParameter("EverythingExceptAnalytics", ValueIsFilled(Query.Parameters.DimensionCalculation));
	RegisterRegisteredRecords_ = Query.Execute().Unload();
	
	Set = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet - 
	Set.Filter.Recorder.Set(DocumentRef);
	Set.Load(RegisterRegisteredRecords_);
	Set.DataExchange.Load = True;
	Set.Write();
	
EndProcedure

Procedure PrepareRecordSetsForCalculation(DocumentRef, RegistersForCalculation, DimensionCalculation)
	
	Block = New DataLock;
	LockItem = Block.Add("Document.ExchangeDifferenceCalculation");
	LockItem.Mode = DataLockMode.Shared;
	For Each Register In RegistersForCalculation Do
		If Register.Key = "CustomersARAPAccountingByDueDates" Or Register.Key = "VendorsARAPAccountingByDueDates" Then
			Continue;
		EndIf;
		LockItem = Block.Add(StrTemplate("AccumulationRegister.%1.RecordSet", Register.Key));
		LockItem.SetValue("Recorder", DocumentRef);
	EndDo;
	Block.Lock();
	
	For Each Register In RegistersForCalculation Do
		If Register.Key = "CustomersARAPAccountingByDueDates" Or Register.Key = "VendorsARAPAccountingByDueDates" Then
			Continue;
		EndIf;
		If DimensionCalculation = Undefined Then
			Set = AccumulationRegisters[Register.Key].CreateRecordSet(); // AccumulationRegisterRecordSet -
			Set.Filter.Recorder.Set(DocumentRef);
			Set.DataExchange.Load = True;
			Set.Write();
		Else
			DeleteAnalyticsRegisteredRecords(DocumentRef, Register.Key, DimensionCalculation);
		EndIf;
	EndDo;
	
EndProcedure

//Deletes the entries at the field Documentpaginator in the register accumulating Resetaccountstat, Reshetilovskaya
//
// Parameters:
//  DocumentRecorder - DocumentRef - Document reference for which you want to delete the records in the accumulation register
//  RegisterName - String - Name of the accumulation register. Values can be Resetaccountstat, Reshetilovskaya
//
Procedure DeleteRegisterRegisteredRecordsByTimeFrame(DocumentRecorder, RegisterName) Export
	
	QueryText = 
	"SELECT
	|	CalculationsByTerms.Recorder AS Ref
	|INTO TTRecorders_
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|WHERE
	|	CalculationsByTerms.DocumentRecorder = &DocumentRecorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|	INNER JOIN TTRecorders_ AS CalculationLoggers
	|	ON CalculationsByTerms.Recorder = CalculationLoggers.Ref
	|WHERE
	|	CalculationsByTerms.DocumentRecorder <> &DocumentRecorder
	|TOTALS BY
	|	Recorder";
	QueryText = StrReplace(QueryText, "CustomersARAPAccountingByDueDates", RegisterName);
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentRecorder", DocumentRecorder);
	
	SelectionByDocuments = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionByDocuments.Next() Do
		Set = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet - 
		Set.Filter.Recorder.Set(SelectionByDocuments.Recorder);
		Selection = SelectionByDocuments.Select();
		While Selection.Next() Do
			NewRecord = Set.Add();
			FillPropertyValues(NewRecord, Selection);
		EndDo;
		Set.Write();
	EndDo;
	
EndProcedure

Function GetCatalogLinks(CatalogName, ReferencesArrray, Organization = Undefined)
	
	QueryText = 
	"SELECT
	|	Cat.Ref
	|FROM
	|	Catalog.Companies AS Cat
	|WHERE
	|	Cat.Ref IN(&ReferencesArrray)
	|	AND TRUE";
	QueryText = StrReplace(QueryText, "Companies", CatalogName);
	If ValueIsFilled(Organization) Then
		QueryText = StrReplace(QueryText, "TRUE", "Cat.Organization = &Organization");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ReferencesArrray", ?(ReferencesArrray = Undefined, New Array, ReferencesArrray));
	ArrayOfOrganizationKeys = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return ArrayOfOrganizationKeys;
	
EndFunction

Function GetAnalytics(NameOfAnalytics, DimensionCalculation)
	
	Result = Undefined;
	If TypeOf(DimensionCalculation) = Type("Structure") Then
		DimensionCalculation.Property(NameOfAnalytics, Result);
	EndIf;
	Return Result;
	
EndFunction

Function RequestPacketSeparator()
	
	Return "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function TypesOfAmountsOfLoansDepositsLoans()
	Result = New Array;
	For Indus = 0 To Metadata.Enums.LoanAndDepositScheduleAmountTypes.EnumValues.Count() - 1 Do
		Result.Add(Enums.LoanAndDepositScheduleAmountTypes[Indus]);
	EndDo;
	Return Result;
EndFunction
Function TypesOfAmountsOfReverseReflectionOfExpenses()
	
	Result = New Array();
	Result.Add(Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	Result.Add(Enums.TypesOfLeasePayments.DepositPayment);
	Result.Add(Enums.TypesOfLeasePayments.RentalServicePrepayment);
	Result.Add(Enums.TypesOfLeasePayments.Interests);
	Result.Add(Enums.TypesOfLeasePayments.VAT);
	Return Result;
	
EndFunction

Function TypesOfRentalPaymentAmounts()
	
	Result = New Array();
	Result.Add(Enums.TypesOfLeasePayments.BuyoutValue);
	Result.Add(Enums.TypesOfLeasePayments.RentalService);
	Return Result;
	
EndFunction

Function TypesOfLeasePaymentAmounts()
	Result = New Array;
	For Indus = 0 To Metadata.Enums.TypesOfLeasePayments.EnumValues.Count() - 1 Do
		Result.Add(Enums.TypesOfLeasePayments[Indus]);
	EndDo;
	Return Result;
EndFunction
#EndRegion

#EndRegion

#EndIf
