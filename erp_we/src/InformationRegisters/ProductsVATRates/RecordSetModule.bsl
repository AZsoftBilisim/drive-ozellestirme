#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If Not GetFunctionalOption("UseMultiCountryAccounting") And IsNewRecord() Then
		For Each Record In ThisObject Do
			Record.Country = SettingsValueClientServerCached.MainCountry();
		EndDo;
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseMultiCountryAccounting") And IsNewRecord() Then
		Constants.MainCountry.CheckFilling();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		SynchronizeInitialDataByCountry();
	EndIf;
	
	UpdateProductSVATRate();
	
EndProcedure

#EndRegion

#Region Private

#Region Products

Procedure UpdateProductSVATRate()
	
	If AdditionalProperties.Property("SkipUpdatingProductSVATRate") Then
		Return;
	EndIf;
	
	MainCountry = SettingsValueClientServerCached.MainCountry();
	
	If Count() Then
		
		RecordsTable = Unload();
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.ProductsVATRates");
		LockItem.SetValue("Country", MainCountry);
		LockItem.DataSource = RecordsTable;
		LockItem.UseFromDataSource("Products", "Products");
		LockItem.Mode = DataLockMode.Shared;
		Block.Lock();
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ProductsVATRates.Period AS Period,
		|	ProductsVATRates.Products AS Products,
		|	CASE
		|		WHEN ProductsVATRates.Country = VALUE(Catalog.WorldCountries.EmptyRef)
		|			THEN &MainCountry
		|		ELSE ProductsVATRates.Country
		|	END AS Country,
		|	ProductsVATRates.VATRate AS VATRate
		|INTO RecordedProductVATRates
		|FROM
		|	&ProductsVATRates AS ProductsVATRates
		|WHERE
		|	(ProductsVATRates.Country = &MainCountry
		|			OR ProductsVATRates.Country = VALUE(Catalog.WorldCountries.EmptyRef))
		|
		|INDEX BY
		|	Period,
		|	Products,
		|	Country,
		|	VATRate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CurrentBids.Products AS Products,
		|	CurrentBids.VATRate AS VATRate
		|FROM
		|	RecordedProductVATRates AS RecordedProductVATRates
		|		INNER JOIN InformationRegister.ProductsVATRates.SliceLast AS CurrentBids
		|		ON RecordedProductVATRates.Period = CurrentBids.Period
		|			AND RecordedProductVATRates.Products = CurrentBids.Products
		|			AND RecordedProductVATRates.Country = CurrentBids.Country
		|			AND RecordedProductVATRates.VATRate = CurrentBids.VATRate";
		
		Query.SetParameter("ProductsVATRates", RecordsTable);
		Query.SetParameter("MainCountry", MainCountry);
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			ItemProducts_ = GetNomenclatureObjectWithVerification(Filter.Products.Value);
			If ItemProducts_ = Undefined Then
				Continue;;
			EndIf;
			
			LockAndWriteProducts(ItemProducts_, Selection.VATRate);
			
		EndDo;
		
	Else
		
		ItemProducts_ = GetNomenclatureObjectWithVerification(Filter.Products.Value);
		If ItemProducts_ = Undefined Then
			Return;
		EndIf;

		Date = BegOfMonth(CurrentSessionDate());
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	1 AS Priority,
		|	ProductsVATRates.VATRate AS VATRate
		|FROM
		|	InformationRegister.ProductsVATRates.SliceLast(&Date, Products = &Products
		|	AND Country = &MainCountry) AS ProductsVATRates
		|
		|UNION ALL
		|
		|SELECT
		|	2 AS Priority,
		|	ProductsVATRates.VATRate AS VATRate
		|FROM
		|	InformationRegister.ProductsVATRates.SliceLast(&Date, Products = &Products
		|	AND Country = &EmptyCountry) AS ProductsVATRates
		|
		|UNION ALL
		|
		|SELECT
		|	3 AS Priority,
		|	BasicVATRates.VATRate AS VATRate
		|FROM
		|	InformationRegister.BasicVATRates.SliceLast(&Date, Country = &MainCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS BasicVATRates
		|ORDER BY
		|	Priority";
		
		Query.SetParameter("Date", Date);
		Query.SetParameter("Products", ItemProducts_.Ref);
		Query.SetParameter("MainCountry", MainCountry);
		Query.SetParameter("EmptyCountry", Catalogs.WorldCountries.EmptyRef());
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			LockAndWriteProducts(ItemProducts_, Selection.VATRate);
			If Selection.Priority = 3 Then
				
				RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
				RecordSet.Filter.Period.Set(Date);
				RecordSet.Filter.Products.Set(ItemProducts_.Ref);
				RecordSet.Filter.Country.Set(MainCountry);
				
				NewRecord = RecordSet.Add();
				NewRecord.Period = Date;
				NewRecord.Products = ItemProducts_.Ref;
				NewRecord.Country = MainCountry;
				NewRecord.VATRate = Selection.VATRate;
				
				RecordSet.AdditionalProperties.Insert("SkipUpdatingProductSVATRate");
				RecordSet.Write();
				
			EndIf;
		EndIf;
		
	EndIf;	
	
EndProcedure

Procedure LockAndWriteProducts(ItemProducts_, VATRate)
	
	If ItemProducts_.VATRate = VATRate Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.Products");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("Ref", ItemProducts_.Ref);
	
	ItemProducts_.VATRate = VATRate;
	ItemProducts_.DataExchange.Load = True;
	
	ItemProducts_.Write();
	
EndProcedure

Function GetNomenclatureObjectWithVerification(ProductsLink)
	
	If Not ValueIsFilled(ProductsLink) Then
		Return Undefined;
	EndIf;
	
	Return ProductsLink.GetObject();
	
EndFunction

#EndRegion

Procedure SynchronizeInitialDataByCountry()
	
	EmptyCountry = Catalogs.WorldCountries.EmptyRef();
	
	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.ProductsVATRates");
	LockItem.DataSource = Unload();
	LockItem.UseFromDataSource("Products", "Products");
	LockItem.Mode = DataLockMode.Exclusive;
	Block.Lock();

	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProductsVATRates.Period AS Period,
		|	ProductsVATRates.Products AS Products,
		|	ProductsVATRates.VATRate AS VATRate
		|FROM
		|	InformationRegister.ProductsVATRates AS ProductsVATRates
		|WHERE
		|	ProductsVATRates.Products IN(&Products)
		|	AND ProductsVATRates.Country = &EmptyCountry";
	
	Query.SetParameter("Products", UnloadColumn("Products"));
	Query.SetParameter("EmptyCountry", EmptyCountry);
	
	QueryResult = Query.Execute();
		
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
			RecordSet.Filter.Period.Set(Selection.Period);
			RecordSet.Filter.Products.Set(Selection.Products);
			RecordSet.DataExchange.Load = True;
			RecordSet.Write();
			
			RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
			RecordSet.Filter.Period.Set(Selection.Period);
			RecordSet.Filter.Products.Set(Selection.Products);
			RecordSet.Filter.Country.Set(SettingsValueClientServerCached.MainCountry());
			
			NewRecord = RecordSet.Add();
			NewRecord.Period = Selection.Period;
			NewRecord.Products = Selection.Products;
			NewRecord.Country = SettingsValueClientServerCached.MainCountry();
			NewRecord.VATRate = Selection.VATRate;
			
			RecordSet.DataExchange.Load = True;
			RecordSet.Write();
			
		EndDo;
	EndIf;
	
EndProcedure

Function IsNewRecord()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProductsVATRates.Period AS Period
		|FROM
		|	InformationRegister.ProductsVATRates AS ProductsVATRates
		|WHERE
		|	ProductsVATRates.Period IN(&Period)
		|	AND ProductsVATRates.Products IN(&Products)
		|	AND ProductsVATRates.Country IN(&Country)";
	
	Query.SetParameter("Products", UnloadColumn("Products"));
	Query.SetParameter("Period", UnloadColumn("Period"));
	Query.SetParameter("Country", UnloadColumn("Country"));
	
	QueryResult = Query.Execute();
	
	Return QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#EndIf