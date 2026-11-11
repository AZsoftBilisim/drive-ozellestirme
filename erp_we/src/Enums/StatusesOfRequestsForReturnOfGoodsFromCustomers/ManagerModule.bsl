#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the status selection list, depending on the enabled options
//
// Parameters:
//  ChoiceData  - ValueList - a list of values to fill in.
//  EstablishedStatus  - EnumRef.StatusesOfRequestsForReturnOfGoodsFromCustomers - a list of values to fill in.
//
Procedure FillChoiceList(ChoiceData, EstablishedStatus) Export
	If Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
		Return
	EndIf;
	
	ChoiceData.Clear();
	
	ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon);
	ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn);
	If Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
		ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply, NStr("vi = 'Đang dự phòng';
																							|ru = 'В резерве';
																							|en = 'In reserve'; fa = 'در رزرو';
																							|it = 'In riserva';
																							|pl = 'W rezerwie';
																							|tr = 'Rezervde'"));
		ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip);
	Else
		ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply, NStr("vi = 'Cần thực hiện';
																							|ru = 'К выполнению';
																							|en = 'Ready for fulfillment'; fa = 'آماده اجرا';
																							|it = 'Da eseguire';
																							|pl = 'Do wykonania';
																							|tr = 'Gerçekleştirilecek'"));
	EndIf;
	
	If GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment")
		Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
		ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	EndIf;
	ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);
	
	If ChoiceData.FindByValue(EstablishedStatus) = Undefined Then
		
		ChoiceData.Insert(ChoiceData.Count() - 2, EstablishedStatus, EstablishedStatus);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon);
	ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn);
	
	If Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
		ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply, NStr("vi = 'Đang dự phòng';
																							|ru = 'В резерве';
																							|en = 'In reserve'; fa = 'در رزرو';
																							|it = 'In riserva';
																							|pl = 'W rezerwie';
																							|tr = 'Rezervde'"));
		ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip);
	Else
		ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply, NStr("vi = 'Cần thực hiện';
																							|ru = 'К выполнению';
																							|en = 'Ready for fulfillment'; fa = 'آماده اجرا';
																							|it = 'Da eseguire';
																							|pl = 'Do wykonania';
																							|tr = 'Gerçekleştirilecek'"));
	EndIf;
	
	If GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment")
		Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
		ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	EndIf;
	ChoiceData.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);
	
EndProcedure

#EndRegion
