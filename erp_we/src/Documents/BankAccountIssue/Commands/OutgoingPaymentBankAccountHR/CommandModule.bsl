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
		CommonClient.MessageToUser(ErrorText);
	EndIf;

	If Not DocumetParameters.PaymentMethodHR = PredefinedValue(
		"Enum.PaymentMethodsHR.EmployeeSBankAccount") Then
		Cancel = True;
		ErrorText = NStr(
			"vi = 'Đã chọn sai phương thức thanh toán cho chứng từ. Dự tính: Tài khoản ngân hàng của nhân viên.';
			|ru = 'Выбран документ с некорректным способом выплаты. Ожидается: Банковский счет сотрудника.';
			|en = 'A document with an incorrect payment method is selected. Expected: Employee bank account.'; fa = 'A document with an incorrect payment method is selected. Expected: Employee bank account.';
			|it = 'A document with an incorrect payment method is selected. Expected: Employee bank account.';
			|pl = 'A document with an incorrect payment method is selected. Expected: Employee bank account.';
			|tr = 'Geçersiz ödeme yöntemine sahip belge seçildi. Beklenen: Çalışanın banka hesabı.'");
		CommonClient.MessageToUser(ErrorText);
	EndIf;

	If Cancel Then
		Return;
	EndIf;

	FillingStructure = New Structure;
	FillingStructure.Insert("ArrayOfStatements", CommandParameter);

	FormParameters = New Structure("Basis", FillingStructure);

	OpenForm("Document.BankAccountIssue.ObjectForm", FormParameters);
	
	//-- WE

	Return;

EndProcedure

#EndRegion