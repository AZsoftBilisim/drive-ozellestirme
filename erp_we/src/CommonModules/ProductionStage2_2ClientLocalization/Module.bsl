
#Region Public

#Region Form

// Handles clicking the hyperlink of the processor's order
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	FormattedStringURL - String
// 	StandardProcessing - Boolean
//
Procedure LabelTollingOrderURLProcessing(Form, FormattedStringURL, StandardProcessing) Export
	
	Object = Form.Object; // DocumentObject.ProductionStage2_2 - form object
	
	If FormattedStringURL = "#CreateOrder"
		Or FormattedStringURL = "#CreateOrder2_5" Then
		
		StandardProcessing = False;
		
		QueryText = Undefined;
		If Object.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.BeingGenerated")
			Or Object.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1") Then
			
			QueryText = NStr("vi = 'Để tạo đơn hàng, cần đặt trạng thái ""Cần thực hiện"".
										|Thay đổi trạng thái công đoạn và tạo mới đơn hàng?';
										|ru = 'Для создания заказа необходимо установить статус ""К выполнению"".
										|Изменить статус этапа и создать заказ?';
										|en = 'To create an order, set the ""For release"" status.
										|Change the stage status and create an order?'; fa = 'To create an order, set the ""For release"" status.
										|Change the stage status and create an order?';
										|it = 'È necessario impostare lo stato ""Da completare"" per la creazione dell''ordine. 
										| Cambiare stato della fase e creare ordine?';
										|pl = 'Aby utworzyć zamówienie, należy ustawić status ""Do wykonania"".
										|Zmienić status stołu montażowego i utworzyć zamówienie?';
										|tr = 'Bir sipariş oluşturmak için durum ""Gerçekleştirilecek"" olarak ayarlanmalıdır.
										|Bir aşamanın durumunu değiştirip sipariş oluşturulsun mu?'");
										
			ButtonsList = New ValueList;
			ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Thay đổi trạng thái và tạo đơn hàng';
														|ru = 'Изменить статус и создать заказ';
														|en = 'Change status and create order'; fa = 'Change status and create order';
														|it = 'Cambiare status e creare ordine';
														|pl = 'Zmień status i utwórz zamówienie';
														|tr = 'Durum değiştir ve sipariş oluştur'"));
			ButtonsList.Add(DialogReturnCode.Cancel);
			
		ElsIf Not ValueIsFilled(Object.Ref) Or Form.Modified Then
			
			QueryText = NStr("vi = 'Để tạo đơn hàng, cần ghi lại chứng từ.
										|Ghi lại chứng từ và tạo đơn hàng?';
										|ru = 'Для создания заказа необходимо записать документ.
										|Записать документ и создать заказ?';
										|en = 'You should save the document to create an order.
										|Save the document and create an order?'; fa = 'You should save the document to create an order.
										|Save the document and create an order?';
										|it = 'Per la creazione dell''ordine è necessario registrare il documento. 
										| Registrare documento e creare ordine?';
										|pl = 'Aby utworzyć zamówienie, należy zapisać dokument.
										|Zapisać dokument i utworzyć zamówienie?';
										|tr = 'Sipariş oluşturmak için bir belge kaydetmeniz gerekir.
										|Bir belge kaydedip sipariş oluşturulsun mu?'");
			
			ButtonsList = New ValueList;
			ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại và tạo đơn hàng';
														|ru = 'Записать и создать заказ';
														|en = 'Save and create order'; fa = 'Save and create order';
														|it = 'Registrare e creare ordine';
														|pl = 'Zapisać i utworzyć zamówienie';
														|tr = 'Siparişi kaydet ve oluştur'"));
			ButtonsList.Add(DialogReturnCode.Cancel);
			
		EndIf; 
		
		If QueryText <> Undefined Then
			
			CallbackDescription =
				New CallbackDescription(
					"RecordObjectAndCreateOrderForProcessor",
					Form,
					FormattedStringURL);
			
			ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
			
		Else
			CreateOrderForProcessor(Object, FormattedStringURL);
		EndIf; 
		
	EndIf;
	
EndProcedure

// Opens a new order form for the processor created based on the production stage
// 
// Parameters:
// 	Object - DocumentObject.ProductionStage2_2 - document form object
// 	Hyperlink - String - Hyperlink
//
Procedure CreateOrderForProcessor(Object, Hyperlink) Export
	
	FormParameters = New Structure("Basis", Object.Ref);
	If Hyperlink = "#CreateOrder2_5" Then
		OpenForm("Document.SubcontractOrder2_5.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion