///////////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Reception for processing"
// related to the business operation "Receipt from the giver".
// 
///////////////////////////////////////////////////////////////////////

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
	
	HyperlinkAnchorText = "DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices/RawMaterialReceiptPage";
	
	ThereAreDocumentsForRegistration = DataProcessors.DocumentsOfReceiptForTollingAll2_5.ThereAreDocumentsForRegistration(
									Parameters, Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
	
	ColorOfHyperlink = ?(ThereAreDocumentsForRegistration, Undefined, StyleColors.EmptyTableField);
	
	Return New FormattedString(NStr("vi = 'Tiếp nhận nguyên liệu';
									|ru = 'Поступление сырья';
									|en = 'Raw material receipt'; fa = 'دریافت مواد اولیه';
									|it = 'Arrivo delle materie prime';
									|pl = 'Napływ surowców';
									|tr = 'Hammadde girişi'"),, ColorOfHyperlink,, HyperlinkAnchorText);
	
EndFunction

#EndRegion

#EndRegion