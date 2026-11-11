#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Adds a command for creating the "loan / Deposit Agreements"directory.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	
	CatalogMetadata = Metadata.Catalogs.LoanAndDepositContracts;
	
	If AccessRight("Insert", CatalogMetadata) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = CatalogMetadata.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(CatalogMetadata);
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);	
	
EndProcedure

// By the nature of the contract determines the type of item (income or expenses)
//
// Parameters:
//  ContractKind - EnumRef.ContractKindsOfFinancialInstruments - the nature of the loan agreement, deposit, loan.
//
// Returns:
//  String - "expenses" or "income".
//
Function ArticleType(ContractKind) Export
	
	Return ?(ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing,NStr("vi = 'chi phí';
																							|ru = 'расходов';
																							|en = 'expenses'; fa = 'expenses';
																							|it = 'dei costi';
																							|pl = 'expenses';
																							|tr = 'giderlerin'"),NStr("vi = 'thu nhập';
																													|ru = 'доходов';
																													|en = 'income'; fa = 'income';
																													|it = 'dei ricavi';
																													|pl = 'income';
																													|tr = 'gelirlerin'"));
	
EndFunction

// For a business transaction, it determines the nature of the loan agreement, Deposit, or loan.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - business transaction for which it is necessary to determine
//                                                               the nature of the contract.
//
// Returns:
//   EnumRef.ContractKindsOfFinancialInstruments - the nature of the loan agreement, deposit, loan.
//
Function NatureOfTransactionAgreement(BusinessOperation) Export
	
	BsnsTransactions = Enums.BusinessTransactions;
	NatureOfContracts = Enums.ContractKindsOfFinancialInstruments;
	Result = Undefined;
	If BusinessOperation = BsnsTransactions.LoansInterestCharge
		Or BusinessOperation = BsnsTransactions.CashReceiptFromLoansRepayment
		Or BusinessOperation = BsnsTransactions.PaymentOnLoansAndBorrowingsReceived Then
		Result = NatureOfContracts.LoanOrBorrowing;
		
	ElsIf BusinessOperation = BsnsTransactions.DepositInterestCharge 
		Or BusinessOperation = BsnsTransactions.CashReceiptUnderDeposits
		Or BusinessOperation = BsnsTransactions.TransferToDeposits Then
		Result = NatureOfContracts.Deposit;
		
	ElsIf BusinessOperation = BsnsTransactions.IssuedBorrowingsInterestCharge
		Or BusinessOperation = BsnsTransactions.CashReceiptBorrowingsProvidedToCounterparty
		Or BusinessOperation = BsnsTransactions.CashIssueAsLoanToCounterparty Then
		Result = NatureOfContracts.IssuedBorrowing;
		
	EndIf;
	Return Result;
	
EndFunction

// By the nature of the loan agreement, Deposit, loan determines the business operation.
//
// Parameters:
//  ContractKind - EnumRef.ContractKindsOfFinancialInstruments - the nature of the loan agreement, Deposit, loan for
//      which it is necessary to determine the business transaction.
//  ThisIsAdmissionDocument_ - Boolean - direction of cash flow.
//
// Returns:
//   EnumRef.BusinessTransactions - economic operation.
//
Function OperationByNatureOfContract(ContractKind, ThisIsAdmissionDocument_ = False) Export
	
	Result = Undefined;
	BsnsTransactions = Enums.BusinessTransactions;
	NatureOfContracts = Enums.ContractKindsOfFinancialInstruments;
	If ContractKind = NatureOfContracts.LoanOrBorrowing Then
		Result = ?(ThisIsAdmissionDocument_, BsnsTransactions.CashReceiptFromLoansRepayment, BsnsTransactions.PaymentOnLoansAndBorrowingsReceived);
		
	ElsIf ContractKind = NatureOfContracts.Deposit Then
		Result = ?(ThisIsAdmissionDocument_, BsnsTransactions.CashReceiptUnderDeposits, BsnsTransactions.TransferToDeposits);
		
	ElsIf ContractKind = NatureOfContracts.IssuedBorrowing Then
		Result = ?(ThisIsAdmissionDocument_, BsnsTransactions.CashReceiptBorrowingsProvidedToCounterparty, BsnsTransactions.CashIssueAsLoanToCounterparty);
		
	EndIf;
	Return Result;
	
EndFunction

// Prepares data for filling in cash flow documents based on a loan agreement, Deposit, or loan.
//
// Parameters:
//  LoanDepositContract - CatalogRef.LoanAndDepositContracts - The contract on the basis of which
//                                                                         the payment document is entered.
//  ThisIsAdmissionDocument_ - Boolean - direction of cash flow.
//
// Returns:
//   Structure - data for filling out the payment document.
//
Function DataForFillingInDDSDocument(LoanDepositContract, ThisIsAdmissionDocument_ = False) Export
	
	FillingData = DataForHeaderOfDDSDocument(LoanDepositContract, ThisIsAdmissionDocument_);
	
	ARAPDetails = PaymentDecryptionDataOfDDSDocument(LoanDepositContract, ThisIsAdmissionDocument_);
	If ARAPDetails.Count() > 0 Then
		FillingData.CounterpartyBankAccount = ARAPDetails[0].CounterpartyBankAccount;
	EndIf;
	FillingData.Insert("ARAPDetails",ARAPDetails);
	
	Return FillingData;
	
EndFunction

// The function gets an array of existing contracts with the counterparty based on the specified parameters.
//
// Parameters:
//	Organization - CatalogRef.Companies - The organization on whose behalf the contract was concluded with the counterparty.
//	Counterparty - CatalogRef.Counterparties - the counterparty with whom the contract is concluded.
//	ContractKind - EnumRef.ContractKindsOfFinancialInstruments - nature of the agreement.
//
// Returns:
//	Array - array of contracts.
//
Function CurrentContractsForCounterparty(Organization, Counterparty, ContractKind) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	LoanAndDepositContracts.Ref AS Contract
	|FROM
	|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|WHERE
	|	LoanAndDepositContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND LoanAndDepositContracts.Organization = &Organization
	|	AND LoanAndDepositContracts.Counterparty = &Counterparty
	|	AND LoanAndDepositContracts.ContractKind = &ContractKind";
	
	Query.SetParameter("Counterparty",        Counterparty);
	Query.SetParameter("Organization",       Organization);
	Query.SetParameter("ContractKind",  ContractKind);
	
	ArrayOfContracts = New Array;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ArrayOfContracts.Add(Selection.Contract);
	EndDo;
	
	Return ArrayOfContracts;
	
EndFunction

// The function returns a table of payment decryption for the loan / Deposit agreement.
//
// Parameters:
//	LoanDepositContract - CatalogRef.LoanAndDepositContracts - The contract that you want to get the data for.
//	ThisIsAdmissionDocument_ - Boolean - A sign that determines the direction of cash flow: payment or receipt.
//	DocumentException - DocumentRef.CashVoucher,
//                       Document link.Write-offsreferencesexternal links,
//                       Document link.Prednisolone,
//                       Document link.Receipt of non-cash monetary funds - a Document whose movements should be excluded.
//
// Returns:
//	ValueTable - Decryption of the payment.
//
Function PaymentDecryptionDataOfDDSDocument(LoanDepositContract, ThisIsAdmissionDocument_ = False, DocumentException = Undefined) Export
	
	AttributesList = "ARAPCurrency,ForeignCurrencyTransaction,PaymentMethod,CashAccount,BankAccount,Organization, ContractKind";
	Attributes = Common.ObjectAttributesValues(LoanDepositContract,AttributesList);
	DocumentCurrency = Attributes.ARAPCurrency;
	If Not Attributes.ForeignCurrencyTransaction Then
		DocumentCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization);
	ElsIf Attributes.ForeignCurrencyTransaction Then
		If Attributes.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
			DocumentCurrency = Common.ObjectAttributeValue(Attributes.CashAccount,"CashCurrency");
		Else
			DocumentCurrency = Common.ObjectAttributeValue(Attributes.BankAccount,"CashCurrency");
		EndIf;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Attributes.ARAPCurrency,
		DocumentCurrency,
		CurrentSessionDate(),
		Attributes.Organization);
	
	QueryText = 
	"SELECT
	|	LoanAndDepositContracts.Ref AS LoanDepositContract,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.CashFlowItemOfReceiptIssuie AS CashFlowItem,
	|	LoanAndDepositContracts.Department,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Tranches) AS ScheduleType,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS AmountType,
	|	SUM(ScheduleOfTrancheForLoansAndDeposits.Sum) AS GraphAmount,
	|	LoanAndDepositContracts.CounterpartyBankAccount
	|INTO TTChartData
	|FROM
	|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|		INNER JOIN InformationRegister.ScheduleOfTrancheForLoansAndDeposits AS ScheduleOfTrancheForLoansAndDeposits
	|		ON LoanAndDepositContracts.Ref = ScheduleOfTrancheForLoansAndDeposits.ScheduleOption.Owner
	|WHERE
	|	ScheduleOfTrancheForLoansAndDeposits.ScheduleOption = &ScheduleOption
	|	AND ScheduleOfTrancheForLoansAndDeposits.Period <= &OnDate
	|	AND &Tranches
	|	AND ScheduleOfTrancheForLoansAndDeposits.Sum > 0
	|
	|GROUP BY
	|	LoanAndDepositContracts.Ref,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.CashFlowItemOfReceiptIssuie,
	|	LoanAndDepositContracts.Department,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	LoanAndDepositContracts.CounterpartyBankAccount
	|
	|UNION ALL
	|
	|SELECT
	|	LoanAndDepositContracts.Ref,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.CashFlowItemOfPrincipalDebt,
	|	LoanAndDepositContracts.Department,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Payments),
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt),
	|	SUM(ScheduleOfPaymentForLoansAndDeposits.Sum),
	|	LoanAndDepositContracts.CounterpartyBankAccount
	|FROM
	|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|		INNER JOIN InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS ScheduleOfPaymentForLoansAndDeposits
	|		ON LoanAndDepositContracts.Ref = ScheduleOfPaymentForLoansAndDeposits.ScheduleOption.Owner
	|WHERE
	|	ScheduleOfPaymentForLoansAndDeposits.ScheduleOption = &ScheduleOption
	|	AND ScheduleOfPaymentForLoansAndDeposits.Period <= &OnDate
	|	AND NOT &Tranches
	|	AND ScheduleOfPaymentForLoansAndDeposits.Sum > 0
	|
	|GROUP BY
	|	LoanAndDepositContracts.Ref,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.Department,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	LoanAndDepositContracts.CashFlowItemOfPrincipalDebt,
	|	LoanAndDepositContracts.CounterpartyBankAccount
	|
	|UNION ALL
	|
	|SELECT
	|	LoanAndDepositContracts.Ref,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.CashFlowItemOfInterestPayment,
	|	LoanAndDepositContracts.Department,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Payments),
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests),
	|	SUM(ScheduleOfPaymentForLoansAndDeposits.Interests),
	|	CASE
	|		WHEN LoanAndDepositContracts.InterestBankAccount = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|			THEN LoanAndDepositContracts.CounterpartyBankAccount
	|		ELSE LoanAndDepositContracts.InterestBankAccount
	|	END
	|FROM
	|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|		INNER JOIN InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS ScheduleOfPaymentForLoansAndDeposits
	|		ON LoanAndDepositContracts.Ref = ScheduleOfPaymentForLoansAndDeposits.ScheduleOption.Owner
	|WHERE
	|	ScheduleOfPaymentForLoansAndDeposits.ScheduleOption = &ScheduleOption
	|	AND ScheduleOfPaymentForLoansAndDeposits.Period <= &OnDate
	|	AND NOT &Tranches
	|	AND ScheduleOfPaymentForLoansAndDeposits.Interests > 0
	|
	|GROUP BY
	|	LoanAndDepositContracts.Ref,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.Department,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	LoanAndDepositContracts.CashFlowItemOfInterestPayment,
	|	CASE
	|		WHEN LoanAndDepositContracts.InterestBankAccount = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|			THEN LoanAndDepositContracts.CounterpartyBankAccount
	|		ELSE LoanAndDepositContracts.InterestBankAccount
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	LoanAndDepositContracts.Ref,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.CashFlowItemOfFeePayment,
	|	LoanAndDepositContracts.Department,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Payments),
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee),
	|	SUM(ScheduleOfPaymentForLoansAndDeposits.Fee),
	|	CASE
	|		WHEN LoanAndDepositContracts.BankAccountOfFee = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|			THEN LoanAndDepositContracts.CounterpartyBankAccount
	|		ELSE LoanAndDepositContracts.BankAccountOfFee
	|	END
	|FROM
	|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|		INNER JOIN InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS ScheduleOfPaymentForLoansAndDeposits
	|		ON LoanAndDepositContracts.Ref = ScheduleOfPaymentForLoansAndDeposits.ScheduleOption.Owner
	|WHERE
	|	ScheduleOfPaymentForLoansAndDeposits.ScheduleOption = &ScheduleOption
	|	AND ScheduleOfPaymentForLoansAndDeposits.Period <= &OnDate
	|	AND NOT &Tranches
	|	AND ScheduleOfPaymentForLoansAndDeposits.Fee > 0
	|
	|GROUP BY
	|	LoanAndDepositContracts.Ref,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.Department,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	CASE
	|		WHEN LoanAndDepositContracts.BankAccountOfFee = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|			THEN LoanAndDepositContracts.CounterpartyBankAccount
	|		ELSE LoanAndDepositContracts.BankAccountOfFee
	|	END,
	|	LoanAndDepositContracts.CashFlowItemOfFeePayment
	|
	|INDEX BY
	|	LoanDepositContract,
	|	AmountType,
	|	ScheduleType,
	|	CashFlowItem
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.AmountType AS AmountType,
	|	FinancialInstrumentsARAP.ScheduleType AS ScheduleType,
	|	SUM(FinancialInstrumentsARAP.Sum) AS AmountInCurrency
	|INTO TTBalances
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS FinancialInstrumentsARAP
	|WHERE
	|	FinancialInstrumentsARAP.Period <= &OnDate
	|	AND FinancialInstrumentsARAP.Contract = &Ref
	|	AND FinancialInstrumentsARAP.ScheduleType <> VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)
	|	AND FinancialInstrumentsARAP.Recorder <> &DocumentException
	|
	|GROUP BY
	|	FinancialInstrumentsARAP.ScheduleType,
	|	FinancialInstrumentsARAP.AmountType,
	|	FinancialInstrumentsARAP.Contract
	|
	|INDEX BY
	|	Contract,
	|	AmountType,
	|	ScheduleType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractData.Ref AS LoanDepositContract,
	|	ContractData.Partner,
	|	CASE WHEN &Tranches
	|		THEN ContractData.CashFlowItemOfReceiptIssuie
	|		ELSE ContractData.CashFlowItemOfPrincipalDebt
	|	END AS CashFlowItem,
	|	ContractData.Department,
	|	ContractData.ARAPCurrency AS ARAPCurrency,
	|	ContractData.CounterpartyBankAccount,
	|	CASE WHEN &Tranches
	|		THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Tranches)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|	END ScheduleType,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS LoanAndDepositAmountType
	|FROM
	|	Catalog.LoanAndDepositContracts AS ContractData
	|WHERE
	|	ContractData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTChartData.LoanDepositContract,
	|	TTChartData.Partner,
	|	TTChartData.CashFlowItem,
	|	TTChartData.Department,
	|	TTChartData.ARAPCurrency,
	|	TTChartData.ScheduleType,
	|	TTChartData.AmountType,
	|	TTChartData.AmountType AS LoanAndDepositAmountType,
	|	TTChartData.GraphAmount,
	|	ISNULL(TTBalances.AmountInCurrency, 0) AS AmountInCurrency,
	|	TTChartData.CounterpartyBankAccount,
	|	CASE
	|		WHEN TTChartData.GraphAmount - ISNULL(TTBalances.AmountInCurrency, 0) > 0
	|			THEN (TTChartData.GraphAmount - ISNULL(TTBalances.AmountInCurrency, 0)) * &ConversionFactorToDocumentCurrency
	|		ELSE 0
	|	END AS Sum,
	|	CASE
	|		WHEN TTChartData.GraphAmount - ISNULL(TTBalances.AmountInCurrency, 0) > 0
	|			THEN TTChartData.GraphAmount - ISNULL(TTBalances.AmountInCurrency, 0)
	|		ELSE 0
	|	END AS AmountARAP
	|FROM
	|	TTChartData AS TTChartData
	|		LEFT JOIN TTBalances AS TTBalances
	|		ON TTChartData.LoanDepositContract = TTBalances.Contract
	|			AND TTChartData.AmountType = TTBalances.AmountType
	|			AND TTChartData.ScheduleType = TTBalances.ScheduleType
	|WHERE
	|	TTChartData.GraphAmount - ISNULL(TTBalances.AmountInCurrency, 0) > 0";
	
	NatureOfContracts = Enums.ContractKindsOfFinancialInstruments;
	Tranches = ThisIsAdmissionDocument_ And Attributes.ContractKind = NatureOfContracts.LoanOrBorrowing
				Or Not ThisIsAdmissionDocument_ And (Attributes.ContractKind = NatureOfContracts.IssuedBorrowing
												Or Attributes.ContractKind = NatureOfContracts.Deposit);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("OnDate", CurrentSessionDate());
	Query.SetParameter("Ref", LoanDepositContract);
	Query.SetParameter("ScheduleOption", Catalogs.OptionsOfLoansAndDepositsSchedules.CurVersionOfGraph(LoanDepositContract));
	Query.SetParameter("Tranches", Tranches);
	Query.SetParameter("ConversionFactorToDocumentCurrency", Coefficients.ConversionRateToSettlementCurrency);
	Query.SetParameter("DocumentException", DocumentException);
	
	Result = Query.ExecuteBatch();
	
	DetailsData = Result[3].Unload();// Amounts On Schedule
	If DetailsData.Count() = 0 Then
		DetailsData = Result[2].Unload();// Contract data without amounts
	EndIf;
	Return DetailsData;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("ContractKind");
	Result.Add("ContractType");
	Result.Add("Partner");
	Result.Add("Counterparty");
	Result.Add("Organization");
	Result.Add("ForeignCurrencyTransaction");
	Result.Add("ARAPCurrency");
	Result.Add("FeeType");
	
	Result.Add("Department");
	Result.Add("LineOfBusiness");
	
	Result.Add("CashFlowItemOfReceiptIssuie");
	Result.Add("CashFlowItemOfPrincipalDebt");
	Result.Add("CashFlowItemOfInterestPayment");
	Result.Add("CashFlowItemOfFeePayment");
	
	Result.Add("IncomeExpenseItemForInterestAccruals");
	Result.Add("IncomeExpenseItemForFeeAccruals");
	
	Result.Add("FinancialAccountingGroupOfCash");
	Result.Add("FinancialAccountingGroup");
	
	
	Return Result;
	
