//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Adds a Commands to open the processing.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
//
Function AddGenerateCommand(GenerationCommands, Parameters) Export
	
	Result = Undefined;
	
	If AccessRight("Insert", Metadata.Documents.AccrualOfCustomerRebates) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.DataProcessors.BulkAccrualOfCustomerRebates.FullName();
		CreateBasedOnCommand.Presentation = 
			TMCommonUse.ObjectPresentation(Metadata.DataProcessors.BulkAccrualOfCustomerRebates);
		CreateBasedOnCommand.FormName = Metadata.DataProcessors.BulkAccrualOfCustomerRebates.Forms.Form.FullName();
		CreateBasedOnCommand.WriteMode = "Post";
		
		Result = CreateBasedOnCommand;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Generates accrual documents from the ARM in a transaction
// 
// Parameters:
//  DataToGenerate_ - Structure:
//  * DataToBeGeneratedWithoutConducting - See NewDataForGeneratingAccrualDocumentsWithoutConducting
//  * DataToBeGeneratedWithFollowing - See NewDataForGeneratingAccrualDocumentsWithoutConducting
//  CalculationParameters - See Reports.CalculateCustomerRebates.RebatesCalculationParameters
//  GenerationParameters - See DocumentGenerationParameters
//
// Returns:
//  See NewTableOfAccrualDocuments
//
Function GenerateAccrualDocuments(DataToGenerate_, CalculationParameters, GenerationParameters) Export
	
	If GenerationParameters.PostWithoutRebateBalanceCheck Then
		SessionParameters.PostWithoutRebateBalanceCheck = True;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("AccumulationRegister.CustomerRebates");
		LockItem.SetValue("TermDocument", CalculationParameters.TermDocument);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.CustomerRebatesConditions");
		LockItem.SetValue("TermDocument", CalculationParameters.TermDocument);
		LockItem.Mode = DataLockMode.Shared;
		Block.Lock();
		
		DataOfConditionsDocument = Documents.ConditionsOfCustomerRebates.UpToDateData(CalculationParameters.TermDocument);
		GoodsSegmentsAreUsed =
			(DataOfConditionsDocument.ContentOfGoods = Enums.RebatesItems.ProductSegments);
		PartnerSegmentsAreUsed =
			(DataOfConditionsDocument.PartyList = Enums.RebatesParticipants.PartnersSegments);
		SegmentsAreUsed = (GoodsSegmentsAreUsed Or PartnerSegmentsAreUsed);
		CompositionOfSegmentsIsFixed = DataOfConditionsDocument.RecordingIsCompleted;
		
		If SegmentsAreUsed
		   And Not CompositionOfSegmentsIsFixed Then
			
			ExceptionText = NStr("vi = 'Theo chứng từ điều kiện chưa ghi nhận thành phần phân khúc';
								|ru = 'По документу условий не зафиксирован состав сегментов';
								|en = 'Segments are not recorded for the condition document'; fa = 'Segments are not recorded for the condition document';
								|it = 'По документу условий не зафиксирован состав сегментов';
								|pl = 'Segments are not recorded for the condition document';
								|tr = 'Segmentlerin bileşimi şartlar ve koşullar belgesine göre sabit değildir'");
			Raise ExceptionText;
			
		EndIf;
		
		FillParameters = ParametersDocumentFilling(CalculationParameters, GenerationParameters);
		
		ProcessedDocuments = GenerateAccrualDocumentsWithoutConducting(
			DataToGenerate_.DataToBeGeneratedWithoutConducting,
			FillParameters);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	GenerateAccrualDocumentsWithFollowing(
		ProcessedDocuments,
		DataToGenerate_.DataToBeGeneratedWithFollowing,
		FillParameters);
	ConductAccrualDocuments(ProcessedDocuments);
	
	Return ProcessedDocuments;
	
EndFunction

// Returns:
//  Structure - New Data For Generating Accrual Documents:
// * FillInAccordingToSystem - See NewDataTableForGeneratingAccrualDocuments
// * FillInWithAdjustments - See NewDataTableForGeneratingAccrualDocuments
// * FillInAccordingToLineData - See NewDataTableForGeneratingAccrualDocuments
//
Function NewDataForGeneratingAccrualDocumentsWithoutConducting() Export
	
	DataToBeGenerated = New Structure; // Structure of See NewDataTableForGeneratingAccrualDocuments
	DataToBeGenerated.Insert("FillInAccordingToSystem", NewDataTableForGeneratingAccrualDocuments());
	DataToBeGenerated.Insert("FillInWithAdjustments", NewDataTableForGeneratingAccrualDocuments());
	DataToBeGenerated.Insert("FillInAccordingToLineData", NewDataTableForGeneratingAccrualDocuments());
	
	Return DataToBeGenerated;
	
EndFunction

// Returns:
//  Structure - New Data For Generating Accrual Documents:
// * FillInAccordingToSystem - See NewDataTableForGeneratingAccrualDocuments
// * FillInWithAdjustments - See NewDataTableForGeneratingAccrualDocuments
// * FillInAccordingToLineData - See NewDataTableForGeneratingAccrualDocuments
// * MarkToDelete - See NewDataTableForGeneratingAccrualDocuments
//
Function NewDataForGeneratingAccrualDocumentsWithConducting() Export
	
	DataToBeGenerated = New Structure; // Structure of See NewDataTableForGeneratingAccrualDocuments
	DataToBeGenerated.Insert("FillInAccordingToSystem", NewDataTableForGeneratingAccrualDocuments());
	DataToBeGenerated.Insert("FillInWithAdjustments", NewDataTableForGeneratingAccrualDocuments());
	DataToBeGenerated.Insert("FillInAccordingToLineData", NewDataTableForGeneratingAccrualDocuments());
	DataToBeGenerated.Insert("MarkToDelete", NewDataTableForGeneratingAccrualDocuments());
	
	Return DataToBeGenerated;
	
EndFunction

// Returns the accrual table for the passed parameters.
// 
// Parameters:
//  FillParameters - See ParametersForFillingInAccrualTable
// 
// Returns:
//  See DataProcessors.BulkAccrualOfCustomerRebates.NewTableOfAccrualDocuments
//
Function TableOfAccrualDocumentsAccordingToSystemData(FillParameters) Export
	
	If FillParameters.DetailsUpToSalesDocument Then
		QueryText = QueryTextAccrualDocumentsForSalesDocument();
	Else
		QueryText = QueryTextAccrualDocumentsBasedOnConditions(FillParameters.PartyCountDetails);
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	TMCommonUse.SetRequestParameters(Query, FillParameters);
	
	DocumentsTable = NewTableOfAccrualDocuments();
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			DocumentLine = DocumentsTable.Add();
			FillPropertyValues(DocumentLine, Selection);
			
		EndDo;
		
	EndIf;
	
	Return DocumentsTable;
	
EndFunction

// Returns:
//  ValueTable:
// * Check - Boolean
// * Counterparty - CatalogRef.Counterparties
// * Partner - CatalogRef.Currencies
// * DocumentAccruals - DocumentRef.AccrualOfCustomerRebates
// * DocumentSales - DocumentRef.CustomerInvoice, DocumentRef.SaleAdjustment, DocumentRef.CustomerInvoiceServices, DocumentRef.ReturnOfGoodsFromCustomer -
// * AmountToAccrue - Number
// * AmountAccrued - Number
// * SettlementAmount_ - Number
// * AmountAccruedBeforeProcessing - Number
// * AmountCalculatedBeforeProcessing - Number
// * CalculationBase - Number
// * AmountInBasePrices - Number
// * RevenueAmount - Number
// * RevenueAmountExcludingVAT - Number
// * Posted - Boolean
// * DeletionMark - Boolean
// * ErrorDescription - String
// * Messages - FixedArray of String
//
Function NewTableOfAccrualDocuments() Export
	
	DescriptionOfCounterpartyType = New TypeDescription("CatalogRef.Counterparties");
	DescriptionOfPartnerType = New TypeDescription("CatalogRef.Partners");
	DescriptionOfAccrualDocumentType = New TypeDescription("DocumentRef.AccrualOfCustomerRebates");
	DescriptionOfAmountType = CurrencyRateOperations.MoneyFieldTypeDescription(AllowedSign.Any);
	BooleanTypeDetails = New TypeDescription("Boolean");
	DescriptionOfSalesDocumentType = New TypeDescription("DocumentRef.CustomerInvoice, DocumentRef.SaleAdjustment, DocumentRef.CustomerInvoiceServices, DocumentRef.ReturnOfGoodsFromCustomer");
	StringTypeDetails = New TypeDescription("String");
	DescriptionOfArrayType = New TypeDescription("FixedArray");
	
	DocumentsTable = New ValueTable();
	DocumentsTable.Columns.Add("Check", BooleanTypeDetails);
	DocumentsTable.Columns.Add("Counterparty", DescriptionOfCounterpartyType);
	DocumentsTable.Columns.Add("Partner", DescriptionOfPartnerType);
	DocumentsTable.Columns.Add("DocumentAccruals", DescriptionOfAccrualDocumentType);
	DocumentsTable.Columns.Add("DocumentSales", DescriptionOfSalesDocumentType);
	DocumentsTable.Columns.Add("AmountToAccrue", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("AmountAccrued", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("AmountAccruedBeforeProcessing", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("AmountCalculatedBeforeProcessing", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("SettlementAmount_", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("CalculationBase", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("AmountInBasePrices", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("RevenueAmount", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("RevenueAmountExcludingVAT", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("Posted", BooleanTypeDetails);
	DocumentsTable.Columns.Add("DeletionMark", BooleanTypeDetails);
	DocumentsTable.Columns.Add("ErrorDescription", StringTypeDetails);
	DocumentsTable.Columns.Add("Messages", DescriptionOfArrayType);
	
	Return DocumentsTable;
	
EndFunction

// Returns:
//  Structure - Document Generation Parameters:
// * PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants - 
// * PostWithoutRebateBalanceCheck - Boolean - 
// * RevenueColumnName - String - 
// * WithoutCalculation - Boolean - 
//
Function DocumentGenerationParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("PartyCountDetails", Enums.ARAPAccountingDrilldownsOfRebatesParticipants.EmptyRef());
	Parameters.Insert("PostWithoutRebateBalanceCheck", False);
	Parameters.Insert("RevenueColumnName", "");
	Parameters.Insert("WithoutCalculation", False);
	
	Return Parameters;
	
EndFunction

// Returns:
//  Structure - Parameters For Filling In The Accrual Table:
// * BonusTable - ValueTable - 
// * TermDocument - DocumentRef.ConditionsOfCustomerRebates - 
// * Currency - CatalogRef.Currencies - 
// * Organization - CatalogRef.Companies - 
// * DocumentsCreationDate - Date - 
// * BeginOfPeriod - Date - 
// * PeriodEnding - Date - 
// * PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants - 
// * DetailsUpToSalesDocument - Boolean - 
// * RevenueColumnName - String - 
// * WithoutCalculation - Boolean - 
//
Function ParametersForFillingInAccrualTable() Export
	
	DateEmpty = Date(1, 1, 1);
	
	Parameters = New Structure;
	Parameters.Insert("BonusTable", New ValueTable);
	Parameters.Insert("TermDocument", Documents.ConditionsOfCustomerRebates.EmptyRef());
	Parameters.Insert("Currency", Catalogs.Currencies.EmptyRef());
	Parameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	Parameters.Insert("DocumentsCreationDate", DateEmpty);
	Parameters.Insert("BeginOfPeriod", DateEmpty);
	Parameters.Insert("PeriodEnding", DateEmpty);
	Parameters.Insert("PartyCountDetails", Enums.ARAPAccountingDrilldownsOfRebatesParticipants.EmptyRef());
	Parameters.Insert("DetailsUpToSalesDocument", False);
	Parameters.Insert("RevenueColumnName", "");
	Parameters.Insert("WithoutCalculation", False);
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

// Returns:
//  ValueTable:
// * Counterparty - CatalogRef.Counterparties
// * Partner - CatalogRef.Currencies
// * DocumentAccruals - DocumentRef.AccrualOfCustomerRebates
// * AmountToAccrue - Number
// * AmountAccrued - Number
// * SettlementAmount_ - Number
//
Function NewDataTableForGeneratingAccrualDocuments()
	
	DescriptionOfCounterpartyType = New TypeDescription("CatalogRef.Counterparties");
	DescriptionOfPartnerType = New TypeDescription("CatalogRef.Partners");
	DescriptionOfAccrualDocumentType = New TypeDescription("DocumentRef.AccrualOfCustomerRebates");
	DescriptionOfAmountType = CurrencyRateOperations.MoneyFieldTypeDescription(AllowedSign.Any);
	
	DocumentsTable = New ValueTable();
	DocumentsTable.Columns.Add("Counterparty", DescriptionOfCounterpartyType);
	DocumentsTable.Columns.Add("Partner", DescriptionOfPartnerType);
	DocumentsTable.Columns.Add("DocumentAccruals", DescriptionOfAccrualDocumentType);
	DocumentsTable.Columns.Add("AmountToAccrue", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("AmountAccrued", DescriptionOfAmountType);
	DocumentsTable.Columns.Add("SettlementAmount_", DescriptionOfAmountType);
	
	Return DocumentsTable;
	
EndFunction

// Parameters:
//  PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants
// 
// Returns:
//  String
//
Function QueryTextAccrualDocumentsBasedOnConditions(PartyCountDetails)
	
	QueryText = TemplateForQueryTextBasedOnConditions();
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	TextOfBonusTableField = "";
	TextOfDocumentDataField = "";
	TextOfAccrualField = "";
	TextLinkCondition = "";
	TextOfAccrualAccordingToConditions = "";
	
	If PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
		
		TextOfBonusTableField =
		"BonusTable.Counterparty,
		|	BonusTable.Partner";
		
		TextOfDocumentDataField =
		"DocumentsData.Counterparty,
		|	DocumentsData.Partner";
		
		TextOfAccrualField =
		"AccrualsAccordingToTerms.Counterparty,
		|	AccrualsAccordingToTerms.Partner";
		
		TextLinkCondition =
		"BonusTable.Counterparty = DocumentsData.Counterparty
		|		AND BonusTable.Partner = DocumentsData.Partner";
		
		TextOfAccrualAccordingToConditions = "ISNULL(BonusTable.Counterparty, DocumentsData.Counterparty) AS Counterparty,
		|		ISNULL(BonusTable.Partner, DocumentsData.Partner) AS Partner";
		
	ElsIf PartyCountDetails = Detailing.ByCounterparty Then
		
		TextOfBonusTableField = "BonusTable.Counterparty";
		TextOfDocumentDataField = "DocumentsData.Counterparty";
		TextOfAccrualField = "AccrualsAccordingToTerms.Counterparty";
		TextLinkCondition = "BonusTable.Counterparty = DocumentsData.Counterparty";
		TextOfAccrualAccordingToConditions = "ISNULL(BonusTable.Counterparty, DocumentsData.Counterparty) AS Counterparty";
		
	ElsIf PartyCountDetails = Detailing.ByCustomer Then
		
		TextOfBonusTableField = "BonusTable.Partner";
		TextOfDocumentDataField = "DocumentsData.Partner";
		TextOfAccrualField = "AccrualsAccordingToTerms.Partner";
		TextLinkCondition = "BonusTable.Partner = DocumentsData.Partner";
		TextOfAccrualAccordingToConditions = "ISNULL(BonusTable.Partner, DocumentsData.Partner) AS Partner";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&BonusTableCounterpartyPartner", TextOfBonusTableField);
	QueryText = StrReplace(QueryText, "&DocumentDataCounterpartyPartner", TextOfDocumentDataField);
	QueryText = StrReplace(QueryText, "&AccrualsCounterpartyPartner", TextOfAccrualField);
	QueryText = StrReplace(QueryText, "&LinkConditionExpression", TextLinkCondition);
	QueryText = StrReplace(QueryText, "&AccrualsUnderTermsOfCounterpartyPartner", TextOfAccrualAccordingToConditions);
	
	Return QueryText;
	
EndFunction

// Returns:
//  String
//
Function TemplateForQueryTextBasedOnConditions()
	
	QueryText =
	"SELECT
	|	&BonusTableCounterpartyPartner,
	|	BonusTable.AmountBonus AS AmountBonus
	|INTO VT_TableOfBonusesPreparation
	|FROM
	|	&BonusTable AS BonusTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BonusTableCounterpartyPartner,
	|	SUM(BonusTable.AmountBonus) AS AmountBonus
	|INTO TT_BonusTable
	|FROM
	|	VT_TableOfBonusesPreparation AS BonusTable
	|GROUP BY
	|	&BonusTableCounterpartyPartner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&DocumentDataCounterpartyPartner,
	|	DocumentsData.Recorder AS DocumentAccruals,
	|	SUM(CustomerRebates.AmountBonus) AS AmountAccrued
	|INTO TT_DocumentsData
	|FROM
	|	InformationRegister.CustomerRebatesAccrualPeriods AS DocumentsData
	|		LEFT JOIN AccumulationRegister.CustomerRebates AS CustomerRebates
	|		ON DocumentsData.Recorder = CustomerRebates.Recorder
	|		 AND DocumentsData.Counterparty = CustomerRebates.Counterparty
	|		 AND DocumentsData.Partner = CustomerRebates.Partner
	|WHERE
	|	DocumentsData.TermDocument = &TermDocument
	|	AND DocumentsData.Currency = &Currency
	|	AND DocumentsData.BeginOfPeriod = &BeginOfPeriod
	|	AND DocumentsData.PeriodEnding = &PeriodEnding
	|GROUP BY
	|	DocumentsData.Recorder,
	|	&DocumentDataCounterpartyPartner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&AccrualsUnderTermsOfCounterpartyPartner,
	|	ISNULL(BonusTable.AmountBonus, 0) AS SettlementAmount_,
	|	ISNULL(DocumentsData.AmountAccrued, 0) AS AmountAccrued,
	|	CASE
	|		WHEN BonusTable.AmountBonus = DocumentsData.AmountAccrued
	|			THEN 0
	|		ELSE ISNULL(BonusTable.AmountBonus, 0)
	|	END AS AmountToAccrue,
	|	CASE
	|		WHEN BonusTable.AmountBonus = DocumentsData.AmountAccrued
	|				OR ISNULL(BonusTable.AmountBonus, 0) = 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Check,
	|	ISNULL(DocumentsData.DocumentAccruals, VALUE(Document.AccrualOfCustomerRebates.EmptyRef)) AS DocumentAccruals
	|INTO TT_AccrualsAccordingToTerms
	|FROM
	|	TT_BonusTable AS BonusTable
	|		FULL JOIN TT_DocumentsData AS DocumentsData
	|		ON &LinkConditionExpression
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&AccrualsCounterpartyPartner,
	|	AccrualsAccordingToTerms.SettlementAmount_ AS SettlementAmount_,
	|	AccrualsAccordingToTerms.AmountAccrued AS AmountAccrued,
	|	AccrualsAccordingToTerms.AmountToAccrue AS AmountToAccrue,
	|	AccrualsAccordingToTerms.Check AS Check,
	|	CAST(AccrualsAccordingToTerms.DocumentAccruals AS Document.AccrualOfCustomerRebates).Posted AS Posted,
	|	AccrualsAccordingToTerms.DocumentAccruals AS DocumentAccruals
	|INTO VT_AccrualsPreparation
	|FROM
	|	TT_AccrualsAccordingToTerms AS AccrualsAccordingToTerms
	|WHERE
	|	AccrualsAccordingToTerms.SettlementAmount_ <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&AccrualsCounterpartyPartner,
	|	AccrualsAccordingToTerms.SettlementAmount_ AS SettlementAmount_,
	|	AccrualsAccordingToTerms.AmountAccrued AS AmountAccrued,
	|	AccrualsAccordingToTerms.AmountToAccrue AS AmountToAccrue,
	|	AccrualsAccordingToTerms.Check AS Check,
	|	CAST(AccrualsAccordingToTerms.DocumentAccruals AS Document.AccrualOfCustomerRebates).Posted AS Posted,
	|	AccrualsAccordingToTerms.DocumentAccruals AS DocumentAccruals
	|FROM
	|	TT_AccrualsAccordingToTerms AS AccrualsAccordingToTerms
	|WHERE
	|	AccrualsAccordingToTerms.SettlementAmount_ = 0
	|	AND AccrualsAccordingToTerms.DocumentAccruals <> VALUE(Document.AccrualOfCustomerRebates.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&AccrualsCounterpartyPartner,
	|	AccrualsAccordingToTerms.SettlementAmount_ AS SettlementAmount_,
	|	AccrualsAccordingToTerms.AmountAccrued AS AmountAccrued,
	|	AccrualsAccordingToTerms.AmountToAccrue AS AmountToAccrue,
	|	AccrualsAccordingToTerms.Check AS Check,
	|	AccrualsAccordingToTerms.Posted AS Posted,
	|	AccrualsAccordingToTerms.DocumentAccruals AS DocumentAccruals
	|FROM
	|	VT_AccrualsPreparation AS AccrualsAccordingToTerms
	|ORDER BY
	|	AccrualsAccordingToTerms.SettlementAmount_ DESC,
	|	&AccrualsCounterpartyPartner";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String
//
Function QueryTextAccrualDocumentsForSalesDocument()
	
	QueryText =
	"SELECT
	|	BonusTable.DocumentSales AS DocumentSales,
	|	BonusTable.Counterparty AS Counterparty,
	|	BonusTable.Partner AS Partner,
	|	BonusTable.CalculationBase AS CalculationBase,
	|	BonusTable.RevenueAmount AS RevenueAmount,
	|	BonusTable.RevenueAmountExcludingVAT AS RevenueAmountExcludingVAT,
	|	BonusTable.AmountInBasePrices AS AmountInBasePrices,
	|	BonusTable.AmountBonus AS AmountBonus
	|INTO VT_TableOfBonusesPreparation
	|FROM
	|	&BonusTable AS BonusTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusTable.DocumentSales AS DocumentSales,
	|	BonusTable.Counterparty AS Counterparty,
	|	BonusTable.Partner AS Partner,
	|	SUM(BonusTable.CalculationBase) AS CalculationBase,
	|	SUM(BonusTable.RevenueAmount) AS RevenueAmount,
	|	SUM(BonusTable.RevenueAmountExcludingVAT) AS RevenueAmountExcludingVAT,
	|	SUM(BonusTable.AmountInBasePrices) AS AmountInBasePrices,
	|	SUM(BonusTable.AmountBonus) AS AmountBonus
	|INTO TT_BonusTable
	|FROM
	|	VT_TableOfBonusesPreparation AS BonusTable
	|
	|GROUP BY
	|	BonusTable.DocumentSales,
	|	BonusTable.Counterparty,
	|	BonusTable.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsData.Counterparty AS Counterparty,
	|	DocumentsData.Partner AS Partner,
	|	DocumentsData.Recorder AS DocumentAccruals,
	|	SUM(CustomerRebates.AmountBonus) AS AmountAccrued
	|INTO TT_DocumentsData
	|FROM
	|	InformationRegister.CustomerRebatesAccrualPeriods AS DocumentsData
	|		LEFT JOIN AccumulationRegister.CustomerRebates AS CustomerRebates
	|		ON DocumentsData.Recorder = CustomerRebates.Recorder
	|		 AND DocumentsData.Counterparty = CustomerRebates.Counterparty
	|		 AND DocumentsData.Partner = CustomerRebates.Partner
	|WHERE
	|	DocumentsData.TermDocument = &TermDocument
	|	AND DocumentsData.Currency = &Currency
	|	AND DocumentsData.BeginOfPeriod = &BeginOfPeriod
	|	AND DocumentsData.PeriodEnding = &PeriodEnding
	|
	|GROUP BY
	|	DocumentsData.Counterparty,
	|	DocumentsData.Partner,
	|	DocumentsData.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusTable.DocumentSales AS DocumentSales,
	|	BonusTable.Counterparty AS Counterparty,
	|	BonusTable.Partner AS Partner,
	|	BonusTable.CalculationBase AS CalculationBase,
	|	BonusTable.RevenueAmount AS RevenueAmount,
	|	BonusTable.RevenueAmountExcludingVAT AS RevenueAmountExcludingVAT,
	|	BonusTable.AmountInBasePrices AS AmountInBasePrices,
	|	BonusTable.AmountBonus AS SettlementAmount_,
	|	DocumentsData.AmountAccrued AS AmountAccrued,
	|	CASE
	|		WHEN BonusTable.AmountBonus = DocumentsData.AmountAccrued
	|			THEN 0
	|		ELSE BonusTable.AmountBonus
	|	END AS AmountToAccrue,
	|	CASE
	|		WHEN BonusTable.AmountBonus = DocumentsData.AmountAccrued
	|				OR BonusTable.AmountBonus = 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Check,
	|	ISNULL(DocumentsData.DocumentAccruals, VALUE(Document.AccrualOfCustomerRebates.EmptyRef)) AS DocumentAccruals
	|FROM
	|	TT_BonusTable AS BonusTable
	|		LEFT JOIN TT_DocumentsData AS DocumentsData
	|		ON BonusTable.Counterparty = DocumentsData.Counterparty
	|			AND BonusTable.Partner = DocumentsData.Partner";
	
	Return QueryText;
	
EndFunction

// Parameters:
//  PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants
//
// Returns:
//  String
//
Function QueryTextBasedOnSystemData(PartyCountDetails)
	
	QueryText =
	"SELECT
	|	RawData.DocumentAccruals AS DocumentAccruals,
	|	RawData.Counterparty AS Counterparty,
	|	RawData.AmountAccrued AS AmountAccrued,
	|	RawData.SettlementAmount_ AS SettlementAmount_,
	|	RawData.Partner AS Partner
	|INTO TT_RawData
	|FROM
	|	&RawData AS RawData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOfSystem.DocumentAccruals AS DocumentAccruals,
	|	DataOfSystem.DocumentSales AS DocumentSales,
	|	CAST(DataOfSystem.Counterparty AS Catalog.Counterparties) AS Counterparty,
	|	DataOfSystem.Partner AS Partner,
	|	DataOfSystem.CalculationBase AS CalculationBase,
	|	DataOfSystem.RevenueAmount AS RevenueAmount,
	|	DataOfSystem.RevenueAmountExcludingVAT AS RevenueAmountExcludingVAT,
	|	DataOfSystem.AmountInBasePrices AS AmountInBasePrices,
	|	DataOfSystem.AmountToAccrue AS AmountToAccrue,
	|	DataOfSystem.AmountAccrued AS AmountAccrued,
	|	DataOfSystem.SettlementAmount_ AS SettlementAmount_
	|INTO TT_DataOfSystem
	|FROM
	|	&DataOfSystem AS DataOfSystem
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TRUE AS PopulationBySettlement,
	|	CASE
	|		WHEN DataOfSystem.DocumentAccruals = VALUE(Document.AccrualOfCustomerRebates.EmptyRef)
	|			THEN RawData.DocumentAccruals
	|		ELSE DataOfSystem.DocumentAccruals
	|	END AS DocumentAccruals,
	|	DataOfSystem.DocumentSales AS DocumentSales,
	|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1)) AS Date,
	|	CAST(CASE
	|		WHEN DataOfSystem.DocumentAccruals = VALUE(Document.AccrualOfCustomerRebates.EmptyRef)
	|			THEN RawData.DocumentAccruals
	|		ELSE DataOfSystem.DocumentAccruals
	|	END AS Document.AccrualOfCustomerRebates).Posted AS Posted,
	|	DataOfSystem.Counterparty AS Counterparty,
	|	DataOfSystem.Partner AS Partner,
	|	DataOfSystem.Counterparty.Partner AS CounterpartySPartner,
	|	DataOfSystem.CalculationBase AS CalculationBase,
	|	DataOfSystem.RevenueAmount AS RevenueAmount,
	|	DataOfSystem.RevenueAmountExcludingVAT AS RevenueAmountExcludingVAT,
	|	DataOfSystem.AmountInBasePrices AS AmountInBasePrices,
	|	RawData.AmountAccrued AS AmountAccruedBeforeProcessing,
	|	RawData.SettlementAmount_ AS AmountCalculatedBeforeProcessing,
	|	DataOfSystem.SettlementAmount_ AS AmountBonusAccrued,
	|	DataOfSystem.SettlementAmount_ AS AmountAccruedBonus
	|FROM
	|	TT_RawData AS RawData
	|		INNER JOIN TT_DataOfSystem AS DataOfSystem
	|			LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			ON DataOfSystem.DocumentSales = DocumentsRegistry.Ref
	|		ON &ConditionText
	|
	|ORDER BY
	|	Date
	|TOTALS
	|	SUM(AmountBonusAccrued),
	|	SUM(AmountAccruedBonus),
	|	MAX(AmountAccruedBeforeProcessing),
	|	MAX(AmountCalculatedBeforeProcessing),
	|	SUM(CalculationBase),
	|	SUM(RevenueAmount),
	|	SUM(RevenueAmountExcludingVAT),
	|	SUM(AmountInBasePrices),
	|	MAX(DocumentAccruals)
	|BY
	|	&TextCounterpartyClient";
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	TextCounterpartyClient = "";
	ConditionText = "";
	
	If PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
		
		TextCounterpartyClient = "DataOfSystem.Counterparty,
								|	DataOfSystem.Partner AS Partner";
		ConditionText = "RawData.Counterparty = DataOfSystem.Counterparty
					   |		AND RawData.Partner = DataOfSystem.Partner";
		
	ElsIf PartyCountDetails = Detailing.ByCounterparty Then
		
		TextCounterpartyClient = "DataOfSystem.Counterparty";
		ConditionText = "RawData.Counterparty = DataOfSystem.Counterparty";
		
	ElsIf PartyCountDetails = Detailing.ByCustomer Then
		
		TextCounterpartyClient = "DataOfSystem.Partner";
		ConditionText = "RawData.Partner = DataOfSystem.Partner";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TextCounterpartyClient", TextCounterpartyClient);
	QueryText = StrReplace(QueryText, "&ConditionText", ConditionText);
	
	Return QueryText;
	
EndFunction

// Parameters:
//  PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants
//
// Returns:
//  String
//
Function QueryTextWithCorrection(PartyCountDetails)
	
	QueryText =
	"SELECT
	|	RawData.DocumentAccruals AS DocumentAccruals,
	|	CAST(RawData.Counterparty AS Catalog.Counterparties) AS Counterparty,
	|	RawData.Partner AS Partner,
	|	RawData.AmountToAccrue AS AmountToAccrue,
	|	RawData.AmountAccrued AS AmountAccrued,
	|	RawData.SettlementAmount_ AS SettlementAmount_
	|INTO TT_RawData
	|FROM
	|	&RawData AS RawData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOfSystem.DocumentAccruals AS DocumentAccruals,
	|	DataOfSystem.DocumentSales AS DocumentSales,
	|	CAST(DataOfSystem.Counterparty AS Catalog.Counterparties) AS Counterparty,
	|	DataOfSystem.Partner AS Partner,
	|	DataOfSystem.CalculationBase AS CalculationBase,
	|	DataOfSystem.RevenueAmount AS RevenueAmount,
	|	DataOfSystem.RevenueAmountExcludingVAT AS RevenueAmountExcludingVAT,
	|	DataOfSystem.AmountInBasePrices AS AmountInBasePrices,
	|	DataOfSystem.SettlementAmount_ AS AmountToAccrue,
	|	DataOfSystem.SettlementAmount_ AS SettlementAmount_
	|INTO TT_DataOfSystem
	|FROM
	|	&DataOfSystem AS DataOfSystem
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualData.DocumentAccruals AS DocumentAccruals,
	|	&AccrualDataCounterpartyClient,
	|	SUM(AccrualData.AmountAccrued) AS AmountAccrued,
	|	SUM(AccrualData.SettlementAmount_) AS SettlementAmount_,
	|	SUM(AccrualData.AmountToAccrue) AS AmountToAccrue
	|INTO VT_InitialDataTotal
	|FROM
	|	TT_RawData AS AccrualData
	|
	|GROUP BY
	|	AccrualData.DocumentAccruals,
	|	&AccrualDataCounterpartyClient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualData.DocumentAccruals AS DocumentAccruals,
	|	&AccrualDataCounterpartyClient,
	|	SUM(AccrualData.CalculationBase) AS CalculationBase,
	|	SUM(AccrualData.RevenueAmount) AS RevenueAmount,
	|	SUM(AccrualData.RevenueAmountExcludingVAT) AS RevenueAmountExcludingVAT,
	|	SUM(AccrualData.AmountInBasePrices) AS AmountInBasePrices,
	|	SUM(AccrualData.SettlementAmount_) AS AmountToAccrue
	|INTO VT_SystemDataTotal
	|FROM
	|	TT_DataOfSystem AS AccrualData
	|
	|GROUP BY
	|	AccrualData.DocumentAccruals,
	|	&AccrualDataCounterpartyClient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TRUE AS PopulationBySettlement,
	|	0 AS Order,
	|	CASE
	|		WHEN DataOfSystem.DocumentAccruals = VALUE(Document.AccrualOfCustomerRebates.EmptyRef)
	|			THEN RawData.DocumentAccruals
	|		ELSE DataOfSystem.DocumentAccruals
	|	END AS DocumentAccruals,
	|	DataOfSystem.DocumentSales AS DocumentSales,
	|	DataOfSystem.Counterparty AS Counterparty,
	|	DataOfSystem.Partner AS Partner,
	|	DataOfSystem.CalculationBase AS CalculationBase,
	|	DataOfSystem.RevenueAmount AS RevenueAmount,
	|	DataOfSystem.RevenueAmountExcludingVAT AS RevenueAmountExcludingVAT,
	|	DataOfSystem.AmountInBasePrices AS AmountInBasePrices,
	|	RawData.AmountAccrued AS AmountAccruedBeforeProcessing,
	|	RawData.SettlementAmount_ AS AmountCalculatedBeforeProcessing,
	|	DataOfSystem.SettlementAmount_ AS AmountBonusAccrued,
	|	DataOfSystem.SettlementAmount_ AS AmountAccruedBonus
	|INTO TT_DocumentData
	|FROM
	|	TT_RawData AS RawData
	|		INNER JOIN TT_DataOfSystem AS DataOfSystem
	|		ON &ConditionText
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE AS PopulationBySettlement,
	|	1 AS Order,
	|	CASE
	|		WHEN DataOfSystem.DocumentAccruals = VALUE(Document.AccrualOfCustomerRebates.EmptyRef)
	|			THEN RawData.DocumentAccruals
	|		ELSE DataOfSystem.DocumentAccruals
	|	END AS DocumentAccruals,
	|	UNDEFINED AS DocumentSales,
	|	&CounterpartyTotal AS Counterparty,
	|	&PartnerTotal AS Partner,
	|	0 AS CalculationBase,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExcludingVAT,
	|	0 AS AmountInBasePrices,
	|	RawData.AmountAccrued AS AmountAccruedBeforeProcessing,
	|	RawData.AmountToAccrue AS AmountCalculatedBeforeProcessing,
	|	RawData.AmountToAccrue - DataOfSystem.AmountToAccrue AS AmountBonusAccrued,
	|	0 AS AmountAccruedBonus
	|FROM
	|	VT_InitialDataTotal AS RawData
	|		INNER JOIN VT_SystemDataTotal AS DataOfSystem
	|		ON &ConditionText
	|WHERE
	|	DataOfSystem.AmountToAccrue <> 0
	|	OR DataOfSystem.DocumentAccruals <> VALUE(Document.AccrualOfCustomerRebates.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.PopulationBySettlement AS PopulationBySettlement,
	|	DocumentData.Order AS Order,
	|	DocumentData.DocumentAccruals AS DocumentAccruals,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|	CAST(DocumentData.Counterparty AS Catalog.Counterparties).Partner AS CounterpartySPartner,
	|	DocumentData.DocumentSales AS DocumentSales,
	|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1)) AS Date,
	|	CAST(DocumentData.DocumentAccruals AS Document.AccrualOfCustomerRebates).Posted AS Posted,
	|	DocumentData.CalculationBase AS CalculationBase,
	|	DocumentData.RevenueAmount AS RevenueAmount,
	|	DocumentData.RevenueAmountExcludingVAT AS RevenueAmountExcludingVAT,
	|	DocumentData.AmountInBasePrices AS AmountInBasePrices,
	|	DocumentData.AmountAccruedBeforeProcessing AS AmountAccruedBeforeProcessing,
	|	DocumentData.AmountCalculatedBeforeProcessing AS AmountCalculatedBeforeProcessing,
	|	DocumentData.AmountBonusAccrued AS AmountBonusAccrued,
	|	DocumentData.AmountAccruedBonus AS AmountAccruedBonus
	|FROM
	|	TT_DocumentData AS DocumentData
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentData.DocumentSales = DocumentsRegistry.Ref
	|		 AND DocumentData.DocumentSales <> UNDEFINED
	|
	|ORDER BY
	|	Order,
	|	Date
	|TOTALS
	|	MAX(DocumentAccruals),
	|	MAX(AmountAccruedBeforeProcessing),
	|	MAX(AmountCalculatedBeforeProcessing),
	|	SUM(CalculationBase),
	|	SUM(RevenueAmount),
	|	SUM(RevenueAmountExcludingVAT),
	|	SUM(AmountInBasePrices),
	|	SUM(AmountBonusAccrued),
	|	SUM(AmountAccruedBonus)
	|BY
	|	&TextCounterpartyClient";
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	TextCounterpartyClient = "";
	ConditionText = "";
	TextAccrualData = "";
	TextCounterpartyTotal = "";
	TextPartnerSummary = "";
	If PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
		
		TextCounterpartyClient = "DocumentData.Counterparty,
								|	DocumentData.Partner AS Partner";
		
		ConditionText = "RawData.Counterparty = DataOfSystem.Counterparty
					   |		AND RawData.Partner = DataOfSystem.Partner";
		
		TextAccrualData = "AccrualData.Counterparty,
								|	AccrualData.Partner";
		
		TextCounterpartyTotal = "RawData.Counterparty";
		TextPartnerSummary = "RawData.Partner";
		
	ElsIf PartyCountDetails = Detailing.ByCounterparty Then
		
		TextCounterpartyClient = "DocumentData.Counterparty";
		
		ConditionText = "RawData.Counterparty = DataOfSystem.Counterparty";
		
		TextAccrualData = "AccrualData.Counterparty";
		
		TextCounterpartyTotal = "RawData.Counterparty";
		TextPartnerSummary = "UNDEFINED";
		
	ElsIf PartyCountDetails = Detailing.ByCustomer Then
		
		TextCounterpartyClient = "DocumentData.Partner";
		
		ConditionText = "RawData.Partner = DataOfSystem.Partner";
		
		TextAccrualData = "AccrualData.Partner";
		
		TextCounterpartyTotal = "UNDEFINED";
		TextPartnerSummary = "RawData.Partner";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TextCounterpartyClient", TextCounterpartyClient);
	QueryText = StrReplace(QueryText, "&ConditionText", ConditionText);
	QueryText = StrReplace(QueryText, "&AccrualDataCounterpartyClient", TextAccrualData);
	QueryText = StrReplace(QueryText, "&CounterpartyTotal", TextCounterpartyTotal);
	QueryText = StrReplace(QueryText, "&PartnerTotal", TextPartnerSummary);
	
	Return QueryText;
	
EndFunction

// Parameters:
//  PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants
//
// Returns:
//  String
//
Function QueryTextBasedOnStringData(PartyCountDetails)
	
	QueryText =
	"SELECT
	|	RawData.DocumentAccruals AS DocumentAccruals,
	|	CAST(RawData.Counterparty AS Catalog.Counterparties) AS Counterparty,
	|	RawData.Partner AS Partner,
	|	RawData.AmountToAccrue AS AmountToAccrue,
	|	RawData.AmountAccrued AS AmountAccrued,
	|	RawData.SettlementAmount_ AS SettlementAmount_
	|INTO TT_RawData
	|FROM
	|	&RawData AS RawData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	FALSE AS PopulationBySettlement,
	|	RawData.DocumentAccruals AS DocumentAccruals,
	|	CAST(RawData.DocumentAccruals AS Document.AccrualOfCustomerRebates).Posted AS Posted,
	|	UNDEFINED AS DocumentSales,
	|	&TextCounterpartyClient,
	|	RawData.Counterparty.Partner AS CounterpartySPartner,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExcludingVAT,
	|	0 AS AmountInBasePrices,
	|	RawData.AmountToAccrue AS AmountBonusAccrued,
	|	RawData.AmountAccrued AS AmountAccruedBeforeProcessing,
	|	RawData.SettlementAmount_ AS AmountCalculatedBeforeProcessing,
	|	RawData.SettlementAmount_ AS AmountAccruedBonus
	|FROM
	|	TT_RawData AS RawData
	|TOTALS
	|	SUM(AmountBonusAccrued),
	|	SUM(AmountAccruedBonus),
	|	MAX(AmountAccruedBeforeProcessing),
	|	MAX(AmountCalculatedBeforeProcessing),
	|	MAX(DocumentAccruals)
	|BY
	|	&TextCounterpartyClient";
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	TextCounterpartyClient = "";
	If PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
		
		TextCounterpartyClient = "RawData.Counterparty,
								|	RawData.Partner AS Partner";
		
	ElsIf PartyCountDetails = Detailing.ByCounterparty Then
		
		TextCounterpartyClient = "RawData.Counterparty";
		
	ElsIf PartyCountDetails = Detailing.ByCustomer Then
		
		TextCounterpartyClient = "RawData.Partner";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TextCounterpartyClient", TextCounterpartyClient);
	
	Return QueryText;
	
EndFunction

// Parameters:
//  PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants
//
// Returns:
//  String
//
Function QueryTextMarkToDelete(PartyCountDetails)
	
	QueryText =
	"SELECT
	|	RawData.DocumentAccruals AS DocumentAccruals,
	|	CAST(RawData.Counterparty AS Catalog.Counterparties) AS Counterparty,
	|	RawData.Partner AS Partner,
	|	RawData.AmountAccrued AS AmountAccrued,
	|	RawData.SettlementAmount_ AS SettlementAmount_,
	|	RawData.AmountToAccrue AS AmountToAccrue
	|INTO TT_RawData
	|FROM
	|	&RawData AS RawData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&AccrualsCounterpartyPartner,
	|	DataOfSystem.Recorder AS DocumentAccruals
	|INTO TT_DataOfSystem
	|FROM
	|	InformationRegister.CustomerRebatesAccrualPeriods AS DataOfSystem
	|WHERE DataOfSystem.TermDocument = &TermDocument
	|	AND DataOfSystem.BeginOfPeriod = &BeginOfPeriod
	|	AND DataOfSystem.PeriodEnding = &PeriodEnding
	|GROUP BY
	|	&AccrualsCounterpartyPartner,
	|	DataOfSystem.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&AccrualsCounterpartyPartner,
	|	RawData.AmountAccrued AS AmountAccruedBeforeProcessing,
	|	RawData.SettlementAmount_ AS AmountCalculatedBeforeProcessing,
	|	RawData.SettlementAmount_ AS SettlementAmount_,
	|	TRUE AS Posted,
	|	RawData.DocumentAccruals AS DocumentAccruals
	|FROM
	|	TT_RawData AS RawData
	|		INNER JOIN TT_DataOfSystem AS DataOfSystem
	|		ON RawData.DocumentAccruals = DataOfSystem.DocumentAccruals
	|		 AND &ConditionText
	|";
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	ConditionText = "";
	TextAccrualData = "";
	If PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
		
		ConditionText = "RawData.Counterparty = DataOfSystem.Counterparty
					   |		AND RawData.Partner = DataOfSystem.Partner";
		
		TextAccrualData = "DataOfSystem.Counterparty,
								|	DataOfSystem.Partner";
		
	ElsIf PartyCountDetails = Detailing.ByCounterparty Then
		
		ConditionText = "RawData.Counterparty = DataOfSystem.Counterparty";
		
		TextAccrualData = "DataOfSystem.Counterparty";
		
	ElsIf PartyCountDetails = Detailing.ByCustomer Then
		
		ConditionText = "RawData.Partner = DataOfSystem.Partner";
		
		TextAccrualData = "DataOfSystem.Partner";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionText", ConditionText);
	QueryText = StrReplace(QueryText, "&AccrualsCounterpartyPartner", TextAccrualData);
	
	Return QueryText;
	
EndFunction

// Parameters:
//  QueryResult - QueryResult
//  FillParameters - See ParametersForFillingInAccrualTable
//  AccrualDocuments - See NewTableOfAccrualDocuments
//
Procedure ProcessRequestResult(QueryResult, FillParameters, AccrualDocuments, SpendImmediately = False)
	
	If Not QueryResult.IsEmpty() Then
		
		Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
		
		If FillParameters.PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
			
			CounterpartySelection = QueryResult.Select(QueryResultIteration.ByGroups);
			While CounterpartySelection.Next() Do
				
				HeaderSelection = CounterpartySelection.Select(QueryResultIteration.ByGroups);
				CreateDocumentBasedOnSampleData(HeaderSelection, FillParameters, AccrualDocuments, SpendImmediately)
				
			EndDo;
			
		ElsIf FillParameters.PartyCountDetails = Detailing.ByCounterparty
		      Or FillParameters.PartyCountDetails = Detailing.ByCustomer Then
			
			HeaderSelection = QueryResult.Select(QueryResultIteration.ByGroups);
			CreateDocumentBasedOnSampleData(HeaderSelection, FillParameters, AccrualDocuments, SpendImmediately)
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  QueryResult - QueryResult
//  AccrualDocuments - See NewTableOfAccrualDocuments
//
Procedure MarkAccrualDocumentsForDeletion(QueryResult, AccrualDocuments)
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ResultOfMarkingDeletion = MarkADocumentForDeletion(Selection.DocumentAccruals);
			NewRow = AccrualDocuments.Add();
			FillPropertyValues(NewRow, Selection);
			If ResultOfMarkingDeletion = Undefined Then
				
				NewRow.DeletionMark = True;
				NewRow.Posted = False;
				
			Else
				
				NewRow.AmountAccrued = NewRow.AmountAccruedBeforeProcessing;
				NewRow.SettlementAmount_ = NewRow.AmountCalculatedBeforeProcessing;
				NewRow.AmountToAccrue = 0;
				
				NewRow.DeletionMark = False;
				NewRow.ErrorDescription = ResultOfMarkingDeletion.ErrorDescription;
				NewRow.Messages = New FixedArray(ResultOfMarkingDeletion.Messages);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Selection - QueryResultSelection
//  FillParameters - See ParametersForFillingInAccrualTable
//  AccrualDocuments - See NewTableOfAccrualDocuments
//  SpendImmediately - Boolean
//
Procedure CreateDocumentBasedOnSampleData(Selection, FillParameters, AccrualDocuments, SpendImmediately)
	
	While Selection.Next() Do
		
		DocumentLine = AccrualDocuments.Add();
		FillPropertyValues(DocumentLine, Selection);
		DocumentLine.AmountAccrued = Selection.AmountBonusAccrued;
		DocumentLine.SettlementAmount_ = Selection.AmountAccruedBonus;
		DocumentLine.AmountToAccrue = 0;
		GenerateAccrualDocument(Selection, FillParameters, DocumentLine, SpendImmediately);
		
	EndDo;
			
EndProcedure

// Parameters:
//  DocumentData - QueryResultSelection
//  FillParameters - See ParametersForFillingInAccrualTable
//  DocumentLine - ValueTableRow: See NewTableOfAccrualDocuments
//  SpendImmediately - Boolean
// 
Procedure GenerateAccrualDocument(DocumentData, FillParameters, DocumentLine, SpendImmediately)
	
	DocumentAccruals = DocumentData.DocumentAccruals; // DocumentRef.AccrualOfCustomerRebates
	
	If DocumentAccruals.IsEmpty() Then
		
		DocumentObject = Documents.AccrualOfCustomerRebates.CreateDocument();
		DocumentObject.Fill(FillParameters.TermDocument);
		
	Else
		
		DocumentObject = DocumentAccruals.GetObject();
		If DocumentObject.DeletionMark Then
			DocumentObject.SetDeletionMark(False);
		EndIf;
		
		DocumentObject.Accruals.Clear();
		
	EndIf;
	
	FillPropertyValues(DocumentObject, DocumentData,, "Posted");
	
	DocumentObject.Date = FillParameters.DocumentsCreationDate;
	DocumentObject.Organization = FillParameters.Organization;
	DocumentObject.BeginOfPeriod = FillParameters.BeginOfPeriod;
	DocumentObject.PeriodEnding = FillParameters.PeriodEnding;
	DocumentObject.Currency = FillParameters.Currency;
	
	Detailing = FillParameters.PartyCountDetails;
	
	DetailedData = DocumentData.Select();
	While DetailedData.Next() Do
		
		NewRow = DocumentObject.Accruals.Add();
		FillPropertyValues(NewRow, DetailedData);
		
		If Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterparty
		   And Not ValueIsFilled(NewRow.Partner) Then
			
			NewRow.Partner = DetailedData.CounterpartySPartner;
			
		EndIf;
		
		If Not FillParameters.WithoutCalculation Then
			
			RevenueByLine = DetailedData[FillParameters.RevenueColumnName]; // DefinedType.MonetaryAmountPositiveNegative
			NewRow.Revenue = RevenueByLine;
			
		EndIf;
		
	EndDo;
	
	If SpendImmediately Then
		
		ToHoldDocumentWithFixationOfResult(DocumentObject, DocumentLine, True);
		
	ElsIf DocumentObject.Posted Then
		
		DocumentObject.Write(DocumentWriteMode.UndoPosting);
		DocumentLine.DocumentAccruals = DocumentObject.Ref;
		
	Else
		
		DocumentObject.Write();
		DocumentLine.DocumentAccruals = DocumentObject.Ref;
		
	EndIf;
	
EndProcedure

// Generates accrual documents based on ARM data
// 
// Parameters:
//  DataToGenerate_ - See NewDataForGeneratingAccrualDocumentsWithoutConducting
//  FillParameters - See ParametersDocumentFilling
//
// Returns:
//  See NewTableOfAccrualDocuments
//
Function GenerateAccrualDocumentsWithoutConducting(DataToGenerate_, FillParameters)
	
	ProcessedDocuments = NewTableOfAccrualDocuments();
	
	DocumentsTable = TableOfAccrualDocumentsAccordingToSystemData(FillParameters);
	
	If DataToGenerate_.FillInAccordingToSystem.Count() > 0 Then
		
		Query = New Query;
		Query.Text = QueryTextBasedOnSystemData(FillParameters.PartyCountDetails);
		Query.SetParameter("RawData", DataToGenerate_.FillInAccordingToSystem);
		Query.SetParameter("DataOfSystem", DocumentsTable);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		ProcessRequestResult(QueryResult, FillParameters, ProcessedDocuments);
		
	EndIf;
	
	If DataToGenerate_.FillInWithAdjustments.Count() > 0 Then
		
		Query = New Query;
		Query.Text = QueryTextWithCorrection(FillParameters.PartyCountDetails);
		Query.SetParameter("RawData", DataToGenerate_.FillInWithAdjustments);
		Query.SetParameter("DataOfSystem", DocumentsTable);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		ProcessRequestResult(QueryResult, FillParameters, ProcessedDocuments);
		
	EndIf;
	
	If DataToGenerate_.FillInAccordingToLineData.Count() > 0 Then
		
		Query = New Query;
		Query.Text = QueryTextBasedOnStringData(FillParameters.PartyCountDetails);
		Query.SetParameter("RawData", DataToGenerate_.FillInAccordingToLineData);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		ProcessRequestResult(QueryResult, FillParameters, ProcessedDocuments);
		
	EndIf;
	
	Return ProcessedDocuments;
	
EndFunction

// Parameters for filling in documents.
// 
// Parameters:
//  CalculationParameters - See Reports.CalculateCustomerRebates.RebatesCalculationParameters
//  GenerationParameters - See DocumentGenerationParameters
// 
// Returns:
//  See ParametersForFillingInAccrualTable
Function ParametersDocumentFilling(CalculationParameters, GenerationParameters)
	
	FillParameters = ParametersForFillingInAccrualTable();
	FillParameters.TermDocument = CalculationParameters.TermDocument;
	FillParameters.Currency = CalculationParameters.Currency;
	FillParameters.DocumentsCreationDate = CalculationParameters.DocumentsCreationDate;
	FillParameters.Organization = CalculationParameters.Organization;
	FillParameters.BeginOfPeriod = CalculationParameters.StartDate;
	FillParameters.PeriodEnding = CalculationParameters.EndDate;
	FillParameters.PartyCountDetails = GenerationParameters.PartyCountDetails;
	FillParameters.DetailsUpToSalesDocument = True;
	FillParameters.RevenueColumnName = GenerationParameters.RevenueColumnName;
	FillParameters.WithoutCalculation = GenerationParameters.WithoutCalculation;
	FillParameters.BonusTable =
		Reports.CalculateCustomerRebates.RebatesForPeriodAccordingToSalesDocuments(CalculationParameters);
	
	Return FillParameters;
	
EndFunction

// Generates accrual documents based on ARM data
// 
// Parameters:
//  ProcessedDocuments - See NewTableOfAccrualDocuments
//  DataToGenerate_ - See NewDataForGeneratingAccrualDocumentsWithoutConducting
//  FillParameters - See ParametersDocumentFilling
//
Procedure GenerateAccrualDocumentsWithFollowing(ProcessedDocuments, DataToGenerate_, FillParameters)
	
	DocumentsTable = TableOfAccrualDocumentsAccordingToSystemData(FillParameters);
	
	If DataToGenerate_.FillInAccordingToSystem.Count() > 0 Then
		
		Query = New Query;
		Query.Text = QueryTextBasedOnSystemData(FillParameters.PartyCountDetails);
		Query.SetParameter("RawData", DataToGenerate_.FillInAccordingToSystem);
		Query.SetParameter("DataOfSystem", DocumentsTable);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		ProcessRequestResult(QueryResult, FillParameters, ProcessedDocuments, True);
		
	EndIf;
	
	If DataToGenerate_.FillInWithAdjustments.Count() > 0 Then
		
		Query = New Query;
		Query.Text = QueryTextWithCorrection(FillParameters.PartyCountDetails);
		Query.SetParameter("RawData", DataToGenerate_.FillInWithAdjustments);
		Query.SetParameter("DataOfSystem", DocumentsTable);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		ProcessRequestResult(QueryResult, FillParameters, ProcessedDocuments, True);
		
	EndIf;
	
	If DataToGenerate_.FillInAccordingToLineData.Count() > 0 Then
		
		Query = New Query;
		Query.Text = QueryTextBasedOnStringData(FillParameters.PartyCountDetails);
		Query.SetParameter("RawData", DataToGenerate_.FillInAccordingToLineData);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		ProcessRequestResult(QueryResult, FillParameters, ProcessedDocuments, True);
		
	EndIf;
	
	If DataToGenerate_.MarkToDelete.Count() > 0 Then
		
		Query = New Query;
		Query.Text = QueryTextMarkToDelete(FillParameters.PartyCountDetails);
		TMCommonUse.SetRequestParameters(Query, FillParameters);
		Query.SetParameter("RawData", DataToGenerate_.MarkToDelete);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		MarkAccrualDocumentsForDeletion(QueryResult, ProcessedDocuments);
		
	EndIf;
	
EndProcedure

// Parameters:
//  AccrualDocuments - See NewTableOfAccrualDocuments
//
Procedure ConductAccrualDocuments(AccrualDocuments)
	
	For Each DocumentLine In AccrualDocuments Do
		
		If Not DocumentLine.DeletionMark
		   And Not DocumentLine.Posted
		   And IsBlankString(DocumentLine.ErrorDescription) Then
			
			DocumentObject = DocumentLine.DocumentAccruals.GetObject();
			ToHoldDocumentWithFixationOfResult(DocumentObject, DocumentLine);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  DocumentObject - DocumentObject.AccrualOfCustomerRebates
//  DocumentLine - ValueTableRow: See NewTableOfAccrualDocuments
//  RecoverAmountsInCaseOfError - Boolean
// 
Procedure ToHoldDocumentWithFixationOfResult(DocumentObject, DocumentLine, RecoverAmountsInCaseOfError = False)
	
	FlagForConductingPreProcessing = DocumentObject.Posted;
	
	ResultOfCarryingOut = PostDocument(DocumentObject);
	If ResultOfCarryingOut <> Undefined Then
		
		If RecoverAmountsInCaseOfError Then
			
			DocumentLine.AmountAccrued = DocumentLine.AmountAccruedBeforeProcessing;
			DocumentLine.SettlementAmount_ = DocumentLine.AmountCalculatedBeforeProcessing;
			DocumentLine.AmountToAccrue = 0;
			
		EndIf;
		
		DocumentLine.ErrorDescription = ResultOfCarryingOut.ErrorDescription;
		DocumentLine.Messages = New FixedArray(ResultOfCarryingOut.Messages);
		
		DocumentLine.Posted = FlagForConductingPreProcessing;
		
	Else
		
		DocumentLine.Posted = True;
		
	EndIf;
	
EndProcedure

// Performs an attempt to hold the document.
//
// Parameters:
//  DocumentObject - DocumentObject.AccrualOfCustomerRebates
//
// Returns:
//  Undefined -
//  Structure:
//   * ErrorDescription - String  - text of the error description.
//   * Messages - Array of String -
//
Function PostDocument(DocumentObject)
	
	Result = Undefined;
	ExecutedSuccessfully = False;
	
	If DocumentObject.CheckFilling() Then
		
		Try
			
			DocumentObject.Write(DocumentWriteMode.Posting);
			ExecutedSuccessfully = True;
			
		Except
			
			ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
		EndTry;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Không thể kết chuyển ""%1""';
							|ru = 'Не удалось провести ""%1""';
							|en = 'Cannot post ""%1""'; fa = 'Cannot post ""%1""';
							|it = 'Impossibile registrare ""%1""';
							|pl = 'Nie udało się zatwierdzić ""%1""';
							|tr = '""%1"" kaydedilemedi'");
		PresentationOfDocument = String(DocumentObject);
		
		ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			PresentationOfDocument);
		
	EndIf;
	
	If Not ExecutedSuccessfully Then
		
		MessageTexts_ = MessageTextsDocumentEntries();
		
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorPresentation);
		Result.Insert("Messages", MessageTexts_);
		
	EndIf;
		
	Return Result;
	
EndFunction 

// Attempts to mark the document for deletion.
//
// Parameters:
//  Document - DocumentRef.AccrualOfCustomerRebates
//
// Returns:
//  Undefined -
//  Structure:
//   * ErrorDescription - String  - text of the error description.
//   * Messages - Array of String -
//
Function MarkADocumentForDeletion(Document)
	
	Result = Undefined;
	
	DocumentObject = Document.GetObject();
	
	Try
		
		DocumentObject.SetDeletionMark(True);
		
	Except
		
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		MessageTexts_ = MessageTextsDocumentEntries();
		
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorPresentation);
		Result.Insert("Messages", MessageTexts_);
		
	EndTry;
	
	Return Result;
	
EndFunction 

Function MessageTextsDocumentEntries()
	
	Session = GetCurrentInfoBaseSession();
	BackgroundJob = Session.GetBackgroundJob();
	If BackgroundJob = Undefined Then
		BackgroundJobIdentifier = Undefined;
	Else
		BackgroundJobIdentifier = BackgroundJob.UUID;
	EndIf;
	Messages = TimeConsumingOperations.UserMessages(True, BackgroundJobIdentifier);
	
	MessageTexts_ = New Array; // Array of String
	For Each Message In Messages Do
		
		MessageTexts_.Add(Message.Text);
		
	EndDo;
	
	Return MessageTexts_;
	
EndFunction

#EndRegion

#EndIf
