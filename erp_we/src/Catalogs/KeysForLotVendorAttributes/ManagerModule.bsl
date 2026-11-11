#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Compliance with the list of details that determine the uniqueness of the key
// 
// Returns:
//   Map - the key is the name of the props 
//
Function KeyAttributes() Export
	
	Return TMCommonUse.KeyDetailsOfKeyCatalogForInformationRegister(Metadata.InformationRegisters.LotVendorAttributes);
	
EndFunction

// Returns the batch accounting analysis key with the fields corresponding to the specified fields.
//
// Parameters:
//	AnalyticsFields - Structure, QueryResultSelection - fields for batch tracking Analytics.
//		If some Analytics fields are not specified in this parameter, these unspecified fields are filled in with empty values.
//		The "date" field must be present to determine the batch accounting mode that affects filling in the fields.
//	SearchForSuitableKey - Boolean - first try to find the key with the specified fields;
//		if the calling procedure has already searched for keys, then this parameter should be set to False to speed up the function.
//
// Returns:
//	CatalogRef.KeysForLotVendorAttributes - the found or generated batch accounting analytics key.
//
Function GetAnalyticsKey(AnalyticsFields = Undefined, SearchForSuitableKey = True) Export
	
	SetPrivilegedMode(True);
	
	// Fill in all the details of the analytics key.
	StructureOfKeyDetails = New Structure;
	
	For Each MetaAttribute In Metadata.Catalogs.KeysForLotVendorAttributes.Attributes Do
		
		AttributeStructure = New Structure(MetaAttribute.Name);
		FillPropertyValues(AttributeStructure, AnalyticsFields); // in the field of analytics, there may not be such a property
		
		StructureOfKeyDetails.Insert(
			MetaAttribute.Name,
			MetaAttribute.Type.AdjustValue(AttributeStructure[MetaAttribute.Name])); // and there is definitely such a property in the structure of the Visa
		
	EndDo;
	
	// We will take into account special cases of filling in the details.
	StructureOfKeyDetails.Insert("FinancialAccountingGroup", Catalogs.InventoryAccountingGroups.EmptyRef());
	
	If CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(AnalyticsFields.Date)) Then
		StructureOfKeyDetails.Insert("VATTaxation", Enums.VATTaxationTypes.EmptyRef());
	Else
		StructureOfKeyDetails.Insert("AssetTaxClass", 		Enums.AssetKinds.EmptyRef());
	EndIf;
	
	// If necessary, we will try to find a suitable key.
	KeyData = New Structure;
	KeyData.Insert("DimensionKey", 	   Catalogs.KeysForLotVendorAttributes.EmptyRef());
	KeyData.Insert("ThereIsRegisterEntry", False);
	
	If SearchForSuitableKey Then
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	Table.Ref AS DimensionKey
		|INTO TTKey
		|FROM
		|	Catalog.KeysForLotVendorAttributes AS Table
		|WHERE
		|	NOT Table.DeletionMark
		|	AND &FilterCriterion
		|
		|INDEX BY
		|	DimensionKey
		|;
		|////////////////////////////////////////////////////////
		|SELECT
		|	T.DimensionKey 			   AS DimensionKey,
		|	MAX(T.ThereIsRegisterEntry) AS ThereIsRegisterEntry
		|FROM
		|(SELECT TOP 1
		|	Table.DimensionKey,
		|	TRUE AS ThereIsRegisterEntry
		|FROM
		|	InformationRegister.LotVendorAttributes AS Table
		|	INNER JOIN TTKey AS TTKey
		|		ON Table.DimensionKey = TTKey.DimensionKey
		|WHERE
		|	TRUE
		|	AND &FilterCriterion
		|
		|UNION ALL
		|
		|SELECT
		|	Table.DimensionKey,
		|	FALSE AS ThereIsRegisterEntry
		|FROM
		|	TTKey AS Table
		|) AS T
		|
		|GROUP BY
		|	T.DimensionKey
		|";
		
		FilterText1 = "";
		
		For Each KeyAndValue In StructureOfKeyDetails Do
			
			Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
			
			FilterText1 = FilterText1 + "
				|	AND Table." + KeyAndValue.Key + " = &" + KeyAndValue.Key;
			
		EndDo;
		
		Query.Text = StrReplace(Query.Text, "AND &FilterCriterion", TrimAll(FilterText1));
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			FillPropertyValues(KeyData, Selection);
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(KeyData.DimensionKey) Then
		
		// The analytics key is not in the directory - let's create a directory element.
		CatalogObject = Catalogs.KeysForLotVendorAttributes.CreateItem();
		
		FillPropertyValues(CatalogObject, StructureOfKeyDetails);
		CatalogObject.Description = DimensionKeyName(StructureOfKeyDetails);
		
		CatalogObject.Write();
		
		KeyData.DimensionKey = CatalogObject.Ref;
		
	EndIf;
	
	If Not KeyData.ThereIsRegisterEntry Then
		
		// The analytics key is not in the register - we will add a register entry.
		Set = InformationRegisters.LotVendorAttributes.CreateRecordSet();
		
		For Each KeyAndValue In StructureOfKeyDetails Do
			Filter = Set.Filter[KeyAndValue.Key]; // FilterItem
			Filter.Set(KeyAndValue.Value);
		EndDo;
		
		Record = Set.Add();
		
		FillPropertyValues(Record, StructureOfKeyDetails);
		Record.DimensionKey = KeyData.DimensionKey;
		
		Set.AdditionalProperties.Insert("ThisIsNewSetOfRecords", True);
		Set.Write(True);
		
	EndIf;
	
	Return KeyData.DimensionKey;

EndFunction

// Used when generating document movements-initializes a table of values (a query parameter)
// and returns the text for creating a temporary table of document batch tracking Analytics from this table of values.
// Table field values TableLayoutPanel:
//		- Kataboliceski (as in the source table)
//		- Line numbers (as in the original table)
//		- Taxation of taxes (as in the original table)
//		- Type of value (as in the original table)
//		-  Of analyticalreports (matched an existing dimension or a new created)
//	A combination of fields (table Partname + line Number) can be used as a unique row identifier
//	to match rows in this table with rows in the source table.
//
// Parameters:
//	TextSelectionOfAnalystField - String - the text of the request for the formation of a temporary table in the field of the analysis of the accounting of parties with the fields:
//		* TabularSectionName - String -
//		* LineNumber - Number - 
//		* Vendor - CatalogRef.Partners - 
//		* Counterparty - CatalogRef.Counterparties - 
//		* VATTaxation - EnumRef.VATTaxationTypes - 
//		* VATRate - CatalogRef.VATRates - 
//		* AssetTaxClass - EnumRef.AssetKinds -
//		* RowCode - Number -
//		* Date - Date - optional
//			if the Date field is present, the batch accounting version check will be performed separately for each row of the table-on the date specified in this row
//			if there is no such field, the check will be performed the same for all rows of the table - on the document date
//	CommonQuery - Query - general request for the formation of document movements
//		The request must have initialized parameters:
//			Link - a link to the document itself
//			company - The company of the document
//			Period or Date - the date of the document
// 	QueryTexts - ValueList - texts of subqueries of the General query.
//
// Returns:
//	String - the text of the request to create a vttablecanalytic accountparties.
//
Function QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, CommonQuery, QueryTexts = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If CommonQuery.Parameters.Property("Period") Then
		DocumentDate = CommonQuery.Parameters.Period;
	Else
		DocumentDate = CommonQuery.Parameters.Date;
	EndIf;
	
	DocumentLink_ = CommonQuery.Parameters.Ref;
	
	// Let's create a query for selecting the analytics fields and fill in its properties.
	RequestPartyAnalytics = New Query;
	RequestPartyAnalytics.Text = TextSelectionOfAnalystField;
	If CommonQuery.TempTablesManager <> Undefined Then
		RequestPartyAnalytics.TempTablesManager = CommonQuery.TempTablesManager;
	Else
		RequestPartyAnalytics.TempTablesManager = New TempTablesManager;
	EndIf;
	
	RequestPartyAnalytics.SetParameter("Ref", 		  		   DocumentLink_);
	RequestPartyAnalytics.SetParameter("DocumentDate", 		   DocumentDate);
	
	If CommonQuery.Parameters.Property("BatchAccountingVersion22") Then
		RequestPartyAnalytics.SetParameter("BatchAccountingVersion22", CommonQuery.Parameters.BatchAccountingVersion22);
	Else
		RequestPartyAnalytics.SetParameter("BatchAccountingVersion22",
			CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(DocumentDate)));
	EndIf;
	
	RequestPartyAnalytics.SetParameter("DateOfMigrationToBatchAccounting22",
		CalculationOfCostCached.DateOfMigrationToBatchAccounting22());
	
	If CommonQuery.Parameters.Property("TaxationOfOrganization") Then
		RequestPartyAnalytics.SetParameter("TaxationOfOrganization", CommonQuery.Parameters.TaxationOfOrganization);
	EndIf;
	If CommonQuery.Parameters.Property("FIFORollingValuation") Then
		RequestPartyAnalytics.SetParameter("FIFORollingValuation", CommonQuery.Parameters.FIFORollingValuation);
	EndIf;
	If CommonQuery.Parameters.Property("KeepRecordsOfInventoryCostByAssignments") Then
		RequestPartyAnalytics.SetParameter("KeepRecordsOfInventoryCostByAssignments", CommonQuery.Parameters.KeepRecordsOfInventoryCostByAssignments);
	EndIf;
	If CommonQuery.Parameters.Property("SimplifiedTaxationSystem") Then
		RequestPartyAnalytics.SetParameter("SimplifiedTaxationSystem", CommonQuery.Parameters.SimplifiedTaxationSystem);
	EndIf;
	
	If CommonQuery.Parameters.Property("ExportVATRate") Then
		RequestPartyAnalytics.SetParameter("ExportVATRate", CommonQuery.Parameters.ExportVATRate);
	Else
		VATAccountingERP.SetParametersForVATRateRequest(RequestPartyAnalytics.Parameters, CommonQuery.Parameters.Organization, DocumentDate);
	EndIf;
	
	// Let's form a temporary table for the analysis of Party accounts.
	RequestPartyAnalytics.Execute();
	
	// Let's create the missing analytics keys.
	RequestPartyAnalytics.Text =
	"SELECT
	|	T.TabularSectionName 													AS TabularSectionName,
	|	T.LineNumber 															AS LineNumber,
	|	VALUE(Catalog.InventoryAccountingGroups.EmptyRef)	AS FinancialAccountingGroup,
	|	CASE WHEN VALUETYPE(T.Vendor) <> TYPE(Catalog.Partners)
	|		THEN VALUE(Catalog.Partners.EmptyRef)
	|		ELSE T.Vendor
	|	END 																	AS Vendor,
	|	CASE WHEN
	|	  NOT VALUETYPE(T.Counterparty) IN (TYPE(Catalog.Companies), TYPE(Catalog.Counterparties))
	|	  OR T.Counterparty IN (VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Counterparties.EmptyRef))
	|		THEN UNDEFINED
	|		ELSE T.Counterparty
	|	END 																	AS Counterparty,
	|	CASE WHEN VALUETYPE(T.VATRate) <> TYPE(Catalog.VATRates)
	|		THEN VALUE(Catalog.VATRates.EmptyRef)
	|		ELSE T.VATRate
	|	END 																	AS VATRate,
	|	CASE WHEN VALUETYPE(T.VATTaxation) <> TYPE(Enum.VATTaxationTypes)
	|		THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE T.VATTaxation
	|	END 																	AS VATTaxation,
	|	CASE WHEN VALUETYPE(T.AssetTaxClass) <> TYPE(Enum.AssetKinds)
	|		THEN VALUE(Enum.AssetKinds.EmptyRef)
	|		ELSE T.AssetTaxClass
	|	END 																	AS AssetTaxClass,
	|	T.RowCode 															AS RowCode,
	|	&DocumentDate															AS Date,
	|	&BatchAccountingVersion22
	|		AND &DocumentDate >= &DateOfMigrationToBatchAccounting22 			AS BatchAccountingVersion22
	|INTO TTAnalyst_ValidBatchTrackingAnalystFields
	|FROM
	|	TTBatchAccountingAnalyst AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.TabularSectionName 													AS TabularSectionName,
	|	T.LineNumber 															AS LineNumber,
	|	T.FinancialAccountingGroup 												AS FinancialAccountingGroup,
	|	T.Vendor 															AS Vendor,
	|	T.Counterparty 															AS Counterparty,
	|	T.VATRate 															AS VATRate,
	|	CASE WHEN T.BatchAccountingVersion22
	|		THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE T.VATTaxation
	|	END 																	AS VATTaxation,
	|	CASE WHEN NOT T.BatchAccountingVersion22
	|		THEN VALUE(Enum.AssetKinds.EmptyRef)
	|		ELSE T.AssetTaxClass
	|	END 																	AS AssetTaxClass,
	|	T.RowCode																AS RowCode,
	|	T.Date																	AS Date,
	|	MAX(ISNULL(DimensionOfLots.DimensionKey,
	|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)))		AS LotVendorAttributes
	|INTO TTAnalyst_TableBatchAccountingAnalystPreliminary
	|FROM
	|	TTAnalyst_ValidBatchTrackingAnalystFields AS T
	|	LEFT JOIN InformationRegister.LotVendorAttributes AS DimensionOfLots
	|		ON T.FinancialAccountingGroup 				= DimensionOfLots.FinancialAccountingGroup
	|			AND T.Vendor 						 	= DimensionOfLots.Vendor
	|			AND T.Counterparty 						 	= DimensionOfLots.Counterparty
	|			AND CASE WHEN T.BatchAccountingVersion22
	|				THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|				ELSE T.VATTaxation
	|			  END 							 	= DimensionOfLots.VATTaxation
	|			AND T.VATRate 						 	= DimensionOfLots.VATRate
	|			AND CASE WHEN NOT T.BatchAccountingVersion22
	|				THEN VALUE(Enum.AssetKinds.EmptyRef)
	|				ELSE T.AssetTaxClass
	|			  END 								= DimensionOfLots.AssetTaxClass
	|			AND T.RowCode 							= DimensionOfLots.RowCode
	|GROUP BY
	|	T.TabularSectionName,
	|	T.LineNumber,
	|	T.FinancialAccountingGroup,
	|	T.Vendor,
	|	T.Counterparty,
	|	T.VATRate,
	|	CASE WHEN T.BatchAccountingVersion22
	|		THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE T.VATTaxation
	|	END, // VATTaxation
	|	CASE WHEN NOT T.BatchAccountingVersion22
	|		THEN VALUE(Enum.AssetKinds.EmptyRef)
	|		ELSE T.AssetTaxClass
	|	END, // AssetTaxClass
	|	T.RowCode,
	|	T.Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	&DocumentDate				AS Date,
	|	T.FinancialAccountingGroup	AS FinancialAccountingGroup,
	|	T.Vendor					AS Vendor,
	|	T.Counterparty				AS Counterparty,
	|	T.VATRate					AS VATRate,
	|	T.VATTaxation		AS VATTaxation,
	|	T.AssetTaxClass				AS AssetTaxClass,
	|	T.RowCode					AS RowCode,
	|	T.LotVendorAttributes		AS LotVendorAttributes
	|FROM
	|	TTAnalyst_TableBatchAccountingAnalystPreliminary AS T
	|WHERE
	|	T.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|";
	
	ThereIsPeriodInTable = CostCalculationAppliedAlgorithms.TemporaryTableColumnExists(
		RequestPartyAnalytics,
		"TTBatchAccountingAnalyst",
		"Date");
	
	If ThereIsPeriodInTable Then
			
		RequestPartyAnalytics.SetParameter("BatchAccountingVersion22", CalculationOfCostCached.BatchAccountingVersion22());
		
		RequestPartyAnalytics.Text = StrReplace(RequestPartyAnalytics.Text, "&DocumentDate", "T.Date");
		
	EndIf;
	
	TableOfEmptyAnalysts = RequestPartyAnalytics.Execute().Unload();
	
	// If the value of the Counterparty column = Undefined, the description of the value types of this column will be empty.
	// In this case, the platform will not be able to select values from the untyped column in the next request.
	// To bypass this situation, we will create a column in the table with the "correct" type of values and replace the original column with it.
	TableOfEmptyAnalysts.Columns.Add("CounterpartyTyped",
		Metadata.Catalogs.KeysForLotVendorAttributes.Attributes.Counterparty.Type);
	
	For Each CurrRow In TableOfEmptyAnalysts Do
		CurrRow.LotVendorAttributes 	= GetAnalyticsKey(CurrRow, False); // create a key without trying to find it
		CurrRow.CounterpartyTyped = CurrRow.Counterparty;
	EndDo;
	
	TableOfEmptyAnalysts.Columns.Delete("Counterparty");
	TableColumn2 = TableOfEmptyAnalysts.Columns.CounterpartyTyped; // ValueTableColumn
	TableColumn2.Name = "Counterparty";
	
	// Let's form a table of analysts.
	// We will return the fields of taxation and type of value from the source table, and not from the batch accounting analytics,
	// because these fields may not be filled in in analytics (depending on the version of the batch accounting mechanism used).
	RequestPartyAnalytics.SetParameter("TableOfCreatedAnalytics", TableOfEmptyAnalysts);
	
	RequestPartyAnalytics.Text =
	"SELECT
	|	T.FinancialAccountingGroup	AS FinancialAccountingGroup,
	|	T.Vendor					AS Vendor,
	|	T.Counterparty				AS Counterparty,
	|	T.VATRate					AS VATRate,
	|	T.VATTaxation		AS VATTaxation,
	|	T.AssetTaxClass				AS AssetTaxClass,
	|	T.RowCode					AS RowCode,
	|	T.LotVendorAttributes		AS LotVendorAttributes
	|INTO TTAnalyst_TableOfCreatedAnalysts
	|FROM
	|	&TableOfCreatedAnalytics AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.TabularSectionName 										AS TabularSectionName,
	|	T.LineNumber 													AS LineNumber,
	|	T.RowCode 														AS RowCode,
	|	RawData.VATTaxation 	AS VATTaxation,
	|	RawData.AssetTaxClass 						AS AssetTaxClass,
	|	ISNULL(TableOfCreatedAnalytics.LotVendorAttributes, T.LotVendorAttributes) AS LotVendorAttributes
	|FROM
	|	TTAnalyst_TableBatchAccountingAnalystPreliminary AS T
	|	LEFT JOIN TTAnalyst_ValidBatchTrackingAnalystFields AS RawData
	|		ON T.TabularSectionName		= RawData.TabularSectionName
	|			AND T.LineNumber			= RawData.LineNumber
	|	LEFT JOIN TTAnalyst_TableOfCreatedAnalysts AS TableOfCreatedAnalytics
	|		ON T.LotVendorAttributes 		= VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			AND T.FinancialAccountingGroup	= TableOfCreatedAnalytics.FinancialAccountingGroup
	|			AND T.Vendor				= TableOfCreatedAnalytics.Vendor
	|			AND T.Counterparty				= TableOfCreatedAnalytics.Counterparty
	|			AND T.VATRate				= TableOfCreatedAnalytics.VATRate
	|			AND T.VATTaxation 		= TableOfCreatedAnalytics.VATTaxation
	|			AND T.AssetTaxClass				= TableOfCreatedAnalytics.AssetTaxClass
	|			AND T.RowCode				= TableOfCreatedAnalytics.RowCode
	|;
	|/////////////////////////////
	|DROP TTAnalyst_TableBatchAccountingAnalystPreliminary
	|;
	|/////////////////////////////
	|DROP TTAnalyst_ValidBatchTrackingAnalystFields
	|;
	|/////////////////////////////
	|DROP TTAnalyst_TableOfCreatedAnalysts
	|";
	
	TableOfBatchAccountingAnalysts = RequestPartyAnalytics.Execute().Unload();
	
	// Let's put the analytics in a temporary table of the general query.
	CommonQuery.SetParameter("TableOfBatchAccountingAnalysts", TableOfBatchAccountingAnalysts);
	
	QueryText = "
	|SELECT
	|	T.TabularSectionName		AS TabularSectionName,
	|	T.LineNumber					AS LineNumber,
	|	T.RowCode							AS RowCode,
	|	T.VATTaxation	AS VATTaxation,
	|	T.AssetTaxClass						AS AssetTaxClass,
	|	T.LotVendorAttributes 	AS LotVendorAttributes
	|INTO TTTableOfPartyAccountingAnalysts
	|FROM
	|	&TableOfBatchAccountingAnalysts AS T
	|INDEX BY
	|	LineNumber,
	|	TabularSectionName
	|";
	
	// Let's add the query to the list of general query texts.
	If QueryTexts <> Undefined Then
		QueryTexts.Add(QueryText, "TTTableOfPartyAccountingAnalysts");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Generates the name of the batch tracking Analytics key.
//
// Parameters:
//	StructureOfKeyDetails - Structure - fields of the key for the batch tracking analysis that you want to create a name for.
//
// Returns:
//	String
//
Function DimensionKeyName(StructureOfKeyDetails) Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	Description = "";
	
	If ValueIsFilled(StructureOfKeyDetails.FinancialAccountingGroup) Then
		Description = Description + NStr("vi = 'Nhóm';
										|ru = 'Группа';
										|en = 'Group'; fa = 'گروه';
										|it = 'Gruppo';
										|pl = 'Grupa';
										|tr = 'Grup'", DefaultLanguageCode) + ": " + StructureOfKeyDetails.FinancialAccountingGroup + "; ";
	EndIf;
	
	If ValueIsFilled(StructureOfKeyDetails.Vendor) Then
		Description = Description + NStr("vi = 'Nhà cung cấp';
										|ru = 'Поставщик';
										|en = 'Vendor'; fa = 'تأمین‌کننده';
										|it = 'Fornitore';
										|pl = 'Dostawca';
										|tr = 'Tedarikçi'", DefaultLanguageCode) + ": " + StructureOfKeyDetails.Vendor + "; ";
	EndIf;
	
	If ValueIsFilled(StructureOfKeyDetails.Counterparty) Then
		Description = Description + NStr("vi = 'Đối tác';
										|ru = 'Контрагент';
										|en = 'Counterparty'; fa = 'طرف حساب';
										|it = 'Controparte';
										|pl = 'Kontrahent';
										|tr = 'Cari hesap'", DefaultLanguageCode) + ": " + StructureOfKeyDetails.Counterparty + "; ";
	EndIf;
	
	If ValueIsFilled(StructureOfKeyDetails.VATTaxation) Then
		Description = Description + NStr("vi = 'Chịu thuế GTGT';
										|ru = 'Налогообложение НДС';
										|en = 'VAT taxation'; fa = 'مشمولیت مالیات بر ارزش افزوده';
										|it = 'Tassazione IVA';
										|pl = 'Opodatkowanie VAT';
										|tr = 'KDV vergilendirilmesi'", DefaultLanguageCode) + ": " + StructureOfKeyDetails.VATTaxation + "; ";
	EndIf;
		
	If ValueIsFilled(StructureOfKeyDetails.VATRate) Then
		// We will get the name of the analytics key in the main language, taking into account the multilingualism of the StavkiNDS directory
		Description = Description + NStr("vi = 'Thuế suất GTGT';
										|ru = 'Ставка НДС';
										|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
										|it = 'Aliquota IVA';
										|pl = 'Stawka VAT';
										|tr = 'KDV oranı'", DefaultLanguageCode) + ": " + Common.ObjectAttributeValue(StructureOfKeyDetails.VATRate, "Description") + "; ";
	EndIf;
	
	If ValueIsFilled(StructureOfKeyDetails.AssetTaxClass) Then
		Description = Description + NStr("vi = 'Dạng giá trị';
										|ru = 'Вид ценности';
										|en = 'Asset tax class'; fa = 'طبقه مالیاتی دارایی';
										|it = 'Tipo dei beni';
										|pl = 'Rodzaj wartości';
										|tr = 'Varlık vergi sınıfı'", DefaultLanguageCode) + ": " + StructureOfKeyDetails.AssetTaxClass + "; ";
	EndIf;  	
	
	If ValueIsFilled(StructureOfKeyDetails.RowCode) Then
		Description = Description + NStr("vi = 'Mã dòng (sản phẩm)';
										|ru = 'Код строки (продукция)';
										|en = 'Line code (manufactured products)'; fa = 'Line code (manufactured products)';
										|it = 'Codice di riga (prodotti)';
										|pl = 'Kod wiersza (wiersze pozycji)';
										|tr = 'Satır kodu (imal edilen ürünler)'", DefaultLanguageCode) + ": " + StructureOfKeyDetails.RowCode;
	EndIf;
	
	Description = TrimAll(Description);
	
	If Right(Description, 1) = ";" Then
		Description = TrimAll(Mid(Description, 1, StrLen(Description) - 1));
	EndIf;
	
	If Not ValueIsFilled(Description) Then
		Description = "<>";
	EndIf;
	
	Return Description;
	
EndFunction

#EndRegion

#Region Private

// Replaces duplicates of Analytics keys.
//
Procedure ReplaceDimensionKeyDuplicates() Export
	
	Query = New Query("
	|SELECT
	|	CatalogData.Ref 			AS Ref,
	|	CatalogData.DeletionMark 	AS DeletionMark,
	|	Dimension.DimensionKey 			AS DimensionKey
	|FROM
	|	Catalog.KeysForLotVendorAttributes AS CatalogData
	|
	|	LEFT JOIN
	|		InformationRegister.LotVendorAttributes AS RegisterData
	|	ON
	|		CatalogData.Ref = RegisterData.DimensionKey
	|
	|	INNER JOIN
	|		InformationRegister.LotVendorAttributes AS Dimension
	|	ON
	|		CatalogData.FinancialAccountingGroup = Dimension.FinancialAccountingGroup
	|		AND CatalogData.Vendor 			 = Dimension.Vendor
	|		AND CatalogData.Counterparty			 = Dimension.Counterparty
	|		AND CatalogData.VATTaxation 	 = Dimension.VATTaxation
	|		AND CatalogData.VATRate 			 = Dimension.VATRate
	|		AND CatalogData.AssetTaxClass 		 = Dimension.AssetTaxClass
	|		AND CatalogData.RowCode			 = Dimension.RowCode
	|WHERE
	|	RegisterData.DimensionKey IS NULL
	|");
	
	// Let's form the correspondence of the analytics keys.
	ComplianceAnalyst = New Map;
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
	
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ComplianceAnalyst.Insert(Selection.Ref, Selection.DimensionKey);
			
			If Not Selection.DeletionMark Then
				CatalogObject = Selection.Ref.GetObject();
				CatalogObject.SetDeletionMark(True, False);
			EndIf;

		EndDo;
		
		TMCommonUse.ReplaceReferences(ComplianceAnalyst);
		
	EndIf;
		
EndProcedure

#EndRegion

#EndIf
