
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// To use in the procedure add a create command Based on other object Manager modules.
// Adds this object to the list of base creation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.GiftCertificateCancellation);
	
EndFunction

#EndRegion

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("GiftCertificates");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");

	GiftCertificateCancellationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of value table elements with data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.GiftCertificateCancellation") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextGiftCertificates(QueryTexts, Registers);
		QueryTextGiftCardHistory(QueryTexts, Registers);
		QueryTextTableOtherIncome(QueryTexts, Registers);
		QueryTextCounterpartyIncomeExpenses(QueryTexts, Registers);
		QueryTextTableReflectionOfDocumentsInLocalAccounting(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#Region Other

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	BusinessOperation = Enums.BusinessTransactions.GiftCertificateSale;
	
	StructuresArray = New Array();
	
	#Region AllOtherFunctions
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.ChangesPaymentPlan = True;
		
	ParametersStructure.ChangesCalculationsByString = "";
	
	ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	
	ParametersStructure.Partner                          = Catalogs.Partners.RetailCustomer;
	ParametersStructure.Counterparty                       = Catalogs.Counterparties.RetailCustomer;
	
	ParametersStructure.ARAPObjectSettings                  = "";
	
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	
	ParametersStructure.Organization                      = "Object.Organization";
	ParametersStructure.Terms                       = "";
	ParametersStructure.Contract                          = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.Date                             = "Object.Date";
	ParametersStructure.PaymentID             = "";
	ParametersStructure.Manager                         = "";
	ParametersStructure.IncomingDocumentNumber          = "";
	ParametersStructure.IncomingDocumentDate           = "";
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	Return StructuresArray;
	
EndFunction

#EndRegion

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#Region RevocationOfCertificates

// Cancel gift certificates at the end of the month
//
// Parameters:
//  CompanyArray - Array of CatalogRef.Companies
//  Period		 	  - Date - Period.
//
Procedure CancelGiftCertificatesAtEndOfMonth(CompanyArray, Period) Export
	
	If Not GetFunctionalOption("UseGiftCards") Then
		Return;
	EndIf;
	
	CheckBlockingIncomingDataWhenUpdatingInformationSecurity(NStr("vi = 'Hủy bỏ phiếu quà tặng';
																	|ru = 'Аннулирование подарочных сертификатов';
																	|en = 'Void gift card'; fa = 'ابطال کارت هدیه';
																	|it = 'Annullamento dei buoni regalo';
																	|pl = 'Anulowanie certyfikatów podarunkowych';
																	|tr = 'Hediye kuponlarının iptali'"));
	
	CancellationOfExpiredGiftCertificates(CompanyArray, EndOfMonth(Period)+1, EndOfMonth(Period));
	
EndProcedure

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return GiftCertificateCancellationLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return GiftCertificateCancellationLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

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

#Region Internal

// Selects the PS that: 
// - will be expired on a certain date (the period-of-nullification parameter) and the Cur Balance of the PS is greater than zero
// - disposable PS 2.5, the Cur Balance for which is less than the nominal value (regardless of the expiration date)
// - PS 2.5, for which there have already been other cancellations on the requested date (regardless of the expiration date)
// The collection parameter is a selection based on the transmitted set of PS. 
// Optional, if it is set, then only the transmitted PS are analyzed. Otherwise, ALL PS.
// 
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies - organizations for which the PS will be canceled.
//	CancellationPeriod - Date,PointInTime - the point in time (in the "excluding" mode)
//												for which it is required to calculate the overdue PS.
//	CollectionOfPS - Undefined,ValueTable:
//		*GiftCertificate - CatalogRef.GiftCertificates - the list of PS for which it is necessary to identify the need for cancellation.
//		*ARAPObject - CatalogRef.ARAPObjects -
//	TempTableName - String - the name in the belt table in which the resulting table will be placed. 
//	TTM - TempTablesManager,Undefined - it doesn't make sense if the time table name parameter is empty.
//	
// Returns:
//	ValueTable:
//		*Organization - CatalogRef.Companies - 
//		*GiftCertificate - CatalogRef.GiftCertificates - 
//		*ARAPObject - CatalogRef.ARAPObjects - Attributes of the gift certificate
//		*AmountInCertificateCurrency - Number - the Balance of the certificate amount to be written off "to zero"
//	is indefinite - if the time table name is filled in, then it is returned indefinitely, otherwise the VT is returned.
//
Function ExpiredGiftCertificatesForDate(Organization, Val CancellationPeriod, CollectionOfPS = Undefined,
	Val TempTableName = "", TTM = Undefined) Export
	
	Query = New Query;
	If ValueIsFilled(TempTableName) Then
		Query.TempTablesManager = TTM;
	EndIf;
	
	QueryBatch = New Array;
	PacketSeparator = "
	|
	|;/////////////////////////////////////////////////////////////////////
	|
	|";
	
	Query.Parameters.Insert("Organization", Organization);
	Query.Parameters.Insert("BoundaryOfCancellationDate", New Boundary(CancellationPeriod, BoundaryType.Excluding));
	If TypeOf(CancellationPeriod) = Type("PointInTime") Then
		Query.Parameters.Insert("CancellationDate", CancellationPeriod.Date); 
		Query.Parameters.Insert("ExpirationDateOfPS", BegOfDay(CancellationPeriod.Date));
	Else
		Query.Parameters.Insert("CancellationDate", CancellationPeriod); 
		Query.Parameters.Insert("ExpirationDateOfPS", BegOfDay(CancellationPeriod));
	EndIf;
	
	ThereIsCollectionOfPS = TypeOf(CollectionOfPS) = Type("ValueTable");
	If ThereIsCollectionOfPS Then
		
		FilterRequestText = 
		"SELECT
		|	CollectionOfPS.GiftCertificate AS GiftCertificate,
		|	CollectionOfPS.ARAPObject AS ARAPObject
		|INTO CollectionOfPS
		|FROM
		|	&CollectionOfPS AS CollectionOfPS
		|
		|INDEX BY
		|	GiftCertificate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CollectionOfPS.GiftCertificate AS Ref,
		|	CollectionOfPS.GiftCertificate.Owner AS Owner,
		|	CollectionOfPS.ARAPObject AS ARAPObject
		|INTO FilterGiftCertificates
		|FROM
		|	CollectionOfPS AS CollectionOfPS
		|
		|INDEX BY
		|	ARAPObject
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CollectionOfPS";
		QueryBatch.Add(FilterRequestText);
		Query.Parameters.Insert("CollectionOfPS", CollectionOfPS);
		
	EndIf; 
	
	
	// data on PS 2.5
	
	QueryText = 
	"SELECT
	|	CatalogLF.Ref AS GiftCertificate
	|INTO BalancesAndCancellations
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, 
	|		ARAPObject.Object REFS Catalog.GiftCertificates AND &SelectionOfObjectsOfCalculationSubstitution) AS CustomersARAPAccountingBalance
	|		INNER JOIN CatCollectionOfPS AS CatalogLF
	|			INNER JOIN Document.GiftCertificateCancellation.GiftCertificates AS PreviousCancellations
	|			ON PreviousCancellations.GiftCertificate = CatalogLF.Ref
	|		ON CustomersARAPAccountingBalance.ARAPObject = CatalogLF.ARAPObject
	|WHERE
	|	PreviousCancellations.Ref.Date <= &ExpirationDateOfPS
	|	AND PreviousCancellations.Ref.Organization IN (&Organization)
	|	AND PreviousCancellations.Ref.Posted
	|GROUP BY
	|	CatalogLF.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 123456789
	|	Activation.Organization AS Organization,
	|	CatalogLF.Ref AS GiftCertificate,
	|	CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	-CustomersARAPAccountingBalance.SumBalance AS AmountInCertificateCurrency
	|INTO OnDebiting25
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, 
	|		ARAPObject.Object REFS Catalog.GiftCertificates AND &SelectionOfObjectsOfCalculationSubstitution) AS CustomersARAPAccountingBalance
	|		INNER JOIN CatCollectionOfPS AS CatalogLF
	|			INNER JOIN Catalog.GiftCertificateKinds AS TypesOfPS
	|			ON CatalogLF.Owner = TypesOfPS.Ref
	|			INNER JOIN InformationRegister.ActivatingGiftCertificates AS Activation
	|			ON CatalogLF.Ref = Activation.GiftCertificate
	|			LEFT JOIN BalancesAndCancellations AS PreviousCancellations
	|			ON PreviousCancellations.GiftCertificate = CatalogLF.Ref
	|		ON CustomersARAPAccountingBalance.ARAPObject = CatalogLF.ARAPObject
	|WHERE
	|	CustomersARAPAccountingBalance.SumBalance < 0
	|	AND Activation.Organization IN (&Organization)
	|	AND CASE
	|		WHEN Activation.ValidityEndDate < &ExpirationDateOfPS
	|			THEN CustomersARAPAccountingBalance.SumBalance < 0
	|		WHEN NOT TypesOfPS.PartialPayment
	|			THEN TypesOfPS.Nominal > -CustomersARAPAccountingBalance.SumBalance
	|		WHEN PreviousCancellations.GiftCertificate IS NOT NULL
	|			THEN TRUE
	|	END";
	QueryText = StrReplace(QueryText, "123456789", Format(AutoCancellationMaxPS(), "NG="));
	
	If ThereIsCollectionOfPS Then
		TextOfCalculationObjectSelection = 
		"ARAPObject IN (SELECT ARAPObject FROM FilterGiftCertificates)";
		QueryText = StrReplace(QueryText, "&SelectionOfObjectsOfCalculationSubstitution", TextOfCalculationObjectSelection);
	Else
		QueryText = StrReplace(QueryText, "CatCollectionOfPS", "Catalog.GiftCertificates");
		QueryText = StrReplace(QueryText, "&SelectionOfObjectsOfCalculationSubstitution", "TRUE");
	EndIf;
	
	QueryBatch.Add(QueryText);
	
	
	// data on PS 2.4
	
	QueryText = 
	"SELECT TOP 123456789
	|	ActivatingGiftCertificates.Organization AS Organization,
	|	GiftCertificates.Ref AS GiftCertificate,
	|	GiftCertificates.ARAPObject AS ARAPObject
	|INTO GiftCertificates24
	|FROM
	|	InformationRegister.GiftCardHistory.SliceLast(&BoundaryOfCancellationDate, &SelectionOfObjectsOfCalculationSubstitution) AS
	|		GiftCardHistorySliceLast
	|		INNER JOIN Catalog.GiftCertificates AS GiftCertificates
	|			INNER JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
	|			ON (ActivatingGiftCertificates.GiftCertificate = GiftCertificates.Ref)
	|		ON (GiftCardHistorySliceLast.GiftCertificate = GiftCertificates.Ref)
	|WHERE
	|	ActivatingGiftCertificates.Organization IN (&Organization)
	|	AND GiftCardHistorySliceLast.Status IN
	|		(VALUE(Enum.GiftCertificateStatuses.Returned__),
	|		VALUE(Enum.GiftCertificateStatuses.FullyRepaid))
	|	AND NOT GiftCertificates.Owner.GiftCardAccounting25
	|	AND NOT (TRUE IN (SELECT TOP 1 TRUE FROM InformationRegister.GiftCardHistory AS HistoryOfPS WHERE
	|					HistoryOfPS.GiftCertificate = GiftCertificates.Ref
	|					AND HistoryOfPS.Period BETWEEN ActivatingGiftCertificates.ValidityStartDate AND &CancellationDate
	|					AND HistoryOfPS.Status = VALUE(Enum.GiftCertificateStatuses.Canceled_)))
	|
	|UNION ALL
	|
	|SELECT TOP 123456789
	|	ActivatingGiftCertificates.Organization AS Organization,
	|	GiftCertificates.Ref,
	|	GiftCertificates.ARAPObject AS ARAPObject
	|FROM
	|	InformationRegister.GiftCardHistory.SliceLast(&BoundaryOfCancellationDate, &SelectionOfObjectsOfCalculationSubstitution) AS
	|		GiftCardHistorySliceLast
	|		INNER JOIN Catalog.GiftCertificates AS GiftCertificates
	|			INNER JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
	|			ON (ActivatingGiftCertificates.GiftCertificate = GiftCertificates.Ref)
	|		ON GiftCardHistorySliceLast.GiftCertificate = GiftCertificates.Ref
	|WHERE
	|	ActivatingGiftCertificates.Organization IN (&Organization)
	|	AND NOT GiftCardHistorySliceLast.Status IN
	|		(VALUE(Enum.GiftCertificateStatuses.Returned__),
	|		VALUE(Enum.GiftCertificateStatuses.FullyRepaid),
	|		VALUE(Enum.GiftCertificateStatuses.Canceled_))
	|	AND ActivatingGiftCertificates.ValidityEndDate < &ExpirationDateOfPS
	|	AND NOT GiftCertificates.Owner.GiftCardAccounting25
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 123456789
	|	GiftCertificates.Organization AS Organization,
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	GiftCertificates.ARAPObject AS ARAPObject,
	|	ISNULL(GiftCertificatesBalance.SumBalance, 0) AS AmountInCertificateCurrency
	|INTO OnDebiting24
	|FROM
	|	GiftCertificates24 AS GiftCertificates
	|		LEFT JOIN AccumulationRegister.GiftCertificates.Balance(, GiftCertificate IN
	|			(SELECT
	|				T.GiftCertificate
	|			FROM
	|				GiftCertificates24 AS T)) AS GiftCertificatesBalance
	|		ON GiftCertificates.GiftCertificate = GiftCertificatesBalance.GiftCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GiftCertificates24";
	
	QueryText = StrReplace(QueryText, "123456789", Format(AutoCancellationMaxPS(), "NG="));

	If ThereIsCollectionOfPS Then
		TextOfCalculationObjectSelection = 
		"GiftCertificate IN (SELECT GiftCertificate FROM FilterGiftCertificates)";
		QueryText = StrReplace(QueryText, "&SelectionOfObjectsOfCalculationSubstitution", TextOfCalculationObjectSelection);
	Else
		QueryText = StrReplace(QueryText, "&SelectionOfObjectsOfCalculationSubstitution", "");
	EndIf;

	QueryBatch.Add(QueryText);
	
	If ThereIsCollectionOfPS Then
		QueryBatch.Add("DROP FilterGiftCertificates");
	EndIf;
	
	// Combining PS 2.4 & 2.5
		
	QueryText = 
	"SELECT DISTINCT
	|	OnDebiting.Organization AS Organization,
	|	OnDebiting.GiftCertificate AS GiftCertificate,
	|	OnDebiting.ARAPObject AS ARAPObject,
	|	OnDebiting.AmountInCertificateCurrency AS AmountInCertificateCurrency
	|INTO ReturnedTemporaryTable
	|FROM
	|	OnDebiting25 AS OnDebiting
	|
	|UNION ALL
	|
	|SELECT
	|	OnDebiting.Organization AS Organization,
	|	OnDebiting.GiftCertificate AS GiftCertificate,
	|	OnDebiting.ARAPObject AS ARAPObject,
	|	OnDebiting.AmountInCertificateCurrency AS AmountInCertificateCurrency
	|FROM
	|	OnDebiting24 AS OnDebiting
	|";
	
	If ValueIsFilled(TempTableName) Then
		QueryText = StrReplace(QueryText, "ReturnedTemporaryTable", TempTableName);
	Else
		QueryText = StrReplace(QueryText, "INTO ReturnedTemporaryTable", "");
		QueryText = QueryText + "
	|ORDER BY
	|	GiftCertificate
	|AUTOORDER";
		
	EndIf;
	
	QueryBatch.Add(QueryText);
	
	QueryBatch.Add("DROP OnDebiting24");
	QueryBatch.Add("DROP OnDebiting25");
	
	Query.Text = StrConcat(QueryBatch, PacketSeparator);

	SetPrivilegedMode(True);	
	If ValueIsFilled(TempTableName) Then
		Query.Execute();
		Return Undefined;
	Else
		Return Query.Execute().Unload();
	EndIf;
	
EndFunction

// Cancellation of gift certificates on the condition of expiration or partial repayment (for one-time).
// Parameters:
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies - the organization for which the PS will be canceled.
//	DeadlineForValidityOfPS - Date,PointInTime - the moment at which the PS are already overdue.
//	DocumentCreationDate - Date - The date that will be set for new documents. if not set, the Cur date of the session will be used.
//
Procedure CancellationOfExpiredGiftCertificates(Val Organization, Val DeadlineForValidityOfPS = Undefined, Val DocumentCreationDate = Undefined) Export
	
	If Not GetFunctionalOption("UseGiftCards") Then
		Return;
	EndIf;
	
	RequestOrganizations = New Query;
	
	RequestOrganizations.Text = 
	"SELECT DISTINCT
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog.Companies AS Companies
	|		INNER JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
	|		ON ActivatingGiftCertificates.Organization = Companies.Ref
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND &SubstitutionSelectionOrganization
	|
	|ORDER BY
	|	Organization";
	If ValueIsFilled(Organization) Then
		SubstitutionSelectionOrganization = "Companies.Ref IN (&FilterOrganization)";
		RequestOrganizations.Parameters.Insert("FilterOrganization", Organization);
	Else
		SubstitutionSelectionOrganization = "&FilterOrganization";
		RequestOrganizations.Parameters.Insert("FilterOrganization", True);
	EndIf;
	RequestOrganizations.Text = StrReplace(RequestOrganizations.Text, "&SubstitutionSelectionOrganization", SubstitutionSelectionOrganization);
	
	CollectionOfOrganizations = RequestOrganizations.Execute().Unload().UnloadColumn(0);
	
	For Each ElemOrganization In CollectionOfOrganizations Do
		
		While True Do
			
			CancellationPeriod = CurrentSessionDate();
			If Not ValueIsFilled(DeadlineForValidityOfPS) Then
				DeadlineForValidityOfPS = CancellationPeriod;
			EndIf;
	
			BoundaryDateForCalculatingExpiredGiftCertificates = DeadlineForValidityOfPS;
			If Not ValueIsFilled(DocumentCreationDate) Then
				BoundaryDateForCalculatingExpiredGiftCertificates = Max(CancellationPeriod, DeadlineForValidityOfPS);	
			EndIf;
			
			PSForCancellation = Documents.GiftCertificateCancellation.ExpiredGiftCertificatesForDate(
			ElemOrganization, BoundaryDateForCalculatingExpiredGiftCertificates);			
			
			If PSForCancellation.Count() = 0 Then
				Break;
			EndIf; 
			
			CancellationParameters = NewCreateDocumentCancellationOptions();

			CancellationParameters.DocumentDate = CancellationPeriod;
			If ValueIsFilled(DocumentCreationDate) Then
				CancellationParameters.DocumentDate = DocumentCreationDate;
			EndIf;

			CancellationParameters.Organization = ElemOrganization; 
			CancellationParameters.GiftCertificates = PSForCancellation; 
			CreateCancellationDocument(CancellationParameters);
			
			If Not IsBlankString(CancellationParameters.ErrorText) Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion
	
#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.Author AS Author,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark
	|
	|FROM
	|	Document.GiftCertificateCancellation AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                                Attributes.Period);
	Query.SetParameter("LocalAccountingCurrency",        Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",            Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("Organization",                           Attributes.Organization);
	Query.SetParameter("Manager",                              Attributes.Manager);
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.GiftCertificateCancellation);
	Query.SetParameter("MetadataIdentifier",			   Common.MetadataObjectID("Document.GiftCertificateCancellation"));
	Query.SetParameter("BusinessOperation",				   Enums.BusinessTransactions.GiftCertificateCancellation);
	Query.SetParameter("NumberForPrinting",						   ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("Number",								   Attributes.Number);
	Query.SetParameter("Author",								   Attributes.Author);
	Query.SetParameter("Comment",						   Attributes.Comment);
	Query.SetParameter("Posted",							   Attributes.Posted);
	Query.SetParameter("DeletionMark",					   Attributes.DeletionMark);

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextGiftCertificates(QueryTexts, Registers)
	
	RegisterName = "GiftCertificates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TabularSection.GiftCertificate    AS GiftCertificate,
	|	TabularSection.AmountInCertificateCurrency AS Sum,
	|	
	|	TabularSection.AmountInCertificateCurrency
	|		* ISNULL(ExchangeRatesCert.CourseNumerator, 1) / ISNULL(ExchangeRatesCert.CourseDenominator, 1)
	|		/ ISNULL(LocalCurrencyExchangeRate.CourseNumerator, 1) * ISNULL(LocalCurrencyExchangeRate.CourseDenominator, 1) AS SumCompl,
	|	TabularSection.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GiftCertificateCancellation.GiftCertificates AS TabularSection
	|	INNER JOIN Catalog.GiftCertificates AS GiftCertificates
	|	ON TabularSection.GiftCertificate = GiftCertificates.Ref	
	|	LEFT JOIN Catalog.GiftCertificateKinds AS GiftCertificateKinds
	|	ON GiftCertificates.Owner = GiftCertificateKinds.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS ExchangeRatesCert
	|	ON
	|		ExchangeRatesCert.Currency = GiftCertificateKinds.Currency
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS LocalCurrencyExchangeRate
	|	ON
	|		LocalCurrencyExchangeRate.Currency = &LocalAccountingCurrency
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND GiftCertificateKinds.GiftCardAccounting25 = FALSE
	|	AND TabularSection.AmountInCertificateCurrency <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextGiftCardHistory(QueryTexts, Registers)
	
	RegisterName = "GiftCardHistory";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period                                                          AS Period,
	|	TabularSection.GiftCertificate                              AS GiftCertificate,
	|	VALUE(Enum.GiftCertificateStatuses.Canceled_) AS Status
	|FROM
	|	Document.GiftCertificateCancellation.GiftCertificates AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.GiftCertificate.Owner.GiftCardAccounting25 = FALSE";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CertificateType_.LineOfBusiness AS LineOfBusiness,
	|	CertificateType_.IncomeItem AS IncomeItem,
	|	CertificateType_.DimensionOfRevenue AS DimensionOfRevenue,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Enum.BusinessTransactions.APWriteOff) AS BusinessOperation,
	|	
	|	CASE WHEN CertificateType_.Currency = &ManagementAccountingCurrency THEN
	|		Rows.AmountInCertificateCurrency
	|	ELSE
	|		Rows.AmountInCertificateCurrency
	|			* ISNULL(ExchangeRatesCert.CourseNumerator, 1) / ISNULL(ExchangeRatesCert.CourseDenominator, 1)
	|			/ ISNULL(ManSExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1)
	|	END AS Sum,
	|	
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting THEN 0
	|		WHEN CertificateType_.Currency = &ManagementAccountingCurrency
	|			THEN Rows.AmountInCertificateCurrency
	|		ELSE
	|			Rows.AmountInCertificateCurrency
	|				* ISNULL(ExchangeRatesCert.CourseNumerator, 1) / ISNULL(ExchangeRatesCert.CourseDenominator, 1)
	|				/ ISNULL(ManSExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1)
	|		END) AS SumMan,
	|	
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN CertificateType_.Currency = &LocalAccountingCurrency
	|			THEN Rows.AmountInCertificateCurrency
	|		ELSE
	|			Rows.AmountInCertificateCurrency
	|				* ISNULL(ExchangeRatesCert.CourseNumerator, 1) / ISNULL(ExchangeRatesCert.CourseDenominator, 1)
	|				/ ISNULL(LocalCurrencyExchangeRate.CourseNumerator, 1) * ISNULL(LocalCurrencyExchangeRate.CourseDenominator, 1)
	|		END) AS SumCompl,
	|
	|	Rows.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GiftCertificateCancellation.GiftCertificates AS Rows
	|	
	|	LEFT JOIN
	|		Catalog.GiftCertificateKinds AS CertificateType_
	|	ON
	|		CertificateType_.Ref = Rows.GiftCertificate.Owner
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS ExchangeRatesCert
	|	ON
	|		ExchangeRatesCert.Currency = CertificateType_.Currency
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS ManSExchangeRate
	|	ON
	|		ManSExchangeRate.Currency = &ManagementAccountingCurrency
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS LocalCurrencyExchangeRate
	|	ON
	|		LocalCurrencyExchangeRate.Currency = &LocalAccountingCurrency
	|
	|WHERE
	|	Rows.Ref = &Ref
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND Rows.AmountInCertificateCurrency <> 0
	|
	|ORDER BY
	|	Rows.LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextCounterpartyIncomeExpenses(QueryTexts, Registers = Undefined)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.GiftCertificateCancellation) AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Department,
	|
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CounterpartyLineOfBusiness,
	|	UNDEFINED AS Partner,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Contract,
	|	Rows.GiftCertificate AS ARAPObject,
	|
	|	CertificateType_.LineOfBusiness AS LineOfBusinessItems,
	|	CertificateType_.IncomeItem AS IncomeAndExpenseItem,
	|	CertificateType_.DimensionOfRevenue AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|
	|	CASE WHEN CertificateType_.Currency = &ManagementAccountingCurrency THEN
	|		Rows.AmountInCertificateCurrency
	|	ELSE
	|		Rows.AmountInCertificateCurrency
	|			* ISNULL(ExchangeRatesCert.CourseNumerator, 1) / ISNULL(ExchangeRatesCert.CourseDenominator, 1)
	|			/ ISNULL(ManSExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1)
	|	END AS Sum,
	|	CASE WHEN CertificateType_.Currency = &LocalAccountingCurrency THEN
	|		Rows.AmountInCertificateCurrency
	|	ELSE
	|		Rows.AmountInCertificateCurrency
	|			* ISNULL(ExchangeRatesCert.CourseNumerator, 1) / ISNULL(ExchangeRatesCert.CourseDenominator, 1)
	|			/ ISNULL(ManSExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1)
	|	END AS SumCompl,
	|
	|	0 AS AmountExcludingVAT,
	|	0 AS LocalAmountExcludingVAT,
	|
	|	CertificateType_.Currency AS Currency,
	|	Rows.AmountInCertificateCurrency AS AmountInCurrency,
	|	CertificateType_.Currency AS ARAPCurrency,
	|	Rows.AmountInCertificateCurrency AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	Rows.RowID AS FinRecordID
	|
	|FROM
	|	Document.GiftCertificateCancellation.GiftCertificates AS Rows
	|	
	|	LEFT JOIN
	|		Catalog.GiftCertificateKinds AS CertificateType_
	|	ON
	|		CertificateType_.Ref = Rows.GiftCertificate.Owner
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS ExchangeRatesCert
	|	ON
	|		ExchangeRatesCert.Currency = CertificateType_.Currency
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS ManSExchangeRate
	|	ON
	|		ManSExchangeRate.Currency = &ManagementAccountingCurrency
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS LocalCurrencyExchangeRate
	|	ON
	|		LocalCurrencyExchangeRate.Currency = &LocalAccountingCurrency
	|
	|WHERE
	|	Rows.Ref = &Ref
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND Rows.AmountInCertificateCurrency <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates

	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates =
	"SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	Table.ARAPObject AS ARAPObject,
	|	&LocalAccountingCurrency AS DocumentCurrency,
	|	&LocalAccountingCurrency AS ARAPCurrency
	|FROM
	|	Document.GiftCertificateCancellation.GiftCertificates AS Table
	|		LEFT JOIN Document.GiftCertificateCancellation AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Table.Ref IN (&Ref)";
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates, True);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);

	#EndRegion
	
	TextReturn = 
		"SELECT
		|	Table.Ref                                                                    AS Ref,
		|	Table.Ref.Organization                                                        AS Organization,
		|	Table.ARAPObject.Partner                                                    AS Partner,
		|	
		|	&LocalAccountingCurrency                                                   AS ARAPCurrency,
		|	Table.ARAPObject                                                            AS ARAPObject,
		|	
		|	Table.AmountInCertificateCurrency                                                   AS AmountARAP,
		|	Table.AmountInCertificateCurrency                                                   AS Sum,
		|	0                                                                                 AS BeingPaid,
		|	Table.Ref.Date                                                               AS RecorderDate,
		|	Table.Ref.Date                                                               AS DateOfCourse,
		|	Table.Ref.Number                                                              AS RecorderNumber,
		|
		|	VALUE(Enum.BusinessTransactions.APWriteOff)    AS BusinessOperation,
		|
		|	VALUE(Enum.PaymentForms.EmptyRef)                                   AS PaymentMethod,
		|	
		|	VALUE(Catalog.CashFlowReportItems.EmptyRef)                   AS CashFlowItem,
		|	UNDEFINED                                                                      AS ProformaInvoice,
		|	UNDEFINED                                                                      AS PaymentRequest,
		|	&LocalAccountingCurrency                                                   AS DocumentCurrency,
		|	UNDEFINED                                                                      AS LinkedDocument,
		|	Table.RowID                                                       AS FinRecordID,
		|	&BusinessTransactionSetting                                                   AS BusinessTransactionSetting
		|FROM
		|	Document.GiftCertificateCancellation.GiftCertificates AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND Table.AmountInCertificateCurrency <> 0
		|";
	
	ARAPAccountingPostingCustomers.MakingRefundToClient(Query, QueryTexts, Registers, TextReturn);
	
EndProcedure

Function QueryTextTableReflectionOfDocumentsInLocalAccounting(QueryTexts, Registers)
	RegisterName = "ReflectionOfDocumentsInLocalAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	BEGINOFPERIOD(&Period, DAY) AS DateRecord";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&Manager AS EmployeeResponsible,
	|	&Author AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	0 AS Sum,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Adapted text of the request for movements by case.
// 
// Parameters:
//  RegisterName - String -
// 
// Returns:
//  See InfobaseUpdateTM.ResultOfRequestAdaptation
//
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.GiftCertificateCancellation";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.GiftCertificateCancellation"));
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.GiftCertificateCancellation);
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
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
			QueryText, FullDocumentName, SynonymForDocumentTable, False);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region SelectionOfCancelledPS

// Parameter Designer
// 
// Returns:
//	Structure:
//		*DocumentDate - Date,PointInTime - 
//		*Organization - CatalogRef.Companies - 
//		*GiftCertificates - See Documents.GiftCertificateCancellation.ExpiredGiftCertificatesForDate
//		*ErrorText - String - returned value
//
Function NewCreateDocumentCancellationOptions()
	
	Result = New Structure;
	Result.Insert("DocumentDate", Date(1,1,1));
	Result.Insert("Organization", PredefinedValue("Catalog.Companies.EmptyRef"));
	
	PSTable = New ValueTable();
	PSTable.Columns.Add("GiftCertificate", New TypeDescription("CatalogRef.GiftCertificates"));
	PSTable.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	Result.Insert("GiftCertificates", PSTable);
	
	Result.Insert("ErrorText", "");
	
	Return Result;
	
