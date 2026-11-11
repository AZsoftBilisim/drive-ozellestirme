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
	
	DocumentMechanisms.Add("DocumentsRegistry");
	
	PhysicalCountReportLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.PhysicalCountReport") Then
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
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
	
	PhysicalCountReportLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the Inventory inventory document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PhysicalCountReport) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PhysicalCountReport.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PhysicalCountReport);
		CreateBasedOnCommand.WriteMode = "Post";

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	PhysicalCountReportLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Returns a list of organizations for which inventory lists are printed.
//
// Parameters:
//	DocumentsArray - Array - massive slylock on the inventory list.
//
// Returns:
//	ValueList - List of organizations.
//
Function ListOfOrganizationsFromDocuments(DocumentsArray) Export
	
	Query = New Query;
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	PhysicalCountReport.Organization
	|FROM
	|	Document.PhysicalCountReport AS PhysicalCountReport
	|WHERE
	|	PhysicalCountReport.Ref IN (&DocumentsArray)";
	
	CompanyArray = Query.Execute().Unload().UnloadColumn("Organization");
	
	CompaniesList = New ValueList;
	CompaniesList.LoadValues(CompanyArray);
	
	Return CompaniesList;
	
EndFunction

// The function receives the document data with the value indicators.
//
// Parameters:
//   DocumentRef - DocumentRef.PhysicalCountReport - the document to get the data for.
//
// Returns:
//   Structure:
//      Resultcap - The result of a request for the document header
//                         . in case of an error, the structure Is: Dateachal, Dateachal from the document.
//      Resultsetmetadata - the query Result in a tabular part of the document.
//      Resultsquality - the result of the query on exchange rates.
//      Error description String, Undefined - if there are no errors, Undefined, otherwise string error ID.
//      Post-preliminary calculation-Boolean flag for getting data from the preliminary calculation.
//
Function InventoryData(DocumentRef) Export
	
	DocumentData = GetDocumentData(Undefined, DocumentRef);
	
	If DocumentData.ErrorDescription = Undefined Then
		Return New Structure(
			"HeaderResults, ResultForTabularPart, ResultCurrencyExchangeRate",
			DocumentData.HeaderResults,
			DocumentData.ResultForTabularPart,
			DocumentData.ResultCurrencyExchangeRate);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Warehouse)";

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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Date                  AS Period,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Warehouse                 AS Warehouse,
	|	DocumentData.EmployeeResponsible         AS EmployeeResponsible,
	|	DocumentData.Department         AS Department,
	|	DocumentData.Comment           AS Comment,
	|	DocumentData.DeletionMark       AS DeletionMark,
	|	DocumentData.Posted              AS Posted
	|FROM
	|	Document.PhysicalCountReport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Number",                       Attributes.Number);
	Query.SetParameter("Period",                      Attributes.Period);
	Query.SetParameter("Organization",                 Attributes.Organization);
	Query.SetParameter("Warehouse",                       Attributes.Warehouse);
	Query.SetParameter("Department",               Attributes.Department);
	Query.SetParameter("EmployeeResponsible",               Attributes.EmployeeResponsible);
	Query.SetParameter("Comment",                 Attributes.Comment);
	Query.SetParameter("DeletionMark",             Attributes.DeletionMark);
	Query.SetParameter("Posted",                    Attributes.Posted);
	Query.SetParameter("BusinessOperation",       Enums.BusinessTransactions.PhysicalCountReport);
	
	Query.SetParameter("MetadataIdentifier",     Common.MetadataObjectID(
		"Document.PhysicalCountReport"));
	Query.SetParameter("NumberForPrinting",               ObjectsPrefixesClientServer.NumberForPrinting(
		Attributes.Number));
	
