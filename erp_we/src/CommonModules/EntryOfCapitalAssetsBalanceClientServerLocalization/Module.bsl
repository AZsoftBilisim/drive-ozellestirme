////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Entering balances of non-current assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region FALineEditingForm

Procedure FormEditStringOS_ConfigureDependentFormElements(Form, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Function FormEditStringOS_RequiredToRecalculateDependentAmounts(StructureOfChangedProps) Export

	ItIsRequiredToRecalculateDependentAmounts = False;
	
	
	Return ItIsRequiredToRecalculateDependentAmounts;

EndFunction

Procedure FormForEditingOS_LineWhenChangingBankingDetails(Form, AttributesList) Export

	
EndProcedure

Procedure LineEditFormOS_RecalculateDependentAmounts(Form) Export
	
	
EndProcedure

Procedure LineEditingFormOS_RecalculateTotals(Form) Export

	
EndProcedure

Procedure FormForEditingLineOS_SupplementValuesOfDetailsBeforeChange(Form, AttributesValuesBeforeChange) Export

	
EndProcedure
 
#EndRegion

#Region IALineEditingForm

Procedure FormEditStringNMA_ConfigureDependentFormElements(Form, StructureOfChangedProps, ParametersForEnteringIAResidues, ItemDetailsParameters) Export

	
EndProcedure

Function Nma_LineEditingFormNeedsToRecalculateDependentAmounts(StructureOfChangedProps) Export

	ItIsRequiredToRecalculateDependentAmounts = False;
	
	
	Return ItIsRequiredToRecalculateDependentAmounts;

EndFunction

Procedure IALineEditingForm_OnChangeAttributes(Form, AttributesList) Export

	
EndProcedure

Procedure FormForEditingLineNMA_SupplementValuesOfDetailsBeforeChange(Form, AttributesValuesBeforeChange) Export

	
EndProcedure

Procedure RowEditFormNMA_RecalculateDependentAmounts(Form) Export
	
	CFMultiplier = ?(Form.ApplicationOfTargetFinancing, 1, 0);
	
	If Not Form.InitialCostIsDifferent Then
		
		Form.InitialCostLocalAccounting = Form.CurrentcCostFinAcc + Form.CurrentCostAccountingTargetFinancing * CFMultiplier;
		Form.InitialCostTA = Form.CurrentCostTaxAccounting + Form.CurrentCostTaxAccountingTargetFinancing * CFMultiplier;
		
	EndIf;
	
	// Time differences are not edited
	Form.CurrentCostTD         = Form.CurrentcCostFinAcc         - Form.CurrentCostTaxAccounting         - Form.CurrentcCostPD;
	Form.CurrentValueOfTheGRCF       = Form.CurrentCostAccountingTargetFinancing       - Form.CurrentCostTaxAccountingTargetFinancing       - Form.CurrentCostTargetFinancingPD;
	Form.AccumulatedDepreciationTD   = Form.AccumulatedDepreciationAccounting   - Form.AccumulatedDepreciationTaxAccounting   - Form.PermanentDifferenceInEvaluationOfAccumulatedDepreciation;
	Form.AccumulatedDepreciationTDSPF = Form.AccumulatedDepreciationAccountingTargetFinancing - Form.AccumulatedDepreciationTaxAccountingTargetFinancing - Form.AccumulatedDepreciationTargetFinancingPD;
	
	// The residual value is not edited
	Form.TAResidualValue   = Form.CurrentCostTaxAccounting   - Form.AccumulatedDepreciationTaxAccounting;
	Form.PDResidualValue   = Form.CurrentcCostPD   - Form.PermanentDifferenceInEvaluationOfAccumulatedDepreciation;
	Form.TDResidualValue   = Form.CurrentCostTD   - Form.AccumulatedDepreciationTD;
	
	Form.ACSPFResidualValue = Form.CurrentCostAccountingTargetFinancing - Form.AccumulatedDepreciationAccountingTargetFinancing;
	Form.TASPFResidualValue = Form.CurrentCostTaxAccountingTargetFinancing - Form.AccumulatedDepreciationTaxAccountingTargetFinancing;
	Form.PDSPFResidualValue = Form.CurrentCostTargetFinancingPD - Form.AccumulatedDepreciationTargetFinancingPD;
	Form.TDSPFResidualValue = Form.CurrentValueOfTheGRCF - Form.AccumulatedDepreciationTDSPF;
	
EndProcedure

#EndRegion

#Region Other

Procedure PaddingPropertyValuesOfDependentProps_EnteringResidues__(Object, AuxiliaryAttributes, ParametersForEnteringFABalances, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure SupplementValuesOfPropertiesOfDependentProps_EnterResidues_NM(Object, AuxiliaryAttributes, ParametersForEnteringIAResidues, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure AddPropertyValuesForDependentProps_OBEntry_NodesComponents(Object, AuxiliaryAttributes, ParametersForEnteringFABalances, StructureOfChangedProps, ItemDetailsParameters) Export

	
EndProcedure

Procedure AddParametersForEnteringFABalances(Object, AuxiliaryAttributes, ParametersForEnteringFABalances) Export
	
	
EndProcedure

Procedure SupplementParametersForEnteringIAResidues(Object, AuxiliaryAttributes, ParametersForEnteringIAResidues) Export
	
	
EndProcedure

#EndRegion

#EndRegion
