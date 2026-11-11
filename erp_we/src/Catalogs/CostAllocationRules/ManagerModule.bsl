#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Returns names of blocked details for the BSP details blocking mechanism
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	Result = New Array;
	Return Result;
EndFunction

// Returns parameters for setting up accounting accounts in the document.
//  
// Returns:
//  See GLAccountSettingsServer.SetupParameters.
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	SetupParameters.AvailabilityByOperation = True;
	SetupParameters.DataPath = "Object.WriteOff";
	SetupParameters.ArticleType   = "ArticleType";
	SetupParameters.Organization = "";
	
	SetupParameters.FormItems.Add("WriteOffTransactionRecordingPresentation");
	
	Return SetupParameters;
	
EndFunction
// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//  See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters(AssignRule) Export 
	If AssignRule = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots Then
		
		// For the rule On the party.
		ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
		ChoiceParameters.DataPath = "Object.WriteOff";
		ChoiceParameters.AssetRef      = "ExpenseItem";
		ChoiceParameters.ArticleType   = "ArticleType";
		
		ChoiceParameters.DimensionOfExpenses 		 = "DimensionOfExpenses";
		ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
		
		ChoiceParameters.ChoosingExpenseItem = True;
		
		OptionsArray = New Array;
		OptionsArray.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
		OptionsArray.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
		OptionsArray.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
		OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
		
		ChoiceParameters.SelectionOfExpenditureItems.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = OptionsArray;
		
		ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
		
		ChoiceParameters.FormItems.AssetRef.Add("WriteOffExpenseItem");
		ChoiceParameters.FormItems.DimensionOfExpenses.Add("WriteOffDimensionOfExpenses");
		ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("WriteOffAssetsLiabilitiesDimension");
	
	EndIf;
	If AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationToDeferredExpenses Then
		// For the RBP rule.
		ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
		ChoiceParameters.DataPath = "Object";
		ChoiceParameters.AssetRef      = "DeferredExpensesWriteOffItem";
		
		ChoiceParameters.DimensionOfExpenses 	= "DeferredExpensesDimension";	
		ChoiceParameters.ChoosingExpenseItem = True;
		
		ChoiceParameters.FormItems.AssetRef.Add("DeferredExpensesWriteOffItem");
		ChoiceParameters.FormItems.DimensionOfExpenses.Add("DeferredExpensesDimension");
	
	EndIf;
	
	Return ChoiceParameters;
	
EndFunction

