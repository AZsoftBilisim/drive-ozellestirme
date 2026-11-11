
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Table of file fields.
// 
// Parameters:
//  StructureOfFileFields - Structure
// 
// Returns:
//  ValueTable - Table of File Fields:
// * FieldName - String
// * Value - String
Function TableOfFileFields(StructureOfFileFields) Export
	
	Result = New ValueTable;
	Result.Columns.Add("FieldName",  New TypeDescription("String"));
	Result.Columns.Add("Value", New TypeDescription("String"));
	
	If StructureOfFileFields <> Undefined Then
		For Each KeyAndValue In StructureOfFileFields Do
			NewRow = Result.Add();
			NewRow.FieldName = KeyAndValue.Key;
			NewRow.Value = KeyAndValue.Value;
		EndDo;
		Result.Sort("FieldName");
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
