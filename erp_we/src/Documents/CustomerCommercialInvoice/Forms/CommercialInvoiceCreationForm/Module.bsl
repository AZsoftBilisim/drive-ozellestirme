#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DocumentBasis = Parameters.Basis;
	If Parameters.Property("OnlyActualDebt") Then
		OnlyActualDebt = Parameters.OnlyActualDebt;
	EndIf;
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		Items.StepsTableAmountIsBeingPaid.Visible = False;
	EndIf;
	
	If Not ValueIsFilled(DocumentBasis) Then
		Raise NStr("vi = 'Chỉ có thể nhập chứng từ trên cơ sở chứng từ khác hoặc hợp đồng với khách hàng.';
					|ru = 'Документ можно вводить только на основании другого документа или договора с клиентом.';
					|en = 'You can enter the document only based on another document or a contract with a customer.'; fa = 'You can enter the document only based on another document or a contract with a customer.';
					|it = 'È possibile inserire il documento solo in base a un altro documento o a un accordo con il cliente.';
					|pl = 'Dokument można wprowadzać tylko na podstawie innego dokumentu lub umowy z klientem.';
					|tr = 'Bir belge yalnızca başka bir belge veya istemci ile yapılan bir sözleşme temelinde girilebilir.'");
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "DocumentBasis", DocumentBasis, DataCompositionComparisonType.Equal,, True);
	
	If DocumentBasis <> Undefined Then
		
		If ValueIsFilled(DocumentBasis) Then
			
			Title = Title + ": " + DocumentBasis;
			
		Else
			
			TextDocument_ = NStr("vi = '%DocumentType% (mới)';
								|ru = '%DocumentType% (новый)';
								|en = '%DocumentType% (new)'; fa = '%DocumentType% (new)';
								|it = '%DocumentType% (nuovo)';
								|pl = '%DocumentType% (nowy)';
								|tr = '%DocumentType% (yeni)'");
			TextDocument_ = StrReplace(TextDocument_, "%DocumentType%", DocumentBasis.Metadata().Synonym);
			Title = Title + ": " + TextDocument_;
			
		EndIf;
		
	EndIf;
	
	HeaderBasis = New Structure("
		|Partner,
		|Counterparty,
		|Contract,
		|Organization,
		|Currency,
		|DocumentBasis,
		|DocumentAmount,
		|DocumentNumber,
		|BankAccount,
		|Prefix,
		|CashAccount,
		|PaymentMethod, 
		|ContactPerson,
		|Director,
		|ChiefAccountant
		|");
		
	SetVisibility1();
	
	RefreshServer();
	
	If ValueIsFilled(Currency) Then
		
		Items.StepsTablePaymentAmount.Title      = CreateCurrencyColumnHeader(Items.StepsTablePaymentAmount.Title, Currency);
		Items.StepsTableAmountToPay.Title      = CreateCurrencyColumnHeader(Items.StepsTableAmountToPay.Title, Currency);
		Items.StepsTablePayAmount.Title       = CreateCurrencyColumnHeader(Items.StepsTablePayAmount.Title, Currency);
		Items.StepsTableAmountIsBeingPaid.Title = CreateCurrencyColumnHeader(Items.StepsTableAmountIsBeingPaid.Title, Currency);
		
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	PrintingInvoices = Constants.UseInternationalPrintingForms.Get();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands


	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	RefreshServer();
	
EndProcedure

&AtClient
Procedure CreateAccount(Command)
	
	CreateInvoice_();
	
EndProcedure

&AtClient
Procedure CreatePrintInvoice(Command)
	
	CreateInvoice_(True);
	
EndProcedure

&AtClient
Procedure Cancel_2(Command)
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Được chọn trong sanh sách hóa đơn thanh toán sẽ bị hủy bỏ. Tiếp tục?';
					|ru = 'Выделенные в списке счетов на оплату будут аннулированы. Продолжить?';
					|en = 'Those selected in the list of commercial invoices will be canceled. Continue?'; fa = 'Those selected in the list of commercial invoices will be canceled. Continue?';
					|it = 'Selezionate nell''elenco delle fatture di pagamento saranno annullate. Continuare?';
					|pl = 'Zaznaczone na liście rachunków do zapłaty zostaną anulowane. Kontynuować?';
					|tr = 'Ticari fatura listesinde seçilenler kaldırılacaktır. Devam et?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("Cancel_2Completion", ThisObject), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure Cancel_2Completion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ProcessedItemsCount = SetInvalidFlagServer(Items.List.SelectedRows);
    
    If ProcessedItemsCount > 0 Then
        
        Items.List.Refresh();
        
        MessageText = NStr("vi = '%ProcessedItemsCount% / %TotalCount1% được chọn trong danh sách tài khoản để trả tiền đã hủy';
							|ru = '%ProcessedItemsCount% из %TotalCount1% выделенных в списке счетов на оплату аннулированы.';
							|en = '%ProcessedItemsCount% from %TotalCount1% selected in the list of commercial invoices are canceled.'; fa = '%ProcessedItemsCount% from %TotalCount1% selected in the list of commercial invoices are canceled.';
							|it = '%ProcessedItemsCount% di %TotalCount1% selezionate nell''elenco delle fatture di pagamento sono state annullate.';
							|pl = '%ProcessedItemsCount% z %TotalCount1% zaznaczonych na liście rachunków do zapłaty anulowano.';
							|tr = '%TotalCount1%''dan %ProcessedItemsCount% ticari fatura listesinden seçilenler kaldırılacaktır.'");
        MessageText = StrReplace(MessageText,"%ProcessedItemsCount%", ProcessedItemsCount);
        MessageText = StrReplace(MessageText,"%TotalCount1%",        Items.List.SelectedRows.Count());
        ShowUserNotification(NStr("vi = 'Hóa đơn thanh toán đã hủy';
									|ru = 'Счета на оплату аннулированы';
									|en = 'Commercial invoices are canceled'; fa = 'Commercial invoices are canceled';
									|it = 'Fatture di pagamento sono state annullate';
									|pl = 'Rachunki do zapłaty anulowano';
									|tr = 'Ticari faturalar kaldırılacaktır'"),, MessageText, PictureLib.Information32);
        
    Else
        
        MessageText = NStr("vi = 'Không hủy bất kỳ một hóa đơn thanh toán nào';
							|ru = 'Не аннулирован ни один счет на оплату.';
							|en = 'No commercial invoice is canceled.'; fa = 'No commercial invoice is canceled.';
							|it = 'Nessuna fattura è stata annullata.';
							|pl = 'Nie anulowano ani jednego rachunki do zapłaty.';
							|tr = 'Hiçbir ticari fatura kaldırılmadı.'");
        ShowUserNotification(NStr("vi = 'Hóa đơn thanh toán chưa hủy';
									|ru = 'Счета на оплату не аннулированы';
									|en = 'Commercial invoices are not canceled'; fa = 'Commercial invoices are not canceled';
									|it = 'Fatture di pagamento non sono state annullate';
									|pl = 'Rachunki do zapłaty nie anulowano';
									|tr = 'Ticari faturalar kaldırılmadı'"),, MessageText, PictureLib.Information32);
        
    EndIf;

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StepsTable.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StepsTable.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StepsTable.Paid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StepsTable.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StepsTable.Paid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.MediumGray);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StepsTableSelected.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StepsTable.Paid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StepsTablePaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StepsTable.ThisIsDepositForPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<ký cược bao bì>';
													|ru = '<залог за тару>';
													|en = '<packaging deposit>'; fa = '<packaging deposit>';
													|it = '<cauzione per l''imballaggio>';
													|pl = '<zastaw za tarę>';
													|tr = '<depozito>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StepsTablePaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StepsTable.StepInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));

EndProcedure

#Region Other

&AtServerNoContext
Function SetInvalidFlagServer (Val ProformaInvoices)
	
	Return Documents.CustomerCommercialInvoice.SetInvalidFlag(ProformaInvoices);
	
EndFunction

&AtServer
Procedure SetVisibility1()
	
	If TypeOf(DocumentBasis) <> Type("CatalogRef.CounterpartyContracts") Then
	
		AttributesStructure1 = Common.ObjectAttributesValues(
			DocumentBasis, 
			New Structure("ARAPObjectSettings", "Contract.ARAPObjectSettings"));
		DisplayPayment = AttributesStructure1.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts;
		
	Else
		
		DisplayPayment = True;
		
	EndIf;
	
	Items.StepsTablePaymentAmount.Visible = DisplayPayment;
	Items.StepsTablePayAmount.Visible  = DisplayPayment;
	Items.TotalPaymentAmount_3.Visible         = DisplayPayment;
	Items.TotalPaymentAmount.Visible          = DisplayPayment;
	
EndProcedure

&AtServer
Procedure RefreshServer()
	
	NewOnlineARAPAccounting = Constants.NewOnlineARAPAccounting.Get();
	
	If TypeOf(DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
		
		#Region QueryText
		QueriesTexts = New Array;
		QueriesTexts.Add("
		|SELECT
		|	DocumentData.Ref                    AS Contract,
		|	DocumentData.Partner                   AS Partner,
		|	DocumentData.Counterparty                AS Counterparty,
		|	DocumentData.Organization               AS Organization,
		|	DocumentData.ARAPCurrency      AS Currency,
		|	DocumentData.Ref                    AS DocumentBasis,
		|	0                                         AS DocumentAmount,
		|	DocumentData.Number                     AS DocumentNumber,
		|	DocumentData.BankAccount            AS BankAccount,
		|	DocumentData.Organization.Prefix       AS Prefix,
		|	UNDEFINED                              AS CashAccount,
		|	UNDEFINED                              AS PaymentMethod,
		|	DocumentData.Ref                    AS Document,
		|	DocumentData.BusinessOperation     AS BusinessOperation,
		|	DocumentData.Status                    AS Status,
		|	DocumentData.ContactPerson            AS ContactPerson,
		|
		|	CASE WHEN DocumentData.Status = VALUE(Enum.CounterpartyContractStatuses.NotApproved) THEN
		|		TRUE
		|	ELSE
		|		FALSE
		|	END                                     AS ThereAreErrorsStatus
		|
		|FROM
		|	Catalog.CounterpartyContracts AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Contract
		|");
		
		If NewOnlineARAPAccounting Then
			QueriesTexts.Add("
				|SELECT
				|	CustomersARAPAccounting.BeingPaidBalance AS BeingPaid
				|FROM
				|	AccumulationRegister.CustomersARAPAccounting.Balance(, AccountingDimensionByPartners.Contract = &Contract) AS CustomersARAPAccounting
				|");
			QueriesTexts.Add("
				|SELECT
				|	FALSE                                                AS Selected,
				|	FALSE                                                AS Paid,
				|	1                                                   AS PictureIndex,
				|	SUM(Calculations.AmountDue)                              AS PaymentAmount,
				|	SUM(Calculations.AmountDue)                              AS AmountToPay,
				|	Calculations.PlannedRepaymentDate                      AS PaymentDate,
				|	0                                                   AS PaymentPercentage,
				|	0                                                   AS PayAmount
				|
				|FROM
				|	(SELECT
				|		CalculationsByTerms.PlannedRepaymentDate AS PlannedRepaymentDate,
				|		CalculationsByTerms.DebtBalance            AS AmountDue                
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, AccountingDimensionByPartners.Contract = &Contract) AS CalculationsByTerms
				|		
				|	UNION ALL
				|	
				|	SELECT
				|		PaymentPlan_.PlannedRepaymentDate       AS PlannedRepaymentDate,
				|		PaymentPlan_.AmountDueBalance               AS AmountDue
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, AccountingDimensionByPartners.Contract = &Contract) AS PaymentPlan_
				|	WHERE
				|		NOT &OnlyActualDebt
				|	) AS Calculations
				|GROUP BY
				|	Calculations.PlannedRepaymentDate
				|
				|HAVING
				|	SUM(Calculations.AmountDue) > 0
				|
				|ORDER BY
				|	Calculations.PlannedRepaymentDate
				|");
		Else
		QueriesTexts.Add("
		|SELECT
		|	BEGINOFPERIOD(CustomersARAPAccounting.Period, DAY) AS Period,
		|	SUM(CustomersARAPAccounting.AmountDue) AS AmountDue
		|INTO TableCalculations
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|WHERE
		|	CustomersARAPAccounting.ARAPObject.Object = &Contract
		|	AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND CustomersARAPAccounting.AmountDue > 0
		|
		|GROUP BY
		|	BEGINOFPERIOD(CustomersARAPAccounting.Period, DAY)
		|");
		QueriesTexts.Add("
		|SELECT
		|	FALSE                                                AS Selected,
		|	FALSE                                                AS Paid,
		|	1                                                   AS PictureIndex,
		|	MAX(PeriodsTable.AmountDue)                   AS PaymentAmount,
		|
		|	CASE WHEN MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
		|			>= SUM(TableForPayment.AmountDue) THEN
		|		MAX(PeriodsTable.AmountDue)
		|	ELSE
		|		MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
		|			- (SUM(TableForPayment.AmountDue) - MAX(PeriodsTable.AmountDue))
		|	END                                               AS AmountToPay,
		|
		|	PeriodsTable.Period                              AS PaymentDate,
		|
		|	CASE WHEN MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
		|			>= SUM(TableForPayment.AmountDue) THEN
		|		MAX(PeriodsTable.AmountDue)
		|	ELSE
		|		MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
		|			- (SUM(TableForPayment.AmountDue) - MAX(PeriodsTable.AmountDue))
		|	END / MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
		|	* 100                                               AS PaymentPercentage,
		|
		|	MAX(PeriodsTable.AmountDue) - CASE WHEN MAX(CustomersARAPAccountingBalance.AmountDueBalance
		|			- CustomersARAPAccountingBalance.BeingPaidBalance) >= SUM(TableForPayment.AmountDue) THEN
		|		MAX(PeriodsTable.AmountDue)
		|	ELSE
		|		MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
		|			- (SUM(TableForPayment.AmountDue) - MAX(PeriodsTable.AmountDue))
		|	END                                               AS PayAmount
		|
		|FROM
		|	TableCalculations AS PeriodsTable
		|		INNER JOIN TableCalculations AS TableForPayment
		|		ON PeriodsTable.Period <= TableForPayment.Period
		|		INNER JOIN AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object = &Contract) AS CustomersARAPAccountingBalance
		|		ON TRUE
		|
		|GROUP BY
		|	PeriodsTable.Period
		|
		|HAVING
		|	MAX(CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance)
		|		> SUM(TableForPayment.AmountDue) - MAX(PeriodsTable.AmountDue)
		|
		|ORDER BY
		|	PeriodsTable.Period
		|");
		EndIf;
		
		Query = New Query(StrConcat(QueriesTexts, Common.QueryBatchSeparator()));
		#EndRegion
		Query.SetParameter("Contract", DocumentBasis);
		Query.SetParameter("OnlyActualDebt", OnlyActualDebt);
		
		ResultsArray       = Query.ExecuteBatch();
		
		If ResultsArray[2].IsEmpty() Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập hóa đơn thanh toán. Số dư nợ theo hợp đồng %1 bằng 0.';
					|ru = 'Не требуется вводить счета на оплату. Остаток задолженности по договору %1 равен 0.';
					|en = 'It is not required to enter commercial invoices. Remaining contract debt %1 is 0.'; fa = 'It is not required to enter commercial invoices. Remaining contract debt %1 is 0.';
					|it = 'Non è necessario inserire le fatture di pagamento. La rimanenza del debito dell''accordo %1 è pari a 0.';
					|pl = 'Nie jest wymagane wprowadzanie rachunków do zapłaty. Reszta zadłużenia wynikającego z umowy %1 wynosi 0.';
					|tr = 'Ticari fatura girilmesine gerek yoktur. %1 sözleşmesi kapsamındaki borç bakiyesi 0''dır.'"),
				DocumentBasis);
			Raise ErrorText;
			
		EndIf;
		
		HeaderSelection            = ResultsArray[0].Select();
		// Array of Results[1] - Tables of accounts (not a new architecture of mutual settlements)
		SelectionOfPaymentStages     = ResultsArray[2].Select();
		
		If HeaderSelection.Next() Then
			
			TMCommonUse.CheckPossibilityOfEnteringBasedOn(
				HeaderSelection.DocumentBasis,
				HeaderSelection.Status,
				, // ThereAreErrorsPosted
				HeaderSelection.ThereAreErrorsStatus);
			
			FillPropertyValues(HeaderBasis, HeaderSelection);
			Currency = HeaderSelection.Currency;
			
		EndIf;
		
		StepsTable.Clear();
		
		While SelectionOfPaymentStages.Next() Do
			
			NewLineStage = StepsTable.Add();
			FillPropertyValues(NewLineStage, SelectionOfPaymentStages);
			
		EndDo;
			
		If NewOnlineARAPAccounting Then
			
			AmountOfBalanceIsBeingPaid = 0;
			SampleIsPaidFor = ResultsArray[1].Select();
			If SampleIsPaidFor.Next() Then
				AmountOfBalanceIsBeingPaid = SampleIsPaidFor.BeingPaid;
			EndIf;
			
			For Each CurrentStep In StepsTable Do
				
				If AmountOfBalanceIsBeingPaid < CurrentStep.PaymentAmount - CurrentStep.PayAmount Then
					CurrentStep.AmountIsBeingPaid = AmountOfBalanceIsBeingPaid;
					CurrentStep.AmountToPay = CurrentStep.AmountToPay - CurrentStep.AmountIsBeingPaid;
					Break;
				EndIf;
					
				CurrentStep.AmountIsBeingPaid = CurrentStep.PaymentAmount - CurrentStep.PayAmount;
				CurrentStep.AmountToPay      = 0;
				CurrentStep.Paid           = True;
				AmountOfBalanceIsBeingPaid      = AmountOfBalanceIsBeingPaid - CurrentStep.AmountIsBeingPaid;
				
			EndDo;
			
			ArrayOfAmounts = StepsTable.Unload().UnloadColumn("PaymentAmount");
			ArrayOfPercentages = TMCommonUseClientServer.DistributeProportionally(100, ArrayOfAmounts, 2);
			If ArrayOfPercentages <> Undefined Then
				For IndexOf = 0 To StepsTable.Count() - 1 Do
					StepsTable[IndexOf].PaymentPercentage = ArrayOfPercentages[IndexOf];
				EndDo;
			EndIf;
			
		EndIf;
		
		TotalAmountForPayment    = StepsTable.Total("AmountToPay");
		TotalPaymentAmount     = StepsTable.Total("PayAmount");
		TotalPaymentAmount_3    = StepsTable.Total("PaymentAmount");
		TotalPercentagePayment  = StepsTable.Total("PaymentPercentage");
		
		CurrentDate = BegOfDay(CurrentSessionDate());
		
		TotalMarkedForPayment = 0;
		
		For Each CurrentStep In StepsTable Do
			
			If Not CurrentStep.Paid Then
				If CurrentStep.PaymentDate <= CurrentDate Then
					CurrentStep.Selected = True;
					TotalMarkedForPayment = TotalMarkedForPayment + CurrentStep.AmountToPay;
				EndIf;
				
				If CurrentStep.PaymentDate > CurrentDate Then
					CurrentStep.Selected = True;
					TotalMarkedForPayment = TotalMarkedForPayment + CurrentStep.AmountToPay;
					Break;
				EndIf;
			EndIf;
			
		EndDo;
		
	Else
		
		DataFromPaymentStages = Not NewOnlineARAPAccounting;
		If TypeOf(DocumentBasis) = Type("DocumentRef.SalesOrder")
			Or TypeOf(DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			ThisIsOrderAsInvoice = Common.ObjectAttributeValue(DocumentBasis, "ThisIsOrderAsInvoice");
			DataFromPaymentStages = DataFromPaymentStages Or ThisIsOrderAsInvoice;
		EndIf;
		QueryTextDocument = DocumentBasis.Metadata().FullName();
		Query = New Query;
		#Region QueryText
		QueryTextLinkingInvoiceOrders = "
			|SELECT
			|	ARAPObjectsOfOrders.Ref    AS ARAPObjectOrder,
			|	ARAPObjectsInvoices.Ref AS ARAPObject,
			|	SUM(CAST(CASE
			|				WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
			|					THEN CASE
			|							WHEN ARAPObjectsInvoices.AmountARAP = 0
			|								THEN CASE
			|										WHEN ARAPObjectsInvoices.Sum = 0
			|											THEN 0
			|										ELSE CustomersARAPAccounting.ToShip / ARAPObjectsInvoices.Sum
			|									END
			|							ELSE CustomersARAPAccounting.ToShip / ARAPObjectsInvoices.AmountARAP
			|						END
			|				ELSE 0
			|			END AS NUMBER(20, 10))) AS OrderShare
			|INTO TTCommunicationOrdersINVOICES
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
			|		INNER JOIN Catalog.ARAPObjects AS ARAPObjectsOfOrders
			|		ON CustomersARAPAccounting.ARAPObject = ARAPObjectsOfOrders.Ref
			|			AND (CustomersARAPAccounting.Active)
			|		INNER JOIN Catalog.ARAPObjects AS ARAPObjectsInvoices
			|		ON CustomersARAPAccounting.Recorder = ARAPObjectsInvoices.Object
			|			AND (NOT ARAPObjectsInvoices.DeletionMark)
			|			AND ARAPObjectsInvoices.Ref <> CustomersARAPAccounting.ARAPObject
			|WHERE
			|	ARAPObjectsOfOrders.Object = &DocumentBasis	
			|
			|GROUP BY
			|	ARAPObjectsOfOrders.Ref,
			|	ARAPObjectsInvoices.Ref
			|
			|HAVING
			|	SUM(CAST(CASE
			|				WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
			|					THEN CASE
			|							WHEN ARAPObjectsInvoices.AmountARAP = 0
			|								THEN CASE
			|										WHEN ARAPObjectsInvoices.Sum = 0
			|											THEN 0
			|										ELSE CustomersARAPAccounting.ToShip / ARAPObjectsInvoices.Sum
			|									END
			|							ELSE CustomersARAPAccounting.ToShip / ARAPObjectsInvoices.AmountARAP
			|						END
			|				ELSE 0
			|			END AS NUMBER(20, 10))) <> 0
			|
			|UNION ALL
			|
			|SELECT
			|	ARAPObjects.Ref AS ARAPObjectOrder,
			|	ARAPObjects.Ref AS ARAPObject,
			|	1 AS OrderShare
			|FROM
			|	Catalog.ARAPObjects AS ARAPObjects
			|WHERE 
			|	ARAPObjects.Object = &DocumentBasis	
			|
			|INDEX BY
			|	ARAPObject
			|;";
		
		If Not DataFromPaymentStages Then
			Query.Text = QueryTextLinkingInvoiceOrders;
			If QueryTextDocument = "Document.SalesOrder" Or QueryTextDocument = "Document.RequestForReturnOfGoodsFromCustomer" Then
				Query.Text = Query.Text + "
					|SELECT
					|	PaymentScheduleSteps.PaymentDate                AS PaymentDate,
					|	SUM(PaymentScheduleSteps.PackageDepositValue)   AS PaymentAmount
					|FROM
					|	#DocumentPaymentScheduleSteps AS PaymentScheduleSteps
					|WHERE
					|	PaymentScheduleSteps.Ref  = &DocumentBasis
					|	AND PaymentScheduleSteps.Ref.PackageDepositIsRequired
					|	AND PaymentScheduleSteps.PackageDepositValue <> 0
					|GROUP BY
					|	PaymentDate
					|;"
			EndIf;
			Query.Text = Query.Text + "
				|SELECT
				|	SUM(CalculationData.ApplyingPrepayment) AS ApplyingPrepayment
				|INTO TTUnrecordedAdvance
				|FROM (SELECT
				|		CASE
				|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
				|				THEN -CalculationsByTerms.Debt
				|			ELSE 0
				|		END AS ApplyingPrepayment
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
				|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
				|			ON TTCommunicationOrdersINVOICES.ARAPObject = CalculationsByTerms.ARAPObject 
				|				AND TTCommunicationOrdersINVOICES.ARAPObjectOrder <> TTCommunicationOrdersINVOICES.ARAPObject
				|	WHERE
				|		CalculationsByTerms.ARAPObject IN
				|				(SELECT
				|					T.ARAPObject
				|				FROM
				|					TTCommunicationOrdersINVOICES AS T)
				|
				|	UNION ALL
				|
				|	SELECT
				|		CASE
				|			WHEN PaymentPlan_.UnallocatedAdvancePayment
				|				AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
				|				AND PaymentPlan_.AmountDue < 0
				|				THEN -PaymentPlan_.AmountDue
				|			ELSE 0
				|		END AS ApplyingPrepayment
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlan_
				|	WHERE
				|		PaymentPlan_.ARAPObject IN
				|				(SELECT
				|					T.ARAPObject
				|				FROM
				|					TTCommunicationOrdersINVOICES AS T
				|				WHERE
				|					T.ARAPObjectOrder <> T.ARAPObject)) AS CalculationData
				|HAVING
				|	SUM(CalculationData.ApplyingPrepayment) > 0
				|;
				|SELECT
				|	CASE 
				|		WHEN ISNULL(CalculationsByTerms.PrepaymentBalance, 0) > TTUnrecordedAdvance.ApplyingPrepayment
				|			THEN TTUnrecordedAdvance.ApplyingPrepayment
				|		ELSE ISNULL(CalculationsByTerms.PrepaymentBalance, 0)
				|	END AS Sum
				|FROM
				|	TTUnrecordedAdvance AS TTUnrecordedAdvance
				|	LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(,
				|			ARAPObject IN
				|				(SELECT
				|					T.ARAPObjectOrder
				|				FROM
				|					TTCommunicationOrdersINVOICES AS T)) AS CalculationsByTerms
				|	ON TRUE	
				|;
				|SELECT
				|	FALSE                                                AS Selected,
				|	CASE
				|		WHEN SUM(Calculations.AmountDue) <= SUM(Calculations.PayAmount)
				|			THEN TRUE
				|		ELSE FALSE
				|	END                                               AS Paid,
				|	1                                                   AS PictureIndex,
				|	SUM(Calculations.AmountDue)                              AS PaymentAmount,
				|	SUM(Calculations.AmountDue) - SUM(Calculations.PayAmount) AS AmountToPay,
				|	Calculations.PlannedRepaymentDate                      AS PaymentDate,
				|	0                                                   AS PaymentPercentage,
				|	SUM(Calculations.PayAmount)                          AS PayAmount,
				|	FALSE                                                AS ThisIsDepositForPackage,
				|	FALSE                                                AS StepInExcessOfOrder
				|
				|FROM
				|	(SELECT
				|		CalculationsByTerms.PlannedRepaymentDate AS PlannedRepaymentDate,
				|		CalculationsByTerms.Debt * TTCommunicationOrdersINVOICES.OrderShare AS AmountDue,
				|		0                                      AS PayAmount
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
				|		INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
				|			ON TTCommunicationOrdersINVOICES.ARAPObject = CalculationsByTerms.ARAPObject
				|	WHERE
				|		CalculationsByTerms.ARAPObject IN (SELECT T.ARAPObject FROM TTCommunicationOrdersINVOICES AS T) 
				|		AND CalculationsByTerms.Active
				|		AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease) 
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		CalculationsByTerms.PlannedRepaymentDate AS PlannedRepaymentDate,
				|		-CalculationsByTerms.Debt * TTCommunicationOrdersINVOICES.OrderShare AS AmountDue,
				|		0                                      AS PayAmount
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
				|		INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
				|			ON TTCommunicationOrdersINVOICES.ARAPObject = CalculationsByTerms.ARAPObject
				|	WHERE
				|		CalculationsByTerms.ARAPObject IN (SELECT T.ARAPObject FROM TTCommunicationOrdersINVOICES AS T) 
				|		AND CalculationsByTerms.Active
				|		AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		CalculationsByTerms.PlannedRepaymentDate AS PlannedRepaymentDate,
				|		0                                      AS AmountDue,
				|		CalculationsByTerms.Debt * TTCommunicationOrdersINVOICES.OrderShare AS PayAmount
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
				|		INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
				|			ON TTCommunicationOrdersINVOICES.ARAPObject = CalculationsByTerms.ARAPObject
				|	WHERE
				|		CalculationsByTerms.ARAPObject IN (SELECT T.ARAPObject FROM TTCommunicationOrdersINVOICES AS T) 
				|		AND CalculationsByTerms.Active
				|		AND CalculationsByTerms.SettlementRecordType IN (
				|			VALUE(Enum.TypesOfSettlementRecords.PaymentDebtDecrease),
				|			VALUE(Enum.TypesOfSettlementRecords.RefundDecreasesDebt),
				|			VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease),
				|			VALUE(Enum.TypesOfSettlementRecords.InvoiceAdjustmentDebtDecrease),
				|			VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsDebtDecrease))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		PaymentPlan_.PlannedRepaymentDate       AS PlannedRepaymentDate,
				|		PaymentPlan_.AmountDue                      AS AmountDue,
				|		0                                      AS PayAmount
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlan_
				|	WHERE 
				|		NOT &OnlyActualDebt
				|		AND PaymentPlan_.DocumentPlan = &DocumentBasis
				|		AND PaymentPlan_.Active
				|		AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Receipt)
				|		AND PaymentPlan_.AmountDue > 0
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		PaymentPlan_.PlannedRepaymentDate       AS PlannedRepaymentDate,
				|		-PaymentPlan_.AmountDue                     AS AmountDue,
				|		0                                      AS PayAmount
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlan_
				|	WHERE 
				|		NOT &OnlyActualDebt
				|		AND PaymentPlan_.DocumentPlan = &DocumentBasis
				|		AND PaymentPlan_.Active
				|		AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
				|		AND NOT PaymentPlan_.UnallocatedAdvancePayment
				|		AND PaymentPlan_.AmountDue > 0
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		PaymentPlan_.PlannedRepaymentDate       AS PlannedRepaymentDate,
				|		-PaymentPlan_.AmountDue                     AS AmountDue,
				|		0                                      AS PayAmount
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlan_
				|	WHERE 
				|		NOT &OnlyActualDebt
				|		AND PaymentPlan_.DocumentPlan = &DocumentBasis
				|		AND PaymentPlan_.Active
				|		AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
				|		AND PaymentPlan_.UnallocatedAdvancePayment
				|		AND PaymentPlan_.AmountDue < 0
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		PaymentPlan_.PlannedRepaymentDate       AS PlannedRepaymentDate,
				|		0                                      AS AmountDue,
				|		PaymentPlan_.AmountDue                      AS PayAmount
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlan_
				|	WHERE 
				|		PaymentPlan_.DocumentPlan = &DocumentBasis
				|		AND PaymentPlan_.Active
				|		AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
				|		AND PaymentPlan_.UnallocatedAdvancePayment
				|		AND PaymentPlan_.AmountDue > 0
				|	) AS Calculations
				|GROUP BY
				|	Calculations.PlannedRepaymentDate
				|
				|HAVING
				|	SUM(Calculations.AmountDue) > 0
				|
				|ORDER BY
				|	Calculations.PlannedRepaymentDate
				|
				|;";
		Else
			Query.Text = QueryTextLinkingInvoiceOrders + "
				|SELECT
				|	PaymentScheduleSteps.Ref                           AS Document,
				|	1                                                   AS Order,
				|	FALSE                                                AS Selected,
				|	FALSE                                                AS Paid,
				|	1                                                   AS PictureIndex,
				|	PaymentScheduleSteps.PaymentAmount                     AS PaymentAmount,
				|	PaymentScheduleSteps.PaymentAmount                     AS AmountToPay,
				|	PaymentScheduleSteps.PaymentDate                      AS PaymentDate,
				|	PaymentScheduleSteps.PaymentPercentage                   AS PaymentPercentage,
				|	FALSE                                                AS ThisIsDepositForPackage,
				|	FALSE                                                AS StepInExcessOfOrder
				|FROM
				|	#DocumentPaymentScheduleSteps AS PaymentScheduleSteps
				|WHERE
				|	PaymentScheduleSteps.Ref  = &DocumentBasis
				|	AND PaymentScheduleSteps.PaymentAmount <> 0
				|";
			
			If QueryTextDocument = "Document.SalesOrder" Or QueryTextDocument = "Document.RequestForReturnOfGoodsFromCustomer" Then
				Query.Text = Query.Text + TextSalesOrder();
			EndIf;
			
			Query.Text = Query.Text + ArrangeText();
		EndIf;
		Query.Text = Query.Text + PaymentRequestText();
		
		QueryText = "
		|SELECT
		|	DocumentData.Partner                   AS Partner,
		|	DocumentData.Counterparty                AS Counterparty,
		|	DocumentData.Contract		              AS Contract,
		|	DocumentData.Organization               AS Organization,
		|	DocumentData.Director              AS Director,
		|	DocumentData.ChiefAccountant          AS ChiefAccountant,
		|	DocumentData.Currency                    AS Currency,
		|	DocumentData.Ref                    AS DocumentBasis,
		|	DocumentData.Number                     AS DocumentNumber,
		|	DocumentData.BankAccount            AS BankAccount,
		|	DocumentData.Organization.Prefix       AS Prefix,
		|	DocumentData.CashAccount                     AS CashAccount,
		|	&DocumentDetailsContactPerson            AS ContactPerson,
		|	&DocumentDataIsOrderAsInvoice           AS ThisIsOrderAsInvoice,
		|	DocumentData.PaymentMethod               AS PaymentMethod,
		|	DocumentData.Ref                    AS Document,
		|	
		|	&Status                                   AS Status,
		|	&ThereAreErrorsEconomicOperation          AS ThereAreErrorsEconomicOperation,
		|	&BusinessOperation                    AS BusinessOperation,
		|	
		|	NOT DocumentData.Posted               AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN VALUETYPE(DocumentData.Ref) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
		|			THEN CASE
		|					WHEN &DataOfDocumentRequiresPackagingDeposit
		|						THEN &DocumentDataReplacementAmount + &DocumentDataAmountOfReturnableContainers
		|					ELSE &DocumentDataReplacementAmount
		|				END
		|		ELSE CASE
		|				WHEN VALUETYPE(DocumentData.Ref) = TYPE(Document.SalesOrder)
		|					THEN CASE
		|							WHEN &DataOfDocumentRequiresPackagingDeposit
		|								THEN &DocumentDataDocumentAmount + &DocumentDataAmountOfReturnableContainers
		|							ELSE &DocumentDataDocumentAmount
		|						END
		|				ELSE &DocumentDataDocumentAmount
		|			END
		|	END                                     AS DocumentAmount
		|FROM
		|	#QueryTextDocument AS DocumentData
		|WHERE
		|	DocumentData.Ref = &DocumentBasis
		|"; 
		
		Query.Text = Query.Text + QueryText;
		
		Query.Text = StrReplace(Query.Text, "#DocumentPaymentScheduleSteps", QueryTextDocument + ".PaymentScheduleSteps");
		Query.Text = StrReplace(Query.Text, "#QueryTextDocument", QueryTextDocument);
		
		Query.Text = StrReplace(Query.Text, "&DocumentDataDocumentAmount",       "DocumentData.DocumentAmount");
		
		If QueryTextDocument = "Document.RequestForReturnOfGoodsFromCustomer" Then
			Query.Text = StrReplace(Query.Text, "&DocumentDataReplacementAmount", "DocumentData.ReplacementAmount");
		Else
			Query.Text = StrReplace(Query.Text, "&DocumentDataReplacementAmount", "0");
		EndIf;
		
		If QueryTextDocument = "Document.SalesOrder" Then
			Query.Text = StrReplace(Query.Text, "&DocumentDetailsContactPerson", "DocumentData.ContactPerson");
			Query.Text = StrReplace(Query.Text, "&DocumentDataIsOrderAsInvoice", "DocumentData.ThisIsOrderAsInvoice");
		Else
			Query.Text = StrReplace(Query.Text, "&DocumentDetailsContactPerson", """""");
			Query.Text = StrReplace(Query.Text, "&DocumentDataIsOrderAsInvoice", """""");
		EndIf;
		
		If QueryTextDocument = "Document.RequestForReturnOfGoodsFromCustomer" Or QueryTextDocument = "Document.SalesOrder" Then
			Query.Text = StrReplace(Query.Text, "&DocumentDataAmountOfReturnableContainers",  "DocumentData.ReturnablePackagingAmount");
			Query.Text = StrReplace(Query.Text, "&DataOfDocumentRequiresPackagingDeposit", "DocumentData.PackageDepositIsRequired");
		Else
			Query.Text = StrReplace(Query.Text, "&DocumentDataAmountOfReturnableContainers", "0");
			Query.Text = StrReplace(Query.Text, "&DataOfDocumentRequiresPackagingDeposit", "FALSE");
		EndIf;
		
		If QueryTextDocument <> "Document.ConsignmentReportFromCustomer" 
			And QueryTextDocument <> "Document.PurchasingReportToConsignorPrincipal"
			And QueryTextDocument <> "Document.CustomerInvoiceServices" Then
			Query.Text = StrReplace(Query.Text, "&Status", "DocumentData.Status");
			Query.Text = StrReplace(Query.Text, "&ThereAreErrorsEconomicOperation", ThereAreErrorsBusinessTransactionField());
			Query.Text = StrReplace(Query.Text, "&BusinessOperation", "DocumentData.BusinessOperation");
		Else
			Query.Text = StrReplace(Query.Text, "&Status", "UNDEFINED");
			Query.Text = StrReplace(Query.Text, "&ThereAreErrorsEconomicOperation", "FALSE");
			Query.Text = StrReplace(Query.Text, "&BusinessOperation", "UNDEFINED");
		EndIf;
		
		If QueryTextDocument = "Document.CustomerInvoice" Or QueryTextDocument = "Document.CustomerInvoiceServices" Then
			Query.Text = StrReplace(Query.Text, "DocumentData.BankAccount", "DocumentData.CompanyBankAccount");
		EndIf;
		#EndRegion
		
		Query.SetParameter("DocumentBasis", DocumentBasis);
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
		Query.SetParameter("OnlyActualDebt", OnlyActualDebt);
		ResultsArray            = Query.ExecuteBatch();
		IndexOfQueryResults     = ResultsArray.UBound();
		DocumentTableStages       = ResultsArray[IndexOfQueryResults - 2].Unload();
		SelectionOfDocumentsPayment      = ResultsArray[IndexOfQueryResults - 1].Select();
		HeaderSelection                 = ResultsArray[IndexOfQueryResults].Select();
		If Not DataFromPaymentStages Then
			// In the order of calculations, the advance payment on orders, the debt on invoices, the amount of the unpaid advance increases the amount of payment
			// (the invoice has already written off the payment plan, but has not credited the advance - this amount remains unallocated on the invoices),
			// we will distribute this amount by stages of payment in ascending order of dates and reduce the amount of payment.
			SampleUncountedAdvance  = ResultsArray[IndexOfQueryResults - 3].Select();
			If SampleUncountedAdvance.Next()
				And SampleUncountedAdvance.Sum > 0 Then
				BalanceOfOutstandingAdvance = SampleUncountedAdvance.Sum;
				For Each DocumentLineStage In DocumentTableStages Do
					If BalanceOfOutstandingAdvance = 0 Then
						Break;
					EndIf;
					DebitedAmount = Min(BalanceOfOutstandingAdvance, DocumentLineStage.AmountToPay);
					DocumentLineStage.AmountToPay = DocumentLineStage.AmountToPay - DebitedAmount;
					DocumentLineStage.PaymentAmount = DocumentLineStage.PaymentAmount - DebitedAmount;
					BalanceOfOutstandingAdvance        = BalanceOfOutstandingAdvance        - DebitedAmount;
				EndDo;
				IndexOf = DocumentTableStages.Count();
				While IndexOf > 0 Do
					IndexOf = IndexOf - 1;
					If DocumentTableStages[IndexOf].PaymentAmount = 0 Then
						DocumentTableStages.Delete(IndexOf);
					EndIf;
				EndDo;
			EndIf;
			// We will subtract the packaging deposit from the general payment plan and add the lines
			If QueryTextDocument = "Document.SalesOrder" Or QueryTextDocument = "Document.RequestForReturnOfGoodsFromCustomer" Then
				TablePackagingDeposit = ResultsArray[IndexOfQueryResults - 5].Unload();
				DepositForPackage = TablePackagingDeposit.Total("PaymentAmount");
				For Each PackagingDepositLine In TablePackagingDeposit Do
					GraphLines = DocumentTableStages.FindRows(New Structure("PaymentDate", PackagingDepositLine.PaymentDate));
					IndexOf = 0;
					While IndexOf < GraphLines.Count()
						And PackagingDepositLine.PaymentAmount > 0 Do
						If GraphLines[IndexOf].PaymentAmount <= PackagingDepositLine.PaymentAmount Then
							GraphLines[IndexOf].ThisIsDepositForPackage = True;
							PackagingDepositLine.PaymentAmount = PackagingDepositLine.PaymentAmount - GraphLines[IndexOf].PaymentAmount;
						Else
							GraphLines[IndexOf].PaymentAmount = GraphLines[IndexOf].PaymentAmount - PackagingDepositLine.PaymentAmount;
							GraphLines[IndexOf].AmountToPay = GraphLines[IndexOf].AmountToPay - PackagingDepositLine.PaymentAmount;
							NewRow = DocumentTableStages.Add();
							FillPropertyValues(NewRow, PackagingDepositLine);
							NewRow.ThisIsDepositForPackage = True;
							NewRow.AmountToPay = NewRow.PaymentAmount;
							PackagingDepositLine.PaymentAmount = 0;
						EndIf;
						IndexOf = IndexOf + 1;
					EndDo;
				EndDo;
			EndIf;
		EndIf;
		
		If HeaderSelection.Next() Then
			
			ArrayOfValidStatuses = Undefined;
			BasisType = TypeOf(DocumentBasis);
			
			If BasisType = Type("DocumentRef.SalesOrder") Then
				
				Documents.SalesOrder.CheckPossibilityOfEnteringBasedOn(
					HeaderSelection.DocumentBasis,
					HeaderSelection.Status,
					HeaderSelection.ThereAreErrorsPosted,
					True);

			ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				
				Documents.RequestForReturnOfGoodsFromCustomer.CheckPossibilityOfEnteringBasedOn(
					HeaderSelection.DocumentBasis,
					HeaderSelection.Status,
					HeaderSelection.ThereAreErrorsPosted,
					True);
				
			EndIf;
			
			If QueryTextDocument <> "Document.ConsignmentReportFromCustomer" Then
				
				Documents.CustomerCommercialInvoice.CheckCorrectnessOfBusinessTransactionOfFoundationDocument(
					HeaderSelection.ThereAreErrorsEconomicOperation,
					HeaderSelection.BusinessOperation);
				
			EndIf;
			
			FillPropertyValues(HeaderBasis, HeaderSelection);
			Currency = HeaderSelection.Currency;
			
		EndIf;
		
		If DocumentTableStages.Count() = 0
			And DataFromPaymentStages Then
			
			ErrorText = NStr("vi = 'Trong chứng từ %Document% không điền giai đoạn lịch biểu thanh toán';
							|ru = 'В документе %Document% не заполнены этапы графика оплаты';
							|en = 'Payment milestones are not populated in document %Document%'; fa = 'Payment milestones are not populated in document %Document%';
							|it = 'Nel documento %Document% non sono state compilate le fasi del grafico di pagamento';
							|pl = 'W dokumencie %Document% nie wypełniono etapów harmonogramu płatności';
							|tr = '%Document% belgesinde, ödeme planının aşamaları tamamlanmadı'");
			ErrorText = StrReplace(ErrorText, "%Document%", DocumentBasis);
			Raise ErrorText;
			
		EndIf;
		
		StepsTable.Clear();
		
		For Each DocumentLineStage In DocumentTableStages Do
			
			If DocumentLineStage.AmountToPay = 0 And DocumentLineStage.PaymentAmount = 0 Then
				Continue;
			EndIf;
			
			NewLineStage = StepsTable.Add();
			FillPropertyValues(NewLineStage, DocumentLineStage);
			
		EndDo;
		
		If StepsTable.Total("PaymentAmount") = 0 Then
			
			ErrorText = NStr("vi = 'Không cần nhập hóa đơn thanh toán. Số tiền thanh toán theo chứng từ %Document% bằng 0.';
							|ru = 'Не требуется вводить счета на оплату. Сумма платежа по документу %Document% равна 0.';
							|en = 'It is not required to enter commercial invoices. Payment amount by document %Document% is 0.'; fa = 'It is not required to enter commercial invoices. Payment amount by document %Document% is 0.';
							|it = 'Non è necessario inserire le fatture di pagamento. L''importo da pagare in base al documento %Document% è pari a 0.';
							|pl = 'Nie jest wymagane wprowadzanie rachunków do zapłaty. Wartość płatności na podstawie dokumentu %Document% wynosi 0.';
							|tr = 'Ticari fatura girilmesine gerek yoktur. %Document% belgesi için ödeme tutarı 0''dır.'");
			ErrorText = StrReplace(ErrorText, "%Document%", DocumentBasis);
			Raise ErrorText;
			
		EndIf;
		
		If SelectionOfDocumentsPayment.Next() Then
			
			AmountBalanceOfPayment = 0;
			AmountBalanceOfPayment = SelectionOfDocumentsPayment.PayAmount;
			
			If AmountBalanceOfPayment > 0 Then
				For Each CurrentStep In StepsTable Do
					
					If AmountBalanceOfPayment < CurrentStep.PaymentAmount Then
						CurrentStep.PayAmount = AmountBalanceOfPayment;
						CurrentStep.AmountToPay = CurrentStep.PaymentAmount - CurrentStep.PayAmount;
						Break;
					EndIf;
						
					CurrentStep.PayAmount  = CurrentStep.PaymentAmount;
					CurrentStep.AmountToPay = 0;
					CurrentStep.Paid      = True;
					AmountBalanceOfPayment       = AmountBalanceOfPayment - CurrentStep.PaymentAmount;
					
				EndDo;
			EndIf;
			
			AmountOfBalanceIsBeingPaid = 0;
			AmountOfBalanceIsBeingPaid = SelectionOfDocumentsPayment.BeingPaid;
			
			If AmountOfBalanceIsBeingPaid > 0 Then
				For Each CurrentStep In StepsTable Do
					
					If AmountOfBalanceIsBeingPaid < CurrentStep.PaymentAmount - CurrentStep.PayAmount Then
						CurrentStep.AmountIsBeingPaid = AmountOfBalanceIsBeingPaid;
						CurrentStep.AmountToPay = CurrentStep.AmountToPay - CurrentStep.AmountIsBeingPaid;
						Break;
					EndIf;
						
					CurrentStep.AmountIsBeingPaid = CurrentStep.PaymentAmount - CurrentStep.PayAmount;
					CurrentStep.AmountToPay      = 0;
					CurrentStep.Paid           = True;
					AmountOfBalanceIsBeingPaid      = AmountOfBalanceIsBeingPaid - CurrentStep.AmountIsBeingPaid;
					
				EndDo;
			EndIf;
			
		EndIf;
		
		TotalAmountForPayment    = StepsTable.Total("AmountToPay");
		TotalPaymentAmount     = StepsTable.Total("PayAmount");
		TotalPaymentAmount_3    = StepsTable.Total("PaymentAmount");
		TotalPercentagePayment  = StepsTable.Total("PaymentPercentage");
		
		If Not DataFromPaymentStages Then
			If StepsTable.Total("AmountToPay") = 0 Then
				ThisIsOrder = TypeOf(DocumentBasis) = Type("DocumentRef.SalesOrder")
					Or TypeOf(DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer");
				If ThisIsOrder Then
					ErrorText = NStr("vi = 'Không cần nhập hóa đơn thanh toán. Số dư cần thanh toán theo chứng từ %Document% bằng 0.';
									|ru = 'Не требуется вводить счета на оплату. Остаток к оплате по документу %Document% равен 0.';
									|en = 'It is not required to enter commercial invoices. The balance to be paid by the %Document% document is 0.'; fa = 'It is not required to enter commercial invoices. The balance to be paid by the %Document% document is 0.';
									|it = 'It is not required to enter commercial invoices. The balance to be paid by the %Document% document is 0.';
									|pl = 'It is not required to enter commercial invoices. The balance to be paid by the %Document% document is 0.';
									|tr = 'Ticari fatura girilmesine gerek yoktur. %Document% belgesi için ödenmesi gereken bakiye 0''dır.'");
				Else
					ErrorText = NStr("vi = 'Không cần nhập hóa đơn thanh toán. Số dư công nợ theo chứng từ %Document% bằng 0.';
									|ru = 'Не требуется вводить счета на оплату. Остаток задолженности по документу %Document% равен 0.';
									|en = 'It is not required to enter commercial invoices. Remaining debt by the %Document% document is 0.'; fa = 'It is not required to enter commercial invoices. Remaining debt by the %Document% document is 0.';
									|it = 'It is not required to enter commercial invoices. Remaining debt by the %Document% document is 0.';
									|pl = 'It is not required to enter commercial invoices. Remaining debt by the %Document% document is 0.';
									|tr = 'Ticari fatura girilmesine gerek yoktur. %Document% belgesi kapsamındaki borç bakiyesi 0''dır.'");
				EndIf;
				ErrorText = StrReplace(ErrorText, "%Document%", DocumentBasis);
				Raise ErrorText;
			EndIf;
		EndIf;
		
		CurrentDate = BegOfDay(CurrentSessionDate());
		
		TotalMarkedForPayment = 0;
		
		For Each CurrentStep In StepsTable Do
			
			If Not CurrentStep.Paid Then
				If CurrentStep.PaymentDate <= CurrentDate Then
					CurrentStep.Selected = True;
					TotalMarkedForPayment = TotalMarkedForPayment + CurrentStep.AmountToPay;
				EndIf;
				
				If CurrentStep.PaymentDate > CurrentDate Then
					CurrentStep.Selected = True;
					TotalMarkedForPayment = TotalMarkedForPayment + CurrentStep.AmountToPay;
					Break;
				EndIf;
			EndIf;
			
		EndDo;
		
		ArrayOfAmounts = StepsTable.Unload(New Structure("ThisIsDepositForPackage", False)).UnloadColumn("PaymentAmount");
		ArrayOfPercentages = TMCommonUseClientServer.DistributeProportionally(100, ArrayOfAmounts, 2);
		If ArrayOfPercentages <> Undefined Then
			PercentageIndex = 0;
			For IndexOf = 0 To StepsTable.Count() - 1 Do
				If StepsTable[IndexOf].ThisIsDepositForPackage Then
					Continue;
				EndIf;
				StepsTable[IndexOf].PaymentPercentage = ArrayOfPercentages[PercentageIndex];
				PercentageIndex = PercentageIndex + 1;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function CreatePaymentInvoiceServer()
	
	CustomerCommercialInvoice = Undefined;
	
	BeginTransaction();
	
	Try
		
		DocumentObject = Documents.CustomerCommercialInvoice.CreateDocument();
		FillPropertyValues(DocumentObject, HeaderBasis);
		DocumentObject.Fill(Undefined);
		DocumentObject.Date = CurrentSessionDate();
		DocumentObject.SetNewNumber();
		
		If TypeOf(HeaderBasis) = Type("Structure")
				And CommonClientServer.HasAttributeOrObjectProperty(HeaderBasis, "DocumentBasis") Then
			BasisOfFillingData = HeaderBasis.DocumentBasis;
		Else
			BasisOfFillingData = Undefined;
		EndIf;
		ResponsiblePersonsServer.InstallManager(DocumentObject, BasisOfFillingData);
		
		DocumentAmount   = 0;
		NumberOfStages = 0;
		StageNumber       = 1;
		PaymentPercentage   = 0;
		AmountOfDocumentWithoutCollateral = 0;
		
		For Each CurrentStep In StepsTable Do
			
			If Not CurrentStep.Selected Then
				Continue;
			EndIf;
			
			DocumentAmount = DocumentAmount + CurrentStep.PaymentAmount - CurrentStep.PayAmount - CurrentStep.AmountIsBeingPaid;
			If Not CurrentStep.ThisIsDepositForPackage Then
				AmountOfDocumentWithoutCollateral = AmountOfDocumentWithoutCollateral + CurrentStep.PaymentAmount - CurrentStep.PayAmount - CurrentStep.AmountIsBeingPaid;
			EndIf;
			NumberOfStages = NumberOfStages + 1;
			
		EndDo;
		
		DocumentObject.DocumentAmount = DocumentAmount;
		
		If HeaderBasis.DocumentAmount <> DocumentAmount Then
			DocumentObject.PartialPayment = True;
		EndIf;
		
		For Each CurrentStep In StepsTable Do
			
			If Not CurrentStep.Selected Then
				Continue;
			EndIf;
			
			NewStage = DocumentObject.PaymentScheduleSteps.Add();
			NewStage.PaymentDate    = CurrentStep.PaymentDate;
			NewStage.PaymentAmount   = CurrentStep.AmountToPay;
			NewStage.ThisIsDepositForPackage = CurrentStep.ThisIsDepositForPackage;
			
			If AmountOfDocumentWithoutCollateral > 0 Then
				If StageNumber = NumberOfStages Then
					NewStage.PaymentPercentage = 100 - PaymentPercentage;
				ElsIf Not CurrentStep.ThisIsDepositForPackage Then
					NewStage.PaymentPercentage = NewStage.PaymentAmount * 100 / AmountOfDocumentWithoutCollateral;
					PaymentPercentage = PaymentPercentage + NewStage.PaymentPercentage;
				EndIf;
			EndIf;
			
			StageNumber = StageNumber + 1;
			
		EndDo;
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(
			DocumentObject.Organization);
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			DocumentObject.BankAccount);
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization = DocumentObject.Organization;
		ParametersStructure.PaymentMethod	= DocumentObject.PaymentMethod;
		ParametersStructure.CashAccount		= DocumentObject.CashAccount;
		CashAccount          = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		
		DocumentObject.PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			HeaderBasis.DocumentNumber,
			HeaderBasis.DocumentBasis);
		DocumentObject.Write(DocumentWriteMode.Posting);
		CustomerCommercialInvoice = DocumentObject.Ref;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		ErrorText = NStr("vi = 'Không thể ghi %Document%. %ErrorDescription%';
						|ru = 'Не удалось записать %Document%. %ErrorDescription%';
						|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
						|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
						|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
						|tr = '%Document% kaydedilemedi. %ErrorDescription%'");
		ErrorText = StrReplace(ErrorText, "%Document%",       DocumentObject);
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
		
		CommonClientServer.MessageToUser(ErrorText);
		
	EndTry;
	
	Return CustomerCommercialInvoice;
	
EndFunction

&AtServerNoContext
Function CreateCurrencyColumnHeader(ColumnTitle, Currency)
	
	 Return ColumnTitle + " (" + Currency + ")";
	
EndFunction

&AtClient
Procedure CreateInvoice_(PrintInvoice = False)
	
	ThereAreSelected = False;
	
	For Each CurrentStep In StepsTable Do
		
		If CurrentStep.Selected Then
			ThereAreSelected = True;
		EndIf;
		
	EndDo;
	
	If Not ThereAreSelected Then
		
		WarningText = NStr("vi = 'Chưa chọn giai đoạn thanh toán';
							|ru = 'Не выбраны этапы оплаты';
							|en = 'Payment milestones are not selected'; fa = 'Payment milestones are not selected';
							|it = 'Non sono state selezionate le fasi di pagamento';
							|pl = 'Nie wybrano etapów harmonogramu płatności';
							|tr = 'Ödeme aşamaları seçilmedi'");
		ShowMessageBox(Undefined, WarningText);
		Return;
		
	EndIf;
	
	CustomerCommercialInvoice =  CreatePaymentInvoiceServer();
	
	If CustomerCommercialInvoice <> Undefined Then
		
		ShowUserNotification(NStr("vi = 'Tạo:';
									|ru = 'Создание:';
									|en = 'Created:'; fa = 'ایجادشده:';
									|it = 'Creazione:';
									|pl = 'Created:';
									|tr = 'Oluşturma:'"),
		                               GetURL(CustomerCommercialInvoice),
		                               CustomerCommercialInvoice,
		                               PictureLib.Information32);
	
		NotifyChanged(CustomerCommercialInvoice);
		Items.Pages.CurrentPage = Items.ProformaInvoicesPage;
		Items.List.CurrentRow = CustomerCommercialInvoice;
		
		If PrintInvoice Then
			GeneratePrintForm(CustomerCommercialInvoice);
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure GeneratePrintForm(CustomerCommercialInvoice)

	DocumentsArray = New Array;
	DocumentsArray.Add(CustomerCommercialInvoice);
	
	CallbackDescription = New CallbackDescription("CheckDocumentsPostingCompletion", ThisObject);
	
	PrintManagementClient.CheckDocumentsPosting(CallbackDescription, DocumentsArray);
	
EndProcedure

&AtClient
Procedure CheckDocumentsPostingCompletion(DocumentsArray, AdditionalParameters) Export
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintCommercialInvoices",
		?(PrintingInvoices, "ProformaInvoiceEn", "ProformaInvoice"),
		DocumentsArray,
		Undefined,
		New Structure("Presentation", NStr("vi = 'Hóa đơn thanh toán';
											|ru = 'Счет на оплату';
											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
											|it = 'Fattura di pagamento';
											|pl = 'Rachunek do zapłaty';
											|tr = 'Ticari fatura'")));
	
EndProcedure

&AtClient
Procedure StepsTableSelectedOnChange(Item)
	
	CurrentStep = Items.StepsTable.CurrentData;
	
	If CurrentStep <> Undefined Then
		
		LineToEdit = StepsTable.FindByID(CurrentStep.GetID());
		
		If Not LineToEdit.Selected Then
			
			ResetFlag = False;
			
			For Each CurRow In StepsTable Do
				
				If LineToEdit = CurRow Then
					ResetFlag = True;
				EndIf;
				
				If ResetFlag And CurRow.Selected Then
					CurRow.Selected = False;
				EndIf;
				
			EndDo;
			
		Else
			
			SetFlag = True;
			
			For Each CurRow In StepsTable Do
				
				If LineToEdit = CurRow Then
					SetFlag = False;
				EndIf;
				
				If SetFlag And Not CurRow.Selected And Not CurRow.Paid Then
					CurRow.Selected = True;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	TotalMarkedForPayment = 0;
	
	For Each CurrentStep In StepsTable Do
		
		If CurrentStep.Selected Then
			TotalMarkedForPayment = TotalMarkedForPayment + CurrentStep.AmountToPay;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function PaymentRequestText()
	
	PaymentRequestText = "";
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		PaymentRequestText = "
		|SELECT
		|	ISNULL(SUM(CalculationData.PayAmount), 0) AS PayAmount,
		|	ISNULL(SUM(CalculationData.BeingPaid), 0) AS BeingPaid
		|FROM
		|	(SELECT
		|		0 AS PayAmount,
		|		CASE
		|			WHEN CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|				THEN CASE
		|						WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|							THEN CustomersARAPAccounting.BeingPaid
		|						ELSE - CustomersARAPAccounting.BeingPaid
		|					END
		|			ELSE 0
		|		END AS BeingPaid
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|	WHERE
		|		CustomersARAPAccounting.ARAPObject IN (SELECT T.ARAPObject FROM TTCommunicationOrdersINVOICES AS T)
		|		AND CustomersARAPAccounting.Active
		|	) AS CalculationData
		|;";
	Else
		PaymentRequestText = "
		|SELECT
		|	ISNULL(SUM(CASE 
		|			WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|				AND (NOT CustomersARAPAccounting.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SettlementOfPrepayment),
		|				                                                 VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|				                                                 VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				                                                 VALUE(Enum.BusinessTransactions.RetailSaleOfGoods))
		|					OR VALUETYPE(CustomersARAPAccounting.Recorder) = TYPE(Document.ARAPSettlement))
		|				THEN CustomersARAPAccounting.AmountDue
		|			ELSE 0
		|		END +
		|		CASE
		|			WHEN CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|				THEN CASE
		|						WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|							THEN CustomersARAPAccounting.BeingPaid
		|						ELSE - CustomersARAPAccounting.BeingPaid
		|					END
		|			ELSE 0
		|		END), 0) AS PayAmount,
		|	ISNULL(SUM(0), 0) AS BeingPaid
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|WHERE
		|	CustomersARAPAccounting.ARAPObject IN (SELECT T.ARAPObject FROM TTCommunicationOrdersINVOICES AS T)
		|	AND CustomersARAPAccounting.Active 
		|;";
	EndIf;
	
	Return PaymentRequestText;
	
EndFunction

&AtServerNoContext
Function TextSalesOrder()
	
	QueryText = "
	|UNION ALL
	|
	|SELECT
	|	PaymentScheduleSteps.Ref                           AS Document,
	|	2                                                   AS Order,
	|	FALSE                                                AS Selected,
	|	FALSE                                                AS Paid,
	|	1                                                   AS PictureIndex,
	|	PaymentScheduleSteps.PackageDepositValue                AS PaymentAmount,
	|	PaymentScheduleSteps.PackageDepositValue                AS AmountToPay,
	|	PaymentScheduleSteps.PaymentDate                      AS PaymentDate,
	|	PaymentScheduleSteps.PackageDepositPercentage              AS PaymentPercentage,
	|	TRUE                                              AS ThisIsDepositForPackage,
	|	FALSE                                                AS StepInExcessOfOrder
	|FROM
	|	#DocumentPaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref  = &DocumentBasis
	|	AND PaymentScheduleSteps.Ref.PackageDepositIsRequired
	|	AND PaymentScheduleSteps.PackageDepositValue <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	CustomersARAPAccounting.Recorder AS Document,
	|	3 AS Order,
	|	FALSE AS Selected,
	|	FALSE AS Paid,
	|	1 AS PictureIndex,
	|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN CustomersARAPAccounting.AmountDue
	|						ELSE -CustomersARAPAccounting.AmountDue
	|				END) AS PaymentAmount,
	|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN CustomersARAPAccounting.AmountDue
	|						ELSE -CustomersARAPAccounting.AmountDue
	|				END) AS AmountToPay,
	|	MIN(CustomersARAPAccounting.Period) AS PaymentDate,
	|	0 AS PaymentPercentage,
	|	FALSE AS ThisIsDepositForPackage,
	|	TRUE AS StepInExcessOfOrder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|WHERE
	|	CustomersARAPAccounting.ARAPObject.Object = &DocumentBasis
	|	AND CustomersARAPAccounting.Recorder <> CustomersARAPAccounting.ARAPObject.Object
	|	AND CustomersARAPAccounting.AmountDue > 0 
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|	AND CustomersARAPAccounting.Active
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|GROUP BY
	|	CustomersARAPAccounting.Recorder
	|
	|HAVING
	|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN CustomersARAPAccounting.AmountDue
	|						ELSE -CustomersARAPAccounting.AmountDue
	|			END) > 0
	|
	|";
	
	Return QueryText;
	
EndFunction

&AtServerNoContext
Function ArrangeText()
	
	Text = "ORDER BY
	|	PaymentDate,
	|	Order
	|;";
	
	Return Text;
	
EndFunction

&AtServerNoContext
Function ThereAreErrorsBusinessTransactionField()
	
	FieldHasErrors = "
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END
	|";
	
	Return FieldHasErrors;
	
EndFunction

#EndRegion

#EndRegion
