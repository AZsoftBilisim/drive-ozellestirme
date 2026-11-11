#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function gets the reference element - the key of the item accounting analysis.
//
// Parameters:
//	AnalyticsParameters - DataSelection, Structure - A selection or Structure with the fields "Nomenclature, Characteristic".
//
// Returns:
//	CatalogRef.InventoryLocationAttributeKeys - The created directory element.
//
Function AnalyticsKeyValue(AnalyticsParameters) Export

	RecordSet = GetRecordSet(AnalyticsParameters);
	
	If RecordSet <> Undefined Then
		RecordSet.Read();
		
		If RecordSet.Count() > 0
			And Not ValueIsFilled(RecordSet[0].DimensionKey) Then
			RecordSet.Clear();
			RecordSet.Write();
		EndIf;

		If RecordSet.Count() > 0
			And ValueIsFilled(RecordSet[0].DimensionKey) Then
			Result = RecordSet[0].DimensionKey;
		Else
			Result = CreateAnalyticsKey(AnalyticsParameters);
		EndIf;

		Return Result;
	EndIf;

EndFunction

// The function gets the reference element-the accounting Analytics key.
//
// Parameters:
//	AnalyticsParameters - DataSelection, Structure - A sample of data or a Structure with the fields "Nomenclature, Characteristic, Warehouse".
//	RecordingWhenUpdatingInformationSecurity - Boolean - 
//
// Returns:
//	CatalogRef.InventoryLocationAttributeKeys - The created directory element.
//
Function CreateAnalyticsKey(AnalyticsParameters, RecordingWhenUpdatingInformationSecurity = False) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(AnalyticsParameters.ProductsInSet) Then
		RecordSet = GetRecordSet(AnalyticsParameters);
		
		If RecordSet <> Undefined Then // Creating a new analytics key.
			
			BeginTransaction();
			Try
				
				SetRow = RecordSet[0];
				
				CatalogObject = Catalogs.KeysOfSetAccountingDimension.CreateItem();
				CatalogObject.Description = DimensionKeyName(SetRow);
				FillPropertyValues(CatalogObject, AnalyticsParameters, "ProductsInSet, ItemVariantOfSet");
				If RecordingWhenUpdatingInformationSecurity Then
					InfobaseUpdate.WriteObject(CatalogObject);
				Else
					CatalogObject.Write();
				EndIf;
				
				Result = CatalogObject.Ref;
				
				SetRow.DimensionKey = Result;
				If RecordingWhenUpdatingInformationSecurity Then
					InfobaseUpdate.WriteRecordSet(RecordSet, False, True);
				Else
					RecordSet.Write(False);
				EndIf;
				
				CommitTransaction();
			Except
				// during key initialization, this key has already been created in the IB by another session.
				RecordSet.Read();
				If RecordSet.Count() = 0 Then // the record was not created due to an error filling in the fields.
					RollbackTransaction();
					Raise;
				Else
					RollbackTransaction();
					Result = RecordSet[0].DimensionKey;
				EndIf;
			EndTry;
			
			Return Result;
			
		EndIf;
	EndIf;
	
EndFunction

// Populates the field of Analyticaanacon in the collection containing the item, description.
//
// Parameters:
//
//	Collection - TabularSection
//
Procedure FillInCollection(Collection) Export
	
	SetPrivilegedMode(True);
	
	FieldsNames = DefaultCollectionFieldNames();
	If True Then QueryText = "
		|SELECT
		|	Collection.LineNumber - 1 AS IndexOf,
		|	&AnalyticsField AS SetAccountingDimension,
		|	&ProductsField AS ProductsInSet,
		|	&CharacteristicField AS ItemVariantOfSet
		|
		|INTO Collection
		|FROM &Collection AS Collection;
		|
		|SELECT
		|	Collection.IndexOf,
		|	Dimension.DimensionKey AS SetAccountingDimension,
		|	Collection.ProductsInSet,
		|	Collection.ItemVariantOfSet
		|FROM
		|	Collection AS Collection
		|	INNER JOIN Catalog.Products AS SN
		|		ON SN.Ref = Collection.ProductsInSet
		|	LEFT JOIN InformationRegister.SetAccountingDimension AS Dimension
		|		ON Dimension.ProductsInSet = Collection.ProductsInSet AND Dimension.ItemVariantOfSet = Collection.ItemVariantOfSet
		|WHERE
		|	Dimension.DimensionKey IS NULL OR Dimension.DimensionKey <> Collection.SetAccountingDimension
		|";
	EndIf;
	
	// replace the substituted fields from the field name structure in the query text
	QueryText = StrReplace(QueryText, "&AnalyticsField", "Collection." + FieldsNames.SetAccountingDimension);
	QueryText = StrReplace(QueryText, "&ProductsField", "Collection." + FieldsNames.ProductsInSet);
	QueryText = StrReplace(QueryText, "&CharacteristicField", "Collection." + FieldsNames.ItemVariantOfSet);
	
	Query = New Query(QueryText);
	Query.SetParameter("Collection", Collection);

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Not ValueIsFilled(Selection.SetAccountingDimension) Then
			DimensionKey = AnalyticsKeyValue(Selection)
		Else
			DimensionKey = Selection.SetAccountingDimension;
		EndIf;
		Collection[Selection.IndexOf][FieldsNames.SetAccountingDimension] = DimensionKey;
	EndDo;
EndProcedure

// Returns the structure of fields for selecting information from the collection for generating item accounting Analytics.
//
// Returns:
//	Structure - contains the real names of the collection fields for obtaining and generating analytics.
//		contains two sections, if the key value is Undefined, then the field name should be taken from the key name.
//		identification section {Nomenclature, Characteristic, analyticscountainment, statusquest, Series},
//			all keys are set.
//		section of the place of accounting {Arbitrary, [Product, Returnable, Service, ] Work}, the keys Arbitrary and Work are set.
//			the details of this section should contain the names of the columns of the collection, from where it is necessary to take values for the same
//			types of nomenclature.
//
Function DefaultCollectionFieldNames() Export
	Return New Structure(
		"ProductsInSet, ItemVariantOfSet, SetAccountingDimension",
		"ProductsInSet", "ItemVariantOfSet", "SetAccountingDimension");
EndFunction

// The function returns the name of the analytics key.
//
// Parameters:
//	RecordManager - InformationRegisterRecordManager.SetAccountingDimension
//                 - CatalogObject.KeysOfSetAccountingDimension - A completed object with the necessary fields to generate the name of the analytics key.
//
// Returns:
//	String
//
Function DimensionKeyName(RecordManager) Export

	// We will get the name of the analytics key in the main language, taking into account the multilingual nature of the directories
	Return TrimAll(Common.ObjectAttributeValue(RecordManager.ProductsInSet, "Description")) + "; " 
		+ ?(ValueIsFilled(RecordManager.ItemVariantOfSet), TrimAll(Common.ObjectAttributeValue(RecordManager.ItemVariantOfSet, "Description")), "");

EndFunction

#EndRegion

#Region Private

#Region Other

Function GetRecordSet(AnalyticsParameters)
	
	// The analytics parameters may not have all the properties
	StructureOfAnalytics = New Structure("ProductsInSet, ItemVariantOfSet");
	FillPropertyValues(StructureOfAnalytics, AnalyticsParameters);
	If Not ValueIsFilled(StructureOfAnalytics.ProductsInSet)
	 And Not ValueIsFilled(StructureOfAnalytics.ItemVariantOfSet) Then
		Return Undefined
	Else
		RecordSet = InformationRegisters.SetAccountingDimension.CreateRecordSet();
		
		For Each KeyValue In StructureOfAnalytics Do
			FilterElement = RecordSet.Filter[KeyValue.Key]; // FilterItem
			FilterElement.Set(KeyValue.Value);
		EndDo;
		
		NewRow = RecordSet.Add();
		
		FillPropertyValues(NewRow, StructureOfAnalytics, "ProductsInSet, ItemVariantOfSet");
		Return RecordSet;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf