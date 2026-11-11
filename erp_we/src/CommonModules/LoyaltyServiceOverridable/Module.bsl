///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Checks the usage of the loyalty server library
//
// Parameters:
//  Response		 - HTTPServiceResponse	 - Loyalty server response.
//  Result	 - Boolean			 - True if the Loyalty Server is used, False if not used.
//
Procedure UseLoyaltyServer(Response, Result) Export
	
	LoyaltyServerDataProviderTM.UseLoyaltyServer(Response, Result);
	
EndProcedure

// Fills in the bonus program on the buyer's discount card
//
// Parameters:
//  DiscountCard				 - DefinedType.LoyaltyCardOfLoyaltyServer	 -The loyalty card that will be used to fill in the bonus data.
//  LoyaltyProgram	 - DefinedType.BonusProgramLoyaltyServer - Bonus loyalty program.
//
Procedure FillOutBonusProgramOnDiscountCard(DiscountCard, LoyaltyProgram) Export
	
	LoyaltyServerDataProviderTM.FillOutBonusProgramOnDiscountCard(DiscountCard, LoyaltyProgram);
	
EndProcedure

// Fills in the structure of the Loyalty Server response with data on the Balance of bonus points
//
// Parameters:
//  DiscountCard	 - DefinedType.LoyaltyCardOfLoyaltyServer	 - loyalty card that will be used to fill in bonus data
//  ResponseStructure	 - See LoyaltyService.GetResponseParametersClientBonuses
//
Procedure FillInBonusDetails(DiscountCard, ResponseStructure) Export
	
	LoyaltyServerDataProviderTM.FillInBonusDetails(DiscountCard, ResponseStructure);
	
EndProcedure

// Performs processing of the State of customer bonuses
//  The presence of blocked customer bonuses is being checked
//  If such are found and the expiration time for them has expired, they are unblocked.
//
Procedure ProcessingStatusOfBonuses() Export

EndProcedure

// Gets the currency code
//
// Parameters:
//  CurrencyCode_	 - String	 - currency code.
//
Procedure GetCurrencyCode(CurrencyCode_ = "") Export
	

	
EndProcedure

// Checks the client's card parameter based on parameters received via the http service
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing client parameters:
//  * IdOfClientSCard - String - loyalty card code
//  * Client - String - Full name of the cardholder
//  * EMAddress - String - e-mail address of the cardholder
//  * PhoneNumber - String - phone number of the cardholder
//  ResponseStructure	 - See LoyaltyService.
//
Procedure CheckClientSCardDetails(MethodParameters, ResponseStructure) Export
	LoyaltyServerDataProviderTM.CheckClientSCardDetails(MethodParameters, ResponseStructure);
EndProcedure

// Searches for the client's card based on parameters received via the http service
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing client parameters:
//  	* IdOfClientSCard - String - loyalty card code
//  	* Client - String - Full name of the cardholder
//  	* EMAddress - String - e-mail address of the cardholder
//  	* PhoneNumber - String - phone number of the cardholder
//  Result		 - DefinedType.LoyaltyCardOfLoyaltyServer, Undefined - customer's discount card
//
Procedure FindCustomerCard(MethodParameters, Result = Undefined) Export
	
	LoyaltyServerDataProviderTM.FindCustomerCard(MethodParameters, Result);
	
EndProcedure

// Creates customer cards
//
// Parameters:
//  CardData		 - Structure - structure containing loyalty card data:
//  	* IdOfClientSCard - String - loyalty card code
//  	* Client - String - Full name of the cardholder
//  	* EMAddress - String - e-mail address of the cardholder
//  	* PhoneNumber - String - phone number of the cardholder
//  Result		 - DefinedType.LoyaltyCardOfLoyaltyServer, Undefined - contains the value
//  							in which the link to the created loyalty card will be stored.
//  OtherClient	 - CatalogRef.Counterparties	 - counterparty with a matching e-mail, but a different phone number
//  ErrorDescription	 - String	 - detailed description of the error
//
Procedure CreateCustomerCard(CardData, Result = Undefined, OtherClient = Undefined, ErrorDescription = "") Export
	
	LoyaltyServerDataProviderTM.CreateCustomerCard(CardData, Result, OtherClient, ErrorDescription);
	
EndProcedure

// Fills in the http service response structure with discount card data
//
// Parameters:
//  DiscountCard	 - DefinedType.LoyaltyCardOfLoyaltyServer	 - Loyalty card.
//  ResponseStructure	 - See LoyaltyService.GetResponseParametersOfClientSCard.ResponseStructure
//  MapExists	 - Boolean											 - Indicates the presence of a card.
//
Procedure FillInResponseStructureWithMapData(DiscountCard, ResponseStructure, MapExists = False) Export 
	
	LoyaltyServerDataProviderTM.FillInResponseStructureWithMapData(DiscountCard, ResponseStructure, MapExists);
	
EndProcedure

// Fills the http service response structure with client data
//
// Parameters:
//  Client			 - CatalogRef.Counterparties	 - The owner of the loyalty card.
//  ResponseStructure	 - See LoyaltyService.GetResponseParametersOfClientSCard.ResponseStructure
//
Procedure FillInResponseStructureWithClientData(Client, ResponseStructure) Export
	
	LoyaltyServerDataProviderTM.FillInResponseStructureWithClientData(Client, ResponseStructure);
	
EndProcedure

// Searches for a gift card based on parameters received via the http service
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing the parameters of a gift card
//  					See LoyaltyService.
//  Result		 - Structure - data of the gift card found:
//  * SerialNumber		 - DefinedType.SerialNumberLoyaltyServer
//  * GiftCertificate - DefinedType.GiftCardLoyaltyServer
//
Procedure FindGiftCard(MethodParameters, Result) Export
	

	
EndProcedure

// Searches for a promo code based on parameters received via the http service
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing the parameters of a gift card
//  							See LoyaltyService.PromoCodeRequestParameters
//  Result		 - Structure - data of the gift card found:
//  * PromoCode		 - DefinedType.PromoCodeLoyaltyServer - The value of the transmitted promo code
//  * AvailableApplications - Number - the number of available applications. 0 when the promo code is not available.
//  * ErrorDescription - String - Optional. When the promo code is not available, an explanation is returned as to why
//  							it is not available.
//
Procedure FindPromoCode(MethodParameters, Result) Export
	

	
EndProcedure

// Returns data about the gift card
//
// Parameters:
//  CertificateData	 - Structure - contains the data of the gift certificate:
//  * SerialNumber		 - DefinedType.SerialNumberLoyaltyServer
//  * GiftCertificate - DefinedType.GiftCardLoyaltyServer
//  ResponseStructure		 - Structure - contains data about the certificate balance,
// 								 See LoyaltyService.
//
Procedure GetGiftCardBalance(CertificateData, ResponseStructure) Export
	

	
EndProcedure

// Returns data about the State of the promo code
//
// Parameters:
//  PromoCodeData			 - Structure - contains the data of the gift card.
//  							See LoyaltyService.PromoCodeRequestParameters
//  ResponseStructure			 - Structure - contains data about the certificate balance,
//  							See LoyaltyService.
//  ReservePromoCode	 - Boolean	 - Reserve the use of a promo code.
//
Procedure GetStateOfPromoCode(PromoCodeData, ResponseStructure, ReservePromoCode = False) Export
	

	
EndProcedure

// Fills in the parameters of the client's card template
//
// Parameters:
//  CardData - Structure - structure containing loyalty card data:
//    * IdOfClientSCard	 - String - loyalty card code.
//    * Client						 - String - Full name of the cardholder.
//    * EMAddress						 - String - the cardholder's email address.
//    * PhoneNumber				 - String - the cardholder's phone number.
//  TemplateStructure - Structure - contains data from the discount card registration template.
//
Procedure FillInMapTemplateParameters(CardData, TemplateStructure) Export

