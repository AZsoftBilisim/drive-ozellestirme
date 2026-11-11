#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns the enumeration value by value name.
//
// Parameters:
//  EnumValueName	- String - name of the value as it is passed through the API
// 
// Returns:
//  EnumRef.ApplicationsStates - the value of the enumeration by name.
//
Function ValueByName(EnumValueName) Export
    
    If EnumValueName = "ready" Then
        Return PredefinedValue("Enum.ApplicationsStates.Done");
    ElsIf EnumValueName = "preparation" Then
        Return PredefinedValue("Enum.ApplicationsStates.BeingPreparedForUse");
    ElsIf EnumValueName = "used" Then
        Return PredefinedValue("Enum.ApplicationsStates.Used");
    ElsIf EnumValueName = "converted" Then
        Return PredefinedValue("Enum.ApplicationsStates.Converting");
    ElsIf EnumValueName = "copied" Then
        Return PredefinedValue("Enum.ApplicationsStates.Copying");
    ElsIf EnumValueName = "decommissioned" Then
        Return PredefinedValue("Enum.ApplicationsStates.ForDeletion");
    ElsIf EnumValueName = "new" Then
        Return PredefinedValue("Enum.ApplicationsStates.IsNew");
    ElsIf EnumValueName = "error" Then
        Return PredefinedValue("Enum.ApplicationsStates.PreparationError");
    ElsIf EnumValueName = "removed" Then
        Return PredefinedValue("Enum.ApplicationsStates.isDeleted");
    Else
        Return PredefinedValue("Enum.ApplicationsStates.EmptyRef");
    EndIf; 
    
EndFunction

#EndRegion

#EndIf