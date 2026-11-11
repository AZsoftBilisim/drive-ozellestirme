#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	Date = BegOfDay(Date);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	Common.MessageToUser(NStr("vi = 'Không cho phép kết chuyển trực tác chứng từ';
								|ru = 'Не допускается интерактивное проведение документа';
								|en = 'Cannot post the document interactively'; fa = 'Cannot post the document interactively';
								|it = 'Не допускается интерактивное проведение документа';
								|pl = 'Cannot post the document interactively';
								|tr = 'Не допускается интерактивное проведение документа'"),,,, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ClearDocumentRegisteredRecords(ThisObject, "AvailabilityOfWorkCenterTypes");
	
EndProcedure

#EndRegion

#EndIf
