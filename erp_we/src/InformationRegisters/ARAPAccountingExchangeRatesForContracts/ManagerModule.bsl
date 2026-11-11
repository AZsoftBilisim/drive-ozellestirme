
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then


#Region Internal

// Function - Get the values of the Contract currency exchange rate
//
// Parameters:
//  Contract		 - 	CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - The Contract under which the course is set
//  DateOfCourse	 - 	Date - the date on which the course is obtained
// 
// Returns:
//  Structure:
//   * Contract - CatalogRef.CounterpartyContracts, 
//               Reference link.Agreements between organizations - A Contract with a fixed exchange rate
//   * DateOfCourse - Date - Date Of Course Receipt
//   * CourseNumerator - Number - The numerator of the currency exchange rate on the specified date.
//   * CourseDenominator - Number - The denominator of the currency exchange rate on the specified date.
//
Function GetContractCurrencyExchangeRateValues(Contract, DateOfCourse)Export
	
	Result = GetLast(DateOfCourse, New Structure("Contract", Contract));
	If Not (ValueIsFilled(Result.CourseNumerator) And ValueIsFilled(Result.CourseDenominator)) Then
		Result.CourseNumerator = 1;
		Result.CourseDenominator = 1;
		Result.Insert("CourseIsNotSet", True);
	EndIf;
	Result.Insert("Contract", Contract);
	Result.Insert("DateOfCourse", DateOfCourse);
	
	Return Result;
	
EndFunction

// Function - There are records of the Contract currency exchange rate
//
// Parameters:
//  Contract	  - 	CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - The Contract under which the course is set
// 
// Returns:
//  Boolean - True if the register contains currency exchange rate values for this Contract
//
Function ThereAreRecordsOfContractCurrencyExchangeRate(Contract)Export
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.Contract.Set(Contract);
	RecordSet.Read();
	Return RecordSet.Selected() And RecordSet.Count() > 0;
	
EndFunction

// Deletes course entries under the Contract
//
// Parameters:
//  Contract	 - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract with the exchange rate
//
Procedure ClearCourseHistoryByContract(Contract)Export 
	
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.Contract.Set(Contract);
	RecordSet.Write(True);
	
EndProcedure

// Procedure - Record the values of the Contract currency exchange rate
//
// Parameters:
//  Contract			 - 	CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - The Contract under which the course is set
//  DateOfCourse		 - 	Date - the date on which you need to record the course
//  CourseNumerator	 - 	Number - Exchange rate
//  CourseDenominator	 - 	Number - multiplicity of the course
//
Procedure RecordValuesOfContractCurrencyExchangeRate(Contract, Val DateOfCourse, CourseNumerator, CourseDenominator)Export 
	
	DateOfCourse = BegOfDay(DateOfCourse);
	RecordSet = CreateRecordSet();
	RecordSet.Filter.Contract.Set(Contract);
	RecordSet.Read();
	
	HasChanges = False;
	If RecordSet.Count() = 0 Then
		
		NewRecord = RecordSet.Add();
		NewRecord.Contract         = Contract;
		NewRecord.Period          = Date(1980, 1, 1);
		NewRecord.CourseNumerator   = CourseNumerator;
		NewRecord.CourseDenominator = CourseDenominator;
		NewRecord = RecordSet.Add();
		NewRecord.Contract         = Contract;
		NewRecord.Period          = DateOfCourse;
		NewRecord.CourseNumerator   = CourseNumerator;
		NewRecord.CourseDenominator = CourseDenominator;
		HasChanges = True;
		
	Else
		
		VTOfCourses = RecordSet.Unload();
		VTOfCourses.Indexes.Add("Period");
		VTOfCourses.Sort("Period");
		// Looking for the latest course record
		ID = 0;
		While ID < VTOfCourses.Count() 
			And VTOfCourses[ID].Period < DateOfCourse Do
			ID = ID + 1;
		EndDo;
		If ID < VTOfCourses.Count()
			And VTOfCourses[ID].Period = DateOfCourse Then
			// There is already an entry for the course date - we replace it only if the values have changed
			If (VTOfCourses[ID].CourseNumerator <> CourseNumerator
				Or VTOfCourses[ID].CourseDenominator <> CourseDenominator) Then 
				// There is already an entry for the course date - you need to replace
				VTOfCourses[ID].CourseNumerator   = CourseNumerator;
				VTOfCourses[ID].CourseDenominator = CourseDenominator;
				HasChanges = True;
			EndIf;
		ElsIf ID = 0 
			Or VTOfCourses[ID-1].CourseNumerator <> CourseNumerator
			Or VTOfCourses[ID-1].CourseDenominator <> CourseDenominator Then 
			// Do I need to add a record earlier than the existing 
			// ones or are there changes compared to the previous record
			NewRecord = VTOfCourses.Insert(ID);
			NewRecord.Contract         = Contract;
			NewRecord.Period          = DateOfCourse;
			NewRecord.CourseNumerator   = CourseNumerator;
			NewRecord.CourseDenominator = CourseDenominator;
			HasChanges = True;
		EndIf;
		If VTOfCourses[0].Period = Date(1980, 1, 1) Then 
			If VTOfCourses.Count() = 2
				And (VTOfCourses[0].CourseNumerator <> VTOfCourses[1].CourseNumerator
					Or VTOfCourses[0].CourseDenominator <> VTOfCourses[1].CourseDenominator) Then 
				// If you have changed the course in the Contract that you have already written down today, you need to update it in the record for 1980.01.01
				VTOfCourses[0].CourseNumerator   = VTOfCourses[1].CourseNumerator;
				VTOfCourses[0].CourseDenominator = VTOfCourses[1].CourseDenominator;
				HasChanges = True;
			EndIf;
		Else
			// It is necessary to add an entry for 1980.01.01 if it does not exist
			NewRecord = VTOfCourses.Add();
			NewRecord.Contract         = Contract;
			NewRecord.Period          = Date(1980, 1, 1);
			NewRecord.CourseNumerator   = VTOfCourses[0].CourseNumerator;
			NewRecord.CourseDenominator = VTOfCourses[0].CourseDenominator;
			HasChanges = True;
		EndIf;
		
		If HasChanges Then
			RecordSet.Load(VTOfCourses);
		EndIf;
		
	EndIf;
	
	If HasChanges Then
		RecordSet.Write();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
