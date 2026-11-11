#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure generates a decryption report in the form of a reconciliation State
// 
// Parameters:
//    ReconciliationParameters - Structure - Structure with parameters to fill in.
// 
// Returns:
//  Structure - Generate A Decryption:
// * Result - SpreadsheetDocument - 
// * DetailsDataAddress - String - 
//
Function GenerateDecryption(ReconciliationParameters) Export
	
	ReportData = GetReportData(ReconciliationParameters);
	CalculationReconciliationServiceIsUsed = False;
	
	DataCompositionSchema = GetTemplate("ReconciliationState");
	
	DefaultSettings = DataCompositionSchema.DefaultSettings;
	If Not ReconciliationParameters.EDIParticipant And CalculationReconciliationServiceIsUsed Then
		DefaultSettings.Structure[1].Name = "ReconciliationWithoutEDI";
		DefaultSettings.Structure[1].Structure[0].Name = "DiscrepanciesWithoutEDI";
	ElsIf ReconciliationParameters.EDIParticipant And Not CalculationReconciliationServiceIsUsed Then
		DefaultSettings.Structure[1].Name = "ReconciliationWithoutReconciliation20";
		DefaultSettings.Structure[1].Structure[0].Name = "DiscrepanciesWithoutReconciliation20";
	ElsIf Not ReconciliationParameters.EDIParticipant And Not CalculationReconciliationServiceIsUsed Then
		DefaultSettings.Structure[1].Name = "ReconciliationWithoutEDOiReconciliation20";
		DefaultSettings.Structure[1].Structure[0].Name = "DiscrepanciesWithoutEDOiReconciliation20";
	EndIf;
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(DefaultSettings);
	
	Period = New StandardPeriod(ReconciliationParameters.BeginOfPeriod, ReconciliationParameters.EndOfPeriod);
	DataCompositionClientServer.SetParameter(SettingsComposer, "Period", Period);
	DataCompositionClientServer.SetParameter(SettingsComposer, "Organization", ReconciliationParameters.Organization);
	DataCompositionClientServer.SetParameter(SettingsComposer, "Counterparty", ReconciliationParameters.Counterparty);
	DataCompositionClientServer.SetParameter(SettingsComposer, "IsBlankString", "");
	
	SettingsForLayoutOfTemplate = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	DetailsData = New DataCompositionDetailsData;
	Template = TemplateComposer.Execute(DataCompositionSchema, SettingsForLayoutOfTemplate, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	ExternalSets = New Structure;
	ExternalSets.Insert("ReconciliationData", ReportData.Reconciliation);
	ExternalSets.Insert("CheckingReconciliationPeriod", ReportData.TimingControl);
	CompositionProcessor.Initialize(Template, ExternalSets, DetailsData, True);
	
	Result = New SpreadsheetDocument;
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(Result);
	OutputProcessor.Output(CompositionProcessor);
	
	DetailsDataAddress = PutToTempStorage(DetailsData, ReconciliationParameters.UUID);
	ResultDecryption = New Structure("Result, DetailsDataAddress", Result, DetailsDataAddress);
	
	Return ResultDecryption;
	
EndFunction

#EndRegion

#Region Private

Function GetReportData(ReconciliationParameters)
	
	Query = New Query;
	Query.Text = TextOfTranscriptReportQuery();
	Query.SetParameter("BeginOfPeriod", ReconciliationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", ReconciliationParameters.EndOfPeriod);
	Query.SetParameter("TypesOfCalculations_", ReconciliationParameters.TypesOfCalculations_);
	Query.SetParameter("Organization", ReconciliationParameters.Organization);
	Query.SetParameter("Counterparty", ReconciliationParameters.Counterparty);
	Query.SetParameter("ForAllCounterparties", Not ValueIsFilled(ReconciliationParameters.Counterparty));
	Query.SetParameter("OnlyOurCompanies", False);
	Query.SetParameter("Manager", ReconciliationParameters.Manager);
	Query.SetParameter("ForAllManagers", Not ValueIsFilled(ReconciliationParameters.Manager));
	Query.SetParameter("Currency", ReconciliationParameters.Currency);
	Query.SetParameter("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(ReconciliationParameters.Organization));
	Query.SetParameter("ForAllCurrencies", False);
	Query.SetParameter("ThisIsLocalCurrency", ReconciliationParameters.ThisIsLocalCurrency);
	Query.SetParameter("ContractsWithoutTurnover", ReconciliationParameters.IncludeContractsWithoutTurnover);
	Query.SetParameter("TypesOfRentalAmountToBeReconciled", Documents.ARAPReconciliation2_5_11.TypesOfRentalAmountsToBeReconciled());
	Query.SetParameter("IsBlankString", "");
	
	QueryResult = Query.ExecuteBatch();
	
	Result = New Structure;
	Reconciliation = QueryResult[QueryResult.UBound()].Unload();
	For Each Record In Reconciliation Do
		If Not ValueIsFilled(Record.ARAPDocument) And ValueIsFilled(Record.PresentationOfDocument) Then
			Record.PresentationOfDocument = StringFunctionsClientServer.SubstituteParametersToString("<%1 №%2 dated %3>",
				Record.PresentationOfDocument, Record.DocumentNumber, Format(Record.DocumentDate, "DLF=D"));
		EndIf;
		If Record.RefPresentation = Undefined Then
			Record.RefPresentation = "<"+NStr("vi = 'Chưa được phản ánh trong các chứng từ đối chiếu công nợ';
												|ru = 'Не отражено в документах сверки взаиморасчетов';
												|en = 'Not recorded in reconciliation documents'; fa = 'Not recorded in reconciliation documents';
												|it = 'Not recorded in reconciliation documents';
												|pl = 'Not recorded in reconciliation documents';
												|tr = 'Alacak/Borç mutabakatı belgelerinde kaydedilmemiş'")+">";
		EndIf;
	EndDo;
	
	ReconciliationTerms = QueryResult[QueryResult.UBound()-1].Unload();
	TimingControl = New ValueTable;
	TimingControl.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	TimingControl.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
	TypePeriod150 = New TypeDescription("String",,New StringQualifiers(150));
	TimingControl.Columns.Add("AccordingToCalculations", TypePeriod150);
	TimingControl.Columns.Add("Comment", TypePeriod150);
	For Each Record In ReconciliationTerms Do
		ThereAreNoSettlementDocuments = Not ValueIsFilled(Record.DateOfOperationOfSettlement);
		ThereAreNoReconciliationDocuments = Not ValueIsFilled(Record.MaximumEndOfReconciliationPeriod);
		NewRow = TimingControl.Add();
		NewRow.Organization = Record.Organization;
		NewRow.Counterparty = Record.Counterparty;
		Record.DateOfOperationOfSettlement = Max(Record.DateOfOperationOfSettlement, ReconciliationParameters.BeginOfPeriod);
		Record.MaximumEndOfReconciliationPeriod = Max(Record.MaximumEndOfReconciliationPeriod, ReconciliationParameters.EndOfPeriod);
		
		If ThereAreNoSettlementDocuments Then
			NewRow.AccordingToCalculations = NStr("vi = 'Không có thanh toán nào được thực hiện trong kỳ hiện tại';
													|ru = 'Расчеты за текущий период не производились';
													|en = 'No calculations are made for the current period'; fa = 'No calculations are made for the current period';
													|it = 'No calculations are made for the current period';
													|pl = 'No calculations are made for the current period';
													|tr = 'Cari dönemde hesaplaşma gerçekleşmedi'");
		Else
			NewRow.AccordingToCalculations = NStr("vi = 'Ngày giao dịch cuối cùng với đối tác';
													|ru = 'Дата последней операции с контрагентом';
													|en = 'Date of the last operation with counterparty'; fa = 'Date of the last operation with counterparty';
													|it = 'Date of the last operation with counterparty';
													|pl = 'Date of the last operation with counterparty';
													|tr = 'Cari hesap ile son işlem tarihi'") + " " + Format(Record.DateOfOperationOfSettlement, "DLF=D");
		EndIf;
		If ThereAreNoReconciliationDocuments Then
			Template = NStr("vi = 'Cần nhập đối chiếu từ %1 đến %2';
							|ru = 'Требуется ввести сверку с %1 по %2';
							|en = 'Reconciliation from %1 to %2 is required'; fa = 'Reconciliation from %1 to %2 is required';
							|it = 'Reconciliation from %1 to %2 is required';
							|pl = 'Reconciliation from %1 to %2 is required';
							|tr = '%1 ve %2 tarihler arasındaki hesap mutabakatı girilmesi gerekiyor'");
			CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				Format(ReconciliationParameters.BeginOfPeriod, "DLF=D"),
				Format(ReconciliationParameters.EndOfPeriod, "DLF=D"));
		ElsIf Record.DateOfOperationOfSettlement > Record.MaximumEndOfReconciliationPeriod Then
			Template = NStr("vi = 'Cần nhập đối chiếu từ %1 đến %2';
							|ru = 'Требуется ввести сверку с %1 по %2';
							|en = 'Reconciliation from %1 to %2 is required'; fa = 'Reconciliation from %1 to %2 is required';
							|it = 'Reconciliation from %1 to %2 is required';
							|pl = 'Reconciliation from %1 to %2 is required';
							|tr = '%1 ve %2 tarihler arasındaki hesap mutabakatı girilmesi gerekiyor'");
			CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				Format(Record.MaximumEndOfReconciliationPeriod, "DLF=D"),
				Format(Record.DateOfOperationOfSettlement, "DLF=D"));
		Else
			CommentText1 = NStr("vi = 'Không cần nhập chứng từ đối chiếu';
								|ru = 'Ввод документов сверки не требуется';
								|en = 'There is no need to create reconciliation documents'; fa = 'There is no need to create reconciliation documents';
								|it = 'There is no need to create reconciliation documents';
								|pl = 'There is no need to create reconciliation documents';
								|tr = 'Hesap mutabakatı belgelerinin girilmesi gerekmiyor'");
		EndIf;
		NewRow.Comment = CommentText1;
	EndDo;
	
	If ReconciliationTerms.Count() = 0 Then
		NewRow = TimingControl.Add();
		NewRow.Organization = ReconciliationParameters.Organization;
		NewRow.Counterparty = ReconciliationParameters.Counterparty;
		NewRow.AccordingToCalculations = NStr("vi = 'Không có thanh toán nào với đối tác';
												|ru = 'Расчеты с контрагентом не производились';
												|en = 'Counterparty AR/AP is not calculated'; fa = 'Counterparty AR/AP is not calculated';
												|it = 'Counterparty AR/AP is not calculated';
												|pl = 'Counterparty AR/AP is not calculated';
												|tr = 'Cari hesap ile işlem yapılmamış'");
		If Reconciliation.Count() = 0 Then
			CommentText1 = NStr("vi = 'Yêu cầu đối chiếu nợ đầu vào';
								|ru = 'Требуется сверка входящей задолженности';
								|en = 'Reconciliation of incoming debt is required'; fa = 'Reconciliation of incoming debt is required';
								|it = 'Reconciliation of incoming debt is required';
								|pl = 'Reconciliation of incoming debt is required';
								|tr = 'Gelen borcun mutabakatı gerekiyor'");
		Else
			CommentText1 = NStr("vi = 'Cần cập nhật các chứng từ đối chiếu';
								|ru = 'Требуется актуализировать документы сверки';
								|en = 'Reconciliation document update is required'; fa = 'Reconciliation document update is required';
								|it = 'Reconciliation document update is required';
								|pl = 'Reconciliation document update is required';
								|tr = 'Mutabakat belgelerinin güncellenmesi gerekiyor'");
		EndIf;
		NewRow.Comment = CommentText1;
	EndIf;
	
	Result.Insert("Reconciliation", Reconciliation);
	Result.Insert("TimingControl", TimingControl);
	
	Return Result;
	
EndFunction

Function TextOfTranscriptReportQuery()

	QueryText = DataProcessors.SettlementReconciliationMonitor.QueryTextCalculationData() + 
	"////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Reconciliation.Ref AS Ref,
	|	Reconciliation.Number AS Number,
	|	Reconciliation.Date AS Date,
	|	Reconciliation.Currency AS Currency,
	|	Reconciliation.Status AS Status,
	|	EDOStates.EDIState AS EDIState,
	|	Reconciliation.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	Reconciliation.BeginOfPeriod AS BeginOfPeriod,
	|	Reconciliation.EndOfPeriod AS EndOfPeriod,
	|	Reconciliation.Counterparty AS Counterparty,
	|	Reconciliation.Organization AS Organization,
	|	SUM(TSSummaryRecords.ClosingBalanceDr) AS ClosingBalanceDr,
	|	SUM(TSSummaryRecords.ClosingBalanceCr) AS ClosingBalanceCr,
	|	SUM(CASE 
	|			WHEN Reconciliation.ThereAreDiscrepancies 
	|				THEN TSSummaryRecords.ClosingBalanceDrCounterparty
	|			ELSE
	|				TSSummaryRecords.ClosingBalanceDr
	|	END) AS ClosingBalanceDrCounterparty,
	|	SUM(CASE 
	|			WHEN Reconciliation.ThereAreDiscrepancies 
	|				THEN TSSummaryRecords.ClosingBalanceCrCounterparty
	|			ELSE
	|				TSSummaryRecords.ClosingBalanceCr
	|	END) AS ClosingBalanceCrCounterparty
	|INTO TTReconciliationDocumentsTotals
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS Reconciliation
	|	INNER JOIN Document.ARAPReconciliation2_5_11.SummaryRecords AS TSSummaryRecords
	|		ON Reconciliation.Ref = TSSummaryRecords.Ref
	|
	|WHERE
	|	Reconciliation.Posted
	|	AND (Reconciliation.Currency = &Currency OR Reconciliation.Currency = &ComplCurrency)
	|	AND Reconciliation.Status <> VALUE(Enum.StatusesOfARAPReconciliation2_5_11.IsRejected)
	|	AND Reconciliation.Organization IN (&Organization)
	|	AND (&ForAllCounterparties OR Reconciliation.Counterparty IN (&Counterparty))
	|	AND SummaryRecords.PaymentType_ IN (&TypesOfCalculations_)
	|	AND Reconciliation.BeginOfPeriod <= &EndOfPeriod
	|	AND Reconciliation.EndOfPeriod >= &BeginOfPeriod
	|	AND TRUE IN (SELECT TOP 1 TRUE 
	|				FROM 
	|					TTBalancesAndTurnoverUnderContracts AS BalanceAndTurnovers
	|				WHERE
	|					BalanceAndTurnovers.Contract = TSSummaryRecords.Contract)
	|	
	|GROUP BY
	|	Reconciliation.Ref,
	|	Reconciliation.Number,
	|	Reconciliation.Date,
	|	Reconciliation.Currency,
	|	Reconciliation.Status,
	|	Reconciliation.ThereAreDiscrepancies,
	|	Reconciliation.BeginOfPeriod,
	|	Reconciliation.EndOfPeriod,
	|	Reconciliation.Counterparty,
	|	Reconciliation.Organization
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Reconciliation.Ref AS Ref,
	|	Reconciliation.Status AS Status,
	|	Reconciliation.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	Reconciliation.BeginOfPeriod AS BeginOfPeriod,
	|	Reconciliation.EndOfPeriod AS EndOfPeriod,
	|	Reconciliation.Counterparty AS Counterparty,
	|	Reconciliation.Organization AS Organization,
	|	TSDetailedRecords.ARAPDocument AS ARAPDocument,
	|	TSDetailedRecords.DocumentNumber AS DocumentNumber,
	|	TSDetailedRecords.DocumentDate AS DocumentDate,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, &IsBlankString) AS IBDocumentNumber,
	|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1,1,1)) AS IBDocumentDate,
	|	SUM(TSDetailedRecords.DebitAmount) AS SumDr,
	|	SUM(CASE 
	|			WHEN Reconciliation.ThereAreDiscrepancies 
	|				THEN TSDetailedRecords.AmountDebitCounterparty
	|			ELSE
	|				TSDetailedRecords.DebitAmount
	|	END) AS DrAmountCounterparty,
	|	SUM(TSDetailedRecords.LoanAmount_) AS SumCr,
	|	SUM(CASE 
	|			WHEN Reconciliation.ThereAreDiscrepancies 
	|				THEN TSDetailedRecords.AmountCreditCounterparty
	|			ELSE
	|				TSDetailedRecords.LoanAmount_
	|	END) AS CrAmountCounterparty
	|
	|INTO TTReconciliationDocumentsDetails
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS Reconciliation
	|	INNER JOIN Document.ARAPReconciliation2_5_11.DetailedRecords AS TSDetailedRecords
	|		ON Reconciliation.Ref = TSDetailedRecords.Ref
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSDetailedRecords.ARAPDocument = DocumentsRegistry.Ref
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	Reconciliation.Posted
	|	AND (Reconciliation.Currency = &Currency OR Reconciliation.Currency = &ComplCurrency)
	|	AND Reconciliation.Status <> VALUE(Enum.StatusesOfARAPReconciliation2_5_11.IsRejected)
	|	AND Reconciliation.Organization IN (&Organization)
	|	AND (&ForAllCounterparties OR Reconciliation.Counterparty IN (&Counterparty))
	|	AND TSDetailedRecords.PaymentType_ IN (&TypesOfCalculations_)
	|	AND Reconciliation.BeginOfPeriod <= &EndOfPeriod
	|	AND Reconciliation.EndOfPeriod >= &BeginOfPeriod
	|	AND TRUE IN (SELECT TOP 1 TRUE 
	|				FROM 
	|					TTARAPDocuments AS SettlementDocuments
	|				WHERE
	|					SettlementDocuments.Ref = TSDetailedRecords.ARAPDocument)
	|	
	|GROUP BY
	|	Reconciliation.Ref,
	|	Reconciliation.Status,
	|	Reconciliation.ThereAreDiscrepancies,
	|	Reconciliation.BeginOfPeriod,
	|	Reconciliation.EndOfPeriod,
	|	Reconciliation.Counterparty,
	|	Reconciliation.Organization,
	|	TSDetailedRecords.ARAPDocument,
	|	TSDetailedRecords.DocumentNumber,
	|	TSDetailedRecords.DocumentDate,
	|	DocumentsRegistry.IBDocumentNumber,
	|	DocumentsRegistry.IBDocumentDate
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Reconciliation_Results.Ref AS Ref,
	|	Reconciliation_Results.Number AS Number,
	|	Reconciliation_Results.Date AS Date,
	|	Reconciliation_Results.Currency AS Currency,
	|	Reconciliation_Results.Status AS Status,
	|	Reconciliation_Results.EDIState AS EDIState,
	|	Reconciliation_Results.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	Reconciliation_Results.BeginOfPeriod AS BeginOfPeriod,
	|	Reconciliation_Results.EndOfPeriod AS EndOfPeriod,
	|	Reconciliation_Results.Counterparty AS Counterparty,
	|	Reconciliation_Results.Organization AS Organization,
	|	Reconciliation_Results.ClosingBalanceDr AS ClosingBalanceDr,
	|	Reconciliation_Results.ClosingBalanceCr AS ClosingBalanceCr,
	|	Reconciliation_Results.ClosingBalanceDrCounterparty AS ClosingBalanceDrCounterparty,
	|	Reconciliation_Results.ClosingBalanceCrCounterparty AS ClosingBalanceCrCounterparty,
	|	
	|	ISNULL(ReconciliationOfDetails.ARAPDocument, UNDEFINED) AS ARAPDocument,
	|	ReconciliationOfDetails.DocumentNumber AS DocumentNumber,
	|	ReconciliationOfDetails.DocumentDate AS DocumentDate,
	|	ReconciliationOfDetails.IBDocumentNumber AS IBDocumentNumber,
	|	ReconciliationOfDetails.IBDocumentDate AS IBDocumentDate,
	|	ReconciliationOfDetails.SumDr AS SumDr,
	|	ReconciliationOfDetails.DrAmountCounterparty AS DrAmountCounterparty,
	|	ReconciliationOfDetails.SumCr AS SumCr,
	|	ReconciliationOfDetails.CrAmountCounterparty AS CrAmountCounterparty
	|	
	|INTO TTReconciliationDocuments
	|FROM
	|	TTReconciliationDocumentsTotals AS Reconciliation_Results
	|	LEFT JOIN TTReconciliationDocumentsDetails AS ReconciliationOfDetails
	|	ON Reconciliation_Results.Ref = ReconciliationOfDetails.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Date AS Date,
	|	NestedQuery.Document AS Document,
	|	NestedQuery.PresentationOfDocument AS PresentationOfDocument,
	|	NestedQuery.PresentationOfDocumentCompany AS PresentationOfDocumentCompany,
	|	NestedQuery.PresentationOfDocumentCounterparty AS PresentationOfDocumentCounterparty,
	|	NestedQuery.Operation AS Operation,
	|	NestedQuery.CompanyOperation AS CompanyOperation,
	|	NestedQuery.CounterpartyOperation AS CounterpartyOperation,
	|	NestedQuery.DocumentNumber AS DocumentNumber,
	|	NestedQuery.DocumentDate AS DocumentDate,
	|	NestedQuery.IBDocumentNumber AS IBDocumentNumber,
	|	NestedQuery.IBDocumentDate AS IBDocumentDate,
	|	SUM(NestedQuery.CompanyAmount) AS CompanyAmount,
	|	SUM(NestedQuery.CounterpartyAmount) AS CounterpartyAmount,
	|	SUM(NestedQuery.AmountOfCompanyInSettlementCurrency) AS AmountOfCompanyInSettlementCurrency,
	|	SUM(NestedQuery.AmountOfCounterpartyInSettlementCurrency) AS AmountOfCounterpartyInSettlementCurrency
	|INTO TTServiceDataReconciliation20Preliminary
	|FROM
	|	(SELECT
	|		UNDEFINED AS Organization,
	|		UNDEFINED AS Counterparty,
	|		UNDEFINED AS Date,
	|		UNDEFINED AS Document,
	|		UNDEFINED AS PresentationOfDocument,
	|		UNDEFINED AS PresentationOfDocumentCompany,
	|		UNDEFINED AS PresentationOfDocumentCounterparty,
	|		UNDEFINED AS Operation,
	|		UNDEFINED AS CompanyOperation,
	|		UNDEFINED AS CounterpartyOperation,
	|		UNDEFINED AS DocumentNumber,
	|		UNDEFINED AS DocumentDate,
	|		UNDEFINED AS IBDocumentNumber,
	|		UNDEFINED AS IBDocumentDate,
	|		0.00 AS CompanyAmount,
	|		0.00 AS CounterpartyAmount,
	|		0.00 AS AmountOfCompanyInSettlementCurrency,
	|		0.00 AS AmountOfCounterpartyInSettlementCurrency
	|	WHERE
	|		FALSE
	|	) AS NestedQuery
	|	
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Date,
	|	NestedQuery.Document,
	|	NestedQuery.PresentationOfDocument,
	|	NestedQuery.PresentationOfDocumentCompany,
	|	NestedQuery.PresentationOfDocumentCounterparty,
	|	NestedQuery.Operation,
	|	NestedQuery.CompanyOperation,
	|	NestedQuery.CounterpartyOperation,
	|	NestedQuery.DocumentNumber,
	|	NestedQuery.DocumentDate,
	|	NestedQuery.IBDocumentNumber,
	|	NestedQuery.IBDocumentDate
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Counterparty AS Counterparty,
	|	MAX(NestedQuery.DateOfOperationOfSettlement) AS DateOfOperationOfSettlement,
	|	MAX(NestedQuery.ReconciliationPeriodEnd) AS MaximumEndOfReconciliationPeriod
	|FROM  
	|	(SELECT
	|		SettlementDocuments.Organization AS Organization,
	|		SettlementDocuments.Counterparty AS Counterparty,
	|		SettlementDocuments.Period AS DateOfOperationOfSettlement,
	|		DATETIME(1,1,1) AS ReconciliationPeriodEnd
	|	FROM
	|		TTARAPDocuments AS SettlementDocuments
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reconciliation_Results.Organization AS Organization,
	|		Reconciliation_Results.Counterparty AS Counterparty,
	|		DATETIME(1,1,1) AS DateOfOperationOfSettlement,
	|		Reconciliation_Results.EndOfPeriod AS MaximumEndOfReconciliationPeriod
	|	FROM
	|		TTReconciliationDocumentsTotals AS Reconciliation_Results
	|	) AS NestedQuery
	|	
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.Counterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	REFPRESENTATION(NestedQuery.Ref) AS RefPresentation,
	|	NestedQuery.Currency AS Currency,
	|	NestedQuery.Status AS Status,
	|	ISNULL(NestedQuery.EDIState, UNDEFINED) AS EDIState,
	|	NestedQuery.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	NestedQuery.BeginOfPeriod AS BeginOfPeriod,
	|	NestedQuery.EndOfPeriod AS EndOfPeriod,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Organization AS Organization,
	|	
	|	NestedQuery.ClosingBalanceDr AS TotalDebtOfCounterparty,
	|	NestedQuery.ClosingBalanceCr AS TotalOfOurDebt,
	|	NestedQuery.ClosingBalanceDrCounterparty AS CounterpartyTotalCounterpartySDebt,
	|	NestedQuery.ClosingBalanceCrCounterparty AS CounterpartyTotalOfOurDebt,
	|		
	|	NestedQuery.ARAPDocument AS ARAPDocument,
	|	CASE 
	|		WHEN NestedQuery.ARAPDocument = UNDEFINED
	|			THEN NestedQuery.PresentationOfDocument
	|		ELSE
	|			REFPRESENTATION(NestedQuery.ARAPDocument)
	|	END AS PresentationOfDocument,
	|	NestedQuery.DocumentNumber AS DocumentNumber,
	|	NestedQuery.DocumentDate AS DocumentDate,
	|	NestedQuery.IBDocumentNumber AS IBDocumentNumber,
	|	NestedQuery.IBDocumentDate AS IBDocumentDate,
	|	SUM(NestedQuery.SumDr) AS CounterpartySDebt,
	|	SUM(NestedQuery.DrAmountCounterparty) AS CounterpartyCounterpartySDebt,
	|	SUM(NestedQuery.SumCr) AS AccountsPayableOfCompany,
	|	SUM(NestedQuery.CrAmountCounterparty) AS CounterpartyIsOurDebt,
	|	CASE 
	|		WHEN NestedQuery.ThereAreDiscrepancies
	|			THEN SUM(NestedQuery.DrAmountCounterparty) - SUM(NestedQuery.SumDr)
	|		ELSE 0
	|	END AS DiscrepancyInCounterpartyDebt,
	|	CASE 
	|		WHEN NestedQuery.ThereAreDiscrepancies
	|			THEN SUM(NestedQuery.CrAmountCounterparty) - SUM(NestedQuery.SumCr)
	|		ELSE 0
	|	END AS DiscrepancyIsOurDebt,
	|	SUM(NestedQuery.CompanyAmount) AS CompanyAmount,
	|	SUM(NestedQuery.CounterpartyAmount) AS CounterpartyAmount
	|FROM 
	|	(SELECT
	|		DetailedRecords.Ref AS Ref,
	|		DetailedRecords.Number AS Number,
	|		DetailedRecords.Date AS Date,
	|		DetailedRecords.Currency AS Currency,
	|		DetailedRecords.Status AS Status,
	|		DetailedRecords.EDIState AS EDIState,
	|		DetailedRecords.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|		DetailedRecords.BeginOfPeriod AS BeginOfPeriod,
	|		DetailedRecords.EndOfPeriod AS EndOfPeriod,
	|		DetailedRecords.Counterparty AS Counterparty,
	|		DetailedRecords.Organization AS Organization,
	|		
	|		DetailedRecords.ClosingBalanceDr AS ClosingBalanceDr,
	|		DetailedRecords.ClosingBalanceCr AS ClosingBalanceCr,
	|		DetailedRecords.ClosingBalanceDrCounterparty AS ClosingBalanceDrCounterparty,
	|		DetailedRecords.ClosingBalanceCrCounterparty AS ClosingBalanceCrCounterparty,
	|		
	|		DetailedRecords.ARAPDocument AS ARAPDocument,
	|		UNDEFINED AS PresentationOfDocument,
	|		DetailedRecords.DocumentNumber AS DocumentNumber,
	|		DetailedRecords.DocumentDate AS DocumentDate,
	|		DetailedRecords.IBDocumentNumber AS IBDocumentNumber,
	|		DetailedRecords.IBDocumentDate AS IBDocumentDate,
	|		DetailedRecords.SumDr AS SumDr,
	|		DetailedRecords.DrAmountCounterparty AS DrAmountCounterparty,
	|		DetailedRecords.SumCr AS SumCr,
	|		DetailedRecords.CrAmountCounterparty AS CrAmountCounterparty,
	|		0 AS CompanyAmount,
	|		0 AS CounterpartyAmount
	|	FROM
	|		TTReconciliationDocuments AS DetailedRecords
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Number,
	|	NestedQuery.Date,
	|	NestedQuery.Currency,
	|	NestedQuery.Status,
	|	ISNULL(NestedQuery.EDIState, UNDEFINED),
	|	NestedQuery.ThereAreDiscrepancies,
	|	NestedQuery.BeginOfPeriod,
	|	NestedQuery.EndOfPeriod,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Organization,
	|	NestedQuery.ARAPDocument,
	|	NestedQuery.PresentationOfDocument,
	|	NestedQuery.DocumentNumber,
	|	NestedQuery.DocumentDate,
	|	NestedQuery.IBDocumentNumber,
	|	NestedQuery.IBDocumentDate,
	|	NestedQuery.ClosingBalanceDr,
	|	NestedQuery.ClosingBalanceCr,
	|	NestedQuery.ClosingBalanceDrCounterparty,
	|	NestedQuery.ClosingBalanceCrCounterparty
	|	
	|ORDER BY
	|	NestedQuery.Date,
	|	NestedQuery.Number,
	|	NestedQuery.BeginOfPeriod,
	|	NestedQuery.EndOfPeriod,
	|	NestedQuery.Organization,
	|	NestedQuery.Counterparty,
	|	NestedQuery.IBDocumentDate,
	|	NestedQuery.IBDocumentNumber";
	
	If Not GetFunctionalOption("LocalizationRFService") Then
		QueryText = StrReplace(QueryText,"EDOStates.EDIState","UNDEFINED");
	EndIf;
	
	Return QueryText;

EndFunction

#EndRegion

#EndIf