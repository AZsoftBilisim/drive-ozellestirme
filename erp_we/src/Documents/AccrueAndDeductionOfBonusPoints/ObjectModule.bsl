#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TypeOfObjectRule = Undefined;
	If ValueIsFilled(AccrualRule) Then
		TypeOfObjectRule = Common.ObjectAttributeValue(AccrualRule, "RuleKind");
	Else
		TypeOfObjectRule = RuleKind;
	EndIf;
	
	If TypeOfObjectRule = Enums.KindsOfBonusPointAccrualRules.Accrual Then
		WriteOff.Clear();
	Else
		Accrual.Clear();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	TypeOfObjectRule = Undefined;
	If ValueIsFilled(AccrualRule) Then
		TypeOfObjectRule = Common.ObjectAttributeValue(AccrualRule, "RuleKind");
		NotCheckedAttributeArray.Add("RuleKind");
	Else
		TypeOfObjectRule = RuleKind;
	EndIf;
	
	If TypeOfObjectRule = Enums.KindsOfBonusPointAccrualRules.Accrual Then
		NotCheckedAttributeArray.Add("WriteOff");
	Else
		NotCheckedAttributeArray.Add("Accrual");
	EndIf;
	
	// The check is performed in the form
	NotCheckedAttributeArray.Add("AccrualRule");
	NotCheckedAttributeArray.Add("ValidTo");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#EndIf
