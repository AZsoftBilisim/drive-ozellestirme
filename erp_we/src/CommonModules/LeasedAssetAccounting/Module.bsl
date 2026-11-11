////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "FA lease".
// 
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region MonthEndTransactions

#Region AccrualOfLeaseInterest

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_AccrualOfLeaseInterest(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.AccrualOfLeaseInterest);
	
	NewRow.MultilingualName = "vi = 'Tính lãi thuê';
								|ru = 'Начисление процентов по аренде';
								|en = 'Accrual of rental interest';
								|it = 'Maturazione degli interessi relativi all''affitto';
								|pl = 'Naliczenie procentów z tytułu dzierżawy';
								|tr = 'Kiraya göre faiz tahakkuk ettirilmesi'"; // @NStr-1
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual);
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.IntangibleAssetAmortizationAccrual);
	
	NewRow.TextExecute = NStr("vi = 'Tính';
								|ru = 'Начислить';
								|en = 'Accrue'; fa = 'محاسبه';
								|it = 'Начислить';
								|pl = 'Accrue';
								|tr = 'Tahakkuk et'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"LeasedAssetAccounting.Use_AccrualOfLeaseInterest");
		
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"LeasedAssetAccounting.Perform_AccrualOfRentalInterest");
		
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AccrualOfLeaseInterest.Forms.ListForm.FullName());
	
EndProcedure

// Determines the status of the operation "Accrual of interest on the lease".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure Use_AccrualOfLeaseInterest(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	If Not GetFunctionalOption("UseNonCurrentAssets2_2")
		And Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Kế toán tài sản dài hạn bị vô hiệu hóa.';
				|ru = 'Учет внеоборотных активов отключен.';
				|en = 'Accounting of fixed assets disabled.'; fa = 'Accounting of fixed assets disabled.';
				|it = 'La contabilità degli attivi non circolanti è disattivata.';
				|pl = 'Ewidencja aktyw pozaobrotowych jest odłączona.';
				|tr = 'Duran varlıkların muhasebeleştirilmesi devre dışı bırakılmıştır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	ElsIf Not NonCurrentAssets.VNAManagementIsUsed_2_4(CalculationParameters.BeginOfPeriod) Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không sử dụng ghi nhận tài sản dài hạn phiên bản 2.4.';
				|ru = 'Не используется учет внеоборотных активов версии 2.4.';
				|en = 'Fixed assets accounting version 2.4 is not used.'; fa = 'Fixed assets accounting version 2.4 is not used.';
				|it = 'Non viene utilizzata la contabilità degli attivi non correnti della versione 2.4.';
				|pl = 'Nie jest używana ewidencja aktyw trwałych wersji 2.4.';
				|tr = 'Duran varlıkların muhasebesi sürüm 2.4 kullanılmamaktadır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If Not LeaseAccountingAccordingToFSB25_2018IsUsed(CalculationParameters.CompanyArray, CalculationParameters.BeginOfPeriod) Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có doanh nghiệp mà trong chính sách kế toán đã sử dụng thuê theo chuẩn kế toán';
				|ru = 'Нет организаций, для которых в учетной политике включен учет аренды по стандарту ФСБУ 25/2018';
				|en = 'There are no companies, for which the accounting policy includes lease accounting according to the Russian GAAP (FSBU 25/2018 standard)'; fa = 'There are no companies, for which the accounting policy includes lease accounting according to the Russian GAAP (FSBU 25/2018 standard)';
				|it = 'Non ci sono organizzazioni per le quali nella politica contabile sia attivata la contabilità di affitto ai sensi dei parametri degli Standard Federali di Contabilità 25/2018';
				|pl = 'Brak organizacji, dla których w polityce ewidencyjnej włączona jest ewidencja dzierżawy wg standardu FSBU 25/2018';
				|tr = 'Muhasebe politikaları FAS 25/2018 uyarınca kiralama muhasebesini içeren iş yerleri yoktur'", Common.DefaultLanguageCode()));
		Return;
		
	EndIf;
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True) Then
		Return;
	EndIf;
	
	MonthEndTransactionsServer.CheckAvailabilityOfRegulatoryDocumentOfClosingStageOfMonth(HandlerParameters, "AccrualOfLeaseInterest");
	
EndProcedure

// Performs the operation "Accrual of interest on the lease".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure Perform_AccrualOfRentalInterest(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	If Not NonCurrentAssets.TransitionToVNAHasBeenCompleted24(CalculationParameters.Period, CalculationParameters.CompanyArray) Then
		Return;
	EndIf;
	
	PerformOperationAccrualOfInterestOnLease(HandlerParameters);
	
EndProcedure

#EndRegion

#Region AccrueProfitableRentalInterest

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_AccrueProfitableRentalInterest(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.AccrueProfitableRentalInterest);
	
	NewRow.MultilingualName = "vi = 'Tính phần trăm theo thu nhập từ cho thuê';
								|ru = 'Начисление процентов по доходной аренде';
								|en = 'Accrue profitable rental interest';
								|it = 'Начисление процентов по доходной аренде';
								|pl = 'Accrue profitable rental interest';
								|tr = 'Kazançlı kiralama kapsamında faiz tahakkuku'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Tính toán';
								|ru = 'Начислить';
								|en = 'Charge'; fa = 'Charge';
								|it = 'Начислить';
								|pl = 'Charge';
								|tr = 'Tahakkuk et'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"LeasedAssetAccounting.Use_AccrualOfInterestOnProfitableLeases");
		
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"LeasedAssetAccounting.Perform_AccrualOfInterestOnProfitableLease");
		
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AccrualOfLeaseInterest.Forms.ListForm.FullName());
	
EndProcedure

// Determines the Status of Operation "Accrual of percentages to a profitable dividend".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure Use_AccrualOfInterestOnProfitableLeases(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	If Not GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Chuyển cho thuê/cho thuê lại có tính đến thu nhập lãi bị vô hiệu hóa.';
				|ru = 'Передача в аренду/субаренду с начислением процентного дохода отключена.';
				|en = 'Rental/sublease with interest income charge is disabled.'; fa = 'Rental/sublease with interest income charge is disabled.';
				|it = 'Передача в аренду/субаренду с начислением процентного дохода отключена.';
				|pl = 'Rental/sublease with interest income charge is disabled.';
				|tr = 'Faiz geliri tahakkuk ettirilerek kiraya/alt kiralamaya devri devre dışı bırakıldı.'", Common.DefaultLanguageCode()));
		
		Return;
		
	ElsIf Not NonCurrentAssets.VNAManagementIsUsed_2_4(CalculationParameters.BeginOfPeriod) Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không sử dụng ghi nhận tài sản dài hạn, phiên bản 2.4.';
				|ru = 'Не используется учет внеоборотных активов версии 2.4.';
				|en = 'Fixed assets accounting version 2.4 is not used.'; fa = 'Fixed assets accounting version 2.4 is not used.';
				|it = 'Non viene utilizzata la contabilità degli attivi non correnti della versione 2.4.';
				|pl = 'Nie jest używana ewidencja aktyw trwałych wersji 2.4.';
				|tr = 'Duran varlıkların muhasebesi sürüm 2.4 kullanılmamaktadır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True) Then
		Return;
	EndIf;
	
	MonthEndTransactionsServer.CheckAvailabilityOfRegulatoryDocumentOfClosingStageOfMonth(HandlerParameters, "AccrualOfLeaseInterest");
	
EndProcedure

// Performs the Operation "Accrual of interest to the income dividend".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure Perform_AccrualOfInterestOnProfitableLease(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	If Not NonCurrentAssets.TransitionToVNAHasBeenCompleted24(CalculationParameters.Period, CalculationParameters.CompanyArray) Then
		Return;
	EndIf;
	
	PerformOperationAccrualOfInterestOnProfitableLease(HandlerParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region SearchForPaymentGroundsAndDocuments

// Creates a structure for search parameters for payment grounds and payment documents
// 
// Returns:
// 	Structure - Contains:
// 	* Companies - Undefined, CatalogRef.Companies, Array of CatalogRef.Companies -
// 	* Documents   - Array of DocumentRef - documents that are used to search for payments.
// 	* OnDate      - Date - for a cross-section of found documents on the date
// 	* RestrictPaymentDocumentTypes - Boolean - If "True", payment documents will be limited to the possible types
// 	                                                of incoming and outgoing payment documents.
// 	* LimitTypesOfPaymentGrounds  - Boolean - If "True", the payment grounds will be limited to the possible types
// 	                                                of incoming and outgoing documents.
// 	* SelectionParametersForDocumentTable - Structure - For selection according to a temporary table with documents, where:
//  	** FieldName - String - Name of the field that contains the document
//  	** SelectionTableName_ - String - name of the temporary table that contains the document
//
Function InitializeSearchParametersForPaymentBasesAndDocuments() Export
	
	SearchParameters = New Structure;
	
	SearchParameters.Insert("Companies",  Undefined);
	SearchParameters.Insert("Documents",    New Array);
	SearchParameters.Insert("OnDate",       Date(1,1,1));
	SearchParameters.Insert("RestrictPaymentDocumentTypes", False);
	SearchParameters.Insert("LimitTypesOfPaymentGrounds", False);
	
	// Documents for which it is necessary to find payment documents
	SelectionParametersForDocumentTable = New Structure;
	SelectionParametersForDocumentTable.Insert("FieldName",          "");
	SelectionParametersForDocumentTable.Insert("SelectionTableName_", "");
	
	SearchParameters.Insert("SelectionParametersForDocumentTable", SelectionParametersForDocumentTable);
	
	Return SearchParameters;
	
EndFunction

// Prepare a temporary table "Calculation by renters_The basis of the Payment document"
// Creates a temporary table with columns:
// 		Organization;
// 		Document payments - payment document;
// 		The basis of payment is a paid document;
// 		Analyticaccounts to partners;
// 		Accounting objects;
// 		Division;
// 		Directions of activity;
// 		Counterparty;
// 		Contract;
// 		Payment totals;
// 		Payment totalupr;
// 		The amount of the payment is correct.
// 
// Parameters:
// 	TempTablesManager - TempTablesManager
// 	SearchParameters         - See InitializeSearchParametersForPaymentBasesAndDocuments
Procedure PrepareVT_SettlementsWithLandlords_GroundsAndPaymentDocuments(TempTablesManager, SearchParameters) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	CatLeaseContract.Organization                  AS Organization,
	|	Calculations.ARAPDocument                      AS DocumentPayments,
	|	Calculations.Recorder                            AS BasisOfPayment,
	|	Calculations.AccountingDimensionByPartners              AS AccountingDimensionByPartners,
	|	Calculations.Contract                                AS ARAPObject,
	|	CatLeaseContract.LineOfBusiness      AS LineOfBusiness,
	|	CatLeaseContract.Counterparty                   AS Counterparty,
	|	CatLeaseContract.Ref                       AS Contract,
	|	Calculations.AmountType                               AS PaymentType,
	|	SUM(Calculations.Sum)                           AS PayAmount,
	|	SUM(Calculations.SumMan)                        AS ManPaymentAmount,
	|	SUM(Calculations.SumCompl)                       AS PaymentAmountLocal
	|INTO SettlementsWithLandlords_GroundsAndPaymentDocuments
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS Calculations
	|		INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|		ON Calculations.ARAPDocument = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection
	|		INNER JOIN Catalog.LeaseContract AS CatLeaseContract
	|		ON Calculations.Contract = CatLeaseContract.Ref
	|WHERE
	|	(Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|	OR Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment))
	|	AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (NOT &EnableOrganizationSelection
	|		OR Calculations.AccountingDimensionByPartners.Organization IN (&Companies))
	|	AND VALUETYPE(Calculations.ARAPDocument) IN (&MTypesOfPaymentDocumentsOutgoing) 
	|	AND VALUETYPE(Calculations.Recorder) IN (&MTypesOfPaymentGroundsIncoming)
	|
	|GROUP BY
	|	Calculations.Recorder,
	|	Calculations.ARAPDocument,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Contract,
	|	Calculations.AmountType,
	|	CatLeaseContract.Ref
	|	
	|UNION ALL
	|	
	|SELECT
	|	CatLeaseContract.Organization                  AS Organization,
	|	Calculations.ARAPDocument                      AS DocumentPayments,
	|	UNDEFINED                                   AS BasisOfPayment,
	|	Calculations.AccountingDimensionByPartners              AS AccountingDimensionByPartners,
	|	Calculations.Contract                                AS ARAPObject,
	|	CatLeaseContract.LineOfBusiness      AS LineOfBusiness,
	|	CatLeaseContract.Counterparty                   AS Counterparty,
	|	CatLeaseContract.Ref                       AS Contract,
	|	Calculations.AmountType                               AS PaymentType,
	|	SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE
	|				-1
	|		END * Calculations.Sum)                           AS PayAmount,
	|	SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE
	|				-1
	|		END * Calculations.SumMan)                        AS ManPaymentAmount,
	|	SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE
	|				-1
	|		END * Calculations.SumCompl)                       AS PaymentAmountLocal
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS Calculations
	|		INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|		ON Calculations.ARAPDocument = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection
	|		INNER JOIN Catalog.LeaseContract AS CatLeaseContract
	|		ON Calculations.Contract = CatLeaseContract.Ref
	|WHERE
	|	(Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|	OR Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment))
	|	AND (NOT &EnableOrganizationSelection
	|		OR Calculations.AccountingDimensionByPartners.Organization IN (&Companies))
	|	AND VALUETYPE(Calculations.ARAPDocument) IN (&MTypesOfPaymentDocumentsOutgoing)
	|	AND (Calculations.Recorder = Calculations.ARAPDocument
	|	OR VALUETYPE(Calculations.Recorder) IN (&MTypesOfPaymentGroundsIncoming)
	|	OR VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) AND Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment))
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Contract,
	|	Calculations.AmountType,
	|	CatLeaseContract.Ref
	|
	|HAVING
	|	SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE
	|				-1
	|		END * Calculations.Sum) <> 0
	|	OR SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE
	|				-1
	|		END * Calculations.SumMan) <> 0
	|	OR SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE
	|				-1
	|		END * Calculations.SumCompl) <> 0
	|	
	|UNION ALL
	|	
	|SELECT
	|	CatLeaseContract.Organization                  AS Organization,
	|	Calculations.Recorder                            AS DocumentPayments,
	|	Calculations.ARAPDocument                      AS BasisOfPayment,
	|	Calculations.AccountingDimensionByPartners              AS AccountingDimensionByPartners,
	|	Calculations.Contract                                AS ARAPObject,
	|	CatLeaseContract.LineOfBusiness      AS LineOfBusiness,
	|	CatLeaseContract.Counterparty                   AS Counterparty,
	|	CatLeaseContract.Ref                       AS Contract,
	|	Calculations.AmountType                               AS PaymentType,
	|	SUM(Calculations.Sum)                           AS PayAmount,
	|	SUM(Calculations.SumMan)                        AS ManPaymentAmount,
	|	SUM(Calculations.SumCompl)                       AS PaymentAmountLocal
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS Calculations
	|		INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|		ON Calculations.Recorder = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection
	|		INNER JOIN Catalog.LeaseContract AS CatLeaseContract
	|		ON Calculations.Contract = CatLeaseContract.Ref
	|WHERE
	|	Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|	AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND (NOT &EnableOrganizationSelection
	|		OR Calculations.AccountingDimensionByPartners.Organization IN (&Companies))
	|	AND VALUETYPE(Calculations.Recorder) IN (&MTypesOfPaymentDocumentsOutgoing)
	|
	|GROUP BY
	|	Calculations.Recorder,
	|	Calculations.ARAPDocument,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Contract,
	|	Calculations.AmountType,
	|	CatLeaseContract.Ref";
	
	RequestPostProcessing_SearchForPaymentGroundsAndDocuments(Query, SearchParameters);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Other

// Adds the values of the parameters to make a document accounting for the lease.
// 
// Parameters:
// 	ValuesOfHoldingParameters - Structure - 
Procedure SupplementValuesOfDocumentParameters(ValuesOfHoldingParameters) Export
	
	ValuesOfHoldingParameters.Insert("BO_ReceivingLeaseServices", Enums.BusinessTransactions.ReceivingLeaseServices);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReceiptOfRentalServices", Catalogs.BusinessTransactionsSettings.ReceivingLeaseServices);

	ValuesOfHoldingParameters.Insert("BO_DepositPayment", Enums.BusinessTransactions.DepositPayment);
	ValuesOfHoldingParameters.Insert("SettingUpHO_SecurityPayment", Catalogs.BusinessTransactionsSettings.DepositPayment);

	ValuesOfHoldingParameters.Insert("BO_VendorInvoiceLeasedAssets", Enums.BusinessTransactions.VendorInvoiceLeasedAssets);
	ValuesOfHoldingParameters.Insert("SettingUpHO_BuyoutOfLeasedFA", Catalogs.BusinessTransactionsSettings.VendorInvoiceLeasedAssets);

	ValuesOfHoldingParameters.Insert("BO_AccrualOfVATInPartOfLeaseService", Enums.BusinessTransactions.AccrualOfVATInPartOfLeaseService);
	ValuesOfHoldingParameters.Insert("SettingUpHO_AccrualOfNDSVPartOfRentalService", Catalogs.BusinessTransactionsSettings.AccrualOfVATInPartOfLeaseService);

	ValuesOfHoldingParameters.Insert("BO_AccrualOfVATInPartOfSecurityPayment", Enums.BusinessTransactions.AccrualOfVATInPartOfSecurityPayment);
	ValuesOfHoldingParameters.Insert("SettingUpHO_AccrualOfPersonalIncomeTaxPartOfSecurityPayment", Catalogs.BusinessTransactionsSettings.AccrualOfVATInPartOfSecurityPayment);

	ValuesOfHoldingParameters.Insert("BO_AccrualOfVATInPartOfBuyoutValue", Enums.BusinessTransactions.AccrualOfVATInPartOfBuyoutValue);
	ValuesOfHoldingParameters.Insert("SettingUpHO_AccrualOfNdsvPartOfRedemptionValue", Catalogs.BusinessTransactionsSettings.AccrualOfVATInPartOfBuyoutValue);

	ValuesOfHoldingParameters.Insert("BO_RecordingLeaseServicesInExpenses", Enums.BusinessTransactions.RecordingLeaseServicesInExpenses);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReflectingRentalServicesInExpenses", Catalogs.BusinessTransactionsSettings.RecordingLeaseServicesInExpenses);

	ValuesOfHoldingParameters.Insert("BO_SecurityPaymentForOffBalanceAccounting", Enums.BusinessTransactions.SecurityPaymentForOffBalanceAccounting);
	ValuesOfHoldingParameters.Insert("SettingUpHO_SecurityPaymentWhenAccountingForBalance", Catalogs.BusinessTransactionsSettings.SecurityPaymentForOffBalanceAccounting);

	ValuesOfHoldingParameters.Insert("BO_ReceiptOfVATInPartOfLeaseService", Enums.BusinessTransactions.ReceiptOfVATInPartOfLeaseService);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReceiptOfNDSVPartOfRentalService", Catalogs.BusinessTransactionsSettings.ReceiptOfVATInPartOfLeaseService);

	ValuesOfHoldingParameters.Insert("BO_ReceiptOfVATInPartOfSecurityPayment", Enums.BusinessTransactions.ReceiptOfVATInPartOfSecurityPayment);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReceiptOfPersonalIncomeTaxPartOfSecurityPayment", Catalogs.BusinessTransactionsSettings.ReceiptOfVATInPartOfSecurityPayment);

	ValuesOfHoldingParameters.Insert("BO_ReceiptOfVATInPartOfBuyoutValue", Enums.BusinessTransactions.ReceiptOfVATInPartOfBuyoutValue);
	ValuesOfHoldingParameters.Insert("SetupHO_ReceiptOfNDSVPartOfRedemptionValue", Catalogs.BusinessTransactionsSettings.ReceiptOfVATInPartOfBuyoutValue);

	ValuesOfHoldingParameters.Insert("BO_ReceiptOfVATInPartOfBuyoutValue", Enums.BusinessTransactions.ReceiptOfVATInPartOfBuyoutValue);
	ValuesOfHoldingParameters.Insert("SetupHO_ReceiptOfNDSVPartOfRedemptionValue", Catalogs.BusinessTransactionsSettings.ReceiptOfVATInPartOfBuyoutValue);

	ValuesOfHoldingParameters.Insert("BO_OffsettingLeaseServicePaymentsAgainstBuyoutPayables", Enums.BusinessTransactions.OffsettingLeaseServicePaymentsAgainstBuyoutPayables);
	ValuesOfHoldingParameters.Insert("SetupHO_OffsetPaymentForRentalServicesAtExpenseOfPurchasePrice", Catalogs.BusinessTransactionsSettings.OffsettingLeaseServicePaymentsAgainstBuyoutPayables);

	ValuesOfHoldingParameters.Insert("BO_SettlementOfDepositPaymentAgainstBuyoutValue", Enums.BusinessTransactions.SettlementOfDepositPaymentAgainstBuyoutValue);
	ValuesOfHoldingParameters.Insert("SettingUpHO_SETTINGSecurityPaymentAgainstPurchasePrice", Catalogs.BusinessTransactionsSettings.SettlementOfDepositPaymentAgainstBuyoutValue);

	ValuesOfHoldingParameters.Insert("BO_SettlementOfPrepaymentForLeaseAssetBuyout", Enums.BusinessTransactions.SettlementOfPrepaymentForLeaseAssetBuyout);
	ValuesOfHoldingParameters.Insert("SettingUpHO_OffsettingAdvanceOfRedemptionValueAgainstRedemptionValue", Catalogs.BusinessTransactionsSettings.SettlementOfPrepaymentForLeaseAssetBuyout);
	
	ValuesOfHoldingParameters.Insert("BO_WriteOffOfLeaseInterest", Enums.BusinessTransactions.WriteOffOfLeaseInterest);
	ValuesOfHoldingParameters.Insert("SettingUpHO_WriteOffRentalInterest", Catalogs.BusinessTransactionsSettings.WriteOffOfLeaseInterest);
	
	ValuesOfHoldingParameters.Insert("BO_VATWriteOffOnLease", Enums.BusinessTransactions.VATWriteOffOnLease);
	ValuesOfHoldingParameters.Insert("SettingsHO_DeductionOfVATForRent", Catalogs.BusinessTransactionsSettings.VATWriteOffOnLease);
	
	ValuesOfHoldingParameters.Insert("BO_WriteOffOfDisregardedCostTA", Enums.BusinessTransactions.WriteOffOfDisregardedCostTA);
	ValuesOfHoldingParameters.Insert("SettingUpHO_WriteOffUnrecordedValueTa", Catalogs.BusinessTransactionsSettings.WriteOffOfDisregardedCostTA);
	
	ValuesOfHoldingParameters.Insert("BO_RecordingLeaseLiabilitiesInExpenses", Enums.BusinessTransactions.RecordingLeaseLiabilitiesInExpenses);
	ValuesOfHoldingParameters.Insert("SettingHO_ReflectionOfLeaseObligationsInExpenses", Catalogs.BusinessTransactionsSettings.RecordingLeaseLiabilitiesInExpenses);

	ValuesOfHoldingParameters.Insert("BO_RecordingLeaseLiabilitiesInIncome", Enums.BusinessTransactions.RecordingLeaseLiabilitiesInIncome);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReflectionOfLeaseObligationsInIncome", Catalogs.BusinessTransactionsSettings.RecordingLeaseLiabilitiesInIncome);

	ValuesOfHoldingParameters.Insert("BO_LeasedFixedAssetsCostAddition", Enums.BusinessTransactions.LeasedFixedAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("SettingUpHO_IncreasingCostOfRentedFA", Catalogs.BusinessTransactionsSettings.LeasedFixedAssetsCostAddition);
	
	ValuesOfHoldingParameters.Insert("BO_DecreaseOfLeasedFixedAssetsCost", Enums.BusinessTransactions.DecreaseOfLeasedFixedAssetsCost);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReducingCostOfLeasedFA", Catalogs.BusinessTransactionsSettings.DecreaseOfLeasedFixedAssetsCost);

	ValuesOfHoldingParameters.Insert("BO_IncreaseOfVATOnLease", Enums.BusinessTransactions.IncreaseOfVATOnLease);
	ValuesOfHoldingParameters.Insert("SettingUpHO_IncreaseInRentalVAT", Catalogs.BusinessTransactionsSettings.IncreaseOfVATOnLease);

	ValuesOfHoldingParameters.Insert("BO_DecreaseOfVATOnLease", Enums.BusinessTransactions.DecreaseOfVATOnLease);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReductionOfVATForRent", Catalogs.BusinessTransactionsSettings.DecreaseOfVATOnLease);

	ValuesOfHoldingParameters.Insert("BO_IncreaseOfLeaseInterest", Enums.BusinessTransactions.IncreaseOfLeaseInterest);
	ValuesOfHoldingParameters.Insert("SettingUpHO_IncreaseInRentalInterest", Catalogs.BusinessTransactionsSettings.IncreaseOfLeaseInterest);

	ValuesOfHoldingParameters.Insert("BO_DecreaseOfLeaseInterest", Enums.BusinessTransactions.DecreaseOfLeaseInterest);
	ValuesOfHoldingParameters.Insert("SettingUpHO_DecreaseInRentalInterest", Catalogs.BusinessTransactionsSettings.DecreaseOfLeaseInterest);

	ValuesOfHoldingParameters.Insert("BO_OverchargedLeaseInterest", Enums.BusinessTransactions.OverchargedLeaseInterest);
	ValuesOfHoldingParameters.Insert("SettingUpHO_UnnecessarilyAccruedRentalInterest", Catalogs.BusinessTransactionsSettings.OverchargedLeaseInterest);

	ValuesOfHoldingParameters.Insert("BO_UnderchargedLeaseInterest", Enums.BusinessTransactions.UnderchargedLeaseInterest);
	ValuesOfHoldingParameters.Insert("SettingUpHO_NonAccruedRentalInterest", Catalogs.BusinessTransactionsSettings.UnderchargedLeaseInterest);

EndProcedure

// Determines whether at least one fixed asset is accounted for on the lessee's balance sheet
// 
// Parameters:
// 	ListOfFA - Array of CatalogRef.Assets
// 	Date - Date -
// Returns:
// 	Boolean -
Function ThereAreRentalItemsOnTenantSBalanceSheet(ListOfFA, Date) Export

	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Date, FixedAsset IN (&ListOfFA)) AS LeasedAsset
	|WHERE
	|	LeasedAsset.Contract.AssetHolder = VALUE(Enum.LeasedAssetHolder.Leaseholder)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not Result.IsEmpty();
	
EndFunction

// Determines whether the fixed asset has been leased .
// 
// Parameters:
//  FixedAsset - CatalogRef.Assets - Fixed asset.
//  Date - Date - On the date.
// 
// Returns:
//  Boolean - True if the OS is leased.
Function FixedAssetsAreLeased(FixedAsset, Date) Export

	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Date, FixedAsset = &FixedAsset) AS LeasedAsset
	|WHERE
	|	LeasedAsset.State IN (
	|		VALUE(Enum.FixedAssetsStates.InLease),
	|		VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting))";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("FixedAsset", FixedAsset);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not Result.IsEmpty();
	
EndFunction

// Determines whether lease accounting is used in accordance with the FSB 25/2018 standard.
//
// Parameters:
//  Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined -
//   The organization for which the accounting procedure is being checked:
//  Period	 - Date - On what date to check (if not specified, it is checked for the current date).
//  ConsiderBeginningOfTransition - Boolean - True, if you need to take into account the beginning of the transition to a new standard.
// 
// Returns:
//  Boolean - True if lease accounting is used according to FSB 
//                    25/2018 for the specified organization or for any organization if the organization is not specified.
//
Function LeaseAccountingAccordingToFSB25_2018IsUsed(Organization = Undefined, Period = '000101010000', ConsiderBeginningOfTransition = False) Export

	LeaseAccountingAccordingToFSB25_2018IsUsed = LeasedAssetAccountingLocalization.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Period, ConsiderBeginningOfTransition);
	
	LeaseAccountingAccordingToFSB25_2018IsUsed = 
		LeaseAccountingAccordingToFSB25_2018IsUsed = Undefined
		Or LeaseAccountingAccordingToFSB25_2018IsUsed = True;
		
	Return LeaseAccountingAccordingToFSB25_2018IsUsed;
	
EndFunction
 
// Defines the start date of lease accounting in accordance with the FSB 25/2018 standard
// 
// Parameters:
// 	Organization - CatalogRef.Companies -
// Returns:
// 	Date - 
Function StartOfLeaseAccountingUnderFSB25_2018(Organization) Export

	TheBeginningOfTheAccounting = LeasedAssetAccountingLocalization.StartOfLeaseAccountingUnderFSB25_2018(Organization);

	Return ?(TheBeginningOfTheAccounting <> Undefined, TheBeginningOfTheAccounting, '000101010000');

EndFunction

// Determines whether the document has been created for the transition to FSB25 2018.
// 
// Parameters:
//  DocumentDate - Date - Document date
//  Organization - CatalogRef.Companies - Organization
// 
// Returns:
//  Boolean - Created for the transition to FSB25 2018
Function CreatedForSwitchingToFSB25_2018(DocumentDate, Organization) Export
	
	Return EndOfDay(DocumentDate) + 1 = StartOfLeaseAccountingUnderFSB25_2018(Organization);
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportsOptions(Settings) Export
	
	LeasedAssetAccountingLocalization.CustomizeReportsOptions(Settings);

	Reports.LeasedAsset.CustomizeReportOptions(Settings);
	Reports.LeaseContractARAPStatement.CustomizeReportOptions(Settings);
	Reports.VarianceAnalysisOfPaymentsAndAccrualsForLease.CustomizeReportOptions(Settings);

EndProcedure

// Defines configuration objects whose manager modules have a procedure for adding Report commands
// describing commands for opening contextual reports.
// For the syntax of the Add Report Commands procedure, see the documentation.
//
// Parameters:
//   Objects - Array of MetadataObject - metadata objects with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export

	Objects.Add(Metadata.Catalogs.LeaseContract);
	Objects.Add(Metadata.Documents.OBEntryOfLeaseSettlements);
	Objects.Add(Metadata.Documents.VendorInvoiceLeasedAssets);
	Objects.Add(Metadata.Documents.SigningOfLeaseContract);
	Objects.Add(Metadata.Documents.LeaseTermAdjustment);
	Objects.Add(Metadata.Documents.ChangeRentalTerms);
	Objects.Add(Metadata.Documents.ReceivingLeaseServices);
	Objects.Add(Metadata.Documents.LeaseTermination);
	Objects.Add(Metadata.DataProcessors.JournalOfLeaseDocuments);

EndProcedure

// Adds roles to the profile that allow you to work in the "Accounting for leased FA" subsystem with change rights.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRolesToAccessSubsystemInResponseToChange(ProfileDetails) Export

	ProfileDetails.Roles.Add("AddEditLeaseContracts");

	ProfileDetails.Roles.Add("AddEditOBEntryOfLeaseSettlements");
	ProfileDetails.Roles.Add("AddEditEnterRentalInvestmentBalance");
	ProfileDetails.Roles.Add("AddEditBuyoutOfLeasedAssets");
	ProfileDetails.Roles.Add("AddEditLeaseTermCommitments");
	ProfileDetails.Roles.Add("AddEditFixedAssetsLeaseTermsModifications");
	ProfileDetails.Roles.Add("AddEditChangeRentalTerms");
	ProfileDetails.Roles.Add("AddEditLeaseInterestAccruals");
	ProfileDetails.Roles.Add("AddEditLeaseServiceReceipts");
	ProfileDetails.Roles.Add("AddEditLeaseContractsTerminations");
	
	ProfileDetails.Roles.Add("ReadRentalInvestments");

	ProfileDetails.Roles.Add("UseLeaseDocumentsJournalDataProcessor");
	ProfileDetails.Roles.Add("ViewOfLeaseAccrualsAndPaymentsVarianceAnalysisReport");
	ProfileDetails.Roles.Add("UseDataProcessor");

	ProfileDetails.Roles.Add("FixedAssetsSubsystem");
	ProfileDetails.Roles.Add("SectionFixedAssets");

EndProcedure

// Adds roles to the profile that allow you to work in the "Accounting for leased FA" subsystem with read permissions.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRolesForReadAccessToVNASubsystem(ProfileDetails) Export

	ProfileDetails.Roles.Add("ReadLeaseContracts");

	ProfileDetails.Roles.Add("ReadOBEntryOfLeaseSettlements");
	ProfileDetails.Roles.Add("ReadEnterRentalInvestmentBalance");
	ProfileDetails.Roles.Add("ReadPurchasesOfLeasedFixedAssets");
	ProfileDetails.Roles.Add("ReadLeaseContractsSigning");
	ProfileDetails.Roles.Add("ReadFixedAssetsLeaseTermsModifications");
	ProfileDetails.Roles.Add("ReadChangeRentalTerms");
	ProfileDetails.Roles.Add("ReadLeaseInterestAccruals");
	ProfileDetails.Roles.Add("ReadInvoicesForLeaseServices");
	ProfileDetails.Roles.Add("ReadLeaseContractsTerminations");
	
	ProfileDetails.Roles.Add("ReadRentalInvestments");

	ProfileDetails.Roles.Add("FAAccountantSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ReportsOfFixedAssetSection");

	ProfileDetails.Roles.Add("FixedAssetsSubsystem");
	ProfileDetails.Roles.Add("SectionFixedAssets");

EndProcedure

// Generates entries in the task registers by the end of the month.
// 
// Parameters:
// 	Document - DocumentObject -
// 	TablesData - See DocumentsPosting.OldStructureTableData
Procedure GenerateTaskRegisterEntries(Document, TablesData) Export

	LeasedAssetAccountingLocalization.GenerateTaskRegisterEntries(Document, TablesData);

	GenerateTasksForCalculatingRentalInterest(TablesData);

	CreateTasksForAccrualOfInterestOnProfitableLeases(Document, TablesData);
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	// Adding update handlers
	
EndProcedure

#Region Reports

// Adds a report command to the list of commands.
// 
// Parameters:
//	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
Procedure AddLeaseSettlementStatementReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.LeaseContractARAPStatement)
		And NonCurrentAssets.VNAManagementIsUsed() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.LeaseContractARAPStatement.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hạch toán công nợ theo hợp đồng';
											|ru = 'Ведомость расчетов по договору';
											|en = 'Contract AR/AP'; fa = 'دریافتنی/پرداختنی قرارداد';
											|it = 'Dichiarazione dei conti in base all''accordo';
											|pl = 'Zestawienie rozliczeń z tytułu umowy';
											|tr = 'Sözleşmeye ilişkin ödemeler tablosu'");
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = True;
		ReportCommand.AdditionalParameters.Insert("CommandName", "ByCustomerContract");
		ReportCommand.VariantKey = "ByCustomerContract";
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region SearchForPaymentGroundsAndDocuments

// Sets the necessary parameters for executing requests based on settlement data
//
// Parameters:
//  Query           - Query - 
//  SearchParameters  - See InitializeSearchParametersForPaymentBasesAndDocuments
Procedure RequestPostProcessing_SearchForPaymentGroundsAndDocuments(Query, SearchParameters)
	
	// Data preparation
	
	// - organizations
	If ValueIsFilled(SearchParameters.Companies) Then
		Companies                 = SearchParameters.Companies;
		EnableOrganizationSelection = True;
	Else
		Companies                 = Undefined;
		EnableOrganizationSelection = False;
	EndIf;
	
	// - initialization of the document table for selection
	TypesOfSelectionDocuments = New Array;
	
	For Each Document In SearchParameters.Documents Do
		TypesOfSelectionDocuments.Add(TypeOf(Document));
	EndDo;
	
	DocumentsTable = New ValueTable;
	DocumentsTable.Columns.Add("DocumentOfSelection", New TypeDescription(TypesOfSelectionDocuments));
	
	For Each Document In SearchParameters.Documents Do
		NewString = DocumentsTable.Add();
		NewString.DocumentOfSelection = Document;
	EndDo;
	
	// - types of payment documents
	
	TypesOfPaymentDocumentsOutgoing = New Array;
	TypesOfPaymentDocumentsOutgoing.Add(Type("DocumentRef.BankAccountIssue"));
	TypesOfPaymentDocumentsOutgoing.Add(Type("DocumentRef.CashVoucher"));
	TypesOfPaymentDocumentsOutgoing.Add(Type("DocumentRef.SourceDocument"));
	TypesOfPaymentDocumentsOutgoing.Add(Type("DocumentRef.ARAPSettlement"));
	
	// - types of payment bases (objects)
	
	TypesOfPaymentBasesIncoming = New Array;
	TypesOfPaymentBasesIncoming.Add(Type("DocumentRef.SourceDocument"));
	TypesOfPaymentBasesIncoming.Add(Type("DocumentRef.ReceivingLeaseServices"));
	
	// Setting parameters
	
	Query.SetParameter("Companies",                        Companies);
	Query.SetParameter("DocumentsTable",                  DocumentsTable);
	Query.SetParameter("EnableOrganizationSelection",        EnableOrganizationSelection);
	Query.SetParameter("RestrictPaymentDocumentTypes",     SearchParameters.RestrictPaymentDocumentTypes);
	Query.SetParameter("LimitTypesOfPaymentGrounds",      SearchParameters.LimitTypesOfPaymentGrounds);
	Query.SetParameter("MTypesOfPaymentDocumentsOutgoing",    TypesOfPaymentDocumentsOutgoing);
	Query.SetParameter("MTypesOfPaymentGroundsIncoming",      TypesOfPaymentBasesIncoming);
		
	// Request text processing
	
	// - The text of the selection of documents
	
	FilterFieldName    = SearchParameters.SelectionParametersForDocumentTable.FieldName;
	SelectionTableName_ = SearchParameters.SelectionParametersForDocumentTable.SelectionTableName_;
	
	TimeTableSelectionIsSet = ValueIsFilled(SelectionTableName_) And ValueIsFilled(FilterFieldName);
	
	If Not TimeTableSelectionIsSet Then
		
		SelectionTableName_ = "TableOfSelectionOfGroundsAndPaymentDocuments";
		FilterFieldName    = "DocumentOfSelection";
		
		RequestTextForCreatingSelectionTable = 
		"SELECT DISTINCT
		|	DocumentsTable.DocumentOfSelection AS DocumentOfSelection
		|INTO TableOfSelectionOfGroundsAndPaymentDocuments_Preliminary
		|FROM
		|	&DocumentsTable AS DocumentsTable
		|;
		|
		|SELECT
		|	DocumentsTable.DocumentOfSelection
		|INTO TableOfSelectionOfGroundsAndPaymentDocuments
		|FROM
		|	TableOfSelectionOfGroundsAndPaymentDocuments_Preliminary AS DocumentsTable
		|
		|INDEX BY
		|	DocumentOfSelection
		|;
		|
		|DROP TableOfSelectionOfGroundsAndPaymentDocuments_Preliminary
		|";
		
	Else
		
		RequestTextForCreatingSelectionTable = 
		"SELECT DISTINCT
		|	NameOfDocumentField AS DocumentOfSelection,
		|	ARAPObjects.Ref AS ARAPObject
		|INTO TableOfSelectionOfGroundsAndPaymentDocuments
		|FROM
		|	NameOfBaseSelectionTableAndPaymentDocuments AS DocumentsTable
		|
		|INDEX BY
		|	DocumentOfSelection
		|";
		
	EndIf;
	
	QueryTextFromSelectionTable = "DROP TableOfSelectionOfGroundsAndPaymentDocuments";
	
	Query.Text = RequestTextForCreatingSelectionTable
					+ Common.QueryBatchSeparator() + Query.Text
					+ Common.QueryBatchSeparator() + QueryTextFromSelectionTable;
	
	Query.Text = StrReplace(Query.Text, "NameOfBaseSelectionTableAndPaymentDocuments", SelectionTableName_);
	Query.Text = StrReplace(Query.Text, "NameOfDocumentField",                           FilterFieldName);
	
EndProcedure

#EndRegion

#Region DeferredFARecordGeneration

// 
// Parameters:
//  ListOfRequests - Array of String - List of requests
//  TTUsed - Array of String - Temporary Tables Used
Procedure ToSupplementParametersOfDelayedFormationOfRegisteredRecorded(ListOfRequests, TTUsed) Export
	
	TTUsed.Add("TT_FinancialInstrumentsARAP");
	TTUsed.Add("TT_InvestmentInRent");
	
	#Region TT_FinancialInstrumentsARAP
	QueryText = 
	"SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Contract AS Contract,
	|	LeasedAsset.Contract.Organization AS Organization,
	|	LeasedAsset.Contract.Partner AS Partner,
	|	LeasedAsset.Contract.Counterparty AS Counterparty,
	|	LeasedAsset.Contract.LineOfBusiness AS LineOfBusiness
	|
	|INTO LeasedAsset
	|
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(
	|		&EndOfPreviousMonth,
	|		FixedAsset IN (SELECT T.AccountingObject FROM TTDataToBeCalculated AS T)) AS LeasedAsset
	|WHERE
	|	LeasedAsset.State IN (
	|		VALUE(Enum.FixedAssetsStates.LeaseContractsSigned), 
	|		VALUE(Enum.FixedAssetsStates.InLease))
	|
	|UNION ALL
	|
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Contract AS Contract,
	|	LeasedAsset.Contract.Organization AS Organization,
	|	LeasedAsset.Contract.Partner AS Partner,
	|	LeasedAsset.Contract.Counterparty AS Counterparty,
	|	LeasedAsset.Contract.LineOfBusiness AS LineOfBusiness
	|
	|FROM
	|	InformationRegister.LeasedAsset AS LeasedAsset
	|
	|WHERE
	|	LeasedAsset.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND LeasedAsset.Active
	|	AND LeasedAsset.State IN (
	|		VALUE(Enum.FixedAssetsStates.LeaseContractsSigned), 
	|		VALUE(Enum.FixedAssetsStates.InLease))
	|
	|	AND LeasedAsset.FixedAsset IN (SELECT T.AccountingObject FROM TTDataToBeCalculated AS T)
	|
	|INDEX BY
	|	Organization,
	|	Partner,
	|	Counterparty,
	|	LineOfBusiness
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataForCalculation.Ref AS Ref,
	|	DataForCalculation.Date AS Date,
	|	LeasedAsset.Contract AS Contract
	|
	|INTO DataForCalculationRent
	|
	|FROM
	|	TTDataToBeCalculated AS DataForCalculation
	|
	|		INNER JOIN LeasedAsset AS LeasedAsset
	|		ON LeasedAsset.FixedAsset = DataForCalculation.AccountingObject
	|
	|INDEX BY
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	LeasedAsset.Contract AS Contract,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS DimensionKey
	|
	|INTO FilterCalculations
	|
	|FROM
	|	LeasedAsset AS LeasedAsset
	|
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON RegisterAccountingAnalyticsForPartners.Organization = LeasedAsset.Organization
	|			AND RegisterAccountingAnalyticsForPartners.Partner = LeasedAsset.Partner
	|			AND RegisterAccountingAnalyticsForPartners.Counterparty = LeasedAsset.Counterparty 
	|			AND RegisterAccountingAnalyticsForPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND RegisterAccountingAnalyticsForPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|INDEX BY
	|	DimensionKey,
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.AmountType AS AmountType,
	|	RegisterData.ARAPDocument AS ARAPDocument,
	|	RegisterData.Currency AS Currency,
	|	RegisterData.SumBalance AS Sum,
	|	RegisterData.SumManBalance AS SumMan,
	|	RegisterData.SumComplBalance AS SumCompl
	|INTO FinancialInstrumentsARAP_Balance
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|			&BegOfMonth,
	|			(AccountingDimensionByPartners, Contract) IN
	|				(SELECT
	|					FilterCalculations.DimensionKey,
	|					FilterCalculations.Contract
	|				FROM
	|					FilterCalculations AS FilterCalculations)) AS RegisterData
	|INDEX BY
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.AmountType AS AmountType,
	|	RegisterData.ARAPDocument AS ARAPDocument,
	|	RegisterData.Currency AS Currency,
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.Sum
	|		ELSE -RegisterData.Sum
	|	END AS Sum,
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.SumMan
	|		ELSE -RegisterData.SumMan
	|	END AS SumMan,
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.SumCompl
	|		ELSE -RegisterData.SumCompl
	|	END AS SumCompl
	|
	|INTO SettlementsOnFinancialInstruments_RegisteredRecords
	|
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS RegisterData
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND RegisterData.Active
	|
	|	AND (RegisterData.AccountingDimensionByPartners, RegisterData.Contract) IN
	|				(SELECT
	|					FilterCalculations.DimensionKey,
	|					FilterCalculations.Contract
	|				FROM
	|					FilterCalculations AS FilterCalculations)
	|INDEX BY
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForCalculationRent.Ref AS Ref,
	|	DataForCalculationRent.Date,
	|	DataForCalculationRent.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	DataForCalculationRent.Contract AS Contract,
	|	DataForCalculationRent.AmountType AS AmountType,
	|	DataForCalculationRent.ARAPDocument AS ARAPDocument,
	|	DataForCalculationRent.Currency AS Currency,
	|
	|	SUM(DataForCalculationRent.Sum) AS Sum,
	|	SUM(DataForCalculationRent.SumMan) AS SumMan,
	|	SUM(DataForCalculationRent.SumCompl) AS SumCompl
	|
	|INTO TT_FinancialInstrumentsARAP
	|
	|FROM
	|	(SELECT
	|		DataForCalculationRent.Ref AS Ref,
	|		DataForCalculationRent.Date AS Date,
	|		DataForCalculationRent.Contract AS Contract,
	|		RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		RegisterData.AmountType AS AmountType,
	|		RegisterData.ARAPDocument AS ARAPDocument,
	|		RegisterData.Currency AS Currency,
	|		ISNULL(RegisterData.Sum, 0) AS Sum,
	|		ISNULL(RegisterData.SumMan, 0) AS SumMan,
	|		ISNULL(RegisterData.SumCompl, 0) AS SumCompl
	|	FROM
	|		DataForCalculationRent AS DataForCalculationRent
	|
	|			LEFT JOIN FinancialInstrumentsARAP_Balance AS RegisterData
	|			ON (RegisterData.Contract = DataForCalculationRent.Contract)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataForCalculationRent.Ref,
	|		DataForCalculationRent.Date,
	|		DataForCalculationRent.Contract,
	|		RegisterData.AccountingDimensionByPartners,
	|		RegisterData.AmountType,
	|		RegisterData.ARAPDocument,
	|		RegisterData.Currency,
	|		ISNULL(RegisterData.Sum, 0),
	|		ISNULL(RegisterData.SumMan, 0),
	|		ISNULL(RegisterData.SumCompl, 0)
	|	FROM
	|		DataForCalculationRent AS DataForCalculationRent
	|
	|			LEFT JOIN SettlementsOnFinancialInstruments_RegisteredRecords AS RegisterData
	|			ON (RegisterData.Contract = DataForCalculationRent.Contract)
	|				AND (RegisterData.Recorder <> DataForCalculationRent.Ref)
	|				AND (RegisterData.Period <= DataForCalculationRent.Date
	|					OR RegisterData.Recorder REFS Document.AccrualOfLeaseInterest)
	|
	|	) AS DataForCalculationRent
	|
	|GROUP BY
	|	DataForCalculationRent.Ref,
	|	DataForCalculationRent.Date,
	|	DataForCalculationRent.AccountingDimensionByPartners,
	|	DataForCalculationRent.Contract,
	|	DataForCalculationRent.AmountType,
	|	DataForCalculationRent.ARAPDocument,
	|	DataForCalculationRent.Currency
	|
	|INDEX BY
	|	Ref,
	|	Contract
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region TT_InvestmentInRent
	QueryText = 
	"SELECT
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.Currency AS Currency,
	|	RegisterData.FixedAsset AS FixedAsset,
	|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RegisterData.RentalPaymentsBalance AS RentalPayments,
	|	RegisterData.RentalPaymentsLocalBalance AS RentalPaymentsLocal,
	|	RegisterData.RentalPaymentsManagBalance AS RentalPaymentsManag,
	|	RegisterData.NonGuaranteedResidualValueLocalBalance AS NonGuaranteedResidualValueLocal,
	|	RegisterData.NonGuaranteedResidualValueManagBalance AS NonGuaranteedResidualValueManag,
	|	RegisterData.InterestDiscountBalance AS InterestDiscount,
	|	RegisterData.InterestDiscountManBalance AS InterestDiscountMan,
	|	RegisterData.InterestDiscountLocalBalance AS InterestDiscountLocal
	|INTO InvestmentInRent_Balance
	|FROM
	|	AccumulationRegister.InvestmentInRent.Balance(
	|			&BegOfMonth,
	|			(Organization, FixedAsset) IN
	|				(SELECT
	|					DataForCalculation.Organization,
	|					DataForCalculation.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS DataForCalculation)) AS RegisterData
	|INDEX BY
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.Currency AS Currency,
	|	RegisterData.FixedAsset AS FixedAsset,
	|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.RentalPayments
	|		ELSE -RegisterData.RentalPayments
	|	END AS RentalPayments,
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.RentalPaymentsLocal
	|		ELSE -RegisterData.RentalPaymentsLocal
	|	END AS RentalPaymentsLocal,
	|
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.RentalPaymentsManag
	|		ELSE -RegisterData.RentalPaymentsManag
	|	END AS RentalPaymentsManag,
	|
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.NonGuaranteedResidualValueLocal
	|		ELSE -RegisterData.NonGuaranteedResidualValueLocal
	|	END AS NonGuaranteedResidualValueLocal,
	|
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.NonGuaranteedResidualValueManag
	|		ELSE -RegisterData.NonGuaranteedResidualValueManag
	|	END AS NonGuaranteedResidualValueManag,
	|
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.InterestDiscount
	|		ELSE -RegisterData.InterestDiscount
	|	END AS InterestDiscount,
	|
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.InterestDiscountMan
	|		ELSE -RegisterData.InterestDiscountMan
	|	END AS InterestDiscountMan,
	|
	|	CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN RegisterData.InterestDiscountLocal
	|		ELSE -RegisterData.InterestDiscountLocal
	|	END AS InterestDiscountLocal
	|
	|INTO InvestmentInRent_RegisteredRecords
	|FROM
	|	AccumulationRegister.InvestmentInRent AS RegisterData
	|WHERE
	|	RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND RegisterData.Active
	|
	|	AND (RegisterData.Organization, RegisterData.FixedAsset) IN
	|		(SELECT
	|			DataForCalculation.Organization,
	|			DataForCalculation.AccountingObject
	|		FROM
	|			TTDataToBeCalculated AS DataForCalculation)
	|
	|	AND NOT RegisterData.Recorder IN
	|		(SELECT
	|			DataForCalculation.Ref
	|		FROM
	|			TTDataToBeCalculated AS DataForCalculation)
	|INDEX BY
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForCalculation.Ref AS Ref,
	|	DataForCalculation.Date,
	|	DataForCalculation.Organization AS Organization,
	|	DataForCalculation.AccountingObject AS AccountingObject,
	|
	|	MAX(DataForCalculation.Contract) AS Contract,
	|	MAX(DataForCalculation.Currency) AS Currency,
	|	MAX(DataForCalculation.FinancialAccountingGroup) AS FinancialAccountingGroup,
	|
	|	SUM(DataForCalculation.RentalPayments) AS RentalPayments,
	|	SUM(DataForCalculation.RentalPaymentsLocal) AS RentalPaymentsLocal,
	|	SUM(DataForCalculation.RentalPaymentsManag) AS RentalPaymentsManag,
	|	SUM(DataForCalculation.NonGuaranteedResidualValueLocal) AS NonGuaranteedResidualValueLocal,
	|	SUM(DataForCalculation.NonGuaranteedResidualValueManag) AS NonGuaranteedResidualValueManag,
	|	SUM(DataForCalculation.InterestDiscount) AS InterestDiscount,
	|	SUM(DataForCalculation.InterestDiscountMan) AS InterestDiscountMan,
	|	SUM(DataForCalculation.InterestDiscountLocal) AS InterestDiscountLocal
	|
	|INTO TT_InvestmentInRent
	|FROM
	|	(SELECT
	|		DataForCalculation.Ref AS Ref,
	|		DataForCalculation.Date AS Date,
	|		DataForCalculation.Organization AS Organization,
	|		DataForCalculation.AccountingObject AS AccountingObject,
	|		InvestmentInRent.Contract AS Contract,
	|		InvestmentInRent.Currency AS Currency,
	|		InvestmentInRent.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ISNULL(InvestmentInRent.RentalPayments, 0) AS RentalPayments,
	|		ISNULL(InvestmentInRent.RentalPaymentsLocal, 0) AS RentalPaymentsLocal,
	|		ISNULL(InvestmentInRent.RentalPaymentsManag, 0) AS RentalPaymentsManag,
	|		ISNULL(InvestmentInRent.NonGuaranteedResidualValueLocal, 0) AS NonGuaranteedResidualValueLocal,
	|		ISNULL(InvestmentInRent.NonGuaranteedResidualValueManag, 0) AS NonGuaranteedResidualValueManag,
	|		ISNULL(InvestmentInRent.InterestDiscount, 0) AS InterestDiscount,
	|		ISNULL(InvestmentInRent.InterestDiscountMan, 0) AS InterestDiscountMan,
	|		ISNULL(InvestmentInRent.InterestDiscountLocal, 0) AS InterestDiscountLocal
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN InvestmentInRent_Balance AS InvestmentInRent
	|			ON (InvestmentInRent.FixedAsset = DataForCalculation.AccountingObject)
	|				AND (InvestmentInRent.Organization = DataForCalculation.Organization)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataForCalculation.Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization,
	|		DataForCalculation.AccountingObject,
	|		InvestmentInRent.Contract AS Contract,
	|		InvestmentInRent.Currency AS Currency,
	|		InvestmentInRent.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ISNULL(InvestmentInRent.RentalPayments, 0) AS RentalPayments,
	|		ISNULL(InvestmentInRent.RentalPaymentsLocal, 0) AS RentalPaymentsLocal,
	|		ISNULL(InvestmentInRent.RentalPaymentsManag, 0) AS RentalPaymentsManag,
	|		ISNULL(InvestmentInRent.NonGuaranteedResidualValueLocal, 0) AS NonGuaranteedResidualValueLocal,
	|		ISNULL(InvestmentInRent.NonGuaranteedResidualValueManag, 0) AS NonGuaranteedResidualValueManag,
	|		ISNULL(InvestmentInRent.InterestDiscount, 0) AS InterestDiscount,
	|		ISNULL(InvestmentInRent.InterestDiscountMan, 0) AS InterestDiscountMan,
	|		ISNULL(InvestmentInRent.InterestDiscountLocal, 0) AS InterestDiscountLocal
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN InvestmentInRent_RegisteredRecords AS InvestmentInRent
	|			ON (InvestmentInRent.FixedAsset = DataForCalculation.AccountingObject)
	|				AND (InvestmentInRent.Organization = DataForCalculation.Organization)
	|				AND (InvestmentInRent.Recorder <> DataForCalculation.Ref)
	|				AND (VALUETYPE(InvestmentInRent.Recorder) <> TYPE(Document.RegisterAdjustment)
	|						OR InvestmentInRent.Period <= DataForCalculation.Date)
	|
	|	) AS DataForCalculation
	|
	|GROUP BY
	|	DataForCalculation.Ref,
	|	DataForCalculation.Date,
	|	DataForCalculation.Organization,
	|	DataForCalculation.AccountingObject
	|HAVING
	|	SUM(DataForCalculation.RentalPayments) <> 0
	|	OR SUM(DataForCalculation.RentalPaymentsLocal) <> 0
	|	OR SUM(DataForCalculation.RentalPaymentsManag) <> 0
	|	OR SUM(DataForCalculation.NonGuaranteedResidualValueLocal) <> 0
	|	OR SUM(DataForCalculation.NonGuaranteedResidualValueManag) <> 0
	|	OR SUM(DataForCalculation.InterestDiscount) <> 0
	|	OR SUM(DataForCalculation.InterestDiscountMan) <> 0
	|	OR SUM(DataForCalculation.InterestDiscountLocal) <> 0
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject,
	|	Organization,
	|	Currency
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
EndProcedure

// Generates the query text in the table.
// 
// Parameters:
//  Query - Query - 
// 	QueryTexts - ValueList of String - 
Procedure QueryTextTableTTCostsUponTerminationOfLease(Query, QueryTexts) Export

	TableName = "TTCostsUponTerminationOfLease";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);

	QueryText =
	"SELECT
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN SUM(CalculationsBalance.Sum) > 0
	|			THEN SUM(CalculationsBalance.Sum)
	|		ELSE 0
	|	END AS Sum,
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|				AND SUM(CalculationsBalance.SumMan) > 0
	|			THEN SUM(CalculationsBalance.SumMan)
	|		WHEN &ARAPCurrency <> &ManagementAccountingCurrency
	|				AND SUM(CalculationsBalance.Sum) > 0
	|			THEN SUM(CalculationsBalance.Sum * &ConversionRateToManCurrency)
	|		ELSE 0
	|	END AS SumMan,
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|				AND SUM(CalculationsBalance.SumCompl) > 0
	|			THEN SUM(CalculationsBalance.SumCompl)
	|		WHEN &ARAPCurrency <> &LocalAccountingCurrency
	|				AND SUM(CalculationsBalance.Sum) > 0
	|			THEN SUM(CalculationsBalance.Sum * &FactorOfConversionToCurrencyOfRegul)
	|		ELSE 0
	|	END AS SumCompl,
	|	&DocumentID AS FinRecordID,
	|	&BO_RecordingLeaseLiabilitiesInExpenses AS BusinessOperation,
	|	&SettingHO_ReflectionOfLeaseObligationsInExpenses AS BusinessTransactionSetting
	|INTO TTCostsUponTerminationOfLease
	|FROM
	|	(SELECT
	|		CalculationsBalance.Sum AS Sum,
	|		CalculationsBalance.SumMan AS SumMan,
	|		CalculationsBalance.SumCompl AS SumCompl
	|	FROM
	|		TT_FinancialInstrumentsARAP AS CalculationsBalance
	|	WHERE
	|		CalculationsBalance.Ref = &Ref
	|		AND CalculationsBalance.Contract = &Contract
	|		AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTChangeInLeaseLiabilities.Sum,
	|		TTChangeInLeaseLiabilities.SumMan,
	|		TTChangeInLeaseLiabilities.SumCompl
	|	FROM
	|		TTChangeInLeaseLiabilities AS TTChangeInLeaseLiabilities) AS CalculationsBalance
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|
	|GROUP BY
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)
	|
	|HAVING
	|	(CASE
	|			WHEN SUM(CalculationsBalance.Sum) > 0
	|				THEN SUM(CalculationsBalance.Sum)
	|			ELSE 0
	|		END <> 0
	|		OR CASE
	|			WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|					AND SUM(CalculationsBalance.SumMan) > 0
	|				THEN SUM(CalculationsBalance.SumMan)
	|			WHEN &ARAPCurrency <> &ManagementAccountingCurrency
	|					AND SUM(CalculationsBalance.Sum) > 0
	|				THEN SUM(CalculationsBalance.Sum * &ConversionRateToManCurrency)
	|			ELSE 0
	|		END <> 0
	|		OR CASE
	|			WHEN &ARAPCurrency = &LocalAccountingCurrency
	|					AND SUM(CalculationsBalance.SumCompl) > 0
	|				THEN SUM(CalculationsBalance.SumCompl)
	|			WHEN &ARAPCurrency <> &LocalAccountingCurrency
	|					AND SUM(CalculationsBalance.Sum) > 0
	|				THEN SUM(CalculationsBalance.Sum * &FactorOfConversionToCurrencyOfRegul)
	|			ELSE 0
	|		END <> 0)";

	QueryTexts.Add(QueryText, TableName, True);

EndProcedure

// Generates the query text in the table.
// 
// Parameters:
//  Query - Query - 
// 	QueryTexts - ValueList of String - 
Procedure QueryTextTableTTIncomeUponTerminationOfLease(Query, QueryTexts) Export

	TableName = "TTIncomeUponTerminationOfLease";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);

	QueryText =
	"SELECT
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	CASE
	|		WHEN SUM(CalculationsBalance.Sum) < 0
	|
	|			THEN -SUM(CalculationsBalance.Sum)
	|
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|				AND SUM(CalculationsBalance.SumMan) < 0
	|
	|			THEN -SUM(CalculationsBalance.SumMan)
	|
	|		WHEN &ARAPCurrency <> &ManagementAccountingCurrency
	|				AND SUM(CalculationsBalance.Sum) < 0
	|
	|			THEN - SUM(CalculationsBalance.Sum) * &ConversionRateToManCurrency
	|
	|		ELSE 0
	|	END AS SumMan,
	|	 
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|				AND SUM(CalculationsBalance.SumCompl) < 0
	|
	|			THEN -SUM(CalculationsBalance.SumCompl)
	|
	|		WHEN &ARAPCurrency <> &LocalAccountingCurrency
	|				AND SUM(CalculationsBalance.Sum) < 0
	|
	|			THEN -SUM(CalculationsBalance.Sum) * &FactorOfConversionToCurrencyOfRegul
	|
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	&DocumentID AS FinRecordID,
	|	&BO_RecordingLeaseLiabilitiesInIncome AS BusinessOperation,
	|	&SettingUpHO_ReflectionOfLeaseObligationsInIncome AS BusinessTransactionSetting
	|
	|INTO TTIncomeUponTerminationOfLease
	|
	|FROM
	|	(SELECT
	|		CalculationsBalance.Sum AS Sum,
	|		CalculationsBalance.SumMan AS SumMan,
	|		CalculationsBalance.SumCompl AS SumCompl
	|	FROM
	|		TT_FinancialInstrumentsARAP AS CalculationsBalance
	|	WHERE
	|		CalculationsBalance.Ref = &Ref
	|		AND CalculationsBalance.Contract = &Contract
	|		AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|
	|	UNION ALL
	|		
	|	SELECT
	|		TTChangeInLeaseLiabilities.Sum AS Sum,
	|		TTChangeInLeaseLiabilities.SumMan AS SumMan,
	|		TTChangeInLeaseLiabilities.SumCompl AS SumCompl
	|	FROM
	|		TTChangeInLeaseLiabilities AS TTChangeInLeaseLiabilities
	|
	|	) AS CalculationsBalance
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|GROUP BY
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)
	|
	|HAVING
	|
	|	(CASE
	|		WHEN SUM(CalculationsBalance.Sum) < 0
	|
	|			THEN -SUM(CalculationsBalance.Sum)
	|
	|		ELSE 0
	|	END <> 0
	|
	|	OR CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|				AND SUM(CalculationsBalance.SumMan) < 0
	|
	|			THEN -SUM(CalculationsBalance.SumMan)
	|
	|		WHEN &ARAPCurrency <> &ManagementAccountingCurrency
	|				AND SUM(CalculationsBalance.Sum) < 0
	|
	|			THEN - SUM(CalculationsBalance.Sum) * &ConversionRateToManCurrency
	|
	|		ELSE 0
	|	END <> 0
	|	
	|	OR CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|				AND SUM(CalculationsBalance.SumCompl) < 0
	|
	|			THEN -SUM(CalculationsBalance.SumCompl)
	|
	|		WHEN &ARAPCurrency <> &LocalAccountingCurrency
	|				AND SUM(CalculationsBalance.Sum) < 0
	|
	|			THEN -SUM(CalculationsBalance.Sum) * &FactorOfConversionToCurrencyOfRegul
	|
	|		ELSE 0
	|	END <> 0)";

	QueryTexts.Add(QueryText, TableName, True);

EndProcedure

#EndRegion

#Region AccrualOfLeaseInterest

// Called when performing the month closing operation "accrual of lease interest".
//
// Parameters:
//	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters 
Procedure PerformOperationAccrualOfInterestOnLease(HandlerParameters) Export

	BusinessOperation = Enums.BusinessTransactions.AccrualOfLeaseInterest;

	CalculationParameters = HandlerParameters.CalculationParameters;
	
	CalculationStart = MonthEndTransactionsServer.CalculationStart(
		HandlerParameters.Data_Stage.Code,
		HandlerParameters.CalculationParameters.EndOfPeriod,,
		HandlerParameters.CalculationParameters.CompanyArray);
	
	HasErrors = False;
	
	While CalculationStart <= CalculationParameters.EndOfPeriod Do
		
		KeyOperationName = StringFunctionsClientServer.SubstituteParametersToString(
			"MonthEndTransactions.%1",
			TrimAll(HandlerParameters.Data_Stage.Code));
			
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperationName);
		DataVolume = 0;
		
		JobNumber = MonthEndTransactionsServer.IncreaseTaskNumber();
		
		PeriodEnding = EndOfMonth(CalculationStart);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
		
		JobNumber = InformationRegisters.JobsForMonthEndClosing.IncreaseTaskNumber();
		
		BeginTransaction();
		
		Try
			
			 MonthEndTransactionsServer.BlockTaskRegister(
				JobNumber,
				AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			
			CalculationDataForMonth = MonthEndTransactionsServer.MonthlyTasks(
				CalculationStart,
				PeriodEnding,
				JobNumber,
				AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			 MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				AvailableCompanies,
				CalculationStart);
			
		EndTry;
		
		ThereAreErrorsInPerformingCalculation = False;
		
		Try
			
			If ValueIsFilled(AvailableCompanies) And Not ValueIsFilled(CalculationDataForMonth.Organization) Then
				OrganizationsToCalculate_ = New Array;
				For Each Organization In AvailableCompanies Do
					OrganizationsToCalculate_.Add(Organization);
				EndDo;
				CalculationDataForMonth.Organization = OrganizationsToCalculate_;
			EndIf;
			
			Documents.AccrualOfLeaseInterest.CreateDocuments(
							CalculationStart,
							CalculationDataForMonth.Organization,
							BusinessOperation,
							DataVolume,
							HasErrors);
		
			ThereAreErrorsInPerformingCalculation = MonthEndTransactionsServer.ThereAreErrorsInPerformingCalculation(
				HandlerParameters.Data_Stage.Code,
				AvailableCompanies, 
				CalculationStart);
											
		Except
			
			HasErrors = True;
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				AvailableCompanies,
				CalculationStart);
			
		EndTry;
		
		If ThereAreErrorsInPerformingCalculation Then
			HasErrors = True;
		EndIf;
		
		If HasErrors Then
			Break;
		EndIf;
		
		MonthEndTransactionsServer.DeleteTasksToBeCalculatedForCurPeriod(HandlerParameters, CalculationDataForMonth);
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
		
		CalculationStart = PeriodEnding + 1;
		
	EndDo;
	
EndProcedure

Procedure GenerateTasksForCalculatingRentalInterest(TablesData)
	
	If Not LeaseAccountingAccordingToFSB25_2018IsUsed() Then
		Return;
	EndIf;
	
	TablesList = New Array;
	TablesList.Add("TermsOfLeaseContracts");
	TablesList.Add("LeaseInterestAccrualSchedule");
	TablesList.Add("OtherAssetsLiabilities");
	
	DataJoinText = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TablesData);
	
	If DataJoinText = "" Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(Catalog.MonthEndClosingOperations.AccrualOfLeaseInterest) AS Operation,
	|	ChangedData.Organization AS Organization,
	|	ChangedData.Document AS Document,
	|	MIN(CASE 
	|				WHEN ChangedData.Period < &AccountingStartDate24
	|					THEN &AccountingStartDate24
	|				WHEN VALUETYPE(ChangedData.Document) = TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|					THEN DATEADD(BEGINOFPERIOD(EntryOfCapitalAssetsBalance24.Date, MONTH), MONTH, 1)
	|				WHEN VALUETYPE(ChangedData.Document) = TYPE(Document.OBEntryOfLeaseSettlements)
	|					THEN DATEADD(BEGINOFPERIOD(OBEntryOfLeaseSettlements.Date, MONTH), MONTH, 1)
	|				WHEN VALUETYPE(ChangedData.Document) = TYPE(Document.LeaseTermAdjustment)
	|					THEN BEGINOFPERIOD(LeaseTermAdjustment.Date, MONTH)
	|				ELSE ChangedData.Period
	|			END) AS Month
	|FROM
	|	DataUnionText_Redefined AS ChangedData
	|
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4 AS EntryOfCapitalAssetsBalance24
	|		ON EntryOfCapitalAssetsBalance24.Ref = ChangedData.Document
	|		LEFT JOIN Document.OBEntryOfLeaseSettlements AS OBEntryOfLeaseSettlements
	|		ON OBEntryOfLeaseSettlements.Ref = ChangedData.Document
	|		LEFT JOIN Document.LeaseTermAdjustment AS LeaseTermAdjustment
	|		ON LeaseTermAdjustment.Ref = ChangedData.Document
	|
	|GROUP BY
	|	ChangedData.Organization,
	|	ChangedData.Document";
	
	QueryText = StrReplace(QueryText, "DataUnionText_Redefined", "(" + DataJoinText + ")");
	
	TablesToUse = TMCommonUse.ListOfTemporaryTables(TablesData.TempTablesManager);

	Query = New Query(QueryText);
	Query.TempTablesManager = TablesData.TempTablesManager;
	Query.SetParameter("AccountingStartDate24", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntriesBasedOnSampleData(Selection);
	
	SetPrivilegedMode(False);
	
	TMCommonUse.DestroyTemporaryTables(TablesData.TempTablesManager,, TablesToUse);
	
EndProcedure

#EndRegion

#Region AccrueProfitableRentalInterest

// It is called when performing the month closing Operation "Accrual of interest on profitable leases".
//
// Parameters:
//	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters 
Procedure PerformOperationAccrualOfInterestOnProfitableLease(HandlerParameters) Export

	BusinessOperation = Enums.BusinessTransactions.AccrueProfitableRentalInterest;

	CalculationParameters = HandlerParameters.CalculationParameters;
	
	CalculationStart = MonthEndTransactionsServer.CalculationStart(
		HandlerParameters.Data_Stage.Code,
		HandlerParameters.CalculationParameters.EndOfPeriod,,
		HandlerParameters.CalculationParameters.CompanyArray);
	
	HasErrors = False;
	
	While CalculationStart <= CalculationParameters.EndOfPeriod Do
		
		KeyOperationName = StringFunctionsClientServer.SubstituteParametersToString(
			"MonthEndTransactions.%1",
			TrimAll(HandlerParameters.Data_Stage.Code));
			
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperationName);
		DataVolume = 0;
		
		JobNumber = MonthEndTransactionsServer.IncreaseTaskNumber();
		
		PeriodEnding = EndOfMonth(CalculationStart);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
		
		JobNumber = InformationRegisters.JobsForMonthEndClosing.IncreaseTaskNumber();
		
		BeginTransaction();
		
		Try
			
			 MonthEndTransactionsServer.BlockTaskRegister(
				JobNumber,
				AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			
			CalculationDataForMonth = MonthEndTransactionsServer.MonthlyTasks(
				CalculationStart,
				PeriodEnding,
				JobNumber,
				AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi thực hiện tính toán trong kỳ %1, đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			 MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				AvailableCompanies,
				CalculationStart);
			
		EndTry;
		
		ThereAreErrorsInPerformingCalculation = False;
		
		Try
			
			If ValueIsFilled(AvailableCompanies) And Not ValueIsFilled(CalculationDataForMonth.Organization) Then
				OrganizationsToCalculate_ = New Array;
				For Each Organization In AvailableCompanies Do
					OrganizationsToCalculate_.Add(Organization);
				EndDo;
				CalculationDataForMonth.Organization = OrganizationsToCalculate_;
			EndIf;
			
			Documents.AccrualOfLeaseInterest.CreateDocuments(
							CalculationStart,
							CalculationDataForMonth.Organization,
							BusinessOperation,
							DataVolume,
							HasErrors);
		
			ThereAreErrorsInPerformingCalculation = MonthEndTransactionsServer.ThereAreErrorsInPerformingCalculation(
				HandlerParameters.Data_Stage.Code,
				AvailableCompanies, 
				CalculationStart);
											
		Except
			
			HasErrors = True;
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				AvailableCompanies,
				CalculationStart);
			
		EndTry;
		
		If ThereAreErrorsInPerformingCalculation Then
			HasErrors = True;
		EndIf;
		
		If HasErrors Then
			Break;
		EndIf;
		
		MonthEndTransactionsServer.DeleteTasksToBeCalculatedForCurPeriod(HandlerParameters, CalculationDataForMonth);
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
		
		CalculationStart = PeriodEnding + 1;
		
	EndDo;
	
EndProcedure

Procedure CreateTasksForAccrualOfInterestOnProfitableLeases(Document, TablesData)
	
	If Not GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		Return;
	EndIf;
	
	If CalculateRentalInvestmentCost.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document) Then
		Return;
	EndIf;
	
	TablesList = New Array;
	TablesList.Add("ScheduleOfInterestChargesOnIncomeRental");
	
	DataJoinText = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TablesData, "FixedAsset");
	
	If DataJoinText = "" Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(Catalog.MonthEndClosingOperations.AccrueProfitableRentalInterest) AS Operation,
	|	ChangedData.Organization AS Organization,
	|	ChangedData.Document AS Document,
	|	MIN(CASE 
	|				WHEN ChangedData.Period < &AccountingStartDate24
	|					THEN &AccountingStartDate24
	|				WHEN VALUETYPE(ChangedData.Document) = TYPE(Document.EnterRentalInvestmentBalance)
	|					THEN DATEADD(BEGINOFPERIOD(ChangedData.Period, MONTH), MONTH, 1)
	|				ELSE ChangedData.Period
	|			END) AS Month
	|FROM
	|	DataUnionText_Redefined AS ChangedData
	|
	|GROUP BY
	|	ChangedData.Organization,
	|	ChangedData.Document
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUE(Catalog.MonthEndClosingOperations.AccrueProfitableRentalInterest) AS Operation,
	|	ChangedData.Organization AS Organization,
	|	ChangedData.Document AS Document,
	|	BEGINOFPERIOD(InvestmentInRent.Period, MONTH) AS Month
	|FROM
	|	DataUnionText_Redefined AS ChangedData
	|	INNER JOIN AccumulationRegister.InvestmentInRent AS InvestmentInRent
	|	ON InvestmentInRent.FixedAsset = ChangedData.FixedAsset
	|		AND InvestmentInRent.Period >= ChangedData.Period
	|		
	|WHERE
	|	VALUETYPE(ChangedData.Document) = TYPE(Document.ReturnAssetsFromLeasee2_4)
	|	AND InvestmentInRent.Active
	|";
	
	QueryText = StrReplace(QueryText, "DataUnionText_Redefined", "(" + DataJoinText + ")");
	
	TablesToUse = TMCommonUse.ListOfTemporaryTables(TablesData.TempTablesManager);

	Query = New Query(QueryText);
	Query.TempTablesManager = TablesData.TempTablesManager;
	Query.SetParameter("AccountingStartDate24", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntriesBasedOnSampleData(Selection);
	
	SetPrivilegedMode(False);
	
	TMCommonUse.DestroyTemporaryTables(TablesData.TempTablesManager,, TablesToUse);
	
EndProcedure

#EndRegion

#Region Other

// 
// Parameters:
//  DocumentsList - Array of String - 
Procedure ListOfSubsystemDocuments(DocumentsList) Export
	
	DocumentsList.Add("OBEntryOfLeaseSettlements");
	DocumentsList.Add("EnterRentalInvestmentBalance");
	DocumentsList.Add("VendorInvoiceLeasedAssets");
	DocumentsList.Add("SigningOfLeaseContract");
	DocumentsList.Add("LeaseTermAdjustment");
	DocumentsList.Add("ChangeRentalTerms");
	DocumentsList.Add("AccrualOfLeaseInterest");
	DocumentsList.Add("ReceivingLeaseServices");
	DocumentsList.Add("LeaseTermination");
	
EndProcedure

// Calculates the rate, cost, and schedule of interest accrual.
// 
// Parameters:
// 	CalculationParameters - See InterestRateCalculationParameters
Procedure CalculateRateCostInterest(CalculationParameters) Export
	
	If Not LeaseAccountingAccordingToFSB25_2018IsUsed(CalculationParameters.Organization, CalculationParameters.Date, True) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CalculationParameters.Contract)
		Or CalculationParameters.ServicePaymentSchedule.Count() = 0 Then
		Return;
	EndIf;
	
	If CalculationParameters.ContractDetails_ = Undefined Then
		CalculationParameters.ContractDetails_ = DetailsOfLeaseAgreement(CalculationParameters.Contract);
	EndIf;
	
	BeginOfPeriod = ?(CalculationParameters.ChangingConditions And Not CalculationParameters.CreatedForTransition,
			CalculationParameters.DateOfLeaseChange, CalculationParameters.LeaseStartDate);
	
	PaymentScheduleForDiscounting = PaymentScheduleForDiscounting(CalculationParameters.ServicePaymentSchedule, BeginOfPeriod);
	
	ScheduleOfPayments = New ValueTable; 
	ScheduleOfPayments.Columns.Add("Date", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	ScheduleOfPayments.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Any));
	
	PaymentsAmountWithoutVAT = 0;
	AdvancesBeforeStartOfLeaseWithoutVAT = 0;
	
	// We will determine the amount of the credited security payment according to the accrual schedule 
	// so that it can be taken into account when distributing it to the cost of goods
	AccruedSecurityPaymentWithoutVAT = 0;
	For Each OriginalAccrualLine In CalculationParameters.ServiceAccrualSchedule Do
		If OriginalAccrualLine.Date < BeginOfPeriod Then
			AccruedSecurityPaymentWithoutVAT = AccruedSecurityPaymentWithoutVAT
				+ OriginalAccrualLine.DepositPayment - OriginalAccrualLine.SecurityPaymentVATAmount;
		EndIf;
	EndDo;
	For Each OriginalGraphLine In PaymentScheduleForDiscounting Do		
		
		LineAmountWithoutVAT =
			OriginalGraphLine.DepositPayment - OriginalGraphLine.SecurityPaymentVATAmount
			+ OriginalGraphLine.RentalService - OriginalGraphLine.RentalServiceVAT
			+ OriginalGraphLine.BuyoutValue - OriginalGraphLine.BuyoutValueVAT;
			
		If OriginalGraphLine.Date < BeginOfPeriod Then
			If OriginalGraphLine.Date < CalculationParameters.LeaseStartDate Then
				AdvancesBeforeStartOfLeaseWithoutVAT = AdvancesBeforeStartOfLeaseWithoutVAT + LineAmountWithoutVAT;
			EndIf;
			Continue;
		EndIf;
		
		PaymentsAmountWithoutVAT = PaymentsAmountWithoutVAT + LineAmountWithoutVAT;
		
		PlotLine = ScheduleOfPayments.Add();
		PlotLine.Date = OriginalGraphLine.Date;
		PlotLine.Sum = LineAmountWithoutVAT;
		
	EndDo;
	
	If ScheduleOfPayments.Count() = 0 Then
		Return;
	EndIf;
	
	PlotLine = ScheduleOfPayments.Insert(0);
	PlotLine.Date = ?(CalculationParameters.ChangingConditions And Not CalculationParameters.CreatedForTransition, BeginOfPeriod - 86400, BeginOfPeriod);
	
	#Region CalculatingBidOrCost
	If CalculationParameters.ContractDetails_.MethodForDeterminingCostOfAssets = 
			Enums.MethodsOfDeterminingLeasedAssetCost.Manually Then
		
		If Not CalculationParameters.ChangingConditions Or CalculationParameters.CreatedForTransition Then
			CalculationParameters.PresentValue = LeasedAssetAccountingClientServer.PresentValue(
				CalculationParameters.LeaseItemsCost,
				PaymentScheduleForDiscounting,
				BeginOfPeriod);
		Else
			DistributionCoefficient = LeasedAssetAccountingClientServer.CostSharingRatio(CalculationParameters.FATable, CalculationParameters.ContractDetails_);
			
			CostOfAddedRentalItems = LeasedAssetAccountingClientServer.CostOfAddedRentalItems(CalculationParameters.FATable);
			
			CalculationParameters.PresentValue = 
				CalculationParameters.PresentValueUnderPreviousConditions
				* DistributionCoefficient
				+ CostOfAddedRentalItems;
		EndIf;
		
		If CalculationParameters.PresentValue <> 0 Then
			
			PlotLine = ScheduleOfPayments[0];
			PlotLine.Sum = -CalculationParameters.PresentValue;
			
			Try
				CalculationParameters.InterestRate = InterestRate(ScheduleOfPayments);
			Except
				CalculationParameters.InterestRate = 0;
				MessageText = NStr("vi = 'Không thể tính lãi suất. Hãy kiểm tra lịch biểu thanh toán và số tiền đầu tư của bên cho thuê.';
									|ru = 'Не удалось рассчитать процентную ставку. Проверьте график оплат и сумму вложений лизингодателя.';
									|en = 'Cannot calculate an interest rate. Check the payment schedule and amount of the lessor''s investments.'; fa = 'Cannot calculate an interest rate. Check the payment schedule and amount of the lessor''s investments.';
									|it = 'Non è stato possibile calcolare l''aliquota percentuale. Verificare il grafico dei pagamenti e l''importo dell''investimento del locatore.';
									|pl = 'Nie udało się obliczyć stopy procentowej. Sprawdź harmonogram płatności i kwotę inwestycji leasingodawcy.';
									|tr = 'Faiz oranı hesaplanamadı. Ödeme planını ve kiraya verenin yatırım miktarını kontrol edin.'");
				Common.MessageToUser(MessageText,, "SecurityDepositAmount",,);
			EndTry;
			
		Else
			CalculationParameters.InterestRate = 0;
		EndIf;
		
	Else
		
		PlotLine = ScheduleOfPayments[0];
		PlotLine.Sum = 0;
			
		CalculationParameters.PresentValue = PresentValueByRateAndSchedule(CalculationParameters.InterestRate, ScheduleOfPayments);
		
		If CalculationParameters.FATable <> Undefined Then
			
			Coefficients = New Array;
			For Each RowData In CalculationParameters.FATable Do
				If RowData.FairValue <> 0 Then
					// The distribution is proportional to the nominal values (stored in the fair value column).
					If CalculationParameters.ChangingConditions Then
						If RowData.ActionWithRentalObject <> Enums.ActionsWithRentalObjects.RentalTermination Then
							Coefficients.Add(RowData.FairValue);
						Else
							Coefficients.Add(0);
						EndIf;
					Else
						Coefficients.Add(RowData.FairValue);
					EndIf;
				Else
					Coefficients.Add(0);
				EndIf;
			EndDo;
			
			TotalCost = CalculationParameters.PresentValue + AdvancesBeforeStartOfLeaseWithoutVAT - AccruedSecurityPaymentWithoutVAT;
			AllocationResult = Common.DistributeAmountInProportionToCoefficients(TotalCost, Coefficients);
			
			If AllocationResult <> Undefined Then
				For RowIndex = 0 To AllocationResult.UBound() Do
					RowData = CalculationParameters.FATable.Get(RowIndex);
					RowData.Cost = AllocationResult[RowIndex];
				EndDo;
			EndIf;
			
		Else
			
			CalculationParameters.LeaseItemsCost = CalculationParameters.PresentValue + AdvancesBeforeStartOfLeaseWithoutVAT;

		EndIf;
		
	EndIf;
	#EndRegion
	
	#Region CompletingInterestSchedule
	If Not CalculationParameters.TheInterestAccrualScheduleIsEnteredManually Then
		
		CalculationParameters.InterestAccrualSchedule.Clear();
		CalculationParameters.InterestAmount = 0;
		
		RemainingInterest = PaymentsAmountWithoutVAT - CalculationParameters.PresentValue;
		LoanBalance = CalculationParameters.PresentValue;
		PreviousDate = CalculationParameters.LeaseStartDate;
		
		// In case of changes in the terms of the lease Contract: 
		// In the mode of transition to FSB25, the interest is recalculated from the beginning of the Contract.
		// In the usual mode, before the date of the change, the interest on the old terms, after - on the new.
		If Not CalculationParameters.CreatedForTransition Then
				
				InterestScheduleForPreviousConditions = CalculationParameters.InterestScheduleForPreviousConditions;
				For Each StringOfOldPercentages In InterestScheduleForPreviousConditions Do
					If StringOfOldPercentages.Interests > 0 Then
						LinePercentages = CalculationParameters.InterestAccrualSchedule.Add();
						FillPropertyValues(LinePercentages, StringOfOldPercentages);
					EndIf;
					PreviousDate = StringOfOldPercentages.Date;
				EndDo;
				
		EndIf;
		
		For Each PlotLine In ScheduleOfPayments Do
			
			If PlotLine.Sum < 0 Then
				Continue;
			EndIf; 

			InterestAmount = 
				LoanBalance
				* (Pow(1 + CalculationParameters.InterestRate / 100, (PlotLine.Date - PreviousDate) / 31536000) - 1);

			InterestAmount = Round(InterestAmount, 2);
			InterestAmount = Min(InterestAmount, RemainingInterest);
			InterestAmount = Max(InterestAmount, 0);
			If InterestAmount > 0 Then

				// The percentage graph should not have the same dates.The interest on one date is summed up.
				InterestLinesByDate = CalculationParameters.InterestAccrualSchedule.FindRows(New Structure("Date",
				PlotLine.Date));
				If InterestLinesByDate.Count() = 0 Then
					LinePercentages = CalculationParameters.InterestAccrualSchedule.Add();
				Else
					LinePercentages = InterestLinesByDate.Get(0);
				EndIf;
				LinePercentages.Date = PlotLine.Date;
				LinePercentages.Interests = LinePercentages.Interests + InterestAmount;
				CalculationParameters.InterestAmount = CalculationParameters.InterestAmount + InterestAmount;
				RemainingInterest = RemainingInterest - InterestAmount;
				
			EndIf;
			
			LoanBalance = Max(LoanBalance - PlotLine.Sum + InterestAmount, 0);
			
			// the rounding error is attributed to the last accrual
			If RemainingInterest > 0 And LoanBalance = 0 And LinePercentages <> Undefined Then
				LinePercentages.Interests = LinePercentages.Interests + RemainingInterest;
				CalculationParameters.InterestAmount = CalculationParameters.InterestAmount + RemainingInterest;
				RemainingInterest = 0;
			EndIf;
			
			PreviousDate = PlotLine.Date;

		EndDo;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Generates a payment schedule that can be used for discounting.
// 
// Parameters:
//  PaymentSchedule - ValueTable - Payment schedule for services.
//  BeginOfPeriod - Date - Beginning of the period
// 
// Returns:
//  ValueTable:
//	* Date - Date
//	* RentalService - Number
//	* RentalServiceVAT - Number
//	* DepositPayment - Number
//	* SecurityPaymentVATAmount - Number
//	* BuyoutValue - Number
//	* BuyoutValueVAT - Number
Function PaymentScheduleForDiscounting(PaymentSchedule, BeginOfPeriod) Export
	
	PaymentScheduleForDiscounting = PaymentSchedule.Unload();
	PaymentScheduleForDiscounting.Sort("Date");
	
	// Adding the last day of the month to the schedule, if there is no one.
	CurrentMonth = BegOfMonth(BeginOfPeriod);
	LastMonth_1 = PaymentScheduleForDiscounting[PaymentScheduleForDiscounting.Count() - 1].Date;
	While CurrentMonth <= LastMonth_1 Do
		ScheduleDate = BegOfDay(EndOfMonth(CurrentMonth));
		If PaymentScheduleForDiscounting.Find(ScheduleDate, "Date") = Undefined Then
			PlotLine = PaymentScheduleForDiscounting.Add();
			PlotLine.Date = ScheduleDate;
		EndIf;
		CurrentMonth = AddMonth(CurrentMonth, 1);
	EndDo;
	
	PaymentScheduleForDiscounting.Sort("Date");
	
	Return PaymentScheduleForDiscounting;
	
EndFunction

// Parameters used to calculate the rate, cost, and interest.
// 
// Parameters:
// 	Object - DocumentObject.OBEntryOfLeaseSettlements, DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
// 	ContractDetails_ - Structure -
// 
// Returns:
//  Structure - Calculation parameters:
//		* Organization - CatalogRef.Companies -
//		* Contract - CatalogRef.LeaseContract -
//		* Date - Date -
//		* LeaseStartDate - Date -
//		* SecurityDepositAmount - Number -
//		* LeaseServicesAmount - Number -
//		* AmountOfLeaseAssetsByuout - Number -
//		* AmountOfVATRepurchaseOfRentalItems - Number -
//		* LeaseItemsCost - Number -
//		* ServicePaymentSchedule - ValueTable:
//			** Date - Date
//			** RentalService - Number
//			** RentalServiceVAT - Number
//			** DepositPayment - Number
//			** SecurityPaymentVATAmount - Number
//			** BuyoutValue - Number
//			** BuyoutValueVAT - Number
//		* ServiceAccrualSchedule - ValueTable:
//			** Date - Date
//			** RentalService - Number
//			** RentalServiceVAT - Number
//			** DepositPayment - Number
//			** SecurityPaymentVATAmount - Number
//		* VATRate - CatalogRef.VATRates -
//		* TheInterestAccrualScheduleIsEnteredManually - Boolean -
//		* ContractDetails_ - See DetailsOfLeaseAgreement
//		* InterestAccrualSchedule - ValueTable:
//			** Date - Date
//			** Interests - Number
//		* InterestRate - Number -
//		* InterestAmount - Number -
//		* PresentValue - Number -
//
Function InterestRateCalculationParameters(Object = Undefined, ContractDetails_ = Undefined) Export
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("Organization");
	CalculationParameters.Insert("Contract");
	CalculationParameters.Insert("Date");
	CalculationParameters.Insert("LeaseStartDate");
	CalculationParameters.Insert("SecurityDepositAmount");
	CalculationParameters.Insert("LeaseServicesAmount");
	CalculationParameters.Insert("AmountOfLeaseAssetsByuout");
	CalculationParameters.Insert("AmountOfVATRepurchaseOfRentalItems");
	CalculationParameters.Insert("LeaseItemsCost");
	CalculationParameters.Insert("ServicePaymentSchedule");
	CalculationParameters.Insert("ServiceAccrualSchedule");
	CalculationParameters.Insert("VATRate");
	CalculationParameters.Insert("TheInterestAccrualScheduleIsEnteredManually");
	CalculationParameters.Insert("ContractDetails_", Undefined);
	CalculationParameters.Insert("FATable", Undefined);
	
	// Changes to the terms of the Contract
	CalculationParameters.Insert("ChangingConditions", False);
	CalculationParameters.Insert("DateOfLeaseChange", '00010101');
	CalculationParameters.Insert("CreatedForTransition", False);
	
	InterestScheduleForPreviousConditions = New ValueTable();
	InterestScheduleForPreviousConditions.Columns.Add("Date", Common.DateTypeDetails(DateFractions.Date));
	InterestScheduleForPreviousConditions.Columns.Add("Interests", TMCommonUse.MoneyFieldTypeDescription());
	CalculationParameters.Insert("InterestScheduleForPreviousConditions", InterestScheduleForPreviousConditions);
	
	// Output parameter
	CalculationParameters.Insert("InterestAccrualSchedule");
	CalculationParameters.Insert("InterestRate", 0);
	CalculationParameters.Insert("InterestAmount", 0);
	CalculationParameters.Insert("PresentValue", 0);

	If Object <> Undefined Then
		FillPropertyValues(CalculationParameters, Object);
		CalculationParameters.ServicePaymentSchedule = Object.ServicePaymentSchedule;
		CalculationParameters.ServiceAccrualSchedule = Object.ServiceAccrualSchedule;
		CalculationParameters.InterestAccrualSchedule = Object.InterestAccrualSchedule;
		CalculationParameters.ChangingConditions = LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object);
		CalculationParameters.DateOfLeaseChange = BegOfDay(Object.Date);
	EndIf;
	
	If ContractDetails_ <> Undefined Then
		CalculationParameters.ContractDetails_ = ContractDetails_;
		If ContractDetails_.MethodForDeterminingCostOfAssets = 
			Enums.MethodsOfDeterminingLeasedAssetCost.ByContractAmount Then
			CalculationParameters.InterestRate = 0;
		EndIf;
	EndIf;
	
	Return CalculationParameters;
	
EndFunction

// Fills in the payment schedule and accruals based on the data in the "Calculations" section"
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
//  ContractDetails_ - Structure - 
Procedure FillInScheduleOfPaymentsAndChargesForSettlements(Object, ContractDetails_) Export
	
	// The schedule is filled in manually.
	If (Object.PaymentFrequency = Enums.ScheduleTimeFence.Custom
			Or Not ValueIsFilled(Object.PaymentFrequency))
		And (Object.AccrualFrequency = Enums.ScheduleTimeFence.Custom
			Or Not ValueIsFilled(Object.AccrualFrequency)) Then
				
		Return;
	EndIf;
	
	EndDate = NonCurrentAssetsClientServer.EndDateByDeadline(
						Object.LeaseStartDate, Object.TermYears, Object.TermMonths, Object.TermDays);
	
	#Region ServicePaymentSchedule
	
	If Object.PaymentFrequency <> Enums.ScheduleTimeFence.Custom
		And ValueIsFilled(Object.PaymentFrequency) Then
	
		Object.ServicePaymentSchedule.Clear();

		// The security payment is paid first
		GraphLineOp = Undefined;
		If Object.SecurityDepositAmount <> 0
			And ValueIsFilled(Object.DateOfFirstSecurityPayment) Then
			
			GraphLineOp = Object.ServicePaymentSchedule.Add();
			GraphLineOp.Date = Object.DateOfFirstSecurityPayment;
			GraphLineOp.DepositPayment = Object.SecurityDepositAmount;
		
		EndIf;
		
		// Formation of schedule dates
		ScheduleDates = New Array;
		CurrentDate = Object.DateOfFirstPayment;
		While CurrentDate <= EndDate Do
			ScheduleDates.Add(CurrentDate);
			CurrentDate = LeasedAssetAccountingClientServer.NextScheduleDate(CurrentDate, Object.PaymentFrequency);
		EndDo;
		
		NumberOfDates = ScheduleDates.Count();
		
		If NumberOfDates > 0 Then
		
			AmountOfLeaseAssetsByuout = Object.AmountOfLeaseAssetsByuout;
			AdvanceRedemptionValue = Round(AmountOfLeaseAssetsByuout / NumberOfDates, 2);
					
			// Filling in the schedule
			For Cnt = 0 To NumberOfDates - 1 Do
				
				CurrentDate = ScheduleDates[Cnt];
				
				If CurrentDate = Object.DateOfFirstSecurityPayment 
					And GraphLineOp <> Undefined Then
					PlotLine = GraphLineOp
				Else
					PlotLine = Object.ServicePaymentSchedule.Add();
				EndIf;
				
				PlotLine.Date = CurrentDate;
				PlotLine.RentalService = Object.PaymentForLeaseService;
				
				If ContractDetails_.ThereIsPrepaymentOfBuyoutValue Then
					
					PlotLine.BuyoutValue = 
						?(Cnt < NumberOfDates - 1,
							Min(AdvanceRedemptionValue, AmountOfLeaseAssetsByuout),
							AmountOfLeaseAssetsByuout);
							
					AmountOfLeaseAssetsByuout = AmountOfLeaseAssetsByuout - PlotLine.BuyoutValue;
					
				EndIf;
			
			EndDo;
		
		EndIf;
		
		If ContractDetails_.ThereIsBuyoutOfLeasedAssets
			And Not ContractDetails_.ThereIsPrepaymentOfBuyoutValue
			And Object.AmountOfLeaseAssetsByuout <> 0 Then
			
			TheStructureOfTheSearch = New Structure("Date", Object.BuyoutDate);
			StringsList = Object.ServicePaymentSchedule.FindRows(TheStructureOfTheSearch);
			If StringsList.Count() = 0 Then
				PlotLine = Object.ServicePaymentSchedule.Add();
				PlotLine.Date = Object.BuyoutDate;
			Else
				PlotLine = StringsList[0];
			EndIf;
			
			PlotLine.BuyoutValue = Object.AmountOfLeaseAssetsByuout;
			
		EndIf;
		
		Object.ServicePaymentSchedule.Sort("Date");
		
	EndIf;
	
	#EndRegion

	#Region ServiceAccrualSchedule
	
	If Object.AccrualFrequency <> Enums.ScheduleTimeFence.Custom
		And ValueIsFilled(Object.AccrualFrequency) Then
	
		Object.ServiceAccrualSchedule.Clear();
			
		// Formation of schedule dates
		ScheduleDates = New Array;
		CurrentDate = Object.DateOfFirstPayment;
		While CurrentDate <= EndDate Do
			ScheduleDates.Add(CurrentDate);
			CurrentDate = LeasedAssetAccountingClientServer.NextScheduleDate(CurrentDate, Object.AccrualFrequency);
		EndDo;
		
		NumberOfDates = ScheduleDates.Count();
		
		If NumberOfDates > 0 Then
		
			SecurityDepositAmount = Object.SecurityDepositAmount;
			SecurityPaymentSettlement = Round(SecurityDepositAmount / NumberOfDates, 2);
					
			// Filling in the schedule
			For Cnt = 0 To NumberOfDates - 1 Do
				
				CurrentDate = ScheduleDates[Cnt];
				
				PlotLine = Object.ServiceAccrualSchedule.Add();
				PlotLine.Date = CurrentDate;
				PlotLine.RentalService = Object.AccrualOfLeaseService;
				
				PlotLine.DepositPayment = 
					?(Cnt < NumberOfDates - 1,
						Min(SecurityPaymentSettlement, SecurityDepositAmount),
						SecurityDepositAmount);
						
				SecurityDepositAmount = SecurityDepositAmount - PlotLine.DepositPayment;
				
			EndDo;
			
		EndIf;
		
		Object.ServicePaymentSchedule.Sort("Date");

	EndIf;

	#EndRegion

	FillInAmountsOfNDSInGraphs(Object.ServicePaymentSchedule, Object.ServiceAccrualSchedule, Object.VATRate);
	
	If Object.LeaseServicesAmount = 0 Then
		
		FillInCalculationsAccordingToScheduleOfPaymentsAndAccruals(Object, ContractDetails_);
		
	EndIf;
	
EndProcedure

// Fills in the payment schedule and accruals according to the "Calculations" section.
// A promising calculation method.
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
//  ContractDetails_ - Structure - 
Procedure FillInScheduleOfPaymentsAndAccrualsForCalculationsChangeOfConditions(Object, ContractDetails_) Export
	
	// The schedule is filled in manually.
	If (Object.PaymentFrequency = Enums.ScheduleTimeFence.Custom
			Or Not ValueIsFilled(Object.PaymentFrequency))
		And (Object.AccrualFrequency = Enums.ScheduleTimeFence.Custom
			Or Not ValueIsFilled(Object.AccrualFrequency)) Then
				
		Return;
	EndIf;
	
	EndDate = NonCurrentAssetsClientServer.EndDateByDeadline(
						Object.LeaseStartDate, Object.TermYears, Object.TermMonths, Object.TermDays);
	
	DateConditionsWereChanged = BegOfDay(Object.Date);
						
	#Region ChartsForOldConditions
	// We take the lines of the graphs before the date of the change from the previous conditions.
	
	Query = New Query();
	Query.Text = "SELECT
	|	TermsOfLeaseContractsSliceLast.EffectiveContractTerms AS PreviousConditions,
	|	TermsOfLeaseContractsSliceLast.SecurityDepositAmount AS SecurityDepositAmount,
	|	CASE
	|		WHEN TermsOfLeaseContractsSliceLast.EffectiveContractTerms REFS Document.LeaseTermAdjustment
	|			THEN BEGINOFPERIOD(CAST(TermsOfLeaseContractsSliceLast.EffectiveContractTerms AS Document.LeaseTermAdjustment).Date, DAY)
	|		ELSE TermsOfLeaseContractsSliceLast.LeaseStartDate
	|	END AS DateOfChangeOfContract
	|INTO TTPreviousConditions
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&DateConditionsWereChanged,
	|			Recorder <> &Ref
	|				AND Contract = &Contract) AS TermsOfLeaseContractsSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeaseServicesAccrualSchedule.Date AS Date,
	|	LeaseServicesAccrualSchedule.RentalService AS RentalService,
	|	LeaseServicesAccrualSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	LeaseServicesAccrualSchedule.DepositPayment AS DepositPayment,
	|	LeaseServicesAccrualSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	LeaseServicesAccrualSchedule.BuyoutValue AS BuyoutValue,
	|	LeaseServicesAccrualSchedule.BuyoutValueVAT AS BuyoutValueVAT
	|INTO AccrualScheduleIsTT
	|FROM
	|	InformationRegister.LeaseServicesAccrualSchedule AS LeaseServicesAccrualSchedule
	|		INNER JOIN TTPreviousConditions AS TTPreviousConditions
	|		ON LeaseServicesAccrualSchedule.EffectiveContractTerms = TTPreviousConditions.PreviousConditions
	|			AND (LeaseServicesAccrualSchedule.Date < &DateConditionsWereChanged)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(AccrualScheduleIsTT.DepositPayment) AS DepositPayment
	|INTO AccrualScheduleTTBalances
	|FROM
	|	AccrualScheduleIsTT AS AccrualScheduleIsTT
	|		INNER JOIN TTPreviousConditions AS TTPreviousConditions
	|		ON (TRUE)
	|WHERE
	|	AccrualScheduleIsTT.Date >= ISNULL(TTPreviousConditions.DateOfChangeOfContract, DATETIME(1, 1, 1))
	|
	|GROUP BY
	|	AccrualScheduleIsTT.DepositPayment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTPreviousConditions.SecurityDepositAmount, 0) - ISNULL(AccrualScheduleTTBalances.DepositPayment, 0) AS DepositPayment
	|FROM
	|	TTPreviousConditions AS TTPreviousConditions
	|		FULL JOIN AccrualScheduleTTBalances AS AccrualScheduleTTBalances
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeaseServicesPaymentSchedule.Date AS Date,
	|	LeaseServicesPaymentSchedule.RentalService AS RentalService,
	|	LeaseServicesPaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	LeaseServicesPaymentSchedule.DepositPayment AS DepositPayment,
	|	LeaseServicesPaymentSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	LeaseServicesPaymentSchedule.BuyoutValue + LeaseServicesPaymentSchedule.BuyoutValuePrepayment AS BuyoutValue,
	|	LeaseServicesPaymentSchedule.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|		INNER JOIN TTPreviousConditions AS TTPreviousConditions
	|		ON LeaseServicesPaymentSchedule.EffectiveContractTerms = TTPreviousConditions.PreviousConditions
	|			AND (LeaseServicesPaymentSchedule.Date < &DateConditionsWereChanged)
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualScheduleIsTT.Date AS Date,
	|	AccrualScheduleIsTT.RentalService AS RentalService,
	|	AccrualScheduleIsTT.RentalServiceVAT AS RentalServiceVAT,
	|	AccrualScheduleIsTT.DepositPayment AS DepositPayment,
	|	AccrualScheduleIsTT.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	AccrualScheduleIsTT.BuyoutValue AS BuyoutValue,
	|	AccrualScheduleIsTT.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	AccrualScheduleIsTT AS AccrualScheduleIsTT
	|
	|ORDER BY
	|	Date";
	
	Query.SetParameter("Ref",               Object.Ref);
	Query.SetParameter("Contract",              Object.Contract);
	Query.SetParameter("DateConditionsWereChanged", DateConditionsWereChanged);
	
	OldConditions = Query.ExecuteBatch();
	
	Balance = OldConditions[OldConditions.UBound()-2].Select();
	OldPayments = OldConditions[OldConditions.UBound()-1].Select();
	OldAccruals = OldConditions[OldConditions.UBound()].Select();
	
	// The security payment is not editable,
	// so it is always replenished in accordance with the old schedules
	Balance.Next();
	Object.SecurityDepositAmount = Balance.DepositPayment;
	#EndRegion
	
	#Region ServicePaymentSchedule
	
	// If the time fence of payments is not arbitrary, then we will clear the entire schedule, 
	// otherwise we will clear only the lines of the schedule with a date less than the date of the condition change.
	If Object.PaymentFrequency <> Enums.ScheduleTimeFence.Custom
		And ValueIsFilled(Object.PaymentFrequency) Then
		Object.ServicePaymentSchedule.Clear();
	Else 
		ArrayOfPaymentLinesToDelete = New Array;
		For Each PaymentLine_ In Object.ServicePaymentSchedule Do
			If PaymentLine_.Date < DateConditionsWereChanged Then
				ArrayOfPaymentLinesToDelete.Add(PaymentLine_);
			EndIf;
		EndDo;
		TMCommonUse.DeleteTableRows(Object.ServicePaymentSchedule, ArrayOfPaymentLinesToDelete);
	EndIf;
	
	// Filling in payment lines according to the old conditions.
	While OldPayments.Next() Do
		PaymentLine_ = Object.ServicePaymentSchedule.Add();
		FillPropertyValues(PaymentLine_, OldPayments);
	EndDo;
	
	// Filling in payment lines according to the new conditions.
	If Object.PaymentFrequency <> Enums.ScheduleTimeFence.Custom
		And ValueIsFilled(Object.PaymentFrequency) Then
		
		PaymentScheduleDates = New Array;
		CurrentDate = Object.DateOfFirstPayment;
		While CurrentDate <= EndDate Do
			If CurrentDate >= DateConditionsWereChanged Then
				PaymentScheduleDates.Add(CurrentDate);
			EndIf;
			CurrentDate = LeasedAssetAccountingClientServer.NextScheduleDate(CurrentDate, Object.PaymentFrequency);
		EndDo;
		
		If ContractDetails_.ThereIsBuyoutOfLeasedAssets Then
			BalanceOfRedemptionAmount = Object.AmountOfLeaseAssetsByuout;
		EndIf;
		
		NumberOfDates = PaymentScheduleDates.Count();
		If NumberOfDates > 0 Then
			
			If ContractDetails_.ThereIsPrepaymentOfBuyoutValue Then
				AmountOfRedemptionAdvance = Round(BalanceOfRedemptionAmount / NumberOfDates, 2);
			EndIf;
			
			Counter = 1;
			For Each PaymentScheduleDate In PaymentScheduleDates Do
				
				PlotLine = Object.ServicePaymentSchedule.Add();
				PlotLine.Date = PaymentScheduleDate;
				PlotLine.RentalService = Object.PaymentForLeaseService;
				
				If ContractDetails_.ThereIsPrepaymentOfBuyoutValue And BalanceOfRedemptionAmount > 0 Then
					PlotLine.BuyoutValue = ?(Counter < NumberOfDates, AmountOfRedemptionAdvance, BalanceOfRedemptionAmount);
					BalanceOfRedemptionAmount = BalanceOfRedemptionAmount - PlotLine.BuyoutValue;
				EndIf;
				
				Counter = Counter + 1;
				
			EndDo;
			
		EndIf;
		
		If ContractDetails_.ThereIsBuyoutOfLeasedAssets
			And Object.BuyoutDate > DateConditionsWereChanged
			And BalanceOfRedemptionAmount > 0 Then
				
			GraphLines = Object.ServicePaymentSchedule.FindRows(New Structure("Date", Object.BuyoutDate));
			If GraphLines.Count() Then
				PlotLine = GraphLines[0];
			Else
				PlotLine = Object.ServicePaymentSchedule.Add();
				PlotLine.Date = Object.BuyoutDate;
			EndIf;
			PlotLine.BuyoutValue = BalanceOfRedemptionAmount;
			
		EndIf;
		
	EndIf;
	
	Object.ServicePaymentSchedule.Sort("Date");
	
	#EndRegion
	
	#Region ServiceAccrualSchedule
	
	// If the time fence of accruals is not arbitrary, then we will clear the entire schedule, 
	// otherwise we will clear only the lines of the schedule with a date less than the date of the condition change.
	
	If Object.AccrualFrequency <> Enums.ScheduleTimeFence.Custom
		And ValueIsFilled(Object.AccrualFrequency) Then
		Object.ServiceAccrualSchedule.Clear();
	Else 
		ArrayOfServiceLinesToDelete = New Array;
		For Each ServiceLine_1 In Object.ServiceAccrualSchedule Do
			If ServiceLine_1.Date < DateConditionsWereChanged Then
				ArrayOfServiceLinesToDelete.Add(ServiceLine_1);
			EndIf;
		EndDo;
		TMCommonUse.DeleteTableRows(Object.ServiceAccrualSchedule, ArrayOfServiceLinesToDelete);
	EndIf;
	
	// Filling in the accrual lines according to the old conditions.
	
	While OldAccruals.Next() Do
		AccrualLine = Object.ServiceAccrualSchedule.Add();
		FillPropertyValues(AccrualLine, OldAccruals);
	EndDo;
	
	// Filling in the accrual lines according to the new conditions.
	
	If Object.AccrualFrequency <> Enums.ScheduleTimeFence.Custom
		And ValueIsFilled(Object.AccrualFrequency) Then
		
		AccrualScheduleDates = New Array;
		CurrentDate = Object.DateOfFirstPayment;
		While CurrentDate <= EndDate Do
			If CurrentDate >= DateConditionsWereChanged Then
				AccrualScheduleDates.Add(CurrentDate);
			EndIf;
			CurrentDate = LeasedAssetAccountingClientServer.NextScheduleDate(CurrentDate, Object.AccrualFrequency);
		EndDo;
		BalanceOfSecurityPayment = Object.SecurityDepositAmount;
		
		NumberOfDates = AccrualScheduleDates.Count();
		If NumberOfDates > 0 Then
			
			If ContractDetails_.HasSecurityDeposit Then
				SecurityDepositAmount = Round(BalanceOfSecurityPayment / NumberOfDates, 2);
			EndIf;
			
			Counter = 1;
			For Each AccrualScheduleDate In AccrualScheduleDates Do
				PlotLine = Object.ServiceAccrualSchedule.Add();
				PlotLine.Date = AccrualScheduleDate;
				PlotLine.RentalService = Object.AccrualOfLeaseService;
				
				If ContractDetails_.HasSecurityDeposit And BalanceOfSecurityPayment > 0 Then
					PlotLine.DepositPayment = 
						?(Counter < NumberOfDates, SecurityDepositAmount, BalanceOfSecurityPayment);
					BalanceOfSecurityPayment = BalanceOfSecurityPayment - PlotLine.DepositPayment;
				EndIf;
				
				Counter = Counter + 1;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Object.ServiceAccrualSchedule.Sort("Date");
	
	#EndRegion
	
	FillInAmountsOfNDSInGraphs(Object.ServicePaymentSchedule, Object.ServiceAccrualSchedule, Object.VATRate, DateConditionsWereChanged);
	
	If Object.LeaseServicesAmount = 0 Then
		
		FillInCalculationsAccordingToScheduleOfPaymentsAndAccruals(Object, ContractDetails_);
		
	EndIf;
	
EndProcedure

// Fills in the "Calculations" section according to the payment and accrual schedule.
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
//  ContractDetails_ - Structure - 
Procedure FillInCalculationsAccordingToScheduleOfPaymentsAndAccruals(Object, ContractDetails_) Export
	
	If Object.ServicePaymentSchedule.Count() = 0
		And Object.ServiceAccrualSchedule.Count() = 0 Then
		Return;
	EndIf;
	
	SchedulesData = LeasedAssetAccountingClientServer.SchedulesData(Object, ContractDetails_);
	
	Object.LeaseServicesAmount = SchedulesData.ServiceAccrualSchedule.RentalServiceAfterChanges;
				
	Object.VATAmount = SchedulesData.ServiceAccrualSchedule.VATAmountAfterChanges;
	
	Object.DateOfFirstPayment = SchedulesData.ServicePaymentSchedule.DateOfFirstPayment;

	If ContractDetails_.HasSecurityDeposit Then
		
		Object.SecurityDepositAmount = SchedulesData.ServiceAccrualSchedule.SecurityPaymentAfterChanges;
		
		Object.DateOfFirstSecurityPayment = 
			?(SchedulesData.ServicePaymentSchedule.DateOfFirstSecurityPayment <> Undefined,
				SchedulesData.ServicePaymentSchedule.DateOfFirstSecurityPayment,
				'000101010000');
				
	EndIf;
	
	If ContractDetails_.ThereIsBuyoutOfLeasedAssets Then
		
		Object.AmountOfLeaseAssetsByuout = SchedulesData.ServicePaymentSchedule.RedemptionCostAfterChanges;
		Object.AmountOfVATRepurchaseOfRentalItems = SchedulesData.ServicePaymentSchedule.VATAmountOfPurchaseOfRentalItemsAfterChanges;
				
	EndIf;

	//
	Object.PaymentFrequency = 
		?(SchedulesData.ServicePaymentSchedule.Periodicity <> Undefined,
			SchedulesData.ServicePaymentSchedule.Periodicity,
			Enums.ScheduleTimeFence.Custom);
	
	Object.AccrualFrequency = 
		?(SchedulesData.ServiceAccrualSchedule.Periodicity <> Undefined,
			SchedulesData.ServiceAccrualSchedule.Periodicity,
			Enums.ScheduleTimeFence.Custom);

	//
	Object.PaymentForLeaseService = 
		?(ValueIsFilled(Object.PaymentFrequency) And Object.PaymentFrequency <> Enums.ScheduleTimeFence.Custom,
			SchedulesData.ServicePaymentSchedule.PaymentForLeaseService,
			0);
			
	Object.AccrualOfLeaseService = 
		?(ValueIsFilled(Object.AccrualFrequency) And Object.AccrualFrequency <> Enums.ScheduleTimeFence.Custom,
			SchedulesData.ServiceAccrualSchedule.AccrualOfLeaseService,
			0);
			
	LeasedAssetAccountingClientServer.RecalculateAmountOfRentalDocument(Object);
	LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(Object);
			
EndProcedure

// Fills in the VAT amounts in the charts.
// 
// Parameters:
//  ServicePaymentSchedule - DocumentTabularSection.SigningOfLeaseContract.ServicePaymentSchedule, DocumentTabularSection.LeaseTermAdjustment.ServicePaymentSchedule - Payment schedule for services.
//  ServiceAccrualSchedule - DocumentTabularSection.LeaseTermAdjustment.ServiceAccrualSchedule, DocumentTabularSection.SigningOfLeaseContract.ServiceAccrualSchedule - Service accrual schedule
//  VATRate - CatalogRef.VATRates - VAT rate.
//  StartDate - Date
//
Procedure FillInAmountsOfNDSInGraphs(ServicePaymentSchedule, ServiceAccrualSchedule, VATRate, StartDate = '00010101') Export
	
	VATPercentage = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
	
	AmountOfPayments = 0;
	AmountOfCharges = 0;
	DepositPayment = 0;
	SecurityPaymentSettlement = 0;

	For Each PlotLine In ServiceAccrualSchedule Do
		SecurityPaymentSettlement = SecurityPaymentSettlement + PlotLine.DepositPayment;
		If PlotLine.Date < StartDate Then
			Continue;
		EndIf;
		PlotLine.RentalServiceVAT = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.RentalService, VATPercentage, True);
		PlotLine.SecurityPaymentVATAmount = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.DepositPayment, VATPercentage, True);
		AmountOfCharges = AmountOfCharges + PlotLine.RentalService;
	EndDo;

	For Each PlotLine In ServicePaymentSchedule Do
		DepositPayment = DepositPayment + PlotLine.DepositPayment;
		If PlotLine.Date < StartDate Then
			Continue;
		EndIf;
		PlotLine.RentalServiceVAT = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.RentalService, VATPercentage, True);
		PlotLine.SecurityPaymentVATAmount = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.DepositPayment, VATPercentage, True);
		PlotLine.BuyoutValueVAT = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.BuyoutValue, VATPercentage, True);
		AmountOfPayments = AmountOfPayments + PlotLine.RentalService;
	EndDo;
	
	If AmountOfPayments = AmountOfCharges Then
		DistributeVATAccrualsToPayments(ServiceAccrualSchedule, ServicePaymentSchedule, "RentalService", "RentalServiceVAT", StartDate);
	EndIf;
	
	If ValueIsFilled(DepositPayment) And DepositPayment = SecurityPaymentSettlement Then
		If Not ValueIsFilled(StartDate) Then
			DistributeVATAccrualsToPayments(ServiceAccrualSchedule, ServicePaymentSchedule, "DepositPayment", "SecurityPaymentVATAmount", StartDate);
		EndIf;
	EndIf;
	
EndProcedure

// Checks whether the document is filled in correctly. 
// 
// Parameters:
// 	Object - DocumentObject.OBEntryOfLeaseSettlements, DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
// 	AuxiliaryAttributes - Structure - 
// 	NotCheckedAttributeArray - Array of String -
//  Cancel - Boolean - 
Procedure CheckLeaseDocument(Object, AuxiliaryAttributes, NotCheckedAttributeArray, Cancel) Export
	
	NotCheckedAttributeArray.Add("ServicePaymentSchedule");
	NotCheckedAttributeArray.Add("ServiceAccrualSchedule");
	
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;
	
	DocumentVersion24 = 
		TypeOf(Object) = Type("DocumentObject.SigningOfLeaseContract")
		And Object.DocumentVersion24;
			
	CreatedForTransition = (EndOfDay(Object.Date) + 1 = AuxiliaryAttributes.StartOfLeaseAccountingUnderFSB25_2018);
			
	EndDate = NonCurrentAssetsClientServer.EndDateByDeadline(
						Object.LeaseStartDate, Object.TermYears, Object.TermMonths, Object.TermDays, True);
						
	If AuxiliaryAttributes.RecordInOperationalAccounting
		And (AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			Or ContractDetails_.AssetHolder = Enums.LeasedAssetHolder.Leaseholder
				And Not DocumentVersion24) Then
		
		CheckResult = LeasedAssetAccountingClientServer.CheckComplianceOfGraphs(
			Object, 
			ContractDetails_,
			AuxiliaryAttributes.StartOfLeaseAccountingUnderFSB25_2018,
			String(ContractDetails_.ARAPCurrency));
		
		If CheckResult.SecurityDepositAmount <> Undefined 
			And Not CreatedForTransition Then
			MessageText = NStr("vi = 'Đã điền sai trường ""Số tiền thanh toán đảm bảo"":
			|%1';
			|ru = 'Неверно заполнено поле ""Сумма обеспечительного платежа"":
			|%1';
			|en = 'The ""Security deposit amount"" field is filled in incorrectly:
			|%1'; fa = 'The ""Security deposit amount"" field is filled in incorrectly:
			|%1';
			|it = 'Campo ""Importo deposito cauzionale"" compilato in maniera errata:
			|%1';
			|pl = 'Niepoprawnie wypełniono pole ""Wartość płatności zabezpieczającej"":
			|%1';
			|tr = '""Kira Güvence Ödemesi Tutarı"" alanı hatalı doldurulmuştur:
			|%1'");
			MessageText = StrTemplate(MessageText, CheckResult.SecurityDepositAmount);
			Common.MessageToUser(MessageText, Object, "SecurityDepositAmount",, Cancel);
		EndIf;
		
		If CheckResult.DateOfFirstSecurityPayment <> Undefined Then
			MessageText = NStr("vi = 'Đã điền sai trường ""Ngày thanh toán đảm bảo đầu tiên"":
			|%1';
			|ru = 'Неверно заполнено поле ""Дата первого обеспечительного платежа"":
			|%1';
			|en = 'The ""First security deposit date"" field is filled in incorrectly:
			|%1'; fa = 'The ""First security deposit date"" field is filled in incorrectly:
			|%1';
			|it = 'Campo ""Data primo deposito cauzionale"" compilato in modo errato:
			|%1';
			|pl = 'Niepoprawnie wypełniono pole ""Data pierwszej płatności zabezpieczającej"":
			|%1';
			|tr = '""İlk kira güvence ödeme tarihi"" alanı hatalı doldurulmuştur:
			|%1'");
			MessageText = StrTemplate(MessageText, CheckResult.DateOfFirstSecurityPayment);
			Common.MessageToUser(MessageText, Object, "DateOfFirstSecurityPayment",, Cancel);
		EndIf;
		
		If CheckResult.LeaseServicesAmount <> Undefined Then
			MessageText = NStr("vi = 'Đã điền sai trường ""Số tiền dịch vụ thuê"":
			|%1';
			|ru = 'Неверно заполнено поле ""Сумма услуг по аренде"":
			|%1';
			|en = 'The ""Amount of rental services"" field is filled in incorrectly:
			|%1'; fa = 'The ""Amount of rental services"" field is filled in incorrectly:
			|%1';
			|it = 'Campo ""Importo dei servizi relativi all''affitto"" non compilato correttamente:
			|%1';
			|pl = 'Nieprawidłowo jest wypełnione pole ""Wartość usług dotyczących dzierżawy"":
			|%1';
			|tr = '""Kiralama hizmetlerinin tutarı"" alanı hatalı doldurulmuştur:
			|%1'");
			MessageText = StrTemplate(MessageText, CheckResult.LeaseServicesAmount);
			Common.MessageToUser(MessageText, Object, "LeaseServicesAmount",, Cancel);
		EndIf;
		
		If CheckResult.DateOfFirstPayment <> Undefined Then
			MessageText = NStr("vi = 'Đã điền sai trường ""Ngày thanh toán đầu tiên"":
			|%1';
			|ru = 'Неверно заполнено поле ""Дата первого платежа"":
			|%1';
			|en = 'The ""First payment date"" field is filled in incorrectly:
			|%1'; fa = 'The ""First payment date"" field is filled in incorrectly:
			|%1';
			|it = 'Campo ""Data primo pagamento"" compilato in modo errato: 
			|%1';
			|pl = 'Nieprawidłowo jest wypełnione pole ""Data pierwszej płatności"":
			|%1';
			|tr = '""İlk ödeme tarihi"" alanı hatalı doldurulmuştur:
			|%1'");
			MessageText = StrTemplate(MessageText, CheckResult.DateOfFirstPayment);
			Common.MessageToUser(MessageText, Object, "DateOfFirstPayment",, Cancel);
		EndIf;
		
		If CheckResult.AmountOfLeaseAssetsByuout <> Undefined Then
			MessageText = NStr("vi = 'Đã điền sai trường ""Số tiền mua lại đối tượng thuê"":
			|%1';
			|ru = 'Неверно заполнено поле ""Сумма выкупа предметов аренды"":
			|%1';
			|en = 'The ""Amount of rental objects redemption"" field is filled in incorrectly:
			|%1'; fa = 'The ""Amount of rental objects redemption"" field is filled in incorrectly:
			|%1';
			|it = 'Campo ""Importo rimborso degli elementi di affitto"" non compilato correttamente:
			|%1';
			|pl = 'Niepoprawnie jest wypełnione pole ""Wartość wykupu przedmiotów dzierżawy"":
			|%1';
			|tr = '""Kiralanan varlıkların itfa tutarı"" alanı yanlış doldurulmuştur:
			|%1'");
			MessageText = StrTemplate(MessageText, CheckResult.AmountOfLeaseAssetsByuout);
			Common.MessageToUser(MessageText, Object, "AmountOfLeaseAssetsByuout",, Cancel);
		EndIf;
		
		If CheckResult.VATAmount <> Undefined Then
			MessageText = NStr("vi = 'Đã điền sai trường ""Số tiền thuế GTGT"":
			|%1';
			|ru = 'Неверно заполнено поле ""Сумма НДС"":
			|%1';
			|en = 'The ""VAT amount"" field is filled in incorrectly:
			|%1'; fa = 'The ""VAT amount"" field is filled in incorrectly:
			|%1';
			|it = 'Campo ""Importo IVA"" non compilato correttamente:
			|%1';
			|pl = 'Nieprawidłowo wypełnione pole ""Wartość VAT"":
			|%1';
			|tr = '""KDV tutarı"" alanı hatalı doldurulmuştur:
			|%1'");
			MessageText = StrTemplate(MessageText, CheckResult.VATAmount);
			Common.MessageToUser(MessageText, Object, "VATAmount",, Cancel);
		EndIf;
		
		If Object.LeaseStartDate = '000101010000'
			And Object.TermYears = 0
			And Object.TermYears = 0
			And Object.TermYears = 0
			And Not DocumentVersion24 Then
			
			MessageText = NStr("vi = 'Chưa chỉ ra thời hạn thuê';
								|ru = 'Не указан срок аренды';
								|en = 'Rental period is not specified'; fa = 'Rental period is not specified';
								|it = 'Periodo di affitto non indicato';
								|pl = 'Nie podano okresu dzierżawy';
								|tr = 'Kira süresi belirtilmemiştir'");
			Common.MessageToUser(MessageText,, "RentalPeriod",, Cancel);
		EndIf;
		
	EndIf;

	If Object.DateOfFirstSecurityPayment > EndDate
		And Object.DateOfFirstSecurityPayment <> '000101010000'
		And EndDate <> '000101010000' Then
			
		MessageText = NStr("vi = 'Khoản thanh toán đảm bảo không được muộn hơn so với cuối kỳ thuê';
							|ru = 'Обеспечительный платеж должен быть не позже окончания срока аренды';
							|en = 'The security deposit must be no later than the end of the rental term'; fa = 'The security deposit must be no later than the end of the rental term';
							|it = 'Il deposito cauzionale deve essere entro e non oltre la fine del periodo di noleggio';
							|pl = 'Płatność zabezpieczająca powinna być nie później zakończenia okresu dzierżawy';
							|tr = 'Teminat ödemesi en geç kira süresinin sonuna kadar yapılmalıdır'");
		Common.MessageToUser(MessageText, Object, "DateOfFirstSecurityPayment",, Cancel);
	EndIf;

	If Object.DateOfFirstPayment < Object.LeaseStartDate
		And Object.DateOfFirstPayment <> '000101010000'
		And Object.LeaseStartDate <> '000101010000' Then
			
		MessageText = NStr("vi = 'Khoản thanh toán đầu tiên không được sớm hơn ngày bắt đầu thuê (%1)';
							|ru = 'Первый платеж должен быть не раньше даты начала аренды (%1)';
							|en = 'The first payment must not be earlier than the rental start date (%1)'; fa = 'The first payment must not be earlier than the rental start date (%1)';
							|it = 'Il primo pagamento non deve essere precedente alla data di inizio dell''affitto (%1)';
							|pl = 'Pierwsza płatność powinna być nie wcześniej niż data początku dzierżawy (%1)';
							|tr = 'İlk ödeme, kiralamanın başlangıç tarihinden önce olmamalıdır (%1)'");
		MessageText = StrTemplate(MessageText, Format(Object.LeaseStartDate,"DLF=D;"));
		
		Common.MessageToUser(MessageText, Object, "DateOfFirstPayment",, Cancel);
	EndIf;

	If Object.BuyoutDate <= Object.LeaseStartDate
			And Object.BuyoutDate <> '000101010000'
			And Object.LeaseStartDate <> '000101010000'
		Or Object.BuyoutDate > EndDate
			And Object.BuyoutDate <> '000101010000'
			And EndDate <> '000101010000' Then
			
		MessageText = NStr("vi = 'Ngày mua lại phải trong thời hạn thuê';
							|ru = 'Дата выкупа должна быть в пределах срока аренды';
							|en = 'The redemption date must be within the rental period'; fa = 'The redemption date must be within the rental period';
							|it = 'La data di rimborso deve essere entro i limiti del periodo di affitto';
							|pl = 'Data wykupu powinna być w granicach terminu dzierżawy';
							|tr = 'İtfa tarihi kira süresi içinde olmalıdır'");
		Common.MessageToUser(MessageText, Object, "BuyoutDate",, Cancel);
	EndIf;

	If Object.ServicePaymentSchedule.Count() = 0 
		And Not DocumentVersion24
		And Not CreatedForTransition
		And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
		And AuxiliaryAttributes.RecordInOperationalAccounting Then
		MessageText = NStr("vi = 'Chưa điền lịch biểu thanh toán dịch vụ';
							|ru = 'Не заполнен график оплат услуг';
							|en = 'Service payment schedule is not filled in'; fa = 'Service payment schedule is not filled in';
							|it = 'Grafico del pagamento dei servizi non compilato';
							|pl = 'Nie wypełniono harmonogramu płatności usług';
							|tr = 'Hizmetler için ücret tarifesi tamamlanmamıştır'");
		Common.MessageToUser(MessageText,, "OpenPaymentSchedule",, Cancel);
	EndIf;
	
	If Object.ServiceAccrualSchedule.Count() = 0
		And Not DocumentVersion24
		And Not CreatedForTransition
		And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
		And AuxiliaryAttributes.RecordInOperationalAccounting Then
		MessageText = NStr("vi = 'Chưa điền lịch biểu tính lãi dịch vụ';
							|ru = 'Не заполнен график начисления услуг';
							|en = 'Service accrual schedule is not filled in'; fa = 'Service accrual schedule is not filled in';
							|it = 'Grafico di maturazione dei servizi non compilato';
							|pl = 'Nie wypełniono harmonogramu naliczania usług';
							|tr = 'Hizmetler için ücret tahakkuku tamamlanmamıştır'");
		Common.MessageToUser(MessageText,, "OpenTheAccrualSchedule",, Cancel);
	EndIf;
	
	If ValueIsFilled(Object.Contract)
		And Not AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed Then
		
		If ContractDetails_.ContractType = Enums.TypesOfLeaseContracts.Lease Then
			MessageText = NStr("vi = 'Chỉ cho phép sử dụng kiểu hợp đồng ""Thuê"" khi ghi nhận theo chuẩn Kế toán Việt Nam';
								|ru = 'Использование типа договора ""Аренда"" допускается только при учете по стандарту ФСБУ 25/2018';
								|en = 'Using the ""Rental"" contract type is only available when accounting is kept according to the Russian GAAP (FSBU 25/2018 standard)'; fa = 'Using the ""Rental"" contract type is only available when accounting is kept according to the Russian GAAP (FSBU 25/2018 standard)';
								|it = 'L''utilizzo del tipo di accordo ""Affitto"" è permesso solo nella contabilità ai sensi degli Standard Federali di Contabilità 25/2018';
								|pl = 'Używanie typu umowy ""Dzierżawa"" jest dopuszczalne tylko przy ewidencji wg standardu FSBU 25/2018';
								|tr = '""Kiralama"" sözleşme türünün kullanımına yalnızca FAS 25/2018 kapsamında muhasebeleştirme yapılırken izin verilir'");
			Common.MessageToUser(MessageText, Object, "Contract",, Cancel);
		EndIf;
		
	EndIf;
	
	If AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
		And ContractDetails_.MethodForDeterminingCostOfAssets = Enums.MethodsOfDeterminingLeasedAssetCost.Manually Then
		
		If Not LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object) Then
			LeaseStartDate = Object.LeaseStartDate;
			LeaseItemsCost = LeasedAssetAccountingClientServer.LeaseItemsCost(
				Object, ContractDetails_, AuxiliaryAttributes.NameOfFATablePart);
			PresentValue = LeasedAssetAccountingClientServer.PresentValue(
				LeaseItemsCost,
				Object.ServicePaymentSchedule,
				Object.LeaseStartDate);
		Else
			LeaseStartDate = BegOfDay(Object.Date);
			DistributionCoefficient =
				LeasedAssetAccountingClientServer.CostSharingRatio(Object.FA, ContractDetails_);
			
			PreviousConditions = CostAccordingToPreviousConditions(Object);
			
			CostOfAddedRentalItems =
				LeasedAssetAccountingClientServer.CostOfAddedRentalItems(Object.FA);
			
			PresentValue = 
				PreviousConditions.PresentValue
				* DistributionCoefficient
				+ CostOfAddedRentalItems;
		EndIf;
		
		TotalPaymentsExcludingVAT = LeasedAssetAccountingClientServer.TotalPaymentsExcludingVAT(
									Object.ServicePaymentSchedule, LeaseStartDate, Object.VATRate);
		
		If PresentValue > TotalPaymentsExcludingVAT And TotalPaymentsExcludingVAT > 0 Then
			If ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing") 
				And Not LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object) Then
				MessageText = NStr("vi = 'Số tiền đầu tư của bên cho thuê (%1) cần nhỏ hơn số tiền thanh toán không thuế GTGT (%2)';
									|ru = 'Сумма вложений лизингодателя (%1) должна быть меньше суммы платежей без НДС (%2)';
									|en = 'The amount of the lessor''s investments (%1) must be less than the amount of payments excluding VAT (%2)'; fa = 'The amount of the lessor''s investments (%1) must be less than the amount of payments excluding VAT (%2)';
									|it = 'Сумма вложений лизингодателя (%1) должна быть меньше суммы платежей без НДС (%2)';
									|pl = 'The amount of the lessor''s investments (%1) must be less than the amount of payments excluding VAT (%2)';
									|tr = 'Kiraya verenin yatırım tutarı (%1), KDV hariç ödeme tutarından az olmalıdır (%2)'");
			Else
				MessageText = NStr("vi = 'Giá trị đối tượng thuê (%1) phải nhỏ hơn số tiền thanh toán không gồm thuế GTGT (%2)';
									|ru = 'Стоимость предметов аренды (%1) должна быть меньше суммы платежей без НДС (%2)';
									|en = 'The cost of rental objects (%1) must be less than the amount of payments excluding VAT (%2)'; fa = 'The cost of rental objects (%1) must be less than the amount of payments excluding VAT (%2)';
									|it = 'Стоимость предметов аренды (%1) должна быть меньше суммы платежей без НДС (%2)';
									|pl = 'The cost of rental objects (%1) must be less than the amount of payments excluding VAT (%2)';
									|tr = 'Kiralanan nesnenin tutarı (%1), KDV hariç ödeme tutarından az olmalıdır (%2)'");
			EndIf;
			
			MessageText = StrTemplate(MessageText, Format(PresentValue, "NFD=2"), Format(TotalPaymentsExcludingVAT, "NFD=2"));
			
			Common.MessageToUser(MessageText,, "InterestRate",, Cancel);
		EndIf;
		
	EndIf;
	
	CheckSchedule(
		Object.ServicePaymentSchedule, 
		"ServicePaymentSchedule", 
		"RentalService,DepositPayment,BuyoutValue",
		Cancel);
		
	CheckSchedule(
		Object.ServiceAccrualSchedule, 
		"ServiceAccrualSchedule", 
		"RentalService,DepositPayment,BuyoutValue",
		Cancel);

	CheckSchedule(
		Object.InterestAccrualSchedule, 
		"InterestAccrualSchedule", 
		"Interests",
		Cancel);
	
EndProcedure

// Returns the interest rate for the payment schedule.
// 
// Parameters:
// 	ScheduleOfPayments - ValueTable of ValueTableRow - contains columns:
// 	    * Date - Date - 
// 	    * Sum - Number -
// 	 
// Returns:
// 	Number - the rate of return.
Function InterestRate(ScheduleOfPayments)
	
	Payments_2 = New Array;
	PaymentDates_ = New Array;
	
	For Each PlotLine In ScheduleOfPayments Do
		
		// For arbitrary graphs, we take lines with nonzero sums.
		If PlotLine.Sum <> 0 Then
			Payments_2.Add(PlotLine.Sum);
			PaymentDates_.Add(PlotLine.Date);
		EndIf;
		
	EndDo;
	
	Rate1 = FinancialInstruments.IRR(Payments_2, PaymentDates_);
	
	If Rate1 = Undefined 
		Or Rate1 > 999999999
		Or Rate1 < 0 Then
		Raise(NStr("vi = 'Lỗi tính toán lãi suất';
					|ru = 'Ошибка расчета процентной ставки';
					|en = 'Interest rate calculation error'; fa = 'Interest rate calculation error';
					|it = 'Ошибка расчета процентной ставки';
					|pl = 'Interest rate calculation error';
					|tr = 'Faiz oranının hesaplama hatası'"));
	EndIf;

	Return Rate1 * 100;
	
EndFunction

// Returns the present value.
// 
// Parameters:
// 	Rate1 - Number - discount rate.
// 	ScheduleOfPayments - ValueTable of ValueTableRow - contains columns:
// 	    * Date - Date - 
// 	    * Sum - Number -
// 	    
// Returns:
// 	Number - The present value.
Function PresentValueByRateAndSchedule(Rate1, ScheduleOfPayments) Export
	
	Payments_2 = New Array;
	PaymentDates_ = New Array;
	
	For Each PlotLine In ScheduleOfPayments Do
		Payments_2.Add(PlotLine.Sum);		
		PaymentDates_.Add(PlotLine.Date);		
	EndDo;

	PresentValue = FinancialInstruments.Thorns(Rate1 / 100, Payments_2, PaymentDates_);
	
	Return PresentValue;
	
EndFunction

// Distributes the difference in VAT between accruals and payments.
Procedure DistributeVATAccrualsToPayments(ServiceAccrualSchedule, ServicePaymentSchedule, NameOfAmountField, NameOfVATAmountField_, StartDate = '00010101')
	
	Coefficients = New Array;
	GraphLines = New Array;
	VATAccruals = 0;
	PaymentOfVAT = 0;
	VATAccrualsBalance = 0;
	PaymentOfVATBalance = 0;
		
	For Each PlotLine In ServiceAccrualSchedule Do
		If PlotLine.Date < StartDate And NameOfVATAmountField_ <> "SecurityPaymentVATAmount" Then
			If NameOfVATAmountField_ = "RentalServiceVAT" Then
				VATAccrualsBalance = VATAccrualsBalance + PlotLine[NameOfVATAmountField_];
			EndIf;
			Continue;
		EndIf;
		VATAccruals = VATAccruals + PlotLine[NameOfVATAmountField_];
	EndDo;

	For Each PlotLine In ServicePaymentSchedule Do
		If PlotLine.Date < StartDate And NameOfVATAmountField_ <> "SecurityPaymentVATAmount" Then
			If NameOfVATAmountField_ = "RentalServiceVAT" Then
				PaymentOfVATBalance = PaymentOfVATBalance + PlotLine[NameOfVATAmountField_];
			EndIf;
			Continue;
		EndIf;
		If PlotLine[NameOfAmountField] <> 0 Then
			If PlotLine.Date >= StartDate Then
				GraphLines.Add(PlotLine);
				Coefficients.Add(PlotLine[NameOfAmountField])	
			EndIf;
			PaymentOfVAT = PaymentOfVAT + PlotLine[NameOfVATAmountField_];
		EndIf;
	EndDo;
	
	PaymentOfVAT = PaymentOfVAT + PaymentOfVATBalance - VATAccrualsBalance;
	
	If (VATAccruals - PaymentOfVAT) <> 0 Then
		
		VATAllocation = Common.DistributeAmountInProportionToCoefficients(
							VATAccruals - PaymentOfVAT, Coefficients);
							
		For IndexOf = 0 To GraphLines.UBound() Do
			PlotLine = GraphLines[IndexOf];
			PlotLine[NameOfVATAmountField_] = PlotLine[NameOfVATAmountField_] + VATAllocation[IndexOf];
		EndDo;
		
	EndIf;
	
EndProcedure

// Checks the schedule.
// 
// Parameters:
//  ChartTable - TabularSection, FormDataCollection- Graph data.
//  ChartName - String - table name.
//  FieldsToCheck - String - Fields to be checked.
//  Cancel - Boolean - True if there are errors.
//
Procedure CheckSchedule(ChartTable, ChartName, FieldsToCheck, Cancel) Export
	
	If ChartTable.Count() = 0 Then
		Return;
	EndIf;
	
	If Upper(ChartName) = Upper("ServicePaymentSchedule") Then
		
		MessageTemplateAmount = NStr("vi = 'Trong lịch biểu thanh toán, cần chỉ ra số tiền vào ngày %1';
									|ru = 'В графике оплат необходимо указать сумму на дату %1';
									|en = 'Specify the amount as of %1 in the payment schedule'; fa = 'Specify the amount as of %1 in the payment schedule';
									|it = 'Nel piano di pagamenti bisogna indicare l''importo per la data %1';
									|pl = 'W harmonogramie płatności należy podać wartość na datę %1';
									|tr = 'Ödeme planında, tutarı%1 tarihte belirtmeniz gerekir'"); 
		MessageTemplateDate = NStr("vi = 'Trong lịch biểu thanh toán bị lặp ngày %1, cần chỉ ra các ngày khác nhau';
									|ru = 'В графике оплат повторяется дата %1, необходимо указывать разные даты';
									|en = 'In the payment schedule, the date %1 is repeated, specify different dates'; fa = 'In the payment schedule, the date %1 is repeated, specify different dates';
									|it = 'Nel grafico dei pagamenti è ripetuta la data %1, è necessario indicare altre date';
									|pl = 'W harmonogramie płatności powtarza się data %1, należy podawać różne daty';
									|tr = 'Tarih %1ödeme planında tekrarlanır, farklı tarihler belirtmek gerekir'");
		 
		CheckAmount = True;
		
	ElsIf Upper(ChartName) = Upper("ServiceAccrualSchedule") Then
		
		MessageTemplateAmount = NStr("vi = 'Trong lịch biểu tính toán, cần chỉ ra số tiền tại ngày %1';
									|ru = 'В графике начислений необходимо указать сумму на дату %1';
									|en = 'Specify the amount as of %1 in the accrual schedule'; fa = 'Specify the amount as of %1 in the accrual schedule';
									|it = 'Nel grafico delle maturazioni è necessario indicare l''importo in data %1';
									|pl = 'W harmonogramie naliczeń należy podać wartość na datę %1';
									|tr = 'Tahakkuk çizelgesinde, tutarı %1tarihte belirtmeniz gerekir'");
		MessageTemplateDate = NStr("vi = 'Trong lịch biểu tính toán bị lặp ngày %1, cần chỉ ra các ngày khác nhau';
									|ru = 'В графике начислений повторяется дата %1, необходимо указывать разные даты';
									|en = 'In the accrual schedule, the date %1 is repeated, specify different dates'; fa = 'In the accrual schedule, the date %1 is repeated, specify different dates';
									|it = 'Nel grafico di enumerazione è ripetuta la data %1, è necessario indicare altre date';
									|pl = 'W harmonogramie naliczeń powtarza się data %1, należy podawać różne daty';
									|tr = 'Tahakkuk çizelgesinde,%1 tarih tekrarlanır, farklı tarihler belirtmek gerekir'"); 
	
		CheckAmount = True;
	
	Else 
		
		MessageTemplateAmount = NStr("vi = 'Trong lịch biểu tính lãi, cần chỉ ra số tiền tại ngày %1';
									|ru = 'В графике процентов необходимо указать сумму на дату %1';
									|en = 'Specify the amount as of %1 in the interest schedule'; fa = 'Specify the amount as of %1 in the interest schedule';
									|it = 'Nel grafico degli interessi è necessario indicare l''importo in data %1';
									|pl = 'W harmonogramie odsetek należy podać wartość na datę %1';
									|tr = 'Faiz planında, tutarı %1tarihte belirtmeniz gerekir'");
		MessageTemplateDate = NStr("vi = 'Trong lịch biểu tính lãi bị lặp ngày %1, cần chỉ ra các ngày khác nhau';
									|ru = 'В графике процентов повторяется дата %1, необходимо указывать разные даты';
									|en = 'In the interest schedule, the date %1 is repeated, specify different dates'; fa = 'In the interest schedule, the date %1 is repeated, specify different dates';
									|it = 'Nel grafico degli interessi è ripetuta la data %1, è necessario indicare altre date';
									|pl = 'W harmonogramie odsetek powtarza się data %1, należy podawać różne daty';
									|tr = 'Faiz grafiğinde, %1tarihi tekrarlanır, farklı tarihler belirtmek gerekir'");
		
		CheckAmount = False;
		 
	EndIf;
	
	FieldList = StrSplit(FieldsToCheck, ",");
	
	ExistingDates = New Map();
	
	LineNumber = 0;
	For Each RowData In ChartTable Do
		
		LineNumber = LineNumber + 1;
		
		If CheckAmount Then
			
			AmountSpecified = False;
			For Each FieldName In FieldList Do
				If ValueIsFilled(RowData[FieldName]) Then
					AmountSpecified = True;
					Break;
				EndIf;
			EndDo;
			
			If Not AmountSpecified Then
				MessageText = StrTemplate(MessageTemplateAmount, Format(RowData.Date, "DLF=D;"));
				Field = CommonClientServer.PathToTabularSection(ChartName, LineNumber, "Date");
				Common.MessageToUser(MessageText,, Field,, Cancel);
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(RowData.Date) Then
			
			If ExistingDates.Get(RowData.Date) <> Undefined Then
				MessageText = StrTemplate(MessageTemplateDate, Format(RowData.Date, "DLF=D;"));
				Field = CommonClientServer.PathToTabularSection(ChartName, LineNumber, "Date");
				Common.MessageToUser(MessageText,, Field,, Cancel);
			EndIf;
			
			ExistingDates.Insert(RowData.Date, True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Receives the details of the lease agreement.
// 
// Parameters:
//  Contract - CatalogRef.LeaseContract - Contract
// 
// Returns:
//  Structure - Details of the lease agreement:
//  * ContractType - EnumRef.TypesOfLeaseContracts
//  * AssetHolder - EnumRef.LeasedAssetHolder
//  * ValidityStartDate - Date
//  * ARAPCurrency - CatalogRef.Currencies
//  * MethodForDeterminingCostOfAssets - EnumRef.MethodsOfDeterminingLeasedAssetCost
//  * HasSecurityDeposit - Boolean
//  * ThereIsBuyoutOfLeasedAssets - Boolean
//  * ThereIsPrepaymentOfBuyoutValue - Boolean
//  * RecognizeLeasedItemsInLocalAccounting - Boolean
//  * RecognizeLeasedAssetsInManagementAccounting - Boolean
//  * VATTaxation - EnumRef.VATTaxationTypes
//  * RegisterImportApplications - Boolean
//  * KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments - Boolean
//
Function DetailsOfLeaseAgreement(Contract) Export
	
	AttributesList = "ContractType,AssetHolder,ValidityStartDate,
	|ARAPCurrency,MethodForDeterminingCostOfAssets,
	|HasSecurityDeposit,ThereIsBuyoutOfLeasedAssets,ThereIsPrepaymentOfBuyoutValue,
	|RecognizeLeasedItemsInLocalAccounting,RecognizeLeasedAssetsInManagementAccounting,
	|VATTaxation,RegisterImportApplications,KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments";
	
	ContractDetails_ = New Structure(AttributesList);
	ContractDetails_.ValidityStartDate = '000101010000';
	ContractDetails_.HasSecurityDeposit = False;
	ContractDetails_.ThereIsBuyoutOfLeasedAssets = False;
	ContractDetails_.ThereIsPrepaymentOfBuyoutValue = False;
	ContractDetails_.RecognizeLeasedItemsInLocalAccounting = False;
	ContractDetails_.RecognizeLeasedAssetsInManagementAccounting = False;
	
	If ValueIsFilled(Contract) Then
		ContractDetails_ = Common.ObjectAttributesValues(Contract, AttributesList);
	EndIf;
	
	Return ContractDetails_;
	
EndFunction

// Receives the Attributes of the counterparty's Contract.
// 
// Parameters:
//  Contract - CatalogRef.CounterpartyContracts - Contract
// 
// Returns:
//  Structure - Attributes of the Counterparty's Contract:
// * ContractType - EnumRef.ContractTypes
// * ARAPCurrency - CatalogRef.Currencies
// * VATRate - CatalogRef.VATRates
// * LeaseContracts - CatalogRef.LeaseContract
//
Function AttributesOfCounterpartySContract(Contract) Export
	
	AttributesList = "ContractType, ARAPCurrency, VATRate, LeaseContracts";
	
	ContractDetails_ = New Structure(AttributesList);
	ContractDetails_.ContractType = Enums.ContractTypes.EmptyRef();
	ContractDetails_.ARAPCurrency = Catalogs.Currencies.EmptyRef();
	ContractDetails_.VATRate = Catalogs.VATRates.EmptyRef();
	ContractDetails_.LeaseContracts = Catalogs.LeaseContract.EmptyRef();
	
	If ValueIsFilled(Contract) And TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts") Then
		ContractDetails_ = Common.ObjectAttributesValues(Contract, AttributesList);
	EndIf;
	
	Return ContractDetails_;
	
EndFunction

// Gets parameters for forming a representation of Attributes in the table part of the FA
// 
// Parameters:
//  Object - FormDataStructure -
//  FormParameters - Structure - 
//  CreatedForTransition - Boolean - 
// 
// Returns:
//  Structure:
// * AssetHolder - EnumRef.LeasedAssetHolder - 
// * ContractType - EnumRef.TypesOfLeaseContracts - 
// * MethodForDeterminingCostOfAssets - EnumRef.MethodsOfDeterminingLeasedAssetCost - 
// * LeaseAccountingAccordingToFSB25_2018IsUsed - Boolean -
// * CreatedForTransition - Boolean -
// * DocumentCurrencyPresentation - String -
// * ComplCurrencyPresentation - String -
// * ChangingConditions - Boolean -
// * ThereIsBuyoutOfLeasedAssets - Boolean -
//
Function ParametersPresentationOfAttributesOfFA(Object, FormParameters, CreatedForTransition = False) Export
	
	ContractDetails_ = FormParameters.ContractDetails_;
	
	DocumentParameters = New Structure;
	DocumentParameters.Insert("AssetHolder", ContractDetails_.AssetHolder);
	DocumentParameters.Insert("ContractType", ContractDetails_.ContractType);
	DocumentParameters.Insert("MethodForDeterminingCostOfAssets", ContractDetails_.MethodForDeterminingCostOfAssets);
	DocumentParameters.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", FormParameters.LeaseAccountingAccordingToFSB25_2018IsUsed);
	DocumentParameters.Insert("CreatedForTransition", CreatedForTransition);
	DocumentParameters.Insert("DocumentCurrencyPresentation", String(Object.Currency));
	DocumentParameters.Insert("ComplCurrencyPresentation", FormParameters.ComplCurrencyPresentation);
	DocumentParameters.Insert("ChangingConditions", LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object));
	DocumentParameters.Insert("ThereIsBuyoutOfLeasedAssets", ContractDetails_.ThereIsBuyoutOfLeasedAssets);
	
	Return DocumentParameters;
	
EndFunction

// Gets parameters for forming a representation of Attributes in the table part of the FA
// 
// Parameters:
//  DocumentParameters - See ParametersPresentationOfAttributesOfFA
// 
// Returns:
//  Map of String
Function PresentationOfFAAttributes(DocumentParameters) Export
	
	PresentationOfDetails = New Map;
	
	FAGroupCost_Header = NStr("vi = 'Giá trị';
								|ru = 'Стоимость';
								|en = 'Cost'; fa = 'بهای تمام‌شده';
								|it = 'Стоимость';
								|pl = 'Cost';
								|tr = 'Maliyet'");

	If DocumentParameters.LeaseAccountingAccordingToFSB25_2018IsUsed Or DocumentParameters.CreatedForTransition Then
		
		If DocumentParameters.ContractType = Enums.TypesOfLeaseContracts.Leasing 
			And Not DocumentParameters.MethodForDeterminingCostOfAssets = Enums.MethodsOfDeterminingLeasedAssetCost.ByContractAmount Then

			CostOfFA_Header = NStr("vi = 'Số tiền đầu tư của bên cho thuê (không gồm thuế GTGT)';
									|ru = 'Сумма вложений лизингодателя (без НДС)';
									|en = 'Amount of lessor''s investments (excluding VAT)'; fa = 'Amount of lessor''s investments (excluding VAT)';
									|it = 'Importo investimenti del locatore (senza IVA)';
									|pl = 'Wartość inwestycji leasingodawcy (bez VAT)';
									|tr = 'Kiralayanın yatırım tutarı (KDV hariç)'");
			CostOfFAIs_Hint = "";
			
			If Not (DocumentParameters.ChangingConditions And DocumentParameters.ThereIsBuyoutOfLeasedAssets) Then
				CostOfFA_Header = NonCurrentAssetsClientServer.AddCurrencyToLine(
					CostOfFA_Header, 
					DocumentParameters.DocumentCurrencyPresentation);
			Else
				FAGroupCost_Header = NonCurrentAssetsClientServer.AddCurrencyToLine(
					FAGroupCost_Header,
					DocumentParameters.DocumentCurrencyPresentation);
			EndIf;

		Else
				
			FAGroupCost_Header = NonCurrentAssetsClientServer.AddCurrencyToLine(
				FAGroupCost_Header, DocumentParameters.DocumentCurrencyPresentation);

			CostOfFA_Header = NStr("vi = 'Giá trị (không gồm thuế GTGT)';
									|ru = 'Стоимость (без НДС)';
									|en = 'Cost (excluding VAT)'; fa = 'بها (بدون مالیات بر ارزش افزوده)';
									|it = 'Costo (Senza IVA)';
									|pl = 'Wartość bez (VAT)';
									|tr = 'Maliyet (KDV hariç)'");
			
			If DocumentParameters.MethodForDeterminingCostOfAssets = Enums.MethodsOfDeterminingLeasedAssetCost.Manually Then
				CostOfFAIs_Hint = NStr("vi = 'Giá trị đối tượng thuê được tính trên cơ sở giá trị hợp lý và không đảm bảo';
										|ru = 'Стоимость предметов аренды, которая рассчитывается на основании справедливой и негарантированной стоимости';
										|en = 'Rental object cost calculated based on the fair and non-guaranteed value'; fa = 'Rental object cost calculated based on the fair and non-guaranteed value';
										|it = 'Costo degli elementi di affitto calcolato in base al valore equo e del valore non garantito';
										|pl = 'Wartość przedmiotów dzierżawy, która jest obliczana na podstawie sprawiedliwej i niegwarantowanej wartości';
										|tr = 'Adil ve garanti edilmeyen değer temelinde hesaplanan kiralık kalemlerin değeri'");
			Else
				CostOfFAIs_Hint = NStr("vi = 'Giá trị đối tượng thuê được phân bổ theo giá trị danh nghĩa';
										|ru = 'Стоимость предметов аренды, распределенная в соответствии с номинальной стоимостью';
										|en = 'Rental object cost allocated according to par value'; fa = 'Rental object cost allocated according to par value';
										|it = 'Стоимость предметов аренды, распределенная в соответствии с номинальной стоимостью';
										|pl = 'Rental object cost allocated according to par value';
										|tr = 'Nominal değere göre dağıtılan kiralanan varlıkların değeri'");
			EndIf;

		EndIf;

	Else

		If DocumentParameters.AssetHolder = Enums.LeasedAssetHolder.Lessor Then

			CostOfFA_Header = NStr("vi = 'Giá trị thế chấp';
									|ru = 'Залоговая стоимость';
									|en = 'Collateral value'; fa = 'ارزش وثیقه';
									|it = 'Costo di cauzione';
									|pl = 'Wartość kaucyjna';
									|tr = 'Teminat değeri'");
			CostOfFAIs_Hint = NStr("vi = 'Giá trị ban đầu của đối tượng thuê';
									|ru = 'Залоговая стоимость предмета аренды';
									|en = 'Collateral value of rental object'; fa = 'Collateral value of rental object';
									|it = 'Valore di garanzia dell''oggetto di affitto';
									|pl = 'Wartość kaucyjna przedmiotu dzierżawy';
									|tr = 'Kiralanan varlık teminat değeri'");
			
			CostOfFA_Header = NonCurrentAssetsClientServer.AddCurrencyToLine(
				CostOfFA_Header,
				DocumentParameters.ComplCurrencyPresentation);

		Else

			CostOfFA_Header = NStr("vi = 'Số tiền đầu tư của bên cho thuê (không gồm thuế GTGT)';
									|ru = 'Сумма вложений лизингодателя (без НДС)';
									|en = 'Amount of lessor''s investments (excluding VAT)'; fa = 'Amount of lessor''s investments (excluding VAT)';
									|it = 'Importo investimenti del locatore (senza IVA)';
									|pl = 'Wartość inwestycji leasingodawcy (bez VAT)';
									|tr = 'Kiralayanın yatırım tutarı (KDV hariç)'");
			CostOfFAIs_Hint = NStr("vi = 'Giá trị đối tượng thuê theo tiền tệ hợp đồng';
									|ru = 'Стоимость предметов аренды в валюте договора';
									|en = 'Rental object cost in contract currency'; fa = 'Rental object cost in contract currency';
									|it = 'Стоимость предметов аренды в валюте договора';
									|pl = 'Rental object cost in contract currency';
									|tr = 'Sözleşme para birimi cinsinden kiralanan varlıkların bedeli'");
			
			CostOfFA_Header = NonCurrentAssetsClientServer.AddCurrencyToLine(
				CostOfFA_Header,
				DocumentParameters.DocumentCurrencyPresentation);

		EndIf;

	EndIf;
	
	If DocumentParameters.ContractType = Enums.TypesOfLeaseContracts.Lease
		And DocumentParameters.MethodForDeterminingCostOfAssets = Enums.MethodsOfDeterminingLeasedAssetCost.Discounting
		Or DocumentParameters.MethodForDeterminingCostOfAssets = Enums.MethodsOfDeterminingLeasedAssetCost.ByContractAmount Then
		
		FAFairCost_Title = NStr("vi = 'Giá trị danh nghĩa';
								|ru = 'Номинальная стоимость';
								|en = 'Par value'; fa = 'ارزش اسمی';
								|it = 'Costo nominale';
								|pl = 'Wartość nominalna';
								|tr = 'Nominal değer'");
		FairCostFA_Hint = NStr("vi = 'Giá trị được tính toán cho phép tách chi phí của các đối tượng quyền sử dụng tài sản riêng khỏi tổng số tiền thanh toán tiền thuê trong tương lai theo hợp đồng thuê';
								|ru = 'Расчетная величина, позволяющая выделить стоимость отдельных объектов ППА из общей величины будущих арендных платежей по договору аренды';
								|en = 'The estimate value singles out the amount of separate lease right objects from the total value of the future rental payments under the rental contract'; fa = 'The estimate value singles out the amount of separate lease right objects from the total value of the future rental payments under the rental contract';
								|it = 'Расчетная величина, позволяющая выделить стоимость отдельных объектов ППА из общей величины будущих арендных платежей по договору аренды';
								|pl = 'The estimate value singles out the amount of separate lease right objects from the total value of the future rental payments under the rental contract';
								|tr = 'Kesintiye uğrayan mülk nesnelerinin maliyetini, kira sözleşmesi kapsamında gelecekte yapılacak kira ödemelerinin toplam tutarından ayırmanıza olanak tanıyan tahmini değer'");
		
	Else
		
		FAFairCost_Title = NStr("vi = 'Giá trị hợp lý';
								|ru = 'Справедливая стоимость';
								|en = 'Fair value'; fa = 'ارزش منصفانه';
								|it = 'Справедливая стоимость';
								|pl = 'Fair value';
								|tr = 'Adil değer'");
		FairCostFA_Hint = NStr("vi = 'Số tiền để có thể trao đổi tài sản hoặc thanh toán khoản nợ trong một giao dịch giữa các bên độc lập có hiểu biết mong muốn thực hiện giao dịch đó.';
								|ru = 'Сумма, на которую можно обменять актив или погасить обязательство в сделке между хорошо осведомленными независимыми сторонами, желающими совершить такую сделку';
								|en = 'The amount at which an asset can be exchanged or a liability settled in a transaction between knowledgeable independent parties willing to enter such transaction'; fa = 'The amount at which an asset can be exchanged or a liability settled in a transaction between knowledgeable independent parties willing to enter such transaction';
								|it = 'Сумма, на которую можно обменять актив или погасить обязательство в сделке между хорошо осведомленными независимыми сторонами, желающими совершить такую сделку';
								|pl = 'The amount at which an asset can be exchanged or a liability settled in a transaction between knowledgeable independent parties willing to enter such transaction';
								|tr = 'Böyle bir işleme girmeye istekli, bilgili ve bağımsız taraflar arasındaki bir işlemde bir varlığın takas edilebileceği veya bir yükümlülüğün ödenebileceği tutar'");
		
	EndIf;
	
	PresentationOfDetails.Insert("FA.CostGroup_Title", FAGroupCost_Header);
	PresentationOfDetails.Insert("FA.Cost_Header", CostOfFA_Header);
	PresentationOfDetails.Insert("FA.Cost_Hint", CostOfFAIs_Hint);
	PresentationOfDetails.Insert("FA.FairCost_Title", FAFairCost_Title);
	PresentationOfDetails.Insert("FA.FairCost_Hint", FairCostFA_Hint);

	Return PresentationOfDetails;

EndFunction

// The present value under the previous terms of the lease Contract.
// 
// Parameters:
//  Object - DocumentObject.LeaseTermAdjustment -
//  GeneratePercentageGraph - Boolean -
// 
// Returns:
//  FixedStructure -  Cost According To Previous Conditions:
// * PresentValue - Number - 
// * ChangeDate - Date - 
// * TermsOfAgreement_ - Undefined, DocumentRef.SigningOfLeaseContract, DocumentRef.LeaseTermAdjustment - 
// * InterestGraph - Undefined, ValueTable - contains columns: 
//	 ** Date - Date -
//	 ** Interests - Number -
Function CostAccordingToPreviousConditions(Object, GeneratePercentageGraph = False) Export
	
	PreviousConditions = New Structure;
	PreviousConditions.Insert("PresentValue", 0);
	PreviousConditions.Insert("ChangeDate", '00010101');
	PreviousConditions.Insert("TermsOfAgreement_", Undefined);
	PreviousConditions.Insert("InterestGraph", Undefined);
	
	If Not ValueIsFilled(Object.Contract) Or Not ValueIsFilled(Object.PreviousContractTerms) Then
		Return New FixedStructure(PreviousConditions);
	EndIf;
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.LeaseStartDate AS LeaseStartDate,
	|	TermsOfLeaseContracts.InterestRate AS InterestRate,
	|	TermsOfLeaseContracts.Period AS Period
	|INTO TTPreviousConditions
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&Date,
	|			Recorder <> &Ref) AS TermsOfLeaseContracts
	|WHERE
	|	Contract IN (&AssociatedContracts)
	|	AND State = VALUE(Enum.CounterpartyContractStates.Valid)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPreviousConditions.EffectiveContractTerms AS EffectiveContractTerms,
	|	SUM(LeaseServicesPaymentSchedule.RentalService
	|		- LeaseServicesPaymentSchedule.RentalServiceVAT
	|		+ LeaseServicesPaymentSchedule.DepositPayment
	|		- LeaseServicesPaymentSchedule.SecurityPaymentVATAmount
	|		+ LeaseServicesPaymentSchedule.BuyoutValue
	|		+ LeaseServicesPaymentSchedule.BuyoutValuePrepayment
	|		- LeaseServicesPaymentSchedule.BuyoutValueVAT) AS Sum
	|INTO PaymentBalancesTT
	|FROM
	|	TTPreviousConditions AS TTPreviousConditions
	|		INNER JOIN InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|		ON TTPreviousConditions.EffectiveContractTerms = LeaseServicesPaymentSchedule.EffectiveContractTerms
	|			AND (LeaseServicesPaymentSchedule.Date >= &Date)
	|
	|GROUP BY
	|	TTPreviousConditions.EffectiveContractTerms
	|
	|INDEX BY
	|	EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPreviousConditions.EffectiveContractTerms AS EffectiveContractTerms,
	|	LeaseInterestAccrualSchedule.Date AS Date,
	|	LeaseInterestAccrualSchedule.Interests AS Interests
	|INTO TTPreviousInterestChart
	|FROM
	|	InformationRegister.LeaseInterestAccrualSchedule AS LeaseInterestAccrualSchedule
	|		INNER JOIN TTPreviousConditions AS TTPreviousConditions
	|		ON LeaseInterestAccrualSchedule.EffectiveContractTerms = TTPreviousConditions.EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPreviousInterestChart.EffectiveContractTerms AS EffectiveContractTerms,
	|	SUM(TTPreviousInterestChart.Interests) AS Interests
	|INTO TTInterestBalances
	|FROM
	|	TTPreviousInterestChart AS TTPreviousInterestChart
	|WHERE
	|	TTPreviousInterestChart.Date >= &Date
	|
	|GROUP BY
	|	TTPreviousInterestChart.EffectiveContractTerms
	|
	|INDEX BY
	|	EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPreviousInterestChart.EffectiveContractTerms AS EffectiveContractTerms,
	|	MAX(TTPreviousInterestChart.Date) AS Date
	|INTO TTPreviousAccrualOfInterest
	|FROM
	|	TTPreviousInterestChart AS TTPreviousInterestChart
	|WHERE
	|	TTPreviousInterestChart.Date < &Date
	|
	|GROUP BY
	|	TTPreviousInterestChart.EffectiveContractTerms
	|
	|INDEX BY
	|	EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPreviousConditions.EffectiveContractTerms AS TermsOfAgreement_,
	|	ISNULL(PaymentBalancesTT.Sum, 0) - ISNULL(TTInterestBalances.Interests, 0) AS PresentValue,
	|	CASE
	|		WHEN TTPreviousConditions.EffectiveContractTerms REFS Document.LeaseTermAdjustment
	|				OR TTPreviousConditions.EffectiveContractTerms REFS Document.RegisterAdjustment
	|			THEN BEGINOFPERIOD(TTPreviousConditions.Period, DAY)
	|		ELSE TTPreviousConditions.LeaseStartDate
	|	END AS ChangeDate,
	|	ISNULL(TTPreviousAccrualOfInterest.Date, TTPreviousConditions.LeaseStartDate) AS DateOfPreviousAccrual,
	|	TTPreviousConditions.InterestRate AS InterestRate
	|FROM
	|	TTPreviousConditions AS TTPreviousConditions
	|		LEFT JOIN PaymentBalancesTT AS PaymentBalancesTT
	|		ON TTPreviousConditions.EffectiveContractTerms = PaymentBalancesTT.EffectiveContractTerms
	|		LEFT JOIN TTInterestBalances AS TTInterestBalances
	|		ON TTPreviousConditions.EffectiveContractTerms = TTInterestBalances.EffectiveContractTerms
	|		LEFT JOIN TTPreviousAccrualOfInterest AS TTPreviousAccrualOfInterest
	|		ON TTPreviousConditions.EffectiveContractTerms = TTPreviousAccrualOfInterest.EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTPreviousInterestChart.Date, TTPreviousConditions.LeaseStartDate) AS Date,
	|	ISNULL(TTPreviousInterestChart.Interests, 0) AS Interests
	|FROM
	|	TTPreviousConditions AS TTPreviousConditions
	|		LEFT JOIN TTPreviousInterestChart AS TTPreviousInterestChart
	|		ON TTPreviousConditions.EffectiveContractTerms = TTPreviousInterestChart.EffectiveContractTerms
	|			AND (TTPreviousInterestChart.Date < &Date)";
	
	Query.SetParameter("Date", BegOfDay(Object.Date));
	Query.SetParameter("AssociatedContracts", LeasedAssetAccounting.RelatedLeaseContracts(Object.Contract));
	Query.SetParameter("Ref", Object.Ref);
	
	QueryResults = Query.ExecuteBatch();

	If Not QueryResults[QueryResults.UBound()-1].IsEmpty() Then

		Selection = QueryResults[QueryResults.UBound()-1].Select();
		Selection.Next();
		FillPropertyValues(PreviousConditions, Selection);
		
		InterestScheduleForPreviousConditions = QueryResults[QueryResults.UBound()].Unload();
	
		// If the Balance of the present value is zero at the time of the change
		// , we will add a line to the graph with a zero amount of interest for the correct calculation of interest in the following periods.
		If Selection.PresentValue = 0 Then
			
			AccrualDate = BegOfDay(Object.Date) - 86400;
			PlotLine = InterestScheduleForPreviousConditions.Add();
			PlotLine.Date = AccrualDate;
			PlotLine.Interests = 0;
			
		// If the conditions change document is not the first of the month, then you need to add an additional line to the percentage chart
		ElsIf BegOfDay(Object.Date) <> BegOfMonth(Object.Date) Then

			AccrualDate = BegOfDay(Object.Date) - 86400;

			InterestAmount =
			Selection.PresentValue * (Pow(1 + Selection.InterestRate / 100,
			(AccrualDate - Selection.DateOfPreviousAccrual) / 31536000) - 1);

			PreviousConditions.PresentValue = PreviousConditions.PresentValue + InterestAmount;

			PlotLine = InterestScheduleForPreviousConditions.Add();
			PlotLine.Date = AccrualDate;
			PlotLine.Interests = InterestAmount;

		EndIf;
		
		If GeneratePercentageGraph Then
			PreviousConditions.Insert("InterestGraph", InterestScheduleForPreviousConditions);
		EndIf;
		
	EndIf;
	
	Return New FixedStructure(PreviousConditions);
	
EndFunction

// Contracts that were changed during the lease process by the document "Changing the terms of the lease Contract"
// 
// Parameters:
//  LeaseContracts - CatalogRef.LeaseContract - Lease Contract
//  ArrayOfContracts - Undefined, Array of CatalogRef.LeaseContract - Array Of Contracts
// 
// Returns:
//  Undefined, Array of CatalogRef.LeaseContract - Related Lease Contracts
Function RelatedLeaseContracts(LeaseContracts, ArrayOfContracts = Undefined) Export
	
	If ArrayOfContracts = Undefined Then
		ArrayOfContracts = New Array;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PreviousConditions.Contract AS Contract
		|FROM
		|	InformationRegister.TermsOfLeaseContracts AS CurrentConditions
		|		INNER JOIN InformationRegister.TermsOfLeaseContracts AS PreviousConditions
		|		ON CurrentConditions.Recorder = PreviousConditions.Recorder
		|			AND CurrentConditions.Contract = &LeaseContracts
		|			AND CurrentConditions.Contract <> PreviousConditions.Contract
		|			AND (PreviousConditions.State = VALUE(Enum.CounterpartyContractStates.Closed))
		|			AND (PreviousConditions.Contract <> VALUE(Catalog.LeaseContract.EmptyRef))";
	
	Query.SetParameter("LeaseContracts", LeaseContracts);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		ArrayOfContracts = RelatedLeaseContracts(Selection.Contract, ArrayOfContracts);
		
	EndIf;
	
	ArrayOfContracts.Add(LeaseContracts);
	
	Return ArrayOfContracts;
	
EndFunction

// Fills in the payment schedule and accruals based on the data in the "Calculations" section"
// 
// Parameters:
//  RowData - Structure
//  ServicePaymentSchedule - ValueTable
//  ServiceAccrualSchedule - ValueTable
//  VATRate - CatalogRef.VATRates
Procedure FillInScheduleOfPaymentsAndAccrualsOfIncomeRent(RowData, ServicePaymentSchedule, ServiceAccrualSchedule, VATRate) Export
	
	FixedAsset = RowData.FixedAsset;
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	StartDate = RowData.LeaseStartDate;
	
	#Region ServicePaymentSchedule
	
	ThereIsPeriodicity = RowData.PaymentFrequency <> Enums.ScheduleTimeFence.Custom;
	
	// Deleting irrelevant graph lines
	LinesToDelete = New Array;
	LinesOfFAGraphBy = ServicePaymentSchedule.FindRows(New Structure("FixedAsset", FixedAsset));
	For Each PlotLine In LinesOfFAGraphBy Do
		If ThereIsPeriodicity Or PlotLine.Date < StartDate Then
			LinesToDelete.Add(PlotLine);
		EndIf;
	EndDo;
	For Each RowToDelete In LinesToDelete Do
		ServicePaymentSchedule.Delete(RowToDelete);
	EndDo;
	
	If ThereIsPeriodicity Then
		
		// Formation of schedule dates
		ScheduleDates = New Array;
		CurrentDate = RowData.FirstPaymentDate;
		While CurrentDate <= RowData.RentalEndDate Do
			ScheduleDates.Add(CurrentDate);
			CurrentDate = LeasedAssetAccountingClientServer.NextScheduleDate(CurrentDate, RowData.PaymentFrequency);
		EndDo;

		NumberOfDates = ScheduleDates.Count();

		If NumberOfDates > 0 Then

			// Filling in the schedule
			For Cnt = 0 To NumberOfDates - 1 Do

				CurrentDate = ScheduleDates[Cnt];

				PlotLine = ServicePaymentSchedule.Add();

				PlotLine.Date = CurrentDate;
				PlotLine.FixedAsset = FixedAsset;
				PlotLine.RentalService = RowData.PayAmount;

			EndDo;

		EndIf;

		ServicePaymentSchedule.Sort("Date");
		
	EndIf;
	
	#EndRegion

	#Region ServiceAccrualSchedule

	ThereIsPeriodicity = RowData.AccrualFrequency <> Enums.ScheduleTimeFence.Custom;
	
	// Deleting irrelevant graph lines
	LinesToDelete = New Array;
	LinesOfFAGraphBy = ServiceAccrualSchedule.FindRows(New Structure("FixedAsset", FixedAsset));
	For Each PlotLine In LinesOfFAGraphBy Do
		If ThereIsPeriodicity Or PlotLine.Date < StartDate Then
			LinesToDelete.Add(PlotLine);
		EndIf;
	EndDo;
	For Each RowToDelete In LinesToDelete Do
		ServiceAccrualSchedule.Delete(RowToDelete);
	EndDo;
	
	If ThereIsPeriodicity Then
		
		// Formation of schedule dates
		ScheduleDates = New Array;
		CurrentDate = RowData.DateOfFirstAccrual;
		While CurrentDate <= RowData.RentalEndDate Do
			ScheduleDates.Add(CurrentDate);
			CurrentDate = LeasedAssetAccountingClientServer.NextScheduleDate(CurrentDate, RowData.AccrualFrequency);
		EndDo;

		NumberOfDates = ScheduleDates.Count();

		If NumberOfDates > 0 Then

			// Filling in the schedule
			For Cnt = 0 To NumberOfDates - 1 Do

				CurrentDate = ScheduleDates[Cnt];

				PlotLine = ServiceAccrualSchedule.Add();

				PlotLine.Date = CurrentDate;
				PlotLine.FixedAsset = FixedAsset;
				PlotLine.RentalService = RowData.AccrualAmount;

			EndDo;

		EndIf;

		ServiceAccrualSchedule.Sort("Date");
		
	EndIf;

	#EndRegion

	FillInAmountsOfNDSInIncomeRentalCharts(ServicePaymentSchedule, ServiceAccrualSchedule, VATRate, RowData.LeaseStartDate);
	
EndProcedure

// Fills in VAT amounts in rental income schedules.
// 
// Parameters:
//  ServicePaymentSchedule - DocumentTabularSection.ProvideAssetsToLeasee2_4.ServicePaymentSchedule, DocumentTabularSection.ChangeRentalTerms.ServicePaymentSchedule - Payment schedule for services.
//  ServiceAccrualSchedule - DocumentTabularSection.ProvideAssetsToLeasee2_4.ServiceAccrualSchedule, DocumentTabularSection.ChangeRentalTerms.ServiceAccrualSchedule - Service accrual schedule
//  VATRate - CatalogRef.VATRates - VAT rate.
//  StartDate - Date - Start date of calculation
Procedure FillInAmountsOfNDSInIncomeRentalCharts(ServicePaymentSchedule, ServiceAccrualSchedule, VATRate, StartDate) Export
	
	VATPercentage = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
	
	AmountOfPayments = 0;
	AmountOfCharges = 0;
	
	For Each PlotLine In ServiceAccrualSchedule Do
		AmountOfPayments =AmountOfPayments + PlotLine.RentalService;
		If PlotLine.Date < StartDate Then
			Continue;
		EndIf;
		PlotLine.RentalServiceVAT = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.RentalService, VATPercentage, True);
	EndDo;
	
	For Each PlotLine In ServicePaymentSchedule Do
		AmountOfCharges =AmountOfCharges + PlotLine.RentalService;
		If PlotLine.Date < StartDate Then
			Continue;
		EndIf;
		PlotLine.RentalServiceVAT = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.RentalService, VATPercentage, True);
	EndDo;
	
	If AmountOfPayments = AmountOfCharges Then
		DistributeVATAccrualsToPayments(ServiceAccrualSchedule, ServicePaymentSchedule, "RentalService", "RentalServiceVAT", StartDate);
	EndIf;
	
EndProcedure

// Fills in the column graph filled in the tabular part of the document.
// 
// Parameters:
// TabularSection - FormDataCollection
// PaymentSchedule - FormDataCollection
// ScheduleOfAccruals - FormDataCollection
//
Procedure FillInGraphFilledColumn(TabularSection, PaymentSchedule, ScheduleOfAccruals) Export
	
	For Each FAString In TabularSection Do
		
		FixedAsset = FAString.FixedAsset;
		If ValueIsFilled(FixedAsset) Then
			
			FAString.ScheduleIsFull = LeasedAssetAccountingClientServer.ScheduleIsFull(
										FixedAsset,
										PaymentSchedule,
										ScheduleOfAccruals);
				
		Else
			FAString.ScheduleIsFull = False;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the columns Rental payments, advance payments, fair
// value of the loan, fair value of the loan in the tabular part of the documents transfer of the LEASE_2_4, change of the conditions of the transfer of the lease, and the introduction of the terms of the investment in the lease.
//
// Parameters:
// Object - DocumentObject.ProvideAssetsToLeasee2_4, DocumentObject.EnterRentalInvestmentBalance, DocumentObject.ChangeRentalTerms -
// Currency - CatalogRef.Currencies - currency of the Contract.
Procedure FillInAmountOfRentalPayments(Object, Currency) Export
	
	FATable = Object.FA.Unload();
	If TypeOf(Object.Ref) = Type("DocumentRef.EnterRentalInvestmentBalance") Then
		FATable.Columns.Add("TheInterestAccrualScheduleIsEnteredManually", New TypeDescription("Boolean"));
		For Each FAString In FATable Do
			FAString.TheInterestAccrualScheduleIsEnteredManually = True;
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually
	|INTO TTFATable
	|FROM
	|	&FATable AS FATable
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServicePaymentSchedule.FixedAsset AS FixedAsset,
	|	ServicePaymentSchedule.RentalService AS RentalService,
	|	ServicePaymentSchedule.RentalServiceVAT AS RentalServiceVAT
	|INTO TTPaymentsSchedule
	|FROM
	|	&ServicePaymentSchedule AS ServicePaymentSchedule
	|WHERE
	|	ServicePaymentSchedule.Date >= &Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTOfPaymentAmount.FixedAsset AS FixedAsset,
	|	SUM(TTOfPaymentAmount.RentalService - TTOfPaymentAmount.RentalServiceVAT) AS RentalPayments
	|INTO TTOfPaymentAmount
	|FROM
	|	TTPaymentsSchedule AS TTOfPaymentAmount
	|GROUP BY
	|	TTOfPaymentAmount.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServiceAccrualSchedule.FixedAsset AS FixedAsset,
	|	ServiceAccrualSchedule.RentalService AS RentalService,
	|	ServiceAccrualSchedule.RentalServiceVAT AS RentalServiceVAT
	|INTO AccrualScheduleIsTT
	|FROM
	|	&ServiceAccrualSchedule AS ServiceAccrualSchedule
	|WHERE
	|	ServiceAccrualSchedule.Date >= &Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AmountOfAccrualsTT.FixedAsset AS FixedAsset,
	|	SUM(AmountOfAccrualsTT.RentalService - AmountOfAccrualsTT.RentalServiceVAT) AS Sum
	|INTO AmountOfAccrualsTT
	|FROM
	|	AccrualScheduleIsTT AS AmountOfAccrualsTT
	|GROUP BY
	|	AmountOfAccrualsTT.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InterestAccrualSchedule.FixedAsset AS FixedAsset,
	|	InterestAccrualSchedule.Date AS Date,
	|	InterestAccrualSchedule.Interests AS Interests
	|INTO TTInterestGraph
	|FROM
	|	&InterestAccrualSchedule AS InterestAccrualSchedule
	|WHERE
	|	InterestAccrualSchedule.Date >= &Period
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InterestGraph.FixedAsset AS FixedAsset,
	|	SUM(InterestGraph.Interests) AS Interests
	|INTO TTOfInterestAmount
	|FROM
	|	TTInterestGraph AS InterestGraph
	|GROUP BY
	|	InterestGraph.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|	CASE WHEN NOT &ThisIsInputOfResiduals THEN
	|		ISNULL(PaymentAmounts.RentalPayments, 0)
	|	ELSE ISNULL(AccrualAmounts.Sum, 0) END AS RentalPayments,
	|	(ISNULL(PaymentAmounts.RentalPayments, 0) - ISNULL(InterestAmounts.Interests, 0))
	|		* &FactorOfConversionToCurrencyOfRegul AS FairValueLocal,
	|	(ISNULL(PaymentAmounts.RentalPayments, 0) - ISNULL(InterestAmounts.Interests, 0))
	|		* &ConversionRateToManCurrency AS FairValueManag,
	|	(ISNULL(AccrualAmounts.Sum, 0) - ISNULL(PaymentAmounts.RentalPayments, 0)) AS AdvancePayments
	|FROM
	|	TTFATable AS FATable
	|		LEFT JOIN TTOfPaymentAmount AS PaymentAmounts
	|		ON FATable.FixedAsset = PaymentAmounts.FixedAsset
	|		LEFT JOIN AmountOfAccrualsTT AS AccrualAmounts
	|		ON FATable.FixedAsset = AccrualAmounts.FixedAsset
	|		LEFT JOIN TTOfInterestAmount AS InterestAmounts
	|		ON FATable.FixedAsset = InterestAmounts.FixedAsset";
	
	ThisIsTransferForRent = TypeOf(Object.Ref) = Type("DocumentRef.ProvideAssetsToLeasee2_4");
	ThisIsInputOfResiduals = TypeOf(Object.Ref) = Type("DocumentRef.EnterRentalInvestmentBalance");
	
	Query.SetParameter("ServicePaymentSchedule", Object.ServicePaymentSchedule.Unload());
	Query.SetParameter("ServiceAccrualSchedule", Object.ServiceAccrualSchedule.Unload());
	Query.SetParameter("InterestAccrualSchedule", Object.InterestAccrualSchedule.Unload());
	Query.SetParameter("FATable", FATable);
	Query.SetParameter("ThisIsInputOfResiduals", ThisIsInputOfResiduals);
	Query.SetParameter("Period", BegOfDay(Object.Date));
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Currency, Currency, Object.Date, Object.Organization);
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		FAStrings = Object.FA.FindRows(New Structure("FixedAsset", Selection.FixedAsset));
		For Each FAString In FAStrings Do
			FillPropertyValues(FAString, Selection, "RentalPayments");
			If ThisIsTransferForRent Then
				FillPropertyValues(FAString, Selection, "AdvancePayments");
			EndIf;
			If Selection.TheInterestAccrualScheduleIsEnteredManually And ThisIsTransferForRent Then
				FillPropertyValues(FAString, Selection, "FairValueLocal, FairValueManag");
			EndIf;
		EndDo;
	EndDo;
	
	If ThisIsTransferForRent Then
		Coefficients = Object.FA.Unload(,"AdvancePayments").UnloadColumn("AdvancePayments");
		AllocationResult = Undefined;
		AllocationResult = Common.DistributeAmountInProportionToCoefficients(
									Object.AmountOfAdvancePaymentsLocal,
									Coefficients);
		If AllocationResult <> Undefined Then
			For RowIndex = 0 To AllocationResult.UBound() Do
				RowData = Object.FA.Get(RowIndex);
				RowData.AdvancePaymentsLocal = AllocationResult[RowIndex];
			EndDo;
		EndIf;
		If Object.AmountOfAdvancePaymentsLocal = 0 Then
			For Each RowData In Object.FA Do
				RowData.AdvancePaymentsLocal = 0;
			EndDo;
		EndIf;
	EndIf;

EndProcedure

// Calculates the rate and schedule of accrual of interest income rent.
// 
// Parameters:
//  TempTablesManager - See ParametersForCalculatingInterestRatesOfProfitableLeases
//  OutputMessages - Boolean
//  Cancel - Boolean -
Procedure CalculateInterestRatesOfProfitableRentInBatches(TempTablesManager, OutputMessages = False, Cancel = False) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	QueryTexts = New ValueList;

	QueryText = 
	"SELECT DISTINCT
	|	DocumentsData.Ref,
	|	DocumentsData.Date,
	|	DocumentsData.Organization,
	|	DocumentsData.Contract.VATRate AS VATRate
	|FROM
	|	RentalDocuments AS DocumentsData
	|";
	QueryTexts.Add(QueryText, "DocumentsForSettlement");

	QueryText = 
	"SELECT
	|	DataFA.Ref,
	|	DataFA.LineNumber,
	|	DataFA.FixedAsset,
	|	DataFA.RentalEndDate,
	|	DataFA.TheInterestAccrualScheduleIsEnteredManually,
	|	CASE
	|		WHEN TTCourses.LocalConversionRatio = 0 THEN
	|			DataFA.PresentValueLocal
	|		ELSE
	|			DataFA.PresentValueLocal/ TTCourses.LocalConversionRatio
	|	END AS PresentValue,
	|	CASE 
	|		WHEN TTCourses.LocalConversionRatio = 0 THEN
	|			DataFA.RentalPayments + DataFA.NonGuaranteedResidualValueLocal
	|		ELSE
	|			DataFA.RentalPayments + DataFA.NonGuaranteedResidualValueLocal / TTCourses.LocalConversionRatio
	|	END AS RentalPayments,
	|	CASE 
	|		WHEN TTCourses.LocalConversionRatio = 0 THEN
	|			DataFA.NonGuaranteedResidualValueLocal
	|		ELSE
	|			DataFA.NonGuaranteedResidualValueLocal / TTCourses.LocalConversionRatio
	|	END AS NGLV,
	|	0 AS RateOfReturn,
	|	DataFA.FixedAssetPresentation AS FixedAssetPresentation
	|
	|FROM
	|	DataFA AS DataFA
	|	INNER JOIN TTCurrencyConversionFactors AS TTCourses
	|		ON DataFA.ARAPCurrency = TTCourses.ARAPCurrency
	|		 AND DataFA.Organization = TTCourses.Organization
	|		 AND DataFA.Date = TTCourses.Date
	|WHERE
	|	NOT DataFA.TheInterestAccrualScheduleIsEnteredManually
	|";
	QueryTexts.Add(QueryText, "DataFA");
	
	QueryText =
	"SELECT
	|	ChartTable.Ref           AS Ref,
	|	ChartTable.Date             AS Date,
	|	ChartTable.FixedAsset AS FixedAsset,
	|	ChartTable.Interests         AS Interests
	|FROM
	|	DocumentDataTableScheduleOfAccrualOfInterest AS ChartTable
	|WHERE
	|	ChartTable.TheInterestAccrualScheduleIsEnteredManually
	|";
	
	QueryTexts.Add(QueryText, "InterestAccrualSchedule");
	
	QueryText =
	"SELECT
	|	ChartTable.Ref            AS Ref,
	|	ChartTable.Date              AS Date,
	|	ChartTable.FixedAsset  AS FixedAsset,
	|	ChartTable.RentalService    AS RentalService,
	|	ChartTable.RentalServiceVAT AS RentalServiceVAT
	|FROM
	|	DocumentDataTableServicePaymentSchedule AS ChartTable
	|";
	
	QueryTexts.Add(QueryText, "ServicePaymentSchedule");
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	InterestAccrualSchedule = MovementTables.TableScheduleOfAccrualOfInterest; // - ValueTable
	InterestAccrualSchedule.Indexes.Add("Ref");
	InterestAccrualSchedule.Indexes.Add("FixedAsset");
	InterestAccrualSchedule.Indexes.Add("Date");
	
	ServicePaymentSchedule = MovementTables.TableScheduleOfPaymentsForServices; // - ValueTable
	ServicePaymentSchedule.Indexes.Add("Ref");
	ServicePaymentSchedule.Indexes.Add("FixedAsset");
	
	ScheduleOfPayments = New ValueTable; 
	ScheduleOfPayments.Columns.Add("Date", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	ScheduleOfPayments.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Any));
	
	For Each DocumentLine In MovementTables.TableDocumentsForCalculation Do
		
		DocumentRows = MovementTables.FADataTable.FindRows(
			New Structure("Ref",
							DocumentLine.Ref));
		FATable = MovementTables.FADataTable.Copy(DocumentRows,);
	
		For Each RowData In FATable Do
			
			FixedAsset = RowData.FixedAsset;
			
			// Calculation of the rate of return
			FACost = RowData.PresentValue;
			RentalPayments = RowData.RentalPayments;
			
			PaymentLinesByFA = ServicePaymentSchedule.FindRows(
				New Structure("FixedAsset,Ref",
								FixedAsset,
								DocumentLine.Ref));
			
			If Not PaymentLinesByFA.Count() Then
				Cancel = True;
				If OutputMessages Then
					TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"" chưa điền lịch thanh toán. Sẽ không tính tỷ suất lợi nhuận';
										|ru = 'В строке %1 списка ""Основные средства"" не заполнен график оплат. Ставка доходности не будет рассчитана';
										|en = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list. The rate of return will not be calculated'; fa = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list. The rate of return will not be calculated';
										|it = 'В строке %1 списка ""Основные средства"" не заполнен график оплат. Ставка доходности не будет рассчитана';
										|pl = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list. The rate of return will not be calculated';
										|tr = '""Sabit kıymetler"" listesinin %1 satırında ödeme planı doldurulmadı. Getiri oranı hesaplanmayacaktır'");
					MessageText = StrTemplate(TextTemplate1, RowData.LineNumber);
					RegisterCalculationExecutionProblem(
						Catalogs.MonthEndClosingOperations.CalculateRentalInvestmentCost, 
						BegOfMonth(DocumentLine.Date),
						DocumentLine.Organization,
						MessageText,,
						DocumentLine.Ref,
						Cancel);
				EndIf;
				Continue;
			EndIf;
			
			If RentalPayments < FACost Then
				TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", số tiền thanh toán tiền thuê không gồm thuế GTGT (%2) ít hơn giá trị đối tượng (%3). Sẽ tính tỷ suất lợi nhuận';
									|ru = 'В строке %1 списка ""Основные средства"" сумма арендных платежей без НДС (%2) меньше стоимости объекта (%3). Ставка доходности не будет рассчитана';
									|en = 'In line %1 of the ""Fixed assets"" list, the amount of rental payments excluding VAT (%2) is less than the object cost (%3). The rate of return will not be calculated'; fa = 'In line %1 of the ""Fixed assets"" list, the amount of rental payments excluding VAT (%2) is less than the object cost (%3). The rate of return will not be calculated';
									|it = 'В строке %1 списка ""Основные средства"" сумма арендных платежей без НДС (%2) меньше стоимости объекта (%3). Ставка доходности не будет рассчитана';
									|pl = 'In line %1 of the ""Fixed assets"" list, the amount of rental payments excluding VAT (%2) is less than the object cost (%3). The rate of return will not be calculated';
									|tr = '""Sabit kıymetler"" listesinin %1 satırında KDV hariç kira ödemelerinin tutarı (%2), nesnenin değerinden (%3) daha azdır. Getiri oranı hesaplanmayacaktır'");
				MessageText = StrTemplate(TextTemplate1, RowData.LineNumber, Format(RentalPayments, "NFD=2; NZ=0,00"), Format(FACost, "NFD=2; NZ=0,00"));
				RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.CalculateRentalInvestmentCost, 
					BegOfMonth(DocumentLine.Date),
					DocumentLine.Organization,
					MessageText,,
					DocumentLine.Ref,
					Cancel);
				Continue;
			EndIf;
			
			ScheduleOfPayments.Clear();
				
			For Each PaymentLine_ In PaymentLinesByFA Do
				PlotLine = ScheduleOfPayments.Add();
				PlotLine.Sum = PaymentLine_.RentalService - PaymentLine_.RentalServiceVAT;
				PlotLine.Date = PaymentLine_.Date;
			EndDo;
			
			If RowData.NGLV > 0 Then
				If ValueIsFilled(RowData.RentalEndDate) Then
					PlotLine = ScheduleOfPayments.Add();
					PlotLine.Sum = RowData.NGLV;
					PlotLine.Date = RowData.RentalEndDate;
				Else
					PlotLine = ScheduleOfPayments[ScheduleOfPayments.Count()-1];
					PlotLine.Sum = PlotLine.Sum + RowData.NGLV;
				EndIf;
			EndIf;
			
			AddLastDayOfMonthToSchedule(ScheduleOfPayments, BegOfDay(DocumentLine.Date));
			
			PlotLine = ScheduleOfPayments.Insert(0);
			PlotLine.Sum = -FACost;
			PlotLine.Date = BegOfDay(DocumentLine.Date);
			
			ScheduleOfPayments.Sort("Date");
			
			Try
				RowData.RateOfReturn = InterestRate(ScheduleOfPayments);
			Except
				RowData.RateOfReturn = 0;
				TemplateText = NStr("vi = 'Không thể tính tỷ suất sinh lời theo tài sản cố định %1. Hãy kiểm tra lịch biểu thanh toán và giá trị tài sản cố định.';
									|ru = 'Не удалось рассчитать ставку доходности по основному средству %1. Проверьте график оплат и стоимость основных средств.';
									|en = 'Cannot calculate the rate of return on the %1 fixed asset. Check the payment schedule and the fixed asset cost.'; fa = 'Cannot calculate the rate of return on the %1 fixed asset. Check the payment schedule and the fixed asset cost.';
									|it = 'Не удалось рассчитать ставку доходности по основному средству %1. Проверьте график оплат и стоимость основных средств.';
									|pl = 'Cannot calculate the rate of return on the %1 fixed asset. Check the payment schedule and the fixed asset cost.';
									|tr = 'Sabit kıymet %1 üzerindeki getiri oranı hesaplanamadı. Ödeme planını ve sabit kıymetlerin maliyetini kontrol edin.'");
				MessageText = StrTemplate(TemplateText, RowData.FixedAssetPresentation);
				RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.CalculateRentalInvestmentCost, 
					BegOfMonth(DocumentLine.Date),
					DocumentLine.Organization,
					MessageText,,
					DocumentLine.Ref,
					Cancel);
				Continue;
			EndTry;
			
			// Calculation of the interest schedule
			LoanBalance = FACost;
			RemainingInterest = RentalPayments - FACost;
			PreviousDate = BegOfDay(DocumentLine.Date);
			
			LinePercentages = Undefined;
			
			For Each PlotLine In ScheduleOfPayments Do
				
				If PlotLine.Sum < 0 Then
					Continue;
				EndIf;
				
				InterestAmount =
					LoanBalance
					* (Pow(1 + RowData.RateOfReturn / 100, (PlotLine.Date - PreviousDate) / 31536000) - 1);
				
				InterestAmount = Round(InterestAmount, 2);
				InterestAmount = Min(InterestAmount, RemainingInterest);
				InterestAmount = Max(InterestAmount, 0);
				If InterestAmount > 0 Then
					
					// The percentage graph should not have the same dates.The interest on one date is summed up.
					InterestLinesByDate = InterestAccrualSchedule.FindRows(
						New Structure("FixedAsset, Date, Ref",
										PlotLine.Date,
										FixedAsset,
										DocumentLine.Ref));
										
					If InterestLinesByDate.Count() = 0 Then
						LinePercentages = InterestAccrualSchedule.Add();
						LinePercentages.Interests = 0;
					Else
						LinePercentages = InterestLinesByDate.Get(0);
					EndIf;
					
					LinePercentages.Date = PlotLine.Date;
					LinePercentages.Interests = LinePercentages.Interests + InterestAmount;
					LinePercentages.FixedAsset = FixedAsset;
					LinePercentages.Ref = DocumentLine.Ref;
					
					RemainingInterest = RemainingInterest - InterestAmount;
					
				EndIf;
				
				LoanBalance = Max(LoanBalance - PlotLine.Sum + InterestAmount, 0);
				
				// the rounding error is attributed to the last accrual
				If RemainingInterest > 0 And LoanBalance = 0 And LinePercentages <> Undefined Then
					LinePercentages.Interests = LinePercentages.Interests + RemainingInterest;
					RemainingInterest = 0;
				EndIf;
					
				PreviousDate = PlotLine.Date;
				
			EndDo;
			
		EndDo;
	EndDo;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	ChartTable.Ref AS Ref,
	|	ChartTable.Date AS Date,
	|	ChartTable.FixedAsset AS FixedAsset,
	|	ChartTable.Interests AS Interests
	|INTO TableScheduleOfAccrualOfInterest_Preliminary
	|FROM
	|	&InterestGraph AS ChartTable
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Delta.Ref AS Ref,
	|	Delta.FixedAsset AS FixedAsset,
	|	SUM(Delta.Interests) AS Delta,
	|	Delta.DateOfFirstMonth AS DateOfFirstMonth
	|INTO DeltasOfFirstMonth
	|FROM
	|	(SELECT
	|		ChartTable.Ref AS Ref,
	|		ChartTable.FixedAsset AS FixedAsset,
	|		SUM(ChartTable.Interests) AS Interests,
	|		MAX(ChartTable.Date) AS DateOfFirstMonth
	|	FROM
	|		DocumentDataTableScheduleOfAccrualOfInterest AS ChartTable
	|			INNER JOIN RentalDocuments AS RentalDocuments
	|			ON ChartTable.Ref = RentalDocuments.Ref
	|				AND ChartTable.FixedAsset = RentalDocuments.FixedAsset
	|				AND (BEGINOFPERIOD(ChartTable.Date, MONTH) = BEGINOFPERIOD(RentalDocuments.Date, MONTH))
	|	
	|	GROUP BY
	|		ChartTable.Ref,
	|		ChartTable.FixedAsset
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ChartTable.Ref,
	|		ChartTable.FixedAsset,
	|		-SUM(ChartTable.Interests),
	|		MAX(ChartTable.Date)
	|	FROM
	|		TableScheduleOfAccrualOfInterest_Preliminary AS ChartTable
	|			INNER JOIN RentalDocuments AS RentalDocuments
	|			ON ChartTable.Ref = RentalDocuments.Ref
	|				AND ChartTable.FixedAsset = RentalDocuments.FixedAsset
	|				AND (BEGINOFPERIOD(ChartTable.Date, MONTH) = BEGINOFPERIOD(RentalDocuments.Date, MONTH))
	|	
	|	GROUP BY
	|		ChartTable.Ref,
	|		ChartTable.FixedAsset) AS Delta
	|
	|GROUP BY
	|	Delta.Ref,
	|	Delta.FixedAsset,
	|	Delta.DateOfFirstMonth
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset,
	|	DateOfFirstMonth
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChartTable.Ref AS Ref,
	|	ChartTable.FixedAsset AS FixedAsset,
	|	MIN(ChartTable.Date) AS DateOfSecondMonth,
	|	MIN(DeltasOfFirstMonth.Delta) AS Delta
	|INTO DatesOfSecondMonth
	|FROM
	|	TableScheduleOfAccrualOfInterest_Preliminary AS ChartTable
	|		INNER JOIN RentalDocuments AS RentalDocuments
	|		ON ChartTable.Ref = RentalDocuments.Ref
	|			AND ChartTable.FixedAsset = RentalDocuments.FixedAsset
	|			AND (BEGINOFPERIOD(ChartTable.Date, MONTH) > BEGINOFPERIOD(RentalDocuments.Date, MONTH))
	|		LEFT JOIN DeltasOfFirstMonth AS DeltasOfFirstMonth
	|		ON ChartTable.Ref = DeltasOfFirstMonth.Ref
	|			AND ChartTable.FixedAsset = DeltasOfFirstMonth.FixedAsset
	|
	|GROUP BY
	|	ChartTable.Ref,
	|	ChartTable.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset,
	|	DateOfSecondMonth
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChartTable.Ref AS Ref,
	|	ChartTable.Date AS Date,
	|	ChartTable.FixedAsset AS FixedAsset,
	|	ChartTable.Interests + ISNULL(DeltasOfFirstMonth.Delta, 0) - ISNULL(DatesOfSecondMonth.Delta, 0) AS Interests,
	|	ISNULL(DeltasOfFirstMonth.Delta, 0) - ISNULL(DatesOfSecondMonth.Delta, 0) AS InterestAdjustment
	|INTO TableScheduleOfAccrualOfInterest
	|FROM
	|	TableScheduleOfAccrualOfInterest_Preliminary AS ChartTable
	|		LEFT JOIN DeltasOfFirstMonth AS DeltasOfFirstMonth
	|		ON ChartTable.Ref = DeltasOfFirstMonth.Ref
	|			AND ChartTable.FixedAsset = DeltasOfFirstMonth.FixedAsset
	|			AND ChartTable.Date = DeltasOfFirstMonth.DateOfFirstMonth
	|		LEFT JOIN DatesOfSecondMonth AS DatesOfSecondMonth
	|		ON ChartTable.Ref = DatesOfSecondMonth.Ref
	|			AND ChartTable.FixedAsset = DatesOfSecondMonth.FixedAsset
	|			AND ChartTable.Date = DatesOfSecondMonth.DateOfSecondMonth
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableScheduleOfAccrualOfInterest_Preliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DeltasOfFirstMonth
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DatesOfSecondMonth
	|";
	Query.SetParameter("InterestGraph", InterestAccrualSchedule);
	
	Query.Execute();

EndProcedure

// Calculates the rate and schedule of accrual of interest income rent in the background task.
// 
// Parameters:
//  CalculationParameters - See ParametersForCalculatingInterestRatesOfProfitableLeases
//
// Returns: 
//  Structure:
//  * FATable - See ParametersForCalculatingInterestRatesOfProfitableLeases
//  * InterestAccrualSchedule - See ParametersForCalculatingInterestRatesOfProfitableLeases
//
Function CalculateRentalInterestRatesInBackground(CalculationParameters) Export
	
	OperationType = ?(CalculationParameters.ThisIsChangeOfConditions, "RentalTermsAdjustment", "TransferToRental");
	KeyOperation = StrTemplate("CommonModule.LeasedAssetAccounting.CalculateInterestRatesOfProfitableRent.%1", OperationType);
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	
	CalculateInterestRatesOfProfitableRent(CalculationParameters);
	ExecutionResult = New Structure;
	ExecutionResult.Insert("FATable", CalculationParameters.FATable);
	ExecutionResult.Insert("InterestAccrualSchedule", CalculationParameters.InterestAccrualSchedule);
	QuantityProcessed = CalculationParameters.InterestAccrualSchedule.Count() / 10000;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, QuantityProcessed);
	
	Return ExecutionResult;
	
EndFunction

// Calculates the rate and schedule of accrual of interest income rent.
// 
// Parameters:
//  CalculationParameters - See ParametersForCalculatingInterestRatesOfProfitableLeases
//  Cancel - Boolean -
Procedure CalculateInterestRatesOfProfitableRent(CalculationParameters, Cancel = False) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
		"SELECT
		|	FATable.LineNumber AS LineNumber,
		|	FATable.FixedAsset AS FixedAsset,
		|	FATable.RentalEndDate AS RentalEndDate,
		|	FATable.FairValueLocal AS FairValueLocal,
		|	FATable.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
		|	FATable.RentalPayments AS RentalPayments,
		|	FATable.AdvancePayments AS AdvancePayments,
		|	FATable.AdvancePaymentsLocal AS AdvancePaymentsLocal,
		|	FATable.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually
		|INTO TTFATable
		|FROM
		|	&FATable AS FATable
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(ServicePaymentSchedules.ChangeDate) AS ChangeDate,
		|	ServicePaymentSchedules.FixedAsset AS FixedAsset,
		|	&DocumentDate AS Date
		|INTO CurrentTermsAndConditionsBeforeChangesToContract
		|FROM
		|	TTFATable AS DocumentData
		|		INNER JOIN InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS ServicePaymentSchedules
		|		ON DocumentData.FixedAsset = ServicePaymentSchedules.FixedAsset
		|WHERE
		|	ServicePaymentSchedules.ChangeDate < BEGINOFPERIOD(&DocumentDate, DAY)
		|	AND ServicePaymentSchedules.Contract = &Contract
		|	AND &ThisIsChangeOfConditions
		|
		|GROUP BY
		|	ServicePaymentSchedules.FixedAsset
		|
		|INDEX BY
		|	FixedAsset,
		|	ChangeDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ChartTable.FixedAsset AS FixedAsset,
		|	SUM(ChartTable.RentalService - ChartTable.RentalServiceVAT) AS RentalPayments
		|INTO RentalPaymentsBeforeChange
		|FROM
		|	InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS ChartTable
		|		INNER JOIN CurrentTermsAndConditionsBeforeChangesToContract AS ActualConditions
		|		ON (ActualConditions.FixedAsset = ChartTable.FixedAsset)
		|			AND (ActualConditions.ChangeDate = ChartTable.ChangeDate)
		|WHERE
		|	ChartTable.Contract = &Contract
		|	AND ChartTable.Date >= BEGINOFPERIOD(ActualConditions.Date, DAY)
		|
		|GROUP BY
		|	ChartTable.FixedAsset
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ChartTable.FixedAsset AS FixedAsset,
		|	SUM(ChartTable.Interests) AS InterestDiscount
		|INTO InterestBeforeChange
		|FROM
		|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS ChartTable
		|		INNER JOIN CurrentTermsAndConditionsBeforeChangesToContract AS ActualConditions
		|		ON (ActualConditions.FixedAsset = ChartTable.FixedAsset)
		|			AND (ActualConditions.ChangeDate = ChartTable.ChangeDate)
		|WHERE
		|	ChartTable.Contract = &Contract
		|	AND ChartTable.Date >= BEGINOFPERIOD(ActualConditions.Date, MONTH)
		|
		|GROUP BY
		|	ChartTable.FixedAsset
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InvestmentInRent.RentalPaymentsLocalBalance + InvestmentInRent.InterestDiscountLocalBalance AS NRILocal,
		|	InvestmentInRent.NonGuaranteedResidualValueLocalBalance AS NonGuaranteedResidualValueLocal,
		|	-InvestmentInRent.InterestDiscountBalance AS RemainingInterest,
		|	InvestmentInRent.FixedAsset AS FixedAsset
		|INTO TTInvestmentInRent
		|FROM
		|	AccumulationRegister.InvestmentInRent.Balance(
		|			&PeriodLimit,
		|			Organization = &Organization
		|				AND FixedAsset IN
		|					(SELECT
		|						TTFATable.FixedAsset AS FixedAsset
		|					FROM
		|						TTFATable AS TTFATable)) AS InvestmentInRent
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(InvestmentInRent.InterestDiscount) AS PercentagesAreFact,
		|	InvestmentInRent.FixedAsset AS FixedAsset
		|INTO TTActualInterest
		|FROM
		|	AccumulationRegister.InvestmentInRent AS InvestmentInRent
		|WHERE
		|	InvestmentInRent.Recorder = &Ref
		|	AND InvestmentInRent.Active
		|
		|GROUP BY
		|	InvestmentInRent.FixedAsset
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OtherExpensesBalance.SumComplBalance AS SumComplBalance,
		|	OtherExpensesBalance.DimensionOfExpenses AS FixedAsset
		|INTO TTFAExpenses
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(
		|			&PeriodLimit,
		|			Organization = &Organization
		|				AND DimensionOfExpenses IN
		|					(SELECT
		|						TTFATable.FixedAsset AS FixedAsset
		|					FROM
		|						TTFATable AS TTFATable)) AS OtherExpensesBalance
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FACostBalance.LocalCostBalance AS LocalCostBalance,
		|	FACostBalance.FixedAsset AS FixedAsset
		|INTO CostTTOfFA
		|FROM
		|	AccumulationRegister.FACost.Balance(
		|			&PeriodLimit,
		|			Organization = &Organization
		|				AND FixedAsset IN
		|					(SELECT
		|						TTFATable.FixedAsset AS FixedAsset
		|					FROM
		|						TTFATable AS TTFATable)) AS FACostBalance
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FixedAssetsDepreciationChargeBalance.FixedAsset AS FixedAsset,
		|	FixedAssetsDepreciationChargeBalance.DepreciationLocalBalance AS DepreciationLocalBalance
		|INTO TTDepreciationFA
		|FROM
		|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
		|			&PeriodLimit,
		|			Organization = &Organization
		|				AND FixedAsset IN
		|					(SELECT
		|						TTFATable.FixedAsset AS FixedAsset
		|					FROM
		|						TTFATable AS TTFATable)) AS FixedAssetsDepreciationChargeBalance
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ImpairmentFABalance.NonCurrentAsset AS NonCurrentAsset,
		|	ImpairmentFABalance.ImpairmentLocalAssetsBalance AS ImpairmentLocalAssetsBalance
		|INTO TTFAImpairment
		|FROM
		|	AccumulationRegister.ImpairmentFA.Balance(
		|			&PeriodLimit,
		|			Organization = &Organization
		|				AND NonCurrentAsset IN
		|					(SELECT
		|						TTFATable.FixedAsset AS FixedAsset
		|					FROM
		|						TTFATable AS TTFATable)) AS ImpairmentFABalance
		|
		|INDEX BY
		|	NonCurrentAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTFATable.LineNumber AS LineNumber,
		|	TTFATable.FixedAsset AS FixedAsset,
		|	TTFATable.RentalEndDate AS RentalEndDate,
		|	CAST((CASE
		|			WHEN &ThisIsChangeOfConditions
		|				THEN ISNULL(RentalPaymentsBeforeChange.RentalPayments, 0) / &ConversionFactorFromLocalCurrency - ISNULL(InterestBeforeChange.InterestDiscount, 0) / &ConversionFactorFromLocalCurrency + ISNULL(TTInvestmentInRent.NonGuaranteedResidualValueLocal, 0) + ISNULL(TTFAExpenses.SumComplBalance, 0)
		|			WHEN TTFATable.FairValueLocal > 0
		|				THEN TTFATable.FairValueLocal - TTFATable.AdvancePaymentsLocal
		|			ELSE ISNULL(CostTTOfFA.LocalCostBalance, 0) + ISNULL(TTDepreciationFA.DepreciationLocalBalance, 0) + ISNULL(TTFAImpairment.ImpairmentLocalAssetsBalance, 0) + ISNULL(TTFAExpenses.SumComplBalance, 0) - TTFATable.AdvancePaymentsLocal
		|		END) * &ConversionFactorFromLocalCurrency AS NUMBER(31, 2)) AS PresentValue,
		|	CASE
		|		WHEN TTActualInterest.FixedAsset IS NULL
		|			THEN 0
		|		ELSE TTFATable.RentalPayments
		|				- ISNULL(TTActualInterest.PercentagesAreFact, 0)
		|				- ISNULL(InterestBeforeChange.InterestDiscount, 0)
		|				+ CAST(TTFATable.NonGuaranteedResidualValueLocal * &ConversionFactorFromLocalCurrency AS NUMBER(31, 2))
		|	END AS PresentValueFact,
		|	TTFATable.RentalPayments + CAST(TTFATable.NonGuaranteedResidualValueLocal * &ConversionFactorFromLocalCurrency AS NUMBER(31, 2)) AS RentalPayments,
		|	TTFATable.AdvancePaymentsLocal AS AdvancePaymentsLocal,
		|	0 AS RateOfReturn,
		|	TTFATable.FairValueLocal AS FairValue,
		|	ISNULL(TTFAExpenses.SumComplBalance, 0) AS ExpenseAmount,
		|	ISNULL(CostTTOfFA.LocalCostBalance, 0) AS FACost,
		|	ISNULL(TTDepreciationFA.DepreciationLocalBalance, 0) AS Depreciation,
		|	ISNULL(TTFAImpairment.ImpairmentLocalAssetsBalance, 0) AS Impairment,
		|	ISNULL(CostTTOfFA.LocalCostBalance, 0) + ISNULL(TTDepreciationFA.DepreciationLocalBalance, 0) + ISNULL(TTFAImpairment.ImpairmentLocalAssetsBalance, 0) AS TotalCostOfFA,
		|	ISNULL(CostTTOfFA.LocalCostBalance, 0) + ISNULL(TTDepreciationFA.DepreciationLocalBalance, 0) + ISNULL(TTFAExpenses.SumComplBalance, 0) + ISNULL(TTFAImpairment.ImpairmentLocalAssetsBalance, 0) AS TotalInvestment,
		|	ISNULL(RentalPaymentsBeforeChange.RentalPayments, 0) / &ConversionFactorFromLocalCurrency
		|		+ ISNULL(TTInvestmentInRent.NonGuaranteedResidualValueLocal, 0)
		|		- ISNULL(InterestBeforeChange.InterestDiscount, 0) / &ConversionFactorFromLocalCurrency AS CHIABalance,
		|	ISNULL(InterestBeforeChange.InterestDiscount, 0) AS RemainingInterest,
		|	TTFATable.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
		|	ISNULL(TTInvestmentInRent.NonGuaranteedResidualValueLocal, 0) AS NGLVBalance,
		|	TTFATable.NonGuaranteedResidualValueLocal - ISNULL(TTInvestmentInRent.NonGuaranteedResidualValueLocal, 0) AS ChangingNGLV,
		|	CAST(TTFATable.NonGuaranteedResidualValueLocal * &ConversionFactorFromLocalCurrency AS NUMBER(31, 2)) AS NGLV,
		|	PRESENTATION(TTFATable.FixedAsset) AS FixedAssetPresentation,
		|	TTFATable.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually
		|FROM
		|	TTFATable AS TTFATable
		|		LEFT JOIN TTInvestmentInRent AS TTInvestmentInRent
		|		ON TTFATable.FixedAsset = TTInvestmentInRent.FixedAsset
		|		LEFT JOIN TTFAExpenses AS TTFAExpenses
		|		ON TTFATable.FixedAsset = TTFAExpenses.FixedAsset
		|		LEFT JOIN CostTTOfFA AS CostTTOfFA
		|		ON TTFATable.FixedAsset = CostTTOfFA.FixedAsset
		|		LEFT JOIN TTDepreciationFA AS TTDepreciationFA
		|		ON TTFATable.FixedAsset = TTDepreciationFA.FixedAsset
		|		LEFT JOIN TTFAImpairment AS TTFAImpairment
		|		ON TTFATable.FixedAsset = TTFAImpairment.NonCurrentAsset
		|		LEFT JOIN RentalPaymentsBeforeChange AS RentalPaymentsBeforeChange
		|		ON (RentalPaymentsBeforeChange.FixedAsset = TTFATable.FixedAsset)
		|		LEFT JOIN InterestBeforeChange AS InterestBeforeChange
		|		ON (InterestBeforeChange.FixedAsset = TTFATable.FixedAsset)
		|		LEFT JOIN TTActualInterest AS TTActualInterest
		|		ON (TTActualInterest.FixedAsset = TTFATable.FixedAsset)";
	
	ConversionFactorFromLocalCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		CalculationParameters.LocalAccountingCurrency, 
		CalculationParameters.ContractDetails_.ARAPCurrency, 
		CalculationParameters.Date);
		
	If ConversionFactorFromLocalCurrency = 0 Then
		ConversionFactorFromLocalCurrency = 1;
	EndIf;
	
	Query.SetParameter("ARAPCurrency", CalculationParameters.ContractDetails_.ARAPCurrency);
	Query.SetParameter("LocalAccountingCurrency", CalculationParameters.LocalAccountingCurrency);
	Query.SetParameter("ConversionFactorFromLocalCurrency", ConversionFactorFromLocalCurrency);
	
	ThisIsChangeOfConditions = TypeOf(CalculationParameters.Ref) = Type("DocumentRef.ChangeRentalTerms");
	Query.SetParameter("ThisIsChangeOfConditions", ThisIsChangeOfConditions);
	
	Query.SetParameter("Ref", CalculationParameters.Ref);
	Query.SetParameter("Organization", CalculationParameters.Organization);
	Query.SetParameter("Contract", CalculationParameters.Contract);
	Query.SetParameter("DocumentDate", CalculationParameters.Date);
	Query.SetParameter("PeriodLimit",
		New Boundary(New PointInTime(CalculationParameters.Date, CalculationParameters.Ref), BoundaryType.Excluding));
	Query.SetParameter("FATable", CalculationParameters.FA);
	
	QueryResult = Query.Execute();
	
	FATable = QueryResult.Unload();
	FATable.Columns.Add("SettlementDetails", New TypeDescription("Structure"));
	For Each RowData In FATable Do
		Details = New Structure;
		Details.Insert("DocumentDate", CalculationParameters.Date);
		If ThisIsChangeOfConditions Then
			Details.Insert("CHIABalance", RowData.CHIABalance);
			Details.Insert("ChangingNGLV", RowData.ChangingNGLV);
			Details.Insert("NGLVBalance", RowData.NGLVBalance);
			Details.Insert("ChangingCHIA", RowData.ExpenseAmount - RowData.ChangingNGLV);
			TotalCHIA = RowData.CHIABalance + RowData.ExpenseAmount - RowData.ChangingNGLV;
		Else
			Details.Insert("FACost", RowData.FACost);
			Details.Insert("Depreciation", RowData.Depreciation);
			Details.Insert("Impairment", RowData.Impairment);
			Details.Insert("TotalCostOfFA", RowData.TotalCostOfFA);
			Details.Insert("FairValue", RowData.FairValue);
			If RowData.FairValue > RowData.TotalInvestment Then
				Details.Insert("RevaluationOfIncome", RowData.FairValue - RowData.TotalInvestment);
			ElsIf RowData.FairValue <> 0 Then
				Details.Insert("RevaluationExpenses", RowData.TotalInvestment - RowData.FairValue);
			EndIf;
			If RowData.FairValue > 0 Then
				TotalCHIA = RowData.FairValue;
			Else
				TotalCHIA = RowData.TotalInvestment;
			EndIf;
		EndIf;
		Details.Insert("ExpenseAmount", RowData.ExpenseAmount);
		Details.Insert("NonGuaranteedResidualValueLocal", RowData.NonGuaranteedResidualValueLocal);
		Details.Insert("TotalCHIA", TotalCHIA);
		If CalculationParameters.ContractDetails_.ARAPCurrency <> CalculationParameters.LocalAccountingCurrency Then
			Details.Insert("ARAPCurrency", "(" + CalculationParameters.ContractDetails_.ARAPCurrency + ")");
			Details.Insert("ComplCurrency", "(" +CalculationParameters.LocalAccountingCurrency + ")");
		Else
			Details.Insert("ARAPCurrency", "");
			Details.Insert("ComplCurrency", "");
		EndIf;
		RowData.SettlementDetails = Details;
	EndDo;
	
	ScheduleOfPayments = New ValueTable; 
	ScheduleOfPayments.Columns.Add("Date", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	ScheduleOfPayments.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Any));
	
	If Cancel Then
		
		CalculationParameters.Insert("FATable", FATable);
		
		If CalculationParameters.ShouldCalculatePercentage Then
			For Each RowData In FATable Do
				If RowData.TheInterestAccrualScheduleIsEnteredManually Then
					Continue;
				EndIf;
				FixedAsset = RowData.FixedAsset;
				FASelectionStructure = New Structure("FixedAsset", FixedAsset);
				PercentageLines = CalculationParameters.InterestAccrualSchedule.FindRows(FASelectionStructure);
				For Each InterestLine In PercentageLines Do
					CalculationParameters.InterestAccrualSchedule.Delete(InterestLine);
				EndDo;
			EndDo;
		EndIf;
		
		Return;
		
	EndIf;
	
	For Each RowData In FATable Do
		
		FixedAsset = RowData.FixedAsset;
		FASelectionStructure = New Structure("FixedAsset", FixedAsset);

		If CalculationParameters.ShouldCalculatePercentage And Not RowData.TheInterestAccrualScheduleIsEnteredManually Then
			
			// The percentage lines for the calculated period must be deleted.
			AdjustmentSum = 0;
			ThisIsChangeOfConditions = TypeOf(CalculationParameters.Ref) = Type("DocumentRef.ChangeRentalTerms");
			StartDate = ?(Not ThisIsChangeOfConditions, BegOfDay(CalculationParameters.Date), EndOfMonth(CalculationParameters.Date) + 1);
			
			PercentageLines = CalculationParameters.InterestAccrualSchedule.FindRows(FASelectionStructure);
			For Each InterestLine In PercentageLines Do
				If InterestLine.Date >= StartDate Then
					CalculationParameters.InterestAccrualSchedule.Delete(InterestLine);
				EndIf;
			EndDo;
			
		EndIf;
		
		// Calculation of the rate of return
		If RowData.PresentValueFact > 0 Then
			FACost = RowData.PresentValueFact;
		Else
			FACost = RowData.PresentValue;
		EndIf;
		RentalPayments = RowData.RentalPayments;
		
		PaymentLinesByFA = CalculationParameters.ServicePaymentSchedule.FindRows(FASelectionStructure);
		
		If Not PaymentLinesByFA.Count() Then
			Cancel = True;
			If CalculationParameters.OutputMessages Then
				TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"" chưa điền lịch thanh toán. Sẽ không tính tỷ suất lợi nhuận';
									|ru = 'В строке %1 списка ""Основные средства"" не заполнен график оплат. Ставка доходности не будет рассчитана';
									|en = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list. The rate of return will not be calculated'; fa = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list. The rate of return will not be calculated';
									|it = 'В строке %1 списка ""Основные средства"" не заполнен график оплат. Ставка доходности не будет рассчитана';
									|pl = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list. The rate of return will not be calculated';
									|tr = '""Sabit kıymetler"" listesinin %1 satırında ödeme planı doldurulmadı. Getiri oranı hesaplanmayacaktır'");
				MessageText = StrTemplate(TextTemplate1, RowData.LineNumber);
				Field = CommonClientServer.PathToTabularSection("Object.FA", RowData.LineNumber, "ScheduleRef");
				Common.MessageToUser(MessageText,, Field);
			EndIf;
			Continue;
		EndIf;
		
		If RentalPayments < FACost Then
			Cancel = True;
			If CalculationParameters.OutputMessages Then
				TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", số tiền thanh toán tiền thuê không gồm thuế GTGT (%2) ít hơn giá trị đối tượng (%3). Sẽ tính tỷ suất lợi nhuận';
									|ru = 'В строке %1 списка ""Основные средства"" сумма арендных платежей без НДС (%2) меньше стоимости объекта (%3). Ставка доходности не будет рассчитана';
									|en = 'In line %1 of the ""Fixed assets"" list, the amount of rental payments excluding VAT (%2) is less than the object cost (%3). The rate of return will not be calculated'; fa = 'In line %1 of the ""Fixed assets"" list, the amount of rental payments excluding VAT (%2) is less than the object cost (%3). The rate of return will not be calculated';
									|it = 'В строке %1 списка ""Основные средства"" сумма арендных платежей без НДС (%2) меньше стоимости объекта (%3). Ставка доходности не будет рассчитана';
									|pl = 'In line %1 of the ""Fixed assets"" list, the amount of rental payments excluding VAT (%2) is less than the object cost (%3). The rate of return will not be calculated';
									|tr = '""Sabit kıymetler"" listesinin %1 satırında KDV hariç kira ödemelerinin tutarı (%2), nesnenin değerinden (%3) daha azdır. Getiri oranı hesaplanmayacaktır'");
				MessageText = StrTemplate(TextTemplate1, RowData.LineNumber, Format(RentalPayments, "NFD=2; NZ=0,00"), Format(FACost, "NFD=2; NZ=0,00"));
				Field = CommonClientServer.PathToTabularSection("Object.FA", RowData.LineNumber, "ScheduleRef");
				Common.MessageToUser(MessageText,, Field);
			EndIf;
			Continue;
		EndIf;
		
		ScheduleOfPayments.Clear();
			
		For Each PaymentLine_ In PaymentLinesByFA Do
			If PaymentLine_.Date >= BegOfDay(CalculationParameters.Date) Then
				PlotLine = ScheduleOfPayments.Add();
				PlotLine.Sum = PaymentLine_.RentalService - PaymentLine_.RentalServiceVAT;
				PlotLine.Date = PaymentLine_.Date;
			EndIf;
		EndDo;
		
		If Not ScheduleOfPayments.Count() Then
			Continue;
		EndIf;
		
		If RowData.NGLV > 0 Then
			If ValueIsFilled(RowData.RentalEndDate) Then
				PlotLine = ScheduleOfPayments.Add();
				PlotLine.Sum = RowData.NGLV;
				PlotLine.Date = RowData.RentalEndDate;
			Else
				PlotLine = ScheduleOfPayments[ScheduleOfPayments.Count()-1];
				PlotLine.Sum = PlotLine.Sum + RowData.NGLV;
			EndIf;
		EndIf;
		
		AddLastDayOfMonthToSchedule(ScheduleOfPayments, BegOfDay(CalculationParameters.Date));
		
		PlotLine = ScheduleOfPayments.Insert(0);
		PlotLine.Sum = -FACost;
		PlotLine.Date = BegOfDay(CalculationParameters.Date);
		
		ScheduleOfPayments.Sort("Date");
		
		Try
			RowData.RateOfReturn = InterestRate(ScheduleOfPayments);
		Except
			RowData.RateOfReturn = 0;
			If CalculationParameters.OutputMessages Then
				Cancel = True;
				TemplateText = NStr("vi = 'Không thể tính tỷ suất sinh lời theo đối tượng đang vận hành %1. Hãy kiểm tra lịch thanh toán và giá trị tài sản cố định. Hãy nhấn vào ô để diễn giải';
									|ru = 'Не удалось рассчитать ставку доходности по объекту эксплуатации %1. Проверьте график оплат и стоимость основных средств. Нажмите на ячейку для расшифровки';
									|en = 'Cannot calculate the rate of return on the %1 asset. Check the payment schedule and the fixed asset cost. Click the cell to drill down'; fa = 'Cannot calculate the rate of return on the %1 asset. Check the payment schedule and the fixed asset cost. Click the cell to drill down';
									|it = 'Не удалось рассчитать ставку доходности по объекту эксплуатации %1. Проверьте график оплат и стоимость основных средств. Нажмите на ячейку для расшифровки';
									|pl = 'Cannot calculate the rate of return on the %1 asset. Check the payment schedule and the fixed asset cost. Click the cell to drill down';
									|tr = '%1 varlığı üzerindeki getiri oranı hesaplanamadı. Ödeme planını ve sabit kıymetlerin maliyetini kontrol edin. Şifreyi çözmek için hücreye tıklayın'");
				MessageText = StrTemplate(TemplateText, RowData.FixedAssetPresentation);
				Field = CommonClientServer.PathToTabularSection("Object.FA", RowData.LineNumber, "RateOfReturn");
				Common.MessageToUser(MessageText,, Field);
			EndIf;
			Continue;
		EndTry;
		
		// Calculation of the interest schedule
		LoanBalance = FACost;
		RemainingInterest = RentalPayments - FACost;
		PreviousDate = BegOfDay(CalculationParameters.Date);
		
		RowData.SettlementDetails.Insert("InterestIncome", RemainingInterest);
		RowData.SettlementDetails.Insert("RentalPayments", RentalPayments - RowData.NGLV);
		RowData.SettlementDetails.Insert("PresentValue",
			RowData.PresentValue - RowData.NGLV);
		RowData.SettlementDetails.Insert("LocalAdvancePayment", RowData.AdvancePaymentsLocal);
		RowData.SettlementDetails.Insert("PresentValueLocal",
			RowData.SettlementDetails.TotalCHIA - RowData.AdvancePaymentsLocal - RowData.NonGuaranteedResidualValueLocal);
		RowData.SettlementDetails.Insert("RemainingInterest", RowData.RemainingInterest);
		RowData.SettlementDetails.Insert("InterestChange",
			RemainingInterest - RowData.RemainingInterest);
		
		If CalculationParameters.ShouldCalculatePercentage = False Or RowData.TheInterestAccrualScheduleIsEnteredManually Then
			RowData.PresentValue = FACost;
			Continue;
		EndIf;
		
		For Each PlotLine In ScheduleOfPayments Do
			
			If PlotLine.Sum < 0 Then
				Continue;
			EndIf;
			
			InterestAmount =
				LoanBalance
				* (Pow(1 + RowData.RateOfReturn / 100, (PlotLine.Date - PreviousDate) / 31536000) - 1);
			
			InterestAmount = Round(InterestAmount, 2);
			InterestAmount = Min(InterestAmount, RemainingInterest);
			InterestAmount = Max(InterestAmount, 0);
			
			RemainingInterest = RemainingInterest - InterestAmount;
			
			If InterestAmount > 0 Then
				
				If ThisIsChangeOfConditions And PlotLine.Date <= EndOfMonth(CalculationParameters.Date) Then
					AdjustmentSum = AdjustmentSum + InterestAmount;
					Continue;
				Else
					
					If AdjustmentSum <> 0 Then
						InterestAmount = InterestAmount + AdjustmentSum;
						AdjustmentSum = 0;
					EndIf;
					
					LinePercentages = CalculationParameters.InterestAccrualSchedule.Add();
					LinePercentages.Date = PlotLine.Date;
					LinePercentages.Interests = LinePercentages.Interests + InterestAmount;
					LinePercentages.FixedAsset = FixedAsset;
					
				EndIf;
				
				LoanBalance = Max(LoanBalance - PlotLine.Sum + InterestAmount, 0);
				
				// the rounding error is attributed to the last accrual
				If RemainingInterest > 0 And LoanBalance = 0 And LinePercentages <> Undefined Then
					LinePercentages.Interests = LinePercentages.Interests + RemainingInterest;
					RemainingInterest = 0;
				EndIf;
					
				PreviousDate = PlotLine.Date;
				
			EndIf;
			
		EndDo;
		
		If AdjustmentSum <> 0 And LinePercentages <> Undefined Then
			LinePercentages.Interests = LinePercentages.Interests + AdjustmentSum;
		EndIf;
		
	EndDo;
			
	CalculationParameters.Insert("FATable", FATable);

EndProcedure

// Parameters used to calculate the rate and interest.
// 
// Parameters:
// 	Object - DocumentObject - Document object.Transfer_2_4, document object.Change in the conditions of the transfer of the lease, Undetermined
// 	ContractDetails_ - Structure, Undefined - See AttributesOfCounterpartySContract
// 
// Returns:
//  Structure:
//		* Contract - CatalogRef.CounterpartyContracts -
//		* Organization - CatalogRef.Companies -
//		* Date - Date -
//		* Ref - DocumentRef.ProvideAssetsToLeasee2_4, DocumentRef.ChangeRentalTerms, Undefined -
//		* FA - ValueTable:
//			** FixedAsset - CatalogRef.Assets
//			** FairValueLocal - Number
//			** FairValueManag - Number
//			** RentalPayments - Number
//			** NonGuaranteedResidualValueLocal - Number
//			** NonGuaranteedResidualValueManag - Number
//			** AdvancePayments - Number
//			** AdvancePaymentsLocal - Number
//			** SecurityDepositValue - Number
//			** TheInterestAccrualScheduleIsEnteredManually - Boolean
//		* ServicePaymentSchedule - ValueTable:
//			** FixedAsset - CatalogRef.Assets
//			** Date - Date
//			** RentalService - Number
//			** RentalServiceVAT - Number
//		* ContractDetails_ - Structure:
//			** ContractType - EnumRef.ContractTypes - 
//			** ARAPCurrency - CatalogRef.Currencies - 
//			** VATRate - CatalogRef.VATRates - 
//			** LeaseContracts - CatalogRef.LeaseContract
//		* LocalAccountingCurrency - CatalogRef.Currencies -
//		* ManagementAccountingCurrency - CatalogRef.Currencies -
//		* AmountOfAdvancePaymentsLocal - Number -
//		* ThisIsChangeOfConditions - Boolean -
//		* ShouldCalculatePercentage - Boolean -
//		* OutputMessages - Boolean -
//		* InterestAccrualSchedule - ValueTable:
//			** FixedAsset - CatalogRef.Assets
//			** Date - Date
//			** Interests - Number
//		* FATable - ValueTable:
//			** FixedAsset - CatalogRef.Assets
//			** FairValueLocal - Number
//			** FairValueManag - Number
//			** RentalPayments - Number
//			** NonGuaranteedResidualValueLocal - Number
//			** NonGuaranteedResidualValueManag - Number
//			** AdvancePayments - Number
//			** AdvancePaymentsLocal - Number
//			** SecurityDepositValue - Number
//			** TheInterestAccrualScheduleIsEnteredManually - Boolean
//
Function ParametersForCalculatingInterestRatesOfProfitableLeases(Object = Undefined, ContractDetails_ = Undefined) Export
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	CalculationParameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	CalculationParameters.Insert("Date", '00010101');
	CalculationParameters.Insert("Ref", Undefined);
	CalculationParameters.Insert("FA", New ValueTable);
	CalculationParameters.Insert("ServicePaymentSchedule", New ValueTable);
	CalculationParameters.Insert("ContractDetails_", New Structure);
	CalculationParameters.Insert("LocalAccountingCurrency", Catalogs.Currencies.EmptyRef());
	CalculationParameters.Insert("ManagementAccountingCurrency", Catalogs.Currencies.EmptyRef());
	CalculationParameters.Insert("AmountOfAdvancePaymentsLocal", 0);
	CalculationParameters.Insert("ThisIsChangeOfConditions", False);
	CalculationParameters.Insert("ShouldCalculatePercentage", True);
	CalculationParameters.Insert("OutputMessages", True);
	
	// Output parameter
	CalculationParameters.Insert("InterestAccrualSchedule", New ValueTable);
	CalculationParameters.Insert("FATable", New ValueTable);

	If Object <> Undefined Then
		If ContractDetails_ <> Undefined Then
			CalculationParameters.ContractDetails_ = ContractDetails_;
		EndIf;
		FillPropertyValues(CalculationParameters, Object);
		CalculationParameters.FA = Object.FA.Unload();
		CalculationParameters.ServicePaymentSchedule = Object.ServicePaymentSchedule.Unload();
		CalculationParameters.ServicePaymentSchedule.Indexes.Add("FixedAsset");
		CalculationParameters.InterestAccrualSchedule = Object.InterestAccrualSchedule.Unload();
		CalculationParameters.InterestAccrualSchedule.Indexes.Add("FixedAsset");
		CalculationParameters.LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		If Not ValueIsFilled(CalculationParameters.Date) Then 
			CalculationParameters.Date = CurrentSessionDate();
		EndIf;
		If TypeOf(Object.Ref) <> Type("DocumentRef.ProvideAssetsToLeasee2_4") Then
			CalculationParameters.FA.Columns.Add("FairValueLocal", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative));
			CalculationParameters.FA.Columns.Add("FairValueManag", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative));
			CalculationParameters.FA.Columns.Add("AdvancePayments", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative));
			CalculationParameters.FA.Columns.Add("AdvancePaymentsLocal", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative));
		EndIf;
	EndIf;
	CalculationParameters.ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	
	Return CalculationParameters;
	
EndFunction

// Generates a payment schedule that can be used for discounting.
// 
// Parameters:
//  ScheduleOfPayments - ValueTable - Payment schedule for services.
//  BeginOfPeriod - Date - Beginning of the period
// 
Procedure AddLastDayOfMonthToSchedule(ScheduleOfPayments, BeginOfPeriod) Export
	
	ScheduleOfPayments.Sort("Date");
	
	// Adding the last day of the month to the schedule, if there is no one.
	CurrentMonth = BegOfMonth(BeginOfPeriod);
	LastMonth_1 = ScheduleOfPayments[ScheduleOfPayments.Count() - 1].Date;
	While CurrentMonth <= LastMonth_1 Do
		ScheduleDate = BegOfDay(EndOfMonth(CurrentMonth));
		If ScheduleOfPayments.Find(ScheduleDate, "Date") = Undefined Then
			PlotLine = ScheduleOfPayments.Add();
			PlotLine.Date = ScheduleDate;
		EndIf;
		CurrentMonth = AddMonth(CurrentMonth, 1);
	EndDo;
	
	ScheduleOfPayments.Sort("Date");
	
EndProcedure

// Checking the completion of rental income schedules.
// 
// Parameters:
//  Object - DocumentObject.ProvideAssetsToLeasee2_4, DocumentObject.ChangeRentalTerms -
//  Cancel - Boolean -
//
Procedure CheckRentalIncomeSchedules(Object, Cancel) Export
	
	FATable = Object.FA.Unload();
	ServicePaymentSchedule = Object.ServicePaymentSchedule;
	ServiceAccrualSchedule = Object.ServiceAccrualSchedule;
	LeaseStartDate = BegOfDay(Object.Date);
	ThisIsTransferForRent = TypeOf(Object.Ref) = Type("DocumentRef.ProvideAssetsToLeasee2_4");
	ThisIsChangeOfConditions = TypeOf(Object.Ref) = Type("DocumentRef.ChangeRentalTerms");
	ThisIsInputOfResiduals = TypeOf(Object.Ref) = Type("DocumentRef.EnterRentalInvestmentBalance");
	ThereAreAdvances = ThisIsTransferForRent And Object.AmountOfAdvancePayments > 0;
	
	If Not ThisIsTransferForRent Then
		FATable.Columns.Add(
			"AdvancePayments", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative));
	EndIf;
	
	If ThisIsChangeOfConditions Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	FATable.FixedAsset AS FixedAsset,
		|	FATable.LineNumber AS LineNumber
		|INTO FATable
		|FROM
		|	&FATable AS FATable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProvideAssetsToLeasee2_4FA.FixedAsset AS FixedAsset,
		|	SUM(ProvideAssetsToLeasee2_4FA.AdvancePayments) AS AdvancePayments
		|INTO Prepayments
		|FROM
		|	Document.ProvideAssetsToLeasee2_4.FA AS ProvideAssetsToLeasee2_4FA
		|WHERE
		|	ProvideAssetsToLeasee2_4FA.Ref.Contract = &Contract
		|	AND ProvideAssetsToLeasee2_4FA.Ref.Posted
		|	AND ProvideAssetsToLeasee2_4FA.FixedAsset IN
		|			(SELECT
		|				FATable.FixedAsset AS FixedAsset
		|			FROM
		|				FATable AS FATable)
		|
		|GROUP BY
		|	ProvideAssetsToLeasee2_4FA.FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FATable.LineNumber AS LineNumber,
		|	FATable.FixedAsset AS FixedAsset,
		|	ISNULL(Prepayments.AdvancePayments, 0) AS AdvancePayments
		|FROM
		|	FATable AS FATable
		|		LEFT JOIN Prepayments AS Prepayments
		|		ON FATable.FixedAsset = Prepayments.FixedAsset
		|
		|ORDER BY
		|	LineNumber";
		
		Query.SetParameter("FATable", FATable);
		Query.SetParameter("Contract", Object.Contract);
		
		FATable = Query.Execute().Unload();
		
	EndIf;
	
	For Each FAString In FATable Do
		
		ThereArePayments = False;
		ThereAreAccruals = False;
		AmountOfPayments = 0;
		AmountOfCharges = 0;
		AmountOfVATPayments = 0;
		AmountOfVATAccruals = 0;
		AmountOfPaymentsBeforeChange = 0;
		AmountOfAccrualsBeforeChange = 0;
		AmountOfVATPaymentsBeforeChange = 0;
		AmountOfVATAccrualsBeforeChange = 0;
		AdvanceAmount = FAString.AdvancePayments;
		
		PaymentLinesFound
			= ServicePaymentSchedule.FindRows(New Structure("FixedAsset", FAString.FixedAsset));
		
		For Each PaymentLine_ In PaymentLinesFound Do
			ThereArePayments = True;
			If PaymentLine_.Date < LeaseStartDate Then
				If ThisIsChangeOfConditions Then
					AmountOfPaymentsBeforeChange = AmountOfPaymentsBeforeChange + PaymentLine_.RentalService;
					AmountOfVATPaymentsBeforeChange = AmountOfVATPaymentsBeforeChange + PaymentLine_.RentalServiceVAT;
				Else
					TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"" trong lịch thanh toán, không cần dòng có ngày nhỏ hơn ngày bắt đầu thuê (%2)';
										|ru = 'В строке %1 списка ""Основные средства"" в графике оплат не должно быть строк с датой меньше, чем дата начала аренды (%2)';
										|en = 'Line %1 of the ""Fixed assets"" list in the payment schedule must contain no lines with a date earlier than the rental start date (%2)'; fa = 'Line %1 of the ""Fixed assets"" list in the payment schedule must contain no lines with a date earlier than the rental start date (%2)';
										|it = 'В строке %1 списка ""Основные средства"" в графике оплат не должно быть строк с датой меньше, чем дата начала аренды (%2)';
										|pl = 'Line %1 of the ""Fixed assets"" list in the payment schedule must contain no lines with a date earlier than the rental start date (%2)';
										|tr = 'Ödeme planındaki ""Sabit kıymetler"" listesinin %1 satırında, tarihi kiralamanın başlangıç tarihinden (%2) önce olan satırlar olmamalıdır'");
					MessageText = StrTemplate(TextTemplate1, FAString.LineNumber, Format(LeaseStartDate, "DLF=D"));
					Field = CommonClientServer.PathToTabularSection("Object.FA", FAString.LineNumber, "ScheduleRef");
					Common.MessageToUser(MessageText,, Field,, Cancel);
					Continue;
				EndIf;
			Else
				AmountOfPayments = AmountOfPayments + PaymentLine_.RentalService;
				AmountOfVATPayments = AmountOfVATPayments + PaymentLine_.RentalServiceVAT;
			EndIf;
		EndDo;
		
		If Cancel Then
			Continue;
		EndIf;
			
		If Not ThisIsInputOfResiduals And Not ThereArePayments Then
			TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", chưa điền lịch biểu thanh toán';
								|ru = 'В строке %1 списка ""Основные средства"" не заполнен график оплат';
								|en = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list'; fa = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list';
								|it = 'В строке %1 списка ""Основные средства"" не заполнен график оплат';
								|pl = 'The payment schedule is not filled in line %1 of the ""Fixed assets"" list';
								|tr = '""Sabit kıymetler"" listesinin %1 satırında ödeme planı doldurulmadı'");
			MessageText = StrTemplate(TextTemplate1, FAString.LineNumber);
			Field = CommonClientServer.PathToTabularSection("Object.FA", FAString.LineNumber, "ScheduleRef");
			Common.MessageToUser(MessageText,, Field,, Cancel);
			Continue;
		EndIf;
		
		AccrualLinesFound
			= ServiceAccrualSchedule.FindRows(New Structure("FixedAsset", FAString.FixedAsset));
		
		For Each AccrualLine In AccrualLinesFound Do
			ThereAreAccruals = True;
			If AccrualLine.Date < LeaseStartDate Then
				If ThisIsChangeOfConditions Then
					AmountOfAccrualsBeforeChange = AmountOfAccrualsBeforeChange + AccrualLine.RentalService;
					AmountOfVATAccrualsBeforeChange = AmountOfVATAccrualsBeforeChange + AccrualLine.RentalServiceVAT;
				Else
					TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"" trong lịch tính toán, không cần dòng có ngày nhỏ hơn ngày bắt đầu thuê (%2)';
										|ru = 'В строке %1 списка ""Основные средства"" в графике начислений не должно быть строк с датой меньше, чем дата начала аренды (%2)';
										|en = 'Line %1 of the ""Fixed assets"" list in the charge schedule must contain no lines with a date earlier than the rental start date (%2)'; fa = 'Line %1 of the ""Fixed assets"" list in the charge schedule must contain no lines with a date earlier than the rental start date (%2)';
										|it = 'В строке %1 списка ""Основные средства"" в графике начислений не должно быть строк с датой меньше, чем дата начала аренды (%2)';
										|pl = 'Line %1 of the ""Fixed assets"" list in the charge schedule must contain no lines with a date earlier than the rental start date (%2)';
										|tr = 'Tahakkuk planındaki ""Sabit kıymetler"" listesinin %1 satırında, tarihi kiralamanın başlangıç tarihinden (%2) önce olan satırlar olmamalıdır'");
					MessageText = StrTemplate(TextTemplate1, FAString.LineNumber, Format(LeaseStartDate, "DLF=D"));
					Field = CommonClientServer.PathToTabularSection("Object.FA", FAString.LineNumber, "ScheduleRef");
					Common.MessageToUser(MessageText,, Field,, Cancel);
					Continue;
				EndIf;
			Else
				AmountOfCharges = AmountOfCharges + AccrualLine.RentalService;
				AmountOfVATAccruals = AmountOfVATAccruals + AccrualLine.RentalServiceVAT;
			EndIf;
		EndDo;
		
		If Cancel Then
			Continue;
		EndIf;
		
		If Not ThisIsInputOfResiduals And Not ThereAreAccruals Then
			TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", chưa điền lịch biểu tính toán';
								|ru = 'В строке %1 списка ""Основные средства"" не заполнен график начислений';
								|en = 'The charge schedule is not filled in line %1 of the ""Fixed assets"" list'; fa = 'The charge schedule is not filled in line %1 of the ""Fixed assets"" list';
								|it = 'В строке %1 списка ""Основные средства"" не заполнен график начислений';
								|pl = 'The charge schedule is not filled in line %1 of the ""Fixed assets"" list';
								|tr = '""Sabit kıymetler"" listesinin %1 satırında tahakkuk planı doldurulmadı'");
			MessageText = StrTemplate(TextTemplate1, FAString.LineNumber);
			Field = CommonClientServer.PathToTabularSection("Object.FA", FAString.LineNumber, "ScheduleRef");
			Common.MessageToUser(MessageText,, Field,, Cancel);
			Continue;
		EndIf;
		
		If ThisIsChangeOfConditions And AdvanceAmount = 0 And AmountOfPaymentsBeforeChange <> AmountOfAccrualsBeforeChange Then
			Balance = AmountOfPaymentsBeforeChange - AmountOfAccrualsBeforeChange;
			AmountOfCharges = AmountOfCharges - Balance;
		EndIf;
		
		If Not ThisIsInputOfResiduals And Not ThereAreAdvances And AdvanceAmount = 0 And AmountOfPayments <> AmountOfCharges Then
			TextTemplate1 = NStr("vi = 'Trong dòng %1của danh sách ""Tài sản cố định"", số tiền dịch vụ theo lịch biểu thanh toán (%2) không bằng với số tiền dịch vụ theo lịch biểu tính toán (%3)';
								|ru = 'В строке %1 списка ""Основные средства"" сумма услуг по графику оплат (%2) не равна сумме услуг по графику начислений (%3)';
								|en = 'In line %1 of the ""Fixed assets"" list, the amount of services by payment schedule (%2) is not equal to the amount of services by charge schedule (%3)'; fa = 'In line %1 of the ""Fixed assets"" list, the amount of services by payment schedule (%2) is not equal to the amount of services by charge schedule (%3)';
								|it = 'В строке %1 списка ""Основные средства"" сумма услуг по графику оплат (%2) не равна сумме услуг по графику начислений (%3)';
								|pl = 'In line %1 of the ""Fixed assets"" list, the amount of services by payment schedule (%2) is not equal to the amount of services by charge schedule (%3)';
								|tr = '""Sabit kıymetler"" listesinin %1 satırında, ödeme planına göre hizmetlerin toplamı (%2), tahakkuk planına göre hizmetlerin toplamına eşit değildir (%3)'");
			MessageText =
				StrTemplate(TextTemplate1, FAString.LineNumber, Format(AmountOfPayments, "NFD=2"), Format(AmountOfCharges, "NFD=2"));
			Field = CommonClientServer.PathToTabularSection("Object.FA", FAString.LineNumber, "ScheduleRef");
			If ThisIsChangeOfConditions Then
				Common.MessageToUser(MessageText,, Field);
			Else
				Common.MessageToUser(MessageText,, Field,, Cancel);
				Continue;
			EndIf;
		EndIf;
		
		If ThisIsChangeOfConditions And AdvanceAmount = 0 And AmountOfVATPaymentsBeforeChange <> AmountOfVATAccrualsBeforeChange Then
			Balance = AmountOfVATPaymentsBeforeChange - AmountOfVATAccrualsBeforeChange;
			AmountOfVATAccruals = AmountOfVATAccruals - Balance;
		EndIf;
		
		If Not ThisIsInputOfResiduals And Not ThereAreAdvances And AdvanceAmount = 0 And AmountOfVATPayments <> AmountOfVATAccruals Then
			TextTemplate1 = NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", số tiền thuế GTGT theo lịch thanh toán (%2) không bằng số tiền thuế GTGT theo lịch tính toán (%3)';
								|ru = 'В строке %1 списка ""Основные средства"" сумма НДС по графику оплат (%2) не равна сумме НДС по графику начислений (%3)';
								|en = 'In line %1 of the ""Fixed assets"" list, the VAT amount by payment schedule (%2) is not equal to the VAT amount by charge schedule (%3)'; fa = 'In line %1 of the ""Fixed assets"" list, the VAT amount by payment schedule (%2) is not equal to the VAT amount by charge schedule (%3)';
								|it = 'В строке %1 списка ""Основные средства"" сумма НДС по графику оплат (%2) не равна сумме НДС по графику начислений (%3)';
								|pl = 'In line %1 of the ""Fixed assets"" list, the VAT amount by payment schedule (%2) is not equal to the VAT amount by charge schedule (%3)';
								|tr = '""Sabit kıymetler"" listesinin %1 satırında ödeme planına göre KDV tutarı (%2) tahakkuk planına göre KDV tutarına (%3) eşit değildir'");
			MessageText =
				StrTemplate(TextTemplate1, FAString.LineNumber, Format(AmountOfVATPayments, "NFD=2"), Format(AmountOfVATAccruals, "NFD=2"));
			Field = CommonClientServer.PathToTabularSection("Object.FA", FAString.LineNumber, "ScheduleRef");
			If ThisIsChangeOfConditions Then
				Common.MessageToUser(MessageText,, Field);
			Else
				Common.MessageToUser(MessageText,, Field,, Cancel);
				Continue;
			EndIf;
		EndIf;
		
		If ThisIsChangeOfConditions And AdvanceAmount <> 0 Then
			AmountOfFAPaymentsTotalExcludingVAT = AmountOfPaymentsBeforeChange - AmountOfVATPaymentsBeforeChange + AmountOfPayments - AmountOfVATPayments;
			AccrualAmountOfFATotalExcludingVAT = AmountOfAccrualsBeforeChange - AmountOfVATAccrualsBeforeChange
				+ AmountOfCharges - AmountOfVATAccruals;
			DifferenceBetweenAccrualsAndPayments = AccrualAmountOfFATotalExcludingVAT - AmountOfFAPaymentsTotalExcludingVAT;
			If DifferenceBetweenAccrualsAndPayments <> AdvanceAmount Then
				TextTemplate1 = NStr(
					"vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", chênh lệch giữa số tiền tính toán chung không gồm thuế GTGT trong toàn kỳ thuê (%2) không bằng số tiền tạm ứng theo TSCĐ (%3) từ chứng từ chuyển cho thuê';
					|ru = 'В строке %1 списка ""Основные средства"" разница между общей суммой начислений и оплат без НДС за весь период аренды (%2) не равна сумме аванса по ОС (%3) из документа передачи в аренду';
					|en = 'In line %1 of the ""Fixed assets"" list, the difference between the total amount of charges and payments excluding VAT for the entire rental period (%2) is not equal to the FA prepayment amount (%3) from the rental document'; fa = 'In line %1 of the ""Fixed assets"" list, the difference between the total amount of charges and payments excluding VAT for the entire rental period (%2) is not equal to the FA prepayment amount (%3) from the rental document';
					|it = 'В строке %1 списка ""Основные средства"" разница между общей суммой начислений и оплат без НДС за весь период аренды (%2) не равна сумме аванса по ОС (%3) из документа передачи в аренду';
					|pl = 'In line %1 of the ""Fixed assets"" list, the difference between the total amount of charges and payments excluding VAT for the entire rental period (%2) is not equal to the FA prepayment amount (%3) from the rental document';
					|tr = '""Sabit kıymetler"" listesinin %1 satırında, tüm kiralama dönemi için KDV hariç tahakkuk ve ödemelerin toplam tutarı (%2) arasındaki fark, kira devri belgesindeki sabit kıymetler için ön ödeme ödeme tutarına (%3) eşit değildir'");
				MessageText = StrTemplate(
					TextTemplate1,
					FAString.LineNumber,
					Format(DifferenceBetweenAccrualsAndPayments, "NFD=2; NZ=0,00"),
					Format(AdvanceAmount, "NFD=2"));
				Field = CommonClientServer.PathToTabularSection("Object.FA", FAString.LineNumber, "ScheduleRef");
				Common.MessageToUser(MessageText,, Field);
			EndIf;
		EndIf;
		
	EndDo;
	
	If Not Cancel And ThereAreAdvances Then
		
		TotalAmountOfPayments = Object.ServicePaymentSchedule.Total("RentalService")
			- Object.ServicePaymentSchedule.Total("RentalServiceVAT")
			+ Object.AmountOfAdvancePayments;
		AmountOfAccrualsTotal = Object.ServiceAccrualSchedule.Total("RentalService")
			- Object.ServiceAccrualSchedule.Total("RentalServiceVAT");
			
		If TotalAmountOfPayments <> AmountOfAccrualsTotal Then
			TextTemplate1 = NStr("vi = 'Số tiền thanh toán chung và thanh toán tạm ứng không gồm thuế GTGT (%1) không bằng số tiền tính toán chung không gồm thuế GTGT theo lịch (%2)';
								|ru = 'Общая сумма оплат и авансовых платежей без НДС (%1) не равна общей сумме начислений без НДС по графику (%2)';
								|en = 'The total amount of payments and prepayments excluding VAT (%1) is not equal to the total amount of charges excluding VAT as scheduled (%2)'; fa = 'The total amount of payments and prepayments excluding VAT (%1) is not equal to the total amount of charges excluding VAT as scheduled (%2)';
								|it = 'Общая сумма оплат и авансовых платежей без НДС (%1) не равна общей сумме начислений без НДС по графику (%2)';
								|pl = 'The total amount of payments and prepayments excluding VAT (%1) is not equal to the total amount of charges excluding VAT as scheduled (%2)';
								|tr = 'KDV hariç ödemelerin ve avansların toplam tutarı (%1) plan kapsamındaki KDV hariç tahakkukların toplam tutarına eşit değildir (%2)'");
			MessageText =
				StrTemplate(TextTemplate1, Format(TotalAmountOfPayments, "NFD=2"), Format(AmountOfAccrualsTotal, "NFD=2"));
			Field = "Object.AmountOfAdvancePayments";
			If ThisIsChangeOfConditions Then
				Common.MessageToUser(MessageText,, Field);
			Else
				Common.MessageToUser(MessageText,, Field,, Cancel);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Deletes irrelevant lines of rental income charts in the document.
// 
// Parameters:
//  Object - DocumentObject.ProvideAssetsToLeasee2_4, DocumentObject.ChangeRentalTerms -
//
Procedure DeleteIrrelevantGraphLines(Object) Export
	Query = New Query;
	Query.SetParameter("FAArray", Object.FA.Unload().UnloadColumn("FixedAsset"));
	Query.SetParameter("ServicePaymentSchedule", Object.ServicePaymentSchedule.Unload());
	Query.SetParameter("ServiceAccrualSchedule", Object.ServiceAccrualSchedule.Unload());
	Query.SetParameter("InterestAccrualSchedule", Object.ServiceAccrualSchedule.Unload());
	
	Query.Text =
		"SELECT
		|	ServicePaymentSchedule.FixedAsset AS FixedAsset
		|INTO TTFAPaymentSchedule
		|FROM
		|	&ServicePaymentSchedule AS ServicePaymentSchedule
		|WHERE
		|	NOT ServicePaymentSchedule.FixedAsset IN (&FAArray)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ServiceAccrualSchedule.FixedAsset AS FixedAsset
		|INTO TTFAOfAccrualSchedule
		|FROM
		|	&ServiceAccrualSchedule AS ServiceAccrualSchedule
		|WHERE
		|	NOT ServiceAccrualSchedule.FixedAsset IN (&FAArray)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InterestAccrualSchedule.FixedAsset AS FixedAsset
		|INTO TTFAPercentageChart
		|FROM
		|	&InterestAccrualSchedule AS InterestAccrualSchedule
		|WHERE
		|	NOT InterestAccrualSchedule.FixedAsset IN (&FAArray)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTFAPaymentSchedule.FixedAsset AS FixedAsset
		|FROM
		|	TTFAPaymentSchedule AS TTFAPaymentSchedule
		|GROUP BY
		|	TTFAPaymentSchedule.FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTFAPercentageChart.FixedAsset AS FixedAsset
		|FROM
		|	TTFAPercentageChart AS TTFAPercentageChart
		|GROUP BY
		|	TTFAPercentageChart.FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTFAOfAccrualSchedule.FixedAsset AS FixedAsset
		|FROM
		|	TTFAOfAccrualSchedule AS TTFAOfAccrualSchedule
		|GROUP BY
		|	TTFAOfAccrualSchedule.FixedAsset";
	
	QueryResults = Query.ExecuteBatch();
	
	FilterStructure1 = New Structure("FixedAsset");
	
	PaymentResult = QueryResults[QueryResults.UBound()-2];
	If Not PaymentResult.IsEmpty() Then
		Selection = PaymentResult.Select();
		While Selection.Next() Do
			FilterStructure1.FixedAsset = Selection.FixedAsset;
			FoundGraphLines = Object.ServicePaymentSchedule.FindRows(FilterStructure1);
			For Each PlotLine In FoundGraphLines Do
				Object.ServicePaymentSchedule.Delete(PlotLine);
			EndDo;
		EndDo;
	EndIf;
	
	AccrualResult = QueryResults[QueryResults.UBound()-1];
	If Not AccrualResult.IsEmpty() Then
		Selection = AccrualResult.Select();
		While Selection.Next() Do
			FilterStructure1.FixedAsset = Selection.FixedAsset;
			FoundGraphLines = Object.ServiceAccrualSchedule.FindRows(FilterStructure1);
			For Each PlotLine In FoundGraphLines Do
				Object.ServiceAccrualSchedule.Delete(PlotLine);
			EndDo;
		EndDo;
	EndIf;
	
	ResultPercentages = QueryResults[QueryResults.UBound()];
	If Not ResultPercentages.IsEmpty() Then
		Selection = ResultPercentages.Select();
		While Selection.Next() Do
			FilterStructure1.FixedAsset = Selection.FixedAsset;
			FoundGraphLines = Object.InterestAccrualSchedule.FindRows(FilterStructure1);
			For Each PlotLine In FoundGraphLines Do
				Object.InterestAccrualSchedule.Delete(PlotLine);
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

// Allows you to determine whether there are fixed assets subleased in the tabular part of the document.
//  When duplicates are found, it generates messages to the user.
//
// Parameters:
//  Object - DocumentObject - Document.
//  Cancel - Boolean - Indicates that further processing was refused.
//  FilterByActions - Boolean
//
Procedure CheckReturnFromSublease(Object, Cancel, FilterByActions = False) Export
	
	If Not GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AssetsLeasedOutSliceLast.Recorder AS Recorder,
	|	AssetsLeasedOutSliceLast.FixedAsset AS FixedAsset,
	|	AssetsLeasedOutSliceLast.Contract AS Contract
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND FixedAsset IN (&ListOfFA)) AS AssetsLeasedOutSliceLast
	|WHERE
	|	AssetsLeasedOutSliceLast.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND AssetsLeasedOutSliceLast.Contract.ContractType IN (&TypesOfContractsUnderFSB25)
	|";
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	Query.SetParameter("ListOfFA", Object.FA.UnloadColumn("FixedAsset"));
	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
	
		RentedOut = Result.Unload();
		RentedOut.Indexes.Add("FixedAsset");
	
		MessageTemplate = NStr("vi = 'Tài sản cố định ""%1"" được chuyển cho thuê lại theo hợp đồng %2, chứng từ chuyển cho thuê %3.
								|Trước khi ngừng thuê TSCĐ, cần trả lại nó từ đã thuê lại.';
								|ru = 'Основное средство ""%1"" передано в субаренду по договору %2, документ передачи в аренду %3.
								|Перед прекращением аренды ОС его нужно вернуть из субаренды.';
								|en = 'The ""%1"" fixed asset is subleased under the %2 contract, the %3 rental document.
								|Before you terminate the fixed asset lease, return it from sublease.'; fa = 'The ""%1"" fixed asset is subleased under the %2 contract, the %3 rental document.
								|Before you terminate the fixed asset lease, return it from sublease.';
								|it = 'Основное средство ""%1"" передано в субаренду по договору %2, документ передачи в аренду %3.
								|Перед прекращением аренды ОС его нужно вернуть из субаренды.';
								|pl = 'The ""%1"" fixed asset is subleased under the %2 contract, the %3 rental document.
								|Before you terminate the fixed asset lease, return it from sublease.';
								|tr = 'Sabit kıymet ""%1"", %3 kira devri belgesi olan %2sözleşmesi kapsamında alt kiralamaya verilmiştir.
								|Sabit kıymetin kiralanması sonlandırılmadan önce, alt kiralamadan iade edilmelidir.'"); 

		For Each RowData In Object.FA Do
			
			If FilterByActions 
				And RowData.ActionWithRentalObject <> Enums.ActionsWithRentalObjects.EarlyRedemption
				And RowData.ActionWithRentalObject <> Enums.ActionsWithRentalObjects.RentalTermination Then
				Continue;
			EndIf;
			
			RentalData = RentedOut.FindRows(New Structure("FixedAsset", RowData.FixedAsset));
			
			If RentalData.Count() > 0 Then
				MessageText = StrTemplate(MessageTemplate,
					RowData.FixedAsset,
					RentalData[0].Contract,
					RentalData[0].Recorder);
				Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
				Common.MessageToUser(MessageText, Object, Field, "", Cancel);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure RegisterCalculationExecutionProblem(Operation, Period, Organization, IssueDetails, ProblemGroup = "", Object = Undefined, Cancel = False) Export

	Cancel = True;
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
		Operation,
		Organization,
		BegOfMonth(Period));
		
	If Not ValueIsFilled(ProblemGroup) Then
		ProblemGroup = NStr("vi = 'Khi thực hiện thao tác, đã ghi nhận lỗi';
							|ru = 'При выполнении операции зарегистрированы ошибки';
							|en = 'Errors are registered while executing the operation:'; fa = 'Errors are registered while executing the operation:';
							|it = 'При выполнении операции зарегистрированы ошибки';
							|pl = 'Errors are registered while executing the operation:';
							|tr = 'İşlemin gerçekleştirilmesi sırasında hatalar kaydedildi'", Common.DefaultLanguageCode());
	EndIf;
		
	MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
		RegistrationParameters,
		ProblemGroup,
		Enums.AccountingIssueSeverity.Error,
		IssueDetails,
		Object);
	
EndProcedure

// Supplements the schedule of payments and accruals under the previous terms of the Transfer Contract for lease
// 
// Parameters:
// RowData - Structure
// ServicePaymentSchedule - DocumentTabularSection.ChangeRentalTerms.ServicePaymentSchedule
// ServiceAccrualSchedule - DocumentTabularSection.ChangeRentalTerms.ServiceAccrualSchedule
// Contract - CatalogRef.CounterpartyContracts
//
Procedure ToSupplementScheduleOfPaymentsAndAccrualsOfIncomeRentUnderPreviousConditions(RowData, ServicePaymentSchedule, ServiceAccrualSchedule, Contract) Export
	
	FixedAsset = RowData.FixedAsset;
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	StartDate = RowData.LeaseStartDate;
	
	Query = New Query;
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("FAArray", FixedAsset);
	Query.SetParameter("Date", BegOfDay(StartDate));
	
	Query.Text = 
	"SELECT
	|	PaymentSchedule.FixedAsset AS FixedAsset,
	|	PaymentSchedule.Date AS Date,
	|	PaymentSchedule.RentalService AS RentalService,
	|	PaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	PaymentSchedule.ChangeDate AS ChangeDate
	|INTO TTPaymentsSchedule
	|FROM
	|	InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS PaymentSchedule
	|WHERE
	|	PaymentSchedule.Contract = &Contract
	|	AND PaymentSchedule.FixedAsset IN (&FAArray)
	|	AND PaymentSchedule.Date < &Date
	|	AND PaymentSchedule.ChangeDate < &Date
	|	AND PaymentSchedule.Active
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentsSchedule.FixedAsset AS FixedAsset,
	|	MAX(TTPaymentsSchedule.ChangeDate) AS ChangeDate
	|INTO TTPaymentSchedulePeriod
	|FROM
	|	TTPaymentsSchedule AS TTPaymentsSchedule
	|
	|GROUP BY
	|	TTPaymentsSchedule.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfAccrual.FixedAsset AS FixedAsset,
	|	ScheduleOfAccrual.Date AS Date,
	|	ScheduleOfAccrual.RentalService AS RentalService,
	|	ScheduleOfAccrual.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleOfAccrual.ChangeDate AS ChangeDate
	|INTO TTAccrualSchedule
	|FROM
	|	InformationRegister.ScheduleOfChargesForIncomeRentalServices AS ScheduleOfAccrual
	|WHERE
	|	ScheduleOfAccrual.Contract = &Contract
	|	AND ScheduleOfAccrual.FixedAsset IN (&FAArray)
	|	AND ScheduleOfAccrual.Date < &Date
	|	AND ScheduleOfAccrual.ChangeDate < &Date
	|	AND ScheduleOfAccrual.Active
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccrualSchedule.FixedAsset AS FixedAsset,
	|	MAX(TTAccrualSchedule.ChangeDate) AS ChangeDate
	|INTO AccrualScheduleIsTTForPeriod
	|FROM
	|	TTAccrualSchedule AS TTAccrualSchedule
	|
	|GROUP BY
	|	TTAccrualSchedule.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentsSchedule.FixedAsset AS FixedAsset,
	|	TTPaymentsSchedule.Date AS Date,
	|	TTPaymentsSchedule.RentalService AS RentalService,
	|	TTPaymentsSchedule.RentalServiceVAT AS RentalServiceVAT
	|FROM
	|	TTPaymentsSchedule AS TTPaymentsSchedule
	|		INNER JOIN TTPaymentSchedulePeriod AS TTPaymentSchedulePeriod
	|		ON TTPaymentsSchedule.FixedAsset = TTPaymentSchedulePeriod.FixedAsset
	|			AND TTPaymentsSchedule.ChangeDate = TTPaymentSchedulePeriod.ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccrualSchedule.FixedAsset AS FixedAsset,
	|	TTAccrualSchedule.Date AS Date,
	|	TTAccrualSchedule.RentalService AS RentalService,
	|	TTAccrualSchedule.RentalServiceVAT AS RentalServiceVAT
	|FROM
	|	TTAccrualSchedule AS TTAccrualSchedule
	|		INNER JOIN AccrualScheduleIsTTForPeriod AS AccrualScheduleIsTTForPeriod
	|		ON TTAccrualSchedule.FixedAsset = AccrualScheduleIsTTForPeriod.FixedAsset
	|			AND TTAccrualSchedule.ChangeDate = AccrualScheduleIsTTForPeriod.ChangeDate";
	
	QueryResults = Query.ExecuteBatch();
	
	PaymentResult = QueryResults[QueryResults.UBound() - 1];
	If Not PaymentResult.IsEmpty() Then
		Selection = PaymentResult.Select();
		While Selection.Next() Do
			PlotLine = ServicePaymentSchedule.Add();
			FillPropertyValues(PlotLine, Selection);
		EndDo;
	EndIf;
	
	AccrualResult = QueryResults[QueryResults.UBound()];
	If Not AccrualResult.IsEmpty() Then
		Selection = AccrualResult.Select();
		While Selection.Next() Do
			PlotLine = ServiceAccrualSchedule.Add();
			FillPropertyValues(PlotLine, Selection);
		EndDo;
	EndIf;

EndProcedure

// Returns the leased FA under the Contract
// 
// Parameters:
// Contract - CatalogRef.CounterpartyContracts -
// Date - Date -
//
// Returns:
// 	Array of CatalogRef.Assets
Function LeasedFAUnderContract(Contract, Date) Export
	
	FAArray = New Array;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	AssetsLeasedOutSliceLast.FixedAsset AS FixedAsset
		|FROM
		|	InformationRegister.AssetsLeasedOut.SliceLast(&Date,) AS AssetsLeasedOutSliceLast
		|WHERE
		|	AssetsLeasedOutSliceLast.Contract = &Contract
		|	AND AssetsLeasedOutSliceLast.State = VALUE(Enum.FixedAssetsStates.LeasedOut)";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Contract", Contract);
	
	QueryResult = Query.Execute();
	
	FAArray = QueryResult.Unload().UnloadColumn("FixedAsset");
	
	Return FAArray;
	
EndFunction

// Returns the leased FA under the Contract
// 
// Parameters:
// Contract - CatalogRef.LeaseContract -
// Date - Date -
//
// Returns:
// 	Array of CatalogRef.Assets
Function FALeasedUnderContract(Contract, Date) Export
	
	FAArray = New Array;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	LeasedAssetSliceLast.FixedAsset AS FixedAsset
		|FROM
		|	InformationRegister.LeasedAsset.SliceLast(&Date, Contract = &Contract) AS LeasedAssetSliceLast
		|WHERE
		|	LeasedAssetSliceLast.State = VALUE(Enum.FixedAssetsStates.InLease)";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Contract", Contract);
	
	QueryResult = Query.Execute();
	
	FAArray = QueryResult.Unload().UnloadColumn("FixedAsset");
	
	Return FAArray;
	
EndFunction

// Returns the time fence of the graph
// 
// Parameters:
// FixedAsset - CatalogRef.Assets -
// Schedule - DocumentTabularSection.ProvideAssetsToLeasee2_4.ServicePaymentSchedule, DocumentTabularSection.ProvideAssetsToLeasee2_4.ServiceAccrualSchedule -
//
// Returns:
// 	EnumRef.ScheduleTimeFence
Function TimeFenceOfIncomeRentalSchedule(FixedAsset, Schedule) Export
	
	PreviousDate = Undefined;
	PreviousPeriodicity = Undefined;
	ArbitraryTimeFence = PredefinedValue("Enum.ScheduleTimeFence.Custom");
	
	LinesOfFAGraphBy = Schedule.FindRows(New Structure("FixedAsset", FixedAsset));
	
	For Each PlotLine In LinesOfFAGraphBy Do
	
		If PreviousDate <> Undefined Then
			
			Periodicity = LeasedAssetAccountingClientServer.ScheduleTimeFence(PreviousDate, PlotLine.Date);
			
			If PreviousPeriodicity = Undefined Then
				PreviousPeriodicity = Periodicity;
			ElsIf PreviousPeriodicity <> Periodicity Then
				PreviousPeriodicity = ArbitraryTimeFence;
				Break;
			EndIf;
			
		EndIf;
		
		PreviousDate = PlotLine.Date;
		
	EndDo;
	
	If Not ValueIsFilled(PreviousPeriodicity) Then 
		PreviousPeriodicity = ArbitraryTimeFence;
	EndIf;
	
	Return PreviousPeriodicity;
	
EndFunction

// Fills in the rate of return and interest schedule according to the calculation data
// 
// Parameters:
//  Form - See Document.ProvideAssetsToLeasee2_4.Form.DocumentForm
//  CalculationParameters - See ParametersForCalculatingInterestRatesOfProfitableLeases
//  RecalculatePercentages - Boolean
// 
Procedure FillInRateOfReturnInterestChart(Form, CalculationParameters, RecalculatePercentages) Export
	
	Object = Form.Object;
	DetailsForFillIn = "RateOfReturn, PresentValue, SettlementDetails, NGLV";
	
	For Each FAString In CalculationParameters.FATable Do
		FoundRows = Object.FA.FindRows(New Structure("FixedAsset", FAString.FixedAsset));
		For Each FoundRow In FoundRows Do
			FillPropertyValues(FoundRow, FAString, DetailsForFillIn);
		EndDo;
	EndDo;
	
	If RecalculatePercentages Then
		Object.InterestAccrualSchedule.Load(CalculationParameters.InterestAccrualSchedule);
		Form.DisplayGraphOfPercentagesFromRegister = False;
		Form.Modified = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
