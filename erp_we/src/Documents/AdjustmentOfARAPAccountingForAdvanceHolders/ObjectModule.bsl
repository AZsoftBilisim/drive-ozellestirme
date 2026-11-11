#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef.AdjustmentOfARAPAccountingForAdvanceHolders") Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	ARAPAdjustment.Clear();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	// Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.AdjustmentOfARAPAccountingForAdvanceHolders.AccountingAccountSettings_(BusinessOperation));
		
	TMCommonUse.FillInDocumentIDs(ThisObject, "ARAPAdjustment");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
EndProcedure

Procedure UndoPosting(Cancel)
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	ItemsAndDimensionsSelectionParameters =
		Documents.AdjustmentOfARAPAccountingForAdvanceHolders.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject,
		                                             Cancel,
		                                             CheckedAttributes,
		                                             ItemsAndDimensionsSelectionParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf