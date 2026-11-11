
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CashRegister = Parameters.CashRegister;
	Organization = Parameters.Organization;
	
	Parameters.Property("Cashier", Cashier); 
	
	Period = New StandardPeriod(StandardPeriodVariant.Today);
	CashRegisterParameters = Catalogs.CashRegisters.CashRegisterParameters(CashRegister);
	CashRegisterIsUsedWithoutConnectionOfEquipment = CashRegisterParameters.UseWithoutConnectingPeripherals;
	
	StructureRegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	CashRegisterShift = StructureRegisterShiftState.CashRegisterShift;
	If ValueIsFilled(CashRegisterShift) Then
		UsedByKKTFZ54 = RetailSalesServerCall.UsedByKKTFZ54(CashRegisterShift);
	Else
		UsedByKKTFZ54 = False;
	EndIf;
	
	FillInTheGoodsTable();

	Items.Period.Visible                  = (UsedByKKTFZ54 Or CashRegisterIsUsedWithoutConnectionOfEquipment);

	FillInPresentationOfTitleOfIssueRefundButtonOnServer();
	Items.FormRegisterReturn.Title = PresentationOfRefundButtonTitle.RegisterReturn;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCertificateTable

&AtClient
Procedure CertificateTableSelectedOnChange(Item)
	
	CertificateTableIsSelectedWhenModifiedOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RegisterReturn(Command)
	
	ClearMessages();
	If SelectedPositions = 0 Then
		MessageText = NStr("vi = 'Cần chọn phiếu tính tiền để lập chứng từ trả lại hàng theo phiếu.';
							|ru = 'Необходимо выбрать чек для оформления возврата по чеку.';
							|en = 'Select a receipt to register return'; fa = 'Select a receipt to register return';
							|it = 'Необходимо выбрать чек для оформления возврата по чеку.';
							|pl = 'Należy wybrać paragon do tworzenia zwrotu według paragonu.';
							|tr = 'Makbuz üzerinden iade yapmak için bir makbuz seçmelisiniz.'", CommonClient.DefaultLanguageCode());
		CommonClient.MessageToUser(MessageText);
		Return;
	Else
 		RowsSelected = CertificateTable.FindRows(New Structure("Selected", True));
		AdditionalParameters = New Structure("RowsSelected", RowsSelected);
		CallbackDescriptionOnCompletion = New CallbackDescription("OpenCWPFormForIssuingCashRegisterReceipt", ThisObject, AdditionalParameters);
		If Not RequestConfirmationOfReceiptSelectionForRefund(CallbackDescriptionOnCompletion) Then
			RunCallback(CallbackDescriptionOnCompletion, DialogReturnCode.Yes);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FindCertificates(Command)
	
	FillInTheGoodsTable();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure OpenCWPFormForIssuingCashRegisterReceipt(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then

		FormParameters = New Structure;	
		Rows = AdditionalParameters.RowsSelected;	
		SelectedReceipt = Rows[0].CashRegisterReceipt;

		OpeningParameters = New Structure;
		OpeningParameters.Insert("Goods", AddressInTempStorage(FormOwner.UUID));
		OpeningParameters.Insert("CashRegisterReceipt", SelectedReceipt);
		OpeningParameters.Insert("Cashier", Cashier);
		FormParameters.Insert("Basis", OpeningParameters);

		OpenForm("Document.ReturnOfGiftCards.Form.CWPDocumentForm", FormParameters, FormOwner);
		
		Close();
	EndIf;
	
EndProcedure

&AtClient
Function RequestConfirmationOfReceiptSelectionForRefund(CallbackOnCompletion)
	
	Result = False;
	
	CashRegisterReceiptCashShiftIsOpen = CallbackOnCompletion.AdditionalParameters.RowsSelected[0].CashRegisterReceiptCashShiftIsOpen;	
	If CashRegisterReceiptCashShiftIsOpen = True Then
		Result = True;
		QueryText = NStr("vi = 'Phiên thu ngân của phiếu bán được chọn khác với phiên hiện tại và còn chưa bị đóng. 
							|Nếu sẽ đóng phiên hiện tại trước thì điều này có thể dẫn đến phản ánh sai khi ghi nhận dữ liệu về trả lại. Tiếp tục?';
							|ru = 'Кассовая смена выбранного чека продажи отличается от текущей и ещё не закрыта.
							|Если текущая кассовая смена будет закрыта раньше, это может привести к неправильному отражению в учете данных о возврате. Продолжить?';
							|en = 'The POS shift of the selected sales receipt differs from the current one and is not yet closed.
							|If the current POS shift is closed earlier, this may lead to incorrect recording of the return data in accounting. Continue?'; fa = 'The POS shift of the selected sales receipt differs from the current one and is not yet closed.
							|If the current POS shift is closed earlier, this may lead to incorrect recording of the return data in accounting. Continue?';
							|it = 'Кассовая смена выбранного чека продажи отличается от текущей и ещё не закрыта.
							|Если текущая кассовая смена будет закрыта раньше, это может привести к неправильному отражению в учете данных о возврате. Продолжить?';
							|pl = 'The POS shift of the selected sales receipt differs from the current one and is not yet closed.
							|If the current POS shift is closed earlier, this may lead to incorrect recording of the return data in accounting. Continue?';
							|tr = 'Seçilen satış fişinin kasa vardiyası mevcut kasa vardiyasından farklı ve henüz kapatılmamış.
							|Mevcut kasa vardiyasının daha erken kapatılması iade verilerinin muhasebeye yanlış yansımasına neden olabilir. Devam edilsin mi?'");
		ShowQueryBox(CallbackOnCompletion, QueryText, QuestionDialogMode.YesNo);

	EndIf;

	Return Result;
EndFunction

&AtServer
Procedure FillInPresentationOfTitleOfIssueRefundButtonOnServer()
	
	PresentationOfRefundButtonTitle = New Structure;
	PresentationOfRefundButtonTitle.Insert("RegisterReturn", Commands.Find(Items.FormRegisterReturn.CommandName).Title);
	PresentationOfRefundButtonTitle.Insert("OpenDeferredRefund", NStr("vi = 'Mở chứng từ trả lại hoãn lại';
																		|ru = 'Открыть отложенный возврат';
																		|en = 'Open deferred return'; fa = 'Open deferred return';
																		|it = 'Открыть отложенный возврат';
																		|pl = 'Otwórz odłożony zwrot';
																		|tr = 'Bekleyen bir iade açın'"));
	
EndProcedure

&AtServer
Function AddressInTempStorage(Var_UUID)
	
	GiftCertificates = CertificateTable.Unload(New Array);
	For Each TSRow In CertificateTable Do
		If TSRow.Selected Then
			FillPropertyValues(GiftCertificates.Add(), TSRow);
		EndIf;
	EndDo;
	
	Return PutToTempStorage(GiftCertificates, Var_UUID);
	
EndFunction

&AtServer
Procedure FillInTheGoodsTable()
	
	CertificateTable.Clear();
	
	ConditionTextIsUsedByKKTFZ54        = "AND T.Date >= &StartDate AND T.Date <= &EndDate";
	TextOfConditionIsUsedByKKTFZ54Refund = "AND T.Date >= &StartDate";
	ConditionTextIsNotUsedByKKTFZ54      = "AND T.CashRegisterShift = &CashRegisterShift";
	ConditionTextReceiptNumber                  = "AND FiscalTransactions.CashRegisterReceiptNumber = &CashRegisterReceiptNumber";
	ConditionTextTypeOfGiftCertificate =
	"AND T.Ref IN (
	|	SELECT T.Ref
	|FROM
	|	Document.GiftCertificateSale.GiftCertificates AS T
	|WHERE
	|	T.Ref.CashRegisterShift = &CashRegisterShift AND T.GiftCertificate.Owner = &GiftCertificateKind)
	|";
	TextOfCompanyCondition                = "AND T.Organization = &Organization";
	
	QueryText =
	"SELECT
	|	T.Ref AS Ref,
	|	T.CashRegisterReceiptNumber AS CashRegisterReceiptNumber,
	|	T.CashRegisterShift AS CashRegisterShift
	|INTO CashRegisterReceipts
	|FROM
	|	Document.GiftCertificateSale AS T
	|		LEFT JOIN InformationRegister.FiscalTransactions AS FiscalTransactions
	|		ON T.Ref = FiscalTransactions.DocumentBasis
	|WHERE
	|	T.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	" + ?(ValueIsFilled(Organization),               TextOfCompanyCondition, "") + "
	|	" + ?(UsedByKKTFZ54,                          ConditionTextIsUsedByKKTFZ54, ConditionTextIsNotUsedByKKTFZ54) + "
	|	" + ?(ValueIsFilled(CashRegisterReceiptNumber),              ConditionTextReceiptNumber,                 "")                          + "
	|	" + ?(ValueIsFilled(GiftCertificateKind), ConditionTextTypeOfGiftCertificate, "")                          + "
	|
	|UNION ALL
	|
	|SELECT
	|	T.Ref AS Ref,
	|	T.CashRegisterReceiptNumber AS CashRegisterReceiptNumber,
	|	T.CashRegisterShift AS CashRegisterShift
	|FROM
	|	Document.ReturnOfGiftCards AS T
	|WHERE
	|	T.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	" + ?(ValueIsFilled(Organization), TextOfCompanyCondition, "") + "
	|	" + ?(UsedByKKTFZ54, TextOfConditionIsUsedByKKTFZ54Refund, ConditionTextIsNotUsedByKKTFZ54) + "
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|";

	QueryText = QueryText +
	"SELECT DISTINCT
	|	PaymentWithPaymentCards.Ref,
	|	TRUE AS PaidByCard
	|INTO CashRegisterReceiptsPaidByCards
	|FROM
	|	Document.GiftCertificateSale.PaymentWithPaymentCards AS PaymentWithPaymentCards
	|WHERE
	|	PaymentWithPaymentCards.Ref IN (SELECT T.Ref FROM CashRegisterReceipts AS T)
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref               AS CashRegisterReceipt,
	|	
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	1                                          AS Count,
	|	GiftCertificates.Sum                AS Sum
	|	
	|INTO TDGiftCertificates
	|FROM
	|	Document.GiftCertificateSale.GiftCertificates AS GiftCertificates
	|WHERE
	|	GiftCertificates.Ref IN (SELECT T.Ref FROM CashRegisterReceipts AS T)
	|
	|UNION ALL
	|
	|SELECT
	|	GiftCertificates.Ref.GiftCertificateSale AS CashRegisterReceipt,
	|	
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	-1                                         AS Count,
	|	-GiftCertificates.Sum               AS Sum
	|FROM
	|	Document.ReturnOfGiftCards.GiftCertificates AS GiftCertificates
	|WHERE
	|	GiftCertificates.Ref IN (SELECT T.Ref FROM CashRegisterReceipts AS T)
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.CashRegisterReceipt               AS CashRegisterReceipt,
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	SUM(GiftCertificates.Count)    AS Count,
	|	SUM(GiftCertificates.Sum)         AS Sum
	|INTO Result
	|FROM
	|	TDGiftCertificates AS GiftCertificates
	|GROUP BY
	|	GiftCertificates.CashRegisterReceipt,
	|	GiftCertificates.GiftCertificate
	|HAVING
	|	SUM(GiftCertificates.Count) > 0
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.CashRegisterReceipt                            AS CashRegisterReceipt,
	|	ISNULL(CashRegisterReceipts.CashRegisterReceiptNumber, 0) AS CashRegisterReceiptNumber,
	|	ISNULL(CashRegisterReceiptsPaidByCards.PaidByCard, FALSE)  AS PaidByCard,
	|	
	|	GiftCertificates.GiftCertificate              AS GiftCertificate,
	|	GiftCertificates.Sum             AS Sum,
	|	CASE WHEN CashRegisterReceipts.CashRegisterShift <> &CashRegisterShift 
	|				AND NOT CashRegisterReceiptCashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
	|		THEN TRUE 
	|		ELSE FALSE 
	|	END AS CashRegisterReceiptCashShiftIsOpen
	|FROM
	|	Result AS GiftCertificates
	|		LEFT JOIN InformationRegister.FiscalTransactions AS FiscalTransactions
	|		ON GiftCertificates.CashRegisterReceipt = FiscalTransactions.DocumentBasis
	|		LEFT JOIN CashRegisterReceiptsPaidByCards ON GiftCertificates.CashRegisterReceipt = CashRegisterReceiptsPaidByCards.Ref
	|		LEFT JOIN CashRegisterReceipts AS CashRegisterReceipts ON CashRegisterReceipts.Ref = GiftCertificates.CashRegisterReceipt
	|		LEFT JOIN Document.CashRegisterShift AS CashRegisterReceiptCashRegisterShift ON CashRegisterReceiptCashRegisterShift.Ref = CashRegisterReceipts.CashRegisterShift
	|";
	Query = New Query(QueryText);
	Query.Parameters.Insert("CashRegisterShift", CashRegisterShift);
	
	If ValueIsFilled(CashRegisterReceiptNumber) Then
		Query.Parameters.Insert("CashRegisterReceiptNumber", CashRegisterReceiptNumber);
	EndIf;
	If ValueIsFilled(GiftCertificateKind) Then
		Query.Parameters.Insert("GiftCertificateKind", GiftCertificateKind);
	EndIf;
	If UsedByKKTFZ54 Then
		Query.Parameters.Insert("StartDate",     Period.StartDate);
		Query.Parameters.Insert("EndDate",  Period.EndDate);
	EndIf;
	If ValueIsFilled(Organization) Then
		Query.Parameters.Insert("Organization", Organization);
	EndIf;
	CurrentSessionDate = CurrentSessionDate();
	
	SelectedPositions = 0;
	Total = 0;
	ValueTable = Query.Execute().Unload();
	DataOfGiftCertificates = GiftCertificatesServerCall.GetGiftCertificatesDetails(ValueTable.UnloadColumn("GiftCertificate"));
	For Each String In ValueTable Do
		GiftCertificateDetails = DataOfGiftCertificates[String.GiftCertificate];
		If Not GiftCertificateDetails = Undefined Then
			If GiftCertificatesClientServer.GiftCertificateCanBeReturned(GiftCertificateDetails, CurrentSessionDate) Then
				TSRow = CertificateTable.Add();
				FillPropertyValues(TSRow, String);
			EndIf;
		Else
			Continue;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculateAtServer()
	
	SelectedPositions = 0;
	Total            = 0;
	
	For Each TSRow In CertificateTable Do
		
		If Not TSRow.Selected Then
			Continue;
		EndIf;
		
		SelectedPositions = SelectedPositions + 1;
		Total = Total + TSRow.Sum;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CertificateTableIsSelectedWhenModifiedOnServer()
	
	CurrentData = CertificateTable.FindByID(Items.CertificateTable.CurrentRow);
	CashRegisterReceipt        = CurrentData.CashRegisterReceipt;
	PaidByCard = CurrentData.PaidByCard;
	For Each TSRow In CertificateTable Do
		If TSRow.CashRegisterReceipt = CashRegisterReceipt And PaidByCard Then
			TSRow.Selected = CurrentData.Selected;
		EndIf;
		If Not TSRow.CashRegisterReceipt = CashRegisterReceipt Then
			TSRow.Selected = False;
		EndIf;
	EndDo;
	
	RecalculateAtServer();
	
EndProcedure

#EndRegion

#EndRegion
