#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("DocumentProperties") Then
		InfobaseUpdate.CheckObjectProcessed(ThisObject);
	EndIf;
	
	If CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
