
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If TypeOf(Parameters.Filter) = Type("Structure") Then
		If Parameters.Filter.Property("Products") Then
			Items.Products.Visible = False;
		ElsIf Parameters.Filter.Property("Warehouse")
			Or Parameters.Filter.Property("Premise") Then
			Items.Warehouse.Visible = False;
			Items.Premise.Visible = False;
		ElsIf Parameters.Filter.Property("Cell") Then
			Items.Warehouse.Visible = False;
			Items.Premise.Visible = False;
			Items.Cell.Visible = False;
		EndIf;
	EndIf;
EndProcedure

#EndRegion
