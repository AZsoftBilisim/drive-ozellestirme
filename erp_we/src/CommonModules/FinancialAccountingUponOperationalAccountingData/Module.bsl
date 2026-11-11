#Region Public

// Adds the reflection parameters necessary for generating transactions in operational accounting registers.
// 
// Parameters:
// 	 ParametersForGeneratingTransactions - See FinancialAccountingPostingServer.ParametersForGeneratingTransactions
//
Procedure AddParametersForGeneratingTransactions(ParametersForGeneratingTransactions) Export
	
	If Not GetFunctionalOption("ConfigurePostingsForBusinessTransactions") Then
		Return;
	EndIf;
	
	ParametersForGeneratingTransactions.Insert("RecordSettings", ReflectionSettingsInInternationalAccounting());
	ParametersForGeneratingTransactions.Insert("RequestTextsByRegister", RequestTextsByRegister());
	ParametersForGeneratingTransactions.Insert("InvoiceRefinementTable", InvoiceRefinementTable());
	InitializeOperationSetupTable(ParametersForGeneratingTransactions.TempTablesManager);
	
EndProcedure

// Generates international accounting transactions based on the data from operational accounting registers.
// 
// Parameters:
// 	ParametersForGeneratingTransactions - Structure - Parameters for generating transactions.
// 	TableOfTransactions - ValueTable - The table that the generated transactions are added to.
//
Procedure Reflect(ParametersForGeneratingTransactions, TableOfTransactions) Export
	
	If Not GetFunctionalOption("ConfigurePostingsForBusinessTransactions") Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.TempTablesManager = ParametersForGeneratingTransactions.TempTablesManager;
	Query.Text = "
	|SELECT
	|	DocumentsToBeReflected.Organization AS Organization,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|WHERE
	|	DocumentsToBeReflected.PostingGenerationSetting.MethodOfCancelingTransactions
	|		= VALUE(Enum.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings)
	|GROUP BY
	|	DocumentsToBeReflected.Organization,
	|	DocumentsToBeReflected.ChartOfAccounts
	|";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		MessageText = NStr("vi = 'Đang sử dụng tùy chỉnh lập bút toán với phương thức điều chỉnh bằng các bút toán đảo ngược:';
							|ru = 'Используется настройка формирования проводок со способом корректировки реверсивными проводками:';
							|en = 'The posting schema with correction by reversing entries is used:'; fa = 'The posting schema with correction by reversing entries is used:';
							|it = 'Viene utilizzata l''impostazione di creazione delle registrazioni con metodo di correzione tramite registrazioni inverse:';
							|pl = 'Jest używane ustawienie tworzenia dekretowań ze sposobem korekty dekretowaniami rewersyjnymi:';
							|tr = 'Ters kayıtlarla ayarlama yöntemiyle kayıtların oluşturulması için ayar kullanılır:'");
		
		Selection = Result.Select();
		While Selection.Next() Do
			MessageText = MessageText + Chars.LF + StrTemplate(
				NStr("vi = 'Doanh nghiệp ""%1"", hệ thống tài khoản ""%2"";';
					|ru = 'Организация ""%1"", план счетов ""%2"";';
					|en = 'Company %1, chart of accounts %2'; fa = 'Company %1, chart of accounts %2';
					|it = 'Azienda ""%1"", piano dei conti ""%2"";';
					|pl = 'Filtr ""%1"", plan kont ""%2"";';
					|tr = 'İş yeri ""%1"", hesap planı ""%2"";'"),
				Selection.Organization, Selection.ChartOfAccounts)
		EndDo;
		
		MessageText = MessageText + Chars.LF + NStr("vi = 'Hãy thay đổi tùy chỉnh tạo bút toán trước khi phản ánh vào kế toán quốc tế.';
													|ru = 'Измените настройку формирования проводок перед отражением в международном учете.';
													|en = 'Change the posting schema before recognition in financial accounting.'; fa = 'Change the posting schema before recognition in financial accounting.';
													|it = 'Modificare l''impostazione di creazione delle registrazioni prima di riportarle nella contabilità internazionale.';
													|pl = 'Zmień ustawienie tworzenia dekretowań przed rejestracją w ewidencji międzynarodowej.';
													|tr = 'Uluslararası muhasebede yansımadan önce kayıtların oluşumu için ayarı değiştir.'");
		Raise MessageText;
	EndIf;
	
	For Each CollectionItem In ParametersForGeneratingTransactions.RequestTextsByRegister Do
		RegisterName = CollectionItem.Key;
		QueryText = CollectionItem.Value;
		ReflectRegisterData(RegisterName, QueryText, ParametersForGeneratingTransactions, TableOfTransactions);
	EndDo;
	
EndProcedure

// Supplements the document registration tables to be reflected in the international accounting for the data of movements in the operational.
// 
// Parameters:
// 	Object - DocumentObject - The document that is being held.
// 	AdditionalProperties - Structure - Additional properties of the RS are reflected in documentsinternational Accounting.
// 	RegistrationTable - ValueTable - A table with registration data for reflection, which needs to be supplemented:
// 	                      * Period - Date - registration period (document date)
// 	                      * Organization - CatalogRef.Companies - the organization for which the document generates transactions
// 	                      * DateRecord - Date - the date on which the document forms of the transaction;
// 	                      * BusinessOperation - EnumRef.BusinessTransactions - of reflected economic operation.
//
Procedure AddRegistrationTablesToReflection(Object, AdditionalProperties, RegistrationTable) Export
	
	If Not GetFunctionalOption("ConfigurePostingsForBusinessTransactions") Then
		Return;
	EndIf;
	
	SupplementRegistrationTableAccordingToDataOfCirculatingRegisters(Object, RegistrationTable);
	
	TableReflectionOfDocumentsInInternationalAccounting = Undefined;
	TableReflectionOfDocumentsInInternationalAccountingIsTransferred = 
		AdditionalProperties.Property("TableReflectionOfDocumentsInInternationalAccounting", TableReflectionOfDocumentsInInternationalAccounting);
	
	If TableReflectionOfDocumentsInInternationalAccountingIsTransferred  Then 
		For Each TableRow In TableReflectionOfDocumentsInInternationalAccounting Do
			Filter = New Structure();
			Filter.Insert("Organization", TableRow.Organization);
			Filter.Insert("DateRecord", TableRow.DateRecord);
			If RegistrationTable.FindRows(Filter).Count() = 0 Then
				NewRegistrationLine = RegistrationTable.Add();
				FillPropertyValues(NewRegistrationLine, TableRow);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Checks whether there are transaction templates for business transactions in documents that need to be reflected.
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - Contains a temporary table documentreflection:
// 	              * ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - 
// 	              * Document - DocumentRef - 
// 	              * Organization - CatalogRef.Companies -
// 	              * PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting
// 	CheckParameters - See DataProcessors.DocumentPostingInFinancialAccounting.ParametersForCheckingReflectionRules
// 	
// Returns:
// 	ValueTable - Table of required settings:
// 	              * Operation - CatalogRef.BusinessTransactionsSettings -
// 	              * ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts -
// 	              * PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - 
// 	              * BusinessOperation - EnumRef.BusinessTransactions -
// 	              * DataSource - String - Name of the data source (register).
//
Function CheckRecordingRules(TempTablesManager, CheckParameters) Export
	
	ErrorsTable = New ValueTable;
	
	If Not GetFunctionalOption("ConfigurePostingsForBusinessTransactions") Then
		Return ErrorsTable;
	EndIf;
		
	ErrorsTable.Columns.Add("Operation", New TypeDescription("CatalogRef.BusinessTransactionsSettings"));
	ErrorsTable.Columns.Add("ChartOfAccounts", New TypeDescription("CatalogRef.FinancialAccountingChartsOfAccounts"));
	ErrorsTable.Columns.Add("PostingGenerationSetting", New TypeDescription("CatalogRef.FinancialAccountingPostingGenerationSetting"));
	ErrorsTable.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	ErrorsTable.Columns.Add("DataSource", New TypeDescription("String"));
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT DISTINCT
	|	FinancialAccountingPostingTemplatesThatRequireSetup.ChartOfAccounts AS ChartOfAccounts,
	|	FinancialAccountingPostingTemplatesThatRequireSetup.PostingGenerationSetting AS PostingGenerationSetting,
	|	FinancialAccountingPostingTemplatesThatRequireSetup.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS Operation,
	|	BusinessTransactionsSettings.DataSource AS DataSource
	|FROM
	|	InformationRegister.FinancialAccountingPostingTemplatesThatRequireSetup AS FinancialAccountingPostingTemplatesThatRequireSetup
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		FinancialAccountingPostingTemplatesThatRequireSetup.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	(ChartOfAccounts, PostingGenerationSetting, Document) IN
	|		(SELECT
	|			DocumentsToBeReflected.ChartOfAccounts,
	|			DocumentsToBeReflected.PostingGenerationSetting,
	|			DocumentsToBeReflected.Recorder
	|		FROM
	|			DocumentsToBeReflected AS DocumentsToBeReflected
	|		)
	|";
	
	ErrorsTable = Query.Execute().Unload();
	ErrorsTable.Indexes.Add("Operation, PostingGenerationSetting");
	ErrorsTable.Sort("Operation, PostingGenerationSetting");
	
	Return ErrorsTable;
	
EndFunction

// Fills in the table with documents that require reflection and form movements in the Opera. accounting for a specific household. operations.
// 
// Parameters:
// 	DocumentsTable - ValueTable - The table of values to be filled in:
// 		* Document - DocumentRef - link to the document;
// 		* Date - Date - The date of the;
// 		* Organization - CatalogRef.Companies - Organization that the document generates traffic for;
// 		* Comment - String - Comment on the status of the document's reflection in international accounting;
// 	BusinessOperation - CatalogRef.BusinessTransactionsSettings - The operation you want to perform the selection.
// 	DataSource - String - Name of the data source (register).
// 	PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - Setting for selecting documents.
// 	Organization - CatalogRef.Companies - The organization for the selection of documents.
//
Procedure FillInTableOfDocumentsForOperation(DocumentsTable, BusinessOperation, DataSource, PostingGenerationSetting, Organization) Export
	
	QueriesTexts = RequestTextsByRegister();
	QueryTextRegisterData = QueriesTexts[DataSource];
	
	If Not ValueIsFilled(QueryTextRegisterData) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentsToBeReflected.DateRecord AS DateRecord,
	|	DocumentsToBeReflected.Recorder AS Recorder,
	|	DocumentsToBeReflected.Organization AS Organization,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting,
	|	DocumentsToBeReflected.Comment AS Comment
	|INTO DocumentsToBeReflected
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentsToBeReflected
	|	
	|WHERE
	|	DocumentsToBeReflected.Organization = &Organization
	|	AND DocumentsToBeReflected.PostingGenerationSetting = &PostingGenerationSetting
	|	AND DocumentsToBeReflected.Status IN (
	|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting),
	|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined))
	|
	|INDEX BY
	|	Organization,
	|	DateRecord,
	|	Recorder
	|;
	|
	|/////////////////////////////////////
	|SELECT DISTINCT
	|	RegisterData.Recorder AS Document,
	|	RegisterData.Period AS Period,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.PostingGenerationSetting AS PostingGenerationSetting
	|INTO RegisterData
	|FROM 
	|	&QueryTextRegisterData AS RegisterData
	|WHERE
	|	RegisterData.BusinessOperation = &BusinessOperation
	|INDEX BY
	|	RegisterData.Recorder,
	|	RegisterData.Period,
	|	RegisterData.Organization
	|;
	|
	|/////////////////////////////////////
	|SELECT
	|	RegisterData.Document AS Document,
	|	RegisterData.Period AS Date,
	|	RegisterData.Organization AS Organization,
	|	DocumentsToBeReflected.Comment AS Comment
	|FROM
	|	RegisterData AS RegisterData
	|	LEFT JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Document = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND RegisterData.PostingGenerationSetting = DocumentsToBeReflected.PostingGenerationSetting
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|";
	QueryText = StrReplace(QueryText, "&QueryTextRegisterData", "(" + QueryTextRegisterData + ")");
	
	TempTablesManager = New TempTablesManager;
	InitializeOperationSetupTable(TempTablesManager);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;

	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
	Query.SetParameter("Organization", Organization);
	
	DocumentsTable.Load(Query.Execute().Unload());
	
EndProcedure

