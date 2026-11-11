
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SampleBonusLoyaltyProgram = BonusPointsServer.LoyaltyCardBonusProgram(Parameters.LoyaltyCard);
	LoyaltyProgram = SampleBonusLoyaltyProgram.LoyaltyProgram;
	Partner                     = Parameters.Partner;
	
	DocumentCurrency         = Parameters.Currency;
	BonusProgramCurrency = SampleBonusLoyaltyProgram.Currency;
	
	StructureOfDocumentExchangeRates         = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency,         CurrentSessionDate());
	StructureOfExchangeRatesOfTheBonusProgram = ProcessingOfExchangeRatesTM.GetCurrencyRate(BonusProgramCurrency, CurrentSessionDate());
	ConversionRateOfBonusesIntoCurrency          = SampleBonusLoyaltyProgram.ConversionRateOfBonusesIntoCurrency;
	
	
	
	// Calculation of the maximum amount of payment with bonuses
	TabularPartProducts = GetFromTempStorage(Parameters.AddressOfTheTablePartProducts); // TabularSection, ValueTable
	TabularPartProducts.Columns.Add("MaxPaymentAmount", TMCommonUse.MoneyFieldTypeDescription());
	TabularPartProducts.Columns.Add("MaxPaymentAmountInPoints", TMCommonUse.MoneyFieldTypeDescription());
	
	Query = New Query("SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.ConnectionKey AS ConnectionKey,
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Price AS PricePerPackaging,
	|	Goods.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	Goods.DiscountMarkupAmount AS DiscountMarkupAmount
	|INTO TemporaryTableOfGoods_
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.ConnectionKey AS ConnectionKey,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	ISNULL(ISNULL(TabularPartPriceGroups.MaximumSharePayableByPoints,
	|		LoyaltyPrograms.MaximumSharePayableByPoints), 0) AS MaximumSharePayableByPoints,
	|	Goods.NumberOfPackages * Goods.PricePerPackaging AS Sum,
	|	Goods.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	Goods.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	CASE
	|		WHEN LoyaltyPrograms.ProductSegment <> VALUE(Catalog.ProductSegments.EmptyRef)
	|			THEN CASE
	|				WHEN SegmentProducts.Segment = LoyaltyPrograms.ProductSegment
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|		ELSE TRUE
	|	END AS IncludedInAvailableSegment,
	|	LoyaltyPrograms.ExcludingDiscountsProvided
	|FROM
	|	TemporaryTableOfGoods_ AS Goods
	|		LEFT JOIN Catalog.LoyaltyPrograms.PriceGroups AS TabularPartPriceGroups
	|		ON (TabularPartPriceGroups.Ref = &LoyaltyProgram)
	|		AND (TabularPartPriceGroups.PriceGroup = Goods.Products.PriceGroup)
	|		LEFT JOIN Catalog.LoyaltyPrograms AS LoyaltyPrograms
	|		ON (LoyaltyPrograms.Ref = &LoyaltyProgram)
	|		LEFT JOIN InformationRegister.SegmentProducts AS SegmentProducts
	|		ON Goods.Products = SegmentProducts.Products
	|		AND Goods.Characteristic = SegmentProducts.Characteristic
	|		AND SegmentProducts.Segment = LoyaltyPrograms.ProductSegment");
	
	Query.SetParameter("Goods", TabularPartProducts);
	Query.SetParameter("LoyaltyProgram", LoyaltyProgram);
	Selection = Query.Execute().Select();
	
	
	While Selection.Next() Do
		
		If Not Selection.MaximumSharePayableByPoints > 0 Then
			Continue;
		EndIf;
		
		If Not Selection.IncludedInAvailableSegment Then
			Continue;
		EndIf;
		
		If Not Selection.ExcludingDiscountsProvided 
			And Selection.PercentRateOfAutomaticDiscountMarkup > Selection.MaximumSharePayableByPoints Then
			Continue;
		EndIf;
		
		TSRow = TabularPartProducts.Find(Selection.LineNumber, "LineNumber");
		
		
		If Selection.ExcludingDiscountsProvided Then
			TSRow.MaxPaymentAmount = (Selection.MaximumSharePayableByPoints / 100) * (Selection.Sum-Selection.DiscountMarkupAmount);
		Else
			TSRow.MaxPaymentAmount = ((Selection.MaximumSharePayableByPoints - Selection.PercentRateOfAutomaticDiscountMarkup) / 100) * Selection.Sum;
		EndIf;
		
		TSRow.MaxPaymentAmountInPoints = ProcessingOfExchangeRatesTM.ConvertAtRate(
			TSRow.MaxPaymentAmount,
			StructureOfDocumentExchangeRates,
			StructureOfExchangeRatesOfTheBonusProgram) / ConversionRateOfBonusesIntoCurrency;
		
	EndDo;
	
	BalanceBonusPoints.Load(BonusPointsServer.BalancesAndRegisteredRecordsOfBonusPoints(LoyaltyProgram, Parameters.Partner));
	InitialBalanceInPoints = BalanceBonusPoints[0].Sum;
	
	OpeningBalance = ProcessingOfExchangeRatesTM.ConvertAtRate(
		InitialBalanceInPoints * ConversionRateOfBonusesIntoCurrency,
		StructureOfExchangeRatesOfTheBonusProgram,
		StructureOfDocumentExchangeRates);
	
	MaxPaymentAmount        = Min(TabularPartProducts.Total("MaxPaymentAmount"), OpeningBalance);
	MaxPaymentAmountInPoints = Min(TabularPartProducts.Total("MaxPaymentAmountInPoints"), InitialBalanceInPoints);
	
	DescriptionMaxPaymentAmount = NStr("vi = 'Số tiền thanh toán tối đa bằng %1%2 hoặc %3';
										|ru = 'Максимальная сумма оплаты составляет %1 %2 или %3';
										|en = 'Max payment amount is %1 %2 or %3'; fa = 'Max payment amount is %1 %2 or %3';
										|it = 'Importo massimo di pagamento di %1 %2 o %3';
										|pl = 'Maksymalna kwota płatności wynosi %1 %2 lub %3';
										|tr = 'Maksimum ödeme tutarı %1 %2 veya %3 şeklindedir'");
	DescriptionMaxPaymentAmount = StringFunctionsClientServer.SubstituteParametersToString(
		DescriptionMaxPaymentAmount,
		MaxPaymentAmount,
		DocumentCurrency,
		StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(
			MaxPaymentAmountInPoints,
			NStr("vi = 'điểm, điểm, điểm';
				|ru = 'балл, балла, баллов';
				|en = 'point, points, points'; fa = 'point, points, points';
				|it = 'punti';
				|pl = 'punkt, punktu, punktów';
				|tr = 'puan, puan, puan'")));
	
	Items.PayAmount.MaxValue = MaxPaymentAmount;
	Items.PaymentAmountInPoints.MaxValue = MaxPaymentAmountInPoints;
	
	If MaxPaymentAmount = 0 Then
		Items.PayAmount.Enabled = False;
		Items.PaymentAmountInPoints.Enabled = False;
		Items.FormPayUsingPoints.Enabled = False;
	EndIf;
	
	PayAmount        = MaxPaymentAmount;
	PaymentAmountInPoints = MaxPaymentAmountInPoints;
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PayAmountOnChange(Item)
	
	PaymentAmountInPoints = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
		PayAmount,
		StructureOfDocumentExchangeRates,
		StructureOfExchangeRatesOfTheBonusProgram) / ConversionRateOfBonusesIntoCurrency;
	
EndProcedure

&AtClient
Procedure PaymentAmountInPointsOnChange(Item)
	
	PayAmount = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
		PaymentAmountInPoints * ConversionRateOfBonusesIntoCurrency,
		StructureOfExchangeRatesOfTheBonusProgram,
		StructureOfDocumentExchangeRates);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PayUsingPoints(Command)
	
	DataParameters = New Structure;
	DataParameters.Insert("AddressInTempStorage", AddressInTempStorage(FormOwner.UUID));
	
	Close(DataParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function AddressInTempStorage(FormOwnerUUID)
	
	TabularSectionRows = GetFromTempStorage(AddressInTempStorage);
	
	AmountForAllocation = PaymentAmountInPoints;
	AmountToBeDistributedInCurrency = PayAmount;
	
	MaxPaymentAmountInPoints = TabularSectionRows.Total("MaxPaymentAmountInPoints");
	
	For Each TSRow In TabularSectionRows Do
		
		If MaxPaymentAmountInPoints <= 0 Then
			Break;
		EndIf;
		
        CurAmountOfBonusPointsToBeDebited = TSRow.MaxPaymentAmountInPoints * (AmountForAllocation / MaxPaymentAmountInPoints);
		TSRow.AmountOfBonusPointsToDeduction = Min(CurAmountOfBonusPointsToBeDebited, AmountForAllocation);
		
		CurAmountOfBonusPointsToBeDebitedInCurrency = ProcessingOfExchangeRatesTM.ConvertAtRate(
			TSRow.AmountOfBonusPointsToDeduction * ConversionRateOfBonusesIntoCurrency,
			StructureOfExchangeRatesOfTheBonusProgram,
			StructureOfDocumentExchangeRates);
		TSRow.AmountOfBonusPointsToDeductionInCurrency = Min(CurAmountOfBonusPointsToBeDebitedInCurrency, AmountToBeDistributedInCurrency);
		
		AmountForAllocation = AmountForAllocation - TSRow.AmountOfBonusPointsToDeduction;
		MaxPaymentAmountInPoints = MaxPaymentAmountInPoints - TSRow.MaxPaymentAmountInPoints;

		AmountToBeDistributedInCurrency = AmountToBeDistributedInCurrency - TSRow.AmountOfBonusPointsToDeductionInCurrency;
		
	EndDo;
	
	Return PutToTempStorage(TabularSectionRows, FormOwnerUUID);
	
EndFunction

#Region Localization

	
#EndRegion

#EndRegion
