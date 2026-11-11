#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Returns accounting sections that are off-balance sheet.
// 
// Returns:
//  Array of EnumRef.SectionsOfInventoryCostAccounting - Off-Balance Sheet Accounting Sections
//
Function OffBalanceSheetAccountingSections() Export
	
	OffBalanceSheetAccountingSections = New Array;
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingToRegisterWriteOff);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	OffBalanceSheetAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners);
	Return OffBalanceSheetAccountingSections;
	
EndFunction

// Returns accounting sections that relate to balance sheets.
// 
// Returns:
//  Array of EnumRef.SectionsOfInventoryCostAccounting - Balance Sections Of Accounting
//
Function BalanceSectionsOfAccounting() Export
	
	BalanceSectionsOfAccounting = New Array;
	OffBalanceSheetAccountingSections = OffBalanceSheetAccountingSections();
	
	For Each MetaValue In Metadata.Enums.SectionsOfInventoryCostAccounting.EnumValues Do
		
		CurrentValue = Enums.SectionsOfInventoryCostAccounting[MetaValue.Name];
		
		If OffBalanceSheetAccountingSections.Find(CurrentValue) = Undefined Then
			BalanceSectionsOfAccounting.Add(CurrentValue);
		EndIf;
		
	EndDo;
	
	Return BalanceSectionsOfAccounting;
	
EndFunction

#EndRegion

#EndIf