// Checks reflection rules before they are recorded in the international accounting Rule register.
//
// Parameters:
// 	RulesOfPostingsInFinancialAccounting - ValueTable - Uploading a set of records in the register of rules for international accounting.
// 	Cancel - Boolean - The record failure flag is set in case of an error.
//
Procedure BeforeWritingReflectionRules(RulesOfPostingsInFinancialAccounting, Cancel) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PostingTemplates.PostingGenerationSetting AS PostingGenerationSetting,
	|	PostingTemplates.PostingTemplate AS PostingTemplate
	|INTO PostingTemplates
	|FROM
	|	&PostingTemplates AS PostingTemplates
	|
	|INDEX BY
	|	PostingTemplates.PostingTemplate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PostingTemplates.PostingGenerationSetting.Owner AS ChartOfAccounts,
	|	PostingTemplates.PostingGenerationSetting AS PostingGenerationSetting,
	|	PostingTemplates.PostingTemplate AS PostingTemplate,
	|	CatalogData.Operation AS Operation
	|INTO BusinessTransactions
	|FROM
	|	PostingTemplates AS PostingTemplates
	|	INNER JOIN
	|		Catalog.PostingTemplatesForFinancialAccounting AS CatalogData
	|	ON
	|		PostingTemplates.PostingTemplate = CatalogData.Ref
	|
	|INDEX BY
	|	CatalogData.Operation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessTransactions.PostingTemplate AS PostingTemplate,
	|	BusinessTransactions.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	BusinessTransactions AS BusinessTransactions
	|	INNER JOIN
	|		InformationRegister.BusinessTransactionsNotPostedInFinancialAccounting AS NonReflectedBusinessTransactions
	|	ON
	|		BusinessTransactions.PostingGenerationSetting = NonReflectedBusinessTransactions.PostingGenerationSetting
	|		AND BusinessTransactions.Operation = NonReflectedBusinessTransactions.Operation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessTransactions.ChartOfAccounts AS ChartOfAccounts,
	|	BusinessTransactions.PostingGenerationSetting AS PostingGenerationSetting,
	|	BusinessTransactions.Operation.BusinessOperation AS BusinessOperation
	|FROM
	|	BusinessTransactions AS BusinessTransactions
	|";
	
	Query.SetParameter("PostingTemplates", RulesOfPostingsInFinancialAccounting);
	
	QueryResults = Query.ExecuteBatch();
	
	SelectionOfTransactionsNotReflected = QueryResults[2].Select();
	While SelectionOfTransactionsNotReflected.Next() Do
		MessageText = 
			StrTemplate(NStr("vi = 'Giao dịch kinh tế được sử dụng trong khuôn mẫu bút toán ""%1"", đã được loại trừ khỏi tùy chỉnh áp dụng ""%2"".';
							|ru = 'Хозяйственная операция, используемая в шаблоне проводки ""%1"", исключена из применяемой настройки ""%2"".';
							|en = 'Business transaction used in posting template ""%1"" is excluded from the applied settings ""%2"".'; fa = 'Business transaction used in posting template ""%1"" is excluded from the applied settings ""%2"".';
							|it = 'Transazione economica utilizzabile nel modello di transazione ""%1"", è esclusa dall''applicazione dell''impostazione ""%2"".';
							|pl = 'Operacja gospodarcza, używana w szablonie księgowania ""%1"", jest wyłączona z zastosowanej konfiguracji ""%2"".';
							|tr = '""%1"" deftere kayıt numunesinde kullanılan ticari işlem, uygulanan ""%2"" ayarların dışında bırakıldı.'"),
				SelectionOfTransactionsNotReflected.PostingTemplate, 
				SelectionOfTransactionsNotReflected.PostingGenerationSetting);
		Common.MessageToUser(MessageText, , , , Cancel);
	EndDo;
	
	If Not Cancel Then
		SelectionOfReflectionRule =  QueryResults[3].Select();
		While SelectionOfReflectionRule.Next() Do
			RecordSet = InformationRegisters.FinancialAccountingPostingTemplatesThatRequireSetup.CreateRecordSet();
			RecordSet.Filter.ChartOfAccounts.Set(SelectionOfReflectionRule.ChartOfAccounts);
			RecordSet.Filter.PostingGenerationSetting.Set(SelectionOfReflectionRule.PostingGenerationSetting);
			RecordSet.Filter.BusinessOperation.Set(SelectionOfReflectionRule.BusinessOperation);
			RecordSet.Write();
		EndDo;
	EndIf;
	
EndProcedure


// See ReportsOptionsOverridable.CustomizeReportsOptions
// 
Procedure CustomizeReportsOptions(Settings) Export
	
	Reports.ErrorsOfPostingTemplatesSetup.CustomizeReportOptions(Settings);
	Reports.AccountSpecificationErrorsFinancialAccounting.CustomizeReportOptions(Settings);
	
EndProcedure

#EndRegion

#Region Private

#Region TextsOfRegisterDataRequests

Function RequestTextsByRegister() Export

	QueriesTexts = New Structure();
	QueriesTexts.Insert("IntangibleAssetsAmortizationCharge", QueryTextIntangibleAssetsAmortizationCharge());
	QueriesTexts.Insert("FixedAssetsDepreciationCharge", QueryTextFixedAssetsDepreciationCharge());
	QueriesTexts.Insert("RevenueAndCOGS", QueryTextRevenueAndCOGS());
	QueriesTexts.Insert("RecordsCashIncomeExpenses", QueryTextRecordsCashIncomeExpenses());
	QueriesTexts.Insert("RecordsCashCounterparty", QueryTextRecordsCashCounterparty());
	QueriesTexts.Insert("CashFlow", QueryTextCashFlow());
	QueriesTexts.Insert("RecordsIncomeExpensesOtherAssetsLiabilities", QueryTextRecordsIncomeExpensesOtherAssetsLiabilities());
	QueriesTexts.Insert("RecordsCounterpartyIncomeExpenses", QueryTextRecordsCounterpartyIncomeExpenses());
	QueriesTexts.Insert("RecordsCounterpartyCounterparty", QueryTextRecordsCounterpartyCounterparty());
	QueriesTexts.Insert("RegisterRecordsProductsIncomeExpenses", QueryTextRegisterRecordsProductsIncomeExpenses());
	QueriesTexts.Insert("RecordsProductsProducts", QueryTextRecordsProductsProducts());
	QueriesTexts.Insert("Purchases", QueryTextPurchases());
	QueriesTexts.Insert("OtherExpenses", QueryTextOtherExpenses());
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		QueriesTexts.Insert("CustomersARAPAccountingByDueDates", QueryTextCustomersARAPAccountingByDueDates());
		QueriesTexts.Insert("VendorsARAPAccountingByDueDates", QueryTextVendorsARAPAccountingByDueDates());
	Else
		QueriesTexts.Insert("CustomersARAPAccountingByDocuments", QueryTextCustomersARAPAccountingByDocuments());
		QueriesTexts.Insert("VendorsARAPAccountingByDocuments", QueryTextVendorsARAPAccountingByDocuments());
	EndIf;
	QueriesTexts.Insert("IACost", QueryTextIACost());
	QueriesTexts.Insert("FACost", QueryTextFACost());
	QueriesTexts.Insert("VATPrepaymentsFromCustomer", QueryTextVATPrepaymentsFromCustomer());
	QueriesTexts.Insert("VATPrepaymentsToVendor", QueryTextVATPrepaymentsToVendor());
	QueriesTexts.Insert("VATRegisterRecords", QueryTextVATRegisterRecords());
	
	Return QueriesTexts;

EndFunction

Function QueryTextRevenueAndCOGS()

	QueryText =
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	
	|	RegisterData.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	RegisterData.ItemsLocationAttributes.Products AS Products,
	|	RegisterData.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	RegisterData.ItemsLocationAttributes.Counterparty AS Custodian,
	|	RegisterData.ItemsLocationAttributes.Products.ItemsType AS ItemsType,
	|	RegisterData.SetAccountingDimension AS SetAccountingDimension,
	|	RegisterData.Warehouse AS Warehouse,
	|	CASE
	|		WHEN RegisterData.Warehouse REFS Catalog.Warehouses
	|			THEN RegisterData.Warehouse.Department
	|		ELSE RegisterData.Warehouse
	|	END AS WarehouseDivision,
	|	RegisterData.InventoryType AS InventoryType,
	|	RegisterData.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.LotVendorAttributes.Vendor AS Vendor,
	|	RegisterData.LotVendorAttributes.Counterparty AS VendorSCounterparty,
	|	RegisterData.Terms AS Terms,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.SalesOrder AS SalesOrder,
	|	
	|	SUM(RegisterData.RevenueAmount) AS RevenueAmount,
	|	SUM(RegisterData.RevenueAmountExcludingVAT) AS RevenueAmountExcludingVAT,
	|	SUM(RegisterData.RevenueAmount - RegisterData.RevenueAmountExcludingVAT) AS VATAmount,
	|	SUM(RegisterData.RevenueAmountIncludingVATLocal) AS RevenueAmountIncludingVATLocal,
	|	SUM(RegisterData.RevenueAmountExclVATLocal) AS RevenueAmountExclVATLocal,
	|	SUM(RegisterData.RevenueAmountIncludingVATLocal - RegisterData.RevenueAmountExclVATLocal) AS VATAmountCompl,
	|	
	|	SUM(RegisterData.Cost) AS Cost,
	|	SUM(RegisterData.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(RegisterData.CostMan) AS CostMan,
	|	SUM(RegisterData.LocalCost) AS LocalCost,
	|	
	|	SUM(RegisterData.OffBalanceCost) AS OffBalanceCost,
	|	SUM(RegisterData.OffBalanceCostLocal) AS OffBalanceCostLocal,
	|
	|	SUM(RegisterData.AddExpensesForGoods) AS AddExpensesForGoods,
	|	SUM(RegisterData.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
	|	SUM(RegisterData.AddExpensesMan) AS AddExpensesMan,
	|	SUM(RegisterData.AddExpensesLocal) AS AddExpensesLocal,
	|	SUM(RegisterData.AddExpensesForGoods - RegisterData.AdditionalExpensesExcludingVAT) AS VATAmountOfAdditionalExpenses,
	|	
	|	SUM(RegisterData.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
	|	SUM(RegisterData.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
	|	SUM(RegisterData.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
	|	SUM(RegisterData.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
	|	
	|	SUM(RegisterData.LaborCosts) AS LaborCosts,
	|	SUM(RegisterData.LaborCostsMan) AS LaborCostsMan,
	|	SUM(RegisterData.LaborCostsLocal) AS LaborCostsLocal,
	|	
	|	SUM(RegisterData.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
	|	SUM(RegisterData.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
	|	SUM(RegisterData.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
	|	SUM(RegisterData.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
	|
	|	SUM(RegisterData.SellingExpensesIncludingVAT) AS SellingExpensesIncludingVAT,
	|	SUM(RegisterData.SellingExpensesExcludingVAT) AS SellingExpensesExcludingVAT,
	|	SUM(RegisterData.SellingExpensesMan) AS SellingExpensesMan,
	|	SUM(RegisterData.SellingExpensesLocal) AS SellingExpensesLocal,
	|
	|	SUM(RegisterData.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
	|	SUM(RegisterData.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
	|	
	|	SUM(CASE WHEN RegisterData.CostMan + RegisterData.AddExpensesMan + RegisterData.ItemizedFixedCostsManag + RegisterData.LaborCostsMan + RegisterData.ItemizedVariableCostsManag = 0
	|			THEN RegisterData.Cost + RegisterData.AddExpensesForGoods + RegisterData.ItemizedFixedCostsIncludingVAT + RegisterData.LaborCosts + RegisterData.ItemizedVariableCostsIncludingVAT
	|			ELSE RegisterData.CostMan + RegisterData.AddExpensesMan + RegisterData.ItemizedFixedCostsManag + RegisterData.LaborCostsMan + RegisterData.ItemizedVariableCostsManag
	|		END) AS ManagementCost,
	|	SUM(RegisterData.LocalCost + RegisterData.AddExpensesLocal + RegisterData.ItemizedFixedCostsCompl + RegisterData.LaborCostsLocal + RegisterData.ItemizedVariableCostsCompl) AS CostLocal,
	|	SUM(RegisterData.CostExcludingVAT + RegisterData.AdditionalExpensesExcludingVAT + RegisterData.ItemizedFixedCostsExcludingVAT + RegisterData.LaborCosts + RegisterData.ItemizedVariableCostsExcludingVAT) AS CostExcludingVAT_,
	|	
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	SUM(RegisterData.AmountInARAPCurrency) AS AmountInARAPCurrency,
	|	SUM(RegisterData.AmountExcludingVATInARAPCurrency) AS AmountExcludingVATInARAPCurrency,
	|	SUM(RegisterData.AmountInARAPCurrency - RegisterData.AmountExcludingVATInARAPCurrency) AS AmountOfNDSInCurrencyOfMutualSettlements,
	|	
	|	RegisterData.DocumentCurrency AS DocumentCurrency,
	|	SUM(RegisterData.AmountInDocumentCurrency) AS AmountInDocumentCurrency,
	|	SUM(RegisterData.AmountExcludingVATInDocumentCurrency) AS AmountExcludingVATInDocumentCurrency,
	|	SUM(RegisterData.AmountInDocumentCurrency - RegisterData.AmountExcludingVATInDocumentCurrency) AS NDSAmountInDocumentCurrency,
	|	
	|	SUM(RegisterData.Count) AS Count,
	|	
	|	RegisterData.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.SourceOfProductFinancialAccountingGroup.FinancialAccountingGroup AS HFCProducts,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|
	|GROUP BY
	|	RegisterData.Period,
	|	RegisterData.Recorder,
	|	VALUETYPE(RegisterData.Recorder),
	|	RegisterData.BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.Department,
	|	RegisterData.ProductLineOfBusiness,
	|	RegisterData.ItemsLocationAttributes,
	|	RegisterData.SetAccountingDimension,
	|	RegisterData.LotVendorAttributes,
	|	RegisterData.Warehouse,
	|	CASE
	|		WHEN RegisterData.Warehouse REFS Catalog.Warehouses
	|			THEN RegisterData.Warehouse.Department
	|		ELSE RegisterData.Warehouse
	|	END,
	|	RegisterData.InventoryType,
	|	RegisterData.InventoryOwnerAttribute,
	|	RegisterData.CounterpartyLineOfBusiness,
	|	RegisterData.InventoryOwnerAttribute.Counterparty,
	|	RegisterData.Terms,
	|	RegisterData.Contract,
	|	RegisterData.SalesOrder,
	|	RegisterData.ARAPCurrency,
	|	RegisterData.DocumentCurrency,
	|	RegisterData.SourceOfProductFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.SourceOfProductFinancialAccountingGroup.FinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup.FinancialAccountingGroup,
	|	RegisterData.ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting
	|";

	Return QueryText;

EndFunction

Function QueryTextRecordsCashIncomeExpenses()
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	RegisterData.IncomeExpenseBusinessUnit AS IncomeExpenseBusinessUnit,
	|
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|	RegisterData.Cash AS Cash,
	|	RegisterData.Cash.Department AS CashDivision,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.LineOfBusinessItems AS LineOfBusinessItems,
	|	RegisterData.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	RegisterData.DimensionOfRevenue AS DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses AS DimensionOfExpenses,
	|	RegisterData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN RegisterData.IncomeAndExpenseItem REFS ChartOfCharacteristicTypes.IncomeItems
	|			THEN RegisterData.DimensionOfRevenue
	|		ELSE RegisterData.DimensionOfExpenses
	|	END AS RevenueExpenseAnalyticsDivision,
	|	RegisterData.VATRate AS VATRate,
	|
	|	RegisterData.Sum AS Sum,
	|	RegisterData.SumCompl AS SumCompl,
	|	RegisterData.AmountInCurrency AS AmountInCurrency,
	|
	|	RegisterData.Sum - RegisterData.VATAmount AS AmountExcludingVAT,
	|	RegisterData.SumCompl - RegisterData.VATAmountCompl AS LocalAmountExcludingVAT,
	|	RegisterData.AmountInCurrency - RegisterData.AmountVATCurrencyPayment AS AmountExcludingVATInPaymentCurrency,
	|
	|	RegisterData.VATAmount AS VATAmount,
	|	RegisterData.VATAmountCompl AS VATAmountCompl,
	|	RegisterData.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
	|
	|	RegisterData.AmountToBePaidWithinLimit + RegisterData.AmountToBePaidAboveLimit AS AmountToBePaid,
	|	RegisterData.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
	|	RegisterData.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
	|	
	|	CASE
	|		WHEN RegisterData.SourceOfCashFinancialAccountingGroup REFS Catalog.LoanAndDepositContracts
	|			THEN RegisterData.SourceOfCashFinancialAccountingGroup.FinancialAccountingGroupOfCash
	|		ELSE RegisterData.SourceOfCashFinancialAccountingGroup.FinancialAccountingGroup
	|	END AS HFCCash,
	|	RegisterData.SourceOfIncomeExpensesFinancialAccountingGroup.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.RecordsCashIncomeExpenses AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsCashCounterparty()
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|
	|	RegisterData.Cash AS Cash,
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|	RegisterData.Cash.Department AS CashDivision,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.ARAPObject.Department AS ObjectOfCalculationsDivision,
	|	RegisterData.ARAPDocument AS ARAPDocument,
	|	
	|	RegisterData.PayAmount AS PayAmount,
	|	RegisterData.PaymentAmountLocal AS PaymentAmountLocal,
	|	RegisterData.PaymentAmountPaymentCurrency AS PaymentAmountPaymentCurrency,
	|	RegisterData.PostpaymentAmount AS PostpaymentAmount,
	|	RegisterData.PostpaymentAmountLocal AS PostpaymentAmountLocal,
	|	RegisterData.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
	|	RegisterData.PrepaymentAmountMan AS PrepaymentAmountMan,
	|	RegisterData.PrepaymentAmountLocal AS PrepaymentAmountLocal,
	|	RegisterData.PrepaymentAmount AS PrepaymentAmount,
	|	
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	RegisterData.PaymentAmountInTheSettlementCurrency AS PaymentAmountInTheSettlementCurrency,
	|	RegisterData.PostPaymentAmountInARAPCurrency AS PostPaymentAmountInARAPCurrency,
	|	RegisterData.PrepaymentAmountInARAPCurrency AS PrepaymentAmountInARAPCurrency,
	|
	|	RegisterData.VATRate AS VATRate,
	|	RegisterData.VATAmount AS VATAmount,
	|	RegisterData.VATAmountCompl AS VATAmountCompl,
	|	RegisterData.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
	|
	|	RegisterData.AmountToBePaidWithinLimit + RegisterData.AmountToBePaidAboveLimit AS AmountToBePaid,
	|	RegisterData.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
	|	RegisterData.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
	|	
	|	CASE
	|		WHEN RegisterData.SourceOfCashFinancialAccountingGroup REFS Catalog.LoanAndDepositContracts
	|			THEN RegisterData.SourceOfCashFinancialAccountingGroup.FinancialAccountingGroupOfCash
	|		ELSE RegisterData.SourceOfCashFinancialAccountingGroup.FinancialAccountingGroup
	|	END AS HFCCash,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.RecordsCashCounterparty AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextCashFlow()
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.Cash AS Cash,
	|	RegisterData.Cash.Department AS CashDivision,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.CorLineOfBusiness AS CorLineOfBusiness,
	|	RegisterData.CorCash AS CorCash,
	|	RegisterData.CorCash.Department AS CorCashDivision,
	|	RegisterData.CorCashType AS CorCashType,
	|	RegisterData.CorrespondingCurency AS CorrespondingCurency,
	|
	|	RegisterData.Sum AS Sum,
	|	RegisterData.SumCompl AS SumCompl,
	|	RegisterData.AmountInCurrency AS AmountInCurrency,
	|	RegisterData.AmountInCorCurrency AS AmountInCorCurrency,
	|
	|	RegisterData.AmountToBePaidWithinLimit + RegisterData.AmountToBePaidAboveLimit AS AmountToBePaid,
	|	RegisterData.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
	|	RegisterData.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
	|	
	|	CASE
	|		WHEN RegisterData.SourceOfCashFinancialAccountingGroup REFS Catalog.LoanAndDepositContracts
	|			THEN RegisterData.SourceOfCashFinancialAccountingGroup.FinancialAccountingGroupOfCash
	|		ELSE RegisterData.SourceOfCashFinancialAccountingGroup.FinancialAccountingGroup
	|	END AS HFCCash,
	|	CASE
	|		WHEN RegisterData.CorSourceOfFAGOfCash REFS Catalog.LoanAndDepositContracts
	|			THEN RegisterData.CorSourceOfFAGOfCash.FinancialAccountingGroupOfCash
	|		ELSE RegisterData.CorSourceOfFAGOfCash.FinancialAccountingGroup
	|	END AS CorHFCCash,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.CashFlow AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsIncomeExpensesOtherAssetsLiabilities()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.AssetRef AS AssetRef,
	|	RegisterData.DimensionOfRevenue AS DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses AS DimensionOfExpenses,
	|	RegisterData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN RegisterData.AssetRef REFS ChartOfCharacteristicTypes.IncomeItems
	|			THEN RegisterData.DimensionOfRevenue
	|		ELSE RegisterData.DimensionOfExpenses
	|	END AS RevenueExpenseAnalyticsDivision,
	|	RegisterData.AssetRef.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	RegisterData.CorLineOfBusiness AS CorLineOfBusiness,
	|	RegisterData.DebitBusinessUnit AS DebitBusinessUnit,
	|	RegisterData.CorItem AS CorItem,
	|	RegisterData.CorIncomeDimension AS CorIncomeDimension,
	|	RegisterData.CorExpenditureDimension AS CorExpenditureDimension,
	|	RegisterData.CorDimensionOfAssetsLiabilities AS CorDimensionOfAssetsLiabilities,
	|	RegisterData.CorItem.FinancialAccountingGroup AS CorHFCRevenueExpenditure,
	|	RegisterData.CorFinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	CASE WHEN RegisterData.SumMan = 0
	|		THEN RegisterData.Sum
	|		ELSE RegisterData.SumMan
	|	END AS SumMan,
	|	RegisterData.SumCompl AS SumCompl,
	|	
	|	RegisterData.Currency AS Currency,
	|	RegisterData.AmountInCurrency AS AmountInCurrency,
	|
	|	RegisterData.SalaryTransactionKind AS SalaryTransactionKind,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.RecordsIncomeExpensesOtherAssetsLiabilities AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsCounterpartyIncomeExpenses()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.ARAPObject.Department AS ObjectOfCalculationsDivision,
	|	
	|	RegisterData.LineOfBusinessItems AS LineOfBusinessItems,
	|	RegisterData.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	RegisterData.DimensionOfRevenue AS DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses AS DimensionOfExpenses,
	|	RegisterData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN RegisterData.IncomeAndExpenseItem REFS ChartOfCharacteristicTypes.IncomeItems
	|			THEN RegisterData.DimensionOfRevenue
	|		ELSE RegisterData.DimensionOfExpenses
	|	END AS RevenueExpenseAnalyticsDivision,
	|
	|	RegisterData.Sum AS Sum,
	|	RegisterData.AmountExcludingVAT AS AmountExcludingVAT,
	|	RegisterData.Sum - RegisterData.AmountExcludingVAT AS VATAmount,
	|	RegisterData.SumCompl AS SumCompl,
	|	RegisterData.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|	RegisterData.SumCompl - RegisterData.LocalAmountExcludingVAT AS VATAmountCompl,
	|
	|	RegisterData.Currency AS Currency,
	|	RegisterData.AmountInCurrency AS AmountInCurrency,
	|	RegisterData.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
	|	RegisterData.AmountInCurrency - RegisterData.AmountExcludingVATInCurrency AS NDSAmountInCurrency,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	RegisterData.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	RegisterData.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|	RegisterData.AmountInARAPCurrency - RegisterData.AmountExcludingVATInARAPCurrency AS AmountOfNDSInCurrencyOfMutualSettlements,
	|
	|	RegisterData.SourceOfARAPFinancialAccountingGroup.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.IncomeAndExpenseItem.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.RecordsCounterpartyIncomeExpenses AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;

EndFunction

Function QueryTextRecordsCounterpartyCounterparty()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.ARAPObject.Department AS ObjectOfCalculationsDivision,
	|	RegisterData.AmountType AS AmountType,
	|	
	|	RegisterData.CorLineOfBusiness AS CorLineOfBusiness,
	|	RegisterData.CorPartner AS CorPartner,
	|	RegisterData.CorCounterparty AS CorCounterparty,
	|	RegisterData.CorContract AS CorContract,
	|	RegisterData.CorARAPObject AS CorARAPObject,
	|	RegisterData.CorARAPObject.Department AS CorObjectOfCalculationsDivision,
	|	RegisterData.CorAmountType AS CorAmountType,
	|
	|	RegisterData.Sum AS Sum,
	|	RegisterData.AmountExcludingVAT AS AmountExcludingVAT,
	|	RegisterData.Sum - RegisterData.AmountExcludingVAT AS VATAmount,
	|	RegisterData.SumCompl AS SumCompl,
	|	RegisterData.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|	RegisterData.SumCompl - RegisterData.LocalAmountExcludingVAT AS VATAmountCompl,
	|
	|	RegisterData.Currency AS Currency,
	|	RegisterData.AmountInCurrency AS AmountInCurrency,
	|	RegisterData.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
	|	RegisterData.AmountInCurrency - RegisterData.AmountExcludingVATInCurrency AS NDSAmountInCurrency,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	RegisterData.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	RegisterData.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|	RegisterData.AmountInARAPCurrency - RegisterData.AmountExcludingVATInARAPCurrency AS AmountOfNDSInCurrencyOfMutualSettlements,
	|	
	|	RegisterData.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
	|	RegisterData.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|	RegisterData.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency,
	|	RegisterData.AdjAmountInARAPCurrency - RegisterData.AdjAmountExcludingVATInARAPCurrency AS CorAmountOfNDSInCurrencyOfMutualSettlements,
	|	
	|	RegisterData.SourceOfARAPFinancialAccountingGroup.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.CorSourceOfARAPFinancialAccountingGroup.FinancialAccountingGroup AS CorHFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.RecordsCounterpartyCounterparty AS RegisterData	
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.ARAPObject.Organization AS Organization,
	|	RegisterData.ARAPObject.Department AS Department,
	|
	|	RegisterData.CorARAPObject.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.CorARAPObject.Partner AS Partner,
	|	RegisterData.CorARAPObject.Counterparty AS Counterparty,
	|	RegisterData.CorARAPObject.Contract AS Contract,
	|	RegisterData.CorARAPObject AS ARAPObject,
	|	RegisterData.CorARAPObject.Department AS ObjectOfCalculationsDivision,
	|	VALUE(Enum.TypesOfDebtAmounts.PrepaymentToVendor) AS AmountType,
	|	
	|	RegisterData.ARAPObject.LineOfBusiness AS CorLineOfBusiness,
	|	RegisterData.ARAPObject.Partner AS CorPartner,
	|	RegisterData.ARAPObject.Counterparty AS CorCounterparty,
	|	RegisterData.ARAPObject.Contract AS CorContract,
	|	RegisterData.ARAPObject AS CorARAPObject,
	|	RegisterData.ARAPObject.Department AS CorObjectOfCalculationsDivision,
	|	VALUE(Enum.TypesOfDebtAmounts.PrepaymentToVendor) AS CorAmountType,
	|
	|	RegisterData.PrepaymentMan  AS Sum,
	|	RegisterData.PrepaymentMan  AS AmountExcludingVAT,
	|	RegisterData.PrepaymentMan  AS VATAmount,
	|	RegisterData.PrepaymentLocal AS SumCompl,
	|	RegisterData.PrepaymentLocal AS LocalAmountExcludingVAT,
	|	RegisterData.PrepaymentLocal AS VATAmountCompl,
	|
	|	RegisterData.Currency         AS Currency,
	|	RegisterData.Prepayment     AS AmountInCurrency,
	|	RegisterData.Prepayment     AS AmountExcludingVATInCurrency,
	|	RegisterData.Prepayment     AS NDSAmountInCurrency,
	|
	|	RegisterData.Currency         AS ARAPCurrency,
	|	RegisterData.Prepayment     AS AmountInARAPCurrency,
	|	RegisterData.Prepayment     AS AmountExcludingVATInARAPCurrency,
	|	RegisterData.Prepayment     AS AmountOfNDSInCurrencyOfMutualSettlements,
	|	
	|	RegisterData.Currency         AS CorCurrencyOfARAPAccounting,
	|	RegisterData.Prepayment     AS AdjAmountInARAPCurrency,
	|	RegisterData.Prepayment     AS AdjAmountExcludingVATInARAPCurrency,
	|	RegisterData.Prepayment     AS CorAmountOfNDSInCurrencyOfMutualSettlements,
	|	
	|	RegisterData.CorARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS CorHFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS RegisterData	
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.ARAPObject.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;

EndFunction

Function QueryTextRegisterRecordsProductsIncomeExpenses()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|
	|	RegisterData.LineOfBusinessItems AS LineOfBusinessItems,
	|	RegisterData.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	RegisterData.DimensionOfRevenue AS DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses AS DimensionOfExpenses,
	|	RegisterData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN RegisterData.IncomeAndExpenseItem REFS ChartOfCharacteristicTypes.IncomeItems
	|			THEN RegisterData.DimensionOfRevenue
	|		ELSE RegisterData.DimensionOfExpenses
	|	END AS RevenueExpenseAnalyticsDivision,
	|
	|	RegisterData.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	RegisterData.Products AS Products,
	|	RegisterData.Characteristic AS Characteristic,
	|	RegisterData.ItemsType AS ItemsType,
	|	RegisterData.Warehouse AS Warehouse,
	|	VALUETYPE(RegisterData.Warehouse) AS WarehouseStore,
	|	RegisterData.WarehouseDivision AS WarehouseDivision,
	|	RegisterData.Custodian AS Custodian,
	|	RegisterData.InventoryType AS InventoryType,
	|	RegisterData.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	RegisterData.InventoryOwnerAttribute.Counterparty AS Vendor,
	|
	|	SUM(RegisterData.Cost) AS Cost,
	|	SUM(RegisterData.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(RegisterData.Cost - RegisterData.CostExcludingVAT) AS VATAmount,
	|	SUM(RegisterData.CostMan) AS CostMan,
	|	SUM(RegisterData.LocalCost) AS LocalCost,
	|
	|	SUM(RegisterData.OffBalanceCost) AS OffBalanceCost,
	|	SUM(RegisterData.OffBalanceCostLocal) AS OffBalanceCostLocal,
	|
	|	SUM(RegisterData.AddExpensesForGoods) AS AddExpensesForGoods,
	|	SUM(RegisterData.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
	|	SUM(RegisterData.AddExpensesMan) AS AddExpensesMan,
	|	SUM(RegisterData.AddExpensesLocal) AS AddExpensesLocal,
	|
	|	SUM(RegisterData.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
	|	SUM(RegisterData.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
	|	SUM(RegisterData.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
	|	SUM(RegisterData.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
	|
	|	SUM(RegisterData.LaborCosts) AS LaborCosts,
	|	SUM(RegisterData.LaborCostsMan) AS LaborCostsMan,
	|	SUM(RegisterData.LaborCostsLocal) AS LaborCostsLocal,
	|
	|	SUM(RegisterData.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
	|	SUM(RegisterData.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
	|	SUM(RegisterData.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
	|	SUM(RegisterData.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
	|
	|	SUM(RegisterData.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
	|	SUM(RegisterData.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
	|
	|	SUM(RegisterData.Count) AS Count,
	|
	|	RegisterData.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
	|	RegisterData.HFCProducts AS HFCProducts,
	|	RegisterData.HFCRevenueExpenditure AS HFCRevenueExpenditure,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	RegisterData.ChartOfAccounts AS ChartOfAccounts,
	|	RegisterData.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	(SELECT
	|		RegisterData.Period AS Period,
	|		RegisterData.Recorder AS Recorder,
	|		RegisterData.BusinessOperation AS BusinessOperation,
	|		RegisterData.Organization AS Organization,
	|		RegisterData.Department AS Department,
	|
	|		RegisterData.LineOfBusinessItems AS LineOfBusinessItems,
	|		RegisterData.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|		RegisterData.DimensionOfRevenue AS DimensionOfRevenue,
	|		RegisterData.DimensionOfExpenses AS DimensionOfExpenses,
	|		RegisterData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|		RegisterData.ProductLineOfBusiness AS ProductLineOfBusiness,
	|		RegisterData.ItemsLocationAttributes.Products AS Products,
	|		RegisterData.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		RegisterData.ItemsLocationAttributes.Products.ItemsType AS ItemsType,
	|		RegisterData.ItemsLocationAttributes.Counterparty AS Custodian,
	|		RegisterData.Warehouse AS Warehouse,
	|		CASE
	|			WHEN RegisterData.Warehouse REFS Catalog.Warehouses
	|				THEN RegisterData.Warehouse.Department
	|			ELSE RegisterData.Warehouse
	|		END AS WarehouseDivision,
	|		RegisterData.InventoryType AS InventoryType,
	|		RegisterData.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|		RegisterData.Cost AS Cost,
	|		RegisterData.CostExcludingVAT AS CostExcludingVAT,
	|		CASE WHEN RegisterData.CostMan + RegisterData.AddExpensesMan + RegisterData.ItemizedFixedCostsManag + RegisterData.LaborCostsMan + RegisterData.ItemizedVariableCostsManag = 0
	|			THEN RegisterData.Cost + RegisterData.AddExpensesForGoods + RegisterData.ItemizedFixedCostsIncludingVAT + RegisterData.LaborCosts + RegisterData.ItemizedVariableCostsIncludingVAT
	|			ELSE RegisterData.CostMan + RegisterData.AddExpensesMan + RegisterData.ItemizedFixedCostsManag + RegisterData.LaborCostsMan + RegisterData.ItemizedVariableCostsManag
	|		END AS CostMan,
	|		RegisterData.LocalCost + RegisterData.AddExpensesLocal + RegisterData.ItemizedFixedCostsCompl + RegisterData.LaborCostsLocal + RegisterData.ItemizedVariableCostsCompl AS LocalCost,
	|
	|		RegisterData.OffBalanceCost AS OffBalanceCost,
	|		RegisterData.OffBalanceCostLocal AS OffBalanceCostLocal,
	|
	|		RegisterData.Count AS Count,
	|
	|		RegisterData.AddExpensesForGoods AS AddExpensesForGoods,
	|		RegisterData.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|		RegisterData.AddExpensesMan AS AddExpensesMan,
	|		RegisterData.AddExpensesLocal AS AddExpensesLocal,
	|
	|		RegisterData.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
	|		RegisterData.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|		RegisterData.ItemizedFixedCostsManag AS ItemizedFixedCostsManag,
	|		RegisterData.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
	|
	|		RegisterData.LaborCosts AS LaborCosts,
	|		RegisterData.LaborCostsMan AS LaborCostsMan,
	|		RegisterData.LaborCostsLocal AS LaborCostsLocal,
	|
	|		RegisterData.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
	|		RegisterData.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
	|		RegisterData.ItemizedVariableCostsManag AS ItemizedVariableCostsManag,
	|		RegisterData.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
	|
	|		RegisterData.ProvisionForImpairmentLocal AS ProvisionForImpairmentLocal,
	|		RegisterData.ProvisionForImpairmentMan AS ProvisionForImpairmentMan,
	|
	|		RegisterData.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
	|		RegisterData.SourceOfProductFinancialAccountingGroup.FinancialAccountingGroup AS HFCProducts,
	|		RegisterData.IncomeAndExpenseItem.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|		RegisterData.ReversingEntry AS ReversingEntry,
	|		DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|		DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|	FROM
	|		AccumulationRegister.RegisterRecordsProductsIncomeExpenses AS RegisterData
	|		INNER JOIN
	|			DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON
	|			RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|			AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|			AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|	WHERE
	|		RegisterData.Active
	|		AND NOT RegisterData.ReversingEntry
	|	) AS RegisterData
	|GROUP BY
	|	RegisterData.Period,
	|	RegisterData.Recorder,
	|	VALUETYPE(RegisterData.Recorder),
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusinessItems,
	|	RegisterData.IncomeAndExpenseItem,
	|	RegisterData.DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses,
	|	RegisterData.ProductLineOfBusiness,
	|	RegisterData.AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN RegisterData.IncomeAndExpenseItem REFS ChartOfCharacteristicTypes.IncomeItems
	|			THEN RegisterData.DimensionOfRevenue
	|		ELSE RegisterData.DimensionOfExpenses
	|	END,
	|	RegisterData.Products,
	|	RegisterData.Characteristic,
	|	RegisterData.ItemsType,
	|	RegisterData.Warehouse,
	|	VALUETYPE(RegisterData.Warehouse),
	|	RegisterData.WarehouseDivision,
	|	RegisterData.Custodian,
	|	RegisterData.InventoryType,
	|	RegisterData.InventoryOwnerAttribute,
	|	RegisterData.InventoryOwnerAttribute.Counterparty,
	|	RegisterData.SourceOfProductFinancialAccountingGroup,
	|	RegisterData.HFCProducts,
	|	RegisterData.HFCRevenueExpenditure,
	|	RegisterData.ChartOfAccounts,
	|	RegisterData.PostingGenerationSetting,
	|	RegisterData.ReversingEntry
	|HAVING
	|	SUM(RegisterData.Cost) <> 0
	|	OR SUM(RegisterData.CostExcludingVAT) <> 0
	|	OR SUM(RegisterData.Cost - RegisterData.CostExcludingVAT) <> 0
	|	OR SUM(RegisterData.CostMan) <> 0
	|	OR SUM(RegisterData.LocalCost) <> 0
	|	OR SUM(RegisterData.ProvisionForImpairmentLocal) <> 0
	|	OR SUM(RegisterData.ProvisionForImpairmentMan) <> 0
	|	OR SUM(RegisterData.Count) <> 0
	|";

	Return QueryText;

EndFunction

Function QueryTextRecordsProductsProducts()

	QueryText =
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.Products AS Products,
	|	RegisterData.Characteristic AS Characteristic,
	|	RegisterData.ItemsType AS ItemsType,
	|	RegisterData.Warehouse AS Warehouse,
	|	VALUETYPE(RegisterData.Warehouse) AS WarehouseStore,
	|	RegisterData.WarehouseDivision AS WarehouseDivision,
	|	RegisterData.Custodian AS Custodian,
	|
	|	RegisterData.InventoryType AS InventoryType,
	|	RegisterData.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	RegisterData.InventoryOwnerAttribute.Counterparty AS Vendor,
	|
	|	RegisterData.CorLineOfBusiness AS CorLineOfBusiness,
	|	RegisterData.CorNomenclature AS CorNomenclature,
	|	RegisterData.CorCharacteristics AS CorCharacteristics,
	|	RegisterData.CorTypeProducts AS CorTypeProducts,
	|	RegisterData.CorWarehouseCorCommissionAgentCorBusinessUnit AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	VALUETYPE(RegisterData.CorWarehouseCorCommissionAgentCorBusinessUnit) AS WarehouseCorType,
	|	RegisterData.CorWarehouseDivision AS CorWarehouseDivision,
	|	RegisterData.KorGuardian AS KorGuardian,
	|	RegisterData.CorInventoryType AS CorInventoryType,
	|	RegisterData.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	RegisterData.CorInventoryOwnerAttribute.Counterparty AS CorSupplier,
	|
	|	SUM(RegisterData.Cost) AS Cost,
	|	SUM(RegisterData.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(RegisterData.CostMan) AS CostMan,
	|	SUM(RegisterData.LocalCost) AS LocalCost,
	|
	|	SUM(RegisterData.OffBalanceCost) AS OffBalanceCost,
	|	SUM(RegisterData.OffBalanceCostLocal) AS OffBalanceCostLocal,
	|
	|	SUM(RegisterData.Count) AS Count,
	|	SUM(RegisterData.CorQuantity) AS CorQuantity,
	|
	|	SUM(RegisterData.AddExpensesForGoods) AS AddExpensesForGoods,
	|	SUM(RegisterData.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
	|	SUM(RegisterData.AddExpensesMan) AS AddExpensesMan,
	|	SUM(RegisterData.AddExpensesLocal) AS AddExpensesLocal,
	|
	|	SUM(RegisterData.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
	|	SUM(RegisterData.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
	|	SUM(RegisterData.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
	|	SUM(RegisterData.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
	|
	|	SUM(RegisterData.LaborCosts) AS LaborCosts,
	|	SUM(RegisterData.LaborCostsMan) AS LaborCostsMan,
	|	SUM(RegisterData.LaborCostsLocal) AS LaborCostsLocal,
	|
	|	SUM(RegisterData.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
	|	SUM(RegisterData.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
	|	SUM(RegisterData.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
	|	SUM(RegisterData.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
	|
	|	SUM(RegisterData.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
	|	SUM(RegisterData.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
	|
	|	RegisterData.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
	|	RegisterData.CorSourceOfItemsFinancialAccountingGroup AS CorSourceOfItemsFinancialAccountingGroup,
	|	RegisterData.HFCProducts AS HFCProducts,
	|	RegisterData.CorHFCProducts AS CorHFCProducts,
	|	RegisterData.CorCompany AS CorCompany,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	RegisterData.ChartOfAccounts AS ChartOfAccounts,
	|	RegisterData.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	(SELECT
	|		RegisterData.Period AS Period,
	|		RegisterData.Recorder AS Recorder,
	|		RegisterData.BusinessOperation AS BusinessOperation,
	|		RegisterData.Organization AS Organization,
	|		RegisterData.Department AS Department,
	|
	|		RegisterData.LineOfBusiness AS LineOfBusiness,
	|		RegisterData.ItemsLocationAttributes.Products AS Products,
	|		RegisterData.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		RegisterData.ItemsLocationAttributes.Products.ItemsType AS ItemsType,
	|		RegisterData.Warehouse AS Warehouse,
	|		CASE
	|			WHEN RegisterData.Warehouse REFS Catalog.Warehouses
	|				THEN RegisterData.Warehouse.Department
	|			ELSE RegisterData.Warehouse
	|		END AS WarehouseDivision,
	|		RegisterData.ItemsLocationAttributes.Counterparty AS Custodian,
	|		RegisterData.InventoryType AS InventoryType,
	|		RegisterData.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|		RegisterData.CorLineOfBusiness AS CorLineOfBusiness,
	|		RegisterData.CorItemsLocationAttributes.Products AS CorNomenclature,
	|		RegisterData.CorItemsLocationAttributes.Characteristic AS CorCharacteristics,
	|		RegisterData.CorItemsLocationAttributes.Products.ItemsType AS CorTypeProducts,
	|		RegisterData.CorWarehouseCorCommissionAgentCorBusinessUnit AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|		CASE
	|			WHEN RegisterData.Warehouse REFS Catalog.Warehouses
	|				THEN RegisterData.CorWarehouseCorCommissionAgentCorBusinessUnit.Department
	|			ELSE RegisterData.CorWarehouseCorCommissionAgentCorBusinessUnit
	|		END AS CorWarehouseDivision,  
	|		RegisterData.CorItemsLocationAttributes.Counterparty AS KorGuardian,
	|		RegisterData.CorInventoryType AS CorInventoryType,
	|		RegisterData.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|
	|		RegisterData.Cost AS Cost,
	|		RegisterData.CostExcludingVAT AS CostExcludingVAT,
	|		CASE WHEN RegisterData.CostMan + RegisterData.AddExpensesMan + RegisterData.ItemizedFixedCostsManag + RegisterData.LaborCostsMan + RegisterData.ItemizedVariableCostsManag = 0
	|			THEN RegisterData.Cost + RegisterData.AddExpensesForGoods + RegisterData.ItemizedFixedCostsIncludingVAT + RegisterData.LaborCosts + RegisterData.ItemizedVariableCostsIncludingVAT
	|			ELSE RegisterData.CostMan + RegisterData.AddExpensesMan + RegisterData.ItemizedFixedCostsManag + RegisterData.LaborCostsMan + RegisterData.ItemizedVariableCostsManag
	|		END AS CostMan,
	|		RegisterData.LocalCost + RegisterData.AddExpensesLocal + RegisterData.ItemizedFixedCostsCompl + RegisterData.LaborCostsLocal + RegisterData.ItemizedVariableCostsCompl AS LocalCost,
	|
	|		RegisterData.OffBalanceCost AS OffBalanceCost,
	|		RegisterData.OffBalanceCostLocal AS OffBalanceCostLocal,
	|
	|		RegisterData.Count AS Count,
	|		RegisterData.CorQuantity AS CorQuantity,
	|
	|		RegisterData.AddExpensesForGoods AS AddExpensesForGoods,
	|		RegisterData.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|		RegisterData.AddExpensesMan AS AddExpensesMan,
	|		RegisterData.AddExpensesLocal AS AddExpensesLocal,
	|
	|		RegisterData.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
	|		RegisterData.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|		RegisterData.ItemizedFixedCostsManag AS ItemizedFixedCostsManag,
	|		RegisterData.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
	|
	|		RegisterData.LaborCosts AS LaborCosts,
	|		RegisterData.LaborCostsMan AS LaborCostsMan,
	|		RegisterData.LaborCostsLocal AS LaborCostsLocal,
	|
	|		RegisterData.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
	|		RegisterData.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
	|		RegisterData.ItemizedVariableCostsManag AS ItemizedVariableCostsManag,
	|		RegisterData.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
	|
	|		RegisterData.ProvisionForImpairmentLocal AS ProvisionForImpairmentLocal,
	|		RegisterData.ProvisionForImpairmentMan AS ProvisionForImpairmentMan,
	|
	|		RegisterData.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
	|		RegisterData.CorSourceOfItemsFinancialAccountingGroup AS CorSourceOfItemsFinancialAccountingGroup,
	|		RegisterData.SourceOfProductFinancialAccountingGroup.FinancialAccountingGroup AS HFCProducts,
	|		RegisterData.CorSourceOfItemsFinancialAccountingGroup.FinancialAccountingGroup AS CorHFCProducts,
	|		RegisterData.CorCompany AS CorCompany,
	|		RegisterData.ReversingEntry AS ReversingEntry,
	|		DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|		DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|	FROM
	|		AccumulationRegister.RecordsProductsProducts AS RegisterData
	|		INNER JOIN
	|			DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON
	|			RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|			AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|			AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|	WHERE
	|		RegisterData.Active
	|		AND NOT RegisterData.ReversingEntry
	|	) RegisterData
	|GROUP BY
	|	RegisterData.Period,
	|	RegisterData.Recorder,
	|	VALUETYPE(RegisterData.Recorder),
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.Products,
	|	RegisterData.Characteristic,
	|	RegisterData.ItemsType,
	|	RegisterData.Warehouse,
	|	VALUETYPE(RegisterData.Warehouse),
	|	RegisterData.CorWarehouseDivision,
	|	RegisterData.WarehouseDivision, 
	|	RegisterData.Custodian,
	|	RegisterData.InventoryType,
	|	RegisterData.InventoryOwnerAttribute,
	|	RegisterData.InventoryOwnerAttribute.Counterparty,
	|	RegisterData.CorLineOfBusiness,
	|	RegisterData.CorNomenclature,
	|	RegisterData.CorCharacteristics,
	|	RegisterData.CorTypeProducts,
	|	RegisterData.CorWarehouseCorCommissionAgentCorBusinessUnit,  
	|	RegisterData.KorGuardian,  
	|	RegisterData.CorInventoryType,
	|	RegisterData.CorInventoryOwnerAttribute,
	|	RegisterData.CorInventoryOwnerAttribute.Counterparty,
	|	RegisterData.SourceOfProductFinancialAccountingGroup,
	|	RegisterData.CorSourceOfItemsFinancialAccountingGroup,
	|	RegisterData.HFCProducts,
	|	RegisterData.CorHFCProducts,
	|	RegisterData.CorCompany,
	|	RegisterData.ReversingEntry,
	|	RegisterData.ChartOfAccounts,
	|	RegisterData.PostingGenerationSetting
	|HAVING
	|	SUM(RegisterData.Cost) <> 0
	|	OR SUM(RegisterData.CostExcludingVAT) <> 0
	|	OR SUM(RegisterData.CostMan) <> 0
	|	OR SUM(RegisterData.LocalCost) <> 0
	|	OR SUM(RegisterData.ProvisionForImpairmentLocal) <> 0
	|	OR SUM(RegisterData.ProvisionForImpairmentMan) <> 0
	|	OR SUM(RegisterData.Count) <> 0
	|	OR SUM(RegisterData.CorQuantity) <> 0";
	
	Return QueryText;

EndFunction


Function QueryTextPurchases()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|
	|	RegisterData.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Products.ItemsType AS ItemsType,
	|	RegisterData.Warehouse AS Warehouse,
	|	CASE
	|		WHEN RegisterData.Warehouse REFS Catalog.Warehouses
	|			THEN RegisterData.Warehouse.Department
	|		ELSE RegisterData.Warehouse
	|	END AS WarehouseDivision,
	|	RegisterData.InventoryType AS InventoryType,
	|	RegisterData.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.InventoryOwnerAttribute.Counterparty AS Vendor,
	|	RegisterData.Terms AS Terms,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.OrderDocument AS OrderDocument,
	|	RegisterData.OrderDocument.Department AS OrderDivision,
	|	RegisterData.AdvanceHolder AS AdvanceHolder,
	|	
	|	RegisterData.Sum AS Sum,
	|	RegisterData.AmountExcludingVAT AS AmountExcludingVAT,
	|	RegisterData.Sum - RegisterData.AmountExcludingVAT AS VATAmount,
	|	RegisterData.SumCompl AS SumCompl,
	|	RegisterData.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|	RegisterData.SumCompl - RegisterData.LocalAmountExcludingVAT AS VATAmountCompl,
	|
	|	RegisterData.Cost AS Cost,
	|	RegisterData.CostExcludingVAT AS CostExcludingVAT,
	|	RegisterData.LocalCost AS LocalCost,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	RegisterData.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	RegisterData.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|	RegisterData.AmountInARAPCurrency - RegisterData.AmountExcludingVATInARAPCurrency AS AmountOfNDSInCurrencyOfMutualSettlements,
	|
	|	RegisterData.DocumentCurrency AS DocumentCurrency,
	|	RegisterData.AmountInDocumentCurrency AS AmountInDocumentCurrency,
	|	RegisterData.AmountExcludingVATInDocumentCurrency AS AmountExcludingVATInDocumentCurrency,
	|	RegisterData.AmountInDocumentCurrency - RegisterData.AmountExcludingVATInDocumentCurrency AS NDSAmountInDocumentCurrency,
	|
	|	RegisterData.Count AS Count,
	|
	|	RegisterData.SourceOfProductFinancialAccountingGroup.FinancialAccountingGroup AS HFCProducts,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.Purchases AS RegisterData
	|	INNER JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		RegisterData.ItemsLocationAttributes = Dimension.DimensionKey
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;

EndFunction

Function QueryTextCustomersARAPAccountingByDocuments()

	#Region CustomerPrepaymentSettlement
	QueryTextCustomerPrepaymentSettlement = 
	"// Offsetting of a client, offsetting of a fee-paying commissionaire
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	CASE WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.ConsignmentReportFromCustomer)
	|		THEN VALUE(Enum.BusinessTransactions.RemunerationOffsetAgainstCommissionAgentSAdvance)
	|		ELSE VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|	END AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.SalesOrder AS OrderDocument,
	|	RegisterData.SalesOrder.Department AS Department,
	|	RegisterData.SalesOrder.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.SalesOrder.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.PrepaymentLocal > 0 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RegisterData.Active";
	#EndRegion

	#Region ReversePrepaymentFromCustomer
	QueryTextReversePrepaymentFromCustomer = 
	"// ReversePrepaymentFromCustomer
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.ReversePrepaymentFromCustomer) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.SalesOrder AS OrderDocument,
	|	RegisterData.SalesOrder.Department AS Department,
	|	RegisterData.SalesOrder.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.SalesOrder.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.Recorder) IN (TYPE(Document.ReturnOfGoodsFromCustomer),
	|			TYPE(Document.SaleAdjustment))
	|	AND RegisterData.PrepaymentLocal > 0 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RegisterData.Active";
	#EndRegion

	#Region RemunerationOffsetWithCommissionAgentSPayment
	QueryTextRemunerationOffsetWithCommissionAgentSPayment = 
	"// RemunerationOffsetWithCommissionAgentSPayment
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.RemunerationOffsetWithCommissionAgentSPayment) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.SalesOrder AS OrderDocument,
	|	RegisterData.SalesOrder.Department AS Department,
	|	RegisterData.SalesOrder.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Debt AS Prepayment,
	|	RegisterData.ARAPMan AS PrepaymentMan,
	|	RegisterData.DebtLocal AS PrepaymentLocal,
	|
	|	RegisterData.SalesOrder.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.Recorder)  IN 
	|		(TYPE(Document.CommissionReportIntercompany),
	|		TYPE(Document.ConsignmentReportFromCustomer))
	|	AND RegisterData.DebtLocal > 0 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RegisterData.Active";
	#EndRegion

	TableTexts = New Array;
	TableTexts.Add(QueryTextCustomerPrepaymentSettlement);
	TableTexts.Add(QueryTextReversePrepaymentFromCustomer);
	TableTexts.Add(QueryTextRemunerationOffsetWithCommissionAgentSPayment);
	
	QueryText = StrConcat(TableTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Return QueryText;

EndFunction

Function QueryTextVendorsARAPAccountingByDocuments()

	#Region VendorPrepaymentSettlement
	
	QueryTextVendorPrepaymentSettlement = 
	"// VendorPrepaymentSettlement
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.PurchaseOrder AS OrderDocument,
	|
	|	RegisterData.PurchaseOrder.Department AS Department,
	|	RegisterData.PurchaseOrder.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.PurchaseOrder.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.PrepaymentLocal > 0 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RegisterData.Active
	|";
	#EndRegion

	#Region SettlementOfComplaintWithPrepayment
	QueryTextSettlementOfComplaintWithPrepayment = 
	"// SettlementOfComplaintWithPrepayment
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.SettlementOfComplaintWithPrepayment) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.PurchaseOrder AS OrderDocument,
	|
	|	RegisterData.PurchaseOrder.Department AS Department,
	|	RegisterData.PurchaseOrder.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.PurchaseOrder.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS RegisterData

	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.Recorder) IN (TYPE(Document.PurchaseAdjustment),
	|			TYPE(Document.ReturnOfGoodsToVendor))
	|	AND (VALUETYPE(RegisterData.PurchaseOrder.Object) <> TYPE(Document.ReturnOfGoodsToVendor)
	|		 OR RegisterData.PurchaseOrder = VALUE(Catalog.ARAPObjects.EmptyRef))
	|	AND RegisterData.PrepaymentLocal > 0 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RegisterData.Active";
	#EndRegion

	#Region MoveComplaintToARAPAccounting
	QueryTextMoveComplaintToARAPAccounting = 
	"// MoveComplaintToARAPAccounting
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.MoveComplaintToARAPAccounting) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.PurchaseOrder AS OrderDocument,
	|
	|	RegisterData.PurchaseOrder.Department AS Department,
	|	RegisterData.PurchaseOrder.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.PurchaseOrder.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.Recorder) = TYPE(Document.ReturnOfGoodsToVendor)
	|	AND RegisterData.DebtLocal > 0 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RegisterData.Active";
	#EndRegion

	#Region RemunerationOffsetWithPaymentToConsignor
	QueryTextRemunerationOffsetWithPaymentToConsignor = 
	"// RemunerationOffsetWithPaymentToConsignor
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.RemunerationOffsetWithPaymentToConsignor) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.PurchaseOrder AS OrderDocument,
	|
	|	RegisterData.PurchaseOrder.Department AS Department,
	|	RegisterData.PurchaseOrder.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Debt AS Prepayment,
	|	RegisterData.ARAPMan AS PrepaymentMan,
	|	RegisterData.DebtLocal AS PrepaymentLocal,
	|
	|	RegisterData.PurchaseOrder.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.Recorder) IN 
	|		(TYPE(Document.CommissionReportIntercompany),
	|		TYPE(Document.ConsignmentReportToVendor))
	|	AND RegisterData.DebtLocal > 0 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RegisterData.Active";
	#EndRegion

	TableTexts = New Array;
	TableTexts.Add(QueryTextVendorPrepaymentSettlement);
	TableTexts.Add(QueryTextSettlementOfComplaintWithPrepayment);
	TableTexts.Add(QueryTextMoveComplaintToARAPAccounting);
	TableTexts.Add(QueryTextRemunerationOffsetWithPaymentToConsignor);
	
	QueryText = StrConcat(TableTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Return QueryText;

EndFunction

Function QueryTextCustomersARAPAccountingByDueDates()

	#Region CustomerPrepaymentSettlement
	QueryTextCustomerPrepaymentSettlement = 
	"// Offsetting of a client, offsetting of a fee-paying commissionaire
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.DocumentRecorder) AS DocumentType,
	|	CASE WHEN VALUETYPE(RegisterData.DocumentRecorder) = TYPE(Document.ConsignmentReportFromCustomer)
	|		THEN VALUE(Enum.BusinessTransactions.RemunerationOffsetAgainstCommissionAgentSAdvance)
	|		ELSE VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|	END AS BusinessOperation,
	|
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS RegisterData
	|	INNER JOIN DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND (RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization)
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|	AND NOT RegisterData.ReversingEntry";
	#EndRegion

	#Region ReversePrepaymentFromCustomer
	QueryTextReversePrepaymentFromCustomer = 
	"// ReversePrepaymentFromCustomer
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.DocumentRecorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.ReversePrepaymentFromCustomer) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	CASE 
	|		WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN RegisterData.Prepayment
	|		ELSE -RegisterData.Prepayment
	|	END AS Prepayment,
	|	CASE 
	|		WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN RegisterData.PrepaymentMan
	|		ELSE -RegisterData.PrepaymentMan
	|	END AS PrepaymentMan,
	|	CASE 
	|		WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN RegisterData.PrepaymentLocal
	|		ELSE -RegisterData.PrepaymentLocal
	|	END AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.BusinessOperation IN(
	|			VALUE(Enum.BusinessTransactions.ARAPAdjustment),
	|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))
	|	AND RegisterData.PrepaymentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.ReversePrepaymentFromCustomer) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.ARAPObject.Currency AS Currency,
	|
	|	SUM(RegisterData.Prepayment) AS Prepayment,
	|	SUM(RegisterData.PrepaymentMan) AS PrepaymentMan,
	|	SUM(RegisterData.PrepaymentLocal) AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|
	|	RegisterData.ChartOfAccounts AS ChartOfAccounts,
	|	RegisterData.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	(SELECT
	|		DocumentsToBeReflected.Recorder AS Recorder,
	|		DocumentsToBeReflected.Period AS Period,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.Debt 
	|			ELSE CustomersARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.DebtLocal 
	|			ELSE CustomersARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.ARAPMan 
	|			ELSE CustomersARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.Prepayment 
	|			ELSE CustomersARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan,
	|		DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|		DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|	FROM
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|		INNER JOIN
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON
	|			DocumentsToBeReflected.Recorder = DocumentsRegistry.Ref
	|			AND DocumentsRegistry.ReverseTransactionCorrection
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|			
	|		INNER JOIN
	|			AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|		ON
	|			DocumentsRegistry.ReversedDocument = CustomersARAPAccountingByDueDates.DocumentRecorder
	|			AND DocumentsToBeReflected.Organization = CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization
	|			AND NOT CustomersARAPAccountingByDueDates.ReversingEntry
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentsToBeReflected.Recorder AS Recorder,
	|		DocumentsToBeReflected.Period AS Period,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.Debt 
	|			ELSE CustomersARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.DebtLocal 
	|			ELSE CustomersARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.ARAPMan 
	|			ELSE CustomersARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.Prepayment 
	|			ELSE CustomersARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan,
	|		DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|		DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|	FROM
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|			
	|		INNER JOIN
	|			AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|		ON
	|			DocumentsToBeReflected.Recorder = CustomersARAPAccountingByDueDates.DocumentRecorder
	|			AND DocumentsToBeReflected.Organization = CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization
	|			AND CustomersARAPAccountingByDueDates.ReversingEntry) AS RegisterData
	|
	|GROUP BY
	|	RegisterData.Recorder,
	|	RegisterData.Period,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject,
	|	RegisterData.ChartOfAccounts,
	|	RegisterData.PostingGenerationSetting
	|
	|HAVING
	|	SUM(RegisterData.Prepayment) <> 0
	|";
	#EndRegion

	#Region RemunerationOffsetWithCommissionAgentSPayment
	QueryTextRemunerationOffsetWithCommissionAgentSPayment = 
	"// RemunerationOffsetWithCommissionAgentSPayment
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.DocumentRecorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.RemunerationOffsetWithCommissionAgentSPayment) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Debt AS Prepayment,
	|	RegisterData.ARAPMan AS PrepaymentMan,
	|	RegisterData.DebtLocal AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.DocumentRecorder)  IN 
	|		(TYPE(Document.CommissionReportIntercompany),
	|		TYPE(Document.ConsignmentReportFromCustomer))
	|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.RemunerationOffsetWithCommissionAgentSPayment)
	|	AND RegisterData.DebtLocal > 0
	|	AND NOT RegisterData.ReversingEntry
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.DocumentRecorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.RemunerationOffsetWithCommissionAgentSPayment) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	-RegisterData.Debt AS Prepayment,
	|	-RegisterData.ARAPMan AS PrepaymentMan,
	|	-RegisterData.DebtLocal AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.DocumentRecorder)  IN 
	|		(TYPE(Document.CommissionReportIntercompany),
	|		TYPE(Document.ConsignmentReportFromCustomer))
	|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction)
	|	AND RegisterData.DebtLocal > 0
	|	AND NOT RegisterData.ReversingEntry";
	#EndRegion

	TableTexts = New Array;
	TableTexts.Add(QueryTextCustomerPrepaymentSettlement);
	TableTexts.Add(QueryTextReversePrepaymentFromCustomer);
	TableTexts.Add(QueryTextRemunerationOffsetWithCommissionAgentSPayment);
	
	QueryText = StrConcat(TableTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Return QueryText;

EndFunction

Function QueryTextVendorsARAPAccountingByDueDates()

	#Region VendorPrepaymentSettlement
	
	QueryTextVendorPrepaymentSettlement = 
	"// VendorPrepaymentSettlement
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.DocumentRecorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|	AND NOT RegisterData.ReversingEntry
	|";
	#EndRegion
	
	#Region ReversePrepaymentToVendor
	QueryTextReversePrepaymentToVendor = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.ReversePrepaymentToVendor) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.ARAPObject.Currency AS Currency,
	|
	|	SUM(RegisterData.Prepayment) AS Prepayment,
	|	SUM(RegisterData.PrepaymentMan) AS PrepaymentMan,
	|	SUM(RegisterData.PrepaymentLocal) AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	FALSE AS ReversingEntry,
	|
	|	RegisterData.ChartOfAccounts AS ChartOfAccounts,
	|	RegisterData.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	(SELECT
	|		DocumentsToBeReflected.Recorder AS Recorder,
	|		DocumentsToBeReflected.Period AS Period,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.Debt 
	|			ELSE VendorsARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.DebtLocal 
	|			ELSE VendorsARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.ARAPMan 
	|			ELSE VendorsARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.Prepayment 
	|			ELSE VendorsARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan,
	|		DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|		DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|	FROM
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|		INNER JOIN
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON
	|			DocumentsToBeReflected.Recorder = DocumentsRegistry.Ref
	|			AND DocumentsRegistry.ReverseTransactionCorrection
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|		INNER JOIN
	|			AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		ON
	|			DocumentsRegistry.ReversedDocument = VendorsARAPAccountingByDueDates.DocumentRecorder
	|			AND DocumentsToBeReflected.Organization = VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization
	|			AND NOT VendorsARAPAccountingByDueDates.ReversingEntry
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentsToBeReflected.Recorder AS Recorder,
	|		DocumentsToBeReflected.Period AS Period,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.Debt 
	|			ELSE VendorsARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.DebtLocal 
	|			ELSE VendorsARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.ARAPMan 
	|			ELSE VendorsARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.Prepayment 
	|			ELSE VendorsARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan,
	|		DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|		DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|	FROM
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|			
	|		INNER JOIN
	|			AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		ON
	|			DocumentsToBeReflected.Recorder = VendorsARAPAccountingByDueDates.DocumentRecorder
	|			AND DocumentsToBeReflected.Organization = VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization
	|			AND VendorsARAPAccountingByDueDates.ReversingEntry) AS RegisterData
	|
	|GROUP BY
	|	RegisterData.Recorder,
	|	RegisterData.Period,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject,
	|	RegisterData.ChartOfAccounts,
	|	RegisterData.PostingGenerationSetting
	|
	|HAVING
	|	SUM(RegisterData.Prepayment) <> 0
	|";
	#EndRegion
	
	#Region SettlementOfComplaintWithPrepayment
	QueryTextSettlementOfComplaintWithPrepayment = 
	"// SettlementOfComplaintWithPrepayment
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.DocumentRecorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.SettlementOfComplaintWithPrepayment) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.DocumentRecorder) IN (
	|			TYPE(Document.PurchaseAdjustment),
	|			TYPE(Document.ReturnOfGoodsToVendor),
	|			TYPE(Document.VendorInvoice),
	|			TYPE(Document.VendorInvoiceServicesAndAssets))
	|	AND (VALUETYPE(RegisterData.ARAPObject.Object) <> TYPE(Document.ReturnOfGoodsToVendor)
	|			OR RegisterData.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef))
	|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RegisterData.Active
	|	AND RegisterData.PrepaymentLocal > 0
	|	AND NOT RegisterData.ReversingEntry";
	#EndRegion

	#Region MoveComplaintToARAPAccounting
	QueryTextMoveComplaintToARAPAccounting = 
	"// MoveComplaintToARAPAccounting
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.DocumentRecorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.MoveComplaintToARAPAccounting) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|	RegisterData.ARAPObject AS OrderDocument,
	|
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Prepayment AS Prepayment,
	|	RegisterData.PrepaymentMan AS PrepaymentMan,
	|	RegisterData.PrepaymentLocal AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.DocumentRecorder) = TYPE(Document.ReturnOfGoodsToVendor)
	|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RegisterData.Active
	|	AND RegisterData.DebtLocal > 0
	|	AND NOT RegisterData.ReversingEntry";
	#EndRegion

	#Region RemunerationOffsetWithPaymentToConsignor
	QueryTextRemunerationOffsetWithPaymentToConsignor = 
	"// RemunerationOffsetWithPaymentToConsignor
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.DocumentRecorder AS Recorder,
	|	VALUETYPE(RegisterData.DocumentRecorder) AS DocumentType,
	|	VALUE(Enum.BusinessTransactions.RemunerationOffsetWithPaymentToConsignor) AS BusinessOperation,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|
	|	RegisterData.AccountingDimensionByPartners.Partner AS Partner,
	|	RegisterData.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
	|
	|	RegisterData.ARAPObject AS OrderDocument,
	|
	|	RegisterData.ARAPObject.Department AS Department,
	|	RegisterData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Currency AS Currency,
	|
	|	RegisterData.Debt AS Prepayment,
	|	RegisterData.ARAPMan AS PrepaymentMan,
	|	RegisterData.DebtLocal AS PrepaymentLocal,
	|
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS HFCCalculations,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS RegisterData
	|
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.DocumentRecorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.AccountingDimensionByPartners.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|WHERE
	|	VALUETYPE(RegisterData.DocumentRecorder) IN 
	|		(TYPE(Document.CommissionReportIntercompany),
	|		TYPE(Document.ConsignmentReportToVendor))
	|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RegisterData.Active
	|	AND RegisterData.DebtLocal > 0
	|	AND NOT RegisterData.ReversingEntry";
	#EndRegion

	TableTexts = New Array;
	TableTexts.Add(QueryTextVendorPrepaymentSettlement);
	TableTexts.Add(QueryTextReversePrepaymentToVendor);
	TableTexts.Add(QueryTextSettlementOfComplaintWithPrepayment);
	TableTexts.Add(QueryTextMoveComplaintToARAPAccounting);
	TableTexts.Add(QueryTextRemunerationOffsetWithPaymentToConsignor);
		
	QueryText = StrConcat(TableTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Return QueryText;

EndFunction

Function QueryTextFixedAssetsDepreciationCharge()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|
	|	RegisterData.FixedAsset AS FixedAsset,
	|	RegisterData.Department AS Department,
	|	RegisterData.FinancialAccountingGroup AS HFCSNonCurrentAssets,
	|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|
	|	RegisterData.CorCompany AS CorCompany,
	|	RegisterData.DebitBusinessUnit AS DebitBusinessUnit,
	|	RegisterData.CorLineOfBusiness AS CorLineOfBusiness,
	|	RegisterData.CorExpenseItem AS ExpenseItem,
	|	RegisterData.CorExpenseItem AS CorExpenseItem,
	|	RegisterData.CorExpenseItem.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|	RegisterData.CorExpenseItem.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	
	|	RegisterData.Depreciation,
	|	RegisterData.DepreciationLocal + RegisterData.FixedAssetDepreciationTargetFinancing AS DepreciationLocal,
	|
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|	LEFT JOIN
	|		OperationSettings AS OperationSettings
	|	ON
	|		RegisterData.BusinessOperation = OperationSettings.Operation
	|WHERE
	|	OperationSettings.DataSource = ""FixedAssetsDepreciationCharge""
	|	AND RegisterData.Active
	|	AND RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
	|	AND (RegisterData.Depreciation <> 0 OR RegisterData.DepreciationLocal + RegisterData.FixedAssetDepreciationTargetFinancing <> 0)
	|";
	
	Return QueryText;

EndFunction

Function QueryTextIntangibleAssetsAmortizationCharge()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|
	|	RegisterData.IntangibleAsset AS IntangibleAsset,
	|	RegisterData.Department AS Department,
	|	RegisterData.FinancialAccountingGroup AS HFCSNonCurrentAssets,
	|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|
	|	RegisterData.CorCompany AS CorCompany,
	|	RegisterData.DebitBusinessUnit AS DebitBusinessUnit,
	|	RegisterData.CorLineOfBusiness AS CorLineOfBusiness,
	|	RegisterData.CorExpenseItem AS ExpenseItem,
	|	RegisterData.CorExpenseItem AS CorExpenseItem,
	|	RegisterData.CorExpenseItem.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|	RegisterData.CorExpenseItem.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	
	|	RegisterData.Depreciation AS Depreciation,
	|	RegisterData.DepreciationLocal + RegisterData.FixedAssetDepreciationTargetFinancing AS DepreciationLocal,
	|
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.IntangibleAssetsAmortizationCharge AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|	LEFT JOIN
	|		OperationSettings AS OperationSettings
	|	ON
	|		RegisterData.BusinessOperation = OperationSettings.Operation
	|WHERE
	|	OperationSettings.DataSource = ""IntangibleAssetsAmortizationCharge""
	|	AND RegisterData.Active
	|	AND RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
	|	AND (RegisterData.Depreciation <> 0 OR RegisterData.DepreciationLocal + RegisterData.FixedAssetDepreciationTargetFinancing <> 0)
	|";
	
	Return QueryText;

EndFunction

Function QueryTextFACost()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|
	|	RegisterData.FixedAsset AS FixedAsset,
	|	RegisterData.Department AS Department,
	|	RegisterData.FinancialAccountingGroup AS HFCSNonCurrentAssets,
	|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.CorExpenseItem AS ExpenseItem,
	|	RegisterData.CorExpenseItem AS CorExpenseItem,
	|	RegisterData.CorExpenseItem.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|	RegisterData.CorExpenseItem.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	RegisterData.CorCounterparty AS Counterparty,
	|	
	|	RegisterData.Cost AS Cost,
	|	RegisterData.LocalCost + RegisterData.CostTargetFinancing AS LocalCost,
	|
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.FACost AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|	LEFT JOIN
	|		OperationSettings AS OperationSettings
	|	ON
	|		RegisterData.BusinessOperation = OperationSettings.Operation
	|WHERE
	|	OperationSettings.DataSource = ""FACost""
	|	AND RegisterData.Active
	|	AND RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
	|	AND (RegisterData.Cost <> 0 OR RegisterData.LocalCost + RegisterData.CostTargetFinancing <> 0)
	|";
	
	Return QueryText;

EndFunction

Function QueryTextIACost()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|
	|	RegisterData.IntangibleAsset AS IntangibleAsset,
	|	RegisterData.Department AS Department,
	|	RegisterData.FinancialAccountingGroup AS HFCSNonCurrentAssets,
	|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.CorExpenseItem AS ExpenseItem,
	|	RegisterData.CorExpenseItem AS CorExpenseItem,
	|	RegisterData.CorExpenseItem.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|	RegisterData.CorExpenseItem.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	
	|	RegisterData.Cost AS Cost,
	|	RegisterData.LocalCost + RegisterData.CostTargetFinancing AS LocalCost,
	|
	|	FALSE AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.IACost AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|	LEFT JOIN
	|		OperationSettings AS OperationSettings
	|	ON
	|		RegisterData.BusinessOperation = OperationSettings.Operation
	|WHERE
	|	OperationSettings.DataSource = ""IACost""
	|	AND RegisterData.Active
	|	AND RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
	|	AND (RegisterData.Cost <> 0 OR RegisterData.LocalCost + RegisterData.CostTargetFinancing <> 0)
	|";
	
	Return QueryText;

EndFunction

Function QueryTextOtherExpenses()

	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|
	|	RegisterData.Department AS Department,
	|	RegisterData.ExpenseItem.FinancialAccountingGroup AS HFCRevenueExpenditure,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|
	|	RegisterData.ExpenseItem AS ExpenseItem,
	|	RegisterData.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	RegisterData.Sum AS Sum,
	|	RegisterData.SumCompl AS SumCompl,
	|
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.OtherExpenses AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|	LEFT JOIN
	|		OperationSettings AS OperationSettings
	|	ON
	|		RegisterData.BusinessOperation = OperationSettings.Operation
	|WHERE
	|	OperationSettings.DataSource = ""OtherExpenses""
	|	AND RegisterData.Active
	|	AND RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
	|	AND (RegisterData.Sum <> 0 OR RegisterData.SumCompl <> 0)
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;

EndFunction

Function QueryTextVATPrepaymentsFromCustomer()
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessTransactionSetting.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.VATRate AS VATRate,
	|	RegisterData.DocumentPayments,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	
	|	RegisterData.VAT AS VAT,
	|	RegisterData.VATManag AS VATManag,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VATPrepaymentsFromCustomer AS RegisterData
	|	INNER JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflected
	|	ON
	|		RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|		AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|	LEFT JOIN
	|		OperationSettings AS OperationSettings
	|	ON
	|		RegisterData.BusinessTransactionSetting = OperationSettings.Ref
	|
	|WHERE
	|	OperationSettings.DataSource = ""VATPrepaymentsFromCustomer""
	|	AND RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry
	|";
	
	Return QueryText;
EndFunction

Function QueryTextVATPrepaymentsToVendor()
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessTransactionSetting.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.VATRate AS VATRate,
	|	RegisterData.DocumentPayments,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|
	|	RegisterData.VAT AS VAT,
	|	RegisterData.VATManag AS VATManag,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VATPrepaymentsToVendor AS RegisterData
	|		INNER JOIN DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|			AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|			AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|	LEFT JOIN
	|		OperationSettings AS OperationSettings
	|	ON
	|		RegisterData.BusinessTransactionSetting = OperationSettings.Ref
	|
	|WHERE
	|	OperationSettings.DataSource = ""VATPrepaymentsToVendor""
	|	AND RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry";
	
	Return QueryText;
	
EndFunction

Function QueryTextVATRegisterRecords()
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	VALUETYPE(RegisterData.Recorder) AS DocumentType,
	|	RegisterData.BusinessTransactionSetting.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.EntryType AS EntryType,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.TaxInvoice AS TaxInvoice,
	|	RegisterData.AssetTaxClass AS AssetTaxClass,
	|	RegisterData.VATRate AS VATRate,
	|	
	|	RegisterData.VAT AS VAT,
	|	RegisterData.VATManag AS VATManag,
	|	RegisterData.ReversingEntry AS ReversingEntry,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	AccumulationRegister.VATRegisterRecords AS RegisterData
	|		INNER JOIN DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON RegisterData.Recorder = DocumentsToBeReflected.Recorder
	|			AND RegisterData.Organization = DocumentsToBeReflected.Organization
	|			AND BEGINOFPERIOD(RegisterData.Period, DAY) = DocumentsToBeReflected.DateRecord
	|
	|	LEFT JOIN
	|		OperationSettings AS OperationSettings
	|	ON
	|		RegisterData.BusinessTransactionSetting = OperationSettings.Ref
	|
	|WHERE
	|	OperationSettings.DataSource = ""VATRegisterRecords""
	|	AND RegisterData.Active
	|	AND NOT RegisterData.ReversingEntry";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Translator

Procedure InitializeOperationSetupTable(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	BusinessTransactionsSettings.Ref AS Ref,
	|	BusinessTransactionsSettings.BusinessOperation AS Operation,
	|	BusinessTransactionsSettings.DataSource AS DataSource
	|INTO OperationSettings
	|FROM
	|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|WHERE
	|	BusinessTransactionsSettings.UseInFinancialAccounting = TRUE
	|	AND BusinessTransactionsSettings.IsFolder = FALSE
	|	AND BusinessTransactionsSettings.DeletionMark = FALSE
	|	AND BusinessTransactionsSettings.DataSource <> """"
	|";
	Query.Execute();
	
EndProcedure

Function InvoiceRefinementTable()

	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReflectionRules.PostingTemplate AS PostingTemplate,
	|	RulesForClarifyingInvoices.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RulesForClarifyingInvoices.RecordType AS RecordType,
	|	RulesForClarifyingInvoices.GLAccount AS GLAccount
	|FROM
	|	InformationRegister.RulesOfPostingsInFinancialAccounting AS ReflectionRules
	|		INNER JOIN InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting AS RulesForClarifyingInvoices
	|		ON ReflectionRules.PostingTemplate = RulesForClarifyingInvoices.PostingTemplate
	|";
	
	InvoiceRefinementTable = Query.Execute().Unload();
	InvoiceRefinementTable.Indexes.Add("PostingTemplate, FinancialAccountingGroup, RecordType");

	Return InvoiceRefinementTable;

EndFunction


Function ReflectionSettingsInInternationalAccounting()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PostingTemplates.Ref AS PostingTemplate,
	|	PostingTemplates.ThisIsTemplateGroup AS ThisIsTemplateGroup,
	|	PostingTemplates.Operation AS Operation,
	|	PostingTemplates.Operation.BusinessOperation AS BusinessOperation,
	|	PostingTemplates.JointApplicationOption AS JointApplicationOption,
	|	PostingTemplates.DrAccountDefault AS DrAccountDefault,
	|	PostingTemplates.CrAccountDefault AS CrAccountDefault,
	|	PostingTemplates.AccountSpecificationSourceTypeDr AS AccountSpecificationSourceDr,
	|	PostingTemplates.AccountSpecificationSourceTypeCr AS AccountSpecificationSourceCr,
	|	PostingTemplates.UnitSourceDr AS UnitSourceDr,
	|	PostingTemplates.UnitSourceCr AS UnitSourceCr,
	|	PostingTemplates.SourceOfDirectionDr AS SourceOfDirectionDr,
	|	PostingTemplates.SourceOfDirectionCr AS SourceOfDirectionCr,
	|	PostingTemplates.SourceOfAmountInCurrencyDr AS SourceOfAmountInCurrencyDr,
	|	PostingTemplates.SourceOfAmountInCurrencyCr AS SourceOfAmountInCurrencyCr,
	|	PostingTemplates.BookAmountSource AS BookAmountSource,
	|	PostingTemplates.ChangeTransactionSignWhileRecordingInAccounting AS ChangeOperationSign,
	|	PostingTemplates.ManualSpecificationOfEntry AS ManualSpecificationOfEntry,
	|	PostingTemplates.AdditionalSelection AS AdditionalSelection,
	|	PostingTemplates.AdditionalFilterIsSet AS AdditionalFilterIsSet,
	|	PostingTemplates.Ignore AS Ignore,
	|	PostingTemplates.PopulateExtraDimensionByCorrespondence AS PopulateExtraDimensionByCorrespondence,
	|	ReflectionRules.PostingGenerationSetting AS PostingGenerationSetting,
	|	CASE 
	|		WHEN &NewSettlementArchitecture AND OperationSettings.DataSource = ""CustomersARAPAccountingByDocuments""
	|			THEN ""CustomersARAPAccountingByDueDates""
	|		WHEN &NewSettlementArchitecture AND OperationSettings.DataSource = ""VendorsARAPAccountingByDocuments""
	|			THEN ""VendorsARAPAccountingByDueDates""
	|		ELSE
	|	    	OperationSettings.DataSource
	|	END AS DataSource,
	|	OperationSettings.Receipt = VALUE(Enum.AccountingDataTypes.Products) AS ProductMovementDr,
	|	OperationSettings.Expense = VALUE(Enum.AccountingDataTypes.Products) AS ProductMovementCr,
	|	PostingTemplates.Parent AS ParentPostingTemplate,
	|	PostingTemplates.Parent.Parent AS ParentPostingTemplate2,
	|	PostingTemplates.Parent.Parent.JointApplicationOption AS Level2JointApplicationOption,
	|	PostingTemplates.SourceOfQuantityDr AS SourceOfQuantityDr,
	|	PostingTemplates.SourceOfQuantityCr AS SourceOfQuantityCr
	|
	|FROM 
	|	Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|	LEFT JOIN
	|		InformationRegister.RulesOfPostingsInFinancialAccounting AS ReflectionRules
	|	ON
	|		PostingTemplates.Ref = ReflectionRules.PostingTemplate
	|	INNER JOIN
	|		Catalog.BusinessTransactionsSettings AS OperationSettings
	|	ON
	|		PostingTemplates.Operation = OperationSettings.Ref
	|WHERE
	|	NOT PostingTemplates.DeletionMark
	|	AND (NOT ReflectionRules.PostingGenerationSetting IS NULL OR PostingTemplates.ThisIsTemplateGroup)
	|
	|ORDER BY
	|	PostingTemplates.AddlOrderingAttribute HIERARCHY
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PopulationSettings.Ref AS PostingTemplate,
	|	PopulationSettings.ExtraDimensionPosition AS ExtraDimensionPosition,
	|	PopulationSettings.ExtDimensionType AS ExtDimensionType,
	|	PopulationSettings.FillInFromSource AS FillInFromSource,
	|	PopulationSettings.SpecifiedValue AS SpecifiedValue,
	|	PopulationSettings.Expression AS Expression,
	|	OperationSettings.DataSource AS DataSource
	|FROM
	|	Catalog.PostingTemplatesForFinancialAccounting.ExtraDimensionFillingSettings AS PopulationSettings
	|	INNER JOIN Catalog.BusinessTransactionsSettings AS OperationSettings
	|	ON PopulationSettings.Ref.Operation = OperationSettings.Ref
	|WHERE
	|	NOT PopulationSettings.Ref.DeletionMark
	|";
	
	Query.SetParameter("NewSettlementArchitecture", Constants.NewOnlineARAPAccounting.Get());
	Results = Query.ExecuteBatch();
	
	Settings = New Structure;
	Settings.Insert("PostingTemplates", Results[0].Unload(QueryResultIteration.ByGroupsWithHierarchy));
	Settings.Insert("ExtdimensionCompliance", Results[1].Unload());
	
	Return Settings;
	
EndFunction

Procedure ReflectRegisterData(RegisterName, QueryText, ParametersForGeneratingTransactions, TableOfTransactions);

	Query = New Query;
	Query.TempTablesManager = ParametersForGeneratingTransactions.TempTablesManager;
	Query.Text = QueryText;
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	OperationalAccountingData = Result.Unload();
	
	// Adding a key field
	OperationalAccountingData.Columns.Add("RowKey", New TypeDescription("Number"));
	OperationalAccountingData.Indexes.Add("RowKey");
	RowKey = 1;
	For Each String In OperationalAccountingData Do
		String.RowKey = RowKey;
		RowKey = RowKey + 1;
	EndDo;
	
	OperationalAccountingData.Columns.Add("Processed", New TypeDescription("Boolean"));
	OperationalAccountingData.Columns.Add("DisplacementGroup", New TypeDescription("CatalogRef.PostingTemplatesForFinancialAccounting"));
	
	UnreportedBusinessTransactions = UnreportedBusinessTransactions(OperationalAccountingData, TableOfTransactions, ParametersForGeneratingTransactions.EntryStructure);
	For Each UnreportedBusinessTransaction In UnreportedBusinessTransactions Do
		OperationalAccountingData.Delete(UnreportedBusinessTransaction);
	EndDo;
	
	ParametersForGeneratingTransactions.Insert("RegisterName", RegisterName);
	RegisterParameters = FinancialAccountingServerCached.RegisterParameters(RegisterName);
	If Not CheckWhetherIndicatorsAreCorrect(Result, RegisterName, RegisterParameters) Then
		Return;
	EndIf;
	ParametersForGeneratingTransactions.Insert("RegisterParameters", RegisterParameters);
	
	Filter = New Structure("DataSource", RegisterName);
	RegisterTemplates = ParametersForGeneratingTransactions.RecordSettings.PostingTemplates.Rows.FindRows(Filter);
	ParametersForGeneratingTransactions.Insert("PostingTemplates", RegisterTemplates);
	ParametersForGeneratingTransactions.Insert("ExtdimensionCompliance", ParametersForGeneratingTransactions.RecordSettings.ExtdimensionCompliance);
	ParametersForGeneratingTransactions.Insert("JointApplicationOption", Enums.OptionsOfJointApplicationOfPostingTemplates.All);
	ParametersForGeneratingTransactions.Insert("AdditionalGroupSelection", Undefined);
	
	DataCompositionSchema = LayoutSchemeOfOperationalAccountingData(OperationalAccountingData);
	
	ReflectOperationalAccountingDataRecursively(DataCompositionSchema,
		OperationalAccountingData,
		ParametersForGeneratingTransactions,
		TableOfTransactions);
		
	OperationalAccountingData.GroupBy("Recorder, BusinessOperation, ChartOfAccounts, PostingGenerationSetting, Organization, Period", "Processed");
	For Each Data In OperationalAccountingData Do
		If Not Data.Processed Then
			AccountingEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
			FillPropertyValues(AccountingEntry, Data);
			FinancialAccountingPostingServer.FillInTransactionStatus(AccountingEntry, Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined);
			ErrorText = NStr("vi = 'Không có mẫu bút toán cho giao dịch kinh doanh ""%BusinessOperation%"".';
							|ru = 'Для хозяйственной операции ""%BusinessOperation%"" отсутствуют шаблоны проводок.';
							|en = 'Posting templates are missing for the ""%BusinessOperation%"" business transaction.'; fa = 'Posting templates are missing for the ""%BusinessOperation%"" business transaction.';
							|it = 'Non sono disponibili modelli di registrazioni contabili per l''operazione economica ""%BusinessOperation%"".';
							|pl = 'Dla operacji gospodarczej ""%BusinessOperation%"" brakują szablony księgowań.';
							|tr = '""%BusinessOperation%"" ticari işlemi için deftere kayıt numunesi mevcut değil.'");
			ErrorText = StrReplace(ErrorText, "%BusinessOperation%", Data.BusinessOperation);
			FinancialAccountingPostingServer.AddTransactionError(AccountingEntry, ErrorText);
			FinancialAccountingPostingServer.AddTransactionToTransactionTable(TableOfTransactions, AccountingEntry);
			
			RecordManager = InformationRegisters.FinancialAccountingPostingTemplatesThatRequireSetup.CreateRecordManager();
			FillPropertyValues(RecordManager, Data);
			RecordManager.Document = Data.Recorder;
			RecordManager.Write();
			
		EndIf;
	EndDo;
	
EndProcedure

Function UnreportedBusinessTransactions(OperationalAccountingData, TableOfTransactions, EntryStructure)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	OperationalAccountingData.Period AS Period,
	|	OperationalAccountingData.RowKey AS RowKey,
	|	OperationalAccountingData.Organization AS Organization,
	|	OperationalAccountingData.BusinessOperation AS BusinessOperation,
	|	OperationalAccountingData.PostingGenerationSetting AS PostingGenerationSetting
	|INTO OperationalAccountingData
	|FROM
	|	&OperationalAccountingData AS OperationalAccountingData
	|INDEX BY
	|	BusinessOperation,
	|	PostingGenerationSetting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OperationalAccountingData.Period AS Period,
	|	OperationalAccountingData.RowKey AS RowKey,
	|	OperationalAccountingData.Organization AS Organization,
	|	OperationalAccountingData.BusinessOperation AS BusinessOperation,
	|	TRUE AS UseInFinancialAccounting
	|FROM
	|	OperationalAccountingData AS OperationalAccountingData
	|	INNER JOIN
	|		Catalog.BusinessTransactionsSettings AS BsnsTransactionsSettings
	|	ON
	|		OperationalAccountingData.BusinessOperation = BsnsTransactionsSettings.BusinessOperation
	|	INNER JOIN
	|		InformationRegister.BusinessTransactionsNotPostedInFinancialAccounting AS NonReflectedBusinessTransactions
	|	ON
	|		OperationalAccountingData.PostingGenerationSetting = NonReflectedBusinessTransactions.PostingGenerationSetting
	|		AND BsnsTransactionsSettings.Ref = NonReflectedBusinessTransactions.Operation
	|WHERE
	|	 BsnsTransactionsSettings.UseInFinancialAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	OperationalAccountingData.Period AS Period,
	|	OperationalAccountingData.RowKey AS RowKey,
	|	OperationalAccountingData.Organization AS Organization,
	|	OperationalAccountingData.BusinessOperation AS BusinessOperation,
	|	BsnsTransactionsSettings.UseInFinancialAccounting AS UseInFinancialAccounting
	|FROM
	|	OperationalAccountingData AS OperationalAccountingData
	|	INNER JOIN
	|		Catalog.BusinessTransactionsSettings AS BsnsTransactionsSettings
	|	ON
	|		OperationalAccountingData.BusinessOperation = BsnsTransactionsSettings.BusinessOperation
	|WHERE
	|	NOT BsnsTransactionsSettings.UseInFinancialAccounting
	|";
	
	Query.SetParameter("OperationalAccountingData", OperationalAccountingData);
	SelectionOfNonReflectedBusinessTransactions = Query.Execute().Select();
	UnreportedBusinessTransactions = New Array;
	While SelectionOfNonReflectedBusinessTransactions.Next() Do
		RegisterRecord = OperationalAccountingData.Find(SelectionOfNonReflectedBusinessTransactions.RowKey, "RowKey");
		UnreportedBusinessTransactions.Add(RegisterRecord);
		AccountingEntry = Common.CopyRecursive(EntryStructure);
		AccountingEntry.Recorder = RegisterRecord.Recorder;
		FillPropertyValues(AccountingEntry, SelectionOfNonReflectedBusinessTransactions);
		FinancialAccountingPostingServer.FillInTransactionStatus(AccountingEntry, Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting);
		ErrorText = NStr("vi = 'Giao dịch kinh tế ""%BusinessOperation%"" bị bỏ qua bởi tùy chỉnh tạo bút toán được áp dụng';
						|ru = 'Хозяйственная операция ""%BusinessOperation%"" игнорируется применяемой настройкой формирования проводок';
						|en = 'The ""%BusinessOperation%"" business transaction is ignored by the applied posting schema'; fa = 'The ""%BusinessOperation%"" business transaction is ignored by the applied posting schema';
						|it = 'Transazione economica ""%BusinessOperation%"" ignora l''impostazione applicabile di formazione delle transazioni';
						|pl = 'Operacja gospodarcza ""%BusinessOperation%"" jest ignorowana przez zastosowaną konfigurację formowania księgowań';
						|tr = '""%BusinessOperation%"" ticari işlemi, uygulanan kayıt oluşturma ayarı tarafından yok sayılır'");
		If Not SelectionOfNonReflectedBusinessTransactions.UseInFinancialAccounting Then
			ErrorText = NStr("vi = 'Giao dịch kinh doanh ""%BusinessOperation%"" không được sử dụng trong kế toán quốc tế.';
							|ru = 'Хозяйственная операция ""%BusinessOperation%"" не используется в международном учете.';
							|en = 'Business transaction ""%BusinessOperation%"" is not used in financial accounting.'; fa = 'Business transaction ""%BusinessOperation%"" is not used in financial accounting.';
							|it = 'Operazione commerciale ""%BusinessOperation%"" non utilizzato nella contabilità internazionale.';
							|pl = 'Operacja gospodarcza ""%BusinessOperation%"" nie jest używana w ewidencji międzynarodowej.';
							|tr = '""%BusinessOperation%"" ticari işlemi uluslararası muhasebede kullanılmıyor.'");
		EndIf;
		ErrorText = StrReplace(ErrorText, "%BusinessOperation%", SelectionOfNonReflectedBusinessTransactions.BusinessOperation);
		FinancialAccountingPostingServer.AddTransactionError(AccountingEntry, ErrorText);
		FinancialAccountingPostingServer.AddTransactionToTransactionTable(TableOfTransactions, AccountingEntry);
	EndDo;
	
	Return UnreportedBusinessTransactions;

EndFunction

Function LayoutSchemeOfOperationalAccountingData(OperationalAccountingData)

	DataCompositionSchema = FinancialReportingServer.NewSchemaSetObject("OperationalAccountingData");
	DataSet = DataCompositionSchema.DataSets.Find("OperationalAccountingData");
	
	Settings = DataCompositionSchema.DefaultSettings;
	NewGrouping = Settings.Structure.Add(Type("DataCompositionGroup"));
	NewGrouping.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	NewGrouping.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
	
	For Each Column In OperationalAccountingData.Columns Do
		FieldName = Column.Name;
		NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = FieldName;
		NewField.DataPath = FieldName;
		NewField.ValueType = Column.ValueType;
	EndDo;
	
	Return DataCompositionSchema;

EndFunction

Procedure ReflectOperationalAccountingDataRecursively(DataCompositionSchema, OperationalAccountingData, ParametersForGeneratingTransactions, TableOfTransactions)

	PostingTemplates = ParametersForGeneratingTransactions.PostingTemplates;
	ExtdimensionCompliance = ParametersForGeneratingTransactions.ExtdimensionCompliance;
	JointApplicationOption = ParametersForGeneratingTransactions.JointApplicationOption;
	AdditionalGroupSelection = ParametersForGeneratingTransactions.AdditionalGroupSelection;
	EntryStructure = ParametersForGeneratingTransactions.EntryStructure;
	
	Exclusion = Enums.OptionsOfJointApplicationOfPostingTemplates.Exclusion;
	ArrayOfDisplacedStrings = New Array;
	For Each PostingTemplate In PostingTemplates Do
		
		If PostingTemplate.ThisIsTemplateGroup Then
			If PostingTemplate.AdditionalFilterIsSet Then
				AdditionalSelection = New DataCompositionSettings;
				FilterValue = PostingTemplate.AdditionalSelection; //ValueStorage
				Filter_Settings = FilterValue.Get();
				FinancialReportingServer.CopyFilter(Filter_Settings.Filter, AdditionalSelection.Filter); 
				If AdditionalGroupSelection <> Undefined Then
					FinancialReportingServer.CopyFilter(AdditionalGroupSelection.Filter, AdditionalSelection.Filter); 
				EndIf;
			EndIf;
			GroupReflectionParameters = Common.CopyRecursive(ParametersForGeneratingTransactions);
			GroupReflectionParameters.Insert("PostingTemplates", PostingTemplate.Rows);
			GroupReflectionParameters.Insert("JointApplicationOption", PostingTemplate.JointApplicationOption);
			GroupReflectionParameters.Insert("AdditionalGroupSelection", AdditionalSelection);
			GroupReflectionParameters.Insert("EntryStructure", EntryStructure);
			
			ReflectOperationalAccountingDataRecursively(
				DataCompositionSchema, 
				OperationalAccountingData, 
				GroupReflectionParameters, 
				TableOfTransactions);
		Else
			
			Settings = New DataCompositionSettings;
			NewGrouping = Settings.Structure.Add(Type("DataCompositionGroup"));
			NewGrouping.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
			NewGrouping.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
			
			FinancialReportingServer.NewSelectionField(Settings, "RowKey");
			
			InvoiceRefinementTable  = ParametersForGeneratingTransactions.InvoiceRefinementTable;
			
			Indicators              = ParametersForGeneratingTransactions.RegisterParameters.Indicators;
			IndicatorsInCurrency       = ParametersForGeneratingTransactions.RegisterParameters.IndicatorsInCurrency;
			QuantityIndicators    = ParametersForGeneratingTransactions.RegisterParameters.QuantityIndicators;
			SourcesOfInvoiceRefinement = ParametersForGeneratingTransactions.RegisterParameters.SourcesOfInvoiceRefinement;
			SourcesOfDivisions  = ParametersForGeneratingTransactions.RegisterParameters.SourcesOfDivisions;
			SourcesOfDirections    = ParametersForGeneratingTransactions.RegisterParameters.SourcesOfDirections;
			SourcesOfExtdimension       = ParametersForGeneratingTransactions.RegisterParameters.SourcesOfExtdimension;
			
			PopulateExtraDimensionByCorrespondence = PostingTemplate.PopulateExtraDimensionByCorrespondence;
			If PopulateExtraDimensionByCorrespondence Then
				SourcesOfExtdimension = SetExtdimensionFillingByUserCompliance(
										DataCompositionSchema, 
										Settings, 
										PostingTemplate, 
										ExtdimensionCompliance);
			EndIf;
			
			SetDataSelectionByTransactionTemplate(
				DataCompositionSchema, 
				Settings, 
				PostingTemplate, 
				AdditionalGroupSelection,
				JointApplicationOption);
				
			ExternalSets = New Structure;
			ExternalSets.Insert("OperationalAccountingData", OperationalAccountingData);
			
			Try
				Result = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings, ExternalSets);
			Except
				MessageText = Chars.LF + NStr("vi = 'Không thể nhận dữ liệu để phản ánh giao dịch kinh tế ""%BusinessTransaction%""
											|theo khuôn mẫu bút toán ""%PostingTemplate%""
											|do nguyên nhân';
											|ru = 'Не удалось получить данные для отражения хозяйственной операции ""%BusinessTransaction%""
											|по шаблону проводки ""%PostingTemplate%""
											|по причине';
											|en = 'Cannot retrieve data to record the business transaction ""%BusinessTransaction%""
											|using the ""%PostingTemplate%"" posting template
											|.Reason:'; fa = 'Cannot retrieve data to record the business transaction ""%BusinessTransaction%""
											|using the ""%PostingTemplate%"" posting template
											|.Reason:';
											|it = 'Impossibile recuperare i dati per riflettere l''operazione economica ""%BusinessTransaction%""
											|dal modello di cablaggio ""%PostingTemplate%""
											|per un motivo';
											|pl = 'Nie udało się otrzymać dane do odzwierciedlenia operacji gospodarczej ""%BusinessTransaction%""
											|wg szablonu zaksięgowania ""%PostingTemplate%""
											|z powodu';
											|tr = '""%BusinessTransaction%"" kayıt numunesini 
											|""%PostingTemplate%"" ticari işlemini yansıtacak veriler şu nedenle alınamadı 
											|'") + ":" + Chars.LF + Chars.Tab + "%Cause%";
				MessageText = StrReplace(MessageText, "%BusinessTransaction%", PostingTemplate.BusinessOperation);
				MessageText = StrReplace(MessageText, "%PostingTemplate%", PostingTemplate.PostingTemplate);
				MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
				MessageText = MessageText + Chars.LF
					+ NStr("vi = 'Có thể trong mẫu bút toán đã thiết lập không chính xác bộ lọc bổ sung hoặc điền khoản mục.';
							|ru = 'Возможно в шаблоне проводки установлены некорректные настройки дополнительного отбора или заполнения субконто.';
							|en = 'Additional filter settings or extra dimension population settings may have been set incorrectly in the posting template.'; fa = 'Additional filter settings or extra dimension population settings may have been set incorrectly in the posting template.';
							|it = 'È possibile che il modello di transazione abbia impostazioni non corrette per la selezione o il riempimento secondario.';
							|pl = 'Możliwie, że w szablonie zaksięgowania są ustawione niepoprawne ustawienia selekcji dodatkowej lub wypełnienia subkonta.';
							|tr = 'Kayıt numunesinin ek filtre veya ekstra boyut doldurma için yanlış ayarları olması mümkündür.'");
				Raise MessageText;
			EndTry;
			
			For Each String In Result Do
				
				Filter = New Structure;
				Filter.Insert("RowKey", String.RowKey);
				Data = OperationalAccountingData.FindRows(Filter)[0];
				
				Data.Processed = True;
				
				If PostingTemplate.Ignore Then
					Continue;
				EndIf;
				
				If JointApplicationOption = Exclusion Then
					Data.DisplacementGroup = PostingTemplate.ParentPostingTemplate;
				EndIf;
				
				If PostingTemplate.Level() = 2
					And PostingTemplate.Level2JointApplicationOption = Exclusion Then
					ArrayOfDisplacedStrings.Add(Data);
				EndIf;
				
				AccountingEntry = Common.CopyRecursive(EntryStructure);
				FillPropertyValues(AccountingEntry, Data, "Period, Recorder, ChartOfAccounts, Organization, ReversingEntry");
				
				If PostingTemplate.ManualSpecificationOfEntry Then
					FinancialAccountingPostingServer.FillInTransactionStatus(AccountingEntry, Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting);
				EndIf;
				
				AccountingEntry.PostingTemplate = PostingTemplate.PostingTemplate;
				
				BookAmountSource = PostingTemplate.BookAmountSource;
				If Not ValueIsFilled(BookAmountSource) Then
					FinancialAccountingPostingServer.FillInTransactionStatus(AccountingEntry, Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined);
					ErrorText = NStr("vi = 'Không có nguồn mang theo được chọn.';
									|ru = 'Не выбран источник балансовой суммы.';
									|en = 'Book amount source is not selected.'; fa = 'Book amount source is not selected.';
									|it = 'Non è selezionata l''origine del saldo.';
									|pl = 'Nie jest wybrane źródło sumy bilansowej.';
									|tr = 'Bilanço tutarı kaynağı seçilmedi.'");
					FinancialAccountingPostingServer.AddTransactionError(AccountingEntry, ErrorText);
				Else
					Resources = Indicators.Get(BookAmountSource).Resources;
					
					AccountingCurrenciesOnChartOfAccounts = FinancialAccountingServerCached.AccountingCurrencies(Data.ChartOfAccounts, Data.Organization);
					
					FunctionalSum = FunctionalSum(Data, PostingTemplate, Resources, AccountingCurrenciesOnChartOfAccounts); 
					AccountingEntry.Sum = FunctionalSum.Sum;
					AccountingEntry.CurrencyOfStorageOfAmount = FunctionalSum.Currency;
					AccountingEntry.CurrencyFunctional = AccountingCurrenciesOnChartOfAccounts.Functional;
					
					PresentationAmount = PresentationAmount(Data, PostingTemplate, Resources, AccountingCurrenciesOnChartOfAccounts);
					AccountingEntry.PresentationAmount = PresentationAmount.Sum;
					AccountingEntry.PresentationAmountStorageCurrency = PresentationAmount.Currency;
					If PresentationAmount.Sum = 0 Then
						AccountingEntry.PresentationAmount = FunctionalSum.Sum;
						AccountingEntry.PresentationAmountStorageCurrency = FunctionalSum.Currency;
					EndIf;
					AccountingEntry.PresentationCurrency = AccountingCurrenciesOnChartOfAccounts.Presentations;
				EndIf;
					
				AccountingEntry.AccountDr = GLAccount(Data, PostingTemplate, InvoiceRefinementTable, SourcesOfInvoiceRefinement, "Dr");
				AccountingEntry.AccountCr = GLAccount(Data, PostingTemplate, InvoiceRefinementTable, SourcesOfInvoiceRefinement, "Cr");
				
				AccountPropertiesDr = FinancialAccountingServerCached.AccountProperties(AccountingEntry.AccountDr);
				If AccountPropertiesDr.Currency1 Then
					SourceOfAmountInCurrencyDr = PostingTemplate.SourceOfAmountInCurrencyDr;
					If Not ValueIsFilled(SourceOfAmountInCurrencyDr) Then
						FinancialAccountingPostingServer.FillInTransactionStatus(AccountingEntry, Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined);
						ErrorText = NStr("vi = 'Chưa chọn nguồn số tiền tiền tệ Nợ.';
										|ru = 'Не выбран источник валютной суммы Дт.';
										|en = 'Dr currency amount source is not selected.'; fa = 'Dr currency amount source is not selected.';
										|it = 'Non è selezionata l''importo in valuta a debito.';
										|pl = 'Nie jest wybrane źródło kwoty walutowej Wn.';
										|tr = 'BÇ döviz tutarı kaynağı seçilmedi.'");
						FinancialAccountingPostingServer.AddTransactionError(AccountingEntry, ErrorText);
					Else
						SourceOfCurrencyDr = IndicatorsInCurrency.Get(SourceOfAmountInCurrencyDr).SourceOfCurrency;
						AccountingEntry.CurrencyDr = Data[SourceOfCurrencyDr];
						AccountingEntry.CurrencyAmountDr = AmountInCurrency(Data, PostingTemplate, Resources, SourceOfCurrencyDr);
					EndIf;
				Else
					AccountingEntry.CurrencyDr = Catalogs.Currencies.EmptyRef();
					AccountingEntry.CurrencyAmountDr = 0;
				EndIf;
				
				AccountPropertiesCr = FinancialAccountingServerCached.AccountProperties(AccountingEntry.AccountCr);
				If AccountPropertiesCr.Currency1 Then
					SourceOfAmountInCurrencyCr = PostingTemplate.SourceOfAmountInCurrencyCr;
					If Not ValueIsFilled(SourceOfAmountInCurrencyCr) Then
						FinancialAccountingPostingServer.FillInTransactionStatus(AccountingEntry, Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined);
						ErrorText = NStr("vi = 'Chưa chọn nguồn gốc của số lượng tiền tệ Có.';
										|ru = 'Не выбран источник валютной суммы Кт.';
										|en = 'Cr currency amount source is not selected.'; fa = 'Cr currency amount source is not selected.';
										|it = 'Non è selezionata l''importo in valuta a credito.';
										|pl = 'Nie wybrano źródła kwoty walutowej Ma.';
										|tr = 'AC döviz tutarı kaynağı seçilmedi.'");
						FinancialAccountingPostingServer.AddTransactionError(AccountingEntry, ErrorText);
					Else
						SourceOfCurrencyCr = IndicatorsInCurrency.Get(SourceOfAmountInCurrencyCr).SourceOfCurrency;
						AccountingEntry.CurrencyCr = Data[SourceOfCurrencyCr];
						AccountingEntry.CurrencyAmountCr = AmountInCurrency(Data, PostingTemplate, Resources, SourceOfCurrencyCr);
					EndIf;
				Else
					AccountingEntry.CurrencyCr = Catalogs.Currencies.EmptyRef();
					AccountingEntry.CurrencyAmountCr = 0;
				EndIf;
				
				If AccountPropertiesDr.AccountingByBusinessUnits Then
					AccountingEntry.DepartmentDr = DimensionValue(Data, SourcesOfDivisions, PostingTemplate.UnitSourceDr);
				EndIf;
				If AccountPropertiesCr.AccountingByBusinessUnits Then
					AccountingEntry.DepartmentCr = DimensionValue(Data, SourcesOfDivisions, PostingTemplate.UnitSourceCr);
				EndIf;
				
				If AccountPropertiesDr.AccountingByLinesOfBusiness Then
					AccountingEntry.LineOfBusinessDr = DimensionValue(Data, SourcesOfDirections, PostingTemplate.SourceOfDirectionDr);
				EndIf;
				If AccountPropertiesCr.AccountingByLinesOfBusiness Then
					AccountingEntry.LineOfBusinessCr = DimensionValue(Data, SourcesOfDirections, PostingTemplate.SourceOfDirectionCr);
				EndIf;
				
				AccountPropertiesDr = FinancialAccountingServerCached.AccountProperties(AccountingEntry.AccountDr);
				If AccountPropertiesDr.Quantitative And ValueIsFilled(PostingTemplate.SourceOfQuantityDr) Then
					CountDr = DimensionValue(Data, QuantityIndicators, PostingTemplate.SourceOfQuantityDr);
					AccountingEntry.CountDr = ?(PostingTemplate.ChangeOperationSign, -CountDr, CountDr);
				EndIf;
				
				AccountPropertiesCr = FinancialAccountingServerCached.AccountProperties(AccountingEntry.AccountCr);
				If AccountPropertiesCr.Quantitative And ValueIsFilled(PostingTemplate.SourceOfQuantityCr) Then
					CountCr = DimensionValue(Data, QuantityIndicators, PostingTemplate.SourceOfQuantityCr);
					AccountingEntry.CountCr = ?(PostingTemplate.ChangeOperationSign, -CountCr, CountCr);
				EndIf;
				
				AccountingEntry.Insert("TransactionTemplateData", PostingTemplate);
				
				ExtdimensionData = New Structure;
				ExtdimensionData.Insert("AccountingEntry", AccountingEntry);
				ExtdimensionData.Insert("Data", Data);
				ExtdimensionData.Insert("SourcesOfExtdimension", SourcesOfExtdimension);
				ExtdimensionData.Insert("AccountPropertiesDr", AccountPropertiesDr);
				ExtdimensionData.Insert("AccountPropertiesCr", AccountPropertiesCr);
				ExtdimensionData.Insert("RegisterName", ParametersForGeneratingTransactions.RegisterName);
				ExtdimensionData.Insert("CaseSynonym", PostingTemplate.Operation.DataSourcePresentation);
				If PopulateExtraDimensionByCorrespondence Then
					ExtdimensionData.Data = String;
				EndIf;
				FillExtdimension("Dr", ExtdimensionData);
				FillExtdimension("Cr", ExtdimensionData);
				
				CheckTransactionCompletion(AccountingEntry, PostingTemplate, ParametersForGeneratingTransactions.RegisterParameters);
				
				FinancialAccountingPostingServer.AddTransactionToTransactionTable(TableOfTransactions, AccountingEntry);
			EndDo;
		EndIf;
	EndDo;
	
	For Each DisplacedString In ArrayOfDisplacedStrings Do
		DisplacedString.DisplacementGroup = PostingTemplates.Parent.Parent.PostingTemplate
	EndDo;

EndProcedure

Function SetExtdimensionFillingByUserCompliance(DataCompositionSchema, Settings, PostingTemplate, ExtdimensionCompliance)
	
	DataCompositionSchema.CalculatedFields.Clear();
	
	CalculatedFieldsToRefine = New Array; // Array of DataCompositionSchemaCalculatedField - 
	
	Filter = New Structure;
	Filter.Insert("PostingTemplate", PostingTemplate.PostingTemplate);
	Filter.Insert("ExtraDimensionPosition");
	
	ExtdimensionProvisions = New Array;
	ExtdimensionProvisions.Add("Dr");
	ExtdimensionProvisions.Add("Cr");
	
	SourcesOfExtdimension = New Structure;
	SourcesOfExtdimension.Insert("ExtDimensionDr", New Array);
	SourcesOfExtdimension.Insert("ExtDimensionCr", New Array);
	For Each ExtraDimensionPosition In ExtdimensionProvisions Do
		Filter.ExtraDimensionPosition = ExtraDimensionPosition;
		PopulationSettings = ExtdimensionCompliance.FindRows(Filter);
		
		SettingNumber = 1;
		SourceFields = SourcesOfExtdimension["ExtDimension"+ExtraDimensionPosition]; // Array -
		For Each Setting In PopulationSettings Do
			DataPath = "ExtdimensionInternational_" + ExtraDimensionPosition + "_N" + SettingNumber;
			Expression = FinancialAccountingPostingServer.ExpressionOfExtdimensionFillingBySetting(DataCompositionSchema, Setting);
			
			FieldToEval = FinancialReportingServer.NewCalculatedField(DataCompositionSchema, DataPath, Expression); 
			FinancialReportingServer.NewSelectionField(Settings, DataPath);
			
			If Setting.FillInFromSource
				And StrFind(Expression, "{") > 0 Then
				// There Are Characteristics
				CalculatedFieldsToRefine.Add(FieldToEval);
			EndIf;
			
			SourceFields.Add(DataPath);
			SettingNumber = SettingNumber + 1;
		EndDo;
	EndDo;
	
	If CalculatedFieldsToRefine.Count() > 0 Then
		OriginalExpressions = New Array;
		For Each FieldToEval In CalculatedFieldsToRefine Do
			If OriginalExpressions.Find(FieldToEval.Expression) = Undefined Then
				OriginalExpressions.Add(FieldToEval.Expression);
			EndIf;
		EndDo;
		ConversionResult = ProcessingOfFormulas.DataForObtainingFormulaExpressionsViaDCS(DataCompositionSchema,
			OriginalExpressions);
		If ConversionResult.HasErrors Then
			ErrorsTexts = New Array;
			For Each OriginalExpressionAndErrorText In ConversionResult.ConversionErrorMessages Do
				ErrorsTexts.Add(OriginalExpressionAndErrorText.Value);
			EndDo;
			AllErrorsText = StrConcat(ErrorsTexts, Chars.LF);
			MessageText = NStr("vi = 'Không thể nhận dữ liệu để phản ánh giao dịch kinh tế ""%1""
											|theo khuôn mẫu bút toán ""%2""
											|do nguyên nhân:
											|	%3';
											|ru = 'Не удалось получить данные для отражения хозяйственной операции ""%1""
											|по шаблону проводки ""%2""
											|по причине:
											|	%3';
											|en = 'Cannot get data to record the business transaction ""%1""
											|using posting template ""%2""
											|. Reason:
											|	%3'; fa = 'Cannot get data to record the business transaction ""%1""
											|using posting template ""%2""
											|. Reason:
											|	%3';
											|it = 'Impossibile recuperare i dati per riportare l''operazione economica ""%1""
											| secondo il modello di registrazione ""%2""
											| a causa di:
											|	%3';
											|pl = 'Nie udało się otrzymać danych do odzwierciedlenia operacji gospodarczej ""%1""
											|wg szablonu zaksięgowania ""%2""
											|z powodu:
											|	%3';
											|tr = '""%2""
											| kayıt numunesini
											| ""%1"" ticari işlemini yansıtacak veriler şu nedenle alınamadı:
											|	%3'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
				PostingTemplate.BusinessOperation,
				PostingTemplate.PostingTemplate,
				AllErrorsText);
			Raise MessageText;
		EndIf;
		ConvertedExpressions = ConversionResult.ConvertedExpressions;
		For Each FieldToEval In CalculatedFieldsToRefine Do
			ReplacingExpression = ConvertedExpressions.Get(FieldToEval.Expression);
			FieldToEval.Expression = ReplacingExpression;
		EndDo;
	EndIf;
	
	Return SourcesOfExtdimension;
	
EndFunction

Procedure SetDataSelectionByTransactionTemplate(DataCompositionSchema, Settings, PostingTemplate, AdditionalGroupSelection, JointApplicationOption)
	
	DataCompositionClientServer.AddFilter(Settings, "BusinessOperation", PostingTemplate.BusinessOperation);
	DataCompositionClientServer.AddFilter(Settings, "PostingGenerationSetting", PostingTemplate.PostingGenerationSetting);
	
	If AdditionalGroupSelection <> Undefined Then
		FinancialReportingServer.CopyFilter(AdditionalGroupSelection.Filter, Settings.Filter);
	EndIf;
	
	If PostingTemplate.AdditionalFilterIsSet Then
		FilterValue = PostingTemplate.AdditionalSelection; //ValueStorage
		Filter_Settings = FilterValue.Get();
		FinancialReportingServer.CopyFilter(Filter_Settings.Filter, Settings.Filter);
	EndIf;
	
	Level = PostingTemplate.Level();
	
	If Level = 1 And JointApplicationOption = Enums.OptionsOfJointApplicationOfPostingTemplates.Exclusion Then
		GroupOfSelectionElementsOr = Settings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		GroupOfSelectionElementsOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		DataCompositionClientServer.AddFilter(GroupOfSelectionElementsOr,
			"Processed",
			False,
			DataCompositionComparisonType.Equal);
		DataCompositionClientServer.AddFilter(GroupOfSelectionElementsOr,
			"DisplacementGroup",
			PostingTemplate.ParentPostingTemplate,
			DataCompositionComparisonType.NotEqual);
	EndIf;
	
	If Level = 2 Then
		If JointApplicationOption = Enums.OptionsOfJointApplicationOfPostingTemplates.All Then
			GroupOfSelectionElementsOr = Settings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			GroupOfSelectionElementsOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			DataCompositionClientServer.AddFilter(GroupOfSelectionElementsOr,
				"Processed",
				False,
				DataCompositionComparisonType.Equal);
			DataCompositionClientServer.AddFilter(GroupOfSelectionElementsOr,
				"DisplacementGroup",
				PostingTemplate.ParentPostingTemplate2,
				DataCompositionComparisonType.NotEqual);
		Else
			GroupOfSelectionElementsOr = Settings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			GroupOfSelectionElementsOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			DataCompositionClientServer.AddFilter(GroupOfSelectionElementsOr,
				"Processed",
				False,
				DataCompositionComparisonType.Equal);
			GroupOfSelectionElementsAnd = GroupOfSelectionElementsOr.Items.Add(Type("DataCompositionFilterItemGroup"));
			GroupOfSelectionElementsAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			DataCompositionClientServer.AddFilter(GroupOfSelectionElementsAnd,
				"DisplacementGroup",
				PostingTemplate.ParentPostingTemplate,
				DataCompositionComparisonType.NotEqual);
			DataCompositionClientServer.AddFilter(GroupOfSelectionElementsAnd,
				"DisplacementGroup",
				PostingTemplate.ParentPostingTemplate2,
				DataCompositionComparisonType.NotEqual);
		EndIf;
	EndIf;
	
EndProcedure


// LongDesc
// 
// Parameters:
// 	QueryResult - QueryResult, Undefined - LongDesc
// 	RegisterName - String -
// 	RegisterParameters - See FinancialAccountingServerCached.RegisterParameters
// Returns:
// 	Boolean - LongDesc
Function CheckWhetherIndicatorsAreCorrect(QueryResult, RegisterName, RegisterParameters)

	Indicators				= RegisterParameters.Indicators; // See FinancialAccountingServerCached.Indicators
	IndicatorsInCurrency		= RegisterParameters.IndicatorsInCurrency;

	ResultColumns = QueryResult.Columns;
	ErrorsArray = New Array;
	For Each Factor In Indicators Do
		ArrayOfResources = Factor.Value.Resources; // See DescriptionOfResources
		For Each Resource In ArrayOfResources Do
			ResourceName = Resource.Name;
			If ResultColumns.Find(ResourceName) = Undefined Then
				ErrorText = NStr("vi = 'Không tìm thấy tài nguyên ""%ResourceName%"" của số liệu ""%Factor%"".';
								|ru = 'Не найден ресурс ""%ResourceName%"" показателя ""%Factor%"".';
								|en = 'Resource ""%ResourceName%"" of indicator ""%Factor%"" is not found.'; fa = 'Resource ""%ResourceName%"" of indicator ""%Factor%"" is not found.';
								|it = 'Non è stata trovata la risorsa ""%ResourceName%"" dell''indicatore ""%Factor%"".';
								|pl = 'Nie jest znaleziony zasób ""%ResourceName%"" wskaźnika ""%Factor%"".';
								|tr = '""%Factor%"" göstergesinin ""%ResourceName%"" kaynağı bulunamadı.'");
				ErrorText = StrReplace(ErrorText, "%ResourceName%", ResourceName);
				ErrorText = StrReplace(ErrorText, "%Factor%", Factor.Key);
				ErrorsArray.Add(ErrorText);
			EndIf;
			SourceOfCurrency = Resource.SourceOfCurrency;
			If SourceOfCurrency <> "CurrencyOfMan" And SourceOfCurrency <> "ComplCurrency"
				And ResultColumns.Find(SourceOfCurrency) = Undefined Then
				ErrorText = NStr("vi = 'Không tìm thấy nguồn tiền tệ ""%SourceOfCurrency%"" của chỉ số ""%Factor%"".';
								|ru = 'Не найден источник валюты ""%SourceOfCurrency%"" показателя ""%Factor%"".';
								|en = 'Currency source ""%SourceOfCurrency%"" of indicator ""%Factor%"" is not found.'; fa = 'Currency source ""%SourceOfCurrency%"" of indicator ""%Factor%"" is not found.';
								|it = 'Fonte di valuta non trovata ""%SourceOfCurrency%"" dell''indicatore ""%Factor%"".';
								|pl = 'Nie jest znalezione źródło waluty ""%SourceOfCurrency%"" wskaźnika ""%Factor%"".';
								|tr = '""%Factor%"" göstergesinin ""%SourceOfCurrency%"" para birimi kaynağı bulunamadı.'");
				ErrorText = StrReplace(ErrorText, "%SourceOfCurrency%", SourceOfCurrency);
				ErrorText = StrReplace(ErrorText, "%Factor%", Factor.Key);
				ErrorsArray.Add(ErrorText);
			EndIf;
		EndDo;
	EndDo;
	
	For Each Factor In IndicatorsInCurrency Do
		SourceOfCurrency = Factor.Value.SourceOfCurrency;
		If SourceOfCurrency <> "CurrencyOfMan" And SourceOfCurrency <> "ComplCurrency"
			And ResultColumns.Find(SourceOfCurrency) = Undefined Then
			ErrorText = NStr("vi = 'Không tìm thấy nguồn tiền tệ ""%SourceOfCurrency%"" của chỉ báo bằng loại tiền ""%Factor%"".';
							|ru = 'Не найден источник валюты ""%SourceOfCurrency%"" показателя в валюте ""%Factor%"".';
							|en = 'Currency source ""%SourceOfCurrency%"" of indicator ""%Factor%"" in currency is not found.'; fa = 'Currency source ""%SourceOfCurrency%"" of indicator ""%Factor%"" in currency is not found.';
							|it = 'Fonte di valuta non trovata ""%SourceOfCurrency%"" dell''indicatore in valuta ""%Factor%"".';
							|pl = 'Nie jest znalezione źródło waluty ""%SourceOfCurrency%"" wskaźnika w walucie ""%Factor%"".';
							|tr = '""%Factor%"" para birimindeki göstergenin ""%SourceOfCurrency%"" para biriminin kaynağı bulunamadı.'");
			ErrorText = StrReplace(ErrorText, "%SourceOfCurrency%", SourceOfCurrency);
			ErrorText = StrReplace(ErrorText, "%Factor%", Factor.Key);
			ErrorsArray.Add(ErrorText);
		EndIf;
	EndDo;
	
	If ErrorsArray.Count() > 0 Then
		ErrorText = NStr("vi = 'Đã tìm thấy lỗi trong số liệu đăng ký ""%RegisterName%"":';
						|ru = 'Обнаружены ошибки показателей регистра ""%RegisterName%"":';
						|en = 'Register ""%RegisterName%"" indicator errors are detected:'; fa = 'Register ""%RegisterName%"" indicator errors are detected:';
						|it = 'Errori di registro rilevati ""%RegisterName%"":';
						|pl = 'Wykryto błędy wskaźników rejestru ""%RegisterName%"":';
						|tr = '""%RegisterName%"" kaydının göstergelerinde hatalar bulundu:'");
		ErrorText = StrReplace(ErrorText, "%RegisterName%", RegisterName);
		For Each Error In ErrorsArray Do
			ErrorText = ErrorText + Chars.LF + Error;
		EndDo;
		Raise ErrorText;
	EndIf;

	Return True;

EndFunction


// Accounting account.
// 
// Parameters:
//  Data - ValueTableRow - Data
//  PostingTemplate - ValueTableRow - International accounting transaction template data
//  InvoiceRefinementTable - ValueTable
//  SourcesOfInvoiceRefinement - Map, Undefined - Sources of account clarification
//  RecordType - String - Type of movement
// 
// Returns:
//   ChartOfAccountsRef
//  
Function GLAccount(Data, PostingTemplate, InvoiceRefinementTable, SourcesOfInvoiceRefinement, RecordType)

	Try
		If RecordType = "Dr" Then
			SourceOfInvoiceRefinementForTransactionTemplate = PostingTemplate.AccountSpecificationSourceDr;
			RecordType = Enums.AccountingMovementKinds.Debit;
			DefaultAccount = PostingTemplate.DrAccountDefault;
		ElsIf RecordType = "Cr" Then
			SourceOfInvoiceRefinementForTransactionTemplate = PostingTemplate.AccountSpecificationSourceCr;
			RecordType = Enums.AccountingMovementKinds.Credit;
			DefaultAccount = PostingTemplate.CrAccountDefault;
		EndIf;
		
		GLAccount = DefaultAccount;
		If ValueIsFilled(SourceOfInvoiceRefinementForTransactionTemplate) Then
			AccountSpecificationSource = SourcesOfInvoiceRefinement.Get(SourceOfInvoiceRefinementForTransactionTemplate);
			FinancialAccountingGroup = Data[AccountSpecificationSource.FieldName];
			FilterParameters = New Structure;
			FilterParameters.Insert("FinancialAccountingGroup", FinancialAccountingGroup);
			FilterParameters.Insert("PostingTemplate", PostingTemplate.PostingTemplate);
			FilterParameters.Insert("RecordType", RecordType);
			ArrayOfFoundStrings = InvoiceRefinementTable.FindRows(FilterParameters);
			If ArrayOfFoundStrings.Count() > 0 Then
				GLAccount = ArrayOfFoundStrings[0].GLAccount;
			EndIf;
		EndIf;
	
	Except
		MessageText = Chars.LF + NStr("vi = 'Khi tạo bút toán đối với giao dịch kinh tế ""%BusinessTransaction%""
									|theo khuôn mẫu ""%PostingTemplate%""
									|không thể nhận chi tiết tài khoản ""%AccountType%""
									|do nguyên nhân';
									|ru = 'При формировании проводки для хозяйственной операции ""%BusinessTransaction%""
									|по шаблону ""%PostingTemplate%""
									|не удалось получить уточнение счета ""%AccountType%""
									|по причине';
									|en = 'When generating an accounting entry for the business transaction ""%BusinessTransaction%""
									|from the ""%PostingTemplate%"" template,
									|the ""%AccountType%"" account specification was not received.
									|Reason:'; fa = 'When generating an accounting entry for the business transaction ""%BusinessTransaction%""
									|from the ""%PostingTemplate%"" template,
									|the ""%AccountType%"" account specification was not received.
									|Reason:';
									|it = 'La formazione di cablaggio per operazione economica ""%BusinessTransaction%""
									|per modello ""%PostingTemplate%""
									|non è riuscito a ottenere la raffinatezza conto ""%AccountType%""
									|per un motivo';
									|pl = 'Podczas tworzenia zaksięgowania dla operacji gospodarczej ""%BusinessTransaction%""
									|wg szablonu ""%PostingTemplate%""
									|nie udało się uzyskać uściślenie rachunku ""%AccountType%""
									|z powodu';
									|tr = '""%BusinessTransaction%"" ticari işlemi için bir kayıt oluşturulurken
									|""%PostingTemplate%"" numunesine göre
									|""%AccountType%"" hesabına ilişkin açıklama elde etmek mümkün olmadı
									|nedeniyle'") + ":" + Chars.LF + Chars.Tab + "%Cause%";
		MessageText = StrReplace(MessageText, "%BusinessTransaction%", PostingTemplate.BusinessOperation);
		MessageText = StrReplace(MessageText, "%PostingTemplate%", PostingTemplate.PostingTemplate);
		MessageText = StrReplace(MessageText, "%AccountType%", RecordType);
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		MessageText = MessageText + Chars.LF
			+ NStr("vi = 'Có thể trong mẫu bút toán đã thiết lập không chính xác việc xác minh tài khoản.';
					|ru = 'Возможно в шаблоне проводки установлены некорректные настройки уточнения счета.';
					|en = 'Incorrect settings of account specification might have been set in the posting template.'; fa = 'Incorrect settings of account specification might have been set in the posting template.';
					|it = 'Forse nel modello di registrazione non sono corrette impostazioni di perfezionamento conto.';
					|pl = 'Możliwie w szablonie zaksięgowania są ustawione niepoprawne ustawienia uściślenia rachunku.';
					|tr = 'Kayıt numunesinde yanlış hesap ayrıntılandırma ayarları belirlenmiş olabilir.'");
		Raise MessageText;
	EndTry;

	Return GLAccount;
	
EndFunction

// Parameters:
// 	Data - ValueTableRow - 
// 	PostingTemplate - ValueTableRow - 
// 	RegisterResources - See DescriptionOfResources
// 	CurrenciesOfInternationalAccounting - See FinancialAccountingOfGeneralPurpose.AccountingCurrencies
// Returns:
// 	Structure - contains fields:
// 		* Sum - Number -
// 		* Currency - CatalogRef.Currencies -
Function FunctionalSum(Data, PostingTemplate, RegisterResources, CurrenciesOfInternationalAccounting) Export
	
	Sum = 0;
	NameOfManResource = "";
	LocalResourceName = "";
	BothResourcesAreFound = False;
	
	// we will find resources containing amounts in the currency of upr. and regl.
	For Each Resource In RegisterResources Do
		If Resource.SourceOfCurrency = "CurrencyOfMan" Then
			NameOfManResource = Resource.Name;
		ElsIf Resource.SourceOfCurrency = "ComplCurrency" Then
			LocalResourceName = Resource.Name;
		EndIf;
		If ValueIsFilled(NameOfManResource) And ValueIsFilled(LocalResourceName) Then
			If CurrenciesOfInternationalAccounting.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
				Sum = Data[NameOfManResource];
				ResourceCurrency = SettingsValueCached.ManagementAccountingCurrency();
			Else
				Sum = Data[LocalResourceName];
				ResourceCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Data.Organization);
			EndIf;
			BothResourcesAreFound = True;
			Break;
		EndIf;
	EndDo;
	
	If Not BothResourcesAreFound Then
		If ValueIsFilled(NameOfManResource) Then
			Sum = Data[NameOfManResource];
			ResourceCurrency = SettingsValueCached.ManagementAccountingCurrency();
		ElsIf ValueIsFilled(LocalResourceName) Then
			Sum = Data[LocalResourceName];
			ResourceCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Data.Organization);
		EndIf;
	EndIf;

	Result = New Structure;
	Result.Insert("Sum", ?(PostingTemplate.ChangeOperationSign, -Sum, Sum));
	Result.Insert("Currency", ResourceCurrency);
	
	Return Result;
	
EndFunction

// Parameters:
// 	Data - ValueTableRow - 
// 	PostingTemplate - ValueTableRow - 
// 	RegisterResources - See DescriptionOfResources
// 	CurrenciesOfInternationalAccounting - See FinancialAccountingOfGeneralPurpose.AccountingCurrencies
// Returns:
// 	Structure - contains fields:
// 		* Sum - Number -
// 		* Currency - CatalogRef.Currencies -
Function PresentationAmount(Data, PostingTemplate, RegisterResources, CurrenciesOfInternationalAccounting)

	Sum = 0;
	NameOfManResource = "";
	LocalResourceName = "";
	ResourceFoundInCurrency = False;
	
	For Each Resource In RegisterResources Do
		If Resource.SourceOfCurrency = "CurrencyOfMan" Then
			NameOfManResource = Resource.Name;
			ResourceCurrency = SettingsValueCached.ManagementAccountingCurrency();
		ElsIf Resource.SourceOfCurrency = "ComplCurrency" Then
			LocalResourceName = Resource.Name;
			ResourceCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Data.Organization);
		Else
			ResourceCurrency = Data[Resource.SourceOfCurrency];
		EndIf;
		If ResourceCurrency = CurrenciesOfInternationalAccounting.Presentations Then
			Sum = Data[Resource.Name];
			ResourceFoundInCurrency = True;
			Break;
		EndIf;
	EndDo;
	
	If Not ResourceFoundInCurrency Then
		If CurrenciesOfInternationalAccounting.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_
			 And ValueIsFilled(NameOfManResource)Then
			Sum = Data[NameOfManResource];
			ResourceCurrency = SettingsValueCached.ManagementAccountingCurrency();
		ElsIf ValueIsFilled(LocalResourceName)Then
			Sum = Data[LocalResourceName];
			ResourceCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Data.Organization);
		EndIf;
	EndIf;

	Result = New Structure;
	Result.Insert("Sum", ?(PostingTemplate.ChangeOperationSign, -Sum, Sum));
	Result.Insert("Currency", ResourceCurrency);
	
	Return Result;
	
EndFunction

// Parameters:
// 	Data - ValueTableRow - 
// 	PostingTemplate - ValueTableRow - 
// 	RegisterResources - See DescriptionOfResources
// 	SourceOfCurrency - String - 
// Returns:
// 	Number - LongDesc
Function AmountInCurrency(Data, PostingTemplate, RegisterResources, SourceOfCurrency)

	Sum = 0;
	For Each Resource In RegisterResources Do
		If Resource.SourceOfCurrency = SourceOfCurrency Then
			Sum = Data[Resource.Name];
			Break;
		EndIf;
	EndDo;
	
	Return ?(PostingTemplate.ChangeOperationSign, -Sum, Sum);

EndFunction

Function DimensionValue(Data, MeasurementSources, MeasurementSourceInPostingTemplate)

	DimensionSource = MeasurementSources.Get(MeasurementSourceInPostingTemplate);
	If DimensionSource <> Undefined Then
		Result = Data[DimensionSource];
	EndIf;

	Return Result;
	
EndFunction

Procedure FillExtdimension(RecordType, Parameters)
	
	RegisterName = Parameters.RegisterName;
	Data = Parameters.Data;
	AccountingEntry = Parameters.AccountingEntry;
	SourcesOfExtdimension = Parameters.SourcesOfExtdimension;
	AccountProperties = Parameters["AccountProperties" + RecordType];
	PopulateExtraDimensionByCorrespondence = AccountingEntry.TransactionTemplateData.PopulateExtraDimensionByCorrespondence;
	
	Account = AccountingEntry["Account" + RecordType];
	ExtdimensionSourceFields = SourcesOfExtdimension["ExtDimension" + RecordType];
	ProductMovement = AccountingEntry.TransactionTemplateData["ProductMovement"+RecordType];
	
	TypesOfFieldsFilledIn = New Map;
	TypesOfAvailableFields = New Map;
	For Each ExtdimensionSourceField In ExtdimensionSourceFields Do
		Value = Data[ExtdimensionSourceField];
		If Value <> Undefined Then
			TypesOfFieldsFilledIn.Insert(ExtdimensionSourceField, TypeOf(Value));
		Else
			TypesArray = FinancialAccountingServerCached.TypesOfRegisterAttribute(RegisterName, ExtdimensionSourceField);
			TypesOfAvailableFields.Insert(ExtdimensionSourceField, TypesArray);
		EndIf;
	EndDo;
	
	// The subconto with the Counterparty type on the nomenclature accounts is filled in by the counterparty from the inventory type.
	If Not PopulateExtraDimensionByCorrespondence Then
		If RegisterName = "RevenueAndCOGS"
			Or RegisterName = "Purchases"
			Or RegisterName = "RegisterRecordsProductsIncomeExpenses"
			Or RegisterName = "RecordsProductsProducts" Then
			If ProductMovement Then// substitute the value of the "Counterparty" field
					
				If TypesOfFieldsFilledIn["Custodian"] <> Undefined And ValueIsFilled(Data.Custodian) Then
					If TypesOfFieldsFilledIn["Vendor"] <> Undefined Then
						TypesOfFieldsFilledIn.Delete("Vendor");
					EndIf;
					If TypesOfFieldsFilledIn["Counterparty"] <> Undefined Then
						TypesOfFieldsFilledIn.Delete("Counterparty");
					EndIf;
					
				ElsIf TypesOfFieldsFilledIn["Vendor"] <> Undefined And ValueIsFilled(Data.Vendor) Then
					
					If TypesOfFieldsFilledIn["Custodian"] <> Undefined Then
						TypesOfFieldsFilledIn.Delete("Custodian");
					EndIf;
					If TypesOfFieldsFilledIn["Counterparty"] <> Undefined Then
						TypesOfFieldsFilledIn.Delete("Counterparty");
					EndIf;
					
				EndIf;
				
			Else// delete the "Supplier" field
				If TypesOfFieldsFilledIn["Vendor"] <> Undefined Then
					TypesOfFieldsFilledIn.Delete("Vendor");
				EndIf;
				If TypesOfFieldsFilledIn["Custodian"] <> Undefined Then
					TypesOfFieldsFilledIn.Delete("Custodian");
				EndIf;
			EndIf;// Nomenclature Movement = Truth
		EndIf;// Register Name = "Revenue and value of sales" OR Register name = "Purchases"
	EndIf;
	
	For K = 1 To AccountProperties.ExtDimensionCount Do
		ExtDimensionType = AccountProperties["ExtDimensionType" + K];
		AccountingEntry["ExtDimensionType" + RecordType + K] = ExtDimensionType;
		Var_226_ExtDimensionType = AccountProperties["ExtDimensionType" + K + "ValueType"];
		TypeDetected = False;
		For Each FieldType In TypesOfFieldsFilledIn Do
			If Var_226_ExtDimensionType.ContainsType(FieldType.Value) Then
				AccountingEntry["ExtDimension" + RecordType + K] = ?(
					ValueIsFilled(Data[FieldType.Key]),
					Data[FieldType.Key],
					Var_226_ExtDimensionType.AdjustValue(Undefined));
				TypeDetected = True;
				Break;
			EndIf;
		EndDo;
		If Not TypeDetected Then
			For Each FieldType In TypesOfAvailableFields Do
				For Each Type In FieldType.Value Do
					If Var_226_ExtDimensionType.ContainsType(Type) Then
						AccountingEntry["ExtDimension" + RecordType + K] = ?(
							ValueIsFilled(Data[FieldType.Key]),
							Data[FieldType.Key],
							Var_226_ExtDimensionType.AdjustValue(Undefined));
						TypeDetected = True;
						Break;
					EndIf;
				EndDo;
				If TypeDetected Then
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckTransactionCompletion(AccountingEntry, PostingTemplate, RegisterParameters)

	If Not ValueIsFilled(AccountingEntry.AccountDr) Then
		FinancialAccountingPostingServer.FillInTransactionStatus(AccountingEntry, Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined);
		ErrorText = NStr("vi = 'Không thể điền tài khoản Nợ.';
						|ru = 'Не удалось заполнить счет Дт.';
						|en = 'Cannot fill in Dr account.'; fa = 'Cannot fill in Dr account.';
						|it = 'Impossibile compilare il conto a debito.';
						|pl = 'Nie udało się wypełnić Konto Wn.';
						|tr = 'BÇ hesabı doldurulamadı.'");
		FinancialAccountingPostingServer.AddTransactionError(AccountingEntry, ErrorText);
	EndIf;

	If Not ValueIsFilled(AccountingEntry.AccountCr) Then
		FinancialAccountingPostingServer.FillInTransactionStatus(AccountingEntry, Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined);
		ErrorText = NStr("vi = 'Không thể điền tài khoản Có.';
						|ru = 'Не удалось заполнить счет Кт.';
						|en = 'Cannot fill in Cr account.'; fa = 'Cannot fill in Cr account.';
						|it = 'Impossibile compilare il conto a credito.';
						|pl = 'Nie udało się wypełnić konta Ma.';
						|tr = 'AC hesabı doldurulamadı.'");
		FinancialAccountingPostingServer.AddTransactionError(AccountingEntry, ErrorText);
	EndIf;

EndProcedure


#EndRegion

#Region RegistrationForReflection

Procedure SupplementRegistrationTableAccordingToDataOfCirculatingRegisters(Document, RegistrationTable)

	QueriesTexts = RequestTextsByRegister();
	For Each KeyAndValue In QueriesTexts Do
		RegisterName = KeyAndValue.Key;
		AddSetOfRecordsToTable(RegistrationTable, Document, RegisterName);
	EndDo;

EndProcedure


Procedure AddSetOfRecordsToTable(RecordsetTable, Document, RegisterName)
	
	If TypeOf(Document.RegisterRecords) = Type("Structure")
		And Not Document.RegisterRecords.Property(RegisterName) Then
		Return;
	EndIf;
	
	If TypeOf(Document.RegisterRecords) = Type("RegisterRecordsCollection")
		And Document.RegisterRecords.Find(RegisterName) = Undefined Then
		Return;
	EndIf;
	
	RecordSet = Document.RegisterRecords[RegisterName];
	
	If RecordSet.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterMetadata = RecordSet.Metadata();
	ThereIsBusinessOperation = RegisterMetadata.Attributes.Find("BusinessOperation") <> Undefined;
	ThereIsSettingOfEconomicOperation = RegisterMetadata.Attributes.Find("BusinessTransactionSetting") <> Undefined;
	
	If RegisterName = "RevenueAndCOGS" Then
		AddSetOfRecordsForRevenueAndCostOfSalesRegister(RecordsetTable, Document);
	Else
		For Each Record In RecordSet Do
			If ThereIsBusinessOperation And Not ValueIsFilled(Record.BusinessOperation) Then
				Continue;
			EndIf;
			If ThereIsSettingOfEconomicOperation And Not ValueIsFilled(Record.BusinessTransactionSetting) Then
				Continue;
			EndIf;
			NewRecord = RecordsetTable.Add();
			FillPropertyValues(NewRecord, Record);
			NewRecord.DateRecord = Record.Period;
		EndDo;
	EndIf;
	
EndProcedure

Procedure AddSetOfRecordsForRevenueAndCostOfSalesRegister(RecordsetTable, Document)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	MovementData.Period AS Period,
	|	MovementData.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|INTO MovementData
	|FROM
	|	&RegisterRecordTable AS MovementData
	|;
	|SELECT
	|	MovementData.Period AS Period,
	|	MovementData.AccountingDimensionByPartners.Organization AS Organization,
	|	MovementData.Period AS DateRecord
	|FROM
	|	MovementData AS MovementData
	|";
	
	Query.SetParameter("RegisterRecordTable", Document.RegisterRecords.RevenueAndCOGS);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRecord = RecordsetTable.Add();
		FillPropertyValues(NewRecord, Selection);
	EndDo;

EndProcedure

// Returns:
// 	Array of Structure - LongDesc:
// 	 *Name - String -
//
Function DescriptionOfResources() Export
	
	Result = New Array;
	Result.Add(New Structure("Name"));
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
