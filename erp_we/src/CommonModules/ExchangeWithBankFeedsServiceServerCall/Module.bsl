
////////////////////////////////////////////////////////////////////////////////
// Bankfeedserverservices exchange: Server function calls are displayed
//
////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks which documents were sent via BankFeeds
// 
// Parameters:
// 	ArrayOfDocumentStructures - Array of Structure - Array of documents to send
// 
// Returns:
// Number - Number of documents accepted by BankFeeds
//
Function NumberOfDocumentsSentToBank(ArrayOfDocumentStructures) Export
	
	DocumentsArray = New Array;
	For Each CurrentLineIsArrayOfDocumentStructures In ArrayOfDocumentStructures Do 
	
		DocumentsArray.Add(CurrentLineIsArrayOfDocumentStructures.PaymentDocumentData.Ref); 
	
	EndDo;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	BankFeedsTransactionStatuses.Object AS ObjectCount
	|FROM
	|	InformationRegister.BankFeedsTransactionStatuses AS BankFeedsTransactionStatuses
	|WHERE
	|	BankFeedsTransactionStatuses.Object IN(&DocumentsArray)
	|	AND BankFeedsTransactionStatuses.IDType = VALUE(Enum.BankFeedsIDTypes.ByPaymentOrder)
	|	AND (BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.accepted)
	|			OR BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.pending)
	|			OR BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.posted)
	|			OR BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.processing))
	|
	|GROUP BY
	|	BankFeedsTransactionStatuses.Object";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Result = Query.Execute().Select();
	
	NumberOfDocumentsSent = 0;
	While Result.Next() Do
		NumberOfDocumentsSent = NumberOfDocumentsSent + 1;
	EndDo;
	
	Return NumberOfDocumentsSent;
	
EndFunction	

// Checks the connection to the service
// 
// Parameters:
// 	BankAccount - CatalogRef.CompaniesBankAccounts - Bank account
// 
// Returns:
// Boolean - True if the bank account is connected to the service
//
Function TestServiceConnection(BankAccount) Export

	Return ExchangeWithBankFeedsServer.TestServiceConnection(BankAccount);
	
EndFunction	

// Defines the current session date
//
// Returns:
//  Date - session date
//
Function LocalCurDate() Export
	
	Return ExchangeWithBankFeedsServer.LocalCurDate();
	
EndFunction

// Fills in the parameters of the background task for reading invoices in the service
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
//  See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskReadInvoicesForOrganization(UUID, FillParameters) Export
	
	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskReadInvoicesForOrganization(
			UUID, FillParameters);
	
EndFunction	

// Fills in the parameters of the background task for checking the connection in the service
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCheckingConnection(UUID, FillParameters) Export

	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskForCheckingConnection(
			UUID, FillParameters);
	
EndFunction

// Fills in the parameters of the background task for user authorization
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForUserAuthorization(UUID, FillParameters) Export
	
	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskForUserAuthorization(
			UUID, FillParameters);
	
EndFunction

// Fills in the parameters of the background task for updating the connection
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundConnectionUpdateTask(UUID, FillParameters) Export

	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundConnectionUpdateTask(
			UUID, FillParameters);
	
EndFunction

// Fills in the parameters of the background task for checking the Status of the connection and consent
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskToCheckStatusOfConnectionAndConsent(UUID, FillParameters) Export

	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskToCheckStatusOfConnectionAndConsent(
			UUID, FillParameters);
	
EndFunction

// Fills in the parameters of the background task for revocation of consent
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForRevocationOfConsent(UUID, FillParameters) Export

	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskForRevocationOfConsent(
			UUID, FillParameters);
	
EndFunction

// Fills in the parameters of the background task for loading transactions
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	ImportParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForDownloadingTransactions(UUID, ImportParameters) Export
	
	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskForDownloadingTransactions(
			UUID, ImportParameters);
	
EndFunction

// Fills in the parameters of the background task for uploading payment documents
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	ExportingParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForUploadingPaymentDocuments(UUID, ExportingParameters) Export
	
	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskForUploadingPaymentDocuments(
			UUID, ExportingParameters);
	
EndFunction

// Fills in the parameters of the background task for uploading payment documents
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCheckingStatusOfPaymentDocuments(UUID) Export
	
	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskForCheckingStatusOfPaymentDocuments(
			UUID);
	
EndFunction

// Fills in the parameters of the background task for connecting to the service
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForConnectingToService(UUID, FillParameters) Export
	
	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskForConnectingToService(
			UUID, FillParameters);	
	
EndFunction

// Fills in the parameters of the background task for connecting to the service
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCheckingConnectionUpdateToService(UUID, FillParameters) Export
	
	Return ExchangeWithBankFeedsServer.FillInParametersOfBackgroundTaskForCheckingConnectionUpdateToService(
			UUID, FillParameters);	
	
EndFunction

// Returns response Statuses
// 
// 
// Returns:
//  Structure - List of values:
//  * IsAnswered - String 
//  * NoResponseReceived - String 
//  * RequestIsNotNeededDataIsReady - String 
//
Function StatusesOfResponses() Export
	
	Return BankFeedsDictionaryInternal.StatusesOfResponse();
	
EndFunction	

// Detects mail by company
// 
// Parameters:
// 	Organization - CatalogRef.Companies - Organization
// 
// Returns:
// String - Mail 
//
Function CompanySMail(Organization) Export
	
	Return ExchangeWithBankFeedsServer.CompanySMail(Organization);
	
EndFunction	

// Defines the service exchange settings for the company and the bank 
// 
// Parameters:
// 	Organization - CatalogRef.Companies - Organization
// 	Bank - CatalogRef.BankClassifier - Bank
// 
// Returns:
//   Structure  - parameter structure: 
//		* ConnectionDate - Date - date of activation.
//		* ServiceSettings - CatalogRef.IntegrateWithBankFeeds - setting up the service.
//
Function ConfigureExchange(Organization, Bank) Export
	
	Return ExchangeWithBankFeedsServer.ConfigureExchange(Organization, Bank);
	
EndFunction	
													
#EndRegion
