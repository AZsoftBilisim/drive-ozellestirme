
#Region Internal

// Gets the value of the presentation of international accounting accounts on the transmitted chart of accounts
//
// Parameters:
//  ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Chart of accounts.
//
// Returns:
//  EnumRef.PresentationOfFinancialAccountingAccounts - Presentation Of International Accounting Accounts
//
Function PresentationOfInvoicesOnChartOfAccounts(ChartOfAccounts) Export
	
	Return Common.ObjectAttributeValue(ChartOfAccounts, "AccountsPresentation");
	
EndFunction

// Gets the properties of an international accounting account
//
// Parameters:
//  Account - ChartOfAccountsRef.International - International chart of accounts account.
//
// Returns:
//  Structure - account properties
//				The key is the name of the account property.
//				Value - the value of the property.
//
Function AccountProperties(Account) Export
	
	Return FinancialAccountingServerCached.AccountProperties(Account);
	
EndFunction

// Called from the international Accountclient module for the"reconciliation of turnover" report.
// 
// Parameters:
//  Address - String - Address
//  IndexOfCurElement - Number - Index of the current element
// 
// Returns:
//  ChartOfAccountsRef - To obtain the row count verification
//
Function GetReconciliationLineInvoice(Address,IndexOfCurElement) Export
	
	ReconciliationLineCount = Undefined;
	DetailsData = GetFromTempStorage(Address);
	AccountInt = GetValueOfDecryptionField(DetailsData, "AccountInt", IndexOfCurElement, "SumOfConAC");
	ACScore = GetValueOfDecryptionField(DetailsData, "ACScore", IndexOfCurElement, "SumOfConAC");
	
	If ValueIsFilled(AccountInt) Then
		ReconciliationLineCount = AccountInt;
	ElsIf ValueIsFilled(ACScore) Then
		ReconciliationLineCount = ACScore;
	EndIf;
	
	Return ReconciliationLineCount;
	
EndFunction

// Called from the international Accountclient module for the"reconciliation of turnover" report.
//
// Parameters:
// 	Address - String - 
// 	Parameters - Structure of KeyAndValue - Selection parameters:
// 		* Account - ChartOfAccountsRef - 
// 		* Period - StandardPeriod - 
Procedure FillInDataOfDecryptionOfAnalysisOfAccountSelfSupporting(Address, Parameters) Export
	
	DetailsData = New Structure("DecryptionSettings");
	DetailsData.Insert("DecryptionSettings", New Structure("AccountAnalysis"));
	
	UserSettings = New DataCompositionUserSettings;
	
	ReportSettings = UserSettings.AdditionalProperties;
	ReportSettings.Insert("IndicatorAccounting", True);
	ReportSettings.Insert("DetailsMode", True);
	For Each Parameter In Parameters Do
		If Parameter.Key = "Period" Then
			Period = Parameter.Value; // StandardPeriod - 
			ReportSettings.Insert("BeginOfPeriod", Period.StartDate);
			ReportSettings.Insert("EndOfPeriod", Period.EndDate);
		Else
			ReportSettings.Insert(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	DetailsData.DecryptionSettings.AccountAnalysis = UserSettings;
	
	PutToTempStorage(DetailsData, Address);
	
EndProcedure

// Returns parameters for decrypting standard reports
// Parameters:
// 	DetailsData - DataCompositionDetailsData - Report form
// 	DetailsID - DataCompositionDetailsID - Decryption ID
// 	ReportName - String - Report name
// 	CurrentVariantKey - String - The key of the current option
// 
// Returns:
// 	Structure - Report decryption parameters:
// 		Decryption Form Parameters - Structure - Decryption Form Parameters
// 		Possible decryption - List of values - A list of possible options for decrypting the report.
//
Function StandardReportDecryptionParameters(DetailsData, DetailsID, ReportName, CurrentVariantKey) Export

	ExplanationFormParameters = GetTranscriptOfReport(DetailsData, DetailsID); 
	
	AccountValues = New Structure("Account,AccountDr,AccountCr", "", "", "");
	AccountParties = New Array;
	AccountParties.Add("");
	AccountParties.Add("Dr");
	AccountParties.Add("Cr");
	
	For Each AccountSide In AccountParties Do 	
		If ExplanationFormParameters.Fields.Property("Account"+AccountSide) Then	
			AccountValues["Account"+AccountSide] = ExplanationFormParameters.Fields["Account"+AccountSide];
		ElsIf ExplanationFormParameters.Filters.Property("Account"+AccountSide) Then
			AccountValues["Account"+AccountSide] = ExplanationFormParameters.Filters["Account"+AccountSide].RightValue; 
		EndIf;		
	EndDo;
	
	If Not ValueIsFilled(AccountValues.Account) And ValueIsFilled(AccountValues.AccountDr) Then
		AccountValues.Account = AccountValues.AccountDr;
	EndIf;
	
	If ExplanationFormParameters.Fields.Property("ChartOfAccounts") Then
		ChartOfAccounts = ExplanationFormParameters.Fields.ChartOfAccounts;
	Else
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	PossibleDecryptions = PossibleDecryptions(ReportName, CurrentVariantKey, ChartOfAccounts, AccountValues);
	
	Result = New Structure();
	Result.Insert("ExplanationFormParameters", ExplanationFormParameters);
	Result.Insert("PossibleDecryptions", PossibleDecryptions);
	
	Return Result;
	
EndFunction

// Called from the international accounting Client module for the report " usingaccountsubcontentinternational Accounting"
// Returns the structure of decryption parameters.
//
// Returns:
//  Structure - decryption data:
//  * ReportKind - CatalogRef.FinancialReportTypes
//  * ReportItem - CatalogRef.FinancialReportItems
//  * ItSArbitrary - Boolean 
//
Function SettingsDecryptionParameters(Details, DetailsDataAddress) Export
	
	DetailsData = GetFromTempStorage(DetailsDataAddress); // DataCompositionDetailsData - 
	
	GroupFields = New Structure;
	ReportsTMServerCallOverridable.GetFieldValues(GroupFields, DetailsData.Items, Details);
	
	CurrentField = New Structure;
	ReportsTMServerCallOverridable.GetFieldValue(CurrentField, DetailsData.Items[Details]);
	
	DetailsParameters = New Structure("ReportKind,ReportItem,ThisIsDerivative");
	DetailsParameters.ThisIsDerivative = False;

	If GroupFields.Property("ReportKind") Then
		DetailsParameters.ReportKind = GroupFields.ReportKind;
	EndIf;
	
	If CurrentField.Property("DerivedItem") Then
		DetailsParameters.ThisIsDerivative = True;
		DetailsParameters.ReportItem = CurrentField.DerivedItem;
	EndIf;
	
	If CurrentField.Property("ReportItem") Then
		DetailsParameters.ReportItem = CurrentField.ReportItem;
	EndIf;
	
	Return DetailsParameters;
	
EndFunction

// Returns the parent predefined version of the report to configure decryption
//
// Parameters:
//  VariantKey - String - the key of the original version of the report
//  ReportName - String - Report name
//
// Returns:
//  String - Key Of The Parent Predefined Version Of The Report
//
Function KeyOfParentPredefinedVersionOfReport(VariantKey, ReportName) Export
	
	ReportVariant = ReportsOptions.ReportVariant(Common.MetadataObjectID("Report."
		+ ReportName), VariantKey);
	While True Do
		OptionAttributes = Common.ObjectAttributesValues(ReportVariant,
			"PredefinedOption, VariantKey, Parent");
		VariantKey = OptionAttributes.VariantKey;
		If ValueIsFilled(OptionAttributes.PredefinedOption) Then
			Break;
		ElsIf Not ValueIsFilled(OptionAttributes.Parent) Then
			Break;
		Else
			ReportVariant = OptionAttributes.Parent;
		EndIf;
	EndDo;
	
	Return VariantKey;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	DetailsData - DataCompositionDetailsData - LongDesc
// 	FieldName - String - LongDesc
// 	InitialIndex - Number - 
// 	LastColumn - String - LongDesc
// Returns:
// 	Arbitrary, Undefined - LongDesc
Function GetValueOfDecryptionField(DetailsData, FieldName, Val InitialIndex, LastColumn = "") Export
	
	IndexOf = Number(InitialIndex);
	Result = Undefined;
	While IndexOf >= 0 Do
		
		DetailsItem = DetailsData.Items[IndexOf];
		If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
			Fields = DetailsItem.GetFields();
			Simple = Fields.Find(FieldName);
			If Simple <> Undefined Then
				Result = Simple.Value;
				Break;
			EndIf;
			
			// end of line
			If Not IsBlankString(LastColumn) Then
				Simple = Fields.Find(LastColumn);
				If Simple <> Undefined Then
					Break;
				EndIf;
			EndIf;
		EndIf;
		IndexOf = IndexOf - 1;
		
	EndDo;
	Return Result;
	
EndFunction

// This function transfers the settings of the calling report to the settings of the decryption report
//
// Parameters:
//  Parameters - Structure - containing keys
//              ReportName-String - name of the decryption report metadata
//              Variant key-String - name of the decryption report variant
//              Linker of customizations-linker of customizedcomposed Data - configured linker of the calling report
//              Parametrised - Structure - Key - name parameter; Value - the parameter value
//              Selection-Structure-Key-field Name; Value-element of the data collection Or structure with the same fields
//              Decryption fields-Structure-Key-field Name; Value - Current value of the selected decryption field.
//
// Returns:
//   DataCompositionSettingsComposer - configured decryption report linker.
//
Function ConfigureDecryptionReport(Val Parameters) Export
	
	// Calling Report Settings
	ReportSettings = Parameters.SettingsComposer.GetSettings();
	CustomReportSettings = Parameters.SettingsComposer.UserSettings; // DataCompositionUserSettings - 
	
	// Settings for the decryption report
	DecryptionSettingsComposer = New DataCompositionSettingsComposer;
	MetadataOfReport = Metadata.Reports[Parameters.ReportName]; // MetadataObjectReport - 
	SchemaName = MetadataOfReport.MainDataCompositionSchema.Name;
	DecryptionScheme = Reports[Parameters.ReportName].GetTemplate(SchemaName);
	
	VariantKey = KeyOfParentPredefinedVersionOfReport(Parameters.VariantKey, Parameters.ReportName);
	OptionSettings = DecryptionScheme.SettingVariants[VariantKey].Settings;
	
	DataCompositionAvailableSettingsSource = New DataCompositionAvailableSettingsSource(DecryptionScheme);
	DecryptionSettingsComposer.Initialize(DataCompositionAvailableSettingsSource);	
	DecryptionSettingsComposer.LoadSettings(OptionSettings);
	CustomDecryptionSettings = DecryptionSettingsComposer.UserSettings;
	CustomDecryptionSelection = DecryptionSettingsComposer.FixedSettings.Filter;
		
	// Moving the parameters of the calling report
	For Each Item In CustomReportSettings.Items Do
		If TypeOf(Item) = Type("DataCompositionSettingsParameterValue") Then
			ParameterKey =  String(Item.Parameter);
			ParameterValue = Item.Value;
			Use = Item.Use;
			
			DecryptionReportParameter = DataCompositionClientServer.GetParameter(CustomDecryptionSettings, ParameterKey);
			If Not DecryptionReportParameter = Undefined Then
				DataCompositionClientServer.SetParameter(
					CustomDecryptionSettings, ParameterKey, ParameterValue, Use);
			EndIf;
		EndIf;// this is a parameter of the report
	EndDo;// by user settings of the calling report
	
	// Set the passed parameters
	If Parameters.Property("DCSParameters") Then
		For Each Parameter In Parameters.DCSParameters Do
			DecryptionReportParameter = DataCompositionClientServer.GetParameter(CustomDecryptionSettings, Parameter.Key);
			If Not DecryptionReportParameter = Undefined And DecryptionReportParameter.Use Then
				DataCompositionClientServer.SetParameter(CustomDecryptionSettings, Parameter.Key, Parameter.Value);
			EndIf;
		EndDo;
	EndIf;
	
	// We will transfer the selections of the calling report, except for the transmitted ones and selections by decryption fields.
	ExceptionFields = New Structure;
	// We will set the transmitted selections
	If Parameters.Property("Filter") Then
		For Each Filter In Parameters.Filter Do
			ExceptionFields.Insert(Filter.Key);
			NewFilter = CustomDecryptionSelection.Items.Add(Type("DataCompositionFilterItem"));
			FillPropertyValues(NewFilter, Filter.Value);
		EndDo;
	EndIf;
	If Parameters.Property("DecryptionFields") And ValueIsFilled(Parameters.DecryptionFields) Then
		CommonClientServer.SupplementStructure(ExceptionFields, Parameters.DecryptionFields);
	EndIf;
	FinancialReportingServer.CopyFilter(
			ReportSettings.Filter,            // Source
			CustomDecryptionSelection, // Receiver
			True,                           // Only used
			ExceptionFields);                  // Exception fields
	
	// Add selections by decryption fields
	If Parameters.Property("DecryptionFields") And ValueIsFilled(Parameters.DecryptionFields) Then
		For Each Field In Parameters.DecryptionFields Do
			NewFilter = CustomDecryptionSelection.Items.Add(Type("DataCompositionFilterItem"));
			NewFilter.LeftValue = New DataCompositionField(Field.Key);
			NewFilter.RightValue = Field.Value;
		EndDo;
	EndIf;
	
	Return DecryptionSettingsComposer;
	
EndFunction

// The values of the decryption fields.
// 
// Parameters:
//  Details - DataCompositionFieldDetailsItem
//  DetailsDataAddress - String
// 
// Returns:
//  ValueList - Values of the decryption fields
Function DecryptionFieldValues(Details, DetailsDataAddress) Export
	
	DetailsData = GetFromTempStorage(DetailsDataAddress); //DataCompositionDetailsData
	ListOfDecryptionFields = New ValueList();

	If Details <> Undefined Then
		AddNewDecryptionFields(DetailsData.Items[Details], ListOfDecryptionFields);
	EndIf;
	
	Return ListOfDecryptionFields;
	
EndFunction

Procedure ReturnDocumentsToReflection(ReflectionParameters) Export
	
	DocumentsToBeReflected = New ValueTable();
	DocumentsToBeReflected.Columns.Add("Period", Common.DateTypeDetails(DateFractions.DateTime));
	DocumentsToBeReflected.Columns.Add("DateRecord", Common.DateTypeDetails(DateFractions.Date));
	DocumentsToBeReflected.Columns.Add("Document", Documents.AllRefsType());
	DocumentsToBeReflected.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	
	For Each DocumentParameters In ReflectionParameters Do
		NewRow = DocumentsToBeReflected.Add();
		FillPropertyValues(NewRow, DocumentParameters);
		NewRow.DateRecord = NewRow.Period;
	EndDo;
	
	If DocumentsToBeReflected.Count() > 1 Then
		DocumentsToBeReflected.GroupBy("Period,DateRecord,Document,Organization");
	EndIf;
	
	FinancialAccountingPostingServer.ReturnDocumentsToReflection(DocumentsToBeReflected);
	
EndProcedure

#EndRegion

#Region Private

Procedure AddNewDecryptionFields(DetailsItem, ListOfDecryptionFields)
	
	HierarchicalStructure = New Structure("LeftValue, ComparisonType, RightValue");
	HierarchicalStructure.ComparisonType = DataCompositionComparisonType.InHierarchy;
	
	If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
		For Each Field In DetailsItem.GetFields() Do
			If Field.Hierarchy Then
				HierarchicalStructure.LeftValue = New DataCompositionField(Field.Field);
				HierarchicalStructure.RightValue = Field.Value;
				ListOfDecryptionFields.Add(HierarchicalStructure, Field.Field);
			Else
				ListOfDecryptionFields.Add(Field.Value, Field.Field);
			EndIf;
		EndDo;
	EndIf;
	For Each Parent In DetailsItem.GetParents() Do
		AddNewDecryptionFields(Parent, ListOfDecryptionFields);
	EndDo;
	
EndProcedure

Function StandardReportParameters(Details, DetailsDataAddress, DetailsParameters, DecryptionFields)

	ReportParameters = New Structure;
	ReportSelections 	= New Structure;
	
	DetailsData = GetFromTempStorage(DetailsDataAddress); // DataCompositionDetailsData - 
	
	ListOfDecryptionFields = New ValueList;
	AddNewDecryptionFields(DetailsData.Items[Details], ListOfDecryptionFields);
	
	For Each FieldData In ListOfDecryptionFields Do
		
		FieldName = FieldData.Presentation;
		If DecryptionFields.Find(FieldName) = Undefined Then
			Continue;
		EndIf;
		
		If ReportSelections.Property(FieldName) Or ReportParameters.Property(FieldName) Then
			Continue;
		EndIf;
		
		If TypeOf(FieldData.Value) = Type("Structure") Then
			ReportSelections.Insert(FieldName, FieldData.Value);
		Else
			ReportParameters.Insert(FieldName, FieldData.Value);
		EndIf;
		
	EndDo;
	
	For Each ParameterName In DetailsParameters Do
		ParameterValue = DetailsData.Settings.DataParameters.Items.Find(ParameterName);
		If ParameterValue = Undefined Then
			ReportParameters.Insert(ParameterName, Undefined);
		Else
			ReportParameters.Insert(ParameterName, ParameterValue.Value);
		EndIf;
	EndDo; 
	
	StructureOfData = New Structure("Fields, Filters", ReportParameters, ReportSelections);
	
	Return StructureOfData;
		
EndFunction

Function GetTranscriptOfReport(DetailsData, DetailsID)
	
	DecryptionFields  = New Array;
	DecryptionFields.Add("Account");
	DecryptionFields.Add("ExtDimension1");
	DecryptionFields.Add("ExtDimension2");
	DecryptionFields.Add("ExtDimension3");
	DecryptionFields.Add("BalancedAccount");
	DecryptionFields.Add("BalancedExtDimension1");
	DecryptionFields.Add("BalancedExtDimension2");
	DecryptionFields.Add("BalancedExtDimension3");
	DecryptionFields.Add("AccountDr");
	DecryptionFields.Add("AccountCr");
	DecryptionFields.Add("Recorder");
	DecryptionFields.Add("SecondPeriod");
	DecryptionFields.Add("MinutePeriod");
	DecryptionFields.Add("HourPeriod");
	DecryptionFields.Add("DayPeriod");
	DecryptionFields.Add("WeekPeriod");
	DecryptionFields.Add("TenDaysPeriod");
	DecryptionFields.Add("MonthPeriod");
	DecryptionFields.Add("QuarterPeriod");
	DecryptionFields.Add("HalfYearPeriod");
	DecryptionFields.Add("YearPeriod");
	
	DetailsParameters = New Array;
	If GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
		DetailsParameters.Add("ChartOfAccounts");
	EndIf;
	
	ExplanationFormParameters = StandardReportParameters(
									DetailsID, 
									DetailsData,
									DetailsParameters, 
									DecryptionFields);
	
	Return ExplanationFormParameters;
	
EndFunction

// Generates a list of transcripts for a standard report.
//
// Parameters:
//  FullReportName - String - Name of the report to decrypt.
//  CurrentVariantKey - String - The decrypted version of the report.
//  ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Option for generating transactions according to the chart of accounts
//	AccountValues - Structure - Accounts involved in decryption.
//
// Returns:
//  ValueList - Contains the name of the report, the name of the variant, the view for the user
Function PossibleDecryptions(FullReportName, CurrentVariantKey, ChartOfAccounts, AccountValues)
	
	PossibleDecryptions = New ValueList;
	DetailsStructure2 = New Structure("ReportName, VariantName, AdditionalParameters");
	
	OptionForGeneratingTransactions = Common.ObjectAttributeValue(ChartOfAccounts, "OptionForGeneratingTransactions");
	
	If FullReportName = Metadata.Reports.AccountingReportFinancialAccounting.Name Then
		
		If CurrentVariantKey = "OSV_OnAccountOfInternational" Then
			
			If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
				DetailsStructure2.ReportName 		= Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
				DetailsStructure2.VariantName 	= "OSVOnAccountWithCorrespondenceInternational";
				Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
														NStr("vi = 'Bảng cân đối số phát sinh theo tài khoản %1 có đối ứng';
															|ru = 'ОСВ по счету %1 с корреспонденцией';
															|en = 'Trial balance for the account %1 with correspondence'; fa = 'Trial balance for the account %1 with correspondence';
															|it = 'Bilancio di verifica del conto %1 con corrispondenza';
															|pl = 'ZOS według rachunku %1 z korespondencją';
															|tr = '%1 hesabında muhabirleşme Büyük Mizanı'"), AccountValues.Account);
				PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
			EndIf;
			
			DetailsStructure2.ReportName 		= Metadata.Reports.AccountCardFinancialAccounting.Name;
			DetailsStructure2.VariantName 	= "AccountCardFinancialAccounting";
			Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Báo cáo bút toán theo tài khoản %1';
														|ru = 'Отчет по проводкам по счету %1';
														|en = 'Entry report by %1 account'; fa = 'Entry report by %1 account';
														|it = 'Report per transazioni per conto %1';
														|pl = 'Raport dotyczące wpisów księgowych według konta %1';
														|tr = 'Hesap kayıt raporu %1'"), AccountValues.Account);
			PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
			AddPossibleTranscriptsByPeriod(PossibleDecryptions, 
											FullReportName,
											CurrentVariantKey);
			
		ElsIf CurrentVariantKey = "OSV_International" Then
			
			DetailsStructure2.ReportName 		= Metadata.Reports.AccountingReportFinancialAccounting.Name;
			DetailsStructure2.VariantName 	= "OSV_OnAccountOfInternational";
			Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Bảng cân đối số phát sinh theo tài khoản %1';
														|ru = 'ОСВ по счету %1';
														|en = 'Trial balance on %1 account'; fa = 'Trial balance on %1 account';
														|it = 'Bilancio di verifica del conto %1';
														|pl = 'Zestawienie obrotowo-saldowe (ZOS) wg rachunku %1';
														|tr = '%1hesap geçici mizanı'"), AccountValues.Account);
			PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
			
			DetailsStructure2.ReportName 		= Metadata.Reports.AccountCardFinancialAccounting.Name;
			DetailsStructure2.VariantName 	= "AccountCardFinancialAccounting";
			Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Thẻ tài khoản %1';
														|ru = 'Карточка счета %1';
														|en = 'Account card %1'; fa = 'Account card %1';
														|it = 'Scheda del conto %1';
														|pl = 'Karta konta %1';
														|tr = 'Hesap kartı%1'"), AccountValues.Account);
			PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
			
			If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
				DetailsStructure2.ReportName 		= Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
				DetailsStructure2.VariantName 	= "AccountAnalysisInternational";
				Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
														NStr("vi = 'Phân tích tài khoản %1';
															|ru = 'Анализ счета %1';
															|en = 'Analysis of account %1'; fa = 'Analysis of account %1';
															|it = 'Analisi del conto %1';
															|pl = 'Analiza rachunku %1';
															|tr = '%1Hesap analizi'"), AccountValues.Account);
				PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
				
				DetailsStructure2.ReportName 		= Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
				DetailsStructure2.VariantName 	= "OSVOnAccountWithCorrespondenceInternational";
				Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
														NStr("vi = 'Bảng cân đối số phát sinh theo tài khoản %1 có đối ứng';
															|ru = 'ОСВ по счету %1 с корреспонденцией';
															|en = 'Trial balance for the account %1 with correspondence'; fa = 'Trial balance for the account %1 with correspondence';
															|it = 'Bilancio di verifica del conto %1 con corrispondenza';
															|pl = 'ZOS według rachunku %1 z korespondencją';
															|tr = '%1 hesabında muhabirleşme Büyük Mizanı'"), AccountValues.Account);
				PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
			
			EndIf;
			AddPossibleTranscriptsByPeriod(PossibleDecryptions, 
											FullReportName,
											CurrentVariantKey);
			
		ElsIf CurrentVariantKey = "AnalysisOfExtdimensionInternational" Then
			
			DetailsStructure2.ReportName 		= "AccountCardFinancialAccounting";
			DetailsStructure2.VariantName 	= "AccountCardFinancialAccounting";
			Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Thẻ tài khoản %1';
														|ru = 'Карточка счета %1';
														|en = 'Account card %1'; fa = 'Account card %1';
														|it = 'Scheda del conto %1';
														|pl = 'Karta konta %1';
														|tr = 'Hesap kartı%1'"), AccountValues.Account);
			PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
			
		EndIf;
	
	ElsIf FullReportName =  Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name Then
		
		If CurrentVariantKey = "AccountAnalysisInternational" Then
			
			DetailsStructure2.ReportName 		= Metadata.Reports.AccountCardFinancialAccounting.Name;
			DetailsStructure2.VariantName 	= "TransactionReportInternational";
			Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Báo cáo theo bút toán %1';
														|ru = 'Отчет по проводкам %1';
														|en = 'Entry report %1'; fa = 'Entry report %1';
														|it = 'Report sulle registrazioni %1';
														|pl = 'Raport o księgowaniu %1';
														|tr = 'Kayıt raporu %1'"), AccountValues.Account);
			PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
			
			DetailsStructure2.ReportName 		= Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
			DetailsStructure2.VariantName 	= "OSVOnAccountWithCorrespondenceInternational";
			Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Bảng cân đối số phát sinh theo tài khoản %1 có đối ứng';
														|ru = 'ОСВ по счету %1 с корреспонденцией';
														|en = 'Trial balance for the account %1 with correspondence'; fa = 'Trial balance for the account %1 with correspondence';
														|it = 'Bilancio di verifica del conto %1 con corrispondenza';
														|pl = 'ZOS według rachunku %1 z korespondencją';
														|tr = '%1 hesabında muhabirleşme Büyük Mizanı'"), AccountValues.Account);
			PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
						
		ElsIf CurrentVariantKey = "OSVOnAccountWithCorrespondenceInternational" Then
			
			DetailsStructure2.ReportName 		= Metadata.Reports.AccountCardFinancialAccounting.Name;
			DetailsStructure2.VariantName 	= "TransactionReportInternational";
			Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Báo cáo theo bút toán %1';
														|ru = 'Отчет по проводкам %1';
														|en = 'Entry report %1'; fa = 'Entry report %1';
														|it = 'Report sulle registrazioni %1';
														|pl = 'Raport o księgowaniu %1';
														|tr = 'Kayıt raporu %1'"), AccountValues.Account);
			PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
				
		EndIf;
		
		AddPossibleTranscriptsByPeriod(PossibleDecryptions, 
												FullReportName,
												CurrentVariantKey);

	ElsIf FullReportName = Metadata.Reports.ArticulationStatementFinancialAccounting.Name Then
		
		DetailsStructure2.ReportName 		= Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
		DetailsStructure2.VariantName 	= "OSVOnAccountWithCorrespondenceInternational";
		DetailsStructure2.AdditionalParameters = New Structure("DrCr", "Dr");
		Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Bảng cân đối số phát sinh theo tài khoản %1 có đối ứng';
														|ru = 'ОСВ по счету %1 с корреспонденцией';
														|en = 'Trial balance for the account %1 with correspondence'; fa = 'Trial balance for the account %1 with correspondence';
														|it = 'Bilancio di verifica del conto %1 con corrispondenza';
														|pl = 'ZOS według rachunku %1 z korespondencją';
														|tr = '%1 hesabında muhabirleşme Büyük Mizanı'"), AccountValues.AccountDr);
		PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
		
		DetailsStructure2.ReportName 		= Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
		DetailsStructure2.VariantName 	= "OSVOnAccountWithCorrespondenceInternational";
		DetailsStructure2.AdditionalParameters = New Structure("DrCr", "Cr");
		Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Bảng cân đối số phát sinh theo tài khoản %1 có đối ứng';
														|ru = 'ОСВ по счету %1 с корреспонденцией';
														|en = 'Trial balance for the account %1 with correspondence'; fa = 'Trial balance for the account %1 with correspondence';
														|it = 'Bilancio di verifica del conto %1 con corrispondenza';
														|pl = 'ZOS według rachunku %1 z korespondencją';
														|tr = '%1 hesabında muhabirleşme Büyük Mizanı'"), AccountValues.AccountCr);
		PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
		
	ElsIf FullReportName = Metadata.Reports.AccountCardFinancialAccounting.Name Then
		
		If CurrentVariantKey = "SummaryTransactions" Then
			
			DetailsStructure2.ReportName 		= Metadata.Reports.AccountCardFinancialAccounting.Name;
			DetailsStructure2.VariantName 	= "TransactionReportInternational";
			Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Báo cáo theo bút toán %1';
														|ru = 'Отчет по проводкам %1';
														|en = 'Entry report %1'; fa = 'Entry report %1';
														|it = 'Report sulle registrazioni %1';
														|pl = 'Raport o księgowaniu %1';
														|tr = 'Kayıt raporu %1'"), AccountValues.Account);
			PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
			
		Else
			
			PossibleDecryptions.Add("Recorder", "Recorder");
			
		EndIf;
		
	ElsIf FullReportName = Metadata.Reports.FinancialReport.Name Then
		
		DetailsStructure2.ReportName 		= Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
		DetailsStructure2.VariantName 	= "AccountAnalysisInternational";
		Presentation						= StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = 'Phân tích tài khoản %1';
														|ru = 'Анализ счета %1';
														|en = 'Analysis of account %1'; fa = 'Analysis of account %1';
														|it = 'Analisi del conto %1';
														|pl = 'Analiza rachunku %1';
														|tr = '%1Hesap analizi'"), AccountValues.Account);
		PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
		
	EndIf;

	Return PossibleDecryptions;
	
EndFunction

Procedure AddPossibleTranscriptsByPeriod(PossibleDecryptions, ReportName, VariantName)
	DetailsStructure2 = New Structure("ReportName, VariantName, AdditionalParameters");

	DetailsStructure2.ReportName 		= ReportName;
	DetailsStructure2.VariantName 	= VariantName;
	DetailsStructure2.AdditionalParameters = New Structure("GroupByPeriod", "DayPeriod");
	Presentation						= NStr("vi = 'Kỳ, Ngày';
												|ru = 'Период, День';
												|en = 'Period, Day'; fa = 'Period, Day';
												|it = 'Период, День';
												|pl = 'Period, Day';
												|tr = 'Dönem, gün'");
	PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
	
	DetailsStructure2.ReportName 		= ReportName;
	DetailsStructure2.VariantName 	= VariantName;
	DetailsStructure2.AdditionalParameters = New Structure("GroupByPeriod", "WeekPeriod");
	Presentation						= NStr("vi = 'Kỳ, Tuần';
												|ru = 'Период, Неделя';
												|en = 'Period, Week'; fa = 'Period, Week';
												|it = 'Период, Неделя';
												|pl = 'Period, Week';
												|tr = 'Dönem, hafta'");

	PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
	
	DetailsStructure2.ReportName 		= ReportName;
	DetailsStructure2.VariantName 	= VariantName;
	DetailsStructure2.AdditionalParameters = New Structure("GroupByPeriod", "TenDaysPeriod");
	Presentation						= NStr("vi = 'Kỳ, 10 ngày';
												|ru = 'Период, Декада';
												|en = 'Period, Ten-day period'; fa = 'Period, Ten-day period';
												|it = 'Период, Декада';
												|pl = 'Period, Ten-day period';
												|tr = 'Dönem, On gün'");
									
	PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
	
	DetailsStructure2.ReportName 		= ReportName;
	DetailsStructure2.VariantName 	= VariantName;
	DetailsStructure2.AdditionalParameters = New Structure("GroupByPeriod", "MonthPeriod");
	Presentation						= NStr("vi = 'Kỳ, Tháng';
												|ru = 'Период, Месяц';
												|en = 'Period, month'; fa = 'دوره، ماه';
												|it = 'Период, Месяц';
												|pl = 'Okres, miesiąc';
												|tr = 'Dönem, Ay'");
										
	PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
	
	DetailsStructure2.ReportName 		= ReportName;
	DetailsStructure2.VariantName 	= VariantName;
	DetailsStructure2.AdditionalParameters = New Structure("GroupByPeriod", "HalfYearPeriod");
	Presentation						= NStr("vi = 'Kỳ, Nửa năm';
												|ru = 'Период, Полугодие';
												|en = 'Period, half-year'; fa = 'دوره، نیم‌سال';
												|it = 'Период, Полугодие';
												|pl = 'Okres, półrocze';
												|tr = 'Dönem, Yarıyıl'");
										
	PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
	
	DetailsStructure2.ReportName 		= ReportName;
	DetailsStructure2.VariantName 	= VariantName;
	DetailsStructure2.AdditionalParameters = New Structure("GroupByPeriod", "YearPeriod");
	Presentation						= NStr("vi = 'Kỳ, Năm';
												|ru = 'Период, Год';
												|en = 'Period, year'; fa = 'دوره، سال';
												|it = 'Период, Год';
												|pl = 'Okres, rok';
												|tr = 'Dönem, Yıl'");
										
	PossibleDecryptions.Add(New FixedStructure(DetailsStructure2), Presentation);
EndProcedure

#EndRegion