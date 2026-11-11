
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	
	OBEntryOfLeaseSettlementsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Additional data sources for movements.
// 
// Parameters:
//  RegisterName - String - Register name
// 
// Returns:
//  Map - Additional data sources for movements.
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

// Generates an adapted text of the request for movements by register.
// 
// Parameters:
//  RegisterName - String - The name of the register to generate the request text for.
// 
// Returns:
//  Structure - Contains:
// 	* QueryText - String - query text.
// 	* ParameterValues - Structure - The values of the request parameters.
Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.OBEntryOfLeaseSettlements";
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RequestHasSource = True;
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ARAPCurrency", "DocumentData.Contract.ARAPCurrency");
	
	QueryText = Undefined;
	SynonymForDocumentTable = Undefined;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		RequestHasSource = False;
		
	EndIf;
				
	If QueryText = Undefined Then
		
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
		
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RequestHasSource,
										RedefiningParameterCalculation);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryOfLeaseSettlements") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers);
		QueryTextTableLeaseServicesPaymentSchedule(QueryTexts, Registers);
		QueryTextTableLeaseServicesAccrualSchedule(QueryTexts, Registers);
		QueryTextTableLeaseInterestAccrualSchedule(QueryTexts, Registers);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		OBEntryOfLeaseSettlementsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region ConductingRegulatedAccounting

// Generates the text of the reflection in the regl. accounting.
// 
// Returns:
//  String - Text of reflection in regl accounting
Function TextOfReflectionInLocalAccounting() Export

	Return OBEntryOfLeaseSettlementsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// Generates the query text of the temporary tables used for reflection in the regl. accounting.
// 
// Returns:
//  String - Query text
Function RequestTextTTReflectedInLocalAccounting() Export

	Return OBEntryOfLeaseSettlementsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object - DocumentObject.OBEntryOfLeaseSettlements, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "LineOfBusiness,AssetHolder");
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = ContractDetails_.LineOfBusiness;
	FillParameters.PurchaseOnArticles = True;
	FillParameters.LeasingPropertyOnBalanceSheet =
		(ContractDetails_.AssetHolder = Enums.LeasedAssetHolder.Leaseholder);
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for filling in VAT taxation for purchases
//
// Parameters:
//  Object - DocumentObject.OBEntryOfLeaseSettlements, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period  = Object.Date;
	
	FillParameters.RentalService = True;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the completion of VAT taxation for purchases
//
// Parameters:
//  Object - DocumentObject.OBEntryOfLeaseSettlements, FormDataStructure - the document to get parameters for.
//
// Returns:
//  Structure - See VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases
//
Function VerificationParametersFillingInDocumentOnVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	FillParameters.TabularSectionName = "FA";
	FillParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	FillParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the filling in of the document by type of activity VAT
//
// Parameters:
//  Object - DocumentObject.OBEntryOfLeaseSettlements, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  Structure - See VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity
//
Function ParametersForCheckingDocumentFillingByTypeOfActivity(Object) Export
	
	FillParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	FillParameters.TabularSectionName = "FA";
	FillParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	FillParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
		
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region FillingInAccordingToOperationalAccountingData

// Returns a table of values for filling in the balance entry document with data obtained from operational accounting data.
// 
// Parameters:
// 	Date - Date - The date on which balances are generated.
// 	BusinessOperation - EnumRef.BusinessTransactions - Business transaction for which balances are selected
// 	Companies - Array - Array containing elements of the reference Link type.Organizations for which balances are selected.
// 	AdditionalSelection - Structure - Structure containing the key and value of the additional selection.
// 	ParametersForFillingBalances - Structure - A structure that contains additional parameters that are necessary for filling in balances.
// Returns:
// 	ValueTable, Undefined - If there is data for this business operation, a table of values with fill values is returned for it.
//
Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export
	
	Result = OBEntryOfLeaseSettlementsLocalization.BalancesByTypeOfOperation(
					Date, 
					BusinessOperation, 
					Companies, 
					AdditionalSelection, 
					ParametersForFillingBalances);

	Return Result;
			
EndFunction

// Returns an array that contains the names of fields that need to be changed to generate a new document for entering balances.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which key fields are defined.
// Returns:
// 	Array - An array containing field names.
//
Function KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation) Export
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Organization");
	KeyAttributes.Add("Partner");
	KeyAttributes.Add("Counterparty");
	KeyAttributes.Add("Contract");
				
	Return KeyAttributes;
		
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)

	QueryText =
	"SELECT
	|	DocumentData.Ref                               AS Ref,
	|	DocumentData.Date                                 AS Period,
	|	DocumentData.Number                                AS Number,
	|	DocumentData.Organization                          AS Organization,
	|	DocumentData.EmployeeResponsible                        AS EmployeeResponsible,
	|	DocumentData.Comment                          AS Comment,
	|	DocumentData.Posted                             AS Posted,
	|	DocumentData.DeletionMark                      AS DeletionMark,
	|	DocumentData.DocumentID               AS DocumentID,
	|	DocumentData.PostInFinancialAndTaxAccounting                       AS PostInFinancialAndTaxAccounting,
	|	DocumentData.RecordInOperationalAccounting            AS RecordInOperationalAccounting,
	|	DocumentData.RecordInMA                          AS RecordInMA,
	|	DocumentData.Partner                              AS Partner,
	|	DocumentData.Counterparty                           AS Counterparty,
	|
	|	DocumentData.Contract                              AS Contract,
	|	DocumentData.Contract.HasSecurityDeposit    AS HasSecurityDeposit,
	|	DocumentData.Contract.ThereIsBuyoutOfLeasedAssets     AS ThereIsBuyoutOfLeasedAssets,
	|	DocumentData.Contract.LineOfBusiness      AS LineOfBusiness,
	|	DocumentData.Contract.ARAPCurrency         AS ARAPCurrency,
	|
	|	DocumentData.LeaseObligationsBalance AS LeaseObligationsBalance,
	|	DocumentData.LeaseLiabilityBalanceLocal AS LeaseLiabilityBalanceLocal,
	|	DocumentData.LeaseLiabilityBalanceMan AS LeaseLiabilityBalanceMan,
	|	DocumentData.LeaseLiabilitiesDebitBalance AS LeaseLiabilitiesDebitBalance,
	|
	|	DocumentData.BuyoutValueBalance AS BuyoutValueBalance,
	|	DocumentData.BuyoutValueBalanceLocal AS BuyoutValueBalanceLocal,
	|	DocumentData.BuyoutValueBalanceMan AS BuyoutValueBalanceMan,
	|	DocumentData.BuyoutValueDebitBalance AS BuyoutValueDebitBalance,
	|
	|	DocumentData.BuyoutDate AS BuyoutDate,
	|	DocumentData.LeaseStartDate AS LeaseStartDate,
	|	DocumentData.DateOfFirstSecurityPayment AS DateOfFirstSecurityPayment,
	|	DocumentData.DateOfFirstPayment AS DateOfFirstPayment,
	|	DocumentData.AccrualOfLeaseService AS AccrualOfLeaseService,
	|
	|	DocumentData.VATBalance AS VATBalance,
	|	DocumentData.VATBalanceLocal AS VATBalanceLocal,
	|	DocumentData.VATBalanceMan AS VATBalanceMan,
	|	DocumentData.VATDebitBalance AS VATDebitBalance,
	|
	|	DocumentData.PaymentForLeaseService AS PaymentForLeaseService,
	|	DocumentData.AccrualFrequency AS AccrualFrequency,
	|	DocumentData.PaymentFrequency AS PaymentFrequency,
	|	DocumentData.InterestRate AS InterestRate,
	|	DocumentData.InterestsBalance AS InterestsBalance,
	|	DocumentData.InterestBalanceLocal AS InterestBalanceLocal,
	|	DocumentData.InterestBalanceMan AS InterestBalanceMan,
	|	DocumentData.InterestDebitBalance AS InterestDebitBalance,
	|	DocumentData.TermDays AS TermDays,
	|	DocumentData.TermYears AS TermYears,
	|	DocumentData.TermMonths AS TermMonths,
	|	DocumentData.VATRate AS VATRate,
	|	DocumentData.VATAmount AS VATAmount,
	|	DocumentData.AmountIncludingVAT AS AmountIncludingVAT,
	|	DocumentData.Sum AS Sum,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountOfLeaseAssetsByuout AS AmountOfLeaseAssetsByuout,
	|	DocumentData.AmountOfVATRepurchaseOfRentalItems AS AmountOfVATRepurchaseOfRentalItems,
	|	DocumentData.SecurityDepositAmount AS SecurityDepositAmount,
	|	DocumentData.InterestAmount AS InterestAmount,
	|	DocumentData.LeaseServicesAmount AS LeaseServicesAmount,
	|	DocumentData.Cost AS Cost,
	|	DocumentData.FairValue AS FairValue,
	|	DocumentData.NonGuaranteedFinalCost AS NonGuaranteedFinalCost,
	|	DocumentData.PresentValue AS PresentValue,
	|	DocumentData.RentalServiceBalance AS RentalServiceBalance,
	|	DocumentData.RentalServiceBalanceLocal AS RentalServiceBalanceLocal,
	|	DocumentData.RentalServiceBalanceMan AS RentalServiceBalanceMan,
	|	DocumentData.RentalServiceDebitBalance AS RentalServiceDebitBalance,
	|	DocumentData.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|	DocumentData.VATTaxation AS VATTaxation
	|	
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.OBEntryOfLeaseSettlements"));
	ValuesOfHoldingParameters.Insert("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Nhập số dư hạch toán công nợ về thuê';
															|ru = 'Ввод остатков взаиморасчетов по аренде';
															|en = 'OB entry: rental AR/AP'; fa = 'ورود مانده افتتاحیه: دریافتنی/پرداختنی اجاره';
															|it = 'Inserimento dei saldi dei regolamenti di conti reciproci di affitto';
															|pl = 'Wprowadzenie sald rozliczeń wzajemnych z tytułu dzierżawy';
															|tr = 'Kira karşılıklı yerleşim bakiyelerinin girilmesi'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.OBEntryLeaseContractsARAP);
	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.OBEntryLeaseContractsARAP);
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		ValuesOfHoldingParameters.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Attributes.Organization, Attributes.Period));
			
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Contract                                AS Contract,
	|	&DocumentAmount                         AS Sum,
	|	&ARAPCurrency                   AS Currency,
	|	&Counterparty                             AS Counterparty,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers)

	RegisterName = "TermsOfLeaseContracts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                       AS Recorder,
	|	&Period                                       AS Period,
	|	&Contract                                      AS Contract,
	|	&SecurityDepositAmount                 AS SecurityDepositAmount,
	|	&LeaseServicesAmount                           AS LeaseServicesAmount,
	|	&AmountOfLeaseAssetsByuout                   AS AmountOfLeaseAssetsByuout,
	|	&InterestAmount                               AS InterestAmount,
	|	&VATAmount                                     AS VATAmount,
	|	&VATRate                                    AS VATRate,
	|	&TermYears                                      AS TermYears,
	|	&TermMonths                                      AS TermMonths,
	|	&TermDays                                     AS TermDays,
	|	&LeaseStartDate                             AS LeaseStartDate,
	|	&DateOfFirstPayment                           AS DateOfFirstPayment,
	|	&DateOfFirstSecurityPayment           AS DateOfFirstSecurityPayment,
	|	&BuyoutDate                                   AS BuyoutDate,
	|	&InterestRate                             AS InterestRate,
	|	&PaymentFrequency                           AS PaymentFrequency,
	|	&AccrualFrequency                      AS AccrualFrequency,
	|	&Cost                                    AS LeaseItemsCost,
	|	&PaymentForLeaseService                         AS PaymentForLeaseService,
	|	&AccrualOfLeaseService                     AS AccrualOfLeaseService,
	|	&TheInterestAccrualScheduleIsEnteredManually       AS TheInterestAccrualScheduleIsEnteredManually,
	|	&VATTaxation                           AS VATTaxation,
	|	&Ref                                       AS EffectiveContractTerms,
	|	VALUE(Enum.CounterpartyContractStates.Valid) AS State";
	
	QueryTexts.Add(QueryText, RegisterName);
		
EndProcedure

Function QueryTextTableLeaseServicesPaymentSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseServicesPaymentSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                 AS ChangeDate,
	|	&Contract                                AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	ChartTable.Date                     AS Date,
	|	ChartTable.RentalService           AS RentalService,
	|	ChartTable.RentalServiceVAT        AS RentalServiceVAT,
	|
	|	CASE 
	|		WHEN &HasSecurityDeposit
	|			THEN ChartTable.DepositPayment
	|		ELSE 0
	|	END AS DepositPayment,
	|
	|	CASE 
	|		WHEN &HasSecurityDeposit
	|			THEN ChartTable.SecurityPaymentVATAmount
	|		ELSE 0
	|	END AS SecurityPaymentVATAmount,
	|
	|	CASE 
	|		WHEN ChartTable.Date >= &BuyoutDate
	|				AND &ThereIsBuyoutOfLeasedAssets
	|			THEN ChartTable.BuyoutValue
	|		ELSE 0
	|	END AS BuyoutValue,
	|
	|	CASE 
	|		WHEN ChartTable.Date < &BuyoutDate
	|				AND &ThereIsBuyoutOfLeasedAssets
	|			THEN ChartTable.BuyoutValue
	|		ELSE 0
	|	END AS BuyoutValuePrepayment,
	|
	|	CASE 
	|		WHEN &ThereIsBuyoutOfLeasedAssets
	|			THEN ChartTable.BuyoutValueVAT
	|		ELSE 0
	|	END AS BuyoutValueVAT
	|FROM
	|	Document.OBEntryOfLeaseSettlements.ServicePaymentSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLeaseServicesAccrualSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseServicesAccrualSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                 AS ChangeDate,
	|	&Contract                                AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	ChartTable.Date                     AS Date,
	|	ChartTable.RentalService           AS RentalService,
	|	ChartTable.RentalServiceVAT        AS RentalServiceVAT,
	|
	|	CASE 
	|		WHEN &HasSecurityDeposit
	|			THEN ChartTable.DepositPayment
	|		ELSE 0
	|	END AS DepositPayment,
	|
	|	CASE 
	|		WHEN &HasSecurityDeposit
	|			THEN ChartTable.SecurityPaymentVATAmount
	|		ELSE 0
	|	END AS SecurityPaymentVATAmount,
	|
	|	CASE 
	|		WHEN &BuyoutDate = ChartTable.Date
	|				AND &ThereIsBuyoutOfLeasedAssets
	|			THEN &AmountOfLeaseAssetsByuout
	|		ELSE 0
	|	END AS BuyoutValue,
	|
	|	CASE 
	|		WHEN &BuyoutDate = ChartTable.Date
	|				AND &ThereIsBuyoutOfLeasedAssets
	|			THEN &AmountOfVATRepurchaseOfRentalItems
	|		ELSE 0
	|	END AS BuyoutValueVAT
	|FROM
	|	Document.OBEntryOfLeaseSettlements.ServiceAccrualSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                 AS ChangeDate,
	|	&Contract                                AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	&BuyoutDate                             AS Date,
	|	0                                       AS RentalService,
	|	0                                       AS RentalServiceVAT,
	|	0                                       AS DepositPayment,
	|	0                                       AS SecurityPaymentVATAmount,
	|	&AmountOfLeaseAssetsByuout             AS BuyoutValue,
	|	&AmountOfVATRepurchaseOfRentalItems          AS BuyoutValueVAT
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS DocumentData
	|
	|		LEFT JOIN Document.OBEntryOfLeaseSettlements.ServiceAccrualSchedule AS ChartTable
	|		ON ChartTable.Ref = DocumentData.Ref
	|			AND ChartTable.Date = DocumentData.BuyoutDate
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND ChartTable.Ref IS NULL
	|	AND &AmountOfLeaseAssetsByuout <> 0
	|	AND &ThereIsBuyoutOfLeasedAssets
	|	AND &BuyoutDate <> DATETIME(1, 1, 1)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableLeaseInterestAccrualSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseInterestAccrualSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                    AS ChangeDate,
	|	&Contract                   AS Contract,
	|	&Ref                    AS EffectiveContractTerms,
	|	ChartTable.Date        AS Date,
	|	ChartTable.Interests    AS Interests
	|FROM
	|	Document.OBEntryOfLeaseSettlements.InterestAccrualSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND &LeaseAccountingAccordingToFSB25_2018IsUsed";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeAnalyticsKeysForPartners(Query);
	
	QueryText = 
	"SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.LeaseLiabilitiesDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)            AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.LeaseObligationsBalance                                 AS Sum,
	|	DocumentData.LeaseLiabilityBalanceMan                              AS SumMan,
	|	DocumentData.LeaseLiabilityBalanceLocal                             AS SumCompl,
	|	
	|	&DocumentID                                                      AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (DocumentData.LeaseObligationsBalance <> 0
	|		OR DocumentData.LeaseLiabilityBalanceMan <> 0
	|		OR DocumentData.LeaseLiabilityBalanceLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.BuyoutValueDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValue)                AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.BuyoutValueBalance                                     AS Sum,
	|	DocumentData.BuyoutValueBalanceMan                                  AS SumMan,
	|	DocumentData.BuyoutValueBalanceLocal                                 AS SumCompl,
	|	
	|	&DocumentID                                                      AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (DocumentData.BuyoutValueBalance <> 0
	|		OR DocumentData.BuyoutValueBalanceMan <> 0
	|		OR DocumentData.BuyoutValueBalanceLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.VATDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.VAT)                              AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.VATBalance                                                   AS Sum,
	|	DocumentData.VATBalanceMan                                                AS SumMan,
	|	DocumentData.VATBalanceLocal                                               AS SumCompl,
	|	
	|	&DocumentID                                                      AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (DocumentData.VATBalance <> 0
	|		OR DocumentData.VATBalanceMan <> 0
	|		OR DocumentData.VATBalanceLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.InterestDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)                         AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.InterestsBalance                                              AS Sum,
	|	DocumentData.InterestBalanceMan                                           AS SumMan,
	|	DocumentData.InterestBalanceLocal                                          AS SumCompl,
	|	
	|	&DocumentID                                                      AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (DocumentData.InterestsBalance <> 0
	|		OR DocumentData.InterestBalanceMan <> 0
	|		OR DocumentData.InterestBalanceLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.RentalServiceDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	CASE
	|		WHEN DocumentData.RentalServiceDebitBalance THEN
	|			VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|		ELSE
	|			VALUE(Enum.TypesOfLeasePayments.RentalService)
	|	END                                                                        AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.RentalServiceBalance                                        AS Sum,
	|	DocumentData.RentalServiceBalanceMan                                     AS SumMan,
	|	DocumentData.RentalServiceBalanceLocal                                    AS SumCompl,
	|	
	|	&DocumentID                                                      AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (DocumentData.RentalServiceBalance <> 0
	|		OR DocumentData.RentalServiceBalanceMan <> 0
	|		OR DocumentData.RentalServiceBalanceLocal <> 0)
	|
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	DocumentData.PaymentType                                                   AS AmountType,
	|	DocumentData.ARAPDocument                                            AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	DocumentData.Sum                                                        AS Sum,
	|	DocumentData.SumMan                                                     AS SumMan,
	|	DocumentData.SumCompl                                                    AS SumCompl,
	|	
	|	DocumentData.RowID                                          AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.OBEntryOfLeaseSettlements.PrepaymentsUnderLeaseContracts AS DocumentData
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (DocumentData.Sum <> 0
	|		OR DocumentData.SumMan <> 0
	|		OR DocumentData.SumCompl <> 0)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text = "
	|SELECT DISTINCT
	|	&Organization                                           AS Organization,
	|	&Partner                                               AS Partner,
	|	&Counterparty                                            AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS DocumentData
	|		
	|		INNER JOIN Catalog.LeaseContract AS ContractData
	|		ON DocumentData.Contract = ContractData.Ref
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON Dimension.Organization = &Organization
	|			AND Dimension.Counterparty = &Counterparty
	|			AND Dimension.Partner = &Partner
	|			AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND Dimension.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|";
	
	QueryAnalyst.SetParameter("Ref",      Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);
	QueryAnalyst.SetParameter("Partner",     Query.Parameters.Partner);
	QueryAnalyst.SetParameter("Counterparty",  Query.Parameters.Counterparty);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Function QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                        AS Period,
	|	&Organization                   AS Organization,
	|	BEGINOFPERIOD(&Period, DAY)   AS DateRecord,
	|	&BusinessOperation         AS BusinessOperation
	|WHERE
	|	&Period >= &AccountingStartDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = Catalogs.LeaseContract.AddCommandToDecryptPercentageCalculation(PrintCommands);
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

#EndRegion

#Region Other

Procedure CalculateRateCostInterest(Object, ContractDetails_) Export
	
	CalculationParameters = LeasedAssetAccounting.InterestRateCalculationParameters(Object, ContractDetails_);

	If ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
		And ContractDetails_.MethodForDeterminingCostOfAssets = PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually") Then
		CalculationParameters.LeaseItemsCost = Object.FairValue - Object.NonGuaranteedFinalCost;
	Else
		CalculationParameters.LeaseItemsCost = Object.Cost;
	EndIf;

	LeasedAssetAccounting.CalculateRateCostInterest(CalculationParameters);

	Object.InterestRate = CalculationParameters.InterestRate;
	Object.InterestAmount = CalculationParameters.InterestAmount;
	Object.PresentValue = CalculationParameters.PresentValue;
	
	If CalculationParameters.ContractDetails_.MethodForDeterminingCostOfAssets = 
		Enums.MethodsOfDeterminingLeasedAssetCost.Discounting Then
		Object.Cost = CalculationParameters.LeaseItemsCost;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf