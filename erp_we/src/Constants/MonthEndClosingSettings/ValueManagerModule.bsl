#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of groups of technological parameters.
//
// Parameters:
//	Operation - CatalogRef.MonthEndClosingOperations
//
// Returns:
//	ValueTable - Description of parameter groups; for the table structure, see the code of the procedure for initializing the description of the operation parameter group.
//
Function DescriptionOfGroupsOfOperationParameters(Operation) Export
	
	If Operation = Catalogs.MonthEndClosingOperations.EmptyRef() Then
		DescriptionOfParameterGroups = MonthEndTransactionsServer.DescriptionOfGroupsOfParametersForMonthClosingOperation();
	ElsIf Operation = Catalogs.MonthEndClosingOperations.LotsAndCostCalculation Then
		DescriptionOfParameterGroups = CostCalculationAppliedAlgorithms.DescriptionOfGroupsOfParametersForMonthClosingOperation();
	Else // the operation has no groups of configurable parameters
		DescriptionOfParameterGroups = Undefined;
	EndIf;
	
	Return DescriptionOfParameterGroups;
	
EndFunction

// Generates a description of technological parameters.
//
// Parameters:
//	Operation - CatalogRef.MonthEndClosingOperations
//
// Returns:
//	ValueTable - description of parameters; for the table structure, see the code of the procedure for initializing the description of operation parameters.
//
Function DescriptionOfOperationParameters(Operation) Export
	
	If Operation = Catalogs.MonthEndClosingOperations.EmptyRef() Then
		
		ParametersDetails = MonthEndTransactionsServer.DescriptionOfTechnologicalParametersForClosingMonth();
		
	ElsIf Operation = Catalogs.MonthEndClosingOperations.LotsAndCostCalculation Then
		
		ParametersDetails = CostCalculationAppliedAlgorithms.DescriptionOfParametersOfMonthClosingOperation();
	ElsIf Operation = Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual Then
		
		ParametersDetails = FixedAssetDepreciationCalculation.DescriptionOfParametersOfMonthClosingOperation();
		
	ElsIf Operation = Catalogs.MonthEndClosingOperations.IntangibleAssetAmortizationAccrual Then
		
		ParametersDetails = IntangibleAssetAmortizationCalculation.DescriptionOfParametersOfMonthClosingOperation();
		
	ElsIf Operation = Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost Then
		
		ParametersDetails = FACostCalculation.DescriptionOfParametersOfMonthClosingOperation();
		
	ElsIf Operation = Catalogs.MonthEndClosingOperations.GenerateFixedAssetAndIntangibleAssetRecords
		Or Operation = Catalogs.MonthEndClosingOperations.UpdatingFARecordsBeforeCalculatingDepreciation Then
		
		ParametersDetails = DeferredFARecordGeneration.DescriptionOfParametersOfMonthClosingOperation();
		
	ElsIf Operation = Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets Then
		
		ParametersDetails = ClosingExpensesFromDisposalOfFixedAssets.DescriptionOfParametersOfMonthClosingOperation();
	ElsIf Operation = Catalogs.MonthEndClosingOperations.PostingGenerationInVATAccounting Then
		
		ParametersDetails = VATAccountingERP.DescriptionOfParametersOfMonthClosingOperation();
	Else // the operation has no configurable parameters
		
		ParametersDetails = Undefined;
		
	EndIf;
	
	Return ParametersDetails;
	
EndFunction

// Generates a description of the same parameters used in several operations.
// When you interactively change the value of such a parameter in one operation
// , the values of similar parameters in other operations are changed synchronously.
// Synced parameters must have the same name in all operations.
//
// Returns:
//	ValueTable - description of the parameters; see the table structure in the procedure code.
//
Function DescriptionOfSynchronizedOperationParameters() Export
	
	ParametersTable = New ValueTable;
	
	ParametersTable.Columns.Add("Name",      New TypeDescription("String")); // the service name of the parameter, as in the description of the operation parameters()
	ParametersTable.Columns.Add("Operations", New TypeDescription("Array")); // synchronized operations
	
	ParametersTable.Indexes.Add("Name");
	ParametersDetails = ParametersTable.Add();
	ParametersDetails.Name = "MaximumNumberOfTasksToCalculateDepreciation";
	ParametersDetails.Operations.Add(Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual);
	ParametersDetails.Operations.Add(Catalogs.MonthEndClosingOperations.IntangibleAssetAmortizationAccrual);
	Return ParametersTable;
	
EndFunction

// Generates an empty table for describing groups of process parameters.
//
// Returns:
// 	ValueTable:
// * Name - String -
// * Description - String -
// * LongDesc - String -
// * Hide - Boolean -
Function InitializeDescriptionOfGroupsOfOperationParameters() Export
	
	TableOfParameterGroups = New ValueTable;
	
	TableOfParameterGroups.Columns.Add("Name",			New TypeDescription("String")); // unique service name of the group
	TableOfParameterGroups.Columns.Add("Description",	New TypeDescription("String")); // group representation
	TableOfParameterGroups.Columns.Add("LongDesc",		New TypeDescription("String")); // detailed description of the purpose of the group
	TableOfParameterGroups.Columns.Add("Hide", 		New TypeDescription("Boolean")); // group parameters are not available for interactive modification
	
	// Let's add table indexes.
	TableOfParameterGroups.Indexes.Add("Name");
	
	Return TableOfParameterGroups;
	
EndFunction

// Generates an empty table for describing process parameters.
//
// Returns:
// 	ValueTable - LongDesc:
// * Name - String -
// * Description - String -
// * LongDesc - String -
// * OldNames - String -
// * Parent - String -
// * ValueType - TypeDescription -
// * ChoiceList - ValueList -
// * RangeWith - Number, Date -
// * RangeBy - Number, Date -
// * Hide - Boolean -
// * DefaultValue - Arbitrary -
// * AdditionalProperties - Arbitrary -
// 
Function InitializeDescriptionOfOperationParameters() Export
	
	ParametersTable = New ValueTable;
	
	ParametersTable.Columns.Add("Name",			New TypeDescription("String")); // unique service name of the parameter
	ParametersTable.Columns.Add("Description",	New TypeDescription("String")); // parameter representation
	ParametersTable.Columns.Add("LongDesc",		New TypeDescription("String")); // detailed description of the parameter assignment
	
	ParametersTable.Columns.Add("OldNames",	New TypeDescription("String")); // optional; name values in previous versions (separated by commas)
	
	ParametersTable.Columns.Add("Parent",		New TypeDescription("String")); // optional; name of the group, see initializationdescription of the operation parameter group
	
	ParametersTable.Columns.Add("ValueType",	New TypeDescription("TypeDescription"));     // type of parameter
	ParametersTable.Columns.Add("ChoiceList",	New TypeDescription("ValueList"));    // optional; possible parameter values (without manual input) - takes precedence over the "range"
	
	ParametersTable.Columns.Add("RangeWith",		New TypeDescription("Number, Date")); // optional; possible minimum value of the parameter
	ParametersTable.Columns.Add("RangeBy",	New TypeDescription("Number, Date")); // optional; possible maximum value of the parameter
	
	ParametersTable.Columns.Add("Hide", 		New TypeDescription("Boolean")); // the parameter value is not available for interactive modification
	
	ParametersTable.Columns.Add("DefaultValue");    // default parameter value
	ParametersTable.Columns.Add("AdditionalProperties"); // optional; arbitrary data for the month closing operation
	
	// Let's add table indexes.
	ParametersTable.Indexes.Add("Name");
	ParametersTable.Indexes.Add("Parent");
	
	Return ParametersTable;
	
EndFunction

// Returns user-defined values for process parameters.
//
// Parameters:
//	Operation - CatalogRef.MonthEndClosingOperations
//	HiddenOnesHaveDefaultValues - Boolean - for hidden parameters, the default value will be returned, regardless of whether there is a changed value.
//
// Returns:
//	Structure - parameter values
//		Key - parameter name
//		Value is the value of the parameter; if the value has not been changed, the default value of the parameter is returned.
//
Function SetValuesOfOperationParameters(Operation, HiddenOnesHaveDefaultValues = True) Export
	
	Result = New Structure;
	ParametersDetails = DescriptionOfOperationParameters(Operation);
	
	If ParametersDetails = Undefined Then
		ParametersDetails = InitializeDescriptionOfOperationParameters();
	EndIf;
	
	// We will get the saved parameter values.
	SetPrivilegedMode(True);
	SavedSettings = Constants.MonthEndClosingSettings.Get().Get(); // getting the contents of the value store
	SetPrivilegedMode(False);
	
	If TypeOf(SavedSettings) = Type("Map") Then
		SavedSettings = SavedSettings.Get(Operation); // we will get the parameters of operation for closing the month
	Else
		SavedSettings = Undefined;
	EndIf;
	
	If Not ValueIsFilled(SavedSettings) Or TypeOf(SavedSettings) <> Type("Structure") Then
		SavedSettings = New Structure; // there are no saved parameters of operation
	EndIf;
	
	SavedValue = Undefined;
	
	For Each CurrentRow In ParametersDetails Do
		
		Result.Insert(CurrentRow.Name, CurrentRow.DefaultValue); // to begin with, let's take the value equal to the default value
		
		If HiddenOnesHaveDefaultValues And CurrentRow.Hide Then
			Continue; // the default value regardless of whether there is a changed value
		EndIf;
		
		IsChanged = SavedSettings.Property(CurrentRow.Name, SavedValue);
		
		If Not IsChanged And ValueIsFilled(CurrentRow.OldNames) Then
			
			// Let's check if there are saved values with the old parameter name.
			OldNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(CurrentRow.OldNames);
			
			For Each OldName In OldNames Do
				
				IsChanged = SavedSettings.Property(TrimAll(OldName), SavedValue);
				
				If IsChanged Then
					Break; // there is a stored value
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Not IsChanged Or Not CurrentRow.ValueType.ContainsType(TypeOf(SavedValue)) Then
			Continue; // default value
		EndIf;
		
		// Let's check that the stored value has a valid value.
		If ValueIsFilled(CurrentRow.ChoiceList) Then
			
			If CurrentRow.ChoiceList.FindByValue(SavedValue) = Undefined Then
				Continue; // default value
			EndIf;
			
		ElsIf CurrentRow.RangeWith <> CurrentRow.RangeBy Then // the range is set
			
			If CurrentRow.RangeWith <> Undefined And SavedValue < CurrentRow.RangeWith Then
				Continue; // default value
			ElsIf CurrentRow.RangeBy <> Undefined And SavedValue > CurrentRow.RangeBy Then
				Continue; // default value
			EndIf;
				
		EndIf;
		
		Result.Insert(CurrentRow.Name, SavedValue); // there is a stored value and this value meets all the constraints
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Returns values of process parameters for all operations.
//
// Returns:
//  Map - parameters of month closing operations.
//
Function ReadAllParameters() Export
	
	AllParameters = New Map;
	
	ReadOperationParameters(Catalogs.MonthEndClosingOperations.EmptyRef(), AllParameters);
	
	Selection = Catalogs.MonthEndClosingOperations.Select();
	While Selection.Next() Do
		ReadOperationParameters(Selection.Ref, AllParameters);
	EndDo;
	
	Return AllParameters;
	
EndFunction

// Returns the values of the process parameters of the specified operation.
//
Procedure ReadOperationParameters(Operation, AllParameters)
	
	ParametersDetails = DescriptionOfOperationParameters(Operation);
	
	If Not ValueIsFilled(ParametersDetails) Then
		Return;
	EndIf;
	
	DescriptionOfParameterGroups = DescriptionOfGroupsOfOperationParameters(Operation);
	ParameterValues = SetValuesOfOperationParameters(Operation, False);
	
	AllParameters.Insert(
		Operation,
		New Structure("DescriptionOfParameterGroups, ParametersDetails, ParameterValues", DescriptionOfParameterGroups, ParametersDetails, ParameterValues));
	
EndProcedure

// Saves the changed technological parameters.
// In the settings store there is a match:
//	The key is the Directories element.Month Closure operationsreferences
//	Value - the structure of the parameters of this stage
//		Key - name of the parameter
//		Value - the value of the parameter.
//
Procedure SaveAllParameters(AllParameters) Export
	
	SavedSettings = New Map;
	
	For Each KeyAndValue In AllParameters Do
		
		OperationParametersList = New Structure;
		
		For Each ParameterDetails In KeyAndValue.Value.ParametersDetails Do
			
			ParameterValue = KeyAndValue.Value.ParameterValues[ParameterDetails.Name];
			
			If ParameterValue <> ParameterDetails.DefaultValue Then
				OperationParametersList.Insert(ParameterDetails.Name, ParameterValue); // save the changed
			EndIf;
			
		EndDo;
		
		If ValueIsFilled(OperationParametersList) Then
			SavedSettings.Insert(KeyAndValue.Key, OperationParametersList);
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(True);
	Constants.MonthEndClosingSettings.Set(New ValueStorage(SavedSettings, New Deflation(9)));
	SetPrivilegedMode(False);
	
	RefreshReusableValues();
	
EndProcedure

#EndRegion

#EndIf