EndProcedure

// Returns data about the use of automatic discounts
//
// Parameters:
//  Result	 - Boolean	 - True, automatic discounts are used,
//  							False, automatic discounts are not used.
//
Procedure UseAutomaticDiscounts(Result) Export
	
	LoyaltyServerDataProviderTM.UseAutomaticDiscounts(Result);
	
EndProcedure

// Returns data on the use of counterparty bonuses
//
// Parameters:
//  Result	 - Boolean	 - True, used,
//  							False, not used.
//
Procedure UseCounterpartyBonuses(Result) Export
	

	
EndProcedure

// Calculates automatic discounts
//
// Parameters:
//  CalculationParameters - Structure - See DeserializeCalculationParameters.
//  Result		 - Structure - a data structure with calculated automatic discounts.
//
Procedure CalculateAutoDiscounts(CalculationParameters, Result) Export
	
	LoyaltyServerDataProviderTM.CalculateAutoDiscounts(CalculationParameters, Result);
	
EndProcedure

// Deserializes parameters for calculating automatic discounts received in JSON format
//
// Parameters:
//  IncomingData	 - String	 - contains the string value of the request body in JSON format.
//  Result		 - Structure - data structure with deserialized parameters for calculating automatic discounts:
//   * InputParameters				 - Structure:
//    ** OnlyPreliminaryCalculation - Boolean
//   * Goods							 - ValueTable
//   * ManagementAccountingCurrency		 - CatalogRef.Currencies
//   * JointApplicationOption	 - EnumRef.OptionsOfJointUsageOfDiscountsAndMarkups
//   * User					 - Undefined
//   * CurrentDate						 - Date
//   * Date							 - Date
//   * OnlyMessagesAfterRegistration	 - Boolean
//   * Recorder						 - DocumentRef.CashRegisterReceipt
//   * Ref							 - DocumentRef.CashRegisterReceipt
//   * AmountIncludesVAT				 - Boolean
//   * DiscountsAreCalculated				 - Boolean
//   * DiscountCard					 - DefinedType.LoyaltyCardOfLoyaltyServer
//   * TypeOfDiscountCard				 - Undefined
//   * Counterparty						 - Undefined
//   * DiscountPercentageOnDiscountCard	 - Number
//   * Store							 - Undefined
//   * DiscountsMarkups					 - ValueTable -
//   * PricesKind							 - CatalogRef.TypesOfPrices
//   * DocumentCurrency					 - CatalogRef.Currencies
//   * GetDiscountsOfFoundationDocumentFromServer - Boolean
//
Procedure DeserializeCalculationParameters(IncomingData, Result) Export
	
	LoyaltyServerDataProviderTM.DeserializeCalculationParameters(IncomingData, Result);
	
EndProcedure

// Checks the gift card for the fact of sale/debiting.
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing the parameters of a gift card:
//  * CertificateNumber - String - the gift card number.
//  ResponseStructure	 - Structure - a structure containing response parameters:
//  * GiftCardUsed - Boolean - indicates that the gift card has been used before.
//
Procedure CheckGiftCard(MethodParameters, ResponseStructure) Export
	

	
EndProcedure

// Checks the use of the gift card payment function
//
// Parameters:
//  Result	 - Boolean	 - the variable in which the result of checking the use
//  							of the gift card payment function will be recorded.
//
Procedure CheckUseOfGiftCards(Result) Export
	
	LoyaltyServerDataProviderTM.CheckUseOfGiftCards(Result);
	
EndProcedure

// Returns data structure about Cur sales bans
//
// Parameters:
//  MethodParameters	 - Structure		 - a set of parameters for getting data on sales bans.
//											See LoyaltyService.
//  Result		 - Structure, Undefined	 - contains data about sales bans
//  							See LoyaltyService.
//
Procedure DataOnSalesBans(MethodParameters, Result) Export
	

	
EndProcedure

// Receives series data by GUID
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing the parameters of a gift card:
//  * GUIDBatch - String - GUID series.
//  ResponseStructure	 - Structure - a structure containing response parameters:
//  * NameBatch - String - The name of the series.
//
Procedure GetBatchData(MethodParameters, ResponseStructure) Export
	

	
EndProcedure

// Fills in the received structure of Attributes with the names of the Attributes of the sales document (Receipt)
//
// Parameters:
//  AttributesNames	  - Undefined,Structure - Names of Attributes of the data provider:
//  	* BankingDetailsNameDiscountCard - String
//  	* DetailsNamePaymentTable - String
//  	* PropsNameGiftCard - String
//  	* PropsNameSerialNumber - String
//  	* DetailsNameBonusAmount - String
//  	* DetailsNameCertificateRedemptionTable - String
//  	* DetailsNameCertificateRedemptionAmount - String
//
Procedure FillInNamesOfAttributesOfDataProvider(AttributesNames) Export
	
	LoyaltyServerDataProviderTM.FillInNamesOfAttributesOfDataProvider(AttributesNames);
	
EndProcedure

// Fills in the list of managed discounts
//
// Parameters:
//  Result		 - ValueTable - the return value.
//  CalculationParameters - Structure					 - a structure containing the selection parameters of managed discounts.
//  													SeeLoyaltyService.RequestParametersManagedDiscounts
//
Procedure FillInTableOfManagedDiscounts(Result, CalculationParameters) Export
	
	LoyaltyServerDataProviderTM.FillInTableOfManagedDiscounts(Result, CalculationParameters);
	
EndProcedure

// Fills in the list of discounts that depend on the selected payment
//
// Parameters:
//  Result	 - Undefined, ValueTable - the return value.
//
Procedure FillInTableOfDiscountsDependingOnTypeOfPayment(Result) Export
	

	
EndProcedure

// Fills in the structure of parameters from the http request
//
// Parameters:
//  IncomingData	 - String	 - contains the string value of the request body in JSON format.
//  Result		 - Structure - contains a set of parameters that can be passed via an http request:
//  * Products 	- String
//  * Characteristic 	- String
//  * Package 		- String
//
Procedure ParametersFromGetBalancesRequest(IncomingData, Result) Export
	
	LoyaltyServerDataProviderTM.ParametersFromGetBalancesRequest(IncomingData, Result);
	
EndProcedure

// Fills in the data on the Balance of the goods
//
// Parameters:
//  MethodParameters	 - Structure - contains parameters for obtaining Balances,
//  								See LoyaltyServiceOverridable.ParametersFromGetBalancesRequest
//  ResponseStructure	 - Structure - contains data about the certificate balance,
//  								See LoyaltyService.GetResponseParametersBalances
//
Procedure GetBalance(MethodParameters, ResponseStructure) Export
	
	LoyaltyServerDataProviderTM.BalancesByItemByWarehousesAndCharacteristics(MethodParameters, ResponseStructure);
	
EndProcedure

// Fills in the array of promo codes used in the document
//
// Parameters:
//  Document		 - DocumentRef	 - link to the document using promo codes.
//  ArrayOfPromoCodes - Array of String	 - Array of applied promo codes
//
Procedure GetUsedPromoCodes(Document, ArrayOfPromoCodes) Export
	

	
EndProcedure

// Fills in the http service response structure with the data of the found maps
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing map search parameters:
//  * IdOfClientSCard - String - loyalty card code
//  * PhoneNumber - String - phone number or the last part of the phone number to search for
//  * EMAddress - String - the cardholder's email address for the search
//  ResponseStructure	 - See LoyaltyService.GetResponseParametersListOfLoyaltyCards
//
Procedure FindLoyaltyCards(MethodParameters, ResponseStructure) Export
	
	LoyaltyServerDataProviderTM.FindLoyaltyCards(MethodParameters, ResponseStructure);
	
EndProcedure

