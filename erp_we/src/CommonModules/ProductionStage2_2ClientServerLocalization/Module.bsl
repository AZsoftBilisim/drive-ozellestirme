
#Region Public

#Region Form

// Generates a hyperlink of the processor's order
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document
Procedure CreateOrderCreationHyperlink(Form) Export
	
	Object = Form.Object;
	If Object.ProductionByThirdParty Then
		
		If Form.TollingOrderCreated Then
			
			RowsArray = New Array;
			
				OrderPresentation =
					StrTemplate(
						NStr("vi = 'đơn đặt hàng gia công số %1 ngày %2';
							|ru = 'заказ переработчику № %1 от %2';
							|en = 'Subcontracting purchase order No. %1, %2'; fa = 'Subcontracting purchase order No. %1, %2';
							|it = 'Ordine al processore №%1 di %2';
							|pl = 'zamówienie dla przetwórcy nr %1 z dnia %2';
							|tr = 'Fason satın alma siparişi № %2''dan %1'"),
						ObjectsPrefixesClientServer.NumberForPrinting(
							Form.TollingOrderAttributes.Number, False, True),
						Format(Form.TollingOrderAttributes.Date, "DLF=D"));
			
			If Form.RightToViewATollingOrder
				Or Form.RightToViewATollingOrder2_5 Then
				LinkToOrder = GetURL(Form.Object.SubcontractOrder);
			Else
				LinkToOrder = Undefined;
			EndIf;
			RowsArray.Add(New FormattedString(OrderPresentation,,,, LinkToOrder));
			
			If Not Form.TollingOrderAttributes.Posted Then
				RowsArray.Add(" ");
				RowsArray.Add(New FormattedString(
											NStr("vi = 'chưa kết chuyển';
												|ru = 'не проведен';
												|en = 'not posted'; fa = 'not posted';
												|it = 'Non effettuato';
												|pl = 'nie zaksięgowany';
												|tr = 'Kaydedilmedi'"),, Form.SpecialTextColor));
			EndIf;
			
			OrderText = New FormattedString(RowsArray);
			
		Else
			
			StringText = NStr("vi = 'tạo đơn đặt hàng gia công';
								|ru = 'создать заказ переработчику';
								|en = 'create subcontracting purchase order'; fa = 'create subcontracting purchase order';
								|it = 'Creare un ordine al processore';
								|pl = 'utwórz zamówienie dla przetwórcy';
								|tr = 'Fason satın alma siparişi oluştur'");
			
			If Form.UseSubcontractOrders2_5
				And Form.RightToAddATollingOrder2_5 Then
				LinkToOrder = "#CreateOrder2_5";
			Else
				StringText = NStr("vi = 'không có đơn đặt hàng gia công';
									|ru = 'нет заказа переработчику';
									|en = 'no subcontracting purchase order'; fa = 'no subcontracting purchase order';
									|it = 'Nessun ordine al processore';
									|pl = 'nie ma zamówienia dla przetwórcy';
									|tr = 'Fason satın alma siparişi yok'");
				LinkToOrder = "";
			EndIf;
			
			OrderText = New FormattedString(StringText,,,, LinkToOrder);
			
		EndIf;
		
		Form.LabelTollingOrder = New FormattedString("(", OrderText, ")");
		
	Else
		Form.LabelTollingOrder = New FormattedString("");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
