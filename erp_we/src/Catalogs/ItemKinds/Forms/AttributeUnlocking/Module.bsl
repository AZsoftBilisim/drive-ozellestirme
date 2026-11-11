
#Region FormEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	Result = New Array;
	
	If AllowEditingTheTypeOfItem Then
		Result.Add("ItemsType");
		Result.Add("AccountingFeature");
	EndIf;
	
	If AllowEditingUsingCharacteristics Then
		Result.Add("UseCharacteristics");
		Result.Add("UseVariants");
		Result.Add("ItemVariantsOwner");
	EndIf;
	
	If AllowEditingTheSeriesUsage Then
		Result.Add("KeepAccountingByBatch");
		Result.Add("BatchAccountingPolicies");
		Result.Add("BatchUsageSettings");
		Result.Add("PrecisionOfBatchShelfLifeIndication");
		Result.Add("BatchOwner");
		Result.Add("BatchSettingsAreTakenFromOtherItemsKind");
		Result.Add("ThereAreIndividualSettingsOfSeriesAccountingPolicy");
	EndIf;
	
	If AllowEditingTheServiceRegistrationOption Then
		Result.Add("SaleRegistrationOption");
	EndIf;
	
	If AllowEditingAlcoholProducts Then
		Result.Add("AlcoholContainingProducts");
	EndIf;
	
	If AllowEditingContainsPreciousMaterials Then
		Result.Add("ContainsPreciousMetalsOrStones");
	EndIf;
	
	If AllowEditingTheSetConfigurations Then
		Result.Add("PresentationOptionInPrintForms");
		Result.Add("SetPricingOption");
	EndIf;
	
	If AllowEditingTheSetOptionOfProductCategories Then
		Result.Add("ProductCategoriesCommonWithAnotherKindOfItems");
		Result.Add("ProductCategoryOwner");
	EndIf;
	
	If AllowEditingPricing Then
		Result.Add("SettingsOfPriceKeyByItemVariant");
		Result.Add("SettingsOfPriceKeyByBatch");
		Result.Add("SettingsOfPriceKeyByPackage");
	EndIf;
	
	Close(Result);
	
EndProcedure // Allow Editing()

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AllowEditingUsingCharacteristics   = True;
	AllowEditingTheTypeOfItem              = True;
	AllowEditingTheSeriesUsage           = True;
	AllowEditingTheServiceRegistrationOption     = True;
	AllowEditingAlcoholProducts         = True;
	AllowEditingContainsPreciousMaterials = True;
	AllowEditingTheSetConfigurations               = True;
	AllowEditingTheSetOptionOfProductCategories = True;
	AllowEditingPricing              = True;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
