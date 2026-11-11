#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the name of a constant that stores the task number for this register.
//
// Returns:
//	String - String representation of the name of the constant of the task number of the account of the property.
Function NameOfJobNumberConstant() Export
	
	Return Metadata.Constants.NumberOfJobForCalculatingCost.Name;
	
EndFunction

// Increases the value of the task number in the constant.
//
// Returns:
//	Number - The previous task number from the constant "Task number for cost calculation".
Function IncreaseTaskNumber() Export
	
	Return MonthEndTransactionsServer.IncreaseTaskNumber(NameOfJobNumberConstant());
	
EndFunction

// Returns the value of the task number from a constant.
//
// Returns:
//	Number - The number of the current task from the constant "Number of the task to calculate the cost".
Function GetTaskNumber() Export
	
	Return MonthEndTransactionsServer.CurTaskNumber(NameOfJobNumberConstant());
	
EndFunction

// This method creates a register entry with the specified parameters.
//
// Parameters:
//	TaskPeriod   - Date - Start of the period for which you need to register a task for calculation
//	DocumentJobs - DocumentRef - document the Registrar who created the movement in the dependent registers
//	Organization - CatalogRef.Companies - organization that needs to be recalculated
//  JobNumber - Number - task number; if omitted, the value from the corresponding constant will be set
//	ChangedDataForBatchAccountingVersion21 - Boolean - if true, then such changes do not need to create records in the period in which batch accounting version 2.2 is used,
//		since these changes no longer affect the result of calculating batches/costs (they only affected in version 2.1);
//		if False, it means that the data that affects the results of the calculation of the batches of version 2.1. and version 2.2 has changed,
//		i.e. a record for such changes is always needed, regardless of its period.
//
Procedure CreateRegisterEntry(TaskPeriod, DocumentJobs = Undefined, Organization = Undefined,
				JobNumber = Undefined, ChangedDataForBatchAccountingVersion21 = False) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	If ChangedDataForBatchAccountingVersion21
	 And CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(TaskPeriod)) Then
		Return; // the changed data does not require recalculation of batches/cost
	EndIf;
	
	If Not ValueIsFilled(DocumentJobs) And Not ValueIsFilled(Organization) Then
		
		// Creating a task for each information security organization
		CompanyArray = CostCalculationAppliedAlgorithms.LinksOfOrganizationsUnderIntercampanyScheme();
		
	Else
		
		CompanyArray = New Array;
		
		If Not ValueIsFilled(Organization) Then
			// Let's try to define the default organization.
			// If it fails, a platform exception will be thrown when writing.
			CompanyArray.Add(Catalogs.Companies.DefaultCompany());
		ElsIf TypeOf(Organization) = Type("Array") Then
			CompanyArray = Organization;
		Else
			CompanyArray.Add(Organization);
		EndIf;
		
	EndIf;
	
	// Let's write down the tasks.
	BeginTransaction();
	
	Try
		
		If JobNumber = Undefined Then
			JobNumber = GetTaskNumber();
		EndIf;
		
		For Each CurrentCompany In CompanyArray Do
			
			RecordSet = InformationRegisters.JobsForCalculatingCost.CreateRecordSet();
			RecordSet.Filter.Month.Set(BegOfMonth(TaskPeriod));
			RecordSet.Filter.Document.Set(DocumentJobs);
			RecordSet.Filter.Organization.Set(CurrentCompany);
			RecordSet.Filter.JobNumber.Set(JobNumber);
			
			RecordSet.AdditionalProperties.Insert("GeneratedProgrammatically", True);
			
			Record = RecordSet.Add();
			
			Record.Month        = BegOfMonth(TaskPeriod);
			Record.Document     = DocumentJobs;
			Record.Organization  = CurrentCompany;
			Record.JobNumber = JobNumber;
			
			RecordSet.Write(True);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		BriefErrorDescription = ErrorProcessing.ErrorMessageForUser(ErrorInfo);
		
		WriteLogEvent(NStr("ru = 'Формирование заданий к расчету себестоимости';
							|vi = 'Generate jobs for calculating cost';
							|en = 'Generate jobs for calculating cost'; fa = 'Generate jobs for calculating cost';
							|it = 'Generate jobs for calculating cost';
							|pl = 'Generate jobs for calculating cost';
							|tr = 'Maliyet hesaplaması için görevlerin oluşturulması'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription);
		
		Raise BriefErrorDescription;
		
	EndTry;
	
EndProcedure

// This method creates register entries with the parameters received by the request.
//
// Parameters:
//	Selection - QueryResultSelection - a sample of the data to generate the records.
//  JobNumber - Number - task number; if omitted, the value from the corresponding constant will be set.
//	ChangedDataForBatchAccountingVersion21 - Boolean - if true, then such changes do not need to create records in the period in which batch accounting version 2.2 is used,
//		since these changes no longer affect the result of calculating batches/costs (they only affected in version 2.1);
//		if False, it means that the data that affects the results of the calculation of the batches of version 2.1. and version 2.2 has changed,
//		i.e. a record for such changes is always needed, regardless of its period.
//
Procedure CreateRegisterEntriesBasedOnSampleData(Selection, JobNumber = Undefined, ChangedDataForBatchAccountingVersion21 = False) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	If Selection.Count() = 0 Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		FieldsStructure = New Structure("Month, Organization, Document");
		
		If JobNumber = Undefined Then
			JobNumber = GetTaskNumber();
		EndIf;
		
		While Selection.Next() Do
			
			FillPropertyValues(FieldsStructure, Selection);
			
			CreateRegisterEntry(
				FieldsStructure.Month,
				FieldsStructure.Document,
				FieldsStructure.Organization,
				JobNumber,
				ChangedDataForBatchAccountingVersion21);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText    = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo tác vụ tính chi phí %1 trong doanh nghiệp %2 do: %3';
				|ru = 'Не удалось сформировать задание к расчету себестоимости за %1 в организации %2 по причине: %3';
				|en = 'Cannot generate the job for calculating cost for %1 in company %2. Reason: %3'; fa = 'Cannot generate the job for calculating cost for %1 in company %2. Reason: %3';
				|it = 'Non è stato possibile creare un''attività per il calcolo del costo %1 nell''organizzazione %2 a causa di: %3';
				|pl = 'Nie udało się utworzyć zadanie do kalkulacja kosztów własnych za %1 w firmie %2 z powodu: %3';
				|tr = 'Bu nedenden dolayı %2 iş yerinde %1 için maliyet hesaplama görevi oluşturulamadı: %3'"),
			Selection.Month,
			Selection.Organization,
			ErrorText);
			
		WriteLogEvent(NStr("vi = 'Kế toán theo lô';
							|ru = 'Партионный учет';
							|en = 'Lot accounting'; fa = 'حسابداری لات';
							|it = 'Contabilità per lotti';
							|pl = 'Ewidencja partii';
							|tr = 'Lot muhasebesi'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , MessageText);
		
	EndTry;
	
EndProcedure

// Performs cleanup tasks to the calculation of the cost.
//
//	Parameters:
//		BeginOfPeriod - Date - the beginning of the cleaning period, if not specified, the selection is not used.
//		EndOfPeriod - Date - end of the cleaning period, if not specified, the selection is not used.
//		Organization - CatalogRef.Companies, Array - selection by organization, if not specified, then the selection is not used.
//
Procedure ClearRecordsForPeriod(BeginOfPeriod = Undefined, EndOfPeriod = Undefined, Organization = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	T.Month AS Month,
	|	T.Organization AS Organization
	|FROM
	|	InformationRegister.JobsForCalculatingCost AS T
	|WHERE
	|	&Filter
	|";
	
	FilterPeriod = "";
	FilterOrganization = "";
	
	If ValueIsFilled(Organization) Then
		
		FilterOrganization = "T.Organization IN (&CompanyArray)";
		
		Query.SetParameter("CompanyArray", Organization);
		
	EndIf; 
	
	If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
		
		FilterPeriod = "T.Month BETWEEN &BeginOfPeriod AND &EndOfPeriod";
		
		Query.SetParameter("BeginOfPeriod", BegOfMonth(BeginOfPeriod));
		Query.SetParameter("EndOfPeriod",  EndOfMonth(EndOfPeriod));
		
	ElsIf ValueIsFilled(BeginOfPeriod) Then
		
		FilterPeriod = "T.Month >= &BeginOfPeriod";
		
		Query.SetParameter("BeginOfPeriod", BegOfMonth(BeginOfPeriod));
		
	ElsIf ValueIsFilled(EndOfPeriod) Then
		
		FilterPeriod = "T.Month <= &EndOfPeriod";
		
		Query.SetParameter("EndOfPeriod",  EndOfMonth(EndOfPeriod));
		
	EndIf;
	
	If ValueIsFilled(FilterOrganization) And ValueIsFilled(FilterPeriod) Then
		TextSelection_ = FilterOrganization + " And " + FilterPeriod;
		
	ElsIf ValueIsFilled(FilterOrganization) Then
		TextSelection_ = FilterOrganization;
		
	ElsIf ValueIsFilled(FilterPeriod) Then
		TextSelection_ = FilterPeriod;
		
	Else
		TextSelection_ = "TRUE";
	
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&Filter", TextSelection_);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordSet = InformationRegisters.JobsForCalculatingCost.CreateRecordSet();
		
		RecordSet.Filter.Month.Set(Selection.Month);
		RecordSet.Filter.Organization.Set(Selection.Organization);
		
		RecordSet.Write(True);
		
	EndDo;
	
EndProcedure

// Adds descriptions of registers for connecting them to the no-change date mechanism.
//
Procedure DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources) Export
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.MaterialsAndWorksInProduction.FullName(),
										"Period",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.RevenueAndCOGS.FullName(),
										"Period",
										"FinancialOutline");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.ItemisedExpensesLots.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.OtherExpenses.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.InventoryCost.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.GoodsCostVariances.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.CompanyGoods.FullName(),
										"Period",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.CompanyGoodsForTransfer.FullName(),
										"Period",
										"RoutineOperations",
										"CompanyOwner");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.GoodsTransferredToCommissionAgent.FullName(),
										"Period",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor.FullName(),
										"Period",
										"FinancialOutline");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.ProductsRelease.FullName(),
										"Period",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.OtherWorkInProgressExpenses.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.WIPLaborCosts.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.FutureExpenseCommitments.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	CalculationOfCostLocalization.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	
EndProcedure

// Returns the date - the beginning of the month, not the calculated period for the transferred company.
//
// Parameters:
//  Organization - CatalogRef.Companies - The organization for which you need to get the date of the period that was not calculated.
//
// Returns:
//  Date - The date of the non-calculated period for the transferred company. If there is no entry in the register for the transferred company, an empty date is returned.
//
Function GetUnCalculatedPeriodForOrganization(Organization) Export
	
	Query = New Query();
	Query.SetParameter("Organization", Organization);
	Query.Text = "SELECT
		|	BEGINOFPERIOD(MIN(Jobs.Month), Month) AS Period
		|FROM
		|	InformationRegister.JobsForCalculatingCost AS Jobs
		|WHERE
		|	Jobs.Organization = &Organization
		|
		|HAVING
		|	BEGINOFPERIOD(MIN(Jobs.Month), Month) IS NOT NULL";
		
	QueryResult = Query.Execute().Select();
	If QueryResult.Next() Then
		Return QueryResult.Period;
	EndIf;
	
	Return Date(1, 1, 1);
	
EndFunction

#EndRegion

#EndIf
