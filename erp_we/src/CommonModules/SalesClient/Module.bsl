////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions for processing user actions
// in the process of working with sales documents.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the largest of the advance dates in the PM line payment Stages
//
// Parameters:
//   PaymentScheduleSteps - FormDataCollection - the stages of payment, in which you want to calculate the date of the advance.
//
// Returns:
//   Date - the maximum advance date, if there are no advance dates, then an empty date.
//
Function MaximumAdvancePaymentDate(PaymentScheduleSteps) Export
	
	MaxAdvanceDate = '00010101';
	
	For Each CurStage In PaymentScheduleSteps Do
		
		If CurStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment")
			Or CurStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision") Then
			
			MaxAdvanceDate = Max(MaxAdvanceDate, CurStage.PaymentDate);
			
		EndIf;
		
	EndDo;

	Return MaxAdvanceDate;
	
EndFunction

// Procedure for processing the "start Editing" event for the table part of the sales document.
//
// Parameters:
//	Form         - ClientApplicationForm - form of the document where the event occurred
//	TableName    - String - name of the table that the event originated from
//	TableRow - FormDataCollectionItem - processed row in the table part of the document
//	NewRow   - Boolean - flag for editing a new line
//	Copy   - Boolean - flag for editing by copying a string.
//
Procedure ProductItemLineAtBeginningOfEditing(Form, TableName, TableRow, NewRow, Copy) Export

	If NewRow And Not Copy Then

		If Not Form.ToUseTermsOfSales And TableRow.Property("PriceKind") Then
			
			Table = Form.Object[TableName];
			
			If Table.Count() > 1 Then
				TableRow.PriceKind = Table[TableRow.LineNumber - 2].PriceKind;
			EndIf;
			
			If Not ValueIsFilled(TableRow.PriceKind) Then
				TableRow.PriceKind = Form.DefaultPriceType;
			EndIf;
			
		EndIf;
			
	EndIf;
	
EndProcedure

// Displays a notification to the user that the desired shipment date has been re-filled.
//
Procedure NotifyDesiredShipmentDateToBeFilledInAgain() Export

	ShowUserNotification(
		NStr("vi = 'Ngày gửi hàng mong muốn';
			|ru = 'Желаемая дата отгрузки перезаполнена';
			|en = 'Requested shipment date is refilled'; fa = 'Requested shipment date is refilled';
			|it = 'La data di spedizione desiderata è piena';
			|pl = 'Żądana data wysyłki jest pełna';
			|tr = 'İstenen sevkiyat tarihi fazlasıyla dolduruldu'"),
		,
		NStr("vi = 'Ngày giao hàng mong muốn được bổ sung dựa trên ngày tạm ứng tối đa.';
			|ru = 'Желаемая дата отгрузки перезаполнена с учетом максимальной даты аванса.';
			|en = 'Requested shipment date is refilled considering the maximum advance date.'; fa = 'Requested shipment date is refilled considering the maximum advance date.';
			|it = 'La data di spedizione desiderata è piena a seguito della data massima di pagamento anticipato.';
			|pl = 'Żądana data wysyłki zostanie uzupełniona, aby odzwierciedlić maksymalny termin zaliczki.';
			|tr = 'İstenen sevkiyat tarihi fazlasıyla maksimum avans tarihi dikkate alınarak dolduruldu.'"),
		PictureLib.Information32);

EndProcedure

// Initializes the State structure of the order.
//
// Returns:
//	Structure - structure with fields:
//	 * State - EnumRef.SalesOrderStates -
//	 * StateOverdue - Boolean -
//	 * PayAmount - Number -
//	 * AmountByShipment - Number -
//	 * PayPercentage - Number -
//	 * OrderShipmentPercentage - Number -
//	 * AmountOfDebt - Number -
//	 * DebtPercentage - Number -
//	 * AmountToPay - Number -
//	 * ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice - Boolean -
//
Function StructureOfStateOfOrder() Export
	
	StructureOfStateOfOrder = ARAPAccountingClientServer.StructureOfStateOfCalculations(True);
	StructureOfStateOfOrder.Insert("ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice", False);
	Return StructureOfStateOfOrder;
	
EndFunction

#Region ProceduresAndFunctionsForWorkingWithValueSelection

// Function-constructor of parameters for starting the selection of an agreement with the client on the form.
//
// Returns:
//	Structure - parameter structure:
//		* Item                      - FormField, Undefined - The selection box of the agreement.
//		* Partner                      - CatalogRef.Partners, Undefined - link to the partner
//																					to select the agreement for.
//		* Organization                  - CatalogRef.Companies, Undefined - link to the organization that
//																						the agreement is selected for.
//		* Document                     - CatalogRef.TermsOfSale, Undefined - a link to the previously selected
//																								agreement for initial
//																								positioning in the list.
//		* DocumentDate                - Date - Date for the determination of the current agreement.
//		* OnlyStandard                - Boolean - flag that allows you to include only standard agreements in the selection list
//		* OnlyUsedBySalesRepresentative  - Boolean - flag that allows you to include only agreements
//													used in the work of sales representatives in the selection list.
//		* BusinessOperation        - EnumRef.BusinessTransactions, Undefined - the business transaction of the object
//																									for which the agreement will be
//																									selected.
//		* FormDataStructure         - FormDataStructure, Undefined - initiator Form data, agreement selection.
//		* ContractsAreUsed - Boolean, Undefined - A selection attribute that allows you to include agreements in the selection list
//																	for which the Contract must be specified.
//		* ConsignmentSales25        - Boolean, Undefined - A selection attribute that allows you to include agreements in the selection list
//																that use the commission
//																sales setting of version 2.5.
//		* ShipmentWithDeferredTransferOfTitle25 - Boolean, Undefined - a selection attribute that allows you to include in
//																			the selection list agreements under which
//																			goods can be sold without transferring
//																			ownership of version 2.5.
//																			A sign indicating the use of Contracts
//																			of counterparties in the agreement must take
//																			the value 'True'.
//		* OnlyTransferOperations        - Boolean, Undefined - A selection attribute that allows you to include agreements in the selection list
//																that use the commission
//																sales setting of version 2.5.
//		* TransferShipmentOperations      - Boolean, Undefined - a selection attribute that allows you to include agreements in the selection list
//																that use the Sales commission setting of version 2.5.
//																and the sale of goods without transfer of ownership of version 2.5.
//
Function ParametersForStartingSelectionOfAgreementWithClient() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("Item", Undefined);
	ParametersStructure.Insert("Partner", Undefined);
	ParametersStructure.Insert("Organization", Undefined);
	ParametersStructure.Insert("Document", Undefined);
	ParametersStructure.Insert("DocumentDate", Date(1,1,1));
	ParametersStructure.Insert("OnlyStandard", False);
	ParametersStructure.Insert("OnlyUsedBySalesRepresentative", False);
	ParametersStructure.Insert("BusinessOperation", Undefined);
	ParametersStructure.Insert("FormDataStructure", Undefined);
	ParametersStructure.Insert("ContractsAreUsed", Undefined);
	ParametersStructure.Insert("ConsignmentSales25", Undefined);
	ParametersStructure.Insert("ShipmentWithDeferredTransferOfTitle25", Undefined);
	ParametersStructure.Insert("OnlyTransferOperations", Undefined);
	ParametersStructure.Insert("TransferShipmentOperations", Undefined);
	
	Return ParametersStructure;
	
EndFunction

// Procedure-handler for the "initial Selection" event of the "Agreement" form element"
//
// Parameters:
//	ParametersStructure  - See SalesClient.ParametersForStartingSelectionOfAgreementWithClient
//	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure StartSelectingAgreementWithClient(ParametersStructure, StandardProcessing) Export
	
	StandardProcessing = False;
	
	Partner = ParametersStructure.Partner;
	
	If Not ValueIsFilled(Partner) Then
		FilterClient = New Structure("Client", True);
		
		If ParametersStructure.Property("ServedBySalesRepresentatives") Then
			FilterClient.Insert("ServedBySalesRepresentatives", ParametersStructure.ServedBySalesRepresentatives);	
		EndIf;
		
		FormParameters = New Structure("Filter", FilterClient);
		DescriptionOfFormClosingNotification = New CallbackDescription("StartSelectingAgreementWithClientCompletion",
																	ThisObject,
																	ParametersStructure);
		
		OpenForm("Catalog.Partners.ChoiceForm",
					FormParameters,
					,
					,
					,
					,
					DescriptionOfFormClosingNotification,
					FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
	EndIf;
	
	StartSelectingAgreementWithClientFragment(ParametersStructure);
	
EndProcedure

// Prepares the parameters for opening the selection form of the Customer Agreement Catalog, after the user
// specifies the customer, and opens the selection form.
//
// Parameters:
//	Result               - CatalogRef.Partners - the partner for which agreements are selected.
//	AdditionalParameters - Structure - additional parameters required for the selection of agreements.
//
Procedure StartSelectingAgreementWithClientCompletion(Result, AdditionalParameters) Export
	
	FormDataStructure = AdditionalParameters.FormDataStructure;
	
	Partner = Result;
	
	If FormDataStructure <> Undefined Then
		FormDataStructure.Partner = Partner;
		If FormDataStructure.Property("Counterparty") Then
			PartnersAndCounterpartiesServerCall.FillInPartnerSDefaultCounterparty(
				Partner,
				FormDataStructure.Counterparty,
				True);
		EndIf;
	EndIf;
	
	StructureForSelection = ParametersForStartingSelectionOfAgreementWithClient();
	FillPropertyValues(StructureForSelection, AdditionalParameters);
	StructureForSelection.Insert("Partner", Partner);
	
	StartSelectingAgreementWithClientFragment(StructureForSelection);
	
EndProcedure

// Procedure-handler for the "start Selection" event of the "expense Analysis" form element.
//
// Parameters:
//	Item  - FormField - Expense analysis selection field
//	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure StartSelectingExpenseAnalytics(Item, StandardProcessing) Export
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.SalesClient.StartSelectingExpenseAnalytics");
	// End StandardSubsystems.PerformanceMeasurement
	
	StandardProcessing = False;
	OpenForm("CommonForm.SelectExpenditureDimension", , Item);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForCheckingAbilityToPerformActions

// Checks whether the details required to cancel rows in the table are filled in
//
// Parameters:
//   TabularSection              - FormDataCollection - the table part where the check should be performed.
//   TabularSectionPresentation - String - representation of the table part for informing the user.
//   SelectedRows - Array
//
// Returns:
//   Boolean - False if the required data is not filled in.
//
Function YouMustFillInReasonsForCancelingSelectedLines(TabularSection, TabularSectionPresentation, SelectedRows) Export
	
	If TabularSection.Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ chưa điền danh sách %TabularSectionPresentation%. Không thể hủy các dòng.';
							|ru = 'В документе не заполнен список %TabularSectionPresentation%. Строки не могут быть отменены.';
							|en = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot cancel the lines.'; fa = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot cancel the lines.';
							|it = 'All''interno del documento non è compilato l''elenco %TabularSectionPresentation%. Le righe non possono essere cancellate.';
							|pl = 'Dokument nie zawiera wypełnionej listy %TabularSectionPresentation%. Terminy nie mogą być anulowane.';
							|tr = '%TabularSectionPresentation% listesi belgede doldurulmadı. Satırlar iptal edilemez.'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	ElsIf SelectedRows.Count() = 0 Then
		
		ShowMessageBox(,NStr("vi = 'Trong bảng không có dòng đã chọn. Hãy chọn dòng để hủy.';
							|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для отмены.';
							|en = 'Selected rows are missing in the table. Select rows to cancel.'; fa = 'Selected rows are missing in the table. Select rows to cancel.';
							|it = 'Non ci sono righe selezionate nella tabella. Selezionare le righe per cancellare.';
							|pl = 'W tabeli nie ma podświetlonych wierszy. Podświetl wiersze, aby anulować.';
							|tr = 'Tabloda seçilen satır yok. İptal edilecek satırları seç.'"));
		Return False;
		
	EndIf;
	
	Return True;

EndFunction

// Checks whether the details required to cancel undelivered lines are filled in
//
// Parameters:
//   TabularSection              - FormDataCollection - the table part where the check should be performed.
//   TabularSectionPresentation - String - representation of the table part for informing the user.
//
// Returns:
//   Boolean - False if the required data is not filled in.
//
Function YouMustFillInReasonForCancelingUndeliveredLines(TabularSection, TabularSectionPresentation) Export
	
	If TabularSection.Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ chưa điền danh sách %TabularSectionPresentation%. Không thể hủy các dòng.';
							|ru = 'В документе не заполнен список %TabularSectionPresentation%. Строки не могут быть отменены.';
							|en = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot cancel the lines.'; fa = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot cancel the lines.';
							|it = 'All''interno del documento non è compilato l''elenco %TabularSectionPresentation%. Le righe non possono essere cancellate.';
							|pl = 'Dokument nie zawiera wypełnionej listy %TabularSectionPresentation%. Terminy nie mogą być anulowane.';
							|tr = '%TabularSectionPresentation% listesi belgede doldurulmadı. Satırlar iptal edilemez.'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	Else
		
		ThereAreNonCanceledLines = False;
		For Each CurRow In TabularSection Do
			If Not CurRow.Canceled Then
				ThereAreNonCanceledLines = True;
			EndIf;
		EndDo;
		
		If Not ThereAreNonCanceledLines Then
			ShowMessageBox(,NStr("vi = 'Đã hủy tất cả các dòng.';
								|ru = 'Все строки отменены.';
								|en = 'All lines are canceled.'; fa = 'All lines are canceled.';
								|it = 'Tutte le righe sono annullate.';
								|pl = 'Wszystkie wiersze anulowano.';
								|tr = 'Tüm satırlar iptal edildi.'"));
			Return False;
		EndIf;
			
	EndIf;
	
	Return True;

EndFunction

// Checks whether the details required to fill in the goods for shipment are filled in.
//
// Parameters:
//   DocumentPosted - Boolean - indicates whether the document is complete.
//
// Returns:
//   Boolean - False if the required data is not filled in.
//
Function ItIsNecessaryToFillInGoodsOnShipment(DocumentPosted) Export
	
	If Not DocumentPosted Then
		ShowMessageBox(,NStr("vi = 'Chưa kết chuyển chứng từ, không thể điền.';
							|ru = 'Документ не проведен, заполнение невозможно.';
							|en = 'Document is not posted, cannot fill in the attributes.'; fa = 'Document is not posted, cannot fill in the attributes.';
							|it = 'Il documento non è verificato, la compilazione non è possibile.';
							|pl = 'Dokument nie jest zatwierdzony, wypełnianie nie jest możliwe.';
							|tr = 'Belge kaydedilmedi, doldurulması mümkün değil.'"));
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Checks whether the notification in the form is an event for changing payment documents.
//
// Parameters:
//   EventName - String - name of the event from the procedure in the "message Processing" form.
//
// Returns:
//   Boolean - True if the notification is a payment.
//
Function ChangedPaymentDocumentsForCustomers(EventName) Export
	
	Return
		EventName = "Write_PaymentCardTransaction"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_ARAPSettlement"
		Or EventName = "Write_DebtCancellation";
	
EndFunction

#EndRegion

#Region ProceduresForNotifyingUserOfCompletedActions

// Displays a notification to the user when the default sales terms are completed.
//
Procedure NotifyEndOfFillingInDefaultSalesConditions() Export

	ShowUserNotification(
		NStr("vi = 'Đã điền điều kiện bán hàng';
			|ru = 'Условия продаж заполнены';
			|en = 'Sales terms and conditions are filled in'; fa = 'Sales terms and conditions are filled in';
			|it = 'Le condizioni di vendita sono compilate';
			|pl = 'Warunki sprzedaży są wypełnione';
			|tr = 'Satış şartları dolduruldu'"),
		,
		NStr("vi = 'Đã điền điều kiện bán hàng theo mặc định';
			|ru = 'Условия продаж по умолчанию заполнены';
			|en = 'Sales terms and conditions are filled in by the default'; fa = 'Sales terms and conditions are filled in by the default';
			|it = 'Le condizioni di vendita predefinite sono compilate';
			|pl = 'Warunki domyślne sprzedaży są wypełnione';
			|tr = 'Varsayılan satış şartları dolduruldu'"),
		PictureLib.Information32);

EndProcedure

// Displays a notification to the user when the sales terms are completed
//
Procedure NotifyEndOfFillingInTermsOfSale() Export

	ShowUserNotification(
		NStr("vi = 'Đã điền điều kiện bán hàng';
			|ru = 'Условия продаж заполнены';
			|en = 'Sales terms and conditions are filled in'; fa = 'Sales terms and conditions are filled in';
			|it = 'Le condizioni di vendita sono compilate';
			|pl = 'Warunki sprzedaży są wypełnione';
			|tr = 'Satış şartları dolduruldu'"),
		,NStr("vi = 'Đã điền điều kiện bán hàng theo thỏa thuận với khách hàng';
				|ru = 'Условия продаж по соглашению с клиентом заполнены';
				|en = 'Sales terms and conditions under customer agreement are filled in'; fa = 'Sales terms and conditions under customer agreement are filled in';
				|it = 'Le condizioni di vendita in base all''accordo con il cliente sono compilate';
				|pl = 'Warunki sprzedaży zależące od umowy z klientem są wypełnione';
				|tr = 'Satış koşulları satış koşullarına göre dolduruldu'"),
		PictureLib.Information32);

EndProcedure

// Displays a notification to the user about the end of filling in prices according to the agreement with the client.
//
// Parameters:
//	PricesCalculated - Boolean - Indicates that prices were calculated successfully in at least one line.
//	ErrorText - String - Description of the error when calculating prices.
//
Procedure NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated = True, ErrorText = "") Export

	If PricesCalculated Then
		ShowUserNotification(
			NStr("vi = 'Đơn giá điền';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled out'; fa = 'Prices are filled out';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar dolduruldu'"),
			,
			NStr("vi = 'Giá theo thỏa thuận với khách hàng đã điền';
				|ru = 'Цены по соглашению с клиентом заполнены';
				|en = 'Prices under customer agreement are filled in'; fa = 'Prices under customer agreement are filled in';
				|it = 'I prezzi in accordo con il cliente sono compilati';
				|pl = 'Ceny po uzgodnieniu z klientem są wypełnione';
				|tr = 'Satış koşullarına göre fiyatlar dolduruldu'"),
			PictureLib.Information32);
	Else
		MessageText = NStr("vi = 'Chưa điền đơn giá theo thỏa thuận với khách hàng vào dòng nào.';
							|ru = 'Ни в одной строке цены по соглашению с клиентом не заполнены.';
							|en = 'Prices according to the terms of sales are not filled in any lines.'; fa = 'Prices according to the terms of sales are not filled in any lines.';
							|it = 'I prezzi da accordo col cliente sono compilati in tutte le stringhe';
							|pl = 'W żadnym wierszu ceny zgodnie z umową z klientem nie są wypełnione.';
							|tr = 'Satırların hiçbirinde satış koşullarına göre fiyatlar doldurulmadı.'");
		If Not IsBlankString(ErrorText) Then
			MessageText = MessageText + Chars.LF + ErrorText;
		EndIf;
		
		ShowUserNotification(
			NStr("vi = 'Chưa điền đơn giá';
				|ru = 'Цены не заполнены';
				|en = 'Prices are not filled in'; fa = 'Prices are not filled in';
				|it = 'I prezzi non sono compilati';
				|pl = 'Nie wypełniono ceny';
				|tr = 'Fiyatlar doldurulmadı'"),
			,
			MessageText,
			PictureLib.Information32);
	EndIf;
	
EndProcedure

// Displays a notification to the user about the end of filling in prices under the Contract With the client.
//
// Parameters:
//	PricesCalculated - Boolean - Indicates that prices were calculated successfully in at least one line.
//	ErrorText - String - Description of the error when calculating prices.
//
Procedure NotifyAboutEndOfFillingInPricesUnderContract(PricesCalculated = True, ErrorText = "") Export

	If PricesCalculated Then
		ShowUserNotification(
			NStr("vi = 'Đã điền đơn giá';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled'; fa = 'Prices are filled';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar dolduruldu'"),
			,
			NStr("vi = 'Đã điền giá theo thỏa thuận với khách hàng';
				|ru = 'Цены по договору с клиентом заполнены';
				|en = 'Prices under the contract with the customer are filled'; fa = 'Prices under the contract with the customer are filled';
				|it = 'Цены по договору с клиентом заполнены';
				|pl = 'Prices under the contract with the customer are filled';
				|tr = 'Müşteri ile sözleşme fiyatları dolduruldu'"),
			PictureLib.Information32);
	Else
		MessageText = NStr("vi = 'Chưa điền đơn giá theo thỏa thuận với khách hàng vào dòng nào.';
							|ru = 'Ни в одной строке цены по договору с клиентом не заполнены.';
							|en = 'Prices under the contract with the customer are not filled in any lines.'; fa = 'Prices under the contract with the customer are not filled in any lines.';
							|it = 'Ни в одной строке цены по договору с клиентом не заполнены.';
							|pl = 'Prices under the contract with the customer are not filled in any lines.';
							|tr = 'Hiçbir satırda müşteri sözleşme fiyatları dolduruldu.'");
		If Not IsBlankString(ErrorText) Then
			MessageText = MessageText + Chars.LF + ErrorText;
		EndIf;
		
		ShowUserNotification(
			NStr("vi = 'Chưa điền đơn giá';
				|ru = 'Цены не заполнены';
				|en = 'Prices are not filled'; fa = 'Prices are not filled';
				|it = 'I prezzi non sono compilati';
				|pl = 'Nie wypełniono ceny';
				|tr = 'Fiyatlar doldurulmadı'"),
			,
			MessageText,
			PictureLib.Information32);
	EndIf;
	
EndProcedure

// Displays a notification to the user about the end of filling in prices by price type.
//
// Parameters:
//  PricesCalculated - Boolean - Indicates that prices were calculated successfully in at least one line.
//  PricesKind - CatalogRef.TypesOfPrices - The type of prices used for filling in prices.
//
Procedure NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind) Export

	If PricesCalculated Then
		ShowUserNotification(
			NStr("vi = 'Đã điền đơn giá';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled out'; fa = 'Prices are filled out';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar dolduruldu'"),
			,
			StrReplace(NStr("vi = 'Đã điền đơn giá theo dạng giá ""%PricesKind%""';
							|ru = 'Цены по виду цен ""%PricesKind%"" заполнены';
							|en = 'Prices according to the ""%PricesKind%"" price type are filled in'; fa = 'Prices according to the ""%PricesKind%"" price type are filled in';
							|it = 'I prezzi per tipologia di prezzo ""%PricesKind%"" sono compilati';
							|pl = 'Ceny wg rodzaju cen ""%PricesKind%"" zapełnione';
							|tr = 'Fiyat türüne göre fiyatlar ""%PricesKind%"" dolduruldu'"), "%PricesKind%", PricesKind),
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Chưa điền đơn giá';
				|ru = 'Цены не заполнены';
				|en = 'Prices are not filled in'; fa = 'Prices are not filled in';
				|it = 'I prezzi non sono compilati';
				|pl = 'Nie wypełniono ceny';
				|tr = 'Fiyatlar doldurulmadı'"),
			,
			StrReplace(NStr("vi = 'Chưa điền đơn giá theo dạng giá ""%PricesKind%"" tại bất kỳ trong dòng nào';
							|ru = 'Ни в одной строке цены по виду цен ""%PricesKind%"" не заполнены';
							|en = 'No lines have prices of the ""%PricesKind%"" price type filled in'; fa = 'No lines have prices of the ""%PricesKind%"" price type filled in';
							|it = 'I prezzi per tipologia di prezzo ""%PricesKind%"" sono compilati in tutte le righe';
							|pl = 'Żaden z wierszy ceny w rodzaju cen ""%PricesKind%"" nie jest wypełniony';
							|tr = 'Satırların hiçbirinde fiyat türüne göre fiyatlar ""%PricesKind%"" doldurulmadı'"), "%PricesKind%", PricesKind),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

// Displays a notification to the user about canceling selected rows
//
// Parameters:
//	CancellationReason - CatalogRef.ReasonsForSaleOrderCancellation - The reason for the cancellation of selected lines.
//
Procedure NotifyAboutCancellationOfSelectedLines(CancellationReason) Export

	NotificationTextTemplate = NStr("ru = 'Выделенные строки отменены%TextReasonForCancellation%.';
									|vi = 'Selected lines are canceled%TextReasonForCancellation%.';
									|en = 'Selected lines are canceled%TextReasonForCancellation%.'; fa = 'Selected lines are canceled%TextReasonForCancellation%.';
									|it = 'Selected lines are canceled%TextReasonForCancellation%.';
									|pl = 'Selected lines are canceled%TextReasonForCancellation%.';
									|tr = 'Seçili satırlar iptal edildi %TextReasonForCancellation%.'");
	
	If ValueIsFilled(CancellationReason) Then
		TextReasonForCancellation =
			StrReplace(NStr("ru = ' по причине ""%CancellationReason%""';
							|vi = ' due to ""%CancellationReason%""';
							|en = ' due to ""%CancellationReason%""'; fa = ' due to ""%CancellationReason%""';
							|it = ' due to ""%CancellationReason%""';
							|pl = ' due to ""%CancellationReason%""';
							|tr = ' gerekçesi: ""%CancellationReason%""'"), "%CancellationReason%", CancellationReason);
	Else
		TextReasonForCancellation = "";
	EndIf;
	
	NotificationText1 = StrReplace(NotificationTextTemplate, "%TextReasonForCancellation%", TextReasonForCancellation);
	
		ShowUserNotification(
			NStr("vi = 'Đã hủy các dòng được chọn';
				|ru = 'Выделенные строки отменены';
				|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
				|it = 'Righe selezionate annullate';
				|pl = 'Zaznaczone wiersze anulowano';
				|tr = 'Seçili satırlar iptal edildi'"),
			,
			NotificationText1,
			PictureLib.Information32);
	
EndProcedure

// Displays a notification to the user about canceling selected rows
//
// Parameters:
//	CancellationReason - CatalogRef.ReasonsForSaleOrderCancellation - The reason for the cancellation of selected lines.
//	NumberOfCanceledLines - Number
//	CheckBalance - Boolean
//
Procedure NotifyAboutCancellationOfUndeliveredLines(CancellationReason, NumberOfCanceledLines, CheckBalance) Export

	If NumberOfCanceledLines = 0 Then
			
		ShowUserNotification(
			NStr("vi = 'Chưa hủy bỏ dòng';
				|ru = 'Строки не отменены';
				|en = 'Lines were not canceled'; fa = 'Lines were not canceled';
				|it = 'Righe non annullate';
				|pl = 'Wiersze nie są anulowane';
				|tr = 'Satırlar iptal edilmedi'"),
			,
			NStr("vi = 'Theo tất cả các dòng đã tạo chứng từ giao hàng. Không thể hủy bỏ dòng.';
				|ru = 'По всем строкам оформлена отгрузка. Строки не могут быть отменены.';
				|en = 'The shipment is registered for all lines. The lines cannot be canceled'; fa = 'The shipment is registered for all lines. The lines cannot be canceled';
				|it = 'Per tutte le righe sono stati formalizzati i documenti. Le righe non possono essere cancellate';
				|pl = 'Na wszystkich jest zatwierdzona wysyłka. Wierszy nie można anulować.';
				|tr = 'Tüm satırlar için sevkiyat düzenlendi. Satırlar iptal edilemez.'"),
			PictureLib.Information32);
			
		Else
			
			If CheckBalance Then
				NotificationTextTemplate = NStr("ru = 'Все непоставленные строки отменены%TextReasonForCancellation%.';
												|vi = 'All undelivered items are canceled%TextReasonForCancellation%.';
												|en = 'All undelivered items are canceled%TextReasonForCancellation%.'; fa = 'All undelivered items are canceled%TextReasonForCancellation%.';
												|it = 'All undelivered items are canceled%TextReasonForCancellation%.';
												|pl = 'All undelivered items are canceled%TextReasonForCancellation%.';
												|tr = 'Tedarik edilmeyen tüm satırlar iptal edildi %TextReasonForCancellation%.'");
			Else
				NotificationTextTemplate = NStr("ru = 'Все строки отменены%TextReasonForCancellation%.';
												|vi = 'All items are canceled%TextReasonForCancellation%.';
												|en = 'All items are canceled%TextReasonForCancellation%.'; fa = 'All items are canceled%TextReasonForCancellation%.';
												|it = 'All items are canceled%TextReasonForCancellation%.';
												|pl = 'All items are canceled%TextReasonForCancellation%.';
												|tr = 'Tüm satırlar iptal edildi %TextReasonForCancellation%.'");
			EndIf;
			
			If ValueIsFilled(CancellationReason) Then
				TextReasonForCancellation =
					StrReplace(NStr("ru = ' по причине ""%CancellationReason%""';
									|vi = ' due to ""%CancellationReason%""';
									|en = ' due to ""%CancellationReason%""'; fa = ' due to ""%CancellationReason%""';
									|it = ' due to ""%CancellationReason%""';
									|pl = ' due to ""%CancellationReason%""';
									|tr = ' gerekçesi: ""%CancellationReason%""'"), "%CancellationReason%", CancellationReason);
			Else
				TextReasonForCancellation = "";
			EndIf;
			
			NotificationText1 = StrReplace(NotificationTextTemplate, "%TextReasonForCancellation%", TextReasonForCancellation);
			
			ShowUserNotification(
					NStr("vi = 'Hủy bỏ dòng';
						|ru = 'Строки отменены';
						|en = 'Lines were canceled'; fa = 'Lines were canceled';
						|it = 'Righe annullate';
						|pl = 'Wiersze są anulowane';
						|tr = 'Satırlar iptal edildi'"),
					,
					NotificationText1,
					PictureLib.Information32);
			
		EndIf;
	
EndProcedure

// Displays a notification to the user that all PM lines have finished filling in the shipment dates.
//
// Parameters:
//	DateOfShipment - Date - the shipment date for which the date was filled in in the table part
//	FillingSelectedRows - Boolean
//
Procedure NotifyEndOfFillingInShipmentDates(DateOfShipment, FillingSelectedRows) Export

	If FillingSelectedRows Then
		
		ShowUserNotification(
			NStr("vi = 'Đã điền ngày giao hàng';
				|ru = 'Дата отгрузки заполнена';
				|en = 'Shipment date is filled in'; fa = 'Shipment date is filled in';
				|it = 'La data di spedizione è piena';
				|pl = 'Data wysyłki jest wypełniona';
				|tr = 'Sevkiyat tarihi dolduruldu'"),
			,
			StrReplace(NStr("vi = 'Đối với tất cả các dòng được chọn đã đặt ngày giao hàng %DateOfShipment%';
							|ru = 'Для выделенных строк установлена дата отгрузки %DateOfShipment%';
							|en = 'Shipment date %DateOfShipment% is set for the selected lines'; fa = 'Shipment date %DateOfShipment% is set for the selected lines';
							|it = 'Per le righe selezionate è stata impostata la data di spedizione %DateOfShipment%';
							|pl = 'Dla wszystkich zaznaczonych wierszy ustalona jest data wysyłki %DateOfShipment%';
							|tr = 'Seçilen satırlar sevkiyat tarihi %DateOfShipment% olarak ayarlandı'"), "%DateOfShipment%", Format(DateOfShipment, "DLF=D")),
			PictureLib.Information32);
		
	Else
		
		ShowUserNotification(
			NStr("vi = 'Đã điền ngày giao hàng';
				|ru = 'Дата отгрузки заполнена';
				|en = 'Shipment date is filled in'; fa = 'Shipment date is filled in';
				|it = 'La data di spedizione è piena';
				|pl = 'Data wysyłki jest wypełniona';
				|tr = 'Sevkiyat tarihi dolduruldu'"),
			,
			StrReplace(NStr("vi = 'Đối với tất cả dòng đã đặt ngày giao hàng %DateOfShipment%';
							|ru = 'Для всех строк установлена дата отгрузки %DateOfShipment%';
							|en = 'Shipment date %DateOfShipment% is set for all lines'; fa = 'Shipment date %DateOfShipment% is set for all lines';
							|it = 'Data di spedizione %DateOfShipment% impostata per tutte le righe';
							|pl = 'Dla wszystkich wierszy ustalona jest data wysyłki %DateOfShipment%';
							|tr = 'Tüm satırlar için sevkiyat tarihi %DateOfShipment% olarak ayarlandı'"), "%DateOfShipment%", Format(DateOfShipment, "DLF=D")),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

// Displays a notification to the user about the end of re-filling of products for the actual shipment.
//
// Parameters:
//	HasChanges           - Boolean - If True, there are changes in the table part
//	RefilledQuantity - Boolean - If True, the quantity was re-filled for the actual shipment.
//	ThereAreUnassembled - Boolean
//
Procedure NotifyEndOfReplenishmentOfGoodsForShipment(HasChanges, RefilledQuantity, ThereAreUnassembled = False) Export
	
	If HasChanges Then
		If ThereAreUnassembled Then
			ShowUserNotification(
				NStr("vi = 'Số lượng đã điền lại';
					|ru = 'Количество перезаполнено';
					|en = 'Refilled quantity'; fa = 'Refilled quantity';
					|it = 'La quantità è ricompilata';
					|pl = 'Ponowne wypełnienie ilości.';
					|tr = 'Miktar yeniden dolduruldu'"),
				,
				NStr("vi = 'Trong các dòng đã điền lại số lượng có ghi nhận hàng hóa được tập hợp tại kho.';
					|ru = 'В строках перезаполнено количество с учетом собирающихся на складе товаров.';
					|en = 'Quantity considering goods that are assembled in the warehouse is refilled in lines.'; fa = 'Quantity considering goods that are assembled in the warehouse is refilled in lines.';
					|it = 'La quantità nelle righe è ricompilata tenuto conto delle merci raccolte in magazzino.';
					|pl = 'W wierszach zapełniono ponownie ilość z uwzględnieniem gromadzących się w magazynie towarów.';
					|tr = 'Satırlarda, ambarda toplanan ürünler dikkate alınarak miktar yeniden dolduruldu.'"),
				PictureLib.Information32);
		Else
			ShowUserNotification(
				NStr("vi = 'Số lượng đã điền lại';
					|ru = 'Количество перезаполнено';
					|en = 'Refilled quantity'; fa = 'Refilled quantity';
					|it = 'La quantità è ricompilata';
					|pl = 'Ponowne wypełnienie ilości.';
					|tr = 'Miktar yeniden dolduruldu'"),
				,
				NStr("vi = 'Đã điền lại số lượng trong các dòng.';
					|ru = 'В строках перезаполнено количество.';
					|en = 'Quantity is refilled in lines.'; fa = 'Quantity is refilled in lines.';
					|it = 'La quantità nelle righe è stata ricompilata.';
					|pl = 'W wierszach jest ponownie wypełnona ilość.';
					|tr = 'Satırlarda miktar yeniden dolduruldu.'"),
				PictureLib.Information32);
		EndIf;
		
	Else
		
		If RefilledQuantity Then
			
			ShowUserNotification(
				NStr("vi = 'Không cần điền lại';
					|ru = 'Перезаполнение не требуется';
					|en = 'You do not need to refill'; fa = 'You do not need to refill';
					|it = 'Reseeding non richiesto';
					|pl = 'Ponowne wypełnienie nie jest potrzebne';
					|tr = 'Yeniden doldurma gerekmiyor'"),
				,
				NStr("vi = 'Không cần điền lại, bởi vì trong tất cả các dòng số lượng trùng với số lượng đã chỉ ra.';
					|ru = 'Перезаполнение не требуется, т.к. во всех строках количество совпадает с указанным.';
					|en = 'Repopulation is not required as the quantity in all lines matches the specified one.'; fa = 'Repopulation is not required as the quantity in all lines matches the specified one.';
					|it = 'Non è richiesta la ricompilazione, poiché in tutte le righe la quantità coincide con quella indicata.';
					|pl = 'Ponowne wypełnienie nie jest potrzebne, ponieważ we wszystkich wierszach ilość jest zbieżna ze wskazaną.';
					|tr = 'Yeniden doldurma gerekli değildir, çünkü tüm satırlarda miktar belirtilenle aynıdır.'"),
				PictureLib.Information32);
			
		Else
		
			ShowUserNotification(
				NStr("vi = 'Không cần điền lại';
					|ru = 'Перезаполнение не требуется';
					|en = 'You do not need to refill'; fa = 'You do not need to refill';
					|it = 'Reseeding non richiesto';
					|pl = 'Ponowne wypełnienie nie jest potrzebne';
					|tr = 'Yeniden doldurma gerekmiyor'"),
				,
				NStr("vi = 'Không theo một dòng nào chưa bắt đầu giao hàng.';
					|ru = 'Ни по одной строке не начата отгрузка.';
					|en = 'Shipment is not started in any line.'; fa = 'Shipment is not started in any line.';
					|it = 'Fase di spedizione cominciata per tutte le righe.';
					|pl = 'Ani w jednym wierszu, nie rozpoczęto wysyłki.';
					|tr = 'Satırların hiçbiri için sevkiyat başlatılmadı.'"),
				PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresForProcessingUserCommands

// Checks whether the details required to fill in the goods for shipment are filled in.
//
// Parameters:
//   CallbackDescription    - CallbackDescription - processing the user selection.
//   ThereAreShippedGoods - Boolean             - indicates whether the goods have been shipped.
//
Procedure QuestionAboutReFillingWithShippedGoods(CallbackDescription, ThereAreShippedGoods) Export
	
	ButtonsList = New ValueList();
	
	If ThereAreShippedGoods Then
		
		QueryText = NStr("vi = 'Không phải tất cả hàng hóa đều được thu thập/giao hàng. Tính khi điền hàng hóa mà đang ở quá trình thu thập?';
						|ru = 'Не все товары собраны/отгружены. Учитывать при заполнении товары, которые находятся в процессе сборки?';
						|en = 'Not all goods are assembled/shipped. Record the goods being assembled during population?'; fa = 'Not all goods are assembled/shipped. Record the goods being assembled during population?';
						|it = 'Non tutte le merci sono raccolte/individuate. Al momento della compilazione delle merci considerare quelle che si trovano in fase di assemblaggio?';
						|pl = 'Nie wszystkie przedmioty są zebrane/wysłane. Wziąć pod uwagę przy wypełnianiu towarów, które są w trakcie montażu?';
						|tr = 'Tüm ürünler montaj/sevk edilmedi. Montaj sürecinde olan ürünleri doldururken dikkate alınıyor mu?'");
		ButtonsList.Add("Consider", NStr("vi = 'Tính đến';
										|ru = 'Учитывать';
										|en = 'Record'; fa = 'ثبت';
										|it = 'Considerare';
										|pl = 'Record';
										|tr = 'Muhasebeleştir'"));
		ButtonsList.Add("DontConsider", NStr("vi = 'Không tính';
											|ru = 'Не учитывать';
											|en = 'Do not record'; fa = 'ثبت نشود';
											|it = 'Non considerare';
											|pl = 'Nie uwzględniać';
											|tr = 'Hesaba katma'"));
		
	Else
		
		QueryText = NStr("vi = 'Thiếu hàng hóa được thu thập/giao. Tính khi điền hàng hóa mà đang ở trạng thái thu thập?';
						|ru = 'Отсутствуют собранные/отгруженные товары. Учитывать при заполнении товары, которые находятся в процессе сборки?';
						|en = 'No assembled/shipped goods. Record the goods being assembled during population?'; fa = 'No assembled/shipped goods. Record the goods being assembled during population?';
						|it = 'Le merci raccolte/individuate sono assenti. Al momento della compilazione delle merci considerare quelle che si trovano in fase di assemblaggio?';
						|pl = 'Brak zebranych/wysłanych towarów. Wziąć pod uwagę przy wypełnianiu towarów, które są w trakcie montażu?';
						|tr = 'Montaj/sevk edilmiş ürün yok. Montaj sürecinde olan ürünleri doldururken dikkate alınıyor mu?'");
		ButtonsList.Add("Consider", NStr("vi = 'Tính đến';
										|ru = 'Учитывать';
										|en = 'Record'; fa = 'ثبت';
										|it = 'Considerare';
										|pl = 'Record';
										|tr = 'Muhasebeleştir'"));
		
	EndIf;
	
	ButtonsList.Add("NotReFill_", NStr("vi = 'Không điền lại';
										|ru = 'Не перезаполнять';
										|en = 'Do not refill'; fa = 'Do not refill';
										|it = 'Non ricompilare';
										|pl = 'Nie wypełniaj ponownie';
										|tr = 'Yeniden doldurma'"));
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	ShowQueryBox(
		New CallbackDescription("QuestionAboutReFillingWithShippedGoodsCompletion", SalesClient, AdditionalParameters),
		QueryText,
		ButtonsList);
	
EndProcedure

// Handler for a question about re-filling with shipped items.
//
// Parameters:
//  UserAnswer           - String - the answer to the question selected by the user.
//  AdditionalParameters - Structure - additional parameters required for filling in.
//
Procedure QuestionAboutReFillingWithShippedGoodsCompletion(UserAnswer, AdditionalParameters) Export
	
	Result = New Structure;
	Result.Insert("FillWithUnassembledGoods", (UserAnswer = "Consider"));
	Result.Insert("Refill", Not (UserAnswer = "NotReFill_"));
	
	RunCallback(AdditionalParameters.CallbackDescription, Result);
	
EndProcedure

// Procedure for selecting the price type from the selection form.
//
// Parameters:
//	CallbackDescription - CallbackDescription - description of the alert.
//	FilterParameters    - Structure - structure of selection parameters
//
Procedure ChooseTypeOfPrices(CallbackDescription, FilterParameters) Export
	
	PriceTypePriceList_ = PriceManagementSystemServerCall.PriceTypePriceList_();
	If PriceTypePriceList_ <> Undefined Then
		RunCallback(CallbackDescription, PriceTypePriceList_);
		Return;
	EndIf;
	
	StructureFilter = New Structure;
	If FilterParameters = Undefined Then
		RunCallback(CallbackDescription, PriceTypePriceList_);
		Return;
	Else
		For Each Parameter In FilterParameters Do
			StructureFilter.Insert(Parameter.Key, Parameter.Value);		
		EndDo;
	EndIf; 
	
	OpenForm(
		"Catalog.TypesOfPrices.ChoiceForm",
		New Structure("Filter", StructureFilter),,,,,
		CallbackDescription);
	
EndProcedure

// Sets the status of agreements selected in the list to "not Agreed".
//
// Parameters:
//	List - DynamicList - List of agreements.
//
Procedure EstablishStatusOfAgreementsWithCustomersNotAgreed(List) Export
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(List) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở những thỏa thuận đã chọn trong danh sách thiết lập trạng thái ""Chưa thống nhất"". Theo thỏa thuận hiện hành có thể lập chứng từ. Sau khi thay đổi trạng thái thì thỏa thuận hiện hành không còn hiệu lực. Tiếp tục?';
					|ru = 'У выделенных в списке соглашений будет установлен статус ""Не согласовано"". По действующим соглашениям могут быть оформлены документы. После изменения статуса действующие соглашения перестанут действовать. Продолжить?';
					|en = 'Status of the agreements selected in the list will be set to Not approved. Documents can be generated for valid agreements. Once the status is changed, the agreements will be no longer valid. Continue?'; fa = 'Status of the agreements selected in the list will be set to Not approved. Documents can be generated for valid agreements. Once the status is changed, the agreements will be no longer valid. Continue?';
					|it = 'Gli accordi selezionati nell''elenco saranno impostati su ""Non concordato"". Secondo gli accordi esistenti potranno essere stilati dei documenti. Dopo la modifica dello stato, gli accordi esistenti cesseranno di funzionare. Continuare?';
					|pl = 'Dla porozumień zaznaczonych na liście zostanie ustawiony status ""Nieuzgodnione"". Dla aktualnych porozumień mogą być sporządzone dokumenty. Po zmianie statusu aktualne porozumienia utracą ważność. Kontynuować?';
					|tr = 'Listede seçili anlaşmaların durumu ""Kabul edilmedi"" olarak ayarlanacaktır. Mevcut anlaşmalar için belge düzenlenebilir. Durum değiştirildikten sonra, mevcut anlaşmaların geçerliliği sona erecektir. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("EstablishStatusOfAgreementsWithCustomersNotAgreedCompletion", ThisObject, New Structure("List", List)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

// Sets the status of agreements with clients
//
// Parameters:
//  QuestionResult		 - DialogReturnCode -  set of user response options 
//  AdditionalParameters	 - Structure - structure of parameters.
//
Procedure EstablishStatusOfAgreementsWithCustomersNotAgreedCompletion(QuestionResult, AdditionalParameters) Export
    
    List = AdditionalParameters.List;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = SalesServerCall.EstablishStatusOfAgreementsWithCustomersNotAgreed(List.SelectedRows);
    TMCommonUseClient.NotifyUserAboutSettingStatus(List, ProcessedItemsCount, List.SelectedRows.Count(), NStr("vi = 'Không thống nhất';
																												|ru = 'Не согласовано';
																												|en = 'Not approved'; fa = 'تأییدنشده';
																												|it = 'Non concordato';
																												|pl = 'Nie uzgodniono';
																												|tr = 'Onaylanmadı'"));

EndProcedure

// Sets the "Valid" status for selected agreements in the list.
//
// Parameters:
//	List - DynamicList - List of agreements.
//
Procedure SetStatusOfAgreementsWithClientsValid(List) Export
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(List) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở những thỏa thuận đã chọn trong danh sách sẽ đặt trạng thái ""Hiệu lực"". Tiếp tục?';
					|ru = 'У выделенных в списке соглашений будет установлен статус ""Действует"". Продолжить?';
					|en = 'Status of the agreements selected in the list will be set to Valid. Continue?'; fa = 'Status of the agreements selected in the list will be set to Valid. Continue?';
					|it = 'Agli accordi selezionati nell''elenco verrà assegnato lo stato ""Attivo"". Continuare?';
					|pl = 'Dla porozumień zaznaczonych na liście zostanie ustawiony status ""Aktualne"". Kontynuować?';
					|tr = 'Listede seçili anlaşmaların durumu ""Aktif"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetStatusOfAgreementsWithClientsValidCompletion", ThisObject, New Structure("List", List)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

// Sets the status of agreements with clients
//
// Parameters:
//  QuestionResult		 - DialogReturnCode -  set of user response options 
//  AdditionalParameters	 - Structure - structure of parameters.
//
Procedure SetStatusOfAgreementsWithClientsValidCompletion(QuestionResult, AdditionalParameters) Export
    
    List = AdditionalParameters.List;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
	
	ClearMessages();
	
    ProcessedItemsCount = SalesServerCall.SetStatusOfAgreementsWithClientsValid(List.SelectedRows);
    TMCommonUseClient.NotifyUserAboutSettingStatus(List, ProcessedItemsCount, List.SelectedRows.Count(), NStr("vi = 'Có hiệu lực';
																												|ru = 'Действует';
																												|en = 'Valid'; fa = 'معتبر';
																												|it = 'In vigore';
																												|pl = 'Valid';
																												|tr = 'Aktif'"));

EndProcedure

// Sets the "Closed" status for selected agreements in the list.
//
// Parameters:
//	List - DynamicList - List of agreements.
//
Procedure SetStatusOfCustomerAgreementsClosed(List) Export
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(List) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở thỏa thuận đã chọn trong danh sách sẽ đặt trạng thái ""Đóng"". Sau khi thay đổi trạng thái thì thỏa thuận có hiệu lực sẽ không còn hiệu lực. Tiếp tục?';
					|ru = 'У выделенных в списке соглашений будет установлен статус ""Закрыто"". После изменения статуса действующие соглашения перестанут действовать. Продолжить?';
					|en = 'Status of the agreements selected in the list will be set to Closed. Once the status is changed, the agreements will be no longer valid. Continue?'; fa = 'Status of the agreements selected in the list will be set to Closed. Once the status is changed, the agreements will be no longer valid. Continue?';
					|it = 'Agli accordi selezionati nell''elenco verrà assegnato lo stato ""Chiuso"". Dopo la modifica dello stato gli accordi attivi smetteranno di funzionare. Procedere?';
					|pl = 'Dla porozumień zaznaczonych na liście zostanie ustawiony status ""Zamknięte"". Po zmianie statusu aktualne porozumienia utracą ważność. Kontynuować?';
					|tr = 'Listede seçili anlaşmaların durumu ""Kapalı"" olarak ayarlanacaktır. Durum değiştirildikten sonra, mevcut anlaşmaların geçerliliği sona erecektir. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetStatusOfCustomerAgreementsClosedCompletion", ThisObject, New Structure("List", List)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

// Sets the status of agreements with clients
//
// Parameters:
//  QuestionResult		 - DialogReturnCode -  set of user response options 
//  AdditionalParameters	 - Structure - structure of parameters.
//
Procedure SetStatusOfCustomerAgreementsClosedCompletion(QuestionResult, AdditionalParameters) Export
    
    List = AdditionalParameters.List;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
	
	ClearMessages();
	
    ProcessedItemsCount = SalesServerCall.SetStatusOfCustomerAgreementsClosed(List.SelectedRows);
    TMCommonUseClient.NotifyUserAboutSettingStatus(List, ProcessedItemsCount, List.SelectedRows.Count(), NStr("vi = 'Đóng';
																												|ru = 'Закрыто';
																												|en = 'Closed'; fa = 'بسته‌شده';
																												|it = 'Chiuso';
																												|pl = 'Closed';
																												|tr = 'Kapalı'"));

EndProcedure

// Sets the Canceled flag for selected rows in the table and fills in the reason for cancellation.
//
// Parameters:
//	TabularSection - FormDataCollection - table part where you need to perform the check
//	SelectedRows - Array - array of user-selected rows in the table part
//	CancellationReason - CatalogRef.ReasonsForSaleOrderCancellation - the reason for a canceled line
//	StructureOfActionsWithModifiedStrings - Structure - The structure of the action with the changed rows.
//
Procedure CancelSelectedLines(TabularSection, SelectedRows, CancellationReason, StructureOfActionsWithModifiedStrings=Undefined) Export
	
	RowsArray = New Array;
	For Each CurRow In SelectedRows Do

		TableRow = TabularSection.FindByID(CurRow);
		RowsArray.Add(TableRow);
	EndDo;
	
	For Each TableRow In RowsArray Do
		
		If TableRow <> Undefined Then
			
			If Not TableRow.Canceled Then
				TableRow.Canceled = True;
			EndIf;
			
			If TableRow.CancellationReason <> CancellationReason Then
				TableRow.CancellationReason = CancellationReason;
			EndIf;
			
			If StructureOfActionsWithModifiedStrings <> Undefined Then
				BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActionsWithModifiedStrings, Undefined);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Handles clicking the document status information hyperlink and displays the "progress Status" report.
//
// Parameters:
//  StandardProcessing  - Boolean - indicates standard event handling.
//  Form                 - ClientApplicationForm - The Form in which the click was made. Contains including:
//    * Object - DocumentObject - 
//
Procedure StatusInFormOfDocumentClick(StandardProcessing, Form) Export
	
	StandardProcessing = False;
	Ref = Form.Object.Ref;
	
	If Not Ref.IsEmpty() Then
		
		StandardProcessing = False;
		DocumentsList = New ValueList;
		DocumentsList.Add(Ref);
		
		OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm", 
		             New Structure("IncomingDocuments", DocumentsList), 
		             Form,
		             True);
	
	EndIf;
	
EndProcedure

//Opens the debt report when you click on the shipment ban hyperlink in the document forms.
Procedure OpenShipmentBanDecryptionReport(Contract, DataOnSaleAmount, PurposeUseKey, NewOnlineARAPAccounting) Export
	
	If Not NewOnlineARAPAccounting Then
		
		FormParameters = New Structure;
		FormParameters.Insert("PurposeUseKey", PurposeUseKey);
		FormParameters.Insert("GenerateOnOpen",     True);
		FormParameters.Insert("Filter",                       New Structure("Contract", Contract));
		FormParameters.Insert("Contract",                     Contract);
		FormParameters.Insert("DataOnSaleAmount",        DataOnSaleAmount);
		
		OpenForm("Report.ShipmentProhibitionReasons.Form",
			FormParameters,
			,
			"Contract=" + Contract);
	Else
		
		FormParameters = New Structure;
		FormParameters.Insert("VariantKey", "CustomerDebtReasonsForBanningShipments" );
		FormParameters.Insert("GenerateOnOpen",         True);
		FormParameters.Insert("Filter",                           New Structure("Contract", Contract));
		FormParameters.Insert("PurposeUseKey",     PurposeUseKey);
		FormParameters.Insert("ReportOptionsCommandsVisibility", False);
		
		OpenForm("Report.CustomersAccountsReceivable.Form", FormParameters);
	EndIf;
	
EndProcedure

// Procedure-handler for clicking on a hyperlink with a list of subordinate documents in the " client Order"
// 
// Parameters:
// 	Form - ClientApplicationForm - Where:
// 		* Object - DocumentObject.SalesOrder
// 	FormattedStringURL - String
// 	StandardProcessing - Boolean
//
Procedure HandlingNavigationLinkOfSubordinateDocuments(Form, FormattedStringURL, StandardProcessing) Export
	
	Separator = "&";
	
	RowsArray = StrSplit(FormattedStringURL, Separator);
	Action = RowsArray[0];
	FullName = "";
	BusinessOperation = Undefined;
	
	If RowsArray.Count() > 1 Then
		FullName = RowsArray[1];
	EndIf;
	
	If RowsArray.Count() > 2 Then
		
		BusinessTransactionName = RowsArray[2];
		BusinessOperation = PredefinedValue(BusinessTransactionName);
		
	EndIf;
	
	StandardProcessing = False;
	
	If Action = "OpenDocument" Then
		
		FileSystemClient.OpenURL(FullName);
		
	ElsIf Action = "ApplyAppearance" Then
		
		TMCommonUseClient.OpenFormAfterCheckingPostingDocument(FullName + ".ObjectForm",
			?(ValueIsFilled(BusinessOperation),
				New Structure("BusinessOperation", BusinessOperation),
				New Structure()),
			Form,
			"Independent",
			"Basis");
		
	ElsIf Action = "OpenList" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", New Structure("Ref", Form.DocumentsBasedOn));
		
		OpenForm(FullName + ".ListForm",
						FormParameters,
						Form,
						,
						,
						,
						,
						FormWindowOpeningMode.LockOwnerWindow);
						
	ElsIf Action = "IssueSet" Then
		
		ReferencesArrray = New Array;
		ReferencesArrray.Add(Form.Object.Ref);
		
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("ReferencesArrray", ReferencesArrray);
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("ObjectKey", "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices/CurrentData");
		
		GenerateSetOfDocumentsChallenge(Undefined, AdditionalParameters);
		
	EndIf;
	
EndProcedure
#EndRegion

#Region WhenCreatingContractFromDocument

// Opens the form for creating a new Contract with partner data.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the document.
//	Item - FormItems - a form field containing information about the Contract.
//	PathToContract - String - the path to the Attribute with the Contract data.
//	Partner - CatalogRef.Partners - partner data for creating a Contract.
//	StandardProcessing - Boolean - this parameter is passed a sign of performing object data matching.
//	NameOfAlertEvent - String - name of the notification event for the document form when the Contract is changed.
//
Procedure OpenContractCreationForm(Form, Item, PathToContract, Partner, StandardProcessing, NameOfAlertEvent = "WhenChangingAgreement") Export
	
	StandardProcessing = False;
	
	ContractFormName = "Catalog.CounterpartyContracts.Form.ItemForm";
	
	FormParameters = New Structure();
	ChoiceParameters = New Structure();
	
	For Each ChoiceParameter In Item.ChoiceParameters Do
		If StrFind(ChoiceParameter.Name,"Filter.") <> 0 Then
			ChoiceParameters.Insert(StrReplace(ChoiceParameter.Name, "Filter.", ""), ChoiceParameter.Value);
		EndIf;
	EndDo;
	
	For Each ChoiceParameter In Item.ChoiceParameterLinks Do
		If StrFind(ChoiceParameter.Name,"Filter.") <> 0 Then
			ParameterValue = TMCommonUseClientServer.DataAlongWay(Form, ChoiceParameter.DataPath);
			KeyName = StrReplace(ChoiceParameter.Name, "Filter.", "");
			If Not ChoiceParameters.Property(KeyName) Then
				ChoiceParameters.Insert(KeyName, ParameterValue);
			EndIf;
		EndIf;
	EndDo;
	
	FormParameters.Insert("Filter",ChoiceParameters);
	
	CreationParameters = CommonClient.CopyRecursive(ChoiceParameters);
	CreationParameters.Insert("Partner", Partner);
	
	FormParameters.Insert("FillingValues",CreationParameters);
	FormParameters.Insert("FillingText", Item.EditText);
	FormParameters.Insert("VerificationWhenCreatingContract", True);
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("Object", Form);
	AdditionalParameters.Insert("Filter", ChoiceParameters);
	AdditionalParameters.Insert("Partner", Partner);
	AdditionalParameters.Insert("PathToContract", PathToContract);
	AdditionalParameters.Insert("NameOfAlertEvent", NameOfAlertEvent);
	
	NotificationOfCreationOfContract = New CallbackDescription("AfterContractIsCreatedEnd", SalesClient, AdditionalParameters);
	
	OpenForm(ContractFormName, FormParameters, Form, Form.UUID,,,NotificationOfCreationOfContract);
	
EndProcedure

// Processing the notification after creating the Contract from the document form.
//
//Parameters:
// Result - Structure:
//  *Contract - CatalogRef.CounterpartyContracts - a Contract has been CREATED.
// AdditionalParameters - Structure:
//  *Object - ClientApplicationForm - the form of the document.
//  *Partner - CatalogRef.Partners - The partner from the document.
//  *PathToContract - String - the path to the Attribute with the Contract data.
//  *NameOfAlertEvent - String - name of the form event when the Contract was changed.
//  *Contract - CatalogRef.CounterpartyContracts - the selected Contract.
//
Procedure AfterContractIsCreatedEnd(Result, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("Contract") And ValueIsFilled(AdditionalParameters.Contract)
		And AdditionalParameters.Property("Partner") Then
		ErrorMessage = "";
		SelectedContract = AdditionalParameters.Contract;
		If SalesServerCall.CheckSelectionAndPartnerData(SelectedContract, AdditionalParameters.Filter, AdditionalParameters.Partner, ErrorMessage) Then
			DocumentData = TMCommonUseClientServer.DataForAssignment(AdditionalParameters.Object,
				AdditionalParameters.PathToContract);
			DocumentData.Data[DocumentData.Name] = SelectedContract;
			Notify(AdditionalParameters.NameOfAlertEvent, DocumentData.Name, AdditionalParameters.Object);
		Else
			ShowMessageBox(,ErrorMessage);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FormationOfSetOfDocuments

// Procedure for creating a set of documents based on the "customer Order" document"
//
// Parameters:
// 	Result - Arbitrary
// 	AdditionalParameters - Structure:
// 		* ReferencesArrray - Array of DocumentRef.SalesOrder
// 		* Form - ClientApplicationForm - must have service Attributes:
// 			** EquipmentTable - FormDataCollection
// 			** ToCancelTheBatchFormation - Boolean
//
Procedure GenerateSetOfDocumentsChallenge(Result, AdditionalParameters) Export
	
	ReferencesArrray = New Array();
	
	If Not AdditionalParameters.Property("ReferencesArrray", ReferencesArrray) Then
		Raise NStr("vi = 'Chưa chọn chứng từ nào mà có thể tạo nó.';
					|ru = 'Не выбрано ни одного документа, который можно было бы оформить.';
					|en = 'No document which could be registered is selected.'; fa = 'No document which could be registered is selected.';
					|it = 'Non è stato selezionato alcun documento da formalizzare.';
					|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować.';
					|tr = 'Düzenlenebilecek hiçbir belge seçilmedi.'");
	EndIf;
	
	If Not AdditionalParameters.Property("ObjectKey") Then
		AdditionalParameters.Insert("ObjectKey", "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices/CurrentData");
	EndIf;
	
	ArrangeShipment = ThisIsShipmentOfItems(AdditionalParameters);
	AdditionalParameters.Insert("ComplianceWithOrders", InitializeOrders(ReferencesArrray, ArrangeShipment));
	
	AdditionalParameters.Insert("GenerationParameters", DocumentGenerationParameters(AdditionalParameters));
	
	If Not AdditionalParameters.GenerationParameters.TheDesignSettingsAreSaved Then
		Notification = New CallbackDescription("GenerateSetOfDocumentsCompletion", ThisObject, AdditionalParameters);
		OpenSettingParametersForm(Notification, AdditionalParameters);
		Return;
	EndIf;
	
	If StartConnectingEquipmentForDocumentFiscalization(Result, AdditionalParameters) Then
		Return;
	EndIf;
	
	GenerateSetOfDocuments(AdditionalParameters.Form, 
								   AdditionalParameters.ComplianceWithOrders, 
								   AdditionalParameters.GenerationParameters);
	
EndProcedure

Procedure GenerateSetOfDocuments(Form, ComplianceWithOrders, GenerationParameters = Undefined, AccumulatedListOfErrors = Undefined) Export
	
	ClearMessages();
	
	// Selecting an action option and returning the result in the form of the name of the form to be opened and its incoming parameters.
	ArrangeShipment = ThisIsShipmentOfItems(GenerationParameters);
	If ArrangeShipment = False Then
		ParametersOfCreatedDocuments = SalesServerCall.IssueInvoiceOnServer(ComplianceWithOrders, GenerationParameters);
	Else
		ParametersOfCreatedDocuments = SalesServerCall.ArrangeShipmentATServer(ComplianceWithOrders, GenerationParameters);
	EndIf;
	
	GenerationParameters.Insert("ComplianceWithOrders", ComplianceWithOrders);
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("GenerationParameters", GenerationParameters);
	AdditionalParameters.Insert("ParametersOfCreatedDocuments", ParametersOfCreatedDocuments);
	AdditionalParameters.Insert("EquipmentTable");
	AdditionalParameters.Insert("Form", Form);
	
	If ValueIsFilled(AccumulatedListOfErrors) Then
		If ParametersOfCreatedDocuments.ErrorList = Undefined Then
			ParametersOfCreatedDocuments.ErrorList = New Array;
		EndIf;	
		For Each ErrorMessage In AccumulatedListOfErrors Do
			ParametersOfCreatedDocuments.ErrorList.Insert(0, ErrorMessage);
		EndDo;
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(AdditionalParameters.Form, "EquipmentTable") Then
		AdditionalParameters.EquipmentTable = AdditionalParameters.Form.EquipmentTable;
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(AdditionalParameters.Form, "ToCancelTheBatchFormation") Then
		AdditionalParameters.Form.ToCancelTheBatchFormation = False;
	EndIf;
	
	If ParametersOfCreatedDocuments.Property("IssueNumberOfInvoices") And ParametersOfCreatedDocuments.IssueNumberOfInvoices Then
		
		If GenerationParameters.FiscalizationIsAvailable And GenerationParameters.FiscalizationIsRequired Then
			// in the event that fiscalization is required, we will form and fiscalize each package separately
			
			CallbackDescription = New CallbackDescription("MakeSaleOnClientEnd", ThisObject, AdditionalParameters);
			
			ListOfLongRunningOperations = New ValueList;
			
			ParametersForFormOfLongTermOperations = New Structure;
			ParametersForFormOfLongTermOperations.Insert("ListOfActions", ListOfLongRunningOperations);
			ParametersForFormOfLongTermOperations.Insert("NumberOfActions", ParametersOfCreatedDocuments.NumberOfPackages_);
			ParametersForFormOfLongTermOperations.Insert("CurActionNumber", 1);
			
			OpenForm("DataProcessor.LogOfSalesDocuments.Form.TimeConsumingOperation",ParametersForFormOfLongTermOperations,
									Form,,,,CallbackDescription);
			
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
			IdleParameters.OutputIdleWindow = False;
			
			AdditionalParameters.Insert("ListOfLongRunningOperations", ListOfLongRunningOperations);
			AdditionalParameters.Insert("IdleParameters", IdleParameters);
			AdditionalParameters.Insert("ParametersForFormOfLongTermOperations", ParametersForFormOfLongTermOperations);
			
			TimeConsumingOperation = SalesServerCall.IssueNumberOfInvoicesAccordingToTablesCall(ParametersOfCreatedDocuments, 
									GenerationParameters, ParametersForFormOfLongTermOperations.CurActionNumber);
			ListOfLongRunningOperations.Add(TimeConsumingOperation);
			
			DescriptionOfAlertFollowingDocument = New CallbackDescription("StartProcessingFollowingDocument", ThisObject, AdditionalParameters);
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, DescriptionOfAlertFollowingDocument, IdleParameters);
			
			Notify("AddedNewAction", ParametersForFormOfLongTermOperations);
			
		Else
			// if fiscalization is not needed, then we will form the documents at once in one block
			TimeConsumingOperation = SalesServerCall.IssueNumberOfInvoicesAccordingToTablesCall(ParametersOfCreatedDocuments, GenerationParameters);
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
			CallbackDescription = New CallbackDescription("MakeSaleOnClientEnd", ThisObject, AdditionalParameters);
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
		EndIf;
	Else // if one order
		If GenerationParameters.FiscalizationIsAvailable And GenerationParameters.FiscalizationIsRequired And Not GenerationParameters.ByNotes Then
			FiscalizeDocuments(Undefined, AdditionalParameters);
		EndIf;
		MakeSaleOnClientEnd(Undefined, AdditionalParameters);
	EndIf;
	
EndProcedure

Procedure GenerateSetOfDocumentsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SalesServerCall.SaveDocumentSetSettings(Result, AdditionalParameters.ObjectKey);
	
	AdditionalParameters.Insert("GenerationParameters", DocumentGenerationParameters(AdditionalParameters));
	
	If StartConnectingEquipmentForDocumentFiscalization(Result, AdditionalParameters) Then
		Return;
	EndIf;
	
	GenerateSetOfDocuments(AdditionalParameters.Form, 
								   AdditionalParameters.ComplianceWithOrders, 
								   AdditionalParameters.GenerationParameters);
	
EndProcedure

Procedure StartProcessingFollowingDocument(Result, AdditionalParameters) Export
	
	ActionCancelled = AdditionalParameters.Form.ToCancelTheBatchFormation;
	
	If ActionCancelled Then 
		If AdditionalParameters.ParametersOfCreatedDocuments.ErrorList = Undefined Then
			AdditionalParameters.ParametersOfCreatedDocuments.ErrorList = New Array;
		EndIf;
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Người sử dụng đã hủy thao tác.';
							|ru = 'Действие отменено пользователем.';
							|en = 'The operation was canceled by the user.'; fa = 'The operation was canceled by the user.';
							|it = 'L''azione è stata annullata dall''utente.';
							|pl = 'Operacja została anulowana przez użytkownika.';
							|tr = 'Eylem kullanıcı tarafından iptal edildi.'");
		AdditionalParameters.ParametersOfCreatedDocuments.ErrorList.Add(Message);
		ReportErrorsToUser(AdditionalParameters.ParametersOfCreatedDocuments.ErrorList);
		Return;
	EndIf;
	
	AdditionalParameters.ParametersForFormOfLongTermOperations.CurActionNumber = AdditionalParameters.ParametersForFormOfLongTermOperations.CurActionNumber + 1;
	
	If AdditionalParameters.ParametersForFormOfLongTermOperations.CurActionNumber <= AdditionalParameters.ParametersForFormOfLongTermOperations.NumberOfActions Then
		
		TimeConsumingOperation = SalesServerCall.IssueNumberOfInvoicesAccordingToTablesCall(AdditionalParameters.ParametersOfCreatedDocuments, 
					AdditionalParameters.GenerationParameters, AdditionalParameters.ParametersForFormOfLongTermOperations.CurActionNumber);
		AdditionalParameters.ListOfLongRunningOperations.Add(TimeConsumingOperation);
		
		DescriptionOfFiscalizeDocumentsAlert = New CallbackDescription("StartProcessingFollowingDocument", ThisObject, AdditionalParameters);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, DescriptionOfFiscalizeDocumentsAlert, AdditionalParameters.IdleParameters);
		
		Notify("AddedNewAction", AdditionalParameters.ParametersForFormOfLongTermOperations);
		
	EndIf;
	
	FiscalizeDocuments(Result, AdditionalParameters);
	
EndProcedure

Procedure MakeSaleOnClientEnd(Result, AdditionalParameters) Export
	
	ParametersOfCreatedDocuments = SalesServerCall.ReadDataFromSecureStorage("FormCreatedSalesDocuments");
	If Result = Undefined And ParametersOfCreatedDocuments = Undefined Then // the background task has been canceled.
		ParametersOfCreatedDocuments = AdditionalParameters.ParametersOfCreatedDocuments;
		GenerationParameters = AdditionalParameters.GenerationParameters;
	Else
		If TypeOf(ParametersOfCreatedDocuments) = Type("Array") Then
			ParametersOfCreatedDocuments = AdditionalParameters.ParametersOfCreatedDocuments;
			GenerationParameters = AdditionalParameters.GenerationParameters;
		Else
			If ParametersOfCreatedDocuments = Undefined Then
				CommonClient.MessageToUser(Result.BriefErrorDescription);
				Return;
			Else
				GenerationParameters = ParametersOfCreatedDocuments.GenerationParameters;
			EndIf;
		EndIf;
	EndIf;
	
	CreatedDocuments = New Array;
	ThereIsPropertyCreatedDocuments = False;
	ThereAreErrorsInCreatingDocuments = False;
	HasErrors = False;
	If ParametersOfCreatedDocuments.Property("Parameters") Then
		If ParametersOfCreatedDocuments.Parameters.Property("CreatedDocuments") Then
			ThereIsPropertyCreatedDocuments = True;
			CreatedDocuments = ParametersOfCreatedDocuments.Parameters.CreatedDocuments;
		ElsIf ParametersOfCreatedDocuments.Parameters.Property("Basis") 
				  And ParametersOfCreatedDocuments.Parameters.Basis.Property("CreatedDocuments") Then
			ThereIsPropertyCreatedDocuments = True;
			CreatedDocuments = ParametersOfCreatedDocuments.Parameters.Basis.CreatedDocuments;
		EndIf;
		For Each Item In CreatedDocuments Do
			If TypeOf(Item) = Type("Structure") And Item.Property("HasErrors",HasErrors) And HasErrors = True Then
				Break;
			EndIf; 
		EndDo;
		ThereAreErrorsInCreatingDocuments = (HasErrors = True);
	EndIf;
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, 
				ThisObject,
				ParametersOfCreatedDocuments),
			ParametersOfCreatedDocuments.TextOfQuestionToUser,
			QuestionDialogMode.YesNo);
	ElsIf ParametersOfCreatedDocuments.Property("FormName") 
			And (Not GenerationParameters.DoNotOpenFormOfCreatedDocument 
				Or (GenerationParameters.DoNotOpenFormOfCreatedDocument And ThereAreErrorsInCreatingDocuments)
				Or ParametersOfCreatedDocuments.FormName = "CommonForm.ReregisterInvoicesByReferences") Then
		
		If ThereIsPropertyCreatedDocuments Then
			
			NotificationText1 = NStr("vi = 'Chứng từ đã tạo: %1';
									|ru = 'Создано документов: %1';
									|en = 'Created documents: %1'; fa = 'Created documents: %1';
									|it = 'Documenti creati: %1';
									|pl = 'Utworzono dokumentów: %1';
									|tr = 'Oluşturulan belgeler: %1'");
			If CreatedDocuments.Count() > 0 Then
				NotificationText1 = StrTemplate(NotificationText1, CreatedDocuments.Count());
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Notify("IssuedSalesDocument", , AdditionalParameters.Form);
			Else
				NotificationText1 = StrTemplate(NotificationText1, 0);
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Notify("IssuedSalesDocument", , AdditionalParameters.Form);
				ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
				Return;
			EndIf;
			
		EndIf;
		OpenForm(ParametersOfCreatedDocuments.FormName, 
			ParametersOfCreatedDocuments.Parameters);
	ElsIf ParametersOfCreatedDocuments.Property("DocumentPrintingMode") Then
		
		ArrayOfPrintedDocuments = New Array;
		
		For Each CurItem In CreatedDocuments Do
			If Not (CurItem.Posted And GenerationParameters.DoNotOpenFormOfCreatedDocument) Then
				
				If TypeOf(CurItem.Document) = Type("DocumentRef.CustomerInvoice") Then
					OpenForm("Document.CustomerInvoice.Form.DocumentForm", New Structure("Key", CurItem.Document));
				ElsIf TypeOf(CurItem.Document) = Type("DocumentRef.CustomerInvoice") Then
					OpenForm("Document.TransferOfGoodsToBailee.Form.DocumentForm", New Structure("Key", CurItem.Document));
				ElsIf TypeOf(CurItem.Document) = Type("DocumentRef.CustomerInvoiceServices") Then 
					OpenForm("Document.CustomerInvoiceServices.Form.DocumentForm", New Structure("Key", CurItem.Document));
				ElsIf TypeOf(CurItem.Document) = Type("DocumentRef.GoodsShipmentFromStorage") Then 
					OpenForm("Document.GoodsShipmentFromStorage.Form.DocumentForm", New Structure("Key", CurItem.Document));
				EndIf;
				
			EndIf;
			
			If CurItem.Posted And CurItem.Print Then
				
				ArrayOfPrintedDocuments.Add(CurItem.Document);
				
			EndIf;
			
		EndDo;
		If CreatedDocuments.Count() > 0 Then
			
			If ArrayOfPrintedDocuments.Count() > 0 Then
				PrintManagementClient.ExecutePrintToPrinterCommand(
					"InformationRegister.ObjectPrintSettings",
					"SetOfDocuments",
					ArrayOfPrintedDocuments,
					New Structure());
				MessageText = NStr("vi = 'Đã tạo và in chứng từ (%DocumentsCount%)';
									|ru = 'Документы созданы и напечатаны (%DocumentsCount%)';
									|en = 'Documents are created and printed (%DocumentsCount%)'; fa = 'Documents are created and printed (%DocumentsCount%)';
									|it = 'I documenti sono creati e stampati (%DocumentsCount%)';
									|pl = 'Dokumenty zostały utworzone i wydrukowane (%DocumentsCount%)';
									|tr = 'Belgeler oluşturuldu ve yazdırıldı (%DocumentsCount%)'");
			Else
				MessageText = NStr("vi = 'Đã tạo chứng từ (%DocumentsCount%)';
									|ru = 'Документы созданы (%DocumentsCount%)';
									|en = 'Documents are created (%DocumentsCount%)'; fa = 'Documents are created (%DocumentsCount%)';
									|it = 'I documenti sono creati (%DocumentsCount%)';
									|pl = 'Dokumenty zostały utworzone (%DocumentsCount%)';
									|tr = 'Belgeler oluşturuldu (%DocumentsCount%)'");
			EndIf;
				
			ShowUserNotification(
				StrReplace(MessageText, "%DocumentsCount%", CreatedDocuments.Count()),
				,,
				PictureLib.Information32);
			
			Notify("IssuedSalesDocument", , AdditionalParameters.Form);
			
		EndIf;
	EndIf;
	
	ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
EndProcedure

// Returns matching structures for passed orders
// 
// Parameters:
// 	ReferenceList - Array of DocumentRef.SalesOrder
// 	ArrangeShipment - Boolean - The sign of the shipment of goods
// 	
// Returns:
// 	Map - Where:
// 		* Key - DocumentRef.SalesOrder
// 		* Value - Structure - Where:
// 			** InvoiceStatus - Number
// 			** NoteState - Number
// 
Function InitializeOrders(ReferenceList, ArrangeShipment) Export
	
	ComplianceWithOrders = New Map;
	If TypeOf(ReferenceList) = Type("Array") Then
		// if the call is from the list form or the "Customer Order" document form
		For Each Ref In ReferenceList Do
			If TypeOf(Ref) = Type("Structure") Then
				ComplianceWithOrders.Insert(Ref.Ref, Ref);
			Else
				Structure = New Structure;
				Structure.Insert("Ref", Ref);
				Structure.Insert("InvoiceStatus", 1);
				Structure.Insert("NoteState", 1);
				ComplianceWithOrders.Insert(Ref, Structure);
			EndIf;
		EndDo;
	ElsIf TypeOf(ReferenceList) = Type("FormDataCollection") Then
		// if the call is out of processing
		For Each String In ReferenceList Do
			Structure = New Structure;
			If TypeOf(String.Ref) = Type("DocumentRef.SalesOrder")
				And String.SplitInvoiceByWarehouses Then
				Var_Key = New Structure;
				Var_Key.Insert("DocumentBasis", String.Ref);
				Var_Key.Insert("Warehouse", String.Warehouse);
			Else
				Var_Key = String.Ref;
			EndIf;

			Structure.Insert("InvoiceStatus", String.InvoiceStatus);
			Structure.Insert("NoteState", String.NoteState);
			
			If ArrangeShipment = True Then
				Structure.InvoiceStatus = String.ShipmentStatus;
				Structure.NoteState = String.StateOfShipmentOrder;
				
				If Not TypeOf(Var_Key) = Type("Structure") Then
					FoundOrder = ComplianceWithOrders.Get(Var_Key);
					If Not FoundOrder = Undefined Then
						If Structure.InvoiceStatus > FoundOrder.InvoiceStatus Then
							Structure.InvoiceStatus = FoundOrder.InvoiceStatus;
						EndIf;
						
						If Structure.NoteState > FoundOrder.NoteState Then
							Structure.NoteState = FoundOrder.NoteState;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			ComplianceWithOrders.Insert(Var_Key, Structure);
		EndDo;
	EndIf;
	
	Return ComplianceWithOrders;
	
EndFunction

Function DocumentGenerationParameters(AdditionalParameters)
	
	GenerationParameters = SalesServerCall.GetASetOfDocumentsSetup(AdditionalParameters.ObjectKey);
	
	ByNotes = False;
	If AdditionalParameters.Property("ByNotes") Then
		ByNotes = AdditionalParameters.ByNotes;
	EndIf;
	GenerationParameters.Insert("ByNotes", ByNotes);
	
	If AdditionalParameters.Property("ArrangeShipment") Then
		GenerationParameters.ArrangeShipment = AdditionalParameters.ArrangeShipment;
	EndIf;
	
	If AdditionalParameters.Property("NameOfShipmentCommand") Then
		GenerationParameters.NameOfShipmentCommand = AdditionalParameters.NameOfShipmentCommand;
	EndIf;
		
	Warehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");
	If AdditionalParameters.Property("Warehouse") Then
		Warehouse = AdditionalParameters.Warehouse;
	EndIf;
	GenerationParameters.Insert("Warehouse", Warehouse);
	
	NamesOfDocumentSetDesignParameters = New Array;
	NamesOfDocumentSetDesignParameters.Add("CreateSalesDocument");
	NamesOfDocumentSetDesignParameters.Add("TheDesignSettingsAreSaved");
	NamesOfDocumentSetDesignParameters.Add("NameOfFormCreatedDocuments");
	
	//Parameters of the "General form.The form of the created documents"
	NamesOfDocumentSetDesignParameters.Add("VisibleColumns");
	NamesOfDocumentSetDesignParameters.Add("UpdateEvents");
	
	For Each ParameterName In NamesOfDocumentSetDesignParameters Do
		
		If Not AdditionalParameters.Property(ParameterName) Then
			Continue;
		EndIf;
		
		FillPropertyValues(GenerationParameters, AdditionalParameters, ParameterName);
		
	EndDo;
	
	GenerationParameters.Insert("UUID", AdditionalParameters.Form.UUID);
	
	If AdditionalParameters.Property("CheckWarehouses") Then
		GenerationParameters.Insert("CheckWarehouses", AdditionalParameters.CheckWarehouses);
	EndIf;
	
	Return GenerationParameters;
	
EndFunction

Procedure OpenSettingParametersForm(Notification, AdditionalParameters)
	
	FormParameters = SalesServerCall.GetASetOfDocumentsSetup(AdditionalParameters.ObjectKey);
	OpenForm("DataProcessor.LogOfSalesDocuments.Form.ParametersOfSalesDocumentCreation", FormParameters,
		AdditionalParameters.Form, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Displays errors accumulated by the add error method to the User.
//
// Parameters:
//  Errors - Array of UserMessage
//  Cancel - Boolean - set to True if errors were reported.
//
Procedure ReportErrorsToUser(Errors, Cancel = False) Export
	
	If Errors = Undefined Then
		Return;
	EndIf;
	Cancel = (Errors.Count()>0);
	
	For Each Error In Errors Do
		Error.Message();
	EndDo;
	
EndProcedure

#Region Fiscalization

Function StartConnectingEquipmentForDocumentFiscalization(Result, AdditionalParameters)
	
	Result = False;
	If AdditionalParameters.GenerationParameters.IssueAFiscalReceipt
		And Not AdditionalParameters.GenerationParameters.ByNotes
		And CommonClientServer.HasAttributeOrObjectProperty(AdditionalParameters.Form, "EquipmentTable") Then
		
		SalesServerCall.ToSupplementStructureOfOrdersAndFormationParameters(AdditionalParameters.ComplianceWithOrders
																				, AdditionalParameters.GenerationParameters);
		
		If AdditionalParameters.GenerationParameters.FiscalizationIsRequired Then
			If AdditionalParameters.GenerationParameters.FiscalizationIsAvailable Then
			    Result = True;
				
				AdditionalParameters.Form.EquipmentTable.Clear();
				EquipmentTable	= AdditionalParameters.Form.EquipmentTable;
				OrderData_3 = New Array;
				For Each Item In AdditionalParameters.ComplianceWithOrders Do
					If Item.Value.Fiscalize Then
						OrderData_3.Add(Item.Value);
					EndIf;
				EndDo;
				SalesServerCall.GetConnectedHardware(OrderData_3, EquipmentTable);

				AdditionalParameters.Insert("UsedEquipment", UsedEquipment(EquipmentTable));
				AdditionalParameters.Insert("EquipmentTable", EquipmentTable);
				AdditionalParameters.Insert("ErrorsWhenConnectingEquipment", Undefined);

				For Each DocumentStructure In OrderData_3 Do
					HardwareSearchStructure = New Structure ("Organization, CashAccount", DocumentStructure.Organization, DocumentStructure.CashAccount);
					FoundEquipment = EquipmentTable.FindRows(HardwareSearchStructure);
					If FoundEquipment.Count() = 0 Then
						
						MessageText = NStr("vi = 'Khi nhận dữ liệu về thiết bị kết nối, đã xảy ra lỗi. Không tìm thấy thiết bị kết nối.
													|Mô tả bổ sung:
													|Doanh nghiệp: %Organization%
													|Quỹ tiền mặt: %CashAccount%';
													|ru = 'При получении данных о подключенном оборудовании произошла ошибка. Не найдено подключенное оборудование.
													|Дополнительное описание:
													|Организация: %Organization%
													|Касса: %CashAccount%';
													|en = 'An error occurred when getting peripheral data. A peripheral is not found.
													|Additional details:
													|Company: %Organization%
													|Cash register: %CashAccount%'; fa = 'An error occurred when getting peripheral data. A peripheral is not found.
													|Additional details:
													|Company: %Organization%
													|Cash register: %CashAccount%';
													|it = 'При получении данных о подключенном оборудовании произошла ошибка. Не найдено подключенное оборудование.
													|Дополнительное описание:
													|Организация: %Organization%
													|Касса: %CashAccount%';
													|pl = 'An error occurred when getting peripheral data. A peripheral is not found.
													|Additional details:
													|Company: %Organization%
													|Cash register: %CashAccount%';
													|tr = 'Bağlı ekipman hakkında bilgi alınırken hata oluştu. Bağlı ekipman bulunamadı.
													|Ek ayrıntılar:
													|İş yeri: %Organization%
													|Kasa: %CashAccount%'");
						
						MessageText = StrReplace(
							MessageText,
							"%Organization%",
							DocumentStructure.Organization);

						MessageText = StrReplace(
							MessageText,
							"%CashAccount%",
							DocumentStructure.CashAccount);
							
						CommonClientServer.AddUserError(AdditionalParameters.ErrorsWhenConnectingEquipment, 
							"", MessageText, Undefined);
								
					EndIf;
				EndDo;
				
				ConnectEquipmentForFiscalizationOfDocumentsContinue(New Structure, AdditionalParameters);
				
			Else
				Raise NStr("vi = 'Trong tùy chỉnh tạo bộ chứng từ có đặt dấu hiệu ""Đánh phiếu tài chính"".
											|Để thực hiện điều này, cần cho phép sử dụng bán lẻ và thiết bị kết nối.';
											|ru = 'В настройках создания комплектов документов установлен признак ""Пробивать фискальный чек"".
											|Для этого необходимо разрешить использование розничных продаж и подключаемого оборудования.';
											|en = 'In the settings to create document sets, the ""Issue a fiscal receipt"" check box is selected.
											|To apply it, allow using retail sales and peripherals.'; fa = 'In the settings to create document sets, the ""Issue a fiscal receipt"" check box is selected.
											|To apply it, allow using retail sales and peripherals.';
											|it = 'В настройках создания комплектов документов установлен признак ""Пробивать фискальный чек"".
											|Для этого необходимо разрешить использование розничных продаж и подключаемого оборудования.';
											|pl = 'In the settings to create document sets, the ""Issue a fiscal receipt"" check box is selected.
											|To apply it, allow using retail sales and peripherals.';
											|tr = 'Belge setleri oluşturma ayarlarında, ""Mali fişi yazdır"" bayrağı ayarlanır.
											|Bunu yapmak için, perakende satışların ve bağlı ekipmanların kullanımını etkinleştirmeniz gerekir.'");
			EndIf;
		EndIf;
	EndIf;
	
	Return Result;
		
EndFunction

Procedure ConnectEquipmentForFiscalizationOfDocumentsContinue(Result, AdditionalParameters) Export
	
	AbortExecution = False;
	If TypeOf(Result) = Type("Structure") Then
		If Result.Property("ErrorDescription") And ValueIsFilled(Result.ErrorDescription) Then
			CommonClientServer.AddUserError(AdditionalParameters.ErrorsWhenConnectingEquipment, 
				"", Result.ErrorDescription, Undefined);
		EndIf;
	Else
		AbortExecution = True;
		ErrorDescription = NStr("vi = 'Khi kết nối thiết bị đã xảy ra lỗi không xác định. Không thể tiếp tục giao dịch, hãy liên hệ với người quản trị.';
								|ru = 'При подключении оборудования возникла неизвестная ошибка. Продолжение операции невозможно, обратитесь к администратору.';
								|en = 'An unknown error occurred when connecting the peripherals. Cannot proceed with the operation. Contact the administrator.'; fa = 'An unknown error occurred when connecting the peripherals. Cannot proceed with the operation. Contact the administrator.';
								|it = 'При подключении оборудования возникла неизвестная ошибка. Продолжение операции невозможно, обратитесь к администратору.';
								|pl = 'An unknown error occurred when connecting the peripherals. Cannot proceed with the operation. Contact the administrator.';
								|tr = 'Ekipman bağlanırken bilinmeyen hata oluştu. İşleme devam edilemiyor, yöneticinizle iletişime geç.'");
		CommonClientServer.AddUserError(AdditionalParameters.ErrorsWhenConnectingEquipment, 
			"", ErrorDescription, Undefined);
	EndIf;
	
	UsedEquipment = New Array;
	If AdditionalParameters.UsedEquipment.Count() And Not AbortExecution Then
		Peripherals = AdditionalParameters.UsedEquipment[AdditionalParameters.UsedEquipment.UBound()];
		AdditionalParameters.UsedEquipment.Delete(AdditionalParameters.UsedEquipment.UBound());
		UsedEquipment.Add(Peripherals);
	EndIf;
	
	If UsedEquipment.Count() Then
		NotificationOFEndOfStatusSETTING = New CallbackDescription("ConnectEquipmentForFiscalizationOfDocumentsContinue", ThisObject, AdditionalParameters);
		TMPeripheralsClient.SetHardwareConnectionStatus(
			True,
			New Structure("UUID", AdditionalParameters.GenerationParameters.UUID),
			UsedEquipment,
			AdditionalParameters.EquipmentTable,
			NotificationOFEndOfStatusSETTING);
	Else
		NotificationOFEndOfStatusSETTING = New CallbackDescription("ConnectEquipmentForFiscalizationOfDocumentsEnd", ThisObject, AdditionalParameters);
		HardwareConnectionResult = (Not AbortExecution);
		RunCallback(NotificationOFEndOfStatusSETTING, HardwareConnectionResult);
	EndIf;
	
EndProcedure

Procedure ConnectEquipmentForFiscalizationOfDocumentsEnd(Result, AdditionalParameters) Export
	
	If Result = True Then
		AdditionalParameters.Insert("Peripherals_", AdditionalParameters.EquipmentTable.FindRows(New Structure("Attached", True)));
		ProcessStateOfSHIFTForFiscalizationOfDocuments(True, AdditionalParameters);
	Else
		CommonClientServer.ReportErrorsToUser(AdditionalParameters.ErrorsWhenConnectingEquipment);
	EndIf;
	
EndProcedure

Procedure ProcessStateOfSHIFTForFiscalizationOfDocuments(Result, AdditionalParameters) Export
	
	AbortExecution = False;
	If Result = False Then
		AbortExecution = True;	
		ErrorDescription = NStr("vi = 'Khi xử lý trạng thái phiên làm việc, đã xảy ra lỗi. Không thể tiếp tục giao dịch, hãy liên hệ với người quản trị.';
								|ru = 'При обработке состояния смены возникла ошибка. Продолжение операции невозможно, обратитесь к администратору.';
								|en = 'An error occurred when processing the shift state. Cannot proceed with the operation. Contact the administrator.'; fa = 'An error occurred when processing the shift state. Cannot proceed with the operation. Contact the administrator.';
								|it = 'При обработке состояния смены возникла ошибка. Продолжение операции невозможно, обратитесь к администратору.';
								|pl = 'An error occurred when processing the shift state. Cannot proceed with the operation. Contact the administrator.';
								|tr = 'Vardiya durumu işlenirken hata oluştu. İşleme devam edilemiyor, yöneticinizle iletişime geç.'");
		CommonClientServer.AddUserError(AdditionalParameters.ErrorsWhenConnectingEquipment, 
			"", ErrorDescription, Undefined);
	EndIf;
	
	Peripherals_ = Undefined;
	If AdditionalParameters.Peripherals_.Count() And Not AbortExecution Then
		Peripherals_ = AdditionalParameters.Peripherals_[AdditionalParameters.Peripherals_.UBound()].Equipment;
		AdditionalParameters.Peripherals_.Delete(AdditionalParameters.Peripherals_.UBound());
	EndIf;
	
	If ValueIsFilled(Peripherals_) Then
		NotificationOFEndOfSHIFTStatePROCESSING = New CallbackDescription("ProcessStateOfSHIFTForFiscalizationOfDocuments", ThisObject, AdditionalParameters);
		RetailSalesClient.HandleShiftStateAutomatically(Peripherals_, NotificationOFEndOfSHIFTStatePROCESSING);
	Else
		NotificationOFEndOfSHIFTStatePROCESSING = New CallbackDescription("ProcessStateOfSHIFTForFiscalizationOfDocumentsCompletion", ThisObject, AdditionalParameters);			
		StateProcessingRESULT = (Not AbortExecution);
		RunCallback(NotificationOFEndOfSHIFTStatePROCESSING, StateProcessingRESULT);
	EndIf;
	
EndProcedure

Procedure ProcessStateOfSHIFTForFiscalizationOfDocumentsCompletion(Result, AdditionalParameters) Export
	
	AccumulatedListOfErrors = Undefined;
	If AdditionalParameters.Property("ErrorsWhenConnectingEquipment") 
		And ValueIsFilled(AdditionalParameters.ErrorsWhenConnectingEquipment) Then
		
		AccumulatedListOfErrors = New Array;
		For Each UserMessage In AdditionalParameters.ErrorsWhenConnectingEquipment.ErrorList Do
			If UserMessage.RowIndex = Undefined Then
				RowIndex = UserMessage.LineNumber;
			Else
				RowIndex = UserMessage.RowIndex;
			EndIf;
			
			Message = CommonInternalClientServer.UserMessage(
							UserMessage.SingleErrorText,
							Undefined,
							StrReplace(UserMessage.ErrorField, "%1", Format(RowIndex, "NZ=0; NG=")));
							
			AccumulatedListOfErrors.Add(Message);
		EndDo;
	EndIf;
	
	If Result = True Then
		GenerateSetOfDocuments(AdditionalParameters.Form, 
									   AdditionalParameters.ComplianceWithOrders, 
									   AdditionalParameters.GenerationParameters,
									   AccumulatedListOfErrors);
	EndIf;
	
EndProcedure

Procedure FiscalizeDocuments(Result, AdditionalParameters) Export
	
	GenerationParameters			= AdditionalParameters.GenerationParameters;
	EquipmentTable				= AdditionalParameters.EquipmentTable;
	If Result = Undefined Then
		ParametersOfCreatedDocuments 	= AdditionalParameters.ParametersOfCreatedDocuments;//Structure
		If ParametersOfCreatedDocuments.Property("Parameters") Then
			CreatedDocuments				= ParametersOfCreatedDocuments.Parameters.Basis.CreatedDocuments;
		Else
			// documents not created
			Return;
		EndIf;
	Else
		ParametersOfCreatedDocuments 	= GetFromTempStorage(Result.ResultAddress);//Structure
		CreatedDocuments				= ParametersOfCreatedDocuments.Parameters.CreatedDocuments;
	EndIf;
	
	If CreatedDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	If Not GenerationParameters.Property("DocumentsProcessedOnFiscalDevice") Then
		GenerationParameters.Insert("DocumentsProcessedOnFiscalDevice", New Array);
	EndIf;
	
	SalesServerCall.GetConnectedHardware(CreatedDocuments, EquipmentTable);
	
	TMPeripheralsClient.SetHardwareConnectionStatus(
		True,
		New Structure("UUID", GenerationParameters.UUID),
		UsedEquipment(EquipmentTable),
		EquipmentTable);
		
	For Each StringEquipment In EquipmentTable Do
		If StringEquipment.Attached Then
			RetailSalesClient.HandleShiftStateAutomatically(StringEquipment.Equipment);
		EndIf;
	EndDo; 
	
	For Each DocumentStructure In CreatedDocuments Do
		
		If Not (TypeOf(DocumentStructure) = Type("Structure")) 
			Or Not DocumentStructure.Posted
			Or GenerationParameters.DocumentsProcessedOnFiscalDevice.Find(DocumentStructure.Document) <> Undefined Then
			Continue;
		EndIf; 
			
		If TypeOf(DocumentStructure.ReferenceArray) = Type("Array") Then 
			If DocumentStructure.ReferenceArray.Count() > 0 Then
				ReferenceOrder = DocumentStructure.ReferenceArray[0];
			Else
				Continue;
			EndIf;
		Else
			ReferenceOrder = DocumentStructure.ReferenceArray;
		EndIf;
			
		TypeOfGNRDocument = TypeOf(DocumentStructure.Document);
		
		If TypeOfGNRDocument = Type("DocumentRef.CustomerInvoice")
			Or TypeOfGNRDocument = Type("DocumentRef.CustomerInvoiceServices")
			Or TypeOfGNRDocument = Type("DocumentRef.CashAccountReceiptNote") Then
			
			DocumentReferenceOrder = GenerationParameters.ComplianceWithOrders.Get(ReferenceOrder);
			If Not DocumentReferenceOrder.Fiscalize Then
				Continue;
			EndIf;
			
			HardwareSearchStructure = New Structure ("Organization, CashAccount, Attached", DocumentStructure.Organization, DocumentStructure.CashAccount, True);
			FoundEquipment = EquipmentTable.FindRows(HardwareSearchStructure);
			If FoundEquipment.Count() > 0 Then
				Equipment = FoundEquipment[0].Equipment;
			EndIf;
			
			If Not ValueIsFilled(Equipment) Then
				Continue;
			EndIf;
			
			ParametersOfReceiptFiscalizationOperation = GeneratingFiscalChecksServerCall.ParametersOfReceiptFiscalizationOperationBatchMode(
																DocumentStructure.Document, Equipment);
			
			If ParametersOfReceiptFiscalizationOperation = Undefined Then
				Continue;
			EndIf;
			
			GenerationParameters.DocumentsProcessedOnFiscalDevice.Add(DocumentStructure.Document);
			
			NotificationOnCompletion = New CallbackDescription("PrintingReceipt_Completion", ThisObject, AdditionalParameters);
			
			PeripheralsReceiptPrintersClient.StartCheckFiscalizationOnFiscalDevice(
				NotificationOnCompletion,
				GenerationParameters.UUID,
				Equipment,
				ParametersOfReceiptFiscalizationOperation);
			
		EndIf;
		
	EndDo;

EndProcedure

Procedure PrintingReceipt_Completion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		FiscalizationParameters = Undefined;
		
		// If the data was not recorded in the Fiscal Operation register, an error occurred during recording.
		If ExecutionResult.Property("OutputParametersSet") And ExecutionResult.OutputParametersSet.Count() > 8 Then
			FiscalizationParameters = ExecutionResult.OutputParametersSet[8];
		EndIf;
		
		CompletionParameters = New Structure;
		CompletionParameters.Insert("CloseForm",                False);
		CompletionParameters.Insert("Form",                       AdditionalParameters.GenerationParameters.UUID);
		CompletionParameters.Insert("FiscalOperationDetails", FiscalizationParameters);
		CompletionParameters.Insert("NotificationOnCompletion",     New CallbackDescription("IssueCashReceiptCompletion", ThisObject, AdditionalParameters));
		
		// in any case, even with a successful recording, we proceed to perform actions after recording 
		TMPeripheralsClient.PerformActionAfterRecordingFiscalTransactionInLog(
			ThisObject,
			New CallbackDescription("FiscalTransactionIsRecordedInLog", TMPeripheralsClient, CompletionParameters),
			NStr("vi = 'Không thể ghi dữ liệu vào nhật ký thao tác tính tiền.';
				|ru = 'Не удалось записать данные в журнал фискальных операций.';
				|en = 'Cannot save data to the fiscal transactions log.'; fa = 'Cannot save data to the fiscal transactions log.';
				|it = 'Non è stato possibile salvare i dati nel registro delle operazioni fiscali.';
				|pl = 'Nie udało się zapisać dane do dziennika operacji fiskalnych.';
				|tr = 'Mali işlem günlüğüne veri yazılamadı.'"));
		
	Else
		
		MessageText = NStr("vi = 'Khi in phiếu đã xảy ra lỗi.
									|Phiếu chưa được in trên thiết bị ghi nhận tiền mặt:
									|%DeviceID%
									|Mô tả bổ sung:
									|%AdditionalDetails%';
									|ru = 'При печати чека произошла ошибка.
									|Чек не напечатан на фискальном устройстве:
									|%DeviceID%
									|Дополнительное описание:
									|%AdditionalDetails%';
									|en = 'An error occurred when printing the receipt.
									|The receipt is not printed on the fiscal device:
									|%DeviceID%
									|Additional details:
									|%AdditionalDetails%'; fa = 'An error occurred when printing the receipt.
									|The receipt is not printed on the fiscal device:
									|%DeviceID%
									|Additional details:
									|%AdditionalDetails%';
									|it = 'При печати чека произошла ошибка.
									|Чек не напечатан на фискальном устройстве:
									|%DeviceID%
									|Дополнительное описание:
									|%AdditionalDetails%';
									|pl = 'An error occurred when printing the receipt.
									|The receipt is not printed on the fiscal device:
									|%DeviceID%
									|Additional details:
									|%AdditionalDetails%';
									|tr = 'Fiş yazdırılırken hata oluştu.
									|Fiş mali cihazda yazdırılmadı:
									|%DeviceID%
									|Ek ayrıntılar:
									|%AdditionalDetails%'");
		
		MessageText = StrReplace(
			MessageText,
			"%DeviceID%",
			ExecutionResult.DeviceID);

		MessageText = StrReplace(
			MessageText,
			"%AdditionalDetails%",
			ExecutionResult.ErrorDescription);
			
		RetailSalesServerCall.LogEntryLevelError("SalesClient.PrintingReceipt_Completion",,, MessageText);
		
		Message = New UserMessage;
		Message.Text = MessageText;
		Message.Field = "";
		If AdditionalParameters.ParametersOfCreatedDocuments.ErrorList = Undefined Then
			AdditionalParameters.ParametersOfCreatedDocuments.ErrorList = New Array;
		EndIf;
		AdditionalParameters.ParametersOfCreatedDocuments.ErrorList.Add(Message);
	
	EndIf;
	
EndProcedure

Procedure IssueCashReceiptCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
EndProcedure

Function UsedEquipment(EquipmentTable)
	
	UsedEquipment = New Array;
	
	If Not EquipmentTable = Undefined Then
		For Each HardwareTableRow In EquipmentTable Do
			UsedEquipment.Add(HardwareTableRow.Equipment);
		EndDo;
	EndIf;
	
	Return UsedEquipment;
	
EndFunction

#EndRegion 

#EndRegion 

#Region Other

Procedure StartSelectingAgreementWithClientFragment(ParametersStructure)
	
	If Not ValueIsFilled(ParametersStructure.Partner) Then
		Return;
	Else
		FormParameters = New Structure;
		FormParameters.Insert("DocumentDate", ParametersStructure.DocumentDate);
		FormParameters.Insert("Partner", ParametersStructure.Partner);
		FormParameters.Insert("OnlyStandard",ParametersStructure.OnlyStandard);
		FormParameters.Insert("OnlyUsedBySalesRepresentative",ParametersStructure.OnlyUsedBySalesRepresentative);
		FormParameters.Insert("CurrentRow",ParametersStructure.Document);
		FormParameters.Insert("BusinessOperation",ParametersStructure.BusinessOperation);
		FormParameters.Insert("ContractsAreUsed",ParametersStructure.ContractsAreUsed);
		FormParameters.Insert("ConsignmentSales25",ParametersStructure.ConsignmentSales25);
		FormParameters.Insert("ShipmentWithDeferredTransferOfTitle25",ParametersStructure.ShipmentWithDeferredTransferOfTitle25);
		FormParameters.Insert("OnlyTransferOperations",ParametersStructure.OnlyTransferOperations);
		FormParameters.Insert("TransferShipmentOperations",ParametersStructure.TransferShipmentOperations);
		
		AdditionalSelection = New Structure;
		
		For Each ChoiceParameter In ParametersStructure.Item.ChoiceParameters Do
			AdditionalSelection.Insert(StrReplace(ChoiceParameter.Name, "Filter.", ""), ChoiceParameter.Value);
		EndDo;
		
		FormParameters.Insert("Filter", AdditionalSelection);
		
		OpenForm("Catalog.TermsOfSale.ChoiceForm",
			FormParameters,
			ParametersStructure.Item);
	EndIf;
	
EndProcedure

// Returns a list of predefined item types for which you need to specify 
// Department analysis in. Used in sales documents.
// 
// Returns:
// 	ValueList
//
Function TypesOfNomenclatureWithUnitAnalytics() Export

	List = New ValueList;
	List.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	Return List;

EndFunction

Procedure ProcessingUnitSelection(TabularSectionData, SelectedRows, ValueSelected) Export

	For Each String In SelectedRows Do
		
		RowData = TabularSectionData.FindByID(String);
		TypesList = TypesOfNomenclatureWithUnitAnalytics();
		
		If TypesList.FindByValue(RowData.ItemsType) = Undefined Then
			Continue;
		EndIf;
		
		RowData.Department = ValueSelected;
		
	EndDo;

EndProcedure

Function ThisIsShipmentOfItems(GenerationParameters)
	
	ArrangeShipment = False;
	If GenerationParameters.Property("ArrangeShipment") Then
		ArrangeShipment = GenerationParameters.ArrangeShipment;
	EndIf;
	
	Return ArrangeShipment;

EndFunction

#EndRegion

#EndRegion


