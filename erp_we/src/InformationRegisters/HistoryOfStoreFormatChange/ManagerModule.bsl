#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the current format of the store installed in the warehouse
//
// Parameters:
//  Warehouse  - CatalogRef.Warehouses - Warehouse to get the format for
//  OnDate  - Date - Optional. The date on which the format is obtained is the current date by default.
//
// Returns:
//   CatalogRef.StoreFormats   - the current store format for the warehouse.
//
Function CurFormat(Warehouse, OnDate = Undefined) Export 
	
	If OnDate = Undefined Then
		OnDate = CurrentSessionDate();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HistoryOfChangesToStoreFormatsCrossSection.StoreFormat
	|FROM
	|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(&OnDate, Warehouse = &Warehouse) AS HistoryOfChangesToStoreFormatsCrossSection";
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("OnDate", OnDate);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		Return SelectionDetailRecords.StoreFormat;
	EndIf;
	
	Return Catalogs.StoreFormats.EmptyRef();

EndFunction
 
// Returns the current format of the store installed in the warehouse
//
// Parameters:
//  Warehouse  - CatalogRef.Warehouses - Warehouse to get the format for
//  OnDate  - Date - Optional. The date on which the format is obtained is the current date by default.
//
// Returns:
//   CatalogRef.StoreFormats   - the current store format for the warehouse.
//
Function CurAssortmentSettings(Warehouse, OnDate = Undefined) Export 
	
	SetPrivilegedMode(True);
	
	If OnDate = Undefined Then
		OnDate = CurrentSessionDate();
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("ControlProductRange", False);
	Settings.Insert("StoreFormat", Catalogs.StoreFormats.EmptyRef());
	Settings.Insert("RetailPricesFromStoreFormat", False);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HistoryOfChangesToStoreFormatsCrossSection.StoreFormat,
	|	HistoryOfChangesToStoreFormatsCrossSection.ControlProductRange,
	|	HistoryOfChangesToStoreFormatsCrossSection.RetailPricesFromStoreFormat
	|FROM
	|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(&OnDate, Warehouse = &Warehouse) AS
	|		HistoryOfChangesToStoreFormatsCrossSection";
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("OnDate", OnDate);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		FillPropertyValues(Settings, SelectionDetailRecords);
	EndIf;
	
	Return Settings;

EndFunction

#EndRegion

#EndIf