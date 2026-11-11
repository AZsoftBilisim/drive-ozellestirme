
&AtServer
Function ResubmitRetailSalesReportsOnServer(CommandParameter)
	
	DocumentsArray = New Array;
	
	Query = New Query(
	"SELECT
	|	CashRegisterShift.Ref AS CashRegisterShift,
	|	CashRegisterShift.CashRegister AS CashRegister,
	|	CashRegisterShift.FiscalDevice AS FiscalDevice	
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Posted
	|	AND CashRegisterShift.Ref IN (&CashRegisterShift)
	|	AND CashRegisterShift.Status <> VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|");
	
	Query.SetParameter("CashRegisterShift", CommandParameter);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ErrorDescription = "";
		// We will get the status of the cash shift
		RegisterShiftState = RetailSales.GetCashShiftState(Selection.CashRegister, CommandParameter);
		
		// We will fill out a couple of documents for each type of tax assessment: a retail sales report, a Retail returns report
		DocumentPairsFormed = RetailSales.CompleteReportsOnRetailSalesAndReturns(RegisterShiftState, ErrorDescription);
		
		DocumentsArray.Add(RegisterShiftState.CashRegisterShift);
		
		If Not DocumentPairsFormed Then
			ArrayOfErrorDescriptionLines = New Array;
			ArrayOfErrorDescriptionLines.Add(StrTemplate(NStr("vi = 'Thao tác điền lại bảng kê bán lẻ hàng hóa theo phiên thu ngân %1 bị ngắt do lỗi.';
																|ru = 'Операция перезаполнения отчета о розничных продажах по кассовой смене %1 прервана по ошибке.';
																|en = 'Refilling the retail sales report for the %1 POS shift was interrupted in error.'; fa = 'Refilling the retail sales report for the %1 POS shift was interrupted in error.';
																|it = 'Операция перезаполнения отчета о розничных продажах по кассовой смене %1 прервана по ошибке.';
																|pl = 'Refilling the retail sales report for the %1 POS shift was interrupted in error.';
																|tr = '%1 POS vardiyasına ilişkin perakende satış raporunun yeniden doldurulması işlemi hata nedeniyle kesintiye uğradı.'"), RegisterShiftState.CashRegisterShift));
			If Not IsBlankString(ErrorDescription) Then
				ArrayOfErrorDescriptionLines.Add(NStr("vi = 'Mô tả bổ sung:';
														|ru = 'Дополнительное описание:';
														|en = 'Additional description:'; fa = 'Additional description:';
														|it = 'Descrizione aggiuntiva:';
														|pl = 'Opis dodatkowy:';
														|tr = 'Ek açıklama:'"));
				ArrayOfErrorDescriptionLines.Add(ErrorDescription);
			EndIf;
			
			ErrorDescription = StrConcat(ArrayOfErrorDescriptionLines, Chars.LF);
			Common.MessageToUser(ErrorDescription);
		EndIf;
		
	EndDo;
	
	Return DocumentsArray;
	
EndFunction

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ClearMessages();
	
	DocumentsArray = ResubmitRetailSalesReportsOnServer(CommandParameter);

	For Each Document In DocumentsArray Do
		
		If TypeOf(Document) = Type("DocumentRef.CashRegisterShift") Then
			OpenForm("Document.CashRegisterShift.ObjectForm", New Structure("Key,OpenShiftReportsTab", Document, True));
		EndIf;	
		
	EndDo;
	
	Notify("Write_RetailReturnsReport", New Structure, CommandParameter);
	Notify("Write_RetailSalesReport", New Structure, CommandParameter);
	
	ShowUserNotification(NStr("vi = 'Đã điền bảng kê hàng hóa bán lẻ và trả lại';
								|ru = 'Заполнение отчетов о розничных продажах и возвратах выполнено';
								|en = 'Retail sales and return reports are filled in'; fa = 'Retail sales and return reports are filled in';
								|it = 'La compilazione dei report su vendite e resi al dettaglio è stata completata';
								|pl = 'Wypełnienie raportów o sprzedaży detalicznej i zwrotów zostało wykonano';
								|tr = 'Perakende satış ve iade raporlarının tamamlanması'", CommonClient.DefaultLanguageCode()));
	
EndProcedure
