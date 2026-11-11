
#Region Internal

#Region ActionsWithAccruals

// Returns a structure for storing accrual data.
//
// Returns:
//   Structure - contains the keys "Organization", "Month of registration" and "Calculation table":
//					* Organization - CatalogRef.Companies
//					* RegistrationMonth - Date
//					* AccrualTable - ValueTable - Accrual table.
Function StructureOfAccrualDataRecords() Export
	
	DataRecords = New Structure("Organization, RegistrationMonth, AccrualTable",
		New TypeDescription("CatalogRef.Companies"),
		New TypeDescription("Date"),
		New TypeDescription("ValueTable"));
	
	Return DataRecords;
	
EndFunction
	
// Creates an accrual table for payroll.
//
// Returns:
//   ValueTable - a table with columns for storing accrual data
Function CreateAccrualTable() Export
	
	AccrualTable = New ValueTable();
	AccrualTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	AccrualTable.Columns.Add("Individual", New TypeDescription("CatalogRef.Persons")); 
	AccrualTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	AccrualTable.Columns.Add("Employee", New TypeDescription("CatalogRef.EmployeesHR"));
	AccrualTable.Columns.Add("Accrual", New TypeDescription("CatalogRef.AccrualAndDeductionKinds"));
	AccrualTable.Columns.Add("PayCode", New TypeDescription("CatalogRef.PayCodesHR"));
	AccrualTable.Columns.Add("Sum", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	AccrualTable.Columns.Add("HoursWorked", New TypeDescription("Number"));
	AccrualTable.Columns.Add("DaysWorked", New TypeDescription("Number"));
	AccrualTable.Columns.Add("Base", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	AccrualTable.Columns.Add("NormalWorkdays", New TypeDescription("Number"));
	AccrualTable.Columns.Add("NormOfHours", New TypeDescription("Number"));
	AccrualTable.Columns.Add("CalculationFormula", New TypeDescription("String"));
	AccrualTable.Columns.Add("ManualAccrual", New TypeDescription("Boolean"));
	AccrualTable.Columns.Add("RowID", Common.StringTypeDetails(36));
	AccrualTable.Columns.Add("Period", New TypeDescription("Date"));
	AccrualTable.Columns.Add("PostingOption", New TypeDescription("EnumRef.AccrualsDeductionsRecordOptions"));
	AccrualTable.Columns.Add("MandatoryAccrual", New TypeDescription("Boolean"));
	AccrualTable.Columns.Add("InputFrequency", New TypeDescription("Number"));   
	AccrualTable.Columns.Add("PeriodEnding", New TypeDescription("Date"));
	
	Return AccrualTable;
EndFunction	

// Records the accrual table in the Accumulation register "Accrual" for the specified registration document.
//
// Parameters:
//   RecordData - Structure - contains data for recording the accrual table:
//       * Organization - CatalogRef.Companies - The company for which registration is being performed.
//       * RegistrationMonth - Date - the month for which registration is performed.
//       * AccrualTable - ValueTable - a table with accrual data.
//       	* Employee - CatalogRef.EmployeesHR - the employee for whom the accrual is performed.
//       	* Department - CatalogRef.BusinessStructure - the division for which the accrual is performed.
//       	* Accrual - CatalogRef.AccrualAndDeductionKinds - type of accrual.
//       	* Sum - Number - accrual amount.
//       	* HoursWorked - Number - the number of hours worked.
//       	* DaysWorked - Number - the number of days worked.
//       	* Base - Number - accrual base.
//       	* NormalWorkdays - Number - the norm of days.
//       	* NormOfHours - Number - the norm of hours.
//       	* ManualAccrual - Boolean - indicates manual accrual.
//       	* RowID - String - Unique ID of the string.
//       	* Period - Date - Accrual date.
//       	* PostingOption - EnumRef.AccrualsDeductionsRecordOptions - Accrual reflection option.
//       	* MandatoryAccrual - Boolean - indicates mandatory accrual.
//       	* InputFrequency - Number - The time fence of input.
//
Procedure WriteDownAccrualTable(RecordData) Export
	
	Organization = RecordData.Organization;
	RegistrationMonth = RecordData.RegistrationMonth;
	AccrualTable = RecordData.AccrualTable;
	EmployeeTable = AccrualTable.Copy(,"Employee");
	EmployeeTable.GroupBy("Employee");
	SelectionByDetails = New Structure("Employee");
	
	DocumentRegistrations = FindPayrollRegistrationDocument(Organization, RegistrationMonth);
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.AccrualsHR.RecordSet");
	LockItem.SetValue("Recorder", DocumentRegistrations);
	
	BeginTransaction();
	Try
		
		Block.Lock();
		SetPrivilegedMode(True);
		
		SetOfAccrualRegisterEntries = AccumulationRegisters.AccrualsHR.CreateRecordSet();
		SetOfAccrualRegisterEntries.Filter.Recorder.Set(DocumentRegistrations);
		SetOfAccrualRegisterEntries.Read();
		OldRecords = SetOfAccrualRegisterEntries.Unload();
		
		For Each CurrentRow In EmployeeTable Do
			
			SelectionByDetails.Employee = CurrentRow.Employee;
			OldEmployeeRecords = OldRecords.Copy(SelectionByDetails);
			NewRecords = AccrualTable.FindRows(SelectionByDetails);
			
			SetOfAccrualRegisterEntriesForRecording = AccumulationRegisters.AccrualsHR.CreateRecordSet();
			SetOfAccrualRegisterEntriesForRecording.Filter.Recorder.Set(DocumentRegistrations);
			
			For Each CurrentRowForNewEntries In NewRecords Do
				
				NewRecord = SetOfAccrualRegisterEntriesForRecording.Add();
				FillPropertyValues(NewRecord, CurrentRowForNewEntries);
				NewRecord.Recorder = DocumentRegistrations;
				
			EndDo;	
			
			ComparisonTableByEmployee = Common.SetRecordsChange(OldEmployeeRecords, SetOfAccrualRegisterEntriesForRecording, True);
			
			AddedRows = ComparisonTableByEmployee.FindRows(New Structure("LineChangeType", 1));
			DeletedRows = ComparisonTableByEmployee.FindRows(New Structure("LineChangeType", -1));
			ModifiedLines = ComparisonTableByEmployee.FindRows(New Structure("LineChangeType", 0));
			
			RecordSetOfRecordsByEmployee("AccrualsHR", DocumentRegistrations, DeletedRows,        ReplacementMode.Delete);
			RecordSetOfRecordsByEmployee("AccrualsHR", DocumentRegistrations, AddedRows,      ReplacementMode.Append);
			RecordSetOfRecordsByEmployee("AccrualsHR", DocumentRegistrations, ModifiedLines, ReplacementMode.Update);
			
		EndDo;	
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region ActionsWithDeductions

// Creates a retention table for payroll.
//
// Returns:
//   ValueTable - a table with columns for storing information about deductions:
//     * Organization - CatalogRef.Companies
//     * Individual - CatalogRef.Persons
//     * Period - Date
//     * Employee - CatalogRef.EmployeesHR
//     * Department - CatalogRef.BusinessStructure
//     * Retention - CatalogRef.AccrualAndDeductionKinds
//     * Sum - Number
//     * ManualDeduction - Boolean
//     * RowID - String
//     * PostingOption - EnumRef.AccrualsDeductionsRecordOptions
//     * MandatoryRetention - Boolean
//     * InputFrequency - Number
Function CreateRetentionTable() Export
	
	RetentionTable = New ValueTable();
	RetentionTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	RetentionTable.Columns.Add("Individual", New TypeDescription("CatalogRef.Persons"));
	RetentionTable.Columns.Add("Period", New TypeDescription("Date"));
	RetentionTable.Columns.Add("Employee", New TypeDescription("CatalogRef.EmployeesHR"));
	RetentionTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	RetentionTable.Columns.Add("Retention", New TypeDescription("CatalogRef.AccrualAndDeductionKinds"));
	RetentionTable.Columns.Add("Sum", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	RetentionTable.Columns.Add("ManualDeduction", New TypeDescription("Boolean"));
	RetentionTable.Columns.Add("RowID", Common.StringTypeDetails(36));
	RetentionTable.Columns.Add("PostingOption", New TypeDescription("EnumRef.AccrualsDeductionsRecordOptions"));
	RetentionTable.Columns.Add("MandatoryRetention", New TypeDescription("Boolean"));
	RetentionTable.Columns.Add("InputFrequency", New TypeDescription("Number")); 
	RetentionTable.Columns.Add("PeriodEnding", New TypeDescription("Date"));
	
	Return RetentionTable;
EndFunction	

// Returns a structure for storing retention data.
//
// Returns:
//   Structure - contains the keys "Organization", "Month of registration" and "Table of contents" and "Table of Statuses":
//   *	Organization - CatalogRef.Companies - The company for which the data is generated
//   *	RegistrationMonth - Date - the month for which the data is generated
//   *	RetentionTable - ValueTable - Retention Table
//   *	StatusTable - ValueTable - table of retention statuses
// 
Function StructureOfRetentionDataRecords() Export
   
    // Structure for storing retention data
    DataRecords = New Structure(); 
    DataRecords.Insert("Organization", Undefined);
    DataRecords.Insert("RegistrationMonth", Undefined);
    DataRecords.Insert("RetentionTable", Undefined);
    DataRecords.Insert("StatusTable", Undefined);
    
    Return DataRecords;
    
EndFunction
	

// Records the retention table in the Accumulation register "Deduction" according to the specified registration document.
//
// Parameters:
//   RecordData - Structure - contains data for recording the retention table:
//       * Organization - CatalogRef.Companies - The company that the record is being made for.
//       * RegistrationMonth - Date - the month for which registration is performed.
//       * RetentionTable - ValueTable - a table with data on deductions.
Procedure  WriteRetentionTable(RecordData) Export
	
	Organization = RecordData.Organization;
	RegistrationMonth = RecordData.RegistrationMonth;
	RetentionTable = RecordData.RetentionTable;
	StatusTable = RecordData.StatusTable;
	EmployeeTable = StatusTable.Copy(,"Employee");
	EmployeeTable.GroupBy("Employee");
	SelectionByDetails = New Structure("Employee");
	
	DocumentRegistrations = FindPayrollRegistrationDocument(Organization, RegistrationMonth);
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.DeductionsHR.RecordSet");
	LockItem.SetValue("Recorder", DocumentRegistrations);

	BeginTransaction();
	Try
		
		Block.Lock();
		SetPrivilegedMode(True);
	
		SetOfRetentionRegisterEntries = AccumulationRegisters.DeductionsHR.CreateRecordSet();
		SetOfRetentionRegisterEntries.Filter.Recorder.Set(DocumentRegistrations);
		SetOfRetentionRegisterEntries.Read();
		OldRecords = SetOfRetentionRegisterEntries.Unload();
		
		For Each CurrentRow In EmployeeTable Do
			
			SelectionByDetails.Employee = CurrentRow.Employee;
			OldEmployeeRecords = OldRecords.Copy(SelectionByDetails);
			NewRecords = RetentionTable.FindRows(SelectionByDetails);
			
			SetOfRetentionRegisterEntriesForRecording = AccumulationRegisters.DeductionsHR.CreateRecordSet();
			SetOfRetentionRegisterEntriesForRecording.Filter.Recorder.Set(DocumentRegistrations);
			
			For Each CurrentRowForNewEntries In NewRecords Do
				
				NewRecord = SetOfRetentionRegisterEntriesForRecording.Add();
				FillPropertyValues(NewRecord, CurrentRowForNewEntries);
				NewRecord.Recorder = DocumentRegistrations;
				
			EndDo;	
			
			ComparisonTableByEmployee = Common.SetRecordsChange(OldEmployeeRecords, SetOfRetentionRegisterEntriesForRecording, True);
			
			AddedRows = ComparisonTableByEmployee.FindRows(New Structure("LineChangeType", 1));
			DeletedRows = ComparisonTableByEmployee.FindRows(New Structure("LineChangeType", -1));
			ModifiedLines = ComparisonTableByEmployee.FindRows(New Structure("LineChangeType", 0));
			
			RecordSetOfRecordsByEmployee("DeductionsHR", DocumentRegistrations, DeletedRows,        ReplacementMode.Delete);
			RecordSetOfRecordsByEmployee("DeductionsHR", DocumentRegistrations, AddedRows,      ReplacementMode.Append);
			RecordSetOfRecordsByEmployee("DeductionsHR", DocumentRegistrations, ModifiedLines, ReplacementMode.Update);
			
		EndDo;	
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	
EndProcedure

#EndRegion

#Region ActionsWithTaxes

// Creates a table of taxes for payroll.
//
// Returns:
//   ValueTable - a table with columns for storing tax information
Function CreateTaxTable() Export
	
	TaxTable = New ValueTable();
	TaxTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	TaxTable.Columns.Add("Individual", New TypeDescription("CatalogRef.Persons"));
	TaxTable.Columns.Add("Employee", New TypeDescription("CatalogRef.EmployeesHR"));
	TaxTable.Columns.Add("TaxKind", New TypeDescription("CatalogRef.TaxContributionKinds"));
	TaxTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	TaxTable.Columns.Add("Period", New TypeDescription("Date"));
	TaxTable.Columns.Add("Sum", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	TaxTable.Columns.Add("ManualTax", New TypeDescription("Boolean"));
	TaxTable.Columns.Add("RowID", Common.StringTypeDetails(36));
	TaxTable.Columns.Add("Base", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	TaxTable.Columns.Add("Deduction", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	TaxTable.Columns.Add("DeductedFromEmployeeWages", New TypeDescription("Boolean"));
	TaxTable.Columns.Add("PostingOption", New TypeDescription("EnumRef.AccrualsDeductionsRecordOptions"));
	TaxTable.Columns.Add("EnteringTaxManually", New TypeDescription("Boolean")); 
	TaxTable.Columns.Add("NonTaxableAmount", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	TaxTable.Columns.Add("Accrual", New TypeDescription("CatalogRef.AccrualAndDeductionKinds"));
	TaxTable.Columns.Add("AccrualRegistrar", New TypeDescription("DocumentRef.OneTimeAccrualsHR"));
	TaxTable.Columns.Add("ThisIsNonTaxableAccrualOfThisTax", New TypeDescription("Boolean"));
	
	Return TaxTable;
EndFunction	

// Returns a structure for storing tax data.
//
// Returns:
//   Structure - contains the keys "Company", "Month of registration" and "Catalog table"
Function StructureOfTaxDataRecords() Export
	
	DataRecords = New Structure("Organization,RegistrationMonth,TaxTable");
	
	Return DataRecords;
	
EndFunction	

// Records the tax table in the Accumulation register "Taxivznosyzik" for the specified payroll registration document.
//
// Parameters:
//   RecordData - Structure - contains data for the tax table entry:
//     * Organization - CatalogRef.Companies - The company for which the record is being made
//     * RegistrationMonth - Date - the month for which registration is performed
//     * TaxTable - ValueTable - table with data on taxes and contributions
Procedure WriteDownTaxTable(RecordData) Export
	
	Organization = RecordData.Organization;
	RegistrationMonth = RecordData.RegistrationMonth;
	TaxTable = RecordData.TaxTable;
	EmployeeTable = TaxTable.Copy(,"Employee");
	EmployeeTable.GroupBy("Employee");
	SelectionByDetails = New Structure("Employee");
	
	DocumentRegistrations = FindPayrollRegistrationDocument(Organization, RegistrationMonth);
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.TaxesContributionsHR.RecordSet");
	LockItem.SetValue("Recorder", DocumentRegistrations);
	
	BeginTransaction();
	Try
		
		Block.Lock();
		SetPrivilegedMode(True);
		
		SetOfTaxRegisterEntries = AccumulationRegisters.TaxesContributionsHR.CreateRecordSet();
		SetOfTaxRegisterEntries.Filter.Recorder.Set(DocumentRegistrations);
		SetOfTaxRegisterEntries.Read();
		OldRecords = SetOfTaxRegisterEntries.Unload(); 
		
		SelectionByDetails = New Structure("Employee");
		
		For Each CurrentRow In EmployeeTable Do
			
			SelectionByDetails.Employee = CurrentRow.Employee;
			OldEmployeeRecords = OldRecords.Copy(SelectionByDetails);
			NewRecords = TaxTable.FindRows(SelectionByDetails);
			
			SetOfTaxRegisterRecordsToRecord = AccumulationRegisters.TaxesContributionsHR.CreateRecordSet();
			SetOfTaxRegisterRecordsToRecord.Filter.Recorder.Set(DocumentRegistrations);
			
			For Each CurrentRowForNewEntries In NewRecords Do
				
				NewRecord = SetOfTaxRegisterRecordsToRecord.Add();
				FillPropertyValues(NewRecord, CurrentRowForNewEntries);
				NewRecord.Recorder = DocumentRegistrations;
				
			EndDo;	
			
			PersonComparisonTable = Common.SetRecordsChange(OldEmployeeRecords,
																		 SetOfTaxRegisterRecordsToRecord, True);
			
			AddedRows = PersonComparisonTable.FindRows(New Structure("LineChangeType", 1));
			DeletedRows = PersonComparisonTable.FindRows(New Structure("LineChangeType", -1));
			ModifiedLines = PersonComparisonTable.FindRows(New Structure("LineChangeType", 0));
			
			RecordSetOfRecordsByEmployee("TaxesContributionsHR", DocumentRegistrations, DeletedRows,        ReplacementMode.Delete);
			RecordSetOfRecordsByEmployee("TaxesContributionsHR", DocumentRegistrations, AddedRows,      ReplacementMode.Append);
			RecordSetOfRecordsByEmployee("TaxesContributionsHR", DocumentRegistrations, ModifiedLines, ReplacementMode.Update);
			
		EndDo;		
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region WorkingWithRegistrationDocument

// Returns a link to the payroll registration document for the specified organization and the month of registration.
// If the document is not found, creates a new one.
//
// Parameters:
//   Organization - CatalogRef.Companies - The company for which registration is being performed
//   RegistrationMonth - Date - the month for which registration is performed
//
// Returns:
//   DocumentRef.RegisterPayrollCalculation - link to the payroll registration document
//
Function FindPayrollRegistrationDocument(Organization, RegistrationMonth) Export 
		
	Query = New Query();
	Query.Text = 
	"SELECT
	|	RegisterPayrollCalculation.Ref
	|FROM
	|	Document.RegisterPayrollCalculation AS RegisterPayrollCalculation
	|WHERE
	|	RegisterPayrollCalculation.Organization = &Organization
	|	AND RegisterPayrollCalculation.Date = &RegistrationMonth
	|	AND RegisterPayrollCalculation.DeletionMark = FALSE";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("RegistrationMonth", RegistrationMonth);
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		Return Result.Ref;
	EndIf;

	DocumentRegistrations = Documents.RegisterPayrollCalculation.CreateDocument();
	DocumentRegistrations.Date = RegistrationMonth;
	DocumentRegistrations.Organization = Organization;
	DocumentRegistrations.Write();
	
	Return DocumentRegistrations.Ref;
	
EndFunction	

#EndRegion

#EndRegion

#Region Private

Procedure RecordSetOfRecordsByEmployee(NameOfAccumulationRegister, DocumentRegistrations, ArrayOfLinesToWrite, RecordSubstitutionMode)
	
	If ArrayOfLinesToWrite.Count() = 0 Then
		Return;
	EndIf;	
	
	SetOfRegisterEntriesForRecordingByEmployee = AccumulationRegisters[NameOfAccumulationRegister].CreateRecordSet();
	SetOfRegisterEntriesForRecordingByEmployee.ExtendedReplaceMode = True;
	SetOfRegisterEntriesForRecordingByEmployee.Filter.Recorder.Set(DocumentRegistrations); 
	
	If RecordSubstitutionMode = ReplacementMode.Delete Then
		ArrayOfEmployees = New Array(); 
			For Each CurrentStringArray In ArrayOfLinesToWrite Do
				If ArrayOfEmployees.Find(CurrentStringArray.Employee) = Undefined Then
					ArrayOfEmployees.Add(CurrentStringArray.Employee);  
				EndIf;	
			EndDo;	
		ArrayOfRecordsToDelete = New Array();	
			
		SetOfRegisterEntriesForRecordingByEmployee.Read();
		For Each CurrentRow In SetOfRegisterEntriesForRecordingByEmployee Do  
			
			If ArrayOfEmployees.Find(CurrentRow.Employee) <> Undefined Then				
					ArrayOfRecordsToDelete.Add(CurrentRow);
			EndIf;	
				
		EndDo;	
		
		For Each CurrentRowArrayOfRecordsToDelete In ArrayOfRecordsToDelete Do
			SetOfRegisterEntriesForRecordingByEmployee.Delete(CurrentRowArrayOfRecordsToDelete);
		EndDo;	
		
		SetOfRegisterEntriesForRecordingByEmployee.Write(True);	
	
	Else
		
		For Each CurrentRow In ArrayOfLinesToWrite Do  
			FillPropertyValues(SetOfRegisterEntriesForRecordingByEmployee.Add(), CurrentRow);
			SetOfRegisterEntriesForRecordingByEmployee.Write(RecordSubstitutionMode);	
		EndDo;	

		SetOfRegisterEntriesForRecordingByEmployee.Write(RecordSubstitutionMode);	
		
	EndIf;	
		
EndProcedure	

#EndRegion
