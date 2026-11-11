
#Region Public

// Returns a link to a list item by barcode
//
// Parameters:
//  Barcode - String - Barcode
//  Managers - Array - Empty links to documents that need to be searched by barcode.
//
// Returns:
//  AnyRef - Link to the found element.
//
Function GetLinkFromBarcodeOfTabularDocument(Barcode, Managers = Undefined) Export
	
	Return BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#Region ForWorkingWithLogs

// Returns a link to a list item by barcode
//
// Parameters:
//  Barcode - String - Barcode
//  AvailableBusinessTransactionsAndDocuments - ValueTable - 
//
// Returns:
//  AnyRef - Link to the found element.
//
Function LinkToListItemByBarcode(Barcode, AvailableBusinessTransactionsAndDocuments) Export 
	
	ArrayOfManagers = TMCommonUse.DocumentManagersUsed(AvailableBusinessTransactionsAndDocuments);
	
	Return BarcodingOfPrintFormsServerCall.GetLinkFromBarcodeOfTabularDocument(Barcode, ?(ArrayOfManagers.Count() > 0, ArrayOfManagers, Undefined));
	
EndFunction
	
#EndRegion

#EndRegion
