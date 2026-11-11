
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a series for pricing
// 
// Parameters:
//  SearchDetails_ - Structure - Search data
//  Series Userusings - Structure - Series Usage Settings:
// * Error - Boolean -
// * ErrorDescription - String -
// * SpecifyUponReceipt - Boolean -
// * SpecifyOnShipment - Boolean -
// * SpecifyWhenPlanningShipment - Boolean -// 
// Returns:
//  CatalogRef.ItemsBatchesForPricing - Link to the Series for pricing
Function GetSeriesOfProductsForPricing(SearchDetails_) Export

	If SearchDetails_.PerformSearchXCO Then
		PricingSeries = FindSeriesOfTSOBySetOfAttributes(SearchDetails_);
		
		If PricingSeries <> Undefined Then
			If Not SearchDetails_.OneToOneLink 
				Or SearchDetails_.CurSeriesOfTSO.IsEmpty() Then
			
				Return PricingSeries;
				
			EndIf;
		Else
			PricingSeries = EmptyRef();
		EndIf;
	Else
		PricingSeries = SearchDetails_.CurSeriesOfTSO;
	EndIf;

	UpdateBankingDetails(PricingSeries, SearchDetails_);
	
	Return PricingSeries;

EndFunction

// The function returns the names of details that can be controlled
// 
// Returns:
// 	Array - The names of the details for which control is possible
Function GetSetOfControlDetails() Export

	ArrayOfBankingDetails  = New Array();
	ArrayOfBankingDetails.Add("ValidUntil_");
	ArrayOfBankingDetails.Add("ProductKind");
	ArrayOfBankingDetails.Add("Number");
	ArrayOfBankingDetails.Add("ProductionDate");
	ArrayOfBankingDetails.Add("NumberOfSPMSControlIdentificationMark");
	ArrayOfBankingDetails.Add("ManufacturerUSAIS");
	ArrayOfBankingDetails.Add("Certificate2USAIS");
	ArrayOfBankingDetails.Add("ManufacturerVetIS");
	ArrayOfBankingDetails.Add("WarehouseBookRecordVetIS");
	ArrayOfBankingDetails.Add("LotIDVetIS");
	ArrayOfBankingDetails.Add("MaximumRetailPriceMOTP");
	
	Return ArrayOfBankingDetails;
	
EndFunction

#EndRegion
	
#Region Private

Function FindSeriesOfTSOBySetOfAttributes(SearchDetails_)

	If SearchDetails_.OneToOneLink And Not SearchDetails_.CurSeriesOfTSO.IsEmpty() Then
		QueryText = "SELECT
		|	ItemsBatches.Ref
		|FROM
		|	Catalog.ItemsBatches AS ItemsBatches
		|WHERE
		|	ItemsBatches.ItemsBatchForPricing = &CurSeriesOfTSO
		|	AND ItemsBatches.Ref <> &CurSeries_";
		
		Query = New Query(QueryText);
		
		Query.SetParameter("CurSeriesOfTSO", SearchDetails_.CurSeriesOfTSO);
		Query.SetParameter("CurSeries_", SearchDetails_.CurSeries_);
		
		CheckResult = Query.Execute();
		If CheckResult.IsEmpty() Then
			Return SearchDetails_.CurSeriesOfTSO;
		EndIf;
	EndIf;
	
	DetailsForPriceKey = SearchDetails_.DetailsForPriceKey;

	Query = New Query;
	Query.SetParameter("ProductKind", SearchDetails_.ProductKind);
	
	QueryTemplate = "
	|SELECT
	|	SeriesOfTSOProductRange.Ref AS Ref
	|INTO SeriesOfTSOProductRange
	|FROM
	|	Catalog.ItemsBatchesForPricing AS SeriesOfTSOProductRange
	|	,&OneToOneCondition
	|WHERE
	|	SeriesOfTSOProductRange.ProductKind = &ProductKind
	|	AND SeriesOfTSOProductRange.AttributesCount = &AttributesCount
	|	AND &ConditionsForHCOAttributes
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SeriesOfTSOProductRange.Ref AS SeriesOfProductsOfCENTRAL
	|FROM
	|	SeriesOfTSOProductRange AS SeriesOfTSOProductRange
	|	,&ConnectionsByAdditionalXCOAttributes
	|WHERE
	|	&ConditionsForAdditionalHSOAttributes
	|";
	
	TableName = "TableOfTSOSeries";
	
	TagForConditionsBasedOnBankingDetails = 0;
	TagForAdditionalPaymentDetails = 0;
	
	ConditionsForHCOAttributes = New Array();
	ConditionsForAdditionalHSOAttributes = New Array();
	ConnectionsByAdditionalXCOAttributes = New Array();
	// We generate the text of the request condition using additional details, set parameters.
	For Each ConditionString In DetailsForPriceKey Do
		
		If ConditionString.IsAddlAttribute Then
			ConditionTagLineForAdditionalBankingDetails = Format(TagForAdditionalPaymentDetails,"NG=0");
	
			NameOfTableWithCondition = TableName + "SubjectToAdditionalBankingDetails_" + ConditionTagLineForAdditionalBankingDetails;
			
			ReplacementText = "
			|" + NameOfTableWithCondition + ".Property = &PropertyDOP_" + ConditionTagLineForAdditionalBankingDetails;
			ConditionsForAdditionalHSOAttributes.Add(ReplacementText);

			ReplacementText = "
			|" + NameOfTableWithCondition + ".Value = &DOPValue_" + ConditionTagLineForAdditionalBankingDetails;
			ConditionsForAdditionalHSOAttributes.Add(ReplacementText);

			Query.SetParameter("PropertyDOP_" + ConditionTagLineForAdditionalBankingDetails, ConditionString.Property);
			Query.SetParameter("DOPValue_" + ConditionTagLineForAdditionalBankingDetails, ConditionString.Value);
			
			ReplacementText = "
			| INNER JOIN Catalog.ItemsBatchesForPricing.AdditionalPricingAttributes AS " + NameOfTableWithCondition + "
			| On SeriesOfTSOProductRange.Ref = " + NameOfTableWithCondition + ".Ref";
			
			ConnectionsByAdditionalXCOAttributes.Add(ReplacementText);
			
			TagForAdditionalPaymentDetails = TagForAdditionalPaymentDetails + 1;
		Else
			
			ConditionsForHCOAttributes.Add(StrTemplate("SeriesOfTSOProductRange.%1 = &Value_%1", ConditionString.AttributeName));
			Query.SetParameter("Value_" + ConditionString.AttributeName, ConditionString.Value);
			TagForConditionsBasedOnBankingDetails = TagForConditionsBasedOnBankingDetails + 1;
			
		EndIf;
		
	EndDo;
	
	If SearchDetails_.OneToOneLink Then
		ReplacementText = "
		|RIGHT JOIN Catalog.ItemsBatches AS ItemsBatches
		|	ON SeriesOfTSOProductRange.Ref = ItemsBatches.ItemsBatchForPricing";

		ConditionsForHCOAttributes.Add("ItemsBatches.Ref IS NULL");
		QueryTemplate = StrReplace(QueryTemplate, ",&OneToOneCondition", ReplacementText);
	Else
		QueryTemplate = StrReplace(QueryTemplate, ",&OneToOneCondition", "");
	EndIf;

	If ConditionsForHCOAttributes.Count() > 0 Then
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionsForHCOAttributes", 
															StrConcat(ConditionsForHCOAttributes, " And " + Chars.LF));
	Else
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionsForHCOAttributes", "True");
	EndIf;
	
	If TagForAdditionalPaymentDetails > 0 Then
		QueryTemplate = StrReplace(QueryTemplate, ",&ConnectionsByAdditionalXCOAttributes", 
															StrConcat(ConnectionsByAdditionalXCOAttributes));
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionsForAdditionalHSOAttributes", 
															StrConcat(ConditionsForAdditionalHSOAttributes, " And "));
	Else
		QueryTemplate = StrReplace(QueryTemplate, ",&ConnectionsByAdditionalXCOAttributes", "");
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionsForAdditionalHSOAttributes", "TRUE");
	EndIf;
	
	If TagForConditionsBasedOnBankingDetails = 0
		And TagForAdditionalPaymentDetails  = 0 Then
		Return Undefined;
	EndIf;
	
	Query.Text = QueryTemplate;
	
	Query.SetParameter("AttributesCount", (TagForConditionsBasedOnBankingDetails + TagForAdditionalPaymentDetails));
	
	TSOSeries = Query.Execute().Unload().UnloadColumn("SeriesOfProductsOfCENTRAL");
	
	If TSOSeries.Count() > 0 Then
		Return TSOSeries[0];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Update Attributes.
// 
// Parameters:
//  PricingSeries - CatalogRef.ItemsBatchesForPricing - Pricing Series
//  SearchDetails_ - Structure - Search details
Function UpdateBankingDetails(PricingSeries, SearchDetails_)

	ActionCompleted = True;

	SetPrivilegedMode(True);

	ArrayForNameFormation = New Array();
	
	If PricingSeries.IsEmpty() Then
		CatObject = CreateItem();
	Else
		CatObject = PricingSeries.GetObject();
		CatObject.AdditionalPricingAttributes.Clear();
	EndIf;

	CatObject.ProductKind = SearchDetails_.ProductKind;

	For Each String In SearchDetails_.DetailsForPriceKey Do
		If String.IsAddlAttribute Then
			NewLineOfAdditionalDetails = CatObject.AdditionalPricingAttributes.Add();
			FillPropertyValues(NewLineOfAdditionalDetails, String);
		Else
			CatObject[String.AttributeName] = String.Value;
		EndIf;
		
		ArrayForNameFormation.Add(String.Value);
	EndDo;
	
	If IsBlankString(CatObject.Description) Then
		CatObject.Description = StrConcat(ArrayForNameFormation, ", ");
	EndIf;
	
	CatObject.AttributesCount = SearchDetails_.DetailsForPriceKey.Count();
	
	Try
		CatObject.Write();
	Except
		ActionCompleted = False;
	EndTry;
	
	PricingSeries = CatObject.Ref;
	
	SetPrivilegedMode(False);
	
	Return ActionCompleted;
	
EndFunction

#Region InfobaseUpdate

#EndRegion

#EndRegion

#EndIf