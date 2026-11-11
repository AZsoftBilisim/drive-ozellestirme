#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Dimensionless Then
		Height	= 0;
		Depth	= 0;
		VolumeM3	= 0;
		Width	= 0;
	EndIf;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
 	NotCheckedAttributeArray = New Array;
	
	If Dimensionless Then
		NotCheckedAttributeArray.Add("Height");
		NotCheckedAttributeArray.Add("Depth");
		NotCheckedAttributeArray.Add("VolumeM3");
		NotCheckedAttributeArray.Add("Width");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	UnitOfMeasureForVolume 	= Constants.UnitOfMeasureForVolume.Get();
	UnitOfMeasureForLength 	= Constants.UnitOfMeasureForLength.Get();
	
	HeightUnitOfMeasure	 = UnitOfMeasureForLength;
	DepthUnitOfMeasure	 = UnitOfMeasureForLength;
	WidthUnitOfMeasure	 = UnitOfMeasureForLength;
	VolumeUnitOfMeasure	 = UnitOfMeasureForVolume;
	
EndProcedure

#EndRegion

#EndIf