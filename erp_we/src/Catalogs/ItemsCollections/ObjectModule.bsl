#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ValueIsFilled(PurchaseStartDate) 
		And ValueIsFilled(PurchaseRestrictionDate) 
		And PurchaseStartDate = PurchaseRestrictionDate Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Kỳ mua hàng phải nhiều hơn một ngày.';
				|ru = 'Период закупок должен быть больше одного дня.';
				|en = 'Purchase period should be longer than one day.'; fa = 'Purchase period should be longer than one day.';
				|it = 'Il periodo di approvvigionamento deve essere superiore a un giorno.';
				|pl = 'Okres zakupów musi być dłuższy niż jeden dzień.';
				|tr = 'Satın alma süresi bir günden fazla olmalıdır.'"),
			ThisObject,
			"PurchaseRestrictionDate",
			,
			Cancel);
		
	EndIf; 
	
	If ValueIsFilled(SalesStartDate) 
		And ValueIsFilled(SalesRestrictionDate) 
		And SalesStartDate = SalesRestrictionDate Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Kỳ bán hàng phải nhiều hơn một ngày.';
				|ru = 'Период продаж должен быть больше одного дня.';
				|en = 'Sales period should be longer than one day.'; fa = 'Sales period should be longer than one day.';
				|it = 'Il periodo di vendite deve essere superiore a un giorno.';
				|pl = 'Okres sprzedaży musi być dłuższy niż jeden dzień.';
				|tr = 'Satış süresi bir günden fazla olmalıdır.'"),
			ThisObject,
			"SalesRestrictionDate",
			,
			Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf