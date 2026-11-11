#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	DebugMode = TMCommonUse.DebugMode();
	Items.List.ReadOnly = Not DebugMode;

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
		|	ItemsCharacteristics.ItemsCharacteristicForPricing AS Ref,
		|	MAX(CASE
		|		WHEN ItemsCharacteristics.Ref IS NULL
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS NoReferenceToTheElement
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.ItemsCharacteristicForPricing IN (&References)
		|GROUP BY
		|	ItemsCharacteristics.ItemsCharacteristicForPricing";
		
	References = New Array;
	For Each Var_Key In Keys Do // CatalogRef.ItemsCharacteristicsForPricing
		References.Add(Var_Key);
	EndDo;
		
	Query.SetParameter("References", References);
	
	DataOnCharacteristics = Query.Execute().Unload();
	For Each String In Rows Do
		String = Rows[String.Key];
		FoundRow = DataOnCharacteristics.Find(String.Data["Ref"], "Ref");
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
