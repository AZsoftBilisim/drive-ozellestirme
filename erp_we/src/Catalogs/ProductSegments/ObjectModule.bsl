#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	SegmentsServer.SegmentObjectBeforeRecording(ThisObject, Cancel);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SegmentsServer.SegmentBeforeDeletion(ThisObject, Cancel);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)

	SegmentsServer.SegmentFillProcessing(ThisObject);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SegmentsServer.SegmentWhenRecording(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	SegmentsServer.SegmentWhenCopying(ThisObject);
	
EndProcedure

#EndRegion

#EndIf