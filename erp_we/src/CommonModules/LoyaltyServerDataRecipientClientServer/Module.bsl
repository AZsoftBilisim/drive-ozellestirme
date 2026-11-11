///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the structure for Transferring the source data when accessing the API
//
// Returns:
//  Structure:
//		*RequestType_ - String - the default is "POST"
//		*RequestBody - String
//		*ServerAddress - String
//		*Login - String
//		*Timeout - Number
//		*Password - String
//		*Resource - String
//		*MethodParameters - Structure
//		*InternetProxy - Undefined
//
Function ServerRequestParameters() Export

	ExecutionResult = New Structure();
	ExecutionResult.Insert("RequestType_", "POST");
	ExecutionResult.Insert("RequestBody", "");
	ExecutionResult.Insert("ServerAddress", "");
	ExecutionResult.Insert("Login", "");
	ExecutionResult.Insert("Timeout", 0);
	ExecutionResult.Insert("Password", "");
	ExecutionResult.Insert("Resource", "");
	ExecutionResult.Insert("MethodParameters", New Structure());
	ExecutionResult.Insert("InternetProxy", Undefined);
	
	Return ExecutionResult;

EndFunction

// Returns parameters for connecting to the http service
//
// Parameters:
//  StringForConnection - String - HTTP service connection string
//
// Returns:
//  Structure:
//		*https - Boolean
//		*ConnectionPort - Number
//		*ServerAddress - String
//		*ServiceName - String
//		*StringsError - Boolean
//		*_1CLinkIsUsed - Boolean
//
Function GetConnectionParametersFromLine(StringForConnection) Export
	
	StructureOfConnectionParameters = StructureOfConnectionParameters();
	ConnectionProtocol = StrFind(StringForConnection, "://");
	
	If Upper(Left(StringForConnection, ConnectionProtocol - 1)) = "HTTPS" Then
		StructureOfConnectionParameters.ThisIsSecureConnection = True;
	Else
		StructureOfConnectionParameters.ThisIsSecureConnection = False;
	EndIf;
	
	// Deleting the connection protocol if it is specified in the connection line
	If ConnectionProtocol <> 0 Then
		ServerAddress = Right(StringForConnection, StrLen(StringForConnection) - (ConnectionProtocol + 2));
	Else
		ServerAddress = StringForConnection;
	EndIf;
	
	StructureOfConnectionParameters.ServerAddress = ServerAddress;
	
	// Deleting the path
	SeparatorPosition = StrFind(ServerAddress, "/");
	ServerAddress = ?(SeparatorPosition = 0, ServerAddress, Left(ServerAddress, SeparatorPosition - 1));
	
	If Not StrFind(Upper(ServerAddress), "LINK.1C.RU") = 0 Then
		ServerAddress = StrReplace(ServerAddress, ".link.1c.ru", "");
		StructureOfConnectionParameters.ThisIsSecureConnection = True;
		StructureOfConnectionParameters._1CLinkIsUsed = True;
	Else
		StructureOfConnectionParameters._1CLinkIsUsed = False;
	EndIf;
	
	// Trying to find the connection port
	PositionOfPortSeparator = Find(ServerAddress, ":");
	ServerAddressWithPort = ServerAddress;
	
	If Not PositionOfPortSeparator = 0 Then
		ConnectionPort = Mid(ServerAddressWithPort, PositionOfPortSeparator + 1);
		Try
			StructureOfConnectionParameters.ConnectionPort = Number(ConnectionPort);
		Except
			StructureOfConnectionParameters.StringsError = True;
			Return StructureOfConnectionParameters;
		EndTry;
	Else
		StructureOfConnectionParameters.ConnectionPort = ?(StructureOfConnectionParameters.ThisIsSecureConnection, 443, 80);
	EndIf;
	
	// Find the directory name.
	// It must be "/hs/".
	// Everything after the server address and before /hs/ is the directory name.
	HSPosition = Find(Upper(StringForConnection), "/HS/");
	If HSPosition = 0 Then
		StructureOfConnectionParameters.StringsError = True;
		Return StructureOfConnectionParameters;
	EndIf;
	
	Return StructureOfConnectionParameters;
	
EndFunction

// Checks whether the request parameters are available and full. It is allowed to pass an empty Password and Method parameters
//
// Parameters:
//  RequestExecutionParameters - Structure - the initial data to be Transferred in a request to the server
//
// Returns:
//  Boolean - Test result 
//
Function RequestExecutionParametersAreCorrect(RequestExecutionParameters) Export
	
	RequestDataIsCorrect = True;
	
	If ValueIsFilled(RequestExecutionParameters)
		And TypeOf(RequestExecutionParameters) = Type("Structure") Then
		
		For Each Parameter In RequestExecutionParameters Do
		
