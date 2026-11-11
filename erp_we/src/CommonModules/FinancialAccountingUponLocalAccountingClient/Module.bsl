#Region Public

// Handler for commands added dynamically.
//
// (See ReportsClientOverridable.HandlerCommands).
//
Procedure HandlerCommands(ThisForm, Command, Result) Export
	
	
EndProcedure

// Handler for decoding a table document in a report form.
//
// (See ReportsClientOverridable.DetailProcessing)
//
Procedure DetailProcessing(ThisForm, Item, Details, StandardProcessing) Export
	
	
EndProcedure

// Opens the form for viewing regulated accounting transactions for a document.
// 
// Parameters:
// 	Document - DocumentRef - The document for which you want to open the form to view the transactions.
// 	OwnerForm - ClientApplicationForm - The owner of the form to view the transactions.
//
Procedure OpenLocalAccountingTransactions(Document, OwnerForm) Export
	
	
EndProcedure

// Opens the form for setting up compliance of accounts and international accounting turnover with regulated ones.
// 
// Parameters:
// 	FormParameters - See FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms
// 	OwnerForm - ClientApplicationForm - Owner of the configuration form.
// 	LocalAccountingAccount - ChartOfAccountsRef, 
// 	                Undefined - a regulated accounting Account that needs to be configured.
// 	                               If Undefined, the form opens for setting up all accounts.
//
Procedure OpenAccountsAndTurnoverMatchingSettings(FormParameters, OwnerForm, LocalAccountingAccount = Undefined) Export
	
	
EndProcedure


#EndRegion

