#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;
	
	// Installing the props of the props of ordering
	If Not Cancel And AddlOrderingAttribute = 0 Then
		
		AddlOrderingAttribute = GetAdditionalOrderingAttributes();
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	AddlOrderingAttribute = GetAdditionalOrderingAttributes();
	
EndProcedure

#EndRegion

#Region Private

Function GetAdditionalOrderingAttributes()
	
	Query = New Query(
		"SELECT TOP 1
		|	Table.AddlOrderingAttribute AS AddlOrderingAttribute
		|FROM
		|	Catalog.ProductionPhases AS Table
		|
		|ORDER BY
		|	AddlOrderingAttribute DESC");
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return ?(Not ValueIsFilled(Selection.AddlOrderingAttribute), 1, Selection.AddlOrderingAttribute + 1);
	
EndFunction

#EndRegion

#EndIf