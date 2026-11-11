#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
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

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	
	Documents.IntangibleAssetsPhysicalCount.FillInAccountingData(ThisObject, IA);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);
		
	If PhysicalInventoryCountCommission.Count() <> 0 
		And PhysicalInventoryCountCommission.Find(True, "Chairman") = Undefined Then
		
		MessageText = NStr("vi = 'Cần chọn chủ tịch ủy ban';
							|ru = 'Необходимо выбрать председателя комиссии';
							|en = 'Select the commission chairperson'; fa = 'Select the commission chairperson';
							|it = 'Select the commission chairperson';
							|pl = 'Select the commission chairperson';
							|tr = 'Komisyon başkanının seçilmesi gerekir'");
		Common.MessageToUser(MessageText, ThisObject, "PhysicalInventoryCountCommission",, Cancel); 
	EndIf;

EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
		
EndProcedure
 
#EndRegion

#EndIf
