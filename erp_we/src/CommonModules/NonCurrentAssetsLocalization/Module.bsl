////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Non-current assets" intended for localization.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The function checks whether the version 2.2 Fixed and intangible assets are being maintained.
// 
// Returns:
//  Boolean - True if the Fixed and intangible assets of version 2.2 are being kept.
//
Function ThereIsAccountingOfNonCurrentAssets2_2() Export

	Result = False;
	
	
	Return Result;

EndFunction

// Returns the start date of accounting for non-current assets in version 2.4.
// 
// Returns:
//  Date - The start date of accounting.
//
Function StartDateOfCapitalAssetsAccounting24() Export

	AccountingStartDate = '000101010000';
	
	
	Return AccountingStartDate;
	
EndFunction
 
Procedure AccountingPoliciesOfOrganizationsBeforeWrite(RecordSet) Export

	
EndProcedure

Procedure AccountingPoliciesOfOrganizationsWhenRecording(RecordSet) Export

	
EndProcedure

#Region MigrationToFixedAssetAccounting2

// The closing stage of the month returns, aimed at the transition of accounting for non-current assets to version 2.4.
// 
// Returns:
//  CatalogRef.MonthEndClosingOperations
//
Function OperationOfSwitchingToFixedAndIntangibleAssets2_4() Export
	
	Operation = Undefined;
	
	Return Operation;
	
EndFunction


#EndRegion


#EndRegion

#Region Internal


#Region DepreciationCalculation

Procedure AddAccountingParametersForNonCurrentAssets(Val CalculationParameters) Export

	
EndProcedure

#EndRegion

#Region GenerateTaskRegisterEntries

Procedure GenerateTaskRegisterEntries(Document, TablesData) Export

	
EndProcedure

Function RequestTextForGeneratingTasksForCalculatingFADepreciation(TablesData, DataJoinText) Export

	QueryText = Undefined;
	
	
	Return QueryText;

EndFunction
 
Function RequestTextForGeneratingTasksForCalculatingIADepreciation(TablesData, DataJoinText) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction
 
#EndRegion

#Region FADocumentLog

// 
// Parameters:
//  BusinessTransactionsAndDocuments - ValueTable of ValueTableRow -
//  PurposeUseKey - String -
Procedure SupplementBusinessOperationsAndFADocuments(BusinessTransactionsAndDocuments, PurposeUseKey) Export

	
EndProcedure

Procedure SupplementTextOfFALogRequest(QueryText) Export

	
EndProcedure

// 
// Parameters:
// 	DocumentCorrespondence - FormDataCollection of FormDataCollectionItem - 
Procedure FillInCorrespondenceOfFALogDocuments(DocumentCorrespondence) Export

	
EndProcedure

// 
// Parameters:
// 	DocumentCorrespondence - FormDataCollection of FormDataCollectionItem - 
Procedure FillInCorrespondenceOfIaJournalDocuments(DocumentCorrespondence) Export
	
	
EndProcedure

#EndRegion

#Region JournalOfIADocuments
 
Procedure SupplementTextOfIAJournalRequest(QueryText) Export

	
EndProcedure

#EndRegion

#Region QueriesTexts

// 
// Parameters:
// 	QueryTexts - ValueList of String - 
// 	NameOfAccountingObjectTable - String -
Procedure QueryTextTableTTTaxationIA(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export

	TableName = "TTVATTaxation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("LocalFAAccounting") Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForNmabu(QueryTexts, NameOfAccountingObjectTable);
	
		QueryText = 
		"SELECT
		|	AccountingProcedure.Ref AS Ref,
		|	AccountingProcedure.IntangibleAsset AS IntangibleAsset,
		|	AccountingProcedure.VATTaxation AS VATTaxation
		|
		|INTO TTVATTaxation
		|
		|FROM
		|	TTAccountingProcedureForNmabu AS AccountingProcedure";
		
	Else	
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForIA(QueryTexts, NameOfAccountingObjectTable);
	
		QueryText = 
		"SELECT
		|	AccountingProcedure.Ref AS Ref,
		|	AccountingProcedure.IntangibleAsset AS IntangibleAsset,
		|	UNDEFINED AS VATTaxation
		|
		|INTO TTVATTaxation
		|
		|FROM
		|	TTAccountingProcedureForIA AS AccountingProcedure";
		
	EndIf;
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Function RequestTextTableReflectionOfAccruedDepreciationInOtherExpenses(Add_Fields) Export

	QueryText = Undefined;
	
	
	Return QueryText

EndFunction

Function QueryTextCostAndDepreciationOfComponentsComponents() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction
 
Function QueryTextCheckPossibilityOfAcceptingIAForAccounting() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function QueryTextTableAssetActivityRecordsUpdate(ListOfTtToDelete) Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function QueryTextCalculateFAAmortizationPackageNumbers() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function QueryTextCalculateIADepreciationPackageNumbers() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function QueryTextCheckDetailsOfFAWhenTakingIntoAccount(Query, Object) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextRequiresFADepreciationCalculation(Period) Export

	QueryText = Undefined;
	
	
	Return QueryText;

EndFunction
 
Function QueryTextRequiresCalculationOfIaDepreciation(Period) Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function QueryTextCheckThatIAAreAcceptedForAccounting() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction
 
Function TextOfRequestOtherexpensesOfAcceptanceForAccounting(ListOfMergeRequests) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextOfOtherExpensesShouldNotBeTakenIntoAccountAndIncludedInExpenses(ThereIsAccountingProcedureForMA, ThereIsAccountingProcedureForAC, ThereIsAccountingProcedureWELL) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction


#EndRegion

#Region MasterDataSectionNonCurrentAssets

Procedure WhenCreatingOnServer_PanelOfCatalogsNonCurrentAssets(Form) Export

	
EndProcedure

Procedure ItemManagement_CatalogPanelNonCurrentAssets(Form) Export
	
	
EndProcedure
 
#EndRegion

#Region CAAdministrationPanel

Procedure SavePropsValue_KaAdministrationPanel(Form, DataPathAttribute, ConstantName) Export

	
EndProcedure
 
#EndRegion

#Region StandardSubsystems

// Defines a list of configuration objects, in the modules of managers of which the procedure is provided 
// Add a creation command on the basis that forms creation commands based on objects.
// For the syntax of the Add Command Creation procedure, see the documentation.
//
// Parameters:
//   Objects - Array - metadata objects (metadata Objects) with commands to create based on.
//
// Example:
//	Objects.Add (Metadata.Guides.Companies);
//   
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export

	
EndProcedure

#EndRegion

#Region Other

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportsOptions(Settings) Export

	
EndProcedure

// 
// Parameters:
// 	Objects - See NonCurrentAssets.DefineObjectsWithReportCommands.Objects 
Procedure DefineObjectsWithReportCommands(Objects) Export

	
EndProcedure

// 
// Parameters:
// 	CurRequestTexts - Array -
Procedure AddQueryTextToTableOtherIncomeAtRevaluation(CurRequestTexts) Export

	
EndProcedure

// 
// Parameters:
// 	QueryTexts - ValueList -
//	KindOfAccountingObjects - String -
//	
// Returns:
//	String -
Function QueryTextTableTTMethodOfRevaluation(QueryTexts, KindOfAccountingObjects) Export
	
	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

// 
// Parameters:
// 	ListOfMergeRequests - Array
Procedure ToSupplementTextOfRequestThereIsAccountingOfNonCurrentAssets(ListOfMergeRequests) Export

	
EndProcedure

// 
// Parameters:
// 	ListOfMergeRequests - Array
Procedure ToSupplementTextOfRequestThereIsAccountingOfNonCurrentAssets2_4(ListOfMergeRequests) Export

	
EndProcedure
 
// 
// Parameters:
// 	EmptyWaysToReflectDepreciation - Array -
Procedure ComplementEmptyWaysToReflectDepreciation(EmptyWaysToReflectDepreciation) Export
	
	
EndProcedure
 
Procedure IntangibleAssetSelectionData2_2(Parameters) Export

	
EndProcedure

Procedure DataSelectionOfObjectsOfOperation2_2(Parameters) Export

	
EndProcedure

Procedure AddAccountingInformation(AccountingPresence) Export

	
EndProcedure
 
Procedure CheckPossibilityOfAcceptingIAForAccounting(Selection, Object, Path, Cancel) Export
	

EndProcedure
 
Function VNAManagementIsUsed_2_4(Period) Export

	VNAManagementIsUsed_2_4 = True;
	

	Return VNAManagementIsUsed_2_4;
	
EndFunction
 
Function VNAManagementIsUsed() Export

	VNAManagementIsUsed = False;
	
	
	Return VNAManagementIsUsed;
	
EndFunction

Function ConditionsForSwitchingToAccounting2_2() Export

	CommentAccounting2_2 = "";
	
	If Not Constants.UseLocal.Get() Then
		CommentAccounting2_2 = CommentAccounting2_2 + Chars.LF
			+ NStr("vi = '- bật tùy chọn ""Kế toán tài chính""
                    |(phân hệ ""Danh mục và quản trị"" - ""Kế toán tài chính"")';
                    |ru = '- включить опцию ""Регламентированный учет""
                    |(раздел ""НСИ и администрирование"" - ""Регламентированный учет"")';
                    |en = '- enable the Local accounting option
                    | (in ""Master data and settings"" — ""Local accounting"")'; fa = '- enable the Local accounting option
                    | (in ""Master data and settings"" — ""Local accounting"")';
                    |it = '- abilitare opzione ""Contabilità regolatoria""
                    | (sezione ""Dati anagrafici e amministrazione"" - ""contabilità regolatoria"")';
                    |pl = '- włączyć opcję ""Ewidencja reglamentowana""
                    |(rozdział ""INP i narzędzia administracyjne"" - ""Ewidencja reglamentowana"")';
                    |tr = '- ""Düzenlenmiş muhasebe"" seçeneğini etkinleştirin
                    |(""Master veri ve yönetim"" - ""Yerel muhasebe"" bölümü)'");
	EndIf;
	
	If ValueIsFilled(CommentAccounting2_2) Then
		CommentAccounting2_2 = NStr("vi = 'Để kích hoạt khả năng kế toán của phiên bản 2.2, bạn phải:';
									|ru = 'Для включения возможности учета версии 2.2 необходимо:';
									|en = 'To enable accounting 2.2:'; fa = 'To enable accounting 2.2:';
									|it = 'Per abilitare la contabilità nella versione 2.4. è necessario:';
									|pl = 'Dla włączenia możliwości ewidencji wersji 2.2 należy:';
									|tr = 'Sürüm 2.2 muhasebe özelliğini etkinleştirmek için şunları yapmanız gereklidir:'") + CommentAccounting2_2;
	EndIf; 
	
	AccountingAvailability2_2 = New Structure;
	AccountingAvailability2_2.Insert("CommentAccounting2_2", CommentAccounting2_2);
	AccountingAvailability2_2.Insert("AccountingIsAvailable", Not ValueIsFilled(CommentAccounting2_2));
	
	Return AccountingAvailability2_2;
	
EndFunction

Procedure ConditionsForSwitchingToAccounting2_4(MinimumAccountingStartDate2_4, CommentMinStartDate2_4, MaximumStartDateOfAccounting2_4, CommentMaxStartDate2_4) Export

	
EndProcedure
 
Procedure AddConditionsForSwitchingToAccounting2_4(AccountingAvailability2_4) Export

	
EndProcedure

Procedure CheckDetailsOfFAWhenTakingIntoAccount(Selection, Object, Path, Cancel) Export

	
EndProcedure

Function ThereAreRightsToReadStateOfIA() Export

	HasRights = True;
	
	
	Return HasRights;

EndFunction
 
// 
// Parameters:
// 	BusinessTransactionsAndDocuments - ValueTable of ValueTableRow - 
Procedure CompleteDescriptionOfOperationsAndDocumentTypesForProcurementDocumentLog(BusinessTransactionsAndDocuments) Export

	
EndProcedure

Function QueryTextFAAcceptedForAccounting() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function QueryTextIAAcceptedForAccounting() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function MarginalCostOfWriteOffForExpenses() Export

	Return 100000;
	
EndFunction

// See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	For Each DocumentName In ListOfVNADocuments() Do
		
		PeriodClosingDates.AddRow(
			DataSources, 
			"Document." + DocumentName,
			"Date", 
			"NonCurrentAssets", 
			"Organization");
			
	EndDo;
	
EndProcedure

// Returns a list of documents in the VNA subsystem.
// 
// Returns:
// 	Array - List of documents of the VNA subsystem.
//
Function ListOfVNADocuments() Export
	
	ListOfVNADocuments = New Array;
	

	Return ListOfVNADocuments;
	
EndFunction

#EndRegion


#Region CheckingAvailabilityOfAccountingAccounts

// Returns an indication that there are errors in filling in the settings for reflecting the depreciation of IA in regulated accounting.
//
// Parameters:
// 		CompanyArray - Array, CatalogRef.Companies - Array or link to an element in the directory of organizations that are being checked
// 		Period - Date - The period of reflection attenuation.
//
// Returns:
// 		Boolean - True if there are errors in filling in the expense reflection settings.
//
Function ThereAreErrorsFillingInIADepreciationExpense(CompanyArray, Period) Export
	
	ReturnValue_1 = False;
	Return ReturnValue_1;
	
EndFunction

// Returns whether there are errors in filling in the settings for reflecting depreciation of the fixed asset in regulated accounting.
//
// Parameters:
// 		CompanyArray - Array, CatalogRef.Companies - Array or link to an element in the directory of organizations that are being checked
// 		Period - Date - The period of reflection attenuation.
//
// Returns:
// 		Boolean - True if there are errors in filling in the expense reflection settings.
//
Function ThereAreErrorsFillingFADepreciationCosts(CompanyArray, Period) Export
	
	ReturnValue_1 = False;
	
	Return ReturnValue_1;
	
EndFunction

// Returns an indication that there are errors in filling in the settings for reflecting income from targeted financing of an IA in
// regulated accounting.
//
// Parameters:
// 		CompanyArray - Array, CatalogRef.Companies - Array or link to an element in the directory of organizations that are being checked
// 		Period - Date - Period of income reflection.
//
// Returns:
// 		Boolean - True if there are errors in filling in the expense reflection settings.
//
Function ThereAreErrorsInFillingInIncomeOfTargetedFinancingOfIa(CompanyArray, Period) Export
	
	ReturnValue_1 = False;
	Return ReturnValue_1;
	
EndFunction

// Returns an indication that there are errors in filling in the settings for reflecting income from target financing of the OS in
// regulated accounting.
//
// Parameters:
// 		CompanyArray - Array, CatalogRef.Companies - Array or link to an element in the directory of organizations that are being checked
// 		Period - Date - Period of income reflection.
//
// Returns:
// 		Boolean - True if there are errors in filling in the expense reflection settings.
//
Function ThereAreErrorsFillingInRevenuesOfTargetFAFunding(CompanyArray, Period) Export
	
	ReturnValue_1 = False;
	Return ReturnValue_1;
	
EndFunction

#EndRegion

#EndRegion

#Region Private
 
Function DocumentNameDepreciationFA() Export

	DocumentName = "";
	
	
	Return DocumentName;

EndFunction

Function DocumentNameIADepreciation() Export

	DocumentName = "";
	
	
	Return DocumentName;

EndFunction

Procedure SetParametersOfSetOfPropertiesInH22() Export

	
EndProcedure

Function DocumentHasAttachedFiles(TypeFileOwner) Export

	DocumentHasAttachedFiles = False;
	
	
	Return DocumentHasAttachedFiles;
	
EndFunction
 
// Adds roles to the profile that allow you to work in the VNA subsystem with change rights.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRolesToAccessSubsystemInResponseToChange(ProfileDetails) Export
	

EndProcedure

// Adds roles to the profile that allow you to work in the VNA subsystem with read rights.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRolesForReadAccessToVNASubsystem(ProfileDetails) Export
	

EndProcedure

Procedure SupplementAccountantForNonCurrentAssetsProfile(ProfileDetails) Export

	
EndProcedure

Procedure AddRegistersThatSupportCorrections(RegistersList) Export
	
	
EndProcedure

Procedure ReturnDocumentsToReflection(Ref, Organization, Date, TablesForRegisteredRecords) Export
	

EndProcedure

// Determines the possibility of entering a depreciation premium as a percentage of the amount.
// 
// Parameters:
//  Date - Date -
//  Organization - CatalogRef.Companies -
//  ExpenseItemOfDepreciationAllowance - ChartOfCharacteristicTypesRef.ExpenseItems - 
//  ListOfFA - Array - 
// 
// Returns:
//  Boolean - True if the depreciation premium can be specified as a percentage of the amount.
Function BonusDepreciationInputInPercentsIsAvailable(Date, Organization, ExpenseItemOfDepreciationAllowance, ListOfFA) Export
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"VATAccountingSettings",
		Organization,
		Date);
	
	If Not AccountingPolicyParameters = Undefined
		And (Not AccountingPolicyParameters.SeparateFAAccountingByVATTaxation
		Or Not ValueIsFilled(ExpenseItemOfDepreciationAllowance)
		Or ListOfFA.Count() = 0) Then
		
		Return True;
	EndIf;
	
	CostAllocationOptionLocal = Common.ObjectAttributeValue(
								ExpenseItemOfDepreciationAllowance, 
								"CostAllocationOptionLocal");
								
	If CostAllocationOptionLocal <> Enums.CostAllocationOptions.ToInventoryCost Then
		Return True;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	1
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&Date,
	|			CorrectionDate = DATETIME(1,1,1)
	|				AND FixedAsset IN (&ListOfFA)
	|				AND Organization = &Organization) AS AccountingProcedureForOSBUSliceLast
	|WHERE
	|	AccountingProcedureForOSBUSliceLast.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Date", ?(Date <> '000101010000', Date, CurrentSessionDate()));
	Query.SetParameter("ListOfFA", ListOfFA);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Result.IsEmpty();

EndFunction

// Allows you to add to the Query Text the formation of a register table when localizing the depreciation calculation.
// 
// Parameters:
//  RegisterName - String - Register name
//  TableName - String - table name
//  AccountingObject - String - Accounting object
//  ListOfRequests - Array of String -
//  CalculatingFields - Structure, Undefined - Calculating fields
Procedure QueryTextDepreciationCalculationParameters(RegisterName, TableName, AccountingObject, ListOfRequests, CalculatingFields = Undefined) Export

	
EndProcedure

#Region Mechanisms

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	
EndProcedure

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export


EndProcedure

#EndRegion


// Date of termination of benefits introduced by law No. 249-FZ.
// 
// Returns:
//  Date - Date of termination of benefits.
//
Function DateOfTerminationOfBenefitsPlato() Export

	Return '201901010000';

EndFunction

Procedure CreateTasksWhenRecordingRegisteredRecordsAndPayments(TempTablesManager) Export
	
	
EndProcedure


#EndRegion
