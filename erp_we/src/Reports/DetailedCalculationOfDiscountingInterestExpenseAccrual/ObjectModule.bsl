#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure GenerateReport(SpreadsheetDocument, FilterContract, FilterDocuments, ReportData, ThereIsDataToDisplay) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Clear();
	
	Template = GetTemplate("Template");
	
	HeaderAreaTwoColumns = Template.GetArea("HeaderAreaTwoColumns");
	HeaderAreaOneColumn = Template.GetArea("HeaderAreaOneColumn");
	Area_TableHeader = Template.GetArea("Area_TableHeader");
	AreaRow = Template.GetArea("AreaRow");
	BasementArea = Template.GetArea("BasementArea");
	
	DiscountDataTable = GetDiscountData(FilterContract, FilterDocuments, ReportData);
	
	DimensionsTable = DiscountDataTable.Copy( , "ARAPDocument, ARAPObject, Organization, Debt, DebtWithoutVAT, AccruedInterest_, PresentValue, AdvanceAmount");
	DimensionsTable.GroupBy("ARAPDocument, ARAPObject, Organization", "Debt, DebtWithoutVAT, AccruedInterest_, PresentValue, AdvanceAmount");
	
	DiscountDataTable.Indexes.Add("ARAPDocument, ARAPObject");
	
	Filter = New Structure("ARAPDocument, ARAPObject");
	
	For Each DimensionString In DimensionsTable Do
		
		FillPropertyValues(Filter, DimensionString);
		PaymentScheduleLines = DiscountDataTable.FindRows(Filter);
		
		DimensionString.AccruedInterest_ = Round(DimensionString.AccruedInterest_, 2);
		DimensionString.PresentValue = DimensionString.DebtWithoutVAT - DimensionString.AccruedInterest_;
		
		RowWithMaximumPercentages = Undefined;
		TotalInterest_ = 0;
		For Each PaymentScheduleLine_ In PaymentScheduleLines Do
			PaymentScheduleLine_.AccruedInterest_ = Round(PaymentScheduleLine_.AccruedInterest_, 2);
			PaymentScheduleLine_.PresentValue =  PaymentScheduleLine_.DebtWithoutVAT - PaymentScheduleLine_.AccruedInterest_;
			TotalInterest_ = TotalInterest_ + PaymentScheduleLine_.AccruedInterest_;
			If RowWithMaximumPercentages = Undefined 
				Or PaymentScheduleLine_.AccruedInterest_ > RowWithMaximumPercentages.AccruedInterest_ Then
				RowWithMaximumPercentages = PaymentScheduleLine_;
			EndIf;
		EndDo;
		RoundingAdjustment = DimensionString.AccruedInterest_ - TotalInterest_;
		If RoundingAdjustment <> 0 Then
			RowWithMaximumPercentages.AccruedInterest_ = RowWithMaximumPercentages.AccruedInterest_ + RoundingAdjustment;
			RowWithMaximumPercentages.PresentValue = RowWithMaximumPercentages.PresentValue - RoundingAdjustment;
		EndIf;
		
		
		PaymentScheduleLine_ = PaymentScheduleLines[0];
		ActualDebtDiffers = DimensionString.DebtWithoutVAT <> PaymentScheduleLine_.FixActualDebtExcludingVAT;
		DiscountRateDiffers = PaymentScheduleLine_.DiscountRate <> PaymentScheduleLine_.FixedDiscountRate;
		PresentValueDiffers = DimensionString.PresentValue <> PaymentScheduleLine_.FixedDiscountedDebtExcludingVAT;
		AccruedInterestDiffers = DimensionString.AccruedInterest_ <> PaymentScheduleLine_.FixedDiscountAmount;
		OutputFixed = Not PaymentScheduleLine_.NoFixedValues	
			And ( ActualDebtDiffers
			Or DiscountRateDiffers 
			Or PresentValueDiffers
			Or AccruedInterestDiffers);
		
		SectionHeader = ?(OutputFixed, HeaderAreaTwoColumns, HeaderAreaOneColumn);
		
		SectionHeader.Parameters.Fill(PaymentScheduleLine_);
		SectionHeader.Parameters.Fill(DimensionString);
		SectionHeader.Parameters.AmountARAP = DimensionString.Debt + PaymentScheduleLine_.AdvanceAmount;
		If OutputFixed Then
			
			SectionHeader.Areas.ActualArrears.BackColor = ?(ActualDebtDiffers, WebColors.Yellow, New Color);
			SectionHeader.Areas.DiscountRate.BackColor = ?(DiscountRateDiffers, WebColors.Yellow, New Color);
			SectionHeader.Areas.PresentValue.BackColor = ?(PresentValueDiffers, WebColors.Yellow, New Color);
			SectionHeader.Areas.AccruedInterest_.BackColor = ?(AccruedInterestDiffers, WebColors.Yellow, New Color);
			
		EndIf;
		
		SpreadsheetDocument.Put(SectionHeader);
		If ReportData = 1 Then
			Area_TableHeader.Parameters.Currency = PaymentScheduleLine_.Currency;
		ElsIf ReportData = 2 Then
			Area_TableHeader.Parameters.Currency = SettingsValueCached.ManagementAccountingCurrency();
		ElsIf ReportData = 3 Then
			Area_TableHeader.Parameters.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DimensionString.Organization);
		EndIf;
		SpreadsheetDocument.Put(Area_TableHeader);
		
		For Each PaymentScheduleLine_ In PaymentScheduleLines Do
			
			AreaRow.Parameters.Fill(PaymentScheduleLine_);
			AreaRow.Parameters.PlannedRepaymentDate = Format(PaymentScheduleLine_.PlannedRepaymentDate, "DLF=D");
			
			SpreadsheetDocument.Put(AreaRow);
			
		EndDo;
		
		BasementArea.Parameters.Fill(DimensionString);
		SpreadsheetDocument.Put(BasementArea);
		
		ThereIsDataToDisplay = True;
		
	EndDo;
	
