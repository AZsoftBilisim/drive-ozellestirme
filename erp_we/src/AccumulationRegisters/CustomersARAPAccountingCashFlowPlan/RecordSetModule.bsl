#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	InformationRegisters.NumberOfRecordsOfARAPRecorders.ReflectNumberOfRecordsOfPaymentRegistrars(
		Filter.Recorder.Value, "CustomersARAPAccountingCashFlowPlan", DataExchange.Load);
		
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure UploadWithProcessing(CalculationTable) Export
	
	ARAPAccountingPosting.AddFillInOrderOfOperation(CalculationTable, TypeOf(Filter.Recorder.Value));
	ARAPAccountingPosting.CheckAndFillOutPartnerAccountingAnalytics(CalculationTable);
	Load(CalculationTable);
	
EndProcedure

#EndRegion

#EndIf