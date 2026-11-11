////////////////////////////////////////////////////////////////////////////////
// The Bank Feeds Service dictionary: describes the settings and values of the service settings 
//
////////////////////////////////////////////////////////////////////////////////
#Region Internal

// Possible response Statuses are described
// 
// Returns:
//  Structure - List of values:
//  * IsAnswered - String 
//  * NoResponseReceived - String 
//  * RequestIsNotNeededDataIsReady - String 
//
Function StatusesOfResponse() Export
	
	StatusesOfResponse = New Structure();
	
	StatusesOfResponse.Insert("IsAnswered", "IsAnswered");
	StatusesOfResponse.Insert("NoResponseReceived", "NoResponseReceived");
	StatusesOfResponse.Insert("RequestIsNotNeededDataIsReady", "RequestIsNotNeededDataIsReady");
	
	Return StatusesOfResponse;
EndFunction

// Service addresses are described
// 
// Returns:
//  Map of String - Transfers.ServiceBankFeeds -> service address:
//
Function ServiceRequestAddresses() Export
	
	RequestAddresses = New Map; 
	RequestAddresses.Insert(Enums.BankFeedsServices.SaltEdge, "https://www.saltedge.com/api/partners/v1/");
	
	Return RequestAddresses; 
	
EndFunction	

// The service Commands are described
// 
// Parameters:
// 	Service - EnumRef.BankFeedsServices - enumeration value
//
//
// Returns:
//  Structure - the service Commands are returned:
//  * CreateUser - String
//  * CreateLeadSession - String
//  * GetListOfProvidersFromService - String
//  * GetListOfConnectionsFromService - String
//  * GetListOfAccountsFromService - String
//  * GetListOfTransactionsFromService - String
//  * OpenPaymentSessionInService - String
//  * GetListOfFormatsFromService - String
//  * GetListOfCurrenciesFromService - String
//  * GetListOfCountriesFromService - String
//  * GetListOfPaymentDocumentsFromService - String
//  * GetTranscriptOfMerchants - String
//  * GetListOfCompanies - String
//  * UpdateConnection - String
//  * GetListOfConsents - String
//  * RevokeConsent - String
//
Function CommandsOfServices(Service) Export
	
	QueryCommands = New Structure();
	
	If Service = Enums.BankFeedsServices.SaltEdge Then
		
		QueryCommands.Insert("CreateUser", "/api/partners/v1/leads");
		QueryCommands.Insert("CreateLeadSession", "/api/partners/v1/lead_sessions/create");
		QueryCommands.Insert("GetListOfProvidersFromService", "/api/partners/v1/providers");
		QueryCommands.Insert("GetListOfConnectionsFromService", "/api/partners/v1/connections");
		QueryCommands.Insert("GetListOfAccountsFromService", "/api/partners/v1/accounts");
		QueryCommands.Insert("GetListOfTransactionsFromService", "/api/partners/v1/transactions");
		QueryCommands.Insert("OpenPaymentSessionInService", "/api/partners/v1/payments/sessions");
		QueryCommands.Insert("GetListOfFormatsFromService", "/api/partners/v1/payments/templates");
		QueryCommands.Insert("GetListOfCurrenciesFromService", "/api/partners/v1/currencies");
		QueryCommands.Insert("GetListOfCountriesFromService", "/api/partners/v1/countries");
		QueryCommands.Insert("GetListOfPaymentDocumentsFromService", "/api/partners/v1/payments"); 
		QueryCommands.Insert("GetTranscriptOfMerchants", "/api/partners/v1/merchants"); 
		QueryCommands.Insert("GetListOfCompanies", "/api/partners/v1/customers"); 
		QueryCommands.Insert("UpdateConnection", "/api/partners/v1/lead_sessions/reconnect"); 
		QueryCommands.Insert("GetListOfConsents", "/api/partners/v1/partner_consents"); 
		QueryCommands.Insert("RevokeConsent", "/api/partners/v1/partner_consents"); 
		
	EndIf;	
	
	Return QueryCommands;
EndFunction 

// The body is returned in the request by the service Command
// 
// Parameters:
// 	Service - EnumRef.BankFeedsServices - enumeration value
//
//
// Returns:
//  Map of String - service Command -> request body 
//
Function ListOfCommandBodies(Service) Export
	
	RelationshipBetweenCommandAndRequestBody = New Map();
	QueryCommands = CommandsOfServices(Service);

	// QueryCommands.CreateUser
	RequestBody = New Structure();
	AddProperty(RequestBody, "data", New Structure());
	Var_Data = RequestBody.Data;
	AddProperty(Var_Data, "email", ""); 
	AddProperty(Var_Data, "identifier", ""); 
	AddProperty(Var_Data, "kyc", New Structure());   
	RegistrationData = Var_Data.kyc;
	AddProperty(RegistrationData, "full_name", "");   
	AddProperty(RegistrationData, "type_of_account", "legal");   
	AddProperty(RegistrationData, "date_of_birth", "");   
	AddProperty(RegistrationData, "place_of_birth", "");   
	AddProperty(RegistrationData, "gender", "");   
	AddProperty(RegistrationData, "citizenship_code", "");   
	AddProperty(RegistrationData, "residence_address", "");   
	AddProperty(RegistrationData, "legal_name", "");   
	AddProperty(RegistrationData, "registered_office_code", "");   
	AddProperty(RegistrationData, "registered_office_address", "");   
	AddProperty(RegistrationData, "registration_number", "");   
	
	RelationshipBetweenCommandAndRequestBody.Insert(QueryCommands.CreateUser, RequestBody);
	
	// QueryCommands.UpdateConnection
	RequestBody = New Structure();
	AddProperty(RequestBody, "data", New Structure());
	Data = RequestBody.Data;
	AddProperty(Data, "connection_id", "");   
	AddProperty(Data, "customer_id", "");   
	AddProperty(Data, "consent", New Structure());   
	Consents = Data.consent;
	AddProperty(Consents, "scopes", New Array());
	Rules = Consents.scopes;
	Rules.Add("account_details");
	Rules.Add("transactions_details");
	AddProperty(Consents, "from_date", "");   
	AddProperty(Data, "attempt", New Structure());   
	RequestBody.Data.attempt.Insert("custom_fields", New Structure());
	RequestBody.Data.attempt.custom_fields.Insert("numberAccount", "");
	RequestBody.Data.attempt.custom_fields.Insert("nameBank", "");
	RequestBody.Data.attempt.custom_fields.Insert("RecordID", "");
	
	RelationshipBetweenCommandAndRequestBody.Insert(QueryCommands.UpdateConnection, RequestBody);
	
	// QueryCommands.CreateLeadSession
	RequestBody = New Structure();
	RequestBody.Insert("data", New Structure());
	RequestBody.Data.Insert("customer_id", ""); 
	RequestBody.Data.Insert("provider_code", ""); 
	RequestBody.Data.Insert("consent", New Structure()); 
	RequestBody.Data.consent.Insert("scopes", New Array());
	RequestBody.Data.consent.scopes.Add("account_details");
	RequestBody.Data.consent.scopes.Add("transactions_details");
	RequestBody.Data.Insert("attempt", New Structure()); 
	RequestBody.Data.attempt.Insert("custom_fields", New Structure());
	RequestBody.Data.attempt.custom_fields.Insert("numberAccount", "");
	RequestBody.Data.attempt.custom_fields.Insert("nameBank", "");
	RequestBody.Data.attempt.custom_fields.Insert("RecordID", "");
	
	RelationshipBetweenCommandAndRequestBody.Insert(QueryCommands.CreateLeadSession, RequestBody);
	
	//QueryCommands.OpenPaymentSessionInService
	RequestBody = New Structure();
	RequestBody.Insert("data", New Structure());
	RequestBody.Data.Insert("customer_id", ""); 
	RequestBody.Data.Insert("provider_code", ""); 
	RequestBody.Data.Insert("payee_description", ""); 
	RequestBody.Data.Insert("template_identifier", "SEPA"); 
	RequestBody.Data.Insert("payment_attributes", New Structure()); 
	
	payment_attributes = New Structure();
	payment_attributes.Insert("end_to_end_id", "");
	payment_attributes.Insert("customer_ip_address", "");
	payment_attributes.Insert("customer_device_os", "");
	
	payment_attributes.Insert("creditor_name", "");
	payment_attributes.Insert("creditor_street_name", "");
	payment_attributes.Insert("creditor_building_number", "");
	payment_attributes.Insert("creditor_post_code", "");
	payment_attributes.Insert("creditor_town", "");
	payment_attributes.Insert("creditor_country_code", "");  
	
	payment_attributes.Insert("debtor_name", "");
	payment_attributes.Insert("debtor_street_name", "");
	payment_attributes.Insert("debtor_building_number", "");
	payment_attributes.Insert("debtor_post_code", "");
	payment_attributes.Insert("debtor_town", "");
	payment_attributes.Insert("debtor_country_code", "");  
	
	payment_attributes.Insert("currency_code", "");
	payment_attributes.Insert("amount", "");
	payment_attributes.Insert("description", "");
	payment_attributes.Insert("creditor_iban", "");
	payment_attributes.Insert("debtor_iban", "");
	payment_attributes.Insert("mode", "");    
	payment_attributes.Insert("charge_bearer", "SHARED");    
	
	payment_attributes.Insert("custom_fields", New Structure("uid_document",""));

	RequestBody.Data.payment_attributes = payment_attributes;	
	
	RelationshipBetweenCommandAndRequestBody.Insert(QueryCommands.OpenPaymentSessionInService, RequestBody);
	
	RequestBody = New Structure();
	RequestBody.Insert("data", New Array());
	RelationshipBetweenCommandAndRequestBody.Insert(QueryCommands.GetTranscriptOfMerchants, RequestBody);
	
	Return RelationshipBetweenCommandAndRequestBody;
	
EndFunction	

// Returns the data structure of the payment request. 
// Matching the name of the column and the field that should be transmitted to the service.
// 
//
// Returns:
//  See PaymentRequestTemplates
//
Function PaymentRequestTemplates() Export

	PaymentTemplates = New Map();
	
	Name_Template = Enums.BankFeedsPaymentMethods.SEPA;
	
	StructureOfData = New Structure();
	StructureOfData.Insert("PaymentTemplateID",      "end_to_end_id");
	StructureOfData.Insert("customer_ip",           "customer_ip_address");
	StructureOfData.Insert("customer_device",       "customer_device_os"); 
	
	StructureOfData.Insert("CounterpartyName",        "debtor_name");
	StructureOfData.Insert("Counterparty_Street",      "debtor_street_name");
	StructureOfData.Insert("Counterparty_House",        "debtor_building_number");
	StructureOfData.Insert("Counterparty_MailNumber", "debtor_post_code");
	StructureOfData.Insert("Counterparty_City",      "debtor_town");
	StructureOfData.Insert("Counterparty_AreaCode",  "debtor_country_code");
	StructureOfData.Insert("CounterpartyBankAccount_",    "debtor_iban"); 

	StructureOfData.Insert("CompanyHiring",        "creditor_name");
	StructureOfData.Insert("Company_Street",      "creditor_street_name");
	StructureOfData.Insert("Company_House",        "creditor_building_number");
	StructureOfData.Insert("Company_MailNumber", "creditor_post_code");
	StructureOfData.Insert("Company_City",      "creditor_town");
	StructureOfData.Insert("Company_AreaCode",  "creditor_country_code");
	StructureOfData.Insert("CompanyBankAccount_",   "creditor_iban");  
	
	StructureOfData.Insert("ISOCurrencyCode_",          "currency_code");
	StructureOfData.Insert("Sum",                 "amount");
	StructureOfData.Insert("PaymentPurposes",     "description");
	StructureOfData.Insert("Mode",                 "mode");
	
	PaymentTemplates.Insert(Name_Template, StructureOfData);
	
	Return PaymentTemplates;
	
EndFunction	

// Returns the data structure of the payment order. 
// Matching the name of the column and the field that should be transmitted to the service.
// 
//
// Returns:
//  Structure - List of parameters and values of the parameter Query Text:
//  * end_to_end_id -  String
//  * customer_ip_address - String
//  * customer_device_os - String
//  * creditor_name - String
//  * creditor_street_name - String
//  * creditor_building_number - String
//  * creditor_post_code - String
//  * creditor_town - String
//  * creditor_country_code - String
//  * currency_code - String
//  * amount - String
//  * description - String
//  * creditor_iban - String
//  * mode - String
//
Function PaymentOrderTemplates() Export
	
	PaymentTemplates = New Map();
	
	Name_Template = Enums.BankFeedsPaymentMethods.SEPA;
	
	StructureOfData = New Structure();
	StructureOfData.Insert("PaymentTemplateID",      "end_to_end_id");
	StructureOfData.Insert("customer_ip",           "customer_ip_address");
	StructureOfData.Insert("customer_device",       "customer_device_os");
	StructureOfData.Insert("CounterpartyName",        "creditor_name");
	StructureOfData.Insert("Counterparty_Street",      "creditor_street_name");
	StructureOfData.Insert("Counterparty_House",        "creditor_building_number");
	StructureOfData.Insert("Counterparty_MailNumber", "creditor_post_code");
	StructureOfData.Insert("Counterparty_City",      "creditor_town");
	StructureOfData.Insert("Counterparty_AreaCode",  "creditor_country_code");
	StructureOfData.Insert("ISOCurrencyCode_",          "currency_code");
	StructureOfData.Insert("Sum",                 "amount");
	StructureOfData.Insert("PaymentPurposes",     "description");
	StructureOfData.Insert("CounterpartyBankAccount_",    "creditor_iban");
	StructureOfData.Insert("CompanyBankAccount_",   "debtor_iban");
	StructureOfData.Insert("Mode",                 "mode");
	
	PaymentTemplates.Insert(Name_Template, StructureOfData);
	
	Return PaymentTemplates;
	
EndFunction

// The body is returned in the request by the service Command
// 
// Parameters:
// 	Command - String - enumeration value
//
//
// Returns:
//  Map of String - service Command -> request body 
//
Function CommandParameters(Command) Export
	
	 SaltEdgeServiceCommands = CommandsOfServices(Enums.BankFeedsServices.SaltEdge);  
	 CommandsParameters = CommandsParameters();
	 
	 QueryParametersByCommand = New Map();
	 QueryParametersByCommand.Insert(SaltEdgeServiceCommands.GetListOfConnectionsFromService, 
	 	New Structure("Customer_id", CommandsParameters.Customer_id));

	 QueryParametersByCommand.Insert(SaltEdgeServiceCommands.GetListOfPaymentDocumentsFromService, 
	 	New Structure("Customer_id", CommandsParameters.Customer_id));
		
	 QueryParametersByCommand.Insert(SaltEdgeServiceCommands.GetListOfAccountsFromService, 
	 	New Structure("Connection_id", CommandsParameters.Connection_id));

  	 QueryParametersByCommand.Insert(SaltEdgeServiceCommands.OpenPaymentSessionInService, 
	 	New Structure("Payment_id", CommandsParameters.Payment_id));

	 QueryParametersByCommand.Insert(SaltEdgeServiceCommands.GetListOfTransactionsFromService, 
	 	New Structure("Connection_id,Account_id" , CommandsParameters.Connection_id, CommandsParameters.Account_id));
		
	 QueryParametersByCommand.Insert(SaltEdgeServiceCommands.GetListOfConsents, 
	 	New Structure("Connection_id" , CommandsParameters.Connection_id));
		
	Return QueryParametersByCommand[Command];
	
 EndFunction	
  
// Returns the Query Text for the parameter
// 
//
// Returns:
//  Structure - List of parameters and values of the parameter Query Text:
//  * Customer_id - String
//  * Connection_id - String
//  * Consent_id - String
//  * Account_id - String
//  * Payment_id - String
//
Function CommandsParameters() Export
	 
	 CommandsParameters = New Structure();
	 CommandsParameters.Insert("Customer_id", "customer_id=%CUSTOMER_ID%");
	 CommandsParameters.Insert("Connection_id", "connection_id=%CONNECTION_ID%");
	 CommandsParameters.Insert("Consent_id", "consent_id=%CONSENT_ID%");
	 CommandsParameters.Insert("Account_id", "account_id=%ACCOUNT_ID%");
	 CommandsParameters.Insert("Payment_id", "payment.id");

	 Return CommandsParameters;
	 
 EndFunction	
  
// The main format of the payment document is returned
// 
//
// Returns:
//  EnumRef.BankFeedsPaymentMethods - SEPA
//
Function MainTemplateForPaymentOrderFormat() Export
	 
	Return Enums.BankFeedsPaymentMethods.SEPA;
	 
EndFunction	 

// Returns the Command that is passed when the connection form is opened programmatically.
// 
//
// Returns:
//  Structure - Connection form Commands:
//  * ConnectAccount - String
//  * AddInvoice - String
//
Function CommandsForOpeningActivationForm() Export
	
	OpeningCommands = New Structure();	
	OpeningCommands.Insert("ConnectAccount", "ConnectAccount");
	OpeningCommands.Insert("AddInvoice", "AddInvoice");
	
	Return OpeningCommands;
	
EndFunction	

// Returns the correspondence of which category in the service corresponds to the business transaction
// upon receipt of Cash.
//
// Returns:
//  Map of EnumRef.BusinessTransactions - Category name in the service -> business transaction
//
Function ListOfComplianceOfCategoryToBusinessOfOperationUponReceiptOfCash() Export
	
	ListOfMatches = New Map();
	
	ListOfMatches.Insert("transfer", Enums.BusinessTransactions.CashReceiptFromAnotherAccount);

	ListOfMatches.Insert("returns", Enums.BusinessTransactions.RefundFromVendor);
	
	ListOfMatches.Insert("student_loan", Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty);

	ListOfMatches.Insert("investment_income",   Enums.BusinessTransactions.CashReceiptUnderDeposits);
	
	ListOfMatches.Insert("gifts_and_donations",    Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("charity", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("income", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("bonus", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("paycheck", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("insurance", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("car_insurance", 		  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("health_insurance", 	  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("life_insurance", 		  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("property_insurance",     Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("kids",                   Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("allowance", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("babysitter_and_daycare", Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("baby_supplies", 		  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("child_support", 		  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("kids_activities", 	      Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("toys",					  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("pets", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("pet_food_and_supplies",  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("pet_grooming", 		  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("veterinary", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("travel", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("hotel", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("transportation", 		  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("vacation", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("uncategorized", 		  Enums.BusinessTransactions.OtherCashReceipt);
	//Business
	ListOfMatches.Insert("financials", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("dividends",			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("donations", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("interest", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("fees", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("fines",				  Enums.BusinessTransactions.OtherCashReceipt);  
	ListOfMatches.Insert("human_resources",		  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("wages", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("bonus", 			 	  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("employee_benefits", 	  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("travel", 				  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("entertainment", 		  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("insurance", 			  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("business_insurance", 	  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("liability_insurance", 	  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("health_insurance", 	  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("equipment_insurance", 	  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("vehicle_insurance", 	  Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("professional_insurance", Enums.BusinessTransactions.OtherCashReceipt);
	ListOfMatches.Insert("uncategorized",   		  Enums.BusinessTransactions.OtherCashReceipt);

	ListOfMatches.Insert("loans", 				  Enums.BusinessTransactions.CashReceiptFromLoansRepayment);
	ListOfMatches.Insert("mortgage",			  	  Enums.BusinessTransactions.CashReceiptFromLoansRepayment);
	
	ListOfMatches.Insert("taxes", 		  Enums.BusinessTransactions.TaxRefund);
	ListOfMatches.Insert("vat", 			  Enums.BusinessTransactions.TaxRefund);
	ListOfMatches.Insert("federal_taxes",  Enums.BusinessTransactions.TaxRefund);
	ListOfMatches.Insert("property_taxes", Enums.BusinessTransactions.TaxRefund);
	ListOfMatches.Insert("income_taxes",   Enums.BusinessTransactions.TaxRefund);
	ListOfMatches.Insert("duty_taxes",     Enums.BusinessTransactions.TaxRefund);
	ListOfMatches.Insert("tax_return",     Enums.BusinessTransactions.TaxRefund);
	ListOfMatches.Insert("payroll_taxes",  Enums.BusinessTransactions.TaxRefund);
	
	Return ListOfMatches;
EndFunction

// Returns the correspondence of which category in the service corresponds to the business transaction
// when the Cash is debited.
//
// Returns:
//  Map of EnumRef.BusinessTransactions - Category name in the service -> business transaction
//
Function ListOfMatchingCategoriesToBusinessOfOperationsWhenWritingOffCash() Export

	ListOfMatches = New Map();
	
	ListOfMatches.Insert("transfer", Enums.BusinessTransactions.TransferCashToAnotherAccount);
	
	ListOfMatches.Insert("fees_and_charges", 	  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("provider_fee", 		  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("loans", 				  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("gifts_and_donations",    Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("charity", 				  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("mortgage", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("rent", 				  Enums.BusinessTransactions.PaymentToLessor);  
	ListOfMatches.Insert("mortgage", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("insurance", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("car_insurance", 		  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("health_insurance", 	  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("life_insurance", 		  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("property_insurance", 	  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("kids",				 	  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("allowance", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("babysitter_and_daycare", Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("baby_supplies", 		  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("child_support", 		  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("kids_activities", 		  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("toys", 				  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("pets", 				  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("pet_food_and_supplies",  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("pet_grooming", 		  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("veterinary",		      Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("financials", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("dividends", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("donations", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("interest", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("fees", 				  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("fines", 				  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("loans",			 	  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("human_resources", 		  Enums.BusinessTransactions.OtherCashIssue); 
	
	ListOfMatches.Insert("wages", Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram); 
	ListOfMatches.Insert("bonus", Enums.BusinessTransactions.SalaryPaymentToBankAccounts); 
	ListOfMatches.Insert("employee_benefits", Enums.BusinessTransactions.SalaryPaymentToBankAccounts); 
	
	ListOfMatches.Insert("travel", 				  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("entertainment", 		  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("insurance", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("business_insurance",     Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("liability_insurance",    Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("health_insurance", 	  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("equipment_insurance", 	  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("vehicle_insurance", 	  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("professional_insurance", Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("real_estate", 			  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("office_rent", 			  Enums.BusinessTransactions.PaymentToLessor);  
	ListOfMatches.Insert("mortgage",				  Enums.BusinessTransactions.OtherCashIssue);  
	ListOfMatches.Insert("uncategorized", 		  Enums.BusinessTransactions.OtherCashIssue);
	
	ListOfMatches.Insert("Taxes", 		  Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	ListOfMatches.Insert("taxes", 		  Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	ListOfMatches.Insert("Vat", 			  Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	ListOfMatches.Insert("federal_taxes",  Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	ListOfMatches.Insert("property_taxes", Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	ListOfMatches.Insert("Income_taxes",   Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	ListOfMatches.Insert("Duty_taxes",     Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	ListOfMatches.Insert("Payroll_taxes",  Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	ListOfMatches.Insert("tax_return",     Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	
	ListOfMatches.Insert("returns", Enums.BusinessTransactions.RefundToCustomer);

	Return ListOfMatches;
	
EndFunction	

// Describes the registration Attributes on the form
//
// Returns:
//  Structure - described Attributes:
//  * RegistrarSResidentialAddress - String
//  * RegistrarSDateOfBirth - String
//  * RegistrarSCountryOfCitizenship - String
//  * LastNameFirstNamePatronymicOfRegistrar - String
//  * RegistrarSPlaceOfBirth - String
//  * GenderOfRegistrar - String
//  * CompanyOfficeAddress - String
//  * CompanyIsRegisteredInCountry - String
//  * CompanyRegistrationNumber - String
//  * LegalNameOfCompany - String
//  * DataIsConfirmedByUser - Boolean
//
Function RegistrationDetailsOnForm() Export

 AttributesSet = New Structure();	

 AttributesSet.Insert("RegistrarSResidentialAddress", "");
 AttributesSet.Insert("RegistrarSDateOfBirth", "");
 AttributesSet.Insert("RegistrarSCountryOfCitizenship", "");
 AttributesSet.Insert("LastNameFirstNamePatronymicOfRegistrar", "");
 AttributesSet.Insert("RegistrarSPlaceOfBirth", "");  
 AttributesSet.Insert("GenderOfRegistrar", "");  

 AttributesSet.Insert("CompanyOfficeAddress", "");
 AttributesSet.Insert("CompanyIsRegisteredInCountry", "");
 AttributesSet.Insert("CompanyRegistrationNumber", "");
 AttributesSet.Insert("LegalNameOfCompany", "");

 AttributesSet.Insert("DataIsConfirmedByUser", False);
 
 Return AttributesSet;  
 
EndFunction

// matches the Attributes on the form with the Attributes in the request
//
// Returns:
//  Map of String - Matching the Attributes in the request
//
Function ComplianceOfRegistrationDetailsOnFormWithRequestDetails() Export
	
	ListOfMatches = New Map();
	
	ListOfMatches.Insert("LastNameFirstNamePatronymicOfRegistrar",  "full_name");
	ListOfMatches.Insert("RegistrarSCountryOfCitizenship",   "citizenship_code");
	ListOfMatches.Insert("RegistrarSResidentialAddress",     "residence_address");
	ListOfMatches.Insert("RegistrarSDateOfBirth",        "date_of_birth");
	ListOfMatches.Insert("RegistrarSPlaceOfBirth",       "place_of_birth");
	ListOfMatches.Insert("GenderOfRegistrar",                 "gender");
	ListOfMatches.Insert("LegalNameOfCompany", "legal_name");
	ListOfMatches.Insert("CompanyIsRegisteredInCountry", "registered_office_code");
	ListOfMatches.Insert("CompanyOfficeAddress",              "registered_office_address");
	ListOfMatches.Insert("CompanyRegistrationNumber",    "registration_number");
	
	Return ListOfMatches;
	
EndFunction	

#EndRegion

#Region Private

// Adds a property to the structure
//
// Parameters:
//  RequestBody - Structure - structure to add the property to
//  Name_Property - String - the name of the property
//  PropertyValue - String - Property value
//
Procedure AddProperty(RequestBody, Val Name_Property, PropertyValue)

	RequestBody.Insert(Name_Property, PropertyValue);	

EndProcedure 

#EndRegion
