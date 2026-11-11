////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Non-current assets" intended for localization.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region FormOfObjectOfOperation

Procedure ConfigureDependentFormElements_Objects_(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure AddPropertyValuesForDependentProps_ObjectsOfOperation(Object, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

#EndRegion

#Region OperationObjectListForm

Procedure FillInInformationInFAListForm(Form, InformationRecords2_4, InformationRecords2_2) Export

	
EndProcedure

Procedure SetFiltersInFAListForm(Form) Export

	
EndProcedure

#EndRegion

#Region FormIntangibleAssets

Procedure ConfigureDependentFormElements_IntangibleAssets(Form, StructureOfChangedProps) Export

	
EndProcedure
 
#EndRegion

#Region IAListForm

Procedure FillInInformationInIAListForm(Form, InformationRecords2_4, InformationRecords2_2) Export

	
EndProcedure

#EndRegion

#Region RecognizeSubAssetsComponentsOfDepreciation

Procedure SupplementValuesOfPropertiesOfDependentProps_AcceptanceOfDepreciationComponentNodesForAccounting(Object, AuxiliaryAttributes, ParametersForTakingIntoAccountDepreciationComponents, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

#EndRegion

#Region FixedAssetsCostAdditions

Procedure SupplementValuesOfPropertiesOfDependentProps__FA(Object, AuxiliaryAttributes, FAUpgradeOptions, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure AddAuxiliaryDetails_UpgradingFA(Form, AuxiliaryAttributes) Export

	
EndProcedure

Procedure ConfigureDependentFormElements_UpgradeFA(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure WhenChangingBankingDetails_UpgradeFA(Object, AuxiliaryAttributes, AttributesList) Export

	
EndProcedure

#EndRegion

#Region AllocateVariancesToFixedAssetCost

Procedure AddPropertyValuesForDependentProps_AttributionOfDeviationsToCostOfFA(Object, AuxiliaryAttributes, DocumentParameters, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure AddAuxiliaryDetails_AttributionOfDeviationsToCostOfFA(Form, AuxiliaryAttributes) Export

	
EndProcedure

Procedure ConfigureDependentFormElements_AttributionOfDeviationsToCostOfFA(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure OnChangeOfBankingDetails_AttributionOfDeviationsToCostOfFA(Object, AuxiliaryAttributes, AttributesList) Export

	
EndProcedure

#EndRegion

#Region ChangeFixedAssetFinancialDetails

Procedure SupplementValuesOfPropertiesOfDependentProps_ChangeFAParameters(Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure
 
Procedure AddAuxiliaryProps_ChangeFAParameters(Form, AuxiliaryAttributes) Export

	
EndProcedure

Procedure ConfigureDependentFormElements_ChangeFASettings(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure SetVisibilityOfCurValues_ChangeFASettings(Form, NumberOfChangedProperties, StructureOfChangedProps) Export

	
EndProcedure

#EndRegion

#Region ChangeIntangibleAssetFinancialDetails

Procedure SupplementValuesOfPropertiesOfDependentProps_ChangeParametersOfIA(Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters) Export
	
	
EndProcedure

Procedure ConfigureDependentFormElements_ChangeIAParameters(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure SetVisibilityOfCurValues_ChangeIAParameters(Form, NumberOfMaProperties, NumberOfPropertiesShared, PropertiesCountLocalization, StructureOfChangedProps) Export

	
EndProcedure

#EndRegion

#Region DisposeFixedAssets

Procedure AddPropertyValuesForDependentDetails_WriteOffFA(Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure AddAuxiliaryDetails_WriteOffFA(Form, AuxiliaryAttributes) Export

	
EndProcedure

#EndRegion

#Region DisposeIntangibleAssets

Procedure AddPropertyValuesForDependentDetails_WriteOffIA(Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure AddAuxiliaryDetails_WriteOffOfIa(Form, AuxiliaryAttributes) Export

	
EndProcedure

#EndRegion

#Region MergeOfFixedAssets

Procedure SupplementValuesOfPropertiesOfDependentProps_FAUnion(Object, AuxiliaryAttributes, FAPoolingOptions, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure
 
Procedure FillInDetailsDependingOnProperties__FA_(Object, AttributeParameters, Action, ChangedBankingDetails) Export

	
EndProcedure
 
#EndRegion

#Region SplitFixedAssets

Procedure SupplementValuesOfPropertiesOfDependentProps_FADisassembly(Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

#EndRegion

#Region CustomerInvoiceServicesAndAssets

Procedure SupplementValuesOfPropertiesOfDependentDetails_SaleOfServicesOfOtherAssets(Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure SupplementAuxiliaryDetails_SaleOfServicesOfOtherAssets(Form, AuxiliaryAttributes) Export

	
EndProcedure
 
Procedure WhenChangingDetails_SaleOfServicesOfOtherAssets(Form, ChangedBankingDetails) Export
	
	
EndProcedure

Procedure ConfigureDependentFormElements_ImplementServicesOtherAssets(Form, StructureOfChangedProps) Export

	
EndProcedure
 
#EndRegion

#Region IntangibleAssetImprovement

Procedure SupplementValuesOfPropertiesOfDependentProps_IAImprovement(Object, AuxiliaryAttributes, IAImprovementParameters, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure AddAuxiliaryDetails_IAImprovement(Form, AuxiliaryAttributes) Export

	
EndProcedure

#EndRegion

#Region Other

// 
// Parameters:
//  Receiver - Structure - Receiver
//  ERPParameters - Structure - ERP parameters
Procedure AddAccountingPolicyParameters(Receiver, ERPParameters) Export
	
	
EndProcedure

Procedure AddAcceptanceParametersToAccountingOfBalanceInputAxis(Object, AuxiliaryAttributes, FAAcceptanceParameters) Export

	
EndProcedure

Procedure ToSupplementParametersOfAcceptanceToAccountingOfNMAIInputBalances(Object, AuxiliaryAttributes, AccountingAcceptanceParameters) Export
	
	
EndProcedure

Function WhenChangingAccountingOrderOfBU_OS(Object, FormServiceParameters = Undefined, ThereIsAccountingProcedureWELL = True) Export

	ChangedBankingDetails = "";
	
	
	Return ChangedBankingDetails;
	
EndFunction

#EndRegion


#Region Other

Procedure SupplementChangedDetails_ChangeParametersOfIA(AttributesToChange) Export

	
EndProcedure

#EndRegion

#EndRegion
