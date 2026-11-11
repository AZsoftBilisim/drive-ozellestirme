#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

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
	
	ReflectionParameters.DataPathConfigurationObject = "ReserveKind";
	ReflectionParameters.PathToDataLineOfBusiness = "LineOfBusiness";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.ManResources.Add("DiscountingAmountMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	ReflectionParameters.LocalResources.Add("DiscountingAmountCompl");
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(
		DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.AssetAndLiabilityItem.Insert("Value",
		ChartsOfCharacteristicTypes.AssetLiabilityItems.RemunerationProvisions);
	ReflectionParameters.StructureOfAnalytics.AssetsLiabilitiesDimension.DataPath = "ReserveKind";
	ReflectionParameters.StructureOfAnalytics.FinancialAccountingGroup.Insert("Value", Undefined);
	ReflectionParameters.StructureOfAnalytics.Counterparty.Insert("Value", Undefined);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
