#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	//++ WE
	Cancel = False;

	DocumetParameters = New Structure("Posted, PaymentMethodHR");

	If StrFind(CommandExecuteParameters.Source.FormName, "Document") > 0 Then
		FillPropertyValues(DocumetParameters, CommandExecuteParameters.Source.Object);
	Else
		FillPropertyValues(DocumetParameters, CommandExecuteParameters.Source.CurrentItem.CurrentData);
	EndIf;

	If Not DocumetParameters.Posted Then
		Cancel = True;
		ErrorText = NStr("vi = 'Không thể tạo chứng từ mới dựa trên chứng từ chưa kết chuyển.';
						|ru = 'Нельзя создавать новый документ на основании непроведенного.';
						|en = 'Cannot create a new document based on an unposted one.'; fa = 'Cannot create a new document based on an unposted one.';
						|it = 'Cannot create a new document based on an unposted one.';
						|pl = 'Cannot create a new document based on an unposted one.';
						|tr = 'Kaydedilmemiş belge üzerinden yeni belge oluşturulamaz.'");
		CommonClient.MessageToUser(ErrorText, CommandParameter);
	EndIf;

	If Not DocumetParameters.PaymentMethodHR = PredefinedValue("Enum.PaymentMethodsHR.CashAccount") Then
		Cancel = True;
		ErrorText = NStr("vi = 'Đã chọn sai phương thức thanh toán cho chứng từ. Dự tính: Tiền mặt.';
						|ru = 'Выбран документ с некорректным способом выплаты. Ожидается: Касса.';
						|en = 'A document with an incorrect payment method is selected. Expected: Cash account.'; fa = 'A document with an incorrect payment method is selected. Expected: Cash account.';
						|it = 'A document with an incorrect payment method is selected. Expected: Cash account.';
						|pl = 'A document with an incorrect payment method is selected. Expected: Cash account.';
						|tr = 'Hatalı ödeme yöntemine sahip bir belge seçildi. Beklenen: Kasa.'");
		CommonClient.MessageToUser(ErrorText, CommandParameter);
	EndIf;

	If Cancel Then
		Return;
	EndIf;

	FormParameters = New Structure("Basis", CommandParameter);
	OpenForm("Document.CashVoucher.ObjectForm", FormParameters);
	//-- WE

	Return;

EndProcedure

#EndRegion