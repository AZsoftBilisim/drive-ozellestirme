///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Fills in the structure of request parameters for the loyalty server
//
// Parameters:
//  MainParameters - Structure - Structure for filling in the parameters of the request to the server See LoyaltyServerDataRecipientClientServer.ServerRequestParameters
//  RequestParameterValues - Structure - Structure for filling in the main parameters
//
Procedure FillInLoyaltyServerParameters(MainParameters, RequestParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the Get Client request method
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersGetClientBonuses(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the parameter structure of the Unblocking Client request method
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersUnlockClientBonuses(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the parameter structure of the request method to write off the client
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInParametersOfRequestToWriteOFFClientSBonuses(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to issue a card to the client
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInParametersOfRequestToIssueCardToClient(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the method for requesting information about sales orders
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersAndDataOnEditingBans(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to get the data of the certificate
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersToGetGiftCardDetails(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to get the data of the promo code
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersToGetPromoCodeData(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method unblockpromocode
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersToUnlockPromoCode(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to unlock the signature certificate
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersToUnlockGiftCard(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to write off the gift certificate
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInParametersOfRequestToWriteOffGiftCard(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to cancel the promo code
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersRedeemPromoCode(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the parameter structure of the Activate Promo Code request method
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersActivatePromoCode(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to calculate automaticskids
//
// Parameters:
//  StructureOfDiscountCalculationParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.StructureOfDiscountCalculationParameters
//  MethodParameterValues - Structure - Structure to fill in the structureparameterscounts
//
Procedure FillInStructureOfDiscountCalculationParameters(StructureOfDiscountCalculationParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the link structure for Transferring to the loyalty server
//
// Parameters:
//  RefStructure - Structure - Link structure See LoyaltyServerDataRecipientClientServer.
//  Ref - AnyRef
//
Procedure FillInLinkStructure(RefStructure, Ref) Export
	

	
EndProcedure

// Fills in the code of the main configuration language, for example "ru".
//
// Parameters:
//  DefaultLanguageCode - String
//
Procedure FillInMainLanguageCode(DefaultLanguageCode) Export
	
	DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
	
EndProcedure

// Fills in the list of managed discounts
//
// Parameters:
//  Result - ValueTable - returned value
//  CalculationParameters - Structure - a structure containing parameters for selecting managed discounts
//
Procedure FillInTableOfManagedDiscounts(Result, CalculationParameters = Undefined) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the Get Data request method
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.StructureOfParametersForObtainingBalances
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersToGetBalances(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the list of card types
//
// Parameters:
//  Result - Undefined, ValueTable - returned value
//  CalculationParameters - Structure - a structure containing settings for working with types of discount cards
//
Procedure FillInTableOfCardTypes(Result, CalculationParameters) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to fill in the Employees table
//
// Parameters:
//  StructureOfEmployeeRequestParameters - See LoyaltyServerDataRecipientClientServer.StructureOfEmployeeRequestParameters
//  MethodParameterValues - Structure - Structure for filling in the structureparameters for employees
//
Procedure FillInStructureOfEmployeeRequestParameters(StructureOfEmployeeRequestParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request methodsfill listselection of serial nomenclature
//
// Parameters:
//  StructureOfBatchRequestParameters - See LoyaltyServerDataRecipientClientServer.StructureOfDiscountCalculationParameters
//  MethodParameterValues - Structure - Structure to fill in the structureparameterscounts
//
Procedure FillInStructureOfBatchRequestParameters(StructureOfBatchRequestParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to fill in the data series to the identifier
//
// Parameters:
//  StructureOfBatchRequestParameters - See LoyaltyServerDataRecipientClientServer.StructureOfDiscountCalculationParameters
//  MethodParameterValues - Structure - Structure to fill in the structureparameterscounts
//
Procedure FillInStructureOfBatchDataRequestParameters(StructureOfBatchRequestParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to process the labeling code
//
// Parameters:
//  StructureOfParametersOfProcessingMarkingCode - Structure - Structure for filling in the parameters of the request method to the server
//  MethodParameterValues - Structure - Structure to fill in the structureparameters of the processing of the labeling code
//
Procedure FillInStructureOfParametersForProcessingMarkingCode(StructureOfParametersOfProcessingMarkingCode, MethodParameterValues) Export
	
	
	
EndProcedure

// Fills in the structure of the parameters of the gettokauthorizationgosis request method
//
// Parameters:
//  StructureOfParametersForObtainingStateIPAuthorizationToken - Structure - Structure for filling in the parameters of the request method to the server
//  MethodParameterValues - Structure - Structure to fill in the structure of the parameters of the receipt of the certificate of authorizationigosis
//
Procedure FillInStructureOfParametersForObtainingStateIPAuthorizationToken(StructureOfParametersForObtainingStateIPAuthorizationToken, MethodParameterValues) Export
	
	
	
EndProcedure

// Fills in the structure of the parameters of the request method to fill in the structureparametersactual price
//
// Parameters:
//  StructureOfPriceRequestParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.StructureOfPriceRequestParameters
//  MethodParameterValues - Structure - Structure to fill in the structureparameterscounts
//
Procedure FillInStructureOfParametersCurrentPrice(StructureOfPriceRequestParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the list of discounts depending on the type of payment
//
// Parameters:
//  Result - ValueTable - returned value
//
Procedure FillInTableOfDiscountsDependingOnTypeOfPayment(Result) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the Merge Customcharts request method
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.StructureOfMapMergeParameters
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInParametersOfCombineDiscountCardsRequest(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to charge the client
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersAndAddClientBonuses(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure

// Fills in the structure of the parameters of the request method to charge a gift certificate
//
// Parameters:
//  MethodParameters - Structure - Structure for filling in the parameters of the request method to the server See LoyaltyServerDataRecipientClientServer.ParametersOfBonusSubsystemMethods
//  MethodParameterValues - Structure - Structure for filling in the parameter method
//
Procedure FillInRequestParametersAndAddGiftCard(MethodParameters, MethodParameterValues) Export
	

	
EndProcedure
#EndRegion