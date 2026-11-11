
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Object.Predefined Then
		ExceptionText = NStr("vi = 'Đây là chính sách ghi nhận sê-ri, cấm chỉnh sửa.';
							|ru = 'Это служебная политика учета серий, редактирование запрещено.';
							|en = 'This is service policy of batch accounting, editing is prohibited.'; fa = 'This is service policy of batch accounting, editing is prohibited.';
							|it = 'Questa è una politica di servizio delle serie contabili, la modifica è vietata.';
							|pl = 'To jest serwisowa polityka ewidencji serii, edycja jest zabroniona.';
							|tr = 'Bu özel toplu muhasebe politikası, düzenleme yasak'");
		Raise ExceptionText;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		If Not ValueIsFilled(Object.PolicyType)
			And Not GetFunctionalOption("UseWarehouseManagementSystem") Then
			Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification;
		EndIf;
		
		TypeOfPolicyWhenChangingOnServer();
		SetSettingWhenReadingCreating();
	Else
		Items.SetupOfSeriesIndicationOnShipment.ReadOnly = True;
	EndIf;
	ProductionSettings = ProductionServer.SubsystemSettingsProduction();
	FillPropertyValues(ThisObject, ProductionSettings, "ProductionIsUsed21, ProductionIsUsed22");
	If ProductionIsUsed21 Then
		
		If GetFunctionalOption("ComplexAutomation") Then
			Items.SpecifyDuringProduction.Visible = False;
			Items.SpecifyOnMaterialConsumption.Visible = False;
		Else
			Items.SpecifyOnShipmentForInternalNeeds.Title = NStr("vi = 'cho sản xuất, nhu cầu nội bộ';
																|ru = 'в производство, на внутренние нужды';
																|en = 'to production, for internal needs'; fa = 'to production, for internal needs';
																|it = 'in produzione, per esigenze interne';
																|pl = 'do produkcji, na potrzeby wewnętrzne';
																|tr = 'üretime, iç gereksinimlere'");
		EndIf;
		
		If ProductionIsUsed22 Then
			Items.SpecifyDuringProduction.Title = NStr("vi = 'khi nhập sản phẩm đầu ra vào tờ lộ trình và giai đoạn sản xuất';
														|ru = 'при вводе выходных изделий в маршрутных листах и этапах производства';
														|en = 'when adding product to operation sheets and production stages'; fa = 'when adding product to operation sheets and production stages';
														|it = 'all''immissione di prodotti in uscita nei fogli di lavorazione e nelle fasi di produzione';
														|pl = 'przy wprowadzaniu wyrobów wyjściowych w listach przewozowych i etapach produkcji';
														|tr = 'işlem listelerinde ve üretim aşamalarında üretilen nihai ürünlerin girişi sırasında'");
		Else
			Items.SpecifyDuringProduction.Title = NStr("vi = 'khi nhập các sản phẩm trong tờ lộ trình';
														|ru = 'при вводе выходных изделий в маршрутных листах';
														|en = 'when adding product to operation sheets'; fa = 'when adding product to operation sheets';
														|it = 'all''immissione di prodotti in uscita nei fogli di lavorazione';
														|pl = 'przy wprowadzaniu wyrobów wyjściowych w listach przewozowych';
														|tr = 'üretilen nihai ürünleri işlem listesine girerken'");
		EndIf;
		
	Else
		
		If ProductionIsUsed22 Then
			Items.SpecifyDuringProduction.Title = NStr("vi = 'khi xuất xưởng sản phẩm';
														|ru = 'при выпуске продукции';
														|en = 'On product release'; fa = 'On product release';
														|it = 'al rilascio della produzione';
														|pl = 'przy wypuszczaniu produkcji';
														|tr = 'imal edilen ürün üretimi sırasında'");
		EndIf;
		
		Items.TheDecorationIsIndicatedWhenMovingMaterials1.Visible = False;
		Items.TheDecorationIsIndicatedWhenMovingMaterials2.Visible = False;
		
	EndIf;
	
	Items.BatchesAccountingInUninvoicedGoodsDeliveries.Visible =
		GetFunctionalOption("UseUninvoicedDeliveries");
	Items.BatchesAccountingOfGoodsInTransitFromVendor.Visible =
		GetFunctionalOption("UseGoodsInTransitFromVendors");
	Items.BatchesAccountingInDepositedGoods.Visible =
		GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	
	Items.SeriesAccountingOfGoodsTransferredToSubcontractor.Visible = False;
	Items.SeriesAccountingOfGoodsTransferredToSubcontractor.Visible =
		GetFunctionalOption("UseProductionByThirdParty2_5");
	Items.AccountingOfBatchesInGoodsTransferredToCommissionAgent.Visible = GetFunctionalOption("UseSalesCommission")
																And GetFunctionalOption("UseCustomerContracts");
	Items.AccountingForGoodsBatchesShippedToCustomer.Visible =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
		
	Items.SpecifyWhenRepairingProducts.Visible = False;
	Items.SpecifyWhenRepairingProducts.Visible = GetFunctionalOption("DynamicStructureOfProductionOrders");
	FillInListOfPolicyTypes();
	ConfigureFormElementsOnServer();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	SetSettingWhenReadingCreating();

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	Object.SpecifyWhenPlanningShipment = (SetupOfSeriesIndicationOnShipment = "WhilePlanningShipment");
	Object.SpecifyWhenPlanningPicking   = (SetupOfSeriesIndicationOnShipment = "WhilePlanningPicking");
	Object.SpecifyByPickingResult           = (SetupOfSeriesIndicationOnShipment = "ByPickingResult");
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PolicyTypeOnChange(Item)
	
	TypeOfPolicyWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure SpecifyOnReceivingOnChange(Item)
	If Not Object.SpecifyOnReceiving Then
		
		Object.SpecifyWhenReceivingComponentsAfterDisassembly    = False;
		Object.SpecifyOnReceivingFromVendor                  = False;
		Object.SpecifyOnReceivingByReturnFromCustomer           = False;
		Object.SpecifyOnReturnOfGoodsNotAcceptedByRecipient = False;
		Object.SpecifyOnReceivingByTransfer                 = False;
		Object.SpecifyOnReceivingByOtherRecordingAsReceived        = False;
		Object.SpecifyWhenReceivingAssembledKits           = False;
		Object.SpecifyWhenReceivingProductsFromManufacturing       = False;
		
	EndIf;
	
	ConfigureFormElementsOnServer();
EndProcedure

&AtClient
Procedure SpecifyOnShipmentOnChange(Item)
	If Not Object.SpecifyOnShipment Then
		
		Object.SpecifyOnShipmentToCustomer                = False;
		Object.SpecifyOnRetailShipment               = False;
		Object.SpecifyWhenShippingKitsForDisassembly  = False;
		Object.SpecifyWhenShippingComponentsForAssembly = False;
		Object.SpecifyOnShipmentForInternalNeeds      = False;
		Object.SpecifyOnShipmentByReturnToVendor   = False;
		Object.SpecifyOnShipmentByTransfer          = False;
		
		SetupOfSeriesIndicationOnShipment = "";
	Else
		SetupOfSeriesIndicationOnShipment = "ByPickingResult";
	EndIf;
	
	ConfigureFormElementsOnServer();
EndProcedure

&AtClient
Procedure SpecifyWhenMovingMaterialsOnChange(Item)
	
	If Not Object.SpecifyWhenMovingMaterials Then
		
		Object.SpecifyWhenReceivingMaterials = False;
		Object.SpecifyOnReturnToWarehouse = False;
		Object.SpecifyOnMaterialConsumption = False;
		Object.SpecifyUponAllocatingCostsToProductionLots = False;
		
	EndIf;
	
	ConfigureFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure SpecifyWhenMovingProductsOnChange(Item)
	
	If Not Object.SpecifyWhenMovingProducts Then
		
		Object.SpecifyDuringProduction = False;
		Object.SpecifyOnProductionIssueToBusinessUnit = False;
		
	EndIf;
	
	ConfigureFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure SpecifyOnMaterialConsumptionOnChange(Item)
	
	If Not ProductionIsUsed21 And ProductionIsUsed22 Then
		
		Object.SpecifyWhenMovingMaterials = Object.SpecifyOnMaterialConsumption;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifyDuringProductionOnChange(Item)
	
	If Not ProductionIsUsed21 And ProductionIsUsed22 Then
		
		Object.SpecifyWhenMovingProducts = Object.SpecifyDuringProduction;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.BatchAccountingPolicies.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array")
		And Result.Count() > 0 Then
		
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
		
		Items.SetupOfSeriesIndicationOnShipment.ReadOnly = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetSettingWhenReadingCreating()
	
	If Object.SpecifyWhenPlanningShipment Then
		SetupOfSeriesIndicationOnShipment = "WhilePlanningShipment";
	ElsIf Object.SpecifyWhenPlanningPicking Then
		SetupOfSeriesIndicationOnShipment = "WhilePlanningPicking";
	ElsIf Object.SpecifyByPickingResult Then
		SetupOfSeriesIndicationOnShipment = "ByPickingResult";
	EndIf;
	
	ConfigureFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsOnServer()
	
	UseWarehouseManagemantSystemForGoodsSurplusesShortages = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsSurplusesShortages");
	UsedProduction22Without21 = ProductionIsUsed22 And Not ProductionIsUsed21;
	
	If Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification Then
		Items.GroupInOperation.Title = NStr("vi = 'Đang hoạt động (quản lý số dư sê-ri)';
											|ru = 'В эксплуатации (управление остатками серий)';
											|en = 'In operation (batch balance management)'; fa = 'In operation (batch balance management)';
											|it = 'In utilizzo (gestione saldi delle serie)';
											|pl = 'W eksploatacji (zarządzanie zapasami serii)';
											|tr = 'Kullanımda (parti bakiye yönetimi)'");
	Else
		Items.GroupInOperation.Title = NStr("vi = 'Đang sử dụng';
											|ru = 'В эксплуатации';
											|en = 'In operation'; fa = 'در حال بهره‌برداری';
											|it = 'In esercizio';
											|pl = 'W eksploatacji';
											|tr = 'Kullanımda'");
	EndIf;
	If Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification Then
		
		Items.SpecifyOnReceivingByReturnFromCustomer.Enabled           = Object.SpecifyOnReceiving;
		Items.SpecifyOnReturnOfGoodsNotAcceptedByRecipient.Enabled = Object.SpecifyOnReceiving;
		Items.SpecifyOnReceivingFromVendor.Enabled                  = Object.SpecifyOnReceiving;
		Items.SpecifyOnReceivingByTransfer.Enabled                 = Object.SpecifyOnReceiving;
		Items.SpecifyWhenReceivingAssembledKits.Enabled           = Object.SpecifyOnReceiving;
		Items.SpecifyWhenReceivingComponentsAfterDisassembly.Enabled    = Object.SpecifyOnReceiving;
		Items.SpecifyOnReceivingByOtherRecordingAsReceived.Enabled        = Object.SpecifyOnReceiving;
		Items.SpecifyWhenReceivingProductsFromManufacturing.Enabled       = Object.SpecifyOnReceiving;
		
		Items.SpecifyOnShipmentToCustomer.Enabled                = Object.SpecifyOnShipment;
		Items.SpecifyOnRetailShipment.Enabled               = Object.SpecifyOnShipment;
		Items.SpecifyWhenShippingComponentsForAssembly.Enabled = Object.SpecifyOnShipment;
		Items.SpecifyOnShipmentForInternalNeeds.Enabled      = Object.SpecifyOnShipment;
		Items.SpecifyOnShipmentByReturnToVendor.Enabled   = Object.SpecifyOnShipment;
		Items.SpecifyOnShipmentByTransfer.Enabled          = Object.SpecifyOnShipment;
		Items.SpecifyWhenShippingKitsForDisassembly.Enabled  = Object.SpecifyOnShipment;
		
		Items.SpecifyWhenRecordingSurpluses.Enabled              = UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		Items.SpecifyUponTransferBetweenWarerooms.Enabled    = True;
		Items.SpecifyOnReceiving.Enabled                        = True;
		Items.SpecifyOnShipment.Enabled                       = True;
		Items.SetupOfSeriesIndicationOnShipment.Enabled          = False;
		Items.SpecifyWhenMovingMaterials.Enabled             = True;
		Items.SpecifyWhenReceivingMaterials.Enabled            = Object.SpecifyWhenMovingMaterials;
		Items.SpecifyOnReturnToWarehouse.Enabled                = Object.SpecifyWhenMovingMaterials;
		Items.SpecifyOnMaterialConsumption.Enabled              = Object.SpecifyWhenMovingMaterials Or UsedProduction22Without21;
		Items.SpecifyUponAllocatingCostsToProductionLots.Enabled  = Object.SpecifyWhenMovingMaterials;
		
		Items.SpecifyWhenMovingProducts.Enabled              = True;
		Items.SpecifyDuringProduction.Enabled          = Object.SpecifyWhenMovingProducts Or UsedProduction22Without21;
		Items.SpecifyOnProductionIssueToBusinessUnit.Enabled          = Object.SpecifyWhenMovingProducts;
		
		Items.TheGroupTakesIntoAccountTheSeriesInProduction.Title = NStr("vi = 'Đang sản xuất';
																		|ru = 'В производстве';
																		|en = 'In production'; fa = 'In production';
																		|it = 'In produzione';
																		|pl = 'W produkcji';
																		|tr = 'Üretimde'");
		
		Items.SeriesAccountingOfGoodsTransferredToSubcontractor.Enabled = False;
		Items.BatchesAccountingInDepositedGoods.Enabled       = False;
		Items.AccountingOfBatchesInGoodsTransferredToCommissionAgent.Enabled       = False;
		Items.AccountingForGoodsBatchesShippedToCustomer.Enabled          = False;
		Items.BatchesAccountingInUninvoicedGoodsDeliveries.Enabled = False;
		Items.BatchesAccountingOfGoodsInTransitFromVendor.Enabled        = False;
		
	ElsIf Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.FEFOAutoCalculationOfRemainingBatch Then
		
		Items.SpecifyOnReceivingByReturnFromCustomer.Enabled           = False;
		Items.SpecifyOnReturnOfGoodsNotAcceptedByRecipient.Enabled = False;
		Items.SpecifyOnReceivingFromVendor.Enabled                  = False;
		Items.SpecifyOnReceivingByTransfer.Enabled                 = False;
		Items.SpecifyWhenReceivingAssembledKits.Enabled           = False;
		Items.SpecifyWhenReceivingComponentsAfterDisassembly.Enabled    = False;
		Items.SpecifyOnReceivingByOtherRecordingAsReceived.Enabled        = False;
		Items.SpecifyWhenReceivingProductsFromManufacturing.Enabled       = False;
		
		Items.SpecifyOnShipmentToCustomer.Enabled                = False;
		Items.SpecifyOnRetailShipment.Enabled               = False;
		Items.SpecifyWhenShippingComponentsForAssembly.Enabled = False;
		Items.SpecifyOnShipmentForInternalNeeds.Enabled      = False;
		Items.SpecifyOnShipmentByReturnToVendor.Enabled   = False;
		Items.SpecifyOnShipmentByTransfer.Enabled          = False;
		Items.SpecifyWhenShippingKitsForDisassembly.Enabled  = False;
		
		Items.SpecifyWhenRecordingSurpluses.Enabled              = False;
		Items.SpecifyUponTransferBetweenWarerooms.Enabled    = False;
		Items.SpecifyOnReceiving.Enabled                        = False;
		Items.SpecifyOnShipment.Enabled                       = False;
		Items.SetupOfSeriesIndicationOnShipment.Enabled          = False;
		Items.SpecifyWhenMovingMaterials.Enabled             = False;
		Items.SpecifyWhenReceivingMaterials.Enabled            = False;
		Items.SpecifyOnReturnToWarehouse.Enabled                = False;
		Items.SpecifyOnMaterialConsumption.Enabled              = UsedProduction22Without21;
		Items.SpecifyUponAllocatingCostsToProductionLots.Enabled  = False;
		
		Items.SpecifyWhenMovingProducts.Enabled              = False;
		Items.SpecifyDuringProduction.Enabled          = True;
		Items.SpecifyOnProductionIssueToBusinessUnit.Enabled          = False;
		
		If UsedProduction22Without21 Then
			Items.TheGroupTakesIntoAccountTheSeriesInProduction.Title = NStr("vi = 'Đang sản xuất (tham khảo)';
																			|ru = 'В производстве (справочное указание)';
																			|en = 'In production (reference specification)'; fa = 'In production (reference specification)';
																			|it = 'In produzione (riferimento)';
																			|pl = 'W produkcji (określenie informacyjne)';
																			|tr = 'Üretimde (referans belirtme)'");
		Else
			Items.TheGroupTakesIntoAccountTheSeriesInProduction.Title = NStr("vi = 'Đang sản xuất';
																			|ru = 'В производстве';
																			|en = 'In production'; fa = 'In production';
																			|it = 'In produzione';
																			|pl = 'W produkcji';
																			|tr = 'Üretimde'");
		EndIf;
		
		Items.SeriesAccountingOfGoodsTransferredToSubcontractor.Enabled = False;
		Items.BatchesAccountingInDepositedGoods.Enabled       = False;
		Items.AccountingOfBatchesInGoodsTransferredToCommissionAgent.Enabled       = False;
		Items.AccountingForGoodsBatchesShippedToCustomer.Enabled          = False;
		Items.BatchesAccountingInUninvoicedGoodsDeliveries.Enabled = False;
		Items.BatchesAccountingOfGoodsInTransitFromVendor.Enabled        = False;
		
	ElsIf Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.BatchesBalancesManagement
		Or Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.BatchesBalancesFEFOManagement Then
		
		Items.SpecifyOnReceivingByReturnFromCustomer.Enabled           = False;
		Items.SpecifyOnReturnOfGoodsNotAcceptedByRecipient.Enabled = False;
		Items.SpecifyOnReceivingFromVendor.Enabled                  = False;
		Items.SpecifyOnReceivingByTransfer.Enabled                 = False;
		Items.SpecifyWhenReceivingAssembledKits.Enabled           = False;
		Items.SpecifyWhenReceivingComponentsAfterDisassembly.Enabled    = False;
		Items.SpecifyOnReceivingByOtherRecordingAsReceived.Enabled        = False;
		Items.SpecifyWhenReceivingProductsFromManufacturing.Enabled       = False;
		
		Items.SpecifyOnShipmentToCustomer.Enabled                = False;
		Items.SpecifyOnRetailShipment.Enabled               = False;
		Items.SpecifyWhenShippingComponentsForAssembly.Enabled = False;
		Items.SpecifyOnShipmentForInternalNeeds.Enabled      = False;
		Items.SpecifyOnShipmentByReturnToVendor.Enabled   = False;
		Items.SpecifyOnShipmentByTransfer.Enabled          = False;
		Items.SpecifyWhenShippingKitsForDisassembly.Enabled  = False;
		
		Items.SpecifyWhenRecordingSurpluses.Enabled              = False;
		Items.SpecifyUponTransferBetweenWarerooms.Enabled    = False;
		Items.SpecifyOnReceiving.Enabled                        = False;
		Items.SpecifyOnShipment.Enabled                       = False;
		
		Items.SetupOfSeriesIndicationOnShipment.Enabled =
			(Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.BatchesBalancesManagement);
		Items.SpecifyWhenMovingMaterials.Enabled             = False;
		Items.SpecifyWhenReceivingMaterials.Enabled            = False;
		Items.SpecifyOnReturnToWarehouse.Enabled                = False;
		Items.SpecifyOnMaterialConsumption.Enabled              = UsedProduction22Without21;
		Items.SpecifyUponAllocatingCostsToProductionLots.Enabled  = False;
		
		Items.SpecifyWhenMovingProducts.Enabled              = False;
		Items.SpecifyDuringProduction.Enabled          = True;
		Items.SpecifyOnProductionIssueToBusinessUnit.Enabled          = False;
		
		If UsedProduction22Without21 Then
			Items.TheGroupTakesIntoAccountTheSeriesInProduction.Title = NStr("vi = 'Đang sản xuất (tham khảo)';
																			|ru = 'В производстве (справочное указание)';
																			|en = 'In production (reference specification)'; fa = 'In production (reference specification)';
																			|it = 'In produzione (riferimento)';
																			|pl = 'W produkcji (określenie informacyjne)';
																			|tr = 'Üretimde (referans belirtme)'");
		Else
			Items.TheGroupTakesIntoAccountTheSeriesInProduction.Title = NStr("vi = 'Đang sản xuất';
																			|ru = 'В производстве';
																			|en = 'In production'; fa = 'In production';
																			|it = 'In produzione';
																			|pl = 'W produkcji';
																			|tr = 'Üretimde'");
		EndIf;
		
		Items.SeriesAccountingOfGoodsTransferredToSubcontractor.Enabled = False;
		Items.BatchesAccountingInDepositedGoods.Enabled       = False;
		Items.AccountingOfBatchesInGoodsTransferredToCommissionAgent.Enabled       = False;
		Items.AccountingForGoodsBatchesShippedToCustomer.Enabled          = False;
		Items.BatchesAccountingInUninvoicedGoodsDeliveries.Enabled = False;
		Items.BatchesAccountingOfGoodsInTransitFromVendor.Enabled        = False;
		
	ElsIf Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.CostAccountingByBatches Then
		
		Items.SpecifyOnReceivingByReturnFromCustomer.Enabled           = False;
		Items.SpecifyOnReturnOfGoodsNotAcceptedByRecipient.Enabled = False;
		Items.SpecifyOnReceivingFromVendor.Enabled                  = False;
		Items.SpecifyOnReceivingByTransfer.Enabled                 = False;
		Items.SpecifyWhenReceivingAssembledKits.Enabled           = False;
		Items.SpecifyWhenReceivingComponentsAfterDisassembly.Enabled    = False;
		Items.SpecifyOnReceivingByOtherRecordingAsReceived.Enabled        = False;
		Items.SpecifyWhenReceivingProductsFromManufacturing.Enabled       = False;
		
		Items.SpecifyOnShipmentToCustomer.Enabled                = False;
		Items.SpecifyOnRetailShipment.Enabled               = False;
		Items.SpecifyWhenShippingComponentsForAssembly.Enabled = False;
		Items.SpecifyOnShipmentForInternalNeeds.Enabled      = False;
		Items.SpecifyOnShipmentByReturnToVendor.Enabled   = False;
		Items.SpecifyOnShipmentByTransfer.Enabled          = False;
		Items.SpecifyWhenShippingKitsForDisassembly.Enabled  = False;
		
		Items.SpecifyWhenRecordingSurpluses.Enabled              = False;
		Items.SpecifyUponTransferBetweenWarerooms.Enabled    = False;
		Items.SpecifyOnReceiving.Enabled                        = False;
		Items.SpecifyOnShipment.Enabled                       = False;
		
		Items.SetupOfSeriesIndicationOnShipment.Enabled          = False;
		Items.SpecifyWhenMovingMaterials.Enabled             = False;
		Items.SpecifyWhenReceivingMaterials.Enabled            = False;
		Items.SpecifyOnReturnToWarehouse.Enabled                = False;
		Items.SpecifyOnMaterialConsumption.Enabled              = False;
		Items.SpecifyUponAllocatingCostsToProductionLots.Enabled  = False;
		
		Items.SpecifyWhenMovingProducts.Enabled              = False;
		Items.SpecifyDuringProduction.Enabled          = Not ProductionIsUsed22;
		Items.SpecifyOnProductionIssueToBusinessUnit.Enabled          = False;
		
		Items.TheGroupTakesIntoAccountTheSeriesInProduction.Title = NStr("vi = 'Đang sản xuất';
																		|ru = 'В производстве';
																		|en = 'In production'; fa = 'In production';
																		|it = 'In produzione';
																		|pl = 'W produkcji';
																		|tr = 'Üretimde'");
		
		Items.SeriesAccountingOfGoodsTransferredToSubcontractor.Enabled = True;
		Items.BatchesAccountingInDepositedGoods.Enabled       = True;
		Items.AccountingOfBatchesInGoodsTransferredToCommissionAgent.Enabled       = True;
		Items.AccountingForGoodsBatchesShippedToCustomer.Enabled          = True;
		Items.BatchesAccountingInUninvoicedGoodsDeliveries.Enabled = True;
		Items.BatchesAccountingOfGoodsInTransitFromVendor.Enabled        = True;
		
	EndIf;
	
	ConfigureFormElementsOnServerLocalization(UseWarehouseManagemantSystemForGoodsSurplusesShortages);
	
EndProcedure

&AtServer
Procedure TypeOfPolicyWhenChangingOnServer()
	
	If Not ValueIsFilled(Object.PolicyType) Then
		Return;
	EndIf;
	
	If Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification Then
		Object.BatchesAccountingByFEFO                = False;
		Object.AccountForRemainingSeries          = False;
		Object.UseCostAccountingByBatches = False;
		
		If Object.SpecifyOnShipment Then
			SetupOfSeriesIndicationOnShipment = "ByPickingResult";
		Else
			SetupOfSeriesIndicationOnShipment = "";
		EndIf;
		
		Object.SpecifyWhenRecountingInventory  = False;
		Object.SpecifyWhenRecordingShortages = False;
		
		Object.BatchesAccountingInUninvoicedGoodsDeliveries = False;
		Object.BatchesAccountingOfGoodsInTransitFromVendor        = False;
		Object.BatchesAccountingInDepositedGoods   = False;
		Object.SeriesAccountingOfGoodsTransferredToSubcontractor = False;
		Object.AccountingOfBatchesInGoodsTransferredToCommissionAgent = False;
		Object.AccountingForGoodsBatchesShippedToCustomer    = False;
		
	ElsIf Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.FEFOAutoCalculationOfRemainingBatch Then
		Object.BatchesAccountingByFEFO                     = False;
		Object.AccountForRemainingSeries               = False;
		Object.UseCostAccountingByBatches = False;
		
		Object.SpecifyOnShipment                       = False;
		Object.SpecifyOnShipmentToCustomer                = False;
		Object.SpecifyOnRetailShipment               = False;
		Object.SpecifyWhenShippingComponentsForAssembly = False;
		Object.SpecifyOnShipmentForInternalNeeds      = False;
		Object.SpecifyOnShipmentByReturnToVendor   = False;
		Object.SpecifyOnShipmentByTransfer          = False;
		Object.SpecifyWhenShippingKitsForDisassembly  = False;
		
		SetupOfSeriesIndicationOnShipment = "";
		
		Object.SpecifyOnReceiving                              = True;
		Object.SpecifyOnReceivingByReturnFromCustomer           = True;
		Object.SpecifyOnReturnOfGoodsNotAcceptedByRecipient = True;
		Object.SpecifyOnReceivingFromVendor                  = True;
		Object.SpecifyOnReceivingByTransfer                 = True;
		Object.SpecifyWhenReceivingAssembledKits           = True;
		Object.SpecifyWhenReceivingComponentsAfterDisassembly    = True;
		Object.SpecifyOnReceivingByOtherRecordingAsReceived        = True;
		Object.SpecifyWhenReceivingProductsFromManufacturing       = True;
		
		Object.SpecifyWhenRecordingSurpluses = True;
		Object.SpecifyWhenRecordingShortages = False;
		Object.SpecifyWhenRecountingInventory  = False;
		
		Object.SpecifyUponTransferBetweenWarerooms = True;
		Object.SpecifyWhenMovingMaterials                      = True;
		Object.SpecifyWhenMovingProducts                       = True;
		Object.SpecifyWhenReceivingMaterials                     = True;
		Object.SpecifyOnReturnToWarehouse                         = False;
		If ProductionIsUsed21 Then
			Object.SpecifyOnMaterialConsumption			       = False;
		EndIf;
		Object.SpecifyUponAllocatingCostsToProductionLots           = False;
		Object.SpecifyOnProductionIssueToBusinessUnit                   = True;
		Object.BatchesAccountingInDepositedGoods               = False;
		Object.SeriesAccountingOfGoodsTransferredToSubcontractor             = False;
		Object.AccountingOfBatchesInGoodsTransferredToCommissionAgent       = False;
		Object.AccountingForGoodsBatchesShippedToCustomer          = False;
		Object.BatchesAccountingInUninvoicedGoodsDeliveries = False;
		Object.BatchesAccountingOfGoodsInTransitFromVendor        = False;
		
	ElsIf Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.BatchesBalancesManagement Then
		Object.BatchesAccountingByFEFO                     = False;
		Object.UseCostAccountingByBatches = False;
		Object.AccountForRemainingSeries               = True;
		
		Object.SpecifyOnShipment                       = True;
		Object.SpecifyOnShipmentToCustomer                = True;
		Object.SpecifyOnRetailShipment               = True;
		Object.SpecifyWhenShippingComponentsForAssembly = True;
		Object.SpecifyOnShipmentForInternalNeeds      = True;
		Object.SpecifyOnShipmentByReturnToVendor   = True;
		Object.SpecifyOnShipmentByTransfer          = True;
		Object.SpecifyWhenShippingKitsForDisassembly  = True;
		
		Object.SpecifyOnReceiving                              = True;
		Object.SpecifyOnReceivingByReturnFromCustomer           = True;
		Object.SpecifyOnReturnOfGoodsNotAcceptedByRecipient = True;
		Object.SpecifyOnReceivingFromVendor                  = True;
		Object.SpecifyOnReceivingByTransfer                 = True;
		Object.SpecifyWhenReceivingAssembledKits           = True;
		Object.SpecifyWhenReceivingComponentsAfterDisassembly    = True;
		Object.SpecifyOnReceivingByOtherRecordingAsReceived        = True;
		Object.SpecifyWhenReceivingProductsFromManufacturing       = True;
		
		Object.SpecifyWhenRecordingSurpluses = True;
		Object.SpecifyWhenRecordingShortages = True;
		Object.SpecifyWhenRecountingInventory  = True;
		
		Object.SpecifyUponTransferBetweenWarerooms = True;
		Object.SpecifyWhenMovingMaterials                      = True;
		Object.SpecifyWhenMovingProducts                       = True;
		Object.SpecifyWhenReceivingMaterials                     = True;
		Object.SpecifyOnReturnToWarehouse                         = True;
		If ProductionIsUsed21 Then
			Object.SpecifyOnMaterialConsumption				   = True;
		EndIf;
		Object.SpecifyUponAllocatingCostsToProductionLots           = True;
		Object.SpecifyOnProductionIssueToBusinessUnit                   = True;
		Object.BatchesAccountingInDepositedGoods               = False;
		Object.SeriesAccountingOfGoodsTransferredToSubcontractor             = False;
		Object.AccountingOfBatchesInGoodsTransferredToCommissionAgent       = False;
		Object.AccountingForGoodsBatchesShippedToCustomer          = False;
		Object.BatchesAccountingInUninvoicedGoodsDeliveries = False;
		Object.BatchesAccountingOfGoodsInTransitFromVendor        = False;
		
	ElsIf Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.BatchesBalancesFEFOManagement Then
		Object.BatchesAccountingByFEFO                     = True;
		Object.UseCostAccountingByBatches = False;
		Object.AccountForRemainingSeries               = True;
		SetupOfSeriesIndicationOnShipment          = "WhilePlanningPicking";
		
		Object.SpecifyOnShipment                       = True;
		Object.SpecifyOnShipmentToCustomer                = True;
		Object.SpecifyOnRetailShipment               = True;
		Object.SpecifyWhenShippingComponentsForAssembly = True;
		Object.SpecifyOnShipmentForInternalNeeds      = True;
		Object.SpecifyOnShipmentByReturnToVendor   = True;
		Object.SpecifyOnShipmentByTransfer          = True;
		Object.SpecifyWhenShippingKitsForDisassembly  = True;
		
		Object.SpecifyOnReceiving                              = True;
		Object.SpecifyOnReceivingByReturnFromCustomer           = True;
		Object.SpecifyOnReturnOfGoodsNotAcceptedByRecipient = True;
		Object.SpecifyOnReceivingFromVendor                  = True;
		Object.SpecifyOnReceivingByTransfer                 = True;
		Object.SpecifyOnReceivingByOtherRecordingAsReceived        = True;
		Object.SpecifyWhenReceivingAssembledKits           = True;
		Object.SpecifyWhenReceivingComponentsAfterDisassembly    = True;
		Object.SpecifyWhenReceivingProductsFromManufacturing       = True;
		
		Object.SpecifyWhenRecordingSurpluses              = True;
		Object.SpecifyWhenRecordingShortages              = True;
		Object.SpecifyWhenRecountingInventory               = True;
		
		Object.SpecifyUponTransferBetweenWarerooms = True;
		Object.SpecifyWhenMovingMaterials                      = True;
		Object.SpecifyWhenMovingProducts                       = True;
		Object.SpecifyWhenReceivingMaterials                     = True;
		Object.SpecifyOnReturnToWarehouse                         = True;
		If ProductionIsUsed21 Then
			Object.SpecifyOnMaterialConsumption				   = True;
		EndIf;
		Object.SpecifyUponAllocatingCostsToProductionLots           = True;
		Object.SpecifyOnProductionIssueToBusinessUnit                   = True;
		Object.BatchesAccountingInDepositedGoods               = False;
		Object.SeriesAccountingOfGoodsTransferredToSubcontractor             = False;
		Object.AccountingOfBatchesInGoodsTransferredToCommissionAgent       = False;
		Object.AccountingForGoodsBatchesShippedToCustomer          = False;
		Object.BatchesAccountingInUninvoicedGoodsDeliveries = False;
		Object.BatchesAccountingOfGoodsInTransitFromVendor        = False;
		
	ElsIf Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.CostAccountingByBatches Then
		Object.BatchesAccountingByFEFO                     = False;
		Object.UseCostAccountingByBatches = True;
		Object.AccountForRemainingSeries               = True;
		SetupOfSeriesIndicationOnShipment          = "WhilePlanningShipment";
		
		Object.SpecifyOnShipment                       = True;
		Object.SpecifyOnShipmentToCustomer                = True;
		Object.SpecifyOnRetailShipment               = True;
		Object.SpecifyWhenShippingComponentsForAssembly = True;
		Object.SpecifyOnShipmentForInternalNeeds      = True;
		Object.SpecifyOnShipmentByReturnToVendor   = True;
		Object.SpecifyOnShipmentByTransfer          = True;
		Object.SpecifyWhenShippingKitsForDisassembly  = True;
		
		Object.SpecifyOnReceiving                              = True;
		Object.SpecifyOnReceivingByReturnFromCustomer           = True;
		Object.SpecifyOnReturnOfGoodsNotAcceptedByRecipient = True;
		Object.SpecifyOnReceivingFromVendor                  = True;
		Object.SpecifyOnReceivingByTransfer                 = True;
		Object.SpecifyOnReceivingByOtherRecordingAsReceived        = True;
		Object.SpecifyWhenReceivingAssembledKits           = True;
		Object.SpecifyWhenReceivingComponentsAfterDisassembly    = True;
		Object.SpecifyWhenReceivingProductsFromManufacturing       = True;
		
		Object.SpecifyWhenRecordingSurpluses              = True;
		Object.SpecifyWhenRecordingShortages              = True;
		Object.SpecifyWhenRecountingInventory               = True;
		
		Object.SpecifyUponTransferBetweenWarerooms = True;
		Object.SpecifyWhenMovingMaterials                      = True;
		Object.SpecifyWhenMovingProducts                       = True;
		Object.SpecifyWhenReceivingMaterials                     = True;
		Object.SpecifyOnReturnToWarehouse                         = True;
		Object.SpecifyOnMaterialConsumption					   = True;
		If ProductionIsUsed22 Then
			Object.SpecifyDuringProduction               = True;
		EndIf;
		Object.SpecifyUponAllocatingCostsToProductionLots           = True;
		Object.SpecifyOnProductionIssueToBusinessUnit                   = True;
		Object.BatchesAccountingInDepositedGoods               = False;
		Object.SeriesAccountingOfGoodsTransferredToSubcontractor             = False;
		Object.AccountingOfBatchesInGoodsTransferredToCommissionAgent       = False;
		Object.AccountingForGoodsBatchesShippedToCustomer          = False;
		Object.BatchesAccountingInUninvoicedGoodsDeliveries = False;
		Object.BatchesAccountingOfGoodsInTransitFromVendor        = False;
		
	EndIf;
	
	TypeOfPolicyWhenChangingOnServerLocalization();
	
	ConfigureFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInListOfPolicyTypes()
	
	PolicyTypeElements = Items.PolicyType.ChoiceList;
	PolicyTypeElements.Clear();
	
	If GetFunctionalOption("BaseVersion") Then
		PolicyTypeElements.Add(Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification);
		
		If Not ValueIsFilled(Object.Ref) Then
			Object.PolicyType = Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification;
			TypeOfPolicyWhenChangingOnServer();
			
			Items.PolicyType.ReadOnly = True;
		ElsIf Object.PolicyType <> Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification Then
			PolicyTypeElements.Add(Object.PolicyType);
		EndIf;
	Else
		GISMSubsystem = Common.SubsystemExists("GosIs.SPMS");
		
		For Each PolicyType In Enums.TypesOfBatchSpecificationPolicies Do
			If GISMSubsystem
				Or PolicyType <> Enums.TypesOfBatchSpecificationPolicies.MarkProductsForSPMS Then
				
				PolicyTypeElements.Add(PolicyType);
				
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region Localization

&AtServer
Procedure ConfigureFormElementsOnServerLocalization(UseWarehouseManagemantSystemForGoodsSurplusesShortages)
	
	
	Return;

EndProcedure

&AtServer
Procedure TypeOfPolicyWhenChangingOnServerLocalization()
	
	
	Return;

EndProcedure

#EndRegion

#EndRegion
