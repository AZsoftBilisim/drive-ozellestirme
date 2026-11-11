
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a list of values from the methods for setting the Attribute value.
// 
// Parameters:
//  Enable - String - list of values to include
//  Exclude - String - list of excluded values
// 
// Returns:
//  ValueList of EnumRef.ImportMasterDataMethodsToSetAttributeValue
//
Function ValueList(Enable = "", Exclude = "") Export
	
	Result = New ValueList;
	
	StructureInclude  = New Structure(Enable);
	StructureExclude = New Structure(Exclude);
	
	For Each Method In Enums.ImportMasterDataMethodsToSetAttributeValue Do
		
		Name = XMLString(Method);
		
		If StructureExclude.Property(Name) Then
			Continue;
		EndIf;
		
		If StructureInclude.Count() > 0 And Not StructureInclude.Property(Name) Then
			Continue;
		EndIf;
		
		Result.Add(Method, Method);
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf