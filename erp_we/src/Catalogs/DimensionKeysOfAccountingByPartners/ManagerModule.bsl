#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
	#Region Public

// Compliance with the list of details that determine the uniqueness of the key
// 
// Returns:
//   Map - the key is the name of the props 
//
Function KeyAttributes() Export
	
	Return TMCommonUse.KeyDetailsOfKeyCatalogForInformationRegister(Metadata.InformationRegisters.AccountingDimensionByPartners);
	
EndFunction

#Region InterfaceImplementation

// Called when replacing duplicates in the Attributes of elements.
//
// Parameters:
//  ReplacementPairs - Map - contains the original and duplicate value pairs.
//  UnprocessedOriginalsValues - Array of Structure:
//    * ValueToReplace - AnyRef - the original value of the object being replaced.
//    * UsedLinks - See Common.SubordinateObjectsLinksByTypes
//    * KeyAttributesValue - Structure - Key - name of the item, value-value of the item.
//
Procedure OnSearchForReferenceReplacement(ReplacementPairs, UnprocessedOriginalsValues) Export

	For Each UnprocessedDuplicate In UnprocessedOriginalsValues Do
		
		ParametersOfKey = New Structure;
		For Each KeyAttribute In UnprocessedDuplicate.KeyAttributesValue Do
			ValueOfOriginal = ReplacementPairs.Get(KeyAttribute.Value);
			ParametersOfKey.Insert(KeyAttribute.Key, ?(ValueOfOriginal = Undefined, KeyAttribute.Value, ValueOfOriginal));
		EndDo;
		
		ReplacementPairs.Insert(
			UnprocessedDuplicate.ValueToReplace,
			InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(ParametersOfKey));
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ReplacingDuplicateAnalyticsKeys

Procedure ReplaceDimensionKeyDuplicates() Export
	
	Query = New Query("
	|SELECT
	|	CatalogData.Ref AS Ref,
	|	CatalogData.DeletionMark AS DeletionMark,
	|	Dimension.DimensionKey AS DimensionKey
	|FROM
	|	Catalog.DimensionKeysOfAccountingByPartners AS CatalogData
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterData
	|	ON
	|		CatalogData.Ref = RegisterData.DimensionKey
	|
	|	INNER JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		CatalogData.Partner = Dimension.Partner
	|		AND CatalogData.Organization = Dimension.Organization
	|		AND CatalogData.Counterparty = Dimension.Counterparty
	|		AND CatalogData.Contract = Dimension.Contract
	|		AND CatalogData.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	RegisterData.DimensionKey IS NULL
	|");
	
	// Let's form the correspondence of the analytics keys.
	ComplianceAnalyst = New Map;
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
	
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ComplianceAnalyst.Insert(Selection.Ref, Selection.DimensionKey);
			
			If Not Selection.DeletionMark Then
				CatalogObject = Selection.Ref.GetObject();
				Try
					CatalogObject.SetDeletionMark(True, False);
				Except
					Raise;
				EndTry;
			EndIf;

		EndDo;
		
		Exceptions = New Array;
		Exceptions.Add(Metadata.InformationRegisters.NumberOfRecordsOfARAPRecorders);
		
		TMCommonUse.ReplaceReferences(ComplianceAnalyst, Exceptions);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf