
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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");

	AccrualOfLeaseInterestLocalization.RegisterAccountingMechanisms(DocumentMechanisms);

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
	
	If TypeOf(Document) = Type("DocumentObject.AccrualOfLeaseInterest") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		Query.TempTablesManager = New TempTablesManager;
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);

		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableInvestmentInRent(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		
		AccrualOfLeaseInterestLocalization.AddRequestTexts(Query, QueryTexts, Registers);

	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region MonthEndTransactions

// This method creates documents for the specified month.
//
// Parameters:
//  Month		 - Date	- The month in which the interest accrual documents must be created.
//  Organization	 - CatalogRef.Companies	 - List of organizations for which documents are generated.
//  BusinessOperation - EnumRef.BusinessTransactions - Business transaction of documents.
//  DataVolume - Number - The number of processed data.
//  Cancel		 - Boolean	- Used when calling from the month closing form. When set to True, no further operations will be performed.
//
Procedure CreateDocuments(Month, Organization, BusinessOperation, DataVolume, Cancel = False) Export
	
	CheckBlockingIncomingDataWhenUpdatingInformationSecurity(NStr("vi = 'Tính lãi thuê';
																	|ru = 'Начисление процентов по аренде';
																	|en = 'Accrual of rental interest'; fa = 'تعهد بهره اجاره';
																	|it = 'Maturazione degli interessi relativi all''affitto';
																	|pl = 'Naliczenie procentów z tytułu dzierżawy';
																	|tr = 'Kiraya göre faiz tahakkuk ettirilmesi'"));
	
	QueryText =
	"SELECT
	|	RegulatoryDocument.Ref
	|FROM
	|	Document.AccrualOfLeaseInterest AS RegulatoryDocument
	|WHERE
	|	(RegulatoryDocument.Organization IN (&CompaniesList)
	|		OR &ByAllCompanies)
	|	AND RegulatoryDocument.Date BETWEEN &StartDate_1 AND &ConDate
	|	AND RegulatoryDocument.BusinessOperation = &BusinessOperation
	|	AND NOT RegulatoryDocument.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatCompanies.Ref AS Organization,
	|	MAX(CASE
	|			WHEN ISNULL(RegulatoryDocument.Posted, FALSE) = TRUE
	|				THEN RegulatoryDocument.Ref
	|			ELSE VALUE(Document.AccrualOfLeaseInterest.EmptyRef)
	|		END) AS LinkHeld,
	|	MAX(CASE
	|			WHEN ISNULL(RegulatoryDocument.Posted, UNDEFINED) = FALSE
	|				THEN RegulatoryDocument.Ref
	|			ELSE VALUE(Document.AccrualOfLeaseInterest.EmptyRef)
	|		END) AS LinkNotFound,
	|	MAX(CASE
	|			WHEN ISNULL(RegulatoryDocument.DeletionMark, FALSE) = TRUE
	|				THEN RegulatoryDocument.Ref
	|			ELSE VALUE(Document.AccrualOfLeaseInterest.EmptyRef)
	|		END) AS LinkRemoved
	|FROM
	|	Catalog.Companies AS CatCompanies
	|		LEFT JOIN Document.AccrualOfLeaseInterest AS RegulatoryDocument
	|		ON CatCompanies.Ref = RegulatoryDocument.Organization
	|			AND RegulatoryDocument.BusinessOperation = &BusinessOperation
	|			AND (RegulatoryDocument.Date >= &StartDate_1)
	|			AND (RegulatoryDocument.Date <= &ConDate)
	|WHERE
	|	(CatCompanies.Ref IN (&CompaniesList)
	|		OR &ByAllCompanies)
	|
	|GROUP BY
	|	CatCompanies.Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("StartDate_1", BegOfMonth(Month));
	Query.SetParameter("ConDate", EndOfMonth(Month));
	Query.SetParameter("CompaniesList", Organization);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Organization));
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	QueryResult = Query.ExecuteBatch();
	
	HasErrors = False;
	
	Selection = QueryResult[QueryResult.UBound()-1].Select();
	While Selection.Next() Do
		
		DocumentObject = Selection.Ref.GetObject();
		DocumentObject.AdditionalProperties.Insert("CleaningForLaterUse",True);
		Try
			DocumentObject.SetDeletionMark(True);
		Except
			
			HasErrors = True;
			
			EventName = 
				NStr("vi = 'Kết chuyển cuối tháng';
					|ru = 'Закрытие месяца';
					|en = 'Month-end closing'; fa = 'بستن پایان ماه';
					|it = 'Chiusura del mese';
					|pl = 'Zamknięcie miesiąca';
					|tr = 'Ay sonu kapanışı'", Common.DefaultLanguageCode())
				+ "."
				+ NStr("vi = 'Tính lãi thuê';
						|ru = 'Начисление процентов по аренде';
						|en = 'Accrual of rental interest'; fa = 'تعهد بهره اجاره';
						|it = 'Maturazione degli interessi relativi all''affitto';
						|pl = 'Naliczenie procentów z tytułu dzierżawy';
						|tr = 'Kiraya göre faiz tahakkuk ettirilmesi'", Common.DefaultLanguageCode());
				
			WriteLogEvent(
				EventName,
				EventLogLevel.Error,,,
				DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	
	If HasErrors Then
		Cancel = True;
		Return;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.AccrualOfLeaseInterest Then
		If Not RentalInterestIsRequired(Month, Organization) Then
			Return;
		EndIf;
	Else
		If Not AccrualOfInterestOnProfitableLeasesIsRequired(Month, Organization, Cancel) Then
			Return;
		EndIf;
	EndIf;
	
	Selection = QueryResult[QueryResult.UBound()].Select();
	While Selection.Next() Do
		
		If Selection.LinkHeld.IsEmpty()
			And Selection.LinkNotFound.IsEmpty()
			And Selection.LinkRemoved.IsEmpty() Then
			
			DocumentObject = Documents.AccrualOfLeaseInterest.CreateDocument();
			
		ElsIf Not Selection.LinkHeld.IsEmpty() Then
			
			DocumentObject = Selection.LinkHeld.GetObject();
			
		ElsIf Not Selection.LinkNotFound.IsEmpty() Then
			
			DocumentObject = Selection.LinkNotFound.GetObject();
			
		Else
			
			DocumentObject = Selection.LinkRemoved.GetObject();
			
		EndIf; 
		
		DocumentObject.Organization = Selection.Organization;
		DocumentObject.Date = EndOfMonth(Month);
		DocumentObject.EmployeeResponsible = Users.CurrentUser();
		DocumentObject.DeletionMark = False;
		DocumentObject.BusinessOperation = BusinessOperation;
		
		Try
			
			DocumentObject.Write(DocumentWriteMode.Posting);
			
		Except
			
			Cancel = True;
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			
			EventName =
				NStr("vi = 'Kết chuyển cuối tháng';
					|ru = 'Закрытие месяца';
					|en = 'Month-end closing'; fa = 'بستن پایان ماه';
					|it = 'Chiusura del mese';
					|pl = 'Zamknięcie miesiąca';
					|tr = 'Ay sonu kapanışı'", Common.DefaultLanguageCode())
				+ "."
				+ NStr("vi = 'Tính lãi thuê';
						|ru = 'Начисление процентов по аренде';
						|en = 'Accrual of rental interest'; fa = 'تعهد بهره اجاره';
						|it = 'Maturazione degli interessi relativi all''affitto';
						|pl = 'Naliczenie procentów z tytułu dzierżawy';
						|tr = 'Kiraya göre faiz tahakkuk ettirilmesi'", Common.DefaultLanguageCode());
			
			WriteLogEvent(
				EventName,
				EventLogLevel.Error,,,
				ErrorText);
			
			Raise ErrorText
			
		EndTry;
		
	EndDo;
	
EndProcedure

// Determines whether the calculation should be calculated in the specified month.
//
// Parameters:
//  Month - Date - The period being checked.
//  Organization - CatalogRef.Companies, Array - List of organizations.
// 
// Returns:
//  Boolean - True if calculation is required.
//
Function RentalInterestIsRequired(Month, Organization) Export
	
	If Not LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Month) Then
		Return False;
	EndIf;
			
	QueryText = 
	"SELECT
	|	LeaseContract.Ref AS Ref
	|INTO TTContracts
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|WHERE
	|	LeaseContract.Organization IN (&Organization)
	|		OR &ByAllCompanies
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract AS Contract,
	|	MIN(ISNULL(TermsOfLeaseAgreementsAreNotValid.Period, &EndOfMonth)) AS EndDate
	|INTO TTTermsOfContracts
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|		&EndOfPreviousMonth, 
	|		Contract IN (SELECT T.Ref FROM TTContracts AS T)) AS TermsOfLeaseContracts
	|
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseAgreementsAreNotValid
	|		ON TermsOfLeaseAgreementsAreNotValid.Contract = TermsOfLeaseContracts.Contract
	|			AND TermsOfLeaseAgreementsAreNotValid.Period >= &BegOfMonth
	|			AND TermsOfLeaseAgreementsAreNotValid.Period <= &EndOfMonth
	|			AND TermsOfLeaseAgreementsAreNotValid.State = VALUE(Enum.CounterpartyContractStates.Closed)
	|			AND TermsOfLeaseAgreementsAreNotValid.Active
	|WHERE
	|	TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|
	|GROUP BY
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract
	|
	|HAVING
	|	MIN(ISNULL(TermsOfLeaseAgreementsAreNotValid.Period, &EndOfMonth)) >= &BegOfMonth
	|
	|UNION ALL
	|
	|SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract,
	|	MIN(ISNULL(DATEADD(TermsOfLeaseAgreementsAreNotValid.Period, DAY, -1), &EndOfMonth))
	|FROM
	|	InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
	|
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseAgreementsAreNotValid
	|		ON TermsOfLeaseAgreementsAreNotValid.Contract = TermsOfLeaseContracts.Contract
	|			AND TermsOfLeaseAgreementsAreNotValid.Period > TermsOfLeaseContracts.Period
	|			AND TermsOfLeaseAgreementsAreNotValid.Period <= &EndOfMonth
	|			AND TermsOfLeaseAgreementsAreNotValid.State = VALUE(Enum.CounterpartyContractStates.Closed)
	|			AND TermsOfLeaseAgreementsAreNotValid.Active
	|WHERE
	|	TermsOfLeaseContracts.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND TermsOfLeaseContracts.Contract IN (SELECT T.Ref FROM TTContracts AS T)
	|	AND TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|	AND TermsOfLeaseContracts.Active
	|
	|GROUP BY
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract
	|
	|HAVING
	|	MIN(ISNULL(TermsOfLeaseAgreementsAreNotValid.Period, &EndOfMonth)) >= &BegOfMonth
	|
	|INDEX BY
	|	EffectiveContractTerms,
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	TTTermsOfContracts AS TTTermsOfContracts
	|		INNER JOIN InformationRegister.LeaseInterestAccrualSchedule AS Schedule
	|		ON Schedule.EffectiveContractTerms = TTTermsOfContracts.EffectiveContractTerms
	|			AND Schedule.Contract = TTTermsOfContracts.Contract
	|			AND Schedule.Date >= &BegOfMonth
	|			AND Schedule.Date <= TTTermsOfContracts.EndDate
	|			AND Schedule.Active";

	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BegOfMonth", BegOfMonth(Month));
	Query.SetParameter("EndOfMonth", EndOfMonth(Month));
	Query.SetParameter("EndOfPreviousMonth", BegOfMonth(Month)-1);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Organization));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not Result.IsEmpty();
	
EndFunction

// Defines the period starting from which you want to calculate interest.
//
// Parameters:
//  Organization   - CatalogRef.Companies - 
//  BeginOfPeriod - Date - The period being checked.
// 
// Returns:
//  Date - The date from which the calculation is required.
//
Function LeaseInterestAccrualPeriod(Organization, BeginOfPeriod) Export

	QueryText = 
	"SELECT
	|	LeaseContract.Ref AS Ref
	|INTO TTContracts
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|WHERE
	|	LeaseContract.Organization IN (&Organization)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract AS Contract,
	|	MIN(ISNULL(TermsOfLeaseAgreementsAreNotValid.Period, DATETIME(1,1,1))) AS EndDate
	|INTO TTTermsOfContracts
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(&BegOfMonth, Contract IN (SELECT T.Ref FROM TTContracts AS T)) AS TermsOfLeaseContracts
	|
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseAgreementsAreNotValid
	|		ON TermsOfLeaseAgreementsAreNotValid.Contract = TermsOfLeaseContracts.Contract
	|			AND TermsOfLeaseAgreementsAreNotValid.State = VALUE(Enum.CounterpartyContractStates.Closed)
	|			AND TermsOfLeaseAgreementsAreNotValid.Active
	|
	|GROUP BY
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract
	|
	|INDEX BY
	|	EffectiveContractTerms,	
	|	Contract	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MIN(Schedule.Date), DATETIME(1,1,1)) AS Period
	|FROM
	|	TTTermsOfContracts AS TTTermsOfContracts
	|		INNER JOIN InformationRegister.LeaseInterestAccrualSchedule AS Schedule
	|		ON Schedule.EffectiveContractTerms = TTTermsOfContracts.EffectiveContractTerms
	|			AND Schedule.Contract = TTTermsOfContracts.Contract
	|			AND Schedule.Date >= &BegOfMonth
	|			AND Schedule.Date >= &TheBeginningOfTheAccounting
	|			AND (Schedule.Date <= TTTermsOfContracts.EndDate
	|					OR TTTermsOfContracts.EndDate = DATETIME(1,1,1))
	|			AND Schedule.Active";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BegOfMonth", BegOfMonth(BeginOfPeriod));
	Query.SetParameter("TheBeginningOfTheAccounting", LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Organization));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	If Selection.Next() Then
		Return ?(ValueIsFilled(Selection.Period), BegOfMonth(Selection.Period), '000101010000');
	EndIf;

	Return '000101010000';
	
EndFunction

// Determines whether the calculation should be calculated in the specified month.
//
// Parameters:
//  Month - Date - The period being checked.
//  Organization - CatalogRef.Companies, Array - List of organizations.
// 
// Returns:
//  Boolean - True if calculation is required.
//
Function AccrualOfInterestOnProfitableLeasesIsRequired(Month, Organization, Cancel) Export
	
	If Not GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	AssetsLeasedOut.Organization AS Organization
	|INTO TTOrganizationsWithInterestAccrual
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(&EndOfPreviousMonth, ) AS AssetsLeasedOut
	|WHERE
	|	AssetsLeasedOut.Contract.ContractType IN(&TypesOfContractsUnderFSB25)
	|	AND AssetsLeasedOut.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND (AssetsLeasedOut.Organization IN (&Organization)
	|			OR &ByAllCompanies)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	AssetsLeasedOut.Organization
	|FROM
	|	InformationRegister.AssetsLeasedOut AS AssetsLeasedOut
	|WHERE
	|	AssetsLeasedOut.Contract.ContractType IN(&TypesOfContractsUnderFSB25)
	|	AND AssetsLeasedOut.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND (AssetsLeasedOut.Organization IN (&Organization)
	|			OR &ByAllCompanies)
	|	AND AssetsLeasedOut.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND AssetsLeasedOut.Active
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForCalculation.Organization AS Organization
	|FROM
	|	TTOrganizationsWithInterestAccrual AS DataForCalculation
	|		LEFT JOIN TTAccountingPolicies AS AccountingPolicies
	|		ON (AccountingPolicies.Organization = DataForCalculation.Organization)
	|WHERE
	|	ISNULL(AccountingPolicies.InterestIncomeItemOfFinancialLease, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef))
	|		= VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TRUE
	|FROM
	|	TTOrganizationsWithInterestAccrual AS DataForCalculation";

	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BegOfMonth", BegOfMonth(Month));
	Query.SetParameter("EndOfMonth", EndOfMonth(Month));
	Query.SetParameter("EndOfPreviousMonth", New Boundary(BegOfMonth(Month)-1, BoundaryType.Including));
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Organization));
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	If Not ValueIsFilled(Organization) Then
		Companies = Catalogs.Companies.AvailableCompanies(True,False);
	Else
		Companies = Organization;
	EndIf;
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		"FinancialAccountingPolicy",
		Query.TempTablesManager,
		BegOfMonth(Month),
		"TTAccountingPolicies",
		Companies);
		
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Selection = Result[1].Select();
	EventName = 
		NStr("vi = 'Kết chuyển cuối tháng';
			|ru = 'Закрытие месяца';
			|en = 'Month-end closing'; fa = 'بستن پایان ماه';
			|it = 'Chiusura del mese';
			|pl = 'Zamknięcie miesiąca';
			|tr = 'Ay sonu kapanışı'", Common.DefaultLanguageCode())
		+ "."
		+ NStr("vi = 'Tính phần trăm theo thu nhập từ cho thuê';
				|ru = 'Начисление процентов по доходной аренде';
				|en = 'Accrue profitable rental interest'; fa = 'محاسبه سود اجاره سودآور';
				|it = 'Начисление процентов по доходной аренде';
				|pl = 'Accrue profitable rental interest';
				|tr = 'Kazançlı kiralama kapsamında faiz tahakkuku'", Common.DefaultLanguageCode());
	ErrorText = NStr("vi = 'Đối với doanh nghiệp %1, chưa chỉ ra dạng thu nhập lãi đối với cho thuê tài chính trong chính sách kế toán của kế toán tài chính.';
					|ru = 'Для организации %1 не указана статья процентных доходов для финансовой аренды в учетной политике фин. учета.';
					|en = 'For the %1 company, the interest income item for finance lease is not specified in the financial accounting policy.'; fa = 'For the %1 company, the interest income item for finance lease is not specified in the financial accounting policy.';
					|it = 'Для организации %1 не указана статья процентных доходов для финансовой аренды в учетной политике фин. учета.';
					|pl = 'For the %1 company, the interest income item for finance lease is not specified in the financial accounting policy.';
					|tr = '%1 iş yeri için finansal kiralamaya ilişkin muhasebe politikasında herhangi bir faiz geliri kalemi belirtilmedi.'",
					Common.DefaultLanguageCode());
	While Selection.Next() Do
		LeasedAssetAccounting.RegisterCalculationExecutionProblem(
			Catalogs.MonthEndClosingOperations.AccrueProfitableRentalInterest,
			Month,
			Selection.Organization,
			StrTemplate(ErrorText,Selection.Organization),
			,,Cancel);
	EndDo;
	
	If Cancel Then
		Return False;
	Else
		Return Not Result[2].IsEmpty();
	EndIf;
	
EndFunction

// Defines the period starting from which you want to calculate interest.
//
// Parameters:
//  Organization   - CatalogRef.Companies - 
//  BeginOfPeriod - Date - The period being checked.
// 
// Returns:
//  Date - The date from which the calculation is required.
//
Function PeriodOfAccrualOfInterestOnProfitableLeases(Organization, BeginOfPeriod) Export

	QueryText = 
	"SELECT
	|	AssetsLeasedOut.Recorder AS EffectiveContractTerms,
	|	AssetsLeasedOut.Contract AS Contract,
	|	MIN(ISNULL(TermsOfLeaseAgreementsAreNotValid.Period, DATETIME(1,1,1))) AS EndDate
	|INTO TTTermsOfContracts
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(&BegOfMonth,Organization IN (&Organization)) AS AssetsLeasedOut
	|
	|		LEFT JOIN InformationRegister.AssetsLeasedOut AS TermsOfLeaseAgreementsAreNotValid
	|		ON TermsOfLeaseAgreementsAreNotValid.Contract = AssetsLeasedOut.Contract
	|			AND TermsOfLeaseAgreementsAreNotValid.FixedAsset = AssetsLeasedOut.FixedAsset
	|			AND TermsOfLeaseAgreementsAreNotValid.State = VALUE(Enum.FixedAssetsStates.EmptyRef)
	|			AND TermsOfLeaseAgreementsAreNotValid.Active
	|
	|WHERE
	|	AssetsLeasedOut.Contract.ContractType IN(&TypesOfContractsUnderFSB25)
	|	AND AssetsLeasedOut.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|GROUP BY
	|	AssetsLeasedOut.Recorder,
	|	AssetsLeasedOut.Contract
	|
	|INDEX BY
	|	EffectiveContractTerms,
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MIN(Schedule.Date), DATETIME(1,1,1)) AS Period
	|FROM
	|	TTTermsOfContracts AS TTTermsOfContracts
	|		INNER JOIN InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS Schedule
	|		ON Schedule.EffectiveContractTerms = TTTermsOfContracts.EffectiveContractTerms
	|			AND Schedule.Contract = TTTermsOfContracts.Contract
	|			AND Schedule.Date >= &BegOfMonth
	|			AND Schedule.Date >= &TheBeginningOfTheAccounting
	|			AND (Schedule.Date <= TTTermsOfContracts.EndDate
	|					OR TTTermsOfContracts.EndDate = DATETIME(1,1,1))
	|			AND Schedule.Active";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BegOfMonth", BegOfMonth(BeginOfPeriod));
	Query.SetParameter("TheBeginningOfTheAccounting", LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Organization));
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	If Selection.Next() Then
		Return ?(ValueIsFilled(Selection.Period), BegOfMonth(Selection.Period), '000101010000');
	EndIf;

	Return '000101010000';
	
EndFunction

#EndRegion

#Region InterfaceImplementation

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

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.AccrualOfLeaseInterest";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		RequestHasSource = False;
		
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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref           AS Ref,
	|	DocumentData.Date             AS Period,
	|	DocumentData.Number            AS Number,
	|	DocumentData.Posted         AS Posted,
	|	DocumentData.DeletionMark  AS DeletionMark,
	|	DocumentData.Comment      AS Comment,
	|	DocumentData.EmployeeResponsible    AS EmployeeResponsible,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS ComplCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.AccrualOfLeaseInterest AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
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

	AccountingPolicyOfFinancialAccounting = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Query.Parameters.Organization,
		Query.Parameters.Period);
	Query.SetParameter("InterestIncomeItemOfFinancialLease", AccountingPolicyOfFinancialAccounting.InterestIncomeItemOfFinancialLease);
	Query.SetParameter("InterestIncomeDimensionOfFinancialLease", AccountingPolicyOfFinancialAccounting.InterestIncomeDimensionOfFinancialLease);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.AccrualOfLeaseInterest"));
	ValuesOfHoldingParameters.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	ValuesOfHoldingParameters.Insert("SettingUpHO_AccrualOfInterest", Catalogs.BusinessTransactionsSettings.AccrualOfLeaseInterest);
	ValuesOfHoldingParameters.Insert("SettingUpHO_AccrualOfInterestOnProfitableLeases", Catalogs.BusinessTransactionsSettings.AccrueProfitableRentalInterest);
	ValuesOfHoldingParameters.Insert("SettingUpHO_WriteOffOfInterestOnDiscounting", Catalogs.BusinessTransactionsSettings.DiscountingInterestWriteOff);
	ValuesOfHoldingParameters.Insert("AssetAndLiabilityItem", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing);

	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Attributes.Organization, Attributes.Period));
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		ValuesOfHoldingParameters.Insert("BegOfMonth", BegOfMonth(Attributes.Period));
		ValuesOfHoldingParameters.Insert("EndOfMonth", EndOfMonth(Attributes.Period));
	
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	GenerateTTAccrualTable(Query);

	QueryAnalyst = New Query;
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);
	
	QueryAnalyst.Text = 
	"SELECT DISTINCT
	|	&Organization                                           AS Organization,
	|	AccrualTable_.Partner                              AS Partner,
	|	AccrualTable_.Counterparty                           AS Counterparty,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract
	|FROM
	|	TTAccruals AS AccrualTable_
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners  AS RegisterAccountingAnalyticsForPartners
	|		ON &Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND AccrualTable_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND AccrualTable_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract
	|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|WHERE
	|	RegisterAccountingAnalyticsForPartners.DimensionKey IS NULL";
	
	QueryResult = QueryAnalyst.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
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
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);
	QueryTextTableTTAccrualOfRentalInterest(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	AccrualTable.Period                                                AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	AccrualTable.Contract                                               AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)                    AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	AccrualTable.ARAPCurrency                                  AS Currency,
	|	
	|	AccrualTable.Sum                                                 AS Sum,
	|	AccrualTable.SumMan                                              AS SumMan,
	|	AccrualTable.SumCompl                                             AS SumCompl,
	|	
	|	&BusinessOperation                                                  AS BusinessOperation,
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)    AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,	
	|	AccrualTable.RowID                                   AS FinRecordID,
	|	&SettingUpHO_AccrualOfInterest                                        AS BusinessTransactionSetting	
	|FROM
	|	TTAccrualOfRentalInterest AS AccrualTable
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = AccrualTable.Partner
	|			AND DimensionByPartners.Counterparty = AccrualTable.Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers) Export
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTAccrualOfRentalInterest(Query, QueryTexts);
	
	Text =
	"SELECT
	|	TableExpenses.Period AS Period,
	|	VALUE(Enum.BusinessTransactions.RecordExpensesAtExpenseOfOtherAssetsLiabilities) AS BusinessOperation,
	|	&Organization AS Organization,
	|
	|	TableExpenses.Department AS Department,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	&AssetAndLiabilityItem AS AssetRef,
	|	TableExpenses.Contract AS AssetsLiabilitiesDimension,
	|
	|	TableExpenses.Department AS DebitBusinessUnit,
	|	TableExpenses.LineOfBusiness AS CorLineOfBusiness,
	|	TableExpenses.ExpenseItem AS CorItem,
	|	TableExpenses.DimensionOfExpenses AS CorExpenditureDimension,
	|	
	|	TableExpenses.SumMan AS Sum,
	|
	|	CASE
	|		WHEN TableExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|		 OR TableExpenses.SumMan = 0
	|			THEN 0
	|		ELSE
	|			TableExpenses.SumMan
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN TableExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN 0
	|		ELSE
	|			TableExpenses.SumCompl
	|	END AS SumCompl,
	|	
	|	TableExpenses.ARAPCurrency AS Currency,
	|	TableExpenses.Sum AS AmountInCurrency,
	|	UNDEFINED AS SalaryTransactionKind
	|FROM
	|	TTAccrualOfRentalInterest AS TableExpenses";
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherIncome(Query, QueryTexts, Registers)

	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	QueryTextTableTTAccrualOfInterestOnProfitableLeases(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	TableRevenue.Period                              AS Period,
	|	&Organization                                      AS Organization,
	|	TableRevenue.Department                       AS Department,
	|	TableRevenue.LineOfBusiness             AS LineOfBusiness,
	|	TableRevenue.IncomeItem                       AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue                    AS DimensionOfRevenue,
	|
	|	TableRevenue.Sum                               AS Sum,
	|	TableRevenue.SumMan                            AS SumMan,
	|	TableRevenue.SumCompl                           AS SumCompl,
	|	0                                                 AS PermanentDifference,
	|	TableRevenue.SumCompl                           AS CostTD,
	|
	|	TableRevenue.RowID                 AS FinRecordID,
	|	&BusinessOperation                            AS BusinessOperation,
	|	&SettingUpHO_AccrualOfInterestOnProfitableLeases  AS BusinessTransactionSetting
	|FROM
	|	TTAccrualOfInterestOnProfitableLeases AS TableRevenue";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableInvestmentInRent(Query, QueryTexts, Registers)
	
	RegisterName = "InvestmentInRent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTableTTAccrualOfInterestOnProfitableLeases(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	AccrualTable.Period                          AS Period,
	|	&Organization                                      AS Organization,
	|	AccrualTable.Contract                         AS Contract,
	|	AccrualTable.Currency                          AS Currency,
	|	AccrualTable.FixedAsset                AS FixedAsset,
	|	AccrualTable.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	0                                                 AS RentalPayments,
	|	0                                                 AS RentalPaymentsLocal,
	|	0                                                 AS RentalPaymentsManag,
	|	0                                                 AS NonGuaranteedResidualValueLocal,
	|	0                                                 AS NonGuaranteedResidualValueManag,
	|	AccrualTable.Sum                           AS InterestDiscount,
	|	AccrualTable.SumCompl                       AS InterestDiscountLocal,
	|	AccrualTable.SumMan                        AS InterestDiscountMan,
	|	&SettingUpHO_AccrualOfInterestOnProfitableLeases  AS BusinessTransactionSetting,
	|	AccrualTable.RowID             AS FinRecordID
	|FROM
	|	TTAccrualOfInterestOnProfitableLeases AS AccrualTable";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#Region TemporaryTablesForConducting

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	TableName = "TTInitialOtherExpenses";
	
	QueryTextTableTTAccrualOfRentalInterest(Query, QueryTexts);

	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses());
	
	QueryText = 
	"SELECT
	|	TableExpenses.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	TableExpenses.SumMan AS AmountIncludingVAT,
	|	TableExpenses.SumMan AS AmountExcludingVAT,
	|	TableExpenses.SumMan AS AmountExcludingVATMan,
	|	TableExpenses.SumCompl AS AmountIncludingVATCompl,
	|	TableExpenses.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	TableExpenses.SumCompl AS CostTD,
	|
	|	VALUE(Enum.BusinessTransactions.OtherExpenses) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TableExpenses.RowID AS FinRecordID,
	|	&SettingUpHO_AccrualOfInterest AS BusinessTransactionSetting
	|
	|FROM
	|	TTAccrualOfRentalInterest AS TableExpenses";
	ListOfMergeRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	QueryTextTableTTAccrualOfRentalInterest(Query, QueryTexts);

	QueryText = 
	"SELECT
	|	TableExpenses.Period                                       AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                      AS RecordType,
	|	&Organization                                                AS Organization,
	|	TableExpenses.Department                                AS Department,
	|	&Ref                                                     AS ExpenseReceiptDocument,
	|	TableExpenses.ExpenseItem                               AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses                            AS DimensionOfExpenses,
	|	UNDEFINED                                                AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	TableExpenses.LineOfBusiness                      AS LineOfBusiness,
	|	UNDEFINED                                                AS ItemsLocationAttributes,
	|	UNDEFINED                                                AS VATActivityType,
	|
	|	TableExpenses.SumMan                                     AS Cost,
	|	TableExpenses.SumMan                                     AS CostExcludingVAT,
	|	0                                                           AS VATManag,
	|	TableExpenses.SumCompl                                    AS LocalCost,
	|	0                                                           AS PermanentDifference,
	|	TableExpenses.SumCompl                                    AS CostTD,
	|	0                                                           AS VATLocal,
	|
	|	&BusinessOperation                                      AS BusinessOperation,
	|	
	|	TableExpenses.RowID                          AS FinRecordID,
	|	&SettingUpHO_AccrualOfInterest                            AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTAccrualOfRentalInterest AS TableExpenses";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTAccrualOfRentalInterest(Query, QueryTexts)
	
	TableName = "TTAccrualOfRentalInterest";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	GenerateTTAccrualTable(Query);
	QueryTextTableTTCurrencyConversionFactors(Query, QueryTexts);

	QueryText =
	"SELECT
	|	AccrualTable_.Date AS Period,
	|	AccrualTable_.Contract AS Contract,
	|	AccrualTable_.Partner AS Partner,
	|	AccrualTable_.Counterparty AS Counterparty,
	|	AccrualTable_.Department AS Department,
	|	AccrualTable_.ARAPCurrency AS ARAPCurrency,
	|	AccrualTable_.ExpenseItem AS ExpenseItem,
	|	AccrualTable_.DimensionOfExpenses AS DimensionOfExpenses,
	|	AccrualTable_.LineOfBusiness AS LineOfBusiness,
	|
	|	AccrualTable_.Sum AS Sum,
	|
	|	CASE
	|		WHEN CAST(AccrualTable_.Contract AS Catalog.LeaseContract).RecognizeLeasedAssetsInManagementAccounting
	|			THEN CAST(AccrualTable_.Sum * ISNULL(Coefficients.ManConversionFactor, 0) AS NUMBER(31,2))
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN CAST(AccrualTable_.Contract AS Catalog.LeaseContract).RecognizeLeasedItemsInLocalAccounting
	|			THEN CAST(AccrualTable_.Sum * ISNULL(Coefficients.LocalConversionRatio, 0) AS NUMBER(31,2))
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	AccrualTable_.RowID AS RowID
	|
	|INTO TTAccrualOfRentalInterest
	|FROM
	|	TTAccruals AS AccrualTable_
	|
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.ARAPCurrency = AccrualTable_.ARAPCurrency
	|			AND Coefficients.Date = AccrualTable_.Date";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTCurrencyConversionFactors(Query, QueryTexts)
	
	TableName = "TTCurrencyConversionFactors";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	GenerateTTAccrualTable(Query);
	GenerateTableOfTTAccrualsForProfitableLeases(Query);

	QueryText = 
	"SELECT DISTINCT
	|	AccrualTable_.ARAPCurrency AS ARAPCurrency,
	|	AccrualTable_.Date AS Date
	|INTO PeriodsTable
	|FROM
	|	TTAccruals AS AccrualTable_
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	AccrualTable_.ARAPCurrency,
	|	AccrualTable_.Date
	|FROM
	|	TTAccrualsForProfitableLeases AS AccrualTable_
	|
	|INDEX BY
	|	ARAPCurrency,
	|	Date";
	
	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, TableName);
	
EndProcedure

Procedure GenerateTTAccrualTable(Query) Export
	
	TableName = "TTAccruals";
	
	If Query.TempTablesManager.Tables.Find(TableName) <> Undefined Then
		Return;
	EndIf;

	QueryText =
	"SELECT
	|	LeaseContract.Ref AS Ref
	|INTO TTContracts
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|WHERE
	|	LeaseContract.Organization = &Organization
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AccrualOfLeaseInterest)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract AS Contract,
	|	TermsOfLeaseContracts.DateOfConditions AS DateOfConditions,
	|	MAX(TermsOfLeaseContracts.Period) AS Period
	|INTO TTLeaseContractTermsForPeriod
	|FROM
	|	(SELECT
	|		TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|		TermsOfLeaseContracts.Contract AS Contract,
	|		TermsOfLeaseContracts.Period AS DateOfConditions,
	|		MIN(ISNULL(TermsOfLeaseAgreementsAreNotValid.Period, &EndOfMonth)) AS Period
	|	FROM
	|		InformationRegister.TermsOfLeaseContracts.SliceLast(&BegOfMonth, Contract IN
	|			(SELECT
	|				TTContracts.Ref
	|			FROM
	|				TTContracts AS TTContracts)) AS TermsOfLeaseContracts
	|			LEFT JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseAgreementsAreNotValid
	|			ON (TermsOfLeaseAgreementsAreNotValid.Contract = TermsOfLeaseContracts.Contract)
	|			AND (TermsOfLeaseAgreementsAreNotValid.Period >= &BegOfMonth)
	|			AND (TermsOfLeaseAgreementsAreNotValid.Period <= &EndOfMonth)
	|			AND (TermsOfLeaseAgreementsAreNotValid.Active)
	|	WHERE
	|		(TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|			OR TermsOfLeaseContracts.Recorder REFS Document.LeaseTermAdjustment
	|				AND TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Closed))
	|	GROUP BY
	|		TermsOfLeaseContracts.EffectiveContractTerms,
	|		TermsOfLeaseContracts.Contract,
	|		TermsOfLeaseContracts.Period
	|
	|	UNION ALL
	|
	|	SELECT
	|		TermsOfLeaseContracts.EffectiveContractTerms,
	|		TermsOfLeaseContracts.Contract,
	|		TermsOfLeaseContracts.Period,
	|		MIN(ISNULL(TermsOfLeaseAgreementsAreNotValid.Period, &EndOfMonth))
	|
	|	FROM
	|		InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
	|
	|			LEFT JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseAgreementsAreNotValid
	|			ON TermsOfLeaseAgreementsAreNotValid.Contract = TermsOfLeaseContracts.Contract
	|				AND TermsOfLeaseAgreementsAreNotValid.Period > TermsOfLeaseContracts.Period
	|				AND TermsOfLeaseAgreementsAreNotValid.Period <= &EndOfMonth
	|				AND TermsOfLeaseAgreementsAreNotValid.Active
	|	WHERE
	|		TermsOfLeaseContracts.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND TermsOfLeaseContracts.Contract IN
	|			(SELECT
	|				TTContracts.Ref
	|			FROM
	|				TTContracts AS TTContracts)
	|		AND (TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|			OR TermsOfLeaseContracts.Recorder REFS Document.LeaseTermAdjustment
	|				AND TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Closed))
	|		AND TermsOfLeaseContracts.Active
	|
	|	GROUP BY
	|		TermsOfLeaseContracts.EffectiveContractTerms,
	|		TermsOfLeaseContracts.Contract,
	|		TermsOfLeaseContracts.Period
	|	) AS TermsOfLeaseContracts
	|
	|GROUP BY
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract,
	|	TermsOfLeaseContracts.DateOfConditions
	|
	|INDEX BY
	|	EffectiveContractTerms,
	|	Contract,
	|	DateOfConditions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTermsOfLeaseAgreements.Contract AS Contract,
	|	MAX(TTTermsOfLeaseAgreements.DateOfConditions) AS DateOfConditions
	|INTO TTOfCurrentTermsAndConditionsDate
	|FROM
	|	TTLeaseContractTermsForPeriod AS TTTermsOfLeaseAgreements
	|
	|GROUP BY
	|	TTTermsOfLeaseAgreements.Contract
	|
	|INDEX BY
	|	Contract,
	|	DateOfConditions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTermsOfLeaseAgreements.EffectiveContractTerms AS EffectiveContractTerms,
	|	TTTermsOfLeaseAgreements.Contract AS Contract,
	|	TTTermsOfLeaseAgreements.Period AS Period
	|INTO TTTermsOfLeaseAgreements
	|FROM
	|	TTLeaseContractTermsForPeriod AS TTTermsOfLeaseAgreements
	|		INNER JOIN TTOfCurrentTermsAndConditionsDate AS TTOfCurrentTermsAndConditionsDate
	|		ON TTTermsOfLeaseAgreements.Contract = TTOfCurrentTermsAndConditionsDate.Contract
	|		AND TTTermsOfLeaseAgreements.DateOfConditions = TTOfCurrentTermsAndConditionsDate.DateOfConditions
	|
	|INDEX BY
	|	EffectiveContractTerms,
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Schedule.Date AS Date,
	|	Schedule.Contract AS Contract,
	|	Schedule.Contract.Partner AS Partner,
	|	Schedule.Contract.Counterparty AS Counterparty,
	|	Schedule.Contract.BusinessUnitInterest AS Department,
	|	Schedule.Contract.ExpenseItemInterest AS ExpenseItem,
	|	Schedule.Contract.ExpensesDimensionInterest AS DimensionOfExpenses,
	|	Schedule.Contract.LineOfBusiness AS LineOfBusiness,
	|	Schedule.Contract.ARAPCurrency AS ARAPCurrency,
	|	Schedule.Interests AS Sum,
	|	RECORDAUTONUMBER() AS RecNo
	|
	|INTO TTAccruals
	|FROM
	|	TTTermsOfLeaseAgreements AS TTTermsOfLeaseAgreements
	|		INNER JOIN InformationRegister.LeaseInterestAccrualSchedule AS Schedule
	|		ON Schedule.EffectiveContractTerms = TTTermsOfLeaseAgreements.EffectiveContractTerms
	|			AND Schedule.Contract = TTTermsOfLeaseAgreements.Contract
	|			AND Schedule.Date >= &BegOfMonth
	|			AND Schedule.Date <= TTTermsOfLeaseAgreements.Period
	|			AND Schedule.Interests <> 0
	|			AND Schedule.Active
	|
	|INDEX BY
	|	Date, ARAPCurrency";
	
	NewQuery = New Query(QueryText);
	NewQuery.TempTablesManager = Query.TempTablesManager;
	NewQuery.SetParameter("Period", Query.Parameters.Period);
	NewQuery.SetParameter("Organization", Query.Parameters.Organization);
	NewQuery.SetParameter("BegOfMonth", Query.Parameters.BegOfMonth);
	NewQuery.SetParameter("EndOfMonth", Query.Parameters.EndOfMonth);
	NewQuery.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	
	NewQuery.Execute();
	
	TMCommonUse.AddIDsToTemporaryTable(TableName, Query.TempTablesManager);
	
EndProcedure

Procedure QueryTextTableDocumentDataDetails(QueryTexts)
	
	TableName = "DocumentDataDetails";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Ref AS Ref
	|INTO DocumentDataDetails
	|
	|INDEX BY
	|	Ref";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTAccrualOfInterestOnProfitableLeases(Query, QueryTexts)
	
	TableName = "TTAccrualOfInterestOnProfitableLeases";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	GenerateTableOfTTAccrualsForProfitableLeases(Query);
	QueryTextTableTTCurrencyConversionFactors(Query, QueryTexts);
	QueryTextTableDocumentDataDetails(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTAccrualsForProfitableLeases", "TTAccountingFA");
	QueryTextTablePeriodReturnsTT(Query, QueryTexts);
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"FixedAssetsAccountingProcedure", "TTFAAccountingProcedureBeforeReturns", "PeriodReturnsTT", QueryTexts,, False);
	
	QueryText =
	"SELECT
	|	AccrualTable_.Date AS Period,
	|	AccrualTable_.Contract AS Contract,
	|	AccrualTable_.ARAPCurrency AS Currency,
	|	AccrualTable_.FixedAsset AS FixedAsset,
	|	ISNULL(FAAccountingProcedureBeforeReturns.FinancialAccountingGroup,FixedAssetsAccountingProcedure.FinancialAccountingGroup) AS FinancialAccountingGroup,
	|	AccrualTable_.Contract.Department AS Department,
	|	AccrualTable_.Contract.LineOfBusiness AS LineOfBusiness,
	|	AccrualTable_.IncomeItem AS IncomeItem,
	|	AccrualTable_.DimensionOfRevenue AS DimensionOfRevenue,
	|
	|	AccrualTable_.Sum AS Sum,
	|	CAST(AccrualTable_.Sum * ISNULL(Coefficients.ManConversionFactor, 0) AS NUMBER(31,2)) AS SumMan,
	|	CAST(AccrualTable_.Sum * ISNULL(Coefficients.LocalConversionRatio, 0) AS NUMBER(31,2)) AS SumCompl,
	|
	|	AccrualTable_.RowID AS RowID
	|
	|INTO TTAccrualOfInterestOnProfitableLeases
	|FROM
	|	TTAccrualsForProfitableLeases AS AccrualTable_
	|
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.ARAPCurrency = AccrualTable_.ARAPCurrency
	|			AND Coefficients.Date = AccrualTable_.Date
	|		INNER JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON AccrualTable_.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset
	|		LEFT JOIN TTFAAccountingProcedureBeforeReturns AS FAAccountingProcedureBeforeReturns
	|		ON AccrualTable_.FixedAsset = FAAccountingProcedureBeforeReturns.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure GenerateTableOfTTAccrualsForProfitableLeases(Query) Export
	
	TableName = "TTAccrualsForProfitableLeases";
	
	If Query.TempTablesManager.Tables.Find(TableName) <> Undefined Then
		Return;
	EndIf;

	QueryText = 
		"SELECT
		|	AssetsLeasedOutSliceLast.FixedAsset AS FixedAsset,
		|	CAST(AssetsLeasedOutSliceLast.Contract AS Catalog.CounterpartyContracts) AS Contract
		|INTO TTLeasedToFA
		|FROM
		|	InformationRegister.AssetsLeasedOut.SliceLast(
		|			&EndOfPreviousMonth,
		|			Organization = &Organization
		|				AND Contract REFS Catalog.CounterpartyContracts) AS AssetsLeasedOutSliceLast
		|WHERE
		|	AssetsLeasedOutSliceLast.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
		|	AND CAST(AssetsLeasedOutSliceLast.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
		|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AccrueProfitableRentalInterest)
		|
		|UNION ALL
		|
		|SELECT
		|	AssetsLeasedOut.FixedAsset AS FixedAsset,
		|	CAST(AssetsLeasedOut.Contract AS Catalog.CounterpartyContracts) AS Contract
		|FROM
		|	InformationRegister.AssetsLeasedOut AS AssetsLeasedOut
		|WHERE
		|	AssetsLeasedOut.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
		|	AND Organization = &Organization
		|	AND Contract REFS Catalog.CounterpartyContracts
		|	AND CAST(AssetsLeasedOut.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
		|	AND AssetsLeasedOut.Active
		|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AccrueProfitableRentalInterest)
		|
		|INDEX BY
		|	Contract,
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Schedule.Contract AS Contract,
		|	Schedule.FixedAsset AS FixedAsset,
		|	MAX(Schedule.ChangeDate) AS ChangeDate
		|INTO TTCurrentCharts
		|FROM
		|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS Schedule
		|WHERE
		|	(Schedule.Contract, Schedule.FixedAsset) IN
		|			(SELECT
		|				TTLeasedToFA.Contract AS Contract,
		|				TTLeasedToFA.FixedAsset AS FixedAsset
		|			FROM
		|				TTLeasedToFA AS TTLeasedToFA)
		|	AND Schedule.Active
		|	AND Schedule.ChangeDate <= &EndOfMonth
		|
		|GROUP BY
		|	Schedule.Contract,
		|	Schedule.FixedAsset
		|
		|INDEX BY
		|	Contract,
		|	FixedAsset,
		|	ChangeDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Schedule.Contract AS Contract,
		|	Schedule.FixedAsset AS FixedAsset,
		|	&EndOfMonth AS Date,
		|	SUM(Schedule.Interests) AS Interests
		|INTO TTInterestSchedule
		|FROM
		|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS Schedule
		|WHERE
		|	(Schedule.Contract, Schedule.FixedAsset, Schedule.ChangeDate) IN
		|			(SELECT
		|				TTCurrentCharts.Contract AS Contract,
		|				TTCurrentCharts.FixedAsset AS FixedAsset,
		|				TTCurrentCharts.ChangeDate AS ChangeDate
		|			FROM
		|				TTCurrentCharts AS TTCurrentCharts)
		|	AND Schedule.Interests <> 0
		|	AND Schedule.Date BETWEEN &BegOfMonth AND &EndOfMonth
		|	AND Schedule.Active
		|	AND Schedule.ChangeDate <= &EndOfMonth
		|
		|GROUP BY
		|	Schedule.Contract,
		|	Schedule.FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&Ref AS Ref,
		|	Schedule.Date AS Date,
		|	Schedule.Contract AS Contract,
		|	Schedule.Contract.ARAPCurrency AS ARAPCurrency,
		|	Schedule.FixedAsset AS FixedAsset,
		|	Schedule.Interests AS Sum,
		|	&InterestIncomeItemOfFinancialLease AS IncomeItem,
		|	CASE
		|		WHEN &FillInAnalyticsWithRentalItem THEN
		|			Schedule.FixedAsset
		|	ELSE
		|			&InterestIncomeDimensionOfFinancialLease
		|	END AS DimensionOfRevenue,
		|	RECORDAUTONUMBER() AS RecNo
		|INTO TTAccrualsForProfitableLeases
		|FROM
		|	TTInterestSchedule AS Schedule
		|
		|INDEX BY
		|	Ref,
		|	Date,
		|	ARAPCurrency";
	
	NewQuery = New Query(QueryText);
	NewQuery.TempTablesManager = Query.TempTablesManager;
	NewQuery.SetParameter("Ref", Query.Parameters.Ref);
	NewQuery.SetParameter("Organization", Query.Parameters.Organization);
	NewQuery.SetParameter("BegOfMonth", Query.Parameters.BegOfMonth);
	NewQuery.SetParameter("EndOfMonth", Query.Parameters.EndOfMonth);
	NewQuery.SetParameter("EndOfPreviousMonth", 
		New Boundary(BegOfMonth(Query.Parameters.BegOfMonth)-1, BoundaryType.Including));
	NewQuery.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	NewQuery.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	NewQuery.SetParameter("InterestIncomeItemOfFinancialLease",
		Query.Parameters.InterestIncomeItemOfFinancialLease);
	NewQuery.SetParameter("InterestIncomeDimensionOfFinancialLease",
		Query.Parameters.InterestIncomeDimensionOfFinancialLease); 
	ValueType = Common.ObjectAttributeValue(Query.Parameters.InterestIncomeItemOfFinancialLease, "ValueType");
	NewQuery.SetParameter("FillInAnalyticsWithRentalItem",
		ValueType = New TypeDescription("CatalogRef.Assets")
			And Not ValueIsFilled(Query.Parameters.InterestIncomeDimensionOfFinancialLease));
	
	NewQuery.Execute();
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager,
		"TTInterestSchedule,TTCurrentCharts,TTLeasedToFA",);
	TMCommonUse.AddIDsToTemporaryTable(TableName, Query.TempTablesManager);
	
EndProcedure

Procedure QueryTextTablePeriodReturnsTT(Query, QueryTexts) Export
	
	TableName = "PeriodReturnsTT";
	
	If Query.TempTablesManager.Tables.Find(TableName) <> Undefined Then
		Return;
	EndIf;

	QueryText = 
	"SELECT
	|	Returns.Date AS Period,
	|	Returns.Ref AS Ref,
	|	ReturnsFA.FixedAsset AS FixedAsset
	|INTO PeriodReturnsTT
	|FROM
	|	Document.ReturnAssetsFromLeasee2_4 AS Returns
	|		INNER JOIN Document.ReturnAssetsFromLeasee2_4.FA AS ReturnsFA
	|		ON Returns.Ref = ReturnsFA.Ref
	|		INNER JOIN TTAccrualsForProfitableLeases AS Accruals
	|		ON Accruals.FixedAsset = ReturnsFA.FixedAsset
	|			AND Accruals.Contract = Returns.Contract
	|WHERE
	|	Returns.Posted
	|
	|INDEX BY
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return AccrualOfLeaseInterestLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return AccrualOfLeaseInterestLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region BlockingWhenUpdatingInformationSecurity

Procedure CheckBlockingIncomingDataWhenUpdatingInformationSecurity(PresentationOperation)
	
	IncomingData = New Map;
	
	IncomingData.Insert(Metadata.InformationRegisters.LeaseInterestAccrualSchedule);
	IncomingData.Insert(Metadata.InformationRegisters.ScheduleOfInterestChargesOnIncomeRental);
	IncomingData.Insert(Metadata.Catalogs.LeaseContract);
	IncomingData.Insert(Metadata.Documents.AccrualOfLeaseInterest);
	
	MonthEndTransactionsServer.CheckBlockingIncomingDataWhenUpdatingInformationSecurity(IncomingData, PresentationOperation);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
