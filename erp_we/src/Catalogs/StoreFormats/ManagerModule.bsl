#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Gets the store format if the format is the same in the directory
//
// Returns:
// CatalogRef.StoreFormats - Found store format
// Referenceslink.Empty link - if there are no formats or more than one.
//
Function GetDefaultStoreFormat() Export
	
	Query = New Query(
	"SELECT ALLOWED TOP 2
	|	StoreFormats.Ref AS StoreFormat
	|FROM
	|	Catalog.StoreFormats AS StoreFormats
	|WHERE
	|	(NOT StoreFormats.IsFolder)
	|	AND (NOT StoreFormats.DeletionMark)");
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		StoreFormat = Selection.StoreFormat;
	Else
		StoreFormat = Catalogs.StoreFormats.EmptyRef();
	EndIf;
	
	Return StoreFormat;

EndFunction

// Generates a query text for a temporary table of current store formats and their warehouses.
//
// Returns:
// String - Query text
//
Function QueryTextTTWarehouseFormats(SelectWarehouses = True) Export
	
	If SelectWarehouses Then
		
		QueryText =
			"SELECT ALLOWED
			|	TableFormats.Warehouse          AS Warehouse,
			|	TableFormats.StoreFormat AS StoreFormat
			|INTO TTWarehouseFormats
			|FROM
			|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(,
			|		Warehouse IN (
			|			SELECT DISTINCT
			|				TableWarehouses_.Warehouse
			|			FROM
			|				TTProducts_1 AS TableWarehouses_)) AS TableFormats
			|WHERE
			|	TableFormats.StoreFormat <> VALUE(Catalog.StoreFormats.EmptyRef)
			|INDEX BY
			|	Warehouse
			|;
			|
			|/////////////////////////////////////////////////
			|";
			
	Else
		
		QueryText =
			"SELECT ALLOWED
			|	TableFormats.Warehouse          AS Warehouse,
			|	TableFormats.StoreFormat AS StoreFormat
			|INTO TTWarehouseFormats
			|FROM
			|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(, ) AS TableFormats
			|WHERE
			|	TableFormats.StoreFormat <> VALUE(Catalog.StoreFormats.EmptyRef)
			|INDEX BY
			|	Warehouse
			|;
			|
			|/////////////////////////////////////////////////
			|";
			
	EndIf;
	
	Return QueryText;

EndFunction

// Gets the object's blocked details
//
// Returns:
//	Array - the names of the object's details.
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("RetailPriceType;RetailPriceType,UseTheRetailPriceView");
	Result.Add("SpecialPriceType;SpecialPriceTypePresentation,UseAnIndividualViewOfThePrice");
	
	Result.Add("StoreSupportsOrderAssembly;StoreSupportsOrderAssembly");
	Result.Add("StoreSupportsDeliveryByOwnCouriers;StoreSupportsDeliveryByOwnCouriers");
	
	Return Result;

EndFunction

// Gets a list of warehouses in the desired format
//
// Parameters:
//	Format - CatalogRef.StoreFormats - the format of the store which are selected warehouses
// Returns:
//	Array - an array of warehouse links.
Function FormatWarehouses(Format) Export
	
	FormatWarehouses = New Array();
	If ValueIsFilled(Format) Then
		
		Query = New Query();
		Query.Text =
			"SELECT
			|	Table.Warehouse AS Ref
			|FROM
			|	InformationRegister.HistoryOfStoreFormatChange.SliceLast() AS Table
			|WHERE
			|	Table.StoreFormat = &Format";
		Query.SetParameter("Format", Format);
		FormatWarehouses = Query.Execute().Unload().UnloadColumn("Ref");
		
	EndIf;
	
	Return FormatWarehouses;
	
EndFunction

// Checks the possibility and sets an individual price list for the object.
// 
// Parameters:
// 	Ref - CatalogRef.StoreFormats - Link to the price list column.
// 	PricesKind - CatalogRef.TypesOfPrices - Link to the price list column.
// Returns:
// 	Boolean - The result of the execution.
Function InstallIPL(Ref, PricesKind) Export
	OperationResult = False;
	
	CatalogObject = Ref.GetObject();
	If ValueIsFilled(CatalogObject.SpecialPriceType) Then
		OperationResult = False;
		
		MessageTextTemplate = NStr("vi = 'Chưa thiết lập dạng giá riêng đối với khuôn dạng cửa hàng ""%ObjectName_1%"" do nguyên nhân: %Cause%';
									|ru = 'Не произведена установка индивидуального виды цен для формата магазинов ""%ObjectName_1%"" по причине: %Cause%';
									|en = 'The individual price types have not been set for the retail format ""%ObjectName_1%"". Reason: %Cause%'; fa = 'The individual price types have not been set for the retail format ""%ObjectName_1%"". Reason: %Cause%';
									|it = 'Non è stata eseguita l''impostazione di tipo di prezzo individuale per il formato del punto vendita ""%ObjectName_1%"" a causa di: %Cause%';
									|pl = 'Nie wykonano ustawienia indywidualnego rodzaju cen dla formatu sklepów ""%ObjectName_1%"" z powodu: %Cause%';
									|tr = '""%ObjectName_1%"" mağaza formatı için özelleştirilmiş fiyat türünün yapılandırılamama nedeni: %Cause%'");
		MessageText = StrReplace(MessageTextTemplate, "%ObjectName_1%", CatalogObject.Description);
		MessageText = StrReplace(MessageText, "%Cause%", "u format_ ofstores already is_specified individual_ kind prices_!");
		
		Raise MessageText;
	Else	
		CatalogObject.SpecialPriceType = PricesKind;
		SetPrivilegedMode(True);
		CatalogObject.Write();
		SetPrivilegedMode(False);
		OperationResult = True;
	EndIf;
	
	Return OperationResult;
EndFunction

// Deletes the individual price list for the item.
// 
// Parameters:
// 	Ref - CatalogRef.StoreFormats - Link to the price list column.
// Returns:
// 	Boolean - The result of the execution.
Function DeleteIPL(Ref) Export
	OperationResult = False;	
	
	CatalogObject = Ref.GetObject();
	CatalogObject.SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
	SetPrivilegedMode(True);
	CatalogObject.Write();
	SetPrivilegedMode(False);
	
	OperationResult = True;
	
	Return OperationResult;
EndFunction

#EndRegion

#EndIf