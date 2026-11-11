
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#EndIf


#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("ProductCategoryOwner") Then
			If ValueIsFilled(Parameters.Filter.ProductCategoryOwner) Then
				Parameters.Filter.Insert("Owner", Parameters.Filter.ProductCategoryOwner);
			EndIf;
			
			Parameters.Filter.Delete("ProductCategoryOwner");
		EndIf;
	EndIf;
EndProcedure

#EndRegion