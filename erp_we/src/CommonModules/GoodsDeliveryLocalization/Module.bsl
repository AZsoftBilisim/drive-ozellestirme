// @strict-types

#Region Internal

// Parameters:
//  AddressValue - String - JSON Presentation of the address
// 
// Returns:
//  String - address ID
//
Function IdOfDeliveryPointAddress(AddressValue) Export
	
	IDFound = "";
	
	
	Return IDFound;
	
EndFunction

// Parameters:
//  InfoAboutAddress - See ContactsManager.InfoAboutAddress
//
Procedure SetAddressTypeInFreeForm(InfoAboutAddress) Export
	
	
	Return;
	
EndProcedure

// Parameters:
//  Address - String - text Presentation of the address
//  AddressValue - String - JSON Presentation of the address
//  FreeForm - Boolean, Undefined -
// 
// Returns:
//  String -
//
Function NameOfDeliveryPointAt(Address, AddressValue, FreeForm = Undefined) Export
	
	Result = Address;
	
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private


#EndRegion