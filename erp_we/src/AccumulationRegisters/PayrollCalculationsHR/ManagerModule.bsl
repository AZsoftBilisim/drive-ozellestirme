#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines register metrics.
//
//
// Parameters:
//  Properties - Structure - containing the keys of the properties of Indicators, properties of Resources.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function Indicators(Properties) Export

	Indicators = New Map;
	
	PropertiesOfIndicators = Properties.PropertiesOfIndicators;
	ResourceProperties = Properties.ResourceProperties;
	
	// The array contains not only register resources, but also fields derived from them in queries.
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "Sum", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInCurrency", "Currency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaid", "Currency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaid, New Structure(PropertiesOfIndicators, ArrayOfResources));

	Return Indicators;
	
EndFunction

// Fills in the parameters for reflecting register movements in financial accounting
//
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
//
// Returns:
// 	See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	ReflectionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection);
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(
		DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	For Each Dimension In ReflectionParameters.StructureOfAnalytics Do
		Dimension.Value.Insert("Value", Undefined);
	EndDo;
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

#EndRegion

#EndIf