// Fills in the customer loyalty card
//
// Parameters:
//  UniqueIdentifierString	 - String						 - unique card ID,
//  CustomerCard					 - DefinedType.LoyaltyCardOfLoyaltyServer	 - Customer Card
//
Procedure GetCustomerCardWithUniqueIdentifier(UniqueIdentifierString, CustomerCard) Export
	
	LoyaltyServerDataProviderTM.GetCustomerCardWithUniqueIdentifier(UniqueIdentifierString, CustomerCard);
	
EndProcedure

// Fills in the http service response structure with the discount card numbers and unique identifier
//
// Parameters:
//  CustomerCard	 - DefinedType.LoyaltyCardOfLoyaltyServer	 - Loyalty card.
//  ResponseStructure	 -  See LoyaltyService.GetResponseParametersClientBonuses
//
Procedure FillInResponseStructureWithCardNumbers(CustomerCard, ResponseStructure) Export
	
	LoyaltyServerDataProviderTM.FillInResponseStructureWithCardNumbers(CustomerCard, ResponseStructure);
	
EndProcedure

// Fills in the list of card types
//
// Parameters:
//  Result		 - Undefined, ValueTable - returned value
//  CalculationParameters - Structure					 - a structure containing settings for working with types of discount cards
//														SeeLoyaltyService.RequestParametersTypesOfDiscountCards
//
Procedure FillInTableOfCardTypes(Result, CalculationParameters) Export
	
	LoyaltyServerDataProviderTM.FillInTableOfCardTypes(Result, CalculationParameters);
	
EndProcedure

// Fills in the structure of the Loyalty Server response with turnover data
//
// Parameters:
//  DiscountCard	 - DefinedType.LoyaltyCardOfLoyaltyServer	 - loyalty card that will be used to fill in bonus data
//  ResponseStructure	 - See LoyaltyService.GetResponseParametersSalesTurnover
//
Procedure FillInSalesTurnoverData(DiscountCard, ResponseStructure) Export
	
	LoyaltyServerDataProviderTM.FillInSalesTurnoverData(DiscountCard, ResponseStructure);
	
EndProcedure

// The parameters of the list of employees received in JSON format are deserialized
//
// Parameters:
//  IncomingData	 - String	 - contains the string value of the request body in JSON format.
//  Result		 - Structure - data structure with employee list parameters:
//  * Store							 - Undefined
//
Procedure DeserializeCalculationParametersListOfEmployees(IncomingData, Result) Export
	

	
EndProcedure

// The parameters of the series received in JSON format are deserialized
//
// Parameters:
//  IncomingData	 - String	 - contains the string value of the request body in JSON format.
//  Result		 - Structure - data structure with series parameters:
//  * InputParameters					 - Structure
//  * Store							 - Undefined
//
Procedure DeserializeBatchParameters(IncomingData, Result) Export
	

	
EndProcedure

// Fills in the list of employees
//
// Parameters:
//  CalculationParameters - Structure				 - For calculation parameters, see Structuratablity of employees
//  Result		 - ValueTable - returned value
//
Procedure FillInEmployeeTable(CalculationParameters, Result) Export
	

	
EndProcedure

// Fills in the list of series
//
// Parameters:
//  CalculationParameters - Structure - Calculation parameters
// 									See LoyaltyService.ParametersForRequestingListOfSeries
//  Result		 - Structure - series structure - return value
//
Procedure FillInListOfBatches(CalculationParameters, Result) Export
	

	
EndProcedure


// The procedure receives the current price of the goods according to the parameters
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing the parameters for getting the price:
//  * GUIDBatch - String - GUID series.
//  * GUIDPriceType - String - Price view GUIDE.
//  * ItemGUIDE - String - The nomenclature GUIDE.
//  * Characteristic - String - GUID characteristics.
//  ResponseStructure	 - Structure - a structure containing response parameters:
//  * Price - Number - the current price of the item.
//
Procedure GetRelevantPrice(MethodParameters, ResponseStructure) Export
	
	
EndProcedure

// Checks the fullness of the bonus program in the loyalty card
//
// Parameters:
//  CustomerCard				 - DefinedType.LoyaltyCardOfLoyaltyServer	 - The loyalty card that will be used to fill in the bonus data.
//  BonusBlockingIsRequired	 - Boolean											 - a sign of the need to block bonuses
//
Procedure CheckBonusProgram(CustomerCard, BonusBlockingIsRequired) Export
	

	
EndProcedure

// Deserializes request parameters received in JSON format
//
// Parameters:
//  IncomingData	 - String	 - contains the string value of the request body in JSON format.
//  Result		 - Structure - data structure with deserialized parameters for calculating automatic discounts:
//  * BonusCards							 - ValueTable
//  * BonusProgram						 - CatalogRef.LoyaltyPrograms
//
Procedure MethodParametersFromCombineBonusCardsRequest(IncomingData, Result) Export
	

	
EndProcedure

// Creates write-off and accrual of bonuses based on received parameters from the loyalty server
//
// Parameters:
//  MethodParameters	 - Structure - a structure containing parameters for debiting/accruing bonus points:
//  * BonusProgram - CatalogRef.LoyaltyPrograms - bonus program.
//  * BonusCard - DefinedType.LoyaltyCardOfLoyaltyServer - bonus accrual card.
//  * TableOfBonusCards - ValueTable - Table of bonus cards.
//  ResponseStructure	 - Structure - a structure containing response parameters:
//  * HasErrors - Boolean - indicates whether there were errors when executing the method.
//  * ErrorText - Boolean - indicates whether there were errors when executing the method.
//
Procedure CombineBonusCards(MethodParameters, ResponseStructure) Export
	

	
EndProcedure

// Deserializes request parameters received in JSON format
//
// Parameters:
//  IncomingData	 - String	 - contains the string value of the request body in JSON format.
//  Result		 - Structure - data structure with deserialized parameters for calculating automatic discounts:
//  * GiftCertificate				- CatalogRef.Products
//  * GiftCardNumber		- CatalogRef.ItemsBatches
//  * Goods							- ValueTable
//
Procedure MethodParametersFromGetGiftCardDataRequest(IncomingData, Result) Export
	

	
EndProcedure

// Fills in the gift card table with accrual data
//
// Parameters:
//  Object							 - DocumentObject.CashRegisterReceipt - register adjustment document.
//  TableOfGiftCertificates	 - ValueTable - The table of debiting and accrual of gift cards.
//
Procedure FillOutAccrualsForGiftCards(Object, TableOfGiftCertificates) Export

EndProcedure

// Sets the sold Status of the Gift card batch
//
// Parameters:
//  CertificateData	 - Structure - data of the gift card found:
//  * SerialNumber		 - DefinedType.SerialNumberLoyaltyServer
//  * GiftCertificate - DefinedType.GiftCardLoyaltyServer
//  WasSold				 - 	Boolean - The Status of the serial number of the gift card.
//
Procedure SetStatusOfGift(CertificateData, WasSold) Export
	

	
EndProcedure

// The function returns an array of gift cards from the passed array that have the "Gift Certificate accepts a payment from a Member organization" attribute.
//
// Parameters:
//  ArrayOfCertificators - Array of DefinedType.GiftCardLoyaltyServer - array of links to gift cards.
//  Result 			- Array of DefinedType.GiftCardLoyaltyServer - Gift cards with activated company control.
//
Procedure SelectCertificatesWithCompanyControl(ArrayOfCertificators, Result) Export
	 


EndProcedure

// Sets the control attribute of the company that originally sold this certificate
//
// Parameters:
//  GiftCertificate	 	- DefinedType.GiftCardLoyaltyServer - The batch of the gift card
//  Result					- Boolean - A sign that the company needs to be monitored.
Procedure FillInControlSignForGiftCardCompanies(GiftCertificate, Result) Export

EndProcedure

#EndRegion