EndFunction

// The Bank account of the loan agreement, Deposit, loan returns the contract with the counterparty (organization).
//
// Parameters:
//  LoanDepositAgreement - CatalogRef.LoanAndDepositContracts - loan, Deposit, or loan agreement.
//
// Returns:
//   CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - contract with the customer.
//
Function ContractWithCustomer(LoanDepositAgreement) Export 
	ContractWithCustomer = Undefined;
	
	QueryText = "
	|SELECT
	|	LoanAndDepositContracts.BankAccount AS Ref
	|INTO BankAccounts
	|FROM
	|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|WHERE
	|	LoanAndDepositContracts.Ref = &LoanDepositAgreement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CounterpartyContracts.Ref
	|FROM
	|	BankAccounts AS BankAccounts
	|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON BankAccounts.Ref = CounterpartyContracts.BankAccount
	|WHERE
	|	CounterpartyContracts.ContractType = VALUE(Enum.ContractTypes.WithCustomer)
	|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|
	|UNION ALL
	|
	|SELECT
	|	IntercompanyContracts.Ref
	|FROM
	|	BankAccounts AS BankAccounts
	|		INNER JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
	|		ON BankAccounts.Ref = IntercompanyContracts.BankAccount
	|WHERE
	|	IntercompanyContracts.ContractType = VALUE(Enum.TypesOfIntercompanyContracts.PurchaseAndSale)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("LoanDepositAgreement", LoanDepositAgreement);
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		ContractWithCustomer = Selection.Ref;
	EndIf;
	
	Return ContractWithCustomer;
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.PartnerHierarchy AS T2 
	|	ON T2.Parent = T.Partner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T2.Partner)
	|	AND ValueAllowed(T.Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

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

// Defines the properties of form fields depending on the data
//
// Returns:
//    ValueTable - table with columns Fields, Condition, Properties.
//
Function FormFieldSettings() Export
	
	Finances = FinancialReportingServer;
	Settings = CashServer.InitializeFormFieldSettings();
	
	//
	Item = Settings.Add();
	Item.Fields.Add("BankAccount");
	Item.Fields.Add("CounterpartyBankAccount");
	Item.Fields.Add("InterestBankAccount");
	Item.Fields.Add("BankAccountOfFee");
	Finances.NewFilter(Item.Condition, "PaymentMethod", Enums.PaymentForms.BankAccountPayment);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CashAccount");
	Finances.NewFilter(Item.Condition, "PaymentMethod", Enums.PaymentForms.CashAccountPayment_);
	Item.Properties.Insert("Visible");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("Fee");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "FeeType", Enums.LoanAndDepositFeeTypes.Percent);
	Finances.NewFilter(OrGroup, "FeeType", Enums.LoanAndDepositFeeTypes.Sum);
	Item.Properties.Insert("Visible");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItemOfFeePayment");
	Item.Fields.Add("IncomeExpenseItemForFeeAccruals");
	Finances.NewFilter(Item.Condition, "FeeType", Enums.LoanAndDepositFeeTypes.None);
	Item.Properties.Insert("Visible", False);
	
	//
	Item = Settings.Add();
	Item.Fields.Add("PaymentMethod");
	Finances.NewFilter(Item.Condition, "ContractKind", Enums.ContractKindsOfFinancialInstruments.Deposit);
	Item.Properties.Insert("ReadOnly");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("FeeType");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "ContractKind", Enums.ContractKindsOfFinancialInstruments.Deposit);
	Finances.NewFilter(OrGroup, "More.FeeTypeIsLocked", True);
	Item.Properties.Insert("ReadOnly");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("FinancialAccountingGroupOfCash");
	Finances.NewFilter(Item.Condition, "ContractKind", Enums.ContractKindsOfFinancialInstruments.Deposit);
	Item.Properties.Insert("Visible");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("LimitAmount");
	Finances.NewFilter(Item.Condition, "More.ControlTheLimit", False);
	Item.Properties.Insert("ReadOnly");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("ChangeTheInterestRate");
	Finances.NewFilter(Item.Condition, "More.RateHistoryIsAvailable", True);
	Item.Properties.Insert("Visible");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("InterestRate");
	Finances.NewFilter(Item.Condition, "More.RateHistoryIsAvailable", True);
	Item.Properties.Insert("ReadOnly");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("DateOfFirstTranche");
	Item.Fields.Add("LastPayment");
	Item.Fields.Add("TermMonths");
	Item.Fields.Add("TermDays");
	Item.Fields.Add("TrancheAmount");
	Item.Fields.Add("InterestAmount");
	Finances.NewFilter(Item.Condition, "More.ScheduleOption",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible", False);
	
	//
	Item = Settings.Add();
	Item.Fields.Add("FeeAmount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "FeeType", Enums.LoanAndDepositFeeTypes.None);
	Finances.NewFilter(OrGroup, "More.ScheduleOption",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible", False);
	
	//
	Item = Settings.Add();
	Item.Fields.Add("DateOfTheFirstTrancheOfTheSchedule");
	Item.Fields.Add("DateOfTheLastPaymentOfTheSchedule");
	Item.Fields.Add("APeriodOfMonthsGraphics");
	Item.Fields.Add("SchedulePeriodOfDays");
	Item.Fields.Add("AmountOfTranchesOfTheChart");
	Item.Fields.Add("AmountOfChartPercentages");
	Item.Fields.Add("ScheduleCommissionAmount");
	Finances.NewFilter(Item.Condition, "More.ScheduleOption",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("ScheduleCommissionAmount");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "FeeType", Enums.LoanAndDepositFeeTypes.None);
	Finances.NewFilter(Item.Condition, "More.ScheduleOption",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible");
	
	//
	Item = Settings.Add();
	Item.Fields.Add("ArticleDdsapplications");
	Finances.NewFilter(Item.Condition, "ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Item.Properties.Insert("Title", NStr("vi = 'Thu';
										|ru = 'Поступление';
										|en = 'Cash inflow'; fa = 'ورود وجه نقد';
										|it = 'Arrivo';
										|pl = 'Cash inflow';
										|tr = 'Giriş'"));
	
	//
	Item = Settings.Add();
	Item.Fields.Add("ArticleDdsapplications");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Item.Properties.Insert("Title", NStr("vi = 'Thanh toán';
										|ru = 'Выплата';
										|en = 'Payment'; fa = 'پرداخت';
										|it = 'Pagamento';
										|pl = 'Payment';
										|tr = 'Ödeme'"));
	
	//
	Item = Settings.Add();
	Item.Fields.Add("GroupItemsOfIncomeExpense");
	Finances.NewFilter(Item.Condition, "ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Item.Properties.Insert("Title", NStr("vi = 'Dạng chi phí';
										|ru = 'Статьи расходов';
										|en = 'Expense items'; fa = 'اقلام هزینه';
										|it = 'Voci di spese';
										|pl = 'Pozycje rozchodów';
										|tr = 'Gider kalemleri'"));
	
	//
	Item = Settings.Add();
	Item.Fields.Add("GroupItemsOfIncomeExpense");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Item.Properties.Insert("Title", NStr("vi = 'Dạng thu nhập';
										|ru = 'Статьи доходов';
										|en = 'Income items'; fa = 'اقلام درآمد';
										|it = 'Voci di entrate';
										|pl = 'Pozycje przychodów';
										|tr = 'Gelir kalemleri'"));
	
	//
	Item = Settings.Add();
	Item.Fields.Add("IncomeExpenseItemForInterestAccruals");
	Item.Fields.Add("IncomeExpenseItemForFeeAccruals");
	Finances.NewFilter(Item.Condition, "ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Item.Properties.Insert("TypeRestriction", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
	
	//
	Item = Settings.Add();
	Item.Fields.Add("IncomeExpenseItemForInterestAccruals");
	Item.Fields.Add("IncomeExpenseItemForFeeAccruals");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Item.Properties.Insert("TypeRestriction", New TypeDescription("ChartOfCharacteristicTypesRef.IncomeItems"));
	
	//
	Item = Settings.Add();
	Item.Fields.Add("CodeForSection7OfVATDeclaration");
	Finances.NewFilter(Item.Condition, "More.TradeManagement", False);
	Item.Properties.Insert("Visible");
	
	LoanAndDepositContractsLocalization.AddFormFieldSettings(Settings);
	
	Return Settings
	
EndFunction

// Function-constructor of parameters to be filled in based on statistics of the object's details usage
//
// Returns:
//  See ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn
// 
Function ParametersOfDetailsToFillInBasedOnStatistics() Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "ContractKind, ContractType, PriorityType";
	Parameters.FillInIf.ObjectFieldsFilledIn = "ContractKind, ContractType, PriorityType";
	
	Return Parameters;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	AttributesNames = "CashFlowItemOfFeePayment, CashFlowItemOfPrincipalDebt, CashFlowItemOfReceiptIssuie, CashFlowItemOfInterestPayment,
		|IncomeExpenseItemForFeeAccruals, IncomeExpenseItemForInterestAccruals";
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, AttributesNames, ParametersOfDetailsToFillInBasedOnStatistics());
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization, ForeignCurrencyTransaction";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty, ForeignCurrencyTransaction";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
EndProcedure

#EndRegion

#Region Private

#Region EnteringCashFlowDocuments

Function DataForHeaderOfDDSDocument(LoanDepositContract, ThisIsAdmissionDocument_ = False)
	
	QueryText = 
	"SELECT
	|		LoanDepositContract.Organization AS Organization,
	|		LoanDepositContract.Ref AS LoanDepositContract,
	|		&BusinessOperation AS BusinessOperation,
	|		0 AS DocumentAmount,
	|		LoanDepositContract.Department AS Department,
	|		LoanDepositContract.Counterparty AS Counterparty,
	|		LoanDepositContract.Counterparty.Description AS CounterpartyName_,
	|		LoanDepositContract.Counterparty.DescriptionFull AS CounterpartyFullName,
	|		CASE
	|			WHEN NOT LoanDepositContract.ForeignCurrencyTransaction AND LoanDepositContract.Organization.LocalAccountingCurrency <> LoanDepositContract.ARAPCurrency
	|				THEN LoanDepositContract.Organization.LocalAccountingCurrency
	|			WHEN LoanDepositContract.ForeignCurrencyTransaction AND LoanDepositContract.Organization.LocalAccountingCurrency = LoanDepositContract.ARAPCurrency
	|				THEN CASE WHEN LoanDepositContract.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|							THEN LoanDepositContract.CashAccount.CashCurrency
	|							ELSE LoanDepositContract.BankAccount.CashCurrency
	|						END
	|			ELSE LoanDepositContract.ARAPCurrency
	|		END AS Currency,
	|		LoanDepositContract.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
	|		LoanDepositContract.PaymentMethod AS PaymentMethod,
	|		LoanDepositContract.Status AS Status,
	|		LoanDepositContract.CashAccount AS CashAccount,
	|		LoanDepositContract.BankAccount AS BankAccount,
	|		LoanDepositContract.ContractKind AS ContractKind,
	|		LoanDepositContract.CounterpartyBankAccount AS CounterpartyBankAccount
	|	FROM
	|		Catalog.LoanAndDepositContracts AS LoanDepositContract
	|	WHERE
	|		LoanDepositContract.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", LoanDepositContract);
	Query.SetParameter("BusinessOperation", OperationByNatureOfContract(
		Common.ObjectAttributeValue(LoanDepositContract, "ContractKind"), ThisIsAdmissionDocument_));
	
	QueryResult = Query.Execute();
	HeaderData_ = New Structure;
	For Each Column In QueryResult.Columns Do
		HeaderData_.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FillPropertyValues(HeaderData_, Selection);
	LoanAndDepositContractsLocalization.AddDataToHeaderOfDDSDocument(HeaderData_, LoanDepositContract);
	Return HeaderData_;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	LoanAndDepositContractsLocalization.AddPrintCommands(PrintCommands);
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.FinancialInstrumentsARAPStatement.AddReportCommand(ReportsCommands);
	Reports.VarianceAnalysisOfFinancialInstruments.AddReportCommand(ReportsCommands, "PlanFactualAnalysisLoansDepositsContext");
	If GetFunctionalOption("TradeManagement") Then
		Reports.VarianceAnalysisOfFinancialInstrumentsTM.AddReportCommand(ReportsCommands, "PlanFactualAnalysisLoansDepositsContext");
	EndIf;
	LoanAndDepositContractsLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
