#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns a list of options for order States.
//
// Returns:
// 	ValueList of EnumRef.SalesOrderStates
//
Function ListOfAvailableStatesOfOrders() Export
	
	ChoiceList = New ValueList;
	
	ChoiceList.Add("AllOpened", NStr("vi = 'Tất cả đã mở';
									|ru = 'Все открытые';
									|en = 'Open orders'; fa = 'سفارش‌های باز';
									|it = 'Tutti aperti';
									|pl = 'Wszystkie otwarte';
									|tr = 'Tümü açık'"));
	ChoiceList.Add("AllPaymentPending", NStr("vi = 'Tất cả đang chờ thanh toán';
											|ru = 'Все ожидающие оплаты';
											|en = 'All pending payment'; fa = 'All pending payment';
											|it = 'Tutti in attesa di pagamento';
											|pl = 'Wszystkie oczekujące płatności';
											|tr = 'Bekleyen ödemelerin tümü'"));
	ChoiceList.Add("AllExecutionPending", NStr("vi = 'Tất cả đang chờ thực hiện';
												|ru = 'Все ожидающие исполнения';
												|en = 'Unfulfilled orders'; fa = 'سفارش‌های اجرانشده';
												|it = 'Tutti in attesa di esecuzione';
												|pl = 'Wszystkie oczekujące wykonania';
												|tr = 'Bekleyen gerçekleştirmelerin tümü'"));
	
	ChoiceList.Add(Enums.SalesOrderStates.PendingApproval);
	
	If Not GetFunctionalOption("UseSimplifiedPaymentSchemeInSales") Then
		ChoiceList.Add(Enums.SalesOrderStates.PendingAdvanceBeforeSupply);
	EndIf;
	
	ChoiceList.Add(Enums.SalesOrderStates.ReadyForSupply);
	ChoiceList.Add(Enums.SalesOrderStates.PendingPrepaymentBeforeShipment);
	ChoiceList.Add(Enums.SalesOrderStates.PendingSupply);
	ChoiceList.Add(Enums.SalesOrderStates.ReadyToShip);
	ChoiceList.Add(Enums.SalesOrderStates.DuringShipment);
	ChoiceList.Add(Enums.SalesOrderStates.TransferOfTitleToGoodsIsExpected);
	ChoiceList.Add(Enums.SalesOrderStates.PendingPaymentAfterShipment);
	
	If GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment")
		Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
		ChoiceList.Add(Enums.SalesOrderStates.ReadyForClosure);
	EndIf;
	
	ChoiceList.Add(Enums.SalesOrderStates.Closed);
	
	Return ChoiceList;
	
EndFunction

#EndRegion

#EndIf