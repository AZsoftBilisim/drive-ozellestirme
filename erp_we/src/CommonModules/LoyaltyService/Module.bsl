///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Checks the blocking of client bonuses
//
// Parameters:
//  DiscountCard - DefinedType.LoyaltyCardOfLoyaltyServer - client's card.
//
// Returns:
//  Boolean - True if there is a bonus lock, False if there is no lock.
//
Function BonusesAreBlocked(DiscountCard) Export

	Query = New Query;
	Query.Text = 
		"SELECT
		|	BonusPointState.DiscountCard AS DiscountCard,
		|	BonusPointState.LockDate AS LockDate
		|FROM
		|	InformationRegister.BonusPointState AS BonusPointState
		|WHERE
		|	BonusPointState.DiscountCard = &DiscountCard";
	
	Query.SetParameter("DiscountCard", DiscountCard);
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

// Blocks the client's bonuses after the Loyalty Service responds to prevent double debiting
//
// Parameters:
//  DiscountCard - DefinedType.LoyaltyCardOfLoyaltyServer - client's card.
//  LockDate  - Date - date and time of bonus blocking.
//
Procedure BlockBonuses(DiscountCard, LockDate) Export
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.BonusPointState");
	LockItem.SetValue("DiscountCard", DiscountCard);
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet = InformationRegisters.BonusPointState.CreateRecordSet();
		RecordSet.Filter.DiscountCard.Set(DiscountCard);
		RegisterRecord = RecordSet.Add();
		RegisterRecord.DiscountCard = DiscountCard;
		RegisterRecord.LockDate = LockDate;
		RecordSet.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Unlocks client bonuses
//
// Parameters: 
//  DiscountCard - DefinedType.LoyaltyCardOfLoyaltyServer - Customer Card
//
Procedure UnlockBonuses(DiscountCard) Export
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.BonusPointState");
	LockItem.SetValue("DiscountCard", DiscountCard);
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet = InformationRegisters.BonusPointState.CreateRecordSet();
		RecordSet.Filter.DiscountCard.Set(DiscountCard);
		RecordSet.Read();
		RecordSet.Clear();
		RecordSet.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Deducts client bonuses
//
// Parameters:
//  DiscountCard				 - DefinedType.LoyaltyCardOfLoyaltyServer	 - client's card.
//  NumberOfBonusesToWriteOff	 - Number - The number of bonuses to be debited.
//  NumberOfBonusesToAccrual - Number - The number of bonuses to be credited.
//
Procedure WriteOffAddBonuses(DiscountCard, NumberOfBonusesToWriteOff, NumberOfBonusesToAccrual) Export
	
	SetPrivilegedMode(True);
	
	LoyaltyProgram = Undefined;
	LoyaltyProgram = Metadata.DefinedTypes.BonusProgramLoyaltyServer.Type.AdjustValue(LoyaltyProgram);
	
	LoyaltyServiceOverridable.FillOutBonusProgramOnDiscountCard(DiscountCard, LoyaltyProgram);
	
	PointReserves = GetBonusPointsReserve(DiscountCard);
	
	RecordManager = InformationRegisters.BonusPointsToWriteOffAndAccrue.CreateRecordManager();
	RecordManager.LoyaltyProgram = LoyaltyProgram;
	RecordManager.DiscountCard = DiscountCard;
	RecordManager.ToWriteOff = NumberOfBonusesToWriteOff + PointReserves.BonusesForWriteOff;
	RecordManager.ToAccrue = NumberOfBonusesToAccrual + PointReserves.AccrualBonuses;
	RecordManager.Write(True);
	
	UnlockBonuses(DiscountCard);
	
	SetPrivilegedMode(False);
	
EndProcedure

#Region CalculationParameters
// Returns the structure of the discount card search parameters from an http request
//
// Parameters:
//  Query		 - Structure - Parameters of the http request.
//  Result	 - Structure - contains a set of parameters that can be passed via an http request:
//  * IdOfClientSCard 	- String - Discount card number.
//  * UniqueCardId 	- String - Unique ID of the discount card.
//  * PhoneNumber 				- String - The phone number of the discount card holder.
//  * EMAddress 						- String - The discount card holder's email Mail.
//
Procedure ClientCardDataParameters(Query, Result) Export
	
	MethodParameters = New Structure;
	
	MethodParameters.Insert("IdOfClientSCard"		,	Query["QueryOptions"].Get("ClientCardID"));
	MethodParameters.Insert("UniqueCardId"	, 	Query["QueryOptions"].Get("CardGUID"));
	MethodParameters.Insert("PhoneNumber"					,	Query["QueryOptions"].Get("Phone"));
	MethodParameters.Insert("EMAddress"						, 	Query["QueryOptions"].Get("Email"));
	MethodParameters.Insert("BonusBlockingIsRequired"		, 	True);
	MethodParameters.Insert("CardReplacementMode"				, 	ConvertMethodParameterToBoolean(Query["QueryOptions"].Get("Replacement")));
	
	Result = MethodParameters;
	
EndProcedure

// The procedure supplements the method execution parameters with additional calculation parameters
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure AddParametersToIssueCardMethod(Query, MethodParameters) Export
	MethodParameters.Insert("Store"					, Query["QueryOptions"].Get("Store"));
	MethodParameters.Insert("MapViewGUIDE"			, Query["QueryOptions"].Get("ClientCardTypeUID"));
	MethodParameters.Insert("Client"					, Query["QueryOptions"].Get("Client"));
	MethodParameters.Insert("BirthDate"				, Query["QueryOptions"].Get("DateOfBirth"));
EndProcedure

// The procedure fills in the parameters of the sales ban information method.
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure ParametersOfSalesBansMethod(Query, MethodParameters) Export
	MethodParameters = New Structure;
	MethodParameters.Insert("Store"					, Query["QueryOptions"].Get("Store"));
EndProcedure

// The procedure fills in the parameters of the get gift card data method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure GiftCardParameters(Query, MethodParameters) Export
	MethodParameters = New Structure;
	MethodParameters.Insert("CertificateNumber"			, Query["QueryOptions"].Get("GiftCardNumber"));
	MethodParameters.Insert("CertificateGUIDE"			, Query["QueryOptions"].Get("GiftCardUID"));
	MethodParameters.Insert("CompanyGUIDE"			, Query["QueryOptions"].Get("Organization"));
EndProcedure

// The procedure complements the parameters of the calculate gift card method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure AddParametersToAddGiftCardMethod(Query, MethodParameters) Export
	MethodParameters.Insert("AccrualAmount"			, ConvertMethodParameterToNumber(Query["QueryOptions"].Get("GiftCardAccrueOffAmount")));
EndProcedure

// The procedure complements the parameters of the Write off gift card method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure AddParametersToWriteOffGiftCardMethod(Query, MethodParameters) Export
	MethodParameters.Insert("DebitedAmount"			, ConvertMethodParameterToNumber(Query["QueryOptions"].Get("GiftCardWriteOffAmount")));
EndProcedure

// The procedure fills in the parameters of the get list of managed discounts method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure RequestParametersManagedDiscounts(Query, MethodParameters) Export
	MethodParameters = New Structure;
	MethodParameters.Insert("UniqueCardId"	, Query["QueryOptions"].Get("CardGUID"));
	MethodParameters.Insert("IdOfClientSCard"	, Query["QueryOptions"].Get("ClientCardID"));
	MethodParameters.Insert("MaxDiscountPercentage"	, ConvertMethodParameterToNumber(Query["QueryOptions"].Get("MaxSale")));
	MethodParameters.Insert("MaxMarkupPercentage"	, ConvertMethodParameterToNumber(Query["QueryOptions"].Get("MaxMarkup")));
	MethodParameters.Insert("UseSelections"			, ConvertMethodParameterToBoolean(Query["QueryOptions"].Get("UseSelection")));
	MethodParameters.Insert("Client"						, Query["QueryOptions"].Get("Client"));
	MethodParameters.Insert("Store"						, Query["QueryOptions"].Get("Store"));
	ParameterValue = Query["QueryOptions"].Get("DiscountsAllowed");
	If ParameterValue = Undefined Then
		MethodParameters.Insert("DiscountsAreAllowed", True);
	Else
		MethodParameters.Insert("DiscountsAreAllowed"	, ConvertMethodParameterToBoolean(ParameterValue));
	EndIf;
EndProcedure

// The procedure fills in the parameters of the get promo code data method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure PromoCodeRequestParameters(Query, MethodParameters) Export
	MethodParameters = New Structure;
	MethodParameters.Insert("PromoCode"					, Query["QueryOptions"].Get("Promocode"));
EndProcedure

// The procedure fills in the parameters of the get types of discount cards method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure RequestParametersTypesOfDiscountCards(Query, MethodParameters) Export
	MethodParameters = New Structure;
	MethodParameters.Insert("Store"						, Query["QueryOptions"].Get("Store"));
EndProcedure

// The procedure fills in the parameters of the get list of sellers method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure ParametersForRequestingListOfSellers(Query, MethodParameters) Export
	MethodParameters = New Structure;
	MethodParameters.Insert("Store"						, Query["QueryOptions"].Get("Store"));
EndProcedure

// The procedure fills in the parameters of the get a list of series method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure ParametersForRequestingListOfSeries(Query, MethodParameters) Export
	MethodParameters = New Structure;
	MethodParameters.Insert("ItemGUIDE"			, Query["QueryOptions"].Get("Product"));
	MethodParameters.Insert("Characteristic"			, Query["QueryOptions"].Get("Characteristic"));
	MethodParameters.Insert("ProductKind"			, Query["QueryOptions"].Get("TypeProduct"));
	MethodParameters.Insert("Store"					, Query["QueryOptions"].Get("Store"));
	MethodParameters.Insert("Sale"					, ConvertMethodParameterToBoolean(Query["QueryOptions"].Get("TypeOperationSale")));
EndProcedure

// The procedure fills in the parameters of the get series data method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure RequestParametersSeriesData(Query, MethodParameters) Export
	MethodParameters = New Structure;
	MethodParameters.Insert("GUIDBatch"				, Query["QueryOptions"].Get("BatchUID"));
EndProcedure

