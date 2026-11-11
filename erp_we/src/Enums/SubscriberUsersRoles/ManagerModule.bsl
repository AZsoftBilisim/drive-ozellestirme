#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns the enumeration value by value name.
//
// Parameters:
//  EnumValueName	- String - name of the value as it is passed through the API
// 
// Returns:
//  EnumRef.SubscriberUsersRoles - the value of the enumeration by name.
//
Function ValueByName(EnumValueName) Export
    
    If EnumValueName = "owner" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.SubscriberOwner");
    ElsIf EnumValueName = "administrator" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.SubscriberAdministrator");
    ElsIf EnumValueName = "operator" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.ServiceCompanyOperator");
    ElsIf EnumValueName = "user" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.SubscriberUser");
    ElsIf EnumValueName = "ext_administrator" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.AdaptationToolsAdministrator");
    Else
        Return PredefinedValue("Enum.SubscriberUsersRoles.EmptyRef");
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
	
    If Value = PredefinedValue("Enum.SubscriberUsersRoles.SubscriberOwner") Then
        Return "owner";
    ElsIf Value = PredefinedValue("Enum.SubscriberUsersRoles.SubscriberAdministrator") Then
        Return "administrator";
    ElsIf Value = PredefinedValue("Enum.SubscriberUsersRoles.ServiceCompanyOperator") Then
        Return "operator";
    ElsIf Value = PredefinedValue("Enum.SubscriberUsersRoles.SubscriberUser") Then
        Return "user";
    ElsIf Value = PredefinedValue("Enum.SubscriberUsersRoles.AdaptationToolsAdministrator") Then
        Return "ext_administrator";
    Else 
        Return Undefined;
    EndIf; 
	
EndFunction

#EndRegion

#EndIf