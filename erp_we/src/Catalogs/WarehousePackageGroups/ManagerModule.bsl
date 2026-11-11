#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the warehouse group if it is the only one in the directory.
//
// Returns:
//	CatalogRef.WarehousePackageGroups - the found warehouse group.
//
Function DefaultWarehouseGroupOfPackages() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 2
	|	WarehousePackageGroups.Ref AS WarehouseGroupOfPackages
	|FROM
	|	Catalog.WarehousePackageGroups AS WarehousePackageGroups
	|WHERE
	|	NOT WarehousePackageGroups.DeletionMark";
	
	Selection = Query.Execute().Select();
	
	If Selection.Count() = 1 Then
		Selection.Next();
		WarehouseGroupOfPackages = Selection.WarehouseGroupOfPackages;
	Else
		WarehouseGroupOfPackages = Catalogs.WarehousePackageGroups.EmptyRef();
	EndIf;
	
	Return WarehouseGroupOfPackages;

EndFunction

#EndRegion

#EndIf