
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	Keys = Rows.GetKeys();
	ListLine = Rows.Get(Keys[0]);
	If Not ListLine.Data.Property("NoReferenceToTheElement") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED
		|	ItemsBatches.ItemsBatchForPricing AS Ref,
		|	MAX(CASE
		|		WHEN ItemsBatches.Ref IS NULL
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS NoReferenceToTheElement
		|FROM
		|	Catalog.ItemsBatches AS ItemsBatches
		|WHERE
		|	ItemsBatches.ItemsBatchForPricing IN (&References)
		|GROUP BY
		|	ItemsBatches.ItemsBatchForPricing";
		
	References = New Array;
	For Each Var_Key In Keys Do // CatalogRef.ItemsBatchesForPricing
		References.Add(Var_Key);
	EndDo;
		
	Query.SetParameter("References", References);
	
	DataBySeries = Query.Execute().Unload();
	For Each String In Rows Do
		String = Rows[String.Key];
		FoundRow = DataBySeries.Find(String.Data["Ref"], "Ref");
		If FoundRow <> Undefined Then
			String.Data["NoReferenceToTheElement"] = FoundRow.NoReferenceToTheElement;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion
