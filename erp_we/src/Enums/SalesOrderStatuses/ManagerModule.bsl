#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the status selection list, depending on the enabled options
//
// Parameters:
//  ChoiceData  - ValueList - a list of values to fill in.
//  EstablishedStatus  - EnumRef.SalesOrderStatuses - a list of values to fill in.
//
Procedure FillChoiceList(ChoiceData, EstablishedStatus) Export
	If Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
		Return
	EndIf;
	
	ChoiceData.Clear();
	
	ChoiceData.Add(Enums.SalesOrderStatuses.NotApproved);
	
	If Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
		ChoiceData.Add(Enums.SalesOrderStatuses.ToSupply, NStr("vi = 'Đang dự phòng';
																|ru = 'В резерве';
																|en = 'In reserve'; fa = 'در رزرو';
																|it = 'In riserva';
																|pl = 'W rezerwie';
																|tr = 'Rezervde'"));
		ChoiceData.Add(Enums.SalesOrderStatuses.ToShip);
	Else
		ChoiceData.Add(Enums.SalesOrderStatuses.ToSupply, NStr("vi = 'Cần thực hiện';
																|ru = 'К выполнению';
																|en = 'Pending fulfillment'; fa = 'در انتظار اجرا';
																|it = 'Da eseguire';
																|pl = 'Do wykonania';
																|tr = 'Gerçekleştirilecek'"));
	EndIf;
	
	If GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment")
		Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
		ChoiceData.Add(Enums.SalesOrderStatuses.Closed);
	EndIf;
	
	If ChoiceData.FindByValue(EstablishedStatus) = Undefined Then
		
		ChoiceData.Add(EstablishedStatus, EstablishedStatus);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	ChoiceData.Add(Enums.SalesOrderStatuses.NotApproved);
	
	If Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
		ChoiceData.Add(Enums.SalesOrderStatuses.ToSupply, NStr("vi = 'Đang dự phòng';
																|ru = 'В резерве';
																|en = 'In reserve'; fa = 'در رزرو';
																|it = 'In riserva';
																|pl = 'W rezerwie';
																|tr = 'Rezervde'"));
		ChoiceData.Add(Enums.SalesOrderStatuses.ToShip);
	Else
		ChoiceData.Add(Enums.SalesOrderStatuses.ToSupply, NStr("vi = 'Cần thực hiện';
																|ru = 'К выполнению';
																|en = 'Pending completion'; fa = 'در انتظار تکمیل';
																|it = 'Da eseguire';
																|pl = 'Do wykonania';
																|tr = 'Gerçekleştirilecek'"));
	EndIf;
	
	If GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment")
		Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
		ChoiceData.Add(Enums.SalesOrderStatuses.Closed);
	EndIf;
	
EndProcedure

#EndRegion
