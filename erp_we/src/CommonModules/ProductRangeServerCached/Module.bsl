////////////////////////////////////////////////////////////////////////////////
// The Assortment module contains procedures and functions for
// verifying the correctness of assortment change documents and setting assortment quotas,
// processing assortment registration in registers,
// processing user-entered data,
// and also contains a number of auxiliary functions and procedures.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The function returns the attribute for monitoring the assortment by the history of changes
//
// Parameters:
//  Warehouse  - CatalogRef.Warehouses - Warehouse / store for which assortment control is checked
//  OnDate  - Date - The date on which the product range control is checked.
//
// Returns:
//   Boolean   - True if the assortment is controlled in the warehouse and False if not.
//
Function ControlProductRange(Val Warehouse, Val OnDate = Undefined) Export 

	If GetFunctionalOption("UseProductRange") Then
	
		Return ProductRangeServer.ControlProductRange(Warehouse, OnDate);
	
	Else
	
		Return False;
	
	EndIf;

EndFunction 

// The function returns the store format based on the history of changes
//
// Parameters:
//  Warehouse  - CatalogRef.Warehouses - Warehouse / store for which the link with the store format is checked
//  OnDate  - Date - The date on which the product range control is checked.
//
// Returns:
//   Boolean   - True if the assortment is controlled in the warehouse and False if not.
//
Function StoreFormatByWarehouse(Val Warehouse, Val OnDate = Undefined) Export 

	If GetFunctionalOption("UseStoreFormats") Then
	
		Return ProductRangeServer.StoreFormatByWarehouse(Warehouse, OnDate);
	
	Else
	
		Return Warehouse;
	
	EndIf;

EndFunction 

#EndRegion