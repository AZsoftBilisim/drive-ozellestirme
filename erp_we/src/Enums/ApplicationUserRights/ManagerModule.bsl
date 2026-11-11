#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns the enumeration value by value name in the API.
//
// Parameters:
//  EnumValueName	- String - name of the value as it is passed through the API
// 
// Returns:
//  EnumRef.ApplicationUserRights - the value of the enumeration by name.
//
Function ValueByName(EnumValueName) Export
    
    If EnumValueName = "user" Then
        Return PredefinedValue("Enum.ApplicationUserRights.Run");
    ElsIf EnumValueName = "administrator" Then
        Return PredefinedValue("Enum.ApplicationUserRights.StartAndAdministration");
    ElsIf EnumValueName = "api" Then
        Return PredefinedValue("Enum.ApplicationUserRights.APIAccess");
    Else
        Return PredefinedValue("Enum.ApplicationUserRights.EmptyRef");
    EndIf; 
    
EndFunction

// Returns the name of the value for the API based on the enumeration value.
//
// Parameters:
//  Value - EnumRef.ApplicationUserRights - enum value to get the value name for the API
// 
// Returns:
//  String - name of the value for the API
//
Function NameByValue(Value) Export
	
    If Value = PredefinedValue("Enum.ApplicationUserRights.Run") Then
        Return "user";
    ElsIf Value = PredefinedValue("Enum.ApplicationUserRights.StartAndAdministration") Then
        Return "administrator";
    ElsIf Value = PredefinedValue("Enum.ApplicationUserRights.APIAccess") Then
        Return "api";
    Else 
        Return Undefined;
    EndIf; 
	
EndFunction

#EndRegion

#EndIf