// The procedure fills in the parameters of the get current price method
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure ParametersOfCurrentPriceRequest(Query, MethodParameters) Export
	
	MethodParameters = New Structure;
	MethodParameters.Insert("GUIDPriceType"				, Query["QueryOptions"].Get("TypePriceUID"));
	MethodParameters.Insert("Characteristic"			, Query["QueryOptions"].Get("Characteristic"));
	MethodParameters.Insert("ItemGUIDE"			, Query["QueryOptions"].Get("Product"));
	MethodParameters.Insert("GUIDBatch"				, Query["QueryOptions"].Get("BatchUID"));
	
EndProcedure

// Returns the structure of parameters from the client's http map search request
//
// Parameters:
//  Query - Structure - Parameters of the http request.
//  Result - Structure - contains a set of parameters that can be passed via an http request:
//    * IdOfClientSCard 						- String
//    * PhoneNumber 									- String
//    * EMAddress 										- String
//    * BlockCard 								- Boolean
//    * UniqueIdOfCardholder 			- String
//
Procedure MethodParametersFromFindClientCardRequest(Query, Result) Export
	
	MethodParameters = New Structure;
	
	MethodParameters.Insert("IdOfClientSCard"				, Query["QueryOptions"].Get("ClientCardID"));
	MethodParameters.Insert("PhoneNumber"							, Query["QueryOptions"].Get("Phone"));
	MethodParameters.Insert("EMAddress"								, Query["QueryOptions"].Get("Email"));
	MethodParameters.Insert("BlockCard"						, Query["QueryOptions"].Get("BlockBonuses"));
	MethodParameters.Insert("UniqueIdOfCardholder"	, Query["QueryOptions"].Get("ClientGUID"));
	MethodParameters.Insert("UniqueCardId" 			, Query["QueryOptions"].Get("CardGUID"));
	MethodParameters.Insert("CounterpartySFullName" 						, Query["QueryOptions"].Get("ClientID"));
	
	Result = MethodParameters;
	
EndProcedure

// The procedure supplements the method execution parameters with additional calculation parameters
//
// Parameters:
//  Query			 - Structure - Parameters of the http request.
//  MethodParameters	 - Structure - Method execution parameters.
//
Procedure AddBonusMethodParameters(Query, MethodParameters) Export
	MethodParameters.Insert("NumberOfBonusPoints"	, 		ConvertMethodParameterToNumber(Query["QueryOptions"].Get("BonusesCount")));
EndProcedure
#EndRegion

#Region AnswerParameters

// Returns the structure of the response parameters connection to the loyalty server
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//    * Connection 				- Boolean
//
Procedure GetParametersOfConnectionVerificationResponse(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("Connection", False);
	
EndProcedure

// Returns the structure of the get client bonuses response parameters
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//    * BonusCount 				- Number
//    * BonusRate		 		- Number
//    * BonusCurrency			- String
//    * PaymentPercent 			- Number
//    * CardRef					- String
//    * Barcode					- String
//    * MagneticCode 			- String
//    * EndDate			 		- Date
//    * ClientNotFound 			- Boolean
//
Procedure GetResponseParametersClientBonuses(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	CurrencyCode_ = "";
	LoyaltyServiceOverridable.GetCurrencyCode(CurrencyCode_);
	ResponseStructure.Insert("BonusCount", 0);
	ResponseStructure.Insert("BonusLimitBalance", 0);
	ResponseStructure.Insert("BonusRate", 1);
	ResponseStructure.Insert("BonusCurrency", CurrencyCode_);
	ResponseStructure.Insert("PaymentPercent", 0);
	ResponseStructure.Insert("CardRef", "");
	ResponseStructure.Insert("Barcode", "");
	ResponseStructure.Insert("MagneticCode", "");
	ResponseStructure.Insert("EndDate", Date(1, 1, 1));
	ResponseStructure.Insert("ClientNotFound", True);
	
EndProcedure

// Returns the structure of the text message response parameters
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//    * TextMessage 			- String
//
Procedure GetTextMessageResponseParameters(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("TextMessage", "");
	
EndProcedure

// Returns the structure of response parameters based on loyalty card data
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//    * BonusCount 				- Number
//    * BonusRate		 		- Number
//    * BonusCurrency			- String
//    * PaymentPercent 			- Number
//    * ExistingCard 			- Boolean
//    * CardRef 				- String
//    * CardID 					- String
//    * Client 					- String
//    * PhoneNumber 			- String
//    * Email 					- String
//    * DateOfBirth 			- Date
//    * ElseClient 				- Boolean
//
Procedure GetResponseParametersOfClientSCard(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	CurrencyCode_ = "";
	LoyaltyServiceOverridable.GetCurrencyCode(CurrencyCode_);
		
	ResponseStructure.Insert("BonusCount", 0);
	ResponseStructure.Insert("BonusRate", 1);
	ResponseStructure.Insert("BonusCurrency", CurrencyCode_);
	ResponseStructure.Insert("PaymentPercent", 0);
	ResponseStructure.Insert("ExistingCard", True);
	ResponseStructure.Insert("CardRef", "");
	ResponseStructure.Insert("CardID", "");
	ResponseStructure.Insert("Client", "");
	ResponseStructure.Insert("PhoneNumber", "");
	ResponseStructure.Insert("Email", "");
	ResponseStructure.Insert("DateOfBirth", Date(1, 1, 1));
	ResponseStructure.Insert("ElseClient", False);
	
EndProcedure

// Returns the structure of response parameters based on sales ban data
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//    * AllowControl 			- Boolean
//    * RestrictionsList		- Array
//
Procedure GetResponseParametersInformationAboutSalesBans(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("AllowControl", True);
	ResponseStructure.Insert("RestrictionsList", New Array);
	ResponseStructure.Insert("TradeControlData", New Structure());
	
EndProcedure

// Returns the structure of the response parameters gift certificate data
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//    * GiftCard	 			- Structure:
//      * GiftCardName			- String
//      * GiftCardRef			- String
//    * GiftCardNumber			- String
//    * GiftCardValue			- Number
//    * GiftCardBalance			- Number
//    * GiftCardLimit			- Boolean
//    * GiftCardAvailable		- Number
//    * Blocked					- Boolean
//    * BalanceBurnout			- Boolean
//
Procedure GetResponseParametersGiftCardData(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	
	CertificateStructure1 = New Structure;
	CertificateStructure1.Insert("GiftCardName", "");
	CertificateStructure1.Insert("GiftCardRef", "");
		
	ResponseStructure.Insert("GiftCard", CertificateStructure1);
	ResponseStructure.Insert("GiftCardNumber", "");
	ResponseStructure.Insert("GiftCardValue", 0);
	ResponseStructure.Insert("GiftCardBalance", 0);
	ResponseStructure.Insert("GiftCardLimit", False);
	ResponseStructure.Insert("GiftCardAvailable", 0);
	ResponseStructure.Insert("Blocked", False);
	ResponseStructure.Insert("BalanceBurnout", False);
EndProcedure

// Returns the structure of the use automatic discounts response parameters
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//    * UseAutomaticDiscounts	- Boolean
//    * UseCounterpartyBonuses	- Boolean
//
Procedure GetResponseParametersUseAutomaticDiscounts(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("UseAutomaticDiscounts", False);
	ResponseStructure.Insert("UseCounterpartyBonuses", False);

EndProcedure

// Returns the structure of the response parameters calculation of discounts
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//
Procedure GetResponseParametersCalculationOfDiscounts(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	
EndProcedure

// Returns the structure of the response parameters checking the use of the gift certificate series
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 					- Boolean
//    * ErrorMessage 			- String
//    * Version 				- String
//    * GiftCardUsed 			- Boolean
//
Procedure GetResponseParametersForCheckingGiftCard(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("GiftCardUsed", False);
	
EndProcedure

// Returns the structure of the response parameters State of the promo code
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 								- Boolean
//    * ErrorMessage 						- String
//    * Version 							- String
//    * PromocodeIsAvalible					- Boolean
//    * PromocodeStatus						- String
//    * PromocodeDiscountDescription		- String
//    * PromocodeDiscount					- String
//
Procedure GetResponseParametersPromoCodeData(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("PromocodeIsAvalible", False);
	ResponseStructure.Insert("PromocodeStatus", "");
	ResponseStructure.Insert("PromocodeDiscountDescription", "");
	ResponseStructure.Insert("PromocodeDiscount", "");

	
EndProcedure

// Returns the structure of the response parameters for getting Balances
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 								- Boolean
//    * ErrorMessage 						- String
//    * Version 							- String
//    * LeftoversList						- Array
//
Procedure GetResponseParametersBalances(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("LeftoversList", New Array);

	
EndProcedure

// Returns the structure of the response parameters for receiving a list of loyalty cards
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 								- Boolean
//    * ErrorMessage 						- String
//    * Version 							- String
//    * LoyaltyCardsList					- Array
//
Procedure GetResponseParametersListOfLoyaltyCards(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("LoyaltyCardsList", New Array);
	
EndProcedure

// Returns the structure of the response parameters for receiving loyalty card sales turnover.
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 								- Boolean
//    * ErrorMessage 						- String
//    * Version 							- String
//    * CardRef								- String
//    * SellCount							- Number
//    * Barcode								- String
//    * MagneticCode						- String
//    * ClientNotFound						- Boolean
//
Procedure GetResponseParametersSalesTurnover(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("CardRef", "");
	ResponseStructure.Insert("SellCount", 0);
	ResponseStructure.Insert("Barcode", "");
	ResponseStructure.Insert("MagneticCode", "");
	ResponseStructure.Insert("ClientNotFound", True);
	
EndProcedure

// Returns the structure of the response parameters of the series data
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 								- Boolean
//    * ErrorMessage 						- String
//    * Version 							- String
//    * NameBatch							- String
//    * BatchUsed							- Boolean
//
Procedure GetResponseParametersSeriesData(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("NameBatch", "");
	ResponseStructure.Insert("BatchUsed", False);
	
EndProcedure

// Returns the structure of the response parameters of the current price
//
// Parameters:
//  ResponseStructure - Structure - contains a set of parameters for the response of the Loyalty http service:
//    * Error 								- Boolean
//    * ErrorMessage 						- String
//    * Version 							- String
//    * Price								- Number
//
Procedure GetParametersOfPriceRequestResponse(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("Price", 0);
	
EndProcedure

// Returns the structure of the response parameters of the current price
//
// Parameters:
//  ResponseStructure - Structure - It contains a set of response parameters for the Loyalty http service.
//
Procedure GetParametersOfStateIPAuthorizationToken(ResponseStructure) Export
	
	ResponseStructure = New Structure;
	GetGeneralResponseParameters(ResponseStructure);
	ResponseStructure.Insert("Organization", EmptyRef(Metadata.DefinedTypes.CompanyLoyaltyServer));
	
EndProcedure
#EndRegion

// Returns the number of reserved bonus points
//
// Parameters:
//  DiscountCard - DefinedType.LoyaltyCardOfLoyaltyServer
//
// Returns:
//  Number - the number of bonus points held in reserve
//
Function GetBonusPointsReserve(DiscountCard) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	SUM(BonusPointsToWriteOffAndAccrue.ToWriteOff) AS ToWriteOff,
	|	BonusPointsToWriteOffAndAccrue.DiscountCard AS DiscountCard,
	|	SUM(BonusPointsToWriteOffAndAccrue.ToAccrue) AS ToAccrue
	|FROM
	|	InformationRegister.BonusPointsToWriteOffAndAccrue AS BonusPointsToWriteOffAndAccrue
	|WHERE
	|	BonusPointsToWriteOffAndAccrue.DiscountCard = &DiscountCard
	|
	|GROUP BY
	|	BonusPointsToWriteOffAndAccrue.DiscountCard";
	
	Query.SetParameter("DiscountCard", DiscountCard);
	
	Selection = Query.Execute().Select();
	BonusesForWriteOff = 0;
	AccrualBonuses = 0;
	
	If Selection.Next() Then
		BonusesForWriteOff = Selection.ToWriteOff;
		AccrualBonuses = Selection.ToAccrue;
	EndIf;
	
	BonusReserves = New Structure;
	BonusReserves.Insert("BonusesForWriteOff", BonusesForWriteOff);
	BonusReserves.Insert("AccrualBonuses", AccrualBonuses);

	Return BonusReserves;
	
EndFunction

// Performs an adjustment of the register of information "Bonus points to write off"
//
// Parameters:
//  Object - DocumentObject.CashRegisterReceipt
//
Procedure AdjustInformationRegisterBonusPointsForDebiting(Object) Export
	
	SetPrivilegedMode(True);
	
	AttributesNames = New Structure;
	FillInEmptyStructureNamesOfMetadataAttributes(AttributesNames);
	
	LoyaltyServiceOverridable.FillInNamesOfAttributesOfDataProvider(AttributesNames);
	
	SourceMetadata = Object.Metadata();
	If SourceMetadata.Attributes.Find(AttributesNames.BankingDetailsNameDiscountCard) = Undefined Then
		Return;
	EndIf;
	DiscountCard = Object[AttributesNames.BankingDetailsNameDiscountCard];
	
	LoyaltyProgram = Undefined;
	LoyaltyServiceOverridable.FillOutBonusProgramOnDiscountCard(DiscountCard, LoyaltyProgram);
	
	TotalPoints = 0;
	ThereIsTableOfPayments = True;
	If SourceMetadata.TabularSections.Find(AttributesNames.DetailsNamePaymentTable) = Undefined Then
		ThereIsTableOfPayments = False;
	EndIf;
	
	If ThereIsTableOfPayments Then
		TableOfPayment = Object[AttributesNames.DetailsNamePaymentTable];
		For Each PaymentLine_ In TableOfPayment Do
			TotalPoints = TotalPoints + PaymentLine_[AttributesNames.DetailsNameBonusAmount];
		EndDo;
	EndIf;
	
	AmountOfPointsToAccrual = 0;
	ThereIsAccrualTable = True;
	If SourceMetadata.TabularSections.Find(AttributesNames.NameOfAttributeBonusPointsForAccrual) = Undefined Then
		ThereIsAccrualTable = False;
	EndIf;
	
	If ThereIsAccrualTable Then
		TableOfPointsToAccrual = Object[AttributesNames.NameOfAttributeBonusPointsForAccrual];
		For Each AccrualLine In TableOfPointsToAccrual Do
			AmountOfPointsToAccrual = AmountOfPointsToAccrual + AccrualLine[AttributesNames.NameOfAttributeAmountOfBonusesToBeAccrual];
		EndDo;
	EndIf;
	
	If TotalPoints > 0
		Or AmountOfPointsToAccrual > 0 Then
		RecordManager = InformationRegisters.BonusPointsToWriteOffAndAccrue.CreateRecordManager();
		
		RecordManager.DiscountCard = DiscountCard;
		RecordManager.LoyaltyProgram = LoyaltyProgram;
		RecordManager.Read();
		
		AmountOfWriteOffRecord = RecordManager.ToWriteOff;
		AccrualAmountRecord = RecordManager.ToAccrue;
		
		AmountOfWriteOffRecord = Max(AmountOfWriteOffRecord - TotalPoints, 0);
		AccrualAmountRecord = Max(AccrualAmountRecord - AmountOfPointsToAccrual, 0);
		If AmountOfWriteOffRecord <= 0
			And AccrualAmountRecord <= 0 Then
			RecordManager.Delete();
		Else
			RecordManager.ToWriteOff = AmountOfWriteOffRecord;
			RecordManager.ToAccrue = AccrualAmountRecord;
			RecordManager.Write(True);
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Performs adjustments to the register of information "Gift cards for debiting and accrual"
//
// Parameters:
//  Object - DocumentObject.CashRegisterReceipt
//
Procedure CorrectInformationRegisterGiftCardsToBeDebited(Object) Export
	
	SetPrivilegedMode(True);
	
	AttributesNames = New Structure;
	FillInEmptyStructureNamesOfMetadataAttributes(AttributesNames);
	
	LoyaltyServiceOverridable.FillInNamesOfAttributesOfDataProvider(AttributesNames);
	
	If AttributesNames = Undefined Then
		Return;
	EndIf;
	
	SourceMetadata = Object.Metadata();
	If SourceMetadata.TabularSections.Find(AttributesNames.DetailsNameCertificateRedemptionTable) = Undefined Then
		Return;
	EndIf;
	
	TypeDescriptionNumber = New TypeDescription("Number",,,New NumberQualifiers(15, 2));
	TableOfGiftCertificates = New ValueTable;
	TableOfGiftCertificates.Columns.Add("GiftCertificate", Metadata.DefinedTypes.GiftCardLoyaltyServer.Type);
	TableOfGiftCertificates.Columns.Add("SerialNumber", Metadata.DefinedTypes.SerialNumberLoyaltyServer.Type);
	TableOfGiftCertificates.Columns.Add("Organization", Metadata.DefinedTypes.CompanyLoyaltyServer.Type);
	TableOfGiftCertificates.Columns.Add("ToWriteOff", TypeDescriptionNumber);
	TableOfGiftCertificates.Columns.Add("ToAccrue", TypeDescriptionNumber);
	
	CertificateRedemptionTable = Object[AttributesNames.DetailsNameCertificateRedemptionTable];
	
	TypeOfGiftCard = Metadata.DefinedTypes.GiftCardLoyaltyServer.Type;
	CertificatePaymentLines = New Array;
	For Each PaymentLine_ In CertificateRedemptionTable Do
		If TypeOf(PaymentLine_[AttributesNames.PropsNameGiftCard]) = TypeOfGiftCard
			And ValueIsFilled(PaymentLine_[AttributesNames.PropsNameGiftCard]) Then
			CertificatePaymentLines.Add(PaymentLine_);
		EndIf;
	EndDo;
	If TypeOf(CertificateRedemptionTable) = Type("ValueTable") Then
		GiftCertificates = CertificateRedemptionTable.Copy(CertificatePaymentLines, AttributesNames.PropsNameGiftCard);
	Else
		GiftCertificates = CertificateRedemptionTable.Unload(CertificatePaymentLines, AttributesNames.PropsNameGiftCard);
	EndIf;
	CertificatesWithCompanyControl = New Array; 
	ReversibleCertificates = GiftCertificates.UnloadColumn(AttributesNames.PropsNameGiftCard); 
	SelectCertificatesWithCompanyControl(ReversibleCertificates, CertificatesWithCompanyControl);
	
	Organization = Undefined;
	If AttributesNames.CompanyAttributeName <> "" Then
		Organization = Object[AttributesNames.CompanyAttributeName];
	EndIf;
	
	For Each CertificateRedemptionLine In CertificateRedemptionTable Do
		
		CertificateRepaymentAmount = CertificateRedemptionLine[AttributesNames.DetailsNameCertificateRedemptionAmount];
		If ValueIsFilled(CertificateRepaymentAmount) Then
			NewRow = TableOfGiftCertificates.Add();
			NewRow.GiftCertificate = CertificateRedemptionLine[AttributesNames.PropsNameGiftCard];
			NewRow.SerialNumber = CertificateRedemptionLine[AttributesNames.PropsNameSerialNumber];
			If Organization <> Undefined 
				And CertificatesWithCompanyControl.Find(CertificateRedemptionLine.GiftCertificate) <> Undefined Then
				NewRow.Organization = Organization;
			EndIf;
			NewRow.ToWriteOff = CertificateRepaymentAmount;
		EndIf;
		
	EndDo;
	
	LoyaltyServiceOverridable.FillOutAccrualsForGiftCards(Object, TableOfGiftCertificates);
	
	TableOfGiftCertificates.GroupBy("GiftCertificate, SerialNumber, Organization", "ToWriteOff, ToAccrue");
	
	For Each TableRow In TableOfGiftCertificates Do
		RecordManager = InformationRegisters.GiftCardsToWriteOffAndAccrue.CreateRecordManager();
		
		RecordManager.GiftCertificate = TableRow.GiftCertificate;
		RecordManager.SerialNumber = TableRow.SerialNumber;
		If Not CertificatesWithCompanyControl.Find(TableRow.GiftCertificate) = Undefined Then
			RecordManager.Organization = TableRow.Organization;
		EndIf;
		RecordManager.Read();
		
		AmountOfWriteOffRecord = RecordManager.ToWriteOff;
		AccrualAmountRecord = RecordManager.ToAccrue;
		
		If AmountOfWriteOffRecord = 0
			And AccrualAmountRecord = 0 Then
			Return;
		EndIf;
				
		AmountOfWriteOffRecord = Max(AmountOfWriteOffRecord - TableRow.ToWriteOff, 0);
		AccrualAmountRecord = Max(AccrualAmountRecord - TableRow.ToAccrue, 0);
		If AmountOfWriteOffRecord <= 0
			And AccrualAmountRecord <= 0 Then
			RecordManager.Delete();
		Else
			RecordManager.ToWriteOff = AmountOfWriteOffRecord;
			RecordManager.ToAccrue = AccrualAmountRecord;
			RecordManager.Write(True);
		EndIf;
	EndDo;
	
EndProcedure

// Performs adjustments to the register of information "Gift cards for debiting and accrual"
//
// Parameters:
//  Object - DocumentObject.CashRegisterReceiptReturn
//
Procedure CorrectInformationRegisterGiftCardsToWriteOffReturn(Object) Export
	
	SetPrivilegedMode(True);
	
	TypeDescriptionNumber = New TypeDescription("Number",,,New NumberQualifiers(15, 2));
	TableOfGiftCertificates = New ValueTable;
	TableOfGiftCertificates.Columns.Add("GiftCertificate", Metadata.DefinedTypes.GiftCardLoyaltyServer.Type);
	TableOfGiftCertificates.Columns.Add("SerialNumber", Metadata.DefinedTypes.SerialNumberLoyaltyServer.Type);
	TableOfGiftCertificates.Columns.Add("Organization", Metadata.DefinedTypes.CompanyLoyaltyServer.Type);
	TableOfGiftCertificates.Columns.Add("ToWriteOff", TypeDescriptionNumber);
	TableOfGiftCertificates.Columns.Add("ToAccrue", TypeDescriptionNumber);
	
	LoyaltyServiceOverridable.FillOutAccrualsForGiftCards(Object, TableOfGiftCertificates);
	
	TableOfGiftCertificates.GroupBy("GiftCertificate, SerialNumber", "ToWriteOff, ToAccrue");
	CertificatesWithCompanyControl = New Array; 
	ReversibleCertificates = TableOfGiftCertificates.UnloadColumn("GiftCertificate"); 
	SelectCertificatesWithCompanyControl(ReversibleCertificates, CertificatesWithCompanyControl);
	
	Organization = Undefined;
	If CommonClientServer.HasAttributeOrObjectProperty(Object, "Organization") Then
		Organization = Object.Organization;
	EndIf;

	For Each TableRow In TableOfGiftCertificates Do
		RecordManager = InformationRegisters.GiftCardsToWriteOffAndAccrue.CreateRecordManager();
		
		RecordManager.GiftCertificate = TableRow.GiftCertificate;
		RecordManager.SerialNumber = TableRow.SerialNumber;
		If CertificatesWithCompanyControl.Find(TableRow.GiftCertificate) = Undefined Then
			RecordManager.Organization = Organization;
		EndIf;
		RecordManager.Read();
		
		AmountOfWriteOffRecord = RecordManager.ToWriteOff;
		AccrualAmountRecord = RecordManager.ToAccrue;
		
		If AmountOfWriteOffRecord = 0
			And AccrualAmountRecord = 0 Then
			Return;
		EndIf;
		
		AmountOfWriteOffRecord = Max(AmountOfWriteOffRecord - TableRow.ToWriteOff, 0);
		AccrualAmountRecord = Max(AccrualAmountRecord - TableRow.ToAccrue, 0);
		If AmountOfWriteOffRecord <= 0
			And AccrualAmountRecord <= 0 Then
			RecordManager.Delete();
		Else
			RecordManager.ToWriteOff = AmountOfWriteOffRecord;
			RecordManager.ToAccrue = AccrualAmountRecord;
			RecordManager.Write(True);
		EndIf;
	EndDo;
EndProcedure

// Corrects the information register "Promo codes to be debited"
//
// Parameters:
//  Object - DocumentObject.CashRegisterReceipt
//
Procedure AdjustInformationRegisterPromoCodesForDebiting(Object) Export
	
	SetPrivilegedMode(True);
	
	ArrayOfPromoCodes = New Array;
	LoyaltyServiceOverridable.GetUsedPromoCodes(Object, ArrayOfPromoCodes);
	
	QueryText = 
	"SELECT
	|	PromoCodesToWriteOffLoyaltyServer.UUID AS UUID,
	|	PromoCodesToWriteOffLoyaltyServer.PromoCode AS PromoCode
	|FROM
	|	InformationRegister.PromoCodesToWriteOffLoyaltyServer AS PromoCodesToWriteOffLoyaltyServer
	|WHERE
	|	PromoCodesToWriteOffLoyaltyServer.PromoCode IN (&ArrayOfPromoCodes)";
	Query = New Query (QueryText);
	Query.SetParameter("ArrayOfPromoCodes", ArrayOfPromoCodes);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordManager = InformationRegisters.PromoCodesToWriteOffLoyaltyServer.CreateRecordManager();
		FillPropertyValues(RecordManager, Selection);
		RecordManager.Delete();
		
	EndDo;
	
EndProcedure

// Unlocks the gift card
//
// Parameters: 
//  CertificateData - Structure - contains links to the gift card and its serial number.
//
Procedure UnlockGiftCard(CertificateData) Export
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(CertificateData.SerialNumber) Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.GiftCardState.CreateRecordSet();
	RecordSet.Filter.GiftCertificate.Set(CertificateData.GiftCertificate);
	RecordSet.Filter.SerialNumber.Set(CertificateData.SerialNumber);
	RecordSet.Write();
	
	SetPrivilegedMode(False);
	
EndProcedure

// Debits the gift card balance
//
// Parameters:
//  CertificateData	 - Structure - Contains gift card data: Gift certificate, Serial number
//  DebitedAmount		 - Number	 - The amount to be debited from the gift card balance
//  AccrualAmount		 - Number	 - The amount that will be credited to the gift card balance
//
Procedure AdjustGiftCardBalance(CertificateData, DebitedAmount, AccrualAmount) Export
	
	SetPrivilegedMode(True);
	
	Balance_Data = GetAmountOfGiftCardReserve(CertificateData);
	RecordManager = InformationRegisters.GiftCardsToWriteOffAndAccrue.CreateRecordManager();
	
	RecordManager.GiftCertificate = CertificateData.GiftCertificate;
	RecordManager.SerialNumber 		= CertificateData.SerialNumber;
	
	
	OnlyIssuerCompanyAcceptsGiftCardAmountDue = False;
	LoyaltyServiceOverridable.FillInControlSignForGiftCardCompanies(CertificateData.GiftCertificate,
		OnlyIssuerCompanyAcceptsGiftCardAmountDue);
		
	If OnlyIssuerCompanyAcceptsGiftCardAmountDue Then
		RecordManager.Organization = CertificateData.Organization;
	Else
		RecordManager.Organization = Catalogs.Companies.EmptyRef();
	EndIf;
	
	RecordManager.ToWriteOff  			= DebitedAmount + Balance_Data.AmountToBeDebited_;
	RecordManager.ToAccrue 			= AccrualAmount + Balance_Data.AmountToAccrue;
	RecordManager.Write(True);
	
	UnlockGiftCard(CertificateData);
	
	SetPrivilegedMode(False);
EndProcedure

// Returns the reserved amount of the gift card
//
// Parameters:
//	CertificateData - Structure - Contains gift card data: Gift Certificate, Serial number, Company
//
// Returns:
//  Structure - gift card balance data:
//   * AmountToBeDebited_ - Number - Amount reserved for debiting
//   * AmountToAccrue - Number - The amount reserved for accrual
//
Function GetAmountOfGiftCardReserve(CertificateData) Export
	
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	ISNULL(SUM(GiftCardsToWriteOffAndAccrue.ToWriteOff), 0) AS ToWriteOff,
	|	ISNULL(SUM(GiftCardsToWriteOffAndAccrue.ToAccrue), 0) AS ToAccrue
	|FROM
	|	InformationRegister.GiftCardsToWriteOffAndAccrue AS GiftCardsToWriteOffAndAccrue
	|WHERE
	|	GiftCardsToWriteOffAndAccrue.GiftCertificate = &GiftCertificate
	|	AND GiftCardsToWriteOffAndAccrue.SerialNumber = &SerialNumber
	|	AND GiftCardsToWriteOffAndAccrue.Organization = &Organization";
	
	Query.SetParameter("GiftCertificate", CertificateData.GiftCertificate);
	Query.SetParameter("SerialNumber"		, CertificateData.SerialNumber);
	Organization = PredefinedValue("Catalog.Companies.EmptyRef");
	If TypeOf(CertificateData) = Type("Structure")
		And CertificateData.Property("Organization") Then
		Organization = CertificateData.Organization;
	EndIf;
	Query.SetParameter("Organization", Organization);
	
	Selection = Query.Execute().Select();
	AmountOfGiftCardWrittenOff = 0;
	AmountOfGiftCardAccrual = 0;
	
	If Selection.Next() Then
		AmountOfGiftCardWrittenOff = Selection.ToWriteOff;
		AmountOfGiftCardAccrual = Selection.ToAccrue;
	EndIf;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("AmountToBeDebited_", AmountOfGiftCardWrittenOff);
	ReturnStructure.Insert("AmountToAccrue", AmountOfGiftCardAccrual);
	
	Return ReturnStructure;
	
EndFunction

// Blocks the gift card after the Loyalty Service responds in order to prevent double debiting of the balance
//
// Parameters:
//  CertificateData - Structure - contains links to the gift card and its serial number
//  LockDate    - Date
//
Procedure BlockGiftCard(CertificateData, LockDate) Export
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.GiftCardState");
	LockItem.SetValue("SerialNumber", CertificateData.SerialNumber);
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet = InformationRegisters.GiftCardState.CreateRecordSet();
		RecordSet.Filter.GiftCertificate.Set(CertificateData.GiftCertificate);
		RecordSet.Filter.SerialNumber.Set(CertificateData.SerialNumber);
		RegisterRecord = RecordSet.Add();
		FillPropertyValues(RegisterRecord, CertificateData);
		RegisterRecord.LockDate = LockDate;
		RecordSet.Write(); 
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Reserves one use of the promo code after the Loyalty Service's response in order to prevent double use
// of the final promo code.
//
// Parameters:
//  PromoCode - DefinedType.PromoCodeLoyaltyServer - The line containing the promo code
//
Procedure ReserveUseOfPromoCode(PromoCode) Export
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.PromoCodesToWriteOffLoyaltyServer");
	LockItem.SetValue("PromoCode", PromoCode);
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordManager = InformationRegisters.PromoCodesToWriteOffLoyaltyServer.CreateRecordManager();
		RecordManager.UUID = New UUID;
		RecordManager.PromoCode = PromoCode;
		RecordManager.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Cancels the reserve for applying the final promo code
//
// Parameters: 
//  PromoCode - DefinedType.PromoCodeLoyaltyServer - A string containing a promo code.
//
Procedure RemoveReserveForUsingPromoCode(PromoCode) Export
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.PromoCodesToWriteOffLoyaltyServer");
	LockItem.SetValue("PromoCode", PromoCode);
	
	BeginTransaction();
	Try
		Block.Lock();
		
		QueryText = 
		"SELECT TOP 1
		|	PromoCodesToWriteOffLoyaltyServer.UUID AS UUID,
		|	PromoCodesToWriteOffLoyaltyServer.PromoCode AS PromoCode
		|FROM
		|	InformationRegister.PromoCodesToWriteOffLoyaltyServer AS PromoCodesToWriteOffLoyaltyServer
		|WHERE
		|	PromoCodesToWriteOffLoyaltyServer.PromoCode IN(&PromoCode)";
		Query = New Query(QueryText);
		Query.SetParameter("PromoCode", PromoCode);
		Selection = Query.Execute().Select();

		If Selection.Next() Then
			RecordManager = InformationRegisters.PromoCodesToWriteOffLoyaltyServer.CreateRecordManager();
			FillPropertyValues(RecordManager, Selection);
			RecordManager.Delete();
			CommitTransaction();
		EndIf;
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Fixes a Loyalty Service error in the registration Log
// 
// Parameters:
//  ErrorDescription - String - text description of the error that occurred
//  ErrorMessage - String - text Presentation of the error.
//  FunctionName     - String - name of the Loyalty Service function
//
// Returns:
//  HTTPServiceResponse
//
Function FixLoyaltyServiceError(ErrorDescription, ErrorMessage, FunctionName) Export
	
	EventName = StrTemplate(NStr("vi = 'Server khách hàng thân thiết, lỗi trong %1.';
								|ru = 'Сервер лояльности, ошибка в %1.';
								|en = 'Loyalty server, error in %1.'; fa = 'Loyalty server, error in %1.';
								|it = 'Сервер лояльности, ошибка в %1.';
								|pl = 'Loyalty server, error in %1.';
								|tr = 'Sadakat sunucusu, %1 içinde hata.'", Common.DefaultLanguageCode()), FunctionName);
		
	WriteLogEvent(EventName, EventLogLevel.Error, , , ErrorDescription);
	
	#If ExternalConnection Then
		Response = Undefined;
	#Else
		Response = New HTTPServiceResponse(500);
		Response.SetBodyFromString(ErrorMessage, TextEncoding.UTF8);
	#EndIf
	
	Return Response;

EndFunction

// Performs processing of the State of bonuses and gift cards of customers
// The presence of blocked bonuses and gift cards of customers is checked
// If such are found and the expiration time for them has expired, they are unblocked
Procedure ProcessingStatusOfBonusesAndGiftCards() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ProcessStateOfBonusPointsAndGiftCardsLoyaltyServer);
	
	Filter = New Structure("Metadata", Metadata.ScheduledJobs.ProcessStateOfBonusPointsAndGiftCardsLoyaltyServer);
	CurrentJobs	= ScheduledJobsServer.FindJobs(Filter);
	
	RulesOfUnblocking = Undefined;
	For Each CurrentJob In CurrentJobs Do
		RulesOfUnblocking = CurrentJob;
		Break;
	EndDo;
	ExpirationTime = RulesOfUnblocking.Schedule.RepeatPeriodInDay;
	
	If Not RulesOfUnblocking.Use And ExpirationTime = 0 Then 
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	BonusPointState.DiscountCard AS DiscountCard,
		|	BonusPointState.LockDate AS LockDate,
		|	NULL AS GiftCertificate,
		|	NULL AS SerialNumber
		|FROM
		|	InformationRegister.BonusPointState AS BonusPointState
		|WHERE
		|	BonusPointState.LockDate <= &Expiration_Date
		|
		|UNION ALL
		|
		|SELECT
		|	NULL,
		|	GiftCardState.LockDate,
		|	GiftCardState.GiftCertificate,
		|	GiftCardState.SerialNumber
		|FROM
		|	InformationRegister.GiftCardState AS GiftCardState
		|WHERE
		|	GiftCardState.LockDate <= &Expiration_Date";
	
	Expiration_Date = CurrentSessionDate() - ExpirationTime;
	Query.SetParameter("Expiration_Date", Expiration_Date);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	Try
		While Selection.Next() Do
			
			If ValueIsFilled(Selection.DiscountCard) Then 
				UnlockBonuses(Selection.DiscountCard);
			EndIf;
			
			If ValueIsFilled(Selection.GiftCertificate) Then
				CertificateData = New Structure;
				CertificateData.Insert("GiftCertificate", Selection.GiftCertificate);
				CertificateData.Insert("SerialNumber", Selection.SerialNumber);
				UnlockGiftCard(CertificateData);
			EndIf;
			
		EndDo;
	Except
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		FunctionName = "LoyaltyService.ProcessingStatusOfBonusesAndGiftCards";
		EventName = StrTemplate(NStr("vi = 'Chương trình khách hàng thân thiết, lỗi trong %1.';
									|ru = 'Сервер лояльности, ошибка в %1.';
									|en = 'Loyalty server, error in %1.'; fa = 'Loyalty server, error in %1.';
									|it = 'Сервер лояльности, ошибка в %1.';
									|pl = 'Loyalty server, error in %1.';
									|tr = 'Sadakat sunucusu, %1 içinde hata.'", Common.DefaultLanguageCode()), FunctionName);
		
		WriteLogEvent(EventName, , , , ErrorDescription);
	EndTry;
	
EndProcedure

// Returns the structure of the "Sales Control" directory element to Transfer to the consumer.
//
// Returns:
//  Structure - structure containing sales control data:
//    *Ref - String - the unique identifier of the "Sales Control" item in the string,
//    *Name - String - name of the "Sales Control" element,
//    *Description - String - the value of the details "Description" of the "Sales Control" element,
//    *Active - Boolean - the value of the Attribute "Use" of the "Sales Control" element,
//    *AllStores - Boolean - the value of the props "For all Retail objects" of the "Sales Control" element,
//    *AllGoods - Boolean - the value of the Attribute "For all the Nomenclature" of the "Sales Control" element,
//    *GoodsGroupDescription - String - the value of the props "Product Group name" of the "Sales Control" element,
//    *GoodsSetRef - String - the unique identifier of the item from the "Palette" props of the "Sales Control" element,
//    *DeletionMark - Boolean - flag indicating whether the "Sales Control" element should be deleted,
//    *IncludedGoodsSets - Array of String- list of unique identifiers of the elements of the "Palette" directory 
//									from the table part of the "Sales Control Palettes"
//    *IncludedGoods - Array of String - list of unique identifiers of items in the "Nomenclature" directory from the "Nomenclature" 
//									tabular section
//    *StoreRef - String - unique identifier of the Retail facility for which sales control is requested,
//							It is not filled in if the requested retail item is not in the "Retail Items" tabular section,
//    *ControlElements - Array of Structure - a list of structures with a description of the sales control line
//								from the "Sales Control" tabular part.
//
Function GetParametersOfSalesControlElement() Export
	
	FunctionResult = New Structure();
	
	FunctionResult.Insert("Ref", "");
	FunctionResult.Insert("Name", "");
	FunctionResult.Insert("Description", "");
	FunctionResult.Insert("Active", False);
	FunctionResult.Insert("AllStores", False);
	FunctionResult.Insert("AllGoods", False);
	FunctionResult.Insert("GoodsGroupDescription", "");
	FunctionResult.Insert("GoodsSetRef", "");
	FunctionResult.Insert("DeletionMark", False);
	FunctionResult.Insert("IncludedGoodsSets", New Array);
	FunctionResult.Insert("IncludedGoods", New Array);
	FunctionResult.Insert("StoreRef", "");
	FunctionResult.Insert("ControlElements", New Array);
	
	Return FunctionResult;
	
EndFunction

// Returns the row structure of the "Sales Control" tabular part
// of the "Sales Control" directory for Transfer to the consumer.
//
// Returns:
//  Structure - the structure containing the data of the sales control line:
//    *RestrictionKindName - String - name of the predefined element in the "Types of Control" directory,
//    *RestrictionKindRef - String - the unique identifier of the "Types of Control" Catalog item as a string.
//									Filled only for non-predefined elements,
//    *PeriodStart - Date - start date of the restriction,
//    *PeriodEnd - Date - expiration date of the restriction,
//    *WeekDayNumber - Number - the number of the day of the week. 0 - not filled, all days of the week,
//    *TimeStart - Date - start time of the restriction,
//    *TimeEnd - Date - expiration time of the restriction
//
Function GetParametersOfSalesControlLine() Export
	
	FunctionResult = New Structure();
	DateEmpty = Date(1, 1, 1, 0, 0, 0);
	
	FunctionResult.Insert("RestrictionKindName", "");
	FunctionResult.Insert("RestrictionKindRef", "");
	FunctionResult.Insert("PeriodStart", DateEmpty);
	FunctionResult.Insert("PeriodEnd", DateEmpty);
	FunctionResult.Insert("WeekDayNumber", 0);
	FunctionResult.Insert("TimeStart", DateEmpty);
	FunctionResult.Insert("TimeEnd", DateEmpty);
	
	Return FunctionResult;
	
EndFunction

// Returns the structure of the "Types of Control" reference list element to be Transferred to the consumer.
// 
// Returns:
//  Structure - structure containing data of the type of control:
//   *PredefinedName - String - name of the predefined element in the "Types of Control" directory,
//    *Ref - String - the unique identifier of the "Types of Control" Catalog item as a string.
//						Filled only for non-predefined elements,
//    *Name - String - name of the type of control,
//    *RestrictionTypeName - String - name of the enumeration value from the "Control Type" Attribute,
//    *PatternTextForUser - String - the value of the Attribute of the "Warning template text",
//    *Parameters - Array - a list of structures with a description of the parameter string of the type of control.
Function GetParametersForTypeOfSalesControl() Export
	
	FunctionResult = New Structure();
	
	FunctionResult.Insert("PredefinedName", "");
	FunctionResult.Insert("Ref", "");
	FunctionResult.Insert("Name", "");
	FunctionResult.Insert("RestrictionTypeName", "");
	FunctionResult.Insert("PatternTextForUser", "");
	FunctionResult.Insert("Parameters", New Array);
	
	Return FunctionResult;
	
EndFunction

// Returns the row structure of the "Control Parameters" tabular part
// of the "Types of Control" Catalog for Transfer to the consumer.
//
// Returns:
//  Structure - the structure containing the data of the parameter string of the type of control:
//    *Parameter - String - the name of the value of the enumeration "Parameters of sales control",
//    *Value - String - the parameter value is a string.
//
Function GetParametersOfParameterLineOfSalesControlType() Export
	
	FunctionResult = New Structure();
	
	FunctionResult.Insert("Parameter", "");
	FunctionResult.Insert("Value", "");
	
	Return FunctionResult;
	
EndFunction

// Returns the structure of the directory item "Palette of RMK goods" for Transfer to the consumer.
//
// Returns:
//  Structure - structure containing product palette data:
//    *Ref - String - unique identifier of the CWP Product Palette Catalog item in the line,
//    *Name - String - name of the product palette,
//    *NumberOfElementsInRow - Number - the value of the Attribute of the "Number of elements in a row" of the product palette,
//    *ElementHeight - Number - the value of the Attribute of the "height element" of the product palette,
//    *NumberOfRows - Number - the value of the Attribute of the "Number of orders" of the product palette,
//    *Service - Boolean - the value of the "Service" Attribute of the product palette,
//    *GoodsContent - Array - a list of structures with a description of the product palette composition line.
//
Function GetGoodsPaletteParameters() Export
	
	FunctionResult = New Structure();
	FunctionResult.Insert("Ref", "");
	FunctionResult.Insert("Name", "");
	FunctionResult.Insert("NumberOfElementsInRow", 0);
	FunctionResult.Insert("ElementHeight", 0);
	FunctionResult.Insert("NumberOfRows", 0);
	FunctionResult.Insert("Service", False);
	FunctionResult.Insert("GoodsContent", New Array);
	
	Return FunctionResult;
	
EndFunction

// Returns the row structure of the table part "Composition"
// of the directory "Palette of RMK goods" for Transfer to the consumer.
//
// Returns:
//  Structure - the structure containing the data of the product palette composition line:
//    *IsFolder - Boolean - meaning of the column "This is a category",
//    *FolderNumber - Number - the value of the "Category number" column,
//    *ParentFolderNumber - Number - the value of the column "Placement category number",
//    *PositionIndex - Number - the value of the "IndexpOsition" column,
//    *ElementName - String - the value of the column "Element name",
//    *NomenclatureRef - String - unique item ID in a string,
//    *CharacteristicRef - String - unique identifier of the characteristic,
//    *ElementTitle - String - the value of the "Element header" column,
//    *CharacteristicsAreUsed - Boolean - The value of the column "Characteristics are used",
//    *HasIncludedElements - Boolean - the value of the column "has an attachment",
//    *ModificatorName - String - the name of the value of the enumeration "VidyModificatorovRMK",
//    *PackageRef - String - unique identifier of the package in a string,
//    *HideAmount - Boolean - the value of the "Hide Status" column,
//    *GoodsSetRef - String - unique ID of the palette as a string.
//
Function GetParametersOfPaletteCompositionLine() Export
	
	FunctionResult = New Structure();
	
	FunctionResult.Insert("IsFolder", False);
	FunctionResult.Insert("FolderNumber", 0);
	FunctionResult.Insert("ParentFolderNumber", 0);
	FunctionResult.Insert("PositionIndex", 0);
	FunctionResult.Insert("ElementName", "");
	FunctionResult.Insert("NomenclatureRef", "");
	FunctionResult.Insert("CharacteristicRef", "");
	FunctionResult.Insert("ElementTitle", "");
	FunctionResult.Insert("CharacteristicsAreUsed", False);
	FunctionResult.Insert("HasIncludedElements", False);
	FunctionResult.Insert("ModificatorName", "");
	FunctionResult.Insert("PackageRef", "");
	FunctionResult.Insert("HideAmount", False);
	FunctionResult.Insert("GoodsSetRef", "");
	
	Return FunctionResult;
	
EndFunction

// Returns the structure of the sales ban
//
// Parameters:
//  Organization - DefinedType.CompanyLoyaltyServer - Organization.
//  Store 	- DefinedType.StoreLoyaltyServer - the store.
//
// Returns:
//  Structure - a structure containing data on sales bans:
//    * StartDate - String -start date of the sales ban.
//    * EndDate - String -expiration date of the sales ban.
//    * SalesPromotionID - String -The test value of the marketing promotion/discount GUIDE that contains
//                         sales ban data.
//    * SalesPromotionName - String - the name of the marketing promotion/discount that contains sales ban data.
//    * Organisation - Structure - Organization Data:
//      ** Name - String - name of the organization.
//      ** Ref - String - the text value of the organization's GUIDE.
//      ** ID - String - organization code.
//      ** TIN - String - INN of the organization.
//    * Store - Structure - Store Data:
//       ** Name - String - store name.
//       ** Ref - String - the text value of the store's GUIDE.
//       ** ID - String - store code.
//    * DaysOfWeek - Array of String - array of days of the week for which the sales ban applies.
//   *  TypesOfGoods - Array of String - array of item types that are subject to the sales ban
//
Function GetParametersForControllingSalesBans(Organization = Undefined, Store = Undefined) Export
	
	ThisOrganization = New Structure;
	ThisOrganization.Insert("Name", ?(ValueIsFilled(Organization), Organization.Description, ""));
	ThisOrganization.Insert("Ref" , ?(ValueIsFilled(Organization), XMLString(Organization)  , ""));
	ThisOrganization.Insert("ID"  , ?(ValueIsFilled(Organization), Organization.Code		 , ""));
	ThisOrganization.Insert("TIN" , ?(ValueIsFilled(Organization), Organization.TIN		 , ""));
	
	StoreData = New Structure;
	StoreData.Insert("Name", ?(ValueIsFilled(Store), Store.Description, ""));
	StoreData.Insert("Ref" , ?(ValueIsFilled(Store), XMLString(Store)  , ""));
	StoreData.Insert("ID"  , ?(ValueIsFilled(Store), Store.Code		  , ""));
	
	SalesBanStructure = New Structure;
	SalesBanStructure.Insert("StartDate"			, "");
	SalesBanStructure.Insert("EndDate"			, "");
	
	SalesBanStructure.Insert("SalesPromotionID"	, "");
	SalesBanStructure.Insert("SalesPromotionName", "");
 	SalesBanStructure.Insert("Organisation"		, ThisOrganization);
	SalesBanStructure.Insert("Store"				, StoreData);
	SalesBanStructure.Insert("DaysOfWeek"		, New Array);
	SalesBanStructure.Insert("TypesOfGoods"		, New Array);
	
	Return SalesBanStructure;

EndFunction

// Returns a structure containing information about Balances
//
// Returns:
//  Structure - a structure containing data on Balances:
//    * LeftoverLocation - String - Balance storage location.
//    * Variant - String - characteristic.
//    * Leftover - Number - The Balance.
//    * Reserved - Number - Reserved.
//    * FreeLeftover - Number - Free Balance.
//
Function GetBalanceRequestParameters() Export
	
	StructureOfResidues = New Structure;
	StructureOfResidues.Insert("LeftoverLocation", "");
	StructureOfResidues.Insert("Variant", "");
	StructureOfResidues.Insert("Leftover", 0);
	StructureOfResidues.Insert("Reserved", 0);
	StructureOfResidues.Insert("FreeLeftover", 0);
	
	Return StructureOfResidues;

EndFunction

// Returns the text of the query
// 
// Returns:
//  String - query text.
//
Function QueryTextBalanceOfGiftCard() Export
	
	QueryText = "";
	Return QueryText;
	
EndFunction

// Returns a deserialized value in the form of a GUID
//
// Parameters:
//  IncomingData - Structure - a structure containing a set of parameters from an http request.
//  ParameterName - String - name of the parameter to be deserialized.
//  ValueType - String - the name of the value type, for example: "Catalogs.Nomenclature".
//
// Returns:
//  AnyRef - the received parameter value.
//
Function GetDeserializedReferenceValue(IncomingData, ParameterName, ValueType) Export
	
	BlankUUID = CommonClientServer.BlankUUID();
	SafeModeSettings = New Structure;
	SafeModeSettings.Insert("ParameterValue");
	SafeModeSettings.Insert("GUID", BlankUUID);

	Try
		StringValueOfParameter = IncomingData[ParameterName].Ref;
		If StringValueOfParameter = String(BlankUUID) Then
			Common.ExecuteInSafeMode("Parameters.ParameterValue = " + ValueType + ".EmptyRef()", SafeModeSettings);
		Else
			GUID = New UUID(StringValueOfParameter);
			SafeModeSettings.Insert("GUID", GUID);
			Common.ExecuteInSafeMode(" Parameters.ParameterValue = " + ValueType + ".GetRef(Parameters.GUID)", SafeModeSettings);
		EndIf;
		If (Not SafeModeSettings.ParameterValue.IsEmpty())
			And SafeModeSettings.ParameterValue.GetObject() = Undefined Then 
			Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndIf;
	Except
		Common.ExecuteInSafeMode("Parameters.ParameterValue = " + ValueType + ".EmptyRef()", SafeModeSettings);
	EndTry;
	
	Return SafeModeSettings.ParameterValue;
	
EndFunction

// Fills the response structure with a list of managed discounts
//
// Parameters:
//  ResponseStructure - Array of Structure - an array of structures containing response parameters:
//   * DiscountValue - Number - the value of the discount.
//   * Presentation - String - Presentation of the discount.
//   * DiscountType - String - the type of discount.
//   * Scope - String - the scope of the discount.
//   * DiscountID - String - unique identifier of the discount.
//   * DiscountMarkup - String - name of the discount.
//  CalculationParameters - Structure - a structure containing a set of parameters from an http request.
//
Procedure ListOfManagedDiscounts(ResponseStructure, CalculationParameters) Export
	
	TableOfManagedDiscounts = EmptyTableOfManagedDiscounts();
	LoyaltyServiceOverridable.FillInTableOfManagedDiscounts(TableOfManagedDiscounts, CalculationParameters);
	ResponseStructure = SerializeTableOfManagedDiscounts(TableOfManagedDiscounts);
	
EndProcedure

// Initializes the structure of the loyalty card.
// 
// Returns:
//  Structure -  Loyalty Card Structure:
// * ClientName - String
// * IsPerson - Boolean
// * DateOfBirth - String
// * Phone - String
// * Email - String
// * Barcode - String
// * MagneticCode - String
// * CardGUID - String
// * ClientGUID - String
// * IsBlocked - String
// * BonusData - Structure:
//  ** PaymentPercent - Number
//  ** BonusCount - Number
//  ** BonusRate - Number
//  ** BonusCurrency - String
// * SellCount - Number
// * SearchType - String
// * Valid - Boolean
// * TypeCard - String
//
Function LoyaltyCardStructure() Export
	
	CurrencyCode_ = "";
	LoyaltyServiceOverridable.GetCurrencyCode(CurrencyCode_);
	
	BonusData = New Structure();
	BonusData.Insert("PaymentPercent", 0);
	BonusData.Insert("BonusCount", 0);
	BonusData.Insert("BonusRate", 1);
	BonusData.Insert("BonusName", "");
	BonusData.Insert("BonusGUID", "");
	BonusData.Insert("BonusLimitBalance", 0);
	BonusData.Insert("BonusCurrency", CurrencyCode_);
	
	MapStructure = New Structure();
	MapStructure.Insert("ClientName", "");
	MapStructure.Insert("IsPerson", False);
	MapStructure.Insert("DateOfBirth", "");
	MapStructure.Insert("Phone", "");
	MapStructure.Insert("Email", "");
	MapStructure.Insert("Barcode", "");
	MapStructure.Insert("MagneticCode", "");
	MapStructure.Insert("CardGUID", "");
	MapStructure.Insert("ClientGUID", "");
	MapStructure.Insert("IsBlocked", "");
	MapStructure.Insert("BonusData", BonusData);
	MapStructure.Insert("SellCount", 0);
	MapStructure.Insert("SearchType", "");
	MapStructure.Insert("Valid", True);
	MapStructure.Insert("TypeCard", "");
	
	Return MapStructure;
	
EndFunction

// Fills in the response structure with a list of types of discount cards
//
// Parameters:
//  ResponseStructure - Array - an array of structures containing response parameters:
//   * Id - String - unique identifier of the discount card type.
//   * Description - String - the name of the type of discount card.
//   * ThisIsNameCard - Boolean - indicates that the discount card type is registered.
//  CalculationParameters -Structure - a structure containing a set of parameters from an http request.
//
Procedure ListOfTypesOfDiscountCards(ResponseStructure, CalculationParameters) Export
	
	TableOfTypesOfDiscountCards = TableOfMapTypes();
	LoyaltyServiceOverridable.FillInTableOfCardTypes(TableOfTypesOfDiscountCards, CalculationParameters);
	ResponseStructure = SerializeTableOfMapTypes(TableOfTypesOfDiscountCards);
	
EndProcedure

// Fills in the list of employees
//
// Parameters:
//  CalculationParameters - Structure - a structure containing a set of parameters from an http request.
//  ResponseStructure - Array - an array of structures containing response parameters:
//   * EmployeePresentation - String - Name of the employee.
//   * CodeOfEmployee - String - The employee's code to log in to CWP.
//   * EmployeeID - String - UID employee.
//
Procedure ListOfEmployees(CalculationParameters, ResponseStructure) Export
	
	EmployeeTable = EmptyEmployeeTable();
	LoyaltyServiceOverridable.FillInEmployeeTable(CalculationParameters, EmployeeTable);
	ResponseStructure = SerializeEmployeeTable(EmployeeTable);
	
EndProcedure

// Fills in the list of series
//
// Parameters:
//  CalculationParameters - Structure - a structure containing a set of parameters from an http request.
//  ResponseStructure - Array - an array of structures containing response parameters:
//   * SeriesPresentation - String - The name of the series.
//   * IDOfSeries - String - UID series.
//
Procedure FillInListOfBatches(CalculationParameters, ResponseStructure) Export
	
	TableOfSeries = EmptySeriesTable();
	LoyaltyServiceOverridable.FillInListOfBatches(CalculationParameters, TableOfSeries);
	ResponseStructure = SerializeBatchTable(TableOfSeries);
	
EndProcedure

// Fills the response structure with a list of managed discounts
//
// Parameters:
//  ResponseStructure - Array - an array of structures containing response parameters:
//   * DiscountValue - Number - the value of the discount.
//   * Presentation - String - Presentation of the discount.
//   * DiscountType - String - the type of discount.
//   * Scope - String - the scope of the discount.
//   * DiscountID - String - unique identifier of the discount.
//   * DiscountMarkup - String - name of the discount.
//
Procedure ListOfDiscountsByPaymentType(ResponseStructure) Export
	
	Result = EmptyTableOfDiscountsByPaymentType();
	LoyaltyServiceOverridable.FillInTableOfDiscountsDependingOnTypeOfPayment(Result);
	ResponseStructure = SerializeDiscountTableForTypeOfPayment(Result);
	
EndProcedure

// The procedure fills in the disabled loyalty server response
//
// Parameters:
//  ResponseStructure	 - Structure - Structure of the response from the loyalty server.
//  Response			 - HTTPServiceResponse - Loyalty server response.
//
Procedure FillInDisabledLoyaltyServerResponse(ResponseStructure, Response) Export
	
	ResponseStructure.Error = True;
	ResponseStructure.ErrorMessage = NStr("vi = 'Đã ngắt sử dụng máy chủ khách hàng thân thiết trong các tùy chỉnh chương trình.';
											|ru = 'Использование сервера лояльности отключено в настройках программы.';
											|en = 'Loyalty server is disabled in the application settings.'; fa = 'Loyalty server is disabled in the application settings.';
											|it = 'Использование сервера лояльности отключено в настройках программы.';
											|pl = 'Loyalty server is disabled in the application settings.';
											|tr = 'Sadakat sunucusunun kullanımı program ayarlarında devre dışı bırakıldı.'");
	// Returning the response structure
	StructureOfJSONResponse = New JSONWriter;
	StructureOfJSONResponse.SetString();
	WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
	Response.SetBodyFromString(StructureOfJSONResponse.Close());
EndProcedure

// The procedure fills in the answer automatic discounts are not used
//
// Parameters:
//  ResponseStructure	 - Structure - Structure of the response from the loyalty server.
//  Response			 - HTTPServiceResponse - Loyalty server response.
//
Procedure FillInResponseAutomaticDiscounts(ResponseStructure, Response) Export
	
	ResponseStructure.Error = True;
	ResponseStructure.ErrorMessage = NStr("vi = 'Đã ngắt sử dụng chiết khấu tự động trong các tùy chỉnh chương trình.';
											|ru = 'Использование автоматических скидок отключено в настройках программы.';
											|en = 'Automatic discounts are disabled in the application settings.'; fa = 'Automatic discounts are disabled in the application settings.';
											|it = 'Использование автоматических скидок отключено в настройках программы.';
											|pl = 'Automatic discounts are disabled in the application settings.';
											|tr = 'İndirimlerin otomatik kullanımı program ayarlarında devre dışı bırakıldı.'");
	// Returning the response structure
	StructureOfJSONResponse = New JSONWriter;
	StructureOfJSONResponse.SetString();
	WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
	Response.SetBodyFromString(StructureOfJSONResponse.Close());
EndProcedure

// The procedure fills in the empty structure and the name of the Attributes for working with bonuses and certificates
//
// Parameters:
//  AttributesNames	 - Structure - Structure of Attributes names
//
Procedure FillInEmptyStructureNamesOfMetadataAttributes(AttributesNames) Export
	AttributesNames.Insert("BankingDetailsNameDiscountCard", "");
	AttributesNames.Insert("DetailsNamePaymentTable", "");
	AttributesNames.Insert("DetailsNameBonusAmount", "");
	AttributesNames.Insert("NameOfAttributeAmountOfBonusesToBeAccrual", "");
	AttributesNames.Insert("NameOfAttributeBonusPointsForAccrual", "");
	AttributesNames.Insert("CompanyAttributeName", "");
	
	AttributesNames.Insert("PropsNameGiftCard", "");
	AttributesNames.Insert("PropsNameSerialNumber", "");
	AttributesNames.Insert("DetailsNameCertificateRedemptionTable", "");
	AttributesNames.Insert("DetailsNameCertificateRedemptionAmount", "");
	AttributesNames.Insert("AttributeNameTableGiftCardsForAccrual", "");
	AttributesNames.Insert("AttributeNameCertificateAccrualAmount", "");
EndProcedure
#EndRegion

#Region Private

Function ConvertMethodParameterToNumber(ParameterValue)
	
	NumberValue = 0;
	If ParameterValue <> Undefined Then 
		Try
			NumberValue = Number(ParameterValue);
		Except
			NumberValue = 0;
		EndTry;
	EndIf;
	
	Return NumberValue;
	
EndFunction

Function EmptyTableOfManagedDiscounts()
	
	TypeDescriptionNumber = New TypeDescription("Number",,,New NumberQualifiers(15, 2));
	StringTypeDetails = New TypeDescription("String");
	BooleanTypeDetails = New TypeDescription("Boolean");
	
	TableOfManagedDiscounts = New ValueTable;
	TableOfManagedDiscounts.Columns.Add("DiscountValue", TypeDescriptionNumber);
	TableOfManagedDiscounts.Columns.Add("Presentation", StringTypeDetails);
	TableOfManagedDiscounts.Columns.Add("DiscountType", StringTypeDetails);
	TableOfManagedDiscounts.Columns.Add("Scope", StringTypeDetails);
	TableOfManagedDiscounts.Columns.Add("DiscountID", StringTypeDetails);
	TableOfManagedDiscounts.Columns.Add("DiscountMarkup", StringTypeDetails);
	TableOfManagedDiscounts.Columns.Add("WhenReturning", BooleanTypeDetails);
	TableOfManagedDiscounts.Columns.Add("ThisIsBonusAccrualRule", BooleanTypeDetails);
	
	Return TableOfManagedDiscounts;
	
EndFunction

Function SerializeTableOfManagedDiscounts(TableOfManagedDiscounts)
	
	ArrayOfManagedDiscounts = New Array;
	
	For Each TableRow In TableOfManagedDiscounts Do
		
		StructureOfManagedDiscountLine = New Structure;
		StructureOfManagedDiscountLine.Insert("DiscountValue", TableRow.DiscountValue);
		StructureOfManagedDiscountLine.Insert("DiscountDescription", TableRow.Presentation);
		StructureOfManagedDiscountLine.Insert("DiscoutType", TableRow.DiscountType);
		StructureOfManagedDiscountLine.Insert("ApplicationArea", TableRow.Scope);
		StructureOfManagedDiscountLine.Insert("DiscountID", TableRow.DiscountID);
		StructureOfManagedDiscountLine.Insert("DiscountRef", TableRow.DiscountMarkup);
		StructureOfManagedDiscountLine.Insert("Return", TableRow.WhenReturning);
		StructureOfManagedDiscountLine.Insert("Bonuses", TableRow.ThisIsBonusAccrualRule);
		
		// for backward compatibility
		StructureOfManagedDiscountLine.Insert("DiscountValue", TableRow.DiscountValue);
		StructureOfManagedDiscountLine.Insert("Presentation", TableRow.Presentation);
		StructureOfManagedDiscountLine.Insert("DiscountType", TableRow.DiscountType);
		StructureOfManagedDiscountLine.Insert("Scope", TableRow.Scope);
		StructureOfManagedDiscountLine.Insert("DiscountID", TableRow.DiscountID);
		StructureOfManagedDiscountLine.Insert("DiscountMarkup", TableRow.DiscountMarkup);
		StructureOfManagedDiscountLine.Insert("WhenReturning", TableRow.WhenReturning);
		StructureOfManagedDiscountLine.Insert("ThisIsBonusAccrualRule", TableRow.ThisIsBonusAccrualRule);
		
		ArrayOfManagedDiscounts.Add(StructureOfManagedDiscountLine);
		
	EndDo;
	
	Return ArrayOfManagedDiscounts;
	
EndFunction

Function TableOfMapTypes()
	
	BooleanTypeDetails = New TypeDescription("Boolean");
	StringTypeDetails = New TypeDescription("String");
	TypeDescriptionNumber = New TypeDescription("Number",,,New NumberQualifiers(15,2));
	
	TableOfMapTypes = New ValueTable;
	TableOfMapTypes.Columns.Add("Id", StringTypeDetails);
	TableOfMapTypes.Columns.Add("Description", StringTypeDetails);
	TableOfMapTypes.Columns.Add("ThisIsNameCard", BooleanTypeDetails);
	TableOfMapTypes.Columns.Add("GenerateANumber", BooleanTypeDetails);
	TableOfMapTypes.Columns.Add("AssignCardNumberToPhoneNumber", BooleanTypeDetails);
	TableOfMapTypes.Columns.Add("TemplatePresentation", StringTypeDetails);
	TableOfMapTypes.Columns.Add("StartOfRange_", StringTypeDetails);
	TableOfMapTypes.Columns.Add("RangeEnd", StringTypeDetails);
	TableOfMapTypes.Columns.Add("RangeLength", TypeDescriptionNumber);
	
	Return TableOfMapTypes;
	
EndFunction

Function SerializeTableOfMapTypes(TableOfMapTypes)
	
	ArrayOfManagedDiscounts = New Array;
	
	For Each TableRow In TableOfMapTypes Do
		
		StructureOfRowOfMapTypes = New Structure;
		StructureOfRowOfMapTypes.Insert("CardTypeID", TableRow.Id);
		StructureOfRowOfMapTypes.Insert("CardTypeDescription", TableRow.Description);
		StructureOfRowOfMapTypes.Insert("IsPerson", TableRow.ThisIsNameCard);
		StructureOfRowOfMapTypes.Insert("GenerateNumer", TableRow.GenerateANumber);
		StructureOfRowOfMapTypes.Insert("NumberToPhone", TableRow.AssignCardNumberToPhoneNumber);
		StructureOfRowOfMapTypes.Insert("TemplateRepresentation", TableRow.TemplatePresentation);
		StructureOfRowOfMapTypes.Insert("BeginRange", TableRow.StartOfRange_);
		StructureOfRowOfMapTypes.Insert("EndRange", TableRow.RangeEnd);
		StructureOfRowOfMapTypes.Insert("LengthRange", TableRow.RangeLength);
		
		
		// for backward compatibility
		StructureOfRowOfMapTypes.Insert("Id", TableRow.Id);
		StructureOfRowOfMapTypes.Insert("Description", TableRow.Description);
		StructureOfRowOfMapTypes.Insert("ThisIsNameCard", TableRow.ThisIsNameCard);
		StructureOfRowOfMapTypes.Insert("GenerateANumber", TableRow.GenerateANumber);
		StructureOfRowOfMapTypes.Insert("AssignCardNumberToPhoneNumber", TableRow.AssignCardNumberToPhoneNumber);
		StructureOfRowOfMapTypes.Insert("TemplatePresentation", TableRow.TemplatePresentation);
		StructureOfRowOfMapTypes.Insert("StartOfRange_", TableRow.StartOfRange_);
		StructureOfRowOfMapTypes.Insert("RangeEnd", TableRow.RangeEnd);
		StructureOfRowOfMapTypes.Insert("RangeLength", TableRow.RangeLength);
		
		ArrayOfManagedDiscounts.Add(StructureOfRowOfMapTypes);
		
	EndDo;
	
	Return ArrayOfManagedDiscounts;
	
EndFunction

Function EmptyEmployeeTable()
	
	StringTypeDetails = New TypeDescription("String");
	
	EmployeeTable = New ValueTable;
	EmployeeTable.Columns.Add("EmployeePresentation", StringTypeDetails);
	EmployeeTable.Columns.Add("CodeOfEmployee", StringTypeDetails);
	EmployeeTable.Columns.Add("EmployeeID", StringTypeDetails);
	
	Return EmployeeTable;
	
EndFunction

Function EmptySeriesTable()
	
	StringTypeDetails = New TypeDescription("String");
	
	TableOfSeries = New ValueTable;
	TableOfSeries.Columns.Add("SeriesPresentation", StringTypeDetails);
	TableOfSeries.Columns.Add("IDOfSeries", StringTypeDetails);
	
	Return TableOfSeries;
	
EndFunction

Function SerializeEmployeeTable(EmployeeTable)
	
	ArrayOfEmployees = New Array;
	
	For Each TableRow In EmployeeTable Do
		
		StructureOfEmployeeLine = New Structure;
		StructureOfEmployeeLine.Insert("EmployeeDescription", TableRow.EmployeePresentation);
		StructureOfEmployeeLine.Insert("EmployeeCode", TableRow.CodeOfEmployee);
		StructureOfEmployeeLine.Insert("EmployeeID", TableRow.EmployeeID);
		
		ArrayOfEmployees.Add(StructureOfEmployeeLine);
		
	EndDo;
	
	Return ArrayOfEmployees;
	
EndFunction

Function SerializeBatchTable(TableOfSeries)
	
	ArrayOfSeries = New Array;
	
	For Each TableRow In TableOfSeries Do
		
		StringStructureBatch = New Structure;
		StringStructureBatch.Insert("BatchDescription", TableRow.SeriesPresentation);
		StringStructureBatch.Insert("BatchID", TableRow.IDOfSeries);
		
		ArrayOfSeries.Add(StringStructureBatch);
		
	EndDo;
	
	Return ArrayOfSeries;
	
EndFunction

Function SerializeDiscountTableForTypeOfPayment(TableOfDiscountsForTypeOfPayment)
	
	ArrayOfDiscountsForTypeOfPayment = New Array;
	
	If TableOfDiscountsForTypeOfPayment = Undefined Then
		Return ArrayOfDiscountsForTypeOfPayment;
	EndIf;
	
	For Each TableRow In TableOfDiscountsForTypeOfPayment Do
				
		StructureOfLineOfBidForTypeOfPayment = New Structure;
		IDOfDiscount = String(TableRow.DiscountMarkup.UUID());
		StructureOfLineOfBidForTypeOfPayment.Insert("DiscountID", IDOfDiscount);
		StructureOfLineOfBidForTypeOfPayment.Insert("PayType", XMLString(TableRow.PaymentKind_));
				
		ArrayOfDiscountsForTypeOfPayment.Add(StructureOfLineOfBidForTypeOfPayment);
		
	EndDo;
	
	Return ArrayOfDiscountsForTypeOfPayment;
	
EndFunction 

Function ConvertMethodParameterToBoolean(ParameterValue)
	
	ValueBoolean = False;
	If ParameterValue <> Undefined Then 
		Try
			ValueBoolean = Boolean(ParameterValue);
		Except
			ValueBoolean = False;
		EndTry;
	EndIf;
	
	Return ValueBoolean;
	
EndFunction

Procedure GetGeneralResponseParameters(ResponseStructure)
	
	ResponseStructure.Insert("Error", False);
	ResponseStructure.Insert("ErrorMessage", "");
	ResponseStructure.Insert("Version", CommonLoyaltyServerClientServer.LibraryVersion());
	
EndProcedure

// Creates and returns an empty table of values for storing discounts by payment type.
//
// Returns:
//  ValueTable - Table of values with columns:
//   * PaymentKind_ - EnumRef.PaymentKindsLoyaltyServer - the type of payment for which the discount is set;
//   * DiscountMarkup - DefinedType.AutomaticDiscountsLoyaltyServer - discount or extra charge corresponding to the type of payment.
Function EmptyTableOfDiscountsByPaymentType()
	
	TypeOfPaymentType = New TypeDescription("EnumRef.PaymentKindsLoyaltyServer");
	DiscountType = Metadata.DefinedTypes.AutomaticDiscountsLoyaltyServer.Type;
	TableOfDiscountsByTypeOfPayment = New ValueTable();
	TableOfDiscountsByTypeOfPayment.Columns.Add("PaymentKind_", TypeOfPaymentType);
	TableOfDiscountsByTypeOfPayment.Columns.Add("DiscountMarkup", DiscountType);
	
	Return TableOfDiscountsByTypeOfPayment;
	
EndFunction

// The function returns an empty reference of the specified type.
//
// Parameters:
//  RefType - Type - The type of link to get an empty value for.
//
// Returns:
//  AnyRef - An empty link of the specified type.
Function EmptyRef(RefType)
	
	Types = New Array;
	Types.Add(RefType);
	TypeDescription = New TypeDescription(Types);
	
	Return TypeDescription.AdjustValue(Undefined);
	
EndFunction

// The function returns an array of gift cards from the passed array that have the "Gift Certificate accepts a payment from a Member organization" attribute.
//
// Parameters:
//  CertificatesArray	- Array of DefinedType.GiftCardLoyaltyServer - Array of links to gift cards to be filtered
//  Result			- Array of DefinedType.GiftCardLoyaltyServer - Gift cards with activated company control
//
Procedure SelectCertificatesWithCompanyControl(CertificatesArray, Result)
	
	LoyaltyServiceOverridable.SelectCertificatesWithCompanyControl(CertificatesArray, Result)
	
EndProcedure

#EndRegion