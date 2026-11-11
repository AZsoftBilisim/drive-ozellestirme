#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
		If FillingData.Property("ReportPeriod") Then
			FillPropertyValues(ThisObject, FillingData.ReportPeriod);
		EndIf;
		If FillingData.Property("Filter") Then
			FillPropertyValues(ThisObject, FillingData.Filter);
		EndIf;
		If FillingData.Property("ReportResult") Then
			ReportResult = New ValueStorage(FillingData.ReportResult);
		EndIf;
		If FillingData.Property("ReportDetails") Then
			DetailsData = New ValueStorage(FillingData.ReportDetails);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf