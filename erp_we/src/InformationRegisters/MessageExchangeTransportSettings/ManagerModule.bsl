#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// for internal use.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	Endpoint - ExchangePlanRef.MessagesExchange - end point,
//	AuthenticationParameters - String - password, or
//							- Structure - With Fields:
//								* UseCurrentUser - Boolean - 
//								* Password - String - not required.
//		
// Returns:
//	Structure - With Fields:
//		* DefaultExchangeMessagesTransportKind - EnumRef.ExchangeMessagesTransportTypes - 
//		* WSWebServiceURL - String -
//		* WSUserName - String -
//		* WSRememberPassword - Boolean -
//		* WSPassword - String -
Function TransportSettingsWS(Endpoint, AuthenticationParameters = Undefined) Export
EndFunction

#EndRegion

#EndIf