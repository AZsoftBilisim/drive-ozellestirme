#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("PolicyType");
	
	Result.Add("BatchesAccountingInUninvoicedGoodsDeliveries");
	Result.Add("BatchesAccountingOfGoodsInTransitFromVendor");
	
	Result.Add("SpecifyOnShipment");
	Result.Add("SpecifyOnRetailShipment");
	Result.Add("SpecifyOnShipmentToCustomer");
	Result.Add("SpecifyWhenShippingKitsForDisassembly");
	Result.Add("SpecifyWhenShippingComponentsForAssembly");
	Result.Add("SpecifyOnShipmentForInternalNeeds");
	Result.Add("SpecifyOnShipmentByReturnToVendor");
	Result.Add("SpecifyOnShipmentByTransfer");
	
	Result.Add("SpecifyOnReceiving");
	Result.Add("SpecifyWhenReceivingComponentsAfterDisassembly");
	Result.Add("SpecifyOnReceivingFromVendor");
	Result.Add("SpecifyOnReceivingByReturnFromCustomer");
	Result.Add("SpecifyOnReturnOfGoodsNotAcceptedByRecipient");
	Result.Add("SpecifyOnReceivingByTransfer");
	Result.Add("SpecifyOnReceivingByOtherRecordingAsReceived");
	Result.Add("SpecifyWhenReceivingAssembledKits");
	
	Result.Add("SpecifyWhenRecordingSurpluses");
	Result.Add("SpecifyWhenRecordingShortages");
	Result.Add("SpecifyUponTransferBetweenWarerooms");
	Result.Add("BatchesAccountingInDepositedGoods");
	Result.Add("SpecifyWhenReceivingProductsFromManufacturing");

	Result.Add("SpecifyDuringProduction");
	Result.Add("SpecifyOnMaterialConsumption");

	Result.Add("SpecifyWhenMovingProducts");
	Result.Add("SpecifyWhenMovingMaterials");
	Result.Add("SpecifyWhenReceivingMaterials");
	Result.Add("SpecifyOnReturnToWarehouse");
	Result.Add("SpecifyUponAllocatingCostsToProductionLots");
	Result.Add("SpecifyOnProductionIssueToBusinessUnit");
	
	Result.Add("SeriesAccountingOfGoodsTransferredToSubcontractor");
	
	Result.Add("SeriesAccountingInventoryInOperation");
	Result.Add("SpecifyWhenRepairingProducts");
	Result.Add("AccountingOfBatchesInGoodsTransferredToCommissionAgent");
	Result.Add("AccountingForGoodsBatchesShippedToCustomer");
	
	Return Result;

EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	#Region SeriesAreNotUsed
	Item = Items.Add();
	Item.PredefinedDataName = "SeriesAreNotUsed";
	Item.Description = NStr("vi = 'Sê-ri không được sử dụng';
							|ru = 'Серии не используются';
							|en = 'Batches are not used'; fa = 'Batches are not used';
							|it = 'Serie non vengono utilizzate';
							|pl = 'Serie nie są używane';
							|tr = 'Partiler kullanılmıyor'", Common.DefaultLanguageCode());
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.BatchAccountingPolicies - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductsServerCall.SeriesAccountingPoliciesProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion
#EndIf
