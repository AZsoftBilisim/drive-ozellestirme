#Region Public

// Returns descriptions of sections and business operations for entering balances.
// 
// Parameters:
// 	ConsiderFOS - Boolean - Accounting for functional options when building a table.
// Returns:
// 	ValueTable - a table of values containing a description of business operations for entering Balances:
// * AccountingSection - String  - Text representation of the accounting section 
// * BusinessOperation - EnumRef.BusinessTransactions - the value of the economic operation of entering Balances
// * ExplanationOfAccountingSection - String - textual representation of the description of the business operation of entering Balances 
// * OrderInTree        - Number - hierarchy of business operations in the Balance entry tree 
// * InputAvailability      - Boolean - allows or disables the entry of a Balance entry document
// * BalanceInputDocument - CatalogRef.MetadataObjectIDs - id of the Balance entry document
// * DocumentHeaderTemplate - String - The template used to create the document view.
// 
Function DescriptionOfBalanceEntrySections(ConsiderFOS = True) Export
	
	DescriptionOfBalanceEntrySections = InitializeDescriptionOfSectionsEnteringBalances();
	
#Region Cash
	SectionDetails = DescriptionOfSectionEnteringCashBalances();
	AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
#EndRegion
	
#Region LoansAndDeposits
	If ConsiderFOS And GetFunctionalOption("UseLoanAndDepositContracts") Then
		SectionDetails = DescriptionOfSectionForEnteringLoanAndDepositBalances();
		AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
	EndIf;
#EndRegion	
	
#Region Acquiring
	If ConsiderFOS And GetFunctionalOption("UsePaymentByCards") Then
		SectionDetails = DescriptionOfSectionForEnteringBalancesOnAcquiring();
		AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
	EndIf;
#EndRegion	
	
#Region AdvanceHolders
	SectionDetails = DescriptionOfSectionForEnteringBalancesOfSettlementsWithAccountablePersons();
	AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
#EndRegion
	
#Region MutualSettlementsWithPartners
	SectionDetails = DescriptionOfSectionEnteringBalancesBalancesOfSettlementsWithPartners(ConsiderFOS);
	AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
#EndRegion	

#Region Goods
	SectionDetails = DescriptionOfSectionEnteringProductBalances();
	AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
#EndRegion
	
#Region Other
	If ConsiderFOS And GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") 
		Or GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		SectionDetails = DescriptionOfBalanceEntrySectionOtherExpenses();
		AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
	EndIf;
#EndRegion	
	
#Region BalancesOfPastPeriods
	SectionDetails = DescriptionOfSectionForEnteringBalancesOfResultsForPreviousPeriod();
	AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
#EndRegion

#Region NonCurrentAssets
	If ConsiderFOS And GetFunctionalOption("UseNonCurrentAssets2_4") Then
		SectionDetails = DescriptionOfSectionForEnteringVNABalances(ConsiderFOS);
		AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
	EndIf;
#EndRegion

#Region InventoryInOperation
	If ConsiderFOS And GetFunctionalOption("UseInventoryConsumption")
		And Not GetFunctionalOption("BaseVersion") Then
		SectionDetails = DescriptionOfSectionForEnteringRemainsOfInventoryItemsInOperation();
		AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, SectionDetails);
	EndIf;
#EndRegion
	
	OBEntryLocalization.FillInComplianceTableForBusinessOperationsSection(DescriptionOfBalanceEntrySections, ConsiderFOS);
	
	Return DescriptionOfBalanceEntrySections;
	
EndFunction

// Returns an array of available business operations.
// 
// Parameters:
// 	FilterParameters - Structure - parameters for selecting available business operations, See InitializeSelectionParametersForAvailableBusinessOperations.
// Returns:
// 	Array - Available business operations.
//
Function AvailableBusinessTransactions(FilterParameters) Export
	
	FilterValues = New Structure();
	FilterValues.Insert("InputAvailability", True);
	
	If FilterParameters.Property("BalanceInputDocument") 
		And ValueIsFilled(FilterParameters.BalanceInputDocument) Then
		FilterValues.Insert("BalanceInputDocument", FilterParameters.BalanceInputDocument);
	EndIf;
	
	If FilterParameters.Property("AccountingSection") 
		And ValueIsFilled(FilterParameters.AccountingSection) Then
		FilterValues.Insert("AccountingSection", FilterParameters.AccountingSection);
	EndIf;
	
	If FilterParameters.Property("InputAvailability")
		And ValueIsFilled(FilterParameters.InputAvailability) Then
		FilterValues.Insert("InputAvailability", FilterParameters.InputAvailability);
	EndIf;
	
	EconomicOperationsOfEnteringBalances = DescriptionOfBalanceEntrySections();
	AvailableBusinessTransactions = EconomicOperationsOfEnteringBalances.Copy(FilterValues).UnloadColumn("BusinessOperation");
	
	Return AvailableBusinessTransactions;
	
EndFunction

// Returns the ID of the balance entry document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - Business operation for entering initial balances.
// Returns:
// 	CatalogRef.MetadataObjectIDs - ID of the document for entering balances.
//
Function DetermineDocumentOnEconomicOperation(BusinessOperation) Export
	
	DocumentTypeForEnteringInitialBalances = Catalogs.MetadataObjectIDs.EmptyRef();
	
	ComplianceOfDocumentWithEconomicOperation = DescriptionOfBalanceEntrySections();
	FoundCorrespondence                                               = ComplianceOfDocumentWithEconomicOperation.Find(BusinessOperation, "BusinessOperation");
	
	If FoundCorrespondence <> Undefined Then
		DocumentTypeForEnteringInitialBalances = FoundCorrespondence.BalanceInputDocument;
	EndIf;
	
	Return DocumentTypeForEnteringInitialBalances;
	
EndFunction

// Returns a synonym for the document defined by the business transaction.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - Business transaction for which the document and a synonym of the document are defined
// Returns:
// 	String - Synonym of the document.
//
Function NameOfBusinessTransactionDocument(BusinessOperation) Export
	
	DocumentName = "";	
	DocumentType = DetermineDocumentOnEconomicOperation(BusinessOperation);
	
	If ValueIsFilled(DocumentType) Then
		DocumentName = Common.ObjectAttributeValue(DocumentType, "FullName");
	EndIf;
	
	Return DocumentName;
	
EndFunction

// Adds a description of the section for entering balances with fill data.
// 
// Parameters:
// 	DescriptionOfBalanceEntrySections - ValueTable - A table of values initialized in the initializationdescription of parts in the output of Outputs 
// 	FillingData              - Structure - The data structure of the filling, initialized in the procedure for initializing the description of the accounting
//
Procedure AddDescriptionOfBalanceEntrySection(DescriptionOfBalanceEntrySections, FillingData) Export
	
	For Each DescriptionOfBusinessOperation In FillingData.BusinessTransactions Do
		
		NewRow = DescriptionOfBalanceEntrySections.Add();
		NewRow.AccountingSection                         = FillingData.AccountingSection;
		NewRow.BusinessOperation               = DescriptionOfBusinessOperation.BusinessOperation;
		NewRow.BalanceInputDocument               = DescriptionOfBusinessOperation.BalanceInputDocument;
		NewRow.DocumentHeaderTemplate            = DescriptionOfBusinessOperation.DocumentHeaderTemplate;
		NewRow.ExplanationOfAccountingSection               = FillingData.ExplanationOfAccountingSection;
		NewRow.OrderInTree                      = FillingData.OrderInTree;
		NewRow.OrderInTreeOfHouseholdOperations           = DescriptionOfBusinessOperation.OrderInTree;
		NewRow.InputAvailability                    = FillingData.InputAvailability;
		
	EndDo;
	
EndProcedure

// Initializes the description structure of the balance entry accounting section.
// 
// Returns:
// 	Structure - A structure containing a description of the Balance entry accounting section:
//       *  InputAvailability - Boolean - determine the possibility of entering a document entering Balances
//       * OrderInTree - Number - hierarchy of business operations in the Balance entry log tree
//       * BusinessTransactions - EnumRef.BusinessTransactions - Business operation for entering balances 
//       * ExplanationOfAccountingSection - String - explanation of the Balance entry accounting section.
//
Function InitializeAccountingSectionDescription() Export
	
	SectionDetails = New Structure();
	SectionDetails.Insert("AccountingSection",           "");
	SectionDetails.Insert("ExplanationOfAccountingSection", "");
	SectionDetails.Insert("BusinessTransactions", InitializeDescriptionOfBusinessTransactionForEnteringBalances());
	SectionDetails.Insert("OrderInTree",        0);
	SectionDetails.Insert("InputAvailability",      True);
	
	Return SectionDetails;
	
EndFunction

// Values of details for filling in the balance entry document.
// 
// Returns:
// 	Structure - A structure containing the names of the Attributes of the Balance entry document and the values of their filling:
//       * Comment                                - String - The comment that will be set by the document being created
//       * DocumentDate                             - Date - The date that will be set for the document to be created
//       * RecordInMA                                - Boolean - A sign of reflection in management accounting
//       * PostInFinancialAndTaxAccounting - Boolean        - A sign of reflection in regulated and tax accounting
//       * RecordInOperationalAccounting - Boolean - The sign of reflection in operational accounting
//       * Organization                                 - CatalogRef.Companies - the organization for which Balances are entered
//       * BusinessOperation            - EnumRef.BusinessTransactions - the economic operation of entering Balances.
//
Function InitializeDocumentFillValuesEnteringBalances() Export
	
	RecordInMA = False;

	FillingValues = New Structure();
	FillingValues.Insert("BusinessOperation",     Enums.BusinessTransactions.EmptyRef());
	FillingValues.Insert("Organization",               Catalogs.Companies.EmptyRef());
	FillingValues.Insert("RecordInOperationalAccounting", False);
	FillingValues.Insert("PostInFinancialAndTaxAccounting",            GetFunctionalOption("UseLocal"));
	FillingValues.Insert("RecordInMA",               RecordInMA);
	FillingValues.Insert("Date",                      Date(1, 1, 1, 0, 0, 0));
	FillingValues.Insert("Comment",               "");
	FillingValues.Insert("EmployeeResponsible",             Catalogs.Users.EmptyRef());
	
	Return FillingValues;
	
