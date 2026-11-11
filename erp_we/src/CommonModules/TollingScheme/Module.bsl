////////////////////////////////////////////////////////////////
// The "Tolling System" module contains procedures and functions for 
// working with the mechanism of production from tolling raw materials.
//
////////////////////////////////////////////////////////////////
//

#Region Public

#Region HandlersForMonthClosingStages


#Region CheckingBalancesForMakingReportsToGiver

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
//
Procedure AddStage_BalancesForReportingToGivers(StepsTable,CurrentParent) Export
	
	NewRow =  MonthEndTransactionsServer.AddStageToTable(
		StepsTable,
		CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterReportsToProviders);
	
	NewRow.MultilingualName = "vi = 'Lập bảng kê hàng hóa cho bên nhận gia công';
								|ru = 'Оформление отчетов давальцам';
								|en = 'Register Consumption reports — Subcontracting services delivered';
								|it = 'Formalizzazione dei report ai fornitori';
								|pl = 'Tworzenie raportów do właścicieli surowców';
								|tr = 'Tedarikçi için tüketim raporlarının düzenlenmesi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.ActionDesign =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"TollingScheme.Registration_BalancesForRegistrationOfReportsToGivers");
	NewRow.ActionUse =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"TollingScheme.Using_BalancesForReportingToGivers");
	
	NewRow.ActionExecute  =  MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.DocumentsOfReceiptForTollingAll2_5.Forms.ToRegisterInvoices.FullName(), True);
	NewRow.ActionExecute.FormParameters.Insert("CurrentPageName", "ReportsPage");
	
EndProcedure

// Stage handlers
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Using_BalancesForReportingToGivers(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	StockBalance.Organization                AS Organization,
	|	StockBalance.ItemsLocationAttributes AS Dimension,
	|	-StockBalance.CountBalance         AS Balance
	|INTO BalancesForReportingToGivers
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(&BorderEndOfPeriod, Organization IN (&CompanyArray)) AS StockBalance
	|
	|WHERE
	|	StockBalance.CountBalance < 0
	|	AND StockBalance.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|	AND ISNULL(StockBalance.InventoryOwnerAttribute.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|		VALUE(Enum.ContractTypes.ReceiptForTolling2_5)
	|	AND NOT ISNULL(StockBalance.ItemsLocationAttributes.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|		VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|";
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.BalancesForReportingToGivers = 0 Then
	
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư để lập báo cáo cho người đặt gia công.';
				|ru = 'Нет остатков к оформлению отчетов давальцам.';
				|en = 'There are no remaining goods to register ""Consumption reports — Subcontracting services delivered"".'; fa = 'There are no remaining goods to register ""Consumption reports — Subcontracting services delivered"".';
				|it = 'Non ci sono saldi in formalizzazione dei report ai fornitori.';
				|pl = 'Brak zapasów do generowania raportów właścicielom surowców.';
				|tr = 'Tedarikçiye bildirilecek herhangi bir bakiye yoktur.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// Forms out the closing stage of the month.
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Registration_BalancesForRegistrationOfReportsToGivers(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Lập chứng từ';
													|ru = 'Оформить';
													|en = 'Register'; fa = 'ثبات';
													|it = 'Formalizzare';
													|pl = 'Register';
													|tr = 'Düzenle'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// System health checks related to the stage.
// 
// Parameters:
// 	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable
//
Procedure DescriptionOfChecks_BalancesForMakingReportsToGivers(TableOfChecks) Export
	
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(
		TableOfChecks,
		"RegisterReportsToProviders",
		Catalogs.MonthEndClosingOperations.RegisterReportsToProviders,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"TollingScheme.CheckingBalancesForMakingReportsToGivers");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chưa tạo báo cáo cho người đặt gia công.';
			|ru = 'Не оформлены отчеты давальцам.';
			|en = '""Consumption reports — Subcontracting services delivered"" are not registered.'; fa = '""Consumption reports — Subcontracting services delivered"" are not registered.';
			|it = 'Non sono formalizzati i report ai fornitori.';
			|pl = 'Nie utworzono raportów właścicielom surowców.';
			|tr = 'Tüketim raporları - Verilen fason hizmetleri hazırlanmamıştır.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đối với tất cả sản phẩm đã cho chuyển cho người đặt gia công, cần tạo bảng kê cho người đặt gia công.';
			|ru = 'На все переданные давальцу изделия должны быть оформлены отчеты давальцу.';
			|en = 'For all finished products transferred to the provider, register ""Consumption reports — Subcontracting services delivered"".'; fa = 'For all finished products transferred to the provider, register ""Consumption reports — Subcontracting services delivered"".';
			|it = 'In tutta la produzione trasferita al fornitore devono essere formalizzati i report al fornitore.';
			|pl = 'Na wszystkie przekazane właścicielowi surowców wyroby należy wygenerować raporty właścicielom surowców.';
			|tr = 'Sağlayıcıya teslim edilen tüm üretilen ürünler için Tüketim raporları - Verilen fason hizmetleri düzenlenmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

// Error logging.
// 
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure CheckingBalancesForMakingReportsToGivers(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Dimension",   NStr("vi = 'Đối tượng phân tích';
										|ru = 'Аналитика';
										|en = 'Dimension'; fa = 'بُعد';
										|it = 'Analitica';
										|pl = 'Dimension';
										|tr = 'Boyut'",   Common.DefaultLanguageCode()));
	FieldList.Add("Balance",     NStr("vi = 'Số dư';
										|ru = 'Остаток';
										|en = 'Remaining stock'; fa = 'موجودی باقیمانده';
										|it = 'Saldo';
										|pl = 'Remaining stock';
										|tr = 'Bakiye'",     Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"BalancesForReportingToGivers",
		NStr("vi = 'Đã phát hiện số dư cần lập bảng kê cho người đặt gia công theo doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены остатки к оформлению отчетов давальцам по организации ""%1"" на конец периода %2';
			|en = 'There is remaining stock to register consumption reports for the ""%1"" company at the end of the period %2'; fa = 'There is remaining stock to register consumption reports for the ""%1"" company at the end of the period %2';
			|it = 'Sono stato rilevati saldi in formalizzazione dei report ai fornitori per l''azienda ""%1"" nella fine del periodo %2';
			|pl = 'Wykryto zapasy do wygenerowania raportów właścicielom surowców według firmy ""%1"" na koniec okresu %2';
			|tr = '%2 dönemi sonunda ""%1"" iş yeri için tedarikçilere raporlanacak bakiyeler tespit edildi'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#EndRegion

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
		
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		DocumentType = TypeOf(Document);
		
		
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
	
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the register.
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

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	
EndProcedure


#EndRegion


#Region Checks


// Checks the correctness of the choice of the assignment of givers in documents with the tabular parts
// "Output products", "Side products" and "Work materials".
// 
// Parameters:
//  Object            - DocumentObject.SubcontractOrder2_5, DocumentObject.SubcontractorReport2_5, DocumentObject.BackflushProduction - The document being checked.
//  CheckParameters - See ParametersForCheckingSelectionOfGiverSDestination
//  Cancel             - Boolean - verification flag.
//
Procedure CheckCorrectnessOfChoiceOfGiverSAppointment(Object, CheckParameters, Cancel) Export
	
	QueryText =
	"SELECT
	|	&TableNameOutputProducts        AS TableName,
	|	&SynonymOfOutputProductsTable    AS TableSynonym,
	|	ManufacturedProducts.LineNumber       AS LineNumber,
	|	ManufacturedProducts.CostGroupNumber AS CostGroupNumber,
	|	ManufacturedProducts.Purpose        AS Purpose
	|INTO ManufacturedProducts
	|FROM
	|	&ManufacturedProducts AS ManufacturedProducts
	|
	|INDEX BY
	|	Purpose,
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&NameOfByProductTable        AS TableName,
	|	&SynonymOfByProductsTable    AS TableSynonym,
	|	SideAndIntermediateRelease.LineNumber       AS LineNumber,
	|	SideAndIntermediateRelease.CostGroupNumber AS CostGroupNumber,
	|	SideAndIntermediateRelease.Purpose        AS Purpose
	|INTO SideAndIntermediateRelease
	|FROM
	|	&SideAndIntermediateRelease AS SideAndIntermediateRelease
	|
	|INDEX BY
	|	Purpose,
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&NameOfMaterialsAndWorksTable        AS TableName,
	|	&SynonymForMaterialsAndWorksTable    AS TableSynonym,
	|	MaterialsAndWorks.LineNumber       AS LineNumber,
	|	MaterialsAndWorks.CostGroupNumber AS CostGroupNumber,
	|	MaterialsAndWorks.Purpose        AS Purpose
	|INTO MaterialsAndWorks
	|FROM
	|	&MaterialsAndWorks AS MaterialsAndWorks
	|
	|INDEX BY
	|	Purpose,
	|	CostGroupNumber
	|";
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryText);
	
	If CheckParameters.TollBasedCostGroupings.Find(Object.GroupCosts) <> Undefined Then
		
		QueryText =
		"SELECT
		|	SideAndIntermediateRelease.TableName     AS TableName,
		|	SideAndIntermediateRelease.TableSynonym AS TableSynonym,
		|	SideAndIntermediateRelease.LineNumber    AS LineNumber
		|FROM
		|	SideAndIntermediateRelease AS SideAndIntermediateRelease
		|		LEFT JOIN Catalog.Assignments AS AppointmentsByProducts
		|		ON SideAndIntermediateRelease.Purpose = AppointmentsByProducts.Ref
		|WHERE
		|	AppointmentsByProducts.AssignmentType IN (&GiveawayTypesOfAppointments)
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			ManufacturedProducts AS ManufacturedProducts
		|				LEFT JOIN Catalog.Assignments AS DestinationOutputProducts
		|				ON ManufacturedProducts.Purpose = DestinationOutputProducts.Ref
		|		WHERE
		|			ManufacturedProducts.CostGroupNumber = SideAndIntermediateRelease.CostGroupNumber
		|			AND ISNULL(DestinationOutputProducts.Partner, VALUE(Catalog.Partners.EmptyRef)) <>
		|																			AppointmentsByProducts.Partner)
		|
		|UNION ALL
		|
		|SELECT
		|	MaterialsAndWorks.TableName     AS TableName,
		|	MaterialsAndWorks.TableSynonym AS TableSynonym,
		|	MaterialsAndWorks.LineNumber    AS LineNumber
		|FROM
		|	MaterialsAndWorks AS MaterialsAndWorks
		|		LEFT JOIN Catalog.Assignments AS AssignmentsMaterialsAndWorks
		|		ON MaterialsAndWorks.Purpose = AssignmentsMaterialsAndWorks.Ref
		|WHERE
		|	AssignmentsMaterialsAndWorks.AssignmentType IN (&GiveawayTypesOfAppointments)
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			ManufacturedProducts AS ManufacturedProducts
		|				LEFT JOIN Catalog.Assignments AS DestinationOutputProducts
		|				ON ManufacturedProducts.Purpose = DestinationOutputProducts.Ref
		|		WHERE
		|			ManufacturedProducts.CostGroupNumber = MaterialsAndWorks.CostGroupNumber
		|			AND ISNULL(DestinationOutputProducts.Partner, VALUE(Catalog.Partners.EmptyRef)) <>
		|																			AssignmentsMaterialsAndWorks.Partner)
		|";
		
		MessageText =
			NStr("vi = 'Trong dòng %1 của danh sách ""%2"", chỉ ra sai gom nhóm chi phí.
					   |Cần đưa nguyên vật liệu của người đặt gia công vào giá thành sản phẩm của chính người gia công.';
					   |ru = 'В строке %1 списка ""%2"" неправильно указана группа затрат.
					   |Материалы давальца должны быть включены в себестоимость продукции того же давальца.';
					   |en = 'In line %1 of the ""%2"" list, cost group is specified incorrectly.
					   |Provider materials must be included in the manufactured product cost of the same provider.'; fa = 'In line %1 of the ""%2"" list, cost group is specified incorrectly.
					   |Provider materials must be included in the manufactured product cost of the same provider.';
					   |it = 'В строке %1 списка ""%2"" неправильно указана группа затрат.
					   |Материалы давальца должны быть включены в себестоимость продукции того же давальца.';
					   |pl = 'In line %1 of the ""%2"" list, cost group is specified incorrectly.
					   |Provider materials must be included in the manufactured product cost of the same provider.';
					   |tr = 'В строке %1 списка ""%2"" неправильно указана группа затрат.
					   |Материалы давальца должны быть включены в себестоимость продукции того же давальца.'");
		
	Else
		
		QueryText =
		"SELECT
		|	ManufacturedProducts.TableName     AS TableName,
		|	ManufacturedProducts.TableSynonym AS TableSynonym,
		|	ManufacturedProducts.LineNumber    AS LineNumber
		|FROM
		|	ManufacturedProducts AS ManufacturedProducts
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON ManufacturedProducts.Purpose = Assignments.Ref
		|WHERE
		|	Assignments.AssignmentType IN (&GiveawayTypesOfAppointments)
		|
		|UNION ALL
		|
		|SELECT
		|	SideAndIntermediateRelease.TableName     AS TableName,
		|	SideAndIntermediateRelease.TableSynonym AS TableSynonym,
		|	SideAndIntermediateRelease.LineNumber    AS LineNumber
		|FROM
		|	SideAndIntermediateRelease AS SideAndIntermediateRelease
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON SideAndIntermediateRelease.Purpose = Assignments.Ref
		|WHERE
		|	Assignments.AssignmentType IN (&GiveawayTypesOfAppointments)
		|
		|UNION ALL
		|
		|SELECT
		|	MaterialsAndWorks.TableName     AS TableName,
		|	MaterialsAndWorks.TableSynonym AS TableSynonym,
		|	MaterialsAndWorks.LineNumber    AS LineNumber
		|FROM
		|	MaterialsAndWorks AS MaterialsAndWorks
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON MaterialsAndWorks.Purpose = Assignments.Ref
		|WHERE
		|	Assignments.AssignmentType IN (&GiveawayTypesOfAppointments)
		|";
		
		MessageText =
			NStr("vi = 'Trong dòng %1 của danh sách ""%2"" đã chọn mục đích gia công.
					   |Có thể chọn mục đích gia công chỉ khi gom nhóm chi phí theo mục đích.';
					   |ru = 'В строке %1 списка ""%2"" выбрано давальческое назначение.
					   |Давальческое назначение может быть выбрано только при группировке затрат по назначениям.';
					   |en = 'In line %1 of the ""%2"" list, provider assignment is selected.
					   |You can select a provider assignment only when you group costs by assignments.'; fa = 'In line %1 of the ""%2"" list, provider assignment is selected.
					   |You can select a provider assignment only when you group costs by assignments.';
					   |it = 'Nella stringa %1 dell''elenco ""%2"" è stata selezionata l''assegnazione del fornitore.
					   |L''assegnazione del fornitore deve essere selezionata solo durante il raggruppamento delle spese per assegnazioni.';
					   |pl = 'W wierszu %1 listy ""%2"" wybrano przeznaczenie powierzone. 
					   |, a Przeznaczenie powierzone może być wybrane tylko w wypadku grupowania kosztów według przeznaczenia.';
					   |tr = '""%2"" listesinin %1 satırında sağlayıcı ataması seçildi.
					   |Sağlayıcı ataması yalnızca maliyetleri atamaya göre gruplandırırken seçilebilir.'");
		
	EndIf;
	
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	MetaTabularParts    = Object.Metadata().TabularSections;
	
	NameOfTSOutputProducts  = CheckParameters.NameOfTSOutputProducts;
	NameTSByProducts  = CheckParameters.NameTSByProducts;
	NameTSMaterialsAndWorks = CheckParameters.NameTSMaterialsAndWorks;
	
	TableColumns1        = "LineNumber, Purpose, CostGroupNumber";
	
	Query.SetParameter("TableNameOutputProducts",      MetaTabularParts[NameOfTSOutputProducts].Name);
	Query.SetParameter("SynonymOfOutputProductsTable",  MetaTabularParts[NameOfTSOutputProducts].Synonym);
	Query.SetParameter("ManufacturedProducts",                Object[NameOfTSOutputProducts].Unload(, TableColumns1));
	
	Query.SetParameter("NameOfByProductTable",      MetaTabularParts[NameTSByProducts].Name);
	Query.SetParameter("SynonymOfByProductsTable",  MetaTabularParts[NameTSByProducts].Synonym);
	Query.SetParameter("SideAndIntermediateRelease",                Object[NameTSByProducts].Unload(, TableColumns1));

	Query.SetParameter("NameOfMaterialsAndWorksTable",     MetaTabularParts[NameTSMaterialsAndWorks].Name);
	Query.SetParameter("SynonymForMaterialsAndWorksTable", MetaTabularParts[NameTSMaterialsAndWorks].Synonym);
	Query.SetParameter("MaterialsAndWorks",               Object[NameTSMaterialsAndWorks].Unload(, TableColumns1));
	
	Query.SetParameter("GiveawayTypesOfAppointments",     CheckParameters.GiveawayTypesOfAppointments);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		Common.MessageToUser(
			StrTemplate(MessageText, Selection.LineNumber, Selection.TableSynonym),
			Object,
			CommonClientServer.PathToTabularSection(Selection.TableName, Selection.LineNumber, "Purpose"),,
			Cancel);
		
	EndDo;
	
EndProcedure

// Returns parameters for checking the selection of the giver's destination.
// 
// Returns:
//  Structure - Parameters For Checking The Selection Of The Giver's Destination:
//   * NameOfTSOutputProducts          - String - the name of the tabular part in which the output products are indicated
//   * NameTSByProducts          - String - the name of the tabular part in which the by-products are indicated
//   * NameTSMaterialsAndWorks         - String - the name of the tabular part in which materials and works are indicated
//   * GiveawayTypesOfAppointments    - Array of EnumRef.AssignmentTypes - Giveaway Types Of Appointments
//   * TollBasedCostGroupings - Array of EnumRef.CostGroupingsInTollingOrder, EnumRef.GroupingsOfCostsInBackflushProduction - Toll-Based Cost Groupings
//
Function ParametersForCheckingSelectionOfGiverSDestination() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("NameOfTSOutputProducts"         , "ManufacturedProducts");
	ParametersStructure.Insert("NameTSByProducts"         , "SideAndIntermediateRelease");
	ParametersStructure.Insert("NameTSMaterialsAndWorks"        , "MaterialsAndWorks");
	ParametersStructure.Insert("GiveawayTypesOfAppointments"   , New Array);
	ParametersStructure.Insert("TollBasedCostGroupings", New Array);
	
	ParametersStructure.GiveawayTypesOfAppointments.Add(Enums.AssignmentTypes.Giveaway2_5);
	
	ParametersStructure.TollBasedCostGroupings.Add(Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments);
	ParametersStructure.TollBasedCostGroupings.Add(Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments);
	
	Return ParametersStructure;
	
EndFunction

// Defines for the transferred array of assignments, the business of operation of production:
// "Production from dvalchesky raw materials", "Production from dvalchesky raw materials 2.5", "Own production".
// Parameters:
//  Assignments - Array of CatalogRef.Assignments
// Returns:
//  EnumRef.BusinessTransactions - of operation, if all assignments can be completed with one production order
//  Undefined - if you need to place different orders of operations.
Function BusinessTransactionOfProduction(Assignments) Export
	
	If Assignments.Count() = 0 Then
		Return Enums.BusinessTransactions.OwnProduction;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Assignments", Assignments);
	Query.Text =
		"SELECT
		|	MIN(Set.BusinessOperation) AS BusinessOperation
		|FROM(
		|	SELECT
		|		CASE
		|			WHEN AllAssignments.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
		|				THEN VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
		|			WHEN AllAssignments.AssignmentType = VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22)
		|					AND IncludedDvaltsy2_5.Value
		|				THEN VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
		
		
		|			ELSE
		|				VALUE(Enum.BusinessTransactions.OwnProduction)
		|		END AS BusinessOperation
		|	FROM
		|		Catalog.Assignments AS AllAssignments
		|			LEFT JOIN Constant.UseTollManufacturing2_5 AS IncludedDvaltsy2_5
		|			ON TRUE
		|	WHERE
		|		AllAssignments.Ref IN(&Assignments)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.BusinessTransactions.OwnProduction) AS BusinessOperation
		|	WHERE
		|		VALUE(Catalog.Assignments.EmptyRef) IN(&Assignments)) AS Set
		|HAVING
		|	MIN(Set.BusinessOperation) = MAX(Set.BusinessOperation)";
		
	BusinessOperation = Undefined;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		BusinessOperation = Selection.BusinessOperation;
	EndIf;
	Return BusinessOperation;
	
EndFunction

#EndRegion


#Region Other

// The type of production process of operation.
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - economic operation
// 
// Returns:
//  EnumRef.ProductionProcessTypes - The Type Of Production Process of Operation
//
Function TypeOfProductionProcessOfOperation(BusinessOperation) Export
	
	Result = Enums.ProductionProcessTypes.Assembly;
	If BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		Result = Enums.ProductionProcessTypes.PerformRM;
	ElsIf BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5 Then
			Result = Enums.ProductionProcessTypes.Repair;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the Attributes associated with the giveaway assignment.
//  Parameters:
//   Purpose - CatalogRef.Assignments - The purpose for which it is necessary to determine the Attributes of the order of the giver
//                                              to which it relates.
//  Returns:
//   Undefined, Structure - With Fields:
//                  * Partner    - CatalogRef.Partners - The partner specified in the giver's order.
//                  * Contract    - CatalogRef.CounterpartyContracts - The Contract specified in the giver's order.
//                  * Counterparty - CatalogRef.Counterparties - The counterparty specified in the giver's order.
//
Function DetailsForPurpose(Purpose) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CASE
	|		WHEN NOT MaterialProviderOrder2_5.Partner IS NULL
	|			THEN MaterialProviderOrder2_5.Partner
	|		ELSE CatAssignments.Partner
	|	END AS Partner,
	|	CASE
	|		WHEN NOT MaterialProviderOrder2_5.Contract IS NULL
	|			THEN MaterialProviderOrder2_5.Contract
	|		ELSE CatAssignments.Contract
	|	END AS Contract,
	|	CASE
	|		WHEN NOT MaterialProviderOrder2_5.Counterparty IS NULL
	|			THEN MaterialProviderOrder2_5.Counterparty
	|		ELSE ISNULL(CatAssignments.Contract.Counterparty, VALUE(Catalog.Counterparties.EmptyRef))
	|	END AS Counterparty
	|FROM
	|	Catalog.Assignments AS CatAssignments
	|
	|
	|		LEFT JOIN Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|		ON CatAssignments.OrderDocument = MaterialProviderOrder2_5.Ref
	|WHERE
	|	CatAssignments.Ref = &Purpose
	|	AND (NOT MaterialProviderOrder.Ref IS NULL
	|		OR NOT MaterialProviderOrder2_5.Ref IS NULL
	|		OR CatAssignments.AssignmentType IN (
	|								VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|								VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			AND CatAssignments.Partner <> VALUE(Catalog.Partners.EmptyRef))
	|";
	
	Query.SetParameter("Purpose", Purpose);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = New Structure("Partner, Contract, Counterparty");
		FillPropertyValues(Result, Selection);
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion