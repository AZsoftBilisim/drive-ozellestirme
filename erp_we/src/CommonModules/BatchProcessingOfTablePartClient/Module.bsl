
#Region Public

// Processing the table part string-called from document forms.
//
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSStrings.
//  StructureOfActions - See  BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//  AdditionalFillingParameters - Structure, Undefined - additional filling parameters.
//
Procedure ProcessTSString(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters = Undefined) Export
	
	If CachedValues = Undefined 
		Or Not CachedValues.Count() Then
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If ServerCallRequired(CurrentRow, StructureOfActions, CachedValues) Then
		
		CurRowStructure = BatchProcessingOfTablePartClientServer.GetCurLine(
									CurrentRow, 
									StructureOfActions,
									CachedValues,
									AdditionalFillingParameters);
									
		WhenFormingStructureForProcessedLine(CurrentRow, StructureOfActions, CachedValues);
		
		BatchTableProcessingServerCall.ProcessTSString(CurRowStructure,
			StructureOfActions,
			CachedValues);
		
		FillPropertyValues(CurrentRow,CurRowStructure);
		
		Return;
	EndIf;
	
	InventoryInOperationClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues,
		AdditionalFillingParameters);
	RebatesClient.ProcessTSString(
		CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters);

	FillInServiceDetailsForProductInLineTS(CurrentRow, StructureOfActions, CachedValues);
	CheckCorrectnessOfTechnicalSpecificationsAndPackaging(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.FillInSpaceInTSLine(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInDefaultCCDNumberType(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInCountryOfOriginForDefaultCCDNumber(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.RecalculateQuantityDoNotShipToTSLine(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesAfterFactInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesFactByPackagesInPMLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateNumberOfSuffixPacksFromDeviationInTSString(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClientServer.RecalculateNumberOfUnitsInTSString(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateNumberOfSuffixUnitsInTSString(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateQuantityByRNPTVAndTS(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateQuantityByRnptSuffixInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateNumberOfSuffixPacksInTSString(CurrentRow, 
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountOfDeviation(CurrentRow, StructureOfActions,
		CachedValues);
	RecalculateNumberOfPackagesByWeight(CurrentRow, StructureOfActions, CachedValues);
	RecalculateNumberOfPackagesByVolume(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateWeightVolumeInTSString(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.FillInPriceTypeInTSLine(CurrentRow, StructureOfActions); 
	BatchProcessingOfTablePartClientServer.RecalculatePricePerPackageInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateOrderPricePerPackageInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	RecalculatePriceOffBalancePerPackageInTSLine(CurrentRow, StructureOfActions, CachedValues);
	FillInRetailSalePriceInTSLine(CurrentRow, StructureOfActions, CachedValues);
	FillInSalesConditionsInTSLine(CurrentRow, StructureOfActions, CachedValues);
	FillInTermsOfRetailSalesInTSLine(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClient.FillInProductionDate(CurrentRow, StructureOfActions,
		CachedValues);
	CheckFillInIssuePriceInTSLine(CurrentRow, StructureOfActions, CachedValues);
	FillInPriceOfTransferOfProductsToGiverInLineTS(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.FillInDefaultStorageLocationType(CurrentRow, StructureOfActions,
		CachedValues);
	FillInBidNDSVLineTS(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.FillInVATRateOfReturnableContainerInLineTS(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculatePercentageOfManualDiscountInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountOfManualDiscountInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountOfAutomaticDiscountInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountOfServiceInLineTSOrderGiver(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountInLineTSOrderGiver(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateSumOfSuffixInTSString(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountInTSLineOfDiscrepancy(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateDiscountPriceByAmountInSalesInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateDiscountPriceByAmountInPurchasesInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculatePriceByAmountInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculatePriceByAmountInTSLineOfGiverSOrder(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateSalePriceBySaleAmountInTSLine(CurrentRow,
		StructureOfActions);
	RecalculateOutOfBalancePriceByOutOfBalanceAmountInTSLine(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountTakingIntoAccountAutomaticDiscountInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountTakingIntoAccountManualDiscountInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountTakingIntoAccountDiscountWithBonusPointsInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	RecalculateAmountOfNDSVInTSLine(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountOfVATSuffixInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateSumOfSNDSInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateSumWithVATSuffixInTSString(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutNDSVToTSLine(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.RecalculateLocalSumInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutVATLocalInTSLine(CurrentRow, StructureOfActions, 
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutVATManInTSLine(CurrentRow, StructureOfActions, 
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutVATLocalSuffixInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutVATManSuffixInTSLine(CurrentRow, StructureOfActions, 
		CachedValues);
	RecalculateAmountOfLocalOffBalanceInTSLine(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateSumOfPRVAndTS(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateSumOfNuvInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountOfVRVTS(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateLocalVATInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateSaleAmountInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateAmountOfSaleOfNDSVToTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.SetStringActivity(CurrentRow, StructureOfActions,
		CachedValues);
	CheckGetConfigurationOption(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInDiscrepancyFlag(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesDeviation(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillExcessSpoilageFlag(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.ClearAmountOfSettlementsInTSLine(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.ClearSumOfMutualSettlementsSuffixInTSLine(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClientServer.SetVATAmountOfLocalManInTSLine(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.RecalculateVATAmountOfShipmentInTSLine(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.ClearAutomaticDiscountInTSLine(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.ClearRewardAmountInTSLine(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInForm(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInNoReturnContainerAttribute(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInCanceledWithoutReturnableContainerAttribute(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInActivityWithoutReturnableContainerAttribute(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInDuplicateDependentDetails(CurrentRow, StructureOfActions);
	CheckSeriesCalculateStatus(CurrentRow, StructureOfActions);
	CheckBatchByOwner(CurrentRow, StructureOfActions);
	CheckBarcodeRegistration(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.RecalculateAmountInExcessOfOrderInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.FillInOptionToReflectImplementationAdjustment(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClient.ProductsOnChangeOverridable(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClient.CharacteristicOnChangeOverridable(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.FillDiscrepanciesAfterShipment(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInDiscrepanciesAfterAcceptance(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInTheDiscrepancies(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInAcceptanceCommentFlag(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInSignForShipmentComment(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInFlagForComments(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInItemLocationAttributeProcessingRequired(CurrentRow,
		StructureOfActions);
	FillInTrafficFlagForWarehouseRegisters(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInActionForRecyclableMaterialsInTSLine(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.CheckFillAssignmentInLineTS(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.FillFlagSeparatelyAsIntended(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.FillInPurposeOfProvisionInProductionPhase(CurrentRow,
		StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.FillInAssignmentInProductionPhase(CurrentRow, StructureOfActions);
	BatchProcessingOfTablePartClientServer.WhenChangingAssignmentInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.FillInMethodForDeterminingCost(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClientServer.FillInCostDeterminationMethodWithLine(CurrentRow,
		StructureOfActions);
	BatchProcessingOfTablePartClient.CheckFillSpecification(CurrentRow, StructureOfActions,
		CachedValues);
	FillInShopPantryAttribute(CurrentRow, StructureOfActions, CachedValues);
	CheckFillInCostShare(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.RecalculateFractionOfCostInTSLine(CurrentRow, StructureOfActions,
		CachedValues);
	BatchProcessingOfTablePartClientServer.CheckFillCommunicationKeySpecifications(CurrentRow,
		StructureOfActions, CachedValues);
	FillInProductOwnerIsAvailable(CurrentRow, StructureOfActions, CachedValues);
	FillInDirectionOfActivity(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.FillInWriteOFFAttributeForExpensesAndDivision(CurrentRow, StructureOfActions,
		CachedValues);
	FillInSubdivisionInTSLine(CurrentRow, StructureOfActions, CachedValues);
	FillInDiscrepancyAttributeOrder(CurrentRow, StructureOfActions, CachedValues);
	FillInDestinationType(CurrentRow, StructureOfActions, CachedValues);
	FillInExcisableItemAttribute(CurrentRow, StructureOfActions, CachedValues);
	RecalculateExciseTaxAmountInTSLine(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClientServer.FillInPresentationOfTermsOfPurchase(CurrentRow, StructureOfActions, CachedValues);
	
	BatchProcessingOfTablePartClientLocalization.ProcessTSString(CurrentRow, StructureOfActions,
		CachedValues);
	
EndProcedure

#EndRegion

#Region Private

#Region RecalculationAndFillingProcedures

Procedure CheckGetConfigurationOption(CurrentRow, StructureOfActions)

	If Not StructureOfActions.Property("CheckCompleteConfigurationOptionByOwner") Then
		Return;
	EndIf;

	If Not ValueIsFilled(CurrentRow.Products)
	 Or Not ValueIsFilled(CurrentRow.Characteristic) And CurrentRow.ItemVariantsAreUsed Then

		CurrentRow.ProductKit = Undefined;

	EndIf;

EndProcedure

Procedure CheckCorrectnessOfTechnicalSpecificationsAndPackaging(CurrentRow, StructureOfActions, CachedValues)

	If StructureOfActions.Property("CheckCharacteristicsByOwner") Then
		CurrentRow.Characteristic             = Undefined;
		CurrentRow.ItemVariantsAreUsed = False;
	EndIf;

	If StructureOfActions.Property("CheckFillPackageByOwner") Then
		CurrentRow.Package = Undefined;
	EndIf;

EndProcedure

Procedure FillInBidNDSVLineTS(CurrentRow, StructureOfActions, CachedValues) 

	If StructureOfActions.Property("FillInVATRate") Then
		CurrentRow.VATRate = Undefined;
	EndIf;

EndProcedure

Procedure RecalculateAmountOfNDSVInTSLine(CurrentRow, StructureOfActions, CachedValues) 
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateVATAmount", StructureOfActionParameters) Then
		
		VATTaxation = Undefined;
		StructureOfActionParameters.Property("VATTaxation", VATTaxation);
		
		VATRate = Undefined;
		If Not StructureOfActionParameters.Property("VATRate", VATRate) Then
			VATRate = CurrentRow.VATRate;
		EndIf;
		
		If CachedValues.Property("PercentOfVATRates") Then
			CurPercentVAT = CachedValues.PercentOfVATRates[VATRate];
		Else
			CachedValues.Insert("PercentOfVATRates", New Map);
			CurPercentVAT = Undefined;
		EndIf;
		
		If CurPercentVAT = Undefined Then
			
			CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
			CachedValues.PercentOfVATRates.Insert(VATRate, CurPercentVAT);
			
		EndIf;
		
		CurrentRow.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
			CurrentRow.Sum,
			CurPercentVAT,
			StructureOfActionParameters.PriceIncludesVAT,
			VATTaxation);
	EndIf;
	
EndProcedure

Procedure FillInSalesConditionsInTSLine(CurrentRow, StructureOfActions, CachedValues) 

	If StructureOfActions.Property("FillIn_TermsOfSales") Then
		
		If CurrentRow.Property("PriceKind") Then
			CurrentRow.PriceKind = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
		EndIf;
		CurrentRow.VATRate = PredefinedValue("Catalog.VATRates.EmptyRef");
	EndIf;

EndProcedure

Procedure FillInTermsOfRetailSalesInTSLine(CurrentRow, StructureOfActions, CachedValues) 

	If StructureOfActions.Property("FillInRetailSalesTermsAndConditions") Then		
		CurrentRow.VATRate = PredefinedValue("Catalog.VATRates.EmptyRef");
	EndIf;

EndProcedure

Procedure FillInServiceDetailsForProductInLineTS(CurrentRow, StructureOfActions, CachedValues)
	
	If StructureOfActions.Property("FillInProductTypeAttribute_") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInProductTypeAttribute_", "ItemsType")]
			= PredefinedValue("Enum.ItemsTypes.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillInProductTypeAttribute") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInProductTypeAttribute", "ProductKind")]
			= PredefinedValue("Catalog.ItemKinds.EmptyRef");
	EndIf; 
	
	If StructureOfActions.Property("FillInUnitOfMeasurementAttribute") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInUnitOfMeasurementAttribute", "UnitOfMeasure")]
			= PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillInMeasuredValueTypeAttribute") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInMeasuredValueTypeAttribute", "MeasuredValueType")]
			= PredefinedValue("Enum.TypesOfMeasuredValues.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillPackageWeight") Then
		CurrentRow.PackageWeight = 0;
	EndIf;
	
	If StructureOfActions.Property("FillPackageVolume") Then
		CurrentRow.PackageVolume = 0;
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfWeight") Then
		CurrentRow.UnitOfMeasureForWeight = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillInVolumeUnit") Then
		CurrentRow.UnitOfMeasureForVolume = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillInFeatureAttribute") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInFeatureAttribute", "ItemVariantsAreUsed")]
			= False;
	EndIf;
	
	If StructureOfActions.Property("FillInCCDTrackingAttribute") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInCCDTrackingAttribute", "TheRecordsAreKeptByCCD")]
			= PredefinedValue("Enum.ItemsTypes.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillInCountryOfOriginOfProduct") Then
		CurrentRow.OriginCountry = PredefinedValue("Catalog.WorldCountries.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillInRnptTrackingAttribute") Then
		CurrentRow.AccountingForTheRNPTIsMaintained = False;
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfMeasurementOfFEA") Then
		CurrentRow.FEACNUnitOfMeasure = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillInFeatureThisIsService") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInFeatureThisIsService", "IsService")] = False;
	EndIf;
	
	If StructureOfActions.Property("FillInArticleAttribute") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInArticleAttribute", "SKU")] = "";
	EndIf;

	If StructureOfActions.Property("FillInCodeAttribute") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInCodeAttribute", "Code")] = "";
	EndIf;

	If StructureOfActions.Property("FillInDescriptionAttribute") Then
		CurrentRow[NameOfFillingField(StructureOfActions, "FillInDescriptionAttribute", "LongDesc")] = "";
	EndIf;

	If StructureOfActions.Property("FillInSeriesAttribute") Then
		CurrentRow.SeriesAreUsed = False;
	EndIf;
	
	BatchProcessingOfTablePartClientLocalization.FillInServiceDetailsForProductInLineTS(
		CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

Function NameOfFillingField(StructureOfActions, Action, DefaultFieldName)
	
	ActionParameters = Undefined;
	StructureOfActions.Property(Action, ActionParameters);
	If ActionParameters = Undefined Then
		Return DefaultFieldName;
	Else
		For Each KeyAndValue In ActionParameters Do
			Return KeyAndValue.Value;
		EndDo;
	EndIf;
	
EndFunction

Procedure FillInRetailSalePriceInTSLine(CurrentRow, StructureOfActions, CachedValues) 
	
	If StructureOfActions.Property("FillRetailSalePrice") Then
		CurrentRow.Price = 0;
	EndIf;
	
EndProcedure

Procedure CheckSeriesCalculateStatus(CurrentRow, StructureOfActions)
	
	Var ActionParameters;
	
	If StructureOfActions.Property("CheckSeriesCalculateStatus",ActionParameters) Then
		If ActionParameters.SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
			CurrentRow.Series = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			CurrentRow.BatchesIndicationStatus = 0;
		Else
			For Each NameOfStatusField In ActionParameters.SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
				FieldNameSeries = FieldNamesBySeriesIndicationStatus(NameOfStatusField).Series;
				CurrentRow[NameOfStatusField] = 0;
				
				If CurrentRow.Property(FieldNameSeries) Then
					CurrentRow[FieldNameSeries] = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
				EndIf;
			EndDo;
		EndIf;
		
		ThereIsSignOfIndicatingSeries = ActionParameters.SeriesSpecificationParameters.LinkFields.Find("SpecifyBatches") <> Undefined;
		If ThereIsSignOfIndicatingSeries Then
			CurrentRow.SpecifyBatches = False;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckBatchByOwner(CurrentRow, StructureOfActions)
	
	Var ActionParameters;
	
	If StructureOfActions.Property("CheckBatchByOwner", ActionParameters) Then
		CurrentRow.Series				= PredefinedValue("Catalog.ItemsBatches.EmptyRef");
		CurrentRow.SeriesAreUsed	= False;
	EndIf;
	
EndProcedure

Procedure CheckBarcodeRegistration(CurrentRow, StructureOfActions)
	
	Var ActionParameters;
	
	If StructureOfActions.Property("CheckBarcodeRegistration", ActionParameters) Then
		CurrentRow.Registered = False;
	EndIf;
	
EndProcedure

Function FieldNamesBySeriesIndicationStatus(NameOfStatusField)
	
	ReturnStructure = New Structure("Series, Products, Characteristic");
	
	If NameOfStatusField = "BatchesIndicationStatus" Then
		ReturnStructure.Series = "Series";
		ReturnStructure.Products = "Products"; 
		ReturnStructure.Characteristic = "Characteristic";
	ElsIf NameOfStatusField = "BatchesIndicationStatusSender" Then
		ReturnStructure.Series = "SenderSeries";
		ReturnStructure.Products = "SenderProducts";
		ReturnStructure.Characteristic = "SenderCharacteristic";
	ElsIf NameOfStatusField = "BatchesIndicationStatusRecipient" Then
		ReturnStructure.Series = "RecipientSeries";
		ReturnStructure.Products = "ProductsRecipient";
		ReturnStructure.Characteristic = "CharacteristicRecipient";
	ElsIf NameOfStatusField = "BatchesIndicationStatusReceipt" Then
		ReturnStructure.Series = "BatchReceipt";
		ReturnStructure.Products = "ProductsRecordingAsReceived";
		ReturnStructure.Characteristic = "CharacteristicRecordingAsReceived";
	ElsIf NameOfStatusField = "BatchesIndicationStatusInWarehouses" Then
		ReturnStructure.Series = "SeriesInWarehouses";
		ReturnStructure.Products = "ProductsInWarehouses";
		ReturnStructure.Characteristic = "CharacteristicsInWarehouses";
	ElsIf NameOfStatusField = "BatchesIndicationStatusGoodsAtPartners" Then
		ReturnStructure.Series = "BuyProductsFromPartners";
		ReturnStructure.Products = "ProductsFromPartners";
		ReturnStructure.Characteristic = "CharacteristicsProductsFromPartners";
	ElsIf NameOfStatusField = "BatchesIndicationStatusOfGoodsTransferred" Then
		ReturnStructure.Series = "SeriesOfTransferredGoods";
		ReturnStructure.Products = "ProductsTransferred";
		ReturnStructure.Characteristic = "CharacteristicsOfTransferredGoods";
	ElsIf NameOfStatusField = "StatusOfSpecifyingSeriesDebitedSeries" Then
		ReturnStructure.Series = "SeriesDecommissionedSeries";
		ReturnStructure.Products = "ProductsDecommissionedSeries";
		ReturnStructure.Characteristic = "CharacteristicDecommissionedSeries";
	ElsIf NameOfStatusField = "BatchIndicationStatusOfGoodsShipped" Then
		ReturnStructure.Series = "BatchOfShippedGoods";
		ReturnStructure.Products = "ItemOfShippedGoods";
		ReturnStructure.Characteristic = "CharacteristicsOfShippedItems";
	ElsIf NameOfStatusField = "UnderRepairBatchSpecificationStatus" Then
		ReturnStructure.Series = "UnderRepairBatch";
		ReturnStructure.Products = "UnderRepairProduct";
		ReturnStructure.Characteristic = "UnderRepairVariant";
	EndIf;
	
	Return ReturnStructure
	
EndFunction

Procedure FillInTrafficFlagForWarehouseRegisters(CurrentRow, StructureOfActions)
	Var FieldName;
	
	If StructureOfActions.Property("FillInTrafficFlagForWarehouseRegisters", FieldName) Then
		CurrentRow[FieldName] = False;
	EndIf;
	
EndProcedure

Procedure FillInPriceOfTransferOfProductsToGiverInLineTS(CurrentRow, StructureOfActions, CachedValues)
	
	If Not StructureOfActions.Property("FillInPriceOfTransferringProductsToGiver") Then
		Return;
	EndIf;
	
	CurrentRow.Price = 0;
	CurrentRow.PriceKind = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
	
EndProcedure

Procedure CheckFillInIssuePriceInTSLine(CurrentRow, StructureOfActions, CachedValues)
	
	If Not StructureOfActions.Property("CheckFillIssuePrice") Then
		Return;
	EndIf;
	
	CurrentRow.Price = 0;
	
EndProcedure

// Fills in the planned / actual production date of the item in the stage
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action, and The value is the Structure - parameters of the action.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInProductionDate(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FillParameters;
	
	If Not StructureOfActions.Property("FillInProductionDate", FillParameters) Then
		Return;
	EndIf;
	
	If CurrentRow.Canceled Then
		CurrentRow.ProductionDate = '00010101';
		Return;
	EndIf;
	
	If CurrentRow.Manufactured Then
		EventDate = FillParameters.ActualProductionDate;
		If Not ValueIsFilled(EventDate) Then
			EventDate = CommonClient.SessionDate();
		EndIf;
	Else
		EventDate = FillParameters.PlannedProductionDate;
	EndIf;
	
	CurrentRow.ProductionDate = BegOfDay(EventDate);
	
EndProcedure

Procedure CheckFillInCostShare(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FillParameters;
	
	If Not StructureOfActions.Property("CheckFillInCostShare", FillParameters) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentRow.Products) Then
		ProductionClientServer.FillInCostFractionInLine(CurrentRow, ProductionClientServer.StructureOfShareValueFields());
		Return;
	EndIf;
	
EndProcedure

// Fills in the service details in the line based on the selected warehouse
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action, and The value is the Structure - parameters of the action.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInShopPantryAttribute(CurrentRow, StructureOfActions, CachedValues)
	
	Var FillParameters;
	
	If Not StructureOfActions.Property("FillInShopPantryAttribute", FillParameters) Then
		Return;
	EndIf;

	ProductionClient.FillInShopPantryAttribute(CurrentRow, FillParameters, CachedValues);	
	
EndProcedure

// Fills in the specification in a line based on the selected item, characteristic, division, and date.
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action, and The value is the Structure - parameters of the action.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues. 
//
Procedure CheckFillSpecification(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FillParameters;
	
	If Not StructureOfActions.Property("CheckFillSpecification", FillParameters) Then
		Return;
	EndIf;
	
	FieldName = FillParameters.FieldNameSpecification;
	
	If Not ValueIsFilled(CurrentRow.Products) Then
		CurrentRow[FieldName] = Undefined;
	EndIf;
	
EndProcedure

// Fills in the service details "Divergence of orders" in the line
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action,
//  														   The value - Structure - activity settings.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInDiscrepancyAttributeOrder(CurrentRow, StructureOfActions, CachedValues)
	
	Var FillParameters;
	
	If Not StructureOfActions.Property("FillInDiscrepancyAttributeOrder", FillParameters) Then
		Return;
	EndIf;

	OrdersClient.FillInDiscrepancyAttributeOrder(CurrentRow, FillParameters, CachedValues);
	
EndProcedure

// Procedure called from the handler of the "Nomenclature" item in the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure ProductsOnChangeOverridable(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	If StructureOfActions.Property("ProductsOnChangeOverridable", ActionParameters) Then
		ConfigurationModificationClientOverridable.ProductsOnChangeOverridable(CurrentRow,
			ActionParameters, CachedValues);
	EndIf;
	
EndProcedure

// Procedure that is called from the handler of the "Characteristics" attribute of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CharacteristicOnChangeOverridable(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	If StructureOfActions.Property("CharacteristicOnChangeOverridable", ActionParameters) Then
		ConfigurationModificationClientOverridable.CharacteristicOnChangeOverridable(CurrentRow,
			ActionParameters, CachedValues);
	EndIf;
	
EndProcedure

Procedure FillInExcisableItemAttribute(CurrentRow, StructureOfActions, CachedValues) 

	If StructureOfActions.Property("FillInExcisableItemAttribute") Then
		CurrentRow.ExcisableGoods = False;
	EndIf;

EndProcedure

Procedure RecalculateExciseTaxAmountInTSLine(CurrentRow, StructureOfActions, CachedValues) 

	If StructureOfActions.Property("RecalculateExciseTaxAmount") Then
		CurrentRow.ExciseTaxAmount = 0;
	EndIf;

EndProcedure

#EndRegion

#Region OtherProcedures

Procedure WhenFormingStructureForProcessedLine(CurrentRow, StructureOfActions, CachedValues)
	
	ActionParameters = Undefined;
	If StructureOfActions.Property("CheckSoftwareInSalesDocument", ActionParameters)
			Or StructureOfActions.Property("FillInAvailableColumn", ActionParameters)
			Or StructureOfActions.Property("WhenChangingTypeOfProductOrSoftwareOption", ActionParameters) Then
			
		ProgramObjectData = ProvisionInDocumentsClientServer.ProgramObjectData(
			ActionParameters,
			CurrentRow);
		
		If StructureOfActions.Property("CheckSoftwareInSalesDocument") Then
			StructureOfActions.CheckSoftwareInSalesDocument.Insert("ProgramObjectData",
				ProgramObjectData);
			StructureOfActions.CheckSoftwareInSalesDocument.Delete("Form");
		EndIf;
		If StructureOfActions.Property("FillInAvailableColumn") Then
			StructureOfActions.FillInAvailableColumn.Insert("ProgramObjectData",
				ProgramObjectData);
			StructureOfActions.FillInAvailableColumn.Delete("Form");
		EndIf;
		If StructureOfActions.Property("WhenChangingTypeOfProductOrSoftwareOption") Then
			StructureOfActions.WhenChangingTypeOfProductOrSoftwareOption.Insert("ProgramObjectData",
				ProgramObjectData);
			StructureOfActions.WhenChangingTypeOfProductOrSoftwareOption.Delete("Form");
		EndIf;
		
	EndIf;
	
	If StructureOfActions.Property("CheckNeedToUpdateColumnIsAvailable")
			Or StructureOfActions.Property("FillInAvailableColumn")
			Or StructureOfActions.Property("UpdateProductCache_") Then
		
		IDOfRowReceived = Undefined;
		If TypeOf(CurrentRow) = Type("FormDataCollectionItem") Then
			IDOfRowReceived = CurrentRow.GetID();
		EndIf;
		
		If StructureOfActions.Property("CheckNeedToUpdateColumnIsAvailable") Then
			StructureOfActions.CheckNeedToUpdateColumnIsAvailable.Insert("IDOfRowReceived",
				IDOfRowReceived);
		EndIf;
		If StructureOfActions.Property("FillInAvailableColumn") Then
			StructureOfActions.FillInAvailableColumn.Insert("IDOfRowReceived",
				IDOfRowReceived);
		EndIf;
		If StructureOfActions.Property("UpdateProductCache_") Then
			StructureOfActions.UpdateProductCache_.Insert("IDOfRowReceived",
				IDOfRowReceived);
		EndIf;
		
	EndIf;
	
EndProcedure

Function ServerCallRequired(CurrentRow, StructureOfActions, CachedValues)
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("FillInCheckQualityDateOfQualityConfirmation")
			Or StructureOfActions.Property("FillInUnblockableDateOfQualityConfirmation")
			Or StructureOfActions.Property("FillInSenderSControlledLotReference") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("CheckNeedToUpdateColumnIsAvailable")
			Or StructureOfActions.Property("FillInAvailableColumn")
			Or StructureOfActions.Property("UpdateProductCache_") Then
		
			Return True;
		
	EndIf;
	
	If StructureOfActions.Property("ItIsNecessaryToProcessAllTS")
		And StructureOfActions.ItIsNecessaryToProcessAllTS Then
		ExceptionText = NStr("vi = 'Để xử lý toàn bộ phần bảng, cần gọi ra hàm Server ""%Function%""';
							|ru = 'Для обработки всей ТЧ, необходимо сделать контекстный вызов серверной функции ""%Function%""';
							|en = 'To process the entire table, make a context call of the ""%Function%"" server function'; fa = 'To process the entire table, make a context call of the ""%Function%"" server function';
							|it = 'Per elaborare l''intero PM, è necessario effettuare una chiamata di contesto alla funzione server ""%Function%""';
							|pl = 'W celu przetwarzania całej sekcji tabelarycznej, należy wykonać wywołanie kontekstowe funkcji serwerowej ""%Function%""';
							|tr = 'TB''nin tamamını işlemek için, ""%Function%"" sunucu işlevine bir içerik çağrısının yapılması gerekir'");
		ExceptionText = StrReplace(ExceptionText, "%Function%", "BatchProcessingOfTablePartServer.TreatTS");
		
		Raise ExceptionText;
	EndIf;
	
	If StructureOfActions.Property("CheckCharacteristicsByOwner")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInGTINInLine")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("CheckFillPackageByOwner")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	PackagingProducts = Undefined;
	
	If (StructureOfActions.Property("RecalculateNumberOfUnits", PackagingProducts)
		Or StructureOfActions.Property("RecalculateNumberOfSuffixUnits")
		Or StructureOfActions.Property("RecalculateNumberOfPackages")
		Or StructureOfActions.Property("RecalculateNumberOfSuffixPacks")
		Or StructureOfActions.Property("RecalculateNumberOfPackagesByWeight")
		Or StructureOfActions.Property("RecalculateNumberOfPackagesByVolume")) Then
		
		RecalculationParameters = BatchProcessingOfTablePartClientServer.NormalizeUnitConversionParameters(CurrentRow, PackagingProducts);
		
		CoefficientKey = BatchProcessingOfTablePartClientServer.PackingCacheKey(RecalculationParameters.Products, RecalculationParameters.Package);
		
		If ValueIsFilled(RecalculationParameters.Package)
			And ValueIsFilled(RecalculationParameters.Products)
			And CachedValues.PackingFactors[CoefficientKey] = Undefined Then
			
			Return True;
			
		EndIf;
		
	EndIf;
	
	If (StructureOfActions.Property("RecalculateNumberOfPackagesByWeight")
		Or StructureOfActions.Property("RecalculateNumberOfPackagesByVolume")
		Or StructureOfActions.Property("RecalculateWeightVolume")) Then
		
		CoefficientKey = BatchProcessingOfTablePartClientServer.PackingCacheKey(Undefined, CurrentRow.UnitOfMeasureForWeight);
		
		If ValueIsFilled(CurrentRow.UnitOfMeasureForWeight)
			And CachedValues.PackingFactors[CoefficientKey] = Undefined Then
			Return True;
		EndIf;
		
		CoefficientKey = BatchProcessingOfTablePartClientServer.PackingCacheKey(Undefined, CurrentRow.UnitOfMeasureForVolume);
		
		If ValueIsFilled(CurrentRow.UnitOfMeasureForVolume)
			And CachedValues.PackingFactors[CoefficientKey] = Undefined Then
				Return True;
		EndIf;
		
	EndIf;
	
	RecalculationParameters = Undefined;
	If StructureOfActions.Property("RecalculateQuantityByRNPT", RecalculationParameters) Then
		CoefficientKey = BatchProcessingOfTablePartClientServer.KeyCacheCoefficientRNPT(CurrentRow, RecalculationParameters);
		
		Cache = CachedValues.RNPTCoefficients[CoefficientKey];
		
		If Cache = Undefined Then
			Return True;
		EndIf;
		
	EndIf;
	
	RecalculationParameters = Undefined;
	If StructureOfActions.Property("RecalculateQuantityByRNPTSuffix", RecalculationParameters) Then
		CoefficientKey = BatchProcessingOfTablePartClientServer.KeyCacheCoefficientRNPT(CurrentRow, RecalculationParameters);
		
		Cache = CachedValues.RNPTCoefficients[CoefficientKey];
		
		If Cache = Undefined Then
			Return True;
		EndIf;
		
	EndIf;
	
	If StructureOfActions.Property("FillInSalePrice", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters.Currency)
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInSalePriceByProductRange", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters.Currency)
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInDefaultSupplierAgreement") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInAttributesAccordingToSupplierSAgreement") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInNumberOfSupplierAgreements") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInPartnerSDefaultCounterparty") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInDefaultContract") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("CompleteOfOperationAccordingToAgreementContract") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInVATTaxationPurchases") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInTermsOfPurchase") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInPurchasePrice", StructureOfActionParameters) Then
		
		If ValueIsFilled(StructureOfActionParameters.Currency)
			And ValueIsFilled(StructureOfActionParameters.Partner)
			And ValueIsFilled(CurrentRow.Products) Then
			
			Return True;
			
		ElsIf StructureOfActionParameters.UseAgreementFromTable Then
			
			Return True;
			
		EndIf;

	EndIf;
	
	If StructureOfActions.Property("FillInVATRate", StructureOfActionParameters) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInVATRateSuffix", StructureOfActionParameters) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInVATRateByPriceType", StructureOfActionParameters) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInVATRateForSettingUpAccountingAtCommitteeSUSN", StructureOfActionParameters) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillIn_TermsOfSales", StructureOfActionParameters)
		And (ValueIsFilled(StructureOfActionParameters.Terms) Or ValueIsFilled(StructureOfActionParameters.Partner)) 
		And ValueIsFilled(StructureOfActionParameters.Currency)
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInRetailSalesTermsAndConditions", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters.ObjectForStoringSalesTermsAndConditions) 
		And ValueIsFilled(StructureOfActionParameters.Currency)
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInTheItemByThePartnerSItem", StructureOfActionParameters)
		And ValueIsFilled(CurrentRow.PartnerProducts) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInProductNameOfProductPartner", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters)
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("CheckMatchedPartnerProducts", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters)
		And Not StructureOfActionParameters.DoNotPerformValidationForUser
		And ValueIsFilled(CurrentRow.PartnerProducts)
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInProductTypeAttribute_")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;

	If StructureOfActions.Property("FillInProductTypeAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;

	If StructureOfActions.Property("FillInCodeAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;

	If StructureOfActions.Property("FillInDescriptionAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;

	If StructureOfActions.Property("FillInUnitOfMeasurementAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInMeasuredValueTypeAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillPackageWeight")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillPackageVolume")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfWeight")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInVolumeUnit")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	If StructureOfActions.Property("FillInAttributeForUsingCharacteristics")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInCCDTrackingAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInCountryOfOriginOfProduct", StructureOfActionParameters)
		And ValueIsFilled(CurrentRow[StructureOfActionParameters.Products])
		And Not ValueIsFilled(CurrentRow.OriginCountry) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInRnptTrackingAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInCCDNumberType")
		And ValueIsFilled(CurrentRow.CCDNumber) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfMeasurementOfFEA")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInFeatureThisIsService")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInArticleAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInCodeAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;

	If StructureOfActions.Property("FillInDescriptionAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;

	If StructureOfActions.Property("FillInDetailsOfProduct", StructureOfActionParameters)
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("RecalculatePriceDiscountByAmountInSales", StructureOfActionParameters) Then
		
		UseManualDiscounts = False;
		If StructureOfActionParameters <> Undefined Then
			If StructureOfActionParameters.Property("UseManualDiscounts") Then
				UseManualDiscounts = True;
			EndIf;
		EndIf;
		
		UseAutomaticDiscounts = False;
		If StructureOfActionParameters <> Undefined Then
			If StructureOfActionParameters.Property("UseAutomaticDiscounts") Then
				UseAutomaticDiscounts = True;
			EndIf;
		EndIf;
		
		If (UseManualDiscounts 
			And CachedValues.UseDiscountAdjustmentsInSales = Undefined)
			Or (UseAutomaticDiscounts 
			And CachedValues.UseDiscountsMarkupsInSales = Undefined) Then
			
			Return True;
			
		EndIf;
		
	EndIf;
	
	If StructureOfActions.Property("RecalculatePriceDiscountForAmountInPurchases", StructureOfActionParameters) Then
		
		UseManualDiscounts = False;
		If StructureOfActionParameters <> Undefined Then
			If StructureOfActionParameters.Property("UseManualDiscounts") Then
				UseManualDiscounts = True;
			EndIf;
		EndIf;
		
		If UseManualDiscounts  <> Undefined 
			And CachedValues.UseDiscountAdjustmentsInPurchases = Undefined Then
			Return True;
		EndIf;
		
	EndIf;

	If StructureOfActions.Property("CheckCompleteConfigurationOptionByOwner")
		And ValueIsFilled(CurrentRow.Products)
		And (ValueIsFilled(CurrentRow.Characteristic) 
		And CurrentRow.ItemVariantsAreUsed
		Or Not ValueIsFilled(CurrentRow.Characteristic) 
		And Not CurrentRow.ItemVariantsAreUsed) Then
		
		Return True;
		
	EndIf;
	
	ActionParameters = Undefined;
	
	If StructureOfActions.Property("FillInItemCostAnalysisOfProductRange", ActionParameters)
		And ValueIsFilled(CurrentRow.Products)
		And ValueIsFilled(ActionParameters.Organization)
		And ValueIsFilled(ActionParameters.Department)
		And Not ValueIsFilled(CurrentRow[ActionParameters.ExpenseItem]) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("ClearExpenseAnalytics_") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("InitializeArticleAndAnalyticsAfterAddingLine") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInTheDefaultAccountSetting") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInInvoiceSettingsPresentation") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInExcisableItemAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInNoReturnContainerAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInCanceledWithoutReturnableContainerAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInActivityWithoutReturnableContainerAttribute")
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAccountingQuantityOfProducts")
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInFlagForWhetherThereIsProductSoldJointly")
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("CheckRowAssortment")
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInContent")
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	If StructureOfActions.Property("FillInPriceOfTransferringProductsToGiver", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters.Currency)
		And ValueIsFilled(CurrentRow.Products) Then
		Return True;
	EndIf;
	If StructureOfActions.Property("SetFlagForUsingPlannedCost") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("CheckFillIssuePrice")
		And ValueIsFilled(CurrentRow.Products) Then

		Return True;
		
	EndIf;
	If StructureOfActions.Property("CheckSeriesCalculateStatus", StructureOfActionParameters)
		And (StructureOfActionParameters.SeriesSpecificationParameters.IndependentCalculationOfSeveralStatusesOfSeriesIndicationIsRequired
			Or ValueIsFilled(CommonClientServer.StructureProperty(
					StructureOfActionParameters, "Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef")))
				And StructureOfActionParameters.SeriesSpecificationParameters.UseItemsBatch
				And Not(CurrentRow.Property("Canceled") 
				And CurrentRow.Canceled)
				And Not(CurrentRow.Property("SupplyOption") 
					And CurrentRow.SupplyOption <> PredefinedValue("Enum.SupplyOptions.Ship")
					And CurrentRow.SupplyOption <> PredefinedValue("Enum.SupplyOptions.FromWarehouse"))) Then
		
		If StructureOfActionParameters.SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0
			And ValueIsFilled(CurrentRow.Products) Then
			Return True;
		Else
			For Each NameOfStatusField In StructureOfActionParameters.SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
				FieldsNames = FieldNamesBySeriesIndicationStatus(NameOfStatusField);
				If CurrentRow.Property(FieldsNames.Products)
					And ValueIsFilled(CurrentRow[FieldsNames.Products]) Then
					Return True;
				EndIf;
			EndDo;
		EndIf;
		Return True;
	EndIf;
	
	If StructureOfActions.Property("CheckBatchByOwner", StructureOfActionParameters)
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("CheckBarcodeRegistration", StructureOfActionParameters)
		And ValueIsFilled(CurrentRow.Products) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("ProductsOnChangeOverridable", ActionParameters)
		And ConfigurationModificationClientOverridable.ProcessingTablePartRequiresServerCall("ProductsOnChangeOverridable",ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("CharacteristicOnChangeOverridable", ActionParameters)
		And ConfigurationModificationClientOverridable.ProcessingTablePartRequiresServerCall("CharacteristicOnChangeOverridable",ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("CheckSoftwareInSalesDocument", ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInShipForOrderPlusImplementationOption", ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInAvailableColumn", ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("CheckSoftwareInProductionPhase", ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("WhenChangingTypeOfProductOrSoftwareOption", ActionParameters) Then
		
		Return True;
		
	EndIf;
	If StructureOfActions.Property("WhenChangingProductType", ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("CheckFillWarehouse", ActionParameters) Then
		
		Return True;
		
	EndIf;
	If StructureOfActions.Property("CheckFillProductionWarehouse", ActionParameters) Then
		
		Return True;
		
	EndIf;
	If StructureOfActions.Property("FillInTrafficFlagForWarehouseRegisters", ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInSpaceUsageAttribute", ActionParameters) Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInCountryOfOriginForCCDNumber", ActionParameters) Then
		If ActionParameters <> Undefined
			And ActionParameters.Property("CCDNumber")
			And ValueIsFilled(ActionParameters.CCDNumber) Then
			
			Return True;
			
		EndIf;
	EndIf;
	If StructureOfActions.Property("CheckFillSpecification") Then
		
		ItemVariantsAreUsed = Undefined;
		CurrentRow.Property("ItemVariantsAreUsed", ItemVariantsAreUsed);
		
		If ItemVariantsAreUsed = True And ValueIsFilled(CurrentRow.Characteristic) Then
			Return True;
		EndIf;
		
		If ItemVariantsAreUsed <> True And ValueIsFilled(CurrentRow.Products) Then
			Return True;
		EndIf;
		
	EndIf;
	
	If StructureOfActions.Property("FillInShopPantryAttribute", StructureOfActionParameters) Then
		
		WarehouseFieldName = "Warehouse";
		WarehouseValue_ = Undefined;
		If StructureOfActionParameters <> Undefined Then
			
			If StructureOfActionParameters.Property("WarehouseFieldName") Then
				WarehouseFieldName = StructureOfActionParameters.WarehouseFieldName;
			EndIf;
			
			StructureOfActionParameters.Property("WarehouseValue_", WarehouseValue_);
			
		EndIf;
		
		CurrentWarehouse = ?(WarehouseValue_ = Undefined, CurrentRow[WarehouseFieldName], WarehouseValue_);
		
    	If CachedValues.WarehouseProperties_.Get(CurrentWarehouse) = Undefined Then
			Return True;
    	EndIf;

	EndIf;
	
	If StructureOfActions.Property("FillInReleaseDirection") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillOutRecipientInDirectionOfIssue") Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("CheckFillInCostShare", ActionParameters)
		And ValueIsFilled(CurrentRow.Products)
		And ActionParameters.Property("MethodOfAllocatingFinishedProductCosts")
		And ProductionClientServer.ShareOfCostIsCalculated(CurrentRow, ActionParameters) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("FillInProductOwnerIsAvailable")
		And ValueIsFilled(CurrentRow.Purpose)
		And CachedValues.AssignmentProperties.Get(CurrentRow.Purpose) = Undefined Then
		Return True;
	EndIf;
	If StructureOfActions.Property("FillInDirectionOfActivity", StructureOfActionParameters)
	   And ValueIsFilled(CurrentRow.Purpose)
	   And CachedValues.AssignmentProperties.Get(CurrentRow.Purpose) = Undefined Then
		Return True;
	EndIf;
	If StructureOfActions.Property("FillInDestinationType")
	   And ValueIsFilled(CurrentRow.Purpose)
	   And CachedValues.AssignmentProperties.Get(CurrentRow.Purpose) = Undefined Then
		Return True;
	EndIf;
	If StructureOfActions.Property("FillInServiceDetailsForPurpose") Then
		
		Return True;
		
	EndIf;
	
	If StructureOfActions.Property("FillInBatchOfTMTSV", ActionParameters)
		And ValueIsFilled(CurrentRow.Products)
		And ValueIsFilled(CurrentRow.Individual) Then
		
		If ActionParameters = Undefined
			Or ValueIsFilled(ActionParameters.Date)
				And ValueIsFilled(ActionParameters.Organization)
				And ValueIsFilled(ActionParameters.Department)
				And (Not ActionParameters.Property("BusinessOperation")
					Or (ValueIsFilled(ActionParameters.BusinessOperation)
						And ActionParameters.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PutOutOfOperation"))) Then
			
			Return True;
		EndIf;
	EndIf;
	
	If StructureOfActions.Property("FillInOrderWarehouseAttribute", StructureOfActionParameters) Then
		Return True;
	EndIf;
	
	If StructureOfActions.Property("RecalculateExciseTaxAmount", StructureOfActionParameters) Then
		Return True;
	EndIf;

	If InventoryInOperationClient.ServerCallIsRequiredToProcessTSString(CurrentRow, StructureOfActions, CachedValues) Then
		Return True;
	EndIf;
	
	If RebatesClient.ServerCallIsRequiredToProcessTSString(CurrentRow, StructureOfActions, CachedValues) Then
		Return True;
	EndIf;
		
	Return BatchProcessingOfTablePartClientLocalization.ServerCallRequired(CurrentRow, StructureOfActions, CachedValues);
	
EndFunction


Procedure FillInProductOwnerIsAvailable(CurrentRow, StructureOfActions, CachedValues)
	
	If Not StructureOfActions.Property("FillInProductOwnerIsAvailable") Then
		Return;
	EndIf;
	
	InternalSubcontractingClient.FillInProductOwnerIsAvailable(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

Procedure FillInDirectionOfActivity(CurrentRow, StructureOfActions, CachedValues)
	
	Var ActionParameters;

	If Not StructureOfActions.Property("FillInDirectionOfActivity", ActionParameters) Then
		Return;
	EndIf;

	LinesOfBusinessClient.FillInDirectionOfActivity(
		CurrentRow, StructureOfActions, CachedValues, ActionParameters);

EndProcedure

Procedure FillInSubdivisionInTSLine(CurrentRow, StructureOfActions, CachedValues)

	Var ActionParameters;
	
	If Not StructureOfActions.Property("FillInSubdivisionInTSLine", ActionParameters) Then
		Return;
	EndIf;
	
	ResetDivision = False;
	If TypeOf(ActionParameters) = Type("Structure")
		And ActionParameters.Property("ThereIsWriteOffForExpenses") Then
		ResetDivision = Not CurrentRow.ToExpenseAs
			And (CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
			Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
			Or CurrentRow.AssignmentType = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal"));
	EndIf;
	
	TypesList = SalesClient.TypesOfNomenclatureWithUnitAnalytics();
	If TypesList.FindByValue(CurrentRow.ItemsType) = Undefined
		Or ResetDivision Then
		CurrentRow.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	Else
		CurrentRow.Department = ActionParameters.Department;
	EndIf;

EndProcedure
Procedure FillInDestinationType(CurrentRow, StructureOfActions, CachedValues)
	
	Var ActionParameters;
	
	If Not StructureOfActions.Property("FillInDestinationType", ActionParameters) Then
		Return;
	EndIf;
	
	AssignmentsClient.FillInDestinationType(CurrentRow, CachedValues, ActionParameters);
	
EndProcedure

Procedure RecalculateAmountOfLocalOffBalanceInTSLine(CurrentRow, StructureOfActions, CachedValues)
	
	Var FactorOfConversionFromManCurrencyToRegulCurrency;
	
	If Not StructureOfActions.Property("RecalculateLocalOffBalanceAmount", FactorOfConversionFromManCurrencyToRegulCurrency) Then
		Return;
	EndIf;
	
	CurrentRow.AmountLocalOffBalance = ?(ValueIsFilled(FactorOfConversionFromManCurrencyToRegulCurrency),
										Round(CurrentRow.AmountOffBalance * FactorOfConversionFromManCurrencyToRegulCurrency, 2, 1),
										0);
	
EndProcedure

Procedure RecalculateOutOfBalancePriceByOutOfBalanceAmountInTSLine(CurrentRow, StructureOfActions, CachedValues)
	
	If Not StructureOfActions.Property("RecalculateOffBalancePriceByOffBalanceAmount") Then
		Return;
	EndIf;
	
	CurrentRow.PriceOffBalance = ?(ValueIsFilled(CurrentRow.NumberOfPackages),
									Round(CurrentRow.AmountOffBalance / CurrentRow.NumberOfPackages, 2),
									CurrentRow.AmountOffBalance);
	
EndProcedure

Procedure RecalculatePriceOffBalancePerPackageInTSLine(CurrentRow, StructureOfActions, CachedValues)
	
	Var NumberOfUnitsBeforeRecalculation;
	
	If Not StructureOfActions.Property("RecalculatePriceOffBalancePerPackage", NumberOfUnitsBeforeRecalculation)
	 Or Not ValueIsFilled(NumberOfUnitsBeforeRecalculation) Then
		Return;
	EndIf;
	
	CurrentRow.PriceOffBalance =
		Round(CurrentRow.PriceOffBalance / NumberOfUnitsBeforeRecalculation * CurrentRow.Count, 2);
	
EndProcedure
Procedure RecalculateNumberOfPackagesByWeight(CurrentRow, StructureOfActions, CachedValues) Export
	
	Suffix = Undefined;
	
	If StructureOfActions.Property("RecalculateNumberOfPackagesByWeight", Suffix) Then
		QuantityWithSuffix = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(Suffix);
		CurrentRow[QuantityWithSuffix.NumberOfPackages] = CurrentRow.Weight
			* Round(BatchProcessingOfTablePartClientServer.GetPackingRatio(
				CurrentRow.UnitOfMeasureForWeight, CachedValues).ZoomRatio
			/ CurrentRow.PackageWeight, 7, RoundMode.Round15as20);
		
		CurrentRow[QuantityWithSuffix.Count] = CurrentRow[QuantityWithSuffix.NumberOfPackages]
			* BatchProcessingOfTablePartClientServer.GetPackingRatio(
				CurrentRow.Package, CachedValues, CurrentRow.Products).ZoomRatio;
		
		UnitVolume_ = BatchProcessingOfTablePartClientServer.GetPackingRatio(
			CurrentRow.UnitOfMeasureForVolume, CachedValues).ZoomRatio;
			
		If CurrentRow.PackageVolume * UnitVolume_ <> 0 Then
			CurrentRow.VolumeM3 = CurrentRow[QuantityWithSuffix.NumberOfPackages] 
				* 1/Round(UnitVolume_/CurrentRow.PackageVolume, 7, RoundMode.Round15as20);
		Else
			CurrentRow.VolumeM3 = 0;
		EndIf;
	EndIf;
	
EndProcedure

Procedure RecalculateNumberOfPackagesByVolume(CurrentRow, StructureOfActions, CachedValues) Export

	Suffix = Undefined;
	
	If StructureOfActions.Property("RecalculateNumberOfPackagesByVolume", Suffix) Then
		QuantityWithSuffix = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(Suffix);
		
		CurrentRow[QuantityWithSuffix.NumberOfPackages] = CurrentRow.VolumeM3 
			* Round(BatchProcessingOfTablePartClientServer.GetPackingRatio(
				CurrentRow.UnitOfMeasureForVolume, CachedValues).ZoomRatio
			/ CurrentRow.PackageVolume, 7, RoundMode.Round15as20);
		
		CurrentRow[QuantityWithSuffix.Count] = CurrentRow[QuantityWithSuffix.NumberOfPackages]
			* BatchProcessingOfTablePartClientServer.GetPackingRatio(
				CurrentRow.Package, CachedValues, CurrentRow.Products).ZoomRatio;
		
		UnitWeight_ = BatchProcessingOfTablePartClientServer.GetPackingRatio(
			CurrentRow.UnitOfMeasureForWeight, CachedValues).ZoomRatio;
			
		If CurrentRow.PackageWeight * UnitWeight_ <> 0 Then
			CurrentRow.Weight = CurrentRow[QuantityWithSuffix.NumberOfPackages]
			* 1/Round(UnitWeight_/CurrentRow.PackageWeight, 7, RoundMode.Round15as20);
		Else
			CurrentRow.Weight = 0;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#EndRegion