EndFunction

// Initializes the structure of the description of the business operation for entering balances.
// 
// Returns:
// 	ValueTable - LongDesc:
//       * BusinessOperation - EnumRef.BusinessTransactions - Business operation for entering balances
//       * DocumentHeaderTemplate - String - Template for the document header for entering balances
//       * BalanceInputDocument - CatalogRef.MetadataObjectIDs - ID of the document for entering balances.
//       * OrderInTree - Number - The order to sort
Function InitializeDescriptionOfBusinessTransactionForEnteringBalances() Export
	
	DescriptionOfBusinessOperationOfEnteringBalances = New ValueTable();
	DescriptionOfBusinessOperationOfEnteringBalances.Columns.Add("BusinessOperation",               New TypeDescription("EnumRef.BusinessTransactions"), NStr("vi = 'Giao dịch kinh tế';
																																								|ru = 'Хозяйственная операция';
																																								|en = 'Business transaction'; fa = 'عملیات تجاری';
																																								|it = 'Operazione economica';
																																								|pl = 'Operacja gospodarcza';
																																								|tr = 'Ticari işlem'"));
	DescriptionOfBusinessOperationOfEnteringBalances.Columns.Add("DocumentHeaderTemplate",            Common.StringTypeDetails(250), NStr("vi = 'Mẫu tiêu đề chứng từ';
																																			|ru = 'Шаблон заголовка документа';
																																			|en = 'Document header template'; fa = 'Document header template';
																																			|it = 'Modello dell''intestazione del documento';
																																			|pl = 'Szablon nagłówka dokumentu';
																																			|tr = 'Belge başlık numunesi'"));
	DescriptionOfBusinessOperationOfEnteringBalances.Columns.Add("BalanceInputDocument",               New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DescriptionOfBusinessOperationOfEnteringBalances.Columns.Add("OrderInTree",                      Common.TypeDescriptionNumber(2,0));
	
	Return DescriptionOfBusinessOperationOfEnteringBalances;
	
EndFunction

// Parameters for selecting available business operations.
// 
// Returns:
// 	Structure - LongDesc:
//        * AccountingSection - String - Accounting section for entering initial Balances
//        * BalanceInputDocument - CatalogRef.MetadataObjectIDs - ID of the document for entering balances.
//        * InputAvailability - String - Input Availability
//
Function InitializeSelectionParametersForAvailableBusinessOperations() Export
	
	FilterParameters = New Structure();
	FilterParameters.Insert("BalanceInputDocument", Catalogs.MetadataObjectIDs.EmptyRef());
	FilterParameters.Insert("AccountingSection",           "");
	FilterParameters.Insert("InputAvailability",      "");
	
	Return FilterParameters;
	
EndFunction

// The procedure based on operational accounting data generates documents for entering balances that are reflected in the regulated accounting.
// 
// Parameters:
// 	Parameters - Structure - Structure containing parameters for creating new documents
// 	StorageAddress - String - Address of the temporary storage where the array of created documents is placed.
//
Procedure GenerateDocumentsForEnteringBalancesBasedOnOperationalAccountingData(Parameters, StorageAddress) Export
	
	InputDate                       = Undefined;
	PostInFinancialAndTaxAccounting                  = False;
	RecordInMA                     = False;
	CreatedBalanceEntryDocuments = New Array;
	
	If Parameters.Property("InputDate") Then
		InputDate = Parameters.InputDate;
	EndIf;
	
	If Not ValueIsFilled(InputDate) Then
		Return;
	EndIf;
	
	If Parameters.Property("PostInFinancialAndTaxAccounting") Then
		PostInFinancialAndTaxAccounting = Parameters.PostInFinancialAndTaxAccounting;
	EndIf;
	
	If Parameters.Property("RecordInMA") Then
		RecordInMA = Parameters.RecordInMA;
	EndIf;
	
	If Not PostInFinancialAndTaxAccounting And Not RecordInMA Then
		Return;
	EndIf;

	ParametersForFillingBalances = New Structure;
	ParametersForFillingBalances.Insert("PostInFinancialAndTaxAccounting", PostInFinancialAndTaxAccounting);
	ParametersForFillingBalances.Insert("RecordInMA", RecordInMA);
	
	If Parameters.Property("ArrayOfBusinessOperations") Then
		AvailableBusinessTransactions = Parameters.ArrayOfBusinessOperations;
	Else
		SelectionParametersOfBusinessOperations = InitializeSelectionParametersForAvailableBusinessOperations();
		AvailableBusinessTransactions       = AvailableBusinessTransactions(SelectionParametersOfBusinessOperations);
	EndIf;
	
	Companies = New Array;
	
	If Not Parameters.Property("Companies", Companies) Then
		
		Query = New Query("SELECT ALLOWED DISTINCT
			|	Companies.Ref AS Organization
			|FROM
			|	Catalog.Companies AS Companies
			|WHERE
			|	NOT Companies.DeletionMark
			|	AND (&Companies = UNDEFINED
			|			OR Companies.Ref IN (&Companies))
			|	AND (Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
			|			OR &ConsiderManOrganization)
			|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
			|");
		
		Query.SetParameter("Companies",                            Companies);
		Query.SetParameter("ConsiderManOrganization", GetFunctionalOption("UseManagementCompany"));
		
		Companies = Query.Execute().Unload().UnloadColumn("Organization");
		
	EndIf;

	SerialNumber = 0;
	TotalObjectCount  = AvailableBusinessTransactions.Count();
	
	For Each BusinessOperation In AvailableBusinessTransactions Do
		
		SerialNumber    = SerialNumber + 1;
		ProgressPercent = Round(100 * SerialNumber / TotalObjectCount);
		
		TimeConsumingOperations.ReportProgress(ProgressPercent);
		
		BalanceInputDocument                      = DetermineDocumentOnEconomicOperation(BusinessOperation);
		DocumentReflectedInRegulatedAccounting = DocumentReflectedInRegulatedAccounting(BalanceInputDocument);
		DocumentSupportsFillingInAccordingToOUData   = DocumentSupportsFillingInAccordingToOUData(Common.ObjectAttributeValue(BalanceInputDocument, "Name"));
		
		If Not DocumentReflectedInRegulatedAccounting Or Not DocumentSupportsFillingInAccordingToOUData Then
			Continue;
		EndIf;
		
		ManagerOfDocument              = Common.ObjectManagerByFullName(Common.MetadataObjectByID(BalanceInputDocument).FullName());
		BusinessTransactionBalances = ManagerOfDocument.BalancesByTypeOfOperation(InputDate, BusinessOperation, Companies,, ParametersForFillingBalances);
		ComparisonFields                  = ManagerOfDocument.KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation);
		
		If BusinessTransactionBalances = Undefined Then
			Continue;
		EndIf;
		
		DocumentInputOfInitialResiduals = Undefined; // DocumentObject
		
		For Each TableRow In BusinessTransactionBalances Do
			
			If KeyFieldsAreDifferent(DocumentInputOfInitialResiduals, TableRow, ComparisonFields) Then
				
				If Not DocumentInputOfInitialResiduals = Undefined Then
					DocumentInputOfInitialResiduals.Write(DocumentWriteMode.Write);
					CreatedBalanceEntryDocuments.Add(DocumentInputOfInitialResiduals.Ref);
				EndIf;
				
				DocumentInputOfInitialResiduals = ManagerOfDocument.CreateDocument();
				FillPropertyValues(DocumentInputOfInitialResiduals, TableRow);
				
				FillingData = InitializeDocumentFillValuesEnteringBalances();
				FillingData.Date           = InputDate;
				FillingData.EmployeeResponsible  = Users.CurrentUser();
				FillingData.PostInFinancialAndTaxAccounting = PostInFinancialAndTaxAccounting;
				FillingData.RecordInMA    = RecordInMA;
				FillingData.Comment    = NStr("vi = '# Nhập số dư theo kế toán hoạt động.';
												|ru = '#Ввод остатков по данным оперативного учета.';
												|en = '#Enter balance by operational accounting data.'; fa = '#Enter balance by operational accounting data.';
												|it = '#Immissione dei saldi secondo i dati della contabilità operativa.';
												|pl = '#Wprowadzenie ostatków według danych ewidencji operacyjnej.';
												|tr = '#Operasyonel muhasebe verilerine göre bakiyelerini girme.'");
				If CommonClientServer.HasAttributeOrObjectProperty(DocumentInputOfInitialResiduals, "BusinessOperation") Then
					FillPropertyValues(DocumentInputOfInitialResiduals, FillingData, , "BusinessOperation, Organization");
				Else
					FillPropertyValues(DocumentInputOfInitialResiduals, FillingData, , "Organization");
				EndIf;
				
				TabularPartOfDocument   = TableRow.TablePartToFillIn;
				TablePartToFillIn = DocumentInputOfInitialResiduals[TabularPartOfDocument]; //TabularSection
				
			EndIf;
			
			LineOfATabularSection = TablePartToFillIn.Add();
			FillPropertyValues(LineOfATabularSection, TableRow);
			
		EndDo;
		
		If Not DocumentInputOfInitialResiduals = Undefined Then
			DocumentInputOfInitialResiduals.Write(DocumentWriteMode.Write);
			CreatedBalanceEntryDocuments.Add(DocumentInputOfInitialResiduals.Ref);
		EndIf;
			
	EndDo;
	
	PutToTempStorage(CreatedBalanceEntryDocuments, StorageAddress);
	
EndProcedure

// Returns available document types for entering balances
// 
// Returns:
// 	Array - Available types of balance entry documents
//
Function AvailableTypesOfResidueInput() Export
	Return OBEntryServerCached.AvailableTypesOfResidueInput();
EndFunction

// Checks the correctness of the specified primary document. Based on one primary document
// with the type "Shipment of goods to the customer", it is permissible to enter only one document for entering the Balance of the shipped goods.
// 
// Parameters:
// 	DocumentObject - DocumentObject.OBEntryGoods - a verifiable Balance entry document.
// 	Cancel - Boolean - a sign of failure.
//
Procedure CheckCompletionOfPrimaryDocument(DocumentObject, Cancel) Export
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods
		And Not DocumentObject.Patch
		And ValueIsFilled(DocumentObject.Lot) Then
		
		Query = New Query();
		Query.SetParameter("Ref", DocumentObject.Ref);
		Query.SetParameter("SourceDocument", DocumentObject.Lot);
		Query.Text =
		"SELECT TOP 1
		|	RegisterTable.Recorder AS Recorder
		|FROM
		|	AccumulationRegister.ShipmentAndReturnReferences AS RegisterTable
		|WHERE
		|	RegisterTable.ReferenceOrder = &SourceDocument
		|	AND RegisterTable.Recorder REFS Document.OBEntryGoods
		|	AND RegisterTable.Recorder <> &Ref";
		
		If Not PrivilegedMode() Then
			SetPrivilegedMode(True);
		EndIf;
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			MessageText = StrTemplate(NStr("vi = 'Trên cơ sở chứng từ %1đã nhập số dư đầu:
				|%2.';
				|ru = 'На основании документа %1 уже были введены начальные остатки:
				|%2.';
				|en = 'Based on the %1 document, the opening balances are already entered:
				|%2.'; fa = 'Based on the %1 document, the opening balances are already entered:
				|%2.';
				|it = 'Based on the %1 document, the opening balances are already entered:
				|%2.';
				|pl = 'Based on the %1 document, the opening balances are already entered:
				|%2.';
				|tr = '%1 belgesi bazında, açılış bakiyeleri zaten girilmiştir: 
				|%2.'"),
				DocumentObject.Lot,
				Selection.Recorder);
			
			Common.MessageToUser(
				MessageText,,
				"Object.Lot",,
				Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Fills in the data of the new document entering balances based on the data of the old document entering balances
// 
// Parameters:
// 	Receiver - DocumentObject - New document for entering balances 
// 	Source - DocumentObject.OBEntry - Old document for entering balances
//
Procedure FillInValuesForOldInputBalances(Receiver, Source) Export
	
	PropertiesToExclude = "Number, Date, Posted, DeletionMark";
	FillPropertyValues(Receiver, Source, , PropertiesToExclude);
	
	For Each TabularSection In Metadata.Documents.OBEntry.TabularSections Do
		
		If Not Receiver.Metadata().TabularSections.Find(TabularSection.Name) = Undefined Then 
			Receiver[TabularSection.Name].Load(Source[TabularSection.Name].Unload()); 
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the parameters required for copying the old document and entering balances in the new one
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business transaction that is used to get the name of a new document for entering product balances
// 	
// Returns:
// 	Structure - LongDesc:
//       * NewDocumentEnteringResiduesByLine - String - full name of the metadata object ID
//       * EconomicOperationsOfEnteringBalanceOfGoods - Array - business operations of product balances
//       * BusinessOperationsAvailableForInput - Array - business operations allowed for entering balances
//
Function GetParametersForCopyingDocument(BusinessOperation) Export
	
	CopyingParameters = InitializeCopyParameters();
	
	NewDocumentEnteringResiduesByLine = NameOfBusinessTransactionDocument(BusinessOperation);
	
	FilterParameters                  = InitializeSelectionParametersForAvailableBusinessOperations();
	FilterParameters.InputAvailability = True;
	AvailableBusinessTransactions   = AvailableBusinessTransactions(FilterParameters);
	
	FilterParameters                       = InitializeSelectionParametersForAvailableBusinessOperations();
	FilterParameters.BalanceInputDocument = Common.MetadataObjectID(
		Metadata.Documents.OBEntryGoods);
	BusinessTransactionsForEnteringProductBalances       = AvailableBusinessTransactions(FilterParameters);
	
	CopyingParameters.BusinessOperationsAvailableForInput    = AvailableBusinessTransactions;
	CopyingParameters.EconomicOperationsOfEnteringBalanceOfGoods = BusinessTransactionsForEnteringProductBalances;
	CopyingParameters.NewDocumentEnteringResiduesByLine         = NewDocumentEnteringResiduesByLine;
	
	Return CopyingParameters;
EndFunction

// Returns the name of the form for entering sales balances for previous periods
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business transaction that you need to get a form for
// Returns:
// 	String - Name of the form for entering balances of sales for previous periods
Function ObtainingFormForEnteringBalancesOnSalesForPastPeriods(BusinessOperation) Export
	
	MatchingOperationTypesToForms = New Map;
		
	MatchingOperationTypesToForms.Insert(
		PredefinedValue("Enum.BusinessTransactions.OBEntryStatisticsOfOtherPLItemsInPastPeriods"),
		"FormFinancialResult");
		
	MatchingOperationTypesToForms.Insert(
		PredefinedValue("Enum.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods"),
		"FormWholesale");
		
	MatchingOperationTypesToForms.Insert(
		PredefinedValue("Enum.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods"),
		"FormRetailSales");
		
	MatchingOperationTypesToForms.Insert(
		PredefinedValue("Enum.BusinessTransactions.OBEntryOpenGiftCards"),
		"FormGiftCards");
	
	Return MatchingOperationTypesToForms[BusinessOperation];
	
EndFunction

// Returns available document types for entering balances
// 
// Returns:
// 	Array - Available types of balance input
//
Function PrepareAvailableDocumentTypes() Export
	
	AvailableTypes = New Array();
	BalanceEntrySections = DescriptionOfBalanceEntrySections();
	BalanceEntrySections.GroupBy("BalanceInputDocument");
	
	For Each RowOfResidueEntrySection In BalanceEntrySections Do
		InputResiduesEmptyLink = Common.ObjectAttributeValue(
			RowOfResidueEntrySection.BalanceInputDocument, "EmptyRefValue");
		AvailableTypes.Add(TypeOf(InputResiduesEmptyLink));
	EndDo;
	
	Return AvailableTypes;
	
EndFunction

#EndRegion

#Region Private

Function InitializeCopyParameters()
	
	CopyingParameters = New Structure();
	CopyingParameters.Insert("BusinessOperationsAvailableForInput",    New Array());
	CopyingParameters.Insert("EconomicOperationsOfEnteringBalanceOfGoods", New Array());
	CopyingParameters.Insert("NewDocumentEnteringResiduesByLine",         "");
	
	Return CopyingParameters;
	
EndFunction

Function InitializeDescriptionOfSectionsEnteringBalances()
	
	DescriptionOfBalanceEntrySections = New ValueTable();
	DescriptionOfBalanceEntrySections.Columns.Add("AccountingSection",               Common.StringTypeDetails(30), NStr("vi = 'Phần hành kế toán';
																														|ru = 'Раздел учета';
																														|en = 'Accounting section'; fa = 'بخش حسابداری';
																														|it = 'Sezione contabilità';
																														|pl = 'Rozdział ewidencji';
																														|tr = 'Muhasebe bölümü'"));
	DescriptionOfBalanceEntrySections.Columns.Add("BusinessOperation",     New TypeDescription("EnumRef.BusinessTransactions"), NStr("vi = 'Giao dịch kinh tế';
																																	|ru = 'Хозяйственная операция';
																																	|en = 'Business transaction'; fa = 'عملیات تجاری';
																																	|it = 'Operazione economica';
																																	|pl = 'Operacja gospodarcza';
																																	|tr = 'Ticari işlem'"));
	DescriptionOfBalanceEntrySections.Columns.Add("ExplanationOfAccountingSection",     Common.StringTypeDetails(250), NStr("vi = 'Giải thích phần kế toán';
																															|ru = 'Пояснение раздела учета';
																															|en = 'Explanation of accounting section'; fa = 'توضیح بخش حسابداری';
																															|it = 'Spiegazione della sezione della contabilità';
																															|pl = 'Komentarz rozdziału ewidencji';
																															|tr = 'Muhasebe bölümü notu'"));
	DescriptionOfBalanceEntrySections.Columns.Add("OrderInTree",            Common.TypeDescriptionNumber(2,0));
	DescriptionOfBalanceEntrySections.Columns.Add("OrderInTreeOfHouseholdOperations", Common.TypeDescriptionNumber(2,0));
	DescriptionOfBalanceEntrySections.Columns.Add("InputAvailability",          New TypeDescription("Boolean"));
	DescriptionOfBalanceEntrySections.Columns.Add("BalanceInputDocument",     New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DescriptionOfBalanceEntrySections.Columns.Add("DocumentHeaderTemplate",  Common.StringTypeDetails(250), NStr("vi = 'Mẫu tiêu đề chứng từ';
																												|ru = 'Шаблон заголовка документа';
																												|en = 'Document header template'; fa = 'Document header template';
																												|it = 'Modello dell''intestazione del documento';
																												|pl = 'Szablon nagłówka dokumentu';
																												|tr = 'Belge başlık numunesi'"));
	
	Return DescriptionOfBalanceEntrySections;
	
EndFunction

Function KeyFieldsAreDifferent(DocumentInputOfInitialResiduals, SamplingBalances, ArrayOfComparisonFields)
	
	If DocumentInputOfInitialResiduals = Undefined Then
		Return True;
	EndIf;
	
	For Each ComparisonField In ArrayOfComparisonFields Do
		If Not DocumentInputOfInitialResiduals[ComparisonField] = SamplingBalances[ComparisonField] Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function DocumentReflectedInRegulatedAccounting(DocumentInputOfInitialResiduals)
	
	ReflectedInRegulatedAccounting = True; 
	
	ManagerOfDocument = Common.ObjectManagerByFullName(Common.MetadataObjectByID(DocumentInputOfInitialResiduals).FullName());
	AccountingMechanisms  = DocumentsPosting.DocumentAccountingMechanisms(ManagerOfDocument);
	ValueIndex    = AccountingMechanisms.Find("LocalAccounting");
	
	If ValueIndex = Undefined Then
		ReflectedInRegulatedAccounting = False;
	EndIf;
	
	Return ReflectedInRegulatedAccounting;
	
EndFunction

Function DocumentSupportsFillingInAccordingToOUData(NameOfInitialRemainderEntryDocument)
	
	DocumentsArray = New Array;
	DocumentsArray.Add("OBEntry");
	DocumentsArray.Add("OBEntryARAP");
	DocumentsArray.Add("OBEntryOfLeaseSettlements");
	DocumentsArray.Add("EntryOfCapitalAssetsBalance2_4");
	DocumentsArray.Add("OBEntrySubAssetsAndComponentsOfDepreciation");
	DocumentsArray.Add("OBEntryCash");
	DocumentsArray.Add("OBEntryFinancialInstruments");
	DocumentsArray.Add("OBEntryOtherExpenses");
	DocumentsArray.Add("OBEntryARAPAdvanceHolders");
	DocumentsArray.Add("OBEntryGoods");
	
	Return DocumentsArray.Find(NameOfInitialRemainderEntryDocument) <> Undefined;
	
EndFunction

#Region DescriptionOfBalanceEntrySections

Function DescriptionOfSectionEnteringCashBalances()
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Tiền mặt, tiền gửi';
														|ru = 'Денежные средства';
														|en = 'Cash'; fa = 'صندوق';
														|it = 'Fondi monetari';
														|pl = 'Środki pieniężne';
														|tr = 'Nakit'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập số dư tiền mặt và tiền gửi của doanh nghiệp';
														|ru = 'Вводятся остатки наличных и безналичных денежных средств организаций';
														|en = 'Balance of companies'' cash accounts and bank accounts is entered'; fa = 'Balance of companies'' cash accounts and bank accounts is entered';
														|it = 'Vengono immessi gli importi residui dei fondi monetari in contanti e di quelli cashless delle società';
														|pl = 'Trwa wprowadzenie sald gotówkowych i bezgotówkowych środków pieniężnych firm';
														|tr = 'İş yeri nakit ve gayri nakit bakiyelerinin girilmesi'");
	SectionDetails.OrderInTree        = 1;
	SectionDetails.BusinessTransactions = DescriptionOfBusinessOperationsForEnteringCashBalances();
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfBusinessOperationsForEnteringCashBalances()
	
	DescriptionOfBusinessOperationsForEnteringCashBalances = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	NameOfInitialRemainderEntryDocument                        = Common.MetadataObjectID(Metadata.Documents.OBEntryCash);
	SeveralCashAccountsAreUsed                                 = GetFunctionalOption("UseMultipleCashAccounts");
	SeveralAccountsAreUsed                               = GetFunctionalOption("UseMultipleBankAccounts");
	
	If SeveralAccountsAreUsed Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu tiền gửi %1';
								|ru = 'Ввод начальных остатков на банковских счетах %1';
								|en = 'Enter opening balance of accounts %1'; fa = 'Enter opening balance of accounts %1';
								|it = 'Inserimento dei saldi iniziali sui conti bancari %1';
								|pl = 'Wprowadzenie sald początkowych na rachunków bankowych %1';
								|tr = '%1 banka hesaplarına açılış bakiyelerinin girilmesi'");
	Else
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu tiền gửi %1';
								|ru = 'Ввод начальных остатков на банковском счете %1';
								|en = 'Enter opening balance of account %1'; fa = 'Enter opening balance of account %1';
								|it = 'Inserimento dei saldi iniziali sul conto bancario %1';
								|pl = 'Wprowadzenie sald początkowych na rachunku bankowym %1';
								|tr = '%1 banka hesabında açılış bakiyelerinin girilmesi'");
	EndIf;
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringCashBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryCashInBankAccounts;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = TitleTemplate1;
	DescriptionOfBusinessOperation.OrderInTree           = 4;
	
	If SeveralCashAccountsAreUsed Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu tiền mặt %1';
								|ru = 'Ввод начальных остатков в кассах %1';
								|en = 'OB entry: cash in retail POS terminals %1'; fa = 'OB entry: cash in retail POS terminals %1';
								|it = 'Inserimento dei saldi iniziali in cassa %1';
								|pl = 'Wprowadzenie sald początkowych w kasach %1';
								|tr = '%1 kasalarda açılış bakiyelerinin girilmesi'");
	Else
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu tiền mặt %1';
								|ru = 'Ввод начальных остатков в кассе %1';
								|en = 'Enter opening balance of cash account %1'; fa = 'Enter opening balance of cash account %1';
								|it = 'Inserimento dei saldi iniziali in cassa %1';
								|pl = 'Wprowadzenie sald początkowych w kasie %1';
								|tr = '%1 kasada açılış bakiyelerinin girilmesi'");
	EndIf;
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringCashBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCashInHand;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = TitleTemplate1;
	DescriptionOfBusinessOperation.OrderInTree                      = 3;
	
	If GetFunctionalOption("UseRetailSales") Then
		
		DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringCashBalances.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = TitleTemplate1;
		DescriptionOfBusinessOperation.OrderInTree                      = 1;
		
		DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringCashBalances.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCashInRetailCashRegister;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = TitleTemplate1;
		DescriptionOfBusinessOperation.OrderInTree                      = 2;
		
	EndIf;
	
	Return DescriptionOfBusinessOperationsForEnteringCashBalances;
	
EndFunction

Function DescriptionOfSectionForEnteringLoanAndDepositBalances()
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Tín dụng và tiền gửi (deposit)';
														|ru = 'Кредиты и депозиты';
														|en = 'Loans and deposits'; fa = 'وام‌ها و سپرده‌ها';
														|it = 'Prestiti e depositi';
														|pl = 'Kredyty i depozyty';
														|tr = 'Krediler ve mevduatlar'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập số dư vay nợ và tiền gửi (deposit) hiện tại của doanh nghiệp';
														|ru = 'Вводятся остатки действующих кредитов и депозитов организаций';
														|en = 'The balances of existing loans and deposits of companies are entered'; fa = 'The balances of existing loans and deposits of companies are entered';
														|it = 'Si imettono i saldi dei crediti e depositi delle aziende';
														|pl = 'Są wprowadzane salda obowiązujących kredytów i depozytów firm';
														|tr = 'İş yerlerinin mevcut kredi ve mevduat bakiyeleri girilir'");
	SectionDetails.OrderInTree        = 2;
	SectionDetails.BusinessTransactions = DescriptionOfBusinessOperationsForEnteringLoanAndDepositBalances();
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfBusinessOperationsForEnteringLoanAndDepositBalances()
	
	DescriptionOfBusinessOperationsForEnteringLoanAndDepositBalances = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	NameOfInitialRemainderEntryDocument                           = Common.MetadataObjectID(Metadata.Documents.OBEntryFinancialInstruments);
	TitleTemplate1 = NStr("vi = 'Nhập số dư đầu hạch toán các khoản vay,  tiền gửi (deposit) và vay nợ khác %1';
							|ru = 'Ввод начальных остатков расчетов по кредитам, депозитам и выданным займам %1';
							|en = 'OB entry: debt outstanding of loans and borrowings %1'; fa = 'OB entry: debt outstanding of loans and borrowings %1';
							|it = 'Inserimento dei saldi iniziali per crediti, depositi e prestiti emessi %1';
							|pl = 'Wprowadzenie sald początkowych rozlibczeń z tytułu kredytów, depozytów i wydanych pożyczek %1';
							|tr = '%1 krediler, mevduatlar ve verilen borçlar üzerindeki hesapların açılış bakiyelerinin girilmesi'");
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringLoanAndDepositBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = TitleTemplate1;
	DescriptionOfBusinessOperation.OrderInTree                      = 1;
	
	Return DescriptionOfBusinessOperationsForEnteringLoanAndDepositBalances;
	
EndFunction

Function DescriptionOfSectionForEnteringBalancesOnAcquiring()
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Thanh toán thẻ';
														|ru = 'Эквайринг';
														|en = 'Acquiring'; fa = 'پذیرندگی کارت';
														|it = 'Acquiring';
														|pl = 'Acquiring';
														|tr = 'POS bankacılık'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập số dư theo các giao dịch mua lại của doanh nghiệp';
														|ru = 'Вводятся остатки по операциям эквайринга организаций';
														|en = 'The balances of transaction of acquiring of companies are entered'; fa = 'The balances of transaction of acquiring of companies are entered';
														|it = 'Si inseriscono le operazioni di acquiring delle aziende';
														|pl = 'Są wprowadzane salda z tytułu operacji firm przez centrum autoryzacyjne';
														|tr = 'İş yeri PoS işlemine göre bakiyelerin girilmesi'");
	SectionDetails.OrderInTree        = 3;
	SectionDetails.BusinessTransactions = DescriptionOfBusinessOperationsOfEnteringBalancesOnAcquiring();
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfBusinessOperationsOfEnteringBalancesOnAcquiring()
	
	DescriptionOfBusinessOperationsOfEnteringBalancesOnAcquiring = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	NameOfInitialRemainderEntryDocument                     = Common.MetadataObjectID(Metadata.Documents.OBEntryAcquiringContractARAP);
	TitleTemplate1 = NStr("vi = 'Nhập số dư tiền mặt phải thu từ người mua lại %1';
							|ru = 'Ввод остатков денежных средств к поступлению от эквайера %1';
							|en = 'Enter cash balance to receive from acquirer %1'; fa = 'Enter cash balance to receive from acquirer %1';
							|it = 'Immissione di saldi di cassa in arrivo dall''acquirente %1';
							|pl = 'Wprowadzenie sald środków pieniężnych do wpływu od centrum autoryzacyjnego %1';
							|tr = 'Alıcı bankadan tahsil edilecek nakit bakiyelerinin girilmesi %1'");
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOnAcquiring.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryOpenOrderForCashToBeReceivedFromAcquirer;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = TitleTemplate1;
	DescriptionOfBusinessOperation.OrderInTree                      = 1;
		
	Return DescriptionOfBusinessOperationsOfEnteringBalancesOnAcquiring;
	
EndFunction

Function DescriptionOfSectionForEnteringBalancesOfSettlementsWithAccountablePersons()
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Người nhận tạm ứng';
														|ru = 'Подотчетные лица';
														|en = 'Advance holders'; fa = 'تنخواه‌گردان‌ها';
														|it = 'Titolari di anticipo';
														|pl = 'Osoby rozliczające się za wydatki';
														|tr = 'Sorumlu kişiler'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập số dư đầu hạch toán với người nhận tạm ứng';
														|ru = 'Вводятся остатки по взаиморасчетов с подотчетными лицами';
														|en = 'The balances of settlements with advance holders are entered'; fa = 'The balances of settlements with advance holders are entered';
														|it = 'Si inseriscono i saldi di regolamenti reciproci con titolari di anticipo';
														|pl = 'Są wprowadzane salda z tytułu rozliczeń wzajemnych z osobami odpowiedzialnymi';
														|tr = 'Sorumlu kişilerle mutabakat bakiyeleri girilir'");
	SectionDetails.OrderInTree        = 4;
	SectionDetails.BusinessTransactions = DescriptionOfBusinessOperationsOfEnteringBalancesOfSettlementsWithAccountablePersons();
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfBusinessOperationsOfEnteringBalancesOfSettlementsWithAccountablePersons()
	
	DescriptionOfBusinessOperationsOfEnteringBalancesOfSettlementsWithAccountablePersons = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	NameOfInitialRemainderEntryDocument                                = Common.MetadataObjectID(Metadata.Documents.OBEntryARAPAdvanceHolders);
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOfSettlementsWithAccountablePersons.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryAdvanceHolderReceivables;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu công nợ với người nhận tạm ứng %1';
																			|ru = 'Ввод начальных остатков задолженности подотчетных лиц %1';
																			|en = 'OB entry: advance holder receivables %1'; fa = 'OB entry: advance holder receivables %1';
																			|it = 'Inserimento dei saldi iniziali del debito dei titolari di anticipo %1';
																			|pl = 'Wprowadzenie sald początkowych zadłużenia osób odpowiedzialnych %1';
																			|tr = '%1 sorumlu kişilerin borçlarının açılış bakiyelerinin girilmesi'");
	DescriptionOfBusinessOperation.OrderInTree                      = 1;
		
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOfSettlementsWithAccountablePersons.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryOpenExpenseReportOfEmployees;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu bội chi tạm ứng %1';
																			|ru = 'Ввод начальных остатков перерасходов подотчетных средств %1';
																			|en = 'OB entry: advance holder overspendings %1'; fa = 'OB entry: advance holder overspendings %1';
																			|it = 'Inserimento dei saldi iniziali degli eccessi di spesa di fondi responsabili %1';
																			|pl = 'Wprowadzenie sald początkowych nadmiernych rozchodów środków podlegających rozliczeniu %1';
																			|tr = '%1 sorumlu kişilerin fazla harcamalarının açılış bakiyelerinin girilmesi'");
	DescriptionOfBusinessOperation.OrderInTree                      = 2;
	
	Return DescriptionOfBusinessOperationsOfEnteringBalancesOfSettlementsWithAccountablePersons;
	
EndFunction

Function DescriptionOfSectionEnteringBalancesBalancesOfSettlementsWithPartners(ConsiderFOS)
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Công nợ với bạn hàng';
														|ru = 'Расчеты с партнерами';
														|en = 'Partners AR/AP'; fa = 'دریافتنی/پرداختنی شرکا';
														|it = 'Regolamento dei conti con i partner';
														|pl = 'Rozliczenia z partnerami';
														|tr = 'İş ortaklarıyla mutabakatlar'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập số dư hạch toán giữa các doanh nghiệp và bạn hàng của công ty (khách hàng và nhà cung cấp)';
														|ru = 'Вводятся остатки взаиморасчетов между организациями и партнерами компании (клиентами и поставщиками)';
														|en = 'Balance of mutual intercompany AR/AP open items and company''s partners (customers and vendors) is entered'; fa = 'Balance of mutual intercompany AR/AP open items and company''s partners (customers and vendors) is entered';
														|it = 'Vengono immessi gli importi residui delle regolazioni reciproche dei conti tra società e partner dell''azienda (clienti e fornitori)';
														|pl = 'Trwa wprowadzenie sald rozliczeń wzajemnych między firmami i partnerami firm (klientami i dostawcami)';
														|tr = 'İş yerleri ve şirketin ortakları (müşteriler ve tedarikçiler) arasındaki karşılıklı uzlaşma kalıntıları tanıtıldı'");
	SectionDetails.OrderInTree        = 5;
	SectionDetails.BusinessTransactions = DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners(ConsiderFOS);
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners(ConsiderFOS)
	
	DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	NameOfInitialRemainderEntryDocument                                  = Common.MetadataObjectID(Metadata.Documents.OBEntryARAP);
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu công nợ với khách hàng %1';
																			|ru = 'Ввод начальных остатков задолженности клиентов %1';
																			|en = 'OB entry: customer receivables %1'; fa = 'OB entry: customer receivables %1';
																			|it = 'Inserimento dei saldi iniziali del debito dei clienti %1';
																			|pl = 'Wprowadzenie sald początkowych zadłużenia klientów %1';
																			|tr = '%1 müşteri alacakları/borçları açılış bakiyelerinin girilmesi'");
	DescriptionOfBusinessOperation.OrderInTree                      = 3;
		
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư ứng trước của khách hàng %1';
																			|ru = 'Ввод начальных остатков авансов, полученных от клиентов %1';
																			|en = 'OB entry: unmatched prepayments from customers %1'; fa = 'OB entry: unmatched prepayments from customers %1';
																			|it = 'Inserimento dei saldi iniziali dei pagamenti anticipati ricevuti dai clienti %1';
																			|pl = 'Wprowadzenie sald początkowych zaliczek, otrzymanych od klientów %1';
																			|tr = '%1 müşterilerden alınan avansların açılış bakiyelerinin girilmesi'");
	DescriptionOfBusinessOperation.OrderInTree                      = 1;
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryVendorAccountsPayable;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu công nợ với nhà cung cấp %1';
																			|ru = 'Ввод начальных остатков задолженности перед поставщиками %1';
																			|en = 'OB entry: vendor payables %1'; fa = 'OB entry: vendor payables %1';
																			|it = 'Inserimento dei saldi iniziali del debito con i fornitori %1';
																			|pl = 'Wprowadzenie sald początkowych zadłużenia wobec dostawców %1';
																			|tr = '%1 tedarikçi borçlarının açılış bakiyelerinin girilmesi'");
	DescriptionOfBusinessOperation.OrderInTree                      = 4;
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư ứng trước cho nhà cung cấp %1';
																			|ru = 'Ввод начальных остатков авансов, выданных поставщикам %1';
																			|en = 'OB entry: unmatched prepayments to vendors %1'; fa = 'OB entry: unmatched prepayments to vendors %1';
																			|it = 'Inserimento dei saldi iniziali dei pagamenti anticipati emessi ai fornitori %1';
																			|pl = 'Wprowadzenie sald początkowych zaliczek, wydanych dostawcom %1';
																			|tr = '%1 tedarikçilere verilen avansların açılış bakiyelerinin girilmesi'");
	DescriptionOfBusinessOperation.OrderInTree                      = 2;	
	
	If ConsiderFOS Then
		
		If GetFunctionalOption("UseCustomerRebates") Then
			
			DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners.Add();
			DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCustomerBonuses;
			DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
			DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu công nợ theo khoản thưởng cho khách hàng %1';
																					|ru = 'Ввод начальных остатков задолженности по премиям клиентам %1';
																					|en = 'OB entry: customer bonus payables %1'; fa = 'OB entry: customer bonus payables %1';
																					|it = 'Ввод начальных остатков задолженности по премиям клиентам %1';
																					|pl = 'OB entry: customer bonus payables %1';
																					|tr = 'Müşterilere ödenmemiş primlerin ilk bakiyelerinin girişi %1'");
			DescriptionOfBusinessOperation.OrderInTree                      = 5;
			
		EndIf;
		
		If GetFunctionalOption("UseVendorRebates") Then
			
			DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners.Add();
			DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryVendorBonuses;
			DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
			DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu công nợ theo khoản thưởng của nhà cung cấp %1';
																					|ru = 'Ввод начальных остатков задолженности по премиям поставщиков %1';
																					|en = 'OB entry: vendor bonus payables %1'; fa = 'OB entry: vendor bonus payables %1';
																					|it = 'Ввод начальных остатков задолженности по премиям поставщиков %1';
																					|pl = 'OB entry: vendor bonus payables %1';
																					|tr = '%1 tedarikçilerine ödenmemiş primlerin ilk bakiyelerinin girişi'");
			DescriptionOfBusinessOperation.OrderInTree                      = 6;
			
		EndIf;
		
	EndIf;
	
	Return DescriptionOfBusinessOperationsOfEnteringBalancesOfMutualSettlementsWithPartners;
	
EndFunction

Function DescriptionOfSectionEnteringProductBalances()
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Hàng hóa';
														|ru = 'Товары';
														|en = 'Goods'; fa = 'کالاها';
														|it = 'Merci';
														|pl = 'Goods';
														|tr = 'Ürünler'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập số dư hàng hóa của doanh nghiệp';
														|ru = 'Вводятся остатки товаров организаций';
														|en = 'Company stock balance are entered'; fa = 'Company stock balance are entered';
														|it = 'Vengono immesse le rimanenze merci delle società';
														|pl = 'Trwa wprowadzenie stanu magazynowego firm';
														|tr = 'İş yer ürün bakiyeleri giriliyor'");
	SectionDetails.OrderInTree        = 6;
	SectionDetails.BusinessTransactions = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods();
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods()
	
	DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	
	NameOfInitialRemainderEntryDocument = Common.MetadataObjectID(Metadata.Documents.OBEntryGoods);
	
	
	DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu hàng hóa riêng %1';
																			|ru = 'Ввод начальных остатков собственных товаров %1';
																			|en = 'OB entry: cost of owned inventory in our warehouse %1'; fa = 'OB entry: cost of owned inventory in our warehouse %1';
																			|it = 'Inserimento dei saldi iniziali della merce propria %1';
																			|pl = 'Wprowadzenie sald początkowych towarów własnych %1';
																			|tr = '%1 yerel ürünlerin açılış bakiyelerinin girilmesi'");
	DescriptionOfBusinessOperation.OrderInTree                      = 11;
	
	If GetFunctionalOption("UsePurchaseCommission") Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu hàng hóa nhận ký gửi %1';
																				|ru = 'Ввод начальных остатков полученных на комиссию товаров %1';
																				|en = 'OB entry: cost of consignment goods in our warehouse %1'; fa = 'OB entry: cost of consignment goods in our warehouse %1';
																				|it = 'Inserimento dei saldi iniziali ricevuti dalle commissioni sulle merci %1';
																				|pl = 'Wprowadzenie początkowych ostatków do komisu towarów %1';
																				|tr = '%1 ürün komisyonuna alınan açılış bakiyelerinin girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree                      = 12;
	EndIf;
	
	If GetFunctionalOption("UseSalesCommission")
		And GetFunctionalOption("ConsignmentSaleIsUsed20") Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		Postfix = ConsignmentSalesServer.PostfixCommissionSchemes20();
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhập số dư hàng hóa đã chuyển giao đi ký gửi (%1) %2';
																																		|ru = 'Ввод остатков товаров, переданных на комиссию (%1) %2';
																																		|en = 'OB entry: consignment sales stock (%1)%2'; fa = 'OB entry: consignment sales stock (%1)%2';
																																		|it = 'Ввод остатков товаров, переданных на комиссию (%1) %2';
																																		|pl = 'OB entry: consignment sales stock (%1)%2';
																																		|tr = 'Konsinye stok üzerine transfer edilen ürün bakiyelerinin girişi (%1) %2'"),
			Postfix, "%1");
		DescriptionOfBusinessOperation.OrderInTree                      = 13;
	EndIf;
	
	If GetFunctionalOption("UseSalesCommission") Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		If Not GetFunctionalOption("ConsignmentSaleIsUsed20")
			Or GetFunctionalOption("OnlyConsignmentSales25") Then
			Postfix = "";
		Else
			Postfix = ConsignmentSalesServer.PostfixCommissionSchemes25();
		EndIf;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhập số dư hàng hóa đã chuyển giao đi ký gửi (%1) %2';
																																		|ru = 'Ввод остатков товаров, переданных на комиссию (%1) %2';
																																		|en = 'OB entry: consignment sales stock (%1)%2'; fa = 'OB entry: consignment sales stock (%1)%2';
																																		|it = 'Ввод остатков товаров, переданных на комиссию (%1) %2';
																																		|pl = 'OB entry: consignment sales stock (%1)%2';
																																		|tr = 'Konsinye stok üzerine transfer edilen ürün bakiyelerinin girişi (%1) %2'"),
			Postfix, "%1");
		DescriptionOfBusinessOperation.OrderInTree                      = 14;
	EndIf;
	
	If GetFunctionalOption("UseCustodyDuringPurchase") Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.EnterRemainingReceivedVMI;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu hàng hóa đã tiếp nhận vào lưu kho %1';
																				|ru = 'Ввод начальных остатков принятых на хранение товаров %1';
																				|en = 'OB entry: VMI in our warehouse %1'; fa = 'OB entry: VMI in our warehouse %1';
																				|it = 'Ввод начальных остатков принятых на хранение товаров %1';
																				|pl = 'OB entry: VMI in our warehouse %1';
																				|tr = '%1 depolamaya kabul edilen ürünlerin açılış bakiyelerinin girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree                      = 15;
	EndIf;
	
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu hàng hóa đã chuyển giao vào lưu kho %1';
																				|ru = 'Ввод начальных остатков переданных на хранение товаров %1';
																				|en = 'OB entry: goods transferred for VMI %1'; fa = 'OB entry: goods transferred for VMI %1';
																				|it = 'Ввод начальных остатков переданных на хранение товаров %1';
																				|pl = 'OB entry: goods transferred for VMI %1';
																				|tr = '%1 depolamaya transfer edilen ürünlerin açılış bakiyelerinin girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree                      = 16;
	EndIf;
	
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
		
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryShippedGoods;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư hàng hóa đã giao cho khách %1';
																				|ru = 'Ввод остатков товаров, отгруженных клиентам %1';
																				|en = 'OB entry: goods shipped to customers %1'; fa = 'OB entry: goods shipped to customers %1';
																				|it = 'OB entry: goods shipped to customers %1';
																				|pl = 'OB entry: goods shipped to customers %1';
																				|tr = '%1  müşterilerine sevk edilen ürünlerin stok miktarlarının girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree                      = 17;
		
	EndIf;
	
	If GetFunctionalOption("UseReusablePackage") Then
		
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư của bao bì luân chuyển được chuyển cho khách hàng %1';
																				|ru = 'Ввод остатков возвратной тары, переданной клиентам %1';
																				|en = 'OB entry: cost of returnable packaging sent to customers %1'; fa = 'OB entry: cost of returnable packaging sent to customers %1';
																				|it = 'OB entry: cost of returnable packaging sent to customers %1';
																				|pl = 'OB entry: cost of returnable packaging sent to customers %1';
																				|tr = 'Müşterilere transfer edilen iade edilebilir ambalajların bakiyelerinin girişi %1'");
		DescriptionOfBusinessOperation.OrderInTree                      = 1;
	
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư của bao bì luân chuyển tiếp nhận từ các nhà cung cấp %1';
																				|ru = 'Ввод остатков возвратной тары, принятой от поставщиков %1';
																				|en = 'OB entry: cost of returnable packaging received from vendors %1'; fa = 'OB entry: cost of returnable packaging received from vendors %1';
																				|it = 'OB entry: cost of returnable packaging received from vendors %1';
																				|pl = 'OB entry: cost of returnable packaging received from vendors %1';
																				|tr = 'Tedarikçilerden alınan iade edilebilir ambalajların bakiyelerinin girilmesi %1'");
		DescriptionOfBusinessOperation.OrderInTree                      = 2;
			
	EndIf;
	
	If GetFunctionalOption("UseBinLocationWarehousing") Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư khi chuyển sang sử dụng lưu trữ địa chỉ số dư %1';
																				|ru = 'Ввод остатков при переходе на использование адресного хранения остатков %1';
																				|en = 'OB entry: bin location system of owned inventory %1'; fa = 'OB entry: bin location system of owned inventory %1';
																				|it = 'OB entry: bin location system of owned inventory %1';
																				|pl = 'OB entry: bin location system of owned inventory %1';
																				|tr = 'Artıkların adreslenebilir depolanmasını kullanmaya devam ederken artıkların girilmesi %1'");
		DescriptionOfBusinessOperation.OrderInTree                      = 8;
	EndIf;
	
	If (GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue")
		And GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt")
		And GetFunctionalOption("UseWarehouseManagemantSystemForGoodsSurplusesShortages")) Then
		
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư khi chuyển sang sử dụng nhà kho %1';
																				|ru = 'Ввод остатков при переходе на использование складских помещений %1';
																				|en = 'OB entry: wareroom address of owned inventory %1'; fa = 'OB entry: wareroom address of owned inventory %1';
																				|it = 'OB entry: wareroom address of owned inventory %1';
																				|pl = 'OB entry: wareroom address of owned inventory %1';
																				|tr = 'Depoları kullanmaya geçişte kalıntıların girilmesi %1'");
		DescriptionOfBusinessOperation.OrderInTree                      = 9;
	EndIf;
	
	FunctionalOptionIsToUseProductionOn2_5Side = GetFunctionalOption("UseProductionByThirdParty2_5");
	FunctionalOptionToUseProductionFromTollFreeRawMaterials2_5 = GetFunctionalOption("UseTollManufacturing2_5");
	
	If FunctionalOptionIsToUseProductionOn2_5Side Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5;
		DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập nguyên vật liệu đã chuyển giao gia công %1';
																	|ru = 'Ввод остатков материалов, переданных переработчикам %1';
																	|en = 'Enter remaining materials transferred to subcontractors %1'; fa = 'Enter remaining materials transferred to subcontractors %1';
																	|it = 'Enter remaining materials transferred to subcontractors %1';
																	|pl = 'Enter remaining materials transferred to subcontractors %1';
																	|tr = 'Fason üreticiye transfer edilen malzemelerin bakiyelerinin girişi %1'");
		DescriptionOfBusinessOperation.OrderInTree           = 4;
	EndIf;
	If FunctionalOptionToUseProductionFromTollFreeRawMaterials2_5 Then
		
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting;
		DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư của nguyên vật liệu đã nhận để gia công %1';
																	|ru = 'Ввод остатков материалов, принятых в переработку %1';
																	|en = 'Enter remaining materials received for subcontracting %1'; fa = 'Enter remaining materials received for subcontracting %1';
																	|it = 'Inserimento dei saldi dei materiali ricevuti in elaborazione %1';
																	|pl = 'Wprowadzenie sald materiałów, przyjętych do przetwarzania %1';
																	|tr = '%1 fason üretimine kabul edilen malzeme bakiyesinin girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree           = 6;
		
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider;
		DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư bán thành phẩm của người đặt gia công %1';
																	|ru = 'Ввод остатков полуфабрикатов давальца %1';
																	|en = 'Enter remaining semi-finished products of the provider %1'; fa = 'Enter remaining semi-finished products of the provider %1';
																	|it = 'Inserimento dei saldi dei semilavorati del fornitore %1';
																	|pl = 'Wprowadzenie sald półproduktów właściciela surowców %1';
																	|tr = '%1 tedarikçi yarı mamul ürün bakiyelerini girme'");
		DescriptionOfBusinessOperation.OrderInTree           = 7;
		
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider;
		DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư sản phẩm của người đặt gia công %1';
																	|ru = 'Ввод остатков продукции давальца %1';
																	|en = 'Enter remaining manufactured products of the provider %1'; fa = 'Enter remaining manufactured products of the provider %1';
																	|it = 'Inserimento dei saldi di produzione del fornitore %1';
																	|pl = 'Wprowadzenie sald produkcji właściciela surowców %1';
																	|tr = '%1 tedarikçi imal edilen ürünlerinin bakiyelerinin girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree           = 10;
		
	EndIf;
	If GetFunctionalOption("UseProduction")
		And Not GetFunctionalOption("BaseVersion") Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned;
		DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập nguyên vật liệu còn lại chuyển sang sản xuất %1';
																	|ru = 'Ввод остатков материалов, переданных в производство %1';
																	|en = 'Enter remaining materials transferred to production %1'; fa = 'Enter remaining materials transferred to production %1';
																	|it = 'Enter remaining materials transferred to production %1';
																	|pl = 'Enter remaining materials transferred to production %1';
																	|tr = 'Üretime aktarılan malzeme bakiyelerinin girişi %1'");
		DescriptionOfBusinessOperation.OrderInTree           = 3;
	EndIf;
	
	If CalculationOfCostCached.MediumSlipValuationIsUsed() And Not GetFunctionalOption("BaseVersion") Then
		DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods.Add();
		DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryGoodsCostVariances;
		DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư chênh lệch vào giá trị hàng hóa %1';
																	|ru = 'Ввод остатков отклонений в стоимости товаров %1';
																	|en = 'OB entry: goods cost variances %1'; fa = 'OB entry: goods cost variances %1';
																	|it = 'OB entry: goods cost variances %1';
																	|pl = 'OB entry: goods cost variances %1';
																	|tr = 'Ürün maliyetindeki farkların bakiyelerinin girilmesi %1'");
		DescriptionOfBusinessOperation.OrderInTree           = 17;
	EndIf;
	
	Return DescriptionOfEconomicOperationsOfEnteringBalanceOfGoods;
	
EndFunction

Function DescriptionOfBalanceEntrySectionOtherExpenses()
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Dạng khác';
														|ru = 'Прочее';
														|en = 'Other'; fa = 'سایر';
														|it = 'Altro';
														|pl = 'Other';
														|tr = 'Diğer'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập số dư theo các giao dịch khác';
														|ru = 'Вводятся остатки по прочим операциям';
														|en = 'Balance of other transactions is entered'; fa = 'Balance of other transactions is entered';
														|it = 'Vengono immessi gli importi residui per altre operazioni';
														|pl = 'Trwa wprowadzenie sald według innych operacji';
														|tr = 'Diğer işlemlerden bakiyeleri girilir'");
	SectionDetails.OrderInTree        = 8;
	SectionDetails.BusinessTransactions = DescriptionOfBusinessOperationsForEnteringBalancesOfOtherExpenses();
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfBusinessOperationsForEnteringBalancesOfOtherExpenses()
	
	DescriptionOfBusinessOperationsForEnteringBalancesOfOtherExpenses = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	
	If GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalancesOfOtherExpenses.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryOtherAssetsAndLiabilities;
		DescriptionOfBusinessOperation.BalanceInputDocument               = Common.MetadataObjectID(Metadata.Documents.OBEntryOtherAssetsAndLiabilities);
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu tài sản và nguồn vốn khác %1';
																				|ru = 'Ввод начальных остатков прочих активов и пассивов %1';
																				|en = 'OB entry: other assets and liabilities %1'; fa = 'OB entry: other assets and liabilities %1';
																				|it = 'Inserimento dei saldi iniziale di altri attivi e passivi %1';
																				|pl = 'Wprowadzenie sald początkowych innych aktywów i pasywów %1';
																				|tr = '%1 diğer varlık ve yükümlülük açılış bakiyelerinin girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree                      = 1;
	EndIf;
	
	If GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalancesOfOtherExpenses.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryOfOtherExpenses;
		DescriptionOfBusinessOperation.BalanceInputDocument               = Common.MetadataObjectID(Metadata.Documents.OBEntryOtherExpenses);
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu các chi phí khác %1';
																				|ru = 'Ввод начальных остатков прочих расходов %1';
																				|en = 'Enter opening balance of other expenses %1'; fa = 'Enter opening balance of other expenses %1';
																				|it = 'Inserimento dei saldi iniziali di altre spese %1';
																				|pl = 'Wprowadzenie sald początkowych innych rozchodów%1';
																				|tr = '%1 diğer giderlerin açılış bakiyelerinin girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree                      = 2;
	EndIf;
	
	Return DescriptionOfBusinessOperationsForEnteringBalancesOfOtherExpenses;
	
EndFunction

Function DescriptionOfSectionForEnteringBalancesOfResultsForPreviousPeriod()
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Kết quả trong các kỳ trước';
														|ru = 'Результаты прошлых периодов';
														|en = 'Previous period results'; fa = 'Previous period results';
														|it = 'Risultati dei periodi precedenti';
														|pl = 'Rezultaty minionych okresów';
														|tr = 'Geçmiş dönem sonuçları'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập kết quả (phát sinh) của các kỳ trước';
														|ru = 'Вводятся результаты (обороты) прошлых периодов';
														|en = 'Previous period results (turnovers) are entered'; fa = 'Previous period results (turnovers) are entered';
														|it = 'Vengono immessi i risultati (fatturati) dei periodi precedenti';
														|pl = 'Trwa wprowadzenie rezultatów (obrotów) poprzednich okresów';
														|tr = 'Geçmiş dönemlerin sonuçları (ciroları) girilir'");
	SectionDetails.OrderInTree        = 11;
	SectionDetails.BusinessTransactions = DescriptionOfBusinessOperationsAndBalancesOfResultsForPreviousPeriod();
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfBusinessOperationsAndBalancesOfResultsForPreviousPeriod()
	
	DescriptionOfBusinessOperationsAndBalancesOfResultsForPreviousPeriod = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	NameOfInitialRemainderEntryDocument                                   = Common.MetadataObjectID(Metadata.Documents.OBEntrySalesForPastPeriods);
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsAndBalancesOfResultsForPreviousPeriod.Add();
	DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods;
	DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Bán buôn trong các kỳ trước %1';
																			|ru = 'Оптовые продажи за прошлые периоды %1';
																			|en = 'Wholesale sales in past periods %1'; fa = 'Wholesale sales in past periods %1';
																			|it = 'Vendite all''ingrosso per i periodi precedenti %1';
																			|pl = 'Operacji sprzedaży hurtowej za poprzednie okresy %1';
																			|tr = '%1 geçmiş dönemlere ait toptan satışlar'");
	DescriptionOfBusinessOperation.OrderInTree                      = 1;
	
	If GetFunctionalOption("UseRetailSales") Then
		DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsAndBalancesOfResultsForPreviousPeriod.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Doanh số bán lẻ trong các kỳ trước %1';
																				|ru = 'Розничные продажи за прошлые периоды %1';
																				|en = 'Retail sales in past periods %1'; fa = 'Retail sales in past periods %1';
																				|it = 'Vendite al dettaglio per i periodi precedenti %1';
																				|pl = 'Operacji sprzedaży detalicznej za poprzednie okresy %1';
																				|tr = '%1 geçmiş dönemlere ait perakende satışlar'");
		DescriptionOfBusinessOperation.OrderInTree                      = 3;
	EndIf;
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsAndBalancesOfResultsForPreviousPeriod.Add();
	DescriptionOfBusinessOperation.BusinessOperation     = Enums.BusinessTransactions.OBEntryStatisticsOfOtherPLItemsInPastPeriods;
	DescriptionOfBusinessOperation.BalanceInputDocument     = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate  = NStr("vi = 'Kết quả kinh doanh trong các kỳ trước %1';
																	|ru = 'Финансовый результат за прошлые периоды %1';
																	|en = 'OB entry: statistics of other P&L items in past periods %1'; fa = 'OB entry: statistics of other P&L items in past periods %1';
																	|it = 'Risultati finanziari dei periodi passati%1';
																	|pl = 'Rezultat finansowy za poprzednie okresy %1';
																	|tr = '%1 geçmiş dönemlere ait kârlılık ve maliyet'");
	DescriptionOfBusinessOperation.OrderInTree            = 4;
	
	If GetFunctionalOption("UseGiftCards") Then
		DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsAndBalancesOfResultsForPreviousPeriod.Add();
		DescriptionOfBusinessOperation.BusinessOperation               = Enums.BusinessTransactions.OBEntryOpenGiftCards;
		DescriptionOfBusinessOperation.BalanceInputDocument               = NameOfInitialRemainderEntryDocument;
		DescriptionOfBusinessOperation.DocumentHeaderTemplate            = NStr("vi = 'Nhập số dư đầu phiếu quà tặng %1';
																				|ru = 'Ввод начальных остатков подарочных сертификатов %1';
																				|en = 'Enter opening balance of gift cards %1'; fa = 'Enter opening balance of gift cards %1';
																				|it = 'Inserimento dei saldi iniziali dei buoni regalo %1';
																				|pl = 'Wprowadzenie sald początkowych certyfikatów podarunkowych %1';
																				|tr = '%1 hediye kartı açılış bakiyelerinin girilmesi'");
		DescriptionOfBusinessOperation.OrderInTree                      = 2;
	EndIf;
	
	Return DescriptionOfBusinessOperationsAndBalancesOfResultsForPreviousPeriod;
	
EndFunction

Function DescriptionOfSectionForEnteringRemainsOfInventoryItemsInOperation()
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection = NStr("vi = 'Vật tư đang sử dụng';
											|ru = 'ТМЦ в эксплуатации';
											|en = 'Inventory in operation'; fa = 'موجودی در حال بهره‌برداری';
											|it = 'Beni materiali in uso';
											|pl = 'Dobra towarowo-materiałowe w eksploatacji';
											|tr = 'Stok kullanımda'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Đưa số dư vật tư vào sử dụng';
														|ru = 'Вводятся остатки ТМЦ в эксплуатации';
														|en = 'Balance of inventory in operation is entered'; fa = 'Balance of inventory in operation is entered';
														|it = 'Vengono inseriti i saldi dei beni materiali in lavorazione';
														|pl = 'Są wprowadzane salda zapasów w eksploatacji';
														|tr = 'Kullanımdaki stok bakiyeleri girilir'");
	SectionDetails.OrderInTree = 9;
	SectionDetails.BusinessTransactions = DescriptionOfEconomicOperationsOfEnteringRemainsOfInventoryItemsInOperation();
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfEconomicOperationsOfEnteringRemainsOfInventoryItemsInOperation()
	
	DescriptionOfEconomicOperationsOfEnteringRemainsOfInventoryItemsInOperation = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	NameOfInitialRemainderEntryDocument = Common.MetadataObjectID(Metadata.Documents.OBEntryInventoryInOperation);
	
	DescriptionOfBusinessOperation = DescriptionOfEconomicOperationsOfEnteringRemainsOfInventoryItemsInOperation.Add();
	DescriptionOfBusinessOperation.BusinessOperation = Enums.BusinessTransactions.OBEntryInventoryInOperation;
	DescriptionOfBusinessOperation.BalanceInputDocument = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư đầu vật tư đang sử dụng %1';
																|ru = 'Ввод начальных остатков ТМЦ в эксплуатации %1';
																|en = 'OB entry: inventory in operation %1'; fa = 'OB entry: inventory in operation %1';
																|it = 'Inserimento saldi iniziale Beni Materiali nell''operazione %1';
																|pl = 'Wprowadzenie sald początkowych zapasy w eksploatacji %1';
																|tr = '%1 kullanımdaki stok açılış bakiyelerinin girilmesi'");
	
	Return DescriptionOfEconomicOperationsOfEnteringRemainsOfInventoryItemsInOperation;
	
EndFunction

Function DescriptionOfSectionForEnteringVNABalances(ConsiderFOS)
	
	SectionDetails = InitializeAccountingSectionDescription();
	
	SectionDetails.AccountingSection           = NStr("vi = 'Tài sản dài hạn';
														|ru = 'Внеоборотные активы';
														|en = 'Fixed and intangible assets'; fa = 'دارایی‌های ثابت و نامشهود';
														|it = 'Attivi non circolanti';
														|pl = 'Środki trwałe';
														|tr = 'Duran varlıklar'");
	SectionDetails.ExplanationOfAccountingSection = NStr("vi = 'Nhập số dư tài sản dài hạn';
														|ru = 'Вводятся остатки внеоборотных активов';
														|en = 'Fixed assets balance is entered'; fa = 'Fixed assets balance is entered';
														|it = 'Vengono inseriti i saldi di attivi non circolanti';
														|pl = 'Są wprowadzane salda aktywów pozaobrotowych';
														|tr = 'Duran varlık bakiyeleri girilir'");
	SectionDetails.OrderInTree        = 6;
	SectionDetails.BusinessTransactions = DescriptionOfBusinessOperationsOfEnteringBalancesIntoAccount(ConsiderFOS);
	
	Return SectionDetails;
	
EndFunction

Function DescriptionOfBusinessOperationsOfEnteringBalancesIntoAccount(ConsiderFOS)
	
	DescriptionOfBusinessOperationsForEnteringBalances = InitializeDescriptionOfBusinessTransactionForEnteringBalances();
	NameOfInitialRemainderEntryDocument = Common.MetadataObjectID(Metadata.Documents.EntryOfCapitalAssetsBalance2_4);
	
	OrderInTree = 1;
	
	#Region FA
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryFixedAssets;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư đầu tài sản cố định %1';
																|ru = 'Ввод начальных остатков основных средств %1';
																|en = 'OB entry: cost of owned fixed assets %1'; fa = 'OB entry: cost of owned fixed assets %1';
																|it = 'Inserimento dei saldi iniziali dei capitali fissi %1';
																|pl = 'Wprowadzenie sald początkowych środków trwałych %1';
																|tr = 'Sabit kıymetlerin açılış bakiyelerinin girişi %1'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntrySubAssetsAndComponentsOfDepreciation;
	DescriptionOfBusinessOperation.BalanceInputDocument    = Common.MetadataObjectID(Metadata.Documents.OBEntrySubAssetsAndComponentsOfDepreciation);
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư đầu của nút, thành phần khấu hao %1';
																|ru = 'Ввод начальных остатков узлов, компонентов амортизации %1';
																|en = 'OB entry: sub-assets and components of depreciation %1'; fa = 'OB entry: sub-assets and components of depreciation %1';
																|it = 'Ввод начальных остатков узлов, компонентов амортизации %1';
																|pl = 'OB entry: sub-assets and components of depreciation %1';
																|tr = 'Açılış bakiyeleri girişi: alt varlıklar ve amortisman bileşenleri %1'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;

	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư ban đầu của tài sản cố định cho thuê %1';
																|ru = 'Ввод начальных остатков переданных в аренду основных средств %1';
																|en = 'OB entry: leased out %1 fixed assets'; fa = 'OB entry: leased out %1 fixed assets';
																|it = 'Inserimento dei saldi iniziali dei capitali fissi dati in affitto %1';
																|pl = 'Wprowadzenie sald początkowych przekazanych do dzierżawy środków trwałych %1';
																|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girişi %1'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;
	
	#EndRegion

	#Region IA
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư Tài sản cố định vô hình và chi phí Nghiên cứu và phát triển %1';
																|ru = 'Ввод остатков нематериальных активов и расходов на НИОКР %1';
																|en = 'OB entry: intangible assets and R&D expenses %1'; fa = 'OB entry: intangible assets and R&D expenses %1';
																|it = 'Inserimento dei saldi di attivi non circolanti e delle spese di Ricerca e Sviluppo %1';
																|pl = 'Wprowadzenie sald aktywów niematerialnych i wydatków na B+R%1';
																|tr = 'Maddi olmayan duran varlıklar ve gider bakiyelerinin Ar-Ge''ye girilmesi %1 '");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;

	#EndRegion

	#Region RentOnBalance
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư đầu tài sản cố định đã thuê (trong bảng) %1';
																|ru = 'Ввод начальных остатков арендованных основных средств (на балансе) %1';
																|en = 'OB entry: leased fixed assets (on balance sheet) %1'; fa = 'OB entry: leased fixed assets (on balance sheet) %1';
																|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (in bilancio) %1';
																|pl = 'Wprowadzenie sald początkowych wynajmowanych środków trwałych (na bilansie) %1';
																|tr = '%1 kiralanan sabit kıymetlerin açılış bakiyelerinin girilmesi (bilanço içi)'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;

	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê trong bảng %1';
																|ru = 'Ввод начальных остатков переданных в аренду предметов лизинга на балансе %1';
																|en = 'OB entry: financial lease assets provided to lessee (on balance sheet) %1'; fa = 'OB entry: financial lease assets provided to lessee (on balance sheet) %1';
																|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio dati in affitto %1';
																|pl = 'Wprowadzenie początkowych sald przekazanych do dzierżawy przedmiotów leasingu na bilansie %1';
																|tr = 'Kiralanan kalemlerin başlangıç bakiyelerinin bilançoya girişi %1'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;

	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryLeaseContractsARAP;
	DescriptionOfBusinessOperation.BalanceInputDocument    = Common.MetadataObjectID(Metadata.Documents.OBEntryOfLeaseSettlements);
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư ban đầu hạch toán công nợ theo hợp đồng thuê %1';
																|ru = 'Ввод начальных остатков взаиморасчетов по договорам аренды %1';
																|en = 'OB entry: AR/AP under rental contracts %1'; fa = 'OB entry: AR/AP under rental contracts %1';
																|it = 'Inserimento dei saldi iniziali dei conti reciproci in base ai contratti di affitto%1';
																|pl = 'Wprowadzenie sald początkowych rozliczeń wzajemnych w ramach umów dzierżawy %1';
																|tr = 'Kira sözleşmeleri kapsamında karşılıklı ödemelerin başlangıç bakiyelerinin girişi %1'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;

	#EndRegion

	#Region RentOffBalance
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê ngoài bảng %1';
																|ru = 'Ввод начальных остатков предметов лизинга за балансом %1';
																|en = 'OB entry: financial lease assets (off balance sheet) %1'; fa = 'OB entry: financial lease assets (off balance sheet) %1';
																|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio %1';
																|pl = 'Wprowadzenie sald początkowych przedmiotów leasingu poza bilansem %1';
																|tr = 'Bilanço dışı kiralanan kalemlerin başlangıç bakiyelerinin girişi %1'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;

	//
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư đầu tài sản cố định đã thuê (ngoài bảng) %1';
																|ru = 'Ввод начальных остатков арендованных основных средств (за балансом) %1';
																|en = 'OB entry: leased fixed assets (off-balance) %1'; fa = 'OB entry: leased fixed assets (off-balance) %1';
																|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (fuori bilancio) %1';
																|pl = 'Wprowadzenie sald początkowych wynajmowanych środków trwałych (poza bilansem) %1';
																|tr = '%1 kiralanan sabit kıymetlerin açılış bakiyelerinin girilmesi (bilanço dışı)'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;
	
	#EndRegion
	
	#Region FinLease
	
	If ConsiderFOS And GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
		DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.EnterRentalInvestmentBalance;
		DescriptionOfBusinessOperation.BalanceInputDocument    = Common.MetadataObjectID(Metadata.Documents.EnterRentalInvestmentBalance);
		DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư đầu cho khoản đầu tư thuê %1';
																	|ru = 'Ввод начальных остатков инвестиции в аренду %1';
																	|en = 'OB: assets for rental investment %1'; fa = 'OB: assets for rental investment %1';
																	|it = 'Ввод начальных остатков инвестиции в аренду %1';
																	|pl = 'OB: assets for rental investment %1';
																	|tr = 'Kiralama için yatırımın açılış bakiyesi %1'");
		DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
		OrderInTree = OrderInTree + 1;
	EndIf;
	
	#EndRegion
	
	#Region Other
	
	DescriptionOfBusinessOperation = DescriptionOfBusinessOperationsForEnteringBalances.Add();
	DescriptionOfBusinessOperation.BusinessOperation    = Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets;
	DescriptionOfBusinessOperation.BalanceInputDocument    = NameOfInitialRemainderEntryDocument;
	DescriptionOfBusinessOperation.DocumentHeaderTemplate = NStr("vi = 'Nhập số dư đầu đầu tư vào tài sản dài hạn %1';
																|ru = 'Ввод начальных остатков вложений во внеоборотные активы %1';
																|en = 'OB entry: cost of fixed and intangible assets %1'; fa = 'OB entry: cost of fixed and intangible assets %1';
																|it = 'Inserimento dei saldi iniziali degli investimenti in attivi non circolanti %1';
																|pl = 'Wprowadzenie sald początkowych inwestycji w aktywa stałe %1';
																|tr = 'Duran varlıklara yapılan yatırımların başlangıç bakiyelerinin girişi %1'");
	DescriptionOfBusinessOperation.OrderInTree           = OrderInTree;
	OrderInTree = OrderInTree + 1;

	#EndRegion
	
	OBEntryLocalization.ToCompleteDescriptionOfBusinessOperationsOfEnteringBalanceOfBHA(DescriptionOfBusinessOperationsForEnteringBalances, ConsiderFOS, OrderInTree);
	
	Return DescriptionOfBusinessOperationsForEnteringBalances;
	
EndFunction

#EndRegion

#EndRegion
