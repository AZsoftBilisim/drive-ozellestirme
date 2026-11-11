#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterPeriod1 = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "FilterPeriod1").Value; // Standard Period -
	Organization = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "Organization").Value; // Referenceslink.Organizations -
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Organization",   Organization);
	ParametersStructure.Insert("StartDate",    FilterPeriod1.StartDate);
	ParametersStructure.Insert("EndDate", ProcessedEndDate(FilterPeriod1.EndDate));
	
	MessageAboutClosingOfMonth = "";
	
	SetPrivilegedMode(True);
	If VATAccountingERPInternal.CheckAvailabilityOfTasksForGeneratingVATRegisteredRecords(ParametersStructure) Then
		MessageAboutClosingOfMonth = NStr("vi = 'Cần thực hiện giao dịch thường kỳ
		|""Tạo bản ghi kết chuyển theo thuế GTGT"".';
		|ru = 'Необходимо выполнить регл. операцию
		|""Формирование движений по НДС"".';
		|en = 'Local operation 
		|""Generate VAT records"" must be performed.'; fa = 'Local operation 
		|""Generate VAT records"" must be performed.';
		|it = 'È necessario eseguire l''operazione di routine 
		|""Generazione di movimenti IVA"".';
		|pl = 'Należy wykonać operację reglamentacyjną
		|""Utworzenie przepływów wg VAT"".';
		|tr = '""KDV kayıtlarını oluşturma"" programlı işleminin
		|gerçekleştirilmesi gerekmektedir.'");
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer,
		"MessageAboutClosingOfMonth",
		MessageAboutClosingOfMonth);
	
	ReportSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	ExternalDataSets = GetExternalDatasets();
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region ServiceProceduresFunctions

Function ProcessedEndDate(Val EndDate)
	
	If Not ValueIsFilled(EndDate) Then
		EndDate        = Date(3000, 1, 1);
	EndIf;
	
	Return EndDate;
	
EndFunction

