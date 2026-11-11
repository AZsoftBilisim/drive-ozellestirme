//@strict-types

#Region Internal

// Parameters:
//  AttributesValues - Structure:
//   * Posted - Boolean
//   * WithoutCalculation - Boolean
//   * Status - EnumRef.RebatesDocumentStatuses
//  Cancel - Boolean
//  RaiseException1 - Boolean
//
Procedure CheckAttributesOfConditions(AttributesValues, Cancel, RaiseException1 = False) Export
	
	MessageText = "";
	
	If AttributesValues.Posted <> True Then
		MessageText = NStr("vi = 'Chưa kết chuyển chứng từ điều kiện thưởng lũy kế. Sẽ không thể lập báo cáo';
							|ru = 'Документ условий ретро-бонусов не проведен. Формирование отчета выполнено не будет';
							|en = 'The rebate condition document is not posted. The report will not be generated'; fa = 'The rebate condition document is not posted. The report will not be generated';
							|it = 'Документ условий ретро-бонусов не проведен. Формирование отчета выполнено не будет';
							|pl = 'The rebate condition document is not posted. The report will not be generated';
							|tr = 'Retro-bonus koşulları belgesi yürütülmemiştir. Rapor oluşturulmayacaktır'");
	EndIf;
	
	If AttributesValues.WithoutCalculation = True Then
		MessageText = NStr("vi = 'Không thể lập báo cáo đối với thưởng lũy kế với hộp kiểm ""Số tiền thưởng được tính ngoài hệ thống""';
							|ru = 'Формирование отчета не предусмотрено для ретро-бонусов с флагом ""Сумма бонуса рассчитывается вне системы""';
							|en = 'The report cannot be generated for rebates with the ""Rebate amount is calculated outside the system"" checkbox selected'; fa = 'The report cannot be generated for rebates with the ""Rebate amount is calculated outside the system"" checkbox selected';
							|it = 'Формирование отчета не предусмотрено для ретро-бонусов с флагом ""Сумма бонуса рассчитывается вне системы""';
							|pl = 'The report cannot be generated for rebates with the ""Rebate amount is calculated outside the system"" checkbox selected';
							|tr = '“Bonus tutarı sistem dışında hesaplanıyor” bayrağı ile retro-bonuslar için rapor üretimi sağlanmıyor'");
	EndIf;
	
	If AttributesValues.Status <> Enums.RebatesDocumentStatuses.Approved Then
		MessageText = NStr("vi = 'Không thống nhất chứng từ điều kiện thưởng lũy kế. Sẽ không thể lập báo cáo';
							|ru = 'Документ условий ретро-бонусов не согласован. Формирование отчета выполнено не будет';
							|en = 'The rebate conditions document is not approved. The report will not be generated'; fa = 'The rebate conditions document is not approved. The report will not be generated';
							|it = 'Документ условий ретро-бонусов не согласован. Формирование отчета выполнено не будет';
							|pl = 'The rebate conditions document is not approved. The report will not be generated';
							|tr = 'Retro-bonus koşulları belgesi eşleştirilmemiştir. Raporun oluşturulması gerçekleştirilmeyecektir'");
	EndIf;
	
	If ValueIsFilled(MessageText) Then
		
		If RaiseException1 Then
			Raise MessageText;
		Else
			Common.MessageToUser(MessageText,,,, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  PreviousParametersOfConditionsForRebates - See NewParametersOfConditionsForRebates
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
// 
// Returns:
//  Boolean
//
Function ParametersOfRebatesConditionsHaveChanged(PreviousParametersOfConditionsForRebates, RebateConditionsParameters) Export
	
	For Each FieldOfParameters In RebateConditionsParameters Do
		
		NewValue_ = RebateConditionsParameters[FieldOfParameters.Key]; // Arbitrary
		ThereIsOldProperty = PreviousParametersOfConditionsForRebates.Property(FieldOfParameters.Key);
		If Not ThereIsOldProperty Then
			Return True;
		EndIf;
		OldValue = PreviousParametersOfConditionsForRebates[FieldOfParameters.Key]; // Arbitrary
		If NewValue_ <> OldValue Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  AdditionalProperties - Structure
//
Procedure SaveParametersOfRebatesTermsAndConditions(RebateConditionsParameters, AdditionalProperties) Export
	
	AdditionalProperties.Insert("RebateConditionsParameters", RebateConditionsParameters);
	
EndProcedure

// Parameters:
//  ReceiverSettings - DataCompositionSettings
//  SettingsSource_ - DataCompositionSettings
//
Procedure TransferUsedSelections(ReceiverSettings, SettingsSource_) Export
	
	For Each SourceElement_ In SettingsSource_.Filter.Items Do
		
		If Not SourceElement_.Use Then
			Continue;
		EndIf;
		
		If TypeOf(SourceElement_) = Type("DataCompositionFilterItem") Then
			
			ReceiverElement = Undefined;
			
			For Each Item In ReceiverSettings.Filter.Items Do
				
				If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
					Continue;
				EndIf;
				
				If Item.LeftValue = SourceElement_.LeftValue Then
					ReceiverElement = Item;
					Break;
				EndIf;
				
			EndDo;
			
			If ReceiverElement = Undefined Then
				
				ReceiverElement = ReceiverSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ReceiverElement.LeftValue = SourceElement_.LeftValue;
				
			EndIf;
			
			FillPropertyValues(ReceiverElement, SourceElement_, "ComparisonType, RightValue, Use");
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  ReceiverSettings - DataCompositionSettings
//  SettingsSource_ - DataCompositionSettings
//
Procedure MoveLayoutSettingsStructure(ReceiverSettings, SettingsSource_) Export
	
	ReceiverSettings.Structure.Clear();
	
	For Each SourceGrouping In SettingsSource_.Structure Do
		
		If TypeOf(SourceGrouping) = Type("DataCompositionGroup") Then
			GroupingReceiver = DataCompositionClientServer.AddGrouping(ReceiverSettings);
		ElsIf TypeOf(SourceGrouping) = Type("DataCompositionTable") Then
			GroupingReceiver = ReceiverSettings.Structure.Add(Type("DataCompositionTable"));
		Else
			Continue;
		EndIf;
		
		DataCompositionClientServer.CopyDataLayoutSettings(GroupingReceiver, SourceGrouping);
		
	EndDo;
	
EndProcedure

// Parameters:
//  ReportPeriod - StandardPeriod
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//
Procedure CheckCorrectReportPeriod(ReportPeriod, RebateConditionsParameters) Export
	
	DateEmpty = '00010101';
	
	// checking the validity period limits for conditions
	
	If ReportPeriod.StartDate = DateEmpty
	 Or ReportPeriod.StartDate < RebateConditionsParameters.ValidOnDate
	 Or ReportPeriod.StartDate > RebateConditionsParameters.ValidTo Then
		
		If ReportPeriod.StartDate <> DateEmpty Then
			
			MessageText = NStr("vi = 'Ngày bắt đầu đã chọn không khớp với kỳ hiệu lực theo điều kiện thưởng lũy kế.
				|Ngày bắt đầu sẽ được điều chỉnh thành ngày bắt đầu theo điều kiện thưởng lũy kế.';
				|ru = 'Выбранная дата начала не соответствует периоду действия по условиям ретро-бонуса.
				|Дата начала будет приведена к дате начала по условиям ретро-бонуса.';
				|en = 'The selected start date does not correspond to the validity period according to the rebate conditions.
				|The start date will be adjusted to the start date according to the rebate conditions.'; fa = 'The selected start date does not correspond to the validity period according to the rebate conditions.
				|The start date will be adjusted to the start date according to the rebate conditions.';
				|it = 'Выбранная дата начала не соответствует периоду действия по условиям ретро-бонуса.
				|Дата начала будет приведена к дате начала по условиям ретро-бонуса.';
				|pl = 'The selected start date does not correspond to the validity period according to the rebate conditions.
				|The start date will be adjusted to the start date according to the rebate conditions.';
				|tr = 'Seçilen başlangıç tarihi retro-bonus geçerlilik süresine karşılık gelmiyor. Başlangıç tarihi retro-bonus başlangıç tarihine göre ayarlanacaktır.'");
			Common.MessageToUser(MessageText);
			
		EndIf;
		
		ReportPeriod.StartDate = RebateConditionsParameters.ValidOnDate;
		
	EndIf;
	
	If ReportPeriod.EndDate = DateEmpty
	 Or ReportPeriod.EndDate < RebateConditionsParameters.ValidOnDate
	 Or ReportPeriod.EndDate > EndOfDay(RebateConditionsParameters.ValidTo) Then
		
		If ReportPeriod.EndDate <> DateEmpty Then
			
			MessageText = NStr("vi = 'Ngày kết thúc đã chọn không khớp với kỳ hiệu lực theo điều kiện thưởng lũy kế.
				|Ngày kết thúc sẽ điều chỉnh đến ngày kết thúc theo điều kiện thưởng lũy kế.';
				|ru = 'Выбранная дата окончания не соответствует периоду действия по условиям ретро-бонуса.
				|Дата окончания будет приведена к дате окончания по условиям ретро-бонуса.';
				|en = 'The selected end date does not correspond to the validity period according to the rebate conditions.
				|The end date will be adjusted to the end date according to the rebate conditions.'; fa = 'The selected end date does not correspond to the validity period according to the rebate conditions.
				|The end date will be adjusted to the end date according to the rebate conditions.';
				|it = 'Выбранная дата окончания не соответствует периоду действия по условиям ретро-бонуса.
				|Дата окончания будет приведена к дате окончания по условиям ретро-бонуса.';
				|pl = 'The selected end date does not correspond to the validity period according to the rebate conditions.
				|The end date will be adjusted to the end date according to the rebate conditions.';
				|tr = 'Seçilen başlangıç tarihi retro-bonus geçerlilik süresine karşılık gelmiyor. 
				|Bitiş tarihi, retro-bonus şartları uyarınca bitiş tarihine göre ayarlanacaktır.'");
			Common.MessageToUser(MessageText);
			
		EndIf;
		
		ReportPeriod.EndDate = RebateConditionsParameters.ValidTo;
		
	EndIf;
	
	// checking the multiplicity of the accrual periodicity according to the conditions
	
	ResultOfCheckingTimeFence = RebatesServer.CheckPeriodsByTimeFence(
		RebateConditionsParameters.ConditionFrequency,
		ReportPeriod.StartDate,
		ReportPeriod.EndDate,
		True);
	
	If ResultOfCheckingTimeFence.ThereIsViolationOfBeginning Then
		
		Raise ResultOfCheckingTimeFence.TextOfStartError;
		
	EndIf;
		
	If ResultOfCheckingTimeFence.ThereIsViolationOfEnding Then
		
		Raise ResultOfCheckingTimeFence.TextOfEndingError;
		
	EndIf;
	
EndProcedure

// Parameters:
//  OptionParameters - See NewOptionParameters
//  LayoutField - DataCompositionField
// 
// Returns:
//  Boolean
//
Function ThisIsDecryptionField(OptionParameters, LayoutField) Export
	
	For Each DecryptionField In OptionParameters.DecryptionFields Do
		
		If DecryptionField = LayoutField Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Parameters:
//  SubordinateStructure - DataCompositionGroup, DataCompositionTableGroup -
//  LayoutField - DataCompositionField
//
Procedure DisableUseOfField(SubordinateStructure, LayoutField) Export
	
	DisableUseOfSelectedField(SubordinateStructure.Selection.Items, LayoutField);
	
	If TypeOf(SubordinateStructure) = Type("DataCompositionGroup")
	 Or TypeOf(SubordinateStructure) = Type("DataCompositionTableGroup") Then
		
		For Each GroupingField In SubordinateStructure.GroupFields.Items Do
			If GroupingField.Field = LayoutField Then
				GroupingField.Use = False;
			EndIf;
			
		EndDo;
	
	EndIf;
	
	If TypeOf(SubordinateStructure) = Type("DataCompositionTable") Then
		
		For Each TableRow In SubordinateStructure.Rows Do
			DisableUseOfField(TableRow, LayoutField);
		EndDo;
		
		For Each TableColumn2 In SubordinateStructure.Columns Do
			DisableUseOfField(TableColumn2, LayoutField);
		EndDo;
		
	ElsIf TypeOf(SubordinateStructure) = Type("DataCompositionGroup")
	      Or TypeOf(SubordinateStructure) = Type("DataCompositionTableGroup") Then
		
		For Each SubordinateStructure In SubordinateStructure.Structure Do
			DisableUseOfField(SubordinateStructure, LayoutField);
		EndDo;
		
	Else
		Return;
	EndIf;
	
EndProcedure

// Parameters:
//  Items - DataCompositionSelectedFieldCollection
//  LayoutField - DataCompositionField
//
Procedure DisableUseOfSelectedField(Items, LayoutField) Export
	
	For Each ComboBox In Items Do
		
		If TypeOf(ComboBox) = Type("DataCompositionAutoSelectedField") Then
			Continue;
		EndIf;
		
		If TypeOf(ComboBox) = Type("DataCompositionSelectedFieldGroup") Then
			DisableUseOfSelectedField(ComboBox.Items, LayoutField);
		Else
			
			If ComboBox.Field = LayoutField Then
				ComboBox.Use = False;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  SourceDocument_ - DocumentRef.ConditionsOfVendorRebates
// 
// Returns:
//  See NewParametersOfConditionsForRebates
//
Function ParametersOfTermsOfRebatesOfSuppliers(SourceDocument_) Export
	
	UpToDateData = Documents.ConditionsOfVendorRebates.UpToDateData(SourceDocument_);
	Result = NewParametersOfConditionsForRebates();
	FillPropertyValues(Result, UpToDateData);
	
	Result.CalculationOfSupplierBonuses = True;
	Result.IndicatorOfItemsIsQuantitative = IndicatorOfItemsIsQuantitative(Result.GoodsIndicator);
	
	If UpToDateData.BonusType = Enums.VendorRebateTypes.Sales Then
		
		Result.ProportionalDistribution = True;
		
	Else
		
		If UpToDateData.AllocationProcedure = Enums.RebatesAllocationProcedures.InProportionToRevenue
		 Or UpToDateData.AllocationProcedure = Enums.RebatesAllocationProcedures.InProportionToPurchaseAmount Then
			Result.ProportionalDistribution = True;
		Else
			Result.ProportionalDistribution = False;
		EndIf;
		
		If UpToDateData.AllocationProcedure = Enums.RebatesAllocationProcedures.EmptyRef() Then
			Result.ProportionalDistribution = True;
		EndIf;
		
	EndIf;
	
	Result.DistributionByFIFO = (UpToDateData.AllocationProcedure
		= Enums.RebatesAllocationProcedures.FIFO);
	
	Result.ProgressiveCalculationScale = CalculationOnProgressiveScale(Result);
	Result.CalculationScaleByRanges = CalculationByRanges(Result);
	
	Result.CalculationInBasePrices = (UpToDateData.BaseOfCalculation = Enums.RebateCalculationBases.RevenueBasePrices
		Or UpToDateData.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountBasePrices);
	
	Result.CalculationByProperties = CalculationByProperties(Result);
	ItemAttributeParameters = ItemAttributeParameters(Result);
	FillPropertyValues(Result, ItemAttributeParameters);
	
	Return Result;
	
EndFunction

// Parameters:
//  SourceDocument_ - DocumentRef.ConditionsOfCustomerRebates
// 
// Returns:
//  See NewParametersOfConditionsForRebates
//
Function ParametersOfTermsOfRebatesForCustomers(SourceDocument_) Export
	
	UpToDateData = Documents.ConditionsOfCustomerRebates.UpToDateData(SourceDocument_);
	Result = NewParametersOfConditionsForRebates();
	FillPropertyValues(Result, UpToDateData);
	
	Result.IndicatorOfItemsIsQuantitative = IndicatorOfItemsIsQuantitative(Result.GoodsIndicator);
	Result.BaseOfCalculation = UpToDateData.SalesCalculationBase;
	Result.CalculationInBasePrices = (UpToDateData.SalesCalculationBase
		= Enums.RebateCalculationBases.RevenueBasePrices);
	Result.CalculationOfCustomerBonuses = True;
	Result.ProportionalDistribution = (UpToDateData.AllocationProcedure
		= Enums.RebatesAllocationProcedures.InProportionToRevenue);
	Result.DistributionByFIFO = (UpToDateData.AllocationProcedure
		= Enums.RebatesAllocationProcedures.FIFO);
	
	Result.ProgressiveCalculationScale = CalculationOnProgressiveScale(Result);
	Result.CalculationScaleByRanges = CalculationByRanges(Result);
	
	Result.CalculationByProperties = CalculationByProperties(Result);
	ItemAttributeParameters = ItemAttributeParameters(Result);
	FillPropertyValues(Result, ItemAttributeParameters);
	
	Return Result;
	
EndFunction

// Returns:
//  Structure - Current parameters of retro bonus conditions:
//  * CalculationOfCustomerBonuses - Boolean -
//  * CalculationOfSupplierBonuses - Boolean -
//	* WithoutCalculation - Boolean -
//	* ValidOnDate - Date -
//	* ValidTo - Date -
//	* DateOfRemainingGoods - Date -
//	* Organization - CatalogRef.Companies -
//	* Currency - CatalogRef.Currencies -
//	* PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants -
//	* PartyCountDetailsPresentation - String -
//	* AccrualFrequency - EnumRef.RebatesFrequencies -
//	* ConditionFrequency - EnumRef.RebatesFrequencies -
//	* ConditionFrequencyPresentation - String -
//	* RecordingIsCompleted - Boolean -
//	* ContentOfGoods - EnumRef.RebatesItems -
//	* PartyList - EnumRef.RebatesParticipants -
//	* Attendees - EnumRef.RebatesLists -
//	* Goods - EnumRef.RebatesLists -
//	* CalculationByProperties - Boolean -
//	* ProductItemProperty - String -
//	* AdditionalItemProperty - Boolean -
//	* ItemItemPropertyLink - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo -
//	* ItemPropertyValueType - TypeDescription -
//	* ItemPropertyTitle - String -
//	* Warehouses - EnumRef.RebatesLists -
//	* RestrictAccrualOverPlan - Boolean -
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//	* GoodsIndicatorPresentation - String -
//	* IndicatorOfItemsIsQuantitative - Boolean -
//	* BaseOfCalculation - EnumRef.RebateCalculationBases -
//	* CalculationInBasePrices - Boolean -
//	* ConsiderVAT - Boolean -
//	* AllocationProcedure - EnumRef.RebatesAllocationProcedures -
//	* ProportionalDistribution - Boolean -
//	* DistributionByFIFO - Boolean -
//	* DocumentTermsOfRetroBonusesPresentation - String -
//	* Counterparty - CatalogRef.Counterparties -
//	* Partner - CatalogRef.Partners -
//	* BonusType - EnumRef.VendorRebateTypes -
//	* CalculationScaleType - Number -
//	* ProgressiveCalculationScale - Boolean -
//	* CalculationScaleByRanges - Boolean -
//
Function NewParametersOfConditionsForRebates() Export
	
	Result = New Structure;
	
	DateEmpty = '00010101';
	
	Result.Insert("CalculationOfCustomerBonuses", False);
	Result.Insert("CalculationOfSupplierBonuses", False);
	Result.Insert("WithoutCalculation", False);
	Result.Insert("ValidOnDate", DateEmpty);
	Result.Insert("ValidTo", DateEmpty);
	Result.Insert("DateOfRemainingGoods", DateEmpty);
	Result.Insert("Organization", Catalogs.Companies.EmptyRef());
	Result.Insert("Currency", Catalogs.Currencies.EmptyRef());
	Result.Insert("PartyCountDetails", Enums.ARAPAccountingDrilldownsOfRebatesParticipants.EmptyRef());
	Result.Insert("PartyCountDetailsPresentation", "");
	Result.Insert("AccrualFrequency", Enums.RebatesFrequencies.EmptyRef());
	Result.Insert("ConditionFrequency", Enums.RebatesFrequencies.EmptyRef());
	Result.Insert("ConditionFrequencyPresentation", "");
	Result.Insert("RecordingIsCompleted", False);
	Result.Insert("ContentOfGoods", Enums.RebatesItems.EmptyRef());
	Result.Insert("PartyList", Enums.RebatesParticipants.EmptyRef());
	Result.Insert("Attendees", Enums.RebatesLists.EmptyRef());
	Result.Insert("Goods", Enums.RebatesLists.EmptyRef());
	Result.Insert("CalculationByProperties", False);
	Result.Insert("ProductItemProperty", "");
	Result.Insert("AdditionalItemProperty", False);
	Result.Insert("ItemItemPropertyLink", ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef());
	Result.Insert("ItemPropertyValueType", New TypeDescription(Undefined));
	Result.Insert("ItemPropertyTitle", "");
	Result.Insert("Warehouses", Enums.RebatesLists.EmptyRef());
	Result.Insert("RestrictAccrualOverPlan", False);
	Result.Insert("GoodsIndicator", Enums.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef());
	Result.Insert("GoodsIndicatorPresentation", "");
	Result.Insert("IndicatorOfItemsIsQuantitative", False);
	Result.Insert("BaseOfCalculation", Enums.RebateCalculationBases.EmptyRef());
	Result.Insert("CalculationInBasePrices", False);
	Result.Insert("ConsiderVAT", False);
	Result.Insert("AllocationProcedure", Enums.RebatesAllocationProcedures.EmptyRef());
	Result.Insert("ProportionalDistribution", False);
	Result.Insert("DistributionByFIFO", False);
	Result.Insert("DocumentTermsOfRetroBonusesPresentation", "");
	Result.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	Result.Insert("Partner", Catalogs.Partners.EmptyRef());
	Result.Insert("BonusType", Enums.VendorRebateTypes.EmptyRef());
	Result.Insert("CalculationScaleType", 0);
	Result.Insert("ProgressiveCalculationScale", False);
	Result.Insert("CalculationScaleByRanges", False);
	
	Return Result;
	
EndFunction

// Returns:
//  Structure - Report Variant Parameters:
// * VariantKey - String - The name of the option in the DCS
// * ThisIsTranscriptOfDocuments - Boolean 
// * ThisIsTranscriptOfNomenclature - Boolean
// * ThisIsTheTranscript - Boolean
// * DetailsMode - Boolean - The value of the Additional Property flag.Decryption mode in the Composer settings
// * DecryptionFields - Array of DataCompositionField
// * OptionIsModifiedByUser - Boolean
// * DetailingToItem - Boolean
// 
Function NewOptionParameters() Export
	
	OptionParameters = New Structure;
	OptionParameters.Insert("VariantKey", "");
	OptionParameters.Insert("ThisIsTranscriptOfDocuments", False);
	OptionParameters.Insert("ThisIsTranscriptOfNomenclature", False);
	OptionParameters.Insert("ThisIsTheTranscript", False);
	OptionParameters.Insert("DetailsMode", False);
	OptionParameters.Insert("DecryptionFields", New Array);
	OptionParameters.Insert("OptionIsModifiedByUser", False);
	OptionParameters.Insert("DetailingToItem", False);
	
	Return OptionParameters;
	
EndFunction

// Parameters:
//  StartDate - Date
//  EndDate - Date
//  ConditionFrequency - EnumRef.RebatesFrequencies
// 
// Returns:
//  Number - The number of whole calculation periods between the start date and the end date
//
Function NumberOfCalculationPeriods(Val StartDate, Val EndDate, Val ConditionFrequency) Export
	
	EndDate = EndOfDay(EndDate) + 1;
	SecondsPerDay = 24 * 60 * 60;
	RebatesFrequencies = Enums.RebatesFrequencies;
	
	If ConditionFrequency = RebatesFrequencies.Day Then
		
		NumberOfPeriods = Int((EndDate - StartDate) / SecondsPerDay);
		
	ElsIf ConditionFrequency = RebatesFrequencies.Week Then
		
		NumberOfPeriods = Int((EndDate - StartDate) / (7 * SecondsPerDay));
		
	ElsIf ConditionFrequency = RebatesFrequencies.Month Then
		
		NumberOfPeriods = Month(EndDate) - Month(StartDate) + 12 * (Year(EndDate) - Year(StartDate));
		
	ElsIf ConditionFrequency = RebatesFrequencies.Quarter Then
		
		NumberOfPeriods = Int(Month(BegOfQuarter(EndDate)) / 3) - Int(Month(BegOfQuarter(StartDate)) / 3)
			+ 4 * (Year(EndDate) - Year(StartDate));
		
	Else
		
		NumberOfPeriods = 1;
		
	EndIf;
	
	Return NumberOfPeriods;
	
EndFunction

// Parameters:
//  Variant - DataCompositionSettingsVariant -
// 
// Returns:
//  Number - Index of the level of dimensions with the Number range field
//
Function LevelOfGroupingByRanges(Variant) Export
	
	GroupingLevels = DataCompositionClientServer.GetGroupings(Variant.Settings);
	Result = Undefined;
	RangeField = New DataCompositionField("RangeNumber");
	For LevelIndex = 0 To GroupingLevels.Count() Do
		
		Group = GroupingLevels[LevelIndex].Value; // DataCompositionGroup
		GroupFields = Group.GroupFields;
		Groups = GroupFields.Items;
		For Each GroupingField In Groups Do
			
			If GroupingField.Field = RangeField Then
				
				Result = LevelIndex;
				Break;
				
			EndIf;
			
		EndDo;
		
		If Result <> Undefined Then
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//
Procedure ConfigureConditionalAppearanceOfReport(ConditionalAppearance) Export
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Characteristic");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tất cả>';
													|ru = '<Все>';
													|en = '<All>'; fa = '<همه>';
													|it = '<All>';
													|pl = '<All>';
													|tr = '<Tümü>'"));
	
EndProcedure

// Parameters:
//  Settings - DataCompositionSettings
//  ColumnHeaders - Structure
//
Procedure CustomizeHeadersOfSelectedColumns(Settings, ColumnHeaders) Export
	
	For Each ColumnHeaderElement In ColumnHeaders Do
		
		Title = ColumnHeaderElement.Value; // String
		LayoutField = New DataCompositionField(ColumnHeaderElement.Key);
		
		For Each SelectedField In Settings.Selection.Items Do
			
			If TypeOf(SelectedField) = Type("DataCompositionAutoSelectedField") Then
				Continue;
			EndIf;
			
			If SelectedField.Field = LayoutField Then
				SelectedField.Title = Title;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Parameters:
//  DatasetFields - DataCompositionSchemaDataSetFields 
//  ColumnHeaders - Structure
//
Procedure ConfigureDataSetColumnHeaders(DatasetFields, ColumnHeaders) Export
	
	For Each ColumnHeaderElement In ColumnHeaders Do
		
		Title = ColumnHeaderElement.Value; // String
		DataSetField = DatasetFields.Find(ColumnHeaderElement.Key);
		DataSetField.Title = Title;
		
	EndDo;
	
EndProcedure

// Parameters:
//  DatasetFields - DataCompositionSchemaDataSetFields 
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//
Procedure ConfigureFormatOfPropertyValue(DatasetFields, RebateConditionsParameters) Export
	
	If Not ValueIsFilled(RebateConditionsParameters.ProductItemProperty) Then
		Return;
	EndIf;
	
	DataSetField = DatasetFields.Find("PropertyValue");
	DataSetField.ValueType = RebateConditionsParameters.ItemPropertyValueType;
	
	FormatParameters = New Array; // Array of String
	
	If RebateConditionsParameters.ItemPropertyValueType.ContainsType(Type("Number")) Then
		
		Digits = RebateConditionsParameters.ItemPropertyValueType.NumberQualifiers.Digits;
		FormatParameterLength = "ND=" + Format(Digits, "NFD=0; NG=;");
		FormatParameters.Add(FormatParameterLength);
		
		Accuracy = RebateConditionsParameters.ItemPropertyValueType.NumberQualifiers.FractionDigits;
		FormatParameterPrecision = "NFD=" + Format(Accuracy, "NFD=0; NG=;");
		FormatParameters.Add(FormatParameterPrecision);
		
	EndIf;
	
	If RebateConditionsParameters.ItemPropertyValueType.ContainsType(Type("Date")) Then
		
		DateComposition = RebateConditionsParameters.ItemPropertyValueType.DateQualifiers.DateFractions;
		If DateComposition = DateFractions.Date Then
			
			DateFormatParameter = "DLF=D";
			
		ElsIf DateComposition = DateFractions.Time Then
			
			DateFormatParameter = "DLF=T";
			
		Else
			
			DateFormatParameter = "DLF=DT";
			
		EndIf;
		
		FormatParameters.Add(DateFormatParameter);
		
	EndIf;
	
	If FormatParameters.Count() > 0 Then
		
		FormatString = StrConcat(FormatParameters, "; ");
		DataSetField.Appearance.SetParameterValue("Format", FormatString);
		
	EndIf;
	
EndProcedure

#Region QueryText

// Returns:
//  String - The expression "COMBINE EVERYTHING"
//
Function SubquerySeparator_() Export
	
	SubquerySeparator_ = Chars.LF + Chars.LF + "UNION ALL" + Chars.LF + Chars.LF;
	Return SubquerySeparator_;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  ByPurchaseRegister - Boolean -
// 
// Returns:
//  String - Expression for the Calculation period field
//
Function ExpressionCalculationPeriod(RebateConditionsParameters, ByPurchaseRegister = False) Export
	
	ConditionFrequency = RebateConditionsParameters.ConditionFrequency;
	Periodicity_ = Enums.RebatesFrequencies;
	ExpressionPeriod = "";
	
	If ByPurchaseRegister Then
		SourceTable1 = "Purchases";
	Else
		SourceTable1 = "RevenueAndCOGS";
	EndIf;
	
	If ConditionFrequency = Periodicity_.Day Then
		
		ExpressionPeriod = "BEGINOFPERIOD(&SourceTable1.Period, DAY)";
		
	ElsIf ConditionFrequency = Periodicity_.Week Then
		
		ExpressionPeriod = "BEGINOFPERIOD(&SourceTable1.Period, WEEK)";
		
	ElsIf ConditionFrequency = Periodicity_.Month Then
		
		ExpressionPeriod = "BEGINOFPERIOD(&SourceTable1.Period, MONTH)";
		
	ElsIf ConditionFrequency = Periodicity_.Quarter Then
		
		ExpressionPeriod = "BEGINOFPERIOD(&SourceTable1.Period, QUARTER)";
		
	ElsIf ConditionFrequency = Periodicity_.WholePeriod
		  Or ConditionFrequency = Enums.RebatesFrequencies.EmptyRef() Then
		
		ExpressionPeriod = "&StartDate";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Không thể xác định định kỳ điều kiện (""%1"") đối với chứng từ ""%2""';
							|ru = 'Не удалось определить периодичность условий (""%1"") для документа ""%2""';
							|en = 'Cannot determine the condition frequency (""%1"") for the ""%2"" document'; fa = 'Cannot determine the condition frequency (""%1"") for the ""%2"" document';
							|it = 'Не удалось определить периодичность условий (""%1"") для документа ""%2""';
							|pl = 'Cannot determine the condition frequency (""%1"") for the ""%2"" document';
							|tr = '“%2“ belgesi için koşulların sıklığı (”%1"") tanımlanamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.ConditionFrequencyPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	ExpressionPeriod = StrReplace(ExpressionPeriod, "&SourceTable1", SourceTable1);
	
	Return ExpressionPeriod;
	
EndFunction

// Returns:
//  String - The size of the portion of the calculation of the cumulative total
//
Function PortionOfCumulativeTotal() Export
	
	Return "100";
	
EndFunction

// Returns:
//  String - The size of the sub-portion of the calculation of the cumulative total
//
Function SubPortionOfCumulativeTotal() Export
	
	Return "10";
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextCalculationScale(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	RECORDAUTONUMBER() AS RangeNumber,
	|	SourceTable1.RangeFrom AS RangeFrom,
	|	SourceTable1.RangeBy AS RangeBy,
	|	SourceTable1.BonusPercent AS BonusPercent
	|INTO TT_CalculationScale
	|FROM
	|	InformationRegister.RebatesCalculationScales AS SourceTable1
	|WHERE
	|	SourceTable1.TermDocument = &SourceDocument_";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextCalculationScaleMinimumPlan(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_CalculationScale.RangeFrom AS RangeFrom,
	|	TT_CalculationScale.RangeBy AS RangeBy,
	|	TT_CalculationScale.BonusPercent AS BonusPercent
	|INTO TT_CalculationScaleMinimumPlan
	|FROM
	|	(SELECT
	|		MIN(CalculationScale.RangeFrom) AS RangeFrom
	|	FROM
	|		TT_CalculationScale AS CalculationScale) AS MinimumRange
	|		INNER JOIN TT_CalculationScale AS TT_CalculationScale
	|		ON (MinimumRange.RangeFrom = TT_CalculationScale.RangeFrom)";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	If RebateConditionsParameters.Goods = Enums.RebatesLists.All Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	SourceTable1.TermDocument AS TermsAndConditionsOfRebates,
	|	SourceTable1.ValidOnDate AS StartDate,
	|	ENDOFPERIOD(SourceTable1.ValidTo, DAY) AS EndDate,
	|	SourceTable1.Products AS Products,
	|	CASE
	|		WHEN
	|			SourceTable1.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	SourceTable1.Characteristic AS Characteristic,
	|	&PropertyValueExpression AS PropertyValue,
	|	SourceTable1.BasePrice AS BasePrice,
	|	SourceTable1.BonusPercent AS BonusPercent,
	|	SourceTable1.CountPlan AS CountPlan,
	|	&ExpressionNumberPlanFor AS NumberOfPlanFor,
	|	&ExpressionBonusPerUnit AS BonusPerUnit
	|INTO TT_Goods
	|FROM
	|	&SourceTable1 AS SourceTable1
	|WHERE
	|	&ConditionForDocument
	|
	|INDEX BY
	|	Products,
	|	Characteristic";
	
	If RebateConditionsParameters.ContentOfGoods = Enums.RebatesItems.ProductSegments
	   And Not RebateConditionsParameters.RecordingIsCompleted Then
		
		// The table vt_composition of Product segments will be transferred to the Data processor via the manager of the Time tables
		SourceTable1 = "TT_CompositionOfGoodsSegments";
		ConditionForDocument = "TRUE";
		ExpressionBonusPerUnit = "0";
		ExpressionNumberPlanFor = "0";
		PropertyValueExpression = "UNDEFINED";
		
	ElsIf RebateConditionsParameters.CalculationByProperties
	        And Not RebateConditionsParameters.RecordingIsCompleted Then
		
		// The table V_T goods by property will be transferred to the Data processor via the moderntables managerreferences
		SourceTable1 = "TT_ItemsByProperty";
		ConditionForDocument = "TRUE";
		ExpressionBonusPerUnit = "0";
		ExpressionNumberPlanFor = "SourceTable1.QuantityPlanRangeBound";
		
		PropertyValueExpression = CompoundTypeFieldTypingExpression(
			RebateConditionsParameters.ItemPropertyValueType, "SourceTable1.PropertyValue");
		
	Else
		
		If RebateConditionsParameters.CalculationOfCustomerBonuses Then
			
			SourceTable1 = "InformationRegister.CustomerRebatesItems";
			ExpressionBonusPerUnit = "0";
			
		ElsIf RebateConditionsParameters.CalculationOfSupplierBonuses Then
			
			SourceTable1 = "InformationRegister.VendorRebatesGoods";
			ExpressionBonusPerUnit = "SourceTable1.BonusPerUnit";
			
		Else
			Raise NStr("vi = 'Kiểu không xác định của thưởng lũy kế';
						|ru = 'Неизвестный тип ретро-бонуса';
						|en = 'Unknown rebate type'; fa = 'Unknown rebate type';
						|it = 'Неизвестный тип ретро-бонуса';
						|pl = 'Unknown rebate type';
						|tr = 'Bilinmeyen retro bonusu türü'");
		EndIf;
		
		ExpressionNumberPlanFor = "SourceTable1.QuantityPlanRangeBound";
		
		If RebateConditionsParameters.CalculationByProperties Then
			PropertyValueExpression = "SourceTable1.PropertyValue";
		Else
			PropertyValueExpression = "UNDEFINED";
		EndIf;
		
		ConditionForDocument =
		"SourceTable1.TermDocument IN
		|			(SELECT
		|				VT_RBParameters.ConditionOfRebateBonusIs
		|			FROM
		|				VT_RBParameters AS VT_RBParameters)";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	QueryText = StrReplace(QueryText, "&ConditionForDocument", ConditionForDocument);
	QueryText = StrReplace(QueryText, "&ExpressionBonusPerUnit", ExpressionBonusPerUnit);
	QueryText = StrReplace(QueryText, "&ExpressionNumberPlanFor", ExpressionNumberPlanFor);
	QueryText = StrReplace(QueryText, "&PropertyValueExpression", PropertyValueExpression);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextOfGoodsMinimumPackingPlan(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_Goods.TermsAndConditionsOfRebates AS TermsAndConditionsOfRebates,
	|	TT_Goods.StartDate AS StartDate,
	|	TT_Goods.EndDate AS EndDate,
	|	&ProductFields,
	|	MIN(TT_Goods.CountPlan) AS CountPlan
	|INTO VT_GoodsMinimumPackingPlan
	|FROM
	|	TT_Goods AS TT_Goods
	|
	|GROUP BY
	|	TT_Goods.TermsAndConditionsOfRebates,
	|	TT_Goods.StartDate,
	|	TT_Goods.EndDate,
	|	&GroupingFieldsByGoodsFields";
	
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_Goods");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextMinimumParametersByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_GoodsMinimumPackingPlan.TermsAndConditionsOfRebates AS TermsAndConditionsOfRebates,
	|	VT_GoodsMinimumPackingPlan.StartDate AS StartDate,
	|	VT_GoodsMinimumPackingPlan.EndDate AS EndDate,
	|	&ProductFields,
	|	VT_GoodsMinimumPackingPlan.CountPlan AS CountPlan,
	|	TT_Goods.BasePrice AS BasePrice,
	|	TT_Goods.BonusPercent AS BonusPercent
	|INTO VT_ItemsMinimumParametersByPosition
	|FROM
	|	VT_GoodsMinimumPackingPlan AS VT_GoodsMinimumPackingPlan
	|		INNER JOIN TT_Goods AS TT_Goods
	|		ON VT_GoodsMinimumPackingPlan.TermsAndConditionsOfRebates = TT_Goods.TermsAndConditionsOfRebates
	|			AND VT_GoodsMinimumPackingPlan.StartDate = TT_Goods.StartDate
	|			AND VT_GoodsMinimumPackingPlan.EndDate = TT_Goods.EndDate
	|			AND &ConnectionFieldsByGoods
	|			AND VT_GoodsMinimumPackingPlan.CountPlan = TT_Goods.CountPlan";
	
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "VT_GoodsMinimumPackingPlan", "TT_Goods");
	
	If RebateConditionsParameters.CalculationByProperties Then
		
		QueryText = StrReplace(QueryText, "SELECT", "SELECT DISTINCT"); // @query-part-1, @query-part-2
		
	EndIf;
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextRanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT TOP 1000000
	|	RECORDAUTONUMBER() AS RangeNumber,
	|	TT_Goods.CountPlan AS RangeFrom,
	|	TT_Goods.NumberOfPlanFor AS RangeBy
	|INTO TT_Ranges
	|FROM
	|	TT_Goods AS TT_Goods
	|GROUP BY
	|	TT_Goods.CountPlan,
	|	TT_Goods.NumberOfPlanFor
	|
	|ORDER BY
	|	RangeFrom";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextGoodsRanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_Goods.StartDate AS StartDate,
	|	TT_Goods.StartDate AS EndDate,
	|	&ProductFields,
	|	TT_Goods.BasePrice AS BasePrice,
	|	TT_Goods.BonusPerUnit AS BonusPerUnit,
	|	TT_Goods.BonusPercent AS BonusPercent,
	|	TT_Goods.CountPlan AS RangeFrom,
	|	TT_Goods.NumberOfPlanFor AS RangeBy,
	|	ISNULL(TT_Ranges.RangeNumber, -1) AS RangeNumber
	|INTO TT_GoodsRanges
	|FROM
	|	TT_Goods AS TT_Goods
	|	LEFT JOIN TT_Ranges AS TT_Ranges
	|	ON TT_Goods.CountPlan = TT_Ranges.RangeFrom
	|		AND TT_Goods.NumberOfPlanFor = TT_Ranges.RangeBy";
	
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_Goods", "TT_Ranges");
	
	If RebateConditionsParameters.CalculationByProperties Then
		
		QueryText = StrReplace(QueryText, "SELECT", "SELECT DISTINCT"); // @query-part-1, @query-part-2
		
	EndIf;
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	LineUpsOfParticipants = Enums.RebatesParticipants;
	ListCompositions = Enums.RebatesLists;
	
	QueryText =
	"SELECT
	|	INNOfClients.TermDocument AS TermsAndConditionsOfRebates,
	|	Counterparties.Ref AS Counterparty,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	INNOfClients.ValidOnDate AS StartDate,
	|	INNOfClients.ValidTo AS EndDate,
	|	&ExpressionSumPlanTIN AS SumPlan
	|INTO VT_PreliminaryParticipants
	|FROM
	|	&TableSourceTIN AS INNOfClients
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON INNOfClients.TIN = Counterparties.TIN
	|WHERE
	|	INNOfClients.TermDocument IN
	|			(SELECT
	|				VT_RBParameters.ConditionOfRebateBonusIs
	|			FROM
	|				VT_RBParameters AS VT_RBParameters
	|			WHERE
	|				VT_RBParameters.FilterByInn)
	|	AND &SelectionConditionForCounterpartyToCatalog
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerCounterparties.TermDocument,
	|	CustomerCounterparties.Counterparty,
	|	&ExpressionCounterpartiesPartner,
	|	CustomerCounterparties.ValidOnDate,
	|	CustomerCounterparties.ValidTo,
	|	&ExpressionAmountPlanCounterparties AS SumPlan
	|FROM
	|	&TableSourceCounterparties AS CustomerCounterparties
	|WHERE
	|	CustomerCounterparties.TermDocument IN
	|			(SELECT
	|				VT_RBParameters.ConditionOfRebateBonusIs
	|			FROM
	|				VT_RBParameters AS VT_RBParameters
	|			WHERE
	|				VT_RBParameters.SelectionByCounterpartyPartner)";
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.PartnersSegments
	   And Not RebateConditionsParameters.RecordingIsCompleted Then
		
		// The table vt_composition of Client segments will be transferred to the Data processor via the manager of the Time tables
		
		QueryText =
		"SELECT
		|	TT_CompositionOfCustomerSegments.TermDocument AS TermsAndConditionsOfRebates,
		|	TT_CompositionOfCustomerSegments.Counterparty AS Counterparty,
		|	TT_CompositionOfCustomerSegments.Partner AS Partner,
		|	TT_CompositionOfCustomerSegments.ValidOnDate AS StartDate,
		|	TT_CompositionOfCustomerSegments.ValidTo AS EndDate,
		|	TT_CompositionOfCustomerSegments.SumPlan AS SumPlan
		|INTO VT_PreliminaryParticipants
		|FROM
		|	TT_CompositionOfCustomerSegments AS TT_CompositionOfCustomerSegments
		|WHERE
		|	&PartnerSelectionCriteriaForCompositionOfSegments";
		
	ElsIf RebateConditionsParameters.PartyList = LineUpsOfParticipants.TIN
	   And RebateConditionsParameters.Attendees = ListCompositions.ExceptForSelectedOnes Then
		
		SubqueryTextEmptyINN =
		"SELECT
		|	&SourceDocument_ AS TermsAndConditionsOfRebates,
		|	Counterparties.Ref AS Counterparty,
		|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
		|	&StartDate AS StartDate,
		|	&EndDate AS EndDate,
		|	0 AS SumPlan
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	TRIML(Counterparties.TIN) = """"";
		
		QueryText = QueryText + TMCommonUse.QuerySeparatorInJoin() + SubqueryTextEmptyINN;
		
	EndIf;
	
	If OptionParameters.ThisIsTheTranscript Then
		
		SelectionConditionForCounterpartyToCatalog =
		"CASE
		|	WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
		|		OR &Counterparty = UNDEFINED
		|	THEN TRUE
		|	ELSE Counterparties.Ref = &Counterparty
		|END";
		
		PartnerSelectionCriteriaForCompositionOfSegments =
		"CASE
		|	WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
		|		OR &Partner = UNDEFINED
		|	THEN TRUE
		|	ELSE TT_CompositionOfCustomerSegments.Partner = &Partner
		|END";
		
	Else
		
		SelectionConditionForCounterpartyToCatalog = "TRUE";
		PartnerSelectionCriteriaForCompositionOfSegments = "TRUE";
		
	EndIf;
	
	If RebateConditionsParameters.CalculationOfCustomerBonuses Then
		
		TableSourceTIN = "InformationRegister.CustomerRebatesTIN";
		TableSourceCounterparties = "InformationRegister.CustomerRebatesCounterparties";
		ExpressionSumPlanTIN = "INNOfClients.SumPlan";
		ExpressionAmountPlanCounterparties = "CustomerCounterparties.SumPlan";
		ExpressionCounterpartiesPartner = "CustomerCounterparties.Partner";
		
	ElsIf RebateConditionsParameters.CalculationOfSupplierBonuses Then
		
		TableSourceTIN = "InformationRegister.VendorRebatesTIN";
		TableSourceCounterparties = "InformationRegister.VendorRebatesCounterparties";
		ExpressionSumPlanTIN = "0";
		ExpressionAmountPlanCounterparties = "0";
		ExpressionCounterpartiesPartner = "VALUE(Catalog.Partners.EmptyRef)";
		
	Else
		Raise NStr("vi = 'Kiểu không xác định của thưởng lũy kế';
					|ru = 'Неизвестный тип ретро-бонуса';
					|en = 'Unknown rebate type'; fa = 'Unknown rebate type';
					|it = 'Неизвестный тип ретро-бонуса';
					|pl = 'Unknown rebate type';
					|tr = 'Bilinmeyen retro bonusu türü'");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ExpressionSumPlanTIN", ExpressionSumPlanTIN);
	QueryText = StrReplace(QueryText, "&ExpressionAmountPlanCounterparties", ExpressionAmountPlanCounterparties);
	QueryText = StrReplace(QueryText, "&ExpressionCounterpartiesPartner", ExpressionCounterpartiesPartner);
	
	QueryText = StrReplace(QueryText, "&TableSourceTIN", TableSourceTIN);
	QueryText = StrReplace(QueryText, "&TableSourceCounterparties", TableSourceCounterparties);
	
	QueryText = StrReplace(
		QueryText, "&SelectionConditionForCounterpartyToCatalog", SelectionConditionForCounterpartyToCatalog);
	QueryText = StrReplace(
		QueryText, "&PartnerSelectionCriteriaForCompositionOfSegments", PartnerSelectionCriteriaForCompositionOfSegments);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_PreliminaryParticipants.TermsAndConditionsOfRebates AS TermsAndConditionsOfRebates,
	|	VT_PreliminaryParticipants.Counterparty AS Counterparty,
	|	VT_PreliminaryParticipants.Partner AS Partner,
	|	VT_PreliminaryParticipants.StartDate AS StartDate,
	|	VT_PreliminaryParticipants.EndDate AS EndDate,
	|	VT_PreliminaryParticipants.SumPlan AS SumPlan
	|INTO TT_Counterparties
	|FROM
	|	VT_PreliminaryParticipants AS VT_PreliminaryParticipants
	|WHERE
	|	VT_PreliminaryParticipants.Partner = VALUE(Catalog.Partners.EmptyRef)
	|	AND &SelectionConditionByCounterparty";
	
	If OptionParameters.ThisIsTheTranscript Then
		
		SelectionConditionByCounterparty =
		"CASE
		|	WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
		|		OR &Counterparty = UNDEFINED
		|	THEN TRUE
		|	ELSE VT_PreliminaryParticipants.Counterparty = &Counterparty
		|END";
		
	Else
		
		SelectionConditionByCounterparty = "TRUE";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionConditionByCounterparty", SelectionConditionByCounterparty);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_PreliminaryParticipants.TermsAndConditionsOfRebates AS TermsAndConditionsOfRebates,
	|	VT_PreliminaryParticipants.Counterparty AS Counterparty,
	|	VT_PreliminaryParticipants.Partner AS Partner,
	|	VT_PreliminaryParticipants.StartDate AS StartDate,
	|	VT_PreliminaryParticipants.EndDate AS EndDate,
	|	VT_PreliminaryParticipants.SumPlan AS SumPlan
	|INTO TT_Partners
	|FROM
	|	VT_PreliminaryParticipants AS VT_PreliminaryParticipants
	|WHERE
	|	VT_PreliminaryParticipants.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|	AND VT_PreliminaryParticipants.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|	AND &PartnerSelectionCriteria";
	
	If OptionParameters.ThisIsTheTranscript Then
		
		PartnerSelectionCriteria =
		"CASE
		|	WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
		|		OR &Partner = UNDEFINED
		|	THEN TRUE
		|	ELSE VT_PreliminaryParticipants.Partner = &Partner
		|END";
		
	Else
		
		PartnerSelectionCriteria = "TRUE";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&PartnerSelectionCriteria", PartnerSelectionCriteria);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_PreliminaryParticipants.TermsAndConditionsOfRebates AS TermsAndConditionsOfRebates,
	|	VT_PreliminaryParticipants.Counterparty AS Counterparty,
	|	VT_PreliminaryParticipants.Partner AS Partner,
	|	VT_PreliminaryParticipants.StartDate AS StartDate,
	|	VT_PreliminaryParticipants.EndDate AS EndDate,
	|	VT_PreliminaryParticipants.SumPlan AS SumPlan
	|INTO TT_CounterpartyPartners
	|FROM
	|	VT_PreliminaryParticipants AS VT_PreliminaryParticipants
	|WHERE
	|	VT_PreliminaryParticipants.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|	AND VT_PreliminaryParticipants.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|	AND &SelectionConditionByCounterparty
	|	AND &PartnerSelectionCriteria";
	
	If OptionParameters.ThisIsTheTranscript Then
		
		SelectionConditionByCounterparty =
		"CASE
		|	WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
		|		OR &Counterparty = UNDEFINED
		|	THEN TRUE
		|	ELSE VT_PreliminaryParticipants.Counterparty = &Counterparty
		|END";
		PartnerSelectionCriteria =
		"CASE
		|	WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
		|		OR &Partner = UNDEFINED
		|	THEN TRUE
		|	ELSE VT_PreliminaryParticipants.Partner = &Partner
		|END";
		
	Else
		
		SelectionConditionByCounterparty = "TRUE";
		PartnerSelectionCriteria = "TRUE";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionConditionByCounterparty", SelectionConditionByCounterparty);
	QueryText = StrReplace(QueryText, "&PartnerSelectionCriteria", PartnerSelectionCriteria);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SubqueryTexts_ = New Array; // Array of String
	
	SubqueryText =
	"SELECT DISTINCT
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
	|	AccountingDimensionByPartners.Organization AS Organization,
	|	AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	AccountingDimensionByPartners.Partner AS Partner,
	|	DATETIME(1, 1, 1) AS StartDate,
	|	DATETIME(2999, 12, 31) AS EndDate,
	|	0 AS SumPlan
	|INTO TT_DimensionByPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|		INNER JOIN VT_RBParameters AS VT_RBParameters
	|		ON (TRUE)
	|WHERE
	|	VT_RBParameters.SelectionOfParticipantsWithoutRestrictions
	|	AND AccountingDimensionByPartners.Organization IN(&Organization)
	|	AND &SelectionConditionByCounterparty
	|	AND &PartnerSelectionCriteria";
	SubqueryTexts_.Add(SubqueryText);
	
	SubqueryText =
	"SELECT
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
	|	AccountingDimensionByPartners.Organization AS Organization,
	|	AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	AccountingDimensionByPartners.Partner AS Partner,
	|	TT_Counterparties.StartDate AS StartDate,
	|	ENDOFPERIOD(TT_Counterparties.EndDate, DAY) AS EndDate,
	|	0 AS SumPlan
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|		INNER JOIN TT_Counterparties AS TT_Counterparties
	|		ON AccountingDimensionByPartners.Counterparty = TT_Counterparties.Counterparty
	|WHERE
	|	AccountingDimensionByPartners.Organization IN (&Organization)
	|	AND NOT (AccountingDimensionByPartners.Counterparty, AccountingDimensionByPartners.Partner) IN
	|		(SELECT
	|			TT_CounterpartyPartners.Counterparty AS Counterparty,
	|			TT_CounterpartyPartners.Partner AS Partner
	|		FROM
	|			TT_CounterpartyPartners AS TT_CounterpartyPartners)";
	SubqueryTexts_.Add(SubqueryText);
	
	SubqueryText =
	"SELECT
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
	|	AccountingDimensionByPartners.Organization AS Organization,
	|	AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	AccountingDimensionByPartners.Partner AS Partner,
	|	TT_Partners.StartDate AS StartDate,
	|	ENDOFPERIOD(TT_Partners.EndDate, DAY) AS EndDate,
	|	0 AS SumPlan
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|		INNER JOIN TT_Partners AS TT_Partners
	|		ON AccountingDimensionByPartners.Partner = TT_Partners.Partner
	|WHERE
	|	AccountingDimensionByPartners.Organization IN (&Organization)
	|	AND NOT (AccountingDimensionByPartners.Counterparty, AccountingDimensionByPartners.Partner) IN
	|		(SELECT
	|			TT_CounterpartyPartners.Counterparty AS Counterparty,
	|			TT_CounterpartyPartners.Partner AS Partner
	|		FROM
	|			TT_CounterpartyPartners AS TT_CounterpartyPartners)";
	SubqueryTexts_.Add(SubqueryText);
	
	SubqueryText =
	"SELECT
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
	|	AccountingDimensionByPartners.Organization AS Organization,
	|	AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	AccountingDimensionByPartners.Partner AS Partner,
	|	TT_CounterpartyPartners.StartDate AS StartDate,
	|	ENDOFPERIOD(TT_CounterpartyPartners.EndDate, DAY) AS EndDate,
	|	0 AS SumPlan
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|		INNER JOIN TT_CounterpartyPartners AS TT_CounterpartyPartners
	|		ON AccountingDimensionByPartners.Partner = TT_CounterpartyPartners.Partner
	|		AND AccountingDimensionByPartners.Counterparty = TT_CounterpartyPartners.Counterparty
	|WHERE
	|	AccountingDimensionByPartners.Organization IN (&Organization)";
	SubqueryTexts_.Add(SubqueryText);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Contracts Then
		
		SubqueryText =
		"SELECT
		|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
		|	AccountingDimensionByPartners.Organization AS Organization,
		|	AccountingDimensionByPartners.Counterparty AS Counterparty,
		|	AccountingDimensionByPartners.Partner AS Partner,
		|	CustomerRebatesContractsTermsOfSales.ValidOnDate AS StartDate,
		|	ENDOFPERIOD(CustomerRebatesContractsTermsOfSales.ValidTo, DAY) AS EndDate,
		|	CustomerRebatesContractsTermsOfSales.SumPlan AS SumPlan
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|		INNER JOIN InformationRegister.CustomerRebatesContractsTermsOfSales AS CustomerRebatesContractsTermsOfSales
		|		ON AccountingDimensionByPartners.Contract = CustomerRebatesContractsTermsOfSales.Contract
		|WHERE
		|	AccountingDimensionByPartners.Organization IN (&Organization)
		|	AND CustomerRebatesContractsTermsOfSales.TermDocument = &SourceDocument_
		|	AND CustomerRebatesContractsTermsOfSales.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|	AND &SelectionConditionByCounterparty
		|	AND &PartnerSelectionCriteria";
		SubqueryTexts_.Add(SubqueryText);
		
	EndIf;
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		SubqueryText =
		"SELECT
		|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
		|	AccountingDimensionByPartners.Organization AS Organization,
		|	AccountingDimensionByPartners.Counterparty AS Counterparty,
		|	AccountingDimensionByPartners.Partner AS Partner,
		|	TT_Terms1.ValidOnDate AS StartDate,
		|	ENDOFPERIOD(TT_Terms1.ValidTo, DAY) AS EndDate,
		|	TT_Terms1.SumPlan AS SumPlan
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|		INNER JOIN TT_Terms1 AS TT_Terms1
		|		ON AccountingDimensionByPartners.Partner = TT_Terms1.Partner
		|		LEFT JOIN VT_AnalyticsForPartnersUnderStandardAgreements AS VT_AnalyticsForPartnersUnderStandardAgreements
		|		ON AccountingDimensionByPartners.DimensionKey = VT_AnalyticsForPartnersUnderStandardAgreements.DimensionKey
		|WHERE
		|	TT_Terms1.ModelAgreement = FALSE
		|	AND VT_AnalyticsForPartnersUnderStandardAgreements.DimensionKey IS NULL
		|	AND AccountingDimensionByPartners.Organization IN (&Organization)
		|	AND &SelectionConditionByCounterparty
		|	AND &PartnerSelectionCriteria";
		SubqueryTexts_.Add(SubqueryText);
		
		SubqueryText =
		"SELECT
		|	VT_AnalyticsForPartnersUnderStandardAgreements.DimensionKey AS DimensionKey,
		|	VT_AnalyticsForPartnersUnderStandardAgreements.Organization AS Organization,
		|	VT_AnalyticsForPartnersUnderStandardAgreements.Counterparty AS Counterparty,
		|	VT_AnalyticsForPartnersUnderStandardAgreements.Partner AS Partner,
		|	TT_Terms1.ValidOnDate AS StartDate,
		|	ENDOFPERIOD(TT_Terms1.ValidTo, DAY) AS EndDate,
		|	TT_Terms1.SumPlan AS SumPlan
		|FROM
		|	VT_AnalyticsForPartnersUnderStandardAgreements AS VT_AnalyticsForPartnersUnderStandardAgreements
		|		INNER JOIN TT_Terms1 AS TT_Terms1
		|		ON VT_AnalyticsForPartnersUnderStandardAgreements.Terms = TT_Terms1.Terms";
		SubqueryTexts_.Add(SubqueryText);
		
	EndIf;
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	
	If OptionParameters.ThisIsTheTranscript Then
		
		SelectionConditionByCounterparty =
		"CASE
		|	WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
		|		OR &Counterparty = UNDEFINED
		|	THEN TRUE
		|	ELSE AccountingDimensionByPartners.Counterparty = &Counterparty
		|END";
		PartnerSelectionCriteria =
		"CASE
		|	WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
		|		OR &Partner = UNDEFINED
		|	THEN TRUE
		|	ELSE AccountingDimensionByPartners.Partner = &Partner
		|END";
		
	Else
		
		SelectionConditionByCounterparty = "TRUE";
		PartnerSelectionCriteria = "TRUE";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionConditionByCounterparty", SelectionConditionByCounterparty);
	QueryText = StrReplace(QueryText, "&PartnerSelectionCriteria", PartnerSelectionCriteria);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	If RebateConditionsParameters.Goods = Enums.RebatesLists.All Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	ItemsLocationAttributes.DimensionKey AS DimensionKey
	|INTO TT_ItemsLocationAttributes
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS ItemsLocationAttributes
	|		INNER JOIN TT_Goods AS TT_Goods
	|		ON ItemsLocationAttributes.Products = TT_Goods.Products
	|			AND ItemsLocationAttributes.Characteristic = TT_Goods.Characteristic
	|WHERE
	|	TT_Goods.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ItemsLocationAttributes.DimensionKey AS DimensionKey
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS ItemsLocationAttributes
	|		INNER JOIN TT_Goods AS TT_Goods
	|		ON ItemsLocationAttributes.Products = TT_Goods.Products
	|WHERE
	|	TT_Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryTemplate =
	"SELECT ALLOWED
	|	RevenueAndCOGS.Period AS Period,
	|	&ExpressionPeriod AS CalculationPeriod,
	|	&ExpressionDocumentLogger AS DocumentRecorder,
	|	RS__AccountingDimensionByPartners.Organization AS Organization,
	|	RS__AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RS__AccountingDimensionByPartners.Partner AS Partner,
	|	RevenueAndCOGS.Contract AS Contract,
	|	RevenueAndCOGS.Terms AS Terms,
	|	RevenueAndCOGS.Warehouse AS Warehouse,
	|	RS_InventoryAccountingAnalytics.Products AS Products,
	|	RS_InventoryAccountingAnalytics.Characteristic AS Characteristic,
	|	SUM(RevenueAndCOGS.Count) AS Count,
	|	SUM(RevenueAndCOGS.RevenueAmount) AS AmountOfTurnoverOfMansWithVAT,
	|	SUM(RevenueAndCOGS.RevenueAmountIncludingVATLocal) AS AmountOfTurnoverOfLocalWithVAT,
	|	SUM(RevenueAndCOGS.AmountInARAPCurrency) AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	SUM(RevenueAndCOGS.RevenueAmountExcludingVAT) AS ManSTurnoverAmountExcludingVAT,
	|	SUM(RevenueAndCOGS.RevenueAmountExclVATLocal) AS AmountOfTurnoverIsLocalWithoutVAT,
	|	SUM(RevenueAndCOGS.AmountExcludingVATInARAPCurrency) AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	SUM(CASE
	|		WHEN VT_RBParameters.ConsiderVAT
	|			THEN RevenueAndCOGS.RevenueAmount
	|		ELSE RevenueAndCOGS.RevenueAmountExcludingVAT
	|	END) AS Sum,
	|	SUM(CASE
	|		WHEN VT_RBParameters.ConsiderVAT
	|			THEN RevenueAndCOGS.RevenueAmountIncludingVATLocal
	|		ELSE RevenueAndCOGS.RevenueAmountExclVATLocal
	|	END) AS SumCompl,
	|	SUM(CASE
	|		WHEN VT_RBParameters.ConsiderVAT
	|			THEN RevenueAndCOGS.AmountInARAPCurrency
	|		ELSE RevenueAndCOGS.AmountExcludingVATInARAPCurrency
	|	END) AS AmountInARAPCurrency,
	|	VT_RBParameters.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_RBParameters.BonusPercent AS BonusPercent,
	|	VT_RBParameters.GoodsIndicator AS GoodsIndicator,
	|	VT_RBParameters.PartyCountDetails AS PartyCountDetails,
	|	VT_RBParameters.ConditionFrequency AS ConditionFrequency,
	|	VT_RBParameters.AccrualFrequency AS AccrualFrequency,
	|	VT_RBParameters.ConsiderVAT AS ConsiderVAT,
	|	VT_RBParameters.Currency AS CurrencyOfConditions,
	|	RevenueAndCOGS.ARAPCurrency AS ARAPCurrency,
	|	VT_RBParameters.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_RBParameters.FIFODistribution AS FIFODistribution,
	|	VT_RBParameters.SumPlan AS SumPlan,
	|	VT_RBParameters.BaseOfCalculation AS BaseOfCalculation,
	|	VT_RBParameters.SelectionOfGoodsSelected AS SelectionOfGoodsSelected,
	|	VT_RBParameters.SelectionOfGoodsOtherThanSelected AS SelectionOfGoodsOtherThanSelected,
	|	VT_RBParameters.SelectionOfGoodsWithoutRestrictions AS SelectionOfGoodsWithoutRestrictions,
	|	VT_RBParameters.SelectionOfParticipantsSelected AS SelectionOfParticipantsSelected,
	|	VT_RBParameters.SelectionOfParticipantsExceptSelected AS SelectionOfParticipantsExceptSelected
	|INTO TT_SalesPurchases
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS RS_InventoryAccountingAnalytics
	|		ON RevenueAndCOGS.ItemsLocationAttributes = RS_InventoryAccountingAnalytics.DimensionKey
	|		LEFT JOIN TT_DimensionByPartners AS TT_DimensionByPartners
	|		ON RevenueAndCOGS.AccountingDimensionByPartners = TT_DimensionByPartners.DimensionKey
	|			AND (RevenueAndCOGS.Period BETWEEN TT_DimensionByPartners.StartDate AND TT_DimensionByPartners.EndDate)
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RS__AccountingDimensionByPartners
	|			LEFT JOIN VT_RBParameters AS VT_RBParameters
	|			ON TRUE
	|		ON RevenueAndCOGS.AccountingDimensionByPartners = RS__AccountingDimensionByPartners.DimensionKey
	|WHERE
	|	&SelectionCriteriaByDocumentType
	|	AND RevenueAndCOGS.Period BETWEEN &StartDate AND &EndDate
	|	AND CASE
	|		WHEN VT_RBParameters.SelectionOfParticipantsSelected
	|			THEN NOT TT_DimensionByPartners.DimensionKey IS NULL
	|		WHEN VT_RBParameters.SelectionOfParticipantsExceptSelected
	|			THEN TT_DimensionByPartners.DimensionKey IS NULL
	|		ELSE TRUE
	|	END
	|	AND &ConditionOfSelectionOfGoods
	|	AND RS__AccountingDimensionByPartners.Organization IN (&Organization)
	|	AND &SelectionConditionByCounterparty
	|	AND &PartnerSelectionCriteria
	|	AND NOT VT_RBParameters.ConditionOfRebateBonusIs IS NULL
	|	AND RevenueAndCOGS.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	AND RevenueAndCOGS.BusinessOperation NOT IN (&ExcludedBusinessOfOperations)
	|	AND RevenueAndCOGS.BusinessTransactionSetting NOT IN (&ExcludedSettingsOfBusinessTransaction)
	|
	|GROUP BY
	|	RevenueAndCOGS.Period,
	|	&ExpressionPeriod,
	|	&ExpressionDocumentLogger,
	|	RS__AccountingDimensionByPartners.Organization,
	|	RS__AccountingDimensionByPartners.Counterparty,
	|	RS__AccountingDimensionByPartners.Partner,
	|	RevenueAndCOGS.Contract,
	|	RevenueAndCOGS.Terms,
	|	RevenueAndCOGS.Warehouse,
	|	RS_InventoryAccountingAnalytics.Products,
	|	RS_InventoryAccountingAnalytics.Characteristic,
	|	VT_RBParameters.ConditionOfRebateBonusIs,
	|	VT_RBParameters.BonusPercent,
	|	VT_RBParameters.GoodsIndicator,
	|	VT_RBParameters.PartyCountDetails,
	|	VT_RBParameters.ConditionFrequency,
	|	VT_RBParameters.AccrualFrequency,
	|	VT_RBParameters.ConsiderVAT,
	|	VT_RBParameters.Currency,
	|	RevenueAndCOGS.ARAPCurrency,
	|	VT_RBParameters.RestrictAccrualOverPlan,
	|	VT_RBParameters.FIFODistribution,
	|	VT_RBParameters.SumPlan,
	|	VT_RBParameters.BaseOfCalculation,
	|	VT_RBParameters.SelectionOfGoodsSelected,
	|	VT_RBParameters.SelectionOfGoodsOtherThanSelected,
	|	VT_RBParameters.SelectionOfGoodsWithoutRestrictions,
	|	VT_RBParameters.SelectionOfParticipantsSelected,
	|	VT_RBParameters.SelectionOfParticipantsExceptSelected";
	
	ExpressionsDocumentLogger = New Array; // Array of String
	ExpressionsDocumentLogger.Add("CAST(RevenueAndCOGS.Recorder AS Document.CustomerInvoice)");
	ExpressionsDocumentLogger.Add("CAST(RevenueAndCOGS.Recorder AS Document.SaleAdjustment)");
	ExpressionsDocumentLogger.Add("CAST(RevenueAndCOGS.Recorder AS Document.CustomerInvoiceServices)");
	ExpressionsDocumentLogger.Add("CAST(RevenueAndCOGS.Recorder AS Document.ReturnOfGoodsFromCustomer)");
	
	SelectionsByDocumentType = New Array; // Array of String
	SelectionsByDocumentType.Add("RevenueAndCOGS.Recorder REFS Document.CustomerInvoice");
	SelectionsByDocumentType.Add("RevenueAndCOGS.Recorder REFS Document.SaleAdjustment");
	SelectionsByDocumentType.Add("RevenueAndCOGS.Recorder REFS Document.CustomerInvoiceServices");
	SelectionsByDocumentType.Add("RevenueAndCOGS.Recorder REFS Document.ReturnOfGoodsFromCustomer");
	
	If RebateConditionsParameters.Goods = Enums.RebatesLists.Selected_ Then
		
		ConditionOfSelectionOfGoods =
		"VT_RBParameters.SelectionOfGoodsSelected
		|	AND RevenueAndCOGS.ItemsLocationAttributes IN
		|			(SELECT
		|				TT_ItemsLocationAttributes.DimensionKey
		|			FROM
		|				TT_ItemsLocationAttributes AS TT_ItemsLocationAttributes)";
		
	ElsIf RebateConditionsParameters.Goods = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		ConditionOfSelectionOfGoods =
		"VT_RBParameters.SelectionOfGoodsOtherThanSelected
		|	AND NOT RevenueAndCOGS.ItemsLocationAttributes IN
		|			(SELECT
		|				TT_ItemsLocationAttributes.DimensionKey
		|			FROM
		|				TT_ItemsLocationAttributes AS TT_ItemsLocationAttributes)";
		
	Else
		
		ConditionOfSelectionOfGoods = "VT_RBParameters.SelectionOfGoodsWithoutRestrictions";
		
	EndIf;
	
	ExpressionPeriod = ExpressionCalculationPeriod(RebateConditionsParameters);
	
	If OptionParameters.ThisIsTheTranscript Then
		
		SelectionConditionByCounterparty =
		"CASE
		|	WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
		|		OR &Counterparty = UNDEFINED
		|	THEN TRUE
		|	ELSE RS__AccountingDimensionByPartners.Counterparty = &Counterparty
		|END";
		PartnerSelectionCriteria =
		"CASE
		|	WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
		|		OR &Partner = UNDEFINED
		|	THEN TRUE
		|	ELSE RS__AccountingDimensionByPartners.Partner = &Partner
		|END";
		
	Else
		
		SelectionConditionByCounterparty = "TRUE";
		PartnerSelectionCriteria = "TRUE";
		
	EndIf;
	
	SubqueryTexts_ = New Array; // Array of String
	SubqueryNumber = 1;
	For DocumentTypeIndex = 0 To SelectionsByDocumentType.UBound() Do
		
		ExpressionDocumentLogger = ExpressionsDocumentLogger[DocumentTypeIndex];
		SelectionCriteriaByDocumentType = SelectionsByDocumentType[DocumentTypeIndex];
		
		QueryText = QueryTemplate;
		
		QueryText = StrReplace(QueryText, "&ExpressionPeriod", ExpressionPeriod);
		QueryText = StrReplace(QueryText, "&ExpressionDocumentLogger", ExpressionDocumentLogger);
		QueryText = StrReplace(QueryText, "&SelectionCriteriaByDocumentType", SelectionCriteriaByDocumentType);
		QueryText = StrReplace(QueryText, "&ConditionOfSelectionOfGoods", ConditionOfSelectionOfGoods);
		QueryText = StrReplace(QueryText, "&SelectionConditionByCounterparty", SelectionConditionByCounterparty);
		QueryText = StrReplace(QueryText, "&PartnerSelectionCriteria", PartnerSelectionCriteria);
		
		If SubqueryNumber > 1 Then
			
			QueryText = StrReplace(QueryText, "ALLOWED", "");
			QueryText = StrReplace(QueryText, "INTO TT_SalesPurchases", "");
			
		EndIf;
		
		SubqueryTexts_.Add(QueryText);
		SubqueryNumber = SubqueryNumber + 1;
		
	EndDo;
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextOfSaleWithoutSelectionByCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryTemplate =
	"SELECT
	|	RevenueAndCOGS.Period AS Period,
	|	RevenueAndCOGS.LineNumber AS LineNumber,
	|	&ExpressionPeriod AS CalculationPeriod,
	|	&ExpressionDocumentLogger AS DocumentRecorder,
	|	RS__AccountingDimensionByPartners.Organization AS Organization,
	|	RS__AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RS__AccountingDimensionByPartners.Partner AS Partner,
	|	RevenueAndCOGS.Contract AS Contract,
	|	RevenueAndCOGS.Terms AS Terms,
	|	RevenueAndCOGS.Warehouse AS Warehouse,
	|	RS_InventoryAccountingAnalytics.Products AS Products,
	|	RS_InventoryAccountingAnalytics.Characteristic AS Characteristic,
	|	RevenueAndCOGS.Count AS Count,
	|	RevenueAndCOGS.RevenueAmount AS AmountOfTurnoverOfMansWithVAT,
	|	RevenueAndCOGS.RevenueAmountIncludingVATLocal AS AmountOfTurnoverOfLocalWithVAT,
	|	RevenueAndCOGS.AmountInARAPCurrency AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	RevenueAndCOGS.RevenueAmountExcludingVAT AS ManSTurnoverAmountExcludingVAT,
	|	RevenueAndCOGS.RevenueAmountExclVATLocal AS AmountOfTurnoverIsLocalWithoutVAT,
	|	RevenueAndCOGS.AmountExcludingVATInARAPCurrency AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	VT_RBParameters.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_RBParameters.BonusPercent AS BonusPercent,
	|	VT_RBParameters.GoodsIndicator AS GoodsIndicator,
	|	VT_RBParameters.PartyCountDetails AS PartyCountDetails,
	|	VT_RBParameters.ConditionFrequency AS ConditionFrequency,
	|	VT_RBParameters.AccrualFrequency AS AccrualFrequency,
	|	VT_RBParameters.ConsiderVAT AS ConsiderVAT,
	|	VT_RBParameters.Currency AS CurrencyOfConditions,
	|	VT_RBParameters.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_RBParameters.FIFODistribution AS FIFODistribution,
	|	VT_RBParameters.SumPlan AS TotalPlanAmount,
	|	TT_DimensionByPartners.SumPlan AS AmountOfPlanByAgreement,
	|	RevenueAndCOGS.ARAPCurrency AS ARAPCurrency,
	|	VT_RBParameters.BaseOfCalculation AS BaseOfCalculation,
	|	VT_RBParameters.SelectionOfGoodsSelected AS SelectionOfGoodsSelected,
	|	VT_RBParameters.SelectionOfGoodsOtherThanSelected AS SelectionOfGoodsOtherThanSelected,
	|	VT_RBParameters.SelectionOfGoodsWithoutRestrictions AS SelectionOfGoodsWithoutRestrictions,
	|	VT_RBParameters.SelectionOfParticipantsSelected AS SelectionOfParticipantsSelected,
	|	VT_RBParameters.SelectionOfParticipantsExceptSelected AS SelectionOfParticipantsExceptSelected
	|INTO VT_SalesPurchasesWithoutSelectionByCounterparties
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS RS_InventoryAccountingAnalytics
	|		ON RevenueAndCOGS.ItemsLocationAttributes = RS_InventoryAccountingAnalytics.DimensionKey
	|		LEFT JOIN TT_DimensionByPartners AS TT_DimensionByPartners
	|		ON RevenueAndCOGS.AccountingDimensionByPartners = TT_DimensionByPartners.DimensionKey
	|			AND (RevenueAndCOGS.Period BETWEEN TT_DimensionByPartners.StartDate AND TT_DimensionByPartners.EndDate)
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RS__AccountingDimensionByPartners
	|			LEFT JOIN VT_RBParameters AS VT_RBParameters
	|			ON TRUE
	|		ON RevenueAndCOGS.AccountingDimensionByPartners = RS__AccountingDimensionByPartners.DimensionKey
	|WHERE
	|	&SelectionCriteriaByDocumentType
	|	AND RevenueAndCOGS.Period BETWEEN &StartDate AND &EndDate
	|	AND CASE
	|			WHEN VT_RBParameters.SelectionOfParticipantsSelected
	|				THEN NOT TT_DimensionByPartners.DimensionKey IS NULL
	|			WHEN VT_RBParameters.SelectionOfParticipantsExceptSelected
	|				THEN TT_DimensionByPartners.DimensionKey IS NULL
	|			ELSE TRUE
	|		END
	|	AND &ConditionOfSelectionOfGoods
	|	AND RS__AccountingDimensionByPartners.Organization IN(&Organization)
	|	AND &SelectionConditionByCounterparty
	|	AND &PartnerSelectionCriteria
	|	AND NOT VT_RBParameters.ConditionOfRebateBonusIs IS NULL
	|	AND RevenueAndCOGS.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	AND RevenueAndCOGS.BusinessTransactionSetting NOT IN (&ExcludedSettingsOfBusinessTransaction)
	|	AND RevenueAndCOGS.BusinessOperation NOT IN (&ExcludedBusinessOfOperations)";
	
	ExpressionsDocumentLogger = New Array; // Array of String
	ExpressionsDocumentLogger.Add("CAST(RevenueAndCOGS.Recorder AS Document.CustomerInvoice)");
	ExpressionsDocumentLogger.Add("CAST(RevenueAndCOGS.Recorder AS Document.SaleAdjustment)");
	ExpressionsDocumentLogger.Add("CAST(RevenueAndCOGS.Recorder AS Document.CustomerInvoiceServices)");
	ExpressionsDocumentLogger.Add("CAST(RevenueAndCOGS.Recorder AS Document.ReturnOfGoodsFromCustomer)");
	
	SelectionsByDocumentType = New Array; // Array of String
	SelectionsByDocumentType.Add("RevenueAndCOGS.Recorder REFS Document.CustomerInvoice");
	SelectionsByDocumentType.Add("RevenueAndCOGS.Recorder REFS Document.SaleAdjustment");
	SelectionsByDocumentType.Add("RevenueAndCOGS.Recorder REFS Document.CustomerInvoiceServices");
	SelectionsByDocumentType.Add("RevenueAndCOGS.Recorder REFS Document.ReturnOfGoodsFromCustomer");
	
	If RebateConditionsParameters.Goods = Enums.RebatesLists.Selected_ Then
		
		ConditionOfSelectionOfGoods =
		"VT_RBParameters.SelectionOfGoodsSelected
		|	AND RevenueAndCOGS.ItemsLocationAttributes IN
		|			(SELECT
		|				TT_ItemsLocationAttributes.DimensionKey
		|			FROM
		|				TT_ItemsLocationAttributes AS TT_ItemsLocationAttributes)";
		
	ElsIf RebateConditionsParameters.Goods = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		ConditionOfSelectionOfGoods =
		"VT_RBParameters.SelectionOfGoodsOtherThanSelected
		|	AND NOT RevenueAndCOGS.ItemsLocationAttributes IN
		|			(SELECT
		|				TT_ItemsLocationAttributes.DimensionKey
		|			FROM
		|				TT_ItemsLocationAttributes AS TT_ItemsLocationAttributes)";
		
	Else
		
		ConditionOfSelectionOfGoods = "VT_RBParameters.SelectionOfGoodsWithoutRestrictions";
		
	EndIf;
	
	ExpressionPeriod = ExpressionCalculationPeriod(RebateConditionsParameters);
	
	If OptionParameters.ThisIsTheTranscript Then
		
		SelectionConditionByCounterparty =
		"CASE
		|	WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
		|		OR &Counterparty = UNDEFINED
		|	THEN TRUE
		|	ELSE RS__AccountingDimensionByPartners.Counterparty = &Counterparty
		|END";
		PartnerSelectionCriteria =
		"CASE
		|	WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
		|		OR &Partner = UNDEFINED
		|	THEN TRUE
		|	ELSE RS__AccountingDimensionByPartners.Partner = &Partner
		|END";
		
	Else
		
		SelectionConditionByCounterparty = "TRUE";
		PartnerSelectionCriteria = "TRUE";
		
	EndIf;
	
	SubqueryTexts_ = New Array; // Array of String
	SubqueryNumber = 1;
	For DocumentTypeIndex = 0 To SelectionsByDocumentType.UBound() Do
		
		ExpressionDocumentLogger = ExpressionsDocumentLogger[DocumentTypeIndex];
		SelectionCriteriaByDocumentType = SelectionsByDocumentType[DocumentTypeIndex];
		
		QueryText = QueryTemplate;
		
		QueryText = StrReplace(QueryText, "&ExpressionPeriod", ExpressionPeriod);
		QueryText = StrReplace(QueryText, "&ExpressionDocumentLogger", ExpressionDocumentLogger);
		QueryText = StrReplace(QueryText, "&SelectionCriteriaByDocumentType", SelectionCriteriaByDocumentType);
		QueryText = StrReplace(QueryText, "&ConditionOfSelectionOfGoods", ConditionOfSelectionOfGoods);
		QueryText = StrReplace(QueryText, "&SelectionConditionByCounterparty", SelectionConditionByCounterparty);
		QueryText = StrReplace(QueryText, "&PartnerSelectionCriteria", PartnerSelectionCriteria);
		
		If SubqueryNumber > 1 Then
			
			QueryText = StrReplace(QueryText, "INTO VT_SalesPurchasesWithoutSelectionByCounterparties", "");
			
		EndIf;
		
		SubqueryTexts_.Add(QueryText);
		SubqueryNumber = SubqueryNumber + 1;
		
	EndDo;
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddSalesQueryTextWithSelectionByCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	RawData.Period AS Period,
	|	RawData.CalculationPeriod AS CalculationPeriod,
	|	RawData.DocumentRecorder AS DocumentRecorder,
	|	RawData.Organization AS Organization,
	|	RawData.Counterparty AS Counterparty,
	|	RawData.Partner AS Partner,
	|	RawData.Contract AS Contract,
	|	RawData.Terms AS Terms,
	|	RawData.Warehouse AS Warehouse,
	|	RawData.Products AS Products,
	|	RawData.Characteristic AS Characteristic,
	|	SUM(RawData.Count) AS Count,
	|	SUM(RawData.AmountOfTurnoverOfMansWithVAT) AS AmountOfTurnoverOfMansWithVAT,
	|	SUM(RawData.AmountOfTurnoverOfLocalWithVAT) AS AmountOfTurnoverOfLocalWithVAT,
	|	SUM(RawData.AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT) AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	SUM(RawData.ManSTurnoverAmountExcludingVAT) AS ManSTurnoverAmountExcludingVAT,
	|	SUM(RawData.AmountOfTurnoverIsLocalWithoutVAT) AS AmountOfTurnoverIsLocalWithoutVAT,
	|	SUM(RawData.AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT) AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	SUM(CASE
	|		WHEN RawData.ConsiderVAT
	|			THEN RawData.AmountOfTurnoverOfMansWithVAT
	|		ELSE RawData.ManSTurnoverAmountExcludingVAT
	|	END) AS Sum,
	|	SUM(CASE
	|		WHEN RawData.ConsiderVAT
	|			THEN RawData.AmountOfTurnoverOfLocalWithVAT
	|		ELSE RawData.AmountOfTurnoverIsLocalWithoutVAT
	|	END) AS SumCompl,
	|	SUM(CASE
	|		WHEN RawData.ConsiderVAT
	|			THEN RawData.AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT
	|		ELSE RawData.AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT
	|	END) AS AmountInARAPCurrency,
	|	RawData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	RawData.BonusPercent AS BonusPercent,
	|	RawData.GoodsIndicator AS GoodsIndicator,
	|	RawData.PartyCountDetails AS PartyCountDetails,
	|	RawData.ConditionFrequency AS ConditionFrequency,
	|	RawData.AccrualFrequency AS AccrualFrequency,
	|	RawData.ConsiderVAT AS ConsiderVAT,
	|	RawData.CurrencyOfConditions AS CurrencyOfConditions,
	|	RawData.ARAPCurrency AS ARAPCurrency,
	|	RawData.BaseOfCalculation AS BaseOfCalculation,
	|	RawData.SelectionOfGoodsSelected AS SelectionOfGoodsSelected,
	|	RawData.SelectionOfGoodsOtherThanSelected AS SelectionOfGoodsOtherThanSelected,
	|	RawData.SelectionOfGoodsWithoutRestrictions AS SelectionOfGoodsWithoutRestrictions,
	|	RawData.SelectionOfParticipantsSelected AS SelectionOfParticipantsSelected,
	|	RawData.SelectionOfParticipantsExceptSelected AS SelectionOfParticipantsExceptSelected,
	|	RawData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	RawData.FIFODistribution AS FIFODistribution,
	|	CASE
	|		WHEN ISNULL(TT_CounterpartyPartners.SumPlan, 0) <> 0
	|			THEN ISNULL(TT_CounterpartyPartners.SumPlan, 0)
	|		WHEN ISNULL(TT_Partners.SumPlan, 0) <> 0
	|			THEN ISNULL(TT_Partners.SumPlan, 0)
	|		WHEN ISNULL(TT_Counterparties.SumPlan, 0) <> 0
	|			THEN ISNULL(TT_Counterparties.SumPlan, 0)
	|		WHEN ISNULL(RawData.AmountOfPlanByAgreement, 0) <> 0
	|			THEN RawData.AmountOfPlanByAgreement
	|		ELSE ISNULL(RawData.TotalPlanAmount, 0)
	|	END AS SumPlan
	|INTO TT_SalesPurchases
	|FROM
	|	VT_SalesPurchasesWithoutSelectionByCounterparties AS RawData
	|		LEFT JOIN TT_Counterparties AS TT_Counterparties
	|		ON RawData.ConditionOfRebateBonusIs = TT_Counterparties.TermsAndConditionsOfRebates
	|			AND RawData.Counterparty = TT_Counterparties.Counterparty
	|			AND (RawData.Period BETWEEN TT_Counterparties.StartDate AND TT_Counterparties.EndDate)
	|		LEFT JOIN TT_Partners AS TT_Partners
	|		ON RawData.ConditionOfRebateBonusIs = TT_Partners.TermsAndConditionsOfRebates
	|			AND RawData.Partner = TT_Partners.Partner
	|			AND (RawData.Period BETWEEN TT_Partners.StartDate AND TT_Partners.EndDate)
	|		LEFT JOIN TT_CounterpartyPartners AS TT_CounterpartyPartners
	|		ON RawData.ConditionOfRebateBonusIs = TT_CounterpartyPartners.TermsAndConditionsOfRebates
	|			AND RawData.Counterparty = TT_CounterpartyPartners.Counterparty
	|			AND RawData.Partner = TT_CounterpartyPartners.Partner
	|			AND (RawData.Period BETWEEN TT_CounterpartyPartners.StartDate AND TT_CounterpartyPartners.EndDate)
	|GROUP BY
	|	RawData.Period,
	|	RawData.CalculationPeriod,
	|	RawData.DocumentRecorder,
	|	RawData.Organization,
	|	RawData.Counterparty,
	|	RawData.Partner,
	|	RawData.Contract,
	|	RawData.Terms,
	|	RawData.Warehouse,
	|	RawData.Products,
	|	RawData.Characteristic,
	|	RawData.RestrictAccrualOverPlan,
	|	RawData.FIFODistribution,
	|	CASE
	|		WHEN ISNULL(TT_CounterpartyPartners.SumPlan, 0) <> 0
	|			THEN ISNULL(TT_CounterpartyPartners.SumPlan, 0)
	|		WHEN ISNULL(TT_Partners.SumPlan, 0) <> 0
	|			THEN ISNULL(TT_Partners.SumPlan, 0)
	|		WHEN ISNULL(TT_Counterparties.SumPlan, 0) <> 0
	|			THEN ISNULL(TT_Counterparties.SumPlan, 0)
	|		WHEN ISNULL(RawData.AmountOfPlanByAgreement, 0) <> 0
	|			THEN RawData.AmountOfPlanByAgreement
	|		ELSE ISNULL(RawData.TotalPlanAmount, 0)
	|	END,
	|	RawData.ConditionOfRebateBonusIs,
	|	RawData.BonusPercent,
	|	RawData.GoodsIndicator,
	|	RawData.PartyCountDetails,
	|	RawData.ConditionFrequency,
	|	RawData.AccrualFrequency,
	|	RawData.ConsiderVAT,
	|	RawData.CurrencyOfConditions,
	|	RawData.ARAPCurrency,
	|	RawData.BaseOfCalculation,
	|	RawData.SelectionOfGoodsSelected,
	|	RawData.SelectionOfGoodsOtherThanSelected,
	|	RawData.SelectionOfGoodsWithoutRestrictions,
	|	RawData.SelectionOfParticipantsSelected,
	|	RawData.SelectionOfParticipantsExceptSelected";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	GoodsIndicator = RebateConditionsParameters.GoodsIndicator;
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	EmptyPropertyValue = EmptyValueOfCompositeField(RebateConditionsParameters.ItemPropertyValueType);
	
	QueryText =
	"SELECT
	|	TT_SalesPurchases.Period AS Period,
	|	RECORDAUTONUMBER() AS LineNumber,
	|	TT_SalesPurchases.CalculationPeriod AS CalculationPeriod,
	|	TT_SalesPurchases.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_SalesPurchases.GoodsIndicator AS GoodsIndicator,
	|	TT_SalesPurchases.PartyCountDetails AS PartyCountDetails,
	|	TT_SalesPurchases.AccrualFrequency AS AccrualFrequency,
	|	&ExpressionOfTimeFenceOfConditions AS ConditionFrequency,
	|	&ExpressionProhibitionOfAccrualInExcessOfPlan AS RestrictAccrualOverPlan,
	|	&ExpressionFIFODistribution AS FIFODistribution,
	|	&ExpressionSumPlan AS SumPlan,
	|	&ExpressionNumberPlan AS CountPlan,
	|	TT_SalesPurchases.DocumentRecorder AS DocumentRecorder,
	|	TT_SalesPurchases.Organization AS Organization,
	|	TT_SalesPurchases.Counterparty AS Counterparty,
	|	TT_SalesPurchases.Partner AS Partner,
	|	TT_SalesPurchases.Contract AS Contract,
	|	TT_SalesPurchases.Terms AS Terms,
	|	TT_SalesPurchases.Products AS Products,
	|	CAST(TT_SalesPurchases.Products AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure,
	|	&ExpressionCharacteristicsAreUsed AS ItemVariantsAreUsed,
	|	&ExpressionCharacteristicOfCalculation AS Characteristic,
	|	TT_SalesPurchases.Characteristic AS CharacteristicsOfSalesPurchases,
	|	&PropertyValueExpression AS PropertyValue,
	|	TT_SalesPurchases.Count AS Count,
	|	TT_SalesPurchases.BaseOfCalculation AS BaseOfCalculation,
	|	TT_SalesPurchases.CurrencyOfConditions AS CurrencyOfConditions,
	|	TT_SalesPurchases.ARAPCurrency AS ARAPCurrency,
	|	&ExpressionCalculationCurrency AS Currency,
	|	CASE
	|		WHEN &ExpressionTurnover < 0
	|			THEN 0
	|		ELSE 1
	|	END AS SignOfRevolutions,
	|	TT_SalesPurchases.Sum AS Sum,
	|	TT_SalesPurchases.SumCompl AS SumCompl,
	|	TT_SalesPurchases.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	TT_SalesPurchases.AmountOfTurnoverOfMansWithVAT AS AmountOfTurnoverOfMansWithVAT,
	|	TT_SalesPurchases.AmountOfTurnoverOfLocalWithVAT AS AmountOfTurnoverOfLocalWithVAT,
	|	TT_SalesPurchases.AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	TT_SalesPurchases.ManSTurnoverAmountExcludingVAT AS ManSTurnoverAmountExcludingVAT,
	|	TT_SalesPurchases.AmountOfTurnoverIsLocalWithoutVAT AS AmountOfTurnoverIsLocalWithoutVAT,
	|	TT_SalesPurchases.AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	&ExpressionBasePrice AS BasePrice,
	|	&ExpressionBonusPercentage AS BonusPercent,
	|	&ExpressionStartDate AS StartDate,
	|	&ExpressionEndDate AS EndDate
	|INTO TT_DiscountPercentage
	|FROM
	|	&TablesSources AS TT_SalesPurchases
	|WHERE
	|	&ConditionOfSelectionOfGoods
	|	AND &SelectionConditionsForAgreements
	|	AND &ConvolutionFieldCondition
	|
	|INDEX BY 1";
	
	If RebateConditionsParameters.Goods = Enums.RebatesLists.Selected_ Then
		
		TablesSources =
		"TT_SalesPurchases AS TT_SalesPurchases
		|		LEFT JOIN TT_Goods AS VT_ItemsWithCharacteristics
		|		ON TT_SalesPurchases.Products = VT_ItemsWithCharacteristics.Products
		|			AND TT_SalesPurchases.Characteristic = VT_ItemsWithCharacteristics.Characteristic
		|			AND (TT_SalesPurchases.Period BETWEEN VT_ItemsWithCharacteristics.StartDate AND VT_ItemsWithCharacteristics.EndDate)
		|			AND VT_ItemsWithCharacteristics.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|			AND &ConditionForConnectingItemsWithCharacteristicsByRanges
		|			AND &ConditionForConnectingItemsWithCharacteristicsByProperties
		|		LEFT JOIN TT_Goods AS VT_ItemsWithoutCharacteristics
		|		ON TT_SalesPurchases.Products = VT_ItemsWithoutCharacteristics.Products
		|			AND (TT_SalesPurchases.Period BETWEEN VT_ItemsWithoutCharacteristics.StartDate AND VT_ItemsWithoutCharacteristics.EndDate)
		|			AND &ConnectionConditionForItemsWithoutCharacteristicsByRanges
		|			AND VT_ItemsWithoutCharacteristics.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)";
		
		ConditionOfSelectionOfGoods = "((VT_ItemsWithCharacteristics.Products IS NOT NULL)
		|	OR (VT_ItemsWithoutCharacteristics.Products IS NOT NULL))";
		
		If GoodsIndicator = IndicatorsKinds.Count Then
			
			// For the CPP, the amount percentage of the bonus on the goods is determined further in the VT-Prepared planeddetermination
			ExpressionBasePrice = "0";
			ExpressionBonusPercentage = "0";
			ExpressionNumberPlan = "0";
			
			If RebateConditionsParameters.CalculationScaleByRanges Then
				
				ConditionForConnectingItemsWithCharacteristicsByRanges = "VT_ItemsWithCharacteristics.CountPlan = 0";
				ConnectionConditionForItemsWithoutCharacteristicsByRanges = "VT_ItemsWithoutCharacteristics.CountPlan = 0";
				
			Else
				
				ConditionForConnectingItemsWithCharacteristicsByRanges = "TRUE";
				ConnectionConditionForItemsWithoutCharacteristicsByRanges = "TRUE";
				
			EndIf;
			
		Else
			
			ExpressionBasePrice = "ISNULL(VT_ItemsWithCharacteristics.BasePrice, VT_ItemsWithoutCharacteristics.BasePrice)";
			
			ExpressionBonusPercentage =
			"CASE
			|	WHEN ISNULL(VT_ItemsWithCharacteristics.BonusPercent, VT_ItemsWithoutCharacteristics.BonusPercent) <> 0
			|		THEN ISNULL(VT_ItemsWithCharacteristics.BonusPercent, VT_ItemsWithoutCharacteristics.BonusPercent)
			|	ELSE TT_SalesPurchases.BonusPercent
			|END";
			
			ExpressionNumberPlan =
				"ISNULL(VT_ItemsWithCharacteristics.CountPlan, VT_ItemsWithoutCharacteristics.CountPlan)";
			
			ConditionForConnectingItemsWithCharacteristicsByRanges = "TRUE";
			ConnectionConditionForItemsWithoutCharacteristicsByRanges = "TRUE";
			
		EndIf;
		
		ExpressionStartDate = "ISNULL(VT_ItemsWithCharacteristics.StartDate, VT_ItemsWithoutCharacteristics.StartDate)";
		ExpressionEndDate = "ISNULL(VT_ItemsWithCharacteristics.EndDate, VT_ItemsWithoutCharacteristics.EndDate)";
		
		If RebateConditionsParameters.CalculationByProperties Then
			
			ExpressionCharacteristicsAreUsed = "FALSE";
			ExpressionCharacteristicOfCalculation = "TT_SalesPurchases.Characteristic";
			ConditionForConnectingItemsWithCharacteristicsByProperties = "FALSE";
			
		Else
			
			ExpressionCharacteristicsAreUsed =
				"ISNULL(VT_ItemsWithCharacteristics.ItemVariantsAreUsed, VT_ItemsWithoutCharacteristics.ItemVariantsAreUsed)";
			
			ExpressionCharacteristicOfCalculation =
				"CAST(ISNULL(VT_ItemsWithCharacteristics.Characteristic,
				|	VT_ItemsWithoutCharacteristics.Characteristic) AS Catalog.ItemsCharacteristics)";
			
			ConditionForConnectingItemsWithCharacteristicsByProperties = "TRUE";
			
		EndIf;
		
		PropertyValueExpression = StrTemplate("ISNULL(VT_ItemsWithoutCharacteristics.PropertyValue, %1)", EmptyPropertyValue);
		
	ElsIf RebateConditionsParameters.Goods = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		TablesSources =
		"TT_SalesPurchases AS TT_SalesPurchases
		|		LEFT JOIN TT_Goods AS VT_ItemsWithCharacteristics
		|		ON TT_SalesPurchases.Products = VT_ItemsWithCharacteristics.Products
		|			AND TT_SalesPurchases.Characteristic = VT_ItemsWithCharacteristics.Characteristic
		|			AND (TT_SalesPurchases.Period BETWEEN VT_ItemsWithCharacteristics.StartDate AND VT_ItemsWithCharacteristics.EndDate)
		|			AND &ConditionForConnectingItemsWithCharacteristicsByRanges
		|			AND &ConditionForConnectingItemsWithCharacteristicsByProperties
		|			AND VT_ItemsWithCharacteristics.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		LEFT JOIN TT_Goods AS VT_ItemsWithoutCharacteristics
		|		ON TT_SalesPurchases.Products = VT_ItemsWithoutCharacteristics.Products
		|			AND (TT_SalesPurchases.Period BETWEEN VT_ItemsWithoutCharacteristics.StartDate AND VT_ItemsWithoutCharacteristics.EndDate)
		|			AND &ConnectionConditionForItemsWithoutCharacteristicsByRanges
		|			AND VT_ItemsWithCharacteristics.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)";
		
		ConditionOfSelectionOfGoods = "VT_ItemsWithCharacteristics.Products IS NULL
		|	AND VT_ItemsWithoutCharacteristics.Products IS NULL";
		
		ExpressionBasePrice = "0";
		ExpressionBonusPercentage = "TT_SalesPurchases.BonusPercent";
		ExpressionStartDate = "TT_SalesPurchases.Period";
		ExpressionEndDate = "TT_SalesPurchases.Period";
		ExpressionNumberPlan = "0";
		ExpressionCharacteristicsAreUsed = "FALSE";
		ExpressionCharacteristicOfCalculation = "TT_SalesPurchases.Characteristic";
		PropertyValueExpression = StrTemplate("ISNULL(VT_ItemsWithoutCharacteristics.PropertyValue, %1)", EmptyPropertyValue);
		
		If GoodsIndicator = IndicatorsKinds.Count
		   And RebateConditionsParameters.CalculationScaleByRanges Then
			
			ConditionForConnectingItemsWithCharacteristicsByRanges = "VT_ItemsWithCharacteristics.CountPlan = 0";
			ConnectionConditionForItemsWithoutCharacteristicsByRanges = "VT_ItemsWithoutCharacteristics.CountPlan = 0";
			
		Else
			
			ConditionForConnectingItemsWithCharacteristicsByRanges = "TRUE";
			ConnectionConditionForItemsWithoutCharacteristicsByRanges = "TRUE";
			
		EndIf;
		
		If RebateConditionsParameters.CalculationByProperties Then
			ConditionForConnectingItemsWithCharacteristicsByProperties = "FALSE";
		Else
			ConditionForConnectingItemsWithCharacteristicsByProperties = "TRUE";
		EndIf;
		
	Else
		
		TablesSources = "TT_SalesPurchases AS TT_SalesPurchases";
		ConditionOfSelectionOfGoods = "TT_SalesPurchases.SelectionOfGoodsWithoutRestrictions";
		ExpressionBasePrice = "0";
		ExpressionBonusPercentage = "TT_SalesPurchases.BonusPercent";
		ExpressionStartDate = "TT_SalesPurchases.Period";
		ExpressionEndDate = "TT_SalesPurchases.Period";
		ExpressionNumberPlan = "0";
		ExpressionCharacteristicsAreUsed = "FALSE";
		ExpressionCharacteristicOfCalculation = "TT_SalesPurchases.Characteristic";
		PropertyValueExpression = "UNDEFINED";
		ConditionForConnectingItemsWithCharacteristicsByRanges = "TRUE";
		ConnectionConditionForItemsWithoutCharacteristicsByRanges = "TRUE";
		ConditionForConnectingItemsWithCharacteristicsByProperties = "TRUE";
		
	EndIf;
	
	If GoodsIndicator = IndicatorsKinds.NotUsed Then
		
		ExpressionOfTimeFenceOfConditions = "VALUE(Enum.RebatesFrequencies.EmptyRef)";
		ExpressionProhibitionOfAccrualInExcessOfPlan = "FALSE";
		ExpressionSumPlan = "0";
		ExpressionFIFODistribution = "TRUE";
		
	Else
		
		ExpressionOfTimeFenceOfConditions = "TT_SalesPurchases.ConditionFrequency";
		ExpressionProhibitionOfAccrualInExcessOfPlan = "TT_SalesPurchases.RestrictAccrualOverPlan";
		ExpressionSumPlan = "TT_SalesPurchases.SumPlan";
		ExpressionFIFODistribution = "TT_SalesPurchases.FIFODistribution";
		
	EndIf;
	
	If GoodsIndicator = IndicatorsKinds.Count Then
		
		// For CPP, the quantity may be several product lines with a different plan and percentage (progressive scale)
		QueryText = StrReplace(QueryText, "SELECT", "SELECT DISTINCT"); // @query-part-1, @query-part-2
		
	EndIf;
	
	// to prevent the removal of convolution fields from the previous table
	ConvolutionFieldCondition = "TT_SalesPurchases.Products IS NOT NULL
	|	AND TT_SalesPurchases.Characteristic IS NOT NULL";
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		SelectionConditionsForAgreements =
		"TT_SalesPurchases.Terms IN
		|	(SELECT
		|		TT_Terms1.Terms
		|	FROM
		|		TT_Terms1 AS TT_Terms1)";
		
	Else
		
		SelectionConditionsForAgreements = "TRUE";
		
	EndIf;
	
	NeedIndexesForCPUSum = (GoodsIndicator = IndicatorsKinds.Sum
		And (RebateConditionsParameters.RestrictAccrualOverPlan
			Or RebateConditionsParameters.CalculationScaleByRanges)
		And Not RebateConditionsParameters.ProportionalDistribution);
	
	If GoodsIndicator = IndicatorsKinds.NotUsed
	 Or Not NeedIndexesForCPUSum Then
		
		IndexingFields = "";
	
	Else
		
		IndexingFields =
			"INDEX BY
			|	DocumentRecorder,
			|	LineNumber";
		
	EndIf;
	
	SubstituteExpressionCalculationCurrency(RebateConditionsParameters, QueryText, "TT_SalesPurchases");
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	   And Not RebateConditionsParameters.CalculationInBasePrices Then
		
		ExpressionTurnover = "&ExpressionAmountWithoutSpecification";
		SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, ExpressionTurnover, "TT_SalesPurchases");
		
	Else
		
		ExpressionTurnover = "TT_SalesPurchases.Count";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TablesSources AS TT_SalesPurchases", TablesSources);
	QueryText = StrReplace(QueryText, "&ConditionOfSelectionOfGoods", ConditionOfSelectionOfGoods);
	QueryText = StrReplace(QueryText, "&ExpressionBasePrice", ExpressionBasePrice);
	QueryText = StrReplace(QueryText, "&ExpressionBonusPercentage", ExpressionBonusPercentage);
	QueryText = StrReplace(QueryText, "&ExpressionStartDate", ExpressionStartDate);
	QueryText = StrReplace(QueryText, "&ExpressionEndDate", ExpressionEndDate);
	QueryText = StrReplace(QueryText, "&ExpressionOfTimeFenceOfConditions", ExpressionOfTimeFenceOfConditions);
	QueryText = StrReplace(QueryText, "&ExpressionProhibitionOfAccrualInExcessOfPlan", ExpressionProhibitionOfAccrualInExcessOfPlan);
	QueryText = StrReplace(QueryText, "&ExpressionSumPlan", ExpressionSumPlan);
	QueryText = StrReplace(QueryText, "&ExpressionFIFODistribution", ExpressionFIFODistribution);
	QueryText = StrReplace(QueryText, "&ExpressionNumberPlan", ExpressionNumberPlan);
	QueryText = StrReplace(QueryText, "&ExpressionCharacteristicsAreUsed", ExpressionCharacteristicsAreUsed);
	QueryText = StrReplace(QueryText, "&ExpressionCharacteristicOfCalculation", ExpressionCharacteristicOfCalculation);
	QueryText = StrReplace(QueryText, "&PropertyValueExpression", PropertyValueExpression);
	QueryText = StrReplace(QueryText, "&ExpressionTurnover", ExpressionTurnover);
	QueryText = StrReplace(QueryText, "&SelectionConditionsForAgreements", SelectionConditionsForAgreements);
	QueryText = StrReplace(QueryText, "&ConvolutionFieldCondition", ConvolutionFieldCondition);
	QueryText = StrReplace(
		QueryText,
		"&ConditionForConnectingItemsWithCharacteristicsByRanges",
		ConditionForConnectingItemsWithCharacteristicsByRanges);
	QueryText = StrReplace(
		QueryText,
		"&ConnectionConditionForItemsWithoutCharacteristicsByRanges",
		ConnectionConditionForItemsWithoutCharacteristicsByRanges);
	QueryText = StrReplace(
		QueryText,
		"&ConditionForConnectingItemsWithCharacteristicsByProperties",
		ConditionForConnectingItemsWithCharacteristicsByProperties);
	QueryText = StrReplace(QueryText, "INDEX BY 1", IndexingFields);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextParticipantsPeriodsDocuments(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT DISTINCT
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.GoodsIndicator AS GoodsIndicator,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency AS AccrualFrequency,
	|	TT_DiscountPercentage.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_DiscountPercentage.FIFODistribution AS FIFODistribution,
	|	TT_DiscountPercentage.SumPlan AS SumPlan,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	&MemberFields,
	|	TT_DiscountPercentage.Contract AS Contract,
	|	TT_DiscountPercentage.Terms AS Terms,
	|	TT_DiscountPercentage.BaseOfCalculation AS BaseOfCalculation,
	|	TT_DiscountPercentage.Currency AS Currency
	|INTO VT_ParticipantsPeriodsDocuments
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextParticipantsPeriodsDocumentsAllGoods(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_ParticipantsPeriodsDocuments.CalculationPeriod AS CalculationPeriod,
	|	VT_ParticipantsPeriodsDocuments.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_ParticipantsPeriodsDocuments.GoodsIndicator AS GoodsIndicator,
	|	VT_ParticipantsPeriodsDocuments.PartyCountDetails AS PartyCountDetails,
	|	VT_ParticipantsPeriodsDocuments.AccrualFrequency AS AccrualFrequency,
	|	VT_ParticipantsPeriodsDocuments.ConditionFrequency AS ConditionFrequency,
	|	VT_ParticipantsPeriodsDocuments.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_ParticipantsPeriodsDocuments.FIFODistribution AS FIFODistribution,
	|	VT_ParticipantsPeriodsDocuments.SumPlan AS SumPlan,
	|	VT_ParticipantsPeriodsDocuments.Organization AS Organization,
	|	&MemberFields,
	|	VT_ParticipantsPeriodsDocuments.BaseOfCalculation AS BaseOfCalculation,
	|	VT_ParticipantsPeriodsDocuments.Currency AS Currency,
	|	&ProductFields,
	|	ISNULL(TT_Goods.ItemVariantsAreUsed, TRUE) AS ItemVariantsAreUsed,
	|	ISNULL(TT_Goods.BasePrice, 0) AS BasePrice,
	|	ISNULL(TT_Goods.BonusPercent, 0) AS BonusPercent,
	|	ISNULL(TT_Goods.CountPlan, 0) AS CountPlan
	|INTO VT_ParticipantsPeriodsDocumentsAllGoods
	|FROM
	|	VT_ParticipantsPeriodsDocuments AS VT_ParticipantsPeriodsDocuments
	|	LEFT JOIN TT_Goods AS TT_Goods
	|		ON TRUE";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_ParticipantsPeriodsDocuments");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_Goods");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextParticipantsPeriodsDocumentsGoodsSold(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT DISTINCT
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.GoodsIndicator AS GoodsIndicator,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency AS AccrualFrequency,
	|	TT_DiscountPercentage.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_DiscountPercentage.FIFODistribution AS FIFODistribution,
	|	TT_DiscountPercentage.SumPlan AS SumPlan,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	&MemberFields,
	|	TT_DiscountPercentage.BaseOfCalculation AS BaseOfCalculation,
	|	TT_DiscountPercentage.Currency AS Currency,
	|	&ProductFields
	|INTO VT_ParticipantsPeriodsDocumentsGoodsSold
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextMissingPackageContents(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_ParticipantsPeriodsDocumentsAllGoods.CalculationPeriod AS CalculationPeriod,
	|	&EmptyRegistrarLink AS DocumentRecorder,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.GoodsIndicator AS GoodsIndicator,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.PartyCountDetails AS PartyCountDetails,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.AccrualFrequency AS AccrualFrequency,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.ConditionFrequency AS ConditionFrequency,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.FIFODistribution AS FIFODistribution,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.SumPlan AS SumPlan,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.Organization AS Organization,
	|	&MemberFields,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.BaseOfCalculation AS BaseOfCalculation,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.Currency AS Currency,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	&ProductFields,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.BasePrice AS BasePrice,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.BonusPercent AS BonusPercent,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.CountPlan AS CountPlan
	|INTO VT_MissingPackageContents
	|FROM
	|	VT_ParticipantsPeriodsDocumentsAllGoods AS VT_ParticipantsPeriodsDocumentsAllGoods
	|	LEFT JOIN VT_ParticipantsPeriodsDocumentsGoodsSold AS VT_ParticipantsPeriodsDocumentsGoodsSold
	|	ON VT_ParticipantsPeriodsDocumentsAllGoods.ConditionOfRebateBonusIs = VT_ParticipantsPeriodsDocumentsGoodsSold.ConditionOfRebateBonusIs
	|		AND VT_ParticipantsPeriodsDocumentsAllGoods.Organization = VT_ParticipantsPeriodsDocumentsGoodsSold.Organization
	|		AND VT_ParticipantsPeriodsDocumentsAllGoods.Currency = VT_ParticipantsPeriodsDocumentsGoodsSold.Currency
	|		AND &ConnectionFieldsByParticipants
	|		AND &ConnectionFieldsByGoods
	|		AND VT_ParticipantsPeriodsDocumentsAllGoods.CalculationPeriod = VT_ParticipantsPeriodsDocumentsGoodsSold.CalculationPeriod
	|WHERE
	|	&ConditionItemIsNotSold";
	
	EmptyRegistrarLink = ValueOfEmptyLoggerReference(RebateConditionsParameters);
	QueryText = StrReplace(QueryText, "&EmptyRegistrarLink", EmptyRegistrarLink);
	
	If RebateConditionsParameters.CalculationByProperties Then
		ConditionItemIsNotSold = "VT_ParticipantsPeriodsDocumentsGoodsSold.PropertyValue IS NULL";
	Else
		ConditionItemIsNotSold = "VT_ParticipantsPeriodsDocumentsGoodsSold.Products IS NULL";
	EndIf;
	QueryText = StrReplace(QueryText, "&ConditionItemIsNotSold", ConditionItemIsNotSold);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		QueryText,
		"VT_ParticipantsPeriodsDocumentsAllGoods",
		"VT_ParticipantsPeriodsDocumentsGoodsSold");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		QueryText,
		"VT_ParticipantsPeriodsDocumentsAllGoods",
		"VT_ParticipantsPeriodsDocumentsGoodsSold");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDiscountPercentageWithPackageData(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SubqueryTexts_ = New Array; // Array of String
	
	SubqueryText =
	"SELECT
	|	TT_DiscountPercentage.Period AS Period,
	|	TT_DiscountPercentage.LineNumber AS LineNumber,
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.GoodsIndicator AS GoodsIndicator,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency AS AccrualFrequency,
	|	TT_DiscountPercentage.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_DiscountPercentage.FIFODistribution AS FIFODistribution,
	|	TT_DiscountPercentage.SumPlan AS SumPlan,
	|	TT_DiscountPercentage.DocumentRecorder AS DocumentRecorder,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	&MemberFields,
	|	TT_DiscountPercentage.Contract AS Contract,
	|	TT_DiscountPercentage.Terms AS Terms,
	|	TT_DiscountPercentage.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_DiscountPercentage.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_DiscountPercentage.Products AS Products,
	|	TT_DiscountPercentage.UnitOfMeasure AS UnitOfMeasure,
	|	TT_DiscountPercentage.Characteristic AS Characteristic,
	|	TT_DiscountPercentage.PropertyValue AS PropertyValue,
	|	TT_DiscountPercentage.Count AS Count,
	|	TT_DiscountPercentage.BaseOfCalculation AS BaseOfCalculation,
	|	TT_DiscountPercentage.Currency AS Currency,
	|	TT_DiscountPercentage.Sum AS Sum,
	|	TT_DiscountPercentage.SumCompl AS SumCompl,
	|	TT_DiscountPercentage.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	TT_DiscountPercentage.AmountOfTurnoverOfMansWithVAT AS AmountOfTurnoverOfMansWithVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverOfLocalWithVAT AS AmountOfTurnoverOfLocalWithVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	TT_DiscountPercentage.ManSTurnoverAmountExcludingVAT AS ManSTurnoverAmountExcludingVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverIsLocalWithoutVAT AS AmountOfTurnoverIsLocalWithoutVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	TT_DiscountPercentage.BasePrice AS BasePrice,
	|	TT_DiscountPercentage.BonusPercent AS BonusPercent,
	|	TT_DiscountPercentage.StartDate AS StartDate,
	|	TT_DiscountPercentage.EndDate AS EndDate,
	|	TT_DiscountPercentage.CountPlan AS CountPlan
	|INTO VT_DiscountPercentageWithPackageData
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, SubqueryText, "TT_DiscountPercentage");
	SubqueryTexts_.Add(SubqueryText);
	
	SubqueryText =
	"SELECT
	|	VT_MissingPackageContents.CalculationPeriod AS Period,
	|	0 AS LineNumber,
	|	VT_MissingPackageContents.CalculationPeriod AS CalculationPeriod,
	|	VT_MissingPackageContents.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_MissingPackageContents.GoodsIndicator AS GoodsIndicator,
	|	VT_MissingPackageContents.PartyCountDetails AS PartyCountDetails,
	|	VT_MissingPackageContents.AccrualFrequency AS AccrualFrequency,
	|	VT_MissingPackageContents.ConditionFrequency AS ConditionFrequency,
	|	VT_MissingPackageContents.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_MissingPackageContents.FIFODistribution AS FIFODistribution,
	|	VT_MissingPackageContents.SumPlan AS SumPlan,
	|	VT_MissingPackageContents.DocumentRecorder AS DocumentRecorder,
	|	VT_MissingPackageContents.Organization AS Organization,
	|	&MemberFields,
	|	VT_MissingPackageContents.Contract AS Contract,
	|	VT_MissingPackageContents.Terms AS Terms,
	|	VT_MissingPackageContents.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	&ExpressionCharacteristic AS CharacteristicsOfSalesPurchases,
	|	&ExpressionProducts AS Products,
	|	&ExpressionUnit AS UnitOfMeasure,
	|	&ExpressionCharacteristic AS Characteristic,
	|	&PropertyValueExpression AS PropertyValue,
	|	0 AS Count,
	|	VT_MissingPackageContents.BaseOfCalculation AS BaseOfCalculation,
	|	VT_MissingPackageContents.Currency AS Currency,
	|	0 AS Sum,
	|	0 AS SumCompl,
	|	0 AS AmountInARAPCurrency,
	|	0 AS AmountOfTurnoverOfMansWithVAT,
	|	0 AS AmountOfTurnoverOfLocalWithVAT,
	|	0 AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	0 AS ManSTurnoverAmountExcludingVAT,
	|	0 AS AmountOfTurnoverIsLocalWithoutVAT,
	|	0 AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	VT_MissingPackageContents.BasePrice AS BasePrice,
	|	VT_MissingPackageContents.BonusPercent AS BonusPercent,
	|	VT_MissingPackageContents.CalculationPeriod AS StartDate,
	|	VT_MissingPackageContents.CalculationPeriod AS EndDate,
	|	VT_MissingPackageContents.CountPlan AS CountPlan
	|FROM
	|	VT_MissingPackageContents AS VT_MissingPackageContents";
	
	If RebateConditionsParameters.CalculationByProperties Then
		
		ExpressionProducts = "VALUE(Catalog.Products.EmptyRef)";
		ExpressionUnit = "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)";
		ExpressionCharacteristic = "VALUE(Catalog.ItemsCharacteristics.EmptyRef)";
		PropertyValueExpression = "VT_MissingPackageContents.PropertyValue";
		
	Else
		
		ExpressionProducts = "VT_MissingPackageContents.Products";
		ExpressionUnit = "CAST(VT_MissingPackageContents.Products AS Catalog.Products).UnitOfMeasure";
		ExpressionCharacteristic = "VT_MissingPackageContents.Characteristic";
		PropertyValueExpression = "UNDEFINED";
		
	EndIf;
	
	SubqueryText = StrReplace(SubqueryText, "&ExpressionProducts", ExpressionProducts);
	SubqueryText = StrReplace(SubqueryText, "&ExpressionUnit", ExpressionUnit);
	SubqueryText = StrReplace(SubqueryText, "&ExpressionCharacteristic", ExpressionCharacteristic);
	SubqueryText = StrReplace(SubqueryText, "&PropertyValueExpression", PropertyValueExpression);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, SubqueryText, "VT_MissingPackageContents");
	SubqueryTexts_.Add(SubqueryText);
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextMultiplicityOfGoodsPackage(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_DiscountPercentageWithPackageData.CalculationPeriod AS CalculationPeriod,
	|	VT_DiscountPercentageWithPackageData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DiscountPercentageWithPackageData.Organization AS Organization,
	|	VT_DiscountPercentageWithPackageData.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_DiscountPercentageWithPackageData.CountPlan AS CountPlan,
	|	SUM(VT_DiscountPercentageWithPackageData.Count) AS Count
	|INTO VT_MultiplicityOfPackageOfGoods
	|FROM
	|	VT_DiscountPercentageWithPackageData AS VT_DiscountPercentageWithPackageData
	|
	|GROUP BY
	|	VT_DiscountPercentageWithPackageData.CalculationPeriod,
	|	VT_DiscountPercentageWithPackageData.ConditionOfRebateBonusIs,
	|	VT_DiscountPercentageWithPackageData.Organization,
	|	VT_DiscountPercentageWithPackageData.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	VT_DiscountPercentageWithPackageData.CountPlan";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextNumberOfGoodsPackages(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	// The conditions on the product fields are necessary to prevent their removal by the DCS optimizer from the previous TT
	
	QueryText =
	"SELECT
	|	VT_MultiplicityOfPackageOfGoods.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_MultiplicityOfPackageOfGoods.CalculationPeriod AS CalculationPeriod,
	|	VT_MultiplicityOfPackageOfGoods.Organization AS Organization,
	|	VT_MultiplicityOfPackageOfGoods.Currency AS Currency,
	|	&MemberFields,
	|	MIN(CASE
	|		WHEN VT_MultiplicityOfPackageOfGoods.Count <= 0
	|			THEN 0
	|		WHEN VT_MultiplicityOfPackageOfGoods.CountPlan = 0
	|			THEN VT_MultiplicityOfPackageOfGoods.Count
	|		ELSE CAST(VT_MultiplicityOfPackageOfGoods.Count / VT_MultiplicityOfPackageOfGoods.CountPlan
	|			- 0.5 AS NUMBER(15, 0))
	|	END) AS NumberOfPackages_
	|INTO VT_NumberOfProductPackages
	|FROM
	|	VT_MultiplicityOfPackageOfGoods AS VT_MultiplicityOfPackageOfGoods
	|WHERE
	|	&ConditionForItemFields
	|
	|GROUP BY
	|	VT_MultiplicityOfPackageOfGoods.ConditionOfRebateBonusIs,
	|	VT_MultiplicityOfPackageOfGoods.CalculationPeriod,
	|	VT_MultiplicityOfPackageOfGoods.Organization,
	|	VT_MultiplicityOfPackageOfGoods.Currency,
	|	&GroupingFieldsByParticipants";
	
	If RebateConditionsParameters.CalculationByProperties Then
		
		ConditionForItemFields = "VT_MultiplicityOfPackageOfGoods.PropertyValue IS NOT NULL";
		
	Else
		
		ConditionForItemFields =
		"VT_MultiplicityOfPackageOfGoods.Products IS NOT NULL
		|	AND VT_MultiplicityOfPackageOfGoods.Characteristic IS NOT NULL";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionForItemFields", ConditionForItemFields);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_MultiplicityOfPackageOfGoods");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	//@skip-check bsl-ql-hub - the indexing fields are refined by replacing the query text
	QueryText =
	"SELECT TOP 1000000000
	|	TT_DiscountPercentage.Period AS Period,
	|	TT_DiscountPercentage.LineNumber AS LineNumber,
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	TT_DiscountPercentage.Currency AS Currency,
	|	&MemberFields,
	|	TT_DiscountPercentage.Contract AS Contract,
	|	TT_DiscountPercentage.Terms AS Terms,
	|	TT_DiscountPercentage.DocumentRecorder AS DocumentRecorder,
	|	TT_DiscountPercentage.Products AS Products,
	|	TT_DiscountPercentage.Characteristic AS Characteristic,
	|	TT_DiscountPercentage.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.SumPlan AS SumPlan,
	|	RECORDAUTONUMBER() AS Priority,
	|	TT_DiscountPercentage.Count AS Count,
	|	&ExpressionAmountWithoutSpecification AS Sum
	|INTO VT_ExceedingLimitTotal
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage
	|
	|ORDER BY
	|	&ExpressionOfOrderingField
	|
	|INDEX BY CalculationPeriod";
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	   And RebateConditionsParameters.RestrictAccrualOverPlan
	   And RebateConditionsParameters.ProportionalDistribution Then
		
		IndexingFields = "";
		
	Else
		
		IndexingFields = "INDEX BY
		|	CalculationPeriod,
		|	ConditionOfRebateBonusIs,
		|	Organization,
		|	&IndexingFieldsByParticipants,
		|	LineNumber,
		|	Products,
		|	Characteristic,
		|	Currency";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "INDEX BY CalculationPeriod", IndexingFields);
	
	OrderFields = OrderingFieldsByChronology(RebateConditionsParameters, "TT_DiscountPercentage");
	ExpressionOfOrderingField = StrConcat(OrderFields, "," + Chars.LF);
	QueryText = StrReplace(QueryText, "&ExpressionOfOrderingField", ExpressionOfOrderingField);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPortions(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	//@skip-check bsl-ql-hub - The grouping and indexing fields are refined by replacing the query text
	QueryText =
	"SELECT
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	CAST(SourceTable1.Priority / &PortionOfCumulativeTotal - 0.5 AS NUMBER(15, 0))
	|		* &PortionOfCumulativeTotal AS PriorityPortion,
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.Organization AS Organization,
	|	SourceTable1.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.SumPlan AS SumPlan,
	|	&ExpressionNumberPlan AS CountPlan,
	|	0 AS QuantityPerServing,
	|	0 AS AmountBeforeServing,
	|	SUM(SourceTable1.Count) AS Count,
	|	SUM(SourceTable1.CalculationBase) AS Sum,
	|	SUM(
	|		CASE
	|			WHEN SourceTable1.CalculationBase > 0
	|				THEN SourceTable1.CalculationBase
	|			ELSE 0
	|		END) AS SumReceipt,
	|	SUM(
	|		CASE
	|			WHEN SourceTable1.Count > 0
	|				THEN SourceTable1.Count
	|			ELSE 0
	|		END) AS CountReceipt
	|INTO VT_TurnoverByPortions
	|FROM
	|	TT_PreparedData AS SourceTable1
	|WHERE
	|	&Expression_Condition
	|
	|GROUP BY
	|	SourceTable1.CalculationPeriod,
	|	CAST(SourceTable1.Priority / &PortionOfCumulativeTotal - 0.5 AS NUMBER(15, 0)) * &PortionOfCumulativeTotal,
	|	SourceTable1.ConditionOfRebateBonusIs,
	|	SourceTable1.Organization,
	|	SourceTable1.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	SourceTable1.SumPlan,
	|	&ExpressionNumberPlan";
	
	If RebateConditionsParameters.GoodsIndicator = SalesFigures.Sum Then
		
		Expression_Condition = "(SourceTable1.VerificationAmount >= SourceTable1.SumPlan)";
		
	ElsIf RebateConditionsParameters.GoodsIndicator = SalesFigures.BatchOffer Then
		
		Expression_Condition = "(SourceTable1.NumberOfPackages_ > 0)";
		
	Else
		
		Expression_Condition = "(SourceTable1.CountOfChecks >= SourceTable1.CountPlan)";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&Expression_Condition", Expression_Condition);
	
	If RebateConditionsParameters.GoodsIndicator = SalesFigures.BatchOffer Then
		
		ExpressionNumberPlan = "SourceTable1.NumberOfPackages_ * SourceTable1.CountPlan";
		
	Else
		
		ExpressionNumberPlan = "SourceTable1.CountPlan";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&ExpressionNumberPlan", ExpressionNumberPlan);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueryText = StrReplace(QueryText, "&PortionOfCumulativeTotal", PortionOfCumulativeTotal());
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//  SourceTable1 - String
//  AssignmentTable - String
//  FirstPass - Boolean
//
Procedure AddQueryTextTurnoverByPortionsCumulativeTotal(RebateConditionsParameters, OptionParameters, QueriesTexts, SourceTable1, AssignmentTable, FirstPass = False) Export
	
	QueryText =
	"SELECT
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	SourceTable1.PriorityPortion AS PriorityPortion,
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.Organization AS Organization,
	|	SourceTable1.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.SumPlan AS SumPlan,
	|	SourceTable1.CountPlan AS CountPlan,
	|	SourceTable1.QuantityPerServing AS QuantityPerServing,
	|	SourceTable1.AmountBeforeServing AS AmountBeforeServing,
	|	SourceTable1.SumReceipt AS SumReceipt,
	|	SourceTable1.Sum AS PortionAmount,
	|	SourceTable1.CountReceipt AS CountReceipt,
	|	SourceTable1.Count AS ServingQuantity,
	|	SUM(TableSourceMirror.Count) AS Count,
	|	SUM(TableSourceMirror.Sum) AS Sum
	|INTO TT_AssignmentTable
	|FROM
	|	&SourceTable1 AS SourceTable1
	|		INNER JOIN &SourceTable1 AS TableSourceMirror
	|		ON SourceTable1.PriorityPortion >= TableSourceMirror.PriorityPortion
	|			AND &ParentPortionCondition
	|			AND SourceTable1.CalculationPeriod = TableSourceMirror.CalculationPeriod
	|			AND SourceTable1.ConditionOfRebateBonusIs = TableSourceMirror.ConditionOfRebateBonusIs
	|			AND SourceTable1.Organization = TableSourceMirror.Organization
	|			AND SourceTable1.Currency = TableSourceMirror.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|
	|GROUP BY
	|	SourceTable1.CalculationPeriod,
	|	SourceTable1.PriorityPortion,
	|	SourceTable1.ConditionOfRebateBonusIs,
	|	SourceTable1.Organization,
	|	SourceTable1.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	SourceTable1.SumPlan,
	|	SourceTable1.CountPlan,
	|	SourceTable1.QuantityPerServing,
	|	SourceTable1.Sum,
	|	SourceTable1.SumReceipt,
	|	SourceTable1.AmountBeforeServing,
	|	SourceTable1.CountReceipt,
	|	SourceTable1.Count";
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	QueryText = StrReplace(QueryText, "TT_AssignmentTable", AssignmentTable);
	
	If FirstPass Then
		ParentPortionCondition = "TRUE";
	Else
		ParentPortionCondition = "SourceTable1.PriorityIsParentPortion <= TableSourceMirror.PriorityPortion";
	EndIf;
	QueryText = StrReplace(QueryText, "&ParentPortionCondition", ParentPortionCondition);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "SourceTable1", "TableSourceMirror");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "SourceTable1", "TableSourceMirror");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//  SourceTable1 - String
//  AssignmentTable - String
//
Procedure AddQueryTextPortionOfLimitExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts, SourceTable1, AssignmentTable) Export
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If Not RebateConditionsParameters.RestrictAccrualOverPlan
	   And RebateConditionsParameters.GoodsIndicator <> SalesFigures.BatchOffer Then
		Return;
	EndIf;
	
	If Not RebateConditionsParameters.DistributionByFIFO Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	MIN(SourceTable1.PriorityPortion) AS PriorityPortion,
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.Organization AS Organization,
	|	SourceTable1.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.SumPlan AS SumPlan,
	|	SourceTable1.CountPlan AS CountPlan
	|INTO TT_AssignmentTable
	|FROM
	|	&SourceTable1 AS SourceTable1
	|WHERE
	|	&ConditionExceedingPlan
	|
	|GROUP BY
	|	SourceTable1.CalculationPeriod,
	|	SourceTable1.ConditionOfRebateBonusIs,
	|	SourceTable1.Organization,
	|	SourceTable1.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	SourceTable1.SumPlan,
	|	SourceTable1.CountPlan
	|
	|UNION ALL
	|
	|SELECT
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	SourceTable1.PriorityPortion AS PriorityPortion,
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.Organization AS Organization,
	|	SourceTable1.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.SumPlan AS SumPlan,
	|	SourceTable1.CountPlan AS CountPlan
	|FROM
	|	&SourceTable1 AS SourceTable1
	|WHERE
	|	&PortionConditionWithAdjustments";
	
	If RebateConditionsParameters.GoodsIndicator = SalesFigures.Sum Then
		
		ConditionExceedingPlan = "SourceTable1.Sum + SourceTable1.AmountBeforeServing >= SourceTable1.SumPlan";
		PortionConditionWithAdjustments = "SourceTable1.Sum + SourceTable1.AmountBeforeServing < SourceTable1.SumPlan
		|	AND SourceTable1.AmountBeforeServing + SourceTable1.Sum - SourceTable1.PortionAmount + SourceTable1.SumReceipt > SourceTable1.SumPlan";
		
	Else
		
		ConditionExceedingPlan = "SourceTable1.Count + SourceTable1.QuantityPerServing >= SourceTable1.CountPlan";
		PortionConditionWithAdjustments = "SourceTable1.Count + SourceTable1.QuantityPerServing < SourceTable1.CountPlan
		|	AND SourceTable1.QuantityPerServing + SourceTable1.Count - SourceTable1.ServingQuantity + SourceTable1.CountReceipt > SourceTable1.CountPlan";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionExceedingPlan", ConditionExceedingPlan);
	QueryText = StrReplace(QueryText, "&PortionConditionWithAdjustments", PortionConditionWithAdjustments);
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	QueryText = StrReplace(QueryText, "TT_AssignmentTable", AssignmentTable);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//  SourceTable1 - String
//  AssignmentTable - String
//
Procedure AddQueryTextPortionOfExceedingRangeLimit(RebateConditionsParameters, OptionParameters, QueriesTexts, SourceTable1, AssignmentTable) Export
	
	QueryText =
	"SELECT DISTINCT
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	SourceTable1.PriorityPortion AS PriorityPortion,
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.Organization AS Organization,
	|	SourceTable1.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.SumPlan AS SumPlan,
	|	SourceTable1.CountPlan AS CountPlan
	|INTO TT_AssignmentTable
	|FROM
	|	&SourceTable1 AS SourceTable1
	|		INNER JOIN &TableCalculationScale AS TableCalculationScale
	|		ON TableCalculationScale.RangeFrom BETWEEN &ConditionTotalBeforeServing AND &ConditionTotalAfterServing
	|			AND TableCalculationScale.RangeFrom > 0
	|			AND &ConnectionFieldsByGoods";
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		TableCalculationScale = "TT_CalculationScale";
		ConditionTotalBeforeServing = "SourceTable1.AmountBeforeServing + SourceTable1.Sum - SourceTable1.PortionAmount";
		ConditionTotalAfterServing = " SourceTable1.AmountBeforeServing + SourceTable1.Sum";
		
	Else
		
		TableCalculationScale = "TT_GoodsRanges";
		ConditionTotalBeforeServing = "SourceTable1.QuantityPerServing + SourceTable1.Count - SourceTable1.ServingQuantity";
		ConditionTotalAfterServing = " SourceTable1.QuantityPerServing + SourceTable1.Count";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionTotalBeforeServing", ConditionTotalBeforeServing);
	QueryText = StrReplace(QueryText, "&ConditionTotalAfterServing", ConditionTotalAfterServing);
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	QueryText = StrReplace(QueryText, "&TableCalculationScale", TableCalculationScale);
	QueryText = StrReplace(QueryText, "TT_AssignmentTable", AssignmentTable);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1", "TableCalculationScale");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreviousPortionBeforeLimitWasExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_PortionExceedingLimit.CalculationPeriod AS CalculationPeriod,
	|	VT_PortionExceedingLimit.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_PortionExceedingLimit.Organization AS Organization,
	|	VT_PortionExceedingLimit.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_PortionExceedingLimit.PriorityPortion AS PriorityPortion,
	|	VT_PortionExceedingLimit.SumPlan AS SumPlan,
	|	VT_PortionExceedingLimit.CountPlan AS CountPlan,
	|	ISNULL(MAX(VT_TurnoverByPortionsCumulativeTotal.PriorityPortion), -1) AS PriorityPreviousPortion
	|INTO VT_PreviousPortionBeforeLimitWasExceeded
	|FROM
	|	VT_PortionExceedingLimit AS VT_PortionExceedingLimit
	|		LEFT JOIN VT_TurnoverByPortionsCumulativeTotal AS VT_TurnoverByPortionsCumulativeTotal
	|		ON VT_PortionExceedingLimit.CalculationPeriod = VT_TurnoverByPortionsCumulativeTotal.CalculationPeriod
	|			AND VT_PortionExceedingLimit.ConditionOfRebateBonusIs = VT_TurnoverByPortionsCumulativeTotal.ConditionOfRebateBonusIs
	|			AND VT_PortionExceedingLimit.Organization = VT_TurnoverByPortionsCumulativeTotal.Organization
	|			AND VT_PortionExceedingLimit.Currency = VT_TurnoverByPortionsCumulativeTotal.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND VT_PortionExceedingLimit.PriorityPortion > VT_TurnoverByPortionsCumulativeTotal.PriorityPortion
	|
	|GROUP BY
	|	VT_PortionExceedingLimit.CalculationPeriod,
	|	VT_PortionExceedingLimit.ConditionOfRebateBonusIs,
	|	VT_PortionExceedingLimit.Organization,
	|	VT_PortionExceedingLimit.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	VT_PortionExceedingLimit.PriorityPortion,
	|	VT_PortionExceedingLimit.SumPlan,
	|	VT_PortionExceedingLimit.CountPlan";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_PortionExceedingLimit", "VT_TurnoverByPortionsCumulativeTotal");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_PortionExceedingLimit", "VT_TurnoverByPortionsCumulativeTotal");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverUntilLimitIsExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_PreviousPortionBeforeLimitWasExceeded.CalculationPeriod AS CalculationPeriod,
	|	VT_PreviousPortionBeforeLimitWasExceeded.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_PreviousPortionBeforeLimitWasExceeded.Organization AS Organization,
	|	VT_PreviousPortionBeforeLimitWasExceeded.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_PreviousPortionBeforeLimitWasExceeded.PriorityPortion AS PriorityPortion,
	|	VT_PreviousPortionBeforeLimitWasExceeded.SumPlan AS SumPlan,
	|	VT_PreviousPortionBeforeLimitWasExceeded.CountPlan AS CountPlan,
	|	0 AS QuantityBeforeSubportion,
	|	0 AS AmountBeforeSubportion,
	|	ISNULL(VT_TurnoverByPortionsCumulativeTotal.Sum, 0) AS AmountBeforeServing,
	|	ISNULL(VT_TurnoverByPortionsCumulativeTotal.Count, 0) AS QuantityPerServing
	|INTO VT_TurnoverUntilLimitIsExceeded
	|FROM
	|	VT_PreviousPortionBeforeLimitWasExceeded AS VT_PreviousPortionBeforeLimitWasExceeded
	|		LEFT JOIN VT_TurnoverByPortionsCumulativeTotal AS VT_TurnoverByPortionsCumulativeTotal
	|		ON VT_PreviousPortionBeforeLimitWasExceeded.CalculationPeriod = VT_TurnoverByPortionsCumulativeTotal.CalculationPeriod
	|			AND VT_PreviousPortionBeforeLimitWasExceeded.ConditionOfRebateBonusIs = VT_TurnoverByPortionsCumulativeTotal.ConditionOfRebateBonusIs
	|			AND VT_PreviousPortionBeforeLimitWasExceeded.Organization = VT_TurnoverByPortionsCumulativeTotal.Organization
	|			AND VT_PreviousPortionBeforeLimitWasExceeded.Currency = VT_TurnoverByPortionsCumulativeTotal.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND VT_PreviousPortionBeforeLimitWasExceeded.PriorityPreviousPortion = VT_TurnoverByPortionsCumulativeTotal.PriorityPortion";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_PreviousPortionBeforeLimitWasExceeded", "VT_TurnoverByPortionsCumulativeTotal");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_PreviousPortionBeforeLimitWasExceeded", "VT_TurnoverByPortionsCumulativeTotal");
	
	QueryText = StrReplace(QueryText, "&PortionOfCumulativeTotal", PortionOfCumulativeTotal());
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextSubPortionOfExceedingLimitRevolutionsPerServing(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_SubPortionOfExceedingLimit.CalculationPeriod AS CalculationPeriod,
	|	VT_SubPortionOfExceedingLimit.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_SubPortionOfExceedingLimit.Organization AS Organization,
	|	VT_SubPortionOfExceedingLimit.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_SubPortionOfExceedingLimit.PriorityPortion AS PriorityPortion,
	|	CAST((VT_SubPortionOfExceedingLimit.PriorityPortion + 1) / &PortionOfCumulativeTotal - 0.5 AS NUMBER(15, 0))
	|		* &PortionOfCumulativeTotal AS PriorityIsParentPortion,
	|	VT_SubPortionOfExceedingLimit.SumPlan AS SumPlan,
	|	VT_SubPortionOfExceedingLimit.CountPlan AS CountPlan,
	|	ISNULL(VT_TurnoverBySubPortionsCumulativeTotal.AmountBeforeServing, 0) AS AmountBeforeServing,
	|	ISNULL(VT_TurnoverBySubPortionsCumulativeTotal.QuantityPerServing, 0) AS QuantityPerServing
	|INTO VT_SubPortionOfExceedingLimitOfRevolutionsPerServing
	|FROM
	|	VT_SubPortionOfExceedingLimit AS VT_SubPortionOfExceedingLimit
	|		LEFT JOIN VT_TurnoverBySubPortionsCumulativeTotal AS VT_TurnoverBySubPortionsCumulativeTotal
	|		ON VT_SubPortionOfExceedingLimit.CalculationPeriod = VT_TurnoverBySubPortionsCumulativeTotal.CalculationPeriod
	|			AND VT_SubPortionOfExceedingLimit.ConditionOfRebateBonusIs = VT_TurnoverBySubPortionsCumulativeTotal.ConditionOfRebateBonusIs
	|			AND VT_SubPortionOfExceedingLimit.Organization = VT_TurnoverBySubPortionsCumulativeTotal.Organization
	|			AND VT_SubPortionOfExceedingLimit.Currency = VT_TurnoverBySubPortionsCumulativeTotal.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND VT_SubPortionOfExceedingLimit.PriorityPortion = VT_TurnoverBySubPortionsCumulativeTotal.PriorityPortion";
	
	QueryText = StrReplace(QueryText, "&PortionOfCumulativeTotal", PortionOfCumulativeTotal());
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_SubPortionOfExceedingLimit", "VT_TurnoverBySubPortionsCumulativeTotal");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_SubPortionOfExceedingLimit", "VT_TurnoverBySubPortionsCumulativeTotal");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreviousSubPortionBeforeLimitIsExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.CalculationPeriod AS CalculationPeriod,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.Organization AS Organization,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.PriorityPortion AS PriorityPortion,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.SumPlan AS SumPlan,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.CountPlan AS CountPlan,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.AmountBeforeServing AS AmountBeforeServing,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.QuantityPerServing AS QuantityPerServing,
	|	ISNULL(MAX(VT_TurnoverBySubPortionsCumulativeTotal.PriorityPortion), -1) AS PriorityPreviousSubPortion
	|INTO VT_PreviousSubPortionBeforeLimitWasExceeded
	|FROM
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing AS VT_SubPortionOfExceedingLimitOfRevolutionsPerServing
	|		LEFT JOIN VT_TurnoverBySubPortionsCumulativeTotal AS VT_TurnoverBySubPortionsCumulativeTotal
	|		ON VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.CalculationPeriod = VT_TurnoverBySubPortionsCumulativeTotal.CalculationPeriod
	|			AND VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.ConditionOfRebateBonusIs = VT_TurnoverBySubPortionsCumulativeTotal.ConditionOfRebateBonusIs
	|			AND VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.Organization = VT_TurnoverBySubPortionsCumulativeTotal.Organization
	|			AND VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.Currency = VT_TurnoverBySubPortionsCumulativeTotal.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.PriorityPortion > VT_TurnoverBySubPortionsCumulativeTotal.PriorityPortion
	|			AND VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.PriorityIsParentPortion <= VT_TurnoverBySubPortionsCumulativeTotal.PriorityPortion
	|
	|GROUP BY
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.CalculationPeriod,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.ConditionOfRebateBonusIs,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.Organization,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.PriorityPortion,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.SumPlan,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.CountPlan,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.AmountBeforeServing,
	|	VT_SubPortionOfExceedingLimitOfRevolutionsPerServing.QuantityPerServing";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_SubPortionOfExceedingLimitOfRevolutionsPerServing", "VT_TurnoverBySubPortionsCumulativeTotal");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_SubPortionOfExceedingLimitOfRevolutionsPerServing", "VT_TurnoverBySubPortionsCumulativeTotal");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextSubPortionOfExceedingLimitTurnoverToSubPortion(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.CalculationPeriod AS CalculationPeriod,
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.Organization AS Organization,
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.PriorityPortion AS PriorityPortion,
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.SumPlan AS SumPlan,
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.CountPlan AS CountPlan,
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.AmountBeforeServing AS AmountBeforeServing,
	|	VT_PreviousSubPortionBeforeLimitWasExceeded.QuantityPerServing AS QuantityPerServing,
	|	ISNULL(VT_TurnoverBySubPortionsCumulativeTotal.Sum, 0) AS AmountBeforeSubportion,
	|	ISNULL(VT_TurnoverBySubPortionsCumulativeTotal.Count, 0) AS QuantityBeforeSubportion
	|INTO VT_SubPortionOfExceedingLimitRevolutionsToSubPortion
	|FROM
	|	VT_PreviousSubPortionBeforeLimitWasExceeded AS VT_PreviousSubPortionBeforeLimitWasExceeded
	|		LEFT JOIN VT_TurnoverBySubPortionsCumulativeTotal AS VT_TurnoverBySubPortionsCumulativeTotal
	|		ON VT_PreviousSubPortionBeforeLimitWasExceeded.CalculationPeriod = VT_TurnoverBySubPortionsCumulativeTotal.CalculationPeriod
	|			AND VT_PreviousSubPortionBeforeLimitWasExceeded.ConditionOfRebateBonusIs = VT_TurnoverBySubPortionsCumulativeTotal.ConditionOfRebateBonusIs
	|			AND VT_PreviousSubPortionBeforeLimitWasExceeded.Organization = VT_TurnoverBySubPortionsCumulativeTotal.Organization
	|			AND VT_PreviousSubPortionBeforeLimitWasExceeded.Currency = VT_TurnoverBySubPortionsCumulativeTotal.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND VT_PreviousSubPortionBeforeLimitWasExceeded.PriorityPreviousSubPortion = VT_TurnoverBySubPortionsCumulativeTotal.PriorityPortion";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_PreviousSubPortionBeforeLimitWasExceeded", "VT_TurnoverBySubPortionsCumulativeTotal");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_PreviousSubPortionBeforeLimitWasExceeded", "VT_TurnoverBySubPortionsCumulativeTotal");
	
	QueryText = StrReplace(QueryText, "&SubPortionOfCumulativeTotal", SubPortionOfCumulativeTotal());
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//  SourceTable1 - String
//  AssignmentTable - String
//  Batch - String
//
Procedure AddQueryTextTurnoverPerPortionExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts, SourceTable1, AssignmentTable, Batch) Export
	
	//@skip-check bsl-ql-hub - the selected fields are combined with the grouping by replacing the query text
	QueryText =
	"SELECT
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.Organization AS Organization,
	|	TT_PreparedData.Currency AS Currency,
	|	&MemberFields,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	&ProductFields,
	|	TT_PreparedData.BonusPercent AS BonusPercent,
	|	TT_PreparedData.Priority AS Priority,
	|	SourceTable1.PriorityPortion AS PriorityPortion,
	|	TT_PreparedData.SumPlan AS SumPlan,
	|	TT_PreparedData.NumberOfPackages_ AS NumberOfPackages_,
	|	TT_PreparedData.NumberOfPlansTakingIntoAccountMultiplicityOfSales AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	SourceTable1.CountPlan AS CountPlan,
	|	SourceTable1.QuantityPerServing AS QuantityPerServing,
	|	SourceTable1.QuantityBeforeSubportion AS QuantityBeforeSubportion,
	|	TT_PreparedData.Count AS Count,
	|	SourceTable1.AmountBeforeServing AS AmountBeforeServing,
	|	SourceTable1.AmountBeforeSubportion AS AmountBeforeSubportion,
	|	TT_PreparedData.CalculationBase AS Sum
	|INTO TT_AssignmentTable
	|FROM
	|	&SourceTable1 AS SourceTable1
	|		INNER JOIN TT_PreparedData AS TT_PreparedData
	|		ON SourceTable1.CalculationPeriod = TT_PreparedData.CalculationPeriod
	|			AND SourceTable1.ConditionOfRebateBonusIs = TT_PreparedData.ConditionOfRebateBonusIs
	|			AND SourceTable1.Organization = TT_PreparedData.Organization
	|			AND SourceTable1.Currency = TT_PreparedData.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND SourceTable1.PriorityPortion <= TT_PreparedData.Priority
	|			AND SourceTable1.PriorityPortion + &PortionOfCumulativeTotal > TT_PreparedData.Priority";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "SourceTable1", "TT_PreparedData");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "SourceTable1", "TT_PreparedData");
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	QueryText = StrReplace(QueryText, "TT_AssignmentTable", AssignmentTable);
	
	QueryText = StrReplace(QueryText, "&PortionOfCumulativeTotal", Batch);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverBySubPortions(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	//@skip-check bsl-ql-hub - The grouping and indexing fields are refined by replacing the query text
	QueryText =
	"SELECT
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.Organization AS Organization,
	|	TT_PreparedData.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	CAST(TT_PreparedData.Priority / &SubPortionOfCumulativeTotal - 0.5 AS NUMBER(15, 0))
	|		* &SubPortionOfCumulativeTotal AS PriorityPortion,
	|	VT_TurnoverUntilLimitIsExceeded.PriorityPortion AS PriorityIsParentPortion,
	|	VT_TurnoverUntilLimitIsExceeded.SumPlan AS SumPlan,
	|	VT_TurnoverUntilLimitIsExceeded.CountPlan AS CountPlan,
	|	VT_TurnoverUntilLimitIsExceeded.QuantityPerServing AS QuantityPerServing,
	|	VT_TurnoverUntilLimitIsExceeded.AmountBeforeServing AS AmountBeforeServing,
	|	SUM(TT_PreparedData.Count) AS Count,
	|	SUM(TT_PreparedData.CalculationBase) AS Sum,
	|	SUM(
	|		CASE
	|			WHEN TT_PreparedData.CalculationBase > 0
	|				THEN TT_PreparedData.CalculationBase
	|			ELSE 0
	|		END) AS SumReceipt,
	|	SUM(
	|		CASE
	|			WHEN TT_PreparedData.Count > 0
	|				THEN TT_PreparedData.Count
	|			ELSE 0
	|		END) AS CountReceipt
	|INTO VT_RevolutionsBySubPortions
	|FROM
	|	VT_TurnoverUntilLimitIsExceeded AS VT_TurnoverUntilLimitIsExceeded
	|		INNER JOIN TT_PreparedData AS TT_PreparedData
	|		ON VT_TurnoverUntilLimitIsExceeded.CalculationPeriod = TT_PreparedData.CalculationPeriod
	|			AND VT_TurnoverUntilLimitIsExceeded.ConditionOfRebateBonusIs = TT_PreparedData.ConditionOfRebateBonusIs
	|			AND VT_TurnoverUntilLimitIsExceeded.Organization = TT_PreparedData.Organization
	|			AND VT_TurnoverUntilLimitIsExceeded.Currency = TT_PreparedData.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND VT_TurnoverUntilLimitIsExceeded.PriorityPortion <= TT_PreparedData.Priority
	|			AND VT_TurnoverUntilLimitIsExceeded.PriorityPortion + &PortionOfCumulativeTotal > TT_PreparedData.Priority
	|
	|GROUP BY
	|	TT_PreparedData.CalculationPeriod,
	|	TT_PreparedData.ConditionOfRebateBonusIs,
	|	TT_PreparedData.Organization,
	|	TT_PreparedData.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	CAST(TT_PreparedData.Priority / &SubPortionOfCumulativeTotal - 0.5 AS NUMBER(15, 0)) * &SubPortionOfCumulativeTotal,
	|	VT_TurnoverUntilLimitIsExceeded.PriorityPortion,
	|	VT_TurnoverUntilLimitIsExceeded.SumPlan,
	|	VT_TurnoverUntilLimitIsExceeded.CountPlan,
	|	VT_TurnoverUntilLimitIsExceeded.QuantityPerServing,
	|	VT_TurnoverUntilLimitIsExceeded.AmountBeforeServing";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_TurnoverUntilLimitIsExceeded", "TT_PreparedData");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_TurnoverUntilLimitIsExceeded", "TT_PreparedData");
	
	QueryText = StrReplace(QueryText, "&PortionOfCumulativeTotal", PortionOfCumulativeTotal());
	QueryText = StrReplace(QueryText, "&SubPortionOfCumulativeTotal", SubPortionOfCumulativeTotal());
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextExceedingLimitCumulativeTotal(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_TurnoverPerSubPortionExceedingLimit.CalculationPeriod AS CalculationPeriod,
	|	VT_TurnoverPerSubPortionExceedingLimit.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_TurnoverPerSubPortionExceedingLimit.Organization AS Organization,
	|	VT_TurnoverPerSubPortionExceedingLimit.Currency AS Currency,
	|	&MemberFields,
	|	VT_TurnoverPerSubPortionExceedingLimit.DocumentRecorder AS DocumentRecorder,
	|	&ProductFields,
	|	VT_TurnoverPerSubPortionExceedingLimit.BonusPercent AS BonusPercent,
	|	VT_TurnoverPerSubPortionExceedingLimit.Priority AS Priority,
	|	VT_TurnoverPerSubPortionExceedingLimit.SumPlan AS SumPlan,
	|	VT_TurnoverPerSubPortionExceedingLimit.CountPlan AS CountPlan,
	|	VT_TurnoverPerSubPortionExceedingLimit.NumberOfPackages_ AS NumberOfPackages_,
	|	VT_TurnoverPerSubPortionExceedingLimit.NumberOfPlansTakingIntoAccountMultiplicityOfSales AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	VT_TurnoverPerSubPortionExceedingLimit.Sum AS LineAmount,
	|	VT_TurnoverPerSubPortionExceedingLimit.Count AS NumberOfLines,
	|	VT_TurnoverPerSubPortionExceedingLimit.QuantityPerServing + VT_TurnoverPerSubPortionExceedingLimit.QuantityBeforeSubportion
	|		+ SUM(VT_RevolutionsPerSubPortionExceedingLimitMirror.Count) AS Count,
	|	VT_TurnoverPerSubPortionExceedingLimit.AmountBeforeServing + VT_TurnoverPerSubPortionExceedingLimit.AmountBeforeSubportion
	|		+ SUM(VT_RevolutionsPerSubPortionExceedingLimitMirror.Sum) AS Sum
	|INTO VT_ExceedingLimitCumulativeTotal
	|FROM
	|	VT_TurnoverPerSubPortionExceedingLimit AS VT_TurnoverPerSubPortionExceedingLimit
	|		INNER JOIN VT_TurnoverPerSubPortionExceedingLimit AS VT_RevolutionsPerSubPortionExceedingLimitMirror
	|		ON VT_TurnoverPerSubPortionExceedingLimit.CalculationPeriod = VT_RevolutionsPerSubPortionExceedingLimitMirror.CalculationPeriod
	|			AND VT_TurnoverPerSubPortionExceedingLimit.ConditionOfRebateBonusIs = VT_RevolutionsPerSubPortionExceedingLimitMirror.ConditionOfRebateBonusIs
	|			AND VT_TurnoverPerSubPortionExceedingLimit.Organization = VT_RevolutionsPerSubPortionExceedingLimitMirror.Organization
	|			AND VT_TurnoverPerSubPortionExceedingLimit.Currency = VT_RevolutionsPerSubPortionExceedingLimitMirror.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND VT_TurnoverPerSubPortionExceedingLimit.Priority >= VT_RevolutionsPerSubPortionExceedingLimitMirror.Priority
	|			AND VT_TurnoverPerSubPortionExceedingLimit.PriorityPortion <= VT_RevolutionsPerSubPortionExceedingLimitMirror.Priority
	|
	|GROUP BY
	|	VT_TurnoverPerSubPortionExceedingLimit.CalculationPeriod,
	|	VT_TurnoverPerSubPortionExceedingLimit.ConditionOfRebateBonusIs,
	|	VT_TurnoverPerSubPortionExceedingLimit.Organization,
	|	VT_TurnoverPerSubPortionExceedingLimit.Currency,
	|	&GroupingFieldsByParticipants,
	|	VT_TurnoverPerSubPortionExceedingLimit.DocumentRecorder,
	|	&GroupingFieldsByGoodsFields,
	|	VT_TurnoverPerSubPortionExceedingLimit.SumPlan,
	|	VT_TurnoverPerSubPortionExceedingLimit.CountPlan,
	|	VT_TurnoverPerSubPortionExceedingLimit.NumberOfPackages_,
	|	VT_TurnoverPerSubPortionExceedingLimit.NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	VT_TurnoverPerSubPortionExceedingLimit.Sum,
	|	VT_TurnoverPerSubPortionExceedingLimit.Count,
	|	VT_TurnoverPerSubPortionExceedingLimit.BonusPercent,
	|	VT_TurnoverPerSubPortionExceedingLimit.Priority,
	|	VT_TurnoverPerSubPortionExceedingLimit.AmountBeforeServing,
	|	VT_TurnoverPerSubPortionExceedingLimit.AmountBeforeSubportion,
	|	VT_TurnoverPerSubPortionExceedingLimit.QuantityPerServing,
	|	VT_TurnoverPerSubPortionExceedingLimit.QuantityBeforeSubportion";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_TurnoverPerSubPortionExceedingLimit", "VT_RevolutionsPerSubPortionExceedingLimitMirror");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_TurnoverPerSubPortionExceedingLimit", "VT_RevolutionsPerSubPortionExceedingLimitMirror");
	
	QueryText = StrReplace(QueryText, "&SubPortionOfCumulativeTotal", SubPortionOfCumulativeTotal());
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	TT_DiscountPercentage.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	&GoodsPeriodsFields,
	|	SUM(TT_DiscountPercentage.Count) AS Count,
	|	SUM(&ExpressionAmountWithoutSpecification) AS Sum
	|INTO TT_TurnoverByPeriod
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage
	|
	|GROUP BY
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.CalculationPeriod,
	|	TT_DiscountPercentage.Organization,
	|	TT_DiscountPercentage.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	&GroupingFieldsByGoodsPeriod";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	
	GoodsIndicator = RebateConditionsParameters.GoodsIndicator;
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	TableName = "TT_DiscountPercentage";
	
	If GoodsIndicator = IndicatorsKinds.Count Then
		
		GoodsPeriodsFields = StrTemplate(
			"%1.StartDate AS StartDate,
			|%1.EndDate AS EndDate",
			TableName);
		
		GroupingFieldsByGoodsPeriod = StrTemplate(
			"%1.StartDate,
			|%1.EndDate",
			TableName);
		
	Else
		
		GoodsPeriodsFields = "NULL AS StartDate";
		GroupingFieldsByGoodsPeriod = "NULL";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&GoodsPeriodsFields", GoodsPeriodsFields);
	QueryText = StrReplace(QueryText, "&GroupingFieldsByGoodsPeriod", GroupingFieldsByGoodsPeriod);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPeriodPackageConditionsNotMet(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT DISTINCT
	|	VT_ParticipantsPeriodsDocumentsAllGoods.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.CalculationPeriod AS CalculationPeriod,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.Organization AS Organization,
	|	VT_ParticipantsPeriodsDocumentsAllGoods.Currency AS Currency,
	|	&MemberFields
	|INTO VT_RevolutionsByPeriodPackageConditionsNotMet
	|FROM
	|	VT_ParticipantsPeriodsDocumentsAllGoods AS VT_ParticipantsPeriodsDocumentsAllGoods
	|		LEFT JOIN TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		ON VT_ParticipantsPeriodsDocumentsAllGoods.ConditionOfRebateBonusIs = TT_TurnoverByPeriod.ConditionOfRebateBonusIs
	|			AND VT_ParticipantsPeriodsDocumentsAllGoods.CalculationPeriod = TT_TurnoverByPeriod.CalculationPeriod
	|			AND VT_ParticipantsPeriodsDocumentsAllGoods.Organization = TT_TurnoverByPeriod.Organization
	|			AND VT_ParticipantsPeriodsDocumentsAllGoods.Currency = TT_TurnoverByPeriod.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|WHERE
	|	VT_ParticipantsPeriodsDocumentsAllGoods.CountPlan > ISNULL(TT_TurnoverByPeriod.Count, 0)";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_ParticipantsPeriodsDocumentsAllGoods", "TT_TurnoverByPeriod");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_ParticipantsPeriodsDocumentsAllGoods", "TT_TurnoverByPeriod");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPeriodPackageConditionsAreMet(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.CalculationPeriod AS CalculationPeriod,
	|	TT_TurnoverByPeriod.Organization AS Organization,
	|	TT_TurnoverByPeriod.Currency AS Currency,
	|	&MemberFields,
	|	SUM(TT_TurnoverByPeriod.Sum) AS Sum
	|INTO VT_TurnoverByPeriodPackageConditionsAreMet
	|FROM
	|	TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|	LEFT JOIN VT_RevolutionsByPeriodPackageConditionsNotMet
	|	ON TT_TurnoverByPeriod.ConditionOfRebateBonusIs = VT_RevolutionsByPeriodPackageConditionsNotMet.ConditionOfRebateBonusIs
	|		AND TT_TurnoverByPeriod.CalculationPeriod = VT_RevolutionsByPeriodPackageConditionsNotMet.CalculationPeriod
	|		AND TT_TurnoverByPeriod.Organization = VT_RevolutionsByPeriodPackageConditionsNotMet.Organization
	|		AND TT_TurnoverByPeriod.Currency = VT_RevolutionsByPeriodPackageConditionsNotMet.Currency
	|		AND &ConnectionFieldsByParticipants
	|WHERE
	|	VT_RevolutionsByPeriodPackageConditionsNotMet.ConditionOfRebateBonusIs IS NULL
	|
	|GROUP BY
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.CalculationPeriod,
	|	TT_TurnoverByPeriod.Organization,
	|	TT_TurnoverByPeriod.Currency,
	|	&GroupingFieldsByParticipants";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "TT_TurnoverByPeriod", "VT_RevolutionsByPeriodPackageConditionsNotMet");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPeriodDefinitionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.Organization AS Organization,
	|	TT_TurnoverByPeriod.CalculationPeriod AS CalculationPeriod,
	|	TT_TurnoverByPeriod.Currency AS Currency,
	|	&MemberFields,
	|	TT_TurnoverByPeriod.Sum AS Sum,
	|	ISNULL(MAX(TT_CalculationScale.RangeFrom), 0) AS SumPlan
	|INTO TT_TurnoverByPeriodDefinitionOfPlan
	|FROM
	|	TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		LEFT JOIN TT_CalculationScale AS TT_CalculationScale
	|		ON TT_TurnoverByPeriod.Sum >= TT_CalculationScale.RangeFrom
	|
	|GROUP BY
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.Organization,
	|	TT_TurnoverByPeriod.CalculationPeriod,
	|	TT_TurnoverByPeriod.Currency,
	|	&GroupingFieldsByParticipants,
	|	TT_TurnoverByPeriod.Sum";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "TT_TurnoverByPeriod");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPeriodBonusPercentageByRangeByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.Organization AS Organization,
	|	TT_TurnoverByPeriod.CalculationPeriod AS CalculationPeriod,
	|	TT_TurnoverByPeriod.Currency AS Currency,
	|	&MemberFields,
	|	TT_TurnoverByPeriod.Sum AS Sum,
	|	ISNULL(TT_CalculationScale.RangeNumber, 0) AS RangeNumber,
	|	ISNULL(TT_CalculationScale.RangeFrom, 0) AS RangeFrom,
	|	ISNULL(TT_CalculationScale.RangeBy, 0) AS RangeBy,
	|	ISNULL(TT_CalculationScale.BonusPercent, 0) AS BonusPercent
	|INTO TT_TurnoverByPeriodBonusPercentageByRange
	|FROM
	|	TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		LEFT JOIN TT_CalculationScale AS TT_CalculationScale
	|		ON TT_TurnoverByPeriod.Sum > TT_CalculationScale.RangeFrom";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "TT_TurnoverByPeriod");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPeriodBonusPercentageByRangeByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.Organization AS Organization,
	|	TT_TurnoverByPeriod.CalculationPeriod AS CalculationPeriod,
	|	TT_TurnoverByPeriod.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	TT_TurnoverByPeriod.Sum AS Sum,
	|	TT_TurnoverByPeriod.Count AS Count,
	|	ISNULL(TT_GoodsRanges.BasePrice, 0) AS BasePrice,
	|	ISNULL(TT_GoodsRanges.RangeNumber, 0) AS RangeNumber,
	|	ISNULL(TT_GoodsRanges.RangeFrom, 0) AS RangeFrom,
	|	ISNULL(TT_GoodsRanges.RangeBy, 0) AS RangeBy,
	|	ISNULL(TT_GoodsRanges.BonusPercent, 0) AS BonusPercent
	|INTO TT_TurnoverByPeriodBonusPercentageByRange
	|FROM
	|	TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		LEFT JOIN TT_GoodsRanges AS TT_GoodsRanges
	|		ON TT_TurnoverByPeriod.Count > TT_GoodsRanges.RangeFrom
	|			AND &ConnectionFieldsByGoods
	|WHERE
	|	TT_TurnoverByPeriod.Count > 0
	|
	|UNION ALL
	|
	|SELECT
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.Organization AS Organization,
	|	TT_TurnoverByPeriod.CalculationPeriod AS CalculationPeriod,
	|	TT_TurnoverByPeriod.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	TT_TurnoverByPeriod.Sum AS Sum,
	|	TT_TurnoverByPeriod.Count AS Count,
	|	ISNULL(TT_GoodsRanges.BasePrice, 0) AS BasePrice,
	|	ISNULL(TT_GoodsRanges.RangeNumber, 0) AS RangeNumber,
	|	ISNULL(TT_GoodsRanges.RangeFrom, 0) AS RangeFrom,
	|	ISNULL(TT_GoodsRanges.RangeBy, 0) AS RangeBy,
	|	ISNULL(TT_GoodsRanges.BonusPercent, 0) AS BonusPercent
	|FROM
	|	TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		LEFT JOIN TT_GoodsRanges AS TT_GoodsRanges
	|		ON TT_GoodsRanges.RangeFrom = 0
	|			AND &ConnectionFieldsByGoods
	|WHERE
	|	TT_TurnoverByPeriod.Count <= 0";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "TT_TurnoverByPeriod");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_TurnoverByPeriod", "TT_GoodsRanges");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPeriodBonusPercentageByRange(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.Organization AS Organization,
	|	TT_TurnoverByPeriod.CalculationPeriod AS CalculationPeriod,
	|	TT_TurnoverByPeriod.Currency AS Currency,
	|	&MemberFields,
	|	TT_TurnoverByPeriod.Sum AS Sum,
	|	ISNULL(TT_CalculationScale.RangeNumber, 0) AS RangeNumber,
	|	ISNULL(TT_CalculationScale.RangeFrom, 0) AS RangeFrom,
	|	ISNULL(TT_CalculationScale.RangeBy, 0) AS RangeBy,
	|	ISNULL(TT_CalculationScale.BonusPercent, 0) AS BonusPercent
	|INTO TT_TurnoverByPeriodBonusPercentageByRange
	|FROM
	|	TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		LEFT JOIN TT_CalculationScale AS TT_CalculationScale
	|		ON TT_TurnoverByPeriod.Sum > TT_CalculationScale.RangeFrom
	|WHERE
	|	TT_TurnoverByPeriod.Sum > 0
	|
	|UNION ALL
	|
	|SELECT
	|	TT_TurnoverByPeriod.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriod.Organization AS Organization,
	|	TT_TurnoverByPeriod.CalculationPeriod AS CalculationPeriod,
	|	TT_TurnoverByPeriod.Currency AS Currency,
	|	&MemberFields,
	|	TT_TurnoverByPeriod.Sum AS Sum,
	|	ISNULL(TT_CalculationScale.RangeNumber, 0) AS RangeNumber,
	|	ISNULL(TT_CalculationScale.RangeFrom, 0) AS RangeFrom,
	|	ISNULL(TT_CalculationScale.RangeBy, 0) AS RangeBy,
	|	ISNULL(TT_CalculationScale.BonusPercent, 0) AS BonusPercent
	|FROM
	|	TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		LEFT JOIN TT_CalculationScale AS TT_CalculationScale
	|		ON TT_CalculationScale.RangeFrom = 0
	|WHERE
	|	TT_TurnoverByPeriod.Sum <= 0";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "TT_TurnoverByPeriod");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTurnoverByPeriodBonusPercentageByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_TurnoverByPeriodDefinitionOfPlan.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_TurnoverByPeriodDefinitionOfPlan.Organization AS Organization,
	|	TT_TurnoverByPeriodDefinitionOfPlan.CalculationPeriod AS CalculationPeriod,
	|	TT_TurnoverByPeriodDefinitionOfPlan.Currency AS Currency,
	|	&MemberFields,
	|	TT_TurnoverByPeriodDefinitionOfPlan.Sum AS Sum,
	|	CASE
	|		WHEN TT_TurnoverByPeriodDefinitionOfPlan.SumPlan <> 0
	|			THEN TT_TurnoverByPeriodDefinitionOfPlan.SumPlan
	|		ELSE ISNULL(TT_CalculationScaleMinimumPlan.RangeFrom, 0)
	|	END AS SumPlan,
	|	ISNULL(TT_CalculationScale.BonusPercent, ISNULL(TT_CalculationScaleMinimumPlan.BonusPercent, 0)) AS BonusPercent
	|INTO TT_TurnoverByPeriodBonusPercentage
	|FROM
	|	TT_TurnoverByPeriodDefinitionOfPlan AS TT_TurnoverByPeriodDefinitionOfPlan
	|		LEFT JOIN TT_CalculationScale AS TT_CalculationScale
	|		ON TT_TurnoverByPeriodDefinitionOfPlan.SumPlan = TT_CalculationScale.RangeFrom
	|		LEFT JOIN TT_CalculationScaleMinimumPlan AS TT_CalculationScaleMinimumPlan
	|		ON TRUE";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "TT_TurnoverByPeriodDefinitionOfPlan");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreparedAmountData(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.GoodsIndicator AS GoodsIndicator,
	|	TT_DiscountPercentage.Period AS Period,
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.DocumentRecorder AS DocumentRecorder,
	|	TT_DiscountPercentage.LineNumber AS LineNumber,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	&MemberFields,
	|	TT_DiscountPercentage.Contract AS Contract,
	|	TT_DiscountPercentage.Terms AS Terms,
	|	TT_DiscountPercentage.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_DiscountPercentage.Products AS Products,
	|	TT_DiscountPercentage.UnitOfMeasure AS UnitOfMeasure,
	|	TT_DiscountPercentage.Characteristic AS Characteristic,
	|	TT_DiscountPercentage.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_DiscountPercentage.PropertyValue AS PropertyValue,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency AS AccrualFrequency,
	|	TT_DiscountPercentage.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_DiscountPercentage.FIFODistribution AS FIFODistribution,
	|	TT_DiscountPercentage.BaseOfCalculation AS BaseOfCalculation,
	|	&PriorityExpression AS Priority,
	|	&ExpressionCalculationCurrency AS Currency,
	|	&ExpressionIsOriginalQuantity AS Count,
	|	0 AS NumberOfPackages_,
	|	&ExpressionSalesAmount AS SalesAmount,
	|	&ExpressionSumTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	&ExpressionAmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	&ExpressionBonusPercentage AS BonusPercent,
	|	&ExpressionAmountWithoutSpecification AS CalculationBase,
	|	TT_DiscountPercentage.BasePrice AS BasePrice,
	|	&ExpressionSumPlan AS SumPlan,
	|	&ExpressionRangeFrom AS RangeFrom,
	|	&ExpressionRangeBy AS RangeBy,
	|	&ExpressionRangeNumber AS RangeNumber,
	|	0 AS CountPlan,
	|	0 AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	ISNULL(TurnoverByPeriod.Sum, 0) AS VerificationAmount,
	|	ISNULL(TurnoverByPeriod.Sum, 0) AS CalculationBaseOfEverything,
	|	0 AS CountOfChecks,
	|	&ExpressionPlanIsCompleted AS PlanIsFulfilled
	|INTO TT_PreparedData
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage
	|		LEFT JOIN &TableTurnoverByPeriod AS TurnoverByPeriod
	|		ON TT_DiscountPercentage.ConditionOfRebateBonusIs = TurnoverByPeriod.ConditionOfRebateBonusIs
	|			AND TT_DiscountPercentage.Organization = TurnoverByPeriod.Organization
	|			AND TT_DiscountPercentage.CalculationPeriod = TurnoverByPeriod.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|	AND &ExceedingLimitTable";
	
	If RebateConditionsParameters.RestrictAccrualOverPlan
	 Or RebateConditionsParameters.CalculationScaleByRanges
	 Or RebateConditionsParameters.GoodsIndicator = SalesFigures.BatchOffer Then
		
		ExceedingLimitTable =
		"LEFT JOIN VT_ExceedingLimitTotal AS VT_ExceedingLimitTotal
		|		ON TT_DiscountPercentage.DocumentRecorder = VT_ExceedingLimitTotal.DocumentRecorder
		|			AND TT_DiscountPercentage.LineNumber = VT_ExceedingLimitTotal.LineNumber";
		
		PriorityExpression = "VT_ExceedingLimitTotal.Priority";
		
	Else
		
		ExceedingLimitTable = "";
		PriorityExpression = "0";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &ExceedingLimitTable", ExceedingLimitTable);
	QueryText = StrReplace(QueryText, "&PriorityExpression", PriorityExpression);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		TableTurnoverByPeriod = "TT_TurnoverByPeriodBonusPercentage";
		ExpressionBonusPercentage = "ISNULL(TurnoverByPeriod.BonusPercent, 0)";
		ExpressionSumPlan = "ISNULL(TurnoverByPeriod.SumPlan, 0)";
		ExpressionRangeFrom = "ISNULL(TurnoverByPeriod.SumPlan, 0)";
		ExpressionRangeBy = "0";
		ExpressionRangeNumber = "0";
		ExpressionIsOriginalQuantity = "TT_DiscountPercentage.Count";
		ExpressionSalesAmount = "&ExpressionAmountWithoutSpecification";
		ExpressionSumTurnoverWithVAT = "&ExpressionSumWithVAT";
		ExpressionAmountOfTurnoverExcludingVAT = "&ExpressionVATExclusive";
		ExpressionPlanIsCompleted = "(ISNULL(TurnoverByPeriod.Sum, 0) >= ISNULL(TurnoverByPeriod.SumPlan, 0))";
	
	ElsIf RebateConditionsParameters.CalculationScaleByRanges
	        And RebateConditionsParameters.ProportionalDistribution Then
		
		TableTurnoverByPeriod = "TT_TurnoverByPeriodBonusPercentageByRange";
		ExpressionBonusPercentage = "ISNULL(TurnoverByPeriod.BonusPercent, 0)";
		ExpressionRangeFrom = "ISNULL(TurnoverByPeriod.RangeFrom, 0)";
		ExpressionRangeBy = "ISNULL(TurnoverByPeriod.RangeBy, 0)";
		ExpressionRangeNumber = "ISNULL(TurnoverByPeriod.RangeNumber, 0)";
		
		If RebateConditionsParameters.GoodsIndicator = SalesFigures.Sum Then
			
			ExpressionSumPlan =
			"CASE
			|	WHEN ISNULL(TurnoverByPeriod.RangeBy, 0) = 0
			|		THEN ISNULL(TurnoverByPeriod.Sum, 0) - ISNULL(TurnoverByPeriod.RangeFrom, 0)
			|	WHEN ISNULL(TurnoverByPeriod.Sum, 0) <= ISNULL(TurnoverByPeriod.RangeBy, 0)
			|		THEN ISNULL(TurnoverByPeriod.Sum, 0) - ISNULL(TurnoverByPeriod.RangeFrom, 0)
			|	ELSE ISNULL(TurnoverByPeriod.RangeBy, 0) - ISNULL(TurnoverByPeriod.RangeFrom, 0)
			|END";
			
			ExpressionIsOriginalQuantity =
			"CASE
			|	WHEN ISNULL(TurnoverByPeriod.RangeFrom, 0) = 0
			|		THEN TT_DiscountPercentage.Count
			|	ELSE 0
			|END";
			
			ExpressionSalesAmount =
			"CASE
			|	WHEN ISNULL(TurnoverByPeriod.RangeFrom, 0) = 0
			|		THEN &ExpressionAmountWithoutSpecification
			|	ELSE 0
			|END";
			ExpressionSumTurnoverWithVAT =
			"CASE
			|	WHEN ISNULL(TurnoverByPeriod.RangeFrom, 0) = 0
			|		THEN &ExpressionSumWithVAT
			|	ELSE 0
			|END";
			ExpressionAmountOfTurnoverExcludingVAT =
			"CASE
			|	WHEN ISNULL(TurnoverByPeriod.RangeFrom, 0) = 0
			|		THEN &ExpressionVATExclusive
			|	ELSE 0
			|END";
			
			ExpressionPlanIsCompleted = "(ISNULL(TurnoverByPeriod.Sum, 0) >= ISNULL(TurnoverByPeriod.RangeFrom, 0))";
			
		Else
			
			ExpressionIsOriginalQuantity = "TT_DiscountPercentage.Count";
			ExpressionSumPlan = "ISNULL(TurnoverByPeriod.RangeFrom, 0)";
			ExpressionSalesAmount = "&ExpressionAmountWithoutSpecification";
			ExpressionSumTurnoverWithVAT = "&ExpressionSumWithVAT";
			ExpressionAmountOfTurnoverExcludingVAT = "&ExpressionVATExclusive";
			ExpressionPlanIsCompleted = "(ISNULL(TurnoverByPeriod.Sum, 0) >= ISNULL(TurnoverByPeriod.RangeFrom, 0))";
			
		EndIf;
		
	Else
		
		TableTurnoverByPeriod = "TT_TurnoverByPeriod";
		ExpressionBonusPercentage = "TT_DiscountPercentage.BonusPercent";
		ExpressionSumPlan = "TT_DiscountPercentage.SumPlan";
		ExpressionRangeFrom = "TT_DiscountPercentage.SumPlan";
		ExpressionRangeBy = "0";
		ExpressionRangeNumber = "0";
		ExpressionIsOriginalQuantity = "TT_DiscountPercentage.Count";
		ExpressionSalesAmount = "&ExpressionAmountWithoutSpecification";
		ExpressionSumTurnoverWithVAT = "&ExpressionSumWithVAT";
		ExpressionAmountOfTurnoverExcludingVAT = "&ExpressionVATExclusive";
		ExpressionPlanIsCompleted = "(ISNULL(TurnoverByPeriod.Sum, 0) >= TT_DiscountPercentage.SumPlan)";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TableTurnoverByPeriod", TableTurnoverByPeriod);
	QueryText = StrReplace(QueryText, "&ExpressionBonusPercentage", ExpressionBonusPercentage);
	QueryText = StrReplace(QueryText, "&ExpressionSumPlan", ExpressionSumPlan);
	QueryText = StrReplace(QueryText, "&ExpressionRangeFrom", ExpressionRangeFrom);
	QueryText = StrReplace(QueryText, "&ExpressionRangeBy", ExpressionRangeBy);
	QueryText = StrReplace(QueryText, "&ExpressionRangeNumber", ExpressionRangeNumber);
	QueryText = StrReplace(QueryText, "&ExpressionSumPlan", ExpressionSumPlan);
	QueryText = StrReplace(QueryText, "&ExpressionIsOriginalQuantity", ExpressionIsOriginalQuantity);
	QueryText = StrReplace(QueryText, "&ExpressionSalesAmount", ExpressionSalesAmount);
	QueryText = StrReplace(QueryText, "&ExpressionSumTurnoverWithVAT", ExpressionSumTurnoverWithVAT);
	QueryText = StrReplace(QueryText, "&ExpressionAmountOfTurnoverExcludingVAT", ExpressionAmountOfTurnoverExcludingVAT);
	QueryText = StrReplace(QueryText, "&ExpressionPlanIsCompleted", ExpressionPlanIsCompleted);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TurnoverByPeriod");
	SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteAmountSelectionFieldWithVAT(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteVATExclusiveAmountSelectionField(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteExpressionCalculationCurrency(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreparedDataPlanDefinition(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.GoodsIndicator AS GoodsIndicator,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency AS AccrualFrequency,
	|	TT_DiscountPercentage.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_DiscountPercentage.FIFODistribution AS FIFODistribution,
	|	TT_DiscountPercentage.Period AS Period,
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.DocumentRecorder AS DocumentRecorder,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	&MemberFields,
	|	TT_DiscountPercentage.Contract AS Contract,
	|	TT_DiscountPercentage.Terms AS Terms,
	|	TT_DiscountPercentage.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_DiscountPercentage.Products AS Products,
	|	TT_DiscountPercentage.Characteristic AS Characteristic,
	|	TT_DiscountPercentage.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_DiscountPercentage.PropertyValue AS PropertyValue,
	|	TT_DiscountPercentage.UnitOfMeasure AS UnitOfMeasure,
	|	TT_DiscountPercentage.LineNumber AS LineNumber,
	|	TT_DiscountPercentage.Count AS Count,
	|	TT_DiscountPercentage.BaseOfCalculation AS BaseOfCalculation,
	|	TT_DiscountPercentage.Currency AS Currency,
	|	TT_DiscountPercentage.Sum AS Sum,
	|	TT_DiscountPercentage.SumCompl AS SumCompl,
	|	TT_DiscountPercentage.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	TT_DiscountPercentage.AmountOfTurnoverOfMansWithVAT AS AmountOfTurnoverOfMansWithVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverOfLocalWithVAT AS AmountOfTurnoverOfLocalWithVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	TT_DiscountPercentage.ManSTurnoverAmountExcludingVAT AS ManSTurnoverAmountExcludingVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverIsLocalWithoutVAT AS AmountOfTurnoverIsLocalWithoutVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	TT_DiscountPercentage.StartDate AS StartDate,
	|	TT_DiscountPercentage.EndDate AS EndDate,
	|	ISNULL(TT_TurnoverByPeriod.Count, 0) AS CountOfChecks,
	|	ISNULL(TT_TurnoverByPeriod.Sum, 0) AS TotalSalesAmount_,
	|	ISNULL(MAX(TT_Goods.CountPlan), 0) AS CountPlan
	|INTO VT_PreparedDataPlanDefinition
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage
	|		LEFT JOIN TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		ON TT_DiscountPercentage.ConditionOfRebateBonusIs = TT_TurnoverByPeriod.ConditionOfRebateBonusIs
	|			AND TT_DiscountPercentage.CalculationPeriod = TT_TurnoverByPeriod.CalculationPeriod
	|			AND TT_DiscountPercentage.Organization = TT_TurnoverByPeriod.Organization
	|			AND TT_DiscountPercentage.Currency = TT_TurnoverByPeriod.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND TT_DiscountPercentage.StartDate = TT_TurnoverByPeriod.StartDate
	|			AND TT_DiscountPercentage.EndDate = TT_TurnoverByPeriod.EndDate
	|		LEFT JOIN TT_Goods AS TT_Goods
	|		ON &ConnectionConditionsItems
	|WHERE
	|	TT_DiscountPercentage.CharacteristicsOfSalesPurchases IS NOT NULL
	|
	|GROUP BY
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.FIFODistribution,
	|	TT_DiscountPercentage.Period,
	|	TT_DiscountPercentage.DocumentRecorder,
	|	TT_DiscountPercentage.Organization,
	|	&GroupingFieldsByParticipants,
	|	TT_DiscountPercentage.Contract,
	|	TT_DiscountPercentage.Terms,
	|	TT_DiscountPercentage.ItemVariantsAreUsed,
	|	TT_DiscountPercentage.Products,
	|	TT_DiscountPercentage.Characteristic,
	|	TT_DiscountPercentage.CharacteristicsOfSalesPurchases,
	|	TT_DiscountPercentage.PropertyValue,
	|	TT_DiscountPercentage.LineNumber,
	|	TT_DiscountPercentage.RestrictAccrualOverPlan,
	|	TT_DiscountPercentage.Count,
	|	TT_DiscountPercentage.Sum,
	|	TT_DiscountPercentage.AmountOfTurnoverOfMansWithVAT,
	|	TT_DiscountPercentage.ManSTurnoverAmountExcludingVAT,
	|	TT_DiscountPercentage.SumPlan,
	|	TT_DiscountPercentage.StartDate,
	|	TT_DiscountPercentage.EndDate,
	|	TT_TurnoverByPeriod.Count,
	|	TT_TurnoverByPeriod.Sum,
	|	TT_DiscountPercentage.GoodsIndicator,
	|	TT_DiscountPercentage.PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency,
	|	TT_DiscountPercentage.ConditionFrequency,
	|	TT_DiscountPercentage.CalculationPeriod,
	|	TT_DiscountPercentage.UnitOfMeasure,
	|	TT_DiscountPercentage.BaseOfCalculation,
	|	TT_DiscountPercentage.Currency,
	|	TT_DiscountPercentage.SumCompl,
	|	TT_DiscountPercentage.AmountInARAPCurrency,
	|	TT_DiscountPercentage.AmountOfTurnoverOfLocalWithVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverIsLocalWithoutVAT,
	|	TT_DiscountPercentage.AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TT_TurnoverByPeriod");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TT_TurnoverByPeriod");
	
	ConnectionConditionsItems =
	"&ConnectionFieldsByGoods
	|	AND TT_DiscountPercentage.StartDate = TT_Goods.StartDate
	|	AND TT_DiscountPercentage.EndDate = TT_Goods.EndDate
	|	AND ISNULL(TT_TurnoverByPeriod.Count, 0) >= TT_Goods.CountPlan";
	SubstituteFieldsForGoods(RebateConditionsParameters, ConnectionConditionsItems, "TT_DiscountPercentage", "TT_Goods", True);
	QueryText = StrReplace(QueryText, "&ConnectionConditionsItems", ConnectionConditionsItems);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreparedQuantityData(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	VT_PreparedDataPlanDefinition.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_PreparedDataPlanDefinition.GoodsIndicator AS GoodsIndicator,
	|	VT_PreparedDataPlanDefinition.Period AS Period,
	|	VT_PreparedDataPlanDefinition.CalculationPeriod AS CalculationPeriod,
	|	VT_PreparedDataPlanDefinition.DocumentRecorder AS DocumentRecorder,
	|	VT_PreparedDataPlanDefinition.LineNumber AS LineNumber,
	|	VT_PreparedDataPlanDefinition.Organization AS Organization,
	|	&MemberFields,
	|	VT_PreparedDataPlanDefinition.Contract AS Contract,
	|	VT_PreparedDataPlanDefinition.Terms AS Terms,
	|	VT_PreparedDataPlanDefinition.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_PreparedDataPlanDefinition.Products AS Products,
	|	VT_PreparedDataPlanDefinition.UnitOfMeasure AS UnitOfMeasure,
	|	VT_PreparedDataPlanDefinition.Characteristic AS Characteristic,
	|	VT_PreparedDataPlanDefinition.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_PreparedDataPlanDefinition.PropertyValue AS PropertyValue,
	|	VT_PreparedDataPlanDefinition.PartyCountDetails AS PartyCountDetails,
	|	VT_PreparedDataPlanDefinition.AccrualFrequency AS AccrualFrequency,
	|	VT_PreparedDataPlanDefinition.ConditionFrequency AS ConditionFrequency,
	|	VT_PreparedDataPlanDefinition.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_PreparedDataPlanDefinition.FIFODistribution AS FIFODistribution,
	|	VT_PreparedDataPlanDefinition.BaseOfCalculation AS BaseOfCalculation,
	|	&PriorityExpression AS Priority,
	|	VT_PreparedDataPlanDefinition.Currency AS Currency,
	|	VT_PreparedDataPlanDefinition.Count AS Count,
	|	0 AS NumberOfPackages_,
	|	&ExpressionAmountWithoutSpecification AS SalesAmount,
	|	&ExpressionSumWithVAT AS AmountOfTurnoverWithVAT,
	|	&ExpressionVATExclusive AS AmountOfTurnoverExcludingVAT,
	|	&ExpressionAmountWithoutSpecification AS CalculationBase,
	|	ISNULL(TT_Goods.BonusPercent, VT_ItemsMinimumParametersByPosition.BonusPercent) AS BonusPercent,
	|	ISNULL(TT_Goods.BasePrice, VT_ItemsMinimumParametersByPosition.BasePrice) AS BasePrice,
	|	0 AS SumPlan,
	|	ISNULL(TT_Goods.CountPlan, VT_ItemsMinimumParametersByPosition.CountPlan) AS CountPlan,
	|	ISNULL(TT_Goods.CountPlan, VT_ItemsMinimumParametersByPosition.CountPlan) AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	0 AS RangeFrom,
	|	0 AS RangeBy,
	|	0 AS RangeNumber,
	|	VT_PreparedDataPlanDefinition.TotalSalesAmount_ AS VerificationAmount,
	|	VT_PreparedDataPlanDefinition.CountOfChecks AS CountOfChecks,
	|	(VT_PreparedDataPlanDefinition.CountOfChecks
	|		>= ISNULL(TT_Goods.CountPlan, VT_ItemsMinimumParametersByPosition.CountPlan)) AS PlanIsFulfilled
	|INTO TT_PreparedData
	|FROM
	|	VT_PreparedDataPlanDefinition AS VT_PreparedDataPlanDefinition
	|		LEFT JOIN TT_Goods AS TT_Goods
	|		ON VT_PreparedDataPlanDefinition.ConditionOfRebateBonusIs = TT_Goods.TermsAndConditionsOfRebates
	|			AND &ConnectionFieldsByGoods
	|			AND VT_PreparedDataPlanDefinition.StartDate = TT_Goods.StartDate
	|			AND VT_PreparedDataPlanDefinition.EndDate = TT_Goods.EndDate
	|			AND VT_PreparedDataPlanDefinition.CountPlan = TT_Goods.CountPlan
	|		LEFT JOIN VT_ItemsMinimumParametersByPosition AS VT_ItemsMinimumParametersByPosition
	|			ON &ConnectionConditionsMinimumParameters
	|			AND &ExceedingLimitTable";
	
	If RebateConditionsParameters.RestrictAccrualOverPlan
	 Or RebateConditionsParameters.GoodsIndicator = SalesFigures.BatchOffer Then
		
		ExceedingLimitTable =
		"LEFT JOIN VT_ExceedingLimitTotal AS VT_ExceedingLimitTotal
		|		ON VT_PreparedDataPlanDefinition.DocumentRecorder = VT_ExceedingLimitTotal.DocumentRecorder
		|			AND VT_PreparedDataPlanDefinition.LineNumber = VT_ExceedingLimitTotal.LineNumber";
		
		PriorityExpression = "VT_ExceedingLimitTotal.Priority";
		
	Else
		
		ExceedingLimitTable = "";
		PriorityExpression = "0";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &ExceedingLimitTable", ExceedingLimitTable);
	QueryText = StrReplace(QueryText, "&PriorityExpression", PriorityExpression);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_PreparedDataPlanDefinition");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "VT_PreparedDataPlanDefinition", "TT_Goods", True);
	SubstituteAmountSelectionFieldWithoutSpecifying(
		RebateConditionsParameters, QueryText, "VT_PreparedDataPlanDefinition", "TT_Goods");
	SubstituteAmountSelectionFieldWithVAT(
		RebateConditionsParameters, QueryText, "VT_PreparedDataPlanDefinition", "TT_Goods");
	SubstituteVATExclusiveAmountSelectionField(
		RebateConditionsParameters, QueryText, "VT_PreparedDataPlanDefinition", "TT_Goods");
	
	ConnectionConditionsMinimumParameters =
	"&ConnectionFieldsByGoods
	|	AND VT_PreparedDataPlanDefinition.StartDate = VT_ItemsMinimumParametersByPosition.StartDate
	|	AND VT_PreparedDataPlanDefinition.EndDate = VT_ItemsMinimumParametersByPosition.EndDate";
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		ConnectionConditionsMinimumParameters,
		"VT_PreparedDataPlanDefinition",
		"VT_ItemsMinimumParametersByPosition");
	QueryText = StrReplace(QueryText, "&ConnectionConditionsMinimumParameters", ConnectionConditionsMinimumParameters);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreparedDataByQuantityByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.GoodsIndicator AS GoodsIndicator,
	|	TT_DiscountPercentage.Period AS Period,
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.DocumentRecorder AS DocumentRecorder,
	|	TT_DiscountPercentage.LineNumber AS LineNumber,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	&MemberFields,
	|	TT_DiscountPercentage.Contract AS Contract,
	|	TT_DiscountPercentage.Terms AS Terms,
	|	TT_DiscountPercentage.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_DiscountPercentage.Products AS Products,
	|	TT_DiscountPercentage.UnitOfMeasure AS UnitOfMeasure,
	|	TT_DiscountPercentage.Characteristic AS Characteristic,
	|	TT_DiscountPercentage.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_DiscountPercentage.PropertyValue AS PropertyValue,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency AS AccrualFrequency,
	|	TT_DiscountPercentage.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_DiscountPercentage.FIFODistribution AS FIFODistribution,
	|	TT_DiscountPercentage.BaseOfCalculation AS BaseOfCalculation,
	|	ISNULL(VT_ExceedingLimitTotal.Priority, -1) AS Priority,
	|	TT_DiscountPercentage.Currency AS Currency,
	|	TT_DiscountPercentage.Count AS Count,
	|	0 AS NumberOfPackages_,
	|	&ExpressionAmountWithoutSpecification AS SalesAmount,
	|	&ExpressionSumWithVAT AS AmountOfTurnoverWithVAT,
	|	&ExpressionVATExclusive AS AmountOfTurnoverExcludingVAT,
	|	&ExpressionAmountWithoutSpecification AS CalculationBase,
	|	ISNULL(TurnoverByPeriod.BonusPercent, 0) AS BonusPercent,
	|	ISNULL(TurnoverByPeriod.BasePrice, 0) AS BasePrice,
	|	0 AS SumPlan,
	|	ISNULL(TurnoverByPeriod.RangeFrom, 0) AS CountPlan,
	|	ISNULL(TurnoverByPeriod.RangeFrom, 0) AS RangeFrom,
	|	ISNULL(TurnoverByPeriod.RangeBy, 0) AS RangeBy,
	|	ISNULL(TurnoverByPeriod.RangeNumber, -1) AS RangeNumber,
	|	ISNULL(TurnoverByPeriod.Sum, 0) AS VerificationAmount,
	|	ISNULL(TurnoverByPeriod.Count, 0) AS CountOfChecks
	|INTO TT_PreparedData
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage
	|		LEFT JOIN TT_TurnoverByPeriodBonusPercentageByRange AS TurnoverByPeriod
	|		ON TT_DiscountPercentage.ConditionOfRebateBonusIs = TurnoverByPeriod.ConditionOfRebateBonusIs
	|			AND TT_DiscountPercentage.Organization = TurnoverByPeriod.Organization
	|			AND TT_DiscountPercentage.Currency = TurnoverByPeriod.Currency
	|			AND TT_DiscountPercentage.CalculationPeriod = TurnoverByPeriod.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|		LEFT JOIN VT_ExceedingLimitTotal AS VT_ExceedingLimitTotal
	|		ON TT_DiscountPercentage.DocumentRecorder = VT_ExceedingLimitTotal.DocumentRecorder
	|			AND TT_DiscountPercentage.LineNumber = VT_ExceedingLimitTotal.LineNumber";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TurnoverByPeriod");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TurnoverByPeriod");
	SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TurnoverByPeriod");
	SubstituteAmountSelectionFieldWithVAT(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TurnoverByPeriod");
	SubstituteVATExclusiveAmountSelectionField(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TurnoverByPeriod");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreparedQuantityDataByFIFORanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.GoodsIndicator AS GoodsIndicator,
	|	TT_DiscountPercentage.Period AS Period,
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	TT_DiscountPercentage.DocumentRecorder AS DocumentRecorder,
	|	TT_DiscountPercentage.LineNumber AS LineNumber,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	&MemberFields,
	|	TT_DiscountPercentage.Contract AS Contract,
	|	TT_DiscountPercentage.Terms AS Terms,
	|	TT_DiscountPercentage.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_DiscountPercentage.Products AS Products,
	|	TT_DiscountPercentage.UnitOfMeasure AS UnitOfMeasure,
	|	TT_DiscountPercentage.Characteristic AS Characteristic,
	|	TT_DiscountPercentage.PropertyValue AS PropertyValue,
	|	TT_DiscountPercentage.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency AS AccrualFrequency,
	|	TT_DiscountPercentage.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_DiscountPercentage.FIFODistribution AS FIFODistribution,
	|	TT_DiscountPercentage.BaseOfCalculation AS BaseOfCalculation,
	|	ISNULL(VT_ExceedingLimitTotal.Priority, -1) AS Priority,
	|	TT_DiscountPercentage.Currency AS Currency,
	|	TT_DiscountPercentage.Count AS Count,
	|	0 AS NumberOfPackages_,
	|	&ExpressionAmountWithoutSpecification AS SalesAmount,
	|	&ExpressionSumWithVAT AS AmountOfTurnoverWithVAT,
	|	&ExpressionVATExclusive AS AmountOfTurnoverExcludingVAT,
	|	&ExpressionAmountWithoutSpecification AS CalculationBase,
	|	0 AS BonusPercent,
	|	0 AS BasePrice,
	|	0 AS SumPlan,
	|	0 AS CountPlan,
	|	0 AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	0 AS VerificationAmount,
	|	ISNULL(TurnoverByPeriod.Count, 0) AS CountOfChecks
	|INTO TT_PreparedData
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage
	|		LEFT JOIN TT_TurnoverByPeriod AS TurnoverByPeriod
	|		ON TT_DiscountPercentage.ConditionOfRebateBonusIs = TurnoverByPeriod.ConditionOfRebateBonusIs
	|			AND TT_DiscountPercentage.Organization = TurnoverByPeriod.Organization
	|			AND TT_DiscountPercentage.Currency = TurnoverByPeriod.Currency
	|			AND TT_DiscountPercentage.CalculationPeriod = TurnoverByPeriod.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|		LEFT JOIN VT_ExceedingLimitTotal AS VT_ExceedingLimitTotal
	|		ON TT_DiscountPercentage.DocumentRecorder = VT_ExceedingLimitTotal.DocumentRecorder
	|			AND TT_DiscountPercentage.LineNumber = VT_ExceedingLimitTotal.LineNumber";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TurnoverByPeriod");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_DiscountPercentage", "TurnoverByPeriod");
	SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteAmountSelectionFieldWithVAT(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteVATExclusiveAmountSelectionField(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreparedDataByQuantityInAggregate(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_DiscountPercentageWithPackageData.Period AS Period,
	|	VT_DiscountPercentageWithPackageData.LineNumber AS LineNumber,
	|	VT_DiscountPercentageWithPackageData.CalculationPeriod AS CalculationPeriod,
	|	VT_DiscountPercentageWithPackageData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DiscountPercentageWithPackageData.GoodsIndicator AS GoodsIndicator,
	|	VT_DiscountPercentageWithPackageData.PartyCountDetails AS PartyCountDetails,
	|	VT_DiscountPercentageWithPackageData.AccrualFrequency AS AccrualFrequency,
	|	VT_DiscountPercentageWithPackageData.ConditionFrequency AS ConditionFrequency,
	|	VT_DiscountPercentageWithPackageData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_DiscountPercentageWithPackageData.FIFODistribution AS FIFODistribution,
	|	VT_DiscountPercentageWithPackageData.SumPlan AS SumPlan,
	|	VT_DiscountPercentageWithPackageData.DocumentRecorder AS DocumentRecorder,
	|	VT_DiscountPercentageWithPackageData.Organization AS Organization,
	|	&MemberFields,
	|	VT_DiscountPercentageWithPackageData.Contract AS Contract,
	|	VT_DiscountPercentageWithPackageData.Terms AS Terms,
	|	VT_DiscountPercentageWithPackageData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_DiscountPercentageWithPackageData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_DiscountPercentageWithPackageData.Products AS Products,
	|	VT_DiscountPercentageWithPackageData.UnitOfMeasure AS UnitOfMeasure,
	|	VT_DiscountPercentageWithPackageData.Characteristic AS Characteristic,
	|	VT_DiscountPercentageWithPackageData.PropertyValue AS PropertyValue,
	|	VT_DiscountPercentageWithPackageData.Count AS Count,
	|	VT_DiscountPercentageWithPackageData.BaseOfCalculation AS BaseOfCalculation,
	|	VT_DiscountPercentageWithPackageData.BasePrice AS BasePrice,
	|	VT_DiscountPercentageWithPackageData.BonusPercent AS BonusPercent,
	|	VT_DiscountPercentageWithPackageData.StartDate AS StartDate,
	|	VT_DiscountPercentageWithPackageData.EndDate AS EndDate,
	|	ISNULL(VT_TurnoverByPeriodPackageConditionsAreMet.Sum, 0) AS VerificationAmount,
	|	VT_DiscountPercentageWithPackageData.CountPlan AS CountPlan,
	|	0 AS CountOfChecks,
	|	0 AS RangeFrom,
	|	0 AS RangeBy,
	|	0 AS RangeNumber,
	|	VT_DiscountPercentageWithPackageData.Currency AS Currency,
	|	&ExpressionAmountWithoutSpecification AS SalesAmount,
	|	&ExpressionSumWithVAT AS AmountOfTurnoverWithVAT,
	|	&ExpressionVATExclusive AS AmountOfTurnoverExcludingVAT,
	|	&ExpressionAmountWithoutSpecification AS CalculationBase
	|INTO TT_PreparedData
	|FROM
	|	VT_DiscountPercentageWithPackageData AS VT_DiscountPercentageWithPackageData
	|	LEFT JOIN VT_TurnoverByPeriodPackageConditionsAreMet AS VT_TurnoverByPeriodPackageConditionsAreMet
	|	ON  VT_DiscountPercentageWithPackageData.ConditionOfRebateBonusIs = VT_TurnoverByPeriodPackageConditionsAreMet.ConditionOfRebateBonusIs
	|		AND VT_DiscountPercentageWithPackageData.CalculationPeriod = VT_TurnoverByPeriodPackageConditionsAreMet.CalculationPeriod
	|		AND VT_DiscountPercentageWithPackageData.Organization = VT_TurnoverByPeriodPackageConditionsAreMet.Organization
	|		AND VT_DiscountPercentageWithPackageData.Currency = VT_TurnoverByPeriodPackageConditionsAreMet.Currency
	|		AND &ConnectionFieldsByParticipants
	|WHERE
	|	&ConditionForSelectingEmptyDocument";
	
	If OptionParameters.DetailingToItem Then
		ConditionForSelectingEmptyDocument = "TRUE";
	Else
		ConditionForSelectingEmptyDocument = "DocumentRecorder <> " + ValueOfEmptyLoggerReference(RebateConditionsParameters);
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionForSelectingEmptyDocument", ConditionForSelectingEmptyDocument);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		QueryText,
		"VT_DiscountPercentageWithPackageData",
		"VT_TurnoverByPeriodPackageConditionsAreMet");
	
	SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData");
	SubstituteAmountSelectionFieldWithVAT(RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData");
	SubstituteVATExclusiveAmountSelectionField(RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPreparedDataForPackageOffer(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_DiscountPercentageWithPackageData.Period AS Period,
	|	VT_DiscountPercentageWithPackageData.LineNumber AS LineNumber,
	|	VT_DiscountPercentageWithPackageData.CalculationPeriod AS CalculationPeriod,
	|	VT_DiscountPercentageWithPackageData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DiscountPercentageWithPackageData.GoodsIndicator AS GoodsIndicator,
	|	VT_DiscountPercentageWithPackageData.PartyCountDetails AS PartyCountDetails,
	|	VT_DiscountPercentageWithPackageData.AccrualFrequency AS AccrualFrequency,
	|	VT_DiscountPercentageWithPackageData.ConditionFrequency AS ConditionFrequency,
	|	VT_DiscountPercentageWithPackageData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_DiscountPercentageWithPackageData.FIFODistribution AS FIFODistribution,
	|	VT_DiscountPercentageWithPackageData.SumPlan AS SumPlan,
	|	VT_DiscountPercentageWithPackageData.DocumentRecorder AS DocumentRecorder,
	|	&PriorityExpression AS Priority,
	|	VT_DiscountPercentageWithPackageData.Organization AS Organization,
	|	&MemberFields,
	|	VT_DiscountPercentageWithPackageData.Contract AS Contract,
	|	VT_DiscountPercentageWithPackageData.Terms AS Terms,
	|	VT_DiscountPercentageWithPackageData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_DiscountPercentageWithPackageData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_DiscountPercentageWithPackageData.Products AS Products,
	|	VT_DiscountPercentageWithPackageData.UnitOfMeasure AS UnitOfMeasure,
	|	VT_DiscountPercentageWithPackageData.Characteristic AS Characteristic,
	|	VT_DiscountPercentageWithPackageData.PropertyValue AS PropertyValue,
	|	VT_DiscountPercentageWithPackageData.Count AS Count,
	|	VT_DiscountPercentageWithPackageData.BaseOfCalculation AS BaseOfCalculation,
	|	VT_DiscountPercentageWithPackageData.Currency AS Currency,
	|	VT_DiscountPercentageWithPackageData.BasePrice AS BasePrice,
	|	VT_DiscountPercentageWithPackageData.BonusPercent AS BonusPercent,
	|	VT_DiscountPercentageWithPackageData.StartDate AS StartDate,
	|	VT_DiscountPercentageWithPackageData.EndDate AS EndDate,
	|	VT_DiscountPercentageWithPackageData.CountPlan AS CountPlan,
	|	ISNULL(VT_NumberOfProductPackages.NumberOfPackages_, 0) AS NumberOfPackages_,
	|	ISNULL(VT_NumberOfProductPackages.NumberOfPackages_, 0) * VT_DiscountPercentageWithPackageData.CountPlan AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	0 AS VerificationAmount,
	|	ISNULL(VT_DiscountPercentageWithPackageData.Count, 0) AS CountOfChecks,
	|	(ISNULL(VT_NumberOfProductPackages.NumberOfPackages_, 0) > 0) AS PlanIsFulfilled,
	|	0 AS RangeFrom,
	|	0 AS RangeBy,
	|	0 AS RangeNumber,
	|	&ExpressionAmountWithoutSpecification AS SalesAmount,
	|	&ExpressionSumWithVAT AS AmountOfTurnoverWithVAT,
	|	&ExpressionVATExclusive AS AmountOfTurnoverExcludingVAT,
	|	&ExpressionAmountWithoutSpecification AS CalculationBase
	|INTO TT_PreparedData
	|FROM
	|	VT_DiscountPercentageWithPackageData AS VT_DiscountPercentageWithPackageData
	|		LEFT JOIN VT_NumberOfProductPackages AS VT_NumberOfProductPackages
	|		ON VT_DiscountPercentageWithPackageData.ConditionOfRebateBonusIs = VT_NumberOfProductPackages.ConditionOfRebateBonusIs
	|			AND VT_DiscountPercentageWithPackageData.CalculationPeriod = VT_NumberOfProductPackages.CalculationPeriod
	|			AND VT_DiscountPercentageWithPackageData.Organization = VT_NumberOfProductPackages.Organization
	|			AND VT_DiscountPercentageWithPackageData.Currency = VT_NumberOfProductPackages.Currency
	|			AND &ConnectionFieldsByParticipants
	|			AND &ExceedingLimitTable
	|WHERE
	|	&ConditionForSelectingEmptyDocument";
	
	If RebateConditionsParameters.DistributionByFIFO Then
		
		ExceedingLimitTable =
		"LEFT JOIN VT_ExceedingLimitTotal AS VT_ExceedingLimitTotal
		|		ON VT_DiscountPercentageWithPackageData.DocumentRecorder = VT_ExceedingLimitTotal.DocumentRecorder
		|			AND VT_DiscountPercentageWithPackageData.LineNumber = VT_ExceedingLimitTotal.LineNumber";
		PriorityExpression = "ISNULL(VT_ExceedingLimitTotal.Priority, -1)";
		
	Else
		
		ExceedingLimitTable = "";
		PriorityExpression = "-1";
		
	EndIf;
	
	If OptionParameters.DetailingToItem Then
		ConditionForSelectingEmptyDocument = "TRUE";
	Else
		ConditionForSelectingEmptyDocument = "VT_DiscountPercentageWithPackageData.DocumentRecorder <> " + ValueOfEmptyLoggerReference(RebateConditionsParameters);
	EndIf;
	QueryText = StrReplace(QueryText, "&ConditionForSelectingEmptyDocument", ConditionForSelectingEmptyDocument);
	
	QueryText = StrReplace(QueryText, "AND &ExceedingLimitTable", ExceedingLimitTable);
	QueryText = StrReplace(QueryText, "&PriorityExpression", PriorityExpression);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData", "VT_NumberOfProductPackages");
	
	SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData");
	SubstituteAmountSelectionFieldWithVAT(RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData");
	SubstituteVATExclusiveAmountSelectionField(RebateConditionsParameters, QueryText, "VT_DiscountPercentageWithPackageData");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	GoodsIndicator = RebateConditionsParameters.GoodsIndicator;
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator AS GoodsIndicator,
	|	TT_PreparedData.Period AS Period,
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.LineNumber AS LineNumber,
	|	TT_PreparedData.Organization AS Organization,
	|	&MemberFields,
	|	TT_PreparedData.Contract AS Contract,
	|	TT_PreparedData.Terms AS Terms,
	|	TT_PreparedData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_PreparedData.Products AS Products,
	|	TT_PreparedData.UnitOfMeasure AS UnitOfMeasure,
	|	TT_PreparedData.Characteristic AS Characteristic,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.PropertyValue AS PropertyValue,
	|	TT_PreparedData.PartyCountDetails AS PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency AS AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency AS ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_PreparedData.FIFODistribution AS FIFODistribution,
	|	TT_PreparedData.BaseOfCalculation AS BaseOfCalculation,
	|	TT_PreparedData.Currency AS Currency,
	|	&ExpressionIsOriginalQuantity AS Count,
	|	&ExpressionSalesAmount AS SalesAmount,
	|	&ExpressionSumTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	&ExpressionAmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	TT_PreparedData.CalculationBase AS CalculationBase,
	|	TT_PreparedData.VerificationAmount AS CalculationBaseOfEverything,
	|	TT_PreparedData.CountOfChecks AS TotalCount1,
	|	TT_PreparedData.BasePrice AS BasePrice,
	|	TT_PreparedData.BonusPercent AS BonusPercent,
	|	&ExpressionSumPlan AS SumPlan,
	|	TT_PreparedData.CountPlan AS CountPlan,
	|	&PriorityExpression AS Priority,
	|	TT_PreparedData.RangeFrom AS RangeFrom,
	|	TT_PreparedData.RangeBy AS RangeBy,
	|	&ExpressionSumIsCumulativeTotal AS CumulativeAmount,
	|	&ExpressionQuantityIsCumulativeTotal AS AmountIsCumulative,
	|	&ExpressionPlanIsCompleted AS PlanIsFulfilled,
	|	&ExpressionSoldPackages AS NumberOfPackages_,
	|	&ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales AS NumberOfPlansTakingIntoAccountMultiplicityOfSales
	|INTO VT_DataIncludingExceedingLimit
	|FROM
	|	&TablesSources AS TT_PreparedData";
	
	If RebateConditionsParameters.RestrictAccrualOverPlan
	 Or RebateConditionsParameters.CalculationScaleByRanges
	 Or GoodsIndicator = IndicatorsKinds.BatchOffer Then
		
		TablesSources =
		"TT_PreparedData AS TT_PreparedData
		|	LEFT JOIN VT_ExceedingLimitTotal AS VT_ExceedingLimitTotal
		|		ON TT_PreparedData.DocumentRecorder = VT_ExceedingLimitTotal.DocumentRecorder
		|			AND TT_PreparedData.LineNumber = VT_ExceedingLimitTotal.LineNumber";
		
		RightTable = "VT_ExceedingLimitTotal";
		
		PriorityExpression = "ISNULL(" + RightTable + ".Priority, -1)";
		ExpressionSumIsCumulativeTotal = "ISNULL(" + RightTable + ".Sum, 0)";
		ExpressionQuantityIsCumulativeTotal = "ISNULL(" + RightTable + ".Count, 0)";
		
		If GoodsIndicator = IndicatorsKinds.Sum Then
			ExpressionPlanIsCompleted = "(TT_PreparedData.VerificationAmount >= TT_PreparedData.SumPlan)";
		ElsIf GoodsIndicator = IndicatorsKinds.Count Then
			
			If RebateConditionsParameters.CalculationScaleByRanges
			   And RebateConditionsParameters.ProportionalDistribution Then
				ExpressionPlanIsCompleted = "(TT_PreparedData.CountOfChecks > 0)";
			Else
				ExpressionPlanIsCompleted = "(TT_PreparedData.CountOfChecks >= TT_PreparedData.CountPlan)";
			EndIf;
			
		ElsIf GoodsIndicator = IndicatorsKinds.QuantityTotal Then
			ExpressionPlanIsCompleted = "(TT_PreparedData.VerificationAmount > 0)";
		ElsIf GoodsIndicator = IndicatorsKinds.BatchOffer Then
			ExpressionPlanIsCompleted = "(TT_PreparedData.NumberOfPackages_ > 0)";
		Else
			ExpressionPlanIsCompleted = "TRUE";
		EndIf;
		
	Else
		
		TablesSources = "TT_PreparedData AS TT_PreparedData";
		RightTable = "";
		PriorityExpression = "0";
		ExpressionSumIsCumulativeTotal = "0";
		ExpressionQuantityIsCumulativeTotal = "0";
		
		If GoodsIndicator = IndicatorsKinds.Sum Then
			ExpressionPlanIsCompleted = "(TT_PreparedData.VerificationAmount >= TT_PreparedData.SumPlan)";
		ElsIf GoodsIndicator = IndicatorsKinds.Count Then
			ExpressionPlanIsCompleted = "(TT_PreparedData.CountOfChecks >= TT_PreparedData.CountPlan)";
		ElsIf GoodsIndicator = IndicatorsKinds.QuantityTotal Then
			ExpressionPlanIsCompleted = "(TT_PreparedData.VerificationAmount > 0)";
		ElsIf GoodsIndicator = IndicatorsKinds.BatchOffer Then
			ExpressionPlanIsCompleted = "(TT_PreparedData.NumberOfPackages_ > 0)";
		Else
			ExpressionPlanIsCompleted = "TRUE";
		EndIf;
		
	EndIf;
	
	If GoodsIndicator = IndicatorsKinds.BatchOffer Then
		
		ExpressionSoldPackages = "TT_PreparedData.NumberOfPackages_";
		ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales =
			"TT_PreparedData.NumberOfPackages_ * TT_PreparedData.CountPlan";
		
	Else
		
		ExpressionSoldPackages = "0";
		ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales = "0";
		
	EndIf;
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		If GoodsIndicator = IndicatorsKinds.Sum Then
			
			ExpressionSumPlan =
			"CASE
			|	WHEN TT_PreparedData.RangeBy = 0
			|		THEN TT_PreparedData.VerificationAmount - TT_PreparedData.RangeFrom
			|	WHEN TT_PreparedData.VerificationAmount <= TT_PreparedData.RangeBy
			|		THEN TT_PreparedData.VerificationAmount - TT_PreparedData.RangeFrom
			|	ELSE TT_PreparedData.RangeBy - TT_PreparedData.RangeFrom
			|END";
			
			ExpressionIsOriginalQuantity =
			"CASE
			|	WHEN TT_PreparedData.RangeFrom = 0
			|		THEN TT_PreparedData.Count
			|	ELSE 0
			|END";
			
		Else
			
			ExpressionSumPlan = "TT_PreparedData.SumPlan";
			ExpressionIsOriginalQuantity = "TT_PreparedData.Count";
			
		EndIf;
		
		ExpressionSalesAmount =
		"CASE
		|	WHEN TT_PreparedData.RangeFrom = 0
		|		THEN TT_PreparedData.SalesAmount
		|	ELSE 0
		|END";
		ExpressionSumTurnoverWithVAT =
		"CASE
		|	WHEN TT_PreparedData.RangeFrom = 0
		|		THEN TT_PreparedData.AmountOfTurnoverWithVAT
		|	ELSE 0
		|END";
		ExpressionAmountOfTurnoverExcludingVAT =
		"CASE
		|	WHEN TT_PreparedData.RangeFrom = 0
		|		THEN TT_PreparedData.AmountOfTurnoverExcludingVAT
		|	ELSE 0
		|END";
		
	Else
		
		ExpressionSumPlan = "TT_PreparedData.SumPlan";
		ExpressionIsOriginalQuantity = "TT_PreparedData.Count";
		ExpressionSalesAmount = "TT_PreparedData.SalesAmount";
		ExpressionSumTurnoverWithVAT = "TT_PreparedData.AmountOfTurnoverWithVAT";
		ExpressionAmountOfTurnoverExcludingVAT = "TT_PreparedData.AmountOfTurnoverExcludingVAT";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TablesSources AS TT_PreparedData", TablesSources);
	QueryText = StrReplace(QueryText, "&PriorityExpression", PriorityExpression);
	QueryText = StrReplace(QueryText, "&ExpressionSumIsCumulativeTotal", ExpressionSumIsCumulativeTotal);
	QueryText = StrReplace(QueryText, "&ExpressionQuantityIsCumulativeTotal", ExpressionQuantityIsCumulativeTotal);
	QueryText = StrReplace(QueryText, "&ExpressionSumPlan", ExpressionSumPlan);
	QueryText = StrReplace(QueryText, "&ExpressionIsOriginalQuantity", ExpressionIsOriginalQuantity);
	QueryText = StrReplace(QueryText, "&ExpressionSalesAmount", ExpressionSalesAmount);
	QueryText = StrReplace(QueryText, "&ExpressionSumTurnoverWithVAT", ExpressionSumTurnoverWithVAT);
	QueryText = StrReplace(QueryText, "&ExpressionAmountOfTurnoverExcludingVAT", ExpressionAmountOfTurnoverExcludingVAT);
	QueryText = StrReplace(QueryText, "&ExpressionPlanIsCompleted", ExpressionPlanIsCompleted);
	QueryText = StrReplace(QueryText, "&ExpressionSoldPackages", ExpressionSoldPackages);
	QueryText = StrReplace(
		QueryText, "&ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales", ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "TT_PreparedData", RightTable);
	SubstituteFieldsForGoods(
		RebateConditionsParameters, QueryText, "TT_PreparedData", RightTable);
	SubstituteRangeNumberField(RebateConditionsParameters, QueryText, "TT_PreparedData");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDataWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	If RebateConditionsParameters.RestrictAccrualOverPlan Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	VT_DataIncludingExceedingLimit.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DataIncludingExceedingLimit.GoodsIndicator AS GoodsIndicator,
	|	VT_DataIncludingExceedingLimit.Period AS Period,
	|	VT_DataIncludingExceedingLimit.CalculationPeriod AS CalculationPeriod,
	|	VT_DataIncludingExceedingLimit.DocumentRecorder AS DocumentRecorder,
	|	VT_DataIncludingExceedingLimit.LineNumber AS LineNumber,
	|	VT_DataIncludingExceedingLimit.Organization AS Organization,
	|	&MemberFields,
	|	VT_DataIncludingExceedingLimit.Contract AS Contract,
	|	VT_DataIncludingExceedingLimit.Terms AS Terms,
	|	VT_DataIncludingExceedingLimit.Products AS Products,
	|	VT_DataIncludingExceedingLimit.UnitOfMeasure AS UnitOfMeasure,
	|	VT_DataIncludingExceedingLimit.Characteristic AS Characteristic,
	|	VT_DataIncludingExceedingLimit.PropertyValue AS PropertyValue,
	|	VT_DataIncludingExceedingLimit.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_DataIncludingExceedingLimit.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_DataIncludingExceedingLimit.PartyCountDetails AS PartyCountDetails,
	|	VT_DataIncludingExceedingLimit.AccrualFrequency AS AccrualFrequency,
	|	VT_DataIncludingExceedingLimit.ConditionFrequency AS ConditionFrequency,
	|	VT_DataIncludingExceedingLimit.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_DataIncludingExceedingLimit.BaseOfCalculation AS BaseOfCalculation,
	|	VT_DataIncludingExceedingLimit.Currency AS Currency,
	|	VT_DataIncludingExceedingLimit.SalesAmount AS SalesAmount,
	|	VT_DataIncludingExceedingLimit.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	VT_DataIncludingExceedingLimit.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	VT_DataIncludingExceedingLimit.Count AS Count,
	|	VT_DataIncludingExceedingLimit.BonusPercent AS BonusPercent,
	|	VT_DataIncludingExceedingLimit.BasePrice AS BasePrice,
	|	VT_DataIncludingExceedingLimit.SumPlan AS SumPlan,
	|	VT_DataIncludingExceedingLimit.CountPlan AS CountPlan,
	|	VT_DataIncludingExceedingLimit.PlanIsFulfilled AS PlanIsFulfilled,
	|	CASE
	|		WHEN VT_DataIncludingExceedingLimit.PlanIsFulfilled
	|			THEN VT_DataIncludingExceedingLimit.Count
	|		ELSE 0
	|	END AS AmountToCalculateBonus,
	|	CASE
	|		WHEN VT_DataIncludingExceedingLimit.PlanIsFulfilled
	|			THEN 
	|				VT_DataIncludingExceedingLimit.SalesAmount
	|		ELSE 0
	|	END AS CalculationBase,
	|	CAST(CASE
	|		WHEN VT_DataIncludingExceedingLimit.PlanIsFulfilled
	|			THEN 
	|				VT_DataIncludingExceedingLimit.SalesAmount
	|		ELSE 0
	|	END * VT_DataIncludingExceedingLimit.BonusPercent / 100 AS NUMBER(31, 2)) AS AmountBonus
	|INTO VT_DataWithoutProhibitionOfExceeding
	|FROM
	|	VT_DataIncludingExceedingLimit AS VT_DataIncludingExceedingLimit";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_DataIncludingExceedingLimit");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	SourceTable1.Organization AS Organization,
	|	SourceTable1.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	MAX(SourceTable1.Priority) AS MaximumPriority
	|INTO TT_RoundingPriority
	|FROM
	|	&SourceTable1 AS SourceTable1
	|WHERE
	|	SourceTable1.PlanIsFulfilled
	|	AND SourceTable1.CalculationBase > 0
	|
	|GROUP BY
	|	SourceTable1.CalculationPeriod,
	|	SourceTable1.ConditionOfRebateBonusIs,
	|	&GroupingFieldRangeNumber,
	|	SourceTable1.Organization,
	|	SourceTable1.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields";
	
	If RebateConditionsParameters.DistributionByFIFO Then
		
		If (RebateConditionsParameters.GoodsIndicator = TargetValues.Count
		 Or RebateConditionsParameters.GoodsIndicator = TargetValues.BatchOffer) Then
			SourceTable1 = "VT_DataForDistributionByFIFOBonusAmount";
		Else
			SourceTable1 = "VT_DataForDistributionByFIFO";
		EndIf;
		
	Else
		SourceTable1 = "VT_DataForProportionalDistribution";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteRangeNumberField(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextOfMinimumPriorityForExecutionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	If Not RebateConditionsParameters.RestrictAccrualOverPlan
	 Or Not RebateConditionsParameters.DistributionByFIFO Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.Organization AS Organization,
	|	&MemberFields,
	|	SourceTable1.Currency AS Currency,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	MIN(SourceTable1.Priority) AS Priority
	|INTO VT_MinimumPriorityOfPlanExecution
	|FROM
	|	VT_ExceedingLimitCumulativeTotal AS SourceTable1
	|WHERE
	|	SourceTable1.Sum >= SourceTable1.SumPlan
	|
	|GROUP BY
	|	SourceTable1.ConditionOfRebateBonusIs,
	|	SourceTable1.Organization,
	|	&GroupingFieldsByParticipants,
	|	SourceTable1.Currency,
	|	SourceTable1.CalculationPeriod";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See ParametersOfTermsOfRebatesForCustomers
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDataForDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator AS GoodsIndicator,
	|	TT_PreparedData.Period AS Period,
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	0 AS RangeNumber,
	|	0 AS RangeFrom,
	|	0 AS RangeBy,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.LineNumber AS LineNumber,
	|	TT_PreparedData.Organization AS Organization,
	|	&MemberFields,
	|	TT_PreparedData.Contract AS Contract,
	|	TT_PreparedData.Terms AS Terms,
	|	TT_PreparedData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_PreparedData.Products AS Products,
	|	TT_PreparedData.UnitOfMeasure AS UnitOfMeasure,
	|	TT_PreparedData.Characteristic AS Characteristic,
	|	TT_PreparedData.PropertyValue AS PropertyValue,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.PartyCountDetails AS PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency AS AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency AS ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_PreparedData.BaseOfCalculation AS BaseOfCalculation,
	|	TT_PreparedData.Currency AS Currency,
	|	TT_PreparedData.Count AS Count,
	|	TT_PreparedData.SalesAmount AS SalesAmount,
	|	TT_PreparedData.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	TT_PreparedData.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	TT_PreparedData.BonusPercent AS BonusPercent,
	|	TT_PreparedData.BasePrice AS BasePrice,
	|	TT_PreparedData.SumPlan AS SumPlan,
	|	&ExpressionNumberOfOriginalPlan AS CountPlan,
	|	&ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	&ExpressionQuantityForCalculatingBonus AS AmountToCalculateBonus,
	|	&ExpressionSumIsCumulativeTotal AS CumulativeAmount,
	|	&ExpressionQuantityIsCumulativeTotal AS AmountIsCumulative,
	|	TT_PreparedData.PlanIsFulfilled AS PlanIsFulfilled,
	|	TT_PreparedData.Priority AS Priority,
	|	ISNULL(VT_MinimumPriorityOfPlanExecution.Priority, -1) AS MinPriority,
	|	&ExpressionNumberOfPackets AS NumberOfPackages_,
	|	&ExpressionCalculationBase AS CalculationBase,
	|	&ExpressionBonusAmountByLine AS AmountBonus,
	|	&ExpressionAmountBonusTotal AS TotalBonusAmount
	|INTO VT_DataForDistributionByFIFO
	|FROM
	|	TT_PreparedData AS TT_PreparedData
	|		LEFT JOIN VT_MinimumPriorityOfPlanExecution AS VT_MinimumPriorityOfPlanExecution
	|		ON TT_PreparedData.Currency = VT_MinimumPriorityOfPlanExecution.Currency
	|			AND TT_PreparedData.CalculationPeriod = VT_MinimumPriorityOfPlanExecution.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		QueryText,
		"TT_PreparedData",
		"VT_MinimumPriorityOfPlanExecution");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		QueryText,
		"TT_PreparedData",
		"VT_MinimumPriorityOfPlanExecution");
	
	TextOfConnectionIsCumulativeResult = "
	|	LEFT JOIN VT_ExceedingLimitCumulativeTotal AS VT_ExceedingLimitCumulativeTotal
	|		ON TT_PreparedData.Currency = VT_ExceedingLimitCumulativeTotal.Currency
	|			AND TT_PreparedData.CalculationPeriod = VT_ExceedingLimitCumulativeTotal.CalculationPeriod
	|			AND TT_PreparedData.Priority = VT_ExceedingLimitCumulativeTotal.Priority
	|			AND &ConnectionFieldsByGoods
	|			AND &ConnectionFieldsByParticipants";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfConnectionIsCumulativeResult,
		"TT_PreparedData",
		"VT_ExceedingLimitCumulativeTotal");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		TextOfConnectionIsCumulativeResult,
		"TT_PreparedData",
		"VT_ExceedingLimitCumulativeTotal");
	
	QueryText = QueryText + TextOfConnectionIsCumulativeResult;
	
	If RebateConditionsParameters.GoodsIndicator = TargetValues.Sum Then
		
		ExpressionNumberOfOriginalPlan = "0";
		ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales = "0";
		ExpressionQuantityForCalculatingBonus = "0";
		ExpressionCalculationBase = "CASE
		|		WHEN NOT TT_PreparedData.PlanIsFulfilled
		|			THEN 0
		|		WHEN TT_PreparedData.Priority > ISNULL(VT_MinimumPriorityOfPlanExecution.Priority, -1)
		|			THEN 0
		|		WHEN ISNULL(VT_ExceedingLimitCumulativeTotal.Sum, 0) <= TT_PreparedData.SumPlan
		|			THEN TT_PreparedData.CalculationBase
		|		ELSE TT_PreparedData.CalculationBase - (ISNULL(VT_ExceedingLimitCumulativeTotal.Sum, 0) - TT_PreparedData.SumPlan)
		|	END";
		ExpressionBonusAmountByLine = "CAST(CASE
		|			WHEN NOT TT_PreparedData.PlanIsFulfilled
		|				THEN 0
		|			WHEN TT_PreparedData.Priority > ISNULL(VT_MinimumPriorityOfPlanExecution.Priority, -1)
		|				THEN 0
		|			WHEN ISNULL(VT_ExceedingLimitCumulativeTotal.Sum, 0) <= TT_PreparedData.SumPlan
		|				THEN TT_PreparedData.CalculationBase
		|			ELSE TT_PreparedData.CalculationBase - (ISNULL(VT_ExceedingLimitCumulativeTotal.Sum, 0) - TT_PreparedData.SumPlan)
		|		END * TT_PreparedData.BonusPercent / 100 AS NUMBER(31, 2))";
		ExpressionAmountBonusTotal = "CAST(TT_PreparedData.SumPlan
		|	* TT_PreparedData.BonusPercent / 100 AS NUMBER(31, 2))";
		ExpressionSumIsCumulativeTotal = "ISNULL(VT_ExceedingLimitCumulativeTotal.Sum, 0)";
		ExpressionQuantityIsCumulativeTotal = "0";
		ExpressionNumberOfPackets = "0";
		
	ElsIf RebateConditionsParameters.GoodsIndicator = TargetValues.Count Then
		
		ExpressionNumberOfOriginalPlan = "TT_PreparedData.CountPlan";
		ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales = "VT_ExceedingLimitCumulativeTotal.NumberOfPlansTakingIntoAccountMultiplicityOfSales";
		ExpressionQuantityForCalculatingBonus = "CASE
		|		WHEN TT_PreparedData.PlanIsFulfilled
		|		AND TT_PreparedData.Priority <= ISNULL(VT_MinimumPriorityOfPlanExecution.Priority, -1)
		|			THEN CASE
		|				WHEN ISNULL(VT_ExceedingLimitCumulativeTotal.Count, 0) <= TT_PreparedData.CountPlan
		|					THEN TT_PreparedData.Count
		|				WHEN TT_PreparedData.Count - (ISNULL(VT_ExceedingLimitCumulativeTotal.Count, 0) - TT_PreparedData.CountPlan) < 0
		|					THEN 0
		|				ELSE TT_PreparedData.Count - (ISNULL(VT_ExceedingLimitCumulativeTotal.Count, 0) - TT_PreparedData.CountPlan)
		|			END
		|		ELSE 0
		|	END";
		ExpressionCalculationBase = "TT_PreparedData.CalculationBase";
		ExpressionBonusAmountByLine = "0";
		ExpressionAmountBonusTotal = "0";
		ExpressionSumIsCumulativeTotal = "0";
		ExpressionQuantityIsCumulativeTotal = "ISNULL(VT_ExceedingLimitCumulativeTotal.Count, 0)";
		ExpressionNumberOfPackets = "0";
		
	ElsIf RebateConditionsParameters.GoodsIndicator = TargetValues.BatchOffer Then
		
		ExpressionNumberOfOriginalPlan = "TT_PreparedData.CountPlan";
		ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales = "VT_ExceedingLimitCumulativeTotal.NumberOfPlansTakingIntoAccountMultiplicityOfSales";
		ExpressionQuantityForCalculatingBonus = "CASE
		|		WHEN TT_PreparedData.PlanIsFulfilled
		|		AND TT_PreparedData.Priority <= ISNULL(VT_MinimumPriorityOfPlanExecution.Priority, -1)
		|			THEN CASE
		|				WHEN ISNULL(VT_ExceedingLimitCumulativeTotal.Count, 0) <= TT_PreparedData.NumberOfPlansTakingIntoAccountMultiplicityOfSales
		|					THEN TT_PreparedData.Count
		|				WHEN TT_PreparedData.Count - (ISNULL(VT_ExceedingLimitCumulativeTotal.Count, 0) - TT_PreparedData.NumberOfPlansTakingIntoAccountMultiplicityOfSales) < 0
		|					THEN 0
		|				ELSE TT_PreparedData.Count - (ISNULL(VT_ExceedingLimitCumulativeTotal.Count, 0) - TT_PreparedData.NumberOfPlansTakingIntoAccountMultiplicityOfSales)
		|			END
		|		ELSE 0
		|	END";
		ExpressionCalculationBase = "TT_PreparedData.CalculationBase";
		ExpressionBonusAmountByLine = "0";
		ExpressionAmountBonusTotal = "0";
		ExpressionSumIsCumulativeTotal = "0";
		ExpressionQuantityIsCumulativeTotal = "ISNULL(VT_ExceedingLimitCumulativeTotal.Count, 0)";
		ExpressionNumberOfPackets = "TT_PreparedData.NumberOfPackages_";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Chưa xác định chỉ tiêu hàng hóa (""%1"") đối với chứng từ ""%2""';
							|ru = 'Не удалось определить показатель товаров (""%1"") для документа ""%2""';
							|en = 'Cannot determine the goods indicator (%1) for the %2 document'; fa = 'Cannot determine the goods indicator (%1) for the %2 document';
							|it = 'Не удалось определить показатель товаров (""%1"") для документа ""%2""';
							|pl = 'Cannot determine the goods indicator (%1) for the %2 document';
							|tr = 'Belge ""%2"" için satış hedefi (""%1"") tanımlanamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.GoodsIndicatorPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ExpressionNumberOfOriginalPlan", ExpressionNumberOfOriginalPlan);
	QueryText = StrReplace(QueryText, "&ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales", ExpressionQuantityPlanTakingIntoAccountMultiplicityOfSales);
	QueryText = StrReplace(QueryText, "&ExpressionQuantityForCalculatingBonus", ExpressionQuantityForCalculatingBonus);
	QueryText = StrReplace(QueryText, "&ExpressionCalculationBase", ExpressionCalculationBase);
	QueryText = StrReplace(QueryText, "&ExpressionBonusAmountByLine", ExpressionBonusAmountByLine);
	QueryText = StrReplace(QueryText, "&ExpressionAmountBonusTotal", ExpressionAmountBonusTotal);
	QueryText = StrReplace(QueryText, "&ExpressionSumIsCumulativeTotal", ExpressionSumIsCumulativeTotal);
	QueryText = StrReplace(QueryText, "&ExpressionQuantityIsCumulativeTotal", ExpressionQuantityIsCumulativeTotal);
	QueryText = StrReplace(QueryText, "&ExpressionNumberOfPackets", ExpressionNumberOfPackets);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextRoundingDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	SourceTable1.Organization AS Organization,
	|	&MemberFields,
	|	&ProductFields,
	|	ISNULL(TT_RoundingPriority.MaximumPriority, -1) AS MaximumPriority,
	|	SUM(CASE
	|			WHEN SourceTable1.Priority = ISNULL(TT_RoundingPriority.MaximumPriority, -1)
	|				THEN 0
	|			ELSE SourceTable1.CalculationBase
	|		END) AS CalculationBaseExceptMaximumPriority,
	|	SUM(CASE
	|			WHEN SourceTable1.Priority = ISNULL(TT_RoundingPriority.MaximumPriority, -1)
	|				THEN 0
	|			ELSE SourceTable1.AmountBonus
	|		END) AS BonusAmountExceptMaximumPriority
	|INTO VT_RoundingUpFIFODistribution
	|FROM
	|	&SourceTable1 AS SourceTable1
	|	LEFT JOIN TT_RoundingPriority AS TT_RoundingPriority
	|	ON SourceTable1.CalculationPeriod = TT_RoundingPriority.CalculationPeriod
	|		AND SourceTable1.ConditionOfRebateBonusIs = TT_RoundingPriority.ConditionOfRebateBonusIs
	|		AND SourceTable1.Organization = TT_RoundingPriority.Organization
	|		AND &ConnectionFieldsByParticipants
	|		AND &ConnectionFieldsByGoods
	|		AND &ConnectionFieldRangeNumber
	|
	|GROUP BY
	|	SourceTable1.CalculationPeriod,
	|	SourceTable1.ConditionOfRebateBonusIs,
	|	&GroupingFieldRangeNumber,
	|	SourceTable1.Organization,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	TT_RoundingPriority.MaximumPriority";
	
	If (RebateConditionsParameters.GoodsIndicator = TargetValues.Count
	 Or RebateConditionsParameters.GoodsIndicator = TargetValues.BatchOffer) Then
		SourceTable1 = "VT_DataForDistributionByFIFOBonusAmount";
	Else
		SourceTable1 = "VT_DataForDistributionByFIFO";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	
	SubstituteFieldsByParticipants(	RebateConditionsParameters, QueryText, "SourceTable1", "TT_RoundingPriority");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1", "TT_RoundingPriority");
	SubstituteRangeNumberField(RebateConditionsParameters, QueryText, "SourceTable1", "TT_RoundingPriority");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextFinalFIFODistributionByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_DataForDistributionByFIFO.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DataForDistributionByFIFO.GoodsIndicator AS GoodsIndicator,
	|	VT_DataForDistributionByFIFO.Period AS Period,
	|	VT_DataForDistributionByFIFO.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	VT_DataForDistributionByFIFO.RangeFrom AS RangeFrom,
	|	VT_DataForDistributionByFIFO.RangeBy AS RangeBy,
	|	VT_DataForDistributionByFIFO.DocumentRecorder AS DocumentRecorder,
	|	VT_DataForDistributionByFIFO.LineNumber AS LineNumber,
	|	VT_DataForDistributionByFIFO.Organization AS Organization,
	|	&MemberFields,
	|	VT_DataForDistributionByFIFO.Contract AS Contract,
	|	VT_DataForDistributionByFIFO.Terms AS Terms,
	|	VT_DataForDistributionByFIFO.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_DataForDistributionByFIFO.Products AS Products,
	|	VT_DataForDistributionByFIFO.UnitOfMeasure AS UnitOfMeasure,
	|	VT_DataForDistributionByFIFO.Characteristic AS Characteristic,
	|	VT_DataForDistributionByFIFO.PropertyValue AS PropertyValue,
	|	VT_DataForDistributionByFIFO.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_DataForDistributionByFIFO.PartyCountDetails AS PartyCountDetails,
	|	VT_DataForDistributionByFIFO.AccrualFrequency AS AccrualFrequency,
	|	VT_DataForDistributionByFIFO.ConditionFrequency AS ConditionFrequency,
	|	VT_DataForDistributionByFIFO.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_DataForDistributionByFIFO.Currency AS Currency,
	|	VT_DataForDistributionByFIFO.Count AS Count,
	|	VT_DataForDistributionByFIFO.SalesAmount AS SalesAmount,
	|	VT_DataForDistributionByFIFO.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	VT_DataForDistributionByFIFO.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	VT_DataForDistributionByFIFO.BonusPercent AS BonusPercent,
	|	VT_DataForDistributionByFIFO.BasePrice AS BasePrice,
	|	VT_DataForDistributionByFIFO.SumPlan AS SumPlan,
	|	VT_DataForDistributionByFIFO.PlanIsFulfilled AS PlanIsFulfilled,
	|	CASE
	|		WHEN VT_DataForDistributionByFIFO.Priority = ISNULL(VT_RoundingUpFIFODistribution.MaximumPriority, -1)
	|			THEN VT_DataForDistributionByFIFO.SumPlan - ISNULL(VT_RoundingUpFIFODistribution.CalculationBaseExceptMaximumPriority, 0)
	|		ELSE VT_DataForDistributionByFIFO.CalculationBase
	|	END AS CalculationBase,
	|	0 AS CountPlan,
	|	VT_DataForDistributionByFIFO.Count AS AmountToCalculateBonus,
	|	CASE
	|		WHEN VT_DataForDistributionByFIFO.Priority = ISNULL(VT_RoundingUpFIFODistribution.MaximumPriority, -1)
	|			THEN VT_DataForDistributionByFIFO.TotalBonusAmount - ISNULL(VT_RoundingUpFIFODistribution.BonusAmountExceptMaximumPriority, 0)
	|		ELSE VT_DataForDistributionByFIFO.AmountBonus
	|	END AS AmountBonus,
	|	0 AS NumberOfPackages_
	|INTO VT_FinalDistributionByFIFO
	|FROM
	|	VT_DataForDistributionByFIFO AS VT_DataForDistributionByFIFO
	|	LEFT JOIN VT_RoundingUpFIFODistribution AS VT_RoundingUpFIFODistribution
	|	ON VT_DataForDistributionByFIFO.CalculationPeriod = VT_RoundingUpFIFODistribution.CalculationPeriod
	|		AND &ConnectionFieldRangeNumber
	|		AND VT_DataForDistributionByFIFO.ConditionOfRebateBonusIs = VT_RoundingUpFIFODistribution.ConditionOfRebateBonusIs
	|		AND VT_DataForDistributionByFIFO.Organization = VT_RoundingUpFIFODistribution.Organization
	|		AND &ConnectionFieldsByParticipants";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForDistributionByFIFO",
		"VT_RoundingUpFIFODistribution");
	SubstituteRangeNumberField(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForDistributionByFIFO",
		"VT_RoundingUpFIFODistribution");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextMinimumPriorityOfPlanExecutionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	SourceTable1.Organization AS Organization,
	|	SourceTable1.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	MIN(SourceTable1.Priority) AS Priority
	|INTO VT_MinimumPriorityOfPlanExecution
	|FROM
	|	VT_ExceedingLimitCumulativeTotal AS SourceTable1
	|WHERE
	|	&Expression_Condition
	|
	|GROUP BY
	|	SourceTable1.ConditionOfRebateBonusIs,
	|	SourceTable1.CalculationPeriod,
	|	SourceTable1.Organization,
	|	SourceTable1.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields";
	
	If RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.BatchOffer Then
		Expression_Condition = "SourceTable1.Count >= SourceTable1.NumberOfPlansTakingIntoAccountMultiplicityOfSales";
	Else
		Expression_Condition = "SourceTable1.Count >= SourceTable1.CountPlan";
	EndIf;
	QueryText = StrReplace(QueryText, "&Expression_Condition", Expression_Condition);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDataForDistributionByFIFOBonusAmountByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_DataForDistributionByFIFO.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DataForDistributionByFIFO.GoodsIndicator AS GoodsIndicator,
	|	VT_DataForDistributionByFIFO.Period AS Period,
	|	VT_DataForDistributionByFIFO.CalculationPeriod AS CalculationPeriod,
	|	VT_DataForDistributionByFIFO.RangeNumber AS RangeNumber,
	|	VT_DataForDistributionByFIFO.RangeFrom AS RangeFrom,
	|	VT_DataForDistributionByFIFO.RangeBy AS RangeBy,
	|	VT_DataForDistributionByFIFO.DocumentRecorder AS DocumentRecorder,
	|	VT_DataForDistributionByFIFO.LineNumber AS LineNumber,
	|	VT_DataForDistributionByFIFO.Organization AS Organization,
	|	&MemberFields,
	|	VT_DataForDistributionByFIFO.Contract AS Contract,
	|	VT_DataForDistributionByFIFO.Terms AS Terms,
	|	VT_DataForDistributionByFIFO.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_DataForDistributionByFIFO.Products AS Products,
	|	VT_DataForDistributionByFIFO.UnitOfMeasure AS UnitOfMeasure,
	|	VT_DataForDistributionByFIFO.Characteristic AS Characteristic,
	|	VT_DataForDistributionByFIFO.PropertyValue AS PropertyValue,
	|	VT_DataForDistributionByFIFO.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_DataForDistributionByFIFO.PartyCountDetails AS PartyCountDetails,
	|	VT_DataForDistributionByFIFO.AccrualFrequency AS AccrualFrequency,
	|	VT_DataForDistributionByFIFO.ConditionFrequency AS ConditionFrequency,
	|	VT_DataForDistributionByFIFO.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_DataForDistributionByFIFO.BaseOfCalculation AS BaseOfCalculation,
	|	VT_DataForDistributionByFIFO.Currency AS Currency,
	|	VT_DataForDistributionByFIFO.Count AS Count,
	|	VT_DataForDistributionByFIFO.SalesAmount AS SalesAmount,
	|	VT_DataForDistributionByFIFO.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	VT_DataForDistributionByFIFO.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	VT_DataForDistributionByFIFO.BonusPercent AS BonusPercent,
	|	VT_DataForDistributionByFIFO.BasePrice AS BasePrice,
	|	VT_DataForDistributionByFIFO.SumPlan AS SumPlan,
	|	VT_DataForDistributionByFIFO.PlanIsFulfilled AS PlanIsFulfilled,
	|	VT_DataForDistributionByFIFO.Priority AS Priority,
	|	VT_DataForDistributionByFIFO.CountPlan AS CountPlan,
	|	VT_DataForDistributionByFIFO.AmountToCalculateBonus AS AmountToCalculateBonus,
	|	VT_DataForDistributionByFIFO.NumberOfPackages_ AS NumberOfPackages_,
	|	CASE
	|		WHEN VT_DataForDistributionByFIFO.AmountToCalculateBonus = 0
	|			THEN CASE
	|				WHEN VT_DataForDistributionByFIFO.PlanIsFulfilled
	|					AND VT_DataForDistributionByFIFO.Count = 0
	|					AND VT_DataForDistributionByFIFO.BaseOfCalculation <> VALUE(Enum.RebateCalculationBases.RevenueBasePrices)
	|					AND VT_DataForDistributionByFIFO.BaseOfCalculation <> VALUE(Enum.RebateCalculationBases.PurchaseAmountBasePrices)
	|					AND VT_DataForDistributionByFIFO.Priority <= VT_DataForDistributionByFIFO.MinPriority
	|					THEN VT_DataForDistributionByFIFO.CalculationBase
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN VT_DataForDistributionByFIFO.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.RevenueBasePrices)
	|				OR VT_DataForDistributionByFIFO.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.PurchaseAmountBasePrices)
	|				THEN CAST(VT_DataForDistributionByFIFO.AmountToCalculateBonus * VT_DataForDistributionByFIFO.BasePrice AS NUMBER(31, 2))
	|			WHEN VT_DataForDistributionByFIFO.AmountToCalculateBonus = VT_DataForDistributionByFIFO.Count
	|				THEN VT_DataForDistributionByFIFO.CalculationBase
	|			ELSE CAST(VT_DataForDistributionByFIFO.CalculationBase * VT_DataForDistributionByFIFO.AmountToCalculateBonus / VT_DataForDistributionByFIFO.Count AS NUMBER(31, 2))
	|		END
	|	END AS CalculationBase,
	|	CASE
	|		WHEN VT_DataForDistributionByFIFO.AmountToCalculateBonus = 0
	|			THEN CASE
	|				WHEN VT_DataForDistributionByFIFO.PlanIsFulfilled
	|					AND VT_DataForDistributionByFIFO.Count = 0
	|					AND VT_DataForDistributionByFIFO.BaseOfCalculation <> VALUE(Enum.RebateCalculationBases.RevenueBasePrices)
	|					AND VT_DataForDistributionByFIFO.BaseOfCalculation <> VALUE(Enum.RebateCalculationBases.PurchaseAmountBasePrices)
	|					AND VT_DataForDistributionByFIFO.Priority <= VT_DataForDistributionByFIFO.MinPriority
	|					THEN CAST(VT_DataForDistributionByFIFO.CalculationBase * VT_DataForDistributionByFIFO.BonusPercent / 100 AS NUMBER(31, 2))
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN VT_DataForDistributionByFIFO.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.RevenueBasePrices)
	|				OR VT_DataForDistributionByFIFO.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.PurchaseAmountBasePrices)
	|				THEN CAST(VT_DataForDistributionByFIFO.AmountToCalculateBonus * VT_DataForDistributionByFIFO.BasePrice * VT_DataForDistributionByFIFO.BonusPercent / 100 AS NUMBER(31, 2))
	|			WHEN VT_DataForDistributionByFIFO.AmountToCalculateBonus = VT_DataForDistributionByFIFO.Count
	|				THEN CAST(VT_DataForDistributionByFIFO.CalculationBase * VT_DataForDistributionByFIFO.BonusPercent / 100 AS NUMBER(31, 2))
	|			ELSE CAST(VT_DataForDistributionByFIFO.CalculationBase * VT_DataForDistributionByFIFO.AmountToCalculateBonus * VT_DataForDistributionByFIFO.BonusPercent / 100 / VT_DataForDistributionByFIFO.Count AS NUMBER(31, 2))
	|		END
	|	END AS AmountBonus,
	|	CAST(VT_DataForDistributionByFIFO.NumberOfPlansTakingIntoAccountMultiplicityOfSales * VT_DataForDistributionByFIFO.BasePrice * VT_DataForDistributionByFIFO.BonusPercent / 100 AS NUMBER(31, 2)) AS TotalBonusAmount
	|INTO VT_DataForDistributionByFIFOBonusAmount
	|FROM
	|	VT_DataForDistributionByFIFO AS VT_DataForDistributionByFIFO";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForDistributionByFIFO");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextFinalFIFODistributionByNumber(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_DataForDistributionByFIFOBonusAmount.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DataForDistributionByFIFOBonusAmount.GoodsIndicator AS GoodsIndicator,
	|	VT_DataForDistributionByFIFOBonusAmount.Period AS Period,
	|	VT_DataForDistributionByFIFOBonusAmount.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	VT_DataForDistributionByFIFOBonusAmount.RangeFrom AS RangeFrom,
	|	VT_DataForDistributionByFIFOBonusAmount.RangeBy AS RangeBy,
	|	VT_DataForDistributionByFIFOBonusAmount.DocumentRecorder AS DocumentRecorder,
	|	VT_DataForDistributionByFIFOBonusAmount.LineNumber AS LineNumber,
	|	VT_DataForDistributionByFIFOBonusAmount.Organization AS Organization,
	|	&MemberFields,
	|	VT_DataForDistributionByFIFOBonusAmount.Contract AS Contract,
	|	VT_DataForDistributionByFIFOBonusAmount.Terms AS Terms,
	|	VT_DataForDistributionByFIFOBonusAmount.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_DataForDistributionByFIFOBonusAmount.Products AS Products,
	|	VT_DataForDistributionByFIFOBonusAmount.UnitOfMeasure AS UnitOfMeasure,
	|	VT_DataForDistributionByFIFOBonusAmount.Characteristic AS Characteristic,
	|	VT_DataForDistributionByFIFOBonusAmount.PropertyValue AS PropertyValue,
	|	VT_DataForDistributionByFIFOBonusAmount.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_DataForDistributionByFIFOBonusAmount.PartyCountDetails AS PartyCountDetails,
	|	VT_DataForDistributionByFIFOBonusAmount.AccrualFrequency AS AccrualFrequency,
	|	VT_DataForDistributionByFIFOBonusAmount.ConditionFrequency AS ConditionFrequency,
	|	VT_DataForDistributionByFIFOBonusAmount.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_DataForDistributionByFIFOBonusAmount.BaseOfCalculation AS BaseOfCalculation,
	|	VT_DataForDistributionByFIFOBonusAmount.Currency AS Currency,
	|	VT_DataForDistributionByFIFOBonusAmount.Count AS Count,
	|	VT_DataForDistributionByFIFOBonusAmount.SalesAmount AS SalesAmount,
	|	VT_DataForDistributionByFIFOBonusAmount.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	VT_DataForDistributionByFIFOBonusAmount.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	VT_DataForDistributionByFIFOBonusAmount.BonusPercent AS BonusPercent,
	|	VT_DataForDistributionByFIFOBonusAmount.BasePrice AS BasePrice,
	|	VT_DataForDistributionByFIFOBonusAmount.SumPlan AS SumPlan,
	|	VT_DataForDistributionByFIFOBonusAmount.PlanIsFulfilled AS PlanIsFulfilled,
	|	VT_DataForDistributionByFIFOBonusAmount.CountPlan AS CountPlan,
	|	VT_DataForDistributionByFIFOBonusAmount.AmountToCalculateBonus AS AmountToCalculateBonus,
	|	VT_DataForDistributionByFIFOBonusAmount.NumberOfPackages_ AS NumberOfPackages_,
	|	VT_DataForDistributionByFIFOBonusAmount.CalculationBase AS CalculationBase,
	|	CASE
	|		WHEN VT_DataForDistributionByFIFOBonusAmount.Priority = ISNULL(VT_RoundingUpFIFODistribution.MaximumPriority, -1)
	|			AND (VT_DataForDistributionByFIFOBonusAmount.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.RevenueBasePrices)
	|				OR VT_DataForDistributionByFIFOBonusAmount.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.PurchaseAmountBasePrices)
	|			)
	|			THEN VT_DataForDistributionByFIFOBonusAmount.TotalBonusAmount - ISNULL(VT_RoundingUpFIFODistribution.BonusAmountExceptMaximumPriority, 0)
	|		ELSE VT_DataForDistributionByFIFOBonusAmount.AmountBonus
	|	END AS AmountBonus
	|INTO VT_FinalDistributionByFIFO
	|FROM
	|	VT_DataForDistributionByFIFOBonusAmount AS VT_DataForDistributionByFIFOBonusAmount
	|	LEFT JOIN VT_RoundingUpFIFODistribution AS VT_RoundingUpFIFODistribution
	|	ON VT_DataForDistributionByFIFOBonusAmount.CalculationPeriod = VT_RoundingUpFIFODistribution.CalculationPeriod
	|		AND VT_DataForDistributionByFIFOBonusAmount.ConditionOfRebateBonusIs = VT_RoundingUpFIFODistribution.ConditionOfRebateBonusIs
	|		AND VT_DataForDistributionByFIFOBonusAmount.Organization = VT_RoundingUpFIFODistribution.Organization
	|		AND &ConnectionFieldsByParticipants
	|		AND &ConnectionFieldRangeNumber
	|		AND &ConnectionFieldsByGoods";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForDistributionByFIFOBonusAmount",
		"VT_RoundingUpFIFODistribution");
	SubstituteRangeNumberField(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForDistributionByFIFOBonusAmount",
		"VT_RoundingUpFIFODistribution");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForDistributionByFIFOBonusAmount",
		"VT_RoundingUpFIFODistribution");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDataForProportionalDistributionByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.Period AS Period,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	SourceTable1.RangeFrom AS RangeFrom,
	|	SourceTable1.RangeBy AS RangeBy,
	|	SourceTable1.DocumentRecorder AS DocumentRecorder,
	|	SourceTable1.LineNumber AS LineNumber,
	|	SourceTable1.Organization AS Organization,
	|	&MemberFields,
	|	SourceTable1.Contract AS Contract,
	|	SourceTable1.Terms AS Terms,
	|	SourceTable1.Products AS Products,
	|	SourceTable1.Characteristic AS Characteristic,
	|	SourceTable1.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	SourceTable1.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	SourceTable1.PropertyValue AS PropertyValue,
	|	SourceTable1.SumPlan AS SumPlan,
	|	SourceTable1.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	SourceTable1.UnitOfMeasure AS UnitOfMeasure,
	|	SourceTable1.GoodsIndicator AS GoodsIndicator,
	|	SourceTable1.PartyCountDetails AS PartyCountDetails,
	|	SourceTable1.AccrualFrequency AS AccrualFrequency,
	|	SourceTable1.ConditionFrequency AS ConditionFrequency,
	|	SourceTable1.Count AS Count,
	|	SourceTable1.Count AS AmountToCalculateBonus,
	|	SourceTable1.Currency AS Currency,
	|	SourceTable1.SalesAmount AS SalesAmount,
	|	SourceTable1.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	SourceTable1.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	SourceTable1.BasePrice AS BasePrice,
	|	SourceTable1.BonusPercent AS BonusPercent,
	|	SourceTable1.CountPlan AS CountPlan,
	|	SourceTable1.PlanIsFulfilled AS PlanIsFulfilled,
	|	SourceTable1.Priority AS Priority,
	|	SourceTable1.CalculationBase AS CalculationBaseIsInitial,
	|	SourceTable1.CalculationBaseOfEverything AS CalculationBaseWithoutRestrictions,
	|	SourceTable1.SumPlan AS CalculationBaseOfEverything,
	|	CAST(SourceTable1.SalesAmount * SourceTable1.BonusPercent / 100 AS NUMBER(31, 2)) AS AmountOfBonusIsUnlimited,
	|	CASE
	|		WHEN SourceTable1.CalculationBaseOfEverything = 0
	|			THEN 0
	|		ELSE CAST(SourceTable1.SumPlan / SourceTable1.CalculationBaseOfEverything AS NUMBER(31, 14))
	|	END AS ZoomRatio,
	|	CAST(SourceTable1.SumPlan * SourceTable1.BonusPercent / 100 AS NUMBER(31, 2)) AS TotalBonusAmount,
	|	CASE
	|		WHEN SourceTable1.CalculationBaseOfEverything = 0
	|			THEN 0
	|		ELSE CAST(SourceTable1.CalculationBase * SourceTable1.SumPlan / SourceTable1.CalculationBaseOfEverything AS NUMBER(31, 2))
	|	END AS CalculationBase,
	|	CASE
	|		WHEN SourceTable1.CalculationBaseOfEverything = 0
	|			THEN 0
	|		ELSE CAST(SourceTable1.CalculationBase * SourceTable1.BonusPercent * SourceTable1.SumPlan / SourceTable1.CalculationBaseOfEverything / 100 AS NUMBER(31, 2))
	|	END AS AmountBonus
	|INTO VT_DataForProportionalDistribution
	|FROM
	|	TT_PreparedData AS SourceTable1
	|WHERE
	|	SourceTable1.PlanIsFulfilled";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteRangeNumberField(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDataForProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_DataIncludingExceedingLimit.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DataIncludingExceedingLimit.Period AS Period,
	|	VT_DataIncludingExceedingLimit.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	VT_DataIncludingExceedingLimit.RangeFrom AS RangeFrom,
	|	VT_DataIncludingExceedingLimit.RangeBy AS RangeBy,
	|	VT_DataIncludingExceedingLimit.DocumentRecorder AS DocumentRecorder,
	|	VT_DataIncludingExceedingLimit.LineNumber AS LineNumber,
	|	VT_DataIncludingExceedingLimit.Organization AS Organization,
	|	&MemberFields,
	|	VT_DataIncludingExceedingLimit.Contract AS Contract,
	|	VT_DataIncludingExceedingLimit.Terms AS Terms,
	|	VT_DataIncludingExceedingLimit.Products AS Products,
	|	VT_DataIncludingExceedingLimit.Characteristic AS Characteristic,
	|	VT_DataIncludingExceedingLimit.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_DataIncludingExceedingLimit.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_DataIncludingExceedingLimit.PropertyValue AS PropertyValue,
	|	VT_DataIncludingExceedingLimit.SumPlan AS SumPlan,
	|	VT_DataIncludingExceedingLimit.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_DataIncludingExceedingLimit.UnitOfMeasure AS UnitOfMeasure,
	|	VT_DataIncludingExceedingLimit.GoodsIndicator AS GoodsIndicator,
	|	VT_DataIncludingExceedingLimit.PartyCountDetails AS PartyCountDetails,
	|	VT_DataIncludingExceedingLimit.AccrualFrequency AS AccrualFrequency,
	|	VT_DataIncludingExceedingLimit.ConditionFrequency AS ConditionFrequency,
	|	VT_DataIncludingExceedingLimit.Count AS Count,
	|	VT_DataIncludingExceedingLimit.TotalCount1 AS TotalCount1,
	|	VT_DataIncludingExceedingLimit.Currency AS Currency,
	|	VT_DataIncludingExceedingLimit.SalesAmount AS SalesAmount,
	|	VT_DataIncludingExceedingLimit.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	VT_DataIncludingExceedingLimit.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	VT_DataIncludingExceedingLimit.BasePrice AS BasePrice,
	|	VT_DataIncludingExceedingLimit.BonusPercent AS BonusPercent,
	|	&ExpressionNumberPlan AS CountPlan,
	|	VT_DataIncludingExceedingLimit.PlanIsFulfilled AS PlanIsFulfilled,
	|	VT_DataIncludingExceedingLimit.Priority AS Priority,
	|	VT_DataIncludingExceedingLimit.CalculationBase AS CalculationBase,
	|	VT_DataIncludingExceedingLimit.CalculationBaseOfEverything AS CalculationBaseOfEverything,
	|	CAST(VT_DataIncludingExceedingLimit.SalesAmount * VT_DataIncludingExceedingLimit.BonusPercent / 100 AS NUMBER(31, 2)) AS AmountOfBonusIsUnlimited,
	|	VT_DataIncludingExceedingLimit.NumberOfPackages_ AS NumberOfPackages_,
	|	VT_DataIncludingExceedingLimit.NumberOfPlansTakingIntoAccountMultiplicityOfSales AS NumberOfPlansTakingIntoAccountMultiplicityOfSales
	|INTO VT_DataForProportionalDistribution
	|FROM
	|	VT_DataIncludingExceedingLimit AS VT_DataIncludingExceedingLimit
	|WHERE
	|	VT_DataIncludingExceedingLimit.PlanIsFulfilled";
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		ExpressionNumberPlan =
		"CASE
		|	WHEN VT_DataIncludingExceedingLimit.RangeBy = 0
		|		THEN VT_DataIncludingExceedingLimit.TotalCount1 - VT_DataIncludingExceedingLimit.RangeFrom
		|	WHEN VT_DataIncludingExceedingLimit.TotalCount1 <= VT_DataIncludingExceedingLimit.RangeBy
		|		THEN VT_DataIncludingExceedingLimit.TotalCount1 - VT_DataIncludingExceedingLimit.RangeFrom
		|	ELSE VT_DataIncludingExceedingLimit.RangeBy - VT_DataIncludingExceedingLimit.RangeFrom
		|END";
		
	Else
		
		ExpressionNumberPlan = "VT_DataIncludingExceedingLimit.CountPlan";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&ExpressionNumberPlan", ExpressionNumberPlan);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_DataIncludingExceedingLimit");
	SubstituteRangeNumberField(RebateConditionsParameters, QueryText, "VT_DataIncludingExceedingLimit");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextBaseOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	VT_DataForProportionalDistribution.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	VT_DataForProportionalDistribution.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	&ProductFields,
	|	VT_DataForProportionalDistribution.Organization AS Organization,
	|	VT_DataForProportionalDistribution.Currency AS Currency,
	|	&MemberFields,
	|	&ExpressionNumberPlan AS CountPlan,
	|	VT_DataForProportionalDistribution.BonusPercent AS BonusPercent,
	|	SUM(VT_DataForProportionalDistribution.Count) AS TotalCount1,
	|	SUM(VT_DataForProportionalDistribution.CalculationBase) AS CalculationBase
	|INTO VT_ProportionalDistributionBase
	|FROM
	|	VT_DataForProportionalDistribution AS VT_DataForProportionalDistribution
	|
	|GROUP BY
	|	VT_DataForProportionalDistribution.CalculationPeriod,
	|	&GroupingFieldRangeNumber,
	|	VT_DataForProportionalDistribution.ConditionOfRebateBonusIs,
	|	&GroupingFieldsByGoodsFields,
	|	VT_DataForProportionalDistribution.Organization,
	|	VT_DataForProportionalDistribution.Currency,
	|	&GroupingFieldsByParticipants,
	|	&ExpressionNumberPlan,
	|	VT_DataForProportionalDistribution.CountPlan,
	|	VT_DataForProportionalDistribution.BonusPercent";
	
	If RebateConditionsParameters.GoodsIndicator = SalesFigures.BatchOffer Then
		ExpressionNumberPlan = "VT_DataForProportionalDistribution.NumberOfPlansTakingIntoAccountMultiplicityOfSales";
	Else
		ExpressionNumberPlan = "VT_DataForProportionalDistribution.CountPlan";
	EndIf;
	QueryText = StrReplace(QueryText, "&ExpressionNumberPlan", ExpressionNumberPlan);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_DataForProportionalDistribution");
	SubstituteRangeNumberField(RebateConditionsParameters, QueryText, "VT_DataForProportionalDistribution");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "VT_DataForProportionalDistribution");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextCalculationOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_ProportionalDistributionBase.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	VT_ProportionalDistributionBase.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	&ProductFields,
	|	VT_ProportionalDistributionBase.Organization AS Organization,
	|	VT_ProportionalDistributionBase.Currency AS Currency,
	|	&MemberFields,
	|	VT_ProportionalDistributionBase.CountPlan AS CountPlan,
	|	VT_ProportionalDistributionBase.TotalCount1 AS TotalCount1,
	|	CASE
	|		WHEN VT_ProportionalDistributionBase.TotalCount1 = 0
	|			THEN 0
	|		ELSE CAST(VT_ProportionalDistributionBase.CalculationBase * VT_ProportionalDistributionBase.CountPlan / VT_ProportionalDistributionBase.TotalCount1 AS NUMBER(31, 2))
	|	END AS CalculationBaseOfEverything,
	|	CASE
	|		WHEN VT_ProportionalDistributionBase.TotalCount1 = 0
	|			THEN 0
	|		ELSE CAST(CAST(VT_ProportionalDistributionBase.CalculationBase * VT_ProportionalDistributionBase.CountPlan / VT_ProportionalDistributionBase.TotalCount1 AS NUMBER(31, 2)) * VT_ProportionalDistributionBase.BonusPercent / 100 AS NUMBER(31, 2))
	|	END AS TotalBonusAmount
	|INTO VT_CalculationOfProportionalDistribution
	|FROM
	|	VT_ProportionalDistributionBase AS VT_ProportionalDistributionBase";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_ProportionalDistributionBase");
	SubstituteRangeNumberField(RebateConditionsParameters, QueryText, "VT_ProportionalDistributionBase");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "VT_ProportionalDistributionBase");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextProportionalDistributionByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_DataForProportionalDistribution.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_DataForProportionalDistribution.Period AS Period,
	|	VT_DataForProportionalDistribution.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	VT_DataForProportionalDistribution.RangeFrom AS RangeFrom,
	|	VT_DataForProportionalDistribution.RangeBy AS RangeBy,
	|	VT_DataForProportionalDistribution.DocumentRecorder AS DocumentRecorder,
	|	VT_DataForProportionalDistribution.LineNumber AS LineNumber,
	|	VT_DataForProportionalDistribution.Organization AS Organization,
	|	&MemberFields,
	|	VT_DataForProportionalDistribution.Contract AS Contract,
	|	VT_DataForProportionalDistribution.Terms AS Terms,
	|	VT_DataForProportionalDistribution.Products AS Products,
	|	VT_DataForProportionalDistribution.Characteristic AS Characteristic,
	|	VT_DataForProportionalDistribution.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	VT_DataForProportionalDistribution.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	VT_DataForProportionalDistribution.PropertyValue AS PropertyValue,
	|	VT_DataForProportionalDistribution.SumPlan AS SumPlan,
	|	VT_DataForProportionalDistribution.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_DataForProportionalDistribution.UnitOfMeasure AS UnitOfMeasure,
	|	VT_DataForProportionalDistribution.GoodsIndicator AS GoodsIndicator,
	|	VT_DataForProportionalDistribution.PartyCountDetails AS PartyCountDetails,
	|	VT_DataForProportionalDistribution.AccrualFrequency AS AccrualFrequency,
	|	VT_DataForProportionalDistribution.ConditionFrequency AS ConditionFrequency,
	|	VT_DataForProportionalDistribution.Count AS Count,
	|	VT_DataForProportionalDistribution.Currency AS Currency,
	|	VT_DataForProportionalDistribution.SalesAmount AS SalesAmount,
	|	VT_DataForProportionalDistribution.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	VT_DataForProportionalDistribution.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	VT_DataForProportionalDistribution.BasePrice AS BasePrice,
	|	VT_DataForProportionalDistribution.BonusPercent AS BonusPercent,
	|	VT_DataForProportionalDistribution.PlanIsFulfilled AS PlanIsFulfilled,
	|	VT_DataForProportionalDistribution.CountPlan AS CountPlan,
	|	ISNULL(VT_CalculationOfProportionalDistribution.TotalCount1, 0) AS TotalCount1,
	|	CASE
	|		WHEN ISNULL(VT_CalculationOfProportionalDistribution.TotalCount1, 0) <> 0
	|			THEN CAST(VT_DataForProportionalDistribution.Count * ISNULL(VT_CalculationOfProportionalDistribution.CountPlan, 0)
	|				/ ISNULL(VT_CalculationOfProportionalDistribution.TotalCount1, 0) AS NUMBER(15, 3))
	|		ELSE 0
	|	END AS AmountToCalculateBonus,
	|	VT_DataForProportionalDistribution.Priority AS Priority,
	|	VT_DataForProportionalDistribution.CalculationBase AS CalculationBaseIsInitial,
	|	VT_DataForProportionalDistribution.AmountOfBonusIsUnlimited AS AmountOfBonusIsUnlimited,
	|	ISNULL(VT_CalculationOfProportionalDistribution.CalculationBaseOfEverything, 0) AS CalculationBaseOfEverything,
	|	ISNULL(VT_CalculationOfProportionalDistribution.TotalBonusAmount, 0) AS TotalBonusAmount,
	|	CASE
	|		WHEN ISNULL(VT_CalculationOfProportionalDistribution.TotalCount1, 0) <> 0
	|			THEN CAST(VT_DataForProportionalDistribution.CalculationBase * ISNULL(VT_CalculationOfProportionalDistribution.CountPlan, 0)
	|				/ ISNULL(VT_CalculationOfProportionalDistribution.TotalCount1, 0) AS NUMBER(31, 2))
	|		ELSE 0
	|	END AS CalculationBase,
	|	CASE
	|		WHEN ISNULL(VT_CalculationOfProportionalDistribution.TotalCount1, 0) <> 0
	|			THEN CAST(VT_DataForProportionalDistribution.CalculationBase * VT_DataForProportionalDistribution.BonusPercent
	|				* ISNULL(VT_CalculationOfProportionalDistribution.CountPlan, 0)
	|				/ ISNULL(VT_CalculationOfProportionalDistribution.TotalCount1, 0) / 100 AS NUMBER(31, 2))
	|		ELSE 0
	|	END AS AmountBonus,
	|	VT_DataForProportionalDistribution.NumberOfPackages_ AS NumberOfPackages_
	|INTO VT_ProportionalDistributionByPosition
	|FROM
	|	VT_DataForProportionalDistribution AS VT_DataForProportionalDistribution
	|	LEFT JOIN VT_CalculationOfProportionalDistribution AS VT_CalculationOfProportionalDistribution
	|	ON VT_DataForProportionalDistribution.CalculationPeriod = VT_CalculationOfProportionalDistribution.CalculationPeriod
	|		AND &ConnectionFieldRangeNumber
	|		AND VT_DataForProportionalDistribution.ConditionOfRebateBonusIs = VT_CalculationOfProportionalDistribution.ConditionOfRebateBonusIs
	|		AND &ConnectionFieldsByGoods
	|		AND VT_DataForProportionalDistribution.Organization = VT_CalculationOfProportionalDistribution.Organization
	|		AND VT_DataForProportionalDistribution.Currency = VT_CalculationOfProportionalDistribution.Currency
	|		AND &ConnectionFieldsByParticipants";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForProportionalDistribution",
		"VT_CalculationOfProportionalDistribution");
	SubstituteRangeNumberField(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForProportionalDistribution",
		"VT_CalculationOfProportionalDistribution");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		QueryText,
		"VT_DataForProportionalDistribution",
		"VT_CalculationOfProportionalDistribution");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTotalsByScaleRanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	SourceTable1.Currency AS Currency,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.Priority AS Priority,
	|	MAX(SourceTable1.RangeFrom) AS LastRangeIsFrom,
	|	SUM(SourceTable1.Count) AS NumberOfTotalOnScale,
	|	SUM(SourceTable1.CalculationBase) AS CalculationBaseTotalOnScale
	|INTO TT_TotalsByScaleRanges
	|FROM
	|	VT_FinalProportionalDistribution AS SourceTable1
	|
	|GROUP BY
	|	SourceTable1.Currency,
	|	SourceTable1.CalculationPeriod,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	SourceTable1.Priority";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextErrorCorrectionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.GoodsIndicator AS GoodsIndicator,
	|	SourceTable1.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	SourceTable1.PartyCountDetails AS PartyCountDetails,
	|	SourceTable1.AccrualFrequency AS AccrualFrequency,
	|	SourceTable1.ConditionFrequency AS ConditionFrequency,
	|	SourceTable1.Period AS Period,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	SourceTable1.DocumentRecorder AS DocumentRecorder,
	|	SourceTable1.LineNumber AS LineNumber,
	|	SourceTable1.RangeFrom AS RangeFrom,
	|	SourceTable1.RangeBy AS RangeBy,
	|	SourceTable1.Organization AS Organization,
	|	SourceTable1.Contract AS Contract,
	|	SourceTable1.Terms AS Terms,
	|	SourceTable1.Products AS Products,
	|	SourceTable1.UnitOfMeasure AS UnitOfMeasure,
	|	SourceTable1.Characteristic AS Characteristic,
	|	SourceTable1.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	SourceTable1.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	SourceTable1.PropertyValue AS PropertyValue,
	|	SourceTable1.SumPlan AS SumPlan,
	|	CASE
	|		WHEN SourceTable1.RangeFrom = 0
	|			THEN SourceTable1.Count
	|		ELSE 0
	|	END AS Count,
	|	SourceTable1.Currency AS Currency,
	|	SourceTable1.SalesAmount AS SalesAmount,
	|	SourceTable1.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	SourceTable1.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	SourceTable1.BasePrice AS BasePrice,
	|	SourceTable1.BonusPercent AS BonusPercent,
	|	SourceTable1.PlanIsFulfilled AS PlanIsFulfilled,
	|	SourceTable1.CountPlan AS CountPlan,
	|	SourceTable1.AmountToCalculateBonus AS AmountToCalculateBonus,
	|	SourceTable1.NumberOfPackages_ AS NumberOfPackages_,
	|	SourceTable1.RangeNumber AS RangeNumber,
	|	&MemberFields,
	|	SourceTable1.Priority AS Priority,
	|	CASE
	|		WHEN SourceTable1.RangeFrom = ISNULL(TT_TotalsByScaleRanges.LastRangeIsFrom, -1)
	|			THEN SourceTable1.CalculationBase + SourceTable1.CalculationBaseIsInitial
	|				- ISNULL(TT_TotalsByScaleRanges.CalculationBaseTotalOnScale, 0)
	|		ELSE SourceTable1.CalculationBase
	|	END AS CalculationBase,
	|	SourceTable1.AmountBonus AS AmountBonus
	|INTO TT_CorrectionOfErrorByRanges
	|FROM
	|	VT_FinalProportionalDistribution AS SourceTable1
	|		LEFT JOIN TT_TotalsByScaleRanges AS TT_TotalsByScaleRanges
	|		ON SourceTable1.Priority = TT_TotalsByScaleRanges.Priority
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1", "TT_TotalsByScaleRanges");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1", "TT_TotalsByScaleRanges");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextRoundingProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	TT_SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	TT_SourceTable1.Organization AS Organization,
	|	TT_SourceTable1.Currency AS Currency,
	|	&MemberFields,
	|	&ProductFields,
	|	ISNULL(TT_RoundingPriority.MaximumPriority, -1) AS MaximumPriority,
	|	SUM(CASE
	|			WHEN TT_SourceTable1.Priority = ISNULL(TT_RoundingPriority.MaximumPriority, -1)
	|				THEN 0
	|			ELSE TT_SourceTable1.CalculationBase
	|		END) AS CalculationBaseExceptMaximumPriority,
	|	SUM(CASE
	|			WHEN TT_SourceTable1.Priority = ISNULL(TT_RoundingPriority.MaximumPriority, -1)
	|				THEN 0
	|			ELSE TT_SourceTable1.AmountBonus
	|		END) AS BonusAmountExceptMaximumPriority
	|INTO VT_RoundingUpProportionalDistribution
	|FROM
	|	&SourceTable1 AS TT_SourceTable1
	|	LEFT JOIN TT_RoundingPriority AS TT_RoundingPriority
	|	ON TT_SourceTable1.CalculationPeriod = TT_RoundingPriority.CalculationPeriod
	|		AND TT_SourceTable1.ConditionOfRebateBonusIs = TT_RoundingPriority.ConditionOfRebateBonusIs
	|		AND TT_SourceTable1.Organization = TT_RoundingPriority.Organization
	|		AND TT_SourceTable1.Currency = TT_RoundingPriority.Currency
	|		AND &ConnectionFieldRangeNumber
	|		AND &ConnectionFieldsByParticipants
	|		AND &ConnectionFieldsByGoods
	|GROUP BY
	|	TT_SourceTable1.CalculationPeriod,
	|	&GroupingFieldRangeNumber,
	|	TT_SourceTable1.ConditionOfRebateBonusIs,
	|	TT_SourceTable1.Organization,
	|	TT_SourceTable1.Currency,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	TT_RoundingPriority.MaximumPriority";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, QueryText, "TT_SourceTable1", "TT_RoundingPriority");
	
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_SourceTable1", "TT_RoundingPriority");
	SubstituteRangeNumberField(RebateConditionsParameters, QueryText, "TT_SourceTable1", "TT_RoundingPriority");
	
	If RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.Count
	 Or RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.BatchOffer Then
		
		SourceTable1 = "VT_ProportionalDistributionByPosition";
		
	ElsIf RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.Sum Then
		
		SourceTable1 = "VT_DataForProportionalDistribution";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Không thể xác định chỉ tiêu bán hàng (""%1"") đối với chứng từ ""%2""';
							|ru = 'Не удалось определить показатель продаж (""%1"") для документа ""%2""';
							|en = 'Cannot determine the sales indicator (""%1"") for the ""%2"" document'; fa = 'Cannot determine the sales indicator (""%1"") for the ""%2"" document';
							|it = 'Не удалось определить показатель продаж (""%1"") для документа ""%2""';
							|pl = 'Cannot determine the sales indicator (""%1"") for the ""%2"" document';
							|tr = 'Belge “%2“ için satış göstergesi (“%1”) tanımlanamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.GoodsIndicatorPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextOfFinalProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	QueryText =
	"SELECT
	|	TT_SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_SourceTable1.Period AS Period,
	|	TT_SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&RangeNumberField,
	|	TT_SourceTable1.DocumentRecorder AS DocumentRecorder,
	|	TT_SourceTable1.LineNumber AS LineNumber,
	|	TT_SourceTable1.Organization AS Organization,
	|	&MemberFields,
	|	TT_SourceTable1.Contract AS Contract,
	|	TT_SourceTable1.Terms AS Terms,
	|	TT_SourceTable1.Products AS Products,
	|	TT_SourceTable1.UnitOfMeasure AS UnitOfMeasure,
	|	TT_SourceTable1.Characteristic AS Characteristic,
	|	TT_SourceTable1.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_SourceTable1.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_SourceTable1.PropertyValue AS PropertyValue,
	|	TT_SourceTable1.SumPlan AS SumPlan,
	|	TT_SourceTable1.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_SourceTable1.GoodsIndicator AS GoodsIndicator,
	|	TT_SourceTable1.PartyCountDetails AS PartyCountDetails,
	|	TT_SourceTable1.AccrualFrequency AS AccrualFrequency,
	|	TT_SourceTable1.ConditionFrequency AS ConditionFrequency,
	|	TT_SourceTable1.Count AS Count,
	|	TT_SourceTable1.Currency AS Currency,
	|	TT_SourceTable1.SalesAmount AS SalesAmount,
	|	TT_SourceTable1.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	TT_SourceTable1.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	TT_SourceTable1.BasePrice AS BasePrice,
	|	TT_SourceTable1.BonusPercent AS BonusPercent,
	|	TT_SourceTable1.PlanIsFulfilled AS PlanIsFulfilled,
	|	TT_SourceTable1.CountPlan AS CountPlan,
	|	TT_SourceTable1.AmountToCalculateBonus AS AmountToCalculateBonus,
	|	TT_SourceTable1.Priority AS Priority,
	|	TT_SourceTable1.RangeFrom AS RangeFrom,
	|	TT_SourceTable1.RangeBy AS RangeBy,
	|	TT_SourceTable1.CalculationBaseOfEverything AS CalculationBaseOfEverything,
	|	TT_SourceTable1.CalculationBaseIsInitial AS CalculationBaseIsInitial,
	|	TT_SourceTable1.TotalBonusAmount AS TotalBonusAmount,
	|	ISNULL(VT_RoundingUpProportionalDistribution.MaximumPriority, -1) AS MaximumPriority,
	|	CASE
	|		WHEN TT_SourceTable1.Priority = ISNULL(VT_RoundingUpProportionalDistribution.MaximumPriority, -1)
	|			THEN TT_SourceTable1.CalculationBaseOfEverything -
	|				ISNULL(VT_RoundingUpProportionalDistribution.CalculationBaseExceptMaximumPriority, 0)
	|		ELSE TT_SourceTable1.CalculationBase
	|	END AS CalculationBase,
	|	CASE
	|		WHEN TT_SourceTable1.Priority = ISNULL(VT_RoundingUpProportionalDistribution.MaximumPriority, -1)
	|			THEN TT_SourceTable1.TotalBonusAmount -
	|				ISNULL(VT_RoundingUpProportionalDistribution.BonusAmountExceptMaximumPriority, 0)
	|		ELSE TT_SourceTable1.AmountBonus
	|	END AS AmountBonus,
	|	&ExpressionSoldPackages AS NumberOfPackages_
	|INTO VT_FinalProportionalDistribution
	|FROM
	|	&SourceTable1 AS TT_SourceTable1
	|	LEFT JOIN VT_RoundingUpProportionalDistribution AS VT_RoundingUpProportionalDistribution
	|	ON TT_SourceTable1.CalculationPeriod = VT_RoundingUpProportionalDistribution.CalculationPeriod
	|		AND &ConnectionFieldRangeNumber
	|		AND TT_SourceTable1.ConditionOfRebateBonusIs = VT_RoundingUpProportionalDistribution.ConditionOfRebateBonusIs
	|		AND TT_SourceTable1.Organization = VT_RoundingUpProportionalDistribution.Organization
	|		AND TT_SourceTable1.Currency = VT_RoundingUpProportionalDistribution.Currency
	|		AND &ConnectionFieldsByParticipants
	|		AND &ConnectionFieldsByGoods";
	
	If RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.Count
	 Or RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.BatchOffer Then
		
		SourceTable1 = "VT_ProportionalDistributionByPosition";
		ExpressionSoldPackages = "TT_SourceTable1.NumberOfPackages_";
		
	ElsIf RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.Sum Then
		
		SourceTable1 = "VT_DataForProportionalDistribution";
		ExpressionSoldPackages = "0";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Không thể xác định chỉ tiêu bán hàng (""%1"") đối với chứng từ ""%2""';
							|ru = 'Не удалось определить показатель продаж (""%1"") для документа ""%2""';
							|en = 'Cannot determine the sales indicator (""%1"") for the ""%2"" document'; fa = 'Cannot determine the sales indicator (""%1"") for the ""%2"" document';
							|it = 'Не удалось определить показатель продаж (""%1"") для документа ""%2""';
							|pl = 'Cannot determine the sales indicator (""%1"") for the ""%2"" document';
							|tr = 'Belge “%2“ için satış göstergesi (“%1”) tanımlanamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.GoodsIndicatorPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	QueryText = StrReplace(QueryText, "&ExpressionSoldPackages", ExpressionSoldPackages);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		QueryText,
		"TT_SourceTable1",
		"VT_RoundingUpProportionalDistribution");
	
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		QueryText,
		"TT_SourceTable1",
		"VT_RoundingUpProportionalDistribution");
	
	SubstituteRangeNumberField(
		RebateConditionsParameters,
		QueryText,
		"TT_SourceTable1",
		"VT_RoundingUpProportionalDistribution");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextSummaryDataWithoutTarget(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_DiscountPercentage.Period AS Period,
	|	TT_DiscountPercentage.CalculationPeriod AS CalculationPeriod,
	|	0 AS RangeNumber,
	|	"""" AS PresentationOfRangeUnit,
	|	TT_DiscountPercentage.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_DiscountPercentage.GoodsIndicator AS GoodsIndicator,
	|	TT_DiscountPercentage.PartyCountDetails AS PartyCountDetails,
	|	TT_DiscountPercentage.AccrualFrequency AS AccrualFrequency,
	|	VALUE(Enum.RebatesFrequencies.EmptyRef) AS ConditionFrequency,
	|	FALSE AS RestrictAccrualOverPlan,
	|	TRUE AS PlanIsFulfilled,
	|	TT_DiscountPercentage.DocumentRecorder AS DocumentRecorder,
	|	TT_DiscountPercentage.LineNumber AS LineNumber,
	|	0 AS RangeFrom,
	|	0 AS RangeBy,
	|	TT_DiscountPercentage.Organization AS Organization,
	|	TT_DiscountPercentage.Counterparty AS Counterparty,
	|	TT_DiscountPercentage.Partner AS Partner,
	|	TT_DiscountPercentage.Contract AS Contract,
	|	TT_DiscountPercentage.Terms AS Terms,
	|	TT_DiscountPercentage.Products AS Products,
	|	TT_DiscountPercentage.UnitOfMeasure AS UnitOfMeasure,
	|	TT_DiscountPercentage.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_DiscountPercentage.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_DiscountPercentage.Characteristic AS Characteristic,
	|	TT_DiscountPercentage.PropertyValue AS PropertyValue,
	|	TT_DiscountPercentage.Count AS Count,
	|	&ExpressionCalculationCurrency AS Currency,
	|	&ExpressionAmountWithoutSpecification AS SalesAmount,
	|	&ExpressionSumWithVAT AS AmountOfTurnoverWithVAT,
	|	&ExpressionVATExclusive AS AmountOfTurnoverExcludingVAT,
	|	TT_DiscountPercentage.BasePrice AS BasePrice,
	|	TT_DiscountPercentage.BonusPercent AS BonusPercent,
	|	0 AS SumPlan,
	|	0 AS CountPlan,
	|	TT_DiscountPercentage.Count AS AmountToCalculateBonus,
	|	&ExpressionAmountWithoutSpecification AS CalculationBase,
	|	CASE
	|		WHEN TT_DiscountPercentage.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.RevenueManagementAccounting)
	|			THEN CAST(TT_DiscountPercentage.Sum * TT_DiscountPercentage.BonusPercent / 100 AS NUMBER(31, 2))
	|		WHEN TT_DiscountPercentage.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.RevenueLocalAccounting)
	|			OR TT_DiscountPercentage.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.PurchaseAmountLocalAccounting)
	|			THEN CAST(TT_DiscountPercentage.SumCompl * TT_DiscountPercentage.BonusPercent / 100 AS NUMBER(31, 2))
	|		WHEN TT_DiscountPercentage.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.RevenueARAPAccounting)
	|			OR TT_DiscountPercentage.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.PurchaseAmountARAPAccounting)
	|			THEN CAST(TT_DiscountPercentage.AmountInARAPCurrency * TT_DiscountPercentage.BonusPercent / 100 AS NUMBER(31, 2))
	|		WHEN TT_DiscountPercentage.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.RevenueBasePrices)
	|			OR TT_DiscountPercentage.BaseOfCalculation = VALUE(Enum.RebateCalculationBases.PurchaseAmountBasePrices)
	|			THEN CAST(TT_DiscountPercentage.Count * TT_DiscountPercentage.BasePrice * TT_DiscountPercentage.BonusPercent / 100 AS NUMBER(31, 2))
	|	END AS AmountBonus,
	|	0 AS NumberOfPackages_
	|INTO TT_SummaryData
	|FROM
	|	TT_DiscountPercentage AS TT_DiscountPercentage";
	
	SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteAmountSelectionFieldWithVAT(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteVATExclusiveAmountSelectionField(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	SubstituteExpressionCalculationCurrency(RebateConditionsParameters, QueryText, "TT_DiscountPercentage");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If (Not RebateConditionsParameters.RestrictAccrualOverPlan
	   And Not RebateConditionsParameters.CalculationScaleByRanges)
	   And RebateConditionsParameters.GoodsIndicator <> IndicatorsKinds.BatchOffer Then
		
		QueryText =
		"SELECT
		|	VT_DataWithoutProhibitionOfExceeding.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
		|	VT_DataWithoutProhibitionOfExceeding.GoodsIndicator AS GoodsIndicator,
		|	VT_DataWithoutProhibitionOfExceeding.Period AS Period,
		|	VT_DataWithoutProhibitionOfExceeding.CalculationPeriod AS CalculationPeriod,
		|	0 AS RangeNumber,
		|	&FieldPresentationOfRangeUnit,
		|	VT_DataWithoutProhibitionOfExceeding.DocumentRecorder AS DocumentRecorder,
		|	VT_DataWithoutProhibitionOfExceeding.LineNumber AS LineNumber,
		|	0 AS RangeFrom,
		|	0 AS RangeBy,
		|	VT_DataWithoutProhibitionOfExceeding.Organization AS Organization,
		|	&MemberFields,
		|	VT_DataWithoutProhibitionOfExceeding.Contract AS Contract,
		|	VT_DataWithoutProhibitionOfExceeding.Terms AS Terms,
		|	VT_DataWithoutProhibitionOfExceeding.Products AS Products,
		|	VT_DataWithoutProhibitionOfExceeding.UnitOfMeasure AS UnitOfMeasure,
		|	VT_DataWithoutProhibitionOfExceeding.ItemVariantsAreUsed AS ItemVariantsAreUsed,
		|	VT_DataWithoutProhibitionOfExceeding.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
		|	VT_DataWithoutProhibitionOfExceeding.Characteristic AS Characteristic,
		|	VT_DataWithoutProhibitionOfExceeding.PropertyValue AS PropertyValue,
		|	VT_DataWithoutProhibitionOfExceeding.PartyCountDetails AS PartyCountDetails,
		|	VT_DataWithoutProhibitionOfExceeding.AccrualFrequency AS AccrualFrequency,
		|	VT_DataWithoutProhibitionOfExceeding.ConditionFrequency AS ConditionFrequency,
		|	VT_DataWithoutProhibitionOfExceeding.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
		|	VT_DataWithoutProhibitionOfExceeding.Count AS Count,
		|	VT_DataWithoutProhibitionOfExceeding.Currency AS Currency,
		|	VT_DataWithoutProhibitionOfExceeding.SalesAmount AS SalesAmount,
		|	VT_DataWithoutProhibitionOfExceeding.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
		|	VT_DataWithoutProhibitionOfExceeding.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
		|	VT_DataWithoutProhibitionOfExceeding.BonusPercent AS BonusPercent,
		|	VT_DataWithoutProhibitionOfExceeding.BasePrice AS BasePrice,
		|	VT_DataWithoutProhibitionOfExceeding.SumPlan AS SumPlan,
		|	VT_DataWithoutProhibitionOfExceeding.PlanIsFulfilled AS PlanIsFulfilled,
		|	VT_DataWithoutProhibitionOfExceeding.CalculationBase AS CalculationBase,
		|	VT_DataWithoutProhibitionOfExceeding.CountPlan AS CountPlan,
		|	VT_DataWithoutProhibitionOfExceeding.Count AS AmountToCalculateBonus,
		|	VT_DataWithoutProhibitionOfExceeding.AmountBonus AS AmountBonus,
		|	0 AS NumberOfPackages_
		|INTO TT_SummaryData
		|FROM
		|	VT_DataWithoutProhibitionOfExceeding AS VT_DataWithoutProhibitionOfExceeding";
		
		SubstituteFieldsByParticipants(
			RebateConditionsParameters,
			QueryText,
			"VT_DataWithoutProhibitionOfExceeding",
			"",
			True);
		SubstitutePresentationOfRangeUnitField(
			RebateConditionsParameters,
			QueryText,
			"VT_DataWithoutProhibitionOfExceeding");
		
	ElsIf RebateConditionsParameters.DistributionByFIFO Then
		
		QueryText =
		"SELECT
		|	VT_FinalDistributionByFIFO.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
		|	VT_FinalDistributionByFIFO.GoodsIndicator AS GoodsIndicator,
		|	VT_FinalDistributionByFIFO.Period AS Period,
		|	VT_FinalDistributionByFIFO.CalculationPeriod AS CalculationPeriod,
		|	&RangeNumberField,
		|	&FieldPresentationOfRangeUnit,
		|	VT_FinalDistributionByFIFO.DocumentRecorder AS DocumentRecorder,
		|	VT_FinalDistributionByFIFO.LineNumber AS LineNumber,
		|	VT_FinalDistributionByFIFO.RangeFrom AS RangeFrom,
		|	VT_FinalDistributionByFIFO.RangeBy AS RangeBy,
		|	VT_FinalDistributionByFIFO.Organization AS Organization,
		|	&MemberFields,
		|	VT_FinalDistributionByFIFO.Contract AS Contract,
		|	VT_FinalDistributionByFIFO.Terms AS Terms,
		|	VT_FinalDistributionByFIFO.Products AS Products,
		|	VT_FinalDistributionByFIFO.UnitOfMeasure AS UnitOfMeasure,
		|	VT_FinalDistributionByFIFO.ItemVariantsAreUsed AS ItemVariantsAreUsed,
		|	VT_FinalDistributionByFIFO.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
		|	VT_FinalDistributionByFIFO.Characteristic AS Characteristic,
		|	VT_FinalDistributionByFIFO.PropertyValue AS PropertyValue,
		|	VT_FinalDistributionByFIFO.PartyCountDetails AS PartyCountDetails,
		|	VT_FinalDistributionByFIFO.AccrualFrequency AS AccrualFrequency,
		|	VT_FinalDistributionByFIFO.ConditionFrequency AS ConditionFrequency,
		|	VT_FinalDistributionByFIFO.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
		|	VT_FinalDistributionByFIFO.Count AS Count,
		|	VT_FinalDistributionByFIFO.Currency AS Currency,
		|	VT_FinalDistributionByFIFO.SalesAmount AS SalesAmount,
		|	VT_FinalDistributionByFIFO.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
		|	VT_FinalDistributionByFIFO.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
		|	VT_FinalDistributionByFIFO.BonusPercent AS BonusPercent,
		|	VT_FinalDistributionByFIFO.BasePrice AS BasePrice,
		|	VT_FinalDistributionByFIFO.SumPlan AS SumPlan,
		|	VT_FinalDistributionByFIFO.PlanIsFulfilled AS PlanIsFulfilled,
		|	VT_FinalDistributionByFIFO.CalculationBase AS CalculationBase,
		|	VT_FinalDistributionByFIFO.CountPlan AS CountPlan,
		|	VT_FinalDistributionByFIFO.AmountToCalculateBonus AS AmountToCalculateBonus,
		|	VT_FinalDistributionByFIFO.AmountBonus AS AmountBonus,
		|	VT_FinalDistributionByFIFO.NumberOfPackages_ AS NumberOfPackages_
		|INTO TT_SummaryData
		|FROM
		|	VT_FinalDistributionByFIFO AS VT_FinalDistributionByFIFO";
		
		SubstituteFieldsByParticipants(
			RebateConditionsParameters,
			QueryText,
			"VT_FinalDistributionByFIFO",
			"",
			True);
		SubstituteRangeNumberField(
			RebateConditionsParameters, QueryText, "VT_FinalDistributionByFIFO");
		SubstitutePresentationOfRangeUnitField(
			RebateConditionsParameters, QueryText, "VT_FinalDistributionByFIFO");
		
	Else
		
		TextOfSubqueryPlanIsCompleted =
		"SELECT
		|	VT_FinalProportionalDistribution.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
		|	VT_FinalProportionalDistribution.GoodsIndicator AS GoodsIndicator,
		|	VT_FinalProportionalDistribution.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
		|	VT_FinalProportionalDistribution.PartyCountDetails AS PartyCountDetails,
		|	VT_FinalProportionalDistribution.AccrualFrequency AS AccrualFrequency,
		|	VT_FinalProportionalDistribution.ConditionFrequency AS ConditionFrequency,
		|	VT_FinalProportionalDistribution.Period AS Period,
		|	VT_FinalProportionalDistribution.CalculationPeriod AS CalculationPeriod,
		|	&RangeNumberField,
		|	&FieldPresentationOfRangeUnit,
		|	VT_FinalProportionalDistribution.DocumentRecorder AS DocumentRecorder,
		|	VT_FinalProportionalDistribution.LineNumber AS LineNumber,
		|	VT_FinalProportionalDistribution.RangeFrom AS RangeFrom,
		|	VT_FinalProportionalDistribution.RangeBy AS RangeBy,
		|	VT_FinalProportionalDistribution.Organization AS Organization,
		|	&MemberFields,
		|	VT_FinalProportionalDistribution.Contract AS Contract,
		|	VT_FinalProportionalDistribution.Terms AS Terms,
		|	VT_FinalProportionalDistribution.Products AS Products,
		|	VT_FinalProportionalDistribution.UnitOfMeasure AS UnitOfMeasure,
		|	VT_FinalProportionalDistribution.ItemVariantsAreUsed AS ItemVariantsAreUsed,
		|	VT_FinalProportionalDistribution.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
		|	VT_FinalProportionalDistribution.Characteristic AS Characteristic,
		|	VT_FinalProportionalDistribution.PropertyValue AS PropertyValue,
		|	VT_FinalProportionalDistribution.SumPlan AS SumPlan,
		|	VT_FinalProportionalDistribution.Count AS Count,
		|	VT_FinalProportionalDistribution.Currency AS Currency,
		|	VT_FinalProportionalDistribution.SalesAmount AS SalesAmount,
		|	VT_FinalProportionalDistribution.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
		|	VT_FinalProportionalDistribution.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
		|	VT_FinalProportionalDistribution.BasePrice AS BasePrice,
		|	VT_FinalProportionalDistribution.BonusPercent AS BonusPercent,
		|	VT_FinalProportionalDistribution.PlanIsFulfilled AS PlanIsFulfilled,
		|	VT_FinalProportionalDistribution.CalculationBase AS CalculationBase,
		|	VT_FinalProportionalDistribution.CountPlan AS CountPlan,
		|	VT_FinalProportionalDistribution.AmountToCalculateBonus AS AmountToCalculateBonus,
		|	VT_FinalProportionalDistribution.AmountBonus AS AmountBonus,
		|	VT_FinalProportionalDistribution.NumberOfPackages_ AS NumberOfPackages_
		|INTO TT_SummaryData
		|FROM
		|	&SourceTable1 AS VT_FinalProportionalDistribution";
		
		If RebateConditionsParameters.CalculationScaleByRanges Then
			SourceTable1 = "TT_CorrectionOfErrorByRanges";
		Else
			SourceTable1 = "VT_FinalProportionalDistribution";
		EndIf;
		TextOfSubqueryPlanIsCompleted = StrReplace(TextOfSubqueryPlanIsCompleted, "&SourceTable1", SourceTable1);
		
		SubstituteFieldsByParticipants(
			RebateConditionsParameters,
			TextOfSubqueryPlanIsCompleted,
			"VT_FinalProportionalDistribution",
			"",
			True);
		SubstituteRangeNumberField(
			RebateConditionsParameters, TextOfSubqueryPlanIsCompleted, "VT_FinalProportionalDistribution");
		SubstitutePresentationOfRangeUnitField(
			RebateConditionsParameters, TextOfSubqueryPlanIsCompleted, "VT_FinalProportionalDistribution");
		
		TextOfSubqueryPlanIsNotCompleted =
		"SELECT
		|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
		|	SourceTable1.GoodsIndicator AS GoodsIndicator,
		|	SourceTable1.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
		|	SourceTable1.PartyCountDetails AS PartyCountDetails,
		|	SourceTable1.AccrualFrequency AS AccrualFrequency,
		|	SourceTable1.ConditionFrequency AS ConditionFrequency,
		|	SourceTable1.Period AS Period,
		|	SourceTable1.CalculationPeriod AS CalculationPeriod,
		|	&RangeNumberField,
		|	&FieldPresentationOfRangeUnit,
		|	SourceTable1.DocumentRecorder AS DocumentRecorder,
		|	SourceTable1.LineNumber AS LineNumber,
		|	SourceTable1.RangeFrom AS RangeFrom,
		|	SourceTable1.RangeBy AS RangeBy,
		|	SourceTable1.Organization AS Organization,
		|	&MemberFields,
		|	SourceTable1.Contract AS Contract,
		|	SourceTable1.Terms AS Terms,
		|	SourceTable1.Products AS Products,
		|	SourceTable1.UnitOfMeasure AS UnitOfMeasure,
		|	SourceTable1.ItemVariantsAreUsed AS ItemVariantsAreUsed,
		|	SourceTable1.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
		|	SourceTable1.Characteristic AS Characteristic,
		|	SourceTable1.PropertyValue AS PropertyValue,
		|	SourceTable1.SumPlan AS SumPlan,
		|	SourceTable1.Count AS Count,
		|	SourceTable1.Currency AS Currency,
		|	SourceTable1.SalesAmount AS SalesAmount,
		|	SourceTable1.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
		|	SourceTable1.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
		|	SourceTable1.BasePrice AS BasePrice,
		|	SourceTable1.BonusPercent AS BonusPercent,
		|	SourceTable1.PlanIsFulfilled AS PlanIsFulfilled,
		|	0 AS CalculationBase,
		|	SourceTable1.CountPlan AS CountPlan,
		|	0 AS AmountToCalculateBonus,
		|	0 AS AmountBonus,
		|	0 AS NumberOfPackages_
		|FROM
		|	&SourceTable1 AS SourceTable1
		|WHERE
		|	&ConditionProhibitionOfAccrualOverPlan
		|	AND NOT SourceTable1.PlanIsFulfilled
		|	AND NOT SourceTable1.FIFODistribution";
		
		If RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.Sum Then
			SourceTable1 = "TT_PreparedData";
		Else
			SourceTable1 = "VT_DataIncludingExceedingLimit";
		EndIf;
		TextOfSubqueryPlanIsNotCompleted = StrReplace(TextOfSubqueryPlanIsNotCompleted, "&SourceTable1", SourceTable1);
		
		If RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.BatchOffer
		 Or RebateConditionsParameters.CalculationScaleByRanges Then
			ConditionProhibitionOfAccrualOverPlan = "TRUE";
		Else
			ConditionProhibitionOfAccrualOverPlan = "SourceTable1.RestrictAccrualOverPlan";
		EndIf;
		TextOfSubqueryPlanIsNotCompleted = StrReplace(
			TextOfSubqueryPlanIsNotCompleted, "&ConditionProhibitionOfAccrualOverPlan", ConditionProhibitionOfAccrualOverPlan);
		
		SubstituteFieldsByParticipants(
			RebateConditionsParameters,
			TextOfSubqueryPlanIsNotCompleted,
			"SourceTable1",
			"",
			True);
		SubstituteRangeNumberField(
			RebateConditionsParameters, TextOfSubqueryPlanIsNotCompleted, "SourceTable1");
		SubstitutePresentationOfRangeUnitField(
			RebateConditionsParameters, TextOfSubqueryPlanIsNotCompleted, "SourceTable1");
		
		QueryText = TextOfSubqueryPlanIsCompleted
			+ TMCommonUse.QuerySeparatorInJoin()
			+ TextOfSubqueryPlanIsNotCompleted;
		
	EndIf;
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextLinesOnBordersOfRangesByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	VT_ExceedingLimitCumulativeTotal.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_ExceedingLimitCumulativeTotal.Organization AS Organization,
	|	&MemberFields,
	|	VT_ExceedingLimitCumulativeTotal.Currency AS Currency,
	|	VT_ExceedingLimitCumulativeTotal.CalculationPeriod AS CalculationPeriod,
	|	VT_ExceedingLimitCumulativeTotal.Priority AS Priority,
	|	VT_ExceedingLimitCumulativeTotal.DocumentRecorder AS DocumentRecorder,
	|	VT_ExceedingLimitCumulativeTotal.Sum AS CumulativeAmount,
	|	VT_ExceedingLimitCumulativeTotal.Count AS AmountIsCumulative,
	|	VT_ExceedingLimitCumulativeTotal.LineAmount AS LineAmount,
	|	VT_ExceedingLimitCumulativeTotal.NumberOfLines AS NumberOfLines,
	|	TT_CalculationScale.RangeNumber AS RangeNumber,
	|	TT_CalculationScale.RangeFrom AS RangeFrom,
	|	TT_CalculationScale.RangeBy AS RangeBy,
	|	TT_CalculationScale.BonusPercent AS BonusPercent,
	|	0 AS BasePrice,
	|	CASE
	|		WHEN TT_CalculationScale.RangeFrom = 0
	|			THEN TT_CalculationScale.RangeBy - VT_ExceedingLimitCumulativeTotal.Sum + VT_ExceedingLimitCumulativeTotal.LineAmount
	|		WHEN TT_CalculationScale.RangeBy = 0
	|			THEN VT_ExceedingLimitCumulativeTotal.Sum - TT_CalculationScale.RangeFrom
	|		WHEN VT_ExceedingLimitCumulativeTotal.Sum < TT_CalculationScale.RangeBy
	|			THEN VT_ExceedingLimitCumulativeTotal.Sum - TT_CalculationScale.RangeFrom
	|		ELSE TT_CalculationScale.RangeBy - TT_CalculationScale.RangeFrom
	|	END AS SpanBalance 
	|INTO TT_LinesOnBoundariesOfRanges
	|FROM
	|	VT_ExceedingLimitCumulativeTotal AS VT_ExceedingLimitCumulativeTotal
	|		INNER JOIN TT_CalculationScale AS TT_CalculationScale
	|		ON TT_CalculationScale.RangeFrom >= VT_ExceedingLimitCumulativeTotal.Sum - VT_ExceedingLimitCumulativeTotal.LineAmount
	|			AND TT_CalculationScale.RangeFrom <= VT_ExceedingLimitCumulativeTotal.Sum
	|
	|UNION ALL
	|
	|SELECT
	|	VT_ExceedingLimitCumulativeTotal.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_ExceedingLimitCumulativeTotal.Organization AS Organization,
	|	&MemberFields,
	|	VT_ExceedingLimitCumulativeTotal.Currency AS Currency,
	|	VT_ExceedingLimitCumulativeTotal.CalculationPeriod AS CalculationPeriod,
	|	VT_ExceedingLimitCumulativeTotal.Priority AS Priority,
	|	VT_ExceedingLimitCumulativeTotal.DocumentRecorder AS DocumentRecorder,
	|	VT_ExceedingLimitCumulativeTotal.Sum AS CumulativeAmount,
	|	VT_ExceedingLimitCumulativeTotal.Count AS AmountIsCumulative,
	|	VT_ExceedingLimitCumulativeTotal.LineAmount AS LineAmount,
	|	VT_ExceedingLimitCumulativeTotal.NumberOfLines AS NumberOfLines,
	|	TT_CalculationScale.RangeNumber AS RangeNumber,
	|	TT_CalculationScale.RangeFrom AS RangeFrom,
	|	TT_CalculationScale.RangeBy AS RangeBy,
	|	TT_CalculationScale.BonusPercent AS BonusPercent,
	|	0 AS BasePrice,
	|	TT_CalculationScale.RangeBy - (VT_ExceedingLimitCumulativeTotal.Sum - VT_ExceedingLimitCumulativeTotal.LineAmount) AS SpanBalance
	|FROM
	|	VT_ExceedingLimitCumulativeTotal AS VT_ExceedingLimitCumulativeTotal
	|		INNER JOIN TT_CalculationScale AS TT_CalculationScale
	|		ON TT_CalculationScale.RangeBy > VT_ExceedingLimitCumulativeTotal.Sum - VT_ExceedingLimitCumulativeTotal.LineAmount
	|			AND TT_CalculationScale.RangeBy <= VT_ExceedingLimitCumulativeTotal.Sum
	|			AND TT_CalculationScale.RangeBy > 0
	|			AND TT_CalculationScale.RangeFrom < VT_ExceedingLimitCumulativeTotal.Sum - VT_ExceedingLimitCumulativeTotal.LineAmount";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "VT_ExceedingLimitCumulativeTotal");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextLinesAtBoundariesOfRangesByNumber(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SubqueryTexts_ = New Array(); // Array of String
	
	SubqueryText =
	"SELECT
	|	VT_ExceedingLimitCumulativeTotal.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_ExceedingLimitCumulativeTotal.Organization AS Organization,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_ExceedingLimitCumulativeTotal.Currency AS Currency,
	|	VT_ExceedingLimitCumulativeTotal.CalculationPeriod AS CalculationPeriod,
	|	VT_ExceedingLimitCumulativeTotal.Priority AS Priority,
	|	VT_ExceedingLimitCumulativeTotal.DocumentRecorder AS DocumentRecorder,
	|	VT_ExceedingLimitCumulativeTotal.Sum AS CumulativeAmount,
	|	VT_ExceedingLimitCumulativeTotal.Count AS AmountIsCumulative,
	|	VT_ExceedingLimitCumulativeTotal.LineAmount AS LineAmount,
	|	VT_ExceedingLimitCumulativeTotal.NumberOfLines AS NumberOfLines,
	|	TT_GoodsRanges.RangeNumber AS RangeNumber,
	|	TT_GoodsRanges.RangeFrom AS RangeFrom,
	|	TT_GoodsRanges.RangeBy AS RangeBy,
	|	TT_GoodsRanges.BonusPercent AS BonusPercent,
	|	TT_GoodsRanges.BasePrice AS BasePrice,
	|	CASE
	|		WHEN TT_GoodsRanges.RangeFrom = 0
	|			THEN TT_GoodsRanges.RangeBy - VT_ExceedingLimitCumulativeTotal.Count + VT_ExceedingLimitCumulativeTotal.NumberOfLines
	|		WHEN TT_GoodsRanges.RangeBy = 0
	|			THEN VT_ExceedingLimitCumulativeTotal.Count - TT_GoodsRanges.RangeFrom
	|		WHEN VT_ExceedingLimitCumulativeTotal.Count < TT_GoodsRanges.RangeBy
	|			THEN VT_ExceedingLimitCumulativeTotal.Count - TT_GoodsRanges.RangeFrom
	|		ELSE TT_GoodsRanges.RangeBy - TT_GoodsRanges.RangeFrom
	|	END AS SpanBalance 
	|INTO TT_LinesOnBoundariesOfRanges
	|FROM
	|	VT_ExceedingLimitCumulativeTotal AS VT_ExceedingLimitCumulativeTotal
	|		INNER JOIN TT_GoodsRanges AS TT_GoodsRanges
	|		ON TT_GoodsRanges.RangeFrom >= VT_ExceedingLimitCumulativeTotal.Count - VT_ExceedingLimitCumulativeTotal.NumberOfLines
	|			AND TT_GoodsRanges.RangeFrom <= VT_ExceedingLimitCumulativeTotal.Count
	|			AND &ConnectionFieldsByGoods
	|		INNER JOIN TT_TurnoverByPeriod AS TurnoverByPeriod
	|		ON &ConnectionConditionsTurnoverByPeriod
	|WHERE
	|	TurnoverByPeriod.Count > TT_GoodsRanges.RangeFrom";
	
	ConnectionConditionsTurnoverByPeriod =
	"VT_ExceedingLimitCumulativeTotal.Currency = TurnoverByPeriod.Currency
	|	AND VT_ExceedingLimitCumulativeTotal.CalculationPeriod = TurnoverByPeriod.CalculationPeriod
	|	AND &ConnectionFieldsByParticipants
	|	AND &ConnectionFieldsByGoods";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		ConnectionConditionsTurnoverByPeriod,
		"VT_ExceedingLimitCumulativeTotal",
		"TurnoverByPeriod");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		ConnectionConditionsTurnoverByPeriod,
		"VT_ExceedingLimitCumulativeTotal",
		"TurnoverByPeriod");
	SubqueryText = StrReplace(SubqueryText, "&ConnectionConditionsTurnoverByPeriod", ConnectionConditionsTurnoverByPeriod);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, SubqueryText, "VT_ExceedingLimitCumulativeTotal", "TT_GoodsRanges");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, SubqueryText, "VT_ExceedingLimitCumulativeTotal", "TT_GoodsRanges");
	
	SubqueryTexts_.Add(SubqueryText);
	
	SubqueryText =
	"SELECT
	|	VT_ExceedingLimitCumulativeTotal.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_ExceedingLimitCumulativeTotal.Organization AS Organization,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_ExceedingLimitCumulativeTotal.Currency AS Currency,
	|	VT_ExceedingLimitCumulativeTotal.CalculationPeriod AS CalculationPeriod,
	|	VT_ExceedingLimitCumulativeTotal.Priority AS Priority,
	|	VT_ExceedingLimitCumulativeTotal.DocumentRecorder AS DocumentRecorder,
	|	VT_ExceedingLimitCumulativeTotal.Sum AS CumulativeAmount,
	|	VT_ExceedingLimitCumulativeTotal.Count AS AmountIsCumulative,
	|	VT_ExceedingLimitCumulativeTotal.LineAmount AS LineAmount,
	|	VT_ExceedingLimitCumulativeTotal.NumberOfLines AS NumberOfLines,
	|	TT_GoodsRanges.RangeNumber AS RangeNumber,
	|	TT_GoodsRanges.RangeFrom AS RangeFrom,
	|	TT_GoodsRanges.RangeBy AS RangeBy,
	|	TT_GoodsRanges.BonusPercent AS BonusPercent,
	|	TT_GoodsRanges.BasePrice AS BasePrice,
	|	TT_GoodsRanges.RangeBy - (VT_ExceedingLimitCumulativeTotal.Count 
	|		- VT_ExceedingLimitCumulativeTotal.NumberOfLines) AS SpanBalance
	|FROM
	|	VT_ExceedingLimitCumulativeTotal AS VT_ExceedingLimitCumulativeTotal
	|		INNER JOIN TT_GoodsRanges AS TT_GoodsRanges
	|		ON TT_GoodsRanges.RangeBy > VT_ExceedingLimitCumulativeTotal.Count - VT_ExceedingLimitCumulativeTotal.NumberOfLines
	|			AND TT_GoodsRanges.RangeBy <= VT_ExceedingLimitCumulativeTotal.Count
	|			AND TT_GoodsRanges.RangeBy > 0
	|			AND TT_GoodsRanges.RangeFrom < VT_ExceedingLimitCumulativeTotal.Count - VT_ExceedingLimitCumulativeTotal.NumberOfLines
	|			AND &ConnectionFieldsByGoods";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, SubqueryText, "VT_ExceedingLimitCumulativeTotal", "TT_GoodsRanges");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, SubqueryText, "VT_ExceedingLimitCumulativeTotal", "TT_GoodsRanges");
	SubqueryTexts_.Add(SubqueryText);
	
	SubqueryText =
	"SELECT
	|	VT_ExceedingLimitCumulativeTotal.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_ExceedingLimitCumulativeTotal.Organization AS Organization,
	|	&MemberFields,
	|	&ProductFields,
	|	VT_ExceedingLimitCumulativeTotal.Currency AS Currency,
	|	VT_ExceedingLimitCumulativeTotal.CalculationPeriod AS CalculationPeriod,
	|	VT_ExceedingLimitCumulativeTotal.Priority AS Priority,
	|	VT_ExceedingLimitCumulativeTotal.DocumentRecorder AS DocumentRecorder,
	|	VT_ExceedingLimitCumulativeTotal.Sum AS CumulativeAmount,
	|	VT_ExceedingLimitCumulativeTotal.Count AS AmountIsCumulative,
	|	VT_ExceedingLimitCumulativeTotal.LineAmount AS LineAmount,
	|	VT_ExceedingLimitCumulativeTotal.NumberOfLines AS NumberOfLines,
	|	TT_GoodsRanges.RangeNumber AS RangeNumber,
	|	TT_GoodsRanges.RangeFrom AS RangeFrom,
	|	TT_GoodsRanges.RangeBy AS RangeBy,
	|	TT_GoodsRanges.BonusPercent AS BonusPercent,
	|	TT_GoodsRanges.BasePrice AS BasePrice,
	|	TT_GoodsRanges.RangeBy - VT_ExceedingLimitCumulativeTotal.Count AS SpanBalance
	|FROM
	|	VT_ExceedingLimitCumulativeTotal AS VT_ExceedingLimitCumulativeTotal
	|		INNER JOIN TT_GoodsRanges AS TT_GoodsRanges
	|		ON TT_GoodsRanges.RangeBy = VT_ExceedingLimitCumulativeTotal.Count
	|			AND VT_ExceedingLimitCumulativeTotal.NumberOfLines = 0
	|			AND TT_GoodsRanges.RangeBy > 0
	|			AND TT_GoodsRanges.RangeFrom < VT_ExceedingLimitCumulativeTotal.Count
	|			AND &ConnectionFieldsByGoods";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, SubqueryText, "VT_ExceedingLimitCumulativeTotal", "TT_GoodsRanges");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, SubqueryText, "VT_ExceedingLimitCumulativeTotal", "TT_GoodsRanges");
	
	SubqueryTexts_.Add(SubqueryText);
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDistributionOfRowsByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		ExpressionValueOfCheck = "TT_PreparedData.CountOfChecks";
		ExpressionIsValueOfStringFrom = "TT_PrioritiesBalancesAtBoundariesOfRanges.NumberOfLinesFrom";
		ExpressionIsValueOfStringBy = "TT_PrioritiesBalancesAtBoundariesOfRanges.NumberOfLinesBy";
		ExpressionBasePrice = "TT_PrioritiesBalancesAtBoundariesOfRanges.BasePrice";
		
		If RebateConditionsParameters.CalculationInBasePrices Then
			
			ExpressionCalculationBaseOnRight = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BasePrice
				| * TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceFrom AS NUMBER(31, 2))";
			ExpressionBonusOnRight = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.BasePrice
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceFrom / 100 AS NUMBER(31, 2))";
			
			ExpressionCalculationBaseOnLeft = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BasePrice
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceBy AS NUMBER(31, 2))";
			ExpressionBonusOnLeft = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.BasePrice
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceBy / 100 AS NUMBER(31, 2))";
			
			ExpressionCalculationBaseInside = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BasePrice
				|* TT_PreparedData.Count AS NUMBER(31, 2))";
			ExpressionBonusInside = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.BasePrice
				|* TT_PreparedData.Count / 100 AS NUMBER(31, 2))";
			
		Else
			
			ExpressionCalculationBaseOnRight = "CAST(TT_PreparedData.CalculationBase
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceFrom
				|/ TT_PrioritiesBalancesAtBoundariesOfRanges.NumberOfLinesFrom AS NUMBER(31, 2))";
			ExpressionBonusOnRight = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
				|* TT_PreparedData.CalculationBase
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceFrom
				|/ TT_PrioritiesBalancesAtBoundariesOfRanges.NumberOfLinesFrom / 100 AS NUMBER(31, 2))";
			
			ExpressionCalculationBaseOnLeft = "CAST(TT_PreparedData.CalculationBase
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceBy 
				|/ TT_PrioritiesBalancesAtBoundariesOfRanges.NumberOfLinesBy AS NUMBER(31, 2))";
			ExpressionBonusOnLeft = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
				|* TT_PreparedData.CalculationBase
				|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceBy
				|/ TT_PrioritiesBalancesAtBoundariesOfRanges.NumberOfLinesBy / 100 AS NUMBER(31, 2))";
			
			ExpressionCalculationBaseInside = "TT_PreparedData.CalculationBase";
			ExpressionBonusInside = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
				|* TT_PreparedData.CalculationBase / 100 AS NUMBER(31, 2))";
			
		EndIf;
		
	Else
		
		ExpressionValueOfCheck = "TT_PreparedData.VerificationAmount";
		ExpressionIsValueOfStringFrom = "TT_PrioritiesBalancesAtBoundariesOfRanges.SumOfLineFrom";
		ExpressionIsValueOfStringBy = "TT_PrioritiesBalancesAtBoundariesOfRanges.SumOfLineBy"; 
		ExpressionBasePrice = "TT_PreparedData.BasePrice";
		
		ExpressionCalculationBaseOnRight = "TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceFrom";
		ExpressionBonusOnRight = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
			|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceFrom / 100 AS NUMBER(31, 2))";
		
		ExpressionCalculationBaseOnLeft = "TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceBy";
		ExpressionBonusOnLeft = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
			|* TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceBy / 100 AS NUMBER(31, 2))";
		
		ExpressionCalculationBaseInside = "TT_PreparedData.CalculationBase";
		ExpressionBonusInside = "CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent
			|* TT_PreparedData.CalculationBase / 100 AS NUMBER(31, 2))";
		
	EndIf;
	
	SubqueryTexts_ = New Array; // Array of String
	
	// For the right parts of the lines at the boundaries of the range, we take the Balance of the cumulative total in the range
	TextOfSubqueryIsRightPartsOfLines =
	"SELECT
	|	FALSE AS Allocated,
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator AS GoodsIndicator,
	|	TT_PreparedData.Period AS Period,
	|	TT_PreparedData.Organization AS Organization,
	|	TT_PreparedData.Contract AS Contract,
	|	TT_PreparedData.Terms AS Terms,
	|	TT_PreparedData.UnitOfMeasure AS UnitOfMeasure,
	|	TT_PreparedData.PartyCountDetails AS PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency AS AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency AS ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_PreparedData.SumPlan AS SumPlan,
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	TT_PreparedData.Currency AS Currency,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.LineNumber AS LineNumber,
	|	TT_PreparedData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_PreparedData.Products AS Products,
	|	TT_PreparedData.Characteristic AS Characteristic,
	|	TT_PreparedData.PropertyValue AS PropertyValue,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.Priority AS Priority,
	|	0 AS Count,
	|	0 AS CountPlanBalance,
	|	0 AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	0 AS SalesAmount,
	|	0 AS AmountOfTurnoverWithVAT,
	|	0 AS AmountOfTurnoverExcludingVAT,
	|	TT_PreparedData.CalculationBase AS CalculationBaseIsInitial,
	|	CASE
	|		WHEN TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy = 0
	|			THEN &ExpressionValueOfCheck - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|		WHEN &ExpressionValueOfCheck <= TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy
	|			THEN &ExpressionValueOfCheck - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|		ELSE TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|	END AS RangeWidth,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeNumber AS RangeNumber,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom AS RangeFrom,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy AS RangeBy,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent AS BonusPercent,
	|	&ExpressionBasePrice AS BasePrice,
	|	TT_PreparedData.VerificationAmount AS VerificationAmount,
	|	TT_PreparedData.CountOfChecks AS CountOfChecks,
	|	FALSE AS FirstRangeOfDocument,
	|	CASE
	|		WHEN &ExpressionIsValueOfStringFrom = 0
	|			THEN 0
	|		ELSE TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceFrom
	|	END AS AmountToCalculateBonus,
	|	CASE
	|		WHEN &ExpressionIsValueOfStringFrom = 0
	|			THEN 0
	|		ELSE &ExpressionCalculationBaseOnRight
	|	END AS CalculationBase,
	|	CASE
	|		WHEN &ExpressionIsValueOfStringFrom = 0
	|			THEN 0
	|		ELSE &ExpressionBonusOnRight
	|	END AS AmountBonus
	|INTO TT_DistributionOfRowsByRanges
	|FROM
	|	TT_PrioritiesBalancesAtBoundariesOfRanges AS TT_PrioritiesBalancesAtBoundariesOfRanges
	|		INNER JOIN TT_PreparedData AS TT_PreparedData
	|		ON TT_PrioritiesBalancesAtBoundariesOfRanges.Currency = TT_PreparedData.Currency
	|			AND TT_PrioritiesBalancesAtBoundariesOfRanges.CalculationPeriod = TT_PreparedData.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND TT_PrioritiesBalancesAtBoundariesOfRanges.PriorityFrom = TT_PreparedData.Priority
	|WHERE
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceFrom <> 0";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfSubqueryIsRightPartsOfLines,
		"TT_PrioritiesBalancesAtBoundariesOfRanges",
		"TT_PreparedData");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		TextOfSubqueryIsRightPartsOfLines,
		"TT_PrioritiesBalancesAtBoundariesOfRanges",
		"TT_PreparedData");
	SubqueryTexts_.Add(TextOfSubqueryIsRightPartsOfLines);
	
	// For the left parts of the lines at the boundaries of the range, we take the Balance of the cumulative total in the range
	TextOfSubqueryLeftPartsOfLines =
	"SELECT
	|	TRUE AS Allocated,
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator AS GoodsIndicator,
	|	TT_PreparedData.Period AS Period,
	|	TT_PreparedData.Organization AS Organization,
	|	TT_PreparedData.Contract AS Contract,
	|	TT_PreparedData.Terms AS Terms,
	|	TT_PreparedData.UnitOfMeasure AS UnitOfMeasure,
	|	TT_PreparedData.PartyCountDetails AS PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency AS AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency AS ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_PreparedData.SumPlan AS SumPlan,
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	TT_PreparedData.Currency AS Currency,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.LineNumber AS LineNumber,
	|	TT_PreparedData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_PreparedData.Products AS Products,
	|	TT_PreparedData.Characteristic AS Characteristic,
	|	TT_PreparedData.PropertyValue AS PropertyValue,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.Priority AS Priority,
	|	CASE
	|		WHEN (TT_PrioritiesBalancesAtBoundariesOfRanges.PriorityFrom <> TT_PrioritiesBalancesAtBoundariesOfRanges.SoftwarePriority)
	|			THEN TT_PreparedData.Count
	|		ELSE 0
	|	END AS Count,
	|	0 AS CountPlanBalance,
	|	0 AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	CASE
	|		WHEN (TT_PrioritiesBalancesAtBoundariesOfRanges.PriorityFrom <> TT_PrioritiesBalancesAtBoundariesOfRanges.SoftwarePriority)
	|			THEN TT_PreparedData.SalesAmount
	|		ELSE 0
	|	END AS SalesAmount,
	|	CASE
	|		WHEN (TT_PrioritiesBalancesAtBoundariesOfRanges.PriorityFrom <> TT_PrioritiesBalancesAtBoundariesOfRanges.SoftwarePriority)
	|			THEN TT_PreparedData.AmountOfTurnoverWithVAT
	|		ELSE 0
	|	END AS AmountOfTurnoverWithVAT,
	|	CASE
	|		WHEN (TT_PrioritiesBalancesAtBoundariesOfRanges.PriorityFrom <> TT_PrioritiesBalancesAtBoundariesOfRanges.SoftwarePriority)
	|			THEN TT_PreparedData.AmountOfTurnoverExcludingVAT
	|		ELSE 0
	|	END AS AmountOfTurnoverExcludingVAT,
	|	TT_PreparedData.CalculationBase AS CalculationBaseIsInitial,
	|	CASE
	|		WHEN TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy = 0
	|			THEN &ExpressionValueOfCheck - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|		WHEN &ExpressionValueOfCheck <= TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy
	|			THEN &ExpressionValueOfCheck - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|		ELSE TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|	END AS RangeWidth,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeNumber AS RangeNumber,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom AS RangeFrom,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy AS RangeBy,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent AS BonusPercent,
	|	&ExpressionBasePrice AS BasePrice,
	|	TT_PreparedData.VerificationAmount AS VerificationAmount,
	|	TT_PreparedData.CountOfChecks AS CountOfChecks,
	|	(TT_PrioritiesBalancesAtBoundariesOfRanges.PriorityFrom <> TT_PrioritiesBalancesAtBoundariesOfRanges.SoftwarePriority) AS FirstRangeOfDocument,
	|	CASE
	|		WHEN &ExpressionIsValueOfStringBy = 0
	|			THEN 0
	|		ELSE CAST(TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceBy * TT_PreparedData.Count
	|			/ &ExpressionIsValueOfStringBy AS NUMBER(15, 6))
	|	END AS AmountToCalculateBonus,
	|	CASE
	|		WHEN &ExpressionIsValueOfStringBy = 0
	|			THEN 0
	|		ELSE &ExpressionCalculationBaseOnLeft
	|	END AS CalculationBase,
	|	CASE
	|		WHEN &ExpressionIsValueOfStringBy = 0
	|			THEN 0
	|		ELSE &ExpressionBonusOnLeft
	|	END AS AmountBonus
	|FROM
	|	TT_PrioritiesBalancesAtBoundariesOfRanges AS TT_PrioritiesBalancesAtBoundariesOfRanges
	|		INNER JOIN TT_PreparedData AS TT_PreparedData
	|		ON TT_PrioritiesBalancesAtBoundariesOfRanges.Currency = TT_PreparedData.Currency
	|			AND TT_PrioritiesBalancesAtBoundariesOfRanges.CalculationPeriod = TT_PreparedData.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND TT_PrioritiesBalancesAtBoundariesOfRanges.SoftwarePriority = TT_PreparedData.Priority
	|WHERE
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeOfBalanceBy <> 0
	|		OR &ExpressionIsValueOfStringBy = 0";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfSubqueryLeftPartsOfLines,
		"TT_PrioritiesBalancesAtBoundariesOfRanges",
		"TT_PreparedData");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		TextOfSubqueryLeftPartsOfLines,
		"TT_PrioritiesBalancesAtBoundariesOfRanges",
		"TT_PreparedData");
	
	SubqueryTexts_.Add(TextOfSubqueryLeftPartsOfLines);
	
	TextOfDocumentsSubqueryWithinRanges =
	"SELECT
	|	TRUE AS Allocated,
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator AS GoodsIndicator,
	|	TT_PreparedData.Period AS Period,
	|	TT_PreparedData.Organization AS Organization,
	|	TT_PreparedData.Contract AS Contract,
	|	TT_PreparedData.Terms AS Terms,
	|	TT_PreparedData.UnitOfMeasure AS UnitOfMeasure,
	|	TT_PreparedData.PartyCountDetails AS PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency AS AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency AS ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_PreparedData.SumPlan AS SumPlan,
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	TT_PreparedData.Currency AS Currency,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.LineNumber AS LineNumber,
	|	TT_PreparedData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_PreparedData.Products AS Products,
	|	TT_PreparedData.Characteristic AS Characteristic,
	|	TT_PreparedData.PropertyValue AS PropertyValue,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.Priority AS Priority,
	|	TT_PreparedData.Count AS Count,
	|	0 AS CountPlanBalance,
	|	0 AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	TT_PreparedData.SalesAmount AS SalesAmount,
	|	TT_PreparedData.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	TT_PreparedData.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	TT_PreparedData.CalculationBase AS CalculationBaseIsInitial,
	|	CASE
	|		WHEN TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy = 0
	|			THEN &ExpressionValueOfCheck - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|		WHEN &ExpressionValueOfCheck <= TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy
	|			THEN &ExpressionValueOfCheck - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|		ELSE TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|	END AS RangeWidth,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeNumber AS RangeNumber,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom AS RangeFrom,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy AS RangeBy,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent AS BonusPercent,
	|	&ExpressionBasePrice AS BasePrice,
	|	TT_PreparedData.VerificationAmount AS VerificationAmount,
	|	TT_PreparedData.CountOfChecks AS CountOfChecks,
	|	TRUE AS FirstRangeOfDocument,
	|	TT_PreparedData.Count AS AmountToCalculateBonus,
	|	&ExpressionCalculationBaseInside AS CalculationBase,
	|	&ExpressionBonusInside AS AmountBonus
	|FROM
	|	TT_PreparedData AS TT_PreparedData
	|		INNER JOIN TT_PrioritiesBalancesAtBoundariesOfRanges AS TT_PrioritiesBalancesAtBoundariesOfRanges
	|		ON TT_PreparedData.Currency = TT_PrioritiesBalancesAtBoundariesOfRanges.Currency
	|			AND TT_PreparedData.CalculationPeriod = TT_PrioritiesBalancesAtBoundariesOfRanges.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND TT_PreparedData.Priority > TT_PrioritiesBalancesAtBoundariesOfRanges.PriorityFrom
	|			AND TT_PreparedData.Priority < TT_PrioritiesBalancesAtBoundariesOfRanges.SoftwarePriority
	|";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfDocumentsSubqueryWithinRanges,
		"TT_PreparedData",
		"TT_PrioritiesBalancesAtBoundariesOfRanges");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		TextOfDocumentsSubqueryWithinRanges,
		"TT_PreparedData",
		"TT_PrioritiesBalancesAtBoundariesOfRanges");
	SubqueryTexts_.Add(TextOfDocumentsSubqueryWithinRanges);
	
	TextOfDocumentsSubqueryIsInLastRange =
	"SELECT
	|	TRUE AS Allocated,
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator AS GoodsIndicator,
	|	TT_PreparedData.Period AS Period,
	|	TT_PreparedData.Organization AS Organization,
	|	TT_PreparedData.Contract AS Contract,
	|	TT_PreparedData.Terms AS Terms,
	|	TT_PreparedData.UnitOfMeasure AS UnitOfMeasure,
	|	TT_PreparedData.PartyCountDetails AS PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency AS AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency AS ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_PreparedData.SumPlan AS SumPlan,
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	TT_PreparedData.Currency AS Currency,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.LineNumber AS LineNumber,
	|	TT_PreparedData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_PreparedData.Products AS Products,
	|	TT_PreparedData.Characteristic AS Characteristic,
	|	TT_PreparedData.PropertyValue AS PropertyValue,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.Priority AS Priority,
	|	TT_PreparedData.Count AS Count,
	|	0 AS CountPlanBalance,
	|	0 AS NumberOfPlansTakingIntoAccountMultiplicityOfSales,
	|	TT_PreparedData.SalesAmount AS SalesAmount,
	|	TT_PreparedData.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	TT_PreparedData.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	TT_PreparedData.CalculationBase AS CalculationBaseIsInitial,
	|	CASE
	|		WHEN TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy = 0
	|			THEN &ExpressionValueOfCheck - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|		WHEN &ExpressionValueOfCheck <= TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy
	|			THEN &ExpressionValueOfCheck - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|		ELSE TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy - TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom
	|	END AS RangeWidth,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeNumber AS RangeNumber,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeFrom AS RangeFrom,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.RangeBy AS RangeBy,
	|	TT_PrioritiesBalancesAtBoundariesOfRanges.BonusPercent AS BonusPercent,
	|	&ExpressionBasePrice AS BasePrice,
	|	TT_PreparedData.VerificationAmount AS VerificationAmount,
	|	TT_PreparedData.CountOfChecks AS CountOfChecks,
	|	TRUE AS FirstRangeOfDocument,
	|	TT_PreparedData.Count AS AmountToCalculateBonus,
	|	&ExpressionCalculationBaseInside AS CalculationBase,
	|	&ExpressionBonusInside AS AmountBonus
	|FROM
	|	TT_PreparedData AS TT_PreparedData
	|		INNER JOIN TT_PrioritiesBalancesAtBoundariesOfRanges AS TT_PrioritiesBalancesAtBoundariesOfRanges
	|		ON TT_PreparedData.Priority > TT_PrioritiesBalancesAtBoundariesOfRanges.PriorityFrom
	|			AND TT_PrioritiesBalancesAtBoundariesOfRanges.SoftwarePriority = -1
	|			AND TT_PreparedData.Currency = TT_PrioritiesBalancesAtBoundariesOfRanges.Currency
	|			AND TT_PreparedData.CalculationPeriod = TT_PrioritiesBalancesAtBoundariesOfRanges.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND &ExpressionValueOfCheck > 0";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfDocumentsSubqueryIsInLastRange,
		"TT_PreparedData",
		"TT_PrioritiesBalancesAtBoundariesOfRanges");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		TextOfDocumentsSubqueryIsInLastRange,
		"TT_PreparedData",
		"TT_PrioritiesBalancesAtBoundariesOfRanges");
	SubqueryTexts_.Add(TextOfDocumentsSubqueryIsInLastRange);
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	
	QueryText = StrReplace(QueryText, "&ExpressionValueOfCheck", ExpressionValueOfCheck);
	QueryText = StrReplace(QueryText, "&ExpressionIsValueOfStringFrom", ExpressionIsValueOfStringFrom);
	QueryText = StrReplace(QueryText, "&ExpressionIsValueOfStringBy", ExpressionIsValueOfStringBy);
	QueryText = StrReplace(QueryText, "&ExpressionCalculationBaseOnRight", ExpressionCalculationBaseOnRight);
	QueryText = StrReplace(QueryText, "&ExpressionCalculationBaseOnLeft", ExpressionCalculationBaseOnLeft);
	QueryText = StrReplace(QueryText, "&ExpressionCalculationBaseInside", ExpressionCalculationBaseInside);
	QueryText = StrReplace(QueryText, "&ExpressionBonusOnRight", ExpressionBonusOnRight);
	QueryText = StrReplace(QueryText, "&ExpressionBonusOnLeft", ExpressionBonusOnLeft);
	QueryText = StrReplace(QueryText, "&ExpressionBonusInside", ExpressionBonusInside);
	QueryText = StrReplace(QueryText, "&ExpressionBasePrice", ExpressionBasePrice);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextTotalsOfDatabaseByWidthOfRanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	SourceTable1.Currency AS Currency,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.RangeNumber AS RangeNumber,
	|	SourceTable1.RangeWidth AS RangeWidth,
	|	MAX(
	|		CASE
	|			WHEN SourceTable1.CalculationBase > 0
	|				THEN SourceTable1.Priority
	|			ELSE -1
	|		END) AS RoundingPriority,
	|	SUM(SourceTable1.Count) AS Quantity_Total_,
	|	SUM(SourceTable1.AmountToCalculateBonus) AS AmountToCalculateBonus_Total,
	|	SUM(SourceTable1.CalculationBase) AS SettlementBaseTotal
	|INTO TT_TotalsOfDatabaseByWidthOfRanges
	|FROM
	|	TT_DistributionOfRowsByRanges AS SourceTable1
	|
	|GROUP BY
	|	SourceTable1.Currency,
	|	SourceTable1.CalculationPeriod,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	SourceTable1.RangeNumber,
	|	SourceTable1.RangeWidth";
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextCorrectionOfBaseErrorByFIFORanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	SourceTable1.Allocated AS Allocated,
	|	SourceTable1.Currency AS Currency,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.DocumentRecorder AS DocumentRecorder,
	|	SourceTable1.Priority AS Priority,
	|	SourceTable1.RangeNumber AS RangeNumber,
	|	SourceTable1.RangeFrom AS RangeFrom,
	|	SourceTable1.RangeBy AS RangeBy,
	|	SourceTable1.BonusPercent AS BonusPercent,
	|	SourceTable1.BasePrice AS BasePrice,
	|	ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.RangeWidth, 0) AS RangeWidth,
	|	SourceTable1.FirstRangeOfDocument AS FirstRangeOfDocument,
	|	SourceTable1.VerificationAmount AS VerificationAmount,
	|	SourceTable1.CountOfChecks AS CountOfChecks,
	|	SourceTable1.CalculationBaseIsInitial AS CalculationBaseIsInitial,
	|	SourceTable1.CalculationBase AS CalculationBaseBeforeAdjustment,
	|	SourceTable1.AmountToCalculateBonus AS AmountToCalculateBonusBeforeAdjustment,
	|	ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.RoundingPriority, -1) AS RoundingPriority,
	|	CASE
	|		WHEN SourceTable1.Priority = ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.RoundingPriority, -1)
	|			THEN &ExpressionCalculationBase
	|		ELSE SourceTable1.CalculationBase
	|	END AS CalculationBase,
	|	CASE
	|		WHEN SourceTable1.Priority = ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.RoundingPriority, -1)
	|			THEN SourceTable1.AmountToCalculateBonus + ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.RangeWidth, 0)
	|				- ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.AmountToCalculateBonus_Total, 0)
	|		ELSE SourceTable1.AmountToCalculateBonus
	|	END AS AmountToCalculateBonus,
	|	SourceTable1.AmountBonus AS BonusAmountBeforeAdjustment,
	|	CASE
	|		WHEN SourceTable1.Priority = ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.RoundingPriority, -1)
	|			THEN CAST(&ExpressionCalculationBase * SourceTable1.BonusPercent / 100 AS NUMBER(31, 2))
	|		ELSE CAST(SourceTable1.CalculationBase * SourceTable1.BonusPercent / 100 AS NUMBER(31, 2))
	|	END AS AmountBonus
	|INTO TT_CorrectionOfBaseErrorByFIFORanges
	|FROM
	|	TT_DistributionOfRowsByRanges AS SourceTable1
	|		LEFT JOIN TT_TotalsOfDatabaseByWidthOfRanges AS TT_TotalsOfDatabaseByWidthOfRanges
	|		ON SourceTable1.Currency = TT_TotalsOfDatabaseByWidthOfRanges.Currency
	|			AND SourceTable1.CalculationPeriod = TT_TotalsOfDatabaseByWidthOfRanges.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND SourceTable1.RangeNumber = TT_TotalsOfDatabaseByWidthOfRanges.RangeNumber";
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		If RebateConditionsParameters.CalculationInBasePrices Then
			
			ExpressionCalculationBase = "(SourceTable1.CalculationBase + CAST(ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.RangeWidth, 0) * SourceTable1.BasePrice AS NUMBER(31, 2))
				|- ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.SettlementBaseTotal, 0))";
			
		Else
			
			ExpressionCalculationBase = "SourceTable1.CalculationBase";
			
		EndIf;
		
	Else
		
		ExpressionCalculationBase = "SourceTable1.CalculationBase + ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.RangeWidth, 0)
			|- ISNULL(TT_TotalsOfDatabaseByWidthOfRanges.SettlementBaseTotal, 0)";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ExpressionCalculationBase", ExpressionCalculationBase);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1", "TT_TotalsOfDatabaseByWidthOfRanges");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1", "TT_TotalsOfDatabaseByWidthOfRanges");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextBalancesOfDatabaseByFIFORanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SubqueryTexts_ = New Array; // Array of String
	
	TextOfSubqueryLeftPartsOfLines =
	"SELECT
	|	TT_CorrectionOfBaseErrorByFIFORanges.Allocated AS Allocated,
	|	TT_CorrectionOfBaseErrorByFIFORanges.Currency AS Currency,
	|	TT_CorrectionOfBaseErrorByFIFORanges.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	TT_CorrectionOfBaseErrorByFIFORanges.DocumentRecorder AS DocumentRecorder,
	|	TT_CorrectionOfBaseErrorByFIFORanges.Priority AS Priority,
	|	CASE
	|		WHEN SourceTable1.RangeBy = 0
	|			THEN &ExpressionValueOfCheck - SourceTable1.RangeFrom
	|		WHEN &ExpressionValueOfCheck <= SourceTable1.RangeBy
	|			THEN &ExpressionValueOfCheck - SourceTable1.RangeFrom
	|		ELSE SourceTable1.RangeBy - SourceTable1.RangeFrom
	|	END AS RangeWidth,
	|	TT_CorrectionOfBaseErrorByFIFORanges.RoundingPriority AS RoundingPriority,
	|	SourceTable1.RangeNumber AS RangeNumber,
	|	SourceTable1.RangeFrom AS RangeFrom,
	|	SourceTable1.RangeBy AS RangeBy,
	|	SourceTable1.BonusPercent AS BonusPercent,
	|	SourceTable1.BasePrice AS BasePrice,
	|	-1 * TT_CorrectionOfBaseErrorByFIFORanges.AmountToCalculateBonus AS AmountToCalculateBonus,
	|	-1 * TT_CorrectionOfBaseErrorByFIFORanges.CalculationBase AS CalculationBase
	|INTO TT_BalancesOfDatabaseByFIFORanges
	|FROM
	|	TT_PrioritiesBalancesAtBoundariesOfRanges AS SourceTable1
	|		INNER JOIN TT_CorrectionOfBaseErrorByFIFORanges AS TT_CorrectionOfBaseErrorByFIFORanges
	|		ON SourceTable1.Currency = TT_CorrectionOfBaseErrorByFIFORanges.Currency
	|			AND SourceTable1.CalculationPeriod = TT_CorrectionOfBaseErrorByFIFORanges.CalculationPeriod
	|			AND SourceTable1.PriorityFrom = TT_CorrectionOfBaseErrorByFIFORanges.Priority
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND (TT_CorrectionOfBaseErrorByFIFORanges.Allocated = TRUE)
	|WHERE
	|	SourceTable1.RangeOfBalanceFrom <> 0";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfSubqueryLeftPartsOfLines,
		"TT_CorrectionOfBaseErrorByFIFORanges",
		"SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters,
		TextOfSubqueryLeftPartsOfLines,
		"TT_CorrectionOfBaseErrorByFIFORanges",
		"SourceTable1");
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		ExpressionValueOfCheck = "TT_CorrectionOfBaseErrorByFIFORanges.CountOfChecks";
	Else
		ExpressionValueOfCheck = "TT_CorrectionOfBaseErrorByFIFORanges.VerificationAmount";
	EndIf;
	TextOfSubqueryLeftPartsOfLines = StrReplace(
		TextOfSubqueryLeftPartsOfLines, "&ExpressionValueOfCheck", ExpressionValueOfCheck);
	
	SubqueryTexts_.Add(TextOfSubqueryLeftPartsOfLines);
	
	TextOfSubquerySourceLines =
	"SELECT
	|	FALSE AS Allocated,
	|	TT_PreparedData.Currency AS Currency,
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.Priority AS Priority,
	|	CASE
	|		WHEN SourceTable1.RangeBy = 0
	|			THEN &ExpressionValueOfCheck - SourceTable1.RangeFrom
	|		WHEN &ExpressionValueOfCheck <= SourceTable1.RangeBy
	|			THEN &ExpressionValueOfCheck - SourceTable1.RangeFrom
	|		ELSE SourceTable1.RangeBy - SourceTable1.RangeFrom
	|	END AS RangeWidth,
	|	-1 AS RoundingPriority,
	|	SourceTable1.RangeNumber AS RangeNumber,
	|	SourceTable1.RangeFrom AS RangeFrom,
	|	SourceTable1.RangeBy AS RangeBy,
	|	SourceTable1.BonusPercent AS BonusPercent,
	|	SourceTable1.BasePrice AS BasePrice,
	|	TT_PreparedData.Count AS AmountToCalculateBonus,
	|	&ExpressionCalculationBase AS CalculationBase
	|FROM
	|	TT_PrioritiesBalancesAtBoundariesOfRanges AS SourceTable1
	|		INNER JOIN TT_PreparedData AS TT_PreparedData
	|		ON SourceTable1.Currency = TT_PreparedData.Currency
	|			AND SourceTable1.CalculationPeriod = TT_PreparedData.CalculationPeriod
	|			AND SourceTable1.PriorityFrom = TT_PreparedData.Priority
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods 
	|WHERE
	|	SourceTable1.RangeOfBalanceFrom <> 0";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfSubquerySourceLines,
		"TT_PreparedData",
		"SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters,
		TextOfSubquerySourceLines,
		"TT_PreparedData",
		"SourceTable1");
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		ExpressionValueOfCheck = "TT_PreparedData.CountOfChecks";
		
		If RebateConditionsParameters.CalculationInBasePrices Then
			
			ExpressionCalculationBase = "CAST(TT_PreparedData.Count * SourceTable1.BasePrice AS NUMBER(31, 2))";
			
		Else
			
			ExpressionCalculationBase = "TT_PreparedData.CalculationBase";
			
		EndIf;
		
	Else
		
		ExpressionValueOfCheck = "TT_PreparedData.VerificationAmount";
		ExpressionCalculationBase = "TT_PreparedData.CalculationBase";
		
	EndIf;
	
	TextOfSubquerySourceLines = StrReplace(TextOfSubquerySourceLines, "&ExpressionValueOfCheck", ExpressionValueOfCheck);
	TextOfSubquerySourceLines = StrReplace(TextOfSubquerySourceLines, "&ExpressionCalculationBase", ExpressionCalculationBase);
	
	SubqueryTexts_.Add(TextOfSubquerySourceLines);
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextDataForBonusDistributionByFIFORanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	// In the first sample, we expand the "left" parts of the lines of the boundary documents by ranges, we take the base as the Balance after the distribution by ranges.
	// In the second sample, we supplement the already distributed "right" parts of the lines.
	
	SubqueryTexts_ = New Array; // Array of String
	
	SubqueryTextLeftParts =
	"SELECT
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator AS GoodsIndicator,
	|	TT_PreparedData.Period AS Period,
	|	TT_BalancesOfDatabaseByFIFORanges.CalculationPeriod AS CalculationPeriod,
	|	TT_BalancesOfDatabaseByFIFORanges.RangeNumber AS RangeNumber,
	|	TT_BalancesOfDatabaseByFIFORanges.RangeFrom AS RangeFrom,
	|	TT_BalancesOfDatabaseByFIFORanges.RangeBy AS RangeBy,
	|	TT_BalancesOfDatabaseByFIFORanges.BonusPercent AS BonusPercent,
	|	&ExpressionBasePrice AS BasePrice,
	|	TT_BalancesOfDatabaseByFIFORanges.RangeWidth AS RangeWidth,
	|	TT_BalancesOfDatabaseByFIFORanges.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.LineNumber AS LineNumber,
	|	TT_BalancesOfDatabaseByFIFORanges.Priority AS Priority,
	|	MAX(TT_BalancesOfDatabaseByFIFORanges.RoundingPriority) AS RoundingPriority,
	|	TT_PreparedData.Organization AS Organization,
	|	&MemberFields,
	|	TT_PreparedData.Contract AS Contract,
	|	TT_PreparedData.Terms AS Terms,
	|	TT_PreparedData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_PreparedData.Products AS Products,
	|	TT_PreparedData.UnitOfMeasure AS UnitOfMeasure,
	|	TT_PreparedData.Characteristic AS Characteristic,
	|	TT_PreparedData.PropertyValue AS PropertyValue,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.PartyCountDetails AS PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency AS AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency AS ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_PreparedData.Currency AS Currency,
	|	0 AS Count,
	|	0 AS SalesAmount,
	|	0 AS AmountOfTurnoverWithVAT,
	|	0 AS AmountOfTurnoverExcludingVAT,
	|	TT_PreparedData.SumPlan AS SumPlan,
	|	TRUE AS PlanIsFulfilled,
	|	0 AS CountPlan,
	|	SUM(TT_BalancesOfDatabaseByFIFORanges.AmountToCalculateBonus) AS AmountToCalculateBonus,
	|	0 AS NumberOfPackages_,
	|	SUM(TT_BalancesOfDatabaseByFIFORanges.CalculationBase) AS CalculationBase,
	|	CAST(SUM(TT_BalancesOfDatabaseByFIFORanges.CalculationBase) * TT_BalancesOfDatabaseByFIFORanges.BonusPercent
	|		/ 100 AS NUMBER(31, 2)) AS AmountBonus
	|INTO TT_DataForDistributionOfBonusByFIFORanges
	|FROM
	|	TT_BalancesOfDatabaseByFIFORanges AS TT_BalancesOfDatabaseByFIFORanges
	|	INNER JOIN TT_PreparedData AS TT_PreparedData
	|		ON TT_BalancesOfDatabaseByFIFORanges.DocumentRecorder = TT_PreparedData.DocumentRecorder
	|			AND TT_BalancesOfDatabaseByFIFORanges.Priority = TT_PreparedData.Priority
	|			AND &ConnectionFieldsByGoods
	|
	|GROUP BY
	|	TT_PreparedData.ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator,
	|	TT_PreparedData.Period,
	|	TT_BalancesOfDatabaseByFIFORanges.CalculationPeriod,
	|	TT_BalancesOfDatabaseByFIFORanges.RangeNumber,
	|	TT_BalancesOfDatabaseByFIFORanges.RangeFrom,
	|	TT_BalancesOfDatabaseByFIFORanges.RangeBy,
	|	TT_BalancesOfDatabaseByFIFORanges.BonusPercent,
	|	&ExpressionBasePrice,
	|	TT_BalancesOfDatabaseByFIFORanges.RangeWidth,
	|	TT_BalancesOfDatabaseByFIFORanges.DocumentRecorder,
	|	TT_PreparedData.LineNumber,
	|	TT_BalancesOfDatabaseByFIFORanges.Priority,
	|	TT_PreparedData.Organization,
	|	&GroupingFieldsByParticipants,
	|	TT_PreparedData.Contract,
	|	TT_PreparedData.Terms,
	|	TT_PreparedData.ItemVariantsAreUsed,
	|	TT_PreparedData.Products,
	|	TT_PreparedData.UnitOfMeasure,
	|	TT_PreparedData.Characteristic,
	|	TT_PreparedData.PropertyValue,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan,
	|	TT_PreparedData.Currency,
	|	TT_PreparedData.SumPlan,
	|	TT_PreparedData.Count";
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		ExpressionBasePrice = "TT_BalancesOfDatabaseByFIFORanges.BasePrice";
	Else
		ExpressionBasePrice = "TT_PreparedData.BasePrice";
	EndIf;
	SubqueryTextLeftParts = StrReplace(SubqueryTextLeftParts, "&ExpressionBasePrice", ExpressionBasePrice);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		SubqueryTextLeftParts,
		"TT_PreparedData",
		"TT_BalancesOfDatabaseByFIFORanges");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		SubqueryTextLeftParts,
		"TT_PreparedData",
		"TT_BalancesOfDatabaseByFIFORanges");
	
	SubqueryTexts_.Add(SubqueryTextLeftParts);
	
	TextOfSubqueryRightParts =
	"SELECT
	|	TT_PreparedData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_PreparedData.GoodsIndicator AS GoodsIndicator,
	|	TT_PreparedData.Period AS Period,
	|	TT_PreparedData.CalculationPeriod AS CalculationPeriod,
	|	TT_CorrectionOfBaseErrorByFIFORanges.RangeNumber AS RangeNumber,
	|	TT_CorrectionOfBaseErrorByFIFORanges.RangeFrom AS RangeFrom,
	|	TT_CorrectionOfBaseErrorByFIFORanges.RangeBy AS RangeBy,
	|	TT_CorrectionOfBaseErrorByFIFORanges.BonusPercent AS BonusPercent,
	|	&ExpressionBasePrice AS BasePrice,
	|	TT_CorrectionOfBaseErrorByFIFORanges.RangeWidth AS RangeWidth,
	|	TT_PreparedData.DocumentRecorder AS DocumentRecorder,
	|	TT_PreparedData.LineNumber AS LineNumber,
	|	TT_PreparedData.Priority AS Priority,
	|	TT_CorrectionOfBaseErrorByFIFORanges.RoundingPriority AS RoundingPriority,
	|	TT_PreparedData.Organization AS Organization,
	|	&MemberFields,
	|	TT_PreparedData.Contract AS Contract,
	|	TT_PreparedData.Terms AS Terms,
	|	TT_PreparedData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_PreparedData.Products AS Products,
	|	TT_PreparedData.UnitOfMeasure AS UnitOfMeasure,
	|	TT_PreparedData.Characteristic AS Characteristic,
	|	TT_PreparedData.PropertyValue AS PropertyValue,
	|	TT_PreparedData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_PreparedData.PartyCountDetails AS PartyCountDetails,
	|	TT_PreparedData.AccrualFrequency AS AccrualFrequency,
	|	TT_PreparedData.ConditionFrequency AS ConditionFrequency,
	|	TT_PreparedData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_PreparedData.Currency AS Currency,
	|	CASE
	|		WHEN TT_CorrectionOfBaseErrorByFIFORanges.FirstRangeOfDocument
	|			THEN TT_PreparedData.Count
	|		ELSE 0
	|	END AS Count,
	|	CASE
	|		WHEN TT_CorrectionOfBaseErrorByFIFORanges.FirstRangeOfDocument
	|			THEN TT_PreparedData.SalesAmount
	|		ELSE 0
	|	END AS SalesAmount,
	|	CASE
	|		WHEN TT_CorrectionOfBaseErrorByFIFORanges.FirstRangeOfDocument
	|			THEN TT_PreparedData.AmountOfTurnoverWithVAT
	|		ELSE 0
	|	END AS AmountOfTurnoverWithVAT,
	|	CASE
	|		WHEN TT_CorrectionOfBaseErrorByFIFORanges.FirstRangeOfDocument
	|			THEN TT_PreparedData.AmountOfTurnoverExcludingVAT
	|		ELSE 0
	|	END AS AmountOfTurnoverExcludingVAT,
	|	TT_PreparedData.SumPlan AS SumPlan,
	|	TRUE AS PlanIsFulfilled,
	|	0 AS CountPlan,
	|	TT_CorrectionOfBaseErrorByFIFORanges.AmountToCalculateBonus AS AmountToCalculateBonus,
	|	0 AS NumberOfPackages_,
	|	TT_CorrectionOfBaseErrorByFIFORanges.CalculationBase AS CalculationBase,
	|	TT_CorrectionOfBaseErrorByFIFORanges.AmountBonus AS AmountBonus
	|FROM
	|	TT_CorrectionOfBaseErrorByFIFORanges AS TT_CorrectionOfBaseErrorByFIFORanges
	|		INNER JOIN TT_PreparedData AS TT_PreparedData
	|		ON TT_CorrectionOfBaseErrorByFIFORanges.DocumentRecorder = TT_PreparedData.DocumentRecorder
	|			AND TT_CorrectionOfBaseErrorByFIFORanges.Priority = TT_PreparedData.Priority
	|			AND &ConnectionFieldsByGoods
	|WHERE
	|	TT_CorrectionOfBaseErrorByFIFORanges.Allocated = TRUE";
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		ExpressionBasePrice = "TT_CorrectionOfBaseErrorByFIFORanges.BasePrice";
	Else
		ExpressionBasePrice = "TT_PreparedData.BasePrice";
	EndIf;
	TextOfSubqueryRightParts = StrReplace(TextOfSubqueryRightParts, "&ExpressionBasePrice", ExpressionBasePrice);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfSubqueryRightParts,
		"TT_PreparedData",
		"TT_CorrectionOfBaseErrorByFIFORanges");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		TextOfSubqueryRightParts,
		"TT_PreparedData",
		"TT_CorrectionOfBaseErrorByFIFORanges");
	
	SubqueryTexts_.Add(TextOfSubqueryRightParts);
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextBonusTotalsByRangeWidth(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	SourceTable1.Currency AS Currency,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	SourceTable1.RangeNumber AS RangeNumber,
	|	SourceTable1.RangeWidth AS RangeWidth,
	|	&ExpressionAmountIsBonusForWidthOfRange AS AmountOfBonusByWidthOfRange,
	|	MAX(
	|		CASE
	|			WHEN SourceTable1.CalculationBase > 0
	|				THEN SourceTable1.Priority
	|			ELSE -1
	|		END) AS RoundingPriority,
	|	SUM(SourceTable1.AmountBonus) AS AmountBonusTotal
	|INTO VT_BonusTotalsByRangeWidth
	|FROM
	|	&SourceTable1 AS SourceTable1
	|
	|GROUP BY
	|	SourceTable1.Currency,
	|	SourceTable1.CalculationPeriod,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	SourceTable1.RangeNumber,
	|	SourceTable1.RangeWidth,
	|	&ExpressionOfGroupingByBasePrice,
	|	SourceTable1.BonusPercent";
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		If RebateConditionsParameters.CalculationInBasePrices Then
			
			ExpressionAmountIsBonusForWidthOfRange = "CAST(SourceTable1.RangeWidth * SourceTable1.BasePrice * SourceTable1.BonusPercent / 100 AS NUMBER(31, 2))";
			ExpressionOfGroupingByBasePrice = "SourceTable1.BasePrice";
			
		Else
			
			ExpressionAmountIsBonusForWidthOfRange = "CAST(SUM(SourceTable1.CalculationBase) * SourceTable1.BonusPercent / 100 AS NUMBER(31, 2))";
			ExpressionOfGroupingByBasePrice = "NULL";
			
		EndIf;
		
		SourceTable1 = "TT_DataForDistributionOfBonusByFIFORanges";
		
	Else
		
		ExpressionAmountIsBonusForWidthOfRange = "CAST(SourceTable1.RangeWidth * SourceTable1.BonusPercent / 100 AS NUMBER(31, 2))";
		ExpressionOfGroupingByBasePrice = "NULL";
		SourceTable1 = "TT_DistributionOfRowsByRanges";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ExpressionAmountIsBonusForWidthOfRange", ExpressionAmountIsBonusForWidthOfRange);
	QueryText = StrReplace(QueryText, "&ExpressionOfGroupingByBasePrice", ExpressionOfGroupingByBasePrice);
	QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "SourceTable1");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "SourceTable1");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextFinalFIFODistributionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	SubqueryTexts_ = New Array; // Array of String
	
	TextOfSubqueryPositiveTurnover =
	"SELECT
	|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SourceTable1.GoodsIndicator AS GoodsIndicator,
	|	SourceTable1.Period AS Period,
	|	SourceTable1.CalculationPeriod AS CalculationPeriod,
	|	SourceTable1.RangeNumber AS RangeNumber,
	|	SourceTable1.RangeFrom AS RangeFrom,
	|	SourceTable1.RangeBy AS RangeBy,
	|	SourceTable1.BonusPercent AS BonusPercent,
	|	SourceTable1.DocumentRecorder AS DocumentRecorder,
	|	SourceTable1.LineNumber AS LineNumber,
	|	SourceTable1.Priority AS Priority,
	|	SourceTable1.Organization AS Organization,
	|	&MemberFields,
	|	SourceTable1.Contract AS Contract,
	|	SourceTable1.Terms AS Terms,
	|	SourceTable1.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	SourceTable1.Products AS Products,
	|	SourceTable1.UnitOfMeasure AS UnitOfMeasure,
	|	SourceTable1.Characteristic AS Characteristic,
	|	SourceTable1.PropertyValue AS PropertyValue,
	|	SourceTable1.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	SourceTable1.PartyCountDetails AS PartyCountDetails,
	|	SourceTable1.AccrualFrequency AS AccrualFrequency,
	|	SourceTable1.ConditionFrequency AS ConditionFrequency,
	|	SourceTable1.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	SourceTable1.Currency AS Currency,
	|	SourceTable1.Count AS Count,
	|	SourceTable1.SalesAmount AS SalesAmount,
	|	SourceTable1.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	SourceTable1.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	SourceTable1.BasePrice AS BasePrice,
	|	SourceTable1.SumPlan AS SumPlan,
	|	TRUE AS PlanIsFulfilled,
	|	0 AS CountPlan,
	|	SourceTable1.Count AS AmountToCalculateBonus,
	|	0 AS NumberOfPackages_,
	|	SourceTable1.CalculationBase AS CalculationBase,
	|	CASE
	|		WHEN SourceTable1.Priority = ISNULL(VT_BonusTotalsByRangeWidth.RoundingPriority, -1)
	|			THEN (SourceTable1.AmountBonus + ISNULL(VT_BonusTotalsByRangeWidth.AmountOfBonusByWidthOfRange, 0)
	|				- ISNULL(VT_BonusTotalsByRangeWidth.AmountBonusTotal, 0)
	|			)
	|		ELSE SourceTable1.AmountBonus
	|	END AS AmountBonus
	|INTO VT_FinalDistributionByFIFO
	|FROM
	|	&SourceTable1 AS SourceTable1
	|		LEFT JOIN VT_BonusTotalsByRangeWidth AS VT_BonusTotalsByRangeWidth
	|		ON SourceTable1.Currency = VT_BonusTotalsByRangeWidth.Currency
	|			AND SourceTable1.CalculationPeriod = VT_BonusTotalsByRangeWidth.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|			AND SourceTable1.RangeNumber = VT_BonusTotalsByRangeWidth.RangeNumber";
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		SourceTable1 = "TT_DataForDistributionOfBonusByFIFORanges";
		
	Else
		
		SourceTable1 = "TT_DistributionOfRowsByRanges";
		
	EndIf;
	TextOfSubqueryPositiveTurnover = StrReplace(TextOfSubqueryPositiveTurnover, "&SourceTable1", SourceTable1);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters,
		TextOfSubqueryPositiveTurnover,
		"SourceTable1",
		"VT_BonusTotalsByRangeWidth");
	SubstituteFieldsForGoods(
		RebateConditionsParameters,
		TextOfSubqueryPositiveTurnover,
		"SourceTable1",
		"VT_BonusTotalsByRangeWidth");
	
	SubqueryTexts_.Add(TextOfSubqueryPositiveTurnover);
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		SubqueryTextNegativeTurns =
		"SELECT
		|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
		|	SourceTable1.GoodsIndicator AS GoodsIndicator,
		|	SourceTable1.Period AS Period,
		|	SourceTable1.CalculationPeriod AS CalculationPeriod,
		|	ISNULL(TT_CalculationScale.RangeNumber, 0) AS RangeNumber,
		|	ISNULL(TT_CalculationScale.RangeFrom, 0) AS RangeFrom,
		|	ISNULL(TT_CalculationScale.RangeBy, 0) AS RangeBy,
		|	ISNULL(TT_CalculationScale.BonusPercent, 0) AS BonusPercent,
		|	SourceTable1.DocumentRecorder AS DocumentRecorder,
		|	SourceTable1.LineNumber AS LineNumber,
		|	SourceTable1.Priority AS Priority,
		|	SourceTable1.Organization AS Organization,
		|	&MemberFields,
		|	SourceTable1.Contract AS Contract,
		|	SourceTable1.Terms AS Terms,
		|	SourceTable1.ItemVariantsAreUsed AS ItemVariantsAreUsed,
		|	SourceTable1.Products AS Products,
		|	SourceTable1.UnitOfMeasure AS UnitOfMeasure,
		|	SourceTable1.Characteristic AS Characteristic,
		|	SourceTable1.PropertyValue AS PropertyValue,
		|	SourceTable1.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
		|	SourceTable1.PartyCountDetails AS PartyCountDetails,
		|	SourceTable1.AccrualFrequency AS AccrualFrequency,
		|	SourceTable1.ConditionFrequency AS ConditionFrequency,
		|	SourceTable1.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
		|	SourceTable1.Currency AS Currency,
		|	SourceTable1.Count AS Count,
		|	SourceTable1.SalesAmount AS SalesAmount,
		|	SourceTable1.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
		|	SourceTable1.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
		|	SourceTable1.BasePrice AS BasePrice,
		|	SourceTable1.SumPlan AS SumPlan,
		|	FALSE AS PlanIsFulfilled,
		|	0 AS CountPlan,
		|	SourceTable1.Count AS AmountToCalculateBonus,
		|	0 AS NumberOfPackages_,
		|	0 AS CalculationBase,
		|	0 AS AmountBonus
		|FROM
		|	TT_PreparedData AS SourceTable1
		|		INNER JOIN TT_CalculationScale AS TT_CalculationScale
		|		ON TT_CalculationScale.RangeFrom = 0
		|WHERE
		|	SourceTable1.VerificationAmount <= 0";
		
	Else
		
		SubqueryTextNegativeTurns =
		"SELECT
		|	SourceTable1.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
		|	SourceTable1.GoodsIndicator AS GoodsIndicator,
		|	SourceTable1.Period AS Period,
		|	SourceTable1.CalculationPeriod AS CalculationPeriod,
		|	ISNULL(TT_GoodsRanges.RangeNumber, 0) AS RangeNumber,
		|	ISNULL(TT_GoodsRanges.RangeFrom, 0) AS RangeFrom,
		|	ISNULL(TT_GoodsRanges.RangeBy, 0) AS RangeBy,
		|	ISNULL(TT_GoodsRanges.BonusPercent, 0) AS BonusPercent,
		|	SourceTable1.DocumentRecorder AS DocumentRecorder,
		|	SourceTable1.LineNumber AS LineNumber,
		|	SourceTable1.Priority AS Priority,
		|	SourceTable1.Organization AS Organization,
		|	&MemberFields,
		|	SourceTable1.Contract AS Contract,
		|	SourceTable1.Terms AS Terms,
		|	SourceTable1.ItemVariantsAreUsed AS ItemVariantsAreUsed,
		|	SourceTable1.Products AS Products,
		|	SourceTable1.UnitOfMeasure AS UnitOfMeasure,
		|	SourceTable1.Characteristic AS Characteristic,
		|	SourceTable1.PropertyValue AS PropertyValue,
		|	SourceTable1.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
		|	SourceTable1.PartyCountDetails AS PartyCountDetails,
		|	SourceTable1.AccrualFrequency AS AccrualFrequency,
		|	SourceTable1.ConditionFrequency AS ConditionFrequency,
		|	SourceTable1.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
		|	SourceTable1.Currency AS Currency,
		|	SourceTable1.Count AS Count,
		|	SourceTable1.SalesAmount AS SalesAmount,
		|	SourceTable1.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
		|	SourceTable1.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
		|	ISNULL(TT_GoodsRanges.BasePrice, 0) AS BasePrice,
		|	SourceTable1.SumPlan AS SumPlan,
		|	FALSE AS PlanIsFulfilled,
		|	0 AS CountPlan,
		|	SourceTable1.Count AS AmountToCalculateBonus,
		|	0 AS NumberOfPackages_,
		|	0 AS CalculationBase,
		|	0 AS AmountBonus
		|FROM
		|	TT_PreparedData AS SourceTable1
		|		LEFT JOIN TT_GoodsRanges AS TT_GoodsRanges
		|		ON TT_GoodsRanges.RangeFrom = 0
		|			AND &ConnectionFieldsByGoods
		|WHERE
		|	SourceTable1.CountOfChecks <= 0";
		
		SubstituteFieldsForGoods(
			RebateConditionsParameters,
			SubqueryTextNegativeTurns,
			"SourceTable1",
			"TT_GoodsRanges");
		
	EndIf;
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, SubqueryTextNegativeTurns, "SourceTable1");
	
	SubqueryTexts_.Add(SubqueryTextNegativeTurns);
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPrioritiesOnRangeBoundaries(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	QueryText =
	"SELECT
	|	TT_LinesOnBoundariesOfRanges.Currency AS Currency,
	|	TT_LinesOnBoundariesOfRanges.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	TT_LinesOnBoundariesOfRanges.RangeNumber AS RangeNumber,
	|	TT_LinesOnBoundariesOfRanges.RangeFrom AS RangeFrom,
	|	TT_LinesOnBoundariesOfRanges.RangeBy AS RangeBy,
	|	TT_LinesOnBoundariesOfRanges.BonusPercent AS BonusPercent,
	|	TT_LinesOnBoundariesOfRanges.BasePrice AS BasePrice,
	|	ISNULL(MIN(
	|		CASE
	|			WHEN TT_LinesOnBoundariesOfRanges.RangeFrom = 0
	|				THEN -1
	|			WHEN &ExpressionSummaryBeforeDocument < TT_LinesOnBoundariesOfRanges.RangeFrom
	|				THEN TT_LinesOnBoundariesOfRanges.Priority
	|			ELSE NULL
	|		END), -1) AS PriorityFrom,
	|	ISNULL(MAX(
	|		CASE
	|			WHEN TT_LinesOnBoundariesOfRanges.RangeBy = 0
	|				THEN -1
	|			WHEN &ExpressionTurnoverForPeriod <= TT_LinesOnBoundariesOfRanges.RangeBy
	|				THEN -1
	|			WHEN &ExpressionSummaryAfterDocument >= TT_LinesOnBoundariesOfRanges.RangeBy
	|				THEN TT_LinesOnBoundariesOfRanges.Priority
	|			ELSE NULL
	|		END), -1) AS SoftwarePriority
	|INTO TT_PrioritiesAtRangeBoundaries
	|FROM
	|	TT_LinesOnBoundariesOfRanges AS TT_LinesOnBoundariesOfRanges
	|		INNER JOIN TT_TurnoverByPeriod AS TurnoverByPeriod
	|		ON TT_LinesOnBoundariesOfRanges.Currency = TurnoverByPeriod.Currency
	|			AND TT_LinesOnBoundariesOfRanges.CalculationPeriod = TurnoverByPeriod.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|
	|GROUP BY
	|	TT_LinesOnBoundariesOfRanges.Currency,
	|	TT_LinesOnBoundariesOfRanges.CalculationPeriod,
	|	&GroupingFieldsByParticipants,
	|	&GroupingFieldsByGoodsFields,
	|	TT_LinesOnBoundariesOfRanges.RangeNumber,
	|	TT_LinesOnBoundariesOfRanges.RangeFrom,
	|	TT_LinesOnBoundariesOfRanges.RangeBy,
	|	TT_LinesOnBoundariesOfRanges.BonusPercent,
	|	TT_LinesOnBoundariesOfRanges.BasePrice";
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		ExpressionSummaryBeforeDocument = "TT_LinesOnBoundariesOfRanges.CumulativeAmount - TT_LinesOnBoundariesOfRanges.LineAmount";
		ExpressionSummaryAfterDocument = "TT_LinesOnBoundariesOfRanges.CumulativeAmount";
		ExpressionTurnoverForPeriod = "TurnoverByPeriod.Sum";
		
	Else
		
		ExpressionSummaryBeforeDocument = "TT_LinesOnBoundariesOfRanges.AmountIsCumulative - TT_LinesOnBoundariesOfRanges.NumberOfLines";
		ExpressionSummaryAfterDocument = "TT_LinesOnBoundariesOfRanges.AmountIsCumulative";
		ExpressionTurnoverForPeriod = "TurnoverByPeriod.Count";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ExpressionSummaryBeforeDocument", ExpressionSummaryBeforeDocument);
	QueryText = StrReplace(QueryText, "&ExpressionSummaryAfterDocument", ExpressionSummaryAfterDocument);
	QueryText = StrReplace(QueryText, "&ExpressionTurnoverForPeriod", ExpressionTurnoverForPeriod);
	
	SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, "TT_LinesOnBoundariesOfRanges", "TurnoverByPeriod");
	SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, "TT_LinesOnBoundariesOfRanges", "TurnoverByPeriod");
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  RebateConditionsParameters - See NewParametersOfConditionsForRebates
//  OptionParameters - See NewOptionParameters
//  QueriesTexts - Array of String
//
Procedure AddQueryTextPrioritiesBalancesOnRangeBoundaries(RebateConditionsParameters, OptionParameters, QueriesTexts) Export
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		TableCalculationScale = "TT_CalculationScale";
		ExpressionBasePrice = "0";
		
	Else
		
		TableCalculationScale = "TT_GoodsRanges";
		ExpressionBasePrice = "TableCalculationScale.BasePrice";
		
	EndIf;
	
	SubqueryTexts_ = New Array; // Array of String
	
	//@skip-check bsl-ql-hub - The Query Text consists of several parts
	SubqueryText =
	"SELECT DISTINCT
	|	TT_PrioritiesAtRangeBoundaries.Currency AS Currency,
	|	TT_PrioritiesAtRangeBoundaries.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	TT_PrioritiesAtRangeBoundaries.RangeNumber AS RangeNumber,
	|	TT_PrioritiesAtRangeBoundaries.RangeFrom AS RangeFrom,
	|	TT_PrioritiesAtRangeBoundaries.RangeBy AS RangeBy,
	|	TT_PrioritiesAtRangeBoundaries.BonusPercent AS BonusPercent,
	|	TT_PrioritiesAtRangeBoundaries.BasePrice AS BasePrice,
	|	TT_PrioritiesAtRangeBoundaries.PriorityFrom AS PriorityFrom,
	|	TT_PrioritiesAtRangeBoundaries.SoftwarePriority AS SoftwarePriority,
	|	ISNULL(TT_LinesOnBordersOfRangesFrom.LineAmount, 0) AS SumOfLineFrom,
	|	ISNULL(TT_LinesOnBordersOfRangesFrom.NumberOfLines, 0) AS NumberOfLinesFrom,
	|	CASE
	|		WHEN ISNULL(TT_LinesOnBordersOfRangesFrom.Priority, -1) <> ISNULL(TT_LinesOnBordersOfRangesBy.Priority, -1)
	|			THEN ISNULL(TT_LinesOnBordersOfRangesFrom.SpanBalance, 0)
	|		ELSE 0
	|	END AS RangeOfBalanceFrom,
	|	ISNULL(TT_LinesOnBordersOfRangesBy.LineAmount, 0) AS SumOfLineBy,
	|	ISNULL(TT_LinesOnBordersOfRangesBy.NumberOfLines, 0) AS NumberOfLinesBy,
	|	ISNULL(TT_LinesOnBordersOfRangesBy.SpanBalance, 0) AS RangeOfBalanceBy
	|INTO TT_PrioritiesBalancesAtBoundariesOfRanges
	|FROM
	|	TT_PrioritiesAtRangeBoundaries AS TT_PrioritiesAtRangeBoundaries
	|		LEFT JOIN TT_LinesOnBoundariesOfRanges AS TT_LinesOnBordersOfRangesFrom
	|		ON TT_PrioritiesAtRangeBoundaries.PriorityFrom = TT_LinesOnBordersOfRangesFrom.Priority
	|			AND TT_PrioritiesAtRangeBoundaries.RangeNumber = TT_LinesOnBordersOfRangesFrom.RangeNumber
	|			AND TT_PrioritiesAtRangeBoundaries.Currency = TT_LinesOnBordersOfRangesFrom.Currency
	|			AND TT_PrioritiesAtRangeBoundaries.CalculationPeriod = TT_LinesOnBordersOfRangesFrom.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods";
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, SubqueryText, "TT_PrioritiesAtRangeBoundaries", "TT_LinesOnBordersOfRangesFrom");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, SubqueryText, "TT_PrioritiesAtRangeBoundaries", "TT_LinesOnBordersOfRangesFrom");
	
	ConnectionTextBorderBy = "
	|		LEFT JOIN TT_LinesOnBoundariesOfRanges AS TT_LinesOnBordersOfRangesBy
	|		ON TT_PrioritiesAtRangeBoundaries.SoftwarePriority = TT_LinesOnBordersOfRangesBy.Priority
	|			AND TT_PrioritiesAtRangeBoundaries.RangeNumber = TT_LinesOnBordersOfRangesBy.RangeNumber
	|			AND TT_PrioritiesAtRangeBoundaries.Currency = TT_LinesOnBordersOfRangesBy.Currency
	|			AND TT_PrioritiesAtRangeBoundaries.CalculationPeriod = TT_LinesOnBordersOfRangesBy.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods";
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, ConnectionTextBorderBy, "TT_PrioritiesAtRangeBoundaries", "TT_LinesOnBordersOfRangesBy");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, ConnectionTextBorderBy, "TT_PrioritiesAtRangeBoundaries", "TT_LinesOnBordersOfRangesBy");
	
	SubqueryText = SubqueryText + ConnectionTextBorderBy;
	SubqueryTexts_.Add(SubqueryText);
	
	SubqueryText =
	"SELECT
	|	TT_TurnoverByPeriod.Currency AS Currency,
	|	TT_TurnoverByPeriod.CalculationPeriod AS CalculationPeriod,
	|	&MemberFields,
	|	&ProductFields,
	|	TableCalculationScale.RangeNumber AS RangeNumber,
	|	TableCalculationScale.RangeFrom AS RangeFrom,
	|	TableCalculationScale.RangeBy AS RangeBy,
	|	TableCalculationScale.BonusPercent AS BonusPercent,
	|	&ExpressionBasePrice AS BasePrice,
	|	-1 AS PriorityFrom,
	|	-1 AS SoftwarePriority,
	|	0 AS AmountOfDocumentFrom,
	|	0 AS NumberOfDocumentsFrom,
	|	0 AS RangeOfBalanceFrom,
	|	0 AS AmountOfDocumentBy,
	|	0 AS NumberOfDocumentsBy,
	|	0 AS RangeOfBalanceBy
	|FROM
	|	TT_TurnoverByPeriod AS TT_TurnoverByPeriod
	|		INNER JOIN &TableCalculationScale AS TableCalculationScale
	|		ON TableCalculationScale.RangeFrom = 0
	|			AND &ConnectionFieldsByGoods";
	
	SubqueryText = StrReplace(SubqueryText, "&TableCalculationScale", TableCalculationScale);
	SubqueryText = StrReplace(SubqueryText, "&ExpressionBasePrice", ExpressionBasePrice);
	
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, SubqueryText, "TT_TurnoverByPeriod", "TT_PrioritiesAtRangeBoundaries");
	SubstituteFieldsForGoods(RebateConditionsParameters, SubqueryText, "TT_TurnoverByPeriod", "TableCalculationScale");
	
	ConnectionTextPriorities = "
	|			AND &TurnoverConditionByPeriod
	|		LEFT JOIN TT_PrioritiesAtRangeBoundaries AS TT_PrioritiesAtRangeBoundaries
	|		ON TableCalculationScale.RangeFrom = TT_PrioritiesAtRangeBoundaries.RangeFrom
	|			AND TT_TurnoverByPeriod.Currency = TT_PrioritiesAtRangeBoundaries.Currency
	|			AND TT_TurnoverByPeriod.CalculationPeriod = TT_PrioritiesAtRangeBoundaries.CalculationPeriod
	|			AND &ConnectionFieldsByParticipants
	|			AND &ConnectionFieldsByGoods
	|WHERE
	|	TT_PrioritiesAtRangeBoundaries.PriorityFrom IS NULL";
	SubstituteFieldsByParticipants(
		RebateConditionsParameters, ConnectionTextPriorities, "TT_TurnoverByPeriod", "TT_PrioritiesAtRangeBoundaries");
	SubstituteFieldsForGoods(
		RebateConditionsParameters, ConnectionTextPriorities, "TT_TurnoverByPeriod", "TT_PrioritiesAtRangeBoundaries");
	SubqueryText = SubqueryText + ConnectionTextPriorities;
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		TurnoverConditionByPeriod = "TT_TurnoverByPeriod.Sum >= 0";
		
	Else
		
		TurnoverConditionByPeriod = "TT_TurnoverByPeriod.Count >= 0";
		
	EndIf;
	
	SubqueryText = StrReplace(SubqueryText, "&TurnoverConditionByPeriod", TurnoverConditionByPeriod);
	
	SubqueryTexts_.Add(SubqueryText);
	
	SubquerySeparator_ = SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure SubstituteFieldsByParticipants(RebateConditionsParameters, QueryText, TableName, NameOfLinkTable = "", BlankValues = False)
	
	PartyCountDetails = RebateConditionsParameters.PartyCountDetails;
	DetailsOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If PartyCountDetails = DetailsOfParticipants.ByCustomer Then
		
		MemberFields = TableName + ".Partner AS Partner";
		If BlankValues Then
			
			MemberFields = MemberFields + ",
			|VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty";
			
		EndIf;
		
		ConnectionFieldsByParticipants = StrTemplate("%1.Partner = %2.Partner", TableName, NameOfLinkTable);
		GroupingFieldsByParticipants = TableName + ".Partner";
		IndexingFieldsByParticipants = "Partner";
		
	ElsIf PartyCountDetails = DetailsOfParticipants.ByCounterparty Then
		
		MemberFields = TableName + ".Counterparty AS Counterparty";
		If BlankValues Then
			
			MemberFields = MemberFields + ",
			|VALUE(Catalog.Partners.EmptyRef) AS Partner";
			
		EndIf;
		
		ConnectionFieldsByParticipants = StrTemplate("%1.Counterparty = %2.Counterparty", TableName, NameOfLinkTable);
		GroupingFieldsByParticipants = TableName + ".Counterparty";
		IndexingFieldsByParticipants = "Counterparty";
		
	ElsIf PartyCountDetails = DetailsOfParticipants.ByCounterpartyAndCustomer Then
		
		MemberFields = StrTemplate(
			"%1.Counterparty AS Counterparty,
			|%1.Partner AS Partner",
			TableName);
			
		ConnectionFieldsByParticipants = StrTemplate(
			"%1.Counterparty = %2.Counterparty
			|AND %1.Partner = %2.Partner",
			TableName,
			NameOfLinkTable);
		
		GroupingFieldsByParticipants = StrTemplate(
			"%1.Counterparty,
			|%1.Partner",
			TableName);
		
		IndexingFieldsByParticipants =
		"Counterparty,
		|Partner";
		
	ElsIf PartyCountDetails = DetailsOfParticipants.EmptyRef() Then
		
		MemberFields = "NULL AS Counterparty";
		ConnectionFieldsByParticipants = "TRUE";
		GroupingFieldsByParticipants = "NULL";
		IndexingFieldsByParticipants = "1";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Không thể xác định chi tiết người tham gia (""%1"") đối với chứng từ ""%2""';
							|ru = 'Не удалось определить детализацию участников (""%1"") для документа ""%2""';
							|en = 'Cannot determine the participant details (""%1"") for the ""%2"" document'; fa = 'Cannot determine the participant details (""%1"") for the ""%2"" document';
							|it = 'Не удалось определить детализацию участников (""%1"") для документа ""%2""';
							|pl = 'Cannot determine the participant details (""%1"") for the ""%2"" document';
							|tr = '“%2“ belgesi için katılımcı detayı (”%1"") tanımlanamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.PartyCountDetailsPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&MemberFields", MemberFields);
	QueryText = StrReplace(QueryText, "&ConnectionFieldsByParticipants", ConnectionFieldsByParticipants);
	QueryText = StrReplace(QueryText, "&GroupingFieldsByParticipants", GroupingFieldsByParticipants);
	QueryText = StrReplace(QueryText, "&IndexingFieldsByParticipants", IndexingFieldsByParticipants);
	
EndProcedure

Procedure SubstituteFieldsForGoods(RebateConditionsParameters, QueryText, TableName, NameOfLinkTable = "", ConnectionByPropertyAndItem = False)
	
	If RebateConditionsParameters.IndicatorOfItemsIsQuantitative
	   And Not RebateConditionsParameters.CalculationByProperties Then
		
		ProductFields = StrTemplate(
			"%1.Products AS Products,
			|%1.Characteristic AS Characteristic",
			TableName);
		
		ConnectionFieldsByGoods = StrTemplate(
			"%1.Products = %2.Products
			|AND %1.Characteristic = %2.Characteristic",
			TableName,
			NameOfLinkTable);
		
		GroupingFieldsByGoods = StrTemplate(
			"%1.Products,
			|%1.Characteristic",
			TableName);
		
		IndexingFieldsByGoods =
		"Products,
		|Characteristic";
		
	ElsIf RebateConditionsParameters.IndicatorOfItemsIsQuantitative
	        And RebateConditionsParameters.CalculationByProperties Then
		
		ProductFields = StrTemplate("%1.PropertyValue AS PropertyValue", TableName);
		
		If ConnectionByPropertyAndItem Then
			
			ConnectionFieldsByGoods = StrTemplate(
				"%1.PropertyValue = %2.PropertyValue
				|AND %1.Products = %2.Products",
				TableName,
				NameOfLinkTable);
			
		Else
			
			ConnectionFieldsByGoods = StrTemplate("%1.PropertyValue = %2.PropertyValue",  TableName, NameOfLinkTable);
			
		EndIf;
		
		GroupingFieldsByGoods = StrTemplate("%1.PropertyValue",  TableName);
		IndexingFieldsByGoods = "1";
		
	Else
		
		ProductFields = "NULL AS Products";
		ConnectionFieldsByGoods = "TRUE";
		GroupingFieldsByGoods = "NULL";
		IndexingFieldsByGoods = "1";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ProductFields", ProductFields);
	QueryText = StrReplace(QueryText, "&ConnectionFieldsByGoods", ConnectionFieldsByGoods);
	QueryText = StrReplace(QueryText, "&GroupingFieldsByGoodsFields", GroupingFieldsByGoods);
	QueryText = StrReplace(QueryText, "&IndexingFieldsByGoods", IndexingFieldsByGoods);
	
EndProcedure

Procedure SubstituteRangeNumberField(RebateConditionsParameters, QueryText, TableName, NameOfLinkTable = "")
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RangeNumberField = StrTemplate(
			"%1.RangeNumber AS RangeNumber",
			TableName);
		
		ConnectionFieldRangeNumber = StrTemplate(
			"%1.RangeNumber = %2.RangeNumber",
			TableName,
			NameOfLinkTable);
		
		GroupingFieldRangeNumber = StrTemplate(
			"%1.RangeNumber",
			TableName);
			
		IndexingFieldRangeNumber =
		"RangeNumber";
		
	Else
		
		RangeNumberField = "0 AS RangeNumber";
		ConnectionFieldRangeNumber = "TRUE";
		GroupingFieldRangeNumber = "NULL";
		IndexingFieldRangeNumber = "1";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&RangeNumberField", RangeNumberField);
	QueryText = StrReplace(QueryText, "&ConnectionFieldRangeNumber", ConnectionFieldRangeNumber);
	QueryText = StrReplace(QueryText, "&GroupingFieldRangeNumber", GroupingFieldRangeNumber);
	QueryText = StrReplace(QueryText, "&IndexingFieldRangeNumber", IndexingFieldRangeNumber);
	
EndProcedure

Procedure SubstitutePresentationOfRangeUnitField(RebateConditionsParameters, QueryText, TableName)
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
		
		If RebateConditionsParameters.GoodsIndicator = IndicatorsKinds.Sum Then
			
			FieldPresentationOfRangeUnit = StrTemplate(
				"PRESENTATION(%1.Currency) AS PresentationOfRangeUnit", TableName);
			
		Else
			
			FieldPresentationOfRangeUnit = """"" AS PresentationOfRangeUnit";
			
		EndIf;
		
	Else
		
		FieldPresentationOfRangeUnit = """"" AS PresentationOfRangeUnit";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FieldPresentationOfRangeUnit", FieldPresentationOfRangeUnit);
	
EndProcedure

Procedure SubstituteAmountSelectionFieldWithoutSpecifying(RebateConditionsParameters, QueryText, TableName, TableNameBasePrice = "")
	
	If RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueManagementAccounting Then
		
		FieldText = "&TableName.Sum";
		
	ElsIf RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueLocalAccounting
	      Or RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountLocalAccounting Then
		
		FieldText = "&TableName.SumCompl";
		
	ElsIf RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueARAPAccounting
	      Or RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountARAPAccounting Then
		
		FieldText = "&TableName.AmountInARAPCurrency";
		
	ElsIf RebateConditionsParameters.CalculationInBasePrices Then
		
		FieldText = "CAST(ISNULL(&TableBasePrice.BasePrice, 0) * &TableName.Count AS NUMBER(31, 2))";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Cơ sở tính toán không xác định ""%1""';
							|ru = 'Неизвестная база расчета ""%1""';
							|en = '""%1"" unknown calculation base'; fa = '""%1"" unknown calculation base';
							|it = '""%1"" unknown calculation base';
							|pl = '""%1"" unknown calculation base';
							|tr = 'Bilinmeyen ""%1"" hesaplama tabanı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate, String(RebateConditionsParameters.BaseOfCalculation));
		Raise ErrorText;
		
	EndIf;
	
	If TableNameBasePrice = "" Then
		TableNameBasePrice = TableName;
	EndIf;
	
	FieldText = StrReplace(FieldText, "&TableName", TableName);
	FieldText = StrReplace(FieldText, "&TableBasePrice", TableNameBasePrice);
	QueryText = StrReplace(QueryText, "&ExpressionAmountWithoutSpecification", FieldText);
	
EndProcedure

Procedure SubstituteAmountSelectionFieldWithVAT(RebateConditionsParameters, QueryText, TableName, TableNameBasePrice = "")
	
	If RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueManagementAccounting Then
		
		FieldText = "&TableName.AmountOfTurnoverOfMansWithVAT";
		
	ElsIf RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueLocalAccounting
	      Or RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountLocalAccounting Then
		
		FieldText = "&TableName.AmountOfTurnoverOfLocalWithVAT";
		
	ElsIf RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueARAPAccounting
	      Or RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountARAPAccounting Then
		
		FieldText = "&TableName.AmountInARAPCurrency";
		
	ElsIf RebateConditionsParameters.CalculationInBasePrices Then
		
		FieldText = "CAST(ISNULL(&TableBasePrice.BasePrice, 0) * &TableName.Count AS NUMBER(31, 2))";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Cơ sở tính toán không xác định ""%1""';
							|ru = 'Неизвестная база расчета ""%1""';
							|en = '""%1"" unknown calculation base'; fa = '""%1"" unknown calculation base';
							|it = '""%1"" unknown calculation base';
							|pl = '""%1"" unknown calculation base';
							|tr = 'Bilinmeyen ""%1"" hesaplama tabanı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate, String(RebateConditionsParameters.BaseOfCalculation));
		Raise ErrorText;
		
	EndIf;
	
	If TableNameBasePrice = "" Then
		TableNameBasePrice = TableName;
	EndIf;
	
	FieldText = StrReplace(FieldText, "&TableName", TableName);
	FieldText = StrReplace(FieldText, "&TableBasePrice", TableNameBasePrice);
	QueryText = StrReplace(QueryText, "&ExpressionSumWithVAT", FieldText);
	
EndProcedure

Procedure SubstituteVATExclusiveAmountSelectionField(RebateConditionsParameters, QueryText, TableName, TableNameBasePrice = "")
	
	If RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueManagementAccounting Then
		
		FieldText = "&TableName.ManSTurnoverAmountExcludingVAT";
		
	ElsIf RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueLocalAccounting
	      Or RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountLocalAccounting Then
		
		FieldText = "&TableName.AmountOfTurnoverIsLocalWithoutVAT";
		
	ElsIf RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueARAPAccounting
	      Or RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountARAPAccounting Then
		
		FieldText = "&TableName.AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT";
		
	ElsIf RebateConditionsParameters.CalculationInBasePrices Then
		
		FieldText = "CAST(ISNULL(&TableBasePrice.BasePrice, 0) * &TableName.Count AS NUMBER(31, 2))";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Cơ sở tính toán không xác định ""%1""';
							|ru = 'Неизвестная база расчета ""%1""';
							|en = '""%1"" unknown calculation base'; fa = '""%1"" unknown calculation base';
							|it = '""%1"" unknown calculation base';
							|pl = '""%1"" unknown calculation base';
							|tr = 'Bilinmeyen ""%1"" hesaplama tabanı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate, String(RebateConditionsParameters.BaseOfCalculation));
		Raise ErrorText;
		
	EndIf;
	
	If TableNameBasePrice = "" Then
		TableNameBasePrice = TableName;
	EndIf;
	
	FieldText = StrReplace(FieldText, "&TableName", TableName);
	FieldText = StrReplace(FieldText, "&TableBasePrice", TableNameBasePrice);
	QueryText = StrReplace(QueryText, "&ExpressionVATExclusive", FieldText);
	
EndProcedure

Function ValueOfEmptyLoggerReference(RebateConditionsParameters)
	
	If RebateConditionsParameters.CalculationOfSupplierBonuses
	   And RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Purchases Then
		
		Result = "VALUE(Document.CustomerInvoice.EmptyRef)";
		
	Else
		
		Result = "VALUE(Document.VendorInvoice.EmptyRef)";
		
	EndIf;
	
	Return Result;
	
EndFunction

Function CalculationOnProgressiveScale(ConditionParameters_)
	
	If ConditionParameters_.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		Return (ConditionParameters_.CalculationScaleType = 1);
		
	ElsIf ConditionParameters_.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		Return (ConditionParameters_.CalculationScaleType = 0);
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

Function CalculationByRanges(ConditionParameters_)
	
	If ConditionParameters_.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		Return (ConditionParameters_.CalculationScaleType = 2);
		
	ElsIf ConditionParameters_.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		Return (ConditionParameters_.CalculationScaleType = 1);
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

Function OrderingFieldsByChronology(ConditionParameters_, SourceTable1)
	
	OrderFields = New Array(); // Array of String
	
	OrderFields.Add(SourceTable1 + ".Currency");
	
	DetailsOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If ConditionParameters_.PartyCountDetails = DetailsOfParticipants.ByCustomer
	 Or ConditionParameters_.PartyCountDetails = DetailsOfParticipants.ByCounterpartyAndCustomer Then
		OrderFields.Add(SourceTable1 + ".Partner");
	EndIf;
	If ConditionParameters_.PartyCountDetails = DetailsOfParticipants.ByCounterparty
	 Or ConditionParameters_.PartyCountDetails = DetailsOfParticipants.ByCounterpartyAndCustomer Then
		OrderFields.Add(SourceTable1 + ".Counterparty");
	EndIf;
	
	OrderFields.Add(SourceTable1 + ".CalculationPeriod");
	
	If ConditionParameters_.IndicatorOfItemsIsQuantitative
	   And ConditionParameters_.CalculationByProperties Then
		
		OrderFields.Add(SourceTable1 + ".PropertyValue");
		
	EndIf;
	
	If ConditionParameters_.IndicatorOfItemsIsQuantitative
	   And Not ConditionParameters_.CalculationByProperties Then
		
		OrderFields.Add(SourceTable1 + ".Products");
		OrderFields.Add(SourceTable1 + ".Characteristic");
		
	EndIf;
	
	OrderFields.Add(SourceTable1 + ".SignOfRevolutions");
	OrderFields.Add(SourceTable1 + ".Period");
	OrderFields.Add(SourceTable1 + ".DocumentRecorder");
	
	If ConditionParameters_.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	 Or (ConditionParameters_.IndicatorOfItemsIsQuantitative
	      And ConditionParameters_.CalculationByProperties) Then
		
		OrderFields.Add(SourceTable1 + ".Products");
		
	EndIf;
	
	OrderFields.Add(SourceTable1 + ".CharacteristicsOfSalesPurchases");
	
	Return OrderFields;
	
EndFunction

Function CalculationByProperties(ConditionParameters_)
	
	Return (ConditionParameters_.ContentOfGoods = Enums.RebatesItems.ProductItemProperty);
	
EndFunction

Function ItemAttributeParameters(ConditionParameters_)
	
	Result = New Structure;
	Result.Insert("AdditionalItemProperty", False);
	Result.Insert("ItemItemPropertyLink", ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef());
	Result.Insert("ItemPropertyValueType", New TypeDescription(Undefined));
	Result.Insert("ItemPropertyTitle", "");
	
	If Not ConditionParameters_.CalculationByProperties Then
		Return Result;
	EndIf;
	
	CheckResult = RebatesServer.ItemPropertyVerificationData(ConditionParameters_.ProductItemProperty);
	If Not CheckResult.AllowedToUse Then
		
		ErrorTemplate = NStr("vi = 'Không tìm thấy mục tin mặt hàng có ID ""%1"". Hãy kiểm tra tùy chỉnh dạng thưởng lũy kế';
							|ru = 'Не найден реквизит номенклатуры с идентификатором ""%1"". Проверьте настройки вида ретро-бонусов';
							|en = 'The item attribute with ID ""%1""  is not found. Please check the rebate kind settings'; fa = 'The item attribute with ID ""%1""  is not found. Please check the rebate kind settings';
							|it = 'The item attribute with ID ""%1""  is not found. Please check the rebate kind settings';
							|pl = 'The item attribute with ID ""%1""  is not found. Please check the rebate kind settings';
							|tr = '""%1"" tanımlayıcılı öğenin özniteliği bulunamadı. Retro bonusu türünün ayarlarını kontrol edin'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, ConditionParameters_.ProductItemProperty);
		Raise ErrorText;
		
	EndIf;
	
	Result.AdditionalItemProperty = ValueIsFilled(CheckResult.Property);
	Result.ItemItemPropertyLink = CheckResult.Property;
	Result.ItemPropertyValueType = CheckResult.ValueType;
	Result.ItemPropertyTitle = CheckResult.Title;
	
	Return Result;
	
EndFunction

Function IndicatorOfItemsIsQuantitative(GoodsIndicator)
	
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If GoodsIndicator = IndicatorsKinds.Count
	 Or GoodsIndicator = IndicatorsKinds.QuantityTotal
	 Or GoodsIndicator = IndicatorsKinds.BatchOffer Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

Procedure SubstituteExpressionCalculationCurrency(RebateConditionsParameters, QueryText, TableName)
	
	If RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.RevenueARAPAccounting
	 Or RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountARAPAccounting Then
	 
		ExpressionCalculationCurrency = "&TableName.ARAPCurrency";
		
	Else
		
		ExpressionCalculationCurrency = "&TableName.CurrencyOfConditions";
		
	EndIf;
	
	ExpressionCalculationCurrency = StrReplace(ExpressionCalculationCurrency, "&TableName", TableName);
	QueryText = StrReplace(QueryText, "&ExpressionCalculationCurrency", ExpressionCalculationCurrency);
	
EndProcedure

Function CompoundTypeFieldTypingExpression(DescriptionOfValueType_, FieldName)
	
	FieldTypeExpressions = New Array; // Array of String
	
	CompoundTypeExpressionTemplate = "WHEN %1 Ref %2
	|THEN %3";
	SimpleTypeExpressionTemplate = "CAST(%1 AS %2)";
	
	For Each FieldType In DescriptionOfValueType_.Types() Do
		
		TypeMetadata = Metadata.FindByType(FieldType);
		If TypeMetadata = Undefined Then
			Continue;
		EndIf;
		
		TypeOfFieldForRequest = TypeMetadata.FullName();
		SimpleTypeExpression = StrTemplate(SimpleTypeExpressionTemplate, FieldName, TypeOfFieldForRequest);
		
		CompoundTypeExpression = StrTemplate(CompoundTypeExpressionTemplate, FieldName, TypeOfFieldForRequest, SimpleTypeExpression);
		FieldTypeExpressions.Add(CompoundTypeExpression);
		
	EndDo;
	
	If DescriptionOfValueType_.ContainsType(Type("String")) Then
		
		SimpleTypeExpressionTemplate = "CAST(%1 AS STRING(%2))";
		StringLength = DescriptionOfValueType_.StringQualifiers.Length;
		SimpleTypeExpression = StrTemplate(SimpleTypeExpressionTemplate, FieldName, StringLength);
		
		CompoundTypeExpressionTemplate = "WHEN VALUETYPE(%1) = TYPE(STRING)
		|THEN %2";
		CompoundTypeExpression = StrTemplate(CompoundTypeExpressionTemplate, FieldName, SimpleTypeExpression);
		FieldTypeExpressions.Add(CompoundTypeExpression);
		
	EndIf;
	
	If DescriptionOfValueType_.ContainsType(Type("Number")) Then
		
		SimpleTypeExpressionTemplate = "CAST(%1 AS NUMBER(%2, %3))";
		Digits = DescriptionOfValueType_.NumberQualifiers.Digits;
		Accuracy = DescriptionOfValueType_.NumberQualifiers.FractionDigits;
		SimpleTypeExpression = StrTemplate(SimpleTypeExpressionTemplate, FieldName, Digits, Accuracy);
		
		CompoundTypeExpressionTemplate = "WHEN VALUETYPE(%1) = TYPE(NUMBER)
		|THEN %2";
		
		CompoundTypeExpression = StrTemplate(CompoundTypeExpressionTemplate, FieldName, SimpleTypeExpression);
		FieldTypeExpressions.Add(CompoundTypeExpression);
		
	EndIf;
	
	If DescriptionOfValueType_.ContainsType(Type("Date")) Then
		
		SimpleTypeExpressionTemplate = "CAST(%1 AS DATE)";
		SimpleTypeExpression = StrTemplate(SimpleTypeExpressionTemplate, FieldName);
		
		CompoundTypeExpressionTemplate = "WHEN VALUETYPE(%1) = TYPE(DATE)
		|THEN %2";
		CompoundTypeExpression = StrTemplate(CompoundTypeExpressionTemplate, FieldName, SimpleTypeExpression);
		FieldTypeExpressions.Add(CompoundTypeExpression);
		
	EndIf;
	
	If DescriptionOfValueType_.ContainsType(Type("Boolean")) Then
		
		SimpleTypeExpressionTemplate = "CAST(%1 AS BOOLEAN)";
		SimpleTypeExpression = StrTemplate(SimpleTypeExpressionTemplate, FieldName);
		
		CompoundTypeExpressionTemplate = "WHEN VALUETYPE(%1) = TYPE(BOOLEAN)
		|THEN %2";
		CompoundTypeExpression = StrTemplate(CompoundTypeExpressionTemplate, FieldName, SimpleTypeExpression);
		FieldTypeExpressions.Add(CompoundTypeExpression);
		
	EndIf;
	
	If DescriptionOfValueType_.Types().Count() > 1 Then
		
		CompoundTypeTypingExpression = "CASE
		|" + StrConcat(FieldTypeExpressions, Chars.LF) + "
		|END";
		
		Return CompoundTypeTypingExpression;
		
	Else
		
		Return SimpleTypeExpression;
		
	EndIf;
	
EndFunction

Function EmptyValueOfCompositeField(DescriptionOfValueType_)
	
	If DescriptionOfValueType_.Types().Count() > 1
	 Or DescriptionOfValueType_.Types().Count() = 0 Then
		
		Return "UNDEFINED";
		
	ElsIf DescriptionOfValueType_.ContainsType(Type("String")) Then
		
		Return """""";
		
	ElsIf DescriptionOfValueType_.ContainsType(Type("Number")) Then
		
		Return "0";
		
	ElsIf DescriptionOfValueType_.ContainsType(Type("Date")) Then
		
		Return "DATETIME(1, 1, 1, 0, 0, 0)";
		
	ElsIf DescriptionOfValueType_.ContainsType(Type("Boolean")) Then
		
		Return "FALSE";
		
	Else
		
		FieldType = DescriptionOfValueType_.Types()[0];
		TypeMetadata = Metadata.FindByType(FieldType);
		If TypeMetadata = Undefined Then
			Raise NStr("vi = 'Không thể xác định kiểu trường';
						|ru = 'Не удалось определить тип поля';
						|en = 'Cannot determine a field type'; fa = 'Cannot determine a field type';
						|it = 'Cannot determine a field type';
						|pl = 'Cannot determine a field type';
						|tr = 'Alan tipi belirlenemedi'");
		EndIf;
		
		TypeOfFieldForRequest = TypeMetadata.FullName();
		EmptyValue = StrTemplate("VALUE(%1.EmptyRef)", TypeOfFieldForRequest);
		Return EmptyValue;
		
	EndIf;
	
EndFunction

#EndRegion
