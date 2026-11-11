#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the default values for register resources.
// The key names of the structure should strictly correspond to the resource names in the register.
// 
// Returns:
// 	Structure - the structure of register resource values.
Function DefaultValues() Export
	
	StructureOfValues = New Structure;
	
	StructureOfValues.Insert("VATPayer", GetFunctionalOption("UseVATAccounting"));
	StructureOfValues.Insert("SeparateAccountingOfGoodsByVATTaxation", False);
	StructureOfValues.Insert("SeparateFAAccountingByVATTaxation", False);
	StructureOfValues.Insert("SeparateAccountingOfItemizedProductionCostsForVATTaxation", False);
	StructureOfValues.Insert("FrequencyOfVATAllocation", Enums.Periodicity.Quarter);
	StructureOfValues.Insert("VATBase", Enums.KindsOfVATBase.CurrentQuarterRevenue);
	StructureOfValues.Insert("RuleOfPrepaymentFilterToRegisterTaxInvoices", Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay);
	StructureOfValues.Insert("AccountingPoliciesExist", False);
	StructureOfValues.Insert("FrequencyOfFormationOfVATDeductionsAndRecoveries", Enums.Periodicity.Month);
	StructureOfValues.Insert("AllocateVATToCapitalExpenditureInReceiptMonth", False);
	StructureOfValues.Insert("GenerateVATChargedWhenIncludingInCost", False);
	StructureOfValues.Insert("WriteOffVATByExpensesThatAreNotRecordedInTA", False);  
	
	VATAccountingLocalization.AddDescriptionOfVATAccountingSettingsForOrganization(StructureOfValues);
	
	Return StructureOfValues;
	
EndFunction

// Returns the request text based on the register data.
// 
// Returns:
// 	String - query text.
Function QueryTextCurrentTaxAccountingPolicySettings() Export
	QueryText = "
	|SELECT ALLOWED
	|	CASE WHEN Table.Period IS NULL THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS AccountingPoliciesExist,
	|	Table.Period AS Period,
	|	ParentOrganizations.BranchOffice AS Organization,
	|	CASE WHEN ISNULL(FinancialAccountingPolicy.InventoryValuationMethod, UNDEFINED) =
	|		VALUE(Enum.InventoryValuationMethods.MovingAverage) THEN
	|			TRUE
	|	ELSE
	|		ISNULL(Table.GenerateVATChargedWhenIncludingInCost, FALSE)
	|	END AS GenerateVATChargedWhenIncludingInCost
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN InformationRegister.VATAccountingSettings.SliceLast(&Period, Organization IN
	|			(SELECT
	|				ParentOrganizations.Organization
	|			FROM
	|				TTParentOrganizations AS ParentOrganizations)) AS Table
	|		ON ParentOrganizations.Organization = Table.Organization
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&Period, Organization IN
	|			(SELECT
	|				ParentOrganizations.Organization
	|			FROM
	|				TTParentOrganizations AS ParentOrganizations)) AS FinancialAccountingPolicy
	|		ON ParentOrganizations.Organization = FinancialAccountingPolicy.Organization
	|";
	
	VATAccountingLocalization.AddCurrentVATParametersToQueryText(QueryText);
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	SelectedFields = QuerySchema.QueryBatch[0].Operators[0].SelectedFields;
	SettingsDescription = DefaultValues(); 
	SettingsDescription.Delete("AccountingPoliciesExist");
	SettingsDescription.Delete("GenerateVATChargedWhenIncludingInCost");
	
	For Each Setting In SettingsDescription Do
		SelectedFields.Add(StrTemplate("Table.%1", Setting.Key));
	EndDo;
	QueryText = QuerySchema.GetQueryText();
	
	VATAccountingLocalization.AddCurrentVATParametersToQueryText(QueryText, True);
	
	Return QueryText
	
EndFunction

// Generates a text description of the set parameters.
// 
// Parameters:
// 	Organization - CatalogRef.Companies - link to the organization.
// 	ValidityDate - Date - period of validity of settings.
// 	CurrentSettings_ - Structure - the parameters of the accounting policies.
// 	All - Boolean - if True, it returns a description of all settings.
// Returns:
// 	String - Description of the current parameters in a string.
Function DescriptionOfActiveParameters(Organization, ValidityDate = Undefined, CurrentSettings_ = Undefined, All = False) Export
	
	SettingsDescriptionString = "";
	
	VATAccountingLocalization.AddDescriptionOfVATAccountingSettings(Organization, ValidityDate,SettingsDescriptionString);
	If ValueIsFilled(SettingsDescriptionString) Then
		Return SettingsDescriptionString;
	EndIf;
	
	If CurrentSettings_ = Undefined Then
		CurrentSettings_ = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"VATAccountingSettings",
			Organization,
			ValidityDate,
			False);
	EndIf;
	
	If Not ValueIsFilled(CurrentSettings_) Then
		SettingsDescriptionString = NStr("vi = 'Chưa xác định tham số.';
										|ru = 'Не заданы параметры.';
										|en = 'Parameters are not specified.'; fa = 'پارامترها مشخص نشده‌اند.';
										|it = 'I parametri non sono imposatti.';
										|pl = 'Nie są ustawione parametry.';
										|tr = 'Parametreler belirtilmedi.'");
		Return SettingsDescriptionString;
	EndIf;

	StringPattern_ = "%1: %2." + Chars.LF;
	StringPatternBoolean = "%1." + Chars.LF;
	ArrayOfParameterDescriptionStrings = New Array;  
	If CurrentSettings_.VATPayer Or All Then
		ArrayOfParameterDescriptionStrings.Add(
			StrTemplate(StringPatternBoolean,
				NStr("vi = 'Doanh nghiệp là người nộp thuế Thuế GTGT';
					|ru = 'Организация является плательщиком НДС';
					|en = 'Company is a VAT payer'; fa = 'شرکت پرداخت‌کننده مالیات بر ارزش افزوده است';
					|it = 'L''organizzazione è un pagatore IVA';
					|pl = 'Firma jest płatnikiem podatku VAT';
					|tr = 'İş yeri KDV mükellefidir'")));
		ArrayOfParameterDescriptionStrings.Add(
			StrTemplate(StringPattern_,
				NStr("vi = 'Quy tắc lọc khoản ứng trước';
					|ru = 'Правило отбора авансов';
					|en = 'Rule of advance filter'; fa = 'قاعده فیلتر پیش‌پرداخت';
					|it = 'Regola di selezione degli acconti';
					|pl = 'Zasada filtru zaliczek';
					|tr = 'Avans seçim kuralı'"),
				CurrentSettings_.RuleOfPrepaymentFilterToRegisterTaxInvoices));
		If CurrentSettings_.SeparateAccountingOfGoodsByVATTaxation Then
			ArrayOfParameterDescriptionStrings.Add(StrTemplate(StringPatternBoolean, NStr("vi = 'Sử dụng kế toán Thuế GTGT riêng biệt';
																							|ru = 'Используется раздельный учет НДС';
																							|en = 'Separate VAT accounting is used'; fa = 'Separate VAT accounting is used';
																							|it = 'Si usa contabilità separata IVA';
																							|pl = 'Jest stosowana ewidencja VAT';
																							|tr = 'Ayrı KDV muhasebesi kullanılıyor'")));
		EndIf;
	Else
		ArrayOfParameterDescriptionStrings.Add(StrTemplate(StringPatternBoolean, NStr("vi = 'Doanh nghiệp không phải là người nộp thuế Thuế GTGT';
																						|ru = 'Организация не является плательщиком НДС';
																						|en = 'Company is not a VAT payer'; fa = 'Company is not a VAT payer';
																						|it = 'L''azienda non è un contribuente IVA';
																						|pl = 'Firma nie jest płatnikiem podatku VAT';
																						|tr = 'İş yeri KDV mükellefi değildir'")));
	EndIf;
	
	VATAccountingLocalization.AddDescriptionOfCurrentVATAccountingSettings(ArrayOfParameterDescriptionStrings, CurrentSettings_, All);
	
	SettingsDescriptionString = StrConcat(ArrayOfParameterDescriptionStrings, Chars.CR);
	
	Return SettingsDescriptionString
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Parameters:
//  Organization - CatalogRef.Companies - The organization for which you are configuring
//  Date - Date - The period for which the configuration is performed
//  VATAccountingOptionOnActivityTypeChange - EnumRef.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne - VAT accounting option
//  
// Returns:
//  Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters(Organization, Date, VATAccountingOptionOnActivityTypeChange) Export
	
	UseAccountingOfOtherIncomeExpenses = GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	ItSNotBasic = GetFunctionalOption("NotBaseVersion");
	ParametersOfTaxSystem = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"TaxationSystemSettings", Organization, Date, True);
	
	ParametersArray = New Array;
	
	#Region ExpenseItemVATExempt
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Record";
	ChoiceParameters.AssetRef      = "ExpenseItemVATExempt";
	
	ChoiceParameters.AvailabilityByOperation = UseAccountingOfOtherIncomeExpenses;
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = True;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpenseDimensionVATExempt";
	
	ChoiceParameters.FormItems.AssetRef.Add("CostItemNotVAT");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpenseDimensionVATExempt");
	
	ParametersArray.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region ExpenceItemUTII

	If ParametersOfTaxSystem = Undefined Then
		CompanyIsAUTIIPayer = False;
	Else
		CompanyIsAUTIIPayer = ParametersOfTaxSystem.CompanyIsAUTIIPayer;
	EndIf;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Record";
	ChoiceParameters.AssetRef      = "ExpenceItemUTII";
	
	ChoiceParameters.AvailabilityByOperation = CompanyIsAUTIIPayer
											And UseAccountingOfOtherIncomeExpenses;
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = True;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "VATDebitingDimensionBySalesSubjectToUTIIActivityType";
	
	ChoiceParameters.FormItems.AssetRef.Add("UTIICostItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("VATDebitingDimensionBySalesSubjectToUTIIActivityType");
	
	ParametersArray.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region ExpenseItemVATWriteOff
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Record";
	ChoiceParameters.AssetRef      = "ExpenseItemVATWriteOff";
	
	ChoiceParameters.AvailabilityByOperation = UseAccountingOfOtherIncomeExpenses And ItSNotBasic;
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = True;
	 
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpenseDimensionVATWriteOff";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemVATWriteOff");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpenseDimensionVATWriteOff");
	
	ParametersArray.Add(ChoiceParameters);
	
	#EndRegion
	
	Return ParametersArray;
	
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

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "RecordForm" Then
		If GetFunctionalOption("LocalizationRFService") Then
			SelectedForm = "RFEntryForm";
			StandardProcessing = False; 
		Else
			SelectedForm = "RecordForm";
			StandardProcessing = False;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region Private

// The average value is used during the validity period of the VAT settings.
// 
// Parameters:
//  Organization - CatalogRef.Companies
//  RecordPeriod - Date
// 
// Returns:
//  Boolean - The average slip is used in the period of validity of the VAT accounting settings
Function AverageSlipIsUsedInPeriodOfValidityOfVATSettings(Organization, RecordPeriod) Export
	
	MediumSlipIsUsed = False;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ISNULL(MIN(VATAccountingSettings.Period), DATETIME(3999, 12, 31)) AS EndDate
		|INTO PeriodOfValidityOfVATAccountingSettingsIsTT
		|FROM
		|	InformationRegister.VATAccountingSettings AS VATAccountingSettings
		|WHERE
		|	VATAccountingSettings.Organization = &Organization
		|	AND VATAccountingSettings.Period > &RecordPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(MAX(FinancialAccountingPolicy.InventoryValuationMethod =
		|		VALUE(Enum.InventoryValuationMethods.MovingAverage)), FALSE) AS MediumSlipIsUsed
		|FROM
		|	InformationRegister.FinancialAccountingPolicy AS FinancialAccountingPolicy
		|		LEFT JOIN PeriodOfValidityOfVATAccountingSettingsIsTT AS ActionPeriod
		|		ON (TRUE)
		|WHERE
		|	FinancialAccountingPolicy.Organization = &Organization
		|	AND FinancialAccountingPolicy.Period BETWEEN &RecordPeriod AND ActionPeriod.EndDate";
	
	Query.SetParameter("RecordPeriod", RecordPeriod);
	Query.SetParameter("Organization", Organization);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		MediumSlipIsUsed = Selection.MediumSlipIsUsed;
	EndIf;
	
	Return MediumSlipIsUsed;
	
EndFunction

#EndRegion 

#EndIf