#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Ref = Parameters.Ref;
	Date = Parameters.Date;
	Organization = Parameters.Organization;
	Partner = Parameters.Partner;
	Counterparty = Parameters.Counterparty;
	Contract = Parameters.Contract;
	DocumentCurrency = Parameters.Currency;
	ARAPCurrency = Parameters.ARAPCurrency;
	Rate = Parameters.Rate;
	Repetition = Parameters.Repetition;
	BusinessOperation = Parameters.BusinessOperation;
	ThereIsPrepaymentOfBuyoutValue = Parameters.ThereIsPrepaymentOfBuyoutValue;
	AddressOffsetOfAdvances = Parameters.AddressOffsetOfAdvances;
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	ConversionFactor_ = CoefficientForRateAndMultiplicity(
		DocumentCurrency,
		ARAPCurrency,
		Rate,
		Repetition,
		ComplCurrency);
		
	AmountARAP = Parameters.DocumentAmount * ConversionFactor_;

	OffsetOfAdvancesInitial = GetFromTempStorage(AddressOffsetOfAdvances);
	CommonClientServer.SupplementTable(OffsetOfAdvancesInitial, PrepaymentsSettlement);
	
	Items.PrepaymentsSettlementPaymentType.Visible = (BusinessOperation = Enums.BusinessTransactions.EarlyBuyoutOfLeasedAssets);
	Items.PrepaymentsSettlementAmountARAP.Visible = (DocumentCurrency <> ARAPCurrency);
	
	If ValueIsFilled(DocumentCurrency) Then
		Items.PrepaymentsSettlementSum.Title = StrTemplate(NStr("vi = 'Số tiền (%1)';
																|ru = 'Сумма (%1)';
																|en = 'Amount (%1)'; fa = 'Amount (%1)';
																|it = 'Totale (%1)';
																|pl = 'Wartość (%1)';
																|tr = 'Tutar (%1)'"), String(DocumentCurrency));
	EndIf;
	
	If ValueIsFilled(ARAPCurrency) Then
		Items.PrepaymentsSettlementAmountARAP.Title = StrTemplate(NStr("vi = 'Số tiền hạch toán công nợ (%1)';
																		|ru = 'Сумма взаиморасчетов (%1)';
																		|en = 'AR/AP amount (%1)'; fa = 'AR/AP amount (%1)';
																		|it = 'Importo dei pagamenti reciproci (%1)';
																		|pl = 'Wartość rozliczeń wzajemnych (%1)';
																		|tr = 'Borç-alacak muhasebesi tutarı (%1)'"), String(ARAPCurrency));
	EndIf;
	
	UpdateTotals(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PrepaymentsSettlementSumOnChange(Item)
	
	CurrentData = Items.PrepaymentsSettlement.CurrentData;
	
	ConversionFactor_ = CoefficientForRateAndMultiplicity(
		DocumentCurrency,
		ARAPCurrency,
		Rate,
		Repetition,
		ComplCurrency);
	
	CurrentData.AmountARAP = CurrentData.Sum * ConversionFactor_;
	
	UpdateTotals(ThisObject);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPrepaymentsSettlement

&AtClient
Procedure PrepaymentsSettlementOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
			
		CurrentData = Items.PrepaymentsSettlement.CurrentData;
		
		CurrentData.PaymentType = 
			?(ThereIsPrepaymentOfBuyoutValue,
				PredefinedValue("Enum.TypesOfLeasePayments.BuyoutValuePrepayment"),
				PredefinedValue("Enum.TypesOfLeasePayments.RentalService"));
		
	EndIf;

EndProcedure

&AtClient
Procedure PrepaymentsSettlementAfterDeleteRow(Item)
	
	UpdateTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure PrepaymentsSettlementARAPDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Organization);
	FormParameters.Insert("Counterparty", Counterparty);
	FormParameters.Insert("Contract", Contract);
	
	CurrentData = Items.PrepaymentsSettlement.CurrentData;
	TypeOfLeasePayment = ?(ValueIsFilled(CurrentData.PaymentType), 
							CommonClientServer.ValueInArray(CurrentData.PaymentType), 
							AvailableTypeOfLeasePayments(BusinessOperation)); 
	FormParameters.Insert("TypeOfLeasePayment", TypeOfLeasePayment);

	OpenForm("Catalog.LeaseContract.Form.SelectARAPDocument", FormParameters, Item);

EndProcedure

&AtClient
Procedure PrepaymentsSettlementARAPDocumentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		TableRow = Items.PrepaymentsSettlement.CurrentData;
		TableRow.PaymentType = ValueSelected.PaymentType;
		TableRow.ARAPDocument = ValueSelected.ARAPDocument;
		Modified = True;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInTheAdvanceCredit(Command)
	FillInOffsetOfAdvancesOnServer();
EndProcedure

&AtClient
Procedure SaveChanges(Command)

	If Not CheckFilling() Then
		Return;
	EndIf;

	ClosingResult = New Structure;
	PlaceOffsettingOfAdvancesInTemporaryStorage();
	
	Close(ClosingResult);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInOffsetOfAdvancesOnServer()
	
	PrepaymentsSettlement.Clear();
	TotalCredited = 0;
	
	If AmountARAP = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	AccountingDimensionByPartners.DimensionKey
	|INTO AccountingDimensionByPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Organization = &Organization
	|	AND AccountingDimensionByPartners.Partner = &Partner
	|	AND AccountingDimensionByPartners.Counterparty = &Counterparty
	|	AND AccountingDimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|
	|INDEX BY
	|	DimensionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|			THEN 0
	|		ELSE 100
	|	END AS Priority,
	|	CalculationsBalance.AmountType AS PaymentType,
	|	CalculationsBalance.ARAPDocument AS ARAPDocument,
	|
	|	CASE
	|		WHEN &DocumentCurrency <> &ARAPCurrency
	|				AND &ConversionRateToSettlementCurrency = 0
	|			THEN 0
	|		WHEN &DocumentCurrency <> &ARAPCurrency
	|				AND &ConversionRateToSettlementCurrency <> 0
	|			THEN CAST(CalculationsBalance.SumBalance / &ConversionRateToSettlementCurrency AS NUMBER (31, 2))
	|		ELSE CalculationsBalance.SumBalance
	|	END AS Sum,
	|
	|	CalculationsBalance.SumBalance AS AmountARAP
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|		&PeriodLimit, 
	|		AmountType IN (&TypeOfLeasePayment)
	|			AND Contract = &Contract
	|			AND AccountingDimensionByPartners IN (SELECT T.DimensionKey FROM AccountingDimensionByPartners AS T)) AS CalculationsBalance
	|WHERE
	|	CalculationsBalance.SumBalance > 0
	|
	|ORDER BY
	|	Priority,
	|	PaymentType,
	|	ARAPDocument,
	|	AmountARAP";
	
	Query = New Query(QueryText);
	Query.SetParameter("PeriodLimit", New Boundary(New PointInTime(Date, Ref), BoundaryType.Excluding));
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("DocumentCurrency", DocumentCurrency);
	Query.SetParameter("ARAPCurrency", ARAPCurrency);
	Query.SetParameter("TypeOfLeasePayment", AvailableTypeOfLeasePayments(BusinessOperation));
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		DocumentCurrency, ARAPCurrency, Date, Organization);
	Query.SetParameter("ConversionRateToSettlementCurrency",  Coefficients.ConversionRateToSettlementCurrency);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	AmountARAPBalance = AmountARAP;
	
	ConversionFactor_ = CoefficientForRateAndMultiplicity(
		DocumentCurrency,
		ARAPCurrency,
		Rate,
		Repetition,
		ComplCurrency);
		
	While Selection.Next() Do
		
		RowData = PrepaymentsSettlement.Add();
		FillPropertyValues(RowData, Selection);
		
		If RowData.AmountARAP > AmountARAPBalance Then
			RowData.Sum = ?(ConversionFactor_ <> 0, AmountARAPBalance / ConversionFactor_, 0);
			RowData.AmountARAP = AmountARAPBalance;
		EndIf;
		
		If RowData.PaymentType <> Enums.TypesOfLeasePayments.DepositPayment
			And RowData.PaymentType <> Enums.TypesOfLeasePayments.BuyoutValuePrepayment Then
			RowData.ARAPDocument = Undefined;
		EndIf;
		
		AmountARAPBalance = AmountARAPBalance - RowData.AmountARAP;
		
		If AmountARAPBalance = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
	UpdateTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	#Region OffsetOfAdvancesSettlementDocument_NotRequired
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsSettlementARAPDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PrepaymentsSettlement.PaymentType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	
	ListOfPayment = New ValueList();
	ListOfPayment.Add(Enums.TypesOfLeasePayments.DepositPayment);
	ListOfPayment.Add(Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	ListOfPayment.Add(Enums.TypesOfLeasePayments.RentalServicePrepayment);
	ListOfPayment.Add(Enums.TypesOfLeasePayments.EmptyRef());
	ItemFilter.RightValue = ListOfPayment;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<Не требуется>';
													|en = '<Not needed>'; fa = '<Not needed>';
													|it = '<non richiesto>';
													|pl = '<Nie jest wymagane>';
													|tr = '<Gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Function AvailableTypeOfLeasePayments(BusinessOperation)

	TypeOfLeasePayment = New Array;
	TypeOfLeasePayment.Add(PredefinedValue("Enum.TypesOfLeasePayments.BuyoutValuePrepayment"));
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EarlyBuyoutOfLeasedAssets") Then
		TypeOfLeasePayment.Add(PredefinedValue("Enum.TypesOfLeasePayments.RentalService"));
		TypeOfLeasePayment.Add(PredefinedValue("Enum.TypesOfLeasePayments.RentalServicePrepayment"));
		TypeOfLeasePayment.Add(PredefinedValue("Enum.TypesOfLeasePayments.DepositPayment"));
	EndIf;
	
	Return TypeOfLeasePayment;
	
EndFunction

&AtServer
Procedure PlaceOffsettingOfAdvancesInTemporaryStorage()
	
	PutToTempStorage(PrepaymentsSettlement.Unload(), AddressOffsetOfAdvances);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTotals(Form)
	
	TotalCredited = Form.PrepaymentsSettlement.Total("Sum");
	
	Form.TotalCredited = TotalCredited;
	 
EndProcedure

&AtClientAtServerNoContext
Function CoefficientForRateAndMultiplicity(Currency, ARAPCurrency, Rate, Repetition, LocalAccountingCurrency)
		
	If Rate = 0 Or Repetition = 0 Then
		Return 0;
	ElsIf Currency = ARAPCurrency Then
		Return 1;
	ElsIf Not ARAPCurrency = LocalAccountingCurrency
			And Currency = LocalAccountingCurrency Then
		Return Repetition / Rate;
	Else
		Return Rate * Repetition;
	EndIf;
	
EndFunction

#EndRegion
