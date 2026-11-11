
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure RecordInformation(Data) Export
	
	SetPrivilegedMode(True);
	
	Set = InformationRegisters.OrderMonitoringPreviousCalculation.CreateRecordSet();
	Set.Filter.ProductionOrder.Set(Data.ProductionOrder);
	FillPropertyValues(Set.Add(), Data);
	Set.Write(True);
	
EndProcedure

Function Get_Information(ProductionOrder) Export
	
	SetPrivilegedMode(True);
	
	CalculationInformation_ = InformationRegisters.OrderMonitoringPreviousCalculation.CreateRecordManager();
	CalculationInformation_.ProductionOrder = ProductionOrder;
	CalculationInformation_.Read();

	If Not CalculationInformation_.Selected() Then
		// Default
		CalculationInformation_.RunTime = 0;
		CalculationInformation_.CalculationPeriod = '00010101';
	EndIf;
	
	Return Common.StructureByRecordManager(
		CalculationInformation_, Metadata.InformationRegisters.OrderMonitoringPreviousCalculation);
	
EndFunction

#EndRegion

#EndIf
