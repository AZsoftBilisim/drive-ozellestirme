
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not TypeOf(Parameters.Filter) = Type("Structure") Then
		Parameters.Filter = New Structure;
	EndIf;
	
	CommonClientServer.SupplementStructure(Parameters.Filter, ProductsServer.SelectionOfSeriesAccountingPoliciesByParameters(Parameters));
	
	OrGroup = CommonClientServer.CreateFilterItemGroup(List.Filter.Items,
		"OrGroup",
		DataCompositionFilterItemsGroupType.OrGroup);
	
	CommonClientServer.SetFilterItem(OrGroup,
			"Predefined",
			True,
			DataCompositionComparisonType.Equal,
			,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	
	AndGroup = CommonClientServer.CreateFilterItemGroup(OrGroup,
		"AndGroup",
		DataCompositionFilterItemsGroupType.AndGroup);
	
	For Each KeyValue In Parameters.Filter Do
		CommonClientServer.SetFilterItem(AndGroup,
			KeyValue.Key,
			KeyValue.Value,
			?(TypeOf(KeyValue.Value) = Type("Array")
				Or TypeOf(KeyValue.Value) = Type("FixedArray"),
					DataCompositionComparisonType.InList,
					DataCompositionComparisonType.Equal),
				,
				True,
				DataCompositionSettingsItemViewMode.Inaccessible);
	EndDo;
	
	Parameters.Filter.Clear();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ThisSelectsACommonPolicyForThisProductType = ValueIsFilled(Parameters.ProductKind);
	AccountingFeature	                     = Parameters.AccountingFeature;
	
	UseUninvoicedDeliveries	= GetFunctionalOption("UseUninvoicedDeliveries");
	UseGoodsInTransitFromVendors 	= GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseTransferToCustodyWithRightOfSale = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	UseProductionByThirdParty2_5	= False;
	UseProductionByThirdParty2_5	= GetFunctionalOption("UseProductionByThirdParty2_5");
	UseSalesCommission			= GetFunctionalOption("UseSalesCommission")
												And GetFunctionalOption("UseCustomerContracts");
	UseShipmentWithDeferredTransferOfTitle2_5 =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
	BaseVersion							= GetFunctionalOption("BaseVersion");
	
	PartnerSSerialTrackingIsUsed = UseUninvoicedDeliveries
										Or UseGoodsInTransitFromVendors
										Or UseTransferToCustodyWithRightOfSale
										Or UseProductionByThirdParty2_5
										Or UseSalesCommission
										Or UseShipmentWithDeferredTransferOfTitle2_5;
	
	Items.DecorationDecodingOfSelection.Visible = PartnerSSerialTrackingIsUsed
													And ThisSelectsACommonPolicyForThisProductType
													And Not BaseVersion;
	
	Items.DecorationRestrictionsOnTheChoiceOfAGeneralPolicyNotAllWarehousesAreOrderedForSurplusShortage.Visible = 
		ThisSelectsACommonPolicyForThisProductType
		And WarehousesServer.ThereAreWarehousesWithoutAnOrderSchemeWhenReflectingSurplusesAndShortages()
		And Not BaseVersion;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationDecodingOfSelectionURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	If Var_URL = "ClearFilter" Then 
		ItemArray = CommonClientServer.FindFilterItemsAndGroups(List.Filter,,"AndGroup");
		
		AndGroup = ItemArray[0];
		
		CommonClientServer.SetFilterItem(AndGroup,
			"BatchesAccountingInUninvoicedGoodsDeliveries",,,,
			False,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
		CommonClientServer.SetFilterItem(AndGroup,
			"BatchesAccountingOfGoodsInTransitFromVendor",,,,
			False,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
		CommonClientServer.SetFilterItem(AndGroup,
			"BatchesAccountingInDepositedGoods",,,,
			False,
			DataCompositionSettingsItemViewMode.Inaccessible);
		CommonClientServer.SetFilterItem(AndGroup,
			"SeriesAccountingOfGoodsTransferredToSubcontractor",,,,
			False,
			DataCompositionSettingsItemViewMode.Inaccessible);
		CommonClientServer.SetFilterItem(AndGroup,
			"AccountingOfBatchesInGoodsTransferredToCommissionAgent",,,,
			False,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
		CommonClientServer.SetFilterItem(AndGroup,
			"AccountingForGoodsBatchesShippedToCustomer",,,,
			False,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
		Items.DecorationDecodingOfSelection.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion