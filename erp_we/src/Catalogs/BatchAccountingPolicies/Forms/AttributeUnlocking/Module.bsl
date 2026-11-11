#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
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

	Close(Result);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion
