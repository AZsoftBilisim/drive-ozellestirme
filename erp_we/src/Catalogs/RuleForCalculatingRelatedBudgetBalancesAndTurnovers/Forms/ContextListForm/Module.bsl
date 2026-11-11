
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Parameters.Property("Source", Source);
	Parameters.Property("Receiver", Receiver);
	
	If ValueIsFilled(Source) Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "Source", Source);
	EndIf;
	
	If ValueIsFilled(Receiver) Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "Receiver", Receiver);
	EndIf;
	
	CustomizeFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	OpeningParameters = New Structure;
	If Copy Then
		OpeningParameters.Insert("CopyingValue", Items.List.CurrentData.Ref);
	Else
		OpeningParameters.Insert("FillingValues", New Structure("Source, Receiver", Source, Receiver));
	EndIf;
	OpenForm("Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Form.ItemForm", 
		OpeningParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure CustomizeFormElements(Form)

	Items = Form.Items;
	
	Items.Source.Visible = Not ValueIsFilled(Form.Source);
	Items.Receiver.Visible = Not ValueIsFilled(Form.Receiver);
	
EndProcedure

#EndRegion
