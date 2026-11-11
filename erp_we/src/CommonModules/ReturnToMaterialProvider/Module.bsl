///////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Acceptance for processing"
// related to the economic operation "Return to the giver".
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
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue) Then
		Return Undefined;
	EndIf;
	
	HyperlinkAnchorText = "DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices/RawMaterialReturnsPage";
	
	ThereAreDocumentsForRegistration = DataProcessors.DocumentsOfReceiptForTollingAll2_5.ThereAreDocumentsForRegistration(
									Parameters, Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	
	ColorOfHyperlink = ?(ThereAreDocumentsForRegistration, Undefined, StyleColors.EmptyTableField);
	
	Return New FormattedString(NStr("vi = 'Hoàn trả nguyên liệu';
									|ru = 'Возврат сырья';
									|en = 'Return of components'; fa = 'برگشت اجزا';
									|it = 'Reso delle materie prime';
									|pl = 'Zwrot surowców';
									|tr = 'Hammadde iadesi'"),, ColorOfHyperlink,, HyperlinkAnchorText);
	
EndFunction

#EndRegion

#EndRegion