EndFunction

// Parameters:
//	Parameters - See NewCreateDocumentCancellationOptions
Procedure CreateCancellationDocument(Parameters)
	
	DocumentObject = CreateDocument();
	DocumentObject.Organization = Parameters.Organization;
	DocumentObject.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Parameters.Organization);
	DocumentObject.Date = Parameters.DocumentDate;
	
	For Each Itm In Parameters.GiftCertificates Do
		NewString = DocumentObject.GiftCertificates.Add();
		NewString.GiftCertificate = Itm.GiftCertificate;
		NewString.ARAPObject = Itm.ARAPObject;
		NewString.AmountInCertificateCurrency = Itm.AmountInCertificateCurrency;
	EndDo;
	
	Try
		
		DocumentObject.Write(DocumentWriteMode.Posting);
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		LogParameters = New Structure("EventGroup_, Metadata, Data");
		LogParameters.EventGroup_ = NStr("vi = 'Tự động hủy phiếu quà tặng. Lỗi hủy phiếu quà tặng';
										|ru = 'Автоматическое аннулирование подарочных сертификатов. Ошибка аннулирования ПС';
										|en = 'Automatically void gift cards. Error voiding gift cards'; fa = 'Automatically void gift cards. Error voiding gift cards';
										|it = 'Annullamento automatico dei buoni regalo. Errore di annullamento PS';
										|pl = 'Automatyczne anulowanie certyfikatów podarunkowych. Błąd anulowania certyfikatów podarunkowych';
										|tr = 'Hediye kuponlarının otomatik iptali. BG''lerin geçersiz kılınması hatası'");
		
		SegmentsServer.LogRecord(LogParameters, EventLogLevel.Error, "", "", ErrorInfo);
		
		Parameters.ErrorText = ErrorProcessing.ErrorDescriptionForUser(ErrorInfo);
		
		Return;
		
	EndTry;
	
EndProcedure

// Returns:
//	Number - the maximum number of lines per document canceling the PS during autocompletion
Function AutoCancellationMaxPS()
	
	Return 10000;
	
EndFunction

#EndRegion

#Region BlockingWhenUpdatingInformationSecurity

Procedure CheckBlockingIncomingDataWhenUpdatingInformationSecurity(PresentationOperation)
	
	IncomingData = New Map;
	
	IncomingData.Insert(Metadata.AccumulationRegisters.GiftCertificates);
	IncomingData.Insert(Metadata.InformationRegisters.GiftCardHistory);
	
	MonthEndTransactionsServer.CheckBlockingIncomingDataWhenUpdatingInformationSecurity(IncomingData, PresentationOperation);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
