#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor);
		
	EndIf;
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor);
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the register.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "GoodsAndServicesToRegisterPurchasingReportsToConsignor");
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	ThereAreChangesOfRegisteredRecordsToDesign = DocumentsPosting.ThereAreRecordsInTable(Document,
		"PreparationOfGoodsAndServicesForPreparationOfReportsToPurchasingCommittee");

	If ThereAreChangesOfRegisteredRecordsToDesign Then
		
		QueryText =
			"SELECT
			|	BalanceTable.Organization						AS Organization,
			|	BalanceTable.Purpose						AS Purpose,
			|	BalanceTable.Products					AS Products,
			|	BalanceTable.Products.UnitOfMeasure	AS UnitOfMeasure,
			|	BalanceTable.Characteristic					AS Characteristic,
			|	BalanceTable.CCDNumber						AS CCDNumber,
			|	BalanceTable.VATRate						AS VATRate,
			|	BalanceTable.CountBalance				AS Count
			|FROM
			|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Balance(,
			|			(Organization, Purpose, Products, Characteristic, CCDNumber, VATRate) IN
			|				(SELECT
			|					Table.Organization,
			|					Table.Purpose,
			|					Table.Products,
			|					Table.Characteristic,
			|					Table.CCDNumber,
			|					Table.VATRate
			|				FROM
			|					PreparationOfGoodsAndServicesForPreparationOfReportsToPurchasingCommittee AS Table)
			|	) AS BalanceTable
			|
			|WHERE
			|	BalanceTable.CountBalance < 0
			|
			|ORDER BY
			|	Organization,
			|	Products,
			|	UnitOfMeasure,
			|	Characteristic,
			|	CCDNumber,
			|	VATRate,
			|	Purpose,
			|	Count";
		
		QueryTexts.Add(QueryText, "ErrorsInMakingReportsToPurchasingCommittee");

	EndIf;
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "PreparationOfGoodsAndServicesForPreparationOfReportsToPurchasingCommittee") Then
		
		MessageTemplate = NStr("vi = 'Mặt hàng %1 %2 %3
			|Đã vượt quá số lượng hàng hóa và dịch vụ cần lập bảng kê của người đặt ký gửi về mua hàng vào %4 %5';
			|ru = 'Номенклатура %1 %2 %3
			|Превышено количество по товарам и услугам к оформлению отчета комитента о закупках на %4 %5';
			|en = 'Items %1 %2 %3
			|The number of goods and services to register the purchase notification is exceeded by %4 %5'; fa = 'Items %1 %2 %3
			|The number of goods and services to register the purchase notification is exceeded by %4 %5';
			|it = 'Номенклатура %1 %2 %3
			|Превышено количество по товарам и услугам к оформлению отчета комитента о закупках на %4 %5';
			|pl = 'Items %1 %2 %3
			|The number of goods and services to register the purchase notification is exceeded by %4 %5';
			|tr = '%1 %2%3
			|Öğesi ürün ve hizmetlere göre %4 %5 satın alma ile ilgili konsinye bildiriminin düzenlenmesi miktarı aşıldı'");
		
		For Each ErrorString In ControlResults.ErrorsInMakingReportsToPurchasingCommittee Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(ErrorString.Products,
				ErrorString.Characteristic);
			Purpose = ?(ValueIsFilled(ErrorString.Purpose), "(" + String(ErrorString.Purpose) + ")", "");
			
			VATText = "";
			If ValueIsFilled(ErrorString.VATRate) Then
				RowVATRate = String(ErrorString.VATRate);
				VATText = NStr("vi = 'Thuế GTGT: %1';
								|ru = 'НДС: %1';
								|en = 'VAT: %1'; fa = 'VAT: %1';
								|it = 'НДС: %1';
								|pl = 'VAT: %1';
								|tr = 'KDV: %1'");
				VATText = StrTemplate(VATText, RowVATRate);
			EndIf;
			
			MessageText = StrTemplate(MessageTemplate, ProductPresentation, Purpose, VATText,
				-ErrorString.Count, ErrorString.UnitOfMeasure);
			
			If Not Document.AdditionalProperties.Property("DisableProductControlForIssuingReportsToPurchasingCommittee") Then
				Common.MessageToUser(MessageText, Document,,, Cancel);
			Else
				Common.MessageToUser(MessageText, Document);
			EndIf;
			
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
	MatchingQueryTexts.Insert("PreparationOfGoodsAndServicesForPreparationOfReportsToPurchasingCommittee", 
		AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Name;
	NameOfChangeTable = "PreparationOfGoodsAndServicesForPreparationOfReportsToPurchasingCommittee"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

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

// Fills in the parameters for reflecting register movements in financial accounting
//
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
//
// Returns:
// 	See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	ReflectionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection);
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathCurrency = "Currency";
	ReflectionParameters.ManResources.Add("0");
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("0");
	ReflectionParameters.LocalResources.Add("SumCompl");
	ReflectionParameters.ShaftResources.Add("AmountIncludingVAT");
	ReflectionParameters.ResourcesQuantity.Add("Count");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Products;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(
		DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.Products.DataPath = "Products";
	ReflectionParameters.StructureOfAnalytics.Warehouse.Insert("Value", Undefined);
	ReflectionParameters.StructureOfAnalytics.InventoryOwnerAttribute.Insert("Value", Undefined);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	FinancialAccountingByFinancialRegisterData.UseLineNumberAsLineId(ReflectionParameters);
	Return ReflectionParameters;
	
EndFunction

#EndRegion

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager = Undefined, DataForRegisteringTasks = Undefined) Export
	
	If Not DataForRegisteringTasks = Undefined Then
		Return DataForRegisteringTasks;
	EndIf;
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

