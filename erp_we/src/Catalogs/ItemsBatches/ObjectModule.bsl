#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	SeriesUseSettings = Catalogs.ItemKinds.SeriesUseSettings(ProductKind);

	SetPricingDetails = False;
	If Not AdditionalProperties.Property("UsePriceManagementSystem25", SetPricingDetails) Then
		SetPricingDetails =	PriceManagementSystemServerCall.UsePriceManagementSystem25();
	EndIf;
	
	For Each Attribute In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If Not Attribute.Use Then
			ThisObject[Attribute.AttributeName] = Undefined;
		EndIf;
	EndDo;
	
	Number = TrimAll(Number);
	
	If SeriesUseSettings.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
		ValidUntil_ = BegOfHour(ValidUntil_);
	ElsIf SeriesUseSettings.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
		ValidUntil_ = BegOfMonth(ValidUntil_);
	Else
		ValidUntil_ = BegOfDay(ValidUntil_);
	EndIf;
	
	If ValueIsFilled(SeriesUseSettings.WorkingNameTemplateSetOfSeries) Then
		Description = ProductsServer.NameByTemplate(SeriesUseSettings.WorkingNameTemplateSetOfSeries, ThisObject);
	Else
		Description = ProductsClientServer.PresentationOfSeriesWithoutCalculationByNameTemplate(SeriesUseSettings, ThisObject);
	EndIf;
	
	PriceKeySettings = SeriesUseSettings.SettingsOfPriceKeyByBatch;
	If SetPricingDetails 
		And ValueIsFilled(PriceKeySettings)
		And PriceKeySettings <> Enums.FilterOptionForPriceKey.DontUse Then
			
		UpdatingPricingSettingsProductTypes = False;
		If Not AdditionalProperties.Property("UpdatingPricingSettingsProductTypes", UpdatingPricingSettingsProductTypes) Then
			UpdatingPricingSettingsProductTypes = False;
		EndIf;
		
		PerformSearchXCO = UpdatingPricingSettingsProductTypes;
		If Not UpdatingPricingSettingsProductTypes Then
			If PriceKeySettings = Enums.FilterOptionForPriceKey.UseByAttributes Then
				PerformSearchXCO = True;
			ElsIf PriceKeySettings = Enums.FilterOptionForPriceKey.Use Then
				PerformSearchXCO = False;
			EndIf;
		EndIf;

		SearchDetails_ = GetAttributesForSearch(ProductKind, SeriesUseSettings, PerformSearchXCO);
		ItemsBatchForPricing = Catalogs.ItemsBatchesForPricing.GetSeriesOfProductsForPricing(SearchDetails_);
		
	EndIf;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
	TMCommonUse.SyncKeys(ThisObject);	
	
EndProcedure

Procedure OnCopy(CopiedObject)
	ItemsBatchForPricing = Catalogs.ItemsBatchesForPricing.EmptyRef();
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	SeriesUseSettings = Catalogs.ItemKinds.SeriesUseSettings(ProductKind);

	For Each Attribute In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If Not Attribute.Use
			Or Not Attribute.CheckFilling Then
			NotCheckedAttributeArray.Add(Attribute.AttributeName);
		EndIf;
	EndDo;
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;
	
	ProductKind = FillingData.ProductKind;
	SeriesUseSettings = New FixedStructure(Catalogs.ItemKinds.SeriesUseSettings(ProductKind));
	
	FieldsStructure = New Structure;
	
	For Each Attribute In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If Attribute.Use Then
			FieldsStructure.Insert(Attribute.AttributeName);
		EndIf;
	EndDo;
			
	FillPropertyValues(FieldsStructure, FillingData);
	
	FillPropertyValues(ThisObject, FieldsStructure);
	
EndProcedure

#EndRegion

#Region Internal

// Get Attributes for the search.
// 
// Parameters:
//  ProductKind - CatalogRef.ItemKinds - Product kind
//  SeriesUseSettings - Structure - details of the object
//  PerformSearchXCO - Boolean - Search for XCO
// 
// Returns:
//  Structure - Get Attributes For The Search:
// * CurSeries_ - CatalogRef.ItemsBatches -
// * CurSeriesOfTSO - CatalogRef.ItemsBatchesForPricing -
// * PerformSearchXCO - Boolean -
// * ProductKind - CatalogRef.ItemKinds -
// * OneToOneLink - Boolean - The truth is, based on the series, there is only one series pricing
// * DetailsForPriceKey - ValueTable -
Function GetAttributesForSearch(Val ProductKind, Val SeriesUseSettings, Val PerformSearchXCO) Export

	//	get a list of additional details by which to search for a series
	DetailsForPriceKey = Catalogs.ItemKinds.GetDetailsForPricingKey(ProductKind, "SetOfSeries");
	
	SearchDetails_ = New Structure;
	SearchDetails_.Insert("CurSeries_",         Ref);
	SearchDetails_.Insert("CurSeriesOfTSO",       ItemsBatchForPricing);
	SearchDetails_.Insert("PerformSearchXCO",   PerformSearchXCO);
	SearchDetails_.Insert("ProductKind",      ProductKind);
	SearchDetails_.Insert("OneToOneLink",    False);
	
	If SeriesUseSettings.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.UseByAttributes Then
		AdditionalAttributesData = AdditionalAttributes.Unload(); 
		
		For Each StringOfPropsForPriceKey In DetailsForPriceKey Do
			If StringOfPropsForPriceKey.IsAddlAttribute Then
				FoundRow = AdditionalAttributesData.Find(StringOfPropsForPriceKey.Property, "Property");
				StringOfPropsForPriceKey.Value = FoundRow.Value;
			Else
				StringOfPropsForPriceKey.Value = ThisObject[StringOfPropsForPriceKey.AttributeName];
			EndIf;
		EndDo;
	Else // for all the details for pricing
		SearchDetails_.Insert("OneToOneLink",          True);
		ArrayOfBankingDetails = Catalogs.ItemsBatchesForPricing.GetSetOfControlDetails();
	
		For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
			If LongDesc.Use And ArrayOfBankingDetails.Find(LongDesc.AttributeName) <> Undefined Then

				StringOfPropsForPriceKey = DetailsForPriceKey.Add();
				StringOfPropsForPriceKey.AttributeName   = LongDesc.AttributeName;
				StringOfPropsForPriceKey.IsAddlAttribute = False;
				StringOfPropsForPriceKey.Used   = True;
				StringOfPropsForPriceKey.Value = ThisObject[LongDesc.AttributeName];
			EndIf;
		EndDo;
		
		For Each String In AdditionalAttributes Do
			StringOfPropsForPriceKey = DetailsForPriceKey.Add();
			FillPropertyValues(StringOfPropsForPriceKey, String);
			StringOfPropsForPriceKey.AttributeName = String.Property;
			StringOfPropsForPriceKey.IsAddlAttribute = True;
			StringOfPropsForPriceKey.Used = True;
		EndDo;
		
		StringOfPropsForPriceKey = DetailsForPriceKey.Add();
		StringOfPropsForPriceKey.AttributeName   = "Description";
		StringOfPropsForPriceKey.Value       = Description;
		StringOfPropsForPriceKey.IsAddlAttribute = False;
		StringOfPropsForPriceKey.Used   = True;
		
	EndIf;
	
	SearchDetails_.Insert("DetailsForPriceKey", DetailsForPriceKey);
	
	Return SearchDetails_
	
EndFunction

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion
#EndIf
#EndIf