////////////////////////////////////////////////////////////////////////////////
// Procedures and functions used in the processing of print labels
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure WhenPreparingDataStructureForPrinting(SettingsStructure, Mode, Query, RawData) Export
EndProcedure

// Modifies the barcode value for the barcode printing component
// 
// Parameters:
// 	BarcodeValueForComponent - String -The value of barcode that will be modified
// 	CodeType - Number - The type of barcode
Procedure WhenDeterminingBarcodeValueForComponent(BarcodeValueForComponent, CodeType, InputDataType = Undefined) Export
EndProcedure

Procedure OnPrint(PrintFormsCollection, PrintParameters, PrintObjects) Export
EndProcedure

Function GetParametersForPrintingSample(Form, Purpose, CodeType, Context) Export
EndFunction


Procedure WhenPreparingSetDataStructure(Mode, DataCompositionSchema, QueryText) Export
	
	Return;
	
EndProcedure

Procedure ModificationOfValueOfStricodeComponent(BarcodeValue, CodeType, InputDataType = Undefined) Export
	
	
EndProcedure

#EndRegion

