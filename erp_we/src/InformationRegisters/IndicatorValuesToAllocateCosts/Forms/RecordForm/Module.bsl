#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
	If Parameters.Property("Factor") And ValueIsFilled(Parameters.Factor) Then
		
		ExistingRecord = InformationRegisters.IndicatorValuesToAllocateCosts.CreateRecordManager();
		ExistingRecord.Factor = Parameters.Factor;
		ExistingRecord.Department = Parameters.Department;
		ExistingRecord.Period = Parameters.Period;
		ExistingRecord.Read();
		
		If ValueIsFilled(ExistingRecord.Factor) Then
			ValueToFormData(ExistingRecord, Record);
		Else
			FillPropertyValues(Record, Parameters);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	Record.Period = BegOfMonth(Record.Period);
EndProcedure

#EndRegion
