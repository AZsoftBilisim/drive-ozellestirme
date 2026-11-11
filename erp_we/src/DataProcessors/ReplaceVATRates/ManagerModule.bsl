#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

 // Getting the number of Catalog items grouped by VAT Rates.
// 
// Parameters:
//  DataGetParameters - Structure - See DataGetParameters()
// 
// Returns:
//  Structure - See StructureOfFinalData() 
Function GettingDataOnVATRates(DataGetParameters) Export
	
	CatalogDataByVATRates = StructureOfFinalData();
	
	Query = New Query();
	Query.SetParameter("CurRate_",     DataGetParameters.CurRate_);
	Query.SetParameter("NewBid",       DataGetParameters.NewBid);
	Query.SetParameter("Period",            DataGetParameters.Period);
	Query.SetParameter("RegistrationCountry", DataGetParameters.Country);
	Query.SetParameter("DateEmpty",        Date(1,1,1));
	
	FillInNumberOfCatalogItems(Query, CatalogDataByVATRates, Catalogs.ItemKinds.EmptyRef().Metadata().Name);
	FillInNumberOfCatalogItems(Query, CatalogDataByVATRates, Catalogs.CounterpartyContracts.EmptyRef().Metadata().Name);
	FillInNumberOfCatalogItems(Query, CatalogDataByVATRates, Catalogs.LeaseContract.EmptyRef().Metadata().Name);
	FillInNumberOfCatalogItems(Query, CatalogDataByVATRates, Catalogs.Products.EmptyRef().Metadata().Name);
	
	If GetFunctionalOption("UseIntercompanyContracts") Then
		FillInNumberOfCatalogItems(Query, CatalogDataByVATRates, Catalogs.IntercompanyContracts.EmptyRef().Metadata().Name);
	EndIf;
	
	Return CatalogDataByVATRates;
	
EndFunction

// Parameters for getting Catalog data on VAT rates.
// 
// Returns:
//  Structure - Parameters for obtaining data for preparing the primary declaration:
//   * CurRate_ - CatalogRef.VATRates
//   * NewBid - CatalogRef.VATRates
//   * Country - CatalogRef.WorldCountries
//   * Period - Date
//   * ListOfReferenceBooks - ValueList of String - list of Catalog titles for processing
Function DataGetParameters() Export
	
	DataGetParameters = New Structure;
	DataGetParameters.Insert("CurRate_",      Catalogs.VATRates.EmptyRef());
	DataGetParameters.Insert("NewBid",        Catalogs.VATRates.EmptyRef());
	DataGetParameters.Insert("Country",             Catalogs.WorldCountries.EmptyRef());
	DataGetParameters.Insert("Period",             Date(1, 1, 1)); 
	DataGetParameters.Insert("ListOfReferenceBooks", New ValueList());
	
	Return DataGetParameters;
	
EndFunction

// The structure of the final data.
// 
// Returns:
//  Structure - Structure Of The Final Data:
// * Products - Array of Structure - See StructureOfReturnedData_() 
// * ItemKinds - Array of Structure - See StructureOfReturnedData_()  
// * CounterpartyContracts - Array of Structure - See StructureOfReturnedData_() 
// * LeaseContract - Array of Structure - See StructureOfReturnedData_()  
// * IntercompanyContracts - Array of Structure - See StructureOfReturnedData_()  
Function StructureOfFinalData() Export
	
	CatalogDataByVATRates = New Structure;
	CatalogDataByVATRates.Insert("Products", New Array());
	CatalogDataByVATRates.Insert("ItemKinds", New Array());
	CatalogDataByVATRates.Insert("CounterpartyContracts", New Array());
	CatalogDataByVATRates.Insert("LeaseContract", New Array());
	CatalogDataByVATRates.Insert("IntercompanyContracts", New Array());
	
	Return CatalogDataByVATRates;
	
EndFunction

// The structure of the final data.
// 
// Returns:
//  Structure:
//	 * VATRate - CatalogRef.VATRates
//	 * Count - Number
//	 * UID - String
Function StructureOfReturnedData_() Export
	
	StringStructure = New Structure();
	
	StringStructure.Insert("VATRate",  Catalogs.VATRates.EmptyRef());
	StringStructure.Insert("Count", 0);
	StringStructure.Insert("UID",        "");
	
	Return StringStructure;
	
EndFunction

#EndRegion

#Region Private

Procedure FillInNumberOfCatalogItems(Query, CatalogDataByVATRates, CatalogView)
	
	DataArray = New Array;
	
	If CatalogView = "ItemKinds" Then
		
		Query.Text = 
		"SELECT ALLOWED
		|	Catalog.VATRate AS VATRate,
		|	COUNT(DISTINCT Catalog.Ref) AS Count,
		|	VATRates.Rate1 AS Rate1
		|FROM
		|	Catalog.ItemKinds AS Catalog
		|		INNER JOIN Catalog.VATRates AS VATRates
		|		ON Catalog.VATRate = VATRates.Ref
		|WHERE
		|	NOT Catalog.DeletionMark
		|
		|GROUP BY
		|	Catalog.VATRate,
		|	VATRates.Rate1
		|
		|";
	ElsIf CatalogView = "LeaseContract" Then
		
		Query.Text = 
		"SELECT ALLOWED
		|	COUNT(DISTINCT TermsOfLeaseContracts.Contract) AS Count,
		|	TermsOfLeaseContracts.VATRate AS VATRate,
		|	VATRates.Rate1 AS Rate1
		|FROM
		|	InformationRegister.TermsOfLeaseContracts.SliceLast(&Period, ) AS TermsOfLeaseContracts
		|		INNER JOIN Catalog.VATRates AS VATRates
		|		ON TermsOfLeaseContracts.VATRate = VATRates.Ref
		|WHERE
		|	TermsOfLeaseContracts.State <> VALUE(Enum.CounterpartyContractStates.Closed)
		|
		|GROUP BY
		|	TermsOfLeaseContracts.VATRate,
		|	VATRates.Rate1
		|
		|";
	ElsIf CatalogView = "Products" Then
		
		Query.Text = 
		"SELECT ALLOWED
		|	COUNT(DISTINCT ProductsVATRatesSliceLast.Products) AS Count,
		|	ProductsVATRatesSliceLast.VATRate AS VATRate,
		|	VATRates.Rate1 AS Rate1
		|FROM
		|	InformationRegister.ProductsVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS ProductsVATRatesSliceLast
		|		INNER JOIN Catalog.VATRates AS VATRates
		|		ON ProductsVATRatesSliceLast.VATRate = VATRates.Ref
		|
		|GROUP BY
		|	ProductsVATRatesSliceLast.VATRate,
		|	VATRates.Rate1
		|
		|";
		
	Else
		
		Query.Text = 
		"SELECT ALLOWED
		|	Catalog.VATRate AS VATRate,
		|	VATRates.Rate1 AS Rate1,
		|	COUNT(DISTINCT Catalog.Ref) AS Count
		|FROM
		|	Catalog.CounterpartyContracts AS Catalog
		|		INNER JOIN Catalog.VATRates AS VATRates
		|		ON Catalog.VATRate = VATRates.Ref
		|WHERE
		|	NOT Catalog.DeletionMark
		|	AND Catalog.Status <> VALUE(Enum.CounterpartyContractStatuses.Closed)
		|	AND (Catalog.ValidityEndDate >= &Period
		|			OR Catalog.ValidityEndDate = &DateEmpty)
		|
		|GROUP BY
		|	Catalog.VATRate,
		|	VATRates.Rate1
		|
		|";
			
		Query.Text = StrReplace(Query.Text, "CounterpartyContracts", CatalogView);
			
	EndIf;
	
	Result = Query.Execute().Unload();
	Result.Sort("Rate1 Desc");
	For Each String In Result Do
		StringStructure = StructureOfReturnedData_();
		StringStructure.Insert("VATRate",  String.VATRate);
		StringStructure.Insert("Count", String.Count);
		StringStructure.Insert("UID",        ?(ValueIsFilled(String.VATRate),String.VATRate.UUID(),""));
		DataArray.Add(StringStructure);
	EndDo;
	
	CatalogDataByVATRates[CatalogView] = DataArray;

EndProcedure

#EndRegion

#EndIf