// Returns a representation of the distribution rule by type of distribution base.
// Parameters:
//	AllocationBase - EnumRef.TypesOfCostAllocatingBase - distribution base.
// Returns:
//	String - representation of the distribution base.
Function GetRulePresentation(AllocationBase) Export
	
	RulePresentation = "";
	If AllocationBase = Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds Then
		RulePresentation = NStr("vi = 'Số lượng tác phẩm:';
								|ru = 'Количество работ:';
								|en = 'Number of works:'; fa = 'Number of works:';
								|it = 'Numero di lavori:';
								|pl = 'Ilość prac:';
								|tr = 'İş miktarı:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel Then
		RulePresentation = NStr("vi = 'Chi phí tiêu chuẩn của công việc:';
								|ru = 'Нормативная стоимость работ:';
								|en = 'Standard work cost:'; fa = 'Standard work cost:';
								|it = 'Costo standard dei lavori:';
								|pl = 'Normatywna wartość prac:';
								|tr = 'Standart iş maliyeti:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses Then
		RulePresentation = NStr("vi = 'Chi phí công việc:';
								|ru = 'Стоимость работ:';
								|en = 'Work cost:'; fa = 'Work cost:';
								|it = 'Costo dei lavori:';
								|pl = 'Wartość prac:';
								|tr = 'İş maliyeti:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials Then
		RulePresentation = NStr("vi = 'Số lượng vật liệu:';
								|ru = 'Количество материалов:';
								|en = 'Quantity of materials:'; fa = 'Quantity of materials:';
								|it = 'Quantità dei materiali:';
								|pl = 'Ilość materiałów:';
								|tr = 'Malzeme miktarı:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials Then
		RulePresentation = NStr("vi = 'Khối lượng nguyên vật liệu:';
								|ru = 'Объем материалов:';
								|en = 'Volume of materials:'; fa = 'Volume of materials:';
								|it = 'Volume dei materiali:';
								|pl = 'Objętość materiałów:';
								|tr = 'Malzeme hacmi:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.MaterialCostsAmount Then
		RulePresentation = NStr("vi = 'Giá trị nguyên vật liệu:';
								|ru = 'Стоимость материалов:';
								|en = 'Material cost:'; fa = 'Material cost:';
								|it = 'Costo dei materiali:';
								|pl = 'Wartość materiałów:';
								|tr = 'Malzeme maliyeti:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials Then
		RulePresentation = NStr("vi = 'Trọng lượng nguyên vật liệu:';
								|ru = 'Вес материалов:';
								|en = 'Weight of materials:'; fa = 'Weight of materials:';
								|it = 'Peso dei materiali:';
								|pl = 'Waga materiałów:';
								|tr = 'Malzeme ağırlığı:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts Then
		RulePresentation = NStr("vi = 'Giá trị nguyên vật liệu và tiền công:';
								|ru = 'Стоимость материалов и оплаты труда:';
								|en = 'Material and labor cost:'; fa = 'Material and labor cost:';
								|it = 'Costo dei materiali e della retribuzione:';
								|pl = 'Wartość materiałów i płatności pracy';
								|tr = 'Malzeme maliyeti ve bordro tutarı'");		
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsWeight
		Or AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases Then
		RulePresentation = NStr("vi = 'Trọng lượng sản phẩm:';
								|ru = 'Вес продукции:';
								|en = 'Product weight:'; fa = 'Product weight:';
								|it = 'Peso della produzione:';
								|pl = 'Waga produkcji:';
								|tr = 'İmal edilen ürün ağırlığı:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsQuantity
		Or AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases Then
		RulePresentation = NStr("vi = 'Số lượng sản xuất:';
								|ru = 'Количество продукции:';
								|en = 'Product quantity:'; fa = 'Product quantity:';
								|it = 'Quantità della produzione:';
								|pl = 'Ilość produkcji:';
								|tr = 'İmal edilen ürün miktarı:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsVolume
		Or AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases Then
			RulePresentation = NStr("vi = 'Khối lương sản phẩm';
									|ru = 'Объем продукции:';
									|en = 'Volume of products:'; fa = 'Volume of products:';
									|it = 'Volume della produzione:';
									|pl = 'Objętość produkcji:';
									|tr = 'İmal edilen ürün hacmi:'");
	ElsIf AllocationBase = Enums.TypesOfCostAllocatingBase.TargetProductCost 
		Or AllocationBase = Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases Then
			RulePresentation = NStr("vi = 'Chi phí sản xuất theo kế hoạch:';
									|ru = 'Плановая стоимость продукции:';
									|en = 'Standard product cost:'; fa = 'Standard product cost:';
									|it = 'Costo di produzione previsto:';
									|pl = 'Planowana wartość produkcji:';
									|tr = 'İmal edilen ürünlerin standart maliyeti:'");
	EndIf;
	
	DescriptionTemplate = "%1 %2";
	Return StrTemplate(DescriptionTemplate, TrimAll(RulePresentation),
		NStr("vi = 'đã thiết lập lọc bổ sung.';
			|ru = 'установлен дополнительный отбор.';
			|en = 'additional filter is set.'; fa = 'additional filter is set.';
			|it = 'è stata impostata una selezione aggiuntiva.';
			|pl = 'Ustawiono dodatkowy wybór.';
			|tr = 'ek filtre yapılandırıldı.'"));
	
EndFunction

// Returns the assignment of the rule corresponding to the distribution variant.
// 
// Parameters:
//  CostAllocationOption - EnumRef.CostAllocationOptions - Cost allocation option
// 
// Returns:
//  EnumRef.AssignmentOfCostAllocationRules - assignment of the rule corresponding to the distribution option
Function GetRuleAssignmentForDistributionOption(CostAllocationOption) Export
	
	If CostAllocationOption = Enums.CostAllocationOptions.ToInventoryCost Then
		Return Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts;
	ElsIf CostAllocationOption = Enums.CostAllocationOptions.ToDeferredExpenses Then
		Return Enums.AssignmentOfCostAllocationRules.CostAllocationToDeferredExpenses;
	ElsIf CostAllocationOption = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly Then
		Return Enums.AssignmentOfCostAllocationRules.WithoutExpenseAllocation;
	ElsIf CostAllocationOption = Enums.CostAllocationOptions.ToProductionCostDirect Then
		Return Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost;
	ElsIf CostAllocationOption = Enums.CostAllocationOptions.ToProductionCosts Then
		Return Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots;
	ElsIf CostAllocationOption = Enums.CostAllocationOptions.ToCostCenters Then
		Return Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter;
	Else
		Return Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult;
	EndIf;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ChoiceForm" Or Not FormType = "ObjectForm" Then
		Return;
	EndIf;
	
	If Parameters.Property("Key") Then
		
		DetailsToReceive = New Array;
		DetailsToReceive.Add("AssignRule");
		DetailsToReceive.Add("Obsolete_");
		AttributesValues = GeneralPurposeTMServerCall.ObjectAttributesValues(Parameters.Key, DetailsToReceive);
		If AttributesValues.Obsolete_ Then
			SelectedForm = "ObsoleteFormOfRule";
			StandardProcessing = False;
			Return;
		EndIf;
	ElsIf Parameters.Property("CopyingValue") Then
		AttributesValues = Parameters.CopyingValue;
	ElsIf Parameters.Property("FillingValues")
		And Parameters.FillingValues.Property("AssignRule") Then
		AttributesValues = Parameters.FillingValues;
	Else
		Return;
	EndIf;
	
	InFrench = PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult");
	OnRBP = PredefinedValue("Enum.AssignmentOfCostAllocationRules.CostAllocationToDeferredExpenses");
	UsedMaterials = PredefinedValue("Enum.AssignmentOfCostAllocationRules.MaterialsAndWorksCostAllocation");
	ToBatches = PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots");
	ByBusinessUnits = PredefinedValue("Enum.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits");
	OnOvz = PredefinedValue("Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter");
	AtCostPrice = PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts");
	
	DestinationForms = New Map;
	DestinationForms.Insert(InFrench, "FRSettingsForm");
	DestinationForms.Insert(OnRBP, "SettingsFormOfDeferredExpenses");
	DestinationForms.Insert(ToBatches, "SettingsFormToLots");
	DestinationForms.Insert(ByBusinessUnits, "IndicatorForm");
	DestinationForms.Insert(OnOvz, "IndicatorForm");
	DestinationForms.Insert(UsedMaterials, "ObsoleteFormOfRule");
	DestinationForms.Insert(AtCostPrice, "SettingsFormToInventoryCost");
		
	SelectedForm = DestinationForms.Get(AttributesValues.AssignRule);
	
	If ValueIsFilled(SelectedForm) Then
		
		StandardProcessing = False;
		Return;
		
	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	SetAssignmentOfRuleByDistributionOption(Parameters);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure SetAssignmentOfRuleByDistributionOption(Parameters) 
	
	If Parameters.Property("CostAllocationOption") Then
		If Not Parameters.Property("Filter") Then
			Parameters.Insert("Filter", New Structure);
		EndIf;
		If Not Parameters.Filter.Property("AssignRule") Then
			Parameters.Filter.Insert("AssignRule", GetRuleAssignmentForDistributionOption(Parameters.CostAllocationOption));
		EndIf;
	EndIf;
	
EndProcedure
#EndRegion

#EndRegion

#EndIf
