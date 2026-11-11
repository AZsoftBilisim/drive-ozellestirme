#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillChoiceList();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	ListOfSelectedItems = New ValueList;
	For Each ChoiceItem In ChoiceList Do
		If ChoiceItem.Check Then
			ListOfSelectedItems.Add(ChoiceItem.Value, ChoiceItem.Presentation);
		EndIf;
	EndDo;
	
	Close(ListOfSelectedItems);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillChoiceList()

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	Teams.Ref AS Value,
	|	Teams.Presentation AS Presentation
	|FROM
	|	Catalog.Teams AS Teams
	|WHERE
	|	(&Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			OR Teams.Department = &Department)
	|	AND NOT Teams.DeletionMark
	|
	|ORDER BY
	|	Teams.Description";
	
	Query.SetParameter("Department", Parameters.Filter.Department);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		Check = (Parameters.ListOfSelectedItems.FindByValue(Selection.Value) <> Undefined);
		ChoiceList.Add(Selection.Value, Selection.Presentation, Check);
	EndDo;

EndProcedure

#EndRegion
