#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a tree of sections of operations for entering balances
// 
// Parameters:
// 	FilterParameters - see the description of initializationparameters of the selected documents in the mainstays
// Returns:
// 	 ValueTree - A tree of values of operations for entering residuals.
//
Function InitializeTreeOfBusinessOperationsForEnteringInitialBalances(FilterParameters = Undefined) Export
	
	NoOrganizationSelection = True;
	ForAllTypesOfAccounting              = True;
	
	If FilterParameters = Undefined Then
		FilterParameters = InitializeSelectionParametersForEnteringInitialBalances();
	Else
		
		If FilterParameters.Property("Organization")
			And ValueIsFilled(FilterParameters.Organization) Then
			NoOrganizationSelection = False;
		EndIf;
		
		If NoOrganizationSelection Then
			FilterParameters.Insert("Organization", Catalogs.Companies.EmptyRef());
		EndIf;
		
		If FilterParameters.Property("FilterByAccountingKind")
			And ValueIsFilled(FilterParameters.FilterByAccountingKind)
			And FilterParameters.FilterByAccountingKind <> "NoFilter" Then
			
			ForAllTypesOfAccounting = False;
		EndIf;
		
	EndIf;
	
	DescriptionOfRazedelovInputBalances = OBEntryServerCached.DescriptionOfBalanceEntrySections();
	
	Query = New Query("SELECT
		|	ComplianceOfBusinessTransactionsSection.BusinessOperation AS BusinessOperation,
		|	ComplianceOfBusinessTransactionsSection.AccountingSection AS AccountingSection,
		|	ComplianceOfBusinessTransactionsSection.ExplanationOfAccountingSection AS ExplanationOfAccountingSection,
		|	ComplianceOfBusinessTransactionsSection.OrderInTree AS OrderInTree,
		|	ComplianceOfBusinessTransactionsSection.BalanceInputDocument AS BalanceInputDocument,
		|	ComplianceOfBusinessTransactionsSection.OrderInTreeOfHouseholdOperations AS OrderInTreeOfHouseholdOperations
		|INTO TTComplianceWithSectionBusinessTransactions
		|FROM
		|	&DescriptionOfRazedelovInputBalances AS ComplianceOfBusinessTransactionsSection
		|
		|INDEX BY
		|	BusinessOperation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
		|	COUNT(DISTINCT DocumentsRegistry.Ref) AS DocumentsCount
		|INTO NumberOfDocumentsEnteringBalances
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.RefType IN(&FilterByDocumentType)
		|	AND DocumentsRegistry.BusinessOperation IN(&FilterByTransactionTypes)
		|	AND (&ForAllOrg
		|			OR DocumentsRegistry.Organization = &Organization)
		|	AND (&ForAllTypesOfAccounting 
		|			OR &FilterByAccountingKind)
		|
		|GROUP BY
		|	DocumentsRegistry.BusinessOperation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PartitionStructure.AccountingSection AS AccountingSection,
		|	PartitionStructure.BusinessOperation AS DocumentBusinessTransaction,
		|	PartitionStructure.ExplanationOfAccountingSection AS ExplanationOfAccountingSection,
		|	SUM(NumberOfDocumentsEnteringBalances.DocumentsCount) AS DocumentsCount,
		|	PartitionStructure.OrderInTree AS OrderInTree,
		|	PartitionStructure.BalanceInputDocument AS BalanceInputDocument,
		|	PartitionStructure.OrderInTreeOfHouseholdOperations AS OrderInTreeOfHouseholdOperations
		|FROM
		|	TTComplianceWithSectionBusinessTransactions AS PartitionStructure
		|		LEFT JOIN NumberOfDocumentsEnteringBalances AS NumberOfDocumentsEnteringBalances
		|		ON (NumberOfDocumentsEnteringBalances.BusinessOperation = PartitionStructure.BusinessOperation)
		|
		|GROUP BY
		|	PartitionStructure.AccountingSection,
		|	PartitionStructure.BusinessOperation,
		|	PartitionStructure.ExplanationOfAccountingSection,
		|	PartitionStructure.OrderInTree,
		|	PartitionStructure.BalanceInputDocument,
		|	PartitionStructure.OrderInTreeOfHouseholdOperations
		|	
		|ORDER BY
		|	OrderInTree,
		|	OrderInTreeOfHouseholdOperations
		|TOTALS
		|	SUM(DocumentsCount)
		|BY
		|	AccountingSection");
	
	TextSelectionByTypeOfAccounting = "CASE";  //@Query-part
	
	ListOfTypesOfSelectionByAccountingSections = DataProcessors.JournalOfOBEntryDocuments.InitializeListOfSelectionTypesByAccountingSection();
	AvailableDocumentTypes_          = DescriptionOfRazedelovInputBalances.UnloadColumn("BalanceInputDocument");
	
	//Compatibility with the previous input of residues
	AvailableDocumentTypes_.Add(Common.MetadataObjectID(Metadata.Documents.OBEntry));
	
	For Each FilterElement In ListOfTypesOfSelectionByAccountingSections Do
		
		ValueOfSelectionElement = FilterElement.Value;
		
		If ValueOfSelectionElement = "NoFilter" Then
			Continue;
		EndIf;
		
		TextSelectionByTypeOfAccounting = TextSelectionByTypeOfAccounting + "
			|		WHEN &FilterByAccountingKind = """ + ValueOfSelectionElement + """
			|			THEN CASE ";
		
		SequenceNumberOfParameter = 0;
		For Each AvailableDocumentType In AvailableDocumentTypes_ Do
			
			SequenceNumberOfParameter = SequenceNumberOfParameter + 1;
			BalanceInputDocument    = AvailableDocumentType;
			DocumentTypeByString      = Common.ObjectAttributeValue(BalanceInputDocument, "FullName");
			MetadataOfDocument      = Common.MetadataObjectByID(BalanceInputDocument);
			ParameterByString          = "&RefType" + SequenceNumberOfParameter;
			
			If Common.HasObjectAttribute(ValueOfSelectionElement, MetadataOfDocument) Then
				TextSelectionByTypeOfAccounting = TextSelectionByTypeOfAccounting + "
					|				WHEN DocumentsRegistry.RefType = " + ParameterByString + "
					|					THEN CAST(DocumentsRegistry.Ref AS " + DocumentTypeByString + ")." + ValueOfSelectionElement;
			EndIf;
		EndDo;
		
		TextSelectionByTypeOfAccounting = TextSelectionByTypeOfAccounting + "
			|				ELSE FALSE
			|			END";
	EndDo;
	
	TextSelectionByTypeOfAccounting = TextSelectionByTypeOfAccounting + "
		|		ELSE FALSE
		|	END";
	
	Query.Text = StrReplace(Query.Text, "&FilterByAccountingKind", TextSelectionByTypeOfAccounting);
	
	SequenceNumberOfParameter  = 0;
	For Each AvailableDocumentType In AvailableDocumentTypes_ Do 
		
		SequenceNumberOfParameter = SequenceNumberOfParameter + 1;
		BalanceInputDocument            = AvailableDocumentType;
		ParameterByString                       = "RefType" + SequenceNumberOfParameter;
		
		Query.SetParameter(ParameterByString, BalanceInputDocument);
		
	EndDo;
	
	AvailableBusinessTransactions = DescriptionOfRazedelovInputBalances.UnloadColumn("BusinessOperation");
	
	Query.SetParameter("FilterByDocumentType",         AvailableDocumentTypes_);
	Query.SetParameter("FilterByTransactionTypes",           AvailableBusinessTransactions);
	Query.SetParameter("DescriptionOfRazedelovInputBalances", DescriptionOfRazedelovInputBalances);
	Query.SetParameter("ForAllOrg",                      NoOrganizationSelection);
	Query.SetParameter("ForAllTypesOfAccounting",               ForAllTypesOfAccounting);
	Query.SetParameter("Organization",                    FilterParameters.Organization);
	Query.SetParameter("FilterByAccountingKind",               FilterParameters.FilterByAccountingKind);
	Query.SetParameter("NoSection",                     NStr("vi = 'Tất cả văn bản';
															|ru = 'Все документы';
															|en = 'All documents'; fa = 'همه اسناد';
															|it = 'Tutti i documenti';
															|pl = 'Wszystkie dokumenty';
															|tr = 'Tüm belgeler'"));
	
	HierarchyOfResidueEntryOperations = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	Return HierarchyOfResidueEntryOperations;
	
EndFunction

// Document selection parameters for entering initial balances in the document tree.
// 
// Returns:
// 	Structure - LongDesc:
//        * AccountingSection - String - Accounting section for entering balances
//        * FilterByAccountingKind - String - Selection by type of accounting (operational, managerial, or regulated)
//        * Organization - CatalogRef.Companies - the organization for which the selection is made.
//
Function InitializeSelectionParametersForEnteringInitialBalances() Export
	
	FilterParameters = New Structure();
	FilterParameters.Insert("Organization",      Catalogs.Companies.EmptyRef());
	FilterParameters.Insert("FilterByAccountingKind", "");
	FilterParameters.Insert("AccountingSection",      "");
	
	Return FilterParameters;
	
EndFunction

// Returns the values of the list of accounting types for selection
// 
// Returns:
// 	ValueList - Values of selections by type of accounting 
Function InitializeListOfSelectionTypesByAccountingSection() Export
	
	RecordInMA = False;
	
	ListOfSelectionTypes = New ValueList();
	ListOfSelectionTypes.Add("NoFilter",                 NStr("vi = 'Tất cả các loại kế toán';
																|ru = 'Всем видам учета';
																|en = 'To all kind of accounting'; fa = 'To all kind of accounting';
																|it = 'Tutti i tipi di contabilità';
																|pl = 'Do wszystkich rodzajów ewidencji';
																|tr = 'Tüm muhasebe türlerine'"));
	ListOfSelectionTypes.Add("RecordInOperationalAccounting", NStr("vi = 'Kế toán hoạt động';
																	|ru = 'Оперативному учету';
																	|en = 'Operational accounting'; fa = 'حسابداری عملیاتی';
																	|it = 'Alla contabilità operativa';
																	|pl = 'Ewidencji operacyjnej';
																	|tr = 'Operasyonel muhasebeye'"));
	
	If GetFunctionalOption("UseLocal") Then
		ListOfSelectionTypes.Add("PostInFinancialAndTaxAccounting", NStr("vi = 'Kế toán và kế toán thuế';
																		|ru = 'Бухгалтерскому и налоговому учету';
																		|en = 'Accounting and tax accounting'; fa = 'Accounting and tax accounting';
																		|it = 'Alla contabilità e contabilità fiscale';
																		|pl = 'Księgowości i ewidencji podatkowej';
																		|tr = 'Genel muhasebe ve vergi muhasebesine'"));
	EndIf;
	
	If RecordInMA Then
		ListOfSelectionTypes.Add("RecordInMA", NStr("vi = 'Kế toán quản trị (trên một hệ thống tài khoản)';
													|ru = 'Управленческому учету (на едином плане счетов)';
													|en = 'Management accounting (unified chart of accounts)'; fa = 'Management accounting (unified chart of accounts)';
													|it = 'Alla contabilità gestionale (su un unico piano dei conti)';
													|pl = 'Ewidencji zarządczej (jednolity plan rachunków)';
													|tr = 'Yönetim muhasebesine (tek hesap planında)'"));
	EndIf;
	
	Return ListOfSelectionTypes;
	
EndFunction

#EndRegion

#EndIf