Function GetExternalDatasets()
	
	StructureOfDataSets = New Structure;
	
	FilterPeriod1 = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "FilterPeriod1").Value; // Standard Period -
	Organization = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "Organization").Value; // Referenceslink.Organizations -
	
	TTM = New TempTablesManager;
	
	CalculationParameters = VATAccountingERPInternal.InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	CalculationParameters.StartDate                    = FilterPeriod1.StartDate;
	CalculationParameters.EndDate                 = FilterPeriod1.EndDate;
	CalculationParameters.Companies                   = Organization;
	
	VATAccountingERPInternal.PrepareVT_AdvancesReceived_Repayments(TTM, CalculationParameters);
	
	Query = New Query;
	Query.TempTablesManager = TTM;
	
	Query.SetParameter("StartDate",    FilterPeriod1.StartDate);
	Query.SetParameter("EndDate", FilterPeriod1.EndDate);
	Query.SetParameter("EndDateIncluding",
		?(ValueIsFilled(FilterPeriod1.EndDate), New Boundary(FilterPeriod1.EndDate, BoundaryType.Including), Undefined));
	Query.SetParameter("Organization",   Organization);
	Query.SetParameter("RefType", Common.MetadataObjectID("Document.IssuedTaxInvoicePrepayment"));
	
	Query.Text =
	"SELECT
	|	VATAdvances.Organization AS Organization,
	|	VATAdvances.LineOfBusiness AS LineOfBusiness,
	|	VATAdvances.Counterparty AS Counterparty,
	|	VATAdvances.ARAPObject AS ARAPObject,
	|	VATAdvances.DocumentPayments AS DocumentPayments,
	|	VATAdvances.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATAdvances.VATRate.Rate1 AS VATRate,
	|	VATAdvances.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATAdvances.AdvanceAmount AS AdvanceAmount,
	|	VATAdvances.VATAccrual AS VATAccrual,
	|	VATAdvances.WriteOffOfNDSSAdvance AS WriteOffOfNDSSAdvance,
	|	VATAdvances.OffsetAmount_ AS OffsetAmount_,
	|	VATAdvances.VATDeductionAmount AS VATDeductionAmount,
	|	VATAdvances.VATBalanceStart AS VATBalanceStart,
	|	VATAdvances.VATBalanceEnd AS VATBalanceEnd
	|INTO TTBalancesAndTurnoverOfNDSSAdvances
	|FROM
	|	(SELECT
	|		VATAdvances.Organization AS Organization,
	|		VATAdvances.LineOfBusiness AS LineOfBusiness,
	|		VATAdvances.Counterparty AS Counterparty,
	|		VATAdvances.ARAPObject AS ARAPObject,
	|		VATAdvances.DocumentPayments AS DocumentPayments,
	|		VATAdvances.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		VATAdvances.VATRate AS VATRate,
	|		VATAdvances.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|		CASE
	|			WHEN VATAdvances.Event = VALUE(Enum.EventsVATFromPrepayments.AccrualFromPrepaymentFromCustomer)
	|				THEN VATAdvances.AmountExcludingVAT + VATAdvances.VAT
	|			ELSE 0
	|		END AS AdvanceAmount,
	|		CASE
	|			WHEN VATAdvances.Event = VALUE(Enum.EventsVATFromPrepayments.AccrualFromPrepaymentFromCustomer)
	|				THEN VATAdvances.VAT
	|			ELSE 0
	|		END AS VATAccrual,
	|		CASE
	|			WHEN VATAdvances.Event = VALUE(Enum.EventsVATFromPrepayments.WriteOffVATFromPrepaymentFromCustomer)
	|				THEN VATAdvances.VAT
	|			ELSE 0
	|		END AS WriteOffOfNDSSAdvance,
	|		CASE
	|			WHEN VATAdvances.Event IN (VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepaymentSettlement), VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepapaymentReturn))
	|				THEN VATAdvances.AmountExcludingVAT + VATAdvances.VAT
	|			ELSE 0
	|		END AS OffsetAmount_,
	|		CASE
	|			WHEN VATAdvances.Event IN (VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepaymentSettlement), VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepapaymentReturn))
	|				THEN VATAdvances.VAT
	|			ELSE 0
	|		END AS VATDeductionAmount,
	|		0 AS VATBalanceStart,
	|		0 AS VATBalanceEnd
	|	FROM
	|		AccumulationRegister.VATPrepaymentsFromCustomer AS VATAdvances
	|	WHERE
	|		VATAdvances.Period BETWEEN &StartDate AND &EndDate
	|		AND VATAdvances.Organization = &Organization
	|		AND VATAdvances.Active = TRUE
	|		AND VATAdvances.Event IN (VALUE(Enum.EventsVATFromPrepayments.AccrualFromPrepaymentFromCustomer), VALUE(Enum.EventsVATFromPrepayments.WriteOffVATFromPrepaymentFromCustomer), VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepaymentSettlement), VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepapaymentReturn))
	|		AND VATAdvances.VAT <> 0
	|		AND VATAdvances.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesOfAdvances.Organization,
	|		BalancesOfAdvances.LineOfBusiness,
	|		BalancesOfAdvances.Counterparty,
	|		BalancesOfAdvances.ARAPObject,
	|		BalancesOfAdvances.DocumentPayments,
	|		BalancesOfAdvances.CorrectedTaxInvoice,
	|		BalancesOfAdvances.VATRate,
	|		UNDEFINED,
	|		BalancesOfAdvances.AmountExcludingVATBalance + BalancesOfAdvances.VATBalance,
	|		0,
	|		0,
	|		0,
	|		0,
	|		BalancesOfAdvances.VATBalance,
	|		0
	|	FROM
	|		AccumulationRegister.VATPrepaymentsFromCustomer.Balance(&StartDate, Organization = &Organization) AS BalancesOfAdvances
	|	WHERE
	|		BalancesOfAdvances.VATBalance <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesOfAdvances.Organization,
	|		BalancesOfAdvances.LineOfBusiness,
	|		BalancesOfAdvances.Counterparty,
	|		BalancesOfAdvances.ARAPObject,
	|		BalancesOfAdvances.DocumentPayments,
	|		BalancesOfAdvances.CorrectedTaxInvoice,
	|		BalancesOfAdvances.VATRate,
	|		UNDEFINED,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		BalancesOfAdvances.VATBalance
	|	FROM
	|		AccumulationRegister.VATPrepaymentsFromCustomer.Balance(&EndDateIncluding, Organization = &Organization) AS BalancesOfAdvances
	|	WHERE
	|		BalancesOfAdvances.VATBalance <> 0) AS VATAdvances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	MainTable.Organization AS Organization,
	|	MainTable.LineOfBusiness AS LineOfBusiness,
	|	MainTable.Counterparty AS Counterparty,
	|	MainTable.DocumentPayments AS DocumentPayments,
	|	MainTable.ARAPObject AS ARAPObject
	|INTO TTMainTable
	|FROM
	|	(SELECT
	|		VATAdvances.Organization AS Organization,
	|		VATAdvances.LineOfBusiness AS LineOfBusiness,
	|		VATAdvances.Counterparty AS Counterparty,
	|		VATAdvances.DocumentPayments AS DocumentPayments,
	|		VATAdvances.ARAPObject AS ARAPObject
	|	FROM
	|		TTBalancesAndTurnoverOfNDSSAdvances AS VATAdvances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OffsetsForMutualSettlements.Organization,
	|		OffsetsForMutualSettlements.LineOfBusiness,
	|		OffsetsForMutualSettlements.Counterparty,
	|		OffsetsForMutualSettlements.ARAPDocument,
	|		OffsetsForMutualSettlements.ARAPObject
	|	FROM
	|		AdvancesReceivedToMaturity AS OffsetsForMutualSettlements
	|	WHERE
	|		(OffsetsForMutualSettlements.ARAPDocument, OffsetsForMutualSettlements.Organization) IN
	|				(SELECT
	|					T.DocumentBasis,
	|					T.Organization
	|				FROM
	|					Document.IssuedTaxInvoicePrepayment AS T
	|				WHERE
	|					T.Posted)) AS MainTable
	|
	|INDEX BY
	|	DocumentPayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxInvoice.DocumentBasis AS DocumentBasis,
	|	TaxInvoice.Ref AS Ref,
	|	CASE
	|		WHEN (CAST(SUBSTRING(TaxInvoice.CorrectionNumber, 2, 1) AS STRING(1))) = """"
	|			THEN CAST(""0"" + TaxInvoice.CorrectionNumber AS STRING(3))
	|		ELSE CAST(TaxInvoice.CorrectionNumber AS STRING(3))
	|	END AS FixNumberForSorting
	|INTO TTInvoices
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS TaxInvoice
	|WHERE
	|	(TaxInvoice.DocumentBasis, TaxInvoice.Organization) IN
	|			(SELECT
	|				T.DocumentPayments,
	|				T.Organization
	|			FROM
	|				TTMainTable AS T)
	|	AND TaxInvoice.Date <= &EndDate
	|	AND TaxInvoice.Posted
	|	AND NOT TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		WHERE
	|			DocumentsRegistry.RefType = &RefType
	|			AND DocumentsRegistry.ReversedDocument = TaxInvoice.Ref
	|			AND DocumentsRegistry.Posted)
	|
	|INDEX BY
	|	TaxInvoice.DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LatestInvoices.DocumentBasis AS DocumentBasis,
	|	TaxInvoice.Ref AS Ref,
	|	CASE
	|		WHEN TaxInvoice.FixNumberForSorting = """"
	|				OR TaxInvoice.FixNumberForSorting = ""0""
	|			THEN VALUE(Document.IssuedTaxInvoicePrepayment.EmptyRef)
	|		ELSE TaxInvoice.Ref
	|	END AS CorrectedTaxInvoice
	|INTO TTInvoicesLatest
	|FROM
	|	(SELECT
	|		T.DocumentBasis AS DocumentBasis,
	|		MAX(T.FixNumberForSorting) AS FixNumberForSorting
	|	FROM
	|		TTInvoices AS T
	|	
	|	GROUP BY
	|		T.DocumentBasis) AS LatestInvoices
	|		LEFT JOIN TTInvoices AS TaxInvoice
	|		ON LatestInvoices.DocumentBasis = TaxInvoice.DocumentBasis
	|			AND LatestInvoices.FixNumberForSorting = TaxInvoice.FixNumberForSorting
	|
	|INDEX BY
	|	DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTInvoices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	MainTable.LineOfBusiness AS LineOfBusiness,
	|	MainTable.Counterparty AS Counterparty,
	|	MainTable.ARAPObject AS ARAPObject,
	|	MainTable.DocumentPayments AS DocumentPayments,
	|	Invoices_.Ref AS TaxInvoice
	|FROM
	|	TTMainTable AS MainTable
	|		INNER JOIN TTInvoicesLatest AS Invoices_
	|		ON MainTable.DocumentPayments = Invoices_.DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATAdvances.LineOfBusiness AS LineOfBusiness,
	|	VATAdvances.Counterparty AS Counterparty,
	|	VATAdvances.ARAPObject AS ARAPObject,
	|	VATAdvances.DocumentPayments AS DocumentPayments,
	|	VATAdvances.VATRate AS VATRate,
	|	SUM(VATAdvances.AdvanceAmount) AS AdvanceAmount,
	|	SUM(VATAdvances.VATAccrual) AS VATAccrual,
	|	SUM(VATAdvances.WriteOffOfNDSSAdvance) AS WriteOffOfNDSSAdvance,
	|	SUM(VATAdvances.VATBalanceStart) AS VATBalanceStart,
	|	SUM(VATAdvances.VATBalanceEnd) AS VATBalanceEnd
	|FROM
	|	TTBalancesAndTurnoverOfNDSSAdvances AS VATAdvances
	|WHERE
	|	(VATAdvances.DocumentPayments, VATAdvances.CorrectedTaxInvoice) IN
	|			(SELECT
	|				Invoices_.DocumentBasis,
	|				Invoices_.CorrectedTaxInvoice
	|			FROM
	|				TTInvoicesLatest AS Invoices_)
	|
	|GROUP BY
	|	VATAdvances.LineOfBusiness,
	|	VATAdvances.Counterparty,
	|	VATAdvances.DocumentPayments,
	|	VATAdvances.VATRate,
	|	VATAdvances.ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATAdvances.LineOfBusiness AS LineOfBusiness,
	|	VATAdvances.Counterparty AS Counterparty,
	|	VATAdvances.ARAPObject AS ARAPObject,
	|	VATAdvances.DocumentPayments AS DocumentPayments,
	|	VATAdvances.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATAdvances.VATRate AS VATRate,
	|	SUM(VATAdvances.OffsetAmount_) AS CreditAmount_Detailed,
	|	SUM(VATAdvances.VATDeductionAmount) AS VATDeductionAmount
	|FROM
	|	TTBalancesAndTurnoverOfNDSSAdvances AS VATAdvances
	|WHERE
	|	(VATAdvances.DocumentPayments, VATAdvances.CorrectedTaxInvoice) IN
	|			(SELECT
	|				Invoices_.DocumentBasis,
	|				Invoices_.CorrectedTaxInvoice
	|			FROM
	|				TTInvoicesLatest AS Invoices_)
	|	AND VATAdvances.VATDeductionAmount <> 0
	|
	|GROUP BY
	|	VATAdvances.LineOfBusiness,
	|	VATAdvances.Counterparty,
	|	VATAdvances.DocumentPayments,
	|	VATAdvances.PrepaymentsSettlementDocument,
	|	VATAdvances.VATRate,
	|	VATAdvances.ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ApplyingPrepayments.LineOfBusiness AS LineOfBusiness,
	|	ApplyingPrepayments.Counterparty AS Counterparty,
	|	ApplyingPrepayments.ARAPObject AS ARAPObject,
	|	ApplyingPrepayments.ARAPDocument AS DocumentPayments,
	|	SUM(ApplyingPrepayments.RepaymentAmount) AS CreditAmount_Total
	|FROM
	|	AdvancesReceivedToMaturity AS ApplyingPrepayments
	|
	|GROUP BY
	|	ApplyingPrepayments.LineOfBusiness,
	|	ApplyingPrepayments.Counterparty,
	|	ApplyingPrepayments.ARAPDocument,
	|	ApplyingPrepayments.ARAPObject";
	
	ResultsPackage = Query.ExecuteBatch();
	
	Selection1 =  ResultsPackage[ResultsPackage.Count() - 4].Select();
	Selection2 =  ResultsPackage[ResultsPackage.Count() - 3].Select();
	Selection3 =  ResultsPackage[ResultsPackage.Count() - 2].Select();
	Selection4 =  ResultsPackage[ResultsPackage.Count() - 1].Select();
	
	StructureOfDataSets.Insert("MainTable",               Selection1);
	StructureOfDataSets.Insert("BalancesAndTurnoverOfNDSSAdvances",    Selection2);
	StructureOfDataSets.Insert("Credits_NDSSAdvances",            Selection3);
	StructureOfDataSets.Insert("Credits_AccordingToMutualSettlements", Selection4);
	
	
	Return StructureOfDataSets;
	
EndFunction

#EndRegion

#EndIf
