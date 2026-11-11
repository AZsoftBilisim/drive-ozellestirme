#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	For Each String In DefaultComplexTableValues Do
		
		If ValueIsFilled(String.Dimension) Then
			TypeOfAnalytics = Common.ObjectAttributeValue(String.Dimension, "ValueType");
			String.Value = BudgetingClientServer.ReducedAnalyticsValue(String.Value, TypeOfAnalytics);
		EndIf;
		
	EndDo;
	
	If Not IsFolder Then
		Array = TemplateIndicators.UnloadColumn("Factor");
		PresentationOfIndicators = StrConcat(Array, "; ");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf