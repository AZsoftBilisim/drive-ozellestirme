///////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Reception for processing"
// related to the economic operation "Transfer to the giver".
// 
///////////////////////////////////////////////////////////

#Region Public

#Region CreatingHyperlinkInJournal

// Returns the hyperlink text for the transition from the document log to the design workspace.
//
// Parameters:
//  Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//  FormattedString, Undefined - the text of the hyperlink of the transition to the workplace of the registration of transfers.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
	 Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue) Then
		Return Undefined;
	EndIf;
	
	HyperlinkAnchorText =
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices/ProductTransferPage";
	
	ThereAreDocumentsForRegistration = DataProcessors.DocumentsOfReceiptForTollingAll2_5.ThereAreDocumentsForRegistration(
									Parameters, Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	
	ColorOfHyperlink = ?(ThereAreDocumentsForRegistration, Undefined, StyleColors.EmptyTableField);
	
	Return New FormattedString(NStr("vi = 'Chuyển sản phẩm';
									|ru = 'Передача продукции';
									|en = 'Product transfer'; fa = 'انتقال محصول';
									|it = 'Consegna prodotti';
									|pl = 'Transfer produkcji';
									|tr = 'Ürünlerin transferi'"),, ColorOfHyperlink,, HyperlinkAnchorText);
	
EndFunction

#EndRegion

#EndRegion