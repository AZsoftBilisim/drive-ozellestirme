#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Returns the structure of the selection of settings for filling in the sub-konto.
// 
// Parameters:
// 	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - International accounting Chart of Accounts.
// 	PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - Setting up the formation of transactions.
// 	AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems - The object of financial accounting for which the accounting accounts used are obtained.
// 	GLAccount - ChartOfAccountsRef.International - The accounting account for which you want to get the status. If Undefined, then for all.
// 
// Returns:
//	Structure - Filter:
//		* ChartOfAccounts -  CatalogRef.FinancialAccountingChartsOfAccounts -
//		* PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting -
//		* AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems -
//		* GLAccount - ChartOfAccountsRef.International - 
//
Function SelectingExtdimensionFillingSettings(ChartOfAccounts, PostingGenerationSetting, AccountingObject, GLAccount = Undefined) Export
	
	Filter = New Structure;
	Filter.Insert("ChartOfAccounts", ChartOfAccounts);
	Filter.Insert("PostingGenerationSetting", PostingGenerationSetting);
	Filter.Insert("AccountingObject", AccountingObject);
	Filter.Insert("GLAccount", GLAccount);
	
	Return Filter;
	
EndFunction

// Returns the settings for filling in the sub-invoice on the accounts on the accounting accounts.
// 
// Parameters:
// 	Filter - See DataProcessors.SettingUpFinancialAccountingAccounts.SelectingExtdimensionFillingSettings
// 	SettingsComposer - DataCompositionSettingsComposer - Required to check the correctness of filling in the sub-konto .
// 	UseManualSettings - Boolean - If False, the user settings are ignored.
// 	
// Returns:
// 	ValueTable - Setup State Table:
// 		* GLAccount - ChartOfAccountsRef.International - Accounting account
// 		* UserSetting - Boolean - Indicates whether to use the custom setting for filling in the sub-konto
// 		* ThereAreExtdimensionFillingIssues - Boolean - Indicates whether there are problems filling in the subconto
// 		
// 		* ExtDimensionType1 - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - View of the first sub-account on the account
// 		* ExtdimensionValueType1 - TypeDescription - Type of the first sub-account on the account
// 		* MethodOfFillingExtdimension1 - EnumRef.MethodsOfFinancialAccountingExtraDimensionFilling - Method of filling in the first sub-account on the account
// 		* ExpressionOfExtdimensionFilling1 - String - If the first subconto is filled "Out Of case", then the expression to get the value
// 		* SpecifiedValueIsExtdimension1 - CatalogRef,
// 		                               Document Link,
// 		                               Enumerationsreferences,
// 		                               Planviewcharacteristicslink - If the first subconto is filled in "Out of case", then the expression to get the value
// 		* ThereAreExtdimensionFillingIssues1 - Boolean - Indicates if there are problems filling in the first subconto
// 		
// 		* ExtDimensionType2 - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - View of the second sub-account on the account
// 		* ExtdimensionValueType2 - TypeDescription - Type of the second sub-account on the account
// 		* MethodOfFillingExtdimension2 - EnumRef.MethodsOfFinancialAccountingExtraDimensionFilling - Method of filling in the second sub-account on the account
// 		* ExpressionOfExtdimensionFilling2 - String - If the second subconto is filled "Out Of case", then the expression to get the value
// 		* SpecifiedValueIsExtdimension2 - CatalogRef,
// 		                               Document Link,
// 		                               Enumerationsreferences,
// 		                               Planviewcharacteristicslink - If the second subconto is filled in "Out of case", then the expression to get the value
// 		* ThereAreExtdimensionFillingIssues2 - Boolean - Indicates if there are problems filling in the second subconto
// 		
// 		* ExtDimensionType3 - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - View of the third sub-account on the account
// 		* ExtdimensionValueType3 - TypeDescription - Type of the third sub-account on the account
// 		* MethodOfFillingExtdimension3 - EnumRef.MethodsOfFinancialAccountingExtraDimensionFilling - Method of filling in the third sub-account on the account
// 		* ExpressionOfExtdimensionFilling3 - String - If the third subconto is filled "Out Of case", then the expression to get the value
// 		* SpecifiedValueIsExtdimension3 - CatalogRef,
// 		                               Document Link,
// 		                               Enumerationsreferences,
// 		                               Planviewcharacteristicslink - If the third sub-conto is filled in "Out of case", then the expression to get the value
// 		* ThereAreExtdimensionFillingIssues3 - Boolean - Indicates that there are problems filling in the third subconto
//
Function ExtraDimensionFillingSettings(Filter, SettingsComposer, UseManualSettings = True) Export
	
	SetupStatus = New ValueTable();
	SetupStatus.Columns.Add("GLAccount", New TypeDescription("ChartOfAccountsRef.International"));
	SetupStatus.Columns.Add("UserSetting", New TypeDescription("Boolean"));
	SetupStatus.Columns.Add("ThereAreExtdimensionFillingIssues", New TypeDescription("Boolean"));
	
	DescriptionOfExtdimensionValueTypes = Metadata.ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Type;
	
	SetupStatus.Columns.Add("ExtDimensionType1", New TypeDescription("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes"));
	SetupStatus.Columns.Add("ExtdimensionValueType1", New TypeDescription("TypeDescription"));
	SetupStatus.Columns.Add("MethodOfFillingExtdimension1", New TypeDescription("EnumRef.MethodsOfFinancialAccountingExtraDimensionFilling"));
	SetupStatus.Columns.Add("ExpressionOfExtdimensionFilling1", New TypeDescription("String"));
	SetupStatus.Columns.Add("SpecifiedValueIsExtdimension1", DescriptionOfExtdimensionValueTypes);
	SetupStatus.Columns.Add("ThereAreExtdimensionFillingIssues1", New TypeDescription("Boolean"));
	
	SetupStatus.Columns.Add("ExtDimensionType2", New TypeDescription("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes"));
	SetupStatus.Columns.Add("ExtdimensionValueType2", New TypeDescription("TypeDescription"));
	SetupStatus.Columns.Add("MethodOfFillingExtdimension2", New TypeDescription("EnumRef.MethodsOfFinancialAccountingExtraDimensionFilling"));
	SetupStatus.Columns.Add("ExpressionOfExtdimensionFilling2", New TypeDescription("String"));
	SetupStatus.Columns.Add("SpecifiedValueIsExtdimension2", DescriptionOfExtdimensionValueTypes);
	SetupStatus.Columns.Add("ThereAreExtdimensionFillingIssues2", New TypeDescription("Boolean"));
	
	SetupStatus.Columns.Add("ExtDimensionType3", New TypeDescription("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes"));
	SetupStatus.Columns.Add("ExtdimensionValueType3", New TypeDescription("TypeDescription"));
	SetupStatus.Columns.Add("MethodOfFillingExtdimension3", New TypeDescription("EnumRef.MethodsOfFinancialAccountingExtraDimensionFilling"));
	SetupStatus.Columns.Add("ExpressionOfExtdimensionFilling3", New TypeDescription("String"));
	SetupStatus.Columns.Add("SpecifiedValueIsExtdimension3", DescriptionOfExtdimensionValueTypes);
	SetupStatus.Columns.Add("ThereAreExtdimensionFillingIssues3", New TypeDescription("Boolean"));
	
	If Not ValueIsFilled(Filter.ChartOfAccounts)
		Or Not ValueIsFilled(Filter.PostingGenerationSetting)
		Or Not ValueIsFilled(Filter.AccountingObject) Then
		Return SetupStatus;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	InvoiceSettingsByMapItem.ChartOfAccounts AS ChartOfAccounts,
	|	InvoiceSettingsByMapItem.PostingGenerationSetting AS PostingGenerationSetting,
	|	InvoiceSettingsByMapItem.AccountingObject AS AccountingObject,
	|	CASE
	|		WHEN UrgencyOfAccountingAccounts.LongTerm
	|			THEN InvoiceSettingsByMapItem.LedgerAccountLongTerm
	|		ELSE InvoiceSettingsByMapItem.GLAccount
	|	END AS GLAccount
	|INTO TTSetUpAccountsByObjects
	|FROM
	|	InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS InvoiceSettingsByMapItem
	|	,
	|	(SELECT
	|		FALSE AS LongTerm
	|	UNION ALL
	|	SELECT
	|		TRUE AS LongTerm
	|	WHERE
	|		TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
	|			WHERE
	|				TransactionGenerationSettings.Ref = &PostingGenerationSetting
	|				AND TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities
	|		)
	|	) AS UrgencyOfAccountingAccounts
	|WHERE
	|	InvoiceSettingsByMapItem.ChartOfAccounts = &ChartOfAccounts
	|	AND InvoiceSettingsByMapItem.PostingGenerationSetting = &PostingGenerationSetting
	|	AND InvoiceSettingsByMapItem.AccountingObject = &AccountingObject
	|	AND (&AllAccountingAccounts
	|		OR CASE
	|			WHEN UrgencyOfAccountingAccounts.LongTerm
	|				THEN InvoiceSettingsByMapItem.LedgerAccountLongTerm
	|			ELSE InvoiceSettingsByMapItem.GLAccount
	|		END = &GLAccount)
	|INDEX BY
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	AccountingObject,
	|	GLAccount
	|;
	|
	|/////////////////////////////////
	|SELECT
	|	InvoiceSettingsByMapItem.GLAccount AS GLAccount,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.ExtDimensionType1 IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS UserSetting,
	|	ISNULL(ExtraDimensionFillingSettings.ExtDimensionType1, UNDEFINED) AS ExtDimensionType1,
	|	ISNULL(ExtraDimensionFillingSettings.MethodOfFillingExtdimension1, UNDEFINED) AS MethodOfFillingExtdimension1,
	|	ISNULL(ExtraDimensionFillingSettings.ExpressionOfExtdimensionFilling1, UNDEFINED) AS ExpressionOfExtdimensionFilling1,
	|	ISNULL(ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension1, UNDEFINED) AS SpecifiedValueIsExtdimension1,
	|	ISNULL(ExtraDimensionFillingSettings.ExtDimensionType2, UNDEFINED) AS ExtDimensionType2,
	|	ISNULL(ExtraDimensionFillingSettings.MethodOfFillingExtdimension2, UNDEFINED) AS MethodOfFillingExtdimension2,
	|	ISNULL(ExtraDimensionFillingSettings.ExpressionOfExtdimensionFilling2, UNDEFINED) AS ExpressionOfExtdimensionFilling2,
	|	ISNULL(ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension2, UNDEFINED) AS SpecifiedValueIsExtdimension2,
	|	ISNULL(ExtraDimensionFillingSettings.ExtDimensionType3, UNDEFINED) AS ExtDimensionType3,
	|	ISNULL(ExtraDimensionFillingSettings.MethodOfFillingExtdimension3, UNDEFINED) AS MethodOfFillingExtdimension3,
	|	ISNULL(ExtraDimensionFillingSettings.ExpressionOfExtdimensionFilling3, UNDEFINED) AS ExpressionOfExtdimensionFilling3,
	|	ISNULL(ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension3, UNDEFINED) AS SpecifiedValueIsExtdimension3
	|INTO TTExtdimensionFillSettings
	|FROM
	|	TTSetUpAccountsByObjects AS InvoiceSettingsByMapItem
	|	LEFT JOIN
	|		InformationRegister.SettingsForFillingExtraDimensionOnFinancialAccountingAccounts AS ExtraDimensionFillingSettings
	|	ON
	|		InvoiceSettingsByMapItem.ChartOfAccounts = ExtraDimensionFillingSettings.ChartOfAccounts
	|		AND InvoiceSettingsByMapItem.PostingGenerationSetting = ExtraDimensionFillingSettings.PostingGenerationSetting
	|		AND InvoiceSettingsByMapItem.AccountingObject = ExtraDimensionFillingSettings.AccountingObject
	|		AND InvoiceSettingsByMapItem.GLAccount = ExtraDimensionFillingSettings.GLAccount
	|		AND &UseManualSettings
	|INDEX BY
	|	GLAccount
	|;
	|
	|/////////////////////////////////
	|SELECT
	|	International.Ref AS GLAccount,
	|	ISNULL(ExtDimensionTypes1.ExtDimensionType, 
	|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType1,
	|	ExtDimensionTypes1.ExtDimensionType.ValueType AS ExtdimensionValueType1,
	|	ISNULL(ExtDimensionTypes2.ExtDimensionType,
	|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType2,
	|	ExtDimensionTypes2.ExtDimensionType.ValueType AS ExtdimensionValueType2,
	|	ISNULL(ExtDimensionTypes3.ExtDimensionType,
	|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType3,
	|	ExtDimensionTypes3.ExtDimensionType.ValueType AS ExtdimensionValueType3,
	|	TTExtdimensionFillSettings.UserSetting AS UserSetting,
	|	TTExtdimensionFillSettings.ExtDimensionType1 AS CustomSettingExtdimensionView1,
	|	TTExtdimensionFillSettings.MethodOfFillingExtdimension1 AS MethodOfFillingExtdimension1,
	|	TTExtdimensionFillSettings.ExpressionOfExtdimensionFilling1 AS ExpressionOfExtdimensionFilling1,
	|	TTExtdimensionFillSettings.SpecifiedValueIsExtdimension1 AS SpecifiedValueIsExtdimension1,
	|	TTExtdimensionFillSettings.ExtDimensionType2 AS CustomSettingExtdimensionView2,
	|	TTExtdimensionFillSettings.MethodOfFillingExtdimension2 AS MethodOfFillingExtdimension2,
	|	TTExtdimensionFillSettings.ExpressionOfExtdimensionFilling2 AS ExpressionOfExtdimensionFilling2,
	|	TTExtdimensionFillSettings.SpecifiedValueIsExtdimension2 AS SpecifiedValueIsExtdimension2,
	|	TTExtdimensionFillSettings.ExtDimensionType3 AS CustomSettingExtdimensionView3,
	|	TTExtdimensionFillSettings.MethodOfFillingExtdimension3 AS MethodOfFillingExtdimension3,
	|	TTExtdimensionFillSettings.ExpressionOfExtdimensionFilling3 AS ExpressionOfExtdimensionFilling3,
	|	TTExtdimensionFillSettings.SpecifiedValueIsExtdimension3 AS SpecifiedValueIsExtdimension3
	|FROM
	|	ChartOfAccounts.International AS International 
	|	INNER JOIN
	|		TTExtdimensionFillSettings AS TTExtdimensionFillSettings
	|	ON
	|		International.Ref = TTExtdimensionFillSettings.GLAccount
	|		
	|	LEFT JOIN
	|		ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes1
	|	ON
	|		International.Ref = ExtDimensionTypes1.Ref
	|		AND ExtDimensionTypes1.LineNumber = 1
	|		
	|	LEFT JOIN
	|		ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes2
	|	ON
	|		International.Ref = ExtDimensionTypes2.Ref
	|		AND ExtDimensionTypes2.LineNumber = 2
	|	
	|	LEFT JOIN
	|		ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes3
	|	ON
	|		International.Ref = ExtDimensionTypes3.Ref
	|		AND ExtDimensionTypes3.LineNumber = 3
	|WHERE
	|	(International.Ref = &GLAccount 
	|		OR &AllAccountingAccounts)
	|";
	
	Query.SetParameter("ChartOfAccounts", Filter.ChartOfAccounts);
	Query.SetParameter("PostingGenerationSetting", Filter.PostingGenerationSetting);
	Query.SetParameter("AccountingObject", Filter.AccountingObject);
	Query.SetParameter("GLAccount", Filter.GLAccount);
	Query.SetParameter("AllAccountingAccounts", Not ValueIsFilled(Filter.GLAccount));
	Query.SetParameter("UseManualSettings", UseManualSettings);
	
	DescriptionOfAccountingObject_ = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObject(Filter.AccountingObject);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = SetupStatus.Add();
		FillPropertyValues(NewRow, Selection);
		If NewRow.UserSetting Then
			FillStateOfManualExtdimensionFillSetting(NewRow, SettingsComposer);
		Else
			FillInAutoFillStateOfExtdimension(NewRow, DescriptionOfAccountingObject_);
		EndIf;
	EndDo;
	
	Return SetupStatus;
	
EndFunction

#EndRegion

#Region Private

Procedure FillInAutoFillStateOfExtdimension(SettingsStateBar, DescriptionOfAccountingObject_)
	
	For ExtDimensionNumber = 1 To 3 Do
		
		If Not IsBlankString(DescriptionOfAccountingObject_.DataSource) Then
			SettingsStateBar["MethodOfFillingExtdimension" + ExtDimensionNumber] 
				= Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister;
		Else
			SettingsStateBar["MethodOfFillingExtdimension" + ExtDimensionNumber] 
				= Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromCorrespondence;
			Continue;
		EndIf;
		
		CurViewOfExtdimension =  SettingsStateBar["ExtDimensionType" + ExtDimensionNumber];
		If Not ValueIsFilled(CurViewOfExtdimension) Then
			Continue;
		EndIf;
		
		PathToExtdimensionData = DescriptionOfAccountingObject_.PathsToExtdimensionData[CurViewOfExtdimension];
		
		If PathToExtdimensionData <> Undefined Then
			SettingsStateBar["ExpressionOfExtdimensionFilling" + ExtDimensionNumber] = PathToExtdimensionData;
		Else
			TypeDescription = SettingsStateBar["ExtdimensionValueType" + ExtDimensionNumber]; // TypeDescription - 
			PossibleFields = FinancialAccountingByFinancialRegisterData.PossibleExtdimensionFields(TypeDescription, DescriptionOfAccountingObject_);
			If PossibleFields.Count() > 0 Then
				SettingsStateBar["ExpressionOfExtdimensionFilling" + ExtDimensionNumber] = PossibleFields[0].Value;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(SettingsStateBar["ExpressionOfExtdimensionFilling" + ExtDimensionNumber]) Then
			SettingsStateBar["ThereAreExtdimensionFillingIssues" + ExtDimensionNumber] = True;
			SettingsStateBar["ThereAreExtdimensionFillingIssues"] = True;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillStateOfManualExtdimensionFillSetting(SettingsStateBar, SettingsComposer)
	
	For ExtDimensionNumber = 1 To 3 Do
		
		MethodOfFillingExtdimension = SettingsStateBar["MethodOfFillingExtdimension" + ExtDimensionNumber];
		ExpressionOfExtdimensionFilling = SettingsStateBar["ExpressionOfExtdimensionFilling" + ExtDimensionNumber];
		SpecifiedValueIsExtdimension = SettingsStateBar["SpecifiedValueIsExtdimension" + ExtDimensionNumber];
		
		If MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister Then
			DataCompositionField = New DataCompositionField(ExpressionOfExtdimensionFilling);
			AvailableSelectionField = SettingsComposer.Settings.SelectionAvailableFields.FindField(DataCompositionField);
			If AvailableSelectionField = Undefined Then
				// The field on the path does not exist
				SettingsStateBar["ThereAreExtdimensionFillingIssues" + ExtDimensionNumber]  = True;
			EndIf;
		ElsIf MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue Then
			DescriptionOfExtdimensionTypes = SettingsStateBar["ExtdimensionValueType" + ExtDimensionNumber]; // TypeDescription - 
			If Not DescriptionOfExtdimensionTypes.ContainsType(TypeOf(SpecifiedValueIsExtdimension)) Then
				// The specified value does not correspond to the type of subconto.
				SettingsStateBar["ThereAreExtdimensionFillingIssues" + ExtDimensionNumber]  = True;
			EndIf;
		EndIf;
		
		If SettingsStateBar["ThereAreExtdimensionFillingIssues" + ExtDimensionNumber]  Then
			SettingsStateBar.ThereAreExtdimensionFillingIssues = True;
		EndIf;
		
	EndDo;

EndProcedure
	
#EndRegion

#EndIf
