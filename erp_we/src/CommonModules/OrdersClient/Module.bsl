#Region Public

// Fills in the service details "Divergence of orders" in the line
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed row
//  FillParameters  - See OrdersClientServer.FillInParametersFlagDiscrepancyOrder
//  CachedValues - Structure - stored values of parameters used in processing
//
Procedure FillInDiscrepancyAttributeOrder(CurrentRow, FillParameters, CachedValues) Export

	If Not FillParameters.ByOrders Then
		Return;
	EndIf;

	CurrentRow.OrderDiscrepancy_3 = ?(CurrentRow.RowCode = 0, 1, 0);
	
EndProcedure

#EndRegion