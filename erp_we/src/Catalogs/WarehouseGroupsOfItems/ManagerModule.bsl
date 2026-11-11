#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the warehouse group if it is the only one in the directory.
//
// Returns:
//	CatalogRef.WarehouseGroupsOfItems - the found warehouse group.
//
Function DefaultProductInventoryGroup() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 2
	|	WarehouseGroupsOfItems.Ref AS WarehouseGroupOfProducts
	|FROM
	|	Catalog.WarehouseGroupsOfItems AS WarehouseGroupsOfItems
	|WHERE
	|	NOT WarehouseGroupsOfItems.DeletionMark";
	
	Selection = Query.Execute().Select();
	
	If Selection.Count() = 1 Then
		Selection.Next();
		WarehouseGroupOfProducts = Selection.WarehouseGroupOfProducts;
	Else
		WarehouseGroupOfProducts = Catalogs.WarehouseGroupsOfItems.EmptyRef();
	EndIf;
	
	Return WarehouseGroupOfProducts;

EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	
	Result.Add("PhysicallyDifferentFromAssignment; PhysicallyDifferentFromTheDestinationString, DoesNotPhysicallyDifferFromTheDestinationString");

	Return Result;

EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductsServerCall.WarehouseGroupsProductsProcessingOfSelectionData(ChoiceData, Parameters,
		StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

