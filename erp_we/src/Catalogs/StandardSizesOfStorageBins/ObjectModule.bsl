#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If NotLimitedByCarryingCapacity Then
		CarryingCapacity = 0;
	EndIf;
	
	If NotLimitedByDimensions Then
		Height	= 0;
		Depth	= 0;
		VolumeM3	= 0;
		Width	= 0;
	EndIf;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
 	NotCheckedAttributeArray = New Array;
	
	If NotLimitedByCarryingCapacity Then
		NotCheckedAttributeArray.Add("CarryingCapacity");
	EndIf;
	
	If NotLimitedByDimensions Then
		NotCheckedAttributeArray.Add("Height");
		NotCheckedAttributeArray.Add("Depth");
		NotCheckedAttributeArray.Add("VolumeM3");
		NotCheckedAttributeArray.Add("Width");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	UnitOfMeasureForWeight 	= Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume 	= Constants.UnitOfMeasureForVolume.Get();
	UnitOfMeasureForLength 	= Constants.UnitOfMeasureForLength.Get();
	
	HeightUnitOfMeasure	 = UnitOfMeasureForLength;
	DepthUnitOfMeasure	 = UnitOfMeasureForLength;
	WidthUnitOfMeasure	 = UnitOfMeasureForLength;
	WeightUnitOfMeasure		 = UnitOfMeasureForWeight;
	VolumeUnitOfMeasure	 = UnitOfMeasureForVolume;
	
EndProcedure

#EndRegion

#EndIf