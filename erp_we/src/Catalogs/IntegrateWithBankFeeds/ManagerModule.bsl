#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Checks whether the email exchange settings are available in the program
// 
// Parameters:
//   Owner - CatalogRef.IntegrateWithBankFeeds - Link To Settings
// 
// Returns:
//  Structure - data set for authorization:
//		*AppID - String - application ID.
//		*Secret - String -  the secret key.
//		*TestMode - Boolean -  test mode.
//		*PrivateKey - String -  the path to the private key.
//
Function AuthorizationSettings(Owner) Export
	
	Result = New Structure("AppID,Secret,TestMode,PrivateKey", "", "", False, "");
	If Not ValueIsFilled(Owner) Then
		Return Result;
	EndIf;
	
	AuthorizationParameters = Common.ObjectAttributesValues(Owner, "AppID,TestMode,PathToCertificate,Secret");
	Result.AppID = AuthorizationParameters.AppID;
	Result.Secret = AuthorizationParameters.Secret;
	Result.TestMode = AuthorizationParameters.TestMode;
	Result.PrivateKey = AuthorizationParameters.PathToCertificate;
	
	Return Result;
	
EndFunction

// The function receives data in the service for further authorization
//
// Parameters:
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//		* ResponseStatus - String - Response Status
//		* FillParameters - Structure - The fill parameters:
//			** Organization - CatalogRef.Companies 
//		* ErrorsArray - Array of String - Array of errors
//
Function ConnectionCheckUp(FillParameters) Export
	
	QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParametersForConnectionVerification(FillParameters);
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	ProcessingResult = New Structure;
	ProcessingResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived);
	ProcessingResult.Insert("FillParameters", FillParameters);
	ProcessingResult.Insert("ErrorsArray", New Array());
	
	ResponseParametersFromService = ExchangeWithBankFeedsServer.TestConnection(QueryOptions);
		
	FillPropertyValues(ProcessingResult, ResponseParametersFromService);
		
	Return ProcessingResult;
	
EndFunction	

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// CloudTechnology.ExportImportData

// Returns the directory details that form the natural key
// for the directory elements.
//
// Returns:
//  Array of String - an array of the names of the requisites forming the natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array();
	
	Result.Add("Code");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf
