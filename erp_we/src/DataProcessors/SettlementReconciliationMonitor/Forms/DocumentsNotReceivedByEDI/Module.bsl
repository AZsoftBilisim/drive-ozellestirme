
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled("BeginOfPeriod") And ValueIsFilled("EndOfPeriod") Then
		CommonClientServer.AddCompositionItem(List.Filter, "IBDocumentDate", DataCompositionComparisonType.GreaterOrEqual, Parameters.BeginOfPeriod,,True);
		CommonClientServer.AddCompositionItem(List.Filter, "IBDocumentDate", DataCompositionComparisonType.LessOrEqual, EndOfDay(Parameters.EndOfPeriod),,True);
	EndIf;
	If ValueIsFilled("Organization") Then
		CommonClientServer.SetDynamicListFilterItem(List, "Organization", Parameters.Organization, DataCompositionComparisonType.Equal,,True);
	EndIf;
	If ValueIsFilled("Counterparty") Then
		CommonClientServer.SetDynamicListFilterItem(List, "Counterparty", Parameters.Counterparty, DataCompositionComparisonType.Equal,,True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Item.CurrentData;
	If Field.Name <> "ListStatusPresentation" Then
		OpenValueAsync(CurrentRow.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private


#EndRegion