EndProcedure

Function TempTablesQueryText()
	
	QueryText = 
		"SELECT ALLOWED
		|	RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	RegisterData.ARAPObject AS ARAPObject,
		|	RegisterData.Currency AS Currency,
		|	RegisterData.ARAPDocument AS ARAPDocument,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN RegisterData.DiscountingAmount
		|		WHEN 2
		|			THEN RegisterData.DiscountingAmountMan
		|		ELSE RegisterData.DiscountingAmountCompl
		|	END AS FixedDiscountAmount,
		|	RegisterData.DiscountRate AS FixedDiscountRate,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN RegisterData.DiscountedDebtWithoutVAT
		|		WHEN 2
		|			THEN RegisterData.DiscountedDebtWithoutVATMan
		|		ELSE RegisterData.DiscountedDebtWithoutVATCompl
		|	END AS FixedDiscountedDebtExcludingVAT,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN RegisterData.ActualDebtWithoutVAT
		|		WHEN 2
		|			THEN RegisterData.ActualDebtWithoutVATMan
		|		ELSE RegisterData.ActualDebtWithoutVATCompl
		|	END AS FixActualDebtExcludingVAT,
		|	DimensionKeysOfAccountingByPartners.Counterparty AS Counterparty,
		|	DimensionKeysOfAccountingByPartners.Contract AS Contract,
		|	CounterpartyContracts.DiscountRate AS DiscountRate,
		|	ISNULL(CounterpartyContracts.VATRate, VALUE(Catalog.VATRates.EXCLUDINGVAT)) AS VATRate,
		|	RegisterData.Recorder AS Recorder,
		|	DimensionKeysOfAccountingByPartners.Organization AS Organization
		|INTO TTFix
		|FROM
		|	AccumulationRegister.DiscountInterestExpense AS RegisterData
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|			INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|			ON DimensionKeysOfAccountingByPartners.Contract = CounterpartyContracts.Ref
		|		ON RegisterData.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		|WHERE
		|	RegisterData.Active
		|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND &FilterByContract
		|	AND &FilterByDocument
		|	AND VALUETYPE(RegisterData.ARAPDocument) IN (&TypesOfDocumentsInvolvedInDiscounting)
		|	AND VALUETYPE(RegisterData.Recorder) <> TYPE(Document.ExchangeDifferenceCalculation)
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency,
		|	ARAPDocument,
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTFix.Counterparty AS Counterparty,
		|	TTFix.Contract AS Contract,
		|	VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
		|	VendorsARAPAccountingByDueDates.ARAPDocument AS ARAPDocument,
		|	VendorsARAPAccountingByDueDates.Currency AS Currency,
		|	TTFix.DiscountRate AS DiscountRate,
		|	VendorsARAPAccountingByDueDates.OccurrenceDate AS OccurrenceDate,
		|	VendorsARAPAccountingByDueDates.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	CASE
		|		WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN 1
		|		ELSE -1
		|	END * CASE &ReportData
		|		WHEN 1
		|			THEN VendorsARAPAccountingByDueDates.Debt
		|		WHEN 2
		|			THEN VendorsARAPAccountingByDueDates.ARAPMan
		|		ELSE VendorsARAPAccountingByDueDates.DebtLocal
		|	END AS Debt,
		|	CASE
		|		WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN CASE &ReportData
		|					WHEN 1
		|						THEN VendorsARAPAccountingByDueDates.Debt
		|					WHEN 2
		|						THEN VendorsARAPAccountingByDueDates.ARAPMan
		|					ELSE VendorsARAPAccountingByDueDates.DebtLocal
		|				END
		|		ELSE 0
		|	END AS AdvanceAmount,
		|	VendorsARAPAccountingByDueDates.DocumentRecorder AS DocumentRecorder,
		|	DATEDIFF(VendorsARAPAccountingByDueDates.OccurrenceDate, VendorsARAPAccountingByDueDates.PlannedRepaymentDate, DAY) AS NumberOfDaysBeforePayment,
		|	TTFix.FixedDiscountAmount AS FixedDiscountAmount,
		|	TTFix.FixedDiscountRate AS FixedDiscountRate,
		|	TTFix.FixActualDebtExcludingVAT AS FixActualDebtExcludingVAT,
		|	TTFix.FixedDiscountedDebtExcludingVAT AS FixedDiscountedDebtExcludingVAT,
		|	TTFix.FixedDiscountAmount IS NULL AS NoFixedValues,
		|	TTFix.VATRate AS VATRate,
		|	TTFix.Organization AS Organization
		|INTO TTChart
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
		|		INNER JOIN TTFix AS TTFix
		|		ON VendorsARAPAccountingByDueDates.AccountingDimensionByPartners = TTFix.AccountingDimensionByPartners
		|			AND VendorsARAPAccountingByDueDates.ARAPObject = TTFix.ARAPObject
		|			AND VendorsARAPAccountingByDueDates.Currency = TTFix.Currency
		|			AND VendorsARAPAccountingByDueDates.ARAPDocument = TTFix.ARAPDocument
		|			AND VendorsARAPAccountingByDueDates.DocumentRecorder = TTFix.Recorder
		|WHERE
		|	VendorsARAPAccountingByDueDates.Active
		|	AND VendorsARAPAccountingByDueDates.Debt <> 0
		|
		|INDEX BY
		|	DocumentRecorder";
	
	Return QueryText;
	
