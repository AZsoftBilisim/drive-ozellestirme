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
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");

	EnterRentalInvestmentBalanceLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

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
	
	If TypeOf(Document) = Type("DocumentObject.EnterRentalInvestmentBalance") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableScheduleOfPaymentsForIncomeRentalServices(QueryTexts, Registers);
		QueryTextTableScheduleOfChargesForIncomeRentalServices(QueryTexts, Registers);
		QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts, Registers);
		QueryTextTableInvestmentInRent(QueryTexts, Registers);
		
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		EnterRentalInvestmentBalanceLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

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

	Return Undefined;
			
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
	
	Return KeyAttributes;
		
EndFunction

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

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.EnterRentalInvestmentBalance";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
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
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments" Then
		
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

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);

	CreateTTTableWithListOfDocuments(Query);
	GetDocumentData(Query);
	
	Query.Text =
	"SELECT
	|	DocumentData.Period  AS Period,
	|	DocumentData.Number   AS Number
	|FROM
	|	DocumentDataDetails AS DocumentData";
	
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

Procedure CreateTTTableWithListOfDocuments(Query)
	
	Query.Text =
	"SELECT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Period
	|INTO TTListOfDocuments
	|FROM
	|	Document.EnterRentalInvestmentBalance AS DocumentsList
	|WHERE
	|	DocumentsList.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	Query.Execute();
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Leaseholder AS Leaseholder,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Contract.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	VALUE(Enum.BusinessTransactions.EnterRentalInvestmentBalance) AS BusinessOperation
	|INTO DocumentDataDetails
	|FROM
	|	Document.EnterRentalInvestmentBalance AS DocumentData
	|WHERE
	|	DocumentData.Ref IN
	|			(SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentTable.RentalPayments AS RentalPayments,
	|	DocumentTable.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
	|	DocumentTable.NonGuaranteedResidualValueManag AS NonGuaranteedResidualValueManag
	|INTO DocumentDataFATable
	|FROM
	|	Document.EnterRentalInvestmentBalance.FA AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN
	|			(SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableServicePaymentSchedule
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.RentalService			AS RentalService,
	|	DocumentTable.RentalServiceVAT		AS RentalServiceVAT
	|
	|INTO DocumentDataTableServicePaymentSchedule
	|
	|FROM
	|	Document.EnterRentalInvestmentBalance.ServicePaymentSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableScheduleOfAccrualOfServices
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.RentalService			AS RentalService,
	|	DocumentTable.RentalServiceVAT		AS RentalServiceVAT
	|
	|INTO DocumentDataTableScheduleOfAccrualOfServices
	|
	|FROM
	|	Document.EnterRentalInvestmentBalance.ServiceAccrualSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableScheduleOfAccrualOfInterest
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.Interests				AS Interests
	|
	|INTO DocumentDataTableScheduleOfAccrualOfInterest
	|
	|FROM
	|	Document.EnterRentalInvestmentBalance.InterestAccrualSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.EnterRentalInvestmentBalance"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Thay đổi điều kiện chuyển giao cho thuê';
															|ru = 'Изменение условий передачи в аренду';
															|en = 'Change rental terms'; fa = 'تغییر شرایط اجاره';
															|it = 'Изменение условий передачи в аренду';
															|pl = 'Change rental terms';
															|tr = 'Kira devir şartlarının değiştirilmesi'"));
	
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses",GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherAssetsAndLiabilities",GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	ValuesOfHoldingParameters.Insert("UseTraceableImportedGoodsAccounting",GetFunctionalOption("UseTraceableImportedGoodsAccounting"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());

	ValuesOfHoldingParameters.Insert("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());

	ValuesOfHoldingParameters.Insert("BO_EnterRentalInvestmentBalance",
		Enums.BusinessTransactions.EnterRentalInvestmentBalance);
	ValuesOfHoldingParameters.Insert("SettingUpHO_EnteringBalancesOfInvestmentInRent",
		Catalogs.BusinessTransactionsSettings.EnterRentalInvestmentBalance);
		
	ValuesOfHoldingParameters.Insert("SettingUpHO_SelectionOfNGLV", Catalogs.BusinessTransactionsSettings.DefineNonGuaranteedResidualValue);
	ValuesOfHoldingParameters.Insert("SettingUpHO_AccrualOfInterestOnProfitableLeases",
		Catalogs.BusinessTransactionsSettings.AccrueProfitableRentalInterest);

	ValuesOfHoldingParameters.Insert("HO_RevaluationOfFI", Enums.BusinessTransactions.RevaluationOfFinancialInstruments);
	ValuesOfHoldingParameters.Insert("SettingUpHO_RevaluationOfFI", Catalogs.BusinessTransactionsSettings.RevaluationOfFinancialInstruments);
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

#Region RequestTextsForConducting

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	DocumentData.Date             AS Date,
	|	DocumentData.Ref           AS Ref,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.Posted         AS Posted,
	|	VALUE(Enum.BusinessTransactions.EnterRentalInvestmentBalance) AS BusinessOperation,
	|	&MetadataIdentifier         AS RefType,
	|	FATable.FixedAsset       AS FixedAsset,
	|	FALSE                             AS AdditionalRecord
	|
	|FROM
	|	Document.EnterRentalInvestmentBalance AS DocumentData
	|
	|		LEFT JOIN Document.EnterRentalInvestmentBalance.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Leaseholder AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	VALUE(Enum.BusinessTransactions.EnterRentalInvestmentBalance) AS BusinessOperation,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	DocumentData.Date AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date   AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|
	|FROM
	|	Document.EnterRentalInvestmentBalance AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableScheduleOfPaymentsForIncomeRentalServices(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfPaymentsForIncomeRentalServices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period				AS ChangeDate,
	|	DocumentData.Contract				AS Contract,
	|	DocumentData.Ref				AS EffectiveContractTerms,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.RentalService		AS RentalService,
	|	ChartTable.RentalServiceVAT	AS RentalServiceVAT
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableServicePaymentSchedule AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableScheduleOfChargesForIncomeRentalServices(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfChargesForIncomeRentalServices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period				AS ChangeDate,
	|	DocumentData.Contract				AS Contract,
	|	DocumentData.Ref				AS EffectiveContractTerms,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.RentalService		AS RentalService,
	|	ChartTable.RentalServiceVAT	AS RentalServiceVAT
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableScheduleOfAccrualOfServices AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfInterestChargesOnIncomeRental";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period				AS ChangeDate,
	|	DocumentData.Contract				AS Contract,
	|	DocumentData.Ref				AS EffectiveContractTerms,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.Interests				AS Interests
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableScheduleOfAccrualOfInterest AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInvestmentInRent(QueryTexts, Registers)
	
	RegisterName = "InvestmentInRent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	QueryTextTableTTInterestOnSchedule(QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region BalanceOnAccountOfCostOfInvestment // Dr <58.AP> - Cr <000>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)                          AS RecordType,
	|	DocumentData.Ref                                          AS Recorder,
	|	DocumentData.Period                                          AS Period,
	|	DocumentData.Organization                                     AS Organization,
	|	DocumentData.Contract                                         AS Contract,
	|	DocumentData.ARAPCurrency                            AS Currency,
	|	FATable.FixedAsset                                      AS FixedAsset,
	|	FATable.FinancialAccountingGroup                                AS FinancialAccountingGroup,
	|	FATable.RentalPayments                                       AS RentalPayments,
	|	FATable.RentalPaymentsLocal                                   AS RentalPaymentsLocal,
	|	FATable.RentalPaymentsManag                                    AS RentalPaymentsManag,
	|	0                                                               AS NonGuaranteedResidualValueLocal,
	|	0                                                               AS NonGuaranteedResidualValueManag,
	|	0                                                               AS InterestDiscount,
	|	0                                                               AS InterestDiscountMan,
	|	0                                                               AS InterestDiscountLocal,
	|	&SettingUpHO_EnteringBalancesOfInvestmentInRent                      AS BusinessTransactionSetting,
	|	FATable.RowID                                   AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|	INNER JOIN TTFATable AS FATable
	|	 ON FATable.Ref = DocumentData.Ref";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region BalanceByNGLV // Dr <58.NGLS> - Cr <000>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)                          AS RecordType,
	|	DocumentData.Ref                                          AS Recorder,
	|	DocumentData.Period                                          AS Period,
	|	DocumentData.Organization                                     AS Organization,
	|	DocumentData.Contract                                         AS Contract,
	|	DocumentData.ARAPCurrency                            AS Currency,
	|	FATable.FixedAsset                                      AS FixedAsset,
	|	FATable.FinancialAccountingGroup                                AS FinancialAccountingGroup,
	|	0                                                               AS RentalPayments,
	|	0                                                               AS RentalPaymentsLocal,
	|	0                                                               AS RentalPaymentsManag,
	|	FATable.NonGuaranteedResidualValueLocal                                              AS NonGuaranteedResidualValueLocal,
	|	FATable.NonGuaranteedResidualValueManag                                               AS NonGuaranteedResidualValueManag,
	|	0                                                               AS InterestDiscount,
	|	0                                                               AS InterestDiscountMan,
	|	0                                                               AS InterestDiscountLocal,
	|	&SettingUpHO_SelectionOfNGLV                                      AS BusinessTransactionSetting,
	|	FATable.RowID                                   AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|	INNER JOIN TTFATable AS FATable
	|	 ON FATable.Ref = DocumentData.Ref";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region InterestBalance // Dr <000> - Cr <58.%>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)                          AS RecordType,
	|	DocumentData.Ref                                          AS Recorder,
	|	DocumentData.Period                                          AS Period,
	|	DocumentData.Organization                                     AS Organization,
	|	DocumentData.Contract                                         AS Contract,
	|	DocumentData.ARAPCurrency                            AS Currency,
	|	FATable.FixedAsset                                      AS FixedAsset,
	|	FATable.FinancialAccountingGroup                                AS FinancialAccountingGroup,
	|	0                                                               AS RentalPayments,
	|	0                                                               AS RentalPaymentsLocal,
	|	0                                                               AS RentalPaymentsManag,
	|	0                                                               AS NonGuaranteedResidualValueLocal,
	|	0                                                               AS NonGuaranteedResidualValueManag,
	|	Interests.Sum                                                  AS InterestDiscount,
	|	Interests.Sum * ISNULL(Coefficients.ManConversionFactor, 0) AS InterestDiscountMan,
	|	Interests.Sum * ISNULL(Coefficients.LocalConversionRatio, 0) AS InterestDiscountLocal,
	|	&SettingUpHO_AccrualOfInterestOnProfitableLeases                AS BusinessTransactionSetting,
	|	FATable.RowID                                   AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTInterestOnSchedule AS Interests
	|		ON FATable.FixedAsset = Interests.FixedAsset
	|		AND DocumentData.Ref = Interests.Ref
	|
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON (Coefficients.Date = DocumentData.Period)
	|			AND (Coefficients.Organization = DocumentData.Organization)
	|			AND (Coefficients.ARAPCurrency = DocumentData.ARAPCurrency)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

#EndRegion

#Region GenerationOfTemporaryTablesForPosting

Procedure QueryTextTableTTFATable(QueryTexts)
	
	TableName = "TTFATable";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTCurrencyConversionFactors(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	FATable.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
	|	FATable.NonGuaranteedResidualValueManag AS NonGuaranteedResidualValueManag,
	|	FATable.RentalPayments AS RentalPayments,
	|	CAST(FATable.RentalPayments * ISNULL(Coefficients.LocalConversionRatio, 0) AS NUMBER(31, 2)) AS RentalPaymentsLocal,
	|	CAST(FATable.RentalPayments * ISNULL(Coefficients.ManConversionFactor, 0) AS NUMBER(31, 2)) AS RentalPaymentsManag,
	|	FATable.RowID AS RowID
	|INTO TTFATable
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON (Coefficients.Date = DocumentData.Period)
	|			AND (Coefficients.Organization = DocumentData.Organization)
	|			AND (Coefficients.ARAPCurrency = DocumentData.ARAPCurrency)
	|
	|INDEX BY
	|	Ref,
	|	RowID,
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTInterestOnSchedule(QueryTexts)
	
	TableName = "TTInterestOnSchedule";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Period AS Period,
	|	InterestAccrualSchedule.FixedAsset AS FixedAsset,
	|	SUM(InterestAccrualSchedule.Interests) AS Sum
	|INTO TTInterestOnSchedule
	|FROM
	|	DocumentDataTableScheduleOfAccrualOfInterest AS InterestAccrualSchedule
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON (DocumentData.Ref = InterestAccrualSchedule.Ref)
	|			AND (DocumentData.Period <= InterestAccrualSchedule.Date)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization,
	|	DocumentData.Period,
	|	InterestAccrualSchedule.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTCurrencyConversionFactors(QueryTexts)

	TableName = "TTCurrencyConversionFactors";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Period AS Date
	|INTO PeriodsTable
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|INDEX BY
	|	Organization,
	|	ARAPCurrency,
	|	Date";
	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, TableName, True);

EndProcedure

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return EnterRentalInvestmentBalanceLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

Function TextOfReflectionInLocalAccounting() Export
	
	Return EnterRentalInvestmentBalanceLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

#EndRegion

#Region Print

// Adds print commands.
// 
// Parameters:
// 	PrintCommands - See PrintManagement.CreatePrintCommandsCollection
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#EndRegion

#EndIf