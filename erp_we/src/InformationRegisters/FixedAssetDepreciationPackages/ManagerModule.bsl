#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Assigns the package number to fixed assets for which it has not yet been defined.
//
// Parameters:
//  CompaniesList	 - Array, Undefined	 - A list of organizations for which you want to create packages.
//  JobNumber		 - Number				 - The task number that will be used to create new tasks.
// 
// Returns:
//  ValueTable - Contains modified depreciation packages.
//
Function CreateDepreciationPackages(CompaniesList, JobNumber = Undefined) Export

	If CompaniesList = Undefined Then
		CompaniesList = New Array;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If JobNumber = Undefined Then
		// Before executing, we increase the task number.
		// Because during execution, new tasks may be added in other sessions and they should remain.
		JobNumber = InformationRegisters.JobsForCalculatingFixedAssetDepreciation.IncreaseTaskNumber();
	EndIf; 
	
	BeginTransaction();

	Try
	
		ModifiedPackages = CalculatePackageNumbers(CompaniesList);
		GenerateTasksAfterCreatingPackages(ModifiedPackages, CompaniesList, JobNumber);
		
		CommitTransaction();
		
	Except
	
		RollbackTransaction();
		
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		Raise ErrorText;
		
	EndTry; 
	
	Return ModifiedPackages;
	
EndFunction

#EndRegion

#Region Private

Function CalculatePackageNumbers(CompaniesList)

	QueryText = NonCurrentAssetsLocalization.QueryTextCalculateFAAmortizationPackageNumbers();
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	MIN(BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, MONTH)) AS Period,
		|	FixedAssetsAccountingProcedure.Organization                           AS Organization,
		|	FixedAssetsAccountingProcedure.FixedAsset                      AS FixedAsset
		|INTO VT_OSList_WithoutNumber
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedure
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
		|		ON (FixedAssetDepreciationPackages.Organization = FixedAssetsAccountingProcedure.Organization)
		|			AND (FixedAssetDepreciationPackages.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
		|WHERE
		|	FixedAssetsAccountingProcedure.AccrueDepreciationOrAmortization
		|	AND FixedAssetsAccountingProcedure.Organization IN(&Organization)
		|	AND FixedAssetDepreciationPackages.PackageNumber IS NULL
		|	AND FixedAssetsAccountingProcedure.CorrectionDate = DATETIME(1,1,1)
		|
		|GROUP BY
		|	FixedAssetsAccountingProcedure.Organization,
		|	FixedAssetsAccountingProcedure.FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ListOfFA.Period                       AS BegOfMonth,
		|	ENDOFPERIOD(ListOfFA.Period, MONTH)  AS EndOfMonth
		|INTO TT_TimeIntervals
		|FROM
		|	VT_OSList_WithoutNumber AS ListOfFA
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_TimeIntervals.BegOfMonth                                  AS Period,
		|	FixedAssetsAccountingProcedure.Organization                            AS Organization,
		|	FixedAssetDepreciationPackages.PackageNumber                       AS PackageNumber,
		|	COUNT(DISTINCT FixedAssetsAccountingProcedure.FixedAsset) AS PackageVolume_
		|FROM
		|	TT_TimeIntervals AS TT_TimeIntervals
		|
		|		INNER JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedure
		|		ON (FixedAssetsAccountingProcedure.Period >= TT_TimeIntervals.BegOfMonth)
		|			AND (FixedAssetsAccountingProcedure.Period <= TT_TimeIntervals.EndOfMonth)
		|			AND (FixedAssetsAccountingProcedure.Organization IN (&Organization))
		|			AND (FixedAssetsAccountingProcedure.AccrueDepreciationOrAmortization)
		|			AND (FixedAssetsAccountingProcedure.CorrectionDate = DATETIME(1,1,1))
		|
		|		INNER JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
		|		ON (FixedAssetDepreciationPackages.Organization = FixedAssetsAccountingProcedure.Organization)
		|			AND (FixedAssetDepreciationPackages.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
		|
		|GROUP BY
		|	TT_TimeIntervals.BegOfMonth,
		|	FixedAssetDepreciationPackages.PackageNumber,
		|	FixedAssetsAccountingProcedure.Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfFA.Period AS Period,
		|	ListOfFA.Organization AS Organization,
		|	ListOfFA.FixedAsset AS FixedAsset
		|FROM
		|	VT_OSList_WithoutNumber AS ListOfFA";
		
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", CompaniesList);
	Query.SetParameter("ByAllCompanies", CompaniesList.Count() = 0);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.FixedAssetDepreciationPackages");
	LockItem.Mode = DataLockMode.Exclusive;
	If CompaniesList.Count() <> 0 Then
		LockItem.DataSource = ListOfOrganizationsInTable(CompaniesList);
		LockItem.UseFromDataSource("Organization", "Organization");
	EndIf; 
	Block.Lock(); 
	
	QueryResult = Query.ExecuteBatch();
	
	PackagesVolume = QueryResult[QueryResult.UBound()-1].Unload();
	Selection = QueryResult[QueryResult.UBound()].Select();
	
	RecordSet = InformationRegisters.FixedAssetDepreciationPackages.CreateRecordSet();
	ModifiedPackages = CalculateDepreciationPackageNumbers(Selection, PackagesVolume, RecordSet);
	
	Return ModifiedPackages;
	
EndFunction

// You need to create tasks, because the OS has a batch number.
// If you do not do this, you will lose information that these operating systems need to be recalculated.
//
Procedure GenerateTasksAfterCreatingPackages(ModifiedPackages, CompaniesList, JobNumber)

	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	If ModifiedPackages.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	ModifiedPackages.Organization AS Organization,
	|	ModifiedPackages.PackageNumber AS PackageNumber
	|INTO ModifiedPackages
	|FROM
	|	&ModifiedPackages AS ModifiedPackages
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Jobs.Month,
	|	Jobs.Organization,
	|	Jobs.PackageNumber,
	|	Jobs.JobNumber,
	|	Jobs.Document
	|INTO Jobs
	|FROM
	|	InformationRegister.JobsForCalculatingFixedAssetDepreciation AS Jobs
	|WHERE
	|	Jobs.PackageNumber = 0
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND Jobs.Month >= &AccountingStartDate24
	|	AND (Jobs.Organization IN (&Organization)
	|			OR &ByAllCompanies)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Recording new tasks
	|SELECT
	|	Jobs.Month,
	|	Jobs.Organization,
	|	ModifiedPackages.PackageNumber,
	|	MAX(Jobs.JobNumber) AS JobNumber
	|FROM
	|	Jobs AS Jobs
	|
	|		INNER JOIN ModifiedPackages AS ModifiedPackages
	|		ON (ModifiedPackages.Organization = Jobs.Organization)
	|
	|GROUP BY
	|	Jobs.Month,
	|	Jobs.Organization,
	|	ModifiedPackages.PackageNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Deleting tasks
	|SELECT DISTINCT
	|	Jobs.Month,
	|	Jobs.Organization,
	|	Jobs.JobNumber
	|FROM
	|	Jobs AS Jobs";
	
	Query = New Query(QueryText);
	Query.SetParameter("ModifiedPackages", ModifiedPackages);
	Query.SetParameter("Organization", CompaniesList);
	Query.SetParameter("ByAllCompanies", CompaniesList.Count() = 0);
	Query.SetParameter("JobNumber", JobNumber);
	Query.SetParameter("AccountingStartDate24", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.JobsForCalculatingFixedAssetDepreciation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("PackageNumber", 0);
	If CompaniesList.Count() <> 0 Then
		LockItem.DataSource = ListOfOrganizationsInTable(CompaniesList);
		LockItem.UseFromDataSource("Organization", "Organization");
	EndIf; 
	Block.Lock(); 
	
	Result = Query.ExecuteBatch();
	
	// Adding new tasks for modified packages.
	Selection = Result[Result.UBound()-1].Select();
	While Selection.Next() Do
		NewJobEntry = InformationRegisters.JobsForCalculatingFixedAssetDepreciation.CreateRecordManager();
		FillPropertyValues(NewJobEntry, Selection);
		NewJobEntry.Write();
	EndDo;
	
	// Deleting tasks for a null batch.
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
		RecordSet = InformationRegisters.JobsForCalculatingFixedAssetDepreciation.CreateRecordSet();
		RecordSet.Filter.Month.Set(Selection.Month);
		RecordSet.Filter.Organization.Set(Selection.Organization);
		RecordSet.Filter.JobNumber.Set(Selection.JobNumber);
		RecordSet.Filter.PackageNumber.Set(0);
		RecordSet.Write();
	EndDo;
	
EndProcedure

Function ListOfOrganizationsInTable(CompaniesList)

	CompanyTable = New ValueTable;
	CompanyTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	
	For Each Organization In CompaniesList Do
		NewRow = CompanyTable.Add();
		NewRow.Organization = Organization;
	EndDo; 

	Return CompanyTable;
	
EndFunction

Function CalculateDepreciationPackageNumbers(Selection, PackagesVolume, RecordSet)
	
	ListOfCurPackages = New ValueTable;
	ListOfCurPackages.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	ListOfCurPackages.Columns.Add("Period", New TypeDescription("Date"));
	ListOfCurPackages.Columns.Add("PackageNumber", New TypeDescription("Number", New NumberQualifiers(10,0)));
	ListOfCurPackages.Columns.Add("PackageVolume_", New TypeDescription("Number", New NumberQualifiers(10,0)));
	
	MaximumPackageVolume = MaximumPackageVolume();
	
	ModifiedPackages = New ValueTable;
	ModifiedPackages.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	ModifiedPackages.Columns.Add("PackageNumber", New TypeDescription("Number", New NumberQualifiers(10,0)));
	
	CurPackage_ = Undefined;
	DataToRecord = 0;
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure("Organization,Period", Selection.Organization, Selection.Period);
		StringsList = ListOfCurPackages.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			CurPackage_ = StringsList[0];
		Else
			CurPackage_ = Undefined;
		EndIf;
		
		If CurPackage_ = Undefined Or CurPackage_.PackageVolume_ >= MaximumPackageVolume Then
			
			SuitablePackage = FindSuitablePackage(
									Selection.Organization, 
									Selection.Period,
									?(CurPackage_ <> Undefined, CurPackage_.PackageNumber, 0), 
									PackagesVolume, 
									MaximumPackageVolume);
			
			If CurPackage_ = Undefined Then
				CurPackage_ = ListOfCurPackages.Add();
				CurPackage_.Organization = Selection.Organization;
				CurPackage_.Period      = Selection.Period;
			EndIf;
			CurPackage_.PackageNumber = SuitablePackage.PackageNumber;
			CurPackage_.PackageVolume_ = SuitablePackage.PackageVolume_;
			
		EndIf; 
		
		If DataToRecord > 5000 Then
			RecordSet.Write(False);
			If TypeOf(RecordSet) = Type("InformationRegisterRecordSet.FixedAssetDepreciationPackages") Then
				RecordSet = InformationRegisters.FixedAssetDepreciationPackages.CreateRecordSet();
			Else
				RecordSet = InformationRegisters.IntangibleAssetAmortizationPackages.CreateRecordSet();
			EndIf;
			DataToRecord = 0;
		EndIf; 
		
		NewRecordingPackage = RecordSet.Add();
		FillPropertyValues(NewRecordingPackage, Selection);
		NewRecordingPackage.PackageNumber = CurPackage_.PackageNumber;
		
		ModifiedPackage = ModifiedPackages.Add();
		FillPropertyValues(ModifiedPackage, NewRecordingPackage);
		
		DataToRecord = DataToRecord + 1;
		
		CurPackage_.PackageVolume_ = CurPackage_.PackageVolume_ + 1;
		
	EndDo;
	
	If DataToRecord > 0 Then
		RecordSet.Write(False);
	EndIf;
	
	ModifiedPackages.GroupBy("Organization,PackageNumber");
	
	Return ModifiedPackages;

EndFunction

Function FindSuitablePackage(Organization, Period, Val PackageNumber, PackagesVolume, MaximumVolume_)
	
	PackageVolume_ = MaximumVolume_;
	While PackageVolume_ >= MaximumVolume_ Do
		PackageNumber = PackageNumber + 1;
		TheStructureOfTheSearch = New Structure("Organization,Period,PackageNumber", Organization, Period, PackageNumber);
		StringsList = PackagesVolume.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			PackageVolume_ = StringsList[0].PackageVolume_;
		Else
			PackageVolume_ = 0;
		EndIf;
	EndDo;

	Return New Structure("PackageVolume_,PackageNumber", PackageVolume_,PackageNumber);
	
EndFunction

Function MaximumPackageVolume() Export

	Return 500;

EndFunction

#EndRegion

#EndIf