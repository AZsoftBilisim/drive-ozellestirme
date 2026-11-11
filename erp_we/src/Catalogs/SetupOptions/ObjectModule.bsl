#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not Owner.IsEmpty() Then
		DetailsOfRCType = Common.ObjectAttributesValues(Owner, "ParallelLoad,ImportOption");
		OpeningHoursAvailable = (DetailsOfRCType.ParallelLoad 
								And DetailsOfRCType.ImportOption = Enums.WorkCenterLoadOptions.Synchronous);
	Else
		OpeningHoursAvailable = False;
	EndIf; 
	
	If Not OpeningHoursAvailable Then
		NotCheckedAttributeArray.Add("OperationTime");
		NotCheckedAttributeArray.Add("UnitOfMeasure");
	EndIf; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf