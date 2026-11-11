#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region StageStatus

// The procedure is intended for calling the mechanics of closing the month from outside - from the calculation mechanism of any stage.
// Performs operations of the month closing mechanism that are called before the stage calculation, if the calculation is not called during the month closing.
// When you close a month, the month closing mechanism itself performs these actions.
//
Procedure PerformOperationsToPrepareForStageCalculation(Stage, Period, CompanyArray) Export
	
	// We will perform checks before calculating the stage.
	StructureOfData 	 = InitializeDataStructureToPopulateState(Period, CompanyArray);
	StageTableRow  = StructureOfData.TableStages.Find(Stage, "Code");
	HandlerParameters = InitializeStageHandlerParameters(StructureOfData, StageTableRow);
	
	PerformStageChecks(StructureOfData, StageTableRow, HandlerParameters, True, False);
	
	// Let's clear the errors diagnosed during the last calculation.
	ClearResultsOfChecksBeforeCalculation(Stage, StructureOfData.CalculationParameters);
	
EndProcedure

// The procedure is intended for calling the mechanics of closing the month from outside - from the calculation mechanism of any stage.
// Performs operations of the month closing mechanism that are called after the stage calculation, if the calculation was not called during the
// month closing. When you close a month, the month closing mechanism itself performs these actions.
//
Procedure PerformOperationsToCompleteStageCalculation(Stage, Period, CompanyArray) Export
	
	// We will perform checks after calculating the stage.
	StructureOfData 	 = InitializeDataStructureToPopulateState(Period, CompanyArray);
	StageTableRow  = StructureOfData.TableStages.Find(Stage, "Code");
	HandlerParameters = InitializeStageHandlerParameters(StructureOfData, StageTableRow);
	
	PerformStageChecks(StructureOfData, StageTableRow, HandlerParameters, False, True);
	
EndProcedure

// Initializes the parameter structure of the stage handler.
// 
// Parameters:
// 	StructureOfData - Structure, Undefined - LongDesc:
// 	StageTableRow - Structure, Undefined, ValueTableRow - LongDesc:
// 	AuxProperties - Structure, Undefined - LongDesc:
// 	KeyOperationName - Undefined, String - LongDesc
// 	
// Returns:
// 	Structure - LongDesc:
// * ExplanationTable_ - See DataProcessors.MonthEndClosingOperations.InitializeStepExplanationTable
// * CalculationParameters - See DataProcessors.MonthEndClosingOperations.InitializeStartupParametersForCalculatingStages
// * Data_Stage - Structure -
// * DataVolume - Number -
// * DescriptionOfPerformanceMeasurement - See PerformanceMonitor.StartTimeConsumingOperationMeasurement
// * OperationalAccounting - Boolean -
// * LocalAccounting - Boolean -
// * FinancialAccounting - Boolean -
// * AutoTesting - Boolean -
// * CalculationID - UUID -
// * MonthEndClosingMode - Arbitrary, Undefined -
// * OnlyOneOrganization - Boolean -
//
Function InitializeStageHandlerParameters(StructureOfData, StageTableRow,
			AuxProperties = Undefined, KeyOperationName = Undefined) Export
	
	HandlerParameters = New Structure;
	
	If ValueIsFilled(KeyOperationName) Then
		HandlerParameters.Insert("DescriptionOfPerformanceMeasurement", PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperationName));
	EndIf;
	
	HandlerParameters.Insert("DataVolume", 			    0); // to measure performance
	
	HandlerParameters.Insert("Data_Stage",				    TMCommonUse.ConvertTableRowToStructure(StageTableRow));
	HandlerParameters.Insert("CalculationParameters",  			    StructureOfData.CalculationParameters);
	HandlerParameters.Insert("ExplanationTable_", 			    InitializeStepExplanationTable());
	HandlerParameters.Insert("CalculationID", 	 	 	New UUID);
	
	If ValueIsFilled(AuxProperties) Then
		HandlerParameters.Insert("OperationalAccounting", 	   	    AuxProperties.OperationalAccounting);
		HandlerParameters.Insert("LocalAccounting",     AuxProperties.LocalAccounting);
		HandlerParameters.Insert("FinancialAccounting", 		    AuxProperties.FinancialAccounting);
		If AuxProperties.Property("OnlyOneOrganization") Then
			HandlerParameters.Insert("OnlyOneOrganization",  AuxProperties.OnlyOneOrganization);
		Else
			HandlerParameters.Insert("OnlyOneOrganization",  False);
		EndIf;
	Else
		HandlerParameters.Insert("OperationalAccounting", 	   	    True);
		HandlerParameters.Insert("LocalAccounting",     True);
		HandlerParameters.Insert("FinancialAccounting", 		    True);
		HandlerParameters.Insert("OnlyOneOrganization",		False);
	EndIf;
	
	If ValueIsFilled(AuxProperties) And AuxProperties.Property("AutoTesting") Then
		HandlerParameters.Insert("AutoTesting", AuxProperties.AutoTesting);
	Else
		HandlerParameters.Insert("AutoTesting", False);
	EndIf;
	
	If ValueIsFilled(AuxProperties) And AuxProperties.Property("MonthEndClosingMode") Then
		HandlerParameters.Insert("MonthEndClosingMode", AuxProperties.MonthEndClosingMode);
	Else
		HandlerParameters.Insert("MonthEndClosingMode", Undefined);
	EndIf;
	
	Return HandlerParameters;
	
EndFunction

#EndRegion

#Region DescriptionOfStages

// Called from outside of processing.
//
// Parameters:
//  IBUpdate - Boolean - When Transferring a value, True returns all operations of operations, regardless of the set values
//                          of the functional options. It is used to update the directory of operationsaccurations of the month.
// 
// Returns:
// See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
//
Function FillInDescriptionOfClosingStagesOfMonth(IBUpdate = False) Export
	
	StepsTable = InitializeStepDescriptionTable();
	
	MonthEndTransactionsServer.FillInDescriptionOfClosingStagesOfMonth(StepsTable);
	
	If Not IBUpdate Then
		For Each Stage In StepsTable Do
			If Stage.DisabledByFO Then
				StepsTable.Delete(Stage);
			EndIf;
		EndDo;
	EndIf;
	
	OrganizeClosingStagesOfMonth(StepsTable);
	
	// Filling in the default fields.
	For Each CurrentRow In StepsTable Do
		
		If Not ValueIsFilled(CurrentRow.Description) Then
			CurrentRow.Description = TrimAll(CurrentRow.Code);
		EndIf;
		
		CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.Undefined;
		
	EndDo;
	
	Return StepsTable;
	
EndFunction

// Creates a table describing the closing stages of the month.
// 
// Returns:
// 	ValueTable - LongDesc:
// * Code - CatalogRef.MonthEndClosingOperations -
// * Description - String -
// * MultilingualName - String -
// * Parent - String -
// * StageNumber - Number -
// * PerformedManually - Boolean -
// * informational - Boolean -
// * DisplayCompletedSuccessfully - Boolean -
// * PreviousStages_ - Array of CatalogRef.MonthEndClosingOperations -
// * DependsOnStages - Array of CatalogRef.MonthEndClosingOperations -
// * AffectsStages - Array of CatalogRef.MonthEndClosingOperations -
// * UpdateStateOfStages - Array of CatalogRef.MonthEndClosingOperations -
// * TextExecute - String -
// * ReadMoreText - String -
// * ActionExecute - Structure -
// * ActionMoreDetails - Structure -
// * ActionUse - Structure -
// * ActionDesign - Structure -
// * SettlementStartDate - Date -
// * CompanyArray - Array of CatalogRef.Companies -
// * State - EnumRef.StatesOfMonthEndClosingOperations -
// * DefaultState - EnumRef.StatesOfMonthEndClosingOperations -
// * TypesOfRoutineOperations - Array of EnumRef.PeriodEndTransactionsTypesFinancialAccounting -
// * OperationalAccounting - Boolean -
// * LocalAccounting - Boolean -
// * FinancialAccounting - Boolean -
// * Disabled - Boolean -
// * DisabledByFO - Boolean - The stage is hidden by a functional option
// * Visible - Boolean -
// * RowID - Number -
// * HyperlinkExecute - Boolean -
// * HyperlinkReadMore - Boolean -
// * ThereAreRecordsOfZHR - Boolean -
// * AdditionalProperties - Structure -
// * PreviousStagesAreCompleted - Boolean -
// * ThereIsImportantInformation - Boolean -
// * ThereIsAUsefulTip - Boolean -
//
Function InitializeStepDescriptionTable() Export
	
	StepsTable = New ValueTable;
	StepsTable.Columns.Add("Code",		   		      New TypeDescription("CatalogRef.MonthEndClosingOperations"));
	StepsTable.Columns.Add("Description", 		      New TypeDescription("String"));
	StepsTable.Columns.Add("MultilingualName", New TypeDescription("String"));
	StepsTable.Columns.Add("MultilingualCommentary", New TypeDescription("String"));
	StepsTable.Columns.Add("Parent", 	   		      New TypeDescription("String")); // code of the parent group
	StepsTable.Columns.Add("StageNumber",	      	  New TypeDescription("Number")); // sequence number of the stage
	StepsTable.Columns.Add("PerformedManually", 	  New TypeDescription("Boolean")); // if True, it will be skipped when calculating the stages
	StepsTable.Columns.Add("informational", 	  	  New TypeDescription("Boolean")); // If True, then the state of the stage will not affect the overall closing state of the month.
	StepsTable.Columns.Add("DisplayCompletedSuccessfully", New TypeDescription("Boolean")); // used for manual checks; by default, successful checks are not displayed in the forms	
	StepsTable.Columns.Add("PerformedAtPreliminaryClosingOfMonth", New TypeDescription("Boolean")); // if True, the stage will be executed at the preliminary closing of the month 
	
	StepsTable.Columns.Add("FollowsStage",		  New TypeDescription("CatalogRef.MonthEndClosingOperations")); // for ordering - the previous stage in the stage tree
	StepsTable.Columns.Add("PreviousStages_",     New TypeDescription("Array")); // codes of the predecessor stages; the state of the current stage will depend on their state
	StepsTable.Columns.Add("UpdateStateOfStages", New TypeDescription("Array")); // codes of previous stages, the status of which must be updated after the end of the calculation of the current stage
	StepsTable.Columns.Add("DependsOnStages", 		  New TypeDescription("Array")); // extending the property of the preceding stages - all stages are recursively added, they are preceding
	StepsTable.Columns.Add("AffectsStages", 		  New TypeDescription("Array")); // the codes of the following stages, the State of which depends on the Cur; in fact, this is the property of the dependent stages "vice versa"
	
	StepsTable.Columns.Add("TextExecute", 	      New TypeDescription("String"));
	StepsTable.Columns.Add("ReadMoreText", 	      New TypeDescription("String"));
	
	StepsTable.Columns.Add("ActionExecute",       New TypeDescription("Structure"));
	StepsTable.Columns.Add("ActionMoreDetails",       New TypeDescription("Structure"));
	
	StepsTable.Columns.Add("ActionUse",   New TypeDescription("Structure"));
	StepsTable.Columns.Add("ActionDesign",      New TypeDescription("Structure"));
	
	StepsTable.Columns.Add("SettlementStartDate",    	  New TypeDescription("Date"));   // the date from which the recalculation is required
	StepsTable.Columns.Add("CompanyArray",   	  New TypeDescription("Array")); // organizations for which the calculation will actually be performed
	
	StepsTable.Columns.Add("State",   		      New TypeDescription("EnumRef.StatesOfMonthEndClosingOperations"));
	StepsTable.Columns.Add("DefaultState",    New TypeDescription("EnumRef.StatesOfMonthEndClosingOperations")); // if the "Use" procedure is not used
	StepsTable.Columns.Add("StateFromCache",
		New TypeDescription("EnumRef.StatesOfMonthEndClosingOperations")); // Month closing State of operation from the "Month Closing Stepstates" information register
	
	StepsTable.Columns.Add("TypesOfRoutineOperations",New TypeDescription("Array")); // correspondence to the values of the enumeration of the same name
	
	// The type of accounting to which the stage belongs.
	StepsTable.Columns.Add("OperationalAccounting",         New TypeDescription("Boolean"));
	StepsTable.Columns.Add("LocalAccounting",  New TypeDescription("Boolean"));
	StepsTable.Columns.Add("FinancialAccounting",       New TypeDescription("Boolean"));
	
	// Service columns.
	StepsTable.Columns.Add("Disabled",   		   	  New TypeDescription("Boolean"));
	StepsTable.Columns.Add("DisabledByFO",           New TypeDescription("Boolean"));
	StepsTable.Columns.Add("Visible",   		      New TypeDescription("Boolean"));
	StepsTable.Columns.Add("RowID",     New TypeDescription("Number"));
	StepsTable.Columns.Add("HyperlinkExecute",    New TypeDescription("Boolean"));
	StepsTable.Columns.Add("HyperlinkReadMore",    New TypeDescription("Boolean"));
	StepsTable.Columns.Add("ThereAreRecordsOfZHR",    	      New TypeDescription("Boolean")); // the presence of errors in the previous calculation
	StepsTable.Columns.Add("AdditionalProperties",  New TypeDescription("Structure"));
	StepsTable.Columns.Add("PreviousStagesAreCompleted", New TypeDescription("Boolean"));
	
	StepsTable.Columns.Add("ThereIsImportantInformation",    New TypeDescription("Boolean"));
	StepsTable.Columns.Add("ThereIsAUsefulTip",    	  New TypeDescription("Boolean"));
	
	// Adding field indexes.
	StepsTable.Indexes.Add("Code");
	StepsTable.Indexes.Add("Parent");
	
	Return StepsTable;
	
EndFunction

#EndRegion

#Region CalculationOfStages

// Registers errors detected during the calculation.
//
// Parameters:
//	HandlerParameters - See InitializeStageHandlerParameters
//
Procedure RegisterStageCalculationProblems(HandlerParameters) Export

	For Each ErrorDescription In HandlerParameters.ExplanationTable_ Do
		
		RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
			HandlerParameters.Data_Stage.Code,
			?(ValueIsFilled(ErrorDescription.Organization),
				ErrorDescription.Organization,
				HandlerParameters.CalculationParameters.CompanyArray),
			HandlerParameters.CalculationParameters.RegistrationPeriod);
			
		MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
			RegistrationParameters,
			Enums.AccountingIssueSeverity.ProblemTextTemplateCodeExecutionError(ErrorDescription.State),
			ErrorDescription.State,
			ErrorDescription.Description,
			ErrorDescription.DecodingError);
		
	EndDo;
	
	HandlerParameters.ExplanationTable_.Clear();
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "Form" Then
		FormFromSettings = Common.CommonSettingsStorageLoad(
			"DataProcessor.MonthEndClosingOperations",
			"DefaultForm",
			"DataProcessor.MonthEndClosingOperations.Form.MonthEndTransactions25");

		If Not FormFromSettings = Undefined Then
			SelectedForm = FormFromSettings;
			StandardProcessing = False;
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region Private

#Region DescriptionOfStageTree

#Region DescriptionOfStageGroups

// Creates a table describing groups of monthly closing stages.
// 
// Returns:
// 	ValueTable - LongDesc:
// * Code - String -
// * Description - String -
// * Parent - String -
// * State - EnumRef.StatesOfMonthEndClosingOperations -
// * Disabled - Boolean -
// * Visible - Boolean -
// * RowID - Number -
//
Function InitializeStageGroupDescriptionTable() Export
	
	TableOfStageGroups = New ValueTable;
	TableOfStageGroups.Columns.Add("Code", 				      New TypeDescription("String"));
	TableOfStageGroups.Columns.Add("Description", 	      New TypeDescription("String"));
	TableOfStageGroups.Columns.Add("InternationalDescription", New TypeDescription("String"));
	TableOfStageGroups.Columns.Add("Parent", 		      New TypeDescription("String")); // code of the parent group
	
	// Service columns.
	TableOfStageGroups.Columns.Add("State",   		      New TypeDescription("EnumRef.StatesOfMonthEndClosingOperations"));
	TableOfStageGroups.Columns.Add("Disabled",   		      New TypeDescription("Boolean"));
	TableOfStageGroups.Columns.Add("Visible",   		      New TypeDescription("Boolean"));
	TableOfStageGroups.Columns.Add("RowID",    New TypeDescription("Number"));
	
	// Adding field indexes.
	TableOfStageGroups.Indexes.Add("Code");
	
	Return TableOfStageGroups;
	
EndFunction

Function FillInDescriptionOfGroupsOfStagesForClosingMonth()
	
	TableOfStageGroups = InitializeStageGroupDescriptionTable();
	
	MonthEndTransactionsServer.FillInDescriptionOfGroupsOfStagesForClosingMonth(TableOfStageGroups);
	
	// Filling in the default fields.
	TableOfStageGroups.FillValues(Enums.StatesOfMonthEndClosingOperations.Undefined, "State");
	
	Return TableOfStageGroups;
	
EndFunction

#EndRegion

#Region DescriptionOfStages

Procedure OrganizeClosingStagesOfMonth(StepsTable)
	
	TableOfStageGroups = FillInDescriptionOfGroupsOfStagesForClosingMonth();
	
	StageTableCopy = StepsTable.Copy();
	GroupStageTable = StepsTable.CopyColumns();
	StepsTable.Clear();
	
	StageTableCopy.Indexes.Add("Parent");
	GroupStageTable.Indexes.Add("Code");
	
	ErrorText = "";
	
	For Each GroupRow In TableOfStageGroups Do
		
		FilterStructure1 = New Structure("Parent", GroupRow.Code);
		
		GroupStages = StageTableCopy.FindRows(FilterStructure1);
		GroupStagesWithOrder = New Array;
		PreviousStages = New Map;
		
		GroupStageTable.Clear();
		
		For Each CurrentStep In GroupStages Do
			
			If Not ValueIsFilled(CurrentStep.FollowsStage) // the previous stage is not specified
			 Or StageTableCopy.Find(CurrentStep.FollowsStage, "Code") = Undefined Then // the previous stage was not found, for example, when cutting the configuration from the ERP
				FillPropertyValues(GroupStageTable.Add(), CurrentStep); // adding the stage in the order it is specified
			Else
				
				GroupStagesWithOrder.Add(CurrentStep);
				
				NumberOfPreviousOnes = PreviousStages.Get(CurrentStep.FollowsStage);
				
				PreviousStages.Insert(
					CurrentStep.FollowsStage,
					?(NumberOfPreviousOnes = Undefined, 0, NumberOfPreviousOnes) + 1);
				
			EndIf;
			
		EndDo;
		
		NumberOfStages = GroupStagesWithOrder.Count();
		
		While NumberOfStages > 0 Do
			
			IndexOfStage = -1;
			
			For Each CurrentStep In GroupStagesWithOrder Do
				
				IndexOfStage = IndexOfStage + 1;
				
				PreviousLine_ = GroupStageTable.Find(CurrentStep.FollowsStage, "Code");
				
				If PreviousLine_ <> Undefined Then
					FillPropertyValues(
						GroupStageTable.Insert(GroupStageTable.IndexOf(PreviousLine_) + 1),
						CurrentStep);
				Else
					
					// The last stage of the previous group can be specified as the previous stage.
					PreviousLine_ = StepsTable.Find(CurrentStep.FollowsStage, "Code");
					
					If PreviousLine_ <> Undefined
					 And StepsTable.IndexOf(PreviousLine_) + 1 = StepsTable.Count() Then
						FillPropertyValues(GroupStageTable.Add(), CurrentStep);
					Else
						PreviousLine_ = Undefined;
					EndIf;
					
				EndIf;
				
				If PreviousLine_ <> Undefined Then
					GroupStagesWithOrder.Delete(IndexOfStage);
					Break;
				EndIf;
				
			EndDo;
			
			If GroupStagesWithOrder.Count() = NumberOfStages Then
				
				For Each CurrentStep In GroupStagesWithOrder Do
					ErrorText = ErrorText + Chars.LF + Catalogs.MonthEndClosingOperations.GetPredefinedItemName(CurrentStep.Code)
				EndDo;
				
				Break;
				
			EndIf;
			
			NumberOfStages = GroupStagesWithOrder.Count();
			
		EndDo;
		
		For Each CurrentStep In GroupStageTable Do
			FillPropertyValues(StepsTable.Add(), CurrentStep);
		EndDo;
		
	EndDo;
	
	If ValueIsFilled(ErrorText) Then
		ErrorText = NStr("vi = 'Đã chỉ ra sai trình tự thao tác đóng tháng';
						|ru = 'Некорректно указан порядок операций закрытия месяца';
						|en = 'Incorrect order of month-end close'; fa = 'Incorrect order of month-end close';
						|it = 'Ordine delle operazioni di chiusura del mese indicato in modo errato';
						|pl = 'Niepoprawnie jest podana kolejność operacji zamknięcia miesiąca';
						|tr = 'Ay sonu kapanışı işlemlerinin hatalı sırası'") + ":" + ErrorText;
		Raise ErrorText;
	EndIf;
	
	StageNumber = 0;
	
	For Each CurrentStep In StepsTable Do
		
		CurrentStep.StageNumber = StageNumber;
		CurrentStep.DependsOnStages.Clear();
		CurrentStep.AffectsStages.Clear();
		
		CommonClientServer.SupplementArray(CurrentStep.DependsOnStages, CurrentStep.PreviousStages_);
		
		For Each PreviousStage_ In CurrentStep.PreviousStages_ Do
			
			PreviousStageLine = StepsTable.Find(PreviousStage_, "Code");
			
			If Not ValueIsFilled(PreviousStageLine)
			 Or PreviousStageLine.DependsOnStages.Count() = 0 Then
				Continue;
			EndIf;
			
			CommonClientServer.SupplementArray(CurrentStep.DependsOnStages, PreviousStageLine.DependsOnStages, True);
			
		EndDo;

		For Each PreviousStage_ In CurrentStep.DependsOnStages Do

			PreviousStageLine = StepsTable.Find(PreviousStage_, "Code");
			
			If Not ValueIsFilled(PreviousStageLine) Then
				Continue;
			EndIf;
			
			PreviousStageLine.AffectsStages.Add(CurrentStep.Code);
			
		EndDo;
		
		StageNumber = StageNumber + 1;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DescriptionOfExplanationsToStages

// Creates a table of explanations for the closing stages of the month.
// 
// Returns:
// 	ValueTable - LongDesc:
// * Code - String -
// * Description - String -
// * State - EnumRef.AccountingIssueSeverity -
// * State - CatalogRef.MonthEndClosingOperations -
// * Period - Date -
// * Organization - CatalogRef.Companies -
//               - Array of CatalogRef.Companies -
// * TextExecute - String -
// * ReadMoreText - String -
// * ActionExecute - Structure -
// * ActionMoreDetails - Structure -
// * Visible - Boolean -
// * RowID - Number -
// * HyperlinkExecute - Boolean -
// * HyperlinkReadMore - Boolean -
// * DecodingError - Arbitrary -
//
Function InitializeStepExplanationTable() Export
	
	ExplanationTable = New ValueTable;
	ExplanationTable.Columns.Add("Code",		   		  New TypeDescription("String")); // name of the check
	ExplanationTable.Columns.Add("Description", 		  New TypeDescription("String"));
	ExplanationTable.Columns.Add("State",   		  New TypeDescription("EnumRef.AccountingIssueSeverity"));
	ExplanationTable.Columns.Add("Parent", 	   		  New TypeDescription("CatalogRef.MonthEndClosingOperations")); // parent stage
	
	ExplanationTable.Columns.Add("Period",   		  	  New TypeDescription("Date"));
	ExplanationTable.Columns.Add("Organization",   		  New TypeDescription("Array, CatalogRef.Companies"));
	
	ExplanationTable.Columns.Add("TextExecute", 	  New TypeDescription("String"));
	ExplanationTable.Columns.Add("ReadMoreText", 	  New TypeDescription("String"));
	
	ExplanationTable.Columns.Add("ActionExecute",    New TypeDescription("Structure"));
	ExplanationTable.Columns.Add("ActionMoreDetails",    New TypeDescription("Structure"));
	
	// Service columns.
	ExplanationTable.Columns.Add("Visible",   		  New TypeDescription("Boolean"));
	ExplanationTable.Columns.Add("RowID",  New TypeDescription("Number"));
	ExplanationTable.Columns.Add("HyperlinkExecute", New TypeDescription("Boolean"));
	ExplanationTable.Columns.Add("HyperlinkReadMore", New TypeDescription("Boolean"));
	
	ExplanationTable.Columns.Add("DecodingError");
	
	// Adding field indexes.
	ExplanationTable.Indexes.Add("Parent");
	
	Return ExplanationTable;
	
EndFunction

// Creates a table of explanations for the closing stages of the month.
// 
// Returns:
// 	ValueTable - LongDesc:
// * Code - String -
// * Description - String -
// * State - EnumRef.AccountingIssueSeverity -
// * State - CatalogRef.MonthEndClosingOperations -
// * Period - Date -
// * Organization - CatalogRef.Companies -
//               - Array of CatalogRef.Companies -
// * TextExecute - String -
// * ReadMoreText - String -
// * ActionExecute - Structure -
// * ActionMoreDetails - Structure -
// * Visible - Boolean -
// * RowID - Number -
// * HyperlinkExecute - Boolean -
// * HyperlinkReadMore - Boolean -
// * DecodingError - Arbitrary -
// * Codes - Array of Number -
// * ObjectCount - Number -
//
Function InitializeTableOfGroupedExplanations() Export
	
	ExplanationTable = InitializeStepExplanationTable(); //ValueTable
	
	ExplanationTable.Columns.Add("Codes",				New TypeDescription("Array"));
	ExplanationTable.Columns.Add("ObjectCount", New TypeDescription("Number"));
	
	Return ExplanationTable;
	
EndFunction

Function AddGroupedExplanation(StructureOfData, ExplanationLine, ObjectCount = 0)
	
	ThereIsGroupedString = False;
	
	If Not ValueIsFilled(ExplanationLine.ActionExecute)
	 And ValueIsFilled(ExplanationLine.ActionMoreDetails)
	 And ExplanationLine.ActionMoreDetails.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.OpenCheckResults Then
	 
		TheStructureOfTheSearch = New Structure("Description, State, Parent, Period");
		FillPropertyValues(TheStructureOfTheSearch, ExplanationLine);
		
		GroupedRows = StructureOfData.TableOfGroupedExplanations.FindRows(TheStructureOfTheSearch);
			
		
		For Each CurrRow In GroupedRows Do
			
			If ValueIsFilled(ExplanationLine.ActionExecute)
			 Or Not ValueIsFilled(CurrRow.ActionMoreDetails)
	 		 Or CurrRow.ActionMoreDetails.ActionKind <> Enums.DrillDownActionKindsForMonthEndOperations.OpenCheckResults
			 Or CurrRow.ActionMoreDetails.FormParameters.Validation <> ExplanationLine.ActionMoreDetails.FormParameters.Validation
			 Or CurrRow.ActionMoreDetails.FormParameters.AccountingChecksContext <> ExplanationLine.ActionMoreDetails.FormParameters.AccountingChecksContext Then
				
				Continue; // we don't group these
				
			ElsIf TypeOf(CurrRow.DecodingError) = Type("Structure")
			 And TypeOf(ExplanationLine.DecodingError) = Type("Structure") Then
				
				SharedKeys = TMCommonUseClientServer.GetSharedKeysOfStructures(
					CurrRow.DecodingError,
					ExplanationLine.DecodingError);
				
				If SharedKeys.Count() <> CurrRow.DecodingError.Count()
				 Or SharedKeys.Count() <> ExplanationLine.DecodingError.Count() Then
					Continue;
				EndIf;
				
				If Not TMCommonUseClientServer.StructuresAreEqual(CurrRow.DecodingError, ExplanationLine.DecodingError) Then
					Continue;
				EndIf;
				
				// Found a suitable string.
				
			ElsIf TypeOf(CurrRow.DecodingError) = Type("Structure")
			 Or TypeOf(ExplanationLine.DecodingError) = Type("Structure") Then
			 
				Continue; // the structure is only in one of the lines
				
			ElsIf CurrRow.DecodingError <> ExplanationLine.DecodingError Then
				
				Continue; // the transcripts don't match
				
			EndIf;
			
			ThereIsGroupedString = True;
			Break;
			
		EndDo;		
		
	EndIf;
	
	If Not ThereIsGroupedString Then
		
		CurrRow = StructureOfData.TableOfGroupedExplanations.Add();
		
		FillPropertyValues(CurrRow, ExplanationLine, , "Code, Organization, RowID");
		
		CurrRow.Code 		   = ExplanationLine.Code;
		CurrRow.Codes 	   = New Array;
		CurrRow.Organization = New Array;
		
	Else
		
		CurrRow.Code = TrimAll(New UUID);
		
		CommonClientServer.SupplementArray(
			CurrRow.ActionMoreDetails.FormParameters.Issue1,
			ExplanationLine.ActionMoreDetails.FormParameters.Issue1,
			True);
		
	EndIf;
	
	CommonClientServer.SupplementArray(
		CurrRow.Codes,
		TMCommonUseClientServer.Array(ExplanationLine.Code),
		True);
	
	CommonClientServer.SupplementArray(
		CurrRow.Organization,
		TMCommonUseClientServer.Array(ExplanationLine.Organization),
		True);
	
	CurrRow.ObjectCount = CurrRow.ObjectCount + ObjectCount;
	
	Return CurrRow;
	
EndFunction

#EndRegion

#EndRegion

#Region StageStatus

// Creates a structure of parameters for calculating monthly closing stages.
// 
// Parameters:
// Period - Date -
// EndOfPeriod - Date -
// CompanyArray - Array of CatalogRef.Companies -
// MonthEndClosingMode - EnumRef.MonthEndClosingModes - 
// 
// Returns:
// 	Structure - LongDesc:
// * CompanyArray - Array of CatalogRef.Companies -
// * ArrayOfCompaniesSource - Array of CatalogRef.Companies -
// * AdditionalCompanies - Array of CatalogRef.Companies -
// * BlockedBusinesses - Array of CatalogRef.Companies -
// * AllCompanies - Boolean -
// * Period - Date -
// * RegistrationPeriod - Date -
// * BeginOfPeriod - Date -
// * EndOfPeriod - Date -
// * EndingDateOfPeriod - Date -
// * MonthEndClosingMode - EnumRef.MonthEndClosingModes, Undefined -
// * ResultIsInRegistrationLog - Boolean -
//
Function InitializeCalculationParametersStructure(Period, EndOfPeriod = Undefined, CompanyArray = Undefined, MonthEndClosingMode = Undefined) Export
	
	CalculationParameters = New Structure;
	
	AvailableCompanies = Catalogs.Companies.AvailableCompanies(True);
	
	CalculationParameters.Insert("CompanyArray",
		?(ValueIsFilled(CompanyArray),
		    TMCommonUseClientServer.IntersectionOfArrays(
				AvailableCompanies,
				TMCommonUseClientServer.Array(CompanyArray)),
			AvailableCompanies));
			
	CalculationParameters.Insert("ArrayOfCompaniesSource", Common.CopyRecursive(CalculationParameters.CompanyArray));
	
	CalculationParameters.Insert("AllCompanies", 	  	   Not ValueIsFilled(CompanyArray));
	CalculationParameters.Insert("AdditionalCompanies", New Array);
	CalculationParameters.Insert("BlockedBusinesses",New Array);
	
	CalculationParameters.Insert("Period", 			  	   BegOfMonth(Period));
	CalculationParameters.Insert("RegistrationPeriod", 	       CalculationParameters.Period);
	CalculationParameters.Insert("BeginOfPeriod", 		  	   CalculationParameters.Period);
	If MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		CalculationParameters.Insert("EndOfPeriod",  		   EndOfDay(EndOfPeriod));
		CalculationParameters.Insert("EndingDateOfPeriod",  EndOfDay(EndOfPeriod));
	Else
		CalculationParameters.Insert("EndOfPeriod",  		   EndOfMonth(CalculationParameters.Period));
		CalculationParameters.Insert("EndingDateOfPeriod",  EndOfMonth(CalculationParameters.Period));
	EndIf;
	CalculationParameters.Insert("MonthEndClosingMode", 	   MonthEndClosingMode);
	CalculationParameters.Insert("OnlyOneStage", 	       False);
	
	CalculationParameters.Insert("ResultIsInRegistrationLog", True);
	
	Return CalculationParameters;
	
EndFunction

// Creates a data structure for filling in the status of the month's closing stages.
//
// Parameters:
// Period - Date -
// CompanyArray - Array of CatalogRef.Companies -
// StructureOfData - Structure -
// MonthEndClosingMode - EnumRef.MonthEndClosingModes -
// 
// Returns:
// 	Structure - LongDesc:
// * StageGroupTable - See DataProcessors.MonthEndClosingOperations.InitializeStageGroupDescriptionTable 
// * TableStages - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable 
// * StageExplanationTable - See DataProcessors.MonthEndClosingOperations.InitializeStepExplanationTable
// * TableOfGroupedExplanations - See DataProcessors.MonthEndClosingOperations.InitializeTableOfGroupedExplanations
// * CalculationParameters - See DataProcessors.MonthEndClosingOperations.InitializeCalculationParametersStructure
// * SettlementStartDate - Date -
// * MonthClosedSuccessfully - Boolean -
// * StepsForRecount - Number -
// * CalculatedSteps - Number -
// * ChangesAreDisabled - Boolean -
// * ExplanationsToChangeClosing - String -
// * ExplanationToChangeProhibition - Arbitrary -
// * IsPeriodLocked - Boolean -
// * PeriodIsPartiallyBlocked - Boolean -
// * BlockedBusinesses - Array of CatalogRef.Companies -
// * DecryptionOfLock - Arbitrary -
// * DecryptionOfTasks - Arbitrary -
//
Function InitializeDataStructureToPopulateState(Period,
			CompanyArray = Undefined, StructureOfData = Undefined, MonthEndClosingMode = Undefined) Export
	
	CalculationParameters = InitializeCalculationParametersStructure(Period, Period, CompanyArray, MonthEndClosingMode);
		
	If Not ValueIsFilled(StructureOfData) Then // not initialized yet
		StructureOfData = New Structure;
		StructureOfData.Insert("StageGroupTable",    			FillInDescriptionOfGroupsOfStagesForClosingMonth());
		StructureOfData.Insert("TableStages", 		   			FillInDescriptionOfClosingStagesOfMonth());
		StructureOfData.Insert("StageExplanationTable", 			InitializeStepExplanationTable());
		StructureOfData.Insert("TableOfGroupedExplanations", InitializeTableOfGroupedExplanations());
	EndIf;
	
	StructureOfData.Insert("CalculationParameters",   			New FixedStructure(CalculationParameters));
	StructureOfData.Insert("SettlementStartDate", 	  		StructureOfData.CalculationParameters.RegistrationPeriod);
	StructureOfData.Insert("MonthClosedSuccessfully", 			True);
	StructureOfData.Insert("StepsForRecount", 			0);
	StructureOfData.Insert("CalculatedSteps", 			0);
	StructureOfData.Insert("ChangesAreDisabled", 			False);
	StructureOfData.Insert("ExplanationsToChangeClosing", 	"");
	StructureOfData.Insert("ExplanationToChangeProhibition", Undefined);
	StructureOfData.Insert("IsPeriodLocked", 			False);
	StructureOfData.Insert("PeriodIsPartiallyBlocked",	False); // part of Intercampany organizations has been blocked
	StructureOfData.Insert("BlockedBusinesses", 	New Array);
	StructureOfData.Insert("DecryptionOfLock", 		Undefined);
	StructureOfData.Insert("DecryptionOfTasks", 			Undefined);
	
	Return StructureOfData;
	
EndFunction

// Creates a data structure for filling in the status of the month's closing stages.
//
// Parameters:
// StructureOfData - See DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState 
// StorageAddress - String -
// UpdateOnlyOneStage - CatalogRef.MonthEndClosingOperations -
// AuxProperties - Structure -
// 
// Returns:
// 	Structure - LongDesc:
// * StructureOfData - See DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState 
// * StorageAddress - String - 
// * CheckBanDate_ - Boolean -
// * CleanUnusedJobEntries - Boolean -
// * UpdateScheduledTaskCaches - Boolean -
// * CheckCompletionOfCalculations_ - Boolean -
// * UpdateListOfChecks - Boolean -
// * UpdatedStages - Array of CatalogRef.MonthEndClosingOperations -
// * UpdateOnlyOneStage - CatalogRef.MonthEndClosingOperations -
// * PerformChecksBeforeStage - Boolean -
// * PerformChecksAfterStage - Boolean -
// * AccountingForStateOfPreviousStages - Boolean -
// * CreateDescriptionOfOrganizations - Boolean -
// * OperationalAccounting - Boolean -
// * LocalAccounting - Boolean -
// * FinancialAccounting - Boolean -
// * AutoTesting - Boolean -
//
Function InitializeStartupParametersToPopulateState(StructureOfData, StorageAddress = "",
			UpdateOnlyOneStage = Undefined, AuxProperties = Undefined) Export
	
	StartupParameters = New Structure;
	
	StartupParameters.Insert("StructureOfData", 					 StructureOfData);
	StartupParameters.Insert("StorageAddress", 					 StorageAddress);
	
	StartupParameters.Insert("CheckBanDate_", 				 False);
	StartupParameters.Insert("CleanUnusedJobEntries",	 False);
	StartupParameters.Insert("UpdateScheduledTaskCaches", 	 False); // needed for the month closing form
	StartupParameters.Insert("CheckCompletionOfCalculations_", 	 	 False); // needed for the month closing form
	
	StartupParameters.Insert("UpdateListOfChecks", 	 		 False);
	StartupParameters.Insert("UpdatedStages", 	 		 		 New Array);
	StartupParameters.Insert("UpdateOnlyOneStage", 			 UpdateOnlyOneStage);
	StartupParameters.Insert("PerformChecksBeforeStage", 			 False);
	StartupParameters.Insert("PerformChecksAfterStage", 		 False);
	StartupParameters.Insert("AccountingForStateOfPreviousStages", 	 True);
	StartupParameters.Insert("GenerateOperationsForClosedPeriod", False);
	
	StartupParameters.Insert("CreateDescriptionOfOrganizations", 	 True);
	
	StartupParameters.Insert("PreliminaryClosingOfMonthIsPerformed", False);
	StartupParameters.Insert("UpdateCacheOfStatusesOfOperations", True);
	
	If ValueIsFilled(AuxProperties) Then
		StartupParameters.Insert("OperationalAccounting", 		 		 AuxProperties.OperationalAccounting);
		StartupParameters.Insert("LocalAccounting", 	 	 AuxProperties.LocalAccounting);
		StartupParameters.Insert("FinancialAccounting", 	 			 AuxProperties.FinancialAccounting);
	Else
		StartupParameters.Insert("OperationalAccounting", 		 		 True);
		StartupParameters.Insert("LocalAccounting", 	 	 True);
		StartupParameters.Insert("FinancialAccounting", 	 			 True);
	EndIf;
	
	If ValueIsFilled(AuxProperties) And AuxProperties.Property("AutoTesting") Then
		StartupParameters.Insert("AutoTesting", AuxProperties.AutoTesting);
	Else
		StartupParameters.Insert("AutoTesting", False);
	EndIf;
	If ValueIsFilled(AuxProperties) And AuxProperties.Property("MonthEndClosingMode") Then
		StartupParameters.Insert("MonthEndClosingMode", AuxProperties.MonthEndClosingMode);
	Else
		StartupParameters.Insert("MonthEndClosingMode", Undefined);
	EndIf;
	
	Return StartupParameters;
	
EndFunction

// Called from outside of processing.
//
Procedure FillInStatesOfStages(StartupParameters) Export
	
	BeginTime = CurrentUniversalDateInMilliseconds();

	DescriptionOfGeneralPerformanceMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions.StateUpdate");
	
	TextDurationOfStages = "";
	StructureOfData = StartupParameters.StructureOfData;
	
	StructureOfData.CalculationParameters.AdditionalCompanies.Clear();
	
	If StartupParameters.CreateDescriptionOfOrganizations Then
		
		StructureOfData.Insert(
			"CompanyDescription",
			DescriptionOfOrganizationsToCalculate(StructureOfData.CalculationParameters.RegistrationPeriod));
		
		// Let's add related organizations to the array of organizations.
		If Not StructureOfData.CalculationParameters.AllCompanies Then
			
			For Each CurrentGroup In StructureOfData.CompanyDescription.GroupsOfOrganizations Do
				
				SharedOrganizations = TMCommonUseClientServer.IntersectionOfArrays(CurrentGroup, StructureOfData.CalculationParameters.CompanyArray);
				
				If SharedOrganizations.Count() > 0 And SharedOrganizations.Count() < CurrentGroup.Count() Then
					
					AdditionalCompanies = TMCommonUseClientServer.RemoveValuesFromArray(CurrentGroup, SharedOrganizations);
					AdditionalCompanies = TMCommonUseClientServer.IntersectionOfArrays(AdditionalCompanies, StructureOfData.CompanyDescription.AvailableCompanies);
					
					For Each AdditionalOrganization In AdditionalCompanies Do
						
						TMCommonUseClientServer.AddNewValueToArray(
							StructureOfData.CalculationParameters.CompanyArray,
							AdditionalOrganization);
						
						TMCommonUseClientServer.AddNewValueToArray(
							StructureOfData.CalculationParameters.AdditionalCompanies,
							AdditionalOrganization);
						
					EndDo;
					
				EndIf;
				
			EndDo;
			
			StructureOfData.CalculationParameters.ArrayOfCompaniesSource.Clear();
			CommonClientServer.SupplementArray(
				StructureOfData.CalculationParameters.ArrayOfCompaniesSource,
				StructureOfData.CalculationParameters.CompanyArray,
				True);
			
		EndIf;
		
	EndIf;
	
	Lock_Settings = InformationRegisters.SetUpLockFromChanges.InformationAboutBlockingChanges(
		StructureOfData.CalculationParameters.CompanyArray,
		StructureOfData.CalculationParameters.RegistrationPeriod);
	
	StructureOfData.IsPeriodLocked = Lock_Settings.PeriodIsBlockedForAllCompanies;
	StructureOfData.PeriodIsPartiallyBlocked = Lock_Settings.ThereAreTasksInBlockedPeriod;
	StructureOfData.CalculationParameters.BlockedBusinesses.Clear();
	StructureOfData.BlockedBusinesses.Clear();
	
	If Not StructureOfData.IsPeriodLocked And ValueIsFilled(Lock_Settings.BlockedBusinesses) Then

		// Payment is possible only for unblocked organizations
		
		For Each BlockedCompany In Lock_Settings.BlockedBusinesses Do
			CommonClientServer.DeleteValueFromArray(StructureOfData.CalculationParameters.CompanyArray, BlockedCompany);
			StructureOfData.BlockedBusinesses.Add(BlockedCompany);
			StructureOfData.CalculationParameters.BlockedBusinesses.Add(BlockedCompany);
		EndDo;
		
		For Each CurrentGroup In StructureOfData.CompanyDescription.GroupsOfOrganizations Do

			LockedAttributesAvailable = False;
			
			For Each CurrentCompany In CurrentGroup Do
				If Lock_Settings.BlockedBusinesses.Find(CurrentCompany) <> Undefined Then
					LockedAttributesAvailable = True;
				EndIf;
			EndDo;
			
			If LockedAttributesAvailable Then
				
				CommonClientServer.SupplementArray(StructureOfData.BlockedBusinesses, CurrentGroup, True);
				CommonClientServer.SupplementArray(StructureOfData.CalculationParameters.BlockedBusinesses, CurrentGroup, True);
				
				For Each CurrentCompany In CurrentGroup Do
					CommonClientServer.DeleteValueFromArray(StructureOfData.CalculationParameters.CompanyArray, CurrentCompany);
				EndDo;
				
			EndIf;
			
		EndDo;
		
		If Not ValueIsFilled(StructureOfData.CalculationParameters.CompanyArray) Then
			
			StructureOfData.PeriodIsPartiallyBlocked = True;
			
			StructureOfData.CalculationParameters.CompanyArray.Clear();
			CommonClientServer.SupplementArray(
				StructureOfData.CalculationParameters.CompanyArray,
				StructureOfData.CalculationParameters.ArrayOfCompaniesSource,
				True); // in the logic of the mechanism, the array of organizations cannot be empty - we will return its original filling, the calculation will still be impossible
			
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	If StartupParameters.UpdateScheduledTaskCaches Then
		
		DataVolume = InformationRegisters.ScheduledJobsOfMonthEndClosing.UpdateCachePropertiesUsingScheduledTask();
		
		// Let 's fix the general measurement
		PerformanceMonitor.FixTimeConsumingOperationMeasure(
			DescriptionOfGeneralPerformanceMeasurement,
			AmountOfDataToMeasure(DataVolume),
			"UpdateScheduledTaskCaches");
		
	EndIf;
	
	If StartupParameters.CheckCompletionOfCalculations_ Then
		
		DataVolume = InformationRegisters.PerformMonthEndClosingOperations.UpdateStateOfActiveCalculations();
		
		// Let 's fix the general measurement
		PerformanceMonitor.FixTimeConsumingOperationMeasure(
			DescriptionOfGeneralPerformanceMeasurement,
			AmountOfDataToMeasure(DataVolume),
			"CheckCompletionOfCalculations_");
		
	EndIf;
	
	If StartupParameters.UpdateListOfChecks Then
		FillInSystemStateCheckCatalog(StartupParameters, DescriptionOfGeneralPerformanceMeasurement);
	EndIf;
	
	MonthEndTransactionsServer.CheckTaskNumber();
	
	If StructureOfData.IsPeriodLocked And Not StartupParameters.GenerateOperationsForClosedPeriod Then
		StageLines_ = New Array; // determination of the State of the stages is not required
	ElsIf ValueIsFilled(StartupParameters.UpdateOnlyOneStage) Then
		StageLines_ = StructureOfData.TableStages.FindRows(New Structure("Code", StartupParameters.UpdateOnlyOneStage));
	ElsIf ValueIsFilled(StartupParameters.UpdatedStages) Then
		
		StageLines_ = New Array;
		StagesForSelection = New Map;
		
		For Each StageBeingUpdated In StartupParameters.UpdatedStages Do
			
			StagesForSelection.Insert(StageBeingUpdated, True);
			
			If StartupParameters.AccountingForStateOfPreviousStages Then
				
				StageString_ = StructureOfData.TableStages.Find(StageBeingUpdated, "Code");
				If StageString_ = Undefined Then
					Continue;
				EndIf;
				
				For Each PreviousStage_ In StageString_.DependsOnStages Do
					StagesForSelection.Insert(PreviousStage_, True);
				EndDo;
				
			EndIf;
			
		EndDo;
		
		For Each StageBeingUpdated In StructureOfData.TableStages Do
			
			If StagesForSelection.Get(StageBeingUpdated.Code) <> Undefined Then
				StageLines_.Add(StageBeingUpdated);
			EndIf;
			
		EndDo;
		
	Else
		StageLines_ = StructureOfData.TableStages;
	EndIf;
	
	SettlementStartDate = StructureOfData.CalculationParameters.RegistrationPeriod;
	
	// Sequential launch of stage checks and accounting checks in the system
	
	TotalStages = StageLines_.Count();
	Counter = 1;
	
	// Getting data from the previous analysis of the State of the month's closing
	
	StatesOfStagesFromCache = New Structure;
	StatesOfStagesFromCache.Insert("StatesOfStages", New Map());
	StatesOfStagesFromCache.Insert("DateWhenTheDataIsUpToDate", StartupParameters.StructureOfData.SettlementStartDate);
		
	ReadResultOfAnalysisOfStages(StartupParameters, StatesOfStagesFromCache);
	
	CacheUpdateRequired = False;
	
	If StartupParameters.UpdateCacheOfStatusesOfOperations Then
		StatesOfStagesFromCache.Insert("StatesOfStages", New Map());
		CacheUpdateRequired = True;
	Else
		For Each CurrentRow In StageLines_ Do
			If StatesOfStagesFromCache.StatesOfStages.Get(CurrentRow.Code) = Undefined Then
				CacheUpdateRequired = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	For Each CurrentRow In StageLines_ Do
		
		If Not CacheUpdateRequired Then
			CurrentRow.StateFromCache = StatesOfStagesFromCache.StatesOfStages.Get(CurrentRow.Code).State;
		EndIf;
		
		DoProcessStep(
			CurrentRow,
			StartupParameters,
			StructureOfData,
			DescriptionOfGeneralPerformanceMeasurement,
			TextDurationOfStages);
		
		If ValueIsFilled(CurrentRow.SettlementStartDate) Then
			SettlementStartDate = Min(SettlementStartDate, BegOfMonth(CurrentRow.SettlementStartDate));
		EndIf;
		
		HyperlinkForStateIsPossible = 
			CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted
			Or CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.DoneWithErrors
			Or (CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully
				 And Not CurrentRow.PerformedManually);
		
		CurrentRow.HyperlinkExecute = HyperlinkForStateIsPossible
			And ValueIsFilled(CurrentRow.ActionExecute) And Not IsBlankString(CurrentRow.TextExecute);
		
		CurrentRow.HyperlinkReadMore = HyperlinkForStateIsPossible
			And (Not CurrentRow.PerformedManually Or ValueIsFilled(CurrentRow.ActionMoreDetails))
			And Not IsBlankString(CurrentRow.ReadMoreText);
			
		TimeConsumingOperations.ReportProgress(Int((Counter/TotalStages)*100),,
			New Structure("UpdateCacheOfStatusesOfOperations, DateWhenTheDataIsUpToDate",
				StartupParameters.UpdateCacheOfStatusesOfOperations,
				StatesOfStagesFromCache.DateWhenTheDataIsUpToDate));
		Counter = Counter + 1;
		
	EndDo;
	
	If CacheUpdateRequired Then
		SaveResultOfStageAnalysis(StartupParameters);
		StructureOfData.Delete("StatesOfStagesFromCache_");
	ElsIf StageLines_.Count() Then
		StructureOfData.Insert("StatesOfStagesFromCache_");
	EndIf;
		
	StructureOfData.Insert("DateWhenTheDataIsUpToDate", StatesOfStagesFromCache.DateWhenTheDataIsUpToDate);
	
	// Sequential launch of stage checks and accounting checks in the system
	
	StructureOfData.SettlementStartDate = SettlementStartDate;
	
	// Fill in the properties of the stage groups.
	FillInStageGroupProperties(StructureOfData);
	
	// Let's check the dates of the ban on changes.
	If StartupParameters.CheckBanDate_ Then
		
		DataVolume = CheckDatesWhenChangesAreBanned(StructureOfData);
		
		// Let 's fix the general measurement
		PerformanceMonitor.FixTimeConsumingOperationMeasure(
			DescriptionOfGeneralPerformanceMeasurement,
			AmountOfDataToMeasure(DataVolume),
			"CheckDatesWhenChangesAreBanned");
			
	EndIf;
	
	// Check the period lock
	If Not StructureOfData.ChangesAreDisabled And (StructureOfData.IsPeriodLocked Or StructureOfData.PeriodIsPartiallyBlocked) Then
		
		StructureOfData.ChangesAreDisabled = True;
		StructureOfData.ExplanationsToChangeClosing = NStr("vi = 'Đã thiết lập phong tỏa tránh các thay đổi';
															|ru = 'Установлена блокировка от изменений';
															|en = 'Lock from changes is set'; fa = 'Lock from changes is set';
															|it = 'Установлена блокировка от изменений';
															|pl = 'Lock from changes is set';
															|tr = 'Değişime karşı kilit ayarlanmış'");
		
	EndIf;
	
	StructureOfData.Insert("DecryptionOfLock", New ValueStorage(Lock_Settings.TableOfLocks, New Deflation(9)));
	StructureOfData.Insert("DecryptionOfTasks",    New ValueStorage(Lock_Settings.TableOfTasksToClose, New Deflation(9)));
		
	// We will clear unused entries of the register of information of the task by closing the month
	If StartupParameters.CleanUnusedJobEntries Then
		
		DataVolume = ClearUnusedJobEntries(StructureOfData);
		
		// Let 's fix the general measurement
		PerformanceMonitor.FixTimeConsumingOperationMeasure(
			DescriptionOfGeneralPerformanceMeasurement,
			AmountOfDataToMeasure(DataVolume),
			"ClearUnusedJobEntries");
			
	EndIf;
	
	If ValueIsFilled(StartupParameters.StorageAddress) Then
		
		// Started as a background task - we will return the data not through a parameter, but through a temporary storage.
		PutToTempStorage(StructureOfData, StartupParameters.StorageAddress);
	
		EndTime = CurrentUniversalDateInMilliseconds();
		
		TextForLog = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thời gian tạo danh sách: %1
				|Kỳ: %2
				|Doanh nghiệp: %3';
				|ru = 'Время формирования списка: %1
				|Период: %2
				|Организации: %3';
				|en = 'List generation time: %1
				|Period: %2
				|Companies: %3'; fa = 'List generation time: %1
				|Period: %2
				|Companies: %3';
				|it = 'Tempo di generazione della lista: %1
				|Periodo: %2
				|Società: %3';
				|pl = 'Czas tworzenia listy: %1
				| Okres: %2
				|Firmy: %3';
				|tr = 'Liste oluşturma zamanı%1
				|Dönem:%2
				|İş yerleri:%3'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.TimePresentation((EndTime - BeginTime)/1000),
			CostCalculationProtocol.PresentationOfCalculationPeriod(StructureOfData.CalculationParameters.RegistrationPeriod),
			CostCalculationAppliedAlgorithms.CalculatedCompanies(StructureOfData.CalculationParameters.CompanyArray, ", ", True));
			
		TextForLog = TextForLog + "
			|
			|" + TextDurationOfStages;
		
		WriteLogEvent(
			MonthEndTransactionsServer.EventLogEventName(NStr("vi = 'Tạo một danh sách các hoạt động';
																|ru = 'Формировании списка операций';
																|en = 'Generate operation list'; fa = 'Generate operation list';
																|it = 'Generazione dell''elenco delle operazioni';
																|pl = 'Tworzeniu listy operacji';
																|tr = 'İşlemlerin listesinin oluşturulması'", Common.DefaultLanguageCode())),
			EventLogLevel.Information,
			,
			,
			TextForLog);
		
	EndIf;
	
	Try
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(
			DescriptionOfGeneralPerformanceMeasurement,
			AmountOfDataToMeasure(1));
	Except
		DescriptionOfGeneralPerformanceMeasurement = Undefined;
	EndTry;
	
EndProcedure

Procedure DoProcessStep(CollectionItem, StartupParameters, StructureOfData, DescriptionOfGeneralPerformanceMeasurement, TextDurationOfStages) Export
	
	CurrentRow = CollectionItem; // See DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState 
	SettlementStartDate = StructureOfData.CalculationParameters.RegistrationPeriod;	
	StageStartTime = CurrentUniversalDateInMilliseconds();
	
	If StartupParameters.PreliminaryClosingOfMonthIsPerformed
	 And Not CurrentRow.PerformedAtPreliminaryClosingOfMonth Then
		CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired;
	ElsIf ValueIsFilled(CurrentRow.DefaultState) Then
		CurrentRow.State = CurrentRow.DefaultState;
	Else
		CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.Undefined;
	EndIf;
	
	CurrentRow.PreviousStagesAreCompleted = True;
	CurrentRow.SettlementStartDate = Undefined;
	CurrentRow.CompanyArray.Clear();
	CurrentRow.AdditionalProperties.Clear();
	
	HandlerParameters = InitializeStageHandlerParameters(
		StructureOfData,
		CurrentRow,
		StartupParameters,
		"MonthEndTransactions.StateUpdate." + Catalogs.MonthEndClosingOperations.GetPredefinedItemName(CurrentRow.Code));
		
	HandlerParameters.Insert("DescriptionOfGeneralPerformanceMeasurement", DescriptionOfGeneralPerformanceMeasurement);
	
	// Determination of the stage execution status.
	If StartupParameters.PreliminaryClosingOfMonthIsPerformed
	 And Not CurrentRow.PerformedAtPreliminaryClosingOfMonth Then
		
		HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotRequired;
		
	Else
		
		// Filling the State of the stage from the cache.		
		If ValueIsFilled(CurrentRow.StateFromCache) Then
			CurrentRow.State = CurrentRow.StateFromCache;
			FillPropertyValues(CurrentRow, HandlerParameters.Data_Stage,
				"SettlementStartDate, CompanyArray, AdditionalProperties");
		Else
			CheckStageUsage(HandlerParameters);
			FillPropertyValues(CurrentRow, HandlerParameters.Data_Stage,
				"State, SettlementStartDate, CompanyArray, AdditionalProperties");
		EndIf;
		
		If ValueIsFilled(CurrentRow.SettlementStartDate) Then
			SettlementStartDate = Min(SettlementStartDate, BegOfMonth(CurrentRow.SettlementStartDate));
		EndIf;
		
		If ValueIsFilled(CurrentRow.StateFromCache) Then
			CurrentRow.StateFromCache = Enums.StatesOfMonthEndClosingOperations.EmptyRef();
		Else
			If StartupParameters.AccountingForStateOfPreviousStages Then
				// Let's check whether the calculation of the stage is required depending on the states of the previous stages.
				CheckPreviousSteps(StructureOfData, CurrentRow, HandlerParameters);
				FillPropertyValues(CurrentRow, HandlerParameters.Data_Stage, "State");
			EndIf;
			
			// Let's check the accounting status.
			PerformStageChecks(
				StructureOfData,
				CurrentRow,
				HandlerParameters,
				StartupParameters.PerformChecksBeforeStage,
				StartupParameters.PerformChecksAfterStage);
		EndIf;
		
	EndIf;
	
	// Fill in the results of performing accounting status checks.
	DetermineStateAndFillInExplanationsForStage(StructureOfData, CurrentRow, HandlerParameters);
	
	// We will make changes to the design of the stage.
	CustomizeStageDesign(HandlerParameters);
	FillPropertyValues(CurrentRow, HandlerParameters.Data_Stage, "Description, TextExecute, ReadMoreText, ThereAreRecordsOfZHR");
	
	If HandlerParameters.Data_Stage.State <> Enums.StatesOfMonthEndClosingOperations.Undefined Then
		FillPropertyValues(CurrentRow, HandlerParameters.Data_Stage, "State");
		DetermineStateAndFillInExplanationsForStage(StructureOfData, CurrentRow, HandlerParameters);
	EndIf;
	
	If HandlerParameters.Property("TempTablesManager") Then
		HandlerParameters.TempTablesManager.Close();
		HandlerParameters.Delete("TempTablesManager");
	EndIf;
	
	// Let's finish measuring
	StageEndTime = CurrentUniversalDateInMilliseconds();
	TextDurationOfStages = TextDurationOfStages + ?(TextDurationOfStages = "", "", "
		|") + CurrentRow.Description + ": " 
		+ CostCalculationProtocol.TimePresentation((StageEndTime - StageStartTime)/1000);
	
	FixMeasurementOfTimeForDeterminingStateOfStage(HandlerParameters,, True);
	
EndProcedure

Procedure FixMeasurementOfTimeForDeterminingStateOfStage(HandlerParameters, DataVolume = 0, EndMeasurement = False)
	
	If Not HandlerParameters.Property("DescriptionOfGeneralPerformanceMeasurement") Then
		Return;
	EndIf;
	
	HandlerParameters.DataVolume = HandlerParameters.DataVolume + DataVolume;
	
	If EndMeasurement Then
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(
			HandlerParameters.DescriptionOfPerformanceMeasurement,
			AmountOfDataToMeasure(HandlerParameters.DataVolume));
	Else
		PerformanceMonitor.FixTimeConsumingOperationMeasure(
			HandlerParameters.DescriptionOfPerformanceMeasurement,
			AmountOfDataToMeasure(HandlerParameters.DataVolume),
			"StageStateDefinitions");
	EndIf;
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(
		HandlerParameters.DescriptionOfGeneralPerformanceMeasurement,
		AmountOfDataToMeasure(HandlerParameters.DataVolume),
		"StageStateDefinitions");
	
	HandlerParameters.DataVolume = 0;
	
EndProcedure

Procedure IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, DataVolume = 1) Export
	
	If Not HandlerParameters.Property("DataVolume") Then
		Return;
	EndIf;
	
	HandlerParameters.DataVolume =
		HandlerParameters.DataVolume + ?(DataVolume <= 0, 1, DataVolume);
	
EndProcedure

Procedure FillInSystemStateCheckCatalog(StartupParameters, DescriptionOfGeneralPerformanceMeasurement)
	
	TypeOfExecutionContext = Type("CatalogRef.MonthEndClosingOperations");
	
	AuditOfSystemState.FillInSystemStateCheckCatalog(TypeOfExecutionContext, True);
		
	// Let 's fix the general measurement
	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(DISTINCT T.Ref) AS Count
	|FROM
	|	Catalog.AccountingCheckRules AS T
	|WHERE
	|	VALUETYPE(T.AccountingChecksContext) = &TypeOfExecutionContext";
	
	Query.SetParameter("TypeOfExecutionContext", TypeOfExecutionContext);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(
		DescriptionOfGeneralPerformanceMeasurement,
		AmountOfDataToMeasure(Selection.Count),
		"FillInSystemStateCheckCatalog");
		
EndProcedure

Procedure CheckStageUsage(HandlerParameters) Export
	
	If HandlerParameters.Property("OperationalAccounting")
	 And HandlerParameters.Property("LocalAccounting")
	 And HandlerParameters.Property("FinancialAccounting") Then
		
		// The type of stage accounting should be available in the Processing Form.
		StageAvailable = (HandlerParameters.Data_Stage.OperationalAccounting And HandlerParameters.OperationalAccounting)
		 Or (HandlerParameters.Data_Stage.LocalAccounting And HandlerParameters.LocalAccounting)
		 Or (HandlerParameters.Data_Stage.FinancialAccounting And HandlerParameters.FinancialAccounting);
		
		If Not StageAvailable Then
		 
			MonthEndTransactionsServer.SetStateDisabled(
				HandlerParameters,
				NStr("vi = 'Loại kế toán này không có sẵn.';
					|ru = 'Данный вид учета недоступен.';
					|en = 'This accounting kind is unavailable.'; fa = 'This accounting kind is unavailable.';
					|it = 'Questo tipo di contabilità non è disponibile.';
					|pl = 'Ten rodzaj ewidencji nie jest dostępny.';
					|tr = 'Mevcut hesap türü kullanılamıyor.'"));
			Return;
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(HandlerParameters.Data_Stage.ActionUse) Then
		Return;
	EndIf;
	
	// Let's execute a handler for checking the use of the stage.
	ParametersArray = New Array;
	ParametersArray.Add(HandlerParameters);
	
	Try
		
		Common.ExecuteConfigurationMethod(
			HandlerParameters.Data_Stage.ActionUse.Handler,
			ParametersArray);
		
	Except
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi xác định trạng thái giao dịch %1 đã xảy ra lỗi:
				|%2';
				|ru = 'При определении состояния операции %1 произошла ошибка:
				|%2';
				|en = 'An error occurred when determining %1 the operation state:
				|%2'; fa = 'An error occurred when determining %1 the operation state:
				|%2';
				|it = 'Si è verificato un errore:
				|%2 durante la determinazione di stato dell''operazione %1';
				|pl = 'Przy ustalaniu statusu operacji %1 wystąpił błąd:
				|%2';
				|tr = '%1 işleminin durumu belirlenirken bir hata oluştu:
				|%2'"),
			HandlerParameters.Data_Stage.Description,
			DetailErrorDescription(ErrorInfo()));
		
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			ErrorText);
		
	EndTry;
	
	FixMeasurementOfTimeForDeterminingStateOfStage(HandlerParameters);
	
EndProcedure

Procedure CheckPreviousSteps(StructureOfData, CurrentRow, HandlerParameters)
	
	If CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		Return;
	EndIf;
	
	CurrentRowIndex = StructureOfData.TableStages.IndexOf(CurrentRow);
	
	For Each PreviousStage_ In CurrentRow.PreviousStages_ Do
		
		PreviousStageLine = StructureOfData.TableStages.Find(PreviousStage_, "Code");
		
		If Not ValueIsFilled(PreviousStageLine) Then
			Continue;
		EndIf;
		
		If StructureOfData.TableStages.IndexOf(PreviousStageLine) >= CurrentRowIndex Then
			
			ErrorText = NStr("vi = 'Thứ tự của các hoạt động ""%1"" và ""%2"" không khớp với các cài đặt cho sự phụ thuộc lẫn nhau của các hoạt động.';
							|ru = 'Порядок выполнения операций ""%1"" и ""%2"" не совпадает с настройками взаимозависимости операций.';
							|en = 'Procedure of ""%1"" and ""%2"" operations execution does not correspond to the operation interdependence settings.'; fa = 'Procedure of ""%1"" and ""%2"" operations execution does not correspond to the operation interdependence settings.';
							|it = 'L''ordine delle operazioni ""%1"" e ""%2"" non corrisponde alle impostazioni dell''interdipendenza delle operazioni.';
							|pl = 'Kolejność wykonywania operacji ""%1"" i ""%2"" nie zgadza się z ustawieniami współzależności operacji.';
							|tr = '""%1"" ve ""%2"" işlemlerinin yürütülme sırası, işlem bağımlılık ayarlarıyla eşleşmiyor.'", Common.DefaultLanguageCode());
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorText,
				CurrentRow.Description,
				PreviousStageLine.Description);
			
			Raise ErrorText;
			
		EndIf;
			
		If PreviousStageLine.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted
		 Or PreviousStageLine.State = Enums.StatesOfMonthEndClosingOperations.PendingExecutionOfPreviousOperations
		 Or PreviousStageLine.State = Enums.StatesOfMonthEndClosingOperations.Undefined Then
			
			// The previous stage has not been completed - after its calculation, it will be necessary to calculate the current stage.
			CurrentRow.PreviousStagesAreCompleted = False;
			
			MonthEndTransactionsServer.SetStateFailed(
				HandlerParameters,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Hoạt động trước ''''%1'''' không thành công';
						|ru = 'Не выполнена предшествующая операция ""%1""';
						|en = 'The previous operation ""%1"" is not executed'; fa = 'The previous operation ""%1"" is not executed';
						|it = 'Operazione precedente ""%1"" non è eseguita';
						|pl = 'Nie powiodła się wcześniejsza operacja ""%1""';
						|tr = 'Önceki ""%1"" işlem başarısız oldu'"),
					PreviousStageLine.Description),
					,
					,
					Enums.AccountingIssueSeverity.Error);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PerformStageChecks(StructureOfData, CurrentRow, HandlerParameters, PerformChecksBeforeStage, PerformChecksAfterStage)
	
	If Not PerformChecksBeforeStage And Not PerformChecksAfterStage Then
		Return; // there is no need to perform checks
	EndIf;
	
	If MonthEndTransactionsServer.SimplifiedAutoTesting() Then
		Return; // there is no need to perform checks
	EndIf;
	
	SelectingWhenToRunCheck = New Array;
	
	If PerformChecksBeforeStage Then
		SelectingWhenToRunCheck.Add(Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation);
		SelectingWhenToRunCheck.Add(Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation);
    EndIf;
	
	If PerformChecksAfterStage Then
		SelectingWhenToRunCheck.Add(Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation);
		SelectingWhenToRunCheck.Add(Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation);
	EndIf;
	
	TableOfChecks = AuditOfSystemState.TableOfChecksByContext(
		CurrentRow.Code,
		SelectingWhenToRunCheck,
		False);
		
	MonthClosingParameters = MonthEndTransactionsServer.GeneralParametersForClosingMonth();
	CleaningIsDone = True;
	
	DataFromCache = ValueIsFilled(CurrentRow.StateFromCache);
	
	For AttemptNumber = 1 To MonthClosingParameters.NumberOfVerificationAttempts Do
		
		Try
			
			If Not DataFromCache Then
				AuditOfSystemState.ClearInspectionResults(
					TableOfChecks.UnloadColumn("Validation"),
					StructureOfData.CalculationParameters.CompanyArray,
					BegOfMonth(StructureOfData.CalculationParameters.RegistrationPeriod),
					EndOfMonth(StructureOfData.CalculationParameters.RegistrationPeriod));
				
				CleaningIsDone = True;
			EndIf;
			
		Except
			
			CleaningIsDone = False;
			
			If AttemptNumber = MonthClosingParameters.NumberOfVerificationAttempts Then
			
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi xóa kết quả kiểm tra, đã xảy ra lỗi:
						|%1';
						|ru = 'При очистке результатов проверок произошла ошибка:
						|%1';
						|en = 'An error occurred when clearing the check results:
						|%1'; fa = 'An error occurred when clearing the check results:
						|%1';
						|it = 'Si è verificato un errore durante la cancellazione dei risultati delle verifiche: 
						|%1';
						|pl = 'Podczas czyszczenia wyników sprawdzenia wystąpił błąd:
						|%1';
						|tr = 'Kontrol sonuçları temizlenirken bir hata oluştu:
						|%1'"),
					DetailErrorDescription(ErrorInfo()));
					
				If Not MonthClosingParameters.IgnoreErrorsOfEmergencyEndOFCheck Then
					MonthEndTransactionsServer.SetStateFailed(
						HandlerParameters,
						ErrorText);
				Else
					MonthEndTransactionsServer.AddExplanatoryInformationToStep(
						HandlerParameters,
						ErrorText);
				EndIf;
				
				MonthEndTransactionsServer.DuplicateToLog(
					HandlerParameters.Data_Stage.Code,
					Undefined,
					ErrorText);
				
			EndIf;
			
		EndTry;
		
		If CleaningIsDone Then
			Break;
		EndIf;
		
	EndDo;
	
	If CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		Return;
	EndIf;
	
	// Let's form additional parameters of checks.
	AdditionalInspectionParameters = CommonClientServer.CopyStructure(StructureOfData.CalculationParameters);
	
	AdditionalInspectionParameters.Insert("State",    		 	   CurrentRow.State);
	AdditionalInspectionParameters.Insert("CheckingBeforeCalculation",    	   PerformChecksBeforeStage);
	AdditionalInspectionParameters.Insert("CheckingAfterCalculation", 	   PerformChecksAfterStage);
	AdditionalInspectionParameters.Insert("AutoTesting", HandlerParameters.AutoTesting);
	AdditionalInspectionParameters.Insert("DataVolume",    	   0); // to measure performance
	
	If HandlerParameters.Property("TempTablesManager") Then
		AdditionalInspectionParameters.Insert("TempTablesManager", HandlerParameters.TempTablesManager);
	EndIf;
	If HandlerParameters.Property("MonthEndClosingMode") Then
		AdditionalInspectionParameters.Insert("MonthEndClosingMode", HandlerParameters.MonthEndClosingMode);
	Else
		AdditionalInspectionParameters.Insert("MonthEndClosingMode", Undefined);
	EndIf;
	
	For Each CurCheck In TableOfChecks Do
		
		If AdditionalInspectionParameters.Property("TempTablesManager") Then
			ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(AdditionalInspectionParameters);
		EndIf;
		
		CheckCompleted = True;
		
		For AttemptNumber = 1 To MonthClosingParameters.NumberOfVerificationAttempts Do
			
			Try
				
				CheckResult = AuditOfSystemState.CheckSystemState(
					CurCheck.Validation,
					AdditionalInspectionParameters);
				
				FixMeasurementOfTimeForDeterminingStateOfStage(
					HandlerParameters,
					CheckResult.IdentifiedProblems.Count() + AdditionalInspectionParameters.DataVolume);
				
				CheckCompleted = True;
				
			Except
				
				CheckCompleted = False;
				
				If AttemptNumber = MonthClosingParameters.NumberOfVerificationAttempts Then
				
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Khi thực hiện kiểm tra ""%1"" đã xảy ra lỗi:
							|%2';
							|ru = 'При выполнении проверки ""%1"" произошла ошибка:
							|%2';
							|en = 'An error occurred while checking ""%1"":
							|%2'; fa = 'An error occurred while checking ""%1"":
							|%2';
							|it = 'Si è verificato un errore:
							|%2 durante l''esecuzione del controllo ""%1""';
							|pl = 'Podczas weryfikacji ""%1"" wystąpił błąd:
							|%2';
							|tr = '""%1"" denetimi gerçekleştirilirken hata oluştu: 
							|%2'"),
						TrimAll(CurCheck.Validation),
						DetailErrorDescription(ErrorInfo()));
						
					If Not MonthClosingParameters.IgnoreErrorsOfEmergencyEndOFCheck Then
						MonthEndTransactionsServer.SetStateFailed(
							HandlerParameters,
							ErrorText);
					Else
						MonthEndTransactionsServer.AddExplanatoryInformationToStep(
							HandlerParameters,
							ErrorText);
					EndIf;
					
					MonthEndTransactionsServer.DuplicateToLog(
						HandlerParameters.Data_Stage.Code,
						Undefined,
						ErrorText);
					
				EndIf;
				
			EndTry;
			
			If CheckCompleted Then
				Break;
			EndIf;
			
		EndDo;
		
		If CheckCompleted And AdditionalInspectionParameters.Property("TempTablesManager") Then
			NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(AdditionalInspectionParameters, ExistingTT);
			CostCalculationAppliedAlgorithms.DestroyTemporaryTables(AdditionalInspectionParameters, NewTT);
		EndIf;
		
	EndDo;
	
EndProcedure

// Determines the status of the specified calculation stage.
// 
// Parameters:
//  StructureOfData - See DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState 
//
Procedure DetermineStateAndFillInExplanationsForStage(StructureOfData, CurrentRow, HandlerParameters, SelectingWhenToRunCheck = Undefined) Export
	
	HasErrors = False;
	ThereAreWarnings = False;
	
	// Let's delete the old explanations for the stage.
	OldExplanations = StructureOfData.StageExplanationTable.FindRows(New Structure("Parent", CurrentRow.Code));
	For Each ExplanationLine In OldExplanations Do
		
		If ValueIsFilled(SelectingWhenToRunCheck)
		 And Not ExplanationLine.HyperlinkReadMore
		 And ExplanationLine.State <> Enums.AccountingIssueSeverity.Error
		 And ExplanationLine.State <> Enums.AccountingIssueSeverity.Warning Then
			Continue;
		EndIf;
		
		StructureOfData.StageExplanationTable.Delete(ExplanationLine);
		
	EndDo;
	
	OldExplanations = StructureOfData.TableOfGroupedExplanations.FindRows(New Structure("Parent", CurrentRow.Code));
	For Each ExplanationLine In OldExplanations Do
		
		If ValueIsFilled(SelectingWhenToRunCheck)
		 And Not ExplanationLine.HyperlinkReadMore
		 And ExplanationLine.State <> Enums.AccountingIssueSeverity.Error
		 And ExplanationLine.State <> Enums.AccountingIssueSeverity.Warning Then
			Continue;
		EndIf;
		
		StructureOfData.TableOfGroupedExplanations.Delete(ExplanationLine);
		
	EndDo;
	
	NumberOfExplanations = StructureOfData.TableOfGroupedExplanations.Count();
	
	CurrentRow.ThereIsImportantInformation = False;
	CurrentRow.ThereIsAUsefulTip = False;
	
	// We will transfer the new explanations to the stage in the general table of explanations.
	For Each ExplanationLine In HandlerParameters.ExplanationTable_ Do
		
		NewExplanation = StructureOfData.StageExplanationTable.Add();
		FillPropertyValues(NewExplanation, ExplanationLine);
		
		NewExplanation.Parent = CurrentRow.Code;
		
		If Not ValueIsFilled(NewExplanation.State) Then
			NewExplanation.State = Enums.AccountingIssueSeverity.Information;
		EndIf;
		
		NewExplanation.HyperlinkExecute =
			ValueIsFilled(NewExplanation.ActionExecute) And Not IsBlankString(NewExplanation.TextExecute);
		
		NewExplanation.HyperlinkReadMore =
			ValueIsFilled(NewExplanation.ActionMoreDetails) And Not IsBlankString(NewExplanation.ReadMoreText);
		
		AddGroupedExplanation(StructureOfData, NewExplanation);
		
	EndDo;
	
	If HandlerParameters.ExplanationTable_.Find(Enums.AccountingIssueSeverity.Error, "State") <> Undefined Then
		HasErrors = True;
	ElsIf HandlerParameters.ExplanationTable_.Find(Enums.AccountingIssueSeverity.Warning, "State") <> Undefined Then
		ThereAreWarnings = True;
	EndIf;
	
	If CurrentRow.State <> Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		
		// Let's add the results of the checks to the general explanation table.
		TableOfChecks = AuditOfSystemState.TableOfChecksByContext(CurrentRow.Code, SelectingWhenToRunCheck);
		
		ProblemTable = AuditOfSystemState.SystemStateProblemTable(
			TableOfChecks.UnloadColumn("Validation"),
			StructureOfData.CalculationParameters.CompanyArray,
			BegOfMonth(StructureOfData.CalculationParameters.RegistrationPeriod),
			EndOfMonth(StructureOfData.CalculationParameters.RegistrationPeriod));
			
		IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, TableOfChecks.Count() + ProblemTable.Count());
		
		For Each ExplanationLine In ProblemTable Do
			
			NewExplanation = StructureOfData.StageExplanationTable.Add();
			
			NewExplanation.Parent 		 = CurrentRow.Code;
			NewExplanation.Code 				 = ExplanationLine.Issue1;
			NewExplanation.State 		 = ExplanationLine.Importance;
			NewExplanation.Organization 		 = ExplanationLine.Organization;
			NewExplanation.Period 		 	 = ExplanationLine.CheckedPeriod;
			NewExplanation.Description 	 = ExplanationLine.Presentation;
			NewExplanation.ReadMoreText    = MonthEndTransactionsServer.DefaultDetailsText();
			NewExplanation.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenVerificationResults(
				ExplanationLine.Validation,
				ExplanationLine.Issue1);
			
			NewExplanation.HyperlinkExecute = False;
			NewExplanation.HyperlinkReadMore = True;
			
			AddGroupedExplanation(StructureOfData, NewExplanation, ExplanationLine.ObjectCount);
			
			HasErrors = HasErrors Or (ExplanationLine.Importance = Enums.AccountingIssueSeverity.Error);
			ThereAreWarnings = ThereAreWarnings Or (ExplanationLine.Importance = Enums.AccountingIssueSeverity.Warning);
			
			If ExplanationLine.Importance = Enums.AccountingIssueSeverity.ImportantInformation Then
				CurrentRow.ThereIsImportantInformation = True;
			ElsIf ExplanationLine.Importance = Enums.AccountingIssueSeverity.UsefulTip Then
				CurrentRow.ThereIsAUsefulTip = True;
			EndIf;
			
			// We will substitute information about the number of problems in the name.
			NewExplanation.Description = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 (%2 chiếc)';
					|ru = '%1 (%2 шт.)';
					|en = '%1 (%2 pcs.)'; fa = '%1 (%2 pcs.)';
					|it = '%1 (%2 pz.)';
					|pl = '%1 (%2 szt.)';
					|tr = '%1 (%2 tane)'", Common.DefaultLanguageCode()),
				NewExplanation.Description,
				TrimAll(ExplanationLine.ObjectCount));
			
		EndDo;
		
	EndIf;
	
	For ExplanationNumber = NumberOfExplanations + 1 To StructureOfData.TableOfGroupedExplanations.Count() Do
		
		ExplanationLine = StructureOfData.TableOfGroupedExplanations[ExplanationNumber - 1]; // See DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState
		
		If ExplanationLine.ObjectCount > 0 Then
			// We will substitute information about the number of problems in the name.
			ExplanationLine.Description = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 (%2 chiếc)';
					|ru = '%1 (%2 шт.)';
					|en = '%1 (%2 pcs.)'; fa = '%1 (%2 pcs.)';
					|it = '%1 (%2 pz.)';
					|pl = '%1 (%2 szt.)';
					|tr = '%1 (%2 tane)'", Common.DefaultLanguageCode()),
				ExplanationLine.Description,
				TrimAll(ExplanationLine.ObjectCount));
		EndIf;
		
	EndDo;
	
	// Let's adjust the state of the stage.
	// The preliminary state can already be established when checking the use of the stage or checking the previous stages.
	If CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired
	 Or CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted Then
		// We do not change these states.
	ElsIf HasErrors Then
		CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted;
	ElsIf ThereAreWarnings Then
		CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.DoneWithErrors;
	ElsIf CurrentRow.State <> Enums.StatesOfMonthEndClosingOperations.DoneWithErrors Then
		If ValueIsFilled(CurrentRow.DefaultState) Then
			CurrentRow.State = CurrentRow.DefaultState;
		ElsIf CurrentRow.PerformedManually Then
			If Not CurrentRow.DisplayCompletedSuccessfully Then
				CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired;
			EndIf;
		Else
			CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully;
		EndIf;
	EndIf;
	
	FixMeasurementOfTimeForDeterminingStateOfStage(HandlerParameters);
	
EndProcedure

Procedure FillInStageGroupProperties(StructureOfData, GroupRows_ = Undefined) Export
	
	If Not ValueIsFilled(GroupRows_) Then  // top level of the tree
		
		StructureOfData.MonthClosedSuccessfully = True;
		StructureOfData.StepsForRecount = 0;
		StructureOfData.CalculatedSteps = 0;
		
		GroupRows_ = StructureOfData.StageGroupTable.FindRows(New Structure("Parent", ""));
		
	EndIf;
	
	For Each CurrentRow In GroupRows_ Do
		
		CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired;
		
		RowsOfSubordinates 	   = StructureOfData.TableStages.FindRows(New Structure("Parent", CurrentRow.Code));
		RowsOfSubordinateGroups = StructureOfData.StageGroupTable.FindRows(New Structure("Parent", CurrentRow.Code));
		
		If ValueIsFilled(RowsOfSubordinateGroups) Then
			// Let's determine the state of subordinate groups.
			FillInStageGroupProperties(StructureOfData, RowsOfSubordinateGroups);
		    // Add them to the array of subordinate elements.
			CommonClientServer.SupplementArray(RowsOfSubordinates, RowsOfSubordinateGroups);
		EndIf;
		
		ThereAreExecutedSuccessfully 	 = False;
		ThereAreExecutedWithErrors = False;
		HasUncompleted 		 = False;
		ThereAreNotDisabled		 = False;
		
		// Depending on the states of the subordinate elements, we will determine the state of the current group.
		For Each SubordinateRow In RowsOfSubordinates Do
			
			If (Not SubordinateRow.Disabled And Not SubordinateRow.PerformedManually)
			  Or (SubordinateRow.PerformedManually And MonthEndTransactionsServer.StageRecalculationIsRequired(SubordinateRow))
			  Or (SubordinateRow.PerformedManually And SubordinateRow.DisplayCompletedSuccessfully
			 		And SubordinateRow.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully) Then
				ThereAreNotDisabled = True;
			EndIf;
			
			If SubordinateRow.State = Enums.StatesOfMonthEndClosingOperations.Undefined
			 Or SubordinateRow.State = Enums.StatesOfMonthEndClosingOperations.PendingExecutionOfPreviousOperations Then
				
				// The month is closing.
				CurrentRow.State = SubordinateRow.State;
				StructureOfData.MonthClosedSuccessfully = False;
				
				Break;
				
			ElsIf SubordinateRow.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully Then
				
				ThereAreExecutedSuccessfully = True;
				StructureOfData.CalculatedSteps = StructureOfData.CalculatedSteps + 1;
				
			ElsIf SubordinateRow.State = Enums.StatesOfMonthEndClosingOperations.DoneWithErrors Then
				
				ThereAreExecutedWithErrors = True;
				
				If Not SubordinateRow.informational Then
					StructureOfData.MonthClosedSuccessfully = False;
					StructureOfData.StepsForRecount = StructureOfData.StepsForRecount + 1;
				EndIf;
				
			ElsIf SubordinateRow.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted Then
				
				HasUncompleted = True;
				
				If Not SubordinateRow.informational Then
					StructureOfData.MonthClosedSuccessfully = False;
					StructureOfData.StepsForRecount = StructureOfData.StepsForRecount + 1;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		CurrentRow.Disabled = Not ThereAreNotDisabled;
		
		If CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
			
			If HasUncompleted Then
				CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted;
			ElsIf ThereAreExecutedWithErrors Then
				CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.DoneWithErrors;
			ElsIf ThereAreExecutedSuccessfully Then
				CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SaveResultOfStageAnalysis(StartupParameters)
	
	Companies = StartupParameters.StructureOfData.CalculationParameters.CompanyArray;
	Month = StartupParameters.StructureOfData.SettlementStartDate;
	
	TableStages = StartupParameters.StructureOfData.TableStages;
	
	For Each Organization In Companies Do 
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.StatesOfMonthEndClosingOperations");
		LockItem.SetValue("Organization", Organization);

		BeginTransaction();
		Try
			Block.Lock();
			Records = InformationRegisters.StatesOfMonthEndClosingOperations.CreateRecordSet();
			Records.Filter.Organization.Set(Organization);
			Records.Filter.Period.Set(Month);
			For Each Stage In TableStages Do
				If Stage.State <> Enums.StatesOfMonthEndClosingOperations.Undefined Then
					Record = Records.Add();
					Record.MonthClosingOperation = Stage.Code;
					Record.Organization = Organization;
					Record.Period = Month;
					Record.DateOfAnalysis = CurrentSessionDate();
					Record.StageState = Stage.State;
				EndIf;
			EndDo;
			Records.Write(ReplacementMode.Replace);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry
	EndDo;
	
EndProcedure

Procedure ReadResultOfAnalysisOfStages(StartupParameters, StatesOfStagesFromCache)
	
	DateWhenTheDataIsUpToDate = CurrentSessionDate();
	
	Companies = StartupParameters.StructureOfData.CalculationParameters.CompanyArray;;
	Period = StartupParameters.StructureOfData.SettlementStartDate;
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	StatesOfMonthEndClosingOperations.MonthClosingOperation AS MonthClosingOperation,
		|	StatesOfMonthEndClosingOperations.StageState AS StageState,
		|	StatesOfMonthEndClosingOperations.DateOfAnalysis AS DateOfAnalysis,
		|	StatesOfMonthEndClosingOperations.Organization AS Organization
		|FROM
		|	InformationRegister.StatesOfMonthEndClosingOperations AS StatesOfMonthEndClosingOperations
		|WHERE
		|	StatesOfMonthEndClosingOperations.Period = &Period
		|	AND StatesOfMonthEndClosingOperations.Organization IN(&Companies)";
	
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("Period", Period);
	
	QueryResult = Query.Execute().Select();

	StatesOfStages = New Map;

	While QueryResult.Next() Do
		
		Stage = StatesOfStages.Get(QueryResult.MonthClosingOperation);

		If Stage = Undefined Then
			Stage = New Structure("State, DateOfAnalysis",
				QueryResult.StageState, QueryResult.DateOfAnalysis);
				
			StatesOfStages.Insert(QueryResult.MonthClosingOperation, Stage);
		Else
			SetStepState(Stage.State, QueryResult.StageState);
		EndIf;
		
		DateWhenTheDataIsUpToDate = Min(DateWhenTheDataIsUpToDate, QueryResult.DateOfAnalysis);
		
	EndDo;
		
	StatesOfStagesFromCache.Insert("StatesOfStages", StatesOfStages);
	StatesOfStagesFromCache.Insert("DateWhenTheDataIsUpToDate", DateWhenTheDataIsUpToDate);

EndProcedure

Procedure SetStepState(CurrentStatus, NewState)
	
	PrioritiesOfStates = New Map;
	PrioritiesOfStates.Insert(Enums.StatesOfMonthEndClosingOperations.Undefined, 1);
	PrioritiesOfStates.Insert(Enums.StatesOfMonthEndClosingOperations.NotRequired, 2);
	PrioritiesOfStates.Insert(Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully, 3);
	PrioritiesOfStates.Insert(Enums.StatesOfMonthEndClosingOperations.PendingExecutionOfPreviousOperations, 4);
	PrioritiesOfStates.Insert(Enums.StatesOfMonthEndClosingOperations.NotCompleted, 5);
	PrioritiesOfStates.Insert(Enums.StatesOfMonthEndClosingOperations.DoneWithErrors, 6);
	
	If PrioritiesOfStates.Get(CurrentStatus) < PrioritiesOfStates.Get(NewState) Then
		CurrentStatus = NewState;
	EndIf;
	
EndProcedure

#EndRegion

#Region StageDesign

Procedure CustomizeStageDesign(HandlerParameters)
	
	If Not ValueIsFilled(HandlerParameters.Data_Stage.Description) Then
		HandlerParameters.Data_Stage.Description = TrimAll(HandlerParameters.Data_Stage.Code); // by default
	EndIf;
	
	If ValueIsFilled(HandlerParameters.Data_Stage.ActionDesign) Then
		
		ParametersArray = New Array;
		ParametersArray.Add(HandlerParameters);
		
		Try
			
			Common.ExecuteConfigurationMethod(
				HandlerParameters.Data_Stage.ActionDesign.Handler,
				ParametersArray);
			
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi tùy chỉnh hiển thị giao dịch %1 đã xảy ra lỗi:
					|%2';
					|ru = 'При настройке отображения операции %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when configuring %1 the operation display:
					|%2'; fa = 'An error occurred when configuring %1 the operation display:
					|%2';
					|it = 'Si è verificato un errore:
					|%2 durante l''impostazione della visualizzazione dell''operazione%1';
					|pl = 'Podczas ustawiania wyświetlania operacji %1 wystąpił błąd:
					|%2';
					|tr = '%1 işleminin görüntüsü yapılandırılırken hata oluştu: 
					|%2'"),
				HandlerParameters.Data_Stage.Description,
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.SetStateFailed(
				HandlerParameters,
				ErrorText);
			
		EndTry;
		
	EndIf;
	
	// Let's define the behavior in the "More Details" action.
	If Not HandlerParameters.Data_Stage.PerformedManually Then
		
		ActionMoreDetails = HandlerParameters.Data_Stage.ActionMoreDetails;
		
		RequiresHyperlinkDetails = False;
		HandlerParameters.Data_Stage.ThereAreRecordsOfZHR = False;
		
		If MonthEndTransactionsServer.StageRecalculationIsRequired(HandlerParameters.Data_Stage) Then
			
			If ValueIsFilled(ActionMoreDetails)
			 And ActionMoreDetails.OpenInsteadOfGR Then
			 
				If HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully Then
					RequiresHyperlinkDetails =	Not ActionMoreDetails.NotRequiredOnSuccessfulExecution;
				Else
					RequiresHyperlinkDetails = Undefined; // the text is set in the stage design handler
				EndIf;
				
			Else
				
				HandlerParameters.Data_Stage.ThereAreRecordsOfZHR = MonthEndTransactionsServer.ThereAreErrorsInPerformingCalculation(
				    HandlerParameters.Data_Stage.Code,
					HandlerParameters.CalculationParameters.CompanyArray,
					HandlerParameters.CalculationParameters.RegistrationPeriod);
				
				RequiresHyperlinkDetails =
					HandlerParameters.Data_Stage.ThereAreRecordsOfZHR
				 	Or (ValueIsFilled(ActionMoreDetails)
				 		And ActionMoreDetails.ActionKind <> Enums.DrillDownActionKindsForMonthEndOperations.OpenEventLog
						And Not (ActionMoreDetails.NotRequiredOnSuccessfulExecution
				 			And HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully));
				
			EndIf;
			
		EndIf;
		
		If RequiresHyperlinkDetails = Undefined Then
			// The text is already installed.
		ElsIf RequiresHyperlinkDetails Then
			HandlerParameters.Data_Stage.ReadMoreText = MonthEndTransactionsServer.DefaultDetailsText();
		Else
			HandlerParameters.Data_Stage.ReadMoreText = "";
		EndIf;
		
	EndIf;
	
	FixMeasurementOfTimeForDeterminingStateOfStage(HandlerParameters);
	
EndProcedure

Function CheckDatesWhenChangesAreBanned(StructureOfData)
	
	VerificationPeriod = BegOfMonth(StructureOfData.SettlementStartDate);
	CompanyArray = StructureOfData.CalculationParameters.ArrayOfCompaniesSource;
	
	// Let's check the setting of the data modification ban dates.
	ExplanationOfBan = New ValueTable;
	ExplanationOfBan.Columns.Add("Organization", 			New TypeDescription("CatalogRef.Companies"));
	ExplanationOfBan.Columns.Add("RoutineOperations", New TypeDescription("Date"));
	ExplanationOfBan.Columns.Add("Bookkeeping", 	New TypeDescription("Date"));
	ExplanationOfBan.Columns.Add("FinancialAccounting", 	New TypeDescription("Date"));
	ExplanationOfBan.Columns.Add("AccountingPolicy", 		New TypeDescription("Date"));
	ExplanationOfBan.Columns.Add("ThereAreRegisteredRecords", 		New TypeDescription("Boolean"));
	
	ExplanationOfBan.Indexes.Add("Organization");
	
	SectionsToCheck = New Array;
	SectionsToCheck.Add("RoutineOperations");
	SectionsToCheck.Add("Bookkeeping");
	SectionsToCheck.Add("FinancialAccounting");
	DataTable = PeriodClosingDates.DataToCheckTemplate();
	
	For Each CurrentCompany In CompanyArray Do
		
		NewRow = ExplanationOfBan.Add();
		NewRow.Organization = CurrentCompany;
		
		For Each CurrentSection In SectionsToCheck Do
			
			NewRow = DataTable.Add();
			NewRow.Date   = VerificationPeriod;
			NewRow.Section = CurrentSection;
			NewRow.Object = CurrentCompany;
			
		EndDo;
		
	EndDo;
	
	DataTable.Sort("Object, Section");
	
	DataDetails = New Structure("NewVersion, Data", False, "");
	ErrorDescription = New Structure;
	PeriodEndClosingDate	   = Date(1,1,1); // the first permitted period
	
	ChangesAreDisabled = PeriodClosingDates.PeriodEndClosingFound(DataTable, DataDetails, ErrorDescription);
	
	If ChangesAreDisabled Then
		
		// We will get a description of all the set dates of the ban, including the smaller dates of the start of the calculation.
		DataTable.FillValues(Date(1,1,2), "Date");
		ErrorDescription = New Structure;
		
		PeriodClosingDates.PeriodEndClosingFound(DataTable, DataDetails, ErrorDescription);
		
		For Each BanLine In ErrorDescription.PeriodEnds Do
			
			CurBan = EndOfMonth(BanLine.PeriodEndClosingDate) + 1;
			
			If Not ValueIsFilled(PeriodEndClosingDate) Then
				PeriodEndClosingDate = CurBan;
			Else
				PeriodEndClosingDate = Max(PeriodEndClosingDate, CurBan);
			EndIf;
			
			DecryptionString = ExplanationOfBan.Find(BanLine.Object, "Organization");
			DecryptionString[BanLine.Section] = CurBan;
			
		EndDo;
		
	EndIf;
	
	StructureOfData.Insert("ChangesAreDisabled", 		   ChangesAreDisabled);
	StructureOfData.Insert("ExplanationsToChangeClosing", "");
	
	// Let's check the start dates of accounting in organizations.
	Query = New Query;
	Query.Text =
	"SELECT
	|	Companies.Ref AS Organization,
	|	MIN(BEGINOFPERIOD(AccountingPolicies.Period, MONTH)) AS Period
	|FROM
	|	Catalog.Companies AS Companies
	|	LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicies
	|		ON Companies.ParentCompany = AccountingPolicies.Organization
	|WHERE
	|	Companies.Ref IN(&CompanyArray)
	|
	|GROUP BY
	|	Companies.Ref
	|
	|ORDER BY
	|	Period";
	
	Query.SetParameter("CompanyArray", CompanyArray);
	
	Selection = Query.Execute().Select();
	
	PolicyPeriod = Date(1,1,1); // first period with accounting policy
	ThereAreOrganizationsWithoutAccountingPolicies = False;
	
	OrganizationsWithRegisteredRecords = CostCalculationAppliedAlgorithms.OrganizationsWithCostRegisteredRecords(
		VerificationPeriod,
		CompanyArray);
	
	While Selection.Next() Do
		
		DecryptionString = ExplanationOfBan.Find(Selection.Organization, "Organization");
		DecryptionString.AccountingPolicy = Selection.Period;
		DecryptionString.ThereAreRegisteredRecords = (OrganizationsWithRegisteredRecords.Find(Selection.Organization) <> Undefined);
		
		If Not DecryptionString.ThereAreRegisteredRecords Then
			PolicyPeriod = Max(PolicyPeriod, VerificationPeriod);
		ElsIf Not ValueIsFilled(Selection.Period) Then
			ThereAreOrganizationsWithoutAccountingPolicies = True;
		Else
			PolicyPeriod = Max(PolicyPeriod, Selection.Period);
		EndIf;
		
	EndDo;
	
	// Let's form the text of the explanation.
	If ThereAreOrganizationsWithoutAccountingPolicies Or Not ValueIsFilled(PolicyPeriod) Then
		
		StructureOfData.ChangesAreDisabled = True;
		StructureOfData.ExplanationsToChangeClosing = NStr("vi = 'Chưa đặt chính sách kế toán';
															|ru = 'Не заданы учетные политики';
															|en = 'Accounting policies are not specified'; fa = 'Accounting policies are not specified';
															|it = 'Non sono fornite le politiche contabili';
															|pl = 'Nie zadano polityk ewidencyjnych';
															|tr = 'Muhasebe politikası beliritilmedi'");
		
	ElsIf ValueIsFilled(PeriodEndClosingDate) Or PolicyPeriod > VerificationPeriod Then
		
		StructureOfData.ChangesAreDisabled = True;
		StructureOfData.ExplanationsToChangeClosing = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Có thể tính toán từ giai đoạn %1';
				|ru = 'Расчет возможен с периода %1';
				|en = 'Calculation is possible from the period of %1'; fa = 'Calculation is possible from the period of %1';
				|it = 'Il calcolo è possibile dal periodo %1';
				|pl = 'Rozliczenie jest możliwe od okresu %1';
				|tr = 'Hesaplama %1 dönemden itibaren mümkün'"),
			CostCalculationProtocol.PresentationOfCalculationPeriod(Max(PeriodEndClosingDate, PolicyPeriod)));
		
	EndIf;
	
	StructureOfData.Insert("ExplanationToChangeProhibition", New ValueStorage(ExplanationOfBan, New Deflation(9)));
	
	Return DataTable.Count();
	
EndFunction

Function ClearUnusedJobEntries(StructureOfData)
	
	DataVolume = 0;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	T.Operation AS Operation
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS T
	|WHERE
	|	T.Operation IN (&UnusedOperations)";
	
	Query.SetParameter("UnusedOperations", Catalogs.MonthEndClosingOperations.UnusedOperations());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		DataVolume = DataVolume + 1;
		
		InformationRegisters.JobsForMonthEndClosing.DeleteRecordsByOperation(Selection.Operation);
		
	EndDo;
	
	Return DataVolume;
	
EndFunction

#EndRegion

#Region CalculationOfStages

Function InitializeStateStructureOfCalculation(StructureOfData, LastStageForCalculation = Undefined) Export
	
	CalculationState = New Structure;
	CalculationState.Insert("CurStageNumber", 	   -1);
	CalculationState.Insert("PreviousStageNumber",     -1);
	CalculationState.Insert("NumberOfStages", 		   0);
	CalculationState.Insert("BeginTime",    		   CurrentUniversalDateInMilliseconds());
	
	CalculationState.Insert("PresentationStage", 	   "");
	CalculationState.Insert("LastStageForCalculation",   LastStageForCalculation);
	CalculationState.Insert("StepsToCalculation", 		   	   New Array);
	
	If ValueIsFilled(StructureOfData) Then
		
		CalculatedStages = StructureOfData.TableStages.FindRows(New Structure("PerformedManually", False));
			
		For Each CurrentRow In CalculatedStages Do
			
			If Not ValueIsFilled(CalculationState.StepsToCalculation) Then
				
				// Let's start the calculation with the first "problematic" stage.
				If MonthEndTransactionsServer.StageRecalculationIsRequired(CurrentRow) Then
					CalculationState.StepsToCalculation.Add(CurrentRow.Code);
		 		EndIf;
				
			Else
				// Any of the following stages may need to be recalculated due to changes caused by the calculation of the previous stages.
				CalculationState.StepsToCalculation.Add(CurrentRow.Code);
			EndIf;
			
			If CurrentRow.Code = LastStageForCalculation Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	CalculationState.NumberOfStages = CalculationState.StepsToCalculation.Count();
	CalculationState.Insert("CalculationIsCompleted", (CalculationState.NumberOfStages = 0));
	
	Return CalculationState;
	
EndFunction

Function InitializeStartupParametersForCalculatingStages(StructureOfData, CalculateOnlyOneStage,	LastStageForCalculation,
			MonthEndClosingMode, StorageAddress = "", AuxProperties = Undefined, CalculationID = Undefined) Export
	
	// Let's prepare the launch parameters.
	StartupParameters = New Structure;
	
	StartupParameters.Insert("StructureOfData", 		     StructureOfData);
	StartupParameters.Insert("StorageAddress", 	 	     StorageAddress);
	StartupParameters.Insert("CalculateOnlyOneStage",    CalculateOnlyOneStage);
	StartupParameters.Insert("CheckStateBeforeCalculation", Not ValueIsFilled(CalculateOnlyOneStage));
	StartupParameters.Insert("LastStageForCalculation", 	 LastStageForCalculation);
	StartupParameters.Insert("CalculationID", 	 	 CalculationID);
	StartupParameters.Insert("MonthEndClosingMode", 	 	 MonthEndClosingMode);
	
	If ValueIsFilled(AuxProperties) And AuxProperties.Property("OperationalAccounting") Then
		StartupParameters.Insert("OperationalAccounting", 		 AuxProperties.OperationalAccounting);
		StartupParameters.Insert("LocalAccounting",  AuxProperties.LocalAccounting);
		StartupParameters.Insert("FinancialAccounting", 	 	 AuxProperties.FinancialAccounting);
	Else
		StartupParameters.Insert("OperationalAccounting", 		 True);
		StartupParameters.Insert("LocalAccounting",  True);
		StartupParameters.Insert("FinancialAccounting", 	 	 True);
	EndIf;
	If ValueIsFilled(AuxProperties) And AuxProperties.Property("OnlyOneOrganization") Then
		StartupParameters.Insert("OnlyOneOrganization",  AuxProperties.OnlyOneOrganization);
	Else
		StartupParameters.Insert("OnlyOneOrganization",  False);
	EndIf;
	
	If ValueIsFilled(AuxProperties) And AuxProperties.Property("AutoTesting") Then
		StartupParameters.Insert("AutoTesting", AuxProperties.AutoTesting);
	Else
		StartupParameters.Insert("AutoTesting", False);
	EndIf;
	
	Return StartupParameters;
	
EndFunction

Procedure PerformCalculationOfStages(StartupParameters) Export
	
	SetPrivilegedMode(True);
	
	TableStages 	 = StartupParameters.StructureOfData.TableStages;
	CalculationParameters = StartupParameters.StructureOfData.CalculationParameters;
	
	InformationRegisters.SetUpLockFromChanges.CheckLocksBeforeStartingCalculation(
		CalculationParameters.CompanyArray,
		CalculationParameters.RegistrationPeriod);
	
	NumberOfLastRowToCalculate = TableStages.IndexOf(TableStages.Find(StartupParameters.LastStageForCalculation, "Code"));
	
	If ValueIsFilled(StartupParameters.CalculateOnlyOneStage) Then
		FirstRowNumber 	 = TableStages.IndexOf(TableStages.Find(StartupParameters.CalculateOnlyOneStage, "Code"));
		LastRowNumber = FirstRowNumber;
	Else
		FirstRowNumber 	 = 0;
		LastRowNumber = NumberOfLastRowToCalculate;
	EndIf;
	
	For LineNumber = FirstRowNumber To TableStages.Count() - 1 Do
		
		// Action with the current row.
		PerformingRowRecalculation = (LineNumber <= LastRowNumber);
		SearchForNextRowRequiringRecalculation = Not PerformingRowRecalculation And (LineNumber <= NumberOfLastRowToCalculate);
		UpdatingStateOfRow = Not PerformingRowRecalculation And Not SearchForNextRowRequiringRecalculation And (LineNumber <= TableStages.Count() - 1);
		
		CurrentRow = TableStages[LineNumber];
		
		// We skip the steps that are not performed at the preliminary closing of the month.
		If StartupParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing
		 And Not CurrentRow.PerformedAtPreliminaryClosingOfMonth Then
		 	Continue;
		EndIf;
		
		// If necessary, first update the state of the stage.
		If StartupParameters.CheckStateBeforeCalculation
		 Or SearchForNextRowRequiringRecalculation Or UpdatingStateOfRow Then
			
			ParametersForTriggeringStateUpdates = InitializeStartupParametersToPopulateState(
				StartupParameters.StructureOfData,
				,
				CurrentRow.Code,
				StartupParameters);
			
			ParametersForTriggeringStateUpdates.PerformChecksBeforeStage 	   = True;
			ParametersForTriggeringStateUpdates.CreateDescriptionOfOrganizations = False;
			
			FillInStatesOfStages(ParametersForTriggeringStateUpdates);
			
		EndIf;
		
		If UpdatingStateOfRow Then
			Continue;
		EndIf;
		
		If PerformingRowRecalculation
		 Or (SearchForNextRowRequiringRecalculation 
		 	  And Not MonthEndTransactionsServer.StageRecalculationIsRequired(CurrentRow)) Then
			  
			// Let's clear the results of the last stage calculation.
			ClearResultsOfChecksBeforeCalculation(CurrentRow.Code, CalculationParameters);
			
		EndIf;
		
		If SearchForNextRowRequiringRecalculation Then
			If MonthEndTransactionsServer.StageRecalculationIsRequired(CurrentRow) Then
				Break;
			Else
				Continue;
			EndIf;
	 	EndIf;
		
		// We recalculate the stage only if there are problems with it.
		If Not MonthEndTransactionsServer.StageRecalculationIsRequired(CurrentRow) Then
			Continue;
	 	EndIf;
		
		// Initialize the stage calculation handler.
		HandlerParameters = InitializeStageHandlerParameters(
			StartupParameters.StructureOfData,
			CurrentRow,
			StartupParameters);
		
		If ValueIsFilled(StartupParameters.CalculationID) Then
			HandlerParameters.CalculationID = StartupParameters.CalculationID;
		EndIf;
		
		ParametersArray = New Array;
		ParametersArray.Add(HandlerParameters);
		
		DescriptionOfStageExecution = New Structure;
		DescriptionOfStageExecution.Insert("Operation",   CurrentRow.Code);
		DescriptionOfStageExecution.Insert("StartDate", CurrentSessionDate());
		
		CalculationStart 	  = CurrentUniversalDateInMilliseconds();
		ThereWasCalculationError = False;
		
		// Let's execute the stage calculation handler.
		Try
			
			If ValueIsFilled(CurrentRow.ActionExecute)
			 And ValueIsFilled(CurrentRow.ActionExecute.Handler) Then
				Common.ExecuteConfigurationMethod(
					CurrentRow.ActionExecute.Handler,
					ParametersArray);
			EndIf;
			
		Except
			
			ThereWasCalculationError = True;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi thực hiện giao dịch ""%1"" đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении операции ""%1"" произошла ошибка:
					|%2';
					|en = 'An error occurred when performing operation ""%1"":
					|%2'; fa = 'An error occurred when performing operation ""%1"":
					|%2';
					|it = 'Si è verificato un errore:
					|%2 durante l''esecuzione dell''operazione ""%1""';
					|pl = 'Podczas wykonywania operacji ""%1"" wystąpił błąd:
					|%2';
					|tr = '""%1"" işlem gerçekleştirilirken hata oluştu: 
					|%2'", Common.DefaultLanguageCode()),
				TrimAll(CurrentRow.Description),
				DetailErrorDescription(ErrorInfo()));
				
			If StrFind(ErrorText, MonthEndTransactionsServer.ServiceSymbol_ExceptionHasAlreadyBeenWorkedOutInCalculationStage()) = 0 Then
				// The error was not worked out during the execution of the stage.
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(HandlerParameters, ErrorText);
			EndIf;
			
		EndTry;
		
		If ThereWasCalculationError And TransactionActive() Then
			// If a transaction was not closed in the stage calculation method for some reason, then we will do it here
			// to guarantee the normal execution of the following stages.
			RollbackTransaction();
		EndIf;
		
		CompleteSubordinateTasksOfCalculationStage(HandlerParameters.CalculationID);
		
		// Let's register the errors detected during the calculation.
		RegisterStageCalculationProblems(HandlerParameters);
		
		// Let's check for calculation errors (they can be registered during the calculation stage).
		StageIsCalculated = Not MonthEndTransactionsServer.ThereAreErrorsInPerformingCalculation(
		    CurrentRow.Code,
			HandlerParameters.CalculationParameters.CompanyArray,
			HandlerParameters.CalculationParameters.RegistrationPeriod);
			
		// We will save the information about the performed calculation.
		DescriptionOfStageExecution.Insert("EndDate", CurrentSessionDate());
		DescriptionOfStageExecution.Insert("Duration",  CurrentUniversalDateInMilliseconds() - CalculationStart);
		
		InformationRegisters.PerformMonthEndClosingOperations.SaveStageCompletionInformation(
			HandlerParameters.CalculationParameters.CompanyArray,
			HandlerParameters.CalculationParameters.RegistrationPeriod,
			DescriptionOfStageExecution,
			Not StageIsCalculated);
		
		// Update the state of the stage after the calculation.
		ParametersForTriggeringStateUpdates = InitializeStartupParametersToPopulateState(
			StartupParameters.StructureOfData,
			,
			CurrentRow.Code,
			StartupParameters);
		
		ParametersForTriggeringStateUpdates.PerformChecksAfterStage    = Not ThereWasCalculationError;
		ParametersForTriggeringStateUpdates.CreateDescriptionOfOrganizations = False;
		
		FillInStatesOfStages(ParametersForTriggeringStateUpdates);
		
		// Let's update the status of the previous stages.
		For Each UpdateStage In CurrentRow.UpdateStateOfStages Do
			
			ParametersForTriggeringStateUpdates = InitializeStartupParametersToPopulateState(
				StartupParameters.StructureOfData,
				,
				UpdateStage,
				StartupParameters);
			
			ParametersForTriggeringStateUpdates.PerformChecksBeforeStage 	   = True;
			ParametersForTriggeringStateUpdates.CreateDescriptionOfOrganizations = False;
			
			FillInStatesOfStages(ParametersForTriggeringStateUpdates);
			
		EndDo;
		
	EndDo;
	
	If ValueIsFilled(StartupParameters.StorageAddress) Then
		
		// Started as a background task - we will return the data not through a parameter, but through a temporary storage.
		PutToTempStorage(StartupParameters.StructureOfData, StartupParameters.StorageAddress);
		
	EndIf;
	
	// We will notify you about the end of the calculation.
	If ValueIsFilled(StartupParameters.CalculationID) Then
		InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(StartupParameters.CalculationID);
	EndIf;
	
EndProcedure

Procedure ClearResultsOfChecksBeforeCalculation(CalculationStage, CalculationParameters) Export
	
	If MonthEndTransactionsServer.SimplifiedAutoTesting() Then
		Return; // there is no need to perform checks
	EndIf;
	
	// Let's clear the results of the last stage calculation.
	MonthEndTransactionsServer.ClearCalculationExecutionProblems(
		CalculationStage,
		CalculationParameters.CompanyArray,
		CalculationParameters.RegistrationPeriod);
		
	SelectingWhenToRunCheck = New Array;
	SelectingWhenToRunCheck.Add(Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation);
	
	TableOfChecks = AuditOfSystemState.TableOfChecksByContext(
		CalculationStage,
		SelectingWhenToRunCheck,
		False); // and non-contextual ones performed after the calculation
		
	AuditOfSystemState.ClearInspectionResults(
		TableOfChecks.UnloadColumn("Validation"),
		CalculationParameters.CompanyArray,
		BegOfMonth(CalculationParameters.RegistrationPeriod),
		EndOfMonth(CalculationParameters.RegistrationPeriod));
	
EndProcedure

// Complete the subordinate tasks of the calculation stage.
// 
// Parameters:
//  CalculationID - UUID -  calculation ID
Procedure CompleteSubordinateTasksOfCalculationStage(CalculationID) Export
	
	If Not ValueIsFilled(CalculationID) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("CalculationID", CalculationID);
	
	Query.Text =
	"SELECT
	|	T.BackgroundJobIdentifier
	|FROM
	|	InformationRegister.LaunchedBackgroundJobsOfMonthEndClosingStages AS T
	|WHERE
	|	T.CalculationID = &CalculationID";
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		
		RegisterName = "InformationRegister.LaunchedBackgroundJobsOfMonthEndClosingStages";
		LockItem = Block.Add(RegisterName);
		LockItem.SetValue("CalculationID", CalculationID);
		LockItem.Mode = DataLockMode.Shared;
		
		Block.Lock();
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			MonthEndTransactionsServer.CancelBackgroundJob_(Selection.BackgroundJobIdentifier);
		EndDo;
		
		If Selection.Count() > 0 Then
			RecordSet = InformationRegisters.LaunchedBackgroundJobsOfMonthEndClosingStages.CreateRecordSet();
			RecordSet.Filter.CalculationID.Set(CalculationID);
			RecordSet.Write(True);
		EndIf;

		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		Raise ErrorText;
		
	EndTry;
	
EndProcedure

#EndRegion


#Region MethodsForMeasuringPerformance

// Used for measuring the time to determine the status of stages.
//
Function AmountOfDataToMeasure(Count)
	
	// The specific time turns out to be very small, which is why rounding errors are possible.
	// To prevent them, we will reduce the number, i.e. we will increase the specific measurement time.
	Return ?(Count = 0, 1, Count) / 100;
	
EndFunction

#EndRegion

#Region Companies

Function DescriptionOfOrganizationsToCalculate(Period, FastInitialization = False) Export
	
	SetPrivilegedMode(True);
	
	If Not FastInitialization Then
		IntercampanyArray = CostCalculationAppliedAlgorithms.AllConnectionsOfOrganizationsUnderIntercampanyScheme(Period); // contains all organizations
	Else
		IntercampanyArray = New Array;
	EndIf;
	
	AllCompanies = Catalogs.Companies.AvailableCompanies();
	
	SetPrivilegedMode(False);
	
	AvailableCompanies = Catalogs.Companies.AvailableCompanies(True);
	
	ArrayOSiIa = New Array;
	If Not FastInitialization Then
		ArrayOSiIa = NonCurrentAssets.GroupsOfOrganizationsAboutSiIa(Period);
	Else
		ArrayOSiIa = New Array;
	EndIf;
	IntercampanyOrganizations = New Map;
	OrganizationsAboutSiIa 		= New Map;
	MergeGroups 		= False;
	
	// Let's remember the organizations that have connections with others according to the Intercampany scheme.
	For Each IntercampanyGroup In IntercampanyArray Do
		
		If IntercampanyGroup.Count() < 2 Then
			Continue; 
		EndIf;
		
		For Each IntercampanyOrganization In IntercampanyGroup Do
			IntercampanyOrganizations.Insert(IntercampanyOrganization, True);
		EndDo;
		
	EndDo;
	
	// We will combine arrays of organizations - we will transfer groups of OS and IA organizations to Intercampany groups of organizations.
	For Each OSINMAGroup In TMCommonUseClientServer.Array(ArrayOSiIa) Do
		
		If OSINMAGroup.Count() < 2 Then
			Continue; // the organization already exists in the Winterkampany array
		EndIf;
		
		For Each IntercampanyGroup In IntercampanyArray Do
			
			If TMCommonUseClientServer.IntersectionOfArrays(IntercampanyGroup, OSINMAGroup).Count() > 0 Then
				
				MergeGroups = True;
				
				// Let's remember the organizations that have connections with others according to the OS and IA scheme.
				For Each OrganizationOSiIa In OSINMAGroup Do
					
					OrganizationsAboutSiIa.Insert(OrganizationOSiIa, True);
					TMCommonUseClientServer.AddNewValueToArray(IntercampanyGroup, OrganizationOSiIa);
					
				EndDo;
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Let's combine in the Intercampany array those groups of organizations that contain the same organizations.
	// For example:
	// 	-  in Intercompany was a group of organizations (1) (2) (3,4,5) (6) (7)
	//	- in fixed asset and intangible asset group (1,3) (4,5,6)
	//	- after the merger of the arrays in Intercompany became (1,3) (2) (3,4,5,6) (6); the group's fixed asset and intangible asset is no longer needed
	//	- now we need to combine the groups in the Intercampany so that it becomes (1,3,4,5,6) (2) (7)
	// , i.e. the calculation can be performed separately for organizations 2 and 7, and organizations (1,3,4,5,6) can only be calculated simultaneously.
	
	GroupCount = IntercampanyArray.Count();
	
	While MergeGroups Do
		
		HadChanges = False;
		
		For NumberOfGroup1 = 0 To GroupCount - 2 Do
			
			If IntercampanyArray[NumberOfGroup1].Count() = 0 Then 
				Continue;
			EndIf;
			
			For NumberOfGroup2 = NumberOfGroup1 + 1 To GroupCount - 1 Do
				
				If IntercampanyArray[NumberOfGroup2].Count() = 0 Then 
					Continue;
				EndIf;
				
				If TMCommonUseClientServer.IntersectionOfArrays(IntercampanyArray[NumberOfGroup1], IntercampanyArray[NumberOfGroup2]).Count() > 0 Then
					
					CommonClientServer.SupplementArray(IntercampanyArray[NumberOfGroup1], IntercampanyArray[NumberOfGroup2], True);
					IntercampanyArray[NumberOfGroup2].Clear();
					
					HadChanges = True;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		MergeGroups = HadChanges;
		
	EndDo;
	
	// Let's divide the organizations: groups of organizations separately, "single" organizations separately.
	If Not FastInitialization Then
		SingleOrganizations = New Array;
	Else
		SingleOrganizations = Common.CopyRecursive(AvailableCompanies);;
	EndIf;
	
	For NumberOfGroup = 0 To GroupCount - 1 Do
		
		GroupIndex = GroupCount - NumberOfGroup - 1;
		
		If IntercampanyArray[GroupIndex].Count() > 1 Then
			
			TMCommonUseClientServer.SortArray(IntercampanyArray[GroupIndex]);
			
		Else
			
			If IntercampanyArray[GroupIndex].Count() = 1 Then
				SingleOrganizations.Add(IntercampanyArray[GroupIndex][0]);
			EndIf;
			
			IntercampanyArray.Delete(GroupIndex);
			
		EndIf;
		
	EndDo;
	
	TMCommonUseClientServer.SortArray(SingleOrganizations);
	
	// Let's form a structure with a description of the organizations.
	Result = New Structure;
	
	Result.Insert("SingleOrganizations", 	  New FixedArray(SingleOrganizations));
	Result.Insert("GroupsOfOrganizations", 	  New FixedArray(IntercampanyArray));
	
	Result.Insert("IntercampanyOrganizations", New FixedMap(IntercampanyOrganizations));
	Result.Insert("OrganizationsAboutSiIa", 	  New FixedMap(OrganizationsAboutSiIa));
	Result.Insert("AvailableCompanies", 	  New FixedArray(AvailableCompanies));
	
	Result.Insert("ThereAreAccessRestrictions",  AvailableCompanies.Count() <> AllCompanies.Count());
	
	Return New FixedStructure(Result);
	
EndFunction

Function NameOfIntercampanyGroupOfOrganizations() Export
	Return NStr("vi = 'Công ty đa quốc gia';
				|ru = 'Интеркампани';
				|en = 'Intercompany'; fa = 'درون‌گروهی';
				|it = 'Intercompany';
				|pl = 'Intercompany';
				|tr = 'Şirketler arası'");
EndFunction

Function NameOfGroupOfOrganizationsAboutSiIa() Export
	Return NStr("vi = 'Quy tắc kế toán tài sản cố định và tài sản cố định vô hình';
				|ru = 'Правила учета ОС и НМА';
				|en = 'Fixed assets and intangible assets accounting rules'; fa = 'Fixed assets and intangible assets accounting rules';
				|it = 'Regole contabili per Capitale Fisso e Beni Immateriali';
				|pl = 'Zasady ewidencji ŚT oraz WNM';
				|tr = 'SK ve maddi olmayan varlıklar hesap kuralları'");
EndFunction

#EndRegion

#Region SettingFunctionalLockWhenUpdatingInformationSecurity

Procedure CheckBlockingIncomingDataWhenUpdatingInformationSecurity() Export
	
	IncomingData = New Map;
	IncomingData.Insert(Metadata.Catalogs.AccountingCheckRules);
	IncomingData.Insert(Metadata.InformationRegisters.LotAndCostCalculationErrors);
	IncomingData.Insert(Metadata.InformationRegisters.MonthEndChecklistsStatus);
	IncomingData.Insert(Metadata.InformationRegisters.SystemStatusIssues);
	IncomingData.Insert(Metadata.InformationRegisters.ObjectsOfSystemStatusIssues);
	IncomingData.Insert(Metadata.InformationRegisters.ScheduledJobsOfMonthEndClosing);
	IncomingData.Insert(Metadata.InformationRegisters.JobsForMonthEndClosing);
	
	MonthEndTransactionsServer.CheckBlockingIncomingDataWhenUpdatingInformationSecurity(
		IncomingData,
		NStr("vi = 'Kết chuyển cuối tháng';
			|ru = 'Закрытие месяца';
			|en = 'Month-end closing'; fa = 'بستن پایان ماه';
			|it = 'Chiusura del mese';
			|pl = 'Zamknięcie miesiąca';
			|tr = 'Ay sonu kapanışı'", Common.DefaultLanguageCode()));
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