EndProcedure

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
	|	UNDEFINED                            AS Partner,
	|	UNDEFINED                            AS Counterparty,
	|	UNDEFINED                            AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
	|	&Department                          AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	CAST(&Comment AS STRING(100))  AS Comment,
	|	UNDEFINED                            AS Currency,
	|	0                                       AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.PhysicalCountReport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.PhysicalCountReport";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.PhysicalCountReport);
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
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

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	PhysicalCountReportLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// The function gets the data of the document.
// It is used for receiving data for the INV3 printing form and for uploading data during exchange.
//
// Returns:
// 	Structure - LongDesc:
// 	* HeaderResults	- QueryResult - Result of the request for the document header
// 						- Structure - returned in case of an error, contains data from the document:
// 							** StartDate - Date
// 							** EndDate - Date
// 	* ResultForTabularPart - QueryResult
// 	* ResultCurrencyExchangeRate - QueryResult
// 	* ErrorDescription - String, Undefined - if there are no errors - Undefined - otherwise the string ID of the error.
// 	* ByPriorCalculation - Boolean
// 
Function GetDocumentData(PrintParameters, DocumentBasis) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("HeaderResults");
	ReturnStructure.Insert("ResultForTabularPart");
	ReturnStructure.Insert("ResultCurrencyExchangeRate");
	ReturnStructure.Insert("ErrorDescription");
	ReturnStructure.Insert("ByPriorCalculation");
	
	ReturnStructure.ErrorDescription = Undefined;
	ReturnStructure.ByPriorCalculation = False;
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	If Not ValueIsFilled(ColumnOfCodes) Then
		ColumnOfCodes = "Code";
	EndIf;
		
	RequestingPreliminaryData = New Query;
	RequestingPreliminaryData.SetParameter("DocumentBasis", DocumentBasis);
	RequestingPreliminaryData.Text =
	"SELECT
	|	PhysicalCountReport.Date AS Date,
	|	PhysicalCountReport.StartDate,
	|	PhysicalCountReport.EndDate,
	|	PhysicalCountReport.PriceKind,
	|	PhysicalCountReport.Warehouse,
	|	PhysicalCountReport.SourseOfInformationAboutPricesForPrinting,
	|	PhysicalCountReport.Organization,
	|	InventoryCostCalculationCompanies.Ref.PreliminaryCalculation AS PreliminaryCalculation
	|FROM
	|	Document.PhysicalCountReport AS PhysicalCountReport
	|		LEFT JOIN Document.InventoryCostCalculation.Companies AS InventoryCostCalculationCompanies
	|		ON (InventoryCostCalculationCompanies.Organization = PhysicalCountReport.Organization)
	|			AND (InventoryCostCalculationCompanies.Ref.Posted)
	|			AND (InventoryCostCalculationCompanies.Ref.Date BETWEEN BEGINOFPERIOD(PhysicalCountReport.StartDate, MONTH) AND ENDOFPERIOD(PhysicalCountReport.EndDate, MONTH))
	|			AND InventoryCostCalculationCompanies.Ref.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|WHERE
	|	PhysicalCountReport.Ref = &DocumentBasis
	|
	|ORDER BY
	|	InventoryCostCalculationCompanies.Ref.Date DESC";
	
	PreliminaryDataResult = RequestingPreliminaryData.Execute().Select();
	If Not PreliminaryDataResult.Next() Then
		
		ReturnStructure.ErrorDescription = "NoInventoryInPeriod";
		Return ReturnStructure;
		
	EndIf;
	
	PreliminaryCalculation				= PreliminaryDataResult.PreliminaryCalculation;
	SourseOfInformationAboutPricesForPrinting	= PreliminaryDataResult.SourseOfInformationAboutPricesForPrinting;
	StartDate							= PreliminaryDataResult.StartDate;
	EndDate						= EndOfDay(PreliminaryDataResult.EndDate);
	EndOfMonthOfPeriod					= New Boundary(EndOfMonth(EndDate), BoundaryType.Including);
	Warehouse								= PreliminaryDataResult.Warehouse;	
	Organization							= PreliminaryDataResult.Organization;
	PriceKind								= PreliminaryDataResult.PriceKind;
	
	Query = New Query;
	Query.SetParameter("StartDate",			StartDate);
	Query.SetParameter("EndDate",		EndDate);
	Query.SetParameter("Warehouse",				Warehouse);
	Query.SetParameter("DateOfRemainingGoods",		EndDate + 1);
	Query.SetParameter("EndOfMonthOfPeriod",	EndOfMonthOfPeriod);
	Query.SetParameter("DocumentBasis",	DocumentBasis);
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("PriceKind",			PriceKind);
	
	// Responsible persons in printed form
	StructureOfResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Organization, EndOfDay(EndDate));
	Query.SetParameter("Director",						StructureOfResponsiblePersons.Director);
	Query.SetParameter("JobTitleExecutive",				StructureOfResponsiblePersons.DirectorJobTitle);
	Query.SetParameter("ChiefAccountant",					StructureOfResponsiblePersons.ChiefAccountant);
	Query.SetParameter("CostOfGoodsForPurposes",	CalculationOfCostCached.CostOfGoodsForPurposes(EndDate));
	
	If SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
		
		If PreliminaryCalculation = Null Then
			
			ReturnStructure.ErrorDescription = "NoPricesAtCost";
			ReturnStructure.HeaderResults = New Structure(
				"StartDate, EndDate",
				StartDate, EndDate
			);
			Return ReturnStructure;
			
		EndIf;
		
		If PreliminaryCalculation Then
			
			ReturnStructure.ByPriorCalculation = True;
			
			QueryText =
			"SELECT DISTINCT
			|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	NestedQuery.Organization AS Organization
			|INTO ProductsTable
			|FROM
			|	(SELECT
			|		Dimension.DimensionKey AS ItemsLocationAttributes,
			|		&Organization AS Organization
			|	FROM
			|		Document.InventoryRecount.Goods AS RecalculationOfGoods
			|			INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
			|			ON RecalculationOfGoods.Products = Dimension.Products
			|				AND RecalculationOfGoods.Characteristic = Dimension.Characteristic
			|				AND (VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement)
			|				AND RecalculationOfGoods.Purpose = Dimension.Purpose
			|				AND (RecalculationOfGoods.Series = Dimension.Series
			|					OR NOT RecalculationOfGoods.BatchesIndicationStatus = 14)
			|				AND RecalculationOfGoods.Ref.Warehouse = Dimension.StorageLocation
			|	WHERE
			|		RecalculationOfGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND RecalculationOfGoods.Ref.Warehouse = &Warehouse
			|		AND RecalculationOfGoods.Ref.Posted
			|		AND RecalculationOfGoods.Ref.Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		WriteOffOfShortagesOfGoods.ItemsLocationAttributes,
			|		&Organization
			|	FROM
			|		Document.WriteOffOfGoodsShortages.Goods AS WriteOffOfShortagesOfGoods
			|	WHERE
			|		WriteOffOfShortagesOfGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND WriteOffOfShortagesOfGoods.Ref.Warehouse = &Warehouse
			|		AND WriteOffOfShortagesOfGoods.Ref.Posted
			|		AND WriteOffOfShortagesOfGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		InventorySurplusRecognitionGoods.ItemsLocationAttributes,
			|		&Organization
			|	FROM
			|		Document.InventorySurplusRecognition.Goods AS InventorySurplusRecognitionGoods
			|	WHERE
			|		InventorySurplusRecognitionGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND InventorySurplusRecognitionGoods.Ref.Warehouse = &Warehouse
			|		AND InventorySurplusRecognitionGoods.Ref.Posted
			|		AND InventorySurplusRecognitionGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsMisgradingGoods.ItemsLocationAttributes,
			|		&Organization
			|	FROM
			|		Document.GoodsMisgrading.Goods AS GoodsMisgradingGoods
			|	WHERE
			|		GoodsMisgradingGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND GoodsMisgradingGoods.Ref.Warehouse = &Warehouse
			|		AND GoodsMisgradingGoods.Ref.Posted
			|		AND GoodsMisgradingGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsMisgradingGoods.ItemsLocationAttributesReceipt,
			|		&Organization
			|	FROM
			|		Document.GoodsMisgrading.Goods AS GoodsMisgradingGoods
			|	WHERE
			|		GoodsMisgradingGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND GoodsMisgradingGoods.Ref.Warehouse = &Warehouse
			|		AND GoodsMisgradingGoods.Ref.Posted
			|		AND GoodsMisgradingGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsDamageGoods.ItemsLocationAttributes,
			|		&Organization
			|	FROM
			|		Document.GoodsDamage.Goods AS GoodsDamageGoods
			|	WHERE
			|		GoodsDamageGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND GoodsDamageGoods.Ref.Warehouse = &Warehouse
			|		AND GoodsDamageGoods.Ref.Posted
			|		AND GoodsDamageGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Dimension.DimensionKey,
			|		&Organization
			|	FROM
			|		Document.GoodsDamage.Goods AS DamageToGoodsRegisteredGoods
			|			INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
			|			ON DamageToGoodsRegisteredGoods.ProductsRecordingAsReceived = Dimension.Products
			|				AND DamageToGoodsRegisteredGoods.CharacteristicRecordingAsReceived = Dimension.Characteristic
			|				AND DamageToGoodsRegisteredGoods.Purpose = Dimension.Purpose
			|				AND (VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement)
			|				AND (DamageToGoodsRegisteredGoods.Series = Dimension.Series
			|					OR NOT DamageToGoodsRegisteredGoods.BatchesIndicationStatus = 14)
			|				AND DamageToGoodsRegisteredGoods.Ref.Warehouse = Dimension.StorageLocation
			|	WHERE
			|		DamageToGoodsRegisteredGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND DamageToGoodsRegisteredGoods.Ref.Warehouse = &Warehouse
			|		AND DamageToGoodsRegisteredGoods.Ref.Posted
			|		AND DamageToGoodsRegisteredGoods.Ref.Organization = &Organization) AS NestedQuery
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	CompanyGoodsBalance.InventoryOwnerAttribute,
			|	CompanyGoodsBalance.CountBalance
			|INTO CompanyGoodsBalance
			|FROM
			|	AccumulationRegister.CompanyGoods.Balance(
			|			&DateOfRemainingGoods,
			|			ItemsLocationAttributes IN
			|					(SELECT DISTINCT
			|						ProductsTable.ItemsLocationAttributes
			|					FROM
			|						ProductsTable)
			|				AND Organization = &Organization
			|				AND InventoryOwnerAttribute.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods))) AS CompanyGoodsBalance
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	-CompanyGoods.Count AS DeviationInStorageUnits,
			|	0 AS Quantity_Actual
			|INTO InventoryItems
			|FROM
			|	AccumulationRegister.CompanyGoods AS CompanyGoods
			|WHERE
			|	CompanyGoods.Recorder REFS Document.WriteOffOfGoodsShortages
			|	AND CAST(CompanyGoods.Recorder AS Document.WriteOffOfGoodsShortages).Date BETWEEN &StartDate AND &EndDate
			|	AND CAST(CompanyGoods.Recorder AS Document.WriteOffOfGoodsShortages).Warehouse = &Warehouse
			|	AND CompanyGoods.Organization = &Organization
			|
			|UNION ALL
			|
			|SELECT
			|	CompanyGoods.ItemsLocationAttributes,
			|	CompanyGoods.InventoryOwnerAttribute,
			|	CompanyGoods.Count,
			|	0
			|FROM
			|	AccumulationRegister.CompanyGoods AS CompanyGoods
			|WHERE
			|	CompanyGoods.Recorder REFS Document.InventorySurplusRecognition
			|	AND CAST(CompanyGoods.Recorder AS Document.InventorySurplusRecognition).Date BETWEEN &StartDate AND &EndDate
			|	AND CAST(CompanyGoods.Recorder AS Document.InventorySurplusRecognition).Warehouse = &Warehouse
			|	AND CompanyGoods.Organization = &Organization
			|
			|UNION ALL
			|
			|SELECT
			|	CompanyGoods.ItemsLocationAttributes,
			|	CompanyGoods.InventoryOwnerAttribute,
			|	CASE
			|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN CompanyGoods.Count
			|		ELSE -CompanyGoods.Count
			|	END,
			|	0
			|FROM
			|	AccumulationRegister.CompanyGoods AS CompanyGoods
			|WHERE
			|	CompanyGoods.Recorder REFS Document.GoodsMisgrading
			|	AND CAST(CompanyGoods.Recorder AS Document.GoodsMisgrading).Date BETWEEN &StartDate AND &EndDate
			|	AND CAST(CompanyGoods.Recorder AS Document.GoodsMisgrading).Warehouse = &Warehouse
			|	AND CompanyGoods.Organization = &Organization
			|
			|UNION ALL
			|
			|SELECT
			|	CompanyGoods.ItemsLocationAttributes,
			|	CompanyGoods.InventoryOwnerAttribute,
			|	CASE
			|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN CompanyGoods.Count
			|		ELSE -CompanyGoods.Count
			|	END,
			|	0
			|FROM
			|	AccumulationRegister.CompanyGoods AS CompanyGoods
			|WHERE
			|	CompanyGoods.Recorder REFS Document.GoodsDamage
			|	AND CAST(CompanyGoods.Recorder AS Document.GoodsDamage).Date BETWEEN &StartDate AND &EndDate
			|	AND CAST(CompanyGoods.Recorder AS Document.GoodsDamage).Warehouse = &Warehouse
			|	AND CompanyGoods.Organization = &Organization
			|
			|UNION ALL
			|
			|SELECT
			|	ProductsTable.ItemsLocationAttributes,
			|	CompanyGoodsBalance.InventoryOwnerAttribute,
			|	0,
			|	CompanyGoodsBalance.CountBalance
			|FROM
			|	ProductsTable AS ProductsTable
			|		INNER JOIN CompanyGoodsBalance AS CompanyGoodsBalance
			|		ON ProductsTable.ItemsLocationAttributes = CompanyGoodsBalance.ItemsLocationAttributes
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventoryItems.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	InventoryItems.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	&Organization AS Organization,
			|	SUM(InventoryItems.Quantity_Actual) AS Quantity_Actual,
			|	SUM(InventoryItems.Quantity_Actual - InventoryItems.DeviationInStorageUnits) AS QuantityByAccount
			|INTO InventoryTable_
			|FROM
			|	InventoryItems AS InventoryItems
			|
			|GROUP BY
			|	InventoryItems.ItemsLocationAttributes,
			|	InventoryItems.InventoryOwnerAttribute
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	&Director AS Director,
			|	&JobTitleExecutive AS JobTitleExecutive,
			|	&ChiefAccountant AS ChiefAccountant,
			|	&Organization AS Organization,
			|	CAST(&Organization AS Catalog.Companies).NCBOCode AS OrganizationForOkpo,
			|	CAST(&Organization AS Catalog.Companies).Prefix AS Prefix,
			|	PhysicalCountReport.Warehouse.CurrentEmployeeInChargeTypes AS Warehouseman,
			|	PhysicalCountReport.Warehouse.CurrentPositionOfTheResponsiblePerson AS StorekeeperPosition,
			|	PhysicalCountReport.Warehouse.Description AS DepartmentPresentation,
			|	&StartDate AS StartDate,
			|	&EndDate AS EndDate,
			|	PhysicalCountReport.Warehouse AS Warehouse,
			|	PhysicalCountReport.Date AS ReferenceDocumentDateForPrintForms,
			|	PhysicalCountReport.Number AS BaseDocumentNumber,
			|	PhysicalCountReport.Number AS DocumentNumber,
			|	PhysicalCountReport.Date AS DocumentDate,
			|	PhysicalCountReport.Ref AS Ref,
			|	&EndDate AS DateOfWithdrawalOfBalances
			|FROM
			|	Document.PhysicalCountReport AS PhysicalCountReport
			|WHERE
			|	PhysicalCountReport.Ref = &DocumentBasis
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ItemsPrices.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	ItemsPrices.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	ItemsPrices.Organization AS Organization,
			|	(ItemsPrices.LocalCost
			|		+ ItemsPrices.AddExpensesLocal
			|		+ ItemsPrices.LaborCostsLocal
			|		+ ItemsPrices.ItemizedFixedCostsCompl
			|		+ ItemsPrices.ItemizedVariableCostsCompl) AS LocalCost
			|INTO ItemsPrices
			|FROM
			|	InformationRegister.GoodsCost.SliceLast(
			|			&EndDate,
			|			(ItemsLocationAttributes, InventoryOwnerAttribute, AccountingSection, Organization) IN
			|				(SELECT
			|					Table.ItemsLocationAttributes,
			|					Table.InventoryOwnerAttribute,
			|					VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
			|					Table.Organization
			|				FROM
			|					InventoryTable_ AS Table)) AS ItemsPrices
			|WHERE
			|	&CostOfGoodsForPurposes
			|
			|UNION ALL
			|
			|SELECT
			|	ItemsPrices.ItemsLocationAttributes,
			|	ItemsPrices.InventoryOwnerAttribute,
			|	ItemsPrices.Organization,
			|	(ItemsPrices.LocalCost
			|		+ ItemsPrices.AddExpensesLocal
			|		+ ItemsPrices.LaborCostsLocal
			|		+ ItemsPrices.ItemizedFixedCostsCompl
			|		+ ItemsPrices.ItemizedVariableCostsCompl)
			|FROM
			|	InformationRegister.GoodsCost.SliceLast(
			|			&EndDate,
			|			(ItemsLocationAttributes.Products, ItemsLocationAttributes.Characteristic, ItemsLocationAttributes.Series, ItemsLocationAttributes.StorageLocation, ItemsLocationAttributes.ProductCostElement, InventoryOwnerAttribute, AccountingSection, Organization) IN
			|				(SELECT
			|					ItemsLocationAttributes.Products, ItemsLocationAttributes.Characteristic, ItemsLocationAttributes.Series, ItemsLocationAttributes.StorageLocation, ItemsLocationAttributes.ProductCostElement,
			|					Table.InventoryOwnerAttribute,
			|					VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
			|					Table.Organization
			|				FROM
			|					InventoryTable_ AS Table)) AS ItemsPrices
			|
			|WHERE
			|	NOT &CostOfGoodsForPurposes
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventoryTable_.ItemsLocationAttributes.Products AS Products,
			|	InventoryTable_.ItemsLocationAttributes.Characteristic AS Characteristic,
			|	InventoryTable_.ItemsLocationAttributes.Series AS Series,
			|	InventoryTable_.ItemsLocationAttributes.Products.DescriptionFull AS ProductItemName,
			|	InventoryTable_.ItemsLocationAttributes.Characteristic.DescriptionFull AS CharacteristicName,
			|	InventoryTable_.ItemsLocationAttributes.Series.Description AS SeriesName_,
			|	SUM(InventoryTable_.QuantityByAccount) AS QuantityByAccount,
			|	SUM(InventoryTable_.Quantity_Actual) AS Quantity_Actual,
			|	ISNULL(ItemsPrices.LocalCost, 0) AS Price,
			|	SUM(InventoryTable_.QuantityByAccount * ISNULL(ItemsPrices.LocalCost, 0)) AS AccountInAccounting,
			|	SUM(InventoryTable_.Quantity_Actual * ISNULL(ItemsPrices.LocalCost, 0)) AS Amount_Actual,
			|	InventoryTable_.ItemsLocationAttributes.Products.Code AS ProductCode_,
			|	InventoryTable_.ItemsLocationAttributes.Products.UnitOfMeasure.Code AS UnitOfMeasureCode,
			|	InventoryTable_.ItemsLocationAttributes.Products.UnitOfMeasure.Description AS UnitOfMeasurementName,
			|	FALSE AS ThisIsReusablePackage
			|FROM
			|	InventoryTable_ AS InventoryTable_
			|		LEFT JOIN ItemsPrices AS ItemsPrices
			|		ON InventoryTable_.ItemsLocationAttributes = ItemsPrices.ItemsLocationAttributes
			|			AND InventoryTable_.InventoryOwnerAttribute = ItemsPrices.InventoryOwnerAttribute
			|			AND ItemsPrices.Organization = &Organization
			|
			|GROUP BY
			|	InventoryTable_.ItemsLocationAttributes.Products,
			|	InventoryTable_.ItemsLocationAttributes.Characteristic.DescriptionFull,
			|	InventoryTable_.ItemsLocationAttributes.Series.Description,
			|	ISNULL(ItemsPrices.LocalCost, 0),
			|	InventoryTable_.ItemsLocationAttributes.Products.UnitOfMeasure.Code,
			|	InventoryTable_.ItemsLocationAttributes.Products.UnitOfMeasure.Description,
			|	InventoryTable_.ItemsLocationAttributes.Products.DescriptionFull,
			|	InventoryTable_.ItemsLocationAttributes.Products.Code,
			|	InventoryTable_.ItemsLocationAttributes.Characteristic,
			|	InventoryTable_.ItemsLocationAttributes.Series
			|
			|ORDER BY
			|	ProductItemName,
			|	Products";
			
			QueryText = StrReplace(QueryText, "Products.Code", "Products." + ColumnOfCodes);
			Query.Text = QueryText;
			
			Results = Query.ExecuteBatch();
			HeaderResults = Results[4];
			ResultForTabularPart = Results[6];
			ResultCurrencyExchangeRate = Undefined;
			
		Else
			
			// actual calculation
			
			QueryText =
			"SELECT DISTINCT
			|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	NestedQuery.Organization AS Organization
			|INTO ProductsTable
			|FROM
			|	(SELECT
			|		Dimension.DimensionKey AS ItemsLocationAttributes,
			|		&Organization AS Organization
			|	FROM
			|		Document.InventoryRecount.Goods AS RecalculationOfGoods
			|			INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
			|			ON RecalculationOfGoods.Products = Dimension.Products
			|				AND RecalculationOfGoods.Characteristic = Dimension.Characteristic
			|				AND RecalculationOfGoods.Purpose = Dimension.Purpose
			|				AND (VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement)
			|				AND (RecalculationOfGoods.Series = Dimension.Series
			|					OR NOT RecalculationOfGoods.BatchesIndicationStatus = 14)
			|				AND RecalculationOfGoods.Ref.Warehouse = Dimension.StorageLocation
			|	WHERE
			|		RecalculationOfGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND RecalculationOfGoods.Ref.Warehouse = &Warehouse
			|		AND RecalculationOfGoods.Ref.Posted
			|		AND RecalculationOfGoods.Ref.Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		WriteOffOfShortagesOfGoods.ItemsLocationAttributes,
			|		&Organization
			|	FROM
			|		Document.WriteOffOfGoodsShortages.Goods AS WriteOffOfShortagesOfGoods
			|	WHERE
			|		WriteOffOfShortagesOfGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND WriteOffOfShortagesOfGoods.Ref.Warehouse = &Warehouse
			|		AND WriteOffOfShortagesOfGoods.Ref.Posted
			|		AND WriteOffOfShortagesOfGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		InventorySurplusRecognitionGoods.ItemsLocationAttributes,
			|		&Organization
			|	FROM
			|		Document.InventorySurplusRecognition.Goods AS InventorySurplusRecognitionGoods
			|	WHERE
			|		InventorySurplusRecognitionGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND InventorySurplusRecognitionGoods.Ref.Warehouse = &Warehouse
			|		AND InventorySurplusRecognitionGoods.Ref.Posted
			|		AND InventorySurplusRecognitionGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsMisgradingGoods.ItemsLocationAttributes,
			|		&Organization
			|	FROM
			|		Document.GoodsMisgrading.Goods AS GoodsMisgradingGoods
			|	WHERE
			|		GoodsMisgradingGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND GoodsMisgradingGoods.Ref.Warehouse = &Warehouse
			|		AND GoodsMisgradingGoods.Ref.Posted
			|		AND GoodsMisgradingGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsMisgradingGoods.ItemsLocationAttributesReceipt,
			|		&Organization
			|	FROM
			|		Document.GoodsMisgrading.Goods AS GoodsMisgradingGoods
			|	WHERE
			|		GoodsMisgradingGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND GoodsMisgradingGoods.Ref.Warehouse = &Warehouse
			|		AND GoodsMisgradingGoods.Ref.Posted
			|		AND GoodsMisgradingGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsDamageGoods.ItemsLocationAttributes,
			|		&Organization
			|	FROM
			|		Document.GoodsDamage.Goods AS GoodsDamageGoods
			|	WHERE
			|		GoodsDamageGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND GoodsDamageGoods.Ref.Warehouse = &Warehouse
			|		AND GoodsDamageGoods.Ref.Posted
			|		AND GoodsDamageGoods.Ref.Organization = &Organization
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Dimension.DimensionKey,
			|		&Organization
			|	FROM
			|		Document.GoodsDamage.Goods AS DamageToGoodsRegisteredGoods
			|			INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
			|			ON DamageToGoodsRegisteredGoods.ProductsRecordingAsReceived = Dimension.Products
			|				AND DamageToGoodsRegisteredGoods.CharacteristicRecordingAsReceived = Dimension.Characteristic
			|				AND (VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement)
			|				AND DamageToGoodsRegisteredGoods.Purpose = Dimension.Purpose
			|				AND (DamageToGoodsRegisteredGoods.Series = Dimension.Series
			|					OR NOT DamageToGoodsRegisteredGoods.BatchesIndicationStatus = 14)
			|				AND DamageToGoodsRegisteredGoods.Ref.Warehouse = Dimension.StorageLocation
			|	WHERE
			|		DamageToGoodsRegisteredGoods.Ref.Date BETWEEN &StartDate AND &EndDate
			|		AND DamageToGoodsRegisteredGoods.Ref.Warehouse = &Warehouse
			|		AND DamageToGoodsRegisteredGoods.Ref.Posted
			|		AND DamageToGoodsRegisteredGoods.Ref.Organization = &Organization) AS NestedQuery
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	CompanyGoodsBalance.InventoryOwnerAttribute,
			|	CompanyGoodsBalance.CountBalance
			|INTO CompanyGoodsBalance
			|FROM
			|	AccumulationRegister.CompanyGoods.Balance(
			|			&DateOfRemainingGoods,
			|			ItemsLocationAttributes IN
			|					(SELECT DISTINCT
			|						ProductsTable.ItemsLocationAttributes
			|					FROM
			|						ProductsTable)
			|				AND Organization = &Organization
			|				AND InventoryOwnerAttribute.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods))) AS CompanyGoodsBalance
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	-CompanyGoods.Count AS DeviationInStorageUnits,
			|	0 AS Quantity_Actual
			|INTO InventoryItems
			|FROM
			|	AccumulationRegister.CompanyGoods AS CompanyGoods
			|WHERE
			|	CompanyGoods.Recorder REFS Document.WriteOffOfGoodsShortages
			|	AND CAST(CompanyGoods.Recorder AS Document.WriteOffOfGoodsShortages).Date BETWEEN &StartDate AND &EndDate
			|	AND CAST(CompanyGoods.Recorder AS Document.WriteOffOfGoodsShortages).Warehouse = &Warehouse
			|	AND CompanyGoods.Organization = &Organization
			|
			|UNION ALL
			|
			|SELECT
			|	CompanyGoods.ItemsLocationAttributes,
			|	CompanyGoods.InventoryOwnerAttribute,
			|	CompanyGoods.Count,
			|	0
			|FROM
			|	AccumulationRegister.CompanyGoods AS CompanyGoods
			|WHERE
			|	CompanyGoods.Recorder REFS Document.InventorySurplusRecognition
			|	AND CAST(CompanyGoods.Recorder AS Document.InventorySurplusRecognition).Date BETWEEN &StartDate AND &EndDate
			|	AND CAST(CompanyGoods.Recorder AS Document.InventorySurplusRecognition).Warehouse = &Warehouse
			|	AND CompanyGoods.Organization = &Organization
			|
			|UNION ALL
			|
			|SELECT
			|	CompanyGoods.ItemsLocationAttributes,
			|	CompanyGoods.InventoryOwnerAttribute,
			|	CASE
			|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN CompanyGoods.Count
			|		ELSE -CompanyGoods.Count
			|	END,
			|	0
			|FROM
			|	AccumulationRegister.CompanyGoods AS CompanyGoods
			|WHERE
			|	CompanyGoods.Recorder REFS Document.GoodsMisgrading
			|	AND CAST(CompanyGoods.Recorder AS Document.GoodsMisgrading).Date BETWEEN &StartDate AND &EndDate
			|	AND CAST(CompanyGoods.Recorder AS Document.GoodsMisgrading).Warehouse = &Warehouse
			|	AND CompanyGoods.Organization = &Organization
			|
			|UNION ALL
			|
			|SELECT
			|	CompanyGoods.ItemsLocationAttributes,
			|	CompanyGoods.InventoryOwnerAttribute,
			|	CASE
			|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN CompanyGoods.Count
			|		ELSE -CompanyGoods.Count
			|	END,
			|	0
			|FROM
			|	AccumulationRegister.CompanyGoods AS CompanyGoods
			|WHERE
			|	CompanyGoods.Recorder REFS Document.GoodsDamage
			|	AND CAST(CompanyGoods.Recorder AS Document.GoodsDamage).Date BETWEEN &StartDate AND &EndDate
			|	AND CAST(CompanyGoods.Recorder AS Document.GoodsDamage).Warehouse = &Warehouse
			|	AND CompanyGoods.Organization = &Organization
			|
			|UNION ALL
			|
			|SELECT
			|	ProductsTable.ItemsLocationAttributes,
			|	CompanyGoodsBalance.InventoryOwnerAttribute,
			|	0,
			|	CompanyGoodsBalance.CountBalance
			|FROM
			|	ProductsTable AS ProductsTable
			|		INNER JOIN CompanyGoodsBalance AS CompanyGoodsBalance
			|		ON ProductsTable.ItemsLocationAttributes = CompanyGoodsBalance.ItemsLocationAttributes
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	GoodsToBeRegisteredInReportsToConsignor.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	GoodsToBeRegisteredInReportsToConsignor.CorInventoryOwnerAttribute AS New_KindOfInventory,
			|	GoodsToBeRegisteredInReportsToConsignor.ItemsLocationAttributes AS ItemsLocationAttributes
			|INTO TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods
			|FROM
			|	InventoryItems AS InventoryItems
			|		INNER JOIN AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsToBeRegisteredInReportsToConsignor
			|		ON (GoodsToBeRegisteredInReportsToConsignor.InventoryOwnerAttribute = InventoryItems.InventoryOwnerAttribute)
			|			AND (GoodsToBeRegisteredInReportsToConsignor.ItemsLocationAttributes.Products = InventoryItems.ItemsLocationAttributes.Products)
			|			AND (GoodsToBeRegisteredInReportsToConsignor.ItemsLocationAttributes.Characteristic = InventoryItems.ItemsLocationAttributes.Characteristic)
			|			AND InventoryItems.ItemsLocationAttributes.Series = GoodsToBeRegisteredInReportsToConsignor.ItemsLocationAttributes.Series
			|WHERE
			|	InventoryItems.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
			|	AND GoodsToBeRegisteredInReportsToConsignor.CorInventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CASE
			|		WHEN TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.InventoryOwnerAttribute IS NULL 
			|			THEN InventoryItems.ItemsLocationAttributes
			|		ELSE TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.ItemsLocationAttributes
			|	END AS ItemsLocationAttributes,
			|	CASE
			|		WHEN TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.InventoryOwnerAttribute IS NULL 
			|			THEN InventoryItems.InventoryOwnerAttribute
			|		ELSE TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.New_KindOfInventory
			|	END AS InventoryOwnerAttribute,
			|	&Organization AS Organization,
			|	SUM(InventoryItems.Quantity_Actual) AS Quantity_Actual,
			|	SUM(InventoryItems.Quantity_Actual - InventoryItems.DeviationInStorageUnits) AS QuantityByAccount
			|INTO InventoryTable_
			|FROM
			|	InventoryItems AS InventoryItems
			|		LEFT JOIN TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods AS TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods
			|		ON (TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.InventoryOwnerAttribute = InventoryItems.InventoryOwnerAttribute)
			|			AND (TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.ItemsLocationAttributes.Products = InventoryItems.ItemsLocationAttributes.Products)
			|			AND (TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.ItemsLocationAttributes.Characteristic = InventoryItems.ItemsLocationAttributes.Characteristic)
			|			AND (TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.ItemsLocationAttributes.Series = InventoryItems.ItemsLocationAttributes.Series)
			|
			|GROUP BY
			|	CASE
			|		WHEN TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.InventoryOwnerAttribute IS NULL 
			|			THEN InventoryItems.ItemsLocationAttributes
			|		ELSE TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.ItemsLocationAttributes
			|	END,
			|	CASE
			|		WHEN TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.InventoryOwnerAttribute IS NULL 
			|			THEN InventoryItems.InventoryOwnerAttribute
			|		ELSE TypesOfStocksAndMethodsOfAccountingForProductRangeOfCommissionGoods.New_KindOfInventory
			|	END
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventoryCostBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	InventoryCostBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	InventoryCostBalance.Organization AS Organization,
			|	CASE
			|		WHEN InventoryCostBalance.CountBalance = 0
			|			THEN 0
			|		ELSE (InventoryCostBalance.LocalCostBalance
			|				+ InventoryCostBalance.AddExpensesLocalBalance
			|				+ InventoryCostBalance.LaborCostsLocalBalance
			|				+ InventoryCostBalance.ItemizedFixedCostsComplBalance
			|				+ InventoryCostBalance.ItemizedVariableCostsComplBalance)
			|			/ InventoryCostBalance.CountBalance
			|	END AS Price
			|INTO InventoryCostBalance
			|FROM
			|	AccumulationRegister.InventoryCost.Balance(
			|			&EndOfMonthOfPeriod,
			|			(ItemsLocationAttributes, InventoryOwnerAttribute, Organization) IN
			|				(SELECT
			|					Table.ItemsLocationAttributes,
			|					Table.InventoryOwnerAttribute,
			|					Table.Organization
			|				FROM
			|					InventoryTable_ AS Table)) AS InventoryCostBalance
			|WHERE
			|	&CostOfGoodsForPurposes
			|
			|UNION ALL
			|
			|SELECT
			|	InventoryCostBalance.ItemsLocationAttributes,
			|	InventoryCostBalance.InventoryOwnerAttribute,
			|	InventoryCostBalance.Organization,
			|	CASE
			|		WHEN InventoryCostBalance.CountBalance = 0
			|			THEN 0
			|		ELSE (InventoryCostBalance.LocalCostBalance
			|				+ InventoryCostBalance.AddExpensesLocalBalance
			|				+ InventoryCostBalance.LaborCostsLocalBalance
			|				+ InventoryCostBalance.ItemizedFixedCostsComplBalance
			|				+ InventoryCostBalance.ItemizedVariableCostsComplBalance)
			|			/ InventoryCostBalance.CountBalance
			|	END
			|FROM
			|	AccumulationRegister.InventoryCost.Balance(
			|			&EndOfMonthOfPeriod,
			|			(ItemsLocationAttributes.Products,
			|				ItemsLocationAttributes.Characteristic,
			|				ItemsLocationAttributes.Series,
			|				ItemsLocationAttributes.StorageLocation,
			|				ItemsLocationAttributes.ProductCostElement,
			|				InventoryOwnerAttribute, Organization) IN
			|				(SELECT
			|					Table.ItemsLocationAttributes.Products,
			|					Table.ItemsLocationAttributes.Characteristic,
			|					Table.ItemsLocationAttributes.Series,
			|					Table.ItemsLocationAttributes.StorageLocation,
			|					Table.ItemsLocationAttributes.ProductCostElement,
			|					Table.InventoryOwnerAttribute,
			|					Table.Organization
			|				FROM
			|					InventoryTable_ AS Table)) AS InventoryCostBalance
			|
			|WHERE
			|	NOT &CostOfGoodsForPurposes
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CostOfGoodsCut.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	CostOfGoodsCut.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	CostOfGoodsCut.Organization AS Organization,
			|	(CostOfGoodsCut.LocalCost
			|		+ CostOfGoodsCut.AddExpensesLocal
			|		+ CostOfGoodsCut.LaborCostsLocal
			|		+ CostOfGoodsCut.ItemizedFixedCostsCompl
			|		+ CostOfGoodsCut.ItemizedVariableCostsCompl) AS Price
			|INTO CostOfGoodsCut
			|FROM
			|	InformationRegister.GoodsCost.SliceLast(
			|			&EndDate,
			|			(ItemsLocationAttributes, InventoryOwnerAttribute, AccountingSection, Organization) IN
			|				(SELECT
			|					Table.ItemsLocationAttributes,
			|					Table.InventoryOwnerAttribute,
			|					VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
			|					Table.Organization
			|				FROM
			|					InventoryTable_ AS Table)) AS CostOfGoodsCut
			|WHERE
			|	&CostOfGoodsForPurposes
			|
			|UNION ALL
			|
			|SELECT
			|	CostOfGoodsCut.ItemsLocationAttributes,
			|	CostOfGoodsCut.InventoryOwnerAttribute,
			|	CostOfGoodsCut.Organization,
			|	(CostOfGoodsCut.LocalCost
			|		+ CostOfGoodsCut.AddExpensesLocal
			|		+ CostOfGoodsCut.LaborCostsLocal
			|		+ CostOfGoodsCut.ItemizedFixedCostsCompl
			|		+ CostOfGoodsCut.ItemizedVariableCostsCompl)
			|FROM
			|	InformationRegister.GoodsCost.SliceLast(
			|			&EndDate,
			|			(ItemsLocationAttributes.Products,
			|				ItemsLocationAttributes.Characteristic,
			|				ItemsLocationAttributes.Series,
			|				ItemsLocationAttributes.StorageLocation,
			|				ItemsLocationAttributes.ProductCostElement,
			|				InventoryOwnerAttribute,
			|				AccountingSection,
			|				Organization) IN
			|				(SELECT
			|					Table.ItemsLocationAttributes.Products,
			|					Table.ItemsLocationAttributes.Characteristic,
			|					Table.ItemsLocationAttributes.Series,
			|					Table.ItemsLocationAttributes.StorageLocation,
			|					Table.ItemsLocationAttributes.ProductCostElement,
			|					Table.InventoryOwnerAttribute,
			|					VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
			|					Table.Organization
			|				FROM
			|					InventoryTable_ AS Table)) AS CostOfGoodsCut
			|
			|WHERE
			|	NOT &CostOfGoodsForPurposes
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventoryTable_.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	InventoryTable_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	CASE
			|		WHEN ISNULL(InventoryCostBalance.Price, 0) = 0
			|			THEN ISNULL(CostOfGoodsCut.Price, 0)
			|		ELSE InventoryCostBalance.Price
			|	END AS Price
			|INTO Price_Table
			|FROM
			|	InventoryTable_ AS InventoryTable_
			|		LEFT JOIN InventoryCostBalance AS InventoryCostBalance
			|		ON InventoryTable_.ItemsLocationAttributes = InventoryCostBalance.ItemsLocationAttributes
			|			AND (InventoryTable_.InventoryOwnerAttribute = InventoryCostBalance.InventoryOwnerAttribute)
			|			AND (InventoryCostBalance.Organization = &Organization)
			|		LEFT JOIN CostOfGoodsCut AS CostOfGoodsCut
			|		ON InventoryTable_.ItemsLocationAttributes = CostOfGoodsCut.ItemsLocationAttributes
			|			AND (InventoryTable_.InventoryOwnerAttribute = CostOfGoodsCut.InventoryOwnerAttribute)
			|			AND (CostOfGoodsCut.Organization = &Organization)
			|WHERE
			|	&CostOfGoodsForPurposes
			|
			|GROUP BY
			|	InventoryTable_.ItemsLocationAttributes,
			|	CASE
			|		WHEN ISNULL(InventoryCostBalance.Price, 0) = 0
			|			THEN ISNULL(CostOfGoodsCut.Price, 0)
			|		ELSE InventoryCostBalance.Price
			|	END,
			|	InventoryTable_.InventoryOwnerAttribute
			|
			|UNION ALL
			|
			|SELECT
			|	InventoryTable_.ItemsLocationAttributes,
			|	InventoryTable_.InventoryOwnerAttribute,
			|	CASE
			|		WHEN ISNULL(InventoryCostBalance.Price, 0) = 0
			|			THEN ISNULL(CostOfGoodsCut.Price, 0)
			|		ELSE InventoryCostBalance.Price
			|	END AS Price
			|FROM
			|	InventoryTable_ AS InventoryTable_
			|		LEFT JOIN InventoryCostBalance AS InventoryCostBalance
			|		ON InventoryTable_.ItemsLocationAttributes.Products = InventoryCostBalance.ItemsLocationAttributes.Products
			|			AND InventoryTable_.ItemsLocationAttributes.Characteristic = InventoryCostBalance.ItemsLocationAttributes.Characteristic
			|			AND InventoryTable_.ItemsLocationAttributes.Series = InventoryCostBalance.ItemsLocationAttributes.Series
			|			AND InventoryTable_.ItemsLocationAttributes.StorageLocation = InventoryCostBalance.ItemsLocationAttributes.StorageLocation
			|			AND InventoryTable_.ItemsLocationAttributes.ProductCostElement = InventoryCostBalance.ItemsLocationAttributes.ProductCostElement
			|			AND (InventoryTable_.InventoryOwnerAttribute = InventoryCostBalance.InventoryOwnerAttribute)
			|			AND (InventoryCostBalance.Organization = &Organization)
			|		LEFT JOIN CostOfGoodsCut AS CostOfGoodsCut
			|		ON InventoryTable_.ItemsLocationAttributes.Products = CostOfGoodsCut.ItemsLocationAttributes.Products
			|			AND InventoryTable_.ItemsLocationAttributes.Characteristic = CostOfGoodsCut.ItemsLocationAttributes.Characteristic
			|			AND InventoryTable_.ItemsLocationAttributes.Series = CostOfGoodsCut.ItemsLocationAttributes.Series
			|			AND InventoryTable_.ItemsLocationAttributes.StorageLocation = CostOfGoodsCut.ItemsLocationAttributes.StorageLocation
			|			AND InventoryTable_.ItemsLocationAttributes.ProductCostElement = CostOfGoodsCut.ItemsLocationAttributes.ProductCostElement
			|			AND (InventoryTable_.InventoryOwnerAttribute = CostOfGoodsCut.InventoryOwnerAttribute)
			|		AND (CostOfGoodsCut.Organization = &Organization)
			|
			|WHERE
			|	NOT &CostOfGoodsForPurposes
			|
			|GROUP BY
			|	InventoryTable_.ItemsLocationAttributes,
			|	CASE
			|		WHEN ISNULL(InventoryCostBalance.Price, 0) = 0
			|			THEN ISNULL(CostOfGoodsCut.Price, 0)
			|		ELSE InventoryCostBalance.Price
			|	END,
			|	InventoryTable_.InventoryOwnerAttribute
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	&Director AS Director,
			|	&JobTitleExecutive AS JobTitleExecutive,
			|	&ChiefAccountant AS ChiefAccountant,
			|	&Organization AS Organization,
			|	CAST(&Organization AS Catalog.Companies).NCBOCode AS OrganizationForOkpo,
			|	CAST(&Organization AS Catalog.Companies).Prefix AS Prefix,
			|	PhysicalCountReport.Warehouse.CurrentEmployeeInChargeTypes AS Warehouseman,
			|	PhysicalCountReport.Warehouse.CurrentPositionOfTheResponsiblePerson AS StorekeeperPosition,
			|	PhysicalCountReport.Warehouse.Description AS DepartmentPresentation,
			|	&StartDate AS StartDate,
			|	&EndDate AS EndDate,
			|	PhysicalCountReport.Warehouse AS Warehouse,
			|	PhysicalCountReport.Date AS ReferenceDocumentDateForPrintForms,
			|	PhysicalCountReport.Number AS BaseDocumentNumber,
			|	PhysicalCountReport.Number AS DocumentNumber,
			|	PhysicalCountReport.Date AS DocumentDate,
			|	PhysicalCountReport.Ref AS Ref,
			|	&EndDate AS DateOfWithdrawalOfBalances
			|FROM
			|	Document.PhysicalCountReport AS PhysicalCountReport
			|WHERE
			|	PhysicalCountReport.Ref = &DocumentBasis
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventoryTable_.ItemsLocationAttributes.Products AS Products,
			|	InventoryTable_.ItemsLocationAttributes.Characteristic AS Characteristic,
			|	InventoryTable_.ItemsLocationAttributes.Series AS Series,
			|	InventoryTable_.ItemsLocationAttributes.Products.DescriptionFull AS ProductItemName,
			|	InventoryTable_.ItemsLocationAttributes.Characteristic.DescriptionFull AS CharacteristicName,
			|	InventoryTable_.ItemsLocationAttributes.Series.Description AS SeriesName_,
			|	SUM(InventoryTable_.QuantityByAccount) AS QuantityByAccount,
			|	SUM(InventoryTable_.Quantity_Actual) AS Quantity_Actual,
			|	Price_Table.Price AS Price,
			|	SUM(InventoryTable_.QuantityByAccount * Price_Table.Price) AS AccountInAccounting,
			|	SUM(InventoryTable_.Quantity_Actual * Price_Table.Price) AS Amount_Actual,
			|	InventoryTable_.ItemsLocationAttributes.Products.UnitOfMeasure.Code AS UnitOfMeasureCode,
			|	InventoryTable_.ItemsLocationAttributes.Products.UnitOfMeasure.Description AS UnitOfMeasurementName,
			|	InventoryTable_.ItemsLocationAttributes.Products.Code AS ProductCode_,
			|	FALSE AS ThisIsReusablePackage
			|FROM
			|	InventoryTable_ AS InventoryTable_
			|		LEFT JOIN Price_Table AS Price_Table
			|		ON InventoryTable_.ItemsLocationAttributes = Price_Table.ItemsLocationAttributes
			|			AND InventoryTable_.InventoryOwnerAttribute = Price_Table.InventoryOwnerAttribute
			|
			|GROUP BY
			|	InventoryTable_.ItemsLocationAttributes.Products,
			|	InventoryTable_.ItemsLocationAttributes.Characteristic.DescriptionFull,
			|	InventoryTable_.ItemsLocationAttributes.Series.Description,
			|	InventoryTable_.ItemsLocationAttributes.Products.UnitOfMeasure.Code,
			|	InventoryTable_.ItemsLocationAttributes.Products.UnitOfMeasure.Description,
			|	InventoryTable_.ItemsLocationAttributes.Products.DescriptionFull,
			|	InventoryTable_.ItemsLocationAttributes.Products.Code,
			|	Price_Table.Price,
			|	InventoryTable_.ItemsLocationAttributes.Characteristic,
			|	InventoryTable_.ItemsLocationAttributes.Series
			|
			|ORDER BY
			|	ProductItemName,
			|	Products";
			
			QueryText = StrReplace(QueryText, "Products.Code", "Products." + ColumnOfCodes);
			Query.Text = QueryText;
			
			Results = Query.ExecuteBatch();
			HeaderResults = Results[8];
			ResultForTabularPart = Results[9];
			ResultCurrencyExchangeRate = Undefined;
			
		EndIf;
		
	ElsIf SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType Then
		
		QueryText =
		"SELECT DISTINCT
		|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	NestedQuery.Organization AS Organization
		|INTO ProductsTable
		|FROM
		|	(SELECT
		|		Dimension.DimensionKey AS ItemsLocationAttributes,
		|		&Organization AS Organization
		|	FROM
		|		Document.InventoryRecount.Goods AS RecalculationOfGoods
		|			INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
		|			ON RecalculationOfGoods.Products = Dimension.Products
		|				AND RecalculationOfGoods.Characteristic = Dimension.Characteristic
		|				AND RecalculationOfGoods.Purpose = Dimension.Purpose
		|				AND (VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement)
		|				AND (RecalculationOfGoods.Series = Dimension.Series
		|					OR NOT RecalculationOfGoods.BatchesIndicationStatus = 14)
		|				AND RecalculationOfGoods.Ref.Warehouse = Dimension.StorageLocation
		|	WHERE
		|		RecalculationOfGoods.Ref.Date BETWEEN &StartDate AND &EndDate
		|		AND RecalculationOfGoods.Ref.Warehouse = &Warehouse
		|		AND RecalculationOfGoods.Ref.Posted
		|		AND RecalculationOfGoods.Ref.Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		WriteOffOfShortagesOfGoods.ItemsLocationAttributes,
		|		&Organization
		|	FROM
		|		Document.WriteOffOfGoodsShortages.Goods AS WriteOffOfShortagesOfGoods
		|	WHERE
		|		WriteOffOfShortagesOfGoods.Ref.Date BETWEEN &StartDate AND &EndDate
		|		AND WriteOffOfShortagesOfGoods.Ref.Warehouse = &Warehouse
		|		AND WriteOffOfShortagesOfGoods.Ref.Posted
		|		AND WriteOffOfShortagesOfGoods.Ref.Organization = &Organization
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		InventorySurplusRecognitionGoods.ItemsLocationAttributes,
		|		&Organization
		|	FROM
		|		Document.InventorySurplusRecognition.Goods AS InventorySurplusRecognitionGoods
		|	WHERE
		|		InventorySurplusRecognitionGoods.Ref.Date BETWEEN &StartDate AND &EndDate
		|		AND InventorySurplusRecognitionGoods.Ref.Warehouse = &Warehouse
		|		AND InventorySurplusRecognitionGoods.Ref.Posted
		|		AND InventorySurplusRecognitionGoods.Ref.Organization = &Organization
		|	
		|	UNION ALL
		|	
		|	SELECT DISTINCT
		|		GoodsMisgradingGoods.ItemsLocationAttributes,
		|		&Organization
		|	FROM
		|		Document.GoodsMisgrading.Goods AS GoodsMisgradingGoods
		|	WHERE
		|		GoodsMisgradingGoods.Ref.Date BETWEEN &StartDate AND &EndDate
		|		AND GoodsMisgradingGoods.Ref.Warehouse = &Warehouse
		|		AND GoodsMisgradingGoods.Ref.Posted
		|		AND GoodsMisgradingGoods.Ref.Organization = &Organization
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsMisgradingGoods.ItemsLocationAttributesReceipt,
		|		&Organization
		|	FROM
		|		Document.GoodsMisgrading.Goods AS GoodsMisgradingGoods
		|	WHERE
		|		GoodsMisgradingGoods.Ref.Date BETWEEN &StartDate AND &EndDate
		|		AND GoodsMisgradingGoods.Ref.Warehouse = &Warehouse
		|		AND GoodsMisgradingGoods.Ref.Posted
		|		AND GoodsMisgradingGoods.Ref.Organization = &Organization
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsDamageGoods.ItemsLocationAttributes,
		|		&Organization
		|	FROM
		|		Document.GoodsDamage.Goods AS GoodsDamageGoods
		|	WHERE
		|		GoodsDamageGoods.Ref.Date BETWEEN &StartDate AND &EndDate
		|		AND GoodsDamageGoods.Ref.Warehouse = &Warehouse
		|		AND GoodsDamageGoods.Ref.Posted
		|		AND GoodsDamageGoods.Ref.Organization = &Organization
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Dimension.DimensionKey,
		|		&Organization
		|	FROM
		|		Document.GoodsDamage.Goods AS DamageToGoodsRegisteredGoods
		|			INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
		|			ON DamageToGoodsRegisteredGoods.ProductsRecordingAsReceived = Dimension.Products
		|				AND (VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement)
		|				AND DamageToGoodsRegisteredGoods.CharacteristicRecordingAsReceived = Dimension.Characteristic
		|				AND DamageToGoodsRegisteredGoods.Purpose = Dimension.Purpose
		|				AND (DamageToGoodsRegisteredGoods.Series = Dimension.Series
		|					OR NOT DamageToGoodsRegisteredGoods.BatchesIndicationStatus = 14)
		|				AND DamageToGoodsRegisteredGoods.Ref.Warehouse = Dimension.StorageLocation
		|	WHERE
		|		DamageToGoodsRegisteredGoods.Ref.Date BETWEEN &StartDate AND &EndDate
		|		AND DamageToGoodsRegisteredGoods.Ref.Warehouse = &Warehouse
		|		AND DamageToGoodsRegisteredGoods.Ref.Posted
		|		AND DamageToGoodsRegisteredGoods.Ref.Organization = &Organization) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.CountBalance
		|INTO CompanyGoodsBalance
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|			&DateOfRemainingGoods,
		|			ItemsLocationAttributes IN
		|					(SELECT DISTINCT
		|						ProductsTable.ItemsLocationAttributes
		|					FROM
		|						ProductsTable)
		|				AND Organization = &Organization
		|				AND InventoryOwnerAttribute.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods))) AS CompanyGoodsBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	-CompanyGoods.Count AS DeviationInStorageUnits,
		|	0 AS Quantity_Actual
		|INTO InventoryItems
		|FROM
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|WHERE
		|	CompanyGoods.Recorder REFS Document.WriteOffOfGoodsShortages
		|	AND CAST(CompanyGoods.Recorder AS Document.WriteOffOfGoodsShortages).Date BETWEEN &StartDate AND &EndDate
		|	AND CAST(CompanyGoods.Recorder AS Document.WriteOffOfGoodsShortages).Warehouse = &Warehouse
		|	AND CompanyGoods.Organization = &Organization
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoods.ItemsLocationAttributes,
		|	CompanyGoods.Count,
		|	0
		|FROM
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|WHERE
		|	CompanyGoods.Recorder REFS Document.InventorySurplusRecognition
		|	AND CAST(CompanyGoods.Recorder AS Document.InventorySurplusRecognition).Date BETWEEN &StartDate AND &EndDate
		|	AND CAST(CompanyGoods.Recorder AS Document.InventorySurplusRecognition).Warehouse = &Warehouse
		|	AND CompanyGoods.Organization = &Organization
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoods.ItemsLocationAttributes,
		|	CASE
		|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CompanyGoods.Count
		|		ELSE -CompanyGoods.Count
		|	END,
		|	0
		|FROM
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|WHERE
		|	CompanyGoods.Recorder REFS Document.GoodsMisgrading
		|	AND CAST(CompanyGoods.Recorder AS Document.GoodsMisgrading).Date BETWEEN &StartDate AND &EndDate
		|	AND CAST(CompanyGoods.Recorder AS Document.GoodsMisgrading).Warehouse = &Warehouse
		|	AND CompanyGoods.Organization = &Organization
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoods.ItemsLocationAttributes,
		|	CASE
		|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CompanyGoods.Count
		|		ELSE -CompanyGoods.Count
		|	END,
		|	0
		|FROM
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|WHERE
		|	CompanyGoods.Recorder REFS Document.GoodsDamage
		|	AND CAST(CompanyGoods.Recorder AS Document.GoodsDamage).Date BETWEEN &StartDate AND &EndDate
		|	AND CAST(CompanyGoods.Recorder AS Document.GoodsDamage).Warehouse = &Warehouse
		|	AND CompanyGoods.Organization = &Organization
		|
		|UNION ALL
		|
		|SELECT
		|	ProductsTable.ItemsLocationAttributes,
		|	0,
		|	CompanyGoodsBalance.CountBalance
		|FROM
		|	ProductsTable AS ProductsTable
		|		INNER JOIN CompanyGoodsBalance AS CompanyGoodsBalance
		|		ON ProductsTable.ItemsLocationAttributes = CompanyGoodsBalance.ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InventoryItems.ItemsLocationAttributes.Products AS Products,
		|	InventoryItems.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	InventoryItems.ItemsLocationAttributes.Series AS Series,
		|	&FieldsForPricingSelection,
		|	SUM(InventoryItems.Quantity_Actual) AS Quantity_Actual,
		|	SUM(InventoryItems.Quantity_Actual - InventoryItems.DeviationInStorageUnits) AS QuantityByAccount
		|INTO InventoryTable_
		|FROM
		|	InventoryItems AS InventoryItems
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = InventoryItems.ItemsLocationAttributes.Products.ProductKind
		|
		|GROUP BY
		|	InventoryItems.ItemsLocationAttributes.Products,
		|	InventoryItems.ItemsLocationAttributes.Characteristic,
		|	&PricingFieldsGrouping,
		|	InventoryItems.ItemsLocationAttributes.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&Director AS Director,
		|	&JobTitleExecutive AS JobTitleExecutive,
		|	&ChiefAccountant AS ChiefAccountant,
		|	&Organization AS Organization,
		|	CAST(&Organization AS Catalog.Companies).NCBOCode AS OrganizationForOkpo,
		|	CAST(&Organization AS Catalog.Companies).Prefix AS Prefix,
		|	PhysicalCountReport.Warehouse.CurrentEmployeeInChargeTypes AS Warehouseman,
		|	PhysicalCountReport.Warehouse.CurrentPositionOfTheResponsiblePerson AS StorekeeperPosition,
		|	PhysicalCountReport.Warehouse.Description AS DepartmentPresentation,
		|	&StartDate AS StartDate,
		|	&EndDate AS EndDate,
		|	PhysicalCountReport.Warehouse AS Warehouse,
		|	PhysicalCountReport.Date AS ReferenceDocumentDateForPrintForms,
		|	PhysicalCountReport.Number AS BaseDocumentNumber,
		|	PhysicalCountReport.Number AS DocumentNumber,
		|	PhysicalCountReport.Date AS DocumentDate,
		|	PhysicalCountReport.Ref AS Ref,
		|	&EndDate AS DateOfWithdrawalOfBalances
		|FROM
		|	Document.PhysicalCountReport AS PhysicalCountReport
		|WHERE
		|	PhysicalCountReport.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InventoryTable_.Products AS Products,
		|	InventoryTable_.Characteristic AS Characteristic,
		|	InventoryTable_.Series AS Series,
		|	InventoryTable_.Products.DescriptionFull AS ProductItemName,
		|	InventoryTable_.Characteristic.DescriptionFull AS CharacteristicName,
		|	InventoryTable_.Series.Description AS SeriesName_,
		|	InventoryTable_.QuantityByAccount,
		|	InventoryTable_.Quantity_Actual,
		|	CASE
		|		WHEN NOT &QueryTextPackagingFactor IS NULL 
		|				AND &QueryTextPackagingFactor <> 0
		|			THEN ISNULL(ItemsPrices.Price, 0) / &QueryTextPackagingFactor
		|		ELSE ISNULL(ItemsPrices.Price, 0)
		|	END AS Price,
		|	InventoryTable_.QuantityByAccount * CASE
		|		WHEN NOT &QueryTextPackagingFactor IS NULL 
		|				AND &QueryTextPackagingFactor <> 0
		|			THEN ISNULL(ItemsPrices.Price, 0) / &QueryTextPackagingFactor
		|		ELSE ISNULL(ItemsPrices.Price, 0)
		|	END AS AccountInAccounting,
		|	InventoryTable_.Quantity_Actual * CASE
		|		WHEN NOT &QueryTextPackagingFactor IS NULL 
		|				AND &QueryTextPackagingFactor <> 0
		|			THEN ISNULL(ItemsPrices.Price, 0) / &QueryTextPackagingFactor
		|		ELSE ISNULL(ItemsPrices.Price, 0)
		|	END AS Amount_Actual,
		|	InventoryTable_.Products.Code AS ProductCode_,
		|	InventoryTable_.Products.UnitOfMeasure.Code AS UnitOfMeasureCode,
		|	InventoryTable_.Products.UnitOfMeasure.Description AS UnitOfMeasurementName,
		|	FALSE AS ThisIsReusablePackage
		|FROM
		|	InventoryTable_ AS InventoryTable_
		|		LEFT JOIN &ItemPricesCrossSectionOfTheLatest AS ItemsPrices
		|		ON &ConditionForCombiningPriceOfItemWithSliceOfLatter
		|
		|ORDER BY
		|	ProductItemName,
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	CurrencyRatesCut.CourseNumerator / CurrencyRatesCut.CourseDenominator AS ConversionFactor_
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(&EndDate, Currency = &PriceKind AND BaseCurrency = &BaseCurrency) AS CurrencyRatesCut";

		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(EndDate);
		
		PricingSettings = PriceManagementSystemClientServer.SettingsForTemporaryTableWithAdditionForPricing();
		PricingSettings.SourceOfGoods = "InventoryItems.ItemsLocationAttributes";
		PricingSettings.PackagingField = "";
		
		ReplacementText = PriceManagementSystemClientServer.TextOfFieldsForPricing(PricingSettings,, UsePriceManagementSystem25);
		If ValueIsFilled(ReplacementText) Then
			QueryText = StrReplace(QueryText, "&FieldsForPricingSelection", ReplacementText);
		Else
			QueryText = StrReplace(QueryText, "&FieldsForPricingSelection,", "");
		EndIf;
		
		ReplacementText = PriceManagementSystemClientServer.TextOfFieldsForPricing(PricingSettings, True, UsePriceManagementSystem25);
		If ValueIsFilled(ReplacementText) Then
			QueryText = StrReplace(QueryText, "&PricingFieldsGrouping", ReplacementText);
		Else
			QueryText = StrReplace(QueryText, "&PricingFieldsGrouping,", "");
		EndIf;
		
		QueryText = StrReplace(QueryText,
			"&ItemPricesCrossSectionOfTheLatest",
			PriceManagementSystemClientServer.QueryTextInformationRegisterItemsPrices(
				"InventoryTable_",
				"&EndDate",
				New Structure("InTable", "&PriceKind"),
				UsePriceManagementSystem25)
		);
		
		QueryText = StrReplace(QueryText,
			"&ConditionForCombiningPriceOfItemWithSliceOfLatter",
			PriceManagementSystemClientServer.RequestTextInformationRegisterItemPricesConnectionCondition(
				"InventoryTable_",
				"ItemsPrices",,
				UsePriceManagementSystem25)
		);
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ItemsPrices.Package",
				"ItemsPrices.Products")
		);
		
		QueryText = StrReplace(QueryText, "Products.Code", "Products." + ColumnOfCodes);
		
		Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
		Query.Text = QueryText;
		
		Results = Query.ExecuteBatch();
		HeaderResults = Results[4];
		ResultForTabularPart = Results[5];
		ResultCurrencyExchangeRate = Results[6];
		
	EndIf;
	
	ReturnStructure.HeaderResults			= HeaderResults;
	ReturnStructure.ResultForTabularPart	= ResultForTabularPart;
	ReturnStructure.ResultCurrencyExchangeRate		= ResultCurrencyExchangeRate;
	
	Return ReturnStructure;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
