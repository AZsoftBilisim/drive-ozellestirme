#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns the enumeration value by the name of the property value of the service's program interface.
//
// Parameters:
//  EnumValueName - String - name of the property value.
// 
// Returns:
//   EnumRef.ServiceSubscriptionsTypes - enumeration value.
//
Function ValueByName(EnumValueName) Export
	
	If EnumValueName = "basic" Then
		Return PredefinedValue("Enum.ServiceSubscriptionsTypes.Main");
	ElsIf EnumValueName = "prolonging" Then
		Return PredefinedValue("Enum.ServiceSubscriptionsTypes.Prolonging");
	ElsIf EnumValueName = "extending" Then
		Return PredefinedValue("Enum.ServiceSubscriptionsTypes.Extending");
	Else
		Return PredefinedValue("Enum.ServiceSubscriptionsTypes.EmptyRef");
	EndIf; 
	
EndFunction

#EndRegion

#EndIf