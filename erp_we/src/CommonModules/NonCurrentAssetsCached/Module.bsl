#Region Public

// IDs of documents for which the cost is calculated.
// 
// Returns:
//  Array of CatalogRef.MetadataObjectIDs -  Document IDs
Function IdsOfDocumentsForWhichCostIsCalculated() Export
	
	TypesList = FACostCalculation.TypesOfDocumentsForWhichCostIsCalculated(False);
	
	ListOfObjects = New Array;
	For Each ObjectType In TypesList Do
		ListOfObjects.Add(Common.MetadataObjectID(ObjectType));
	EndDo; 
	
	Return ListOfObjects;
	
EndFunction

// IDs of documents for which deferred Register Records are generated.
// 
// Returns:
//  Array of CatalogRef.MetadataObjectIDs - Document IDs
Function IdsOfDocumentsForGeneratingDeferredTraffic() Export

	TypesList = New Array;
	
	// FA
	TypesList.Add(Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4"));
	TypesList.Add(Type("DocumentRef.FixedAssetCostAndDepreciationAdjustment"));
	TypesList.Add(Type("DocumentRef.FixedAssetsCostAdditions2_4"));
	TypesList.Add(Type("DocumentRef.MergeOfFixedAssets"));
	TypesList.Add(Type("DocumentRef.AllocateVariancesToFixedAssetCost"));
	TypesList.Add(Type("DocumentRef.FATransfer2_4"));
	TypesList.Add(Type("DocumentRef.FARevaluation2_4"));
	TypesList.Add(Type("DocumentRef.PreparingForFixedAssetSale2_4"));
	TypesList.Add(Type("DocumentRef.SplitFixedAssets"));
	TypesList.Add(Type("DocumentRef.DisposeFixedAssets2_4"));

	// IA
	TypesList.Add(Type("DocumentRef.ChangeIntangibleAssetFinancialDetails2_4"));
	TypesList.Add(Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment"));
	TypesList.Add(Type("DocumentRef.IATransfer2_4"));
	TypesList.Add(Type("DocumentRef.IARevaluation2_4"));
	TypesList.Add(Type("DocumentRef.PreparingForIntangibleAssetSale2_4"));
	TypesList.Add(Type("DocumentRef.DisposeIntangibleAssets2_4"));
	TypesList.Add(Type("DocumentRef.IntangibleAssetImprovement"));
	
	// Lease
	TypesList.Add(Type("DocumentRef.ReturnAssetsFromLeasee2_4"));
	TypesList.Add(Type("DocumentRef.ReturnLeasedAssets"));
	TypesList.Add(Type("DocumentRef.VendorInvoiceLeasedAssets"));
	TypesList.Add(Type("DocumentRef.LeaseTermAdjustment"));
	TypesList.Add(Type("DocumentRef.ProvideAssetsToLeasee2_4"));
	TypesList.Add(Type("DocumentRef.LeaseTermination"));
	
	// Other
	TypesList.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
	TypesList.Add(Type("DocumentRef.FutureExpenseCommitmentsAccrualWriteOff"));
	
	ListOfObjects = New Array;
	For Each ObjectType In TypesList Do
		ListOfObjects.Add(Common.MetadataObjectID(ObjectType));
	EndDo; 
	
	DeferredFARecordGenerationLocalization.AddIdsOfDocumentsThatAreUsedForGeneratingDeferredTraffic(ListOfObjects);
	
	Return ListOfObjects;

EndFunction

#EndRegion

