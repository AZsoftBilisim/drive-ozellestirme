#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FinancialInstrumentsARAP");
	
	OBEntryLocalization.OBEntryFinancialInstrumentsBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsProcessing(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsProcessingDeletions(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If Not RecordInOperationalAccounting 
		And Not PostInFinancialAndTaxAccounting
		And Not RecordInMA Then
		
		MessageText = NStr("vi = 'Cần phản ánh hoạt động trong một trong số sổ kế toán';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
		
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsProcessingFillChecks(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsProcessingFilling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FinancialInstrumentsARAP");
	
	OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsWhenCopying(ThisObject, CopiedObject);
	
	EmployeeResponsible = Undefined;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsWhenRecording(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If FillingData.Property("Comment") Then
			Comment = FillingData.Comment;
		EndIf;
		
		If FillingData.Property("CopyingValue") Then
			OBEntryServer.FillInValuesForOldInputBalances(ThisObject, FillingData.CopyingValue);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
