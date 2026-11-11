#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
		
	TMCommonUse.FillInDocumentIDs(ThisObject, "Corrections");
		
	CorrectionOfSidedBalanceInCompanyGoodsAccountingLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CorrectionOfSidedBalanceInCompanyGoodsAccountingLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", InventoriesServer.ParametersForFillingInventoryTypes());
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	CorrectionOfSidedBalanceInCompanyGoodsAccountingLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", InventoriesServer.ParametersForFillingInventoryTypes());
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CorrectionOfSidedBalanceInCompanyGoodsAccountingLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Corrections");
	
EndProcedure

#EndRegion

#EndIf