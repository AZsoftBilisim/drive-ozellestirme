#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Get the characteristics of the item for pricing.
// 
// Parameters:
//  SearchDetails_ - Structure - Search details
// 
// Returns:
//  CatalogRef.ItemsCharacteristicsForPricing - To obtain the feature item for pricing
Function GetCharacteristicsOfProductsForPricing(SearchDetails_) Export

	If SearchDetails_.SearchForXCO Then
		PricingCharacteristics = FindCharacteristicsOfCenterBySetOfAttributes(SearchDetails_);
		
		If PricingCharacteristics <> Undefined Then
			If Not SearchDetails_.OneToOneLink 
				Or SearchDetails_.CurCurrentCharacteristicsOfTSO.IsEmpty() Then
			
				Return PricingCharacteristics;
				
			EndIf;
		Else
			PricingCharacteristics = EmptyRef();
		EndIf;
	Else
		PricingCharacteristics = SearchDetails_.CurCurrentCharacteristicsOfTSO;
	EndIf;

	UpdateBankingDetails(PricingCharacteristics, SearchDetails_);
	
	Return PricingCharacteristics;
	
EndFunction

// Synchronize the deletion tag.
// 
// Parameters:
//  SynchronizationParameters - Structure - Synchronization Parameters
// 
// Returns:
//  Boolean - Synchronize the deletion tag
Function SyncDeleteTag(SynchronizationParameters) Export

	ActionCompleted = True;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ItemsCharacteristics.Ref
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		LEFT JOIN Catalog.ItemsCharacteristicsForPricing AS
	|			ItemsCharacteristicsForPricing
	|		ON ItemsCharacteristics.ItemsCharacteristicForPricing = ItemsCharacteristicsForPricing.Ref
	|WHERE
	|	ItemsCharacteristicsForPricing.Ref = &Ref
	|	AND NOT ItemsCharacteristics.DeletionMark
	|	AND NOT ItemsCharacteristics.Ref = &ProductCharacteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsCharacteristicsForPricing.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.ItemsCharacteristicsForPricing AS ItemsCharacteristicsForPricing
	|WHERE
	|	ItemsCharacteristicsForPricing.Ref = &Ref
	|	AND NOT ItemsCharacteristicsForPricing.DeletionMark = &DeletionMark";
	
	Query.SetParameter("ProductCharacteristic", SynchronizationParameters.ProductCharacteristic);
	Query.SetParameter("Ref", SynchronizationParameters.ItemsCharacteristicForPricing);
	Query.SetParameter("DeletionMark",  SynchronizationParameters.DeletionMark);
	
	Results = Query.ExecuteBatch();
	
	// if the marks for deletion do not differ
	If Results[1].Unload().Count() = 0 Then
		Return ActionCompleted;
	EndIf;
	
	// if there are no more links to the pricing characteristic, we change the mark
	If Results[0].Unload().Count() = 0 Then
		Try
			CatObject = SynchronizationParameters.ItemsCharacteristicForPricing.GetObject();
			CatObject.DeletionMark = SynchronizationParameters.DeletionMark;
			CatObject.Write();
		Except
			ActionCompleted = False;
		EndTry;
	EndIf;
	
	Return ActionCompleted;

EndFunction

#EndRegion
	
#Region Private

Function FindCharacteristicsOfCenterBySetOfAttributes(SearchDetails_)
	
	If SearchDetails_.OneToOneLink And Not SearchDetails_.CurCurrentCharacteristicsOfTSO.IsEmpty() Then
		QueryText = "SELECT
		|	ItemsCharacteristics.Ref
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.ItemsCharacteristicForPricing = &CurCurrentCharacteristicsOfTSO
		|	AND ItemsCharacteristics.Ref <> &CurrentCharacteristic";
		
		Query = New Query(QueryText);
		
		Query.SetParameter("CurCurrentCharacteristicsOfTSO", SearchDetails_.CurCurrentCharacteristicsOfTSO);
		Query.SetParameter("CurrentCharacteristic", SearchDetails_.CurrentCharacteristic);
		
		CheckResult = Query.Execute();
		If CheckResult.IsEmpty() Then
			Return SearchDetails_.CurCurrentCharacteristicsOfTSO;
		EndIf;
	EndIf;
	
	DetailsForPriceKey = SearchDetails_.DetailsForPriceKey;

	Query = New Query;
	Query.SetParameter("ProductKind", SearchDetails_.ProductKind);
	
	QueryTemplate = "
	|SELECT
	|	CharacteristicsOfTSOProductRange.Ref AS Ref
	|INTO CharacteristicsOfTSOProductRange
	|FROM
	|	Catalog.ItemsCharacteristicsForPricing AS CharacteristicsOfTSOProductRange
	|	,&OneToOneCondition
	|WHERE
	|	CharacteristicsOfTSOProductRange.ProductKind = &ProductKind
	|	AND CharacteristicsOfTSOProductRange.AttributesCount = &AttributesCount
	|	AND &ConditionsForAttributesOfHCO
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CharacteristicsOfTSOProductRange.Ref AS CharacteristicsOfProductRangeOfTSO
	|FROM
	|	CharacteristicsOfTSOProductRange AS CharacteristicsOfTSOProductRange
	|	,&ConnectionsByAdditionalAttributesOfXCO
	|WHERE
	|	&ConditionsForAdditionalXCOAttributes
	|";
	
	TableName = "TableOfCharacteristicsOfCenter";
	
	TagForConditionsBasedOnBankingDetails = 0;
	TagForAdditionalPaymentDetails = 0;
	
	ConditionsForAttributesOfHCO = New Array();
	ConditionsForAdditionalXCOAttributes = New Array();
	ConnectionsByAdditionalAttributesOfXCO = New Array();
	// We generate the text of the request condition using additional details, set parameters.
	For Each ConditionString In DetailsForPriceKey Do
		
		If ConditionString.IsAddlAttribute Then
			ConditionTagLineForAdditionalBankingDetails = Format(TagForAdditionalPaymentDetails,"NG=0");
	
			NameOfTableWithCondition = TableName + "SubjectToAdditionalBankingDetails_" + ConditionTagLineForAdditionalBankingDetails;
			
			ReplacementText = "
			|" + NameOfTableWithCondition + ".Property = &PropertyDOP_" + ConditionTagLineForAdditionalBankingDetails;
			ConditionsForAdditionalXCOAttributes.Add(ReplacementText);

			ReplacementText = "
			|" + NameOfTableWithCondition + ".Value = &DOPValue_" + ConditionTagLineForAdditionalBankingDetails;
			ConditionsForAdditionalXCOAttributes.Add(ReplacementText);

			Query.SetParameter("PropertyDOP_" + ConditionTagLineForAdditionalBankingDetails, ConditionString.Property);
			Query.SetParameter("DOPValue_" + ConditionTagLineForAdditionalBankingDetails, ConditionString.Value);
			
			ReplacementText = "
			| INNER JOIN Catalog.ItemsCharacteristicsForPricing.AdditionalPricingAttributes AS " + NameOfTableWithCondition + "
			| On CharacteristicsOfTSOProductRange.Ref = " + NameOfTableWithCondition + ".Ref";
			
			ConnectionsByAdditionalAttributesOfXCO.Add(ReplacementText);
			
			TagForAdditionalPaymentDetails = TagForAdditionalPaymentDetails + 1;
		Else
			
			ConditionsForAttributesOfHCO.Add(StrTemplate("CharacteristicsOfTSOProductRange.%1 = &Value_%1", ConditionString.AttributeName));
			Query.SetParameter("Value_" + ConditionString.AttributeName, ConditionString.Value);
			TagForConditionsBasedOnBankingDetails = TagForConditionsBasedOnBankingDetails + 1;
			
		EndIf;
		
	EndDo;
	
	If SearchDetails_.OneToOneLink Then
		ReplacementText = "
		|RIGHT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|	ON CharacteristicsOfTSOProductRange.Ref = ItemsCharacteristics.ItemsCharacteristicForPricing";

		ConditionsForAttributesOfHCO.Add("ItemsCharacteristics.Ref IS NULL");
		QueryTemplate = StrReplace(QueryTemplate, ",&OneToOneCondition", ReplacementText);
	Else
		QueryTemplate = StrReplace(QueryTemplate, ",&OneToOneCondition", "");
	EndIf;

	If ConditionsForAttributesOfHCO.Count() > 0 Then
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionsForAttributesOfHCO", 
															StrConcat(ConditionsForAttributesOfHCO, " And " + Chars.LF));
	Else
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionsForAttributesOfHCO", "True");
	EndIf;
	
	If TagForAdditionalPaymentDetails > 0 Then
		QueryTemplate = StrReplace(QueryTemplate, ",&ConnectionsByAdditionalAttributesOfXCO", 
															StrConcat(ConnectionsByAdditionalAttributesOfXCO));
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionsForAdditionalXCOAttributes", 
															StrConcat(ConditionsForAdditionalXCOAttributes, " And "));
	Else
		QueryTemplate = StrReplace(QueryTemplate, ",&ConnectionsByAdditionalAttributesOfXCO", "");
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionsForAdditionalXCOAttributes", "TRUE");
	EndIf;
	
	If TagForConditionsBasedOnBankingDetails = 0
		And TagForAdditionalPaymentDetails  = 0 Then
		Return Undefined;
	EndIf;
	
	Query.Text = QueryTemplate;
	
	Query.SetParameter("AttributesCount", (TagForConditionsBasedOnBankingDetails + TagForAdditionalPaymentDetails));
	
	CharacteristicsOfTSO = Query.Execute().Unload().UnloadColumn("CharacteristicsOfProductRangeOfTSO");
	
	If CharacteristicsOfTSO.Count() > 0 Then
		Return CharacteristicsOfTSO[0];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Update Attributes.
// 
// Parameters:
//  PricingCharacteristics - CatalogRef.ItemsCharacteristicsForPricing - Pricing characteristics
//  SearchDetails_ - Structure - Search details
Function UpdateBankingDetails(PricingCharacteristics, SearchDetails_)

	ActionCompleted = True;

	SetPrivilegedMode(True);

	ArrayForNameFormation = New Array();
	
	If PricingCharacteristics.IsEmpty() Then
		CatObject = Catalogs.ItemsCharacteristicsForPricing.CreateItem();
	Else
		CatObject = PricingCharacteristics.GetObject();
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
	
	PricingCharacteristics = CatObject.Ref;
	
	SetPrivilegedMode(False);
	
	Return ActionCompleted;
	
EndFunction

#Region InfobaseUpdate

#EndRegion

#EndRegion

#EndIf