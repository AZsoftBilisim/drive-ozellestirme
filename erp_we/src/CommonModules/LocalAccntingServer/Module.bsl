#Region Public

// Returns the regulated accounting settings.
// 
// Returns:
// 	Structure - LongDesc:
//		* AdditionallyManagementAccountingIsConducted - Boolean - True if management accounting is maintained together with the regulated one (on the same chart of accounts).
//		* DateOfCommencementOfManagementAccounting - Date - The date from which joint management and regulated accounting is maintained. If empty, then from the beginning of accounting.
//		* AdditionallyAccountingIsCarriedOutInCurrencyOfFinancialStatements - Boolean - True if the chart of accounts for regulated accounting is additionally recorded in the currency of the financial statements.
//		* FinReportingCurrency - CatalogRef.Currencies - Currency of financial statements.
//
Function AccountingSettings() Export
	
	AccountingSettings = New Structure();
	AccountingSettings.Insert("AdditionallyManagementAccountingIsConducted",       False);
	AccountingSettings.Insert("DateOfCommencementOfManagementAccounting",        Date(1,1,1));
	AccountingSettings.Insert("AdditionallyAccountingIsCarriedOutInCurrencyOfFinancialStatements", False);
	AccountingSettings.Insert("FinReportingCurrency",                          Catalogs.Currencies.EmptyRef());
	AccountingSettings.Insert("UseLocal",                         False);
	AccountingSettings.Insert("StartDateOfLocalAccounting",                   Date(1,1,1));
	
	
	Return AccountingSettings;
	
EndFunction

// Defines the maintenance of regl. accounting for the specified date.
// 
// Parameters:
// 	Date - Date - The date on which you want to check the maintenance of regl. accounting's.
// 	
// Returns:
// 	Boolean - True if regl. accounting is conducted.
Function ReglRecordsAreMaintained(Date = '000101010000') Export
	
	AccountingSettings = AccountingSettings();
	
	ReglRecordsAreMaintained =
		AccountingSettings.UseLocal
		And (Date >= AccountingSettings.StartDateOfLocalAccounting
			Or Date = '000101010000' 
				And CurrentSessionDate() >= AccountingSettings.StartDateOfLocalAccounting);
	
	Return ReglRecordsAreMaintained;
	
EndFunction

// The function returns an accounting invoice depending on the selected tax type. The function is called from
// payment documents.
//
// Parameters:
//   TaxType - CatalogRef.TaxContributionKinds - Type of taxes.
//
// Returns:
//   ChartOfAccountsRef - By taking into account the type of tax.
// 
Function InvoiceByTaxType(TaxType) Export
	
	GLAccount = Undefined;
	
	Return GLAccount;
	
EndFunction

//The function returns an array of Types of Balance input documents
// 
// Returns:
//  Array - Types Of Residue Entry Documents
Function BalanceEntryDocuments() Export
	
	TypesOfResidueEntryDocuments = New Array;
	
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntry")); 
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryARAP"));
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryCash"));
	
	
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntrySalesForPastPeriods")); 
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryFinancialInstruments"));
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryOtherExpenses"));
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryOtherAssetsAndLiabilities"));
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryAcquiringContractARAP")); 
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryARAPAdvanceHolders"));
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryInventoryInOperation"));
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryGoods"));
	
	
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.OBEntryOfLeaseSettlements"));
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.EntryOfCapitalAssetsBalance2_4"));
	TypesOfResidueEntryDocuments.Add(Type("DocumentRef.EnterRentalInvestmentBalance"));  

	Return TypesOfResidueEntryDocuments;
	
EndFunction
	
// The function returns the type of tax depending on the selected accounting account. The function is called from
// update handlers.
//
// Parameters:
//   GLAccount - ChartOfAccountsRef - By taking into account the type of tax.
//
// Returns:
//   CatalogRef.TaxContributionKinds - The type of taxes on the accounting account.
// 
Function TypeOfTaxByAccount(GLAccount) Export
	
	TaxType = Undefined;
	
	
	Return TaxType;
	
EndFunction

// Returns the availability of document reflection in regl. account for the current user.
// 
// Returns:
// 	Boolean - Availability of rights to reflect documents in the regl. accounting
//
Function ThereIsRightOfReflectionOfDocumentsInLocalAccounting() Export
	
	Result = False;
	Return Result;
	
EndFunction

// Returns documents to be reflected in regl. accounting
//
// Parameters:
// 	DocumentsToBeReflected -   ValueTable, 
// 							Time table Manager - a table of documents to be returned to reflection, 
// 													  or a temporary table Manager that has a document table to Reflect
// 													  The table should have the columns Document, Organization, and Datareferences. 
// 	ProcessedItemsCount - Number - This parameter sets the number of documents returned for reflection.
// 									 This parameter is optional.
//
Procedure ReturnDocumentsToReflection(DocumentsToBeReflected, ProcessedItemsCount = Undefined) Export
	
	
EndProcedure

// Registers documents of settlements with partners for reflection in the regulated accounting.
//
// Parameters:
//	Calculations - ValueTable - Table of movements for settlements with partners:
//	                         * Recorder - DocumentRef - Document-motion recorder
//	                         * Period - Date - Period of movements
//	                         * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Accounting Analytics.
//
Procedure RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(Calculations) Export
	
	
EndProcedure

// The procedure is called from the methods of routine operations to record data in the register of information "setdisclosing Month"
//	about the need to recalculate the recognition of expenses (if organizations with the object of taxation "Income minus expenses" change).
// Parameters:
//	Period - Date - the counting period;
//	CompaniesList - Array - Spravochnike.Organizations-an array of organizations that the recalculation procedure is running for.
//	OnlyExpenses - Boolean - Flag for selecting suitable organizations. The default value is True.
//		If True, organizations on the USN will be selected, with the object of taxation "Income minus expenses".
//		If False, organizations on the USN will be selected regardless of the object of taxation. the default value is True.
//	ProcessedItemsCount - Number - The amount of data processed by this procedure (see the general module "Performance") .
//
Procedure UpdateTasksByEndOfMonthWhenPerformingLocalOperation(Period, CompaniesList, OnlyExpenses = True, ProcessedItemsCount = 0) Export
	
	
EndProcedure

// Returns the structure of regl accounting registers
// 
// Returns:
// 	Structure - The structure of VAT registers, where
// 	     Key - Register Name
// 	     The value is a set of register entries.
Function LocalAccountingRegisters() Export
	
	LocalRegisters = New Structure();
	Return LocalRegisters;
	
EndFunction

// The procedure of formation of movements on the slave registers of regulated accounting.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	
EndProcedure

// Returns properties of a regulated accounting account
//
// Parameters:
// 	Account - ChartOfAccountsRef - The expense of the regulated accounting
// Returns:
// 	Structure - Account properties
Function GetAccountProperties(Val Account) Export
	
	InvoiceData = Undefined;
	
	
	Return InvoiceData;
	
EndFunction

// Adjusts the visibility of the WELL, PR, and BP fields on the form
//
// Parameters:
//  IncomeTaxFields - Map - key = form field, including line headings; value = type of accounting TA/PD/TD
//  Period         - Date - the main period of the recordset
//  Organization    - CatalogRef.Companies - organizing a set of records
//                 - Undefined - the organization of the recordset cannot be determined
//  TypeOfUseOfAmounts - String -
//  WithdrawAmountOfDifferencesForProfitTaxPayer - Boolean - withdraw the amounts of differences if the company keeps records of PBU 18/02 using a simple balance method 
//
Procedure ConfigureVisibilityOfTaxAccountingAndDifferencesFields(IncomeTaxFields, Period, Organization = Undefined, TypeOfUseOfAmounts = "",
	WithdrawAmountOfDifferencesForProfitTaxPayer = False) Export
	
	DefaultVisibility = False;
	
	For Each Field In IncomeTaxFields Do
		Field.Key.Visible = DefaultVisibility;
	EndDo;
	
	
EndProcedure


// Types of taxes with account settings.
// 
// Returns:
//  Array - CatalogRef.TaxContributionKinds
//
Function TypesOfTaxesWithAccountSettings() Export
	
	TaxesKinds = New Array;
	
	
	Return TaxesKinds;
	
EndFunction


// The accounting policy of financial accounting when recording.
// 
// Parameters:
//  Cancel - Boolean - Cancel
//  RecordSet - InformationRegisterRecordSet.FinancialAccountingPolicy - a set of information register entries
Procedure AccountingPolicyOfFinancialAccounting_WhenRecording(Cancel, RecordSet) Export
	Var AdvancedDetailingIsIncluded;

EndProcedure

// Organizations before recording.
// 
// Parameters:
//  Object - CatalogObject.Companies - organizationCatalog item
//  Cancel - Boolean - Cancel
Procedure Companies_BeforeWrite(Object, Cancel) Export
	Var AdvancedDetailingIsIncluded;

EndProcedure

#EndRegion

#Region Private


#EndRegion
