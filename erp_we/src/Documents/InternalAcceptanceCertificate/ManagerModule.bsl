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
	
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	
	InternalAcceptanceCertificateLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.InternalAcceptanceCertificate") Then
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
		
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers, DocumentRef);
		
		InternalAcceptanceCertificateLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region StandardCommandSubsystems

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Populates the list of creation commands based on.
// 
// Parameters:
// 	GenerationCommands - ValueTable - list of commands
// 	Parameters - Structure - Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	InternalAcceptanceCertificateLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create an object based on.
// 
// Parameters:
// 	GenerationCommands - ValueTable - list of commands
// Returns:
// 	Undefined, ValueTableRow - added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.InternalAcceptanceCertificate) Then
		
		CreateBasedOnCommand						= GenerationCommands.Add();
		CreateBasedOnCommand.Handler			= "ProductionClient.CreateActOfCompletedInternalWorksOnBasisOf";
		CreateBasedOnCommand.Manager				= "Document.InternalAcceptanceCertificate";
		CreateBasedOnCommand.Id			= "CreationOfActOfCompletedInternalWorks";
		CreateBasedOnCommand.Presentation			= TMCommonUse.ObjectPresentation(Metadata.Documents.InternalAcceptanceCertificate);
		CreateBasedOnCommand.WriteMode			= "Post";
		CreateBasedOnCommand.FunctionalOptions	= "UseProductionManagement2_2";
		CreateBasedOnCommand.MultipleChoice	= True;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Fills in the list of report commands.
// 
// Parameters:
// 	ReportsCommands - ValueTable - list of commands
// 	Parameters - Structure - Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	InternalAcceptanceCertificateLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// StandardSubsystems.Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	InternalAcceptanceCertificateLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region ChangeOfStatus

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
// 		DocumentsArray - Array of DocumentRef.InternalAcceptanceCertificate - An array of references to documents that should be reviewed
// 		NewStatus - String - Name of the new status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsTable.Ref                AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status)                  AS PresentationOfNewStatus,
	|	DocumentsTable.Status = &Status      AS StatusMatches,
	|	DocumentsTable.Posted              AS Posted,
	|	DocumentsTable.DeletionMark       AS DeletionMark,
	|	TRUE                                  AS Recording
	|FROM
	|	Document.InternalAcceptanceCertificate AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	Query.SetParameter("Status",           Enums.StatusesOfInternalAcceptanceCertificate[NewStatus]);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction// Formationproverciprismenestatus();

// Returns the result of checking when the document status changes
//
// Parameters:
// 		ValidationSample - QueryResultSelection - Current selection string
// 		NewStatus - EnumRef.InternalConsumptionStatuses - New status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // No checks are required
	
EndFunction

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
	
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	If GetFunctionalOption("UseStatusesOfInternalWorksAcceptance") Then
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfInternalAcceptanceCertificate.Issued);
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfInternalAcceptanceCertificate.Accepted);
	EndIf;
	
	Return Table;
	
EndFunction

#EndRegion

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.Goods.Purpose");
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway2_5));
	
	// The needs for issued works in the recipient division.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Goods.Department";
	
	DescriptionOfColumns.FormItemName = "Purpose";
	
	Return FormTemplate;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about works.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about services and works.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.InternalAcceptanceCertificate, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Date								= Object.Date;
	FillParameters.LineOfBusiness				= Object.LineOfBusiness;
	FillParameters.MovementOfGoodsAndWorksInProduction	= True;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices Then
		FillParameters.Organization = Object.CompanyRecipient;
	Else
		FillParameters.Organization = Object.Organization;
	EndIf;
	
	Return FillParameters;
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Status)";

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

#Region Initialize

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.InternalAcceptanceCertificate";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	TemporaryTableQueryTexts = New Map;
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		TemporaryTableQueryTexts.Insert("TTUnits", QueryTextTTUnits(Query, QueryTexts));
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
									QueryText,
									FullDocumentName,
									SynonymForDocumentTable,
									RequestHasSource,
									RedefiningParameterCalculation,
									TemporaryTableQueryTexts);

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	Attributes.Ref						AS Ref,
	|	Attributes.Posted						AS Posted,
	|	Attributes.DeletionMark				AS DeletionMark,
	|	Attributes.Number							AS Number,
	|	Attributes.Date							AS Date,
	|	Attributes.Date							AS Period,
	|	Attributes.Organization					AS Organization,
	|	Attributes.CompanyRecipient			AS CompanyRecipient,
	|	Attributes.Department					AS Department,
	|	Attributes.BusinessOperation			AS BusinessOperation,
	|	Attributes.Status						AS Status,
	|	Attributes.TransferForActivity	AS TransferForActivity,
	|	Attributes.LineOfBusiness		AS LineOfBusiness,
	|	Attributes.EmployeeResponsible					AS EmployeeResponsible,
	|	Attributes.Patch					AS Patch,
	|	Attributes.ReversedDocument			AS ReversedDocument,
	|	Attributes.CorrectedDocument			AS CorrectedDocument,
	|	Attributes.Comment					AS Comment,
	|	BusinessTransactionsSettings.Ref 	AS BusinessTransactionSetting,
	|	Attributes.CorrectedDocument.Date		AS AdjustmentPeriod_
	|FROM
	|	Document.InternalAcceptanceCertificate AS Attributes
	|	
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON Attributes.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	Attributes.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ParametersOfTheEvent = ValuesOfHoldingParameters(Attributes);
	For Each CurParameter In ParametersOfTheEvent Do
		Query.SetParameter(CurParameter.Key, CurParameter.Value);
	EndDo;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.InternalAcceptanceCertificate"));

	ValuesOfHoldingParameters.Insert("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	ValuesOfHoldingParameters.Insert("AnalyticalAccountingByProductsGroups",
								GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	
								
	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure InitializeProductAnalysisKeys(Query)

	If Query = Undefined
		Or Query.Parameters.Property("ProductAnalysisKeysInitialized") Then
		Return;
	EndIf;
	
	AnalyticsRequest = New Query(
	"SELECT DISTINCT
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ProductCostElement AS ProductCostElement
	|FROM
	|	(
	// analytics of the sender of works without assignment
	|	SELECT
	|		Works.Products									AS Products,
	|		Works.Characteristic								AS Characteristic,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		&Department										AS Warehouse,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.InternalAcceptanceCertificate.Goods AS Works
	|	WHERE
	|		Works.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// analytics of the recipient of works
	|	SELECT
	|		Works.Products									AS Products,
	|		Works.Characteristic								AS Characteristic,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		Works.Department								AS Warehouse,
	|		Works.Purpose									AS Purpose,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.InternalAcceptanceCertificate.Goods AS Works
	|	WHERE
	|		Works.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// analytics of the recipient of works without assignment
	|	SELECT
	|		Works.Products									AS Products,
	|		Works.Characteristic								AS Characteristic,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		Works.Department								AS Warehouse,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.InternalAcceptanceCertificate.Goods AS Works
	|	WHERE
	|		Works.Ref = &Ref
	|	) AS GoodsTable
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON GoodsTable.Products = Dimension.Products
	|			AND GoodsTable.Characteristic = Dimension.Characteristic
	|			AND GoodsTable.Series = Dimension.Series
	|			AND GoodsTable.Warehouse = Dimension.StorageLocation
	|			AND GoodsTable.Purpose = Dimension.Purpose
	|			AND GoodsTable.ProductCostElement = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL
	|
	|GROUP BY
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	GoodsTable.ProductCostElement");
	
	AnalyticsRequest.SetParameter("Ref", Query.Parameters.Ref);
	AnalyticsRequest.SetParameter("Department", Query.Parameters.Department);
	
	Selection = AnalyticsRequest.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;

	Query.SetParameter("ProductAnalysisKeysInitialized", True);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - query text.
//
Function TextOfReflectionInLocalAccounting() Export

	Return InternalAcceptanceCertificateLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
// 
// Returns:
// 	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return InternalAcceptanceCertificateLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

#Region QueryTextsTemporaryTables

Function QueryTextTTUnits(Query, QueryTexts)
	
	RegisterName = "TTUnits";
	
	QueryText = 
	"SELECT
	|	Departments.Ref                        AS Ref,
	|	Departments.Organization                   AS Organization,
	|	Departments.StorageLocation                 AS StorageLocation,
	|	MIN(Departments.AdditionalRecord) AS AdditionalRecord
	|INTO TTUnits
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref,
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS StorageLocation,
	|		FALSE AS AdditionalRecord
	|	FROM
	|		Document.InternalAcceptanceCertificate AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&Ref,
	|		CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|				THEN &CompanyRecipient
	|			ELSE &Organization
	|		END,
	|		DocumentData.Department,
	|		TRUE
	|	FROM
	|		Document.InternalAcceptanceCertificate.Goods AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND (NOT DocumentData.Department = &Department
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
	|	) AS Departments
	|
	|GROUP BY
	|	Departments.Ref,
	|	Departments.StorageLocation,
	|	Departments.AdditionalRecord,
	|	Departments.Organization
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTProducts_1(Query, QueryTexts)
	
	RegisterName = "TTProducts_1";
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = 
	"SELECT
	|	Works.ItemsLocationAttributes				AS DimensionOfProductItem,
	|	ProductKeysWithoutAssignment.DimensionKey	AS AnalysisOfProductsWithoutAssignment,
	|	KeysByRecipient.DimensionKey					AS ProductAnalysisByRecipient,
	|	KeysByRecipientWithoutAssignment.DimensionKey	AS ProductAnalysisByRecipientWithoutAssignment,
	|	Works.Department							AS ReceivingBusinessUnit,
	|	Works.Products								AS Products,
	|	Works.Characteristic							AS Characteristic,
	|	Works.Purpose								AS Purpose,
	|	CASE
	|		WHEN ISNULL(Works.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Works.Purpose.VATActivityType
	|		ELSE &TransferForActivity
	|	END 											AS VATActivityType,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			AND NOT CatProducts.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN CatProducts.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END											AS ProductGroupSender,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			AND NOT Works.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN Works.ProductsGroup
	|		ELSE UNDEFINED
	|	END											AS ProductsGroup,
	|	SUM(Works.Count)						AS Count,
	|	Works.RowID						AS RowID
	|INTO TTProducts_1
	|FROM
	|	Document.InternalAcceptanceCertificate.Goods AS Works
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductKeysWithoutAssignment
	|			ON ProductKeysWithoutAssignment.Products		= Works.Products
	|			AND ProductKeysWithoutAssignment.Characteristic		= Works.Characteristic
	|			AND ProductKeysWithoutAssignment.Series				= VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND ProductKeysWithoutAssignment.StorageLocation		= &Department
	|			AND ProductKeysWithoutAssignment.Purpose			= VALUE(Catalog.Assignments.EmptyRef)
	|			AND ProductKeysWithoutAssignment.ProductCostElement	= VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS KeysByRecipient
	|			ON KeysByRecipient.Products		= Works.Products
	|			AND KeysByRecipient.Characteristic		= Works.Characteristic
	|			AND KeysByRecipient.Series				= VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND KeysByRecipient.StorageLocation		= Works.Department
	|			AND KeysByRecipient.Purpose			= Works.Purpose
	|			AND KeysByRecipient.ProductCostElement	= VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS KeysByRecipientWithoutAssignment
	|			ON KeysByRecipientWithoutAssignment.Products		= Works.Products
	|			AND KeysByRecipientWithoutAssignment.Characteristic		= Works.Characteristic
	|			AND KeysByRecipientWithoutAssignment.Series				= VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND KeysByRecipientWithoutAssignment.StorageLocation		= Works.Department
	|			AND KeysByRecipientWithoutAssignment.Purpose			= VALUE(Catalog.Assignments.EmptyRef)
	|			AND KeysByRecipientWithoutAssignment.ProductCostElement	= VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON CatProducts.Ref = Works.Products
	|WHERE
	|	Works.Ref = &Ref
	|
	|GROUP BY
	|	KeysByRecipientWithoutAssignment.DimensionKey,
	|	Works.Purpose,
	|	CASE
	|		WHEN ISNULL(Works.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Works.Purpose.VATActivityType
	|		ELSE &TransferForActivity
	|	END,
	|	Works.Characteristic,
	|	ProductKeysWithoutAssignment.DimensionKey,
	|	Works.Products,
	|	Works.ItemsLocationAttributes,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			AND NOT CatProducts.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN CatProducts.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			AND NOT Works.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN Works.ProductsGroup
	|		ELSE UNDEFINED
	|	END,
	|	Works.Department,
	|	KeysByRecipient.DimensionKey,
	|	Works.RowID";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = 
	"SELECT
	|	Dimension.Ref								AS DimensionOfProductItem,
	|	ProductKeysWithoutAssignment.DimensionKey	AS AnalysisOfProductsWithoutAssignment,
	|	KeysByRecipient.DimensionKey					AS ProductAnalysisByRecipient,
	|	KeysByRecipientWithoutAssignment.DimensionKey	AS ProductAnalysisByRecipientWithoutAssignment,
	|	InventoryKinds.ReceivingBusinessUnit				AS ReceivingBusinessUnit,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Purpose							AS Purpose,
	|	Dimension.Purpose.LineOfBusiness	AS LineOfBusiness,
	|	InventoryKinds.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	InventoryKinds.RecipientInventoryOwnerAttribute				AS RecipientInventoryOwnerAttribute,
	|	CASE
	|		WHEN ISNULL(Dimension.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Dimension.Purpose.VATActivityType
	|		ELSE &TransferForActivity
	|	END 											AS VATActivityType,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			AND NOT InventoryKinds.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN InventoryKinds.ProductsGroup
	|		ELSE UNDEFINED
	|	END											AS ProductsGroup,
	|	SUM(InventoryKinds.Count)					AS Count,
	|	InventoryKinds.RowID					AS RowID,
	|	CASE
	|		WHEN Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND Dimension.Products.TracedGoods
	|			THEN TRUE
	|		ELSE FALSE
	|	END 											AS ThisIsTraceableWork
	|INTO TTTypesOfStocks
	|FROM
	|	Document.InternalAcceptanceCertificate.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductKeysWithoutAssignment
	|			ON ProductKeysWithoutAssignment.Products		= InventoryKinds.ItemsLocationAttributes.Products
	|			AND ProductKeysWithoutAssignment.Characteristic		= InventoryKinds.ItemsLocationAttributes.Characteristic
	|			AND ProductKeysWithoutAssignment.Series				= VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND ProductKeysWithoutAssignment.StorageLocation		= &Department
	|			AND ProductKeysWithoutAssignment.Purpose			= VALUE(Catalog.Assignments.EmptyRef)
	|			AND ProductKeysWithoutAssignment.ProductCostElement	= VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS KeysByRecipient
	|			ON KeysByRecipient.Products		= InventoryKinds.ItemsLocationAttributes.Products
	|			AND KeysByRecipient.Characteristic		= InventoryKinds.ItemsLocationAttributes.Characteristic
	|			AND KeysByRecipient.Series				= VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND KeysByRecipient.StorageLocation		= InventoryKinds.ReceivingBusinessUnit
	|			AND KeysByRecipient.Purpose			= InventoryKinds.ItemsLocationAttributes.Purpose
	|			AND KeysByRecipient.ProductCostElement	= VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS KeysByRecipientWithoutAssignment
	|			ON KeysByRecipientWithoutAssignment.Products		= InventoryKinds.ItemsLocationAttributes.Products
	|			AND KeysByRecipientWithoutAssignment.Characteristic		= InventoryKinds.ItemsLocationAttributes.Characteristic
	|			AND KeysByRecipientWithoutAssignment.Series				= VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND KeysByRecipientWithoutAssignment.StorageLocation		= InventoryKinds.ReceivingBusinessUnit
	|			AND KeysByRecipientWithoutAssignment.Purpose			= VALUE(Catalog.Assignments.EmptyRef)
	|			AND KeysByRecipientWithoutAssignment.ProductCostElement	= VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON CatProducts.Ref = InventoryKinds.ItemsLocationAttributes.Products
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|			ON InventoryKinds.ItemsLocationAttributes = Dimension.Ref
	|			
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|
	|GROUP BY
	|	KeysByRecipientWithoutAssignment.DimensionKey,
	|	Dimension.Purpose,
	|	Dimension.Purpose.LineOfBusiness,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.RecipientInventoryOwnerAttribute,
	|	CASE
	|		WHEN ISNULL(Dimension.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Dimension.Purpose.VATActivityType
	|		ELSE &TransferForActivity
	|	END,
	|	Dimension.Characteristic,
	|	ProductKeysWithoutAssignment.DimensionKey,
	|	Dimension.Products,
	|	Dimension.Ref,
	|	InventoryKinds.ReceivingBusinessUnit,
	|	KeysByRecipient.DimensionKey,
	|	InventoryKinds.RowID,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			AND NOT InventoryKinds.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN InventoryKinds.ProductsGroup
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND Dimension.Products.TracedGoods
	|			THEN TRUE
	|		ELSE FALSE
	|	END";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText =
	// Expense of work from the sender
	"SELECT
	|	&Date									AS Period,
	|	VALUE(AccumulationRecordType.Expense)	AS RecordType,
	|	&Organization							AS Organization,
	|	&Department							AS Department,
	|	TTProducts_1.Products					AS Products,
	|	TTProducts_1.Characteristic					AS Characteristic,
	|	TTProducts_1.Purpose						AS Purpose,
	|	TTProducts_1.Count						AS Count
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	NOT TTProducts_1.Products.TracedGoods
	|
	|UNION ALL
	// arrival of works to the recipient
	|SELECT
	|	&Date									AS Period,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|			THEN &CompanyRecipient
	|		ELSE &Organization
	|	END									AS Organization,
	|	TTProducts_1.ReceivingBusinessUnit		AS Department,
	|	TTProducts_1.Products					AS Products,
	|	TTProducts_1.Characteristic					AS Characteristic,
	|	TTProducts_1.Purpose						AS Purpose,
	|	TTProducts_1.Count						AS Count
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	&Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
	|	AND NOT TTProducts_1.Products.TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)

	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Date										AS Period,
	|	&BusinessOperation						AS BusinessOperation,
	|	&Organization								AS Organization,
	|	&Department								AS Department,
	|	TTProducts_1.Purpose.LineOfBusiness	AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TTProducts_1.DimensionOfProductItem
	|		ELSE TTProducts_1.AnalysisOfProductsWithoutAssignment
	|	END										AS ItemsLocationAttributes,
	|	&Department								AS Warehouse,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS InventoryType,
	|	UNDEFINED								AS InventoryOwnerAttribute,
	|	TTProducts_1.Purpose.LineOfBusiness	AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TTProducts_1.ProductAnalysisByRecipient
	|		ELSE TTProducts_1.ProductAnalysisByRecipientWithoutAssignment
	|	END										AS CorItemsLocationAttributes,
	|	TTProducts_1.ReceivingBusinessUnit			AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS CorInventoryType,
	|	UNDEFINED								AS CorInventoryOwnerAttribute,
	|	TTProducts_1.Count							AS Count,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|			THEN 0
	|		ELSE TTProducts_1.Count
	|	END										AS CorQuantity,
	|	0											AS Cost,
	|	0											AS CostExcludingVAT,
	|	0											AS LocalCost,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TTProducts_1.Products
	|	END										AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TTProducts_1.Products
	|	END										AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED								AS DocumentRegisterRecords,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|			THEN &CompanyRecipient
	|		ELSE &Organization
	|	END										AS CorCompany
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	&Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
	|
	|UNION ALL
	|
	|SELECT
	|	&Date										AS Period,
	|	VALUE(Enum.BusinessTransactions.InternalWorkReceipt) AS BusinessOperation,
	|	&CompanyRecipient						AS Organization,
	|	TTProducts_1.ReceivingBusinessUnit			AS Department,
	|	TTProducts_1.Purpose.LineOfBusiness	AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TTProducts_1.DimensionOfProductItem
	|		ELSE TTProducts_1.AnalysisOfProductsWithoutAssignment
	|	END										AS ItemsLocationAttributes,
	|	&Department								AS Warehouse,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS InventoryType,
	|	UNDEFINED								AS InventoryOwnerAttribute,
	|	TTProducts_1.Purpose.LineOfBusiness	AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TTProducts_1.ProductAnalysisByRecipient
	|		ELSE TTProducts_1.ProductAnalysisByRecipientWithoutAssignment
	|	END										AS CorItemsLocationAttributes,
	|	TTProducts_1.ReceivingBusinessUnit			AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS CorInventoryType,
	|	UNDEFINED								AS CorInventoryOwnerAttribute,
	|	0											AS Count,
	|	TTProducts_1.Count							AS CorQuantity,
	|	0											AS Cost,
	|	0											AS CostExcludingVAT,
	|	0											AS LocalCost,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TTProducts_1.Products
	|	END										AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TTProducts_1.Products
	|	END										AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED								AS DocumentRegisterRecords,
	|	&Organization								AS CorCompany
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	&Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|
	|UNION ALL
	|
	// Traceable works are taken from TS types of stocks.
	|SELECT
	|	&Date										AS Period,
	|	&BusinessOperation						AS BusinessOperation,
	|	&Organization								AS Organization,
	|	&Department								AS Department,
	|	TableTypesOfStocks_.LineOfBusiness	AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.DimensionOfProductItem
	|		ELSE TableTypesOfStocks_.AnalysisOfProductsWithoutAssignment
	|	END										AS ItemsLocationAttributes,
	|	&Department								AS Warehouse,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS InventoryType,
	|	UNDEFINED								AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LineOfBusiness	AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.ProductAnalysisByRecipient
	|		ELSE TableTypesOfStocks_.ProductAnalysisByRecipientWithoutAssignment
	|	END										AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.ReceivingBusinessUnit	AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS CorInventoryType,
	|	UNDEFINED								AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count				AS Count,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|			THEN 0
	|		ELSE TableTypesOfStocks_.Count
	|	END										AS CorQuantity,
	|	0											AS Cost,
	|	0											AS CostExcludingVAT,
	|	0											AS LocalCost,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TableTypesOfStocks_.Products
	|	END										AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TableTypesOfStocks_.Products
	|	END										AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED								AS DocumentRegisterRecords,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|			THEN &CompanyRecipient
	|		ELSE &Organization
	|	END										AS CorCompany
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
	|	AND TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	&Date										AS Period,
	|	VALUE(Enum.BusinessTransactions.InternalWorkReceipt) AS BusinessOperation,
	|	&CompanyRecipient						AS Organization,
	|	TableTypesOfStocks_.ReceivingBusinessUnit	AS Department,
	|	TableTypesOfStocks_.LineOfBusiness	AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.DimensionOfProductItem
	|		ELSE TableTypesOfStocks_.AnalysisOfProductsWithoutAssignment
	|	END										AS ItemsLocationAttributes,
	|	&Department								AS Warehouse,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS InventoryType,
	|	UNDEFINED								AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LineOfBusiness	AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.ProductAnalysisByRecipient
	|		ELSE TableTypesOfStocks_.ProductAnalysisByRecipientWithoutAssignment
	|	END										AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.ReceivingBusinessUnit	AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS CorInventoryType,
	|	UNDEFINED								AS CorInventoryOwnerAttribute,
	|	0											AS Count,
	|	TableTypesOfStocks_.Count				AS CorQuantity,
	|	0											AS Cost,
	|	0											AS CostExcludingVAT,
	|	0											AS LocalCost,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TableTypesOfStocks_.Products
	|	END										AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TableTypesOfStocks_.Products
	|	END										AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED								AS DocumentRegisterRecords,
	|	&Organization								AS CorCompany
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|	AND TableTypesOfStocks_.ThisIsTraceableWork
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTUnits", QueryTexts) Then
		QueryTextTTUnits(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                            AS Ref,
	|	&Date                              AS IBDocumentDate,
	|	&Number                             AS IBDocumentNumber,
	|	&MetadataIdentifier           AS RefType,
	|	Departments.Organization          AS Organization,
	|	&BusinessOperation             AS BusinessOperation,
	|	&LineOfBusiness           AS LineOfBusiness,
	|	Departments.StorageLocation        AS Department,
	|	&EmployeeResponsible                     AS EmployeeResponsible,
	|	&Comment                       AS Comment,
	|	&Posted                          AS Posted,
	|	&DeletionMark                   AS DeletionMark,
	|	Departments.AdditionalRecord AS AdditionalRecord,
	|	&Date                              AS SourceDocumentDate,
	|	&NumberForPrinting                     AS SourceDocumentNumber,
	|	Departments.StorageLocation        AS StorageLocation,
	|	&Patch                       AS ReverseTransactionCorrection,
	|	&ReversedDocument              AS ReversedDocument,
	|	&CorrectedDocument              AS CorrectedDocument,
	|	&Date                              AS RecordingInAccountingDate,
	|	&Status                            AS Status
	|FROM
	|	TTUnits AS Departments
	|	
	|	LEFT JOIN Document.InternalAcceptanceCertificate AS DocumentData
	|	ON Departments.Ref = DocumentData.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers, DocumentRef)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts, DocumentRef);
	EndIf;
	
	QueryText =
	"SELECT
	|	TTProductsOfOrganizations.RecordType AS RecordType,
	|	TTProductsOfOrganizations.Period AS Period,
	|	TTProductsOfOrganizations.ShipmentCompany AS ShipmentCompany,
	|	TTProductsOfOrganizations.Organization AS Organization,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.Products AS Products,
	|	TTProductsOfOrganizations.Characteristic AS Characteristic,
	|	TTProductsOfOrganizations.CCDNumber AS CCDNumber,
	|	TTProductsOfOrganizations.Count AS Count,
	|	TTProductsOfOrganizations.QuantityByGBRN AS QuantityByGBRN,
	|	TTProductsOfOrganizations.BusinessOperation AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation AS VATTaxation,
	|	TTProductsOfOrganizations.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductsOfOrganizations(Query, QueryTexts, DocumentObject)
	
	TableName = "TTProductsOfOrganizations";
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS ShipmentCompany,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS VATTaxation,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute
	|INTO TTProductsOfOrganizations
	|FROM
	|	Document.InternalAcceptanceCertificate.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS ShipmentCompany,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits)
	|			THEN
	|				&Organization
	|			ELSE
	|				&CompanyRecipient
	|	END AS Organization,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits)
	|			THEN
	|				TableTypesOfStocks_.InventoryOwnerAttribute
	|			ELSE
	|				TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	ISNULL(AnalyticsOfRecipientSDivision.DimensionKey, UNDEFINED) AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS VATTaxation,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute
	|FROM
	|	Document.InternalAcceptanceCertificate.InventoryKinds AS TableTypesOfStocks_
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfRecipientSDivision
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsOfRecipientSDivision.Products
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsOfRecipientSDivision.Characteristic
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = AnalyticsOfRecipientSDivision.Series
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Purpose = AnalyticsOfRecipientSDivision.Purpose
	|			AND TableTypesOfStocks_.ReceivingBusinessUnit = AnalyticsOfRecipientSDivision.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsOfRecipientSDivision.ProductCostElement
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.Ref.Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Department AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.InternalAcceptanceCertificate.Goods AS TabPart
		|";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Department AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.InternalAcceptanceCertificate.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
		|";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTProducts_1");
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTProducts_1(Query, QueryTexts);
		EndIf;
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Moving_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 		AS Organization,
	|	TableTypesOfStocks_.DimensionOfProductItem         		AS ItemsLocationAttributes,
	|	UNDEFINED							 		 		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			 		AS VATActivityType,
	|	DocumentTable.TransferForActivity	 			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|			THEN DocumentTable.CompanyRecipient
	|			ELSE UNDEFINED
	|	END													AS CorCompany,
	|	UNDEFINED 									   		AS CorLot,
	|	TableTypesOfStocks_.ProductAnalysisByRecipient	AS CorItemsLocationAttributes,
	|	UNDEFINED											AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED									AS SalesOpportunity,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|		THEN TableTypesOfStocks_.ReceivingBusinessUnit
	|		ELSE UNDEFINED
	|	END											AS Department,
	|	DocumentTable.EmployeeResponsible					AS Manager,
	|	TableTypesOfStocks_.ProductsGroup			 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.InternalAcceptanceCertificate AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
	|	AND NOT TableTypesOfStocks_.Products.TracedGoods
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion
	
	#Region Moving_TraceableWorks
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 		AS Organization,
	|	TableTypesOfStocks_.DimensionOfProductItem         		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			 		AS VATActivityType,
	|	DocumentTable.TransferForActivity	 			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|			THEN DocumentTable.CompanyRecipient
	|			ELSE UNDEFINED
	|	END													AS CorCompany,
	|	UNDEFINED 									   		AS CorLot,
	|	TableTypesOfStocks_.ProductAnalysisByRecipient	AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|			THEN
	|				TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|			ELSE
	|				TableTypesOfStocks_.InventoryOwnerAttribute
	|	END													AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED									AS SalesOpportunity,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|		THEN TableTypesOfStocks_.ReceivingBusinessUnit
	|		ELSE UNDEFINED
	|	END											AS Department,
	|	DocumentTable.EmployeeResponsible					AS Manager,
	|	TableTypesOfStocks_.ProductsGroup			 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.InternalAcceptanceCertificate AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Accepted)
	|	AND TableTypesOfStocks_.Products.TracedGoods
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Other

// Forming the order of document processing when changing the direction of activity
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// Returns:
// 	Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

Function TransactionList() Export

	TransactionList = New ValueList;
	
	PerformanceOfWorks					= PredefinedValue("Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits");
	ExecutionOfWorkBetweenBranches	= PredefinedValue("Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices");
	
	TransactionList.Add(PerformanceOfWorks,				NStr("vi = 'Nhận- điều chuyển giữa các bộ phận';
																|ru = 'Прием-передача между подразделениями';
																|en = 'Work acceptance between business units'; fa = 'Work acceptance between business units';
																|it = 'Ricezione-trasferimento tra reparti';
																|pl = 'Przyjęcie-przekazanie pomiędzy działami';
																|tr = 'Departmanlar arası teslim alma-transfer'"));
	If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		TransactionList.Add(ExecutionOfWorkBetweenBranches, NStr("vi = 'Nhận- điều chuyển giữa các chi nhánh';
																|ru = 'Прием-передача между филиалами';
																|en = 'Work acceptance between branches'; fa = 'Work acceptance between branches';
																|it = 'Ricezione-trasferimento tra le filiali';
																|pl = 'Przyjęcie-przekazanie pomiędzy filiami';
																|tr = 'Şubeler arası teslim alma-transfer'"));
	EndIf;
	
	Return TransactionList;

EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.InternalAcceptanceCertificate.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.23.18";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("7344728c-a805-4938-a7d4-52a2ec44bcee");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.InternalAcceptanceCertificate.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Biên bản nghiệm thu công việc nội bộ"":';
								|ru = 'Обновление документов ""Акт выполненных внутренних работ"":';
								|en = 'Update the ""Internal work acceptance"" documents:'; fa = 'Update the ""Internal work acceptance"" documents:';
								|it = 'Update the ""Internal work acceptance"" documents:';
								|pl = 'Update the ""Internal work acceptance"" documents:';
								|tr = '""Tamamlanan dahili iş tutanağı"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Trạng thái"" bằng giá trị ""Đã tiếp nhận"".';
								|ru = '- заполняет реквизит ""Статус"" значением ""Принят"".';
								|en = '- Fills the ""Status"" attribute with the ""Accepted"" value.'; fa = '- Fills the ""Status"" attribute with the ""Accepted"" value.';
								|it = '- Fills the ""Status"" attribute with the ""Accepted"" value.';
								|pl = '- Fills the ""Status"" attribute with the ""Accepted"" value.';
								|tr = '- ""Durum"" özniteliğini ""Kabul edildi"" değeriyle doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.InternalAcceptanceCertificate.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.InternalAcceptanceCertificate.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.InternalAcceptanceCertificate";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM 
	|	Document.InternalAcceptanceCertificate AS DocumentAttributes
	|WHERE
	|	DocumentAttributes.Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.EmptyRef)
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.InternalAcceptanceCertificate";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref        AS Ref,
	|	DocumentAttributes.DataVersion AS DataVersion
	|FROM
	|	UpdatedData AS UpdatedData
	|
	|	LEFT JOIN Document.InternalAcceptanceCertificate AS DocumentAttributes
	|	ON UpdatedData.Ref = DocumentAttributes.Ref
	|";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ExceptionReason = 0;
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			ObjectModified = False;
			
			If DocumentObject <> Undefined Then
				
				If Not ValueIsFilled(DocumentObject.Status) Then
					DocumentObject.Status = Enums.StatusesOfInternalAcceptanceCertificate.Accepted;
					ObjectModified = True;
				EndIf;
				
			EndIf;
			
			ExceptionReason = 2; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = 2 Then
				Raise NStr("vi = 'Không thể cập nhật chứng từ ""Biên bản nghiệm thu công việc nội bộ"".';
							|ru = 'Не удалось обработать обновление документов ""Акт выполненных внутренних работ"".';
							|en = 'Cannot process the update of the ""Internal work acceptance"" documents.'; fa = 'Cannot process the update of the ""Internal work acceptance"" documents.';
							|it = 'Cannot process the update of the ""Internal work acceptance"" documents.';
							|pl = 'Cannot process the update of the ""Internal work acceptance"" documents.';
							|tr = '""Tamamlanan dahili iş tutanağı"" belgelerinin güncellenmesi işlenemedi.'");
			EndIf;
			
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
