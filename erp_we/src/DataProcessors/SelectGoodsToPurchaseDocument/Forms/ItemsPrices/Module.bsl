
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Title = Title + ": "+ Parameters.Products;
	
	If ValueIsFilled(Parameters.Characteristic) Then
		Items.ListCharacteristic.Visible = False;
		Title = Title + " ("+ Parameters.Characteristic + ")";
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "Date", Parameters.Date);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Products",
		Parameters.Products,
		DataCompositionComparisonType.Equal,,True);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Characteristic",
		Parameters.Characteristic,
		DataCompositionComparisonType.Equal,,ValueIsFilled(Parameters.Characteristic));
	
	CommonClientServer.SetDynamicListParameter(List, "Partner", Parameters.Partner);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion