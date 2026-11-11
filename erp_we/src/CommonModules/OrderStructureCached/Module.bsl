#Region Private

#Region CalculationParameters

Function Service_Settings() Export
	
	Settings = OrderStructure.Service_Settings();
	
	Return Settings;
	
EndFunction

Function CalculationParameters() Export
	
	CalculationParameters = OrderStructure.CalculationParameters();
	
	Return CalculationParameters;
	
EndFunction

#EndRegion

#Region Metadata

// Returns a description of the structure of the information register
// 
// Parameters:
// 	RegisterName - String - name of the information register
// 	ExcludeServiceColumns - Boolean - exclude service columns
// Returns:
// 	Structure - LongDesc:
// * Attributes - Array -
// * StringAttributes - String -
// * Resources - Array -
// * ResourcesString - String -
// * Dimensions - Array -
// * DimensionsString - String -
Function RegisterMetadataStructure(RegisterName, ExcludeServiceColumns = True) Export
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	MetadataStructure = New Structure();

	Columns = RegisterMetadata.Dimensions;

	ColumnsArray1 = New Array();
	
	For Each Column In Columns Do
		If ExcludeServiceColumns
			And StrFind("Separator", Column.Name) > 0 Then
			Continue;
		EndIf;
		ColumnsArray1.Add(Column.Name);
	EndDo;
	
	MetadataStructure.Insert("DimensionsString", StrConcat(ColumnsArray1, ","));
	MetadataStructure.Insert("Dimensions", ColumnsArray1);
	
	Columns = RegisterMetadata.Resources;
	
	ColumnsArray1 = New Array();
	
	For Each Column In Columns Do
		ColumnsArray1.Add(Column.Name);
	EndDo;
	
	MetadataStructure.Insert("ResourcesString", StrConcat(ColumnsArray1, ","));
	MetadataStructure.Insert("Resources", ColumnsArray1);
	
	Columns = RegisterMetadata.Attributes;
	
	ColumnsArray1 = New Array();
	
	For Each Column In Columns Do
		If ExcludeServiceColumns
			And StrFind("AdditionalRecord", Column.Name) > 0 Then
			Continue;
		EndIf;
		ColumnsArray1.Add(Column.Name);
	EndDo;
	
	MetadataStructure.Insert("StringAttributes", StrConcat(ColumnsArray1, ","));
	MetadataStructure.Insert("Attributes", ColumnsArray1);
	
	Return MetadataStructure;
	
EndFunction

#EndRegion

#EndRegion