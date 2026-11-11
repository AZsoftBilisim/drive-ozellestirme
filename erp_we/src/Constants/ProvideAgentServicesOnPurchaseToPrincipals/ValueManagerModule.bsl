#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.ProvideAgentServicesOnPurchaseToPrincipals.Get();	
	PropertyManager.SetPropertySetParameters("Document_PurchasingReportToConsignorPrincipal", SetParameters);
	
	If ThisObject.Value = True Then
		
		UseSalesOrders = Constants.UseSalesOrders.Get();
		OrderExecutionMode     = Number(Constants.UseAdvancedFeaturesOfSalesOrder.Get())
			+ Number(Constants.UseShipmentByRowsInSalesOrder.Get());
		
		YouCanUseOrderSeparation = UseSalesOrders
			And Constants.UseOrderSupplyWithAssignment.Get()
			And OrderExecutionMode = 2;

		If Not YouCanUseOrderSeparation Then
			Constants.OptionOfGoodsAssignmentInSales.Set(Enums.OptionsOfGoodsAssignmentInSales.Contract);
		EndIf;
		
	Else
		
		CurSeparationOption                    = Constants.OptionOfGoodsAssignmentInSales.Get();
		UseSalesOrders                   = Constants.UseSalesOrders.Get();
		UseRequestsForReturnOfGoodsFromCustomers = Constants.UseRequestsForReturnOfGoodsFromCustomers.Get();
		
		If CurSeparationOption = Enums.OptionsOfGoodsAssignmentInSales.Contract Then
			
			If UseSalesOrders 
				Or UseRequestsForReturnOfGoodsFromCustomers Then
				Constants.OptionOfGoodsAssignmentInSales.Set(Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);
			Else
				Constants.OptionOfGoodsAssignmentInSales.Set(Enums.OptionsOfGoodsAssignmentInSales.EmptyRef());
			EndIf;
			
		ElsIf Not (UseSalesOrders Or UseRequestsForReturnOfGoodsFromCustomers)
					And Not CurSeparationOption = Enums.OptionsOfGoodsAssignmentInSales.EmptyRef() Then
			Constants.OptionOfGoodsAssignmentInSales.Set(Enums.OptionsOfGoodsAssignmentInSales.EmptyRef());
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
