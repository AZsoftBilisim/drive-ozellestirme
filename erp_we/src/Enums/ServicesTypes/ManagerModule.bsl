#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Parameters: 
//  EnumValueName - String
// 
// Returns:
//  EnumRef.ServicesTypes
//	
Function ValueByName(EnumValueName) Export
	
	If EnumValueName = "unlimited" Then
		Return PredefinedValue("Enum.ServicesTypes.Unlimited");
	ElsIf EnumValueName = "limited" Then
		Return PredefinedValue("Enum.ServicesTypes.Limited");
	ElsIf EnumValueName = "unique" Then
		Return PredefinedValue("Enum.ServicesTypes.Unique");
	Else
		Return PredefinedValue("Enum.ServicesTypes.EmptyRef");
	EndIf;
	
EndFunction

#EndRegion

#EndIf