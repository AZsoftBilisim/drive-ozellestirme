
#Region Public

// Returns a structure with gift certificate data for the end of the day of the Cur session date, including the border.
//
// Parameters:
//  GiftCertificate - CatalogRef.GiftCertificates - Gift certificate.
//  GiftCertificateKind - CatalogRef.GiftCertificateKinds - The form of a gift certificate.
//
// Returns:
//  See GiftCertificatesServerCall.InitializeGiftCertificateDescription
//
Function GetGiftCertificateDetails(GiftCertificate, GiftCertificateKind = Undefined) Export
	
	MapDataStructure = InitializeGiftCertificateDescription();
	
	Query = New Query(TextOfRequestToReceiveGiftCertificateData());
	
	Query.SetParameter("Ref", GiftCertificate);
	Query.SetParameter("GiftCertificateKind", GiftCertificateKind);
	CurrentSessionDate = CurrentSessionDate();
	BorderCurDateEndOfDay = New Boundary(EndOfDay(CurrentSessionDate), BoundaryType.Including);
	Query.SetParameter("BorderCurDateEndOfDay", BorderCurDateEndOfDay);
	Query.SetParameter("CurrentDate", CurrentSessionDate);
	Query.SetParameter("CurrentDocument", Undefined);
	
	SetPrivilegedMode(True);
	Result = Query.Execute(); // QueryResult
	Selection = Result.Select();
	
	If Selection.Next() Then
		FillPropertyValues(MapDataStructure, Selection);
	EndIf;
	
	Return MapDataStructure;
	
EndFunction

// Returns a match where the key is a link to the Gift Certificates Catalog 
// and the value is a structure with gift certificate data.
//
// Parameters:
//  GiftCertificates - Array of CatalogRef.GiftCertificates - Gift certificate.
//  CurrentDate - Date, Undefined - If a date is passed, the Balances and a slice of the last ones will be calculated at the end of the day, including the border,
//										otherwise the end of the day of the Cur session date will be used.
//  CurrentDocument - DocumentRef, Undefined - If a link is passed, the Balances and a slice of the latter will be calculated at the time excluding the border;
//													However, if the value of the current date is not set, the current session date will be used.
//
// Returns:
//  Map of KeyAndValue:
//  * Key - CatalogRef.GiftCertificates
//  * Value - See GiftCertificatesServerCall.InitializeGiftCertificateDescription
//
Function GetGiftCertificatesDetails(GiftCertificates, CurrentDate = Undefined, CurrentDocument = Undefined) Export
		
	ResultData = New Map();
	If GiftCertificates.Count() Then
		Query = New Query(TextOfRequestToReceiveGiftCertificateData());
		
		Query.SetParameter("Ref", GiftCertificates);
		Query.SetParameter("GiftCertificateKind", Undefined);
		CurrentSessionDate = CurrentSessionDate();
		If ValueIsFilled(CurrentDate) Then
			CurrentSessionDate = CurrentDate;
		EndIf;
		BorderCurDateEndOfDay = New Boundary(EndOfDay(CurrentSessionDate), BoundaryType.Including);
		CurCurrentDocumentLink = Undefined;
		If ValueIsFilled(CurrentDocument) Then
			CurCurrentDocumentLink = CurrentDocument;
			// If you passed a link to the document, then the border excludes the boundary value.
			BorderCurDateEndOfDay = New Boundary(New PointInTime(CurrentSessionDate, CurrentDocument), BoundaryType.Excluding);
		EndIf;
		
		Query.SetParameter("CurrentDate", CurrentSessionDate);
		Query.SetParameter("BorderCurDateEndOfDay", BorderCurDateEndOfDay);
		Query.SetParameter("CurrentDocument", CurCurrentDocumentLink);
		
		SetPrivilegedMode(True);
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			MapDataStructure = InitializeGiftCertificateDescription();
			FillPropertyValues(MapDataStructure, Selection);
			ResultData.Insert(Selection.Ref, MapDataStructure);
		EndDo;
	EndIf;
	
	Return ResultData;

EndFunction

// Returns the parameter structure that is used when processing the gift certificate code.
//
// Returns:
//  Structure - structure with properties: 
//   * Filters - Structure - Additional selections when searching for gift certificates; 
//							It can have properties, for example: Organization, Status, Currency, accountingparticipations2_5;
//							if the Register New property is set to True, then in the method of the server's gift certificate. 
//							The Status field is disabled for processing the received server code, since it is not a key one for checking the uniqueness of the gift certificate.
//   * RegisterNewOnes - Boolean - The need to register gift certificates that were not found by code.
//
Function ParametersForProcessingReceivedCode() Export
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("Filters", New Structure);
	ProcessingParameters.Insert("RegisterNewOnes", True);
	
	Return ProcessingParameters;
	
EndFunction
	
// The function returns an empty gift certificate data structure.
//
// Returns:
//  Structure - structure with properties:
//   * Ref - CatalogRef.GiftCertificates - Gift certificate.
//   * Barcode - String - barcode.
//   * MagneticCode - String - Magnetic code.
//   * SerialNumber - String - Serial number.
//   * GiftCertificateKind - CatalogRef.GiftCertificateKinds - The form of a gift certificate.
//   * PartialPayment - Boolean - If True, then the certificate is reusable
//   * Description - String - Name of the gift certificate.
//   * CardType - EnumRef.CardTypes - Type of card.
//   * ActivationStatus - Boolean - Status of gift certificate activation.
//   * StatusFromHistoryOfGiftCertificates - EnumRef.GiftCertificateStatuses - Gift certificate Status from the Gift Certificate History register.
//   * Canceled_ - Boolean - Indicates that the certificate has been revoked.
//   * RefundIssued - Boolean - Indicates that the certificate was returned.
//   * Nominal - Number - The value of the gift certificate.
//   * Balance - Number - The remaining value of the gift certificate.
//   * Currency - CatalogRef.Currencies - Currency of the gift certificate.
//   * ProductSegment - CatalogRef.ProductSegments - Segment of the gift certificate item.
//   * ActionPeriod - EnumRef.Periodicity - The validity period of the gift certificate.
//   * NumberOfValidityPeriods - Number - Number of validity periods.
//   * ValidityStartDate - Date - Date of commencement of the action.
//   * ValidityEndDate - Date - Expiration date.
//   * ARAPObject - CatalogRef.ARAPObjects - The object of the calculations
//   * Partner - CatalogRef.Partners - Partner from the settlement object
//   * CashFlowItemSale - CatalogRef.CashFlowReportItems - 
//   * CashFlowItemReturn - CatalogRef.CashFlowReportItems - 
//   * IncomeItem - ChartOfCharacteristicTypesRef.IncomeItems - 
//   * DimensionOfRevenue - Characteristic.IncomeItems -
//   * InformationAboutTypeOfGiftCertificateIsFilledIn - Boolean
//
Function InitializeGiftCertificateDescription() Export
	
	StructureOfData = New Structure;
	
	StructureOfData.Insert("Ref");
	StructureOfData.Insert("Barcode");
	StructureOfData.Insert("MagneticCode");
	StructureOfData.Insert("SerialNumber");
	StructureOfData.Insert("GiftCertificateKind");
	StructureOfData.Insert("Description");
	StructureOfData.Insert("CardType");
	StructureOfData.Insert("ActivationStatus");
	StructureOfData.Insert("StatusFromHistoryOfGiftCertificates");
	StructureOfData.Insert("Nominal");
	StructureOfData.Insert("Balance");
	StructureOfData.Insert("Currency");
	StructureOfData.Insert("ProductSegment");
	StructureOfData.Insert("ActionPeriod");
	StructureOfData.Insert("NumberOfValidityPeriods");
	StructureOfData.Insert("ValidityStartDate");
	StructureOfData.Insert("ValidityEndDate");
	StructureOfData.Insert("GiftCardAccounting25");
	StructureOfData.Insert("Organization");
	StructureOfData.Insert("CashFlowItemSale");
	StructureOfData.Insert("CashFlowItemReturn");	
	StructureOfData.Insert("ARAPObject");
	StructureOfData.Insert("Partner");
	StructureOfData.Insert("DocumentSales");
	StructureOfData.Insert("Canceled_");
	StructureOfData.Insert("PartialPayment");
	StructureOfData.Insert("RefundIssued");
	StructureOfData.Insert("IncomeItem");
	StructureOfData.Insert("DimensionOfRevenue");
	StructureOfData.Insert("InformationAboutTypeOfGiftCertificateIsFilledIn");
	
	Return StructureOfData;
	
EndFunction

// The procedure writes a gift certificate to the database based
// on the transmitted data about the code and type of certificate.
//
// Parameters:
//  GiftCertificateKind - CatalogRef.GiftCertificateKinds - The form of a gift certificate.
//  CodeType - EnumRef.CardCodeTypes - Type of map code.
//  MagneticCode - String - Magnetic code.
//  Barcode - String - barcode.
//
// Returns:
//  CatalogRef.GiftCertificates - A registered gift certificate.
//
Function RegisterGiftCertificateSimplistically(GiftCertificateKind, CodeType, MagneticCode, Barcode) Export
	
	GiftCertificateDataStructure = InitializeGiftCertificateDescription();
	GiftCertificateDataStructure.GiftCertificateKind = GiftCertificateKind;
	If CodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
		GiftCertificateDataStructure.MagneticCode = MagneticCode;
	ElsIf CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
		GiftCertificateDataStructure.Barcode = Barcode;
	EndIf;
	
	Return GiftCertificatesServer.RegisterGiftCertificate(GiftCertificateDataStructure);
	
EndFunction

//Returns the address in the temporary storage with the data of the tabular part of the document for analyzing the possibility of paying with gift certificates.
//
// Parameters:
//  Ref - DocumentRef, CatalogRef - 
//  UUID - UUID - A unique identifier for linking to temporary storage.
//
// Returns:
//  String, Undefined - address in temporary storage
//
Function AddressOfProductsTabularPartForAnalyzingPossibilityOfPayingWithGiftCertificates(Val Ref, Val UUID) Export
	AddressInTempStorage = Undefined;
	
	ProductsForAnalysis = GiftCertificatesServer.ProductsForAnalyzingPossibilityOfPayingWithGiftCertificates(Ref);
	If ProductsForAnalysis <> Undefined  Then
		AddressInTempStorage = PutToTempStorage(ProductsForAnalysis, UUID);
	EndIf;
	
	Return AddressInTempStorage;
EndFunction

// The procedure writes a gift certificate to the database based
// on the transmitted certificate data.
//
// Parameters:
//  GiftCertificateDataStructure - See GiftCertificatesServerCall.InitializeGiftCertificateDescription
//
// Returns:
//  CatalogRef.GiftCertificates - Registered gift certificate.
//
Function RegisterGiftCertificate(GiftCertificateDataStructure) Export
	
	Return GiftCertificatesServer.RegisterGiftCertificate(GiftCertificateDataStructure);
	
EndFunction

// The function searches for gift certificates by code.
//
// Parameters:
//  Data - String - read code.
//  CardCodeType - EnumRef.CardCodeTypes - type of code read.
//	AdditionalParameters - See GiftCertificatesServerCall.ParametersForProcessingReceivedCode
//
// Returns:
//  Array of CatalogRef.GiftCertificates - Found gift certificates.
//
Function ProcessReceivedCodeOnServer(Data, CardCodeType, AdditionalParameters) Export
	
	SetPrivilegedMode(True);
	
	FoundGiftCertificates = New Array;
	
	Filters = New Structure(New FixedStructure(AdditionalParameters.Filters));	
	If AdditionalParameters.RegisterNewOnes And Filters.Property("Status") Then
		Filters.Delete("Status");
	EndIf;
	
	If CardCodeType = Enums.CardCodeTypes.MagneticCode Then
		If GiftCertificatesClientServer.DataPreprocessingIsRequired(Data, CardCodeType) Then
			TableGiftCertificates = FindGiftCertificatesBasedOnMagneticCardReaderData(Data, Filters);
		Else
			TableGiftCertificates = FindGiftCertificatesByMagneticCode(Data, Filters);
		EndIf;
	Else
		TableGiftCertificates = FindGiftCertificatesByBarcode(Data, Filters);
	EndIf;
	
	For Each TSRow In TableGiftCertificates.RegisteredGiftCertificates Do
		
		If Not AdditionalParameters.RegisterNewOnes Or 
				AdditionalParameters.RegisterNewOnes And TSRow.ActivationStatus = False Then
			NewRow = InitializeGiftCertificateDescription();
			FillPropertyValues(NewRow, TSRow);
			
			If TSRow.ActivationStatus = True Then 
				NewRow.Description = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1, Số dư: %2 %3';
						|ru = '%1, Остаток: %2 %3';
						|en = '%1, Balance: %2 %3'; fa = '%1, Balance: %2 %3';
						|it = '%1, Saldo: %2%3';
						|pl = '%1, Pozostało: %2 %3';
						|tr = '%1, Bakiye: %2 %3'"), String(TSRow.GiftCertificateKind), TSRow.Balance, TSRow.Currency);
			Else
				NewRow.Description = String(TSRow.GiftCertificateKind);
			EndIf;
			
			FoundGiftCertificates.Add(NewRow);
		EndIf;
		
	EndDo;
	
	If AdditionalParameters.RegisterNewOnes Then
		For Each TSRow In TableGiftCertificates.NotRegisteredGiftCertificates Do
			
			NewRow = InitializeGiftCertificateDescription();
			FillPropertyValues(NewRow, TSRow);
			
			NewRow.Description = String(TSRow.GiftCertificateKind);
			
			FoundGiftCertificates.Add(NewRow);
			
		EndDo;
	EndIf;
	
	Return FoundGiftCertificates;
	
EndFunction

#Region SearchForGiftCertificates

// The function searches for gift certificates based on data received from
// the magnetic card reader.
//
// Parameters:
//  Data - Array of String - Data received from the magnetic card reader.
//  Filters - Structure -
//
// Returns:
//  Structure - structure with properties:
//   * RegisteredGiftCertificates - Array of See InitializeGiftCertificateDescription
//   * NotRegisteredGiftCertificates - Array of See InitializeGiftCertificateDescription
//
Function FindGiftCertificatesBasedOnMagneticCardReaderData(Data, Filters = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RegisteredGiftCertificates = New Array;
	NotRegisteredGiftCertificates = New Array;
	
	DecryptedData = Data[1][3];
	If DecryptedData <> Undefined Then
		For Each Structure In DecryptedData Do
			
			MagneticStripeCardTemplate = Structure.Template;
			CardCode             = Data[0];
			For Each FieldData In Structure.TrackData Do
				If FieldData.Field = Enums.MagneticStripeCardTemplateFields.Code Then
					CardCode = FieldData.Simple;
					Break;
				EndIf;
			EndDo;
			
			Query = New Query(
			"SELECT DISTINCT
			|	GiftCertificateCodeTemplates.Ref AS Ref,
			|	GiftCertificateCodeTemplates.Ref.ActionPeriod AS ActionPeriod,
			|	GiftCertificateCodeTemplates.Ref.NumberOfValidityPeriods AS NumberOfValidityPeriods,
			|	GiftCertificateCodeTemplates.Ref.Nominal AS Nominal,
			|	GiftCertificateCodeTemplates.Ref.Currency AS Currency,
			|	GiftCertificateCodeTemplates.Ref.CardType AS CardType,
			|	GiftCertificateCodeTemplates.Ref.ProductSegment AS ProductSegment,
			|	GiftCertificateCodeTemplates.Ref.GiftCardAccounting25 AS GiftCardAccounting25,
			|	GiftCertificateCodeTemplates.Ref.PartialPayment AS PartialPayment,
			|	GiftCertificateCodeTemplates.Ref.CashFlowItemSale AS CashFlowItemSale,
			|	GiftCertificateCodeTemplates.Ref.CashFlowItemReturn AS CashFlowItemReturn,
			|	GiftCertificateCodeTemplates.Ref.IncomeItem AS IncomeItem,
			|	GiftCertificateCodeTemplates.Ref.DimensionOfRevenue AS DimensionOfRevenue,
			|	GiftCertificateCodeTemplates.Ref.Organization AS Organization
			|INTO GiftCertificateKinds
			|FROM
			|	Catalog.GiftCertificateKinds.GiftCertificateCodeTemplates AS GiftCertificateCodeTemplates
			|WHERE
			|	GiftCertificateCodeTemplates.StartOfMagneticCodeRange <= &CardCode
			|	AND GiftCertificateCodeTemplates.EndOfMagneticCodeRange >= &CardCode
			|	AND GiftCertificateCodeTemplates.MagneticCodeLength = &CodeLength
			|	AND GiftCertificateCodeTemplates.MagneticStripeCardTemplate = &MagneticStripeCardTemplate
			|	AND &SelectionConditionCurrency
			|	AND &SelectionConditionAccountingForGiftCertificates2_5
			|	AND GiftCertificateCodeTemplates.Ref.DeletionMark = FALSE
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GiftCertificates.Ref AS Ref,
			|	GiftCertificates.Description AS Description,
			|	GiftCertificates.MagneticCode AS MagneticCode,
			|	GiftCertificates.Barcode AS Barcode,
			|	GiftCertificates.Code AS SerialNumber,
			|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
			|	ISNULL(ARAPObjects.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,
			|	CASE
			|		WHEN GiftCertificateKinds.GiftCardAccounting25
			|			THEN VALUE(Enum.GiftCertificateStatuses.EmptyRef)
			|		ELSE ISNULL(GiftCardHistory.Status, VALUE(Enum.GiftCertificateStatuses.NotActivated))
			|	END AS StatusFromHistoryOfGiftCertificates,
			|	ISNULL(ActivatingGiftCertificates.Active, FALSE) AS ActivationStatus,
			|	GiftCertificateKinds.Ref AS GiftCertificateKind,
			|	GiftCertificateKinds.ActionPeriod AS ActionPeriod,
			|	GiftCertificateKinds.NumberOfValidityPeriods AS NumberOfValidityPeriods,
			|	GiftCertificateKinds.Nominal AS Nominal,
			|	GiftCertificateKinds.Currency AS Currency,
			|	GiftCertificateKinds.CardType AS CardType,
			|	GiftCertificateKinds.ProductSegment AS ProductSegment,
			|	GiftCertificateKinds.GiftCardAccounting25 AS GiftCardAccounting25,
			|	GiftCertificateKinds.PartialPayment AS PartialPayment,
			|	GiftCertificateKinds.CashFlowItemSale AS CashFlowItemSale,
			|	GiftCertificateKinds.CashFlowItemReturn AS CashFlowItemReturn,
			|	GiftCertificateKinds.IncomeItem AS IncomeItem,
			|	GiftCertificateKinds.DimensionOfRevenue AS DimensionOfRevenue,
			|	ISNULL(ActivatingGiftCertificates.Organization, CASE
			|			WHEN GiftCertificateKinds.GiftCardAccounting25
			|				THEN GiftCertificateKinds.Organization
			|			ELSE VALUE(Catalog.Companies.EmptyRef)
			|		END) AS Organization,
			|	ISNULL(ActivatingGiftCertificates.ValidityStartDate, DATETIME(1, 1, 1)) AS ValidityStartDate,
			|	ISNULL(ActivatingGiftCertificates.ValidityEndDate, DATETIME(1, 1, 1)) AS ValidityEndDate
			|INTO GiftCertificates
			|FROM
			|	Catalog.GiftCertificates AS GiftCertificates
			|		INNER JOIN GiftCertificateKinds AS GiftCertificateKinds
			|		ON (GiftCertificateKinds.Ref = GiftCertificates.Owner)
			|		LEFT JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
			|		ON (ActivatingGiftCertificates.GiftCertificate = GiftCertificates.Ref)
			|		LEFT JOIN InformationRegister.GiftCardHistory.SliceLast(, ) AS GiftCardHistory
			|		ON (GiftCardHistory.GiftCertificate = GiftCertificates.Ref)
			|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
			|		ON (ARAPObjects.Object = GiftCertificates.Ref)
			|			AND NOT ARAPObjects.DeletionMark
			|WHERE
			|	TRUE
			|	AND GiftCertificates.MagneticCode = &CardCode
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GiftCertificates.Ref AS Ref,
			|	GiftCertificates.ARAPObject AS ARAPObject
			|INTO OldStyleGiftCertificates
			|FROM
			|	GiftCertificates AS GiftCertificates
			|WHERE
			|	NOT GiftCertificates.GiftCardAccounting25
			|
			|INDEX BY
			|	Ref
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GiftCertificates.Ref AS Ref,
			|	GiftCertificates.ARAPObject AS ARAPObject
			|INTO NewStyleGiftCertificates
			|FROM
			|	GiftCertificates AS GiftCertificates
			|WHERE
			|	GiftCertificates.GiftCardAccounting25
			|	AND NOT GiftCertificates.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
			|
			|INDEX BY
			|	ARAPObject
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CertificateBalances.GiftCertificate AS GiftCertificate,
			|	CertificateBalances.SumBalance
			|INTO BalanceOfGiftCertificates
			|FROM
			|	AccumulationRegister.GiftCertificates.Balance(
			|		,
			|		GiftCertificate IN
			|			(SELECT
			|				T.Ref
			|			FROM
			|				OldStyleGiftCertificates AS T)) AS CertificateBalances
			|
			|UNION ALL
			|
			|SELECT
			|	CertificateBalances.ARAPObject.Object AS GiftCertificate,
			|	CASE WHEN CertificateBalances.SumBalance < 0 
			|		THEN -CertificateBalances.SumBalance
			|		ELSE CertificateBalances.SumBalance
			|	END	
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Balance(
			|		,
			|		ARAPObject IN
			|			(SELECT
			|				T.ARAPObject
			|			FROM
			|				NewStyleGiftCertificates AS T)) AS CertificateBalances
			|
			|INDEX BY
			|	GiftCertificate
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GiftCertificates.Ref AS GiftCertificate,
			|	CASE WHEN (GiftCertificates.Ref, TRUE) 
			|		IN (SELECT TOP 1
			|				T.GiftCertificate, 
			|				TRUE 
			|			FROM AccumulationRegister.GiftCertificates AS T
			|			WHERE
			|				T.Recorder REFS Document.GiftCertificateCancellation
			|				AND T.Active
			|				AND T.GiftCertificate = GiftCertificates.Ref) THEN TRUE ELSE FALSE END AS Canceled_,
			|	CASE WHEN (GiftCertificates.Ref, TRUE) 
			|		IN (SELECT TOP 1
			|				T.GiftCertificate, 
			|				TRUE 
			|			FROM AccumulationRegister.GiftCertificates AS T
			|			WHERE
			|				T.Recorder REFS Document.ReturnOfGiftCards
			|				AND T.Active
			|				AND T.Sum <> 0
			|				AND T.GiftCertificate = GiftCertificates.Ref) THEN TRUE ELSE FALSE END AS RefundIssued
			|INTO StateOfGiftCertificates
			|FROM
			|	OldStyleGiftCertificates AS GiftCertificates
			|
			|UNION ALL
			|
			|SELECT
			|	GiftCertificates.Ref AS GiftCertificate,
			|	CASE WHEN (GiftCertificates.ARAPObject, TRUE) 
			|		IN (SELECT TOP 1
			|				T.ARAPObject, 
			|				TRUE 
			|			FROM AccumulationRegister.CustomersARAPAccounting AS T
			|			WHERE
			|				T.Recorder REFS Document.GiftCertificateCancellation
			|				AND T.Active
			|				AND T.ARAPObject = GiftCertificates.ARAPObject) THEN TRUE ELSE FALSE END AS Canceled_,
			|	CASE WHEN (GiftCertificates.ARAPObject, TRUE) 
			|		IN (SELECT TOP 1
			|				T.ARAPObject, 
			|				TRUE 
			|			FROM AccumulationRegister.CustomersARAPAccounting AS T
			|			WHERE
			|				(T.Recorder REFS Document.ReturnOfGiftCards
			|				OR T.Recorder REFS Document.CashVoucher
			|				OR T.Recorder REFS Document.BankAccountIssue
			|				OR T.Recorder REFS Document.PaymentCardTransaction
			|				OR T.Recorder REFS Document.PaymentRequest)
			|				AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.RefundToCustomer),
			|											VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
			|				AND T.Active
			|				AND T.Sum <> 0
			|				AND T.ARAPObject = GiftCertificates.ARAPObject) THEN TRUE ELSE FALSE END AS RefundIssued
			|FROM
			|	NewStyleGiftCertificates AS GiftCertificates
			|
			|INDEX BY
			|	GiftCertificate
			|
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	1 AS Order,
			|	GiftCertificates.Ref AS Ref,
			|	GiftCertificates.Description AS Description,
			|	GiftCertificates.MagneticCode AS MagneticCode,
			|	GiftCertificates.Barcode AS Barcode,
			|	GiftCertificates.SerialNumber AS SerialNumber,
			|	GiftCertificates.ValidityStartDate AS ValidityStartDate,
			|	GiftCertificates.ValidityEndDate AS ValidityEndDate,
			|	GiftCertificates.StatusFromHistoryOfGiftCertificates AS StatusFromHistoryOfGiftCertificates,
			|	GiftCertificates.ActivationStatus AS ActivationStatus,
			|	ISNULL(CertificateBalances.SumBalance, 0) AS Balance,
			|	GiftCertificates.GiftCertificateKind AS GiftCertificateKind,
			|	GiftCertificates.ActionPeriod AS ActionPeriod,
			|	GiftCertificates.NumberOfValidityPeriods AS NumberOfValidityPeriods,
			|	GiftCertificates.Nominal AS Nominal,
			|	GiftCertificates.Currency AS Currency,
			|	GiftCertificates.CardType AS CardType,
			|	GiftCertificates.ProductSegment AS ProductSegment,
			|	GiftCertificates.GiftCardAccounting25 AS GiftCardAccounting25,
			|	GiftCertificates.PartialPayment AS PartialPayment,
			|	GiftCertificates.ARAPObject AS ARAPObject,
			|	GiftCertificates.Partner AS Partner,
			|	GiftCertificates.CashFlowItemSale AS CashFlowItemSale,
			|	GiftCertificates.CashFlowItemReturn AS CashFlowItemReturn,
			|	GiftCertificates.IncomeItem AS IncomeItem,
			|	GiftCertificates.DimensionOfRevenue AS DimensionOfRevenue,
			|	GiftCertificates.Organization AS Organization,
			|	ISNULL(StateOfGiftCertificates.RefundIssued, FALSE) AS RefundIssued,
			|	ISNULL(StateOfGiftCertificates.Canceled_, FALSE) AS Canceled_
			|FROM
			|	GiftCertificates AS GiftCertificates
			|   LEFT JOIN BalanceOfGiftCertificates AS CertificateBalances
			|	ON CertificateBalances.GiftCertificate = GiftCertificates.Ref
			|	LEFT JOIN StateOfGiftCertificates AS StateOfGiftCertificates
			|	ON GiftCertificates.Ref = StateOfGiftCertificates.GiftCertificate
			|WHERE
			|	NOT GiftCertificates.GiftCardAccounting25
			|	AND &SelectionCriteriaOrganizationByTypeOfOperation
			|	AND &SelectionConditionStatusFromHistoryOfGiftCertificates
			|
			|UNION ALL
			|
			|SELECT
			|	1 AS Order,
			|	GiftCertificates.Ref AS Ref,
			|	GiftCertificates.Description AS Description,
			|	GiftCertificates.MagneticCode AS MagneticCode,
			|	GiftCertificates.Barcode AS Barcode,
			|	GiftCertificates.SerialNumber AS SerialNumber,
			|	GiftCertificates.ValidityStartDate AS ValidityStartDate,
			|	GiftCertificates.ValidityEndDate AS ValidityEndDate,
			|	GiftCertificates.StatusFromHistoryOfGiftCertificates AS StatusFromHistoryOfGiftCertificates,
			|	GiftCertificates.ActivationStatus AS ActivationStatus,
			|	ISNULL(CertificateBalances.SumBalance, 0) AS Balance,
			|	GiftCertificates.GiftCertificateKind AS GiftCertificateKind,
			|	GiftCertificates.ActionPeriod AS ActionPeriod,
			|	GiftCertificates.NumberOfValidityPeriods AS NumberOfValidityPeriods,
			|	GiftCertificates.Nominal AS Nominal,
			|	GiftCertificates.Currency AS Currency,
			|	GiftCertificates.CardType AS CardType,
			|	GiftCertificates.ProductSegment AS ProductSegment,
			|	GiftCertificates.GiftCardAccounting25 AS GiftCardAccounting25,
			|	GiftCertificates.PartialPayment AS PartialPayment,
			|	GiftCertificates.ARAPObject AS ARAPObject,
			|	GiftCertificates.Partner AS Partner,
			|	GiftCertificates.CashFlowItemSale AS CashFlowItemSale,
			|	GiftCertificates.CashFlowItemReturn AS CashFlowItemReturn,
			|	GiftCertificates.IncomeItem AS IncomeItem,
			|	GiftCertificates.DimensionOfRevenue AS DimensionOfRevenue,
			|	GiftCertificates.Organization AS Organization,
			|	ISNULL(StateOfGiftCertificates.RefundIssued, FALSE) AS RefundIssued,
			|	ISNULL(StateOfGiftCertificates.Canceled_, FALSE) AS Canceled_
			|FROM
			|	GiftCertificates AS GiftCertificates
			|		LEFT JOIN BalanceOfGiftCertificates AS CertificateBalances
			|		ON (CertificateBalances.GiftCertificate = GiftCertificates.Ref)
			|		LEFT JOIN StateOfGiftCertificates AS StateOfGiftCertificates
			|		ON GiftCertificates.Ref = StateOfGiftCertificates.GiftCertificate
			|WHERE
			|	GiftCertificates.GiftCardAccounting25
			|	AND &SelectionConditionOrganization
			|	AND &SelectionCriteriaByTypeOfOperation
			|
			|UNION ALL
			|
			|SELECT
			|	2,
			|	VALUE(Catalog.GiftCertificates.EmptyRef),
			|	UNDEFINED,
			|	&CardCode,
			|	"""",
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	VALUE(Enum.GiftCertificateStatuses.EmptyRef),
			|	FALSE,
			|	0,
			|	GiftCertificateKinds.Ref,
			|	GiftCertificateKinds.ActionPeriod,
			|	GiftCertificateKinds.NumberOfValidityPeriods,
			|	GiftCertificateKinds.Nominal,
			|	GiftCertificateKinds.Currency,
			|	GiftCertificateKinds.CardType,
			|	GiftCertificateKinds.ProductSegment,
			|	GiftCertificateKinds.GiftCardAccounting25,
			|	GiftCertificateKinds.PartialPayment,
			|	VALUE(Catalog.ARAPObjects.EmptyRef),
			|	VALUE(Catalog.Partners.EmptyRef),
			|	GiftCertificateKinds.CashFlowItemSale,
			|	GiftCertificateKinds.CashFlowItemReturn,
			|	GiftCertificateKinds.IncomeItem AS IncomeItem,
			|	GiftCertificateKinds.DimensionOfRevenue AS DimensionOfRevenue,
			|	ISNULL(Companies.Ref, GiftCertificateKinds.Organization),
			|	FALSE,
			|	FALSE
			|FROM
			|	GiftCertificateKinds AS GiftCertificateKinds
			|		LEFT JOIN Catalog.Companies AS Companies
			|		ON (&ConnectionConditionByOrganizationByTypeOfOperation)
			|WHERE
			|	NOT GiftCertificateKinds.Ref IN
			|				(SELECT DISTINCT
			|					T.GiftCertificateKind
			|				FROM
			|					GiftCertificates AS T)
			|	AND NOT GiftCertificateKinds.GiftCardAccounting25
			|
			|UNION ALL
			|
			|SELECT
			|	2,
			|	VALUE(Catalog.GiftCertificates.EmptyRef),
			|	UNDEFINED,
			|	&CardCode,
			|	"""",
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	VALUE(Enum.GiftCertificateStatuses.EmptyRef),
			|	FALSE,
			|	0,
			|	GiftCertificateKinds.Ref,
			|	GiftCertificateKinds.ActionPeriod,
			|	GiftCertificateKinds.NumberOfValidityPeriods,
			|	GiftCertificateKinds.Nominal,
			|	GiftCertificateKinds.Currency,
			|	GiftCertificateKinds.CardType,
			|	GiftCertificateKinds.ProductSegment,
			|	GiftCertificateKinds.GiftCardAccounting25,
			|	GiftCertificateKinds.PartialPayment,
			|	VALUE(Catalog.ARAPObjects.EmptyRef),
			|	VALUE(Catalog.Partners.EmptyRef),
			|	GiftCertificateKinds.CashFlowItemSale,
			|	GiftCertificateKinds.CashFlowItemReturn,
			|	GiftCertificateKinds.IncomeItem AS IncomeItem,
			|	GiftCertificateKinds.DimensionOfRevenue AS DimensionOfRevenue,
			|	GiftCertificateKinds.Organization,
			|	FALSE,
			|	FALSE
			|FROM
			|	GiftCertificateKinds AS GiftCertificateKinds
			|		LEFT JOIN Catalog.Companies AS Companies
			|		ON (&ConnectionConditionByOrganization)
			|WHERE
			|	NOT GiftCertificateKinds.Ref IN
			|				(SELECT DISTINCT
			|					T.GiftCertificateKind
			|				FROM
			|					GiftCertificates AS T)
			|	AND GiftCertificateKinds.GiftCardAccounting25
			|	AND &ConditionForSelectingTypeOfGiftCertificateForOrganization
			|
			|ORDER BY
			|	Order");
			
			Query.SetParameter("MagneticStripeCardTemplate", MagneticStripeCardTemplate);
			Query.SetParameter("CardCode",             CardCode);
			Query.SetParameter("CodeLength",            StrLen(CardCode));
			
			FilterConditions = Filters;
			If Not TypeOf(Filters) = Type("Structure") Then
				FilterConditions = New Structure;
			EndIf;
			
			CurrentSessionDate = CurrentSessionDate();
			If FilterConditions.Property("Date") And ValueIsFilled(FilterConditions.Date) Then
				CurrentSessionDate = FilterConditions.Date;
			EndIf;
			Query.SetParameter("CurrentDate", CurrentSessionDate);
			
			ReplacementTextOfSelectionCriteriaByTypeOfOperation = "TRUE";
			If FilterConditions.Property("OperationType") Then
				If FilterConditions.OperationType = 1 Then
				// Sale
					ReplacementTextOfSelectionCriteriaByTypeOfOperation = "NOT GiftCertificates.ActivationStatus";
				ElsIf FilterConditions.OperationType = 2 Then
				// Return
					ReplacementTextOfSelectionCriteriaByTypeOfOperation = "GiftCertificates.ActivationStatus
					|	AND ISNULL(StateOfGiftCertificates.RefundIssued, FALSE) = FALSE
					|	AND GiftCertificates.ValidityEndDate >= &CurrentDate 
					|	AND ISNULL(CertificateBalances.SumBalance, 0) = GiftCertificates.Nominal";
				ElsIf FilterConditions.OperationType = 3 Then
				// Payment
					ReplacementTextOfSelectionCriteriaByTypeOfOperation = "GiftCertificates.ActivationStatus 
					|	AND GiftCertificates.ValidityStartDate <= &CurrentDate AND GiftCertificates.ValidityEndDate >= &CurrentDate 
					|	AND (ISNULL(CertificateBalances.SumBalance, 0) > 0 AND GiftCertificates.PartialPayment
					|		OR ISNULL(CertificateBalances.SumBalance, 0) = GiftCertificates.Nominal AND NOT GiftCertificates.PartialPayment)";
				ElsIf FilterConditions.OperationType = 4 Then
				// Cancellation
					ReplacementTextOfSelectionCriteriaByTypeOfOperation = "GiftCertificates.ActivationStatus
					|	AND ISNULL(CertificateBalances.SumBalance, 0) > 0
					|	AND (GiftCertificates.PartialPayment = FALSE AND 
					|			ISNULL(CertificateBalances.SumBalance, 0) <= GiftCertificates.Nominal
					|		OR GiftCertificates.PartialPayment = TRUE)";
				EndIf;
			EndIf;
			Query.Text = StrReplace(Query.Text,"&SelectionCriteriaByTypeOfOperation", ReplacementTextOfSelectionCriteriaByTypeOfOperation);
			
			ReplacementTextOfSelectionConditions = "TRUE";
			ReplacementTextOfSelectionCriteriaByTypeOfOperation = "TRUE";
			ReplacementTextOfSelectionConditionByType = "TRUE";
			TextOfConnectionConditionReplacementByTypeOfOperation = "FALSE";
			If FilterConditions.Property("Organization") Then
				ReplacementTextOfSelectionConditions = "GiftCertificates.Organization IN (&Organization)";
				ReplacementTextOfSelectionConditionByType = "GiftCertificateKinds.Organization IN (&Organization)";
				Query.SetParameter("Organization", FilterConditions.Organization);
				If FilterConditions.Property("OperationType") Then
					If FilterConditions.OperationType > 1 Then
						ReplacementTextOfSelectionCriteriaByTypeOfOperation = "GiftCertificates.Organization IN (&Organization)";
						TextOfConnectionConditionReplacementByTypeOfOperation = "Companies.Ref IN (&Organization)";
					EndIf;
				EndIf;
			EndIf;
			Query.Text = StrReplace(Query.Text,"&SelectionCriteriaOrganizationByTypeOfOperation", ReplacementTextOfSelectionCriteriaByTypeOfOperation);
			Query.Text = StrReplace(Query.Text,"&SelectionConditionOrganization", ReplacementTextOfSelectionConditions);
			Query.Text = StrReplace(Query.Text,"&ConnectionConditionByOrganizationByTypeOfOperation", TextOfConnectionConditionReplacementByTypeOfOperation);
			Query.Text = StrReplace(Query.Text,"&ConditionForSelectingTypeOfGiftCertificateForOrganization", ReplacementTextOfSelectionConditionByType);
			
			ReplacementTextOfSelectionConditions = "TRUE";
			If FilterConditions.Property("Currency") Then
				ReplacementTextOfSelectionConditions = "GiftCertificateCodeTemplates.Ref.Currency IN (&Currency)";
				Query.SetParameter("Currency", FilterConditions.Currency);
			EndIf;
			Query.Text = StrReplace(Query.Text,"&SelectionConditionCurrency", ReplacementTextOfSelectionConditions);
			
			ReplacementTextOfSelectionConditions = "TRUE";
			If FilterConditions.Property("GiftCardAccounting25") Then
				ReplacementTextOfSelectionConditions = "GiftCertificateCodeTemplates.Ref.GiftCardAccounting25 = &GiftCardAccounting25";
				Query.SetParameter("GiftCardAccounting25", FilterConditions.GiftCardAccounting25);
			EndIf;
			Query.Text = StrReplace(Query.Text,"&SelectionConditionAccountingForGiftCertificates2_5", ReplacementTextOfSelectionConditions);
			
			ReplacementTextOfSelectionConditions = "TRUE";		
			If FilterConditions.Property("Status") Then
				ReplacementTextOfSelectionConditions = "GiftCertificates.StatusFromHistoryOfGiftCertificates IN (&Status)";
				Query.SetParameter("Status", FilterConditions.Status);
				If FilterConditions.Property("OperationType") Then
					If FilterConditions.OperationType = 3 Then
					// Payment
						ReplacementTextOfSelectionConditions = ReplacementTextOfSelectionConditions + " AND ISNULL(CertificateBalances.SumBalance, 0) > 0";
					ElsIf FilterConditions.OperationType = 4 Then
					// Cancellation
						// You cannot cancel a reusable gift certificate if it is partially redeemed and its Balance is zero.
						// The Cash Register Receipt document does not take into account the Balance of the gift certificate when calculating the Status.
						ReplacementTextOfSelectionConditions = ReplacementTextOfSelectionConditions + "
							|AND NOT (GiftCertificates.PartialPayment = TRUE 
							|		AND GiftCertificates.StatusFromHistoryOfGiftCertificates = VALUE(Enum.GiftCertificateStatuses.PartiallyRepaid) 
							|		AND ISNULL(CertificateBalances.SumBalance, 0) = 0)";
					EndIf;
				EndIf;
			EndIf;
			Query.Text = StrReplace(Query.Text,"&SelectionConditionStatusFromHistoryOfGiftCertificates", ReplacementTextOfSelectionConditions);
			
			SetPrivilegedMode(True);
			Result = Query.Execute();
			SetPrivilegedMode(False);
			
			Selection = Result.Select();
			While Selection.Next() Do
				
				NewRow = InitializeGiftCertificateDescription();
				FillPropertyValues(NewRow, Selection);
			
				If ValueIsFilled(Selection.Ref) Then
					RegisteredGiftCertificates.Add(NewRow);
				Else
					NotRegisteredGiftCertificates.Add(NewRow);
				EndIf;
				
			EndDo;
			
		EndDo;
	EndIf;
	
	ReturnValue = New Structure("RegisteredGiftCertificates, NotRegisteredGiftCertificates");
	ReturnValue.RegisteredGiftCertificates   = RegisteredGiftCertificates;
	ReturnValue.NotRegisteredGiftCertificates = NotRegisteredGiftCertificates;
	
	Return ReturnValue;
	
EndFunction

// The function searches for gift certificates by barcode.
//
// Parameters:
//  Barcode - String - barcode.
//	Filters - Structure -
//	
// Returns:
//  See GiftCertificatesServer.FindGiftCertificates
//
Function FindGiftCertificatesByBarcode(Barcode, Filters = Undefined) Export

	Return GiftCertificatesServer.FindGiftCertificates(Barcode, Enums.CardCodeTypes.Barcode, Filters);
	
EndFunction

// The function searches for gift certificates by magnetic code.
//
// Parameters:
//  MagneticCode - String - Magnetic code.
//	Filters - Structure -
//
// Returns:
// 	See GiftCertificatesServer.FindGiftCertificates
//
Function FindGiftCertificatesByMagneticCode(MagneticCode, Filters = Undefined) Export
		
	Return GiftCertificatesServer.FindGiftCertificates(MagneticCode, Enums.CardCodeTypes.MagneticCode, Filters);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function TextOfRequestToReceiveGiftCertificateData()
	
	QueryText = "SELECT
	|	GiftCertificates.Ref AS Ref,
	|	GiftCertificates.Description AS Description,
	|	GiftCertificates.MagneticCode AS MagneticCode,
	|	GiftCertificates.Barcode AS Barcode,
	|	GiftCertificates.Code AS SerialNumber,
	|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	ISNULL(ARAPObjects.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,
	|
	|	CASE
	|		WHEN ISNULL(GiftCertificates.Owner.GiftCardAccounting25, FALSE)
	|			THEN VALUE(Enum.GiftCertificateStatuses.EmptyRef)
	|		ELSE ISNULL(GiftCardHistory.Status, VALUE(Enum.GiftCertificateStatuses.NotActivated))
	|	END AS StatusFromHistoryOfGiftCertificates,
	|	CASE WHEN &CurrentDocument = UNDEFINED 
	|					OR NOT &CurrentDocument IN (UNDEFINED, ActivatingGiftCertificates.Recorder)
	|		THEN ISNULL(ActivatingGiftCertificates.Active, FALSE)
	|		ELSE FALSE
	|	END AS ActivationStatus,
	|	ISNULL(ActivatingGiftCertificates.Organization, CASE
	|			WHEN ISNULL(GiftCertificates.Owner.GiftCardAccounting25, FALSE)
	|				THEN GiftCertificates.Owner.Organization
	|			ELSE VALUE(Catalog.Companies.EmptyRef)
	|		END) AS Organization,
	|	GiftCertificates.Owner AS GiftCertificateKind,
	|	GiftCertificates.Owner.ActionPeriod AS ActionPeriod,
	|	GiftCertificates.Owner.NumberOfValidityPeriods AS NumberOfValidityPeriods,
	|	GiftCertificates.Owner.Nominal AS Nominal,
	|	GiftCertificates.Owner.Currency AS Currency,
	|	GiftCertificates.Owner.CardType AS CardType,
	|	GiftCertificates.Owner.ProductSegment AS ProductSegment,
	|	GiftCertificates.Owner.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificates.Owner.PartialPayment AS PartialPayment,
	|	GiftCertificates.Owner.CashFlowItemSale AS CashFlowItemSale,
	|	GiftCertificates.Owner.CashFlowItemReturn AS CashFlowItemReturn,
	|	GiftCertificates.Owner.IncomeItem AS IncomeItem,
	|	GiftCertificates.Owner.DimensionOfRevenue AS DimensionOfRevenue,
	|	ISNULL(ActivatingGiftCertificates.ValidityStartDate, DATETIME(1, 1, 1)) AS ValidityStartDate,
	|	ISNULL(ActivatingGiftCertificates.ValidityEndDate, DATETIME(1, 1, 1)) AS ValidityEndDate,
	|	ISNULL(ActivatingGiftCertificates.Recorder, UNDEFINED) AS DocumentSales,
	|	CASE WHEN GiftCertificates.Owner.GiftCardAccounting25 IS NULL 
	|		THEN FALSE 
	|		ELSE TRUE 
	|	END AS InformationAboutTypeOfGiftCertificateIsFilledIn
	|INTO GiftCertificates
	|FROM
	|	Catalog.GiftCertificates AS GiftCertificates
	|		LEFT JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
	|		ON (ActivatingGiftCertificates.GiftCertificate = GiftCertificates.Ref)
	|		LEFT JOIN InformationRegister.GiftCardHistory.SliceLast(&BorderCurDateEndOfDay, GiftCertificate IN (&Ref)) AS GiftCardHistory
	|		ON (GiftCardHistory.GiftCertificate = GiftCertificates.Ref)
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON (ARAPObjects.Object = GiftCertificates.Ref)
	|		AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	GiftCertificates.Ref IN (&Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref AS Ref,
	|	GiftCertificates.ARAPObject AS ARAPObject
	|INTO OldStyleGiftCertificates
	|FROM
	|	GiftCertificates AS GiftCertificates
	|WHERE
	|	NOT GiftCertificates.GiftCardAccounting25
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref AS Ref,
	|	GiftCertificates.ARAPObject AS ARAPObject
	|INTO NewStyleGiftCertificates
	|FROM
	|	GiftCertificates AS GiftCertificates
	|WHERE
	|	GiftCertificates.GiftCardAccounting25
	|	AND NOT GiftCertificates.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
	|
	|INDEX BY
	|	ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateBalances.GiftCertificate AS GiftCertificate,
	|	SUM(CertificateBalances.SumBalance) AS SumBalance
	|INTO BalanceOfGiftCertificates
	|FROM
	|	(SELECT
	|		CertificateBalances.GiftCertificate AS GiftCertificate,
	|		CertificateBalances.SumBalance AS SumBalance
	|	FROM
	|		AccumulationRegister.GiftCertificates.Balance(
	|				,
	|				GiftCertificate IN
	|					(SELECT
	|						T.Ref
	|					FROM
	|						OldStyleGiftCertificates AS T)) AS CertificateBalances
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterRecords.GiftCertificate AS GiftCertificate,
	|		CASE WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -RegisterRecords.Sum
	|			ELSE RegisterRecords.Sum
	|		END AS SumBalance
	|	FROM
	|		AccumulationRegister.GiftCertificates AS RegisterRecords
	|		INNER JOIN OldStyleGiftCertificates AS GiftCertificates
	|		ON RegisterRecords.GiftCertificate = GiftCertificates.Ref
	|	WHERE
	|		&CurrentDocument <> UNDEFINED
	|		AND RegisterRecords.Recorder = &CurrentDocument) AS CertificateBalances
	|GROUP BY
	|	CertificateBalances.GiftCertificate
	|
	|UNION ALL
	|
	|SELECT
	|	CertificateBalances.GiftCertificate AS GiftCertificate,
	|	CASE
	|		WHEN SUM(CertificateBalances.SumBalance) < 0
	|			THEN -SUM(CertificateBalances.SumBalance)
	|		ELSE SUM(CertificateBalances.SumBalance)
	|	END AS SumBalance
	|FROM
	|	(SELECT
	|		CertificateBalances.ARAPObject.Object AS GiftCertificate,
	|		CertificateBalances.SumBalance AS SumBalance
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting.Balance(
	|				,
	|				ARAPObject IN
	|					(SELECT
	|						T.ARAPObject
	|					FROM
	|						NewStyleGiftCertificates AS T)) AS CertificateBalances
	|
	|	UNION ALL
	|
	|	SELECT
	|		GiftCertificates.Ref AS GiftCertificate,
	|		CASE WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -RegisterRecords.Sum
	|			ELSE RegisterRecords.Sum
	|		END AS SumBalance
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS RegisterRecords
	|		INNER JOIN NewStyleGiftCertificates AS GiftCertificates
	|		ON RegisterRecords.ARAPObject = GiftCertificates.ARAPObject
	|	WHERE
	|		&CurrentDocument <> UNDEFINED
	|		AND RegisterRecords.Recorder = &CurrentDocument) AS CertificateBalances
	|GROUP BY
	|		CertificateBalances.GiftCertificate
	|
	|INDEX BY
	|	GiftCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref AS GiftCertificate,
	|	CASE WHEN (GiftCertificates.Ref, TRUE) 
	|		IN (SELECT TOP 1
	|				T.GiftCertificate, 
	|				TRUE 
	|			FROM AccumulationRegister.GiftCertificates AS T
	|			WHERE
	|				T.Recorder REFS Document.GiftCertificateCancellation
	|				AND T.Active
	|				AND T.GiftCertificate = GiftCertificates.Ref
	|				AND (&CurrentDocument = UNDEFINED
	|					OR NOT &CurrentDocument IN (UNDEFINED, T.Recorder))) THEN TRUE ELSE FALSE END AS Canceled_,
	|	CASE WHEN (GiftCertificates.Ref, TRUE) 
	|		IN (SELECT TOP 1
	|				T.GiftCertificate, 
	|				TRUE 
	|			FROM AccumulationRegister.GiftCertificates AS T
	|			WHERE
	|				T.Recorder REFS Document.ReturnOfGiftCards
	|				AND T.Active
	|				AND T.GiftCertificate = GiftCertificates.Ref
	|				AND T.Sum <> 0
	|				AND (&CurrentDocument = UNDEFINED
	|					OR NOT &CurrentDocument IN (UNDEFINED, T.Recorder))) THEN TRUE ELSE FALSE END AS RefundIssued
	|INTO StateOfGiftCertificates
	|FROM
	|	OldStyleGiftCertificates AS GiftCertificates
	|
	|UNION ALL
	|
	|SELECT
	|	GiftCertificates.Ref AS GiftCertificate,
	|	CASE WHEN (GiftCertificates.ARAPObject, TRUE) 
	|		IN (SELECT TOP 1
	|				T.ARAPObject, 
	|				TRUE 
	|			FROM AccumulationRegister.CustomersARAPAccounting AS T
	|			WHERE
	|				T.Recorder REFS Document.GiftCertificateCancellation
	|				AND T.Active
	|				AND T.ARAPObject = GiftCertificates.ARAPObject
	|				AND (&CurrentDocument = UNDEFINED
	|					OR NOT &CurrentDocument IN (UNDEFINED, T.Recorder))) THEN TRUE ELSE FALSE END AS Canceled_,
	|	CASE WHEN (GiftCertificates.ARAPObject, TRUE) 
	|		IN (SELECT TOP 1
	|				T.ARAPObject, 
	|				TRUE 
	|			FROM AccumulationRegister.CustomersARAPAccounting AS T
	|			WHERE
	|				(T.Recorder REFS Document.ReturnOfGiftCards
	|				OR T.Recorder REFS Document.CashVoucher
	|				OR T.Recorder REFS Document.BankAccountIssue
	|				OR T.Recorder REFS Document.PaymentCardTransaction
	|				OR T.Recorder REFS Document.PaymentRequest)
	|				AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|											VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
	|				AND T.Active
	|				AND T.ARAPObject = GiftCertificates.ARAPObject
	|				AND T.Sum <> 0
	|				AND (&CurrentDocument = UNDEFINED
	|					OR NOT &CurrentDocument IN (UNDEFINED, T.Recorder))) THEN TRUE ELSE FALSE END AS RefundIssued
	|FROM
	|	NewStyleGiftCertificates AS GiftCertificates
	|
	|INDEX BY
	|	GiftCertificate
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref AS Ref,
	|	GiftCertificates.Description AS Description,
	|	GiftCertificates.MagneticCode AS MagneticCode,
	|	GiftCertificates.Barcode AS Barcode,
	|	GiftCertificates.SerialNumber AS SerialNumber,
	|	GiftCertificates.StatusFromHistoryOfGiftCertificates AS StatusFromHistoryOfGiftCertificates,
	|	GiftCertificates.ActivationStatus AS ActivationStatus,
	|	ISNULL(CertificateBalances.SumBalance, 0) AS Balance,
	|	GiftCertificates.GiftCertificateKind AS GiftCertificateKind,
	|	GiftCertificates.ActionPeriod AS ActionPeriod,
	|	GiftCertificates.NumberOfValidityPeriods AS NumberOfValidityPeriods,
	|	GiftCertificates.Nominal AS Nominal,
	|	GiftCertificates.Currency AS Currency,
	|	GiftCertificates.CardType AS CardType,
	|	GiftCertificates.ProductSegment AS ProductSegment,
	|	GiftCertificates.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificates.PartialPayment AS PartialPayment,
	|	GiftCertificates.Organization AS Organization,
	|	GiftCertificates.CashFlowItemSale AS CashFlowItemSale,
	|	GiftCertificates.CashFlowItemReturn AS CashFlowItemReturn,
	|	GiftCertificates.IncomeItem AS IncomeItem,
	|	GiftCertificates.DimensionOfRevenue AS DimensionOfRevenue,
	|	GiftCertificates.ARAPObject AS ARAPObject,
	|	GiftCertificates.Partner AS Partner,
	|	GiftCertificates.ValidityStartDate AS ValidityStartDate,
	|	GiftCertificates.ValidityEndDate AS ValidityEndDate,
	|	GiftCertificates.DocumentSales AS DocumentSales,
	|	ISNULL(StateOfGiftCertificates.Canceled_, FALSE) AS Canceled_,
	|	ISNULL(StateOfGiftCertificates.RefundIssued, FALSE) AS RefundIssued,
	|	GiftCertificates.InformationAboutTypeOfGiftCertificateIsFilledIn AS InformationAboutTypeOfGiftCertificateIsFilledIn
	|
	|FROM
	|	GiftCertificates AS GiftCertificates
	|		LEFT JOIN BalanceOfGiftCertificates AS CertificateBalances
	|		ON (CertificateBalances.GiftCertificate = GiftCertificates.Ref)
	|		LEFT JOIN StateOfGiftCertificates AS StateOfGiftCertificates
	|		ON GiftCertificates.Ref = StateOfGiftCertificates.GiftCertificate
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.GiftCertificates.EmptyRef),
	|	"""",
	|	"""",
	|	"""",
	|	"""",
	|	VALUE(Enum.GiftCertificateStatuses.NotActivated),
	|	FALSE,
	|	0,
	|	GiftCertificateKinds.Ref,
	|	GiftCertificateKinds.ActionPeriod,
	|	GiftCertificateKinds.NumberOfValidityPeriods,
	|	GiftCertificateKinds.Nominal,
	|	GiftCertificateKinds.Currency,
	|	GiftCertificateKinds.CardType,
	|	GiftCertificateKinds.ProductSegment,
	|	GiftCertificateKinds.GiftCardAccounting25,
	|	GiftCertificateKinds.PartialPayment,
	|	GiftCertificateKinds.Organization,
	|	GiftCertificateKinds.CashFlowItemSale,
	|	GiftCertificateKinds.CashFlowItemReturn,
	|	GiftCertificateKinds.IncomeItem,
	|	GiftCertificateKinds.DimensionOfRevenue,
	|	VALUE(Catalog.ARAPObjects.EmptyRef),
	|	VALUE(Catalog.Partners.EmptyRef),
	|	DATETIME(1, 1, 1),
	|	DATETIME(1, 1, 1),
	|	UNDEFINED,
	|	FALSE AS Canceled_,
	|	FALSE AS RefundIssued,
	|	TRUE
	|FROM
	|	Catalog.GiftCertificateKinds AS GiftCertificateKinds
	|WHERE
	|	GiftCertificateKinds.Ref = &GiftCertificateKind
	|	AND GiftCertificateKinds.DeletionMark = FALSE";
	
	Return QueryText;
EndFunction

#EndRegion