// The key and value must be filled in, but the password, method parameters, request body,
// internet proxy, or connection port may be empty
			Var_Key = Parameter.Key;
			If (Var_Key = "Password" Or Var_Key = "MethodParameters" Or Var_Key = "Timeout"
				Or Var_Key = "RequestBody" Or Var_Key = "ConnectionPort" Or Var_Key = "InternetProxy") Then
				Continue;
			Else
				
				KeyAndValueAreFilledIn = CommonClientServer.HasAttributeOrObjectProperty(RequestExecutionParameters, Var_Key)
					And ValueIsFilled(Parameter.Value);
				
				If Not KeyAndValueAreFilledIn Then
					
					RequestDataIsCorrect = False;
					Break;
					
				EndIf;
				
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Return RequestDataIsCorrect;
	
EndFunction

// Generates a data structure for storing the response from the server
//
// Returns:
//  Structure:
//		*ResponseData - String
//		*HasErrors - Boolean
//		*ErrorText - String
//
Function ResultOfDefaultRequest() Export
	
	ExecutionResult = New Structure();
	ExecutionResult.Insert("ResponseData", "");
	ExecutionResult.Insert("HasErrors", True);
	ExecutionResult.Insert("ErrorText", "");

	Return ExecutionResult;

EndFunction

// Accesses the resource of the loyalty server 
//
// Parameters:
//  RequestExecutionParameters - Structure:
//		*RequestType_ - String - the default is "POST"
//		*ServerAddress - String
//		*Login - String
//		*Password - String
//		*Resource - String
//		*MethodParameters - Structure
//		*InternetProxy
//
// Returns:
//  Structure:
//		*ResponseData - String,
//		*HasErrors - Boolean,
//		*ErrorText - String
//
Function MakeRequestToLoyaltyServer(RequestExecutionParameters) Export
	
	Return LoyaltyServerDataRecipientServerCall.MakeRequestToLoyaltyServer(RequestExecutionParameters);
	
EndFunction

// Returns the structure of required parameters for requesting loyalty server Balances
//
// Returns:
//  Structure:
//		*Item - Structure
//		*Variant - Structure
//		*Package - Structure
//		*DisplayNameVariantForPrinting - Structure
//
Function StructureOfParametersForObtainingBalances() Export

	ExecutionResult = New Structure();
	ExecutionResult.Insert("Item");
	ExecutionResult.Insert("Variant");
	ExecutionResult.Insert("Package");
	ExecutionResult.Insert("DisplayNameVariantForPrinting");
	
	Return ExecutionResult;

EndFunction

// Returns the structure of required parameters for the client's card search request
//
// Returns:
//  Structure:
//		*ClientCardID - String
//		*Phone - String
//		*Email - String
//		*BlockBonuses - String
//		*ClientGUID - String
//		*CardGUID - String
//
Function StructureOfParametersToFindClientSCard() Export

	ExecutionResult = New Structure();
	ExecutionResult.Insert("ClientCardID");
	ExecutionResult.Insert("Phone");
	ExecutionResult.Insert("Email");
	ExecutionResult.Insert("BlockBonuses");
	ExecutionResult.Insert("ClientGUID");
	ExecutionResult.Insert("CardGUID");
	ExecutionResult.Insert("ClientID");
	
	Return ExecutionResult;

EndFunction

// Returns the structure of required parameters for a request to the loyalty server bonus subsystem
//
// Returns:
//  Structure:
//		*ClientCardID - String
//		*Phone - String
//		*Email - String
//		*Client - String
//		*Store - String
//		*GiftCardNumber - String
//		*GiftCardUID - String
//		*BonusesCount - String
//		*GiftCardWriteOffAmount - String
//		*Promocode - String
//		*DateOfBirth - String
//		*ClientCardTypeUID - String
//
Function ParametersOfBonusSubsystemMethods() Export

	ExecutionResult = New Structure();
	ExecutionResult.Insert("ClientCardID");
	ExecutionResult.Insert("CardGUID");
	ExecutionResult.Insert("Phone");
	ExecutionResult.Insert("Email");
	ExecutionResult.Insert("Client");
	ExecutionResult.Insert("Store");
	ExecutionResult.Insert("GiftCardNumber");
	ExecutionResult.Insert("GiftCardUID");
	ExecutionResult.Insert("BonusesCount");
	ExecutionResult.Insert("GiftCardWriteOffAmount");
	ExecutionResult.Insert("Promocode");
	ExecutionResult.Insert("DateOfBirth");
	ExecutionResult.Insert("ClientCardTypeUID");
	ExecutionResult.Insert("Currency");
	ExecutionResult.Insert("GenerateNumber");
	ExecutionResult.Insert("Replacement");
	
	Return ExecutionResult;

EndFunction

// Returns the structure of required parameters for the discount calculation request to the loyalty server
//
// Returns:
//  Structure:
//		*RecoverManagedDiscounts - Boolean
//		*ObjectTime - Date
//		*CurrentDate - Date
//		*LoyaltyCardPresented - Boolean
//		*HasGifts - Boolean
//		*UseApplicationPrices - Boolean
//		*ControlBalanceOfGoods - Boolean
//		*LoyaltyCardsList - Array of String - Array of card codes
//		*RetailStore - see getstructurelinks
//		*ApplyObject - Boolean
//		*WorkPlace - see getstructurelinks
//		*Goods - See StructureOfGoodsForCalculatingDiscounts
//		*GetLoyaltyCardData - Boolean
//		*GetMaxBonusPay - Boolean
//		*BlockBonuses - String - "0" or "1"
//		*BonusesGUID - String
//		*GetPossibleBonusesToAccrual - Boolean
//		*GetDiscountsFromParentDocument - Boolean
//		*CheckToReturn - String - Receipt TYPE-grounds for refund
//
Function StructureOfDiscountCalculationParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("RecoverManagedDiscounts");
	ParametersStructure.Insert("ObjectTime");
	ParametersStructure.Insert("CurrentDate");
	ParametersStructure.Insert("LoyaltyCardPresented");
	ParametersStructure.Insert("HasGifts");
	ParametersStructure.Insert("UseApplicationPrices");
	ParametersStructure.Insert("ControlBalanceOfGoods");
	ParametersStructure.Insert("LoyaltyCardsList");
	ParametersStructure.Insert("PromocodesList");
	ParametersStructure.Insert("ControlledDiscountsList");
	ParametersStructure.Insert("RetailStore");
	ParametersStructure.Insert("ApplyObject");
	ParametersStructure.Insert("WorkPlace");
	ParametersStructure.Insert("Goods");
	ParametersStructure.Insert("GetLoyaltyCardData");
	ParametersStructure.Insert("GetMaxBonusPay");
	ParametersStructure.Insert("BlockBonuses");
	ParametersStructure.Insert("Currency");
	ParametersStructure.Insert("Return");
	ParametersStructure.Insert("PayTypes");
	ParametersStructure.Insert("GetPossibleOnPayDiscounts");
	ParametersStructure.Insert("BonusesGUID");
	ParametersStructure.Insert("GetPossibleBonusesToAccrual", False);
	ParametersStructure.Insert("GetDiscountsFromParentDocument");
	ParametersStructure.Insert("CheckToReturn");
	
	Return ParametersStructure;
	
EndFunction

// Returns the structure of the products to fill in the parameters for calculating discounts by the loyalty server
//
// Returns:
//  Structure:
//		*LineUID - String
//		*Count - Number
//		*PackagesCount - Number
//		*Item - see getstructurelinks
//		*Price - Number
//		*GiftSale - Boolean
//		*PercentOfAutomaticDiscount - Number
//		*PercentOfManualDiscount - Number
//		*VATRate - String
//		*Amount - Number
//		*AmountOfAutomaticDiscount - Number
//		*TotalAmount - Number
//		*VATAmount - Number
//		*AmountOfManualDiscount - Number
//		*Package - see getstructurelinks
//		*Variant - see getstructurelinks
//		*CheckToReturn - Structure
//
Function StructureOfGoodsForCalculatingDiscounts() Export
	
	StringStructure = New Structure;
	StringStructure.Insert("LineUID");
	StringStructure.Insert("Count");
	StringStructure.Insert("PackagesCount");
	StringStructure.Insert("Item");
	StringStructure.Insert("Price");
	StringStructure.Insert("GiftSale");
	StringStructure.Insert("PercentOfAutomaticDiscount");
	StringStructure.Insert("PercentOfManualDiscount");
	StringStructure.Insert("VATRate");
	StringStructure.Insert("Amount");
	StringStructure.Insert("AmountOfAutomaticDiscount");
	StringStructure.Insert("TotalAmount");
	StringStructure.Insert("VATAmount");
	StringStructure.Insert("AmountOfManualDiscount");
	StringStructure.Insert("Package");
	StringStructure.Insert("Variant");
	StringStructure.Insert("Organization");
	StringStructure.Insert("CheckToReturn");
	
	Return StringStructure;
	
EndFunction

// Returns the structure of promo codes for filling in the parameters for calculating discounts by the loyalty server
//
// Returns:
//  Structure:
//		*Promocode - String
//		*PromocodeDiscountUID - String
//		*PromocodeUID - String
//
Function StructureOfPromoCodesForCalculatingDiscounts() Export
	
	StringStructure = New Structure;
	StringStructure.Insert("Promocode");
	StringStructure.Insert("PromocodeDiscountUID");
	StringStructure.Insert("PromocodeUID");
	
	Return StringStructure;
	
EndFunction

// Returns the structure of the selected managed discount to fill in the parameters for calculating discounts by the loyalty server
//
// Returns:
//  Structure:
//		*ControlledDiscount - String
//		*ControlledDiscountUID - String
//		*LineUID - String
//		*KeyRelation - Number
//
Function StructureOfSelectedManagedDiscount() Export
	
	StringStructure = New Structure;
	StringStructure.Insert("ControlledDiscount");
	StringStructure.Insert("ControlledDiscountUID");
	StringStructure.Insert("LineUID");
	StringStructure.Insert("KeyRelation");
	
	Return StringStructure;
	
EndFunction  


// Returns the structure of possible types of payments and signs of their use to fill in the parameters for calculating discounts by the loyalty server
//
// Returns:
//  Structure:
//		*PayType - String
//		*IsUsed - Boolean
//
Function StructureOfSelectedTypeOfPayment() Export
	
	StringStructure = New Structure;
	StringStructure.Insert("PayType");
	StringStructure.Insert("IsUsed");
	
	Return StringStructure;
	
EndFunction


// Returns the structure of the link to be Transferred to the loyalty server
//
// Parameters:
//  Ref - any link
//
// Returns:
//  Structure:
//		*Ref - String Presentation of a unique link identifier,
//		*Name - String Presentation of the link
//
Function GetLinkParameters(Ref) Export
	
	RefStructure = New Structure;
	RefStructure.Insert("Ref");	//String Presentation of a unique link identifier
	RefStructure.Insert("Name");	//String Presentation of the link
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLinkStructure(RefStructure, Ref);
	
	Return RefStructure;
	
EndFunction

// Returns the result of processing data from the default response 
//
// Returns:
//  Structure:
//		*ExecutionIsSuccessful - Boolean
//		*Comment - String - additional information about the State of execution
//
Function DefaultDataProcessingResult() Export
	
	Result = New Structure();
	Result.Insert("ExecutionIsSuccessful", False);
	Result.Insert("Comment", "");
	
	Return Result;
	
EndFunction

// Method for processing JSON
//
// Parameters:
//  JSONString - String - source data in JSON format
//  ResponseData - Structure, Undefined - result of parsing the response
//
Procedure ProcessJSON(JSONString, ResponseData) Export
	
	Try
		
		#If WebClient Then
			LoyaltyServerDataRecipientServerCall.ProcessJSON(JSONString, ResponseData);
		#Else
			ReadResponse = New JSONReader;
			ReadResponse.SetString(JSONString);
			ResponseData = ReadJSON(ReadResponse);
		#EndIf
		
	Except
		
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		EventName = NStr("vi = 'Thử phân tích phản hồi từ chương trình khách hàng thân thiết.';
						|ru = 'Попытка разбора ответа от сервера лояльности.';
						|en = 'An attempt to parse the response from the loyalty server.'; fa = 'An attempt to parse the response from the loyalty server.';
						|it = 'An attempt to parse the response from the loyalty server.';
						|pl = 'An attempt to parse the response from the loyalty server.';
						|tr = 'Sadakat sunucusundan gelen yanıtı ayrıştırma girişimi'", DefaultLanguageCode);
		
		LocalizedMessage = NStr("vi = 'Lỗi phân tích cú pháp JSON, có thể là đã nhận thông báo hệ thống về chương trình khách hàng thân thiết không hợp lệ.';
								|ru = 'Ошибка разбора JSON, возможно, получено служебное сообщение о недоступности сервера лояльности.';
								|en = 'An error occurred when parsing JSON. An internal message about the loyalty server unavailability might have been received.'; fa = 'An error occurred when parsing JSON. An internal message about the loyalty server unavailability might have been received.';
								|it = 'Ошибка разбора JSON, возможно, получено служебное сообщение о недоступности сервера лояльности.';
								|pl = 'An error occurred when parsing JSON. An internal message about the loyalty server unavailability might have been received.';
								|tr = 'JSON ayrıştırma hatası, sadakat sunucusunun kullanılamadığına dair bir hizmet mesajı alınmış olabilir.'");
		LoyaltyServerDataRecipientServerCall.WriteEventsToEventLog(EventName, LocalizedMessage);
		
	EndTry;
		
EndProcedure

// Fills in the list of managed discounts
//
// Parameters:
//  UseLoyaltyServerDataRecipient - Boolean - whether the loyalty server is being used
//  TableOfManagedDiscounts - ValueTable - returned value
//
Procedure FillInTableOfManagedDiscounts(UseLoyaltyServerDataRecipient, TableOfManagedDiscounts) Export
	
	If UseLoyaltyServerDataRecipient Then
		Return;
	Else
		LoyaltyServerDataRecipientClientServerOverridable.FillInTableOfManagedDiscounts(TableOfManagedDiscounts);
	EndIf;
	
EndProcedure

// Returns the structure of required parameters for requesting employees to the loyalty server
//
// Returns:
//  Structure - Structure of Employee Request Parameters:
//		*Store - Structure - the structure of the store's link.
//
Function StructureOfEmployeeRequestParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Store");
	
	Return ParametersStructure;
	
EndFunction

#Region ParametersOfLoyaltyServerRequests

// Returns the structure of the ping request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersCheckConnectionToLoyaltyServer(RequestParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "ping";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the Get Customer request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersGetClientBonuses(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "getclientbonuses";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersGetClientBonuses(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the Unblocking client request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//  ResourceName - String - Name of the loyalty server method.
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersToUnlockClientBonuses(RequestParameterValues, MethodParameterValues, ResourceName = "unlockclientbonuses") Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = ResourceName;
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersUnlockClientBonuses(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to write off the customer for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//  ResourceName - String - Name of the loyalty server method.
////
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersForWritingOffClientBonuses(RequestParameterValues, MethodParameterValues, ResourceName = "writeoffclientbonuses") Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = ResourceName;
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInParametersOfRequestToWriteOFFClientSBonuses(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the Get Sales Turnover request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersGetSalesTurnover(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "salesturnover";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersGetClientBonuses(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to issue a customer card for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function ParametersOfIssueCardToClientRequest(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "issueclientcard";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	MethodParameters.Insert("Client");
	LoyaltyServerDataRecipientClientServerOverridable.FillInParametersOfRequestToIssueCardToClient(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the Sales information request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersDataOnEditingBans(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "salesrestrictionsinfo";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersAndDataOnEditingBans(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to get the data of the Certificate of the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//  RequestType_ - String - Type of GET or POST request. By default, the request type is "GET".
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersForGettingGiftCardData(RequestParameterValues, MethodParameterValues, RequestType_ = "GET") Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = RequestType_;
	QueryOptions.Resource = "getgiftcardinfo";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = GiftCardParameters();

	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersToGetGiftCardDetails(MethodParameters, MethodParameterValues);
	
	If RequestType_ = "GET" Then
		QueryOptions = ParametersOfGetGiftCardDataGETRequest(MethodParameters, QueryOptions);
	Else
		QueryOptions = RequestParametersForGettingPOSTGiftCardData(MethodParameters, QueryOptions);
	EndIf;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to unblock a custom certificate for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//  ResourceName - String - Name of the loyalty server method.
////
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersToUnlockGiftCard(RequestParameterValues, MethodParameterValues, ResourceName = "unlockgiftcard") Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = ResourceName;
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersToUnlockGiftCard(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to get the data of the PROMO code for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersForGettingPromoCodeData(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "promocodeinfo";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersToGetPromoCodeData(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to unblock the loyalty server promo code
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//  ResourceName - String - Name of the loyalty server method.
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersForUnblockingPromoCode(RequestParameterValues, MethodParameterValues, ResourceName = "unlockpromocode") Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = ResourceName;
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersToUnlockPromoCode(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the Redeem Promo code request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersRedeemPromoCode(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "redeempromocode";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersRedeemPromoCode(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the Activate Promo Code request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersActivatePromoCode(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "activatepromocode";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersActivatePromoCode(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to write off a custom certificate for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//  ResourceName - String - Name of the loyalty server method.
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersForWritingOffGiftCard(RequestParameterValues, MethodParameterValues, ResourceName = "writeoffgiftcard") Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = ResourceName;
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = GiftCardParameters();
	MethodParameters.Insert("GiftCardWriteOffAmount");
	LoyaltyServerDataRecipientClientServerOverridable.FillInParametersOfRequestToWriteOffGiftCard(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to use automatic discounts for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersUseAutomaticDiscounts(RequestParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "useautomaticdiscounts";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to calculate automatic discounts for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See StructureOfDiscountCalculationParameters
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersCalculateAutomaticDiscounts(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "calculatediscounts";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	StructureOfDiscountCalculationParameters = StructureOfDiscountCalculationParameters();
	LoyaltyServerDataRecipientClientServerOverridable.FillInStructureOfDiscountCalculationParameters(StructureOfDiscountCalculationParameters, MethodParameterValues);

	#If WebClient Then
		SerializedParameterStructure = LoyaltyServerDataRecipientServerCall.SerializeParameterStructure(StructureOfDiscountCalculationParameters);
	#Else
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, StructureOfDiscountCalculationParameters);
		SerializedParameterStructure = StructureOfJSONResponse.Close();
	#EndIf
	
	QueryOptions.RequestBody = SerializedParameterStructure;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to get a table of manageable discounts for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersToGetTableOfManagedDiscounts(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "getcontrolleddiscountslist";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	QueryOptions.MethodParameters = MethodParameterValues;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to get data for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See StructureOfParametersForObtainingBalances
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersForGettingBalances(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "getleftovers";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	StructureOfParametersForObtainingBalances = StructureOfParametersForObtainingBalances();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersToGetBalances(StructureOfParametersForObtainingBalances, MethodParameterValues);
	
	#If WebClient Then
		SerializedParameterStructure = LoyaltyServerDataRecipientServerCall.SerializeParameterStructure(StructureOfParametersForObtainingBalances);
	#Else
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, StructureOfParametersForObtainingBalances);
		SerializedParameterStructure = StructureOfJSONResponse.Close();
	#EndIf
	
	QueryOptions.RequestBody = SerializedParameterStructure;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of a customer's request for a loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function ParametersOfFindClientCardRequest(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "findclientcard";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	QueryOptions.MethodParameters = MethodParameterValues;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the Get a Video Card request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function ParametersOfGetMapTypesRequest(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "getcardtypes";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = MethodParameterValues;
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the Get Employee tables request for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function ParametersOfGetEmployeeTableRequest(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "listofemployees";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	StructureOfEmployeeRequestParameters = StructureOfEmployeeRequestParameters();
	LoyaltyServerDataRecipientClientServerOverridable.FillInStructureOfEmployeeRequestParameters(StructureOfEmployeeRequestParameters, MethodParameterValues);
	
	#If WebClient Then
		SerializedParameterStructure = LoyaltyServerDataRecipientServerCall.SerializeParameterStructure(StructureOfEmployeeRequestParameters);
	#Else
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, StructureOfEmployeeRequestParameters);
		SerializedParameterStructure = StructureOfJSONResponse.Close();
	#EndIf
	
	QueryOptions.RequestBody = SerializedParameterStructure;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to check the data of the loyalty server's certificate card
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersToVerifyGiftCertificateDetails(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "checkgiftcard";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersToGetGiftCardDetails(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to fill in the list of Serial nomenclature selections for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See StructureOfDiscountCalculationParameters
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function SeriesRequestParameters(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "getlistbatches";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	StructureOfBatchRequestParameters = StructureOfBatchRequestParameters();
	LoyaltyServerDataRecipientClientServerOverridable.FillInStructureOfBatchRequestParameters(StructureOfBatchRequestParameters, MethodParameterValues);
	
	QueryOptions.MethodParameters = MethodParameterValues;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to fill in the data series to the identifier for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See StructureOfDiscountCalculationParameters
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function SeriesDataRequestParameters(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "getseriesdata";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	StructureOfBatchRequestParameters = StructureOfBatchDataRequestParameters();
	LoyaltyServerDataRecipientClientServerOverridable.FillInStructureOfBatchDataRequestParameters(StructureOfBatchRequestParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameterValues;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to process the tagging code for the loyalty server
//
// Parameters:
//  RequestParameterValues	 - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                           ()
//  MethodParameterValues	 - Structure - Structure for filling in the parameters of the request method to the server
// 
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersToProcessMarkingCode(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "processmarkingcode";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	StructureOfParametersOfProcessingMarkingCode = Undefined;
	LoyaltyServerDataRecipientClientServerOverridable.FillInStructureOfParametersForProcessingMarkingCode(StructureOfParametersOfProcessingMarkingCode, MethodParameterValues);

	#If WebClient Then
		SerializedParameterStructure = LoyaltyServerDataRecipientServerCall.SerializeParameterStructure(StructureOfParametersOfProcessingMarkingCode);
	#Else
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, StructureOfParametersOfProcessingMarkingCode);
		SerializedParameterStructure = StructureOfJSONResponse.Close();
	#EndIf
	
	QueryOptions.RequestBody = SerializedParameterStructure;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to process the tagging code for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server
//
// Returns:
//  See ServerRequestParameters
//
Function ParametersOfRequestToGetStateIPAuthorizationToken(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "getgosisauthorizationtoken";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	StructureOfParametersForObtainingStateIPAuthorizationToken = Undefined;
	LoyaltyServerDataRecipientClientServerOverridable.FillInStructureOfParametersForObtainingStateIPAuthorizationToken(StructureOfParametersForObtainingStateIPAuthorizationToken, MethodParameterValues);

	#If WebClient Then
		SerializedParameterStructure = LoyaltyServerDataRecipientServerCall.SerializeParameterStructure(StructureOfParametersForObtainingStateIPAuthorizationToken);
	#Else
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, StructureOfParametersForObtainingStateIPAuthorizationToken);
		SerializedParameterStructure = StructureOfJSONResponse.Close();
	#EndIf
	
	QueryOptions.RequestBody = SerializedParameterStructure;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request parametersadded prices for the loyalty server
//
// Parameters:
//  RequestParameterValues	 - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                           ()
//  MethodParameterValues	 - Structure - Structure for filling in the parameters of the request method to the server See StructureOfPriceRequestParameters
//                                          ()
// 
// Returns:
//  See ServerRequestParameters
//
Function ParametersForRequestingPriceData(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "getprice";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	StructureOfPriceRequestParameters = StructureOfPriceRequestParameters();
	LoyaltyServerDataRecipientClientServerOverridable.FillInStructureOfParametersCurrentPrice(StructureOfPriceRequestParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameterValues;
	
	Return QueryOptions;
	
EndFunction 

// Returns the structure of required parameters for requesting discounts, which may depend on the selected payment type
//
// Parameters:
//  RequestParameterValues	 - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                           ()
//  MethodParameterValues	 - Structure - Structure for filling in the parameters of the request method to the server See StructureOfDiscountCalculationParameters
//                                          ()
// 
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersToGetTableOfDiscountsDependingOnTypeOfPayment(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "GET";
	QueryOptions.Resource = "getlistonpaydiscounts";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	QueryOptions.MethodParameters = MethodParameterValues;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to write off the customer for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersToCombineBonusCards(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "unitedbonuscards";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = StructureOfMapMergeParameters();
	LoyaltyServerDataRecipientClientServerOverridable.FillInParametersOfCombineDiscountCardsRequest(MethodParameters, MethodParameterValues);
	
	#If WebClient Then
		SerializedParameterStructure = LoyaltyServerDataRecipientServerCall.SerializeParameterStructure(MethodParameters);
	#Else
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, MethodParameters);
		SerializedParameterStructure = StructureOfJSONResponse.Close();
	#EndIf
	
	QueryOptions.RequestBody = SerializedParameterStructure;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to charge a customer for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersAddClientBonuses(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "accrueclientbonuses";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = ParametersOfBonusSubsystemMethods();
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersAndAddClientBonuses(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

// Returns the structure of the request to charge a gift certificate for the loyalty server
//
// Parameters:
//  RequestParameterValues - Structure - Structure for filling in the parameters of the request to the server See ServerRequestParameters
//                                          ()
//  MethodParameterValues - Structure - Structure for filling in the parameters of the request method to the server See ParametersOfBonusSubsystemMethods
//                                         ()
//
// Returns:
//  See ServerRequestParameters
//
Function RequestParametersToAddGiftCard(RequestParameterValues, MethodParameterValues) Export
	
	QueryOptions = ServerRequestParameters();
	QueryOptions.RequestType_ = "POST";
	QueryOptions.Resource = "accruegiftcard";
	
	LoyaltyServerDataRecipientClientServerOverridable.FillInLoyaltyServerParameters(QueryOptions, RequestParameterValues);
	
	MethodParameters = GiftCardParameters();
	MethodParameters.Insert("GiftCardAccrueOffAmount");
	LoyaltyServerDataRecipientClientServerOverridable.FillInRequestParametersAndAddGiftCard(MethodParameters, MethodParameterValues);
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction
#EndRegion

// Returns the structure of required parameters for requesting series to the loyalty server
//
// Returns:
//  Structure:
//    *Store - String - UID of the Shopping facility
//    *TypeProduct - String - Item Type UID
//    *Product - String - Nomenclature UID
//    *Characteristic - String - UID Characteristics
//    *UIDBatch - String - UID Series
//    *TypeOperationSale - Boolean - indicates the type of operation sales
//
Function StructureOfBatchRequestParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Store");
	ParametersStructure.Insert("TypeProduct");
	ParametersStructure.Insert("Product");
	ParametersStructure.Insert("Characteristic");
	ParametersStructure.Insert("UIDBatch");
	ParametersStructure.Insert("TypeOperationSale");
	
	Return ParametersStructure;
	
EndFunction

// Returns the structure of required parameters for requesting series data to the loyalty server
//
// Returns:
//  Structure:
//		*BatchUID - Structure - see Get Link Structure ()
//
Function StructureOfBatchDataRequestParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("BatchUID");
	
	Return ParametersStructure;
	
EndFunction

// Returns the structure of required parameters for requesting series to the loyalty server
//
// Returns:
//  Structure:
//    *Store - String - UID of the Shopping facility
//    *TypeProduct - String - Item Type UID
//    *Product - String - Nomenclature UID
//    *Characteristic - String - UID Characteristics
//    *UIDBatch - String - UID Series
//
Function StructureOfPriceRequestParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("TypePriceUID");
	ParametersStructure.Insert("Product");
	ParametersStructure.Insert("Characteristic");
	ParametersStructure.Insert("BatchUID");
	
	Return ParametersStructure;
	
EndFunction

// Returns the structure of required parameters for requesting series to the loyalty server
//
// Returns:
//  Structure:
//		*Store - String - Unique identifier of the shopping facility.
//
Function ParametersOfMethodForFillingInTypesOfCards() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Store");
	
	Return ParametersStructure;
	
EndFunction

// Returns the structure of required parameters for a request to managed discounts on the loyalty server
//
// Returns:
//  Structure:
//		*MaxSale - String - The maximum value of the manual discount.
//		*MaxMarkup - String - The maximum value of the manual markup.
//		*Store - String - Unique identifier of the shopping facility.
//		*Client - String - Unique identifier of the counterparty.
//		*CardGUID - String - Unique ID of the loyalty card.
//		*ClientCardID - String - Loyalty card number.
//		*UseSelection - Boolean - Use selection in the management database.
//		*DiscountsAllowed - Boolean - Manual discounts are allowed.
//
Function ParametersOfMethodForFillingManagedDiscounts() Export

	ExecutionResult = New Structure();
	ExecutionResult.Insert("MaxSale");
	ExecutionResult.Insert("MaxMarkup");
	ExecutionResult.Insert("Store");
	ExecutionResult.Insert("Client");
	ExecutionResult.Insert("CardGUID");
	ExecutionResult.Insert("ClientCardID");
	ExecutionResult.Insert("UseSelection");
	ExecutionResult.Insert("DiscountsAllowed");
	
	Return ExecutionResult;

EndFunction

// Returns the structure of required parameters for combining discount cards.
//
// Returns:
//  Structure:
//		*BonusCards - Array
//		*BonusProgramm - String
//
Function StructureOfMapMergeParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("BonusCards");
	ParametersStructure.Insert("BonusCardGUID");
	ParametersStructure.Insert("BonusCardNumber");
	ParametersStructure.Insert("BonusProgramm");
	
	Return ParametersStructure;
	
EndFunction

// Returns the structure of bonus cards for combining discount cards.
//
// Returns:
//  Structure:
//		*CardGUID - String
//		*CardNumber - String
//		*BonusesCount - Number
//
Function StructureOfBonusCardLine() Export
	
	StringStructure = New Structure;
	StringStructure.Insert("CardGUID");
	StringStructure.Insert("CardNumber");
	StringStructure.Insert("BonusesCount");
	
	Return StringStructure;
	
EndFunction

// Returns the structure of required parameters for requesting gift certificates
//
// Returns:
//  Structure:
//		*GiftCardNumber - String - Gift Card Number
//		*GiftCardUID - String - unique identifier
//		*Organization - String - unique identifier
//		*Goods - Array - List of goods SeeStructureOfGoodsForGiftCard
//                    ()
//
Function GiftCardParameters() Export

	ParametersStructure = New Structure();
	ParametersStructure.Insert("GiftCardNumber");
	ParametersStructure.Insert("GiftCardUID");
	ParametersStructure.Insert("Organization");
	ParametersStructure.Insert("Goods");
	
	Return ParametersStructure;

EndFunction

// Returns the structure of the products to fill in the parameters for calculating discounts by the loyalty server
//
// Returns:
//  Structure:
//		*Item - Structure - For the item list of the product line, see Get the Link structure
//		*Variant - Structure - Product line characteristics, see Get the Link structure
//		*Amount - Number - Amount Including Discount
//
Function StructureOfGoodsForGiftCard() Export
	
	StringStructure = New Structure;
	StringStructure.Insert("Item");
	StringStructure.Insert("Variant");
	StringStructure.Insert("Amount");
	
	Return StringStructure;
EndFunction
#EndRegion

#Region Private

// Returns the structure of the http service connection parameters
//
// Returns:
//  Structure:
//		*ThisIsSecureConnection - Boolean
//		*ConnectionPort - Number
//		*ServerAddress - String
//		*ServiceName - String
//		*StringsError - Boolean
//		*_1CLinkIsUsed - Boolean
//
Function StructureOfConnectionParameters()
	
	StructureOfConnectionParameters = New Structure;
	StructureOfConnectionParameters.Insert("ThisIsSecureConnection", False);
	StructureOfConnectionParameters.Insert("ConnectionPort", 80);
	StructureOfConnectionParameters.Insert("ServerAddress", "");
	StructureOfConnectionParameters.Insert("ServiceName", "");
	StructureOfConnectionParameters.Insert("StringsError", False);
	StructureOfConnectionParameters.Insert("_1CLinkIsUsed", False);
	
	Return StructureOfConnectionParameters;
	
EndFunction


Function ParametersOfGetGiftCardDataGETRequest(MethodParameters, QueryOptions)
	
	QueryOptions.MethodParameters = MethodParameters;
	
	Return QueryOptions;
	
EndFunction

Function RequestParametersForGettingPOSTGiftCardData(MethodParameters, QueryOptions)
	
	#If WebClient Then
		SerializedParameterStructure = LoyaltyServerDataRecipientServerCall.SerializeParameterStructure(MethodParameters);
	#Else
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, MethodParameters);
		SerializedParameterStructure = StructureOfJSONResponse.Close();
	#EndIf
	
	QueryOptions.RequestBody = SerializedParameterStructure;
	
	Return QueryOptions;
	
EndFunction
#EndRegion
