
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the default structure passed as a parameter to the validation procedure "Prioritizable".
// 
// Returns:
// 	Structure - LongDesc:
//      * NodeVerificationParameters - Structure -:
//           ** Form - Undefined -
//           ** Report_Errors - Boolean -
//           ** ErrorStream - Structure -
//      * CheckNodes - Boolean -
//      * UseSubAssets - Boolean -
//      * Form - ClientApplicationForm - with Attributes:
//           ** PropertiesAdditionalAttributeDetails - FormDataCollection - with columns:
//                  *** Description - String -
//      * Report_Errors - Boolean -
//      * ErrorStream - Structure -
Function FillVerificationParameters() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("ErrorStream", New Structure);
	Assets.InitializeErrorFlow(Parameters.ErrorStream);
	
	Parameters.Insert("Report_Errors", True);
	Parameters.Insert("Form", Undefined);
	
	Parameters.Insert("UseSubAssets", GetFunctionalOption("UseSubAssets"));
	
	Parameters.Insert("CheckNodes", True);
	Parameters.Insert("NodeVerificationParameters", Catalogs.SubAssets.FillVerificationParameters());
	Parameters.NodeVerificationParameters.Insert("Report_Errors", False);
	
	Return Parameters;
	
EndFunction

// Returns a description of the operation object's details
//
// Returns:
//		ValueTable - A table with a description of the details of an element of the directory of objects of operation.
//
Function CompositionOfDetailsOfObjectOfOperation() Export
	
	// Description of the format of the returned details table
	Table = New ValueTable;
	Table.Columns.Add("Name", New TypeDescription("String"));
	Table.Columns.Add("Synonym", New TypeDescription("String"));
	Table.Columns.Add("RequiredForFilling", New TypeDescription("Boolean"));
	Table.Columns.Add("RequiredForViewOnly", New TypeDescription("Boolean"));
	
	// The values to be filled in by default in the row of each of the details
	DefaultValues = New Structure;
	DefaultValues.Insert("Name", "");
	DefaultValues.Insert("Synonym", "");
	DefaultValues.Insert("RequiredForFilling", "False");
	DefaultValues.Insert("RequiredForViewOnly", "False");
	
	// Descriptions of the details, with parameter values different from the "default"
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("DateOfLastEdit", New Structure("RequiredForViewOnly", True));
	AttributesStructure1.Insert("Status", New Structure("RequiredForViewOnly", True));
	AttributesStructure1.Insert("Class", New Structure("RequiredForViewOnly", True));
	AttributesStructure1.Insert("Subclass", New Structure("RequiredForFilling, RequiredForViewOnly", False, True));
	
	// A list of details that should be excluded: service, unused, intended for deletion, Boolean attributes
	// or any other not intended for interactive user configuration.
	StopList = New Structure;
	StopList.Insert("OSType");
	StopList.Insert("Comment");
	StopList.Insert("HouseholdObject");
	StopList.Insert("DateOfLastEdit");
	StopList.Insert("RegisteredInPlatonSystemRegistry");
	StopList.Insert("ConsiderResidualLiabilityValue");
	
	If Not GetFunctionalOption("LocalFAAccounting") Then
		StopList.Insert("OSGroup");
	EndIf;

	If Not GetFunctionalOption("UseFinancialAccounting") Then
		StopList.Insert("FixedAssetsGroupFinancialAccounting");
	EndIf;
	
	// Getting the details table from the metadata description
	StructureOfCatalog = Metadata.Catalogs.Assets;
	For Each Attribute In StructureOfCatalog.Attributes Do
		
		If StopList.Property(Attribute.Name) Then
			Continue;
		EndIf;
		
		PropsString = Table.Add();
		FillPropertyValues(PropsString, DefaultValues);
		FillPropertyValues(PropsString, Attribute);
		
		PropsString.RequiredForFilling = (Attribute.FillChecking = FillChecking.ShowError);
		
		If AttributesStructure1.Property(Attribute.Name) Then
			FillPropertyValues(PropsString, AttributesStructure1[Attribute.Name]);
		EndIf;
		
	EndDo;
	
	Return Table;
	
EndFunction

// Checks whether the passed verification object is filled in according to the specified parameters.
//
// Parameters:
// 		VerificationObject - FormDataStructure, CatalogObject.Assets, CatalogRef.Assets - An object reference or array of references to objects of exploitation, which is necessary to check the correctness of filling.
// 		CheckParameters - See Catalogs.Assets.FillVerificationParameters
// 		Cancel - Boolean - Return parameter that indicates whether there are errors during verification.
//
Procedure CheckFillingOfObjectOfOperation(VerificationObject, CheckParameters, Cancel=False) Export
	
	CachedValues = Undefined;
	Assets.InitializeCachedFillCheckValues(CachedValues);
	
	ObjectType = TypeOf(VerificationObject);
	
	ArrayOfOperationalObjects = New Array;
	
	If ObjectType = Type("CatalogRef.Assets")
		Or ObjectType = Type("Array") Then
		
		Query = New Query;
		Query.SetParameter("Assets", VerificationObject);
		
		GenerateFillVerificationRequest(Query.Text);
		
		Result = Query.Execute();
		
		If Result.IsEmpty() Then
			Return;
		EndIf;
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			CheckObjectOfOperation(
				Selection,
				CheckParameters,
				CachedValues);
			
			ArrayOfOperationalObjects.Add(Selection.Ref);
			
		EndDo;
		
	Else
		
		CheckObjectOfOperation(
			VerificationObject,
			CheckParameters,
			CachedValues);
		
		ArrayOfOperationalObjects.Add(VerificationObject.Ref);
		
	EndIf;
	
	CheckParameters.Insert("NodeValidationFailure", False);
	
	If CheckParameters.UseSubAssets
		And CheckParameters.CheckNodes Then
		
		Query = New Query;
		Query.SetParameter("Assets", ArrayOfOperationalObjects);
		GenerateRequestToCheckFillingOfNodes(Query.Text);
		
		Result = Query.Execute();
		
		If Not Result.IsEmpty() Then
			
			Selection = Result.Select();
			
			While Selection.Next() Do
				
				Catalogs.SubAssets.CheckFilling(
					Selection,
					CheckParameters.NodeVerificationParameters,
					CheckParameters.NodeValidationFailure, // Cancel
					CachedValues);
				
			EndDo;
			
		EndIf;
	EndIf;
	
	If CheckParameters.ErrorStream.ErrorList.Count() <> 0 Then
		Cancel = True;
	EndIf;
	
	If CheckParameters.NodeVerificationParameters.ErrorStream.ErrorList.Count() <> 0 Then
		Cancel = True;
	EndIf;
	
	If CheckParameters.Report_Errors Then
		Assets.ReportFillVerificationErrors(CheckParameters.ErrorStream, Cancel);
	EndIf;
	
EndProcedure

// Performs the unlock operation of the object to permit interactive editing.
//
// Parameters:
//	Asset - CatalogRef.Assets - Link to a reference list item
//	Cancel - Boolean - Return parameter that indicates whether there are errors during execution.
//
Procedure UnlockObjectOfOperation(Asset, Cancel=False) Export
	
	FillingData = New Structure("Status", Enums.AssetStatuses.IsBeingEdited);
	
	ObjectOfCatalog = Asset.GetObject();
	
	FillPropertyValues(ObjectOfCatalog, FillingData);
	Try
		ObjectOfCatalog.Write();
	Except
		Cancel = True;
		Raise NStr("vi = 'Đã xảy ra lỗi trong khi cố gắng ghi lại tài sản đang vận hành:';
					|ru = 'Ошибка при попытке записи объекта эксплуатации:';
					|en = 'An error occurred while trying to save asset:'; fa = 'An error occurred while trying to save asset:';
					|it = 'Errore durante il tentativo di scrittura dell''oggetto di esercizio:';
					|pl = 'Błąd podczas próby zapisania obiektu eksploatacji:';
					|tr = 'İşletimsel bir nesne kaydedilmeye çalışılırken hata oluştu:'") + " " + ErrorInfo().Description;
	EndTry;
	
EndProcedure

// Generates information about fixed asset accounting
//
// Parameters:
//  FixedAsset - CatalogRef.Assets, Array - The main tool to get information for.
//  FilterOrganization - CatalogRef.Companies - The organization for which you want to retrieve information.
//  Date - Date -
//  Recorder - DocumentRef -
// 
// Returns:
//  Structure, Map, Undefined - Contains information about accounting.
//
Function InformationAboutAccounting(FixedAsset, FilterOrganization = Undefined, Date = '00010101', Recorder = Undefined) Export

	If Not ValueIsFilled(FixedAsset) Then
		Return Undefined;
	EndIf;

	InformationAboutAccounting = AssetsLocalization.InformationAboutAccounting(FixedAsset, FilterOrganization, Date, Recorder);
	
	If InformationAboutAccounting = NULL Then
		
		If Not AccessRight("Read", Metadata.InformationRegisters.FALocation)
			Or Not AccessRight("Read", Metadata.InformationRegisters.InitialFixedAssetsInformation)
			Or Not AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedure)
			Or Not AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting)
			Or Not AccessRight("Read", Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting) Then
			Return Undefined;
		EndIf;
		
		QueryText = 
		"SELECT ALLOWED
		|	FALocation.FixedAsset AS FixedAsset,
		|
		|	ISNULL(InitialFixedAssetsInformation.CommissioningDateAC, DATETIME(1, 1, 1)) AS CommissioningDateAC,
		|	DATETIME(1,1,1) AS CommissioningDateTA,
		|	ISNULL(InitialFixedAssetsInformation.CommissioningDateMA, DATETIME(1,1,1)) AS CommissioningDateMA,
		|
		|	ISNULL(InitialFixedAssetsInformation.CommissioningDocumentAC, UNDEFINED) AS CommissioningDocumentAC,
		|	UNDEFINED AS CommissioningDocumentTA,
		|	ISNULL(InitialFixedAssetsInformation.CommissioningDocumentMA, UNDEFINED) AS CommissioningDocumentMA,
		|
		|	ISNULL(InitialFixedAssetsInformation.DeregistrationDocumentACC, UNDEFINED) AS DeregistrationDocumentACC,
		|	UNDEFINED AS DeregistrationDocumentTA,
		|	ISNULL(InitialFixedAssetsInformation.DeregistrationDocumentMA, UNDEFINED) AS DeregistrationDocumentMA,
		|
		|	CASE
		|		WHEN InitialFixedAssetsInformation.DeregistrationDocumentACC REFS Document.DisposeFixedAssets2_4
		|				AND ISNULL(CAST(InitialFixedAssetsInformation.DeregistrationDocumentACC AS Document.DisposeFixedAssets2_4).AdjustmentModeFromPreviousDate, FALSE)
		|			THEN CAST(InitialFixedAssetsInformation.DeregistrationDocumentACC AS Document.DisposeFixedAssets2_4).DateOfDeduction
		|		ELSE ISNULL(InitialFixedAssetsInformation.DeregistrationDocumentACC.Date, DATETIME(1, 1, 1))
		|	END AS DateOfDeRegistrationOfBU,
		|
		|	DATETIME(1, 1, 1) AS DateOfDeRegistrationWELL,
		|
		|	CASE
		|		WHEN InitialFixedAssetsInformation.DeregistrationDocumentMA REFS Document.DisposeFixedAssets2_4
		|				AND ISNULL(CAST(InitialFixedAssetsInformation.DeregistrationDocumentMA AS Document.DisposeFixedAssets2_4).AdjustmentModeFromPreviousDate, FALSE)
		|			THEN CAST(InitialFixedAssetsInformation.DeregistrationDocumentMA AS Document.DisposeFixedAssets2_4).DateOfDeduction
		|		ELSE ISNULL(InitialFixedAssetsInformation.DeregistrationDocumentMA.Date, DATETIME(1, 1, 1))
		|	END AS DateMaWasDeRegistered,
		|
		|	ISNULL(FixedAssetsAccountingProcedure.FinancialAccountingGroup, UNDEFINED) AS FinancialAccountingGroup,
		|	ISNULL(FixedAssetsAccountingProcedure.FinancialAccountingGroup.Presentation, """") AS FinancialAccountingGroupPresentation,
		|
		|	CASE 
		|		WHEN &FilterByCompany 
		|				AND FALocation.Leaseholder = &FilterOrganization
		|				AND NOT AccountingProcedureForOSBU.FixedAsset IS NULL
		|			THEN VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
		|		ELSE ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_))
		|	END AS BUState,
		|
		|	VALUE(Enum.FixedAssetsStates.NotRecognized_) AS StateTa,
		|
		|	CASE 
		|		WHEN &FilterByCompany 
		|				AND FALocation.Leaseholder = &FilterOrganization
		|				AND NOT FixedAssetsAccountingProcedureManagementAccounting.FixedAsset IS NULL
		|			THEN VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
		|		ELSE ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_))
		|	END AS StateOfTheUU,
		|
		|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
		|	ISNULL(OSBUDepreciationParameters.ResidualValueMan, 0) AS ResidualValueLocal,
		|
		|	ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0) AS UsefulLifeAccounting,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths, 0) AS UsefulLifeManagementAccounting,
		|	ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0) AS UsefulLifeTaxAccounting,
		|
		|	FALocation.Period AS LocationInformationPeriod,
		|	FALocation.Organization AS Organization,
		|	ISNULL(FALocation.Organization.Presentation, """") AS OrganizationPresentation,
		|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson,
		|	ISNULL(FALocation.FinanciallyLiablePerson.Presentation, """") AS FinanciallyLiablePersonPresentation,
		|	FALocation.FixedAssetsLocation AS Department,
		|	ISNULL(FALocation.FixedAssetsLocation.Presentation, """") AS DepartmentPresentation,
		|	FALocation.LocationAddress AS LocationAddress,
		|	FALocation.FixedAsset.OSType AS OSType,
		|	UNDEFINED AS KindOfAccountingObject,
		|	FALSE AS ReceivedOnLeaseFromAnotherOrganization,
		|	NOT LeasedAsset.FixedAsset IS NULL AS ReceivedForRent,
		|	NOT AssetsLeasedOut.FixedAsset IS NULL AS Leased_,
		|	ISNULL(LeasedAsset.Partner, ISNULL(AssetsLeasedOut.Partner, UNDEFINED)) AS Partner,
		|	ISNULL(LeasedAsset.Partner.Presentation, ISNULL(AssetsLeasedOut.Partner.Presentation, """")) AS PartnerPresentation,
		|	ISNULL(LeasedAsset.Counterparty, ISNULL(AssetsLeasedOut.Counterparty, UNDEFINED)) AS Counterparty,
		|	ISNULL(LeasedAsset.Counterparty.Presentation, ISNULL(AssetsLeasedOut.Counterparty.Presentation, """")) AS CounterpartyPresentation,
		|	ISNULL(LeasedAsset.Contract, ISNULL(AssetsLeasedOut.Contract, UNDEFINED)) AS Contract,
		|	ISNULL(LeasedAsset.Contract.Presentation, ISNULL(AssetsLeasedOut.Contract.Presentation, """")) AS ContractPresentation
		|
		|FROM
		|	InformationRegister.FALocation.SliceLast(
		|			&Date, 
		|			CorrectionDate = DATETIME(1,1,1)
		|				AND Recorder <> &Recorder
		|				AND FixedAsset IN (&FixedAsset)) AS FALocation
		|
		|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
		|				&Date,  
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND Recorder <> &Recorder
		|					AND FixedAsset IN (&FixedAsset)) AS InitialFixedAssetsInformation
		|		ON (InitialFixedAssetsInformation.FixedAsset = FALocation.FixedAsset)
		|			AND (InitialFixedAssetsInformation.Organization = FALocation.Organization)
		|
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|				&Date, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND Recorder <> &Recorder
		|					AND FixedAsset IN (&FixedAsset)) AS FixedAssetsAccountingProcedure
		|		ON (FixedAssetsAccountingProcedure.FixedAsset = FALocation.FixedAsset)
		|
		|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|				&Date, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND Recorder <> &Recorder
		|					AND FixedAsset IN (&FixedAsset)) AS AccountingProcedureForOSBU
		|		ON (AccountingProcedureForOSBU.FixedAsset = FALocation.FixedAsset)
		|			AND (AccountingProcedureForOSBU.Organization = FALocation.Organization)
		|
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Date, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND Recorder <> &Recorder
		|					AND FixedAsset IN (&FixedAsset)) AS FixedAssetsAccountingProcedureManagementAccounting
		|		ON (FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FALocation.FixedAsset)
		|			AND (FixedAssetsAccountingProcedureManagementAccounting.Organization = FALocation.Organization)
		|
		|		LEFT JOIN InformationRegister.OSBUDepreciationParameters.SliceLast(
		|				&Date, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND Recorder <> &Recorder
		|					AND FixedAsset IN (&FixedAsset)) AS OSBUDepreciationParameters
		|		ON (OSBUDepreciationParameters.FixedAsset = FALocation.FixedAsset)
		|			AND (OSBUDepreciationParameters.Organization = FALocation.Organization)
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
		|				&Date, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND Recorder <> &Recorder
		|					AND FixedAsset IN (&FixedAsset)) AS FixedAssetDepreciationParametersManagementAccounting
		|		ON (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FALocation.FixedAsset)
		|			AND (FixedAssetDepreciationParametersManagementAccounting.Organization = FALocation.Organization)
		|
		|		LEFT JOIN InformationRegister.AssetsLeasedOut.SliceLast(
		|				&Date, 
		|				Recorder <> &Recorder
		|					AND FixedAsset IN (&FixedAsset)) AS AssetsLeasedOut
		|		ON (AssetsLeasedOut.FixedAsset = FALocation.FixedAsset)
		|			AND (AssetsLeasedOut.Organization = FALocation.Organization)
		|
		|		LEFT JOIN InformationRegister.LeasedAsset.SliceLast(
		|				&Date, 
		|				Recorder <> &Recorder
		|					AND FixedAsset IN (&FixedAsset)) AS LeasedAsset
		|		ON (LeasedAsset.FixedAsset = FALocation.FixedAsset)
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("FixedAsset", ?(TypeOf(FixedAsset) = Type("Array"), FixedAsset, CommonClientServer.ValueInArray(FixedAsset)));
		Query.SetParameter("FilterOrganization", FilterOrganization);
		Query.SetParameter("FilterByCompany", ValueIsFilled(FilterOrganization));
		Query.SetParameter("Date", Date);
		Query.SetParameter("Recorder", Recorder);
		
		Result = Query.Execute();
		
		If Result.IsEmpty() Then
			Return Undefined;
		EndIf;
		
		AccountingInformationTemplate = New Structure();
		For Each QueryColumn In Result.Columns Do
			AccountingInformationTemplate.Insert(QueryColumn.Name);
		EndDo; 
		AccountingInformationTemplate = New FixedStructure(AccountingInformationTemplate);
		
		Selection = Result.Select();
		
		If TypeOf(FixedAsset) = Type("Array") Then
			
			InformationAboutAccounting = New Map();
			While Selection.Next() Do
				
				FAAccountingInformation = New Structure(AccountingInformationTemplate);
				FillPropertyValues(FAAccountingInformation, Selection);
				InformationAboutAccounting.Insert(Selection.FixedAsset, FAAccountingInformation);
				
			EndDo;
			
		Else
			
			InformationAboutAccounting = New Structure(AccountingInformationTemplate);
			Selection.Next();
			FillPropertyValues(InformationAboutAccounting, Selection);
			
		EndIf;
		
	EndIf; 
	
	Return InformationAboutAccounting;

EndFunction

// Returns information about the main tool.
//
// Parameters:
//  PrimaryFacilityOrList - Array, CatalogRef.Assets - The main tool for which you need to get information.
//  Period - Date - On what date you need to get information.
// 
// Returns:
//  Map, Structure - Contains information about the main tool.
//
Function InitialInformation(PrimaryFacilityOrList, Period = '000101010000') Export
	
	InitialInformation = AssetsLocalization.InitialInformation(PrimaryFacilityOrList, Period);
	
	If InitialInformation <> Undefined Then
		Return InitialInformation;
	EndIf; 
		
	InitialInformation = New Structure;
	InitialInformation.Insert("Organization", Undefined);
	InitialInformation.Insert("FixedAssetsLocation", Undefined);
	InitialInformation.Insert("FINANCIALLYLIABLEPERSON", Undefined);
	InitialInformation.Insert("LineOfBusiness", Undefined);
	InitialInformation.Insert("CommissioningDateAC", '000101010000');
	InitialInformation.Insert("CommissioningDateTA", '000101010000');
	InitialInformation.Insert("CommissioningDateMA", '000101010000');
	InitialInformation.Insert("CommissioningDocumentAC", Undefined);
	InitialInformation.Insert("CommissioningDocumentTA", Undefined);
	InitialInformation.Insert("CommissioningDocumentMA", Undefined);
	InitialInformation.Insert("BUState", Enums.FixedAssetsStates.NotRecognized_);
	InitialInformation.Insert("StateTa", Enums.FixedAssetsStates.NotRecognized_);
	InitialInformation.Insert("StateOfTheUU", Enums.FixedAssetsStates.NotRecognized_);
	InitialInformation.Insert("InitialCostLocalAccounting", 0);
	InitialInformation.Insert("InitialCostTA", 0);
	InitialInformation.Insert("InitialCostMA", 0);
	InitialInformation.Insert("ResidualValueMan", 0);
	InitialInformation.Insert("ResidualValueLocal", 0);
	InitialInformation.Insert("ApplicationOfTargetFinancing", False);
	
	If Not ValueIsFilled(PrimaryFacilityOrList)
		Or Not AccessRight("Read", Metadata.InformationRegisters.FALocation)
		Or Not AccessRight("Read", Metadata.InformationRegisters.InitialFixedAssetsInformation)
		Or Not AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting) Then
		
		Return ?(TypeOf(PrimaryFacilityOrList) = Type("Array"), New Map, InitialInformation);
	EndIf; 
	
	QueryText = 
	"SELECT ALLOWED
	|	FALocation.FixedAsset AS FixedAsset,
	|	FALocation.Organization AS Organization,
	|	FALocation.FixedAssetsLocation AS FixedAssetsLocation,
	|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson,
	|	FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness,
	|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
	|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
	|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
	|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
	|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	InitialFixedAssetsInformation.InitialCostTA AS InitialCostTA,
	|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
	|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) AS StateOfTheUU,
	|	ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) AS BUState,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
	|	ISNULL(OSBUDepreciationParameters.ResidualValueMan, 0) AS ResidualValueLocal
	|FROM
	|	InformationRegister.FALocation.SliceLast(&Period, CorrectionDate = DATETIME(1,1,1) AND FixedAsset IN (&ListOfFA)) AS FALocation
	|
	|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|				&Period, 
	|				CorrectionDate = DATETIME(1,1,1) 
	|					AND FixedAsset IN (&ListOfFA)) AS InitialFixedAssetsInformation
	|		ON FALocation.FixedAsset = InitialFixedAssetsInformation.FixedAsset
	|			AND FALocation.Organization = InitialFixedAssetsInformation.Organization
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|				&Period, 
	|				CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedure
	|		ON FALocation.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset
	|
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|				&Period,
	|				CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureForOSBU
	|		ON FALocation.FixedAsset = AccountingProcedureForOSBU.FixedAsset
	|			AND FALocation.Organization = AccountingProcedureForOSBU.Organization
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|				&Period, 
	|				CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FALocation.FixedAsset = FixedAssetsAccountingProcedureManagementAccounting.FixedAsset
	|			AND FALocation.Organization = FixedAssetsAccountingProcedureManagementAccounting.Organization
	|
	|		LEFT JOIN InformationRegister.OSBUDepreciationParameters.SliceLast(
	|				&Period, 
	|				CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN (&ListOfFA)) AS OSBUDepreciationParameters
	|		ON FALocation.FixedAsset = OSBUDepreciationParameters.FixedAsset
	|			AND FALocation.Organization = OSBUDepreciationParameters.Organization
	|
	|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
	|				&Period, 
	|				CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FALocation.FixedAsset = FixedAssetDepreciationParametersManagementAccounting.FixedAsset
	|			AND FALocation.Organization = FixedAssetDepreciationParametersManagementAccounting.Organization
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", Period);
	
	ListOfFA = ?(TypeOf(PrimaryFacilityOrList) = Type("Array"), PrimaryFacilityOrList, CommonClientServer.ValueInArray(PrimaryFacilityOrList));
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return ?(TypeOf(PrimaryFacilityOrList) = Type("Array"), New Map, InitialInformation);
	EndIf;
	
	Selection = Result.Select();
	
	If TypeOf(PrimaryFacilityOrList) = Type("Array") Then
		Result = New Map;
		While Selection.Next() Do
			InitialFixedAssetsInformation = Common.CopyRecursive(InitialInformation);
			FillPropertyValues(InitialFixedAssetsInformation, Selection);
			Result.Insert(Selection.FixedAsset, InitialFixedAssetsInformation);
		EndDo;
	Else
		Result = InitialInformation;
		Selection.Next();
		FillPropertyValues(Result, Selection);
	EndIf; 
	
	Return Result;

EndFunction

// Returns names of blocked details for the BSP details blocking mechanism
//
// Returns:
// 		Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("OSGroup");
	Result.Add("CodeByUFADR");
	Result.Add("CodeByRNCFA");
	Result.Add("FixedAssetsGroupFinancialAccounting");
	
	AttributeDetails = ObjectAttributesLock.NewAttributeToLock();
	AttributeDetails.Name = "OSType";
	AttributeDetails.FormItems.Add("OSType");
	Result.Add(AttributeDetails);

	Return Result;
	
EndFunction

// Returns the operating time indicator for the operational object.
//
// Parameters:
//  Asset	 - CatalogRef.Assets	 - Object of operation.
//  Date				 - Date									 - date.
// 
// Returns:
//  CatalogRef.RunningTimeValues - Indicator of operating time of the object of operation.
//
Function RunningTimeValue(Asset, Date) Export

	QueryText = AssetsLocalization.QueryTextRunningTimeValue();
	
	If QueryText = Undefined Then
		QueryText = 
		"SELECT
		|	FixedAssetsAccountingProcedure.RunningTimeValue AS RunningTimeValue
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|		&Date, 
		|		CorrectionDate = DATETIME(1,1,1)
		|			AND FixedAsset = &Object) AS FixedAssetsAccountingProcedure"
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Object", Asset);
	Query.SetParameter("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Date));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Result.IsEmpty() Then
		Return Catalogs.RunningTimeValues.EmptyRef();
	EndIf;
		
	Selection = Result.Select();
	Selection.Next();
		
	Return Selection.RunningTimeValue;

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns object details that can be edited
// by processing group changes to details.
//
// Returns:
//  Array - a list of the names of the object's details.
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	
	If GetFunctionalOption("UseRMManagement") Then
		AttributesToEdit.Add("DateOfProduction");
		AttributesToEdit.Add("Manufacturer_");
		AttributesToEdit.Add("Model");
		AttributesToEdit.Add("RMBusinessUnit");
		AttributesToEdit.Add("OperatingBusinessUnit");
		AttributesToEdit.Add("ExpenseItem");
	EndIf;
	
	Return AttributesToEdit;

EndFunction

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	ProcessSucceeded = NonCurrentAssetsServerCall.FormReceiptProcessing_ObjectsOfOperation(
							FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
	If FormType = "ChoiceForm" And Not ProcessSucceeded Then
		
		SelectedForm = "ChoiceForm2_4";
		StandardProcessing = False;

	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ChoiceData = NonCurrentAssetsServerCall.DataSelectionOfObjectsOfOperation(Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns parameters for selecting fixed assets based on the passed parameters and rights settings.
// 
// Parameters:
//  Parameters - Structure - Parameters
//  RightsSettings - Structure - Rights settings
// 
// Returns:
//  Structure - The selection parameters
//
Function GetChoiceParameters(Parameters, RightsSettings) Export
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Filter", New Structure);
	
	// Various parameters
		
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "DateOfLastEdit");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "CurrentRegistrar");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "RecordInLocalAccounting");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "RecordInManAccounting");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "PostInAccounting");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "RecordInTA");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "AttributesThatShouldMatch");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "OwnerOfFAComponentNode");
	

	If Parameters.Property("Context") Then
		ChoiceParameters.Insert("Context", New Structure(Parameters.Context));
	Else
		ChoiceParameters.Insert("Context", New Structure("MA,ACC"));
	EndIf;

	// Filters

	ListFilter = CommonClientServer.StructureProperty(Parameters, "Filter", New Structure); // Structure
	
	ItemsToDelete1 = New Array;
	For Each FilterDetails In ListFilter Do
		
		FilterName = Upper(FilterDetails.Key);
		
		If Not ValueIsFilled(ListFilter[FilterName])
			
			
			Or Not RightsSettings.ThereIsRightToRead_LocationOfFA
				And (FilterName = Upper("Organization")
					Or FilterName = Upper("FINANCIALLYLIABLEPERSON")
					Or FilterName = Upper("Department")
					Or FilterName = Upper("LocationAddress")
					Or FilterName = Upper("Leaseholder"))
			
			Or Not RightsSettings.ThereIsRightToRead_InitialFAInformation
				And (FilterName = Upper("DateOfRegistrationOfTheRegl")
					Or FilterName = Upper("DateOfRegistrationOfTheUpr")
					Or FilterName = Upper("Lessor"))
			
			Or Not RightsSettings.ThereIsRightToRead_FAAccountingProcedure
				And (FilterName = Upper("FinancialAccountingGroup")
					Or FilterName = Upper("LineOfBusiness"))
		
			Or Not RightsSettings.ThereIsRightToRead_RentedFA
				And FilterName = Upper("Contract")
				
			Or Not RightsSettings.ThereIsRightToRead_OSUUDepreciationParameters
				And FilterName = Upper("UsefulLifeManagementAccounting")
					
			Or Not RightsSettings.ThereIsRightToRead_OSBUDepreciationParameters
				And (FilterName = Upper("UsefulLifeAccounting")
					Or FilterName = Upper("UsefulLifeTaxAccounting"))
		
			Or Not RightsSettings.ThereIsRightToRead_OrderOfAccountingOfOSU
				And FilterName = Upper("StateOfTheUU")
		
			Or Not RightsSettings.ThereIsRightToRead_OSBUAccountingProcedure
				And (FilterName = Upper("BUState")
					Or FilterName = Upper("VATTaxation")
					Or FilterName = Upper("RealEstate")
					Or FilterName = Upper("DepreciationGroup")) Then
		
			// Deleting selections with an empty value and selections based on inaccessible information
			ItemsToDelete1.Add(FilterName);
			
			Continue;
			
		EndIf; 
		
		If FilterName = Upper("State")
			Or FilterName = Upper("DepreciationGroup")
			Or FilterName = Upper("OSGroup") Then
			
			FilterValue = NonCurrentAssetsInternal.ValueToArray(FilterDetails.Value);
	
			ChoiceParameters.Filter.Insert(FilterName, FilterValue);
			
		Else
				
			NonCurrentAssetsClientServer.CopyStructureProperty(ListFilter, ChoiceParameters.Filter, FilterName);

		EndIf; 
		
	EndDo;
		
	For Each FilterName In ItemsToDelete1 Do
		Parameters.Filter.Delete(FilterName);
	EndDo;
	
	ExcludeComponents = False;
	If ListFilter.Property("Owner")
		And TypeOf(ListFilter.Owner) = Type("ChartOfCharacteristicTypesRef.ExpenseItems")
		And ChoiceParameters.Context.Property("ACC") Then
		ExcludeComponents = True; // Depreciation components are not allowed to be selected as expense analytics
	EndIf; 
	ChoiceParameters.Insert("ExcludeComponents", ExcludeComponents);

	Return ChoiceParameters;
	
EndFunction

// Generates a description of the request for selecting Catalog items.
// 
// Parameters:
//  ChoiceParameters - See GetChoiceParameters
//  RightsSettings - Structure - Rights settings
//  ConsiderInformation - Boolean - True if you need to take into account the selection based on information from the registers (Organization, PIER, etc.)
//	SetFilters - Boolean - True if you want to generate a selection text for all selections of the selection parameters
// 
// Returns:
//  Structure - Request parameters to select:
// 		* TextSelections - String - 
// 		* RequiredTables - Structure - 
// 		* QueryFields - Structure - 
// 		* QueryOptions - Structure -
//
Function DescriptionOfItemSelectionRequest(ChoiceParameters, RightsSettings, ConsiderInformation, SetFilters = False) Export

	QueryDetails = New Structure;
	QueryDetails.Insert("TextSelections", "");
	QueryDetails.Insert("RequiredTables", New Structure);
	QueryDetails.Insert("QueryOptions", New Structure);
	
	QueryDetails.Insert("QueryFields", New Structure);
	QueryDetails.QueryFields.Insert("Organization", "VALUE(Catalog.Companies.EmptyRef)");
	QueryDetails.QueryFields.Insert("Department", "VALUE(Catalog.BusinessStructure.EmptyRef)");
	QueryDetails.QueryFields.Insert("MateriallyResponsiblePerson", "VALUE(Catalog.Persons.EmptyRef)");
	QueryDetails.QueryFields.Insert("LocationAddress", """""");
	QueryDetails.QueryFields.Insert("LineOfBusiness", "VALUE(Catalog.LinesOfBusiness.EmptyRef)");
	QueryDetails.QueryFields.Insert("RealEstate", "FALSE");
	QueryDetails.QueryFields.Insert("BUState", "VALUE(Enum.FixedAssetsStates.EmptyRef)");
	QueryDetails.QueryFields.Insert("StateOfTheUU", "VALUE(Enum.FixedAssetsStates.EmptyRef)");
	QueryDetails.QueryFields.Insert("FinancialAccountingGroup", "VALUE(Catalog.NonCurrentAssetsAccountingGroups.EmptyRef)");
	QueryDetails.QueryFields.Insert("UsefulLifeManagementAccounting", "0");
	QueryDetails.QueryFields.Insert("UsefulLifeAccounting", "0");
	QueryDetails.QueryFields.Insert("UsefulLifeTaxAccounting", "0");
	QueryDetails.QueryFields.Insert("ResidualLifetimeMA", "0");
	QueryDetails.QueryFields.Insert("ResidualLifetimeAC", "0");
	QueryDetails.QueryFields.Insert("ResidualLifetimeTA", "0");
	QueryDetails.QueryFields.Insert("VATTaxation", "VALUE(Enum.VATTaxationTypes.EmptyRef)");
	QueryDetails.QueryFields.Insert("DateOfRegistrationOfTheRegl", "DATETIME(1,1,1)");
	QueryDetails.QueryFields.Insert("DateOfRegistrationOfTheUpr", "DATETIME(1,1,1)");
	QueryDetails.QueryFields.Insert("Lessor", "VALUE(Catalog.Counterparties.EmptyRef)");
	QueryDetails.QueryFields.Insert("Leaseholder", "VALUE(Catalog.Counterparties.EmptyRef)");
	QueryDetails.QueryFields.Insert("Contract", "UNDEFINED");

	QueryDetails.QueryFields.Insert("DepreciationGroup", """""");
	
	AvailableContexts = ChoiceParameters.Context; // Structure
	ListFilter = Common.CopyRecursive(ChoiceParameters.Filter); // Structure

	If ChoiceParameters.Property("DateOfLastEdit") Then
		DateOfLastEdit = EndOfDay(ChoiceParameters.DateOfLastEdit);
	Else
		DateOfLastEdit = '00010101';
	EndIf;
	
	#Region QueryFields
	
	If RightsSettings.ThereIsRightToRead_LocationOfFA
		And (AvailableContexts.Property("ACC") Or AvailableContexts.Property("MA"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.Organization = "ISNULL(FALocation.Organization, VALUE(Catalog.Companies.EmptyRef))";
		QueryDetails.QueryFields.MateriallyResponsiblePerson = "ISNULL(FALocation.FinanciallyLiablePerson, VALUE(Catalog.Persons.EmptyRef))";
		QueryDetails.QueryFields.Department = "ISNULL(FALocation.FixedAssetsLocation, VALUE(Catalog.BusinessStructure.EmptyRef))";
		QueryDetails.QueryFields.LocationAddress = "ISNULL(FALocation.LocationAddress, """""""")";
		QueryDetails.QueryFields.Leaseholder = "ISNULL(FALocation.Leaseholder, UNDEFINED)";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("FALocation");
		EndIf;

	EndIf;
	
	If RightsSettings.ThereIsRightToRead_InitialFAInformation
		And (AvailableContexts.Property("ACC") Or AvailableContexts.Property("MA"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.Lessor = "ISNULL(InitialFixedAssetsInformation.Counterparty, VALUE(Catalog.Counterparties.EmptyRef))";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("InitialFixedAssetsInformation");
		EndIf;
		
	EndIf;
	
	If RightsSettings.ThereIsRightToRead_FAAccountingProcedure
		And (AvailableContexts.Property("ACC") Or AvailableContexts.Property("MA"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.FinancialAccountingGroup = 
			"ISNULL(FixedAssetsAccountingProcedure.FinancialAccountingGroup, VALUE(Catalog.NonCurrentAssetsAccountingGroups.EmptyRef))";
			
		QueryDetails.QueryFields.LineOfBusiness = 
			"ISNULL(FixedAssetsAccountingProcedure.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedure");
		EndIf;

	EndIf;
	
	If RightsSettings.ThereIsRightToRead_InitialFAInformation
		And RightsSettings.ThereIsRightToRead_LocationOfFA
		And (AvailableContexts.Property("ACC") Or AvailableContexts.Property("MA"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.DateOfRegistrationOfTheRegl = 
			"CASE 
			|	WHEN ISNULL(InitialFixedAssetsInformation.CommissioningDateAC, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
			|			AND (ISNULL(InitialFixedAssetsInformation.CommissioningDateAC, DATETIME(1, 1, 1)) <= ISNULL(InitialFixedAssetsInformation.CommissioningDateTA, DATETIME(1, 1, 1))
			|				OR ISNULL(InitialFixedAssetsInformation.CommissioningDateTA, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1))
			|		THEN ISNULL(InitialFixedAssetsInformation.CommissioningDateAC, DATETIME(1, 1, 1))
			|	ELSE ISNULL(InitialFixedAssetsInformation.CommissioningDateTA, DATETIME(1, 1, 1))
			|END";
			
		QueryDetails.QueryFields.DateOfRegistrationOfTheUpr =
			"ISNULL(InitialFixedAssetsInformation.CommissioningDateMA, DATETIME(1, 1, 1))";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("InitialFixedAssetsInformation");
		EndIf;
		
	EndIf;

	If RightsSettings.ThereIsRightToRead_RentedFA
		And ChoiceParameters.Property("Contract")
		And ValueIsFilled(ChoiceParameters.Contract)
		And (AvailableContexts.Property("ACC") Or AvailableContexts.Property("MA"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.Contract = "ISNULL(LeasedAsset.Contract, UNDEFINED)";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("LeasedAsset");
		EndIf;
		
	EndIf;

	If RightsSettings.ThereIsRightToRead_OSUUDepreciationParameters
		And (ChoiceParameters.Property("AttributesThatShouldMatch")
				And StrFind(ChoiceParameters.AttributesThatShouldMatch, "UsefulLifeManagementAccounting") <> 0 
			Or ChoiceParameters.Filter.Property("UsefulLifeManagementAccounting"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.UsefulLifeManagementAccounting = "ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths, 0)";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("FixedAssetDepreciationParametersManagementAccounting");
		EndIf;
		
	EndIf;
	
	If RightsSettings.ThereIsRightToRead_OSBUDepreciationParameters
		And (ChoiceParameters.Property("AttributesThatShouldMatch")
				And StrFind(ChoiceParameters.AttributesThatShouldMatch, "UsefulLifeAccounting") <> 0 
			Or ListFilter.Property("UsefulLifeAccounting"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.UsefulLifeAccounting = "ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0)";
		QueryDetails.QueryFields.UsefulLifeTaxAccounting = "ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsTA, 0)";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("OSBUDepreciationParameters");
		EndIf;
		
	EndIf;
	
	If RightsSettings.ThereIsRightToRead_OSUUDepreciationParameters
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.ResidualLifetimeMA = 
			"CASE 
			|	WHEN InitialFixedAssetsInformation.CommissioningDateMA IS NULL
			|		THEN 0
			|	WHEN FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths - DATEDIFF(InitialFixedAssetsInformation.CommissioningDateMA, BEGINOFPERIOD(&DateOfLastEdit, DAY), MONTH) < 0
			|		THEN 0
			|	ELSE FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths - DATEDIFF(InitialFixedAssetsInformation.CommissioningDateMA, BEGINOFPERIOD(&DateOfLastEdit, DAY), MONTH)
			|END";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("InitialFixedAssetsInformation");
			QueryDetails.RequiredTables.Insert("FixedAssetDepreciationParametersManagementAccounting");
		EndIf;
		
		QueryDetails.QueryOptions.Insert("DateOfLastEdit", DateOfLastEdit);
		
	EndIf;
	
	If RightsSettings.ThereIsRightToRead_OSBUDepreciationParameters
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.ResidualLifetimeAC = 
			"CASE 
			|	WHEN InitialFixedAssetsInformation.CommissioningDateAC IS NULL
			|		THEN 0
			|	WHEN OSBUDepreciationParameters.UsefulLifeMonthsAC - DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(&DateOfLastEdit, DAY), MONTH) < 0
			|		THEN 0
			|	ELSE OSBUDepreciationParameters.UsefulLifeMonthsAC - DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(&DateOfLastEdit, DAY), MONTH)
			|END";
		
		QueryDetails.QueryFields.ResidualLifetimeTA = 
			"CASE 
			|	WHEN InitialFixedAssetsInformation.CommissioningDateTA IS NULL
			|		THEN 0
			|	WHEN OSBUDepreciationParameters.UsefulLifeMonthsTA - DATEDIFF(InitialFixedAssetsInformation.CommissioningDateTA, BEGINOFPERIOD(&DateOfLastEdit, DAY), MONTH) < 0
			|		THEN 0
			|	ELSE OSBUDepreciationParameters.UsefulLifeMonthsTA - DATEDIFF(InitialFixedAssetsInformation.CommissioningDateTA, BEGINOFPERIOD(&DateOfLastEdit, DAY), MONTH)
			|END";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("InitialFixedAssetsInformation");
			QueryDetails.RequiredTables.Insert("OSBUDepreciationParameters");
		EndIf;
		
		QueryDetails.QueryOptions.Insert("DateOfLastEdit", DateOfLastEdit);
		
	EndIf;
	
	If AvailableContexts.Property("ACC") 
		And RightsSettings.ThereIsRightToRead_OSBUAccountingProcedure
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.BUState =
			"CASE 
			|	WHEN CatalogDataOverridable.IsFolder 
			|		THEN VALUE(Enum.FixedAssetsStates.EmptyRef)
			|	WHEN AccountingProcedureForOSBU.BUState <> VALUE(Enum.FixedAssetsStates.EmptyRef)
			|		THEN AccountingProcedureForOSBU.BUState
			|	ELSE ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_))
			|END";
	
		QueryDetails.QueryFields.VATTaxation =		
			"ISNULL(AccountingProcedureForOSBU.VATTaxation, UNDEFINED)";
			
	
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
		EndIf;
		
	Else
		
		QueryDetails.QueryFields.BUState = 
			"CASE 
			|	WHEN NOT CatalogDataOverridable.IsFolder 
			|		THEN VALUE(Enum.FixedAssetsStates.NotRecognized_)
			|		ELSE VALUE(Enum.FixedAssetsStates.EmptyRef)
			|END";
			
	EndIf; 
	
	If AvailableContexts.Property("MA")
		And RightsSettings.ThereIsRightToRead_OrderOfAccountingOfOSU
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.StateOfTheUU =
			"CASE 
			|	WHEN NOT CatalogDataOverridable.IsFolder 
			|		THEN ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_))
			|		ELSE VALUE(Enum.FixedAssetsStates.EmptyRef)
			|END";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedureManagementAccounting");
		EndIf;
		
	Else
		
		QueryDetails.QueryFields.StateOfTheUU =
			"CASE 
			|	WHEN NOT CatalogDataOverridable.IsFolder 
			|		THEN VALUE(Enum.FixedAssetsStates.NotRecognized_)
			|		ELSE VALUE(Enum.FixedAssetsStates.EmptyRef)
			|END";
		
	EndIf;

	#EndRegion
	
	#Region FiltersCustom
		
	If RightsSettings.ThereIsRightToRead_OrderOfAccountingOfOSU 
		And RightsSettings.ThereIsRightToRead_OSBUAccountingProcedure
		And (ConsiderInformation Or SetFilters And ListFilter.Property("State")) Then
		
		ChoiceOfAccountingIsAvailable = 
			ChoiceParameters.Property("RecordInLocalAccounting") 
			Or ChoiceParameters.Property("RecordInManAccounting"); // In the document there is a choice in which accounting it is reflected
	
		If ChoiceOfAccountingIsAvailable Then

			RecordInManAccounting = False;
			PostInAccounting = False;
			RecordInTA = False;

			If ChoiceParameters.Property("RecordInManAccounting") Then
				RecordInManAccounting = ChoiceParameters.RecordInManAccounting;
			EndIf;
			
			If ChoiceParameters.Property("PostInAccounting") Then
				PostInAccounting = ChoiceParameters.PostInAccounting;
			ElsIf ChoiceParameters.Property("RecordInLocalAccounting") Then
				PostInAccounting = ChoiceParameters.RecordInLocalAccounting;
			EndIf;
			
			
			If RecordInManAccounting And PostInAccounting And RecordInTA And ChoiceParameters.Property("RecordInTA") Then
				
				ConditionText =
					"(ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|			AND ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|			AND ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
				QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedureManagementAccounting");
				QueryDetails.RequiredTables.Insert("FALocation");
				
			ElsIf RecordInManAccounting And PostInAccounting And RecordInTA And Not ChoiceParameters.Property("RecordInTA") Then
				
				ConditionText =
					"(ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|			AND (ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|				OR ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State))
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
				QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedureManagementAccounting");
				QueryDetails.RequiredTables.Insert("FALocation");
				
			ElsIf RecordInManAccounting And Not PostInAccounting And Not RecordInTA Then
				
				ConditionText =
					"(ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedureManagementAccounting");
				QueryDetails.RequiredTables.Insert("FALocation");
				
			ElsIf PostInAccounting And Not RecordInTA And Not RecordInManAccounting Then
				
				ConditionText =
					"(ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
				QueryDetails.RequiredTables.Insert("FALocation");
				
			ElsIf RecordInTA And ChoiceParameters.Property("RecordInTA") And Not PostInAccounting And Not RecordInManAccounting Then
				
				ConditionText =
					"(ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
				QueryDetails.RequiredTables.Insert("FALocation");
				
			ElsIf PostInAccounting And RecordInTA And ChoiceParameters.Property("RecordInTA") And Not RecordInManAccounting Then
				
				ConditionText =
					"(ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|			AND ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
				QueryDetails.RequiredTables.Insert("FALocation");
				
			ElsIf PostInAccounting And RecordInTA And Not ChoiceParameters.Property("RecordInTA") And Not RecordInManAccounting Then
				
				ConditionText =
					"(ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
				QueryDetails.RequiredTables.Insert("FALocation");
				
			Else
				
				ConditionText = 
					"(ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				
				QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
				QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedureManagementAccounting");
				QueryDetails.RequiredTables.Insert("FALocation");
				
			EndIf;
							
		Else
			
			ConditionText = 
				"(ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
				|		OR ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN(&State)
				|		OR &DoNotUseStateSelection)"; // @query-part-1
			
			
			QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
			QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedureManagementAccounting");
			QueryDetails.RequiredTables.Insert("FALocation");

		EndIf; 
		
		NonCurrentAssetsInternal.AddSelectionText(QueryDetails.TextSelections, ConditionText);
		
	EndIf; 
	
	
	If (ChoiceParameters.Property("RunningTimeRegistration")
			Or ChoiceParameters.Property("SettingTheOperatingTime")
			Or ChoiceParameters.Property("SourceOfTheOperatingTimeIndicator")) Then
		
		QueryDetails.RequiredTables.Insert("FixedAssetDepreciationParametersManagementAccounting");
		QueryDetails.RequiredTables.Insert("InitialFixedAssetsInformation");
		QueryDetails.RequiredTables.Insert("FALocation");

		ConditionText = "";
		If GetFunctionalOption("UseRMManagement") Then
			
			QueryDetails.QueryOptions.Insert(
				"RunningTimeRegistration",
				?(ChoiceParameters.Property("RunningTimeRegistration"), ChoiceParameters.RunningTimeRegistration, False));
	
			QueryDetails.QueryOptions.Insert(
				"SettingTheOperatingTime",
				?(ChoiceParameters.Property("SettingTheOperatingTime"), ChoiceParameters.SettingTheOperatingTime, False));
	
			QueryDetails.QueryOptions.Insert(
				"SourceOfTheOperatingTimeIndicator",
				?(ChoiceParameters.Property("SourceOfTheOperatingTimeIndicator"), ChoiceParameters.SourceOfTheOperatingTimeIndicator, False));
	
			QueryDetails.QueryOptions.Insert(
				"RunningTimeValue",
				?(ChoiceParameters.Property("RunningTimeValue"), ChoiceParameters.RunningTimeValue, Undefined));

			ConditionText = 
			"CatalogDataOverridable.Class IN
			|	(SELECT
			|		ClassMetricParameters.Ref
			|	FROM
			|		Catalog.MaintenanceSchemes.RunningTimeValues AS ClassMetricParameters
			|	WHERE
			|		NOT ClassMetricParameters.Ref.DeletionMark
			|		AND CASE
			|			WHEN &RunningTimeRegistration
			|				THEN NOT ClassMetricParameters.RegisterBySource
			|			WHEN &SettingTheOperatingTime
			|				THEN TRUE
			|			WHEN &SourceOfTheOperatingTimeIndicator
			|				THEN ClassMetricParameters.RunningTimeValue = &RunningTimeValue
			|			ELSE TRUE
			|		END)
			|"; // @query-part-1
			
		Else
			
			ConditionText = 
			"(ISNULL(FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod, UNDEFINED) = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
			|	OR ISNULL(InitialFixedAssetsInformation.DepreciationMethodAccounting, UNDEFINED) = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction))"; // @query-part-1
			
		EndIf;
			
		NonCurrentAssetsInternal.AddSelectionText(QueryDetails.TextSelections, ConditionText);
		
	EndIf;
	If ChoiceParameters.Property("AccountAsGroupFA")
		And ChoiceParameters.AccountAsGroupFA Then
		
		ConditionText = 
			"CatalogDataOverridable.OSType = VALUE(Enum.FATypes.GroupFA)"; // @query-part-1
		NonCurrentAssetsInternal.AddSelectionText(QueryDetails.TextSelections, ConditionText);
			
	EndIf;
	
	If ChoiceParameters.ExcludeComponents Then
		
		ConditionText = 
			"(NOT CatalogDataOverridable.OSType = VALUE(Enum.FATypes.DepreciationComponent)
			|	OR CatalogDataOverridable.ConsiderResidualLiabilityValue)"; // @query-part-1
			
		NonCurrentAssetsInternal.AddSelectionText(QueryDetails.TextSelections, ConditionText);
			
	EndIf;
	
	If ChoiceParameters.Property("OwnerOfFAComponentNode") Then
		
		SubAssetsOfDepreciationComponentsByOwner = GetNodesOfDepreciationComponentsByOwner(ChoiceParameters.OwnerOfFAComponentNode, DateOfLastEdit);
		
		ConditionText = 
			"CatalogDataOverridable.Ref IN (&SubAssetsOfDepreciationComponentsByOwner)"; // @query-part-1
		
		NonCurrentAssetsInternal.AddSelectionText(QueryDetails.TextSelections, ConditionText);
		
		QueryDetails.QueryOptions.Insert("SubAssetsOfDepreciationComponentsByOwner", SubAssetsOfDepreciationComponentsByOwner);
		
	EndIf;
	
	
	#EndRegion
	
	#Region SelectionsByAttributes
	
	If SetFilters Then
		
		For Each KeyAndValue In ListFilter Do
			
			FilterName = Upper(KeyAndValue.Key);
			
			If ThisIsSelectionBasedOnInformation(FilterName)
				And QueryDetails.QueryFields.Property(FilterName)
				And FilterName <> Upper("State") Then
				
				PathToField = QueryDetails.QueryFields[KeyAndValue.Key];
				
				If FilterName = Upper("Organization")
					Or FilterName = Upper("Department")
					Or FilterName = Upper("FINANCIALLYLIABLEPERSON")
					Or FilterName = Upper("LocationAddress")
					Or FilterName = Upper("Leaseholder") Then
					
					QueryDetails.RequiredTables.Insert("FALocation");
				
				ElsIf FilterName = Upper("LineOfBusiness")
					Or FilterName = Upper("FinancialAccountingGroup") Then	
				
					QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedure");
					
				ElsIf FilterName = Upper("DepreciationGroup")
					Or FilterName = Upper("RealEstate")
					Or FilterName = Upper("BUState")
					Or FilterName = Upper("VATTaxation") Then
					
					QueryDetails.RequiredTables.Insert("AccountingProcedureForOSBU");
					
				ElsIf FilterName = Upper("StateOfTheUU") Then
					
					QueryDetails.RequiredTables.Insert("FixedAssetsAccountingProcedureManagementAccounting");
					
				ElsIf FilterName = Upper("UsefulLifeAccounting")
					Or FilterName = Upper("UsefulLifeTaxAccounting")
					Or FilterName = Upper("ResidualLifetimeAC")
					Or FilterName = Upper("ResidualLifetimeTA") Then
					
					QueryDetails.RequiredTables.Insert("OSBUDepreciationParameters");
					
				ElsIf FilterName = Upper("UsefulLifeManagementAccounting")
					Or FilterName = Upper("ResidualLifetimeMA") Then
					
					QueryDetails.RequiredTables.Insert("FixedAssetDepreciationParametersManagementAccounting");
					
				ElsIf FilterName = Upper("DateOfRegistrationOfTheRegl")
					Or FilterName = Upper("DateOfRegistrationOfTheUpr")
					Or FilterName = Upper("Lessor") Then
					
					QueryDetails.RequiredTables.Insert("InitialFixedAssetsInformation");
					
				ElsIf FilterName = Upper("Contract") Then
						
					QueryDetails.RequiredTables.Insert("LeasedAsset");
					
				EndIf;
				
			ElsIf FilterName = Upper("OSType")
				Or FilterName = Upper("OSGroup")
				Or FilterName = Upper("FixedAssetsGroupFinancialAccounting")
				Or FilterName = Upper("DateOfProduction")
				Or FilterName = Upper("DateOfLastEdit")
				Or FilterName = Upper("ManufaturerNumber")
				Or FilterName = Upper("RegisteredInPlatonSystemRegistry")
				Or FilterName = Upper("Manufacturer_")
				Or FilterName = Upper("Class")
				Or FilterName = Upper("Subclass")
				Or FilterName = Upper("CodeByRNCFA")
				Or FilterName = Upper("Model")
				Or FilterName = Upper("PassportNumber")
				Or FilterName = Upper("HouseholdObject")
				Or FilterName = Upper("OperatingBusinessUnit")
				Or FilterName = Upper("RMBusinessUnit")
				Or FilterName = Upper("SerialNumber")
				Or FilterName = Upper("PayrollExpensesPostingMethod")
				Or FilterName = Upper("Status")
				Or FilterName = Upper("ExpenseItem")
				Or FilterName = Upper("CodeByUFADR")
				Or FilterName = Upper("ConsiderResidualLiabilityValue") Then
				
				PathToField = "CatalogDataOverridable" + "." + KeyAndValue.Key;
			
			Else
				
				Continue;
				
			EndIf;
			
			ThisIsArray = 
				TypeOf(KeyAndValue.Value) = Type("FixedArray") 
				Or TypeOf(KeyAndValue.Value) = Type("Array");
						
			ConditionText = PathToField + ?(ThisIsArray, " IN " + "(&" + KeyAndValue.Key + ")", " = &" + KeyAndValue.Key); // @query-part-1
			NonCurrentAssetsInternal.AddSelectionText(QueryDetails.TextSelections, ConditionText);
			
			If ThisIsArray Then
				FilterValue = NonCurrentAssetsInternal.ValueToArray(KeyAndValue.Value);
			Else
				FilterValue = KeyAndValue.Value;
			EndIf;
			
			QueryDetails.QueryOptions.Insert(KeyAndValue.Key, FilterValue);
			
		EndDo; 
		
	EndIf;
	
	#EndRegion
	
	Return QueryDetails;
	
EndFunction

Function ThereAreRightsToReadInformation() Export

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4()
		Or Not AccessRight("Read", Metadata.InformationRegisters.FALocation)
		Or Not AccessRight("Read", Metadata.InformationRegisters.InitialFixedAssetsInformation)
		Or Not AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting)
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.FACost)
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge)
		Or Not AssetsLocalization.ThereAreRightsToReadInformation() Then
		Return False;
	EndIf;

	Return True;
	
EndFunction

Function PresentationOfAccountingInformation(InformationAboutAccounting, CostAndDepreciation, IncludeBlankFields = True) Export

	PresentationOfInformation = New Structure;

	InformationLiquidationValue = New Array;
	InformationLiquidationValueOfRegl = New Array;
	
	InformationReplacementCost = New Array;
	InformationAccumulatedDepreciation = New Array;
	InformationImpairment = New Array;
	InformationResidualValue = New Array;
	
	InformationLocationAddress = New Array;
	Period = '000101010000';
	
	If InformationAboutAccounting <> Undefined Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(InformationAboutAccounting.Organization);
	Else
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf; 

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
		
	ComplCurrencyPresentation = String(ComplCurrency);
	CurrencyOfManPresentation = String(CurrencyOfMan);
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	NonCurrentAssetsInternal.PresentationOfInformationOnDateOfAcceptanceForAccounting(InformationAboutAccounting, PresentationOfInformation);
	NonCurrentAssetsInternal.PresentationOfInformationAboutPeriodOfUse(InformationAboutAccounting, PresentationOfInformation);
	NonCurrentAssetsInternal.PresentationOfInformationAboutDateOfWriteOff(InformationAboutAccounting, PresentationOfInformation);
	NonCurrentAssetsInternal.PresentationOfInformationOnLiquidationCosts(InformationAboutAccounting, PresentationOfInformation);
				
	#Region GeneralInformation
	
	If InformationAboutAccounting <> Undefined Then
		
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"HFCInformation", 
			NStr("vi = 'Nhóm kế toán tài chính:';
				|ru = 'Группа финансового учета:';
				|en = 'Financial accounting group:'; fa = 'گروه حسابداری مالی:';
				|it = 'Gruppo di contabilità finanziaria:';
				|pl = 'Grupa ewidencji finansowej:';
				|tr = 'Finansal muhasebe grubu'"), 
			InformationAboutAccounting.FinancialAccountingGroup, 
			InformationAboutAccounting.FinancialAccountingGroupPresentation, 
			PresentationOfInformation);
		
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"PartnerInformation", 
			 ?(InformationAboutAccounting.ReceivedForRent, NStr("vi = 'Người cho thuê tài chính:';
																|ru = 'Арендодатель:';
																|en = 'Lessor:'; fa = 'Lessor:';
																|it = 'Locatore:';
																|pl = 'Wynajemca:';
																|tr = 'Mülk Sahibi:'"), NStr("vi = 'Người thuê:';
																						|ru = 'Арендатор:';
																						|en = 'Lessee:'; fa = 'Lessee:';
																						|it = 'Арендатор:';
																						|pl = 'Najemca:';
																						|tr = 'Kiralayan:'")), 
			InformationAboutAccounting.Partner, 
			InformationAboutAccounting.PartnerPresentation, 
			PresentationOfInformation);
			
		If Not ValueIsFilled(InformationAboutAccounting.Partner) Then
			LabelText = ?(InformationAboutAccounting.ReceivedForRent, NStr("vi = 'Người cho thuê tài chính:';
																			|ru = 'Арендодатель:';
																			|en = 'Lessor:'; fa = 'Lessor:';
																			|it = 'Locatore:';
																			|pl = 'Wynajemca:';
																			|tr = 'Kiraya veren:'"), NStr("vi = 'Người thuê:';
																									|ru = 'Арендатор:';
																									|en = 'Lessee:'; fa = 'Lessee:';
																									|it = 'Proprietario:';
																									|pl = 'Najemca:';
																									|tr = 'Kiralayan:'"));
		Else
			LabelText = NStr("vi = 'Đối tác:';
							|ru = 'Контрагент:';
							|en = 'Counterparty:'; fa = 'طرف حساب:';
							|it = 'Controparte:';
							|pl = 'Kontrahent:';
							|tr = 'Cari hesap:'");
		EndIf;
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"InformationCounterparty", 
			LabelText, 
			InformationAboutAccounting.Counterparty, 
			InformationAboutAccounting.CounterpartyPresentation, 
			PresentationOfInformation);
			
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"InformationContract", 
			NStr("vi = 'Hợp đồng:';
				|ru = 'Договор:';
				|en = 'Contract:'; fa = 'قرارداد:';
				|it = 'Contratto:';
				|pl = 'Umowa:';
				|tr = 'Sözleşme:'"), 
			InformationAboutAccounting.Contract, 
			InformationAboutAccounting.ContractPresentation, 
			PresentationOfInformation);
		 
	Else
			
		PresentationOfInformation.Insert("HFCInformation", Undefined);
		PresentationOfInformation.Insert("PartnerInformation", Undefined);
		PresentationOfInformation.Insert("InformationCounterparty", Undefined);
		PresentationOfInformation.Insert("InformationContract", Undefined);
		
	EndIf;
	
	#EndRegion
	
	#Region FixedAssetsLocation
	
	If InformationAboutAccounting <> Undefined Then
		
		Period = InformationAboutAccounting.LocationInformationPeriod; 

		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"InformationLocationCompany", 
			NStr("vi = 'Doanh nghiệp:';
				|ru = 'Организация:';
				|en = 'Company:'; fa = 'شرکت:';
				|it = 'Организация:';
				|pl = 'Firma:';
				|tr = 'İş yeri:'"), 
			InformationAboutAccounting.Organization, 
			InformationAboutAccounting.OrganizationPresentation, 
			PresentationOfInformation);
			
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"InformationLocationDepartment", 
			NStr("vi = 'Bộ phận:';
				|ru = 'Подразделение:';
				|en = 'Business unit:'; fa = 'واحد تجاری:';
				|it = 'Подразделение:';
				|pl = 'Dział:';
				|tr = 'Departman:'"), 
			InformationAboutAccounting.Department, 
			InformationAboutAccounting.DepartmentPresentation, 
			PresentationOfInformation);
			
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"InformationInventoryCustodianLocation", 
			NStr("vi = 'Chịu trách nhiệm:';
				|ru = 'МОЛ:';
				|en = 'Responsible employee:'; fa = 'Responsible employee:';
				|it = 'Persone Responsabili Materialmente:';
				|pl = 'Responsible employee:';
				|tr = 'Sorumlu çalışan:'"), 
			InformationAboutAccounting.FinanciallyLiablePerson, 
			InformationAboutAccounting.FinanciallyLiablePersonPresentation, 
			PresentationOfInformation);
			
		If ValueIsFilled(InformationAboutAccounting.LocationAddress) Then
			InformationLocationAddress.Add(NStr("vi = 'Địa chỉ:';
												|ru = 'Адрес:';
												|en = 'Address:'; fa = 'آدرس:';
												|it = 'Indirizzo:';
												|pl = 'Address:';
												|tr = 'Adres:'"));
			InformationLocationAddress.Add(" ");
			InformationLocationAddress.Add(InformationAboutAccounting.LocationAddress);
			InformationLocationAddress.Add(" ");
			InformationLocationAddress.Add(New FormattedString(PictureLib.ShowOnMap,,,, InformationAboutAccounting.LocationAddress));
		ElsIf IncludeBlankFields Then
			InformationLocationAddress.Add(NStr("vi = 'Địa chỉ:';
												|ru = 'Адрес:';
												|en = 'Address:'; fa = 'آدرس:';
												|it = 'Indirizzo:';
												|pl = 'Address:';
												|tr = 'Adres:'"));
			InformationLocationAddress.Add(" ");
			InformationLocationAddress.Add(New FormattedString(NStr("vi = 'chưa chỉ ra';
																	|ru = 'не указан';
																	|en = 'not specified'; fa = 'مشخص نشده';
																	|it = 'non specificato';
																	|pl = 'nie określony';
																	|tr = 'belirtilmedi'"),, StyleColors.EmptyTableField));
		EndIf;
		 
	Else
			
		PresentationOfInformation.Insert("InformationLocationCompany", Undefined);
		PresentationOfInformation.Insert("InformationLocationDepartment", Undefined);
		PresentationOfInformation.Insert("InformationInventoryCustodianLocation", Undefined);
		
	EndIf; 
	
	#EndRegion
	
	#Region Amounts
	
	If Not ComplianceCAAccountingIsKept 
		And ComplCurrency = CurrencyOfMan
		And InformationAboutAccounting <> Undefined Then
		
		SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
			CostAndDepreciation.Cost, NStr("vi = 'Chi phí thay thế:';
											|ru = 'Восстановительная стоимость:';
											|en = 'Replacement cost:'; fa = 'Replacement cost:';
											|it = 'Costi recuperabili:';
											|pl = 'Koszt odtworzenia:';
											|tr = 'Yenileme değeri:'"), CurrencyOfMan);
		InformationReplacementCost.Add(SumPresentation_);
		
		SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
			CostAndDepreciation.Depreciation, NStr("vi = 'Khấu hao lũy kế:';
													|ru = 'Накопленная амортизация:';
													|en = 'Accumulated depreciation:'; fa = 'Accumulated depreciation:';
													|it = 'Ammortamenti accumulati:';
													|pl = 'Skumulowana amortyzacja:';
													|tr = 'Birikmiş amortisman:'"), CurrencyOfMan);
		InformationAccumulatedDepreciation.Add(SumPresentation_);
		
		If GetFunctionalOption("UseFixedAssetImpairment") Then
			SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
				CostAndDepreciation.ImpairmenMan, NStr("vi = 'Giảm giá:';
														|ru = 'Обесценение:';
														|en = 'Impairment:'; fa = 'Impairment:';
														|it = 'Svalutazione:';
														|pl = 'Utrata wartości:';
														|tr = 'Değer kaybı:'"), CurrencyOfMan);
			InformationImpairment.Add(SumPresentation_);
		EndIf;
		
		SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
			CostAndDepreciation.Cost - CostAndDepreciation.Depreciation - CostAndDepreciation.ImpairmenMan,
			NStr("vi = 'Giá trị còn lại:';
				|ru = 'Остаточная стоимость:';
				|en = 'Net book value:'; fa = 'Net book value:';
				|it = 'Valore residuo:';
				|pl = 'Wartość rezydualna:';
				|tr = 'Net defter değeri:'"), CurrencyOfMan);
		InformationResidualValue.Add(SumPresentation_);
		
	EndIf;
	
	#EndRegion
	
	PresentationOfInformation.Insert("Period", Period);
	PresentationOfInformation.Insert("InformationReplacementCost", InformationReplacementCost);
	PresentationOfInformation.Insert("InformationAccumulatedDepreciation", InformationAccumulatedDepreciation);
	PresentationOfInformation.Insert("InformationImpairment", InformationImpairment);
	PresentationOfInformation.Insert("InformationResidualValue", InformationResidualValue);
	PresentationOfInformation.Insert("InformationLocationAddress", InformationLocationAddress);
	
	Return PresentationOfInformation;

EndFunction

// Returns the owner of the depreciation node or component as of the date.
// 
// Parameters:
//  SubAssetComponent - CatalogRef.Assets - depreciation unit or component
//  DateOfLastEdit - Date - The date of the information, if not specified, then on the current date.
// 
// Returns:
//  CatalogRef.Assets - Owner of the depreciation node or component.
//
Function OwnerOfDepreciationComponentNode(SubAssetComponent, DateOfLastEdit = Undefined) Export
	
	If Not ValueIsFilled(SubAssetComponent) Then
		Return EmptyRef();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("SubAssetComponent", SubAssetComponent);
	Query.SetParameter("Period", ?(DateOfLastEdit = Undefined, CurrentSessionDate(), DateOfLastEdit));
	Query.Text = 
	"SELECT
	|	NodesComponents.FixedAsset AS FixedAsset
	|FROM
	|	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(&Period, SubAssetComponent = &SubAssetComponent) AS NodesComponents";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.FixedAsset;
	Else
		Return EmptyRef();
	EndIf;
	
EndFunction

// Defines the selection attribute based on information.
// 
// Parameters:
//  FilterName - String - Selection name
// 
// Returns:
//  Boolean - True if it is a selection based on information
Function ThisIsSelectionBasedOnInformation(FilterName) Export

	Result =
		Upper(FilterName) = Upper("Organization")
		Or Upper(FilterName) = Upper("Department")
		Or Upper(FilterName) = Upper("FINANCIALLYLIABLEPERSON")
		Or Upper(FilterName) = Upper("LocationAddress")
		Or Upper(FilterName) = Upper("LineOfBusiness")
		Or Upper(FilterName) = Upper("DepreciationGroup")
		Or Upper(FilterName) = Upper("RealEstate")
		Or Upper(FilterName) = Upper("State")
		Or Upper(FilterName) = Upper("StateOfTheUU")
		Or Upper(FilterName) = Upper("BUState")
		Or Upper(FilterName) = Upper("FinancialAccountingGroup")
		Or Upper(FilterName) = Upper("UsefulLifeManagementAccounting")
		Or Upper(FilterName) = Upper("UsefulLifeAccounting")
		Or Upper(FilterName) = Upper("UsefulLifeTaxAccounting")
		Or Upper(FilterName) = Upper("ResidualLifetimeMA")
		Or Upper(FilterName) = Upper("ResidualLifetimeAC")
		Or Upper(FilterName) = Upper("ResidualLifetimeTA")
		Or Upper(FilterName) = Upper("VATTaxation")
		Or Upper(FilterName) = Upper("DateOfRegistrationOfTheRegl")
		Or Upper(FilterName) = Upper("DateOfRegistrationOfTheUpr")
		Or Upper(FilterName) = Upper("Lessor")
		Or Upper(FilterName) = Upper("Leaseholder")
		Or Upper(FilterName) = Upper("Contract");
			
	Return Result;
	 	
EndFunction

#EndRegion

#Region Private

// Returns an array of depreciation nodes and components by the Owner OS
//
// Parameters:
//  FixedAsset - CatalogRef.Assets - OS-Owner or node/component of depreciation
//  DateOfLastEdit - Date -
//
// Returns:
//   Array - Array of subordinate nodes and depreciation components
//
Function GetNodesOfDepreciationComponentsByOwner(FixedAsset, DateOfLastEdit = Undefined)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	&FixedAsset AS FixedAsset
		|
		|INTO TTFAOwner
		|
		|UNION ALL
		|
		|SELECT
		|	SubAssetsComponentsOfDepreciation.FixedAsset
		|
		|FROM
		|	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(
		|			&DateOfLastEdit, 
		|			SubAssetComponent = &FixedAsset) AS SubAssetsComponentsOfDepreciation
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	NodesComponents.SubAssetComponent AS SubAssetComponent
		|
		|INTO TTUnitsOfFixedAssets
		|
		|FROM
		|	InformationRegister.SubAssetsComponentsOfDepreciation AS NodesComponents
		|
		|		INNER JOIN TTFAOwner AS FAOwner
		|		ON NodesComponents.FixedAsset = FAOwner.FixedAsset
		|WHERE
		//If it is not the owner, but the node that is passed, then we exclude the node itself from the selection
		|	NodesComponents.SubAssetComponent <> &FixedAsset
		|
		|INDEX BY
		|	SubAssetComponent
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NodesComponents.SubAssetComponent AS SubAssetComponent
		|
		|FROM
		|	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(
		|			&DateOfLastEdit, 
		|			SubAssetComponent IN (
		|				SELECT
		|					TTUnitsOfFixedAssets.SubAssetComponent AS SubAssetComponent
		|				FROM
		|					TTUnitsOfFixedAssets AS TTUnitsOfFixedAssets)) AS NodesComponents
		|
		|		INNER JOIN TTFAOwner AS FAOwner
		|		ON NodesComponents.FixedAsset = FAOwner.FixedAsset
		|";
	
	Query.SetParameter("FixedAsset", FixedAsset);
	Query.SetParameter("DateOfLastEdit", DateOfLastEdit);
	
	QueryResult = Query.Execute();
	
	Return QueryResult.Unload().UnloadColumn("SubAssetComponent");

EndFunction

Function HistoryOfChangingProps(FixedAsset, AttributeName) Export

	QueryText = 
	"SELECT
	|	FixedAssetsDocuments.Date AS Date,
	|	FixedAssetsDocuments.Ref AS Document
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		INNER JOIN Document.ChangeFixedAssetFinancialDetails2_4 AS ChangeFixedAssetFinancialDetails
	|		ON (ChangeFixedAssetFinancialDetails.Ref = FixedAssetsDocuments.Ref)
	|WHERE
	|	FixedAssetsDocuments.FixedAsset = &FixedAsset
	|	AND FixedAssetsDocuments.RefType = &RefType
	|	AND FixedAssetsDocuments.RecNo = 0
	|	AND FixedAssetsDocuments.Posted
	|	AND NOT FixedAssetsDocuments.AdditionalRecord
	|	AND (ChangeFixedAssetFinancialDetails.LineOfBusinessFlag
	|				AND &AttributeName = ""LineOfBusiness""
	|			OR ChangeFixedAssetFinancialDetails.DepreciationGroupFlag
	|				AND &AttributeName = ""DepreciationGroup""
	|			OR ChangeFixedAssetFinancialDetails.RealEstateFlag
	|				AND &AttributeName = ""RealEstate"")
	|
	|ORDER BY
	|	FixedAssetsDocuments.Date";
	
	Query = New Query(QueryText);
	Query.SetParameter("FixedAsset", FixedAsset);
	Query.SetParameter("AttributeName", AttributeName);
	Query.SetParameter("RefType", Common.MetadataObjectID(Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4")));
	
	SetPrivilegedMode(True);
	ChangeHistory = Query.Execute().Unload();
	SetPrivilegedMode(False);

	Return ChangeHistory;
	
EndFunction

// Called when the class of the operation object is changed.
// 
// Parameters:
// 	Object - CatalogObject.Assets -
Procedure WhenChangingClass(Object) Export
	
	Object.Subclass = Catalogs.MaintenanceSchemeOptions.EmptyRef();
	
EndProcedure

#Region CheckingFillingOfObjectsOfOperation

Procedure GenerateFillVerificationRequest(QueryText)
	
	QueryText =
		"SELECT
		|	Assets.*
		|FROM
		|	Catalog.Assets AS Assets
		|WHERE
		|	Assets.Ref IN (&Assets)";
	
EndProcedure

Procedure GenerateRequestToCheckFillingOfNodes(QueryText)
	
	QueryText =
		"SELECT
		|	SubAssets.*
		|FROM
		|	Catalog.SubAssets AS SubAssets
		|WHERE
		|	SubAssets.Owner IN(&Assets)
		|	AND SubAssets.Owner <> VALUE(Catalog.Assets.EmptyRef)
		|	AND NOT SubAssets.DeletionMark
		|	AND SubAssets.Status IN (VALUE(Enum.AssetStatuses.InOperation), VALUE(Enum.AssetStatuses.EmptyRef))";
	
EndProcedure

Function GetRequiredBankingDetails(Class, CachedValues)
	
	RequiredDetails_ = CachedValues.RequiredDetails_.Get(Class);
	
	If RequiredDetails_ = Undefined Then
		
		Query = New Query;
		
		If ValueIsFilled(Class) Then
			Query.Text =
				"SELECT
				|	DetailsForObjectControl.Name,
				|	DetailsForObjectControl.Synonym
				|FROM
				|	Catalog.MaintenanceSchemes.AttributesForControl AS Attributes
				|		INNER JOIN ObjectsAttributes AS DetailsForObjectControl
				|		ON Attributes.AttributeName = DetailsForObjectControl.Name
				|WHERE
				|	Attributes.Ref = &Class
				|	AND Attributes.RequiredForFilling";
		Else
			Query.Text =
				"SELECT
				|	Attributes.Name,
				|	Attributes.Synonym
				|FROM
				|	ObjectsAttributes AS Attributes
				|WHERE
				|	Attributes.RequiredForFilling";
			
		EndIf;
		Query.TempTablesManager = CachedValues.TempTablesManager;
		Query.SetParameter("Class", Class);
		
		RequiredDetails_ = Query.Execute().Unload();
		
		CachedValues.RequiredDetails_.Insert(Class, RequiredDetails_);
		
	EndIf;
	
	Return RequiredDetails_;
	
EndFunction

Function GetRequiredAdditionalBankingDetails(Class, CachedValues)
	
	MandatoryAdditionalDetails = CachedValues.MandatoryAdditionalDetails.Get(Class);
	
	If MandatoryAdditionalDetails = Undefined Then
		
		Query = New Query(
			"SELECT DISTINCT
			|	AddAttributes.Property
			|FROM
			|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AddAttributes
			|WHERE
			|	AddAttributes.Ref = CAST(&Class AS Catalog.MaintenanceSchemes).PropertiesSet
			|	AND (AddAttributes.Property.RequiredToFill)
			|	AND NOT AddAttributes.Property IN
			|				(SELECT
			|					GeneralAdditionalDetailsOfObjects.Property
			|				FROM
			|					GeneralAdditionalDetailsOfObjects AS GeneralAdditionalDetailsOfObjects)
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	AddAttributes.Property
			|FROM
			|	GeneralAdditionalDetailsOfObjects AS AddAttributes
			|WHERE
			|	AddAttributes.RequiredToFill");
		
		Query.TempTablesManager = CachedValues.TempTablesManager;
		Query.SetParameter("Class", Class);
		
		MandatoryAdditionalDetails = Query.Execute().Unload().UnloadColumn("Property");
		
		CachedValues.MandatoryAdditionalDetails.Insert(Class, MandatoryAdditionalDetails);
		
	EndIf;
	
	Return MandatoryAdditionalDetails;
	
EndFunction

Function GetPerformanceAccountingParameters(Class, CachedValues)
	
	RunningTimeRecordingParameters = CachedValues.RunningTimeRecordingParameters.Get(Class);
	
	If RunningTimeRecordingParameters = Undefined Then
		
		Query = New Query(
			"SELECT
			|	Parameters.RunningTimeValue AS RunningTimeValue,
			|	Parameters.CalculateResidualLifetime AS FillOutTheAssignedResource,
			|	Parameters.RegisterBySource AS FillInTheSource
			|FROM
			|	Catalog.MaintenanceSchemes.RunningTimeValues AS Parameters
			|WHERE
			|	Parameters.Ref = &Class
			|	AND (Parameters.RegisterBySource
			|			OR Parameters.CalculateResidualLifetime)");
		Query.TempTablesManager = CachedValues.TempTablesManager;
		Query.SetParameter("Class", Class);
		
		RunningTimeRecordingParameters = Query.Execute().Unload();
		
		CachedValues.RunningTimeRecordingParameters.Insert(Class, RunningTimeRecordingParameters);
		
	EndIf;
	
	Return RunningTimeRecordingParameters;
	
EndFunction

Procedure CheckObjectOfOperation(VerificationObject, CheckParameters, CachedValues)
	
	CheckBankingDetails(VerificationObject, CheckParameters, CachedValues);
	CheckAdditionalBankingDetails(VerificationObject, CheckParameters, CachedValues);
	CheckWorkCenters(VerificationObject, CheckParameters, CachedValues);
	CheckParametersOfAccountingOfDevelopments(VerificationObject, CheckParameters, CachedValues);
	
EndProcedure

Procedure CheckBankingDetails(VerificationObject, CheckParameters, CachedValues)
	
	RequiredDetails_ = GetRequiredBankingDetails(VerificationObject.Class, CachedValues);
	
	For Each Attribute In RequiredDetails_ Do
		
		If Not ValueIsFilled(VerificationObject[TrimAll(Attribute.Name)]) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trường ""%1"" chưa điền.';
					|ru = 'Поле ""%1"" не заполнено.';
					|en = '""%1"" is required.'; fa = '""%1"" is required.';
					|it = 'Il campo ""%1"" non è compilato.';
					|pl = 'Nie wypełniono pola ""%1"".';
					|tr = '""%1"" gerekli.'"),
				TrimAll(Attribute.Synonym));
			
			Assets.AddUserError(
				CheckParameters.ErrorStream,
				VerificationObject.Ref,
				"Object."+Attribute.Name,
				ErrorText,
				"Attributes",
				0,
				ErrorText);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckAdditionalBankingDetails(VerificationObject, CheckParameters, CachedValues)
	
	If CheckParameters.Form = Undefined Then
		
		MandatoryAdditionalDetails = GetRequiredAdditionalBankingDetails(VerificationObject.Class, CachedValues);
		
		AddlAttributesTable = VerificationObject.AdditionalAttributes.Unload();
		
		For Each Property In MandatoryAdditionalDetails Do
			
			If AddlAttributesTable.Find(Property, "Property") = Undefined Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trường ""%1"" chưa điền.';
						|ru = 'Поле ""%1"" не заполнено.';
						|en = 'Field %1 is required.'; fa = 'Field %1 is required.';
						|it = 'Il campo ""%1"" non è compilato.';
						|pl = 'Nie wypełniono pola ""%1"".';
						|tr = '""%1"" gerekli.'"),
					Property);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"GroupAdditionalAttributes",
					ErrorText,
					"AddAttributes",
					0,
					ErrorText);
				
			EndIf;
			
		EndDo;
		
	Else
		
		If Not (CheckParameters.Form.PropertiesUseProperties And CheckParameters.Form.PropertiesUseAddlAttributes) Then
			Return;
		EndIf;
		
		AddlAttributesTable = CheckParameters.Form.PropertiesAdditionalAttributeDetails;
		
		For Each String In AddlAttributesTable Do
			If String.RequiredToFill Then
				
				If Not ValueIsFilled(CheckParameters.Form[String.ValueAttributeName]) Then
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trường ""%1"" chưa điền.';
							|ru = 'Поле ""%1"" не заполнено.';
							|en = 'Field %1 is required.'; fa = 'Field %1 is required.';
							|it = 'Il campo ""%1"" non è compilato.';
							|pl = 'Nie wypełniono pola ""%1"".';
							|tr = '""%1"" gerekli.'"),
						String.Description);
					
					Assets.AddUserError(
						CheckParameters.ErrorStream,
						VerificationObject.Ref,
						String.ValueAttributeName,
						ErrorText,
						"AddAttributes",
						0,
						ErrorText);
					
				EndIf;
				
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckWorkCenters(VerificationObject, CheckParameters, CachedValues)
	
	WorkCenters = VerificationObject.WorkCenters.Unload();
	For CurIndex__=0 To WorkCenters.Count()-1 Do
		
		String = WorkCenters[CurIndex__];
		
		If Not ValueIsFilled(String["WorkCenter"]) Then
			
			Assets.AddUserError(
				CheckParameters.ErrorStream,
				VerificationObject.Ref,
				"Object.WorkCenters[%1].WorkCenter",
				NStr("vi = 'Chưa điền trường ''''Nguồn lực sản xuất''''';
					|ru = 'Не заполнено поле ""Рабочий центр""';
					|en = '""Work center"" is required'; fa = '""Work center"" is required';
					|it = 'Il campo ""Centro di lavoro"" non è compilato';
					|pl = 'Nie wypełniono pola ""Centrum pracy""';
					|tr = '""İş merkezi"" alanı doldurulmamış'"),
				"WorkCenters",
				CurIndex__,
				NStr("vi = 'Chưa điền cột ""Nguồn lực sản xuất"" tại dòng %1 của danh sách ''''Nguồn lực sản xuất''''';
					|ru = 'Не заполнена колонка ""Рабочий центр"" в строке %1 списка ""Рабочие центры""';
					|en = 'The ""Work center"" column in line %1 of the ""Operation centers"" list is not filled in'; fa = 'The ""Work center"" column in line %1 of the ""Operation centers"" list is not filled in';
					|it = 'La colonna ""Centro di lavoro"" non è compilato nella riga %1 dell''elenco ""Centri di lavoro""';
					|pl = 'Nie wypełniono pola ""Centrum pracy"" w wierszu %1 listy ""Centra wykonania prac""';
					|tr = '""İş merkezleri"" listesinin %1satırındaki ""İş merkezi"" sütunu doldurulmamış'"));
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckParametersOfAccountingOfDevelopments(VerificationObject, CheckParameters, CachedValues)
	
	If CheckParameters.Form = Undefined Then
		
		OperatingTimeAccountingParameters = GetPerformanceAccountingParameters(VerificationObject.Class, CachedValues);
		
		ParametersTable = VerificationObject.RunningTimeRecordingParameters.Unload(); 
		
		For Each ConfiguringMetric In OperatingTimeAccountingParameters Do
			
			String = ParametersTable.Find(ConfiguringMetric.RunningTimeValue, "RunningTimeValue");
			
			If String = Undefined Or (ConfiguringMetric.FillOutTheAssignedResource And Not ValueIsFilled(String.AssignedResource)) Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tài nguyên chỉ báo sản lượng được chỉ định ""%1"" không đầy đủ';
						|ru = 'Назначенный ресурс показателя наработки ""%1"" не заполнен';
						|en = 'Specify lifetime for the ""%1"" asset activity measure'; fa = 'Specify lifetime for the ""%1"" asset activity measure';
						|it = 'La risorsa assegnata dell''indicatore del tempo di funzionamento senza guasti ""%1"" non è compilata';
						|pl = 'Nie wypełniono wyznaczonego źródła wskaźnika średniego czasu pracy ""%1""';
						|tr = 'İşlem süresi göstergesinin atanman kaynağı ""%1"" tamamlanmadı'"),
					ConfiguringMetric.RunningTimeValue);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"RunningTimeRecordingParameters",
					ErrorText,
					"RunningTimeRecordingParameters",
					0,
					ErrorText);
				
			EndIf;
			
			If String = Undefined Or (ConfiguringMetric.FillInTheSource And Not ValueIsFilled(String.SourceOfParameter)) Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nguồn của các giá trị hiện tại của chỉ báo sản lượng ""%1"" không được điền';
						|ru = 'Источник текущих значений показателя наработки ""%1"" не заполнен';
						|en = 'Specify the source of the current values of ""%1"" asset activity'; fa = 'Specify the source of the current values of ""%1"" asset activity';
						|it = 'La fonte dei valori correnti dell''indicatore del tempo di funzionamento senza guasti ""%1"" non è indicata';
						|pl = 'Nie wypełniono źródła bieżących wartości wskaźnika średniego czasu pracy ""%1""';
						|tr = 'İşletim süresi göstergesi ""%1'''' mevcut değerlerinin kaynağı doldurulmamış'"),
					ConfiguringMetric.RunningTimeValue);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"RunningTimeRecordingParameters",
					ErrorText,
					"RunningTimeRecordingParameters",
					0,
					ErrorText);
				
			EndIf;
			
		EndDo;
		
	Else
		
		If CheckParameters.Form.RunningTimeRecordingParameters.Count()=0 Then
			Return;
		EndIf;
		
		For CurIndex__=0 To CheckParameters.Form.RunningTimeRecordingParameters.Count()-1 Do
			
			String = CheckParameters.Form.RunningTimeRecordingParameters[CurIndex__];
			
			If String.FillOutTheAssignedResource And Not ValueIsFilled(String.AssignedResource) Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tài nguyên chỉ báo sản lượng được chỉ định ""%1"" không đầy đủ';
						|ru = 'Назначенный ресурс показателя наработки ""%1"" не заполнен';
						|en = 'Specify lifetime for the ""%1"" asset activity measure'; fa = 'Specify lifetime for the ""%1"" asset activity measure';
						|it = 'La risorsa assegnata dell''indicatore del tempo di funzionamento senza guasti ""%1"" non è compilata';
						|pl = 'Nie wypełniono wyznaczonego źródła wskaźnika średniego czasu pracy ""%1""';
						|tr = 'İşlem süresi göstergesinin atanman kaynağı ""%1"" tamamlanmadı'"),
					String.RunningTimeValue);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"RunningTimeRecordingParameters[%1].AssignedResource",
					ErrorText,
					"RunningTimeRecordingParameters",
					CurIndex__,
					ErrorText);
				
			EndIf;
			If String.FillInTheSource And Not ValueIsFilled(String.SourceOfParameter) Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nguồn của các giá trị hiện tại của chỉ báo sản lượng ""%1"" không được điền';
						|ru = 'Источник текущих значений показателя наработки ""%1"" не заполнен';
						|en = 'Specify the source of the current values of ""%1"" asset activity'; fa = 'Specify the source of the current values of ""%1"" asset activity';
						|it = 'La fonte dei valori correnti dell''indicatore del tempo di funzionamento senza guasti ""%1"" non è indicata';
						|pl = 'Nie wypełniono źródła bieżących wartości wskaźnika średniego czasu pracy ""%1""';
						|tr = 'İşletim süresi göstergesi ""%1'''' mevcut değerlerinin kaynağı doldurulmamış'"),
					String.RunningTimeValue);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"RunningTimeRecordingParameters[%1].SourceOfParameter",
					ErrorText,
					"RunningTimeRecordingParameters",
					CurIndex__,
					ErrorText);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("View", Metadata.DataProcessors.LabelPrintingOfAssets) Then
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "NonCurrentAssetsClient.LabelPrintingOfAssets";
		PrintCommand.Id = "LabelOfObjectsOfOperation";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
										|ru = 'Этикетки';
										|en = 'Labels'; fa = 'برچسب‌ها';
										|it = 'Etichette';
										|pl = 'Labels';
										|tr = 'Etiketler'");
		
	EndIf;
	
	AssetsLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.FixedAssetsInitialRecognition2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.RecognizeSubAssetsComponentsOfDepreciation.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
		
		List = New Array;
		List.Add(Enums.FATypes.Asset);
		List.Add(Enums.FATypes.Node);
		List.Add(Enums.FATypes.DepreciationComponent);
		AttachableCommands.AddCommandVisibilityCondition(Command, "OSType", List, DataCompositionComparisonType.InList);
		
	EndIf;
	
	Command = Documents.ChangeFixedAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.FixedAssetsCostAdditions2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.AllocateVariancesToFixedAssetCost.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.FARevaluation2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.FATransfer2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.PreparingForFixedAssetSale2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.DisposeFixedAssets2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.AssetActivityRecord.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.SplitFixedAssets.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.MergeOfFixedAssets.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
		Command.MultipleChoice = True;
	EndIf;
	
	Command = Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
		Command.MultipleChoice = True;
	EndIf;
	
	Command = Documents.ProvideAssetsToLeasee2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then

		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
		
		List = New Array;
		List.Add(Enums.FATypes.Asset);
		List.Add(Enums.FATypes.CapitalExpenditureInLeasedAssets);
		AttachableCommands.AddCommandVisibilityCondition(Command, "OSType", List, DataCompositionComparisonType.InList);
		
	EndIf;
	
	Command = Documents.ReturnAssetsFromLeasee2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
		
		List = New Array;
		List.Add(Enums.FATypes.Asset);
		List.Add(Enums.FATypes.CapitalExpenditureInLeasedAssets);
		AttachableCommands.AddCommandVisibilityCondition(Command, "OSType", List, DataCompositionComparisonType.InList);
			
	EndIf;
	Command = Documents.RMOrder.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then

		Command.VisibilityInForms = "ItemForm, ListForm";
		Command.WriteMode = "";
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command, 
			"OSType",
			Enums.FATypes.Asset);
		
	EndIf;
	
	Command = Documents.SetRunningTimeValues.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListForm";
		Command.WriteMode = "";
	EndIf;
	AssetsLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Command = Reports.FixedAssetsStatementManagementAccounting.AddReportCommand(ReportsCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
	EndIf;
	
	Command = Reports.StatementCalculationOfAssetsDepreciation.AddFAReportCommand(ReportsCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
	EndIf;
	
	Command = Reports.CapitalizationExpenseStructure.AddReportCommand(ReportsCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
	EndIf;
	
	Command = Reports.AssetCard.AddReportCommand(ReportsCommands);
	If Command <> Undefined Then
		
		Command.VisibilityInForms = "ItemForm, ListForm";
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command, 
			"OSType",
			Enums.FATypes.Asset);
			
	EndIf;
	
	AssetsLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	OutputParameters.PrintingBySetsIsAvailable = True;
	
	AssetsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
