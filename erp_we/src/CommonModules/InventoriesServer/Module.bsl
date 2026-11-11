#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CompanyGoods);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CompanyGoodsForTransfer);
		
		If Document.AdditionalProperties.Property("RecordReservesOfGoodsOfOrganizationsTogetherWithAll")
			And Document.AdditionalProperties.RecordReservesOfGoodsOfOrganizationsTogetherWithAll Then
			
			TableName = NameOfOrganizationSProductReservesTable();
			
			Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CompanySafeStock);
			DocumentsPosting.AddDocumentDataTable(Document,
																TableName,
																Document.AdditionalProperties[TableName]);
		Else
			Parameters.ThereAreDerivedMotions = True;
		EndIf;
		
		Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.DatesOfCompanyGoodsReceipt);
		
	ElsIf Properties.WriteMode = DocumentWriteMode.UndoPosting Then // formation of reserves
		Parameters.ThereAreDerivedMotions = True;
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.CompanyGoods);
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.CompanySafeStock);
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.CompanyGoods);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.CompanyGoodsForTransfer);
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.CompanyGoods;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.CompanyGoodsForTransfer;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));	
	EndIf;
		
	Return QueriesTexts;
	
EndFunction

// Procedure for forming movements in subordinate registers of operational accounting of goods of organizations.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , "CompanyGoods");
	
	If RegisterRecords.Find("CompanyGoods") <> Undefined
		And RegisterRecords.CompanyGoods.Count() = 0
		And RegisterRecords.CompanyGoods.Write Then
		
		If RegisterRecords.Find("LotsOfGoodsOfOrganizations") <> Undefined Then
			RegisterRecords.LotsOfGoodsOfOrganizations.Write = True;
		EndIf;
	
		If RegisterRecords.Find("CustomersARAPAccountingByDocuments") <> Undefined Then
			RegisterRecords.CustomersARAPAccountingByDocuments.Write = True;
		EndIf;
		
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , "CompanyGoodsForTransfer");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , "GoodsForRegistrationOfImportDocuments");
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , "CompanySafeStock");
		
EndProcedure

// Procedure for forming movements based on independent registers of operational accounting of goods of organizations.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	TableName = "Table" + "DatesOfCompanyGoodsReceipt";
	
	If TablesForRegisteredRecords.Property(TableName)
		And ValueIsFilled(TablesForRegisteredRecords[TableName]) Then
		
		For Each TableRow In TablesForRegisteredRecords[TableName] Do
			RecordManager = InformationRegisters.DatesOfCompanyGoodsReceipt.CreateRecordManager();
			FillPropertyValues(RecordManager, TableRow);
			RecordManager.Write(True);
		EndDo;
		
	EndIf;
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//								used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	// Disabling standard motion cleaning
	If Document.RegisterRecords.CompanySafeStock.Write
		And (Not Document.AdditionalProperties.Property("RecordReservesOfGoodsOfOrganizationsTogetherWithAll")
		Or Not Document.AdditionalProperties.RecordReservesOfGoodsOfOrganizationsTogetherWithAll) Then
		Document.RegisterRecords.CompanySafeStock.Write = False;
	EndIf;
	
	If Document.AdditionalProperties.Property("ParametersForFillingInventoryTypes") Then
		If Document.AdditionalProperties.ParametersForFillingInventoryTypes = "GetBeforePreparation" Then
			Document.AdditionalProperties.ParametersForFillingInventoryTypes
				= Document.ParametersForFillingInventoryTypes(TempTablesManager);
		EndIf;
		
		WriteMode = DocumentsPosting.DocumentProperties(Document).WriteMode;
		If Document.AdditionalProperties.Property("UseFillingParametersForInventoryTypesInPreparation") Then
			FillParameters = Document.AdditionalProperties.ParametersForFillingInventoryTypes;
		Else
			FillParameters = Undefined;
		EndIf;
		PrepareRecordOfBusinessProducts(Document, TempTablesManager, WriteMode, FillParameters);
	EndIf;
	
EndProcedure

// Occurs after execution of the write registers of the instrument.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//								used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	FillParameters =
		ParametersForFillingInventoryTypesByAdditionalProperties(Document, TempTablesManager);
	
	If Not FillParameters = Undefined Then
		If TypeOf(FillParameters) = Type("Structure") Then
			CreateReservesForGoodsOfOrganizations(Document, TempTablesManager, Cancel, FillParameters);
		Else // Collection
			For Each CollectionItem In FillParameters Do
				CreateReservesForGoodsOfOrganizations(Document, TempTablesManager, Cancel, CollectionItem);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject, Structure - the document being recorded contains:
//  	* AdditionalProperties - Structure:
//  		** DocumentsPosting - Structure:
//  			*** DocumentProperties - FixedStructure:
//  				**** IsNew - Boolean
//  				**** WriteMode - DocumentWriteMode
//  				**** PostingMode - DocumentPostingMode
//  				**** Posted - Boolean
//  			*** ControlTables - Structure:
//  				**** MovementOfGoodsOfOrganizationsChange - Structure:
//  					***** ThereAreRecordsInTable - Boolean
//  					***** Parameters - Structure:
//  						****** MinimumPeriod - Date
//  		** PreparationOfGoodsForRegistrationOfImportDocumentsChange - Arbitrary
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	ParametersForFillingInventoryTypes =
		ParametersForFillingInventoryTypesByAdditionalProperties(Document, DocumentsPosting.ManagerOfTemporaryControlTables(Document));
	
	#Region CompanyGoods
	
	ThereIsTableOfResidues = DocumentsPosting.ThereAreRecordsInTable(Document, "MovementOfGoodsOfOrganizationsChange");
	ThereIsTableOfReserves = DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsReservesOfGoodsOfOrganizationsChange");
	
	WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault =
		WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault(ParametersForFillingInventoryTypes);
	
	If Not Document.AdditionalProperties.Property("FailureToFillInventoryTypes")
		And Not WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault
		And (ThereIsTableOfResidues Or ThereIsTableOfReserves) Then
		
		If ThereIsTableOfResidues Then
			ControlTableParameters = Document.AdditionalProperties.DocumentsPosting.ControlTables.MovementOfGoodsOfOrganizationsChange;
			MinimumPeriod = ControlTableParameters.Parameters.MinimumPeriod;
		Else
			MinimumPeriod = DateOfCurrentBalances();
		EndIf;
		
		If ThereIsTableOfResidues And ThereIsTableOfReserves Then
			
			RequestTextTTControlSelections =
			"SELECT DISTINCT
			|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	NestedQuery.Organization AS Organization,
			|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	NestedQuery.CCDNumber AS CCDNumber
			|INTO TTMotionControlSelections
			|FROM
			|	(SELECT
			|		ChangesTable.ItemsLocationAttributes AS ItemsLocationAttributes,
			|		ChangesTable.Organization AS Organization,
			|		ChangesTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|		ChangesTable.CCDNumber AS CCDNumber
			|	FROM
			|		MovementOfGoodsOfOrganizationsChange AS ChangesTable
			|			INNER JOIN Catalog.InventoryKinds AS InventoryKinds
			|			ON ChangesTable.InventoryOwnerAttribute = InventoryKinds.Ref
			|		
			|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
			|			ON ChangesTable.ItemsLocationAttributes = DimensionKeys.Ref
			|			
			|			LEFT JOIN Catalog.Assignments AS CatalogAssignments
			|			ON DimensionKeys.Purpose = CatalogAssignments.Ref
			|	WHERE
			|		NOT InventoryKinds.InventoryType IN (&UncontrolledInventoryTypes)
			|		AND (
			|			(
			|			NOT ISNULL(ChangesTable.ItemsLocationAttributes.Products.TracedGoods, FALSE)
			|				OR (ISNULL(ChangesTable.ItemsLocationAttributes.Products.TracedGoods, FALSE)
			|					AND ChangesTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef))
			|			OR NOT &UseTraceableImportedGoodsAccounting
			|			OR BEGINOFPERIOD(ChangesTable.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
			|			)
			|			AND (
			|				NOT &UseSeparateProcurement
			|				OR (&UseSeparateProcurement
			|					AND (NOT (ISNULL(ChangesTable.ItemsLocationAttributes.Products.KeepRecordsByCCD, FALSE)
			|						AND ChangesTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)))
			|					)
			|			)
			|		)
			|		AND (NOT &IgnoreTraceableWorkPurchasesUnderPrincipal
			|			OR (&IgnoreTraceableWorkPurchasesUnderPrincipal
			|				AND NOT (InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
			|					AND ISNULL(CatalogAssignments.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal), FALSE)
			|					)
			|				)
			|			)
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ChangesTable.ItemsLocationAttributes,
			|		ChangesTable.Organization,
			|		ChangesTable.InventoryOwnerAttribute,
			|		ChangesTable.CCDNumber
			|	FROM
			|		RegisteredRecordsReservesOfGoodsOfOrganizationsChange AS ChangesTable
			|			INNER JOIN Catalog.InventoryKinds AS InventoryKinds
			|			ON ChangesTable.InventoryOwnerAttribute = InventoryKinds.Ref
			|	WHERE
			|		NOT InventoryKinds.InventoryType IN (&UncontrolledInventoryTypes)) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.ItemsLocationAttributes,
			|	NestedQuery.InventoryOwnerAttribute,
			|	NestedQuery.Organization,
			|	NestedQuery.CCDNumber
			|
			|INDEX BY
			|	NestedQuery.InventoryOwnerAttribute,
			|	NestedQuery.CCDNumber,
			|	NestedQuery.Organization,
			|	NestedQuery.ItemsLocationAttributes";
			
		ElsIf ThereIsTableOfResidues Then
			
			RequestTextTTControlSelections =
			"SELECT
			|	ChangesTable.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	ChangesTable.Organization AS Organization,
			|	ChangesTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	ChangesTable.CCDNumber AS CCDNumber
			|INTO TTMotionControlSelections
			|FROM
			|	MovementOfGoodsOfOrganizationsChange AS ChangesTable
			|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
			|		ON ChangesTable.InventoryOwnerAttribute = InventoryKinds.Ref
			|		
			|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
			|		ON ChangesTable.ItemsLocationAttributes = DimensionKeys.Ref
			|		
			|		LEFT JOIN Catalog.Assignments AS CatalogAssignments
			|		ON DimensionKeys.Purpose = CatalogAssignments.Ref
			|WHERE
			|	NOT InventoryKinds.InventoryType IN (&UncontrolledInventoryTypes)
			|	AND (
			|		(
			|		NOT ISNULL(ChangesTable.ItemsLocationAttributes.Products.TracedGoods, FALSE)
			|			OR (ISNULL(ChangesTable.ItemsLocationAttributes.Products.TracedGoods, FALSE)
			|				AND ChangesTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef))
			|		OR NOT &UseTraceableImportedGoodsAccounting
			|		OR BEGINOFPERIOD(ChangesTable.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
			|		)
			|			AND (
			|				NOT &UseSeparateProcurement
			|				OR (&UseSeparateProcurement
			|					AND (NOT (ISNULL(ChangesTable.ItemsLocationAttributes.Products.KeepRecordsByCCD, FALSE)
			|						AND ChangesTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)))
			|					)
			|			)
			|	)
			|	AND (NOT &IgnoreTraceableWorkPurchasesUnderPrincipal
			|		OR (&IgnoreTraceableWorkPurchasesUnderPrincipal
			|			AND NOT (InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
			|				AND ISNULL(CatalogAssignments.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal), FALSE)
			|				)
			|			)
			|		)";
			
		ElsIf ThereIsTableOfReserves Then
			
			RequestTextTTControlSelections =
			"SELECT
			|	ChangesTable.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	ChangesTable.Organization AS Organization,
			|	ChangesTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	ChangesTable.CCDNumber AS CCDNumber
			|INTO TTMotionControlSelections
			|FROM
			|	RegisteredRecordsReservesOfGoodsOfOrganizationsChange AS ChangesTable
			|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
			|		ON ChangesTable.InventoryOwnerAttribute = InventoryKinds.Ref
			|WHERE
			|	NOT InventoryKinds.InventoryType IN (&UncontrolledInventoryTypes)
			|";
			
		EndIf;
		
		AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
		
		QueryTexts.Add(RequestTextTTControlSelections); //TTMotionControlSelections
		
		RequestTemplateForMonthBalance =
		"SELECT
		|	&PeriodDate AS Period,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.Organization AS Organization,
		|	CompanyGoodsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber AS CCDNumber,
		|	0 AS ReserveBalance,
		|	CompanyGoodsBalance.CountBalance AS CountBalance,
		|	CompanyGoodsBalance.ToRegisterGoodsIssueBalance AS ToRegisterGoodsIssueBalance
		|INTO TTBalanceOfGoodsOfOrganizationsByMonth
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|			&PeriodLimit,
		|			(ItemsLocationAttributes, Organization, InventoryOwnerAttribute, CCDNumber) IN
		|				(SELECT
		|					Filter.ItemsLocationAttributes,
		|					Filter.Organization,
		|					Filter.InventoryOwnerAttribute,
		|					Filter.CCDNumber
		|				FROM
		|					TTMotionControlSelections AS Filter)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	&PeriodDate,
		|	CompanySafeStockBalance.ItemsLocationAttributes,
		|	CompanySafeStockBalance.Organization,
		|	CompanySafeStockBalance.InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber,
		|	CompanySafeStockBalance.CountBalance,
		|	0,
		|	0
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|			&PeriodLimit,
		|			(ItemsLocationAttributes, Organization, InventoryOwnerAttribute, CCDNumber) IN
		|				(SELECT
		|					Filter.ItemsLocationAttributes,
		|					Filter.Organization,
		|					Filter.InventoryOwnerAttribute,
		|					Filter.CCDNumber
		|				FROM
		|					TTMotionControlSelections AS Filter)) AS CompanySafeStockBalance";
		
		MinimumPeriod = EndOfMonth(Min(MinimumPeriod, DateOfFirstReserve(MinimumPeriod)));
		EndOfTheCurrentMonth = EndOfMonth(CurrentSessionDate());
		
		// We haven't controlled it for more than three years, so as not to exceed the number of tables in the query.
		ThreeYearsAgo = EndOfMonth(AddMonth(EndOfTheCurrentMonth, -36)); 
		If MinimumPeriod < ThreeYearsAgo Then
			MinimumPeriod = ThreeYearsAgo;
		ElsIf MinimumPeriod > EndOfTheCurrentMonth Then
			MinimumPeriod = EndOfTheCurrentMonth;
		EndIf;
		
		ProcessedMonth = EndOfMonth(AddMonth(DateOfLastMovement(), -1));
		
		RequestTextsForBalancesByMonth = New Array;
		
		Counter = 0;
		
		While ProcessedMonth >= MinimumPeriod Do
			
			RequestTextForMonthBalance = StrReplace(RequestTemplateForMonthBalance, "&PeriodDate", "&PeriodDate" + String(Counter));
			RequestTextForMonthBalance = StrReplace(RequestTextForMonthBalance, "&PeriodLimit", "&PeriodLimit" + String(Counter));
			If Counter > 0 Then
				RequestTextForMonthBalance = StrReplace(RequestTextForMonthBalance, "INTO TTBalanceOfGoodsOfOrganizationsByMonth", "");
			EndIf;
			RequestTextsForBalancesByMonth.Add(RequestTextForMonthBalance);
			
			Query.SetParameter("PeriodDate" + String(Counter), ProcessedMonth);
			Query.SetParameter("PeriodLimit" + String(Counter), New Boundary(ProcessedMonth, BoundaryType.Including));
			
			Counter = Counter + 1;
			ProcessedMonth = EndOfMonth(AddMonth(ProcessedMonth, -1));
			
		EndDo;
		
		RequestTextForMonthBalance = StrReplace(RequestTemplateForMonthBalance, "&PeriodDate", "&PeriodDate" + String(Counter));
		RequestTextForMonthBalance = StrReplace(RequestTextForMonthBalance, "&PeriodLimit", "");
		If Counter > 0 Then
			RequestTextForMonthBalance = StrReplace(RequestTextForMonthBalance, "INTO TTBalanceOfGoodsOfOrganizationsByMonth", "");
		EndIf;
		RequestTextsForBalancesByMonth.Add(RequestTextForMonthBalance);
		
		QueryTexts.Add(StrConcat(RequestTextsForBalancesByMonth,
			TMCommonUse.QuerySeparatorInJoin()));// TTBalanceOfGoodsOfOrganizationsByMonth
		
		ControlRequestText =
		"SELECT
		|	BalancesByMonth.Period AS Period,
		|	BalancesByMonth.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InventoryLocationAttributeKeys.Products.UnitOfMeasure AS UnitOfMeasure,
		|	InventoryLocationAttributeKeys.Products AS Products,
		|	InventoryLocationAttributeKeys.StorageLocation AS StorageLocation,
		|	BalancesByMonth.Organization AS Organization,
		|	BalancesByMonth.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	BalancesByMonth.CCDNumber AS CCDNumber,
		|	SUM(BalancesByMonth.CountBalance) AS CountBalance,
		|	SUM(BalancesByMonth.ReserveBalance) AS ReserveBalance,
		|	SUM(BalancesByMonth.ToRegisterGoodsIssueBalance) AS ToRegisterGoodsIssueBalance
		|FROM
		|	TTBalanceOfGoodsOfOrganizationsByMonth AS BalancesByMonth
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON BalancesByMonth.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|
		|GROUP BY
		|	BalancesByMonth.ItemsLocationAttributes,
		|	InventoryLocationAttributeKeys.Products.UnitOfMeasure,
		|	InventoryLocationAttributeKeys.Products,
		|	InventoryLocationAttributeKeys.StorageLocation,
		|	BalancesByMonth.Organization,
		|	BalancesByMonth.InventoryOwnerAttribute,
		|	BalancesByMonth.CCDNumber,
		|	BalancesByMonth.Period
		|
		|ORDER BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber,
		|	Period";
		
		ParametersForFillingInventoryTypesAreSet =
			TypeOf(ParametersForFillingInventoryTypes) = Type("Structure");
		UseSeparateProcurement =
			?(ParametersForFillingInventoryTypesAreSet,
				ParametersForFillingInventoryTypes.UseSeparateProcurement,
				False);
		IgnoreTraceableWorkPurchasesUnderPrincipal = 
			?(ParametersForFillingInventoryTypesAreSet,
				ParametersForFillingInventoryTypes.IgnoreTraceableWorkPurchasesUnderPrincipal,
				False);
		
		Query.SetParameter("PeriodDate" + String(Counter), DateOfCurrentBalances());
		Query.SetParameter("UncontrolledInventoryTypes", UncontrolledInventoryTypes());
		Query.SetParameter("UseSeparateProcurement", UseSeparateProcurement);
		Query.SetParameter("IgnoreTraceableWorkPurchasesUnderPrincipal",
									IgnoreTraceableWorkPurchasesUnderPrincipal);
		
		QueryTexts.Add(ControlRequestText, "ErrorsGoodsOfOrganizationsReservesSummary");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	#Region CompanyGoods
	
	If Not Document.AdditionalProperties.Property("FailureToFillInventoryTypes")
		And (DocumentsPosting.ThereAreRecordsInTable(Document, "MovementOfGoodsOfOrganizationsChange")
			Or DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsReservesOfGoodsOfOrganizationsChange"))
		And ControlResults.Property("ErrorsGoodsOfOrganizationsReservesSummary")
		And ValueIsFilled(ControlResults.ErrorsGoodsOfOrganizationsReservesSummary) Then
		
		ErrorLines = ControlResults.ErrorsGoodsOfOrganizationsReservesSummary;
		
		ControlNegativeBalances = Not SessionParameters.PostWithoutControlOfCompanyStockBalance
			And Constants.ControlCompanyStockBalance.Get();
		RefillInventoryKinds = Document.AdditionalProperties.Property("RefillInventoryKinds")
			And Document.AdditionalProperties.RefillInventoryKinds;
		
		WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault =
			Document.AdditionalProperties.Property("ParametersForFillingInventoryTypes")
			And WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault(
				Document.AdditionalProperties.ParametersForFillingInventoryTypes);
		
		NegativeRemainder = 0;
		CoveringReserve = 0;
		
		IndexOf = 0;
		RowsCount = ErrorLines.Count();
		
		While IndexOf < RowsCount Do
			
			ErrorString = ErrorLines[IndexOf];
			IndexOf = IndexOf + 1;
			
			If Not RefillInventoryKinds Then
				NegativeRemainder = Min(ErrorString.CountBalance, NegativeRemainder);
				CoveringReserve = Max(ErrorString.ReserveBalance, CoveringReserve);
			EndIf;
			
			// Checking for a negative balance.
			If ControlNegativeBalances
				And ErrorString.CountBalance + ErrorString.ReserveBalance < 0
				And Not WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault Then
				
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization% tại %Month% tìm thấy số dư âm %Count% %UnitOfMeasure% hàng hóa %OwnGoods% trong kho bãi %StorageLocation%';
									|ru = 'По организации %Organization% на %Month% обнаружен отрицательный остаток %Count% %UnitOfMeasure% товара %OwnGoods% в месте хранения %StorageLocation%';
									|en = 'By company %Organization% for the %Month% negative balance detected %Count% %UnitOfMeasure% of goods %OwnGoods% in storage location %StorageLocation%'; fa = 'By company %Organization% for the %Month% negative balance detected %Count% %UnitOfMeasure% of goods %OwnGoods% in storage location %StorageLocation%';
									|it = 'Per l''azienda %Organization% in %Month% è stato rilevato un saldo negativo  %Count% %UnitOfMeasure% della merce %OwnGoods% nella posizione di stoccaggio %StorageLocation%';
									|pl = 'Wg firmy %Organization% na %Month% została ujawniona ujemna pozostałość %Count% %UnitOfMeasure% towaru %OwnGoods% w magazynie %StorageLocation%';
									|tr = '%Organization% iş yeri için %Month% için, %StorageLocation% ambar konumunda %Count% %UnitOfMeasure% %OwnGoods%ürün için negatif bir bakiye bulundu'");
				
				If ErrorString.Period = DateOfCurrentBalances() Then
					MessageText = StrReplace(MessageText, "%Month%", NStr("vi = 'ngày liên quan của số dư';
																			|ru = 'дату актуальности остатков';
																			|en = 'balance relevance date'; fa = 'balance relevance date';
																			|it = 'Data saldi';
																			|pl = 'datę aktualności pozostałości';
																			|tr = 'bakiyelerin geçerlilik tarihine'"));
				EndIf;
				
				FillInGeneralParametersForErrorMessagesForOrganizationsProductsAndReserves(
					MessageText, Document.Ref, ErrorString);
				MessageText = StrReplace(MessageText, "%Count%", ErrorString.CountBalance + ErrorString.ReserveBalance);
				MessageText = StrReplace(MessageText, "%UnitOfMeasure%", ErrorString.UnitOfMeasure);
				MessageText = StrReplace(MessageText, "%OwnGoods%", ErrorString.Products);
				MessageText = StrReplace(MessageText, "%StorageLocation%", ErrorString.StorageLocation);
				
				CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
				
			EndIf;
			
			If ControlNegativeBalances 
				And ErrorString.ToRegisterGoodsIssueBalance < 0 Then
				
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization% vào %Month% đã tìm thấy số dư âm cần lập chứng từ ghi giảm %Count% %UnitOfMeasure% hàng hóa %OwnGoods% tại vị trí lưu %StorageLocation%';
									|ru = 'По организации %Organization% на %Month% обнаружен отрицательный остаток к оформлению списания %Count% %UnitOfMeasure% товара %OwnGoods% в месте хранения %StorageLocation%';
									|en = 'By company %Organization% for the %Month% negative balance detected for write-off %Count% %UnitOfMeasure% of goods %OwnGoods% in storage location %StorageLocation%'; fa = 'By company %Organization% for the %Month% negative balance detected for write-off %Count% %UnitOfMeasure% of goods %OwnGoods% in storage location %StorageLocation%';
									|it = 'Per l''azienda %Organization% in %Month% è stato rilevato un saldo negativo nella formalizzazione della cancellazione %Count% %UnitOfMeasure% della merce%OwnGoods% nella posizione di stoccaggio %StorageLocation%';
									|pl = 'Wg firmy %Organization% na %Month% została ujawniona ujemna pozostałość do zatwierdzenia rozchodu %Count% %UnitOfMeasure% towaru %OwnGoods% w miejscu przechowywania %StorageLocation%';
									|tr = '%Organization% iş yeri için %Month% için, %StorageLocation% ambar konumunda %Count% %UnitOfMeasure% %OwnGoods%gider yazılacak negatif ürün bakiyesi bulundu'");
				
				If ErrorString.Period = DateOfCurrentBalances() Then
					MessageText = StrReplace(MessageText, "%Month%", NStr("vi = 'ngày liên quan của số dư';
																			|ru = 'дату актуальности остатков';
																			|en = 'balance relevance date'; fa = 'balance relevance date';
																			|it = 'Data saldi';
																			|pl = 'datę aktualności pozostałości';
																			|tr = 'bakiyelerin geçerlilik tarihine'"));
				EndIf;
				
				FillInGeneralParametersForErrorMessagesForOrganizationsProductsAndReserves(
					MessageText, Document.Ref, ErrorString);
				MessageText = StrReplace(MessageText, "%Count%", ErrorString.ToRegisterGoodsIssueBalance);
				MessageText = StrReplace(MessageText, "%UnitOfMeasure%", ErrorString.UnitOfMeasure);
				MessageText = StrReplace(MessageText, "%OwnGoods%", ErrorString.Products);
				MessageText = StrReplace(MessageText, "%StorageLocation%", ErrorString.StorageLocation);
				
				CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
				
			EndIf;
			
			If IndexOf = RowsCount
				Or ErrorString.Organization <> ErrorLines[IndexOf].Organization
				Or ErrorString.ItemsLocationAttributes <> ErrorLines[IndexOf].ItemsLocationAttributes
				Or ErrorString.InventoryOwnerAttribute <> ErrorLines[IndexOf].InventoryOwnerAttribute
				Or ErrorString.CCDNumber <> ErrorLines[IndexOf].CCDNumber Then
			
				// General check of excess reserve for all periods.
				If NegativeRemainder + CoveringReserve > 0 Then
					MessageText = NStr("vi = 'Khi ghi lại %Recorder% trong biểu ghi %Register1% và %Register2%
					|đã tìm thấy dự phòng thừa theo chiều đo: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, dự phòng thừa %Delta%.';
					|ru = 'При записи %Recorder% в регистры %Register1% и %Register2%
					|обнаружен лишний резерв по измерениям: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, лишний резерв %Delta%.';
					|en = 'While writing %Recorder% to the %Register1% and %Register2% registers,
					|an excessive reserve was found for dimensions: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, extra reserve %Delta%.'; fa = 'While writing %Recorder% to the %Register1% and %Register2% registers,
					|an excessive reserve was found for dimensions: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, extra reserve %Delta%.';
					|it = 'Durante la registrazione %Recorder% nel registro %Register1% e %Register2%
					| è stata rilevata una riserva aggiuntiva per misurazioni: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, riserva aggiuntiva %Delta%.';
					|pl = 'Podczas zapisu %Recorder% do rejestrów %Register1% i %Register2%
					|jest ujawniony nadmierny rezerw wg pomiarów: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, nadmierny rezerw %Delta%.';
					|tr = '%Recorder%, %Register1% ve %Register2%
					| kayıtlarına kaydedilirken, şu boyutlar için fazladan bir rezerv bulundu: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, fazladan rezerv %Delta%.'");
					MessageText = StrReplace(MessageText, "%Register2%", "CompanySafeStock");
					MessageText = StrReplace(MessageText, "%Register1%", "CompanyGoods");
					
					FillInGeneralParametersForErrorMessagesForOrganizationsProductsAndReserves(MessageText, Document.Ref, ErrorString);
					MessageText = StrReplace(MessageText, "%Delta%", NegativeRemainder + CoveringReserve);
					
					CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
				EndIf;
				
				NegativeRemainder = 0;
				CoveringReserve = 0;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Returns the name of the temporary accumulation register table 'Organization Reserves'.
//
// Returns:
//	String - the name of the temporary table of the accumulation register 'Reserves of organizations'.
//
Function NameOfOrganizationSProductReservesTable() Export
	
	TableName = "Table" + "CompanySafeStock";
	
	Return TableName;
	
EndFunction

#EndRegion

#Region CheckingNeedToFillTypesOfStocks

// The procedure checks the change of details in the document.
//
// Parameters:
// 	TempTablesManager - TempTablesManager - 
// 	Ref - DocumentRef - 
// 	AttributesNames - String - 
// 	
// Returns:
// 	Boolean - LongDesc
//
Function CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref", Ref);
	
	Query.Text =
	"SELECT
	|	TRUE AS DetailsChanged_
	|FROM
	|	DocumentDataTable AS DocumentData
	|	LEFT JOIN &Document AS SavedData
	|		ON SavedData.Ref = &Ref
	|WHERE
	|	SavedData.Ref IS NULL
	|	OR &TextCondition";
	
	TextCondition = "";
	
	For Each KeyAndValue In New Structure(AttributesNames) Do
		TextCondition = TextCondition + "
			|	OR DocumentData." + KeyAndValue.Key + " <> SavedData." + KeyAndValue.Key;
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&Document", "Document." + Ref.Metadata().Name);
	Query.Text = StrReplace(Query.Text, "OR &TextCondition", TextCondition);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

// The function checks for changes in the "Products" table part relative to the "inventory Types" table part of the document.
//
// Parameters:
//	TempTablesManager - TempTablesManager -
//
// Returns:
//	Boolean - True, the commodity composition of the document has changed.
//
Function CheckProductChangesByQuantity(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.Count AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		-TableTypesOfStocks_.Count AS Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

// The function checks for changes in the "Products" table part relative to the "inventory Types" table part of the document.
//
// Parameters:
//	TempTablesManager - TempTablesManager -
//
// Returns:
//	Boolean - The truth is that the goods have been changed.
//
Function CheckChangesInGoodsByQuantityAndAmount(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.VATRate AS VATRate
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.CommissionAmount AS CommissionAmount,
	|		TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType  IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|		-TableTypesOfStocks_.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.CommissionAmount) <> 0
	|	OR SUM(TableOfGoods.AmountVATRemuneration) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

// Checks whether inventory types need to be forcibly refilled and sets the appropriate
// request parameter.
//
// Parameters:
//	DocumentObjectOrItsProperties - DocumentObject, Structure - the object of the document or additional document properties.
//	Query - Query - request to contact the IB.
//
// Returns:
//	Boolean - True, it is necessary to replenish the types of stocks.
//
Function CheckWhetherDocumentInventoryTypesNeedToBeRefilled(DocumentObjectOrItsProperties, Query = Undefined) Export
	
	NameOfThisProperty = NameOfAdditionalPropertyForRefillingInventoryViews();
	
	RefillInventoryKinds = ?(TypeOf(DocumentObjectOrItsProperties) = Type("Structure"),
								DocumentObjectOrItsProperties.Property(NameOfThisProperty),
								DocumentObjectOrItsProperties.AdditionalProperties.Property(NameOfThisProperty));
	
	If Query <> Undefined Then
		Query.SetParameter(NameOfThisProperty, RefillInventoryKinds);
	EndIf;
	
	Return RefillInventoryKinds;
	
EndFunction

// Adds mandatory columns to temporary tables that are required for correct filling of inventory types.
//
// Parameters:
//	Query - Query - a query that contains a description of temporary tables.
//
Procedure AddMandatoryColumnsToTemporaryTables(Query) Export
	
	DescriptionOfTables = DescriptionOfTablesWithRequiredColumns();
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(Query.Text);
	
	For Each SchemaRequest In QuerySchema.QueryBatch Do
		
		If TypeOf(SchemaRequest) = Type("QuerySchemaTableDropQuery") Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(SchemaRequest.PlacementTable) Then
			Continue;
		EndIf;
		
		// If the source of the request is taken from a parameter, then we will add a temporary service
		// table so that it is possible to select values INDEFINITELY.
		If DescriptionOfTables.Property(SchemaRequest.PlacementTable) Then
			
			If SchemaRequest.Operators[0].Sources.Count()
				And CommonClientServer.HasAttributeOrObjectProperty(SchemaRequest.Operators[0].Sources[0].Source, "TableName")
				And StrFind(SchemaRequest.Operators[0].Sources[0].Source.TableName, "&") <> 0 Then
				
				PlacementTable = SchemaRequest.PlacementTable;
				SchemaRequest.PlacementTable = PlacementTable + "ServiceTT";
				
				NewSchemaRequest = QuerySchema.QueryBatch.Add(Type("QuerySchemaSelectQuery"));
				NewSchemaRequest.PlacementTable = PlacementTable;
				NewSchemaRequest.Operators[0].Sources.Add(PlacementTable + "ServiceTT");
				
				AvailableFields = NewSchemaRequest.Operators[0].Sources[0].Source.AvailableFields;
				
				For Each AvailableField In AvailableFields Do
					NewSchemaRequest.Operators[0].SelectedFields.Add(PlacementTable + "ServiceTT."
																			+ AvailableField.Name);
				EndDo;
				
				QuerySchema.QueryBatch.Add(Type("QuerySchemaTableDropQuery")).TableName =
					PlacementTable + "ServiceTT";
				
			EndIf;
			
		EndIf;
		
		TableDetails = Undefined;
		
		If DescriptionOfTables.Property(SchemaRequest.PlacementTable, TableDetails) Then
			For Each ColumnDetails In TableDetails Do
				If SchemaRequest.Columns.Find(ColumnDetails.Key) <> Undefined Then
					Continue;
				EndIf;
				
				For Each Operator In SchemaRequest.Operators Do
					Field = Operator.SelectedFields.Add(ColumnDetails.Value);
				EndDo;
				
				Column = SchemaRequest.Columns.Find(Field);
				Column.Alias = ColumnDetails.Key;
			EndDo;
		EndIf;
		
	EndDo;
	
	Query.Text = QuerySchema.GetQueryText();
	
EndProcedure

#EndRegion

#Region FillingStockTypes

// Returns the structure that is used when filling in inventory types.
// The structure describes the main selection of inventory types and control options.
//
// Returns:
//	Structure - LongDesc:
//		* NameTSTypesOfStocks - String - the name of the tabular part of the document to which the selected inventory types will be added.
//		* TableTypesOfStocks_ - Undefined, ValueTable - the table to which the selected inventory types will be added.
//																If defined, the inventory types will be added only
//																to the value table, and not to the table part.
//																Table description:
//			** ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys
//			** InventoryOwnerAttribute - CatalogRef.InventoryKinds
//			** CCDNumber - CatalogRef.CCDNumbers
//			** Warehouse - CatalogRef.Warehouses
//			** Count - Number
//			** QuantityByGBRN - Number
//			** AmountIncludingVAT - Number
//			** VATAmount - Number
//			** VATRate - CatalogRef.VATRates
//			** CommissionAmount - Number
//			** AmountVATRemuneration - Number
//			** ItemsLocationAttributesShipment - CatalogRef.InventoryLocationAttributeKeys
//			** InventoryOwnerAttributeShipment - CatalogRef.InventoryKinds
//			** CorInventoryOwnerAttribute - CatalogRef.InventoryKinds
//			** DocumentTransfers_ - Undefined
//			** SalesOrder - Undefined
//		* CompanyFieldName1 - String - Name of the Bank account in the document where the organization is stored.
//		* AvailableTypesOfStocksHaveAlreadyBeenFormed - Boolean - shows the absence of the need To Form TT available Types Of Reserves.
//		* TableOfBalancesHasAlreadyBeenFormed - Boolean - in rare cases, The Balance Table, according to which
//													stock types need to be filled, can be generated in advance in the calling code.
//		* SelectTypesOfStocksForIntercampany - Boolean - Solves the need of consumption of inventories
//														under the scheme intercompany.
//		* WhenSelectingByIntercampanyExcludeOrganizations - Array of CatalogRef.Companies - exclude organizations.
//		* CorTypesOfStocks - Array of CatalogRef.InventoryKinds- collection of stock types.
//		* DocumentMakesBothArrivalAndExpenditure - Boolean - indicates that the document makes incoming and outgoing movements.
//													For example: Document.Transfer of goods between organizations.
//													In this case, a more complex mechanism
//													for the formation of reserves is used - reserves are recorded once when processing
//													all types of movements.
//		* VATTaxation - Undefined - Type of tax document. If it is not filled in, it is considered that
//												it does not change.
//		* SelectionOfStockTypes_ - See Catalogs.InventoryKinds.StockTypeSelectionParameters.
//		* ThereIsSelectionByCCDNumber - Boolean - TRUE, a sign that when selecting goods Balances, Balances are taken into account in the context of CCD numbers.
//		* ReportFillingErrors - Boolean - Indicates whether information messages should be displayed to the user.
//		* NameOfRemainderTable - String - Name of the balance table.
//		* NumberOfPeriodsWhenFormingReservesOfOrganizations - Number, Undefined - filled in when
//																						Balances are Generated by the source of the organizations' Products.
//		* SelectStocksOfDifferentPeriods - Boolean - The document is allowed to use inventory types from different periods.
//		* TableNewReserves - Undefined, ValueTable - a table of generated reserves containing the following columns:
//			** ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys
//			** Organization - CatalogRef.Companies
//			** InventoryOwnerAttribute - CatalogRef.InventoryKinds
//			** CCDNumber - CatalogRef.CCDNumbers
//			** ThisIsReverseTransaction - Boolean
//			** Count - Number
//			** QuantityByGBRN - Number
//		* TableOfStornoRegisteredRecords- Undefined, ValueTable - table of reversing movements of reserves of goods of organizations, containing the following columns:
//			** ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys
//			** Organization - CatalogRef.Companies
//			** InventoryOwnerAttribute - CatalogRef.InventoryKinds
//			** CCDNumber - CatalogRef.CCDNumbers
//			** ThisIsReverseTransaction - Boolean
//			** Count - Number
//			** QuantityByGBRN - Number
//		* WithoutSelectionByCCDNumbers - Boolean - an indication of the need to select stocks in the context of CCD Numbers.
//		* FillingPeriod - Undefined, Date - if Select stocks of different periods = True, then this parameter
//													indicates the period from which inventory types need to be replenished.
//		* ThereIsTableOfInventoryTypes - Boolean - a sign that you need to add a table of inventory types
//														from the document being filled In to The Balance table, i.e. the document
//														enters these types of inventory during the process, so the document itself can use them
//														up already.
//		* NameOfInventoryTypeTable - String - The name of the temporary table containing the types of inventory received during the
//														document, which must be taken into account when the
//														flag is set to the table of inventory types received.
//		* PickUpVTCHGoodsAcceptedForResponsibleStorage - Map of KeyAndValue:
//			** Key - EnumRef.InventoryTypes - type of inventory.
//			** Values - String - The value is Never, according to the adjustment of the agreement, the economic operation - if the type of inventory of the inventory has been selected by the Balance
//															, then, depending on the flag, it will either be substituted in the TS, or its own will be substituted, and by the type of key stock
//															A reserve will be formed. If an economic operation is specified, the choice of action depends on the economic operation in the line and is determined
//															by the parameter. If there is no setting for the inventory type, then it is substituted in the TS.
//		* ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation - Map of KeyAndValue:
//			** Key - EnumRef.InventoryTypes - type of inventory.
//			** Value - Map of KeyAndValue:
//				*** Key - EnumRef.BusinessTransactions - economic operation.
//				*** Value - String - A string from the list of values of the Select Item parameter is received responsiblethe storage.
//		* WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault - Undefined - If there are not enough balances, the default inventory type is generated. The value "False" is ignored
//																							if the control of the organization's product balances is disabled. A strict prohibition for "false" can be set by using
//																							the additional parameter ignore control of the organization's productsubscribe from silence.
//																							When using this parameter, you need a table of Requisitovidovzapasovpomolchaniyu.
//		* IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited - Boolean - Specifies whether to ignore the disabled control of organization products if the parameter
//																							Prinehvatketovarorganizationfillvidamizapasovmolchaniyu set to "False".
//		* ProductOwnerInHeader - Boolean - it is used to determine where to get values for generating inventory types - from the data table OF the document, which contains the details of the document header, or
//											from the table of requisitovidovzapasovpol.
//		* TableOfDetailsOfStockTypesByDefault - See EmptyTableOfDetailsOfStockTypesByDefault.
//		* ReversedDocument - DocumentRef, Undefined - a link to the document being reversed in the information security, used
//																when selecting types of stocks in the document Correction
//																or Reverse before writing the document.
//		* UseSeparateProcurement - Boolean - used to perform Balance Control
//																Goods of organizations for separate procurement (two-way).
//		* SelectAmountsWithZeroAmount- Boolean - It is used to obtain summary indicators of Balances
//														regardless of quantitative Balances.
//		* IgnoreTraceableWorkPurchasesUnderPrincipal - Boolean - used to perform Balance control
//																			Items of organizations for traceable
//																			work in the scheme of procurement of items for the principal.
//		* CalculateAmountOfExciseTax - Boolean - determines the need to calculate the amount of excise tax for the types of stocks subject to excise tax.
//		* ExciseAccrualPeriod - Undefined, Date - used to determine the excisability of the item and the current excise tax rate.
//		* PriorityOfSelectionOfExcisableInventory - Boolean - determines the use of priority selection of stocks on the basis of Is subject to excise duty.
//		* FillExcisableItemsWithDefaultInventoryOwnerAttributes - Boolean - determines the need to fill in the Inventory 
//																		owner attributes by default when there is a shortage of Balances for items 
//																		of organizations for excisable items in documents
//																		where it is not possible to specify the Inventory
//																		owner attributes manually.
//		* CreditNoteAdjustmentAfterTransferOfOwnership - Boolean - It is used for the selection of analysts at the place
//																			of storage when selecting stocks
//																			for the registration of a sales adjustment document.
//		* PeriodOfFoundationDocument - Undefined, Date - used to obtain infobase data as of the date of the founding document.
//		* SelectCommissionInventoryForCommitteeSTaxation - Boolean - It is used to select commission types
//																			of stocks according to the committee's taxation and
//																			the applicable VAT rate when selling.
//
Function ParametersForFillingInventoryTypes() Export
	
	Result = New Structure;
	Result.Insert("NameTSTypesOfStocks", "InventoryKinds");
	Result.Insert("TableTypesOfStocks_", Undefined);
	Result.Insert("CompanyFieldName1", "Organization");
	
	Result.Insert("AvailableTypesOfStocksHaveAlreadyBeenFormed", False);
	Result.Insert("TableOfBalancesHasAlreadyBeenFormed", False);
	
	Result.Insert("SelectTypesOfStocksForIntercampany", True);
	Result.Insert("WhenSelectingByIntercampanyExcludeOrganizations", New Array);
	Result.Insert("CorTypesOfStocks", New Array);
	
	Result.Insert("DocumentMakesBothArrivalAndExpenditure", False);
	
	Result.Insert("VATTaxation", Undefined);
	Result.Insert("SelectionOfStockTypes_", Catalogs.InventoryKinds.StockTypeSelectionParameters());
	Result.SelectionOfStockTypes_.InventoryType = New Array;
	Result.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	Result.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	Result.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ConsignedGoods);
	
	Result.SelectionOfStockTypes_.SubjectToExcise = New Array;
	Result.SelectionOfStockTypes_.SubjectToExcise.Add(False);
	
	Result.Insert("ThereIsSelectionByCCDNumber", False);
	
	Result.Insert("ReportFillingErrors", True);
	Result.Insert("NameOfRemainderTable", "CompanyGoods");
	Result.Insert("NumberOfPeriodsWhenFormingReservesOfOrganizations", Undefined);
	
	Result.Insert("SelectStocksOfDifferentPeriods", False);
	Result.Insert("FillingPeriod", Undefined);
	Result.Insert("ThereIsTableOfInventoryTypes", False);
	Result.Insert("NameOfInventoryTypeTable", "");
	
	Result.Insert("TableNewReserves", Undefined);
	Result.Insert("TableOfStornoRegisteredRecords", Undefined);
	
	Result.Insert("WithoutSelectionByCCDNumbers", False);
	Result.Insert("PickUpVTCHGoodsAcceptedForResponsibleStorage", New Map);
	Result.Insert("ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation", Undefined);
	
	Result.Insert("WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault", Undefined);
	Result.Insert("IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited", False);
	Result.Insert("TableOfDetailsOfStockTypesByDefault", EmptyTableOfDetailsOfStockTypesByDefault());
	Result.Insert("ProductOwnerInHeader", True);
	Result.Insert("ReversedDocument", Undefined);
	
	Result.Insert("UseSeparateProcurement", False);
	Result.Insert("SelectAmountsWithZeroAmount", False);
	Result.Insert("IgnoreTraceableWorkPurchasesUnderPrincipal", False);
	Result.Insert("CreditNoteAdjustmentAfterTransferOfOwnership", False);
	
	Result.Insert("CalculateAmountOfExciseTax", False);
	Result.Insert("ExciseAccrualPeriod", Undefined);
	Result.Insert("PriorityOfSelectionOfExcisableInventory", False);
	Result.Insert("FillExcisableItemsWithDefaultInventoryOwnerAttributes", False);
	Result.Insert("PeriodOfFoundationDocument", Undefined);
	Result.Insert("SelectCommissionInventoryForCommitteeSTaxation", False);
	
	Return Result;
	
EndFunction

// Returns a collection of parameters that is used when selecting Inventory owner attributes in the manual mode of specifying
// document data.
//
// Returns:
//	Structure - a collection that contains the following properties:
//		* IgnoreResidueControlErrors - Boolean - the attribute that determines the need to continue
//														the execution of the transaction for the selection of document stocks.
//		* DoNotFillInInventoryOwnerAttributesOfExcisableItems - Boolean - An attribute that determines
//																whether the default inventory type for excisable items needs to be filled in.
//
Function ParametersForFillingInInventoryOwnerAttributesManually() Export
	
	FillParameters = New Structure;
	FillParameters.Insert("IgnoreResidueControlErrors",			False);
	FillParameters.Insert("DoNotFillInInventoryOwnerAttributesOfExcisableItems",	False);
	
	Return FillParameters;
	
EndFunction

// Fills in the inventory types in the "Products" tabular part of the goods receipt document.
//
// Parameters:
//	TempTablesManager - TempTablesManager - requires a temporary table of SourceTable Items
//								(Line Numbers, Nomenclature, Organization, Business Operation, Inventory Type, Supplier, 
//								Agreement, Currency, And Taxation).
//	TabularPartProducts - TabularSection - the tabular part of the document.
//	DocumentInventoryView - CatalogRef.InventoryKinds - Found inventory type (return value).
//															Used if the parameter "tableparts" is 
//															set to Undefined.
//	FieldName - String - Name of the field in the table part of the inventory table Where the inventory types should be located.
//	This transfer of goods between organizations is Boolean-Indicates that the call comes from a document for transferring goods 
//													between organizations.
//		
Procedure FillStockTypesByDefault(TempTablesManager,
											TabularPartProducts,
											DocumentInventoryView = Undefined,
											FieldName = "InventoryOwnerAttribute") Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ThisIsReusablePackage AS ThisIsReusablePackage,
	|	CASE
	|		WHEN ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.InventoryTypes.Work_5)
	|		WHEN TableOfGoods.ThisIsReusablePackage
	|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|		ELSE TableOfGoods.InventoryType
	|	END AS InventoryType,
	|	TableOfGoods.Organization AS Organization,
	|	CASE
	|		WHEN ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		WHEN TableOfGoods.ThisIsReusablePackage
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		ELSE TableOfGoods.BusinessOperation
	|	END AS BusinessOperation,
	|	TableOfGoods.Terms AS Terms,
	|	TableOfGoods.Currency AS Currency,
	|	CASE
	|		WHEN TableOfGoods.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TableOfGoods.VATTaxation
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxation,
	|	TableOfGoods.TaxationOfOrganization AS TaxationOfOrganization,
	|	CASE TableOfGoods.GoodsOwner
	|		WHEN VALUE(Catalog.Partners.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.GoodsOwner
	|	END AS GoodsOwner,
	|	CASE TableOfGoods.Counterparty
	|		WHEN VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.Counterparty
	|	END AS Counterparty,
	|	CASE TableOfGoods.Contract
	|		WHEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.Contract
	|	END AS Contract,
	|	CASE
	|		WHEN NOT &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|				OR ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|		ELSE ProductData_1.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	TableOfGoods.PriceKind AS PriceKind,
	|	TableOfGoods.SubjectToExcise AS SubjectToExcise,
	|	TableOfGoods.BusinessUnitProduction AS BusinessUnitProduction,
	|	TableOfGoods.CurViewOfStocks AS CurViewOfStocks
	|INTO TableOfProductsWithAnalytics
	|FROM
	|	OriginalProductTable AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	ProductData_1.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|										VALUE(Enum.ItemsTypes.Work_5),
	|										VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Organization AS Organization
	|INTO SelectionOfStockTypes
	|FROM
	|	TableOfProductsWithAnalytics AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TypesOfReserveReserves.Ref AS Ref,
	|	TypesOfReserveReserves.Organization AS Organization,
	|	TypesOfReserveReserves.InventoryType AS InventoryType,
	|	TypesOfReserveReserves.VATTaxation AS VATTaxation,
	|	TypesOfReserveReserves.GoodsOwner AS GoodsOwner,
	|	TypesOfReserveReserves.Terms AS Terms,
	|	TypesOfReserveReserves.Currency AS Currency,
	|	TypesOfReserveReserves.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TypesOfReserveReserves.Counterparty AS Counterparty,
	|	TypesOfReserveReserves.Contract AS Contract,
	|	TypesOfReserveReserves.ProductsGroup AS ProductsGroup,
	|	TypesOfReserveReserves.PriceKind AS PriceKind,
	|	TypesOfReserveReserves.SubjectToExcise AS SubjectToExcise,
	|	TypesOfReserveReserves.BusinessUnitProduction AS BusinessUnitProduction,
	|	TypesOfReserveReserves.Obsolete1 AS Obsolete1
	|INTO TypesOfReserveReserves
	|FROM
	|	Catalog.InventoryKinds AS TypesOfReserveReserves
	|		INNER JOIN SelectionOfStockTypes AS Filter
	|		ON TypesOfReserveReserves.Organization = Filter.Organization
	|WHERE
	|	NOT TypesOfReserveReserves.IsDuplicate
	|
	|INDEX BY
	|	Organization,
	|	InventoryType,
	|	Terms,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber            AS LineNumber,
	|	TableOfGoods.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TableOfGoods.InventoryType             AS InventoryType,
	|	TableOfGoods.ThisIsReusablePackage      AS ThisIsReusablePackage,
	|	TableOfGoods.Organization            AS Organization,
	|	TableOfGoods.BusinessOperation  AS BusinessOperation,
	|	TableOfGoods.Terms             AS Terms,
	|	TableOfGoods.Currency                 AS Currency,
	|	TableOfGoods.VATTaxation     AS VATTaxation,
	|	TableOfGoods.TaxationOfOrganization AS TaxationOfOrganization,
	|	TableOfGoods.GoodsOwner         AS GoodsOwner,
	|	TableOfGoods.Counterparty             AS Counterparty,
	|	TableOfGoods.Contract                AS Contract,
	|	TableOfGoods.ProductsGroup        AS ProductsGroup,
	|	TableOfGoods.PriceKind                AS PriceKind,
	|	TableOfGoods.SubjectToExcise      AS SubjectToExcise,
	|	TableOfGoods.BusinessUnitProduction AS BusinessUnitProduction,
	|	TypesOfReserveReserves.Ref             AS InventoryOwnerAttribute
	|FROM
	|	TableOfProductsWithAnalytics AS TableOfGoods
	|		LEFT JOIN TypesOfReserveReserves AS TypesOfReserveReserves
	|		ON TableOfGoods.Organization = TypesOfReserveReserves.Organization
	|			AND TableOfGoods.InventoryType = TypesOfReserveReserves.InventoryType
	|			AND TableOfGoods.GoodsOwner = TypesOfReserveReserves.GoodsOwner
	|			AND TableOfGoods.Counterparty = TypesOfReserveReserves.Counterparty
	|			AND TableOfGoods.Terms = TypesOfReserveReserves.Terms
	|			AND TableOfGoods.Contract = TypesOfReserveReserves.Contract
	|			AND TableOfGoods.Currency = TypesOfReserveReserves.Currency
	|			AND TableOfGoods.ProductsGroup = TypesOfReserveReserves.ProductsGroup
	|			AND TableOfGoods.PriceKind = TypesOfReserveReserves.PriceKind
	|			AND TableOfGoods.VATTaxation = TypesOfReserveReserves.VATTaxation
	|			AND TableOfGoods.FinancialAccountingGroup = TypesOfReserveReserves.FinancialAccountingGroup
	|			AND TableOfGoods.SubjectToExcise = TypesOfReserveReserves.SubjectToExcise
	|			AND TableOfGoods.BusinessUnitProduction = TypesOfReserveReserves.BusinessUnitProduction
	|			AND (CASE
	|					WHEN TableOfGoods.CurViewOfStocks = VALUE(Catalog.InventoryKinds.EmptyRef)
	|						THEN NOT TypesOfReserveReserves.Obsolete1
	|					ELSE TypesOfReserveReserves.Ref = TableOfGoods.CurViewOfStocks
	|				END)
	|
	|ORDER BY
	|	FinancialAccountingGroup,
	|	ProductsGroup,
	|	InventoryType,
	|	TableOfGoods.ThisIsReusablePackage,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SelectionOfStockTypes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TypesOfReserveReserves";

	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Query.TempTablesManager = TempTablesManager;
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	KeyFields	=
	"Organization,
	|GoodsOwner,
	|VATTaxation,
	|FinancialAccountingGroup,
	|ProductsGroup,
	|InventoryType,
	|ThisIsReusablePackage,
	|SubjectToExcise,
	|BusinessUnitProduction,
	|Contract";
	
	RowKey	= New Structure(KeyFields);
	InventoryOwnerAttribute	= Undefined;
	
	While Selection.Next() Do
		
		If Selection.Organization <> RowKey.Organization
			Or Selection.GoodsOwner <> RowKey.GoodsOwner
			Or Selection.VATTaxation <> RowKey.VATTaxation
			Or Selection.FinancialAccountingGroup <> RowKey.FinancialAccountingGroup
			Or Selection.ProductsGroup <> RowKey.ProductsGroup
			Or Selection.InventoryType <> RowKey.InventoryType
			Or Selection.ThisIsReusablePackage <> RowKey.ThisIsReusablePackage
			Or Selection.SubjectToExcise <> RowKey.SubjectToExcise
			Or Selection.BusinessUnitProduction <> RowKey.BusinessUnitProduction
			Or Selection.Contract <> RowKey.Contract Then
			
			FillPropertyValues(RowKey, Selection);
			
			InventoryOwnerAttribute = Undefined;
			
		EndIf;
		
		If Not ValueIsFilled(InventoryOwnerAttribute) Then
			If ValueIsFilled(Selection.InventoryOwnerAttribute) Then
				InventoryOwnerAttribute = Selection.InventoryOwnerAttribute;
			Else
				If InfobaseUpdate.IsCallFromUpdateHandler("Deferred") Then
					Raise NStr("vi = 'Tạo các loại hàng tồn kho mới trong chế độ cập nhật bị trì hoãn đều bị cấm.';
								|ru = 'Создание новых видов запасов в режиме отложенного обновления запрещено.';
								|en = 'Cannot create new inventory owner attributes in deferred update mode.'; fa = 'Cannot create new inventory owner attributes in deferred update mode.';
								|it = 'È vietata la creazione di nuovi tipi di scorte in modalità di aggiornamento in sospeso.';
								|pl = 'Utworzenie nowych rodzajów zapasów w trybie odłożonej aktualizacji jest zabronione.';
								|tr = 'Ertelenmiş güncelleme modda yeni stok türleri oluşturmak yasak.'");
				EndIf;
				
				InventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(Selection.Organization,
																		Selection.BusinessOperation,
																		Selection);
			EndIf;
		EndIf;
		
		If TabularPartProducts <> Undefined Then
			TableRow = TabularPartProducts.Find(Selection.LineNumber, "LineNumber");
			TableRow[FieldName]= InventoryOwnerAttribute;
		Else
			DocumentInventoryView = InventoryOwnerAttribute;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the inventory types in the "inventory Types" tabular part of the document.
//
// Parameters:
//	DocumentObject - DocumentObject - The document, which are filled with stock types.
//	TempTablesManager - TempTablesManager - required temporary tables Tablatures, Tablerowiterator.
//	Cancel - Boolean - Indicates whether the document should be interrupted.
//	ParametersForFillingInventoryTypes - See InventoriesServer.ParametersForFillingInventoryTypes.
//	UpdatingInformationSecurity - Boolean - Indicates that the call was made from the metadata object update method.
//		
Procedure FillInInventoryTypesForOrganizationsProducts(DocumentObject,
													TempTablesManager,
													Cancel,
													ParametersForFillingInventoryTypes,
													UpdatingInformationSecurity = False) Export
	
	SetPrivilegedMode(True);
	
	If Not ParametersForFillingInventoryTypes.TableOfBalancesHasAlreadyBeenFormed
		And ParametersForFillingInventoryTypes.NameOfRemainderTable <> "CompanyGoods"
		And ParametersForFillingInventoryTypes.NameOfRemainderTable <> "GoodsTransferredBetweenOrganizations"
		And ParametersForFillingInventoryTypes.NameOfRemainderTable <> "AcceptedGoods" Then
		
		ExceptionText = NStr("vi = 'Chỉ có thể gọi ra thủ tục %1 với bảng số dư %2 hoặc %3';
							|ru = 'Процедуру %1 можно вызывать только с таблицей остатков %2 или %3';
							|en = 'The %1 procedure can be called only with the %2 balance table or with %3'; fa = 'The %1 procedure can be called only with the %2 balance table or with %3';
							|it = 'È possibile definire la procedura %1 solamente con la tabella dei saldi %2 o %3';
							|pl = 'Procedurę %1 można wywoływać tylko z tabelą ostatków %2 lub %3';
							|tr = '%1 prosedürü yalnızca %2 veya %3 bakiyesi tablosuyla çağrılabilir'");
		ExceptionText = StrTemplate(ExceptionText, "FillInInventoryTypesForOrganizationsProducts", "CompanyGoods", "GoodsTransferredBetweenOrganizations");
		Raise ExceptionText;
		
	EndIf;
	
	If Not ParametersForFillingInventoryTypes.AvailableTypesOfStocksHaveAlreadyBeenFormed Then
		TableName = ?(ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods,
						"TableTypesOfStocksByPeriod",
						"TableTypesOfStocks_");
		
		GenerateTTAvailableInventoryTypes(DocumentObject,
											TempTablesManager,
											ParametersForFillingInventoryTypes,
											TableName);
	EndIf;
	
	GenerateTTTableOfDetailsOfStockTypesByDefault(TempTablesManager, ParametersForFillingInventoryTypes);
	PreserveOriginalRegisteredRecordsOfGoodsAndReserves(DocumentObject.Ref, TempTablesManager);
	GenerateTTSelectionsOfBalancesForProductTable(TempTablesManager,
												True,
												ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods);
	
	CreatingStornoDocument				= ValueIsFilled(ParametersForFillingInventoryTypes.ReversedDocument)
											And Not HasRecordsInTemporaryTable(TempTablesManager,
																			"MovementOfOrganizationsProductsBeforeRecording");
	ToFormReservesOfReverseDocument	= CreatingStornoDocument;
	
	If CreatingStornoDocument Then
		DateOfDocumentBeingCancelled = Common.ObjectAttributeValue(
										ParametersForFillingInventoryTypes.ReversedDocument,
										"Date");
		
		If EndOfMonth(DateOfDocumentBeingCancelled) = EndOfMonth(DocumentObject.Date) Then
			SaveRegisteredRecordsOfReversedDocument(ParametersForFillingInventoryTypes.ReversedDocument,
													TempTablesManager,
													"CompanyGoods");
			
			ToFormReservesOfReverseDocument = False;
		EndIf;
	EndIf;
	
	If Not UpdatingInformationSecurity Then
		SetRegisterLock(DocumentObject, TempTablesManager);
	EndIf;
	
	ToFormVTGoodsOfOrganizationsChanges(DocumentObject,
											TempTablesManager,
											ParametersForFillingInventoryTypes);
	
	NameOfOrganizationSProductReservesTable = NameOfOrganizationSProductReservesTable();
	
	// If not re-launching the filling of inventory types
	If Not DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable)
		And (// and not launching from the fix assistant
			Not DocumentObject.AdditionalProperties.Property("RefillInventoryKinds")
			Or Not DocumentObject.AdditionalProperties.RefillInventoryKinds) Then
		
		FormTTStornoReserves(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
	EndIf;
	
	If ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods Then
		
		FillTypesOfStocksOfDifferentPeriods(DocumentObject,
											TempTablesManager,
											Cancel,
											ParametersForFillingInventoryTypes);
		
	Else
		
		GenerateTTTableOfBalances(ParametersForFillingInventoryTypes.NameOfRemainderTable,
										DocumentObject,
										TempTablesManager,
										ParametersForFillingInventoryTypes,
										True);
		
		FillInTypesOfReservesAccordingToTableOfBalancesFormTTNewReserves(DocumentObject,
																		TempTablesManager,
																		Cancel,
																		ParametersForFillingInventoryTypes);
		
	EndIf;
	
	If Cancel Then
		DocumentObject.AdditionalProperties.Insert("FailureToFillInventoryTypes");
		
		Return;
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert(
		"RecordReservesOfGoodsOfOrganizationsTogetherWithAll",
		Not ((CreatingStornoDocument
				And ToFormReservesOfReverseDocument)
			Or ParametersForFillingInventoryTypes.DocumentMakesBothArrivalAndExpenditure));
	
	TableReservesOfGoodsOfOrganizations = TableReservesOfGoodsOfOrganizations(DocumentObject,
																		TempTablesManager,
																		ParametersForFillingInventoryTypes,
																		True);
	
	DocumentObject.AdditionalProperties.Insert(NameOfOrganizationSProductReservesTable, TableReservesOfGoodsOfOrganizations);
	
	SetPrivilegedMode(False);
	
EndProcedure

// Fills in the inventory types in the "inventory Types" tabular part of the document.
//
// Parameters:
//	DocumentObject - DocumentObject - The document, which are filled with stock types.
//	TempTablesManager - TempTablesManager- required temporary tables Tablatures, Tablerowiterator.
//	Cancel - Boolean - Indicates whether the document should be interrupted.
//	ParametersForFillingInventoryTypes - Undefined, Structure - See InventoriesServer.ParametersForFillingInventoryTypes.
//
Procedure FillOutInventoryTypesForIntercampanyCommissionGoods(DocumentObject, TempTablesManager, Cancel, ParametersForFillingInventoryTypes) Export
	
	SetPrivilegedMode(True);
	
	If Not ParametersForFillingInventoryTypes.AvailableTypesOfStocksHaveAlreadyBeenFormed Then
		GenerateTTAvailableInventoryTypes(DocumentObject,
											TempTablesManager,
											ParametersForFillingInventoryTypes,
											"TableTypesOfStocks_");
	EndIf;
	
	GenerateTTTableOfDetailsOfStockTypesByDefault(TempTablesManager, ParametersForFillingInventoryTypes);
	
	GenerateTTSelectionsOfBalancesForProductTable(TempTablesManager, False);
	
	SetRegisterLock(DocumentObject, TempTablesManager);
	
	GenerateTTTableOfBalances("IntercampanyCommissionGoods",
									DocumentObject,
									TempTablesManager,
									ParametersForFillingInventoryTypes);
	
	FillInTypesOfStocksAccordingToTableOfBalancesOfCommissionGoodsIntercampany(DocumentObject,
																		TempTablesManager,
																		Cancel,
																		ParametersForFillingInventoryTypes);
	
	If Not Cancel Then
		ReplenishTypesOfStocksInReportsOnIntercampanyCommission(DocumentObject,
															TempTablesManager,
															Cancel,
															ParametersForFillingInventoryTypes);
	EndIf;
	
	SetPrivilegedMode(False);
	
	If Cancel Then
		DocumentObject.AdditionalProperties.Insert("FailureToFillInventoryTypes");
	EndIf;
	
EndProcedure

// Fills in the inventory types in the "inventory Types" tabular part of the document.
//
// Parameters:
//	DocumentObject - DocumentObject - The document, which are filled with stock types.
//	TempTablesManager - TempTablesManager- required temporary tables Tablatures, Tablerowiterator.
//	Cancel - Boolean - Indicates whether the document should be interrupted.
//	ParametersForFillingInventoryTypes - Undefined, Structure - See InventoriesServer.ParametersForFillingInventoryTypes.
//
Procedure FillOutTypesOfStocksOnBalancesForRegistration(DocumentObject,
													TempTablesManager,
													Cancel,
													ParametersForFillingInventoryTypes) Export
	
	SetPrivilegedMode(True);
	
	If ParametersForFillingInventoryTypes.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = Undefined Then
		ExceptionText = NStr("vi = 'Trong mã gọi ra chưa đặt giá trị tham số %1.';
							|ru = 'В вызывающем коде не задано значение параметра %1.';
							|en = 'Value of the %1 parameter is not specified in the called code.'; fa = 'Value of the %1 parameter is not specified in the called code.';
							|it = 'Nella definizione del codice non è indicato il valore del parametro %1.';
							|pl = 'W kodzie wywołującym nie jest zadana wartość parametru %1.';
							|tr = 'Çağırılan kodda, %1 parametresi için bir değer belirtilmedi.'");
		ExceptionText = StrTemplate(ExceptionText, "WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault");
		
		Raise ExceptionText;
	EndIf;
	
	If ParametersForFillingInventoryTypes.NameOfRemainderTable = "TableTypesOfStocks_"
		And Not ParametersForFillingInventoryTypes.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault Then
		
		ExceptionText = NStr("vi = '%1 cần thiết để điền dạng vật tư theo mặc định, do đó %2 phải được đặt là TRUE.';
							|ru = '%1 нужна для заполнения видов запасов по умолчанию, поэтому %2 должен быть выстален в ИСТИНА.';
							|en = '%1 is needed to fill in the inventory owner attributes by default, therefore, %2 should be set to TRUE.'; fa = '%1 is needed to fill in the inventory owner attributes by default, therefore, %2 should be set to TRUE.';
							|it = '%1 serve soltanto per la compilazione dei tipi di scorte con impostazioni predefinite, pertanto %2 deve essere impostato a TRUE.';
							|pl = '%1 jest potrzebna do wypełnienia rodzajów zapasów domyślnie, dlatego %2 powinien być ustawiony w TRUE.';
							|tr = 'Varsayılan stok türlerini doldurmak için %1 gereklidir, bu nedenle %2 1 olarak ayarlanmalıdır.'");
		ExceptionText = StrTemplate(ExceptionText, "TableTypesOfStocks_", "WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault");
		
		Raise ExceptionText;
	EndIf;
	
	TemporaryTableNames = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	
	If Not ParametersForFillingInventoryTypes.AvailableTypesOfStocksHaveAlreadyBeenFormed Then
		GenerateTTAvailableInventoryTypes(DocumentObject,
											TempTablesManager,
											ParametersForFillingInventoryTypes,
											"TableTypesOfStocks_");
	EndIf;
	
	GenerateTTTableOfDetailsOfStockTypesByDefault(TempTablesManager, ParametersForFillingInventoryTypes);
	
	GenerateTTSelectionsOfBalancesForProductTable(TempTablesManager, False);
	
	SetRegisterLock(DocumentObject, TempTablesManager);
	
	GenerateTTTableOfBalances(ParametersForFillingInventoryTypes.NameOfRemainderTable,
									DocumentObject,
									TempTablesManager,
									ParametersForFillingInventoryTypes);
	
	FillTypesOfStocksOnTableOfBalances(DocumentObject, 
											TempTablesManager, 
											Cancel, 
											ParametersForFillingInventoryTypes);
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager, ,TemporaryTableNames);
	
	SetPrivilegedMode(False);
	
	If Cancel Then
		DocumentObject.AdditionalProperties.Insert("FailureToFillInventoryTypes");
	EndIf;
	
EndProcedure

// When carrying out the document, the fact of consumption of "foreign" types of stocks is determined and
// movements are formed for the PH Reserves of goods of organizations.
//
// Parameters:
//	DocumentObject - DocumentObject - The document, which are filled with stock types.
//	TempTablesManager - TempTablesManager - Manager of temporary tables used for creating reserves.
//	Cancel - Boolean - Indicates whether the document should be interrupted.
//	ParametersForFillingInventoryTypes - Undefined, Structure - See InventoriesServer.ParametersForFillingInventoryTypes.
//
Procedure CreateReservesForGoodsOfOrganizations(DocumentObject,
													TempTablesManager,
													Cancel,
													ParametersForFillingInventoryTypes) Export
	
	If InfobaseUpdate.IsCallFromUpdateHandler() Then
		Return;
	EndIf;
	
	AdditionalProperties = DocumentObject.AdditionalProperties;
	
	If AdditionalProperties.Property("RecordReservesOfGoodsOfOrganizationsTogetherWithAll")
		And AdditionalProperties.RecordReservesOfGoodsOfOrganizationsTogetherWithAll Then
		
		Return;
		
	EndIf;
	
	If AdditionalProperties.ItIsNecessaryToControlRemnantsOfGoods
		Or AdditionalProperties.ItIsNecessaryToFormStornoOnReservesOfGoods Then
		
		// We call the reserves one time
		If AdditionalProperties.ItIsNecessaryToFormStornoOnReservesOfGoods
			And Not DocumentObject.AdditionalProperties.Property("GeneratedByTTReverse") Then
			
			FormTTStornoReserves(DocumentObject, TempTablesManager,  ParametersForFillingInventoryTypes);
			
			DocumentObject.AdditionalProperties.Insert("GeneratedByTTReverse", True);
			
		EndIf;
		
		If AdditionalProperties.ItIsNecessaryToControlRemnantsOfGoods Then
			
			CreateReservesForOrganizationsForControl(DocumentObject,
														TempTablesManager,
														Cancel,
														ParametersForFillingInventoryTypes);
			
		EndIf;
		
		If Cancel Then
			AdditionalProperties.Insert("FailureToFillInventoryTypes");
			
			Return;
		EndIf;
		
	EndIf;
	
	NameOfOrganizationSProductReservesTable	= NameOfOrganizationSProductReservesTable();
	TableReservesOfGoodsOfOrganizations	= TableReservesOfGoodsOfOrganizations(DocumentObject,
																			TempTablesManager,
																			ParametersForFillingInventoryTypes,
																			False);
	
	// If the document makes both the arrival and the expense, then you need to write the register only when
	// the table has already been formed on the second side of the movements.
	If Not ParametersForFillingInventoryTypes.DocumentMakesBothArrivalAndExpenditure
		Or DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable) Then
		
		SetReservesOfGoodsOfOrganizations = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
		SetReservesOfGoodsOfOrganizations.Filter.Recorder.Set(DocumentObject.Ref);
		
		DocumentsPosting.SetAdditionalRegisterProperties(SetReservesOfGoodsOfOrganizations,
															DocumentObject,
															TempTablesManager,
															True);
		
		SetReservesOfGoodsOfOrganizations.Load(TableReservesOfGoodsOfOrganizations);
		SetReservesOfGoodsOfOrganizations.Write();
		
		If DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable) Then
			DocumentObject.AdditionalProperties[NameOfOrganizationSProductReservesTable].Clear();
		EndIf;
		
	Else
		
		DocumentObject.AdditionalProperties.Insert(NameOfOrganizationSProductReservesTable, TableReservesOfGoodsOfOrganizations);
		DocumentObject.AdditionalProperties.Insert("RecordReservesOfGoodsOfOrganizationsTogetherWithAll", False);
		
	EndIf;
	
EndProcedure

// When conducting a document, a LIST of available types of Reserves is formed for use in other control mechanisms, and the necessary locks are set.
// 
//
// Parameters:
//	DocumentObject - DocumentObject - The document, which are filled with stock types.
//	TempTablesManager - TempTablesManager - Manager of temporary tables that are used for preparing
//														register entry data.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//	FillParameters - Undefined, Structure - See InventoriesServer.ParametersForFillingInventoryTypes.
//
Procedure PrepareRecordOfBusinessProducts(DocumentObject,
												TempTablesManager,
												WriteMode,
												FillParameters = Undefined) Export
	
	AdditionalProperties = DocumentObject.AdditionalProperties;
	
	If FillParameters = Undefined Then
		FillParameters = ParametersForFillingInventoryTypes();
		FillParameters.SelectionOfStockTypes_.Organization = DocumentObject[FillParameters.CompanyFieldName1];
	EndIf;
	
	If AdditionalProperties.Property("RecordReservesOfGoodsOfOrganizationsTogetherWithAll")
		And AdditionalProperties.RecordReservesOfGoodsOfOrganizationsTogetherWithAll Then
		
		Return;
		
	EndIf;
	
	PreserveOriginalRegisteredRecordsOfGoodsAndReserves(DocumentObject.Ref, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	CompanyGoods.Period		AS Period,
	|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoods.Organization	AS Organization,
	|	CompanyGoods.InventoryOwnerAttribute	AS InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber		AS CCDNumber,
	|	CompanyGoods.ReversingEntry		AS ReversingEntry,
	|	CASE
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CompanyGoods.Count
	|		ELSE -CompanyGoods.Count
	|	END							AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(CompanyGoods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|		ELSE -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|	END AS QuantityByGBRN
	|INTO CompanyGoods
	|FROM
	|	&CompanyGoods AS CompanyGoods";
	
	CompanyGoods = ?(WriteMode = DocumentWriteMode.Posting,
							DocumentObject.RegisterRecords.CompanyGoods,
							AccumulationRegisters.CompanyGoods.CreateRecordSet().UnloadColumns());
	
	Query.SetParameter("CompanyGoods", CompanyGoods);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Execute();
	
	ToFormVTGoodsOfOrganizationsChanges(DocumentObject, TempTablesManager, FillParameters);
	
	If Not FillParameters.AvailableTypesOfStocksHaveAlreadyBeenFormed Then
		
		Companies = OrganizationsForBalanceControl(TempTablesManager);
		
		If ValueIsFilled(FillParameters.SelectionOfStockTypes_.Organization) Then
			Companies.Add(FillParameters.SelectionOfStockTypes_.Organization);
			
			Companies = CommonClientServer.CollapseArray(Companies);
		EndIf;
		
		FillParameters.SelectionOfStockTypes_.Organization = Companies;
		
		GenerateTTAvailableInventoryTypes(DocumentObject,
											TempTablesManager,
											FillParameters,
											"MovementOfOrganizationsProductsBeforeRecording");
		
	EndIf;
	
	SetAdditionalPropertiesControlResiduesAndFormStorno(DocumentObject,
																FillParameters,
																TempTablesManager);
	
	If AdditionalProperties.ItIsNecessaryToControlRemnantsOfGoods
		Or AdditionalProperties.ItIsNecessaryToFormStornoOnReservesOfGoods Then
		
		GenerateTTSelectionsOfBalancesAccordingToTableOfChanges(TempTablesManager);
		SetRegisterLock(DocumentObject, TempTablesManager);
		
	EndIf;
	
EndProcedure

// Saves in the temporary table Manager the original movements in the goods register of organizations.
//
// Parameters:
//	DocumentRef - DocumentRef - link to the document.
//	TempTablesManager - TempTablesManager - Temporary table Manager to place the table in.
//	CreateEmptyTables - Boolean - True, indicates that you need to create empty tables in the temporary table Manager.
//
Procedure PreserveOriginalRegisteredRecordsOfGoodsAndReserves(DocumentRef,
													TempTablesManager,
													CreateEmptyTables = False) Export
	
	Query = New Query;
	QueryTexts = New Array;
	
	If TempTablesManager.Tables.Find("MovementOfOrganizationsProductsBeforeRecording") = Undefined Then
		
		If CreateEmptyTables Then
			
			QueryText =
			"SELECT
			|	Goods.Period,
			|	Goods.Recorder,
			|	Goods.LineNumber,
			|	Goods.Active,
			|	Goods.RecordType,
			|	Goods.ItemsLocationAttributes,
			|	Goods.Organization,
			|	Goods.InventoryOwnerAttribute,
			|	Goods.CCDNumber,
			|	Goods.Count,
			|	CAST(Goods.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
			|	Goods.BusinessOperation,
			|	Goods.VATTaxation,
			|	Goods.CorItemsLocationAttributes,
			|	Goods.CorInventoryOwnerAttribute,
			|	Goods.ShipmentCompany,
			|	Goods.DocumentSalesOfGoodsAndServices,
			|	Goods.ExpenseItem,
			|	Goods.DimensionOfExpenses,
			|	Goods.AssetsLiabilitiesDimension,
			|	Goods.Products,
			|	Goods.Characteristic,
			|	Goods.LotCalculation,
			|	Goods.Primary,
			|	Goods.ReversingEntry,
			|	Goods.ItemsType
			|INTO MovementOfOrganizationsProductsBeforeRecording
			|FROM
			|	&CompanyGoods AS Goods";
			
			CompanyGoods = AccumulationRegisters.CompanyGoods.CreateRecordSet().UnloadColumns();
			CompanyGoods.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
			
			Query.SetParameter("CompanyGoods", CompanyGoods);
			
		Else
			
			QueryText =
			"SELECT
			|	Goods.Period,
			|	Goods.Recorder,
			|	Goods.LineNumber,
			|	Goods.Active,
			|	Goods.RecordType,
			|	Goods.ItemsLocationAttributes,
			|	Goods.Organization,
			|	Goods.InventoryOwnerAttribute,
			|	Goods.CCDNumber,
			|	Goods.Count,
			|	CASE
			|		WHEN &UseTraceableImportedGoodsAccounting
			|				AND BEGINOFPERIOD(Goods.Period, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
			|			THEN CAST(Goods.QuantityByGBRN AS NUMBER(23, 11))
			|		ELSE 0
			|	END AS QuantityByGBRN,
			|	Goods.BusinessOperation,
			|	Goods.VATTaxation,
			|	Goods.CorItemsLocationAttributes,
			|	Goods.CorInventoryOwnerAttribute,
			|	Goods.ShipmentCompany,
			|	Goods.DocumentSalesOfGoodsAndServices,
			|	Goods.ExpenseItem,
			|	Goods.DimensionOfExpenses,
			|	Goods.AssetsLiabilitiesDimension,
			|	Goods.Products,
			|	Goods.Characteristic,
			|	Goods.LotCalculation,
			|	Goods.Primary,
			|	Goods.ReversingEntry AS ReversingEntry,
			|	CatalogProducts.ItemsType AS ItemsType
			|INTO MovementOfOrganizationsProductsBeforeRecording
			|FROM
			|	AccumulationRegister.CompanyGoods AS Goods
			|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
			|		ON (InventoryLocationAttributeKeys.Ref = Goods.ItemsLocationAttributes)
			|		LEFT JOIN Catalog.Products AS CatalogProducts
			|		ON (CatalogProducts.Ref = InventoryLocationAttributeKeys.Products)
			|WHERE
			|	Goods.Recorder = &Ref";
			
		EndIf;
		
		QueryTexts.Add(QueryText);
		
	EndIf;
	
	If TempTablesManager.Tables.Find("RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording") = Undefined Then
		
		If CreateEmptyTables Then
			
			QueryText =
			"SELECT
			|	Reserves.Period,
			|	Reserves.Recorder,
			|	Reserves.LineNumber,
			|	Reserves.Active,
			|	Reserves.RecordType,
			|	Reserves.ItemsLocationAttributes,
			|	Reserves.Organization,
			|	Reserves.InventoryOwnerAttribute,
			|	Reserves.CCDNumber,
			|	Reserves.Count,
			|	CAST(Reserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
			|	Reserves.CorCompany,
			|	Reserves.CorInventoryOwnerAttribute
			|INTO RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording
			|FROM
			|	&CompanySafeStock AS Reserves
			|WHERE
			|	Reserves.Recorder = &Ref";
			
			CompanySafeStock = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
			
			Query.SetParameter("CompanySafeStock", CompanySafeStock);
			
		Else
			
			QueryText =
			"SELECT
			|	Reserves.Period,
			|	Reserves.Recorder,
			|	Reserves.LineNumber,
			|	Reserves.Active,
			|	Reserves.RecordType,
			|	Reserves.ItemsLocationAttributes,
			|	Reserves.Organization,
			|	Reserves.InventoryOwnerAttribute,
			|	Reserves.CCDNumber,
			|	Reserves.Count,
			|	CASE
			|		WHEN &UseTraceableImportedGoodsAccounting
			|				AND BEGINOFPERIOD(Reserves.Period, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
			|			THEN CAST(Reserves.QuantityByGBRN AS NUMBER(23, 11))
			|		ELSE 0
			|	END AS QuantityByGBRN,
			|	Reserves.CorCompany,
			|	Reserves.CorInventoryOwnerAttribute
			|INTO RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording
			|FROM
			|	AccumulationRegister.CompanySafeStock AS Reserves
			|WHERE
			|	Reserves.Recorder = &Ref";
			
		EndIf;
		
		QueryTexts.Add(QueryText);
		
	EndIf;
	
	If QueryTexts.Count() > 0 Then
		
		Query.TempTablesManager = TempTablesManager;
		
		Separator = "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		Query.Text = StrConcat(QueryTexts, Separator);
		Query.SetParameter("Ref", DocumentRef);
		
		AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
		
		Query.Execute();
		
	EndIf;
	
EndProcedure

// The method generates the available types of Reserves based on the selections. Used when building a table of balances.
// Exported for the document return to the destination.
//
// Parameters:
//	DocumentObject - DocumentObject - A document that will be used to fill in inventory types.
//	TempTablesManager - TempTablesManager - Temporary table Manager.
//														For the algorithm to work, you need a table of products.
//														A temporary table of available inventory Views is formed during the algorithm operation and placed in the current Manager.
//	ParametersForFillingInventoryTypes - See ParametersForFillingInventoryTypes.
//	TTSourceNameOfCurStockTypes - String - name of the table that stores data about the current inventory types of the document.
//
Procedure GenerateTTAvailableInventoryTypes(DocumentObject,
											TempTablesManager,
											ParametersForFillingInventoryTypes,
											TTSourceNameOfCurStockTypes) Export
	
	ParametersForFillingInventoryTypes.AvailableTypesOfStocksHaveAlreadyBeenFormed = True;
	
	If TempTablesManager.Tables.Find("AvailableTypesOfStocks") <> Undefined Then
		Return;
	EndIf;
	
	Period				= ?(ParametersForFillingInventoryTypes.PeriodOfFoundationDocument = Undefined,
							DocumentObject.Date,
							ParametersForFillingInventoryTypes.PeriodOfFoundationDocument);
	SelectionOfStockTypes_	= ParametersForFillingInventoryTypes.SelectionOfStockTypes_;
	
	VATAccountingERP.GenerateTTSettingsForAccountingOfVATCounterparties(TempTablesManager, Period);
	
	If TempTablesManager.Tables.Find("TypesOfDocumentStocks") <> Undefined Then
		QueryText =
		"DROP TypesOfDocumentStocks
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
	Else
		QueryText = "";
	EndIf;
	
	QueryText = QueryText +
	"SELECT DISTINCT
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TypesOfDocumentStocks
	|FROM
	|	&TTSourceNameOfCurStockTypes AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Types of stocks of your own organization
	|SELECT DISTINCT
	|	InventoryKinds.Organization	AS ForCompany,
	|	InventoryKinds.Ref		AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN VATAccountingSettings.Consignor IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END					AS SelectionAccordingToCommitteeSVATRate,
	|	CASE
	|		WHEN VATAccountingSettings.Consignor IS NULL
	|			THEN UNDEFINED
	|		ELSE VATAccountingSettings.VATRate
	|	END					AS CommitteeSVATRate
	|INTO AvailableTypesOfStocks
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.ObsoleteInventoryOwnerAttributesWithBalance AS ObsoleteInventoryOwnerAttributesWithBalance
	|		ON InventoryKinds.Ref = ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute
	|		
	|		LEFT JOIN TypesOfDocumentStocks AS TypesOfDocumentStocks
	|		ON InventoryKinds.Ref = TypesOfDocumentStocks.InventoryOwnerAttribute
	|		
	|		LEFT JOIN TTSettingsForVATAccountingOfCounterparties AS VATAccountingSettings
	|		ON InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			AND InventoryKinds.Counterparty = VATAccountingSettings.Consignor
	|			AND &SelectCommissionInventoryForCommitteeSTaxation
	|
	|WHERE
	|	InventoryKinds.Organization IN(
	|		&Organization,
	|		&MaterialProviderCompany,
	|		UNDEFINED)
	|	AND (&ForAllTypesOfStocks_
	|			OR InventoryKinds.InventoryType IN (&InventoryType))
	|	AND (&ForAllVATTaxation
	|			OR (InventoryKinds.VATTaxation IN (&VATTaxation)
	|				AND NOT InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods))
	|			OR InventoryKinds.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			OR InventoryKinds.VATTaxation = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			OR InventoryKinds.InventoryType IN(VALUE(Enum.InventoryTypes.OwnGoods),
	|										VALUE(Enum.InventoryTypes.Work_5)) // own item or work can be sold under any taxation.
	|			OR (InventoryKinds.VATTaxation IN (&VATTaxation)
	|				AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND (VATAccountingSettings.Consignor IS NULL
	|					OR (ISNULL(VATAccountingSettings.BasicTaxation, UNDEFINED) IN (&TaxationWithVAT)
	|						AND VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) IN (&VATTaxation))
	|					OR (ISNULL(VATAccountingSettings.BasicTaxation, UNDEFINED) IN (&TaxationWithoutVAT_)
	|						AND VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) IN (&VATTaxation))
	|					)
	|				)
	|		)
	|	AND (&ForAllProductOwners
	|			OR InventoryKinds.GoodsOwner IN (&GoodsOwner))
	|	AND (&ByAllAgreements
	|			OR InventoryKinds.Terms IN (&Terms))
	|	AND (&ForAllCurrencies
	|			OR InventoryKinds.Currency IN (&Currency))
	|	AND (&ForAllCounterparties
	|			OR InventoryKinds.Counterparty IN (&Counterparty))
	|	AND (&ByAllContracts
	|			OR InventoryKinds.Contract IN (&Contract))
	|	AND (&ForAllProductGroups
	|			OR InventoryKinds.ProductsGroup IN (&ProductsGroup))
	|	AND (&ForAllTypesOfPrices
	|			OR InventoryKinds.PriceKind IN (&PriceKind))
	|	AND (&ForAllExciseTaxes
	|			OR InventoryKinds.SubjectToExcise IN (&SubjectToExcise))
	|	AND (&ForAllProductionUnits
	|			OR (NOT InventoryKinds.SubjectToExcise
	|				OR (InventoryKinds.SubjectToExcise
	|					AND InventoryKinds.BusinessUnitProduction IN (&BusinessUnitProduction)
	|					)
	|				)
	|		)
	|	AND (NOT InventoryKinds.Obsolete1
	|				AND NOT InventoryKinds.IsDuplicate
	|			OR NOT ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute IS NULL
	|			OR NOT TypesOfDocumentStocks.InventoryOwnerAttribute IS NULL
	|			OR NOT &ExcludeObsoleteOnes)
	|
	|UNION
	|
	// Types of reserves by intercampany
	|SELECT DISTINCT
	|	InventoryKinds.Organization,
	|	InventoryKinds.Ref,
	|	CASE
	|		WHEN Setting.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|				AND NOT VATAccountingSettingsOrganizations.Organization IS NULL
	|			THEN TRUE
	|		WHEN Setting.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND NOT CounterpartyVATAccountingSettings.Consignor IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN Setting.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			THEN ISNULL(VATAccountingSettingsOrganizations.VATRate, UNDEFINED)
	|		WHEN Setting.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN ISNULL(CounterpartyVATAccountingSettings.VATRate, UNDEFINED)
	|		ELSE UNDEFINED
	|	END
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|		INNER JOIN InformationRegister.CustomizeCustomerInvoiceIntercompany AS Setting
	|		ON InventoryKinds.Organization = Setting.CompanyOwner
	|			AND InventoryKinds.InventoryType = Setting.InventoryType
	|		
	|		LEFT JOIN InformationRegister.ObsoleteInventoryOwnerAttributesWithBalance AS ObsoleteInventoryOwnerAttributesWithBalance
	|		ON InventoryKinds.Ref = ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute
	|		
	|		LEFT JOIN TypesOfDocumentStocks AS TypesOfDocumentStocks
	|		ON InventoryKinds.Ref = TypesOfDocumentStocks.InventoryOwnerAttribute
	|		
	|		LEFT JOIN TTVATAccountingSettingsForOrganizations AS VATAccountingSettingsOrganizations
	|		ON InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND InventoryKinds.Organization = VATAccountingSettingsOrganizations.Organization
	|			AND &SelectCommissionInventoryForCommitteeSTaxation
	|			AND Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|		
	|		LEFT JOIN TTSettingsForVATAccountingOfCounterparties AS CounterpartyVATAccountingSettings
	|		ON InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			AND InventoryKinds.Counterparty = CounterpartyVATAccountingSettings.Consignor
	|			AND &SelectCommissionInventoryForCommitteeSTaxation
	|			AND Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|
	|WHERE
	|	&SelectTypesOfStocksForIntercampany
	|	AND NOT InventoryKinds.Organization IN (&IntercampanyExcept)
	|	AND Setting.GoodsTransferMethod <> VALUE(Enum.GoodsTransferMethods.NotTransferred)
	|	AND Setting.CompanyCustomer IN(&Organization)
	|	AND (&ForAllTypesOfStocks_
	|			OR Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale)
	|				AND VALUE(Enum.InventoryTypes.OwnGoods) IN (&InventoryType)
	|			OR Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|				AND VALUE(Enum.InventoryTypes.ConsignedGoods) IN (&InventoryType))
	|	AND (&ForAllVATTaxation
	|			OR Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale)
	// With the commission, we control the taxation of the owner organization.
	|			OR Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|				AND Setting.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|				AND ((Setting.CompanyOwner IN (&OrganizationsWithoutVAT)
	|						AND VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) IN(&VATTaxation))
	|					OR (NOT Setting.CompanyOwner IN (&OrganizationsWithoutVAT)
	|						AND VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) IN(&VATTaxation)))
	// At the sub-commission, we control the taxation of the committee.
	|			OR Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|				AND Setting.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND InventoryKinds.VATTaxation IN (&VATTaxation)
	|				AND (CounterpartyVATAccountingSettings.Consignor IS NULL
	|					OR (ISNULL(CounterpartyVATAccountingSettings.BasicTaxation, UNDEFINED) IN (&TaxationWithVAT)
	|						AND VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) IN (&VATTaxation))
	|					OR (ISNULL(CounterpartyVATAccountingSettings.BasicTaxation, UNDEFINED) IN (&TaxationWithoutVAT_)
	|						AND VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) IN(&VATTaxation))
	|					)
	|		)
	|	AND NOT InventoryKinds.SaleOfAnotherCompanyInventory
	|	AND (NOT InventoryKinds.SubjectToExcise
	|			OR Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale))
	|	AND (NOT InventoryKinds.Obsolete1
	|				AND NOT InventoryKinds.IsDuplicate
	|			OR NOT ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute IS NULL
	|			OR NOT TypesOfDocumentStocks.InventoryOwnerAttribute IS NULL
	|			OR NOT &ExcludeObsoleteOnes)
	|
	|INDEX BY
	|	InventoryOwnerAttribute
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTVATAccountingSettingsForOrganizations
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTSettingsForVATAccountingOfCounterparties";
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If IsBlankString(TTSourceNameOfCurStockTypes) Then
		EmptyTableOfStockTypes = New ValueTable;
		EmptyTableOfStockTypes.Columns.Add("InventoryOwnerAttribute", New TypeDescription("CatalogRef.InventoryKinds"));
		
		Query.SetParameter("TTSourceNameOfCurStockTypes", EmptyTableOfStockTypes);
	Else
		QueryText = StrReplace(QueryText, "&TTSourceNameOfCurStockTypes", TTSourceNameOfCurStockTypes);
	EndIf;
	
	Query.Text = QueryText;
	
	Query.SetParameter("Date", DocumentObject.Date);
	
	If ValueIsFilled(SelectionOfStockTypes_.Organization) Then
		Organization = SelectionOfStockTypes_.Organization;
	Else
		Organization = DocumentOrganization(DocumentObject, ParametersForFillingInventoryTypes);
	EndIf;
	
	Query.SetParameter("Organization", Organization);
	If ValueIsFilled(SelectionOfStockTypes_.MaterialProviderCompany) Then
		Query.SetParameter("MaterialProviderCompany", SelectionOfStockTypes_.MaterialProviderCompany);
	Else
		Query.SetParameter("MaterialProviderCompany", Undefined);
	EndIf;
	ControlVATTaxation	= ControlVATTaxation(ParametersForFillingInventoryTypes);
	SelectTypesOfStocksForIntercampany	= GetFunctionalOption("UseCustomerInvoiceIntercompany")
											And ParametersForFillingInventoryTypes.SelectTypesOfStocksForIntercampany;
	IntercampanyExcept					= ?(SelectTypesOfStocksForIntercampany,
											ParametersForFillingInventoryTypes.WhenSelectingByIntercampanyExcludeOrganizations,
											New Array);
	
	If ControlVATTaxation
		And SelectTypesOfStocksForIntercampany Then
		
		OrganizationsWithoutVAT = VATAccountingERP.OrganizationsWithoutVAT(Period);
		
	Else
		OrganizationsWithoutVAT = New Array;
	EndIf;
	
	VATAccountingERP.CreateTTSettingsForVATAccountingForOrganizations(TempTablesManager, Period, OrganizationsWithoutVAT);
	
	Query.SetParameter("SelectTypesOfStocksForIntercampany", SelectTypesOfStocksForIntercampany);
	Query.SetParameter("IntercampanyExcept", IntercampanyExcept);
	
	Query.SetParameter("InventoryType", SelectionOfStockTypes_.InventoryType);
	Query.SetParameter("ForAllTypesOfStocks_", Not ValueIsFilled(SelectionOfStockTypes_.InventoryType));
	
	If ControlVATTaxation Then
		VATTaxation = ?(Enums.VATTaxationTypes.TypesWithVAT().Find(SelectionOfStockTypes_.VATTaxation) <> Undefined,
								Enums.VATTaxationTypes.SaleIsSubjectToVAT,
								Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		
		Query.SetParameter("VATTaxation", VATTaxation);
		Query.SetParameter("ForAllVATTaxation", False);
	Else
		Query.SetParameter("VATTaxation", Enums.VATTaxationTypes.EmptyRef());
		Query.SetParameter("ForAllVATTaxation", True);
	EndIf;
	
	Query.SetParameter("OrganizationsWithoutVAT", OrganizationsWithoutVAT);
	
	Query.SetParameter("GoodsOwner", SelectionOfStockTypes_.GoodsOwner);
	Query.SetParameter("ForAllProductOwners", Not ValueIsFilled(SelectionOfStockTypes_.GoodsOwner));
	
	Query.SetParameter("Terms", SelectionOfStockTypes_.Terms);
	Query.SetParameter("ByAllAgreements", Not ValueIsFilled(SelectionOfStockTypes_.Terms));
	
	Query.SetParameter("Currency", SelectionOfStockTypes_.Currency);
	Query.SetParameter("ForAllCurrencies", Not ValueIsFilled(SelectionOfStockTypes_.Currency));
	
	Query.SetParameter("Counterparty", SelectionOfStockTypes_.Counterparty);
	Query.SetParameter("ForAllCounterparties", Not ValueIsFilled(SelectionOfStockTypes_.Counterparty));
	
	Query.SetParameter("Contract", SelectionOfStockTypes_.Contract);
	Query.SetParameter("ByAllContracts", Not ValueIsFilled(SelectionOfStockTypes_.Contract));
	
	Query.SetParameter("ProductsGroup", SelectionOfStockTypes_.ProductsGroup);
	Query.SetParameter("ForAllProductGroups", Not ValueIsFilled(SelectionOfStockTypes_.ProductsGroup));
	
	Query.SetParameter("PriceKind", SelectionOfStockTypes_.PriceKind);
	Query.SetParameter("ForAllTypesOfPrices", Not ValueIsFilled(SelectionOfStockTypes_.PriceKind));
	Query.SetParameter("SubjectToExcise", SelectionOfStockTypes_.SubjectToExcise);
	Query.SetParameter("ForAllExciseTaxes", Not ValueIsFilled(SelectionOfStockTypes_.SubjectToExcise));
	
	Query.SetParameter("BusinessUnitProduction", SelectionOfStockTypes_.BusinessUnitProduction);
	Query.SetParameter("ForAllProductionUnits", Not ValueIsFilled(SelectionOfStockTypes_.BusinessUnitProduction));
	Query.SetParameter("TaxationWithVAT",	Enums.VATTaxationTypes.TypesWithVAT());
	Query.SetParameter("TaxationWithoutVAT_",	Enums.VATTaxationTypes.TypesWithoutVAT());
	
	Query.SetParameter("SelectCommissionInventoryForCommitteeSTaxation",
								ParametersForFillingInventoryTypes.SelectCommissionInventoryForCommitteeSTaxation);
	
	Query.SetParameter("ExcludeObsoleteOnes", ParametersForFillingInventoryTypes.NameOfRemainderTable = "CompanyGoods");
	
	Query.Execute();
	
EndProcedure

// Returns a typed table of values, the rows of which describe the values of the details of the types of stocks,
// formed according to the document data.
//
// Parameters:
//	Query - Query - request for document data
//
// Returns:
//	See EmptyTableOfDetailsOfStockTypesByDefault
//
Function TableOfDetailsOfInventoryTypesByDefaultRequest(Query) Export
	
	Selection		= Query.Execute().Select();
	Result	= EmptyTableOfDetailsOfStockTypesByDefault();
	
	While Selection.Next() Do
		FillPropertyValues(Result.Add(), Selection);
	EndDo;
	
	Return Result;
	
EndFunction

// Supplements the available inventory types of items used in the Inventory owner attribute selection parameters with the passed value.
//
// Parameters:
//	SelectionOfStockTypes_ - See Catalogs.InventoryKinds.StockTypeSelectionParameters.
//	SelectionData_ - EnumRef.InventoryTypes, Array of EnumRef.InventoryTypes - new available item inventory types.
//
Procedure ToSupplementSelectionOfInventoryOwnerAttributesByTypeOfInventory(SelectionOfStockTypes_, SelectionData_) Export
	
	AvailableStockTypes = New Array;
	
	If TypeOf(SelectionOfStockTypes_.InventoryType) = Type("Array") Then
		CommonClientServer.SupplementArray(AvailableStockTypes, SelectionOfStockTypes_.InventoryType);
	Else
		AvailableStockTypes.Add(SelectionOfStockTypes_.InventoryType);
	EndIf;
	
	If TypeOf(SelectionData_) = Type("Array") Then
		CommonClientServer.SupplementArray(AvailableStockTypes, SelectionData_);
	Else
		AvailableStockTypes.Add(SelectionData_);
	EndIf;
	
	SelectionOfStockTypes_.InventoryType = CommonClientServer.CollapseArray(AvailableStockTypes);
	
EndProcedure

#EndRegion

#Region ProceduresForRoutineTasks

// Runs a roll-up of the inventory records of the "organization's product Reserves" register.
// As a result, extra register entries are deleted.
Procedure PerformConvolutionOfReservesOfGoodsOfOrganizations() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.CompanySafeStockRollup);
	AccumulationRegisters.CompanySafeStock.CollapseRegisterReservesOfGoodsOfOrganizations();
	
EndProcedure

#EndRegion

#Region UserInterface

// We set the conditional design for the division, if the types of inventory by division are used.
//
// Parameters:
// 		Form - ClientApplicationForm - Contains this form 
// 		NameOfUnitInputField_ - String - Name of the form element containing the division,
//												if it differs from "Division".
// 		PathToSelectionField - String - The full path to the "Division" attribute,
//									if it differs from " Object.Unit".
//
Procedure EstablishConditionalAppearanceOfDivisionForTypesOfStocks(Form,
																	NameOfUnitInputField_ = "Department",
																	PathToSelectionField = "Object.Department") Export
	
	If Not GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		Return;
	EndIf;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfUnitInputField_].Name);
	
	FormItems[NameOfUnitInputField_].AutoMarkIncomplete = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

// Parameters for editing data in the table part of document inventory types.
//
// Returns:
//	Structure - parameters for editing the tabular part of the inventory types of the document:
//		* InventoryOwnerAttributesAreSpecifiedManually - Boolean - indicates whether the inventory types are specified in the document.
//		* DocumentItemModified - Boolean - indicates that the document form has been modified after making changes to the
//											table part of inventory types.
//		* PriceIncludesVAT - Boolean - indicates that VAT is included in the product price.
//		* Organization - CatalogRef.Companies, Undefined - the organization that the table
//														part is being edited for.
//		* Warehouse - CatalogRef.Warehouses - the warehouse where inventory is recorded.
//		* Department - CatalogRef.BusinessStructure - the division that performs the work.
//		* DisplaySalesDocuments - Boolean - indicates whether to display a column containing information 
//													about the implementation document.
//		* DisplayExciseTaxAmount - Boolean - indicates whether a column containing information 
//													about the excise tax amount should be displayed.
//		* UseExcisableGoods - Boolean - indicates whether the Inventory owner attribute can be specified manually subject to excise tax.
//		* EditInventoryKinds - Boolean - indicates that the data in the table part can be edited.
//		* ColumnNameProducts - String - name of the column containing information about the item.
//		* ColumnNameCharacteristic - String - name of the column that contains information about the item's characteristics.
//		* ColumnNamePurpose - String - the name of the column containing information about the destination of the product.
//		* StorageLocationInTabularPart - Boolean - indicates that the source of the item's storage location is
//													the Attribute Warehouse of the Goods tabular part. To ignore the values
//													of the table part, set the value of the parameter to FALSE and
//													initialize the value of the Warehouse parameter.
//		* ProductInHeader - Boolean - indicates that information about the item is specified in the document header (not in the table
//									part).
//		* DivisionInHeader - Boolean - indicates that the information about the division performing the work is indicated
//											in the header of the document (not in the table part).
//		* AddressOfInventoryKindsInStorage - String - address of the temporary storage that stores information about the table 
//													part of inventory types.
//		* GoodsAddressInStorage - String - address of the temporary storage where the information of the table 
//													part of the goods is stored.
//		* NameTSTypesOfStocks - String - name of the table part of the document's inventory types.
//		* NameTSGoods - String - name of the table part of the document's products.
//		* DocumentDate - Date - date of the document for which the inventory types are specified.
//		* Recorder - DocumentRef, Undefined - link to the document-motion recorder.
//		* AddressOfDocumentDataInRepository - String - the address of the temporary storage that stores the data structure
//													of the document for which the table part is being edited.
//
Function OptionsForEditingInventoryTypes() Export
	
	Result = New Structure;
	Result.Insert("NameTSGoods",                    "Goods");
	Result.Insert("NameTSTypesOfStocks",               "InventoryKinds");
	Result.Insert("GoodsAddressInStorage",         "");
	Result.Insert("AddressOfInventoryKindsInStorage",    "");
	Result.Insert("ProductInHeader",                    False);
	Result.Insert("DivisionInHeader",            False);
	Result.Insert("ColumnNameProducts",         "Products");
	Result.Insert("ColumnNameCharacteristic",       "Characteristic");
	Result.Insert("ColumnNamePurpose",           "Purpose");
	Result.Insert("StorageLocationInTabularPart",   True);
	Result.Insert("EditInventoryKinds",       True);
	Result.Insert("DisplaySalesDocuments",  False);
	Result.Insert("DisplayExciseTaxAmount",          False);
	Result.Insert("UseExcisableGoods",  False);
	Result.Insert("Warehouse",                          Catalogs.Warehouses.EmptyRef());
	Result.Insert("Organization",                    Undefined);
	Result.Insert("Department",                  Catalogs.BusinessStructure.EmptyRef());
	Result.Insert("PriceIncludesVAT",                False);
	Result.Insert("DocumentItemModified",          False);
	Result.Insert("InventoryOwnerAttributesAreSpecifiedManually",      False);
	Result.Insert("DocumentDate",                  Date(1, 1, 1));
	Result.Insert("Recorder",                    Undefined);
	Result.Insert("AddressOfDocumentDataInRepository", "");
	
	Return Result;
	
EndFunction

// Places the "Products" and "inventory Types" table parts in temporary storage.
//
// Parameters:
//	Form - ClientApplicationForm - A document Form that contains the following properties:
//		* Object - DocumentObject, FormDataStructure - the main details of the document form.
//	OptionsForEditingInventoryTypes - See OptionsForEditingInventoryTypes.
//
// Returns:
//	See OptionsForEditingInventoryTypes.
//
Function PutGoodsAndStockTypesInStorage(Form, OptionsForEditingInventoryTypes = Undefined) Export
	
	If OptionsForEditingInventoryTypes = Undefined Then
		OptionsForEditingInventoryTypes = OptionsForEditingInventoryTypes();
	EndIf;
	
	Object                  = Form.Object;
	Goods                  = Object[OptionsForEditingInventoryTypes.NameTSGoods];
	InventoryKinds             = Object[OptionsForEditingInventoryTypes.NameTSTypesOfStocks];
	UUID = Form.UUID;
	
	If OptionsForEditingInventoryTypes.ProductInHeader Then
		
		TableOfGoods = New ValueTable;
		TableOfGoods.Columns.Add("LineNumber", New TypeDescription("Number"));
		TableOfGoods.Columns.Add("ItemsLocationAttributes",
										New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
		TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		TableOfGoods.Columns.Add("Characteristic",
										New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TableOfGoods.Columns.Add("Count", New TypeDescription("Number"));
		
		NewRow = TableOfGoods.Add();
		FillPropertyValues(NewRow, Object);
		NewRow.LineNumber = 1;
		
	Else
		
		TableOfGoods = Goods.Unload();
		
		If OptionsForEditingInventoryTypes.ColumnNameProducts <> "Products" Then
			If TableOfGoods.Columns.Find("Products") <> Undefined Then
				TableOfGoods.Columns.Delete("Products");
			EndIf;
			
			ColumnProducts = TableOfGoods.Columns[OptionsForEditingInventoryTypes.ColumnNameProducts]; // ValueTableColumn
			ColumnProducts.Name = "Products";
		EndIf;
		
		If OptionsForEditingInventoryTypes.ColumnNameCharacteristic <> "Characteristic" Then
			If TableOfGoods.Columns.Find("Characteristic") <> Undefined Then
				TableOfGoods.Columns.Delete("Characteristic");
			EndIf;
			
			ColumnCharacteristics = TableOfGoods.Columns[OptionsForEditingInventoryTypes.ColumnNameCharacteristic]; // ValueTableColumn
			ColumnCharacteristics.Name = "Characteristic";
		EndIf;
		
		If OptionsForEditingInventoryTypes.ColumnNamePurpose <> "Purpose" Then
			If TableOfGoods.Columns.Find("Purpose") <> Undefined Then
				TableOfGoods.Columns.Delete("Purpose");
			EndIf;
			
			DestinationColumn_ = TableOfGoods.Columns[OptionsForEditingInventoryTypes.ColumnNamePurpose]; // ValueTableColumn
			DestinationColumn_.Name = "Purpose";
		EndIf;
		
		If Not OptionsForEditingInventoryTypes.StorageLocationInTabularPart Then
			If TableOfGoods.Columns.Find("Warehouse") <> Undefined Then
				TableOfGoods.Columns.Delete("Warehouse");
			EndIf;
		EndIf;
		
	EndIf;
	
	OptionsForEditingInventoryTypes.GoodsAddressInStorage = PutToTempStorage(
																	TableOfGoods,
																	UUID);
	
	InventoryKindTable = InventoryKinds.Unload();
	
	OptionsForEditingInventoryTypes.AddressOfInventoryKindsInStorage = PutToTempStorage(
																		InventoryKindTable,
																		UUID);
	
	If Not ValueIsFilled(OptionsForEditingInventoryTypes.Organization) Then
		OptionsForEditingInventoryTypes.Organization = Object.Organization;
	EndIf;
	
	OptionsForEditingInventoryTypes.InventoryOwnerAttributesAreSpecifiedManually = Object.InventoryOwnerAttributesAreSpecifiedManually;
	
	If Object.Property("PriceIncludesVAT") Then
		OptionsForEditingInventoryTypes.PriceIncludesVAT = Object.PriceIncludesVAT;
	EndIf;
	
	If Not ValueIsFilled(OptionsForEditingInventoryTypes.Warehouse)
		And Object.Property("Warehouse") Then
		
		OptionsForEditingInventoryTypes.Warehouse = Object.Warehouse;
		
	EndIf;
	
	If Not ValueIsFilled(OptionsForEditingInventoryTypes.Department)
		And Object.Property("Department") Then
		
		OptionsForEditingInventoryTypes.Department = Object.Department;
		
	EndIf;
	
	OptionsForEditingInventoryTypes.DocumentItemModified    = Form.Modified;
	OptionsForEditingInventoryTypes.EditInventoryKinds = OptionsForEditingInventoryTypes.EditInventoryKinds
																	And Not Form.ReadOnly
																	And Form.Enabled
																	And UserRightsCached.EditDocumentInventoryOwnerAttributes();
	
	OptionsForEditingInventoryTypes.Recorder		= Object.Ref;
	OptionsForEditingInventoryTypes.DocumentDate	= Object.Date;
	
	DocumentData = TMCommonUse.StructureWithMetadataObjectProperties(Object.Ref.Metadata());
	FillPropertyValues(DocumentData, Object);
	
	DocumentData.Insert(OptionsForEditingInventoryTypes.NameTSGoods, Goods.Unload());
	
	OptionsForEditingInventoryTypes.AddressOfDocumentDataInRepository = PutToTempStorage(
																			DocumentData,
																			UUID);
	
	Return OptionsForEditingInventoryTypes;
	
EndFunction

// Processes the input of inventory types and places the specified inventory types in the table part of the object.
//
// Parameters:
//	ValueSelected	 - See OptionsForEditingInventoryTypes.
//	Form				 - ClientApplicationForm	 - the form of an object that has a table part of the Viewspaces
//
Procedure ProcessInputOfInventoryTypesManually(ValueSelected, Form) Export
	
	FormAttributes				= Form.GetAttributes();
	AddAttribute			= True;
	NameOfPropsToAdd	= NameOfFormPropsAndInventoryTypesHaveBeenChanged();
	
	For Each FormAttribute In FormAttributes Do
		If FormAttribute.Name = NameOfPropsToAdd Then
			AddAttribute = False;
			
			Break;
		EndIf;
	EndDo;
	
	If AddAttribute Then
		PropsStockTypesHaveBeenChangedManually = New FormAttribute(NameOfPropsToAdd,
																	New TypeDescription("Boolean"));
		
		AttributesToAddArray = New Array;
		AttributesToAddArray.Add(PropsStockTypesHaveBeenChangedManually);
		
		Form.ChangeAttributes(AttributesToAddArray);
	EndIf;
	
	TableTypesOfStocks_	= GetFromTempStorage(ValueSelected.AddressOfInventoryKindsInStorage);
	TypesOfStocksChanged	= Form.Object.InventoryOwnerAttributesAreSpecifiedManually <> ValueSelected.InventoryOwnerAttributesAreSpecifiedManually;
	
	If TableTypesOfStocks_.Count()
		And ValueSelected.InventoryOwnerAttributesAreSpecifiedManually Then
		
		TypesOfDocumentStocks = Form.Object[ValueSelected.NameTSTypesOfStocks].Unload();
		
		Query = New Query;
		Query.Text = TextOfRequestToCheckChangesInInventoryTypesManually(TypesOfDocumentStocks);
		
		Query.SetParameter("TypesOfDocumentStocks",			TypesOfDocumentStocks);
		Query.SetParameter("TypesOfStocksSpecifiedManually",	TableTypesOfStocks_);
		
		TypesOfStocksChanged = Not Query.Execute().IsEmpty();
		
	EndIf;
	
	Form.Modified				= TypesOfStocksChanged;
	Form[NameOfPropsToAdd]			= TypesOfStocksChanged;
	Form.Object.InventoryOwnerAttributesAreSpecifiedManually	= ValueSelected.InventoryOwnerAttributesAreSpecifiedManually;
	
	Form.Object[ValueSelected.NameTSTypesOfStocks].Load(TableTypesOfStocks_);
	
EndProcedure

#EndRegion

#Region CheckingDetails

// Checks whether the division is filled in in the table part.
//
// Parameters:
//	DocumentObject - DocumentObject, ClientApplicationForm - The document being checked.
//	ItemsTypes - Array of EnumRef.ItemsTypes - Product types to be checked.
//	ErrorText - String - Error text with the "%1" parameter for the line number.
//	Cancel - Boolean - Indicates the presence of errors.
//	TSName - String - the name of the Attribute of the tabular part in which the check is performed.
//
Procedure CheckFillingOfDivisionInTablePart(DocumentObject,
															ItemsTypes,
															ErrorText,
															Cancel,
															TSName = "Goods") Export
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(DocumentObject[TSName]) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Purpose AS Purpose
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber
	|FROM
	|	GoodsTable AS GoodsTable
	|WHERE
	|	CAST(GoodsTable.Products AS Catalog.Products).ItemsType IN (&ItemsTypes)
	|	AND CASE
	|		WHEN CAST(GoodsTable.Products AS Catalog.Products).ItemsType IN 
	|				(VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.ToExpenseAs
	|		ELSE
	|			(GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			OR NOT (CAST(GoodsTable.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				AND CAST(GoodsTable.Purpose AS Catalog.Assignments).AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)))
	|	END
	|	AND GoodsTable.Department = VALUE(Catalog.BusinessStructure.EmptyRef)";
	
	// If only a service or job is checked, then the "Write off expenses" flag is not used to check the condition. 
	// However, it may not be in the document, so you need to disable its use.
	ItemPackaging = New Array;
	ItemPackaging.Add(Enums.ItemsTypes.OwnGoods);
	ItemPackaging.Add(Enums.ItemsTypes.ReusablePackage);
	
	CheckWriteOffForExpenses = False;
	For Each ItemTypeBeingChecked In ItemPackaging Do
		
		If ItemsTypes.Find(ItemTypeBeingChecked) <> Undefined Then
			CheckWriteOffForExpenses = True;
			Break;
		EndIf;
		
	EndDo;
	
	UnloadedColumns = New Array;
	UnloadedColumns.Add("LineNumber");
	UnloadedColumns.Add("Products");
	UnloadedColumns.Add("Purpose");
	UnloadedColumns.Add("Department");
	
	If CheckWriteOffForExpenses Then
		UnloadedColumns.Add("ToExpenseAs");
	EndIf;
	
	UnloadedColumns = StrConcat(UnloadedColumns, ", ");
	
	If TypeOf(DocumentObject[TSName]) = Type("ValueTable") Then
		GoodsTable = DocumentObject[TSName].Copy(, UnloadedColumns); // ValueTable
	Else
		GoodsTable = DocumentObject[TSName].Unload(, UnloadedColumns); // ValueTable
	EndIf;
	
	If Not CheckWriteOffForExpenses Then
		GoodsTable.Columns.Add("ToExpenseAs", New TypeDescription("Boolean"));
	EndIf;
	
	Query.SetParameter("GoodsTable",		GoodsTable);
	Query.SetParameter("ItemsTypes",	ItemsTypes);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	DataKey		= TMCommonUse.DataKeyForMessageToUser(DocumentObject);
	DataKey		= ?(Common.IsReference(TypeOf(DataKey)),
						DocumentObject,
						Undefined);
	
	While Selection.Next() Do
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Selection.LineNumber);
		
		Field = CommonClientServer.PathToTabularSection(TSName,
																Selection.LineNumber,
																"Department");
		
		Common.MessageToUser(
			MessageText,
			DataKey,
			Field,
			,
			Cancel);
	EndDo;
	
EndProcedure

// Returns the parameter structure used when checking the filling of GTD numbers in the tabular part of the object.
//
// Returns:
//	Structure - contains the following properties:
//		* TSName - String - the name of the tabular part in which the check is performed.
//		* PresentationOfTS - String - representation of the table part being checked. If the parameter value is not specified,
//										then the view takes the value equal to the synonym OF the Attribute
//										OF the metadata object.
//		* NameOfProductsField - String - the name of the field containing information about the item.
//		* BusinessOperation - EnumRef.BusinessTransactions, Undefined - business operation of the document.
//		* CheckItemsAndContainers - Boolean - indicates whether the ProductBatchID numbers of traceable items and multi-turn containers have been checked.
//		* CheckWorks - Boolean - indicates an additional check for filling in the ProductBatchID numbers for the works being tracked.
//		* AllowTraceableItemWithoutCCDNumbers - Boolean - if True, filling in the CCD number for the item being tracked is not checked.
//		* CheckingReSortingOfGoods - Boolean - indicates whether the tabular part of the product re-sorting documents has been checked.
//
Function ParametersForCheckingFillingInOfCCDNumbers() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",                  "Goods");
	CheckParameters.Insert("PresentationOfTS",        "");
	CheckParameters.Insert("PresentationOfCCDNumber", "");
	CheckParameters.Insert("NameOfProductsField",    "Products");
	CheckParameters.Insert("BusinessOperation",  Undefined);
	CheckParameters.Insert("CheckItemsAndContainers",   True);
	CheckParameters.Insert("CheckWorks",        False);
	CheckParameters.Insert("AllowTraceableItemWithoutCCDNumbers", False);
	CheckParameters.Insert("CheckingReSortingOfGoods", False);
	
	Return CheckParameters;
	
EndFunction

// The procedure checks the indication of GTD numbers in the "Products" table part.
//
// Parameters:
//	DocumentObject - DocumentObject, ClientApplicationForm - The document being checked.
//	Cancel - Boolean - indicates that the document was rejected.
//	CheckParameters - See ParametersForCheckingFillingInOfCCDNumbers.
//
Procedure CheckFillingOfCCDNumbers(DocumentObject, Cancel, CheckParameters = Undefined) Export
	
	If CheckParameters = Undefined Then
		CheckParameters = ParametersForCheckingFillingInOfCCDNumbers();
	EndIf;
	
	If Not CheckParameters.CheckItemsAndContainers
		And Not CheckParameters.CheckWorks Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	
	If Not CheckParameters.CheckingReSortingOfGoods Then
		
		NameOfProductsField = CheckParameters.NameOfProductsField;
		
		QueryText =
		"SELECT
		|	SourceTable.LineNumber AS LineNumber,
		|	CAST(&NameOfProductsField AS Catalog.Products) AS Products,
		|	SourceTable.CCDNumber AS CCDNumber
		|INTO GoodsTable
		|FROM
		|	&GoodsTable AS SourceTable
		|
		|INDEX BY
		|	Products,
		|	CCDNumber
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.LineNumber	AS LineNumber,
		|	TRUE						AS ErrorCCDNumberIsNotFilledIn,
		|	FALSE						AS ErrorIsIncorrectProductBatchID,
		|	FALSE						AS ErrorIncorrectCCDNumber
		|FROM
		|	GoodsTable AS GoodsTable
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON GoodsTable.Products = CatalogProducts.Ref
		|WHERE
		|	GoodsTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
		|	AND CatalogProducts.ItemsType IN (&ItemsTypes)
		|	AND CatalogProducts.KeepRecordsByCCD
		|	AND ((&RestrictGoodsReceiptWithoutCCDNumbers
		|			AND NOT ISNULL(CatalogProducts.TracedGoods, FALSE))
		|		OR (ISNULL(CatalogProducts.TracedGoods, FALSE)
		|			AND &UseTraceableImportedGoodsAccounting
		|			AND NOT &AllowTraceableItemWithoutCCDNumbers
		|			AND NOT &ThisIsPurchaseInEAEUCountries))
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber	AS LineNumber,
		|	FALSE						AS ErrorCCDNumberIsNotFilledIn,
		|	TRUE						AS ErrorIsIncorrectProductBatchID,
		|	FALSE						AS ErrorIncorrectCCDNumber
		|FROM
		|	GoodsTable AS GoodsTable
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON GoodsTable.Products = CatalogProducts.Ref
		|		
		|		INNER JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
		|		ON GoodsTable.CCDNumber = CatalogCCDNumbers.Ref
		|WHERE
		|	CatalogProducts.TracedGoods
		|	AND NOT &AllowTraceableItemWithoutCCDNumbers
		|	AND GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
		|	AND CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
		|												VALUE(Enum.ItemsTypes.Work_5),
		|												VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND ((&UseTraceableImportedGoodsAccounting
		|			AND CatalogCCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.CCDNumber))
		|		OR (NOT &UseTraceableImportedGoodsAccounting
		|			AND CatalogCCDNumbers.CCDNumberType <> VALUE(Enum.CCDNumberTypes.CCDNumber)))
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber	AS LineNumber,
		|	FALSE						AS ErrorCCDNumberIsNotFilledIn,
		|	FALSE						AS ErrorIsIncorrectProductBatchID,
		|	TRUE						AS ErrorIncorrectCCDNumber
		|FROM
		|	GoodsTable AS GoodsTable
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON GoodsTable.Products = CatalogProducts.Ref
		|		
		|		INNER JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
		|		ON GoodsTable.CCDNumber = CatalogCCDNumbers.Ref
		|WHERE
		|	CatalogProducts.KeepRecordsByCCD
		|	AND NOT CatalogProducts.TracedGoods
		|	AND GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
		|	AND CatalogCCDNumbers.CCDNumberType <> VALUE(Enum.CCDNumberTypes.CCDNumber)
		|
		|ORDER BY
		|	LineNumber";
		
		QueryText = StrReplace(QueryText, "&NameOfProductsField", "SourceTable." + NameOfProductsField);
		
		UnloadedColumns = "LineNumber, CCDNumber, " + NameOfProductsField;
		
		ItemsTypes = New Array;
		
		If CheckParameters.CheckItemsAndContainers Then
			ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
			ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
		EndIf;
		
		If CheckParameters.CheckWorks Then
			ItemsTypes.Add(Enums.ItemsTypes.Work_5);
		EndIf;
		
		ThisIsPurchaseInEAEUCountries	= False;
		BusinessOperation	= CheckParameters.BusinessOperation;
		
		If ValueIsFilled(BusinessOperation) Then
			BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
												Enums.BusinessTransactions.ImportFromEAEU);
			ThisIsPurchaseInEAEUCountries = (BusinessTransactionsProcurementInEAEUCountries.Find(BusinessOperation) <> Undefined);
		EndIf;
		
		Query.SetParameter("ItemsTypes",		ItemsTypes);
		Query.SetParameter("ThisIsPurchaseInEAEUCountries",	ThisIsPurchaseInEAEUCountries);
		
	Else
		
		QueryText = 
		"SELECT
		|	SourceTable.LineNumber					AS LineNumber,
		|	SourceTable.Products				AS Products,
		|	SourceTable.ProductsRecordingAsReceived	AS ProductsRecordingAsReceived,
		|	SourceTable.CCDNumber					AS CCDNumber
		|INTO GoodsTable
		|FROM
		|	&GoodsTable AS SourceTable
		|
		|INDEX BY
		|	Products,
		|	ProductsRecordingAsReceived,
		|	CCDNumber
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.LineNumber	AS LineNumber,
		|	TRUE						AS ErrorCCDNumberIsNotFilledIn,
		|	FALSE						AS ErrorIsIncorrectProductBatchID,
		|	FALSE						AS ErrorIncorrectCCDNumber
		|FROM
		|	GoodsTable AS GoodsTable
		|		INNER JOIN Catalog.Products AS ItemDataForWriteOff
		|		ON GoodsTable.Products = ItemDataForWriteOff.Ref
		|		
		|		INNER JOIN Catalog.Products AS ItemDataEntry
		|		ON GoodsTable.ProductsRecordingAsReceived = ItemDataEntry.Ref
		|
		|WHERE
		|	GoodsTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
		|	AND ItemDataEntry.KeepRecordsByCCD
		|	AND ((&RestrictGoodsReceiptWithoutCCDNumbers
		|			AND NOT ItemDataEntry.TracedGoods)
		|		OR (&UseTraceableImportedGoodsAccounting
		|			AND ItemDataEntry.TracedGoods))
		|	AND (NOT ItemDataForWriteOff.KeepRecordsByCCD
		|		OR (ItemDataForWriteOff.TracedGoods
		|			AND NOT ItemDataEntry.TracedGoods)
		|		OR (&UseTraceableImportedGoodsAccounting
		|			AND ItemDataEntry.TracedGoods
		|			AND (NOT ItemDataForWriteOff.TracedGoods
		|				OR (ItemDataForWriteOff.TracedGoods
		|					AND ItemDataForWriteOff.FEACNUnitOfMeasure <> ItemDataEntry.FEACNUnitOfMeasure))))
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber	AS LineNumber,
		|	FALSE						AS ErrorCCDNumberIsNotFilledIn,
		|	TRUE						AS ErrorIsIncorrectProductBatchID,
		|	FALSE						AS ErrorIncorrectCCDNumber
		|FROM
		|	GoodsTable AS GoodsTable
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON GoodsTable.ProductsRecordingAsReceived = CatalogProducts.Ref
		|		
		|		INNER JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
		|		ON GoodsTable.CCDNumber = CatalogCCDNumbers.Ref
		|WHERE
		|	CatalogProducts.TracedGoods
		|	AND GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
		|	AND ((&UseTraceableImportedGoodsAccounting
		|			AND CatalogCCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.CCDNumber))
		|		OR (NOT &UseTraceableImportedGoodsAccounting
		|			AND CatalogCCDNumbers.CCDNumberType <> VALUE(Enum.CCDNumberTypes.CCDNumber)))
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber	AS LineNumber,
		|	FALSE						AS ErrorCCDNumberIsNotFilledIn,
		|	FALSE						AS ErrorIsIncorrectProductBatchID,
		|	TRUE						AS ErrorIncorrectCCDNumber
		|FROM
		|	GoodsTable AS GoodsTable
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON GoodsTable.ProductsRecordingAsReceived = CatalogProducts.Ref
		|		
		|		INNER JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
		|		ON GoodsTable.CCDNumber = CatalogCCDNumbers.Ref
		|WHERE
		|	CatalogProducts.KeepRecordsByCCD
		|	AND NOT CatalogProducts.TracedGoods
		|	AND GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
		|	AND CatalogCCDNumbers.CCDNumberType <> VALUE(Enum.CCDNumberTypes.CCDNumber)
		|
		|ORDER BY
		|	LineNumber";
		
		UnloadedColumns = "LineNumber, Products, ProductsRecordingAsReceived, CCDNumber";
		
	EndIf;
	
	TSName = CheckParameters.TSName;
	
	If TypeOf(DocumentObject[TSName]) = Type("ValueTable") Then
		GoodsTable = DocumentObject[TSName].Copy(, UnloadedColumns);
	Else
		GoodsTable = DocumentObject[TSName].Unload(, UnloadedColumns);
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(DocumentObject, "Date") Then
		ObjectDate = DocumentObject.Date;
	Else
		ObjectDate = CurrentSessionDate();
	EndIf;
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														ObjectDate);
	
	Query.Text = QueryText;
	
	Query.SetParameter("GoodsTable", GoodsTable);
	Query.SetParameter("RestrictGoodsReceiptWithoutCCDNumbers", RestrictGoodsReceiptWithoutCCDNumbers);
	Query.SetParameter("UseTraceableImportedGoodsAccounting",
								UseTraceableImportedGoodsAccounting);
	Query.SetParameter("AllowTraceableItemWithoutCCDNumbers",
								CheckParameters.AllowTraceableItemWithoutCCDNumbers);
	
	DataKey		= TMCommonUse.DataKeyForMessageToUser(DocumentObject);
	DataKey		= ?(Common.IsReference(TypeOf(DataKey)),
						DocumentObject,
						Undefined);
	PresentationOfTS	= ?(IsBlankString(CheckParameters.PresentationOfTS),
						DocumentObject.Metadata().TabularSections[TSName].Synonym,
						CheckParameters.PresentationOfTS);
	
	PresentationOfCCDNumber =
		?(IsBlankString(CheckParameters.PresentationOfCCDNumber),
			NStr("vi = 'Số tờ khai hải quan';
				|ru = 'Номер ГТД';
				|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
				|it = 'Номер ГТД';
				|pl = 'Numer ŁDC (ładunkowej deklaracji celnej)';
				|tr = 'Gümrük kargo beyannamesi numarası'"),
			CheckParameters.PresentationOfCCDNumber);
						
	TemplateErrorCCDNumberIsNotFilledIn = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 của danh sách ""%3""';
												|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
												|en = 'Column ""%1"" in line %2 of list ""%3"" is required'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required';
												|it = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
												|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
												|tr = 'Sütun ""%1"" ""%2"" listesinin %3 satırında doldurulmadı'");
	TemplateErrorInvalidCCDNumber = NStr("vi = 'Trong dòng %1 của danh sách ""%2"" đã chỉ ra số TKHQ sai loại. Hãy chỉ ra số TKHQ kiểu ""TKHQ""';
										|ru = 'В строке %1 списка ""%2"" указан номер ГТД некорректного типа. Укажите номер ГТД типа ""ГТД""';
										|en = 'In line %1 of the ""%2"" list, the CCD number of the incorrect type is specified. Specify the CCD number of the ""CCD"" type'; fa = 'In line %1 of the ""%2"" list, the CCD number of the incorrect type is specified. Specify the CCD number of the ""CCD"" type';
										|it = 'В строке %1 списка ""%2"" указан номер ГТД некорректного типа. Укажите номер ГТД типа ""ГТД""';
										|pl = 'In line %1 of the ""%2"" list, the CCD number of the incorrect type is specified. Specify the CCD number of the ""CCD"" type';
										|tr = '“%2” listesinin %1 satırı yanlış tipte GTE numarası içeriyor. “GTE” türündeki GTE sayısını belirtin'");
	
	If UseTraceableImportedGoodsAccounting Then
		TemplateErrorIncorrectProductBatchID = NStr("vi = 'Trong dòng %1 của danh sách ""%2"" đã chỉ ra số TKHQ sai loại. Hãy chỉ ra số TKHQ kiểu ""SĐK lô hàng"" hoặc ""SĐK lô hàng của bộ""';
													|ru = 'В строке %1 списка ""%2"" указан номер ГТД некорректного типа. Укажите номер ГТД типа ""РНПТ"" или ""РНПТ комплекта""';
													|en = 'In line %1 of the ""%2"" list, the CCD number of the incorrect type is specified. Specify the CCD number of the ""RNPT"" or ""Kit RNPT"" type'; fa = 'In line %1 of the ""%2"" list, the CCD number of the incorrect type is specified. Specify the CCD number of the ""RNPT"" or ""Kit RNPT"" type';
													|it = 'В строке %1 списка ""%2"" указан номер ГТД некорректного типа. Укажите номер ГТД типа ""РНПТ"" или ""РНПТ комплекта""';
													|pl = 'In line %1 of the ""%2"" list, the CCD number of the incorrect type is specified. Specify the CCD number of the ""RNPT"" or ""Kit RNPT"" type';
													|tr = '“%2” listesinin %1 satırı yanlış türde GKB numarası içeriyor. “RNPT” veya ‘RNPT seti’ türündeki GKB sayısını belirtin'");
	Else
		TemplateErrorIncorrectProductBatchID = TemplateErrorInvalidCCDNumber;
	EndIf;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Selection.ErrorCCDNumberIsNotFilledIn Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
						TemplateErrorCCDNumberIsNotFilledIn,
						PresentationOfCCDNumber,
						Selection.LineNumber,
						PresentationOfTS);
			
			Common.MessageToUser(Text,
													DataKey,
													TSName + "[" + (Selection.LineNumber - 1) + "].CCDNumber",
													,
													Cancel);
		EndIf;
		
		If Selection.ErrorIsIncorrectProductBatchID Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
						TemplateErrorIncorrectProductBatchID,
						Selection.LineNumber,
						PresentationOfTS);
			
			Common.MessageToUser(Text,
													DataKey,
													TSName + "[" + (Selection.LineNumber - 1) + "].CCDNumber");
		EndIf;
		
		If Selection.ErrorIncorrectCCDNumber Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
						TemplateErrorInvalidCCDNumber,
						Selection.LineNumber,
						PresentationOfTS);
			
			Common.MessageToUser(Text,
													DataKey,
													TSName + "[" + (Selection.LineNumber - 1) + "].CCDNumber");
		EndIf;
	EndDo;
	
EndProcedure

// The procedure checks whether there is an item in the manufactured products that has the GTD numbers enabled.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - indicates that the document was rejected.
//	CheckParameters - See ParametersForCheckingFillingInOfCCDNumbers.
//
Procedure CheckAvailabilityOfVTCHSProductsWithCCDSoftware(DocumentObject, Cancel, CheckParameters = Undefined) Export
	
	If CheckParameters = Undefined Then
		CheckParameters = ParametersForCheckingFillingInOfCCDNumbers();
	EndIf;
	
	UseTraceableImportedGoodsAccounting =
		Not CheckParameters.AllowTraceableItemWithoutCCDNumbers
		And AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date(1, 1, 1));
	RestrictTransactionsWithImportedGoodsWithoutCCDNumbers =
		GetFunctionalOption("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers");
	
	If Not (UseTraceableImportedGoodsAccounting
		Or RestrictTransactionsWithImportedGoodsWithoutCCDNumbers) Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SourceTable.LineNumber		AS LineNumber,
	|	SourceTable.Products	AS Products
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS SourceTable
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber	AS LineNumber,
	|	CASE
	|		WHEN ProductData_1.TracedGoods
	|				AND &UseTraceableImportedGoodsAccounting
	|			THEN TRUE
	|		ELSE FALSE
	|	END						AS TracedGoods
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|	
	|WHERE
	|	ProductData_1.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND ((ProductData_1.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting)
	|		OR (ProductData_1.KeepRecordsByCCD
	|			AND &RestrictTransactionsWithImportedGoodsWithoutCCDNumbers))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber	AS LineNumber,
	|	TRUE						AS TracedGoods
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|	
	|WHERE
	|	ProductData_1.TracedGoods
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|ORDER BY
	|	LineNumber";
	
	TSName = CheckParameters.TSName;
	
	GoodsTable = DocumentObject[TSName].Unload(, "LineNumber, Products");
	
	Query.SetParameter("GoodsTable", GoodsTable);
	Query.SetParameter("UseTraceableImportedGoodsAccounting",
								UseTraceableImportedGoodsAccounting);
	Query.SetParameter("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers",
								RestrictTransactionsWithImportedGoodsWithoutCCDNumbers);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	ObjectMetadata	= DocumentObject.Metadata();
	PresentationOfTS		= ObjectMetadata.TabularSections[TSName].Synonym;
	
	TemplateImportedItem		= NStr("vi = 'Trong dòng %1 của danh sách ""%2"" đã chọn mặt hàng có ghi nhận theo Tờ khai hải quan.
										|Khi sử dụng tùy chọn ""Cấm giao dịch với hàng hóa không có số TKHQ"", thì chương trình sẽ cấm chọn hàng hóa như vậy.';
										|ru = 'В строке %1 списка ""%2"" выбрана номенклатура, для которой ведется учет по ГТД.
										|При включенной опции ""Запретить операции с товарами без номеров ГТД"" выбор такой номенклатуры запрещен.';
										|en = 'Items with CCD records are selected in line %1 of the %2 list. 
										|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.'; fa = 'Items with CCD records are selected in line %1 of the %2 list. 
										|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
										|it = 'Items with CCD records are selected in line %1 of the %2 list. 
										|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
										|pl = 'Items with CCD records are selected in line %1 of the %2 list. 
										|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
										|tr = '""%2"" listesinin  %1  satırında Kargo Gümrük Beyannamesine göre muhasebesinin tutulduğu öğe seçildi.
										|""Kargo Gümrük Beyannamesi numaraları olmayan ürün işlemlerini yasakla"" seçeneği etkinleştirildiğinde, bu türdeki bir öğenin seçilmesi yasaktır.'");
	TemplateTraceableItem	= NStr("vi = 'Trong dòng %1 của danh sách ""%2"" đã chọn mặt hàng được truy xuất.
										|Khi bật sử dụng ghi nhận hàng hóa nhập khẩu được truy xuất, cấm chọn mặt hàng như vậy.';
										|ru = 'В строке %1 списка ""%2"" выбрана прослеживаемая номенклатура.
										|При включенном учете прослеживаемых импортных товаров выбор такой номенклатуры запрещен.';
										|en = 'Traceable item is selected in line %1 of the ""%2"" list.
										|If traceable imported goods accounting is enabled, such item cannot be selected.'; fa = 'Traceable item is selected in line %1 of the ""%2"" list.
										|If traceable imported goods accounting is enabled, such item cannot be selected.';
										|it = 'В строке %1 списка ""%2"" выбрана прослеживаемая номенклатура.
										|При включенном учете прослеживаемых импортных товаров выбор такой номенклатуры запрещен.';
										|pl = 'Traceable item is selected in line %1 of the ""%2"" list.
										|If traceable imported goods accounting is enabled, such item cannot be selected.';
										|tr = '""%2"" listesinin %1 satırında izlenebilir öğe seçildi.
										|İzlenebilir ithalat muhasebesi etkinleştirildiğinde, bu tür öğenin seçilmesi yasaktır.'");
	
	While Selection.Next() Do
		MessageText	= ?(Selection.TracedGoods, TemplateTraceableItem, TemplateImportedItem);
		MessageText	= StringFunctionsClientServer.SubstituteParametersToString(MessageText,
																					Selection.LineNumber,
																					PresentationOfTS);
		Field			= CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "Products");
		
		Common.MessageToUser(MessageText, DocumentObject, Field, , Cancel);
	EndDo;
	
EndProcedure

// The procedure checks whether there is a manufactured item that has the GTD number tracking enabled.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure CheckAvailabilityOfProductsInHeaderTakingIntoAccountCCD(DocumentObject, Cancel) Export
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date(1, 1, 1));
	RestrictTransactionsWithImportedGoodsWithoutCCDNumbers =
		GetFunctionalOption("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers");
	
	If Not (UseTraceableImportedGoodsAccounting
		Or RestrictTransactionsWithImportedGoodsWithoutCCDNumbers) Then
		
		Return;
		
	EndIf;
	
	AttributesNames		= "KeepRecordsByCCD, TracedGoods, ItemsType";
	WareAttributes	= Common.ObjectAttributesValues(DocumentObject.Products, AttributesNames);
	
	MessageText = "";
	
	If WareAttributes.TracedGoods = True
		And UseTraceableImportedGoodsAccounting Then
		
		MessageText = NStr("vi = 'Trong chứng từ, đã chọn mặt hàng được truy xuất.
							|Khi bật sử dụng ghi nhận hàng hóa nhập khẩu được truy xuát, cấm chọn mặt hàng như vậy.';
							|ru = 'В документе выбрана прослеживаемая номенклатура.
							|При включенном учете прослеживаемых импортных товаров выбор такой номенклатуры запрещен.';
							|en = 'Traceable item is selected in the document.
							|If traceable imported goods accounting is enabled, such item cannot be selected.'; fa = 'Traceable item is selected in the document.
							|If traceable imported goods accounting is enabled, such item cannot be selected.';
							|it = 'В документе выбрана прослеживаемая номенклатура.
							|При включенном учете прослеживаемых импортных товаров выбор такой номенклатуры запрещен.';
							|pl = 'Traceable item is selected in the document.
							|If traceable imported goods accounting is enabled, such item cannot be selected.';
							|tr = 'Seçili belgede izlenebilir öğe seçildi.
							|İzlenebilir ithalat muhasebesi etkinleştirildiğinde, bu tür öğenin seçilmesi yasaktır.'");
		
	ElsIf WareAttributes.KeepRecordsByCCD = True
		And RestrictTransactionsWithImportedGoodsWithoutCCDNumbers
		And (WareAttributes.ItemsType = Enums.ItemsTypes.OwnGoods
			Or WareAttributes.ItemsType = Enums.ItemsTypes.ReusablePackage) Then
		
		MessageText = NStr("vi = 'Trong chứng từ đã chọn mặt hàng có tiến hành ghi nhận theo Tờ khai hải quan.
							|Khi sử dụng tùy chọn ""Cấm giao dịch với hàng hóa không có số TKHQ"", thì chương trình sẽ cấm chọn hàng hóa như vậy.';
							|ru = 'В документе выбрана номенклатура, для которой ведется учет по ГТД.
							|При включенной опции ""Запретить операции с товарами без номеров ГТД"" выбор такой номенклатуры запрещен.';
							|en = 'Items with CCD records are selected in the document.
							|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.'; fa = 'Items with CCD records are selected in the document.
							|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
							|it = 'Items with CCD records are selected in the document.
							|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
							|pl = 'Items with CCD records are selected in the document.
							|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
							|tr = 'Belgede Kargo Gümrük Beyannamesine göre muhasebesinin tutulduğu öğe seçildi.
							|""Kargo Gümrük Beyannamesi numaraları olmayan ürün işlemlerini yasakla"" seçeneği etkinleştirildiğinde, bu türdeki bir öğenin seçilmesi yasaktır.'");
		
	EndIf;
	
	If Not IsBlankString(MessageText) Then
		Common.MessageToUser(MessageText, DocumentObject, "Products", , Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region CorrectionOfNegativeBalancesOfGoodsForTransfer

// Performs the correction of negative balances the PH of the Products of the organizations to transfer in a background job.
//
// Parameters:
//	JobParameters - Structure - Calculation parameters in the background.
//
// Returns:
//	Boolean - Indicates that the task has been successfully started.
Function FixBalancesOnItemsToBeTransferredInBackgroundTask(JobParameters) Export
	
	JobDescription = NStr("vi = 'Điều chỉnh số dư âm theo hàng hóa cần chuyển giao';
							|ru = 'Исправление отрицательных остатков по товарам к передаче';
							|en = 'Correct negative stock balance for transfer'; fa = 'Correct negative stock balance for transfer';
							|it = 'Correzione dei saldi negativi per le merci in trasferimento';
							|pl = 'Sprostowanie ujemnych pozostałości wg towarów do przekazania';
							|tr = 'Transfer edilecek ürünler için negatif bakiyelerin düzeltilmesi'");
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(JobParameters);
	
	JobParameters = New Array();
	JobParameters.Add("InventoriesServer.CorrectBalancesOnGoodsToBeTransferred");
	JobParameters.Add(ExportProcedureParameters);
	
	BackgroundJob = BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, , JobDescription);
	
	Return BackgroundJob.UUID;
	
EndFunction

// corrects negative ph Balances of organizations' goods for transfer.
// Called from Processing.JournaLdocumentsIntercampany.Working place of transmission of goods 21.
//
// Parameters:
//	CallParameters - Structure - a collection of parameters containing the following properties:
//		* BeginOfPeriod - Date - Start date of the selection of movements to be corrected.
//		* EndOfPeriod - Date - The end date of the selection of movements to be corrected.
//		* Companies - Array of CatalogRef.Companies - the list of organizations for which Balances need to be corrected.
//
Procedure CorrectBalancesOnGoodsToBeTransferred(CallParameters) Export
	
	SetPrivilegedMode(True);
	InitialConductWithoutControlOfRemainingGoods = SessionParameters.PostWithoutControlOfCompanyStockBalance;
	SessionParameters.PostWithoutControlOfCompanyStockBalance = True;
	
	EndOfPeriod = CallParameters.EndOfPeriod;
	Companies = CallParameters.Companies;
	StatusOfDocuments_ = New Map;
	DocumentCache = New Map;
	
	Query = New Query;
	Query.SetParameter("AsOfThePeriodEnd", New Boundary(EndOfPeriod, BoundaryType.Including));
	Query.SetParameter("EndOfMonth", EndOfMonth(EndOfPeriod));
	Query.SetParameter("CompanyArray", Companies);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Companies));
	Query.Text = 
	"SELECT
	|	BalancesAtEndOfPeriod.CompanyOwner AS CompanyOwner,
	|	BalancesAtEndOfPeriod.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalancesAtEndOfPeriod.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	BalancesAtEndOfPeriod.CCDNumber AS CCDNumber,
	|	-BalancesAtEndOfPeriod.CountBalance AS Count,
	|	TRUE AS ByUninvoicedGoods,
	|	FALSE AS ThisIsReturn
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer.Balance(
	|			&AsOfThePeriodEnd,
	|			CompanyOwner IN (&CompanyArray)
	|				OR &ByAllCompanies) AS BalancesAtEndOfPeriod
	|WHERE
	|	BalancesAtEndOfPeriod.CountBalance < 0
	|
	|UNION ALL
	|
	|SELECT
	|	BalancesAtEndOfPeriod.CompanyOwner AS CompanyOwner,
	|	BalancesAtEndOfPeriod.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalancesAtEndOfPeriod.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	BalancesAtEndOfPeriod.CCDNumber AS CCDNumber,
	|	-BalancesAtEndOfPeriod.ReturnedBalance AS Count,
	|	TRUE AS ByUninvoicedGoods,
	|	TRUE AS ThisIsReturn
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer.Balance(
	|			&AsOfThePeriodEnd,
	|			CompanyOwner IN (&CompanyArray)
	|				OR &ByAllCompanies) AS BalancesAtEndOfPeriod
	|WHERE
	|	BalancesAtEndOfPeriod.ReturnedBalance < 0
	|";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		QuantityIsNegative = Selection.Count;
		QuantityInAdjustments = 0;
		
		Query = New Query(
		"SELECT
		|	Goods.Period AS Period,
		|	Goods.Recorder AS Ref,
		|	SUM(Goods.Count) AS Count,
		|	Goods.Recorder REFS Document.RegisterAdjustment AS ThisIsRegisterAdjustment,
		|	Goods.Recorder REFS Document.CustomerInvoiceIntercompany AS ThisIsTransferOfGoodsBetweenOrganizations,
		|	FALSE AS ThisIsReturnOfGoodsBetweenOrganizations,
		|	CASE
		|		WHEN Goods.Recorder REFS Document.CustomerInvoiceIntercompany
		|			THEN CAST(Goods.Recorder AS Document.CustomerInvoiceIntercompany).SpecifyCCDNumbers
		|		ELSE FALSE
		|	END AS SpecifyCCDNumbers
		|FROM
		|	AccumulationRegister.CompanyGoodsForTransfer AS Goods
		|WHERE
		|	Goods.CompanyOwner = &CompanyOwner
		|	AND Goods.ItemsLocationAttributes = &ItemsLocationAttributes
		|	AND Goods.SellerInventoryOwnerAttribute = &SellerInventoryOwnerAttribute
		|	AND Goods.CCDNumber = &CCDNumber
		|	AND (Goods.Recorder REFS Document.CustomerInvoiceIntercompany
		|			OR Goods.Recorder REFS Document.RegisterAdjustment)
		|	AND Goods.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Goods.Period <= &EndOfPeriod
		|	AND Goods.Active
		|	AND NOT &ThisIsReturn
		|
		|GROUP BY
		|	Goods.Recorder,
		|	Goods.Period
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.Period,
		|	Goods.Recorder,
		|	SUM(Goods.Returned),
		|	Goods.Recorder REFS Document.RegisterAdjustment,
		|	FALSE AS ThisIsTransferOfGoodsBetweenOrganizations,
		|	Goods.Recorder REFS Document.IntercompanyGoodsReturn AS ThisIsReturnOfGoodsBetweenOrganizations,
		|	FALSE
		|FROM
		|	AccumulationRegister.CompanyGoodsForTransfer AS Goods
		|WHERE
		|	Goods.CompanyOwner = &CompanyOwner
		|	AND Goods.ItemsLocationAttributes = &ItemsLocationAttributes
		|	AND Goods.SellerInventoryOwnerAttribute = &SellerInventoryOwnerAttribute
		|	AND Goods.CCDNumber = &CCDNumber
		|	AND (Goods.Recorder REFS Document.IntercompanyGoodsReturn
		|			OR Goods.Recorder REFS Document.RegisterAdjustment)
		|	AND Goods.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Goods.Period <= &EndOfPeriod
		|	AND Goods.Active
		|	AND &ThisIsReturn
		|
		|GROUP BY
		|	Goods.Recorder,
		|	Goods.Period
		|
		|ORDER BY
		|	Goods.Period DESC");

	
		Query.SetParameter("CompanyOwner", Selection.CompanyOwner);
		Query.SetParameter("ItemsLocationAttributes", Selection.ItemsLocationAttributes);
		Query.SetParameter("SellerInventoryOwnerAttribute", Selection.SellerInventoryOwnerAttribute);
		Query.SetParameter("CCDNumber", Selection.CCDNumber);
		Query.SetParameter("EndOfPeriod", EndOfPeriod);
		Query.SetParameter("ThisIsReturn", Selection.ThisIsReturn);
	
		DocumentsToBeCorrected = Query.Execute().Select();
		While DocumentsToBeCorrected.Next() And QuantityIsNegative > 0 Do
			
			If DocumentsToBeCorrected.ThisIsRegisterAdjustment Then
				QuantityInAdjustments = QuantityInAdjustments + DocumentsToBeCorrected.Count;
				Continue;
			EndIf;
			
			DocumentData = DocumentCache.Get(DocumentsToBeCorrected.Ref);
			If DocumentData = Undefined Then
				DocumentData = Common.ObjectAttributesValues(DocumentsToBeCorrected.Ref, "Goods, InventoryKinds");
				DocumentData.Goods = DocumentData.Goods.Unload();
				DocumentData.InventoryKinds = DocumentData.InventoryKinds.Unload();
			EndIf;
			If DocumentsToBeCorrected.SpecifyCCDNumbers Then
				SearchParameters = New Structure("ItemsLocationAttributes, CCDNumber, ByUninvoicedGoods");
			Else
				SearchParameters = New Structure("ItemsLocationAttributes, ByUninvoicedGoods");
			EndIf;
		
			FillPropertyValues(SearchParameters, Selection);
		
			WriteOffByDocument = Min(QuantityIsNegative, DocumentsToBeCorrected.Count); // in the document, we correct only the quantity for this type of inventory.
			QuantityIsNegative = QuantityIsNegative - WriteOffByDocument;
			
			ToWriteOff = WriteOffByDocument;
			TabularSection = DocumentData.Goods;
			ProductLinesToAdjust = TabularSection.FindRows(SearchParameters);
			For Each RowOfGoods In ProductLinesToAdjust Do
				
				If ToWriteOff = 0 Then
					Break;
				EndIf;
				
				If RowOfGoods.Count < ToWriteOff Then
					ToWriteOff = ToWriteOff - RowOfGoods.Count;
				ElsIf RowOfGoods.Count > ToWriteOff Then
					ProductLineForCheckout = TabularSection.Add();
					FillPropertyValues(ProductLineForCheckout, RowOfGoods);
				
					NewCount = RowOfGoods.Count - ToWriteOff;
					
					ProductLineForCheckout.Count = NewCount;
					ProductLineForCheckout.NumberOfPackages = Round(RowOfGoods.NumberOfPackages * NewCount / RowOfGoods.Count, 3, RoundMode.Round15as20);
					ProductLineForCheckout.Price = Round(RowOfGoods.Price * NewCount / RowOfGoods.Count, 2, RoundMode.Round15as20);
					ProductLineForCheckout.Sum = Round(RowOfGoods.Sum * NewCount / RowOfGoods.Count, 2, RoundMode.Round15as20);
					ProductLineForCheckout.VATAmount = Round(RowOfGoods.VATAmount * NewCount / RowOfGoods.Count, 2, RoundMode.Round15as20);
					ProductLineForCheckout.AmountIncludingVAT = Round(RowOfGoods.AmountIncludingVAT * NewCount / RowOfGoods.Count, 2, RoundMode.Round15as20);
					ProductLineForCheckout.AmountARAP = Round(RowOfGoods.AmountARAP * NewCount / RowOfGoods.Count, 2, RoundMode.Round15as20);
					ProductLineForCheckout.AmountVATARAP = Round(RowOfGoods.AmountVATARAP * NewCount / RowOfGoods.Count, 2, RoundMode.Round15as20);
					
					RowOfGoods.Count = ToWriteOff;
					RowOfGoods.NumberOfPackages = RowOfGoods.NumberOfPackages - ProductLineForCheckout.NumberOfPackages;
					RowOfGoods.Price = RowOfGoods.Price - ProductLineForCheckout.Price;
					RowOfGoods.Sum = RowOfGoods.Sum - ProductLineForCheckout.Sum;
					RowOfGoods.VATAmount = RowOfGoods.VATAmount - ProductLineForCheckout.VATAmount;
					RowOfGoods.AmountIncludingVAT = RowOfGoods.AmountIncludingVAT - ProductLineForCheckout.AmountIncludingVAT;
					RowOfGoods.AmountARAP = RowOfGoods.AmountARAP - ProductLineForCheckout.AmountARAP;
					RowOfGoods.AmountVATARAP = RowOfGoods.AmountVATARAP - ProductLineForCheckout.AmountVATARAP;
					
					ToWriteOff = 0;
				
				Else // String of goods.Quantity = to the list - just remove the sign for the goods to be formalized
					ToWriteOff = 0;
				EndIf;
				RowOfGoods.ByUninvoicedGoods = False;
				If DocumentsToBeCorrected.ThisIsTransferOfGoodsBetweenOrganizations Then
					RowOfGoods.InventoryOwnerAttribute = Undefined;
				EndIf;
				
			EndDo;
			
			// We distribute the lines of inventory types so that the filling of inventory types works only on lines not "by registration".
			ToWriteOff = WriteOffByDocument;
			TabularSection = DocumentData.InventoryKinds;
			If DocumentsToBeCorrected.SpecifyCCDNumbers Then
				SearchParameters = New Structure("ItemsLocationAttributes, CCDNumber, ByUninvoicedGoods");
			Else
				SearchParameters = New Structure("ItemsLocationAttributes, ByUninvoicedGoods");
			EndIf;
			FillPropertyValues(SearchParameters, Selection);
			RowsTypesOfStocksToAdjust = TabularSection.FindRows(SearchParameters);
			For Each OtherTypesOfStocks In RowsTypesOfStocksToAdjust Do
				
				If ToWriteOff = 0 Then
					Break;
				EndIf;
				
				If OtherTypesOfStocks.Count < ToWriteOff Then
					ToWriteOff = ToWriteOff - OtherTypesOfStocks.Count;
				ElsIf OtherTypesOfStocks.Count > ToWriteOff Then
					LineTypesOfInventoryForRegistration = TabularSection.Add();
					FillPropertyValues(LineTypesOfInventoryForRegistration, OtherTypesOfStocks);
				
					NewCount = OtherTypesOfStocks.Count - ToWriteOff;
					
					LineTypesOfInventoryForRegistration.Count = NewCount;
					LineTypesOfInventoryForRegistration.NumberOfPackages = Round(OtherTypesOfStocks.NumberOfPackages * NewCount / OtherTypesOfStocks.Count, 3, RoundMode.Round15as20);
					LineTypesOfInventoryForRegistration.VATAmount = Round(OtherTypesOfStocks.VATAmount * NewCount / OtherTypesOfStocks.Count, 2, RoundMode.Round15as20);
					LineTypesOfInventoryForRegistration.AmountIncludingVAT = Round(OtherTypesOfStocks.AmountIncludingVAT * NewCount / OtherTypesOfStocks.Count, 2, RoundMode.Round15as20);
					LineTypesOfInventoryForRegistration.AmountARAP = Round(OtherTypesOfStocks.AmountARAP * NewCount / OtherTypesOfStocks.Count, 2, RoundMode.Round15as20);
					LineTypesOfInventoryForRegistration.AmountVATARAP = Round(OtherTypesOfStocks.AmountVATARAP * NewCount / OtherTypesOfStocks.Count, 2, RoundMode.Round15as20);
					
					OtherTypesOfStocks.Count = ToWriteOff;
					OtherTypesOfStocks.NumberOfPackages = OtherTypesOfStocks.NumberOfPackages - LineTypesOfInventoryForRegistration.NumberOfPackages;
					OtherTypesOfStocks.VATAmount = OtherTypesOfStocks.VATAmount - LineTypesOfInventoryForRegistration.VATAmount;
					OtherTypesOfStocks.AmountIncludingVAT = OtherTypesOfStocks.AmountIncludingVAT - LineTypesOfInventoryForRegistration.AmountIncludingVAT;
					OtherTypesOfStocks.AmountARAP = OtherTypesOfStocks.AmountARAP - LineTypesOfInventoryForRegistration.AmountARAP;
					OtherTypesOfStocks.AmountVATARAP = OtherTypesOfStocks.AmountVATARAP - LineTypesOfInventoryForRegistration.AmountVATARAP;
					
					ToWriteOff = 0;
				
				Else // String of goods.Quantity = to the list - just remove the sign for the goods to be formalized
					ToWriteOff = 0;
				EndIf;
				TabularSection.Delete(OtherTypesOfStocks);
				
			EndDo;
			
			DocumentCache.Insert(DocumentsToBeCorrected.Ref, DocumentData); // we write documents to the IB only once, at the very end.
		EndDo;
	
		If QuantityIsNegative <> 0 Then
			If QuantityIsNegative > QuantityInAdjustments Then
				MessageText = NStr("vi = 'Lỗi trong thuật toán chỉnh sửa số dư cho hàng hóa cần chuyển giao.
				|Hãy liên hệ với nhà phát triển chương trình.';
				|ru = 'Ошибка в алгоритме исправления остатков по товарам к передаче.
				|Обратитесь к разработчикам программы.';
				|en = 'An error occurred in the correction algorithm of stock balance to transfer.
				|Contact application developers.'; fa = 'An error occurred in the correction algorithm of stock balance to transfer.
				|Contact application developers.';
				|it = 'Errore nell''algoritmo di correzione dei saldi per merci in trasferimento.
				|Rivolgersi al processore del programma.';
				|pl = 'Błąd w algorytmie sprostowania pozostałości wg towarów do przekazania.
				|Zwróć się do programistów programu.';
				|tr = 'Transfer edilecek ürünler için bakiyeleri düzeltme algoritmasında hata.
				|Program geliştiricileriyle iletişime geç.'");
				Raise MessageText;
			Else
				MessageText = NStr("vi = 'Lỗi chỉnh sửa số dư theo hàng hóa cần chuyển giao: 
				|có những biến động chi phí quá mức khi điều chỉnh biểu ghi theo chiều đo 
				|%Organization% - %ItemsLocationAttributes% - %InventoryOwnerAttribute% - %CCDNumber%,
				|chi phí thừa %QuantityIsNegative%. Cần điều chỉnh bản ghi kết chuyển của chứng từ và kết chuyển thủ công.';
				|ru = 'Ошибка исправления остатков по товарам к передаче: 
				|есть избыточные расходные движения в корректировках регистров по измерениям 
				|%Organization% - %ItemsLocationAttributes% - %InventoryOwnerAttribute% - %CCDNumber%,
				|лишний расход %QuantityIsNegative%. Необходимо скорректировать движения документов и провести вручную.';
				|en = 'An error occurred while correcting the stock balance for transfer:
				|there are excessive expense movements in register adjusting entries by dimensions 
				|%Organization% - %ItemsLocationAttributes% - %InventoryOwnerAttribute% - %CCDNumber%,
				|excessive expense %QuantityIsNegative%. Adjust document register records and post manually.'; fa = 'An error occurred while correcting the stock balance for transfer:
				|there are excessive expense movements in register adjusting entries by dimensions 
				|%Organization% - %ItemsLocationAttributes% - %InventoryOwnerAttribute% - %CCDNumber%,
				|excessive expense %QuantityIsNegative%. Adjust document register records and post manually.';
				|it = 'Errore di correzione dei saldi per merce in trasferimento:
				|ci sono movimenti di spesa ridondanti negli aggiustamenti del registro per misurazioni
				|%Organization% - %ItemsLocationAttributes% - %InventoryOwnerAttribute% - %CCDNumber%,
				| spesa ulteriore %QuantityIsNegative%. Risulta necessario coreggere i movimenti dei documenti ed eseguirli manualmente.';
				|pl = 'Błąd sprostowania pozostałości wg towarów do przekazania: 
				|istnieją nadmierne przepływy rozchodów w zapisach korygujących rejestrów wg pomiarów 
				|%Organization% - %ItemsLocationAttributes% - %InventoryOwnerAttribute% - %CCDNumber%,
				|zbędny rozchód %QuantityIsNegative%. Trzeba skorygować przepływy dokumentów i zatwierdzić ręcznie.';
				|tr = 'Transfer edilecek ürünler için bakiyeleri düzeltme hatası: 
				|boyutlara göre düzeltme kayıtlarında fazla gider hareketleri mevcut 
				|%Organization% - %ItemsLocationAttributes% - %InventoryOwnerAttribute% - %CCDNumber%,
				|fazladan gider%QuantityIsNegative%. Belge kayıtlarının manuel olarak düzeltilmesi ve kaydedilmesi gerekir.'");
				MessageText = StrReplace(MessageText, "%Organization%", String(Selection.CompanyOwner));
				MessageText = StrReplace(MessageText, "%ItemsLocationAttributes%", String(Selection.ItemsLocationAttributes));
				MessageText = StrReplace(MessageText, "%InventoryOwnerAttribute%", String(Selection.SellerInventoryOwnerAttribute));
				MessageText = StrReplace(MessageText, "%CCDNumber%", String(Selection.CCDNumber));
				MessageText = StrReplace(MessageText, "%QuantityIsNegative%", String(QuantityIsNegative));
				
				ExceptionString = NStr("vi = '%1 chỉnh sửa số dư';
										|ru = '%1 исправления остатков';
										|en = '%1 balance corrections'; fa = '%1 balance corrections';
										|it = '%1 correzione saldi';
										|pl = '%1 korekty sald';
										|tr = '%1 bakiyeleri düzeltme'",
					Common.DefaultLanguageCode());
				ExceptionString = StrTemplate(ExceptionString, "CorrectNegativeBalance.Error");
				WriteLogEvent(
					ExceptionString,
					EventLogLevel.Error,
					,
					,
					MessageText);
				CommonClientServer.MessageToUser(MessageText);
			EndIf;
		EndIf;
				
	EndDo;
	
	DocumentsArray = New Array;
	For Each CacheItem In DocumentCache Do
		DocumentsArray.Add(CacheItem.Key);
	EndDo;
	
	MaxIndex = DocumentsArray.UBound();
	For i = 0 To MaxIndex Do
		
		CurDocument = DocumentsArray[MaxIndex - i];
		
		DocumentObject = CurDocument.GetObject();
		DocumentObject.Goods.Load(DocumentCache[CurDocument].Goods);
		DocumentObject.InventoryKinds.Load(DocumentCache[CurDocument].InventoryKinds);
		Try
			DocumentObject.Write(DocumentWriteMode.Posting);
			ResultOfCarryingOut = NStr("vi = 'truyền lại thành công.';
										|ru = 'перепроведен успешно.';
										|en = 'reposted successfully.'; fa = 'reposted successfully.';
										|it = 'Eseguito con successo.';
										|pl = 'jest pomyślnie zaksięgowany ponownie.';
										|tr = 'başarıyla yeniden kaydedildi.'");
		Except
			ErrorInfo = DetailErrorDescription(ErrorInfo());
			ResultOfCarryingOut = NStr("vi = 'Xảy ra lỗi. Cần phải hủy bỏ kết chuyển và kết chuyển lại thủ công.';
										|ru = 'Ошибка при проведении. Необходимо отменить проведение и провести вручную.';
										|en = 'An error occurred while posting. Cancel posting and post manually.'; fa = 'An error occurred while posting. Cancel posting and post manually.';
										|it = 'Errore durante l''esecuzione. È necessario annullare l''esecuzione ed eseguire manualmente.';
										|pl = 'Błąd podczas księgowania. Należy anulować księgowanie i zaksięgować ręcznie.';
										|tr = 'Kayıt sırasında hata. Kaydı iptal etmeli ve manuel olarak yeniden kaydetmeli.'");
			
			
			ExceptionText = NStr("vi = '%Couples1% kết chuyển lại chứng từ';
								|ru = '%Couples1% перепроведения документа';
								|en = '%Couples1% of document reposting'; fa = '%Couples1% of document reposting';
								|it = '%Couples1% ripubblicazione del documento';
								|pl = '%Couples1% ponownego zatwierdzenia dokumentu';
								|tr = '%Couples1% belgenin yeniden kaydı'",
			Common.DefaultLanguageCode());
			ExceptionText = StrReplace(ExceptionText, "%Couples1%", "CorrectNegativeBalance.Error");
			
			WriteLogEvent(
			ExceptionText,
				EventLogLevel.Error,
				DocumentObject.Metadata(),
				,
				ErrorInfo);
		EndTry;
		StatusOfDocuments_.Insert(CurDocument, ResultOfCarryingOut);
	EndDo;
	
	If CallParameters.Property("StorageAddress") Then
		PutToTempStorage(StatusOfDocuments_, CallParameters.StorageAddress);
	EndIf;
	
	SessionParameters.PostWithoutControlOfCompanyStockBalance = InitialConductWithoutControlOfRemainingGoods;
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Other

// Performs the setting of the session. Called from the session module.
//
// Parameters:
//   ParameterName           - String - name of the session parameter.
//   SpecifiedParameters - Array - an array of all set parameters of the session.
//
Procedure SetSessionParameters(ParameterName, SpecifiedParameters) Export
	
	SessionParameters.PostWithoutControlOfCompanyStockBalance = False;
	
	If ParameterName = "PostWithoutControlOfCompanyStockBalance" Then
		SessionParameters.PostWithoutControlOfCompanyStockBalance = False;
		SpecifiedParameters.Add(ParameterName);
	EndIf;

EndProcedure

Function EventNameResidueControlDisabled() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	Return NStr("vi = 'Kiểm soát số dư hàng hóa của các doanh nghiệp';
				|ru = 'Контроль остатков товаров организаций';
				|en = 'Control of stock balance of companies'; fa = 'کنترل مانده موجودی شرکت‌ها';
				|it = 'Controllo delle giacenze di merce delle società';
				|pl = 'Kontrola pozostałości towarów firm';
				|tr = 'İş yeri ürün bakiyelerinin kontrolü'", DefaultLanguageCode);
	
EndFunction

Function NameOfAdditionalPropertyForRefillingInventoryViews() Export
	
	Return "RefillInventoryKinds";
	
EndFunction

Function NameOfFormPropsAndInventoryTypesHaveBeenChanged()
	
	Return "StockTypesHaveBeenChanged";
	
EndFunction

// The procedure generates a table of the remaining materials in the division.
//
// Parameters:
//	TempTablesManager - TempTablesManager - The Manager that the resulting table is placed in.
//	ParametersStructure - Structure - Building parameters: Organization, Division, return Document, Nomenclature, Characteristic.
//
Procedure TableOfMaterialBalancesInSubdivision(TempTablesManager, ParametersStructure) Export
	
	Var Department, Purpose, Products, Characteristic;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	MaterialsAndWorksInProduction.Department AS Department,
	|	MaterialsAndWorksInProduction.Products AS Products,
	|	MaterialsAndWorksInProduction.Characteristic AS Characteristic,
	|	MaterialsAndWorksInProduction.Series AS Series,
	|	MaterialsAndWorksInProduction.Purpose AS Purpose,
	|	MaterialsAndWorksInProduction.CountBalance AS Count
	|INTO TTBalances
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction.Balance(
	|			,
	|			Organization = &Organization
	|				AND (Department IN (&Department) OR &ByAllBusinessUnits)
	|				AND (Purpose = &Purpose OR &ForAllAppointments)
	|				AND (Products = &Products
	|					AND Characteristic = &Characteristic
	|						OR &ByAllProducts)
	|	
	|	) AS MaterialsAndWorksInProduction
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterRecords.Department,
	|	RegisterRecords.Products,
	|	RegisterRecords.Characteristic,
	|	RegisterRecords.Series,
	|	RegisterRecords.Purpose,
	|	RegisterRecords.Count
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction AS RegisterRecords
	|
	|WHERE
	|	RegisterRecords.Recorder = &DocumentException
	|				AND (RegisterRecords.Department IN(&Department)
	|					OR &ByAllBusinessUnits)
	|				AND (RegisterRecords.Purpose = &Purpose
	|					OR &ForAllAppointments)
	|				AND (RegisterRecords.Products = &Products
	|					AND RegisterRecords.Characteristic = &Characteristic
	|						OR &ByAllProducts)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceTable.Department AS Department,
	|	BalanceTable.Products AS Products,
	|	BalanceTable.Characteristic AS Characteristic,
	|	BalanceTable.Series AS Series,
	|	SUM(BalanceTable.Count) AS Count,
	|	BalanceTable.Purpose AS Purpose
	|INTO BalanceTable
	|FROM
	|	TTBalances AS BalanceTable
	|
	|GROUP BY
	|	BalanceTable.Department,
	|	BalanceTable.Products,
	|	BalanceTable.Characteristic,
	|	BalanceTable.Series,
	|	BalanceTable.Purpose";
	
	ParametersStructure.Property("Products",	Products);
	ParametersStructure.Property("Characteristic",	Characteristic);
	ParametersStructure.Property("Department",	Department);
	ParametersStructure.Property("Purpose",		Purpose);
	
	Query.SetParameter("Organization",		ParametersStructure.Organization);
	Query.SetParameter("DocumentException",	ParametersStructure.DocumentReturnPolicy);
	Query.SetParameter("Purpose",			Purpose);
	Query.SetParameter("ForAllAppointments",	Not ValueIsFilled(Purpose));
	Query.SetParameter("Products",		Products);
	Query.SetParameter("ByAllProducts",	Not ValueIsFilled(Products));
	Query.SetParameter("Characteristic",		Characteristic);
	
	If TypeOf(Department) = Type("CatalogRef.BusinessStructure") And ValueIsFilled(Department) Then
		
		Query.SetParameter("Department",			CommonClientServer.ValueInArray(Department));
		Query.SetParameter("ByAllBusinessUnits",	False);
		
	ElsIf TypeOf(Department) = Type("Array")
		And Department.Count() > 0 Then
		
		Query.SetParameter("Department",			Department);
		Query.SetParameter("ByAllBusinessUnits",	False);
		
	Else
		Query.SetParameter("Department",			Undefined);
		Query.SetParameter("ByAllBusinessUnits",	True);
	EndIf;
	
	Query.Execute();
	
EndProcedure

// This method prepares data for the report "organization product Balances".
//
// Parameters:
//	DocumentObject - DocumentObject - The document to generate the report for.
//	TempTablesManager - TempTablesManager - Contains a temporary table of goods Tables, 
//														the prepared data is placed in the Manager.
//	ParametersForFillingInventoryTypes - Structure - The fill parameters, See InventoriesServer.ParametersForFillingInventoryTypes.
//
Procedure PrepareDataForReport(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes) Export
	
	GenerateTTAvailableInventoryTypes(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes, "");
	GenerateTTSelectionsOfBalancesForProductTable(TempTablesManager, False);
	PreserveOriginalRegisteredRecordsOfGoodsAndReserves(DocumentObject.Ref, TempTablesManager);
	
EndProcedure

// Fills in information fields in the message text.
//
// Parameters:
//	MessageText - String - Message text template.
//	Recorder - DocumentRef - link to the document.
//	Selection - QueryResultSelection - Data source to fill in.
//
Procedure FillInGeneralParametersForErrorMessagesForOrganizationsProductsAndReserves(MessageText,
																								Recorder,
																								Selection) Export
	
	MessageText = StrReplace(MessageText, "%Recorder%", Recorder);
	MessageText = StrReplace(MessageText, "%Organization%", Selection.Organization);
	MessageText = StrReplace(MessageText, "%DimensionOfProductItem%", Selection.ItemsLocationAttributes);
	MessageText = StrReplace(MessageText, "%InventoryOwnerAttribute%", Selection.InventoryOwnerAttribute);
	
	If ValueIsFilled(Selection.CCDNumber) Then
		MessageText = StrReplace(MessageText, "%CCDNumber%", TrimAll(Selection.CCDNumber));
	Else
		MessageText = StrReplace(MessageText, "%CCDNumber%", NStr("vi = '<không có số TKHQ>';
																	|ru = '<без номера ГТД>';
																	|en = '<without CCD number>'; fa = '<without CCD number>';
																	|it = '<senza numero di dichiarazione doganale>';
																	|pl = '<bez numeru ŁDC>';
																	|tr = '<GKB numarası olmadan>'"));
	EndIf;
	
	MessageText = StrReplace(MessageText, "%Month%", Format(Selection.Period, NStr("vi = 'ДФ=''ММММ гггг''';
																					|ru = 'ДФ=''MMMM гггг''';
																					|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																					|it = 'ДФ=''ММММ гггг''';
																					|pl = 'DF=''MMMM yyyy''';
																					|tr = 'DF=''MMMM yyyy'''")));
	
EndProcedure

// Returns the date when current balances are stored
// 
// Returns:
// 	Date - date of storage of current balances
//
Function DateOfCurrentBalances() Export
	
	Return '30000101';
	
EndFunction

#EndRegion

#Region Exchanges

// Fills in the details that store information about the types of stocks and inventory accounting analysts in the tabular parts of the goods
// of the document, and also fills in the tabular parts of the types of stocks.
//
// Parameters:
//	Object - DocumentObject - the document for which you need to fill in the information.
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - Structure, Undefined - a collection containing information about the data of the tabular parts
//													of the goods of the document.
//
Procedure FillOutTypesOfStockWhenExchanging(Object, Cancel, DocumentTables = Undefined) Export
	
	ManagerOfDocument	= Common.ObjectManagerByRef(Object.Ref);
	DocumentMechanisms	= DocumentsPosting.DocumentAccountingMechanisms(ManagerOfDocument);
	
	If DocumentMechanisms.Find("OperationalAccountingOfGoodsOfOrganizations") = Undefined Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		Object.FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables);
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// Registers data for setting the use of a routine reserve rollup task.
//
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataForSettingUseOfRoutineTaskOfConvolutionOfReserves(Parameters) Export
	
	// Data registration is not required, because routine tasks are not used as
	// data for which changes need to be registered.
	Return;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

#Region CorrectDuplicatesOfInventoryOwnerAttributes

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - ValueTable - table of stages (See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable)
//                                   .
//	CurrentParent - String - group ID.
//
Procedure AddStage_CorrectDuplicatesOfInventoryOwnerAttributes(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable,
															CurrentParent,
															Catalogs.MonthEndClosingOperations.CorrectDuplicatesOfInventoryOwnerAttributes,
															True,
															False,
															False);
	
	NewRow.MultilingualName = "vi = 'Sửa lỗi trùng lặp dạng hàng tồn kho';
								|ru = 'Исправление дублей видов запасов';
								|en = 'Correct duplicates of inventory owner attributes';
								|it = 'Sostituzione dei duplicati dei tipi delle scorte';
								|pl = 'Poprawianie duplikatów rodzajów zapasów';
								|tr = 'Yinelenen stok türlerinin düzeltilmesi'"; // @NStr-1
	NewRow.PerformedManually		= True;
	NewRow.TextExecute			= NStr("vi = 'Chỉnh sửa';
										|ru = 'Исправить';
										|en = 'Correct'; fa = 'اصلاح';
										|it = 'Correggere';
										|pl = 'Correct';
										|tr = 'Düzelt'");
	NewRow.ActionUse	= MonthEndTransactionsServer.ActionDescription_ServerProcedure(
											"InventoriesServer.Use_FixDuplicatesOfStockViews");
	NewRow.ActionExecute		= MonthEndTransactionsServer.ActionDescription_OpenForm(
										Metadata.Catalogs.InventoryKinds.Forms.ListForm.FullName());
	
EndProcedure

Procedure Use_FixDuplicatesOfStockViews(HandlerParameters) Export
	
	Query = New Query;
	Query.Text = Catalogs.InventoryKinds.RequestTextAvailabilityOfDuplicateInventoryTypes();
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		MonthEndTransactionsServer.NoNeedToSetState(HandlerParameters,
															NStr("vi = 'Không tìm thấy loại hàng tồn kho trùng lặp.';
																|ru = 'Дублей видов запасов не найдено.';
																|en = 'Duplicate of inventory owner attributes are not found.'; fa = 'Duplicate of inventory owner attributes are not found.';
																|it = 'Tipi delle scorte doppi non trovati.';
																|pl = 'Duplikatów rodzajów zapasów nie znaleziono.';
																|tr = 'Stok türleri tekrarları bulunmadı.'",
																Common.DefaultLanguageCode()));
		
	Else
		
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			NStr("vi = 'Các loại hàng tồn kho trùng lặp được tìm thấy. Cần thay thế trùng lặp và xóa các loại hàng tồn kho được đánh dấu.';
				|ru = 'Обнаружены дубли видов запасов. Требуется выполнить замену дублей и удалить помеченные виды запасов.';
				|en = 'Duplicates of inventory owner attributes are found. Replace duplicates and remove the selected inventory owner attributes.'; fa = 'Duplicates of inventory owner attributes are found. Replace duplicates and remove the selected inventory owner attributes.';
				|it = 'Tipi delle scorte doppi trovati. È necessario rimpiazzare i doppioni e rimuovere i tipi delle scorte contrassegnati.';
				|pl = 'Wykryto duplikaty rodzajów zapasów. Należy wykonać wymianę duplikatów i usunąć zaznaczone rodzaje zapasów.';
				|tr = 'Tekrarlanan stok türleri bulundu. Tekrarlananların değiştirilmesi ve işaretli stok türlerinin silinmesi gerekmektedir.'",
				Common.DefaultLanguageCode()),
			,
			,
			Enums.AccountingIssueSeverity.Error);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CorrectErrorsInInitialData

Procedure ObsoleteInventoryTypesWithBalancesUpdateRecords(CheckParameters) Export
	
	InformationRegisters.ObsoleteInventoryOwnerAttributesWithBalance.UpdateRecords();
	
EndProcedure

Procedure CheckingCorrectnessOfImplementationSpecifiedInReturn(CheckParameters) Export
	
	QueryText =
	"SELECT DISTINCT
	|	T.Organization 					AS Organization,
	|	T.Recorder 					AS Return,
	|	T.DocumentSource 				AS SaleOfGoodsAndServices,
	|	T.CorItemsLocationAttributes AS AnalysisOfAccountingForImplementationProducts,
	|	T.CorInventoryOwnerAttribute 				AS TypeOfSalesStocks,
	|	T.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute 					AS InventoryOwnerAttribute
	|INTO TTAllMotionReturns
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|
	|WHERE
	|	&BatchAccountingVersion22
	|	AND T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.Recorder REFS Document.ReturnOfGoodsFromCustomer
	|	AND T.DocumentSource REFS Document.CustomerInvoice
	|INDEX BY
	|	Return
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization 							AS Organization,
	|	T.Return 								AS Return,
	|	T.SaleOfGoodsAndServices 							AS SaleOfGoodsAndServices,
	|	T.AnalysisOfAccountingForImplementationProducts	AS AnalysisOfAccountingForImplementationProducts,
	|	T.TypeOfSalesStocks 					AS TypeOfSalesStocks,
	|	T.ItemsLocationAttributes 			AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute 							AS InventoryOwnerAttribute
	|INTO TTMovementOfRefunds
	|FROM
	|	TTAllMotionReturns AS T
	|	INNER JOIN Document.ReturnOfGoodsFromCustomer.InventoryKinds AS Returns
	|		ON T.Return = Returns.Ref
	|		AND T.ItemsLocationAttributes = Returns.ItemsLocationAttributes
	|		AND T.InventoryOwnerAttribute = Returns.InventoryOwnerAttribute
	|
	|WHERE
	|	Returns.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|
	|INDEX BY
	|	Organization,
	|	SaleOfGoodsAndServices,
	|	AnalysisOfAccountingForImplementationProducts,
	|	TypeOfSalesStocks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.SaleOfGoodsAndServices,
	|	T.SaleOfGoodsAndServices AS Recorder
	|INTO TTImplementation
	|FROM
	|	TTMovementOfRefunds AS T
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	T.SaleOfGoodsAndServices,
	|	Adjusting.Ref AS Recorder
	|FROM
	|	TTMovementOfRefunds AS T
	|	INNER JOIN Document.SaleAdjustment AS Adjusting
	|		ON Adjusting.DocumentBasis = T.SaleOfGoodsAndServices  	
	|
	|INDEX BY
	|	SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization 					AS Organization,
	|	SalesOfGoodsAndServices.SaleOfGoodsAndServices			AS SaleOfGoodsAndServices,
	|	T.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute 					AS InventoryOwnerAttribute
	|INTO TTMovementImplementations
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN TTImplementation AS SalesOfGoodsAndServices
	|		ON T.Recorder = SalesOfGoodsAndServices.Recorder
	|WHERE
	|	&BatchAccountingVersion22
	|	AND T.Period <= &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|
	|INDEX BY
	|	Organization,
	|	SaleOfGoodsAndServices,
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Returns.Organization 						  AS Organization,
	|	Returns.Return 							  AS Return,
	|	Returns.SaleOfGoodsAndServices 						  AS SaleOfGoodsAndServices,
	|	Returns.AnalysisOfAccountingForImplementationProducts AS ItemsLocationAttributes,
	|	Returns.TypeOfSalesStocks 				  AS InventoryOwnerAttribute
	|INTO TTRefundDiscrepancies
	|FROM
	|	TTMovementOfRefunds AS Returns
	|	LEFT JOIN TTMovementImplementations AS SalesOfGoodsAndServices
	|		ON Returns.Organization = SalesOfGoodsAndServices.Organization
	|			AND Returns.SaleOfGoodsAndServices = SalesOfGoodsAndServices.SaleOfGoodsAndServices
	|			AND Returns.AnalysisOfAccountingForImplementationProducts = SalesOfGoodsAndServices.ItemsLocationAttributes
	|			AND (Returns.TypeOfSalesStocks = SalesOfGoodsAndServices.InventoryOwnerAttribute
	|				OR SalesOfGoodsAndServices.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef))
	|
	|WHERE
	|	SalesOfGoodsAndServices.SaleOfGoodsAndServices IS NULL";
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 				NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Company';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Return",						NStr("vi = 'Chứng từ trả lại';
														|ru = 'Документ возврата';
														|en = 'Returns document'; fa = 'سند برگشت‌ها';
														|it = 'Documento di reso';
														|pl = 'Dokument zwrotu';
														|tr = 'İade belgesi'", Common.DefaultLanguageCode()));
	FieldList.Add("SaleOfGoodsAndServices",					NStr("vi = 'Chứng từ bán hàng';
																	|ru = 'Документ реализации';
																	|en = 'Sales document'; fa = 'سند فروش';
																	|it = 'Documento di vendita';
																	|pl = 'Dokument sprzedaży';
																	|tr = 'Satış belgesi'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes",	NStr("vi = 'Chỉ số mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute",					NStr("vi = 'Dạng hàng tồn kho';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTRefundDiscrepancies",
		NStr("vi = 'Tìm thấy hàng trả lại từ khách hàng không có trong chứng từ của doanh nghiệp ""%1""';
			|ru = 'Обнаружены возвращенные от клиента товары, отсутствующие в документе реализации организации ""%1""';
			|en = 'Goods returned from the customer that are missing in the sales document of the ""%1"" company are detected'; fa = 'Goods returned from the customer that are missing in the sales document of the ""%1"" company are detected';
			|it = 'Trovati dei prodotti restituiti da un cliente che non si trovano nel documento di realizzo dell''organizzazione ""%1""';
			|pl = 'Wykryto zwrócone od klienta wiersze pozycji, brakujące w dokumencie sprzedaży firmy ""%1""';
			|tr = 'Müşteriden iade edilen ürünler, iş yerinin ""%1"" satış belgesinde bulunamadı'", Common.DefaultLanguageCode()),
		FieldList,
		"Return");
	
	MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters,
																	RegistrationParameters,
																	QueryText);
	
EndProcedure

Procedure CheckingCorrectnessOfFillingInAmountsInCommissionReportsBetweenOrganizations(CheckParameters) Export
	
	QueryText = 
	"SELECT
	|	ReportProducts.Organization  AS Organization,
	|	ReportProducts.Ref       AS ReportOnCommission,
	|	ReportProducts.ItemsLocationAttributes AS DocumentReport_,
	|	SUM(ReportProducts.Sum) AS Sum
	|INTO TTCommissionReportsBetweenOrganizations
	|FROM
	|	(SELECT
	|		ReportOnCommission.Organization AS Organization,
	|		ReportOnCommission.Ref      AS Ref,
	|		ReportProducts.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		ReportProducts.SalesAmount   AS Sum
	|	FROM
	|		Document.CommissionReportIntercompany.Goods AS ReportProducts
	|			INNER JOIN Document.CommissionReportIntercompany AS ReportOnCommission
	|			ON ReportProducts.Ref = ReportOnCommission.Ref
	|		
	|			LEFT JOIN Catalog.Products AS ProductsTable
	|			ON ReportProducts.Products = ProductsTable.Ref
	|	WHERE
	|		ReportOnCommission.Posted
	|		AND ReportOnCommission.Organization IN(&CompanyArray)
	|		AND ReportOnCommission.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ISNULL(ProductsTable.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) IN(
	|			VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnCommission.Organization AS Organization,
	|		ReportOnCommission.Ref      AS Ref,
	|		ReportInventory.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		-ReportInventory.AmountIncludingVAT     AS Sum
	|	FROM
	|		Document.CommissionReportIntercompany.InventoryKinds AS ReportInventory
	|			INNER JOIN Document.CommissionReportIntercompany AS ReportOnCommission
	|			ON ReportInventory.Ref = ReportOnCommission.Ref
	|	WHERE
	|		ReportOnCommission.Posted
	|		AND ReportOnCommission.Organization IN(&CompanyArray)
	|		AND ReportOnCommission.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	
	|	) AS ReportProducts
	|
	|GROUP BY
	|	ReportProducts.Organization,
	|	ReportProducts.Ref,
	|	ReportProducts.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(ReportProducts.Sum) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ReportProducts.Organization     AS Organization,
	|	ReportProducts.ReportOnCommission AS ReportOnCommission
	|INTO IncorrectAmountsOfCommissionReportsBetweenOrganizations
	|FROM
	|	TTCommissionReportsBetweenOrganizations AS ReportProducts";
	
	ObjectFieldName = "ReportOnCommission";
	
	TempTableName = "IncorrectAmountsOfCommissionReportsBetweenOrganizations";
	ErrorTextTemplate  = NStr("vi = 'Tìm thấy bảng kê bán hàng ký gửi giữa các doanh nghiệp có số tiền không chính xác theo doanh nghiệp ""%1"" trong kỳ %2';
								|ru = 'Обнаружены отчеты по комиссии между организациями с некорректными суммовыми показателями по организации ""%1"" за период %2';
								|en = '""Commission reports — Intercompany"" with incorrect sum indicators for the company ""%1"" for the period %2 are found'; fa = '""Commission reports — Intercompany"" with incorrect sum indicators for the company ""%1"" for the period %2 are found';
								|it = 'Sono stati trovati dei report di commissione tra aziende con importi totali non corretti per l''azienda ""%1"" nel periodo %2';
								|pl = 'Wykryto raporty według prowizji między firmami z nieprawidłowymi zsumowanymi wskaźnikami według firmy ""%1"" za okres %2';
								|tr = 'İş yerleri arasında komisyon raporları, %2 dönemi için ""%1"" iş yeri için hatalı tutarlarda bulundu'",
								Common.DefaultLanguageCode());
	
	FieldList = New ValueList;
	FieldList.Add("Organization",  NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add(ObjectFieldName, NStr("vi = 'Bảng kê hàng bán ký gửi giữa các doanh nghiệp';
										|ru = 'Отчет по комиссии между организациями';
										|en = 'Commission sales report — Intercompany'; fa = 'گزارش فروش حق‌العملی — بین‌شرکتی';
										|it = 'Report sulla commissione tra le organizzazioni';
										|pl = 'Raport po komisji sprawdzającej pomiędzy firmami';
										|tr = 'İşyerleri arası komisyon satış raporu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(TempTableName,
																									ErrorTextTemplate,
																									FieldList,
																									ObjectFieldName);
	
	MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters, RegistrationParameters, QueryText);
	
EndProcedure

#EndRegion

#Region CorrectNegativeStockBalanceOfCompanyGoods

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable  - ValueTable - table of stages (See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable)
//                                    .
//	CurrentParent - String - group ID.
//
Procedure AddStage_CorrectNegativeStockBalanceOfCompanyGoods(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.CorrectNegativeStockBalanceOfCompanyGoods);
		
	NewRow.MultilingualName = "vi = 'Điều chỉnh số dư âm hàng hóa doanh nghiệp';
								|ru = 'Исправление отрицательных остатков товаров организаций';
								|en = 'Correct negative stock balance of company goods';
								|it = 'Correzione dei saldi negativi delle rimanenze delle aziende';
								|pl = 'Poprawianie ujemnych stanów magazynowych towarów firm';
								|tr = 'İş yerleri ürünlerinin eksi bakiyelerinin düzeltilmesi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InventoriesServer.Registration_CorrectionOfNegativeBalancesOfGoodsOfOrganizations");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.WizardOfCorrectingCompanyStockBalance.Forms.DefaultForm.FullName());
	
EndProcedure

// Initializes the stage of correcting negative product balances of the organization.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Registration_CorrectionOfNegativeBalancesOfGoodsOfOrganizations(HandlerParameters) Export
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		HandlerParameters.Data_Stage.Description = NStr("vi = 'Điều chỉnh số dư âm hàng hóa doanh nghiệp';
														|ru = 'Исправление отрицательных остатков товаров организации';
														|en = 'Correct negative stock balance of the company goods'; fa = 'Correct negative stock balance of the company goods';
														|it = 'Correzione dei saldi negativi delle rimanenze dell''organizzazione';
														|pl = 'Sprostowanie ujemnych pozostałości towarów firmy';
														|tr = 'İş yerinin ürünlerinin negatif bakiyelerinin düzeltilmesi'");
	EndIf;
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Chỉnh sửa';
													|ru = 'Исправить';
													|en = 'Correct'; fa = 'اصلاح';
													|it = 'Correggere';
													|pl = 'Correct';
													|tr = 'Düzelt'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

Procedure DescriptionOfChecks_CorrectionOfNegativeBalancesOfGoodsOfOrganizations(TableOfChecks) Export
	
	// Negative balances of goods of organizations.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"CompanyNegativeStockBalance",
		Catalogs.MonthEndClosingOperations.CorrectNegativeStockBalanceOfCompanyGoods,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"InventoriesServer.CheckingNegativeBalancesOfGoodsOfOrganizations");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Số dư âm trong sổ đăng ký ""Sản phẩm doanh nghiệp""';
			|ru = 'Отрицательные остатки в регистре ""Товары организаций""';
			|en = 'Negative stock balance in the ""Company goods"" register'; fa = 'Negative stock balance in the ""Company goods"" register';
			|it = 'Rimanenze negative nel registro ""Prodotti delle organizzazioni""';
			|pl = 'Ujemne pozostałości w rejestrze ""Товары организаций""';
			|tr = '""İş yerlerinin ürünleri"" sicilindeki negatif bakiyeler'", Common.DefaultLanguageCode()),
		NStr("vi = 'Dư lượng âm không nên.';
			|ru = 'Отрицательных остатков быть не должно.';
			|en = 'There must be no negative inventory.'; fa = 'There must be no negative inventory.';
			|it = 'Non devono esserci rimanenze negative.';
			|pl = 'Ujemnych pozostałości być nie powinno.';
			|tr = 'Negatif bakiye olmamalıdır.'", Common.DefaultLanguageCode()));
	
EndProcedure

// Determines whether there are movements in separate procurement transactions.
//
// Parameters:
//	Period - Date - the end of the period for which the movement is selected from the Accumulation register of merchandise organizations;
//		   - Undefined - a selection without a condition by period.
//
// Returns:
//	Boolean - True if there are movements of separate procurement.
//
Function ThereIsSeparateProcurementProcess(Period = Undefined) Export
	
	If Not GetFunctionalOption("UseGoodsInTransitFromVendors") And 
		 Not GetFunctionalOption("UseUninvoicedDeliveries") Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = "
		|SELECT TOP 1
		|	TRUE
		|FROM 
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|WHERE
		|	CompanyGoods.BusinessOperation IN (&SeparatePurchaseProcessingOperations)
		|	AND (CompanyGoods.ItemsLocationAttributes.Products.KeepRecordsByCCD
		|	AND CompanyGoods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef))
		|	AND CompanyGoods.Period <= &Period
		|
		|ORDER BY
		|	CompanyGoods.Period DESC";

	If Period = Undefined Then
		Query.Text = StrReplace(Query.Text, "AND CompanyGoods.Period <= &Period", "");
	EndIf;
	
	Query.SetParameter("SeparatePurchaseProcessingOperations", PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections());
	Query.SetParameter("Period", 							  Period);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Generates the text of an additional request for Conditional Cancellation Of Registered Records Of The Accumulation Register Of Organizations' Goods according to the "On the way" schemes.
// Data samples for each of the documents under consideration should be generated in accordance with the functions of the text Query tables of the organizations()
// modules of document managers.
// The "Service" field of the selection corresponds to the index in the request for the text of the request for the Organization's Product tables().
//
// Parameters:
//	 TemplatePeriod                  - String - the name of the parameter "Period"; is determined from queries that use the call to this function;
//   CorrectionsOfExpandedBalance - Boolean - a Sign Of the Formation Of Reversing RegisteredRecords for documents of correction of inverted inventory of organizations.
//
// Returns:
//	 String - query text.
//
Function StopRegisteringRecordsOfCompanyGoodsInTransit(Val TemplatePeriod = "&EndOfPeriod", Val CorrectionsOfExpandedBalance = False) Export
	
	QueryText = 
		"SELECT
		|	DocumentsRegistry.ReversedDocument AS Ref
		|INTO ReversingEntry
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.ReverseTransactionCorrection
		|	AND DocumentsRegistry.Posted
		|	AND DocumentsRegistry.IBDocumentDate <= &TemplatePeriod
		|	AND NOT DocumentsRegistry.AdditionalRecord
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentData.Date							AS Period,
		|	DocumentData.Organization						AS Organization,
		|	TableOfCorrections.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	TableOfCorrections.InventoryOwnerAttributeGoodsReceipts		AS InventoryOwnerAttribute,
		|	TableOfCorrections.CCDNumberForReceiving 		AS CCDNumber,
		|	TableOfCorrections.Count					AS NumberIsReversed,
		|	0												AS IsInternal
		|INTO CorrectionOfSidedBalanceInCompanyGoodsAccounting
		|FROM
		|	Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting.Corrections AS TableOfCorrections
		|		INNER JOIN Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting AS DocumentData
		|		ON DocumentData.Ref = TableOfCorrections.Ref
		|WHERE
		|	&CorrectionsOfExpandedBalance
		|	AND DocumentData.Posted
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND TableOfCorrections.ItemsLocationAttributes.Products.KeepRecordsByCCD
		|	AND TableOfCorrections.CCDNumberForReceiving = VALUE(Catalog.CCDNumbers.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Date							AS Period,
		|	DocumentData.Organization						AS Organization,
		|	TableOfCorrections.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	TableOfCorrections.WriteOffInventoryAttributes			AS InventoryOwnerAttribute,
		|	TableOfCorrections.CCDNumberForWriteOff				AS CCDNumber,
		|	-TableOfCorrections.Count					AS NumberIsReversed,
		|	1												AS IsInternal
		|FROM
		|	Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting.Corrections AS TableOfCorrections
		|		INNER JOIN Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting AS DocumentData
		|		ON DocumentData.Ref = TableOfCorrections.Ref
		|WHERE
		|	&CorrectionsOfExpandedBalance
		|	AND DocumentData.Posted
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND TableOfCorrections.ItemsLocationAttributes.Products.KeepRecordsByCCD
		|	AND TableOfCorrections.CCDNumberForWriteOff = VALUE(Catalog.CCDNumbers.EmptyRef)
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentData.Date								AS Period,
		|	DocumentData.Organization							AS Organization,
		|	AnalysisOfProductAccountingByPartners.DimensionKey	AS ItemsLocationAttributes,
		|	DocumentTable.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)			AS CCDNumber,
		|	CASE
		|		WHEN ReceiptData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			THEN 0
		|		ELSE 1
		|	END * DocumentTable.Count					AS NumberIsReversed,
		|	4													AS IsInternal
		|INTO PurchaseAdjustment
		|FROM
		|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
		|		INNER JOIN Document.PurchaseAdjustment AS DocumentData
		|		ON DocumentData.Ref = DocumentTable.Ref
		|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
		|		ON DocumentTable.Ref = DivergenceTable.Ref
		|			AND DocumentTable.RowCode = DivergenceTable.RowCode
		|			AND DocumentTable.PurchaseOrder = DivergenceTable.PurchaseOrder
		|			AND DocumentTable.ItemsLocationAttributes.Products = DivergenceTable.Products
		|			AND DocumentTable.ItemsLocationAttributes.Characteristic = DivergenceTable.Characteristic
		|			AND DocumentTable.ItemsLocationAttributes.Purpose = DivergenceTable.Purpose
		|			AND (DocumentTable.ItemsLocationAttributes.Series = DivergenceTable.Series
		|				OR DivergenceTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|			AND DocumentTable.PostingOption = DivergenceTable.PostingOption
		|			AND DocumentTable.CCDNumber = DivergenceTable.CCDNumber
		|		INNER JOIN Document.VendorInvoice AS ReceiptData
		|		ON DocumentData.DocumentBasis = ReceiptData.Ref
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalysisOfProductAccountingByPartners
		|		ON DocumentTable.ItemsLocationAttributes.Products = AnalysisOfProductAccountingByPartners.Products
		|			AND DocumentTable.ItemsLocationAttributes.Characteristic = AnalysisOfProductAccountingByPartners.Characteristic
		|			AND DocumentTable.ItemsLocationAttributes.Purpose = AnalysisOfProductAccountingByPartners.Purpose
		|			AND DocumentTable.ItemsLocationAttributes.Series = AnalysisOfProductAccountingByPartners.Series
		|			AND (ReceiptData.Contract = AnalysisOfProductAccountingByPartners.StorageLocation)
		|			AND DocumentTable.ItemsLocationAttributes.ProductCostElement = AnalysisOfProductAccountingByPartners.ProductCostElement
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND ReceiptData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery), 
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	AND DocumentTable.PostingOption IN (
		|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners), 
		|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners))
		// There Is No Shortage of Non-Invoicing.
		|	AND NOT (
		|		DocumentData.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|		AND DocumentData.Contract.PurchaseRegistrationOption IN (VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods),
		|															  VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices))
		|		AND DocumentTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners)
		|	)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Date								AS Period,
		|	DocumentData.Organization							AS Organization,
		|	InventoryInventoryLocationAttributeByWarehouse.DimensionKey	AS ItemsLocationAttributes,
		|	TypesOfStocksWarehouse.Ref							AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)			AS CCDNumber,
		|	CASE
		|		WHEN ReceiptData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			THEN 0
		|		ELSE 1
		|	END * -DocumentTable.Count				AS NumberIsReversed,
		|	5													AS IsInternal
		|FROM
		|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
		|		INNER JOIN Document.PurchaseAdjustment AS DocumentData
		|		ON DocumentData.Ref = DocumentTable.Ref
		|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
		|		ON DocumentTable.Ref = DivergenceTable.Ref
		|			AND DocumentTable.RowCode = DivergenceTable.RowCode
		|			AND DocumentTable.PurchaseOrder = DivergenceTable.PurchaseOrder
		|			AND DocumentTable.ItemsLocationAttributes.Products = DivergenceTable.Products
		|			AND DocumentTable.ItemsLocationAttributes.Characteristic = DivergenceTable.Characteristic
		|			AND DocumentTable.ItemsLocationAttributes.Purpose = DivergenceTable.Purpose
		|			AND (DocumentTable.ItemsLocationAttributes.Series = DivergenceTable.Series
		|				OR DivergenceTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|			AND DocumentTable.CCDNumber = DivergenceTable.CCDNumber
		|		INNER JOIN Document.VendorInvoice AS ReceiptData
		|		ON DocumentTable.Ref.DocumentBasis = ReceiptData.Ref
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryInventoryLocationAttributeByWarehouse
		|		ON DocumentTable.ItemsLocationAttributes.Products = InventoryInventoryLocationAttributeByWarehouse.Products
		|			AND DocumentTable.ItemsLocationAttributes.Characteristic = InventoryInventoryLocationAttributeByWarehouse.Characteristic
		|			AND DocumentTable.ItemsLocationAttributes.Purpose = InventoryInventoryLocationAttributeByWarehouse.Purpose
		|			AND DocumentTable.ItemsLocationAttributes.Series = InventoryInventoryLocationAttributeByWarehouse.Series
		|			AND (DivergenceTable.Warehouse = InventoryInventoryLocationAttributeByWarehouse.StorageLocation)
		|			AND DocumentTable.ItemsLocationAttributes.ProductCostElement = InventoryInventoryLocationAttributeByWarehouse.ProductCostElement
		|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
		|		ON TypesOfStocksWarehouse.Organization = DocumentTable.InventoryOwnerAttribute.Organization
		|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentTable.InventoryOwnerAttribute.GoodsOwner
		|			AND TypesOfStocksWarehouse.VATTaxation = DocumentTable.InventoryOwnerAttribute.VATTaxation
		|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentTable.InventoryOwnerAttribute.FinancialAccountingGroup
		|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentTable.InventoryOwnerAttribute.ProductsGroup
		|			AND TypesOfStocksWarehouse.PriceKind = DocumentTable.InventoryOwnerAttribute.PriceKind
		|			AND NOT TypesOfStocksWarehouse.IsDuplicate
		|			AND NOT TypesOfStocksWarehouse.Obsolete1
		|			AND NOT TypesOfStocksWarehouse.DeletionMark
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND ReceiptData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery), 
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	AND DocumentTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners)
		|	AND DocumentTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
		// There Is No Shortage of Non-Invoicing.
		|	AND NOT (
		|		DocumentData.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|		AND DocumentData.Contract.PurchaseRegistrationOption IN (VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods),
		|															  VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices))
		|	)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Date								AS Period,
		|	DocumentData.Organization							AS Organization,
		|	InventoryInventoryLocationAttributeByWarehouse.DimensionKey	AS ItemsLocationAttributes,
		|	TypesOfStocksWarehouse.Ref							AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)			AS CCDNumber,
		|	CASE
		|		WHEN ReceiptData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			THEN 0
		|		ELSE -1
		|	END * DocumentTable.Count					AS NumberIsReversed,
		|	8													AS IsInternal
		|FROM
		|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
		|		INNER JOIN Document.PurchaseAdjustment AS DocumentData
		|		ON DocumentData.Ref = DocumentTable.Ref
		|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
		|		ON DocumentTable.Ref = DivergenceTable.Ref
		|			AND DocumentTable.RowCode = DivergenceTable.RowCode
		|			AND DocumentTable.PurchaseOrder = DivergenceTable.PurchaseOrder
		|			AND DocumentTable.ItemsLocationAttributes.Products = DivergenceTable.Products
		|			AND DocumentTable.ItemsLocationAttributes.Characteristic = DivergenceTable.Characteristic
		|			AND DocumentTable.ItemsLocationAttributes.Purpose = DivergenceTable.Purpose
		|			AND (DocumentTable.ItemsLocationAttributes.Series = DivergenceTable.Series
		|				OR DivergenceTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|			AND DocumentTable.CCDNumber = DivergenceTable.CCDNumber
		|		INNER JOIN Document.VendorInvoice AS ReceiptData
		|		ON DocumentTable.Ref.DocumentBasis = ReceiptData.Ref
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryInventoryLocationAttributeByWarehouse
		|		ON DocumentTable.ItemsLocationAttributes.Products = InventoryInventoryLocationAttributeByWarehouse.Products
		|			AND DocumentTable.ItemsLocationAttributes.Characteristic = InventoryInventoryLocationAttributeByWarehouse.Characteristic
		|			AND DocumentTable.ItemsLocationAttributes.Purpose = InventoryInventoryLocationAttributeByWarehouse.Purpose
		|			AND DocumentTable.ItemsLocationAttributes.Series = InventoryInventoryLocationAttributeByWarehouse.Series
		|			AND (DivergenceTable.Warehouse = InventoryInventoryLocationAttributeByWarehouse.StorageLocation)
		|			AND DocumentTable.ItemsLocationAttributes.ProductCostElement = InventoryInventoryLocationAttributeByWarehouse.ProductCostElement
		|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
		|		ON TypesOfStocksWarehouse.Organization = DocumentTable.InventoryOwnerAttribute.Organization
		|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentTable.InventoryOwnerAttribute.GoodsOwner
		|			AND TypesOfStocksWarehouse.VATTaxation = DocumentTable.InventoryOwnerAttribute.VATTaxation
		|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentTable.InventoryOwnerAttribute.FinancialAccountingGroup
		|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentTable.InventoryOwnerAttribute.ProductsGroup
		|			AND TypesOfStocksWarehouse.PriceKind = DocumentTable.InventoryOwnerAttribute.PriceKind
		|			AND NOT TypesOfStocksWarehouse.IsDuplicate
		|			AND NOT TypesOfStocksWarehouse.Obsolete1
		|			AND NOT TypesOfStocksWarehouse.DeletionMark
		|		INNER JOIN (SELECT
		|								Goods.Ref AS Ref,
										// In two-way operation, the Status of the series indications in the Acquisition and Adjustment of the Acquisition may be zero when accounting for the series at cost.
										// Such series are explicitly indicated in the document Receipt of goods. Here it is required to find out the very fact of such a series accounting setting.
		|								MAX(Goods.BatchesIndicationStatus = 14 OR ISNULL(Policies.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)) AS AccountingOfSeriesAtCost,
		|								MAX(ISNULL(Goods.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)) AS BatchesAccountingInUninvoicedGoodsDeliveries,
		|								MAX(ISNULL(Goods.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)) AS BatchesAccountingOfGoodsInTransitFromVendor,
		|								Goods.ItemsLocationAttributes.Products AS Products
		|							FROM
		|								Document.PurchaseAdjustment.Discrepancies AS Goods
		|									LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS Policies
		|									ON Policies.Ref = Goods.ItemsLocationAttributes.Products.ProductKind
		|										AND Policies.Warehouse = Goods.Warehouse
		|							GROUP BY
		|								Goods.Ref,
		|								Goods.ItemsLocationAttributes.Products) AS SeriesStatusData
		|		ON DocumentTable.Ref = SeriesStatusData.Ref
		|			AND DocumentTable.ItemsLocationAttributes.Products = SeriesStatusData.Products
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND ReceiptData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery), 
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	AND DocumentTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners)
		// There is no surplus on goods in transit with batches at cost price.
		|	AND NOT (
		|		DocumentData.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|		AND DocumentData.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.GoodsInTransit)
		|		AND (SeriesStatusData.AccountingOfSeriesAtCost
		|			AND NOT (SeriesStatusData.BatchesAccountingInUninvoicedGoodsDeliveries
		|				OR SeriesStatusData.BatchesAccountingOfGoodsInTransitFromVendor))
		|	)
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.Ref AS Ref,
		|	MAX(GoodsTable.BatchesIndicationStatus) AS BatchesIndicationStatus,
		|	MAX(ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)) AS BatchesAccountingInUninvoicedGoodsDeliveries,
		|	MAX(ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)) AS BatchesAccountingOfGoodsInTransitFromVendor,
		|	GoodsTable.ItemsLocationAttributes.Products AS Products
		|INTO ReceiptOfGoodsAtWarehouse_TTItemParameters
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|
		|GROUP BY
		|	GoodsTable.Ref,
		|	GoodsTable.ItemsLocationAttributes.Products
		|
		|INDEX BY
		|	Ref,
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentData.Date						AS Period,
		|	DocumentData.Organization					AS Organization,
		|	GoodsTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	GoodsTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber,
		|	CASE
		|		WHEN GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
		|			THEN 1
		|		ELSE 0
		|	END * GoodsTable.Count			AS NumberIsReversed,
		|	0											AS IsInternal
		|INTO ReceiptOfGoodsToWarehouse
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
		|	AND NOT (GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
		// Series at cost (14).
		|		AND GoodsTable.BatchesIndicationStatus = 14
		|		AND NOT (ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
		|			OR ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)))
		|
		|UNION ALL
		|
		// In transit, purchase compensation for GTD with series at cost.
		|SELECT
		|	DocumentData.Date						AS Period,
		|	DocumentData.Organization					AS Organization,
		|	Analysts.DimensionKey						AS ItemsLocationAttributes,
		|	GoodsTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber,
		|	GoodsTable.Count					AS NumberIsReversed,
		|	2											AS IsInternal
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Analysts
		|		ON GoodsTable.ItemsLocationAttributes.Products = Analysts.Products
		|			AND GoodsTable.ItemsLocationAttributes.Characteristic = Analysts.Characteristic
		|			AND GoodsTable.ItemsLocationAttributes.StorageLocation = Analysts.StorageLocation
		|			AND GoodsTable.ItemsLocationAttributes.Purpose = Analysts.Purpose
		|			AND GoodsTable.ItemsLocationAttributes.ProductCostElement = Analysts.ProductCostElement
		|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = Analysts.Series
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
		|	AND GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
		// Series at cost (14).
		|	AND GoodsTable.BatchesIndicationStatus = 14
		|	AND NOT (ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
		|		OR ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE))
		|
		|UNION ALL
		|
		// En route, reverse purchases for GTD (including RNPT) with series at cost price.
		|SELECT
		|	DocumentData.Date				AS Period,
		|	DocumentData.Organization			AS Organization,
		|	Analysts.DimensionKey 			AS ItemsLocationAttributes,
		|	GoodsTable.WarehouseInventoryAttributes	AS InventoryOwnerAttribute,
		|	GoodsTable.CCDNumber              AS CCDNumber,
		|	CASE
		|		WHEN GoodsTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
		|			THEN -1
		|		ELSE 0
		|	END * GoodsTable.Count	AS NumberIsReversed,
		|	3									AS IsInternal
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS GoodsTable
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Analysts
		|		ON GoodsTable.ItemsLocationAttributes.Products = Analysts.Products
		|			AND GoodsTable.ItemsLocationAttributes.Characteristic = Analysts.Characteristic
		|			AND GoodsTable.ItemsLocationAttributes.StorageLocation = Analysts.StorageLocation
		|			AND GoodsTable.ItemsLocationAttributes.Purpose = Analysts.Purpose
		|			AND GoodsTable.ItemsLocationAttributes.ProductCostElement = Analysts.ProductCostElement
		|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = Analysts.Series
		|		INNER JOIN ReceiptOfGoodsAtWarehouse_TTItemParameters AS SeriesStatusData
		|		ON GoodsTable.Ref = SeriesStatusData.Ref
		|			AND GoodsTable.ItemsLocationAttributes.Products = SeriesStatusData.Products
		|
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
		|	AND GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
		// Series at cost (14).
		|	AND (SeriesStatusData.BatchesIndicationStatus = 14
		|		AND NOT (SeriesStatusData.BatchesAccountingInUninvoicedGoodsDeliveries
		|			OR SeriesStatusData.BatchesAccountingOfGoodsInTransitFromVendor))
		|
		|UNION ALL
		|
		// Goods are on the way.
		|SELECT
		|	DocumentData.Date										AS Period,
		|	DocumentData.Organization									AS Organization,
		|	GoodsTable.ItemsLocationAttributesGoodsAtPartners	AS ItemsLocationAttributes,
		|	GoodsTable.InventoryOwnerAttribute									AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)					AS CCDNumber,
		|	-GoodsTable.Count									AS NumberIsReversed,
		|	4															AS IsInternal
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS GoodsTable
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND GoodsTable.ItemsLocationAttributesGoodsAtPartners.Products.KeepRecordsByCCD
		|	AND DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
		|
		|UNION ALL
		|
		// Non-invoice.
		|SELECT
		|	DocumentData.Date										AS Period,
		|	DocumentData.Organization									AS Organization,
		|	GoodsTable.ItemsLocationAttributesGoodsAtPartners	AS ItemsLocationAttributes,
		|	GoodsTable.InventoryOwnerAttribute									AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)					AS CCDNumber,
		|	0															AS NumberIsReversed,
		|	5															AS IsInternal
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS GoodsTable
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Date						AS Period,
		|	DocumentData.Organization					AS Organization,
		|	GoodsTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	GoodsTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber,
		|	0											AS NumberIsReversed,
		|	6											AS IsInternal
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.Ref AS Ref,
		|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsTable.CCDNumber AS CCDNumber,
		|	SUM(GoodsTable.Count) AS Count,
		|	SUM(GoodsTable.QuantityByGBRN) AS QuantityByGBRN,
		|	GoodsTable.VATRate AS VATRate,
		|	GoodsTable.Warehouse AS Warehouse,
		|	GoodsTable.PurchaseOrder AS PurchaseOrder
		|INTO PurchaseOfGoodsOfServices_TTGoodsForConnectionAnalytics
		|FROM
		|	Document.VendorInvoice.Goods AS GoodsTable
		|		INNER JOIN Document.VendorInvoice AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|
		|GROUP BY
		|	GoodsTable.Ref,
		|	GoodsTable.ItemsLocationAttributes,
		|	GoodsTable.CCDNumber,
		|	GoodsTable.VATRate,
		|	GoodsTable.PurchaseOrder,
		|	GoodsTable.Warehouse
		|
		|INDEX BY
		|	Ref,
		|	ItemsLocationAttributes,
		|	CCDNumber,
		|	PurchaseOrder,
		|	Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// Two-way.
		|SELECT
		|	DocumentData.Date						AS Period,
		|	DocumentData.Organization					AS Organization,
		// On the contract.
		|	GoodsTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	GoodsTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber,
		|	CASE
		|		WHEN DocumentData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit), 
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|				VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|			THEN 1
		|		WHEN DocumentData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			THEN 0
		|		ELSE 0
		|	END * GoodsTable.Count			AS NumberIsReversed,
		|	3											AS IsInternal
		|INTO VendorInvoice
		|FROM
		|	Document.VendorInvoice.InventoryKinds AS GoodsTable
		|		INNER JOIN Document.VendorInvoice AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND GoodsTable.ItemsLocationAttributes.Products.ItemsType IN (
		|		VALUE(Enum.ItemsTypes.OwnGoods), 
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery), 
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	AND NOT DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|	AND NOT GoodsTable.ToExpenseAs
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Date						AS Period,
		|	DocumentData.Organization					AS Organization,
		// To the warehouse.
		|	Dimension.DimensionKey						AS ItemsLocationAttributes,
		|	TypesOfStocksWarehouse.Ref					AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber,
		|	CASE
		|		WHEN DocumentData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit), 
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery))
		|			THEN -1
		|		WHEN DocumentData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			THEN 0
		|		ELSE 0
		|	END * GoodsTable.Count			AS NumberIsReversed,
		|	5											AS IsInternal
		|FROM
		|	Document.VendorInvoice.InventoryKinds AS GoodsTable
		|		INNER JOIN Document.VendorInvoice AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|		INNER JOIN PurchaseOfGoodsOfServices_TTGoodsForConnectionAnalytics AS DocumentGoods
		|		ON GoodsTable.Ref = DocumentGoods.Ref
		|			AND GoodsTable.ItemsLocationAttributes.Products = DocumentGoods.ItemsLocationAttributes.Products
		|			AND GoodsTable.ItemsLocationAttributes.Characteristic = DocumentGoods.ItemsLocationAttributes.Characteristic
		|			AND GoodsTable.ItemsLocationAttributes.Purpose = DocumentGoods.ItemsLocationAttributes.Purpose
		|			AND (GoodsTable.ItemsLocationAttributes.StorageLocation = DocumentGoods.ItemsLocationAttributes.StorageLocation
		|				OR (DocumentData.Contract = DocumentGoods.ItemsLocationAttributes.StorageLocation
		|						AND DocumentData.BusinessOperation IN (
		|							VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit), 
		|							VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|							VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|							VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery), 
		|							VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|						AND NOT DocumentData.BusinessOperation IN (
		|							VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|							VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
		|					)
		|			)
		|			AND (GoodsTable.ItemsLocationAttributes.Series = DocumentGoods.ItemsLocationAttributes.Series
		|				OR DocumentGoods.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|			AND GoodsTable.CCDNumber = DocumentGoods.CCDNumber
		|			AND GoodsTable.VATRate = DocumentGoods.VATRate
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
		|		ON GoodsTable.ItemsLocationAttributes.Products = Dimension.Products
		|			AND GoodsTable.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
		|			AND GoodsTable.ItemsLocationAttributes.Series = Dimension.Series
		|			AND GoodsTable.ItemsLocationAttributes.Purpose = Dimension.Purpose
		|			AND GoodsTable.ItemsLocationAttributes.ProductCostElement = Dimension.ProductCostElement
		|			AND DocumentGoods.Warehouse = Dimension.StorageLocation
		|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
		|		ON TypesOfStocksWarehouse.Organization = GoodsTable.InventoryOwnerAttribute.Organization
		|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|			AND TypesOfStocksWarehouse.GoodsOwner = GoodsTable.InventoryOwnerAttribute.GoodsOwner
		|			AND TypesOfStocksWarehouse.VATTaxation = GoodsTable.InventoryOwnerAttribute.VATTaxation
		|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = GoodsTable.InventoryOwnerAttribute.FinancialAccountingGroup
		|			AND TypesOfStocksWarehouse.ProductsGroup = GoodsTable.InventoryOwnerAttribute.ProductsGroup
		|			AND TypesOfStocksWarehouse.PriceKind = GoodsTable.InventoryOwnerAttribute.PriceKind
		|			AND NOT TypesOfStocksWarehouse.IsDuplicate
		|			AND NOT TypesOfStocksWarehouse.Obsolete1
		|			AND NOT TypesOfStocksWarehouse.DeletionMark
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND GoodsTable.ItemsLocationAttributes.Products.ItemsType IN (
		|		VALUE(Enum.ItemsTypes.OwnGoods), 
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND (NOT DocumentData.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit), 
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery), 
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery))
		|		OR NOT ISNULL(GoodsTable.ItemsLocationAttributes.Products.TracedGoods, FALSE))
		|	AND DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit), 
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery), 
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	AND GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
		|	AND NOT GoodsTable.ToExpenseAs
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentData.Date											AS Period,
		|	DocumentData.Organization										AS Organization,
		|	CASE
		|		WHEN TableOfDiscrepancies.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
		|			OR CASE 
		|					WHEN DocumentData.ReferenceOrder REFS Document.PurchaseOrder 
		|						THEN CAST(DocumentData.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation
		|					WHEN DocumentData.ReferenceOrder REFS Document.VendorInvoice 
		|						THEN CAST(DocumentData.ReferenceOrder AS Document.VendorInvoice).BusinessOperation
		|					WHEN DocumentData.ReferenceOrder REFS Catalog.CounterpartyContracts
		|						THEN CAST(DocumentData.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation
		|				END IN (
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			THEN TableOfDiscrepancies.ItemsLocationAttributesGoodsAtPartners
		|		ELSE InventoryLocationAttributeWithoutSeries.DimensionKey
		|	END															AS ItemsLocationAttributes,
		|	TableOfDiscrepancies.InventoryOwnerAttribute									AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)						AS CCDNumber,
		|	CASE
		|		WHEN TableOfDiscrepancies.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
		|			THEN -1
		|		ELSE 1
		|	END * TableOfDiscrepancies.Count							AS NumberIsReversed,
		|	0																AS IsInternal
		|INTO WriteOffDiscrepanciesBetweenReceiptAndPurchase
		|FROM
		|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS TableOfDiscrepancies
		|		INNER JOIN Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS DocumentData
		|		ON DocumentData.Ref = TableOfDiscrepancies.Ref
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryLocationAttributeWithoutSeries
		|		ON TableOfDiscrepancies.ItemsLocationAttributesGoodsAtPartners.Products = InventoryLocationAttributeWithoutSeries.Products
		|			AND TableOfDiscrepancies.ItemsLocationAttributesGoodsAtPartners.Characteristic = InventoryLocationAttributeWithoutSeries.Characteristic
		|			AND InventoryLocationAttributeWithoutSeries.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			AND TableOfDiscrepancies.ItemsLocationAttributesGoodsAtPartners.Purpose = InventoryLocationAttributeWithoutSeries.Purpose
		|			AND TableOfDiscrepancies.ItemsLocationAttributesGoodsAtPartners.StorageLocation = InventoryLocationAttributeWithoutSeries.StorageLocation
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND TableOfDiscrepancies.Products.ItemsType IN (
		|		VALUE(Enum.ItemsTypes.OwnGoods), 
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND (
		|		TableOfDiscrepancies.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
		|			OR 
		|			(
		|				TableOfDiscrepancies.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
		|					AND CASE 
		|						WHEN DocumentData.ReferenceOrder REFS Document.PurchaseOrder 
		|							THEN CAST(DocumentData.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation
		|						WHEN DocumentData.ReferenceOrder REFS Document.VendorInvoice 
		|							THEN CAST(DocumentData.ReferenceOrder AS Document.VendorInvoice).BusinessOperation
		|						WHEN DocumentData.ReferenceOrder REFS Catalog.CounterpartyContracts
		|							THEN CAST(DocumentData.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation
		|					END IN (
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		)
		|	)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Date							AS Period,
		|	DocumentData.Organization						AS Organization,
		|	InventoryKindTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	InventoryKindTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)		AS CCDNumber,
		|	CASE
		|		WHEN CASE
		|				WHEN DocumentData.ReferenceOrder REFS Document.PurchaseOrder 
		|					THEN CAST(DocumentData.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation
		|				WHEN DocumentData.ReferenceOrder REFS Document.VendorInvoice 
		|					THEN CAST(DocumentData.ReferenceOrder AS Document.VendorInvoice).BusinessOperation
		|				WHEN DocumentData.ReferenceOrder REFS Catalog.CounterpartyContracts
		|					THEN CAST(DocumentData.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation
		|			END IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			THEN 0
		|		ELSE 1
		|	END * InventoryKindTable.Count			AS NumberIsReversed,
		|	1												AS IsInternal
		|FROM
		|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryKinds AS InventoryKindTable
		|		INNER JOIN Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS DocumentData
		|		ON DocumentData.Ref = InventoryKindTable.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND (InventoryKindTable.ItemsLocationAttributes.Products.TracedGoods
		|		OR InventoryKindTable.ItemsLocationAttributes.Products.KeepRecordsByCCD)
		|	AND InventoryKindTable.ItemsLocationAttributes.Products.ItemsType IN (
		|		VALUE(Enum.ItemsTypes.OwnGoods), 
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND InventoryKindTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT 
		|	DocumentData.Date							AS Period,
		|	DocumentData.Organization						AS Organization,
		|	TableOfDiscrepancies.ItemsLocationAttributes  	AS ItemsLocationAttributes,
		|	TableOfDiscrepancies.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)		AS CCDNumber,
		|	TableOfDiscrepancies.Count					AS NumberIsReversed,
		|	4												AS IsInternal
		|FROM
		|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS TableOfDiscrepancies
		|		INNER JOIN Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS DocumentData
		|		ON DocumentData.Ref = TableOfDiscrepancies.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod  
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND TableOfDiscrepancies.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND TableOfDiscrepancies.ItemsLocationAttributes.Products.TracedGoods
		|	AND TableOfDiscrepancies.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
		|	AND CASE 
		|		WHEN DocumentData.ReferenceOrder REFS Document.PurchaseOrder 
		|			THEN CAST(DocumentData.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation
		|		WHEN DocumentData.ReferenceOrder REFS Document.VendorInvoice 
		|			THEN CAST(DocumentData.ReferenceOrder AS Document.VendorInvoice).BusinessOperation
		|		WHEN DocumentData.ReferenceOrder REFS Catalog.CounterpartyContracts
		|			THEN CAST(DocumentData.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation
		|		END IN (
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// Arrival of goods in transit, on contract, without GTD.
		|SELECT
		|	DocumentData.Date						AS Period,
		|	DocumentData.Organization					AS Organization,
		|	DocumentGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	DocumentGoods.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber,
		|	DocumentGoods.Count					AS NumberIsReversed,
		|	1											AS IsInternal
		|INTO CCDImport
		|FROM
		|	Document.CCDImport.Goods AS DocumentGoods
		|		INNER JOIN Document.CCDImport AS DocumentData
		|		ON DocumentData.Ref = DocumentGoods.Ref
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms)
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|
		|UNION ALL
		|
		// Consumption of own goods, to the warehouse, without GTE.
		|SELECT
		|	DocumentData.Date															AS Period,
		|	DocumentData.Organization														AS Organization,
		|	ISNULL(Dimension.DimensionKey, DocumentGoods.ItemsLocationAttributes)	AS ItemsLocationAttributes,
		|	ISNULL(TypesOfStocksWarehouse.Ref, DocumentGoods.InventoryOwnerAttribute)				AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)										AS CCDNumber,
		|	-DocumentGoods.Count														AS NumberIsReversed,
		|	3																				AS IsInternal
		|FROM
		|	Document.CCDImport.Goods AS DocumentGoods
		|		INNER JOIN Document.CCDImport AS DocumentData
		|		ON DocumentData.Ref = DocumentGoods.Ref
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
		|		ON DocumentGoods.Products = Dimension.Products
		|			AND DocumentGoods.Characteristic = Dimension.Characteristic
		|			AND DocumentGoods.Series = Dimension.Series
		|			AND DocumentGoods.Purpose = Dimension.Purpose
		|			AND DocumentGoods.ItemsLocationAttributes.ProductCostElement = Dimension.ProductCostElement
		|			AND DocumentGoods.Warehouse = Dimension.StorageLocation
		|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
		|		ON TypesOfStocksWarehouse.Organization = DocumentGoods.InventoryOwnerAttribute.Organization
		|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentGoods.InventoryOwnerAttribute.GoodsOwner
		|			AND TypesOfStocksWarehouse.VATTaxation = DocumentGoods.InventoryOwnerAttribute.VATTaxation
		|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentGoods.InventoryOwnerAttribute.FinancialAccountingGroup
		|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentGoods.InventoryOwnerAttribute.ProductsGroup
		|			AND TypesOfStocksWarehouse.PriceKind = DocumentGoods.InventoryOwnerAttribute.PriceKind
		|			AND NOT TypesOfStocksWarehouse.IsDuplicate
		|			AND NOT TypesOfStocksWarehouse.Obsolete1
		|			AND NOT TypesOfStocksWarehouse.DeletionMark
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.Date <= &TemplatePeriod
		|	AND NOT DocumentData.Ref IN 
		|		(SELECT
		|			ReversingEntry.Ref AS Ref
		|		FROM
		|			ReversingEntry AS ReversingEntry)
		|	AND DocumentData.Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms)
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DATETIME(1, 1, 1)													AS Period,
		|	VALUE(Catalog.Companies.EmptyRef)						AS Organization,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)	AS ItemsLocationAttributes,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)						AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)							AS CCDNumber,
		|	0																	AS NumberIsReversed,
		|	-1																	AS IsInternal
		|INTO NotificationOfImportOfTraceableGoods
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CorrectionOfSidedBalanceInCompanyGoodsAccounting.Period						AS Period,
		|	CorrectionOfSidedBalanceInCompanyGoodsAccounting.Organization					AS Organization,
		|	CorrectionOfSidedBalanceInCompanyGoodsAccounting.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CorrectionOfSidedBalanceInCompanyGoodsAccounting.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	CorrectionOfSidedBalanceInCompanyGoodsAccounting.CCDNumber					AS CCDNumber,
		|	CorrectionOfSidedBalanceInCompanyGoodsAccounting.NumberIsReversed			AS NumberIsReversed
		|INTO CompanyGoodsOnWay
		|FROM
		|	CorrectionOfSidedBalanceInCompanyGoodsAccounting AS CorrectionOfSidedBalanceInCompanyGoodsAccounting
		|WHERE
		|	&CorrectionsOfExpandedBalance
		|	AND (CorrectionOfSidedBalanceInCompanyGoodsAccounting.Organization, CorrectionOfSidedBalanceInCompanyGoodsAccounting.ItemsLocationAttributes, CorrectionOfSidedBalanceInCompanyGoodsAccounting.InventoryOwnerAttribute) IN
		|		(SELECT
		|			PurchaseAdjustment.Organization					AS Organization,
		|			PurchaseAdjustment.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|			PurchaseAdjustment.InventoryOwnerAttribute					AS InventoryOwnerAttribute
		|		FROM
		|			PurchaseAdjustment AS PurchaseAdjustment
		|		WHERE
		|			PurchaseAdjustment.NumberIsReversed <> 0
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			ReceiptOfGoodsToWarehouse.Organization					AS Organization,
		|			ReceiptOfGoodsToWarehouse.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|			ReceiptOfGoodsToWarehouse.InventoryOwnerAttribute					AS InventoryOwnerAttribute
		|		FROM
		|			ReceiptOfGoodsToWarehouse AS ReceiptOfGoodsToWarehouse
		|		WHERE
		|			ReceiptOfGoodsToWarehouse.NumberIsReversed <> 0
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			VendorInvoice.Organization				AS Organization,
		|			VendorInvoice.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|			VendorInvoice.InventoryOwnerAttribute					AS InventoryOwnerAttribute
		|		FROM
		|			VendorInvoice AS VendorInvoice
		|		WHERE
		|			VendorInvoice.NumberIsReversed <> 0
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			WriteOffDiscrepanciesBetweenReceiptAndPurchase.Organization					AS Organization,
		|			WriteOffDiscrepanciesBetweenReceiptAndPurchase.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|			WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryOwnerAttribute					AS InventoryOwnerAttribute
		|		FROM
		|			WriteOffDiscrepanciesBetweenReceiptAndPurchase AS WriteOffDiscrepanciesBetweenReceiptAndPurchase
		|		WHERE
		|			WriteOffDiscrepanciesBetweenReceiptAndPurchase.NumberIsReversed <> 0
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			CCDImport.Organization					AS Organization,
		|			CCDImport.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|			CCDImport.InventoryOwnerAttribute					AS InventoryOwnerAttribute
		|		FROM
		|			CCDImport AS CCDImport
		|		WHERE
		|			CCDImport.NumberIsReversed <> 0
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			NotificationOfImportOfTraceableGoods.Organization					AS Organization,
		|			NotificationOfImportOfTraceableGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|			NotificationOfImportOfTraceableGoods.InventoryOwnerAttribute					AS InventoryOwnerAttribute
		|		FROM
		|			NotificationOfImportOfTraceableGoods AS NotificationOfImportOfTraceableGoods
		|		WHERE
		|			NotificationOfImportOfTraceableGoods.NumberIsReversed <> 0)
		|
		|UNION ALL
		|
		|SELECT
		|	PurchaseAdjustment.Period						AS Period,
		|	PurchaseAdjustment.Organization					AS Organization,
		|	PurchaseAdjustment.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	PurchaseAdjustment.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	PurchaseAdjustment.CCDNumber						AS CCDNumber,
		|	PurchaseAdjustment.NumberIsReversed				AS NumberIsReversed
		|FROM
		|	PurchaseAdjustment AS PurchaseAdjustment
		|
		|UNION ALL
		|
		|SELECT
		|	ReceiptOfGoodsToWarehouse.Period						AS Period,
		|	ReceiptOfGoodsToWarehouse.Organization					AS Organization,
		|	ReceiptOfGoodsToWarehouse.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	ReceiptOfGoodsToWarehouse.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	ReceiptOfGoodsToWarehouse.CCDNumber						AS CCDNumber,
		|	ReceiptOfGoodsToWarehouse.NumberIsReversed				AS NumberIsReversed
		|FROM
		|	ReceiptOfGoodsToWarehouse AS ReceiptOfGoodsToWarehouse
		|
		|UNION ALL
		|
		|SELECT
		|	VendorInvoice.Period						AS Period,
		|	VendorInvoice.Organization				AS Organization,
		|	VendorInvoice.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	VendorInvoice.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	VendorInvoice.CCDNumber					AS CCDNumber,
		|	VendorInvoice.NumberIsReversed			AS NumberIsReversed
		|FROM
		|	VendorInvoice AS VendorInvoice
		|
		|UNION ALL
		|
		|SELECT
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.Period						AS Period,
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.Organization					AS Organization,
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.CCDNumber						AS CCDNumber,
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.NumberIsReversed				AS NumberIsReversed
		|FROM
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase AS WriteOffDiscrepanciesBetweenReceiptAndPurchase
		|
		|UNION ALL
		|
		|SELECT
		|	CCDImport.Period						AS Period,
		|	CCDImport.Organization					AS Organization,
		|	CCDImport.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CCDImport.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	CCDImport.CCDNumber						AS CCDNumber,
		|	CCDImport.NumberIsReversed				AS NumberIsReversed
		|FROM
		|	CCDImport AS CCDImport
		|
		|UNION ALL
		|
		|SELECT
		|	NotificationOfImportOfTraceableGoods.Period						AS Period,
		|	NotificationOfImportOfTraceableGoods.Organization					AS Organization,
		|	NotificationOfImportOfTraceableGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	NotificationOfImportOfTraceableGoods.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	NotificationOfImportOfTraceableGoods.CCDNumber						AS CCDNumber,
		|	NotificationOfImportOfTraceableGoods.NumberIsReversed				AS NumberIsReversed
		|FROM
		|	NotificationOfImportOfTraceableGoods AS NotificationOfImportOfTraceableGoods
		|
		|INDEX BY
		|	Period,
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReversingEntry
		|;
		|                                                                 
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CorrectionOfSidedBalanceInCompanyGoodsAccounting
		|;
		|                                                                 
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PurchaseAdjustment
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReceiptOfGoodsAtWarehouse_TTItemParameters
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReceiptOfGoodsToWarehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PurchaseOfGoodsOfServices_TTGoodsForConnectionAnalytics
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP VendorInvoice
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP WriteOffDiscrepanciesBetweenReceiptAndPurchase
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CCDImport
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP NotificationOfImportOfTraceableGoods";
	
	QueryText = StrReplace(QueryText, "&TemplatePeriod",                  TemplatePeriod);
	QueryText = StrReplace(QueryText, "&CorrectionsOfExpandedBalance", ?(CorrectionsOfExpandedBalance, "TRUE", "FALSE"));
	
	Return QueryText;
	
EndFunction

Function RequestNegativeBalancesOfGoodsOfOrganizations()
	
	QueryText = 
		StopRegisteringRecordsOfCompanyGoodsInTransit("&EndOfPeriod") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	InventoryOwnerAttribute.Ref AS Ref
		|INTO TTPermittedStocks
		|FROM
		|	Catalog.InventoryKinds AS InventoryOwnerAttribute
		|WHERE
		|	InventoryOwnerAttribute.InventoryType IN (&ControlledInventoryTypes)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&EndOfPeriod										AS Period,
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance  		AS CountBalance,
		|	CompanyGoodsBalance.ToRegisterGoodsIssueBalance AS ToRegisterGoodsIssueBalance
		|INTO TTForCurPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&BorderEndOfPeriod,
		|		Organization IN (&CompanyArray)
		|			AND InventoryOwnerAttribute IN (
		|				SELECT
		|					TTPermittedStocks.Ref
		|				FROM
		|					TTPermittedStocks AS TTPermittedStocks)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	&EndOfPeriod										AS Period,
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance,
		|	0													AS ToRegisterGoodsIssueBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &EndOfPeriod
		|	AND CompanyGoodsOnWay.Organization IN (&CompanyArray)
		|	AND CompanyGoodsOnWay.InventoryOwnerAttribute IN (
		|		SELECT
		|			TTPermittedStocks.Ref
		|		FROM
		|			TTPermittedStocks AS TTPermittedStocks)
		|
		|UNION ALL
		|
		|SELECT
		|	&EndOfPeriod												AS Period,
		|	CompanySafeStockBalance.Organization				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance			AS CountBalance,
		|	0															AS ToRegisterGoodsIssueBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|		&BorderEndOfPeriod,
		|		Organization IN (&CompanyArray)
		|			AND InventoryOwnerAttribute IN (
		|				SELECT
		|					TTPermittedStocks.Ref
		|				FROM
		|					TTPermittedStocks AS TTPermittedStocks)) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT               
		|	&EndOfPeriod										AS Period,
		|	CompanyGoodsBalance.Organization				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance			AS CountBalance,
		|	CompanyGoodsBalance.ToRegisterGoodsIssueBalance	AS ToRegisterGoodsIssueBalance
		|INTO BalanceOfPreviousPeriodTT
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&BorderEndOfPreviousPeriod,
		|		Organization IN (&CompanyArray)
		|			AND InventoryOwnerAttribute IN (
		|				SELECT
		|					TTPermittedStocks.Ref
		|				FROM
		|					TTPermittedStocks AS TTPermittedStocks)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	&EndOfPeriod										AS Period,
		|	CompanyGoodsOnWay.Organization					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance,
		|	0													AS ToRegisterGoodsIssueBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &EndOfPreviousPeriod
		|	AND CompanyGoodsOnWay.Organization IN (&CompanyArray)
		|	AND CompanyGoodsOnWay.InventoryOwnerAttribute IN (
		|		SELECT
		|			TTPermittedStocks.Ref
		|		FROM
		|			TTPermittedStocks AS TTPermittedStocks)
		|
		|UNION ALL
		|
		|SELECT                     
		|	&EndOfPeriod												AS Period,
		|	CompanySafeStockBalance.Organization				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance			AS CountBalance,
		|	0															AS ToRegisterGoodsIssueBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|		&BorderEndOfPreviousPeriod,
		|		Organization IN (&CompanyArray)
		|			AND InventoryOwnerAttribute IN (
		|				SELECT
		|					TTPermittedStocks.Ref
		|				FROM
		|					TTPermittedStocks AS TTPermittedStocks)) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTPermittedStocks
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTForCurPeriod.Period								AS Period,
		|	TTForCurPeriod.Organization 							AS Organization,
		|	TTForCurPeriod.ItemsLocationAttributes			AS ItemsLocationAttributes,
		|	TTForCurPeriod.InventoryOwnerAttribute 							AS InventoryOwnerAttribute,
		|	TTForCurPeriod.CCDNumber 							AS CCDNumber,
		|	SUM(TTForCurPeriod.CountBalance)				AS CountBalance,
		|	SUM(TTForCurPeriod.ToRegisterGoodsIssueBalance)	AS ToRegisterGoodsIssueBalance
		|INTO TTBalancesOfCurrentPeriodGrouped
		|FROM
		|	TTForCurPeriod AS TTForCurPeriod
		|
		|GROUP BY
		|	TTForCurPeriod.Period,
		|	TTForCurPeriod.Organization,
		|	TTForCurPeriod.ItemsLocationAttributes,
		|	TTForCurPeriod.InventoryOwnerAttribute,
		|	TTForCurPeriod.CCDNumber
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTForCurPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalanceOfPreviousPeriodTT.Period							AS Period,
		|	BalanceOfPreviousPeriodTT.Organization 						AS Organization,
		|	BalanceOfPreviousPeriodTT.ItemsLocationAttributes		AS ItemsLocationAttributes,
		|	BalanceOfPreviousPeriodTT.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
		|	BalanceOfPreviousPeriodTT.CCDNumber 							AS CCDNumber,
		|	SUM(BalanceOfPreviousPeriodTT.CountBalance)			AS CountBalance,
		|	SUM(BalanceOfPreviousPeriodTT.ToRegisterGoodsIssueBalance)	AS ToRegisterGoodsIssueBalance
		|INTO TTPreviousPeriodBalancesGrouped
		|FROM
		|	BalanceOfPreviousPeriodTT AS BalanceOfPreviousPeriodTT
		|
		|GROUP BY
		|	BalanceOfPreviousPeriodTT.Period,
		|	BalanceOfPreviousPeriodTT.Organization,
		|	BalanceOfPreviousPeriodTT.ItemsLocationAttributes,
		|	BalanceOfPreviousPeriodTT.InventoryOwnerAttribute,
		|	BalanceOfPreviousPeriodTT.CCDNumber
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalanceOfPreviousPeriodTT
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 10
		|	BalancesCurPeriod.Period																				AS Period,
		|	BalancesCurPeriod.Organization 																		AS Organization,
		|	BalancesCurPeriod.ItemsLocationAttributes															AS ItemsLocationAttributes,
		|	BalancesCurPeriod.InventoryOwnerAttribute 																		AS InventoryOwnerAttribute,
		|	BalancesCurPeriod.CCDNumber 																			AS CCDNumber,
		|	SUM(BalancesCurPeriod.CountBalance)															AS Count,
		|	SUM(BalancesCurPeriod.CountBalance - ISNULL(BalancesOfPreviousPeriod.CountBalance, 0))	AS Turnover
		|INTO Negative_Balance
		|FROM
		|	TTBalancesOfCurrentPeriodGrouped AS BalancesCurPeriod
		|		LEFT JOIN TTPreviousPeriodBalancesGrouped AS BalancesOfPreviousPeriod
		|		ON BalancesCurPeriod.Organization = BalancesOfPreviousPeriod.Organization
		|			AND BalancesCurPeriod.ItemsLocationAttributes = BalancesOfPreviousPeriod.ItemsLocationAttributes
		|			AND BalancesCurPeriod.InventoryOwnerAttribute = BalancesOfPreviousPeriod.InventoryOwnerAttribute
		|			AND BalancesCurPeriod.CCDNumber = BalancesOfPreviousPeriod.CCDNumber
		|
		|GROUP BY
		|	BalancesCurPeriod.Period,
		|	BalancesCurPeriod.Organization,
		|	BalancesCurPeriod.ItemsLocationAttributes,
		|	BalancesCurPeriod.InventoryOwnerAttribute,
		|	BalancesCurPeriod.CCDNumber
		|
		|HAVING
		|	SUM(BalancesCurPeriod.CountBalance) < 0
		|
		|UNION ALL
		|
		|SELECT TOP 10
		|	BalancesCurPeriod.Period																									AS Period,
		|	BalancesCurPeriod.Organization																							AS Organization,
		|	BalancesCurPeriod.ItemsLocationAttributes																				AS ItemsLocationAttributes,
		|	BalancesCurPeriod.InventoryOwnerAttribute																								AS InventoryOwnerAttribute,
		|	BalancesCurPeriod.CCDNumber																								AS CCDNumber,
		|	SUM(BalancesCurPeriod.ToRegisterGoodsIssueBalance)																		AS Count,
		|	SUM(BalancesCurPeriod.ToRegisterGoodsIssueBalance - ISNULL(BalancesOfPreviousPeriod.ToRegisterGoodsIssueBalance, 0))	AS Turnover
		|FROM
		|	TTBalancesOfCurrentPeriodGrouped AS BalancesCurPeriod
		|		LEFT JOIN TTPreviousPeriodBalancesGrouped AS BalancesOfPreviousPeriod
		|		ON BalancesCurPeriod.Organization = BalancesOfPreviousPeriod.Organization
		|			AND BalancesCurPeriod.ItemsLocationAttributes = BalancesOfPreviousPeriod.ItemsLocationAttributes
		|			AND BalancesCurPeriod.InventoryOwnerAttribute = BalancesOfPreviousPeriod.InventoryOwnerAttribute
		|			AND BalancesCurPeriod.CCDNumber = BalancesOfPreviousPeriod.CCDNumber
		|
		|GROUP BY
		|	BalancesCurPeriod.Period,
		|	BalancesCurPeriod.Organization,
		|	BalancesCurPeriod.ItemsLocationAttributes,
		|	BalancesCurPeriod.InventoryOwnerAttribute,
		|	BalancesCurPeriod.CCDNumber
		|
		|HAVING
		|	SUM(BalancesCurPeriod.ToRegisterGoodsIssueBalance) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTBalancesOfCurrentPeriodGrouped
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTPreviousPeriodBalancesGrouped";
	
	Return QueryText;
	
EndFunction

// The presence of negative Balances of organizations' goods is checked at the end of the month.
//
// Parameters:
//	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters.
//
Procedure CheckingNegativeBalancesOfGoodsOfOrganizations(CheckParameters) Export
	
	SectionsToCheck = New Array;
	SectionsToCheck.Add("RoutineOperations");
	SectionsToCheck.Add("Bookkeeping");
	
	DataTable = PeriodClosingDates.DataToCheckTemplate();
	For Each CurrentCompany In CheckParameters.AdditionalParameters.CompanyArray Do
		For Each CurrentSection In SectionsToCheck Do
			NewRow        = DataTable.Add();
			NewRow.Date   = CheckParameters.AdditionalParameters.EndOfPeriod;
			NewRow.Section = CurrentSection;
			NewRow.Object = CurrentCompany;
		EndDo;
	EndDo;
	DataTable.Sort("Object, Section");
	
	DataDetails = New Structure("NewVersion, Data", False, "");
	ErrorDescription = New Structure;
	PeriodEndClosingDate	   = Date(1,1,1); // the first permitted period
	
	ChangesAreDisabled = PeriodClosingDates.PeriodEndClosingFound(DataTable, DataDetails, ErrorDescription);		
	If ChangesAreDisabled Then
		For Each BanLine In ErrorDescription.PeriodEnds Do
			CurBan = EndOfMonth(BanLine.PeriodEndClosingDate) + 1;
			
			If Not ValueIsFilled(PeriodEndClosingDate) Then
				PeriodEndClosingDate = CurBan;
			Else
				PeriodEndClosingDate = Max(PeriodEndClosingDate, CurBan);
			EndIf;
		EndDo;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("UncontrolledInventoryTypes", Enums.InventoryTypes.NonControllingEntitiesInventoryTypes());
	AdditionalParameters.Insert("ControlledInventoryTypes",   Enums.InventoryTypes.ControlledInventoryTypes());
	
	FieldList = New ValueList;
	FieldList.Add("Organization",					NStr("vi = 'Doanh nghiệp';
															|ru = 'Организация';
															|en = 'Company'; fa = 'Company';
															|it = 'Azienda';
															|pl = 'Company';
															|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes",	NStr("vi = 'Đối tượng phân tích mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute",					NStr("vi = 'Dạng hàng tồn kho';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	FieldList.Add("CCDNumber",					NStr("vi = 'Số tờ khai hải quan';
														|ru = 'Номер ГТД';
														|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
														|it = 'Numero della polizza doganale di carico';
														|pl = 'Numer ŁDC (ładunkowej deklaracji celnej)';
														|tr = 'Gümrük Kargo Beyannamesi numarası'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",					NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Quantità';
													|pl = 'Quantity';
													|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	If PeriodEndClosingDate > CheckParameters.AdditionalParameters.EndOfPeriod Then
		RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
									"Negative_Balance",
									NStr("vi = 'Nên chỉnh sửa số dư âm của hàng hóa trong doanh nghiệp ""%1"" vào cuối kỳ %2 trong kỳ mở';
										|ru = 'Рекомендуется исправить отрицательные остатки товаров организации ""%1"" на конец периода %2 в открытом периоде';
										|en = 'Correct the negative stock balance of the %1 company at the end of the period %2 in an open period'; fa = 'Correct the negative stock balance of the %1 company at the end of the period %2 in an open period';
										|it = 'Рекомендуется исправить отрицательные остатки товаров организации ""%1"" на конец периода %2 в открытом периоде';
										|pl = 'Correct the negative stock balance of the %1 company at the end of the period %2 in an open period';
										|tr = 'Açık dönemde %2 döneminin sonunda ""%1"" iş yerinin negatif stok bakiyelerinin düzeltilmesi önerilmektedir'", Common.DefaultLanguageCode()),
									FieldList);
		
		MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters,
																		RegistrationParameters,
																		RequestNegativeBalancesOfGoodsOfOrganizations(),
																		AdditionalParameters,
																		Enums.AccountingIssueSeverity.Warning);
																		
	Else
		RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
									"Negative_Balance",
									NStr("vi = 'Đã tìm thấy số dư âm của hàng hóa trong doanh nghiệp ""%1"" vào cuối kỳ %2';
										|ru = 'Обнаружены отрицательные остатки товаров организации ""%1"" на конец периода %2';
										|en = 'Negative stock balance of the ""%1"" company goods is detected as of the end of the %2 period'; fa = 'Negative stock balance of the ""%1"" company goods is detected as of the end of the %2 period';
										|it = 'Trovate delle rimanenze negative dei prodotti dell''organizzazione ""%1"" alla fine del periodo %2';
										|pl = 'Wykryto ujemne pozostałości towarów firmy ""%1"" na koniec okresu %2';
										|tr = '""%1"" iş yeri, %2 döneminin sonunda negatif stok bakiyeleri bulundu'", Common.DefaultLanguageCode()),
									FieldList);
		
		MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters,
																		RegistrationParameters,
																		RequestNegativeBalancesOfGoodsOfOrganizations(),
																		AdditionalParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region RegisterGoodsTransfers

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - ValueTable - table of stages (See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable)
//                                   .
//	CurrentParent - String - group ID.
//
Procedure AddStage_RegisterGoodsTransfers(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterGoodsTransfers);
		
	NewRow.MultilingualName = "vi = 'Lập chứng từ chuyển giao hàng hóa';
								|ru = 'Оформление передач товаров';
								|en = 'Register goods transfers';
								|it = 'Formalizzazione dei trasferimenti delle merci';
								|pl = 'Sporządzenie przekazywań towarów';
								|tr = 'Ürün transferlerinin düzenlenmesi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Tạo';
								|ru = 'Оформить';
								|en = 'Register'; fa = 'ثبات';
								|it = 'Preparare';
								|pl = 'Register';
								|tr = 'Düzenle'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InventoriesServer.Use_RegistrationOfTransfersOfGoods");
	ActionDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.LogOfIntercompanyDocuments.Forms.RegisterTransfersAndRedemptions.FullName());
	ActionDetails.FormParameters.Insert("PurposeUseKey", "DocumentsBetweenCompaniesAll");
	NewRow.ActionExecute  = ActionDetails;
EndProcedure

// Stage handlers.

Procedure Use_RegistrationOfTransfersOfGoods(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	If HandlerParameters.CalculationParameters.AllCompanies Then 
		Query.SetParameter("Recipient", New Array);
	Else
		Query.SetParameter("Recipient", HandlerParameters.CalculationParameters.CompanyArray);
	EndIf;	
	Query.SetParameter("MakeTransfers", True);
	Query.Text = TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query, "VTKRegistrationOfTransfers");
		
	Query.Execute();
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "VTKRegistrationOfTransfers", HandlerParameters) = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư trong biểu ghi ""Dự phòng hàng hóa trong doanh nghiệp""';
				|ru = 'Нет остатков в регистре ""Резервы товаров организаций""';
				|en = 'No balance in the ""Company goods reserves"" register'; fa = 'No balance in the ""Company goods reserves"" register';
				|it = 'Non ci sono rimanenze nel registro ""Riserve delle merci delle organizzazioni""';
				|pl = 'Brak pozostałości w rejestrze ""Резервы товаров организаций""';
				|tr = '""İş yerlerinin ürün rezervleri"" sicilinde bakiye yok'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_RegistrationOfTransfersOfGoods(TableOfChecks) Export
	
	// Registration of transfers of goods.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"GoodsWereNotTransferred",
		Catalogs.MonthEndClosingOperations.RegisterGoodsTransfers,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"InventoriesServer.CheckingNeedForRegistrationOfTransfersOfGoods");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chuyển giao hàng hóa giữa các doanh nghiệp chưa được tạo';
			|ru = 'Не оформленные передачи товаров между организациями';
			|en = '""Customer invoices — Intercompany"" that are not registered'; fa = '""Customer invoices — Intercompany"" that are not registered';
			|it = 'Transazioni delle merci tra le organizzazioni non regolarizzate';
			|pl = 'Nie sporządzone przekazania towarów między firmami';
			|tr = 'İş yerleri arasında kayıt dışı ürün transferleri'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần tạo chứng từ ""Chuyển giao hàng hóa giữa các doanh nghiệp""';
			|ru = 'Должны быть оформлены документы ""Передача товаров между организациями"".';
			|en = 'The ""Customer invoice  — Intercompany"" documents must be registered.'; fa = 'The ""Customer invoice  — Intercompany"" documents must be registered.';
			|it = 'Devono essere regolarizzati i documenti ""Transazioni delle merci tra le organizzazioni"".';
			|pl = 'Muszą być sporządzone dokumenty ""Przekazanie towarów pomiędzy firmami"".';
			|tr = '""İş yerleri arasında mal transferi"" belgeleri kaydedilmelidir.'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure CheckingNeedForRegistrationOfTransfersOfGoods(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			   NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Company';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes", NStr("vi = 'Đối tượng phân tích mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute", 				   NStr("vi = 'Dạng hàng tồn kho';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	FieldList.Add("CCDNumber", 				   NStr("vi = 'Số tờ khai hải quan';
														|ru = 'Номер ГТД';
														|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
														|it = 'Numero della polizza doganale di carico';
														|pl = 'Numer ŁDC (ładunkowej deklaracji celnej)';
														|tr = 'Gümrük Kargo Beyannamesi numarası'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",		 		   NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Quantità';
													|pl = 'Quantity';
													|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"VTKRegistrationOfTransfers",
		NStr("vi = 'Cần tạo chuyển hàng vào doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Требуется оформить передачу товаров в организацию ""%1"" на конец периода %2';
			|en = 'Register goods transfer to the ""%1"" company as of the %2 period end'; fa = 'Register goods transfer to the ""%1"" company as of the %2 period end';
			|it = 'È necessario regolamentare la transazione delle merci all''organizzazione ""%1"" per la fine del periodo %2';
			|pl = 'Należy sporządzić przekazanie towarów do firmy ""%1"" na koniec okresu %2';
			|tr = '%2 döneminin sonunda ""%1"" iş yerine mal transferinin kaydedilmesi gerekiyor'", Common.DefaultLanguageCode()),
		FieldList);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region RegisterGoodsStockToTransfer

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - ValueTable - table of stages (See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable)
//                                   .
//	CurrentParent - String - group ID.
//
Procedure AddStage_RegisterGoodsStockToTransfer(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterGoodsStockToTransfer);
	
	NewRow.MultilingualName =
		"vi = 'Lập chứng từ chuyển giao và trả lại (theo dữ liệu được nhập trước phiên bản 2.4)';
		|ru = 'Оформление передач и возвратов товаров (по данным, введенным до версии 2.4)';
		|en = 'Register goods transfers and returns (according to the data entered before version 2.4)';
		|it = 'Formalizzazione dei trasferimenti e resi di merci (per dati inseriti fino alla versione 2.4)';
		|pl = 'Rejestracja przelewów i zwrotów towarów (zgodnie z danymi wprowadzonymi przed wersją 2.4)';
		|tr = 'Ürün iadelerinin ve transferlerinin düzenlenmesi (2.4 sürümünden önce girilen verilere dayanmaktadır)'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Tạo';
								|ru = 'Оформить';
								|en = 'Register'; fa = 'ثبات';
								|it = 'Preparare';
								|pl = 'Register';
								|tr = 'Düzenle'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InventoriesServer.Use_RegistrationOfRemainingGoodsForTransfer");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InventoriesServer.Registration_RegistrationOfRemainingGoodsForTransfer");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.LogOfIntercompanyDocuments.Forms.RegisterHandoverAndReturn.FullName());
EndProcedure

// Stage handlers.

Procedure Use_RegistrationOfRemainingGoodsForTransfer(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	ToTransfer.CompanyOwner AS Organization,
	|	ToTransfer.ItemsLocationAttributes,
	|	ToTransfer.SellerInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ToTransfer.CCDNumber,
	|	ToTransfer.CountClosingBalance AS Count
	|INTO BalancesToTransfer
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod) AS ToTransfer
	|WHERE
	|	(ToTransfer.CompanyOwner IN (&CompanyArray)
	|		OR ToTransfer.SellerInventoryOwnerAttribute.Organization IN (&CompanyArray))
	|	AND ToTransfer.CountClosingBalance <> 0
	|	AND (ToTransfer.CountClosingBalance - ToTransfer.CountOpeningBalance > 0
	|		OR ToTransfer.CountOpeningBalance = 0)
	|
	|UNION ALL
	|
	|SELECT
	|	ToTransfer.CompanyOwner AS Organization,
	|	ToTransfer.ItemsLocationAttributes,
	|	ToTransfer.SellerInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ToTransfer.CCDNumber,
	|	ToTransfer.ReturnedClosingBalance AS Count
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod) AS ToTransfer
	|WHERE
	|	(ToTransfer.CompanyOwner IN (&CompanyArray)
	|		OR ToTransfer.SellerInventoryOwnerAttribute.Organization IN (&CompanyArray))
	|	AND ToTransfer.ReturnedClosingBalance <> 0
	|	AND (ToTransfer.ReturnedClosingBalance - ToTransfer.ReturnedOpeningBalance <> 0
	|		OR ToTransfer.ReturnedOpeningBalance = 0)
	|";
	
	Query.Execute();
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "BalancesToTransfer", HandlerParameters) = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư trong biểu ghi ""Hàng hóa của doanh nghiệp cần chuyển giao""';
				|ru = 'Нет остатков в регистре ""Товары организаций к передаче""';
				|en = 'No balance in the ""Company goods for transfer"" register'; fa = 'No balance in the ""Company goods for transfer"" register';
				|it = 'Non ci sono rimanenze nel registro ""Merci dell''organizzazione per la transazione""';
				|pl = 'Brak pozostałości w rejestrze ""Товары организаций к передаче""';
				|tr = '""Transfer için iş yeri ürünleri"" sicilinde bakiye yok'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// Initializes the stage of processing balances for transfer.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Registration_RegistrationOfRemainingGoodsForTransfer(HandlerParameters) Export
	
	If GetFunctionalOption("TradeManagement") Then
		HandlerParameters.Data_Stage.Description = StrReplace(HandlerParameters.Data_Stage.Description, "2.4", "11.4");
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_RegistrationOfRemainingGoodsForTransfer(TableOfChecks) Export
	
	// Registration of the remaining transfers of goods.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"RemnantsOfTransfersOfGoodsAreNotRegistered",
		Catalogs.MonthEndClosingOperations.RegisterGoodsStockToTransfer,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"InventoriesServer.CheckingBalanceOfTransfersOfGoods");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Số dư chuyển giao hàng hóa giữa các doanh nghiệp chưa được tạo';
			|ru = 'Не оформленные остатки передач товаров между организациями';
			|en = 'Non-registered balance of intercompany goods transfers'; fa = 'Non-registered balance of intercompany goods transfers';
			|it = 'Gli importi residui delle transazioni delle merci tra le organizzazioni non regolarizzate';
			|pl = 'Nie sporządzone pozostałości przekazań towarów między firmami';
			|tr = 'İş yerleri arası müşteri faturası kayıt dışı bakiyeleri'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần lập chứng từ ""Chuyển giao hàng hóa giữa các doanh nghiệp"".';
			|ru = 'Должны быть оформлены документы ""Передача товаров между организациями"".';
			|en = 'The ""Customer invoice  — Intercompany"" documents must be registered.'; fa = 'The ""Customer invoice  — Intercompany"" documents must be registered.';
			|it = 'Devono essere regolarizzati i documenti ""Transazioni delle merci tra le organizzazioni"".';
			|pl = 'Muszą być sporządzone dokumenty ""Przekazanie towarów pomiędzy firmami"".';
			|tr = '""İş yerleri arasında mal transferi"" belgeleri kaydedilmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

Procedure CheckingBalanceOfTransfersOfGoods(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			   NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Company';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes", NStr("vi = 'Đối tượng phân tích mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute", 				   NStr("vi = 'Dạng hàng tồn kho';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	FieldList.Add("CCDNumber", 				   NStr("vi = 'Số tờ khai hải quan';
														|ru = 'Номер ГТД';
														|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
														|it = 'Numero della polizza doganale di carico';
														|pl = 'Numer ŁDC (ładunkowej deklaracji celnej)';
														|tr = 'Gümrük Kargo Beyannamesi numarası'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",		 		   NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Quantità';
													|pl = 'Quantity';
													|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"BalancesToTransfer",
		NStr("vi = 'Tìm thấy hàng hóa yêu cầu lập điều chuyển / trả lại từ doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены товары, требующие оформления передачи/возврата от организации ""%1"" на конец периода %2';
			|en = 'Goods that require transfer/return from the ""%1"" company to be registered are detected at the end of %2 period'; fa = 'Goods that require transfer/return from the ""%1"" company to be registered are detected at the end of %2 period';
			|it = 'Trovate delle merci la cui transazione/ritorno dall''organizzazione ""%1"" per la fine del periodo %2 deve essere regolarizzata';
			|pl = 'Wykryto wiersze pozycji, wymagające sporządzenia przekazania/zwrotu od firmy ""%1"" na koniec okresu %2';
			|tr = '%2 döneminin sonunda ''%1'' iş yerinden transfer/iade kaydı gerektiren ürünler bulundu'", Common.DefaultLanguageCode()),
		FieldList);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region RegisterGoodsRedemption

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - ValueTable - table of stages (See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable)
//                                   .
//	CurrentParent - String - group ID.
//
Procedure AddStage_RegisterGoodsRedemption(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterGoodsRedemption);
	
	NewRow.MultilingualName = "vi = 'Lập mua lại hàng hóa';
								|ru = 'Оформление выкупа товаров';
								|en = 'Register goods redemption';
								|it = 'Formalizzazione del riscatto delle merci';
								|pl = 'Sporządzenie wykupu towarów';
								|tr = 'Ürünlerin itfasının düzenlenmesi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Tạo';
								|ru = 'Оформить';
								|en = 'Register'; fa = 'ثبات';
								|it = 'Preparare';
								|pl = 'Register';
								|tr = 'Düzenle'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InventoriesServer.Use_ExecutionOfRedemptionOfGoods");
	ActionDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.LogOfIntercompanyDocuments.Forms.RegisterTransfersAndRedemptions.FullName());
	ActionDetails.FormParameters.Insert("PurposeUseKey", "MonthEndTransactions");
	NewRow.ActionExecute  = ActionDetails;
EndProcedure

// Stage handlers.

Procedure Use_ExecutionOfRedemptionOfGoods(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	If HandlerParameters.CalculationParameters.AllCompanies Then 
		Query.SetParameter("Recipient", New Array);
	Else
		Query.SetParameter("Recipient", HandlerParameters.CalculationParameters.CompanyArray);
	EndIf;	
	Query.SetParameter("IssueRansoms", True);
	Query.Text = TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query, "VTKRegistrationOfRepurchases");
		
	Query.Execute();
			
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "VTKRegistrationOfRepurchases", HandlerParameters) = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư hàng hóa để mua lại trong biểu ghi ""Dự phòng hàng hóa trong doanh nghiệp""';
				|ru = 'Нет остатков товаров к выкупу в регистре ""Резервы товаров организаций""';
				|en = 'No stock balance to redemption in the ""Company goods reserves"" register'; fa = 'No stock balance to redemption in the ""Company goods reserves"" register';
				|it = 'Non ci sono rimanenze di merci da riscattare nel registro ""Riserve delle merci delle organizzazioni""';
				|pl = 'Brak pozostałości towarów do wykupu w rejestrze ""Резервы товаров организаций""';
				|tr = '""İş yerlerinin ürün rezervleri"" sicilinde satın alınacak ürün bakiyesi mevcut değil'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_ExecutionOfRedemptionOfGoods(TableOfChecks) Export
	
	// Registration of the redemption of goods.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"NoRedemptionOfGoods",
		Catalogs.MonthEndClosingOperations.RegisterGoodsRedemption,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"InventoriesServer.CheckingRemainingGoodsForRedemption");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chưa lập chứng từ mua lại hàng hóa đã tiếp nhận vào nơi cất giữ';
			|ru = 'Не оформленные выкупы товаров, принятых на ответственное хранение';
			|en = 'Non-registered redemptions of available VMI'; fa = 'Non-registered redemptions of available VMI';
			|it = 'Riscatto di beni in custodia non regolarizzato';
			|pl = 'Nie sporządzone wykupy towarów, przyjętych do depozytowania';
			|tr = 'Satıcı tarafından yönetilen kayıt dışı ürün satın alımları'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần tạo các chứng từ ""Mua hàng hóa từ kho"".';
			|ru = 'Должны быть оформлены документы ""Выкуп товаров с хранения"".';
			|en = 'The ""Purchase invoice — VMI"" documents should be registered.'; fa = 'The ""Purchase invoice — VMI"" documents should be registered.';
			|it = 'Devono essere regolarizzati i documenti ""Riscatto delle merci dal magazzino"".';
			|pl = 'Muszą być sporządzone dokumenty ""Выкуп товаров с хранения"".';
			|tr = '""Satın alma faturası - VMI"" belgeleri düzenlenmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

Procedure CheckingRemainingGoodsForRedemption(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			   NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Company';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes", NStr("vi = 'Chỉ số mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",		 		   NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Quantità';
													|pl = 'Ilość';
													|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"VTKRegistrationOfRepurchases",
		NStr("vi = 'Đã tìm thấy hàng hóa yêu cầu tạo mua lại theo doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены товары, требующие оформления выкупа по организации ""%1"" на конец периода %2';
			|en = 'Goods that require redemption registration are detected for the ""%1"" company at the end of %2 period'; fa = 'Goods that require redemption registration are detected for the ""%1"" company at the end of %2 period';
			|it = 'Trovati delle merci il cui riscatto per l''organizzazione ""%1"" per la fine del periodo %2 deve essere regolarizzato';
			|pl = 'Wykryto wiersze pozycji, wymagające sporządzenia wykupu wg firmy ""%1"" na koniec okresu %2';
			|tr = '""%1"" iş yeri için %2 döneminin sonunda satın alınması gereken ürünler bulundu'", Common.DefaultLanguageCode()),
		FieldList);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region RegistrationOfCommissionReportsIntercompany

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - ValueTable - table of stages (See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable)
//                                   .
//	CurrentParent - String - group ID.
//
Procedure AddStage_RegistrationOfCommissionReportsIntercompany(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RegistrationOfCommissionReportsIntercompany);
	
	NewRow.MultilingualName = "vi = 'Lập báo cáo về hoa hồng giữa các doanh nghiệp';
								|ru = 'Оформление отчетов по комиссии между организациями';
								|en = 'Register ""Consignment notifications — Intercompany"" ';
								|it = 'Formalizzazione dei report sulla commissione tra le aziende';
								|pl = 'Edycja raportów po komisji sprawdzającej pomiędzy firmami';
								|tr = 'Şirketler arası komisyon raporlarının düzenlenmesi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute     = NStr("vi = 'Tạo';
									|ru = 'Оформить';
									|en = 'Register'; fa = 'ثبات';
									|it = 'Preparare';
									|pl = 'Register';
									|tr = 'Düzenle'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InventoriesServer.Use_PreparationOfCommissionReportsBetweenOrganizations");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.LogOfIntercompanyDocuments.Forms.RegisterCommissionReports.FullName());
	
EndProcedure

// Stage handlers.

Procedure Use_PreparationOfCommissionReportsBetweenOrganizations(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text = "
	|SELECT
	|	Keys.StorageLocation AS Consignee,
	|	GoodsTransferred.InventoryOwnerAttribute.Organization AS Consignor,
	|	Keys.Products AS Products,
	|	Keys.Characteristic AS Characteristic,
	|	Keys.Purpose AS Purpose,
	|	GoodsTransferred.CountClosingBalance - GoodsTransferred.CountOpeningBalance AS Count
	|INTO BalancesOfGoodsTransferred
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod) AS GoodsTransferred
	|
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON Keys.Ref = GoodsTransferred.ItemsLocationAttributes
	|WHERE
	|	GoodsTransferred.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Organization)
	|	AND (GoodsTransferred.CountClosingBalance - GoodsTransferred.CountOpeningBalance <> 0)
	|
	|INDEX BY
	|	Keys.StorageLocation,
	|	GoodsTransferred.InventoryOwnerAttribute.Organization,
	|	Keys.Products,
	|	Keys.Characteristic,
	|	Keys.Purpose
	|;
	|///////////////////////////////////////////////////
	|SELECT
	|	ToRegister.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ToRegister.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ToRegister.CCDNumber AS CCDNumber,
	|	ToRegister.InventoryOwnerAttribute.Organization AS Consignee,
	|	ToRegister.InventoryOwnerAttribute.GoodsOwner AS Consignor,
	|	Keys.Products AS Products,
	|	Keys.Characteristic AS Characteristic,
	|	Keys.Purpose AS Purpose,
	|	ToRegister.CountClosingBalance - ToRegister.CountOpeningBalance
	|		+ ToRegister.QuantityConsumedClosingBalance - ToRegister.QuantityConsumedOpeningBalance AS Count
	|INTO LeftoversForClearanceAll
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod) AS ToRegister
	|
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON Keys.Ref = ToRegister.ItemsLocationAttributes
	|WHERE
	|	ToRegister.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Organization)
	|	AND ((ToRegister.CountClosingBalance - ToRegister.CountOpeningBalance <> 0)
	|		OR (ToRegister.QuantityConsumedClosingBalance - ToRegister.QuantityConsumedOpeningBalance <> 0))
	|
	|INDEX BY
	|	ToRegister.InventoryOwnerAttribute.Organization,
	|	ToRegister.InventoryOwnerAttribute.GoodsOwner,
	|	Keys.Products,
	|	Keys.Characteristic,
	|	Keys.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ToRegister.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ToRegister.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ToRegister.CCDNumber AS CCDNumber,
	|	ToRegister.Consignee AS Consignee,
	|	ToRegister.Consignor AS Consignor,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ToRegister.Purpose AS Purpose,
	|	CASE WHEN ToRegister.Count < GoodsTransferred.Count
	|		THEN ToRegister.Count
	|		ELSE GoodsTransferred.Count
	|	END AS Count
	|INTO RemnantsOfGoodsForRegistration
	|FROM
	|	LeftoversForClearanceAll AS ToRegister
	|
	|	INNER JOIN BalancesOfGoodsTransferred AS GoodsTransferred
	|	ON ToRegister.Consignee = GoodsTransferred.Consignee
	|		AND ToRegister.Consignor = GoodsTransferred.Consignor
	|		AND ToRegister.Products = GoodsTransferred.Products
	|		AND ToRegister.Characteristic = GoodsTransferred.Characteristic
	|		AND ToRegister.Purpose = GoodsTransferred.Purpose
	|WHERE
	|	ToRegister.Count <> 0
	|	AND GoodsTransferred.Count <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ToRegister.Consignor AS Organization,
	|	ToRegister.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ToRegister.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ToRegister.CCDNumber AS CCDNumber,
	|	ToRegister.Consignee AS Consignee,
	|	ToRegister.Consignor AS Consignor,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ToRegister.Purpose AS Purpose,
	|	ToRegister.Count AS Count
	|INTO TTCommitteeBalances
	|FROM
	|	RemnantsOfGoodsForRegistration AS ToRegister
	|WHERE
	|	ToRegister.Consignor IN(&CompanyArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ToRegister.Consignee AS Organization,
	|	ToRegister.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ToRegister.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ToRegister.CCDNumber AS CCDNumber,
	|	ToRegister.Consignee AS Consignee,
	|	ToRegister.Consignor AS Consignor,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ToRegister.Purpose AS Purpose,
	|	ToRegister.Count AS Count
	|INTO TTCommissionAgentSBalances
	|FROM
	|	RemnantsOfGoodsForRegistration AS ToRegister
	|WHERE
	|	ToRegister.Consignee IN(&CompanyArray)
	|";
	
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TTCommitteeBalances = 0 And TemporaryTableSizes.TTCommissionAgentSBalances = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư trong biểu ghi ""Hàng hóa cần lập bảng kê của người đặt ký gửi"" theo sơ đồ liên công ty';
				|ru = 'Нет остатков в регистре ""Товары к оформлению отчетов комитенту"" по схеме Интеркампани';
				|en = 'No balance in the ""Goods for consignment notifications issue"" register under Intercompany'; fa = 'No balance in the ""Goods for consignment notifications issue"" register under Intercompany';
				|it = 'Non ci sono rimanenze nel registro ""Merci per la regolarizzazione dei rapporti al committente"" secondo lo schema Intercompany';
				|pl = 'Brak pozostałości w rejestrze  ""Товары к оформлению отчетов комитенту"" wg schematu Intercompany';
				|tr = 'Şirketlerarası şemaya göre ""Kaydedilecek ürünler için konsinye bildirimi"" sicilinde bakiye yok'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfInspections_PreparationOfCommissionReportsBetweenOrganizations(TableOfChecks) Export
	
	// Preparation of commission reports between organizations.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"FailedToIssueCommissionReportsBetweenOrganizations",
		Catalogs.MonthEndClosingOperations.RegistrationOfCommissionReportsIntercompany,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"InventoriesServer.CheckingPreparationOfReportsToCommitteeBetweenOrganizations");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chưa lập bảng kê ký gửi giữa các doanh nghiệp';
			|ru = 'Не оформленные отчеты по комиссии между организациями';
			|en = '""Commission reports — Intercompany"" that are not registered'; fa = '""Commission reports — Intercompany"" that are not registered';
			|it = 'Report sulla commissione tra le organizzazioni non regolarizzate';
			|pl = 'Nie sporządzone raporty wg prowizji między firmami';
			|tr = 'Düzenlenmeyen komisyon raporu - şirketler arası'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần tạo chứng từ ""Bảng kê ký gửi giữa các doanh nghiệp"" và ""Bảng kê ký gửi giữa các doanh nghiệp về ghi giảm""';
			|ru = 'Должны быть оформлены документы ""Отчет по комиссии между организациями"" и ""Отчет по комиссии между организациями о списании"".';
			|en = 'The ""Commission sales report — Intercompany"" and ""Commission write-off report — Intercompany"" documents must be registered.'; fa = 'The ""Commission sales report — Intercompany"" and ""Commission write-off report — Intercompany"" documents must be registered.';
			|it = 'Devono essere regolarizzati i documenti ""Report sulla commissione tra le organizzazioni"" e ""Report sulla commissione tra le organizzazioni sullo storno"".';
			|pl = 'Muszą być sporządzone dokumenty ""Raport po komisji sprawdzającej pomiędzy firmami"" oraz ""Raport w sprawie komisji pomiędzy firmami o rozchodowaniu"".';
			|tr = '""İşyerleri arası komisyon satış raporu"" ve ""Komisyon iptal raporu - Şirketler arası"" belgeleri düzenlenmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

Procedure CheckingPreparationOfReportsToCommitteeBetweenOrganizations(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			   NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Company';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Consignee", 			   NStr("vi = 'Doanh nghiệp nhận ký gửi';
													|ru = 'Организация-комиссионер';
													|en = 'Consignee company'; fa = 'Consignee company';
													|it = 'Società-commissionaria';
													|pl = 'Consignee company';
													|tr = 'Konsinye iş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes", NStr("vi = 'Đối tượng phân tích mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute", 				   NStr("vi = 'Dạng hàng tồn kho';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	FieldList.Add("CCDNumber", 				   NStr("vi = 'Số tờ khai hải quan';
														|ru = 'Номер ГТД';
														|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
														|it = 'Numero della polizza doganale di carico';
														|pl = 'Numer ŁDC (ładunkowej deklaracji celnej)';
														|tr = 'Gümrük Kargo Beyannamesi numarası'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",		 		   NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Quantità';
													|pl = 'Ilość';
													|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTCommitteeBalances",
		NStr("vi = 'Đã tìm thấy hàng hóa, yêu cầu lập bảng kê bán hàng hóa dành cho người đặt ký gửi ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены товары, требующие оформления отчетов комитенту ""%1"" на конец периода %2';
			|en = 'Goods that require consignment notifications issue to the ""%1"" consignor were detected as of the end of %2 period'; fa = 'Goods that require consignment notifications issue to the ""%1"" consignor were detected as of the end of %2 period';
			|it = 'Trovate delle merci i cui rapporti al committente ""%1"" per la fine del periodo %2 devono essere regolarizzati';
			|pl = 'Wykryto wiersze pozycji, wymagające sporządzenia raportów do komitenta ""%1"" na koniec okresu %2';
			|tr = '%2 döneminin sonunda ""%1"" konsinye bildirimi kaydı gereken ürünler bulundu'"),
		FieldList);
		
	FieldList = New ValueList;
	FieldList.Add("Organization", 			   NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Company';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Consignor", 				   NStr("vi = 'Doanh nghiệp đặt ký gủi';
														|ru = 'Организация-комитент';
														|en = 'Consignor company'; fa = 'شرکت امانت‌گذار';
														|it = 'Società-committente';
														|pl = 'Consignor company';
														|tr = 'Gönderici iş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes", NStr("vi = 'Đối tượng phân tích mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute", 				   NStr("vi = 'Dạng hàng tồn kho';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	FieldList.Add("CCDNumber", 				   NStr("vi = 'Số tờ khai hải quan';
														|ru = 'Номер ГТД';
														|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
														|it = 'Numero della polizza doganale di carico';
														|pl = 'Numer ŁDC (ładunkowej deklaracji celnej)';
														|tr = 'Gümrük Kargo Beyannamesi numarası'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",		 		   NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Quantità';
													|pl = 'Ilość';
													|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	MonthEndTransactionsServer.AddRegistrationAndVerificationParameters(RegistrationParameters,
		"TTCommissionAgentSBalances",
		NStr("vi = 'Đã tìm thấy hàng hóa, yêu cầu lập bảng kê bán hàng hóa dành cho người đặt ký gửi từ doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены товары, требующие оформления отчетов комитенту от организации ""%1"" на конец периода %2';
			|en = 'Goods were detected that require consignment notifications issue to the consignor from the ""%1"" company as of the end of %2 period'; fa = 'Goods were detected that require consignment notifications issue to the consignor from the ""%1"" company as of the end of %2 period';
			|it = 'Trovate delle merci i cui rapporti al committente dall''organizzazione ""%1"" per la fine del periodo %2 devono essere regolarizzati';
			|pl = 'Wykryto wiersze pozycji, wymagające sporządzenia raportów do komitenta od firmy ""%1"" na koniec okresu %2';
			|tr = '%2 döneminin sonunda ""%1"" iş yeri tarafından konsinye bildirimi kaydı gereken ürünler bulundu'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region RegisterWriteOffReportsToConsignors

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - ValueTable - table of stages (See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable)
//                                   .
//	CurrentParent - String - group ID.
//
Procedure AddStage_RegisterWriteOffReportsToConsignors(StepsTable,CurrentParent) Export

	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterWriteOffReportsToConsignors);
	
	NewRow.MultilingualName = "vi = 'Lập báo cáo cho người đặt ký gửi về ghi giảm';
								|ru = 'Оформление отчетов комитентам о списании';
								|en = 'Register write-off reports to consignors';
								|it = 'Formalizzazione dei report sullo storno ai committenti ';
								|pl = 'Rejestracja sprawozdań z rozchodów dla komitentów';
								|tr = 'Tedarikçi konsinye stok ayarlamalarının düzenlenmesi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute     = NStr("vi = 'Lập bảng kê';
									|ru = 'Оформить';
									|en = 'Register'; fa = 'ثبات';
									|it = 'Preparare';
									|pl = 'Register';
									|tr = 'Düzenle'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InventoriesServer.Use_PreparationOfReportsToCommitteesOnWriteOffs");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.AccountSalesToConsignors.Forms.DocumentsList.FullName());
EndProcedure

// Stage handlers.

Procedure Use_PreparationOfReportsToCommitteesOnWriteOffs(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	ToRegister.InventoryOwnerAttribute.Organization AS Organization,
	|	ToRegister.ItemsLocationAttributes.StorageLocation AS Consignor,
	|	ToRegister.ItemsLocationAttributes,
	|	ToRegister.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ToRegister.CCDNumber,
	|	ToRegister.QuantityConsumedClosingBalance - ToRegister.QuantityConsumedOpeningBalance AS Count
	|INTO VTKRegistration
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod, , ,
	|			NOT ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Organization)
	|			AND InventoryOwnerAttribute.Organization IN (&CompanyArray)) AS ToRegister
	|
	|WHERE
	|	ToRegister.QuantityConsumedClosingBalance - ToRegister.QuantityConsumedOpeningBalance <> 0";
	
	Query.Execute();
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "VTKRegistration", HandlerParameters) = 0 Then
		Explanation = NStr("vi = 'Không có số dư trong biểu ghi ""Hàng hóa cần lập bảng kê cho người đặt ký gửi"" theo người đặt ký gửi bên ngoài';
							|ru = 'Нет остатков в регистре ""Товары к оформлению отчетов комитенту"" по сторонним комитентам';
							|en = 'No balance in the ""Goods for consignment notifications issue"" register for third-party consignors'; fa = 'No balance in the ""Goods for consignment notifications issue"" register for third-party consignors';
							|it = 'Non ci sono rimanenze nel registro ""Merci per la regolarizzazione dei rapporti al committente"" secondo i committenti esterni';
							|pl = 'Brak pozostałości w rejestrze  ""Товары к оформлению отчетов комитенту"" wg postronnych komitentów';
							|tr = 'Üçüncü taraf göndericiler için ""Konsinye bildirimi kaydı gereken ürünler"" kaydında bakiye yok'",
						Common.DefaultLanguageCode());
		
		MonthEndTransactionsServer.NoNeedToSetState(HandlerParameters, Explanation);
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_PreparationOfReportsToCommitteesOnWriteOffs(TableOfChecks) Export
	
	// Preparation of reports to the committees on the write-off.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"CompletionOfReportsToCommitteeOnDebitingWasNotCompleted",
		Catalogs.MonthEndClosingOperations.RegisterWriteOffReportsToConsignors,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"InventoriesServer.CheckingExecutionOfReportsToCommitteeOnDebiting");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Báo cáo đặt ký gửi về ghi giảm chưa được tạo';
			|ru = 'Не оформленные отчеты комитентам о списании';
			|en = 'Non-registered vendor consignment stock adjustments'; fa = 'Non-registered vendor consignment stock adjustments';
			|it = 'Report ai committenti sullo storno non regolarizzati';
			|pl = 'Nie sporządzone raporty do komitentów o wyksięgowaniu';
			|tr = 'Düzenlenmeyen satıcı konsinye stok düzeltmeleri'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần tạo chứng từ ""Báo cáo đặt ký gửi về ghi giảm"".';
			|ru = 'Должны быть оформлены документы ""Отчет комитенту о списании"".';
			|en = 'The ""Vendor consignment stock adjustment"" documents should be registered.'; fa = 'The ""Vendor consignment stock adjustment"" documents should be registered.';
			|it = 'Devono essere regolarizzati i documenti ""Report al committente sullo storno"".';
			|pl = 'Muszą być sporządzone dokumenty ""Отчет комитенту о списании"".';
			|tr = '""Satıcı konsinye stok düzeltmesi"" belgeleri düzenlenmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

Procedure CheckingExecutionOfReportsToCommitteeOnDebiting(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			   NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Firma';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Consignor", 				   NStr("vi = 'Người đặt ký gửi';
														|ru = 'Комитент';
														|en = 'Consignor'; fa = 'امانت‌گذار';
														|it = 'Committente';
														|pl = 'Komitent';
														|tr = 'Gönderici'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes", NStr("vi = 'Chỉ số mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute", 				   NStr("vi = 'Dạng hàng tồn kho';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	FieldList.Add("CCDNumber", 				   NStr("vi = 'Số tờ khai hải quan';
														|ru = 'Номер ГТД';
														|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
														|it = 'Numero della polizza doganale di carico';
														|pl = 'Numer ŁDC (ładunkowej deklaracji celnej)';
														|tr = 'Gümrük Kargo Beyannamesi numarası'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",		 		   NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Quantità';
													|pl = 'Quantity';
													|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"VTKRegistration",
		NStr("vi = 'Đã tìm thấy các mặt hàng cần lập bảng kê bán hàng hóa dành cho người ký gửi về ghi giảm từ doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены товары, требующие оформления отчетов комитенту о списании от организации ""%1"" на конец периода %2';
			|en = 'Goods were detected that require consignment notifications from the ""%1"" company as of the end of %2 period'; fa = 'Goods were detected that require consignment notifications from the ""%1"" company as of the end of %2 period';
			|it = 'Trovate delle merci i cui rapporti al committente sullo storno dall''organizzazione ""%1"" per la fine del periodo %2 devono essere regolarizzati';
			|pl = 'Wykryto wiersze pozycji, wymagające sporządzenia raportów do komitenta o wyksięgowaniu od firmy ""%1"" na koniec okresu %2';
			|tr = '%2 döneminin sonunda ""%1"" iş yerinden tedarikçi konsinye stok ayarlaması gerektiren ürünler bulundu'", Common.DefaultLanguageCode()),
		FieldList);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region FillingStockTypes

// Returns an empty table of values whose rows describe the values of inventory types ' details.
//
// Returns:
//	ValueTable - which contains the following columns:
//		* LineNumber - Number - row number of the table.
//		* ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - analysis of product range accounting.
//		* Organization - CatalogRef.Companies - organization-seller of goods.
//		* InventoryOwnerAttribute - CatalogRef.InventoryKinds - type of inventory.
//		* CCDNumber - CatalogRef.CCDNumbers - the product's GTD number.
//		* GoodsOwner - CatalogRef.Companies, CatalogRef.Partners - the owner of the goods.
//		* InventoryType - EnumRef.InventoryTypes - the type of inventory item.
//		* Counterparty - CatalogRef.Companies, CatalogRef.Counterparties - the recipient of the goods.
//		* Contract - CatalogRef.IntercompanyContracts, CatalogRef.CounterpartyContracts - the contract under which the goods are transferred.
//
Function EmptyTableOfDetailsOfStockTypesByDefault() Export
	
	Result = New ValueTable;
	
	Result.Columns.Add("LineNumber",
						New TypeDescription("Number"));
	Result.Columns.Add("ItemsLocationAttributes",
						New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	Result.Columns.Add("Organization",
						New TypeDescription("CatalogRef.Companies"));
	Result.Columns.Add("InventoryOwnerAttribute",
						New TypeDescription("CatalogRef.InventoryKinds"));
	Result.Columns.Add("CCDNumber",
						New TypeDescription("CatalogRef.CCDNumbers"));
	Result.Columns.Add("GoodsOwner",
						Metadata.Catalogs.InventoryKinds.Attributes.GoodsOwner.Type);
	Result.Columns.Add("InventoryType",
						New TypeDescription("EnumRef.InventoryTypes"));
	Result.Columns.Add("Counterparty",
						Metadata.Catalogs.InventoryKinds.Attributes.Counterparty.Type);
	Result.Columns.Add("Contract",
						Metadata.Catalogs.InventoryKinds.Attributes.Contract.Type);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region FillingStockTypes

Function UncontrolledInventoryTypes()
	
	InventoryTypes = New Array;
	InventoryTypes.Add(Enums.InventoryTypes.OwnGoodsInTransit);
	InventoryTypes.Add(Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery);
	
	Return InventoryTypes;
	
EndFunction

Function WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault(ParametersForFillingInventoryTypes)
	
	ParametersArray = New Array;
	If TypeOf(ParametersForFillingInventoryTypes) = Type("Array") Then
		ParametersArray = ParametersForFillingInventoryTypes;
	Else
		ParametersArray.Add(ParametersForFillingInventoryTypes);
	EndIf;
	
	Result = False;
	
	For Each CurrentParameters In ParametersArray Do
		
		If CurrentParameters = Undefined
			Or CurrentParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = Undefined Then
			Result = Not GetFunctionalOption("ControlCompanyStockBalance");
		Else
			Result = CurrentParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault;
		EndIf;
		
		If Result Then
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function InventoryOwnerAttributeIsInitializedByDefault(ParametersForFillingInventoryTypes)
	
	ParametersArray = New Array;
	If TypeOf(ParametersForFillingInventoryTypes) = Type("Array") Then
		ParametersArray = ParametersForFillingInventoryTypes;
	Else
		ParametersArray.Add(ParametersForFillingInventoryTypes);
	EndIf;
	
	Result = Undefined;
	
	For Each CurrentParameters In ParametersArray Do
		If CurrentParameters = Undefined
			Or CurrentParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = Undefined Then
			
			Continue;
			
		Else
			Result = CurrentParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault;
		EndIf;
		
		If TypeOf(Result) = Type("Boolean") Then
			Break;
		EndIf;
		
	EndDo;
	
	Return Result <> Undefined;
	
EndFunction

Function DocumentOrganization(DocumentObject, ParametersForFillingInventoryTypes)
	
	If ValueIsFilled(ParametersForFillingInventoryTypes.CompanyFieldName1) Then
		
		If TypeOf(DocumentObject) = Type("DocumentObject.ReversingEntry")
			And Not CommonClientServer.HasAttributeOrObjectProperty(DocumentObject, ParametersForFillingInventoryTypes.CompanyFieldName1) Then
			
			Return Common.ObjectAttributeValue(DocumentObject.ReversedDocument,
																ParametersForFillingInventoryTypes.CompanyFieldName1);
			
		Else
			Return DocumentObject[ParametersForFillingInventoryTypes.CompanyFieldName1];
		EndIf;
		
	ElsIf ValueIsFilled(ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization) Then
		Return ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization;
	Else
		ExceptionText = NStr("vi = 'Lỗi trong chương trình: không thể xác định doanh nghiệp của chứng từ.';
							|ru = 'Ошибка в программе: невозможно определить организацию документа.';
							|en = 'An error occurred in the application: cannot identify the company mentioned in the document.'; fa = 'An error occurred in the application: cannot identify the company mentioned in the document.';
							|it = 'Errore nel programma: impossibile definite l''azienda del documento.';
							|pl = 'Błąd w programie: niemożliwe jest określenie firmy dokumentu.';
							|tr = 'Program hatası: Belgenin iş yeri belirlenemiyor.'");
		Raise ExceptionText;
	EndIf;
	
EndFunction

Function OrganizationsForBalanceControl(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT DISTINCT
	|	TTProductsAndChanges.Organization AS Organization
	|FROM
	|	TTProductsAndChanges AS TTProductsAndChanges
	|WHERE
	|	TTProductsAndChanges.ForResidueControl";
	Result = Query.Execute();
	Companies = Result.Unload().UnloadColumn("Organization");
	Return Companies;
	
EndFunction

Procedure ToFormVTGoodsOfOrganizationsChanges(DocumentObject,
													TempTablesManager,
													ParametersForFillingInventoryTypes)
	
	CheckForTemporaryReserveTables(TempTablesManager, "CompanyGoods");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	CompanyGoods.Period AS Period,
	|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoods.Organization AS Organization,
	|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber AS CCDNumber,
	|	CompanyGoods.Count AS Count,
	|	CompanyGoods.QuantityByGBRN AS QuantityByGBRN,
	|	CompanyGoods.ReversingEntry AS ReversingEntry,
	|	CatalogProducts.ItemsType AS ItemsType
	|INTO ItemsFromOrganizationsWithType
	|FROM
	|	CompanyGoods AS CompanyGoods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON (InventoryLocationAttributeKeys.Ref = CompanyGoods.ItemsLocationAttributes)
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = InventoryLocationAttributeKeys.Products)
	|
	|INDEX BY
	|	ItemsType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsOfOrganizationsChanges.Period AS Period,
	|	ProductsOfOrganizationsChanges.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ProductsOfOrganizationsChanges.Organization AS Organization,
	|	ProductsOfOrganizationsChanges.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ProductsOfOrganizationsChanges.CCDNumber AS CCDNumber,
	|	SUM(ProductsOfOrganizationsChanges.Count) AS Count,
	|	SUM(ProductsOfOrganizationsChanges.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(CASE
	|			WHEN ProductsOfOrganizationsChanges.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				THEN 0
	|			ELSE ProductsOfOrganizationsChanges.Count
	|		END) > 0 AS ForStornoReserve,
	|	SUM(ProductsOfOrganizationsChanges.Count) < 0 AS ForResidueControl
	|INTO TTProductsAndChanges
	|FROM
	|	(SELECT
	|		ENDOFPERIOD(CompanyGoods.Period, MONTH) AS Period,
	|		CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanyGoods.ItemsType AS ItemsType,
	|		CompanyGoods.Organization AS Organization,
	|		CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanyGoods.CCDNumber AS CCDNumber,
	|		CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CompanyGoods.Count
	|			ELSE -CompanyGoods.Count
	|		END AS Count,
	|		CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|			ELSE CAST(-CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|		END AS QuantityByGBRN
	|	FROM
	|		MovementOfOrganizationsProductsBeforeRecording AS CompanyGoods
	|	WHERE
	|		CompanyGoods.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.Work_5),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|		AND (NOT &SelectStocksOfDifferentPeriods
	|			OR ENDOFPERIOD(CompanyGoods.Period, MONTH) >= &FillingPeriod)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ENDOFPERIOD(CompanyGoods.Period, MONTH),
	|		CompanyGoods.ItemsLocationAttributes,
	|		CompanyGoods.ItemsType,
	|		CompanyGoods.Organization,
	|		CompanyGoods.InventoryOwnerAttribute,
	|		CompanyGoods.CCDNumber,
	|		CompanyGoods.Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanyGoods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|		END
	|	FROM
	|		ItemsFromOrganizationsWithType AS CompanyGoods
	|	WHERE
	|		CompanyGoods.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.Work_5),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|		AND (NOT &SelectStocksOfDifferentPeriods
	|			OR ENDOFPERIOD(CompanyGoods.Period, MONTH) >= &FillingPeriod)
	|	
	|	) AS ProductsOfOrganizationsChanges
	|
	|GROUP BY
	|	ProductsOfOrganizationsChanges.ItemsLocationAttributes,
	|	ProductsOfOrganizationsChanges.Period,
	|	ProductsOfOrganizationsChanges.Organization,
	|	ProductsOfOrganizationsChanges.InventoryOwnerAttribute,
	|	ProductsOfOrganizationsChanges.CCDNumber
	|
	|HAVING
	|	SUM(ProductsOfOrganizationsChanges.Count) <> 0
	|";
	
	Query.SetParameter("Recorder",					DocumentObject.Ref);
	Query.SetParameter("SelectStocksOfDifferentPeriods",	ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods);
	Query.SetParameter("FillingPeriod",				ParametersForFillingInventoryTypes.FillingPeriod);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Execute();
	
EndProcedure

// To select those accepted for safekeeping.
// 
// Parameters:
//  ParametersForFillingInventoryTypes - See InventoriesServer.ParametersForFillingInventoryTypes
//  ProductSelection_4 - QueryResultSelection - The sample of goods
// 
// Returns:
//  Undefined, String - To select those accepted for safekeeping
//
Function PickUpVTCHGoodsAcceptedForResponsibleStorage(ParametersForFillingInventoryTypes, ProductSelection_4)
	
	PickUpVTCHGoodsAcceptedForResponsibleStorage =
		ParametersForFillingInventoryTypes.PickUpVTCHGoodsAcceptedForResponsibleStorage.Get(ProductSelection_4.InventoryType);
	
	If PickUpVTCHGoodsAcceptedForResponsibleStorage = Undefined Then
		Return Undefined;
	ElsIf Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) = Upper("Always")
		Or Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) = Upper("Never")
		Or Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) = Upper("ByAgreementSettings")
		Or Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) = Upper("AccordingToSettingsOfProductionContract") Then
		
		Return PickUpVTCHGoodsAcceptedForResponsibleStorage;
		
	ElsIf Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) = Upper("ByBusinessTransaction") Then
		
		ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation =
			ParametersForFillingInventoryTypes.ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation.Get(ProductSelection_4.InventoryType);
		
		If ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation = Undefined Then
			ExceptionText = NStr("vi = 'Trong các tham số điền dạng vật tư, chưa xác định điền hoặc điền hàng hóa đã tiếp nhận vào nơi cất giữ đối với kiểu vật tư không vào phần bảng %InventoryType%.';
								|ru = 'В параметрах заполнения видов запасов не определено подставлять или нет в табличную часть товары, принятые на ответственное хранение для типа запасов %InventoryType%.';
								|en = 'In the parameters for filling the inventory owner attributes, it is not defined whether to insert the available VMI in the table for the %InventoryType% inventory type.'; fa = 'In the parameters for filling the inventory owner attributes, it is not defined whether to insert the available VMI in the table for the %InventoryType% inventory type.';
								|it = 'Nei parametri di compilazione dei tipi di scorte non è definito se sostituire o meno nella parte tabellare le merci ricevute in custodia per il tipo di scorte %InventoryType%.';
								|pl = 'W parametrach wypełnienia rodzajów zapasów nie określono, czy należy wstawiać do sekcji tabelarycznej towary, przyjęte do depozytowania dla typu zapasów %InventoryType%.';
								|tr = 'Stok türlerinin doldurulmasına ilişkin parametrelerde, %InventoryType% stok türü için satıcı tarafından yönetilen ürünlerin tablo bölümünde ikame edilip edilmeyeceği tanımlanmamıştır.'");
			ExceptionText = StrReplace(ExceptionText, "%InventoryType%", ProductSelection_4.InventoryType);
			Raise ExceptionText;
		EndIf;
		
		PickUpVTCHGoodsAcceptedForResponsibleStorage =
			ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation[ProductSelection_4.BusinessOperation];
			
		If Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) <> Upper("Always")
			And Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) <> Upper("Never")
			And Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) <> Upper("ByAgreementSettings")
			And Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) <> Upper("AccordingToSettingsOfProductionContract") Then
			ExceptionText = NStr("vi = 'Trong các tham số điền dạng vật tư chưa xác định điền hoặc trong phần bảng không có hàng hóa đã nhận vào nơi cất giữ đối với giao dịch kinh tế %BusinessOperation%.';
								|ru = 'В параметрах заполнения видов запасов не определено подставлять или нет в табличную часть товары, принятые на ответственное хранение для хозяйственной операции %BusinessOperation%.';
								|en = 'In the parameters for filling in the inventory owner attributes, it is not defined whether to insert the available VMI in the table for the business transaction %BusinessOperation%.'; fa = 'In the parameters for filling in the inventory owner attributes, it is not defined whether to insert the available VMI in the table for the business transaction %BusinessOperation%.';
								|it = 'Nei parametri di compilazione dei tipi di scorte non è definito se inserire o no nella tabella le merci accettate in custodia per l''operazione gestionale %BusinessOperation%.';
								|pl = 'W parametrach dotyczących wypełniania typów zapasów nie jest określone, czy należy wstawić do części tabelarycznej wiersze pozycji przyjęte do odpowiedzialnego przechowywania dla operacji gospodarczej %BusinessOperation%.';
								|tr = 'Stok türlerinin doldurulmasına ilişkin parametrelerde, %BusinessOperation% ticari işlemi için satıcı tarafından yönetilen ürünlerin tablo bölümünde değiştirilip değiştirilmeyeceği tanımlanmamıştır.'");
			ExceptionText = StrReplace(ExceptionText, "%BusinessOperation%", ProductSelection_4.BusinessOperation);
			Raise ExceptionText;
		EndIf;
		
		Return PickUpVTCHGoodsAcceptedForResponsibleStorage;
	Else
		ExceptionText = NStr("vi = 'Trong các tham số điền dạng vật tư chưa xác định điền hoặc trong phần bảng không có hàng hóa đã nhận vào nơi cất giữ.';
							|ru = 'В параметрах заполнения видов запасов не определено подставлять или нет в табличную часть товары, принятые на ответственное хранение.';
							|en = 'In the filling parameters for inventory owner attributes, it is not defined whether to add the available VMI to the table.'; fa = 'In the filling parameters for inventory owner attributes, it is not defined whether to add the available VMI to the table.';
							|it = 'Nei parametri di compilazione dei tipi di scorte non è definito se inserire o meno nella parte tabellare la merce accettata per la custodia sicura.';
							|pl = 'W parametrach dotyczących wypełniania typów zapasów nie jest określone, czy należy wstawić do części tabelarycznej wiersze pozycji przyjęte do odpowiedzialnego składowania.';
							|tr = 'Stok türlerinin doldurulmasına ilişkin parametrelerde, tablo bölümünde satıcı tarafından yönetilen ürün ikame edilip edilmeyeceği tanımlanmamıştır.'");
		Raise ExceptionText;
	EndIf;
	
EndFunction

Procedure FillInTypesOfReservesAccordingToTableOfBalancesFormTTNewReserves(DocumentObject, TempTablesManager, Cancel, ParametersForFillingInventoryTypes)
	
	ErrorsTable			= TableOfErrorsInFillingInventoryTypes();
	AdditionalProperties	= DocumentObject.AdditionalProperties;
	
	If ParametersForFillingInventoryTypes.TableTypesOfStocks_ <> Undefined Then
		TableTypesOfStocks_ = ParametersForFillingInventoryTypes.TableTypesOfStocks_;
	Else
		TableTypesOfStocks_ = DocumentObject[ParametersForFillingInventoryTypes.NameTSTypesOfStocks].UnloadColumns();
	EndIf;
	
	ControlChangeOfCCDNumbers = AdditionalProperties.Property("ControlChangeOfCCDNumbers");
	
	If ControlChangeOfCCDNumbers Then
		TableOfCCDNumbers = TableTypesOfStocks_.Copy(, "ItemsLocationAttributes, CCDNumber, Count"); // ValueTable
	EndIf;
	
	DefaultStockView	= Undefined;
	TableNewReserves		= AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	
	WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault =
		WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault(ParametersForFillingInventoryTypes);
	IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited = 
		Not WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault
		And ParametersForFillingInventoryTypes.IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited;
	InventoryOwnerAttributeIsInitializedByDefault = InventoryOwnerAttributeIsInitializedByDefault(
																ParametersForFillingInventoryTypes);
	
	StringDataStructure = New Structure("
		|Warehouse,
		|Count,
		|QuantityByGBRN,
		|AmountIncludingVAT,
		|VATRate,
		|VATAmount,
		|CommissionAmount,
		|AmountVATRemuneration,
		|ExciseTaxAmount,
		|ItemsLocationAttributesShipment,
		|InventoryOwnerAttributeShipment,
		|CorInventoryOwnerAttribute,
		|DocumentTransfers_,
		|SalesOrder,
		|InsufficientProductBalances");
	
	DefaultInventoryViewStructure = New Structure("
		|FinancialAccountingGroup,
		|GoodsOwner,
		|Counterparty,
		|Terms,
		|Contract,
		|Currency,
		|VATTaxation,
		|TaxationOfOrganization,
		|InventoryType,
		|SubjectToExcise,
		|BusinessUnitProduction,
		|PriceKind");
	
	LeftoverSearchKey =
		"Priority,
		|InventoryOwnerAttribute,
		|ItemsLocationAttributes,
		|RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage,
		|RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction,
		|CCDNumber,
		|ShipmentCompany,
		|OrganizationOfBalance,
		|DateOfReceipt,
		|DocumentTransfers_,
		|ItemsLocationAttributesShipment,
		|InventoryOwnerAttributeShipment,
		|CorInventoryOwnerAttribute";
	
	Query = RequestDistributionBasedOnPrioritiesOfGoodsTableToBalanceTable(TempTablesManager,
																					AdditionalProperties,
																					ParametersForFillingInventoryTypes);
	
	If ValueIsFilled(ParametersForFillingInventoryTypes.CompanyFieldName1) Then
		Organization = DocumentObject[ParametersForFillingInventoryTypes.CompanyFieldName1];
	ElsIf TypeOf(ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization) = Type("Array") Then
		If ValueIsFilled(ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization) Then
			Organization = ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization[0];
		Else
			Organization = Catalogs.Companies.EmptyRef();
		EndIf;
	Else
		Organization = ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization;
	EndIf;
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	
	If ValueIsFilled(ParametersForFillingInventoryTypes.ExciseAccrualPeriod) Then
		Date = ParametersForFillingInventoryTypes.ExciseAccrualPeriod;
	Else
		Date = DocumentObject.Date;
	EndIf;
	
	Query.SetParameter("Date",	Date);
	Query.SetParameter("Country",	RegistrationCountry);
	Query.SetParameter("UseExcisableGoods",
								GetFunctionalOption("UseExcisableGoods"));
	
	ResultsArray = Query.ExecuteBatchWithIntermediateData();
	
	// In TM and AR, some of the requests are cut out, so we adjust the package numbers.
	IndexIsNotTMAR = 1;
	IndexIsNotTMAR = 0;
	IndexIsNotTMAR = IndexIsNotTMAR - ?(ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods, 2, 0);
	
	FetchingDocumentData	= ResultsArray[3 - IndexIsNotTMAR].Select();
	SelectionTableOfProducts	= ResultsArray[4 - IndexIsNotTMAR].Select();
	BalanceTable			= ResultsArray[6 - IndexIsNotTMAR].Unload(); // ValueTable -
	SelectingDataByLine	= ResultsArray[7 - IndexIsNotTMAR].Select(QueryResultIteration.ByGroups);
	
	Query.Text = "DROP TTBalance";
	Query.Execute();
	
	FetchingDocumentData.Next();
	FillPropertyValues(DefaultInventoryViewStructure, FetchingDocumentData);
	
	Organization             = FetchingDocumentData.Organization;
	BusinessOperation   = FetchingDocumentData.BusinessOperation;
	TransferForActivity_ = FetchingDocumentData.VATTaxation;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods Then
			
		ExceptionText = NStr("vi = 'Hàm %Function% không được dùng để gọi ra với giao dịch kinh tế %BusinessOperation%';
							|ru = 'Функция %Function% не предназначена для вызова с хозяйственной операцией %BusinessOperation%';
							|en = 'The %Function% function cannot be called with business transaction %BusinessOperation%'; fa = 'The %Function% function cannot be called with business transaction %BusinessOperation%';
							|it = 'La funzione %Function% non è assegnata alla definizione della transazione commerciale %BusinessOperation%';
							|pl = 'Funkcja %Function% nie jest przeznaczona do wywołania z operacją gospodarczą %BusinessOperation%';
							|tr = '%Function% işlevi, %BusinessOperation% ticari işlemiyle çağrılmak üzere tasarlanmamıştır'");
		ExceptionText = StrReplace(ExceptionText, "%Function%", "FillInTypesOfReservesAccordingToTableOfBalancesFormTTNewReserves");
		ExceptionText = StrReplace(ExceptionText, "%BusinessOperation%", BusinessOperation);
		Raise ExceptionText;
		
	EndIf;
	
	BalanceTable.Columns.Add("OrganizationOfBalance", New TypeDescription("CatalogRef.Companies"));
	BalanceTable.LoadColumn(BalanceTable.UnloadColumn("OrganizationOfInventoryType"), "OrganizationOfBalance");
	BalanceTable.Columns.Delete("OrganizationOfInventoryType");
	BalanceTable.Indexes.Add(LeftoverSearchKey);
	
	DefaultStockTypes = New Map;
	
	PostWithoutControlOfCompanyStockBalance = SessionParameters.PostWithoutControlOfCompanyStockBalance
														Or Not Constants.ControlCompanyStockBalance.Get();
	
	AllowRetroactiveReleaseRegistration = UserRightsCached.AllowRetroactiveReleaseRegistration();
	
	SubjectToExcise = ParametersForFillingInventoryTypes.SelectionOfStockTypes_.SubjectToExcise;
	OnlyNonExciseItems = ValueIsFilled(SubjectToExcise);
	
	ParametersForFillingInInventoryOwnerAttributesManually = ?(AdditionalProperties.Property("ParametersForFillingInInventoryOwnerAttributesManually"),
												AdditionalProperties.ParametersForFillingInInventoryOwnerAttributesManually,
												ParametersForFillingInInventoryOwnerAttributesManually());
	
	While SelectingDataByLine.Next() Do
		MaterialProviderCompany			= SelectingDataByLine.MaterialProviderCompany;
		ProductQuantity_			= SelectingDataByLine.Count;
		QuantityOfGoodsAccordingToRNPT		= SelectingDataByLine.QuantityByGBRN;
		ProductAmountWithVAT				= SelectingDataByLine.AmountIncludingVAT;
		ProductVATAmount				= SelectingDataByLine.VATAmount;
		TotalRemunerationAmount	= SelectingDataByLine.CommissionAmount;
		AmountOfVATRemunerationTotal	= SelectingDataByLine.AmountVATRemuneration;
		
		ThereIsQuantityOfRNPT = QuantityOfGoodsAccordingToRNPT <> 0;
		
		// Detail record
		Selection = SelectingDataByLine.Select();
		
		While Selection.Next() Do
			
			ExportSaleOfCommissionGoods = False;
			
			FillInStructureByProductLine(DefaultInventoryViewStructure, Selection, FetchingDocumentData);
			
			If ValueIsFilled(Selection.InventoryOwnerAttribute) Then
				
				PickUpVTCHGoodsAcceptedForResponsibleStorage =
					PickUpVTCHGoodsAcceptedForResponsibleStorage(
						ParametersForFillingInventoryTypes,
						Selection);
				
				If (Selection.OrganizationOfBalance = Organization
						Or Selection.OrganizationOfBalance = MaterialProviderCompany
						Or False)
					And (PickUpVTCHGoodsAcceptedForResponsibleStorage = Undefined
						Or (Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) = Upper("ByAgreementSettings")
									And Selection.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage =
										Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterWriteOff)
							Or Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) = Upper("AccordingToSettingsOfProductionContract")
								And Selection.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction =
									Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterWriteOff
							Or Upper(PickUpVTCHGoodsAcceptedForResponsibleStorage) = Upper("Always")) Then
					
					InventoryOwnerAttribute = Selection.InventoryOwnerAttribute;
					
				ElsIf Selection.TransferSetting = Enums.GoodsTransferMethods.TransferToCommissionAgent
					And TransferForActivity_ <> Enums.VATTaxationTypes.ExportSale
					And TransferForActivity_ <> Enums.VATTaxationTypes.ExportOfNonResourceGoods
					And TransferForActivity_ <> Enums.VATTaxationTypes.ExportOfCommoditiesServicesWorks Then
					
					// A commission item must be generated,
					// the balances of which will later be closed by the transfer document for the commission.
					If Selection.NewKindOfInventoryIsSubCommission Then
						// The original taxation under which the item was accepted for commission remains.
						TaxationOfCommissionTypeOfStocks = Selection.NewTypeOfInventoryTaxationOfPrincipal;
					Else	
						// taxation is determined by the committee organization.
						AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(
														Selection.NewTypeOfInventoryProductOwner,
														DocumentObject.Date);
						
						TaxationOfCommissionTypeOfStocks =
							?(Enums.VATTaxationTypes.TypesWithVAT().Find(AccountingParametersForOrganization.BasicTaxationVATSales) <> Undefined,
								Enums.VATTaxationTypes.SaleIsSubjectToVAT,
								Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
					EndIf;
					
					DefaultInventoryViewStructure.VATTaxation = TaxationOfCommissionTypeOfStocks;
					
					InventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(
									Organization,
									Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany,
									DefaultInventoryViewStructure);
					
				ElsIf Selection.TransferSetting = Enums.GoodsTransferMethods.Sale Then
					
					InventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(
									Organization,
									Enums.BusinessTransactions.GoodsSaleToAnotherCompany,
									DefaultInventoryViewStructure);
					
				ElsIf Selection.OrganizationOfBalance = Organization
					And ValueIsFilled(Selection.GoodsOwner) Then
					
					InventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(
									Organization,
									Enums.BusinessTransactions.GoodsSaleToAnotherCompany,
									DefaultInventoryViewStructure);
				ElsIf Selection.OrganizationOfBalance = MaterialProviderCompany
					And ValueIsFilled(Selection.GoodsOwner) Then
					
					InventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(
									MaterialProviderCompany,
									Enums.BusinessTransactions.GoodsSaleToAnotherCompany,
									DefaultInventoryViewStructure);
				Else // with the intercampany settings - transfer to the commission, you can not sell for export.
					InventoryOwnerAttribute = Catalogs.InventoryKinds.EmptyRef();
					ExportSaleOfCommissionGoods = True;
				EndIf;
				
			Else
				InventoryOwnerAttribute = Catalogs.InventoryKinds.EmptyRef();
			EndIf;
			
			CountBalance				= Selection.CountBalance;
			QuantityBalanceTotal			= Selection.QuantityBalanceTotal;
			QuantityByRNPTBalanceTotal	= Selection.QuantityByRNPTBalanceTotal;
			SumBalance					= Selection.SumBalance;
			ExciseTaxAmountBalance				= Selection.ExciseTaxAmountBalance;
			NotCCDNumberIsSpecified				= False;
			TracedGoods				= False;
			
			FilterLeftovers = New Structure(LeftoverSearchKey);
			FillPropertyValues(FilterLeftovers, Selection);
			
			For Each KeyAndValue In FilterLeftovers Do
				If Not ValueIsFilled(KeyAndValue.Value) Then
					FilterLeftovers[KeyAndValue.Key] = BalanceTable.Columns[KeyAndValue.Key].ValueType.AdjustValue();
				EndIf;
			EndDo;
			
			RemainderLines_			= BalanceTable.FindRows(FilterLeftovers);
			CurrentBalanceLine	= Undefined;
			
			If RemainderLines_.Count() > 0 Then
				
				MinimumRemainderFound = False;
				
				For Each RemainderLine_ In RemainderLines_ Do
					If (CountBalance > 0
							And RemainderLine_.CountBalance > 0)
						Or (CountBalance < 0
							And RemainderLine_.CountBalance < 0) Then
						
						If CountBalance > 0 Then
							CountBalance = Min(RemainderLine_.CountBalance, CountBalance);
						Else
							CountBalance = Max(RemainderLine_.CountBalance, CountBalance);
						EndIf;
						
						MinimumRemainderFound	= True;
						CurrentBalanceLine		= RemainderLine_;
						
						Break;
						
					EndIf;
				EndDo;
				
				If Not MinimumRemainderFound Then
					CountBalance = 0;
				EndIf;
				
			EndIf;
			
			If (ValueIsFilled(InventoryOwnerAttribute)
					And Selection.InventoryOwnerAttribute <> InventoryOwnerAttribute
					And DefaultInventoryViewStructure.InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell)
				// There can be no arrival of a reserve for the inventory of the right sale
				Or Selection.NotCCDNumberIsSpecified
				Or ExportSaleOfCommissionGoods Then
				
				CountBalance				= 0;
				QuantityBalanceTotal			= 0;
				QuantityByRNPTBalanceTotal	= 0;
				SumBalance					= 0;
				ExciseTaxAmountBalance				= 0;
				NotCCDNumberIsSpecified				= Selection.NotCCDNumberIsSpecified;
				TracedGoods				= Selection.TracedGoods;
				
			ElsIf (ProductQuantity_ > 0
					And CountBalance > 0)
				Or (ProductQuantity_ < 0
					And CountBalance < 0) Then
				
				NewRow = TableTypesOfStocks_.Add();
				FillPropertyValues(NewRow, Selection);
				
				If ValueIsFilled(InventoryOwnerAttribute) Then
					NewRow.InventoryOwnerAttribute = InventoryOwnerAttribute;
				Else
					ExceptionText = NStr("vi = 'Số lượng khác 0 khi hàng tồn kho trống.';
										|ru = 'Ненулевое количество при пустом виде запасов.';
										|en = 'Non-zero quantity with empty inventory owner attributes.'; fa = 'Non-zero quantity with empty inventory owner attributes.';
										|it = 'Quantità diversa da zero in un tipo vuoto di scorta.';
										|pl = 'Niezerowa ilość przy pustym rodzaju zapasów.';
										|tr = 'Stok türü boşsa sıfır olmayan bir miktar.'");
					
					Raise ExceptionText;
				EndIf;
				
				If ProductQuantity_ > 0 Then
					
					Count = Min(ProductQuantity_, CountBalance);
					
					If SumBalance <> 0 Then
						SumBalance	= Max(SumBalance, 0);
						AmountIncludingVAT		= ?(CountBalance = Count,
											SumBalance,
											Min(ProductAmountWithVAT, SumBalance));
					Else
						AmountIncludingVAT = ?(ProductQuantity_ <> 0,
										Round(Count * ProductAmountWithVAT / ProductQuantity_, 2, 1),
										0);
					EndIf;
					
				Else
					
					Count = Max(ProductQuantity_, CountBalance);
					
					If SumBalance <> 0 Then
						SumBalance = Min(SumBalance, 0);
						AmountIncludingVAT = ?(CountBalance = Count,
										SumBalance,
										Max(ProductAmountWithVAT, SumBalance));
					Else
						AmountIncludingVAT = ?(ProductQuantity_ <> 0,
										Round(Count * ProductAmountWithVAT / ProductQuantity_, 2, 1),
										0);
					EndIf;
					
				EndIf;
				
				FillPropertyValues(StringDataStructure, Selection);
				
				StringDataStructure.Count				= Count;
				StringDataStructure.QuantityByGBRN			= ?(QuantityBalanceTotal <> 0,
																	?(QuantityBalanceTotal - Count = 0,
																		QuantityByRNPTBalanceTotal,
																		Count * QuantityByRNPTBalanceTotal / QuantityBalanceTotal),
																	0);
				StringDataStructure.AmountIncludingVAT					= AmountIncludingVAT;
				StringDataStructure.VATAmount					= ?(ProductAmountWithVAT <> 0,
																	Round(AmountIncludingVAT * ProductVATAmount / ProductAmountWithVAT, 2, 1),
																	0);
				StringDataStructure.CommissionAmount		= ?(ProductQuantity_ <> 0,
																	Round(Count * TotalRemunerationAmount / ProductQuantity_, 2, 1),
																	0);
				StringDataStructure.AmountVATRemuneration	= ?(ProductQuantity_ <> 0,
																	Round(Count * AmountOfVATRemunerationTotal / ProductQuantity_, 2, 1),
																	0);
				StringDataStructure.ExciseTaxAmount				= ?(CountBalance <> 0,
																	?(CountBalance - Count = 0,
																		ExciseTaxAmountBalance,
																		Round(Count * ExciseTaxAmountBalance
																		/ CountBalance, 2, 1)),
																	0);
				StringDataStructure.InsufficientProductBalances = False;
				
				FillPropertyValues(NewRow, StringDataStructure);
				
				// For goods redeemed by intercampany, movements on Reserves are formed.
				If Selection.InventoryOwnerAttribute <> InventoryOwnerAttribute Then
					
					MovementOfSellerSReserve = TableNewReserves.Add();
					FillPropertyValues(MovementOfSellerSReserve, NewRow);
					
					MovementOfSellerSReserve.RecordType		= AccumulationRecordType.Receipt;
					MovementOfSellerSReserve.Period			= EndOfMonth(FetchingDocumentData.Period);
					If Selection.OrganizationOfBalance = MaterialProviderCompany Then
						MovementOfSellerSReserve.Organization		= MaterialProviderCompany;
					Else
						MovementOfSellerSReserve.Organization		= Organization;
					EndIf;
					MovementOfSellerSReserve.CorCompany	= Selection.OrganizationOfBalance;
					MovementOfSellerSReserve.CorInventoryOwnerAttribute	= Selection.InventoryOwnerAttribute;
					
					AccumulationRegisters.CompanySafeStock.AddCorRecordToReserveSet(TableNewReserves,
																								MovementOfSellerSReserve);
					
				EndIf;
				
				ProductQuantity_			= ProductQuantity_				- StringDataStructure.Count;
				If ThereIsQuantityOfRNPT Then
					QuantityOfGoodsAccordingToRNPT = QuantityOfGoodsAccordingToRNPT - StringDataStructure.QuantityByGBRN;
				EndIf;
				ProductAmountWithVAT				= ProductAmountWithVAT				- StringDataStructure.AmountIncludingVAT;
				ProductVATAmount				= ProductVATAmount				- StringDataStructure.VATAmount;
				TotalRemunerationAmount	= TotalRemunerationAmount		- StringDataStructure.CommissionAmount;
				AmountOfVATRemunerationTotal	= AmountOfVATRemunerationTotal	- StringDataStructure.AmountVATRemuneration;
				
				If CurrentBalanceLine <> Undefined Then
					CurrentBalanceLine.CountBalance = CurrentBalanceLine.CountBalance - StringDataStructure.Count;
				EndIf;
				
			EndIf;
			
		EndDo; // Sampling by residuals
		
		If ProductQuantity_ <> 0
			Or ProductAmountWithVAT <> 0 Then
			
			ControlExcisableItems = SelectingDataByLine.ExcisableGoods
												And Not OnlyNonExciseItems
												And Not InventoryOwnerAttributeIsInitializedByDefault
												And Not ParametersForFillingInventoryTypes.FillExcisableItemsWithDefaultInventoryOwnerAttributes;
			
			If (WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault
						And Not ControlExcisableItems)
					Or ((Not SelectingDataByLine.ExcisableGoods
							Or OnlyNonExciseItems
							Or ParametersForFillingInventoryTypes.FillExcisableItemsWithDefaultInventoryOwnerAttributes)
						And PostWithoutControlOfCompanyStockBalance
						And Not IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited)
					// If the user has the appropriate role, then the consumption of work is not controlled
					Or (AllowRetroactiveReleaseRegistration
						And SelectingDataByLine.ItemsType = Enums.ItemsTypes.Work_5) Then
				
				If Not ParametersForFillingInventoryTypes.ProductOwnerInHeader
					And ParametersForFillingInventoryTypes.TableOfDetailsOfStockTypesByDefault.Count() = 0 Then
					
					ExceptionText = NStr("vi = 'Đã đặt dấu hộp kiểm nhận hàng từ chủ sở hữu từ bảng
												|mục tin dạng vật tư theo mặc định, nhưng chưa chuyển bảng.';
												|ru = 'Установлен флаг получения владельца товаров из таблицы
												|реквизитов видов запасов по умолчанию, но таблица не передана.';
												|en = 'Check box of receiving goods owner from the inventory owner attribute table
												|is selected by default, but the table is not transferred.'; fa = 'Check box of receiving goods owner from the inventory owner attribute table
												|is selected by default, but the table is not transferred.';
												|it = 'Impostato flag di ricezione del proprietario della merce dalla tabella
												| dei requisiti dei tipi di scorta per impostazione predefinita, ma la tabella non è impostata.';
												|pl = 'Zostało ustanowione zaznaczenie otrzymania właściciela towarów z tabeli
												|atrybutów rodzajów zapasów domyślnych, ale tabela nie była przekazana.';
												|tr = 'Stok türlerinin tablosu
												|özniteliklerinden ürün sahibini alma bayrağı varsayılan olarak ayarlanmıştır, ancak tablo transfer edilmedi.'");
					
					Raise ExceptionText;
					
				EndIf;
				
				SelectionTableOfProducts.Reset();
				DefaultStockTypes.Clear();
				
				RowFilter = New Structure("LineNumber", SelectingDataByLine.LineNumber);
				
				If SelectionTableOfProducts.FindNext(RowFilter) Then
					
					If ParametersForFillingInventoryTypes.ProductOwnerInHeader Then
						DefaultInventoryViewStructure.InventoryType	= ?(SelectionTableOfProducts.InventoryType = Enums.InventoryTypes.Work_5,
																		SelectionTableOfProducts.InventoryType,
																		DefaultInventoryViewStructure.InventoryType);
					Else
						DefaultInventoryViewStructure.InventoryType		= SelectionTableOfProducts.InventoryType;
						DefaultInventoryViewStructure.GoodsOwner	= SelectionTableOfProducts.GoodsOwner;
						DefaultInventoryViewStructure.Counterparty		= SelectionTableOfProducts.Counterparty;
						DefaultInventoryViewStructure.Contract			= SelectionTableOfProducts.Contract;
					EndIf;
					
					DefaultInventoryViewStructure.PriceKind					= SelectionTableOfProducts.PriceKind;
					DefaultInventoryViewStructure.FinancialAccountingGroup	= SelectionTableOfProducts.FinancialAccountingGroup;
					DefaultInventoryViewStructure.SubjectToExcise			= SelectionTableOfProducts.SubjectToExcise;
					DefaultInventoryViewStructure.BusinessUnitProduction	= FetchingDocumentData.BusinessUnitProduction;
					KeyOfInventoryOwnerAttribute = KeyOfInventoryOwnerAttributeSelectionCache(ParametersForFillingInventoryTypes.ProductOwnerInHeader,
																DefaultInventoryViewStructure);
					DefaultStockView = DefaultStockTypes[KeyOfInventoryOwnerAttribute];
					
					If DefaultStockView = Undefined Then
						DefaultStockView = Catalogs.InventoryKinds.DocumentInventoryView(
													Organization,
													BusinessOperation,
													DefaultInventoryViewStructure);
						
						DefaultStockTypes.Insert(KeyOfInventoryOwnerAttribute, DefaultStockView);
					EndIf;
					
					NewRow = TableTypesOfStocks_.Add();
					FillPropertyValues(NewRow, SelectionTableOfProducts);
					NewRow.InventoryOwnerAttribute = DefaultStockView;
					
					FillPropertyValues(StringDataStructure, SelectionTableOfProducts);
					
					StringDataStructure.Count				= ProductQuantity_;
					StringDataStructure.QuantityByGBRN			= QuantityOfGoodsAccordingToRNPT;
					StringDataStructure.AmountIncludingVAT					= ProductAmountWithVAT;
					StringDataStructure.VATAmount					= ProductVATAmount;
					StringDataStructure.CommissionAmount		= 0;
					StringDataStructure.AmountVATRemuneration	= 0;
					StringDataStructure.SalesOrder				= Undefined;
					StringDataStructure.DocumentTransfers_			= Undefined;
					StringDataStructure.InsufficientProductBalances = True;
					
					FillPropertyValues(NewRow, StringDataStructure);
					
				EndIf;
				
			EndIf;
			
			If (Not WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault
					Or ControlExcisableItems)
				And Not ParametersForFillingInInventoryOwnerAttributesManually.IgnoreResidueControlErrors Then
				
				If ParametersForFillingInventoryTypes.ReportFillingErrors Then
					Selection = SelectingDataByLine.Select();
					Selection.Next();
					
					NewLineOfErrors = ErrorsTable.Add();
					FillPropertyValues(NewLineOfErrors, SelectionTableOfProducts);
					
					NewLineOfErrors.Count			= ProductQuantity_;
					NewLineOfErrors.ItemsType		= Selection.ItemsType;
					NewLineOfErrors.UnitOfMeasure		= Selection.UnitOfMeasure;
					NewLineOfErrors.NotCCDNumberIsSpecified		= NotCCDNumberIsSpecified;
					NewLineOfErrors.TracedGoods	= TracedGoods;
					NewLineOfErrors.Products			= Selection.Products;
					NewLineOfErrors.Characteristic		= Selection.Characteristic;
					NewLineOfErrors.Series					= Selection.Series;
					NewLineOfErrors.Warehouse					= Selection.Warehouse;
					NewLineOfErrors.Purpose			= Selection.Purpose;
				EndIf;
				
				If ((SelectingDataByLine.ExcisableGoods
							And Not OnlyNonExciseItems
							And Not ParametersForFillingInventoryTypes.FillExcisableItemsWithDefaultInventoryOwnerAttributes)
						Or Not PostWithoutControlOfCompanyStockBalance
						Or IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited)
					// If the user has the appropriate role, then the consumption of work is not controlled
					And (Not AllowRetroactiveReleaseRegistration
						Or Not SelectingDataByLine.ItemsType = Enums.ItemsTypes.Work_5) Then
					
					Cancel = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo; // Sampling by document lines
	
	If ErrorsTable.Count() > 0
		And PostWithoutControlOfCompanyStockBalance Then
		
		MessageText = NStr( "vi = 'Đã kết chuyển chứng từ %Ref% có ngắt sử dụng kiểm soát số dư hàng hóa trong doanh nghiệp.';
							|ru = 'Документ %Ref% проведен с выключенным контролем остатков товаров организаций.';
							|en = 'The %Ref% document is posted with enabled company stock balance control.'; fa = 'The %Ref% document is posted with enabled company stock balance control.';
							|it = 'Documento %Ref% eseguito con il controllo dei beni residui delle aziende disattivato.';
							|pl = 'Dokument %Ref% jest zaksięgowany z wyłączoną kontrolą pozostałości towarów firm.';
							|tr = '%Ref% belgesi, iş yerinin stok kontrolü kapalıyken kaydedildi.'", Metadata.DefaultLanguage.LanguageCode);
		MessageText = StrReplace(MessageText, "%Ref%", DocumentObject.Ref);
		
		WriteLogEvent(EventNameResidueControlDisabled(),
									EventLogLevel.Warning,
									,
									DocumentObject.Ref,
									MessageText);
		
	EndIf;
	
	If ParametersForFillingInventoryTypes.TableTypesOfStocks_ = Undefined
		And Not Cancel Then
		
		DocumentObject[ParametersForFillingInventoryTypes.NameTSTypesOfStocks].Load(TableTypesOfStocks_);
		
	EndIf;
	
	If ControlChangeOfCCDNumbers Then
		
		TableOfCCDNumbers.Columns.Add("NewCount");
		
		For Each TableRow In TableTypesOfStocks_ Do
			
			NewRow = TableOfCCDNumbers.Add();
			FillPropertyValues(NewRow, TableRow);
			NewRow.Count = 0;
			NewRow.NewCount = TableRow.Count;
			
		EndDo;
		
		TableOfCCDNumbers.GroupBy("ItemsLocationAttributes, CCDNumber", "Count, NewCount");
		
		For Each TableRow In TableOfCCDNumbers Do
			If TableRow.Count <> TableRow.NewCount Then
				AdditionalProperties.Insert("CCDNumbersHaveChanged", True);
			EndIf;
		EndDo;
		
	EndIf;
	
	ReportProductControlErrorsInOrganizations(DocumentObject, ErrorsTable, ParametersForFillingInventoryTypes);
	
	If ParametersForFillingInventoryTypes.TableNewReserves <> Undefined Then
		// The condition is met only at the production stage. In this document, the distribution of reserves by periods when filling
		// in the types of reserves is not done - it occurs when reserves are formed in the processing of the event.
		ParametersForFillingInventoryTypes.Insert("TableNewReserves", TableNewReserves);
	Else
		
		TableNewReserves = DistributeReservesOfGoodsOfOrganizationsByPeriods(
								ParametersForFillingInventoryTypes.NumberOfPeriodsWhenFormingReservesOfOrganizations,
								TableNewReserves,
								TempTablesManager);
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text =
		"SELECT
		|	NewReserves.RecordType,
		|	NewReserves.Period,
		|	NewReserves.ItemsLocationAttributes,
		|	NewReserves.Organization,
		|	NewReserves.InventoryOwnerAttribute,
		|	NewReserves.CCDNumber,
		|	NewReserves.Count,
		|	CAST(NewReserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
		|	NewReserves.CorCompany,
		|	NewReserves.CorInventoryOwnerAttribute
		|INTO TTNewReserves
		|FROM
		|	&TableNewReserves AS NewReserves";
		
		Query.SetParameter("TableNewReserves", TableNewReserves);
		
		Query.Execute();
		
	EndIf;
	
EndProcedure

Function QueryingAllocationOfReservesByBalanceTable(TempTablesManager, ParametersForFillingInventoryTypes)
	
	ReserveAllocationRequest = New Query;
	ReserveAllocationRequest.TempTablesManager = TempTablesManager;
	ReserveAllocationRequest.Text =
	"SELECT
	|	&Period AS Period,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.Organization AS Organization,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.CCDNumber AS CCDNumber,
	|	0 - Balance.CountBalance AS Count,
	|	CASE
	|		WHEN Balance.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|					AND VALUETYPE(Balance.InventoryOwnerAttribute.GoodsOwner) = VALUE(Catalog.Partners)
	|				OR Balance.InventoryOwnerAttribute.InventoryType IN(
	|						VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|						VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|						VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|						VALUE(Enum.InventoryTypes.Work_5),
	|						VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS CoveredByReserve,
	|	Balance.ItemsLocationAttributes.Products AS Products,
	|	Balance.ItemsLocationAttributes.Products.ItemsType AS ItemsType,
	|	Balance.ItemsLocationAttributes.Products.UnitOfMeasure AS UnitOfMeasure,
	|	Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	Balance.ItemsLocationAttributes.Series AS Series,
	|	Balance.ItemsLocationAttributes.Purpose AS Purpose,
	|	Balance.ItemsLocationAttributes.StorageLocation AS Warehouse
	|FROM
	|	BalanceTable AS Balance
	|WHERE
	|	Balance.CountBalance < 0
	|	AND Balance.Organization = &Organization
	|	AND NOT Balance.InventoryOwnerAttribute.InventoryType IN(&UncontrolledInventoryTypes)
	|	AND (Balance.ItemsLocationAttributes, Balance.Organization, Balance.InventoryOwnerAttribute) IN
	|			(SELECT
	|				TTProductsAndChanges.ItemsLocationAttributes AS ItemsLocationAttributes,
	|				TTProductsAndChanges.Organization AS Organization,
	|				TTProductsAndChanges.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|			FROM
	|				TTProductsAndChanges AS TTProductsAndChanges
	|			WHERE
	|				TTProductsAndChanges.ForResidueControl)
	|	AND ((Balance.ItemsLocationAttributes, Balance.Organization, Balance.InventoryOwnerAttribute, Balance.CCDNumber) IN
	|			(SELECT
	|				TTProductsAndChanges.ItemsLocationAttributes AS ItemsLocationAttributes,
	|				TTProductsAndChanges.Organization AS Organization,
	|				TTProductsAndChanges.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|				TTProductsAndChanges.CCDNumber AS CCDNumber
	|			FROM
	|				TTProductsAndChanges AS TTProductsAndChanges
	|			WHERE
	|				TTProductsAndChanges.ForResidueControl)
	|			OR &WithoutSelectionByCCDNumbers)
	|	AND
	|		(
	|			(
	|			NOT ISNULL(Balance.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			OR (ISNULL(Balance.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|				AND Balance.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef))
	|			OR NOT &UseTraceableImportedGoodsAccounting
	|			OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			)
	|			AND (
	|				NOT &UseSeparateProcurement
	|				OR (&UseSeparateProcurement
	|					AND (NOT (ISNULL(Balance.ItemsLocationAttributes.Products.KeepRecordsByCCD, FALSE)
	|						AND Balance.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)))
	|					)
	|			)
	|		)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Period AS Period,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.Organization AS Organization,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.CCDNumber AS CCDNumber,
	|	SUM(Balance.Count) AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE SUM(Balance.QuantityByGBRN)
	|	END AS QuantityByGBRN,
	|	Balance.Products AS Products,
	|	Balance.UnitOfMeasure AS UnitOfMeasure,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.Series AS Series,
	|	Balance.Purpose AS Purpose,
	|	Balance.Warehouse AS Warehouse,
	|	ISNULL(DatesOfCompanyGoodsReceipt.DateOfReceipt, DATETIME(1, 1, 1)) AS DateOfReceipt
	|FROM
	|	(SELECT
	|		Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Balance.Organization AS Organization,
	|		Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Balance.CCDNumber AS CCDNumber,
	|		Balance.CountBalance AS Count,
	|		CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11)) AS QuantityByGBRN,
	|		Balance.ItemsLocationAttributes.Products AS Products,
	|		Balance.ItemsLocationAttributes.Products.UnitOfMeasure AS UnitOfMeasure,
	|		Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		Balance.ItemsLocationAttributes.Series AS Series,
	|		Balance.ItemsLocationAttributes.Purpose AS Purpose,
	|		Balance.ItemsLocationAttributes.StorageLocation AS Warehouse
	|	FROM
	|		BalanceTable AS Balance
	|	WHERE
	|		Balance.CountBalance > 0
	|		AND Balance.Organization <> &Organization
	|		AND NOT Balance.InventoryOwnerAttribute.InventoryType IN(VALUE(Enum.InventoryTypes.Work_5),
	|											VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Balance.ItemsLocationAttributes,
	|		Balance.Organization,
	|		Balance.InventoryOwnerAttribute,
	|		Balance.CCDNumber,
	|		Balance.CountBalance,
	|		CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11)),
	|		Balance.ItemsLocationAttributes.Products,
	|		Balance.ItemsLocationAttributes.Products.UnitOfMeasure,
	|		Balance.ItemsLocationAttributes.Characteristic,
	|		Balance.ItemsLocationAttributes.Series,
	|		Balance.ItemsLocationAttributes.Purpose,
	|		Balance.ItemsLocationAttributes.StorageLocation
	|	FROM
	|		BalanceTable AS Balance
	|			INNER JOIN InformationRegister.CustomizeCustomerInvoiceIntercompany AS Settings
	|			ON (Settings.CompanyOwner = Balance.Organization)
	|				AND (Settings.CompanyCustomer = &Organization)
	|				AND (Settings.InventoryType = Balance.InventoryOwnerAttribute.InventoryType)
	|				AND (Settings.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale)
	|					OR Settings.Currency = Balance.InventoryOwnerAttribute.Currency
	|						AND Settings.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent))
	|	WHERE
	|		Balance.CountBalance > 0
	|		AND Balance.Organization <> &Organization
	|		AND Balance.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReverseArrivalOfReserve.ItemsLocationAttributes,
	|		ReverseArrivalOfReserve.CorCompany,
	|		ReverseArrivalOfReserve.CorInventoryOwnerAttribute,
	|		ReverseArrivalOfReserve.CCDNumber,
	|		-ReverseArrivalOfReserve.Count,
	|		-CAST(ReverseArrivalOfReserve.QuantityByGBRN AS NUMBER(23, 11)),
	|		ReverseArrivalOfReserve.ItemsLocationAttributes.Products,
	|		ReverseArrivalOfReserve.ItemsLocationAttributes.Products.UnitOfMeasure,
	|		ReverseArrivalOfReserve.ItemsLocationAttributes.Characteristic,
	|		ReverseArrivalOfReserve.ItemsLocationAttributes.Series,
	|		ReverseArrivalOfReserve.ItemsLocationAttributes.Purpose,
	|		ReverseArrivalOfReserve.ItemsLocationAttributes.StorageLocation
	|	FROM
	|		TTStornoReserves AS ReverseArrivalOfReserve
	|	WHERE
	|		ReverseArrivalOfReserve.Count < 0
	|		AND ReverseArrivalOfReserve.Organization = &Organization
	|		AND ReverseArrivalOfReserve.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Balance.ItemsLocationAttributes,
	|		Balance.Organization,
	|		Balance.InventoryOwnerAttribute,
	|		Balance.CCDNumber,
	|		Balance.CountBalance,
	|		CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11)),
	|		Balance.ItemsLocationAttributes.Products,
	|		Balance.ItemsLocationAttributes.Products.UnitOfMeasure,
	|		Balance.ItemsLocationAttributes.Characteristic,
	|		Balance.ItemsLocationAttributes.Series,
	|		Balance.ItemsLocationAttributes.Purpose,
	|		Balance.ItemsLocationAttributes.StorageLocation
	|	FROM
	|		BalanceTable AS Balance
	|	WHERE
	|		Balance.CountBalance > 0
	|		AND Balance.Organization = &Organization
	|		AND Balance.InventoryOwnerAttribute.InventoryType IN(
	|			VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|		
	|		) AS Balance
	|		
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfCompanyGoodsReceipt
	|		ON Balance.InventoryOwnerAttribute = DatesOfCompanyGoodsReceipt.InventoryOwnerAttribute
	|			AND Balance.Products = DatesOfCompanyGoodsReceipt.Products
	|			AND Balance.Characteristic = DatesOfCompanyGoodsReceipt.Characteristic
	|			AND Balance.Series = DatesOfCompanyGoodsReceipt.Series
	|			AND Balance.Purpose = DatesOfCompanyGoodsReceipt.Purpose
	|			AND Balance.CCDNumber = DatesOfCompanyGoodsReceipt.CCDNumber
	|
	|GROUP BY
	|	Balance.Products,
	|	Balance.Series,
	|	Balance.ItemsLocationAttributes,
	|	Balance.UnitOfMeasure,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.Characteristic,
	|	ISNULL(DatesOfCompanyGoodsReceipt.DateOfReceipt, DATETIME(1, 1, 1)),
	|	Balance.Purpose,
	|	Balance.Warehouse,
	|	Balance.Organization,
	|	Balance.CCDNumber
	|
	|ORDER BY
	|	DateOfReceipt
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP BalanceTable";
	
	CheckForTemporaryReserveTables(TempTablesManager, "TTStornoReserves");
	
	ReserveAllocationRequest.SetParameter("UncontrolledInventoryTypes", UncontrolledInventoryTypes());
	ReserveAllocationRequest.SetParameter("WithoutSelectionByCCDNumbers",
													ParametersForFillingInventoryTypes.WithoutSelectionByCCDNumbers);
	ReserveAllocationRequest.SetParameter("UseSeparateProcurement",
		ParametersForFillingInventoryTypes.UseSeparateProcurement);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(
		ReserveAllocationRequest);
	
	Return ReserveAllocationRequest;
	
EndFunction

Procedure AllocateNewReservesToBalanceTable(Val ReserveAllocationRequest,
													Val Organization,
													Val ParametersForFillingInventoryTypes,
													TableNewReservesInitial,
													ErrorsTable)
	
	RemainderSearchColumnsToDistribution = "ItemsLocationAttributes, CCDNumber";
	
	ReserveAllocationRequest.SetParameter("Organization", Organization);
	
	Results				= ReserveAllocationRequest.ExecuteBatch();
	DistributionTable_1	= Results[0].Unload();
	ResiduesToDistribution	= Results[1].Unload(); // ValueTable
	ResiduesToDistribution.Indexes.Add(RemainderSearchColumnsToDistribution);
	
	TheStructureOfTheSearch = New Structure(RemainderSearchColumnsToDistribution);
	
	TableNewReserves		= TableNewReservesInitial.CopyColumns();
	OriginalTableIsEmpty	= TableNewReservesInitial.Count() = 0;
	
	For Each DistributionString In DistributionTable_1 Do
		
		If Not DistributionString.CoveredByReserve Then
			
			ErrorRecording = ErrorsTable.Add();
			FillPropertyValues(ErrorRecording, DistributionString);
			ErrorRecording.NotCCDNumberIsSpecified = False;
			
			Continue;
			
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, DistributionString);
		RemainderLines = ResiduesToDistribution.FindRows(TheStructureOfTheSearch);
		
		For Each RemainderLine In RemainderLines Do
			
			If RemainderLine.Count <= 0 Then
				Continue;
			EndIf;
			
			Count = Min(DistributionString.Count, RemainderLine.Count);
			
			SellerSReserve = TableNewReserves.Add();
			FillPropertyValues(SellerSReserve, DistributionString);
			SellerSReserve.RecordType		= AccumulationRecordType.Receipt;
			SellerSReserve.Count		= Count;
			SellerSReserve.QuantityByGBRN	= ?(RemainderLine.Count - Count = 0,
												RemainderLine.QuantityByGBRN,
												Count * RemainderLine.QuantityByGBRN / RemainderLine.Count);
			SellerSReserve.CorCompany	= RemainderLine.Organization;
			SellerSReserve.CorInventoryOwnerAttribute	= RemainderLine.InventoryOwnerAttribute;
			SellerSReserve.ThisIsReverseTransaction		= False;
			
			RemainderLine.Count		= RemainderLine.Count - Count;
			RemainderLine.QuantityByGBRN	= RemainderLine.QuantityByGBRN - SellerSReserve.QuantityByGBRN;
			DistributionString.Count	= DistributionString.Count - Count;
			
			AccumulationRegisters.CompanySafeStock.AddCorRecordToReserveSet(TableNewReserves,
																						SellerSReserve);
			
		EndDo;
		
		If DistributionString.Count <> 0 Then
			ErrorRecording = ErrorsTable.Add();
			FillPropertyValues(ErrorRecording, DistributionString);
			ErrorRecording.NotCCDNumberIsSpecified = False;
		EndIf;
		
	EndDo;

	TableNewReserves = DistributeReservesOfGoodsOfOrganizationsByPeriods(
							ParametersForFillingInventoryTypes.NumberOfPeriodsWhenFormingReservesOfOrganizations,
							TableNewReserves,
							ReserveAllocationRequest.TempTablesManager);
	
	If OriginalTableIsEmpty Then
		TableNewReservesInitial = TableNewReserves;
	Else
		TMCommonUse.AddRowsToTable(TableNewReservesInitial, TableNewReserves);
	EndIf;
	
EndProcedure

Function ControlVATTaxation(ParametersForFillingInventoryTypes)
	
	VATTaxation = ParametersForFillingInventoryTypes.SelectionOfStockTypes_.VATTaxation;
	
	If Not ValueIsFilled(VATTaxation)
		Or Not GetFunctionalOption("UseVATAccounting") Then
		
		ControlTaxation = False;
	Else
		ControlTaxation = True;
	EndIf;
	
	Return ControlTaxation;
	
EndFunction

Procedure FormTTStornoReserves(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes)
	
	CheckForTemporaryReserveTables(TempTablesManager, "TTReverseReservesOfPreviousPeriods");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT DISTINCT
	|	TTProductsAndChanges.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|FROM
	|	TTProductsAndChanges AS TTProductsAndChanges
	|WHERE
	|	NOT TTProductsAndChanges.ForStornoReserve
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Ref AS Ref
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	(&ForAllTypesOfStocks_
	|			OR InventoryKinds.InventoryType IN (&InventoryType))
	|	AND (&ForAllVATTaxation
	|			OR InventoryKinds.VATTaxation IN (&VATTaxation)
	|			OR InventoryKinds.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef))
	|	AND (&ForAllProductOwners
	|			OR InventoryKinds.GoodsOwner IN (&GoodsOwner))
	|	AND (&ByAllAgreements
	|			OR InventoryKinds.Terms IN (&Terms))
	|	AND (&ForAllCurrencies
	|			OR InventoryKinds.Currency IN (&Currency))
	|	AND (&ForAllCounterparties
	|			OR InventoryKinds.Counterparty IN (&Counterparty))
	|	AND (&ByAllContracts
	|			OR InventoryKinds.Contract IN (&Contract))
	|	AND (&ForAllProductGroups
	|			OR InventoryKinds.ProductsGroup IN (&ProductsGroup))
	|	AND (&ForAllTypesOfPrices
	|			OR InventoryKinds.PriceKind IN (&PriceKind))
	|	AND (&ByAllCompanies
	|			OR InventoryKinds.Organization IN (&Organization))
	|	AND NOT InventoryKinds.SaleOfAnotherCompanyInventory
	|	AND NOT InventoryKinds.IsDuplicate";
	
	SelectionOfStockTypes_ = ParametersForFillingInventoryTypes.SelectionOfStockTypes_;
	
	Query.SetParameter("InventoryType", SelectionOfStockTypes_.InventoryType);
	Query.SetParameter("ForAllTypesOfStocks_", Not ValueIsFilled(SelectionOfStockTypes_.InventoryType));
	
	Query.SetParameter("VATTaxation", SelectionOfStockTypes_.VATTaxation);
	Query.SetParameter("ForAllVATTaxation", Not ValueIsFilled(SelectionOfStockTypes_.VATTaxation));
	
	Query.SetParameter("GoodsOwner", SelectionOfStockTypes_.GoodsOwner);
	Query.SetParameter("ForAllProductOwners", Not ValueIsFilled(SelectionOfStockTypes_.GoodsOwner));
	
	Query.SetParameter("Terms", SelectionOfStockTypes_.Terms);
	Query.SetParameter("ByAllAgreements", Not ValueIsFilled(SelectionOfStockTypes_.Terms));
	
	Query.SetParameter("Currency", SelectionOfStockTypes_.Currency);
	Query.SetParameter("ForAllCurrencies", Not ValueIsFilled(SelectionOfStockTypes_.Currency));
	
	Query.SetParameter("Counterparty", SelectionOfStockTypes_.Counterparty);
	Query.SetParameter("ForAllCounterparties", Not ValueIsFilled(SelectionOfStockTypes_.Counterparty));
	
	Query.SetParameter("Contract", SelectionOfStockTypes_.Contract);
	Query.SetParameter("ByAllContracts", Not ValueIsFilled(SelectionOfStockTypes_.Contract));
	
	Query.SetParameter("ProductsGroup", SelectionOfStockTypes_.ProductsGroup);
	Query.SetParameter("ForAllProductGroups", Not ValueIsFilled(SelectionOfStockTypes_.ProductsGroup));
	
	Query.SetParameter("PriceKind", SelectionOfStockTypes_.PriceKind);
	Query.SetParameter("ForAllTypesOfPrices", Not ValueIsFilled(SelectionOfStockTypes_.PriceKind));
	
	Query.SetParameter("Organization", SelectionOfStockTypes_.Organization);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(SelectionOfStockTypes_.Organization));
	
	Results = Query.ExecuteBatch();
	
	Query.SetParameter("CorTypesOfStocksForStorno", Results[0].Unload().UnloadColumn("InventoryOwnerAttribute"));
	Query.SetParameter("TypesOfStocksOfRecipient", Results[1].Unload().UnloadColumn("Ref"));
	
	Query.Text =
	"SELECT
	|	FormedReserves.Period AS Period,
	|	FormedReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	FormedReserves.Organization AS Organization,
	|	FormedReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	FormedReserves.CCDNumber AS CCDNumber,
	|	FormedReserves.CorCompany AS CorCompany,
	|	FormedReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	FormedReserves.Count AS Count,
	|	CAST(FormedReserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	FormedReserves.RecordType AS RecordType
	|INTO TTFormedReserves
	|FROM
	|	&FormedReserves AS FormedReserves
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTProductsAndChanges.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsAndChanges.Organization AS Organization,
	|	TTProductsAndChanges.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsAndChanges.CCDNumber AS CCDNumber,
	|	TTProductsAndChanges.Period AS Period
	|INTO TTReserveSelectionsForStorno
	|FROM
	|	TTProductsAndChanges AS TTProductsAndChanges
	|WHERE
	|	TTProductsAndChanges.ForStornoReserve
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(NestedQuery.Period, MONTH) AS Period,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	NestedQuery.CorCompany AS CorCompany,
	|	NestedQuery.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.QuantityByGBRN) AS QuantityByGBRN,
	|	CASE
	|		WHEN NestedQuery.CorInventoryOwnerAttribute IN (&CorTypesOfStocksForStorno)
	|			THEN 0
	|		WHEN NestedQuery.CorInventoryOwnerAttribute IN (&TypesOfStocksOfRecipient)
	|			THEN 1
	|		ELSE 2
	|	END AS Priority
	|FROM
	|	(SELECT
	|		CompanySafeStock.Period AS Period,
	|		CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanySafeStock.Organization AS Organization,
	|		CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber AS CCDNumber,
	|		CompanySafeStock.CorCompany AS CorCompany,
	|		CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		CompanySafeStock.Count AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanySafeStock.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
	|		END AS QuantityByGBRN,
	|		ISNULL(DatesOfReceipt.DateOfReceipt, DATETIME(2399, 1, 1)) AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|			ON CompanySafeStock.ItemsLocationAttributes = DimensionKeys.Ref
	|			
	|			LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfReceipt
	|			ON CompanySafeStock.CorInventoryOwnerAttribute = DatesOfReceipt.InventoryOwnerAttribute
	|				AND DimensionKeys.Products = DatesOfReceipt.Products
	|				AND DimensionKeys.Characteristic = DatesOfReceipt.Characteristic
	|				AND DimensionKeys.Series = DatesOfReceipt.Series
	|				AND DimensionKeys.Purpose = DatesOfReceipt.Purpose
	|				AND CompanySafeStock.CCDNumber = DatesOfReceipt.CCDNumber
	|	WHERE
	|		(CompanySafeStock.ItemsLocationAttributes, CompanySafeStock.Organization, CompanySafeStock.InventoryOwnerAttribute, CompanySafeStock.CCDNumber) IN
	|				(SELECT
	|					TTReserveSelectionsForStorno.ItemsLocationAttributes,
	|					TTReserveSelectionsForStorno.Organization,
	|					TTReserveSelectionsForStorno.InventoryOwnerAttribute,
	|					TTReserveSelectionsForStorno.CCDNumber
	|				FROM
	|					TTReserveSelectionsForStorno AS TTReserveSelectionsForStorno)
	|		AND CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		StornoReserves.Period,
	|		StornoReserves.ItemsLocationAttributes,
	|		StornoReserves.Organization,
	|		StornoReserves.InventoryOwnerAttribute,
	|		StornoReserves.CCDNumber,
	|		StornoReserves.CorCompany,
	|		StornoReserves.CorInventoryOwnerAttribute,
	|		StornoReserves.Count,
	|		CAST(StornoReserves.QuantityByGBRN AS NUMBER(23, 11)),
	|		ISNULL(DatesOfReceipt.DateOfReceipt, DATETIME(2399, 1, 1))
	|	FROM
	|		TTReverseReservesOfPreviousPeriods AS StornoReserves
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|			ON StornoReserves.ItemsLocationAttributes = DimensionKeys.Ref
	|			
	|			LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfReceipt
	|			ON StornoReserves.CorInventoryOwnerAttribute = DatesOfReceipt.InventoryOwnerAttribute
	|				AND DimensionKeys.Products = DatesOfReceipt.Products
	|				AND DimensionKeys.Characteristic = DatesOfReceipt.Characteristic
	|				AND DimensionKeys.Series = DatesOfReceipt.Series
	|				AND DimensionKeys.Purpose = DatesOfReceipt.Purpose
	|				AND StornoReserves.CCDNumber = DatesOfReceipt.CCDNumber
	|	WHERE
	|		(StornoReserves.ItemsLocationAttributes, StornoReserves.Organization, StornoReserves.InventoryOwnerAttribute, StornoReserves.CCDNumber) IN
	|				(SELECT
	|					TTReserveSelectionsForStorno.ItemsLocationAttributes,
	|					TTReserveSelectionsForStorno.Organization,
	|					TTReserveSelectionsForStorno.InventoryOwnerAttribute,
	|					TTReserveSelectionsForStorno.CCDNumber
	|				FROM
	|					TTReserveSelectionsForStorno AS TTReserveSelectionsForStorno)
	|		AND StornoReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		FormedReserves.Period,
	|		FormedReserves.ItemsLocationAttributes,
	|		FormedReserves.Organization,
	|		FormedReserves.InventoryOwnerAttribute,
	|		FormedReserves.CCDNumber,
	|		FormedReserves.CorCompany,
	|		FormedReserves.CorInventoryOwnerAttribute,
	|		FormedReserves.Count,
	|		CAST(FormedReserves.QuantityByGBRN AS NUMBER(23, 11)),
	|		ISNULL(DatesOfReceipt.DateOfReceipt, DATETIME(2399, 1, 1))
	|	FROM
	|		TTFormedReserves AS FormedReserves
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|			ON FormedReserves.ItemsLocationAttributes = DimensionKeys.Ref
	|			
	|			LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfReceipt
	|			ON FormedReserves.CorInventoryOwnerAttribute = DatesOfReceipt.InventoryOwnerAttribute
	|				AND DimensionKeys.Products = DatesOfReceipt.Products
	|				AND DimensionKeys.Characteristic = DatesOfReceipt.Characteristic
	|				AND DimensionKeys.Series = DatesOfReceipt.Series
	|				AND DimensionKeys.Purpose = DatesOfReceipt.Purpose
	|				AND FormedReserves.CCDNumber = DatesOfReceipt.CCDNumber
	|	WHERE
	|		(FormedReserves.ItemsLocationAttributes, FormedReserves.Organization, FormedReserves.InventoryOwnerAttribute, FormedReserves.CCDNumber) IN
	|				(SELECT
	|					TTReserveSelectionsForStorno.ItemsLocationAttributes,
	|					TTReserveSelectionsForStorno.Organization,
	|					TTReserveSelectionsForStorno.InventoryOwnerAttribute,
	|					TTReserveSelectionsForStorno.CCDNumber
	|				FROM
	|					TTReserveSelectionsForStorno AS TTReserveSelectionsForStorno)
	|		AND FormedReserves.RecordType = VALUE(AccumulationRecordType.Receipt)) AS NestedQuery
	|
	|GROUP BY
	|	BEGINOFPERIOD(NestedQuery.Period, MONTH),
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.Organization,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.CorCompany,
	|	NestedQuery.CorInventoryOwnerAttribute,
	|	NestedQuery.DateOfReceipt
	|
	|HAVING
	|	SUM(NestedQuery.Count) > 0
	|
	|ORDER BY
	|	Period,
	|	Priority,
	|	NestedQuery.DateOfReceipt
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(TTProductsAndChanges.Period, MONTH) AS Period,
	|	TTProductsAndChanges.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsAndChanges.Organization AS Organization,
	|	TTProductsAndChanges.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsAndChanges.CCDNumber AS CCDNumber,
	|	SUM(TTProductsAndChanges.Count) AS Count
	|FROM
	|	TTProductsAndChanges AS TTProductsAndChanges
	|WHERE
	|	TTProductsAndChanges.ForStornoReserve
	|
	|GROUP BY
	|	BEGINOFPERIOD(TTProductsAndChanges.Period, MONTH),
	|	TTProductsAndChanges.ItemsLocationAttributes,
	|	TTProductsAndChanges.Organization,
	|	TTProductsAndChanges.InventoryOwnerAttribute,
	|	TTProductsAndChanges.CCDNumber
	|
	|ORDER BY
	|	Period";
	
	NameOfOrganizationSProductReservesTable = NameOfOrganizationSProductReservesTable();
	
	If DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable) Then
		FormedReserves = DocumentObject.AdditionalProperties[NameOfOrganizationSProductReservesTable].Copy();
	Else
		FormedReserves = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	EndIf;
	
	Query.SetParameter("FormedReserves", FormedReserves);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Results = Query.ExecuteBatch();
	ProvisionsForStorno = Results[Results.UBound() - 1].Unload();
	ProvisionsForStorno.Indexes.Add("ItemsLocationAttributes, Organization, InventoryOwnerAttribute, CCDNumber");
	
	ProductsOfOrganizationsForStorno	= Results[Results.UBound()].Unload();
	TableOfStornoRegisteredRecords		= AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, Organization, InventoryOwnerAttribute, CCDNumber");
	
	For Each OrganizationProductsForStornoLine In ProductsOfOrganizationsForStorno Do
		
		YouCanDetach = OrganizationProductsForStornoLine.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, OrganizationProductsForStornoLine);
		LinesReservesForStorno = ProvisionsForStorno.FindRows(TheStructureOfTheSearch);
		
		For Each LineReservesForStorno In LinesReservesForStorno Do
			
			If LineReservesForStorno.Period < OrganizationProductsForStornoLine.Period Then
				Continue;
			EndIf;
			
			If YouCanDetach = 0 Then
				Continue;
			EndIf;
			
			QuantityToReverse	= Min(YouCanDetach, LineReservesForStorno.Count);
			
			NewRow = TableOfStornoRegisteredRecords.Add();
			FillPropertyValues(NewRow, LineReservesForStorno);
			NewRow.Period				= EndOfMonth(LineReservesForStorno.Period);
			NewRow.RecordType			= AccumulationRecordType.Receipt;
			NewRow.Count			= -QuantityToReverse;
			NewRow.QuantityByGBRN	= -?(LineReservesForStorno.Count <> 0,
												?(LineReservesForStorno.Count - QuantityToReverse = 0,
													LineReservesForStorno.QuantityByGBRN,
													QuantityToReverse * LineReservesForStorno.QuantityByGBRN / LineReservesForStorno.Count),
												0);
			NewRow.ThisIsReverseTransaction			= True;
			
			AccumulationRegisters.CompanySafeStock.AddCorRecordToReserveSet(TableOfStornoRegisteredRecords,
																						NewRow);
			
			LineReservesForStorno.Count		= LineReservesForStorno.Count - QuantityToReverse;
			LineReservesForStorno.QuantityByGBRN	= LineReservesForStorno.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			YouCanDetach = YouCanDetach - QuantityToReverse;
			
		EndDo;
		
	EndDo;
	
	Query.Text = 
	"DROP TTReserveSelectionsForStorno
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTFormedReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTReverseReservesOfPreviousPeriods";
	
	Query.Execute();
	
	If TableOfStornoRegisteredRecords.Count() > 0 Then
		RecursionDepth = 0;
		
		AddToTableStornoReservesStornoByExpense(DocumentObject,
														TableOfStornoRegisteredRecords,
														TableOfStornoRegisteredRecords,
														RecursionDepth);
	EndIf;
	
	If ParametersForFillingInventoryTypes.TableOfStornoRegisteredRecords <> Undefined Then
		ParametersForFillingInventoryTypes.Insert("TableOfStornoRegisteredRecords", TableOfStornoRegisteredRecords);
	Else
		Query.Text =
		"SELECT
		|	TTStornoReserves.RecordType AS RecordType,
		|	TTStornoReserves.Period AS Period,
		|	TTStornoReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TTStornoReserves.Organization AS Organization,
		|	TTStornoReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TTStornoReserves.CCDNumber AS CCDNumber,
		|	TTStornoReserves.Count AS Count,
		|	TTStornoReserves.QuantityByGBRN AS QuantityByGBRN,
		|	TTStornoReserves.CorCompany AS CorCompany,
		|	TTStornoReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
		|INTO TTStornoReserves
		|FROM
		|	&TableOfStornoRegisteredRecords AS TTStornoReserves";
		
		Query.SetParameter("TableOfStornoRegisteredRecords", TableOfStornoRegisteredRecords);
		
		Query.Execute();
	EndIf;
		
EndProcedure

Procedure AddToTableStornoReservesStornoByExpense(DocumentObject,
														OriginalTableIsStornow,
														ResultingTableIsStornow,
														RecursionDepth)
	
	If OriginalTableIsStornow.Count() = 0 Then
		Return;
	EndIf;
	
	RecursionDepth = RecursionDepth + 1;
	
	If RecursionDepth > 100 Then
		ExceptionText = NStr("vi = 'Độ sâu đệ quy tối đa đã vượt quá trong việc lập dự phòng đảo ngược cho tiêu dùng. Lưu trạng thái hiện tại của CSTT và chuyển nó cho các nhà phát triển chương trình.';
							|ru = 'Превышена максимальная глубина рекурсии при формировании сторно резервов по расходу. Сохраните текущее состояние информационной базы и передайте ее разработчикам программы.';
							|en = 'The maximum recursion depth is exceeded while generating expense reserve storno. Save the current infobase state and pass it to the application developers.'; fa = 'The maximum recursion depth is exceeded while generating expense reserve storno. Save the current infobase state and pass it to the application developers.';
							|it = 'Superata la profondità massima di ricorsione durante la formazione dello storno delle riserve per spese. Salvare lo stato corrente del database informatico e trasferirlo agli sviluppatori del programma.';
							|pl = 'Przekroczono maksymalną głębokość rekursji w tworzeniu rezerw odwracalnych do konsumpcji. Zapisz bieżący stan bazy danych informacji i prześlij ją do programistów.';
							|tr = 'Gidere göre iptal rezervler oluşturulurken maksimum güncelleme derinliği aşıldı. Infobase''in mevcut durumunu kaydet ve uygulama geliştiricilerine transfer et.'");
		
		Raise ExceptionText;
	EndIf;
	
	InventoriesServer.TextOfCounterReserveRequest("TTCounterReserveAnalysts", "TTReserveSelections");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FormedReserves.RecordType AS RecordType,
	|	ENDOFPERIOD(FormedReserves.Period, MONTH) AS Period,
	|	FormedReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	FormedReserves.Organization AS Organization,
	|	FormedReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	FormedReserves.CCDNumber AS CCDNumber,
	|	FormedReserves.Count AS Count,
	|	CAST(FormedReserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	FormedReserves.CorCompany AS CorCompany,
	|	FormedReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO FormedReserves
	|FROM
	|	&FormedReserves AS FormedReserves
	|WHERE
	|	FormedReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(ResultingTableIsStornow.Period, MONTH) AS Period,
	|	ResultingTableIsStornow.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ResultingTableIsStornow.Organization AS Organization,
	|	ResultingTableIsStornow.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ResultingTableIsStornow.CCDNumber AS CCDNumber,
	|	ResultingTableIsStornow.Count AS Count,
	|	CAST(ResultingTableIsStornow.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	ResultingTableIsStornow.CorCompany AS CorCompany,
	|	ResultingTableIsStornow.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO ResultingTableIsStornow
	|FROM
	|	&ResultingTableIsStornow AS ResultingTableIsStornow
	|WHERE
	|	ResultingTableIsStornow.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND ResultingTableIsStornow.ThisIsReverseTransaction
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(TTOriginalTableOfStornoRegisteredRecords.Period, MONTH) AS Period,
	|	TTOriginalTableOfStornoRegisteredRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTOriginalTableOfStornoRegisteredRecords.Organization AS Organization,
	|	TTOriginalTableOfStornoRegisteredRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTOriginalTableOfStornoRegisteredRecords.CCDNumber AS CCDNumber,
	|	TTOriginalTableOfStornoRegisteredRecords.Count AS Count,
	|	CAST(TTOriginalTableOfStornoRegisteredRecords.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	TTOriginalTableOfStornoRegisteredRecords.CorCompany AS CorCompany,
	|	TTOriginalTableOfStornoRegisteredRecords.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO TTOriginalTableOfStornoRegisteredRecords
	|FROM
	|	&OriginalTableIsStornow AS TTOriginalTableOfStornoRegisteredRecords
	|WHERE
	|	TTOriginalTableOfStornoRegisteredRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND TTOriginalTableOfStornoRegisteredRecords.ThisIsReverseTransaction
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTStornoReservesForInquiry.Period AS Period,
	|	TTStornoReservesForInquiry.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTStornoReservesForInquiry.Organization AS Organization,
	|	TTStornoReservesForInquiry.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTStornoReservesForInquiry.CCDNumber AS CCDNumber,
	|	SUM(TTStornoReservesForInquiry.Count) AS Count,
	|	SUM(TTStornoReservesForInquiry.QuantityByGBRN) AS QuantityByGBRN,
	|	TTStornoReservesForInquiry.CorCompany AS CorCompany,
	|	TTStornoReservesForInquiry.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO TTStornoReservesForInquiry
	|FROM
	|	(SELECT
	|		TTOriginalTableOfStornoRegisteredRecords.Period AS Period,
	|		TTOriginalTableOfStornoRegisteredRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TTOriginalTableOfStornoRegisteredRecords.Organization AS Organization,
	|		TTOriginalTableOfStornoRegisteredRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		TTOriginalTableOfStornoRegisteredRecords.CCDNumber AS CCDNumber,
	|		TTOriginalTableOfStornoRegisteredRecords.Count AS Count,
	|		TTOriginalTableOfStornoRegisteredRecords.QuantityByGBRN AS QuantityByGBRN,
	|		TTOriginalTableOfStornoRegisteredRecords.CorCompany AS CorCompany,
	|		TTOriginalTableOfStornoRegisteredRecords.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|	FROM
	|		TTOriginalTableOfStornoRegisteredRecords AS TTOriginalTableOfStornoRegisteredRecords
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		FormedReserves.Period,
	|		FormedReserves.ItemsLocationAttributes,
	|		FormedReserves.Organization,
	|		FormedReserves.InventoryOwnerAttribute,
	|		FormedReserves.CCDNumber,
	|		FormedReserves.Count,
	|		FormedReserves.QuantityByGBRN,
	|		FormedReserves.CorCompany,
	|		FormedReserves.CorInventoryOwnerAttribute
	|	FROM
	|		FormedReserves AS FormedReserves) AS TTStornoReservesForInquiry
	|
	|GROUP BY
	|	TTStornoReservesForInquiry.Organization,
	|	TTStornoReservesForInquiry.InventoryOwnerAttribute,
	|	TTStornoReservesForInquiry.CCDNumber,
	|	TTStornoReservesForInquiry.ItemsLocationAttributes,
	|	TTStornoReservesForInquiry.Period,
	|	TTStornoReservesForInquiry.CorInventoryOwnerAttribute,
	|	TTStornoReservesForInquiry.CorCompany
	|
	|HAVING
	|	SUM(TTStornoReservesForInquiry.Count) < 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTStornoReservesForInquiry.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTStornoReservesForInquiry.CCDNumber AS CCDNumber,
	|	TTStornoReservesForInquiry.Count AS Count,
	|	TTStornoReservesForInquiry.CorCompany AS CorCompany,
	|	TTStornoReservesForInquiry.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO TTReserveSelections
	|FROM
	|	TTStornoReservesForInquiry AS TTStornoReservesForInquiry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	NestedQuery.CorCompany AS CorCompany,
	|	NestedQuery.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.QuantityByGBRN) AS QuantityByGBRN
	|INTO TTReceiptsOfReservesForReversal
	|FROM
	|	(SELECT
	|		ENDOFPERIOD(CompanySafeStock.Period, MONTH) AS Period,
	|		CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanySafeStock.Organization AS Organization,
	|		CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber AS CCDNumber,
	|		CompanySafeStock.CorCompany AS CorCompany,
	|		CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		CompanySafeStock.Count AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanySafeStock.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
	|		END AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|			INNER JOIN TTReserveSelections AS TTReserveSelections
	|			ON CompanySafeStock.ItemsLocationAttributes = TTReserveSelections.ItemsLocationAttributes
	|				AND CompanySafeStock.CCDNumber = TTReserveSelections.CCDNumber
	|				AND CompanySafeStock.Organization = TTReserveSelections.CorCompany
	|				AND CompanySafeStock.InventoryOwnerAttribute = TTReserveSelections.CorInventoryOwnerAttribute
	|				AND (CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ENDOFPERIOD(CompanySafeStock.Period, MONTH),
	|		CompanySafeStock.ItemsLocationAttributes,
	|		CompanySafeStock.Organization,
	|		CompanySafeStock.InventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber,
	|		CompanySafeStock.CorCompany,
	|		CompanySafeStock.CorInventoryOwnerAttribute,
	|		-CompanySafeStock.Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanySafeStock.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE -CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
	|		END
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|			INNER JOIN TTReserveSelections AS TTReserveSelections
	|			ON CompanySafeStock.ItemsLocationAttributes = TTReserveSelections.ItemsLocationAttributes
	|				AND CompanySafeStock.CCDNumber = TTReserveSelections.CCDNumber
	|				AND CompanySafeStock.Organization = TTReserveSelections.CorCompany
	|				AND CompanySafeStock.InventoryOwnerAttribute = TTReserveSelections.CorInventoryOwnerAttribute
	|				AND (CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ENDOFPERIOD(FormedReserves.Period, MONTH),
	|		FormedReserves.ItemsLocationAttributes,
	|		FormedReserves.Organization,
	|		FormedReserves.InventoryOwnerAttribute,
	|		FormedReserves.CCDNumber,
	|		FormedReserves.CorCompany,
	|		FormedReserves.CorInventoryOwnerAttribute,
	|		FormedReserves.Count,
	|		FormedReserves.QuantityByGBRN
	|	FROM
	|		FormedReserves AS FormedReserves
	|			INNER JOIN TTReserveSelections AS TTReserveSelections
	|			ON FormedReserves.ItemsLocationAttributes = TTReserveSelections.ItemsLocationAttributes
	|				AND FormedReserves.CCDNumber = TTReserveSelections.CCDNumber
	|				AND FormedReserves.Organization = TTReserveSelections.CorCompany
	|				AND FormedReserves.InventoryOwnerAttribute = TTReserveSelections.CorInventoryOwnerAttribute
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ResultingTableIsStornow.Period,
	|		ResultingTableIsStornow.ItemsLocationAttributes,
	|		ResultingTableIsStornow.Organization,
	|		ResultingTableIsStornow.InventoryOwnerAttribute,
	|		ResultingTableIsStornow.CCDNumber,
	|		ResultingTableIsStornow.CorCompany,
	|		ResultingTableIsStornow.CorInventoryOwnerAttribute,
	|		ResultingTableIsStornow.Count,
	|		ResultingTableIsStornow.QuantityByGBRN
	|	FROM
	|		ResultingTableIsStornow AS ResultingTableIsStornow) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.CorCompany,
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.CorInventoryOwnerAttribute,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.Organization,
	|	NestedQuery.Period
	|
	|HAVING
	|	SUM(NestedQuery.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanySafeStock.Period AS Period,
	|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanySafeStock.Organization AS Organization,
	|	CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber AS CCDNumber,
	|	CompanySafeStock.CorCompany AS CorCompany,
	|	CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	CompanySafeStock.Count AS Count,
	|	CompanySafeStock.QuantityByGBRN AS QuantityByGBRN,
	|	TTStornoReservesForInquiry.Period AS ReserveReversalPeriod,
	|	-TTStornoReservesForInquiry.Count AS QuantityToDistribution,
	|	-TTStornoReservesForInquiry.QuantityByGBRN AS QuantityByRNPTKDistribution
	|FROM
	|	TTReceiptsOfReservesForReversal AS CompanySafeStock
	|		INNER JOIN TTStornoReservesForInquiry AS TTStornoReservesForInquiry
	|		ON CompanySafeStock.ItemsLocationAttributes = TTStornoReservesForInquiry.ItemsLocationAttributes
	|			AND CompanySafeStock.CCDNumber = TTStornoReservesForInquiry.CCDNumber
	|			AND CompanySafeStock.Organization = TTStornoReservesForInquiry.CorCompany
	|			AND CompanySafeStock.InventoryOwnerAttribute = TTStornoReservesForInquiry.CorInventoryOwnerAttribute
	|			AND CompanySafeStock.Period >= TTStornoReservesForInquiry.Period
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	CCDNumber,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	ReserveReversalPeriod,
	|	Period,
	|	CorCompany,
	|	CorInventoryOwnerAttribute";
	
	Query.SetParameter("OriginalTableIsStornow", OriginalTableIsStornow);
	
	NameOfOrganizationSProductReservesTable = NameOfOrganizationSProductReservesTable();
	
	If DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable) Then
		FormedReserves = DocumentObject.AdditionalProperties[NameOfOrganizationSProductReservesTable].Copy();
	Else
		FormedReserves = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	EndIf;
	
	Query.SetParameter("FormedReserves", FormedReserves);
	Query.SetParameter("ResultingTableIsStornow", ResultingTableIsStornow);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	CurAnalytics		= Undefined;
	CurNumberOfCCD			= Undefined;
	CurrentCompany		= Undefined;
	CurViewOfStocks		= Undefined;
	DistributedStorno	= New Map;
	OffsetReserves		= New Map;
	ReverseReserveConsumptionForDistribution = 0;
	
	Selection = Query.Execute().Select();
	
	TableOfStornoRegisteredRecords = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	
	While Selection.Next() Do
		
		DistributedInReversePeriod			= DistributedStorno.Get(Selection.ReserveReversalPeriod);
		ReverseReserveConsumptionForDistribution	= Selection.QuantityToDistribution;
		
		If CurAnalytics <> Selection.ItemsLocationAttributes
			Or CurNumberOfCCD <> Selection.CCDNumber
			Or CurrentCompany <> Selection.Organization
			Or CurViewOfStocks <> Selection.InventoryOwnerAttribute Then
			
			CurAnalytics		= Selection.ItemsLocationAttributes;
			CurNumberOfCCD			= Selection.CCDNumber;
			CurrentCompany		= Selection.Organization;
			CurViewOfStocks		= Selection.InventoryOwnerAttribute;
			DistributedStorno	= New Map;
			OffsetReserves		= New Map;
			
		ElsIf DistributedInReversePeriod <> Undefined
			And ReverseReserveConsumptionForDistribution = DistributedInReversePeriod.Count Then
			
			Continue;
			
		EndIf;
		
		DistributedInReversePeriod = DistributedStorno.Get(Selection.ReserveReversalPeriod);
		
		If DistributedInReversePeriod = Undefined Then
			DistributedQuantity = New Structure("Count, QuantityByGBRN", 0, 0);
			DistributedStorno.Insert(Selection.ReserveReversalPeriod, DistributedQuantity);
			
			AmountDistributedInPeriod		= 0;
			QuantityDistributedInPeriodAccordingToRNPT	= 0;
		Else
			AmountDistributedInPeriod		= DistributedInReversePeriod.Count;
			QuantityDistributedInPeriodAccordingToRNPT	= DistributedInReversePeriod.QuantityByGBRN;
		EndIf;
		
		KeyForFindingCreditedReserve = KeyForFindingCreditedReserve(Selection.Period,
																	Selection.CorCompany,
																	Selection.CorInventoryOwnerAttribute);
		
		ReserveCreditedInPeriod = OffsetReserves.Get(KeyForFindingCreditedReserve);
		
		If ReserveCreditedInPeriod = Undefined Then
			CreditedQuantity = New Structure("Count, QuantityByGBRN", 0, 0);
			OffsetReserves.Insert(KeyForFindingCreditedReserve, CreditedQuantity);
			
			AmountCreditedInPeriod			= 0;
			AmountCreditedInPeriodAccordingToRNPT	= 0;
		Else
			AmountCreditedInPeriod			= ReserveCreditedInPeriod.Count;
			AmountCreditedInPeriodAccordingToRNPT	= ReserveCreditedInPeriod.QuantityByGBRN;
		EndIf;
		
		QuantityToReverse		= Min(ReverseReserveConsumptionForDistribution - AmountDistributedInPeriod,
										Selection.Count - AmountCreditedInPeriod);
		QuantityForRNPTKReversal	= Min(Selection.QuantityByRNPTKDistribution - QuantityDistributedInPeriodAccordingToRNPT,
												Selection.QuantityByGBRN - AmountCreditedInPeriodAccordingToRNPT);
		
		NewRow = TableOfStornoRegisteredRecords.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.Period				= Selection.Period;
		NewRow.RecordType			= AccumulationRecordType.Receipt;
		NewRow.Count			= -QuantityToReverse;
		NewRow.QuantityByGBRN	= -QuantityForRNPTKReversal;
		NewRow.ThisIsReverseTransaction			= True;
		
		AccumulationRegisters.CompanySafeStock.AddCorRecordToReserveSet(TableOfStornoRegisteredRecords, NewRow);
		
		DistributedStorno[Selection.ReserveReversalPeriod].Count		= QuantityToReverse
																				+ DistributedStorno[Selection.ReserveReversalPeriod].Count;
		DistributedStorno[Selection.ReserveReversalPeriod].QuantityByGBRN	= QuantityToReverse
																				+ DistributedStorno[Selection.ReserveReversalPeriod].QuantityByGBRN;
		
		OffsetReserves[KeyForFindingCreditedReserve].Count		= QuantityToReverse
																			+ OffsetReserves[KeyForFindingCreditedReserve].Count;
		OffsetReserves[KeyForFindingCreditedReserve].QuantityByGBRN	= QuantityForRNPTKReversal
																			+ OffsetReserves[KeyForFindingCreditedReserve].QuantityByGBRN;
		
	EndDo;
	
	If TableOfStornoRegisteredRecords.Count() > 0 Then
		TMCommonUse.AddRowsToTable(ResultingTableIsStornow, TableOfStornoRegisteredRecords);
		
		AddToTableStornoReservesStornoByExpense(DocumentObject,
														TableOfStornoRegisteredRecords,
														ResultingTableIsStornow,
														RecursionDepth);
	EndIf;
	
EndProcedure

Function KeyForFindingCreditedReserve(Period, CorCompany, CorInventoryOwnerAttribute)
	
	Return String(Period) + String(CorCompany.UUID()) + String(CorInventoryOwnerAttribute.UUID());
	
EndFunction

Function TableReservesOfGoodsOfOrganizations(DocumentObject,
											TempTablesManager,
											ParametersForFillingInventoryTypes,
											BeforeWritingDocument)
	
	QueryText = 	
	"SELECT
	|	FormedReserves.RecordType AS RecordType,
	|	FormedReserves.Period AS Period,
	|	FormedReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	FormedReserves.Organization AS Organization,
	|	FormedReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	FormedReserves.CCDNumber AS CCDNumber,
	|	FormedReserves.Count AS Count,
	|	CAST(FormedReserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	FormedReserves.CorCompany AS CorCompany,
	|	FormedReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO FormedReserves
	|FROM
	|	&FormedReserves AS FormedReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.RecordType AS RecordType,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.QuantityByGBRN) AS QuantityByGBRN,
	|	CASE
	|		WHEN SUM(NestedQuery.Count) < 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsReverseTransaction,
	|	NestedQuery.CorCompany AS CorCompany,
	|	NestedQuery.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|FROM
	|	(SELECT
	|		TableNewReserves.RecordType AS RecordType,
	|		ENDOFPERIOD(TableNewReserves.Period, MONTH) AS Period,
	|		TableNewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableNewReserves.Organization AS Organization,
	|		TableNewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		TableNewReserves.CCDNumber AS CCDNumber,
	|		TableNewReserves.Count AS Count,
	|		CAST(TableNewReserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|		TableNewReserves.CorCompany AS CorCompany,
	|		TableNewReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|	FROM
	|		TTNewReserves AS TableNewReserves
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableStorno.RecordType,
	|		ENDOFPERIOD(TableStorno.Period, MONTH),
	|		TableStorno.ItemsLocationAttributes,
	|		TableStorno.Organization,
	|		TableStorno.InventoryOwnerAttribute,
	|		TableStorno.CCDNumber,
	|		TableStorno.Count,
	|		CAST(TableStorno.QuantityByGBRN AS NUMBER(23, 11)),
	|		TableStorno.CorCompany,
	|		TableStorno.CorInventoryOwnerAttribute
	|	FROM
	|		TTStornoReserves AS TableStorno
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProvisionsForOrganizationsForControl.RecordType,
	|		ENDOFPERIOD(ProvisionsForOrganizationsForControl.Period, MONTH),
	|		ProvisionsForOrganizationsForControl.ItemsLocationAttributes,
	|		ProvisionsForOrganizationsForControl.Organization,
	|		ProvisionsForOrganizationsForControl.InventoryOwnerAttribute,
	|		ProvisionsForOrganizationsForControl.CCDNumber,
	|		ProvisionsForOrganizationsForControl.Count,
	|		CAST(ProvisionsForOrganizationsForControl.QuantityByGBRN AS NUMBER(23, 11)),
	|		ProvisionsForOrganizationsForControl.CorCompany,
	|		ProvisionsForOrganizationsForControl.CorInventoryOwnerAttribute
	|	FROM
	|		TTProvisionsForOrganizationsForControl AS ProvisionsForOrganizationsForControl
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		FormedReserves.RecordType,
	|		ENDOFPERIOD(FormedReserves.Period, MONTH),
	|		FormedReserves.ItemsLocationAttributes,
	|		FormedReserves.Organization,
	|		FormedReserves.InventoryOwnerAttribute,
	|		FormedReserves.CCDNumber,
	|		FormedReserves.Count,
	|		CAST(FormedReserves.QuantityByGBRN AS NUMBER(23, 11)),
	|		FormedReserves.CorCompany,
	|		FormedReserves.CorInventoryOwnerAttribute
	|	FROM
	|		FormedReserves AS FormedReserves
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.RecordType,
	|		ENDOFPERIOD(RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.Period, MONTH),
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.ItemsLocationAttributes,
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.Organization,
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.InventoryOwnerAttribute,
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.CCDNumber,
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.QuantityByGBRN AS NUMBER(23, 11))
	|		END,
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.CorCompany,
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.CorInventoryOwnerAttribute
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording
	|	WHERE
	|		RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording.Recorder = &Ref
	|		AND &AddMovementReservesBeforeRecording) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.CorCompany,
	|	NestedQuery.CorInventoryOwnerAttribute,
	|	NestedQuery.RecordType,
	|	NestedQuery.Period
	|
	|HAVING
	|	NOT &ExcludeReverse
	|		AND SUM(NestedQuery.Count) <> 0
	// If reserves are completed (recalculated reversed) after recording the main movements,
	// then before recording it is necessary to exclude the reverse of reserves.
	|	OR &ExcludeReverse
	|		AND SUM(NestedQuery.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTNewReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTStornoReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTProvisionsForOrganizationsForControl
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FormedReserves";
	
	CheckForTemporaryReserveTables(TempTablesManager,
											"TTNewReserves, TTStornoReserves, TTProvisionsForOrganizationsForControl");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	
	NameOfOrganizationSProductReservesTable = NameOfOrganizationSProductReservesTable();
	
	If DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable) Then
		FormedReserves = DocumentObject.AdditionalProperties[NameOfOrganizationSProductReservesTable].Copy();
	Else
		FormedReserves = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	EndIf;
	
	Query.SetParameter("FormedReserves", FormedReserves);
	Query.SetParameter("Ref", DocumentObject.Ref);
	
	Query.SetParameter(
		"ExcludeReverse",
		BeforeWritingDocument
		And Not DocumentObject.AdditionalProperties.RecordReservesOfGoodsOfOrganizationsTogetherWithAll);
	
	Query.SetParameter(
		"AddMovementReservesBeforeRecording",
		// Reserves are recorded together with other registers.
		Not ParametersForFillingInventoryTypes.DocumentMakesBothArrivalAndExpenditure
		// Reserves are recorded separately after the formation of the table of reserves in the processing of the event.
		Or DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable)
			And Not BeforeWritingDocument);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	ResultTableReserves = Query.Execute().Unload();
	
	Return ResultTableReserves;
	
EndFunction

Procedure CheckForTemporaryReserveTables(TempTablesManager, TablesNames)
	
	NamesArray = StrSplit(TablesNames, ",");
	
	QueryTexts = New Array;
	
	For Each ArrRow In NamesArray Do
		ArrRow = TrimAll(ArrRow);
		
		If TempTablesManager.Tables.Find(ArrRow) = Undefined Then
			QueryText =
			"SELECT
			|	NewTable.Period,
			|	NewTable.RecordType,
			|	NewTable.ItemsLocationAttributes,
			|	NewTable.Organization,
			|	NewTable.InventoryOwnerAttribute,
			|	NewTable.CCDNumber,
			|	NewTable.Count,
			|	CAST(NewTable.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
			|	NewTable.CorCompany,
			|	NewTable.CorInventoryOwnerAttribute,
			|	NewTable.ThisIsReverseTransaction AS ReversingEntry
			|INTO TableName
			|FROM
			|	&EmptyTable AS NewTable";
			
			QueryText = StrReplace(QueryText, "TableName", ArrRow);
			
			QueryTexts.Add(QueryText);
		EndIf;
		
	EndDo;
	
	If QueryTexts.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("EmptyTable",
								AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns());
	
	Query.Execute();
	
EndProcedure

Procedure SetAdditionalPropertiesControlResiduesAndFormStorno(DocumentObject, ParametersForFillingInventoryTypes, TempTablesManager)
	
	AdditionalProperties = DocumentObject.AdditionalProperties; 
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT TOP 1
	|	TTProductsAndChanges.Period,
	|	TTProductsAndChanges.Organization
	|FROM
	|	TTProductsAndChanges AS TTProductsAndChanges
	|WHERE
	|	TTProductsAndChanges.ForResidueControl
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TTProductsAndChanges.Period,
	|	TTProductsAndChanges.Organization
	|FROM
	|	TTProductsAndChanges AS TTProductsAndChanges
	|WHERE
	|	TTProductsAndChanges.ForStornoReserve";
	
	Results = Query.ExecuteBatch();
	
	YouNeedToControlLeftovers = Not Results[0].IsEmpty();
	NeedToFormStorno     = Not Results[1].IsEmpty();
	
	AdditionalProperties.Insert("ItIsNecessaryToControlRemnantsOfGoods", YouNeedToControlLeftovers);
	If Not YouNeedToControlLeftovers Then
		ParametersForFillingInventoryTypes.NumberOfPeriodsWhenFormingReservesOfOrganizations = 0;
	EndIf;
	AdditionalProperties.Insert("ItIsNecessaryToFormStornoOnReservesOfGoods", NeedToFormStorno);
	
EndProcedure

Procedure GenerateTTTableOfDetailsOfStockTypesByDefault(TempTablesManager, ParametersForFillingInventoryTypes)
	
	QueryText = "";
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager, "TableOfDetailsOfStockTypesByDefault") Then
		QueryText =
		"DROP TableOfDetailsOfStockTypesByDefault
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
	EndIf;
	
	QueryText = QueryText +
	"SELECT
	|	DefaultStockTypes.LineNumber AS LineNumber,
	|	DefaultStockTypes.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DefaultStockTypes.Organization		AS Organization,
	|	DefaultStockTypes.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	DefaultStockTypes.CCDNumber			AS CCDNumber,
	|	DefaultStockTypes.GoodsOwner	AS GoodsOwner,
	|	DefaultStockTypes.Counterparty		AS Counterparty,
	|	DefaultStockTypes.Contract			AS Contract,
	|	DefaultStockTypes.InventoryType		AS InventoryType
	|INTO TableOfDetailsOfStockTypesByDefault
	|FROM
	|	&TableOfDetailsOfStockTypesByDefault AS DefaultStockTypes
	|";
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	
	Query.SetParameter("TableOfDetailsOfStockTypesByDefault", ParametersForFillingInventoryTypes.TableOfDetailsOfStockTypesByDefault);
	
	Query.Execute();
	
EndProcedure

Procedure GenerateTTSelectionsOfBalancesForProductTable(TempTablesManager, AddAnalyticsFromRegisteredRecordsBeforeRecording, SelectStocksOfDifferentPeriods = False)

	PartsOfQueryText = New Array;
	TextOfRequestPart =
		"SELECT
		|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Goods.CCDNumber AS CCDNumber,
		|	InventoryKinds.ForCompany AS Organization,
		|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute
		|FROM
		|	TableOfGoods AS Goods
		|		INNER JOIN AvailableTypesOfStocks AS InventoryKinds
		|		ON (TRUE)
		|		
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
		|		ON Goods.ItemsLocationAttributes = DimensionKeys.Ref
		|		
		|		LEFT JOIN Catalog.Products AS ProductData_1
		|		ON DimensionKeys.Products = ProductData_1.Ref
		|WHERE
		|	ProductData_1.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
		|										VALUE(Enum.ItemsTypes.ReusablePackage))
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Goods.CCDNumber AS CCDNumber,
		|	InventoryKinds.ForCompany AS Organization,
		|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute
		|FROM
		|	TableOfGoods AS Goods
		|		INNER JOIN AvailableTypesOfStocks AS InventoryKinds
		|		ON (TRUE)
		|		
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
		|		ON Goods.ItemsLocationAttributes = DimensionKeys.Ref
		|		
		|		LEFT JOIN Catalog.Products AS ProductData_1
		|		ON DimensionKeys.Products = ProductData_1.Ref
		|WHERE
		|	(ProductData_1.ItemsType, ProductData_1.TracedGoods) IN
		|		(SELECT
		|			VALUE(Enum.ItemsTypes.Work_5),
		|			TRUE)";
	If SelectStocksOfDifferentPeriods Then
		TextOfRequestPart = StrReplace(TextOfRequestPart, "TableOfGoods", "TableOfProductsByPeriod");
	EndIf;
	PartsOfQueryText.Add(TextOfRequestPart);

	If TempTablesManager.Tables.Find("TTTableOfGoodsRegistration") <> Undefined Then	// To escalate the context to a platform lock
		TextOfRequestPart =
			"SELECT
			|	ItemsRegistration.ItemsLocationAttributes,
			|	VALUE(Catalog.CCDNumbers.EmptyRef),
			|	InventoryKinds.ForCompany,
			|	InventoryKinds.InventoryOwnerAttribute
			|FROM
			|	TTTableOfGoodsRegistration AS ItemsRegistration
			|		INNER JOIN AvailableTypesOfStocks AS InventoryKinds
			|		ON (TRUE)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If AddAnalyticsFromRegisteredRecordsBeforeRecording Then
		TextOfRequestPart =
			"SELECT
			|	GoodsBeforeWrite.ItemsLocationAttributes,
			|	GoodsBeforeWrite.CCDNumber,
			|	GoodsBeforeWrite.Organization,
			|	GoodsBeforeWrite.InventoryOwnerAttribute
			|FROM
			|	MovementOfOrganizationsProductsBeforeRecording AS GoodsBeforeWrite
			|		INNER JOIN AvailableTypesOfStocks AS AvailableTypesOfStocks
			|		ON GoodsBeforeWrite.Organization = AvailableTypesOfStocks.ForCompany
			|			AND GoodsBeforeWrite.InventoryOwnerAttribute = AvailableTypesOfStocks.InventoryOwnerAttribute";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;
	
	TheTextOfASubquery = StrConcat(PartsOfQueryText, TMCommonUse.QuerySeparatorInJoin());

	QueryText = 
		"SELECT DISTINCT
		|	InventoryLocationAttributeKeys.Ref AS ItemsLocationAttributes,
		|	InventoryLocationAttributeKeys.Products AS Products,
		|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
		|	InventoryLocationAttributeKeys.Series AS Series,
		|	InventoryLocationAttributeKeys.Purpose AS Purpose,
		|	InventoryLocationAttributeKeys.StorageLocation AS Warehouse,
		|	Filters.Organization AS Organization,
		|	Filters.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Filters.CCDNumber AS CCDNumber
		|INTO TTSelectionsOfBusinessBalances
		|FROM
		|	&TheTextOfASubquery AS Filters
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON (InventoryLocationAttributeKeys.Ref = Filters.ItemsLocationAttributes)
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	Organization";
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", StrTemplate("(%1)", TheTextOfASubquery));

	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
		
EndProcedure

Procedure GenerateTTSelectionsOfBalancesAccordingToTableOfChanges(TempTablesManager)
	
	QueryText = 
	"SELECT DISTINCT
	|	ProductsOfOrganizationsChanges.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ProductsOfOrganizationsChanges.CCDNumber AS CCDNumber,
	|	InventoryLocationAttributeKeys.Products AS Products,
	|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
	|	InventoryLocationAttributeKeys.Series AS Series,
	|	InventoryLocationAttributeKeys.Purpose AS Purpose,
	|	InventoryLocationAttributeKeys.StorageLocation AS Warehouse,
	|	InventoryKinds.ForCompany AS Organization,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTSelectionsOfBusinessBalances
	|FROM
	|	TTProductsAndChanges AS ProductsOfOrganizationsChanges
	|		INNER JOIN AvailableTypesOfStocks AS InventoryKinds
	|		ON (TRUE)
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON ProductsOfOrganizationsChanges.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|WHERE
	|	CatProducts.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods), 
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	Organization";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// Fills in the tabular part of the document types "Report on commission between organizations"
// and "Report on commission between organizations (on write-off)" the fields of the Assignee's type and number.
//
// Parameters:
//	DocumentObject - DocumentObject - the document in which the filling is performed.
//	TempTablesManager - TempTablesManager - Used FOR available types of Supplies.
//	Cancel - Boolean - Indicates whether the document should be interrupted.
//	ParametersForFillingInventoryTypes - See InventoriesServer.ParametersForFillingInventoryTypes.
//
Procedure ReplenishTypesOfStocksInReportsOnIntercampanyCommission(DocumentObject,
																TempTablesManager,
																Cancel,
																ParametersForFillingInventoryTypes)
	
	If DocumentObject.InventoryKinds.Find(Catalogs.InventoryKinds.EmptyRef(), "InventoryAttributesOfConsignor") = Undefined Then
		Return;
	EndIf;
	
	If TempTablesManager.Tables.Find("BalanceTable") <> Undefined Then
		Query = New Query("DROP BalanceTable");
		Query.TempTablesManager = TempTablesManager;
		
		Query.Execute();
	EndIf;
	
	ThisIsASalesReport = TypeOf(DocumentObject.Ref) = Type("DocumentRef.CommissionReportIntercompany");
	
	GenerateTTTableOfBalances("GoodsTransferredToCommissionAgent",
									DocumentObject,
									TempTablesManager,
									ParametersForFillingInventoryTypes);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Inventories.ItemsLocationAttributes,
	|	Inventories.CCDNumber
	|INTO Inventories
	|FROM
	|	&InventoryKinds AS Inventories
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Inventories.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Inventories.CCDNumber AS CCDNumber
	|INTO FilterLeftovers
	|FROM
	|	Inventories AS Inventories
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CommissionAgentAnalytics.DimensionKey	AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute					AS InventoryAttributesOfConsignor,
	|	Balance.CCDNumber					AS CCDNumber,
	|	CASE
	|		WHEN Balance.CountBalance < 0
	|			THEN -Balance.CountBalance
	|		ELSE Balance.CountBalance
	|	END								AS Count,
	|	CASE
	|		WHEN Balance.QuantityByGBRNBalance < 0
	|			THEN -CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11))
	|		ELSE CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11))
	|	END								AS QuantityByGBRN
	|FROM
	|	BalanceTable AS Balance
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON Balance.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Balance.ItemsLocationAttributes = Dimension.Ref
	|		
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS CommissionAgentAnalytics
	|		ON Dimension.Products = CommissionAgentAnalytics.Products
	|			AND Dimension.Characteristic = CommissionAgentAnalytics.Characteristic
	|			AND Dimension.Series = CommissionAgentAnalytics.Series
	|			AND CommissionAgentAnalytics.StorageLocation = &Organization
	|		
	|		INNER JOIN FilterLeftovers AS Filter
	|		ON CommissionAgentAnalytics.DimensionKey = Filter.ItemsLocationAttributes
	|			AND Balance.CCDNumber = Filter.CCDNumber
	|
	|WHERE
	|	NOT InventoryKinds.SaleOfAnotherCompanyInventory
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	Balance.CCDNumber,
	|	Balance.CountBalance ASC
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|DROP Inventories
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|DROP FilterLeftovers";
	
	UnloadedColumns	= "ItemsLocationAttributes, CCDNumber";
	
	Query.SetParameter("Organization",	DocumentObject.Organization);
	Query.SetParameter("InventoryKinds",	DocumentObject.InventoryKinds.Unload(, UnloadedColumns));
	
	ResultsArray = Query.ExecuteBatch();
	BalanceTable = ResultsArray[ResultsArray.UBound() - 2].Unload();
	
	RowSelectionColumns = "ItemsLocationAttributes, CCDNumber, InventoryAttributesOfConsignor";
	
	InventoryKinds = DocumentObject.InventoryKinds.Unload();
	InventoryKinds.Sort("ItemsLocationAttributes, CCDNumber, Count ASC");
	InventoryKinds.Indexes.Add("Count");
	InventoryKinds.Indexes.Add(RowSelectionColumns);
	InventoryKinds.Indexes.Add("InventoryAttributesOfConsignor");
	
	DocumentObject.InventoryKinds.Sort("ItemsLocationAttributes, CCDNumber, Count ASC");
	
	SelectingBalanceRows	= New Structure(UnloadedColumns);
	FilterDocumentLines	= New Structure(RowSelectionColumns);
	
	CurAnalytics		= Undefined;
	CurNumberOfCCD			= Undefined;
	InventoryOwnerAttributeOfDistribution	= Undefined; // The committee's Inventory owner attribute to which the number of returned inventory is distributed according to one item accounting analysis.
	
	AmountOfCompensation		= 0; // The number of the committee's returned inventory according to one item accounting analysis, with the exception of the amount of inventory for which the distribution is performed.
	AmountOfProductBatchIDCompensation	= 0;
	
	For Each RemainderLine In BalanceTable Do
		
		If RemainderLine.ItemsLocationAttributes <> CurAnalytics
			Or RemainderLine.CCDNumber <> CurNumberOfCCD Then
			
			CurAnalytics	= RemainderLine.ItemsLocationAttributes;
			CurNumberOfCCD		= RemainderLine.CCDNumber;
			
			AmountOfCompensation		= 0;
			AmountOfProductBatchIDCompensation	= 0;
			
			FillPropertyValues(SelectingBalanceRows, RemainderLine);
			LinesOfCurrentAnalytics = BalanceTable.FindRows(SelectingBalanceRows);
			
			InventoryOwnerAttributeOfDistribution = LinesOfCurrentAnalytics[LinesOfCurrentAnalytics.Count() - 1].InventoryAttributesOfConsignor;
		EndIf;
		
		CompensateForQuantity = RemainderLine.InventoryAttributesOfConsignor <> InventoryOwnerAttributeOfDistribution;
		
		FillPropertyValues(FilterDocumentLines, RemainderLine);
		FilterDocumentLines.InventoryAttributesOfConsignor = Catalogs.InventoryKinds.EmptyRef();
		
		QuantityForReturn			= RemainderLine.Count;
		QuantityForRNPTKReturn	= RemainderLine.QuantityByGBRN;
		
		SignChange = False;
		
		For Each InventoryLine In InventoryKinds.FindRows(FilterDocumentLines) Do
			
			If RemainderLine.Count = 0 Then
				Break;
			EndIf;
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count	= ?(InventoryLine.Count < 0, -InventoryLine.Count, InventoryLine.Count);
			Character		= ?(InventoryLine.Count < 0, -1, 1);
			
			If Character < 0 Then
				
				If QuantityForReturn = 0 Then
					Continue;
				EndIf;
				
				SignChange = True;
				
				If QuantityForReturn >= Count Then
					InventoryLine.InventoryAttributesOfConsignor = RemainderLine.InventoryAttributesOfConsignor;
					
					QuantityForRNPTKReturnUpTo	= QuantityForRNPTKReturn;
					QuantityForRNPTKReturn	= ?(QuantityForReturn <> 0,
													?(QuantityForReturn - Count = 0,
														0,
														QuantityForRNPTKReturn - Count
															* QuantityForRNPTKReturn / QuantityForReturn),
													0);
					QuantityForReturn			= QuantityForReturn - Count;
					
					If CompensateForQuantity Then
						AmountOfCompensation		= AmountOfCompensation + Count;
						AmountOfProductBatchIDCompensation	= AmountOfProductBatchIDCompensation + QuantityForRNPTKReturnUpTo
														- QuantityForRNPTKReturn;
					EndIf;
				Else
					NewRow = InventoryKinds.Add();
					FillPropertyValues(NewRow, InventoryLine);
					
					NewRow.InventoryAttributesOfConsignor	= RemainderLine.InventoryAttributesOfConsignor;
					NewRow.AmountIncludingVAT			= Round(QuantityForReturn * InventoryLine.AmountIncludingVAT / InventoryLine.Count,
															2,
															1) * Character;
					NewRow.VATAmount			= Round(QuantityForReturn * InventoryLine.VATAmount / InventoryLine.Count,
															2,
															1) * Character;
					
					If ThisIsASalesReport Then
						NewRow.CommissionAmount		= Round(QuantityForReturn * InventoryLine.CommissionAmount
																		/ InventoryLine.Count,
																	2,
																	1) * Character;
						NewRow.AmountVATRemuneration	= Round(QuantityForReturn * InventoryLine.AmountVATRemuneration
																		/ InventoryLine.Count,
																	2,
																	1) * Character;
					EndIf;
					
					NewRow.Count			= QuantityForReturn * Character;
					NewRow.QuantityByGBRN	= QuantityForRNPTKReturn * Character;
					NewRow.NumberOfPackages	= Round(QuantityForReturn * InventoryLine.NumberOfPackages
																/ InventoryLine.Count,
															2,
															1) * Character;
					
					InventoryLine.Count			= InventoryLine.Count - NewRow.Count;
					InventoryLine.QuantityByGBRN		= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
					InventoryLine.NumberOfPackages	= InventoryLine.NumberOfPackages - NewRow.NumberOfPackages;
					InventoryLine.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
					InventoryLine.VATAmount				= InventoryLine.VATAmount - NewRow.VATAmount;
					
					If ThisIsASalesReport Then
						InventoryLine.CommissionAmount		= InventoryLine.CommissionAmount - NewRow.CommissionAmount;
						InventoryLine.AmountVATRemuneration	= InventoryLine.AmountVATRemuneration - NewRow.AmountVATRemuneration;
					EndIf;
					
					If CompensateForQuantity Then
						AmountOfCompensation		= AmountOfCompensation + QuantityForReturn;
						AmountOfProductBatchIDCompensation	= AmountOfProductBatchIDCompensation + QuantityForRNPTKReturn;
					EndIf;
					
					QuantityForReturn			= 0;
					QuantityForRNPTKReturn	= 0;
					
				EndIf;
				
			Else
				
				If SignChange Then
					// The accumulated amount is compensated for the committee's last Inventory owner attribute.
					If Not CompensateForQuantity Then
						RemainderLine.Count		= 2 * RemainderLine.Count - QuantityForReturn
															+ AmountOfCompensation;
						RemainderLine.QuantityByGBRN	= 2 * RemainderLine.QuantityByGBRN - QuantityForRNPTKReturn
															+ AmountOfProductBatchIDCompensation;
					EndIf;
					
					SignChange = False;
				Else
					// The accumulated amount is compensated for the committee's last Inventory owner attribute.
					If Not CompensateForQuantity Then
						CompensateForQuantity = True; // Restoration of the amount of Balances is performed 1 time.
						
						RemainderLine.Count		= RemainderLine.Count + AmountOfCompensation;
						RemainderLine.QuantityByGBRN	= RemainderLine.QuantityByGBRN + AmountOfProductBatchIDCompensation;
					EndIf;
				EndIf;
				
				If RemainderLine.Count >= Count Then
					InventoryLine.InventoryAttributesOfConsignor = RemainderLine.InventoryAttributesOfConsignor;
					
					RemainderLine.QuantityByGBRN	= ?(RemainderLine.Count <> 0,
														?(RemainderLine.Count - Count = 0,
															0,
															RemainderLine.QuantityByGBRN - Count
																* RemainderLine.QuantityByGBRN / RemainderLine.Count),
															0);
					RemainderLine.Count		= RemainderLine.Count - Count;
				Else
					
					NewRow = InventoryKinds.Add();
					FillPropertyValues(NewRow, InventoryLine);
					
					NewRow.InventoryAttributesOfConsignor	= RemainderLine.InventoryAttributesOfConsignor;
					NewRow.AmountIncludingVAT			= Round(RemainderLine.Count * InventoryLine.AmountIncludingVAT / InventoryLine.Count,
															2,
															1);
					NewRow.VATAmount			= Round(RemainderLine.Count * InventoryLine.VATAmount / InventoryLine.Count,
															2,
															1);
					
					If ThisIsASalesReport Then
						NewRow.CommissionAmount		= Round(RemainderLine.Count * InventoryLine.CommissionAmount
																		/ InventoryLine.Count,
																	2,
																	1);
						NewRow.AmountVATRemuneration	= Round(RemainderLine.Count * InventoryLine.AmountVATRemuneration
																		/ InventoryLine.Count,
																	2,
																	1);
					EndIf;
					
					NewRow.Count			= RemainderLine.Count;
					NewRow.QuantityByGBRN	= RemainderLine.QuantityByGBRN;
					NewRow.NumberOfPackages	= Round(RemainderLine.Count * InventoryLine.NumberOfPackages
																/ InventoryLine.Count,
															2,
															1);
					
					InventoryLine.Count			= InventoryLine.Count - NewRow.Count;
					InventoryLine.QuantityByGBRN		= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
					InventoryLine.NumberOfPackages	= InventoryLine.NumberOfPackages - NewRow.NumberOfPackages;
					InventoryLine.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
					InventoryLine.VATAmount				= InventoryLine.VATAmount - NewRow.VATAmount;
					
					If ThisIsASalesReport Then
						InventoryLine.CommissionAmount		= InventoryLine.CommissionAmount - NewRow.CommissionAmount;
						InventoryLine.AmountVATRemuneration	= InventoryLine.AmountVATRemuneration - NewRow.AmountVATRemuneration;
					EndIf;
					
					RemainderLine.Count		= 0;
					RemainderLine.QuantityByGBRN	= 0;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	RowFilter = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(RowFilter);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
	RowFilter = New Structure("InventoryAttributesOfConsignor", Catalogs.InventoryKinds.EmptyRef());
	LinesWithEmptyViewOfCommitteeSInventory = InventoryKinds.FindRows(RowFilter);
	
	If ValueIsFilled(LinesWithEmptyViewOfCommitteeSInventory)
		And ParametersForFillingInventoryTypes.ReportFillingErrors Then
		
		Cancel = True;
		
		For Each TableRow In LinesWithEmptyViewOfCommitteeSInventory Do
			
			AnalyticsDetails_ = Common.ObjectAttributesValues(TableRow.ItemsLocationAttributes, 
				"Products, Products.UnitOfMeasure, Characteristic");
			
			If TableRow.Count <> 0 Then
				MessageText = NStr("vi = 'Theo người đặt ký gửi %Consignor% không đủ %Count% %UnitOfMeasure% hàng hóa %ProductPresentation% do người nhận ký gửi đã bán %Consignee%';
									|ru = 'По комитенту %Consignor% не хватает %Count% %UnitOfMeasure% товара %ProductPresentation%, реализованного комиссионером %Consignee%';
									|en = 'By the %Consignor% consignor, not enough %Count% %UnitOfMeasure% of the %ProductPresentation% goods sold by the %Consignee% consignee'; fa = 'By the %Consignor% consignor, not enough %Count% %UnitOfMeasure% of the %ProductPresentation% goods sold by the %Consignee% consignee';
									|it = 'Per committente %Consignor% non è sufficiente %Count%%UnitOfMeasure% della merce %ProductPresentation%, venduta dall''agente in conto vendita %Consignee%';
									|pl = 'Dla komitenta %Consignor% brakuje %Count% %UnitOfMeasure% towaru %ProductPresentation%, sprzedanego przez komisanta %Consignee%';
									|tr = 'Göndericiye %Consignor% göre konsinye %Count% %UnitOfMeasure% tarafından %ProductPresentation% satışı yapılan ürün eksik %Consignee%'");
				MessageText = StrReplace(MessageText, "%Consignor%", DocumentObject.Organization);
				MessageText = StrReplace(MessageText, "%Consignee%", DocumentObject.Consignee);
				MessageText = StrReplace(MessageText,
											"%ProductPresentation%",
											ProductsClientServer.ProductPresentation(
												AnalyticsDetails_.Products,
												AnalyticsDetails_.Characteristic));
				MessageText = StrReplace(MessageText, "%Count%", TableRow.Count);
				MessageText = StrReplace(MessageText,
											"%UnitOfMeasure%",
											AnalyticsDetails_.ProductsUnitOfMeasure);
				
				Common.MessageToUser(MessageText, DocumentObject);
			EndIf;
			
			If ThisIsASalesReport
				And TableRow.AmountIncludingVAT <> 0 Then
				
				MessageText = NStr("vi = 'Hàng hóa: %ProductPresentation% Số lượng bán vượt quá số lượng hàng bán của đại lý theo %Sum% %Currency%';
									|ru = 'Товар: %ProductPresentation% Сумма продажи превышает сумму реализованного товара комиссионером на %Sum% %Currency%';
									|en = 'Goods: %ProductPresentation% The sale amount exceeds the amount of goods sold by the consignee by %Sum% %Currency%'; fa = 'Goods: %ProductPresentation% The sale amount exceeds the amount of goods sold by the consignee by %Sum% %Currency%';
									|it = 'Merce:  %ProductPresentation% L''importo della vendita supera l''importo della merce venduta dall''agente in conto vendita di %Sum% %Currency%';
									|pl = 'Towar: %ProductPresentation% Wartość sprzedaży przekracza kwotę towaru, sprzedanego przez komisanta o %Sum% %Currency%';
									|tr = 'Ürünler: %ProductPresentation% Satış tutarı, konsinye tarafından satılan ürün miktarını %Sum% %Currency% oranında aşıyor'");
				MessageText = StrReplace(MessageText,
											"%ProductPresentation%",
											ProductsClientServer.ProductPresentation(
												AnalyticsDetails_.Products,
												AnalyticsDetails_.Characteristic));
				MessageText = StrReplace(MessageText, "%Sum%", TableRow.AmountIncludingVAT);
				MessageText = StrReplace(MessageText, "%Currency%", DocumentObject.Currency);
				
				Common.MessageToUser(MessageText, DocumentObject);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	DocumentObject.InventoryKinds.Load(InventoryKinds);
	
EndProcedure

// Fills in the tabular part "Types of stocks" of the documents "Commission report between organizations" and "
// Commission report between organizations on write-off".
//
// Parameters:
//	DocumentObject - DocumentObject - The document, which are filled with stock types.
//	TempTablesManager - TempTablesManager- a manager containing temporary tables of tables of goods,
//														Tables of Inventory views, tables of statistics.
//	Cancel - Boolean - Indicates whether the document should be interrupted.
//	ParametersForFillingInventoryTypes - Undefined, Structure - See InventoriesServer.ParametersForFillingInventoryTypes.
//
Procedure FillInTypesOfStocksAccordingToTableOfBalancesOfCommissionGoodsIntercampany(DocumentObject,
																				TempTablesManager,
																				Cancel,
																				ParametersForFillingInventoryTypes)
	
	ErrorsTable			= TableOfErrorsInFillingInventoryTypes();
	AdditionalProperties	= DocumentObject.AdditionalProperties;
	
	TableTypesOfStocks_ = DocumentObject[ParametersForFillingInventoryTypes.NameTSTypesOfStocks].UnloadColumns(); // TabularSection
	
	DefaultStockView = Undefined;
	
	ThisIsASalesReport = TypeOf(DocumentObject.Ref) = Type("DocumentRef.CommissionReportIntercompany");
	
	RefillInventoryKinds = CheckWhetherDocumentInventoryTypesNeedToBeRefilled(AdditionalProperties);
	
	ControlCompanyStockBalance = ?(RefillInventoryKinds,
												False,
												GetFunctionalOption("ControlCompanyStockBalance"));
	
	AttributesNames = 
		"FinancialAccountingGroup,
		|Vendor,
		|Counterparty,
		|Terms,
		|Contract,
		|Currency,
		|VATTaxation,
		|TaxationOfOrganization,
		|Organization";
	
	DefaultInventoryViewStructure = New Structure(AttributesNames);
	
	DefaultInventoryViewStructure.FinancialAccountingGroup		= Catalogs.InventoryAccountingGroups.EmptyRef();
	DefaultInventoryViewStructure.Vendor					= DocumentObject.Organization;
	DefaultInventoryViewStructure.Counterparty					= Undefined;
	DefaultInventoryViewStructure.Terms					= Undefined;
	DefaultInventoryViewStructure.Contract						= Undefined;
	DefaultInventoryViewStructure.Currency						= DocumentObject.Currency;
	DefaultInventoryViewStructure.VATTaxation			= DocumentObject.VATTaxation;
	DefaultInventoryViewStructure.TaxationOfOrganization	= DocumentObject.VATTaxation;
	DefaultInventoryViewStructure.Organization					= DocumentObject.Organization;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Balance.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	Balance.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Balance.CCDNumber					AS CCDNumber,
	|	CASE
	|		WHEN VALUETYPE(BalanceTable.TaxInvoice) = TYPE(STRING)
	|			THEN CASE
	|					WHEN BalanceTable.TaxInvoice = """"
	|						THEN UNDEFINED
	|					ELSE BalanceTable.TaxInvoice
	|				END
	|		ELSE ISNULL(BalanceTable.TaxInvoice, UNDEFINED)
	|	END								AS IssuedTaxInvoiceOfCommissionAgent,
	|	BalanceTable.TaxInvoiceDate	AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Balance.Customer					AS Customer,
	|	BalanceTable.Character				AS Character,
	|	SUM(CASE
	|			WHEN BalanceTable.Count < 0
	|				THEN -BalanceTable.Count
	|			ELSE BalanceTable.Count
	|		END)							AS Count,
	|	SUM(CASE
	|			WHEN BalanceTable.QuantityByGBRN < 0
	|				THEN -BalanceTable.QuantityByGBRN
	|			ELSE BalanceTable.QuantityByGBRN
	|		END)							AS QuantityByGBRN,
	|	SUM(CASE
	|			WHEN BalanceTable.Count < 0
	|				THEN -BalanceTable.RevenueAmount
	|			ELSE BalanceTable.RevenueAmount
	|		END)							AS RevenueAmount
	|FROM
	|	(SELECT
	|		BalanceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		BalanceTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		BalanceTable.CCDNumber					AS CCDNumber,
	|		BalanceTable.Customer					AS Customer,
	|		SUM(BalanceTable.Count)			AS Count,
	|		SUM(CAST(BalanceTable.QuantityByGBRN AS NUMBER(23, 11)))	AS QuantityByGBRN,
	|		SUM(BalanceTable.RevenueAmount)			AS RevenueAmount
	|	FROM
	|		BalanceTable AS BalanceTable
	|	
	|	GROUP BY
	|		BalanceTable.InventoryOwnerAttribute,
	|		BalanceTable.ItemsLocationAttributes,
	|		BalanceTable.CCDNumber,
	|		BalanceTable.Customer
	|	
	|	HAVING
	|		SUM(BalanceTable.Count) <> 0
	|	
	|	) AS Balance
	|		LEFT JOIN BalanceTable AS BalanceTable
	|		ON Balance.InventoryOwnerAttribute = BalanceTable.InventoryOwnerAttribute
	|			AND Balance.ItemsLocationAttributes = BalanceTable.ItemsLocationAttributes
	|			AND Balance.CCDNumber = BalanceTable.CCDNumber
	|			AND Balance.Customer = BalanceTable.Customer
	|
	|GROUP BY
	|	Balance.InventoryOwnerAttribute,
	|	Balance.ItemsLocationAttributes,
	|	Balance.CCDNumber,
	|	CASE
	|		WHEN VALUETYPE(BalanceTable.TaxInvoice) = TYPE(STRING)
	|			THEN CASE
	|					WHEN BalanceTable.TaxInvoice = """"
	|						THEN UNDEFINED
	|					ELSE BalanceTable.TaxInvoice
	|				END
	|		ELSE ISNULL(BalanceTable.TaxInvoice, UNDEFINED)
	|	END,
	|	BalanceTable.TaxInvoiceDate,
	|	Balance.Customer,
	|	BalanceTable.Character
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Customer,
	|	CCDNumber,
	|	Count DESC,
	|	Character DESC
	|;
	|
	|//////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ItemsLocationAttributes          AS ItemsLocationAttributes,
	|	Goods.CCDNumber                            AS CCDNumber,
	|	Goods.Package                            AS Package,
	|	Goods.DateOfTaxInvoiceIssuedByCommissionAgent        AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Goods.IssuedTaxInvoiceOfCommissionAgent AS IssuedTaxInvoiceOfCommissionAgent,
	|	Goods.Customer                          AS Customer,
	|	CASE
	|		WHEN Goods.Count < 0
	|			THEN -1
	|		ELSE 1
	|	END                                      AS Character,
	|	SUM(CASE
	|			WHEN Goods.Count < 0
	|				THEN 0 - Goods.Count
	|			ELSE Goods.Count
	|		END)                                 AS Count,
	|	SUM(CASE
	|			WHEN Goods.QuantityByGBRN < 0
	|				THEN -CAST(Goods.QuantityByGBRN AS NUMBER(23, 11))
	|			ELSE CAST(Goods.QuantityByGBRN AS NUMBER(23, 11))
	|		END)                                 AS QuantityByGBRN,
	|	SUM(CASE
	|			WHEN Goods.Count < 0
	|			THEN -Goods.NumberOfPackages
	|			ELSE Goods.NumberOfPackages
	|		END)                                 AS NumberOfPackages,
	|	SUM(CASE
	|			WHEN Goods.Count < 0
	|				THEN -Goods.AmountIncludingVAT
	|			ELSE Goods.AmountIncludingVAT
	|		END)                                 AS AmountIncludingVAT,
	|	SUM(CASE
	|			WHEN Goods.Count < 0
	|				THEN -Goods.CommissionAmount
	|			ELSE Goods.CommissionAmount
	|		END)                                 AS CommissionAmount,
	|	SUM(CASE
	|			WHEN Goods.Count < 0
	|				THEN -Goods.AmountVATRemuneration
	|			ELSE Goods.AmountVATRemuneration
	|		END)                                 AS AmountVATRemuneration,
	|	SUM(CASE
	|			WHEN Goods.Count < 0
	|				THEN -Goods.VATAmount
	|			ELSE Goods.VATAmount
	|		END)                                 AS VATAmount,
	|	Goods.VATRate                           AS VATRate,
	|	Goods.Warehouse                               AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	CASE
	|		WHEN &UseFinAccountingGroups
	|			THEN ISNULL(ProductData_1.FinancialAccountingGroup, VALUE(Catalog.InventoryAccountingGroups.EmptyRef))
	|		ELSE VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|	END                                      AS FinancialAccountingGroup,
	|	ProductData_1.UnitOfMeasure        AS UnitOfMeasure,
	|	Goods.Products                        AS Products,
	|	Goods.Series                               AS Series
	|FROM
	|	TableOfGoods AS Goods
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON Goods.Products = ProductData_1.Ref
	|
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.CCDNumber,
	|	Goods.Package,
	|	Goods.DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Goods.IssuedTaxInvoiceOfCommissionAgent,
	|	Goods.Customer,
	|	Goods.VATRate,
	|	Goods.Warehouse,
	|	Goods.Purpose,
	|	CASE
	|		WHEN &UseFinAccountingGroups
	|			THEN ISNULL(ProductData_1.FinancialAccountingGroup, VALUE(Catalog.InventoryAccountingGroups.EmptyRef))
	|		ELSE VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|	END,
	|	ProductData_1.UnitOfMeasure,
	|	CASE
	|		WHEN Goods.Count < 0
	|			THEN -1
	|		ELSE 1
	|	END,
	|	Goods.Products,
	|	Goods.Series
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	CCDNumber,
	|	DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Customer,
	|	Count DESC,
	|	Character DESC";
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("UseFinAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Result		= Query.ExecuteBatch();
	Balance			= Result[Result.UBound() - 1].Unload();
	SampleProducts_	= Result[Result.UBound()].Select();
	
	While SampleProducts_.Next() Do
		
		Count				= SampleProducts_.Count;
		QuantityByGBRN		= SampleProducts_.QuantityByGBRN;
		NumberOfPackages		= SampleProducts_.NumberOfPackages;
		AmountIncludingVAT				= SampleProducts_.AmountIncludingVAT;
		VATAmount				= SampleProducts_.VATAmount;
		CommissionAmount		= SampleProducts_.CommissionAmount;
		AmountVATRemuneration	= SampleProducts_.AmountVATRemuneration;
		
		TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, Customer, Character,
											|IssuedTaxInvoiceOfCommissionAgent");
		
		FillPropertyValues(TheStructureOfTheSearch, SampleProducts_);
		
		If ValueIsFilled(SampleProducts_.CCDNumber) Then
			TheStructureOfTheSearch.Insert("CCDNumber", SampleProducts_.CCDNumber);
		EndIf;
		
		If Not ValueIsFilled(TheStructureOfTheSearch.IssuedTaxInvoiceOfCommissionAgent) Then
			TheStructureOfTheSearch.IssuedTaxInvoiceOfCommissionAgent = Undefined;
		EndIf;
		
		For Each RemainderLine In Balance.FindRows(TheStructureOfTheSearch) Do
			
			If RemainderLine.Count = 0 Then
				Continue;
			EndIf;
			
			NewRow = TableTypesOfStocks_.Add();
			FillPropertyValues(NewRow, SampleProducts_);
			FillPropertyValues(NewRow, RemainderLine, "InventoryOwnerAttribute, CCDNumber");
			
			If Count <= RemainderLine.Count Then
				
				If AmountIncludingVAT = 0
					Or Not ThisIsASalesReport
					Or AmountIncludingVAT <= RemainderLine.RevenueAmount Then
					
					NewRow.AmountIncludingVAT	= AmountIncludingVAT * SampleProducts_.Character;
					NewRow.VATAmount	= VATAmount * SampleProducts_.Character;
					
				Else
					NewRow.AmountIncludingVAT	= RemainderLine.RevenueAmount * RemainderLine.Character;
					NewRow.VATAmount	= VATAmount * SampleProducts_.Character * RemainderLine.RevenueAmount / AmountIncludingVAT;
				EndIf;
				
				NewRow.Count			= Count * SampleProducts_.Character;
				NewRow.QuantityByGBRN	= ?(RemainderLine.Count <> 0,
													?(RemainderLine.Count - Count = 0,
														RemainderLine.QuantityByGBRN,
														Count * SampleProducts_.Character * RemainderLine.QuantityByGBRN
														/ RemainderLine.Count),
													0);
				NewRow.NumberOfPackages	= NumberOfPackages * SampleProducts_.Character;
				
				If ThisIsASalesReport Then
					NewRow.CommissionAmount		= CommissionAmount * SampleProducts_.Character;
					NewRow.AmountVATRemuneration	= AmountVATRemuneration * SampleProducts_.Character;
				EndIf;
				
				RemainderLine.Count		= RemainderLine.Count - Count;
				RemainderLine.QuantityByGBRN	= RemainderLine.QuantityByGBRN - NewRow.QuantityByGBRN;
				RemainderLine.RevenueAmount		= RemainderLine.RevenueAmount - NewRow.AmountIncludingVAT * RemainderLine.Character;
				
			Else
				
				NewRow.Count			= RemainderLine.Count * RemainderLine.Character;
				NewRow.QuantityByGBRN	= RemainderLine.QuantityByGBRN * RemainderLine.Character;
				NewRow.NumberOfPackages	= Round(NumberOfPackages * RemainderLine.Count / Count, 2, 1)
													* RemainderLine.Character;
				
				If AmountIncludingVAT = 0
					Or Not ThisIsASalesReport
					Or AmountIncludingVAT <= RemainderLine.RevenueAmount Then
					
					NewRow.AmountIncludingVAT	= AmountIncludingVAT * SampleProducts_.Character;
					NewRow.VATAmount	= VATAmount * SampleProducts_.Character;
					
				Else
					NewRow.AmountIncludingVAT	= RemainderLine.RevenueAmount * RemainderLine.Character;
					NewRow.VATAmount	= VATAmount * SampleProducts_.Character * RemainderLine.RevenueAmount / AmountIncludingVAT;
				EndIf;
				
				If ThisIsASalesReport Then
					NewRow.CommissionAmount		= Round(CommissionAmount * RemainderLine.Count / Count,
																2,
																1) * RemainderLine.Character;
					NewRow.AmountVATRemuneration	= Round(AmountVATRemuneration * RemainderLine.Count / Count,
																2,
																1) * RemainderLine.Character;
				EndIf;
				
				RemainderLine.Count		= 0;
				RemainderLine.QuantityByGBRN	= 0;
				RemainderLine.RevenueAmount		= RemainderLine.RevenueAmount - NewRow.AmountIncludingVAT * RemainderLine.Character;
				
			EndIf;
			
			Count			= Count - NewRow.Count * SampleProducts_.Character;
			QuantityByGBRN	= QuantityByGBRN - NewRow.QuantityByGBRN * SampleProducts_.Character;
			NumberOfPackages	= NumberOfPackages - NewRow.NumberOfPackages * SampleProducts_.Character;
			AmountIncludingVAT			= AmountIncludingVAT - NewRow.AmountIncludingVAT * SampleProducts_.Character;
			VATAmount			= VATAmount - NewRow.VATAmount * SampleProducts_.Character;
			
			If ThisIsASalesReport Then
				CommissionAmount		= CommissionAmount - NewRow.CommissionAmount * SampleProducts_.Character;
				AmountVATRemuneration	= AmountVATRemuneration - NewRow.AmountVATRemuneration * SampleProducts_.Character;
			EndIf;
			
			If Count = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
		If Count <> 0 Then // there were not enough leftovers, we generate a type of inventory - our own.
			
			NewRow = TableTypesOfStocks_.Add();
			FillPropertyValues(NewRow, SampleProducts_);
			
			NewRow.Count			= Count * SampleProducts_.Character;
			NewRow.QuantityByGBRN	= QuantityByGBRN * SampleProducts_.Character;
			NewRow.NumberOfPackages	= NumberOfPackages * SampleProducts_.Character;
			NewRow.AmountIncludingVAT			= AmountIncludingVAT * SampleProducts_.Character;
			NewRow.VATAmount			= VATAmount * SampleProducts_.Character;
			
			If ThisIsASalesReport Then
				NewRow.CommissionAmount		= CommissionAmount * SampleProducts_.Character;
				NewRow.AmountVATRemuneration	= AmountVATRemuneration * SampleProducts_.Character;
			EndIf;
			
			If DefaultStockView = Undefined Then
				DefaultStockView = Catalogs.InventoryKinds.DocumentInventoryView(
											DocumentObject.Organization,
											Enums.BusinessTransactions.CommissionReportIntercompany,
											DefaultInventoryViewStructure);
			EndIf;
			
			NewRow.InventoryOwnerAttribute = DefaultStockView;
			
			AdditionalProperties.Insert("InsufficientProductBalances", True);
			
			PostWithoutControlOfCompanyStockBalance = SessionParameters.PostWithoutControlOfCompanyStockBalance;
			
			If ControlCompanyStockBalance 
				Or PostWithoutControlOfCompanyStockBalance Then
				
				NewLineOfErrors = ErrorsTable.Add();
				FillPropertyValues(NewLineOfErrors, SampleProducts_);
				
				NewLineOfErrors.Count		= Count;
				NewLineOfErrors.Sum				= AmountIncludingVAT;
				NewLineOfErrors.UnitOfMeasure	= SampleProducts_.UnitOfMeasure;
				
				If Not RefillInventoryKinds
					Or Not PostWithoutControlOfCompanyStockBalance Then
					Cancel = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ErrorsTable.Count() > 0
		And PostWithoutControlOfCompanyStockBalance Then
		
		MessageText = NStr("vi = 'Đã kết chuyển chứng từ %Ref% có ngắt kiểm soát số dư hàng hóa trong doanh nghiệp.';
							|ru = 'Документ %Ref% проведен с выключенным контролем остатков товаров организаций.';
							|en = 'The %Ref% document is posted with enabled company stock balance control.'; fa = 'The %Ref% document is posted with enabled company stock balance control.';
							|it = 'Documento %Ref% eseguito con il controllo dei beni residui delle aziende disattivato.';
							|pl = 'Dokument %Ref% jest zaksięgowany z wyłączoną kontrolą pozostałości towarów firm.';
							|tr = '%Ref% belgesi, iş yerinin stok kontrolü kapalıyken kaydedildi.'",
								Metadata.DefaultLanguage.LanguageCode);
		MessageText = StrReplace(MessageText, "%Ref%", DocumentObject.Ref);
		
		WriteLogEvent(EventNameResidueControlDisabled(),
								EventLogLevel.Warning,
								,
								DocumentObject.Ref,
								MessageText);
		
	EndIf;
	
	DocumentObject[ParametersForFillingInventoryTypes.NameTSTypesOfStocks].Load(TableTypesOfStocks_);
	
	ReportErrorsInFillingInCommitteeInventoryTypes(DocumentObject, ErrorsTable, ParametersForFillingInventoryTypes);
	
EndProcedure

Procedure SetRegisterLock(DocumentObject, TempTablesManager)
	
	Query = New Query;
	PartsOfQueryText = New Array;
	BlockingByCompany = False;
	If GetFunctionalOption("UseCustomerInvoiceIntercompany") Then	// The intercampany mechanism is used.

		TextOfRequestPart = 
			"SELECT DISTINCT
			|	ResidueSelections.ItemsLocationAttributes AS ItemsLocationAttributes
			|FROM
			|	TTSelectionsOfBusinessBalances AS ResidueSelections";

	ElsIf GetFunctionalOption("UseManagementCompany") Then	// Separate purchase and Sale operations are used for management and Local accounting.

		TextOfRequestPart = 
			"SELECT DISTINCT
			|	&Organization AS Organization,
			|	ResidueSelections.ItemsLocationAttributes AS ItemsLocationAttributes
			|FROM
			|	TTSelectionsOfBusinessBalances AS ResidueSelections
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	VALUE(Catalog.Companies.ManagementCompany),
			|	ResidueSelections.ItemsLocationAttributes
			|FROM
			|	TTSelectionsOfBusinessBalances AS ResidueSelections";
		Query.SetParameter("Organization", DocumentObject.Organization);
		BlockingByCompany = True;

	Else	// Only Register Records can be performed by the registrar's organization

		TextOfRequestPart = 
			"SELECT DISTINCT
			|	&Organization AS Organization,
			|	ResidueSelections.ItemsLocationAttributes AS ItemsLocationAttributes
			|FROM
			|	TTSelectionsOfBusinessBalances AS ResidueSelections";
		Query.SetParameter("Organization", DocumentObject.Organization);
		BlockingByCompany = True;

	EndIf;
	PartsOfQueryText.Add(TextOfRequestPart);
	
	TextOfRequestPart = 
		"SELECT DISTINCT
		|	ResidueSelections.InventoryOwnerAttribute AS InventoryOwnerAttribute
		|FROM
		|	TTSelectionsOfBusinessBalances AS ResidueSelections
		|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON ResidueSelections.InventoryOwnerAttribute = InventoryKinds.Ref
		|WHERE
		|	(InventoryKinds.IsDuplicate
		|			OR InventoryKinds.Obsolete1)";
	PartsOfQueryText.Add(TextOfRequestPart);

	Query.Text = StrConcat(PartsOfQueryText, Common.QueryBatchSeparator());
	
	Query.TempTablesManager = TempTablesManager;
	
	QueryResult = Query.ExecuteBatch();
	RequestResultSelectingBalances = QueryResult[0];
	QueryResultObsoleteInventoryTypes	= QueryResult[1];
	
	ObjectOfMovement = ?(TypeOf(DocumentObject) = Type("DocumentObject.ReversingEntry"),
						DocumentObject.ReversedDocument.GetObject(),
						DocumentObject);
	
	Block = New DataLock;
	
	If ThereIsMovementInCollection(ObjectOfMovement, "CompanyGoods") Then
		
		LockItem = Block.Add("AccumulationRegister.CompanyGoods");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = RequestResultSelectingBalances;
		LockItem.UseFromDataSource("ItemsLocationAttributes", "ItemsLocationAttributes");
		If BlockingByCompany Then
			LockItem.UseFromDataSource("Organization", "Organization");
		EndIf;
		
		If ThereIsMovementInCollection(DocumentObject,"CompanySafeStock") = Undefined Then
			ExceptionText = NStr("vi = 'Lỗi trong mô tả bản ghi kết chuyển của chứng từ: chứng từ là nguồn ghi %Register1% và không phải là nguồn ghi %Register2%.';
								|ru = 'Ошибка в описании движений документа: документ является регистратором %Register1% и не является регистратором %Register2%.';
								|en = 'An error occurred in the document record description: the document is the %Register1% recorder and is not the %Register2% recorder.'; fa = 'An error occurred in the document record description: the document is the %Register1% recorder and is not the %Register2% recorder.';
								|it = 'Errore durante la descrizione del documento di trasferimento: il documento è il registratore %Register1% e non il registratore %Register2%.';
								|pl = 'Błąd w opisie ruchów dokumentu: dokument jest rejestratorem %Register1% i nie jest rejestratorem %Register2%.';
								|tr = 'Belge kayıt açıklamasında hata: Belge bir %Register1% kaydedicisi ve bir %Register2% kaydedicisi değildir.'");
			ExceptionText = StrReplace(ExceptionText, "%Register2%", "CompanySafeStock");
			ExceptionText = StrReplace(ExceptionText, "%Register1%", "CompanyGoods");
			
			Raise ExceptionText;
		EndIf;
		
		LockItem = Block.Add("AccumulationRegister.CompanySafeStock");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = RequestResultSelectingBalances;
		LockItem.UseFromDataSource("ItemsLocationAttributes", "ItemsLocationAttributes");
		If BlockingByCompany Then
			LockItem.UseFromDataSource("Organization", "Organization");
		EndIf;
		
		If Not QueryResultObsoleteInventoryTypes.IsEmpty() Then
			LockItem = Block.Add("InformationRegister.ObsoleteInventoryOwnerAttributesWithBalance");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.DataSource = QueryResultObsoleteInventoryTypes;
			LockItem.UseFromDataSource("InventoryOwnerAttribute", "InventoryOwnerAttribute");
		EndIf;
		
	EndIf;

	If ThereIsMovementInCollection(ObjectOfMovement, "GoodsToBeRegisteredInReportsToConsignor") Then
		
		LockItem = Block.Add("AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = RequestResultSelectingBalances;
		LockItem.UseFromDataSource("ItemsLocationAttributes", "ItemsLocationAttributes");
		
	EndIf;
	

	If ThereIsMovementInCollection(ObjectOfMovement, "GoodsTransferredToCommissionAgent") Then
		
		RequestForCommission = New Query;
		RequestForCommission.Text =
		"SELECT DISTINCT
		|	ResidueSelections.ItemsLocationAttributes AS ItemsLocationAttributes
		|FROM
		|	TTSelectionsOfBusinessBalances AS ResidueSelections
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	CommissionAgentAnalytics.DimensionKey AS ItemsLocationAttributes
		|FROM
		|	TTSelectionsOfBusinessBalances AS ResidueSelections
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
		|		ON Keys.Ref = ResidueSelections.ItemsLocationAttributes
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS CommissionAgentAnalytics
		|		ON CommissionAgentAnalytics.Products = Keys.Products
		|			AND CommissionAgentAnalytics.Characteristic = Keys.Characteristic
		|			AND CommissionAgentAnalytics.Series = Keys.Series
		|			AND CommissionAgentAnalytics.StorageLocation = &Partner
		|			AND CommissionAgentAnalytics.Purpose = Keys.Purpose
		|			AND CommissionAgentAnalytics.ProductCostElement = Keys.ProductCostElement
		|";
		
		RequestForCommission.TempTablesManager = TempTablesManager;
		
		If TypeOf(ObjectOfMovement) = Type("DocumentObject.CommissionReportIntercompany") Then
			RequestForCommission.SetParameter("Partner", ObjectOfMovement.Consignee);
		Else
			RequestForCommission.SetParameter("Partner", ObjectOfMovement.Partner);
		EndIf;
		
		CommissionRequestResult = RequestForCommission.Execute();
		
		LockItem = Block.Add("AccumulationRegister.GoodsTransferredToCommissionAgent");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = CommissionRequestResult;
		LockItem.UseFromDataSource("ItemsLocationAttributes", "ItemsLocationAttributes");
		
	EndIf;
	
	Block.Lock();
	
EndProcedure

Procedure FillTypesOfStocksOfDifferentPeriods(DocumentObject, TempTablesManager, Cancel, ParametersForFillingInventoryTypes)
	
	RequestDestructionOfTables = New Query;
	RequestDestructionOfTables.TempTablesManager = TempTablesManager;
	RequestDestructionOfTables.Text = "
	|///////////////////////////////////////////////////////////////////////////////
	|DROP TTSelectedStockTypes
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP TTNewReserves
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP BalanceTable
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP TableOfGoods
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP TableTypesOfStocks_
	|;
	|";
	
	If ParametersForFillingInventoryTypes.TableTypesOfStocks_.Columns.Find("Period") = Undefined Then
		ParametersForFillingInventoryTypes.TableTypesOfStocks_.Columns.Add("Period", New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime)));
	EndIf;
	
	RequestForDifferentPeriods = RequestForDifferentPeriods(TempTablesManager, ParametersForFillingInventoryTypes);
	
	ResultsForDifferentPeriods = RequestForDifferentPeriods.Execute();
	
	If ResultsForDifferentPeriods.IsEmpty() Then
		ParametersForFillingInventoryTypes.NumberOfPeriodsWhenFormingReservesOfOrganizations = 0;
		
		Return;
	EndIf;
	
	Selection = ResultsForDifferentPeriods.Select();
	
	BalanceDates = ResultsForDifferentPeriods.Unload().UnloadColumn("Period");
	
	If Not ParametersForFillingInventoryTypes.TableOfBalancesHasAlreadyBeenFormed Then
		MinimumBalanceDate = ParametersForFillingInventoryTypes.FillingPeriod;
		
		TableOfOrganizationsProductBalances(DocumentObject,
											TempTablesManager,
											ParametersForFillingInventoryTypes,
											True,
											MinimumBalanceDate,
											BalanceDates);
	EndIf;
	
	TableTypesOfStocks_ = ParametersForFillingInventoryTypes.TableTypesOfStocks_.CopyColumns();
	
	TableNewReserves = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	ParametersForFillingInventoryTypes.TableNewReserves = TableNewReserves.CopyColumns();
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = 
	"SELECT
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	InventoryKinds.Period AS Period,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.Count AS Count,
	|	CAST(InventoryKinds.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN
	|INTO TTSelectedStockTypes
	|FROM
	|	&TableTypesOfStocks_ AS InventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NewReserves.CCDNumber AS CCDNumber,
	|	NewReserves.Organization AS Organization,
	|	ENDOFPERIOD(NewReserves.Period, MONTH) AS Period,
	|	CASE
	|		WHEN NewReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN NewReserves.Count
	|		ELSE -NewReserves.Count
	|	END AS Count,
	|	CASE
	|		WHEN NewReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CAST(NewReserves.QuantityByGBRN AS NUMBER(23, 11))
	|		ELSE -CAST(NewReserves.QuantityByGBRN AS NUMBER(23, 11))
	|	END AS QuantityByGBRN
	|INTO TTNewReserves
	|FROM
	|	&TableNewReserves AS NewReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodBalances.Organization AS Organization,
	|	PeriodBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	PeriodBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	PeriodBalances.CCDNumber AS CCDNumber,
	|	SUM(PeriodBalances.Count) AS CountBalance,
	|	SUM(PeriodBalances.QuantityByGBRN) AS QuantityByGBRNBalance,
	|	MAX(PeriodBalances.DateOfReceipt) AS DateOfReceipt,
	|	CAST(PeriodBalances.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products AS Products,
	|	CAST(PeriodBalances.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Characteristic AS Characteristic,
	|	CAST(PeriodBalances.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Series AS Series,
	|	CAST(PeriodBalances.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Purpose AS Purpose,
	|	CAST(PeriodBalances.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).StorageLocation AS Warehouse,
	|	0 AS SumBalance,
	|	UNDEFINED AS DocumentTransfers_,
	|	UNDEFINED AS ItemsLocationAttributesShipment,
	|	UNDEFINED AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		TableOfBalancesByPeriod.Organization AS Organization,
	|		TableOfBalancesByPeriod.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfBalancesByPeriod.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		TableOfBalancesByPeriod.CCDNumber AS CCDNumber,
	|		TableOfBalancesByPeriod.CountBalance AS Count,
	|		CAST(TableOfBalancesByPeriod.QuantityByGBRNBalance AS NUMBER(23, 11)) AS QuantityByGBRN,
	|		TableOfBalancesByPeriod.DateOfReceipt AS DateOfReceipt
	|	FROM
	|		TableOfBalancesByPeriod AS TableOfBalancesByPeriod
	|	WHERE
	|		TableOfBalancesByPeriod.Period = &CurrentPeriod
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTSelectedStockTypes.InventoryOwnerAttribute.Organization,
	|		TTSelectedStockTypes.ItemsLocationAttributes,
	|		TTSelectedStockTypes.InventoryOwnerAttribute,
	|		TTSelectedStockTypes.CCDNumber,
	|		-TTSelectedStockTypes.Count,
	|		-CAST(TTSelectedStockTypes.QuantityByGBRN AS NUMBER(23, 11)),
	|		DATETIME(1,1,1)
	|	FROM
	|		TTSelectedStockTypes AS TTSelectedStockTypes
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTNewReserves.Organization,
	|		TTNewReserves.ItemsLocationAttributes,
	|		TTNewReserves.InventoryOwnerAttribute,
	|		TTNewReserves.CCDNumber,
	|		TTNewReserves.Count,
	|		CAST(TTNewReserves.QuantityByGBRN AS NUMBER(23, 11)),
	|		DATETIME(1,1,1)
	|	FROM
	|		TTNewReserves AS TTNewReserves
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTSelectedStockTypes.InventoryOwnerAttribute.Organization,
	|		TTSelectedStockTypes.CorItemsLocationAttributes,
	|		TTSelectedStockTypes.InventoryOwnerAttribute,
	|		TTSelectedStockTypes.CCDNumber,
	|		TTSelectedStockTypes.Count,
	|		CAST(TTSelectedStockTypes.QuantityByGBRN AS NUMBER(23, 11)),
	|		TTSelectedStockTypes.Period
	|	FROM
	|		TTSelectedStockTypes AS TTSelectedStockTypes
	|	WHERE
	|		TTSelectedStockTypes.CorItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)) AS PeriodBalances
	|
	|GROUP BY
	|	PeriodBalances.Organization,
	|	PeriodBalances.ItemsLocationAttributes,
	|	PeriodBalances.InventoryOwnerAttribute,
	|	PeriodBalances.CCDNumber
	|
	|HAVING
	|	SUM(PeriodBalances.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.InternalSubcontracting AS InternalSubcontracting,
	|	TableOfGoods.MaterialProviderCompany    AS MaterialProviderCompany,
	|	TableOfGoods.ItemsLocationAttributes.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	TableOfGoods.ItemsLocationAttributes.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes.Series AS Series,
	|	0 AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TableOfGoods.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN &FillingByBalances
	|			THEN TableOfGoods.QuantityByBalance
	|		ELSE TableOfGoods.CurPeriodQuantity
	|	END AS Count,
	|	CASE
	|		WHEN &FillingByBalances
	|			THEN CAST(TableOfGoods.QuantityByRNPTByBalance AS NUMBER(23, 11))
	|		ELSE CAST(TableOfGoods.QuantityByRPTForCurPeriod AS NUMBER(23, 11))
	|	END AS QuantityByGBRN,
	|	TableOfGoods.Period AS DateOfShipment,
	|	TableOfGoods.Period AS DateOfReceipt,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS SalesOpportunity,
	|	UNDEFINED AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.Period AS Period
	|INTO TableOfGoods
	|FROM
	|	TableOfProductsByPeriod AS TableOfGoods
	|WHERE
	|	ENDOFPERIOD(TableOfGoods.Period, MONTH) = &CurrentPeriod
	|	AND CASE
	|			WHEN &FillingByBalances
	|				THEN TableOfGoods.QuantityByBalance
	|			ELSE TableOfGoods.CurPeriodQuantity
	|		END > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS Series,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CAST(TableTypesOfStocks_.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	UNDEFINED AS SalesOpportunity,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
	|	TableTypesOfStocks_.Period AS DateOfShipment,
	|	FALSE AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TableTypesOfStocksByPeriod AS TableTypesOfStocks_
	|WHERE
	|	ENDOFPERIOD(TableTypesOfStocks_.Period, MONTH) = &CurrentPeriod";
	
	Selection.Reset();
	While Selection.Next() Do
		
		Query.SetParameter("TableTypesOfStocks_",		TableTypesOfStocks_);
		Query.SetParameter("TableNewReserves",	TableNewReserves);
		Query.SetParameter("CurrentPeriod",			Selection.Period);
		Query.SetParameter("FillingByBalances",	True);
		
		Results = Query.ExecuteBatch();
		
		If Results[3].Unload()[0].Count = 0 Then
			RequestDestructionOfTables.Execute();
			
			Continue;
		EndIf;
		
		ParametersForFillingInventoryTypes.TableTypesOfStocks_.Clear();
		ParametersForFillingInventoryTypes.TableNewReserves.Clear();
		
		FillInTypesOfReservesAccordingToTableOfBalancesFormTTNewReserves(DocumentObject,
																		TempTablesManager,
																		Cancel,
																		ParametersForFillingInventoryTypes);
		
		RequestDestructionOfTables.Execute();
		
		If Cancel Then
			Return;
		EndIf;
		
		ParametersForFillingInventoryTypes.TableTypesOfStocks_.FillValues(Selection.Period, "Period");
		ParametersForFillingInventoryTypes.TableNewReserves.FillValues(Selection.Period, "Period");
		
		CommonClientServer.SupplementTable(ParametersForFillingInventoryTypes.TableTypesOfStocks_, TableTypesOfStocks_);
		CommonClientServer.SupplementTable(ParametersForFillingInventoryTypes.TableNewReserves, TableNewReserves);
		
		Query.SetParameter("TableTypesOfStocks_",		TableTypesOfStocks_);
		Query.SetParameter("TableNewReserves",	TableNewReserves);
		Query.SetParameter("CurrentPeriod",			Selection.Period);
		Query.SetParameter("FillingByBalances",	False);
		Results = Query.ExecuteBatch();
		
		If Results[3].Unload()[0].Count = 0 Then
			RequestDestructionOfTables.Execute();
			
			Continue;
		EndIf;
		
		ParametersForFillingInventoryTypes.TableTypesOfStocks_.Clear();
		ParametersForFillingInventoryTypes.TableNewReserves.Clear();
		
		FillInTypesOfReservesAccordingToTableOfBalancesFormTTNewReserves(DocumentObject,
																		TempTablesManager,
																		Cancel,
																		ParametersForFillingInventoryTypes);
		
		RequestDestructionOfTables.Execute();
		
		If Cancel Then
			Return;
		EndIf;
		
		ParametersForFillingInventoryTypes.TableTypesOfStocks_.FillValues(Selection.Period, "Period");
		ParametersForFillingInventoryTypes.TableNewReserves.FillValues(Selection.Period, "Period");
		
		CommonClientServer.SupplementTable(ParametersForFillingInventoryTypes.TableTypesOfStocks_, TableTypesOfStocks_);
		CommonClientServer.SupplementTable(ParametersForFillingInventoryTypes.TableNewReserves, TableNewReserves);
		
	EndDo;
	
	Query.Text =
	"SELECT
	|	TableNewReserves.RecordType AS RecordType,
	|	TableNewReserves.Period AS Period,
	|	TableNewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableNewReserves.Organization AS Organization,
	|	TableNewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableNewReserves.CCDNumber AS CCDNumber,
	|	TableNewReserves.Count AS Count,
	|	CAST(TableNewReserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	TableNewReserves.CorCompany AS CorCompany,
	|	TableNewReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO TTNewReserves
	|FROM
	|	&TableNewReserves AS TableNewReserves";
	
	Query.SetParameter("TableNewReserves", TableNewReserves);
	
	Query.Execute();
	
	ParametersForFillingInventoryTypes.TableTypesOfStocks_ = TableTypesOfStocks_;
	
EndProcedure

Function RequestForDifferentPeriods(TempTablesManager, Val ParametersForFillingInventoryTypes)
	
	RequestPeriods = New Query;
	RequestPeriods.TempTablesManager = TempTablesManager;
	If TempTablesManager.Tables.Find("TTFillingPeriods") = Undefined Then
		
		RequestPeriods.Text = 
		"SELECT DISTINCT
		|	NestedQuery.Period AS Period
		|INTO TTFillingPeriods
		|FROM
		|	TextNestedRequest AS NestedQuery
		|WHERE
		|	NestedQuery.Period >= &FillingPeriod";
		
		If TempTablesManager.Tables.Find("TableOfProductsByPeriod") <> Undefined Then
			
			TextNestedRequest =
			"SELECT
			|	ENDOFPERIOD(TableOfProductsByPeriod.Period, MONTH) AS Period
			|FROM
			|	TableOfProductsByPeriod AS TableOfProductsByPeriod";
			
		Else
			
			TextNestedRequest =
			"SELECT
			|	ENDOFPERIOD(GoodsOfOrganizationsAndReservesChanges.Period, MONTH) AS Period
			|FROM
			|	TTProductsAndChanges AS GoodsOfOrganizationsAndReservesChanges";
			
		EndIf;
		
		RequestPeriods.Text = StrReplace(RequestPeriods.Text, "TextNestedRequest", "(" + TextNestedRequest + ")");
		
		RequestPeriods.Text = RequestPeriods.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	RequestPeriods.Text = RequestPeriods.Text +
	"SELECT
	|	TTFillingPeriods.Period AS Period
	|FROM
	|	TTFillingPeriods AS TTFillingPeriods
	|
	|ORDER BY
	|	TTFillingPeriods.Period";
	
	RequestPeriods.SetParameter("FillingPeriod", ParametersForFillingInventoryTypes.FillingPeriod);
	
	Return RequestPeriods;
	
EndFunction

// This method fills in the "inventory Types" tabular part of the document.
//
// Parameters:
//	DocumentObject - DocumentObject - The document, which are filled with stock types.
//	TempTablesManager - TempTablesManager - temporary tables are required:
//		Tables of products, tables of Document data, tables of inventory views, tables of statistics.
//	Cancel - Boolean - indicates that the document was not recorded.
//	ParametersForFillingInventoryTypes - See ParametersForFillingInventoryTypes.
//
Procedure FillTypesOfStocksOnTableOfBalances(DocumentObject,
												TempTablesManager,
												Cancel,
												ParametersForFillingInventoryTypes)
	
	ErrorsTable			= TableOfErrorsInFillingInventoryTypes();
	AdditionalProperties	= DocumentObject.AdditionalProperties;
	
	If ParametersForFillingInventoryTypes.TableTypesOfStocks_ <> Undefined Then
		TableTypesOfStocks_ = ParametersForFillingInventoryTypes.TableTypesOfStocks_;
	Else
		TableTypesOfStocks_ = DocumentObject[ParametersForFillingInventoryTypes.NameTSTypesOfStocks].UnloadColumns();
	EndIf;
	
	ControlChangeOfCCDNumbers = AdditionalProperties.Property("ControlChangeOfCCDNumbers");
	
	If ControlChangeOfCCDNumbers Then
		TableOfCCDNumbers = TableTypesOfStocks_.Copy(, "ItemsLocationAttributes, CCDNumber, Count"); // ValueTable
	EndIf;
	
	Query = RequestDistributionWithoutTakingIntoAccountPrioritiesOfTableOfGoodsOnTableOfBalances(TempTablesManager,
																					AdditionalProperties,
																					ParametersForFillingInventoryTypes);
	
	Organization			= DocumentObject[ParametersForFillingInventoryTypes.CompanyFieldName1];
	RegistrationCountry	= SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	
	If ValueIsFilled(ParametersForFillingInventoryTypes.ExciseAccrualPeriod) Then
		Date = ParametersForFillingInventoryTypes.ExciseAccrualPeriod;
	Else
		Date = DocumentObject.Date;
	EndIf;
	
	Query.SetParameter("Date",	Date);
	Query.SetParameter("Country",	RegistrationCountry);
	
	ResultsArray = Query.ExecuteBatch();
	FetchingDocumentData	= ResultsArray[2].Select();
	SelectionTableOfProducts	= ResultsArray[3].Select();
	
	FetchingDocumentData.Next();
	Organization = FetchingDocumentData.Organization;
	BusinessOperation = FetchingDocumentData.BusinessOperation;
	
	StringDataStructure = New Structure("
		|ItemsLocationAttributesShipment,
		|Count,
		|QuantityByGBRN,
		|AmountIncludingVAT,
		|VATRate,
		|VATAmount,
		|CommissionAmount,
		|AmountVATRemuneration,
		|ExciseTaxAmount,
		|InsufficientProductBalances,
		|InventoryOwnerAttributeShipment,
		|CorInventoryOwnerAttribute");
	
	DefaultInventoryViewStructure = New Structure("
		|FinancialAccountingGroup,
		|PriceKind,
		|GoodsOwner,
		|Counterparty,
		|Terms,
		|Contract,
		|Currency,
		|VATTaxation,
		|InventoryType,
		|SubjectToExcise,
		|BusinessUnitProduction,
		|TaxationOfOrganization");
	
	LeftoverSearchKey =
		"InventoryOwnerAttribute,
		|ItemsLocationAttributesShipment,
		|CCDNumber,
		|RecipientInventoryOwnerAttribute,
		|InventoryOwnerAttributeShipment,
		|CorInventoryOwnerAttribute,
		|DocumentSalesOfGoodsAndServices,
		|DocumentLoggingIn";
	
	DefaultInventoryViewStructure.FinancialAccountingGroup		= Catalogs.InventoryAccountingGroups.EmptyRef();
	DefaultInventoryViewStructure.PriceKind						= Catalogs.VendorPriceTypes.EmptyRef();
	DefaultInventoryViewStructure.GoodsOwner				= FetchingDocumentData.Partner;
	DefaultInventoryViewStructure.Counterparty					= FetchingDocumentData.Counterparty;
	DefaultInventoryViewStructure.Terms					= FetchingDocumentData.Terms;
	DefaultInventoryViewStructure.Contract						= FetchingDocumentData.Contract;
	DefaultInventoryViewStructure.Currency						= FetchingDocumentData.Currency;
	DefaultInventoryViewStructure.VATTaxation			= FetchingDocumentData.VATTaxation;
	DefaultInventoryViewStructure.TaxationOfOrganization	= FetchingDocumentData.VATTaxation;
	DefaultInventoryViewStructure.InventoryType					= FetchingDocumentData.InventoryType;
	DefaultInventoryViewStructure.SubjectToExcise			= False;
	DefaultInventoryViewStructure.BusinessUnitProduction	= FetchingDocumentData.BusinessUnitProduction;
	QueryResult		= ResultsArray[ResultsArray.UBound() - 2];
	SelectingDataByLine	= QueryResult.Select(QueryResultIteration.ByGroups); // QueryResult
	
	WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault(
																		ParametersForFillingInventoryTypes);
	IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited =
		Not WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault
		And ParametersForFillingInventoryTypes.IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited;
	InventoryOwnerAttributeIsInitializedByDefault = InventoryOwnerAttributeIsInitializedByDefault(
																ParametersForFillingInventoryTypes);
	
	DefaultStockView			= Undefined;
	TypesOfStockToReturn			= New Map;
	InventoryKindsByTransferSettings = New Map;
	DefaultStockTypes			= New Map;
	
	Query.Text = 
	"SELECT
	|	GroupedBalanceTable.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	GroupedBalanceTable.Series					AS Series,
	|	GroupedBalanceTable.InventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	GroupedBalanceTable.RecipientInventoryOwnerAttribute		AS RecipientInventoryOwnerAttribute,
	|	GroupedBalanceTable.InventoryOwnerAttributeShipment		AS InventoryOwnerAttributeShipment,
	|	GroupedBalanceTable.CorInventoryOwnerAttribute			AS CorInventoryOwnerAttribute,
	|	GroupedBalanceTable.CCDNumber					AS CCDNumber,
	|	GroupedBalanceTable.DocumentSalesOfGoodsAndServices		AS DocumentSalesOfGoodsAndServices,
	|	GroupedBalanceTable.DocumentLoggingIn	AS DocumentLoggingIn,
	|	SUM(GroupedBalanceTable.CountBalance)	AS CountBalance
	|FROM
	|	(SELECT
	|		ISNULL(DimensionShipments.DimensionKey, BalanceTable.ItemsLocationAttributes) AS ItemsLocationAttributesShipment,
	|		CASE
	|			WHEN DimensionShipments.DimensionKey IS NULL
	|				THEN BalanceTable.Series
	|			ELSE DimensionShipments.Series
	|		END										AS Series,
	|		BalanceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		BalanceTable.RecipientInventoryOwnerAttribute		AS RecipientInventoryOwnerAttribute,
	|		BalanceTable.InventoryOwnerAttributeShipment			AS InventoryOwnerAttributeShipment,
	|		BalanceTable.CorInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|		BalanceTable.CCDNumber					AS CCDNumber,
	|		BalanceTable.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|		BalanceTable.DocumentLoggingIn		AS DocumentLoggingIn,
	|		SUM(BalanceTable.CountBalance)	AS CountBalance
	|	FROM
	|		TTBalance AS BalanceTable
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionShipments
	|			ON BalanceTable.Products = DimensionShipments.Products
	|				AND BalanceTable.Characteristic = DimensionShipments.Characteristic
	|				AND BalanceTable.ShipmentBatch = DimensionShipments.Series
	|				AND BalanceTable.OriginWarehouse = DimensionShipments.StorageLocation
	|				AND BalanceTable.PurposeOfShipment = DimensionShipments.Purpose
	|				AND BalanceTable.ProductCostElement = DimensionShipments.ProductCostElement
	|	
	|	WHERE
	|		BalanceTable.DocumentRemnants
	|	
	|	GROUP BY
	|		ISNULL(DimensionShipments.DimensionKey, BalanceTable.ItemsLocationAttributes),
	|		CASE
	|			WHEN DimensionShipments.DimensionKey IS NULL
	|				THEN BalanceTable.Series
	|			ELSE DimensionShipments.Series
	|		END,
	|		BalanceTable.InventoryOwnerAttribute,
	|		BalanceTable.RecipientInventoryOwnerAttribute,
	|		BalanceTable.InventoryOwnerAttributeShipment,
	|		BalanceTable.CorInventoryOwnerAttribute,
	|		BalanceTable.CCDNumber,
	|		BalanceTable.DocumentSalesOfGoodsAndServices,
	|		BalanceTable.DocumentLoggingIn
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ISNULL(DimensionShipments.DimensionKey, BalanceTable.ItemsLocationAttributes) AS ItemsLocationAttributesShipment,
	|		CASE
	|			WHEN DimensionShipments.DimensionKey IS NULL
	|				THEN BalanceTable.Series
	|			ELSE DimensionShipments.Series
	|		END										AS Series,
	|		BalanceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		BalanceTable.RecipientInventoryOwnerAttribute		AS RecipientInventoryOwnerAttribute,
	|		BalanceTable.InventoryOwnerAttributeShipment			AS InventoryOwnerAttributeShipment,
	|		BalanceTable.CorInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|		BalanceTable.CCDNumber					AS CCDNumber,
	|		BalanceTable.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|		BalanceTable.DocumentLoggingIn		AS DocumentLoggingIn,
	|		MAX(BalanceTable.CountBalance)	AS CountBalance
	|	FROM
	|		TTBalance AS BalanceTable
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionShipments
	|			ON BalanceTable.Products = DimensionShipments.Products
	|				AND BalanceTable.Characteristic = DimensionShipments.Characteristic
	|				AND BalanceTable.ShipmentBatch = DimensionShipments.Series
	|				AND BalanceTable.OriginWarehouse = DimensionShipments.StorageLocation
	|				AND BalanceTable.PurposeOfShipment = DimensionShipments.Purpose
	|				AND BalanceTable.ProductCostElement = DimensionShipments.ProductCostElement
	|	
	|	WHERE
	|		NOT BalanceTable.DocumentRemnants
	|	
	|	GROUP BY
	|		ISNULL(DimensionShipments.DimensionKey, BalanceTable.ItemsLocationAttributes),
	|		CASE
	|			WHEN DimensionShipments.DimensionKey IS NULL
	|				THEN BalanceTable.Series
	|			ELSE DimensionShipments.Series
	|		END,
	|		BalanceTable.InventoryOwnerAttribute,
	|		BalanceTable.RecipientInventoryOwnerAttribute,
	|		BalanceTable.InventoryOwnerAttributeShipment,
	|		BalanceTable.CorInventoryOwnerAttribute,
	|		BalanceTable.CCDNumber,
	|		BalanceTable.DocumentSalesOfGoodsAndServices,
	|		BalanceTable.DocumentLoggingIn
	|	
	|	) AS GroupedBalanceTable
	|
	|GROUP BY
	|	GroupedBalanceTable.ItemsLocationAttributesShipment,
	|	GroupedBalanceTable.Series,
	|	GroupedBalanceTable.InventoryOwnerAttribute,
	|	GroupedBalanceTable.RecipientInventoryOwnerAttribute,
	|	GroupedBalanceTable.InventoryOwnerAttributeShipment,
	|	GroupedBalanceTable.CorInventoryOwnerAttribute,
	|	GroupedBalanceTable.CCDNumber,
	|	GroupedBalanceTable.DocumentSalesOfGoodsAndServices,
	|	GroupedBalanceTable.DocumentLoggingIn
	|";
	
	BalanceTable = Query.Execute().Unload();
	BalanceTable.Indexes.Add(LeftoverSearchKey);
	
	TableOfBalancesByRow = Undefined;
	
	PostWithoutControlOfCompanyStockBalance = SessionParameters.PostWithoutControlOfCompanyStockBalance
														Or Not Constants.ControlCompanyStockBalance.Get();
	
	AllowRetroactiveReleaseRegistration = UserRightsCached.AllowRetroactiveReleaseRegistration();
	
	SubjectToExcise = ParametersForFillingInventoryTypes.SelectionOfStockTypes_.SubjectToExcise;
	OnlyNonExciseItems = ValueIsFilled(SubjectToExcise);
	
	ParametersForFillingInInventoryOwnerAttributesManually = ?(AdditionalProperties.Property("ParametersForFillingInInventoryOwnerAttributesManually"),
												AdditionalProperties.ParametersForFillingInInventoryOwnerAttributesManually,
												ParametersForFillingInInventoryOwnerAttributesManually());
	
	While SelectingDataByLine.Next() Do
		
		ProductQuantity_				= SelectingDataByLine.Count;
		QuantityOfGoodsAccordingToRNPT			= SelectingDataByLine.QuantityByGBRN;
		ProductAmountWithVAT					= SelectingDataByLine.AmountIncludingVAT;
		ProductVATAmount					= SelectingDataByLine.VATAmount;
		TotalRemunerationAmount		= SelectingDataByLine.CommissionAmount;
		AmountOfVATRemunerationTotal		= SelectingDataByLine.AmountVATRemuneration;
		
		ThereIsQuantityOfRNPT = QuantityOfGoodsAccordingToRNPT <> 0;
		
		// Detail record
		Selection = SelectingDataByLine.Select();
		
		While Selection.Next() Do
			
			DefaultInventoryViewStructure.FinancialAccountingGroup = Selection.FinancialAccountingGroup;
			
			InventoryOwnerAttributeShipment = Undefined;
			
			If ValueIsFilled(Selection.InventoryOwnerAttribute) Then
				
				InventoryOwnerAttribute = Selection.InventoryOwnerAttribute;
				InventoryOwnerAttributeShipment = ?(ValueIsFilled(Selection.InventoryOwnerAttributeShipment),
										Selection.InventoryOwnerAttributeShipment,
										Selection.InventoryOwnerAttribute);
				
			ElsIf ValueIsFilled(Selection.InventoryOwnerAttributeShipment) Then
				
				If Selection.ShippingInventoryToAnotherOrganization Then
					InventoryOwnerAttributeShipment = Selection.InventoryOwnerAttributeShipment;
				Else
					
					InventoryOwnerAttributeShipment = InventoryKindsByTransferSettings.Get(Selection.InventoryOwnerAttributeShipment);
					
					If InventoryOwnerAttributeShipment = Undefined Then
						InventoryOwnerAttributeShipment = Catalogs.InventoryKinds.TypeOfInventoryToTransferBetweenOrganizations(
												Selection.InventoryOwnerAttributeShipment,
												Organization,
												FetchingDocumentData.VATTaxation);
						
						InventoryKindsByTransferSettings.Insert(Selection.InventoryOwnerAttributeShipment, InventoryOwnerAttributeShipment);
					EndIf;
					
				EndIf;
				
				InventoryOwnerAttribute = TypesOfStockToReturn.Get(InventoryOwnerAttributeShipment);
				
				If InventoryOwnerAttribute = Undefined Then
					InventoryOwnerAttribute = Catalogs.InventoryKinds.TypeOfStockToReturnGoodsFromCustomer(InventoryOwnerAttributeShipment,
																								Organization);
					
					TypesOfStockToReturn.Insert(InventoryOwnerAttributeShipment, InventoryOwnerAttribute);
				EndIf;
				
			Else
				InventoryOwnerAttribute = Catalogs.InventoryKinds.EmptyRef();
			EndIf;
			
			CorInventoryOwnerAttribute = Catalogs.InventoryKinds.EmptyRef();
			If ValueIsFilled(Selection.CorInventoryOwnerAttribute) Then
				CorInventoryOwnerAttribute = Selection.CorInventoryOwnerAttribute;
			EndIf;
			
			CountBalance				= Selection.CountBalance;
			QuantityBalanceTotal			= Selection.QuantityBalanceTotal;
			QuantityByRNPTBalanceTotal	= Selection.QuantityByRNPTBalanceTotal;
			SumBalance					= Selection.SumBalance;
			ExciseTaxAmountBalance				= Selection.ExciseTaxAmountBalance;
			NotCCDNumberIsSpecified				= False;
			TracedGoods				= False;
			
			FilterLeftovers = New Structure(LeftoverSearchKey);
			FillPropertyValues(FilterLeftovers, Selection);
			
			For Each KeyAndValue In FilterLeftovers Do
				If Not ValueIsFilled(KeyAndValue.Value) Then
					FilterLeftovers[KeyAndValue.Key] =
						BalanceTable.Columns[KeyAndValue.Key].ValueType.AdjustValue(KeyAndValue.Value);
				EndIf;
			EndDo;
			
			RemainderLines_			= BalanceTable.FindRows(FilterLeftovers);
			CurrentBalanceLine	= Undefined;
			
			If RemainderLines_.Count() > 0 Then
				For Each RemainderLine_ In RemainderLines_ Do
					If (CountBalance > 0
							And RemainderLine_.CountBalance > 0)
						Or (CountBalance < 0
							And RemainderLine_.CountBalance < 0) Then
						
						If CountBalance > 0 Then
							CountBalance = Min(RemainderLine_.CountBalance, CountBalance);
						Else
							CountBalance = Max(RemainderLine_.CountBalance, CountBalance);
						EndIf;
						
						If Not ValueIsFilled(Selection.Series)
							And Selection.Series <> RemainderLine_.Series Then
							
							CurrentBalanceLine = RemainderLine_;
							
							If TableOfBalancesByRow = Undefined Then
								TableOfBalancesByRow = TMCommonUse.TreeData(
									QueryResult.Unload(QueryResultIteration.ByGroups), 1);
								TableOfBalancesByRow.Indexes.Add(LeftoverSearchKey);
							EndIf;
							
							ProductLines_2 = TableOfBalancesByRow.FindRows(FilterLeftovers);
							
							If ProductLines_2.Count() > 1 Then
								RowToDelete = Undefined;
								
								For Each GoodsBalanceLine In ProductLines_2 Do
									
									If Selection.LineNumber = GoodsBalanceLine.LineNumber Then
										If Selection.ItemsLocationAttributesShipment = GoodsBalanceLine.ItemsLocationAttributesShipment Then
											RowToDelete = GoodsBalanceLine;
										EndIf;
										
										Continue;
									EndIf;
									
									If (CountBalance > 0
											And GoodsBalanceLine.CountBalance <= 0)
										Or (CountBalance < 0
											And GoodsBalanceLine.CountBalance >= 0) Then
										
										Continue;
										
									EndIf;
									
									If RemainderLine_.Series = GoodsBalanceLine.Series Then
										LineBalance = RemainderLine_.CountBalance - Selection.CountBalance;
										
										If (CountBalance > 0
												And LineBalance < GoodsBalanceLine.CountBalance)
											Or (CountBalance < 0
												And LineBalance > GoodsBalanceLine.CountBalance) Then
											
											CurrentBalanceLine = Undefined;
											
											Break;
											
										EndIf;
										
									EndIf;
								EndDo;
								
								If RowToDelete <> Undefined Then
									TableOfBalancesByRow.Delete(RowToDelete)
								EndIf;
							EndIf;
							
						Else
							CurrentBalanceLine = RemainderLine_;
							
							Break;
						EndIf;
						
					EndIf;
				EndDo;
				
				If CurrentBalanceLine = Undefined Then
					CountBalance = 0;
				EndIf;
			
			EndIf;
			
			If Selection.NotCCDNumberIsSpecified Then
				
				CountBalance				= 0;
				QuantityBalanceTotal			= 0;
				QuantityByRNPTBalanceTotal	= 0;
				SumBalance					= 0;
				ExciseTaxAmountBalance				= 0;
				NotCCDNumberIsSpecified				= Selection.NotCCDNumberIsSpecified;
				TracedGoods				= Selection.TracedGoods;
				
			ElsIf (ProductQuantity_ > 0
					And CountBalance > 0)
				Or (ProductQuantity_ < 0
					And CountBalance < 0)
				Or (ParametersForFillingInventoryTypes.SelectAmountsWithZeroAmount And ProductAmountWithVAT > 0
					And SumBalance > 0)
				Or (ParametersForFillingInventoryTypes.SelectAmountsWithZeroAmount And ProductAmountWithVAT < 0
					And SumBalance < 0) Then
				
				NewRow = TableTypesOfStocks_.Add();
				FillPropertyValues(NewRow, Selection);
				
				If TableTypesOfStocks_.Columns.Find("DocumentTransfers_") <> Undefined Then
					NewRow.DocumentTransfers_ = Selection.DocumentSalesOfGoodsAndServices;
				EndIf;
				
				If ValueIsFilled(InventoryOwnerAttribute) Then
					NewRow.InventoryOwnerAttribute = InventoryOwnerAttribute;
				Else
					ExceptionText = NStr("vi = 'Số lượng khác 0 khi hàng tồn kho trống.';
										|ru = 'Ненулевое количество при пустом виде запасов.';
										|en = 'Non-zero quantity with empty inventory owner attributes.'; fa = 'Non-zero quantity with empty inventory owner attributes.';
										|it = 'Quantità diversa da zero in un tipo vuoto di scorta.';
										|pl = 'Niezerowa ilość przy pustym rodzaju zapasów.';
										|tr = 'Stok türü boşsa sıfır olmayan bir miktar.'");
					
					Raise ExceptionText;
				EndIf;
				
				If ProductQuantity_ > 0 
					Or (ParametersForFillingInventoryTypes.SelectAmountsWithZeroAmount
						And ProductQuantity_ = 0 And SumBalance > 0) Then
					
					Count = Min(ProductQuantity_, CountBalance);
					
					If SumBalance <> 0 Then
						SumBalance	= Max(SumBalance, 0);
						AmountIncludingVAT		= ?(CountBalance = Count,
											SumBalance,
											Min(ProductAmountWithVAT, SumBalance));
					Else
						AmountIncludingVAT = ?(ProductQuantity_ <> 0,
										Round(Count * ProductAmountWithVAT / ProductQuantity_, 2, 1),
										0);
					EndIf;
					
				Else
					
					Count = Max(ProductQuantity_, CountBalance);
					
					If SumBalance <> 0 Then
						SumBalance	= Min(SumBalance, 0);
						AmountIncludingVAT		= ?(CountBalance = Count,
											SumBalance,
											Max(ProductAmountWithVAT, SumBalance));
					Else
						AmountIncludingVAT = ?(ProductQuantity_ <> 0,
										Round(Count * ProductAmountWithVAT / ProductQuantity_, 2, 1),
										0);
					EndIf;
					
				EndIf;
				
				StringDataStructure.Count				= Count;
				StringDataStructure.QuantityByGBRN			= ?(QuantityBalanceTotal <> 0,
																	?(QuantityBalanceTotal - Count = 0,
																		QuantityByRNPTBalanceTotal,
																		Count * QuantityByRNPTBalanceTotal / QuantityBalanceTotal),
																	0);
				StringDataStructure.AmountIncludingVAT					= AmountIncludingVAT;
				StringDataStructure.VATAmount					= ?(ProductAmountWithVAT <> 0,
																	Round(AmountIncludingVAT * ProductVATAmount / ProductAmountWithVAT, 2, 1),
																	0);
				StringDataStructure.VATRate					= Selection.VATRate;
				StringDataStructure.CommissionAmount		= ?(ProductQuantity_ <> 0,
																	Round(Count * TotalRemunerationAmount / ProductQuantity_, 2, 1),
																	?(ParametersForFillingInventoryTypes.SelectAmountsWithZeroAmount And ProductAmountWithVAT <> 0,
																	Round(AmountIncludingVAT * TotalRemunerationAmount / ProductAmountWithVAT, 2, 1),
																	0));
				StringDataStructure.AmountVATRemuneration	= ?(ProductQuantity_ <> 0,
																	Round(Count * AmountOfVATRemunerationTotal / ProductQuantity_, 2, 1),
																	?(ParametersForFillingInventoryTypes.SelectAmountsWithZeroAmount And ProductAmountWithVAT <> 0,
																	Round(AmountIncludingVAT * AmountOfVATRemunerationTotal / ProductAmountWithVAT, 2, 1),
																	0));
				StringDataStructure.ExciseTaxAmount				= ?(QuantityBalanceTotal <> 0,
																	?(QuantityBalanceTotal - Count = 0,
																		ExciseTaxAmountBalance,
																		Round(Count * ExciseTaxAmountBalance / QuantityBalanceTotal, 2, 1)),
																	0);
				StringDataStructure.InventoryOwnerAttributeShipment		= InventoryOwnerAttributeShipment;
				StringDataStructure.CorInventoryOwnerAttribute				= CorInventoryOwnerAttribute;
				StringDataStructure.InsufficientProductBalances = False;
				StringDataStructure.ItemsLocationAttributesShipment = Selection.ItemsLocationAttributesShipment;
				
				FillPropertyValues(NewRow, StringDataStructure);
				
				ProductQuantity_			= ProductQuantity_				- StringDataStructure.Count;
				If ThereIsQuantityOfRNPT Then
					QuantityOfGoodsAccordingToRNPT = QuantityOfGoodsAccordingToRNPT - StringDataStructure.QuantityByGBRN;
				EndIf;
				ProductAmountWithVAT				= ProductAmountWithVAT				- StringDataStructure.AmountIncludingVAT;
				ProductVATAmount				= ProductVATAmount				- StringDataStructure.VATAmount;
				TotalRemunerationAmount	= TotalRemunerationAmount		- StringDataStructure.CommissionAmount;
				AmountOfVATRemunerationTotal	= AmountOfVATRemunerationTotal	- StringDataStructure.AmountVATRemuneration;
				SumBalance				= SumBalance					- StringDataStructure.AmountIncludingVAT;
				
				If CurrentBalanceLine <> Undefined Then
					CurrentBalanceLine.CountBalance = CurrentBalanceLine.CountBalance
																- StringDataStructure.Count;
				EndIf;
				
			EndIf;
			
		EndDo; // Sampling by residuals
		
		If ProductQuantity_ <> 0
			Or ProductAmountWithVAT <> 0 Then
			
			ControlExcisableItems = SelectingDataByLine.ExcisableGoods
												And Not OnlyNonExciseItems
												And Not InventoryOwnerAttributeIsInitializedByDefault;
			
			If (WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault
					And Not ControlExcisableItems)
				Or ((Not SelectingDataByLine.ExcisableGoods
						Or OnlyNonExciseItems)
					And PostWithoutControlOfCompanyStockBalance
						And Not IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited)
				// If the user has the appropriate role, then the consumption of work is not controlled
				Or (AllowRetroactiveReleaseRegistration
						And SelectingDataByLine.ItemsType = Enums.ItemsTypes.Work_5) Then
				
				If Not ParametersForFillingInventoryTypes.ProductOwnerInHeader
					And ParametersForFillingInventoryTypes.TableOfDetailsOfStockTypesByDefault.Count() = 0 Then
					
					ExceptionText = NStr("vi = 'Đã đặt dấu hộp kiểm nhận hàng từ chủ sở hữu từ bảng
												|mục tin dạng vật tư theo mặc định, nhưng chưa chuyển bảng.';
												|ru = 'Установлен флаг получения владельца товаров из таблицы
												|реквизитов видов запасов по умолчанию, но таблица не передана.';
												|en = 'Check box of receiving goods owner from the inventory owner attribute table
												|is selected by default, but the table is not transferred.'; fa = 'Check box of receiving goods owner from the inventory owner attribute table
												|is selected by default, but the table is not transferred.';
												|it = 'Impostato flag di ricezione del proprietario della merce dalla tabella
												| dei requisiti dei tipi di scorta per impostazione predefinita, ma la tabella non è impostata.';
												|pl = 'Zostało ustanowione zaznaczenie otrzymania właściciela towarów z tabeli
												|atrybutów rodzajów zapasów domyślnych, ale tabela nie była przekazana.';
												|tr = 'Stok türlerinin tablosu
												|özniteliklerinden ürün sahibini alma bayrağı varsayılan olarak ayarlanmıştır, ancak tablo transfer edilmedi.'");
					
					Raise ExceptionText;
					
				EndIf;
				
				SelectionTableOfProducts.Reset();
				
				RowFilter = New Structure("LineNumber", SelectingDataByLine.LineNumber);
				
				If SelectionTableOfProducts.FindNext(RowFilter) Then
					
					If ParametersForFillingInventoryTypes.ProductOwnerInHeader Then
						DefaultInventoryViewStructure.InventoryType	= ?(SelectionTableOfProducts.InventoryType = Enums.InventoryTypes.Work_5,
																		SelectionTableOfProducts.InventoryType,
																		FetchingDocumentData.InventoryType);
					Else
						DefaultInventoryViewStructure.InventoryType		= SelectionTableOfProducts.InventoryType;
						DefaultInventoryViewStructure.GoodsOwner	= SelectionTableOfProducts.GoodsOwner;
						DefaultInventoryViewStructure.Counterparty		= SelectionTableOfProducts.Counterparty;
						DefaultInventoryViewStructure.Contract			= SelectionTableOfProducts.Contract;
					EndIf;
					
					DefaultInventoryViewStructure.PriceKind					= SelectionTableOfProducts.PriceKind;
					DefaultInventoryViewStructure.FinancialAccountingGroup	= SelectionTableOfProducts.FinancialAccountingGroup;
					DefaultInventoryViewStructure.SubjectToExcise			= SelectionTableOfProducts.SubjectToExcise;
					DefaultInventoryViewStructure.BusinessUnitProduction	= FetchingDocumentData.BusinessUnitProduction;
					KeyOfInventoryOwnerAttribute = KeyOfInventoryOwnerAttributeSelectionCache(ParametersForFillingInventoryTypes.ProductOwnerInHeader,
																DefaultInventoryViewStructure);
					DefaultStockView = DefaultStockTypes[KeyOfInventoryOwnerAttribute];
					
					If DefaultStockView = Undefined Then
						DefaultStockView = Catalogs.InventoryKinds.DocumentInventoryView(
													Organization,
													BusinessOperation,
													DefaultInventoryViewStructure);
						
						DefaultStockTypes.Insert(KeyOfInventoryOwnerAttribute, DefaultStockView);
					EndIf;
					
					NewRow = TableTypesOfStocks_.Add();
					FillPropertyValues(NewRow, SelectionTableOfProducts);
					NewRow.InventoryOwnerAttribute = DefaultStockView;
					
					If TableTypesOfStocks_.Columns.Find("DocumentTransfers_") <> Undefined Then
						NewRow.DocumentTransfers_ = SelectionTableOfProducts.DocumentSalesOfGoodsAndServices;
					EndIf;
					
					If ParametersForFillingInventoryTypes.NameOfRemainderTable = "CompanyGoodsForTransfer" Then
						NewRow.RecipientInventoryOwnerAttribute = Catalogs.InventoryKinds.TypeOfInventoryToTransferBetweenOrganizations(
																DefaultStockView,
																DocumentObject.CompanyRecipient,
																DefaultInventoryViewStructure.VATTaxation,
																DocumentObject.Date);
					EndIf;
					
					StringDataStructure.Count				= ProductQuantity_;
					StringDataStructure.QuantityByGBRN			= QuantityOfGoodsAccordingToRNPT;
					StringDataStructure.AmountIncludingVAT					= ProductAmountWithVAT;
					StringDataStructure.VATAmount					= ProductVATAmount;
					StringDataStructure.CommissionAmount		= TotalRemunerationAmount;
					StringDataStructure.AmountVATRemuneration	= AmountOfVATRemunerationTotal;
					StringDataStructure.VATRate					= SelectionTableOfProducts.VATRate;
					StringDataStructure.InsufficientProductBalances = True;
					StringDataStructure.ItemsLocationAttributesShipment = NewRow.ItemsLocationAttributes;
					StringDataStructure.InventoryOwnerAttributeShipment		= NewRow.InventoryOwnerAttribute;
					StringDataStructure.CorInventoryOwnerAttribute				= NewRow.InventoryOwnerAttribute;
					StringDataStructure.ExciseTaxAmount = 0;
					FillPropertyValues(NewRow, StringDataStructure);
					
				EndIf;
				
			EndIf;
			
			If (Not WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault
					Or ControlExcisableItems)
				And Not ParametersForFillingInInventoryOwnerAttributesManually.IgnoreResidueControlErrors Then
				
				If ParametersForFillingInventoryTypes.ReportFillingErrors Then
					
					Selection = SelectingDataByLine.Select();
					Selection.Next();
					
					NewLineOfErrors = ErrorsTable.Add();
					FillPropertyValues(NewLineOfErrors, Selection);
					
					NewLineOfErrors.Count			= ProductQuantity_;
					NewLineOfErrors.Sum					= ProductAmountWithVAT;
					NewLineOfErrors.UnitOfMeasure		= Selection.UnitOfMeasure;
					NewLineOfErrors.NotCCDNumberIsSpecified		= NotCCDNumberIsSpecified;
					NewLineOfErrors.TracedGoods	= TracedGoods;
					
				EndIf;
				
				If ((SelectingDataByLine.ExcisableGoods
							And Not OnlyNonExciseItems)
						Or Not PostWithoutControlOfCompanyStockBalance
						Or IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited)
					// If the user has the appropriate role, then the consumption of work is not controlled
					And (Not AllowRetroactiveReleaseRegistration
						Or Not SelectingDataByLine.ItemsType = Enums.ItemsTypes.Work_5) Then
					
					Cancel = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo; // Sampling by document lines
	
	If ErrorsTable.Count() > 0
		And PostWithoutControlOfCompanyStockBalance Then
		
		MessageText = NStr("vi = 'Đã kết chuyển chứng từ %Ref% có ngắt sử dụng kiểm soát số dư hàng hóa trong doanh nghiệp.';
							|ru = 'Документ %Ref% проведен с выключенным контролем остатков товаров организаций.';
							|en = 'The %Ref% document is posted with enabled company stock balance control.'; fa = 'The %Ref% document is posted with enabled company stock balance control.';
							|it = 'Documento %Ref% eseguito con il controllo dei beni residui delle aziende disattivato.';
							|pl = 'Dokument %Ref% jest zaksięgowany z wyłączoną kontrolą pozostałości towarów firm.';
							|tr = '%Ref% belgesi, iş yerinin stok kontrolü kapalıyken kaydedildi.'",
								Metadata.DefaultLanguage.LanguageCode);
		MessageText = StrReplace(MessageText, "%Ref%", DocumentObject.Ref);
		
		WriteLogEvent(EventNameResidueControlDisabled(),
								EventLogLevel.Warning,
								,
								DocumentObject.Ref,
								MessageText);
		
	EndIf;
	
	If ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods Then
		ParametersForFillingInventoryTypes.TableTypesOfStocks_ = TableTypesOfStocks_;
	Else
		DocumentObject[ParametersForFillingInventoryTypes.NameTSTypesOfStocks].Load(TableTypesOfStocks_);
	EndIf;
	
	If ControlChangeOfCCDNumbers Then
		
		TableOfCCDNumbers.Columns.Add("NewCount");
		
		For Each TableRow In TableTypesOfStocks_ Do
			NewRow = TableOfCCDNumbers.Add();
			FillPropertyValues(NewRow, TableRow);
			NewRow.Count		= 0;
			NewRow.NewCount	= TableRow.Count;
		EndDo;
		
		TableOfCCDNumbers.GroupBy("ItemsLocationAttributes, CCDNumber", "Count, NewCount");
		
		For Each TableRow In TableOfCCDNumbers Do
			If TableRow.Count <> TableRow.NewCount Then
				AdditionalProperties.Insert("CCDNumbersHaveChanged", True);
			EndIf;
		EndDo;
		
	EndIf;
	
	ReportErrorsInFillingOutInventoryTypesUsingTableForRegistration(DocumentObject,
																ErrorsTable,
																ParametersForFillingInventoryTypes,
																BusinessOperation);
	
EndProcedure

Function RequestDistributionWithoutTakingIntoAccountPrioritiesOfTableOfGoodsOnTableOfBalances(TempTablesManager,
																				AdditionalProperties,
																				FillParameters)
	
	Query = New Query;
	Query.Text = ExcisableGoodsAccounting.QueryTextTTExcisableItems("TableOfGoods")
	+ Common.QueryBatchSeparator() +
	"SELECT
	|	MAX(TableOfGoods.LineNumber) AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ISNULL(CommissionAgentAnalytics.DimensionKey, TableOfGoods.ItemsLocationAttributes) AS DimensionLeftovers,
	|	ISNULL(CommissionAgentAnalytics.Products, TableOfGoods.ItemsLocationAttributes.Products) AS ProductList_,
	|	ISNULL(CommissionAgentAnalytics.Characteristic, TableOfGoods.ItemsLocationAttributes.CHARACTERISTIC) AS CharacteristicsOfResidues,
	|	ISNULL(CommissionAgentAnalytics.Series, TableOfGoods.ItemsLocationAttributes.Series) AS SeriesOfResidues,
	|	ProductsTable.UnitOfMeasure AS UnitOfMeasure,
	|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE) AS ExcisableGoods,
	|	DocumentDataTable.SubjectToExcise AS SubjectToExcise,
	|	ProductsTable.KeepRecordsByCCD AS KeepRecordsByCCD,
	|	CASE
	|		WHEN ProductsTable.TracedGoods
	|				AND &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(DocumentDataTable.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TracedGoods,
	|	ISNULL(CommissionAgentAnalytics.StorageLocation, TableOfGoods.ItemsLocationAttributes.StorageLocation) AS LeftoversWarehouse,
	|	ISNULL(CommissionAgentAnalytics.Purpose, TableOfGoods.ItemsLocationAttributes.Purpose) AS TheAppointmentOfResidues,
	|	ISNULL(CommissionAgentAnalytics.ProductCostElement, TableOfGoods.ItemsLocationAttributes.ProductCostElement) AS ArticleCalculationOfBalances,
	|	TableOfGoods.ItemsLocationAttributes.Products AS Products,
	|	ProductsTable.ItemsType AS ItemsType,
	|	TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes.Series AS Series,
	|	TableOfGoods.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	&FieldTextTableOfGoodsPartnerProducts_ AS PartnerProducts,
	|	TableOfGoods.SelectTypesOfStocks AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.PriceKind AS PriceKind,
	|	TableOfGoods.ItemsLocationAttributes.Purpose AS Purpose,
	|	CASE
	|		WHEN &FieldTextTableOfGoodsDocumentSalesOfGoodsAndServices_ IN(&EmptyValuesOfImplementationDocument)
	|			THEN UNDEFINED
	|		ELSE &FieldTextTableOfGoodsDocumentSalesOfGoodsAndServices_
	|	END AS DocumentSalesOfGoodsAndServices,
	|	CASE
	|		WHEN &FieldTextTableOfGoodsDocumentLoggingIn_ IN(&EmptyValuesOfRegistrationDocument)
	|			THEN UNDEFINED
	|		ELSE &FieldTextTableOfGoodsDocumentLoggingIn_
	|	END AS DocumentLoggingIn,
	|	&FieldTextTableOfGoodsPeriod_ AS Period,
	|	DocumentDataTable.BusinessOperation AS BusinessOperation,
	|	&TextOfSelectionFieldTableOfProductsVATRate_ AS VATRate,
	|	&TextOfSelectionFieldVATRatesBasicVATRate_ AS BasicVATRate,
	|	SUM(TableOfGoods.Count) AS Count,
	|	&FieldTextTableOfGoodsQuantityByGBRN_ AS QuantityByGBRN,
	|	SUM(TableOfGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	SUM(TableOfGoods.VATAmount) AS VATAmount,
	|	&FieldTextTableOfGoodsExciseTaxAmount_ AS ExciseTaxAmount,
	|	SUM(TableOfGoods.CommissionAmount) AS CommissionAmount,
	|	SUM(TableOfGoods.AmountVATRemuneration) AS AmountVATRemuneration
	|INTO DocumentTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|		
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON TableOfGoods.Products = ProductsTable.Ref
	|		
	|		LEFT JOIN Catalog.VATRates AS VATRates
	|		ON &FieldTextTableOfGoodsVATRate_ = VATRates.Ref
	|			AND VATRates.CalculatedRate
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommissionAgentAnalytics
	|		ON TableOfGoods.Products = CommissionAgentAnalytics.Products
	|			AND TableOfGoods.Characteristic = CommissionAgentAnalytics.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef) = CommissionAgentAnalytics.Purpose
	|			AND DocumentDataTable.Partner = CommissionAgentAnalytics.StorageLocation
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommissionAgentAnalytics.Series
	|			AND CommissionAgentAnalytics.ProductCostElement = &EmptyValueOfCalculationArticle
	|			AND (DocumentDataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|				OR DocumentDataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|		
	|		LEFT JOIN TTExcisableItems AS TTExcisableItems
	|		ON ProductsTable.Ref = TTExcisableItems.Products
	|
	|WHERE
	|	ProductsTable.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage),
	|											VALUE(Enum.ItemsTypes.Work_5))
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	ISNULL(CommissionAgentAnalytics.DimensionKey, TableOfGoods.ItemsLocationAttributes),
	|	ProductsTable.UnitOfMeasure,
	|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE),
	|	DocumentDataTable.SubjectToExcise,
	|	ProductsTable.KeepRecordsByCCD,
	|	CASE
	|		WHEN ProductsTable.TracedGoods
	|				AND &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(DocumentDataTable.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	ISNULL(CommissionAgentAnalytics.Products, TableOfGoods.ItemsLocationAttributes.Products),
	|	ISNULL(CommissionAgentAnalytics.Characteristic, TableOfGoods.ItemsLocationAttributes.CHARACTERISTIC),
	|	ISNULL(CommissionAgentAnalytics.Series, TableOfGoods.ItemsLocationAttributes.Series),
	|	ISNULL(CommissionAgentAnalytics.StorageLocation, TableOfGoods.ItemsLocationAttributes.StorageLocation),
	|	ISNULL(CommissionAgentAnalytics.Purpose, TableOfGoods.ItemsLocationAttributes.Purpose),
	|	ISNULL(CommissionAgentAnalytics.ProductCostElement, TableOfGoods.ItemsLocationAttributes.ProductCostElement),
	|	TableOfGoods.ItemsLocationAttributes.Products,
	|	ProductsTable.ItemsType,
	|	TableOfGoods.ItemsLocationAttributes.CHARACTERISTIC,
	|	TableOfGoods.ItemsLocationAttributes.Series,
	|	TableOfGoods.ItemsLocationAttributes.StorageLocation,
	|	&FieldTextTableOfGoodsPartnerProducts_,
	|	TableOfGoods.ItemsLocationAttributes.Purpose,
	|	CASE 
	|		WHEN &FieldTextTableOfGoodsDocumentSalesOfGoodsAndServices_ IN(&EmptyValuesOfImplementationDocument)
	|			THEN UNDEFINED
	|		ELSE &FieldTextTableOfGoodsDocumentSalesOfGoodsAndServices_
	|	END,
	|	CASE
	|		WHEN &FieldTextTableOfGoodsDocumentLoggingIn_ IN(&EmptyValuesOfRegistrationDocument)
	|			THEN UNDEFINED
	|		ELSE &FieldTextTableOfGoodsDocumentLoggingIn_
	|	END,
	|	&FieldTextTableOfGoodsPeriod_,
	|	DocumentDataTable.BusinessOperation,
	|	&TextOfDimensionFieldTableOfProductsVATRate_,
	|	&TextOfVATRateDimensionFieldBasicVATRate_,
	|	TableOfGoods.SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.PriceKind
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentDataTable.Organization AS Organization,
	|	DocumentDataTable.Date AS Period,
	|	DocumentDataTable.Partner AS Partner,
	|	DocumentDataTable.Counterparty AS Counterparty,
	|	DocumentDataTable.Terms AS Terms,
	|	DocumentDataTable.Contract AS Contract,
	|	DocumentDataTable.Currency AS Currency,
	|	DocumentDataTable.VATTaxation AS VATTaxation,
	|	DocumentDataTable.BusinessOperation AS BusinessOperation,
	|	DocumentDataTable.SubjectToExcise AS SubjectToExcise,
	|	DocumentDataTable.BusinessUnitProduction AS BusinessUnitProduction,
	|	DocumentDataTable.InventoryType AS InventoryType
	|FROM
	|	DocumentDataTable AS DocumentDataTable
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DefaultStockTypes.GoodsOwner AS GoodsOwner,
	|	CASE
	|		WHEN DefaultStockTypes.InventoryType IS NULL
	|				AND DocumentTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.InventoryTypes.Work_5)
	|		ELSE DefaultStockTypes.InventoryType
	|	END AS InventoryType,
	|	DefaultStockTypes.Counterparty AS Counterparty,
	|	DefaultStockTypes.Contract AS Contract,
	|	DocumentTable.Warehouse AS Warehouse,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentTable.UnitOfMeasure AS UnitOfMeasure,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.Series AS Series,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.Count AS Count,
	|	CAST(DocumentTable.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	DocumentTable.CCDNumber AS CCDNumber,
	|	DocumentTable.PriceKind AS PriceKind,
	|	DocumentTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	DocumentTable.DocumentLoggingIn AS DocumentLoggingIn,
	|	DocumentTable.Period AS Period,
	|	CASE
	|		WHEN DocumentTable.SubjectToExcise
	|			THEN DocumentTable.ExcisableGoods
	|		ELSE FALSE
	|	END AS SubjectToExcise,
	|	CASE
	|		WHEN NOT &UseFinAccountingGroups
	|				OR DocumentTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|		ELSE ISNULL(CatalogProducts.FinancialAccountingGroup, VALUE(Catalog.InventoryAccountingGroups.EmptyRef))
	|	END AS FinancialAccountingGroup
	|FROM
	|	DocumentTable AS DocumentTable
	|		LEFT JOIN TableOfDetailsOfStockTypesByDefault AS DefaultStockTypes
	|		ON DefaultStockTypes.LineNumber = DocumentTable.LineNumber
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON DocumentTable.Products = CatalogProducts.Ref
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(TableTypesOfStocks_.LineNumber) AS LineNumber,
	|	ISNULL(CommissionAgentAnalytics.DimensionKey, TableTypesOfStocks_.ItemsLocationAttributes) AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	ISNULL(DimensionShipments.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS ShipmentBatch,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	SUM(TableTypesOfStocks_.Count) AS Count,
	|	&FieldTextTableTypesOfStocks_QuantityByGBRN_ AS QuantityByGBRN,
	|	&FieldTextTableTypesOfStocks_VATAmount_ AS VATAmount,
	|	&FieldTextTableTypesOfStocks_ExciseTaxAmount_ AS ExciseTaxAmount,
	|	CASE
	|		WHEN SUM(TableTypesOfStocks_.Count) > 0
	|			THEN 1
	|		ELSE -1
	|	END AS Character,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.DocumentLoggingIn AS DocumentLoggingIn,
	|	&FieldTextTableTypesOfStocks_ItemsLocationAttributesShipment_ AS ItemsLocationAttributesShipment,
	|	&FieldTextTableTypesOfStocks_Period_ AS Period
	|INTO TTTypesOfStocksInSummary
	|FROM
	|	TableTypesOfStocks_ AS TableTypesOfStocks_
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionShipments
	|		ON &FieldTextTableTypesOfStocks_ItemsLocationAttributesShipment_ = DimensionShipments.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommissionAgentAnalytics
	|		ON TableTypesOfStocks_.Products = CommissionAgentAnalytics.Products
	|			AND TableTypesOfStocks_.Characteristic = CommissionAgentAnalytics.Characteristic
	|			AND DocumentDataTable.Partner = CommissionAgentAnalytics.StorageLocation
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Purpose = CommissionAgentAnalytics.Purpose
	|			AND CommissionAgentAnalytics.ProductCostElement = &EmptyValueOfCalculationArticle
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommissionAgentAnalytics.Series
	|			AND DocumentDataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|
	|GROUP BY
	|	ISNULL(CommissionAgentAnalytics.DimensionKey, TableTypesOfStocks_.ItemsLocationAttributes),
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute,
	|	ISNULL(DimensionShipments.Series, VALUE(Catalog.ItemsBatches.EmptyRef)),
	|	TableTypesOfStocks_.OriginWarehouse,
	|	TableTypesOfStocks_.CCDNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.DocumentLoggingIn,
	|	&FieldTextTableTypesOfStocks_ItemsLocationAttributesShipment_,
	|	&FieldTextTableTypesOfStocks_Period_
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	RecipientInventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	// Let's group the leftovers. For each grouped row
	// , we will determine the use of this remainder in the current document.
	// It is necessary to correctly obtain the totals from the document,
	// and not the average of the balances.
	|SELECT
	|	MAX(TTBalancesWithoutGrouping.DocumentRemnants) AS DocumentRemnants,
	|
	|	TTBalancesWithoutGrouping.Organization AS Organization,
	|	TTBalancesWithoutGrouping.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTBalancesWithoutGrouping.Products AS Products,
	|	TTBalancesWithoutGrouping.Characteristic AS Characteristic,
	|	TTBalancesWithoutGrouping.Series AS Series,
	|	TTBalancesWithoutGrouping.ShipmentBatch AS ShipmentBatch,
	|	TTBalancesWithoutGrouping.Warehouse AS Warehouse,
	|	TTBalancesWithoutGrouping.Purpose AS Purpose,
	|	TTBalancesWithoutGrouping.PurposeOfShipment AS PurposeOfShipment,
	|	TTBalancesWithoutGrouping.ProductCostElement AS ProductCostElement,
	|	TTBalancesWithoutGrouping.OriginWarehouse AS OriginWarehouse,
	|
	|	TTBalancesWithoutGrouping.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTBalancesWithoutGrouping.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TTBalancesWithoutGrouping.InventoryOwnerAttributeShipment AS InventoryOwnerAttributeShipment,
	|	TTBalancesWithoutGrouping.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TTBalancesWithoutGrouping.CCDNumber AS CCDNumber,
	|	TTBalancesWithoutGrouping.DateOfReceipt AS DateOfReceipt,
	|
	|	MAX(TTBalancesWithoutGrouping.QuantityBalanceTotal) AS QuantityBalanceTotal,
	|	SUM(TTBalancesWithoutGrouping.CountBalance) AS CountBalance,
	|	MAX(TTBalancesWithoutGrouping.QuantityByRNPTBalanceTotal) AS QuantityByRNPTBalanceTotal,
	|	SUM(TTBalancesWithoutGrouping.SumBalance) AS SumBalance,
	|	MAX(TTBalancesWithoutGrouping.VATAmountBalance) AS VATAmountBalance,
	|	MAX(TTBalancesWithoutGrouping.ExciseTaxAmountBalance) AS ExciseTaxAmountBalance,
	|
	|	TTBalancesWithoutGrouping.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TTBalancesWithoutGrouping.DocumentLoggingIn AS DocumentLoggingIn,
	|	TTBalancesWithoutGrouping.Period AS Period,
	|	TTBalancesWithoutGrouping.ProcedureForUsingBatch AS ProcedureForUsingBatch,
	|	TTBalancesWithoutGrouping.WarehouseUsageProcedure AS WarehouseUsageProcedure,
	|	TTBalancesWithoutGrouping.SelectionAccordingToCommitteeSVATRate AS SelectionAccordingToCommitteeSVATRate,
	|	TTBalancesWithoutGrouping.CommitteeSVATRate AS CommitteeSVATRate
	|INTO TTBalance
	|FROM
	|	(SELECT // BALANCES SPECIFIED IN THE DOCUMENT
	|		TRUE AS DocumentRemnants,
	|		
	|		Balance.Organization AS Organization,
	|		InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Keys.Products AS Products,
	|		Keys.Characteristic AS Characteristic,
	|		Keys.Series AS Series,
	|		InventoryKinds.ShipmentBatch AS ShipmentBatch,
	|		Keys.StorageLocation AS Warehouse,
	|		Keys.Purpose AS Purpose,
	|		Balance.Purpose AS PurposeOfShipment,
	|		Keys.ProductCostElement AS ProductCostElement,
	|		InventoryKinds.OriginWarehouse AS OriginWarehouse,
	|		
	|		InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		InventoryKinds.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|		Balance.InventoryOwnerAttributeShipment AS InventoryOwnerAttributeShipment,
	|		Balance.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		InventoryKinds.CCDNumber AS CCDNumber,
	|		Balance.DateOfReceipt AS DateOfReceipt,
	|		
	|		InventoryKinds.Count AS QuantityBalanceTotal,
	|		CASE
	|			WHEN InventoryKinds.InventoryOwnerAttributesAreSpecifiedManually
	|					AND (NOT &RefillInventoryKinds
	|						OR &PostWithoutControlOfCompanyStockBalance)
	|				THEN InventoryKinds.Count
	|			WHEN InventoryKinds.Character * Balance.CountBalance > InventoryKinds.Character * InventoryKinds.Count
	|				THEN InventoryKinds.Count
	|			ELSE Balance.CountBalance
	|		END AS CountBalance,
	|		InventoryKinds.QuantityByGBRN AS QuantityByRNPTBalanceTotal,
	|	
	|		CASE
	|			WHEN (InventoryKinds.Character * Balance.CountBalance > InventoryKinds.Character * InventoryKinds.Count)
	|					AND Balance.CountBalance <> 0
	|				THEN InventoryKinds.Count * Balance.SumBalance / Balance.CountBalance
	|			ELSE Balance.SumBalance
	|		END AS SumBalance,
	|		InventoryKinds.VATAmount AS VATAmountBalance,
	|		InventoryKinds.ExciseTaxAmount AS ExciseTaxAmountBalance,
	|		InventoryKinds.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		InventoryKinds.DocumentLoggingIn AS DocumentLoggingIn,
	|		InventoryKinds.Period AS Period,
	|		CASE
	|			WHEN Balance.Series = DimensionLeftovers.Series
	|				THEN 1
	|			ELSE 0
	|		END AS ProcedureForUsingBatch,
	|		CASE
	|			WHEN Balance.OriginWarehouse = DimensionLeftovers.StorageLocation
	|				THEN 1
	|			ELSE 0
	|		END AS WarehouseUsageProcedure,
	|		CASE
	|			WHEN NOT AvailableTypesOfStocks.InventoryOwnerAttribute IS NULL
	|				THEN AvailableTypesOfStocks.SelectionAccordingToCommitteeSVATRate
	|			ELSE FALSE
	|		END AS SelectionAccordingToCommitteeSVATRate,
	|		CASE
	|			WHEN NOT AvailableTypesOfStocks.InventoryOwnerAttribute IS NULL
	|				THEN AvailableTypesOfStocks.CommitteeSVATRate
	|			ELSE UNDEFINED
	|		END AS CommitteeSVATRate
	|	FROM
	|		TTTypesOfStocksInSummary AS InventoryKinds
	|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON InventoryKinds.ItemsLocationAttributes = Keys.Ref
	|			
	|			LEFT JOIN BalanceTable AS Balance
	|			ON Balance.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|				AND Balance.InventoryOwnerAttribute = InventoryKinds.InventoryOwnerAttribute
	|				AND (Balance.Series = InventoryKinds.ShipmentBatch
	|					OR InventoryKinds.ShipmentBatch IN(VALUE(Catalog.ItemsBatches.EmptyRef), UNDEFINED))
	|				AND (Balance.OriginWarehouse = InventoryKinds.OriginWarehouse
	|					OR InventoryKinds.OriginWarehouse IN(VALUE(Catalog.Warehouses.EmptyRef), UNDEFINED))
	|				AND Balance.CCDNumber = InventoryKinds.CCDNumber
	|				AND Balance.DocumentSalesOfGoodsAndServices = InventoryKinds.DocumentSalesOfGoodsAndServices
	|				AND Balance.DocumentLoggingIn = InventoryKinds.DocumentLoggingIn
	|				AND (InventoryKinds.Period = DATETIME(1,1,1)
	|					OR InventoryKinds.Period = Balance.DateOfReceipt)
	|			
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionLeftovers
	|			ON Balance.ItemsLocationAttributes = DimensionLeftovers.Ref
	|			
	|			LEFT JOIN AvailableTypesOfStocks AS AvailableTypesOfStocks
	|			ON Balance.InventoryOwnerAttribute = AvailableTypesOfStocks.InventoryOwnerAttribute
	|				AND &SelectCommissionInventoryForCommitteeSTaxation
	|	
	|	WHERE
	|		NOT Balance.InventoryOwnerAttribute IS NULL
	|		OR (InventoryKinds.InventoryOwnerAttributesAreSpecifiedManually
	|			AND (NOT &RefillInventoryKinds
	|				OR &PostWithoutControlOfCompanyStockBalance))
	|	
	|	UNION ALL
	|	
	|	SELECT // BALANCES NOT SPECIFIED IN THE DOCUMENT
	|		FALSE AS DocumentRemnants,
	|		
	|		Balance.Organization AS Organization,
	|		Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Keys.Products,
	|		Keys.Characteristic,
	|		Keys.Series,
	|		Balance.Series,
	|		Keys.StorageLocation,
	|		Keys.Purpose,
	|		Balance.Purpose,
	|		Keys.ProductCostElement,
	|		Balance.OriginWarehouse AS OriginWarehouse,
	|		
	|		Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Balance.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|		Balance.InventoryOwnerAttributeShipment AS InventoryOwnerAttributeShipment,
	|		Balance.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		Balance.CCDNumber AS CCDNumber,
	|		Balance.DateOfReceipt AS DateOfReceipt,
	|		
	|		Balance.CountBalance AS QuantityBalanceTotal,
	|		Balance.CountBalance - ISNULL(InventoryKinds.Count, 0) AS CountBalance,
	|		&FieldTextBalanceTableQuantityByGBRNBalance_ AS QuantityByRNPTBalanceTotal,
	|		CASE
	|			WHEN Balance.CountBalance <> 0
	|				THEN Balance.SumBalance - (ISNULL(InventoryKinds.Count, 0) * Balance.SumBalance / Balance.CountBalance)
	|			WHEN ISNULL(InventoryKinds.Count, 0) = 0
	|				THEN Balance.SumBalance
	|			ELSE 0 // The amount of the balance was selected in the lines with the type of inventory
	|		END AS SumBalance,
	|		&FieldTextBalanceTableVATAmountBalance_ AS VATAmountBalance,
	|		&FieldTextBalanceTableExciseTaxAmountBalance_ AS ExciseTaxAmountBalance,
	|		CASE
	|			WHEN Balance.DocumentSalesOfGoodsAndServices IN (&EmptyValuesOfImplementationDocument)
	|				THEN UNDEFINED
	|			ELSE Balance.DocumentSalesOfGoodsAndServices
	|		END AS DocumentSalesOfGoodsAndServices,
	|		CASE
	|			WHEN Balance.DocumentLoggingIn IN (&EmptyValuesOfRegistrationDocument)
	|				THEN UNDEFINED
	|			ELSE Balance.DocumentLoggingIn
	|		END AS DocumentLoggingIn,
	|		InventoryKinds.Period,
	|		CASE
	|			WHEN Balance.Series = Keys.Series
	|				THEN 1
	|			ELSE 0
	|		END AS ProcedureForUsingBatch,
	|		CASE
	|			WHEN Balance.OriginWarehouse = Keys.StorageLocation
	|				THEN 1
	|			ELSE 0
	|		END AS WarehouseUsageProcedure,
	|		CASE
	|			WHEN NOT AvailableTypesOfStocks.InventoryOwnerAttribute IS NULL
	|				THEN AvailableTypesOfStocks.SelectionAccordingToCommitteeSVATRate
	|			ELSE FALSE
	|		END AS SelectionAccordingToCommitteeSVATRate,
	|		CASE
	|			WHEN NOT AvailableTypesOfStocks.InventoryOwnerAttribute IS NULL
	|				THEN AvailableTypesOfStocks.CommitteeSVATRate
	|			ELSE UNDEFINED
	|		END AS CommitteeSVATRate
	|	FROM
	|		BalanceTable AS Balance
	|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Balance.ItemsLocationAttributes = Keys.Ref
	|			
	|			LEFT JOIN TTTypesOfStocksInSummary AS InventoryKinds
	|			ON Balance.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|				AND Balance.InventoryOwnerAttribute = InventoryKinds.InventoryOwnerAttribute
	|				AND (Balance.Series = InventoryKinds.ShipmentBatch
	|					OR InventoryKinds.ShipmentBatch IN(VALUE(Catalog.ItemsBatches.EmptyRef), UNDEFINED))
	|				AND (Balance.OriginWarehouse = InventoryKinds.OriginWarehouse
	|					OR InventoryKinds.OriginWarehouse IN(VALUE(Catalog.Warehouses.EmptyRef), UNDEFINED))
	|				AND Balance.CCDNumber = InventoryKinds.CCDNumber
	|				AND Balance.DocumentSalesOfGoodsAndServices = InventoryKinds.DocumentSalesOfGoodsAndServices
	|				AND Balance.DocumentLoggingIn = InventoryKinds.DocumentLoggingIn
	|				AND (InventoryKinds.Period = DATETIME(1,1,1)
	|					OR InventoryKinds.Period = Balance.DateOfReceipt)
	|			
	|			LEFT JOIN AvailableTypesOfStocks AS AvailableTypesOfStocks
	|			ON Balance.InventoryOwnerAttribute = AvailableTypesOfStocks.InventoryOwnerAttribute
	|				AND &SelectCommissionInventoryForCommitteeSTaxation
	|	
	|	WHERE
	|		CASE
	|			WHEN InventoryKinds.Count IS NULL
	|				THEN TRUE
	|			WHEN InventoryKinds.Count = 0
	|				THEN NOT InventoryKinds.LineNumber = 99999
	|			WHEN InventoryKinds.Character * InventoryKinds.Count > 0
	|				THEN InventoryKinds.Character * Balance.CountBalance - InventoryKinds.Character * InventoryKinds.Count > 0
	|			ELSE InventoryKinds.Character * Balance.CountBalance - InventoryKinds.Character * InventoryKinds.Count < 0
	|		END
	|	
	|	) AS TTBalancesWithoutGrouping
	|
	|GROUP BY
	|	TTBalancesWithoutGrouping.Organization,
	|	TTBalancesWithoutGrouping.ItemsLocationAttributes,
	|	TTBalancesWithoutGrouping.Products,
	|	TTBalancesWithoutGrouping.Characteristic,
	|	TTBalancesWithoutGrouping.Series,
	|	TTBalancesWithoutGrouping.ShipmentBatch,
	|	TTBalancesWithoutGrouping.Warehouse,
	|	TTBalancesWithoutGrouping.Purpose,
	|	TTBalancesWithoutGrouping.PurposeOfShipment,
	|	TTBalancesWithoutGrouping.ProductCostElement,
	|	TTBalancesWithoutGrouping.OriginWarehouse,
	|	TTBalancesWithoutGrouping.InventoryOwnerAttribute,
	|	TTBalancesWithoutGrouping.RecipientInventoryOwnerAttribute,
	|	TTBalancesWithoutGrouping.InventoryOwnerAttributeShipment,
	|	TTBalancesWithoutGrouping.CorInventoryOwnerAttribute,
	|	TTBalancesWithoutGrouping.CCDNumber,
	|	TTBalancesWithoutGrouping.DateOfReceipt,
	|	TTBalancesWithoutGrouping.DocumentSalesOfGoodsAndServices,
	|	TTBalancesWithoutGrouping.DocumentLoggingIn,
	|	TTBalancesWithoutGrouping.Period,
	|	TTBalancesWithoutGrouping.ProcedureForUsingBatch,
	|	TTBalancesWithoutGrouping.WarehouseUsageProcedure,
	|	TTBalancesWithoutGrouping.SelectionAccordingToCommitteeSVATRate,
	|	TTBalancesWithoutGrouping.CommitteeSVATRate
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Warehouse AS Warehouse,
	|	ISNULL(ProductKeys.Purpose, UNDEFINED) AS Purpose,
	|	DocumentTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.ItemsType AS ItemsType,
	|	CASE
	|		WHEN NOT &UseFinAccountingGroups
	|				OR DocumentTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|		ELSE ISNULL(CAST(DocumentTable.Products AS Catalog.Products).FinancialAccountingGroup, VALUE(Catalog.InventoryAccountingGroups.EmptyRef))
	|	END AS FinancialAccountingGroup,
	|	ISNULL(CAST(DocumentTable.Products AS Catalog.Products).FEACNCode.Commodity, FALSE) AS Commodity,
	|	DocumentTable.ExcisableGoods AS ExcisableGoods,
	|	DocumentTable.UnitOfMeasure AS UnitOfMeasure,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.PartnerProducts AS PartnerProducts,
	|	DocumentTable.Series AS Series,
	|	DocumentTable.Count AS Count,
	|	CAST(DocumentTable.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	DocumentTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.ExciseTaxAmount AS ExciseTaxAmount,
	|	DocumentTable.CommissionAmount AS CommissionAmount,
	|	DocumentTable.AmountVATRemuneration AS AmountVATRemuneration,
	|	DocumentDataTable.Date AS DocumentDate,
	|	DocumentDataTable.Currency AS Currency,
	|
	|	ISNULL(Balance.InventoryOwnerAttribute, UNDEFINED) AS InventoryOwnerAttribute,
	|	ISNULL(Balance.RecipientInventoryOwnerAttribute, UNDEFINED) AS RecipientInventoryOwnerAttribute,
	|	ISNULL(Balance.InventoryOwnerAttributeShipment, UNDEFINED) AS InventoryOwnerAttributeShipment,
	|	ISNULL(Balance.CorInventoryOwnerAttribute, VALUE(Catalog.InventoryKinds.EmptyRef)) AS CorInventoryOwnerAttribute,
	|	ISNULL(DetailsOfTypeOfShipmentInventory.SaleOfAnotherCompanyInventory, FALSE) AS ShippingInventoryToAnotherOrganization,
	|	ISNULL(Balance.CCDNumber, UNDEFINED) AS CCDNumber,
	|	CASE
	|		WHEN &MonitorCCDNumbers = FALSE
	|				OR NOT DocumentTable.KeepRecordsByCCD
	// Disabling verification for givers of version 2.4.
	|				OR (ISNULL(InventoryTypeDetails.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) IN (
	|							VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|							VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
	|					AND NOT ISNULL(InventoryTypeDetails.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|						VALUE(Enum.ContractTypes.ReceiptForTolling2_5))
	|			THEN FALSE
	// A check is enabled to write off discrepancies in purchase receipts.
	|		WHEN &MonitorCCDNumbers = TRUE
	|				AND DocumentTable.KeepRecordsByCCD
	|				AND (Balance.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|					OR Balance.CCDNumber IS NULL)
	|			THEN TRUE
	|		WHEN (DocumentTable.TracedGoods
	|					OR (DocumentTable.KeepRecordsByCCD
	|						AND &RestrictTransactionsWithImportedGoodsWithoutCCDNumbers))
	|				AND (Balance.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|					OR Balance.CCDNumber IS NULL)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NotCCDNumberIsSpecified,
	|	DocumentTable.TracedGoods AS TracedGoods,
	|
	|	ISNULL(Balance.DateOfReceipt, DATETIME(2399, 1, 1)) AS DateOfReceipt,
	|	ISNULL(Balance.OriginWarehouse, UNDEFINED) AS OriginWarehouse,
	|
	|	ISNULL(Balance.QuantityBalanceTotal, 0) AS QuantityBalanceTotal,
	|	ISNULL(Balance.CountBalance, 0) AS CountBalance,
	|	ISNULL(Balance.QuantityByRNPTBalanceTotal, 0) AS QuantityByRNPTBalanceTotal,
	|	ISNULL(Balance.SumBalance, 0) AS SumBalance,
	|	ISNULL(Balance.VATAmountBalance, 0) AS VATAmountBalance,
	|	ISNULL(Balance.ExciseTaxAmountBalance, 0) AS ExciseTaxAmountBalance,
	|	ISNULL(DimensionShipments.DimensionKey, DocumentTable.ItemsLocationAttributes) AS ItemsLocationAttributesShipment,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor))
	|				AND DocumentTable.DocumentSalesOfGoodsAndServices <> UNDEFINED
	|			THEN DocumentTable.DocumentSalesOfGoodsAndServices
	|		ELSE ISNULL(Balance.DocumentSalesOfGoodsAndServices, UNDEFINED)
	|	END AS DocumentSalesOfGoodsAndServices,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor))
	|				AND DocumentTable.DocumentLoggingIn <> UNDEFINED
	|			THEN DocumentTable.DocumentLoggingIn
	|		ELSE ISNULL(Balance.DocumentLoggingIn, UNDEFINED)
	|	END AS DocumentLoggingIn,
	|	DocumentTable.Period AS Period,
	|	ISNULL(Balance.ProcedureForUsingBatch, -1) AS ProcedureForUsingBatch,
	|	ISNULL(Balance.WarehouseUsageProcedure, -1) AS WarehouseUsageProcedure
	|FROM
	|	DocumentTable AS DocumentTable
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|		
	|		LEFT JOIN Catalog.VATRates AS VATRateTable
	|		ON DocumentTable.BasicVATRate = VATRateTable.Ref
	|		LEFT JOIN TTBalance AS Balance
	|		ON DocumentTable.ProductList_ = Balance.Products
	|			AND DocumentTable.CharacteristicsOfResidues = Balance.Characteristic
	|			AND DocumentTable.SeriesOfResidues = Balance.Series
	|			AND DocumentTable.LeftoversWarehouse = Balance.Warehouse
	|			AND (DocumentTable.Purpose = Balance.Purpose
	|				OR DocumentDataTable.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
	|																	VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
	|																	VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5),
	|																	VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)))
	|			AND DocumentTable.ArticleCalculationOfBalances = &EmptyValueOfCalculationArticle
	|			AND (DocumentTable.DocumentSalesOfGoodsAndServices = Balance.DocumentSalesOfGoodsAndServices
	|				OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|			AND (DocumentTable.DocumentLoggingIn = Balance.DocumentLoggingIn
	|				OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|			AND (DocumentTable.CCDNumber = Balance.CCDNumber
	|				OR DocumentTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|				OR Balance.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|				OR &WithoutSelectionByCCDNumbers)
	|			AND (DocumentTable.Period = DATETIME(1,1,1)
	|				OR DocumentTable.Period <= Balance.DateOfReceipt)
	|			AND (NOT Balance.SelectionAccordingToCommitteeSVATRate
	|				OR ((Balance.CommitteeSVATRate = VALUE(Catalog.VATRates.EmptyRef)
	|						AND NOT VATRateTable.PaymentVATRate IN (&ExcludedVATRates))
	|					OR DocumentTable.BasicVATRate = Balance.CommitteeSVATRate))
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON Keys.Ref = Balance.ItemsLocationAttributes
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionShipments
	|		ON DimensionShipments.Products = Keys.Products
	|			AND DimensionShipments.Characteristic = Keys.Characteristic
	|			AND DimensionShipments.Series = Balance.ShipmentBatch
	|			AND DimensionShipments.StorageLocation = Balance.OriginWarehouse
	|			AND DimensionShipments.Purpose = Balance.PurposeOfShipment
	|			AND DimensionShipments.ProductCostElement = Keys.ProductCostElement
	|		
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfReceipt
	|		ON DatesOfReceipt.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|			AND DatesOfReceipt.Products = Keys.Products
	|			AND DatesOfReceipt.Characteristic = Keys.Characteristic
	|			AND DatesOfReceipt.Series = Keys.Series
	|			AND DatesOfReceipt.Purpose = Keys.Purpose
	|			AND DatesOfReceipt.CCDNumber = Balance.CCDNumber
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ProductKeys
	|		ON ProductKeys.Ref = DocumentTable.ItemsLocationAttributes
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryTypeDetails
	|		ON InventoryTypeDetails.Ref = Balance.InventoryOwnerAttribute
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS DetailsOfTypeOfShipmentInventory
	|		ON DetailsOfTypeOfShipmentInventory.Ref = Balance.InventoryOwnerAttributeShipment
	|
	|ORDER BY
	|	LineNumber,
	|	DocumentRemnants DESC,
	|	Period,
	|	DocumentTable.CCDNumber = Balance.CCDNumber DESC,
	|	DateOfReceipt,
	|	DatesOfReceipt.DateOfReceipt,
	|	ProcedureForUsingBatch DESC,
	|	WarehouseUsageProcedure DESC
	|
	|TOTALS
	|	MAX(Count),
	|	MAX(QuantityByGBRN),
	|	MAX(AmountIncludingVAT),
	|	MAX(VATRate),
	|	MAX(VATAmount),
	|	MAX(CommissionAmount),
	|	MAX(AmountVATRemuneration),
	|	SUM(CountBalance),
	|	MAX(ItemsType),
	|	MAX(ExcisableGoods)
	|BY
	|	LineNumber
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP DocumentTable
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP TTTypesOfStocksInSummary";
	
	QueryTextForReplacingVATRateField(TempTablesManager, Query.Text, FillParameters);
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableOfGoodsQuantityByGBRN_",
																"TableOfGoods",
																"QuantityByGBRN",
																"SUM(CAST(TableOfGoods.QuantityByGBRN AS NUMBER(23, 11)))",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableOfGoodsExciseTaxAmount_",
																"TableOfGoods",
																"ExciseTaxAmount",
																"SUM(TableOfGoods.ExciseTaxAmount)",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableOfGoodsDocumentSalesOfGoodsAndServices_",
																"TableOfGoods",
																"DocumentSalesOfGoodsAndServices",
																"TableOfGoods.DocumentSalesOfGoodsAndServices",
																"UNDEFINED");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableOfGoodsDocumentLoggingIn_",
																"TableOfGoods",
																"DocumentLoggingIn",
																"TableOfGoods.DocumentLoggingIn",
																"UNDEFINED");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableOfGoodsPeriod_",
																"TableOfGoods",
																"Period",
																"TableOfGoods.Period",
																"DATETIME(1,1,1)");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableTypesOfStocks_ItemsLocationAttributesShipment_",
																"TableTypesOfStocks_",
																"ItemsLocationAttributesShipment",
																"TableTypesOfStocks_.ItemsLocationAttributesShipment",
																"VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableTypesOfStocks_Period_",
																"TableTypesOfStocks_",
																"Period",
																"TableTypesOfStocks_.Period",
																"DATETIME(1,1,1)");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableTypesOfStocks_QuantityByGBRN_",
																"TableTypesOfStocks_",
																"QuantityByGBRN",
																"SUM(CAST(TableTypesOfStocks_.QuantityByGBRN AS NUMBER(23, 11)))",
																"0");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableTypesOfStocks_VATAmount_",
																"TableTypesOfStocks_",
																"VATAmount",
																"SUM(TableTypesOfStocks_.VATAmount)",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableTypesOfStocks_ExciseTaxAmount_",
																"TableTypesOfStocks_",
																"ExciseTaxAmount",
																"SUM(TableTypesOfStocks_.ExciseTaxAmount)",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextBalanceTableQuantityByGBRNBalance_",
																"BalanceTable",
																"QuantityByGBRNBalance",
																"CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11))",
																"0");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextBalanceTableVATAmountBalance_",
																"BalanceTable",
																"VATAmountBalance",
																"Balance.VATAmountBalance",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextBalanceTableExciseTaxAmountBalance_",
																"BalanceTable",
																"ExciseTaxAmountBalance",
																"Balance.ExciseTaxAmountBalance",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableOfGoodsPartnerProducts_",
																"TableOfGoods",
																"PartnerProducts",
																"TableOfGoods.PartnerProducts",
																"VALUE(Catalog.ProductCrossReferences.EmptyRef)");
	
	MonitorCCDNumbers = ?(AdditionalProperties.Property("MonitorCCDNumbers"),
								AdditionalProperties.MonitorCCDNumbers,
								Undefined);
	
	EmptyValuesOfImplementationDocument = New Array;
	EmptyValuesOfImplementationDocument.Add(Documents.CustomerInvoice.EmptyRef());
	EmptyValuesOfImplementationDocument.Add(Documents.CustomerInvoiceIntercompany.EmptyRef());
	EmptyValuesOfImplementationDocument.Add(Documents.RetailSalesReport.EmptyRef());
	EmptyValuesOfImplementationDocument.Add(Undefined);
	
	EmptyValuesOfReceiptDocument = New Array;
	EmptyValuesOfReceiptDocument.Add(Documents.VendorInvoice.EmptyRef());
	EmptyValuesOfReceiptDocument.Add(Undefined);
	
	PostWithoutControlOfCompanyStockBalance = SessionParameters.PostWithoutControlOfCompanyStockBalance 
														Or Not Constants.ControlCompanyStockBalance.Get();
	
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities",
								GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("UseFinAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers",
								GetFunctionalOption("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers"));
	Query.SetParameter("WithoutSelectionByCCDNumbers", FillParameters.WithoutSelectionByCCDNumbers);
	Query.SetParameter("MonitorCCDNumbers", MonitorCCDNumbers);
	Query.SetParameter("EmptyValuesOfImplementationDocument", EmptyValuesOfImplementationDocument);
	Query.SetParameter("EmptyValuesOfRegistrationDocument", EmptyValuesOfReceiptDocument);
	Query.SetParameter("PostWithoutControlOfCompanyStockBalance",
								PostWithoutControlOfCompanyStockBalance);
	Query.SetParameter("SelectCommissionInventoryForCommitteeSTaxation",
								FillParameters.SelectCommissionInventoryForCommitteeSTaxation);
	Query.SetParameter("ExcludedVATRates", VATAccountingLocalization.ExcludedTransfersVATRates());
	Query.SetParameter("EmptyValueOfCalculationArticle", "");
	Query.SetParameter("EmptyValueOfCalculationArticle", Catalogs.ProductCostElements.EmptyRef());
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	CheckWhetherDocumentInventoryTypesNeedToBeRefilled(AdditionalProperties, Query);
	
	Query.TempTablesManager = TempTablesManager;
	
	Return Query;
	
EndFunction

// Generates a request based on information security data to fill in the document inventory types.
//
// Parameters:
//	TempTablesManager - TempTablesManager	- a temporary table Manager that contains the tables required
//															for the distribution algorithm to run.
//	AdditionalProperties	- Structure					- additional properties of the document for which
//															inventory types are filled in.
//	FillParameters - See ParametersForFillingInventoryTypes.
//
// Returns:
//	Query - request to contact the IB.
//
Function RequestDistributionBasedOnPrioritiesOfGoodsTableToBalanceTable(TempTablesManager,
																			AdditionalProperties,
																			FillParameters)
	
	If FillParameters.SelectStocksOfDifferentPeriods Then
		RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
		RequestTextParameters.SelectingCategoriesByDate = False;
		
		QueryTextTTExcisableItems = ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(
											TempTablesManager,
											RequestTextParameters);
	Else
		QueryTextTTExcisableItems = ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(
											TempTablesManager);
	EndIf;
	
	QueryText = QueryTextTTExcisableItems + Common.QueryBatchSeparator() + "
	|SELECT
	|	TableOfGoods.MaterialProviderCompany AS MaterialProviderCompany
	|INTO GiverSCompanies
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Products.ItemsType IN(
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(TableOfGoods.LineNumber)						AS LineNumber,
	|	DocumentDataTable.Date									AS DocumentDate,
	|	&FieldTextTableOfGoodsBusinessOperation_				AS BusinessOperation,
	|	TableOfGoods.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributes					AS DimensionLeftovers,
	|	ProductsTable.UnitOfMeasure						AS UnitOfMeasure,
	|	ISNULL(ProductsTable.FEACNCode.Commodity, FALSE)	AS Commodity,
	|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE)		AS ExcisableGoods,
	|	DocumentDataTable.SubjectToExcise					AS SubjectToExcise,
	|	ProductsTable.KeepRecordsByCCD							AS KeepRecordsByCCD,
	|	CASE
	|		WHEN ProductsTable.TracedGoods
	|				AND &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(DocumentDataTable.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|			THEN TRUE
	|		ELSE FALSE
	|	END														AS TracedGoods,
	|	CASE
	|		WHEN ISNULL(ProductsTable.ItemsType, UNDEFINED) = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|		ELSE ProductsTable.FinancialAccountingGroup
	|	END														AS FinancialAccountingGroup,
	|	TableOfGoods.Products									AS Products,
	|	ProductsTable.ItemsType							AS ItemsType,
	|	TableOfGoods.Characteristic								AS Characteristic,
	|	TableOfGoods.MaterialProviderCompany							AS MaterialProviderCompany,
	|	&FieldTextTableOfGoodsPartnerProducts_ 				AS PartnerProducts,
	|	TableOfGoods.Purpose									AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus IN (14, 18)
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END														AS Series,
	|	SUM(TableOfGoods.Count)							AS Count,
	|	&FieldTextTableOfGoodsQuantityByGBRN_					AS QuantityByGBRN,
	|	&FieldTextTableOfGoodsPriceKind_							AS PriceKind,
	|	&TextOfSelectionFieldTableOfProductsVATRate_					AS VATRate,
	|	&TextOfSelectionFieldVATRatesBasicVATRate_					AS BasicVATRate,
	|	&FieldTextTableOfGoodsAmountIncludingVAT_							AS AmountIncludingVAT,
	|	&FieldTextTableOfGoodsVATAmount_							AS VATAmount,
	|	&FieldTextTableOfGoodsCommissionAmount_				AS CommissionAmount,
	|	&FieldTextTableOfGoodsAmountVATRemuneration_				AS AmountVATRemuneration,
	|	&FieldTextTableOfGoodsExciseTaxAmount_						AS ExciseTaxAmount,
	|	TableOfGoods.Warehouse										AS Warehouse,
	|	TableOfGoods.CCDNumber										AS CCDNumber,
	|	ISNULL(TableOfGoods.Purpose.OrderDocument, UNDEFINED)		AS OrderDocument,
	|	&FieldTextTableOfGoodsDocumentTransfers__					AS DocumentTransfers_,
	|	&FieldTextTableOfGoodsCorItemsLocationAttributes_		AS CorItemsLocationAttributes,
	|	TableOfGoods.SelectTypesOfStocks							AS SelectTypesOfStocks
	|INTO DocumentTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|		
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON TableOfGoods.Products = ProductsTable.Ref
	|		
	|		LEFT JOIN Catalog.VATRates AS VATRates
	|		ON &FieldTextTableOfGoodsVATRate_ = VATRates.Ref
	|			AND VATRates.CalculatedRate
	|		
	|		LEFT JOIN TTExciseCategoriesOfItems AS TTExcisableItems
	|		ON TableOfGoods.Products = TTExcisableItems.Products
	|			AND &ConditionForSelectionOfExcisableItems
	|
	|WHERE
	|	ProductsTable.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|	OR ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND TableOfGoods.Products.TracedGoods
	|
	|GROUP BY
	|	DocumentDataTable.Date,
	|	&FieldTextTableOfGoodsBusinessOperation_,
	|	TableOfGoods.ItemsLocationAttributes,
	|	ProductsTable.UnitOfMeasure,
	|	ISNULL(ProductsTable.FEACNCode.Commodity, FALSE),
	|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE),
	|	DocumentDataTable.SubjectToExcise,
	|	ProductsTable.KeepRecordsByCCD,
	|	TableOfGoods.Products.FinancialAccountingGroup,
	|	CASE
	|		WHEN ProductsTable.TracedGoods
	|				AND &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(DocumentDataTable.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN ISNULL(ProductsTable.ItemsType, UNDEFINED) = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|		ELSE ProductsTable.FinancialAccountingGroup
	|	END,
	|	TableOfGoods.Products,
	|	ProductsTable.ItemsType,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.MaterialProviderCompany,
	|	&FieldTextTableOfGoodsPartnerProducts_,
	|	TableOfGoods.Purpose,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus IN (14, 18)
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	&FieldTextTableOfGoodsPriceKind_,
	|	&TextOfDimensionFieldTableOfProductsVATRate_,
	|	&TextOfVATRateDimensionFieldBasicVATRate_,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.CCDNumber,
	|	ISNULL(TableOfGoods.Purpose.OrderDocument, UNDEFINED),
	|	&FieldTextTableOfGoodsDocumentTransfers__,
	|	&FieldTextTableOfGoodsCorItemsLocationAttributes_,
	|	TableOfGoods.SelectTypesOfStocks
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentDataTable.Date						AS Period,
	|	DocumentDataTable.Organization				AS Organization,
	|	DocumentDataTable.Partner					AS GoodsOwner,
	|	DocumentDataTable.Counterparty				AS Counterparty,
	|	DocumentDataTable.Terms				AS Terms,
	|	DocumentDataTable.Contract					AS Contract,
	|	DocumentDataTable.BusinessOperation	AS BusinessOperation,
	|	DocumentDataTable.Currency					AS Currency,
	|	DocumentDataTable.VATTaxation		AS VATTaxation,
	|	DocumentDataTable.InventoryType				AS InventoryType,
	|	DocumentDataTable.SubjectToExcise		AS SubjectToExcise,
	|	DocumentDataTable.BusinessUnitProduction AS BusinessUnitProduction,
	|	VALUE(Catalog.InventoryAccountingGroups.EmptyRef) AS FinancialAccountingGroup
	|FROM
	|	DocumentDataTable AS DocumentDataTable
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber					AS LineNumber,
	|	CASE
	|		WHEN DefaultStockTypes.InventoryType IS NULL
	|				AND DocumentTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.InventoryTypes.Work_5)
	|		ELSE DefaultStockTypes.InventoryType
	|	END											AS InventoryType,
	|	DefaultStockTypes.GoodsOwner			AS GoodsOwner,
	|	DefaultStockTypes.Counterparty				AS Counterparty,
	|	DefaultStockTypes.Contract					AS Contract,
	|	DocumentTable.Warehouse							AS Warehouse,
	|	DocumentTable.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	DocumentTable.UnitOfMeasure				AS UnitOfMeasure,
	|	DocumentTable.Commodity					AS Commodity,
	|	CASE
	|		WHEN DocumentTable.SubjectToExcise
	|			THEN DocumentTable.ExcisableGoods
	|		ELSE FALSE
	|	END 											AS SubjectToExcise,
	|	CASE
	|		WHEN &UseFinAccountingGroups
	|			THEN ISNULL(DocumentTable.FinancialAccountingGroup, VALUE(Catalog.InventoryAccountingGroups.EmptyRef))
	|		ELSE VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|	END											AS FinancialAccountingGroup,
	|	DocumentTable.Products					AS Products,
	|	DocumentTable.PartnerProducts 			AS PartnerProducts,
	|	DocumentTable.Characteristic					AS Characteristic,
	|	DocumentTable.Series							AS Series,
	|	DocumentTable.MaterialProviderCompany				AS MaterialProviderCompany,
	|	DocumentTable.Count						AS Count,
	|	CAST(DocumentTable.QuantityByGBRN AS NUMBER(23, 11))	AS QuantityByGBRN,
	|	DocumentTable.CCDNumber						AS CCDNumber,
	|	DocumentTable.PriceKind						AS PriceKind,
	|	DocumentTable.VATRate						AS VATRate,
	|	DocumentTable.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	DocumentTable.BusinessOperation			AS BusinessOperation
	|FROM
	|	DocumentTable AS DocumentTable
	|		LEFT JOIN TableOfDetailsOfStockTypesByDefault AS DefaultStockTypes
	|		ON DefaultStockTypes.LineNumber = DocumentTable.LineNumber
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(TableTypesOfStocks_.LineNumber)			AS LineNumber,
	|	DocumentDataTable.Date							AS DocumentDate,
	|	DocumentDataTable.Organization					AS DocumentOrganization,
	|	DocumentDataTable.VATTaxation			AS TaxationOfVAT,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	&FieldTextTableTypesOfStocks_DocumentTransfers__		AS DocumentTransfers_,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType			AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Organization			AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner		AS GoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.VATTaxation	AS VATTaxation,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	&FieldTextTableTypesOfStocks_ItemsLocationAttributesShipment_ AS ItemsLocationAttributesShipment,
	|	&FieldTextTableTypesOfStocks_InventoryOwnerAttributeShipment_		AS InventoryOwnerAttributeShipment,
	|	&FieldTextTableTypesOfStocks_CorInventoryOwnerAttribute_			AS CorInventoryOwnerAttribute,
	|	SUM(TableTypesOfStocks_.Count)				AS Count,
	|	&FieldTextTableTypesOfStocks_QuantityByGBRN_		AS QuantityByGBRN,
	|	&FieldTextTableTypesOfStocks_ExciseTaxAmount_			AS ExciseTaxAmount,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually		AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocksSummary
	|FROM
	|	TableTypesOfStocks_ AS TableTypesOfStocks_
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|
	|GROUP BY
	|	DocumentDataTable.Date,
	|	DocumentDataTable.Organization,
	|	DocumentDataTable.VATTaxation,
	|	TableTypesOfStocks_.ItemsLocationAttributes,
	|	&FieldTextTableTypesOfStocks_DocumentTransfers__,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.VATTaxation,
	|	TableTypesOfStocks_.CCDNumber,
	|	&FieldTextTableTypesOfStocks_ItemsLocationAttributesShipment_,
	|	&FieldTextTableTypesOfStocks_InventoryOwnerAttributeShipment_,
	|	&FieldTextTableTypesOfStocks_CorInventoryOwnerAttribute_,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	CCDNumber,
	|	DocumentTransfers_,
	|	ItemsLocationAttributesShipment,
	|	InventoryOwnerAttributeShipment,
	|	CorInventoryOwnerAttribute
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemainsGrouped.Priority							AS Priority,
	|	RemainsGrouped.Organization							AS Organization,
	|	RemainsGrouped.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	RemainsGrouped.DocumentTransfers_						AS DocumentTransfers_,
	|	RemainsGrouped.Products							AS Products,
	|	RemainsGrouped.Characteristic						AS Characteristic,
	|	RemainsGrouped.Purpose							AS Purpose,
	|	RemainsGrouped.Series								AS Series,
	|	RemainsGrouped.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	RemainsGrouped.InventoryType							AS InventoryType,
	|	RemainsGrouped.OrganizationOfInventoryType				AS OrganizationOfInventoryType,
	|	RemainsGrouped.GoodsOwner						AS GoodsOwner,
	|	RemainsGrouped.VATTaxationOfInventoryKind		AS VATTaxationOfInventoryKind,
	|	RemainsGrouped.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage AS RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage,
	|	RemainsGrouped.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction AS RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction,
	|	RemainsGrouped.CCDNumber								AS CCDNumber,
	|	RemainsGrouped.DateOfReceipt						AS DateOfReceipt,
	|	RemainsGrouped.ShipmentCompany					AS ShipmentCompany,
	|	RemainsGrouped.ItemsLocationAttributesShipment	AS ItemsLocationAttributesShipment,
	|	RemainsGrouped.InventoryOwnerAttributeShipment					AS InventoryOwnerAttributeShipment,
	|	RemainsGrouped.CorInventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|	RemainsGrouped.QuantityBalanceTotal				AS QuantityBalanceTotal,
	|	SUM(RemainsGrouped.CountBalance)				AS CountBalance,
	|	RemainsGrouped.QuantityByRNPTBalanceTotal			AS QuantityByRNPTBalanceTotal,
	|	RemainsGrouped.SubjectToExcise					AS SubjectToExcise,
	|	MAX(RemainsGrouped.ExciseTaxAmountBalance)			AS ExciseTaxAmountBalance,
	|	MAX(RemainsGrouped.SumBalance)				AS SumBalance,
	|	RemainsGrouped.SelectionAccordingToCommitteeSVATRate			AS SelectionAccordingToCommitteeSVATRate,
	|	RemainsGrouped.CommitteeSVATRate					AS CommitteeSVATRate
	|INTO TTBalance
	|FROM
	|	(
	// An attempt to save the types of stocks selected in the document - if the selected quantity is covered by the current Balance, a high priority is set for it
	|	SELECT
	|		CASE
	|			WHEN TableTypesOfStocksSummary.InventoryOwnerAttributesAreSpecifiedManually
	|				THEN 1
	|			WHEN Balance.Organization IN(SELECT GiverSCompanies.MaterialProviderCompany FROM GiverSCompanies AS GiverSCompanies)
	|					AND NOT ISNULL(InventoryKinds.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|				THEN 3
	|			WHEN Balance.Organization = DocumentAttributes.Organization
	|					AND NOT ISNULL(InventoryKinds.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|				THEN 5
	|			ELSE 7
	|		END										AS Priority,
	|		Balance.Organization							AS Organization,
	|		Balance.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|		Balance.DocumentTransfers_					AS DocumentTransfers_,
	|		Balance.Products						AS Products,
	|		Balance.Characteristic						AS Characteristic,
	|		Balance.Purpose							AS Purpose,
	|		Balance.Series								AS Series,
	|		Balance.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|		InventoryKinds.InventoryType						AS InventoryType,
	|		InventoryKinds.Organization						AS OrganizationOfInventoryType,
	|		InventoryKinds.GoodsOwner					AS GoodsOwner,
	|		InventoryKinds.VATTaxation				AS VATTaxationOfInventoryKind,
	|		InventoryKinds.Contract.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage AS RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage,
	|		InventoryKinds.Contract.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction AS RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction,
	|		Balance.CCDNumber							AS CCDNumber,
	|		Balance.DateOfReceipt						AS DateOfReceipt,
	|		DocumentAttributes.Organization				AS ShipmentCompany,
	|		Balance.ItemsLocationAttributesShipment	AS ItemsLocationAttributesShipment,
	|		Balance.InventoryOwnerAttributeShipment					AS InventoryOwnerAttributeShipment,
	|		Balance.CorInventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|		Balance.CountBalance					AS QuantityBalanceTotal,
	|		CASE
	|			WHEN TableTypesOfStocksSummary.Count <= Balance.CountBalance
	|				THEN TableTypesOfStocksSummary.Count
	|			ELSE Balance.CountBalance
	|		END										AS CountBalance,
	|		&FieldTextBalanceTableQuantityByGBRNBalance_ AS QuantityByRNPTBalanceTotal,
	|		InventoryKinds.SubjectToExcise				AS SubjectToExcise,
	|		CASE
	|			WHEN TableTypesOfStocksSummary.Count <= Balance.CountBalance
	|				THEN TableTypesOfStocksSummary.ExciseTaxAmount
	|			WHEN TableTypesOfStocksSummary.Count = 0
	|				THEN 0
	|			ELSE Balance.CountBalance * TableTypesOfStocksSummary.ExciseTaxAmount / TableTypesOfStocksSummary.Count
	|		END										AS ExciseTaxAmountBalance,
	|		CASE
	|			WHEN Balance.CountBalance <> 0
	|				THEN Balance.SumBalance
	|			ELSE 0
	|		END										AS SumBalance,
	|		CASE
	|			WHEN NOT AvailableTypesOfStocks.InventoryOwnerAttribute IS NULL
	|				THEN AvailableTypesOfStocks.SelectionAccordingToCommitteeSVATRate
	|			ELSE FALSE
	|		END										AS SelectionAccordingToCommitteeSVATRate,
	|		CASE
	|			WHEN NOT AvailableTypesOfStocks.InventoryOwnerAttribute IS NULL
	|				THEN AvailableTypesOfStocks.CommitteeSVATRate
	|			ELSE UNDEFINED
	|		END										AS CommitteeSVATRate
	|	FROM
	|		BalanceTable AS Balance
	|			INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|			ON Balance.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|			INNER JOIN DocumentDataTable AS DocumentAttributes
	|			ON TRUE
	|			
	|			INNER JOIN TableTypesOfStocksSummary AS TableTypesOfStocksSummary
	|			ON Balance.ItemsLocationAttributes = TableTypesOfStocksSummary.ItemsLocationAttributes
	|				AND Balance.InventoryOwnerAttribute = TableTypesOfStocksSummary.InventoryOwnerAttribute
	|				AND Balance.CCDNumber = TableTypesOfStocksSummary.CCDNumber
	|				AND Balance.DocumentTransfers_ = TableTypesOfStocksSummary.DocumentTransfers_
	|				AND Balance.ItemsLocationAttributesShipment = TableTypesOfStocksSummary.ItemsLocationAttributesShipment
	|				AND Balance.InventoryOwnerAttributeShipment = TableTypesOfStocksSummary.InventoryOwnerAttributeShipment
	|				AND Balance.CorInventoryOwnerAttribute = TableTypesOfStocksSummary.CorInventoryOwnerAttribute
	|			
	|			LEFT JOIN AvailableTypesOfStocks AS AvailableTypesOfStocks
	|			ON Balance.InventoryOwnerAttribute = AvailableTypesOfStocks.InventoryOwnerAttribute
	|				AND &SelectCommissionInventoryForCommitteeSTaxation
	|	
	|	UNION ALL
	|	
	// Adding Balances of inventory types missing from the document - added with low priority
	|	SELECT
	|		CASE
	|			WHEN ISNULL(TableTypesOfStocksSummary.InventoryOwnerAttributesAreSpecifiedManually, FALSE)
	|				THEN 2
	|			WHEN Balance.Organization IN(SELECT GiverSCompanies.MaterialProviderCompany FROM GiverSCompanies AS GiverSCompanies)
	|					AND NOT ISNULL(InventoryKinds.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|				THEN 4
	|			WHEN Balance.Organization = DocumentAttributes.Organization
	|					AND NOT ISNULL(InventoryKinds.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|				THEN 6
	|			ELSE 8
	|		END										AS Priority,
	|		Balance.Organization							AS Organization,
	|		Balance.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|		Balance.DocumentTransfers_					AS DocumentTransfers_,
	|		Balance.Products						AS Products,
	|		Balance.Characteristic						AS Characteristic,
	|		Balance.Purpose							AS Purpose,
	|		Balance.Series								AS Series,
	|		Balance.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|		InventoryKinds.InventoryType						AS InventoryType,
	|		InventoryKinds.Organization						AS OrganizationOfInventoryType,
	|		InventoryKinds.GoodsOwner					AS GoodsOwner,
	|		InventoryKinds.VATTaxation				AS VATTaxationOfInventoryKind,
	|		InventoryKinds.Contract.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage AS RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage,
	|		InventoryKinds.Contract.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction AS RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction,
	|		Balance.CCDNumber							AS CCDNumber,
	|		Balance.DateOfReceipt						AS DateOfReceipt,
	|		DocumentAttributes.Organization				AS ShipmentCompany,
	|		Balance.ItemsLocationAttributesShipment	AS ItemsLocationAttributesShipment,
	|		Balance.InventoryOwnerAttributeShipment					AS InventoryOwnerAttributeShipment,
	|		Balance.CorInventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|		Balance.CountBalance					AS QuantityBalanceTotal,
	|		CASE
	|			WHEN Balance.CountBalance > ISNULL(TableTypesOfStocksSummary.Count, 0)
	|				THEN Balance.CountBalance - ISNULL(TableTypesOfStocksSummary.Count, 0)
	|			ELSE 0
	|		END										AS CountBalance,
	|		&FieldTextBalanceTableQuantityByGBRNBalance_ AS QuantityByRNPTBalanceTotal,
	|		InventoryKinds.SubjectToExcise				AS SubjectToExcise,
	|		&FieldTextBalanceTableExciseTaxAmountBalance_ AS ExciseTaxAmountBalance,
	|		CASE
	|			WHEN Balance.CountBalance <> 0
	|				THEN Balance.SumBalance
	|			ELSE 0
	|		END										AS SumBalance,
	|		CASE
	|			WHEN NOT AvailableTypesOfStocks.InventoryOwnerAttribute IS NULL
	|				THEN AvailableTypesOfStocks.SelectionAccordingToCommitteeSVATRate
	|			ELSE FALSE
	|		END										AS SelectionAccordingToCommitteeSVATRate,
	|		CASE
	|			WHEN NOT AvailableTypesOfStocks.InventoryOwnerAttribute IS NULL
	|				THEN AvailableTypesOfStocks.CommitteeSVATRate
	|			ELSE UNDEFINED
	|		END										AS CommitteeSVATRate
	|	FROM
	|		BalanceTable AS Balance
	|			INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|			ON Balance.InventoryOwnerAttribute = InventoryKinds.Ref
	|			
	|			INNER JOIN DocumentDataTable AS DocumentAttributes
	|			ON TRUE
	|			
	|			LEFT JOIN TableTypesOfStocksSummary AS TableTypesOfStocksSummary
	|			ON Balance.ItemsLocationAttributes = TableTypesOfStocksSummary.ItemsLocationAttributes
	|				AND Balance.InventoryOwnerAttribute = TableTypesOfStocksSummary.InventoryOwnerAttribute
	|				AND Balance.CCDNumber = TableTypesOfStocksSummary.CCDNumber
	|				AND Balance.DocumentTransfers_ = TableTypesOfStocksSummary.DocumentTransfers_
	|				AND Balance.ItemsLocationAttributesShipment = TableTypesOfStocksSummary.ItemsLocationAttributesShipment
	|				AND Balance.InventoryOwnerAttributeShipment = TableTypesOfStocksSummary.InventoryOwnerAttributeShipment
	|				AND Balance.CorInventoryOwnerAttribute = TableTypesOfStocksSummary.CorInventoryOwnerAttribute
	|			
	|			LEFT JOIN AvailableTypesOfStocks AS AvailableTypesOfStocks
	|			ON Balance.InventoryOwnerAttribute = AvailableTypesOfStocks.InventoryOwnerAttribute
	|				AND &SelectCommissionInventoryForCommitteeSTaxation
	|	
	|	UNION ALL
	|	
	// Adding inventory types selected in the document with Balance control disabled - we carry out as is with the old inventory types
	|	SELECT
	|		0                                                           AS Priority,
	|		TableTypesOfStocksSummary.Organization                        AS Organization,
	|		TableTypesOfStocksSummary.ItemsLocationAttributes         AS ItemsLocationAttributes,
	|		TableTypesOfStocksSummary.DocumentTransfers_                   AS DocumentTransfers_,
	|		Dimension.Products                                      AS Products,
	|		Dimension.Characteristic                                    AS Characteristic,
	|		Dimension.Purpose                                        AS Purpose,
	|		Dimension.Series                                             AS Series,
	|		TableTypesOfStocksSummary.InventoryOwnerAttribute                         AS InventoryOwnerAttribute,
	|		InventoryKinds.InventoryType                                      AS InventoryType,
	|		InventoryKinds.Organization                                     AS OrganizationOfInventoryType,
	|		InventoryKinds.GoodsOwner                                  AS GoodsOwner,
	|		InventoryKinds.VATTaxation                              AS VATTaxationOfInventoryKind,
	|		InventoryKinds.Contract.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage      AS RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage,
	|		InventoryKinds.Contract.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction AS RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction,
	|		TableTypesOfStocksSummary.CCDNumber                           AS CCDNumber,
	|		DATETIME(1, 1, 1)                                          AS DateOfReceipt,
	|		DocumentAttributes.Organization                              AS ShipmentCompany,
	|		TableTypesOfStocksSummary.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|		TableTypesOfStocksSummary.InventoryOwnerAttributeShipment                 AS InventoryOwnerAttributeShipment,
	|		TableTypesOfStocksSummary.CorInventoryOwnerAttribute                      AS CorInventoryOwnerAttribute,
	|		TableTypesOfStocksSummary.Count                         AS QuantityBalanceTotal,
	|		TableTypesOfStocksSummary.Count                         AS CountBalance,
	|		TableTypesOfStocksSummary.QuantityByGBRN                   AS QuantityByRNPTBalanceTotal,
	|		InventoryKinds.SubjectToExcise                               AS SubjectToExcise,
	|		TableTypesOfStocksSummary.ExciseTaxAmount                        AS ExciseTaxAmountBalance,
	|		0                                                           AS SumBalance,
	|		FALSE                                                        AS SelectionAccordingToCommitteeSVATRate,
	|		UNDEFINED                                                AS CommitteeSVATRate
	|	FROM
	|		TableTypesOfStocksSummary AS TableTypesOfStocksSummary
	|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|			ON TableTypesOfStocksSummary.ItemsLocationAttributes = Dimension.Ref
	|			
	|			INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|			ON TableTypesOfStocksSummary.InventoryOwnerAttribute = InventoryKinds.Ref
	|			
	|			INNER JOIN DocumentDataTable AS DocumentAttributes
	|			ON InventoryKinds.Organization = DocumentAttributes.Organization
	|	
	|	WHERE
	|		TableTypesOfStocksSummary.InventoryOwnerAttributesAreSpecifiedManually = TRUE
	|		AND &PostWithoutControlOfCompanyStockBalance = TRUE
	|	
	|	) AS RemainsGrouped
	|
	|GROUP BY
	|	RemainsGrouped.Priority,
	|	RemainsGrouped.Organization,
	|	RemainsGrouped.ItemsLocationAttributes,
	|	RemainsGrouped.DocumentTransfers_,
	|	RemainsGrouped.Products,
	|	RemainsGrouped.Characteristic,
	|	RemainsGrouped.Purpose,
	|	RemainsGrouped.Series,
	|	RemainsGrouped.InventoryOwnerAttribute,
	|	RemainsGrouped.InventoryType,
	|	RemainsGrouped.OrganizationOfInventoryType,
	|	RemainsGrouped.GoodsOwner,
	|	RemainsGrouped.VATTaxationOfInventoryKind,
	|	RemainsGrouped.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage,
	|	RemainsGrouped.SubjectToExcise,
	|	RemainsGrouped.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction,
	|	RemainsGrouped.CCDNumber,
	|	RemainsGrouped.DateOfReceipt,
	|	RemainsGrouped.ShipmentCompany,
	|	RemainsGrouped.ItemsLocationAttributesShipment,
	|	RemainsGrouped.InventoryOwnerAttributeShipment,
	|	RemainsGrouped.CorInventoryOwnerAttribute,
	|	RemainsGrouped.QuantityBalanceTotal,
	|	RemainsGrouped.QuantityByRNPTBalanceTotal,
	|	RemainsGrouped.SelectionAccordingToCommitteeSVATRate,
	|	RemainsGrouped.CommitteeSVATRate
	|
	|HAVING
	|	SUM(RemainsGrouped.CountBalance) <> 0
	|	OR MAX(RemainsGrouped.SumBalance) <> 0
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	CCDNumber
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	// Document data
	|	ISNULL(Balance.Priority, 0)						AS Priority,
	|	DocumentTable.LineNumber						AS LineNumber,
	|	DocumentTable.DocumentDate						AS DocumentDate,
	|	DocumentTable.BusinessOperation				AS BusinessOperation,
	|	DocumentTable.Warehouse								AS Warehouse,
	|	DocumentTable.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	DocumentTable.UnitOfMeasure					AS UnitOfMeasure,
	|	DocumentTable.Commodity						AS Commodity,
	|	DocumentTable.ExcisableGoods					AS ExcisableGoods,
	|	DocumentTable.FinancialAccountingGroup				AS FinancialAccountingGroup,
	|	DocumentTable.Products						AS Products,
	|	DocumentTable.ItemsType					AS ItemsType,
	|	DocumentTable.Characteristic						AS Characteristic,
	|	DocumentTable.MaterialProviderCompany					AS MaterialProviderCompany,
	|	DocumentTable.PartnerProducts 				AS PartnerProducts,	
	|	DocumentTable.Purpose							AS Purpose,
	|	DocumentTable.Series								AS Series,
	|	DocumentTable.Count							AS Count,
	|	CAST(DocumentTable.QuantityByGBRN AS NUMBER(23, 11))	AS QuantityByGBRN,
	|	DocumentTable.VATRate							AS VATRate,
	|	DocumentTable.AmountIncludingVAT							AS AmountIncludingVAT,
	|	DocumentTable.VATAmount							AS VATAmount,
	|	DocumentTable.CommissionAmount				AS CommissionAmount,
	|	DocumentTable.AmountVATRemuneration				AS AmountVATRemuneration,
	|	DocumentTable.ExciseTaxAmount						AS ExciseTaxAmount,
	|	DocumentTable.CorItemsLocationAttributes		AS CorItemsLocationAttributes,
	|
	// balance data
	|	ISNULL(Balance.InventoryOwnerAttribute, UNDEFINED)			AS InventoryOwnerAttribute,
	|	ISNULL(Balance.InventoryType, UNDEFINED)			AS InventoryType,
	|	ISNULL(Balance.OrganizationOfInventoryType, UNDEFINED) AS OrganizationOfBalance,
	|	ISNULL(Balance.GoodsOwner, UNDEFINED)		AS GoodsOwner,
	|	ISNULL(Balance.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage, UNDEFINED) AS RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage,
	|	ISNULL(Balance.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction, UNDEFINED) AS RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction,
	|	ISNULL(Balance.CCDNumber, UNDEFINED)			AS CCDNumber,
	|	CASE
	|		WHEN &MonitorCCDNumbers = FALSE
	|				OR NOT DocumentTable.KeepRecordsByCCD
	|			THEN FALSE
	|		WHEN &MonitorCCDNumbers = TRUE
	|				AND DocumentTable.KeepRecordsByCCD
	|				AND (Balance.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|					OR Balance.CCDNumber IS NULL)
	|			THEN TRUE
	|		WHEN (DocumentTable.TracedGoods
	|					OR (DocumentTable.KeepRecordsByCCD
	|						AND &RestrictTransactionsWithImportedGoodsWithoutCCDNumbers))
	|				AND (Balance.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|					OR Balance.CCDNumber IS NULL)
	|			THEN TRUE
	|		ELSE FALSE
	|	END												AS NotCCDNumberIsSpecified,
	|	DocumentTable.TracedGoods				AS TracedGoods,
	|	ISNULL(Balance.ShipmentCompany, UNDEFINED)	AS ShipmentCompany,
	|	ISNULL(Balance.DateOfReceipt, DATETIME(2399, 1, 1)) AS DateOfReceipt,
	|	ISNULL(Balance.DocumentTransfers_, UNDEFINED)	AS DocumentTransfers_,
	|	ISNULL(Balance.ItemsLocationAttributesShipment, UNDEFINED) AS ItemsLocationAttributesShipment,
	|	ISNULL(Balance.InventoryOwnerAttributeShipment, UNDEFINED)	AS InventoryOwnerAttributeShipment,
	|	ISNULL(Balance.CorInventoryOwnerAttribute, VALUE(Catalog.InventoryKinds.EmptyRef)) AS CorInventoryOwnerAttribute,
	|	ISNULL(DocumentTable.OrderDocument, UNDEFINED)		AS OrderDocument,
	|	ISNULL(Balance.QuantityBalanceTotal, 0)			AS QuantityBalanceTotal,
	|	ISNULL(Balance.CountBalance, 0)				AS CountBalance,
	|	ISNULL(Balance.QuantityByRNPTBalanceTotal, 0)	AS QuantityByRNPTBalanceTotal,
	|	ISNULL(Balance.SumBalance, 0)					AS SumBalance,
	|	ISNULL(Balance.ExciseTaxAmountBalance, 0)				AS ExciseTaxAmountBalance,
	|
	// data for generating a new type of inventory by intercampany
	|	ISNULL(Setting.GoodsTransferMethod, VALUE(Enum.GoodsTransferMethods.NotTransferred)) AS TransferSetting,
	|	CASE
	|		WHEN NOT Setting.CompanyOwner IS NULL
	|			THEN Setting.CompanyOwner
	|		ELSE UNDEFINED
	|	END												AS NewTypeOfInventoryProductOwner,
	|	CASE
	|		WHEN NOT Setting.Contract IS NULL
	|			THEN Setting.Contract
	|		ELSE UNDEFINED
	|	END												AS NewKindOfInventoryContract,
	|	ISNULL(Setting.Currency, UNDEFINED)			AS NewKindOfStockCurrency,
	|	CASE WHEN NOT Setting.CompanyOwner IS NULL
	|		THEN Setting.CompanyOwner
	|		ELSE UNDEFINED
	|	END												AS NewTypeOfInventoryCounterparty,
	|	CASE
	|		WHEN ISNULL(Setting.GoodsTransferMethod, VALUE(Enum.GoodsTransferMethods.EmptyRef)) = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|				AND ISNULL(Balance.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TRUE
	|		ELSE FALSE
	|	END												AS NewKindOfInventoryIsSubCommission,
	|	ISNULL(Balance.VATTaxationOfInventoryKind, UNDEFINED) AS NewTypeOfInventoryTaxationOfPrincipal,
	|	CASE
	|		WHEN ISNULL(Setting.GoodsTransferMethod, VALUE(Enum.GoodsTransferMethods.NotTransferred)) = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|			THEN VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END												AS NewTypeOfInventoryTypeOfInventory,
	|	DocumentTable.CCDNumber = Balance.CCDNumber		AS CCDNumberMatches
	|FROM
	|	DocumentTable AS DocumentTable
	|		LEFT JOIN Catalog.VATRates AS VATRateTable
	|		ON DocumentTable.BasicVATRate = VATRateTable.Ref
	|		LEFT JOIN TTBalance AS Balance
	|		ON DocumentTable.DimensionLeftovers = Balance.ItemsLocationAttributes
	|			AND (DocumentTable.DocumentTransfers_ = Balance.DocumentTransfers_
	|				OR DocumentTable.DocumentTransfers_ = UNDEFINED
	|					AND DocumentTable.SelectTypesOfStocks)
	|			AND (DocumentTable.CCDNumber = Balance.CCDNumber
	|				OR DocumentTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|				OR Balance.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef))
	|			AND (NOT Balance.SelectionAccordingToCommitteeSVATRate
	|				OR ((Balance.CommitteeSVATRate = VALUE(Catalog.VATRates.EmptyRef)
	|						AND NOT VATRateTable.PaymentVATRate IN (&ExcludedVATRates))
	|					OR DocumentTable.BasicVATRate = Balance.CommitteeSVATRate))
	|
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfReceipt
	|		ON DatesOfReceipt.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|			AND DatesOfReceipt.Products = Balance.Products
	|			AND DatesOfReceipt.Characteristic = Balance.Characteristic
	|			AND DatesOfReceipt.Series = Balance.Series
	|			AND DatesOfReceipt.Purpose = Balance.Purpose
	|			AND DatesOfReceipt.CCDNumber = Balance.CCDNumber
	|		
	|		LEFT JOIN InformationRegister.CustomizeCustomerInvoiceIntercompany AS Setting
	|		ON Balance.InventoryType = Setting.InventoryType
	|			AND Balance.OrganizationOfInventoryType = Setting.CompanyOwner
	|			AND Balance.ShipmentCompany = Setting.CompanyCustomer
	|
	|ORDER BY
	|	LineNumber ASC,
	|	&PriorityOfSelectionOfExcisableInventory,
	|	Priority ASC,
	|	DateOfReceipt ASC,
	|	DatesOfReceipt.DateOfReceipt ASC,
	|	DocumentTable.CCDNumber = Balance.CCDNumber DESC,
	|	InventoryType,
	|	OrganizationOfBalance,
	|	GoodsOwner,
	|	InventoryOwnerAttribute
	|
	|TOTALS
	|	MAX(Count),
	|	MAX(QuantityByGBRN),
	|	MAX(AmountIncludingVAT),
	|	MAX(VATRate),
	|	MAX(MaterialProviderCompany),
	|	MAX(VATAmount),
	|	MAX(CommissionAmount),
	|	MAX(AmountVATRemuneration),
	|	SUM(CountBalance),
	|	MAX(ItemsType),
	|	MAX(ExcisableGoods)
	|BY
	|	LineNumber
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP GiverSCompanies
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP DocumentTable
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|DROP TableTypesOfStocksSummary";
	
#Region ReplacingUseOfOptionalFields	

	QueryTextForReplacingVATRateField(TempTablesManager, QueryText, FillParameters);
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsQuantityByGBRN_",
																"TableOfGoods",
																"QuantityByGBRN",
																"SUM(CAST(TableOfGoods.QuantityByGBRN AS NUMBER(23, 11)))",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsExciseTaxAmount_",
																"TableOfGoods",
																"ExciseTaxAmount",
																"SUM(TableOfGoods.ExciseTaxAmount)",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsPriceKind_",
																"TableOfGoods",
																"PriceKind",
																"TableOfGoods.PriceKind",
																"VALUE(Catalog.VendorPriceTypes.EmptyRef)");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsDocumentTransfers__",
																"TableOfGoods",
																"DocumentTransfers_",
																"TableOfGoods.DocumentTransfers_",
																"UNDEFINED");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsCorItemsLocationAttributes_",
																"TableOfGoods",
																"CorItemsLocationAttributes",
																"TableOfGoods.CorItemsLocationAttributes",
																"TableOfGoods.ItemsLocationAttributes");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsBusinessOperation_",
																"TableOfGoods",
																"BusinessOperation",
																"TableOfGoods.BusinessOperation",
																"DocumentDataTable.BusinessOperation");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsAmountIncludingVAT_",
																"TableOfGoods",
																"AmountIncludingVAT",
																"SUM(TableOfGoods.AmountIncludingVAT)",
																"0");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsVATAmount_",
																"TableOfGoods",
																"VATAmount",
																"SUM(TableOfGoods.VATAmount)",
																"0");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsCommissionAmount_",
																"TableOfGoods",
																"CommissionAmount",
																"SUM(TableOfGoods.CommissionAmount)",
																"0");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsAmountVATRemuneration_",
																"TableOfGoods",
																"AmountVATRemuneration",
																"SUM(TableOfGoods.AmountVATRemuneration)",
																"0");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableTypesOfStocks_DocumentTransfers__",
																"TableTypesOfStocks_",
																"DocumentTransfers_",
																"TableTypesOfStocks_.DocumentTransfers_",
																"UNDEFINED");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableTypesOfStocks_ItemsLocationAttributesShipment_",
																"TableTypesOfStocks_",
																"ItemsLocationAttributesShipment",
																"TableTypesOfStocks_.ItemsLocationAttributesShipment",
																"UNDEFINED");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableTypesOfStocks_InventoryOwnerAttributeShipment_",
																"TableTypesOfStocks_",
																"InventoryOwnerAttributeShipment",
																"TableTypesOfStocks_.InventoryOwnerAttributeShipment",
																"UNDEFINED");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableTypesOfStocks_CorInventoryOwnerAttribute_",
																"TableTypesOfStocks_",
																"CorInventoryOwnerAttribute",
																"TableTypesOfStocks_.CorInventoryOwnerAttribute",
																"VALUE(Catalog.InventoryKinds.EmptyRef)");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableTypesOfStocks_QuantityByGBRN_",
																"TableTypesOfStocks_",
																"QuantityByGBRN",
																"SUM(CAST(TableTypesOfStocks_.QuantityByGBRN AS NUMBER(23, 11)))",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableTypesOfStocks_ExciseTaxAmount_",
																"TableTypesOfStocks_",
																"ExciseTaxAmount",
																"SUM(TableTypesOfStocks_.ExciseTaxAmount)",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextBalanceTableQuantityByGBRNBalance_",
																"BalanceTable",
																"QuantityByGBRNBalance",
																"CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11))",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextBalanceTableExciseTaxAmountBalance_",
																"BalanceTable",
																"ExciseTaxAmountBalance",
																"Balance.ExciseTaxAmountBalance",
																"0");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																QueryText,
																"&FieldTextTableOfGoodsPartnerProducts_",
																"TableOfGoods",
																"PartnerProducts",
																"TableOfGoods.PartnerProducts",
																"VALUE(Catalog.ProductCrossReferences.EmptyRef)");
	
	#EndRegion
	
	MonitorCCDNumbers = ?(AdditionalProperties.Property("MonitorCCDNumbers"),
								AdditionalProperties.MonitorCCDNumbers,
								Undefined);
	PostWithoutControlOfCompanyStockBalance = SessionParameters.PostWithoutControlOfCompanyStockBalance 
														Or Not Constants.ControlCompanyStockBalance.Get();
	
	TextConditionsForSelectionOfExcisableItems = ?(FillParameters.SelectStocksOfDifferentPeriods,
											"TableOfGoods.Period = TTExcisableItems.Period",
											"TRUE");
	TextPriorityOfSelectionOfExcisableInventory = ?(FillParameters.PriorityOfSelectionOfExcisableInventory,
												"ISNULL(Balance.SubjectToExcise, FALSE) DESC,",
												"");
	
	QueryText = StrReplace(QueryText,
								"&PriorityOfSelectionOfExcisableInventory,",
								TextPriorityOfSelectionOfExcisableInventory);
	QueryText = StrReplace(QueryText, "&ConditionForSelectionOfExcisableItems", TextConditionsForSelectionOfExcisableItems);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("UseFinAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities",
								GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("PostWithoutControlOfCompanyStockBalance",
								PostWithoutControlOfCompanyStockBalance);
	Query.SetParameter("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers",
								GetFunctionalOption("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers"));
	Query.SetParameter("MonitorCCDNumbers", MonitorCCDNumbers);
	Query.SetParameter("SelectCommissionInventoryForCommitteeSTaxation",
								FillParameters.SelectCommissionInventoryForCommitteeSTaxation);
	Query.SetParameter("ExcludedVATRates", VATAccountingLocalization.ExcludedTransfersVATRates());
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	CheckWhetherDocumentInventoryTypesNeedToBeRefilled(AdditionalProperties, Query);
	
	Query.TempTablesManager = TempTablesManager;
	
	Return Query;
	
EndFunction

Procedure FillInStructureByProductLine(Structure, RowOfGoods, HeaderData_)
	
	If ValueIsFilled(RowOfGoods.NewTypeOfInventoryProductOwner) Then
		Structure.GoodsOwner = RowOfGoods.NewTypeOfInventoryProductOwner;
		Structure.Counterparty     = RowOfGoods.NewTypeOfInventoryCounterparty;
		Structure.Contract        = RowOfGoods.NewKindOfInventoryContract;
		Structure.Currency         = RowOfGoods.NewKindOfStockCurrency;
		Structure.InventoryType     = RowOfGoods.NewTypeOfInventoryTypeOfInventory;
	Else
		FillPropertyValues(Structure, HeaderData_);
	EndIf;
	
	Structure.FinancialAccountingGroup = RowOfGoods.FinancialAccountingGroup;
	Structure.SubjectToExcise			= False;
	Structure.BusinessUnitProduction	= Undefined;
EndProcedure

Procedure CreateReservesForOrganizationsForControl(DocumentObject,
														TempTablesManager,
														Cancel,
														ParametersForFillingInventoryTypes)
	
	CompanyArray = OrganizationsForBalanceControl(TempTablesManager);
	
	If Not CompanyArray.Count() Then
		Return;
	EndIf;
	
	RequestBalanceDates = New Query;
	RequestBalanceDates.TempTablesManager = TempTablesManager;
	RequestBalanceDates.Text = 
	"SELECT
	|	MIN(TTProductsAndChanges.Period) AS Period
	|FROM
	|	TTProductsAndChanges AS TTProductsAndChanges
	|WHERE
	|	TTProductsAndChanges.ForResidueControl";
	
	Selection = RequestBalanceDates.Execute().Select();
	
	If Not Selection.Next()
		Or Not ValueIsFilled(Selection.Period) Then
		
		Return;
		
	Else
		DateOfRemainingGoods = Selection.Period;
	EndIf;
	
	AllowRetroactiveReleaseRegistration  = UserRightsCached.AllowRetroactiveReleaseRegistration();
	TableReservesForOrganizationsForControl = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	ErrorsTable = TableOfErrorsInFillingInventoryTypes();
	GenerateTTTableOfDetailsOfStockTypesByDefault(TempTablesManager, ParametersForFillingInventoryTypes);
	
	ReserveAllocationRequest = QueryingAllocationOfReservesByBalanceTable(TempTablesManager,
																				ParametersForFillingInventoryTypes);
	
	RequestToDestroy = New Query;
	RequestToDestroy.TempTablesManager = TempTablesManager;
	
	For Each Organization In CompanyArray Do
		
		// The available inventory types were created earlier when preparing a record
		// of organizations' products (see the Inventory Server procedure.Prepare a record of the organization's products) .
		// If there is only one Cur organization in the selection, then the available inventory types are suitable
		// for the Cur organization and do not need to be replenished.
		If TypeOf(ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization) = Type("Array")
			And ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization.Count() = 1
			And ParametersForFillingInventoryTypes.SelectionOfStockTypes_.Organization[0] = Organization Then
			
			ItIsRequiredToReplenishAvailableTypesOfStocks = False;
			
		Else
			ItIsRequiredToReplenishAvailableTypesOfStocks = True;
		EndIf;
		
		If ItIsRequiredToReplenishAvailableTypesOfStocks Then
			FillingParametersByOrganization = Common.CopyRecursive(ParametersForFillingInventoryTypes);
			FillingParametersByOrganization.SelectionOfStockTypes_.Organization = Organization;
			
			If TempTablesManager.Tables.Find("AvailableTypesOfStocks") <> Undefined Then
				RequestToDestroy.Text = "DROP AvailableTypesOfStocks";
				RequestToDestroy.Execute();
			EndIf;
			
			If TempTablesManager.Tables.Find("TTSelectionsOfBusinessBalances") <> Undefined Then
				RequestToDestroy.Text = "DROP TTSelectionsOfBusinessBalances";
				
				RequestToDestroy.Execute();
			EndIf;
			
			GenerateTTAvailableInventoryTypes(DocumentObject,
												TempTablesManager,
												FillingParametersByOrganization,
												"MovementOfOrganizationsProductsBeforeRecording");
			
			GenerateTTSelectionsOfBalancesAccordingToTableOfChanges(TempTablesManager);
			
		Else
			FillingParametersByOrganization = ParametersForFillingInventoryTypes;
		EndIf;
		
		GenerateTTTableOfBalances("CompanyGoods",
										DocumentObject,
										TempTablesManager,
										FillingParametersByOrganization,
										False,
										DateOfRemainingGoods);
		
		ReserveAllocationRequest.SetParameter("Period", DateOfRemainingGoods);
		
		AllocateNewReservesToBalanceTable(ReserveAllocationRequest,
													Organization,
													FillingParametersByOrganization,
													TableReservesForOrganizationsForControl,
													ErrorsTable);
		
		If ErrorsTable.Count() <> 0 Then
			
			If TypeOf(DocumentObject) <> Type("Structure") Then
				ReportProductControlErrorsInOrganizations(DocumentObject,
															ErrorsTable,
															ParametersForFillingInventoryTypes,
															Organization);
			EndIf;
			
			If Not SessionParameters.PostWithoutControlOfCompanyStockBalance Then
				
				FilterWorks = New Structure("ItemsType", Enums.ItemsTypes.Work_5);
				ErrorsAreOnlyForWorks = ErrorsTable.FindRows(FilterWorks).Count() = ErrorsTable.Count();
				
				If Constants.ControlCompanyStockBalance.Get()
					And Not WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault(ParametersForFillingInventoryTypes)
					// If the user has the appropriate role, then the consumption of work is not controlled
					And (Not AllowRetroactiveReleaseRegistration
						Or Not ErrorsAreOnlyForWorks) Then
					Cancel = True;
				EndIf;
				
			EndIf;
			
			If Not DocumentObject.AdditionalProperties.Property("RefillInventoryKinds")
				Or Not DocumentObject.AdditionalProperties.RefillInventoryKinds
				Or Cancel Then
				
				Return;
				
			EndIf;
			
		EndIf;
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		
		If TempTablesManager.Tables.Find("TTProvisionsForOrganizationsForControl") <> Undefined Then
			Query.Text = 
			"DROP TTProvisionsForOrganizationsForControl
			|;
			|";
		EndIf;
		
		Query.Text = Query.Text + 
		"SELECT
		|	TTProvisionsForOrganizationsForControl.RecordType AS RecordType,
		|	TTProvisionsForOrganizationsForControl.Period AS Period,
		|	TTProvisionsForOrganizationsForControl.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TTProvisionsForOrganizationsForControl.Organization AS Organization,
		|	TTProvisionsForOrganizationsForControl.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TTProvisionsForOrganizationsForControl.CCDNumber AS CCDNumber,
		|	TTProvisionsForOrganizationsForControl.Count AS Count,
		|	CAST(TTProvisionsForOrganizationsForControl.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
		|	TTProvisionsForOrganizationsForControl.CorCompany AS CorCompany,
		|	TTProvisionsForOrganizationsForControl.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
		|INTO TTProvisionsForOrganizationsForControl
		|FROM
		|	&TableReservesForOrganizationsForControl AS TTProvisionsForOrganizationsForControl";
		
		Query.SetParameter("TableReservesForOrganizationsForControl", TableReservesForOrganizationsForControl);
		
		Query.Execute();
		
	EndDo;
	
EndProcedure

Function DistributeReservesOfGoodsOfOrganizationsByPeriods(NumberOfPeriodsWhenFormingReservesOfOrganizations,
														TableNewReservesInitial,
														TempTablesManager) Export
	
	If NumberOfPeriodsWhenFormingReservesOfOrganizations < 2
		Or TableNewReservesInitial.Count() = 0 Then
		
		Return TableNewReservesUnchanged(TableNewReservesInitial, TempTablesManager);
		
	EndIf;
	
	QueryText =
	"SELECT
	|	TableNewReserves.Period AS Period,
	|	TableNewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableNewReserves.Organization AS Organization,
	|	TableNewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableNewReserves.CCDNumber AS CCDNumber,
	|	TableNewReserves.CorCompany AS CorCompany,
	|	TableNewReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TableNewReserves.Count AS Count,
	|	CAST(TableNewReserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	TableNewReserves.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	TableNewReserves.RecordType AS RecordType
	|INTO TTTableNewReserves
	|FROM
	|	&TableNewReservesInitial AS TableNewReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(ENDOFPERIOD(TableNewReserves.Period, MONTH)) AS Period,
	|	TableNewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableNewReserves.Organization AS Organization,
	|	TableNewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableNewReserves.CCDNumber AS CCDNumber,
	|	SUM(TableNewReserves.Count) AS Count,
	|	SUM(TableNewReserves.QuantityByGBRN) AS QuantityByGBRN
	|INTO TTReserveIncomeGrouped
	|FROM
	|	TTTableNewReserves AS TableNewReserves
	|WHERE
	|	TableNewReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT TableNewReserves.ThisIsReverseTransaction
	|
	|GROUP BY
	|	TableNewReserves.ItemsLocationAttributes,
	|	TableNewReserves.Organization,
	|	TableNewReserves.InventoryOwnerAttribute,
	|	TableNewReserves.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTReserveIncomeGrouped.Period AS ReservePeriod,
	|	TTReserveIncomeGrouped.Organization AS Organization,
	|	TTReserveIncomeGrouped.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTReserveIncomeGrouped.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTReserveIncomeGrouped.CCDNumber AS CCDNumber,
	|	TTReserveIncomeGrouped.Count AS Reserve,
	|	ISNULL(GroupedBalances.CountBalance, 0) AS MinimumBalance
	|INTO TTReserveArrivalMinimumBalance
	|FROM
	|	TTReserveIncomeGrouped AS TTReserveIncomeGrouped
	|		LEFT JOIN GroupedBalances AS GroupedBalances
	|		ON TTReserveIncomeGrouped.Organization = GroupedBalances.Organization
	|			AND TTReserveIncomeGrouped.ItemsLocationAttributes = GroupedBalances.ItemsLocationAttributes
	|			AND TTReserveIncomeGrouped.InventoryOwnerAttribute = GroupedBalances.InventoryOwnerAttribute
	|			AND TTReserveIncomeGrouped.CCDNumber = GroupedBalances.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQueryByMonth.RemainderPeriod AS RemainderPeriod,
	|	NestedQueryByMonth.Organization AS Organization,
	|	NestedQueryByMonth.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQueryByMonth.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQueryByMonth.CCDNumber AS CCDNumber,
	|	NestedQueryByMonth.ReserveNotNeededThisMonth AS ReserveNotNeededThisMonth,
	|	NestedQueryByMonth.NewReserveTotal AS NewReserveTotal
	|FROM
	|	CombinedQueryTextByMonth AS NestedQueryByMonth
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	CCDNumber,
	|	RemainderPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(TableNewReserves.Period, MONTH) AS PeriodEndOfMonth,
	|	TableNewReserves.Period AS Period,
	|	TableNewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableNewReserves.Organization AS Organization,
	|	TableNewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableNewReserves.CCDNumber AS CCDNumber,
	|	TableNewReserves.CorCompany AS CorCompany,
	|	TableNewReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TableNewReserves.Count AS Count,
	|	TableNewReserves.QuantityByGBRN AS QuantityByGBRN,
	|	TableNewReserves.Count AS QuantityNotDistributedByPeriod,
	|	TableNewReserves.QuantityByGBRN AS AmountOfRNPTNotDistributedOverPeriods,
	|	TableNewReserves.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	TableNewReserves.RecordType AS RecordType
	|FROM
	|	TTTableNewReserves AS TableNewReserves
	|
	|WHERE
	|	TableNewReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT TableNewReserves.ThisIsReverseTransaction
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	CCDNumber,
	|	Period DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTableNewReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTReserveArrivalMinimumBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTReserveIncomeGrouped";
	
	TextTemplateByMonth =
	"SELECT
	|	&TextRemainderPeriod AS RemainderPeriod,
	|	TTReserveArrivalMinimumBalance.Organization AS Organization,
	|	TTReserveArrivalMinimumBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTReserveArrivalMinimumBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTReserveArrivalMinimumBalance.CCDNumber AS CCDNumber,
	|	ISNULL(MonthlyBalancesTemplate.CountBalance, 0) - TTReserveArrivalMinimumBalance.MinimumBalance AS ReserveNotNeededThisMonth,
	|	TTReserveArrivalMinimumBalance.Reserve AS NewReserveTotal
	|FROM
	|	TTReserveArrivalMinimumBalance AS TTReserveArrivalMinimumBalance
	|		LEFT JOIN MonthlyBalancesTemplate AS MonthlyBalancesTemplate
	|		ON TTReserveArrivalMinimumBalance.ItemsLocationAttributes = MonthlyBalancesTemplate.ItemsLocationAttributes
	|			AND TTReserveArrivalMinimumBalance.Organization = MonthlyBalancesTemplate.Organization
	|			AND TTReserveArrivalMinimumBalance.InventoryOwnerAttribute = MonthlyBalancesTemplate.InventoryOwnerAttribute
	|			AND TTReserveArrivalMinimumBalance.CCDNumber = MonthlyBalancesTemplate.CCDNumber
	|WHERE
	|	TTReserveArrivalMinimumBalance.ReservePeriod <= &TextRemainderPeriod";
	
	ArrayOfQueriesByMonth = New Array;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("TableNewReservesInitial", TableNewReservesInitial);
	
	MonthOfFirstBalance	= '30000101';
	DateTypeDetails	= New TypeDescription("Date");
	
	For Each Table In TempTablesManager.Tables Do
		
		PeriodAsString	= StrReplace(Table.FullName, "Balance", "");
		Period			= DateTypeDetails.AdjustValue(PeriodAsString);
		
		If ValueIsFilled(Period)
			And StrStartsWith(Table.FullName, "Balance") Then
			
			QueryTextByMonths	= StrReplace(TextTemplateByMonth, "MonthlyBalancesTemplate", Table.FullName);
			TextRemainderPeriod		= "EndOfMonth" + PeriodAsString;
			QueryTextByMonths	= StrReplace(QueryTextByMonths, "TextRemainderPeriod", TextRemainderPeriod);
			PeriodByDate				= EndOfMonth(Period);
			
			If PeriodByDate < MonthOfFirstBalance Then
				MonthOfFirstBalance = PeriodByDate;
			EndIf;
			
			Query.SetParameter(TextRemainderPeriod, PeriodByDate);
			
			ArrayOfQueriesByMonth.Add(QueryTextByMonths);
			
		EndIf;
		
	EndDo;
	
	CombinedQueryTextByMonth = StrConcat(ArrayOfQueriesByMonth,
													TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = StrReplace(QueryText,
								"CombinedQueryTextByMonth",
								"(" + CombinedQueryTextByMonth + ")");
	
	Query.Text		= QueryText;
	QueryResult	= Query.ExecuteBatch();
	SamplingBalances		= QueryResult[3].Select();
	TableNewReserves	= QueryResult[4].Unload(); // ValueTable
	
	SearchKeys = "ItemsLocationAttributes,Organization,InventoryOwnerAttribute,CCDNumber";
	
	TableNewReservesAddedRows = TableNewReserves.CopyColumns();
	TableNewReserves.Indexes.Add(SearchKeys);
	
	TheStructureOfTheSearch			= New Structure(SearchKeys);
	AnalyticalReserves		= New Array;
	ThereAreChangesInTable	= False;
	SkipThisAnalytics	= False;
	NewReserveTotalNotDistributed = 0;
	
	While SamplingBalances.Next() Do
		
		If Not TMCommonUseClientServer.StructuresAreEqual(TheStructureOfTheSearch, SamplingBalances) Then
			
			FillPropertyValues(TheStructureOfTheSearch, SamplingBalances);
			
			If SamplingBalances.RemainderPeriod = MonthOfFirstBalance
				And SamplingBalances.ReserveNotNeededThisMonth = 0 Then
				//If the minimum balance is in the first month,
				//then it is not necessary to distribute reserves by month - the reserve must be recorded in the first month
				SkipThisAnalytics = True;
				Continue;
			Else
				SkipThisAnalytics = False;
			EndIf;
			
			If NewReserveTotalNotDistributed <> 0 Then
				ExceptionText = NStr("vi = 'Lỗi phân bổ dự phòng hàng tháng';
									|ru = 'Ошибка распределения резервов по месяцам';
									|en = 'An error occurred when allocating reserves by months'; fa = 'An error occurred when allocating reserves by months';
									|it = 'Errore di distribuzione delle riserve per mese';
									|pl = 'Błąd podziału rezerw wg miesięcy';
									|tr = 'Aylık rezerv dağıtım hatası'");
				
				Raise ExceptionText;
			EndIf;
			
			NewReserveTotalNotDistributed	= SamplingBalances.NewReserveTotal;
			AnalyticalReserves				= TMCommonUse.FindRowsWithPreservingOrder(TableNewReserves,
																								TheStructureOfTheSearch);
			
		ElsIf SkipThisAnalytics Then
			Continue;
		EndIf;
		
		ReserveThisMonthTotalUnallocated = NewReserveTotalNotDistributed - SamplingBalances.ReserveNotNeededThisMonth;
		
		If ReserveThisMonthTotalUnallocated <= 0 Then
			Continue;
		EndIf;
		
		IndexOf = AnalyticalReserves.Count() - 1;
		
		DistributedThisMonth = 0;
		
		While IndexOf >= 0 Do
			
			RetainedReserve		= AnalyticalReserves[IndexOf];
			ReserveThisMonthInThisRecord	= Min(RetainedReserve.QuantityNotDistributedByPeriod,
												ReserveThisMonthTotalUnallocated);
			
			If ReserveThisMonthInThisRecord = RetainedReserve.QuantityNotDistributedByPeriod Then
				RetainedReserve.Period = SamplingBalances.RemainderPeriod;
				RetainedReserve.PeriodEndOfMonth = SamplingBalances.RemainderPeriod;
				RetainedReserve.Count = ReserveThisMonthInThisRecord;
				RetainedReserve.QuantityByGBRN = RetainedReserve.AmountOfRNPTNotDistributedOverPeriods;
				RetainedReserve.QuantityNotDistributedByPeriod = 0;
				RetainedReserve.AmountOfRNPTNotDistributedOverPeriods = 0;
				
				AnalyticalReserves.Delete(IndexOf);
			Else
				NewRow = TableNewReservesAddedRows.Add();
				FillPropertyValues(NewRow, RetainedReserve);
				NewRow.Period = SamplingBalances.RemainderPeriod;
				NewRow.PeriodEndOfMonth = SamplingBalances.RemainderPeriod;
				NewRow.QuantityNotDistributedByPeriod = 0;
				NewRow.AmountOfRNPTNotDistributedOverPeriods = 0;
				NewRow.Count = ReserveThisMonthInThisRecord;
				NewRow.QuantityByGBRN = ?(RetainedReserve.QuantityNotDistributedByPeriod <> 0,
												NewRow.Count * RetainedReserve.AmountOfRNPTNotDistributedOverPeriods
													/ RetainedReserve.QuantityNotDistributedByPeriod,
												0);
				
				RetainedReserve.QuantityNotDistributedByPeriod = RetainedReserve.QuantityNotDistributedByPeriod
																				- ReserveThisMonthInThisRecord;
				RetainedReserve.AmountOfRNPTNotDistributedOverPeriods = RetainedReserve.AmountOfRNPTNotDistributedOverPeriods
																							- NewRow.QuantityByGBRN;
			EndIf;
			
			DistributedThisMonth	= DistributedThisMonth + ReserveThisMonthInThisRecord;
			ThereAreChangesInTable	= True;
			ReserveThisMonthTotalUnallocated = ReserveThisMonthTotalUnallocated - ReserveThisMonthInThisRecord;
			
			If ReserveThisMonthTotalUnallocated = 0 Then
				Break;
			EndIf;
			
			IndexOf = IndexOf - 1;
			
		EndDo;
		
		If ReserveThisMonthTotalUnallocated <> 0 Then
			ExceptionText = NStr("vi = 'Lỗi phân bổ dự phòng hàng tháng';
								|ru = 'Ошибка распределения резервов по месяцам';
								|en = 'An error occurred when allocating reserves by months'; fa = 'An error occurred when allocating reserves by months';
								|it = 'Errore di distribuzione delle riserve per mese';
								|pl = 'Błąd podziału rezerw wg miesięcy';
								|tr = 'Aylık rezerv dağıtım hatası'");
			
			Raise ExceptionText;
		EndIf;
		
		NewReserveTotalNotDistributed = NewReserveTotalNotDistributed - DistributedThisMonth;
		
		If NewReserveTotalNotDistributed <= 0 Then
			SkipThisAnalytics = True;
		EndIf;
		
	EndDo;
	
	If NewReserveTotalNotDistributed <> 0 Then
		ExceptionText = NStr("vi = 'Lỗi phân bổ dự phòng hàng tháng';
							|ru = 'Ошибка распределения резервов по месяцам';
							|en = 'An error occurred when allocating reserves by months'; fa = 'An error occurred when allocating reserves by months';
							|it = 'Errore di distribuzione delle riserve per mese';
							|pl = 'Błąd podziału rezerw wg miesięcy';
							|tr = 'Aylık rezerv dağıtım hatası'");
		
		Raise ExceptionText;
	EndIf;
	
	If ThereAreChangesInTable Then
		
		TableNewReserves.Indexes.Clear();
		
		If TableNewReservesAddedRows.Count() > 0 Then
			TMCommonUse.AddRowsToTable(TableNewReserves, TableNewReservesAddedRows);
		EndIf;
		
		TableNewReserves.Columns.Delete("PeriodEndOfMonth");
		TableNewReserves.Columns.Delete("QuantityNotDistributedByPeriod");
		
		RowsCount = TableNewReserves.Count(); 
		
		For IndexOf = 0 To RowsCount - 1 Do
			ArrivalLine = TableNewReserves[IndexOf];
			ArrivalLine.RecordType = AccumulationRecordType.Receipt;
			
			AccumulationRegisters.CompanySafeStock.AddCorRecordToReserveSet(TableNewReserves,
																						ArrivalLine);
		EndDo;
		
		RequestTextForDestructionOfResidueTables = RequestTextForDestructionOfResidueTables(TempTablesManager);
		
		If Not IsBlankString(RequestTextForDestructionOfResidueTables) Then
			Query = New Query;
			Query.TempTablesManager = TempTablesManager;
			Query.Text = RequestTextForDestructionOfResidueTables;
			
			Query.Execute();
		EndIf;
		
		Return TableNewReserves;
		
	Else
		Return TableNewReservesUnchanged(TableNewReservesInitial, TempTablesManager);	
	EndIf;
	
EndFunction

Function RequestTextForDestructionOfResidueTables(TempTablesManager)
	
	ArrayOfRequestsForTTDestruction = New Array;
	
	For Each Table In TempTablesManager.Tables Do
		
		If Left(Table.FullName,7) = "Balance" Then
			ArrayOfRequestsForTTDestruction.Add("DROP " + Table.FullName);
		EndIf;
		
	EndDo;
	
	If TempTablesManager.Tables.Find("GroupedBalances") <> Undefined Then
		ArrayOfRequestsForTTDestruction.Add("DROP GroupedBalances");
	EndIf;
	
	Return StrConcat(ArrayOfRequestsForTTDestruction, Common.QueryBatchSeparator());
	
EndFunction

Function TableNewReservesUnchanged(TableNewReserves, TempTablesManager)
	
	TableDestructionText = RequestTextForDestructionOfResidueTables(TempTablesManager);
	
	If Not IsBlankString(TableDestructionText) Then
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = TableDestructionText;
		Query.Execute();
	EndIf;
	
	Return TableNewReserves;
	
EndFunction

Function ThereIsMovementInCollection(DocumentObject, RegisterName)
	
	If TypeOf(DocumentObject.RegisterRecords) = Type("Structure") Then
		Return DocumentObject.RegisterRecords.Property(RegisterName);
	Else
		Return DocumentObject.RegisterRecords.Find(RegisterName) <> Undefined;
	EndIf;	
	
EndFunction

Function ParametersForFillingInventoryTypesByAdditionalProperties(Document, TempTablesManager)
	
	FillParameters = Undefined;
	If Document.AdditionalProperties.Property("ParametersForFillingInventoryTypes", FillParameters) Then
		If FillParameters = "GetBeforeFormation" Then
			FillParameters = Document.ParametersForFillingInventoryTypes(TempTablesManager);
			Document.AdditionalProperties.ParametersForFillingInventoryTypes = FillParameters;
		EndIf;
	EndIf;
	
	Return FillParameters;
	
EndFunction

Function KeyOfInventoryOwnerAttributeSelectionCache(ProductOwnerInHeader, SelectionOfStockTypes)
	
	PartsOfCacheKey = New Array;
	EmptyValue = "EmptyValue";
	
	CacheKey = ?(ValueIsFilled(SelectionOfStockTypes.InventoryType),
				String(SelectionOfStockTypes.InventoryType),
				EmptyValue);
	PartsOfCacheKey.Add(CacheKey);
	
	CacheKey = ?(ValueIsFilled(SelectionOfStockTypes.PriceKind),
				String(SelectionOfStockTypes.PriceKind.UUID()),
				EmptyValue);
	PartsOfCacheKey.Add(CacheKey);
	
	CacheKey = ?(ValueIsFilled(SelectionOfStockTypes.FinancialAccountingGroup),
				String(SelectionOfStockTypes.FinancialAccountingGroup.UUID()),
				EmptyValue);
	PartsOfCacheKey.Add(CacheKey);
	CacheKey = ?(ValueIsFilled(SelectionOfStockTypes.SubjectToExcise),
				String(SelectionOfStockTypes.SubjectToExcise),
				EmptyValue);
	PartsOfCacheKey.Add(CacheKey);
	
	CacheKey = ?(ValueIsFilled(SelectionOfStockTypes.BusinessUnitProduction),
				String(SelectionOfStockTypes.BusinessUnitProduction.UUID()),
				EmptyValue);
	PartsOfCacheKey.Add(CacheKey);
	If Not ProductOwnerInHeader Then
		CacheKey = ?(ValueIsFilled(SelectionOfStockTypes.GoodsOwner),
					String(SelectionOfStockTypes.GoodsOwner.UUID()),
					EmptyValue);
		PartsOfCacheKey.Add(CacheKey);
		
		CacheKey = ?(ValueIsFilled(SelectionOfStockTypes.Counterparty),
					String(SelectionOfStockTypes.Counterparty.UUID()),
					EmptyValue);
		PartsOfCacheKey.Add(CacheKey);
		
		CacheKey = ?(ValueIsFilled(SelectionOfStockTypes.Contract),
					String(SelectionOfStockTypes.Contract.UUID()),
					EmptyValue);
		PartsOfCacheKey.Add(CacheKey);
	EndIf;
	
	CacheKey = StrConcat(PartsOfCacheKey);
	
	Return CacheKey;
	
EndFunction

Procedure QueryTextForReplacingVATRateField(TempTablesManager, QueryText, FillParameters)
	
	SelectCommissionInventory = FillParameters.SelectCommissionInventoryForCommitteeSTaxation;
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(
		TempTablesManager,
		QueryText,
		"&TextOfSelectionFieldTableOfProductsVATRate_",
		"TableOfGoods",
		"VATRate",
		?(SelectCommissionInventory, "TableOfGoods.VATRate", "MAX(TableOfGoods.VATRate)"),
		"VALUE(Catalog.VATRates.EmptyRef)");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(
		TempTablesManager,
		QueryText,
		"&TextOfSelectionFieldVATRatesBasicVATRate_",
		"TableOfGoods",
		"VATRate",
		?(SelectCommissionInventory,
			"ISNULL(VATRates.RelevantBaseRate, TableOfGoods.VATRate)",
			"MAX(ISNULL(VATRates.RelevantBaseRate, TableOfGoods.VATRate))"
			),
		"VALUE(Catalog.VATRates.EmptyRef)");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(
		TempTablesManager,
		QueryText,
		"&FieldTextTableOfGoodsVATRate_",
		"TableOfGoods",
		"VATRate",
		"TableOfGoods.VATRate",
		"VALUE(Catalog.VATRates.EmptyRef)");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(
		TempTablesManager,
		QueryText,
		"&TextOfDimensionFieldTableOfProductsVATRate_",
		"TableOfGoods",
		"VATRate",
		?(SelectCommissionInventory, "TableOfGoods.VATRate", "UNDEFINED"),
		"UNDEFINED");
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(
		TempTablesManager,
		QueryText,
		"&TextOfVATRateDimensionFieldBasicVATRate_",
		"TableOfGoods",
		"VATRate",
		?(SelectCommissionInventory,
			"ISNULL(VATRates.RelevantBaseRate, TableOfGoods.VATRate)",
			"UNDEFINED"
			),
		"UNDEFINED");
	
EndProcedure

#EndRegion

#Region ReportAboutErrors

Function TableOfErrorsInFillingInventoryTypes()
	
	ErrorsTable = New ValueTable;
	ErrorsTable.Columns.Add("Products");
	ErrorsTable.Columns.Add("Characteristic");
	ErrorsTable.Columns.Add("Series");
	ErrorsTable.Columns.Add("Warehouse");
	ErrorsTable.Columns.Add("OriginWarehouse");
	ErrorsTable.Columns.Add("Purpose");
	ErrorsTable.Columns.Add("UnitOfMeasure");
	ErrorsTable.Columns.Add("NotCCDNumberIsSpecified");
	ErrorsTable.Columns.Add("TracedGoods");
	ErrorsTable.Columns.Add("ItemsType");
	ErrorsTable.Columns.Add("Count");
	ErrorsTable.Columns.Add("Sum");
	ErrorsTable.Columns.Add("Currency");
	
	Return ErrorsTable;
	
EndFunction 

Procedure ReportProductControlErrorsInOrganizations(DocumentObject, ErrorsTable, ParametersForFillingInventoryTypes, Organization = Undefined)
	
	If ParametersForFillingInventoryTypes.ReportFillingErrors
		And ErrorsTable.Count() > 0 Then
		
		ErrorsTable.GroupBy("Products, Characteristic, Series, Warehouse, Purpose, UnitOfMeasure, NotCCDNumberIsSpecified, TracedGoods, ItemsType",
								"Count,Sum");
		
		OrganizingErrorMessage		= ?(ValueIsFilled(Organization),
												Organization,
												DocumentOrganization(DocumentObject, ParametersForFillingInventoryTypes));
		VATTaxation					= ParametersForFillingInventoryTypes.SelectionOfStockTypes_.VATTaxation;
		ControlVATTaxation	= ControlVATTaxation(ParametersForFillingInventoryTypes);
		
		For Each TableRow In ErrorsTable Do
			
			If Not TableRow.NotCCDNumberIsSpecified
				And Not ControlVATTaxation Then
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% không đủ %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation%';
									|ru = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation%';
									|en = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company'; fa = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|it = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation%';
									|pl = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|tr = '%Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% Kuruluşa göre %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% eksik'");
			ElsIf Not TableRow.NotCCDNumberIsSpecified Then
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% không đủ %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% về chịu thuế %VATTaxation%';
									|ru = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% по налогообложению %VATTaxation%';
									|en = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company'; fa = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|it = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% по налогообложению %VATTaxation%';
									|pl = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|tr = 'Kurum üzerinde %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% vergi %VATTaxation% eksikliği %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% vardır'");
			ElsIf Not ControlVATTaxation
				And Not TableRow.TracedGoods Then
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% không đủ %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% với số cụ thể Tờ khai hải quan';
									|ru = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными номерами ГТД';
									|en = '%Count% %UnitOfMeasure% of the %PresentationOfItemType% %ProductPresentation% with specified CCD numbers are missing in%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company'; fa = '%Count% %UnitOfMeasure% of the %PresentationOfItemType% %ProductPresentation% with specified CCD numbers are missing in%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|it = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными номерами ГТД';
									|pl = '%Count% %UnitOfMeasure% of the %PresentationOfItemType% %ProductPresentation% with specified CCD numbers are missing in%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|tr = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными номерами ГТД'");
			ElsIf Not ControlVATTaxation Then
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% không đủ %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% với số đăng ký lô hàng cụ thể';
									|ru = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными РНПТ';
									|en = '%Count% %UnitOfMeasure% of the %PresentationOfItemType% %ProductPresentation% with specified RNPT are missing in%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company'; fa = '%Count% %UnitOfMeasure% of the %PresentationOfItemType% %ProductPresentation% with specified RNPT are missing in%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|it = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными РНПТ';
									|pl = '%Count% %UnitOfMeasure% of the %PresentationOfItemType% %ProductPresentation% with specified RNPT are missing in%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|tr = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными РНПТ'");
			ElsIf TableRow.TracedGoods Then
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% không đủ %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% với số đăng ký lô hàng về chịu thuế %VATTaxation%';
									|ru = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными РНПТ по налогообложению %VATTaxation%';
									|en = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% with specified RNPT by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company'; fa = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% with specified RNPT by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|it = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными РНПТ по налогообложению %VATTaxation%';
									|pl = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% with specified RNPT by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|tr = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными РНПТ по налогообложению %VATTaxation%'");
			Else
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% không đủ %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% với số cụ thể  TKHQ về chịu thuế %VATTaxation%';
									|ru = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными номерами ГТД по налогообложению %VATTaxation%';
									|en = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items with specified CCD numbers by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company'; fa = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items with specified CCD numbers by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|it = 'По организации %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% не хватает %Count% %UnitOfMeasure% %PresentationOfItemType% %ProductPresentation% с указанными номерами ГТД по налогообложению %VATTaxation%';
									|pl = '%Count% %UnitOfMeasure% of the %ProductPresentation% %PresentationOfItemType% items with specified CCD numbers by the %VATTaxation% taxation are missing in the %SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% of the %Organization% company';
									|tr = 'Kurum tarafından %Organization%%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% vergilendirmede %Count%%UnitOfMeasure%%PresentationOfItemType%%ProductPresentation% belirtilen numaralar GKB eksiktir %VATTaxation%'");
			EndIf;
			
			ProductPresentation	= ProductsClientServer.ProductPresentation(TableRow.Products,
																							TableRow.Characteristic,
																							,
																							TableRow.Series,
																							TableRow.Purpose);
			PlaceOfStorageName	= NameOfStorageLocationForReportingBalanceControlErrorsForOrganizations(
											TableRow);
			SpaceWarehouse					= ?(ValueIsFilled(TableRow.Warehouse), " ", "");
			PresentationOfItemType = ?(TableRow.ItemsType = Enums.ItemsTypes.Work_5,
												NStr("vi = 'công việc';
													|ru = 'работы';
													|en = 'work'; fa = 'work';
													|it = 'работы';
													|pl = 'work';
													|tr = 'işin'"),
												NStr("vi = 'hàng hóa';
													|ru = 'товара';
													|en = 'goods'; fa = 'goods';
													|it = 'товара';
													|pl = 'goods';
													|tr = 'ürünün'"));
			
			MessageText = StrReplace(MessageText, "%Organization%",					OrganizingErrorMessage);
			MessageText = StrReplace(MessageText, "%Count%",					TableRow.Count);
			MessageText = StrReplace(MessageText, "%UnitOfMeasure%",				TableRow.UnitOfMeasure);
			MessageText = StrReplace(MessageText, "%ProductPresentation%",		ProductPresentation);
			MessageText = StrReplace(MessageText, "%PlaceOfStorageName%",		PlaceOfStorageName);
			MessageText = StrReplace(MessageText, "%PresentationOfItemType%",	PresentationOfItemType);
			MessageText = StrReplace(MessageText, "%SpaceWarehouse%",					SpaceWarehouse);
			MessageText = StrReplace(MessageText, "%Warehouse%",							TableRow.Warehouse);
			MessageText = StrReplace(MessageText, "%VATTaxation%",			VATTaxation);
			Common.MessageToUser(MessageText, DocumentObject);
			
		EndDo;
		
		ReportOnTaxControlWhenSelectingInventoryTypes(DocumentObject, ParametersForFillingInventoryTypes);
		
	EndIf;
		
EndProcedure

Procedure ReportErrorsInFillingInCommitteeInventoryTypes(DocumentObject, ErrorsTable, ParametersForFillingInventoryTypes)
	
	If ErrorsTable.Count() > 0
		And ParametersForFillingInventoryTypes.ReportFillingErrors Then
		
		ErrorsTable.GroupBy("Products, Characteristic, Series, Warehouse, Purpose, UnitOfMeasure, NotCCDNumberIsSpecified, TracedGoods",
								"Count, Sum");
		
		For Each TableRow In ErrorsTable Do
			
			If TableRow.Count <> 0 Then
				MessageText = NStr("vi = 'Theo người đặt ký gửi %Consignor% không đủ %Count% %UnitOfMeasure% hàng hóa %ProductPresentation% do người nhận ký gửi đã bán %Consignee%';
									|ru = 'По комитенту %Consignor% не хватает %Count% %UnitOfMeasure% товара %ProductPresentation%, реализованного комиссионером %Consignee%';
									|en = 'By the %Consignor% consignor, not enough %Count% %UnitOfMeasure% of the %ProductPresentation% goods sold by the %Consignee% consignee'; fa = 'By the %Consignor% consignor, not enough %Count% %UnitOfMeasure% of the %ProductPresentation% goods sold by the %Consignee% consignee';
									|it = 'Per committente %Consignor% non è sufficiente %Count% %UnitOfMeasure% della merce %ProductPresentation%, venduta dall''agente in conto vendita %Consignee%';
									|pl = 'Dla komitenta %Consignor% brakuje %Count% %UnitOfMeasure% towaru %ProductPresentation%, sprzedanego przez komisanta %Consignee%';
									|tr = 'Göndericiye %Consignor% göre konsinye %Count% %UnitOfMeasure% tarafından %ProductPresentation% satışı yapılan ürün eksik %Consignee%'"); 
				MessageText = StrReplace(MessageText, "%Consignor%", DocumentObject.Organization);
				MessageText = StrReplace(MessageText, "%Consignee%", DocumentObject.Consignee);
				MessageText = StrReplace(MessageText,
											"%ProductPresentation%",
											ProductsClientServer.ProductPresentation(
												TableRow.Products,
												TableRow.Characteristic));
				MessageText = StrReplace(MessageText, "%Count%", TableRow.Count);
				MessageText = StrReplace(MessageText, "%UnitOfMeasure%", TableRow.UnitOfMeasure);
				
				Common.MessageToUser(MessageText, DocumentObject);
			EndIf;
			
			If TableRow.Sum <> 0 Then
				MessageText = NStr("vi = 'Hàng hóa: %ProductPresentation% Số lượng bán vượt quá số lượng hàng bán của đại lý theo %Sum% %Currency%';
									|ru = 'Товар: %ProductPresentation% Сумма продажи превышает сумму реализованного товара комиссионером на %Sum% %Currency%';
									|en = 'Goods: %ProductPresentation% The sale amount exceeds the amount of goods sold by the consignee by %Sum% %Currency%'; fa = 'Goods: %ProductPresentation% The sale amount exceeds the amount of goods sold by the consignee by %Sum% %Currency%';
									|it = 'Merce:  %ProductPresentation% L''importo della vendita supera l''importo della merce venduta dall''agente in conto vendita di %Sum% %Currency%';
									|pl = 'Towar: %ProductPresentation% Wartość sprzedaży przekracza kwotę towaru, sprzedanego przez komisanta o %Sum% %Currency%';
									|tr = 'Ürünler: %ProductPresentation% Satış tutarı, konsinye tarafından satılan ürün miktarını %Sum% %Currency% oranında aşıyor'"); 
				MessageText = StrReplace(MessageText,
											"%ProductPresentation%",
											ProductsClientServer.ProductPresentation(
												TableRow.Products,
												TableRow.Characteristic));
				MessageText = StrReplace(MessageText, "%Sum%", TableRow.Sum);
				MessageText = StrReplace(MessageText, "%Currency%", DocumentObject.Currency);
				
				Common.MessageToUser(MessageText, DocumentObject);
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ReportErrorsInFillingOutInventoryTypesUsingTableForRegistration(
	DocumentObject, 
	ErrorsTable, 
	ParametersForFillingInventoryTypes, 
	BusinessOperation = Undefined)
	
	If ParametersForFillingInventoryTypes.ReportFillingErrors
		And ErrorsTable.Count() > 0 Then
		
		ErrorsTable.GroupBy(
			"Products,Characteristic,Series,Warehouse,OriginWarehouse,Purpose,UnitOfMeasure,NotCCDNumberIsSpecified,TracedGoods,Currency,ItemsType",
			"Count,Sum");
		
		For Each TableRow In ErrorsTable Do
			
			If ValueIsFilled(TableRow.Warehouse)
				And ValueIsFilled(TableRow.Currency)
				And (TableRow.Sum) Then
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization% không đủ %MovementType% %Count% %UnitOfMeasure% với số tiền %Sum%%Currency% %PresentationOfItemType%: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|ru = 'По организации %Organization% не хватает %MovementType% %Count% %UnitOfMeasure% на сумму %Sum%%Currency% %PresentationOfItemType%: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|en = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% in the amount of %Sum%%Currency% are missing in the %Organization% company: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%'; fa = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% in the amount of %Sum%%Currency% are missing in the %Organization% company: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|it = 'По организации %Organization% не хватает %MovementType% %Count% %UnitOfMeasure% на сумму %Sum%%Currency% %PresentationOfItemType%: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|pl = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% in the amount of %Sum%%Currency% are missing in the %Organization% company: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|tr = '%Organization% iş yeri kapsamında %Sum%%Currency% %PresentationOfItemType% tutarına yönelik %MovementType% %Count% %UnitOfMeasure% eksik: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%'");
			ElsIf ValueIsFilled(TableRow.Warehouse) Then
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization% không đủ %MovementType% %Count% %UnitOfMeasure% %PresentationOfItemType%: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|ru = 'По организации %Organization% не хватает %MovementType% %Count% %UnitOfMeasure% %PresentationOfItemType%: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|en = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% are missing in the %Organization% company: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%'; fa = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% are missing in the %Organization% company: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|it = 'По организации %Organization% не хватает %MovementType% %Count% %UnitOfMeasure% %PresentationOfItemType%: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|pl = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% are missing in the %Organization% company: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl%';
									|tr = '%Organization% iş yerinde, ürün %MovementType% %Count% %UnitOfMeasure% %PresentationOfItemType%: %ProductPresentation%,%SpaceWarehouse%%PlaceOfStorageName%%SpaceWarehouse%%Warehouse% %CCDControl% eksik:'");
			ElsIf ValueIsFilled(TableRow.Sum)
				And ValueIsFilled(TableRow.Currency) Then
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization% không đủ %MovementType% %Count% %UnitOfMeasure% đối với số tiền %Sum%%Currency% %PresentationOfItemType%: %ProductPresentation% %CCDControl%';
									|ru = 'По организации %Organization% не хватает %MovementType% %Count% %UnitOfMeasure% на сумму %Sum%%Currency% %PresentationOfItemType%: %ProductPresentation% %CCDControl%';
									|en = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% in the amount of %Sum%%Currency% are missing in the %Organization% company: %ProductPresentation% %CCDControl%'; fa = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% in the amount of %Sum%%Currency% are missing in the %Organization% company: %ProductPresentation% %CCDControl%';
									|it = 'По организации %Organization% не хватает %MovementType% %Count% %UnitOfMeasure% на сумму %Sum%%Currency% %PresentationOfItemType%: %ProductPresentation% %CCDControl%';
									|pl = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% in the amount of %Sum%%Currency% are missing in the %Organization% company: %ProductPresentation% %CCDControl%';
									|tr = '%Organization% iş yerinde , ürün tutarı %Sum%%Currency% %PresentationOfItemType%: %ProductPresentation% %CCDControl%, %MovementType% %Count% %UnitOfMeasure%eksik'");
			Else
				MessageText = NStr("vi = 'Theo doanh nghiệp %Organization% không đủ %MovementType% %Count% %UnitOfMeasure% %PresentationOfItemType%: %ProductPresentation% %CCDControl%';
									|ru = 'По организации %Organization% не хватает %MovementType% %Count% %UnitOfMeasure% %PresentationOfItemType%: %ProductPresentation% %CCDControl%';
									|en = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% are missing in the %Organization% company: %ProductPresentation% %CCDControl%'; fa = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% are missing in the %Organization% company: %ProductPresentation% %CCDControl%';
									|it = 'По организации %Organization% не хватает %MovementType% %Count% %UnitOfMeasure% %PresentationOfItemType%: %ProductPresentation% %CCDControl%';
									|pl = '%MovementType% %Count% %UnitOfMeasure% of %PresentationOfItemType% are missing in the %Organization% company: %ProductPresentation% %CCDControl%';
									|tr = '%Organization% iş yerinde, ürün %MovementType% %Count% %UnitOfMeasure% %PresentationOfItemType%: %ProductPresentation% %CCDControl% eksik'");
			EndIf;	
			
			ProductPresentation = ProductsClientServer.ProductPresentation(TableRow.Products, TableRow.Characteristic,,TableRow.Series);
			
			MessageText = StrReplace(MessageText, "%Organization%", DocumentOrganization(DocumentObject, ParametersForFillingInventoryTypes));
			MessageText = StrReplace(MessageText, "%ProductPresentation%" , ProductPresentation); 
			
			PresentationOfItemType = ?(TableRow.ItemsType = Enums.ItemsTypes.Work_5,
												NStr("vi = 'công việc';
													|ru = 'работы';
													|en = 'work'; fa = 'work';
													|it = 'работы';
													|pl = 'work';
													|tr = 'işin'"),
												NStr("vi = 'hàng hóa';
													|ru = 'товара';
													|en = 'goods'; fa = 'goods';
													|it = 'товара';
													|pl = 'goods';
													|tr = 'ürünün'"));
			MessageText = StrReplace(MessageText, "%PresentationOfItemType%", PresentationOfItemType);
			
			PlaceOfStorageName = NameOfStorageLocationForReportingBalanceControlErrorsForOrganizations(TableRow, BusinessOperation);
			MessageText = StrReplace(MessageText, "%PlaceOfStorageName%", PlaceOfStorageName);
			
			If BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
				Or False Then
				SpaceWarehouse = ?(ValueIsFilled(TableRow.OriginWarehouse), " ", "");
				
				MessageText = StrReplace(MessageText, "%Warehouse%", String(TableRow.OriginWarehouse));
			Else
				SpaceWarehouse = ?(ValueIsFilled(TableRow.Warehouse), " ", "");
				
				MessageText = StrReplace(MessageText, "%Warehouse%", String(TableRow.Warehouse));
			EndIf;
			
			MessageText = StrReplace(MessageText, "%SpaceWarehouse%", SpaceWarehouse);
			
			If BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
				Or False Then
				MessageText = StrReplace(MessageText, "%MovementType%", NStr("vi = 'cần trả lại';
																			|ru = 'к возврату';
																			|en = 'for return'; fa = 'for return';
																			|it = 'In restituzione';
																			|pl = 'do zwrotu';
																			|tr = 'iade edilecek'"));
			Else
				MessageText = StrReplace(MessageText, "%MovementType%", NStr("vi = 'cần lập bảng kê';
																			|ru = 'к оформлению';
																			|en = 'to register'; fa = 'to register';
																			|it = 'In formalizzazione';
																			|pl = 'do zarejestrowania';
																			|tr = 'düzenlenecek'"));
			EndIf;
			
			MessageText = StrReplace(MessageText, "%Count%" , TableRow.Count);
			
			SumText = "";
			If ValueIsFilled(TableRow.Sum) Then
				SumText = Format(TableRow.Sum, "NFD=2");
			EndIf;
			MessageText = StrReplace(MessageText, "%Sum%" , SumText);
			
			Currency_Text = "";
			If ValueIsFilled(TableRow.Currency) Then
				Currency_Text = Format(" " + TableRow.Currency);
			EndIf;
			MessageText = StrReplace(MessageText, "%Currency%" , Currency_Text);

			MessageText = StrReplace(MessageText, "%UnitOfMeasure%" , TableRow.UnitOfMeasure);
			
			If TableRow.NotCCDNumberIsSpecified
				And TableRow.TracedGoods Then
				MessageText = StrReplace(MessageText, "%CCDControl%", NStr("vi = 'có số đăng ký lô hàng cụ thể';
																			|ru = 'с указанными РНПТ';
																			|en = 'with specified RNPT'; fa = 'with specified RNPT';
																			|it = 'с указанными РНПТ';
																			|pl = 'with specified RNPT';
																			|tr = 'belirtilen Lot Kayıt Numaraları ile'"));
			ElsIf TableRow.NotCCDNumberIsSpecified Then
				MessageText = StrReplace(MessageText, "%CCDControl%", NStr("vi = 'có số tờ khai hải quan đã chỉ ra';
																			|ru = 'с указанными номерами ГТД';
																			|en = 'with specified CCD numbers'; fa = 'with specified CCD numbers';
																			|it = 'Con i numeri di dichiarazione doganale indicati';
																			|pl = 'ze wskazanymi numerami ŁDC';
																			|tr = 'belirtilen Gümrük Kargo Beyannamesi numaralarıyla'"));
			Else
				MessageText = StrReplace(MessageText, "%CCDControl%", "");
			EndIf;
			
			Common.MessageToUser(MessageText, DocumentObject);
			
		EndDo;
		
		ReportOnTaxControlWhenSelectingInventoryTypes(DocumentObject, ParametersForFillingInventoryTypes);
		
	EndIf;
		
EndProcedure

Procedure ReportOnTaxControlWhenSelectingInventoryTypes(Val DocumentObject, Val ParametersForFillingInventoryTypes)
	
	If ControlVATTaxation(ParametersForFillingInventoryTypes) Then
		
		TaxationOfVAT = ParametersForFillingInventoryTypes.SelectionOfStockTypes_.VATTaxation;
		
		AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(
			DocumentOrganization(DocumentObject, ParametersForFillingInventoryTypes),
			DocumentObject.Date);
	
		CompanyVATTaxation = AccountingParametersForOrganization.BasicTaxationVATSales;
				
		If TaxationOfVAT <> Enums.VATTaxationTypes.SaleIsSubjectToUTII
			And TaxationOfVAT <> Enums.VATTaxationTypes.SalesByPatent
			And TaxationOfVAT <> Enums.VATTaxationTypes.SubjectToVATAtCustomer
			And TaxationOfVAT <> Enums.VATTaxationTypes.ProductionWithLongCycle
			And TaxationOfVAT <> Enums.VATTaxationTypes.ExportSale
			And Enums.VATTaxationTypes.WithOrWithoutVAT(TaxationOfVAT) <> CompanyVATTaxation Then
			MessageText = NStr(
			"vi = 'Xin lưu ý rằng loại thuế ""%VATTaxation%"" không được hỗ trợ bởi các chính sách kế toán của doanh nghiệp. Trong trường hợp này, có thể ghi giảm chỉ hàng hóa ký gửi.';
			|ru = 'Обратите внимание, что тип налогообложения ""%VATTaxation%"" не поддерживается учетной политикой организации. В этом случае могут быть списаны только комиссионные товары.';
			|en = 'Note that the ""%VATTaxation%"" taxation type is not supported by company policy. In this case, only consignment goods can be written off.'; fa = 'Note that the ""%VATTaxation%"" taxation type is not supported by company policy. In this case, only consignment goods can be written off.';
			|it = 'Si noti che il tipo di tassazione ""%VATTaxation%"" non è supportata dalla politica contabile dell''azienda. In tal caso, solo le merci in conto vendita possono essere stornate.';
			|pl = 'Zwróć uwagę, że typ opodatkowania ""%VATTaxation%"" nie jest obsługiwany polityką rachunkowości firmy. W tym przypadku mogą być wyksięgowane tylko wiersze pozycji komisowe.';
			|tr = '""%VATTaxation%"" vergilendirme türünün iş yerinin muhasebe politikası tarafından desteklenmediğini unutma. Bu durumda, yalnızca sipariş edilen ürünler kayıttan düşülebilir.'");
			MessageText = StrReplace(MessageText, "%VATTaxation%", TaxationOfVAT);
			Common.MessageToUser(MessageText, DocumentObject, "VATTaxation");
		EndIf;
	EndIf;

EndProcedure

Function NameOfStorageLocationForReportingBalanceControlErrorsForOrganizations(TableRow, BusinessOperation = Undefined)
	
	PlaceOfStorageName = "";
	
	// Formation of the name of the business transaction.
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
		Or False Then
		PlaceOfStorageName = NStr("vi = 'từ bên nhận gia công';
									|ru = 'от переработчика';
									|en = 'from subcontractor'; fa = 'from subcontractor';
									|it = 'Dal subfornitore';
									|pl = 'od przetwórcy';
									|tr = 'fason üreticiden'");
	EndIf;
	
	If ValueIsFilled(PlaceOfStorageName) Then
		Return PlaceOfStorageName;
	EndIf;
	
	// Formation of the name by the type of the Warehouse field
	If Not ValueIsFilled(TableRow.Warehouse) Then
		PlaceOfStorageName = "";
	ElsIf TypeOf(TableRow.Warehouse) = Type("CatalogRef.Partners") Then
		PlaceOfStorageName = NStr("vi = 'tại đối tác';
									|ru = 'у партнера';
									|en = 'from partner'; fa = 'from partner';
									|it = 'Presso il partner';
									|pl = 'u partnera';
									|tr = 'iş ortağının'");
	ElsIf TypeOf(TableRow.Warehouse) = Type("CatalogRef.Companies") Then
		PlaceOfStorageName = NStr("vi = 'tại doanh nghiệp';
									|ru = 'у организации';
									|en = 'of the company'; fa = 'of the company';
									|it = 'presso l''azienda';
									|pl = 'u firmy';
									|tr = 'iş yerinin'");
	ElsIf TypeOf(TableRow.Warehouse) = Type("CatalogRef.BusinessStructure") Then
		PlaceOfStorageName = NStr("vi = 'sang bộ phận';
									|ru = 'в подразделении';
									|en = 'in business unit'; fa = 'in business unit';
									|it = 'Nel reparto';
									|pl = 'w dziale';
									|tr = 'departmanda'");
	ElsIf TypeOf(TableRow.Warehouse) = Type("CatalogRef.CounterpartyContracts") Then
		PlaceOfStorageName = NStr("vi = 'theo hợp đồng';
									|ru = 'по договору';
									|en = 'by contract'; fa = 'بر اساس قرارداد';
									|it = 'in base al contratto';
									|pl = 'wg kontraktu';
									|tr = 'sözleşme kapsamında'");
	ElsIf TypeOf(TableRow.Warehouse) = Type("CatalogRef.Warehouses") Then
		PlaceOfStorageName = NStr("vi = 'trong kho';
									|ru = 'на складе';
									|en = 'in warehouse'; fa = 'در انبار';
									|it = 'nel magazzino';
									|pl = 'w magazynie';
									|tr = 'ambarda'");
	Else
		ExceptionText = NStr("vi = 'Trong thủ tục %1 không tính đến nơi cất giữ ""%2""';
							|ru = 'В процедуре %1 не учтен тип места хранения ""%2""';
							|en = 'The ""%2"" storage location type is not recorded in the %1 procedure'; fa = 'The ""%2"" storage location type is not recorded in the %1 procedure';
							|it = 'Nella procedura %1 non è preso in considerazione il tipo di posizione di stoccaggio ""%2""';
							|pl = 'W procedurze %1 nie jest uwzględniony typ miejsca przechowywania ""%2""';
							|tr = '%1 prosedüründe, ""%2"" saklama yeri tipi dikkate alınmadı'");
		ExceptionText = StrTemplate(ExceptionText, "NameOfStorageLocationForReportingBalanceControlErrorsForOrganizations", TypeOf(TableRow.Warehouse));
		Raise ExceptionText;
	EndIf;
	
	Return PlaceOfStorageName;
	
EndFunction

#EndRegion

#Region TTTableOfBalances

// This method returns the VALUE of the table of Stocks, which is used when filling in inventory types.
//
// Parameters:
//	NameOfRemainderTable - String - Name of the balance table, shows which register will be used to build the balance.
//	DocumentObject - DocumentObject - The document for which the balance table is generated.
//	TempTablesManager - TempTablesManager - Manager, contains all available types of Inventory.
//	ParametersForFillingInventoryTypes - Structure - Selection of leftovers. See InventoriesServer.ParametersForFillingInventoryTypes.
//	DeductRegisteredRecordsOnProductsOfOrganizations - Undefined, Boolean - The need for subtraction of the current remnants of the old movements of the document.
//	DateOfRemainingGoods - Undefined, Date - The date on which balances are generated. Usually on the date of the document.
//
Procedure GenerateTTTableOfBalances(NameOfRemainderTable,
										DocumentObject,
										TempTablesManager,
										ParametersForFillingInventoryTypes,
										DeductRegisteredRecordsOnProductsOfOrganizations = Undefined,
										DateOfRemainingGoods = Undefined) Export
	
	If ParametersForFillingInventoryTypes.TableOfBalancesHasAlreadyBeenFormed Then
		Return;
	EndIf;
	
	If DateOfRemainingGoods = Undefined Then
		If ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods Then
			DateOfRemainingGoods = ParametersForFillingInventoryTypes.FillingPeriod;
		ElsIf DocumentObject.Posted
			Or ValueIsFilled(ParametersForFillingInventoryTypes.ReversedDocument) Then
			DateOfRemainingGoods = DocumentObject.Date;
		Else
			DateOfRemainingGoods = Min(DocumentObject.Date, CurrentSessionDate());
		EndIf;
	EndIf;
	
	If NameOfRemainderTable = "CompanyGoods" Then
		If DeductRegisteredRecordsOnProductsOfOrganizations = Undefined Then
			ExceptionText = NStr("vi = 'Lỗi tạo bảng số dư hàng hóa trong doanh nghiệp: chưa truyền tham số %1.';
								|ru = 'Ошибка формирования таблицы остатков товаров организаций: не передан параметр %1.';
								|en = 'An error occurred while generating company stock balance: the %1 parameter is not transferred.'; fa = 'An error occurred while generating company stock balance: the %1 parameter is not transferred.';
								|it = 'Errore di creazione della tabella dei saldi dei prodotti dell''organizzazione: parametro %1 non dato.';
								|pl = 'Błąd utworzenia tabeli ostatków towarów firm: nie przekazano parametru %1.';
								|tr = 'İş yerlerinin ürün bakiyeleri tablosu oluşturulurken hata oluştu: %1 parametresi transfer edilmedi.'");
			ExceptionText = StrTemplate(ExceptionText, "DeductRegisteredRecordsOnProductsOfOrganizations");
			Raise ExceptionText;
		EndIf;
		
		TableOfOrganizationsProductBalances(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes, DeductRegisteredRecordsOnProductsOfOrganizations, DateOfRemainingGoods);
		
	ElsIf NameOfRemainderTable = "IntercampanyCommissionGoods" Then
		
		IntercampanyCommissionGoodsBalanceTable(DocumentObject,
														TempTablesManager,
														ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "GoodsTransferredToCommissionAgent" Then
		
		TableOfBalancesOfGoodsTransferredToCommission(DocumentObject,
													ParametersForFillingInventoryTypes,
													TempTablesManager,
													DateOfRemainingGoods);
		

	ElsIf NameOfRemainderTable = "SoldGoods" Then
		TableOfBalancesOfGoodsSold(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "AcceptedGoods" Then
		TableOfBalancesOfAcceptedGoods(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "TransferredReturnablePackaging" Then
		TableOfResiduesOfTransferredReturnContainers(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "GoodsTransferredBetweenOrganizations" Then
		TableOfBalancesOfGoodsTransferredBetweenOrganizations(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "GoodsToBeRegisteredInReportsToConsignor" Then
		TableOfBalancesForMakingReportToCommittee(DocumentObject, TempTablesManager, DateOfRemainingGoods);
		
	ElsIf NameOfRemainderTable = "RequirementsForIssuingReportsToCommitteeOnWriteOffs" Then
		
		TableOfBalancesForIssuingReportToCommitteeOnWriteOffs(DocumentObject,
															TempTablesManager,
															ParametersForFillingInventoryTypes);
		

	ElsIf NameOfRemainderTable = "GoodsWrittenOffAsExpenses" Then
		TableOfBalancesOfGoodsWrittenOffForExpenses(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "CompanyGoodsForTransfer" Then
		TableOfBalancesOfGoodsForTransfer(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes, DateOfRemainingGoods);
		
	ElsIf NameOfRemainderTable = "ProductsFromOrganizationsToBeReturned" Then
		TableOfRemainingItemsForReturn(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes, DateOfRemainingGoods);
		
	ElsIf NameOfRemainderTable = "ProductsFromPartnersHavePositiveBalance" Then
		
		Negative_Balance = False;
		
		TableOfProductBalancesWithPartners(DocumentObject,
										TempTablesManager,
										Negative_Balance,
										ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "PartnerProductsHaveNegativeBalance" Then
		Negative_Balance = True;
		TableOfProductBalancesWithPartners(DocumentObject, TempTablesManager, Negative_Balance);
		
	ElsIf NameOfRemainderTable = "WriteOffOfDiscrepanciesPositiveBalance" Then
		Negative_Balance = False;
		TableOfBalancesForWriteOffOfDiscrepancies(DocumentObject, TempTablesManager, Negative_Balance, ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "WriteOffOfDiscrepanciesNegativeBalance" Then
		Negative_Balance = True;
		TableOfBalancesForWriteOffOfDiscrepancies(DocumentObject, TempTablesManager, Negative_Balance);
		
	ElsIf NameOfRemainderTable = "ItemsAcceptedForWriteOff" Then
		TableOfProductBalancesAccepted(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
	ElsIf NameOfRemainderTable = "TableTypesOfStocks_" Then
		TableOfBalancesTableTypesOfStocks(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
	Else
		ExceptionText = NStr("vi = 'Tên bảng còn lại không xác định.';
							|ru = 'Неизвестное имя таблицы остатков.';
							|en = 'Unknown name of the remaining quantity table.'; fa = 'Unknown name of the remaining quantity table.';
							|it = 'Nome sconosciuto della tabella dei saldi.';
							|pl = 'Nieznana nazwa tabeli pozostałości.';
							|tr = 'Bakiye tablosunun bilinmeyen adı.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

Procedure TableOfOrganizationsProductBalances(DocumentObject,
											TempTablesManager,
											ParametersForFillingInventoryTypes,
											DeductRegisteredRecordsOnProductsOfOrganizations,
											MinimumBalanceDate,
											BalanceDates = Undefined)
	
	DocumentRef = DocumentObject.Ref;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	Reserves.Period AS Period,
	|	Reserves.Organization AS Organization,
	|	Reserves.RecordType AS RecordType,
	|	Reserves.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Reserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Reserves.CCDNumber AS CCDNumber,
	|	Reserves.Count AS Count,
	|	CAST(Reserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	Reserves.CorCompany AS CorCompany,
	|	Reserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO FormedReserves
	|FROM
	|	&FormedReserves AS Reserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(DocumentRegisterRecords.Period, MONTH)	AS Period,
	|	DocumentRegisterRecords.Organization					AS Organization,
	|	DocumentRegisterRecords.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DocumentRegisterRecords.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DocumentRegisterRecords.CCDNumber						AS CCDNumber,
	|	CASE
	|		WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN DocumentRegisterRecords.Count
	|		ELSE -DocumentRegisterRecords.Count
	|	END											AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(DocumentRegisterRecords.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN CAST(DocumentRegisterRecords.QuantityByGBRN AS NUMBER(23, 11))
	|		ELSE -CAST(DocumentRegisterRecords.QuantityByGBRN AS NUMBER(23, 11))
	|	END											AS QuantityByGBRN
	|INTO RegisteredRecordsOfCancelledDocument
	|FROM
	|	AccumulationRegister.CompanyGoods AS DocumentRegisterRecords
	|WHERE
	|	NOT DocumentRegisterRecords.ReversingEntry
	|	AND &DeductRegisteredRecordsOnProductsOfOrganizations
	|	AND DocumentRegisterRecords.Recorder = &ReversedDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(RegisterRecords.Period, MONTH) AS Period,
	|	RegisterRecords.Organization,
	|	RegisterRecords.ItemsLocationAttributes,
	|	RegisterRecords.InventoryOwnerAttribute,
	|	RegisterRecords.CCDNumber,
	|	SUM(RegisterRecords.Count) AS Count,
	|	SUM(RegisterRecords.QuantityByGBRN) AS QuantityByGBRN
	|INTO DocumentRegisterRecords
	|FROM
	|	(SELECT
	|		Goods.Period AS Period,
	|		Goods.Organization AS Organization,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		CASE
	|			WHEN Goods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -Goods.Count
	|			ELSE Goods.Count
	|		END AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(Goods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			WHEN Goods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CAST(Goods.QuantityByGBRN AS NUMBER(23, 11))
	|			ELSE CAST(Goods.QuantityByGBRN AS NUMBER(23, 11))
	|		END AS QuantityByGBRN
	|	FROM
	|		MovementOfOrganizationsProductsBeforeRecording AS Goods
	|	
	|		INNER JOIN AvailableTypesOfStocks AS AvailableTypesOfStocks
	|		ON AvailableTypesOfStocks.ForCompany = Goods.Organization
	|			AND AvailableTypesOfStocks.InventoryOwnerAttribute = Goods.InventoryOwnerAttribute
	|	WHERE
	|		&DeductRegisteredRecordsOnProductsOfOrganizations
	|	
	|	UNION ALL
	|	
	|	SELECT // Repayment of reserves under the intercampany scheme, used in transfer documents
	|		Reserves.Period,
	|		Reserves.Organization,
	|		Reserves.ItemsLocationAttributes,
	|		Reserves.InventoryOwnerAttribute,
	|		Reserves.CCDNumber,
	|		CASE
	|			WHEN Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -Reserves.Count
	|			ELSE Reserves.Count
	|		END,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(Reserves.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			WHEN Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CAST(Reserves.QuantityByGBRN AS NUMBER(23, 11))
	|			ELSE CAST(Reserves.QuantityByGBRN AS NUMBER(23, 11))
	|		END
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS Reserves
	|			INNER JOIN TTSelectionsOfBusinessBalances AS SelectingOrganizationBalances
	|			ON SelectingOrganizationBalances.InventoryOwnerAttribute = Reserves.InventoryOwnerAttribute
	|				AND SelectingOrganizationBalances.Organization = Reserves.Organization // product owner
	|				AND SelectingOrganizationBalances.ItemsLocationAttributes = Reserves.ItemsLocationAttributes
	|	WHERE
	|		Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Reserves.CorInventoryOwnerAttribute IN (&CorTypesOfStocks)// the seller of the goods
	|		AND (Reserves.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			OR NOT Reserves.InventoryOwnerAttribute IN (&CorTypesOfStocks))
	|		AND Reserves.Period >= BEGINOFPERIOD(&EndOfMonth, MONTH)
	|	
	|	UNION ALL
	|	
	|	SELECT // Repayment of reserves due to repurchase from the depositor
	|		Reserves.Period,
	|		Reserves.Organization,
	|		Reserves.ItemsLocationAttributes,
	|		Reserves.InventoryOwnerAttribute,
	|		Reserves.CCDNumber,
	|		-Reserves.Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(Reserves.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE -CAST(Reserves.QuantityByGBRN AS NUMBER(23, 11))
	|		END
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS Reserves
	|			
	|			INNER JOIN TTSelectionsOfBusinessBalances AS SelectingOrganizationBalances
	|			ON Reserves.ItemsLocationAttributes = SelectingOrganizationBalances.ItemsLocationAttributes
	|				AND Reserves.InventoryOwnerAttribute = SelectingOrganizationBalances.InventoryOwnerAttribute
	|				AND Reserves.Organization = SelectingOrganizationBalances.Organization // product owner
	|				AND Reserves.CorCompany = SelectingOrganizationBalances.Organization // the seller of the goods
	|	
	|	WHERE
	|		Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Reserves.InventoryOwnerAttribute <> Reserves.CorInventoryOwnerAttribute
	|		AND &ThisIsRedemptionOfGoods
	|		AND Reserves.Period >= BEGINOFPERIOD(&EndOfMonth, MONTH)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reserves.Period,
	|		Reserves.Organization,
	|		Reserves.ItemsLocationAttributes,
	|		Reserves.InventoryOwnerAttribute,
	|		Reserves.CCDNumber,
	|		CASE
	|			WHEN Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Reserves.Count
	|			ELSE -Reserves.Count
	|		END,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(Reserves.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			WHEN Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CAST(Reserves.QuantityByGBRN AS NUMBER(23, 11))
	|			ELSE -CAST(Reserves.QuantityByGBRN AS NUMBER(23, 11))
	|		END
	|	FROM
	|		FormedReserves AS Reserves
	|
	|			INNER JOIN AvailableTypesOfStocks AS AvailableTypesOfStocks
	|			ON AvailableTypesOfStocks.ForCompany = Reserves.Organization
	|				AND AvailableTypesOfStocks.InventoryOwnerAttribute = Reserves.InventoryOwnerAttribute
	|	WHERE
	|		Reserves.InventoryOwnerAttribute IN (&CorTypesOfStocks) // the seller of the goods
	|		AND CAST(Reserves.InventoryOwnerAttribute AS Catalog.InventoryKinds).InventoryType <> VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			OR NOT Reserves.CorInventoryOwnerAttribute IN (&CorTypesOfStocks)
	|
	|	) AS RegisterRecords
	|
	|GROUP BY
	|	ENDOFPERIOD(RegisterRecords.Period, MONTH),
	|	RegisterRecords.Organization,
	|	RegisterRecords.ItemsLocationAttributes,
	|	RegisterRecords.InventoryOwnerAttribute,
	|	RegisterRecords.CCDNumber
	|
	|INDEX BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTSelectionsOfBusinessBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DatesOfCompanyGoodsReceipt.DateOfReceipt AS DateOfReceipt,
	|	DatesOfCompanyGoodsReceipt.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DatesOfCompanyGoodsReceipt.CCDNumber AS CCDNumber
	|INTO TTDateOfReceiptOfGoodsOrganizations
	|FROM
	|	TTSelectionsOfBusinessBalances AS TTSelectionsOfBusinessBalances
	|		INNER JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfCompanyGoodsReceipt
	|		ON TTSelectionsOfBusinessBalances.Products = DatesOfCompanyGoodsReceipt.Products
	|			AND TTSelectionsOfBusinessBalances.Characteristic = DatesOfCompanyGoodsReceipt.Characteristic
	|			AND TTSelectionsOfBusinessBalances.Series = DatesOfCompanyGoodsReceipt.Series
	|			AND TTSelectionsOfBusinessBalances.Purpose = DatesOfCompanyGoodsReceipt.Purpose
	|			AND TTSelectionsOfBusinessBalances.InventoryOwnerAttribute = DatesOfCompanyGoodsReceipt.InventoryOwnerAttribute
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|	
	|	SELECT &TextTTBalancesByMonth;
	|	
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupedBalances.Period AS Period,
	|	GroupedBalances.Organization AS Organization,
	|	GroupedBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GroupedBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GroupedBalances.CCDNumber AS CCDNumber,
	|	MIN(GroupedBalances.CountBalance) AS CountBalance,
	|	MIN(GroupedBalances.QuantityByGBRNBalance) AS QuantityByGBRNBalance,
	|	SUM(GroupedBalances.PeriodCounter) AS PeriodCounter
	|INTO GroupedBalances
	|FROM
	|	&TextBalancesByMonth AS GroupedBalances
	|
	|GROUP BY
	|	GroupedBalances.Period,
	|	GroupedBalances.PeriodNumber,
	|	GroupedBalances.Organization,
	|	GroupedBalances.ItemsLocationAttributes,
	|	GroupedBalances.InventoryOwnerAttribute,
	|	GroupedBalances.CCDNumber
	|
	|HAVING
	|	(MIN(GroupedBalances.CountBalance) <> 0
	|	AND SUM(GroupedBalances.PeriodCounter) >= &TotalPeriods - GroupedBalances.PeriodNumber + 1)
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	CCDNumber,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	GroupedBalances.Period AS Period,
	|	GroupedBalances.Organization AS Organization,
	|	GroupedBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GroupedBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GroupedBalances.CCDNumber AS CCDNumber,
	|	DatesOfCompanyGoodsReceipt.DateOfReceipt AS DateOfReceipt,
	|	InventoryLocationAttributeKeys.Products AS Products,
	|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
	|	InventoryLocationAttributeKeys.Series AS Series,
	|	InventoryLocationAttributeKeys.StorageLocation AS Warehouse,
	|	InventoryLocationAttributeKeys.Purpose AS Purpose,
	|	UNDEFINED AS DocumentTransfers_, // to fill in the return items between organizations 
	|	UNDEFINED AS ItemsLocationAttributesShipment,  // to fill in the return items between organizations
	|	UNDEFINED AS InventoryOwnerAttributeShipment,  // to fill in the return items between organizations
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,  // to fill in the report correction to the giver
	|	0 AS SumBalance,
	|	GroupedBalances.CountBalance AS CountBalance,
	|	GroupedBalances.QuantityByGBRNBalance AS QuantityByGBRNBalance,
	|	GroupedBalances.PeriodCounter AS PeriodCounter
	|INTO TextTableOfBalances
	|FROM
	|	GroupedBalances AS GroupedBalances
	|		LEFT JOIN TTDateOfReceiptOfGoodsOrganizations AS DatesOfCompanyGoodsReceipt
	|		ON GroupedBalances.InventoryOwnerAttribute = DatesOfCompanyGoodsReceipt.InventoryOwnerAttribute
	|			AND GroupedBalances.ItemsLocationAttributes = DatesOfCompanyGoodsReceipt.ItemsLocationAttributes
	|			AND GroupedBalances.CCDNumber = DatesOfCompanyGoodsReceipt.CCDNumber
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON GroupedBalances.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref";
	
	ExtensionParameters_ = ParametersForAddingBalancesToRequestForEachMonth();
	FillPropertyValues(ExtensionParameters_, ParametersForFillingInventoryTypes);
	
	EndOfControlPeriod = Undefined;
	DocumentObject.AdditionalProperties.Property("EndOfPeriodForCorrectingBalances", EndOfControlPeriod);
	ExtensionParameters_.EndOfControlPeriod = EndOfControlPeriod;
	
	TotalPeriods = AddBalanceControlForEachMonthToRequest(Query,
																	QueryText,
																	ExtensionParameters_,
																	MinimumBalanceDate,
																	BalanceDates);
	
	If ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods Then
		QueryText = StrReplace(QueryText, "TextTableOfBalances", "TableOfBalancesByPeriod");
		Query.SetParameter("FillingPeriod", MinimumBalanceDate);
	Else
		QueryText = StrReplace(QueryText, "TextTableOfBalances", "BalanceTable");
		Query.SetParameter("FillingPeriod", Date(1,1,1));
	EndIf;
	
	Query.Text = QueryText;
	
	If TypeOf(DocumentObject) = Type("DocumentObject.CustomerInvoiceIntercompany") Then
		Query.SetParameter("CorCompany", ParametersForFillingInventoryTypes.WhenSelectingByIntercampanyExcludeOrganizations);
	Else
		Query.SetParameter("CorCompany", Catalogs.Companies.EmptyRef());
	EndIf;
	
	NameOfOrganizationSProductReservesTable = NameOfOrganizationSProductReservesTable();
	
	If DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable) Then
		FormedReserves = DocumentObject.AdditionalProperties[NameOfOrganizationSProductReservesTable].Copy();
	Else
		FormedReserves = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
	EndIf;
	
	If TempTablesManager.Tables.Find("TTStornoReserves") <> Undefined Then
		RequestStorno = New Query("SELECT * FROM TTStornoReserves");
		RequestStorno.TempTablesManager = TempTablesManager;
		TMCommonUse.AddRowsToTable(FormedReserves, RequestStorno.Execute().Unload());
	EndIf;
	
	If TempTablesManager.Tables.Find("TTProvisionsForOrganizationsForControl") <> Undefined Then
		RequestReservesOfOtherOrganizations = New Query("SELECT * FROM TTProvisionsForOrganizationsForControl");
		RequestReservesOfOtherOrganizations.TempTablesManager = TempTablesManager;
		TMCommonUse.AddRowsToTable(FormedReserves, RequestReservesOfOtherOrganizations.Execute().Unload());
	EndIf;
	
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("EndOfMonth", EndOfMonth(MinimumBalanceDate));
	Query.SetParameter("EndOfDay", EndOfDay(MinimumBalanceDate));
	Query.SetParameter("MonthBoundary", New Boundary(EndOfMonth(MinimumBalanceDate), BoundaryType.Including));
	Query.SetParameter("BorderOfDay", New Boundary(EndOfDay(MinimumBalanceDate), BoundaryType.Including));
	Query.SetParameter("DocumentDate", MinimumBalanceDate);
	Query.SetParameter("DeductRegisteredRecordsOnProductsOfOrganizations", DeductRegisteredRecordsOnProductsOfOrganizations);
	Query.SetParameter("FormedReserves", FormedReserves);
	Query.SetParameter("CorTypesOfStocks", ParametersForFillingInventoryTypes.CorTypesOfStocks);
	Query.SetParameter("ThisIsRedemptionOfGoods", False);
	Query.Parameters.ThisIsRedemptionOfGoods = TypeOf(DocumentRef) = Type("DocumentRef.RedemptionOfGoodsFromStorage");
	Query.SetParameter("DateOfCurBalances", ?(ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods,
														EndOfMonth(CurrentSessionDate()),
														Date(1, 1, 1)));
	Query.SetParameter("SelectStocksOfDifferentPeriods", ParametersForFillingInventoryTypes.SelectStocksOfDifferentPeriods);
	Query.SetParameter("TotalPeriods", TotalPeriods);
	Query.SetParameter("ReversedDocument", ParametersForFillingInventoryTypes.ReversedDocument);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
	Query.Text =
	"DROP RegisteredRecordsOfCancelledDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DocumentRegisterRecords
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FormedReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTDateOfReceiptOfGoodsOrganizations
	|";
	
	Query.Execute();
	
	ParametersForFillingInventoryTypes.NumberOfPeriodsWhenFormingReservesOfOrganizations = TotalPeriods;
	
EndProcedure

Procedure TableOfProductBalancesWithPartners(DocumentObject,
											TempTablesManager,
											Negative_Balance,
											ParametersForFillingInventoryTypes = Undefined)
	
	If ParametersForFillingInventoryTypes = Undefined Then
		ParametersForFillingInventoryTypes = ParametersForFillingInventoryTypes();
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTSelectionsOfBusinessBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTSelectionsOfBusinessBalances.Organization                AS Organization,
	|	TTSelectionsOfBusinessBalances.Products               AS Products,
	|	TTSelectionsOfBusinessBalances.Characteristic             AS Characteristic,
	|	TTSelectionsOfBusinessBalances.Series                      AS Series,
	|	(CASE WHEN
	|		ISNULL(TTSelectionsOfBusinessBalances.Products.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)
	|		AND (ISNULL(TTSelectionsOfBusinessBalances.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
	|			OR ISNULL(TTSelectionsOfBusinessBalances.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE))
	|		THEN
	|			TTSelectionsOfBusinessBalances.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END) AS SeriesForSelection,
	|	TTSelectionsOfBusinessBalances.Purpose                 AS Purpose,
	|	TTSelectionsOfBusinessBalances.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TTSelectionsOfBusinessBalances.CCDNumber                   AS CCDNumber,
	|	&Partner                                               AS Partner,
	|	&Counterparty                                            AS Counterparty,
	|	&Contract                                               AS Contract
	|INTO TTSelection
	|FROM
	|	TTSelectionsOfBusinessBalances AS TTSelectionsOfBusinessBalances
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TTSelectionsOfBusinessBalances.InventoryOwnerAttribute = InventoryKinds.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsFromPartnersAreLeftovers.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ProductsFromPartnersAreLeftovers.Organization,
	|	ProductsFromPartnersAreLeftovers.CCDNumber,
	|	ProductsFromPartnersAreLeftovers.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ProductsFromPartnersAreLeftovers.CountBalance,
	|	CAST(ProductsFromPartnersAreLeftovers.QuantityByGBRNBalance AS NUMBER(23, 11)) AS QuantityByGBRNBalance
	|INTO ProductsFromPartnersAreLeftovers
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			,
	|			(ItemsLocationAttributes, Organization, InventoryOwnerAttribute) IN
	|				(SELECT
	|					TTSelection.ItemsLocationAttributes,
	|					TTSelection.Organization,
	|					TTSelection.InventoryOwnerAttribute
	|				FROM
	|					TTSelection AS TTSelection)) AS ProductsFromPartnersAreLeftovers
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.InventoryOwnerAttribute.Organization AS Organization,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Series AS Series,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS RecipientInventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	DATETIME(1, 1, 1) AS DateOfReceipt,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.CCDNumber,
	|	SUM(&TextNumberTransmitted) AS CountBalance,
	|	SUM(&TextQuantityTransmittedByRNPT) AS QuantityByGBRNBalance,
	|	SUM(0) AS OnDateOfControl,
	|	SUM(0) AS CurrentDate_,
	|	SUM(0) AS SumBalance
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes.Products AS Products,
	|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes.Series AS Series,
	|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes.Purpose AS Purpose,
	|		ProductsFromPartnersAreLeftovers.CCDNumber AS CCDNumber,
	|		ProductsFromPartnersAreLeftovers.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		ProductsFromPartnersAreLeftovers.CountBalance AS Passed,
	|		ProductsFromPartnersAreLeftovers.QuantityByGBRNBalance AS TransmittedByRNPT
	|	FROM
	|		ProductsFromPartnersAreLeftovers AS ProductsFromPartnersAreLeftovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTSelection.ItemsLocationAttributes,
	|		CompanyGoods.ItemsLocationAttributes.Products,
	|		CompanyGoods.ItemsLocationAttributes.Characteristic,
	|		CompanyGoods.ItemsLocationAttributes.Series,
	|		CompanyGoods.ItemsLocationAttributes.Purpose,
	|		CompanyGoods.CCDNumber,
	|		CompanyGoods.InventoryOwnerAttribute,
	|		CompanyGoods.Count,
	|		CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|	FROM
	|		AccumulationRegister.CompanyGoods AS CompanyGoods
	|			INNER JOIN TTSelection AS TTSelection
	|			ON CompanyGoods.ItemsLocationAttributes = TTSelection.ItemsLocationAttributes
	|				AND CompanyGoods.Organization = TTSelection.Organization
	|				AND CompanyGoods.InventoryOwnerAttribute = TTSelection.InventoryOwnerAttribute
	|	WHERE
	|		CompanyGoods.Recorder = &Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTSelection.ItemsLocationAttributes,
	|		CompanyGoods.ItemsLocationAttributes.Products,
	|		CompanyGoods.ItemsLocationAttributes.Characteristic,
	|		CompanyGoods.ItemsLocationAttributes.Series,
	|		CompanyGoods.ItemsLocationAttributes.Purpose,
	|		CompanyGoods.CCDNumber,
	|		CompanyGoods.InventoryOwnerAttribute,
	|		CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CompanyGoods.Count
	|			ELSE CompanyGoods.Count
	|		END AS Count,
	|		CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|			ELSE CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|		END AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.CompanyGoods AS CompanyGoods
	|			INNER JOIN TTSelection AS TTSelection
	|			ON CompanyGoods.ItemsLocationAttributes = TTSelection.ItemsLocationAttributes
	|				AND CompanyGoods.Organization = TTSelection.Organization
	|				AND CompanyGoods.InventoryOwnerAttribute = TTSelection.InventoryOwnerAttribute
	|				AND CompanyGoods.CCDNumber = TTSelection.CCDNumber
	|	WHERE
	|		CompanyGoods.Recorder = &ReversedDocument
	|		AND NOT CompanyGoods.ReversingEntry
	|	
	|	) AS NestedQuery
	|
	|WHERE
	|	&TextVersionOfLeftovers
	|
	|GROUP BY
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Series,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.Purpose,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.InventoryOwnerAttribute.Organization,
	|	NestedQuery.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	NestedQuery.ItemsLocationAttributes
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductsFromPartnersAreLeftovers
	|";
	
	QueryText = QueryText + "
	|;
	|//////////////////////////////
	|";
	
	TextOfConditionWithCutOffOfEmptyCCD = "NestedQuery.Passed < 0
	|AND (NOT NestedQuery.Products.KeepRecordsByCCD
	|	OR NestedQuery.Products.KeepRecordsByCCD
	|	AND NestedQuery.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|)";
	
	QueryText = StrReplace(QueryText,
								"&TextVersionOfLeftovers",
								?(Negative_Balance, TextOfConditionWithCutOffOfEmptyCCD, "NestedQuery.Passed > 0"));
	QueryText = StrReplace(QueryText,
								"&TextNumberTransmitted",
								?(Negative_Balance, "-NestedQuery.Passed", "NestedQuery.Passed"));
	QueryText = StrReplace(QueryText,
								"&TextQuantityTransmittedByRNPT",
								?(Negative_Balance, "-CAST(NestedQuery.TransmittedByRNPT AS NUMBER(23, 11))",
								"CAST(NestedQuery.TransmittedByRNPT AS NUMBER(23, 11))"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Partner",				DocumentObject.Partner);
	Query.SetParameter("Contract",				DocumentObject.Contract);
	Query.SetParameter("Counterparty",				DocumentObject.Counterparty);
	Query.SetParameter("Recorder",			DocumentObject.Ref);
	Query.SetParameter("ReversedDocument",	ParametersForFillingInventoryTypes.ReversedDocument);
	
	Query.Execute();
	
EndProcedure

Procedure TableOfBalancesForWriteOffOfDiscrepancies(DocumentObject, TempTablesManager, Negative_Balance, 
			ParametersForFillingInventoryTypes = Undefined)
	
	If ParametersForFillingInventoryTypes = Undefined Then
		ParametersForFillingInventoryTypes = ParametersForFillingInventoryTypes();
	EndIf;
	
	QueryText = 
		"SELECT
		|	TTSelectionsOfBusinessBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TTSelectionsOfBusinessBalances.Organization                AS Organization,
		|	TTSelectionsOfBusinessBalances.Products               AS Products,
		|	TTSelectionsOfBusinessBalances.Characteristic             AS Characteristic,
		|	TTSelectionsOfBusinessBalances.Series                      AS Series,
		|	(CASE WHEN
		|		ISNULL(TTSelectionsOfBusinessBalances.Products.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)
		|		AND (ISNULL(TTSelectionsOfBusinessBalances.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
		|			OR ISNULL(TTSelectionsOfBusinessBalances.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE))
		|		THEN
		|			TTSelectionsOfBusinessBalances.Series
		|		ELSE
		|			VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END) AS SeriesForSelection,
		|	TTSelectionsOfBusinessBalances.Purpose                 AS Purpose,
		|	TTSelectionsOfBusinessBalances.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|	TTSelectionsOfBusinessBalances.CCDNumber                   AS CCDNumber,
		|	&Partner                                               AS Partner,
		|	&Counterparty                                            AS Counterparty,
		|	&Contract                                               AS Contract
		|INTO TTSelection
		|FROM
		|	TTSelectionsOfBusinessBalances AS TTSelectionsOfBusinessBalances
		|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON TTSelectionsOfBusinessBalances.InventoryOwnerAttribute = InventoryKinds.Ref
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoods.Organization AS Organization,
		|	CompanyGoods.CCDNumber AS CCDNumber,
		|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TTRecordersGoodsToBeReceived.DocumentLoggingIn AS DocumentLoggingIn,
		|	SUM(CASE
		|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CompanyGoods.Count
		|		ELSE -CompanyGoods.Count
		|	END) AS CountBalance,
		|	SUM(CASE
		|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
		|		ELSE -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
		|	END) AS QuantityByGBRNBalance
		|INTO ProductsFromPartnersAreLeftovers
		|FROM
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|		INNER JOIN TTSelection AS TTSelection
		|		ON CompanyGoods.ItemsLocationAttributes = TTSelection.ItemsLocationAttributes
		|			AND CompanyGoods.Organization = TTSelection.Organization
		|			AND CompanyGoods.InventoryOwnerAttribute = TTSelection.InventoryOwnerAttribute
		|		INNER JOIN TTRecordersGoodsToBeReceived AS TTRecordersGoodsToBeReceived
		|		ON TTRecordersGoodsToBeReceived.Recorder = CompanyGoods.Recorder
		|
		|GROUP BY
		|    CompanyGoods.ItemsLocationAttributes,
		|    CompanyGoods.Organization,
		|    CompanyGoods.CCDNumber,
		|    CompanyGoods.InventoryOwnerAttribute,
		|    TTRecordersGoodsToBeReceived.DocumentLoggingIn
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.InventoryOwnerAttribute.Organization AS Organization,
		|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	NestedQuery.Products AS Products,
		|	NestedQuery.Characteristic AS Characteristic,
		|	NestedQuery.Series AS Series,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
		|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
		|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
		|	NestedQuery.DocumentLoggingIn AS DocumentLoggingIn,
		|	NestedQuery.InventoryOwnerAttribute,
		|	NestedQuery.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS RecipientInventoryOwnerAttribute,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttributeShipment,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
		|	DATETIME(1, 1, 1) AS DateOfReceipt,
		|	NestedQuery.Purpose AS Purpose,
		|	NestedQuery.CCDNumber,
		|	SUM(&TextNumberTransmitted) AS CountBalance,
		|	SUM(&TextQuantityTransmittedByRNPT) AS QuantityByGBRNBalance,
		|	SUM(0) AS OnDateOfControl,
		|	SUM(0) AS CurrentDate_,
		|	SUM(0) AS SumBalance
		|INTO BalanceTable
		|FROM
		|	(SELECT
		|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes.Products AS Products,
		|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes.Characteristic AS Characteristic,
		|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes.Series AS Series,
		|		ProductsFromPartnersAreLeftovers.ItemsLocationAttributes.Purpose AS Purpose,
		|		ProductsFromPartnersAreLeftovers.CCDNumber AS CCDNumber,
		|		ProductsFromPartnersAreLeftovers.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		ProductsFromPartnersAreLeftovers.DocumentLoggingIn AS DocumentLoggingIn,
		|		ProductsFromPartnersAreLeftovers.CountBalance AS Passed,
		|		ProductsFromPartnersAreLeftovers.QuantityByGBRNBalance AS TransmittedByRNPT
		|	FROM
		|		ProductsFromPartnersAreLeftovers AS ProductsFromPartnersAreLeftovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTSelection.ItemsLocationAttributes,
		|		CompanyGoods.ItemsLocationAttributes.Products,
		|		CompanyGoods.ItemsLocationAttributes.Characteristic,
		|		CompanyGoods.ItemsLocationAttributes.Series,
		|		CompanyGoods.ItemsLocationAttributes.Purpose,
		|		CompanyGoods.CCDNumber,
		|		CompanyGoods.InventoryOwnerAttribute,
		|		TTRecordersGoodsToBeReceived.DocumentLoggingIn AS DocumentLoggingIn,
		|		CASE
		|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -CompanyGoods.Count
		|			ELSE CompanyGoods.Count
		|		END AS Count,
		|		CASE
		|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
		|			ELSE CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
		|		END AS QuantityByGBRN
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoods
		|			INNER JOIN TTSelection AS TTSelection
		|			ON CompanyGoods.ItemsLocationAttributes = TTSelection.ItemsLocationAttributes
		|				AND CompanyGoods.Organization = TTSelection.Organization
		|				AND CompanyGoods.InventoryOwnerAttribute = TTSelection.InventoryOwnerAttribute
		|			INNER JOIN TTRecordersGoodsToBeReceived AS TTRecordersGoodsToBeReceived
		|			ON TTRecordersGoodsToBeReceived.Recorder = CompanyGoods.Recorder
		|	WHERE
		|		CompanyGoods.Recorder = &Recorder
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTSelection.ItemsLocationAttributes,
		|		CompanyGoods.ItemsLocationAttributes.Products,
		|		CompanyGoods.ItemsLocationAttributes.Characteristic,
		|		CompanyGoods.ItemsLocationAttributes.Series,
		|		CompanyGoods.ItemsLocationAttributes.Purpose,
		|		CompanyGoods.CCDNumber,
		|		CompanyGoods.InventoryOwnerAttribute,
		|		TTRecordersGoodsToBeReceived.DocumentLoggingIn AS DocumentLoggingIn,
		|		CASE
		|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -CompanyGoods.Count
		|			ELSE CompanyGoods.Count
		|		END AS Count,
		|		CASE
		|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
		|			ELSE CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
		|		END AS QuantityByGBRN
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoods
		|			INNER JOIN TTSelection AS TTSelection
		|			ON CompanyGoods.ItemsLocationAttributes = TTSelection.ItemsLocationAttributes
		|				AND CompanyGoods.Organization = TTSelection.Organization
		|				AND CompanyGoods.InventoryOwnerAttribute = TTSelection.InventoryOwnerAttribute
		|				AND CompanyGoods.CCDNumber = TTSelection.CCDNumber
		|			INNER JOIN TTRecordersGoodsToBeReceived AS TTRecordersGoodsToBeReceived
		|			ON TTRecordersGoodsToBeReceived.Recorder = CompanyGoods.Recorder
		|	WHERE
		|		CompanyGoods.Recorder = &ReversedDocument
		|		AND NOT CompanyGoods.ReversingEntry
		|	
		|	) AS NestedQuery
		|
		|WHERE
		|	&TextVersionOfLeftovers
		|
		|GROUP BY
		|	NestedQuery.InventoryOwnerAttribute.Organization,
		|	NestedQuery.ItemsLocationAttributes,
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Series,
		|	NestedQuery.DocumentLoggingIn,
		|	NestedQuery.InventoryOwnerAttribute,
		|	NestedQuery.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner,
		|	NestedQuery.Purpose,
		|	NestedQuery.CCDNumber
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTSelection
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductsFromPartnersAreLeftovers
		|";
		
	QueryText = QueryText + "
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
	
	TextOfConditionWithCutOffOfEmptyCCD = "NestedQuery.Passed < 0
		|AND (NOT NestedQuery.Products.KeepRecordsByCCD
		|	OR NestedQuery.Products.KeepRecordsByCCD
		|	AND NestedQuery.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
		|)";
	
	QueryText = StrReplace(QueryText,
		"&TextVersionOfLeftovers",
		?(Negative_Balance, TextOfConditionWithCutOffOfEmptyCCD, "NestedQuery.Passed > 0"));
	QueryText = StrReplace(QueryText,
		"&TextNumberTransmitted",
		?(Negative_Balance, "-NestedQuery.Passed", "NestedQuery.Passed"));
	QueryText = StrReplace(QueryText,
		"&TextQuantityTransmittedByRNPT",
		?(Negative_Balance, "-CAST(NestedQuery.TransmittedByRNPT AS NUMBER(23, 11))",
		"CAST(NestedQuery.TransmittedByRNPT AS NUMBER(23, 11))"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Partner",			  DocumentObject.Partner);
	Query.SetParameter("Contract",			  DocumentObject.Contract);
	Query.SetParameter("Counterparty",			  DocumentObject.Counterparty);
	Query.SetParameter("Recorder",		  DocumentObject.Ref);
	Query.SetParameter("ReversedDocument", ParametersForFillingInventoryTypes.ReversedDocument);
	
	Query.Execute();
	
EndProcedure

// The procedure generates a table of residues of Commission products of intercompany.
//
Procedure IntercampanyCommissionGoodsBalanceTable(DocumentObject,
														TempTablesManager,
														ParametersForFillingInventoryTypes)
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsTable.Organization					AS Organization,
	|	GoodsTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	GoodsTable.RecipientInventoryOwnerAttribute			AS RecipientInventoryOwnerAttribute,
	|	GoodsTable.CCDNumber						AS CCDNumber,
	|	GoodsTable.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|	GoodsTable.TaxInvoiceDate				AS TaxInvoiceDate,
	|	GoodsTable.TaxInvoiceNumber				AS TaxInvoiceNumber,
	|	GoodsTable.Customer					AS Customer,
	|	GoodsTable.Character							AS Character,
	|	SUM(GoodsTable.Count)				AS Count,
	|	SUM(GoodsTable.QuantityByGBRN)		AS QuantityByGBRN,
	|	SUM(GoodsTable.RevenueAmount)			AS RevenueAmount
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		Filters.Organization								AS Organization,
	|		GoodsForRegistration.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		GoodsForRegistration.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		UNDEFINED									AS RecipientInventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber						AS CCDNumber,
	|		CASE
	|			WHEN GoodsForRegistration.Recorder REFS Document.SaleAdjustment
	|						AND (CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|							OR CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|					OR CAST(GoodsForRegistration.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|				THEN GoodsForRegistration.Recorder
	|			WHEN NOT Return.Ref IS NULL
	|					AND NOT Return.CustomerVATExempt
	|				THEN UNDEFINED
	|			ELSE GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|		END											AS DocumentSalesOfGoodsAndServices,
	|		GoodsForRegistration.TaxInvoiceDate				AS TaxInvoiceDate,
	|		GoodsForRegistration.TaxInvoiceNumber				AS TaxInvoiceNumber,
	|		CASE
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.RetailSalesReport)
	|				THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoice)
	|				THEN ImplementationData.Counterparty
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoiceIntercompany)
	|				THEN GoodsHandover.CompanyRecipient
	|			WHEN VALUETYPE(GoodsForRegistration.Recorder) = TYPE(Document.ReturnOfGoodsFromCustomer)
	|				THEN Return.Counterparty
	|			WHEN GoodsForRegistration.Customer = UNDEFINED
	|					OR GoodsForRegistration.Customer = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|			ELSE GoodsForRegistration.Customer
	|		END											AS Customer,
	|		CASE
	|			WHEN (CASE
	|						WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|							THEN CASE
	|									WHEN &ThisIsWriteOffReport
	|										THEN GoodsForRegistration.QuantityConsumed
	|									ELSE GoodsForRegistration.Count
	|								END
	|						ELSE CASE
	|								WHEN &ThisIsWriteOffReport
	|									THEN -GoodsForRegistration.QuantityConsumed
	|								ELSE -GoodsForRegistration.Count
	|							END
	|					END) >= 0
	|				THEN 1
	|			ELSE -1
	|		END											AS Character,
	|		SUM(CASE
	|				WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CASE
	|							WHEN &ThisIsWriteOffReport
	|								THEN GoodsForRegistration.QuantityConsumed
	|							ELSE GoodsForRegistration.Count
	|						END
	|				ELSE CASE
	|						WHEN &ThisIsWriteOffReport
	|							THEN -GoodsForRegistration.QuantityConsumed
	|						ELSE -GoodsForRegistration.Count
	|					END
	|			END)										AS Count,
	|		SUM(CASE
	|				WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CASE
	|							WHEN &ThisIsWriteOffReport
	|								THEN CAST(GoodsForRegistration.QuantityIsWrittenOffForRegistrationByProductBatchID AS NUMBER(23, 11))
	|							ELSE CAST(GoodsForRegistration.QuantityForRegistrationByProductBatchID AS NUMBER(23, 11))
	|						END
	|				ELSE CASE
	|						WHEN &ThisIsWriteOffReport
	|							THEN -CAST(GoodsForRegistration.QuantityIsWrittenOffForRegistrationByProductBatchID AS NUMBER(23, 11))
	|						ELSE -CAST(GoodsForRegistration.QuantityForRegistrationByProductBatchID AS NUMBER(23, 11))
	|					END
	|			END) AS QuantityByGBRN,
	|		SUM(CASE
	|				WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN GoodsForRegistration.RevenueAmount
	|				ELSE -GoodsForRegistration.RevenueAmount
	|			END)										AS RevenueAmount
	|	FROM
	|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|			INNER JOIN TTSelectionsOfBusinessBalances AS Filters
	|			ON Filters.ItemsLocationAttributes = GoodsForRegistration.ItemsLocationAttributes
	|				AND Filters.InventoryOwnerAttribute = GoodsForRegistration.InventoryOwnerAttribute
	|			
	|			LEFT JOIN Document.ReturnOfGoodsFromCustomer AS Return
	|			ON Return.Ref = GoodsForRegistration.Recorder
	|			
	|			LEFT JOIN Document.CustomerInvoice AS ImplementationData
	|			ON GoodsForRegistration.DocumentSalesOfGoodsAndServices = ImplementationData.Ref
	|			
	|			LEFT JOIN Document.CustomerInvoiceIntercompany AS GoodsHandover
	|			ON GoodsForRegistration.DocumentSalesOfGoodsAndServices = GoodsHandover.Ref
	|	
	|	WHERE
	|		GoodsForRegistration.Active
	|		AND GoodsForRegistration.Recorder <> &CurrentReport
	|		AND GoodsForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	
	|	GROUP BY
	|		GoodsForRegistration.TaxInvoiceDate,
	|		GoodsForRegistration.TaxInvoiceNumber,
	|		CASE
	|			WHEN GoodsForRegistration.Recorder REFS Document.SaleAdjustment
	|						AND (CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|							OR CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|					OR CAST(GoodsForRegistration.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|				THEN GoodsForRegistration.Recorder
	|			WHEN NOT Return.Ref IS NULL
	|					AND NOT Return.CustomerVATExempt
	|				THEN UNDEFINED
	|			ELSE GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|		END,
	|		CASE
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.RetailSalesReport)
	|				THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoice)
	|				THEN ImplementationData.Counterparty
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoiceIntercompany)
	|				THEN GoodsHandover.CompanyRecipient
	|			WHEN VALUETYPE(GoodsForRegistration.Recorder) = TYPE(Document.ReturnOfGoodsFromCustomer)
	|				THEN Return.Counterparty
	|			WHEN GoodsForRegistration.Customer = UNDEFINED
	|					OR GoodsForRegistration.Customer = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|			ELSE GoodsForRegistration.Customer
	|		END,
	|		GoodsForRegistration.ItemsLocationAttributes,
	|		Filters.Organization,
	|		GoodsForRegistration.InventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber,
	|		CASE
	|			WHEN (CASE
	|						WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|							THEN CASE
	|									WHEN &ThisIsWriteOffReport
	|										THEN GoodsForRegistration.QuantityConsumed
	|									ELSE GoodsForRegistration.Count
	|								END
	|						ELSE CASE
	|								WHEN &ThisIsWriteOffReport
	|									THEN -GoodsForRegistration.QuantityConsumed
	|								ELSE -GoodsForRegistration.Count
	|							END
	|					END) >= 0
	|				THEN 1
	|			ELSE -1
	|		END
	|	
	|	HAVING
	|		SUM(CASE
	|				WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CASE
	|							WHEN &ThisIsWriteOffReport
	|								THEN GoodsForRegistration.QuantityConsumed
	|							ELSE GoodsForRegistration.Count
	|						END
	|				ELSE CASE
	|						WHEN &ThisIsWriteOffReport
	|							THEN -GoodsForRegistration.QuantityConsumed
	|						ELSE -GoodsForRegistration.Count
	|					END
	|			END) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Filters.Organization								AS Organization,
	|		GoodsForRegistration.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		GoodsForRegistration.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		UNDEFINED									AS RecipientInventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber						AS CCDNumber,
	|		CASE
	|			WHEN GoodsForRegistration.Recorder REFS Document.SaleAdjustment
	|						AND (CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|							OR CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|					OR CAST(GoodsForRegistration.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|				THEN GoodsForRegistration.Recorder
	|			WHEN NOT Return.Ref IS NULL
	|					AND NOT Return.CustomerVATExempt
	|				THEN UNDEFINED
	|			ELSE GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|		END											AS DocumentSalesOfGoodsAndServices,
	|		GoodsForRegistration.TaxInvoiceDate				AS TaxInvoiceDate,
	|		GoodsForRegistration.TaxInvoiceNumber				AS TaxInvoiceNumber,
	|		CASE
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.RetailSalesReport)
	|				THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoice)
	|				THEN ImplementationData.Counterparty
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoiceIntercompany)
	|				THEN GoodsHandover.CompanyRecipient
	|			WHEN VALUETYPE(GoodsForRegistration.Recorder) = TYPE(Document.ReturnOfGoodsFromCustomer)
	|				THEN Return.Counterparty
	|			WHEN GoodsForRegistration.Customer = UNDEFINED
	|					OR GoodsForRegistration.Customer = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|			ELSE GoodsForRegistration.Customer
	|		END											AS Customer,
	|		CASE
	|			WHEN (CASE
	|						WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|							THEN CASE
	|									WHEN &ThisIsWriteOffReport
	|										THEN -GoodsForRegistration.QuantityConsumed
	|									ELSE -GoodsForRegistration.Count
	|								END
	|						ELSE CASE
	|								WHEN &ThisIsWriteOffReport
	|									THEN GoodsForRegistration.QuantityConsumed
	|								ELSE GoodsForRegistration.Count
	|							END
	|					END) >= 0
	|				THEN 1
	|			ELSE -1
	|		END											AS Character,
	|		SUM(CASE
	|				WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CASE
	|							WHEN &ThisIsWriteOffReport
	|								THEN -GoodsForRegistration.QuantityConsumed
	|							ELSE -GoodsForRegistration.Count
	|						END
	|				ELSE CASE
	|						WHEN &ThisIsWriteOffReport
	|							THEN GoodsForRegistration.QuantityConsumed
	|						ELSE GoodsForRegistration.Count
	|					END
	|			END)										AS Count,
	|		SUM(CASE
	|				WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CASE
	|							WHEN &ThisIsWriteOffReport
	|								THEN -CAST(GoodsForRegistration.QuantityIsWrittenOffForRegistrationByProductBatchID AS NUMBER(23, 11))
	|							ELSE -CAST(GoodsForRegistration.QuantityForRegistrationByProductBatchID AS NUMBER(23, 11))
	|						END
	|				ELSE CASE
	|						WHEN &ThisIsWriteOffReport
	|							THEN CAST(GoodsForRegistration.QuantityIsWrittenOffForRegistrationByProductBatchID AS NUMBER(23, 11))
	|						ELSE CAST(GoodsForRegistration.QuantityForRegistrationByProductBatchID AS NUMBER(23, 11))
	|					END
	|			END) AS QuantityByGBRN,
	|		SUM(CASE
	|				WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -GoodsForRegistration.RevenueAmount
	|				ELSE GoodsForRegistration.RevenueAmount
	|			END)										AS RevenueAmount
	|	FROM
	|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|			INNER JOIN TTSelectionsOfBusinessBalances AS Filters
	|			ON Filters.ItemsLocationAttributes = GoodsForRegistration.ItemsLocationAttributes
	|				AND Filters.InventoryOwnerAttribute = GoodsForRegistration.InventoryOwnerAttribute
	|			
	|			LEFT JOIN Document.ReturnOfGoodsFromCustomer AS Return
	|			ON Return.Ref = GoodsForRegistration.Recorder
	|			
	|			LEFT JOIN Document.CustomerInvoice AS ImplementationData
	|			ON GoodsForRegistration.DocumentSalesOfGoodsAndServices = ImplementationData.Ref
	|			
	|			LEFT JOIN Document.CustomerInvoiceIntercompany AS GoodsHandover
	|			ON GoodsForRegistration.DocumentSalesOfGoodsAndServices = GoodsHandover.Ref
	|	
	|	WHERE
	|		NOT GoodsForRegistration.ReversingEntry
	|		AND GoodsForRegistration.Active
	|		AND GoodsForRegistration.Recorder = &ReversedDocument
	|		AND GoodsForRegistration.Period <= &EndOfPeriod
	|	
	|	GROUP BY
	|		GoodsForRegistration.TaxInvoiceDate,
	|		GoodsForRegistration.TaxInvoiceNumber,
	|		CASE
	|			WHEN GoodsForRegistration.Recorder REFS Document.SaleAdjustment
	|						AND (CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|							OR CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|					OR CAST(GoodsForRegistration.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|				THEN GoodsForRegistration.Recorder
	|			WHEN NOT Return.Ref IS NULL
	|					AND NOT Return.CustomerVATExempt
	|				THEN UNDEFINED
	|			ELSE GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|		END,
	|		CASE
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.RetailSalesReport)
	|				THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoice)
	|				THEN ImplementationData.Counterparty
	|			WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoiceIntercompany)
	|				THEN GoodsHandover.CompanyRecipient
	|			WHEN VALUETYPE(GoodsForRegistration.Recorder) = TYPE(Document.ReturnOfGoodsFromCustomer)
	|				THEN Return.Counterparty
	|			WHEN GoodsForRegistration.Customer = UNDEFINED
	|					OR GoodsForRegistration.Customer = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|			ELSE GoodsForRegistration.Customer
	|		END,
	|		GoodsForRegistration.ItemsLocationAttributes,
	|		Filters.Organization,
	|		GoodsForRegistration.InventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber,
	|		CASE
	|			WHEN (CASE
	|						WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|							THEN CASE
	|									WHEN &ThisIsWriteOffReport
	|										THEN -GoodsForRegistration.QuantityConsumed
	|									ELSE -GoodsForRegistration.Count
	|								END
	|						ELSE CASE
	|								WHEN &ThisIsWriteOffReport
	|									THEN GoodsForRegistration.QuantityConsumed
	|								ELSE GoodsForRegistration.Count
	|							END
	|					END) >= 0
	|				THEN 1
	|			ELSE -1
	|		END
	|	
	|	HAVING
	|		SUM(CASE
	|				WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CASE
	|							WHEN &ThisIsWriteOffReport
	|								THEN -GoodsForRegistration.QuantityConsumed
	|							ELSE -GoodsForRegistration.Count
	|						END
	|				ELSE CASE
	|						WHEN &ThisIsWriteOffReport
	|							THEN GoodsForRegistration.QuantityConsumed
	|						ELSE GoodsForRegistration.Count
	|					END
	|			END) <> 0
	|	
	|	) AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Organization,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.RecipientInventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.DocumentSalesOfGoodsAndServices,
	|	GoodsTable.TaxInvoiceDate,
	|	GoodsTable.TaxInvoiceNumber,
	|	GoodsTable.Customer,
	|	GoodsTable.Character
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	
	Query.TempTablesManager = TempTablesManager;
	Boundary = New Boundary(DocumentObject.EndOfPeriod, BoundaryType.Including);
	
	Query.SetParameter("Boundary",				Boundary);
	Query.SetParameter("BeginOfPeriod",			DocumentObject.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",			EndOfMonth(DocumentObject.EndOfPeriod));
	Query.SetParameter("Organization",			DocumentObject.Organization);
	Query.SetParameter("CurrentReport",			DocumentObject.Ref);
	Query.SetParameter("ThisIsWriteOffReport",		TypeOf(DocumentObject.Ref) = Type("DocumentRef.CommissionWriteOffReportIntercompany"));
	Query.SetParameter("ReversedDocument",	ParametersForFillingInventoryTypes.ReversedDocument);
	
	Query.Execute();
	
	VATAccountingERP.SupplementTableWithDataOfInvoicesIssuedToCustomers(TempTablesManager, "BalanceTable");
	
EndProcedure

// The procedure generates a table of product balances transferred to the Commission.
//
Procedure TableOfBalancesOfGoodsTransferredToCommission(DocumentObject,
													ParametersForFillingInventoryTypes,
													TempTablesManager,
													DateOfRemainingGoods)
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic
	|INTO TTSelectionByProductName
	|FROM
	|	TTSelectionsOfBusinessBalances AS Filters
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Filters.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Dimension.DimensionKey AS ItemsLocationAttributes
	|INTO TTSelectionBasedOnPartnerAnalytics
	|FROM
	|	TableOfGoods AS Goods
	|	
	|	INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Goods.Products = Dimension.Products
	|		AND Goods.Characteristic = Dimension.Characteristic
	|		AND Goods.Purpose = Dimension.Purpose
	|		AND Dimension.StorageLocation = &Partner
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanyGoods.Organization AS Organization,
	|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoods.ItemsLocationAttributes.Products AS Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.Series AS Series,
	|	CompanyGoods.ItemsLocationAttributes.StorageLocation AS OriginWarehouse,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	CASE
	|		WHEN &ThisIsCommissionAgentSReport
	|			THEN CompanyGoods.InventoryOwnerAttribute
	|		WHEN ISNULL(InventoryKinds.SaleOfAnotherCompanyInventory, FALSE)
	|			THEN UNDEFINED
	|		ELSE CompanyGoods.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	UNDEFINED AS RecipientInventoryOwnerAttribute,
	|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	CompanyGoods.ItemsLocationAttributes.Purpose AS Purpose,
	|	CompanyGoods.CCDNumber AS CCDNumber,
	|	CompanyGoods.Character,
	|	MAX(CompanyGoods.DateOfReceipt) AS DateOfReceipt,
	|	SUM(CompanyGoods.Count) AS CountBalance,
	|	SUM(CompanyGoods.QuantityByGBRN) AS QuantityByGBRNBalance,
	|	0 AS SumBalance
	|
	|INTO BalanceTable
	|FROM (
	|	SELECT
	|		Goods.Organization AS Organization,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		Goods.CountBalance AS Count,
	|		CASE
	|			WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(DatesOfConsignmentGoodsTransfer.TransferDate, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|				THEN CAST(Goods.QuantityByGBRNBalance AS NUMBER(23, 11))
	|			ELSE 0
	|		END AS QuantityByGBRN,
	|		CASE
	|			WHEN Goods.CountBalance < 1
	|				THEN -1
	|			ELSE 1
	|		END AS Character,
	|		DatesOfConsignmentGoodsTransfer.TransferDate AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(&MonthBoundary,
	|			ItemsLocationAttributes IN 
	|				(SELECT
	|					Filter.ItemsLocationAttributes
	|				FROM
	|					TTSelectionBasedOnPartnerAnalytics AS Filter)
	|				AND Terms = &Terms
	|				AND Organization = &Organization
	|		) AS Goods
	|		
	|		LEFT JOIN InformationRegister.DatesOfConsignmentGoodsTransfer AS DatesOfConsignmentGoodsTransfer
	|			ON Goods.InventoryOwnerAttribute = DatesOfConsignmentGoodsTransfer.InventoryOwnerAttribute
	|			AND Goods.ItemsLocationAttributes = DatesOfConsignmentGoodsTransfer.ItemsLocationAttributes
	|			AND Goods.CCDNumber = DatesOfConsignmentGoodsTransfer.CCDNumber
	|			AND Goods.Terms = DatesOfConsignmentGoodsTransfer.Terms
	|			AND Goods.Organization = DatesOfConsignmentGoodsTransfer.Organization
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Organization AS Organization,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		CASE
	|			WHEN Goods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Goods.Count
	|			ELSE -Goods.Count
	|		END AS Count,
	|		-(CASE
	|			WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(DatesOfConsignmentGoodsTransfer.TransferDate, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|				THEN CASE
	|					WHEN Goods.RecordType = VALUE(AccumulationRecordType.Expense)
	|						THEN -CAST(Goods.QuantityByGBRN AS NUMBER(23, 11))
	|					ELSE
	|						CAST(Goods.QuantityByGBRN AS NUMBER(23, 11))
	|				END
	|			ELSE 0
	|		END) AS QuantityByGBRN,
	|		CASE
	|			WHEN Goods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CASE
	|						WHEN Goods.Count >= 0
	|							THEN 1
	|						ELSE -1
	|					END
	|			ELSE CASE
	|					WHEN Goods.Count >= 0
	|						THEN -1
	|					ELSE 1
	|				END
	|		END AS Character,
	|		DatesOfConsignmentGoodsTransfer.TransferDate AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.GoodsTransferredToCommissionAgent AS Goods
	|		LEFT JOIN InformationRegister.DatesOfConsignmentGoodsTransfer AS DatesOfConsignmentGoodsTransfer
	|			ON Goods.InventoryOwnerAttribute = DatesOfConsignmentGoodsTransfer.InventoryOwnerAttribute
	|			AND Goods.ItemsLocationAttributes = DatesOfConsignmentGoodsTransfer.ItemsLocationAttributes
	|			AND Goods.CCDNumber = DatesOfConsignmentGoodsTransfer.CCDNumber
	|			AND Goods.Terms = DatesOfConsignmentGoodsTransfer.Terms
	|			AND Goods.Organization = DatesOfConsignmentGoodsTransfer.Organization
	|	
	|	WHERE
	|		Goods.Period <= &EndOfPeriod
	|		AND Goods.Recorder = &Ref
	|		AND Goods.Active
	|		AND Goods.Organization = &Organization
	|		AND Goods.ItemsLocationAttributes.StorageLocation = &Partner
	|		AND Goods.Terms = &Terms
	|		AND Goods.ItemsLocationAttributes IN
	|				(SELECT
	|					Filter.ItemsLocationAttributes
	|				FROM
	|					TTSelectionBasedOnPartnerAnalytics AS Filter)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Organization AS Organization,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		CASE
	|			WHEN Goods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Goods.Count
	|			ELSE -Goods.Count
	|		END AS Count,
	|		0 AS QuantityByGBRN,
	|		CASE
	|			WHEN Goods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CASE
	|						WHEN Goods.Count >= 0
	|							THEN 1
	|						ELSE -1
	|					END
	|			ELSE CASE
	|					WHEN Goods.Count >= 0
	|						THEN -1
	|					ELSE 1
	|				END
	|		END AS Character,
	|		DatesOfConsignmentGoodsTransfer.TransferDate AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.GoodsTransferredToCommissionAgent AS Goods
	|		LEFT JOIN InformationRegister.DatesOfConsignmentGoodsTransfer AS DatesOfConsignmentGoodsTransfer
	|			ON Goods.InventoryOwnerAttribute = DatesOfConsignmentGoodsTransfer.InventoryOwnerAttribute
	|			AND Goods.ItemsLocationAttributes = DatesOfConsignmentGoodsTransfer.ItemsLocationAttributes
	|			AND Goods.CCDNumber = DatesOfConsignmentGoodsTransfer.CCDNumber
	|			AND Goods.Terms = DatesOfConsignmentGoodsTransfer.Terms
	|			AND Goods.Organization = DatesOfConsignmentGoodsTransfer.Organization
	|	
	|	WHERE
	|		NOT Goods.ReversingEntry
	|		AND Goods.Active
	|		AND Goods.Period <= &EndOfPeriod
	|		AND Goods.Terms = &Terms
	|		AND Goods.Organization = &Organization
	|		AND Goods.Recorder = &ReversedDocument
	|		AND Goods.ItemsLocationAttributes.StorageLocation = &Partner
	|		AND Goods.ItemsLocationAttributes IN
	|				(SELECT
	|					Filter.ItemsLocationAttributes
	|				FROM
	|					TTSelectionBasedOnPartnerAnalytics AS Filter)
	|	
	|	UNION ALL
	|	
	|	SELECT // Returnable containers written off by the document
	|		RegisterRecords.InventoryOwnerAttribute.Organization AS Organization,
	|		Dimension.DimensionKey AS ItemsLocationAttributes,
	|		RegisterRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		RegisterRecords.CCDNumber AS CCDNumber,
	|		RegisterRecords.Count AS Count,
	|		CASE
	|			WHEN &UseTraceableImportedGoodsAccounting
	|					AND BEGINOFPERIOD(RegisterRecords.DocumentTransfers_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|				THEN CAST(RegisterRecords.QuantityByGBRN AS NUMBER(23, 11))
	|			ELSE 0
	|		END AS QuantityByGBRN,
	|		0 AS Character,
	|		RegisterRecords.DocumentTransfers_.Date AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.TransferredReturnablePackaging AS RegisterRecords
	|	
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON RegisterRecords.Products = Dimension.Products
	|			AND RegisterRecords.Characteristic = Dimension.Characteristic
	|			AND RegisterRecords.Partner = Dimension.StorageLocation
	|			AND Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND Dimension.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		RegisterRecords.Recorder = &Ref
	|		AND RegisterRecords.Active
	|		AND RegisterRecords.InventoryOwnerAttribute.Organization = &Organization
	|		AND RegisterRecords.Partner = &Partner
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|
	|	UNION ALL
	|
	|	SELECT // Transferred to returnable packaging
	|		Balance.InventoryOwnerAttribute.Organization AS Organization,
	|		Dimension.DimensionKey AS ItemsLocationAttributes,
	|		Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Balance.CCDNumber AS CCDNumber,
	|		Balance.CountBalance AS Count,
	|		CASE
	|			WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(Balance.DocumentTransfers_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|				THEN CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11))
	|			ELSE 0
	|		END AS QuantityByGBRN,
	|		0 AS Character,
	|		Balance.DocumentTransfers_.Date AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.TransferredReturnablePackaging.Balance(&MonthBoundary,
	|			InventoryOwnerAttribute.Organization = &Organization
	|			AND Partner = &Partner
	|			AND (Products, Characteristic) IN (
	|				SELECT DISTINCT
	|					TTSelectionByProductName.Products,
	|					TTSelectionByProductName.Characteristic
	|				FROM
	|					TTSelectionByProductName AS TTSelectionByProductName
	|				)
	|		) AS Balance
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Balance.Products = Dimension.Products
	|			AND Balance.Characteristic = Dimension.Characteristic
	|			AND Balance.Partner = Dimension.StorageLocation
	|			AND Dimension.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|
	|	) AS CompanyGoods
	|	
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON CompanyGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|
	|GROUP BY
	|	CompanyGoods.Organization,
	|	CompanyGoods.ItemsLocationAttributes,
	|	CompanyGoods.ItemsLocationAttributes.Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.Series,
	|	CompanyGoods.ItemsLocationAttributes.StorageLocation,
	|	CASE
	|		WHEN &ThisIsCommissionAgentSReport
	|			THEN CompanyGoods.InventoryOwnerAttribute
	|		WHEN ISNULL(InventoryKinds.SaleOfAnotherCompanyInventory, FALSE)
	|			THEN UNDEFINED
	|		ELSE CompanyGoods.InventoryOwnerAttribute
	|	END,
	|	CompanyGoods.InventoryOwnerAttribute,
	|	CompanyGoods.ItemsLocationAttributes.Purpose,
	|	CompanyGoods.CCDNumber,
	|	CompanyGoods.Character
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|DROP TTSelectionByProductName
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|DROP TTSelectionBasedOnPartnerAnalytics
	|";

	Query.SetParameter("MonthBoundary",	New Boundary(EndOfMonth(DateOfRemainingGoods), BoundaryType.Including));
	Query.SetParameter("BeginOfPeriod",	BegOfMonth(DateOfRemainingGoods));
	Query.SetParameter("EndOfPeriod",	EndOfMonth(DateOfRemainingGoods));
	Query.SetParameter("Ref",			DocumentObject.Ref);
	Query.SetParameter("Organization",	DocumentObject.Organization);
	Query.SetParameter("BusinessOperation",
								?(TypeOf(DocumentObject.Ref) = Type("DocumentRef.ReturnOfGoodsFromCustomer"),
									DocumentObject.BusinessOperation,
									Undefined));
	Query.SetParameter("ThisIsCommissionAgentSReport",
								TypeOf(DocumentObject.Ref) = Type("DocumentRef.ConsignmentReportFromCustomer")
								Or TypeOf(DocumentObject.Ref) = Type("DocumentRef.WriteOffReportFromCommissionAgent"));
	
	If TypeOf(DocumentObject.Ref) = Type("DocumentRef.CommissionReportIntercompany")
		Or TypeOf(DocumentObject.Ref) = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
		
		Query.SetParameter("Partner",	DocumentObject.Consignee);
		Query.SetParameter("Terms", Catalogs.TermsOfSale.EmptyRef());
		
	Else
		Query.SetParameter("Partner",	DocumentObject.Partner);
		Query.SetParameter("Terms",	DocumentObject.Terms);
	EndIf;
	
	Query.SetParameter("ReversedDocument", ParametersForFillingInventoryTypes.ReversedDocument);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
EndProcedure

// The procedure generates a table of the remaining goods sold.
//
Procedure TableOfBalancesOfGoodsSold(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT DISTINCT
	|	TableOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	CAST(TableOfGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	&FieldTextTableOfGoodsPartnerProducts_ AS PartnerProducts	
	|INTO GroupedTableOfProducts
	|FROM
	|	TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.DocumentSalesOfGoodsAndServices AS Ref,
	|	InventoryLocationAttributeKeys.DimensionKey AS ItemsLocationAttributes
	|INTO TableOfProductsWithKeysForAllWarehouses
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryLocationAttributeKeys
	|		ON TableOfGoods.Products = InventoryLocationAttributeKeys.Products
	|			AND TableOfGoods.Characteristic = InventoryLocationAttributeKeys.Characteristic
	|			AND (&ThisIsReturn
	|				OR (NOT &ThisIsReturn
	|					AND TableOfGoods.Series = InventoryLocationAttributeKeys.Series))
	|WHERE
	|	TableOfGoods.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributesShipment,
	|	TSInventoryKinds.Ref AS DocumentSalesOfGoodsAndServices,
	|	TSInventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber AS CCDNumber,
	|	TSInventoryKinds.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CAST(TSInventoryKinds.QuantityByGBRN AS NUMBER(23, 11))
	|	END AS QuantityByGBRN,
	|	TSInventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.VATAmount
	|		ELSE 0
	|	END AS VATAmount
	|INTO SoldGoods
	|FROM
	|	Document.CustomerInvoice.InventoryKinds AS TSInventoryKinds
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND (TSInventoryKinds.Ref, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributesShipment,
	|	TSInventoryKinds.Ref AS DocumentSalesOfGoodsAndServices,
	|	TSInventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TSInventoryKinds.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber AS CCDNumber,
	|	TSInventoryKinds.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TSInventoryKinds.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	TSInventoryKinds.VATAmount AS VATAmount
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS TSInventoryKinds
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND (TSInventoryKinds.Ref, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributes,
	|	TSInventoryKinds.Ref,
	|	TSInventoryKinds.InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber,
	|	TSInventoryKinds.Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CAST(TSInventoryKinds.QuantityByGBRN AS NUMBER(23, 11))
	|	END AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	0 AS VATAmount
	|FROM
	|	Document.RetailSalesReport.InventoryKinds AS TSInventoryKinds
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	(TSInventoryKinds.Ref, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND DocumentDataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributesShipment,
	|	TSInventoryKinds.DocumentSalesOfGoodsAndServices,
	|	TSInventoryKinds.InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber,
	|	-TSInventoryKinds.Count,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	0 AS VATAmount
	|FROM
	|	Document.RetailReturnsReport.InventoryKinds AS TSInventoryKinds
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|WHERE
	|	TSInventoryKinds.Ref <> &Ref
	|	AND (TSInventoryKinds.DocumentSalesOfGoodsAndServices, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Posted
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND DocumentDataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributes,
	|	TSInventoryKinds.Ref.DocumentBasis,
	|	TSInventoryKinds.InventoryOwnerAttribute,
	|	TSInventoryKinds.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.Count
	|		ELSE 0
	|	END AS Count,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN CASE
	|					WHEN NOT &UseTraceableImportedGoodsAccounting
	|							OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|						THEN 0
	|					ELSE CAST(TSInventoryKinds.QuantityByGBRN AS NUMBER(23, 11))
	|				END
	|			ELSE 0
	|	END AS QuantityByGBRN,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.ExciseTaxAmount
	|		ELSE 0
	|	END AS ExciseTaxAmount,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.VATAmount
	|		ELSE 0
	|	END AS VATAmount
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS TSInventoryKinds
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref <> &Ref
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND NOT &CreditNoteAdjustmentAfterTransferOfOwnership
	|	AND (TSInventoryKinds.Ref.DocumentBasis, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Posted
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.CorItemsLocationAttributes,
	|	TSInventoryKinds.Ref.DocumentBasis,
	|	TSInventoryKinds.InventoryOwnerAttribute,
	|	TSInventoryKinds.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.Count
	|		ELSE 0
	|	END AS Count,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN CASE
	|					WHEN NOT &UseTraceableImportedGoodsAccounting
	|							OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|						THEN 0
	|					ELSE CAST(TSInventoryKinds.QuantityByGBRN AS NUMBER(23, 11))
	|				END
	|			ELSE 0
	|	END AS QuantityByGBRN,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.ExciseTaxAmount
	|		ELSE 0
	|	END AS ExciseTaxAmount,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.VATAmount
	|		ELSE 0
	|	END AS VATAmount
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS TSInventoryKinds
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref <> &Ref
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND &CreditNoteAdjustmentAfterTransferOfOwnership
	|	AND (TSInventoryKinds.Ref.DocumentBasis, TSInventoryKinds.CorItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Posted
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributes,
	|	TSInventoryKinds.Ref.DocumentBasis,
	|	TSInventoryKinds.InventoryOwnerAttribute,
	|	TSInventoryKinds.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN -TSInventoryKinds.Count
	|		ELSE 0
	|	END AS Count,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN CASE
	|					WHEN NOT &UseTraceableImportedGoodsAccounting
	|							OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|						THEN 0
	|					ELSE -CAST(TSInventoryKinds.QuantityByGBRN AS NUMBER(23, 11))
	|				END
	|			ELSE 0
	|	END AS QuantityByGBRN,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN -TSInventoryKinds.ExciseTaxAmount
	|		ELSE 0
	|	END AS ExciseTaxAmount,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN -TSInventoryKinds.VATAmount
	|		ELSE 0
	|	END AS VATAmount
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS TSInventoryKinds
	|		
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref <> &Ref
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND NOT &CreditNoteAdjustmentAfterTransferOfOwnership
	|	AND (TSInventoryKinds.Ref.DocumentBasis, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Posted
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.CorItemsLocationAttributes,
	|	TSInventoryKinds.Ref.DocumentBasis,
	|	TSInventoryKinds.InventoryOwnerAttribute,
	|	TSInventoryKinds.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN -TSInventoryKinds.Count
	|		ELSE 0
	|	END AS Count,
	|	CASE
	|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
	|				OR &ThisIsImplementationAdjustment
	|			THEN CASE
	|					WHEN NOT &UseTraceableImportedGoodsAccounting
	|							OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|						THEN 0
	|					ELSE -CAST(TSInventoryKinds.QuantityByGBRN AS NUMBER(23, 11))
	|				END
	|			ELSE 0
	|	END AS QuantityByGBRN,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN -TSInventoryKinds.ExciseTaxAmount
	|		ELSE 0
	|	END AS ExciseTaxAmount,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN -TSInventoryKinds.VATAmount
	|		ELSE 0
	|	END AS VATAmount
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS TSInventoryKinds
	|		LEFT JOIN Document.CustomerInvoice AS CustomerInvoice
	|		ON TSInventoryKinds.Ref.DocumentBasis = CustomerInvoice.Ref
	|		
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref <> &Ref
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND &CreditNoteAdjustmentAfterTransferOfOwnership
	|	AND (TSInventoryKinds.Ref.DocumentBasis, TSInventoryKinds.CorItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Posted
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributes,
	|	TSInventoryKinds.Ref.DocumentBasis,
	|	TSInventoryKinds.InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber,
	|	0,
	|	0,
	|	0 AS ExciseTaxAmount,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.VATAmount
	|		ELSE 0
	|	END AS VATAmount
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS TSInventoryKinds
	|		
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref <> &Ref
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND (TSInventoryKinds.Ref.DocumentBasis, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Posted
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributesShipment,
	|	TSInventoryKinds.DocumentSalesOfGoodsAndServices,
	|	TSInventoryKinds.InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber,
	|	-TSInventoryKinds.Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE -CAST(TSInventoryKinds.QuantityByGBRN AS NUMBER(23, 11))
	|	END AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	0 AS VATAmount
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS TSInventoryKinds
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref <> &Ref
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND (TSInventoryKinds.DocumentSalesOfGoodsAndServices, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Posted
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|UNION ALL
	|
	|SELECT
	|	TSInventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributesShipment,
	|	TSInventoryKinds.Ref AS DocumentSalesOfGoodsAndServices,
	|	TSInventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber AS CCDNumber,
	|	TSInventoryKinds.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(TSInventoryKinds.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CAST(TSInventoryKinds.QuantityByGBRN AS NUMBER(23, 11))
	|	END AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	CASE
	|		WHEN &ThisIsImplementationAdjustment
	|			THEN TSInventoryKinds.VATAmount
	|		ELSE 0
	|	END AS VATAmount
	|FROM
	|	Document.CustomerInvoiceServices.InventoryKinds AS TSInventoryKinds
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TSInventoryKinds.Ref.Organization = DocumentDataTable.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	TSInventoryKinds.Ref.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND (TSInventoryKinds.Ref, TSInventoryKinds.ItemsLocationAttributes) IN
	|			(SELECT
	|				TableOfProductsWithKeysForAllWarehouses.Ref,
	|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
	|			FROM
	|				TableOfProductsWithKeysForAllWarehouses)
	|	AND TSInventoryKinds.Ref.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
	|	AND (TSInventoryKinds.InventoryOwnerAttribute, TRUE) IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute, TRUE
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|INDEX BY
	|	ItemsLocationAttributesShipment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.DocumentSalesOfGoodsAndServices					AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.ItemsLocationAttributesShipment	AS ItemsLocationAttributesShipment,
	|	DimensionKeys.Products							AS Products,
	|	DimensionKeys.Characteristic						AS Characteristic,
	|	DimensionKeys.Purpose							AS Purpose,
	|	DimensionKeys.Series								AS Series,
	|	DimensionKeys.StorageLocation						AS StorageLocation,
	|	TableOfGoods.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	TableOfGoods.CorInventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|	TableOfGoods.CCDNumber								AS CCDNumber,
	|	SUM(TableOfGoods.Count)					AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN)				AS QuantityByGBRN,
	|	SUM(TableOfGoods.ExciseTaxAmount)					AS ExciseTaxAmount,
	|	SUM(TableOfGoods.VATAmount)						AS VATAmount
	|INTO GoodsSoldGrouped
	|FROM
	|	SoldGoods AS TableOfGoods
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TableOfGoods.ItemsLocationAttributesShipment = DimensionKeys.Ref
	|
	|GROUP BY
	|	TableOfGoods.DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.ItemsLocationAttributesShipment,
	|	DimensionKeys.Products,
	|	DimensionKeys.Characteristic,
	|	DimensionKeys.Purpose,
	|	DimensionKeys.Series,
	|	DimensionKeys.StorageLocation,
	|	TableOfGoods.InventoryOwnerAttribute,
	|	TableOfGoods.CorInventoryOwnerAttribute,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	SUM(TableOfGoods.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.DocumentSalesOfGoodsAndServices				AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod	AS CostDefiningMethod,
	|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	DimensionKeys.Products						AS Products,
	|	DimensionKeys.Characteristic					AS Characteristic,
	|	DimensionKeys.Purpose						AS Purpose,
	|	DimensionKeys.Series							AS Series,
	|	DimensionKeys.StorageLocation					AS StorageLocation,
	|	SoldGoods.Series						AS BatchForConnection,
	|	TableOfGoods.PartnerProducts				AS PartnerProducts
	|INTO GoodsTableForConnection
	|FROM
	|	GroupedTableOfProducts AS TableOfGoods
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TableOfGoods.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		INNER JOIN GoodsSoldGrouped AS SoldGoods
	|		ON DimensionKeys.Products = SoldGoods.Products
	|			AND DimensionKeys.Characteristic = SoldGoods.Characteristic
	|			AND (DimensionKeys.Series = SoldGoods.Series
	|				OR DimensionKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|WHERE
	|	&ThisIsReturn
	|	AND NOT SoldGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TableOfGoods.DocumentSalesOfGoodsAndServices				AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod	AS CostDefiningMethod,
	|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	DimensionKeys.Products						AS Products,
	|	DimensionKeys.Characteristic					AS Characteristic,
	|	DimensionKeys.Purpose						AS Purpose,
	|	DimensionKeys.Series							AS Series,
	|	DimensionKeys.StorageLocation					AS StorageLocation,
	|	SoldGoods.Series						AS BatchForConnection,
	|	TableOfGoods.PartnerProducts				AS PartnerProducts
	|FROM
	|	GroupedTableOfProducts AS TableOfGoods
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TableOfGoods.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		INNER JOIN GoodsSoldGrouped AS SoldGoods
	|		ON DimensionKeys.Products = SoldGoods.Products
	|			AND DimensionKeys.Characteristic = SoldGoods.Characteristic
	|			AND (DimensionKeys.Series = SoldGoods.Series
	|				OR NOT DimensionKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|WHERE
	|	&ThisIsReturn
	|	AND SoldGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TableOfGoods.DocumentSalesOfGoodsAndServices				AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod	AS CostDefiningMethod,
	|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	DimensionKeys.Products						AS Products,
	|	DimensionKeys.Characteristic					AS Characteristic,
	|	DimensionKeys.Purpose						AS Purpose,
	|	DimensionKeys.Series							AS Series,
	|	DimensionKeys.StorageLocation					AS StorageLocation,
	|	DimensionKeys.Series							AS BatchForConnection,
	|	TableOfGoods.PartnerProducts				AS PartnerProducts
	|FROM
	|	GroupedTableOfProducts AS TableOfGoods
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TableOfGoods.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		INNER JOIN GoodsSoldGrouped AS SoldGoods
	|		ON DimensionKeys.Products = SoldGoods.Products
	|			AND DimensionKeys.Characteristic = SoldGoods.Characteristic
	|			AND DimensionKeys.Series = SoldGoods.Series
	|WHERE
	|	NOT &ThisIsReturn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentDataTable.Organization AS Organization,
	|	DocumentDataTable.Warehouse AS Warehouse,
	|	GroupedTableOfProducts.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SoldGoods.Products AS Products,
	|	SoldGoods.Characteristic AS Characteristic,
	|	SoldGoods.Series AS Series,
	|	SoldGoods.StorageLocation AS OriginWarehouse,
	|	SoldGoods.Purpose AS Purpose,
	|	SoldGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	GroupedTableOfProducts.PartnerProducts AS PartnerProducts,
	|	CASE
	|		WHEN SoldGoods.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN UNDEFINED
	|		ELSE SoldGoods.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN SoldGoods.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN SoldGoods.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE SoldGoods.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	SoldGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeShipment,
	|	SoldGoods.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	SoldGoods.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	UNDEFINED AS RecipientInventoryOwnerAttribute,
	|	UNDEFINED AS DateOfReceipt,
	|	SUM(SoldGoods.Count) AS CountBalance,
	|	SUM(CAST(SoldGoods.QuantityByGBRN AS NUMBER(23, 11))) AS QuantityByGBRNBalance,
	|	SUM(SoldGoods.ExciseTaxAmount) AS ExciseTaxAmountBalance,
	|	0 AS SumBalance,
	|	SUM(SoldGoods.VATAmount) AS VATAmountBalance
	|INTO BalanceTable
	|FROM
	|	GoodsSoldGrouped AS SoldGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON (TRUE)
	|		INNER JOIN GoodsTableForConnection AS GroupedTableOfProducts
	|		ON SoldGoods.Products = GroupedTableOfProducts.Products
	|			AND SoldGoods.Characteristic = GroupedTableOfProducts.Characteristic
	|			AND SoldGoods.Series = GroupedTableOfProducts.BatchForConnection
	|			AND CASE
	|				WHEN &ThisIsImplementationAdjustment
	|					THEN SoldGoods.StorageLocation = GroupedTableOfProducts.StorageLocation
	|				ELSE TRUE
	|			END
	|			AND SoldGoods.DocumentSalesOfGoodsAndServices = GroupedTableOfProducts.DocumentSalesOfGoodsAndServices
	|			AND (
	|				(&ThisIsImplementationAdjustment
	|					AND SoldGoods.Purpose = GroupedTableOfProducts.Purpose)
	|				OR
	|				(NOT &ThisIsImplementationAdjustment
	|					AND (SoldGoods.Purpose = GroupedTableOfProducts.Purpose
	|						OR GroupedTableOfProducts.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|						OR SoldGoods.Purpose = VALUE(Catalog.Assignments.EmptyRef)))
	|				)
	|			AND (GroupedTableOfProducts.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument))
	|
	|GROUP BY
	|	DocumentDataTable.Warehouse,
	|	SoldGoods.Products,
	|	SoldGoods.Series,
	|	GroupedTableOfProducts.ItemsLocationAttributes,
	|	SoldGoods.Purpose,
	|	SoldGoods.StorageLocation,
	|	SoldGoods.CCDNumber,
	|	DocumentDataTable.Organization,
	|	SoldGoods.DocumentSalesOfGoodsAndServices,
	|	GroupedTableOfProducts.PartnerProducts,
	|	SoldGoods.Characteristic,
	|	CASE
	|		WHEN SoldGoods.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN UNDEFINED
	|		ELSE SoldGoods.InventoryOwnerAttribute
	|	END,
	|	CASE
	|		WHEN SoldGoods.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN SoldGoods.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE SoldGoods.InventoryOwnerAttribute
	|	END,
	|	SoldGoods.InventoryOwnerAttribute,
	|	SoldGoods.CorInventoryOwnerAttribute
	|
	|HAVING
	|	SUM(SoldGoods.Count) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataTable.Organization,
	|	DocumentDataTable.Warehouse,
	|	GroupedTableOfProducts.ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment.Products,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment.Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment.Series,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment.StorageLocation,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment.Purpose,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	GroupedTableOfProducts.PartnerProducts,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef),
	|	UNDEFINED,
	|	UNDEFINED,
	|	TableTypesOfStocks_.Count,
	|	CAST(TableTypesOfStocks_.QuantityByGBRN AS NUMBER(23, 11)),
	|	&FieldTextTableOfGoodsExciseTaxAmount_ AS ExciseTaxAmount,
	|	0,
	|	TableTypesOfStocks_.VATAmount
	|FROM
	|	GroupedTableOfProducts AS GroupedTableOfProducts
	|		INNER JOIN TableTypesOfStocks_ AS TableTypesOfStocks_
	|		ON GroupedTableOfProducts.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|			AND GroupedTableOfProducts.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			AND TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SoldGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GroupedTableOfProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableOfProductsWithKeysForAllWarehouses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsSoldGrouped
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsTableForConnection";
	
	Query.SetParameter("Ref", DocumentObject.Ref);
	Query.SetParameter("ThisIsReturn",
								TypeOf(DocumentObject) = Type("DocumentObject.ReturnOfGoodsFromCustomer"));
	Query.SetParameter("ThisIsImplementationAdjustment",
								TypeOf(DocumentObject) = Type("DocumentObject.SaleAdjustment"));
	Query.SetParameter("CreditNoteAdjustmentAfterTransferOfOwnership",
								ParametersForFillingInventoryTypes.CreditNoteAdjustmentAfterTransferOfOwnership);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableOfGoodsPartnerProducts_",
																"TableOfGoods",
																"PartnerProducts",
																"TableOfGoods.PartnerProducts",
																"VALUE(Catalog.ProductCrossReferences.EmptyRef)");
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableOfGoodsExciseTaxAmount_",
																"TableTypesOfStocks_",
																"ExciseTaxAmount",
																"TableTypesOfStocks_.ExciseTaxAmount",
																"0");
	Query.Execute();
	
EndProcedure

// The procedure generates a table of product balances for reporting to the Committee.
//
Procedure TableOfBalancesForMakingReportToCommittee(DocumentObject, TempTablesManager, DateOfRemainingGoods)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CompanyGoods.Organization				AS Organization,
	|	VALUE(Catalog.Warehouses.EmptyRef)	AS Warehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef)	AS OriginWarehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoods.ItemsLocationAttributes.Products AS Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.Purpose AS Purpose,
	|	CompanyGoods.ItemsLocationAttributes.Series AS Series,
	|	CompanyGoods.DocumentSalesOfGoodsAndServices		AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED								AS DocumentLoggingIn,
	|	CompanyGoods.InventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	CompanyGoods.InventoryOwnerAttribute				AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	UNDEFINED								AS RecipientInventoryOwnerAttribute,
	|	UNDEFINED								AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber					AS CCDNumber,
	|	MAX(CompanyGoods.DateOfReceipt)	AS DateOfReceipt,
	|	SUM(CompanyGoods.Count)			AS CountBalance,
	|	SUM(CompanyGoods.QuantityByGBRN)	AS QuantityByGBRNBalance,
	|	SUM(CompanyGoods.RevenueAmount)		AS SumBalance
	|INTO BalanceTable
	|FROM
	|	(SELECT // Types of reserves written off by the document
	|		GoodsForRegistration.InventoryOwnerAttribute.Organization		AS Organization,
	|		GoodsForRegistration.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		GoodsForRegistration.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber						AS CCDNumber,
	|		GoodsForRegistration.Count					AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsForRegistration.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(GoodsForRegistration.QuantityForRegistrationByProductBatchID AS NUMBER(23, 11))
	|		END											AS QuantityByGBRN,
	|		GoodsForRegistration.RevenueAmount					AS RevenueAmount,
	|		DatesOfReceiptOfGoods.DateOfReceipt			AS DateOfReceipt,
	|		GoodsForRegistration.DocumentSales				AS DocumentSalesOfGoodsAndServices
	|	FROM
	|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|			INNER JOIN TTSelectionsOfBusinessBalances AS Filters
	|			ON Filters.InventoryOwnerAttribute = GoodsForRegistration.InventoryOwnerAttribute
	|				AND Filters.ItemsLocationAttributes = GoodsForRegistration.ItemsLocationAttributes
	|			
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON GoodsForRegistration.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|			
	|			LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfReceiptOfGoods
	|			ON GoodsForRegistration.InventoryOwnerAttribute = DatesOfReceiptOfGoods.InventoryOwnerAttribute
	|				AND InventoryLocationAttributeKeys.Products = DatesOfReceiptOfGoods.Products
	|				AND InventoryLocationAttributeKeys.Characteristic = DatesOfReceiptOfGoods.Characteristic
	|				AND InventoryLocationAttributeKeys.Series = DatesOfReceiptOfGoods.Series
	|				AND InventoryLocationAttributeKeys.Purpose = DatesOfReceiptOfGoods.Purpose
	|				AND GoodsForRegistration.CCDNumber = DatesOfReceiptOfGoods.CCDNumber
	|	
	|	WHERE
	|		GoodsForRegistration.Active
	|		AND GoodsForRegistration.Period <= &Date
	|		AND GoodsForRegistration.Recorder = &Ref
	|		AND GoodsForRegistration.InventoryOwnerAttribute.Organization = &Organization
	|	
	|	UNION ALL
	|	
	|	SELECT // Realized types of stocks
	|		GoodsForRegistration.InventoryOwnerAttribute.Organization		AS Organization,
	|		GoodsForRegistration.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		GoodsForRegistration.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber						AS CCDNumber,
	|		GoodsForRegistration.CountBalance				AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(GoodsForRegistration.QuantityForRegistrationByProductBatchIDBalance AS NUMBER(23, 11))
	|		END											AS QuantityByGBRN,
	|		GoodsForRegistration.RevenueAmountBalance			AS RevenueAmount,
	|		DatesOfReceiptOfGoods.DateOfReceipt			AS DateOfReceipt,
	|		GoodsForRegistration.DocumentSales				AS DocumentSalesOfGoodsAndServices
	|	FROM
	|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(&DateOfRemainingGoods,
	|				Currency = &Currency
	|				AND (InventoryOwnerAttribute, ItemsLocationAttributes) IN
	|						(SELECT
	|							Filters.InventoryOwnerAttribute,
	|							Filters.ItemsLocationAttributes
	|						FROM
	|						TTSelectionsOfBusinessBalances AS Filters)
	|		
	|		) AS GoodsForRegistration
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON GoodsForRegistration.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|			
	|			LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfReceiptOfGoods
	|			ON GoodsForRegistration.InventoryOwnerAttribute = DatesOfReceiptOfGoods.InventoryOwnerAttribute
	|				AND InventoryLocationAttributeKeys.Products = DatesOfReceiptOfGoods.Products
	|				AND InventoryLocationAttributeKeys.Characteristic = DatesOfReceiptOfGoods.Characteristic
	|				AND InventoryLocationAttributeKeys.Series = DatesOfReceiptOfGoods.Series
	|				AND InventoryLocationAttributeKeys.Purpose = DatesOfReceiptOfGoods.Purpose
	|				AND GoodsForRegistration.CCDNumber = DatesOfReceiptOfGoods.CCDNumber
	|	
	|	UNION ALL
	|	
	|	SELECT // Types of stocks specified in the document manually.
	|		Inventories.InventoryOwnerAttribute.Organization		AS Organization,
	|		Inventories.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		Inventories.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		Inventories.CCDNumber						AS CCDNumber,
	|		Inventories.Count					AS Count,
	|		CAST(Inventories.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|		Inventories.AmountIncludingVAT					AS RevenueAmount,
	|		DATETIME(1,1,1)					AS DateOfReceipt,
	|		Inventories.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices
	|	FROM
	|		TableTypesOfStocks_ AS Inventories
	|	
	|	WHERE
	|		Inventories.InventoryOwnerAttributesAreSpecifiedManually
	|		AND Inventories.ItemsLocationAttributes IN
	|				(SELECT DISTINCT
	|					TableOfGoods.ItemsLocationAttributes
	|				FROM
	|					TableOfGoods AS TableOfGoods)
	|	
	|	) AS CompanyGoods
	|
	|GROUP BY
	|	CompanyGoods.Organization,
	|	CompanyGoods.ItemsLocationAttributes,
	|	CompanyGoods.ItemsLocationAttributes.Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.Purpose,
	|	CompanyGoods.ItemsLocationAttributes.Series,
	|	CompanyGoods.InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber,
	|	CompanyGoods.DocumentSalesOfGoodsAndServices
	|
	|INDEX BY
	|	ItemsLocationAttributes";

	EndOfPeriod = EndOfDay(DateOfRemainingGoods);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref",			DocumentObject.Ref);
	Query.SetParameter("Currency",			DocumentObject.Currency);
	Query.SetParameter("Organization",	DocumentObject.Organization);
	Query.SetParameter("Date",			EndOfPeriod);
	Query.SetParameter("DateOfRemainingGoods",	New Boundary(EndOfPeriod, BoundaryType.Including));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Execute();
	
EndProcedure

Procedure TableOfBalancesForIssuingReportToCommitteeOnWriteOffs(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CompanyGoods.Organization				AS Organization,
	|	VALUE(Catalog.Warehouses.EmptyRef)	AS Warehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef)	AS OriginWarehouse,
	|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoods.ItemsLocationAttributes.Products AS Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	CompanyGoods.ItemsLocationAttributes.Series AS Series,
	|	CompanyGoods.InventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	UNDEFINED								AS RecipientInventoryOwnerAttribute,
	|	UNDEFINED								AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber					AS CCDNumber,
	|	MAX(CompanyGoods.DateOfReceipt)	AS DateOfReceipt,
	|	SUM(CompanyGoods.Count)			AS CountBalance,
	|	SUM(CompanyGoods.QuantityByGBRN)	AS QuantityByGBRNBalance,
	|	SUM(CompanyGoods.RevenueAmount)		AS SumBalance,
	|	UNDEFINED								AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED								AS DocumentLoggingIn
	|INTO BalanceTable
	|FROM
	|	(SELECT // Types of reserves written off by the document
	|		GoodsForRegistration.InventoryOwnerAttribute.Organization AS Organization,
	|		GoodsForRegistration.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		GoodsForRegistration.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber AS CCDNumber,
	|		GoodsForRegistration.QuantityConsumed AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsForRegistration.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(GoodsForRegistration.QuantityIsWrittenOffForRegistrationByProductBatchID AS NUMBER(23, 11))
	|		END AS QuantityByGBRN,
	|		0 AS RevenueAmount,
	|		DatesOfConsignmentGoodsTransfer.TransferDate AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|			LEFT JOIN InformationRegister.DatesOfConsignmentGoodsTransfer AS DatesOfConsignmentGoodsTransfer
	|			ON GoodsForRegistration.InventoryOwnerAttribute = DatesOfConsignmentGoodsTransfer.InventoryOwnerAttribute
	|				AND GoodsForRegistration.ItemsLocationAttributes = DatesOfConsignmentGoodsTransfer.ItemsLocationAttributes
	|				AND GoodsForRegistration.CCDNumber = DatesOfConsignmentGoodsTransfer.CCDNumber
	|				AND GoodsForRegistration.InventoryOwnerAttribute.Terms = DatesOfConsignmentGoodsTransfer.Terms
	|				AND GoodsForRegistration.InventoryOwnerAttribute.Organization = DatesOfConsignmentGoodsTransfer.Organization
	|
	|	WHERE
	|		GoodsForRegistration.Active
	|		AND GoodsForRegistration.Recorder = &Ref
	|		AND GoodsForRegistration.InventoryOwnerAttribute.Organization = &Organization
	|		AND GoodsForRegistration.InventoryOwnerAttribute IN
	|				(SELECT DISTINCT
	|					Filters.InventoryOwnerAttribute
	|				FROM
	|					TTSelectionsOfBusinessBalances AS Filters)
	|	
	|	UNION ALL
	|
	|	SELECT // Types of reserves written off by the document being cancelled
	|		GoodsForRegistration.InventoryOwnerAttribute.Organization AS Organization,
	|		GoodsForRegistration.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		GoodsForRegistration.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber AS CCDNumber,
	|		GoodsForRegistration.QuantityConsumed AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsForRegistration.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(GoodsForRegistration.QuantityIsWrittenOffForRegistrationByProductBatchID AS NUMBER(23, 11))
	|		END AS QuantityByGBRN,
	|		0 AS RevenueAmount,
	|		DatesOfConsignmentGoodsTransfer.TransferDate AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|			LEFT JOIN InformationRegister.DatesOfConsignmentGoodsTransfer AS DatesOfConsignmentGoodsTransfer
	|			ON GoodsForRegistration.InventoryOwnerAttribute = DatesOfConsignmentGoodsTransfer.InventoryOwnerAttribute
	|				AND GoodsForRegistration.ItemsLocationAttributes = DatesOfConsignmentGoodsTransfer.ItemsLocationAttributes
	|				AND GoodsForRegistration.CCDNumber = DatesOfConsignmentGoodsTransfer.CCDNumber
	|				AND GoodsForRegistration.InventoryOwnerAttribute.Terms = DatesOfConsignmentGoodsTransfer.Terms
	|				AND GoodsForRegistration.InventoryOwnerAttribute.Organization = DatesOfConsignmentGoodsTransfer.Organization
	|	
	|	WHERE
	|		NOT GoodsForRegistration.ReversingEntry
	|		AND GoodsForRegistration.Active
	|		AND GoodsForRegistration.Recorder = &ReversedDocument
	|		AND GoodsForRegistration.InventoryOwnerAttribute.Organization = &Organization
	|		AND GoodsForRegistration.InventoryOwnerAttribute IN
	|				(SELECT DISTINCT
	|					Filters.InventoryOwnerAttribute
	|				FROM
	|					TTSelectionsOfBusinessBalances AS Filters)
	|	
	|	UNION ALL
	|	
	|	SELECT // Written-off types of inventory
	|		GoodsForRegistration.InventoryOwnerAttribute.Organization		AS Organization,
	|		GoodsForRegistration.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		GoodsForRegistration.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		GoodsForRegistration.CCDNumber						AS CCDNumber,
	|		GoodsForRegistration.QuantityConsumedReceipt
	|			- GoodsForRegistration.QuantityConsumedExpense	AS Count,
	|		CAST(GoodsForRegistration.QuantityIsWrittenOffForRegistrationByProductBatchIDReceipt AS NUMBER(23, 11))
	|			- CAST(GoodsForRegistration.QuantityIsWrittenOffForRegistrationByProductBatchIDExpense AS NUMBER(23, 11)) AS QuantityByGBRN,
	|		0 AS RevenueAmount,
	|		DatesOfConsignmentGoodsTransfer.TransferDate AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Turnovers(&BeginOfPeriod, &EndOfPeriod, Period,
	|				Currency = &Currency
	|				AND (ItemsLocationAttributes, InventoryOwnerAttribute) IN
	|						(SELECT DISTINCT
	|							Filters.ItemsLocationAttributes,
	|							Filters.InventoryOwnerAttribute
	|						FROM
	|							TTSelectionsOfBusinessBalances AS Filters)
	|		
	|		) AS GoodsForRegistration
	|			LEFT JOIN InformationRegister.DatesOfConsignmentGoodsTransfer AS DatesOfConsignmentGoodsTransfer
	|			ON GoodsForRegistration.InventoryOwnerAttribute = DatesOfConsignmentGoodsTransfer.InventoryOwnerAttribute
	|				AND GoodsForRegistration.ItemsLocationAttributes = DatesOfConsignmentGoodsTransfer.ItemsLocationAttributes
	|				AND GoodsForRegistration.CCDNumber = DatesOfConsignmentGoodsTransfer.CCDNumber
	|				AND GoodsForRegistration.InventoryOwnerAttribute.Terms = DatesOfConsignmentGoodsTransfer.Terms
	|				AND GoodsForRegistration.InventoryOwnerAttribute.Organization = DatesOfConsignmentGoodsTransfer.Organization
	|	
	|	UNION ALL
	|	
	|	SELECT // Types of stocks specified in the document manually.
	|		Inventories.InventoryOwnerAttribute.Organization		AS Organization,
	|		Inventories.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		Inventories.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		Inventories.CCDNumber						AS CCDNumber,
	|		Inventories.Count					AS Count,
	|		CAST(Inventories.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|		0									AS RevenueAmount,
	|		DATETIME(1,1,1)					AS DateOfReceipt
	|	FROM
	|		TableTypesOfStocks_ AS Inventories
	|	WHERE
	|		Inventories.InventoryOwnerAttributesAreSpecifiedManually
	|		AND Inventories.ItemsLocationAttributes IN
	|				(SELECT DISTINCT
	|					TableOfGoods.ItemsLocationAttributes
	|				FROM
	|					TableOfGoods AS TableOfGoods)
	|		
	|	) AS CompanyGoods
	|
	|GROUP BY
	|	CompanyGoods.Organization,
	|	CompanyGoods.ItemsLocationAttributes,
	|	CompanyGoods.ItemsLocationAttributes.Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.Series,
	|	CompanyGoods.InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	
	BeginOfPeriod	= ?(ValueIsFilled(DocumentObject.BeginOfPeriod), DocumentObject.BeginOfPeriod, Date(1,1,1));
	EndOfPeriod	= ?(ValueIsFilled(DocumentObject.EndOfPeriod),
						EndOfDay(DocumentObject.EndOfPeriod),
						EndOfMonth(DocumentObject.Date));
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref",			DocumentObject.Ref);
	Query.SetParameter("Currency",			DocumentObject.Currency);
	Query.SetParameter("Organization",	DocumentObject.Organization);
	Query.SetParameter("BeginOfPeriod",	BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",	EndOfPeriod);
	Query.SetParameter("ReversedDocument", ParametersForFillingInventoryTypes.ReversedDocument);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Execute();
	
EndProcedure

// Formation of time table. TableColumn to the transfer of intercompany.
// Parameters:
//	Link-Document Link.{Transfers of goods between organizations | Return of goods between organizations}
//	Owner - Spravochnike.Organizations that own the transferred / returned inventory
//	Warehouse - warehouse for selecting balances in the operation
//	Date - the date when balances were collected
//	Temporary tables-the temporary table Manager for the Tablestates, must contain ALL available types of Reserves
//	Passengercapacity - a sign of ignoring the available types of inventory.
Procedure TableOfBalancesOfGoodsForTransfer(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes, DateOfRemainingGoods)
	
	QueryText =
	"SELECT
	|	ToTransfer.Organization AS Organization,
	|	ToTransfer.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ToTransfer.ItemsLocationAttributes.Products AS Products,
	|	ToTransfer.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	ToTransfer.ItemsLocationAttributes.Series AS Series,
	|	ToTransfer.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	ToTransfer.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttribute,
	|	ToTransfer.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	ToTransfer.SellerInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	UNDEFINED AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	DATETIME(1,1,1) AS DateOfReceipt,
	|	ToTransfer.ItemsLocationAttributes.Purpose AS Purpose,
	|	ToTransfer.CCDNumber AS CCDNumber,
	|	SUM(ToTransfer.Count) AS CountBalance,
	|	0 AS OnDateOfControl,
	|	0 AS CurrentDate_,
	|	0 AS SumBalance
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		ToTransfer.CompanyOwner AS Organization,
	|		ToTransfer.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		ToTransfer.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttribute,
	|		ToTransfer.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|		ToTransfer.CCDNumber AS CCDNumber,
	|		ToTransfer.Count AS Count,
	|		DATETIME(1, 1, 1) AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.CompanyGoodsForTransfer AS ToTransfer
	|	WHERE
	|		ToTransfer.Recorder = &Ref
	|		AND ToTransfer.CompanyOwner = &Owner
	|		AND ToTransfer.Active
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ToTransfer.CompanyOwner,
	|		ToTransfer.ItemsLocationAttributes,
	|		ToTransfer.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner,
	|		ToTransfer.SellerInventoryOwnerAttribute,
	|		ToTransfer.CCDNumber,
	|		ToTransfer.CountBalance,
	|		DATETIME(1, 1, 1)
	|	FROM
	|		AccumulationRegister.CompanyGoodsForTransfer.Balance(
	|				&Date,
	|				(CompanyOwner, ItemsLocationAttributes, SellerInventoryOwnerAttribute) IN
	|					(SELECT
	|						InventoryKinds.Organization AS CompanyOwner,
	|						InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|						InventoryKinds.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute
	|					FROM
	|						TTSelectionsOfBusinessBalances AS InventoryKinds)) AS ToTransfer) AS ToTransfer
	|
	|GROUP BY
	|	ToTransfer.Organization,
	|	ToTransfer.ItemsLocationAttributes,
	|	ToTransfer.ItemsLocationAttributes.Products,
	|	ToTransfer.ItemsLocationAttributes.Characteristic,
	|	ToTransfer.ItemsLocationAttributes.Purpose,
	|	ToTransfer.ItemsLocationAttributes.Series,
	|	ToTransfer.ItemsLocationAttributes.StorageLocation,
	|	ToTransfer.SellerInventoryOwnerAttribute,
	|	ToTransfer.CCDNumber,
	|	ToTransfer.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner";
	
	QueryText = QueryText + " 
	|;
	|///////////////////////////////////////
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Ref", DocumentObject.Ref);
	Query.SetParameter("Owner", DocumentObject.Organization);
	Query.SetParameter("Warehouse", DocumentObject.Warehouse);
	Query.SetParameter("Date", New Boundary(EndOfDay(DateOfRemainingGoods), BoundaryType.Including));
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// Formation of time table. TableColumn to the return of intercompany.
// Parameters:
//	Link-Document Link.{Transfers of goods between organizations | Return of goods between organizations}
//	Owner - Spravochnike.Organizations that own the transferred / returned inventory
//	Warehouse - warehouse for selecting balances in the operation
//	Date - the date when balances were collected
//	Temporary tables-the temporary table Manager for the Tablestates, must contain ALL available types of Reserves
//	Passengercapacity - a sign of ignoring the available types of inventory.
Procedure TableOfRemainingItemsForReturn(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes, DateOfRemainingGoods)
	
	QueryText =
	"SELECT
	|	ToTransfer.Organization AS Organization,
	|	ToTransfer.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ToTransfer.ItemsLocationAttributes.Products AS Products,
	|	ToTransfer.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	ToTransfer.ItemsLocationAttributes.Series AS Series,
	|	ToTransfer.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	ToTransfer.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ToTransfer.RecipientInventoryOwnerAttribute AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	ToTransfer.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	UNDEFINED AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	DATETIME(1,1,1) AS DateOfReceipt,
	|	ToTransfer.ItemsLocationAttributes.Purpose AS Purpose,
	|	ToTransfer.CCDNumber AS CCDNumber,
	|	SUM(ToTransfer.Count) AS CountBalance,
	|	0 AS OnDateOfControl,
	|	0 AS CurrentDate_,
	|	0 AS SumBalance
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		ToTransfer.CompanyOwner AS Organization,
	|		ToTransfer.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		ToTransfer.SellerInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		ToTransfer.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS RecipientInventoryOwnerAttribute,
	|		ToTransfer.CCDNumber AS CCDNumber,
	|		ToTransfer.Returned AS Count,
	|		DATETIME(1, 1, 1) AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.CompanyGoodsForTransfer AS ToTransfer
	|	WHERE
	|		ToTransfer.Recorder = &Ref
	|		AND ToTransfer.CompanyOwner = &Owner
	|		AND ToTransfer.Active
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ToTransfer.CompanyOwner AS Organization,
	|		ToTransfer.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		ToTransfer.SellerInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		ToTransfer.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS RecipientInventoryOwnerAttribute,
	|		ToTransfer.CCDNumber,
	|		ToTransfer.ReturnedBalance,
	|		DATETIME(1, 1, 1)
	|	FROM
	|		AccumulationRegister.CompanyGoodsForTransfer.Balance(
	|			&Date,
	|			(CompanyOwner, ItemsLocationAttributes, SellerInventoryOwnerAttribute) IN
	|				(SELECT
	|					&Owner AS CompanyOwner,
	|					InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|					InventoryKinds.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute
	|				FROM
	|					TTSelectionsOfBusinessBalances AS InventoryKinds)
	|		) AS ToTransfer
	|
	|) AS ToTransfer
	|
	|GROUP BY
	|	ToTransfer.Organization,
	|	ToTransfer.ItemsLocationAttributes,
	|	ToTransfer.ItemsLocationAttributes.Products,
	|	ToTransfer.ItemsLocationAttributes.Characteristic,
	|	ToTransfer.ItemsLocationAttributes.Purpose,
	|	ToTransfer.ItemsLocationAttributes.Series,
	|	ToTransfer.ItemsLocationAttributes.StorageLocation,
	|	ToTransfer.RecipientInventoryOwnerAttribute,
	|	ToTransfer.CCDNumber,
	|	ToTransfer.InventoryOwnerAttribute
	|";
	
	QueryText = QueryText + " 
	|;
	|///////////////////////////////////////
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Ref", DocumentObject.Ref);
	Query.SetParameter("Owner", DocumentObject.CompanyRecipient);
	Query.SetParameter("Warehouse", DocumentObject.Warehouse);
	Query.SetParameter("Date", DateOfRemainingGoods + 1);
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
EndProcedure

// The procedure generates a table of the remaining items written off for expenses.
//
Procedure TableOfBalancesOfGoodsWrittenOffForExpenses(DocumentObject,
													TempTablesManager,
													ParametersForFillingInventoryTypes)
	
	DocumentRef	= DocumentObject.Ref;
	Organization		= DocumentOrganization(DocumentObject, ParametersForFillingInventoryTypes);
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date
	|INTO WriteOffDocuments
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Document.InventoryConsumption AS DocumentData
	|		ON TableOfGoods.DocumentSalesOfGoodsAndServices = DocumentData.Ref
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanyGoods.Recorder AS DocumentSalesOfGoodsAndServices,
	|	CompanyGoods.ItemsLocationAttributes.Products AS Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.Series AS Series,
	|	CompanyGoods.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	CompanyGoods.ItemsLocationAttributes.Purpose AS Purpose,
	|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber AS CCDNumber,
	|	CASE
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CompanyGoods.Count
	|		ELSE CompanyGoods.Count
	|	END AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(CompanyGoods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|		ELSE CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|	END AS QuantityByGBRN,
	|	WriteOffDocuments.Date AS DateOfDeduction
	|INTO BalancesOfGoodsWrittenOffForConsumption
	|FROM
	|	AccumulationRegister.CompanyGoods AS CompanyGoods
	|		INNER JOIN WriteOffDocuments AS WriteOffDocuments
	|		ON CompanyGoods.Recorder = WriteOffDocuments.Ref
	|WHERE
	|	NOT CompanyGoods.ReversingEntry
	|
	|UNION ALL
	|
	|SELECT
	|	CompanyGoods.DocumentSalesOfGoodsAndServices,
	|	CompanyGoods.CorItemsLocationAttributes.Products,
	|	CompanyGoods.CorItemsLocationAttributes.Characteristic,
	|	CompanyGoods.CorItemsLocationAttributes.Series,
	|	CompanyGoods.CorItemsLocationAttributes.StorageLocation,
	|	CompanyGoods.CorItemsLocationAttributes.Purpose,
	|	CompanyGoods.InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber,
	|	CASE
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CompanyGoods.Count
	|		ELSE CompanyGoods.Count
	|	END,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(CompanyGoods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|		ELSE CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|	END,
	|	WriteOffDocuments.Date
	|FROM
	|	AccumulationRegister.CompanyGoods AS CompanyGoods
	|		INNER JOIN WriteOffDocuments AS WriteOffDocuments
	|		ON CompanyGoods.DocumentSalesOfGoodsAndServices = WriteOffDocuments.Ref
	|WHERE
	|	NOT CompanyGoods.Recorder IN
	|				(SELECT
	|					WriteOffDocuments.Ref AS Ref
	|				FROM
	|					WriteOffDocuments AS WriteOffDocuments)
	|	AND CompanyGoods.Recorder <> &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	CompanyGoods.DocumentSalesOfGoodsAndServices,
	|	CompanyGoods.ItemsLocationAttributes.Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.Series,
	|	CompanyGoods.ItemsLocationAttributes.StorageLocation,
	|	CompanyGoods.ItemsLocationAttributes.Purpose,
	|	CompanyGoods.InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber,
	|	CASE
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CompanyGoods.Count
	|		ELSE -CompanyGoods.Count
	|	END,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(CompanyGoods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|		ELSE -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|	END,
	|	WriteOffDocuments.Date
	|FROM
	|	AccumulationRegister.CompanyGoods AS CompanyGoods
	|		INNER JOIN WriteOffDocuments AS WriteOffDocuments
	|		ON CompanyGoods.DocumentSalesOfGoodsAndServices = WriteOffDocuments.Ref
	|WHERE
	|	CompanyGoods.Recorder = &ReversedDocument
	|	AND NOT CompanyGoods.ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Organization AS Organization,
	|	&Warehouse AS Warehouse,
	|	Dimension.DimensionKey AS ItemsLocationAttributes,
	|	CompanyGoods.Warehouse AS OriginWarehouse,
	|	CompanyGoods.Products AS Products,
	|	CompanyGoods.Characteristic AS Characteristic,
	|	CompanyGoods.Series AS Series,
	|	CompanyGoods.Purpose AS Purpose,
	|	CompanyGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	CASE
	|		WHEN InventoryKinds.Organization <> &Organization
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE InventoryKinds.Ref
	|	END AS InventoryOwnerAttribute,
	|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	UNDEFINED AS RecipientInventoryOwnerAttribute,
	|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber AS CCDNumber,
	|	MIN(DATEDIFF(CompanyGoods.DateOfDeduction, &MaxDate, DAY)) AS DateOfReceipt,
	|	SUM(CompanyGoods.Count) AS CountBalance,
	|	SUM(CompanyGoods.QuantityByGBRN) AS QuantityByGBRNBalance,
	|	0 AS SumBalance
	|INTO BalanceTable
	|FROM
	|	BalancesOfGoodsWrittenOffForConsumption AS CompanyGoods
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON CompanyGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON CompanyGoods.Products = Dimension.Products
	|			AND CompanyGoods.Characteristic = Dimension.Characteristic
	|			AND CompanyGoods.Series = Dimension.Series
	|			AND CompanyGoods.Warehouse = Dimension.StorageLocation
	|			AND CompanyGoods.Purpose = Dimension.Purpose
	|			AND Dimension.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|GROUP BY
	|	Dimension.DimensionKey,
	|	CompanyGoods.Warehouse,
	|	CompanyGoods.Products,
	|	CompanyGoods.Characteristic,
	|	CompanyGoods.Series,
	|	CompanyGoods.Purpose,
	|	CompanyGoods.DocumentSalesOfGoodsAndServices,
	|	CompanyGoods.InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber,
	|	CASE
	|		WHEN InventoryKinds.Organization <> &Organization
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE InventoryKinds.Ref
	|	END
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP WriteOffDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP BalancesOfGoodsWrittenOffForConsumption";
	
	Query.SetParameter("Ref",					DocumentRef);
	Query.SetParameter("Organization",			Organization);
	Query.SetParameter("Warehouse",					DocumentObject.Warehouse);
	Query.SetParameter("MaxDate",		Date(2399, 1, 1));
	Query.SetParameter("ReversedDocument",	ParametersForFillingInventoryTypes.ReversedDocument);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
EndProcedure


Procedure TableOfBalancesTableTypesOfStocks(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Organization AS Organization,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Series AS Series,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	UNDEFINED AS RecipientInventoryOwnerAttribute,
	|	UNDEFINED AS DateOfReceipt,
	|	TableTypesOfStocks_.Count AS CountBalance,
	|	CAST(TableTypesOfStocks_.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRNBalance,
	|	&FieldTextTableTypesOfStocks_ExciseTaxAmount_ AS ExciseTaxAmountBalance,
	|	0 AS SumBalance
	|INTO BalanceTable
	|FROM
	|	TableTypesOfStocks_ AS TableTypesOfStocks_
	|		INNER JOIN TTSelectionsOfBusinessBalances AS TTSelectionsOfBusinessBalances
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = TTSelectionsOfBusinessBalances.ItemsLocationAttributes
	|			AND TableTypesOfStocks_.InventoryOwnerAttribute = TTSelectionsOfBusinessBalances.InventoryOwnerAttribute
	|";
	TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager,
																Query.Text,
																"&FieldTextTableTypesOfStocks_ExciseTaxAmount_",
																"TableTypesOfStocks_",
																"ExciseTaxAmount",
																"TableTypesOfStocks_.ExciseTaxAmount",
																"0");
	Query.Execute();
	
EndProcedure

// Returns the parameters of the add-on request the rest of the goods for each month.
//
// Returns:
//	Structure - parameters for completing the request for the Balance of products for each month:
//		* SelectStocksOfDifferentPeriods - Boolean - TRUE, a sign that you need to select stocks from different periods.
//													The default value is FALSE.
//		* ThereIsTableOfInventoryTypes - Boolean - TRUE, indicates that there is a data table containing information about 
//														the types of inventory that are received.
//														The default value is FALSE.
//		* NameOfInventoryTypeTable - String - Name of the table of inventory types that are received.
//														The default value is an empty string.
//		* EndOfControlPeriod - Date - the end period for monitoring product balances.
//											By default, the value is Undefined.
//		* ThereIsSelectionByCCDNumber - Boolean - TRUE, a sign that the selection of product balances takes into account balances in 
//											the context of GTD numbers.
//											The default value is Undefined.
//
Function ParametersForAddingBalancesToRequestForEachMonth() Export
		
	ExtensionParameters_ = New Structure;
	ExtensionParameters_.Insert("SelectStocksOfDifferentPeriods", False);
	ExtensionParameters_.Insert("ThereIsTableOfInventoryTypes", False);
	ExtensionParameters_.Insert("NameOfInventoryTypeTable", "");
	ExtensionParameters_.Insert("EndOfControlPeriod", Undefined);
	ExtensionParameters_.Insert("ThereIsSelectionByCCDNumber", False);
	
	Return ExtensionParameters_;
	
EndFunction

Function AddBalanceControlForEachMonthToRequest(Query, QueryText, ExtensionParameters_, MinimumBalanceDate, BalanceDates = Undefined) Export
	
	EndOfMonthDateOfLastMovement = EndOfMonth(DateOfLastMovement());
	EndOfTheCurrentMonth = EndOfMonth(CurrentSessionDate());
	
	// For the last three years, a tax audit is possible.
	ThreeYearsAgo = AddMonth(EndOfTheCurrentMonth, -36);
	InitialMonth = EndOfMonth(Max(MinimumBalanceDate, ThreeYearsAgo));
	If ValueIsFilled(ExtensionParameters_.EndOfControlPeriod) Then
		InitialMonth = EndOfMonth(Min(ExtensionParameters_.EndOfControlPeriod, InitialMonth));
		EndMonth = EndOfMonth(ExtensionParameters_.EndOfControlPeriod);
	Else
		EndMonth = EndOfMonth(Max(EndOfMonthDateOfLastMovement, EndOfTheCurrentMonth, InitialMonth));
	EndIf;
	
	MonthsOfControl = New Map;
	CurrentMonth = InitialMonth;
	While CurrentMonth <= EndMonth Do
		MonthsOfControl.Insert(CurrentMonth);
		CurrentMonth = EndOfMonth(EndOfMonth(CurrentMonth) + 1);
	EndDo;
	
	TextTTBalancesByMonthTemplate = 
	"SELECT
	|	&TextPeriod AS Period,
	|	MonthlyBalancesTemplate.Organization AS Organization,
	|	MonthlyBalancesTemplate.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MonthlyBalancesTemplate.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	MonthlyBalancesTemplate.CCDNumber AS CCDNumber,
	|	SUM(MonthlyBalancesTemplate.CountBalance) AS CountBalance,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&TextPeriod, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE SUM(MonthlyBalancesTemplate.QuantityByGBRNBalance)
	|	END AS QuantityByGBRNBalance
	|INTO MonthlyBalancesTemplate
	|FROM
	|	(SELECT
	|		Balance.Organization AS Organization,
	|		Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Balance.CCDNumber AS CCDNumber,
	|		Balance.CountBalance AS CountBalance,
	|		CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11)) AS QuantityByGBRNBalance
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(
	|				&TemplateBorderForMonth,
	|				(&TextAndNumberOfCCD, ItemsLocationAttributes, Organization, InventoryOwnerAttribute) IN
	|					(SELECT
	|						&TextSelectionForSelectionCCDNumber,
	|						TTSelections.ItemsLocationAttributes,
	|						TTSelections.Organization,
	|						TTSelections.InventoryOwnerAttribute
	|					FROM
	|						TTSelectionsOfBusinessBalances AS TTSelections)) AS Balance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Balance.Organization,
	|		Balance.ItemsLocationAttributes,
	|		Balance.InventoryOwnerAttribute,
	|		Balance.CCDNumber,
	|		Balance.CountBalance,
	|		CAST(Balance.QuantityByGBRNBalance AS NUMBER(23, 11))
	|	FROM
	|		AccumulationRegister.CompanySafeStock.Balance(
	|				&TemplateBorderForMonth,
	|				(&TextAndNumberOfCCD, ItemsLocationAttributes, Organization, InventoryOwnerAttribute) IN
	|					(SELECT
	|						&TextSelectionForSelectionCCDNumber,
	|						TTSelections.ItemsLocationAttributes,
	|						TTSelections.Organization,
	|						TTSelections.InventoryOwnerAttribute
	|					FROM
	|						TTSelectionsOfBusinessBalances AS TTSelections)) AS Balance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecords.Organization,
	|		DocumentRegisterRecords.ItemsLocationAttributes,
	|		DocumentRegisterRecords.InventoryOwnerAttribute,
	|		DocumentRegisterRecords.CCDNumber,
	|		-DocumentRegisterRecords.Count,
	|		-CAST(DocumentRegisterRecords.QuantityByGBRN AS NUMBER(23, 11))
	|	FROM
	|		DocumentRegisterRecords AS DocumentRegisterRecords
	|	WHERE
	|		(&TextTheseAreLastRegisteredRecords
	|		OR DocumentRegisterRecords.Period <= &EndOfMonthTemplate)
	|		AND DocumentRegisterRecords.Period >= &BeginningOfMonthMinimumBalanceDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTSelections.Organization,
	|		TTSelections.ItemsLocationAttributes,
	|		TTSelections.InventoryOwnerAttribute,
	|		&TextSelectionCCDNumber,
	|		0,
	|		0
	|	FROM
	|		TTSelectionsOfBusinessBalances AS TTSelections
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecords.Organization		AS Organization,
	|		DocumentRegisterRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		DocumentRegisterRecords.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|		DocumentRegisterRecords.CCDNumber			AS CCDNumber,
	|		DocumentRegisterRecords.Count		AS CountBalance,
	|		CAST(DocumentRegisterRecords.QuantityByGBRN AS NUMBER(23, 11))	AS QuantityByGBRNBalance
	|	FROM
	|		RegisteredRecordsOfCancelledDocument AS DocumentRegisterRecords
	|	WHERE
	|		(&TextTheseAreLastRegisteredRecords
	|			OR DocumentRegisterRecords.Period <= &EndOfMonthTemplate)
	|		AND DocumentRegisterRecords.Period >= &BeginningOfMonthMinimumBalanceDate
	|	
	|	AND &TextIncomingInventoryTypes
	|	
	|		) AS MonthlyBalancesTemplate
	|	
	|GROUP BY
	|	MonthlyBalancesTemplate.Organization,
	|	MonthlyBalancesTemplate.ItemsLocationAttributes,
	|	MonthlyBalancesTemplate.InventoryOwnerAttribute,
	|	MonthlyBalancesTemplate.CCDNumber
	|
	|INDEX BY
	|	Organization,
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	CCDNumber";
	
	RequestTextForMonthTemplate = 
	"SELECT
	|	&TextSelectionOfPeriod AS Period,
	|	MonthlyBalancesTemplate.Organization AS Organization,
	|	MonthlyBalancesTemplate.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MonthlyBalancesTemplate.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	MonthlyBalancesTemplate.CCDNumber AS CCDNumber,
	|	1 AS PeriodCounter,
	|	&TextPeriodNumber AS PeriodNumber,
	|	MonthlyBalancesTemplate.CountBalance AS CountBalance,
	|	&TextQuantityByRNPTResidue AS QuantityByGBRNBalance
	|FROM
	|	MonthlyBalancesTemplate AS MonthlyBalancesTemplate";
	
	If ExtensionParameters_.ThereIsSelectionByCCDNumber Then
		TextTTBalancesByMonthTemplate = StrReplace(TextTTBalancesByMonthTemplate, "&TextAndNumberOfCCD,", "CCDNumber,");
		TextTTBalancesByMonthTemplate = StrReplace(TextTTBalancesByMonthTemplate, "&TextSelectionCCDNumber,", "TTSelections.CCDNumber,");
		TextTTBalancesByMonthTemplate = StrReplace(TextTTBalancesByMonthTemplate, "&TextSelectionForSelectionCCDNumber,", "TTSelections.CCDNumber,");
	Else
		TextTTBalancesByMonthTemplate = StrReplace(TextTTBalancesByMonthTemplate, "&TextAndNumberOfCCD,", "");
		TextTTBalancesByMonthTemplate = StrReplace(TextTTBalancesByMonthTemplate, "&TextSelectionCCDNumber,", "VALUE(Catalog.CCDNumbers.EmptyRef),");
		TextTTBalancesByMonthTemplate = StrReplace(TextTTBalancesByMonthTemplate, "&TextSelectionForSelectionCCDNumber,", "");
	EndIf;
	
	ArrayOfQueryTextsByMonth = New Array;
	ArrayTTBalancesByMonth = New Array;
	
	PeriodCounter = 0;
	
	For Each MonthOfControl In MonthsOfControl Do
		
		CurrentMonth = MonthOfControl.Key;
		PeriodCounter = PeriodCounter + 1;
		TheseAreLastRegisteredRecords = EndOfMonthDateOfLastMovement = CurrentMonth;
		
		// The text representation of each month, for example: 20160630
		LineCurMonth = Format(CurrentMonth, DateFormatInTTName());
		
		RequestTextTTBalancesForCurMonth = TextTTBalancesByMonthTemplate;
		
		If ExtensionParameters_.ThereIsTableOfInventoryTypes Then
			
			//Additional types of stocks received by the document
			TextIncomingInventoryTypes =
			"SELECT 
			|	TableTypesOfStocks_.Organization                AS Organization,
			|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
			|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
			|	TableTypesOfStocks_.Count                 AS Count,
			|	CAST(TableTypesOfStocks_.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN
			|FROM
			|	NameOfInventoryTypeTable AS TableTypesOfStocks_
			|WHERE
			|	&TextTheseAreLastRegisteredRecords OR TableTypesOfStocks_.Period <= &TextPeriod";
			
			TextIncomingInventoryTypes = StrReplace(TextIncomingInventoryTypes,
				"NameOfInventoryTypeTable",
				ExtensionParameters_.NameOfInventoryTypeTable);
			RequestTextTTBalancesForCurMonth = StrReplace(RequestTextTTBalancesForCurMonth, "AND &TextIncomingInventoryTypes",
			TMCommonUse.QuerySeparatorInJoin() + TextIncomingInventoryTypes);
			
		Else
			
			RequestTextTTBalancesForCurMonth = StrReplace(RequestTextTTBalancesForCurMonth, "AND &TextIncomingInventoryTypes", "");
			
		EndIf;
		
		If ExtensionParameters_.SelectStocksOfDifferentPeriods Then
			
			For Each ArrRow In BalanceDates Do
				
				TextQuantityByRNPTResidue = 
				"CASE
				|		WHEN NOT &UseTraceableImportedGoodsAccounting
				|				OR BEGINOFPERIOD(&TextSelectionOfPeriod, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
				|			THEN 0
				|		ELSE CAST(MonthlyBalancesTemplate.QuantityByGBRNBalance AS NUMBER(23, 11))
				|	END";
				
				RequestTextForCurMonth = RequestTextForMonthTemplate;
				RequestTextForCurMonth = StrReplace(RequestTextForCurMonth,
														"&TextQuantityByRNPTResidue",
														TextQuantityByRNPTResidue);
				RequestTextForCurMonth = StrReplace(RequestTextForCurMonth,
														"MonthlyBalancesTemplate",
														NameTTBalancesAtEndOfMonth(CurrentMonth));
				
				EndOfMonthBalancesReceived = EndOfMonth(ArrRow);
				
				// The controlled month is more than a month of this iteration
				If CurrentMonth >= EndOfMonthBalancesReceived
					// or the month of this iteration is in the future period.
					Or EndOfMonthBalancesReceived > EndOfTheCurrentMonth Then
					
					BalanceDateString	= Format(EndOfMonthBalancesReceived, DateFormatInTTName());
					PeriodNumber		= Year(EndOfMonthBalancesReceived) * 12 + Month(EndOfMonthBalancesReceived)
											- Year(MinimumBalanceDate) * 12 - Month(MinimumBalanceDate) + 1;
					
					RequestTextForCurMonth = StrReplace(RequestTextForCurMonth,
															"&TextSelectionOfPeriod",
															"&End" + BalanceDateString);
					RequestTextForCurMonth = StrReplace(RequestTextForCurMonth,
															"&TextPeriodNumber",
															Format(PeriodNumber, "NZ=0; NG="));
					
					ArrayOfQueryTextsByMonth.Add(RequestTextForCurMonth);
					
					Query.SetParameter("End" + BalanceDateString, EndOfMonthBalancesReceived);
					
				EndIf;
				
			EndDo;
			
		Else
			
			TextQuantityByRNPTResidue = "CAST(MonthlyBalancesTemplate.QuantityByGBRNBalance AS NUMBER(23, 11))";
			
			RequestTextForCurMonth = RequestTextForMonthTemplate;
			RequestTextForCurMonth = StrReplace(RequestTextForCurMonth,
													"&TextQuantityByRNPTResidue",
													TextQuantityByRNPTResidue);
			RequestTextForCurMonth = StrReplace(RequestTextForCurMonth,
													"MonthlyBalancesTemplate",
													NameTTBalancesAtEndOfMonth(CurrentMonth));
			RequestTextForCurMonth = StrReplace(RequestTextForCurMonth,
													"&TextSelectionOfPeriod",
													"DATETIME(1,1,1)");
			RequestTextForCurMonth = StrReplace(RequestTextForCurMonth, "&TextPeriodNumber", "1");
			
			ArrayOfQueryTextsByMonth.Add(RequestTextForCurMonth);
			
		EndIf;
		
		RequestTextTTBalancesForCurMonth = StrReplace(RequestTextTTBalancesForCurMonth,
															"MonthlyBalancesTemplate",
															NameTTBalancesAtEndOfMonth(CurrentMonth));
		RequestTextTTBalancesForCurMonth = StrReplace(RequestTextTTBalancesForCurMonth,
															"TemplateBorderForMonth",
															"Boundary" + LineCurMonth);
		RequestTextTTBalancesForCurMonth = StrReplace(RequestTextTTBalancesForCurMonth,
															"EndOfMonthTemplate",
															"End" + LineCurMonth);
		RequestTextTTBalancesForCurMonth = StrReplace(RequestTextTTBalancesForCurMonth,
															"&TextPeriod",
															"&End" + LineCurMonth);
		RequestTextTTBalancesForCurMonth = StrReplace(RequestTextTTBalancesForCurMonth,
															"&TextTheseAreLastRegisteredRecords",
															?(TheseAreLastRegisteredRecords, "TRUE", "FALSE"));
		
		ArrayTTBalancesByMonth.Add(RequestTextTTBalancesForCurMonth);
		
		If CurrentMonth >= EndOfMonthDateOfLastMovement Then
			Query.SetParameter("Boundary" + LineCurMonth, Undefined);
		Else
			Query.SetParameter("Boundary" + LineCurMonth, New Boundary(CurrentMonth, BoundaryType.Including));
		EndIf;
		
		Query.SetParameter("End" + LineCurMonth, CurrentMonth);
		
	EndDo;
	
	If ExtensionParameters_.SelectStocksOfDifferentPeriods Then
		Query.SetParameter("FillingPeriod", MinimumBalanceDate);
		Query.SetParameter("BeginningOfMonthMinimumBalanceDate", BegOfMonth(MinimumBalanceDate));
	Else
		Query.SetParameter("FillingPeriod", Date(1,1,1));
		Query.SetParameter("BeginningOfMonthMinimumBalanceDate", Date(1,1,1));
	EndIf;
	
	TextBalancesByMonth = StrConcat(ArrayOfQueryTextsByMonth,
										TMCommonUse.QuerySeparatorInJoin());
	TextTTBalancesByMonth = StrConcat(ArrayTTBalancesByMonth,
											Common.QueryBatchSeparator()) + Common.QueryBatchSeparator();
	
	QueryText = StrReplace(QueryText, ",&TextBalancesByMonthMerge", "UNION ALL "+TextBalancesByMonth);
	QueryText = StrReplace(QueryText, "&TextBalancesByMonth", "("+TextBalancesByMonth+")");
	QueryText = StrReplace(QueryText, "SELECT &TextTTBalancesByMonth;", TextTTBalancesByMonth);
	
	Return PeriodCounter;
	
EndFunction

Procedure TableOfProductBalancesAccepted(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes)
	
	QueryText = 
	"SELECT
	|	TTSelectionsOfBusinessBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTSelectionsOfBusinessBalances.Organization AS Organization,
	|	TTSelectionsOfBusinessBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTSelection
	|FROM
	|	TTSelectionsOfBusinessBalances AS TTSelectionsOfBusinessBalances
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TTSelectionsOfBusinessBalances.InventoryOwnerAttribute = InventoryKinds.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoodsBalance.Organization AS Organization,
	|	CompanyGoodsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanyGoodsBalance.CCDNumber AS CCDNumber,
	|	CompanyGoodsBalance.ToRegisterGoodsIssueBalance AS Count,
	|	CompanyGoodsBalance.ToRegisterGoodsIssueByProductBatchIDBalance AS QuantityByGBRN
	|INTO ProductsOfOrganizationsBalancesToWriteOff
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			,
	|			(ItemsLocationAttributes, Organization, InventoryOwnerAttribute) IN
	|				(SELECT
	|					TTSelection.ItemsLocationAttributes,
	|					TTSelection.Organization,
	|					TTSelection.InventoryOwnerAttribute
	|				FROM
	|					TTSelection AS TTSelection)) AS CompanyGoodsBalance
	|WHERE
	|	CompanyGoodsBalance.ToRegisterGoodsIssueBalance > 0
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS DocumentLoggingIn,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS RecipientInventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	DATETIME(1, 1, 1) AS DateOfReceipt,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	SUM(NestedQuery.Count) AS CountBalance,
	|	SUM(NestedQuery.QuantityByGBRN) AS QuantityByGBRNBalance,
	|	SUM(0) AS OnDateOfControl,
	|	SUM(0) AS CurrentDate_,
	|	SUM(0) AS SumBalance
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanyGoodsBalance.Organization AS Organization,
	|		CompanyGoodsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanyGoodsBalance.CCDNumber AS CCDNumber,
	|		CompanyGoodsBalance.Count AS Count,
	|		CAST(CompanyGoodsBalance.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN
	|	FROM
	|		ProductsOfOrganizationsBalancesToWriteOff AS CompanyGoodsBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CompanyGoods.ItemsLocationAttributes,
	|		CompanyGoods.Organization,
	|		CompanyGoods.InventoryOwnerAttribute,
	|		CompanyGoods.CCDNumber,
	|		CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CompanyGoods.ToRegisterGoodsIssue
	|			ELSE -CompanyGoods.ToRegisterGoodsIssue
	|		END,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanyGoods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CompanyGoods.ToRegisterGoodsIssueByProductBatchID
	|			ELSE -CompanyGoods.ToRegisterGoodsIssueByProductBatchID
	|		END
	|	FROM
	|		AccumulationRegister.CompanyGoods AS CompanyGoods
	|			INNER JOIN TTSelection AS TTSelection
	|			ON CompanyGoods.ItemsLocationAttributes = TTSelection.ItemsLocationAttributes
	|				AND CompanyGoods.Organization = TTSelection.Organization
	|				AND CompanyGoods.InventoryOwnerAttribute = TTSelection.InventoryOwnerAttribute
	|	WHERE
	|		CompanyGoods.Recorder = &Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CompanyGoods.ItemsLocationAttributes,
	|		CompanyGoods.Organization,
	|		CompanyGoods.InventoryOwnerAttribute,
	|		CompanyGoods.CCDNumber,
	|		CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CompanyGoods.ToRegisterGoodsIssue
	|			ELSE CompanyGoods.ToRegisterGoodsIssue
	|		END AS Count,
	|		CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CAST(CompanyGoods.ToRegisterGoodsIssueByProductBatchID AS NUMBER(23, 11))
	|			ELSE CAST(CompanyGoods.ToRegisterGoodsIssueByProductBatchID AS NUMBER(23, 11))
	|		END AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.CompanyGoods AS CompanyGoods
	|			INNER JOIN TTSelection AS TTSelection
	|			ON CompanyGoods.ItemsLocationAttributes = TTSelection.ItemsLocationAttributes
	|				AND CompanyGoods.Organization = TTSelection.Organization
	|				AND CompanyGoods.InventoryOwnerAttribute = TTSelection.InventoryOwnerAttribute
	|	WHERE
	|		CompanyGoods.Recorder = &ReversedDocument
	|		AND NOT CompanyGoods.ReversingEntry
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.Organization,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	CCDNumber,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductsOfOrganizationsBalancesToWriteOff";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Partner",		DocumentObject.Partner);
	Query.SetParameter("Contract",		DocumentObject.Contract);
	Query.SetParameter("Recorder",	DocumentObject.Ref);
	Query.SetParameter("ReversedDocument", ParametersForFillingInventoryTypes.ReversedDocument);

	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Execute();
	
EndProcedure

// The procedure generates a table of balances of goods accepted by order.
//
Procedure TableOfBalancesOfAcceptedGoods(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT DISTINCT
	|	TableOfGoods.DocumentInflow AS DocumentInflow,
	|	CAST(TableOfGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes
	|INTO GroupedTableOfProducts
	|FROM
	|	TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.DocumentInflow	AS DocumentInflow,
	|	AccountingAnalytics.DimensionKey		AS ItemsLocationAttributes,
	|	AccountingAnalytics.Products			AS Products,
	|	AccountingAnalytics.Characteristic		AS Characteristic,
	|	AccountingAnalytics.Purpose			AS Purpose,
	|	AccountingAnalytics.Series				AS Series
	|INTO TableOfProductsWithKeysForAllWarehouses
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AccountingAnalytics
	|		ON TableOfGoods.Products = AccountingAnalytics.Products
	|			AND TableOfGoods.Characteristic = AccountingAnalytics.Characteristic
	|			AND (TableOfGoods.Series = AccountingAnalytics.Series
	|				OR AccountingAnalytics.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND TableOfGoods.Purpose = AccountingAnalytics.Purpose
	|
	|INDEX BY
	|	DocumentInflow,
	|	ItemsLocationAttributes,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Preliminary grouping is required for correct connection with TS types of stocks, in order to extract the warehouse.
	|SELECT
	|	TableOfGoods.Ref					AS Ref,
	|	DimensionKeys.Products				AS Products,
	|	DimensionKeys.Characteristic			AS Characteristic,
	|	DimensionKeys.Purpose				AS Purpose,
	|	DimensionKeys.Series					AS Series,
	|	DimensionKeys.StorageLocation			AS StorageLocation,
	|	TableOfGoods.CCDNumber					AS CCDNumber,
	|	TableOfGoods.Warehouse					AS Warehouse,
	|	SUM(TableOfGoods.Count)		AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN)	AS QuantityByGBRN
	|INTO TTGoodsOfPurchase
	|FROM
	|	Document.VendorInvoice.Goods AS TableOfGoods
	|		INNER JOIN Document.VendorInvoice AS DocumentData
	|		ON TableOfGoods.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TableOfGoods.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		INNER JOIN TableOfProductsWithKeysForAllWarehouses AS TableOfReturnItems
	|		ON TableOfGoods.Ref = TableOfReturnItems.DocumentInflow
	|			AND DimensionKeys.Products = TableOfReturnItems.Products
	|			AND DimensionKeys.Characteristic = TableOfReturnItems.Characteristic
	|			AND DimensionKeys.Purpose = TableOfReturnItems.Purpose
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableOfGoods.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	DimensionKeys.Products,
	|	DimensionKeys.Characteristic,
	|	DimensionKeys.Purpose,
	|	DimensionKeys.Series,
	|	DimensionKeys.StorageLocation,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.Warehouse
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	StorageLocation,
	|	CCDNumber,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Preliminary grouping of purchase adjustments is required for correct connection with TS types of stocks, in order to extract the warehouse.
	|SELECT
	|	TableOfGoods.Ref					AS Ref,
	|	DimensionKeys.Products				AS Products,
	|	DimensionKeys.Characteristic			AS Characteristic,
	|	DimensionKeys.Purpose				AS Purpose,
	|	DimensionKeys.Series					AS Series,
	|	DimensionKeys.StorageLocation			AS StorageLocation,
	|	TableOfGoods.CCDNumber					AS CCDNumber,
	|	TableOfGoods.Warehouse					AS Warehouse,
	|	SUM(TableOfGoods.Count)		AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN)	AS QuantityByGBRN
	|INTO TTGoodsDebitNote
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS TableOfGoods
	|		INNER JOIN Document.PurchaseAdjustment AS DocumentData
	|		ON TableOfGoods.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TableOfGoods.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		INNER JOIN TableOfProductsWithKeysForAllWarehouses AS TableOfReturnItems
	|		ON DocumentData.DocumentBasis = TableOfReturnItems.DocumentInflow
	|			AND TableOfGoods.Products = TableOfReturnItems.Products
	|			AND TableOfGoods.Characteristic = TableOfReturnItems.Characteristic
	|			AND TableOfGoods.Purpose = TableOfReturnItems.Purpose
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableOfGoods.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	DimensionKeys.Products,
	|	DimensionKeys.Characteristic,
	|	DimensionKeys.Purpose,
	|	DimensionKeys.Series,
	|	DimensionKeys.StorageLocation,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.Warehouse
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	StorageLocation,
	|	CCDNumber,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref						AS Ref,
	|	DocumentData.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DocumentData.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DocumentData.CCDNumber					AS CCDNumber,
	|	DocumentData.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(HeaderData_.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CAST(DocumentData.QuantityByGBRN AS NUMBER(23, 11))
	|	END										AS QuantityByGBRN
	|INTO AcceptedGoods
	|FROM
	|	Document.VendorInvoice.Goods AS DocumentData
	|		INNER JOIN Document.VendorInvoice AS HeaderData_
	|		ON DocumentData.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN TableOfProductsWithKeysForAllWarehouses AS TableOfGoods
	|		ON DocumentData.Ref = TableOfGoods.DocumentInflow
	|			AND DocumentData.ItemsLocationAttributes = TableOfGoods.ItemsLocationAttributes
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentData.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	HeaderData_.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|		AND (HeaderData_.BusinessOperation NOT IN (
	|			VALUE(Enum.BusinessTransactions.PurchaseByImport),
	|			VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|		)
	|		OR NOT &ThisIsRefundToSupplier)
	|
	|UNION ALL
	|
	// Return to the supplier for an unfactured delivery or for goods in transit.
	|SELECT
	|	DocumentData.Ref					AS Ref,
	|	TypesOfStocksWarehouse.Ref				AS InventoryOwnerAttribute,
	|	Dimension.DimensionKey					AS ItemsLocationAttributes,
	|	CASE
	|		WHEN NOT DocumentData.CCDNumber IS NULL
	|			THEN DocumentData.CCDNumber
	|		ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|	END									AS CCDNumber,
	|	TableOfPurchaseItems.Count	AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(HeaderData_.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CAST(TableOfPurchaseItems.QuantityByGBRN AS NUMBER(23, 11))
	|	END									AS QuantityByGBRN
	|FROM
	|	Document.VendorInvoice.InventoryKinds AS DocumentData
	|		INNER JOIN Document.VendorInvoice AS HeaderData_
	|		ON DocumentData.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN TableOfProductsWithKeysForAllWarehouses AS TableOfReturnItems
	|		ON DocumentData.Ref = TableOfReturnItems.DocumentInflow
	|			AND DocumentData.ItemsLocationAttributes.Products = TableOfReturnItems.Products
	|			AND DocumentData.ItemsLocationAttributes.Characteristic = TableOfReturnItems.Characteristic
	|			AND (DocumentData.ItemsLocationAttributes.Series = TableOfReturnItems.Series
	|				OR DocumentData.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentData.ItemsLocationAttributes.Purpose = TableOfReturnItems.Purpose
	|		
	|		INNER JOIN TTGoodsOfPurchase AS TableOfPurchaseItems
	|		ON DocumentData.Ref = TableOfPurchaseItems.Ref
	|			AND DocumentData.ItemsLocationAttributes.Products = TableOfPurchaseItems.Products
	|			AND DocumentData.ItemsLocationAttributes.Characteristic = TableOfPurchaseItems.Characteristic
	|			AND (DocumentData.ItemsLocationAttributes.Series = TableOfPurchaseItems.Series
	|				OR DocumentData.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|				OR TableOfPurchaseItems.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentData.ItemsLocationAttributes.Purpose = TableOfPurchaseItems.Purpose
	|			AND DocumentData.ItemsLocationAttributes.StorageLocation = TableOfPurchaseItems.StorageLocation
	|			AND DocumentData.CCDNumber = TableOfPurchaseItems.CCDNumber
	|		
	|		INNER JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|		ON TypesOfStocksWarehouse.Organization = DocumentData.InventoryOwnerAttribute.Organization
	|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentData.InventoryOwnerAttribute.GoodsOwner
	|			AND TypesOfStocksWarehouse.VATTaxation = DocumentData.InventoryOwnerAttribute.VATTaxation
	|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentData.InventoryOwnerAttribute.FinancialAccountingGroup
	|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentData.InventoryOwnerAttribute.ProductsGroup
	|			AND TypesOfStocksWarehouse.PriceKind = DocumentData.InventoryOwnerAttribute.PriceKind
	|			AND NOT TypesOfStocksWarehouse.IsDuplicate
	|			AND NOT TypesOfStocksWarehouse.Obsolete1
	|			AND NOT TypesOfStocksWarehouse.DeletionMark
	|		
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON DocumentData.ItemsLocationAttributes.Products = Dimension.Products
	|			AND DocumentData.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND (DocumentData.ItemsLocationAttributes.Series = Dimension.Series
	|				OR DocumentData.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentData.ItemsLocationAttributes.Purpose = Dimension.Purpose
	|			AND DocumentData.ItemsLocationAttributes.ProductCostElement = Dimension.ProductCostElement
	|			AND TableOfPurchaseItems.Warehouse = Dimension.StorageLocation
	|
	|WHERE
	|	&ThisIsRefundToSupplier
	|	AND HeaderData_.Posted
	|	AND HeaderData_.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.DocumentInflow	AS Ref,
	|	ISNULL(ReceiptOfGoodsToWarehouse.WarehouseInventoryAttributes, DocumentData.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|	ISNULL(ReceiptOfGoodsToWarehouse.ItemsLocationAttributes, DocumentData.ItemsLocationAttributes) AS ItemsLocationAttributes,
	|	DocumentData.CCDNumber			AS CCDNumber,
	|	DocumentData.Count			AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(HeaderData_.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CAST(DocumentData.QuantityByGBRN AS NUMBER(23, 11))
	|	END								AS QuantityByGBRN
	|FROM
	|	Document.CCDImport.Goods AS DocumentData
	|		INNER JOIN Document.CCDImport AS HeaderData_
	|		ON DocumentData.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN TableOfProductsWithKeysForAllWarehouses AS TableOfGoods
	|		ON DocumentData.DocumentInflow = TableOfGoods.DocumentInflow
	|			AND DocumentData.ItemsLocationAttributes = TableOfGoods.ItemsLocationAttributes
	|		
	|		LEFT JOIN Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS ReceiptOfGoodsToWarehouse
	|			ON ReceiptOfGoodsToWarehouse.Ref.ReferenceOrder = DocumentData.DocumentInflow
	|			AND ReceiptOfGoodsToWarehouse.ItemsLocationAttributesGoodsAtPartners = DocumentData.ItemsLocationAttributes
	|			AND ReceiptOfGoodsToWarehouse.Ref.Posted
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfReceipts
	|		ON ReceiptOfGoodsToWarehouse.Ref = RegisterOfReceipts.ReversedDocument
	|			AND RegisterOfReceipts.Posted
	|			AND NOT RegisterOfReceipts.AdditionalRecord
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDeclarations
	|		ON DocumentData.Ref = RegisterOfDeclarations.ReversedDocument
	|			AND RegisterOfDeclarations.Posted
	|			AND NOT RegisterOfDeclarations.AdditionalRecord
	|
	|WHERE
	|	HeaderData_.Posted
	|	AND RegisterOfDeclarations.Ref IS NULL
	|	AND RegisterOfReceipts.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	HeaderData_.DocumentBasis				AS Ref,
	|	DocumentData.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DocumentData.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DocumentData.CCDNumber					AS CCDNumber,
	|	DocumentData.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(HeaderData_.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CAST(DocumentData.QuantityByGBRN AS NUMBER(23, 11))
	|	END										AS QuantityByGBRN
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DocumentData
	|		INNER JOIN Document.PurchaseAdjustment AS HeaderData_
	|		ON DocumentData.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN TableOfProductsWithKeysForAllWarehouses AS TableOfGoods
	|		ON HeaderData_.DocumentBasis = TableOfGoods.DocumentInflow
	|			AND DocumentData.ItemsLocationAttributes = TableOfGoods.ItemsLocationAttributes
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentData.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	HeaderData_.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND DocumentData.Ref <> &Ref
	|	AND (HeaderData_.DocumentBasis.BusinessOperation NOT IN (
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|		)
	|		OR NOT &ThisIsRefundToSupplier)
	|
	|UNION ALL
	|
	// Return to the supplier, taking into account adjustments for an unfactured delivery or for goods in transit.
	|SELECT
	|	HeaderData_.DocumentBasis			AS Ref,
	|	TypesOfStocksWarehouse.Ref				AS InventoryOwnerAttribute,
	|	Dimension.DimensionKey					AS ItemsLocationAttributes,
	|	DocumentData.CCDNumber				AS CCDNumber,
	|	TableOfPurchaseItems.Count	AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(HeaderData_.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CAST(TableOfPurchaseItems.QuantityByGBRN AS NUMBER(23, 11))
	|	END									AS QuantityByGBRN
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DocumentData
	|		INNER JOIN Document.PurchaseAdjustment AS HeaderData_
	|		ON DocumentData.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN TableOfProductsWithKeysForAllWarehouses AS TableOfReturnItems
	|		ON DocumentData.Ref.DocumentBasis = TableOfReturnItems.DocumentInflow
	|			AND DocumentData.ItemsLocationAttributes.Products = TableOfReturnItems.Products
	|			AND DocumentData.ItemsLocationAttributes.Characteristic = TableOfReturnItems.Characteristic
	|			AND (DocumentData.ItemsLocationAttributes.Series = TableOfReturnItems.Series
	|				OR DocumentData.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentData.ItemsLocationAttributes.Purpose = TableOfReturnItems.Purpose
	|		
	|		INNER JOIN TTGoodsDebitNote AS TableOfPurchaseItems
	|		ON DocumentData.Ref = TableOfPurchaseItems.Ref
	|			AND DocumentData.ItemsLocationAttributes.Products = TableOfPurchaseItems.Products
	|			AND DocumentData.ItemsLocationAttributes.Characteristic = TableOfPurchaseItems.Characteristic
	|			AND (DocumentData.ItemsLocationAttributes.Series = TableOfPurchaseItems.Series
	|				OR DocumentData.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|				OR TableOfPurchaseItems.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentData.ItemsLocationAttributes.Purpose = TableOfPurchaseItems.Purpose
	|			AND DocumentData.ItemsLocationAttributes.StorageLocation = TableOfPurchaseItems.StorageLocation
	|			AND DocumentData.CCDNumber = TableOfPurchaseItems.CCDNumber
	|		
	|		INNER JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|		ON TypesOfStocksWarehouse.Organization = DocumentData.InventoryOwnerAttribute.Organization
	|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentData.InventoryOwnerAttribute.GoodsOwner
	|			AND TypesOfStocksWarehouse.VATTaxation = DocumentData.InventoryOwnerAttribute.VATTaxation
	|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentData.InventoryOwnerAttribute.FinancialAccountingGroup
	|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentData.InventoryOwnerAttribute.ProductsGroup
	|			AND TypesOfStocksWarehouse.PriceKind = DocumentData.InventoryOwnerAttribute.PriceKind
	|			AND NOT TypesOfStocksWarehouse.IsDuplicate
	|			AND NOT TypesOfStocksWarehouse.Obsolete1
	|			AND NOT TypesOfStocksWarehouse.DeletionMark
	|		
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON DocumentData.ItemsLocationAttributes.Products = Dimension.Products
	|			AND DocumentData.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND (DocumentData.ItemsLocationAttributes.Series = Dimension.Series
	|				OR DocumentData.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentData.ItemsLocationAttributes.Purpose = Dimension.Purpose
	|			AND DocumentData.ItemsLocationAttributes.ProductCostElement = Dimension.ProductCostElement
	|			AND TableOfPurchaseItems.Warehouse = Dimension.StorageLocation
	|
	|WHERE
	|	&ThisIsRefundToSupplier
	|	AND HeaderData_.Posted
	|	AND HeaderData_.DocumentBasis.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.DocumentInflow			AS Ref,
	|	DocumentData.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DocumentData.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DocumentData.CCDNumber					AS CCDNumber,
	|	-DocumentData.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(HeaderData_.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE -CAST(DocumentData.QuantityByGBRN AS NUMBER(23, 11))
	|	END										AS QuantityByGBRN
	|FROM
	|	Document.ReturnOfGoodsToVendor.InventoryKinds AS DocumentData
	|		INNER JOIN Document.ReturnOfGoodsToVendor AS HeaderData_
	|		ON DocumentData.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN TableOfProductsWithKeysForAllWarehouses AS TableOfGoods
	|		ON DocumentData.DocumentInflow = TableOfGoods.DocumentInflow
	|			AND DocumentData.ItemsLocationAttributes = TableOfGoods.ItemsLocationAttributes
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentData.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	HeaderData_.Posted
	|	AND DocumentData.Ref <> &Ref
	|	AND DocumentsRegistry.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfPurchase
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsDebitNote
	|";
	
	ThisIsRefundToSupplier = TypeOf(DocumentObject) = Type("DocumentObject.ReturnOfGoodsToVendor");
	Query.SetParameter("Ref", DocumentObject.Ref);
	Query.SetParameter("ThisIsRefundToSupplier", ThisIsRefundToSupplier);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	If ThisIsRefundToSupplier Then
		
		GenerateTTTableOfBalances("CompanyGoods",
										DocumentObject,
										TempTablesManager,
										ParametersForFillingInventoryTypes,
										True);
		
		TextBalances =
		"SELECT
		|	DocumentData.Organization AS Organization,
		|	AcceptedGoods.Ref AS DocumentInflow,
		|	AcceptedGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	AcceptedGoods.ItemsLocationAttributes.Products AS Products,
		|	AcceptedGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	AcceptedGoods.ItemsLocationAttributes.Series AS Series,
		|	AcceptedGoods.ItemsLocationAttributes.Purpose AS Purpose,
		|	AcceptedGoods.CCDNumber AS CCDNumber,
		|	SUM(AcceptedGoods.Count) AS CountBalance,
		|	SUM(AcceptedGoods.QuantityByGBRN) AS QuantityByGBRNBalance
		|FROM
		|	AcceptedGoods AS AcceptedGoods
		|		LEFT JOIN DocumentDataTable AS DocumentData
		|		ON (TRUE)
		|
		|GROUP BY
		|	DocumentData.Organization,
		|	AcceptedGoods.CCDNumber,
		|	AcceptedGoods.ItemsLocationAttributes.Products,
		|	AcceptedGoods.ItemsLocationAttributes.CHARACTERISTIC,
		|	AcceptedGoods.ItemsLocationAttributes.Series,
		|	AcceptedGoods.ItemsLocationAttributes.Purpose,
		|	AcceptedGoods.InventoryOwnerAttribute,
		|	AcceptedGoods.Ref
		|
		|HAVING
		|	SUM(AcceptedGoods.Count) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Organization,
		|	AcceptedGoods.DocumentInflow,
		|	AcceptedGoods.InventoryOwnerAttribute,
		|	CAST(AcceptedGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products,
		|	CAST(AcceptedGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Characteristic,
		|	CAST(AcceptedGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Series,
		|	CAST(AcceptedGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Purpose,
		|	AcceptedGoods.CCDNumber,
		|	SUM(AcceptedGoods.Count),
		|	SUM(CAST(AcceptedGoods.QuantityByGBRN AS NUMBER(23, 11)))
		|FROM
		|	TableTypesOfStocks_ AS AcceptedGoods
		|		LEFT JOIN DocumentDataTable AS DocumentData
		|		ON (TRUE)
		|
		|GROUP BY
		|	DocumentData.Organization,
		|	AcceptedGoods.CCDNumber,
		|	CAST(AcceptedGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products,
		|	CAST(AcceptedGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Characteristic,
		|	CAST(AcceptedGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Series,
		|	CAST(AcceptedGoods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Purpose,
		|	AcceptedGoods.InventoryOwnerAttribute,
		|	AcceptedGoods.DocumentInflow
		|
		|HAVING
		|	SUM(AcceptedGoods.Count) <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DocumentData.Organization AS Organization,
		|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
		|INTO TTTableOfProductsByAnalytics
		|FROM
		|	TableOfGoods AS TableOfGoods
		|		LEFT JOIN DocumentDataTable AS DocumentData
		|		ON (TRUE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	BalanceTable.Products AS Products,
		|	BalanceTable.Characteristic AS Characteristic,
		|	BalanceTable.Series AS Series,
		|	BalanceTable.Purpose AS Purpose,
		|	BalanceTable.Organization AS Organization,
		|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	BalanceTable.CCDNumber AS CCDNumber,
		|	BalanceTable.CountBalance AS CountBalance,
		|	BalanceTable.QuantityByGBRNBalance AS QuantityByGBRNBalance
		|FROM
		|	BalanceTable AS BalanceTable
		|		INNER JOIN TTTableOfProductsByAnalytics AS TableOfGoods
		|		ON (TableOfGoods.Organization = BalanceTable.Organization)
		|			AND (TableOfGoods.ItemsLocationAttributes = BalanceTable.ItemsLocationAttributes)";
		
		Query.Text = Query.Text 
			+ Common.QueryBatchSeparator()
			+ TextBalances;
		
		QueryResult = Query.ExecuteBatch();
		DataOnAcceptedBalances = QueryResult[QueryResult.UBound()-2].Unload();
		DataOnCompanyBalances = QueryResult[QueryResult.UBound()].Unload();
		
		TableBalance = New ValueTable();
		TableBalance.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
		TableBalance.Columns.Add("DocumentInflow", New TypeDescription("DocumentRef.VendorInvoice"));
		TableBalance.Columns.Add("InventoryOwnerAttribute", New TypeDescription("CatalogRef.InventoryKinds"));
		TableBalance.Columns.Add("ItemsLocationAttributes", New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
		TableBalance.Columns.Add("CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
		TableBalance.Columns.Add("CountBalance", New TypeDescription("Number"));
		TableBalance.Columns.Add("QuantityByGBRNBalance", New TypeDescription("Number"));
		TableBalance.Columns.Add("DateOfReceipt", New TypeDescription("Date"));
	
		SearchTemplate = New Structure;
		SearchTemplate.Insert("Products");
		SearchTemplate.Insert("Characteristic");
		SearchTemplate.Insert("Series");
		SearchTemplate.Insert("Purpose");
		SearchTemplate.Insert("Organization");
		SearchTemplate.Insert("CCDNumber");
		
		BalanceSearchTemplate = New Structure;
		BalanceSearchTemplate.Insert("Organization");
		BalanceSearchTemplate.Insert("DocumentInflow");
		BalanceSearchTemplate.Insert("InventoryOwnerAttribute");
		BalanceSearchTemplate.Insert("ItemsLocationAttributes");
		BalanceSearchTemplate.Insert("CCDNumber");
		BalanceSearchTemplate.Insert("DateOfReceipt");
		
		For Each RemainderLine In DataOnCompanyBalances Do
			
			FillPropertyValues(SearchTemplate, RemainderLine);
			ReceivingLines = DataOnAcceptedBalances.FindRows(SearchTemplate);
			
			For Each AcceptanceLine In ReceivingLines Do
				If AcceptanceLine.CountBalance <> 0 And RemainderLine.CountBalance <> 0 Then
					
					FillPropertyValues(BalanceSearchTemplate, RemainderLine);
					FillPropertyValues(BalanceSearchTemplate, AcceptanceLine);
					CurBalanceLines = TableBalance.FindRows(BalanceSearchTemplate);
					
					If CurBalanceLines.Count() = 0 Then
						CurrentBalanceRow = TableBalance.Add();
						FillPropertyValues(CurrentBalanceRow, BalanceSearchTemplate);
					Else
						CurrentBalanceRow = CurBalanceLines[0];
					EndIf;
					
					QuantityToDistribution = Min(AcceptanceLine.CountBalance, RemainderLine.CountBalance);
					QuantityByRNPTKDistribution = (AcceptanceLine.QuantityByGBRNBalance / AcceptanceLine.CountBalance) * QuantityToDistribution;
					
					RemainderLine.CountBalance = RemainderLine.CountBalance - QuantityToDistribution;
					RemainderLine.QuantityByGBRNBalance = RemainderLine.QuantityByGBRNBalance - QuantityByRNPTKDistribution;
					AcceptanceLine.CountBalance = AcceptanceLine.CountBalance - QuantityToDistribution;
					AcceptanceLine.QuantityByGBRNBalance = AcceptanceLine.QuantityByGBRNBalance - QuantityByRNPTKDistribution;
					
					CurrentBalanceRow.CountBalance = CurrentBalanceRow.CountBalance + QuantityToDistribution;
					CurrentBalanceRow.QuantityByGBRNBalance = CurrentBalanceRow.QuantityByGBRNBalance + QuantityByRNPTKDistribution;
	
				EndIf;
			EndDo;
			
		EndDo;
		
		Query.Text =
		"DROP BalanceTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableBalance.Organization AS Organization,
		|	TableBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	CAST(TableBalance.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
		|	TableBalance.CCDNumber AS CCDNumber,
		|	TableBalance.CountBalance AS CountBalance,
		|	TableBalance.QuantityByGBRNBalance AS QuantityByGBRNBalance,
		|	TableBalance.DateOfReceipt AS DateOfReceipt,
		|	TableBalance.DocumentInflow AS DocumentTransfers_
		|INTO BbTableOfBalances
		|FROM
		|	&TableBalance AS TableBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableBalance.Organization AS Organization,
		|	TableBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TableBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributesShipment,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttributeShipment,
		|	TableBalance.ItemsLocationAttributes.Products AS Products,
		|	TableBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	TableBalance.ItemsLocationAttributes.Series AS Series,
		|	TableBalance.ItemsLocationAttributes.Purpose AS Purpose,
		|	TableBalance.CCDNumber AS CCDNumber,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
		|	TableBalance.DateOfReceipt AS DateOfReceipt,
		|	SUM(TableBalance.CountBalance) AS CountBalance,
		|	SUM(TableBalance.QuantityByGBRNBalance) AS QuantityByGBRNBalance,
		|	TableBalance.DocumentTransfers_ AS DocumentTransfers_,
		|	SUM(0) AS SumBalance
		|INTO BalanceTable
		|FROM
		|	BbTableOfBalances AS TableBalance
		|
		|GROUP BY
		|	TableBalance.Organization,
		|	TableBalance.CCDNumber,
		|	TableBalance.ItemsLocationAttributes,
		|	TableBalance.InventoryOwnerAttribute,
		|	TableBalance.DateOfReceipt,
		|	TableBalance.ItemsLocationAttributes.Products,
		|	TableBalance.ItemsLocationAttributes.Characteristic,
		|	TableBalance.ItemsLocationAttributes.Series,
		|	TableBalance.ItemsLocationAttributes.Purpose,
		|	TableBalance.DocumentTransfers_
		|
		|HAVING
		|	SUM(TableBalance.CountBalance) <> 0";
		
		Query.SetParameter("TableBalance", TableBalance);
		
	Else // This is not a return
		
		TextBalances =
		"SELECT
		|	DocumentData.Organization AS Organization,
		|	AcceptedGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	AcceptedGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	AcceptedGoods.ItemsLocationAttributes.Products AS Products,
		|	AcceptedGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	AcceptedGoods.ItemsLocationAttributes.Series AS Series,
		|	AcceptedGoods.ItemsLocationAttributes.Purpose AS Purpose,
		|	AcceptedGoods.CCDNumber AS CCDNumber,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
		|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
		|	AcceptedGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeOfCompanyGoodsOwner,
		|	AcceptedGoods.InventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
		|	AcceptedGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeShipment,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
		|	DATETIME(1, 1, 1) AS DateOfReceipt,
		|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
		|	UNDEFINED AS DocumentLoggingIn,
		|	SUM(0) AS OnDateOfControl,
		|	SUM(0) AS CurrentDate_,
		|	SUM(0) AS SumBalance,
		|	-SUM(AcceptedGoods.Count) AS CountBalance,
		|	-SUM(AcceptedGoods.QuantityByGBRN) AS QuantityByGBRNBalance
		|INTO BalanceTable
		|FROM
		|	AcceptedGoods AS AcceptedGoods
		|		LEFT JOIN DocumentDataTable AS DocumentData
		|		ON TRUE
		|
		|GROUP BY
		|	DocumentData.Organization,
		|	AcceptedGoods.CCDNumber,
		|	AcceptedGoods.ItemsLocationAttributes,
		|	AcceptedGoods.InventoryOwnerAttribute,
		|	AcceptedGoods.ItemsLocationAttributes.Products,
		|	AcceptedGoods.ItemsLocationAttributes.CHARACTERISTIC,
		|	AcceptedGoods.ItemsLocationAttributes.Series,
		|	AcceptedGoods.ItemsLocationAttributes.Purpose
		|
		|HAVING
		|	-SUM(AcceptedGoods.Count) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Organization AS Organization,
		|	AcceptedGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	AcceptedGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DimensionKeys.Products AS Products,
		|	DimensionKeys.Characteristic AS Characteristic,
		|	DimensionKeys.Series AS Series,
		|	DimensionKeys.Purpose AS Purpose,
		|	AcceptedGoods.CCDNumber AS CCDNumber,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
		|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
		|	AcceptedGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeOfCompanyGoodsOwner,
		|	AcceptedGoods.InventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
		|	AcceptedGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeShipment,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
		|	DATETIME(1, 1, 1) AS DateOfReceipt,
		|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
		|	UNDEFINED AS DocumentLoggingIn,
		|	SUM(0) AS OnDateOfControl,
		|	SUM(0) AS CurrentDate_,
		|	SUM(0) AS SumBalance,
		|	-SUM(AcceptedGoods.Count) AS CountBalance,
		|	-SUM(CAST(AcceptedGoods.QuantityByGBRN AS NUMBER(23, 11))) AS QuantityByGBRNBalance
		|FROM
		|	TableTypesOfStocks_ AS AcceptedGoods
		|		LEFT JOIN DocumentDataTable AS DocumentData
		|		ON TRUE
		|		
		|		INNER JOIN GroupedTableOfProducts AS GroupedTableOfProducts
		|		ON AcceptedGoods.DocumentInflow = GroupedTableOfProducts.DocumentInflow
		|			AND AcceptedGoods.ItemsLocationAttributes = GroupedTableOfProducts.ItemsLocationAttributes
		|		
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
		|		ON AcceptedGoods.ItemsLocationAttributes = DimensionKeys.Ref
		|
		|GROUP BY
		|	DocumentData.Organization,
		|	AcceptedGoods.CCDNumber,
		|	AcceptedGoods.ItemsLocationAttributes,
		|	AcceptedGoods.InventoryOwnerAttribute,
		|	DimensionKeys.Products,
		|	DimensionKeys.Characteristic,
		|	DimensionKeys.Series,
		|	DimensionKeys.Purpose
		|
		|HAVING
		|	-SUM(AcceptedGoods.Count) <> 0";
		
	Query.Text = Query.Text 
		+ Common.QueryBatchSeparator()
		+ TextBalances;
		
	EndIf;
	
	Query.Execute();
	
EndProcedure

Procedure TableOfResiduesOfTransferredReturnContainers(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes)
	
	ThisIsGoodsReturn = TypeOf(DocumentObject.Ref) = Type("DocumentRef.ReturnOfGoodsFromCustomer");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref",				DocumentObject.Ref);
	Query.SetParameter("ThisIsGoodsReturn",	ThisIsGoodsReturn);
	Query.SetParameter("EmptyValueOfTransferDocument",
								Metadata.AccumulationRegisters.TransferredReturnablePackaging.Dimensions.DocumentTransfers_.Type.AdjustValue());
	
	If ValueIsFilled(DocumentObject.Date) Then 
		Query.SetParameter("Date", New Boundary(DocumentObject.Date, BoundaryType.Including));
	Else
		Query.SetParameter("Date", Undefined);
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Text =
	"SELECT
	|	TransferredReturnablePackagingBalance.Products		AS Products,
	|	TransferredReturnablePackagingBalance.Characteristic		AS Characteristic,
	|	TransferredReturnablePackagingBalance.Partner				AS Partner,
	|	TransferredReturnablePackagingBalance.DocumentTransfers_	AS DocumentTransfers_,
	|	TransferredReturnablePackagingBalance.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)		AS CorInventoryOwnerAttribute,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS OriginWarehouse,
	|	TransferredReturnablePackagingBalance.CCDNumber			AS CCDNumber,
	|	TransferredReturnablePackagingBalance.CountBalance	AS CountBalance,
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND (BEGINOFPERIOD(TransferredReturnablePackagingBalance.DocumentTransfers_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|					OR TransferredReturnablePackagingBalance.DocumentTransfers_ = &EmptyValueOfTransferDocument)
	|			THEN CAST(TransferredReturnablePackagingBalance.QuantityByGBRNBalance AS NUMBER(23, 11))
	|		ELSE 0
	|	END												AS QuantityByGBRNBalance
	|INTO TransferredReturnablePackagingBalance
	|FROM
	|	AccumulationRegister.TransferredReturnablePackaging.Balance(
	|			&Date,
	|			(Products, Characteristic, DocumentTransfers_) IN
	|					(SELECT
	|						TableOfGoods.Products,
	|						TableOfGoods.Characteristic,
	|						TableOfGoods.DocumentSalesOfGoodsAndServices
	|					FROM
	|						TableOfGoods)
	|				AND Partner IN
	|					(SELECT
	|						DocumentDataTable.Partner
	|					FROM
	|						DocumentDataTable)
	|				AND InventoryOwnerAttribute IN
	|					(SELECT
	|						AvailableTypesOfStocks.InventoryOwnerAttribute
	|					FROM
	|						AvailableTypesOfStocks)) AS TransferredReturnablePackagingBalance
	|
	|UNION ALL
	|
	|SELECT
	|	TransferredReturnablePackaging.Products			AS Products,
	|	TransferredReturnablePackaging.Characteristic			AS Characteristic,
	|	TransferredReturnablePackaging.Partner				AS Partner,
	|	TransferredReturnablePackaging.DocumentTransfers_		AS DocumentTransfers_,
	|	TransferredReturnablePackaging.InventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS CorInventoryOwnerAttribute,
	|	VALUE(Catalog.Warehouses.EmptyRef)		AS OriginWarehouse,
	|	TransferredReturnablePackaging.CCDNumber				AS CCDNumber,
	|	CASE
	|		WHEN TransferredReturnablePackaging.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -TransferredReturnablePackaging.Count
	|		ELSE TransferredReturnablePackaging.Count
	|	END											AS CountBalance,
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND (BEGINOFPERIOD(TransferredReturnablePackaging.DocumentTransfers_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|					OR TransferredReturnablePackaging.DocumentTransfers_ = &EmptyValueOfTransferDocument)
	|			THEN CASE
	|				WHEN TransferredReturnablePackaging.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -CAST(TransferredReturnablePackaging.QuantityByGBRN AS NUMBER(23, 11))
	|				ELSE CAST(TransferredReturnablePackaging.QuantityByGBRN AS NUMBER(23, 11))
	|			END
	|		ELSE 0
	|	END											AS QuantityByGBRNBalance
	|FROM
	|	AccumulationRegister.TransferredReturnablePackaging AS TransferredReturnablePackaging
	|WHERE
	|	TransferredReturnablePackaging.Recorder = &Ref
	|	AND (TransferredReturnablePackaging.Products, TransferredReturnablePackaging.Characteristic, TransferredReturnablePackaging.DocumentTransfers_) IN
	|			(SELECT
	|				TableOfGoods.Products,
	|				TableOfGoods.Characteristic,
	|				TableOfGoods.DocumentSalesOfGoodsAndServices
	|			FROM
	|				TableOfGoods)
	|	AND TransferredReturnablePackaging.Partner IN
	|			(SELECT
	|				DocumentDataTable.Partner
	|			FROM
	|				DocumentDataTable)
	|	AND TransferredReturnablePackaging.InventoryOwnerAttribute IN
	|			(SELECT
	|				AvailableTypesOfStocks.InventoryOwnerAttribute
	|			FROM
	|				AvailableTypesOfStocks)
	|
	|INDEX BY
	|	Products,
	|	Characteristic";
	
	Query.SetParameter("Ref", DocumentObject.Ref);
	Query.SetParameter("EmptyValueOfTransferDocument",
								Metadata.AccumulationRegisters.TransferredReturnablePackaging.Dimensions.DocumentTransfers_.Type.AdjustValue());
	
	If ThisIsGoodsReturn Then
		
		Query.Text = Query.Text + Common.QueryBatchSeparator() +
		"SELECT DISTINCT
		|	TableOfGoods.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
		|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	TableOfGoods.Products					AS Products,
		|	TableOfGoods.Characteristic				AS Characteristic,
		|	TableOfGoods.Purpose					AS Purpose,
		|	TableOfGoods.Series						AS Series
		|INTO GroupedTableOfProducts
		|FROM
		|	TableOfGoods AS TableOfGoods
		|
		|INDEX BY
		|	DocumentSalesOfGoodsAndServices,
		|	Products,
		|	Characteristic,
		|	Series,
		|	Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TableOfGoods.DocumentSalesOfGoodsAndServices				AS Ref,
		|	InventoryLocationAttributeKeys.DimensionKey	AS ItemsLocationAttributes
		|INTO TableOfProductsWithKeysForAllWarehouses
		|FROM
		|	TableOfGoods AS TableOfGoods
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryLocationAttributeKeys
		|		ON TableOfGoods.Products = InventoryLocationAttributeKeys.Products
		|			AND TableOfGoods.Characteristic = InventoryLocationAttributeKeys.Characteristic
		|			AND TableOfGoods.Series = InventoryLocationAttributeKeys.Series
		|
		|INDEX BY
		|	Ref,
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TSInventoryKinds.ItemsLocationAttributes		AS ItemsLocationAttributesShipment,
		|	InventoryLocationAttributeKeys.Products	AS Products,
		|	InventoryLocationAttributeKeys.Characteristic	AS Characteristic,
		|	InventoryLocationAttributeKeys.Purpose		AS Purpose,
		|	InventoryLocationAttributeKeys.Series			AS Series,
		|	InventoryLocationAttributeKeys.StorageLocation	AS StorageLocation,
		|	TSInventoryKinds.Ref							AS DocumentSalesOfGoodsAndServices,
		|	TSInventoryKinds.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS CorInventoryOwnerAttribute,
		|	TSInventoryKinds.CCDNumber							AS CCDNumber,
		|	TSInventoryKinds.Count						AS Count
		|INTO SoldGoods
		|FROM
		|	Document.CustomerInvoice.InventoryKinds AS TSInventoryKinds
		|		INNER JOIN Document.CustomerInvoice AS CustomerInvoice
		|		ON TSInventoryKinds.Ref = CustomerInvoice.Ref
		|		
		|		INNER JOIN DocumentDataTable AS DocumentDataTable
		|		ON CustomerInvoice.Organization = DocumentDataTable.Organization
		|		
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON TSInventoryKinds.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|		
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
		|			AND DocumentsRegistry.Posted
		|			AND NOT DocumentsRegistry.AdditionalRecord
		|
		|WHERE
		|	CustomerInvoice.Posted
		|	AND DocumentsRegistry.Ref IS NULL
		|	AND (TSInventoryKinds.Ref, TSInventoryKinds.ItemsLocationAttributes) IN
		|			(SELECT
		|				TableOfProductsWithKeysForAllWarehouses.Ref,
		|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
		|			FROM
		|				TableOfProductsWithKeysForAllWarehouses)
		|	AND (TSInventoryKinds.InventoryOwnerAttribute) IN
		|			(SELECT
		|				AvailableTypesOfStocks.InventoryOwnerAttribute
		|			FROM
		|				AvailableTypesOfStocks)
		|	AND CustomerInvoice.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
		|
		|UNION ALL
		|
		|SELECT
		|	TSInventoryKinds.ItemsLocationAttributes		AS ItemsLocationAttributesShipment,
		|	InventoryLocationAttributeKeys.Products	AS Products,
		|	InventoryLocationAttributeKeys.Characteristic	AS Characteristic,
		|	InventoryLocationAttributeKeys.Purpose		AS Purpose,
		|	InventoryLocationAttributeKeys.Series			AS Series,
		|	InventoryLocationAttributeKeys.StorageLocation	AS StorageLocation,
		|	SaleAdjustment.DocumentBasis		AS DocumentSalesOfGoodsAndServices,
		|	TSInventoryKinds.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
		|	TSInventoryKinds.CorInventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
		|	TSInventoryKinds.CCDNumber							AS CCDNumber,
		|	CASE
		|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
		|			THEN TSInventoryKinds.Count
		|		ELSE 0
		|	END											AS Count
		|FROM
		|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS TSInventoryKinds
		|		INNER JOIN Document.SaleAdjustment AS SaleAdjustment
		|		ON TSInventoryKinds.Ref = SaleAdjustment.Ref
		|		
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON TSInventoryKinds.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|		
		|		INNER JOIN DocumentDataTable AS DocumentDataTable
		|		ON SaleAdjustment.Organization = DocumentDataTable.Organization
		|		
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
		|			AND DocumentsRegistry.Posted
		|			AND NOT DocumentsRegistry.AdditionalRecord
		|
		|WHERE
		|	SaleAdjustment.Posted
		|	AND DocumentsRegistry.Ref IS NULL
		|	AND (SaleAdjustment.DocumentBasis, TSInventoryKinds.ItemsLocationAttributes) IN
		|			(SELECT
		|				TableOfProductsWithKeysForAllWarehouses.Ref,
		|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
		|			FROM
		|				TableOfProductsWithKeysForAllWarehouses)
		|	AND (TSInventoryKinds.InventoryOwnerAttribute) IN
		|			(SELECT
		|				AvailableTypesOfStocks.InventoryOwnerAttribute
		|			FROM
		|				AvailableTypesOfStocks)
		|	AND SaleAdjustment.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
		|
		|UNION ALL
		|
		|SELECT
		|	TSInventoryKinds.ItemsLocationAttributes		AS ItemsLocationAttributesShipment,
		|	InventoryLocationAttributeKeys.Products	AS Products,
		|	InventoryLocationAttributeKeys.Characteristic	AS Characteristic,
		|	InventoryLocationAttributeKeys.Purpose		AS Purpose,
		|	InventoryLocationAttributeKeys.Series			AS Series,
		|	InventoryLocationAttributeKeys.StorageLocation	AS StorageLocation,
		|	SaleAdjustment.DocumentBasis		AS DocumentSalesOfGoodsAndServices,
		|	TSInventoryKinds.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
		|	TSInventoryKinds.CorInventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
		|	TSInventoryKinds.CCDNumber							AS CCDNumber,
		|	CASE
		|		WHEN NOT TSInventoryKinds.ToIncomeExpenses
		|			THEN -TSInventoryKinds.Count
		|		ELSE 0
		|	END											AS Count
		|FROM
		|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS TSInventoryKinds
		|		INNER JOIN Document.SaleAdjustment AS SaleAdjustment
		|		ON TSInventoryKinds.Ref = SaleAdjustment.Ref
		|		
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON TSInventoryKinds.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|		
		|		INNER JOIN DocumentDataTable AS DocumentDataTable
		|		ON SaleAdjustment.Organization = DocumentDataTable.Organization
		|		
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
		|			AND DocumentsRegistry.Posted
		|			AND NOT DocumentsRegistry.AdditionalRecord
		|
		|WHERE
		|	SaleAdjustment.Posted
		|	AND DocumentsRegistry.Ref IS NULL
		|	AND (SaleAdjustment.DocumentBasis, TSInventoryKinds.ItemsLocationAttributes) IN
		|			(SELECT
		|				TableOfProductsWithKeysForAllWarehouses.Ref,
		|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
		|			FROM
		|				TableOfProductsWithKeysForAllWarehouses)
		|	AND (TSInventoryKinds.InventoryOwnerAttribute) IN
		|			(SELECT
		|				AvailableTypesOfStocks.InventoryOwnerAttribute
		|			FROM
		|				AvailableTypesOfStocks)
		|	AND SaleAdjustment.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
		|
		|UNION ALL
		|
		|SELECT
		|	TSInventoryKinds.ItemsLocationAttributesShipment	AS ItemsLocationAttributesShipment,
		|	InventoryLocationAttributeKeys.Products		AS Products,
		|	InventoryLocationAttributeKeys.Characteristic		AS Characteristic,
		|	InventoryLocationAttributeKeys.Purpose			AS Purpose,
		|	InventoryLocationAttributeKeys.Series				AS Series,
		|	InventoryLocationAttributeKeys.StorageLocation		AS StorageLocation,
		|	TSInventoryKinds.DocumentSalesOfGoodsAndServices					AS DocumentSalesOfGoodsAndServices,
		|	TSInventoryKinds.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)		AS CorInventoryOwnerAttribute,
		|	TSInventoryKinds.CCDNumber								AS CCDNumber,
		|	-TSInventoryKinds.Count							AS Count
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS TSInventoryKinds
		|		INNER JOIN Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
		|		ON TSInventoryKinds.Ref = ReturnOfGoodsFromCustomer.Ref
		|		
		|		INNER JOIN DocumentDataTable AS DocumentDataTable
		|		ON ReturnOfGoodsFromCustomer.Organization = DocumentDataTable.Organization
		|		
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON TSInventoryKinds.ItemsLocationAttributesShipment = InventoryLocationAttributeKeys.Ref
		|		
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON TSInventoryKinds.Ref = DocumentsRegistry.ReversedDocument
		|			AND DocumentsRegistry.Posted
		|			AND NOT DocumentsRegistry.AdditionalRecord
		|
		|WHERE
		|	TSInventoryKinds.Ref <> &Ref
		|	AND DocumentsRegistry.Ref IS NULL
		|	AND (TSInventoryKinds.DocumentSalesOfGoodsAndServices, TSInventoryKinds.ItemsLocationAttributes) IN
		|			(SELECT
		|				TableOfProductsWithKeysForAllWarehouses.Ref,
		|				TableOfProductsWithKeysForAllWarehouses.ItemsLocationAttributes
		|			FROM
		|				TableOfProductsWithKeysForAllWarehouses)
		|	AND ReturnOfGoodsFromCustomer.Posted
		|	AND (TSInventoryKinds.InventoryOwnerAttribute) IN
		|			(SELECT
		|				AvailableTypesOfStocks.InventoryOwnerAttribute
		|			FROM
		|				AvailableTypesOfStocks)
		|	AND ReturnOfGoodsFromCustomer.Date <= ENDOFPERIOD(DocumentDataTable.Date, DAY)
		|
		|INDEX BY
		|	DocumentSalesOfGoodsAndServices,
		|	Products,
		|	Characteristic,
		|	Series,
		|	Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GroupedTableOfProducts.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	SoldGoods.Products		AS Products,
		|	SoldGoods.Characteristic		AS Characteristic,
		|	SoldGoods.StorageLocation		AS OriginWarehouse,
		|	SoldGoods.Purpose			AS Purpose,
		|	SoldGoods.Series				AS Series,
		|	SoldGoods.DocumentSalesOfGoodsAndServices	AS DocumentSalesOfGoodsAndServices,
		|	SoldGoods.InventoryOwnerAttribute			AS InventoryOwnerAttributeShipment,
		|	SoldGoods.CorInventoryOwnerAttribute		AS CorInventoryOwnerAttribute,
		|	SoldGoods.CCDNumber			AS CCDNumber,
		|	SUM(SoldGoods.Count)	AS CountBalance
		|FROM
		|	SoldGoods AS SoldGoods
		|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON SoldGoods.InventoryOwnerAttribute = InventoryKinds.Ref
		|		
		|		INNER JOIN GroupedTableOfProducts AS GroupedTableOfProducts
		|		ON SoldGoods.Products = GroupedTableOfProducts.Products
		|			AND SoldGoods.Characteristic = GroupedTableOfProducts.Characteristic
		|			AND SoldGoods.Series = GroupedTableOfProducts.Series
		|			AND SoldGoods.DocumentSalesOfGoodsAndServices = GroupedTableOfProducts.DocumentSalesOfGoodsAndServices
		|			AND (SoldGoods.Purpose = GroupedTableOfProducts.Purpose
		|				OR GroupedTableOfProducts.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				OR SoldGoods.Purpose = VALUE(Catalog.Assignments.EmptyRef))
		|
		|GROUP BY
		|	GroupedTableOfProducts.ItemsLocationAttributes,
		|	SoldGoods.Products,
		|	SoldGoods.Characteristic,
		|	SoldGoods.StorageLocation,
		|	SoldGoods.Purpose,
		|	SoldGoods.Series,
		|	SoldGoods.DocumentSalesOfGoodsAndServices,
		|	SoldGoods.InventoryOwnerAttribute,
		|	SoldGoods.CorInventoryOwnerAttribute,
		|	SoldGoods.CCDNumber
		|
		|HAVING
		|	SUM(SoldGoods.Count) > 0";
		
		Query.Text = Query.Text + Common.QueryBatchSeparator()
						+ QueryTextTransferredReturnablePackagingBalance(False)
						+ Common.QueryBatchSeparator() +
		"DROP TransferredReturnablePackagingBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP GroupedTableOfProducts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfProductsWithKeysForAllWarehouses
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SoldGoods";
		
		QueryResult = Query.ExecuteBatch();
		
		TransferredPackageBalance		= QueryResult[QueryResult.UBound() - 4].Unload();
		SoldGoodsBalance	= QueryResult[QueryResult.UBound() - 5].Unload();
		
		NamesOfGroupingColumns = "ItemsLocationAttributes, DocumentSalesOfGoodsAndServices, OriginWarehouse, InventoryOwnerAttributeShipment,
									|CCDNumber";
		SearchKey = "ItemsLocationAttributes, DocumentSalesOfGoodsAndServices, InventoryOwnerAttributeShipment, CCDNumber";
		
		SoldGoodsBalance.GroupBy(NamesOfGroupingColumns, "CountBalance");
		SoldGoodsBalance.Indexes.Add(SearchKey);
		
		BalanceTable = TransferredPackageBalance.CopyColumns();
		BalanceTable.Columns.Add("QuantityByGBRN", New TypeDescription("Number", New NumberQualifiers(23, 11)));
		
		RowFilter = New Structure(SearchKey);
		
		For Each TareString In TransferredPackageBalance Do
			
			QuantityPerLine		= TareString.CountBalance;
			QuantityByRNPTVLine	= TareString.QuantityByGBRNBalance;
			
			FillPropertyValues(RowFilter, TareString);
			
			For Each ImplementationString In SoldGoodsBalance.FindRows(RowFilter) Do
				If ImplementationString.CountBalance <= 0 Then
					Continue;
				EndIf;
				
				Count = Min(QuantityPerLine, ImplementationString.CountBalance);
				
				NewRow = BalanceTable.Add();
				FillPropertyValues(NewRow, TareString);
				
				NewRow.OriginWarehouse		= ImplementationString.OriginWarehouse;
				NewRow.CountBalance	= Count;
				NewRow.QuantityByGBRN	= ?(QuantityPerLine - Count = 0,
													QuantityByRNPTVLine,
													Count * TareString.QuantityByGBRNBalance
														/ TareString.CountBalance);
				
				ImplementationString.CountBalance = ImplementationString.CountBalance - Count;
				
				QuantityPerLine		= QuantityPerLine - NewRow.CountBalance;
				QuantityByRNPTVLine	= QuantityByRNPTVLine - NewRow.QuantityByGBRNBalance;
				
				If QuantityPerLine = 0 Then
					Break;
				EndIf;
			EndDo;
			
			If QuantityPerLine > 0 Then
				NewRow = BalanceTable.Add();
				FillPropertyValues(NewRow, TareString);
				
				NewRow.OriginWarehouse		= DocumentObject.Warehouse;
				NewRow.CountBalance	= QuantityPerLine;
				NewRow.QuantityByGBRN	= QuantityByRNPTVLine;
			EndIf;
			
		EndDo;
		
		Query.Text =
		"SELECT
		|	TransferredReturnablePackaging.Warehouse				AS Partner,
		|	TransferredReturnablePackaging.Products		AS Products,
		|	TransferredReturnablePackaging.Characteristic		AS Characteristic,
		|	TransferredReturnablePackaging.DocumentSalesOfGoodsAndServices	AS DocumentTransfers_,
		|	TransferredReturnablePackaging.InventoryOwnerAttributeShipment	AS InventoryOwnerAttribute,
		|	TransferredReturnablePackaging.CorInventoryOwnerAttribute		AS CorInventoryOwnerAttribute,
		|	TransferredReturnablePackaging.OriginWarehouse		AS OriginWarehouse,
		|	TransferredReturnablePackaging.CCDNumber			AS CCDNumber,
		|	TransferredReturnablePackaging.CountBalance	AS CountBalance,
		|	TransferredReturnablePackaging.QuantityByGBRN	AS QuantityByGBRNBalance
		|INTO TransferredReturnablePackagingBalance
		|FROM
		|	&BalanceTable AS TransferredReturnablePackaging";
		
		Query.Text = Query.Text + Common.QueryBatchSeparator()
						+ QueryTextTransferredReturnablePackagingBalance();
		
		Query.SetParameter("BalanceTable", BalanceTable);
		
	Else
		Query.Text = Query.Text + Common.QueryBatchSeparator()
						+ QueryTextTransferredReturnablePackagingBalance();
	EndIf;
	
	Query.Execute();
	
EndProcedure

Procedure TableOfBalancesOfGoodsTransferredBetweenOrganizations(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	InventoryLocationAttributeKeys.Ref AS ItemsLocationAttributes,
	|	InventoryLocationAttributeKeys.Products AS Products,
	|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
	|	InventoryLocationAttributeKeys.Series AS Series,
	|	InventoryLocationAttributeKeys.Purpose AS Purpose
	|INTO TTKeysForAnalyticsOfBalanceSelection
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|WHERE
	|	InventoryLocationAttributeKeys.Ref IN
	|			(SELECT
	|				TableOfGoods.ItemsLocationAttributes
	|			FROM
	|				TableOfGoods)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransferredGoods.Organization AS Organization,
	|	TransferredGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TransferredGoods.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	TransferredGoods.InventoryOwnerAttributeShipment AS InventoryOwnerAttributeShipment,
	|	TransferredGoods.DocumentTransfers_ AS DocumentTransfers_,
	|	TransferredGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TransferredGoods.CCDNumber AS CCDNumber,
	|	SUM(TransferredGoods.Count) AS CountBalance,
	|	SUM(TransferredGoods.QuantityByGBRN) AS QuantityByGBRNBalance,
	|	SUM(TransferredGoods.ExciseTaxAmount) AS ExciseTaxAmountBalance,
	|	0 AS SumBalance
	|FROM
	|	(SELECT
	|		DataOfInventory.ItemsLocationAttributes AS ItemsLocationAttributesShipment,
	|		DataOfInventory.InventoryOwnerAttribute AS InventoryOwnerAttributeShipment,
	|		TTKeysForAnalyticsOfBalanceSelection.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		HeaderData_.CompanyRecipient AS Organization,
	|		DataOfInventory.RecipientInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		DataOfInventory.CCDNumber AS CCDNumber,
	|		DataOfInventory.Count AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(HeaderData_.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(DataOfInventory.QuantityByGBRN AS NUMBER(23, 11))
	|		END AS QuantityByGBRN,
	|		DataOfInventory.ExciseTaxAmount AS ExciseTaxAmount,
	|		DataOfInventory.Ref AS DocumentTransfers_
	|	FROM
	|		Document.CustomerInvoiceIntercompany.InventoryKinds AS DataOfInventory
	|			INNER JOIN Document.CustomerInvoiceIntercompany AS HeaderData_
	|			ON DataOfInventory.Ref = HeaderData_.Ref
	|			
	|			INNER JOIN DocumentDataTable AS DocumentDataTable
	|			ON HeaderData_.BusinessOperation = DocumentDataTable.EconomicTransferOperation
	|				AND HeaderData_.CompanyRecipient = DocumentDataTable.Organization
	|				AND HeaderData_.Organization = DocumentDataTable.CompanyRecipient
	|				AND HeaderData_.Posted
	|				AND HeaderData_.Date <= ENDOFPERIOD(DocumentDataTable.Date, MONTH)
	|			
	|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON DataOfInventory.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|			
	|			INNER JOIN TTKeysForAnalyticsOfBalanceSelection AS TTKeysForAnalyticsOfBalanceSelection
	|			ON InventoryLocationAttributeKeys.Products = TTKeysForAnalyticsOfBalanceSelection.Products
	|				AND InventoryLocationAttributeKeys.Characteristic = TTKeysForAnalyticsOfBalanceSelection.Characteristic
	|				AND InventoryLocationAttributeKeys.Series = TTKeysForAnalyticsOfBalanceSelection.Series
	|				AND InventoryLocationAttributeKeys.Purpose = TTKeysForAnalyticsOfBalanceSelection.Purpose
	|	WHERE
	|		HeaderData_.Ref IN
	|				(SELECT DISTINCT
	|					TableOfGoods.DocumentTransfers_ AS Ref
	|				FROM
	|					TableOfGoods AS TableOfGoods)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataOfInventory.ItemsLocationAttributesShipment,
	|		DataOfInventory.RecipientInventoryOwnerAttribute,
	|		DataOfInventory.ItemsLocationAttributes,
	|		HeaderData_.Organization,
	|		DataOfInventory.InventoryOwnerAttribute,
	|		DataOfInventory.CCDNumber,
	|		-DataOfInventory.Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(HeaderData_.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE -CAST(DataOfInventory.QuantityByGBRN AS NUMBER(23, 11))
	|		END,
	|		-DataOfInventory.ExciseTaxAmount,
	|		DataOfInventory.DocumentTransfers_
	|	FROM
	|		Document.IntercompanyGoodsReturn.InventoryKinds AS DataOfInventory
	|			INNER JOIN Document.IntercompanyGoodsReturn AS HeaderData_
	|			ON DataOfInventory.Ref = HeaderData_.Ref
	|			
	|			INNER JOIN DocumentDataTable AS DocumentDataTable
	|			ON HeaderData_.BusinessOperation = DocumentDataTable.BusinessReturnOperation
	|				AND HeaderData_.Organization = DocumentDataTable.Organization
	|				AND HeaderData_.CompanyRecipient = DocumentDataTable.CompanyRecipient
	|				AND HeaderData_.Posted
	|				AND HeaderData_.Date <= ENDOFPERIOD(DocumentDataTable.Date, MONTH)
	|			
	|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON DataOfInventory.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|	WHERE
	|		DataOfInventory.Ref <> &Ref
	|		AND DataOfInventory.DocumentTransfers_ IN
	|				(SELECT DISTINCT
	|					TableOfGoods.DocumentTransfers_ AS DocumentTransfers_
	|				FROM
	|					TableOfGoods AS TableOfGoods)
	|		AND (InventoryLocationAttributeKeys.Products, InventoryLocationAttributeKeys.Characteristic, InventoryLocationAttributeKeys.Series, InventoryLocationAttributeKeys.Purpose) IN
	|				(SELECT
	|					TTKeysForAnalyticsOfBalanceSelection.Products,
	|					TTKeysForAnalyticsOfBalanceSelection.Characteristic,
	|					TTKeysForAnalyticsOfBalanceSelection.Series,
	|					TTKeysForAnalyticsOfBalanceSelection.Purpose
	|				FROM
	|					TTKeysForAnalyticsOfBalanceSelection)) AS TransferredGoods
	|
	|GROUP BY
	|	TransferredGoods.CCDNumber,
	|	TransferredGoods.Organization,
	|	TransferredGoods.ItemsLocationAttributes,
	|	TransferredGoods.ItemsLocationAttributesShipment,
	|	TransferredGoods.InventoryOwnerAttributeShipment,
	|	TransferredGoods.DocumentTransfers_,
	|	TransferredGoods.InventoryOwnerAttribute
	|
	|HAVING
	|	SUM(TransferredGoods.Count) > 0";
	
	Query.SetParameter("Ref", DocumentObject.Ref);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryResult = Query.Execute();
	
	TableOfBalancesOfTransferredGoods = QueryResult.Unload();
	
	GenerateTTTableOfBalances("CompanyGoods",
									DocumentObject,
									TempTablesManager,
									ParametersForFillingInventoryTypes,
									True);
	
	Query.Text = 
	"SELECT
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceTable.Warehouse AS Warehouse,
	|	BalanceTable.Products AS Products,
	|	BalanceTable.Characteristic AS Characteristic,
	|	BalanceTable.Series AS Series,
	|	BalanceTable.Purpose AS Purpose,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceTable.CCDNumber AS CCDNumber,
	|	BalanceTable.DateOfReceipt AS DateOfReceipt,
	|	BalanceTable.CountBalance AS CountBalance,
	|	CAST(BalanceTable.QuantityByGBRNBalance AS NUMBER(23, 11)) AS QuantityByGBRNBalance,
	|	BalanceTable.SumBalance AS SumBalance
	|FROM
	|	BalanceTable AS BalanceTable";
	
	QueryResult = Query.Execute();
	TableOfOrganizationsProductBalances = QueryResult.Unload();
	
	TableOfGoods = DocumentObject.Goods.Unload(,
													"ItemsLocationAttributes, DocumentTransfers_, CCDNumber,Count,
													|QuantityByGBRN");
	TableOfGoods.GroupBy("ItemsLocationAttributes, DocumentTransfers_, CCDNumber", "Count, QuantityByGBRN");
	
	DeductTransferredGoodsFromBalance(TableOfOrganizationsProductBalances, TableOfBalancesOfTransferredGoods, TableOfGoods);
	
	Query.Text = 
	"DROP BalanceTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanyStockBalance.Organization AS Organization,
	|	CompanyStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyStockBalance.Warehouse AS Warehouse,
	|	CompanyStockBalance.Products AS Products,
	|	CompanyStockBalance.Characteristic AS Characteristic,
	|	CompanyStockBalance.Series AS Series,
	|	CompanyStockBalance.Purpose AS Purpose,
	|	CompanyStockBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanyStockBalance.CCDNumber AS CCDNumber,
	|	CompanyStockBalance.DateOfReceipt AS DateOfReceipt,
	|	CompanyStockBalance.CountBalance AS CountBalance,
	|	CAST(CompanyStockBalance.QuantityByGBRNBalance AS NUMBER(23, 11)) AS QuantityByGBRNBalance,
	|	CompanyStockBalance.SumBalance AS SumBalance
	|INTO CompanyStockBalance
	|FROM
	|	&TableOfOrganizationsProductBalances AS CompanyStockBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesOfTransferredGoods.Organization AS Organization,
	|	BalancesOfTransferredGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalancesOfTransferredGoods.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	BalancesOfTransferredGoods.InventoryOwnerAttributeShipment AS InventoryOwnerAttributeShipment,
	|	BalancesOfTransferredGoods.DocumentTransfers_ AS DocumentTransfers_,
	|	BalancesOfTransferredGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalancesOfTransferredGoods.ExciseTaxAmountBalance AS ExciseTaxAmountBalance,
	|	BalancesOfTransferredGoods.CCDNumber AS CCDNumber,
	|	BalancesOfTransferredGoods.CountBalance AS CountBalance,
	|	CAST(BalancesOfTransferredGoods.QuantityByGBRNBalance AS NUMBER(23, 11)) AS QuantityByGBRNBalance
	|INTO BalancesOfTransferredGoods
	|FROM
	|	&TableOfBalancesOfTransferredGoods AS BalancesOfTransferredGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanyStockBalance.Organization AS Organization,
	|	CompanyStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributesShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	CompanyStockBalance.Warehouse AS Warehouse,
	|	CompanyStockBalance.Products AS Products,
	|	CompanyStockBalance.Characteristic AS Characteristic,
	|	CompanyStockBalance.Series AS Series,
	|	CompanyStockBalance.Purpose AS Purpose,
	|	VALUE(Document.CustomerInvoiceIntercompany.EmptyRef) AS DocumentTransfers_,
	|	CompanyStockBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanyStockBalance.CCDNumber AS CCDNumber,
	|	CompanyStockBalance.DateOfReceipt AS DateOfReceipt,
	|	CompanyStockBalance.CountBalance AS CountBalance,
	|	CompanyStockBalance.QuantityByGBRNBalance AS QuantityByGBRNBalance,
	|	0 AS ExciseTaxAmountBalance,
	|	CompanyStockBalance.SumBalance AS SumBalance
	|INTO BalanceTable
	|FROM
	|	CompanyStockBalance AS CompanyStockBalance
	|
	|WHERE
	|	CompanyStockBalance.CountBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	BalancesOfTransferredGoods.Organization,
	|	BalancesOfTransferredGoods.ItemsLocationAttributes,
	|	BalancesOfTransferredGoods.ItemsLocationAttributesShipment,
	|	BalancesOfTransferredGoods.InventoryOwnerAttributeShipment,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	InventoryLocationAttributeKeys.StorageLocation,
	|	InventoryLocationAttributeKeys.Products,
	|	InventoryLocationAttributeKeys.Characteristic,
	|	InventoryLocationAttributeKeys.Series,
	|	InventoryLocationAttributeKeys.Purpose,
	|	BalancesOfTransferredGoods.DocumentTransfers_,
	|	BalancesOfTransferredGoods.InventoryOwnerAttribute,
	|	BalancesOfTransferredGoods.CCDNumber,
	|	DatesOfCompanyGoodsReceipt.DateOfReceipt,
	|	BalancesOfTransferredGoods.CountBalance,
	|	BalancesOfTransferredGoods.QuantityByGBRNBalance,
	|	BalancesOfTransferredGoods.ExciseTaxAmountBalance,
	|	0
	|FROM
	|	BalancesOfTransferredGoods AS BalancesOfTransferredGoods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON BalancesOfTransferredGoods.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfCompanyGoodsReceipt
	|		ON BalancesOfTransferredGoods.InventoryOwnerAttribute = DatesOfCompanyGoodsReceipt.InventoryOwnerAttribute
	|			AND BalancesOfTransferredGoods.CCDNumber = DatesOfCompanyGoodsReceipt.CCDNumber
	|			AND (InventoryLocationAttributeKeys.Products = DatesOfCompanyGoodsReceipt.Products)
	|			AND (InventoryLocationAttributeKeys.Characteristic = DatesOfCompanyGoodsReceipt.Characteristic)
	|			AND (InventoryLocationAttributeKeys.Series = DatesOfCompanyGoodsReceipt.Series)
	|			AND (InventoryLocationAttributeKeys.Purpose = DatesOfCompanyGoodsReceipt.Purpose)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CompanyStockBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP BalancesOfTransferredGoods";
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("TableOfOrganizationsProductBalances", TableOfOrganizationsProductBalances);
	Query.SetParameter("TableOfBalancesOfTransferredGoods", TableOfBalancesOfTransferredGoods);
	
	Query.Execute();
	
EndProcedure

Procedure DeductTransferredGoodsFromBalance(TableOfOrganizationsProductBalances, TableOfBalancesOfTransferredGoods, TableOfGoods)
	
	ResidueSearchStructure	= New Structure("Organization, ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber");
	ProductSearchStructure_	= New Structure("ItemsLocationAttributes, DocumentTransfers_, CCDNumber");
	
	For Each RowOfTransmitted In TableOfBalancesOfTransferredGoods Do
		
		QuantityToDeduct = RowOfTransmitted.CountBalance;
		
		FillPropertyValues(ProductSearchStructure_, RowOfTransmitted);
		
		ProductLines_2 = TableOfGoods.FindRows(ProductSearchStructure_);
		If ProductLines_2.Count() > 0 Then
			// We subtract no more than the quantity from the table of goods
			QuantityToDeduct = Min(ProductLines_2[0].Count, QuantityToDeduct);
		Else
			Continue;
		EndIf;
		
		FillPropertyValues(ResidueSearchStructure, RowOfTransmitted);
		BusinessProductBalanceLines = TableOfOrganizationsProductBalances.FindRows(ResidueSearchStructure);
		
		For Each RowOfResidues In BusinessProductBalanceLines Do
			
			If QuantityToDeduct = 0
				Or RowOfResidues.CountBalance = 0 Then
				
				Break;
				
			EndIf;
			
			If RowOfResidues.CountBalance > QuantityToDeduct Then
				CountBalance = RowOfResidues.CountBalance;
				
				RowOfResidues.CountBalance = RowOfResidues.CountBalance - QuantityToDeduct;
				RowOfResidues.QuantityByGBRNBalance = RowOfResidues.QuantityByGBRNBalance - (QuantityToDeduct
														* RowOfResidues.QuantityByGBRNBalance / CountBalance);
			Else
				RowOfResidues.CountBalance = 0;
				RowOfResidues.QuantityByGBRNBalance = 0;
			EndIf;
			
		EndDo;
		
		If ProductLines_2.Count() > 0 Then
			Count = ProductLines_2[0].Count;
			
			ProductLines_2[0].Count = QuantityToDeduct;
			ProductLines_2[0].QuantityByGBRN = ?(Count = 0,
													0,
													QuantityToDeduct * ProductLines_2[0].QuantityByGBRN / Count);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ControlOfOperationsOnGoodsOfOrganizations

Function DateOfLastMovement() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CompanyGoods.Period AS Period,
	|	CompanyGoods.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CompanyGoods AS CompanyGoods
	|
	|ORDER BY
	|	Period DESC";
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = Result.Select();
	If Selection.Next() Then
		If Selection.Period > AddMonth(CurrentSessionDate(), 12) Then
			
			ExceptionText = NStr("vi = 'Đã kết chuyển chứng từ %Recorder% theo biểu ghi %Register1% với ngày lớn hơn ngày hiện tại 12 tháng. Hãy hủy kết chuyển chứng từ này và sửa lại ngày.';
								|ru = 'Документ %Recorder% проведен по регистру %Register1% с датой, которая больше текущей на 12 месяцев. Отмените проведение этого документа и исправьте дату.';
								|en = '%Recorder% document is posted in the %Register1% register with a date that exceeds the current date by 12 months. Cancel the posting of this document and correct the date.'; fa = '%Recorder% document is posted in the %Register1% register with a date that exceeds the current date by 12 months. Cancel the posting of this document and correct the date.';
								|it = 'Il documento %Recorder% è stato eseguito in base al registro %Register1% con data successiva rispetto a quella attuale di 12 mesi. Annullare l''esecuzione di tale documento e correggere la data.';
								|pl = 'Dokument %Recorder% posiadany w rejestrze %Register1% z datą większą niż bieżące 12 miesięcy. Anuluj publikowanie tego dokumentu i popraw datę.';
								|tr = '%Recorder% belgesi, geçerli tarihten 12 ay daha eski bir tarihle %Register1% kaydedildi. Bu belgenin kaydını iptal et ve tarihi düzelt.'");
			ExceptionText = StrReplace(ExceptionText, "%Register1%", "CompanyGoods");
			ExceptionText = StrReplace(ExceptionText, "%Recorder%", Selection.Recorder);
			Raise ExceptionText;
			
		EndIf;
		
		Return Selection.Period;
	Else
		Return Date('00010101');
	EndIf;
	
EndFunction

Function DateOfFirstReserve(DefaultDate) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	CompanySafeStock.Period AS Period
		|FROM
		|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
		|
		|ORDER BY
		|	Period";
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	SelectionDetailRecords = QueryResult.Select();
	If SelectionDetailRecords.Next() Then
		Return SelectionDetailRecords.Period;
	Else
		Return DefaultDate;
	EndIf;
	
EndFunction

Function NameTTBalancesAtEndOfMonth(Period, NamePrefix = "") Export
	
	If IsBlankString(NamePrefix) Then
		Return "Balance" + Format(EndOfMonth(Period), DateFormatInTTName());
	Else
		Return NamePrefix + Format(EndOfMonth(Period), DateFormatInTTName());
	EndIf;
	
EndFunction

Function DateFormatInTTName() Export
	
	Return "DF=yyyyMMdd";
	
EndFunction

#EndRegion

#Region Other

// Records the movement of the document in the IB.
//
// Parameters:
//	MovementManager - AccumulationRegisterManager - The register of accumulation, in which are written the movement.
//	Table - ValueTable - Table source of movements.
//	Ref - DocumentRef - link to the document.
//	FillingWithCycle - Boolean - Entries in the set are loaded or filled in by a loop. By default, false.
//	SetActive - Boolean - The installation activity in the recorded records. By default, true.
//	AuxProperties - Structure - Properties passed to a set of register entries.
//
Procedure RecordRegisteredRecordsInDatabase(MovementManager, Table, Ref, FillingWithCycle = False, SetActive = True, AuxProperties = Undefined) Export
	Set = MovementManager.CreateRecordSet();
	Set.Filter.Recorder.Set(Ref);
	Set.Read();
	If AuxProperties <> Undefined Then
		For Each Property In AuxProperties Do
			Set.AdditionalProperties.Insert(Property.Key, Property.Value);
		EndDo;
	EndIf;
	If Set.Count() > 0 Or Table.Count() > 0 Then
		If FillingWithCycle Then
			For Each String In Table Do
				Record = Set.Add();
				FillPropertyValues(Record, String);
			EndDo;
		Else
			Set.Load(Table);
		EndIf;
		If SetActive Then
			Set.SetActive(True);
		EndIf;
		Set.Write();
	EndIf;
EndProcedure

Function DescriptionOfTablesWithRequiredColumns()
	
	DescriptionOfTables = New Structure;
	
	DescriptionOfTables.Insert("TableOfGoods", New Map);
	DescriptionOfTables.TableOfGoods.Insert("DocumentSalesOfGoodsAndServices", "UNDEFINED");
	DescriptionOfTables.TableOfGoods.Insert("DocumentLoggingIn", "UNDEFINED");
	DescriptionOfTables.TableOfGoods.Insert("SelectTypesOfStocks", "TRUE");
	DescriptionOfTables.TableOfGoods.Insert("CommissionAmount", "0");
	DescriptionOfTables.TableOfGoods.Insert("AmountVATRemuneration", "0");
	DescriptionOfTables.TableOfGoods.Insert("PriceKind", "VALUE(Catalog.VendorPriceTypes.EmptyRef)");
	DescriptionOfTables.TableOfGoods.Insert("MaterialProviderCompany", "VALUE(Catalog.Companies.EmptyRef)");
	DescriptionOfTables.Insert("TableTypesOfStocks_", New Map);
	DescriptionOfTables.TableTypesOfStocks_.Insert("DocumentSalesOfGoodsAndServices", "UNDEFINED");
	DescriptionOfTables.TableTypesOfStocks_.Insert("DocumentLoggingIn", "UNDEFINED");
	DescriptionOfTables.TableTypesOfStocks_.Insert("OriginWarehouse", "VALUE(Catalog.Warehouses.EmptyRef)");
	DescriptionOfTables.TableTypesOfStocks_.Insert("InventoryOwnerAttributesAreSpecifiedManually", "FALSE");
	DescriptionOfTables.TableTypesOfStocks_.Insert("RecipientInventoryOwnerAttribute", "UNDEFINED");
	DescriptionOfTables.TableTypesOfStocks_.Insert("CorInventoryOwnerAttribute", "VALUE(Catalog.InventoryKinds.EmptyRef)");
	
	DescriptionOfTables.Insert("TableTypesOfStocksByPeriod", New Map);
	DescriptionOfTables.TableTypesOfStocksByPeriod.Insert("DocumentSalesOfGoodsAndServices", "UNDEFINED");
	DescriptionOfTables.TableTypesOfStocksByPeriod.Insert("DocumentLoggingIn", "UNDEFINED");
	DescriptionOfTables.TableTypesOfStocksByPeriod.Insert("OriginWarehouse", "VALUE(Catalog.Warehouses.EmptyRef)");
	DescriptionOfTables.TableTypesOfStocksByPeriod.Insert("InventoryOwnerAttributesAreSpecifiedManually", "FALSE");
	
	DescriptionOfTables.Insert("OriginalProductTable", New Map);
	DescriptionOfTables.OriginalProductTable.Insert("DocumentSalesOfGoodsAndServices", "UNDEFINED");
	DescriptionOfTables.OriginalProductTable.Insert("DocumentLoggingIn", "UNDEFINED");
	DescriptionOfTables.OriginalProductTable.Insert("ProductsGroup", "VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)");
	DescriptionOfTables.OriginalProductTable.Insert("PriceKind", "VALUE(Catalog.VendorPriceTypes.EmptyRef)");
	DescriptionOfTables.OriginalProductTable.Insert("SubjectToExcise", "FALSE");
	DescriptionOfTables.OriginalProductTable.Insert("BusinessUnitProduction", "VALUE(Catalog.BusinessStructure.EmptyRef)");
	DescriptionOfTables.Insert("DocumentDataTable", New Map);
	DescriptionOfTables.DocumentDataTable.Insert("Currency", "VALUE(Catalog.Currencies.EmptyRef)");
	DescriptionOfTables.DocumentDataTable.Insert("SubjectToExcise", "FALSE");
	DescriptionOfTables.DocumentDataTable.Insert("BusinessUnitProduction", "VALUE(Catalog.BusinessStructure.EmptyRef)");
	Return DescriptionOfTables;

EndFunction

// A utility function for viewing the contents of the enterprise Reserve register in the debugger.
// 
// Returns:
// ValueTable  - the contents of the register.
//
Function ShowOrganizationSProductReserves() Export
	Query = New Query("SELECT * FROM AccumulationRegister.CompanySafeStock");
	Return Query.Execute().Unload();
EndFunction

// Checks whether there are records in the inventory information register of the organizations That are being deleted.
//
// Parameters:
//	Source - DocumentObject -Accumulation register Manager - the accumulation Register in which movements are written.
//	Cancel - Boolean - True, indicates that you don't need to delete the logger.
//
Procedure CheckIfThereAreEntriesInCompanySafeStockBeforeRemovingRecorder(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;

	DocumentType = TypeOf(Source.Ref);
	
	If Not Metadata.AccumulationRegisters.CompanySafeStock.StandardAttributes.Recorder.Type.ContainsType(DocumentType) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CompanySafeStock.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.Recorder = &Recorder";
	
	Query.SetParameter("Recorder", Source.Ref);
	
	If Not Query.Execute().IsEmpty() Then
		
		ExceptionText = NStr("vi = 'Theo chứng từ %Document% có bản ghi kết chuyển trong biểu ghi %Register1%. Không thể xóa chứng từ.';
							|ru = 'По документу %Document% есть движения в регистре %Register1%. Удаление документа невозможно.';
							|en = 'The %Document% contains records in the %Register1% register. Cannot remove the document.'; fa = 'The %Document% contains records in the %Register1% register. Cannot remove the document.';
							|it = 'In base al documento %Document% esistono movimenti nel registro %Register1%. Impossibile cancellare il documento.';
							|pl = 'Według dokumentu %Document% sa przepływy w rejestrze %Register1%. Usunięcie dokumentu jest niemożliwe.';
							|tr = '%Document% belgesine göre, %Register1% kaydında hareketler var. Belge silinemez.'");
		ExceptionText = StrReplace(ExceptionText, "%Register1%", "CompanySafeStock");
		ExceptionText = StrReplace(ExceptionText, "%Document%", Source.Ref);
		
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

// Checks whether a temporary table exists in the temporary table Manager and whether it contains records.
//
// Parameters:
//	TempTablesManager - TempTablesManager - The temporary table Manager that is being validated.
//	TTName - String - name of the temporary table that is being checked for records.
//
// Returns:
//	Boolean - True when the temporary table manager contains a temporary table with records.
//
Function HasRecordsInTemporaryTable(TempTablesManager, TTName)
	
	TempTable = TempTablesManager.Tables.Find(TTName);
	
	If TempTable = Undefined Then
		Return False;
	EndIf;
	
	Return Not TempTable.GetData().IsEmpty();
	
EndFunction

// Saves in the Manager of temporary tables of movement of the reversed document by the register Of goods of organizations.
//
// Parameters:
//	ReversedDocument - DocumentRef - Link to the document being reversed.
//	TempTablesManager - TempTablesManager - Temporary table Manager to place the table in.
//	TTName - String - name of the temporary table that will contain information about document movements.
//
Procedure SaveRegisteredRecordsOfReversedDocument(ReversedDocument, TempTablesManager, TTName)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	CompanyGoods.Period		AS Period,
	|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoods.Organization	AS Organization,
	|	CompanyGoods.InventoryOwnerAttribute	AS InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber		AS CCDNumber,
	|	CompanyGoods.ReversingEntry		AS ReversingEntry,
	|	CASE
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CompanyGoods.Count
	|		ELSE CompanyGoods.Count
	|	END							AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(CompanyGoods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|		ELSE CAST(CompanyGoods.QuantityByGBRN AS NUMBER(23, 11))
	|	END							AS QuantityByGBRN
	|INTO TTName
	|FROM
	|	AccumulationRegister.CompanyGoods AS CompanyGoods
	|WHERE
	|	CompanyGoods.Recorder = &ReversedDocument
	|	AND NOT CompanyGoods.ReversingEntry";
	
	Query.Text = StrReplace(Query.Text, "TTName", TTName);
	
	Query.SetParameter("ReversedDocument", ReversedDocument);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Execute();
	
EndProcedure

Function QueryTextTransferredReturnablePackagingBalance(ThisIsTemporaryTable = True)
	
	QueryText =
	"SELECT
	|	DocumentDataTable.Organization						AS Organization,
	|	ItemsLocationAttributes.StorageLocation				AS Warehouse,
	|	ItemsLocationAttributes.DimensionKey				AS ItemsLocationAttributes,
	|	ItemsLocationAttributes.Products					AS Products,
	|	ItemsLocationAttributes.Characteristic				AS Characteristic,
	|	ItemsLocationAttributes.Series						AS Series,
	|	CASE
	|		WHEN &ThisIsGoodsReturn
	|			THEN TransferredReturnablePackaging.OriginWarehouse
	|		ELSE DocumentDataTable.Warehouse
	|	END													AS OriginWarehouse,
	|	ItemsLocationAttributes.Purpose					AS Purpose,
	|	TransferredReturnablePackaging.DocumentTransfers_				AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED											AS DocumentLoggingIn,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN UNDEFINED
	|		ELSE TransferredReturnablePackaging.InventoryOwnerAttribute
	|	END													AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TransferredReturnablePackaging.InventoryOwnerAttribute
	|	END													AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TransferredReturnablePackaging.InventoryOwnerAttribute						AS InventoryOwnerAttributeShipment,
	|	TransferredReturnablePackaging.CorInventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	TransferredReturnablePackaging.CCDNumber						AS CCDNumber,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)		AS SalesOpportunity,
	|	UNDEFINED											AS RecipientInventoryOwnerAttribute,
	|	UNDEFINED											AS DateOfReceipt,
	|	SUM(TransferredReturnablePackaging.CountBalance)		AS CountBalance,
	|	SUM(TransferredReturnablePackaging.QuantityByGBRNBalance)	AS QuantityByGBRNBalance,
	|	0														AS SumBalance
	|,&TextNameTTResult
	|FROM
	|	TransferredReturnablePackagingBalance AS TransferredReturnablePackaging
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TransferredReturnablePackaging.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|		
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS ItemsLocationAttributes
	|		ON TransferredReturnablePackaging.Products = ItemsLocationAttributes.Products
	|			AND TransferredReturnablePackaging.Characteristic = ItemsLocationAttributes.Characteristic
	|			AND TransferredReturnablePackaging.Partner = ItemsLocationAttributes.StorageLocation
	|			AND ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND ItemsLocationAttributes.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND ItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|GROUP BY
	|	DocumentDataTable.Organization,
	|	ItemsLocationAttributes.StorageLocation,
	|	ItemsLocationAttributes.DimensionKey,
	|	ItemsLocationAttributes.Products,
	|	ItemsLocationAttributes.Characteristic,
	|	ItemsLocationAttributes.Series,
	|	CASE
	|		WHEN &ThisIsGoodsReturn
	|			THEN TransferredReturnablePackaging.OriginWarehouse
	|		ELSE DocumentDataTable.Warehouse
	|	END,
	|	ItemsLocationAttributes.Purpose,
	|	TransferredReturnablePackaging.DocumentTransfers_,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN UNDEFINED
	|		ELSE TransferredReturnablePackaging.InventoryOwnerAttribute
	|	END,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TransferredReturnablePackaging.InventoryOwnerAttribute
	|	END,
	|	TransferredReturnablePackaging.InventoryOwnerAttribute,
	|	TransferredReturnablePackaging.CorInventoryOwnerAttribute,
	|	TransferredReturnablePackaging.CCDNumber
	|
	|HAVING
	|	SUM(TransferredReturnablePackaging.CountBalance) > 0";
	
	If ThisIsTemporaryTable Then
		QueryText = QueryText + "
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TransferredReturnablePackagingBalance";
	EndIf;
	
	QueryText = StrReplace(QueryText,
								",&TextNameTTResult",
								?(ThisIsTemporaryTable,
									"INTO BalanceTable",
									""));
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ExecutionOfRansomsAndTransfers

Function FieldsInHeaderForRegistrationByOrganizationSProductReserves() Export
	
	Result = New Structure;
	Result.Insert("Period");
	Result.Insert("Sender");
	Result.Insert("Recipient");
	Result.Insert("Counterparty");
	Result.Insert("StorageLocation");
	Result.Insert("StorageLocationPartner");
	Result.Insert("StorageLocationWarehouse");
	Result.Insert("StorageLocationCounterparty");
	Result.Insert("StorageLocationContract");
	Result.Insert("StorageLocationDepartment");
	Result.Insert("BusinessOperation");
	Result.Insert("VATTaxation");
	Result.Insert("Contract");
	Result.Insert("PriceKind");
	Result.Insert("Currency");
	
	Return Result;
EndFunction

// Function - text of the request for registration for the period
//
// Parameters:
//  Query					 - Query - a request with set parameters that affect the selection.
//										If the parameters are not set, they will be assigned default values.
//										Analyzed parameters:
//											* Warehouse - CatalogRef.Warehouses, CatalogRef.BusinessStructure - if it is not set, or an empty value is set, then for all warehouses.
//											* Sender - CatalogRef.Companies, CatalogRef.Partners - if it is not set, or an empty value is set, then for all senders.
//											* Recipient - CatalogRef.Companies - if not set, or an empty value is set, then for all recipients.
//											* MakeTransfers - Boolean - if not set, then FALSE is set.
//											* IssueRansoms - Boolean - if not set, then FALSE is set.
//											* BeginOfPeriod - Date - if it is not set, then the date of the first reserve for goods of organizations is taken.
//											* EndOfPeriod - Date - if not set, then the end of the current month.
//  ResultType			 - String - possible values:
//											Selections in the Folder,
//											Nomenclature sampler - the selection by nomenclature is ordered by header fields,
//											The name of the nomenclature is saved in the temporary name table, if it is simply passed to the "Name of the Nomenclature", then it is stored in the inventory of organizations
//											List of recordsreferences
//											Document Fill-in selection - superimposed selections on all fields of the header:
//																				Period,
//																				Sender,
//																				Counterparty,
//																				Recipient,
//																				Business operation,
//																				taxingendc,
//																				Transfer Activity,
//																				Contract,
//																				View prices,
//																				Currency.
//
//	NameTTProductSelections	 - String - the name W with speakers:Analyticaccounts Of Nomenclature, Types Of Reserves, Nomergtd
//											If not passed , it is selected for the entire item.
// 
// Returns:
//	String - query text.
//
Function TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query,
															ResultType = "ValueTable",
															Val NameTTProductSelections = "") Export
	
	QueryText =
	"SELECT ALLOWED
	|	NestedQuery.Period AS Period,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.QuantityByGBRN) AS QuantityByGBRN,
	|	NestedQuery.CorCompany AS CorCompany,
	|	NestedQuery.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|INTO TTReservesOfOrganizationsGoodsToRequest
	|FROM
	|	(SELECT
	|		ENDOFPERIOD(CompanySafeStock.Period, MONTH) AS Period,
	|		CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanySafeStock.Organization AS Organization,
	|		CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber AS CCDNumber,
	|		CompanySafeStock.CorCompany AS CorCompany,
	|		CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		CompanySafeStock.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		CompanySafeStock.Count AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanySafeStock.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
	|		END AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|	WHERE
	|		CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND CompanySafeStock.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (&MakeTransfers
	|					AND CompanySafeStock.Organization <> CompanySafeStock.CorCompany
	|				OR &IssueRansoms
	|					AND CompanySafeStock.Organization = CompanySafeStock.CorCompany
	|					AND CompanySafeStock.CorInventoryOwnerAttribute.InventoryType IN (&TypesOfRedemptionStocks))
	|		AND (&ForAllRecipients
	|				OR CompanySafeStock.Organization IN (&Recipient))
	|		AND (&InAllWarehouses
	|				OR CompanySafeStock.ItemsLocationAttributes.StorageLocation = &StorageLocation)
	|		AND (&ForAllSenders
	|				OR (&MakeTransfers
	|						AND CompanySafeStock.CorCompany = &Sender
	|					OR &IssueRansoms
	|						AND CompanySafeStock.CorInventoryOwnerAttribute.GoodsOwner = &Sender))
	|		AND (&ByAllProducts
	|				OR (CompanySafeStock.ItemsLocationAttributes, CompanySafeStock.CorInventoryOwnerAttribute, CompanySafeStock.CorCompany, CompanySafeStock.CCDNumber) IN
	|					(SELECT
	|						TTSelections.ItemsLocationAttributes,
	|						TTSelections.InventoryOwnerAttribute,
	|						TTSelections.Organization,
	|						TTSelections.CCDNumber
	|					FROM
	|						NameTTProductSelections AS TTSelections))
	| AND &TextOfRequestOfAssociationSVTCounterReserves
	|		) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.CorInventoryOwnerAttribute,
	|	NestedQuery.CorCompany,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.Organization,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.Period
	|
	|HAVING
	|	SUM(NestedQuery.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED &TextParameterForCheckingForRecords,
	|	ENDOFPERIOD(CompanySafeStock.Period, MONTH) AS Period,
	|	CASE
	|		WHEN CompanySafeStock.CorInventoryOwnerAttribute.InventoryType IN (
	|					VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|				AND CompanySafeStock.CorCompany = CompanySafeStock.Organization
	|			THEN CompanySafeStock.CorInventoryOwnerAttribute.GoodsOwner
	|		ELSE CompanySafeStock.CorCompany
	|	END AS Sender,
	|	CASE
	|		WHEN CompanySafeStock.CorInventoryOwnerAttribute.InventoryType IN (
	|					VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|				AND CompanySafeStock.CorCompany = CompanySafeStock.Organization
	|			THEN CompanySafeStock.CorInventoryOwnerAttribute.Counterparty
	|		ELSE UNDEFINED
	|	END AS Counterparty,
	|	CompanySafeStock.Organization AS Organization,
	|	CompanySafeStock.Organization AS Recipient,
	|	CASE
	|		WHEN CompanySafeStock.CorInventoryOwnerAttribute.InventoryType IN (
	|					VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|			THEN CompanySafeStock.Organization
	|		ELSE CompanySafeStock.CorCompany
	|	END AS CorCompany,
	|	CASE
	|		WHEN CompanySafeStock.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|		WHEN CompanySafeStock.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|				AND CompanySafeStock.CorCompany = CompanySafeStock.Organization
	|			THEN CASE
	|					WHEN CompanySafeStock.ItemsLocationAttributes.StorageType IN (VALUE(Enum.StorageLocationTypes.Warehouse), VALUE(Enum.StorageLocationTypes.Department), VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|						THEN VALUE(Enum.BusinessTransactions.RedemptionOfGoodsFromStorage)
	|					ELSE VALUE(Enum.BusinessTransactions.EmptyRef)
	|				END
	|		WHEN CompanySafeStock.CorInventoryOwnerAttribute.InventoryType IN (
	|														VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|				AND CompanySafeStock.CorCompany = CompanySafeStock.Organization
	|			THEN CASE
	|					WHEN CompanySafeStock.ItemsLocationAttributes.StorageType IN (
	|														VALUE(Enum.StorageLocationTypes.Warehouse),
	|														VALUE(Enum.StorageLocationTypes.Department),
	|														VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|						THEN VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
	|					ELSE VALUE(Enum.BusinessTransactions.EmptyRef)
	|				  END
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	END AS BusinessOperation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	CASE
	|		WHEN CompanySafeStock.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN CASE
	|					WHEN ISNULL(CompanySafeStock.InventoryOwnerAttribute.Contract, UNDEFINED) = UNDEFINED
	|						THEN ISNULL(SettingUpProductTransfers.Contract, UNDEFINED)
	|					ELSE CompanySafeStock.InventoryOwnerAttribute.Contract
	|				END
	|		WHEN CompanySafeStock.CorInventoryOwnerAttribute.InventoryType IN (
	|					VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|				AND CompanySafeStock.CorCompany = CompanySafeStock.Organization
	|			THEN ISNULL(CompanySafeStock.CorInventoryOwnerAttribute.Contract, UNDEFINED)
	|		ELSE CASE
	|				WHEN ISNULL(SettingUpProductTransfers.GoodsTransferMethod, UNDEFINED) = VALUE(Enum.GoodsTransferMethods.Sale)
	|					THEN SettingUpProductTransfers.Contract
	|				ELSE CompanySafeStock.InventoryOwnerAttribute.Contract
	|			END
	|	END AS Contract,
	|	CASE
	|		WHEN CompanySafeStock.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN CASE
	|					WHEN CompanySafeStock.CorCompany = CompanySafeStock.Organization
	|						THEN CompanySafeStock.CorInventoryOwnerAttribute.PriceKind
	|					WHEN ISNULL(SettingUpProductTransfers.GoodsTransferMethod, UNDEFINED) = VALUE(Enum.GoodsTransferMethods.Sale)
	|						THEN SettingUpProductTransfers.PriceKind
	|					ELSE &DefaultPriceType
	|				END
	|		WHEN ISNULL(SettingUpProductTransfers.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN &DefaultPriceType
	|		ELSE SettingUpProductTransfers.PriceKind
	|	END AS PriceKind,
	|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanySafeStock.ItemsLocationAttributes.StorageLocation AS StorageLocation,
	|	CompanySafeStock.ItemsLocationAttributes.Partner AS StorageLocationPartner,
	|	CompanySafeStock.ItemsLocationAttributes.WarehouseArea AS StorageLocationWarehouse,
	|	CompanySafeStock.ItemsLocationAttributes.Department AS StorageLocationDepartment,
	|	CompanySafeStock.ItemsLocationAttributes.Counterparty AS StorageLocationCounterparty,
	|	CompanySafeStock.ItemsLocationAttributes.Contract AS StorageLocationContract,
	|	CompanySafeStock.ItemsLocationAttributes.Products AS Products,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
	|	CompanySafeStock.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CompanySafeStock.ItemsLocationAttributes.Series AS Series,
	|	CompanySafeStock.ItemsLocationAttributes.Purpose AS Purpose,
	|	CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanySafeStock.InventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	CompanySafeStock.CorInventoryOwnerAttribute AS SenderSInventoryType,
	|	CASE
	|		WHEN CompanySafeStock.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN CompanySafeStock.InventoryOwnerAttribute.Currency
	|		WHEN CompanySafeStock.CorInventoryOwnerAttribute.InventoryType IN (
	|					VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|				AND CompanySafeStock.CorCompany = CompanySafeStock.Organization
	|			THEN CompanySafeStock.CorInventoryOwnerAttribute.Currency
	|		WHEN ISNULL(SettingUpProductTransfers.GoodsTransferMethod, UNDEFINED) = VALUE(Enum.GoodsTransferMethods.Sale)
	|				AND ISNULL(SettingUpProductTransfers.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN SettingUpProductTransfers.PriceKind.PriceCurrency
	|		WHEN &DefaultPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN CAST(&DefaultPriceType AS Catalog.TypesOfPrices).PriceCurrency
	|		ELSE CompanySafeStock.Organization.LocalAccountingCurrency
	|	END AS Currency,
	|	CompanySafeStock.CCDNumber AS CCDNumber,
	|	CompanySafeStock.Count AS Count,
	|	CompanySafeStock.QuantityByGBRN AS QuantityByGBRN
	|,&TextNameTTResult
	|FROM
	|	TTReservesOfOrganizationsGoodsToRequest AS CompanySafeStock
	|		LEFT JOIN InformationRegister.CustomizeCustomerInvoiceIntercompany AS SettingUpProductTransfers
	|		ON CompanySafeStock.Organization = SettingUpProductTransfers.CompanyCustomer
	|			AND CompanySafeStock.CorCompany = SettingUpProductTransfers.CompanyOwner
	|			AND CompanySafeStock.CorInventoryOwnerAttribute.InventoryType = SettingUpProductTransfers.InventoryType
	|			AND &TextOfHeaderOrderingField
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&EndOfPeriod) AS ProductsVATRates
	|		ON CompanySafeStock.ItemsLocationAttributes.Products = ProductsVATRates.Products
	|			AND CompanySafeStock.Organization.RegistrationCountry = ProductsVATRates.Country
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&EndOfPeriod) AS BasicVATRates
	|		ON CompanySafeStock.Organization.RegistrationCountry = BasicVATRates.Country";
	
	TextOfCounterReserves = TextOfCounterReserveRequest("SampleIsNotOrdered", NameTTProductSelections, True);
	
	QueryText = StrReplace(QueryText,"AND &TextOfRequestOfAssociationSVTCounterReserves",
		TMCommonUse.QuerySeparatorInJoin() + TextOfCounterReserves);
	
	If Not Query.Parameters.Property("BeginOfPeriod")
		Or Not ValueIsFilled(Query.Parameters.BeginOfPeriod) Then
		
		Query.SetParameter("BeginOfPeriod", BegOfMonth(DateOfFirstReserve(CurrentSessionDate())));
		
	EndIf;
	
	If Not Query.Parameters.Property("EndOfPeriod")
		Or Not ValueIsFilled(Query.Parameters.EndOfPeriod) Then
		
		Query.SetParameter("EndOfPeriod", EndOfMonth(CurrentSessionDate()));
		
	EndIf;
	
	If IsBlankString(NameTTProductSelections) Then
		TextTTProductSelections =
		"SELECT
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
		|INTO TTProductSelectionsForReserves
		|WHERE
		|	FALSE";
		
		QueryText = TextTTProductSelections + Common.QueryBatchSeparator() + QueryText;
		QueryText = StrReplace(QueryText, "NameTTProductSelections", "TTProductSelectionsForReserves");
		
		Query.SetParameter("ByAllProducts", True);
	Else
		Query.SetParameter("ByAllProducts", False);
		
		QueryText = StrReplace(QueryText, "NameTTProductSelections", NameTTProductSelections);
	EndIf;
	
	If Not Query.Parameters.Property("MakeTransfers") Then
		Query.SetParameter("MakeTransfers", False);
	EndIf;
	
	If Not Query.Parameters.Property("IssueRansoms") Then
		Query.SetParameter("IssueRansoms", False);
	EndIf;
	
	If Not Query.Parameters.Property("StorageLocation") Then
		Query.SetParameter("StorageLocation", Undefined);
	EndIf;
	
	Query.SetParameter("InAllWarehouses", Not ValueIsFilled(Query.Parameters.StorageLocation));
	
	If Not Query.Parameters.Property("Sender") Then
		Query.SetParameter("Sender", Undefined);
	EndIf;
	
	Query.SetParameter("ForAllSenders", Not ValueIsFilled(Query.Parameters.Sender));
	
	If Not Query.Parameters.Property("Recipient") Then
		Query.SetParameter("Recipient", New Array);
		Query.SetParameter("ForAllRecipients", True);
	ElsIf TypeOf(Query.Parameters.Recipient) = Type("Array") Then	
		Query.SetParameter("Recipient", Query.Parameters.Recipient);
		Query.SetParameter("ForAllRecipients", Query.Parameters.Recipient.Count() = 0);
	Else
		
		If ValueIsFilled(Query.Parameters.Recipient) Then
			ArrayParameter = New Array;
			ArrayParameter.Add(Query.Parameters.Recipient);
			
			Query.SetParameter("Recipient", ArrayParameter);
			Query.SetParameter("ForAllRecipients", False);
		Else
			Query.SetParameter("Recipient", New Array);
			Query.SetParameter("ForAllRecipients", True);
		EndIf;
		
	EndIf;
	
	Query.SetParameter("DefaultPriceType",
								Catalogs.TypesOfPrices.DefaultPriceType(
									Catalogs.TypesOfPrices.EmptyRef(),
									New Structure("UseForIntercompanySales", True)));
	
	If Not Query.Parameters.Property("TypesOfRedemptionStocks")
	 Or Not ValueIsFilled(Query.Parameters.TypesOfRedemptionStocks) Then
		
		TypesOfRedemptionStocks = New Array;
		TypesOfRedemptionStocks.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
		If GetFunctionalOption("UseTollManufacturing2_5") Then
			TypesOfRedemptionStocks.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
			TypesOfRedemptionStocks.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
			TypesOfRedemptionStocks.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
		EndIf;
		Query.SetParameter("TypesOfRedemptionStocks", TypesOfRedemptionStocks);
		
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	If Upper(ResultType) = Upper("SelectionByHeader") Then
		
		TextNameTTResult  = "TTReservesOfGoodsOfOrganizations";
		QueryText = StrReplace(QueryText, ",&TextNameTTResult", "INTO " + TextNameTTResult);
		
		SelectionArray = New Array;
		
		HeaderFields = FieldsInHeaderForRegistrationByOrganizationSProductReserves();
		
		For Each KeyValue In HeaderFields Do
			FieldText = "CompanySafeStock." + KeyValue.Key + " AS " + KeyValue.Key;
			
			SelectionArray.Add(FieldText);
		EndDo;
		
		FieldSelectionText = StrConcat(SelectionArray, ",");
		
		SelectionText = "
		|SELECT DISTINCT
		|	&FieldSelectionText
		|FROM
		|	TTReservesOfGoodsOfOrganizations AS CompanySafeStock";
		
		SelectionText = StrReplace(SelectionText, "&FieldSelectionText", FieldSelectionText);
		
		QueryText = QueryText + Common.QueryBatchSeparator() + SelectionText;
		
	ElsIf Upper(ResultType) = Upper("SelectionByProductType_") Then
		
		SelectionArray = New Array;
		
		HeaderFields = FieldsInHeaderForRegistrationByOrganizationSProductReserves();
		
		For Each KeyValue In HeaderFields Do
			FieldText = KeyValue.Key;
			
			SelectionArray.Add(FieldText);
		EndDo;
		
		TextOfHeaderOrderingField = "
		|
		|ORDER BY "
		+ StrConcat(SelectionArray, ",");
		
		QueryText = StrReplace(QueryText, "AND &TextOfHeaderOrderingField", TextOfHeaderOrderingField);
		
	ElsIf Upper(ResultType) = Upper("TTByProductRange") Then
		
		TextNameTTResult = "TTReservesOfGoodsOfOrganizations";
		
		QueryText = StrReplace(QueryText, ",&TextNameTTResult", "INTO " + TextNameTTResult);
		
	ElsIf Upper(ResultType) = Upper("VTKRegistrationOfRepurchases")
		Or Upper(ResultType) = Upper("VTKRegistrationOfTransfers") Then
		
		QueryText = StrReplace(QueryText, ",&TextNameTTResult", "INTO " + ResultType);
		
	ElsIf Upper(ResultType) = Upper("SamplingPresenceOfRecords") Then
		
		QueryText = StrReplace(QueryText, "&TextParameterForCheckingForRecords,", "TOP 1");
		
	ElsIf Upper(ResultType) = Upper("SelectingDocumentContent") Then
		
		TextNameTTResult  = "TTReservesOfGoodsOfOrganizations";
		QueryText = StrReplace(QueryText, ",&TextNameTTResult", "INTO " + TextNameTTResult);
		
		SelectionText = 
		"SELECT
		|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStock.Products AS Products,
		|	CompanySafeStock.Characteristic AS Characteristic,
		|	CompanySafeStock.Series AS Series,
		|	CompanySafeStock.Purpose AS Purpose,
		|	CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	CompanySafeStock.VATRate AS VATRate,
		|	CompanySafeStock.Count AS Count,
		|	CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
		|	CompanySafeStock.Count AS NumberOfPackages,
		|	CompanySafeStock.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
		|	CompanySafeStock.SenderSInventoryType AS SenderSInventoryType,
		|	CompanySafeStock.CCDNumber AS CCDNumber
		|FROM
		|	TTReservesOfGoodsOfOrganizations AS CompanySafeStock
		|WHERE
		|	&TextOfSelectionCriteriaForHeader";
		
		ArrayOfSelectionConditions = New Array;
		
		HeaderFields = FieldsInHeaderForRegistrationByOrganizationSProductReserves();
		
		For Each KeyValue In HeaderFields Do
			
			If Query.Parameters.Property(KeyValue.Key)
				And TypeOf(Query.Parameters[KeyValue.Key]) = Type("Array") Then
				
				FieldText = "CompanySafeStock." + KeyValue.Key + " IN  (&" + KeyValue.Key + ")";
				
			Else
				FieldText = "CompanySafeStock." + KeyValue.Key + " =  &" + KeyValue.Key;
			EndIf;
			
			ArrayOfSelectionConditions.Add(FieldText);
			
		EndDo;
		
		TextOfSelectionCriteriaForHeader = StrConcat(ArrayOfSelectionConditions,
		"
		| AND ");
		
		SelectionText = StrReplace(SelectionText, "&TextOfSelectionCriteriaForHeader", TextOfSelectionCriteriaForHeader);
		
		QueryText = QueryText
			+ Common.QueryBatchSeparator()
			+ SelectionText;	
		
	Else
		ExceptionText = NStr("vi = 'Kiểu kết quả không xác định.';
							|ru = 'Неизвестный тип результата.';
							|en = 'Unknown result type.'; fa = 'Unknown result type.';
							|it = 'Tipo di risultato sconosciuto.';
							|pl = 'Nieznany typ wyniku.';
							|tr = 'Bilinmeyen sonuç tipi.'");
		
		Raise ExceptionText;
	EndIf;
	
	QueryText = StrReplace(QueryText, ",&TextNameTTResult", "");
	QueryText = StrReplace(QueryText, "AND &TextOfHeaderOrderingField", "");
	QueryText = StrReplace(QueryText, "&TextParameterForCheckingForRecords,", "");
	
	
	Return QueryText;
EndFunction

// Text of the request for counter reserves
//
// Parameters:
//  ResultType		 - String - possible values:
//											The sample is ordered,
//											Fetchingordered organizations,
//											Vtanalytikivstrechnykh reserve - saved in the temporary table Vtanalytikivstrechnykh reserve.
//  NameTTAnalyticsSelections - String - name of the DEPARTMENT with columns: analyticaccounts of Nomenclature, type of Inventory, Nomergtd, Organization
//											If not passed , it is selected for all analysts.
//  NeedSelectionByPeriod	 - Boolean - True, a sign that you need to take into account the selection by period when generating data 
//  								on counter reserves.
//
// Returns:
//  String - Query text
//
Function TextOfCounterReserveRequest(ResultType, NameTTAnalyticsSelections = "", NeedSelectionByPeriod = False) Export
	
	TextOfCounterReserveRequest =
	"SELECT
	|	ENDOFPERIOD(CompanySafeStock.Period, MONTH) AS Period,
	|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanySafeStock.Organization AS Organization,
	|	CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber AS CCDNumber,
	|	CompanySafeStock.CorCompany AS CorCompany,
	|	CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TRUE AS ThisIsReverseTransaction,
	|	-SUM(CASE
	|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CompanySafeStock.Count
	|			ELSE 0
	|		END) AS Count,
	|	-SUM(CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanySafeStock.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
	|			ELSE 0
	|		END) AS QuantityByGBRN
	|,&TextOfIWTPremises
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|WHERE
	|	&ConditionTextByPeriod
	|	AND &TextOfConditionForProducts
	|GROUP BY
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.Organization,
	|	CompanySafeStock.InventoryOwnerAttribute,
	|	CompanySafeStock.CorInventoryOwnerAttribute,
	|	CompanySafeStock.CorCompany,
	|	ENDOFPERIOD(CompanySafeStock.Period, MONTH),
	|	CompanySafeStock.CCDNumber
	|
	|HAVING
	|	SUM(CASE
	|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CompanySafeStock.Count
	|			ELSE 0
	|		END) >= SUM(CASE
	|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CompanySafeStock.Count
	|			ELSE 0
	|		END) AND
	|	SUM(CASE
	|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CompanySafeStock.Count
	|			ELSE 0
	|		END) > 0
	|ORDER BY &OrderingTextByOrganization";
	
	If Not IsBlankString(NameTTAnalyticsSelections) Then
		TextOfConditionForProducts = "
		|	(CompanySafeStock.ItemsLocationAttributes, CompanySafeStock.Organization, CompanySafeStock.InventoryOwnerAttribute, CompanySafeStock.CCDNumber)
		|	IN (SELECT
		|			TTCounterReserveAnalysts.ItemsLocationAttributes,
		|			TTCounterReserveAnalysts.Organization,
		|			TTCounterReserveAnalysts.InventoryOwnerAttribute,
		|			TTCounterReserveAnalysts.CCDNumber
		|		FROM
		|			TTCounterReserveAnalysts AS TTCounterReserveAnalysts)";
		
		TextOfConditionForProducts = StrReplace(TextOfConditionForProducts,
												"TTCounterReserveAnalysts",
												NameTTAnalyticsSelections);
		
		TextOfCounterReserveRequest = StrReplace(TextOfCounterReserveRequest,
													"&TextOfConditionForProducts",
													TextOfConditionForProducts);
	Else
		TextOfCounterReserveRequest = StrReplace(TextOfCounterReserveRequest,
													"&TextOfConditionForProducts",
													"TRUE");
	EndIf;
	
	If NeedSelectionByPeriod Then
		TextOfCounterReserveRequest = StrReplace(TextOfCounterReserveRequest,
													"&ConditionTextByPeriod",
													"CompanySafeStock.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod");
	Else
		TextOfCounterReserveRequest = StrReplace(TextOfCounterReserveRequest,
													"&ConditionTextByPeriod",
													"TRUE");
	EndIf;
	
	If ResultType = "SelectionOrderedByOrganization" Then
		
		OrderingText = "
		|ORDER BY
		|	CompanySafeStock.Organization";
		
		TextOfCounterReserveRequest = StrReplace(TextOfCounterReserveRequest, "ORDER BY &OrderingTextByOrganization", OrderingText);	
	ElsIf ResultType = "TTCounterReserveAnalysts" Then
		
		TextOfCounterReserveRequest = StrReplace(TextOfCounterReserveRequest, ",&TextOfIWTPremises", "INTO TTCounterReserveAnalysts");
	ElsIf ResultType <> "SampleIsNotOrdered" Then
		ExceptionText = NStr("vi = 'Loại kết quả không xác định.';
							|ru = 'Неизвестный тип результата.';
							|en = 'Unknown result type.'; fa = 'Unknown result type.';
							|it = 'Tipo di risultato sconosciuto.';
							|pl = 'Nieznany typ wyniku.';
							|tr = 'Bilinmeyen sonuç tipi.'");
		
		Raise ExceptionText;
	EndIf;

	TextOfCounterReserveRequest = StrReplace(TextOfCounterReserveRequest, ",&TextOfIWTPremises", "");
	TextOfCounterReserveRequest = StrReplace(TextOfCounterReserveRequest, "ORDER BY &OrderingTextByOrganization", "");

	
	Return TextOfCounterReserveRequest;
	
EndFunction

#EndRegion

#Region UserInterface

// Returns the text of the request to verify changes in the data of the tabular part of the document's 'Views' performed manually.
//
// Parameters:
//	TableTypesOfStocks_ - ValueTable - data of the tabular part of the document inventory types.
//
Function TextOfRequestToCheckChangesInInventoryTypesManually(TableTypesOfStocks_)
	
	QueryText =
	"SELECT
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	&DimensionFields,
	|	&ResourceFields,
	|	InventoryKinds.Count
	|INTO TypesOfDocumentStocks
	|FROM
	|	&TypesOfDocumentStocks AS InventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	&DimensionFields,
	|	&ResourceFields,
	|	InventoryKinds.Count
	|INTO TypesOfStocksSpecifiedManually
	|FROM
	|	&TypesOfStocksSpecifiedManually AS InventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		InventoryKinds.ItemsLocationAttributes,
	|		InventoryKinds.InventoryOwnerAttribute,
	|		&DimensionFields,
	|		&ResourceFields,
	|		InventoryKinds.Count
	|	FROM
	|		TypesOfDocumentStocks AS InventoryKinds
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InventoryKinds.ItemsLocationAttributes,
	|		InventoryKinds.InventoryOwnerAttribute,
	|		&DimensionFields,
	|		-&FieldsOfSubtractedResources,
	|		-InventoryKinds.Count
	|	FROM
	|		TypesOfStocksSpecifiedManually AS InventoryKinds
	|	
	|	) AS InventoryKinds
	|
	|GROUP BY
	|	InventoryKinds.ItemsLocationAttributes,
	|	&DimensionFields,
	|	InventoryKinds.InventoryOwnerAttribute
	|
	|HAVING
	|	SUM(InventoryKinds.Count) <> 0
	|	OR &SelectionCondition";
	
	SelectionFieldNames	= New Array;
	DimensionFieldNames	= MeasurementsOfEditableStockTypes();
	ResourceFieldNames	= ResourcesForEditableInventoryTypes();
	
	CommonClientServer.SupplementArray(SelectionFieldNames, DimensionFieldNames);
	CommonClientServer.SupplementArray(SelectionFieldNames, ResourceFieldNames);
	
	TableName = "InventoryKinds";
	
	DimensionFields	= New Array;
	ResourceFields	= New Array;
	SelectionConditions_	= New Array;
	
	For Each FieldName In SelectionFieldNames Do
		If TableTypesOfStocks_.Columns.Find(FieldName) <> Undefined Then
			If DimensionFieldNames.Find(FieldName) <> Undefined Then
				MeasurementField = TableName + "." + FieldName;
				DimensionFields.Add(MeasurementField);
			Else
				ResourceField = TableName + "." + FieldName;
				ResourceFields.Add(ResourceField);
				
				SelectionCondition = "SUM(" + TableName + "." + FieldName  + ") <> 0";
				SelectionConditions_.Add(SelectionCondition);
			EndIf;
		EndIf;
	EndDo;
	
	FieldSeparator = ",
						|	";
	SeparatorForSubtractedResources = ",
									|	-";
	SelectionConditionSeparator = "
								|	OR" + " ";
	
	QueryTextDimensionFields			= StrConcat(DimensionFields, FieldSeparator);
	QueryTextResourceFields			= StrConcat(ResourceFields, FieldSeparator);
	QueryTextFieldsOfSubtractedResources	= StrConcat(ResourceFields, SeparatorForSubtractedResources);
	QueryTextSelectionConditions_			= StrConcat(SelectionConditions_, SelectionConditionSeparator);
	
	QueryText = StrReplace(QueryText,
								"&DimensionFields,",
								?(ValueIsFilled(QueryTextDimensionFields),
								QueryTextDimensionFields + ",",
								""));
	QueryText = StrReplace(QueryText,
								"&ResourceFields,",
								?(ValueIsFilled(QueryTextResourceFields),
								QueryTextResourceFields + ",",
								""));
	QueryText = StrReplace(QueryText,
								"&FieldsOfSubtractedResources,",
								?(ValueIsFilled(QueryTextFieldsOfSubtractedResources),
								QueryTextFieldsOfSubtractedResources + ",",
								""));
	QueryText = StrReplace(QueryText,
								"&SelectionCondition",
								?(ValueIsFilled(QueryTextSelectionConditions_),
								QueryTextSelectionConditions_,
								"FALSE"));
	
	Return QueryText;
	
EndFunction

Function MeasurementsOfEditableStockTypes()
	
	DimensionFieldNames = New Array;
	DimensionFieldNames.Add("CCDNumber");
	DimensionFieldNames.Add("VATRate");
	DimensionFieldNames.Add("Warehouse");
	DimensionFieldNames.Add("OriginWarehouse");
	DimensionFieldNames.Add("DocumentSalesOfGoodsAndServices");
	DimensionFieldNames.Add("CostDefiningMethod");
	
	Return DimensionFieldNames;
	
EndFunction

Function ResourcesForEditableInventoryTypes()
	
	ResourceFieldNames = New Array;
	ResourceFieldNames.Add("QuantityByGBRN");
	ResourceFieldNames.Add("VATAmount");
	ResourceFieldNames.Add("AmountIncludingVAT");
	
	Return ResourceFieldNames;
	
EndFunction

#EndRegion

#EndRegion
