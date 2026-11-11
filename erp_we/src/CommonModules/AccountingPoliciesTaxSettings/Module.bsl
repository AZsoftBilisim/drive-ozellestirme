#Region Public

// Returns the current values of the organization's settings as of the date.
// 
// Parameters:
// 	RegisterName - String - name of the information register.
// 	Organization - CatalogRef.Companies - link to the organization.
// 	ValidityDate - Date - period of validity of settings.
// 	ReturnDefault - Boolean - indicates whether default values are filled 
// 		in if false is passed-returns Undefined when there are no entries in the register.
// 	ThrowException - Boolean - throw an exception if the parameters are not set.
// Returns:
// 	Structure, Undefined - register resource values. Undefined if there is no register or disabled by FO.
Function CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(RegisterName, Organization, Val ValidityDate = Undefined, ReturnDefault = True, ThrowException = False) Export
	If ValueIsFilled(ValidityDate) Then
		ValidityDate = BegOfMonth(ValidityDate);
	EndIf;
	AccountingPolicySettings = AccountingPoliciesTaxSettingsCached.CurrentTaxAccountingPolicySettings(RegisterName,
		Organization,
		ValidityDate,
		ReturnDefault,
		ThrowException);
		
	Return AccountingPolicySettings;
	
EndFunction

// Returns a table of current settings values for the list of organizations as of the date.
// 
// Parameters:
// 	RegisterName - String - name of the information register.
// 	Companies - Array of CatalogRef.Companies - array of links to the organization.
// 	ValidityDate - Date - period of validity of settings.
// 	ReturnDefault - Boolean - a sign of the filling of default values 
// 		if passed false - returns an empty table.
// Returns:
// 	ValueTable - table of current settings by case.
Function CurrentParametersOfTaxesAndAccountingPoliciesForOrganizations(RegisterName, Companies, ValidityDate = Undefined, ReturnDefault = True) Export
	
	If Not ValueIsFilled(ValidityDate) Then
		ValidityDate = BegOfMonth(CurrentSessionDate());
	EndIf;
	
	DefaultValues = InformationRegisters[RegisterName].DefaultValues();
	
	Query = New Query(InformationRegisters[RegisterName].QueryTextCurrentTaxAccountingPolicySettings());
	
	TempTablesManager = New TempTablesManager();
	AddParentOrganizationsToTemporaryTableManager(TempTablesManager, Companies);
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Period", ValidityDate);
	Query.SetParameter("Organization", Companies);
	QueryResultTable = Query.Execute().Unload();

	ArrayOfRowsToDelete_1 = New Array;
	For Each TableRow In QueryResultTable Do
		If TableRow.Period = Null Then
			If ReturnDefault Then
				FillPropertyValues(TableRow, DefaultValues);
				TableRow.Period = BegOfMonth(ValidityDate);
			Else
				ArrayOfRowsToDelete_1.Add(TableRow);
				Continue;
			EndIf;
		EndIf;
		ParametersList = AvailableSettingsForAccountingPolicies(TableRow.Organization, ValidityDate);
		If ParametersList.Find(RegisterName) = Undefined Then
			ArrayOfRowsToDelete_1.Add(TableRow);
		EndIf;
	EndDo;
	
	If ReturnDefault And QueryResultTable.Count() = 0 Then
		TableRow = QueryResultTable.Add();
		FillPropertyValues(TableRow, DefaultValues);
		TableRow.Period = BegOfMonth(ValidityDate);
	EndIf;
	
	For Each RowToDelete In ArrayOfRowsToDelete_1 Do
		QueryResultTable.Delete(RowToDelete);
	EndDo;
	Return QueryResultTable;
EndFunction

// Creates a temporary table with parent organizations.
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - Manager of temporary query tables.
// 	Companies - Array of CatalogRef.Companies - array of links to organizations.
Procedure AddParentOrganizationsToTemporaryTableManager(TempTablesManager, Companies = Undefined) Export
	TableName = "TTParentOrganizations";
	If TempTablesManager.Tables.Find(TableName) <> Undefined Then
		// The required temporary table has already been created.
		Return;
	EndIf;
	Query = New Query(QueryTextParentOrganizations());
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("ByAllCompanies", Companies = Undefined);
	Query.Execute();
EndProcedure

// Creates a temporary table with the current values of settings for the organization on the date.
// 
// Parameters:
// 	RegisterName - String - name of the information register.
// 	TempTablesManager - TempTablesManager - Manager of temporary query tables.
// 	ValidityDate - Date - period of validity of settings.
// 	TableName - String - name of the temporary table to create.
// 	Companies - CatalogRef.Companies, Array - a link to an organization, or an array of links. 
Procedure SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(RegisterName, TempTablesManager, ValidityDate, TableName, Companies = Undefined) Export
	If Not ValueIsFilled(TableName) Then
		TableName = "TT"+ RegisterName;
	EndIf;
	If TempTablesManager.Tables.Find(TableName) <> Undefined Then
		// The required temporary table has already been created.
		Return;
	EndIf;
	
	If Not ValueIsFilled(ValidityDate) Then
		ValidityDate = BegOfMonth(CurrentSessionDate());
	EndIf;
	
	QueryText = InformationRegisters[RegisterName].QueryTextCurrentTaxAccountingPolicySettings();
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	QuerySchema.QueryBatch[0].PlacementTable = TableName;
	QuerySchema.QueryBatch[0].Index.Add("Organization");
	NewPackage = QuerySchema.QueryBatch.Add(Type("QuerySchemaTableDropQuery"));
	NewPackage.TableName = "TTParentOrganizations";
	QueryText = QuerySchema.GetQueryText();
	
	Query = New Query(QueryText);
	AddParentOrganizationsToTemporaryTableManager(TempTablesManager, Companies);
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Period", ValidityDate);
	Query.Execute();
EndProcedure

// Forms the text of the query the temporary table of Theloneranger
// 
// Returns:
// 	String - query text.
Function QueryTextParentOrganizations() Export
	
	QueryText = "
	|SELECT ALLOWED
	|	CatCompanies.ParentCompany AS Organization,
	|	CatCompanies.Ref AS BranchOffice
	|INTO
	|	TTParentOrganizations
	|FROM
	|	Catalog.Companies AS CatCompanies
	|WHERE
	|	(&ByAllCompanies = TRUE
	|	AND CatCompanies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid))
	|	OR CatCompanies.Ref IN (&Companies)
	|INDEX BY
	|	Organization;
	|";
	Return QueryText;
	
EndFunction

// Gets the last active record and generates a register entry key for it
// that uniquely identifies it.
// 
// Parameters:
// 	RegisterName - String - name of the periodic register of information.
// 	DimensionValue - CatalogRef - reference to the dimension of the record.
// 	Period - Date - period of record.
// 	DimensionName - String - Name of the selection dimension
// 	
// Returns:
// 	Undefined, InformationRegisterRecordKey - the recording key.
Function KeyForRecordingCurrentAccountingPolicy(RegisterName, DimensionValue, Val Period = Undefined, DimensionName = "Organization") Export
	
	If Not ValueIsFilled(DimensionValue) Then
		Return Undefined;
	EndIf;
	
	Period = ?(Period = Undefined, BegOfMonth(CurrentSessionDate()), Period);
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	Table.Period AS Period
	|FROM
	|	&AccountingPolicy AS Table";
	
	SectionName_ = "InformationRegister.%RegisterName%.SliceLast(&Period," + DimensionName + " = &DimensionValue)";
	SectionName_ = StrReplace(SectionName_, "%RegisterName%", RegisterName);

	QueryText = StrReplace(QueryText, 
		"&AccountingPolicy",
		SectionName_);
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", Period);
	Query.SetParameter("DimensionValue", DimensionValue);
	Selection = Query.Execute().Select();
	KeyValues = New Structure("Period, " + DimensionName, Period, DimensionValue);
	If Selection.Next() Then
		KeyValues.Period = Selection.Period;
	EndIf;
	
	Return InformationRegisters[RegisterName].CreateRecordKey(KeyValues);

EndFunction

// Creates a new register entry key
// 
// Parameters:
// 	RegisterName - String - name of the periodic register of information.
// 	DimensionValue - CatalogRef - dimension of the record.
// 	Period - Date - period of record.
// 	DimensionName - String - name of the dimension to fill in
// 	
// Returns:
// 	Undefined, InformationRegisterRecordKey - the recording key.
Function NewAccountPolicyEntryKey(RegisterName, DimensionValue, Period = Undefined, DimensionName = "Organization") Export
	
	If Not ValueIsFilled(DimensionValue) Then
		Return Undefined;
	EndIf;
	
	Period = ?(Period = Undefined, BegOfMonth(CurrentSessionDate()), Period);
	KeyValues = New Structure("Period, " + DimensionName, Period, DimensionValue);
	
	Return InformationRegisters[RegisterName].CreateRecordKey(KeyValues);
	
EndFunction

