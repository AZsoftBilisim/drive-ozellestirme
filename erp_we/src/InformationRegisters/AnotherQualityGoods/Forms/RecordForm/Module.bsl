
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If ValueIsFilled(Record.OtherQualityGoods) Then
		Record.QualityGradation = Common.ObjectAttributeValue(Record.OtherQualityGoods, "Quality");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OtherQualityGoodsOnChange(Item)
	Record.QualityGradation = GeneralPurposeTMServerCall.ObjectAttributeValue(Record.OtherQualityGoods, "Quality");
EndProcedure

#EndRegion

