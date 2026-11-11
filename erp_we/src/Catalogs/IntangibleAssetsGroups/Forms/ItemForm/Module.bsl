
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not GetFunctionalOption("LocalizationRFService") Then
		Items.AccountingProcedure.Visible = False;
		Items.RevaluationCycle.Visible = False;
	EndIf;

EndProcedure

#EndRegion

