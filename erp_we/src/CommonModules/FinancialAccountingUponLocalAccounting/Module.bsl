#Region Public

// Adds the reflection parameters necessary for generating transactions based on regulated accounting data.
// 
// Parameters:
// 	 ParametersForGeneratingTransactions - See FinancialAccountingPostingServer.ParametersForGeneratingTransactions
//
Procedure AddParametersForGeneratingTransactions(ParametersForGeneratingTransactions) Export
EndProcedure

// Generates international accounting entries based on regulated accounting data.
// 
// Parameters:
// 	ParametersForGeneratingTransactions - Structure - Parameters for generating transactions.
// 	TableOfTransactions - ValueTable - The table that the generated transactions are added to.
//
Procedure Reflect(ParametersForGeneratingTransactions, TableOfTransactions) Export
EndProcedure

// Supplements the tables of registration of a document to be reflected in international accounting according to registration data to be reflected in the regulated one.
// 
// Parameters:
// 	Object - DocumentObject - The document that is being held.
// 	AdditionalObjectProperties - Structure - Additional object properties
// 	AdditionalPropertiesOfRegister - Structure - Additional properties of the RS are reflected in documentsinternational Accounting.
// 	RegistrationTable - ValueTable - A table with registration data for reflection, which needs to be supplemented:
// 	                      * Period - Date - registration period (document date);
// 	                      * Organization - CatalogRef.Companies - the organization for which the document generates transactions;
// 	                      * DateRecord - Date - the date on which the document forms of the transaction;
// 	                      * BusinessOperation - EnumRef.BusinessTransactions - of reflected economic operation.
//
Procedure AddRegistrationTablesToReflection(Object, AdditionalObjectProperties, AdditionalPropertiesOfRegister, RegistrationTable) Export
EndProcedure

// Checks whether there are configured invoice matches that are required to reflect documents. 
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - Contains a temporary table documentreflection:
// 	              * Document - DocumentRef - 
// 	              * Organization - CatalogRef.Companies - 
// 	              * PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting -
// 	CheckParameters - See DataProcessors.DocumentPostingInFinancialAccounting.ParametersForCheckingReflectionRules
// 	
// Returns:
// 	ValueTable - Table of required settings:
// 	              * Account - ChartOfAccountsRef -
// 	              * PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - 
// 	              * Comment - String -
//
Function CheckRecordingRules(TempTablesManager, CheckParameters) Export
	
	ErrorsTable = New ValueTable;
	
	
	Return ErrorsTable;
	
EndFunction

// Causes the document to be reflected in regulated accounting.
// 
// Parameters:
// 	DocumentAttributes - Structure - Attributes of the document to be reflected:
// 	                     * Ref - DocumentRef - link to the document;
// 	                     * Date - Date - document date;
// 	                     * Organization - CatalogRef.Companies - document date.
//
Procedure ReflectDocumentInLocalAccounting(DocumentAttributes) Export
EndProcedure

// Fills in the table with documents that require reflection and generate transactions of regulated accounting for a specific account.
// 
// Parameters:
// 	DocumentsTable - ValueTable - The table of values to be filled in:
// 						Columns:
// 						* Document - DocumentRef - link to the document;
// 						* Date - Date - document date;
// 						* Organization - CatalogRef.Companies - The organization for which the document generates regl transactions. accounting's;
// 						* Comment - String - Comment on the status of the document's reflection in international accounting;
// 	Account - ChartOfAccountsRef - A regulated accounting account for which you need to select document transactions.
// 	PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - Setting of the formation transactions for the selection of documents.
// 	Organization - CatalogRef.Companies - The organization for the selection of documents.
//
Procedure FillInTableOfDocumentsOnAccount(DocumentsTable, Account, PostingGenerationSetting, Organization) Export
	
	
EndProcedure

// Checks reflection rules before they are recorded in the international accounting Rule register.
//
// Parameters:
// 	RulesOfPostingsInFinancialAccounting - ValueTable - Uploading a set of records in the register of rules for international accounting.
// 	Cancel - Boolean - The record failure flag is set in case of an error.
//
Procedure BeforeWritingReflectionRules(RulesOfPostingsInFinancialAccounting, Cancel) Export

	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions
// 
Procedure CustomizeReportsOptions(Settings) Export
	
	
EndProcedure

#EndRegion

