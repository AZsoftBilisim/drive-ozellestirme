#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	AllocationOfOtherCostsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	CalculationOfInventoryImpairmentProvisionLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CalculationOfInventoryImpairmentProvisionLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(BegOfMonth(Date),
		Ref,
		Organization,
		Catalogs.MonthEndClosingOperations.AccualOfInventoryImpairmentProvision);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CalculationOfInventoryImpairmentProvisionLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	CalculationOfInventoryImpairmentProvisionLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CalculationOfInventoryImpairmentProvisionLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	CalculationOfInventoryImpairmentProvisionLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf
