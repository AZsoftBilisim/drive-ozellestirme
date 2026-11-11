#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns the enumeration value by value name.
//
// Parameters:
//  EnumValueName	- String - name of the value as it is passed through the API
// 
// Returns:
//  EnumRef.TariffTypes - the value of the enumeration by name.
//
Function ValueByName(EnumValueName) Export
	
	If EnumValueName = "basic" Then
		Return PredefinedValue("Enum.TariffTypes.Main");
	ElsIf EnumValueName = "extension" Then
		Return PredefinedValue("Enum.TariffTypes.Extension");
	ElsIf EnumValueName = "upgrade" Then
		Return PredefinedValue("Enum.TariffTypes.IsUpgrade");
	Else
		Return PredefinedValue("Enum.SubscriberUsersRoles.EmptyRef");
	EndIf;
	
EndFunction

#EndRegion

#EndIf