// Generates a periodic register record Manager based on the passed parameters.
// 
// Parameters:
// 	RegisterName - String - name of the periodic register of information.
// 	RecordKey - InformationRegisterRecordKey - register entry key.
// 	DimensionName - String - name of the master dimension.
// 	FillingValues - FormDataStructure, Structure - values for filling in a new record.
// Returns:
// 	InformationRegisterRecordKey - information register record manager.
Function PeriodicRegisterRecordManager(RegisterName, RecordKey, DimensionName = "Organization", FillingValues=Undefined) Export
	
	RecordManager = InformationRegisters[RegisterName].CreateRecordManager();
	RecordManager[DimensionName] = RecordKey[DimensionName];
	RecordManager.Period        = RecordKey.Period;
	RecordManager.Read();
	If Not RecordManager.Selected() Then
		DefaultValues = FillingValues;
		If DefaultValues=Undefined Or Not ValueIsFilled(DefaultValues.Period) Then
			DefaultValues = InformationRegisters[RegisterName].DefaultValues();
		EndIf;
		FillPropertyValues(RecordManager, DefaultValues);
		RecordManager[DimensionName] = RecordKey[DimensionName];
		RecordManager.Period        = RecordKey.Period;
	EndIf;
	
	Return RecordManager;

EndFunction

