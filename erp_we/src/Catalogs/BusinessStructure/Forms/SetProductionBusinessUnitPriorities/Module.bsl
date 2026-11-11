#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		
		Return;
		
	EndIf;
	
	RightToEditDivisions = AccessRight("Edit", Metadata.Catalogs.BusinessStructure);
	If Not RightToEditDivisions Then
		Items.TheQueueOfDivisionsMoveTheItemUp.Enabled = False;
		Items.TheQueueWillMoveTheItemDown.Enabled  = False;
	EndIf; 
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.DepartmentQueue.Representation = TableRepresentation.List;

EndProcedure

&AtClient
Procedure DepartmentQueueBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveItemUp(Command)
	
	MoveElement(Items.DepartmentQueue.CurrentRow, True);
	Items.DepartmentQueue.Refresh();
	
EndProcedure

&AtClient
Procedure MoveItemDown(Command)
	
	MoveElement(Items.DepartmentQueue.CurrentRow, False);
	Items.DepartmentQueue.Refresh();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure MoveElement(ObjectReference, Up)
	
	If ObjectReference = Undefined Then
		
		Return;
		
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	T.Ref AS Ref,
	|	CASE WHEN &Up THEN
	|		-T.AddlOrderingAttribute
	|	ELSE
	|		T.AddlOrderingAttribute
	|	END AS AddlOrderingAttribute
	|FROM
	|	Catalog.BusinessStructure AS T
	|
	|WHERE
	|	CASE WHEN &Up THEN
	|		T.AddlOrderingAttribute < &AddlOrderingAttribute
	|	ELSE
	|		T.AddlOrderingAttribute > &AddlOrderingAttribute
	|	END
	|	AND T.ProductionDispatcherBusinessUnit
	|
	|ORDER BY
	|	AddlOrderingAttribute");
	
	Query.SetParameter("Up", Up);
	Query.SetParameter("AddlOrderingAttribute", Common.ObjectAttributeValue(ObjectReference, "AddlOrderingAttribute"));
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	If Selection.Count() <> 1 Then
		
		Return;
		
	EndIf;
	
	Selection.Next();
	
	BeginTransaction();

	Try
		
		LockDataForEdit(ObjectReference);
		LockDataForEdit(Selection.Ref);
		
		ItemToMove = ObjectReference.GetObject(); // CatalogObject.BusinessStructure - 
		AdjacentElement = Selection.Ref.GetObject(); // CatalogObject.BusinessStructure -
		
		ItemToMove.AddlOrderingAttribute = ItemToMove.AddlOrderingAttribute + AdjacentElement.AddlOrderingAttribute;
		AdjacentElement.AddlOrderingAttribute     = ItemToMove.AddlOrderingAttribute - AdjacentElement.AddlOrderingAttribute;
		ItemToMove.AddlOrderingAttribute = ItemToMove.AddlOrderingAttribute - AdjacentElement.AddlOrderingAttribute;
	
		SetPrivilegedMode(True);
	
		ItemToMove.Write();
		AdjacentElement.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion
