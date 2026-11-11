#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets a brand if there is only one brand for the specified manufacturer in the reference list
// Parameters:
// Manufacturer - CatalogRef.Manufacturers - the manufacturer that owns the brand.
//
// Returns:
// CatalogRef.Brands - The found format of the store, an empty link if there are no stamps or more than one.
//
Function GetDefaultBrand(Manufacturer) Export
	
	Query = New Query(
	"SELECT ALLOWED TOP 2
	|	Brands.Ref AS Brand
	|FROM
	|	Catalog.Brands AS Brands
	|WHERE
	|	(NOT Brands.IsFolder)
	|	AND (NOT Brands.DeletionMark)
	|	AND (Brands.Manufacturer = &Manufacturer)
	|");
	Query.SetParameter("Manufacturer", Manufacturer);
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		Brand = Selection.Brand;
	Else
		Brand = Catalogs.Brands.EmptyRef();
	EndIf;
	
	Return Brand;

EndFunction

#EndRegion

#EndIf