// Updates the information register form data for the record key.
// 
// Parameters:
// 	Form - ClientApplicationForm - Information Register Entry Form:
// 	* Record - InformationRegisterRecordManager - The main props of the form.
// 	RegisterName - String - name of the periodic register of information.
// 	Organization - CatalogRef.Companies - link to the organization.
// 	CreateANewOne - Boolean - forced to create a new record.
// 	RecordKey - InformationRegisterRecordKey - key for recording the data register.
// 	PeriodOfValues - Date - data acquisition period.
// 	AddAttributes - Structure - register details not available in the form data.
Procedure ReadRegisterEntry(Form, RegisterName, Organization, CreateANewOne, RecordKey = Undefined, PeriodOfValues = Undefined, AddAttributes = Undefined) Export
	
	If Not ValueIsFilled(Organization) 
		And ValueIsFilled(RecordKey) Then
		Organization = RecordKey.Organization;
	EndIf;
	
	If Not ValueIsFilled(Organization) Then
		Return
	EndIf;
	
	If CreateANewOne Then
		RecordKey = NewAccountPolicyEntryKey(RegisterName, Organization, PeriodOfValues);
	EndIf;
	
	If RecordKey = Undefined Then
		RecordKey = KeyForRecordingCurrentAccountingPolicy(RegisterName, Organization, PeriodOfValues);
	ElsIf TypeOf(RecordKey) = Type("Structure") Then
		RecordKey = NewAccountPolicyEntryKey(RegisterName, RecordKey.Organization, RecordKey.Period);
	EndIf;
	
	RecordManager = PeriodicRegisterRecordManager(RegisterName, RecordKey, , Form.Record);
	
	If AddAttributes <> Undefined Then
		FillPropertyValues(AddAttributes, RecordManager);
	EndIf;
	Form.ValueToFormAttribute(RecordManager, "Record");
	Form.ChangeDate = RecordManager.Period;
	Form.BranchOffice = Common.ObjectAttributeValue(Organization,"BranchOffice");
	UpdateHistoryDescription(Form, RegisterName, Organization, RecordManager.Period);
	
	Try
		UnlockDataForEdit(,  Form.UUID); // Unlock other keys blocked by this form
		LockDataForEdit(RecordKey, , Form.UUID);
	Except
		
		ErrorText = NStr("vi = 'Không thể phong tỏa bản ghi của biểu ghi theo doanh nghiệp %Organization% trong kỳ %Period%.
		|%ErrorDescription%';
		|ru = 'Не удалось заблокировать запись регистра по организации %Organization% за период %Period%.
		|%ErrorDescription%';
		|en = 'Failed to lock the register record by company %Organization% for the period %Period%.
		|%ErrorDescription%'; fa = 'Failed to lock the register record by company %Organization% for the period %Period%.
		|%ErrorDescription%';
		|it = 'Non è stato possibile bloccare la registrazione per azienda %Organization% per il periodo %Period%.
		|%ErrorDescription%';
		|pl = 'Nie udało się zablokować wpisu rejestru dot. firmy %Organization% za okres %Period%.
		|%ErrorDescription%';
		|tr = '%Period% dönemi için %Organization% iş yeri için kayıt girişi engellenemedi.
		|%ErrorDescription%'");
		ErrorText = StrReplace(ErrorText, "%Organization%", Organization);
		ErrorText = StrReplace(ErrorText, "%Period%", RecordManager.Period);
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
		Raise ErrorText;
		
	EndTry;
	
EndProcedure

// Updates the information register form data by copying the register entry values.
// 
// Parameters:
// 	Form - ClientApplicationForm:
// 		* Record - InformationRegisterRecordManagerInformationRegisterName
// 	Filter - Structure - Copy value of the information register entry.
// 	RegisterName - String - name of the periodic register of information.
//  DimensionName - String - name of the dimension to copy.
Procedure CopyAccountingPolicy(Form, Filter, RegisterName, DimensionName = "Organization") Export
	
	Value =  Filter[DimensionName];
	
	RecordManager = InformationRegisters[RegisterName].CreateRecordManager();
	RecordManager[DimensionName] = Value;
	RecordManager.Period        = Filter.Period;
	RecordManager.Read();
	
	FillPropertyValues(Form.Record, RecordManager);
	
	Form[DimensionName] = Value;
	Form.ChangeDate = RecordManager.Period;
	If TMCommonUseClientServer.HasObjectAttribute(Form, "BranchOffice") Then
		Form.BranchOffice = Common.ObjectAttributeValue(Value, "BranchOffice");
	EndIf;
	
EndProcedure

// Creates a hyperlink with a description of the story.
// 
// Parameters:
// 	Form - ManagedFormExtensionForInformationRegisterRecords - form of register entry, of information.
// 	RegisterName - String - name of the periodic register of information.
// 	DimensionValue - CatalogRef - dimension of the record.
// 	ComparisonPeriod - Date - date for comparison.
// 	DimensionName - String - Name of the selection dimension
Procedure UpdateHistoryDescription(Form, RegisterName, DimensionValue, ComparisonPeriod, DimensionName = "Organization") Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	Table.Period AS Period
	|FROM
	|	&RegisterName AS Table
	|WHERE
	|	&FilterCriterion
	|ORDER BY
	|	Table.Period ASC
	|";
	
	Query.Text = StrReplace(Query.Text, "&RegisterName", "InformationRegister." + RegisterName);
	Query.Text = StrReplace(Query.Text, "&FilterCriterion", "Table." + DimensionName  + " = &DimensionValue");
	Query.SetParameter("DimensionValue", DimensionValue);
	ArrayOfPeriods = Query.Execute().Unload().UnloadColumn("Period");
	
	DateOfNextEntry = Undefined;
	For Each RecordPeriod In ArrayOfPeriods Do
		If RecordPeriod > ComparisonPeriod Then
			DateOfNextEntry = BegOfDay(RecordPeriod) - 1;
			Break;
		EndIf;
	EndDo;
	
	If ValueIsFilled(DateOfNextEntry) Then
		TextDescriptionOfStory = NStr("vi = 'hợp lệ cho';
										|ru = 'действует по';
										|en = 'Valid until'; fa = 'معتبر تا';
										|it = 'in vigore fino a';
										|pl = 'Obowiązuje do';
										|tr = 'kadar geçerlidir'") + " " + Format(DateOfNextEntry, "DLF=DD");
	Else
		TextDescriptionOfStory = NStr("vi = 'có hiệu lực đến hết thời gian này.';
										|ru = 'действует по настоящее время.';
										|en = 'valid as of today.'; fa = 'valid as of today.';
										|it = 'valido fino ad oggi.';
										|pl = 'ważne do chwili obecnej.';
										|tr = 'hala geçerli.'");
	EndIf;
	HistoryDescription = New FormattedString(TextDescriptionOfStory);
	
	If ArrayOfPeriods.Count() > 0 Then
		HyperlinkText_ = NStr("vi = 'Lịch sử thay đổi';
								|ru = 'История изменений';
								|en = 'Change history'; fa = 'سابقه تغییرات';
								|it = 'Cronologia delle modifiche';
								|pl = 'Historia zmian';
								|tr = 'Değişiklik geçmişi'") + " (" + ArrayOfPeriods.Count() + ")";
		HyperlinkHistory = New FormattedString(HyperlinkText_, , StyleColors.HyperlinkColor, , "ChangeHistory");
		HistoryDescription = New FormattedString(HistoryDescription, " ", HyperlinkHistory);
	EndIf;
	
	FillingValues = New Structure("HistoryDescription, DateOfNextEntry", HistoryDescription, DateOfNextEntry);
	FillPropertyValues(Form, FillingValues);
	
EndProcedure

// Called when writing data from the data register entry form.
// 
// Parameters:
// 	Form - ManagedFormExtensionForInformationRegisterRecords - form of register entry, of information.
// 	Close - Boolean - indicates whether the form is closed after recording.
// 	AddAttributes - Structure - register details not available in the form data.
// Returns:
// 	Boolean - sign of successful recording
Function RecordChangingRegisterEntries(Form, Close = False, AddAttributes = Undefined) Export
		
	Cancel = Not Form.CheckFilling();
	If Cancel Then
		Return Not Cancel;
	EndIf;
	
	RecordManager = Form.FormAttributeToValue("Record");
	RecordManager.Period = Form.ChangeDate;
	If AddAttributes <> Undefined Then
		FillPropertyValues(RecordManager, AddAttributes);
	EndIf;
	RecordManager.Write(Not Form.ThisIsARecordForm);
	Form.Modified = False;
	
	If Not Close Then
		ReadRegisterEntry(Form, Form.RegisterName, Form.Organization, False, Undefined, RecordManager.Period, AddAttributes);
	EndIf;
	RefreshReusableValues();
	Return True 
	
EndFunction

// Fills in the description of the current accounting policy parameters on the form.
// 
// Parameters:
// 	Form - See Catalog.Companies.Form.ItemForm.
// 	Organization - CatalogRef.Companies - link to the Business directory.
// 	RegisterName - String - name of the periodic register of information.
// 	ValidityDate - Date - data acquisition period.
Procedure FillInDescriptionOfCurrentParameters(Form, Organization, RegisterName = "", Val ValidityDate = "") Export
	If Not ValueIsFilled(ValidityDate) Then
		ValidityDate = BegOfMonth(CurrentSessionDate());
	Else 
		ValidityDate = BegOfMonth(ValidityDate);
	EndIf;
	Items = Form.Items;
	
	MatchingElements = Catalogs.Companies.ComplianceOfFormElementsWithTaxAccountingPolicyParameters();
	If ValueIsFilled(RegisterName) Then
		TagName = MatchingElements.Get(RegisterName).DescriptionElement;
		ElementDescriptionOfAccountingPolicy = Items[TagName];
		ElementDescriptionOfAccountingPolicy.Title = InformationRegisters[RegisterName].DescriptionOfActiveParameters(Organization,
			ValidityDate);
		Return;
	EndIf;

	ParametersArray = AvailableSettingsForAccountingPolicies(Organization, ValidityDate);
	ArrayOfRequestTexts = New Array;
	
	For Each RegisterName In ParametersArray Do
		ArrayOfRequestTexts.Add(InformationRegisters[RegisterName].QueryTextCurrentTaxAccountingPolicySettings());
	EndDo;
	QueryText = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	TempTablesManager = New TempTablesManager();
	AddParentOrganizationsToTemporaryTableManager(TempTablesManager, Organization);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Period", ValidityDate);
	ResultsArray = Query.ExecuteBatch();
	
	For CurrentIndex = 0 To ParametersArray.Count()-1 Do
		Selection = ResultsArray[CurrentIndex].Select();
		If Selection.Next() Then
			RegisterName = ParametersArray[CurrentIndex];
			RegisterData = Selection;
			If Selection.Period = Null Then
				RegisterData = Undefined;
			EndIf;
			RegisterElements = MatchingElements.Get(RegisterName);
			If RegisterElements <> Undefined Then
				TagName = MatchingElements.Get(RegisterName).DescriptionElement;
				ElementDescriptionOfAccountingPolicy = Items[TagName];
				ElementDescriptionOfAccountingPolicy.Title = InformationRegisters[RegisterName].DescriptionOfActiveParameters(
					Organization,
					ValidityDate,
					RegisterData);
			EndIf;
		EndIf;
	EndDo;

EndProcedure

// Controls the visibility of form elements related to accounting policies and taxes.
// 
// Parameters:
// 	Form - ClientApplicationForm - form with elements of accounting policies.
// 	MatchingFormElements - Map of KeyAndValue- matching the array of form elements and the name of the accounting policy register.
// 	Organization - CatalogRef.Companies - link to the Business directory.
// 	ValidityDate - Date - data acquisition period.
Procedure ManagingVisibilityOfAccountingPolicyElements(Form, MatchingFormElements, Organization, ValidityDate = Undefined) Export
	
	ParametersList = AvailableSettingsForAccountingPolicies(Organization, ValidityDate);
	For Each MapItem In MatchingFormElements Do
		ParameterEnabled = ParametersList.Find(MapItem.Key) <> Undefined;
		TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items, 
			MapItem.Value.ItemArray,
			"Visible",
			ParameterEnabled);
	EndDo;
	
EndProcedure

#Region FunctionsForObtainingIndividualAccountingPolicyDetails

// Returns an array of organizations that have the specified accounting policy parameter set.
//
// Parameters:
//	RegisterName  - String - name of the periodic register of information.
//	ParameterName 	  - String - the name of the accounting policy parameter, see the result of the Accounting Policy Parameter function()
//	ParameterValue - Arbitrary - value of the specified accounting policy parameter
//	Companies 	  - Array of CatalogRef.Companies, CatalogRef.Companies, Undefined - personnel to verify that accounting policies
//	Period 			  - Date - the date on which it is necessary to check the accounting policy
//
// Returns:
//	Array of CatalogRef.Companies - a subset of the Organization parameter, with the accounting policy parameter set.
//
Function OrganizationsWithSpecifiedPolicyParameter(RegisterName, ParameterName, ParameterValue,
			Companies = Undefined, Period = Undefined) Export
	
	Result = New Array;
	
	AccountingPolicies = CurrentParametersOfTaxesAndAccountingPoliciesForOrganizations(RegisterName, Companies, Period);
	
	For Each AccountingPolicyParameters In AccountingPolicies Do
		
		If AccountingPolicyParameters[ParameterName] = ParameterValue Then
			Result.Add(AccountingPolicyParameters.Organization);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction
	
// Function-aggregator of information about tax accounting settings for a specific date
//
// Parameters:
//  Period       - Date - date when the settings were read.
//  Organization  - CatalogRef.Companies - the organization that you want to get settings for.
// 
// Returns:
//  Undefined, ValueTable - if there is not a single record of the accounting settings is undefined,
//                                  otherwise the table.
Function AccountingPolicyTaxAccounting(Period, Organization) Export
	Return AccountingPoliciesTaxSettingsLocalization.AccountingPolicyTaxAccounting(Period, Organization);
EndFunction

// Returns the order of accounting for non-current assets.
// 
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which the order is defined.
//	Period - Date - the date on which the order is determined.
//
// Returns:
//	EnumRef.AccountingPolicyForFixedAssets -  Accounting procedure for non-current assets.
//
Function AccountingPolicyForFixedAssets(Organization, Period) Export
	
	Query = New Query(
		"SELECT
		|	T.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets
		|FROM
		|	InformationRegister.FinancialAccountingPolicy.SliceLast(
		|		&Period, 
		|		Organization = CAST(&Organization AS Catalog.Companies).ParentCompany) AS T");
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Period", New Boundary(Period, BoundaryType.Including));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.AccountingPolicyForFixedAssets;
	EndIf;
	
	Return Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function CurrentTaxAccountingPolicySettings(RegisterName, Organization, Val ValidityDate = Undefined, ReturnDefault = True, ThrowException = False) Export
	If ValidityDate = Undefined Then
		ValidityDate = BegOfMonth(CurrentSessionDate());
	EndIf;
	QueryResultTable = CurrentParametersOfTaxesAndAccountingPoliciesForOrganizations(RegisterName, Organization, ValidityDate, ReturnDefault);
	If QueryResultTable.Count() = 1 Then
		ActiveParameters = New Structure;
		For Each Column In QueryResultTable.Columns Do
			ActiveParameters.Insert(Column.Name);
		EndDo;
		FillPropertyValues(ActiveParameters, QueryResultTable[0]);
		Return ActiveParameters;
	ElsIf ThrowException Then
		RegisterName_ = Metadata.InformationRegisters[RegisterName].Synonym;
		PatternException = NStr("vi = 'Các tham số ""%1"" không được đặt cho doanh nghiệp ""%2"" vào ngày %3.';
								|ru = 'Не заданы параметры ""%1"" для организации ""%2"" на дату %3.';
								|en = 'Parameters ""%1"" for the company ""%2"" are not set on the date %3.'; fa = 'Parameters ""%1"" for the company ""%2"" are not set on the date %3.';
								|it = 'Parametri non impostati""%1"" per le aziende ""%2"" alla data %3.';
								|pl = 'Nie zostały określone parametry ""%1"" dla firmy ""%2"" na datę %3.';
								|tr = '""%1"" parametreleri, %3 tarihinde ""%2"" iş yeri için ayarlanmadı.'");
		Raise StrTemplate(PatternException, RegisterName_, Organization, Format(ValidityDate, "DLF=DD;"));
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function AvailableSettingsForAccountingPolicies(Companies, ValidityDate = Undefined) Export
	
	ParametersList = New Array();
	ParametersList.Add("FinancialAccountingPolicy");
	If GetFunctionalOption("UseVATAccounting") Then
		ParametersList.Add("VATAccountingSettings");
	EndIf;
	AccountingPoliciesTaxSettingsLocalization.AddAvailableParametersForAccountingPolicies(ParametersList,
		Companies,
		ValidityDate);
	Return ParametersList;
	
EndFunction

Procedure CollectStatisticsOnAccountPolicySettings() Export
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then 
		ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
	Else
		Return
	EndIf;
	QueriesTexts = New Array();
	TextsOfRequestsForObtainingAccountingPolicyStatistics(QueriesTexts);
	
	QueriesText = StrConcat(QueriesTexts, " UNION ALL ");
	Query = New Query(QueriesText);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Selection.SettingBooleanType Then
			IndicatorName = StrTemplate("InformationRegisters.%1.%2", Selection.RegisterName, Selection.IndicatorName);
		Else
			ResourceValue = XMLString(Selection.IndicatorValue);
			IndicatorName = StrTemplate("InformationRegisters.%1.%2.%3", Selection.RegisterName, Selection.IndicatorName, ResourceValue);
		EndIf;
		
		ModuleMonitoringCenter.WriteConfigurationObjectStatistics(IndicatorName, Selection.Count);
	EndDo;
	
EndProcedure

Procedure AddRequestTextsForStatisticsIndicators(RegisterName, StatisticalIndicators, QueriesTexts) Export
	
	ArrayOfIndicators = StringFunctionsClientServer.SplitStringIntoSubstringsArray(StatisticalIndicators,,,True);
	
	For Each IndicatorName In ArrayOfIndicators Do
		QueryTextTemplate2 = "
		|
		|SELECT
		|	""#RegisterName""                         AS RegisterName,
		|	""#IndicatorName""                       AS IndicatorName,
		|	&RegisterField                            AS IndicatorValue,
		|	CASE
		|		WHEN VALUETYPE(&RegisterField) = TYPE(BOOLEAN)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                    AS SettingBooleanType,
		|	SUM(1)                                 AS Count
		|FROM
		|	&RegisterData AS RegisterData
		|WHERE
		|	(VALUETYPE(&RegisterField) = TYPE(BOOLEAN)
		|				AND &RegisterField = TRUE
		|			OR VALUETYPE(&RegisterField) <> TYPE(BOOLEAN))
		|
		|GROUP BY
		|	RegisterData.RegisterField
		|
		|";
		
		QueryText = StrReplace(QueryTextTemplate2,	"#RegisterName", RegisterName);
		QueryText = StrReplace(QueryText,		"#IndicatorName", IndicatorName);
		QueryText = StrReplace(QueryText,		"&RegisterData", StrTemplate("InformationRegister.%1.SliceLast", RegisterName));
		QueryText = StrReplace(QueryText,		"&RegisterField", StrTemplate("RegisterData.%1", IndicatorName));
		QueriesTexts.Add(QueryText);
	EndDo;
	
EndProcedure

// Processes the "Organization" parameter
// in the case of an array:
//   * no empty values
//   * unique values only
//   * the list of values leads to an array
//   * if there is only one element in the array, it returns a link to the organization
//   * if the result is an empty array, it returns Undefined.
// 
// Parameters:
// 	OrganizationOfExh - Array of CatalogRef.Companies, CatalogRef.Companies, Undefined - outgoing organization
//  
// Returns:
// 	Array of CatalogRef.Companies, CatalogRef.Companies, Undefined - processed "Organization" parameter
Function ProcessedOrganizationParameter(Val OrganizationOfExh) Export
	
	OBROrganization = Undefined;
	
	If TypeOf(OrganizationOfExh) = Type("ValueList") Then
		OrganizationOfExh = OrganizationOfExh.UnloadValues();
	EndIf;
	
	If TypeOf(OrganizationOfExh) = Type("CatalogRef.Companies")
		And ValueIsFilled(OrganizationOfExh) Then
		OBROrganization = OrganizationOfExh;
	EndIf;
	
	If TypeOf(OrganizationOfExh) = Type("Array") Then
		Nmbr = OrganizationOfExh.Count();
		If Nmbr = 1 Then
			OBROrganization = OrganizationOfExh.Get(0); // CatalogRef.Companies
		ElsIf Nmbr > 1 Then
			// we point the "Organization" link passed by value to the new array
			UniqueOrganizations = New Map;
			OBROrganization      = New Array;
			For Each It_ In OrganizationOfExh Do
				If ValueIsFilled(It_) And UniqueOrganizations.Get(It_) = Undefined Then
					UniqueOrganizations.Insert(It_, True);
					OBROrganization.Add(It_);
				EndIf;
			EndDo;
			If Not ValueIsFilled(OBROrganization) Then
				OBROrganization = Undefined;
			EndIf;
		EndIf;
	EndIf;
	
	Return OBROrganization;
	
EndFunction

// Fills in the global search result.
// 
// Parameters:
//  SearchString                - String - search bar. 
//  GlobalSearchResults - GlobalSearchResult - contains search results.
//  AdditionalParameters     - Structure - advanced setting.
//
Procedure FillInResultOfGlobalSearchForAccountingPolicies(SearchString, GlobalSearchResults, AdditionalParameters) Export

	SearchResults = ResultsOfGlobalSearchForAccountingPolicies(SearchString);

	If SearchResults = Undefined Then
		Return;
	EndIf;

	For Each SearchResult In SearchResults Do
		GlobalSearchResults.Add(SearchResult.Value, SearchResult.Presentation, SearchResult.Picture,
			"SearchForAccountingPolicies", SearchResult.ActionDetails);
	EndDo;

EndProcedure

#EndRegion

#Region Private

Procedure TextsOfRequestsForObtainingAccountingPolicyStatistics(QueriesTexts)
	
	//Register of Accounting policy of Financial accounting
	StatisticalIndicators = "InventoryValuationMethod,
							|ProductCostingByPlannedCost";
	StatisticalIndicators = StatisticalIndicators + "|ToGenerateLossAllowance,							
													|FrequencyOfLossAllowance";
	AddRequestTextsForStatisticsIndicators("FinancialAccountingPolicy", StatisticalIndicators, QueriesTexts);
	
	AccountingPoliciesTaxSettingsLocalization.TextsOfRequestsForObtainingAccountingPolicyStatistics(QueriesTexts)
	
EndProcedure

Function ResultsOfGlobalSearchForAccountingPolicies(SearchString)
	SearchResults = New Array;
	NoteText = StyleColors.NoteText;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Companies.Ref AS Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|	AND NOT Companies.BranchOffice";
	
	CompanyArray = Query.Execute().Unload().UnloadColumn("Ref");
	AvailableParameters = GloballySearchableRegisters(CompanyArray, SearchString);
	If CompanyArray.Count() = 0 Or AvailableParameters.Count() = 0 Then
		Return SearchResults;
	EndIf;
	
	For Each RegisterName In AvailableParameters Do
		//@skip-check query-in-loop
		CurrentOrganizationParameters = CurrentParametersOfTaxesAndAccountingPoliciesForOrganizations(RegisterName, CompanyArray,,False);
		Synonym = Metadata.InformationRegisters[RegisterName].Synonym;
		For Each ActiveParameters In CurrentOrganizationParameters Do
			Organization = ActiveParameters.Organization;
			LongDesc = InformationRegisters[RegisterName].DescriptionOfActiveParameters(Organization,,ActiveParameters);
			LongDesc = New FormattedString(LongDesc, , NoteText);
			FoundRow = StrFindAndHighlightByAppearance(LongDesc, SearchString);
			If FoundRow <> Undefined Then
				RecordKey = AccountingPoliciesTaxSettings.KeyForRecordingCurrentAccountingPolicy(RegisterName, Organization);
				SearchResult = SystemSettingsClientServer.NewGlobalSearchResult();
				SearchResult.Value = GetURL(RecordKey);
				
				RowsArray = New Array;
				RowsArray.Add(Synonym + " " + Organization);
				RowsArray.Add(Chars.LF);
				RowsArray.Add(FoundRow);
				
				SearchResult.Presentation = New FormattedString(RowsArray);
				SearchResult.Picture = PictureLib.Setting;
				SearchResult.ActionDetails = "";
				
				SearchResults.Add(SearchResult);
			EndIf;
		EndDo;
		
		If AccessRight("Update", Metadata.InformationRegisters[RegisterName]) Then
			SearchResult = SystemSettingsClientServer.NewGlobalSearchResult();
			
			KeyValues = New Structure("Organization, Period");
			SearchResult.Value = GetURL(InformationRegisters[RegisterName].CreateRecordKey(KeyValues));
			
			DefaultValues = InformationRegisters[RegisterName].DefaultValues();
			DescriptionOfActiveParameters = InformationRegisters[RegisterName].DescriptionOfActiveParameters(Undefined,,DefaultValues, True);
			LongDesc = New FormattedString(DescriptionOfActiveParameters, , NoteText);
			FoundRow = StrFindAndHighlightByAppearance(LongDesc, SearchString);
			
			RowsArray = New Array;
			TemplateCreate = NStr("vi = 'Tạo mới ""%1""';
									|ru = 'Создать ""%1""';
									|en = 'Create ""%1""'; fa = 'Create ""%1""';
									|it = 'Create ""%1""';
									|pl = 'Create ""%1""';
									|tr = '""%1"" oluştur'");
			TemplateCreate = StringFunctionsClientServer.SubstituteParametersToString(TemplateCreate, Synonym);
			RowsArray.Add(TemplateCreate);
			RowsArray.Add(Chars.LF);
			RowsArray.Add(FoundRow);
			
			SearchResult.Presentation = New FormattedString(RowsArray);
			SearchResult.Picture = PictureLib.CreateListItem;
			SearchResult.ActionDetails = "";
			
			SearchResults.Add(SearchResult);
		EndIf;
	EndDo;
	
	Return SearchResults;
	
EndFunction

Function GloballySearchableRegisters(CompanyArray, SearchString)
	
	AvailableParameters = AvailableSettingsForAccountingPolicies(CompanyArray);
	
	IndexOf = AvailableParameters.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		If Not AccessRight("View", Metadata.InformationRegisters[AvailableParameters[IndexOf]]) Then
			AvailableParameters.Delete(IndexOf);
			Continue;
		EndIf;
		
		Register_Manager = InformationRegisters[AvailableParameters[IndexOf]];
		DefaultValues = Register_Manager.DefaultValues();
		DescriptionOfActiveParameters = Register_Manager.DescriptionOfActiveParameters(Undefined,,DefaultValues, True);
		If StrFindAndHighlightByAppearance(DescriptionOfActiveParameters, SearchString) = Undefined Then
			AvailableParameters.Delete(IndexOf);
		EndIf;
	EndDo;
	
	Return AvailableParameters;
EndFunction

#EndRegion
