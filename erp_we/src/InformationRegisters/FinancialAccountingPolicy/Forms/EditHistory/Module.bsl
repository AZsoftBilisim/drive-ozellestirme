
#Region Variables

&AtClient
Var DeletionParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Organization = Parameters.Organization;
	ReadOnly = Parameters.ReadOnly;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal, , 
		ValueIsFilled(Organization),,);
		
	VNASettingIsAvailable = False;
	LocalFAAccounting = False;
	VNASettingIsAvailable = GetFunctionalOption("UseNonCurrentAssets2_4");
	LocalFAAccounting = GetFunctionalOption("LocalFAAccounting");
	If VNASettingIsAvailable Then
		
		If LocalFAAccounting Then
			Items.ListProcedureOfFixedAssetDepreciationChargeLocal.Visible = False;
			Items.ListLeasedAssetDepreciationChargedProcedureLocal.Visible = False;
			Items.ListProcedureOfIntangibleAssetAmortizationChargeLocal.Visible = False;
			Items.ListFixedAssetAccountingProcedureInLocalAccounting.Visible = False;
		EndIf;
		
	Else
		Items.ListProcedureOfFixedAssetDepreciationCharge.Visible = False;
		Items.ListLeasedAssetDepreciationChargeProcedureManag.Visible = False;
		Items.ListProcedureOfIntangibleAssetAmortizationCharge.Visible = False;
		Items.ListProcedureOfFixedAssetDepreciationChargeLocal.Visible = False;
		Items.ListLeasedAssetDepreciationChargedProcedureLocal.Visible = False;
		Items.ListProcedureOfIntangibleAssetAmortizationChargeLocal.Visible = False;
		Items.ListAccountingForRentAccordingToFSB252018.Visible = False;
		Items.ListFixedAssetAccountingProcedureInLocalAccounting.Visible = False;
		Items.ListFixedAssetRevaluationMethod.Visible = False;
		Items.ListIntangibleAssetRevaluationMethod.Visible = False;
	EndIf;
			
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Add(Command)
	NotifyChoice(New Structure("Organization, Period", 
		Organization,
		CommonClient.SessionDate()));
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	NotifyChoice(RowSelected);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure Select(Command)
	NotifyChoice(Items.List.CurrentRow);
EndProcedure

&AtServerNoContext
Procedure DeleteDiscountRates(Period, Organization)
	RecordSet = InformationRegisters.DiscountRates.CreateRecordSet();
	RecordSet.Filter.Period.Set(Period);
	RecordSet.Filter.Organization.Set(Organization);
	RecordSet.Write();
EndProcedure

&AtClient
Procedure ListAfterDeleteRow(Item)
	If DeletionParameters <> Undefined Then
		DeleteDiscountRates(DeletionParameters.Period, DeletionParameters.Organization);
		DeletionParameters = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then
		DeletionParameters = New Structure;
		DeletionParameters.Insert("Period", CurrentData.Period);
		DeletionParameters.Insert("Organization", CurrentData.Organization);
	EndIf;
EndProcedure

#EndRegion