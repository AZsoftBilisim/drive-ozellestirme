#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Parameters:
//  PricingMethod - EnumRef.PriceSettingMethods - verifiable method for setting prices
// 
// Returns:
//  Boolean - True if the pricing method can contain an arbitrary algorithm
Function ThisIsUnsafeWayToSetPrice(PricingMethod) Export
	Return UnsafeWaysToSetPrices().Find(PricingMethod) <> Undefined;
EndFunction

// Returns methods for setting prices, which may contain arbitrary algorithms.
// 
// Returns:
//  Array of EnumRef.PriceSettingMethods - containing unsafe ways to set prices.
//
Function UnsafeWaysToSetPrices() Export
	
	ReturnValue = New Array;
	ReturnValue.Add(CalculateUsingFormulasOfOtherPriceTypes);
	ReturnValue.Add(FillInByInfobaseData);

	Return ReturnValue;

EndFunction

#EndRegion

#EndIf