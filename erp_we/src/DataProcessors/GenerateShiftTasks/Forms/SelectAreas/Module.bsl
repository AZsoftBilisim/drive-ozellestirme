
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Title = Metadata.FindByType(List.ValueType.Types()[0]).Synonym;
	
	Query = New Query(
		"SELECT
		|	ProductionSites.Ref AS Ref
		|FROM
		|	Catalog.ProductionSites AS ProductionSites
		|WHERE
		|	ProductionSites.Owner = &Department
		|	AND NOT ProductionSites.DeletionMark
		|
		|ORDER BY
		|	ProductionSites.Description");
	Query.SetParameter("Department", Parameters.Department);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		List.Add(Selection.Ref,,
			Parameters.SelectedValues.FindByValue(Selection.Ref) <> Undefined);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Result = New ValueList;
	
	For Each Item In List Do
		
		If Item.Check Then
			
			Result.Add(Item.Value);
			
		EndIf;
		
	EndDo;
	
	NotifyChoice(Result);
	
EndProcedure

#EndRegion