EndFunction

Function RequestTextWithVATCoefficients()
	
	QueryText = 
		"SELECT
		|	DocumentAmountsInAccountingCurrency.Recorder AS Recorder,
		|	CASE
		|		WHEN SUM(DocumentAmountsInAccountingCurrency.AmountARAP) = 0
		|			THEN 0
		|		ELSE CAST(SUM(DocumentAmountsInAccountingCurrency.AmountARAP - DocumentAmountsInAccountingCurrency.AmountVATARAP) / SUM(DocumentAmountsInAccountingCurrency.AmountARAP) AS NUMBER(11, 10))
		|	END AS CoefficientOfAmountWithoutVAT
		|INTO TTCoefficientsOfVATAmount
		|FROM
		|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
		|WHERE
		|	DocumentAmountsInAccountingCurrency.Recorder IN
		|			(SELECT
		|				TTChart.DocumentRecorder
		|			FROM
		|				TTChart)
		|	AND DocumentAmountsInAccountingCurrency.Active
		|
		|GROUP BY
		|	DocumentAmountsInAccountingCurrency.Recorder
		|
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTChart.Counterparty AS Counterparty,
		|	TTChart.Contract AS Contract,
		|	TTChart.ARAPObject AS ARAPObject,
		|	TTChart.ARAPDocument AS ARAPDocument,
		|	TTChart.Currency AS Currency,
		|	TTChart.DiscountRate AS DiscountRate,
		|	TTChart.OccurrenceDate AS OccurrenceDate,
		|	TTChart.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	TTChart.VATRate AS VATRate,
		|	SUM(TTChart.Debt) AS Debt,
		|	TTChart.NumberOfDaysBeforePayment AS NumberOfDaysBeforePayment,
		|	ISNULL(TTCoefficientsOfVATAmount.CoefficientOfAmountWithoutVAT, 1) AS CoefficientOfAmountWithoutVAT,
		|	TTChart.FixedDiscountAmount AS FixedDiscountAmount,
		|	TTChart.FixedDiscountRate AS FixedDiscountRate,
		|	TTChart.FixActualDebtExcludingVAT AS FixActualDebtExcludingVAT,
		|	TTChart.FixedDiscountedDebtExcludingVAT AS FixedDiscountedDebtExcludingVAT,
		|	TTChart.NoFixedValues AS NoFixedValues,
		|	SUM(TTChart.AdvanceAmount) AS AdvanceAmount,
		|	SUM(CAST(ISNULL(TTCoefficientsOfVATAmount.CoefficientOfAmountWithoutVAT, 0) * TTChart.AdvanceAmount AS NUMBER(31, 2))) AS AdvancePaymentAmountWithoutVAT_,
		|	TTChart.Organization AS Organization
		|FROM
		|	TTChart AS TTChart
		|		LEFT JOIN TTCoefficientsOfVATAmount AS TTCoefficientsOfVATAmount
		|		ON TTChart.DocumentRecorder = TTCoefficientsOfVATAmount.Recorder
		|
		|GROUP BY
		|	TTChart.Counterparty,
		|	TTChart.Contract,
		|	TTChart.ARAPObject,
		|	TTChart.ARAPDocument,
		|	TTChart.Currency,
		|	TTChart.DiscountRate,
		|	TTChart.OccurrenceDate,
		|	TTChart.PlannedRepaymentDate,
		|	TTChart.VATRate,
		|	TTChart.NumberOfDaysBeforePayment,
		|	TTCoefficientsOfVATAmount.CoefficientOfAmountWithoutVAT,
		|	TTChart.FixedDiscountAmount,
		|	TTChart.FixedDiscountRate,
		|	TTChart.FixActualDebtExcludingVAT,
		|	TTChart.FixedDiscountedDebtExcludingVAT,
		|	TTChart.NoFixedValues,
		|	TTChart.Organization";
	
	Return QueryText;
	
EndFunction

Function GetDiscountData(FilterContract, FilterDocuments, ReportData)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("TypesOfDocumentsInvolvedInDiscounting", 
		AccumulationRegisters.DiscountInterestExpense.GetTypesOfDocumentsInvolvedInDiscounting());
	Query.SetParameter("ReportData", ReportData);
	
	Query.Text = TempTablesQueryText();
	
	If ValueIsFilled(FilterContract) Then
		Query.Text = StrReplace(Query.Text, "&FilterByContract", "DimensionKeysOfAccountingByPartners.Contract IN (&Contract)");
		Query.SetParameter("Contract", FilterContract);
	Else
		Query.SetParameter("FilterByContract", True);
	EndIf;
	If FilterDocuments.Count() > 0 Then
		Query.Text = StrReplace(Query.Text, "&FilterByDocument", "RegisterData.Recorder IN (&Documents)");
		Query.SetParameter("Documents", FilterDocuments);
	Else 
		Query.SetParameter("FilterByDocument", True);
	EndIf;
	
	Query.Execute();
	
	Query.Text = RequestTextWithVATCoefficients();
	SetPrivilegedMode(True);
	ResultTable1 = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	ResultTable1.Columns.Add("AccruedInterest_", TMCommonUse.MoneyFieldTypeDescription());
	ResultTable1.Columns.Add("DebtWithoutVAT", TMCommonUse.DescriptionOfTypesByType(Type("Number")));
	ResultTable1.Columns.Add("PresentValue", TMCommonUse.DescriptionOfTypesByType(Type("Number")));
	ResultTable1.Indexes.Add("ARAPDocument, ARAPObject");
	
	TableGrouping = ResultTable1.Copy(,"ARAPDocument, ARAPObject");
	TableGrouping.GroupBy("ARAPDocument, ARAPObject");
	
	Filter = New Structure("ARAPDocument, ARAPObject");
	For Each DimensionString In TableGrouping Do
		FillPropertyValues(Filter, DimensionString);
		GraphLines = ResultTable1.FindRows(Filter);
		TotalPresentValue = 0;
		TotalOcdPresentValue = 0;
		RowMaximum = Undefined;
		For Each TableRow In GraphLines Do
			TableRow.DebtWithoutVAT = TableRow.Debt * TableRow.CoefficientOfAmountWithoutVAT;
			If TypeOf(TableRow.ARAPDocument) = Type("DocumentRef.SourceDocument") Then
				VATRate = VATAccountingERPClientServer.ValueOfVATRate(TableRow.VATRate) / 100;
				TableRow.DebtWithoutVAT = Round(TableRow.Debt / (1 + VATRate), 2);
				TableRow.AdvancePaymentAmountWithoutVAT_ = Round(TableRow.AdvanceAmount / (1 + VATRate), 2);
			EndIf;
			TableRow.PresentValue = TableRow.DebtWithoutVAT
				/ Pow((1+TableRow.DiscountRate/100), TableRow.NumberOfDaysBeforePayment/365);
			TotalPresentValue = TotalPresentValue + TableRow.PresentValue;
			TableRow.PresentValue = Round(TableRow.PresentValue, 2);
			TotalOcdPresentValue = TotalOcdPresentValue + TableRow.PresentValue;
			If RowMaximum = Undefined Or RowMaximum.PresentValue < TableRow.PresentValue Then
				RowMaximum = TableRow;
			EndIf;
		EndDo;
		TotalPresentValue = Round(TotalPresentValue, 2);
		Balance = TotalPresentValue - TotalOcdPresentValue;
		If Balance <> 0 Then
			RowMaximum.PresentValue = RowMaximum.PresentValue + Balance;
		EndIf;
		For Each TableRow In GraphLines Do
			TableRow.DebtWithoutVAT = Round(TableRow.DebtWithoutVAT, 2);
			TableRow.AccruedInterest_ = TableRow.DebtWithoutVAT - TableRow.PresentValue;
		EndDo;
	EndDo;
	
	Return ResultTable1;
	
EndFunction

#EndRegion

#EndIf
